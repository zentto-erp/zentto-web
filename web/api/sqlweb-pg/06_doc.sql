-- sp_anular_documento_compra_tx
DROP FUNCTION IF EXISTS public.sp_anular_documento_compra_tx(character varying, character varying, character varying, character varying) CASCADE;
DROP FUNCTION IF EXISTS public.sp_anular_documento_compra_tx(p_num_fact character varying, p_tipo_operacion character varying DEFAULT NULL::character varying, p_cod_usuario character varying DEFAULT 'API'::character varying, p_motivo character varying DEFAULT ''::character varying)
 RETURNS TABLE(ok boolean, "numFact" character varying, mensaje character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM "DocumentosCompra" WHERE "NUM_FACT" = p_num_fact) THEN
        RAISE EXCEPTION 'documento_no_encontrado';
    END IF;

    IF EXISTS (SELECT 1 FROM "DocumentosCompra" WHERE "NUM_FACT" = p_num_fact AND "ANULADA" = 1) THEN
        RAISE EXCEPTION 'documento_ya_anulado';
    END IF;

    UPDATE "DocumentosCompra" SET "ANULADA" = 1 WHERE "NUM_FACT" = p_num_fact;

    -- Anular en CxP si existe
    IF p_tipo_operacion = 'COMPRA' THEN
        UPDATE "P_Pagar" SET
            "SALDO" = 0,
            "PAID" = 1,
            "OBS" = COALESCE("OBS", '') || ' [ANULADO]'
        WHERE "DOCUMENTO" = p_num_fact;
    END IF;

    RETURN QUERY SELECT TRUE, p_num_fact, 'Documento anulado'::TEXT;
END;
$function$
;

-- sp_anular_documento_compra_tx
DROP FUNCTION IF EXISTS public.sp_anular_documento_compra_tx(character varying, character varying, character varying, character varying, boolean) CASCADE;
DROP FUNCTION IF EXISTS public.sp_anular_documento_compra_tx(p_num_doc character varying, p_tipo_operacion character varying, p_cod_usuario character varying DEFAULT 'API'::character varying, p_motivo character varying DEFAULT ''::character varying, p_revertir_inventario boolean DEFAULT true)
 RETURNS TABLE(ok boolean, "numDoc" character varying, "tipoOperacion" character varying, mensaje character varying, "inventarioRevertido" boolean)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_fecha_anulacion TIMESTAMP := NOW() AT TIME ZONE 'UTC';
    v_ya_anulado      BOOLEAN;
BEGIN
    -- Verificar existencia
    -- TODO: tabla DocumentosCompra es legacy
    SELECT "ANULADA"::BOOLEAN
    INTO v_ya_anulado
    FROM "DocumentosCompra"
    WHERE "NUM_DOC" = p_num_doc AND "TIPO_OPERACION" = p_tipo_operacion;

    IF v_ya_anulado IS NULL THEN
        RAISE EXCEPTION 'documento_no_encontrado';
    END IF;

    IF v_ya_anulado = TRUE THEN
        RAISE EXCEPTION 'documento_ya_anulado';
    END IF;

    -- Validaciones especificas
    IF p_tipo_operacion = 'ORDEN' AND EXISTS (
        SELECT 1 FROM "DocumentosCompra"
        WHERE "DOC_ORIGEN" = p_num_doc AND "TIPO_OPERACION" = 'COMPRA' AND "ANULADA" = FALSE
    ) THEN
        RAISE EXCEPTION 'orden_tiene_compra_asociada';
    END IF;

    -- Cargar detalle para reversion de inventario
    CREATE TEMP TABLE IF NOT EXISTS _detalles_compra (
        "COD_SERV" VARCHAR(60),
        "CANTIDAD" DOUBLE PRECISION,
        "PRECIO"   DOUBLE PRECISION
    ) ON COMMIT DROP;

    DELETE FROM _detalles_compra;

    IF p_revertir_inventario = TRUE AND p_tipo_operacion = 'COMPRA' THEN
        INSERT INTO _detalles_compra
        SELECT "COD_SERV", COALESCE("CANTIDAD", 0), COALESCE("PRECIO", COALESCE("COSTO", 0))
        FROM "DocumentosCompraDetalle"
        WHERE "NUM_DOC" = p_num_doc AND "TIPO_OPERACION" = p_tipo_operacion AND COALESCE("ANULADA"::INT, 0) = 0;
    END IF;

    -- Marcar como anulado
    UPDATE "DocumentosCompra" SET
        "ANULADA" = TRUE,
        "OBSERV" = COALESCE("OBSERV", '') || ' [ANULADO: ' || TO_CHAR(v_fecha_anulacion, 'YYYY-MM-DD HH24:MI:SS') || COALESCE(' - ' || p_motivo, '') || ']'
    WHERE "NUM_DOC" = p_num_doc AND "TIPO_OPERACION" = p_tipo_operacion;

    -- Anular detalle
    UPDATE "DocumentosCompraDetalle" SET "ANULADA" = TRUE
    WHERE "NUM_DOC" = p_num_doc AND "TIPO_OPERACION" = p_tipo_operacion;

    -- Reversar inventario en master.Product si era compra
    IF p_revertir_inventario = TRUE AND p_tipo_operacion = 'COMPRA' THEN
        -- Restar inventario
        WITH "Totales" AS (
            SELECT "COD_SERV", SUM("CANTIDAD") AS "TOTAL"
            FROM _detalles_compra
            WHERE "COD_SERV" IS NOT NULL
            GROUP BY "COD_SERV"
        )
        UPDATE master."Product" i
        SET "StockQty" = COALESCE(i."StockQty", 0) - t."TOTAL"
        FROM "Totales" t
        WHERE t."COD_SERV" = i."ProductCode";

        -- Registrar movimiento de reversion
        INSERT INTO "MovInvent" ("CODIGO", "PRODUCT", "DOCUMENTO", "FECHA", "MOTIVO", "TIPO",
            "CANTIDAD_ACTUAL", "CANTIDAD", "CANTIDAD_NUEVA", "CO_USUARIO",
            "PRECIO_COMPRA", "ALICUOTA", "PRECIO_VENTA")
        SELECT d."COD_SERV", d."COD_SERV", p_num_doc || '_ANUL', v_fecha_anulacion,
            'Anulacion COMPRA:' || p_num_doc, 'Egreso',
            COALESCE(i."StockQty", 0) + d."CANTIDAD",
            d."CANTIDAD",
            COALESCE(i."StockQty", 0),
            p_cod_usuario,
            COALESCE(d."PRECIO", 0),
            0,
            COALESCE(i."SalesPrice", 0)
        FROM _detalles_compra d
        INNER JOIN master."Product" i ON i."ProductCode" = d."COD_SERV"
        WHERE d."COD_SERV" IS NOT NULL AND d."CANTIDAD" > 0;
    END IF;

    -- Reversar CxP si era compra
    IF p_tipo_operacion = 'COMPRA' THEN
        UPDATE "P_Pagar" SET
            "ANULADA" = TRUE,
            "SALDO" = 0,
            "OBSERVACION" = COALESCE("OBSERVACION", '') || ' [ANULADO]'
        WHERE "FACTURA" = p_num_doc AND "ANULADA" = FALSE;
    END IF;

    RETURN QUERY
    SELECT TRUE, p_num_doc, p_tipo_operacion, 'Documento anulado'::VARCHAR, p_revertir_inventario;

EXCEPTION WHEN OTHERS THEN
    RAISE EXCEPTION '%', SQLERRM;
END;
$function$
;

-- sp_anular_documento_venta_tx
DROP FUNCTION IF EXISTS public.sp_anular_documento_venta_tx(character varying, character varying, character varying, character varying, boolean) CASCADE;
DROP FUNCTION IF EXISTS public.sp_anular_documento_venta_tx(p_num_doc character varying, p_tipo_operacion character varying, p_cod_usuario character varying DEFAULT 'API'::character varying, p_motivo character varying DEFAULT ''::character varying, p_revertir_inventario boolean DEFAULT true)
 RETURNS TABLE(ok boolean, "numDoc" character varying, "tipoOperacion" character varying, mensaje character varying, "inventarioRevertido" boolean)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_fecha_anulacion TIMESTAMP := NOW() AT TIME ZONE 'UTC';
    v_ya_anulado      BOOLEAN;
    v_fecha_doc       TIMESTAMP;
BEGIN
    -- Verificar existencia
    -- TODO: tabla DocumentosVenta es legacy
    SELECT "ANULADA"::BOOLEAN, "FECHA"
    INTO v_ya_anulado, v_fecha_doc
    FROM "DocumentosVenta"
    WHERE "NUM_DOC" = p_num_doc AND "TIPO_OPERACION" = p_tipo_operacion;

    IF v_ya_anulado IS NULL THEN
        RAISE EXCEPTION 'documento_no_encontrado';
    END IF;

    IF v_ya_anulado = TRUE THEN
        RAISE EXCEPTION 'documento_ya_anulado';
    END IF;

    -- Validaciones especificas por tipo
    IF p_tipo_operacion = 'PEDIDO' AND EXISTS (SELECT 1 FROM "DocumentosVenta" WHERE "DOC_ORIGEN" = p_num_doc AND "ANULADA" = FALSE) THEN
        RAISE EXCEPTION 'pedido_tiene_factura_asociada';
    END IF;

    -- Cargar detalle para reversion de inventario
    CREATE TEMP TABLE IF NOT EXISTS _detalles_venta (
        "COD_SERV" VARCHAR(60),
        "CANTIDAD" DOUBLE PRECISION,
        "PRECIO"   DOUBLE PRECISION,
        "ALICUOTA" DOUBLE PRECISION
    ) ON COMMIT DROP;

    DELETE FROM _detalles_venta;

    IF p_revertir_inventario = TRUE AND p_tipo_operacion IN ('PEDIDO', 'NOTA_ENTREGA') THEN
        INSERT INTO _detalles_venta
        SELECT "COD_SERV", COALESCE("CANTIDAD", 0), COALESCE("PRECIO", 0), COALESCE("ALICUOTA", 0)
        FROM "DocumentosVentaDetalle"
        WHERE "NUM_DOC" = p_num_doc AND "TIPO_OPERACION" = p_tipo_operacion AND COALESCE("ANULADA"::INT, 0) = 0;
    END IF;

    -- Marcar como anulado
    UPDATE "DocumentosVenta" SET
        "ANULADA" = TRUE,
        "OBSERV" = COALESCE("OBSERV", '') || ' [ANULADO: ' || TO_CHAR(v_fecha_anulacion, 'YYYY-MM-DD HH24:MI:SS') || COALESCE(' - ' || p_motivo, '') || ']'
    WHERE "NUM_DOC" = p_num_doc AND "TIPO_OPERACION" = p_tipo_operacion;

    -- Anular detalle
    UPDATE "DocumentosVentaDetalle" SET "ANULADA" = TRUE
    WHERE "NUM_DOC" = p_num_doc AND "TIPO_OPERACION" = p_tipo_operacion;

    -- Reversar inventario en master.Product si aplica
    IF p_revertir_inventario = TRUE AND p_tipo_operacion IN ('PEDIDO', 'NOTA_ENTREGA') THEN
        -- Devolver inventario
        WITH "Totales" AS (
            SELECT "COD_SERV", SUM("CANTIDAD") AS "TOTAL"
            FROM _detalles_venta
            WHERE "COD_SERV" IS NOT NULL
            GROUP BY "COD_SERV"
        )
        UPDATE master."Product" i
        SET "StockQty" = COALESCE(i."StockQty", 0) + t."TOTAL"
        FROM "Totales" t
        WHERE t."COD_SERV" = i."ProductCode";

        -- Registrar movimiento de reversion
        INSERT INTO "MovInvent" ("CODIGO", "PRODUCT", "DOCUMENTO", "FECHA", "MOTIVO", "TIPO",
            "CANTIDAD_ACTUAL", "CANTIDAD", "CANTIDAD_NUEVA", "CO_USUARIO",
            "PRECIO_COMPRA", "ALICUOTA", "PRECIO_VENTA")
        SELECT d."COD_SERV", d."COD_SERV", p_num_doc || '_ANUL', v_fecha_anulacion,
            'Anulacion ' || p_tipo_operacion || ':' || p_num_doc, 'Ingreso',
            COALESCE(i."StockQty", 0) - d."CANTIDAD",
            d."CANTIDAD",
            COALESCE(i."StockQty", 0),
            p_cod_usuario,
            COALESCE(i."COSTO_REFERENCIA", 0),
            COALESCE(d."ALICUOTA", 0),
            COALESCE(d."PRECIO", 0)
        FROM _detalles_venta d
        INNER JOIN master."Product" i ON i."ProductCode" = d."COD_SERV"
        WHERE d."COD_SERV" IS NOT NULL AND d."CANTIDAD" > 0;
    END IF;

    -- Reversar CxC si era factura
    IF p_tipo_operacion = 'FACT' THEN
        UPDATE "P_Cobrar" SET
            "ANULADA" = TRUE,
            "SALDO" = 0,
            "OBSERVACION" = COALESCE("OBSERVACION", '') || ' [ANULADO]'
        WHERE "FACTURA" = p_num_doc AND "ANULADA" = FALSE;
    END IF;

    RETURN QUERY
    SELECT TRUE, p_num_doc, p_tipo_operacion, 'Documento anulado'::VARCHAR, p_revertir_inventario;

EXCEPTION WHEN OTHERS THEN
    RAISE EXCEPTION '%', SQLERRM;
END;
$function$
;

-- sp_anular_documento_venta_tx
DROP FUNCTION IF EXISTS public.sp_anular_documento_venta_tx(character varying, character varying, character varying, character varying) CASCADE;
DROP FUNCTION IF EXISTS public.sp_anular_documento_venta_tx(p_num_fact character varying, p_tipo_operacion character varying DEFAULT NULL::character varying, p_cod_usuario character varying DEFAULT 'API'::character varying, p_motivo character varying DEFAULT ''::character varying)
 RETURNS TABLE(ok boolean, "numFact" character varying, mensaje character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM "DocumentosVenta" WHERE "NUM_FACT" = p_num_fact) THEN
        RAISE EXCEPTION 'documento_no_encontrado';
    END IF;

    IF EXISTS (SELECT 1 FROM "DocumentosVenta" WHERE "NUM_FACT" = p_num_fact AND "FECHA_ANULA" IS NOT NULL) THEN
        RAISE EXCEPTION 'documento_ya_anulado';
    END IF;

    UPDATE "DocumentosVenta" SET
        "FECHA_ANULA" = NOW() AT TIME ZONE 'UTC',
        "MOTIVO_ANULA" = p_motivo
    WHERE "NUM_FACT" = p_num_fact;

    -- Anular en CxC si existe
    IF p_tipo_operacion = 'FACT' THEN
        UPDATE "P_Cobrar" SET
            "SALDO" = 0,
            "PAID" = 1,
            "OBS" = COALESCE("OBS", '') || ' [ANULADO]'
        WHERE "DOCUMENTO" = p_num_fact;
    END IF;

    RETURN QUERY SELECT TRUE, p_num_fact, 'Documento anulado'::TEXT;
END;
$function$
;

-- sp_documentoscompra_get
DROP FUNCTION IF EXISTS public.sp_documentoscompra_get(character varying, character varying) CASCADE;
DROP FUNCTION IF EXISTS public.sp_documentoscompra_get(p_num_doc character varying, p_tipo_operacion character varying)
 RETURNS TABLE(result_set integer, data jsonb)
 LANGUAGE plpgsql
AS $function$
BEGIN
    -- Cabecera (result_set = 1)
    RETURN QUERY
    SELECT 1,
           ROW_TO_JSON(d)::JSONB
    FROM "DocumentosCompra" d
    WHERE d."NUM_DOC" = p_num_doc AND d."TIPO_OPERACION" = p_tipo_operacion;

    -- Detalle (result_set = 2)
    RETURN QUERY
    SELECT 2,
           ROW_TO_JSON(dd)::JSONB
    FROM "DocumentosCompraDetalle" dd
    WHERE dd."NUM_DOC" = p_num_doc AND dd."TIPO_OPERACION" = p_tipo_operacion
    ORDER BY dd."RENGLON";

    -- Pagos (result_set = 3)
    RETURN QUERY
    SELECT 3,
           ROW_TO_JSON(dp)::JSONB
    FROM "DocumentosCompraPago" dp
    WHERE dp."NUM_DOC" = p_num_doc AND dp."TIPO_OPERACION" = p_tipo_operacion;
END;
$function$
;

-- sp_documentoscompra_list
DROP FUNCTION IF EXISTS public.sp_documentoscompra_list(character varying, character varying, character varying, date, date, boolean, integer, integer) CASCADE;
DROP FUNCTION IF EXISTS public.sp_documentoscompra_list(p_tipo_operacion character varying DEFAULT NULL::character varying, p_search character varying DEFAULT NULL::character varying, p_cod_proveedor character varying DEFAULT NULL::character varying, p_desde date DEFAULT NULL::date, p_hasta date DEFAULT NULL::date, p_anulada boolean DEFAULT NULL::boolean, p_page integer DEFAULT 1, p_limit integer DEFAULT 50)
 RETURNS TABLE("TotalCount" bigint, "ID" integer, "NUM_DOC" character varying, "SERIALTIPO" character varying, "TIPO_OPERACION" character varying, "COD_PROVEEDOR" character varying, "NOMBRE" character varying, "RIF" character varying, "FECHA" timestamp without time zone, "FECHA_VENCE" timestamp without time zone, "FECHA_RECIBO" timestamp without time zone, "HORA" character varying, "SUBTOTAL" double precision, "MONTO_GRA" double precision, "MONTO_EXE" double precision, "EXENTO" double precision, "IVA" double precision, "ALICUOTA" double precision, "TOTAL" double precision, "ANULADA" integer, "CANCELADA" character varying, "RECIBIDA" character varying, "DOC_ORIGEN" character varying, "NUM_CONTROL" character varying, "LEGAL" integer, "CONCEPTO" character varying, "OBSERV" character varying, "ALMACEN" character varying, "IVA_RETENIDO" double precision, "ISLR" character varying, "MONTO_ISLR" double precision, "COD_USUARIO" character varying, "FECHA_REPORTE" timestamp without time zone, "ESTADO" character varying)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_offset INT;
    v_total  BIGINT;
BEGIN
    v_offset := (p_page - 1) * p_limit;

    -- Contar total
    SELECT COUNT(1) INTO v_total
    FROM "DocumentosCompra"
    WHERE (p_tipo_operacion IS NULL OR "TIPO_OPERACION" = p_tipo_operacion)
      AND (p_search IS NULL OR "NUM_DOC" LIKE '%' || p_search || '%'
           OR "NOMBRE" LIKE '%' || p_search || '%'
           OR "RIF" LIKE '%' || p_search || '%'
           OR "COD_PROVEEDOR" LIKE '%' || p_search || '%')
      AND (p_cod_proveedor IS NULL OR "COD_PROVEEDOR" = p_cod_proveedor)
      AND (p_desde IS NULL OR "FECHA"::DATE >= p_desde)
      AND (p_hasta IS NULL OR "FECHA"::DATE <= p_hasta)
      AND (p_anulada IS NULL OR ("ANULADA" = 1) = p_anulada);

    -- Devolver resultados paginados
    RETURN QUERY
    SELECT
        v_total,
        d."ID", d."NUM_DOC", d."SERIALTIPO", d."TIPO_OPERACION",
        d."COD_PROVEEDOR", d."NOMBRE", d."RIF",
        d."FECHA", d."FECHA_VENCE", d."FECHA_RECIBO", d."HORA",
        d."SUBTOTAL", d."MONTO_GRA", d."MONTO_EXE", d."EXENTO",
        d."IVA", d."ALICUOTA", d."TOTAL",
        d."ANULADA", d."CANCELADA", d."RECIBIDA",
        d."DOC_ORIGEN", d."NUM_CONTROL", d."LEGAL",
        d."CONCEPTO", d."OBSERV", d."ALMACEN",
        d."IVA_RETENIDO", d."ISLR", d."MONTO_ISLR",
        d."COD_USUARIO", d."FECHA_REPORTE",
        CASE
            WHEN d."ANULADA" = 1 THEN 'ANULADO'
            WHEN d."CANCELADA" = 'S' THEN 'PAGADO'
            WHEN d."RECIBIDA" = 'S' THEN 'RECIBIDO'
            ELSE 'PENDIENTE'
        END::TEXT
    FROM "DocumentosCompra" d
    WHERE (p_tipo_operacion IS NULL OR d."TIPO_OPERACION" = p_tipo_operacion)
      AND (p_search IS NULL OR d."NUM_DOC" LIKE '%' || p_search || '%'
           OR d."NOMBRE" LIKE '%' || p_search || '%'
           OR d."RIF" LIKE '%' || p_search || '%'
           OR d."COD_PROVEEDOR" LIKE '%' || p_search || '%')
      AND (p_cod_proveedor IS NULL OR d."COD_PROVEEDOR" = p_cod_proveedor)
      AND (p_desde IS NULL OR d."FECHA"::DATE >= p_desde)
      AND (p_hasta IS NULL OR d."FECHA"::DATE <= p_hasta)
      AND (p_anulada IS NULL OR (d."ANULADA" = 1) = p_anulada)
    ORDER BY d."FECHA" DESC, d."ID" DESC
    LIMIT p_limit OFFSET v_offset;
END;
$function$
;

-- sp_documentoscompra_list_legacy
DROP FUNCTION IF EXISTS public.sp_documentoscompra_list_legacy(character varying, character varying, character varying, date, date, boolean, integer, integer) CASCADE;
DROP FUNCTION IF EXISTS public.sp_documentoscompra_list_legacy(p_tipo_operacion character varying DEFAULT NULL::character varying, p_search character varying DEFAULT NULL::character varying, p_cod_proveedor character varying DEFAULT NULL::character varying, p_desde date DEFAULT NULL::date, p_hasta date DEFAULT NULL::date, p_anulada boolean DEFAULT NULL::boolean, p_page integer DEFAULT 1, p_limit integer DEFAULT 50)
 RETURNS TABLE("TotalCount" bigint, "NUM_FACT" character varying, "COD_PROVEEDOR" character varying, "TIPO_OPERACION" character varying, "FECHA" timestamp without time zone, "NOMBRE" character varying, "RIF" character varying, "TOTAL" numeric, "COD_USUARIO" character varying, "ANULADA" integer, "ESTADO" character varying)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_offset INT;
    v_total  BIGINT;
BEGIN
    v_offset := (p_page - 1) * p_limit;

    SELECT COUNT(1) INTO v_total
    FROM "DocumentosCompra"
    WHERE (p_tipo_operacion IS NULL OR "TIPO_OPERACION" = p_tipo_operacion)
      AND (p_search IS NULL OR "NUM_FACT" LIKE '%' || p_search || '%' OR "NOMBRE" LIKE '%' || p_search || '%')
      AND (p_cod_proveedor IS NULL OR "COD_PROVEEDOR" = p_cod_proveedor)
      AND (p_desde IS NULL OR "FECHA"::DATE >= p_desde)
      AND (p_hasta IS NULL OR "FECHA"::DATE <= p_hasta)
      AND (p_anulada IS NULL OR "ANULADA"::BOOLEAN = p_anulada);

    RETURN QUERY
    SELECT
        v_total,
        d."NUM_FACT", d."COD_PROVEEDOR", d."TIPO_OPERACION",
        d."FECHA", d."NOMBRE", d."RIF", d."TOTAL", d."COD_USUARIO", d."ANULADA",
        CASE WHEN d."ANULADA" = 1 THEN 'ANULADO' ELSE 'PENDIENTE' END::TEXT
    FROM "DocumentosCompra" d
    WHERE (p_tipo_operacion IS NULL OR d."TIPO_OPERACION" = p_tipo_operacion)
      AND (p_search IS NULL OR d."NUM_FACT" LIKE '%' || p_search || '%' OR d."NOMBRE" LIKE '%' || p_search || '%')
      AND (p_cod_proveedor IS NULL OR d."COD_PROVEEDOR" = p_cod_proveedor)
      AND (p_desde IS NULL OR d."FECHA"::DATE >= p_desde)
      AND (p_hasta IS NULL OR d."FECHA"::DATE <= p_hasta)
      AND (p_anulada IS NULL OR d."ANULADA"::BOOLEAN = p_anulada)
    ORDER BY d."FECHA" DESC
    LIMIT p_limit OFFSET v_offset;
END;
$function$
;

-- sp_documentosventa_get
DROP FUNCTION IF EXISTS public.sp_documentosventa_get(character varying, character varying) CASCADE;
DROP FUNCTION IF EXISTS public.sp_documentosventa_get(p_num_doc character varying, p_tipo_operacion character varying)
 RETURNS TABLE(result_set integer, data jsonb)
 LANGUAGE plpgsql
AS $function$
BEGIN
    -- Cabecera (result_set = 1)
    RETURN QUERY
    SELECT 1,
           ROW_TO_JSON(d)::JSONB
    FROM "DocumentosVenta" d
    WHERE d."NUM_DOC" = p_num_doc AND d."TIPO_OPERACION" = p_tipo_operacion;

    -- Detalle (result_set = 2)
    RETURN QUERY
    SELECT 2,
           ROW_TO_JSON(dd)::JSONB
    FROM "DocumentosVentaDetalle" dd
    WHERE dd."NUM_DOC" = p_num_doc AND dd."TIPO_OPERACION" = p_tipo_operacion
    ORDER BY dd."RENGLON";

    -- Pagos (result_set = 3)
    RETURN QUERY
    SELECT 3,
           ROW_TO_JSON(dp)::JSONB
    FROM "DocumentosVentaPago" dp
    WHERE dp."NUM_DOC" = p_num_doc AND dp."TIPO_OPERACION" = p_tipo_operacion;
END;
$function$
;

-- sp_documentosventa_list
DROP FUNCTION IF EXISTS public.sp_documentosventa_list(character varying, character varying, character varying, date, date, boolean, integer, integer) CASCADE;
DROP FUNCTION IF EXISTS public.sp_documentosventa_list(p_tipo_operacion character varying DEFAULT NULL::character varying, p_search character varying DEFAULT NULL::character varying, p_codigo character varying DEFAULT NULL::character varying, p_desde date DEFAULT NULL::date, p_hasta date DEFAULT NULL::date, p_anulada boolean DEFAULT NULL::boolean, p_page integer DEFAULT 1, p_limit integer DEFAULT 50)
 RETURNS TABLE("TotalCount" bigint, "ID" integer, "NUM_DOC" character varying, "SERIALTIPO" character varying, "TIPO_OPERACION" character varying, "CODIGO" character varying, "NOMBRE" character varying, "RIF" character varying, "FECHA" timestamp without time zone, "FECHA_VENCE" timestamp without time zone, "HORA" character varying, "SUBTOTAL" double precision, "MONTO_GRA" double precision, "MONTO_EXE" double precision, "IVA" double precision, "ALICUOTA" double precision, "TOTAL" double precision, "DESCUENTO" double precision, "ANULADA" integer, "CANCELADA" character varying, "FACTURADA" character varying, "ENTREGADA" character varying, "DOC_ORIGEN" character varying, "TIPO_DOC_ORIGEN" character varying, "NUM_CONTROL" character varying, "LEGAL" integer, "OBSERV" character varying, "VENDEDOR" character varying, "MONEDA" character varying, "TASA_CAMBIO" double precision, "COD_USUARIO" character varying, "FECHA_REPORTE" timestamp without time zone, "ESTADO" character varying)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_offset INT;
    v_total  BIGINT;
