-- ============================================================
-- Zentto PostgreSQL - 12_manufacturing.sql
-- Schema: mfg (Manufactura)
-- Tablas: BillOfMaterials, BOMLine, WorkCenter, Routing,
--         WorkOrder, WorkOrderMaterial, WorkOrderOutput
-- ============================================================

BEGIN;

CREATE SCHEMA IF NOT EXISTS mfg;

-- ============================================================
-- 1. mfg."BillOfMaterials"  (Lista de materiales — cabecera)
-- ============================================================
CREATE TABLE IF NOT EXISTS mfg."BillOfMaterials"(
  "BOMId"                 BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"             INT NOT NULL,
  "BOMCode"               VARCHAR(30) NOT NULL,
  "BOMName"               VARCHAR(200) NOT NULL,
  "ProductId"             BIGINT NOT NULL,
  "OutputQuantity"        DECIMAL(18,3) NOT NULL DEFAULT 1,
  "UnitOfMeasure"         VARCHAR(20) NULL,
  "Version"               INT NOT NULL DEFAULT 1,
  "Status"                VARCHAR(20) NOT NULL DEFAULT 'DRAFT',
  "EffectiveFrom"         DATE NULL,
  "EffectiveTo"           DATE NULL,
  "Notes"                 VARCHAR(500) NULL,
  "IsActive"              BOOLEAN NOT NULL DEFAULT TRUE,
  "CreatedAt"             TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"             TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId"       INT NULL,
  "UpdatedByUserId"       INT NULL,
  "IsDeleted"             BOOLEAN NOT NULL DEFAULT FALSE,
  "DeletedAt"             TIMESTAMP NULL,
  "DeletedByUserId"       INT NULL,
  CONSTRAINT "CK_mfg_BOM_Status" CHECK ("Status" IN ('DRAFT', 'ACTIVE', 'OBSOLETE')),
  CONSTRAINT "UQ_mfg_BOM_Code" UNIQUE ("CompanyId", "BOMCode"),
  CONSTRAINT "FK_mfg_BOM_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId"),
  CONSTRAINT "FK_mfg_BOM_Product" FOREIGN KEY ("ProductId") REFERENCES master."Product"("ProductId"),
  CONSTRAINT "FK_mfg_BOM_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_mfg_BOM_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_mfg_BOM_DeletedBy" FOREIGN KEY ("DeletedByUserId") REFERENCES sec."User"("UserId")
);

CREATE INDEX IF NOT EXISTS "IX_mfg_BOM_Company"
  ON mfg."BillOfMaterials" ("CompanyId", "IsDeleted", "IsActive");

CREATE INDEX IF NOT EXISTS "IX_mfg_BOM_Product"
  ON mfg."BillOfMaterials" ("ProductId")
  WHERE "IsDeleted" = FALSE;

-- ============================================================
-- 2. mfg."BOMLine"  (Componentes de la lista de materiales)
-- ============================================================
CREATE TABLE IF NOT EXISTS mfg."BOMLine"(
  "BOMLineId"             BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "BOMId"                 BIGINT NOT NULL,
  "LineNumber"            INT NOT NULL,
  "ComponentProductId"    BIGINT NOT NULL,
  "Quantity"              DECIMAL(18,3) NOT NULL,
  "UnitOfMeasure"         VARCHAR(20) NULL,
  "WastePercent"          DECIMAL(5,2) NOT NULL DEFAULT 0,
  "IsOptional"            BOOLEAN NOT NULL DEFAULT FALSE,
  "Notes"                 VARCHAR(500) NULL,
  "CreatedAt"             TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"             TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  CONSTRAINT "UQ_mfg_BOMLine" UNIQUE ("BOMId", "LineNumber"),
  CONSTRAINT "FK_mfg_BOMLine_BOM" FOREIGN KEY ("BOMId") REFERENCES mfg."BillOfMaterials"("BOMId"),
  CONSTRAINT "FK_mfg_BOMLine_Component" FOREIGN KEY ("ComponentProductId") REFERENCES master."Product"("ProductId")
);

CREATE INDEX IF NOT EXISTS "IX_mfg_BOMLine_BOM"
  ON mfg."BOMLine" ("BOMId");

CREATE INDEX IF NOT EXISTS "IX_mfg_BOMLine_Component"
  ON mfg."BOMLine" ("ComponentProductId");

