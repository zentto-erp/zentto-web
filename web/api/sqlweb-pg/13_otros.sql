-- sp_anular_compra_tx
DROP FUNCTION IF EXISTS public.sp_anular_compra_tx(character varying, character varying, character varying) CASCADE;
CREATE OR REPLACE FUNCTION public.sp_anular_compra_tx(p_num_fact character varying, p_cod_usuario character varying DEFAULT 'API'::character varying, p_motivo character varying DEFAULT ''::character varying)
 RETURNS TABLE(ok boolean, "numFact" character varying, "codProveedor" character varying, mensaje character varying)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_fecha_anulacion  TIMESTAMP;
    v_cod_proveedor    VARCHAR(60);
    v_fecha_compra     TIMESTAMP;
    v_ya_anulada       BOOLEAN;
    v_saldo_total      DOUBLE PRECISION;
BEGIN
    v_fecha_anulacion := NOW() AT TIME ZONE 'UTC';

    -- ============================================
    -- 1. Validar que la compra existe
    -- TODO: tabla Compras es legacy
    -- ============================================
    SELECT
        "COD_PROVEEDOR",
        "FECHA",
        CASE WHEN "ANULADA"::TEXT IN ('1', 'true') THEN TRUE ELSE FALSE END
    INTO v_cod_proveedor, v_fecha_compra, v_ya_anulada
    FROM "Compras"
    WHERE "NUM_FACT" = p_num_fact;

    IF v_cod_proveedor IS NULL THEN
        RAISE EXCEPTION 'compra_not_found';
    END IF;

    IF v_ya_anulada = TRUE THEN
        RAISE EXCEPTION 'compra_already_anulled';
    END IF;

    -- ============================================
    -- 2. Marcar compra como anulada
    -- TODO: tabla Compras es legacy
    -- ============================================
    UPDATE "Compras"
    SET "ANULADA" = 1,
        "CONCEPTO" = COALESCE("CONCEPTO", '') || ' [ANULADA: ' || TO_CHAR(v_fecha_anulacion, 'YYYY-MM-DD HH24:MI:SS') || ']'
    WHERE "NUM_FACT" = p_num_fact;

    -- ============================================
    -- 3. Anular detalle
    -- TODO: tabla Detalle_Compras es legacy
    -- ============================================
    UPDATE "Detalle_Compras"
    SET "ANULADA" = 1
    WHERE "NUM_FACT" = p_num_fact;

    -- ============================================
    -- 4. Revertir master."Product" — restar lo que se habia sumado
    -- ============================================
    CREATE TEMP TABLE _detalles_compra_anul (
        "CODIGO"   VARCHAR(60),
        "CANTIDAD" DOUBLE PRECISION
    ) ON COMMIT DROP;

    -- TODO: tabla Detalle_Compras es legacy
    INSERT INTO _detalles_compra_anul ("CODIGO", "CANTIDAD")
    SELECT
        "CODIGO",
        COALESCE("CANTIDAD", 0)
    FROM "Detalle_Compras"
    WHERE "NUM_FACT" = p_num_fact
      AND COALESCE("ANULADA"::INT, 0) = 0;

    -- Insertar movimiento de anulacion en MovInvent
    INSERT INTO "MovInvent" (
        "DOCUMENTO", "CODIGO", "PRODUCT", "FECHA", "MOTIVO", "TIPO",
        "CANTIDAD_ACTUAL", "CANTIDAD", "CANTIDAD_NUEVA", "CO_USUARIO",
        "PRECIO_COMPRA", "ALICUOTA", "PRECIO_VENTA", "ANULADA"
    )
    SELECT
        p_num_fact || '_ANUL',
        d."CODIGO",
        d."CODIGO",
        v_fecha_anulacion,
        'Anulacion Compra:' || p_num_fact || ' - ' || p_motivo,
        'Anulacion Ingreso',
        COALESCE(i."StockQty", 0),
        d."CANTIDAD",
        COALESCE(i."StockQty", 0) - d."CANTIDAD",
        p_cod_usuario,
        COALESCE(i."COSTO_REFERENCIA", 0),
        0,
        COALESCE(i."SalesPrice", 0),
        0
    FROM _detalles_compra_anul d
    INNER JOIN master."Product" i ON i."ProductCode" = d."CODIGO"
    WHERE d."CODIGO" IS NOT NULL AND d."CANTIDAD" > 0;

    -- Restar del inventario en master.Product.StockQty (revertir el ingreso)
    WITH "Totales" AS (
        SELECT "CODIGO", SUM("CANTIDAD") AS "TOTAL"
        FROM _detalles_compra_anul
        WHERE "CODIGO" IS NOT NULL
        GROUP BY "CODIGO"
    )
    UPDATE master."Product" i
    SET "StockQty" = COALESCE(i."StockQty", 0) - t."TOTAL"
    FROM "Totales" t
    WHERE t."CODIGO" = i."ProductCode";

    -- ============================================
    -- 5. Anular CxP (marcar como anulada en P_Pagar)
    -- TODO: tabla P_Pagar es legacy
    -- ============================================
    UPDATE "P_Pagar"
    SET "PAID" = 1,
        "PEND" = 0,
        "SALDO" = 0
    WHERE "DOCUMENTO" = p_num_fact
      AND "TIPO" = 'FACT'
      AND "CODIGO" = v_cod_proveedor;

    -- ============================================
    -- 6. Recalcular saldos del proveedor en master."Supplier"
    -- Antes actualizaba dbo.Proveedores.SALDO_TOT; ahora actualiza master.Supplier.TotalBalance
    -- ============================================
    -- TODO: tabla P_Pagar es legacy
    SELECT COALESCE(SUM(COALESCE("PEND", 0)), 0)
    INTO v_saldo_total
    FROM "P_Pagar"
    WHERE "CODIGO" = v_cod_proveedor
      AND "PAID" = 0;

    UPDATE master."Supplier"
    SET "TotalBalance" = v_saldo_total
    WHERE "SupplierCode" = v_cod_proveedor
      AND COALESCE("IsDeleted", FALSE) = FALSE;

    -- Retornar resultado
    RETURN QUERY
    SELECT
        TRUE                                AS "ok",
        p_num_fact                          AS "numFact",
        v_cod_proveedor                     AS "codProveedor",
        'Compra anulada exitosamente'::TEXT AS "mensaje";

EXCEPTION WHEN OTHERS THEN
    RAISE;
END;
$function$
;

-- sp_anular_factura_tx
DROP FUNCTION IF EXISTS public.sp_anular_factura_tx(character varying, character varying, character varying) CASCADE;
CREATE OR REPLACE FUNCTION public.sp_anular_factura_tx(p_num_fact character varying, p_cod_usuario character varying DEFAULT 'API'::character varying, p_motivo character varying DEFAULT ''::character varying)
 RETURNS TABLE(ok boolean, "numFact" character varying, "codCliente" character varying, mensaje character varying)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_fecha_anulacion    TIMESTAMP := NOW() AT TIME ZONE 'UTC';
    v_cod_cliente        VARCHAR(60);
    v_customer_id        BIGINT;
    v_ya_anulada         BOOLEAN;
    v_default_company_id INT := 1;
    v_default_branch_id  INT := 1;
BEGIN
    SELECT "CompanyId" INTO v_default_company_id
    FROM cfg."Company" WHERE "CompanyCode" = 'DEFAULT' LIMIT 1;

    SELECT "BranchId" INTO v_default_branch_id
    FROM cfg."Branch" WHERE "CompanyId" = v_default_company_id AND "BranchCode" = 'MAIN' LIMIT 1;

    -- 1. Validar factura en ar.SalesDocument
    SELECT
        "CustomerCode",
        CASE WHEN "IsVoided" = TRUE THEN TRUE ELSE FALSE END
    INTO v_cod_cliente, v_ya_anulada
    FROM ar."SalesDocument"
    WHERE "DocumentNumber" = p_num_fact AND "OperationType" = 'FACT' AND "IsDeleted" = FALSE;

    IF v_cod_cliente IS NULL THEN
        RAISE EXCEPTION 'factura_not_found';
    END IF;

    IF v_ya_anulada = TRUE THEN
        RAISE EXCEPTION 'factura_already_anulled';
    END IF;

    -- Resolver CustomerId
    SELECT "CustomerId" INTO v_customer_id
    FROM master."Customer"
    WHERE "CustomerCode" = v_cod_cliente AND COALESCE("IsDeleted", FALSE) = FALSE
    LIMIT 1;

    -- 2. Marcar anulada -> ar.SalesDocument
    UPDATE ar."SalesDocument"
    SET "IsVoided" = TRUE,
        "Notes" = COALESCE("Notes", '') || ' [ANULADA: ' || TO_CHAR(v_fecha_anulacion, 'YYYY-MM-DD HH24:MI:SS') || ']',
        "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
    WHERE "DocumentNumber" = p_num_fact AND "OperationType" = 'FACT';

    -- 3. Anular detalle -> ar.SalesDocumentLine
    UPDATE ar."SalesDocumentLine"
    SET "IsVoided" = TRUE, "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
    WHERE "DocumentNumber" = p_num_fact AND "OperationType" = 'FACT';

    -- 4. Revertir inventario
    CREATE TEMP TABLE IF NOT EXISTS _detalles_factura (
        "COD_SERV"     VARCHAR(60),
        "CANTIDAD"     NUMERIC(18,4),
        "RELACIONADA"  INT,
        "COD_ALTERNO"  VARCHAR(60)
    ) ON COMMIT DROP;

    DELETE FROM _detalles_factura;

    INSERT INTO _detalles_factura ("COD_SERV", "CANTIDAD", "RELACIONADA", "COD_ALTERNO")
    SELECT "ProductCode", COALESCE("Quantity", 0),
        CASE WHEN "RelatedRef" = '1' THEN 1 ELSE 0 END, "AlternateCode"
    FROM ar."SalesDocumentLine"
    WHERE "DocumentNumber" = p_num_fact AND "OperationType" = 'FACT' AND COALESCE("IsVoided", FALSE) = FALSE;

    -- Movimiento de anulacion -> master.InventoryMovement
    INSERT INTO master."InventoryMovement" ("CompanyId", "ProductCode", "DocumentRef", "MovementType", "MovementDate", "Quantity", "UnitCost", "TotalCost", "Notes")
    SELECT v_default_company_id, d."COD_SERV", p_num_fact || '_ANUL', 'ENTRADA',
        v_fecha_anulacion::DATE, d."CANTIDAD",
        COALESCE(i."COSTO_REFERENCIA", 0), d."CANTIDAD" * COALESCE(i."COSTO_REFERENCIA", 0),
        'Anulacion Factura:' || p_num_fact || ' - ' || p_motivo
    FROM _detalles_factura d
    INNER JOIN master."Product" i ON i."ProductCode" = d."COD_SERV"
    WHERE d."COD_SERV" IS NOT NULL AND d."CANTIDAD" > 0;

    -- Sumar de vuelta stock -> master.Product
    WITH "Totales" AS (
        SELECT "COD_SERV", SUM("CANTIDAD") AS "TOTAL"
        FROM _detalles_factura WHERE "COD_SERV" IS NOT NULL GROUP BY "COD_SERV"
    )
    UPDATE master."Product" i
    SET "StockQty" = COALESCE(i."StockQty", 0) + t."TOTAL"
    FROM "Totales" t WHERE t."COD_SERV" = i."ProductCode";

    -- Sumar de vuelta stock auxiliar -> master.AlternateStock
    WITH "AuxTotales" AS (
        SELECT "COD_ALTERNO", SUM("CANTIDAD") AS "TOTAL"
        FROM _detalles_factura WHERE "RELACIONADA" = 1 AND "COD_ALTERNO" IS NOT NULL GROUP BY "COD_ALTERNO"
    )
    UPDATE master."AlternateStock" a
    SET "StockQty" = COALESCE(a."StockQty", 0) + at2."TOTAL"
    FROM "AuxTotales" at2 WHERE at2."COD_ALTERNO" = a."ProductCode";

    -- 5. Anular CxC -> ar.ReceivableDocument
    UPDATE ar."ReceivableDocument"
    SET "PaidFlag" = TRUE, "PendingAmount" = 0, "Status" = 'VOIDED', "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
    WHERE "DocumentNumber" = p_num_fact AND "DocumentType" = 'FACT'
      AND "CompanyId" = v_default_company_id AND "BranchId" = v_default_branch_id;

    -- 6. Recalcular saldos -> master.Customer.TotalBalance
    IF v_customer_id IS NOT NULL THEN
        UPDATE master."Customer"
        SET "TotalBalance" = COALESCE((
            SELECT SUM("PendingAmount")
            FROM ar."ReceivableDocument"
            WHERE "CustomerId" = v_customer_id AND "Status" <> 'VOIDED' AND "PaidFlag" = FALSE
        ), 0)
        WHERE "CustomerId" = v_customer_id AND COALESCE("IsDeleted", FALSE) = FALSE;
    END IF;

    RETURN QUERY
    SELECT TRUE, p_num_fact, v_cod_cliente, 'Factura anulada exitosamente'::VARCHAR;

EXCEPTION WHEN OTHERS THEN
    RAISE EXCEPTION '%', SQLERRM;
END;
$function$
;

-- sp_anular_pedido_tx
DROP FUNCTION IF EXISTS public.sp_anular_pedido_tx(character varying, character varying, character varying) CASCADE;
CREATE OR REPLACE FUNCTION public.sp_anular_pedido_tx(p_num_pedido character varying, p_cod_usuario character varying DEFAULT 'API'::character varying, p_motivo character varying DEFAULT ''::character varying)
 RETURNS TABLE(ok boolean, "numPedido" character varying, mensaje character varying)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_fecha_anulacion TIMESTAMP := NOW() AT TIME ZONE 'UTC';
    v_ya_anulado      BOOLEAN;
