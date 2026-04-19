-- +goose Up
-- PR2: Trazabilidad de origen en movimientos + vista de compatibilidad de ledgers
-- Objetivo: unificar master.InventoryMovement (legacy) e inv.StockMovement (nuevo)
-- con una vista de lectura común y añadir contexto de origen a los movimientos.

-- =============================================================================
-- 1. Añadir columnas de trazabilidad a master.InventoryMovement (si no existen)
-- =============================================================================
-- +goose StatementBegin
ALTER TABLE master."InventoryMovement"
    ADD COLUMN IF NOT EXISTS "SourceDocumentType" VARCHAR(30),
    ADD COLUMN IF NOT EXISTS "SourceDocumentId"   BIGINT,
    ADD COLUMN IF NOT EXISTS "WarehouseFrom"       VARCHAR(30),
    ADD COLUMN IF NOT EXISTS "WarehouseTo"         VARCHAR(30);
-- +goose StatementEnd

-- +goose StatementBegin
CREATE INDEX IF NOT EXISTS "ix_master_InventoryMovement_SourceDocumentType"
    ON master."InventoryMovement" ("CompanyId", "SourceDocumentType", "SourceDocumentId");
-- +goose StatementEnd

-- =============================================================================
-- 2. Actualizar usp_inventario_movimiento_insert — añade source tracking + warehouses
-- =============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_inventario_movimiento_insert(
    p_company_id            INTEGER,
    p_product_code          VARCHAR    DEFAULT NULL,
    p_movement_type         VARCHAR    DEFAULT 'ENTRADA',
    p_quantity              NUMERIC    DEFAULT 0,
    p_unit_cost             NUMERIC    DEFAULT 0,
    p_document_ref          VARCHAR    DEFAULT NULL,
    p_warehouse_from        VARCHAR    DEFAULT NULL,
    p_warehouse_to          VARCHAR    DEFAULT NULL,
    p_notes                 VARCHAR    DEFAULT NULL,
    p_user_id               INTEGER    DEFAULT NULL,
    p_source_document_type  VARCHAR(30) DEFAULT NULL,
    p_source_document_id    BIGINT     DEFAULT NULL
) RETURNS TABLE("Resultado" INTEGER, "Mensaje" VARCHAR)
LANGUAGE plpgsql AS $$
DECLARE
    v_product_name VARCHAR(250);
BEGIN
    IF p_product_code IS NULL OR TRIM(p_product_code) = '' THEN
        RETURN QUERY SELECT -1, 'ProductCode requerido'::VARCHAR;
        RETURN;
    END IF;

    IF p_company_id IS NULL OR p_company_id <= 0 THEN
        RETURN QUERY SELECT -2, 'CompanyId requerido'::VARCHAR;
        RETURN;
    END IF;

    SELECT "ProductName" INTO v_product_name
    FROM master."Product"
    WHERE "ProductCode" = p_product_code AND "CompanyId" = p_company_id
    LIMIT 1;

    INSERT INTO master."InventoryMovement" (
        "CompanyId", "ProductCode", "ProductName",
        "MovementType", "Quantity", "UnitCost", "TotalCost",
        "DocumentRef", "Notes", "CreatedByUserId",
        "SourceDocumentType", "SourceDocumentId",
        "WarehouseFrom", "WarehouseTo"
    ) VALUES (
        p_company_id,
        p_product_code,
        COALESCE(v_product_name, p_product_code),
        COALESCE(NULLIF(p_movement_type, ''), 'ENTRADA'),
        COALESCE(p_quantity, 0),
        COALESCE(p_unit_cost, 0),
        COALESCE(p_quantity, 0) * COALESCE(p_unit_cost, 0),
        NULLIF(p_document_ref, ''),
        NULLIF(p_notes, ''),
        p_user_id,
        NULLIF(p_source_document_type, ''),
        p_source_document_id,
        NULLIF(p_warehouse_from, ''),
        NULLIF(p_warehouse_to, '')
    );

    -- Update denormalized stock on master.Product
    IF p_movement_type IN ('ENTRADA', 'AJUSTE_POSITIVO') THEN
        UPDATE master."Product"
        SET "StockQty" = COALESCE("StockQty", 0) + p_quantity
        WHERE "ProductCode" = p_product_code AND "CompanyId" = p_company_id;
    ELSIF p_movement_type IN ('SALIDA', 'AJUSTE_NEGATIVO') THEN
        UPDATE master."Product"
        SET "StockQty" = GREATEST(COALESCE("StockQty", 0) - p_quantity, 0)
        WHERE "ProductCode" = p_product_code AND "CompanyId" = p_company_id;
    END IF;

    RETURN QUERY SELECT 1, 'OK'::VARCHAR;

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, SQLERRM::VARCHAR;
END;
$$;
-- +goose StatementEnd

