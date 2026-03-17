-- =============================================
-- Funcion: Anular Presupuesto (revertir inventario y CxC tipo PRESUP)
-- Traducido de SQL Server a PostgreSQL
-- DEPRECATED: Usa tablas legacy
-- =============================================

DROP FUNCTION IF EXISTS sp_anular_presupuesto_tx(VARCHAR(60), VARCHAR(60), VARCHAR(500)) CASCADE;
CREATE OR REPLACE FUNCTION sp_anular_presupuesto_tx(
    p_num_fact    VARCHAR(60),
    p_cod_usuario VARCHAR(60) DEFAULT 'API',
    p_motivo      VARCHAR(500) DEFAULT ''
)
RETURNS TABLE(
    "ok"         BOOLEAN,
    "numFact"    VARCHAR,
    "codCliente" VARCHAR,
    "mensaje"    VARCHAR
) LANGUAGE plpgsql AS $$
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
$$;
