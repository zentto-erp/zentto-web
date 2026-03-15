-- ============================================================
-- DatqBoxWeb PostgreSQL - sp_anular_compra_tx.sql
-- Anulacion de compra con reversion de inventario y CxP
-- ============================================================

-- =============================================
-- Funcion: sp_anular_compra_tx
-- Descripcion: Anula una compra revertiendo inventario y CxP
-- Traducido de: web/api/sqlweb/includes/sp/sp_anular_compra_tx.sql
-- Compatible con: PostgreSQL 14+
-- DEPRECATED: Usa tablas legacy (Compras, Detalle_Compras, P_Pagar, MovInvent)
-- =============================================

DROP FUNCTION IF EXISTS sp_anular_compra_tx(VARCHAR, VARCHAR, VARCHAR);

CREATE OR REPLACE FUNCTION sp_anular_compra_tx(
    p_num_fact     VARCHAR(60),
    p_cod_usuario  VARCHAR(60) DEFAULT 'API',
    p_motivo       VARCHAR(500) DEFAULT ''
)
RETURNS TABLE (
    "ok"            BOOLEAN,
    "numFact"       VARCHAR,
    "codProveedor"  VARCHAR,
    "mensaje"       TEXT
)
LANGUAGE plpgsql
AS $$
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
$$;
