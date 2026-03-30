-- =============================================
-- Funcion: Emitir Documento de Compra (Unificado)
-- Maneja: ORDEN, COMPRA
-- Compatible con: PostgreSQL 14+
-- =============================================

DROP FUNCTION IF EXISTS sp_emitir_documento_compra_tx(VARCHAR, JSONB, JSONB, JSONB, VARCHAR, BOOLEAN, BOOLEAN);
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
    "numDoc"         VARCHAR,
    "tipoOperacion"  VARCHAR,
    "total"          DOUBLE PRECISION,
    "lineas"         BIGINT
) LANGUAGE plpgsql AS $$
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
    v_num_doc         := NULLIF(p_doc_json->>'NUM_DOC', ''::VARCHAR);
    v_serial_tipo     := COALESCE(NULLIF(p_doc_json->>'SERIALTIPO', ''::VARCHAR),''::VARCHAR);
    v_cod_proveedor   := NULLIF(p_doc_json->>'COD_PROVEEDOR', ''::VARCHAR);
    v_nombre          := NULLIF(p_doc_json->>'NOMBRE', ''::VARCHAR);
    v_rif             := NULLIF(p_doc_json->>'RIF', ''::VARCHAR);
    v_fecha_str       := NULLIF(p_doc_json->>'FECHA', ''::VARCHAR);
    v_fecha           := CASE WHEN v_fecha_str IS NOT NULL THEN v_fecha_str::TIMESTAMP ELSE NOW() AT TIME ZONE 'UTC' END;
    v_fecha_vence_str := NULLIF(p_doc_json->>'FECHA_VENCE', ''::VARCHAR);
    v_fecha_vence     := CASE WHEN v_fecha_vence_str IS NOT NULL THEN v_fecha_vence_str::TIMESTAMP ELSE NULL END;
    v_fecha_recibo_str := NULLIF(p_doc_json->>'FECHA_RECIBO', ''::VARCHAR);
    v_fecha_recibo    := CASE WHEN v_fecha_recibo_str IS NOT NULL THEN v_fecha_recibo_str::TIMESTAMP ELSE NULL END;
    v_observ          := NULLIF(p_doc_json->>'OBSERV', ''::VARCHAR);
    v_concepto        := NULLIF(p_doc_json->>'CONCEPTO', ''::VARCHAR);
    v_num_control     := NULLIF(p_doc_json->>'NUM_CONTROL', ''::VARCHAR);
    v_doc_origen      := NULLIF(p_doc_json->>'DOC_ORIGEN', ''::VARCHAR);
    v_almacen         := NULLIF(p_doc_json->>'ALMACEN', ''::VARCHAR);
    v_precio_dollar   := COALESCE(NULLIF(p_doc_json->>'PRECIO_DOLLAR', ''::VARCHAR)::DOUBLE PRECISION, 0);
    v_moneda          := COALESCE(NULLIF(p_doc_json->>'MONEDA', ''::VARCHAR), 'BS');
    v_tasa_cambio     := COALESCE(NULLIF(p_doc_json->>'TASA_CAMBIO', ''::VARCHAR)::DOUBLE PRECISION, 1);

    -- Retenciones
    v_iva_retenido    := COALESCE(NULLIF(p_doc_json->>'IVA_RETENIDO', ''::VARCHAR)::DOUBLE PRECISION, 0);
    v_monto_islr      := COALESCE(NULLIF(p_doc_json->>'MONTO_ISLR', ''::VARCHAR)::DOUBLE PRECISION, 0);
    v_islr            := NULLIF(p_doc_json->>'ISLR', ''::VARCHAR);

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
        NULLIF(elem->>'COD_SERV', ''::VARCHAR),
        NULLIF(elem->>'DESCRIPCION', ''::VARCHAR),
        COALESCE(NULLIF(elem->>'CANTIDAD', ''::VARCHAR)::DOUBLE PRECISION, 0),
        COALESCE(NULLIF(elem->>'PRECIO', ''::VARCHAR)::DOUBLE PRECISION, 0),
        COALESCE(NULLIF(elem->>'COSTO', ''::VARCHAR)::DOUBLE PRECISION, 0),
        COALESCE(NULLIF(elem->>'ALICUOTA', ''::VARCHAR)::DOUBLE PRECISION, 0),
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
                NULLIF(v_row->>'TIPO_PAGO', ''::VARCHAR),
                NULLIF(v_row->>'BANCO', ''::VARCHAR),
                NULLIF(v_row->>'NUMERO', ''::VARCHAR),
                COALESCE(NULLIF(v_row->>'MONTO', ''::VARCHAR)::DOUBLE PRECISION, 0),
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
$$;