BEGIN
    v_offset := (p_page - 1) * p_limit;

    -- Contar total
    SELECT COUNT(1) INTO v_total
    FROM "DocumentosVenta"
    WHERE (p_tipo_operacion IS NULL OR "TIPO_OPERACION" = p_tipo_operacion)
      AND (p_search IS NULL OR "NUM_DOC" LIKE '%' || p_search || '%'
           OR "NOMBRE" LIKE '%' || p_search || '%'
           OR "RIF" LIKE '%' || p_search || '%'
           OR "CODIGO" LIKE '%' || p_search || '%')
      AND (p_codigo IS NULL OR "CODIGO" = p_codigo)
      AND (p_desde IS NULL OR "FECHA"::DATE >= p_desde)
      AND (p_hasta IS NULL OR "FECHA"::DATE <= p_hasta)
      AND (p_anulada IS NULL OR ("ANULADA" = 1) = p_anulada);

    -- Devolver resultados paginados
    RETURN QUERY
    SELECT
        v_total,
        d."ID", d."NUM_DOC", d."SERIALTIPO", d."TIPO_OPERACION", d."CODIGO", d."NOMBRE", d."RIF",
        d."FECHA", d."FECHA_VENCE", d."HORA",
        d."SUBTOTAL", d."MONTO_GRA", d."MONTO_EXE", d."IVA", d."ALICUOTA", d."TOTAL", d."DESCUENTO",
        d."ANULADA", d."CANCELADA", d."FACTURADA", d."ENTREGADA",
        d."DOC_ORIGEN", d."TIPO_DOC_ORIGEN", d."NUM_CONTROL", d."LEGAL",
        d."OBSERV", d."VENDEDOR", d."MONEDA", d."TASA_CAMBIO",
        d."COD_USUARIO", d."FECHA_REPORTE",
        CASE
            WHEN d."ANULADA" = 1 THEN 'ANULADO'
            WHEN d."CANCELADA" = 'S' THEN 'PAGADO'
            WHEN d."FACTURADA" = 'S' THEN 'FACTURADO'
            ELSE 'PENDIENTE'
        END::TEXT
    FROM "DocumentosVenta" d
    WHERE (p_tipo_operacion IS NULL OR d."TIPO_OPERACION" = p_tipo_operacion)
      AND (p_search IS NULL OR d."NUM_DOC" LIKE '%' || p_search || '%'
           OR d."NOMBRE" LIKE '%' || p_search || '%'
           OR d."RIF" LIKE '%' || p_search || '%'
           OR d."CODIGO" LIKE '%' || p_search || '%')
      AND (p_codigo IS NULL OR d."CODIGO" = p_codigo)
      AND (p_desde IS NULL OR d."FECHA"::DATE >= p_desde)
      AND (p_hasta IS NULL OR d."FECHA"::DATE <= p_hasta)
      AND (p_anulada IS NULL OR (d."ANULADA" = 1) = p_anulada)
    ORDER BY d."FECHA" DESC, d."ID" DESC
    LIMIT p_limit OFFSET v_offset;
END;
$function$
;

-- sp_documentosventa_list_legacy
DROP FUNCTION IF EXISTS public.sp_documentosventa_list_legacy(character varying, character varying, character varying, date, date, boolean, integer, integer) CASCADE;
DROP FUNCTION IF EXISTS public.sp_documentosventa_list_legacy(p_tipo_operacion character varying DEFAULT NULL::character varying, p_search character varying DEFAULT NULL::character varying, p_codigo character varying DEFAULT NULL::character varying, p_desde date DEFAULT NULL::date, p_hasta date DEFAULT NULL::date, p_anulada boolean DEFAULT NULL::boolean, p_page integer DEFAULT 1, p_limit integer DEFAULT 50)
 RETURNS TABLE("TotalCount" bigint, "NUM_FACT" character varying, "SERIALTIPO" character varying, "Tipo_Orden" character varying, "TIPO_OPERACION" character varying, "CODIGO" character varying, "FECHA" timestamp without time zone, "TOTAL" numeric, "COD_USUARIO" character varying, "OBSERV" character varying, "CANCELADA" character varying, "FECHA_ANULA" timestamp without time zone, "ESTADO" character varying)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_offset INT;
    v_total  BIGINT;
BEGIN
    v_offset := (p_page - 1) * p_limit;

    SELECT COUNT(1) INTO v_total
    FROM "DocumentosVenta"
    WHERE (p_tipo_operacion IS NULL OR "TIPO_OPERACION" = p_tipo_operacion)
      AND (p_search IS NULL OR "NUM_FACT" LIKE '%' || p_search || '%' OR "OBSERV" LIKE '%' || p_search || '%')
      AND (p_codigo IS NULL OR "CODIGO" = p_codigo)
      AND (p_desde IS NULL OR "FECHA"::DATE >= p_desde)
      AND (p_hasta IS NULL OR "FECHA"::DATE <= p_hasta)
      AND (p_anulada IS NULL OR
           CASE WHEN "FECHA_ANULA" IS NULL THEN FALSE ELSE TRUE END = p_anulada);

    RETURN QUERY
    SELECT
        v_total,
        d."NUM_FACT", d."SERIALTIPO", d."Tipo_Orden", d."TIPO_OPERACION",
        d."CODIGO", d."FECHA", d."TOTAL", d."COD_USUARIO", d."OBSERV",
        d."CANCELADA", d."FECHA_ANULA",
        CASE
            WHEN d."FECHA_ANULA" IS NOT NULL THEN 'ANULADO'
            WHEN d."CANCELADA" = 'S' THEN 'CANCELADO'
            ELSE 'PENDIENTE'
        END::TEXT
    FROM "DocumentosVenta" d
    WHERE (p_tipo_operacion IS NULL OR d."TIPO_OPERACION" = p_tipo_operacion)
      AND (p_search IS NULL OR d."NUM_FACT" LIKE '%' || p_search || '%' OR d."OBSERV" LIKE '%' || p_search || '%')
      AND (p_codigo IS NULL OR d."CODIGO" = p_codigo)
      AND (p_desde IS NULL OR d."FECHA"::DATE >= p_desde)
      AND (p_hasta IS NULL OR d."FECHA"::DATE <= p_hasta)
      AND (p_anulada IS NULL OR
           CASE WHEN d."FECHA_ANULA" IS NULL THEN FALSE ELSE TRUE END = p_anulada)
    ORDER BY d."FECHA" DESC
    LIMIT p_limit OFFSET v_offset;
END;
$function$
;

-- sp_documentosventa_tipos
DROP FUNCTION IF EXISTS public.sp_documentosventa_tipos() CASCADE;
CREATE OR REPLACE FUNCTION public.sp_documentosventa_tipos()
 RETURNS TABLE(codigo character varying, nombre character varying, cantidad bigint)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        d."TIPO_OPERACION" AS "codigo",
        CASE d."TIPO_OPERACION"
            WHEN 'FACT' THEN 'Factura'
            WHEN 'PRESUP' THEN 'Presupuesto'
            WHEN 'PEDIDO' THEN 'Pedido'
            WHEN 'COTIZ' THEN 'Cotizacion'
            WHEN 'NOTACRED' THEN 'Nota de Credito'
            WHEN 'NOTADEB' THEN 'Nota de Debito'
            WHEN 'NOTA_ENTREGA' THEN 'Nota de Entrega'
            ELSE d."TIPO_OPERACION"
        END::TEXT AS "nombre",
        COUNT(*)
    FROM "DocumentosVenta" d
    WHERE d."ANULADA" = 0
    GROUP BY d."TIPO_OPERACION"
    ORDER BY d."TIPO_OPERACION";
END;
$function$
;

-- sp_emitir_compra_tx
DROP FUNCTION IF EXISTS public.sp_emitir_compra_tx(jsonb, jsonb, boolean, boolean, boolean) CASCADE;
DROP FUNCTION IF EXISTS public.sp_emitir_compra_tx(p_compra_json jsonb, p_detalle_json jsonb, p_actualizar_inventario boolean DEFAULT true, p_generar_cxp boolean DEFAULT true, p_actualizar_saldos_proveedor boolean DEFAULT true)
 RETURNS TABLE(ok boolean, "numFact" character varying, "detalleRows" integer, "inventoryUpdated" boolean, "cxpGenerated" boolean)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_num_fact        VARCHAR(60);
    v_cod_proveedor   VARCHAR(60);
    v_fecha           TIMESTAMP;
    v_total           NUMERIC(18,4);
    v_cod_usuario     VARCHAR(60);
    v_tipo            VARCHAR(30);
    v_nombre          VARCHAR(200);
    v_rif             VARCHAR(50);
    v_concepto        VARCHAR(500);
    v_detalle_rows    INT;
    v_saldo_previo    DOUBLE PRECISION;
    v_saldo_total     DOUBLE PRECISION;
BEGIN
    -- Extraer datos de la compra
    v_num_fact      := NULLIF(TRIM(p_compra_json->>'NUM_FACT'), '');
    v_cod_proveedor := NULLIF(TRIM(p_compra_json->>'COD_PROVEEDOR'), '');
    v_cod_usuario   := COALESCE(NULLIF(TRIM(p_compra_json->>'COD_USUARIO'), ''), 'API')::character varying;
    v_tipo          := UPPER(COALESCE(NULLIF(TRIM(p_compra_json->>'TIPO'), ''), 'CONTADO')::character varying)::character varying;
    v_nombre        := COALESCE(NULLIF(TRIM(p_compra_json->>'NOMBRE'), ''), '')::character varying;
    v_rif           := COALESCE(NULLIF(TRIM(p_compra_json->>'RIF'), ''), '')::character varying;
    v_concepto      := NULLIF(TRIM(p_compra_json->>'CONCEPTO'), '');

    BEGIN
        v_fecha := (p_compra_json->>'FECHA')::TIMESTAMP;
    EXCEPTION WHEN OTHERS THEN
        v_fecha := NOW() AT TIME ZONE 'UTC';
    END;

    v_total := COALESCE((p_compra_json->>'TOTAL')::NUMERIC(18,4), 0);

    IF v_num_fact IS NULL OR TRIM(v_num_fact) = '' THEN
        RAISE EXCEPTION 'missing_num_fact';
    END IF;

    -- Verificar que la compra no existe (tabla legacy "Compras")
    IF EXISTS (SELECT 1 FROM "Compras" WHERE "NUM_FACT" = v_num_fact) THEN
        RAISE EXCEPTION 'compra_already_exists';
    END IF;

    -- 1. Insertar cabecera en Compras (legacy)
    INSERT INTO "Compras" (
        "NUM_FACT", "COD_PROVEEDOR", "FECHA", "NOMBRE", "RIF", "TOTAL",
        "TIPO", "CONCEPTO", "COD_USUARIO", "ANULADA", "FECHARECIBO"
    )
    VALUES (
        v_num_fact, v_cod_proveedor, v_fecha, v_nombre, v_rif, v_total,
        v_tipo, v_concepto, v_cod_usuario, 0, v_fecha
    );

    -- 2. Insertar detalle en Detalle_Compras (legacy)
    INSERT INTO "Detalle_Compras" (
        "NUM_FACT", "CODIGO", "Referencia", "DESCRIPCION", "FECHA", "CANTIDAD",
        "PRECIO_COSTO", "Alicuota", "Co_Usuario"
    )
    SELECT
        v_num_fact,
        NULLIF(TRIM(d->>'CODIGO'), ''),
        NULLIF(TRIM(d->>'REFERENCIA'), ''),
        NULLIF(TRIM(d->>'DESCRIPCION'), ''),
        v_fecha,
        COALESCE((d->>'CANTIDAD')::NUMERIC(18,4), 0),
        COALESCE((d->>'PRECIO_COSTO')::NUMERIC(18,4), 0),
        COALESCE((d->>'ALICUOTA')::NUMERIC(18,4), 0),
        v_cod_usuario
    FROM jsonb_array_elements(p_detalle_json) AS d;

    SELECT COUNT(*) INTO v_detalle_rows FROM jsonb_array_elements(p_detalle_json);

    -- 3. Actualizar master."Product" â€” Ingreso
    IF p_actualizar_inventario THEN
        -- Insertar en MovInvent (historial)
        INSERT INTO "MovInvent" (
            "DOCUMENTO", "CODIGO", "PRODUCT", "FECHA", "MOTIVO", "TIPO",
            "CANTIDAD_ACTUAL", "CANTIDAD", "CANTIDAD_NUEVA", "CO_USUARIO",
            "PRECIO_COMPRA", "ALICUOTA", "PRECIO_VENTA"
        )
        SELECT
            v_num_fact,
            NULLIF(TRIM(d->>'CODIGO'), ''),
            NULLIF(TRIM(d->>'CODIGO'), ''),
            v_fecha,
            'Compra:' || v_num_fact,
            'Ingreso',
            COALESCE(inv."StockQty", 0),
            COALESCE((d->>'CANTIDAD')::NUMERIC(18,4), 0),
            COALESCE(inv."StockQty", 0) + COALESCE((d->>'CANTIDAD')::NUMERIC(18,4), 0),
            v_cod_usuario,
            COALESCE((d->>'PRECIO_COSTO')::NUMERIC(18,4), 0),
            COALESCE((d->>'ALICUOTA')::NUMERIC(18,4), 0),
            COALESCE(inv."SalesPrice", 0)
        FROM jsonb_array_elements(p_detalle_json) AS d
        INNER JOIN master."Product" inv ON inv."ProductCode" = NULLIF(TRIM(d->>'CODIGO'), '')
        WHERE NULLIF(TRIM(d->>'CODIGO'), '') IS NOT NULL
          AND COALESCE((d->>'CANTIDAD')::NUMERIC(18,4), 0) > 0;

        -- Actualizar existencias
        UPDATE master."Product" AS p
           SET "StockQty" = COALESCE(p."StockQty", 0) + agg."Total"
          FROM (
              SELECT NULLIF(TRIM(d->>'CODIGO'), '') AS cod_serv,
                     SUM(COALESCE((d->>'CANTIDAD')::NUMERIC(18,4), 0)) AS "Total"
                FROM jsonb_array_elements(p_detalle_json) AS d
               WHERE NULLIF(TRIM(d->>'CODIGO'), '') IS NOT NULL
               GROUP BY NULLIF(TRIM(d->>'CODIGO'), '')
          ) agg
         WHERE p."ProductCode" = agg.cod_serv;
    END IF;

    -- 4. Generar CxP (si es credito) â€” tabla legacy "P_Pagar"
    IF p_generar_cxp AND v_tipo = 'CREDITO' AND v_total > 0 THEN
        -- Obtener saldo previo del proveedor
        SELECT COALESCE("SALDO", 0) INTO v_saldo_previo
          FROM "P_Pagar"
         WHERE "CODIGO" = v_cod_proveedor
         ORDER BY "FECHA" DESC
         LIMIT 1;
        v_saldo_previo := COALESCE(v_saldo_previo, 0);

        -- Eliminar CxP previa del documento
        DELETE FROM "P_Pagar"
         WHERE "CODIGO" = v_cod_proveedor
           AND "DOCUMENTO" = v_num_fact
           AND "TIPO" = 'FACT';

        -- Insertar nueva CxP
        INSERT INTO "P_Pagar" (
            "CODIGO", "FECHA", "DOCUMENTO", "TIPO", "DEBE", "HABER", "PEND", "SALDO", "ISRL", "OBS"
        )
        VALUES (
            v_cod_proveedor, v_fecha, v_num_fact, 'FACT', 0, v_total::DOUBLE PRECISION,
            v_total::DOUBLE PRECISION, v_saldo_previo + v_total::DOUBLE PRECISION, '', ''
        );
    END IF;

    -- 5. Actualizar saldos del proveedor en master."Supplier"
    IF p_actualizar_saldos_proveedor AND v_cod_proveedor IS NOT NULL AND TRIM(v_cod_proveedor) <> '' THEN
        SELECT COALESCE(SUM(CASE WHEN "TIPO" = 'FACT' THEN COALESCE("PEND", 0) ELSE 0 END), 0)
          INTO v_saldo_total
          FROM "P_Pagar"
         WHERE "CODIGO" = v_cod_proveedor;

        UPDATE master."Supplier"
           SET "TotalBalance" = v_saldo_total
         WHERE "SupplierCode" = v_cod_proveedor
           AND COALESCE("IsDeleted", FALSE) = FALSE;
    END IF;

    RETURN QUERY SELECT
        TRUE AS "ok",
        v_num_fact AS "numFact",
        v_detalle_rows AS "detalleRows",
        p_actualizar_inventario AS "inventoryUpdated",
        (p_generar_cxp AND v_tipo = 'CREDITO') AS "cxpGenerated";

EXCEPTION WHEN OTHERS THEN
    RAISE EXCEPTION '%', SQLERRM;
END;
$function$
;

-- sp_emitir_cotizacion_tx
DROP FUNCTION IF EXISTS public.sp_emitir_cotizacion_tx(jsonb, jsonb, character varying) CASCADE;
DROP FUNCTION IF EXISTS public.sp_emitir_cotizacion_tx(p_cotizacion_json jsonb, p_detalle_json jsonb, p_cod_usuario character varying DEFAULT 'API'::character varying)
 RETURNS TABLE(ok boolean, "numFact" character varying, "detalleRows" integer)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_num_fact      VARCHAR(60);
    v_codigo        VARCHAR(60);
    v_fecha         TIMESTAMP;
    v_total         NUMERIC(18,4);
    v_nombre        VARCHAR(200);
    v_serial_tipo   VARCHAR(60);
    v_detalle_rows  INT;
BEGIN
    v_num_fact    := NULLIF(TRIM(p_cotizacion_json->>'NUM_FACT'), '');
    v_codigo      := NULLIF(TRIM(p_cotizacion_json->>'CODIGO'), '');
    v_nombre      := COALESCE(NULLIF(TRIM(p_cotizacion_json->>'NOMBRE'), ''), '')::character varying;
    v_serial_tipo := COALESCE(NULLIF(TRIM(p_cotizacion_json->>'SERIALTIPO'), ''), '')::character varying;

    BEGIN
        v_fecha := (p_cotizacion_json->>'FECHA')::TIMESTAMP;
    EXCEPTION WHEN OTHERS THEN
        v_fecha := NOW() AT TIME ZONE 'UTC';
    END;

    v_total := COALESCE((p_cotizacion_json->>'TOTAL')::NUMERIC(18,4), 0);

    IF v_num_fact IS NULL OR TRIM(v_num_fact) = '' THEN
        RAISE EXCEPTION 'missing_num_fact';
    END IF;

    -- Verificar que no existe (tabla legacy "Cotizacion")
    IF EXISTS (SELECT 1 FROM "Cotizacion" WHERE "NUM_FACT" = v_num_fact) THEN
        RAISE EXCEPTION 'cotizacion_already_exists';
    END IF;

    -- 1. Insertar cabecera
    INSERT INTO "Cotizacion" (
        "NUM_FACT", "SERIALTIPO", "CODIGO", "FECHA", "NOMBRE", "TOTAL",
        "COD_USUARIO", "ANULADA", "FECHA_REPORTE", "CANCELADA"
    )
    VALUES (
        v_num_fact, v_serial_tipo, v_codigo, v_fecha, v_nombre, v_total,
        p_cod_usuario, 0, v_fecha, 'N'
    );

    -- 2. Insertar detalle
    INSERT INTO "Detalle_Cotizacion" (
        "NUM_FACT", "SERIALTIPO", "COD_SERV", "DESCRIPCION", "FECHA", "CANTIDAD",
        "PRECIO", "TOTAL", "ANULADA", "Co_Usuario", "Alicuota", "PRECIO_DESCUENTO",
        "Relacionada", "RENGLON", "Vendedor", "Cod_alterno"
    )
    SELECT
        v_num_fact,
        COALESCE(NULLIF(TRIM(d->>'SERIALTIPO'), ''), v_serial_tipo)::character varying,
        NULLIF(TRIM(d->>'COD_SERV'), ''),
        NULLIF(TRIM(d->>'DESCRIPCION'), ''),
        v_fecha,
        COALESCE((d->>'CANTIDAD')::DOUBLE PRECISION, 0),
        COALESCE((d->>'PRECIO')::DOUBLE PRECISION, 0),
        COALESCE(
            (d->>'TOTAL')::DOUBLE PRECISION,
            COALESCE((d->>'PRECIO')::DOUBLE PRECISION, 0) * COALESCE((d->>'CANTIDAD')::DOUBLE PRECISION, 0)
        ),
        0,
        p_cod_usuario,
        COALESCE((d->>'Alicuota')::DOUBLE PRECISION, 0),
        COALESCE(
            (d->>'PRECIO_DESCUENTO')::DOUBLE PRECISION,
            COALESCE((d->>'PRECIO')::DOUBLE PRECISION, 0)
        ),
        COALESCE(NULLIF(TRIM(d->>'Relacionada'), ''), '0')::character varying,
        COALESCE((d->>'RENGLON')::DOUBLE PRECISION, 0),
        NULLIF(TRIM(d->>'Vendedor'), ''),
        NULLIF(TRIM(d->>'Cod_alterno'), '')
    FROM jsonb_array_elements(p_detalle_json) AS d;

    SELECT COUNT(*) INTO v_detalle_rows FROM jsonb_array_elements(p_detalle_json);

    RETURN QUERY SELECT
        TRUE AS "ok",
        v_num_fact AS "numFact",
        v_detalle_rows AS "detalleRows";

EXCEPTION WHEN OTHERS THEN
    RAISE EXCEPTION '%', SQLERRM;
END;
$function$
;

-- sp_emitir_documento_compra_tx
DROP FUNCTION IF EXISTS public.sp_emitir_documento_compra_tx(character varying, jsonb, jsonb, jsonb, character varying, boolean, boolean) CASCADE;
DROP FUNCTION IF EXISTS public.sp_emitir_documento_compra_tx(p_tipo_operacion character varying, p_doc_json jsonb, p_detalle_json jsonb, p_pagos_json jsonb DEFAULT NULL::jsonb, p_cod_usuario character varying DEFAULT 'API'::character varying, p_actualizar_inventario boolean DEFAULT true, p_generar_cxp boolean DEFAULT true)
 RETURNS TABLE(ok boolean, "numDoc" character varying, "tipoOperacion" character varying, total double precision, lineas bigint)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_num_doc        VARCHAR(60);
    v_serial_tipo    VARCHAR(60);
    v_cod_proveedor  VARCHAR(60);
    v_nombre         VARCHAR(255);
    v_rif            VARCHAR(15);
    v_fecha_str      VARCHAR(50);
    v_fecha          TIMESTAMP;
    v_fecha_vence_str VARCHAR(50);
    v_fecha_vence    TIMESTAMP;
    v_fecha_recibo_str VARCHAR(50);
    v_fecha_recibo   TIMESTAMP;
    v_observ         VARCHAR(500);
    v_concepto       VARCHAR(255);
    v_num_control    VARCHAR(60);
    v_doc_origen     VARCHAR(60);
    v_almacen        VARCHAR(50);
    v_precio_dollar  DOUBLE PRECISION;
    v_moneda         VARCHAR(20);
    v_tasa_cambio    DOUBLE PRECISION;

    -- Retenciones
    v_iva_retenido   DOUBLE PRECISION;
    v_monto_islr     DOUBLE PRECISION;
    v_islr           VARCHAR(50);

    -- Calculos
    v_sub_total      DOUBLE PRECISION := 0;
    v_monto_iva      DOUBLE PRECISION := 0;
    v_total          DOUBLE PRECISION := 0;
    v_monto_gra      DOUBLE PRECISION := 0;
    v_monto_exe      DOUBLE PRECISION := 0;
    v_exento         DOUBLE PRECISION := 0;
    v_alicuota       DOUBLE PRECISION := 0;

    v_row            JSONB;
    v_linea_count    BIGINT := 0;