BEGIN
    SELECT CASE WHEN "ANULADA"::TEXT IN ('1', 'true') THEN TRUE ELSE FALSE END
    INTO v_ya_anulado
    FROM "Pedidos" WHERE "NUM_FACT" = p_num_pedido;

    IF v_ya_anulado IS NULL THEN
        RAISE EXCEPTION 'pedido_not_found';
    END IF;

    IF v_ya_anulado = TRUE THEN
        RAISE EXCEPTION 'pedido_already_anulled';
    END IF;

    UPDATE "Pedidos" SET
        "ANULADA" = TRUE,
        "OBSERV" = COALESCE("OBSERV", '') || ' [ANULADO: ' || TO_CHAR(v_fecha_anulacion, 'YYYY-MM-DD HH24:MI:SS') || ']'
    WHERE "NUM_FACT" = p_num_pedido;

    UPDATE "Detalle_Pedidos" SET "ANULADA" = TRUE WHERE "NUM_FACT" = p_num_pedido;

    -- Reversar inventario
    CREATE TEMP TABLE IF NOT EXISTS _detalles_pedido (
        "COD_SERV" VARCHAR(60),
        "CANTIDAD" DOUBLE PRECISION
    ) ON COMMIT DROP;

    DELETE FROM _detalles_pedido;

    INSERT INTO _detalles_pedido
    SELECT "COD_SERV", COALESCE("CANTIDAD", 0)
    FROM "Detalle_Pedidos"
    WHERE "NUM_FACT" = p_num_pedido AND COALESCE("ANULADA"::INT, 0) = 0;

    INSERT INTO "MovInvent" ("DOCUMENTO", "CODIGO", "PRODUCT", "FECHA", "MOTIVO", "TIPO",
        "CANTIDAD_ACTUAL", "CANTIDAD", "CANTIDAD_NUEVA", "CO_USUARIO")
    SELECT p_num_pedido || '_ANUL', d."COD_SERV", d."COD_SERV", v_fecha_anulacion,
        'Anulacion Pedido:' || p_num_pedido, 'Anulacion Pedido',
        COALESCE(i."EXISTENCIA", 0), d."CANTIDAD", COALESCE(i."EXISTENCIA", 0) + d."CANTIDAD", p_cod_usuario
    FROM _detalles_pedido d
    INNER JOIN "Inventario" i ON i."CODIGO" = d."COD_SERV"
    WHERE d."COD_SERV" IS NOT NULL AND d."CANTIDAD" > 0;

    WITH "Totales" AS (
        SELECT "COD_SERV", SUM("CANTIDAD") AS "TOTAL"
        FROM _detalles_pedido WHERE "COD_SERV" IS NOT NULL GROUP BY "COD_SERV"
    )
    UPDATE "Inventario" i
    SET "EXISTENCIA" = COALESCE(i."EXISTENCIA", 0) + t."TOTAL"
    FROM "Totales" t WHERE t."COD_SERV" = i."CODIGO";

    RETURN QUERY
    SELECT TRUE, p_num_pedido, 'Pedido anulado'::VARCHAR;

EXCEPTION WHEN OTHERS THEN
    RAISE EXCEPTION '%', SQLERRM;
END;
$function$
;

-- sp_anular_presupuesto_tx
DROP FUNCTION IF EXISTS public.sp_anular_presupuesto_tx(character varying, character varying, character varying) CASCADE;
CREATE OR REPLACE FUNCTION public.sp_anular_presupuesto_tx(p_num_fact character varying, p_cod_usuario character varying DEFAULT 'API'::character varying, p_motivo character varying DEFAULT ''::character varying)
 RETURNS TABLE(ok boolean, "numFact" character varying, "codCliente" character varying, mensaje character varying)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_fecha_anulacion TIMESTAMP := NOW() AT TIME ZONE 'UTC';
    v_cod_cliente     VARCHAR(60);
    v_ya_anulada      BOOLEAN;
    v_saldo_total     DOUBLE PRECISION;
    v_rows_affected   INT;
BEGIN
    -- TODO: tabla Presupuestos es legacy
    SELECT "CODIGO", CASE WHEN "ANULADA"::TEXT = '1' THEN TRUE ELSE FALSE END
    INTO v_cod_cliente, v_ya_anulada
    FROM "Presupuestos" WHERE "NUM_FACT" = p_num_fact;

    IF v_cod_cliente IS NULL THEN
        RAISE EXCEPTION 'presupuesto_not_found';
    END IF;

    IF v_ya_anulada = TRUE THEN
        RAISE EXCEPTION 'presupuesto_already_anulled';
    END IF;

    -- 1. Marcar presupuesto como anulado
    UPDATE "Presupuestos"
    SET "ANULADA" = TRUE,
        "OBSERV" = COALESCE("OBSERV", '') || ' [ANULADA: ' || TO_CHAR(v_fecha_anulacion, 'YYYY-MM-DD HH24:MI:SS') || ']'
    WHERE "NUM_FACT" = p_num_fact;

    -- 2. Anular detalle
    UPDATE "Detalle_Presupuestos" SET "ANULADA" = TRUE WHERE "NUM_FACT" = p_num_fact;

    -- 3. Revertir master.Product
    CREATE TEMP TABLE IF NOT EXISTS _detalles_presup (
        "COD_SERV"     VARCHAR(60),
        "CANTIDAD"     DOUBLE PRECISION,
        "RELACIONADA"  INT,
        "COD_ALTERNO"  VARCHAR(60)
    ) ON COMMIT DROP;

    DELETE FROM _detalles_presup;

    INSERT INTO _detalles_presup ("COD_SERV", "CANTIDAD", "RELACIONADA", "COD_ALTERNO")
    SELECT "COD_SERV", COALESCE("CANTIDAD", 0),
        CASE WHEN "Relacionada"::TEXT = '1' THEN 1 ELSE 0 END, "Cod_Alterno"
    FROM "Detalle_Presupuestos" WHERE "NUM_FACT" = p_num_fact AND COALESCE("ANULADA"::INT, 0) = 0;

    -- Insertar movimiento de anulacion
    INSERT INTO "MovInvent" (
        "DOCUMENTO", "CODIGO", "PRODUCT", "FECHA", "MOTIVO", "TIPO",
        "CANTIDAD_ACTUAL", "CANTIDAD", "CANTIDAD_NUEVA", "CO_USUARIO",
        "PRECIO_COMPRA", "ALICUOTA", "PRECIO_VENTA", "ANULADA"
    )
    SELECT
        p_num_fact || '_ANUL',
        d."COD_SERV",
        d."COD_SERV",
        v_fecha_anulacion,
        'Anulacion Presupuesto:' || p_num_fact || ' - ' || p_motivo,
        'Anulacion Egreso',
        COALESCE(i."StockQty", 0),
        d."CANTIDAD",
        COALESCE(i."StockQty", 0) + d."CANTIDAD",
        p_cod_usuario,
        COALESCE(i."COSTO_REFERENCIA", 0),
        0,
        COALESCE(i."SalesPrice", 0),
        FALSE
    FROM _detalles_presup d
    INNER JOIN master."Product" i ON i."ProductCode" = d."COD_SERV"
    WHERE d."COD_SERV" IS NOT NULL AND d."CANTIDAD" > 0;

    -- Sumar de vuelta al inventario
    WITH "Totales" AS (
        SELECT "COD_SERV", SUM("CANTIDAD") AS "TOTAL"
        FROM _detalles_presup WHERE "COD_SERV" IS NOT NULL GROUP BY "COD_SERV"
    )
    UPDATE master."Product" i
    SET "StockQty" = COALESCE(i."StockQty", 0) + t."TOTAL"
    FROM "Totales" t WHERE t."COD_SERV" = i."ProductCode";

    -- Sumar de vuelta a Inventario_Aux si es relacionada
    WITH "AuxTotales" AS (
        SELECT "COD_ALTERNO", SUM("CANTIDAD") AS "TOTAL"
        FROM _detalles_presup WHERE "RELACIONADA" = 1 AND "COD_ALTERNO" IS NOT NULL GROUP BY "COD_ALTERNO"
    )
    UPDATE "Inventario_Aux" ia
    SET "CANTIDAD" = COALESCE(ia."CANTIDAD", 0) + a."TOTAL"
    FROM "AuxTotales" a WHERE a."COD_ALTERNO" = ia."CODIGO";

    -- 4. Anular CxC (P_Cobrar / P_CobrarC)
    UPDATE "P_Cobrar" SET "PAID" = TRUE, "PEND" = 0, "SALDO" = 0
    WHERE "DOCUMENTO" = p_num_fact AND "TIPO" = 'PRESUP' AND "CODIGO" = v_cod_cliente;

    GET DIAGNOSTICS v_rows_affected = ROW_COUNT;

    IF v_rows_affected = 0 THEN
        UPDATE "P_CobrarC" SET "PAID" = TRUE, "PEND" = 0, "SALDO" = 0
        WHERE "DOCUMENTO" = p_num_fact AND "TIPO" = 'PRESUP' AND "CODIGO" = v_cod_cliente;
    END IF;

    -- 5. Recalcular saldos del cliente en master.Customer
    SELECT COALESCE(SUM(COALESCE("PEND", 0)), 0)
    INTO v_saldo_total
    FROM "P_Cobrar" WHERE "CODIGO" = v_cod_cliente AND "PAID" = FALSE;

    IF v_saldo_total IS NULL OR v_saldo_total = 0 THEN
        SELECT COALESCE(SUM(COALESCE("PEND", 0)), 0)
        INTO v_saldo_total
        FROM "P_CobrarC" WHERE "CODIGO" = v_cod_cliente AND "PAID" = FALSE;
    END IF;

    UPDATE master."Customer"
    SET "TotalBalance" = COALESCE(v_saldo_total, 0)
    WHERE "CustomerCode" = v_cod_cliente
      AND COALESCE("IsDeleted", FALSE) = FALSE;

    RETURN QUERY
    SELECT TRUE, p_num_fact, v_cod_cliente, 'Presupuesto anulada'::VARCHAR;

EXCEPTION WHEN OTHERS THEN
    RAISE EXCEPTION '%', SQLERRM;
END;
$function$
;

-- sp_cerrar_conciliacion
DROP FUNCTION IF EXISTS public.sp_cerrar_conciliacion(integer, numeric, character varying, character varying) CASCADE;
CREATE OR REPLACE FUNCTION public.sp_cerrar_conciliacion(p_conciliacion_id integer, p_saldo_final_banco numeric, p_observaciones character varying DEFAULT NULL::character varying, p_co_usuario character varying DEFAULT 'API'::character varying)
 RETURNS TABLE(ok boolean, diferencia numeric, estado character varying)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_saldo_final_sistema NUMERIC(18,2);
    v_diferencia          NUMERIC(18,2);
    v_estado              VARCHAR(20);
BEGIN
    SELECT "Saldo_Final_Sistema" INTO v_saldo_final_sistema
    FROM "ConciliacionBancaria"
    WHERE "ID" = p_conciliacion_id;

    v_diferencia := v_saldo_final_sistema - p_saldo_final_banco;
    v_estado := CASE WHEN ABS(v_diferencia) < 0.01 THEN 'CONCILIADO' ELSE 'DIFERENCIA' END;

    UPDATE "ConciliacionBancaria" SET
        "Saldo_Final_Banco" = p_saldo_final_banco,
        "Diferencia" = v_diferencia,
        "Observaciones" = p_observaciones,
        "Estado" = v_estado,
        "Fecha_Cierre" = NOW() AT TIME ZONE 'UTC',
        "Co_Usuario" = p_co_usuario
    WHERE "ID" = p_conciliacion_id;

    RETURN QUERY SELECT TRUE, v_diferencia, v_estado;
END;
$function$
;

-- sp_cerrarmesinventario
DROP FUNCTION IF EXISTS public.sp_cerrarmesinventario(character varying) CASCADE;
CREATE OR REPLACE FUNCTION public.sp_cerrarmesinventario(p_periodo character varying)
 RETURNS TABLE("ProductosCerrados" integer, "Periodo" character varying, "FechaCierre" date)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_mes        INT;
    v_anio       INT;
    v_fin        DATE;
    v_fin_dt     TIMESTAMP;
    v_filas      INT;
BEGIN
    v_mes  := CAST(LEFT(p_periodo, 2) AS INT);
    v_anio := CAST(RIGHT(p_periodo, 4) AS INT);
    v_fin  := (make_date(v_anio, v_mes, 1) + INTERVAL '1 month - 1 day')::DATE;
    v_fin_dt := (v_fin + INTERVAL '1 day')::TIMESTAMP;

    -- Verificar que exista la tabla CierreMensualInventario
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = 'public' AND table_name = 'cierremensualinventario'
    ) THEN
        RAISE EXCEPTION 'Crear antes la tabla CierreMensualInventario (create_cierre_mensual_inventario.sql).';
    END IF;

    -- Eliminar datos previos del periodo
    DELETE FROM public."CierreMensualInventario" WHERE "Periodo" = p_periodo;

    -- Ultimo movimiento por producto hasta v_fin
    WITH "UltimoMov" AS (
        SELECT
            COALESCE(m."Codigo", m."Product") AS "Codigo",
            m."cantidad_nueva"                AS "CantidadFinal",
            COALESCE(m."Precio_Compra", 0)    AS "CostoUnitario",
            ROW_NUMBER() OVER (
                PARTITION BY COALESCE(m."Codigo", m."Product")
                ORDER BY m."Fecha" DESC, m."id" DESC
            ) AS rn
        FROM public."MovInvent" m
        WHERE m."Fecha" < v_fin_dt
          AND COALESCE(m."Anulada", 0) = 0
          AND (
              (m."Codigo" IS NOT NULL AND TRIM(m."Codigo") <> '')
              OR (m."Product" IS NOT NULL AND TRIM(m."Product") <> '')
          )
    )
    INSERT INTO public."CierreMensualInventario"
        ("Periodo", "Codigo", "Descripcion", "CantidadFinal", "MontoFinal", "CostoUnitario", "FechaCierre")
    SELECT
        p_periodo,
        u."Codigo",
        i."DESCRIPCION",
        u."CantidadFinal",
        u."CantidadFinal" * u."CostoUnitario",
        u."CostoUnitario",
        NOW() AT TIME ZONE 'UTC'
    FROM "UltimoMov" u
    LEFT JOIN public."Inventario" i ON i."CODIGO" = u."Codigo"
    WHERE u.rn = 1 AND u."CantidadFinal" <> 0;

    -- Productos con existencia en Inventario sin movimiento hasta v_fin
    INSERT INTO public."CierreMensualInventario"
        ("Periodo", "Codigo", "Descripcion", "CantidadFinal", "MontoFinal", "CostoUnitario", "FechaCierre")
    SELECT
        p_periodo,
        i."CODIGO",
        i."DESCRIPCION",
        COALESCE(i."EXISTENCIA", 0),
        COALESCE(i."EXISTENCIA", 0) * COALESCE(i."COSTO_REFERENCIA", i."COSTO_PROMEDIO"),
        COALESCE(i."COSTO_REFERENCIA", i."COSTO_PROMEDIO"),
        NOW() AT TIME ZONE 'UTC'
    FROM public."Inventario" i
    WHERE COALESCE(i."EXISTENCIA", 0) > 0
      AND i."CODIGO" IS NOT NULL AND TRIM(i."CODIGO") <> ''
      AND NOT EXISTS (
          SELECT 1 FROM public."CierreMensualInventario" c
          WHERE c."Periodo" = p_periodo AND c."Codigo" = i."CODIGO"
      );

    GET DIAGNOSTICS v_filas = ROW_COUNT;

    RETURN QUERY SELECT v_filas, p_periodo, v_fin;
END;
$function$
;

-- sp_conciliar_movimientos
DROP FUNCTION IF EXISTS public.sp_conciliar_movimientos(integer, integer, integer, character varying) CASCADE;
CREATE OR REPLACE FUNCTION public.sp_conciliar_movimientos(p_conciliacion_id integer, p_movimiento_sistema_id integer, p_extracto_id integer DEFAULT NULL::integer, p_co_usuario character varying DEFAULT 'API'::character varying)
 RETURNS TABLE(ok boolean, mensaje character varying)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_mov_cuentas_id   INT;
    v_sistema_debito   NUMERIC(18,2);
    v_sistema_credito  NUMERIC(18,2);
    v_banco_debito     NUMERIC(18,2);
    v_banco_credito    NUMERIC(18,2);