-- ============================================================
-- 3. mfg."WorkCenter"  (Centros de trabajo)
-- ============================================================
CREATE TABLE IF NOT EXISTS mfg."WorkCenter"(
  "WorkCenterId"          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"             INT NOT NULL,
  "WorkCenterCode"        VARCHAR(20) NOT NULL,
  "WorkCenterName"        VARCHAR(200) NOT NULL,
  "WarehouseId"           BIGINT NULL,
  "CostPerHour"           DECIMAL(18,4) NOT NULL DEFAULT 0,
  "Capacity"              DECIMAL(18,2) NOT NULL DEFAULT 1,
  "CapacityUom"           VARCHAR(20) NOT NULL DEFAULT 'UNITS_PER_HOUR',
  "IsActive"              BOOLEAN NOT NULL DEFAULT TRUE,
  "CreatedAt"             TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"             TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId"       INT NULL,
  "UpdatedByUserId"       INT NULL,
  "IsDeleted"             BOOLEAN NOT NULL DEFAULT FALSE,
  "DeletedAt"             TIMESTAMP NULL,
  "DeletedByUserId"       INT NULL,
  CONSTRAINT "UQ_mfg_WorkCenter_Code" UNIQUE ("CompanyId", "WorkCenterCode"),
  CONSTRAINT "FK_mfg_WorkCenter_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId"),
  CONSTRAINT "FK_mfg_WorkCenter_Warehouse" FOREIGN KEY ("WarehouseId") REFERENCES inv."Warehouse"("WarehouseId"),
  CONSTRAINT "FK_mfg_WorkCenter_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_mfg_WorkCenter_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_mfg_WorkCenter_DeletedBy" FOREIGN KEY ("DeletedByUserId") REFERENCES sec."User"("UserId")
);

CREATE INDEX IF NOT EXISTS "IX_mfg_WorkCenter_Company"
  ON mfg."WorkCenter" ("CompanyId", "IsDeleted", "IsActive");

-- ============================================================
-- 4. mfg."Routing"  (Rutas de produccion — operaciones)
-- ============================================================
CREATE TABLE IF NOT EXISTS mfg."Routing"(
  "RoutingId"             BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "BOMId"                 BIGINT NOT NULL,
  "OperationNumber"       INT NOT NULL,
  "OperationName"         VARCHAR(200) NOT NULL,
  "WorkCenterId"          BIGINT NOT NULL,
  "SetupTimeMinutes"      DECIMAL(10,2) NOT NULL DEFAULT 0,
  "RunTimeMinutes"        DECIMAL(10,2) NOT NULL DEFAULT 0,
  "Notes"                 VARCHAR(500) NULL,
  "CreatedAt"             TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"             TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  CONSTRAINT "UQ_mfg_Routing_Operation" UNIQUE ("BOMId", "OperationNumber"),
  CONSTRAINT "FK_mfg_Routing_BOM" FOREIGN KEY ("BOMId") REFERENCES mfg."BillOfMaterials"("BOMId"),
  CONSTRAINT "FK_mfg_Routing_WorkCenter" FOREIGN KEY ("WorkCenterId") REFERENCES mfg."WorkCenter"("WorkCenterId")
);

CREATE INDEX IF NOT EXISTS "IX_mfg_Routing_BOM"
  ON mfg."Routing" ("BOMId", "OperationNumber");

-- ============================================================
-- 5. mfg."WorkOrder"  (Ordenes de trabajo / produccion)
-- ============================================================
CREATE TABLE IF NOT EXISTS mfg."WorkOrder"(
  "WorkOrderId"           BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"             INT NOT NULL,
  "BranchId"              INT NOT NULL,
  "WorkOrderNumber"       VARCHAR(30) NOT NULL,
  "BOMId"                 BIGINT NOT NULL,
  "ProductId"             BIGINT NOT NULL,
  "PlannedQuantity"       DECIMAL(18,3) NOT NULL,
  "ProducedQuantity"      DECIMAL(18,3) NOT NULL DEFAULT 0,
  "ScrapQuantity"         DECIMAL(18,3) NOT NULL DEFAULT 0,
  "UnitOfMeasure"         VARCHAR(20) NULL,
  "WarehouseId"           BIGINT NOT NULL,
  "Status"                VARCHAR(20) NOT NULL DEFAULT 'DRAFT',
  "Priority"              VARCHAR(10) NOT NULL DEFAULT 'MEDIUM',
  "PlannedStartDate"      TIMESTAMP NULL,
  "PlannedEndDate"        TIMESTAMP NULL,
  "ActualStartDate"       TIMESTAMP NULL,
  "ActualEndDate"         TIMESTAMP NULL,
  "Notes"                 VARCHAR(500) NULL,
  "CreatedAt"             TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"             TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId"       INT NULL,
  "UpdatedByUserId"       INT NULL,
  "IsDeleted"             BOOLEAN NOT NULL DEFAULT FALSE,
  "DeletedAt"             TIMESTAMP NULL,
  "DeletedByUserId"       INT NULL,
  CONSTRAINT "CK_mfg_WorkOrder_Status" CHECK ("Status" IN ('DRAFT', 'CONFIRMED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED')),
  CONSTRAINT "CK_mfg_WorkOrder_Priority" CHECK ("Priority" IN ('LOW', 'MEDIUM', 'HIGH', 'URGENT')),
  CONSTRAINT "UQ_mfg_WorkOrder_Number" UNIQUE ("CompanyId", "WorkOrderNumber"),
  CONSTRAINT "FK_mfg_WorkOrder_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId"),
  CONSTRAINT "FK_mfg_WorkOrder_Branch" FOREIGN KEY ("BranchId") REFERENCES cfg."Branch"("BranchId"),
  CONSTRAINT "FK_mfg_WorkOrder_BOM" FOREIGN KEY ("BOMId") REFERENCES mfg."BillOfMaterials"("BOMId"),
  CONSTRAINT "FK_mfg_WorkOrder_Product" FOREIGN KEY ("ProductId") REFERENCES master."Product"("ProductId"),
  CONSTRAINT "FK_mfg_WorkOrder_Warehouse" FOREIGN KEY ("WarehouseId") REFERENCES inv."Warehouse"("WarehouseId"),
  CONSTRAINT "FK_mfg_WorkOrder_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_mfg_WorkOrder_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_mfg_WorkOrder_DeletedBy" FOREIGN KEY ("DeletedByUserId") REFERENCES sec."User"("UserId")
);