BEGIN
    -- Validar tipo de operacion
    IF p_tipo_operacion NOT IN ('ORDEN', 'COMPRA') THEN
        RAISE EXCEPTION 'tipo_operacion_invalido';
    END IF;

    -- Extraer campos principales
    v_num_doc         := NULLIF(p_doc_json->>'NUM_DOC', ''::character varying);
    v_serial_tipo     := COALESCE(NULLIF(p_doc_json->>'SERIALTIPO', ''::character varying), '')::character varying;
    v_cod_proveedor   := NULLIF(p_doc_json->>'COD_PROVEEDOR', ''::character varying);
    v_nombre          := NULLIF(p_doc_json->>'NOMBRE', ''::character varying);
    v_rif             := NULLIF(p_doc_json->>'RIF', ''::character varying);
    v_fecha_str       := NULLIF(p_doc_json->>'FECHA', ''::character varying);
    v_fecha           := CASE WHEN v_fecha_str IS NOT NULL THEN v_fecha_str::TIMESTAMP ELSE NOW() AT TIME ZONE 'UTC' END;
    v_fecha_vence_str := NULLIF(p_doc_json->>'FECHA_VENCE', ''::character varying);
    v_fecha_vence     := CASE WHEN v_fecha_vence_str IS NOT NULL THEN v_fecha_vence_str::TIMESTAMP ELSE NULL END;
    v_fecha_recibo_str := NULLIF(p_doc_json->>'FECHA_RECIBO', ''::character varying);
    v_fecha_recibo    := CASE WHEN v_fecha_recibo_str IS NOT NULL THEN v_fecha_recibo_str::TIMESTAMP ELSE NULL END;
    v_observ          := NULLIF(p_doc_json->>'OBSERV', ''::character varying);
    v_concepto        := NULLIF(p_doc_json->>'CONCEPTO', ''::character varying);
    v_num_control     := NULLIF(p_doc_json->>'NUM_CONTROL', ''::character varying);
    v_doc_origen      := NULLIF(p_doc_json->>'DOC_ORIGEN', ''::character varying);
    v_almacen         := NULLIF(p_doc_json->>'ALMACEN', ''::character varying);
    v_precio_dollar   := COALESCE(NULLIF(p_doc_json->>'PRECIO_DOLLAR', ''::character varying)::DOUBLE PRECISION, 0)::character varying;
    v_moneda          := COALESCE(NULLIF(p_doc_json->>'MONEDA', ''::character varying), 'BS')::character varying;
    v_tasa_cambio     := COALESCE(NULLIF(p_doc_json->>'TASA_CAMBIO', ''::character varying)::DOUBLE PRECISION, 1)::character varying;

    -- Retenciones
    v_iva_retenido    := COALESCE(NULLIF(p_doc_json->>'IVA_RETENIDO', ''::character varying)::DOUBLE PRECISION, 0)::character varying;
    v_monto_islr      := COALESCE(NULLIF(p_doc_json->>'MONTO_ISLR', ''::character varying)::DOUBLE PRECISION, 0)::character varying;
    v_islr            := NULLIF(p_doc_json->>'ISLR', ''::character varying);

    IF v_num_doc IS NULL THEN
        RAISE EXCEPTION 'num_doc_requerido';
    END IF;

    -- Verificar duplicado
    IF EXISTS (SELECT 1 FROM "DocumentosCompra" WHERE "NUM_DOC" = v_num_doc AND "TIPO_OPERACION" = p_tipo_operacion) THEN
        RAISE EXCEPTION 'documento_ya_existe';
    END IF;

    -- 1. Calcular detalle en tabla temporal
    CREATE TEMP TABLE _detalle_compra_temp (
        "RENGLON"     INT,
        "COD_SERV"    VARCHAR(60),
        "DESCRIPCION" VARCHAR(255),
        "CANTIDAD"    DOUBLE PRECISION,
        "PRECIO"      DOUBLE PRECISION,
        "COSTO"       DOUBLE PRECISION,
        "ALICUOTA"    DOUBLE PRECISION,
        "SUBTOTAL"    DOUBLE PRECISION,
        "MONTO_IVA"   DOUBLE PRECISION,
        "TOTAL"       DOUBLE PRECISION
    ) ON COMMIT DROP;

    INSERT INTO _detalle_compra_temp ("RENGLON", "COD_SERV", "DESCRIPCION", "CANTIDAD", "PRECIO", "COSTO", "ALICUOTA", "SUBTOTAL", "MONTO_IVA", "TOTAL")
    SELECT
        ROW_NUMBER() OVER (ORDER BY (SELECT NULL))::INT,
        NULLIF(elem->>'COD_SERV', ''::character varying),
        NULLIF(elem->>'DESCRIPCION', ''::character varying),
        COALESCE(NULLIF(elem->>'CANTIDAD', ''::character varying)::DOUBLE PRECISION, 0)::character varying,
        COALESCE(NULLIF(elem->>'PRECIO', ''::character varying)::DOUBLE PRECISION, 0)::character varying,
        COALESCE(NULLIF(elem->>'COSTO', ''::character varying)::DOUBLE PRECISION, 0)::character varying,
        COALESCE(NULLIF(elem->>'ALICUOTA', ''::character varying)::DOUBLE PRECISION, 0)::character varying,
        0, 0, 0
    FROM jsonb_array_elements(p_detalle_json) AS elem;

    -- Calcular totales por linea
    UPDATE _detalle_compra_temp SET
        "SUBTOTAL"  = "CANTIDAD" * "PRECIO",
        "MONTO_IVA" = CASE WHEN "ALICUOTA" > 0 THEN "CANTIDAD" * "PRECIO" * ("ALICUOTA" / 100) ELSE 0 END,
        "TOTAL"     = "CANTIDAD" * "PRECIO" * (1 + CASE WHEN "ALICUOTA" > 0 THEN "ALICUOTA" / 100 ELSE 0 END);

    -- Calcular totales del documento
    SELECT SUM("SUBTOTAL"), SUM("MONTO_IVA"), SUM("TOTAL"),
           SUM(CASE WHEN "ALICUOTA" > 0 THEN "SUBTOTAL" ELSE 0 END),
           SUM(CASE WHEN "ALICUOTA" = 0 THEN "SUBTOTAL" ELSE 0 END),
           SUM(CASE WHEN "ALICUOTA" = 0 THEN "SUBTOTAL" ELSE 0 END),
           MAX("ALICUOTA"),
           COUNT(1)
    INTO v_sub_total, v_monto_iva, v_total, v_monto_gra, v_monto_exe, v_exento, v_alicuota, v_linea_count
    FROM _detalle_compra_temp;

    -- 2. Insertar cabecera
    INSERT INTO "DocumentosCompra" (
        "NUM_DOC", "SERIALTIPO", "TIPO_OPERACION", "COD_PROVEEDOR", "NOMBRE", "RIF",
        "FECHA", "FECHA_VENCE", "FECHA_RECIBO", "HORA",
        "SUBTOTAL", "MONTO_GRA", "MONTO_EXE", "EXENTO", "IVA", "ALICUOTA", "TOTAL",
        "ANULADA", "CANCELADA", "RECIBIDA",
        "DOC_ORIGEN", "NUM_CONTROL", "LEGAL",
        "CONCEPTO", "OBSERV", "ALMACEN",
        "IVA_RETENIDO", "ISLR", "MONTO_ISLR",
        "MONEDA", "TASA_CAMBIO", "PRECIO_DOLLAR",
        "COD_USUARIO", "FECHA_REPORTE"
    ) VALUES (
        v_num_doc, v_serial_tipo, p_tipo_operacion, v_cod_proveedor, v_nombre, v_rif,
        v_fecha, v_fecha_vence, v_fecha_recibo, TO_CHAR(NOW() AT TIME ZONE 'UTC', 'HH24:MI:SS'),
        v_sub_total, v_monto_gra, v_monto_exe, v_exento, v_monto_iva, v_alicuota, v_total,
        0, 'N',
        CASE WHEN p_tipo_operacion = 'ORDEN' THEN 'N' ELSE NULL END,
        v_doc_origen, v_num_control,
        CASE WHEN p_tipo_operacion = 'COMPRA' THEN 1 ELSE 0 END,
        v_concepto, v_observ, v_almacen,
        v_iva_retenido, v_islr, v_monto_islr,
        v_moneda, v_tasa_cambio, v_precio_dollar,
        p_cod_usuario, NOW() AT TIME ZONE 'UTC'
    );

    -- 3. Insertar detalle
    INSERT INTO "DocumentosCompraDetalle" (
        "NUM_DOC", "TIPO_OPERACION", "RENGLON", "COD_SERV", "DESCRIPCION",
        "CANTIDAD", "PRECIO", "COSTO", "ALICUOTA",
        "SUBTOTAL", "MONTO_IVA", "TOTAL",
        "CO_USUARIO", "FECHA"
    )
    SELECT v_num_doc, p_tipo_operacion, d."RENGLON", d."COD_SERV", d."DESCRIPCION",
           d."CANTIDAD", d."PRECIO", d."COSTO", d."ALICUOTA",
           d."SUBTOTAL", d."MONTO_IVA", d."TOTAL",
           p_cod_usuario, v_fecha
    FROM _detalle_compra_temp d;

    -- 4. Insertar formas de pago (si aplica)
    IF p_pagos_json IS NOT NULL THEN
        FOR v_row IN SELECT * FROM jsonb_array_elements(p_pagos_json)
        LOOP
            INSERT INTO "DocumentosCompraPago" (
                "NUM_DOC", "TIPO_OPERACION", "TIPO_PAGO", "BANCO", "NUMERO", "MONTO", "FECHA", "CO_USUARIO"
            ) VALUES (
                v_num_doc, p_tipo_operacion,
                NULLIF(v_row->>'TIPO_PAGO', ''::character varying),
                NULLIF(v_row->>'BANCO', ''::character varying),
                NULLIF(v_row->>'NUMERO', ''::character varying),
                COALESCE(NULLIF(v_row->>'MONTO', ''::character varying)::DOUBLE PRECISION, 0)::character varying,
                v_fecha, p_cod_usuario
            );
        END LOOP;
    END IF;

    -- 5. Actualizar inventario (para COMPRA)
    IF p_actualizar_inventario AND p_tipo_operacion = 'COMPRA' THEN
        -- Actualizar costos y existencias
        UPDATE "Inventario" i SET
            "EXISTENCIA" = COALESCE(i."EXISTENCIA", 0) + c."TOTAL_CANT",
            "COSTO_REFERENCIA" = c."AVG_PRECIO",
            "ULTIMO_COSTO" = c."AVG_PRECIO"
        FROM (
            SELECT "COD_SERV",
                   SUM("CANTIDAD") AS "TOTAL_CANT",
                   AVG("PRECIO") AS "AVG_PRECIO"
            FROM _detalle_compra_temp
            WHERE "COD_SERV" IS NOT NULL
            GROUP BY "COD_SERV"
        ) c
        WHERE i."CODIGO" = c."COD_SERV";

        -- Registrar movimiento
        INSERT INTO "MovInvent" (
            "CODIGO", "PRODUCT", "DOCUMENTO", "FECHA", "MOTIVO", "TIPO",
            "CANTIDAD_ACTUAL", "CANTIDAD", "CANTIDAD_NUEVA", "CO_USUARIO",
            "PRECIO_COMPRA", "ALICUOTA", "PRECIO_VENTA"
        )
        SELECT
            d."COD_SERV", d."COD_SERV", v_num_doc, v_fecha,
            'COMPRA:' || v_num_doc, 'Ingreso',
            COALESCE(i."EXISTENCIA", 0) - d."CANTIDAD",
            d."CANTIDAD",
            COALESCE(i."EXISTENCIA", 0),
            p_cod_usuario,
            COALESCE(d."PRECIO", d."COSTO"),
            COALESCE(d."ALICUOTA", 0),
            COALESCE(i."PRECIO_VENTA", 0)
        FROM _detalle_compra_temp d
        INNER JOIN "Inventario" i ON i."CODIGO" = d."COD_SERV"
        WHERE d."COD_SERV" IS NOT NULL;
    END IF;

    -- 6. Generar CxP (solo para COMPRA)
    IF p_generar_cxp AND p_tipo_operacion = 'COMPRA' THEN
        INSERT INTO "P_Pagar" (
            "CODIGO", "FACTURA", "FECHA", "FECHA_VENCE", "TOTAL", "ABONO", "SALDO",
            "TIPO", "DOCUMENTO", "REFERENCIA", "OBSERVACION",
            "FECHA_E", "COD_USUARIO", "ANULADA", "CANCELADA"
        )
        SELECT v_cod_proveedor, v_num_doc, v_fecha, v_fecha_vence, v_total, 0, v_total,
               'COMPRA', v_num_doc, v_num_control, v_observ,
               v_fecha, p_cod_usuario, 0, 'N'
        WHERE NOT EXISTS (SELECT 1 FROM "P_Pagar" WHERE "FACTURA" = v_num_doc);
    END IF;

    -- 7. Actualizar orden si se esta recibiendo como compra
    IF v_doc_origen IS NOT NULL AND p_tipo_operacion = 'COMPRA' THEN
        UPDATE "DocumentosCompra" SET
            "RECIBIDA" = 'S'
        WHERE "NUM_DOC" = v_doc_origen AND "TIPO_OPERACION" = 'ORDEN';
    END IF;

    RETURN QUERY SELECT TRUE, v_num_doc, p_tipo_operacion, v_total, v_linea_count;
END;
$function$
;

-- sp_emitir_documento_venta_tx
DROP FUNCTION IF EXISTS public.sp_emitir_documento_venta_tx(character varying, jsonb, jsonb, jsonb, character varying, boolean, boolean) CASCADE;
DROP FUNCTION IF EXISTS public.sp_emitir_documento_venta_tx(p_tipo_operacion character varying, p_doc_json jsonb, p_detalle_json jsonb, p_pagos_json jsonb DEFAULT NULL::jsonb, p_cod_usuario character varying DEFAULT 'API'::character varying, p_actualizar_inventario boolean DEFAULT true, p_generar_cxc boolean DEFAULT true)
 RETURNS TABLE(ok boolean, "numDoc" character varying, "tipoOperacion" character varying, total double precision, lineas bigint)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_num_doc        VARCHAR(60);
    v_serial_tipo    VARCHAR(60);
    v_codigo         VARCHAR(60);
    v_nombre         VARCHAR(255);
    v_rif            VARCHAR(20);
    v_fecha_str      VARCHAR(50);
    v_fecha          TIMESTAMP;
    v_fecha_vence_str VARCHAR(50);
    v_fecha_vence    TIMESTAMP;
    v_observ         VARCHAR(500);
    v_vendedor       VARCHAR(60);
    v_doc_origen     VARCHAR(60);
    v_tipo_doc_origen VARCHAR(20);
    v_num_control    VARCHAR(60);
    v_terminos       VARCHAR(255);
    v_moneda         VARCHAR(20);
    v_tasa_cambio    DOUBLE PRECISION;
    v_descuento      DOUBLE PRECISION;
    v_placas         VARCHAR(20);
    v_kilometros     INT;

    v_sub_total      DOUBLE PRECISION := 0;
    v_monto_iva      DOUBLE PRECISION := 0;
    v_total          DOUBLE PRECISION := 0;
    v_monto_gra      DOUBLE PRECISION := 0;
    v_monto_exe      DOUBLE PRECISION := 0;
    v_alicuota       DOUBLE PRECISION := 0;

    v_row            JSONB;
    v_linea_count    BIGINT := 0;
BEGIN
    -- Validar tipo de operacion
    IF p_tipo_operacion NOT IN ('FACT', 'PRESUP', 'PEDIDO', 'COTIZ', 'NOTACRED', 'NOTADEB', 'NOTA_ENTREGA') THEN
        RAISE EXCEPTION 'tipo_operacion_invalido';
    END IF;

    -- Extraer campos principales
    v_num_doc         := NULLIF(p_doc_json->>'NUM_DOC', ''::character varying);
    v_serial_tipo     := COALESCE(NULLIF(p_doc_json->>'SERIALTIPO', ''::character varying), '')::character varying;
    v_codigo          := NULLIF(p_doc_json->>'CODIGO', ''::character varying);
    v_nombre          := NULLIF(p_doc_json->>'NOMBRE', ''::character varying);
    v_rif             := NULLIF(p_doc_json->>'RIF', ''::character varying);
    v_fecha_str       := NULLIF(p_doc_json->>'FECHA', ''::character varying);
    v_fecha           := CASE WHEN v_fecha_str IS NOT NULL THEN v_fecha_str::TIMESTAMP ELSE NOW() AT TIME ZONE 'UTC' END;
    v_fecha_vence_str := NULLIF(p_doc_json->>'FECHA_VENCE', ''::character varying);
    v_fecha_vence     := CASE WHEN v_fecha_vence_str IS NOT NULL THEN v_fecha_vence_str::TIMESTAMP ELSE NULL END;
    v_observ          := NULLIF(p_doc_json->>'OBSERV', ''::character varying);
    v_vendedor        := NULLIF(p_doc_json->>'VENDEDOR', ''::character varying);
    v_doc_origen      := NULLIF(p_doc_json->>'DOC_ORIGEN', ''::character varying);
    v_tipo_doc_origen := NULLIF(p_doc_json->>'TIPO_DOC_ORIGEN', ''::character varying);
    v_num_control     := NULLIF(p_doc_json->>'NUM_CONTROL', ''::character varying);
    v_terminos        := NULLIF(p_doc_json->>'TERMINOS', ''::character varying);
    v_moneda          := COALESCE(NULLIF(p_doc_json->>'MONEDA', ''::character varying), 'BS')::character varying;
    v_tasa_cambio     := COALESCE(NULLIF(p_doc_json->>'TASA_CAMBIO', ''::character varying)::DOUBLE PRECISION, 1)::character varying;
    v_descuento       := COALESCE(NULLIF(p_doc_json->>'DESCUENTO', ''::character varying)::DOUBLE PRECISION, 0)::character varying;
    v_placas          := NULLIF(p_doc_json->>'PLACAS', ''::character varying);
    v_kilometros      := NULLIF(p_doc_json->>'KILOMETROS', ''::character varying)::INT;

    IF v_num_doc IS NULL THEN
        RAISE EXCEPTION 'num_doc_requerido';
    END IF;

    -- Verificar duplicado
    IF EXISTS (SELECT 1 FROM "DocumentosVenta" WHERE "NUM_DOC" = v_num_doc AND "TIPO_OPERACION" = p_tipo_operacion) THEN
        RAISE EXCEPTION 'documento_ya_existe';
    END IF;

    -- 1. Calcular detalle en tabla temporal
    CREATE TEMP TABLE _detalle_temp (
        "RENGLON"     INT,
        "COD_SERV"    VARCHAR(60),
        "DESCRIPCION" VARCHAR(255),
        "CANTIDAD"    DOUBLE PRECISION,
        "PRECIO"      DOUBLE PRECISION,
        "PRECIO_DESC" DOUBLE PRECISION,
        "ALICUOTA"    DOUBLE PRECISION,
        "SUBTOTAL"    DOUBLE PRECISION,
        "MONTO_IVA"   DOUBLE PRECISION,
        "TOTAL"       DOUBLE PRECISION
    ) ON COMMIT DROP;

    INSERT INTO _detalle_temp ("RENGLON", "COD_SERV", "DESCRIPCION", "CANTIDAD", "PRECIO", "PRECIO_DESC", "ALICUOTA", "SUBTOTAL", "MONTO_IVA", "TOTAL")
    SELECT
        ROW_NUMBER() OVER (ORDER BY (SELECT NULL))::INT,
        NULLIF(elem->>'COD_SERV', ''::character varying),
        NULLIF(elem->>'DESCRIPCION', ''::character varying),
        COALESCE(NULLIF(elem->>'CANTIDAD', ''::character varying)::DOUBLE PRECISION, 0)::character varying,
        COALESCE(NULLIF(elem->>'PRECIO', ''::character varying)::DOUBLE PRECISION, 0)::character varying,
        COALESCE(NULLIF(elem->>'PRECIO_DESCUENTO', ''::character varying)::DOUBLE PRECISION, 0)::character varying,
        COALESCE(NULLIF(elem->>'ALICUOTA', ''::character varying)::DOUBLE PRECISION, 0)::character varying,
        0, 0, 0
    FROM jsonb_array_elements(p_detalle_json) AS elem;

    -- Calcular totales por linea
    UPDATE _detalle_temp SET
        "SUBTOTAL"  = "CANTIDAD" * CASE WHEN "PRECIO_DESC" > 0 THEN "PRECIO_DESC" ELSE "PRECIO" END,
        "MONTO_IVA" = CASE WHEN "ALICUOTA" > 0
                      THEN "CANTIDAD" * CASE WHEN "PRECIO_DESC" > 0 THEN "PRECIO_DESC" ELSE "PRECIO" END * ("ALICUOTA" / 100)
                      ELSE 0 END,
        "TOTAL"     = "CANTIDAD" * CASE WHEN "PRECIO_DESC" > 0 THEN "PRECIO_DESC" ELSE "PRECIO" END
                      * (1 + CASE WHEN "ALICUOTA" > 0 THEN "ALICUOTA" / 100 ELSE 0 END);

    -- Calcular totales del documento
    SELECT SUM("SUBTOTAL"), SUM("MONTO_IVA"), SUM("TOTAL"),
           SUM(CASE WHEN "ALICUOTA" > 0 THEN "SUBTOTAL" ELSE 0 END),
           SUM(CASE WHEN "ALICUOTA" = 0 THEN "SUBTOTAL" ELSE 0 END),
           MAX("ALICUOTA"),
           COUNT(1)
    INTO v_sub_total, v_monto_iva, v_total, v_monto_gra, v_monto_exe, v_alicuota, v_linea_count
    FROM _detalle_temp;

    -- Aplicar descuento global
    IF v_descuento > 0 THEN
        v_sub_total := v_sub_total * (1 - v_descuento / 100);
        v_monto_iva := v_monto_iva * (1 - v_descuento / 100);
        v_total     := v_sub_total + v_monto_iva;
    END IF;

    -- 2. Insertar cabecera
    INSERT INTO "DocumentosVenta" (
        "NUM_DOC", "SERIALTIPO", "TIPO_OPERACION", "CODIGO", "NOMBRE", "RIF",
        "FECHA", "FECHA_VENCE", "HORA",
        "SUBTOTAL", "MONTO_GRA", "MONTO_EXE", "IVA", "ALICUOTA", "TOTAL", "DESCUENTO",
        "ANULADA", "CANCELADA", "FACTURADA", "ENTREGADA",
        "DOC_ORIGEN", "TIPO_DOC_ORIGEN", "NUM_CONTROL", "LEGAL",
        "OBSERV", "TERMINOS", "VENDEDOR",
        "MONEDA", "TASA_CAMBIO",
        "PLACAS", "KILOMETROS",
        "COD_USUARIO", "FECHA_REPORTE"
    ) VALUES (
        v_num_doc, v_serial_tipo, p_tipo_operacion, v_codigo, v_nombre, v_rif,
        v_fecha, v_fecha_vence, TO_CHAR(NOW() AT TIME ZONE 'UTC', 'HH24:MI:SS'),
        v_sub_total, v_monto_gra, v_monto_exe, v_monto_iva, v_alicuota, v_total, v_descuento,
        0, 'N',
        CASE WHEN p_tipo_operacion = 'PEDIDO' THEN 'N' ELSE NULL END,
        CASE WHEN p_tipo_operacion = 'NOTA_ENTREGA' THEN 'N' ELSE NULL END,
        v_doc_origen, v_tipo_doc_origen, v_num_control,
        CASE WHEN p_tipo_operacion = 'FACT' THEN 1 ELSE 0 END,
        v_observ, v_terminos, v_vendedor,
        v_moneda, v_tasa_cambio,
        v_placas, v_kilometros,
        p_cod_usuario, NOW() AT TIME ZONE 'UTC'
    );

    -- 3. Insertar detalle
    INSERT INTO "DocumentosVentaDetalle" (
        "NUM_DOC", "TIPO_OPERACION", "RENGLON", "COD_SERV", "DESCRIPCION",
        "CANTIDAD", "PRECIO", "PRECIO_DESCUENTO", "ALICUOTA",
        "SUBTOTAL", "MONTO_IVA", "TOTAL",
        "CO_USUARIO", "FECHA"
    )
    SELECT v_num_doc, p_tipo_operacion, d."RENGLON", d."COD_SERV", d."DESCRIPCION",
           d."CANTIDAD", d."PRECIO", d."PRECIO_DESC", d."ALICUOTA",
           d."SUBTOTAL", d."MONTO_IVA", d."TOTAL",
           p_cod_usuario, v_fecha
    FROM _detalle_temp d;

    -- 4. Insertar formas de pago (si aplica)
    IF p_pagos_json IS NOT NULL THEN
        FOR v_row IN SELECT * FROM jsonb_array_elements(p_pagos_json)
        LOOP
            INSERT INTO "DocumentosVentaPago" (
                "NUM_DOC", "TIPO_OPERACION", "TIPO_PAGO", "BANCO", "NUMERO",
                "MONTO", "TASA_CAMBIO", "FECHA", "CO_USUARIO"
            ) VALUES (
                v_num_doc, p_tipo_operacion,
                NULLIF(v_row->>'TIPO_PAGO', ''::character varying),
                NULLIF(v_row->>'BANCO', ''::character varying),
                NULLIF(v_row->>'NUMERO', ''::character varying),
                COALESCE(NULLIF(v_row->>'MONTO', ''::character varying)::DOUBLE PRECISION, 0)::character varying,
                COALESCE(NULLIF(v_row->>'TASA_CAMBIO', ''::character varying)::DOUBLE PRECISION, v_tasa_cambio)::character varying,
                v_fecha, p_cod_usuario
            );
        END LOOP;
    END IF;

    -- 5. Actualizar inventario (para PEDIDO, NOTA_ENTREGA)
    IF p_actualizar_inventario AND p_tipo_operacion IN ('PEDIDO', 'NOTA_ENTREGA') THEN
        -- Descontar inventario
        UPDATE "Inventario" i SET
            "EXISTENCIA" = COALESCE(i."EXISTENCIA", 0) - t."TOTAL_CANT"
        FROM (
            SELECT "COD_SERV", SUM("CANTIDAD") AS "TOTAL_CANT"
            FROM _detalle_temp
            WHERE "COD_SERV" IS NOT NULL
            GROUP BY "COD_SERV"
        ) t
        WHERE i."CODIGO" = t."COD_SERV";

        -- Registrar movimiento
        INSERT INTO "MovInvent" (
            "CODIGO", "PRODUCT", "DOCUMENTO", "FECHA", "MOTIVO", "TIPO",
            "CANTIDAD_ACTUAL", "CANTIDAD", "CANTIDAD_NUEVA", "CO_USUARIO",
            "PRECIO_COMPRA", "ALICUOTA", "PRECIO_VENTA"
        )
        SELECT
            d."COD_SERV", d."COD_SERV", v_num_doc, v_fecha,
            p_tipo_operacion || ':' || v_num_doc,
            CASE p_tipo_operacion WHEN 'NOTACRED' THEN 'Ingreso' ELSE 'Egreso' END,
            COALESCE(i."EXISTENCIA", 0) + d."CANTIDAD" * CASE WHEN p_tipo_operacion = 'NOTACRED' THEN -1 ELSE 1 END,
            d."CANTIDAD",
            COALESCE(i."EXISTENCIA", 0),
            p_cod_usuario,
            COALESCE(i."COSTO_REFERENCIA", i."ULTIMO_COSTO"),
            COALESCE(d."ALICUOTA", 0),
            d."PRECIO"
        FROM _detalle_temp d
        INNER JOIN "Inventario" i ON i."CODIGO" = d."COD_SERV"
        WHERE d."COD_SERV" IS NOT NULL;
    END IF;

    -- 6. Generar CxC (solo para FACT)
    IF p_generar_cxc AND p_tipo_operacion = 'FACT' THEN
        INSERT INTO "P_Cobrar" (
            "CODIGO", "FACTURA", "FECHA", "FECHA_VENCE", "TOTAL", "ABONO", "SALDO",
            "TIPO", "DOCUMENTO", "NUMERO", "REFERENCIA", "OBSERVACION",
            "FECHA_E", "COD_USUARIO", "SERIALTIPO", "ANULADA"
        )
        SELECT v_codigo, v_num_doc, v_fecha, v_fecha_vence, v_total, 0, v_total,
               p_tipo_operacion, v_serial_tipo, v_num_doc, v_num_control, v_observ,
               v_fecha, p_cod_usuario, v_serial_tipo, 0
        WHERE NOT EXISTS (SELECT 1 FROM "P_Cobrar" WHERE "FACTURA" = v_num_doc);
    END IF;

    -- 7. Actualizar documento origen si aplica
    IF v_doc_origen IS NOT NULL AND v_tipo_doc_origen IS NOT NULL THEN
        UPDATE "DocumentosVenta" SET
            "FACTURADA" = 'S',
            "DOC_ORIGEN" = v_doc_origen
        WHERE "NUM_DOC" = v_doc_origen AND "TIPO_OPERACION" = v_tipo_doc_origen;
    END IF;

    RETURN QUERY SELECT TRUE, v_num_doc, p_tipo_operacion, v_total, v_linea_count;
END;
$function$
;

-- sp_emitir_factura_tx
DROP FUNCTION IF EXISTS public.sp_emitir_factura_tx(jsonb, jsonb, jsonb, boolean, boolean, boolean) CASCADE;
DROP FUNCTION IF EXISTS public.sp_emitir_factura_tx(p_factura_json jsonb, p_detalle_json jsonb, p_formas_pago_json jsonb DEFAULT NULL::jsonb, p_actualizar_inventario boolean DEFAULT true, p_generar_cxc boolean DEFAULT true, p_actualizar_saldos_cliente boolean DEFAULT true)
 RETURNS TABLE(ok boolean, "numFact" character varying, "detalleRows" integer, "montoEfectivo" numeric, "montoCheque" numeric, "montoTarjeta" numeric, "saldoPendiente" numeric, abono numeric)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_num_fact        VARCHAR(60);
    v_codigo          VARCHAR(60);
    v_pago            VARCHAR(30);
    v_cod_usuario     VARCHAR(60);
    v_serial_tipo     VARCHAR(60);
    v_tipo_orden      VARCHAR(80);
    v_observ          VARCHAR(4000);
    v_fecha           TIMESTAMP;
    v_fecha_reporte   TIMESTAMP;
    v_total           NUMERIC(18,4);
    v_default_company_id INT := 1;
    v_default_branch_id  INT := 1;
    v_customer_id     BIGINT;
    v_memoria         VARCHAR(80);
    v_monto_efectivo  NUMERIC(18,4) := 0;
    v_monto_cheque    NUMERIC(18,4) := 0;
    v_monto_tarjeta   NUMERIC(18,4) := 0;
    v_saldo_pendiente NUMERIC(18,4) := 0;
    v_num_tarjeta     VARCHAR(60) := '0';
    v_cta             VARCHAR(80) := ' ';
    v_banco_cheque    VARCHAR(120) := ' ';
    v_banco_tarjeta   VARCHAR(120) := ' ';
    v_abono           NUMERIC(18,4);
    v_cancelada       CHAR(1);
    v_detalle_rows    INT;