-- =============================================================================
-- 3. Vista de compatibilidad: unifica ambos ledgers en columnas normalizadas
-- =============================================================================
-- +goose StatementBegin
CREATE OR REPLACE VIEW inv.v_movement_compat AS
-- Ledger legacy (master.InventoryMovement)
SELECT
    'LEGACY'::VARCHAR(10)                              AS "LedgerSource",
    m."MovementId",
    m."CompanyId",
    COALESCE(m."BranchId", 1)                         AS "BranchId",
    NULL::BIGINT                                       AS "ProductId",
    m."ProductCode",
    m."ProductName",
    CASE m."MovementType"
        WHEN 'ENTRADA'        THEN 'PURCHASE_IN'
        WHEN 'SALIDA'         THEN 'SALE_OUT'
        WHEN 'TRASLADO'       THEN 'TRANSFER'
        WHEN 'AJUSTE'         THEN 'ADJUSTMENT'
        WHEN 'AJUSTE_POSITIVO'THEN 'ADJUSTMENT'
        WHEN 'AJUSTE_NEGATIVO'THEN 'ADJUSTMENT'
        ELSE m."MovementType"
    END::VARCHAR(30)                                   AS "MovementTypeNorm",
    m."MovementType"                                   AS "MovementTypeRaw",
    m."Quantity",
    m."UnitCost",
    m."TotalCost",
    m."WarehouseFrom",
    m."WarehouseTo",
    m."SourceDocumentType",
    m."SourceDocumentId"::VARCHAR(60)                  AS "SourceDocumentRef",
    m."DocumentRef",
    m."Notes",
    m."MovementDate"::TIMESTAMP                        AS "MovementDate",
    m."CreatedByUserId",
    m."CreatedAt"
FROM master."InventoryMovement" m
WHERE COALESCE(m."IsDeleted", FALSE) = FALSE

UNION ALL

-- Ledger nuevo (inv.StockMovement)
SELECT
    'ADVANCED'::VARCHAR(10)                            AS "LedgerSource",
    sm."MovementId",
    sm."CompanyId",
    sm."BranchId",
    sm."ProductId",
    p."ProductCode",
    p."ProductName",
    sm."MovementType"                                  AS "MovementTypeNorm",
    sm."MovementType"                                  AS "MovementTypeRaw",
    sm."Quantity",
    sm."UnitCost",
    sm."TotalCost",
    wf."WarehouseCode"                                 AS "WarehouseFrom",
    wt."WarehouseCode"                                 AS "WarehouseTo",
    sm."SourceDocumentType",
    sm."SourceDocumentNumber"                          AS "SourceDocumentRef",
    sm."SourceDocumentNumber"                          AS "DocumentRef",
    sm."Notes",
    sm."MovementDate",
    sm."CreatedByUserId",
    sm."CreatedAt"
FROM inv."StockMovement" sm
LEFT JOIN master."Product"   p  ON p."ProductId"   = sm."ProductId"
LEFT JOIN inv."Warehouse"    wf ON wf."WarehouseId" = sm."FromWarehouseId"
LEFT JOIN inv."Warehouse"    wt ON wt."WarehouseId" = sm."ToWarehouseId";
-- +goose StatementEnd

