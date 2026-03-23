-- =============================================
-- Funciones para Documentos Unificados
-- Compatible con: PostgreSQL 14+
-- Adaptados a la estructura existente de tablas
-- =============================================

-- =============================================
-- 1. EMITIR DOCUMENTO DE VENTA (legacy unificado)
-- =============================================
DROP FUNCTION IF EXISTS sp_emitir_documento_venta_tx CASCADE;
DROP FUNCTION IF EXISTS sp_emitir_documento_venta_tx(VARCHAR(20), JSONB, JSONB, JSONB, VARCHAR(60), BOOLEAN, BOOLEAN) CASCADE;
CREATE OR REPLACE FUNCTION sp_emitir_documento_venta_tx(
    p_tipo_operacion         VARCHAR(20),
    p_doc_json               JSONB,
    p_detalle_json           JSONB,
    p_pagos_json             JSONB DEFAULT NULL,
    p_cod_usuario            VARCHAR(60) DEFAULT 'API',
    p_actualizar_inventario  BOOLEAN DEFAULT TRUE,
    p_generar_cxc            BOOLEAN DEFAULT TRUE
)
RETURNS TABLE (
    "ok"             BOOLEAN,
    "numFact"        VARCHAR,
    "tipoOperacion"  VARCHAR,
    "total"          NUMERIC
) LANGUAGE plpgsql AS $$
DECLARE
    v_num_fact       VARCHAR(60);
    v_serial_tipo    VARCHAR(60);
    v_tipo_orden     VARCHAR(6);
    v_codigo         VARCHAR(12);
    v_fecha_str      VARCHAR(50);
    v_fecha          TIMESTAMP;
    v_total          NUMERIC(18,4);
    v_observ         VARCHAR(4000);
    v_cod_usuario_doc VARCHAR(60);
    v_monto_efect    NUMERIC(18,4);
    v_monto_cheque   NUMERIC(18,4);
    v_monto_tarjeta  NUMERIC(18,4);
    v_banco_cheque   VARCHAR(120);
    v_banco_tarjeta  VARCHAR(120);
    v_tarjeta        VARCHAR(60);
    v_cta            VARCHAR(80);
    v_row            JSONB;