CREATE INDEX IF NOT EXISTS "IX_mfg_WorkOrder_Company"
  ON mfg."WorkOrder" ("CompanyId", "BranchId", "Status")
  WHERE "IsDeleted" = FALSE;

CREATE INDEX IF NOT EXISTS "IX_mfg_WorkOrder_BOM"
  ON mfg."WorkOrder" ("BOMId")
  WHERE "IsDeleted" = FALSE;

CREATE INDEX IF NOT EXISTS "IX_mfg_WorkOrder_Planned"
  ON mfg."WorkOrder" ("CompanyId", "PlannedStartDate")
  WHERE "Status" IN ('DRAFT', 'CONFIRMED') AND "IsDeleted" = FALSE;

-- ============================================================
-- 6. mfg."WorkOrderMaterial"  (Materiales consumidos)
-- ============================================================
CREATE TABLE IF NOT EXISTS mfg."WorkOrderMaterial"(
  "WorkOrderMaterialId"   BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "WorkOrderId"           BIGINT NOT NULL,
  "LineNumber"            INT NOT NULL,
  "ProductId"             BIGINT NOT NULL,
  "PlannedQuantity"       DECIMAL(18,3) NOT NULL,
  "ConsumedQuantity"      DECIMAL(18,3) NOT NULL DEFAULT 0,
  "UnitOfMeasure"         VARCHAR(20) NULL,
  "LotId"                 BIGINT NULL,
  "BinId"                 BIGINT NULL,
  "UnitCost"              DECIMAL(18,4) NOT NULL DEFAULT 0,
  "Notes"                 VARCHAR(500) NULL,
  "CreatedAt"             TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"             TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  CONSTRAINT "UQ_mfg_WOMaterial" UNIQUE ("WorkOrderId", "LineNumber"),
  CONSTRAINT "FK_mfg_WOMaterial_WorkOrder" FOREIGN KEY ("WorkOrderId") REFERENCES mfg."WorkOrder"("WorkOrderId"),
  CONSTRAINT "FK_mfg_WOMaterial_Product" FOREIGN KEY ("ProductId") REFERENCES master."Product"("ProductId"),
  CONSTRAINT "FK_mfg_WOMaterial_Lot" FOREIGN KEY ("LotId") REFERENCES inv."ProductLot"("LotId"),
  CONSTRAINT "FK_mfg_WOMaterial_Bin" FOREIGN KEY ("BinId") REFERENCES inv."WarehouseBin"("BinId")
);

CREATE INDEX IF NOT EXISTS "IX_mfg_WOMaterial_WorkOrder"
  ON mfg."WorkOrderMaterial" ("WorkOrderId");

-- ============================================================
-- 7. mfg."WorkOrderOutput"  (Productos terminados / salida)
-- ============================================================
CREATE TABLE IF NOT EXISTS mfg."WorkOrderOutput"(
  "WorkOrderOutputId"     BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "WorkOrderId"           BIGINT NOT NULL,
  "ProductId"             BIGINT NOT NULL,
  "Quantity"              DECIMAL(18,3) NOT NULL,
  "UnitOfMeasure"         VARCHAR(20) NULL,
  "LotNumber"             VARCHAR(60) NULL,
  "WarehouseId"           BIGINT NOT NULL,
  "BinId"                 BIGINT NULL,
  "UnitCost"              DECIMAL(18,4) NOT NULL DEFAULT 0,
  "IsScrap"               BOOLEAN NOT NULL DEFAULT FALSE,
  "Notes"                 VARCHAR(500) NULL,
  "ProducedAt"            TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId"       INT NULL,
  "CreatedAt"             TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  CONSTRAINT "FK_mfg_WOOutput_WorkOrder" FOREIGN KEY ("WorkOrderId") REFERENCES mfg."WorkOrder"("WorkOrderId"),
  CONSTRAINT "FK_mfg_WOOutput_Product" FOREIGN KEY ("ProductId") REFERENCES master."Product"("ProductId"),
  CONSTRAINT "FK_mfg_WOOutput_Warehouse" FOREIGN KEY ("WarehouseId") REFERENCES inv."Warehouse"("WarehouseId"),
  CONSTRAINT "FK_mfg_WOOutput_Bin" FOREIGN KEY ("BinId") REFERENCES inv."WarehouseBin"("BinId"),
  CONSTRAINT "FK_mfg_WOOutput_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId")
);

CREATE INDEX IF NOT EXISTS "IX_mfg_WOOutput_WorkOrder"
  ON mfg."WorkOrderOutput" ("WorkOrderId");

COMMIT;
