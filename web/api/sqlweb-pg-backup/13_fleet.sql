-- ============================================================
-- Zentto PostgreSQL - 13_fleet.sql
-- Schema: fleet (Flota vehicular)
-- Tablas: Vehicle, FuelLog, MaintenanceType, MaintenanceOrder,
--         MaintenanceOrderLine, Trip, VehicleDocument
-- ============================================================

BEGIN;

CREATE SCHEMA IF NOT EXISTS fleet;

-- ============================================================
-- 1. fleet."Vehicle"  (Vehiculos)
-- ============================================================
CREATE TABLE IF NOT EXISTS fleet."Vehicle"(
  "VehicleId"             BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"             INT NOT NULL,
  "VehicleCode"           VARCHAR(20) NOT NULL,
  "LicensePlate"          VARCHAR(20) NOT NULL,
  "VehicleType"           VARCHAR(30) NOT NULL DEFAULT 'CAR',
  "Brand"                 VARCHAR(60) NULL,
  "Model"                 VARCHAR(60) NULL,
  "Year"                  INT NULL,
  "Color"                 VARCHAR(30) NULL,
  "VinNumber"             VARCHAR(30) NULL,
  "EngineNumber"          VARCHAR(30) NULL,
  "FuelType"              VARCHAR(20) NOT NULL DEFAULT 'GASOLINE',
  "TankCapacity"          DECIMAL(10,2) NULL,
  "CurrentOdometer"       DECIMAL(12,2) NOT NULL DEFAULT 0,
  "OdometerUnit"          VARCHAR(5) NOT NULL DEFAULT 'KM',
  "DefaultDriverId"       BIGINT NULL,
  "WarehouseId"           BIGINT NULL,
  "PurchaseDate"          DATE NULL,
  "PurchaseCost"          DECIMAL(18,2) NULL,
  "InsurancePolicy"       VARCHAR(60) NULL,
  "InsuranceExpiry"       DATE NULL,
  "Status"                VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
  "Notes"                 VARCHAR(500) NULL,
  "IsActive"              BOOLEAN NOT NULL DEFAULT TRUE,
  "CreatedAt"             TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"             TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId"       INT NULL,
  "UpdatedByUserId"       INT NULL,
  "IsDeleted"             BOOLEAN NOT NULL DEFAULT FALSE,
  "DeletedAt"             TIMESTAMP NULL,
  "DeletedByUserId"       INT NULL,
  CONSTRAINT "CK_fleet_Vehicle_Type" CHECK ("VehicleType" IN ('CAR', 'TRUCK', 'VAN', 'MOTORCYCLE', 'BUS', 'TRAILER', 'FORKLIFT', 'OTHER')),
  CONSTRAINT "CK_fleet_Vehicle_Fuel" CHECK ("FuelType" IN ('GASOLINE', 'DIESEL', 'GAS', 'ELECTRIC', 'HYBRID', 'OTHER')),
  CONSTRAINT "CK_fleet_Vehicle_OdoUnit" CHECK ("OdometerUnit" IN ('KM', 'MI')),
  CONSTRAINT "CK_fleet_Vehicle_Status" CHECK ("Status" IN ('ACTIVE', 'IN_MAINTENANCE', 'OUT_OF_SERVICE', 'SOLD', 'SCRAPPED')),
  CONSTRAINT "UQ_fleet_Vehicle_Code" UNIQUE ("CompanyId", "VehicleCode"),
  CONSTRAINT "UQ_fleet_Vehicle_Plate" UNIQUE ("CompanyId", "LicensePlate"),
  CONSTRAINT "FK_fleet_Vehicle_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId"),
  CONSTRAINT "FK_fleet_Vehicle_Driver" FOREIGN KEY ("DefaultDriverId") REFERENCES logistics."Driver"("DriverId"),
  CONSTRAINT "FK_fleet_Vehicle_Warehouse" FOREIGN KEY ("WarehouseId") REFERENCES inv."Warehouse"("WarehouseId"),
  CONSTRAINT "FK_fleet_Vehicle_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_fleet_Vehicle_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_fleet_Vehicle_DeletedBy" FOREIGN KEY ("DeletedByUserId") REFERENCES sec."User"("UserId")
);

CREATE INDEX IF NOT EXISTS "IX_fleet_Vehicle_Company"
  ON fleet."Vehicle" ("CompanyId", "IsDeleted", "IsActive");

CREATE INDEX IF NOT EXISTS "IX_fleet_Vehicle_Status"
  ON fleet."Vehicle" ("CompanyId", "Status")
  WHERE "IsDeleted" = FALSE;

