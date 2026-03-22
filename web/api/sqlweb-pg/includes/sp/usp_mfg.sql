-- ============================================================
-- DatqBoxWeb PostgreSQL - usp_mfg.sql
-- Funciones del modulo MFG (Manufacturing / Manufactura)
-- Fecha: 2026-03-22
-- ============================================================

-- =============================================================================
--  usp_Mfg_BOM_List
-- =============================================================================
DROP FUNCTION IF EXISTS usp_mfg_bom_list(INT, VARCHAR, VARCHAR, INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_mfg_bom_list(
    p_company_id INT,
    p_status     VARCHAR(20) DEFAULT NULL,
    p_search     VARCHAR(200) DEFAULT NULL,
    p_page       INT DEFAULT 1,
    p_limit      INT DEFAULT 50
)
RETURNS TABLE(
    "BOMId"            INT,
    "BOMCode"          VARCHAR,
    "BOMName"          VARCHAR,
    "ProductId"        INT,
    "ExpectedQuantity" NUMERIC,
    "Status"           VARCHAR,
    "CreatedAt"        TIMESTAMP,
    "UpdatedAt"        TIMESTAMP,
    "LineCount"        BIGINT,
    "TotalCount"       BIGINT
)
LANGUAGE plpgsql AS $$
DECLARE
    v_total BIGINT;
BEGIN
    SELECT COUNT(*) INTO v_total
    FROM   mfg."BillOfMaterials" b
    WHERE  b."CompanyId" = p_company_id
      AND  (p_status IS NULL OR b."Status" = p_status)
      AND  (p_search IS NULL OR b."BOMCode" ILIKE '%' || p_search || '%'
                             OR b."BOMName" ILIKE '%' || p_search || '%');

    RETURN QUERY
    SELECT
        b."BOMId", b."BOMCode", b."BOMName",
        b."ProductId", b."ExpectedQuantity",
        b."Status", b."CreatedAt", b."UpdatedAt",
        (SELECT COUNT(*) FROM mfg."BOMLine" bl WHERE bl."BOMId" = b."BOMId"),
        v_total
    FROM   mfg."BillOfMaterials" b
    WHERE  b."CompanyId" = p_company_id
      AND  (p_status IS NULL OR b."Status" = p_status)
      AND  (p_search IS NULL OR b."BOMCode" ILIKE '%' || p_search || '%'
                             OR b."BOMName" ILIKE '%' || p_search || '%')
    ORDER BY b."CreatedAt" DESC
    LIMIT p_limit OFFSET (p_page - 1) * p_limit;
END;
$$;

-- =============================================================================
--  usp_Mfg_BOM_Get
-- =============================================================================
DROP FUNCTION IF EXISTS usp_mfg_bom_get(INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_mfg_bom_get(
    p_bom_id INT
)
RETURNS TABLE(
    "BOMId"            INT,
    "BOMCode"          VARCHAR,
    "BOMName"          VARCHAR,
    "CompanyId"        INT,
    "ProductId"        INT,
    "ExpectedQuantity" NUMERIC,
    "Status"           VARCHAR,
    "CreatedAt"        TIMESTAMP,
    "UpdatedAt"        TIMESTAMP,
    "_section"         VARCHAR
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        b."BOMId", b."BOMCode", b."BOMName", b."CompanyId",
        b."ProductId", b."ExpectedQuantity",
        b."Status", b."CreatedAt", b."UpdatedAt",
        'header'::VARCHAR
    FROM mfg."BillOfMaterials" b
    WHERE b."BOMId" = p_bom_id;
END;
$$;

-- =============================================================================
--  usp_Mfg_BOM_Create
-- =============================================================================
DROP FUNCTION IF EXISTS usp_mfg_bom_create(INT, INT, VARCHAR, VARCHAR, NUMERIC, TEXT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_mfg_bom_create(
    p_company_id        INT,
    p_product_id        INT,
    p_bom_code          VARCHAR(30),
    p_bom_name          VARCHAR(200),
    p_expected_quantity NUMERIC(18,4) DEFAULT 1,
    p_lines_json        TEXT DEFAULT NULL,
    p_user_id           INT DEFAULT NULL
)
RETURNS TABLE("ok" INT, "mensaje" VARCHAR, "BOMId" INT)
LANGUAGE plpgsql AS $$
DECLARE
    v_id  INT;
    v_line RECORD;
BEGIN
    IF EXISTS (SELECT 1 FROM mfg."BillOfMaterials" WHERE "CompanyId" = p_company_id AND "BOMCode" = p_bom_code) THEN
        RETURN QUERY SELECT 0, ('Ya existe un BOM con el codigo ' || p_bom_code)::VARCHAR, 0;
        RETURN;
    END IF;

    INSERT INTO mfg."BillOfMaterials" (
        "CompanyId", "ProductId", "BOMCode", "BOMName",
        "ExpectedQuantity", "Status",
        "CreatedByUserId", "UpdatedByUserId", "CreatedAt", "UpdatedAt"
    ) VALUES (
        p_company_id, p_product_id, p_bom_code, p_bom_name,
        p_expected_quantity, 'DRAFT',
        p_user_id, p_user_id, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'
    ) RETURNING "BOMId" INTO v_id;

    IF p_lines_json IS NOT NULL AND LENGTH(p_lines_json) > 2 THEN
        FOR v_line IN SELECT * FROM jsonb_array_elements(p_lines_json::JSONB)
        LOOP
            INSERT INTO mfg."BOMLine" ("BOMId", "ProductId", "Quantity", "UnitOfMeasure", "Sequence", "ScrapPercent", "Notes")
            VALUES (
                v_id,
                (v_line.value->>'ProductId')::INT,
                (v_line.value->>'Quantity')::NUMERIC(18,4),
                v_line.value->>'UnitOfMeasure',
                (v_line.value->>'Sequence')::INT,
                COALESCE((v_line.value->>'ScrapPercent')::NUMERIC(5,2), 0),
                v_line.value->>'Notes'
            );
        END LOOP;
    END IF;

    RETURN QUERY SELECT 1, 'OK'::VARCHAR, v_id;

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT 0, SQLERRM::VARCHAR, 0;
END;
$$;

-- =============================================================================
--  usp_Mfg_BOM_Activate
-- =============================================================================
DROP FUNCTION IF EXISTS usp_mfg_bom_activate(INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_mfg_bom_activate(
    p_bom_id  INT,
    p_user_id INT DEFAULT NULL
)
RETURNS TABLE("ok" INT, "mensaje" VARCHAR)
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE mfg."BillOfMaterials"
    SET    "Status" = 'ACTIVE', "UpdatedByUserId" = p_user_id, "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
    WHERE  "BOMId" = p_bom_id;

    RETURN QUERY SELECT 1, 'OK'::VARCHAR;

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT 0, SQLERRM::VARCHAR;
END;
$$;

-- =============================================================================
--  usp_Mfg_BOM_Obsolete
-- =============================================================================
DROP FUNCTION IF EXISTS usp_mfg_bom_obsolete(INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_mfg_bom_obsolete(
    p_bom_id  INT,
    p_user_id INT DEFAULT NULL
)
RETURNS TABLE("ok" INT, "mensaje" VARCHAR)
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE mfg."BillOfMaterials"
    SET    "Status" = 'OBSOLETE', "UpdatedByUserId" = p_user_id, "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
    WHERE  "BOMId" = p_bom_id;

    RETURN QUERY SELECT 1, 'OK'::VARCHAR;

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT 0, SQLERRM::VARCHAR;
END;
$$;

-- =============================================================================
--  usp_Mfg_WorkCenter_List
-- =============================================================================
DROP FUNCTION IF EXISTS usp_mfg_workcenter_list(INT, VARCHAR, INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_mfg_workcenter_list(
    p_company_id INT,
    p_search     VARCHAR(200) DEFAULT NULL,
    p_page       INT DEFAULT 1,
    p_limit      INT DEFAULT 50
)
RETURNS TABLE(
    "WorkCenterId"   INT,
    "WorkCenterCode" VARCHAR,
    "WorkCenterName" VARCHAR,
    "CostPerHour"    NUMERIC,
    "Capacity"       INT,
    "IsActive"       BOOLEAN,
    "CreatedAt"      TIMESTAMP,
    "UpdatedAt"      TIMESTAMP,
    "TotalCount"     BIGINT
)
LANGUAGE plpgsql AS $$
DECLARE
    v_total BIGINT;
BEGIN
    SELECT COUNT(*) INTO v_total
    FROM   mfg."WorkCenter" w
    WHERE  w."CompanyId" = p_company_id
      AND  (p_search IS NULL OR w."WorkCenterCode" ILIKE '%' || p_search || '%'
                             OR w."WorkCenterName" ILIKE '%' || p_search || '%');

    RETURN QUERY
    SELECT
        w."WorkCenterId", w."WorkCenterCode", w."WorkCenterName",
        w."CostPerHour", w."Capacity", w."IsActive",
        w."CreatedAt", w."UpdatedAt",
        v_total
    FROM   mfg."WorkCenter" w
    WHERE  w."CompanyId" = p_company_id
      AND  (p_search IS NULL OR w."WorkCenterCode" ILIKE '%' || p_search || '%'
                             OR w."WorkCenterName" ILIKE '%' || p_search || '%')
    ORDER BY w."WorkCenterName"
    LIMIT p_limit OFFSET (p_page - 1) * p_limit;
END;
$$;

-- =============================================================================
--  usp_Mfg_WorkCenter_Upsert
-- =============================================================================
DROP FUNCTION IF EXISTS usp_mfg_workcenter_upsert(INT, INT, VARCHAR, VARCHAR, NUMERIC, INT, BOOLEAN, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_mfg_workcenter_upsert(
    p_company_id       INT,
    p_work_center_id   INT DEFAULT NULL,
    p_work_center_code VARCHAR(30) DEFAULT NULL,
    p_work_center_name VARCHAR(120) DEFAULT NULL,
    p_cost_per_hour    NUMERIC(18,2) DEFAULT 0,
    p_capacity         INT DEFAULT 1,
    p_is_active        BOOLEAN DEFAULT TRUE,
    p_user_id          INT DEFAULT NULL
)
RETURNS TABLE("ok" INT, "mensaje" VARCHAR)
LANGUAGE plpgsql AS $$
BEGIN
    IF p_work_center_id IS NULL THEN
        IF EXISTS (SELECT 1 FROM mfg."WorkCenter" WHERE "CompanyId" = p_company_id AND "WorkCenterCode" = p_work_center_code) THEN
            RETURN QUERY SELECT 0, ('Ya existe un centro de trabajo con el codigo ' || p_work_center_code)::VARCHAR;
            RETURN;
        END IF;

        INSERT INTO mfg."WorkCenter" ("CompanyId", "WorkCenterCode", "WorkCenterName", "CostPerHour", "Capacity", "IsActive", "CreatedByUserId", "UpdatedByUserId", "CreatedAt", "UpdatedAt")
        VALUES (p_company_id, p_work_center_code, p_work_center_name, p_cost_per_hour, p_capacity, p_is_active, p_user_id, p_user_id, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC');
    ELSE
        UPDATE mfg."WorkCenter"
        SET    "WorkCenterCode"  = p_work_center_code,
               "WorkCenterName"  = p_work_center_name,
               "CostPerHour"     = p_cost_per_hour,
               "Capacity"        = p_capacity,
               "IsActive"        = p_is_active,
               "UpdatedByUserId" = p_user_id,
               "UpdatedAt"       = NOW() AT TIME ZONE 'UTC'
        WHERE  "WorkCenterId" = p_work_center_id AND "CompanyId" = p_company_id;
    END IF;

    RETURN QUERY SELECT 1, 'OK'::VARCHAR;

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT 0, SQLERRM::VARCHAR;
END;
$$;

-- =============================================================================
--  usp_Mfg_Routing_List
-- =============================================================================
DROP FUNCTION IF EXISTS usp_mfg_routing_list(INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_mfg_routing_list(
    p_bom_id INT
)
RETURNS TABLE(
    "RoutingId"       INT,
    "BOMId"           INT,
    "OperationNumber" INT,
    "WorkCenterId"    INT,
    "WorkCenterName"  VARCHAR,
    "OperationName"   VARCHAR,
    "SetupTime"       NUMERIC,
    "RunTime"         NUMERIC,
    "Description"     VARCHAR
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        r."RoutingId", r."BOMId", r."OperationNumber",
        r."WorkCenterId", wc."WorkCenterName",
        r."OperationName", r."SetupTime", r."RunTime",
        r."Description"
    FROM   mfg."Routing" r
    LEFT JOIN mfg."WorkCenter" wc ON wc."WorkCenterId" = r."WorkCenterId"
    WHERE  r."BOMId" = p_bom_id
    ORDER BY r."OperationNumber";
END;
$$;

-- =============================================================================
--  usp_Mfg_Routing_Upsert
-- =============================================================================
DROP FUNCTION IF EXISTS usp_mfg_routing_upsert(INT, INT, INT, INT, VARCHAR, NUMERIC, NUMERIC, VARCHAR, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_mfg_routing_upsert(
    p_bom_id           INT,
    p_routing_id       INT DEFAULT NULL,
    p_operation_number INT DEFAULT 0,
    p_work_center_id   INT DEFAULT NULL,
    p_operation_name   VARCHAR(200) DEFAULT NULL,
    p_setup_time       NUMERIC(10,2) DEFAULT 0,
    p_run_time         NUMERIC(10,2) DEFAULT 0,
    p_description      VARCHAR(500) DEFAULT NULL,
    p_user_id          INT DEFAULT NULL
)
RETURNS TABLE("ok" INT, "mensaje" VARCHAR)
LANGUAGE plpgsql AS $$
BEGIN
    IF p_routing_id IS NULL THEN
        INSERT INTO mfg."Routing" ("BOMId", "OperationNumber", "WorkCenterId", "OperationName", "SetupTime", "RunTime", "Description", "CreatedByUserId", "UpdatedByUserId", "CreatedAt", "UpdatedAt")
        VALUES (p_bom_id, p_operation_number, p_work_center_id, p_operation_name, p_setup_time, p_run_time, p_description, p_user_id, p_user_id, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC');
    ELSE
        UPDATE mfg."Routing"
        SET    "OperationNumber" = p_operation_number,
               "WorkCenterId"    = p_work_center_id,
               "OperationName"   = p_operation_name,
               "SetupTime"       = p_setup_time,
               "RunTime"         = p_run_time,
               "Description"     = p_description,
               "UpdatedByUserId" = p_user_id,
               "UpdatedAt"       = NOW() AT TIME ZONE 'UTC'
        WHERE  "RoutingId" = p_routing_id AND "BOMId" = p_bom_id;
    END IF;

    RETURN QUERY SELECT 1, 'OK'::VARCHAR;

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT 0, SQLERRM::VARCHAR;
END;
$$;

-- =============================================================================
--  usp_Mfg_WorkOrder_List
-- =============================================================================
DROP FUNCTION IF EXISTS usp_mfg_workorder_list(INT, VARCHAR, TIMESTAMP, TIMESTAMP, INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_mfg_workorder_list(
    p_company_id   INT,
    p_status       VARCHAR(20) DEFAULT NULL,
    p_fecha_desde  TIMESTAMP DEFAULT NULL,
    p_fecha_hasta  TIMESTAMP DEFAULT NULL,
    p_page         INT DEFAULT 1,
    p_limit        INT DEFAULT 50
)
RETURNS TABLE(
    "WorkOrderId"      INT,
    "WorkOrderNumber"  VARCHAR,
    "BOMId"            INT,
    "ProductId"        INT,
    "PlannedQuantity"  NUMERIC,
    "ProducedQuantity" NUMERIC,
    "Status"           VARCHAR,
    "Priority"         VARCHAR,
    "PlannedStart"     TIMESTAMP,
    "PlannedEnd"       TIMESTAMP,
    "ActualStart"      TIMESTAMP,
    "ActualEnd"        TIMESTAMP,
    "WarehouseId"      INT,
    "AssignedToUserId" INT,
    "Notes"            TEXT,
    "CreatedAt"        TIMESTAMP,
    "UpdatedAt"        TIMESTAMP,
    "TotalCount"       BIGINT
)
LANGUAGE plpgsql AS $$
DECLARE
    v_total BIGINT;
BEGIN
    SELECT COUNT(*) INTO v_total
    FROM   mfg."WorkOrder" wo
    WHERE  wo."CompanyId" = p_company_id
      AND  (p_status      IS NULL OR wo."Status"      = p_status)
      AND  (p_fecha_desde IS NULL OR wo."PlannedStart" >= p_fecha_desde)
      AND  (p_fecha_hasta IS NULL OR wo."PlannedEnd"   <= p_fecha_hasta);

    RETURN QUERY
    SELECT
        wo."WorkOrderId", wo."WorkOrderNumber",
        wo."BOMId", wo."ProductId",
        wo."PlannedQuantity", wo."ProducedQuantity",
        wo."Status", wo."Priority",
        wo."PlannedStart", wo."PlannedEnd",
        wo."ActualStart", wo."ActualEnd",
        wo."WarehouseId", wo."AssignedToUserId",
        wo."Notes"::TEXT, wo."CreatedAt", wo."UpdatedAt",
        v_total
    FROM   mfg."WorkOrder" wo
    WHERE  wo."CompanyId" = p_company_id
      AND  (p_status      IS NULL OR wo."Status"      = p_status)
      AND  (p_fecha_desde IS NULL OR wo."PlannedStart" >= p_fecha_desde)
      AND  (p_fecha_hasta IS NULL OR wo."PlannedEnd"   <= p_fecha_hasta)
    ORDER BY wo."CreatedAt" DESC
    LIMIT p_limit OFFSET (p_page - 1) * p_limit;
END;
$$;

-- =============================================================================
--  usp_Mfg_WorkOrder_Get
-- =============================================================================
DROP FUNCTION IF EXISTS usp_mfg_workorder_get(INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_mfg_workorder_get(
    p_work_order_id INT
)
RETURNS TABLE(
    "WorkOrderId"      INT,
    "WorkOrderNumber"  VARCHAR,
    "CompanyId"        INT,
    "BranchId"         INT,
    "BOMId"            INT,
    "ProductId"        INT,
    "PlannedQuantity"  NUMERIC,
    "ProducedQuantity" NUMERIC,
    "Status"           VARCHAR,
    "Priority"         VARCHAR,
    "PlannedStart"     TIMESTAMP,
    "PlannedEnd"       TIMESTAMP,
    "ActualStart"      TIMESTAMP,
    "ActualEnd"        TIMESTAMP,
    "WarehouseId"      INT,
    "AssignedToUserId" INT,
    "Notes"            TEXT,
    "CreatedAt"        TIMESTAMP,
    "UpdatedAt"        TIMESTAMP,
    "_section"         VARCHAR
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        wo."WorkOrderId", wo."WorkOrderNumber", wo."CompanyId", wo."BranchId",
        wo."BOMId", wo."ProductId",
        wo."PlannedQuantity", wo."ProducedQuantity",
        wo."Status", wo."Priority",
        wo."PlannedStart", wo."PlannedEnd", wo."ActualStart", wo."ActualEnd",
        wo."WarehouseId", wo."AssignedToUserId",
        wo."Notes"::TEXT, wo."CreatedAt", wo."UpdatedAt",
        'header'::VARCHAR
    FROM mfg."WorkOrder" wo
    WHERE wo."WorkOrderId" = p_work_order_id;
END;
$$;

-- =============================================================================
--  usp_Mfg_WorkOrder_Create
-- =============================================================================
DROP FUNCTION IF EXISTS usp_mfg_workorder_create(INT, INT, INT, INT, NUMERIC, TIMESTAMP, TIMESTAMP, VARCHAR, INT, TEXT, INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_mfg_workorder_create(
    p_company_id         INT,
    p_branch_id          INT,
    p_bom_id             INT,
    p_product_id         INT,
    p_planned_quantity   NUMERIC(18,4),
    p_planned_start      TIMESTAMP,
    p_planned_end        TIMESTAMP,
    p_priority           VARCHAR(20) DEFAULT 'MEDIUM',
    p_warehouse_id       INT DEFAULT NULL,
    p_notes              TEXT DEFAULT NULL,
    p_assigned_to_user_id INT DEFAULT NULL,
    p_user_id            INT DEFAULT NULL
)
RETURNS TABLE("ok" INT, "mensaje" VARCHAR, "WorkOrderId" INT, "WorkOrderNumber" VARCHAR)
LANGUAGE plpgsql AS $$
DECLARE
    v_id   INT;
    v_seq  INT;
    v_code VARCHAR(30);
BEGIN
    SELECT COALESCE(MAX("WorkOrderId"), 0) + 1 INTO v_seq FROM mfg."WorkOrder" WHERE "CompanyId" = p_company_id;
    v_code := 'WO-' || LPAD(v_seq::TEXT, 6, '0');

    INSERT INTO mfg."WorkOrder" (
        "CompanyId", "BranchId", "WorkOrderNumber",
        "BOMId", "ProductId", "PlannedQuantity", "ProducedQuantity",
        "Status", "Priority",
        "PlannedStart", "PlannedEnd",
        "WarehouseId", "AssignedToUserId", "Notes",
        "CreatedByUserId", "UpdatedByUserId", "CreatedAt", "UpdatedAt"
    ) VALUES (
        p_company_id, p_branch_id, v_code,
        p_bom_id, p_product_id, p_planned_quantity, 0,
        'PLANNED', p_priority,
        p_planned_start, p_planned_end,
        p_warehouse_id, p_assigned_to_user_id, p_notes,
        p_user_id, p_user_id, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'
    ) RETURNING "WorkOrderId" INTO v_id;

    RETURN QUERY SELECT 1, 'OK'::VARCHAR, v_id, v_code;

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT 0, SQLERRM::VARCHAR, 0, ''::VARCHAR;
END;
$$;

-- =============================================================================
--  usp_Mfg_WorkOrder_Start
-- =============================================================================
DROP FUNCTION IF EXISTS usp_mfg_workorder_start(INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_mfg_workorder_start(
    p_work_order_id INT,
    p_user_id       INT DEFAULT NULL
)
RETURNS TABLE("ok" INT, "mensaje" VARCHAR)
LANGUAGE plpgsql AS $$
DECLARE
    v_status VARCHAR(20);
BEGIN
    SELECT "Status" INTO v_status FROM mfg."WorkOrder" WHERE "WorkOrderId" = p_work_order_id;

    IF v_status <> 'PLANNED' THEN
        RETURN QUERY SELECT 0, ('Solo se puede iniciar una orden en estado PLANNED. Estado actual: ' || COALESCE(v_status, 'NULL'))::VARCHAR;
        RETURN;
    END IF;

    UPDATE mfg."WorkOrder"
    SET    "Status" = 'IN_PROGRESS', "ActualStart" = NOW() AT TIME ZONE 'UTC',
           "UpdatedByUserId" = p_user_id, "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
    WHERE  "WorkOrderId" = p_work_order_id;

    RETURN QUERY SELECT 1, 'OK'::VARCHAR;

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT 0, SQLERRM::VARCHAR;
END;
$$;

-- =============================================================================
--  usp_Mfg_WorkOrder_ConsumeMaterial
-- =============================================================================
DROP FUNCTION IF EXISTS usp_mfg_workorder_consumematerial(INT, INT, NUMERIC, VARCHAR, INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_mfg_workorder_consumematerial(
    p_work_order_id INT,
    p_product_id    INT,
    p_quantity      NUMERIC(18,4),
    p_lot_number    VARCHAR(50) DEFAULT NULL,
    p_warehouse_id  INT DEFAULT NULL,
    p_user_id       INT DEFAULT NULL
)
RETURNS TABLE("ok" INT, "mensaje" VARCHAR)
LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO mfg."WorkOrderMaterial" ("WorkOrderId", "ProductId", "Quantity", "LotNumber", "WarehouseId", "ConsumedAt", "CreatedByUserId")
    VALUES (p_work_order_id, p_product_id, p_quantity, p_lot_number, p_warehouse_id, NOW() AT TIME ZONE 'UTC', p_user_id);

    RETURN QUERY SELECT 1, 'OK'::VARCHAR;

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT 0, SQLERRM::VARCHAR;
END;
$$;

-- =============================================================================
--  usp_Mfg_WorkOrder_ReportOutput
-- =============================================================================
DROP FUNCTION IF EXISTS usp_mfg_workorder_reportoutput(INT, NUMERIC, VARCHAR, INT, INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_mfg_workorder_reportoutput(
    p_work_order_id INT,
    p_quantity      NUMERIC(18,4),
    p_lot_number    VARCHAR(50) DEFAULT NULL,
    p_warehouse_id  INT DEFAULT NULL,
    p_bin_id        INT DEFAULT NULL,
    p_user_id       INT DEFAULT NULL
)
RETURNS TABLE("ok" INT, "mensaje" VARCHAR, "OutputId" INT)
LANGUAGE plpgsql AS $$
DECLARE
    v_id INT;
BEGIN
    INSERT INTO mfg."WorkOrderOutput" ("WorkOrderId", "Quantity", "LotNumber", "WarehouseId", "BinId", "ProducedAt", "CreatedByUserId")
    VALUES (p_work_order_id, p_quantity, p_lot_number, p_warehouse_id, p_bin_id, NOW() AT TIME ZONE 'UTC', p_user_id)
    RETURNING "OutputId" INTO v_id;

    UPDATE mfg."WorkOrder"
    SET    "ProducedQuantity" = COALESCE("ProducedQuantity", 0) + p_quantity,
           "UpdatedByUserId"  = p_user_id,
           "UpdatedAt"        = NOW() AT TIME ZONE 'UTC'
    WHERE  "WorkOrderId" = p_work_order_id;

    RETURN QUERY SELECT 1, 'OK'::VARCHAR, v_id;

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT 0, SQLERRM::VARCHAR, 0;
END;
$$;

-- =============================================================================
--  usp_Mfg_WorkOrder_Complete
-- =============================================================================
DROP FUNCTION IF EXISTS usp_mfg_workorder_complete(INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_mfg_workorder_complete(
    p_work_order_id INT,
    p_user_id       INT DEFAULT NULL
)
RETURNS TABLE("ok" INT, "mensaje" VARCHAR)
LANGUAGE plpgsql AS $$
DECLARE
    v_status VARCHAR(20);
BEGIN
    SELECT "Status" INTO v_status FROM mfg."WorkOrder" WHERE "WorkOrderId" = p_work_order_id;

    IF v_status <> 'IN_PROGRESS' THEN
        RETURN QUERY SELECT 0, ('Solo se puede completar una orden en estado IN_PROGRESS. Estado actual: ' || COALESCE(v_status, 'NULL'))::VARCHAR;
        RETURN;
    END IF;

    UPDATE mfg."WorkOrder"
    SET    "Status" = 'COMPLETED', "ActualEnd" = NOW() AT TIME ZONE 'UTC',
           "UpdatedByUserId" = p_user_id, "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
    WHERE  "WorkOrderId" = p_work_order_id;

    RETURN QUERY SELECT 1, 'OK'::VARCHAR;

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT 0, SQLERRM::VARCHAR;
END;
$$;

-- =============================================================================
--  usp_Mfg_WorkOrder_Cancel
-- =============================================================================
DROP FUNCTION IF EXISTS usp_mfg_workorder_cancel(INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_mfg_workorder_cancel(
    p_work_order_id INT,
    p_user_id       INT DEFAULT NULL
)
RETURNS TABLE("ok" INT, "mensaje" VARCHAR)
LANGUAGE plpgsql AS $$
DECLARE
    v_status VARCHAR(20);
BEGIN
    SELECT "Status" INTO v_status FROM mfg."WorkOrder" WHERE "WorkOrderId" = p_work_order_id;

    IF v_status IN ('COMPLETED', 'CANCELLED') THEN
        RETURN QUERY SELECT 0, ('No se puede cancelar una orden en estado ' || v_status)::VARCHAR;
        RETURN;
    END IF;

    UPDATE mfg."WorkOrder"
    SET    "Status" = 'CANCELLED', "UpdatedByUserId" = p_user_id, "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
    WHERE  "WorkOrderId" = p_work_order_id;

    RETURN QUERY SELECT 1, 'OK'::VARCHAR;

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT 0, SQLERRM::VARCHAR;
END;
$$;
