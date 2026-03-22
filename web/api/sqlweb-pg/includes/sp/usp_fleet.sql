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
 *
 *  Columnas reales de tablas fleet.* (produccion):
 *    Vehicle: VehicleId, CompanyId, VehicleCode, LicensePlate, VehicleType, Brand, Model,
 *             Year, Color, VinNumber, EngineNumber, FuelType, TankCapacity, CurrentOdometer,
 *             OdometerUnit, DefaultDriverId, WarehouseId, PurchaseDate, PurchaseCost,
 *             InsurancePolicy, InsuranceExpiry, Status, Notes, IsActive, CreatedAt, UpdatedAt,
 *             CreatedByUserId, UpdatedByUserId, IsDeleted, DeletedAt, DeletedByUserId
 *    FuelLog: FuelLogId, CompanyId, VehicleId, DriverId, FuelDate, FuelType, Quantity,
 *             UnitPrice, TotalCost, CurrencyCode, OdometerReading, IsFullTank, StationName,
 *             InvoiceNumber, Notes, CreatedAt, UpdatedAt, CreatedByUserId, UpdatedByUserId,
 *             IsDeleted, DeletedAt, DeletedByUserId
 *    MaintenanceType: MaintenanceTypeId, CompanyId, TypeCode, TypeName, Category,
 *             DefaultIntervalKm, DefaultIntervalDays, IsActive, CreatedAt, UpdatedAt,
 *             CreatedByUserId, UpdatedByUserId, IsDeleted, DeletedAt, DeletedByUserId
 *    MaintenanceOrder: MaintenanceOrderId, CompanyId, VehicleId, MaintenanceTypeId,
 *             OrderNumber, OrderDate, OdometerAtService, Status, Priority, ScheduledDate,
 *             StartedAt, CompletedAt, WorkshopName, TechnicianName, TotalLaborCost,
 *             TotalPartsCost, TotalCost, CurrencyCode, Notes, CreatedAt, UpdatedAt,
 *             CreatedByUserId, UpdatedByUserId, IsDeleted, DeletedAt, DeletedByUserId
 *    MaintenanceOrderLine: MaintenanceOrderLineId, MaintenanceOrderId, LineNumber,
 *             LineType, ProductId, Description, Quantity, UnitCost, TotalCost, Notes,
 *             CreatedAt, UpdatedAt
 *    Trip: TripId, CompanyId, VehicleId, DriverId, DeliveryNoteId, TripNumber, TripDate,
 *             Origin, Destination, DistanceKm, OdometerStart, OdometerEnd, DepartedAt,
 *             ArrivedAt, Status, Notes, CreatedAt, UpdatedAt, CreatedByUserId,
 *             UpdatedByUserId, IsDeleted, DeletedAt, DeletedByUserId
 *    VehicleDocument: VehicleDocumentId, VehicleId, DocumentType, DocumentNumber,
 *             Description, IssuedAt, ExpiresAt, FileUrl, Notes, CreatedAt, UpdatedAt,
 *             CreatedByUserId, UpdatedByUserId, IsDeleted, DeletedAt, DeletedByUserId
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
    "LicensePlate"           VARCHAR,
    "VinNumber"              VARCHAR,
    "Brand"                  VARCHAR,
    "Model"                  VARCHAR,
    "Year"                   INT,
    "Color"                  VARCHAR,
    "VehicleType"            VARCHAR,
    "FuelType"               VARCHAR,
    "CurrentOdometer"        NUMERIC,
    "OdometerUnit"           VARCHAR,
    "IsActive"               BOOLEAN,
    "DefaultDriverId"        INT,
    "WarehouseId"            INT,
    "InsuranceExpiry"        TIMESTAMP,
    "Status"                 VARCHAR,
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
    FROM fleet."Vehicle" v
    WHERE v."CompanyId" = p_company_id
      AND v."IsDeleted" IS NOT TRUE
      AND (p_status IS NULL OR (
            (p_status = 'ACTIVE' AND v."IsActive" = TRUE)
            OR (p_status = 'INACTIVE' AND v."IsActive" = FALSE)
          ))
      AND (p_vehicle_type IS NULL OR v."VehicleType" = p_vehicle_type)
      AND (p_search IS NULL OR (
            v."LicensePlate" ILIKE '%' || p_search || '%'
            OR v."Brand" ILIKE '%' || p_search || '%'
            OR v."Model" ILIKE '%' || p_search || '%'
            OR v."VinNumber" ILIKE '%' || p_search || '%'
          ));

    RETURN QUERY
    SELECT
        v."VehicleId",
        v."LicensePlate"::VARCHAR,
        v."VinNumber"::VARCHAR,
        v."Brand"::VARCHAR,
        v."Model"::VARCHAR,
        v."Year",
        v."Color"::VARCHAR,
        v."VehicleType"::VARCHAR,
        v."FuelType"::VARCHAR,
        v."CurrentOdometer",
        v."OdometerUnit"::VARCHAR,
        v."IsActive",
        v."DefaultDriverId",
        v."WarehouseId",
        v."InsuranceExpiry",
        v."Status"::VARCHAR,
        v."CreatedAt",
        v_total
    FROM fleet."Vehicle" v
    WHERE v."CompanyId" = p_company_id
      AND v."IsDeleted" IS NOT TRUE
      AND (p_status IS NULL OR (
            (p_status = 'ACTIVE' AND v."IsActive" = TRUE)
            OR (p_status = 'INACTIVE' AND v."IsActive" = FALSE)
          ))
      AND (p_vehicle_type IS NULL OR v."VehicleType" = p_vehicle_type)
      AND (p_search IS NULL OR (
            v."LicensePlate" ILIKE '%' || p_search || '%'
            OR v."Brand" ILIKE '%' || p_search || '%'
            OR v."Model" ILIKE '%' || p_search || '%'
            OR v."VinNumber" ILIKE '%' || p_search || '%'
          ))
    ORDER BY v."LicensePlate"
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
    "VehicleCode"            VARCHAR,
    "LicensePlate"           VARCHAR,
    "VinNumber"              VARCHAR,
    "EngineNumber"           VARCHAR,
    "Brand"                  VARCHAR,
    "Model"                  VARCHAR,
    "Year"                   INT,
    "Color"                  VARCHAR,
    "VehicleType"            VARCHAR,
    "FuelType"               VARCHAR,
    "TankCapacity"           NUMERIC,
    "CurrentOdometer"        NUMERIC,
    "OdometerUnit"           VARCHAR,
    "PurchaseDate"           TIMESTAMP,
    "PurchaseCost"           NUMERIC,
    "InsurancePolicy"        VARCHAR,
    "InsuranceExpiry"        TIMESTAMP,
    "DefaultDriverId"        INT,
    "WarehouseId"            INT,
    "Status"                 VARCHAR,
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
        v."VehicleCode"::VARCHAR,
        v."LicensePlate"::VARCHAR,
        v."VinNumber"::VARCHAR,
        v."EngineNumber"::VARCHAR,
        v."Brand"::VARCHAR,
        v."Model"::VARCHAR,
        v."Year",
        v."Color"::VARCHAR,
        v."VehicleType"::VARCHAR,
        v."FuelType"::VARCHAR,
        v."TankCapacity",
        v."CurrentOdometer",
        v."OdometerUnit"::VARCHAR,
        v."PurchaseDate",
        v."PurchaseCost",
        v."InsurancePolicy"::VARCHAR,
        v."InsuranceExpiry",
        v."DefaultDriverId",
        v."WarehouseId",
        v."Status"::VARCHAR,
        v."Notes"::VARCHAR,
        v."IsActive",
        v."CreatedAt",
        v."UpdatedAt"
    FROM fleet."Vehicle" v
    WHERE v."VehicleId" = p_vehicle_id
      AND v."IsDeleted" IS NOT TRUE;