-- ============================================================
-- 2. fleet."FuelLog"  (Registro de combustible)
-- ============================================================
CREATE TABLE IF NOT EXISTS fleet."FuelLog"(
  "FuelLogId"             BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"             INT NOT NULL,
  "VehicleId"             BIGINT NOT NULL,
  "DriverId"              BIGINT NULL,
  "FuelDate"              TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "FuelType"              VARCHAR(20) NOT NULL,
  "Quantity"              DECIMAL(10,3) NOT NULL,
  "UnitPrice"             DECIMAL(18,4) NOT NULL,
  "TotalCost"             DECIMAL(18,2) NOT NULL,
  "CurrencyCode"          CHAR(3) NOT NULL DEFAULT 'USD',
  "OdometerReading"       DECIMAL(12,2) NULL,
  "IsFullTank"            BOOLEAN NOT NULL DEFAULT TRUE,
  "StationName"           VARCHAR(200) NULL,
  "InvoiceNumber"         VARCHAR(60) NULL,
  "Notes"                 VARCHAR(500) NULL,
  "CreatedAt"             TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"             TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId"       INT NULL,
  "UpdatedByUserId"       INT NULL,
  "IsDeleted"             BOOLEAN NOT NULL DEFAULT FALSE,
  "DeletedAt"             TIMESTAMP NULL,
  "DeletedByUserId"       INT NULL,
  CONSTRAINT "FK_fleet_FuelLog_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId"),
  CONSTRAINT "FK_fleet_FuelLog_Vehicle" FOREIGN KEY ("VehicleId") REFERENCES fleet."Vehicle"("VehicleId"),
  CONSTRAINT "FK_fleet_FuelLog_Driver" FOREIGN KEY ("DriverId") REFERENCES logistics."Driver"("DriverId"),
  CONSTRAINT "FK_fleet_FuelLog_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_fleet_FuelLog_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_fleet_FuelLog_DeletedBy" FOREIGN KEY ("DeletedByUserId") REFERENCES sec."User"("UserId")
);

CREATE INDEX IF NOT EXISTS "IX_fleet_FuelLog_Vehicle"
  ON fleet."FuelLog" ("VehicleId", "FuelDate" DESC);

CREATE INDEX IF NOT EXISTS "IX_fleet_FuelLog_Company"
  ON fleet."FuelLog" ("CompanyId", "FuelDate" DESC)
  WHERE "IsDeleted" = FALSE;

-- ============================================================
-- 3. fleet."MaintenanceType"  (Tipos de mantenimiento)
-- ============================================================
CREATE TABLE IF NOT EXISTS fleet."MaintenanceType"(
  "MaintenanceTypeId"     BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"             INT NOT NULL,
  "TypeCode"              VARCHAR(20) NOT NULL,
  "TypeName"              VARCHAR(200) NOT NULL,
  "Category"              VARCHAR(20) NOT NULL DEFAULT 'PREVENTIVE',
  "DefaultIntervalKm"     DECIMAL(12,2) NULL,
  "DefaultIntervalDays"   INT NULL,
  "IsActive"              BOOLEAN NOT NULL DEFAULT TRUE,
  "CreatedAt"             TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"             TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId"       INT NULL,
  "UpdatedByUserId"       INT NULL,
  "IsDeleted"             BOOLEAN NOT NULL DEFAULT FALSE,
  "DeletedAt"             TIMESTAMP NULL,
  "DeletedByUserId"       INT NULL,
  CONSTRAINT "CK_fleet_MaintType_Category" CHECK ("Category" IN ('PREVENTIVE', 'CORRECTIVE', 'PREDICTIVE', 'INSPECTION')),
  CONSTRAINT "UQ_fleet_MaintType_Code" UNIQUE ("CompanyId", "TypeCode"),
  CONSTRAINT "FK_fleet_MaintType_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId"),
  CONSTRAINT "FK_fleet_MaintType_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_fleet_MaintType_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_fleet_MaintType_DeletedBy" FOREIGN KEY ("DeletedByUserId") REFERENCES sec."User"("UserId")
);

CREATE INDEX IF NOT EXISTS "IX_fleet_MaintType_Company"
  ON fleet."MaintenanceType" ("CompanyId", "IsDeleted", "IsActive");