BEGIN
    IF p_tipo_operacion NOT IN ('FACT', 'PRESUP', 'PEDIDO', 'COTIZ', 'NOTACRED', 'NOTADEB', 'NOTA_ENTREGA') THEN
        RAISE EXCEPTION 'tipo_operacion_invalido';
    END IF;

    v_num_fact       := NULLIF(p_doc_json->>'NUM_FACT', ''::VARCHAR);
    v_serial_tipo    := COALESCE(NULLIF(p_doc_json->>'SERIALTIPO', ''::VARCHAR),''::VARCHAR);
    v_tipo_orden     := COALESCE(NULLIF(p_doc_json->>'Tipo_Orden', ''::VARCHAR),''::VARCHAR);
    v_codigo         := NULLIF(p_doc_json->>'CODIGO', ''::VARCHAR);
    v_fecha_str      := NULLIF(p_doc_json->>'FECHA', ''::VARCHAR);
    v_fecha          := CASE WHEN v_fecha_str IS NOT NULL THEN v_fecha_str::TIMESTAMP ELSE NOW() AT TIME ZONE 'UTC' END;
    v_total          := COALESCE(NULLIF(p_doc_json->>'TOTAL', ''::VARCHAR)::NUMERIC(18,4), 0);
    v_observ         := NULLIF(p_doc_json->>'OBSERV', ''::VARCHAR);
    v_cod_usuario_doc := COALESCE(NULLIF(p_doc_json->>'COD_USUARIO', ''::VARCHAR), p_cod_usuario);
    v_monto_efect    := COALESCE(NULLIF(p_doc_json->>'Monto_Efect', ''::VARCHAR)::NUMERIC(18,4), 0);
    v_monto_cheque   := COALESCE(NULLIF(p_doc_json->>'Monto_Cheque', ''::VARCHAR)::NUMERIC(18,4), 0);
    v_monto_tarjeta  := COALESCE(NULLIF(p_doc_json->>'Monto_Tarjeta', ''::VARCHAR)::NUMERIC(18,4), 0);
    v_banco_cheque   := NULLIF(p_doc_json->>'BANCO_CHEQUE', ''::VARCHAR);
    v_banco_tarjeta  := NULLIF(p_doc_json->>'Banco_Tarjeta', ''::VARCHAR);
    v_tarjeta        := NULLIF(p_doc_json->>'Tarjeta', ''::VARCHAR);
    v_cta            := NULLIF(p_doc_json->>'Cta', ''::VARCHAR);

    IF v_num_fact IS NULL THEN
        RAISE EXCEPTION 'num_fact_requerido';
    END IF;

    IF EXISTS (SELECT 1 FROM "DocumentosVenta" WHERE "NUM_FACT" = v_num_fact) THEN
        RAISE EXCEPTION 'documento_ya_existe';
    END IF;

    -- Insertar cabecera
    INSERT INTO "DocumentosVenta" (
        "NUM_FACT", "SERIALTIPO", "Tipo_Orden", "TIPO_OPERACION", "CODIGO",
        "FECHA", "FECHA_REPORTE", "TOTAL", "COD_USUARIO", "OBSERV",
        "CANCELADA", "Monto_Efect", "Monto_Cheque", "Monto_Tarjeta",
        "BANCO_CHEQUE", "Banco_Tarjeta", "Tarjeta", "Cta"
    ) VALUES (
        v_num_fact, v_serial_tipo, v_tipo_orden, p_tipo_operacion, v_codigo,
        v_fecha, NOW() AT TIME ZONE 'UTC', v_total, v_cod_usuario_doc, v_observ,
        'N', v_monto_efect, v_monto_cheque, v_monto_tarjeta,
        v_banco_cheque, v_banco_tarjeta, v_tarjeta, v_cta
    );

    -- Insertar detalle
    FOR v_row IN SELECT * FROM jsonb_array_elements(p_detalle_json)
    LOOP
        INSERT INTO "DocumentosVentaDetalle" (
            "NUM_FACT", "SERIALTIPO", "Tipo_Orden", "COD_SERV",
            "CANTIDAD", "PRECIO", "ALICUOTA", "TOTAL", "PRECIO_DESCUENTO", "Relacionada", "Cod_Alterno"
        ) VALUES (
            v_num_fact, v_serial_tipo, v_tipo_orden,
            NULLIF(v_row->>'COD_SERV', ''::VARCHAR),
            COALESCE(NULLIF(v_row->>'CANTIDAD', ''::VARCHAR)::NUMERIC(18,4), 0),
            COALESCE(NULLIF(v_row->>'PRECIO', ''::VARCHAR)::NUMERIC(18,4), 0),
            COALESCE(NULLIF(v_row->>'ALICUOTA', ''::VARCHAR)::NUMERIC(18,4), 0),
            COALESCE(NULLIF(v_row->>'TOTAL', ''::VARCHAR)::NUMERIC(18,4), 0),
            COALESCE(NULLIF(v_row->>'PRECIO_DESCUENTO', ''::VARCHAR)::NUMERIC(18,4), 0),
            COALESCE(NULLIF(v_row->>'Relacionada', ''::VARCHAR)::INT, 0),
            NULLIF(v_row->>'Cod_Alterno', ''::VARCHAR)
        );
    END LOOP;

    -- Insertar pagos si aplica
    IF p_pagos_json IS NOT NULL THEN
        FOR v_row IN SELECT * FROM jsonb_array_elements(p_pagos_json)
        LOOP
            INSERT INTO "DocumentosVentaPago" (
                "NUM_DOC", "TIPO_OPERACION", "TIPO_PAGO", "BANCO", "NUMERO", "MONTO", "FECHA", "CO_USUARIO"
            ) VALUES (
                v_num_fact, p_tipo_operacion,
                NULLIF(v_row->>'TIPO_PAGO', ''::VARCHAR),
                NULLIF(v_row->>'BANCO', ''::VARCHAR),
                NULLIF(v_row->>'NUMERO', ''::VARCHAR),
                COALESCE(NULLIF(v_row->>'MONTO', ''::VARCHAR)::DOUBLE PRECISION, 0),
                v_fecha, p_cod_usuario
            );
        END LOOP;
    END IF;

    -- Generar CxC si es FACTURA
    IF p_generar_cxc AND p_tipo_operacion = 'FACT' THEN
        INSERT INTO "P_Cobrar" ("CODIGO", "FECHA", "DOCUMENTO", "DEBE", "HABER", "SALDO", "TIPO", "OBS", "COD_USUARIO")
        SELECT v_codigo, v_fecha, v_num_fact, v_total, 0, v_total, p_tipo_operacion, 'CxC generada desde documento', p_cod_usuario
        WHERE NOT EXISTS (SELECT 1 FROM "P_Cobrar" WHERE "DOCUMENTO" = v_num_fact);
    END IF;

    RETURN QUERY SELECT TRUE, v_num_fact, p_tipo_operacion, v_total;
