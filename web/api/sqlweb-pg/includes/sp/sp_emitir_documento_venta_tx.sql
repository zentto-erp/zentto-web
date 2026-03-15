-- =============================================
-- Funcion: Emitir Documento de Venta (Unificado)
-- Maneja: FACT, PRESUP, PEDIDO, COTIZ, NOTACRED, NOTADEB, NOTA_ENTREGA
-- Compatible con: PostgreSQL 14+
-- =============================================

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
    "numDoc"         VARCHAR,
    "tipoOperacion"  VARCHAR,
    "total"          DOUBLE PRECISION,
    "lineas"         BIGINT
) LANGUAGE plpgsql AS $$
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
    v_num_doc         := NULLIF(p_doc_json->>'NUM_DOC', '');
    v_serial_tipo     := COALESCE(NULLIF(p_doc_json->>'SERIALTIPO', ''), '');
    v_codigo          := NULLIF(p_doc_json->>'CODIGO', '');
    v_nombre          := NULLIF(p_doc_json->>'NOMBRE', '');
    v_rif             := NULLIF(p_doc_json->>'RIF', '');
    v_fecha_str       := NULLIF(p_doc_json->>'FECHA', '');
    v_fecha           := CASE WHEN v_fecha_str IS NOT NULL THEN v_fecha_str::TIMESTAMP ELSE NOW() AT TIME ZONE 'UTC' END;
    v_fecha_vence_str := NULLIF(p_doc_json->>'FECHA_VENCE', '');
    v_fecha_vence     := CASE WHEN v_fecha_vence_str IS NOT NULL THEN v_fecha_vence_str::TIMESTAMP ELSE NULL END;
    v_observ          := NULLIF(p_doc_json->>'OBSERV', '');
    v_vendedor        := NULLIF(p_doc_json->>'VENDEDOR', '');
    v_doc_origen      := NULLIF(p_doc_json->>'DOC_ORIGEN', '');
    v_tipo_doc_origen := NULLIF(p_doc_json->>'TIPO_DOC_ORIGEN', '');
    v_num_control     := NULLIF(p_doc_json->>'NUM_CONTROL', '');
    v_terminos        := NULLIF(p_doc_json->>'TERMINOS', '');
    v_moneda          := COALESCE(NULLIF(p_doc_json->>'MONEDA', ''), 'BS');
    v_tasa_cambio     := COALESCE(NULLIF(p_doc_json->>'TASA_CAMBIO', '')::DOUBLE PRECISION, 1);
    v_descuento       := COALESCE(NULLIF(p_doc_json->>'DESCUENTO', '')::DOUBLE PRECISION, 0);
    v_placas          := NULLIF(p_doc_json->>'PLACAS', '');
    v_kilometros      := NULLIF(p_doc_json->>'KILOMETROS', '')::INT;

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
        NULLIF(elem->>'COD_SERV', ''),
        NULLIF(elem->>'DESCRIPCION', ''),
        COALESCE(NULLIF(elem->>'CANTIDAD', '')::DOUBLE PRECISION, 0),
        COALESCE(NULLIF(elem->>'PRECIO', '')::DOUBLE PRECISION, 0),
        COALESCE(NULLIF(elem->>'PRECIO_DESCUENTO', '')::DOUBLE PRECISION, 0),
        COALESCE(NULLIF(elem->>'ALICUOTA', '')::DOUBLE PRECISION, 0),
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
                NULLIF(v_row->>'TIPO_PAGO', ''),
                NULLIF(v_row->>'BANCO', ''),
                NULLIF(v_row->>'NUMERO', ''),
                COALESCE(NULLIF(v_row->>'MONTO', '')::DOUBLE PRECISION, 0),
                COALESCE(NULLIF(v_row->>'TASA_CAMBIO', '')::DOUBLE PRECISION, v_tasa_cambio),
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
$$;