BEGIN
    -- Parsear cabecera
    v_num_fact     := NULLIF(TRIM(p_factura_json->>'NUM_FACT'), '');
    v_codigo       := NULLIF(TRIM(p_factura_json->>'CODIGO'), '');
    v_pago         := UPPER(COALESCE(NULLIF(TRIM(p_factura_json->>'PAGO'), ''), '')::character varying)::character varying;
    v_cod_usuario  := COALESCE(NULLIF(TRIM(p_factura_json->>'COD_USUARIO'), ''), 'API')::character varying;
    v_serial_tipo  := COALESCE(NULLIF(TRIM(p_factura_json->>'SERIALTIPO'), ''), '')::character varying;
    v_tipo_orden   := COALESCE(NULLIF(TRIM(p_factura_json->>'TIPO_ORDEN'), ''), '1')::character varying;
    v_observ       := NULLIF(TRIM(p_factura_json->>'OBSERV'), '');

    BEGIN
        v_fecha := (p_factura_json->>'FECHA')::TIMESTAMP;
    EXCEPTION WHEN OTHERS THEN
        v_fecha := NOW() AT TIME ZONE 'UTC';
    END;

    BEGIN
        v_fecha_reporte := (p_factura_json->>'FECHA_REPORTE')::TIMESTAMP;
    EXCEPTION WHEN OTHERS THEN
        v_fecha_reporte := v_fecha;
    END;

    v_total := COALESCE((p_factura_json->>'TOTAL')::NUMERIC(18,4), 0);

    IF v_num_fact IS NULL OR TRIM(v_num_fact) = '' THEN
        RAISE EXCEPTION 'missing_num_fact';
    END IF;

    -- Resolver IDs canonicos
    SELECT "CompanyId" INTO v_default_company_id
      FROM cfg."Company" WHERE "CompanyCode" = 'DEFAULT' LIMIT 1;
    v_default_company_id := COALESCE(v_default_company_id, 1);

    SELECT "BranchId" INTO v_default_branch_id
      FROM cfg."Branch" WHERE "CompanyId" = v_default_company_id AND "BranchCode" = 'MAIN' LIMIT 1;
    v_default_branch_id := COALESCE(v_default_branch_id, 1);

    IF v_codigo IS NOT NULL THEN
        SELECT "CustomerId" INTO v_customer_id
          FROM master."Customer"
         WHERE "CustomerCode" = v_codigo AND COALESCE("IsDeleted", FALSE) = FALSE
         LIMIT 1;
    END IF;

    -- 1. Cabecera -> ar."SalesDocument"
    INSERT INTO ar."SalesDocument" (
        "DocumentNumber", "SerialType", "FiscalMemoryNumber", "OperationType",
        "CustomerCode", "DocumentDate", "ReportDate", "PaymentTerms",
        "TotalAmount", "UserCode", "Notes"
    )
    VALUES (
        v_num_fact, v_serial_tipo, v_tipo_orden, 'FACT',
        v_codigo, v_fecha, v_fecha_reporte, v_pago,
        v_total, v_cod_usuario, v_observ
    );

    -- 2. Detalle -> ar."SalesDocumentLine"
    INSERT INTO ar."SalesDocumentLine" (
        "DocumentNumber", "SerialType", "FiscalMemoryNumber", "OperationType",
        "ProductCode", "Quantity", "UnitPrice", "TaxRate", "TotalAmount",
        "DiscountedPrice", "RelatedRef", "AlternateCode"
    )
    SELECT
        COALESCE(NULLIF(TRIM(row_data->>'NUM_FACT'), ''), v_num_fact)::character varying,
        COALESCE(NULLIF(TRIM(row_data->>'SERIALTIPO'), ''), v_serial_tipo)::character varying,
        v_tipo_orden, 'FACT',
        NULLIF(TRIM(row_data->>'COD_SERV'), ''),
        COALESCE((row_data->>'CANTIDAD')::NUMERIC(18,4), 0),
        COALESCE((row_data->>'PRECIO')::NUMERIC(18,4), 0),
        COALESCE((row_data->>'ALICUOTA')::NUMERIC(18,4), 0),
        COALESCE(
            (row_data->>'TOTAL')::NUMERIC(18,4),
            COALESCE((row_data->>'PRECIO')::NUMERIC(18,4), 0) * COALESCE((row_data->>'CANTIDAD')::NUMERIC(18,4), 0)
        ),
        COALESCE(
            (row_data->>'PRECIO_DESCUENTO')::NUMERIC(18,4),
            COALESCE((row_data->>'PRECIO')::NUMERIC(18,4), 0)
        ),
        COALESCE(NULLIF(TRIM(row_data->>'RELACIONADA'), ''), '0')::character varying,
        NULLIF(TRIM(row_data->>'COD_ALTERNO'), '')
    FROM jsonb_array_elements(p_detalle_json) AS row_data;

    -- Contar filas de detalle
    SELECT COUNT(*) INTO v_detalle_rows FROM jsonb_array_elements(p_detalle_json);

    -- 3. Formas de pago
    v_memoria := v_tipo_orden;

    IF p_formas_pago_json IS NOT NULL THEN
        -- Eliminar pagos previos
        DELETE FROM ar."SalesDocumentPayment"
         WHERE "DocumentNumber" = v_num_fact AND "OperationType" = 'FACT';

        -- Insertar pagos
        INSERT INTO ar."SalesDocumentPayment" (
            "ExchangeRate", "PaymentMethod", "DocumentNumber", "Amount",
            "BankCode", "ReferenceNumber", "PaymentDate", "PaymentNumber",
            "FiscalMemoryNumber", "SerialType", "OperationType"
        )
        SELECT
            COALESCE((fp->>'tasacambio')::NUMERIC(18,6), 1),
            NULLIF(TRIM(fp->>'tipo'), ''),
            v_num_fact,
            COALESCE((fp->>'monto')::NUMERIC(18,4), 0),
            COALESCE(NULLIF(TRIM(fp->>'banco'), ''), ' ')::character varying,
            COALESCE(NULLIF(TRIM(fp->>'cuenta'), ''), ' ')::character varying,
            v_fecha,
            COALESCE(NULLIF(TRIM(fp->>'numero'), ''), '0')::character varying,
            v_memoria, v_serial_tipo, 'FACT'
        FROM jsonb_array_elements(p_formas_pago_json) AS fp;

        -- Calcular resumen de pagos
        SELECT
            COALESCE(SUM(CASE WHEN UPPER(COALESCE(NULLIF(TRIM(fp->>'tipo'), ''), ''))::character varying = 'EFECTIVO' THEN COALESCE((fp->>'monto')::NUMERIC(18,4), 0) ELSE 0 END), 0)::character varying,
            COALESCE(SUM(CASE WHEN UPPER(COALESCE(NULLIF(TRIM(fp->>'tipo'), ''), ''))::character varying = 'CHEQUE' THEN COALESCE((fp->>'monto')::NUMERIC(18,4), 0) ELSE 0 END), 0)::character varying,
            COALESCE(SUM(CASE WHEN UPPER(COALESCE(NULLIF(TRIM(fp->>'tipo'), ''), ''))::character varying LIKE 'TARJETA%' OR UPPER(COALESCE(NULLIF(TRIM(fp->>'tipo'), ''), ''))::character varying LIKE 'TICKET%' THEN COALESCE((fp->>'monto')::NUMERIC(18,4), 0) ELSE 0 END), 0)::character varying,
            COALESCE(SUM(CASE WHEN UPPER(COALESCE(NULLIF(TRIM(fp->>'tipo'), ''), ''))::character varying = 'SALDO PENDIENTE' THEN COALESCE((fp->>'monto')::NUMERIC(18,4), 0) ELSE 0 END), 0)::character varying
        INTO v_monto_efectivo, v_monto_cheque, v_monto_tarjeta, v_saldo_pendiente
        FROM jsonb_array_elements(p_formas_pago_json) AS fp;

        -- Depositos cheque -> acct."BankDeposit"
        INSERT INTO acct."BankDeposit" ("Amount", "CheckNumber", "BankAccount", "CustomerCode", "IsRelated", "BankName", "DocumentRef", "OperationType")
        SELECT
            COALESCE((fp->>'monto')::NUMERIC(18,4), 0),
            COALESCE(NULLIF(TRIM(fp->>'numero'), ''), '0')::character varying,
            COALESCE(NULLIF(TRIM(fp->>'cuenta'), ''), ' ')::character varying,
            v_codigo, FALSE,
            COALESCE(NULLIF(TRIM(fp->>'banco'), ''), ' ')::character varying,
            v_num_fact, 'FACT'
        FROM jsonb_array_elements(p_formas_pago_json) AS fp
        WHERE UPPER(COALESCE(NULLIF(TRIM(fp->>'tipo'), ''), '')::character varying)::character varying = 'CHEQUE';
    END IF;

    v_abono := v_total - v_saldo_pendiente;
    v_cancelada := CASE WHEN v_saldo_pendiente > 0 THEN 'N' ELSE 'S' END;

    -- Actualizar estado en ar."SalesDocument"
    UPDATE ar."SalesDocument"
       SET "IsPaid" = v_cancelada,
           "ReportDate" = v_fecha_reporte,
           "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
     WHERE "DocumentNumber" = v_num_fact AND "OperationType" = 'FACT';

    -- 4. CxC -> ar."ReceivableDocument"
    IF p_generar_cxc AND v_customer_id IS NOT NULL AND (v_pago = 'CREDITO' OR v_saldo_pendiente > 0) THEN
        DELETE FROM ar."ReceivableDocument"
         WHERE "CompanyId" = v_default_company_id AND "BranchId" = v_default_branch_id
           AND "DocumentType" = 'FACT' AND "DocumentNumber" = v_num_fact;

        INSERT INTO ar."ReceivableDocument" (
            "CompanyId", "BranchId", "CustomerId", "DocumentType", "DocumentNumber",
            "IssueDate", "CurrencyCode", "TotalAmount", "PendingAmount",
            "PaidFlag", "Status"
        )
        VALUES (
            v_default_company_id, v_default_branch_id, v_customer_id, 'FACT', v_num_fact,
            v_fecha::DATE, 'VES', v_saldo_pendiente, v_saldo_pendiente,
            0, 'PENDING'
        );
    END IF;

    -- 5. Inventario -> master."Product" + master."InventoryMovement"
    IF p_actualizar_inventario THEN
        -- Movimientos -> master."InventoryMovement"
        INSERT INTO master."InventoryMovement" ("CompanyId", "ProductCode", "DocumentRef", "MovementType", "MovementDate", "Quantity", "UnitCost", "TotalCost", "Notes")
        SELECT
            v_default_company_id,
            NULLIF(TRIM(d->>'COD_SERV'), ''),
            v_num_fact, 'SALIDA', v_fecha::DATE,
            COALESCE((d->>'CANTIDAD')::NUMERIC(18,4), 0),
            COALESCE(i."COSTO_REFERENCIA", 0),
            COALESCE((d->>'CANTIDAD')::NUMERIC(18,4), 0) * COALESCE(i."COSTO_REFERENCIA", 0),
            'Doc:' || v_num_fact
        FROM jsonb_array_elements(p_detalle_json) AS d
        INNER JOIN master."Product" i ON i."ProductCode" = NULLIF(TRIM(d->>'COD_SERV'), '')
        WHERE NULLIF(TRIM(d->>'COD_SERV'), '') IS NOT NULL
          AND COALESCE((d->>'CANTIDAD')::NUMERIC(18,4), 0) > 0;

        -- Descontar stock -> master."Product"."StockQty"
        UPDATE master."Product" AS p
           SET "StockQty" = COALESCE(p."StockQty", 0) - agg."Total"
          FROM (
              SELECT NULLIF(TRIM(d->>'COD_SERV'), '') AS cod_serv, SUM(COALESCE((d->>'CANTIDAD')::NUMERIC(18,4), 0)) AS "Total"
                FROM jsonb_array_elements(p_detalle_json) AS d
               GROUP BY NULLIF(TRIM(d->>'COD_SERV'), '')
          ) agg
         WHERE p."ProductCode" = agg.cod_serv;

        -- Stock auxiliar -> master."AlternateStock"
        UPDATE master."AlternateStock" AS a
           SET "StockQty" = COALESCE(a."StockQty", 0) - agg."Total"
          FROM (
              SELECT NULLIF(TRIM(d->>'COD_ALTERNO'), '') AS cod_alterno, SUM(COALESCE((d->>'CANTIDAD')::NUMERIC(18,4), 0)) AS "Total"
                FROM jsonb_array_elements(p_detalle_json) AS d
               WHERE COALESCE((d->>'RELACIONADA')::INT, 0) = 1
               GROUP BY NULLIF(TRIM(d->>'COD_ALTERNO'), '')
          ) agg
         WHERE a."ProductCode" = agg.cod_alterno;
    END IF;

    -- 6. Saldos del cliente -> master."Customer"."TotalBalance"
    IF p_actualizar_saldos_cliente AND v_customer_id IS NOT NULL THEN
        UPDATE master."Customer"
           SET "TotalBalance" = COALESCE((
               SELECT SUM("PendingAmount")
                 FROM ar."ReceivableDocument"
                WHERE "CustomerId" = v_customer_id AND "Status" <> 'VOIDED' AND "PaidFlag" = 0
           ), 0)
         WHERE "CustomerId" = v_customer_id AND COALESCE("IsDeleted", FALSE) = FALSE;
    END IF;

    RETURN QUERY SELECT
        TRUE AS "ok",
        v_num_fact AS "numFact",
        v_detalle_rows AS "detalleRows",
        v_monto_efectivo AS "montoEfectivo",
        v_monto_cheque AS "montoCheque",
        v_monto_tarjeta AS "montoTarjeta",
        v_saldo_pendiente AS "saldoPendiente",
        v_abono AS "abono";

EXCEPTION WHEN OTHERS THEN
    RAISE EXCEPTION '%', SQLERRM;
END;
$function$
;

-- sp_emitir_pedido_tx
DROP FUNCTION IF EXISTS public.sp_emitir_pedido_tx(jsonb, jsonb, boolean, character varying) CASCADE;
DROP FUNCTION IF EXISTS public.sp_emitir_pedido_tx(p_pedido_json jsonb, p_detalle_json jsonb, p_actualizar_inventario boolean DEFAULT true, p_cod_usuario character varying DEFAULT 'API'::character varying)
 RETURNS TABLE(ok boolean, "numPedido" character varying, "detalleRows" integer, "inventoryUpdated" boolean)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_num_fact      VARCHAR(60);
    v_codigo        VARCHAR(60);
    v_fecha         TIMESTAMP;
    v_total         NUMERIC(18,4);
    v_nombre        VARCHAR(200);
    v_serial_tipo   VARCHAR(60);
    v_vendedor      VARCHAR(60);
    v_detalle_rows  INT;
BEGIN
    v_num_fact    := NULLIF(TRIM(p_pedido_json->>'NUM_FACT'), '');
    v_codigo      := NULLIF(TRIM(p_pedido_json->>'CODIGO'), '');
    v_nombre      := COALESCE(NULLIF(TRIM(p_pedido_json->>'NOMBRE'), ''), '')::character varying;
    v_serial_tipo := COALESCE(NULLIF(TRIM(p_pedido_json->>'SERIALTIPO'), ''), '')::character varying;
    v_vendedor    := COALESCE(NULLIF(TRIM(p_pedido_json->>'Vendedor'), ''), '')::character varying;

    BEGIN
        v_fecha := (p_pedido_json->>'FECHA')::TIMESTAMP;
    EXCEPTION WHEN OTHERS THEN
        v_fecha := NOW() AT TIME ZONE 'UTC';
    END;

    v_total := COALESCE((p_pedido_json->>'TOTAL')::NUMERIC(18,4), 0);

    IF v_num_fact IS NULL OR TRIM(v_num_fact) = '' THEN
        RAISE EXCEPTION 'missing_num_pedido';
    END IF;

    -- Verificar que el pedido no existe (tabla legacy "Pedidos")
    IF EXISTS (SELECT 1 FROM "Pedidos" WHERE "NUM_FACT" = v_num_fact) THEN
        RAISE EXCEPTION 'pedido_already_exists';
    END IF;

    -- 1. Insertar cabecera en Pedidos (legacy)
    INSERT INTO "Pedidos" (
        "NUM_FACT", "SERIALTIPO", "CODIGO", "FECHA", "NOMBRE", "TOTAL",
        "COD_USUARIO", "ANULADA", "FECHA_REPORTE", "CANCELADA", "Vendedor"
    )
    VALUES (
        v_num_fact, v_serial_tipo, v_codigo, v_fecha, v_nombre, v_total,
        p_cod_usuario, 0, v_fecha, 'N', v_vendedor
    );

    -- 2. Insertar detalle en Detalle_Pedidos (legacy)
    INSERT INTO "Detalle_Pedidos" (
        "NUM_FACT", "SERIALTIPO", "COD_SERV", "DESCRIPCION", "FECHA", "CANTIDAD",
        "PRECIO", "TOTAL", "ANULADA", "Co_Usuario", "Alicuota", "PRECIO_DESCUENTO",
        "Relacionada", "RENGLON", "Vendedor", "Cod_alterno"
    )
    SELECT
        v_num_fact,
        COALESCE(NULLIF(TRIM(d->>'SERIALTIPO'), ''), v_serial_tipo)::character varying,
        NULLIF(TRIM(d->>'COD_SERV'), ''),
        NULLIF(TRIM(d->>'DESCRIPCION'), ''),
        v_fecha,
        COALESCE((d->>'CANTIDAD')::DOUBLE PRECISION, 0),
        COALESCE((d->>'PRECIO')::DOUBLE PRECISION, 0),
        COALESCE(
            (d->>'TOTAL')::DOUBLE PRECISION,
            COALESCE((d->>'PRECIO')::DOUBLE PRECISION, 0) * COALESCE((d->>'CANTIDAD')::DOUBLE PRECISION, 0)
        ),
        0,
        p_cod_usuario,
        COALESCE((d->>'Alicuota')::DOUBLE PRECISION, 0),
        COALESCE(
            (d->>'PRECIO_DESCUENTO')::DOUBLE PRECISION,
            COALESCE((d->>'PRECIO')::DOUBLE PRECISION, 0)
        ),
        COALESCE(NULLIF(TRIM(d->>'Relacionada'), ''), '0')::character varying,
        COALESCE((d->>'RENGLON')::DOUBLE PRECISION, 0),
        COALESCE(NULLIF(TRIM(d->>'Vendedor'), ''), v_vendedor)::character varying,
        NULLIF(TRIM(d->>'Cod_alterno'), '')
    FROM jsonb_array_elements(p_detalle_json) AS d;

    -- Contar filas de detalle
    SELECT COUNT(*) INTO v_detalle_rows FROM jsonb_array_elements(p_detalle_json);

    -- 3. Comprometer inventario en master."Product"
    IF p_actualizar_inventario THEN
        -- MovInvent (historial)
        INSERT INTO "MovInvent" (
            "DOCUMENTO", "CODIGO", "PRODUCT", "FECHA", "MOTIVO", "TIPO",
            "CANTIDAD_ACTUAL", "CANTIDAD", "CANTIDAD_NUEVA", "CO_USUARIO",
            "PRECIO_COMPRA", "ALICUOTA", "PRECIO_VENTA"
        )
        SELECT
            v_num_fact,
            NULLIF(TRIM(d->>'COD_SERV'), ''),
            NULLIF(TRIM(d->>'COD_SERV'), ''),
            v_fecha,
            'Pedido:' || v_num_fact,
            'Pedido',
            COALESCE(inv."StockQty", 0),
            COALESCE((d->>'CANTIDAD')::NUMERIC(18,4), 0),
            COALESCE(inv."StockQty", 0) - COALESCE((d->>'CANTIDAD')::NUMERIC(18,4), 0),
            p_cod_usuario,
            COALESCE(inv."COSTO_REFERENCIA", 0),
            COALESCE((d->>'ALICUOTA')::NUMERIC(18,4), 0),
            COALESCE((d->>'PRECIO')::NUMERIC(18,4), 0)
        FROM jsonb_array_elements(p_detalle_json) AS d
        INNER JOIN master."Product" inv ON inv."ProductCode" = NULLIF(TRIM(d->>'COD_SERV'), '')
        WHERE NULLIF(TRIM(d->>'COD_SERV'), '') IS NOT NULL
          AND COALESCE((d->>'CANTIDAD')::NUMERIC(18,4), 0) > 0;

        -- Descontar existencias en master."Product"."StockQty"
        UPDATE master."Product" AS p
           SET "StockQty" = COALESCE(p."StockQty", 0) - agg."Total"
          FROM (
              SELECT NULLIF(TRIM(d->>'COD_SERV'), '') AS cod_serv,
                     SUM(COALESCE((d->>'CANTIDAD')::NUMERIC(18,4), 0)) AS "Total"
                FROM jsonb_array_elements(p_detalle_json) AS d
               WHERE NULLIF(TRIM(d->>'COD_SERV'), '') IS NOT NULL
               GROUP BY NULLIF(TRIM(d->>'COD_SERV'), '')
          ) agg
         WHERE p."ProductCode" = agg.cod_serv;
    END IF;

    RETURN QUERY SELECT
        TRUE AS "ok",
        v_num_fact AS "numPedido",
        v_detalle_rows AS "detalleRows",
        p_actualizar_inventario AS "inventoryUpdated";

EXCEPTION WHEN OTHERS THEN
    RAISE EXCEPTION '%', SQLERRM;
END;
$function$
;

-- sp_emitir_presupuesto_tx
DROP FUNCTION IF EXISTS public.sp_emitir_presupuesto_tx(jsonb, jsonb, jsonb, boolean, boolean, boolean) CASCADE;
DROP FUNCTION IF EXISTS public.sp_emitir_presupuesto_tx(p_presupuesto_json jsonb, p_detalle_json jsonb, p_formas_pago_json jsonb DEFAULT NULL::jsonb, p_actualizar_inventario boolean DEFAULT true, p_generar_cxc boolean DEFAULT true, p_actualizar_saldos_cliente boolean DEFAULT true)
 RETURNS TABLE(ok boolean, "numFact" character varying, "detalleRows" integer, "montoEfectivo" numeric, "montoCheque" numeric, "montoTarjeta" numeric, "saldoPendiente" numeric, abono numeric)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_num_fact        VARCHAR(60);
    v_codigo          VARCHAR(60);
    v_pago            VARCHAR(30);
    v_cod_usuario     VARCHAR(60);
    v_serial_tipo     VARCHAR(60);
    v_tipo_orden      VARCHAR(80);
    v_observ          VARCHAR(4000);
    v_fecha           TIMESTAMP;
    v_fecha_reporte   TIMESTAMP;
    v_total           NUMERIC(18,4);
    v_default_company_id INT := 1;
    v_default_branch_id  INT := 1;
    v_customer_id     BIGINT;
    v_memoria         VARCHAR(80);
    v_monto_efectivo  NUMERIC(18,4) := 0;
    v_monto_cheque    NUMERIC(18,4) := 0;
    v_monto_tarjeta   NUMERIC(18,4) := 0;
    v_saldo_pendiente NUMERIC(18,4) := 0;
    v_num_tarjeta     VARCHAR(60) := '0';
    v_cta             VARCHAR(80) := ' ';
    v_banco_cheque    VARCHAR(120) := ' ';
    v_banco_tarjeta   VARCHAR(120) := ' ';
    v_abono           NUMERIC(18,4);
    v_cancelada       CHAR(1);
    v_detalle_rows    INT;
BEGIN
    -- Parsear cabecera (soporta nodos presupuesto y factura por compat)
    v_num_fact := COALESCE(NULLIF(TRIM(p_presupuesto_json->>'NUM_FACT'), ''), NULL)::character varying;
    v_codigo := NULLIF(TRIM(p_presupuesto_json->>'CODIGO'), '');
    v_pago := UPPER(COALESCE(NULLIF(TRIM(p_presupuesto_json->>'PAGO'), ''), '')::character varying)::character varying;
    v_cod_usuario := COALESCE(NULLIF(TRIM(p_presupuesto_json->>'COD_USUARIO'), ''), 'API')::character varying;
    v_serial_tipo := COALESCE(NULLIF(TRIM(p_presupuesto_json->>'SERIALTIPO'), ''), '')::character varying;
    v_tipo_orden := COALESCE(NULLIF(TRIM(p_presupuesto_json->>'TIPO_ORDEN'), ''),
                    COALESCE(NULLIF(TRIM(p_presupuesto_json->>'Tipo_orden'), ''), '1'))::character varying;
    v_observ := NULLIF(TRIM(p_presupuesto_json->>'OBSERV'), '');

    BEGIN
        v_fecha := (p_presupuesto_json->>'FECHA')::TIMESTAMP;
    EXCEPTION WHEN OTHERS THEN
        v_fecha := NOW() AT TIME ZONE 'UTC';
    END;

    BEGIN
        v_fecha_reporte := (p_presupuesto_json->>'FECHA_REPORTE')::TIMESTAMP;
    EXCEPTION WHEN OTHERS THEN
        v_fecha_reporte := v_fecha;
    END;

    v_total := COALESCE((p_presupuesto_json->>'TOTAL')::NUMERIC(18,4), 0);

    IF v_num_fact IS NULL OR TRIM(v_num_fact) = '' THEN
        RAISE EXCEPTION 'missing_num_fact';
    END IF;

    -- Resolver IDs canonicos
    SELECT "CompanyId" INTO v_default_company_id
      FROM cfg."Company" WHERE "CompanyCode" = 'DEFAULT' LIMIT 1;
    v_default_company_id := COALESCE(v_default_company_id, 1);

    SELECT "BranchId" INTO v_default_branch_id
      FROM cfg."Branch" WHERE "CompanyId" = v_default_company_id AND "BranchCode" = 'MAIN' LIMIT 1;
    v_default_branch_id := COALESCE(v_default_branch_id, 1);

    IF v_codigo IS NOT NULL THEN
        SELECT "CustomerId" INTO v_customer_id
          FROM master."Customer"
         WHERE "CustomerCode" = v_codigo AND COALESCE("IsDeleted", FALSE) = FALSE
         LIMIT 1;
    END IF;

    -- 1. Cabecera -> ar."SalesDocument" (OperationType='PRESUP')
    INSERT INTO ar."SalesDocument" (
        "DocumentNumber", "SerialType", "FiscalMemoryNumber", "OperationType",
        "CustomerCode", "DocumentDate", "ReportDate", "PaymentTerms",
        "TotalAmount", "UserCode", "Notes"
    )
    VALUES (
        v_num_fact, v_serial_tipo, v_tipo_orden, 'PRESUP',
        v_codigo, v_fecha, v_fecha_reporte, v_pago,
        v_total, v_cod_usuario, v_observ
    );

    -- 2. Detalle -> ar."SalesDocumentLine"
    INSERT INTO ar."SalesDocumentLine" (
        "DocumentNumber", "SerialType", "FiscalMemoryNumber", "OperationType",
        "ProductCode", "Quantity", "UnitPrice", "TaxRate", "TotalAmount",
        "DiscountedPrice", "RelatedRef", "AlternateCode"
    )
    SELECT
        COALESCE(NULLIF(TRIM(d->>'NUM_FACT'), ''), v_num_fact)::character varying,
        COALESCE(NULLIF(TRIM(d->>'SERIALTIPO'), ''), v_serial_tipo)::character varying,
        v_tipo_orden, 'PRESUP',
        NULLIF(TRIM(d->>'COD_SERV'), ''),
        COALESCE((d->>'CANTIDAD')::NUMERIC(18,4), 0),
        COALESCE((d->>'PRECIO')::NUMERIC(18,4), 0),
        COALESCE((d->>'ALICUOTA')::NUMERIC(18,4), 0),
        COALESCE(
            (d->>'TOTAL')::NUMERIC(18,4),
            COALESCE((d->>'PRECIO')::NUMERIC(18,4), 0) * COALESCE((d->>'CANTIDAD')::NUMERIC(18,4), 0)
        ),
        COALESCE(
            (d->>'PRECIO_DESCUENTO')::NUMERIC(18,4),
            COALESCE((d->>'PRECIO')::NUMERIC(18,4), 0)
        ),
        COALESCE(NULLIF(TRIM(d->>'RELACIONADA'), ''), '0')::character varying,
        NULLIF(TRIM(d->>'COD_ALTERNO'), '')
    FROM jsonb_array_elements(p_detalle_json) AS d;

    SELECT COUNT(*) INTO v_detalle_rows FROM jsonb_array_elements(p_detalle_json);

    -- 3. Formas de pago
    v_memoria := v_tipo_orden;

    IF p_formas_pago_json IS NOT NULL THEN
        DELETE FROM ar."SalesDocumentPayment"
         WHERE "DocumentNumber" = v_num_fact
           AND "FiscalMemoryNumber" = v_memoria
           AND "SerialType" = v_serial_tipo
           AND "OperationType" = 'PRESUP';

        INSERT INTO ar."SalesDocumentPayment" (
            "ExchangeRate", "PaymentMethod", "DocumentNumber", "Amount",
            "BankCode", "ReferenceNumber", "PaymentDate", "PaymentNumber",
            "FiscalMemoryNumber", "SerialType", "OperationType"
        )
        SELECT
            COALESCE((fp->>'tasacambio')::NUMERIC(18,6), 1),
            NULLIF(TRIM(fp->>'tipo'), ''),
            v_num_fact,
            COALESCE((fp->>'monto')::NUMERIC(18,4), 0),
            COALESCE(NULLIF(TRIM(fp->>'banco'), ''), ' ')::character varying,
            COALESCE(NULLIF(TRIM(fp->>'cuenta'), ''), ' ')::character varying,
            v_fecha,
            COALESCE(NULLIF(TRIM(fp->>'numero'), ''), '0')::character varying,
            v_memoria, v_serial_tipo, 'PRESUP'
        FROM jsonb_array_elements(p_formas_pago_json) AS fp;

        SELECT
            COALESCE(SUM(CASE WHEN UPPER(COALESCE(fp->>'tipo',''))::character varying = 'EFECTIVO' THEN COALESCE((fp->>'monto')::NUMERIC(18,4), 0) ELSE 0 END), 0),
            COALESCE(SUM(CASE WHEN UPPER(COALESCE(fp->>'tipo',''))::character varying = 'CHEQUE' THEN COALESCE((fp->>'monto')::NUMERIC(18,4), 0) ELSE 0 END), 0),
            COALESCE(SUM(CASE WHEN UPPER(COALESCE(fp->>'tipo',''))::character varying LIKE 'TARJETA%' OR UPPER(COALESCE(fp->>'tipo',''))::character varying LIKE 'TICKET%' THEN COALESCE((fp->>'monto')::NUMERIC(18,4), 0) ELSE 0 END), 0),
            COALESCE(SUM(CASE WHEN UPPER(COALESCE(fp->>'tipo',''))::character varying = 'SALDO PENDIENTE' THEN COALESCE((fp->>'monto')::NUMERIC(18,4), 0) ELSE 0 END), 0)
        INTO v_monto_efectivo, v_monto_cheque, v_monto_tarjeta, v_saldo_pendiente
        FROM jsonb_array_elements(p_formas_pago_json) AS fp;

        -- Depositos cheque
        INSERT INTO acct."BankDeposit" ("Amount", "CheckNumber", "BankAccount", "CustomerCode", "IsRelated", "BankName", "DocumentRef", "OperationType")
        SELECT
            COALESCE((fp->>'monto')::NUMERIC(18,4), 0),
            COALESCE(NULLIF(TRIM(fp->>'numero'), ''), '0')::character varying,
            COALESCE(NULLIF(TRIM(fp->>'cuenta'), ''), ' ')::character varying,
            v_codigo, FALSE,
            COALESCE(NULLIF(TRIM(fp->>'banco'), ''), ' ')::character varying,
            v_num_fact, 'PRESUP'
        FROM jsonb_array_elements(p_formas_pago_json) AS fp
        WHERE UPPER(COALESCE(fp->>'tipo', ''))::character varying = 'CHEQUE';
    END IF;

    v_abono := v_total - v_saldo_pendiente;
    v_cancelada := CASE WHEN v_saldo_pendiente > 0 THEN 'N' ELSE 'S' END;

    UPDATE ar."SalesDocument"
       SET "IsPaid" = v_cancelada,
           "ReportDate" = v_fecha_reporte,
           "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
     WHERE "DocumentNumber" = v_num_fact AND "OperationType" = 'PRESUP';

    -- 4. CxC
    IF p_generar_cxc AND v_customer_id IS NOT NULL AND (v_pago = 'CREDITO' OR v_saldo_pendiente > 0) THEN
        DELETE FROM ar."ReceivableDocument"
         WHERE "CompanyId" = v_default_company_id AND "BranchId" = v_default_branch_id
           AND "DocumentType" = 'PRESUP' AND "DocumentNumber" = v_num_fact;

        INSERT INTO ar."ReceivableDocument" (
            "CompanyId", "BranchId", "CustomerId", "DocumentType", "DocumentNumber",
            "IssueDate", "CurrencyCode", "TotalAmount", "PendingAmount", "PaidFlag", "Status"
        )
        VALUES (
            v_default_company_id, v_default_branch_id, v_customer_id, 'PRESUP', v_num_fact,
            v_fecha::DATE, 'VES', v_saldo_pendiente, v_saldo_pendiente, 0, 'PENDING'
        );
    END IF;

    -- 5. Inventario
    IF p_actualizar_inventario THEN
        INSERT INTO master."InventoryMovement" ("CompanyId", "ProductCode", "DocumentRef", "MovementType", "MovementDate", "Quantity", "UnitCost", "TotalCost", "Notes")
        SELECT v_default_company_id, NULLIF(TRIM(d->>'COD_SERV'), ''), v_num_fact, 'SALIDA', v_fecha::DATE,
            COALESCE((d->>'CANTIDAD')::NUMERIC(18,4), 0),
            COALESCE(i."COSTO_REFERENCIA", 0),
            COALESCE((d->>'CANTIDAD')::NUMERIC(18,4), 0) * COALESCE(i."COSTO_REFERENCIA", 0),
            'Presup:' || v_num_fact
        FROM jsonb_array_elements(p_detalle_json) AS d
        INNER JOIN master."Product" i ON i."ProductCode" = NULLIF(TRIM(d->>'COD_SERV'), '')
        WHERE NULLIF(TRIM(d->>'COD_SERV'), '') IS NOT NULL AND COALESCE((d->>'CANTIDAD')::NUMERIC(18,4), 0) > 0;

        UPDATE master."Product" AS p
           SET "StockQty" = COALESCE(p."StockQty", 0) - agg."Total"
          FROM (
              SELECT NULLIF(TRIM(d->>'COD_SERV'), '') AS cod_serv, SUM(COALESCE((d->>'CANTIDAD')::NUMERIC(18,4), 0)) AS "Total"
                FROM jsonb_array_elements(p_detalle_json) AS d
               GROUP BY NULLIF(TRIM(d->>'COD_SERV'), '')
          ) agg
         WHERE p."ProductCode" = agg.cod_serv;

        UPDATE master."AlternateStock" AS a
           SET "StockQty" = COALESCE(a."StockQty", 0) - agg."Total"
          FROM (
              SELECT NULLIF(TRIM(d->>'COD_ALTERNO'), '') AS cod_alterno, SUM(COALESCE((d->>'CANTIDAD')::NUMERIC(18,4), 0)) AS "Total"
                FROM jsonb_array_elements(p_detalle_json) AS d
               WHERE COALESCE((d->>'RELACIONADA')::INT, 0) = 1
               GROUP BY NULLIF(TRIM(d->>'COD_ALTERNO'), '')
          ) agg
         WHERE a."ProductCode" = agg.cod_alterno;
    END IF;

    -- 6. Saldos
    IF p_actualizar_saldos_cliente AND v_customer_id IS NOT NULL THEN
        UPDATE master."Customer"
           SET "TotalBalance" = COALESCE((
               SELECT SUM("PendingAmount") FROM ar."ReceivableDocument"
                WHERE "CustomerId" = v_customer_id AND "Status" <> 'VOIDED' AND "PaidFlag" = 0
           ), 0)
         WHERE "CustomerId" = v_customer_id AND COALESCE("IsDeleted", FALSE) = FALSE;
    END IF;

    RETURN QUERY SELECT
        TRUE AS "ok",
        v_num_fact AS "numFact",
        v_detalle_rows AS "detalleRows",
        v_monto_efectivo AS "montoEfectivo",
        v_monto_cheque AS "montoCheque",
        v_monto_tarjeta AS "montoTarjeta",
        v_saldo_pendiente AS "saldoPendiente",
        v_abono AS "abono";