-- ============================================================
-- 4. fleet."MaintenanceOrder"  (Ordenes de mantenimiento)
-- ============================================================
CREATE TABLE IF NOT EXISTS fleet."MaintenanceOrder"(
  "MaintenanceOrderId"    BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"             INT NOT NULL,
  "VehicleId"             BIGINT NOT NULL,
  "MaintenanceTypeId"     BIGINT NOT NULL,
  "OrderNumber"           VARCHAR(30) NOT NULL,
  "OrderDate"             TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "OdometerAtService"     DECIMAL(12,2) NULL,
  "Status"                VARCHAR(20) NOT NULL DEFAULT 'DRAFT',
  "Priority"              VARCHAR(10) NOT NULL DEFAULT 'MEDIUM',
  "ScheduledDate"         TIMESTAMP NULL,
  "StartedAt"             TIMESTAMP NULL,
  "CompletedAt"           TIMESTAMP NULL,
  "WorkshopName"          VARCHAR(200) NULL,
  "TechnicianName"        VARCHAR(200) NULL,
  "TotalLaborCost"        DECIMAL(18,2) NOT NULL DEFAULT 0,
  "TotalPartsCost"        DECIMAL(18,2) NOT NULL DEFAULT 0,
  "TotalCost"             DECIMAL(18,2) NOT NULL DEFAULT 0,
  "CurrencyCode"          CHAR(3) NOT NULL DEFAULT 'USD',
  "Notes"                 VARCHAR(500) NULL,
  "CreatedAt"             TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"             TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId"       INT NULL,
  "UpdatedByUserId"       INT NULL,
  "IsDeleted"             BOOLEAN NOT NULL DEFAULT FALSE,
  "DeletedAt"             TIMESTAMP NULL,
  "DeletedByUserId"       INT NULL,
  CONSTRAINT "CK_fleet_MaintOrder_Status" CHECK ("Status" IN ('DRAFT', 'SCHEDULED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED')),
  CONSTRAINT "CK_fleet_MaintOrder_Priority" CHECK ("Priority" IN ('LOW', 'MEDIUM', 'HIGH', 'URGENT')),
  CONSTRAINT "UQ_fleet_MaintOrder_Number" UNIQUE ("CompanyId", "OrderNumber"),
  CONSTRAINT "FK_fleet_MaintOrder_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId"),
  CONSTRAINT "FK_fleet_MaintOrder_Vehicle" FOREIGN KEY ("VehicleId") REFERENCES fleet."Vehicle"("VehicleId"),
  CONSTRAINT "FK_fleet_MaintOrder_Type" FOREIGN KEY ("MaintenanceTypeId") REFERENCES fleet."MaintenanceType"("MaintenanceTypeId"),
  CONSTRAINT "FK_fleet_MaintOrder_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_fleet_MaintOrder_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_fleet_MaintOrder_DeletedBy" FOREIGN KEY ("DeletedByUserId") REFERENCES sec."User"("UserId")
);

CREATE INDEX IF NOT EXISTS "IX_fleet_MaintOrder_Vehicle"
  ON fleet."MaintenanceOrder" ("VehicleId", "OrderDate" DESC);

CREATE INDEX IF NOT EXISTS "IX_fleet_MaintOrder_Status"
  ON fleet."MaintenanceOrder" ("CompanyId", "Status")
  WHERE "IsDeleted" = FALSE;

-- ============================================================
-- 5. fleet."MaintenanceOrderLine"  (Lineas de la orden)
-- ============================================================
CREATE TABLE IF NOT EXISTS fleet."MaintenanceOrderLine"(
  "MaintenanceOrderLineId" BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "MaintenanceOrderId"    BIGINT NOT NULL,
  "LineNumber"            INT NOT NULL,
  "LineType"              VARCHAR(10) NOT NULL DEFAULT 'PART',
  "ProductId"             BIGINT NULL,
  "Description"           VARCHAR(300) NOT NULL,
  "Quantity"              DECIMAL(18,3) NOT NULL DEFAULT 1,
  "UnitCost"              DECIMAL(18,4) NOT NULL DEFAULT 0,
  "TotalCost"             DECIMAL(18,2) NOT NULL DEFAULT 0,
  "Notes"                 VARCHAR(500) NULL,
  "CreatedAt"             TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"             TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  CONSTRAINT "CK_fleet_MOLine_Type" CHECK ("LineType" IN ('PART', 'LABOR', 'SERVICE', 'OTHER')),
  CONSTRAINT "UQ_fleet_MOLine" UNIQUE ("MaintenanceOrderId", "LineNumber"),
  CONSTRAINT "FK_fleet_MOLine_Order" FOREIGN KEY ("MaintenanceOrderId") REFERENCES fleet."MaintenanceOrder"("MaintenanceOrderId"),
  CONSTRAINT "FK_fleet_MOLine_Product" FOREIGN KEY ("ProductId") REFERENCES master."Product"("ProductId")
);

CREATE INDEX IF NOT EXISTS "IX_fleet_MOLine_Order"
  ON fleet."MaintenanceOrderLine" ("MaintenanceOrderId");

