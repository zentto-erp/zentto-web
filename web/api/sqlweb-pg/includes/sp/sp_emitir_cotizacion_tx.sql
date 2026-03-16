-- =============================================
-- Funcion: Emitir Cotizacion (Transaccional) - PostgreSQL
-- Descripcion: Emite una cotizacion con detalle (sin inventario)
-- Traducido de SQL Server a PostgreSQL
-- =============================================

DROP FUNCTION IF EXISTS sp_emitir_cotizacion_tx(JSONB, JSONB, VARCHAR);

CREATE OR REPLACE FUNCTION sp_emitir_cotizacion_tx(
    p_cotizacion_json  JSONB,
    p_detalle_json     JSONB,
    p_cod_usuario      VARCHAR(60) DEFAULT 'API'
)
RETURNS TABLE (
    "ok"           BOOLEAN,
    "numFact"      VARCHAR(60),
    "detalleRows"  INT
)
LANGUAGE plpgsql AS $$
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
    v_nombre      := COALESCE(NULLIF(TRIM(p_cotizacion_json->>'NOMBRE'), ''), '');
    v_serial_tipo := COALESCE(NULLIF(TRIM(p_cotizacion_json->>'SERIALTIPO'), ''), '');

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
        COALESCE(NULLIF(TRIM(d->>'SERIALTIPO'), ''), v_serial_tipo),
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
        COALESCE(NULLIF(TRIM(d->>'Relacionada'), ''), '0'),
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
$$;