BEGIN
    -- Marcar como conciliado en detalle
    UPDATE "ConciliacionDetalle" SET
        "Conciliado" = TRUE,
        "Extracto_ID" = p_extracto_id
    WHERE "ID" = p_movimiento_sistema_id AND "Conciliacion_ID" = p_conciliacion_id;

    -- Obtener MovCuentas_ID
    SELECT "MovCuentas_ID" INTO v_mov_cuentas_id
    FROM "ConciliacionDetalle"
    WHERE "ID" = p_movimiento_sistema_id;

    -- Marcar MovCuentas como confirmado
    UPDATE "MovCuentas" SET "Confirmada" = TRUE
    WHERE "id" = v_mov_cuentas_id;

    -- Si hay extracto, marcarlo como conciliado
    IF p_extracto_id IS NOT NULL THEN
        UPDATE "ExtractoBancario" SET
            "Conciliado" = TRUE,
            "Fecha_Conciliacion" = NOW() AT TIME ZONE 'UTC',
            "MovCuentas_ID" = v_mov_cuentas_id
        WHERE "ID" = p_extracto_id;
    END IF;

    -- Recalcular diferencia
    SELECT SUM("Debito"), SUM("Credito")
    INTO v_sistema_debito, v_sistema_credito
    FROM "ConciliacionDetalle"
    WHERE "Conciliacion_ID" = p_conciliacion_id
      AND "Tipo_Origen" = 'SISTEMA'
      AND "Conciliado" = TRUE;

    SELECT
        SUM(CASE WHEN e."Tipo" = 'DEBITO' THEN e."Monto" ELSE 0 END),
        SUM(CASE WHEN e."Tipo" = 'CREDITO' THEN e."Monto" ELSE 0 END)
    INTO v_banco_debito, v_banco_credito
    FROM "ExtractoBancario" e
    INNER JOIN "ConciliacionDetalle" d ON e."ID" = d."Extracto_ID"
    WHERE d."Conciliacion_ID" = p_conciliacion_id AND d."Conciliado" = TRUE;

    -- Actualizar conciliacion
    UPDATE "ConciliacionBancaria" SET
        "Diferencia" = (COALESCE(v_sistema_credito, 0) - COALESCE(v_sistema_debito, 0)) -
                       (COALESCE(v_banco_credito, 0) - COALESCE(v_banco_debito, 0))
    WHERE "ID" = p_conciliacion_id;

    RETURN QUERY SELECT TRUE, 'Movimiento conciliado'::VARCHAR;
END;
$function$
;

-- sp_crear_conciliacion
DROP FUNCTION IF EXISTS public.sp_crear_conciliacion(character varying, timestamp without time zone, timestamp without time zone, character varying) CASCADE;
CREATE OR REPLACE FUNCTION public.sp_crear_conciliacion(p_nro_cta character varying, p_fecha_desde timestamp without time zone, p_fecha_hasta timestamp without time zone, p_co_usuario character varying DEFAULT 'API'::character varying)
 RETURNS TABLE("conciliacionId" integer, "saldoInicial" numeric, "saldoFinal" numeric)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_saldo_inicial   NUMERIC(18,2) := 0;
    v_saldo_final     NUMERIC(18,2) := 0;
    v_conciliacion_id INT;
BEGIN
    -- Obtener saldo inicial (al inicio del periodo)
    SELECT COALESCE("Saldo", 0) INTO v_saldo_inicial
    FROM "MovCuentas"
    WHERE "Nro_Cta" = p_nro_cta AND "Fecha" < p_fecha_desde
    ORDER BY "Fecha" DESC, "id" DESC
    LIMIT 1;

    -- Si no hay movimientos previos, tomar saldo apertura de CuentasBank
    IF v_saldo_inicial IS NULL THEN
        SELECT COALESCE("Saldo_Apertura", 0) INTO v_saldo_inicial
        FROM "CuentasBank"
        WHERE "Nro_Cta" = p_nro_cta;
    END IF;

    -- Obtener saldo final (movimientos hasta fecha hasta)
    SELECT COALESCE("Saldo", 0) INTO v_saldo_final
    FROM "MovCuentas"
    WHERE "Nro_Cta" = p_nro_cta AND "Fecha" <= p_fecha_hasta
    ORDER BY "Fecha" DESC, "id" DESC
    LIMIT 1;

    IF v_saldo_final IS NULL THEN
        v_saldo_final := v_saldo_inicial;
    END IF;

    -- Crear conciliacion
    INSERT INTO "ConciliacionBancaria" (
        "Nro_Cta", "Fecha_Desde", "Fecha_Hasta",
        "Saldo_Inicial_Sistema", "Saldo_Final_Sistema",
        "Estado", "Co_Usuario", "Fecha_Creacion"
    )
    VALUES (
        p_nro_cta, p_fecha_desde, p_fecha_hasta,
        v_saldo_inicial, v_saldo_final, 'PENDIENTE', p_co_usuario, NOW() AT TIME ZONE 'UTC'
    )
    RETURNING "ID" INTO v_conciliacion_id;

    -- Insertar movimientos del sistema no conciliados
    INSERT INTO "ConciliacionDetalle" (
        "Conciliacion_ID", "Tipo_Origen", "MovCuentas_ID",
        "Fecha", "Descripcion", "Referencia", "Debito", "Credito", "Conciliado"
    )
    SELECT
        v_conciliacion_id, 'SISTEMA', "id", "Fecha", "Concepto", "Nro_Ref",
        COALESCE("Gastos", 0), COALESCE("Ingresos", 0), "Confirmada"
    FROM "MovCuentas"
    WHERE "Nro_Cta" = p_nro_cta
      AND "Fecha" BETWEEN p_fecha_desde AND p_fecha_hasta
      AND "Confirmada" = FALSE;  -- Solo no conciliados

    RETURN QUERY SELECT v_conciliacion_id, v_saldo_inicial, v_saldo_final;
END;
$function$
;

-- sp_generar_ajuste_bancario
DROP FUNCTION IF EXISTS public.sp_generar_ajuste_bancario(integer, character varying, numeric, character varying, character varying) CASCADE;
CREATE OR REPLACE FUNCTION public.sp_generar_ajuste_bancario(p_conciliacion_id integer, p_tipo_ajuste character varying, p_monto numeric, p_descripcion character varying, p_co_usuario character varying DEFAULT 'API'::character varying)
 RETURNS TABLE(ok boolean, mensaje character varying)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_nro_cta   VARCHAR(20);
    v_tipo_mov  VARCHAR(10);
    v_debito    NUMERIC(18,2) := 0;
    v_credito   NUMERIC(18,2) := 0;
BEGIN
    SELECT "Nro_Cta" INTO v_nro_cta
    FROM "ConciliacionBancaria"
    WHERE "ID" = p_conciliacion_id;

    IF v_nro_cta IS NULL THEN
        RAISE EXCEPTION 'conciliacion_no_existe';
    END IF;

    -- Determinar tipo
    IF p_tipo_ajuste = 'NOTA_CREDITO' THEN
        v_tipo_mov := 'NCR';
        v_credito  := p_monto;
    ELSIF p_tipo_ajuste = 'NOTA_DEBITO' THEN
        v_tipo_mov := 'NDB';
        v_debito   := p_monto;
    ELSE
        RAISE EXCEPTION 'tipo_ajuste_invalido';
    END IF;

    -- Generar movimiento bancario
    PERFORM sp_generar_movimiento_bancario(
        p_nro_cta               := v_nro_cta,
        p_tipo                  := v_tipo_mov,
        p_nro_ref               := 'AJUSTE-' || p_conciliacion_id::TEXT,
        p_beneficiario          := 'AJUSTE CONCILIACION',
        p_monto                 := p_monto,
        p_concepto              := p_descripcion,
        p_co_usuario            := p_co_usuario
    );

    -- Insertar en detalle de conciliacion como ajuste
    INSERT INTO "ConciliacionDetalle" (
        "Conciliacion_ID", "Tipo_Origen", "Fecha", "Descripcion",
        "Referencia", "Debito", "Credito", "Conciliado", "Tipo_Ajuste", "Co_Usuario"
    )
    VALUES (
        p_conciliacion_id, 'AJUSTE', NOW() AT TIME ZONE 'UTC', p_descripcion,
        'AJUSTE-' || p_conciliacion_id::TEXT, v_debito, v_credito, TRUE, p_tipo_ajuste, p_co_usuario
    );

    RETURN QUERY SELECT TRUE, 'Ajuste generado'::VARCHAR;
END;
$function$
;

-- sp_generar_movimiento_bancario
DROP FUNCTION IF EXISTS public.sp_generar_movimiento_bancario(character varying, character varying, character varying, character varying, numeric, character varying, character varying, character varying, character varying, character varying) CASCADE;
CREATE OR REPLACE FUNCTION public.sp_generar_movimiento_bancario(p_nro_cta character varying, p_tipo character varying, p_nro_ref character varying, p_beneficiario character varying, p_monto numeric, p_concepto character varying, p_categoria character varying DEFAULT NULL::character varying, p_co_usuario character varying DEFAULT 'API'::character varying, p_documento_relacionado character varying DEFAULT NULL::character varying, p_tipo_doc_rel character varying DEFAULT NULL::character varying)
 RETURNS TABLE(ok boolean, "movimientoId" integer, "saldoNuevo" numeric)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_gastos       NUMERIC(18,2) := 0;
    v_ingresos     NUMERIC(18,2) := 0;
    v_saldo_actual NUMERIC(18,2);
    v_mov_id       INT;
    v_debe         NUMERIC(18,2);
    v_haber        NUMERIC(18,2);
    v_banco        VARCHAR(100);
BEGIN
    -- Validar cuenta existe
    IF NOT EXISTS (SELECT 1 FROM "CuentasBank" WHERE "Nro_Cta" = p_nro_cta) THEN
        RAISE EXCEPTION 'cuenta_bancaria_no_existe';
    END IF;

    -- Determinar si es gasto o ingreso segun tipo
    -- PCH (cheque), NDB (nota debito) = Gasto
    -- DEP (deposito), NCR (nota credito) = Ingreso
    IF p_tipo IN ('PCH', 'NDB', 'IDB') THEN
        v_gastos := p_monto;
    ELSIF p_tipo IN ('DEP', 'NCR') THEN
        v_ingresos := p_monto;
    END IF;

    -- Obtener saldo actual
    SELECT COALESCE("Saldo", 0) INTO v_saldo_actual
    FROM "CuentasBank"
    WHERE "Nro_Cta" = p_nro_cta;

    -- Calcular nuevo saldo
    v_saldo_actual := v_saldo_actual + v_ingresos - v_gastos;

    -- Insertar en MovCuentas
    INSERT INTO "MovCuentas" (
        "Nro_Cta", "Fecha", "Tipo", "Nro_Ref", "Beneficiario", "Categoria",
        "Gastos", "Ingresos", "Saldo_Dia", "Saldo", "Confirmada",
        "Co_Usuario", "Concepto", "Fecha_Banco"
    )
    VALUES (
        p_nro_cta, NOW() AT TIME ZONE 'UTC', p_tipo, p_nro_ref, p_beneficiario, p_categoria,
        v_gastos, v_ingresos, v_saldo_actual, v_saldo_actual, FALSE,
        p_co_usuario, p_concepto, NULL
    )
    RETURNING "id" INTO v_mov_id;

    -- Actualizar saldo en CuentasBank
    UPDATE "CuentasBank" SET
        "Saldo" = v_saldo_actual,
        "Saldo_Disponible" = v_saldo_actual
    WHERE "Nro_Cta" = p_nro_cta;

    -- Si hay documento relacionado, insertar en Movimiento_Cuenta para control contable
    IF p_documento_relacionado IS NOT NULL THEN
        v_debe  := CASE WHEN v_gastos > 0 THEN v_gastos ELSE 0 END;
        v_haber := CASE WHEN v_ingresos > 0 THEN v_ingresos ELSE 0 END;

        SELECT "Banco" INTO v_banco FROM "CuentasBank" WHERE "Nro_Cta" = p_nro_cta;

        INSERT INTO "Movimiento_Cuenta" (
            "COD_CUENTA", "COD_OPER", "FECHA", "DEBE", "HABER",
            "COD_USUARIO", "DESCRIPCION", "CONCEPTO", "Banco", "Cheque"
        )
        VALUES (
            p_nro_cta, p_tipo_doc_rel, NOW() AT TIME ZONE 'UTC', v_debe, v_haber,
            p_co_usuario, p_concepto, p_documento_relacionado, v_banco, p_nro_ref
        );
    END IF;

    RETURN QUERY SELECT TRUE, v_mov_id, v_saldo_actual;
END;
$function$
;