-- ============================================================
-- 6. fleet."Trip"  (Viajes)
-- ============================================================
CREATE TABLE IF NOT EXISTS fleet."Trip"(
  "TripId"                BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"             INT NOT NULL,
  "VehicleId"             BIGINT NOT NULL,
  "DriverId"              BIGINT NULL,
  "DeliveryNoteId"        BIGINT NULL,
  "TripNumber"            VARCHAR(30) NOT NULL,
  "TripDate"              TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "Origin"                VARCHAR(300) NULL,
  "Destination"           VARCHAR(300) NULL,
  "DistanceKm"            DECIMAL(10,2) NULL,
  "OdometerStart"         DECIMAL(12,2) NULL,
  "OdometerEnd"           DECIMAL(12,2) NULL,
  "DepartedAt"            TIMESTAMP NULL,
  "ArrivedAt"             TIMESTAMP NULL,
  "Status"                VARCHAR(20) NOT NULL DEFAULT 'PLANNED',
  "Notes"                 VARCHAR(500) NULL,
  "CreatedAt"             TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"             TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId"       INT NULL,
  "UpdatedByUserId"       INT NULL,
  "IsDeleted"             BOOLEAN NOT NULL DEFAULT FALSE,
  "DeletedAt"             TIMESTAMP NULL,
  "DeletedByUserId"       INT NULL,
  CONSTRAINT "CK_fleet_Trip_Status" CHECK ("Status" IN ('PLANNED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED')),
  CONSTRAINT "UQ_fleet_Trip_Number" UNIQUE ("CompanyId", "TripNumber"),
  CONSTRAINT "FK_fleet_Trip_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId"),
  CONSTRAINT "FK_fleet_Trip_Vehicle" FOREIGN KEY ("VehicleId") REFERENCES fleet."Vehicle"("VehicleId"),
  CONSTRAINT "FK_fleet_Trip_Driver" FOREIGN KEY ("DriverId") REFERENCES logistics."Driver"("DriverId"),
  CONSTRAINT "FK_fleet_Trip_DeliveryNote" FOREIGN KEY ("DeliveryNoteId") REFERENCES logistics."DeliveryNote"("DeliveryNoteId"),
  CONSTRAINT "FK_fleet_Trip_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_fleet_Trip_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_fleet_Trip_DeletedBy" FOREIGN KEY ("DeletedByUserId") REFERENCES sec."User"("UserId")
);

CREATE INDEX IF NOT EXISTS "IX_fleet_Trip_Vehicle"
  ON fleet."Trip" ("VehicleId", "TripDate" DESC);

CREATE INDEX IF NOT EXISTS "IX_fleet_Trip_Company"
  ON fleet."Trip" ("CompanyId", "TripDate" DESC)
  WHERE "IsDeleted" = FALSE;

CREATE INDEX IF NOT EXISTS "IX_fleet_Trip_DeliveryNote"
  ON fleet."Trip" ("DeliveryNoteId")
  WHERE "DeliveryNoteId" IS NOT NULL;

-- ============================================================
-- 7. fleet."VehicleDocument"  (Documentos del vehiculo)
-- ============================================================
CREATE TABLE IF NOT EXISTS fleet."VehicleDocument"(
  "VehicleDocumentId"     BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "VehicleId"             BIGINT NOT NULL,
  "DocumentType"          VARCHAR(30) NOT NULL,
  "DocumentNumber"        VARCHAR(60) NULL,
  "Description"           VARCHAR(300) NULL,
  "IssuedAt"              DATE NULL,
  "ExpiresAt"             DATE NULL,
  "FileUrl"               VARCHAR(500) NULL,
  "Notes"                 VARCHAR(500) NULL,
  "CreatedAt"             TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"             TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId"       INT NULL,
  "UpdatedByUserId"       INT NULL,
  "IsDeleted"             BOOLEAN NOT NULL DEFAULT FALSE,
  "DeletedAt"             TIMESTAMP NULL,
  "DeletedByUserId"       INT NULL,
  CONSTRAINT "CK_fleet_VehicleDoc_Type" CHECK ("DocumentType" IN ('REGISTRATION', 'INSURANCE', 'INSPECTION', 'PERMIT', 'WARRANTY', 'TITLE', 'OTHER')),
  CONSTRAINT "FK_fleet_VehicleDoc_Vehicle" FOREIGN KEY ("VehicleId") REFERENCES fleet."Vehicle"("VehicleId"),
  CONSTRAINT "FK_fleet_VehicleDoc_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_fleet_VehicleDoc_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_fleet_VehicleDoc_DeletedBy" FOREIGN KEY ("DeletedByUserId") REFERENCES sec."User"("UserId")
);

CREATE INDEX IF NOT EXISTS "IX_fleet_VehicleDoc_Vehicle"
  ON fleet."VehicleDocument" ("VehicleId")
  WHERE "IsDeleted" = FALSE;

CREATE INDEX IF NOT EXISTS "IX_fleet_VehicleDoc_Expiry"
  ON fleet."VehicleDocument" ("ExpiresAt")
  WHERE "ExpiresAt" IS NOT NULL AND "IsDeleted" = FALSE;

COMMIT;
