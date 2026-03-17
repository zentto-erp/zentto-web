-- =============================================
-- Funcion: Anular Pedido (Transaccional)
-- Descripcion: Anula un pedido y reversa el inventario comprometido
-- Traducido de SQL Server a PostgreSQL
-- =============================================

DROP FUNCTION IF EXISTS sp_anular_pedido_tx(VARCHAR(60), VARCHAR(60), VARCHAR(500)) CASCADE;
CREATE OR REPLACE FUNCTION sp_anular_pedido_tx(
    p_num_pedido  VARCHAR(60),
    p_cod_usuario VARCHAR(60) DEFAULT 'API',
    p_motivo      VARCHAR(500) DEFAULT ''
)
RETURNS TABLE(
    "ok"         BOOLEAN,
    "numPedido"  VARCHAR,
    "mensaje"    VARCHAR
) LANGUAGE plpgsql AS $$
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
$$;