END;
$$;

-- usp_Fleet_Vehicle_Upsert
DROP FUNCTION IF EXISTS usp_fleet_vehicle_upsert(INT, INT, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, INT, VARCHAR, VARCHAR, VARCHAR, NUMERIC, NUMERIC, VARCHAR, TIMESTAMP, NUMERIC, VARCHAR, TIMESTAMP, INT, INT, VARCHAR, VARCHAR, BOOLEAN, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_fleet_vehicle_upsert(
    p_company_id              INT,
    p_vehicle_id              INT DEFAULT NULL,
    p_vehicle_code            VARCHAR(20) DEFAULT NULL,
    p_license_plate           VARCHAR(20) DEFAULT NULL,
    p_vin_number              VARCHAR(50) DEFAULT NULL,
    p_engine_number           VARCHAR(50) DEFAULT NULL,
    p_brand                   VARCHAR(50) DEFAULT NULL,
    p_model                   VARCHAR(50) DEFAULT NULL,
    p_vehicle_type            VARCHAR(30) DEFAULT NULL,
    p_year                    INT DEFAULT NULL,
    p_color                   VARCHAR(30) DEFAULT NULL,
    p_fuel_type               VARCHAR(20) DEFAULT NULL,
    p_tank_capacity           NUMERIC(10,2) DEFAULT NULL,
    p_current_odometer        NUMERIC(12,2) DEFAULT 0,
    p_odometer_unit           VARCHAR(10) DEFAULT 'km',
    p_purchase_date           TIMESTAMP DEFAULT NULL,
    p_purchase_cost           NUMERIC(18,2) DEFAULT NULL,
    p_insurance_policy        VARCHAR(100) DEFAULT NULL,
    p_insurance_expiry        TIMESTAMP DEFAULT NULL,
    p_default_driver_id       INT DEFAULT NULL,
    p_warehouse_id            INT DEFAULT NULL,
    p_status                  VARCHAR(20) DEFAULT 'ACTIVE',
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
    IF p_vehicle_id IS NOT NULL AND EXISTS (SELECT 1 FROM fleet."Vehicle" WHERE "VehicleId" = p_vehicle_id AND "IsDeleted" IS NOT TRUE) THEN
        UPDATE fleet."Vehicle" SET
            "VehicleCode"            = COALESCE(p_vehicle_code, "VehicleCode"),
            "LicensePlate"           = p_license_plate,
            "VinNumber"              = p_vin_number,
            "EngineNumber"           = p_engine_number,
            "Brand"                  = p_brand,
            "Model"                  = p_model,
            "VehicleType"            = p_vehicle_type,
            "Year"                   = p_year,
            "Color"                  = p_color,
            "FuelType"               = p_fuel_type,
            "TankCapacity"           = p_tank_capacity,
            "CurrentOdometer"        = p_current_odometer,
            "OdometerUnit"           = p_odometer_unit,
            "PurchaseDate"           = p_purchase_date,
            "PurchaseCost"           = p_purchase_cost,
            "InsurancePolicy"        = p_insurance_policy,
            "InsuranceExpiry"        = p_insurance_expiry,
            "DefaultDriverId"        = p_default_driver_id,
            "WarehouseId"            = p_warehouse_id,
            "Status"                 = p_status,
            "Notes"                  = p_notes,
            "IsActive"               = p_is_active,
            "UpdatedAt"              = NOW() AT TIME ZONE 'UTC',
            "UpdatedByUserId"        = p_user_id
        WHERE "VehicleId" = p_vehicle_id;
        v_id := p_vehicle_id;
    ELSE
        INSERT INTO fleet."Vehicle" (
            "CompanyId", "VehicleCode", "LicensePlate", "VinNumber", "EngineNumber",
            "Brand", "Model", "VehicleType", "Year", "Color",
            "FuelType", "TankCapacity", "CurrentOdometer", "OdometerUnit",
            "PurchaseDate", "PurchaseCost",
            "InsurancePolicy", "InsuranceExpiry",
            "DefaultDriverId", "WarehouseId", "Status", "Notes", "IsActive",
            "CreatedAt", "CreatedByUserId"
        ) VALUES (
            p_company_id, p_vehicle_code, p_license_plate, p_vin_number, p_engine_number,
            p_brand, p_model, p_vehicle_type, p_year, p_color,
            p_fuel_type, p_tank_capacity, p_current_odometer, p_odometer_unit,
            p_purchase_date, p_purchase_cost,
            p_insurance_policy, p_insurance_expiry,
            p_default_driver_id, p_warehouse_id, p_status, p_notes, p_is_active,
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
    "FuelLogId"       INT,
    "VehicleId"       INT,
    "LicensePlate"    VARCHAR,
    "FuelDate"        TIMESTAMP,
    "OdometerReading" NUMERIC,
    "FuelType"        VARCHAR,
    "Quantity"        NUMERIC,
    "UnitPrice"       NUMERIC,
    "TotalCost"       NUMERIC,
    "CurrencyCode"    VARCHAR,
    "IsFullTank"      BOOLEAN,
    "StationName"     VARCHAR,
    "DriverId"        INT,
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
    FROM fleet."FuelLog" fl
    INNER JOIN fleet."Vehicle" v ON v."VehicleId" = fl."VehicleId"
    WHERE fl."CompanyId" = p_company_id
      AND fl."IsDeleted" IS NOT TRUE
      AND (p_vehicle_id IS NULL OR fl."VehicleId" = p_vehicle_id)
      AND (p_fecha_desde IS NULL OR fl."FuelDate" >= p_fecha_desde)
      AND (p_fecha_hasta IS NULL OR fl."FuelDate" <= p_fecha_hasta);

    RETURN QUERY
    SELECT
        fl."FuelLogId",
        fl."VehicleId",
        v."LicensePlate"::VARCHAR,
        fl."FuelDate",
        fl."OdometerReading",
        fl."FuelType"::VARCHAR,
        fl."Quantity",
        fl."UnitPrice",
        fl."TotalCost",
        fl."CurrencyCode"::VARCHAR,
        fl."IsFullTank",
        fl."StationName"::VARCHAR,
        fl."DriverId",
        fl."Notes"::VARCHAR,
        fl."CreatedAt",
        v_total
    FROM fleet."FuelLog" fl
    INNER JOIN fleet."Vehicle" v ON v."VehicleId" = fl."VehicleId"
    WHERE fl."CompanyId" = p_company_id
      AND fl."IsDeleted" IS NOT TRUE
      AND (p_vehicle_id IS NULL OR fl."VehicleId" = p_vehicle_id)
      AND (p_fecha_desde IS NULL OR fl."FuelDate" >= p_fecha_desde)
      AND (p_fecha_hasta IS NULL OR fl."FuelDate" <= p_fecha_hasta)
    ORDER BY fl."FuelDate" DESC
    OFFSET v_offset LIMIT p_limit;
END;
$$;

-- usp_Fleet_FuelLog_Create
DROP FUNCTION IF EXISTS usp_fleet_fuellog_create(INT, INT, TIMESTAMP, NUMERIC, VARCHAR, NUMERIC, NUMERIC, NUMERIC, VARCHAR, BOOLEAN, VARCHAR, INT, VARCHAR, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_fleet_fuellog_create(
    p_company_id      INT,
    p_vehicle_id      INT,
    p_fuel_date       TIMESTAMP,
    p_odometer_reading NUMERIC(12,2),
    p_fuel_type       VARCHAR(20),
    p_quantity        NUMERIC(10,3),
    p_unit_price      NUMERIC(10,4),
    p_total_cost      NUMERIC(18,2),
    p_currency_code   VARCHAR(10) DEFAULT NULL,
    p_is_full_tank    BOOLEAN DEFAULT FALSE,
    p_station_name    VARCHAR(100) DEFAULT NULL,
    p_driver_id       INT DEFAULT NULL,
    p_notes           VARCHAR(500) DEFAULT NULL,
    p_user_id         INT DEFAULT NULL
)
RETURNS TABLE("ok" INT, "FuelLogId" INT)
LANGUAGE plpgsql
AS $$
DECLARE
    v_id INT;
BEGIN
    INSERT INTO fleet."FuelLog" (
        "CompanyId", "VehicleId", "FuelDate", "OdometerReading", "FuelType",
        "Quantity", "UnitPrice", "TotalCost", "CurrencyCode", "IsFullTank",
        "StationName", "DriverId", "Notes", "CreatedAt", "CreatedByUserId"
    ) VALUES (
        p_company_id, p_vehicle_id, p_fuel_date, p_odometer_reading, p_fuel_type,
        p_quantity, p_unit_price, p_total_cost, p_currency_code, p_is_full_tank,
        p_station_name, p_driver_id, p_notes, NOW() AT TIME ZONE 'UTC', p_user_id
    ) RETURNING "FuelLogId" INTO v_id;

    -- Actualizar odometro si es mayor al actual
    UPDATE fleet."Vehicle"
    SET "CurrentOdometer" = p_odometer_reading,
        "UpdatedAt" = NOW() AT TIME ZONE 'UTC',
        "UpdatedByUserId" = p_user_id
    WHERE "VehicleId" = p_vehicle_id AND "CurrentOdometer" < p_odometer_reading;

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
    "MaintenanceTypeId"   INT,
    "TypeCode"            VARCHAR,
    "TypeName"            VARCHAR,
    "Category"            VARCHAR,
    "DefaultIntervalKm"   NUMERIC,
    "DefaultIntervalDays" INT,
    "IsActive"            BOOLEAN,
    "CreatedAt"           TIMESTAMP
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
      AND mt."IsDeleted" IS NOT TRUE
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
    IF p_maintenance_type_id IS NOT NULL AND EXISTS (SELECT 1 FROM fleet."MaintenanceType" WHERE "MaintenanceTypeId" = p_maintenance_type_id AND "IsDeleted" IS NOT TRUE) THEN
        UPDATE fleet."MaintenanceType" SET
            "TypeCode"            = p_type_code,
            "TypeName"            = p_type_name,
            "Category"            = p_category,
            "DefaultIntervalKm"   = p_default_interval_km,
            "DefaultIntervalDays" = p_default_interval_days,
            "IsActive"            = p_is_active,
            "UpdatedAt"           = NOW() AT TIME ZONE 'UTC',
            "UpdatedByUserId"     = p_user_id
        WHERE "MaintenanceTypeId" = p_maintenance_type_id;

        RETURN QUERY SELECT 1, 'Tipo de mantenimiento actualizado'::VARCHAR;
    ELSE
        INSERT INTO fleet."MaintenanceType" (
            "CompanyId", "TypeCode", "TypeName", "Category",
            "DefaultIntervalKm", "DefaultIntervalDays", "IsActive",
            "CreatedAt", "CreatedByUserId"
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
    "LicensePlate"         VARCHAR,
    "MaintenanceTypeName"  VARCHAR,
    "OdometerAtService"    NUMERIC,
    "ScheduledDate"        TIMESTAMP,
    "TotalLaborCost"       NUMERIC,
    "TotalPartsCost"       NUMERIC,
    "TotalCost"            NUMERIC,
    "CompletedAt"          TIMESTAMP,
    "Status"               VARCHAR,
    "Priority"             VARCHAR,
    "Notes"                VARCHAR,
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
    WHERE mo."CompanyId" = p_company_id
      AND mo."IsDeleted" IS NOT TRUE
      AND (p_vehicle_id IS NULL OR mo."VehicleId" = p_vehicle_id)
      AND (p_status IS NULL OR mo."Status" = p_status);

    RETURN QUERY
    SELECT
        mo."MaintenanceOrderId",
        mo."OrderNumber"::VARCHAR,
        mo."VehicleId",
        v."LicensePlate"::VARCHAR,
        mt."TypeName"::VARCHAR,
        mo."OdometerAtService",
        mo."ScheduledDate",
        mo."TotalLaborCost",
        mo."TotalPartsCost",
        mo."TotalCost",
        mo."CompletedAt",
        mo."Status"::VARCHAR,
        mo."Priority"::VARCHAR,
        mo."Notes"::VARCHAR,
        mo."CreatedAt",
        v_total
    FROM fleet."MaintenanceOrder" mo
    INNER JOIN fleet."Vehicle" v ON v."VehicleId" = mo."VehicleId"
    LEFT JOIN fleet."MaintenanceType" mt ON mt."MaintenanceTypeId" = mo."MaintenanceTypeId"
    WHERE mo."CompanyId" = p_company_id
      AND mo."IsDeleted" IS NOT TRUE
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
    "OrderDate"            TIMESTAMP,
    "VehicleId"            INT,
    "LicensePlate"         VARCHAR,
    "Brand"                VARCHAR,
    "Model"                VARCHAR,
    "MaintenanceTypeId"    INT,
    "MaintenanceTypeName"  VARCHAR,
    "Category"             VARCHAR,
    "OdometerAtService"    NUMERIC,
    "ScheduledDate"        TIMESTAMP,
    "StartedAt"            TIMESTAMP,
    "CompletedAt"          TIMESTAMP,
    "WorkshopName"         VARCHAR,
    "TechnicianName"       VARCHAR,
    "TotalLaborCost"       NUMERIC,
    "TotalPartsCost"       NUMERIC,
    "TotalCost"            NUMERIC,
    "CurrencyCode"         VARCHAR,
    "Status"               VARCHAR,
    "Priority"             VARCHAR,
    "Notes"                VARCHAR,
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
        mo."OrderDate",
        mo."VehicleId",
        v."LicensePlate"::VARCHAR,
        v."Brand"::VARCHAR,
        v."Model"::VARCHAR,
        mo."MaintenanceTypeId",
        mt."TypeName"::VARCHAR,
        mt."Category"::VARCHAR,
        mo."OdometerAtService",
        mo."ScheduledDate",
        mo."StartedAt",
        mo."CompletedAt",
        mo."WorkshopName"::VARCHAR,
        mo."TechnicianName"::VARCHAR,
        mo."TotalLaborCost",
        mo."TotalPartsCost",
        mo."TotalCost",
        mo."CurrencyCode"::VARCHAR,
        mo."Status"::VARCHAR,
        mo."Priority"::VARCHAR,
        mo."Notes"::VARCHAR,
        mo."CreatedAt",
        mo."UpdatedAt"
    FROM fleet."MaintenanceOrder" mo
    INNER JOIN fleet."Vehicle" v ON v."VehicleId" = mo."VehicleId"
    LEFT JOIN fleet."MaintenanceType" mt ON mt."MaintenanceTypeId" = mo."MaintenanceTypeId"
    WHERE mo."MaintenanceOrderId" = p_maintenance_order_id
      AND mo."IsDeleted" IS NOT TRUE;
END;
$$;

-- usp_Fleet_MaintenanceOrder_Create
DROP FUNCTION IF EXISTS usp_fleet_maintenanceorder_create(INT, INT, INT, NUMERIC, TIMESTAMP, VARCHAR, VARCHAR, NUMERIC, VARCHAR, VARCHAR, VARCHAR, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_fleet_maintenanceorder_create(
    p_company_id          INT,
    p_vehicle_id          INT,
    p_maintenance_type_id INT,
    p_odometer_at_service NUMERIC(12,2),
    p_scheduled_date      TIMESTAMP,
    p_priority            VARCHAR(20) DEFAULT 'NORMAL',
    p_workshop_name       VARCHAR(200) DEFAULT NULL,
    p_estimated_cost      NUMERIC(18,2) DEFAULT 0,
    p_currency_code       VARCHAR(10) DEFAULT NULL,
    p_notes               VARCHAR(500) DEFAULT NULL,
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
    WHERE mo."CompanyId" = p_company_id;

    v_number := 'MO-' || LPAD(v_seq::TEXT, 6, '0');

    INSERT INTO fleet."MaintenanceOrder" (
        "CompanyId", "VehicleId", "MaintenanceTypeId", "OrderNumber",
        "OrderDate", "OdometerAtService", "ScheduledDate", "Priority",
        "WorkshopName", "TotalCost", "CurrencyCode",
        "Notes", "Status", "CreatedAt", "CreatedByUserId"
    ) VALUES (
        p_company_id, p_vehicle_id, p_maintenance_type_id, v_number,
        NOW() AT TIME ZONE 'UTC', p_odometer_at_service, p_scheduled_date, p_priority,
        p_workshop_name, p_estimated_cost, p_currency_code,
        p_notes, 'PENDING', NOW() AT TIME ZONE 'UTC', p_user_id
    ) RETURNING "MaintenanceOrderId" INTO v_id;

    -- Insertar lineas si vienen
    IF p_lines_json IS NOT NULL AND LENGTH(p_lines_json) > 2 THEN
        INSERT INTO fleet."MaintenanceOrderLine" (
            "MaintenanceOrderId", "LineNumber", "LineType", "ProductId",
            "Description", "Quantity", "UnitCost", "TotalCost"
        )
        SELECT
            v_id,
            ROW_NUMBER() OVER ()::INT,
            (j->>'lineType')::VARCHAR,
            (j->>'productId')::INT,
            (j->>'description')::VARCHAR,
            (j->>'quantity')::NUMERIC,
            (j->>'unitCost')::NUMERIC,
            (j->>'quantity')::NUMERIC * (j->>'unitCost')::NUMERIC
        FROM jsonb_array_elements(p_lines_json::JSONB) AS j;
    END IF;

    RETURN QUERY SELECT 1, v_id, v_number;

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -1, 0, ''::VARCHAR;
END;
$$;

-- usp_Fleet_MaintenanceOrder_Complete
DROP FUNCTION IF EXISTS usp_fleet_maintenanceorder_complete(INT, NUMERIC, NUMERIC, NUMERIC, TIMESTAMP, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_fleet_maintenanceorder_complete(
    p_maintenance_order_id INT,
    p_total_labor_cost     NUMERIC(18,2) DEFAULT 0,
    p_total_parts_cost     NUMERIC(18,2) DEFAULT 0,
    p_total_cost           NUMERIC(18,2) DEFAULT 0,
    p_completed_at         TIMESTAMP DEFAULT NULL,
    p_user_id              INT DEFAULT NULL
)
RETURNS TABLE("ok" INT, "mensaje" VARCHAR)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM fleet."MaintenanceOrder" WHERE "MaintenanceOrderId" = p_maintenance_order_id AND "Status" IN ('PENDING', 'SCHEDULED', 'IN_PROGRESS') AND "IsDeleted" IS NOT TRUE) THEN
        RETURN QUERY SELECT -1, 'Orden no encontrada o no se puede completar'::VARCHAR;
        RETURN;
    END IF;

    UPDATE fleet."MaintenanceOrder" SET
        "TotalLaborCost" = p_total_labor_cost,
        "TotalPartsCost" = p_total_parts_cost,
        "TotalCost"      = p_total_cost,
        "CompletedAt"    = COALESCE(p_completed_at, NOW() AT TIME ZONE 'UTC'),
        "Status"         = 'COMPLETED',
        "UpdatedAt"      = NOW() AT TIME ZONE 'UTC',
        "UpdatedByUserId" = p_user_id
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
    IF NOT EXISTS (SELECT 1 FROM fleet."MaintenanceOrder" WHERE "MaintenanceOrderId" = p_maintenance_order_id AND "Status" IN ('PENDING', 'SCHEDULED') AND "IsDeleted" IS NOT TRUE) THEN
        RETURN QUERY SELECT -1, 'Orden no encontrada o no se puede cancelar'::VARCHAR;
        RETURN;
    END IF;

    UPDATE fleet."MaintenanceOrder" SET
        "Status"          = 'CANCELLED',
        "UpdatedAt"       = NOW() AT TIME ZONE 'UTC',
        "UpdatedByUserId" = p_user_id
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
    "TripDate"        TIMESTAMP,
    "VehicleId"       INT,
    "LicensePlate"    VARCHAR,
    "DriverId"        INT,
    "Origin"          VARCHAR,
    "Destination"     VARCHAR,
    "DistanceKm"      NUMERIC,
    "DepartedAt"      TIMESTAMP,
    "ArrivedAt"       TIMESTAMP,
    "OdometerStart"   NUMERIC,
    "OdometerEnd"     NUMERIC,
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
    WHERE t."CompanyId" = p_company_id
      AND t."IsDeleted" IS NOT TRUE
      AND (p_vehicle_id IS NULL OR t."VehicleId" = p_vehicle_id)
      AND (p_status IS NULL OR t."Status" = p_status)
      AND (p_fecha_desde IS NULL OR t."DepartedAt" >= p_fecha_desde)
      AND (p_fecha_hasta IS NULL OR t."DepartedAt" <= p_fecha_hasta);

    RETURN QUERY
    SELECT
        t."TripId",
        t."TripNumber"::VARCHAR,
        t."TripDate",
        t."VehicleId",
        v."LicensePlate"::VARCHAR,
        t."DriverId",
        t."Origin"::VARCHAR,
        t."Destination"::VARCHAR,
        t."DistanceKm",
        t."DepartedAt",
        t."ArrivedAt",
        t."OdometerStart",
        t."OdometerEnd",
        t."DeliveryNoteId",
        t."Status"::VARCHAR,
        t."Notes"::VARCHAR,
        t."CreatedAt",
        v_total
    FROM fleet."Trip" t
    INNER JOIN fleet."Vehicle" v ON v."VehicleId" = t."VehicleId"
    WHERE t."CompanyId" = p_company_id
      AND t."IsDeleted" IS NOT TRUE
      AND (p_vehicle_id IS NULL OR t."VehicleId" = p_vehicle_id)
      AND (p_status IS NULL OR t."Status" = p_status)
      AND (p_fecha_desde IS NULL OR t."DepartedAt" >= p_fecha_desde)
      AND (p_fecha_hasta IS NULL OR t."DepartedAt" <= p_fecha_hasta)
    ORDER BY t."DepartedAt" DESC
    OFFSET v_offset LIMIT p_limit;
END;
$$;

-- usp_Fleet_Trip_Create
DROP FUNCTION IF EXISTS usp_fleet_trip_create(INT, INT, INT, VARCHAR, VARCHAR, TIMESTAMP, TIMESTAMP, NUMERIC, INT, VARCHAR, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_fleet_trip_create(
    p_company_id       INT,
    p_vehicle_id       INT,
    p_driver_id        INT DEFAULT NULL,
    p_origin           VARCHAR(200) DEFAULT NULL,
    p_destination      VARCHAR(200) DEFAULT NULL,
    p_trip_date        TIMESTAMP DEFAULT NULL,
    p_departed_at      TIMESTAMP DEFAULT NULL,
    p_odometer_start   NUMERIC(12,2) DEFAULT 0,
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
    WHERE t."CompanyId" = p_company_id;

    v_number := 'TR-' || LPAD(v_seq::TEXT, 6, '0');

    INSERT INTO fleet."Trip" (
        "CompanyId", "VehicleId", "DriverId", "TripNumber", "TripDate",
        "Origin", "Destination", "DepartedAt", "OdometerStart",
        "DeliveryNoteId", "Notes",
        "Status", "CreatedAt", "CreatedByUserId"
    ) VALUES (
        p_company_id, p_vehicle_id, p_driver_id, v_number,
        COALESCE(p_trip_date, NOW() AT TIME ZONE 'UTC'),
        p_origin, p_destination, p_departed_at, p_odometer_start,
        p_delivery_note_id, p_notes,
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
    p_trip_id        INT,
    p_odometer_end   NUMERIC(12,2),
    p_arrived_at     TIMESTAMP,
    p_distance_km    NUMERIC(10,2) DEFAULT NULL,
    p_user_id        INT DEFAULT NULL
)
RETURNS TABLE("ok" INT, "mensaje" VARCHAR)
LANGUAGE plpgsql
AS $$
DECLARE
    v_vehicle_id INT;
    v_odometer_start NUMERIC;
BEGIN
    SELECT t."VehicleId", t."OdometerStart" INTO v_vehicle_id, v_odometer_start
    FROM fleet."Trip" t
    WHERE t."TripId" = p_trip_id AND t."Status" = 'IN_PROGRESS' AND t."IsDeleted" IS NOT TRUE;

    IF v_vehicle_id IS NULL THEN
        RETURN QUERY SELECT -1, 'Viaje no encontrado o ya completado'::VARCHAR;
        RETURN;
    END IF;

    UPDATE fleet."Trip" SET
        "OdometerEnd"     = p_odometer_end,
        "ArrivedAt"       = p_arrived_at,
        "DistanceKm"      = COALESCE(p_distance_km, p_odometer_end - v_odometer_start),
        "Status"          = 'COMPLETED',
        "UpdatedAt"       = NOW() AT TIME ZONE 'UTC',
        "UpdatedByUserId" = p_user_id
    WHERE "TripId" = p_trip_id;

    -- Actualizar odometro del vehiculo
    UPDATE fleet."Vehicle"
    SET "CurrentOdometer" = p_odometer_end,
        "UpdatedAt" = NOW() AT TIME ZONE 'UTC',
        "UpdatedByUserId" = p_user_id
    WHERE "VehicleId" = v_vehicle_id AND "CurrentOdometer" < p_odometer_end;

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
    "VehicleDocumentId" INT,
    "VehicleId"         INT,
    "DocumentType"      VARCHAR,
    "DocumentNumber"    VARCHAR,
    "Description"       VARCHAR,
    "IssuedAt"          TIMESTAMP,
    "ExpiresAt"         TIMESTAMP,
    "FileUrl"           VARCHAR,
    "Notes"             VARCHAR,
    "CreatedAt"         TIMESTAMP
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        d."VehicleDocumentId",
        d."VehicleId",
        d."DocumentType"::VARCHAR,
        d."DocumentNumber"::VARCHAR,
        d."Description"::VARCHAR,
        d."IssuedAt",
        d."ExpiresAt",
        d."FileUrl"::VARCHAR,
        d."Notes"::VARCHAR,
        d."CreatedAt"
    FROM fleet."VehicleDocument" d
    WHERE d."VehicleId" = p_vehicle_id
      AND d."IsDeleted" IS NOT TRUE
    ORDER BY d."ExpiresAt" DESC;
END;
$$;

-- usp_Fleet_VehicleDocument_Upsert
DROP FUNCTION IF EXISTS usp_fleet_vehicledocument_upsert(INT, INT, VARCHAR, VARCHAR, VARCHAR, TIMESTAMP, TIMESTAMP, VARCHAR, VARCHAR, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_fleet_vehicledocument_upsert(
    p_vehicle_document_id INT DEFAULT NULL,
    p_vehicle_id          INT DEFAULT NULL,
    p_document_type       VARCHAR(50) DEFAULT NULL,
    p_document_number     VARCHAR(50) DEFAULT NULL,
    p_description         VARCHAR(200) DEFAULT NULL,
    p_issued_at           TIMESTAMP DEFAULT NULL,
    p_expires_at          TIMESTAMP DEFAULT NULL,
    p_file_url            VARCHAR(500) DEFAULT NULL,
    p_notes               VARCHAR(500) DEFAULT NULL,
    p_user_id             INT DEFAULT NULL
)
RETURNS TABLE("ok" INT, "mensaje" VARCHAR)
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_vehicle_document_id IS NOT NULL AND EXISTS (SELECT 1 FROM fleet."VehicleDocument" WHERE "VehicleDocumentId" = p_vehicle_document_id AND "IsDeleted" IS NOT TRUE) THEN
        UPDATE fleet."VehicleDocument" SET
            "DocumentType"     = p_document_type,
            "DocumentNumber"   = p_document_number,
            "Description"      = p_description,
            "IssuedAt"         = p_issued_at,
            "ExpiresAt"        = p_expires_at,
            "FileUrl"          = p_file_url,
            "Notes"            = p_notes,
            "UpdatedAt"        = NOW() AT TIME ZONE 'UTC',
            "UpdatedByUserId"  = p_user_id
        WHERE "VehicleDocumentId" = p_vehicle_document_id;

        RETURN QUERY SELECT 1, 'Documento actualizado'::VARCHAR;
    ELSE
        INSERT INTO fleet."VehicleDocument" (
            "VehicleId", "DocumentType", "DocumentNumber", "Description",
            "IssuedAt", "ExpiresAt", "FileUrl", "Notes",
            "CreatedAt", "CreatedByUserId"
        ) VALUES (
            p_vehicle_id, p_document_type, p_document_number, p_description,
            p_issued_at, p_expires_at, p_file_url, p_notes,
            NOW() AT TIME ZONE 'UTC', p_user_id
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
        (SELECT COUNT(*)::INT FROM fleet."Vehicle" WHERE "CompanyId" = p_company_id AND "IsActive" = TRUE AND "IsDeleted" IS NOT TRUE),
        (SELECT COUNT(*)::INT FROM fleet."Vehicle" WHERE "CompanyId" = p_company_id AND "IsDeleted" IS NOT TRUE),
        (SELECT COUNT(*)::INT FROM fleet."VehicleDocument" vd
         INNER JOIN fleet."Vehicle" v ON v."VehicleId" = vd."VehicleId"
         WHERE v."CompanyId" = p_company_id AND v."IsDeleted" IS NOT TRUE
           AND vd."IsDeleted" IS NOT TRUE
           AND vd."ExpiresAt" <= v_in30days AND vd."ExpiresAt" >= v_now
        ),
        (SELECT COUNT(*)::INT FROM fleet."MaintenanceOrder" mo
         WHERE mo."CompanyId" = p_company_id AND mo."Status" IN ('PENDING', 'SCHEDULED')
           AND mo."IsDeleted" IS NOT TRUE
        ),
        (SELECT COALESCE(SUM(fl."TotalCost"), 0) FROM fleet."FuelLog" fl
         WHERE fl."CompanyId" = p_company_id AND fl."FuelDate" >= v_month_start
           AND fl."IsDeleted" IS NOT TRUE
        ),
        (SELECT COUNT(*)::INT FROM fleet."Trip" t
         WHERE t."CompanyId" = p_company_id AND t."Status" = 'IN_PROGRESS'
           AND t."IsDeleted" IS NOT TRUE
        );
END;
$$;