EXCEPTION WHEN OTHERS THEN
    RAISE EXCEPTION '%', SQLERRM;
END;
$function$
;

-- usp_compras_getbynumfact
DROP FUNCTION IF EXISTS public.usp_compras_getbynumfact(character varying) CASCADE;
DROP FUNCTION IF EXISTS public.usp_compras_getbynumfact(p_num_fact character varying)
 RETURNS TABLE("NUM_FACT" character varying, "FECHA" date, "COD_PROVEEDOR" character varying, "NOMBRE" character varying, "RIF" character varying, "TIPO" character varying, "MONTO" numeric, "IVA" numeric, "TOTAL" numeric)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        co."NUM_FACT",
        co."FECHA",
        co."COD_PROVEEDOR",
        co."NOMBRE",
        co."RIF",
        co."TIPO",
        co."MONTO",
        co."IVA",
        co."TOTAL"
    FROM public."Compras" co
    WHERE co."NUM_FACT" = p_num_fact;
END;
$function$
;

-- usp_compras_list
DROP FUNCTION IF EXISTS public.usp_compras_list(character varying, character varying, character varying, date, date, integer, integer) CASCADE;
DROP FUNCTION IF EXISTS public.usp_compras_list(p_search character varying DEFAULT NULL::character varying, p_proveedor character varying DEFAULT NULL::character varying, p_estado character varying DEFAULT NULL::character varying, p_fecha_desde date DEFAULT NULL::date, p_fecha_hasta date DEFAULT NULL::date, p_page integer DEFAULT 1, p_limit integer DEFAULT 50)
 RETURNS TABLE("NUM_FACT" character varying, "FECHA" date, "COD_PROVEEDOR" character varying, "NOMBRE" character varying, "RIF" character varying, "TIPO" character varying, "MONTO" numeric, "IVA" numeric, "TOTAL" numeric, "TotalCount" integer)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_offset INT;
    v_limit  INT;
    v_search VARCHAR(100);
    v_total  INT;
BEGIN
    v_limit  := COALESCE(NULLIF(p_limit, 0), 50);
    IF v_limit < 1  THEN v_limit := 50;  END IF;
    IF v_limit > 500 THEN v_limit := 500; END IF;

    v_offset := (COALESCE(NULLIF(p_page, 0), 1) - 1) * v_limit;
    IF v_offset < 0 THEN v_offset := 0; END IF;

    v_search := NULL;
    IF p_search IS NOT NULL AND TRIM(p_search) <> '' THEN
        v_search := '%' || p_search || '%';
    END IF;

    -- Conteo total
    SELECT COUNT(1) INTO v_total
    FROM public."Compras" co
    WHERE (v_search IS NULL OR (co."NUM_FACT" ILIKE v_search OR co."NOMBRE" ILIKE v_search OR co."RIF" ILIKE v_search))
      AND (p_proveedor IS NULL OR TRIM(p_proveedor) = '' OR co."COD_PROVEEDOR" = p_proveedor)
      AND (p_estado IS NULL OR TRIM(p_estado) = '' OR co."TIPO" = p_estado)
      AND (p_fecha_desde IS NULL OR co."FECHA" >= p_fecha_desde)
      AND (p_fecha_hasta IS NULL OR co."FECHA" <= p_fecha_hasta);

    -- Resultados paginados
    RETURN QUERY
    SELECT
        co."NUM_FACT",
        co."FECHA",
        co."COD_PROVEEDOR",
        co."NOMBRE",
        co."RIF",
        co."TIPO",
        co."MONTO",
        co."IVA",
        co."TOTAL",
        v_total AS "TotalCount"
    FROM public."Compras" co
    WHERE (v_search IS NULL OR (co."NUM_FACT" ILIKE v_search OR co."NOMBRE" ILIKE v_search OR co."RIF" ILIKE v_search))
      AND (p_proveedor IS NULL OR TRIM(p_proveedor) = '' OR co."COD_PROVEEDOR" = p_proveedor)
      AND (p_estado IS NULL OR TRIM(p_estado) = '' OR co."TIPO" = p_estado)
      AND (p_fecha_desde IS NULL OR co."FECHA" >= p_fecha_desde)
      AND (p_fecha_hasta IS NULL OR co."FECHA" <= p_fecha_hasta)
    ORDER BY co."FECHA" DESC
    LIMIT v_limit OFFSET v_offset;
END;
$function$
;

-- usp_cotizacion_getbynumfact
DROP FUNCTION IF EXISTS public.usp_cotizacion_getbynumfact(character varying) CASCADE;
DROP FUNCTION IF EXISTS public.usp_cotizacion_getbynumfact(p_num_fact character varying)
 RETURNS TABLE("NUM_FACT" character varying, "FECHA" date, "CODIGO" character varying, "NOMBRE" character varying, "RIF" character varying, "MONTO" numeric, "IVA" numeric, "TOTAL" numeric)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        ct."NUM_FACT",
        ct."FECHA",
        ct."CODIGO",
        ct."NOMBRE",
        ct."RIF",
        ct."MONTO",
        ct."IVA",
        ct."TOTAL"
    FROM public."Cotizacion" ct
    WHERE ct."NUM_FACT" = p_num_fact;
END;
$function$
;

-- usp_cotizacion_list
DROP FUNCTION IF EXISTS public.usp_cotizacion_list(character varying, character varying, integer, integer) CASCADE;
DROP FUNCTION IF EXISTS public.usp_cotizacion_list(p_search character varying DEFAULT NULL::character varying, p_codigo character varying DEFAULT NULL::character varying, p_page integer DEFAULT 1, p_limit integer DEFAULT 50)
 RETURNS TABLE("NUM_FACT" character varying, "FECHA" date, "CODIGO" character varying, "NOMBRE" character varying, "RIF" character varying, "MONTO" numeric, "IVA" numeric, "TOTAL" numeric, "TotalCount" integer)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_offset INT;
    v_limit  INT;
    v_search VARCHAR(100);
    v_total  INT;
BEGIN
    v_limit  := COALESCE(NULLIF(p_limit, 0), 50);
    IF v_limit < 1  THEN v_limit := 50;  END IF;
    IF v_limit > 500 THEN v_limit := 500; END IF;

    v_offset := (COALESCE(NULLIF(p_page, 0), 1) - 1) * v_limit;
    IF v_offset < 0 THEN v_offset := 0; END IF;

    v_search := NULL;
    IF p_search IS NOT NULL AND TRIM(p_search) <> '' THEN
        v_search := '%' || p_search || '%';
    END IF;

    -- Conteo total
    SELECT COUNT(1) INTO v_total
    FROM public."Cotizacion" ct
    WHERE (v_search IS NULL OR (ct."NUM_FACT" ILIKE v_search OR ct."NOMBRE" ILIKE v_search OR ct."RIF" ILIKE v_search))
      AND (p_codigo IS NULL OR TRIM(p_codigo) = '' OR ct."CODIGO" = p_codigo);

    -- Resultados paginados
    RETURN QUERY
    SELECT
        ct."NUM_FACT",
        ct."FECHA",
        ct."CODIGO",
        ct."NOMBRE",
        ct."RIF",
        ct."MONTO",
        ct."IVA",
        ct."TOTAL",
        v_total AS "TotalCount"
    FROM public."Cotizacion" ct
    WHERE (v_search IS NULL OR (ct."NUM_FACT" ILIKE v_search OR ct."NOMBRE" ILIKE v_search OR ct."RIF" ILIKE v_search))
      AND (p_codigo IS NULL OR TRIM(p_codigo) = '' OR ct."CODIGO" = p_codigo)
    ORDER BY ct."FECHA" DESC
    LIMIT v_limit OFFSET v_offset;
END;
$function$
;

-- usp_doc_purchasedocument_convertorder
DROP FUNCTION IF EXISTS public.usp_doc_purchasedocument_convertorder(character varying, character varying, jsonb, jsonb, character varying) CASCADE;
DROP FUNCTION IF EXISTS public.usp_doc_purchasedocument_convertorder(p_num_doc_orden character varying, p_num_doc_compra character varying, p_compra_override_json jsonb DEFAULT NULL::jsonb, p_detalle_json jsonb DEFAULT NULL::jsonb, p_cod_usuario character varying DEFAULT 'API'::character varying)
 RETURNS TABLE(ok boolean, orden character varying, compra character varying, "detalleRows" integer, "formasPagoRows" integer, "pendingAmount" double precision, mensaje character varying)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_ok              BOOLEAN := FALSE;
    v_detalle_rows    INT := 0;
    v_formas_pago_rows INT := 0;
    v_pending_amount  DOUBLE PRECISION := 0;
    v_total_amount    DOUBLE PRECISION;
    v_supplier_code   VARCHAR(60);
    v_is_paid         VARCHAR(1);
    v_doc_date        TIMESTAMP;
    v_notes           VARCHAR(500);
    v_company_id      INT;
    v_branch_id       INT;
    v_user_id         INT;
    v_supplier_id     BIGINT;
    v_safe_pending    DOUBLE PRECISION;
    v_status          VARCHAR(20);
    v_existing_id     BIGINT;
BEGIN
    -- Validate params
    IF p_num_doc_orden IS NULL OR TRIM(p_num_doc_orden) = '' THEN
        RETURN QUERY SELECT FALSE, p_num_doc_orden, p_num_doc_compra, 0, 0, 0::DOUBLE PRECISION,
                     'Numero de orden requerido (@NumDocOrden)'::VARCHAR;
        RETURN;
    END IF;

    IF p_num_doc_compra IS NULL OR TRIM(p_num_doc_compra) = '' THEN
        RETURN QUERY SELECT FALSE, p_num_doc_orden, p_num_doc_compra, 0, 0, 0::DOUBLE PRECISION,
                     'Numero de compra requerido (@NumDocCompra)'::VARCHAR;
        RETURN;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM doc."PurchaseDocument" WHERE "DocumentNumber" = p_num_doc_orden AND "DocumentType" = 'ORDEN' AND "IsDeleted" = FALSE) THEN
        RETURN QUERY SELECT FALSE, p_num_doc_orden, p_num_doc_compra, 0, 0, 0::DOUBLE PRECISION,
                     ('Orden de compra no encontrada: ' || p_num_doc_orden)::VARCHAR;
        RETURN;
    END IF;

    IF EXISTS (SELECT 1 FROM doc."PurchaseDocument" WHERE "DocumentNumber" = p_num_doc_orden AND "DocumentType" = 'ORDEN' AND "IsDeleted" = FALSE AND "IsVoided" = TRUE) THEN
        RETURN QUERY SELECT FALSE, p_num_doc_orden, p_num_doc_compra, 0, 0, 0::DOUBLE PRECISION,
                     ('La orden esta anulada y no puede convertirse: ' || p_num_doc_orden)::VARCHAR;
        RETURN;
    END IF;

    -- 1. Delete existing purchase (idempotent)
    DELETE FROM doc."PurchaseDocumentPayment" WHERE "DocumentNumber" = p_num_doc_compra AND "DocumentType" = 'COMPRA';
    DELETE FROM doc."PurchaseDocumentLine" WHERE "DocumentNumber" = p_num_doc_compra AND "DocumentType" = 'COMPRA';
    DELETE FROM doc."PurchaseDocument" WHERE "DocumentNumber" = p_num_doc_compra AND "DocumentType" = 'COMPRA';

    -- 2. Copy header from order with overrides
    INSERT INTO doc."PurchaseDocument" (
        "DocumentNumber", "SerialType", "DocumentType",
        "SupplierCode", "SupplierName", "FiscalId",
        "IssueDate", "DueDate", "ReceiptDate", "PaymentDate", "DocumentTime",
        "SubTotal", "TaxableAmount", "ExemptAmount", "TaxAmount", "TaxRate",
        "TotalAmount", "DiscountAmount",
        "IsVoided", "IsPaid", "IsReceived", "IsLegal",
        "OriginDocumentNumber", "ControlNumber",
        "VoucherNumber", "VoucherDate", "RetainedTax",
        "IsrCode", "IsrAmount", "IsrSubjectCode", "IsrSubjectAmount", "RetentionRate",
        "ImportAmount", "ImportTax", "ImportBase", "FreightAmount",
        "Notes", "Concept", "OrderNumber", "ReceivedBy", "WarehouseCode",
        "CurrencyCode", "ExchangeRate", "UsdAmount",
        "UserCode", "ShortUserCode", "ReportDate", "HostName",
        "CreatedAt", "UpdatedAt"
    )
    SELECT
        p_num_doc_compra,
        o."SerialType",
        'COMPRA',
        COALESCE(CASE WHEN p_compra_override_json IS NOT NULL THEN p_compra_override_json->>'SupplierCode' END, o."SupplierCode"),
        COALESCE(CASE WHEN p_compra_override_json IS NOT NULL THEN p_compra_override_json->>'SupplierName' END, o."SupplierName"),
        COALESCE(CASE WHEN p_compra_override_json IS NOT NULL THEN p_compra_override_json->>'FiscalId' END, o."FiscalId"),
        COALESCE(CASE WHEN p_compra_override_json IS NOT NULL THEN (p_compra_override_json->>'IssueDate')::TIMESTAMP END, NOW() AT TIME ZONE 'UTC'),
        COALESCE(CASE WHEN p_compra_override_json IS NOT NULL THEN (p_compra_override_json->>'DueDate')::TIMESTAMP END, o."DueDate"),
        COALESCE(CASE WHEN p_compra_override_json IS NOT NULL THEN (p_compra_override_json->>'ReceiptDate')::TIMESTAMP END, o."ReceiptDate"),
        COALESCE(CASE WHEN p_compra_override_json IS NOT NULL THEN (p_compra_override_json->>'PaymentDate')::TIMESTAMP END, o."PaymentDate"),
        COALESCE(CASE WHEN p_compra_override_json IS NOT NULL THEN p_compra_override_json->>'DocumentTime' END, TO_CHAR(NOW() AT TIME ZONE 'UTC', 'HH24:MI:SS')),
        COALESCE(CASE WHEN p_compra_override_json IS NOT NULL THEN (p_compra_override_json->>'SubTotal')::DOUBLE PRECISION END, o."SubTotal"),
        COALESCE(CASE WHEN p_compra_override_json IS NOT NULL THEN (p_compra_override_json->>'TaxableAmount')::DOUBLE PRECISION END, o."TaxableAmount"),
        COALESCE(CASE WHEN p_compra_override_json IS NOT NULL THEN (p_compra_override_json->>'ExemptAmount')::DOUBLE PRECISION END, o."ExemptAmount"),
        COALESCE(CASE WHEN p_compra_override_json IS NOT NULL THEN (p_compra_override_json->>'TaxAmount')::DOUBLE PRECISION END, o."TaxAmount"),
        COALESCE(CASE WHEN p_compra_override_json IS NOT NULL THEN (p_compra_override_json->>'TaxRate')::DOUBLE PRECISION END, o."TaxRate"),
        COALESCE(CASE WHEN p_compra_override_json IS NOT NULL THEN (p_compra_override_json->>'TotalAmount')::DOUBLE PRECISION END, o."TotalAmount"),
        COALESCE(CASE WHEN p_compra_override_json IS NOT NULL THEN (p_compra_override_json->>'DiscountAmount')::DOUBLE PRECISION END, o."DiscountAmount"),
        FALSE,
        COALESCE(CASE WHEN p_compra_override_json IS NOT NULL THEN p_compra_override_json->>'IsPaid' END, 'N'),
        'N',
        COALESCE(CASE WHEN p_compra_override_json IS NOT NULL THEN (p_compra_override_json->>'IsLegal')::BOOLEAN END, o."IsLegal"),
        p_num_doc_orden,
        COALESCE(CASE WHEN p_compra_override_json IS NOT NULL THEN p_compra_override_json->>'ControlNumber' END, o."ControlNumber"),
        o."VoucherNumber", o."VoucherDate", o."RetainedTax",
        o."IsrCode", o."IsrAmount", o."IsrSubjectCode", o."IsrSubjectAmount", o."RetentionRate",
        o."ImportAmount", o."ImportTax", o."ImportBase", o."FreightAmount",
        COALESCE(CASE WHEN p_compra_override_json IS NOT NULL THEN p_compra_override_json->>'Notes' END, o."Notes"),
        o."Concept", o."OrderNumber", o."ReceivedBy",
        COALESCE(CASE WHEN p_compra_override_json IS NOT NULL THEN p_compra_override_json->>'WarehouseCode' END, o."WarehouseCode"),
        COALESCE(o."CurrencyCode", 'BS'),
        COALESCE(o."ExchangeRate", 1),
        o."UsdAmount",
        p_cod_usuario,
        o."ShortUserCode",
        NOW() AT TIME ZONE 'UTC',
        inet_client_addr()::TEXT,
        NOW() AT TIME ZONE 'UTC',
        NOW() AT TIME ZONE 'UTC'
    FROM doc."PurchaseDocument" o
    WHERE o."DocumentNumber" = p_num_doc_orden AND o."DocumentType" = 'ORDEN' AND o."IsDeleted" = FALSE;

    -- 3. Copy detail lines (from JSONB or from order)
    IF p_detalle_json IS NOT NULL AND jsonb_array_length(p_detalle_json) > 0 THEN
        INSERT INTO doc."PurchaseDocumentLine" (
            "DocumentNumber", "DocumentType", "LineNumber",
            "ProductCode", "Description",
            "Quantity", "UnitPrice", "UnitCost",
            "SubTotal", "DiscountAmount", "TotalAmount",
            "TaxRate", "TaxAmount",
            "IsVoided", "UserCode", "LineDate",
            "CreatedAt", "UpdatedAt"
        )
        SELECT
            p_num_doc_compra, 'COMPRA',
            (r->>'LineNumber')::INT,
            r->>'ProductCode',
            r->>'Description',
            COALESCE((r->>'Quantity')::DOUBLE PRECISION, 0),
            COALESCE((r->>'UnitPrice')::DOUBLE PRECISION, 0),
            COALESCE((r->>'UnitCost')::DOUBLE PRECISION, 0),
            COALESCE((r->>'SubTotal')::DOUBLE PRECISION, 0),
            COALESCE((r->>'DiscountAmount')::DOUBLE PRECISION, 0),
            COALESCE((r->>'TotalAmount')::DOUBLE PRECISION, 0),
            COALESCE((r->>'TaxRate')::DOUBLE PRECISION, 0),
            COALESCE((r->>'TaxAmount')::DOUBLE PRECISION, 0),
            COALESCE((r->>'IsVoided')::BOOLEAN, FALSE),
            p_cod_usuario,
            NOW() AT TIME ZONE 'UTC',
            NOW() AT TIME ZONE 'UTC',
            NOW() AT TIME ZONE 'UTC'
        FROM jsonb_array_elements(p_detalle_json) AS r;

        GET DIAGNOSTICS v_detalle_rows = ROW_COUNT;
    ELSE
        INSERT INTO doc."PurchaseDocumentLine" (
            "DocumentNumber", "DocumentType", "LineNumber",
            "ProductCode", "Description",
            "Quantity", "UnitPrice", "UnitCost",
            "SubTotal", "DiscountAmount", "TotalAmount",
            "TaxRate", "TaxAmount",
            "IsVoided", "UserCode", "LineDate",
            "CreatedAt", "UpdatedAt"
        )
        SELECT
            p_num_doc_compra, 'COMPRA',
            ol."LineNumber", ol."ProductCode", ol."Description",
            ol."Quantity", ol."UnitPrice", ol."UnitCost",
            ol."SubTotal", ol."DiscountAmount", ol."TotalAmount",
            ol."TaxRate", ol."TaxAmount",
            FALSE, p_cod_usuario, NOW() AT TIME ZONE 'UTC',
            NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'
        FROM doc."PurchaseDocumentLine" ol
        WHERE ol."DocumentNumber" = p_num_doc_orden AND ol."DocumentType" = 'ORDEN' AND ol."IsDeleted" = FALSE;

        GET DIAGNOSTICS v_detalle_rows = ROW_COUNT;
    END IF;

    IF v_detalle_rows = 0 THEN
        RAISE EXCEPTION 'La orden no tiene lineas de detalle: %', p_num_doc_orden;
    END IF;

    -- 4. Mark order as received
    UPDATE doc."PurchaseDocument"
    SET "IsReceived" = 'S',
        "Notes" = COALESCE("Notes", '') || ' | Convertida a compra ' || p_num_doc_compra
                  || ' el ' || TO_CHAR(NOW() AT TIME ZONE 'UTC', 'YYYY-MM-DD HH24:MI') || ' por ' || p_cod_usuario,
        "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
    WHERE "DocumentNumber" = p_num_doc_orden AND "DocumentType" = 'ORDEN' AND "IsDeleted" = FALSE;

    -- 5. Sync ap."PayableDocument"
    SELECT "TotalAmount", "SupplierCode", COALESCE("IsPaid", 'N'), "IssueDate", "Notes"
    INTO v_total_amount, v_supplier_code, v_is_paid, v_doc_date, v_notes
    FROM doc."PurchaseDocument"
    WHERE "DocumentNumber" = p_num_doc_compra AND "DocumentType" = 'COMPRA';

    v_pending_amount := CASE WHEN UPPER(v_is_paid)::character varying = 'S' THEN 0 ELSE v_total_amount END;

    IF v_supplier_code IS NOT NULL AND TRIM(v_supplier_code) <> '' THEN
        SELECT c."CompanyId" INTO v_company_id FROM cfg."Company" c
        WHERE c."IsDeleted" = FALSE AND c."IsActive" = TRUE
        ORDER BY CASE WHEN c."CompanyCode" = 'DEFAULT' THEN 0 ELSE 1 END, c."CompanyId" LIMIT 1;

        SELECT b."BranchId" INTO v_branch_id FROM cfg."Branch" b
        WHERE b."CompanyId" = v_company_id AND b."IsDeleted" = FALSE AND b."IsActive" = TRUE
        ORDER BY CASE WHEN b."BranchCode" = 'MAIN' THEN 0 ELSE 1 END, b."BranchId" LIMIT 1;

        SELECT u."UserId" INTO v_user_id FROM sec."User" u
        WHERE u."UserCode" = p_cod_usuario AND u."IsDeleted" = FALSE LIMIT 1;

        SELECT s."SupplierId" INTO v_supplier_id FROM master."Supplier" s
        WHERE s."SupplierCode" = v_supplier_code AND s."CompanyId" = v_company_id AND s."IsDeleted" = FALSE LIMIT 1;

        IF v_supplier_id IS NOT NULL AND v_company_id IS NOT NULL AND v_branch_id IS NOT NULL THEN
            v_safe_pending := CASE WHEN v_pending_amount < 0 THEN 0 ELSE v_pending_amount END;
            v_status := CASE
                WHEN v_safe_pending <= 0 THEN 'PAID'
                WHEN v_safe_pending < v_total_amount THEN 'PARTIAL'
                ELSE 'PENDING'
            END;

            SELECT pd."PayableDocumentId" INTO v_existing_id FROM ap."PayableDocument" pd
            WHERE pd."CompanyId" = v_company_id AND pd."BranchId" = v_branch_id
              AND pd."DocumentType" = 'COMPRA' AND pd."DocumentNumber" = p_num_doc_compra LIMIT 1;

            IF v_existing_id IS NOT NULL THEN
                UPDATE ap."PayableDocument"
                SET "SupplierId" = v_supplier_id, "IssueDate" = v_doc_date, "DueDate" = v_doc_date,
                    "TotalAmount" = v_total_amount, "PendingAmount" = v_safe_pending,
                    "PaidFlag" = CASE WHEN v_safe_pending <= 0 THEN TRUE ELSE FALSE END,
                    "Status" = v_status, "Notes" = v_notes,
                    "UpdatedAt" = NOW() AT TIME ZONE 'UTC', "UpdatedByUserId" = v_user_id
                WHERE "PayableDocumentId" = v_existing_id;
            ELSE
                INSERT INTO ap."PayableDocument" (
                    "CompanyId", "BranchId", "SupplierId", "DocumentType", "DocumentNumber",
                    "IssueDate", "DueDate", "CurrencyCode", "TotalAmount", "PendingAmount",
                    "PaidFlag", "Status", "Notes",
                    "CreatedAt", "UpdatedAt", "CreatedByUserId", "UpdatedByUserId"
                )
                VALUES (
                    v_company_id, v_branch_id, v_supplier_id, 'COMPRA', p_num_doc_compra,
                    v_doc_date, v_doc_date, 'USD', v_total_amount, v_safe_pending,
                    CASE WHEN v_safe_pending <= 0 THEN TRUE ELSE FALSE END,
                    v_status, v_notes,
                    NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC', v_user_id, v_user_id
                );
            END IF;

            PERFORM usp_master_supplier_updatebalance(v_supplier_id, v_user_id);
        END IF;
    END IF;

    v_ok := TRUE;

    RETURN QUERY SELECT v_ok, p_num_doc_orden, p_num_doc_compra,
                        v_detalle_rows, v_formas_pago_rows, v_pending_amount, ''::VARCHAR;