-- =============================================================================
-- 4. SP para trazabilidad de un artículo: kardex detallado con origen
-- =============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_inventario_kardex_detallado(
    p_company_id   INTEGER,
    p_product_code VARCHAR,
    p_fecha_desde  DATE    DEFAULT NULL,
    p_fecha_hasta  DATE    DEFAULT NULL,
    p_page         INTEGER DEFAULT 1,
    p_limit        INTEGER DEFAULT 100
) RETURNS TABLE(
    "TotalCount"         BIGINT,
    "MovementId"         BIGINT,
    "LedgerSource"       VARCHAR,
    "MovementDate"       TIMESTAMP,
    "MovementTypeNorm"   VARCHAR,
    "MovementTypeRaw"    VARCHAR,
    "Quantity"           NUMERIC,
    "UnitCost"           NUMERIC,
    "TotalCost"          NUMERIC,
    "SaldoAcumulado"     NUMERIC,
    "WarehouseFrom"      VARCHAR,
    "WarehouseTo"        VARCHAR,
    "SourceDocumentType" VARCHAR,
    "SourceDocumentRef"  VARCHAR,
    "DocumentRef"        VARCHAR,
    "Notes"              VARCHAR,
    "CreatedByUserId"    INTEGER
) LANGUAGE plpgsql AS $$
DECLARE
    v_offset INT;
    v_limit  INT;
    v_total  BIGINT;
BEGIN
    v_limit  := LEAST(GREATEST(COALESCE(NULLIF(p_limit, 0), 100), 1), 500);
    v_offset := (GREATEST(COALESCE(NULLIF(p_page, 0), 1), 1) - 1) * v_limit;

    SELECT COUNT(1) INTO v_total
    FROM inv.v_movement_compat vc
    WHERE vc."CompanyId"   = p_company_id
      AND vc."ProductCode" = p_product_code
      AND (p_fecha_desde IS NULL OR vc."MovementDate"::DATE >= p_fecha_desde)
      AND (p_fecha_hasta IS NULL OR vc."MovementDate"::DATE <= p_fecha_hasta);

    RETURN QUERY
    WITH ordered AS (
        SELECT vc.*, ROW_NUMBER() OVER (ORDER BY vc."MovementDate", vc."MovementId") AS rn
        FROM inv.v_movement_compat vc
        WHERE vc."CompanyId"   = p_company_id
          AND vc."ProductCode" = p_product_code
          AND (p_fecha_desde IS NULL OR vc."MovementDate"::DATE >= p_fecha_desde)
          AND (p_fecha_hasta IS NULL OR vc."MovementDate"::DATE <= p_fecha_hasta)
    ),
    with_balance AS (
        SELECT o.*,
               SUM(
                 CASE o."MovementTypeNorm"
                   WHEN 'PURCHASE_IN'    THEN o."Quantity"
                   WHEN 'RETURN_IN'      THEN o."Quantity"
                   WHEN 'PRODUCTION_IN'  THEN o."Quantity"
                   WHEN 'SALE_OUT'       THEN -o."Quantity"
                   WHEN 'RETURN_OUT'     THEN -o."Quantity"
                   WHEN 'PRODUCTION_OUT' THEN -o."Quantity"
                   WHEN 'SCRAP'          THEN -o."Quantity"
                   WHEN 'TRANSFER'       THEN 0
                   WHEN 'ADJUSTMENT'     THEN o."Quantity" -- puede ser + o -
                   ELSE 0
                 END
               ) OVER (ORDER BY o."MovementDate", o."MovementId") AS "SaldoAcumulado"
        FROM ordered o
    )
    SELECT
        v_total,
        wb."MovementId",
        wb."LedgerSource",
        wb."MovementDate",
        wb."MovementTypeNorm",
        wb."MovementTypeRaw",
        wb."Quantity",
        wb."UnitCost",
        wb."TotalCost",
        wb."SaldoAcumulado",
        wb."WarehouseFrom",
        wb."WarehouseTo",
        wb."SourceDocumentType",
        wb."SourceDocumentRef",
        wb."DocumentRef",
        wb."Notes",
        wb."CreatedByUserId"
    FROM with_balance wb
    WHERE wb.rn > v_offset AND wb.rn <= v_offset + v_limit
    ORDER BY wb."MovementDate", wb."MovementId";
END;
$$;
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
DROP FUNCTION IF EXISTS public.usp_inventario_kardex_detallado(INTEGER, VARCHAR, DATE, DATE, INTEGER, INTEGER);
DROP VIEW IF EXISTS inv.v_movement_compat;
ALTER TABLE master."InventoryMovement"
    DROP COLUMN IF EXISTS "SourceDocumentType",
    DROP COLUMN IF EXISTS "SourceDocumentId",
    DROP COLUMN IF EXISTS "WarehouseFrom",
    DROP COLUMN IF EXISTS "WarehouseTo";
-- +goose StatementEnd
