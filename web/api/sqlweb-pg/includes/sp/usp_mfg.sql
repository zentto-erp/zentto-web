-- ============================================================
-- DatqBoxWeb PostgreSQL - usp_mfg.sql
-- Funciones del modulo MFG (Manufacturing / Manufactura)
-- Fecha: 2026-03-22
-- ============================================================

-- =============================================================================
--  usp_Mfg_BOM_List
--  Service envía: CompanyId, Status, Search, Page, Limit
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
    "BOMId" BIGINT,
    "BOMCode"        VARCHAR,
    "BOMName"        VARCHAR,
    "ProductId" BIGINT,
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
--  Service envía: BOMId
-- =============================================================================
DROP FUNCTION IF EXISTS usp_mfg_bom_get(INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_mfg_bom_get(
    p_bom_id INT
)
RETURNS TABLE(
    "BOMId" BIGINT,
    "BOMCode"        VARCHAR,
    "BOMName"        VARCHAR,
    "CompanyId"      INT,
    "ProductId" BIGINT,
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
--  Service envía: CompanyId, ProductId, BOMCode, BOMName, OutputQuantity, LinesJson, UserId
-- =============================================================================
DROP FUNCTION IF EXISTS usp_mfg_bom_create(INT, INT, VARCHAR, VARCHAR, NUMERIC, TEXT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_mfg_bom_create(
    p_company_id          INT,
    p_product_id          INT,
    p_bom_code            VARCHAR(30),
    p_bom_name            VARCHAR(200),
    p_output_quantity     NUMERIC(18,4) DEFAULT 1,
    p_lines_json          TEXT DEFAULT NULL,
    p_user_id             INT DEFAULT NULL
)
RETURNS TABLE("ok" INT, "mensaje" VARCHAR, "BOMId" BIGINT)
LANGUAGE plpgsql AS $$
DECLARE
    v_id BIGINT;
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
--  Service envía: BOMId, UserId
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
--  Service envía: BOMId, UserId
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
--  Service envía: CompanyId, Search, Page, Limit
--  Tabla tiene: WorkCenterId, CompanyId, WorkCenterCode, WorkCenterName,
--               WarehouseId, CostPerHour, Capacity, CapacityUom, IsActive
-- =============================================================================
DROP FUNCTION IF EXISTS usp_mfg_workcenter_list(INT, VARCHAR, INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_mfg_workcenter_list(
    p_company_id INT,
    p_search     VARCHAR(200) DEFAULT NULL,
    p_page       INT DEFAULT 1,
    p_limit      INT DEFAULT 50
)
RETURNS TABLE(
    "WorkCenterId" BIGINT,
    "CompanyId"      INT,
    "WorkCenterCode" VARCHAR,
    "WorkCenterName" VARCHAR,
    "WarehouseId" BIGINT,
    "CostPerHour"    NUMERIC,
    "Capacity" NUMERIC,
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
        w."WorkCenterId", w."CompanyId",
        w."WorkCenterCode", w."WorkCenterName",
        w."WarehouseId", w."CostPerHour",
        w."Capacity", w."CapacityUom", w."IsActive",
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
--  Service envía: CompanyId, WorkCenterId, WorkCenterCode, WorkCenterName,
--                 CostPerHour, Capacity, IsActive, UserId
--  Nota: CapacityUom y WarehouseId NO vienen del service, usan defaults
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

        INSERT INTO mfg."WorkCenter" ("CompanyId", "WorkCenterCode", "WorkCenterName", "CostPerHour", "Capacity", "CapacityUom", "IsActive", "CreatedByUserId", "UpdatedByUserId", "CreatedAt", "UpdatedAt")
        VALUES (p_company_id, p_work_center_code, p_work_center_name, p_cost_per_hour, p_capacity, 'UNITS', p_is_active, p_user_id, p_user_id, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC');
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
--  Service envía: BOMId
--  Tabla Routing: RoutingId, BOMId, OperationNumber, OperationName,
--                 WorkCenterId, SetupTimeMinutes, RunTimeMinutes, Notes
-- =============================================================================
DROP FUNCTION IF EXISTS usp_mfg_routing_list(INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_mfg_routing_list(
    p_bom_id INT
)
RETURNS TABLE(
    "RoutingId" BIGINT,
    "BOMId" BIGINT,
    "OperationNumber"  INT,
    "WorkCenterId" BIGINT,
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
--  Service envía: BOMId, RoutingId, OperationNumber, WorkCenterId,
--                 OperationName, SetupTimeMinutes, RunTimeMinutes, Notes, UserId
--  Nota: Tabla Routing NO tiene CreatedByUserId/UpdatedByUserId, solo timestamps
-- =============================================================================
DROP FUNCTION IF EXISTS usp_mfg_routing_upsert(INT, INT, INT, INT, VARCHAR, NUMERIC, NUMERIC, VARCHAR, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_mfg_routing_upsert(
    p_bom_id             INT,
    p_routing_id         INT DEFAULT NULL,
    p_operation_number   INT DEFAULT 0,
    p_work_center_id     INT DEFAULT NULL,
    p_operation_name     VARCHAR(200) DEFAULT NULL,
    p_setup_time_minutes NUMERIC(10,2) DEFAULT 0,
    p_run_time_minutes   NUMERIC(10,2) DEFAULT 0,
    p_notes              VARCHAR(500) DEFAULT NULL,
    p_user_id            INT DEFAULT NULL
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
--  Service envía: CompanyId, Status, FechaDesde, FechaHasta, Page, Limit
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
    "WorkOrderId" BIGINT,
    "WorkOrderNumber"  VARCHAR,
    "BOMId" BIGINT,
    "ProductId" BIGINT,
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
    "WarehouseId" BIGINT,
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
--  Service envía: WorkOrderId
-- =============================================================================
DROP FUNCTION IF EXISTS usp_mfg_workorder_get(INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_mfg_workorder_get(
    p_work_order_id INT
)
RETURNS TABLE(
    "WorkOrderId" BIGINT,
    "WorkOrderNumber"  VARCHAR,
    "CompanyId"        INT,
    "BranchId"         INT,
    "BOMId" BIGINT,
    "ProductId" BIGINT,
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
    "WarehouseId" BIGINT,
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
--  Service envía: CompanyId, BranchId, BOMId, ProductId, PlannedQuantity,
--                 PlannedStart, PlannedEnd, Priority, WarehouseId, Notes,
--                 AssignedToUserId, UserId
--  Nota: AssignedToUserId se acepta pero se ignora (tabla no tiene esa columna)
-- =============================================================================
DROP FUNCTION IF EXISTS usp_mfg_workorder_create(INT, INT, INT, INT, NUMERIC, TIMESTAMP, TIMESTAMP, VARCHAR, INT, TEXT, INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_mfg_workorder_create(
    p_company_id           INT,
    p_branch_id            INT,
    p_bom_id               INT,
    p_product_id           INT,
    p_planned_quantity     NUMERIC(18,4),
    p_planned_start        TIMESTAMP DEFAULT NULL,
    p_planned_end          TIMESTAMP DEFAULT NULL,
    p_priority             VARCHAR(20) DEFAULT 'MEDIUM',
    p_warehouse_id         INT DEFAULT NULL,
    p_notes                TEXT DEFAULT NULL,
    p_assigned_to_user_id  INT DEFAULT NULL,
    p_user_id              INT DEFAULT NULL
)
RETURNS TABLE("ok" INT, "mensaje" VARCHAR, "WorkOrderId" BIGINT, "WorkOrderNumber" VARCHAR)
LANGUAGE plpgsql AS $$
DECLARE
    v_id BIGINT;
    v_seq  INT;
    v_code VARCHAR(30);
BEGIN
    -- p_assigned_to_user_id se ignora: la tabla no tiene esa columna
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
        'UND', 'PLANNED', p_priority,
        p_planned_start, p_planned_end,
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
--  Service envía: WorkOrderId, UserId
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
--  usp_Mfg_WorkOrder_Complete
--  Service envía: WorkOrderId, UserId
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
--  Service envía: WorkOrderId, UserId
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

-- =============================================================================
--  usp_Mfg_WorkOrder_ConsumeMaterial
--  Service envía: WorkOrderId, ProductId, Quantity, LotNumber, WarehouseId, UserId
--  Mapeo: p_quantity → "ConsumedQuantity", p_lot_number → ignorado (tabla usa "LotId")
--  Nota: Tabla tiene LotId (INT), no LotNumber. Se ignora p_lot_number por ahora.
-- =============================================================================
DROP FUNCTION IF EXISTS usp_mfg_workorder_consumematerial(INT, INT, NUMERIC, VARCHAR, INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_mfg_workorder_consumematerial(
    p_work_order_id  INT,
    p_product_id     INT DEFAULT NULL,
    p_quantity       NUMERIC(18,4) DEFAULT 0,
    p_lot_number     VARCHAR(50) DEFAULT NULL,
    p_warehouse_id   INT DEFAULT NULL,
    p_user_id        INT DEFAULT NULL
)
RETURNS TABLE("ok" INT, "mensaje" VARCHAR)
LANGUAGE plpgsql AS $$
DECLARE
    v_next_line INT;
BEGIN
    -- Calcular siguiente LineNumber
    SELECT COALESCE(MAX("LineNumber"), 0) + 1 INTO v_next_line
    FROM   mfg."WorkOrderMaterial"
    WHERE  "WorkOrderId" = p_work_order_id;

    INSERT INTO mfg."WorkOrderMaterial" (
        "WorkOrderId", "LineNumber", "ProductId",
        "PlannedQuantity", "ConsumedQuantity", "UnitOfMeasure",
        "LotId", "BinId", "UnitCost", "Notes",
        "CreatedAt", "UpdatedAt"
    ) VALUES (
        p_work_order_id, v_next_line, p_product_id,
        p_quantity, p_quantity, 'UND',
        NULL, NULL, 0, NULL,
        NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'
    );

    RETURN QUERY SELECT 1, 'OK'::VARCHAR;

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT 0, SQLERRM::VARCHAR;
END;
$$;

-- =============================================================================
--  usp_Mfg_WorkOrder_ReportOutput
--  Service envía: WorkOrderId, Quantity, LotNumber, WarehouseId, BinId, UserId
--  Tabla WorkOrderOutput: ProductId, Quantity, LotNumber, WarehouseId, BinId,
--                         UnitCost, IsScrap
--  Nota: ProductId se obtiene del WorkOrder
-- =============================================================================
DROP FUNCTION IF EXISTS usp_mfg_workorder_reportoutput(INT, NUMERIC, VARCHAR, INT, INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_mfg_workorder_reportoutput(
    p_work_order_id  INT,
    p_quantity       NUMERIC(18,4),
    p_lot_number     VARCHAR(50) DEFAULT NULL,
    p_warehouse_id   INT DEFAULT NULL,
    p_bin_id         INT DEFAULT NULL,
    p_user_id        INT DEFAULT NULL
)
RETURNS TABLE("ok" INT, "mensaje" VARCHAR, "OutputId" INT)
LANGUAGE plpgsql AS $$
DECLARE
    v_id BIGINT;
    v_product_id INT;
BEGIN
    -- Obtener ProductId del WorkOrder
    SELECT wo."ProductId" INTO v_product_id
    FROM   mfg."WorkOrder" wo
    WHERE  wo."WorkOrderId" = p_work_order_id;

    INSERT INTO mfg."WorkOrderOutput" (
        "WorkOrderId", "ProductId", "Quantity", "UnitOfMeasure",
        "LotNumber", "WarehouseId", "BinId", "UnitCost",
        "IsScrap", "Notes", "ProducedAt", "CreatedByUserId", "CreatedAt"
    ) VALUES (
        p_work_order_id, v_product_id, p_quantity, 'UND',
        p_lot_number, p_warehouse_id, p_bin_id, 0,
        FALSE, NULL, NOW() AT TIME ZONE 'UTC', p_user_id, NOW() AT TIME ZONE 'UTC'
    ) RETURNING "WorkOrderOutputId" INTO v_id;

    -- Actualizar cantidad producida en la orden
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