END;
$function$
;

-- usp_doc_purchasedocument_get
DROP FUNCTION IF EXISTS public.usp_doc_purchasedocument_get(character varying, character varying) CASCADE;
DROP FUNCTION IF EXISTS public.usp_doc_purchasedocument_get(p_tipo_operacion character varying, p_num_doc character varying)
 RETURNS TABLE("PurchaseDocumentId" bigint, "DocumentNumber" character varying, "SerialType" character varying, "DocumentType" character varying, "SupplierCode" character varying, "SupplierName" character varying, "FiscalId" character varying, "IssueDate" timestamp without time zone, "DueDate" timestamp without time zone, "ReceiptDate" timestamp without time zone, "PaymentDate" timestamp without time zone, "DocumentTime" character varying, "SubTotal" double precision, "TaxableAmount" double precision, "ExemptAmount" double precision, "TaxAmount" double precision, "TaxRate" double precision, "TotalAmount" double precision, "DiscountAmount" double precision, "IsVoided" boolean, "IsPaid" character varying, "IsReceived" character varying, "IsLegal" boolean, "OriginDocumentNumber" character varying, "ControlNumber" character varying, "VoucherNumber" character varying, "VoucherDate" timestamp without time zone, "RetainedTax" double precision, "IsrCode" character varying, "IsrAmount" double precision, "IsrSubjectCode" character varying, "IsrSubjectAmount" double precision, "RetentionRate" double precision, "ImportAmount" double precision, "ImportTax" double precision, "ImportBase" double precision, "FreightAmount" double precision, "Notes" character varying, "Concept" character varying, "OrderNumber" character varying, "ReceivedBy" character varying, "WarehouseCode" character varying, "CurrencyCode" character varying, "ExchangeRate" double precision, "UsdAmount" double precision, "UserCode" character varying, "ShortUserCode" character varying, "ReportDate" timestamp without time zone, "HostName" character varying, "IsDeleted" boolean, "CreatedAt" timestamp without time zone, "UpdatedAt" timestamp without time zone)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        d."PurchaseDocumentId",
        d."DocumentNumber",
        d."SerialType",
        d."DocumentType",
        d."SupplierCode",
        d."SupplierName",
        d."FiscalId",
        d."IssueDate",
        d."DueDate",
        d."ReceiptDate",
        d."PaymentDate",
        d."DocumentTime",
        d."SubTotal",
        d."TaxableAmount",
        d."ExemptAmount",
        d."TaxAmount",
        d."TaxRate",
        d."TotalAmount",
        d."DiscountAmount",
        d."IsVoided",
        d."IsPaid",
        d."IsReceived",
        d."IsLegal",
        d."OriginDocumentNumber",
        d."ControlNumber",
        d."VoucherNumber",
        d."VoucherDate",
        d."RetainedTax",
        d."IsrCode",
        d."IsrAmount",
        d."IsrSubjectCode",
        d."IsrSubjectAmount",
        d."RetentionRate",
        d."ImportAmount",
        d."ImportTax",
        d."ImportBase",
        d."FreightAmount",
        d."Notes",
        d."Concept",
        d."OrderNumber",
        d."ReceivedBy",
        d."WarehouseCode",
        d."CurrencyCode",
        d."ExchangeRate",
        d."UsdAmount",
        d."UserCode",
        d."ShortUserCode",
        d."ReportDate",
        d."HostName",
        d."IsDeleted",
        d."CreatedAt",
        d."UpdatedAt"
    FROM doc."PurchaseDocument" d
    WHERE d."DocumentNumber" = p_num_doc
      AND d."DocumentType" = p_tipo_operacion
      AND d."IsDeleted" = FALSE
    LIMIT 1;
END;
$function$
;

-- usp_doc_purchasedocument_getdetail
DROP FUNCTION IF EXISTS public.usp_doc_purchasedocument_getdetail(character varying, character varying) CASCADE;
DROP FUNCTION IF EXISTS public.usp_doc_purchasedocument_getdetail(p_tipo_operacion character varying, p_num_doc character varying)
 RETURNS TABLE("LineId" bigint, "DocumentNumber" character varying, "DocumentType" character varying, "LineNumber" integer, "ProductCode" character varying, "Description" character varying, "Quantity" double precision, "UnitPrice" double precision, "UnitCost" double precision, "SubTotal" double precision, "DiscountAmount" double precision, "TotalAmount" double precision, "TaxRate" double precision, "TaxAmount" double precision, "IsVoided" boolean, "IsDeleted" boolean, "UserCode" character varying, "LineDate" timestamp without time zone, "CreatedAt" timestamp without time zone, "UpdatedAt" timestamp without time zone)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        l."LineId",
        l."DocumentNumber",
        l."DocumentType",
        l."LineNumber",
        l."ProductCode",
        l."Description",
        l."Quantity",
        l."UnitPrice",
        l."UnitCost",
        l."SubTotal",
        l."DiscountAmount",
        l."TotalAmount",
        l."TaxRate",
        l."TaxAmount",
        l."IsVoided",
        l."IsDeleted",
        l."UserCode",
        l."LineDate",
        l."CreatedAt",
        l."UpdatedAt"
    FROM doc."PurchaseDocumentLine" l
    WHERE l."DocumentNumber" = p_num_doc
      AND l."DocumentType" = p_tipo_operacion
      AND l."IsDeleted" = FALSE
    ORDER BY COALESCE(l."LineNumber", 0), l."LineId";
END;
$function$
;

