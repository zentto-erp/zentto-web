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
 *    - Los parametros de entrada usan los nombres que el service.ts envia
 *      (PascalCase → snake_case via callSp). Internamente se mapean a las
 *      columnas reales de la tabla.
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
-- Service envia: CompanyId, Status, VehicleType, Search, Page, Limit
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
    "VehicleId" BIGINT,
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
    "DefaultDriverId" BIGINT,
    "WarehouseId" BIGINT,
    "InsuranceExpiry"        TIMESTAMP,
    "Status"                 VARCHAR,
    "CreatedAt"              TIMESTAMP,
    "TotalCount" BIGINT
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
-- Service envia: VehicleId
DROP FUNCTION IF EXISTS usp_fleet_vehicle_get(INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_fleet_vehicle_get(
    p_vehicle_id INT
)
RETURNS TABLE(
    "VehicleId" BIGINT,
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
    "DefaultDriverId" BIGINT,
    "WarehouseId" BIGINT,
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
-- Service envia: CompanyId, VehicleId, VehiclePlate, VIN, Brand, Model, Year, Color,
--   VehicleType, FuelType, CurrentMileage, PurchaseDate, PurchaseCost, InsurancePolicy,
--   InsuranceExpiry, TechnicalReviewExpiry, PermitExpiry, AssignedDriverId, AssignedBranchId,
--   Notes, IsActive, UserId
-- Mapeo: VehiclePlate→LicensePlate, VIN→VinNumber, CurrentMileage→CurrentOdometer,
--   AssignedDriverId→DefaultDriverId, AssignedBranchId→WarehouseId
-- TechnicalReviewExpiry y PermitExpiry se aceptan pero se ignoran (la tabla no los tiene)
DROP FUNCTION IF EXISTS usp_fleet_vehicle_upsert CASCADE;
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
RETURNS TABLE("ok" INT, "VehicleId" BIGINT)
LANGUAGE plpgsql
AS $$
DECLARE
    v_id INT;
BEGIN
    -- p_technical_review_expiry y p_permit_expiry se ignoran (la tabla no tiene esas columnas)

    IF p_vehicle_id IS NOT NULL AND EXISTS (SELECT 1 FROM fleet."Vehicle" WHERE "VehicleId" = p_vehicle_id AND "IsDeleted" IS NOT TRUE) THEN
        UPDATE fleet."Vehicle" SET
            "LicensePlate"           = p_vehicle_plate,
            "VinNumber"              = p_vin,
            "Brand"                  = p_brand,
            "Model"                  = p_model,
            "VehicleType"            = p_vehicle_type,
            "Year"                   = p_year,
            "Color"                  = p_color,
            "FuelType"               = p_fuel_type,
            "CurrentOdometer"        = p_current_mileage,
            "PurchaseDate"           = p_purchase_date,
            "PurchaseCost"           = p_purchase_cost,
            "InsurancePolicy"        = p_insurance_policy,
            "InsuranceExpiry"        = p_insurance_expiry,
            "DefaultDriverId"        = p_assigned_driver_id,
            "WarehouseId"            = p_assigned_branch_id,
            "Notes"                  = p_notes,
            "IsActive"               = p_is_active,
            "UpdatedAt"              = NOW() AT TIME ZONE 'UTC',
            "UpdatedByUserId"        = p_user_id
        WHERE "VehicleId" = p_vehicle_id;
        v_id := p_vehicle_id;
    ELSE
        INSERT INTO fleet."Vehicle" (
            "CompanyId", "LicensePlate", "VinNumber",
            "Brand", "Model", "VehicleType", "Year", "Color",
            "FuelType", "CurrentOdometer",
            "PurchaseDate", "PurchaseCost",
            "InsurancePolicy", "InsuranceExpiry",
            "DefaultDriverId", "WarehouseId", "Notes", "IsActive",
            "CreatedAt", "CreatedByUserId"
        ) VALUES (
            p_company_id, p_vehicle_plate, p_vin,
            p_brand, p_model, p_vehicle_type, p_year, p_color,
            p_fuel_type, p_current_mileage,
            p_purchase_date, p_purchase_cost,
            p_insurance_policy, p_insurance_expiry,
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
-- Service envia: CompanyId, VehicleId, FechaDesde, FechaHasta, Page, Limit
-- Filtrar por FuelDate usando FechaDesde/FechaHasta
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
    "FuelLogId" BIGINT,
    "VehicleId" BIGINT,
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
    "DriverId" BIGINT,
    "Notes"           VARCHAR,
    "CreatedAt"       TIMESTAMP,
    "TotalCount" BIGINT
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
-- Service envia: CompanyId, VehicleId, LogDate, Mileage, FuelType, Liters, PricePerLiter,
--   TotalCost, StationName, DriverId, Notes, UserId
-- Mapeo: LogDate→FuelDate, Mileage→OdometerReading, Liters→Quantity, PricePerLiter→UnitPrice
DROP FUNCTION IF EXISTS usp_fleet_fuellog_create CASCADE;
CREATE OR REPLACE FUNCTION usp_fleet_fuellog_create(
    p_company_id      INT,
    p_vehicle_id      INT,
    p_log_date        TIMESTAMP,
    p_mileage         NUMERIC(12,2),
    p_fuel_type       VARCHAR(20),
    p_liters          NUMERIC(10,3),
    p_price_per_liter NUMERIC(10,4),
    p_total_cost      NUMERIC(18,2),
    p_station_name    VARCHAR(100) DEFAULT NULL,
    p_driver_id       INT DEFAULT NULL,
    p_notes           VARCHAR(500) DEFAULT NULL,
    p_user_id         INT DEFAULT NULL
)
RETURNS TABLE("ok" INT, "FuelLogId" BIGINT)
LANGUAGE plpgsql
AS $$
DECLARE
    v_id INT;
BEGIN
    INSERT INTO fleet."FuelLog" (
        "CompanyId", "VehicleId", "FuelDate", "OdometerReading", "FuelType",
        "Quantity", "UnitPrice", "TotalCost",
        "StationName", "DriverId", "Notes", "CreatedAt", "CreatedByUserId"
    ) VALUES (
        p_company_id, p_vehicle_id, p_log_date, p_mileage, p_fuel_type,
        p_liters, p_price_per_liter, p_total_cost,
        p_station_name, p_driver_id, p_notes, NOW() AT TIME ZONE 'UTC', p_user_id
    ) RETURNING "FuelLogId" INTO v_id;

    -- Actualizar odometro si es mayor al actual
    UPDATE fleet."Vehicle"
    SET "CurrentOdometer" = p_mileage,
        "UpdatedAt" = NOW() AT TIME ZONE 'UTC',
        "UpdatedByUserId" = p_user_id
    WHERE "VehicleId" = p_vehicle_id AND "CurrentOdometer" < p_mileage;

    RETURN QUERY SELECT 1, v_id;
END;
$$;

-- =============================================================================
--  SECCION 3: TIPOS DE MANTENIMIENTO
-- =============================================================================

-- usp_Fleet_MaintenanceType_List
-- Service envia: CompanyId
DROP FUNCTION IF EXISTS usp_fleet_maintenancetype_list(INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_fleet_maintenancetype_list(
    p_company_id INT
)
RETURNS TABLE(
    "MaintenanceTypeId" BIGINT,
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
-- Service envia: CompanyId, MaintenanceTypeId, TypeCode, TypeName, Category,
--   DefaultIntervalKm, DefaultIntervalDays, IsActive, UserId
DROP FUNCTION IF EXISTS usp_fleet_maintenancetype_upsert CASCADE;
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
-- Service envia: CompanyId, VehicleId, Status, Page, Limit
DROP FUNCTION IF EXISTS usp_fleet_maintenanceorder_list(INT, INT, VARCHAR, INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_fleet_maintenanceorder_list(
    p_company_id  INT,
    p_vehicle_id  INT DEFAULT NULL,
    p_status      VARCHAR(20) DEFAULT NULL,
    p_page        INT DEFAULT 1,
    p_limit       INT DEFAULT 50
)
RETURNS TABLE(
    "MaintenanceOrderId" BIGINT,
    "OrderNumber"          VARCHAR,
    "VehicleId" BIGINT,
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
    "TotalCount" BIGINT
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
-- Service envia: MaintenanceOrderId
DROP FUNCTION IF EXISTS usp_fleet_maintenanceorder_get(INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_fleet_maintenanceorder_get(
    p_maintenance_order_id INT
)
RETURNS TABLE(
    "MaintenanceOrderId" BIGINT,
    "OrderNumber"          VARCHAR,
    "OrderDate"            TIMESTAMP,
    "VehicleId" BIGINT,
    "LicensePlate"         VARCHAR,
    "Brand"                VARCHAR,
    "Model"                VARCHAR,
    "MaintenanceTypeId" BIGINT,
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
-- Service envia: CompanyId, BranchId, VehicleId, MaintenanceTypeId, MileageAtService,
--   ScheduledDate, SupplierId, EstimatedCost, Description, LinesJson, UserId
-- Mapeo: MileageAtService→OdometerAtService, Description→Notes, EstimatedCost→TotalCost,
--   SupplierId→WorkshopName (se guarda como texto del id)
-- BranchId se acepta pero se ignora (la tabla no lo tiene directamente)
DROP FUNCTION IF EXISTS usp_fleet_maintenanceorder_create CASCADE;
CREATE OR REPLACE FUNCTION usp_fleet_maintenanceorder_create(
    p_company_id          INT,
    p_branch_id           INT DEFAULT NULL,
    p_vehicle_id          INT DEFAULT NULL,
    p_maintenance_type_id INT DEFAULT NULL,
    p_mileage_at_service  NUMERIC(12,2) DEFAULT 0,
    p_scheduled_date      TIMESTAMP DEFAULT NULL,
    p_supplier_id         INT DEFAULT NULL,
    p_estimated_cost      NUMERIC(18,2) DEFAULT 0,
    p_description         VARCHAR(500) DEFAULT NULL,
    p_lines_json          VARCHAR DEFAULT NULL,
    p_user_id             INT DEFAULT NULL
)
RETURNS TABLE("ok" INT, "MaintenanceOrderId" BIGINT, "OrderNumber" VARCHAR)
LANGUAGE plpgsql
AS $$
DECLARE
    v_id     INT;
    v_seq    INT;
    v_number VARCHAR(20);
    v_workshop VARCHAR(200);
BEGIN
    -- p_branch_id se ignora (la tabla no tiene esa columna)
    -- p_supplier_id se mapea a WorkshopName como texto
    IF p_supplier_id IS NOT NULL THEN
        v_workshop := 'Proveedor #' || p_supplier_id::TEXT;
    ELSE
        v_workshop := NULL;
    END IF;

    -- Generar numero de orden
    SELECT COALESCE(MAX(
        CAST(SUBSTRING(mo."OrderNumber" FROM 4) AS INT)
    ), 0) + 1 INTO v_seq
    FROM fleet."MaintenanceOrder" mo
    WHERE mo."CompanyId" = p_company_id;

    v_number := 'MO-' || LPAD(v_seq::TEXT, 6, '0');

    INSERT INTO fleet."MaintenanceOrder" (
        "CompanyId", "VehicleId", "MaintenanceTypeId", "OrderNumber",
        "OrderDate", "OdometerAtService", "ScheduledDate",
        "WorkshopName", "TotalCost",
        "Notes", "Status", "CreatedAt", "CreatedByUserId"
    ) VALUES (
        p_company_id, p_vehicle_id, p_maintenance_type_id, v_number,
        NOW() AT TIME ZONE 'UTC', p_mileage_at_service, p_scheduled_date,
        v_workshop, p_estimated_cost,
        p_description, 'PENDING', NOW() AT TIME ZONE 'UTC', p_user_id
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
-- Service envia: MaintenanceOrderId, ActualCost, CompletedDate, UserId
-- Mapeo: ActualCost→TotalCost, CompletedDate→CompletedAt
DROP FUNCTION IF EXISTS usp_fleet_maintenanceorder_complete CASCADE;
CREATE OR REPLACE FUNCTION usp_fleet_maintenanceorder_complete(
    p_maintenance_order_id INT,
    p_actual_cost          NUMERIC(18,2) DEFAULT 0,
    p_completed_date       TIMESTAMP DEFAULT NULL,
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
        "TotalCost"      = p_actual_cost,
        "CompletedAt"    = COALESCE(p_completed_date, NOW() AT TIME ZONE 'UTC'),
        "Status"         = 'COMPLETED',
        "UpdatedAt"      = NOW() AT TIME ZONE 'UTC',
        "UpdatedByUserId" = p_user_id
    WHERE "MaintenanceOrderId" = p_maintenance_order_id;

    RETURN QUERY SELECT 1, 'Orden completada'::VARCHAR;
END;
$$;

-- usp_Fleet_MaintenanceOrder_Cancel
-- Service envia: MaintenanceOrderId, UserId
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
-- Service envia: CompanyId, VehicleId, Status, FechaDesde, FechaHasta, Page, Limit
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
    "TripId" BIGINT,
    "TripNumber"      VARCHAR,
    "TripDate"        TIMESTAMP,
    "VehicleId" BIGINT,
    "LicensePlate"    VARCHAR,
    "DriverId" BIGINT,
    "Origin"          VARCHAR,
    "Destination"     VARCHAR,
    "DistanceKm"      NUMERIC,
    "DepartedAt"      TIMESTAMP,
    "ArrivedAt"       TIMESTAMP,
    "OdometerStart"   NUMERIC,
    "OdometerEnd"     NUMERIC,
    "DeliveryNoteId" BIGINT,
    "Status"          VARCHAR,
    "Notes"           VARCHAR,
    "CreatedAt"       TIMESTAMP,
    "TotalCount" BIGINT
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
-- Service envia: CompanyId, VehicleId, DriverId, Origin, Destination, DepartureDate,
--   StartMileage, DeliveryNoteId, Notes, UserId
-- Mapeo: DepartureDate→DepartedAt, StartMileage→OdometerStart
DROP FUNCTION IF EXISTS usp_fleet_trip_create CASCADE;
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
RETURNS TABLE("ok" INT, "TripId" BIGINT, "TripNumber" VARCHAR)
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
        COALESCE(p_departure_date, NOW() AT TIME ZONE 'UTC'),
        p_origin, p_destination, p_departure_date, p_start_mileage,
        p_delivery_note_id, p_notes,
        'IN_PROGRESS', NOW() AT TIME ZONE 'UTC', p_user_id
    ) RETURNING "TripId" INTO v_id;

    RETURN QUERY SELECT 1, v_id, v_number;

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -1, 0, ''::VARCHAR;
END;
$$;

-- usp_Fleet_Trip_Complete
-- Service envia: TripId, EndMileage, ArrivalDate, FuelUsed, UserId
-- Mapeo: EndMileage→OdometerEnd, ArrivalDate→ArrivedAt
-- FuelUsed se acepta pero se ignora (la tabla no tiene esa columna)
DROP FUNCTION IF EXISTS usp_fleet_trip_complete CASCADE;
CREATE OR REPLACE FUNCTION usp_fleet_trip_complete(
    p_trip_id        INT,
    p_end_mileage    NUMERIC(12,2),
    p_arrival_date   TIMESTAMP,
    p_fuel_used      NUMERIC(10,2) DEFAULT NULL,
    p_user_id        INT DEFAULT NULL
)
RETURNS TABLE("ok" INT, "mensaje" VARCHAR)
LANGUAGE plpgsql
AS $$
DECLARE
    v_vehicle_id INT;
    v_odometer_start NUMERIC;
BEGIN
    -- p_fuel_used se ignora (la tabla no tiene esa columna)

    SELECT t."VehicleId", t."OdometerStart" INTO v_vehicle_id, v_odometer_start
    FROM fleet."Trip" t
    WHERE t."TripId" = p_trip_id AND t."Status" = 'IN_PROGRESS' AND t."IsDeleted" IS NOT TRUE;

    IF v_vehicle_id IS NULL THEN
        RETURN QUERY SELECT -1, 'Viaje no encontrado o ya completado'::VARCHAR;
        RETURN;
    END IF;

    UPDATE fleet."Trip" SET
        "OdometerEnd"     = p_end_mileage,
        "ArrivedAt"       = p_arrival_date,
        "DistanceKm"      = p_end_mileage - v_odometer_start,
        "Status"          = 'COMPLETED',
        "UpdatedAt"       = NOW() AT TIME ZONE 'UTC',
        "UpdatedByUserId" = p_user_id
    WHERE "TripId" = p_trip_id;

    -- Actualizar odometro del vehiculo
    UPDATE fleet."Vehicle"
    SET "CurrentOdometer" = p_end_mileage,
        "UpdatedAt" = NOW() AT TIME ZONE 'UTC',
        "UpdatedByUserId" = p_user_id
    WHERE "VehicleId" = v_vehicle_id AND "CurrentOdometer" < p_end_mileage;

    RETURN QUERY SELECT 1, 'Viaje completado'::VARCHAR;
END;
$$;

-- =============================================================================
--  SECCION 6: DOCUMENTOS DE VEHICULO
-- =============================================================================

-- usp_Fleet_VehicleDocument_List
-- Service envia: VehicleId
DROP FUNCTION IF EXISTS usp_fleet_vehicledocument_list(INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_fleet_vehicledocument_list(
    p_vehicle_id INT
)
RETURNS TABLE(
    "VehicleDocumentId" BIGINT,
    "VehicleId" BIGINT,
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
-- Service envia: CompanyId, DocumentId, VehicleId, DocumentType, DocumentNumber,
--   IssueDate, ExpiryDate, FilePath, Notes, UserId
-- Mapeo: DocumentId→VehicleDocumentId, IssueDate→IssuedAt, ExpiryDate→ExpiresAt, FilePath→FileUrl
-- CompanyId se acepta pero se ignora (la tabla no lo tiene directamente)
DROP FUNCTION IF EXISTS usp_fleet_vehicledocument_upsert CASCADE;
CREATE OR REPLACE FUNCTION usp_fleet_vehicledocument_upsert(
    p_company_id      INT DEFAULT NULL,
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
    -- p_company_id se ignora (la tabla VehicleDocument no tiene CompanyId)

    IF p_document_id IS NOT NULL AND EXISTS (SELECT 1 FROM fleet."VehicleDocument" WHERE "VehicleDocumentId" = p_document_id AND "IsDeleted" IS NOT TRUE) THEN
        UPDATE fleet."VehicleDocument" SET
            "DocumentType"     = p_document_type,
            "DocumentNumber"   = p_document_number,
            "IssuedAt"         = p_issue_date,
            "ExpiresAt"        = p_expiry_date,
            "FileUrl"          = p_file_path,
            "Notes"            = p_notes,
            "UpdatedAt"        = NOW() AT TIME ZONE 'UTC',
            "UpdatedByUserId"  = p_user_id
        WHERE "VehicleDocumentId" = p_document_id;

        RETURN QUERY SELECT 1, 'Documento actualizado'::VARCHAR;
    ELSE
        INSERT INTO fleet."VehicleDocument" (
            "VehicleId", "DocumentType", "DocumentNumber",
            "IssuedAt", "ExpiresAt", "FileUrl", "Notes",
            "CreatedAt", "CreatedByUserId"
        ) VALUES (
            p_vehicle_id, p_document_type, p_document_number,
            p_issue_date, p_expiry_date, p_file_path, p_notes,
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
-- Service envia: CompanyId
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
