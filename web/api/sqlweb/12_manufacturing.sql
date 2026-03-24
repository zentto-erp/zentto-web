-- =============================================================================
-- 12_manufacturing.sql
-- Manufacturing: BOM, BOM Lines, Work Centers, Routing, Work Orders,
--                Work Order Materials, Work Order Outputs
-- =============================================================================
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

USE DatqBoxWeb;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

-- Schema
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'mfg')
  EXEC('CREATE SCHEMA mfg');
GO

BEGIN TRY
  BEGIN TRAN;

  -- =========================================================================
  -- 1. mfg.BillOfMaterials
  -- =========================================================================
  IF OBJECT_ID('mfg.BillOfMaterials', 'U') IS NULL
  BEGIN
    CREATE TABLE mfg.BillOfMaterials(
      BOMId               BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      CompanyId           INT NOT NULL,
      ProductId           BIGINT NOT NULL,
      BOMCode             NVARCHAR(40) NOT NULL,
      BOMName             NVARCHAR(200) NOT NULL,
      Version             INT NOT NULL CONSTRAINT DF_mfg_BOM_Version DEFAULT(1),
      OutputQuantity      DECIMAL(18,3) NOT NULL CONSTRAINT DF_mfg_BOM_OutputQty DEFAULT(1),
      ExpectedCost        DECIMAL(18,4) NOT NULL CONSTRAINT DF_mfg_BOM_ExpectedCost DEFAULT(0),
      Status              NVARCHAR(10) NOT NULL CONSTRAINT DF_mfg_BOM_Status DEFAULT('DRAFT'),
      IsActive            BIT NOT NULL CONSTRAINT DF_mfg_BOM_IsActive DEFAULT(1),
      CreatedAt           DATETIME2(0) NOT NULL CONSTRAINT DF_mfg_BOM_CreatedAt DEFAULT(SYSUTCDATETIME()),
      UpdatedAt           DATETIME2(0) NOT NULL CONSTRAINT DF_mfg_BOM_UpdatedAt DEFAULT(SYSUTCDATETIME()),
      CreatedByUserId     INT NULL,
      UpdatedByUserId     INT NULL,
      IsDeleted           BIT NOT NULL CONSTRAINT DF_mfg_BOM_IsDeleted DEFAULT(0),
      DeletedAt           DATETIME2(0) NULL,
      DeletedByUserId     INT NULL,
      RowVer              ROWVERSION NOT NULL,
      CONSTRAINT UQ_mfg_BOM_Code_Version UNIQUE (CompanyId, BOMCode, Version),
      CONSTRAINT CK_mfg_BOM_Status CHECK (Status IN ('DRAFT','ACTIVE','OBSOLETE')),
      CONSTRAINT FK_mfg_BOM_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId),
      CONSTRAINT FK_mfg_BOM_Product FOREIGN KEY (ProductId) REFERENCES master.Product(ProductId),
      CONSTRAINT FK_mfg_BOM_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
      CONSTRAINT FK_mfg_BOM_UpdatedBy FOREIGN KEY (UpdatedByUserId) REFERENCES sec.[User](UserId),
      CONSTRAINT FK_mfg_BOM_DeletedBy FOREIGN KEY (DeletedByUserId) REFERENCES sec.[User](UserId)
    );
  END;

  -- =========================================================================
  -- 2. mfg.BOMLine
  -- =========================================================================
  IF OBJECT_ID('mfg.BOMLine', 'U') IS NULL
  BEGIN
    CREATE TABLE mfg.BOMLine(
      BOMLineId           BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      BOMId               BIGINT NOT NULL,
      LineNumber          INT NOT NULL,
      ComponentProductId  BIGINT NOT NULL,
      Quantity            DECIMAL(18,4) NOT NULL,
      UnitOfMeasure       NVARCHAR(20) NULL,
      WastePercent        DECIMAL(9,4) NOT NULL CONSTRAINT DF_mfg_BOMLine_WastePercent DEFAULT(0),
      IsOptional          BIT NOT NULL CONSTRAINT DF_mfg_BOMLine_IsOptional DEFAULT(0),
      Notes               NVARCHAR(500) NULL,
      CreatedAt           DATETIME2(0) NOT NULL CONSTRAINT DF_mfg_BOMLine_CreatedAt DEFAULT(SYSUTCDATETIME()),
      UpdatedAt           DATETIME2(0) NOT NULL CONSTRAINT DF_mfg_BOMLine_UpdatedAt DEFAULT(SYSUTCDATETIME()),
      CreatedByUserId     INT NULL,
      UpdatedByUserId     INT NULL,
      IsDeleted           BIT NOT NULL CONSTRAINT DF_mfg_BOMLine_IsDeleted DEFAULT(0),
      DeletedAt           DATETIME2(0) NULL,
      DeletedByUserId     INT NULL,
      RowVer              ROWVERSION NOT NULL,
      CONSTRAINT UQ_mfg_BOMLine_Number UNIQUE (BOMId, LineNumber),
      CONSTRAINT FK_mfg_BOMLine_BOM FOREIGN KEY (BOMId) REFERENCES mfg.BillOfMaterials(BOMId),
      CONSTRAINT FK_mfg_BOMLine_Product FOREIGN KEY (ComponentProductId) REFERENCES master.Product(ProductId),
      CONSTRAINT FK_mfg_BOMLine_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
      CONSTRAINT FK_mfg_BOMLine_UpdatedBy FOREIGN KEY (UpdatedByUserId) REFERENCES sec.[User](UserId),
      CONSTRAINT FK_mfg_BOMLine_DeletedBy FOREIGN KEY (DeletedByUserId) REFERENCES sec.[User](UserId)
    );
  END;

  -- =========================================================================
  -- 3. mfg.WorkCenter
  -- =========================================================================
  IF OBJECT_ID('mfg.WorkCenter', 'U') IS NULL
  BEGIN
    CREATE TABLE mfg.WorkCenter(
      WorkCenterId        BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      CompanyId           INT NOT NULL,
      WorkCenterCode      NVARCHAR(20) NOT NULL,
      WorkCenterName      NVARCHAR(200) NOT NULL,
      CostPerHour         DECIMAL(18,4) NOT NULL CONSTRAINT DF_mfg_WorkCenter_CostPerHour DEFAULT(0),
      Capacity            DECIMAL(18,2) NOT NULL CONSTRAINT DF_mfg_WorkCenter_Capacity DEFAULT(1),
      IsActive            BIT NOT NULL CONSTRAINT DF_mfg_WorkCenter_IsActive DEFAULT(1),
      CreatedAt           DATETIME2(0) NOT NULL CONSTRAINT DF_mfg_WorkCenter_CreatedAt DEFAULT(SYSUTCDATETIME()),
      UpdatedAt           DATETIME2(0) NOT NULL CONSTRAINT DF_mfg_WorkCenter_UpdatedAt DEFAULT(SYSUTCDATETIME()),
      CreatedByUserId     INT NULL,
      UpdatedByUserId     INT NULL,
      IsDeleted           BIT NOT NULL CONSTRAINT DF_mfg_WorkCenter_IsDeleted DEFAULT(0),
      DeletedAt           DATETIME2(0) NULL,
      DeletedByUserId     INT NULL,
      RowVer              ROWVERSION NOT NULL,
      CONSTRAINT UQ_mfg_WorkCenter_Code UNIQUE (CompanyId, WorkCenterCode),
      CONSTRAINT FK_mfg_WorkCenter_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId),
      CONSTRAINT FK_mfg_WorkCenter_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
      CONSTRAINT FK_mfg_WorkCenter_UpdatedBy FOREIGN KEY (UpdatedByUserId) REFERENCES sec.[User](UserId),
      CONSTRAINT FK_mfg_WorkCenter_DeletedBy FOREIGN KEY (DeletedByUserId) REFERENCES sec.[User](UserId)
    );
  END;

  -- =========================================================================
  -- 4. mfg.Routing
  -- =========================================================================
  IF OBJECT_ID('mfg.Routing', 'U') IS NULL
  BEGIN
    CREATE TABLE mfg.Routing(
      RoutingId           BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      BOMId               BIGINT NOT NULL,
      OperationNumber     INT NOT NULL,
      WorkCenterId        BIGINT NOT NULL,
      OperationName       NVARCHAR(200) NOT NULL,
      SetupTimeMinutes    DECIMAL(18,2) NOT NULL CONSTRAINT DF_mfg_Routing_SetupTimeMinutes DEFAULT(0),
      RunTimeMinutes      DECIMAL(18,2) NOT NULL CONSTRAINT DF_mfg_Routing_RunTimeMinutes DEFAULT(0),
      Notes               NVARCHAR(500) NULL,
      CreatedAt           DATETIME2(0) NOT NULL CONSTRAINT DF_mfg_Routing_CreatedAt DEFAULT(SYSUTCDATETIME()),
      UpdatedAt           DATETIME2(0) NOT NULL CONSTRAINT DF_mfg_Routing_UpdatedAt DEFAULT(SYSUTCDATETIME()),
      CreatedByUserId     INT NULL,
      UpdatedByUserId     INT NULL,
      IsDeleted           BIT NOT NULL CONSTRAINT DF_mfg_Routing_IsDeleted DEFAULT(0),
      DeletedAt           DATETIME2(0) NULL,
      DeletedByUserId     INT NULL,
      RowVer              ROWVERSION NOT NULL,
      CONSTRAINT UQ_mfg_Routing_Operation UNIQUE (BOMId, OperationNumber),
      CONSTRAINT FK_mfg_Routing_BOM FOREIGN KEY (BOMId) REFERENCES mfg.BillOfMaterials(BOMId),
      CONSTRAINT FK_mfg_Routing_WorkCenter FOREIGN KEY (WorkCenterId) REFERENCES mfg.WorkCenter(WorkCenterId),
      CONSTRAINT FK_mfg_Routing_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
      CONSTRAINT FK_mfg_Routing_UpdatedBy FOREIGN KEY (UpdatedByUserId) REFERENCES sec.[User](UserId),
      CONSTRAINT FK_mfg_Routing_DeletedBy FOREIGN KEY (DeletedByUserId) REFERENCES sec.[User](UserId)
    );
  END;

  -- =========================================================================
  -- 5. mfg.WorkOrder
  -- =========================================================================
  IF OBJECT_ID('mfg.WorkOrder', 'U') IS NULL
  BEGIN
    CREATE TABLE mfg.WorkOrder(
      WorkOrderId         BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      CompanyId           INT NOT NULL,
      BranchId            INT NOT NULL,
      WorkOrderNumber     NVARCHAR(40) NOT NULL,
      BOMId               BIGINT NOT NULL,
      ProductId           BIGINT NOT NULL,
      PlannedQuantity     DECIMAL(18,3) NOT NULL,
      ProducedQuantity    DECIMAL(18,3) NOT NULL CONSTRAINT DF_mfg_WO_ProducedQty DEFAULT(0),
      ScrapQuantity       DECIMAL(18,3) NOT NULL CONSTRAINT DF_mfg_WO_ScrapQty DEFAULT(0),
      PlannedStartDate    DATE NOT NULL,
      PlannedEndDate      DATE NOT NULL,
      ActualStartDate     DATETIME2(0) NULL,
      ActualEndDate       DATETIME2(0) NULL,
      Status              NVARCHAR(15) NOT NULL CONSTRAINT DF_mfg_WO_Status DEFAULT('DRAFT'),
      Priority            NVARCHAR(10) NOT NULL CONSTRAINT DF_mfg_WO_Priority DEFAULT('MEDIUM'),
      WarehouseId         BIGINT NULL,
      Notes               NVARCHAR(MAX) NULL,
      AssignedToUserId    INT NULL,
      CreatedAt           DATETIME2(0) NOT NULL CONSTRAINT DF_mfg_WO_CreatedAt DEFAULT(SYSUTCDATETIME()),
      UpdatedAt           DATETIME2(0) NOT NULL CONSTRAINT DF_mfg_WO_UpdatedAt DEFAULT(SYSUTCDATETIME()),
      CreatedByUserId     INT NULL,
      UpdatedByUserId     INT NULL,
      IsDeleted           BIT NOT NULL CONSTRAINT DF_mfg_WO_IsDeleted DEFAULT(0),
      DeletedAt           DATETIME2(0) NULL,
      DeletedByUserId     INT NULL,
      RowVer              ROWVERSION NOT NULL,
      CONSTRAINT UQ_mfg_WorkOrder_Number UNIQUE (CompanyId, WorkOrderNumber),
      CONSTRAINT CK_mfg_WO_Status CHECK (Status IN ('DRAFT','PLANNED','IN_PROGRESS','COMPLETED','CANCELLED')),
      CONSTRAINT CK_mfg_WO_Priority CHECK (Priority IN ('LOW','MEDIUM','HIGH','URGENT')),
      CONSTRAINT FK_mfg_WO_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId),
      CONSTRAINT FK_mfg_WO_Branch FOREIGN KEY (BranchId) REFERENCES cfg.Branch(BranchId),
      CONSTRAINT FK_mfg_WO_BOM FOREIGN KEY (BOMId) REFERENCES mfg.BillOfMaterials(BOMId),
      CONSTRAINT FK_mfg_WO_Product FOREIGN KEY (ProductId) REFERENCES master.Product(ProductId),
      CONSTRAINT FK_mfg_WO_Warehouse FOREIGN KEY (WarehouseId) REFERENCES inv.Warehouse(WarehouseId),
      CONSTRAINT FK_mfg_WO_AssignedTo FOREIGN KEY (AssignedToUserId) REFERENCES sec.[User](UserId),
      CONSTRAINT FK_mfg_WO_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
      CONSTRAINT FK_mfg_WO_UpdatedBy FOREIGN KEY (UpdatedByUserId) REFERENCES sec.[User](UserId),
      CONSTRAINT FK_mfg_WO_DeletedBy FOREIGN KEY (DeletedByUserId) REFERENCES sec.[User](UserId)
    );

    CREATE INDEX IX_mfg_WorkOrder_Status
      ON mfg.WorkOrder (CompanyId, Status, PlannedStartDate);
  END;

  -- =========================================================================
  -- 6. mfg.WorkOrderMaterial
  -- =========================================================================
  IF OBJECT_ID('mfg.WorkOrderMaterial', 'U') IS NULL
  BEGIN
    CREATE TABLE mfg.WorkOrderMaterial(
      MaterialId          BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      WorkOrderId         BIGINT NOT NULL,
      BOMLineId           BIGINT NULL,
      ProductId           BIGINT NOT NULL,
      PlannedQuantity     DECIMAL(18,3) NOT NULL,
      ConsumedQuantity    DECIMAL(18,3) NOT NULL CONSTRAINT DF_mfg_WOM_ConsumedQty DEFAULT(0),
      UnitCost            DECIMAL(18,4) NOT NULL CONSTRAINT DF_mfg_WOM_UnitCost DEFAULT(0),
      LotNumber           NVARCHAR(60) NULL,
      WarehouseId         BIGINT NULL,
      CreatedAt           DATETIME2(0) NOT NULL CONSTRAINT DF_mfg_WOM_CreatedAt DEFAULT(SYSUTCDATETIME()),
      UpdatedAt           DATETIME2(0) NOT NULL CONSTRAINT DF_mfg_WOM_UpdatedAt DEFAULT(SYSUTCDATETIME()),
      CreatedByUserId     INT NULL,
      UpdatedByUserId     INT NULL,
      IsDeleted           BIT NOT NULL CONSTRAINT DF_mfg_WOM_IsDeleted DEFAULT(0),
      DeletedAt           DATETIME2(0) NULL,
      DeletedByUserId     INT NULL,
      RowVer              ROWVERSION NOT NULL,
      CONSTRAINT UQ_mfg_WOM_Product_Lot UNIQUE (WorkOrderId, ProductId, LotNumber),
      CONSTRAINT FK_mfg_WOM_WorkOrder FOREIGN KEY (WorkOrderId) REFERENCES mfg.WorkOrder(WorkOrderId),
      CONSTRAINT FK_mfg_WOM_BOMLine FOREIGN KEY (BOMLineId) REFERENCES mfg.BOMLine(BOMLineId),
      CONSTRAINT FK_mfg_WOM_Product FOREIGN KEY (ProductId) REFERENCES master.Product(ProductId),
      CONSTRAINT FK_mfg_WOM_Warehouse FOREIGN KEY (WarehouseId) REFERENCES inv.Warehouse(WarehouseId),
      CONSTRAINT FK_mfg_WOM_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
      CONSTRAINT FK_mfg_WOM_UpdatedBy FOREIGN KEY (UpdatedByUserId) REFERENCES sec.[User](UserId),
      CONSTRAINT FK_mfg_WOM_DeletedBy FOREIGN KEY (DeletedByUserId) REFERENCES sec.[User](UserId)
    );
  END;

  -- =========================================================================
  -- 7. mfg.WorkOrderOutput
  -- =========================================================================
  IF OBJECT_ID('mfg.WorkOrderOutput', 'U') IS NULL
  BEGIN
    CREATE TABLE mfg.WorkOrderOutput(
      OutputId            BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      WorkOrderId         BIGINT NOT NULL,
      ProductId           BIGINT NOT NULL,
      Quantity            DECIMAL(18,3) NOT NULL,
      UnitCost            DECIMAL(18,4) NOT NULL CONSTRAINT DF_mfg_WOO_UnitCost DEFAULT(0),
      LotNumber           NVARCHAR(60) NULL,
      WarehouseId         BIGINT NULL,
      BinId               BIGINT NULL,
      OutputDate          DATETIME2(0) NOT NULL,
      CreatedByUserId     INT NULL,
      CreatedAt           DATETIME2(0) NOT NULL CONSTRAINT DF_mfg_WOO_CreatedAt DEFAULT(SYSUTCDATETIME()),
      CONSTRAINT FK_mfg_WOO_WorkOrder FOREIGN KEY (WorkOrderId) REFERENCES mfg.WorkOrder(WorkOrderId),
      CONSTRAINT FK_mfg_WOO_Product FOREIGN KEY (ProductId) REFERENCES master.Product(ProductId),
      CONSTRAINT FK_mfg_WOO_Warehouse FOREIGN KEY (WarehouseId) REFERENCES inv.Warehouse(WarehouseId),
      CONSTRAINT FK_mfg_WOO_Bin FOREIGN KEY (BinId) REFERENCES inv.WarehouseBin(BinId),
      CONSTRAINT FK_mfg_WOO_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId)
    );
  END;

  COMMIT TRAN;
  PRINT '[12_manufacturing] Esquema MFG creado correctamente.';
END TRY
BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRAN;
  PRINT '[12_manufacturing] ERROR: ' + ERROR_MESSAGE();
  THROW;
END CATCH;
GO