END;
$$;

-- =============================================
-- 2. EMITIR DOCUMENTO DE COMPRA (legacy unificado)
-- =============================================
DROP FUNCTION IF EXISTS sp_emitir_documento_compra_tx CASCADE;
DROP FUNCTION IF EXISTS sp_emitir_documento_compra_tx(VARCHAR(20), JSONB, JSONB, JSONB, VARCHAR(60), BOOLEAN, BOOLEAN) CASCADE;
CREATE OR REPLACE FUNCTION sp_emitir_documento_compra_tx(
    p_tipo_operacion         VARCHAR(20),
    p_doc_json               JSONB,
    p_detalle_json           JSONB,
    p_pagos_json             JSONB DEFAULT NULL,
    p_cod_usuario            VARCHAR(60) DEFAULT 'API',
    p_actualizar_inventario  BOOLEAN DEFAULT TRUE,
    p_generar_cxp            BOOLEAN DEFAULT TRUE
)
RETURNS TABLE (
    "ok"             BOOLEAN,
    "numFact"        VARCHAR,
    "tipoOperacion"  VARCHAR,
    "total"          NUMERIC
) LANGUAGE plpgsql AS $$
DECLARE
    v_num_fact       VARCHAR(60);
    v_cod_proveedor  VARCHAR(10);
    v_serial_tipo    VARCHAR(60);
    v_tipo_orden     VARCHAR(6);
    v_fecha_str      VARCHAR(50);
    v_fecha          TIMESTAMP;
    v_total          NUMERIC(18,4);
    v_observ         VARCHAR(500);
    v_nombre         VARCHAR(200);
    v_rif            VARCHAR(50);
    v_tipo           VARCHAR(30);
    v_row            JSONB;
