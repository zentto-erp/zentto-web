/*
 * ============================================================================
 *  Archivo : usp_fleet.sql  (PostgreSQL)
 *  Esquemas: fleet (tablas)
 *
 *  Descripcion:
 *    Funciones para el modulo de Control de Flota.
 *    Vehiculos, Combustible, Mantenimiento, Viajes, Documentos, Dashboard.
 *
 *  Convenciones:
 *    - Nombrado: usp_fleet_[entity]_[action]
 *    - Patron: CREATE OR REPLACE FUNCTION ... LANGUAGE plpgsql
 * ============================================================================
 */

-- =============================================================================
--  SECCION 1: VEHICULOS
-- =============================================================================

-- usp_Fleet_Vehicle_List
DROP FUNCTION IF EXISTS usp_fleet_vehicle_list(INT, VARCHAR, VARCHAR, VARCHAR, INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_fleet_vehicle_list(
    p_company_id   INT,
    p_status       VARCHAR(20)  DEFAULT NULL,
    p_vehicle_type VARCHAR(30)  DEFAULT NULL,
    p_search       VARCHAR(100) DEFAULT NULL,
    p_page         INT DEFAULT 1,
    p_limit        INT DEFAULT 50
)
RETURNS TABLE(
    "VehicleId"              INT,
    "VehiclePlate"           VARCHAR,
    "VIN"                    VARCHAR,
    "Brand"                  VARCHAR,
    "Model"                  VARCHAR,
    "Year"                   INT,
    "Color"                  VARCHAR,
    "VehicleType"            VARCHAR,
    "FuelType"               VARCHAR,
    "CurrentMileage"         NUMERIC,
    "IsActive"               BOOLEAN,
    "AssignedDriverId"       INT,
    "AssignedBranchId"       INT,
    "InsuranceExpiry"        TIMESTAMP,
    "TechnicalReviewExpiry"  TIMESTAMP,
    "PermitExpiry"           TIMESTAMP,
    "CreatedAt"              TIMESTAMP,
    "TotalCount"             INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_offset INT := (p_page - 1) * p_limit;
    v_total  INT;
BEGIN
    SELECT COUNT(*) INTO v_total
    FROM fleet."Vehicle"
    WHERE "CompanyId" = p_company_id
      AND (p_status IS NULL OR (
            (p_status = 'ACTIVE' AND "IsActive" = TRUE)
            OR (p_status = 'INACTIVE' AND "IsActive" = FALSE)
          ))
      AND (p_vehicle_type IS NULL OR "VehicleType" = p_vehicle_type)
      AND (p_search IS NULL OR (
            "VehiclePlate" ILIKE '%' || p_search || '%'
            OR "Brand" ILIKE '%' || p_search || '%'
            OR "Model" ILIKE '%' || p_search || '%'
            OR "VIN" ILIKE '%' || p_search || '%'
          ));

    RETURN QUERY
    SELECT
        v."VehicleId",
        v."VehiclePlate"::VARCHAR,
        v."VIN"::VARCHAR,
        v."Brand"::VARCHAR,
        v."Model"::VARCHAR,
        v."Year",
        v."Color"::VARCHAR,
        v."VehicleType"::VARCHAR,
        v."FuelType"::VARCHAR,
        v."CurrentMileage",
        v."IsActive",
        v."AssignedDriverId",
        v."AssignedBranchId",
        v."InsuranceExpiry",
        v."TechnicalReviewExpiry",
        v."PermitExpiry",
        v."CreatedAt",
        v_total
    FROM fleet."Vehicle" v
    WHERE v."CompanyId" = p_company_id
      AND (p_status IS NULL OR (
            (p_status = 'ACTIVE' AND v."IsActive" = TRUE)
            OR (p_status = 'INACTIVE' AND v."IsActive" = FALSE)
          ))
      AND (p_vehicle_type IS NULL OR v."VehicleType" = p_vehicle_type)
      AND (p_search IS NULL OR (
            v."VehiclePlate" ILIKE '%' || p_search || '%'
            OR v."Brand" ILIKE '%' || p_search || '%'
            OR v."Model" ILIKE '%' || p_search || '%'
            OR v."VIN" ILIKE '%' || p_search || '%'
          ))
    ORDER BY v."VehiclePlate"
    OFFSET v_offset LIMIT p_limit;
END;
$$;

-- usp_Fleet_Vehicle_Get
DROP FUNCTION IF EXISTS usp_fleet_vehicle_get(INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_fleet_vehicle_get(
    p_vehicle_id INT
)
RETURNS TABLE(
    "VehicleId"              INT,
    "CompanyId"              INT,
    "VehiclePlate"           VARCHAR,
    "VIN"                    VARCHAR,
    "Brand"                  VARCHAR,
    "Model"                  VARCHAR,
    "Year"                   INT,
    "Color"                  VARCHAR,
    "VehicleType"            VARCHAR,
    "FuelType"               VARCHAR,
    "CurrentMileage"         NUMERIC,
    "PurchaseDate"           TIMESTAMP,
    "PurchaseCost"           NUMERIC,
    "InsurancePolicy"        VARCHAR,
    "InsuranceExpiry"        TIMESTAMP,
    "TechnicalReviewExpiry"  TIMESTAMP,
    "PermitExpiry"           TIMESTAMP,
    "AssignedDriverId"       INT,
    "AssignedBranchId"       INT,
    "Notes"                  VARCHAR,
    "IsActive"               BOOLEAN,
    "CreatedAt"              TIMESTAMP,
    "UpdatedAt"              TIMESTAMP
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        v."VehicleId",
        v."CompanyId",
        v."VehiclePlate"::VARCHAR,
        v."VIN"::VARCHAR,
        v."Brand"::VARCHAR,
        v."Model"::VARCHAR,
        v."Year",
        v."Color"::VARCHAR,
        v."VehicleType"::VARCHAR,
        v."FuelType"::VARCHAR,
        v."CurrentMileage",
        v."PurchaseDate",
        v."PurchaseCost",
        v."InsurancePolicy"::VARCHAR,
        v."InsuranceExpiry",
        v."TechnicalReviewExpiry",
        v."PermitExpiry",
        v."AssignedDriverId",
        v."AssignedBranchId",
        v."Notes"::VARCHAR,
        v."IsActive",
        v."CreatedAt",
        v."UpdatedAt"
    FROM fleet."Vehicle" v
    WHERE v."VehicleId" = p_vehicle_id;
END;
$$;

-- usp_Fleet_Vehicle_Upsert
DROP FUNCTION IF EXISTS usp_fleet_vehicle_upsert(INT, INT, VARCHAR, VARCHAR, VARCHAR, VARCHAR, INT, VARCHAR, VARCHAR, VARCHAR, NUMERIC, TIMESTAMP, NUMERIC, VARCHAR, TIMESTAMP, TIMESTAMP, TIMESTAMP, INT, INT, VARCHAR, BOOLEAN, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_fleet_vehicle_upsert(
    p_company_id              INT,
    p_vehicle_id              INT DEFAULT NULL,
    p_vehicle_plate           VARCHAR(20) DEFAULT NULL,
    p_vin                     VARCHAR(50) DEFAULT NULL,
    p_brand                   VARCHAR(50) DEFAULT NULL,
    p_model                   VARCHAR(50) DEFAULT NULL,
    p_year                    INT DEFAULT NULL,
    p_color                   VARCHAR(30) DEFAULT NULL,
    p_vehicle_type            VARCHAR(30) DEFAULT NULL,
    p_fuel_type               VARCHAR(20) DEFAULT NULL,
    p_current_mileage         NUMERIC(12,2) DEFAULT 0,
    p_purchase_date           TIMESTAMP DEFAULT NULL,
    p_purchase_cost           NUMERIC(18,2) DEFAULT NULL,
    p_insurance_policy        VARCHAR(100) DEFAULT NULL,
    p_insurance_expiry        TIMESTAMP DEFAULT NULL,
    p_technical_review_expiry TIMESTAMP DEFAULT NULL,
    p_permit_expiry           TIMESTAMP DEFAULT NULL,
    p_assigned_driver_id      INT DEFAULT NULL,
    p_assigned_branch_id      INT DEFAULT NULL,
    p_notes                   VARCHAR(500) DEFAULT NULL,
    p_is_active               BOOLEAN DEFAULT TRUE,
    p_user_id                 INT DEFAULT NULL
)
RETURNS TABLE("ok" INT, "VehicleId" INT)
LANGUAGE plpgsql
AS $$
DECLARE
    v_id INT;
BEGIN
    IF p_vehicle_id IS NOT NULL AND EXISTS (SELECT 1 FROM fleet."Vehicle" WHERE "VehicleId" = p_vehicle_id) THEN
        UPDATE fleet."Vehicle" SET
            "VehiclePlate"           = p_vehicle_plate,
            "VIN"                    = p_vin,
            "Brand"                  = p_brand,
            "Model"                  = p_model,
            "Year"                   = p_year,
            "Color"                  = p_color,
            "VehicleType"            = p_vehicle_type,
            "FuelType"               = p_fuel_type,
            "CurrentMileage"         = p_current_mileage,
            "PurchaseDate"           = p_purchase_date,
            "PurchaseCost"           = p_purchase_cost,
            "InsurancePolicy"        = p_insurance_policy,
            "InsuranceExpiry"        = p_insurance_expiry,
            "TechnicalReviewExpiry"  = p_technical_review_expiry,
            "PermitExpiry"           = p_permit_expiry,
            "AssignedDriverId"       = p_assigned_driver_id,
            "AssignedBranchId"       = p_assigned_branch_id,
            "Notes"                  = p_notes,
            "IsActive"               = p_is_active,
            "UpdatedAt"              = NOW() AT TIME ZONE 'UTC',
            "UpdatedBy"              = p_user_id
        WHERE "VehicleId" = p_vehicle_id;
        v_id := p_vehicle_id;
    ELSE
        INSERT INTO fleet."Vehicle" (
            "CompanyId", "VehiclePlate", "VIN", "Brand", "Model", "Year", "Color",
            "VehicleType", "FuelType", "CurrentMileage", "PurchaseDate", "PurchaseCost",
            "InsurancePolicy", "InsuranceExpiry", "TechnicalReviewExpiry", "PermitExpiry",
            "AssignedDriverId", "AssignedBranchId", "Notes", "IsActive",
            "CreatedAt", "CreatedBy"
        ) VALUES (
            p_company_id, p_vehicle_plate, p_vin, p_brand, p_model, p_year, p_color,
            p_vehicle_type, p_fuel_type, p_current_mileage, p_purchase_date, p_purchase_cost,
            p_insurance_policy, p_insurance_expiry, p_technical_review_expiry, p_permit_expiry,
            p_assigned_driver_id, p_assigned_branch_id, p_notes, p_is_active,
            NOW() AT TIME ZONE 'UTC', p_user_id
        ) RETURNING "VehicleId" INTO v_id;
    END IF;

    RETURN QUERY SELECT 1, v_id;
END;
$$;

-- =============================================================================
--  SECCION 2: COMBUSTIBLE (Fuel Logs)
-- =============================================================================

-- usp_Fleet_FuelLog_List
DROP FUNCTION IF EXISTS usp_fleet_fuellog_list(INT, INT, TIMESTAMP, TIMESTAMP, INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_fleet_fuellog_list(
    p_company_id  INT,
    p_vehicle_id  INT DEFAULT NULL,
    p_fecha_desde TIMESTAMP DEFAULT NULL,
    p_fecha_hasta TIMESTAMP DEFAULT NULL,
    p_page        INT DEFAULT 1,
    p_limit       INT DEFAULT 50
)
RETURNS TABLE(
    "FuelLogId"     INT,
    "VehicleId"     INT,
    "VehiclePlate"  VARCHAR,
    "LogDate"       TIMESTAMP,
    "Mileage"       NUMERIC,
    "FuelType"      VARCHAR,
    "Liters"        NUMERIC,
    "PricePerLiter" NUMERIC,
    "TotalCost"     NUMERIC,
    "StationName"   VARCHAR,
    "DriverId"      INT,
    "Notes"         VARCHAR,
    "CreatedAt"     TIMESTAMP,
    "TotalCount"    INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_offset INT := (p_page - 1) * p_limit;
    v_total  INT;
BEGIN
    SELECT COUNT(*) INTO v_total
    FROM fleet."FuelLog" fl
    INNER JOIN fleet."Vehicle" v ON v."VehicleId" = fl."VehicleId"
    WHERE v."CompanyId" = p_company_id
      AND (p_vehicle_id IS NULL OR fl."VehicleId" = p_vehicle_id)
      AND fl."LogDate" >= p_fecha_desde
      AND fl."LogDate" <= p_fecha_hasta;

    RETURN QUERY
    SELECT
        fl."FuelLogId",
        fl."VehicleId",
        v."VehiclePlate"::VARCHAR,
        fl."LogDate",
        fl."Mileage",
        fl."FuelType"::VARCHAR,
        fl."Liters",
        fl."PricePerLiter",
        fl."TotalCost",
        fl."StationName"::VARCHAR,
        fl."DriverId",
        fl."Notes"::VARCHAR,
        fl."CreatedAt",
        v_total
    FROM fleet."FuelLog" fl
    INNER JOIN fleet."Vehicle" v ON v."VehicleId" = fl."VehicleId"
    WHERE v."CompanyId" = p_company_id
      AND (p_vehicle_id IS NULL OR fl."VehicleId" = p_vehicle_id)
      AND fl."LogDate" >= p_fecha_desde
      AND fl."LogDate" <= p_fecha_hasta
    ORDER BY fl."LogDate" DESC
    OFFSET v_offset LIMIT p_limit;
END;
$$;

-- usp_Fleet_FuelLog_Create
DROP FUNCTION IF EXISTS usp_fleet_fuellog_create(INT, INT, TIMESTAMP, NUMERIC, VARCHAR, NUMERIC, NUMERIC, NUMERIC, VARCHAR, INT, VARCHAR, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_fleet_fuellog_create(
    p_company_id     INT,
    p_vehicle_id     INT,
    p_log_date       TIMESTAMP,
    p_mileage        NUMERIC(12,2),
    p_fuel_type      VARCHAR(20),
    p_liters         NUMERIC(10,3),
    p_price_per_liter NUMERIC(10,4),
    p_total_cost     NUMERIC(18,2),
    p_station_name   VARCHAR(100) DEFAULT NULL,
    p_driver_id      INT DEFAULT NULL,
    p_notes          VARCHAR(500) DEFAULT NULL,
    p_user_id        INT DEFAULT NULL
)
RETURNS TABLE("ok" INT, "FuelLogId" INT)
LANGUAGE plpgsql
AS $$
DECLARE
    v_id INT;
BEGIN
    INSERT INTO fleet."FuelLog" (
        "VehicleId", "LogDate", "Mileage", "FuelType", "Liters", "PricePerLiter",
        "TotalCost", "StationName", "DriverId", "Notes", "CreatedAt", "CreatedBy"
    ) VALUES (
        p_vehicle_id, p_log_date, p_mileage, p_fuel_type, p_liters, p_price_per_liter,
        p_total_cost, p_station_name, p_driver_id, p_notes, NOW() AT TIME ZONE 'UTC', p_user_id
    ) RETURNING "FuelLogId" INTO v_id;

    -- Actualizar kilometraje si es mayor al actual
    UPDATE fleet."Vehicle"
    SET "CurrentMileage" = p_mileage, "UpdatedAt" = NOW() AT TIME ZONE 'UTC', "UpdatedBy" = p_user_id
    WHERE "VehicleId" = p_vehicle_id AND "CurrentMileage" < p_mileage;

    RETURN QUERY SELECT 1, v_id;
END;
$$;

-- =============================================================================
--  SECCION 3: TIPOS DE MANTENIMIENTO
-- =============================================================================

-- usp_Fleet_MaintenanceType_List
DROP FUNCTION IF EXISTS usp_fleet_maintenancetype_list(INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_fleet_maintenancetype_list(
    p_company_id INT
)
RETURNS TABLE(
    "MaintenanceTypeId"  INT,
    "TypeCode"           VARCHAR,
    "TypeName"           VARCHAR,
    "Category"           VARCHAR,
    "DefaultIntervalKm"  NUMERIC,
    "DefaultIntervalDays" INT,
    "IsActive"           BOOLEAN,
    "CreatedAt"          TIMESTAMP
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        mt."MaintenanceTypeId",
        mt."TypeCode"::VARCHAR,
        mt."TypeName"::VARCHAR,
        mt."Category"::VARCHAR,
        mt."DefaultIntervalKm",
        mt."DefaultIntervalDays",
        mt."IsActive",
        mt."CreatedAt"
    FROM fleet."MaintenanceType" mt
    WHERE mt."CompanyId" = p_company_id
    ORDER BY mt."TypeName";
END;
$$;

-- usp_Fleet_MaintenanceType_Upsert
DROP FUNCTION IF EXISTS usp_fleet_maintenancetype_upsert(INT, INT, VARCHAR, VARCHAR, VARCHAR, NUMERIC, INT, BOOLEAN, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_fleet_maintenancetype_upsert(
    p_company_id           INT,
    p_maintenance_type_id  INT DEFAULT NULL,
    p_type_code            VARCHAR(20) DEFAULT NULL,
    p_type_name            VARCHAR(100) DEFAULT NULL,
    p_category             VARCHAR(50) DEFAULT NULL,
    p_default_interval_km  NUMERIC(12,2) DEFAULT NULL,
    p_default_interval_days INT DEFAULT NULL,
    p_is_active            BOOLEAN DEFAULT TRUE,
    p_user_id              INT DEFAULT NULL
)
RETURNS TABLE("ok" INT, "mensaje" VARCHAR)
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_maintenance_type_id IS NOT NULL AND EXISTS (SELECT 1 FROM fleet."MaintenanceType" WHERE "MaintenanceTypeId" = p_maintenance_type_id) THEN
        UPDATE fleet."MaintenanceType" SET
            "TypeCode"            = p_type_code,
            "TypeName"            = p_type_name,
            "Category"            = p_category,
            "DefaultIntervalKm"   = p_default_interval_km,
            "DefaultIntervalDays" = p_default_interval_days,
            "IsActive"            = p_is_active,
            "UpdatedAt"           = NOW() AT TIME ZONE 'UTC',
            "UpdatedBy"           = p_user_id
        WHERE "MaintenanceTypeId" = p_maintenance_type_id;

        RETURN QUERY SELECT 1, 'Tipo de mantenimiento actualizado'::VARCHAR;
    ELSE
        INSERT INTO fleet."MaintenanceType" (
            "CompanyId", "TypeCode", "TypeName", "Category",
            "DefaultIntervalKm", "DefaultIntervalDays", "IsActive",
            "CreatedAt", "CreatedBy"
        ) VALUES (
            p_company_id, p_type_code, p_type_name, p_category,
            p_default_interval_km, p_default_interval_days, p_is_active,
            NOW() AT TIME ZONE 'UTC', p_user_id
        );

        RETURN QUERY SELECT 1, 'Tipo de mantenimiento creado'::VARCHAR;
    END IF;

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -1, SQLERRM::VARCHAR;
END;
$$;

-- =============================================================================
--  SECCION 4: ORDENES DE MANTENIMIENTO
-- =============================================================================

-- usp_Fleet_MaintenanceOrder_List
DROP FUNCTION IF EXISTS usp_fleet_maintenanceorder_list(INT, INT, VARCHAR, INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_fleet_maintenanceorder_list(
    p_company_id  INT,
    p_vehicle_id  INT DEFAULT NULL,
    p_status      VARCHAR(20) DEFAULT NULL,
    p_page        INT DEFAULT 1,
    p_limit       INT DEFAULT 50
)
RETURNS TABLE(
    "MaintenanceOrderId"   INT,
    "OrderNumber"          VARCHAR,
    "VehicleId"            INT,
    "VehiclePlate"         VARCHAR,
    "MaintenanceTypeName"  VARCHAR,
    "MileageAtService"     NUMERIC,
    "ScheduledDate"        TIMESTAMP,
    "EstimatedCost"        NUMERIC,
    "ActualCost"           NUMERIC,
    "CompletedDate"        TIMESTAMP,
    "Status"               VARCHAR,
    "Description"          VARCHAR,
    "CreatedAt"            TIMESTAMP,
    "TotalCount"           INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_offset INT := (p_page - 1) * p_limit;
    v_total  INT;
BEGIN
    SELECT COUNT(*) INTO v_total
    FROM fleet."MaintenanceOrder" mo
    INNER JOIN fleet."Vehicle" v ON v."VehicleId" = mo."VehicleId"
    WHERE v."CompanyId" = p_company_id
      AND (p_vehicle_id IS NULL OR mo."VehicleId" = p_vehicle_id)
      AND (p_status IS NULL OR mo."Status" = p_status);

    RETURN QUERY
    SELECT
        mo."MaintenanceOrderId",
        mo."OrderNumber"::VARCHAR,
        mo."VehicleId",
        v."VehiclePlate"::VARCHAR,
        mt."TypeName"::VARCHAR,
        mo."MileageAtService",
        mo."ScheduledDate",
        mo."EstimatedCost",
        mo."ActualCost",
        mo."CompletedDate",
        mo."Status"::VARCHAR,
        mo."Description"::VARCHAR,
        mo."CreatedAt",
        v_total
    FROM fleet."MaintenanceOrder" mo
    INNER JOIN fleet."Vehicle" v ON v."VehicleId" = mo."VehicleId"
    INNER JOIN fleet."MaintenanceType" mt ON mt."MaintenanceTypeId" = mo."MaintenanceTypeId"
    WHERE v."CompanyId" = p_company_id
      AND (p_vehicle_id IS NULL OR mo."VehicleId" = p_vehicle_id)
      AND (p_status IS NULL OR mo."Status" = p_status)
    ORDER BY mo."ScheduledDate" DESC
    OFFSET v_offset LIMIT p_limit;
END;
$$;

-- usp_Fleet_MaintenanceOrder_Get
DROP FUNCTION IF EXISTS usp_fleet_maintenanceorder_get(INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_fleet_maintenanceorder_get(
    p_maintenance_order_id INT
)
RETURNS TABLE(
    "MaintenanceOrderId"   INT,
    "OrderNumber"          VARCHAR,
    "VehicleId"            INT,
    "VehiclePlate"         VARCHAR,
    "Brand"                VARCHAR,
    "Model"                VARCHAR,
    "MaintenanceTypeName"  VARCHAR,
    "Category"             VARCHAR,
    "MileageAtService"     NUMERIC,
    "ScheduledDate"        TIMESTAMP,
    "SupplierId"           INT,
    "EstimatedCost"        NUMERIC,
    "ActualCost"           NUMERIC,
    "CompletedDate"        TIMESTAMP,
    "Status"               VARCHAR,
    "Description"          VARCHAR,
    "BranchId"             INT,
    "CreatedAt"            TIMESTAMP,
    "UpdatedAt"            TIMESTAMP
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        mo."MaintenanceOrderId",
        mo."OrderNumber"::VARCHAR,
        mo."VehicleId",
        v."VehiclePlate"::VARCHAR,
        v."Brand"::VARCHAR,
        v."Model"::VARCHAR,
        mt."TypeName"::VARCHAR,
        mt."Category"::VARCHAR,
        mo."MileageAtService",
        mo."ScheduledDate",
        mo."SupplierId",
        mo."EstimatedCost",
        mo."ActualCost",
        mo."CompletedDate",
        mo."Status"::VARCHAR,
        mo."Description"::VARCHAR,
        mo."BranchId",
        mo."CreatedAt",
        mo."UpdatedAt"
    FROM fleet."MaintenanceOrder" mo
    INNER JOIN fleet."Vehicle" v ON v."VehicleId" = mo."VehicleId"
    INNER JOIN fleet."MaintenanceType" mt ON mt."MaintenanceTypeId" = mo."MaintenanceTypeId"
    WHERE mo."MaintenanceOrderId" = p_maintenance_order_id;
END;
$$;

-- usp_Fleet_MaintenanceOrder_Create
DROP FUNCTION IF EXISTS usp_fleet_maintenanceorder_create(INT, INT, INT, INT, NUMERIC, TIMESTAMP, INT, NUMERIC, VARCHAR, VARCHAR, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_fleet_maintenanceorder_create(
    p_company_id          INT,
    p_branch_id           INT,
    p_vehicle_id          INT,
    p_maintenance_type_id INT,
    p_mileage_at_service  NUMERIC(12,2),
    p_scheduled_date      TIMESTAMP,
    p_supplier_id         INT DEFAULT NULL,
    p_estimated_cost      NUMERIC(18,2) DEFAULT 0,
    p_description         VARCHAR(500) DEFAULT NULL,
    p_lines_json          VARCHAR DEFAULT NULL,
    p_user_id             INT DEFAULT NULL
)
RETURNS TABLE("ok" INT, "MaintenanceOrderId" INT, "OrderNumber" VARCHAR)
LANGUAGE plpgsql
AS $$
DECLARE
    v_id     INT;
    v_seq    INT;
    v_number VARCHAR(20);
BEGIN
    -- Generar numero de orden
    SELECT COALESCE(MAX(
        CAST(SUBSTRING(mo."OrderNumber" FROM 4) AS INT)
    ), 0) + 1 INTO v_seq
    FROM fleet."MaintenanceOrder" mo
    WHERE mo."VehicleId" = p_vehicle_id;

    v_number := 'MO-' || LPAD(v_seq::TEXT, 6, '0');

    INSERT INTO fleet."MaintenanceOrder" (
        "CompanyId", "BranchId", "VehicleId", "MaintenanceTypeId", "OrderNumber",
        "MileageAtService", "ScheduledDate", "SupplierId", "EstimatedCost",
        "Description", "Status", "CreatedAt", "CreatedBy"
    ) VALUES (
        p_company_id, p_branch_id, p_vehicle_id, p_maintenance_type_id, v_number,
        p_mileage_at_service, p_scheduled_date, p_supplier_id, p_estimated_cost,
        p_description, 'PENDING', NOW() AT TIME ZONE 'UTC', p_user_id
    ) RETURNING "MaintenanceOrderId" INTO v_id;

    -- Insertar lineas si vienen
    IF p_lines_json IS NOT NULL AND LENGTH(p_lines_json) > 2 THEN
        INSERT INTO fleet."MaintenanceOrderLine" (
            "MaintenanceOrderId", "Description", "PartNumber", "Quantity", "UnitCost", "TotalCost", "LineType"
        )
        SELECT
            v_id,
            (j->>'description')::VARCHAR,
            (j->>'partNumber')::VARCHAR,
            (j->>'quantity')::NUMERIC,
            (j->>'unitCost')::NUMERIC,
            (j->>'quantity')::NUMERIC * (j->>'unitCost')::NUMERIC,
            (j->>'lineType')::VARCHAR
        FROM jsonb_array_elements(p_lines_json::JSONB) AS j;
    END IF;

    RETURN QUERY SELECT 1, v_id, v_number;

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -1, 0, ''::VARCHAR;
END;
$$;

-- usp_Fleet_MaintenanceOrder_Complete
DROP FUNCTION IF EXISTS usp_fleet_maintenanceorder_complete(INT, NUMERIC, TIMESTAMP, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_fleet_maintenanceorder_complete(
    p_maintenance_order_id INT,
    p_actual_cost          NUMERIC(18,2),
    p_completed_date       TIMESTAMP,
    p_user_id              INT
)
RETURNS TABLE("ok" INT, "mensaje" VARCHAR)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM fleet."MaintenanceOrder" WHERE "MaintenanceOrderId" = p_maintenance_order_id AND "Status" IN ('PENDING', 'SCHEDULED', 'IN_PROGRESS')) THEN
        RETURN QUERY SELECT -1, 'Orden no encontrada o no se puede completar'::VARCHAR;
        RETURN;
    END IF;

    UPDATE fleet."MaintenanceOrder" SET
        "ActualCost"    = p_actual_cost,
        "CompletedDate" = p_completed_date,
        "Status"        = 'COMPLETED',
        "UpdatedAt"     = NOW() AT TIME ZONE 'UTC',
        "UpdatedBy"     = p_user_id
    WHERE "MaintenanceOrderId" = p_maintenance_order_id;

    RETURN QUERY SELECT 1, 'Orden completada'::VARCHAR;
END;
$$;

-- usp_Fleet_MaintenanceOrder_Cancel
DROP FUNCTION IF EXISTS usp_fleet_maintenanceorder_cancel(INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_fleet_maintenanceorder_cancel(
    p_maintenance_order_id INT,
    p_user_id              INT
)
RETURNS TABLE("ok" INT, "mensaje" VARCHAR)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM fleet."MaintenanceOrder" WHERE "MaintenanceOrderId" = p_maintenance_order_id AND "Status" IN ('PENDING', 'SCHEDULED')) THEN
        RETURN QUERY SELECT -1, 'Orden no encontrada o no se puede cancelar'::VARCHAR;
        RETURN;
    END IF;

    UPDATE fleet."MaintenanceOrder" SET
        "Status"    = 'CANCELLED',
        "UpdatedAt" = NOW() AT TIME ZONE 'UTC',
        "UpdatedBy" = p_user_id
    WHERE "MaintenanceOrderId" = p_maintenance_order_id;

    RETURN QUERY SELECT 1, 'Orden cancelada'::VARCHAR;
END;
$$;

-- =============================================================================
--  SECCION 5: VIAJES (Trips)
-- =============================================================================

-- usp_Fleet_Trip_List
DROP FUNCTION IF EXISTS usp_fleet_trip_list(INT, INT, VARCHAR, TIMESTAMP, TIMESTAMP, INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_fleet_trip_list(
    p_company_id  INT,
    p_vehicle_id  INT DEFAULT NULL,
    p_status      VARCHAR(20) DEFAULT NULL,
    p_fecha_desde TIMESTAMP DEFAULT NULL,
    p_fecha_hasta TIMESTAMP DEFAULT NULL,
    p_page        INT DEFAULT 1,
    p_limit       INT DEFAULT 50
)
RETURNS TABLE(
    "TripId"          INT,
    "TripNumber"      VARCHAR,
    "VehicleId"       INT,
    "VehiclePlate"    VARCHAR,
    "DriverId"        INT,
    "Origin"          VARCHAR,
    "Destination"     VARCHAR,
    "DepartureDate"   TIMESTAMP,
    "ArrivalDate"     TIMESTAMP,
    "StartMileage"    NUMERIC,
    "EndMileage"      NUMERIC,
    "FuelUsed"        NUMERIC,
    "DeliveryNoteId"  INT,
    "Status"          VARCHAR,
    "Notes"           VARCHAR,
    "CreatedAt"       TIMESTAMP,
    "TotalCount"      INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_offset INT := (p_page - 1) * p_limit;
    v_total  INT;
BEGIN
    SELECT COUNT(*) INTO v_total
    FROM fleet."Trip" t
    INNER JOIN fleet."Vehicle" v ON v."VehicleId" = t."VehicleId"
    WHERE v."CompanyId" = p_company_id
      AND (p_vehicle_id IS NULL OR t."VehicleId" = p_vehicle_id)
      AND (p_status IS NULL OR t."Status" = p_status)
      AND t."DepartureDate" >= p_fecha_desde
      AND t."DepartureDate" <= p_fecha_hasta;

    RETURN QUERY
    SELECT
        t."TripId",
        t."TripNumber"::VARCHAR,
        t."VehicleId",
        v."VehiclePlate"::VARCHAR,
        t."DriverId",
        t."Origin"::VARCHAR,
        t."Destination"::VARCHAR,
        t."DepartureDate",
        t."ArrivalDate",
        t."StartMileage",
        t."EndMileage",
        t."FuelUsed",
        t."DeliveryNoteId",
        t."Status"::VARCHAR,
        t."Notes"::VARCHAR,
        t."CreatedAt",
        v_total
    FROM fleet."Trip" t
    INNER JOIN fleet."Vehicle" v ON v."VehicleId" = t."VehicleId"
    WHERE v."CompanyId" = p_company_id
      AND (p_vehicle_id IS NULL OR t."VehicleId" = p_vehicle_id)
      AND (p_status IS NULL OR t."Status" = p_status)
      AND t."DepartureDate" >= p_fecha_desde
      AND t."DepartureDate" <= p_fecha_hasta
    ORDER BY t."DepartureDate" DESC
    OFFSET v_offset LIMIT p_limit;
END;
$$;

-- usp_Fleet_Trip_Create
DROP FUNCTION IF EXISTS usp_fleet_trip_create(INT, INT, INT, VARCHAR, VARCHAR, TIMESTAMP, NUMERIC, INT, VARCHAR, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_fleet_trip_create(
    p_company_id       INT,
    p_vehicle_id       INT,
    p_driver_id        INT DEFAULT NULL,
    p_origin           VARCHAR(200) DEFAULT NULL,
    p_destination      VARCHAR(200) DEFAULT NULL,
    p_departure_date   TIMESTAMP DEFAULT NULL,
    p_start_mileage    NUMERIC(12,2) DEFAULT 0,
    p_delivery_note_id INT DEFAULT NULL,
    p_notes            VARCHAR(500) DEFAULT NULL,
    p_user_id          INT DEFAULT NULL
)
RETURNS TABLE("ok" INT, "TripId" INT, "TripNumber" VARCHAR)
LANGUAGE plpgsql
AS $$
DECLARE
    v_id     INT;
    v_seq    INT;
    v_number VARCHAR(20);
BEGIN
    SELECT COALESCE(MAX(
        CAST(SUBSTRING(t."TripNumber" FROM 4) AS INT)
    ), 0) + 1 INTO v_seq
    FROM fleet."Trip" t
    INNER JOIN fleet."Vehicle" v ON v."VehicleId" = t."VehicleId"
    WHERE v."CompanyId" = p_company_id;

    v_number := 'TR-' || LPAD(v_seq::TEXT, 6, '0');

    INSERT INTO fleet."Trip" (
        "VehicleId", "DriverId", "TripNumber", "Origin", "Destination",
        "DepartureDate", "StartMileage", "DeliveryNoteId", "Notes",
        "Status", "CreatedAt", "CreatedBy"
    ) VALUES (
        p_vehicle_id, p_driver_id, v_number, p_origin, p_destination,
        p_departure_date, p_start_mileage, p_delivery_note_id, p_notes,
        'IN_PROGRESS', NOW() AT TIME ZONE 'UTC', p_user_id
    ) RETURNING "TripId" INTO v_id;

    RETURN QUERY SELECT 1, v_id, v_number;

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -1, 0, ''::VARCHAR;
END;
$$;

-- usp_Fleet_Trip_Complete
DROP FUNCTION IF EXISTS usp_fleet_trip_complete(INT, NUMERIC, TIMESTAMP, NUMERIC, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_fleet_trip_complete(
    p_trip_id      INT,
    p_end_mileage  NUMERIC(12,2),
    p_arrival_date TIMESTAMP,
    p_fuel_used    NUMERIC(10,3) DEFAULT NULL,
    p_user_id      INT DEFAULT NULL
)
RETURNS TABLE("ok" INT, "mensaje" VARCHAR)
LANGUAGE plpgsql
AS $$
DECLARE
    v_vehicle_id INT;
BEGIN
    SELECT "VehicleId" INTO v_vehicle_id
    FROM fleet."Trip"
    WHERE "TripId" = p_trip_id AND "Status" = 'IN_PROGRESS';

    IF v_vehicle_id IS NULL THEN
        RETURN QUERY SELECT -1, 'Viaje no encontrado o ya completado'::VARCHAR;
        RETURN;
    END IF;

    UPDATE fleet."Trip" SET
        "EndMileage"  = p_end_mileage,
        "ArrivalDate" = p_arrival_date,
        "FuelUsed"    = p_fuel_used,
        "Status"      = 'COMPLETED',
        "UpdatedAt"   = NOW() AT TIME ZONE 'UTC',
        "UpdatedBy"   = p_user_id
    WHERE "TripId" = p_trip_id;

    -- Actualizar kilometraje del vehiculo
    UPDATE fleet."Vehicle"
    SET "CurrentMileage" = p_end_mileage, "UpdatedAt" = NOW() AT TIME ZONE 'UTC', "UpdatedBy" = p_user_id
    WHERE "VehicleId" = v_vehicle_id AND "CurrentMileage" < p_end_mileage;

    RETURN QUERY SELECT 1, 'Viaje completado'::VARCHAR;
END;
$$;

-- =============================================================================
--  SECCION 6: DOCUMENTOS DE VEHICULO
-- =============================================================================

-- usp_Fleet_VehicleDocument_List
DROP FUNCTION IF EXISTS usp_fleet_vehicledocument_list(INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_fleet_vehicledocument_list(
    p_vehicle_id INT
)
RETURNS TABLE(
    "DocumentId"     INT,
    "VehicleId"      INT,
    "DocumentType"   VARCHAR,
    "DocumentNumber" VARCHAR,
    "IssueDate"      TIMESTAMP,
    "ExpiryDate"     TIMESTAMP,
    "FilePath"       VARCHAR,
    "Notes"          VARCHAR,
    "CreatedAt"      TIMESTAMP
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        d."DocumentId",
        d."VehicleId",
        d."DocumentType"::VARCHAR,
        d."DocumentNumber"::VARCHAR,
        d."IssueDate",
        d."ExpiryDate",
        d."FilePath"::VARCHAR,
        d."Notes"::VARCHAR,
        d."CreatedAt"
    FROM fleet."VehicleDocument" d
    WHERE d."VehicleId" = p_vehicle_id
    ORDER BY d."ExpiryDate" DESC;
END;
$$;

-- usp_Fleet_VehicleDocument_Upsert
DROP FUNCTION IF EXISTS usp_fleet_vehicledocument_upsert(INT, INT, INT, VARCHAR, VARCHAR, TIMESTAMP, TIMESTAMP, VARCHAR, VARCHAR, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_fleet_vehicledocument_upsert(
    p_company_id      INT,
    p_document_id     INT DEFAULT NULL,
    p_vehicle_id      INT DEFAULT NULL,
    p_document_type   VARCHAR(50) DEFAULT NULL,
    p_document_number VARCHAR(50) DEFAULT NULL,
    p_issue_date      TIMESTAMP DEFAULT NULL,
    p_expiry_date     TIMESTAMP DEFAULT NULL,
    p_file_path       VARCHAR(500) DEFAULT NULL,
    p_notes           VARCHAR(500) DEFAULT NULL,
    p_user_id         INT DEFAULT NULL
)
RETURNS TABLE("ok" INT, "mensaje" VARCHAR)
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_document_id IS NOT NULL AND EXISTS (SELECT 1 FROM fleet."VehicleDocument" WHERE "DocumentId" = p_document_id) THEN
        UPDATE fleet."VehicleDocument" SET
            "DocumentType"   = p_document_type,
            "DocumentNumber" = p_document_number,
            "IssueDate"      = p_issue_date,
            "ExpiryDate"     = p_expiry_date,
            "FilePath"       = p_file_path,
            "Notes"          = p_notes,
            "UpdatedAt"      = NOW() AT TIME ZONE 'UTC',
            "UpdatedBy"      = p_user_id
        WHERE "DocumentId" = p_document_id;

        RETURN QUERY SELECT 1, 'Documento actualizado'::VARCHAR;
    ELSE
        INSERT INTO fleet."VehicleDocument" (
            "VehicleId", "DocumentType", "DocumentNumber", "IssueDate", "ExpiryDate",
            "FilePath", "Notes", "CreatedAt", "CreatedBy"
        ) VALUES (
            p_vehicle_id, p_document_type, p_document_number, p_issue_date, p_expiry_date,
            p_file_path, p_notes, NOW() AT TIME ZONE 'UTC', p_user_id
        );

        RETURN QUERY SELECT 1, 'Documento creado'::VARCHAR;
    END IF;

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -1, SQLERRM::VARCHAR;
END;
$$;

-- =============================================================================
--  SECCION 7: DASHBOARD
-- =============================================================================

-- usp_Fleet_Dashboard
DROP FUNCTION IF EXISTS usp_fleet_dashboard(INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_fleet_dashboard(
    p_company_id INT
)
RETURNS TABLE(
    "TotalActiveVehicles" INT,
    "TotalVehicles"       INT,
    "DocsExpiringSoon"    INT,
    "MaintenancePending"  INT,
    "FuelCostThisMonth"   NUMERIC,
    "ActiveTrips"         INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_now        TIMESTAMP := NOW() AT TIME ZONE 'UTC';
    v_in30days   TIMESTAMP := (NOW() AT TIME ZONE 'UTC') + INTERVAL '30 days';
    v_month_start TIMESTAMP := DATE_TRUNC('month', NOW() AT TIME ZONE 'UTC');
BEGIN
    RETURN QUERY
    SELECT
        (SELECT COUNT(*)::INT FROM fleet."Vehicle" WHERE "CompanyId" = p_company_id AND "IsActive" = TRUE),
        (SELECT COUNT(*)::INT FROM fleet."Vehicle" WHERE "CompanyId" = p_company_id),
        (SELECT COUNT(*)::INT FROM fleet."VehicleDocument" vd
         INNER JOIN fleet."Vehicle" v ON v."VehicleId" = vd."VehicleId"
         WHERE v."CompanyId" = p_company_id AND vd."ExpiryDate" <= v_in30days AND vd."ExpiryDate" >= v_now
        ),
        (SELECT COUNT(*)::INT FROM fleet."MaintenanceOrder" mo
         INNER JOIN fleet."Vehicle" v ON v."VehicleId" = mo."VehicleId"
         WHERE v."CompanyId" = p_company_id AND mo."Status" IN ('PENDING', 'SCHEDULED')
        ),
        (SELECT COALESCE(SUM(fl."TotalCost"), 0) FROM fleet."FuelLog" fl
         INNER JOIN fleet."Vehicle" v ON v."VehicleId" = fl."VehicleId"
         WHERE v."CompanyId" = p_company_id AND fl."LogDate" >= v_month_start
        ),
        (SELECT COUNT(*)::INT FROM fleet."Trip" t
         INNER JOIN fleet."Vehicle" v ON v."VehicleId" = t."VehicleId"
         WHERE v."CompanyId" = p_company_id AND t."Status" = 'IN_PROGRESS'
        );
END;
$$;