-- usp_doc_purchasedocument_getindicadores
DROP FUNCTION IF EXISTS public.usp_doc_purchasedocument_getindicadores(character varying, character varying) CASCADE;
DROP FUNCTION IF EXISTS public.usp_doc_purchasedocument_getindicadores(p_tipo_operacion character varying, p_num_doc character varying)
 RETURNS TABLE("IsVoided" boolean, "IsPaid" character varying, "IsReceived" character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        d."IsVoided",
        d."IsPaid",
        d."IsReceived"
    FROM doc."PurchaseDocument" d
    WHERE d."DocumentNumber" = p_num_doc
      AND d."DocumentType" = p_tipo_operacion
      AND d."IsDeleted" = FALSE;
END;
$function$
;

-- usp_doc_purchasedocument_getpayments
DROP FUNCTION IF EXISTS public.usp_doc_purchasedocument_getpayments(character varying, character varying) CASCADE;
DROP FUNCTION IF EXISTS public.usp_doc_purchasedocument_getpayments(p_tipo_operacion character varying, p_num_doc character varying)
 RETURNS TABLE("PaymentId" bigint, "DocumentNumber" character varying, "DocumentType" character varying, "PaymentMethod" character varying, "BankCode" character varying, "PaymentNumber" character varying, "Amount" double precision, "PaymentDate" timestamp without time zone, "DueDate" timestamp without time zone, "ReferenceNumber" character varying, "UserCode" character varying, "IsDeleted" boolean, "CreatedAt" timestamp without time zone, "UpdatedAt" timestamp without time zone)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        p."PaymentId",
        p."DocumentNumber",
        p."DocumentType",
        p."PaymentMethod",
        p."BankCode",
        p."PaymentNumber",
        p."Amount",
        p."PaymentDate",
        p."DueDate",
        p."ReferenceNumber",
        p."UserCode",
        p."IsDeleted",
        p."CreatedAt",
        p."UpdatedAt"
    FROM doc."PurchaseDocumentPayment" p
    WHERE p."DocumentNumber" = p_num_doc
      AND p."DocumentType" = p_tipo_operacion
      AND p."IsDeleted" = FALSE;
END;
$function$
;

-- usp_doc_purchasedocument_list
DROP FUNCTION IF EXISTS public.usp_doc_purchasedocument_list(character varying, character varying, character varying, date, date, integer, integer) CASCADE;
DROP FUNCTION IF EXISTS public.usp_doc_purchasedocument_list(p_tipo_operacion character varying DEFAULT 'COMPRA'::character varying, p_search character varying DEFAULT NULL::character varying, p_codigo character varying DEFAULT NULL::character varying, p_from_date date DEFAULT NULL::date, p_to_date date DEFAULT NULL::date, p_page integer DEFAULT 1, p_limit integer DEFAULT 50)
 RETURNS TABLE("PurchaseDocumentId" bigint, "DocumentNumber" character varying, "SerialType" character varying, "DocumentType" character varying, "SupplierCode" character varying, "SupplierName" character varying, "FiscalId" character varying, "IssueDate" timestamp without time zone, "DueDate" timestamp without time zone, "ReceiptDate" timestamp without time zone, "PaymentDate" timestamp without time zone, "DocumentTime" character varying, "SubTotal" double precision, "TaxableAmount" double precision, "ExemptAmount" double precision, "TaxAmount" double precision, "TaxRate" double precision, "TotalAmount" double precision, "DiscountAmount" double precision, "IsVoided" boolean, "IsPaid" character varying, "IsReceived" character varying, "IsLegal" boolean, "OriginDocumentNumber" character varying, "ControlNumber" character varying, "VoucherNumber" character varying, "VoucherDate" timestamp without time zone, "RetainedTax" double precision, "IsrCode" character varying, "IsrAmount" double precision, "IsrSubjectCode" character varying, "IsrSubjectAmount" double precision, "RetentionRate" double precision, "ImportAmount" double precision, "ImportTax" double precision, "ImportBase" double precision, "FreightAmount" double precision, "Notes" character varying, "Concept" character varying, "OrderNumber" character varying, "ReceivedBy" character varying, "WarehouseCode" character varying, "CurrencyCode" character varying, "ExchangeRate" double precision, "UsdAmount" double precision, "UserCode" character varying, "ShortUserCode" character varying, "ReportDate" timestamp without time zone, "HostName" character varying, "IsDeleted" boolean, "CreatedAt" timestamp without time zone, "UpdatedAt" timestamp without time zone, "TotalCount" bigint)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_page   INT := GREATEST(COALESCE(p_page, 1), 1);
    v_limit  INT := LEAST(GREATEST(COALESCE(p_limit, 50), 1), 500);
    v_offset INT := (v_page - 1) * v_limit;
    v_total  BIGINT;
BEGIN
    -- Contar total de registros que coinciden con los filtros
    SELECT COUNT(*) INTO v_total
    FROM doc."PurchaseDocument"
    WHERE "DocumentType" = p_tipo_operacion
      AND "IsDeleted" = FALSE
      AND (p_search IS NULL OR (
            "DocumentNumber" ILIKE '%' || p_search || '%'
            OR "SupplierName" ILIKE '%' || p_search || '%'
            OR "FiscalId" ILIKE '%' || p_search || '%'
          ))
      AND (p_codigo IS NULL OR "SupplierCode" = p_codigo)
      AND (p_from_date IS NULL OR "IssueDate" >= p_from_date)
      AND (p_to_date IS NULL OR "IssueDate" < (p_to_date + INTERVAL '1 day'));

    -- Retornar pagina de resultados
    RETURN QUERY
    SELECT
        d."PurchaseDocumentId",
        d."DocumentNumber",
        d."SerialType",
        d."DocumentType",
        d."SupplierCode",
        d."SupplierName",
        d."FiscalId",
        d."IssueDate",
        d."DueDate",
        d."ReceiptDate",
        d."PaymentDate",
        d."DocumentTime",
        d."SubTotal",
        d."TaxableAmount",
        d."ExemptAmount",
        d."TaxAmount",
        d."TaxRate",
        d."TotalAmount",
        d."DiscountAmount",
        d."IsVoided",
        d."IsPaid",
        d."IsReceived",
        d."IsLegal",
        d."OriginDocumentNumber",
        d."ControlNumber",
        d."VoucherNumber",
        d."VoucherDate",
        d."RetainedTax",
        d."IsrCode",
        d."IsrAmount",
        d."IsrSubjectCode",
        d."IsrSubjectAmount",
        d."RetentionRate",
        d."ImportAmount",
        d."ImportTax",
        d."ImportBase",
        d."FreightAmount",
        d."Notes",
        d."Concept",
        d."OrderNumber",
        d."ReceivedBy",
        d."WarehouseCode",
        d."CurrencyCode",
        d."ExchangeRate",
        d."UsdAmount",
        d."UserCode",
        d."ShortUserCode",
        d."ReportDate",
        d."HostName",
        d."IsDeleted",
        d."CreatedAt",
        d."UpdatedAt",
        v_total
    FROM doc."PurchaseDocument" d
    WHERE d."DocumentType" = p_tipo_operacion
      AND d."IsDeleted" = FALSE
      AND (p_search IS NULL OR (
            d."DocumentNumber" ILIKE '%' || p_search || '%'
            OR d."SupplierName" ILIKE '%' || p_search || '%'
            OR d."FiscalId" ILIKE '%' || p_search || '%'
          ))
      AND (p_codigo IS NULL OR d."SupplierCode" = p_codigo)
      AND (p_from_date IS NULL OR d."IssueDate" >= p_from_date)
      AND (p_to_date IS NULL OR d."IssueDate" < (p_to_date + INTERVAL '1 day'))
    ORDER BY d."IssueDate" DESC, d."DocumentNumber" DESC
    LIMIT v_limit OFFSET v_offset;
END;
$function$
;

-- usp_doc_purchasedocument_receiveorder
DROP FUNCTION IF EXISTS public.usp_doc_purchasedocument_receiveorder(character varying, character varying) CASCADE;
DROP FUNCTION IF EXISTS public.usp_doc_purchasedocument_receiveorder(p_num_doc character varying, p_cod_usuario character varying DEFAULT 'API'::character varying)
 RETURNS TABLE(ok boolean, "numDoc" character varying, mensaje character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
    -- Validar que la orden existe
    IF NOT EXISTS (
        SELECT 1 FROM doc."PurchaseDocument"
        WHERE "DocumentNumber" = p_num_doc
          AND "DocumentType" = 'ORDEN'
          AND "IsDeleted" = FALSE
    ) THEN
        RETURN QUERY SELECT FALSE, p_num_doc,
            ('Orden de compra no encontrada: ' || p_num_doc)::VARCHAR(500);
        RETURN;
    END IF;

    -- Validar que la orden no esta anulada
    IF EXISTS (
        SELECT 1 FROM doc."PurchaseDocument"
        WHERE "DocumentNumber" = p_num_doc
          AND "DocumentType" = 'ORDEN'
          AND "IsDeleted" = FALSE
          AND "IsVoided" = TRUE
    ) THEN
        RETURN QUERY SELECT FALSE, p_num_doc,
            ('La orden esta anulada y no puede marcarse como recibida: ' || p_num_doc)::VARCHAR(500);
        RETURN;
    END IF;

    -- Marcar como recibida
    UPDATE doc."PurchaseDocument"
    SET "IsReceived" = 'S',
        "Notes"      = COALESCE("Notes", '') || ' | Recibido '
                       || TO_CHAR(NOW() AT TIME ZONE 'UTC', 'YYYY-MM-DD HH24:MI')
                       || ' por ' || p_cod_usuario,
        "UpdatedAt"  = NOW() AT TIME ZONE 'UTC'
    WHERE "DocumentNumber" = p_num_doc
      AND "DocumentType" = 'ORDEN'
      AND "IsDeleted" = FALSE;

    RETURN QUERY SELECT TRUE, p_num_doc,
        ('Orden marcada como recibida exitosamente: ' || p_num_doc)::VARCHAR(500);
END;
$function$
;

-- usp_doc_purchasedocument_upsert
DROP FUNCTION IF EXISTS public.usp_doc_purchasedocument_upsert(character varying, jsonb, jsonb, jsonb, character varying) CASCADE;
DROP FUNCTION IF EXISTS public.usp_doc_purchasedocument_upsert(p_tipo_operacion character varying, p_header_json jsonb, p_detail_json jsonb, p_payments_json jsonb DEFAULT NULL::jsonb, p_doc_origen character varying DEFAULT NULL::character varying)
 RETURNS TABLE(ok boolean, "numDoc" character varying, "detalleRows" integer, "formasPagoRows" integer, "pendingAmount" double precision, mensaje character varying)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_ok              BOOLEAN := FALSE;
    v_num_doc         VARCHAR(60);
    v_detalle_rows    INT := 0;
    v_formas_pago_rows INT := 0;
    v_pending_amount  DOUBLE PRECISION := 0;
    v_total_amount    DOUBLE PRECISION;
    v_supplier_code   VARCHAR(60);
    v_is_paid         VARCHAR(1);
    v_doc_date        TIMESTAMP;
    v_notes           VARCHAR(500);
    v_user_code       VARCHAR(60);
    v_company_id      INT;
    v_branch_id       INT;
    v_user_id         INT;
    v_supplier_id     BIGINT;
    v_safe_pending    DOUBLE PRECISION;
    v_status          VARCHAR(20);
    v_existing_id     BIGINT;
    r                 JSONB;
BEGIN
    -- Get document number from header
    v_num_doc := TRIM(p_header_json->>'DocumentNumber');

    IF v_num_doc IS NULL OR v_num_doc = '' THEN
        RETURN QUERY SELECT FALSE, v_num_doc, 0, 0, 0::DOUBLE PRECISION,
                     'Numero de documento requerido (DocumentNumber)'::VARCHAR;
        RETURN;
    END IF;

    -- 1. Delete existing (idempotent)
    DELETE FROM doc."PurchaseDocumentPayment" WHERE "DocumentNumber" = v_num_doc AND "DocumentType" = p_tipo_operacion;
    DELETE FROM doc."PurchaseDocumentLine" WHERE "DocumentNumber" = v_num_doc AND "DocumentType" = p_tipo_operacion;
    DELETE FROM doc."PurchaseDocument" WHERE "DocumentNumber" = v_num_doc AND "DocumentType" = p_tipo_operacion;

    -- 2. INSERT header from JSONB
    INSERT INTO doc."PurchaseDocument" (
        "DocumentNumber", "SerialType", "DocumentType",
        "SupplierCode", "SupplierName", "FiscalId",
        "IssueDate", "DueDate", "ReceiptDate", "PaymentDate", "DocumentTime",
        "SubTotal", "TaxableAmount", "ExemptAmount", "TaxAmount", "TaxRate",
        "TotalAmount", "DiscountAmount",
        "IsVoided", "IsPaid", "IsReceived", "IsLegal",
        "OriginDocumentNumber", "ControlNumber",
        "VoucherNumber", "VoucherDate", "RetainedTax",
        "IsrCode", "IsrAmount", "IsrSubjectCode", "IsrSubjectAmount", "RetentionRate",
        "ImportAmount", "ImportTax", "ImportBase", "FreightAmount",
        "Notes", "Concept", "OrderNumber", "ReceivedBy", "WarehouseCode",
        "CurrencyCode", "ExchangeRate", "UsdAmount",
        "UserCode", "ShortUserCode", "ReportDate", "HostName",
        "CreatedAt", "UpdatedAt"
    )
    VALUES (
        v_num_doc,
        COALESCE(p_header_json->>'SerialType', ''),
        p_tipo_operacion,
        p_header_json->>'SupplierCode',
        p_header_json->>'SupplierName',
        p_header_json->>'FiscalId',
        COALESCE((p_header_json->>'IssueDate')::TIMESTAMP, NOW() AT TIME ZONE 'UTC'),
        (p_header_json->>'DueDate')::TIMESTAMP,
        (p_header_json->>'ReceiptDate')::TIMESTAMP,
        (p_header_json->>'PaymentDate')::TIMESTAMP,
        COALESCE(p_header_json->>'DocumentTime', TO_CHAR(NOW() AT TIME ZONE 'UTC', 'HH24:MI:SS')),
        COALESCE((p_header_json->>'SubTotal')::DOUBLE PRECISION, 0),
        COALESCE((p_header_json->>'TaxableAmount')::DOUBLE PRECISION, 0),
        COALESCE((p_header_json->>'ExemptAmount')::DOUBLE PRECISION, 0),
        COALESCE((p_header_json->>'TaxAmount')::DOUBLE PRECISION, 0),
        COALESCE((p_header_json->>'TaxRate')::DOUBLE PRECISION, 0),
        COALESCE((p_header_json->>'TotalAmount')::DOUBLE PRECISION, 0),
        COALESCE((p_header_json->>'DiscountAmount')::DOUBLE PRECISION, 0),
        COALESCE((p_header_json->>'IsVoided')::BOOLEAN, FALSE),
        COALESCE(p_header_json->>'IsPaid', 'N'),
        COALESCE(p_header_json->>'IsReceived', 'N'),
        COALESCE((p_header_json->>'IsLegal')::BOOLEAN, FALSE),
        COALESCE(p_doc_origen, p_header_json->>'OriginDocumentNumber'),
        p_header_json->>'ControlNumber',
        p_header_json->>'WithholdingCertNumber',
        (p_header_json->>'WithholdingCertDate')::TIMESTAMP,
        COALESCE((p_header_json->>'WithheldTaxAmount')::DOUBLE PRECISION, 0),
        p_header_json->>'IncomeTaxCode',
        COALESCE((p_header_json->>'IncomeTaxAmount')::DOUBLE PRECISION, 0),
        p_header_json->>'IncomeTaxPercent',
        COALESCE((p_header_json->>'IsSubjectToIncomeTax')::DOUBLE PRECISION, 0),
        COALESCE((p_header_json->>'WithholdingRate')::DOUBLE PRECISION, 0),
        COALESCE((p_header_json->>'IsImport')::DOUBLE PRECISION, 0),
        COALESCE((p_header_json->>'ImportTaxAmount')::DOUBLE PRECISION, 0),
        COALESCE((p_header_json->>'ImportTaxBase')::DOUBLE PRECISION, 0),
        COALESCE((p_header_json->>'FreightAmount')::DOUBLE PRECISION, 0),
        p_header_json->>'Notes',
        p_header_json->>'Concept',
        p_header_json->>'OrderNumber',
        p_header_json->>'ReceivedBy',
        p_header_json->>'WarehouseCode',
        COALESCE(p_header_json->>'CurrencyCode', 'BS'),
        COALESCE((p_header_json->>'ExchangeRate')::DOUBLE PRECISION, 1),
        COALESCE((p_header_json->>'DollarPrice')::DOUBLE PRECISION, 0),
        COALESCE(p_header_json->>'UserCode', 'API'),
        p_header_json->>'ShortUserCode',
        COALESCE((p_header_json->>'ReportDate')::TIMESTAMP, NOW() AT TIME ZONE 'UTC'),
        COALESCE(p_header_json->>'HostName', inet_client_addr()::TEXT),
        NOW() AT TIME ZONE 'UTC',
        NOW() AT TIME ZONE 'UTC'
    );

    -- 3. INSERT detail lines from JSONB array
    INSERT INTO doc."PurchaseDocumentLine" (
        "DocumentNumber", "DocumentType", "LineNumber",
        "ProductCode", "Description",
        "Quantity", "UnitPrice", "UnitCost",
        "SubTotal", "DiscountAmount", "TotalAmount",
        "TaxRate", "TaxAmount",
        "IsVoided", "UserCode", "LineDate",
        "CreatedAt", "UpdatedAt"
    )
    SELECT
        v_num_doc,
        p_tipo_operacion,
        (r->>'LineNumber')::INT,
        r->>'ProductCode',
        r->>'Description',
        COALESCE((r->>'Quantity')::DOUBLE PRECISION, 0),
        COALESCE((r->>'UnitPrice')::DOUBLE PRECISION, 0),
        COALESCE((r->>'UnitCost')::DOUBLE PRECISION, 0),
        COALESCE((r->>'SubTotal')::DOUBLE PRECISION, 0),
        COALESCE((r->>'DiscountAmount')::DOUBLE PRECISION, 0),
        COALESCE((r->>'TotalAmount')::DOUBLE PRECISION, 0),
        COALESCE((r->>'TaxRate')::DOUBLE PRECISION, 0),
        COALESCE((r->>'TaxAmount')::DOUBLE PRECISION, 0),
        COALESCE((r->>'IsVoided')::BOOLEAN, FALSE),
        r->>'UserCode',
        COALESCE((r->>'LineDate')::TIMESTAMP, NOW() AT TIME ZONE 'UTC'),
        NOW() AT TIME ZONE 'UTC',
        NOW() AT TIME ZONE 'UTC'
    FROM jsonb_array_elements(p_detail_json) AS r;

    GET DIAGNOSTICS v_detalle_rows = ROW_COUNT;

    -- 4. INSERT payments from JSONB (if provided)
    IF p_payments_json IS NOT NULL AND jsonb_array_length(p_payments_json) > 0 THEN
        INSERT INTO doc."PurchaseDocumentPayment" (
            "DocumentNumber", "DocumentType",
            "PaymentMethod", "BankCode", "PaymentNumber",
            "Amount", "PaymentDate", "DueDate",
            "ReferenceNumber", "UserCode",
            "CreatedAt", "UpdatedAt"
        )
        SELECT
            v_num_doc,
            p_tipo_operacion,
            r->>'PaymentMethod',
            r->>'BankCode',
            r->>'PaymentNumber',
            COALESCE((r->>'Amount')::DOUBLE PRECISION, 0),
            COALESCE((r->>'PaymentDate')::TIMESTAMP, NOW() AT TIME ZONE 'UTC'),
            (r->>'DueDate')::TIMESTAMP,
            r->>'ReferenceNumber',
            r->>'UserCode',
            NOW() AT TIME ZONE 'UTC',
            NOW() AT TIME ZONE 'UTC'
        FROM jsonb_array_elements(p_payments_json) AS r;

        GET DIAGNOSTICS v_formas_pago_rows = ROW_COUNT;
    END IF;

    -- 5. Sync ap."PayableDocument" for COMPRA
    IF p_tipo_operacion = 'COMPRA' THEN
        SELECT "TotalAmount", "SupplierCode", COALESCE("IsPaid", 'N'),
               "IssueDate", "Notes", "UserCode"
        INTO v_total_amount, v_supplier_code, v_is_paid,
             v_doc_date, v_notes, v_user_code
        FROM doc."PurchaseDocument"
        WHERE "DocumentNumber" = v_num_doc AND "DocumentType" = p_tipo_operacion;

        v_pending_amount := CASE WHEN UPPER(v_is_paid)::character varying = 'S' THEN 0 ELSE v_total_amount END;

        IF v_supplier_code IS NOT NULL AND TRIM(v_supplier_code) <> '' THEN
            SELECT c."CompanyId" INTO v_company_id
            FROM cfg."Company" c
            WHERE c."IsDeleted" = FALSE AND c."IsActive" = TRUE
            ORDER BY CASE WHEN c."CompanyCode" = 'DEFAULT' THEN 0 ELSE 1 END, c."CompanyId"
            LIMIT 1;

            SELECT b."BranchId" INTO v_branch_id
            FROM cfg."Branch" b
            WHERE b."CompanyId" = v_company_id AND b."IsDeleted" = FALSE AND b."IsActive" = TRUE
            ORDER BY CASE WHEN b."BranchCode" = 'MAIN' THEN 0 ELSE 1 END, b."BranchId"
            LIMIT 1;

            IF v_user_code IS NOT NULL THEN
                SELECT u."UserId" INTO v_user_id
                FROM sec."User" u
                WHERE u."UserCode" = v_user_code AND u."IsDeleted" = FALSE
                LIMIT 1;
            END IF;

            SELECT s."SupplierId" INTO v_supplier_id
            FROM master."Supplier" s
            WHERE s."SupplierCode" = v_supplier_code AND s."CompanyId" = v_company_id AND s."IsDeleted" = FALSE
            LIMIT 1;

            IF v_supplier_id IS NOT NULL AND v_company_id IS NOT NULL AND v_branch_id IS NOT NULL THEN
                v_safe_pending := CASE WHEN v_pending_amount < 0 THEN 0 ELSE v_pending_amount END;
                v_status := CASE
                    WHEN v_safe_pending <= 0 THEN 'PAID'
                    WHEN v_safe_pending < v_total_amount THEN 'PARTIAL'
                    ELSE 'PENDING'
                END;

                SELECT pd."PayableDocumentId" INTO v_existing_id
                FROM ap."PayableDocument" pd
                WHERE pd."CompanyId" = v_company_id AND pd."BranchId" = v_branch_id
                  AND pd."DocumentType" = p_tipo_operacion AND pd."DocumentNumber" = v_num_doc
                LIMIT 1;

                IF v_existing_id IS NOT NULL THEN
                    UPDATE ap."PayableDocument"
                    SET "SupplierId" = v_supplier_id, "IssueDate" = v_doc_date, "DueDate" = v_doc_date,
                        "TotalAmount" = v_total_amount, "PendingAmount" = v_safe_pending,
                        "PaidFlag" = CASE WHEN v_safe_pending <= 0 THEN TRUE ELSE FALSE END,
                        "Status" = v_status, "Notes" = v_notes,
                        "UpdatedAt" = NOW() AT TIME ZONE 'UTC', "UpdatedByUserId" = v_user_id
                    WHERE "PayableDocumentId" = v_existing_id;
                ELSE
                    INSERT INTO ap."PayableDocument" (
                        "CompanyId", "BranchId", "SupplierId",
                        "DocumentType", "DocumentNumber",
                        "IssueDate", "DueDate", "CurrencyCode",
                        "TotalAmount", "PendingAmount", "PaidFlag", "Status", "Notes",
                        "CreatedAt", "UpdatedAt", "CreatedByUserId", "UpdatedByUserId"
                    )
                    VALUES (
                        v_company_id, v_branch_id, v_supplier_id,
                        p_tipo_operacion, v_num_doc,
                        v_doc_date, v_doc_date, 'USD',
                        v_total_amount, v_safe_pending,
                        CASE WHEN v_safe_pending <= 0 THEN TRUE ELSE FALSE END,
                        v_status, v_notes,
                        NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC', v_user_id, v_user_id
                    );
                END IF;

                PERFORM usp_master_supplier_updatebalance(v_supplier_id, v_user_id);
            END IF;
        END IF;
    END IF;

    v_ok := TRUE;

    RETURN QUERY SELECT v_ok, v_num_doc, v_detalle_rows,
                        v_formas_pago_rows, v_pending_amount, ''::VARCHAR;
END;
$function$
;

-- usp_doc_purchasedocument_void
DROP FUNCTION IF EXISTS public.usp_doc_purchasedocument_void(character varying, character varying, character varying, character varying) CASCADE;
DROP FUNCTION IF EXISTS public.usp_doc_purchasedocument_void(p_tipo_operacion character varying, p_num_doc character varying, p_cod_usuario character varying DEFAULT 'API'::character varying, p_motivo character varying DEFAULT ''::character varying)
 RETURNS TABLE(ok boolean, "numDoc" character varying, "codProveedor" character varying, mensaje character varying)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_ok             BOOLEAN := FALSE;
    v_cod_proveedor  VARCHAR(60) := NULL;
    v_company_id     INT;
    v_branch_id      INT;
    v_supplier_id    BIGINT;
BEGIN
    -- Validar que el documento existe y no esta eliminado
    IF NOT EXISTS (
        SELECT 1 FROM doc."PurchaseDocument"
        WHERE "DocumentNumber" = p_num_doc
          AND "DocumentType" = p_tipo_operacion
          AND "IsDeleted" = FALSE
    ) THEN
        RETURN QUERY SELECT FALSE, p_num_doc, v_cod_proveedor,
            ('Documento no encontrado: ' || p_num_doc || ' / ' || p_tipo_operacion)::VARCHAR(500);
        RETURN;
    END IF;

    -- Validar que no este ya anulado
    IF EXISTS (
        SELECT 1 FROM doc."PurchaseDocument"
        WHERE "DocumentNumber" = p_num_doc
          AND "DocumentType" = p_tipo_operacion
          AND "IsDeleted" = FALSE
          AND "IsVoided" = TRUE
    ) THEN
        RETURN QUERY SELECT FALSE, p_num_doc, v_cod_proveedor,
            ('El documento ya se encuentra anulado: ' || p_num_doc)::VARCHAR(500);
        RETURN;
    END IF;

    -- Obtener codigo de proveedor
    SELECT d."SupplierCode" INTO v_cod_proveedor
    FROM doc."PurchaseDocument" d
    WHERE d."DocumentNumber" = p_num_doc
      AND d."DocumentType" = p_tipo_operacion
      AND d."IsDeleted" = FALSE;

    -- Anular cabecera del documento
    UPDATE doc."PurchaseDocument"
    SET "IsVoided"  = TRUE,
        "Notes"     = COALESCE("Notes", '') || ' | ANULADO '
                      || TO_CHAR(NOW() AT TIME ZONE 'UTC', 'YYYY-MM-DD HH24:MI')
                      || ' por ' || p_cod_usuario
                      || CASE WHEN p_motivo <> '' THEN ' - Motivo: ' || p_motivo ELSE '' END,
        "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
    WHERE "DocumentNumber" = p_num_doc
      AND "DocumentType" = p_tipo_operacion
      AND "IsDeleted" = FALSE;

    -- Anular lineas del documento
    UPDATE doc."PurchaseDocumentLine"
    SET "IsVoided"  = TRUE,
        "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
    WHERE "DocumentNumber" = p_num_doc
      AND "DocumentType" = p_tipo_operacion
      AND "IsDeleted" = FALSE;

    -- Resolver contexto: CompanyId y BranchId
    SELECT c."CompanyId" INTO v_company_id
    FROM cfg."Company" c
    WHERE c."IsDeleted" = FALSE AND c."IsActive" = TRUE
    ORDER BY c."CompanyId"
    LIMIT 1;

    SELECT b."BranchId" INTO v_branch_id
    FROM cfg."Branch" b
    WHERE b."CompanyId" = v_company_id AND b."IsDeleted" = FALSE AND b."IsActive" = TRUE
    ORDER BY b."BranchId"
    LIMIT 1;

    -- Resolver SupplierId desde master.Supplier
    SELECT s."SupplierId" INTO v_supplier_id
    FROM master."Supplier" s
    WHERE s."SupplierCode" = v_cod_proveedor
      AND s."CompanyId" = v_company_id
      AND s."IsDeleted" = FALSE
    LIMIT 1;

    -- Actualizar cuenta por pagar si existe
    IF v_supplier_id IS NOT NULL AND v_company_id IS NOT NULL AND v_branch_id IS NOT NULL THEN
        UPDATE ap."PayableDocument"
        SET "PendingAmount" = 0,
            "PaidFlag"      = TRUE,
            "Status"        = 'VOIDED',
            "UpdatedAt"     = NOW() AT TIME ZONE 'UTC'
        WHERE "CompanyId"      = v_company_id
          AND "BranchId"       = v_branch_id
          AND "DocumentNumber" = p_num_doc
          AND "DocumentType"   = p_tipo_operacion
          AND "SupplierId"     = v_supplier_id;

        -- Recalcular saldo total del proveedor
        UPDATE master."Supplier"
        SET "TotalBalance" = COALESCE((
                SELECT SUM("PendingAmount")
                FROM ap."PayableDocument"
                WHERE "SupplierId" = v_supplier_id
                  AND "Status" <> 'VOIDED'
            ), 0),
            "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
        WHERE "SupplierId" = v_supplier_id;
    END IF;

    RETURN QUERY SELECT TRUE, p_num_doc, v_cod_proveedor,
        ('Documento anulado exitosamente: ' || p_num_doc)::VARCHAR(500);
END;
$function$
;

-- usp_doc_salesdocument_get
DROP FUNCTION IF EXISTS public.usp_doc_salesdocument_get(character varying, character varying) CASCADE;
DROP FUNCTION IF EXISTS public.usp_doc_salesdocument_get(p_tipo_operacion character varying, p_num_doc character varying)
 RETURNS SETOF doc."SalesDocument"
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT *
    FROM doc."SalesDocument"
    WHERE "DocumentNumber" = p_num_doc
      AND "OperationType" = p_tipo_operacion
      AND "IsDeleted" = FALSE
    LIMIT 1;
END;
$function$
;

-- usp_doc_salesdocument_getdetail
DROP FUNCTION IF EXISTS public.usp_doc_salesdocument_getdetail(character varying, character varying) CASCADE;
DROP FUNCTION IF EXISTS public.usp_doc_salesdocument_getdetail(p_tipo_operacion character varying, p_num_doc character varying)
 RETURNS SETOF doc."SalesDocumentLine"
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT *
    FROM doc."SalesDocumentLine"
    WHERE "DocumentNumber" = p_num_doc
      AND "OperationType" = p_tipo_operacion
      AND "IsDeleted" = FALSE
    ORDER BY COALESCE("LineNumber", 0), "LineId";
END;
$function$
;

-- usp_doc_salesdocument_getpayments
DROP FUNCTION IF EXISTS public.usp_doc_salesdocument_getpayments(character varying, character varying) CASCADE;
DROP FUNCTION IF EXISTS public.usp_doc_salesdocument_getpayments(p_tipo_operacion character varying, p_num_doc character varying)
 RETURNS SETOF doc."SalesDocumentPayment"
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT *
    FROM doc."SalesDocumentPayment"
    WHERE "DocumentNumber" = p_num_doc
      AND "OperationType" = p_tipo_operacion
      AND "IsDeleted" = FALSE;
END;
$function$
;

-- usp_doc_salesdocument_invoicefromorder
DROP FUNCTION IF EXISTS public.usp_doc_salesdocument_invoicefromorder(character varying, character varying, jsonb, character varying) CASCADE;
DROP FUNCTION IF EXISTS public.usp_doc_salesdocument_invoicefromorder(p_num_doc_pedido character varying, p_num_doc_factura character varying, p_formas_pago_json jsonb DEFAULT NULL::jsonb, p_cod_usuario character varying DEFAULT 'API'::character varying)
 RETURNS TABLE(ok boolean, pedido character varying, factura character varying, mensaje character varying)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_elem JSONB;
BEGIN
    -- Validar que el pedido existe
    IF NOT EXISTS (
        SELECT 1 FROM doc."SalesDocument"
        WHERE "DocumentNumber" = p_num_doc_pedido
          AND "OperationType" = 'PEDIDO'
          AND "IsDeleted" = FALSE
    ) THEN
        RETURN QUERY SELECT FALSE, p_num_doc_pedido, p_num_doc_factura,
            ('Pedido no encontrado: ' || p_num_doc_pedido)::TEXT;
        RETURN;
    END IF;

    -- Validar que no esta anulado
    IF EXISTS (
        SELECT 1 FROM doc."SalesDocument"
        WHERE "DocumentNumber" = p_num_doc_pedido
          AND "OperationType" = 'PEDIDO'
          AND "IsDeleted" = FALSE
          AND "IsVoided" = TRUE
    ) THEN
        RETURN QUERY SELECT FALSE, p_num_doc_pedido, p_num_doc_factura,
            ('El pedido esta anulado y no puede facturarse: ' || p_num_doc_pedido)::TEXT;
        RETURN;
    END IF;

    -- Validar que no fue ya facturado
    IF EXISTS (
        SELECT 1 FROM doc."SalesDocument"
        WHERE "DocumentNumber" = p_num_doc_pedido
          AND "OperationType" = 'PEDIDO'
          AND "IsDeleted" = FALSE
          AND "IsInvoiced" = 'S'
    ) THEN
        RETURN QUERY SELECT FALSE, p_num_doc_pedido, p_num_doc_factura,
            ('El pedido ya fue facturado previamente: ' || p_num_doc_pedido)::TEXT;
        RETURN;
    END IF;

    -- Copiar cabecera del pedido como nueva factura
    INSERT INTO doc."SalesDocument" (
        "DocumentNumber", "SerialType", "FiscalMemoryNumber", "OperationType",
        "CustomerCode", "CustomerName", "FiscalId",
        "DocumentDate", "DueDate", "DocumentTime",
        "SubTotal", "TaxableAmount", "ExemptAmount", "TaxAmount", "TaxRate", "TotalAmount", "DiscountAmount",
        "IsVoided", "IsPaid", "IsInvoiced", "IsDelivered",
        "OriginDocumentNumber", "OriginDocumentType",
        "ControlNumber", "IsLegal", "IsPrinted",
        "Notes", "Concept", "PaymentTerms", "ShipToAddress",
        "SellerCode", "DepartmentCode", "LocationCode",
        "CurrencyCode", "ExchangeRate",
        "UserCode", "ReportDate", "HostName",
        "VehiclePlate", "Mileage", "TollAmount",
        "CreatedAt", "UpdatedAt"
    )
    SELECT
        p_num_doc_factura,
        s."SerialType",
        s."FiscalMemoryNumber",
        'FACT',
        s."CustomerCode", s."CustomerName", s."FiscalId",
        NOW() AT TIME ZONE 'UTC',
        s."DueDate",
        to_char(NOW() AT TIME ZONE 'UTC', 'HH24:MI:SS'),
        s."SubTotal", s."TaxableAmount", s."ExemptAmount", s."TaxAmount", s."TaxRate", s."TotalAmount", s."DiscountAmount",
        FALSE,
        'N',
        'N',
        'N',
        p_num_doc_pedido,
        'PEDIDO',
        s."ControlNumber", s."IsLegal", FALSE,
        s."Notes", s."Concept", s."PaymentTerms", s."ShipToAddress",
        s."SellerCode", s."DepartmentCode", s."LocationCode",
        s."CurrencyCode", s."ExchangeRate",
        p_cod_usuario,
        NOW() AT TIME ZONE 'UTC',
        inet_client_addr()::TEXT,
        s."VehiclePlate", s."Mileage", s."TollAmount",
        NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'
    FROM doc."SalesDocument" s
    WHERE s."DocumentNumber" = p_num_doc_pedido
      AND s."OperationType" = 'PEDIDO'
      AND s."IsDeleted" = FALSE;

    -- Copiar lineas del pedido a la factura
    INSERT INTO doc."SalesDocumentLine" (
        "DocumentNumber", "SerialType", "FiscalMemoryNumber", "OperationType",
        "LineNumber", "ProductCode", "Description", "AlternateCode",
        "Quantity", "UnitPrice", "DiscountedPrice", "UnitCost",
        "SubTotal", "DiscountAmount", "TotalAmount",
        "TaxRate", "TaxAmount",
        "IsVoided", "RelatedRef",
        "UserCode", "LineDate",
        "CreatedAt", "UpdatedAt"
    )
    SELECT
        p_num_doc_factura,
        sl."SerialType",
        sl."FiscalMemoryNumber",
        'FACT',
        sl."LineNumber", sl."ProductCode", sl."Description", sl."AlternateCode",
        sl."Quantity", sl."UnitPrice", sl."DiscountedPrice", sl."UnitCost",
        sl."SubTotal", sl."DiscountAmount", sl."TotalAmount",
        sl."TaxRate", sl."TaxAmount",
        FALSE,
        sl."RelatedRef",
        p_cod_usuario,
        NOW() AT TIME ZONE 'UTC',
        NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'
    FROM doc."SalesDocumentLine" sl
    WHERE sl."DocumentNumber" = p_num_doc_pedido
      AND sl."OperationType" = 'PEDIDO'
      AND sl."IsDeleted" = FALSE;

    -- Insertar formas de pago desde JSONB si se proporcionaron
    IF p_formas_pago_json IS NOT NULL AND jsonb_array_length(p_formas_pago_json) > 0 THEN
        INSERT INTO doc."SalesDocumentPayment" (
            "DocumentNumber", "SerialType", "FiscalMemoryNumber", "OperationType",
            "PaymentMethod", "BankCode", "PaymentNumber",
            "Amount", "AmountBs", "ExchangeRate",
            "PaymentDate", "DueDate",
            "ReferenceNumber", "UserCode",
            "CreatedAt", "UpdatedAt"
        )
        SELECT
            p_num_doc_factura,
            COALESCE(elem->>'serialType', ''),
            COALESCE(elem->>'fiscalMemoryNumber', '1'),
            'FACT',
            elem->>'paymentMethod',
            elem->>'bankCode',
            elem->>'paymentNumber',
            COALESCE((elem->>'amount')::NUMERIC, 0),
            COALESCE((elem->>'amountBs')::NUMERIC, 0),
            COALESCE((elem->>'exchangeRate')::NUMERIC, 1),
            COALESCE((elem->>'paymentDate')::TIMESTAMP, NOW() AT TIME ZONE 'UTC'),
            (elem->>'dueDate')::TIMESTAMP,
            elem->>'referenceNumber',
            p_cod_usuario,
            NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'
        FROM jsonb_array_elements(p_formas_pago_json) elem;
    END IF;

    -- Marcar el pedido como facturado
    UPDATE doc."SalesDocument"
    SET "IsInvoiced" = 'S',
        "Notes"      = CONCAT(COALESCE("Notes", ''), ' | Facturado como ', p_num_doc_factura,
                        ' el ', to_char(NOW() AT TIME ZONE 'UTC', 'YYYY-MM-DD HH24:MI'),
                        ' por ', p_cod_usuario),
        "UpdatedAt"  = NOW() AT TIME ZONE 'UTC'
    WHERE "DocumentNumber" = p_num_doc_pedido
      AND "OperationType" = 'PEDIDO'
      AND "IsDeleted" = FALSE;

    RETURN QUERY SELECT TRUE, p_num_doc_pedido, p_num_doc_factura,
        ('Factura ' || p_num_doc_factura || ' generada exitosamente desde pedido ' || p_num_doc_pedido)::TEXT;
END;
$function$
;

-- usp_doc_salesdocument_list
DROP FUNCTION IF EXISTS public.usp_doc_salesdocument_list(character varying, character varying, character varying, date, date, integer, integer) CASCADE;
DROP FUNCTION IF EXISTS public.usp_doc_salesdocument_list(p_tipo_operacion character varying, p_search character varying DEFAULT NULL::character varying, p_codigo character varying DEFAULT NULL::character varying, p_from_date date DEFAULT NULL::date, p_to_date date DEFAULT NULL::date, p_page integer DEFAULT 1, p_limit integer DEFAULT 50)
 RETURNS TABLE("SalesDocumentId" bigint, "DocumentNumber" character varying, "SerialType" character varying, "FiscalMemoryNumber" character varying, "OperationType" character varying, "CustomerCode" character varying, "CustomerName" character varying, "FiscalId" character varying, "DocumentDate" timestamp without time zone, "DueDate" timestamp without time zone, "DocumentTime" character varying, "SubTotal" numeric, "TaxableAmount" numeric, "ExemptAmount" numeric, "TaxAmount" numeric, "TaxRate" numeric, "TotalAmount" numeric, "DiscountAmount" numeric, "IsVoided" boolean, "IsPaid" character varying, "IsInvoiced" character varying, "IsDelivered" character varying, "OriginDocumentNumber" character varying, "OriginDocumentType" character varying, "ControlNumber" character varying, "IsLegal" character varying, "IsPrinted" boolean, "Notes" character varying, "Concept" character varying, "PaymentTerms" character varying, "ShipToAddress" character varying, "SellerCode" character varying, "DepartmentCode" character varying, "LocationCode" character varying, "CurrencyCode" character varying, "ExchangeRate" numeric, "UserCode" character varying, "ReportDate" timestamp without time zone, "HostName" character varying, "VehiclePlate" character varying, "Mileage" numeric, "TollAmount" numeric, "CreatedAt" timestamp without time zone, "UpdatedAt" timestamp without time zone, "IsDeleted" boolean, "TotalCount" bigint)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_total  BIGINT;
    v_page   INT := GREATEST(p_page, 1);
    v_limit  INT := LEAST(GREATEST(p_limit, 1), 500);
BEGIN
    SELECT COUNT(*) INTO v_total
    FROM doc."SalesDocument"
    WHERE "OperationType" = p_tipo_operacion
      AND "IsDeleted" = FALSE
      AND (p_search IS NULL OR (
            "DocumentNumber" LIKE '%' || p_search || '%'
            OR "CustomerName" LIKE '%' || p_search || '%'
            OR "FiscalId" LIKE '%' || p_search || '%'
          ))
      AND (p_codigo IS NULL OR "CustomerCode" = p_codigo)
      AND (p_from_date IS NULL OR "DocumentDate" >= p_from_date)
      AND (p_to_date IS NULL OR "DocumentDate" < (p_to_date + INTERVAL '1 day'));

    RETURN QUERY
    SELECT
        sd."SalesDocumentId",
        sd."DocumentNumber"::VARCHAR,
        sd."SerialType"::VARCHAR,
        sd."FiscalMemoryNumber"::VARCHAR,
        sd."OperationType"::VARCHAR,
        sd."CustomerCode"::VARCHAR,
        sd."CustomerName"::VARCHAR,
        sd."FiscalId"::VARCHAR,
        sd."DocumentDate",
        sd."DueDate",
        sd."DocumentTime"::VARCHAR,
        sd."SubTotal",
        sd."TaxableAmount",
        sd."ExemptAmount",
        sd."TaxAmount",
        sd."TaxRate",
        sd."TotalAmount",
        sd."DiscountAmount",
        sd."IsVoided",
        sd."IsPaid"::VARCHAR,
        sd."IsInvoiced"::VARCHAR,
        sd."IsDelivered"::VARCHAR,
        sd."OriginDocumentNumber"::VARCHAR,
        sd."OriginDocumentType"::VARCHAR,
        sd."ControlNumber"::VARCHAR,
        sd."IsLegal"::VARCHAR,
        sd."IsPrinted",
        sd."Notes"::TEXT,
        sd."Concept"::VARCHAR,
        sd."PaymentTerms"::VARCHAR,
        sd."ShipToAddress"::VARCHAR,
        sd."SellerCode"::VARCHAR,
        sd."DepartmentCode"::VARCHAR,
        sd."LocationCode"::VARCHAR,
        sd."CurrencyCode"::VARCHAR,
        sd."ExchangeRate",
        sd."UserCode"::VARCHAR,
        sd."ReportDate",
        sd."HostName"::VARCHAR,
        sd."VehiclePlate"::VARCHAR,
        sd."Mileage",
        sd."TollAmount",
        sd."CreatedAt",
        sd."UpdatedAt",
        sd."IsDeleted",
        v_total
    FROM doc."SalesDocument" sd
    WHERE sd."OperationType" = p_tipo_operacion
      AND sd."IsDeleted" = FALSE
      AND (p_search IS NULL OR (
            sd."DocumentNumber" LIKE '%' || p_search || '%'
            OR sd."CustomerName" LIKE '%' || p_search || '%'
            OR sd."FiscalId" LIKE '%' || p_search || '%'
          ))
      AND (p_codigo IS NULL OR sd."CustomerCode" = p_codigo)
      AND (p_from_date IS NULL OR sd."DocumentDate" >= p_from_date)
      AND (p_to_date IS NULL OR sd."DocumentDate" < (p_to_date + INTERVAL '1 day'))
    ORDER BY sd."DocumentDate" DESC, sd."DocumentNumber" DESC
    LIMIT v_limit OFFSET (v_page - 1) * v_limit;
END;
$function$
;

-- usp_doc_salesdocument_upsert
DROP FUNCTION IF EXISTS public.usp_doc_salesdocument_upsert(character varying, jsonb, jsonb, jsonb, character varying, character varying) CASCADE;
DROP FUNCTION IF EXISTS public.usp_doc_salesdocument_upsert(p_tipo_operacion character varying, p_header_json jsonb, p_detail_json jsonb, p_payments_json jsonb DEFAULT NULL::jsonb, p_doc_origen character varying DEFAULT NULL::character varying, p_tipo_doc_origen character varying DEFAULT NULL::character varying)
 RETURNS TABLE(ok boolean, "numDoc" character varying, "detalleRows" integer, "formasPagoRows" integer, "pendingAmount" numeric)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_num_doc           VARCHAR(60);
    v_detalle_rows      INT := 0;
    v_formas_pago_rows  INT := 0;
    v_pending_amount    NUMERIC(18,4) := 0;
    -- Header fields
    v_serial_type       VARCHAR(60);
    v_fiscal_memory     VARCHAR(10);
    v_customer_code     VARCHAR(60);
    v_customer_name     VARCHAR(200);
    v_fiscal_id         VARCHAR(60);
    v_document_date     TIMESTAMP;
    v_due_date          TIMESTAMP;
    v_document_time     VARCHAR(20);
    v_sub_total         NUMERIC(18,4);
    v_taxable_amount    NUMERIC(18,4);
    v_exempt_amount     NUMERIC(18,4);
    v_tax_amount        NUMERIC(18,4);
    v_tax_rate          NUMERIC(8,4);
    v_total_amount      NUMERIC(18,4);
    v_discount_amount   NUMERIC(18,4);
    v_is_voided         BOOLEAN;
    v_is_paid           VARCHAR(10);
    v_is_invoiced       VARCHAR(10);
    v_is_delivered      VARCHAR(10);
    v_origin_doc_number VARCHAR(60);
    v_origin_doc_type   VARCHAR(20);
    v_control_number    VARCHAR(60);
    v_is_legal          VARCHAR(10);
    v_is_printed        BOOLEAN;
    v_notes             TEXT;
    v_concept           VARCHAR(200);
    v_payment_terms     VARCHAR(100);
    v_ship_to_address   VARCHAR(500);
    v_seller_code       VARCHAR(60);
    v_department_code   VARCHAR(60);
    v_location_code     VARCHAR(60);
    v_currency_code     VARCHAR(10);
    v_exchange_rate     NUMERIC(18,6);
    v_user_code         VARCHAR(60);
    v_report_date       TIMESTAMP;
    v_host_name         VARCHAR(100);
    v_vehicle_plate     VARCHAR(30);
    v_mileage           NUMERIC(18,2);
    v_toll_amount       NUMERIC(18,4);
    -- AR sync
    v_cod_cliente       VARCHAR(60);
    v_company_id        INT;
    v_branch_id         INT;
    v_customer_id       BIGINT;
    v_user_id           INT;
    v_total_pagado      NUMERIC(18,4) := 0;
    v_ar_status         VARCHAR(20);
    v_ar_paid_flag      BOOLEAN;
BEGIN
    -- Parsear cabecera
    v_num_doc           := TRIM(p_header_json->>'DocumentNumber');
    v_serial_type       := COALESCE(p_header_json->>'SerialType', '');
    v_fiscal_memory     := COALESCE(p_header_json->>'FiscalMemoryNumber', '1');
    v_customer_code     := p_header_json->>'CustomerCode';
    v_customer_name     := p_header_json->>'CustomerName';
    v_fiscal_id         := p_header_json->>'FiscalId';
    v_document_date     := COALESCE((p_header_json->>'DocumentDate')::TIMESTAMP, NOW() AT TIME ZONE 'UTC');
    v_due_date          := (p_header_json->>'DueDate')::TIMESTAMP;
    v_document_time     := p_header_json->>'DocumentTime';
    v_sub_total         := COALESCE((p_header_json->>'SubTotal')::NUMERIC, 0);
    v_taxable_amount    := (p_header_json->>'TaxableAmount')::NUMERIC;
    v_exempt_amount     := (p_header_json->>'ExemptAmount')::NUMERIC;
    v_tax_amount        := COALESCE((p_header_json->>'TaxAmount')::NUMERIC, 0);
    v_tax_rate          := COALESCE((p_header_json->>'TaxRate')::NUMERIC, 0);
    v_total_amount      := COALESCE((p_header_json->>'TotalAmount')::NUMERIC, 0);
    v_discount_amount   := (p_header_json->>'DiscountAmount')::NUMERIC;
    v_is_voided         := COALESCE((p_header_json->>'IsVoided')::BOOLEAN, FALSE);
    v_is_paid           := COALESCE(p_header_json->>'IsPaid', 'N');
    v_is_invoiced       := COALESCE(p_header_json->>'IsInvoiced', 'N');
    v_is_delivered      := COALESCE(p_header_json->>'IsDelivered', 'N');
    v_origin_doc_number := COALESCE(p_doc_origen, p_header_json->>'OriginDocumentNumber');
    v_origin_doc_type   := COALESCE(p_tipo_doc_origen, p_header_json->>'OriginDocumentType');
    v_control_number    := p_header_json->>'ControlNumber';
    v_is_legal          := p_header_json->>'IsLegal';
    v_is_printed        := (p_header_json->>'IsPrinted')::BOOLEAN;
    v_notes             := p_header_json->>'Notes';
    v_concept           := p_header_json->>'Concept';
    v_payment_terms     := p_header_json->>'PaymentTerms';
    v_ship_to_address   := p_header_json->>'ShipToAddress';
    v_seller_code       := p_header_json->>'SellerCode';
    v_department_code   := p_header_json->>'DepartmentCode';
    v_location_code     := p_header_json->>'LocationCode';
    v_currency_code     := p_header_json->>'CurrencyCode';
    v_exchange_rate     := (p_header_json->>'ExchangeRate')::NUMERIC;
    v_user_code         := p_header_json->>'UserCode';
    v_report_date       := COALESCE((p_header_json->>'ReportDate')::TIMESTAMP, NOW() AT TIME ZONE 'UTC');
    v_host_name         := p_header_json->>'HostName';
    v_vehicle_plate     := p_header_json->>'VehiclePlate';
    v_mileage           := (p_header_json->>'Mileage')::NUMERIC;
    v_toll_amount       := (p_header_json->>'TollAmount')::NUMERIC;

    -- Validar DocumentNumber
    IF v_num_doc IS NULL OR v_num_doc = '' THEN
        RETURN QUERY SELECT FALSE, NULL::VARCHAR, 0, 0, 0::NUMERIC;
        RETURN;
    END IF;

    -- DELETE existente (detalle, pagos, cabecera)
    DELETE FROM doc."SalesDocumentLine"
    WHERE "DocumentNumber" = v_num_doc AND "OperationType" = p_tipo_operacion;

    DELETE FROM doc."SalesDocumentPayment"
    WHERE "DocumentNumber" = v_num_doc AND "OperationType" = p_tipo_operacion;

    DELETE FROM doc."SalesDocument"
    WHERE "DocumentNumber" = v_num_doc AND "OperationType" = p_tipo_operacion;

    -- INSERT cabecera
    INSERT INTO doc."SalesDocument" (
        "DocumentNumber", "SerialType", "FiscalMemoryNumber", "OperationType",
        "CustomerCode", "CustomerName", "FiscalId",
        "DocumentDate", "DueDate", "DocumentTime",
        "SubTotal", "TaxableAmount", "ExemptAmount", "TaxAmount", "TaxRate",
        "TotalAmount", "DiscountAmount",
        "IsVoided", "IsPaid", "IsInvoiced", "IsDelivered",
        "OriginDocumentNumber", "OriginDocumentType",
        "ControlNumber", "IsLegal", "IsPrinted",
        "Notes", "Concept", "PaymentTerms", "ShipToAddress",
        "SellerCode", "DepartmentCode", "LocationCode",
        "CurrencyCode", "ExchangeRate",
        "UserCode", "ReportDate", "HostName",
        "VehiclePlate", "Mileage", "TollAmount",
        "CreatedAt", "UpdatedAt", "IsDeleted"
    )
    VALUES (
        v_num_doc, v_serial_type, v_fiscal_memory, p_tipo_operacion,
        v_customer_code, v_customer_name, v_fiscal_id,
        v_document_date, v_due_date, v_document_time,
        v_sub_total, v_taxable_amount, v_exempt_amount, v_tax_amount, v_tax_rate,
        v_total_amount, v_discount_amount,
        v_is_voided, v_is_paid, v_is_invoiced, v_is_delivered,
        v_origin_doc_number, v_origin_doc_type,
        v_control_number, v_is_legal, v_is_printed,
        v_notes, v_concept, v_payment_terms, v_ship_to_address,
        v_seller_code, v_department_code, v_location_code,
        v_currency_code, v_exchange_rate,
        v_user_code, v_report_date, v_host_name,
        v_vehicle_plate, v_mileage, v_toll_amount,
        NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC', FALSE
    );

    -- INSERT lineas de detalle desde JSONB
    IF p_detail_json IS NOT NULL AND jsonb_array_length(p_detail_json) > 0 THEN
        INSERT INTO doc."SalesDocumentLine" (
            "DocumentNumber", "SerialType", "FiscalMemoryNumber", "OperationType",
            "LineNumber", "ProductCode", "Description", "AlternateCode",
            "Quantity", "UnitPrice", "DiscountedPrice", "UnitCost",
            "SubTotal", "DiscountAmount", "TotalAmount",
            "TaxRate", "TaxAmount",
            "IsVoided", "RelatedRef",
            "UserCode", "LineDate",
            "CreatedAt", "UpdatedAt", "IsDeleted"
        )
        SELECT
            v_num_doc,
            COALESCE(elem->>'SerialType', v_serial_type),
            COALESCE(elem->>'FiscalMemoryNumber', v_fiscal_memory),
            p_tipo_operacion,
            (elem->>'LineNumber')::INT,
            elem->>'ProductCode',
            elem->>'Description',
            elem->>'AlternateCode',
            COALESCE((elem->>'Quantity')::NUMERIC, 0),
            COALESCE((elem->>'UnitPrice')::NUMERIC, 0),
            (elem->>'DiscountedPrice')::NUMERIC,
            (elem->>'UnitCost')::NUMERIC,
            COALESCE((elem->>'SubTotal')::NUMERIC, 0),
            COALESCE((elem->>'DiscountAmount')::NUMERIC, 0),
            COALESCE((elem->>'TotalAmount')::NUMERIC, 0),
            COALESCE((elem->>'TaxRate')::NUMERIC, 0),
            COALESCE((elem->>'TaxAmount')::NUMERIC, 0),
            COALESCE((elem->>'IsVoided')::BOOLEAN, FALSE),
            elem->>'RelatedRef',
            COALESCE(elem->>'UserCode', v_user_code),
            COALESCE((elem->>'LineDate')::TIMESTAMP, NOW() AT TIME ZONE 'UTC'),
            NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC', FALSE
        FROM jsonb_array_elements(p_detail_json) elem;

        GET DIAGNOSTICS v_detalle_rows = ROW_COUNT;
    END IF;

    -- INSERT formas de pago desde JSONB
    IF p_payments_json IS NOT NULL AND jsonb_array_length(p_payments_json) > 0 THEN
        INSERT INTO doc."SalesDocumentPayment" (
            "DocumentNumber", "SerialType", "FiscalMemoryNumber", "OperationType",
            "PaymentMethod", "BankCode", "PaymentNumber",
            "Amount", "AmountBs", "ExchangeRate",
            "PaymentDate", "DueDate",
            "ReferenceNumber", "UserCode",
            "CreatedAt", "UpdatedAt", "IsDeleted"
        )
        SELECT
            v_num_doc,
            COALESCE(elem->>'SerialType', v_serial_type),
            COALESCE(elem->>'FiscalMemoryNumber', v_fiscal_memory),
            p_tipo_operacion,
            elem->>'PaymentMethod',
            elem->>'BankCode',
            elem->>'PaymentNumber',
            COALESCE((elem->>'Amount')::NUMERIC, 0),
            COALESCE((elem->>'AmountBs')::NUMERIC, 0),
            COALESCE((elem->>'ExchangeRate')::NUMERIC, 1),
            COALESCE((elem->>'PaymentDate')::TIMESTAMP, NOW() AT TIME ZONE 'UTC'),
            (elem->>'DueDate')::TIMESTAMP,
            elem->>'ReferenceNumber',
            COALESCE(elem->>'UserCode', v_user_code),
            NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC', FALSE
        FROM jsonb_array_elements(p_payments_json) elem;

        GET DIAGNOSTICS v_formas_pago_rows = ROW_COUNT;
    END IF;

    -- Sincronizar cuenta por cobrar para FACT/NOTADEB/NOTACRED
    IF p_tipo_operacion IN ('FACT', 'NOTADEB', 'NOTACRED') THEN
        v_cod_cliente := TRIM(COALESCE(v_customer_code, ''));

        IF v_cod_cliente <> '' THEN
            -- Resolver contexto canonico
            SELECT c."CompanyId" INTO v_company_id
            FROM cfg."Company" c
            WHERE c."IsDeleted" = FALSE AND c."IsActive" = TRUE
            ORDER BY CASE WHEN c."CompanyCode" = 'DEFAULT' THEN 0 ELSE 1 END, c."CompanyId"
            LIMIT 1;

            SELECT b."BranchId" INTO v_branch_id
            FROM cfg."Branch" b
            WHERE b."CompanyId" = v_company_id AND b."IsDeleted" = FALSE AND b."IsActive" = TRUE
            ORDER BY CASE WHEN b."BranchCode" = 'MAIN' THEN 0 ELSE 1 END, b."BranchId"
            LIMIT 1;

            SELECT "CustomerId" INTO v_customer_id
            FROM master."Customer"
            WHERE "CustomerCode" = v_cod_cliente
              AND "CompanyId" = v_company_id
              AND "IsDeleted" = FALSE
            LIMIT 1;

            IF v_customer_id IS NOT NULL AND v_company_id IS NOT NULL AND v_branch_id IS NOT NULL THEN
                -- Calcular monto pendiente
                IF UPPER(v_is_paid)::character varying = 'S' THEN
                    v_pending_amount := 0;
                ELSE
                    IF p_payments_json IS NOT NULL AND jsonb_array_length(p_payments_json) > 0 THEN
                        SELECT COALESCE(SUM(COALESCE((elem->>'Amount')::NUMERIC, 0)), 0)
                        INTO v_total_pagado
                        FROM jsonb_array_elements(p_payments_json) elem
                        WHERE UPPER(COALESCE(elem->>'PaymentMethod', ''))::character varying NOT LIKE '%SALDO%';
                    END IF;

                    v_pending_amount := CASE
                        WHEN v_total_amount - v_total_pagado > 0 THEN v_total_amount - v_total_pagado
                        ELSE 0
                    END;
                END IF;

                -- Determinar status
                v_ar_status := CASE
                    WHEN v_pending_amount <= 0              THEN 'PAID'
                    WHEN v_pending_amount < v_total_amount  THEN 'PARTIAL'
                    ELSE                                         'PENDING'
                END;
                v_ar_paid_flag := (v_pending_amount <= 0);

                -- Resolver UserId
                IF v_user_code IS NOT NULL AND v_user_code <> '' THEN
                    SELECT "UserId" INTO v_user_id
                    FROM sec."User"
                    WHERE "UserCode" = v_user_code AND "IsDeleted" = FALSE
                    LIMIT 1;
                END IF;

                -- Upsert ar.ReceivableDocument
                IF EXISTS (
                    SELECT 1 FROM ar."ReceivableDocument"
                    WHERE "CompanyId" = v_company_id
                      AND "BranchId"  = v_branch_id
                      AND "DocumentType"   = p_tipo_operacion
                      AND "DocumentNumber" = v_num_doc
                ) THEN
                    UPDATE ar."ReceivableDocument"
                    SET "CustomerId"      = v_customer_id,
                        "IssueDate"       = v_document_date,
                        "DueDate"         = COALESCE(v_due_date, v_document_date),
                        "TotalAmount"     = v_total_amount,
                        "PendingAmount"   = v_pending_amount,
                        "PaidFlag"        = v_ar_paid_flag,
                        "Status"          = v_ar_status,
                        "Notes"           = v_notes,
                        "UpdatedAt"       = NOW() AT TIME ZONE 'UTC',
                        "UpdatedByUserId" = v_user_id
                    WHERE "CompanyId"      = v_company_id
                      AND "BranchId"       = v_branch_id
                      AND "DocumentType"   = p_tipo_operacion
                      AND "DocumentNumber" = v_num_doc;
                ELSE
                    INSERT INTO ar."ReceivableDocument" (
                        "CompanyId", "BranchId", "CustomerId", "DocumentType", "DocumentNumber",
                        "IssueDate", "DueDate", "CurrencyCode",
                        "TotalAmount", "PendingAmount", "PaidFlag", "Status", "Notes",
                        "CreatedAt", "UpdatedAt", "CreatedByUserId", "UpdatedByUserId"
                    )
                    VALUES (
                        v_company_id, v_branch_id, v_customer_id, p_tipo_operacion, v_num_doc,
                        v_document_date, COALESCE(v_due_date, v_document_date), COALESCE(v_currency_code, 'USD'),
                        v_total_amount, v_pending_amount, v_ar_paid_flag, v_ar_status, v_notes,
                        NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC', v_user_id, v_user_id
                    );
                END IF;

                -- Actualizar saldo del cliente
                PERFORM usp_master_customer_updatebalance(v_customer_id, v_user_id);
            END IF;
        END IF;
    END IF;

    RETURN QUERY SELECT TRUE, v_num_doc, v_detalle_rows, v_formas_pago_rows, v_pending_amount;
END;
$function$
;

-- usp_doc_salesdocument_void
DROP FUNCTION IF EXISTS public.usp_doc_salesdocument_void(character varying, character varying, character varying, character varying) CASCADE;
DROP FUNCTION IF EXISTS public.usp_doc_salesdocument_void(p_tipo_operacion character varying, p_num_doc character varying, p_cod_usuario character varying DEFAULT 'API'::character varying, p_motivo character varying DEFAULT ''::character varying)
 RETURNS TABLE(ok boolean, "numFact" character varying, "codCliente" character varying, mensaje character varying)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_cod_cliente  VARCHAR(60);
    v_company_id   INT;
    v_branch_id    INT;
    v_customer_id  BIGINT;
BEGIN
    -- Validar que el documento existe
    IF NOT EXISTS (
        SELECT 1 FROM doc."SalesDocument"
        WHERE "DocumentNumber" = p_num_doc
          AND "OperationType" = p_tipo_operacion
          AND "IsDeleted" = FALSE
    ) THEN
        RETURN QUERY SELECT FALSE, p_num_doc, NULL::VARCHAR,
            ('Documento no encontrado: ' || p_num_doc || ' / ' || p_tipo_operacion)::TEXT;
        RETURN;
    END IF;

    -- Validar que no esta ya anulado
    IF EXISTS (
        SELECT 1 FROM doc."SalesDocument"
        WHERE "DocumentNumber" = p_num_doc
          AND "OperationType" = p_tipo_operacion
          AND "IsDeleted" = FALSE
          AND "IsVoided" = TRUE
    ) THEN
        RETURN QUERY SELECT FALSE, p_num_doc, NULL::VARCHAR,
            ('El documento ya se encuentra anulado: ' || p_num_doc)::TEXT;
        RETURN;
    END IF;

    -- Obtener codigo de cliente
    SELECT "CustomerCode" INTO v_cod_cliente
    FROM doc."SalesDocument"
    WHERE "DocumentNumber" = p_num_doc
      AND "OperationType" = p_tipo_operacion
      AND "IsDeleted" = FALSE;

    -- Anular cabecera
    UPDATE doc."SalesDocument"
    SET "IsVoided"  = TRUE,
        "Notes"     = CONCAT(COALESCE("Notes", ''), ' | ANULADO ',
                       to_char(NOW() AT TIME ZONE 'UTC', 'YYYY-MM-DD HH24:MI'),
                       ' por ', p_cod_usuario,
                       CASE WHEN p_motivo <> '' THEN ' - Motivo: ' || p_motivo ELSE '' END),
        "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
    WHERE "DocumentNumber" = p_num_doc
      AND "OperationType" = p_tipo_operacion
      AND "IsDeleted" = FALSE;

    -- Anular lineas
    UPDATE doc."SalesDocumentLine"
    SET "IsVoided"  = TRUE,
        "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
    WHERE "DocumentNumber" = p_num_doc
      AND "OperationType" = p_tipo_operacion
      AND "IsDeleted" = FALSE;

    -- Resolver contexto
    SELECT c."CompanyId" INTO v_company_id
    FROM cfg."Company" c
    WHERE c."IsDeleted" = FALSE AND c."IsActive" = TRUE
    ORDER BY c."CompanyId"
    LIMIT 1;

    SELECT b."BranchId" INTO v_branch_id
    FROM cfg."Branch" b
    WHERE b."CompanyId" = v_company_id AND b."IsDeleted" = FALSE AND b."IsActive" = TRUE
    ORDER BY b."BranchId"
    LIMIT 1;

    -- Resolver CustomerId
    SELECT "CustomerId" INTO v_customer_id
    FROM master."Customer"
    WHERE "CustomerCode" = v_cod_cliente
      AND "CompanyId" = v_company_id
      AND "IsDeleted" = FALSE
    LIMIT 1;

    -- Actualizar cuenta por cobrar si existe
    IF v_customer_id IS NOT NULL AND v_company_id IS NOT NULL AND v_branch_id IS NOT NULL THEN
        UPDATE ar."ReceivableDocument"
        SET "PendingAmount" = 0,
            "PaidFlag"      = TRUE,
            "Status"        = 'VOIDED',
            "UpdatedAt"     = NOW() AT TIME ZONE 'UTC'
        WHERE "CompanyId"      = v_company_id
          AND "BranchId"       = v_branch_id
          AND "DocumentNumber" = p_num_doc
          AND "DocumentType"   = p_tipo_operacion
          AND "CustomerId"     = v_customer_id;

        -- Recalcular saldo total del cliente
        UPDATE master."Customer"
        SET "TotalBalance" = COALESCE((
                SELECT SUM("PendingAmount")
                FROM ar."ReceivableDocument"
                WHERE "CustomerId" = v_customer_id
                  AND "Status" <> 'VOIDED'
            ), 0),
            "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
        WHERE "CustomerId" = v_customer_id;
    END IF;

    RETURN QUERY SELECT TRUE, p_num_doc, v_cod_cliente,
        ('Documento anulado exitosamente: ' || p_num_doc)::TEXT;
END;
$function$
;

-- usp_facturas_getbynumfact
DROP FUNCTION IF EXISTS public.usp_facturas_getbynumfact(character varying) CASCADE;
DROP FUNCTION IF EXISTS public.usp_facturas_getbynumfact(p_num_fact character varying)
 RETURNS TABLE("Id" integer, "DocumentNumber" character varying, "OperationType" character varying, "DocumentDate" timestamp without time zone, "UserCode" character varying, "ClientCode" character varying, "ClientName" character varying, "SubTotal" numeric, "TaxAmount" numeric, "TotalAmount" numeric, "Currency" character varying, "ExchangeRate" numeric, "Notes" character varying, "IsDeleted" boolean, "CreatedAt" timestamp without time zone, "UpdatedAt" timestamp without time zone)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        sd."Id",
        sd."DocumentNumber",
        sd."OperationType",
        sd."DocumentDate",
        sd."UserCode",
        sd."ClientCode",
        sd."ClientName",
        sd."SubTotal",
        sd."TaxAmount",
        sd."TotalAmount",
        sd."Currency",
        sd."ExchangeRate",
        sd."Notes",
        sd."IsDeleted",
        sd."CreatedAt",
        sd."UpdatedAt"
    FROM ar."SalesDocument" sd
    WHERE sd."DocumentNumber" = p_num_fact
      AND sd."OperationType" = 'FACT'
      AND sd."IsDeleted" = FALSE;
END;
$function$
;

-- usp_facturas_list
DROP FUNCTION IF EXISTS public.usp_facturas_list(character varying, character varying, date, date, integer, integer) CASCADE;
DROP FUNCTION IF EXISTS public.usp_facturas_list(p_num_fact character varying DEFAULT NULL::character varying, p_cod_usuario character varying DEFAULT NULL::character varying, p_from date DEFAULT NULL::date, p_to date DEFAULT NULL::date, p_page integer DEFAULT 1, p_limit integer DEFAULT 50)
 RETURNS TABLE("TotalCount" integer, "Id" integer, "DocumentNumber" character varying, "OperationType" character varying, "DocumentDate" timestamp without time zone, "UserCode" character varying, "ClientCode" character varying, "ClientName" character varying, "SubTotal" numeric, "TaxAmount" numeric, "TotalAmount" numeric, "Currency" character varying, "ExchangeRate" numeric, "Notes" character varying, "IsDeleted" boolean, "CreatedAt" timestamp without time zone, "UpdatedAt" timestamp without time zone)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_offset INT;
    v_limit  INT;
    v_total  INT;
BEGIN
    v_limit  := COALESCE(NULLIF(p_limit, 0), 50);
    IF v_limit < 1 THEN v_limit := 50; END IF;
    IF v_limit > 500 THEN v_limit := 500; END IF;
    v_offset := (COALESCE(NULLIF(p_page, 0), 1) - 1) * v_limit;
    IF v_offset < 0 THEN v_offset := 0; END IF;

    -- Contar total
    SELECT COUNT(1) INTO v_total
    FROM ar."SalesDocument" sd
    WHERE sd."OperationType" = 'FACT'
      AND sd."IsDeleted" = FALSE
      AND (p_num_fact IS NULL OR TRIM(p_num_fact) = '' OR sd."DocumentNumber" = p_num_fact)
      AND (p_cod_usuario IS NULL OR TRIM(p_cod_usuario) = '' OR sd."UserCode" = p_cod_usuario)
      AND (p_from IS NULL OR sd."DocumentDate" >= p_from)
      AND (p_to IS NULL OR sd."DocumentDate" <= p_to);

    -- Devolver filas
    RETURN QUERY
    SELECT
        v_total,
        sd."Id",
        sd."DocumentNumber",
        sd."OperationType",
        sd."DocumentDate",
        sd."UserCode",
        sd."ClientCode",
        sd."ClientName",
        sd."SubTotal",
        sd."TaxAmount",
        sd."TotalAmount",
        sd."Currency",
        sd."ExchangeRate",
        sd."Notes",
        sd."IsDeleted",
        sd."CreatedAt",
        sd."UpdatedAt"
    FROM ar."SalesDocument" sd
    WHERE sd."OperationType" = 'FACT'
      AND sd."IsDeleted" = FALSE
      AND (p_num_fact IS NULL OR TRIM(p_num_fact) = '' OR sd."DocumentNumber" = p_num_fact)
      AND (p_cod_usuario IS NULL OR TRIM(p_cod_usuario) = '' OR sd."UserCode" = p_cod_usuario)
      AND (p_from IS NULL OR sd."DocumentDate" >= p_from)
      AND (p_to IS NULL OR sd."DocumentDate" <= p_to)
    ORDER BY sd."DocumentDate" DESC
    LIMIT v_limit OFFSET v_offset;
END;
$function$
;

-- usp_pedidos_getbynumfact
DROP FUNCTION IF EXISTS public.usp_pedidos_getbynumfact(character varying) CASCADE;
DROP FUNCTION IF EXISTS public.usp_pedidos_getbynumfact(p_num_fact character varying)
 RETURNS TABLE("NUM_FACT" character varying, "CODIGO" character varying, "NOMBRE" character varying, "RIF" character varying, "FECHA" timestamp without time zone, "SUBTOTAL" numeric, "IMPUESTO" numeric, "TOTAL" numeric)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        p."NUM_FACT",
        p."CODIGO",
        p."NOMBRE",
        p."RIF",
        p."FECHA",
        p."SUBTOTAL",
        p."IMPUESTO",
        p."TOTAL"
    FROM public."Pedidos" p
    WHERE p."NUM_FACT" = p_num_fact;
END;
$function$
;

-- usp_pedidos_list
DROP FUNCTION IF EXISTS public.usp_pedidos_list(character varying, character varying, integer, integer) CASCADE;
DROP FUNCTION IF EXISTS public.usp_pedidos_list(p_search character varying DEFAULT NULL::character varying, p_codigo character varying DEFAULT NULL::character varying, p_page integer DEFAULT 1, p_limit integer DEFAULT 50)
 RETURNS TABLE("NUM_FACT" character varying, "CODIGO" character varying, "NOMBRE" character varying, "RIF" character varying, "FECHA" timestamp without time zone, "SUBTOTAL" numeric, "IMPUESTO" numeric, "TOTAL" numeric, "TotalCount" bigint)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_offset INT;
    v_total BIGINT;
    v_search_param VARCHAR(100);
BEGIN
    v_offset := (COALESCE(NULLIF(p_page, 0), 1) - 1) * COALESCE(NULLIF(p_limit, 0), 50);
    IF v_offset < 0 THEN v_offset := 0; END IF;
    IF p_limit < 1 THEN p_limit := 50; END IF;
    IF p_limit > 500 THEN p_limit := 500; END IF;

    v_search_param := NULL;
    IF p_search IS NOT NULL AND TRIM(p_search) <> '' THEN
        v_search_param := '%' || p_search || '%';
    END IF;

    SELECT COUNT(1) INTO v_total
    FROM public."Pedidos" p
    WHERE (v_search_param IS NULL
           OR p."NUM_FACT" LIKE v_search_param
           OR p."NOMBRE" LIKE v_search_param
           OR p."RIF" LIKE v_search_param)
      AND (p_codigo IS NULL OR TRIM(p_codigo) = '' OR p."CODIGO" = p_codigo);

    RETURN QUERY
    SELECT
        p."NUM_FACT",
        p."CODIGO",
        p."NOMBRE",
        p."RIF",
        p."FECHA",
        p."SUBTOTAL",
        p."IMPUESTO",
        p."TOTAL",
        v_total AS "TotalCount"
    FROM public."Pedidos" p
    WHERE (v_search_param IS NULL
           OR p."NUM_FACT" LIKE v_search_param
           OR p."NOMBRE" LIKE v_search_param
           OR p."RIF" LIKE v_search_param)
      AND (p_codigo IS NULL OR TRIM(p_codigo) = '' OR p."CODIGO" = p_codigo)
    ORDER BY p."FECHA" DESC
    LIMIT p_limit OFFSET v_offset;
END;
$function$
;