BEGIN
    IF p_tipo_operacion NOT IN ('ORDEN', 'COMPRA') THEN
        RAISE EXCEPTION 'tipo_operacion_invalido';
    END IF;

    v_num_fact      := NULLIF(p_doc_json->>'NUM_FACT', ''::VARCHAR);
    v_cod_proveedor := NULLIF(p_doc_json->>'COD_PROVEEDOR', ''::VARCHAR);
    v_serial_tipo   := COALESCE(NULLIF(p_doc_json->>'SERIALTIPO', ''::VARCHAR),''::VARCHAR);
    v_tipo_orden    := COALESCE(NULLIF(p_doc_json->>'Tipo_Orden', ''::VARCHAR),''::VARCHAR);
    v_fecha_str     := NULLIF(p_doc_json->>'FECHA', ''::VARCHAR);
    v_fecha         := CASE WHEN v_fecha_str IS NOT NULL THEN v_fecha_str::TIMESTAMP ELSE NOW() AT TIME ZONE 'UTC' END;
    v_total         := COALESCE(NULLIF(p_doc_json->>'TOTAL', ''::VARCHAR)::NUMERIC(18,4), 0);
    v_observ        := NULLIF(p_doc_json->>'CONCEPTO', ''::VARCHAR);
    v_nombre        := NULLIF(p_doc_json->>'NOMBRE', ''::VARCHAR);
    v_rif           := NULLIF(p_doc_json->>'RIF', ''::VARCHAR);
    v_tipo          := NULLIF(p_doc_json->>'TIPO', ''::VARCHAR);

    IF v_num_fact IS NULL THEN
        RAISE EXCEPTION 'num_fact_requerido';
    END IF;

    IF EXISTS (SELECT 1 FROM "DocumentosCompra" WHERE "NUM_FACT" = v_num_fact) THEN
        RAISE EXCEPTION 'documento_ya_existe';
    END IF;

    -- Insertar cabecera
    INSERT INTO "DocumentosCompra" (
        "NUM_FACT", "COD_PROVEEDOR", "TIPO_OPERACION", "FECHA", "NOMBRE", "RIF",
        "TOTAL", "TIPO", "CONCEPTO", "COD_USUARIO", "SERIALTIPO", "Tipo_Orden", "ANULADA"
    ) VALUES (
        v_num_fact, v_cod_proveedor, p_tipo_operacion, v_fecha, v_nombre, v_rif,
        v_total, v_tipo, v_observ, p_cod_usuario, v_serial_tipo, v_tipo_orden, 0
    );

    -- Insertar detalle
    FOR v_row IN SELECT * FROM jsonb_array_elements(p_detalle_json)
    LOOP
        INSERT INTO "DocumentosCompraDetalle" (
            "NUM_FACT", "COD_PROVEEDOR", "CODIGO", "Referencia", "DESCRIPCION",
            "FECHA", "CANTIDAD", "PRECIO_COSTO", "Alicuota", "Co_Usuario"
        ) VALUES (
            v_num_fact, v_cod_proveedor,
            NULLIF(v_row->>'CODIGO', ''::VARCHAR),
            NULLIF(v_row->>'Referencia', ''::VARCHAR),
            NULLIF(v_row->>'DESCRIPCION', ''::VARCHAR),
            v_fecha,
            COALESCE(NULLIF(v_row->>'CANTIDAD', ''::VARCHAR)::NUMERIC(18,4), 0),
            COALESCE(NULLIF(v_row->>'PRECIO_COSTO', ''::VARCHAR)::NUMERIC(18,4), 0),
            COALESCE(NULLIF(v_row->>'Alicuota', ''::VARCHAR)::NUMERIC(18,4), 0),
            p_cod_usuario
        );
    END LOOP;

    -- Insertar pagos si aplica
    IF p_pagos_json IS NOT NULL THEN
        FOR v_row IN SELECT * FROM jsonb_array_elements(p_pagos_json)
        LOOP
            INSERT INTO "DocumentosCompraPago" (
                "NUM_DOC", "TIPO_OPERACION", "TIPO_PAGO", "BANCO", "NUMERO", "MONTO", "FECHA", "CO_USUARIO"
            ) VALUES (
                v_num_fact, p_tipo_operacion,
                NULLIF(v_row->>'TIPO_PAGO', ''::VARCHAR),
                NULLIF(v_row->>'BANCO', ''::VARCHAR),
                NULLIF(v_row->>'NUMERO', ''::VARCHAR),
                COALESCE(NULLIF(v_row->>'MONTO', ''::VARCHAR)::DOUBLE PRECISION, 0),
                v_fecha, p_cod_usuario
            );
        END LOOP;
    END IF;

    -- Generar CxP si es COMPRA
    IF p_generar_cxp AND p_tipo_operacion = 'COMPRA' THEN
        INSERT INTO "P_Pagar" ("CODIGO", "FECHA", "DOCUMENTO", "DEBE", "HABER", "SALDO", "TIPO", "OBS", "Cod_usuario")
        SELECT v_cod_proveedor, v_fecha, v_num_fact, v_total, 0, v_total, 'COMPRA', 'CxP generada desde documento', p_cod_usuario
        WHERE NOT EXISTS (SELECT 1 FROM "P_Pagar" WHERE "DOCUMENTO" = v_num_fact);
    END IF;

    RETURN QUERY SELECT TRUE, v_num_fact, p_tipo_operacion, v_total;
END;
$$;