-- sp_get_movimiento_bancario_by_id
DROP FUNCTION IF EXISTS public.sp_get_movimiento_bancario_by_id(integer) CASCADE;
CREATE OR REPLACE FUNCTION public.sp_get_movimiento_bancario_by_id(p_movimiento_id integer)
 RETURNS TABLE(id integer, "BankAccountId" integer, "Fecha" timestamp without time zone, "Tipo" character varying, "MovementSign" character varying, "Monto" numeric, "NetAmount" numeric, "Nro_Ref" character varying, "Beneficiario" character varying, "Concepto" character varying, "Categoria" character varying, "Documento_Relacionado" character varying, "Tipo_Doc_Rel" character varying, "Saldo" numeric, "IsReconciled" boolean, "CreatedAt" timestamp without time zone, "Nro_Cta" character varying, "CuentaDescripcion" character varying, "SaldoActual" numeric, "BancoNombre" character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        m."BankMovementId",
        m."BankAccountId",
        m."MovementDate",
        m."MovementType",
        m."MovementSign",
        m."Amount",
        m."NetAmount",
        m."ReferenceNo",
        m."Beneficiary",
        m."Concept",
        m."CategoryCode",
        m."RelatedDocumentNo",
        m."RelatedDocumentType",
        m."BalanceAfter",
        m."IsReconciled",
        m."CreatedAt",
        a."AccountNumber",
        a."AccountName",
        a."Balance",
        b."BankName"
    FROM fin."BankMovement" m
    INNER JOIN fin."BankAccount" a ON a."BankAccountId" = m."BankAccountId"
    LEFT JOIN fin."Bank" b ON b."BankId" = a."BankId"
    WHERE m."BankMovementId" = p_movimiento_id;
END;
$function$
;

-- sp_importar_extracto
DROP FUNCTION IF EXISTS public.sp_importar_extracto(jsonb, character varying, character varying) CASCADE;
CREATE OR REPLACE FUNCTION public.sp_importar_extracto(p_extracto_json jsonb, p_nro_cta character varying, p_co_usuario character varying DEFAULT 'API'::character varying)
 RETURNS TABLE(ok boolean, "registrosImportados" integer)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_count INT := 0;
BEGIN
    INSERT INTO "ExtractoBancario" (
        "Nro_Cta", "Fecha", "Descripcion", "Referencia", "Tipo", "Monto", "Saldo", "Conciliado", "Co_Usuario"
    )
    SELECT
        p_nro_cta,
        CASE WHEN (elem->>'Fecha') IS NOT NULL
             THEN (elem->>'Fecha')::TIMESTAMP
             ELSE NOW() AT TIME ZONE 'UTC' END,
        NULLIF(elem->>'Descripcion', ''::character varying),
        NULLIF(elem->>'Referencia', ''::character varying),
        NULLIF(elem->>'Tipo', ''::character varying),                -- DEBITO/CREDITO
        CASE WHEN (elem->>'Monto') IS NOT NULL
             THEN (elem->>'Monto')::NUMERIC(18,2)
             ELSE 0 END,
        CASE WHEN (elem->>'Saldo') IS NOT NULL
             THEN (elem->>'Saldo')::NUMERIC(18,2)
             ELSE NULL END,
        FALSE,  -- No conciliado
        p_co_usuario
    FROM jsonb_array_elements(p_extracto_json) AS elem;

    GET DIAGNOSTICS v_count = ROW_COUNT;

    RETURN QUERY SELECT TRUE, v_count;
END;
$function$
;

-- sp_movunidades
DROP FUNCTION IF EXISTS public.sp_movunidades(character varying, date, date, boolean) CASCADE;
CREATE OR REPLACE FUNCTION public.sp_movunidades(p_periodo character varying DEFAULT NULL::character varying, p_fecha_desde date DEFAULT NULL::date, p_fecha_hasta date DEFAULT NULL::date, p_solo_estructura boolean DEFAULT false)
 RETURNS TABLE("FilasInsertadas" integer, "Periodo" character varying)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_ini            DATE;
    v_fin            DATE;
    v_ini_dt         TIMESTAMP;
    v_fin_dt         TIMESTAMP;
    v_periodo        VARCHAR(10);
    v_mes            INT;
    v_anio           INT;
    v_inv_inicial    DOUBLE PRECISION;
    v_filas          INT;
BEGIN
    v_periodo := p_periodo;

    IF p_periodo IS NOT NULL THEN
        v_mes    := CAST(LEFT(p_periodo, 2) AS INT);
        v_anio   := CAST(RIGHT(p_periodo, 4) AS INT);
        v_ini    := make_date(v_anio, v_mes, 1);
        v_fin    := (v_ini + INTERVAL '1 month - 1 day')::DATE;
        v_ini_dt := v_ini::TIMESTAMP;
        v_fin_dt := (v_fin + INTERVAL '1 day')::TIMESTAMP;
    ELSIF p_fecha_desde IS NOT NULL AND p_fecha_hasta IS NOT NULL THEN
        v_ini     := p_fecha_desde;
        v_fin     := p_fecha_hasta;
        v_periodo := TO_CHAR(v_ini, 'MM/YYYY');
        v_ini_dt  := v_ini::TIMESTAMP;
        v_fin_dt  := (v_fin + INTERVAL '1 day')::TIMESTAMP;
    ELSE
        RAISE EXCEPTION 'Especificar p_periodo (MM/YYYY) o p_fecha_desde y p_fecha_hasta.';
    END IF;

    -- Eliminar datos del periodo en MovInventMes para refrescar
    DELETE FROM public."MovInventMes" WHERE "Periodo" = v_periodo;

    IF p_solo_estructura THEN
        RETURN QUERY SELECT 0, v_periodo;
        RETURN;
    END IF;

    -- Clasificacion: 1=Entradas, 2=Salidas, 3=AutoConsumo, 4=Retiros
    WITH "MovClasificado" AS (
        SELECT
            m."Fecha"::DATE                      AS "FechaDia",
            COALESCE(m."Codigo", m."Product")    AS "Codigo",
            m."Cantidad",
            COALESCE(m."Precio_Compra", 0)       AS "CostoUnit",
            m."Cantidad" * COALESCE(m."Precio_Compra", 0) AS "Monto",
            CASE
                WHEN UPPER(TRIM(COALESCE(m."Tipo", '')))::character varying = 'INGRESO' THEN 1
                WHEN UPPER(TRIM(COALESCE(m."Tipo", '')))::character varying = 'EGRESO' THEN
                    CASE
                        WHEN m."Motivo" ILIKE '%Autoconsumo%' THEN 3
                        WHEN m."Motivo" ILIKE '%FACT%'
                             OR m."Motivo" ILIKE '%Doc:%'
                             OR m."Motivo" ILIKE '%PEDIDO%'
                             OR m."Motivo" ILIKE '%NOTA_ENTREGA%'
                             OR m."Motivo" ILIKE '%Presup%'
                             OR m."Motivo" ILIKE '%Factura%'
                             OR m."Motivo" ILIKE '%Pedido%' THEN 2
                        ELSE 4
                    END
                WHEN UPPER(TRIM(COALESCE(m."Tipo", '')))::character varying LIKE '%ANULACION%INGRESO%' THEN 1
                WHEN UPPER(TRIM(COALESCE(m."Tipo", '')))::character varying LIKE '%ANULACION%EGRESO%' THEN 1
                ELSE 4
            END AS "Clase"
        FROM public."MovInvent" m
        WHERE m."Fecha" >= v_ini_dt AND m."Fecha" < v_fin_dt
          AND COALESCE(m."Anulada", 0) = 0
          AND (
              (m."Codigo" IS NOT NULL AND TRIM(m."Codigo") <> '')
              OR (m."Product" IS NOT NULL AND TRIM(m."Product") <> '')
          )
    ),
    "AgregadoDia" AS (
        SELECT
            "FechaDia",
            "Codigo",
            SUM(CASE WHEN "Clase" = 1 THEN "Cantidad" ELSE 0 END) AS "EntradasCant",
            SUM(CASE WHEN "Clase" = 1 THEN "Monto"    ELSE 0 END) AS "EntradasMonto",
            SUM(CASE WHEN "Clase" = 2 THEN "Cantidad" ELSE 0 END) AS "SalidasCant",
            SUM(CASE WHEN "Clase" = 2 THEN "Monto"    ELSE 0 END) AS "SalidasMonto",
            SUM(CASE WHEN "Clase" = 3 THEN "Cantidad" ELSE 0 END) AS "AutoConsumoCant",
            SUM(CASE WHEN "Clase" = 3 THEN "Monto"    ELSE 0 END) AS "AutoConsumoMonto",
            SUM(CASE WHEN "Clase" = 4 THEN "Cantidad" ELSE 0 END) AS "RetirosCant",
            SUM(CASE WHEN "Clase" = 4 THEN "Monto"    ELSE 0 END) AS "RetirosMonto"
        FROM "MovClasificado"
        GROUP BY "FechaDia", "Codigo"
    ),
    -- Inventario inicial: (1) CierreMensualInventario mes anterior (2) MovInvent ultimo antes del periodo (3) Inventario
    "PeriodoAnterior" AS (
        SELECT TO_CHAR(v_ini - INTERVAL '1 month', 'MM/YYYY') AS "Periodo"
    ),
    "InicialDesdeCierre" AS (
        SELECT c."Codigo", c."CantidadFinal" AS "InicialCant", c."CostoUnitario" AS "CostoUnit"
        FROM public."CierreMensualInventario" c
        INNER JOIN "PeriodoAnterior" p ON p."Periodo" = c."Periodo"
        WHERE c."CantidadFinal" <> 0
    ),
    "InicialMes" AS (
        SELECT
            COALESCE(m."Codigo", m."Product") AS "Codigo",
            m."cantidad_nueva"                AS "InicialCant",
            COALESCE(m."Precio_Compra", 0)    AS "CostoUnit",
            ROW_NUMBER() OVER (
                PARTITION BY COALESCE(m."Codigo", m."Product")
                ORDER BY m."Fecha" DESC, m."id" DESC
            ) AS rn
        FROM public."MovInvent" m
        WHERE m."Fecha" < v_ini_dt
          AND COALESCE(m."Anulada", 0) = 0
          AND (
              (m."Codigo" IS NOT NULL AND TRIM(m."Codigo") <> '')
              OR (m."Product" IS NOT NULL AND TRIM(m."Product") <> '')
          )
    ),
    "InicialDesdeMov" AS (
        SELECT "Codigo", "InicialCant", "CostoUnit"
        FROM "InicialMes"
        WHERE rn = 1 AND "InicialCant" <> 0
          AND NOT EXISTS (SELECT 1 FROM "InicialDesdeCierre" c WHERE c."Codigo" = "InicialMes"."Codigo")
    ),
    "InicialDesdeInventario" AS (
        SELECT
            i."ProductCode"                                       AS "Codigo",
            COALESCE(i."StockQty", 0)                             AS "InicialCant",
            COALESCE(i."COSTO_REFERENCIA", i."COSTO_PROMEDIO")    AS "CostoUnit"
        FROM master."Product" i
        WHERE COALESCE(i."IsDeleted", FALSE) = FALSE
          AND COALESCE(i."StockQty", 0) > 0
          AND i."ProductCode" IS NOT NULL AND TRIM(i."ProductCode") <> ''
          AND NOT EXISTS (SELECT 1 FROM "InicialDesdeCierre" c WHERE c."Codigo" = i."ProductCode")
          AND NOT EXISTS (SELECT 1 FROM "InicialDesdeMov" m2 WHERE m2."Codigo" = i."ProductCode")
    ),
    "InicialPorProducto" AS (
        SELECT "Codigo", "InicialCant", "CostoUnit" FROM "InicialDesdeCierre"
        UNION ALL
        SELECT "Codigo", "InicialCant", "CostoUnit" FROM "InicialDesdeMov"
        UNION ALL
        SELECT "Codigo", "InicialCant", "CostoUnit" FROM "InicialDesdeInventario"
    ),
    "DiasProducto" AS (
        SELECT "FechaDia", "Codigo" FROM "AgregadoDia"
        UNION
        SELECT v_ini, "Codigo" FROM "InicialPorProducto"
    ),
    "ConInicial" AS (
        SELECT
            d."FechaDia",
            d."Codigo",
            COALESCE(i."InicialCant", 0) AS "InicialCantMes",
            COALESCE(i."CostoUnit", 0)   AS "CostoInicial",
            a."EntradasCant", a."EntradasMonto", a."SalidasCant", a."SalidasMonto",
            a."AutoConsumoCant", a."AutoConsumoMonto", a."RetirosCant", a."RetirosMonto"
        FROM "DiasProducto" d
        LEFT JOIN "InicialPorProducto" i ON i."Codigo" = d."Codigo"
        LEFT JOIN "AgregadoDia" a ON a."FechaDia" = d."FechaDia" AND a."Codigo" = d."Codigo"
    ),
    "ConAcum" AS (
        SELECT
            "FechaDia", "Codigo", "InicialCantMes", "CostoInicial",
            "EntradasCant", "EntradasMonto", "SalidasCant", "SalidasMonto",
            "AutoConsumoCant", "AutoConsumoMonto", "RetirosCant", "RetirosMonto",
            SUM(
                COALESCE("EntradasCant", 0) - COALESCE("SalidasCant", 0)
                - COALESCE("AutoConsumoCant", 0) - COALESCE("RetirosCant", 0)
            ) OVER (PARTITION BY "Codigo" ORDER BY "FechaDia" ROWS UNBOUNDED PRECEDING) AS "Acumulado"
        FROM "ConInicial"
    ),
    "ConSaldo" AS (
        SELECT
            "FechaDia", "Codigo", "InicialCantMes", "CostoInicial",
            "EntradasCant", "EntradasMonto", "SalidasCant", "SalidasMonto",
            "AutoConsumoCant", "AutoConsumoMonto", "RetirosCant", "RetirosMonto",
            "InicialCantMes" + "Acumulado" - (
                COALESCE("EntradasCant", 0) - COALESCE("SalidasCant", 0)
                - COALESCE("AutoConsumoCant", 0) - COALESCE("RetirosCant", 0)
            ) AS "InicialDelDia",
            "InicialCantMes" + "Acumulado" AS "FinalDelDia"
        FROM "ConAcum"
    )
    INSERT INTO public."MovInventMes"
        ("Periodo", "Codigo", "Descripcion", "Costo", "Inicial", "Entradas", "Salidas",
         "AutoConsumo", "Retiros", "Inventario", "Final", "fecha")
    SELECT
        v_periodo,
        s."Codigo",
        COALESCE(inv."ProductName", s."Codigo"),
        COALESCE(s."CostoInicial", 0),
        s."InicialDelDia",
        COALESCE(s."EntradasCant", 0),
        COALESCE(s."SalidasCant", 0),
        COALESCE(s."AutoConsumoCant", 0),
        COALESCE(s."RetirosCant", 0),
        s."FinalDelDia" * COALESCE(s."CostoInicial", 0),
        s."FinalDelDia",
        s."FechaDia"
    FROM "ConSaldo" s
    LEFT JOIN master."Product" inv ON inv."ProductCode" = s."Codigo"
    WHERE COALESCE(inv."IsDeleted", FALSE) = FALSE OR inv."ProductCode" IS NULL;

    -- Fila resumen INVENTARIO INICIAL MES ANTERIOR
    SELECT SUM("Inicial" * "Costo") INTO v_inv_inicial
    FROM public."MovInventMes"
    WHERE "Periodo" = v_periodo AND "fecha" = v_ini AND "Codigo" <> '0000000001';

    INSERT INTO public."MovInventMes"
        ("Periodo", "Codigo", "Descripcion", "Costo", "Inicial", "Entradas", "Salidas",
         "AutoConsumo", "Retiros", "Inventario", "Final", "AjusteIncial", "AjusteFinal", "fecha")
    VALUES (
        v_periodo,
        '0000000001',
        'INVENTARIO INICIAL MES ANTERIOR',
        COALESCE(v_inv_inicial, 0),
        1,
        0, 0, 0, 0,
        COALESCE(v_inv_inicial, 0),
        1,
        NULL, NULL,
        v_ini
    );

    GET DIAGNOSTICS v_filas = ROW_COUNT;

    RETURN QUERY SELECT v_filas, v_periodo;
END;
$function$
;

-- sp_movunidadesmes
DROP FUNCTION IF EXISTS public.sp_movunidadesmes(character varying, boolean, boolean) CASCADE;
CREATE OR REPLACE FUNCTION public.sp_movunidadesmes(p_periodo character varying, p_cerrar_mes_anterior boolean DEFAULT true, p_refrescar_siguiente boolean DEFAULT false)
 RETURNS TABLE("FilasInsertadas" integer, "Periodo" character varying)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_mes           INT;
    v_anio          INT;
    v_prev_date     DATE;
    v_prev_periodo  VARCHAR(10);
    v_next_periodo  VARCHAR(10);
    v_result        RECORD;
BEGIN
    IF p_periodo IS NULL OR TRIM(p_periodo) = '' THEN
        RAISE EXCEPTION 'p_periodo es requerido (formato MM/YYYY).';
    END IF;

    v_mes  := CAST(LEFT(p_periodo, 2) AS INT);
    v_anio := CAST(RIGHT(p_periodo, 4) AS INT);

    -- Cerrar mes anterior si se solicita
    IF p_cerrar_mes_anterior THEN
        v_prev_date   := make_date(v_anio, v_mes, 1) - INTERVAL '1 month';
        v_prev_periodo := TO_CHAR(v_prev_date, 'MM/YYYY');

        PERFORM public.sp_CerrarMesInventario(v_prev_periodo);
    END IF;

    -- Ejecutar sp_MovUnidades para el periodo solicitado
    RETURN QUERY SELECT * FROM public.sp_MovUnidades(p_periodo);

    -- Refrescar el mes siguiente si se solicita
    IF p_refrescar_siguiente THEN
        v_next_periodo := TO_CHAR(make_date(v_anio, v_mes, 1) + INTERVAL '1 month', 'MM/YYYY');

        PERFORM public.sp_MovUnidades(v_next_periodo);
    END IF;
END;
$function$
;

-- usp_master_customer_updatebalance
DROP FUNCTION IF EXISTS public.usp_master_customer_updatebalance(bigint, integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_master_customer_updatebalance(p_customer_id bigint, p_updated_by_user_id integer DEFAULT NULL::integer)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
    IF p_customer_id IS NULL THEN
        RAISE EXCEPTION 'p_customer_id no puede ser NULL.';
    END IF;

    UPDATE master."Customer"
    SET "TotalBalance" = (
            SELECT COALESCE(SUM(rd."PendingAmount"), 0)
            FROM ar."ReceivableDocument" rd
            WHERE rd."CustomerId" = p_customer_id
              AND rd."Status" <> 'VOIDED'
        ),
        "UpdatedAt"       = NOW() AT TIME ZONE 'UTC',
        "UpdatedByUserId" = p_updated_by_user_id
    WHERE "CustomerId" = p_customer_id;
END;
$function$
;

-- usp_master_generic_list
DROP FUNCTION IF EXISTS public.usp_master_generic_list(character varying, character varying, character varying, character varying, integer, integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_master_generic_list(p_schema_name character varying, p_table_name character varying, p_search character varying DEFAULT NULL::character varying, p_sort_column character varying DEFAULT 'id'::character varying, p_offset integer DEFAULT 0, p_limit integer DEFAULT 50)
 RETURNS TABLE("TotalCount" bigint, "JsonRow" jsonb)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_full_table  TEXT := quote_ident(p_schema_name) || '.' || quote_ident(p_table_name);
    v_safe_sort   TEXT := quote_ident(p_sort_column);
    v_where       TEXT := '';
    v_search_cols TEXT := '';
    v_total       BIGINT;
    v_col         RECORD;
BEGIN
    -- Build dynamic LIKE search on string columns
    IF p_search IS NOT NULL AND LENGTH(TRIM(p_search)) > 0 THEN
        FOR v_col IN
            SELECT column_name FROM information_schema.columns
            WHERE table_schema = p_schema_name AND table_name = p_table_name
              AND data_type IN ('character varying','varchar','text','character','char')
        LOOP
            IF v_search_cols <> '' THEN v_search_cols := v_search_cols || ' OR '; END IF;
            v_search_cols := v_search_cols || quote_ident(v_col.column_name) || ' ILIKE ' || quote_literal('%' || p_search || '%');
        END LOOP;

        IF v_search_cols <> '' THEN
            v_where := ' WHERE (' || v_search_cols || ')';
        END IF;
    END IF;

    -- Count
    EXECUTE 'SELECT COUNT(1) FROM ' || v_full_table || v_where INTO v_total;

    -- Data
    RETURN QUERY EXECUTE
        'SELECT ' || v_total || '::BIGINT, to_jsonb(t.*) FROM ' || v_full_table || ' t' || v_where
        || ' ORDER BY ' || v_safe_sort || ' ASC'
        || ' LIMIT ' || p_limit || ' OFFSET ' || p_offset;
END;
$function$
;

-- usp_master_supplier_updatebalance
DROP FUNCTION IF EXISTS public.usp_master_supplier_updatebalance(bigint, integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_master_supplier_updatebalance(p_supplier_id bigint, p_updated_by_user_id integer DEFAULT NULL::integer)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
    IF p_supplier_id IS NULL THEN
        RAISE EXCEPTION 'p_supplier_id no puede ser NULL.';
    END IF;

    UPDATE master."Supplier"
    SET "TotalBalance" = (
            SELECT COALESCE(SUM(pd."PendingAmount"), 0)
            FROM ap."PayableDocument" pd
            WHERE pd."SupplierId" = p_supplier_id
              AND pd."Status" <> 'VOIDED'
        ),
        "UpdatedAt"       = NOW() AT TIME ZONE 'UTC',
        "UpdatedByUserId" = p_updated_by_user_id
    WHERE "SupplierId" = p_supplier_id;
END;
$function$
;

-- usp_store_address_delete
DROP FUNCTION IF EXISTS public.usp_store_address_delete(integer, character varying) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_store_address_delete(p_address_id integer DEFAULT NULL::integer, p_customer_code character varying DEFAULT NULL::character varying)
 RETURNS TABLE("Resultado" integer, "Mensaje" character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM master."CustomerAddress"
                  WHERE "AddressId" = p_address_id AND "CustomerCode" = p_customer_code AND "IsDeleted" = FALSE) THEN
        RETURN QUERY SELECT -1, 'Direccion no encontrada'::VARCHAR(500);
        RETURN;
    END IF;

    UPDATE master."CustomerAddress"
    SET "IsDeleted" = TRUE, "IsDefault" = FALSE, "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
    WHERE "AddressId" = p_address_id AND "CustomerCode" = p_customer_code;

    RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);
END;
$function$
;

-- usp_store_address_list
DROP FUNCTION IF EXISTS public.usp_store_address_list(integer, character varying) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_store_address_list(p_company_id integer DEFAULT 1, p_customer_code character varying DEFAULT NULL::character varying)
 RETURNS TABLE("AddressId" integer, "Label" character varying, "RecipientName" character varying, "Phone" character varying, "AddressLine" character varying, "City" character varying, "State" character varying, "ZipCode" character varying, "Country" character varying, "Instructions" character varying, "IsDefault" boolean)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT a."AddressId", a."Label"::VARCHAR(50), a."RecipientName"::VARCHAR(200),
           a."Phone"::VARCHAR(40), a."AddressLine"::VARCHAR(300),
           a."City"::VARCHAR(100), a."State"::VARCHAR(100), a."ZipCode"::VARCHAR(20),
           a."Country"::VARCHAR(50), a."Instructions"::VARCHAR(300), a."IsDefault"
    FROM master."CustomerAddress" a
    WHERE a."CompanyId" = p_company_id AND a."CustomerCode" = p_customer_code AND a."IsDeleted" = FALSE
    ORDER BY a."IsDefault" DESC, a."UpdatedAt" DESC;
END;
$function$
;

-- usp_store_address_upsert
DROP FUNCTION IF EXISTS public.usp_store_address_upsert(integer, integer, character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying, boolean) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_store_address_upsert(p_address_id integer DEFAULT NULL::integer, p_company_id integer DEFAULT 1, p_customer_code character varying DEFAULT NULL::character varying, p_label character varying DEFAULT NULL::character varying, p_recipient_name character varying DEFAULT NULL::character varying, p_phone character varying DEFAULT NULL::character varying, p_address_line character varying DEFAULT NULL::character varying, p_city character varying DEFAULT NULL::character varying, p_state character varying DEFAULT NULL::character varying, p_zip_code character varying DEFAULT NULL::character varying, p_country character varying DEFAULT 'Venezuela'::character varying, p_instructions character varying DEFAULT NULL::character varying, p_is_default boolean DEFAULT false)
 RETURNS TABLE("Resultado" integer, "Mensaje" character varying, "NewId" integer)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_new_id INT := 0;
BEGIN
    -- Si es default, quitar default de las demas
    IF p_is_default THEN
        UPDATE master."CustomerAddress"
        SET "IsDefault" = FALSE, "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
        WHERE "CompanyId" = p_company_id AND "CustomerCode" = p_customer_code AND "IsDeleted" = FALSE;
    END IF;

    IF p_address_id IS NULL THEN
        INSERT INTO master."CustomerAddress"
            ("CompanyId", "CustomerCode", "Label", "RecipientName", "Phone", "AddressLine",
             "City", "State", "ZipCode", "Country", "Instructions", "IsDefault")
        VALUES
            (p_company_id, p_customer_code, p_label, p_recipient_name, p_phone, p_address_line,
             p_city, p_state, p_zip_code, COALESCE(p_country, 'Venezuela'), p_instructions, p_is_default)
        RETURNING "AddressId" INTO v_new_id;

        -- Si es la primera, hacerla default
        IF NOT EXISTS (SELECT 1 FROM master."CustomerAddress"
                      WHERE "CompanyId" = p_company_id AND "CustomerCode" = p_customer_code
                        AND "IsDeleted" = FALSE AND "IsDefault" = TRUE) THEN
            UPDATE master."CustomerAddress" SET "IsDefault" = TRUE WHERE "AddressId" = v_new_id;
        END IF;
    ELSE
        IF NOT EXISTS (SELECT 1 FROM master."CustomerAddress"
                      WHERE "AddressId" = p_address_id AND "CustomerCode" = p_customer_code AND "IsDeleted" = FALSE) THEN
            RETURN QUERY SELECT -1, 'Direccion no encontrada'::VARCHAR(500), 0;
            RETURN;
        END IF;

        UPDATE master."CustomerAddress" SET
            "Label" = p_label, "RecipientName" = p_recipient_name, "Phone" = p_phone,
            "AddressLine" = p_address_line, "City" = p_city, "State" = p_state,
            "ZipCode" = p_zip_code, "Country" = COALESCE(p_country, 'Venezuela'),
            "Instructions" = p_instructions, "IsDefault" = p_is_default,
            "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
        WHERE "AddressId" = p_address_id AND "CustomerCode" = p_customer_code;
        v_new_id := p_address_id;
    END IF;

    RETURN QUERY SELECT 1, 'OK'::VARCHAR(500), v_new_id;

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500), 0;
END;
$function$
;

-- usp_store_brand_list
DROP FUNCTION IF EXISTS public.usp_store_brand_list(integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_store_brand_list(p_company_id integer DEFAULT 1)
 RETURNS TABLE(code character varying, name character varying, "productCount" integer)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        b."BrandCode"::VARCHAR(20),
        b."BrandName"::VARCHAR(200),
        0::INT
    FROM master."Brand" b
    WHERE b."CompanyId" = p_company_id
      AND b."IsDeleted" = FALSE
      AND b."IsActive"  = TRUE
    ORDER BY b."BrandName";
END;
$function$
;

-- usp_store_category_list
DROP FUNCTION IF EXISTS public.usp_store_category_list(integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_store_category_list(p_company_id integer DEFAULT 1)
 RETURNS TABLE(code character varying, name character varying, "productCount" bigint)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        c."CategoryCode"::VARCHAR(100),
        c."CategoryName"::VARCHAR(200),
        COUNT(p."ProductId")
    FROM master."Category" c
    LEFT JOIN master."Product" p
        ON p."CategoryCode" = c."CategoryCode"
        AND p."CompanyId" = c."CompanyId"
        AND p."IsDeleted" = FALSE
        AND p."IsActive" = TRUE
        AND (p."StockQty" > 0 OR p."IsService" = TRUE)
    WHERE c."CompanyId" = p_company_id
      AND c."IsDeleted" = FALSE
      AND c."IsActive" = TRUE
    GROUP BY c."CategoryCode", c."CategoryName"
    HAVING COUNT(p."ProductId") > 0
    ORDER BY c."CategoryName";
END;
$function$
;

-- usp_store_customer_findorcreate
DROP FUNCTION IF EXISTS public.usp_store_customer_findorcreate(integer, character varying, character varying, character varying, character varying, character varying) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_store_customer_findorcreate(p_company_id integer DEFAULT 1, p_email character varying DEFAULT NULL::character varying, p_name character varying DEFAULT NULL::character varying, p_phone character varying DEFAULT NULL::character varying, p_address character varying DEFAULT NULL::character varying, p_fiscal_id character varying DEFAULT NULL::character varying)
 RETURNS TABLE("CustomerCode" character varying, "Resultado" integer, "Mensaje" character varying)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_code VARCHAR(24);
    v_seq  INT;
BEGIN
    SELECT c."CustomerCode" INTO v_code
    FROM master."Customer" c
    WHERE c."CompanyId" = p_company_id AND c."Email" = p_email AND c."IsDeleted" = FALSE
    LIMIT 1;

    IF v_code IS NOT NULL THEN
        RETURN QUERY SELECT v_code, 1, 'Cliente encontrado'::VARCHAR(500);
        RETURN;
    END IF;

    SELECT COALESCE(MAX(REPLACE(c."CustomerCode", 'ECOM-', '')::INT), 0) + 1
    INTO v_seq
    FROM master."Customer" c
    WHERE c."CompanyId" = p_company_id AND c."CustomerCode" LIKE 'ECOM-%';

    v_code := 'ECOM-' || LPAD(v_seq::TEXT, 6, '0');

    INSERT INTO master."Customer" (
        "CompanyId", "CustomerCode", "CustomerName", "Email", "Phone", "AddressLine", "FiscalId",
        "IsActive", "IsDeleted", "CreatedAt", "UpdatedAt"
    ) VALUES (
        p_company_id, v_code, p_name, p_email, p_phone, p_address,
        COALESCE(p_fiscal_id, ''),
        TRUE, FALSE, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'
    );

    RETURN QUERY SELECT v_code, 1, 'Cliente creado'::VARCHAR(500);
END;
$function$
;

-- usp_store_customer_login
DROP FUNCTION IF EXISTS public.usp_store_customer_login(character varying) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_store_customer_login(p_email character varying)
 RETURNS TABLE("UserId" integer, "Email" character varying, "displayName" character varying, "passwordHash" character varying, "isActive" boolean, "customerCode" character varying, "customerName" character varying, phone character varying, address character varying, "fiscalId" character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        u."UserId",
        u."Email"::VARCHAR(150),
        u."DisplayName"::VARCHAR(200),
        u."PasswordHash"::VARCHAR(500),
        u."IsActive",
        c."CustomerCode"::VARCHAR(24),
        c."CustomerName"::VARCHAR(200),
        c."Phone"::VARCHAR(40),
        c."AddressLine"::VARCHAR(250),
        c."FiscalId"::VARCHAR(30)
    FROM sec."Users" u
    LEFT JOIN master."Customer" c ON c."Email" = u."Email" AND c."CompanyId" = u."CompanyId" AND c."IsDeleted" = FALSE
    WHERE u."Email" = p_email AND u."IsDeleted" = FALSE AND u."Role" = 'customer'
    LIMIT 1;
END;
$function$
;

-- usp_store_customer_register
DROP FUNCTION IF EXISTS public.usp_store_customer_register(integer, character varying, character varying, character varying, character varying, character varying, character varying) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_store_customer_register(p_company_id integer DEFAULT 1, p_email character varying DEFAULT NULL::character varying, p_name character varying DEFAULT NULL::character varying, p_password_hash character varying DEFAULT NULL::character varying, p_phone character varying DEFAULT NULL::character varying, p_address character varying DEFAULT NULL::character varying, p_fiscal_id character varying DEFAULT NULL::character varying)
 RETURNS TABLE("Resultado" integer, "Mensaje" character varying)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_customer_code VARCHAR(24);
    v_r INT;
    v_m VARCHAR(500);
BEGIN
    IF EXISTS (SELECT 1 FROM sec."Users" WHERE "Email" = p_email AND "IsDeleted" = FALSE) THEN
        RETURN QUERY SELECT -1, 'Ya existe una cuenta con este email'::VARCHAR(500);
        RETURN;
    END IF;

    -- Buscar o crear cliente
    SELECT r."CustomerCode" INTO v_customer_code
    FROM usp_Store_Customer_FindOrCreate(p_company_id, p_email, p_name, p_phone, p_address, p_fiscal_id) r;

    INSERT INTO sec."Users" (
        "CompanyId", "UserName", "Email", "PasswordHash", "DisplayName",
        "IsAdmin", "IsActive", "IsDeleted", "Role", "CreatedAt"
    ) VALUES (
        p_company_id, p_email, p_email, p_password_hash, p_name,
        FALSE, TRUE, FALSE, 'customer', NOW() AT TIME ZONE 'UTC'
    );

    RETURN QUERY SELECT 1, 'Cuenta creada exitosamente'::VARCHAR(500);
END;
$function$
;

-- usp_store_industrytemplate_list
DROP FUNCTION IF EXISTS public.usp_store_industrytemplate_list(integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_store_industrytemplate_list(p_company_id integer DEFAULT 1)
 RETURNS TABLE(id integer, code character varying, name character varying, description character varying, "iconName" character varying, "sortOrder" integer)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        it."IndustryTemplateId" AS "id",
        it."TemplateCode"       AS "code",
        it."TemplateName"       AS "name",
        it."Description"        AS "description",
        it."IconName"           AS "iconName",
        it."SortOrder"          AS "sortOrder"
    FROM store."IndustryTemplate" it
    WHERE it."CompanyId" = p_company_id
      AND it."IsDeleted" = FALSE
      AND it."IsActive"  = TRUE
    ORDER BY it."SortOrder", it."TemplateName";
END;
$function$
;

-- usp_store_industrytemplate_listattributes
DROP FUNCTION IF EXISTS public.usp_store_industrytemplate_listattributes(integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_store_industrytemplate_listattributes(p_company_id integer DEFAULT 1)
 RETURNS TABLE("templateCode" character varying, key character varying, label character varying, "dataType" character varying, "isRequired" boolean, "defaultValue" character varying, "listOptions" character varying, "displayGroup" character varying, "sortOrder" integer)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        ita."TemplateCode"   AS "templateCode",
        ita."AttributeKey"   AS "key",
        ita."AttributeLabel" AS "label",
        ita."DataType"       AS "dataType",
        ita."IsRequired"     AS "isRequired",
        ita."DefaultValue"   AS "defaultValue",
        ita."ListOptions"    AS "listOptions",
        ita."DisplayGroup"   AS "displayGroup",
        ita."SortOrder"      AS "sortOrder"
    FROM store."IndustryTemplateAttribute" ita
    WHERE ita."CompanyId" = p_company_id
      AND ita."IsDeleted" = FALSE
      AND ita."IsActive"  = TRUE
    ORDER BY ita."TemplateCode", ita."SortOrder";
END;
$function$
;

-- usp_store_order_create
DROP FUNCTION IF EXISTS public.usp_store_order_create(integer, integer, character varying, character varying, character varying, character varying, character varying, character varying, character varying, jsonb, integer, integer, character varying) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_store_order_create(p_company_id integer DEFAULT 1, p_branch_id integer DEFAULT 1, p_customer_code character varying DEFAULT NULL::character varying, p_customer_name character varying DEFAULT NULL::character varying, p_customer_email character varying DEFAULT NULL::character varying, p_fiscal_id character varying DEFAULT NULL::character varying, p_phone character varying DEFAULT NULL::character varying, p_address character varying DEFAULT NULL::character varying, p_notes character varying DEFAULT NULL::character varying, p_items_json jsonb DEFAULT NULL::jsonb, p_address_id integer DEFAULT NULL::integer, p_payment_method_id integer DEFAULT NULL::integer, p_payment_method_type character varying DEFAULT NULL::character varying)
 RETURNS TABLE("OrderNumber" character varying, "OrderToken" character varying, "Resultado" integer, "Mensaje" character varying)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_order_number VARCHAR(60);
    v_order_token  VARCHAR(100);
    v_today        VARCHAR(8);
    v_seq          INT;
    v_total_sub    NUMERIC(18,2);
    v_total_tax    NUMERIC(18,2);
BEGIN
    v_today := TO_CHAR(NOW(), 'YYYYMMDD');

    SELECT COALESCE(MAX(
        CASE WHEN RIGHT("DocumentNumber", 4) ~ '^\d+$'
             THEN RIGHT("DocumentNumber", 4)::INT ELSE 0 END
    ), 0) + 1
    INTO v_seq
    FROM doc."SalesDocument"
    WHERE "OperationType" = 'PEDIDO' AND "DocumentNumber" LIKE 'ECOM-' || v_today || '-%';

    v_order_number := 'ECOM-' || v_today || '-' || LPAD(v_seq::TEXT, 4, '0');
    v_order_token  := LOWER(REPLACE(gen_random_uuid()::TEXT, '-', ''));

    -- Calcular totales desde JSON
    SELECT COALESCE(SUM((item->>'st')::NUMERIC(18,2)), 0),
           COALESCE(SUM((item->>'ta')::NUMERIC(18,2)), 0)
    INTO v_total_sub, v_total_tax
    FROM jsonb_array_elements(p_items_json) AS item;

    -- Insertar cabecera
    INSERT INTO doc."SalesDocument" (
        "DocumentNumber", "SerialType", "OperationType",
        "CustomerCode", "CustomerName", "FiscalId",
        "IssueDate", "DocumentTime",
        "Subtotal", "TaxableAmount", "ExemptAmount", "TaxAmount", "TotalAmount", "DiscountAmount",
        "IsVoided", "IsCanceled", "IsInvoiced", "IsDelivered",
        "Notes", "CurrencyCode", "ExchangeRate",
        "CreatedAt", "UpdatedAt", "IsDeleted"
    ) VALUES (
        v_order_number, 'ECOM', 'PEDIDO',
        p_customer_code, p_customer_name, COALESCE(p_fiscal_id, ''),
        CURRENT_DATE, TO_CHAR(NOW(), 'HH24:MI:SS'),
        v_total_sub, v_total_sub, 0, v_total_tax, v_total_sub + v_total_tax, 0,
        FALSE, 'N', 'N', 'N',
        COALESCE(p_notes, '') || ' | token=' || v_order_token
            || CASE WHEN p_address_id IS NOT NULL THEN ' | addressId=' || p_address_id::TEXT ELSE '' END
            || CASE WHEN p_payment_method_id IS NOT NULL THEN ' | paymentMethodId=' || p_payment_method_id::TEXT ELSE '' END
            || CASE WHEN p_payment_method_type IS NOT NULL THEN ' | paymentType=' || p_payment_method_type ELSE '' END,
        'USD', 1.0,
        NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC', FALSE
    );

    -- Insertar lineas de detalle desde JSON
    INSERT INTO doc."SalesDocumentLine" (
        "DocumentNumber", "SerialType", "DocumentType", "LineNumber",
        "ProductCode", "Description", "Quantity", "UnitPrice", "DiscountUnitPrice", "UnitCost",
        "Subtotal", "DiscountAmount", "LineTotal", "TaxRate", "TaxAmount", "IsVoided",
        "CreatedAt", "UpdatedAt", "IsDeleted"
    )
    SELECT
        v_order_number, 'ECOM', 'PEDIDO', ROW_NUMBER() OVER ()::INT,
        (item->>'pc')::VARCHAR(80),
        (item->>'pn')::VARCHAR(250),
        (item->>'qty')::NUMERIC(18,3),
        (item->>'up')::NUMERIC(18,2),
        (item->>'up')::NUMERIC(18,2),
        0,
        (item->>'st')::NUMERIC(18,2),
        0,
        (item->>'st')::NUMERIC(18,2) + (item->>'ta')::NUMERIC(18,2),
        (item->>'tr')::NUMERIC(9,4),
        (item->>'ta')::NUMERIC(18,2),
        FALSE,
        NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC', FALSE
    FROM jsonb_array_elements(p_items_json) AS item;

    -- Descontar stock
    UPDATE master."Product" pr
    SET "StockQty" = pr."StockQty" - d.qty
    FROM (
        SELECT (item->>'pc')::VARCHAR(80) AS pc, SUM((item->>'qty')::NUMERIC) AS qty
        FROM jsonb_array_elements(p_items_json) AS item
        GROUP BY (item->>'pc')
    ) d
    WHERE d.pc = pr."ProductCode" AND pr."CompanyId" = p_company_id;

    RETURN QUERY SELECT v_order_number, v_order_token, 1, 'Pedido creado exitosamente'::VARCHAR(500);

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT NULL::VARCHAR(60), NULL::VARCHAR(100), -99, SQLERRM::VARCHAR(500);
END;
$function$
;

-- usp_store_order_getbynumber
DROP FUNCTION IF EXISTS public.usp_store_order_getbynumber(integer, character varying) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_store_order_getbynumber(p_company_id integer DEFAULT 1, p_order_number character varying DEFAULT NULL::character varying)
 RETURNS TABLE("orderNumber" character varying, "orderDate" date, "customerCode" character varying, "customerName" character varying, "fiscalId" character varying, subtotal numeric, "taxAmount" numeric, "totalAmount" numeric, "discountAmount" numeric, "isInvoiced" character varying, "isDelivered" character varying, notes character varying, "createdAt" timestamp without time zone)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT d."DocumentNumber"::VARCHAR(60), d."IssueDate",
        d."CustomerCode"::VARCHAR(24), d."CustomerName"::VARCHAR(200), d."FiscalId"::VARCHAR(30),
        d."Subtotal", d."TaxAmount", d."TotalAmount",
        d."DiscountAmount", d."IsInvoiced"::VARCHAR(1),
        d."IsDelivered"::VARCHAR(1), d."Notes"::TEXT, d."CreatedAt"
    FROM doc."SalesDocument" d
    WHERE d."OperationType" = 'PEDIDO' AND d."DocumentNumber" = p_order_number
    LIMIT 1;
END;
$function$
;

-- usp_store_order_getbynumber_lines
DROP FUNCTION IF EXISTS public.usp_store_order_getbynumber_lines(character varying) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_store_order_getbynumber_lines(p_order_number character varying DEFAULT NULL::character varying)
 RETURNS TABLE("lineNumber" integer, "productCode" character varying, "productName" character varying, quantity numeric, "unitPrice" numeric, subtotal numeric, "taxRate" numeric, "taxAmount" numeric, "lineTotal" numeric)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT l."LineNumber", l."ProductCode"::VARCHAR(80), l."Description"::VARCHAR(250),
        l."Quantity", l."UnitPrice", l."Subtotal",
        l."TaxRate", l."TaxAmount", l."LineTotal"
    FROM doc."SalesDocumentLine" l
    WHERE l."DocumentNumber" = p_order_number AND l."SerialType" = 'ECOM' AND l."IsVoided" = FALSE
    ORDER BY l."LineNumber";
END;
$function$
;

-- usp_store_order_getbytoken
DROP FUNCTION IF EXISTS public.usp_store_order_getbytoken(integer, character varying) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_store_order_getbytoken(p_company_id integer DEFAULT 1, p_token character varying DEFAULT NULL::character varying)
 RETURNS TABLE("orderNumber" character varying, "orderDate" date, "customerCode" character varying, "customerName" character varying, "fiscalId" character varying, subtotal numeric, "taxAmount" numeric, "totalAmount" numeric, "discountAmount" numeric, "isInvoiced" character varying, "isDelivered" character varying, notes character varying, "createdAt" timestamp without time zone)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_order_number VARCHAR(60);
BEGIN
    SELECT d."DocumentNumber" INTO v_order_number
    FROM doc."SalesDocument" d
    WHERE d."OperationType" = 'PEDIDO' AND d."SerialType" = 'ECOM'
      AND d."Notes" LIKE '%token=' || p_token || '%'
    LIMIT 1;

    IF v_order_number IS NOT NULL THEN
        RETURN QUERY SELECT * FROM usp_Store_Order_GetByNumber(p_company_id, v_order_number);
    END IF;
END;
$function$
;

-- usp_store_order_list
DROP FUNCTION IF EXISTS public.usp_store_order_list(integer, character varying, integer, integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_store_order_list(p_company_id integer DEFAULT 1, p_customer_code character varying DEFAULT NULL::character varying, p_page integer DEFAULT 1, p_limit integer DEFAULT 20)
 RETURNS TABLE("TotalCount" bigint, "orderNumber" character varying, "orderDate" date, "customerName" character varying, subtotal numeric, "taxAmount" numeric, "totalAmount" numeric, "isInvoiced" character varying, "isDelivered" character varying, notes character varying)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_offset INT := (GREATEST(p_page, 1) - 1) * p_limit;
    v_total  BIGINT;
BEGIN
    SELECT COUNT(*) INTO v_total FROM doc."SalesDocument"
    WHERE "OperationType" = 'PEDIDO' AND "SerialType" = 'ECOM'
      AND "CustomerCode" = p_customer_code AND "IsVoided" = FALSE;

    RETURN QUERY
    SELECT v_total,
        d."DocumentNumber"::VARCHAR(60), d."IssueDate", d."CustomerName"::VARCHAR(200),
        d."Subtotal", d."TaxAmount", d."TotalAmount",
        d."IsInvoiced"::VARCHAR(1), d."IsDelivered"::VARCHAR(1), d."Notes"::TEXT
    FROM doc."SalesDocument" d
    WHERE d."OperationType" = 'PEDIDO' AND d."SerialType" = 'ECOM'
      AND d."CustomerCode" = p_customer_code AND d."IsVoided" = FALSE
    ORDER BY d."IssueDate" DESC, d."DocumentNumber" DESC
    LIMIT p_limit OFFSET v_offset;
END;
$function$
;

-- usp_store_paymentmethod_delete
DROP FUNCTION IF EXISTS public.usp_store_paymentmethod_delete(integer, character varying) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_store_paymentmethod_delete(p_payment_method_id integer DEFAULT NULL::integer, p_customer_code character varying DEFAULT NULL::character varying)
 RETURNS TABLE("Resultado" integer, "Mensaje" character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM master."CustomerPaymentMethod"
                  WHERE "PaymentMethodId" = p_payment_method_id AND "CustomerCode" = p_customer_code AND "IsDeleted" = FALSE) THEN
        RETURN QUERY SELECT -1, 'Metodo de pago no encontrado'::VARCHAR(500);
        RETURN;
    END IF;

    UPDATE master."CustomerPaymentMethod"
    SET "IsDeleted" = TRUE, "IsDefault" = FALSE, "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
    WHERE "PaymentMethodId" = p_payment_method_id AND "CustomerCode" = p_customer_code;

    RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);
END;
$function$
;

-- usp_store_paymentmethod_list
DROP FUNCTION IF EXISTS public.usp_store_paymentmethod_list(integer, character varying) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_store_paymentmethod_list(p_company_id integer DEFAULT 1, p_customer_code character varying DEFAULT NULL::character varying)
 RETURNS TABLE("PaymentMethodId" integer, "MethodType" character varying, "Label" character varying, "BankName" character varying, "AccountPhone" character varying, "AccountNumber" character varying, "AccountEmail" character varying, "HolderName" character varying, "HolderFiscalId" character varying, "CardType" character varying, "CardLast4" character varying, "CardExpiry" character varying, "IsDefault" boolean)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT m."PaymentMethodId", m."MethodType"::VARCHAR(30), m."Label"::VARCHAR(50),
           m."BankName"::VARCHAR(100), m."AccountPhone"::VARCHAR(40),
           m."AccountNumber"::VARCHAR(40), m."AccountEmail"::VARCHAR(150),
           m."HolderName"::VARCHAR(200), m."HolderFiscalId"::VARCHAR(30),
           m."CardType"::VARCHAR(20), m."CardLast4"::VARCHAR(4),
           m."CardExpiry"::VARCHAR(7), m."IsDefault"
    FROM master."CustomerPaymentMethod" m
    WHERE m."CompanyId" = p_company_id AND m."CustomerCode" = p_customer_code AND m."IsDeleted" = FALSE
    ORDER BY m."IsDefault" DESC, m."UpdatedAt" DESC;
END;
$function$
;

-- usp_store_paymentmethod_upsert
DROP FUNCTION IF EXISTS public.usp_store_paymentmethod_upsert(integer, integer, character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying, boolean) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_store_paymentmethod_upsert(p_payment_method_id integer DEFAULT NULL::integer, p_company_id integer DEFAULT 1, p_customer_code character varying DEFAULT NULL::character varying, p_method_type character varying DEFAULT NULL::character varying, p_label character varying DEFAULT NULL::character varying, p_bank_name character varying DEFAULT NULL::character varying, p_account_phone character varying DEFAULT NULL::character varying, p_account_number character varying DEFAULT NULL::character varying, p_account_email character varying DEFAULT NULL::character varying, p_holder_name character varying DEFAULT NULL::character varying, p_holder_fiscal_id character varying DEFAULT NULL::character varying, p_card_type character varying DEFAULT NULL::character varying, p_card_last4 character varying DEFAULT NULL::character varying, p_card_expiry character varying DEFAULT NULL::character varying, p_is_default boolean DEFAULT false)
 RETURNS TABLE("Resultado" integer, "Mensaje" character varying, "NewId" integer)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_new_id INT := 0;
BEGIN
    IF p_method_type NOT IN ('PAGO_MOVIL', 'TRANSFERENCIA', 'ZELLE', 'EFECTIVO', 'TARJETA') THEN
        RETURN QUERY SELECT -1, 'Tipo de metodo de pago invalido'::VARCHAR(500), 0;
        RETURN;
    END IF;

    IF p_is_default THEN
        UPDATE master."CustomerPaymentMethod"
        SET "IsDefault" = FALSE, "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
        WHERE "CompanyId" = p_company_id AND "CustomerCode" = p_customer_code AND "IsDeleted" = FALSE;
    END IF;

    IF p_payment_method_id IS NULL THEN
        INSERT INTO master."CustomerPaymentMethod"
            ("CompanyId", "CustomerCode", "MethodType", "Label", "BankName", "AccountPhone",
             "AccountNumber", "AccountEmail", "HolderName", "HolderFiscalId",
             "CardType", "CardLast4", "CardExpiry", "IsDefault")
        VALUES
            (p_company_id, p_customer_code, p_method_type, p_label, p_bank_name, p_account_phone,
             p_account_number, p_account_email, p_holder_name, p_holder_fiscal_id,
             p_card_type, p_card_last4, p_card_expiry, p_is_default)
        RETURNING "PaymentMethodId" INTO v_new_id;

        IF NOT EXISTS (SELECT 1 FROM master."CustomerPaymentMethod"
                      WHERE "CompanyId" = p_company_id AND "CustomerCode" = p_customer_code
                        AND "IsDeleted" = FALSE AND "IsDefault" = TRUE) THEN
            UPDATE master."CustomerPaymentMethod" SET "IsDefault" = TRUE WHERE "PaymentMethodId" = v_new_id;
        END IF;
    ELSE
        IF NOT EXISTS (SELECT 1 FROM master."CustomerPaymentMethod"
                      WHERE "PaymentMethodId" = p_payment_method_id AND "CustomerCode" = p_customer_code AND "IsDeleted" = FALSE) THEN
            RETURN QUERY SELECT -1, 'Metodo de pago no encontrado'::VARCHAR(500), 0;
            RETURN;
        END IF;

        UPDATE master."CustomerPaymentMethod" SET
            "MethodType" = p_method_type, "Label" = p_label, "BankName" = p_bank_name,
            "AccountPhone" = p_account_phone, "AccountNumber" = p_account_number,
            "AccountEmail" = p_account_email, "HolderName" = p_holder_name,
            "HolderFiscalId" = p_holder_fiscal_id, "CardType" = p_card_type,
            "CardLast4" = p_card_last4, "CardExpiry" = p_card_expiry,
            "IsDefault" = p_is_default, "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
        WHERE "PaymentMethodId" = p_payment_method_id AND "CustomerCode" = p_customer_code;
        v_new_id := p_payment_method_id;
    END IF;

    RETURN QUERY SELECT 1, 'OK'::VARCHAR(500), v_new_id;

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500), 0;
END;
$function$
;

-- usp_store_product_getattributes
DROP FUNCTION IF EXISTS public.usp_store_product_getattributes(integer, character varying) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_store_product_getattributes(p_company_id integer DEFAULT 1, p_product_code character varying DEFAULT NULL::character varying)
 RETURNS TABLE(key character varying, label character varying, "dataType" character varying, "displayGroup" character varying, "valueText" character varying, "valueNumber" numeric, "valueDate" date, "valueBoolean" boolean, "sortOrder" integer)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        pa."AttributeKey"    AS "key",
        ita."AttributeLabel" AS "label",
        ita."DataType"       AS "dataType",
        ita."DisplayGroup"   AS "displayGroup",
        pa."ValueText"       AS "valueText",
        pa."ValueNumber"     AS "valueNumber",
        pa."ValueDate"       AS "valueDate",
        pa."ValueBoolean"    AS "valueBoolean",
        ita."SortOrder"      AS "sortOrder"
    FROM store."ProductAttribute" pa
    INNER JOIN store."IndustryTemplateAttribute" ita
        ON ita."TemplateCode"  = pa."TemplateCode"
       AND ita."AttributeKey"  = pa."AttributeKey"
       AND ita."CompanyId"     = pa."CompanyId"
       AND ita."IsDeleted"     = FALSE
       AND ita."IsActive"      = TRUE
    WHERE pa."CompanyId"   = p_company_id
      AND pa."ProductCode" = p_product_code
      AND pa."IsDeleted"   = FALSE
      AND pa."IsActive"    = TRUE
    ORDER BY ita."DisplayGroup", ita."SortOrder";
END;
$function$
;

-- usp_store_product_getbycode
DROP FUNCTION IF EXISTS public.usp_store_product_getbycode(integer, integer, character varying) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_store_product_getbycode(p_company_id integer DEFAULT 1, p_branch_id integer DEFAULT 1, p_code character varying DEFAULT NULL::character varying)
 RETURNS TABLE(id bigint, code character varying, name character varying, "fullDescription" character varying, "shortDescription" character varying, "longDescription" character varying, category character varying, "categoryName" character varying, "brandCode" character varying, "brandName" character varying, price numeric, "compareAtPrice" numeric, "costPrice" numeric, stock numeric, "isService" boolean, "unitCode" character varying, "taxRate" numeric, "weightKg" numeric, "widthCm" numeric, "heightCm" numeric, "depthCm" numeric, "warrantyMonths" integer, "barCode" character varying, slug character varying, "avgRating" double precision, "reviewCount" integer)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        p."ProductId"::BIGINT,
        p."ProductCode"::VARCHAR(80),
        p."ProductName"::VARCHAR(250),
        COALESCE(p."ShortDescription", p."ProductName")::TEXT,
        p."ShortDescription"::VARCHAR(500),
        p."LongDescription"::TEXT,
        p."CategoryCode"::VARCHAR(100),
        c."CategoryName"::VARCHAR(200),
        p."BrandCode"::VARCHAR(20),
        b."BrandName"::VARCHAR(200),
        p."SalesPrice",
        p."CompareAtPrice",
        p."CostPrice",
        p."StockQty",
        p."IsService",
        p."UnitCode"::VARCHAR(20),
        CASE WHEN p."DefaultTaxRate" > 1 THEN p."DefaultTaxRate" / 100.0
             ELSE COALESCE(p."DefaultTaxRate", 0) END,
        p."WeightKg",
        p."WidthCm",
        p."HeightCm",
        p."DepthCm",
        p."WarrantyMonths",
        p."BarCode"::VARCHAR(50),
        p."Slug"::VARCHAR(200),
        COALESCE(rv."AvgRating", 0),
        COALESCE(rv."ReviewCount", 0)::INT
    FROM master."Product" p
    LEFT JOIN master."Category" c ON c."CategoryCode" = p."CategoryCode" AND c."CompanyId" = p."CompanyId" AND c."IsDeleted" = FALSE
    LEFT JOIN master."Brand" b ON b."BrandCode" = p."BrandCode" AND b."CompanyId" = p."CompanyId" AND b."IsDeleted" = FALSE
    LEFT JOIN LATERAL (
        SELECT
            AVG(r."Rating"::DOUBLE PRECISION) AS "AvgRating",
            COUNT(*)::INT AS "ReviewCount"
        FROM store."ProductReview" r
        WHERE r."CompanyId" = p."CompanyId"
          AND r."ProductCode" = p."ProductCode"
          AND r."IsDeleted" = FALSE AND r."IsApproved" = TRUE
    ) rv ON TRUE
    WHERE p."CompanyId"   = p_company_id
      AND p."IsDeleted"   = FALSE
      AND p."IsActive"    = TRUE
      AND p."ProductCode" = p_code
    LIMIT 1;
END;
$function$
;

-- usp_store_product_gethighlights
DROP FUNCTION IF EXISTS public.usp_store_product_gethighlights(integer, character varying) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_store_product_gethighlights(p_company_id integer DEFAULT 1, p_code character varying DEFAULT NULL::character varying)
 RETURNS TABLE(text character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT h."HighlightText"::character varying
    FROM store."ProductHighlight" h
    WHERE h."CompanyId"   = p_company_id
      AND h."ProductCode" = p_code
      AND h."IsActive"    = TRUE
    ORDER BY h."SortOrder", h."HighlightId";
END;
$function$
;

-- usp_store_product_getimages
DROP FUNCTION IF EXISTS public.usp_store_product_getimages(integer, integer, character varying) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_store_product_getimages(p_company_id integer DEFAULT 1, p_branch_id integer DEFAULT 1, p_code character varying DEFAULT NULL::character varying)
 RETURNS TABLE(id integer, url character varying, role character varying, "isPrimary" boolean, "sortOrder" integer, "altText" character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        ma."MediaAssetId",
        ma."PublicUrl"::VARCHAR(500),
        ei."RoleCode"::VARCHAR(50),
        ei."IsPrimary",
        ei."SortOrder",
        ma."AltText"::VARCHAR(200)
    FROM cfg."EntityImage" ei
    INNER JOIN cfg."MediaAsset" ma ON ma."MediaAssetId" = ei."MediaAssetId"
    INNER JOIN master."Product" p ON p."ProductId" = ei."EntityId" AND p."CompanyId" = ei."CompanyId"
    WHERE ei."CompanyId"   = p_company_id
      AND ei."BranchId"    = p_branch_id
      AND ei."EntityType"  = 'MASTER_PRODUCT'
      AND p."ProductCode"  = p_code
      AND ei."IsDeleted"   = FALSE
      AND ei."IsActive"    = TRUE
      AND ma."IsDeleted"   = FALSE
      AND ma."IsActive"    = TRUE
    ORDER BY CASE WHEN ei."IsPrimary" = TRUE THEN 0 ELSE 1 END, ei."SortOrder";
END;
$function$
;

-- usp_store_product_getspecs
DROP FUNCTION IF EXISTS public.usp_store_product_getspecs(integer, character varying) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_store_product_getspecs(p_company_id integer DEFAULT 1, p_code character varying DEFAULT NULL::character varying)
 RETURNS TABLE("group" character varying, key character varying, value character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT s."SpecGroup"::VARCHAR(100),
           s."SpecKey"::VARCHAR(100),
           s."SpecValue"::VARCHAR(500)
    FROM store."ProductSpec" s
    WHERE s."CompanyId"   = p_company_id
      AND s."ProductCode" = p_code
      AND s."IsActive"    = TRUE
    ORDER BY s."SpecGroup", s."SortOrder", s."SpecId";
END;
$function$
;

-- usp_store_product_getvariantoptions
DROP FUNCTION IF EXISTS public.usp_store_product_getvariantoptions(integer, character varying) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_store_product_getvariantoptions(p_company_id integer DEFAULT 1, p_parent_product_code character varying DEFAULT NULL::character varying)
 RETURNS TABLE(code character varying, "groupCode" character varying, "groupName" character varying, "displayType" character varying, "optionCode" character varying, "optionLabel" character varying, "colorHex" character varying, "imageUrl" character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        pv."VariantProductCode" AS "code",
        vg."GroupCode"          AS "groupCode",
        vg."GroupName"          AS "groupName",
        vg."DisplayType"       AS "displayType",
        vo."OptionCode"         AS "optionCode",
        vo."OptionLabel"        AS "optionLabel",
        vo."ColorHex"           AS "colorHex",
        vo."ImageUrl"           AS "imageUrl"
    FROM store."ProductVariantOptionValue" pvov
    INNER JOIN store."ProductVariant" pv       ON pv."ProductVariantId"  = pvov."ProductVariantId"
    INNER JOIN store."ProductVariantOption" vo  ON vo."VariantOptionId"   = pvov."VariantOptionId"
    INNER JOIN store."ProductVariantGroup" vg   ON vg."VariantGroupId"   = vo."VariantGroupId"
    WHERE pv."CompanyId"          = p_company_id
      AND pv."ParentProductCode"  = p_parent_product_code
      AND pv."IsDeleted" = FALSE
      AND pv."IsActive"  = TRUE
    ORDER BY vg."SortOrder", vo."SortOrder";
END;
$function$
;

-- usp_store_product_getvariants
DROP FUNCTION IF EXISTS public.usp_store_product_getvariants(integer, character varying) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_store_product_getvariants(p_company_id integer DEFAULT 1, p_parent_product_code character varying DEFAULT NULL::character varying)
 RETURNS TABLE("variantId" integer, code character varying, name character varying, sku character varying, price numeric, "priceDelta" numeric, stock numeric, "isDefault" boolean, "sortOrder" integer)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        pv."ProductVariantId"                                      AS "variantId",
        pv."VariantProductCode"                                    AS "code",
        p."ProductName"                                            AS "name",
        COALESCE(pv."SKU", pv."VariantProductCode")                AS "sku",
        p."SalesPrice"                                             AS "price",
        pv."PriceDelta"                                            AS "priceDelta",
        COALESCE(pv."StockOverride", p."StockQty")                 AS "stock",
        pv."IsDefault"                                             AS "isDefault",
        pv."SortOrder"                                             AS "sortOrder"
    FROM store."ProductVariant" pv
    INNER JOIN master."Product" p
        ON p."ProductCode" = pv."VariantProductCode"
       AND p."CompanyId"   = pv."CompanyId"
    WHERE pv."CompanyId"          = p_company_id
      AND pv."ParentProductCode"  = p_parent_product_code
      AND pv."IsDeleted" = FALSE
      AND pv."IsActive"  = TRUE
      AND p."IsDeleted"  = FALSE
      AND p."IsActive"   = TRUE
    ORDER BY pv."SortOrder", pv."ProductVariantId";
END;
$function$
;

-- usp_store_product_list
DROP FUNCTION IF EXISTS public.usp_store_product_list(integer, integer, character varying, character varying, character varying, numeric, numeric, integer, boolean, character varying, integer, integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_store_product_list(p_company_id integer DEFAULT 1, p_branch_id integer DEFAULT 1, p_search character varying DEFAULT NULL::character varying, p_category character varying DEFAULT NULL::character varying, p_brand character varying DEFAULT NULL::character varying, p_price_min numeric DEFAULT NULL::numeric, p_price_max numeric DEFAULT NULL::numeric, p_min_rating integer DEFAULT NULL::integer, p_in_stock_only boolean DEFAULT true, p_sort_by character varying DEFAULT 'name'::character varying, p_page integer DEFAULT 1, p_limit integer DEFAULT 24)
 RETURNS TABLE("TotalCount" bigint, id bigint, code character varying, name character varying, "fullDescription" character varying, "shortDescription" character varying, category character varying, "categoryName" character varying, "brandCode" character varying, "brandName" character varying, price numeric, "compareAtPrice" numeric, stock numeric, "isService" boolean, "taxRate" numeric, "imageUrl" character varying, "avgRating" double precision, "reviewCount" integer)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_offset         INT := (GREATEST(p_page, 1) - 1) * p_limit;
    v_search_pattern VARCHAR(202) := CASE
        WHEN p_search IS NOT NULL AND TRIM(p_search) <> '' THEN '%' || TRIM(p_search) || '%'
        ELSE NULL END;
    v_total          BIGINT;
BEGIN
    -- Calcular total
    SELECT COUNT(*) INTO v_total
    FROM master."Product" p
    LEFT JOIN (
        SELECT r."CompanyId", r."ProductCode",
               AVG(r."Rating"::DOUBLE PRECISION) AS "AvgRating",
               COUNT(*) AS "ReviewCount"
        FROM store."ProductReview" r
        WHERE r."IsDeleted" = FALSE AND r."IsApproved" = TRUE
        GROUP BY r."CompanyId", r."ProductCode"
    ) rv ON rv."CompanyId" = p."CompanyId" AND rv."ProductCode" = p."ProductCode"
    WHERE p."CompanyId"  = p_company_id
      AND p."IsDeleted"  = FALSE
      AND p."IsActive"   = TRUE
      AND (NOT p_in_stock_only OR p."StockQty" > 0 OR p."IsService" = TRUE)
      AND (v_search_pattern IS NULL OR p."ProductCode" LIKE v_search_pattern
           OR p."ProductName" LIKE v_search_pattern OR p."CategoryCode" LIKE v_search_pattern)
      AND (p_category IS NULL OR p."CategoryCode" = p_category)
      AND (p_brand IS NULL OR p."BrandCode" = p_brand)
      AND (p_price_min IS NULL OR p."SalesPrice" >= p_price_min)
      AND (p_price_max IS NULL OR p."SalesPrice" <= p_price_max)
      AND (p_min_rating IS NULL OR COALESCE(rv."AvgRating", 0) >= p_min_rating);

    RETURN QUERY
    SELECT v_total,
        p."ProductId"::BIGINT,
        p."ProductCode"::VARCHAR(80),
        p."ProductName"::VARCHAR(250),
        COALESCE(p."ShortDescription", p."ProductName")::VARCHAR(500),
        p."ShortDescription"::VARCHAR(500),
        p."CategoryCode"::VARCHAR(100),
        c."CategoryName"::VARCHAR(200),
        p."BrandCode"::VARCHAR(20),
        b."BrandName"::VARCHAR(200),
        p."SalesPrice",
        p."CompareAtPrice",
        p."StockQty",
        p."IsService",
        CASE WHEN p."DefaultTaxRate" > 1 THEN p."DefaultTaxRate" / 100.0
             ELSE COALESCE(p."DefaultTaxRate", 0) END,
        img."PublicUrl"::VARCHAR(500),
        COALESCE(rv."AvgRating", 0),
        COALESCE(rv."ReviewCount", 0)::INT
    FROM master."Product" p
    LEFT JOIN master."Category" c
        ON c."CategoryCode" = p."CategoryCode" AND c."CompanyId" = p."CompanyId" AND c."IsDeleted" = FALSE
    LEFT JOIN master."Brand" b
        ON b."BrandCode" = p."BrandCode" AND b."CompanyId" = p."CompanyId" AND b."IsDeleted" = FALSE
    LEFT JOIN LATERAL (
        SELECT ma."PublicUrl"
        FROM cfg."EntityImage" ei
        INNER JOIN cfg."MediaAsset" ma ON ma."MediaAssetId" = ei."MediaAssetId"
        WHERE ei."CompanyId"   = p."CompanyId"
          AND ei."BranchId"    = p_branch_id
          AND ei."EntityType"  = 'MASTER_PRODUCT'
          AND ei."EntityId"    = p."ProductId"
          AND ei."IsDeleted"   = FALSE
          AND ei."IsActive"    = TRUE
          AND ma."IsDeleted"   = FALSE
          AND ma."IsActive"    = TRUE
        ORDER BY CASE WHEN ei."IsPrimary" = TRUE THEN 0 ELSE 1 END, ei."SortOrder", ei."EntityImageId"
        LIMIT 1
    ) img ON TRUE
    LEFT JOIN (
        SELECT r."CompanyId", r."ProductCode",
               AVG(r."Rating"::DOUBLE PRECISION) AS "AvgRating",
               COUNT(*)::INT AS "ReviewCount"
        FROM store."ProductReview" r
        WHERE r."IsDeleted" = FALSE AND r."IsApproved" = TRUE
        GROUP BY r."CompanyId", r."ProductCode"
    ) rv ON rv."CompanyId" = p."CompanyId" AND rv."ProductCode" = p."ProductCode"
    WHERE p."CompanyId"  = p_company_id
      AND p."IsDeleted"  = FALSE
      AND p."IsActive"   = TRUE
      AND (NOT p_in_stock_only OR p."StockQty" > 0 OR p."IsService" = TRUE)
      AND (v_search_pattern IS NULL OR p."ProductCode" LIKE v_search_pattern
           OR p."ProductName" LIKE v_search_pattern OR p."CategoryCode" LIKE v_search_pattern)
      AND (p_category IS NULL OR p."CategoryCode" = p_category)
      AND (p_brand IS NULL OR p."BrandCode" = p_brand)
      AND (p_price_min IS NULL OR p."SalesPrice" >= p_price_min)
      AND (p_price_max IS NULL OR p."SalesPrice" <= p_price_max)
      AND (p_min_rating IS NULL OR COALESCE(rv."AvgRating", 0) >= p_min_rating)
    ORDER BY
        CASE WHEN p_sort_by = 'name'       THEN p."ProductName" END ASC,
        CASE WHEN p_sort_by = 'price_asc'  THEN p."SalesPrice"  END ASC,
        CASE WHEN p_sort_by = 'price_desc' THEN p."SalesPrice"  END DESC,
        CASE WHEN p_sort_by = 'rating'     THEN rv."AvgRating"  END DESC,
        CASE WHEN p_sort_by = 'newest'     THEN p."ProductId"   END DESC,
        CASE WHEN p_sort_by = 'bestseller' THEN rv."ReviewCount" END DESC,
        p."ProductName" ASC
    LIMIT p_limit OFFSET v_offset;
END;
$function$
;

-- usp_store_review_create
DROP FUNCTION IF EXISTS public.usp_store_review_create(integer, character varying, integer, character varying, character varying, character varying, character varying) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_store_review_create(p_company_id integer DEFAULT 1, p_product_code character varying DEFAULT NULL::character varying, p_rating integer DEFAULT NULL::integer, p_title character varying DEFAULT NULL::character varying, p_comment character varying DEFAULT NULL::character varying, p_reviewer_name character varying DEFAULT 'Cliente'::character varying, p_reviewer_email character varying DEFAULT NULL::character varying)
 RETURNS TABLE("Resultado" integer, "Mensaje" character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
    IF p_rating < 1 OR p_rating > 5 THEN
        RETURN QUERY SELECT -1, 'La calificacion debe ser entre 1 y 5'::VARCHAR(500);
        RETURN;
    END IF;

    INSERT INTO store."ProductReview" (
        "CompanyId", "ProductCode", "Rating", "Title", "Comment",
        "ReviewerName", "ReviewerEmail", "IsVerified", "IsApproved", "IsDeleted", "CreatedAt"
    ) VALUES (
        p_company_id, p_product_code, p_rating, p_title, p_comment,
        p_reviewer_name, p_reviewer_email, FALSE, TRUE, FALSE, NOW() AT TIME ZONE 'UTC'
    );

    RETURN QUERY SELECT 1, 'Resena creada exitosamente'::VARCHAR(500);
END;
$function$
;

-- usp_store_review_list_items
DROP FUNCTION IF EXISTS public.usp_store_review_list_items(integer, character varying, integer, integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_store_review_list_items(p_company_id integer DEFAULT 1, p_product_code character varying DEFAULT NULL::character varying, p_page integer DEFAULT 1, p_limit integer DEFAULT 20)
 RETURNS TABLE(id integer, rating integer, title character varying, comment character varying, "reviewerName" character varying, "isVerified" boolean, "createdAt" timestamp without time zone)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_offset INT := (GREATEST(p_page, 1) - 1) * p_limit;
BEGIN
    RETURN QUERY
    SELECT r."ReviewId", r."Rating", r."Title"::VARCHAR(200), r."Comment"::VARCHAR(2000),
        r."ReviewerName"::VARCHAR(200), r."IsVerified", r."CreatedAt"
    FROM store."ProductReview" r
    WHERE r."CompanyId" = p_company_id AND r."ProductCode" = p_product_code
      AND r."IsDeleted" = FALSE AND r."IsApproved" = TRUE
    ORDER BY r."CreatedAt" DESC
    LIMIT p_limit OFFSET v_offset;
END;
$function$
;

-- usp_store_review_list_summary
DROP FUNCTION IF EXISTS public.usp_store_review_list_summary(integer, character varying) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_store_review_list_summary(p_company_id integer DEFAULT 1, p_product_code character varying DEFAULT NULL::character varying)
 RETURNS TABLE("avgRating" double precision, "totalCount" bigint, star1 bigint, star2 bigint, star3 bigint, star4 bigint, star5 bigint)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT COALESCE(AVG(r."Rating"::DOUBLE PRECISION), 0), COUNT(*),
        SUM(CASE WHEN r."Rating" = 1 THEN 1 ELSE 0 END),
        SUM(CASE WHEN r."Rating" = 2 THEN 1 ELSE 0 END),
        SUM(CASE WHEN r."Rating" = 3 THEN 1 ELSE 0 END),
        SUM(CASE WHEN r."Rating" = 4 THEN 1 ELSE 0 END),
        SUM(CASE WHEN r."Rating" = 5 THEN 1 ELSE 0 END)
    FROM store."ProductReview" r
    WHERE r."CompanyId" = p_company_id AND r."ProductCode" = p_product_code
      AND r."IsDeleted" = FALSE AND r."IsApproved" = TRUE;
END;
$function$
;

-- usp_store_variantgroup_getoptions
DROP FUNCTION IF EXISTS public.usp_store_variantgroup_getoptions(integer, character varying) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_store_variantgroup_getoptions(p_company_id integer DEFAULT 1, p_group_code character varying DEFAULT NULL::character varying)
 RETURNS TABLE(id integer, code character varying, label character varying, "colorHex" character varying, "imageUrl" character varying, "sortOrder" integer)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        vo."VariantOptionId" AS "id",
        vo."OptionCode"      AS "code",
        vo."OptionLabel"     AS "label",
        vo."ColorHex"        AS "colorHex",
        vo."ImageUrl"        AS "imageUrl",
        vo."SortOrder"       AS "sortOrder"
    FROM store."ProductVariantOption" vo
    INNER JOIN store."ProductVariantGroup" vg ON vg."VariantGroupId" = vo."VariantGroupId"
    WHERE vo."CompanyId" = p_company_id
      AND vg."GroupCode" = p_group_code
      AND vo."IsDeleted" = FALSE
      AND vo."IsActive"  = TRUE
      AND vg."IsDeleted" = FALSE
      AND vg."IsActive"  = TRUE
    ORDER BY vo."SortOrder", vo."OptionLabel";
END;
$function$
;

-- usp_store_variantgroup_list
DROP FUNCTION IF EXISTS public.usp_store_variantgroup_list(integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_store_variantgroup_list(p_company_id integer DEFAULT 1)
 RETURNS TABLE(id integer, code character varying, name character varying, "displayType" character varying, "sortOrder" integer)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        vg."VariantGroupId"  AS "id",
        vg."GroupCode"       AS "code",
        vg."GroupName"       AS "name",
        vg."DisplayType"     AS "displayType",
        vg."SortOrder"       AS "sortOrder"
    FROM store."ProductVariantGroup" vg
    WHERE vg."CompanyId" = p_company_id
      AND vg."IsDeleted" = FALSE
      AND vg."IsActive"  = TRUE
    ORDER BY vg."SortOrder", vg."GroupName";
END;
$function$
;

