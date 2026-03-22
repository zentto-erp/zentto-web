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
    "BOMId"          INT,
    "BOMCode"        VARCHAR,
    "BOMName"        VARCHAR,
    "ProductId"      INT,
    "OutputQuantity" NUMERIC,
    "Status"         VARCHAR,
    "CreatedAt"      TIMESTAMP,
    "UpdatedAt"      TIMESTAMP,
    "LineCount"      BIGINT,
    "TotalCount"     BIGINT
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
        b."ProductId", b."OutputQuantity",
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
    "BOMId"          INT,
    "BOMCode"        VARCHAR,
    "BOMName"        VARCHAR,
    "CompanyId"      INT,
    "ProductId"      INT,
    "OutputQuantity" NUMERIC,
    "Status"         VARCHAR,
    "CreatedAt"      TIMESTAMP,
    "UpdatedAt"      TIMESTAMP,
    "_section"       VARCHAR
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        b."BOMId", b."BOMCode", b."BOMName", b."CompanyId",
        b."ProductId", b."OutputQuantity",
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
    p_output_quantity   NUMERIC(18,4) DEFAULT 1,
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
        "OutputQuantity", "Status",
        "CreatedByUserId", "UpdatedByUserId", "CreatedAt", "UpdatedAt"
    ) VALUES (
        p_company_id, p_product_id, p_bom_code, p_bom_name,
        p_output_quantity, 'DRAFT',
        p_user_id, p_user_id, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'
    ) RETURNING "BOMId" INTO v_id;

    IF p_lines_json IS NOT NULL AND LENGTH(p_lines_json) > 2 THEN
        FOR v_line IN SELECT * FROM jsonb_array_elements(p_lines_json::JSONB)
        LOOP
            INSERT INTO mfg."BOMLine" ("BOMId", "LineNumber", "ComponentProductId", "Quantity", "UnitOfMeasure", "WastePercent", "IsOptional", "Notes")
            VALUES (
                v_id,
                COALESCE((v_line.value->>'LineNumber')::INT, 0),
                (v_line.value->>'ComponentProductId')::INT,
                (v_line.value->>'Quantity')::NUMERIC(18,4),
                v_line.value->>'UnitOfMeasure',
                COALESCE((v_line.value->>'WastePercent')::NUMERIC(5,2), 0),
                COALESCE((v_line.value->>'IsOptional')::BOOLEAN, FALSE),
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
    "CapacityUom"    VARCHAR,
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
        w."CostPerHour", w."Capacity", w."CapacityUom", w."IsActive",
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
DROP FUNCTION IF EXISTS usp_mfg_workcenter_upsert(INT, INT, VARCHAR, VARCHAR, NUMERIC, INT, VARCHAR, BOOLEAN, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_mfg_workcenter_upsert(
    p_company_id       INT,
    p_work_center_id   INT DEFAULT NULL,
    p_work_center_code VARCHAR(30) DEFAULT NULL,
    p_work_center_name VARCHAR(120) DEFAULT NULL,
    p_cost_per_hour    NUMERIC(18,2) DEFAULT 0,
    p_capacity         INT DEFAULT 1,
    p_capacity_uom     VARCHAR(20) DEFAULT 'UNITS',
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

        INSERT INTO mfg."WorkCenter" ("CompanyId", "WorkCenterCode", "WorkCenterName", "CostPerHour", "Capacity", "CapacityUom", "IsActive", "CreatedByUserId", "UpdatedByUserId", "CreatedAt", "UpdatedAt")
        VALUES (p_company_id, p_work_center_code, p_work_center_name, p_cost_per_hour, p_capacity, p_capacity_uom, p_is_active, p_user_id, p_user_id, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC');
    ELSE
        UPDATE mfg."WorkCenter"
        SET    "WorkCenterCode"  = p_work_center_code,
               "WorkCenterName"  = p_work_center_name,
               "CostPerHour"     = p_cost_per_hour,
               "Capacity"        = p_capacity,
               "CapacityUom"     = p_capacity_uom,
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
    "RoutingId"        INT,
    "BOMId"            INT,
    "OperationNumber"  INT,
    "WorkCenterId"     INT,
    "WorkCenterName"   VARCHAR,
    "OperationName"    VARCHAR,
    "SetupTimeMinutes" NUMERIC,
    "RunTimeMinutes"   NUMERIC,
    "Notes"            VARCHAR
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        r."RoutingId", r."BOMId", r."OperationNumber",
        r."WorkCenterId", wc."WorkCenterName",
        r."OperationName", r."SetupTimeMinutes", r."RunTimeMinutes",
        r."Notes"::VARCHAR
    FROM   mfg."Routing" r
    LEFT JOIN mfg."WorkCenter" wc ON wc."WorkCenterId" = r."WorkCenterId"
    WHERE  r."BOMId" = p_bom_id
    ORDER BY r."OperationNumber";
END;
$$;

-- =============================================================================
--  usp_Mfg_Routing_Upsert
-- =============================================================================
DROP FUNCTION IF EXISTS usp_mfg_routing_upsert(INT, INT, INT, INT, VARCHAR, NUMERIC, NUMERIC, VARCHAR) CASCADE;
CREATE OR REPLACE FUNCTION usp_mfg_routing_upsert(
    p_bom_id             INT,
    p_routing_id         INT DEFAULT NULL,
    p_operation_number   INT DEFAULT 0,
    p_work_center_id     INT DEFAULT NULL,
    p_operation_name     VARCHAR(200) DEFAULT NULL,
    p_setup_time_minutes NUMERIC(10,2) DEFAULT 0,
    p_run_time_minutes   NUMERIC(10,2) DEFAULT 0,
    p_notes              VARCHAR(500) DEFAULT NULL
)
RETURNS TABLE("ok" INT, "mensaje" VARCHAR)
LANGUAGE plpgsql AS $$
BEGIN
    IF p_routing_id IS NULL THEN
        INSERT INTO mfg."Routing" ("BOMId", "OperationNumber", "WorkCenterId", "OperationName", "SetupTimeMinutes", "RunTimeMinutes", "Notes", "CreatedAt", "UpdatedAt")
        VALUES (p_bom_id, p_operation_number, p_work_center_id, p_operation_name, p_setup_time_minutes, p_run_time_minutes, p_notes, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC');
    ELSE
        UPDATE mfg."Routing"
        SET    "OperationNumber"  = p_operation_number,
               "WorkCenterId"     = p_work_center_id,
               "OperationName"    = p_operation_name,
               "SetupTimeMinutes" = p_setup_time_minutes,
               "RunTimeMinutes"   = p_run_time_minutes,
               "Notes"            = p_notes,
               "UpdatedAt"        = NOW() AT TIME ZONE 'UTC'
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
    "ScrapQuantity"    NUMERIC,
    "UnitOfMeasure"    VARCHAR,
    "Status"           VARCHAR,
    "Priority"         VARCHAR,
    "PlannedStartDate" TIMESTAMP,
    "PlannedEndDate"   TIMESTAMP,
    "ActualStartDate"  TIMESTAMP,
    "ActualEndDate"    TIMESTAMP,
    "WarehouseId"      INT,
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
      AND  (p_status      IS NULL OR wo."Status"           = p_status)
      AND  (p_fecha_desde IS NULL OR wo."PlannedStartDate" >= p_fecha_desde)
      AND  (p_fecha_hasta IS NULL OR wo."PlannedEndDate"   <= p_fecha_hasta);

    RETURN QUERY
    SELECT
        wo."WorkOrderId", wo."WorkOrderNumber",
        wo."BOMId", wo."ProductId",
        wo."PlannedQuantity", wo."ProducedQuantity",
        wo."ScrapQuantity", wo."UnitOfMeasure",
        wo."Status", wo."Priority",
        wo."PlannedStartDate", wo."PlannedEndDate",
        wo."ActualStartDate", wo."ActualEndDate",
        wo."WarehouseId",
        wo."Notes"::TEXT, wo."CreatedAt", wo."UpdatedAt",
        v_total
    FROM   mfg."WorkOrder" wo
    WHERE  wo."CompanyId" = p_company_id
      AND  (p_status      IS NULL OR wo."Status"           = p_status)
      AND  (p_fecha_desde IS NULL OR wo."PlannedStartDate" >= p_fecha_desde)
      AND  (p_fecha_hasta IS NULL OR wo."PlannedEndDate"   <= p_fecha_hasta)
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
    "ScrapQuantity"    NUMERIC,
    "UnitOfMeasure"    VARCHAR,
    "Status"           VARCHAR,
    "Priority"         VARCHAR,
    "PlannedStartDate" TIMESTAMP,
    "PlannedEndDate"   TIMESTAMP,
    "ActualStartDate"  TIMESTAMP,
    "ActualEndDate"    TIMESTAMP,
    "WarehouseId"      INT,
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
        wo."ScrapQuantity", wo."UnitOfMeasure",
        wo."Status", wo."Priority",
        wo."PlannedStartDate", wo."PlannedEndDate",
        wo."ActualStartDate", wo."ActualEndDate",
        wo."WarehouseId",
        wo."Notes"::TEXT, wo."CreatedAt", wo."UpdatedAt",
        'header'::VARCHAR
    FROM mfg."WorkOrder" wo
    WHERE wo."WorkOrderId" = p_work_order_id;
END;
$$;

-- =============================================================================
--  usp_Mfg_WorkOrder_Create
-- =============================================================================
DROP FUNCTION IF EXISTS usp_mfg_workorder_create(INT, INT, INT, INT, NUMERIC, VARCHAR, TIMESTAMP, TIMESTAMP, VARCHAR, INT, TEXT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_mfg_workorder_create(
    p_company_id         INT,
    p_branch_id          INT,
    p_bom_id             INT,
    p_product_id         INT,
    p_planned_quantity   NUMERIC(18,4),
    p_unit_of_measure    VARCHAR(20) DEFAULT 'UND',
    p_planned_start_date TIMESTAMP DEFAULT NULL,
    p_planned_end_date   TIMESTAMP DEFAULT NULL,
    p_priority           VARCHAR(20) DEFAULT 'MEDIUM',
    p_warehouse_id       INT DEFAULT NULL,
    p_notes              TEXT DEFAULT NULL,
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
        "BOMId", "ProductId", "PlannedQuantity", "ProducedQuantity", "ScrapQuantity",
        "UnitOfMeasure", "Status", "Priority",
        "PlannedStartDate", "PlannedEndDate",
        "WarehouseId", "Notes",
        "CreatedByUserId", "UpdatedByUserId", "CreatedAt", "UpdatedAt"
    ) VALUES (
        p_company_id, p_branch_id, v_code,
        p_bom_id, p_product_id, p_planned_quantity, 0, 0,
        p_unit_of_measure, 'PLANNED', p_priority,
        p_planned_start_date, p_planned_end_date,
        p_warehouse_id, p_notes,
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
    SELECT wo."Status" INTO v_status FROM mfg."WorkOrder" wo WHERE wo."WorkOrderId" = p_work_order_id;

    IF v_status <> 'PLANNED' THEN
        RETURN QUERY SELECT 0, ('Solo se puede iniciar una orden en estado PLANNED. Estado actual: ' || COALESCE(v_status, 'NULL'))::VARCHAR;
        RETURN;
    END IF;

    UPDATE mfg."WorkOrder"
    SET    "Status" = 'IN_PROGRESS', "ActualStartDate" = NOW() AT TIME ZONE 'UTC',
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
DROP FUNCTION IF EXISTS usp_mfg_workorder_consumematerial(INT, INT, INT, NUMERIC, NUMERIC, VARCHAR, INT, INT, NUMERIC, VARCHAR, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_mfg_workorder_consumematerial(
    p_work_order_id    INT,
    p_line_number      INT DEFAULT 1,
    p_product_id       INT DEFAULT NULL,
    p_planned_quantity NUMERIC(18,4) DEFAULT 0,
    p_consumed_quantity NUMERIC(18,4) DEFAULT 0,
    p_unit_of_measure  VARCHAR(20) DEFAULT 'UND',
    p_lot_id           INT DEFAULT NULL,
    p_bin_id           INT DEFAULT NULL,
    p_unit_cost        NUMERIC(18,4) DEFAULT 0,
    p_notes            VARCHAR(500) DEFAULT NULL,
    p_user_id          INT DEFAULT NULL
)
RETURNS TABLE("ok" INT, "mensaje" VARCHAR)
LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO mfg."WorkOrderMaterial" (
        "WorkOrderId", "LineNumber", "ProductId",
        "PlannedQuantity", "ConsumedQuantity", "UnitOfMeasure",
        "LotId", "BinId", "UnitCost", "Notes",
        "CreatedAt", "UpdatedAt"
    ) VALUES (
        p_work_order_id, p_line_number, p_product_id,
        p_planned_quantity, p_consumed_quantity, p_unit_of_measure,
        p_lot_id, p_bin_id, p_unit_cost, p_notes,
        NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'
    );

    RETURN QUERY SELECT 1, 'OK'::VARCHAR;

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT 0, SQLERRM::VARCHAR;
END;
$$;

-- =============================================================================
--  usp_Mfg_WorkOrder_ReportOutput
-- =============================================================================
DROP FUNCTION IF EXISTS usp_mfg_workorder_reportoutput(INT, INT, NUMERIC, VARCHAR, VARCHAR, INT, INT, NUMERIC, BOOLEAN, VARCHAR, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_mfg_workorder_reportoutput(
    p_work_order_id  INT,
    p_product_id     INT,
    p_quantity       NUMERIC(18,4),
    p_unit_of_measure VARCHAR(20) DEFAULT 'UND',
    p_lot_number     VARCHAR(50) DEFAULT NULL,
    p_warehouse_id   INT DEFAULT NULL,
    p_bin_id         INT DEFAULT NULL,
    p_unit_cost      NUMERIC(18,4) DEFAULT 0,
    p_is_scrap       BOOLEAN DEFAULT FALSE,
    p_notes          VARCHAR(500) DEFAULT NULL,
    p_user_id        INT DEFAULT NULL
)
RETURNS TABLE("ok" INT, "mensaje" VARCHAR, "WorkOrderOutputId" INT)
LANGUAGE plpgsql AS $$
DECLARE
    v_id INT;
BEGIN
    INSERT INTO mfg."WorkOrderOutput" (
        "WorkOrderId", "ProductId", "Quantity", "UnitOfMeasure",
        "LotNumber", "WarehouseId", "BinId", "UnitCost",
        "IsScrap", "Notes", "ProducedAt", "CreatedByUserId", "CreatedAt"
    ) VALUES (
        p_work_order_id, p_product_id, p_quantity, p_unit_of_measure,
        p_lot_number, p_warehouse_id, p_bin_id, p_unit_cost,
        p_is_scrap, p_notes, NOW() AT TIME ZONE 'UTC', p_user_id, NOW() AT TIME ZONE 'UTC'
    ) RETURNING "WorkOrderOutputId" INTO v_id;

    -- Actualizar cantidad producida o scrap en la orden
    IF p_is_scrap THEN
        UPDATE mfg."WorkOrder"
        SET    "ScrapQuantity"    = COALESCE("ScrapQuantity", 0) + p_quantity,
               "UpdatedByUserId"  = p_user_id,
               "UpdatedAt"        = NOW() AT TIME ZONE 'UTC'
        WHERE  "WorkOrderId" = p_work_order_id;
    ELSE
        UPDATE mfg."WorkOrder"
        SET    "ProducedQuantity" = COALESCE("ProducedQuantity", 0) + p_quantity,
               "UpdatedByUserId"  = p_user_id,
               "UpdatedAt"        = NOW() AT TIME ZONE 'UTC'
        WHERE  "WorkOrderId" = p_work_order_id;
    END IF;

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
    SELECT wo."Status" INTO v_status FROM mfg."WorkOrder" wo WHERE wo."WorkOrderId" = p_work_order_id;

    IF v_status <> 'IN_PROGRESS' THEN
        RETURN QUERY SELECT 0, ('Solo se puede completar una orden en estado IN_PROGRESS. Estado actual: ' || COALESCE(v_status, 'NULL'))::VARCHAR;
        RETURN;
    END IF;

    UPDATE mfg."WorkOrder"
    SET    "Status" = 'COMPLETED', "ActualEndDate" = NOW() AT TIME ZONE 'UTC',
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
    SELECT wo."Status" INTO v_status FROM mfg."WorkOrder" wo WHERE wo."WorkOrderId" = p_work_order_id;

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