-- =============================================
-- 3. LISTAR DOCUMENTOS VENTA (legacy)
-- =============================================
DROP FUNCTION IF EXISTS sp_documentosventa_list_legacy(VARCHAR(20), VARCHAR(100), VARCHAR(12), DATE, DATE, BOOLEAN, INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION sp_documentosventa_list_legacy(
    p_tipo_operacion VARCHAR(20) DEFAULT NULL,
    p_search         VARCHAR(100) DEFAULT NULL,
    p_codigo         VARCHAR(12) DEFAULT NULL,
    p_desde          DATE DEFAULT NULL,
    p_hasta          DATE DEFAULT NULL,
    p_anulada        BOOLEAN DEFAULT NULL,
    p_page           INT DEFAULT 1,
    p_limit          INT DEFAULT 50
)
RETURNS TABLE (
    "TotalCount"      BIGINT,
    "NUM_FACT"        VARCHAR,
    "SERIALTIPO"      VARCHAR,
    "Tipo_Orden"      VARCHAR,
    "TIPO_OPERACION"  VARCHAR,
    "CODIGO"          VARCHAR,
    "FECHA"           TIMESTAMP,
    "TOTAL"           NUMERIC,
    "COD_USUARIO"     VARCHAR,
    "OBSERV"          VARCHAR,
    "CANCELADA"       VARCHAR,
    "FECHA_ANULA"     TIMESTAMP,
    "ESTADO"          TEXT
) LANGUAGE plpgsql AS $$
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
$$;

-- =============================================
-- 4. LISTAR DOCUMENTOS COMPRA (legacy)
-- =============================================
DROP FUNCTION IF EXISTS sp_documentoscompra_list_legacy(VARCHAR(20), VARCHAR(100), VARCHAR(10), DATE, DATE, BOOLEAN, INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION sp_documentoscompra_list_legacy(
    p_tipo_operacion VARCHAR(20) DEFAULT NULL,
    p_search         VARCHAR(100) DEFAULT NULL,
    p_cod_proveedor  VARCHAR(10) DEFAULT NULL,
    p_desde          DATE DEFAULT NULL,
    p_hasta          DATE DEFAULT NULL,
    p_anulada        BOOLEAN DEFAULT NULL,
    p_page           INT DEFAULT 1,
    p_limit          INT DEFAULT 50
)
RETURNS TABLE (
    "TotalCount"       BIGINT,
    "NUM_FACT"         VARCHAR,
    "COD_PROVEEDOR"    VARCHAR,
    "TIPO_OPERACION"   VARCHAR,
    "FECHA"            TIMESTAMP,
    "NOMBRE"           VARCHAR,
    "RIF"              VARCHAR,
    "TOTAL"            NUMERIC,
    "COD_USUARIO"      VARCHAR,
    "ANULADA"          INT,
    "ESTADO"           TEXT
) LANGUAGE plpgsql AS $$
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
$$;

-- =============================================
-- 5. ANULAR DOCUMENTO VENTA
-- =============================================
DROP FUNCTION IF EXISTS sp_anular_documento_venta_tx(VARCHAR(60), VARCHAR(20), VARCHAR(60), VARCHAR(500)) CASCADE;
CREATE OR REPLACE FUNCTION sp_anular_documento_venta_tx(
    p_num_fact       VARCHAR(60),
    p_tipo_operacion VARCHAR(20) DEFAULT NULL,
    p_cod_usuario    VARCHAR(60) DEFAULT 'API',
    p_motivo         VARCHAR(500) DEFAULT ''
)
RETURNS TABLE (
    "ok"      BOOLEAN,
    "numFact" VARCHAR,
    "mensaje" TEXT
) LANGUAGE plpgsql AS $$
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
            "OBS" = COALESCE("OBS",''::VARCHAR) || ' [ANULADO]'
        WHERE "DOCUMENTO" = p_num_fact;
    END IF;

    RETURN QUERY SELECT TRUE, p_num_fact, 'Documento anulado'::TEXT;
END;
$$;

-- =============================================
-- 6. ANULAR DOCUMENTO COMPRA
-- =============================================
DROP FUNCTION IF EXISTS sp_anular_documento_compra_tx(VARCHAR(60), VARCHAR(20), VARCHAR(60), VARCHAR(500)) CASCADE;
CREATE OR REPLACE FUNCTION sp_anular_documento_compra_tx(
    p_num_fact       VARCHAR(60),
    p_tipo_operacion VARCHAR(20) DEFAULT NULL,
    p_cod_usuario    VARCHAR(60) DEFAULT 'API',
    p_motivo         VARCHAR(500) DEFAULT ''
)
RETURNS TABLE (
    "ok"      BOOLEAN,
    "numFact" VARCHAR,
    "mensaje" TEXT
) LANGUAGE plpgsql AS $$
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
            "OBS" = COALESCE("OBS",''::VARCHAR) || ' [ANULADO]'
        WHERE "DOCUMENTO" = p_num_fact;
    END IF;

    RETURN QUERY SELECT TRUE, p_num_fact, 'Documento anulado'::TEXT;
END;
$$;
