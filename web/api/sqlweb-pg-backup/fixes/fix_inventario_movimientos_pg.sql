-- ============================================================
-- FIX: inventario movimientos functions
-- master."InventoryMovement" columns:
--   MovementId, CompanyId, BranchId, ProductCode, ProductName,
--   DocumentRef, MovementType, MovementDate, Quantity, UnitCost,
--   TotalCost, Notes, IsDeleted, CreatedAt, UpdatedAt,
--   CreatedByUserId, UpdatedByUserId
-- Note: NO WarehouseFrom, WarehouseTo columns
-- ============================================================

-- ---------- usp_inventario_movimiento_list ----------
DROP FUNCTION IF EXISTS usp_inventario_movimiento_list(INT, VARCHAR, VARCHAR, VARCHAR, VARCHAR, DATE, DATE, INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_inventario_movimiento_list(
    p_company_id    INT          DEFAULT 1,
    p_search        VARCHAR(100) DEFAULT NULL,
    p_product_code  VARCHAR(80)  DEFAULT NULL,
    p_movement_type VARCHAR(20)  DEFAULT NULL,
    p_warehouse_code VARCHAR(20) DEFAULT NULL,
    p_fecha_desde   DATE         DEFAULT NULL,
    p_fecha_hasta   DATE         DEFAULT NULL,
    p_page          INT          DEFAULT 1,
    p_limit         INT          DEFAULT 50
)
RETURNS TABLE(
    "TotalCount"      BIGINT,
    "MovementId"      BIGINT,
    "ProductCode"     VARCHAR,
    "ProductName"     VARCHAR,
    "MovementType"    VARCHAR,
    "MovementDate"    DATE,
    "Quantity"        NUMERIC,
    "UnitCost"        NUMERIC,
    "TotalCost"       NUMERIC,
    "DocumentRef"     VARCHAR,
    "WarehouseFrom"   VARCHAR,
    "WarehouseTo"     VARCHAR,
    "Notes"           VARCHAR,
    "CreatedAt"       TIMESTAMP,
    "CreatedByUserId" INT
)
LANGUAGE plpgsql AS $$
DECLARE
    v_offset INT;
    v_limit  INT;
    v_total  BIGINT;
BEGIN
    v_limit  := COALESCE(NULLIF(p_limit, 0), 50);
    IF v_limit < 1  THEN v_limit := 50;  END IF;
    IF v_limit > 500 THEN v_limit := 500; END IF;

    v_offset := (COALESCE(NULLIF(p_page, 0), 1) - 1) * v_limit;
    IF v_offset < 0 THEN v_offset := 0; END IF;

    SELECT COUNT(1) INTO v_total
    FROM master."InventoryMovement" m
    WHERE m."CompanyId" = p_company_id
      AND COALESCE(m."IsDeleted", FALSE) = FALSE
      AND (p_search IS NULL OR m."ProductCode" ILIKE '%' || p_search || '%'
           OR COALESCE(m."ProductName",'') ILIKE '%' || p_search || '%'
           OR COALESCE(m."DocumentRef",'') ILIKE '%' || p_search || '%')
      AND (p_product_code IS NULL OR m."ProductCode" = p_product_code)
      AND (p_movement_type IS NULL OR m."MovementType" = p_movement_type)
      AND (p_fecha_desde IS NULL OR m."MovementDate" >= p_fecha_desde)
      AND (p_fecha_hasta IS NULL OR m."MovementDate" <= p_fecha_hasta);

    RETURN QUERY
    SELECT
        v_total,
        m."MovementId",
        m."ProductCode"::VARCHAR,
        COALESCE(m."ProductName",'')::VARCHAR,
        m."MovementType"::VARCHAR,
        m."MovementDate",
        m."Quantity",
        m."UnitCost",
        m."TotalCost",
        COALESCE(m."DocumentRef",'')::VARCHAR AS "DocumentRef",
        NULL::VARCHAR                         AS "WarehouseFrom",
        NULL::VARCHAR                         AS "WarehouseTo",
        COALESCE(m."Notes",'')::VARCHAR       AS "Notes",
        m."CreatedAt",
        m."CreatedByUserId"
    FROM master."InventoryMovement" m
    WHERE m."CompanyId" = p_company_id
      AND COALESCE(m."IsDeleted", FALSE) = FALSE
      AND (p_search IS NULL OR m."ProductCode" ILIKE '%' || p_search || '%'
           OR COALESCE(m."ProductName",'') ILIKE '%' || p_search || '%'
           OR COALESCE(m."DocumentRef",'') ILIKE '%' || p_search || '%')
      AND (p_product_code IS NULL OR m."ProductCode" = p_product_code)
      AND (p_movement_type IS NULL OR m."MovementType" = p_movement_type)
      AND (p_fecha_desde IS NULL OR m."MovementDate" >= p_fecha_desde)
      AND (p_fecha_hasta IS NULL OR m."MovementDate" <= p_fecha_hasta)
    ORDER BY m."CreatedAt" DESC
    LIMIT v_limit OFFSET v_offset;
END;
$$;

-- ---------- usp_inventario_movimiento_insert ----------
DROP FUNCTION IF EXISTS usp_inventario_movimiento_insert(INT, VARCHAR, VARCHAR, NUMERIC, NUMERIC, VARCHAR, VARCHAR, VARCHAR, VARCHAR, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_inventario_movimiento_insert(
    p_company_id    INT          DEFAULT 1,
    p_product_code  VARCHAR(80)  DEFAULT NULL,
    p_movement_type VARCHAR(20)  DEFAULT 'ENTRADA',
    p_quantity      NUMERIC      DEFAULT 0,
    p_unit_cost     NUMERIC      DEFAULT 0,
    p_document_ref  VARCHAR(60)  DEFAULT NULL,
    p_warehouse_from VARCHAR(20) DEFAULT NULL,
    p_warehouse_to  VARCHAR(20)  DEFAULT NULL,
    p_notes         VARCHAR(300) DEFAULT NULL,
    p_user_id       INT          DEFAULT NULL
)
RETURNS TABLE(
    "Resultado" INT,
    "Mensaje"   VARCHAR(500)
)
LANGUAGE plpgsql AS $$
DECLARE
    v_product_name VARCHAR(250);
BEGIN
    IF p_product_code IS NULL OR TRIM(p_product_code) = '' THEN
        RETURN QUERY SELECT -1, 'ProductCode requerido'::VARCHAR(500);
        RETURN;
    END IF;

    -- Get product name for denormalization
    SELECT "ProductName" INTO v_product_name
    FROM master."Product"
    WHERE "ProductCode" = p_product_code AND "CompanyId" = p_company_id
    LIMIT 1;

    INSERT INTO master."InventoryMovement" (
        "CompanyId", "ProductCode", "ProductName",
        "MovementType", "Quantity", "UnitCost", "TotalCost",
        "DocumentRef", "Notes", "CreatedByUserId"
    )
    VALUES (
        p_company_id,
        p_product_code,
        COALESCE(v_product_name, p_product_code),
        COALESCE(NULLIF(p_movement_type,''), 'ENTRADA'),
        COALESCE(p_quantity, 0),
        COALESCE(p_unit_cost, 0),
        COALESCE(p_quantity, 0) * COALESCE(p_unit_cost, 0),
        NULLIF(p_document_ref,''),
        NULLIF(p_notes,''),
        p_user_id
    );

    -- Update stock
    IF p_movement_type IN ('ENTRADA', 'AJUSTE_POSITIVO') THEN
        UPDATE master."Product" SET "StockQty" = "StockQty" + p_quantity
        WHERE "ProductCode" = p_product_code AND "CompanyId" = p_company_id;
    ELSIF p_movement_type IN ('SALIDA', 'AJUSTE_NEGATIVO') THEN
        UPDATE master."Product" SET "StockQty" = GREATEST("StockQty" - p_quantity, 0)
        WHERE "ProductCode" = p_product_code AND "CompanyId" = p_company_id;
    END IF;

    RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
END;
$$;
