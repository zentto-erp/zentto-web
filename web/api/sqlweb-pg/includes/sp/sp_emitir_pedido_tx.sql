-- =============================================
-- Funcion: Emitir Pedido (Transaccional) - PostgreSQL
-- Descripcion:
--   - Emite un pedido comprometiendo inventario
--   - Si se factura despues, NO vuelve a descontar inventario
--   - Si se anula, reversa el inventario
-- Traducido de SQL Server a PostgreSQL
-- =============================================

-- =============================================
-- 1. sp_emitir_pedido_tx
-- =============================================
DROP FUNCTION IF EXISTS sp_emitir_pedido_tx(JSONB, JSONB, BOOLEAN, VARCHAR);

CREATE OR REPLACE FUNCTION sp_emitir_pedido_tx(
    p_pedido_json   JSONB,
    p_detalle_json  JSONB,
    p_actualizar_inventario BOOLEAN DEFAULT TRUE,
    p_cod_usuario   VARCHAR(60) DEFAULT 'API'
)
RETURNS TABLE (
    "ok"                BOOLEAN,
    "numPedido"         VARCHAR(60),
    "detalleRows"       INT,
    "inventoryUpdated"  BOOLEAN
)
LANGUAGE plpgsql AS $$
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
    v_nombre      := COALESCE(NULLIF(TRIM(p_pedido_json->>'NOMBRE'), ''), '');
    v_serial_tipo := COALESCE(NULLIF(TRIM(p_pedido_json->>'SERIALTIPO'), ''), '');
    v_vendedor    := COALESCE(NULLIF(TRIM(p_pedido_json->>'Vendedor'), ''), '');

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
        COALESCE(NULLIF(TRIM(d->>'Vendedor'), ''), v_vendedor),
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
$$;


-- =============================================
-- 2. sp_anular_pedido_tx
-- =============================================
DROP FUNCTION IF EXISTS sp_anular_pedido_tx(VARCHAR, VARCHAR, VARCHAR);

CREATE OR REPLACE FUNCTION sp_anular_pedido_tx(
    p_num_pedido   VARCHAR(60),
    p_cod_usuario  VARCHAR(60) DEFAULT 'API',
    p_motivo       VARCHAR(500) DEFAULT ''
)
RETURNS TABLE (
    "ok"         BOOLEAN,
    "numPedido"  VARCHAR(60),
    "mensaje"    VARCHAR(100)
)
LANGUAGE plpgsql AS $$
DECLARE
    v_fecha_anulacion TIMESTAMP := NOW() AT TIME ZONE 'UTC';
    v_ya_anulado      BOOLEAN;
BEGIN
    -- Verificar existencia y estado (tabla legacy "Pedidos")
    SELECT CASE WHEN "ANULADA"::TEXT = '1' OR "ANULADA"::INT = 1 THEN TRUE ELSE FALSE END
      INTO v_ya_anulado
      FROM "Pedidos" WHERE "NUM_FACT" = p_num_pedido;

    IF v_ya_anulado IS NULL THEN
        RAISE EXCEPTION 'pedido_not_found';
    END IF;

    IF v_ya_anulado THEN
        RAISE EXCEPTION 'pedido_already_anulled';
    END IF;

    -- Marcar pedido como anulado (legacy)
    UPDATE "Pedidos"
       SET "ANULADA" = 1,
           "OBSERV" = COALESCE("OBSERV", '') || ' [ANULADO: ' || TO_CHAR(v_fecha_anulacion, 'YYYY-MM-DD HH24:MI:SS') || ']'
     WHERE "NUM_FACT" = p_num_pedido;

    UPDATE "Detalle_Pedidos" SET "ANULADA" = 1 WHERE "NUM_FACT" = p_num_pedido;

    -- Reversar inventario en master."Product"
    INSERT INTO "MovInvent" ("DOCUMENTO", "CODIGO", "PRODUCT", "FECHA", "MOTIVO", "TIPO", "CANTIDAD_ACTUAL", "CANTIDAD", "CANTIDAD_NUEVA", "CO_USUARIO")
    SELECT
        p_num_pedido || '_ANUL',
        dp."COD_SERV",
        dp."COD_SERV",
        v_fecha_anulacion,
        'Anulacion Pedido:' || p_num_pedido,
        'Anulacion Pedido',
        COALESCE(inv."StockQty", 0),
        COALESCE(dp."CANTIDAD", 0),
        COALESCE(inv."StockQty", 0) + COALESCE(dp."CANTIDAD", 0),
        p_cod_usuario
    FROM "Detalle_Pedidos" dp
    INNER JOIN master."Product" inv ON inv."ProductCode" = dp."COD_SERV"
    WHERE dp."NUM_FACT" = p_num_pedido
      AND COALESCE(dp."ANULADA", 0) = 0
      AND dp."COD_SERV" IS NOT NULL
      AND COALESCE(dp."CANTIDAD", 0) > 0;

    -- Sumar de vuelta al inventario
    UPDATE master."Product" AS p
       SET "StockQty" = COALESCE(p."StockQty", 0) + agg."Total"
      FROM (
          SELECT dp."COD_SERV" AS cod_serv, SUM(COALESCE(dp."CANTIDAD", 0)) AS "Total"
            FROM "Detalle_Pedidos" dp
           WHERE dp."NUM_FACT" = p_num_pedido
             AND COALESCE(dp."ANULADA", 0) = 0
             AND dp."COD_SERV" IS NOT NULL
           GROUP BY dp."COD_SERV"
      ) agg
     WHERE p."ProductCode" = agg.cod_serv;

    RETURN QUERY SELECT TRUE AS "ok", p_num_pedido AS "numPedido", 'Pedido anulado'::VARCHAR(100) AS "mensaje";

EXCEPTION WHEN OTHERS THEN
    RAISE EXCEPTION '%', SQLERRM;
END;
$$;
