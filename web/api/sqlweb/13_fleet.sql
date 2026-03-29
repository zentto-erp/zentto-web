-- =============================================================================
-- 13_fleet.sql
-- Fleet Management: Vehicles, Fuel Logs, Maintenance Types/Orders/Lines,
--                   Trips, Vehicle Documents
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
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'fleet')
  EXEC('CREATE SCHEMA fleet');
GO

BEGIN TRY
  BEGIN TRAN;

  -- =========================================================================
  -- 1. fleet.Vehicle
  -- =========================================================================
  IF OBJECT_ID('fleet.Vehicle', 'U') IS NULL
  BEGIN
    CREATE TABLE fleet.Vehicle(
      VehicleId               BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      CompanyId               INT NOT NULL,
      VehiclePlate            NVARCHAR(20) NOT NULL,
      VIN                     NVARCHAR(30) NULL,
      Brand                   NVARCHAR(50) NOT NULL,
      Model                   NVARCHAR(50) NOT NULL,
      [Year]                  INT NOT NULL,
      Color                   NVARCHAR(30) NULL,
      VehicleType             NVARCHAR(15) NOT NULL CONSTRAINT DF_fleet_Vehicle_Type DEFAULT('CAR'),
      FuelType                NVARCHAR(15) NOT NULL CONSTRAINT DF_fleet_Vehicle_FuelType DEFAULT('GASOLINE'),
      CurrentMileage          DECIMAL(12,1) NOT NULL CONSTRAINT DF_fleet_Vehicle_Mileage DEFAULT(0),
      Status                  NVARCHAR(15) NOT NULL CONSTRAINT DF_fleet_Vehicle_Status DEFAULT('ACTIVE'),
      PurchaseDate            DATE NULL,
      PurchaseCost            DECIMAL(18,2) NULL,
      FixedAssetId            BIGINT NULL,
      InsurancePolicy         NVARCHAR(60) NULL,
      InsuranceExpiry         DATE NULL,
      TechnicalReviewExpiry   DATE NULL,
      PermitExpiry            DATE NULL,
      AssignedDriverId        BIGINT NULL,
      AssignedBranchId        INT NULL,
      Notes                   NVARCHAR(MAX) NULL,
      IsActive                BIT NOT NULL CONSTRAINT DF_fleet_Vehicle_IsActive DEFAULT(1),
      CreatedAt               DATETIME2(0) NOT NULL CONSTRAINT DF_fleet_Vehicle_CreatedAt DEFAULT(SYSUTCDATETIME()),
      UpdatedAt               DATETIME2(0) NOT NULL CONSTRAINT DF_fleet_Vehicle_UpdatedAt DEFAULT(SYSUTCDATETIME()),
      CreatedByUserId         INT NULL,
      UpdatedByUserId         INT NULL,
      IsDeleted               BIT NOT NULL CONSTRAINT DF_fleet_Vehicle_IsDeleted DEFAULT(0),
      DeletedAt               DATETIME2(0) NULL,
      DeletedByUserId         INT NULL,
      RowVer                  ROWVERSION NOT NULL,
      CONSTRAINT UQ_fleet_Vehicle_Plate UNIQUE (CompanyId, VehiclePlate),
      CONSTRAINT CK_fleet_Vehicle_Type CHECK (VehicleType IN ('CAR','TRUCK','VAN','MOTORCYCLE','HEAVY')),
      CONSTRAINT CK_fleet_Vehicle_FuelType CHECK (FuelType IN ('GASOLINE','DIESEL','ELECTRIC','HYBRID','GAS')),
      CONSTRAINT CK_fleet_Vehicle_Status CHECK (Status IN ('ACTIVE','MAINTENANCE','INACTIVE','SOLD')),
      CONSTRAINT FK_fleet_Vehicle_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId),
      CONSTRAINT FK_fleet_Vehicle_Branch FOREIGN KEY (AssignedBranchId) REFERENCES cfg.Branch(BranchId),
      -- FK a logistics.Driver (schema pendiente de creacion)
      -- CONSTRAINT FK_fleet_Vehicle_Driver FOREIGN KEY (AssignedDriverId) REFERENCES logistics.Driver(DriverId),
      CONSTRAINT FK_fleet_Vehicle_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
      CONSTRAINT FK_fleet_Vehicle_UpdatedBy FOREIGN KEY (UpdatedByUserId) REFERENCES sec.[User](UserId),
      CONSTRAINT FK_fleet_Vehicle_DeletedBy FOREIGN KEY (DeletedByUserId) REFERENCES sec.[User](UserId)
    );
  END;

  -- Agregar FK a acct.FixedAsset si la tabla existe
  IF OBJECT_ID('acct.FixedAsset', 'U') IS NOT NULL
    AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_fleet_Vehicle_FixedAsset')
  BEGIN
    ALTER TABLE fleet.Vehicle
      ADD CONSTRAINT FK_fleet_Vehicle_FixedAsset
      FOREIGN KEY (FixedAssetId) REFERENCES acct.FixedAsset(FixedAssetId);
  END;

  -- =========================================================================
  -- 2. fleet.FuelLog
  -- =========================================================================
  IF OBJECT_ID('fleet.FuelLog', 'U') IS NULL
  BEGIN
    CREATE TABLE fleet.FuelLog(
      FuelLogId           BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      CompanyId           INT NOT NULL,
      VehicleId           BIGINT NOT NULL,
      LogDate             DATETIME2(0) NOT NULL,
      Mileage             DECIMAL(12,1) NOT NULL,
      FuelType            NVARCHAR(15) NOT NULL,
      Liters              DECIMAL(10,2) NOT NULL,
      PricePerLiter       DECIMAL(18,4) NOT NULL,
      TotalCost           DECIMAL(18,2) NOT NULL,
      StationName         NVARCHAR(200) NULL,
      DriverId            BIGINT NULL,
      Notes               NVARCHAR(500) NULL,
      CreatedAt           DATETIME2(0) NOT NULL CONSTRAINT DF_fleet_FuelLog_CreatedAt DEFAULT(SYSUTCDATETIME()),
      UpdatedAt           DATETIME2(0) NOT NULL CONSTRAINT DF_fleet_FuelLog_UpdatedAt DEFAULT(SYSUTCDATETIME()),
      CreatedByUserId     INT NULL,
      UpdatedByUserId     INT NULL,
      IsDeleted           BIT NOT NULL CONSTRAINT DF_fleet_FuelLog_IsDeleted DEFAULT(0),
      DeletedAt           DATETIME2(0) NULL,
      DeletedByUserId     INT NULL,
      RowVer              ROWVERSION NOT NULL,
      CONSTRAINT FK_fleet_FuelLog_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId),
      CONSTRAINT FK_fleet_FuelLog_Vehicle FOREIGN KEY (VehicleId) REFERENCES fleet.Vehicle(VehicleId),
      -- FK a logistics.Driver (schema pendiente de creacion)
      -- CONSTRAINT FK_fleet_FuelLog_Driver FOREIGN KEY (DriverId) REFERENCES logistics.Driver(DriverId),
      CONSTRAINT FK_fleet_FuelLog_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
      CONSTRAINT FK_fleet_FuelLog_UpdatedBy FOREIGN KEY (UpdatedByUserId) REFERENCES sec.[User](UserId),
      CONSTRAINT FK_fleet_FuelLog_DeletedBy FOREIGN KEY (DeletedByUserId) REFERENCES sec.[User](UserId)
    );

    CREATE INDEX IX_fleet_FuelLog_Vehicle
      ON fleet.FuelLog (CompanyId, VehicleId, LogDate DESC);
  END;

  -- =========================================================================
  -- 3. fleet.MaintenanceType
  -- =========================================================================
  IF OBJECT_ID('fleet.MaintenanceType', 'U') IS NULL
  BEGIN
    CREATE TABLE fleet.MaintenanceType(
      MaintenanceTypeId   BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      CompanyId           INT NOT NULL,
      TypeCode            NVARCHAR(20) NOT NULL,
      TypeName            NVARCHAR(200) NOT NULL,
      Category            NVARCHAR(15) NOT NULL CONSTRAINT DF_fleet_MaintType_Category DEFAULT('PREVENTIVE'),
      DefaultIntervalKm   DECIMAL(12,1) NULL,
      DefaultIntervalDays INT NULL,
      IsActive            BIT NOT NULL CONSTRAINT DF_fleet_MaintType_IsActive DEFAULT(1),
      CreatedAt           DATETIME2(0) NOT NULL CONSTRAINT DF_fleet_MaintType_CreatedAt DEFAULT(SYSUTCDATETIME()),
      UpdatedAt           DATETIME2(0) NOT NULL CONSTRAINT DF_fleet_MaintType_UpdatedAt DEFAULT(SYSUTCDATETIME()),
      CreatedByUserId     INT NULL,
      UpdatedByUserId     INT NULL,
      IsDeleted           BIT NOT NULL CONSTRAINT DF_fleet_MaintType_IsDeleted DEFAULT(0),
      DeletedAt           DATETIME2(0) NULL,
      DeletedByUserId     INT NULL,
      RowVer              ROWVERSION NOT NULL,
      CONSTRAINT UQ_fleet_MaintType_Code UNIQUE (CompanyId, TypeCode),
      CONSTRAINT CK_fleet_MaintType_Category CHECK (Category IN ('PREVENTIVE','CORRECTIVE','INSPECTION')),
      CONSTRAINT FK_fleet_MaintType_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId),
      CONSTRAINT FK_fleet_MaintType_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
      CONSTRAINT FK_fleet_MaintType_UpdatedBy FOREIGN KEY (UpdatedByUserId) REFERENCES sec.[User](UserId),
      CONSTRAINT FK_fleet_MaintType_DeletedBy FOREIGN KEY (DeletedByUserId) REFERENCES sec.[User](UserId)
    );
  END;

  -- =========================================================================
  -- 4. fleet.MaintenanceOrder
  -- =========================================================================
  IF OBJECT_ID('fleet.MaintenanceOrder', 'U') IS NULL
  BEGIN
    CREATE TABLE fleet.MaintenanceOrder(
      MaintenanceOrderId  BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      CompanyId           INT NOT NULL,
      BranchId            INT NOT NULL,
      OrderNumber         NVARCHAR(40) NOT NULL,
      VehicleId           BIGINT NOT NULL,
      MaintenanceTypeId   BIGINT NOT NULL,
      MileageAtService    DECIMAL(12,1) NOT NULL CONSTRAINT DF_fleet_MaintOrd_Mileage DEFAULT(0),
      ScheduledDate       DATE NOT NULL,
      CompletedDate       DATE NULL,
      Status              NVARCHAR(15) NOT NULL CONSTRAINT DF_fleet_MaintOrd_Status DEFAULT('SCHEDULED'),
      SupplierId          BIGINT NULL,
      EstimatedCost       DECIMAL(18,2) NOT NULL CONSTRAINT DF_fleet_MaintOrd_EstCost DEFAULT(0),
      ActualCost          DECIMAL(18,2) NOT NULL CONSTRAINT DF_fleet_MaintOrd_ActCost DEFAULT(0),
      Description         NVARCHAR(500) NULL,
      Notes               NVARCHAR(MAX) NULL,
      CreatedAt           DATETIME2(0) NOT NULL CONSTRAINT DF_fleet_MaintOrd_CreatedAt DEFAULT(SYSUTCDATETIME()),
      UpdatedAt           DATETIME2(0) NOT NULL CONSTRAINT DF_fleet_MaintOrd_UpdatedAt DEFAULT(SYSUTCDATETIME()),
      CreatedByUserId     INT NULL,
      UpdatedByUserId     INT NULL,
      IsDeleted           BIT NOT NULL CONSTRAINT DF_fleet_MaintOrd_IsDeleted DEFAULT(0),
      DeletedAt           DATETIME2(0) NULL,
      DeletedByUserId     INT NULL,
      RowVer              ROWVERSION NOT NULL,
      CONSTRAINT UQ_fleet_MaintOrd_Number UNIQUE (CompanyId, OrderNumber),
      CONSTRAINT CK_fleet_MaintOrd_Status CHECK (Status IN ('SCHEDULED','IN_PROGRESS','COMPLETED','CANCELLED')),
      CONSTRAINT FK_fleet_MaintOrd_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId),
      CONSTRAINT FK_fleet_MaintOrd_Branch FOREIGN KEY (BranchId) REFERENCES cfg.Branch(BranchId),
      CONSTRAINT FK_fleet_MaintOrd_Vehicle FOREIGN KEY (VehicleId) REFERENCES fleet.Vehicle(VehicleId),
      CONSTRAINT FK_fleet_MaintOrd_MaintType FOREIGN KEY (MaintenanceTypeId) REFERENCES fleet.MaintenanceType(MaintenanceTypeId),
      CONSTRAINT FK_fleet_MaintOrd_Supplier FOREIGN KEY (SupplierId) REFERENCES master.Supplier(SupplierId),
      CONSTRAINT FK_fleet_MaintOrd_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
      CONSTRAINT FK_fleet_MaintOrd_UpdatedBy FOREIGN KEY (UpdatedByUserId) REFERENCES sec.[User](UserId),
      CONSTRAINT FK_fleet_MaintOrd_DeletedBy FOREIGN KEY (DeletedByUserId) REFERENCES sec.[User](UserId)
    );

    CREATE INDEX IX_fleet_MaintOrd_Vehicle
      ON fleet.MaintenanceOrder (CompanyId, VehicleId, Status);
  END;

  -- =========================================================================
  -- 5. fleet.MaintenanceOrderLine
  -- =========================================================================
  IF OBJECT_ID('fleet.MaintenanceOrderLine', 'U') IS NULL
  BEGIN
    CREATE TABLE fleet.MaintenanceOrderLine(
      LineId              BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      MaintenanceOrderId  BIGINT NOT NULL,
      LineNumber          INT NOT NULL,
      Description         NVARCHAR(250) NOT NULL,
      Quantity            DECIMAL(18,3) NOT NULL CONSTRAINT DF_fleet_MaintLine_Qty DEFAULT(1),
      UnitCost            DECIMAL(18,4) NOT NULL CONSTRAINT DF_fleet_MaintLine_UnitCost DEFAULT(0),
      TotalCost           DECIMAL(18,2) NOT NULL CONSTRAINT DF_fleet_MaintLine_TotalCost DEFAULT(0),
      ProductId           BIGINT NULL,
      LineType            NVARCHAR(10) NOT NULL CONSTRAINT DF_fleet_MaintLine_LineType DEFAULT('SERVICE'),
      CreatedAt           DATETIME2(0) NOT NULL CONSTRAINT DF_fleet_MaintLine_CreatedAt DEFAULT(SYSUTCDATETIME()),
      UpdatedAt           DATETIME2(0) NOT NULL CONSTRAINT DF_fleet_MaintLine_UpdatedAt DEFAULT(SYSUTCDATETIME()),
      CreatedByUserId     INT NULL,
      UpdatedByUserId     INT NULL,
      IsDeleted           BIT NOT NULL CONSTRAINT DF_fleet_MaintLine_IsDeleted DEFAULT(0),
      DeletedAt           DATETIME2(0) NULL,
      DeletedByUserId     INT NULL,
      RowVer              ROWVERSION NOT NULL,
      CONSTRAINT UQ_fleet_MaintLine_Number UNIQUE (MaintenanceOrderId, LineNumber),
      CONSTRAINT CK_fleet_MaintLine_LineType CHECK (LineType IN ('PART','LABOR','SERVICE')),
      CONSTRAINT FK_fleet_MaintLine_Order FOREIGN KEY (MaintenanceOrderId) REFERENCES fleet.MaintenanceOrder(MaintenanceOrderId),
      CONSTRAINT FK_fleet_MaintLine_Product FOREIGN KEY (ProductId) REFERENCES master.Product(ProductId),
      CONSTRAINT FK_fleet_MaintLine_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
      CONSTRAINT FK_fleet_MaintLine_UpdatedBy FOREIGN KEY (UpdatedByUserId) REFERENCES sec.[User](UserId),
      CONSTRAINT FK_fleet_MaintLine_DeletedBy FOREIGN KEY (DeletedByUserId) REFERENCES sec.[User](UserId)
    );
  END;

  -- =========================================================================
  -- 6. fleet.Trip
  -- =========================================================================
  IF OBJECT_ID('fleet.Trip', 'U') IS NULL
  BEGIN
    CREATE TABLE fleet.Trip(
      TripId              BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      CompanyId           INT NOT NULL,
      VehicleId           BIGINT NOT NULL,
      DriverId            BIGINT NULL,
      TripNumber          NVARCHAR(40) NOT NULL,
      Origin              NVARCHAR(200) NOT NULL,
      Destination         NVARCHAR(200) NOT NULL,
      DepartureDate       DATETIME2(0) NOT NULL,
      ArrivalDate         DATETIME2(0) NULL,
      StartMileage        DECIMAL(12,1) NOT NULL,
      EndMileage          DECIMAL(12,1) NULL,
      Distance            AS (EndMileage - StartMileage) PERSISTED,
      FuelUsed            DECIMAL(10,2) NULL,
      Status              NVARCHAR(15) NOT NULL CONSTRAINT DF_fleet_Trip_Status DEFAULT('PLANNED'),
      DeliveryNoteId      BIGINT NULL,
      Notes               NVARCHAR(MAX) NULL,
      CreatedAt           DATETIME2(0) NOT NULL CONSTRAINT DF_fleet_Trip_CreatedAt DEFAULT(SYSUTCDATETIME()),
      UpdatedAt           DATETIME2(0) NOT NULL CONSTRAINT DF_fleet_Trip_UpdatedAt DEFAULT(SYSUTCDATETIME()),
      CreatedByUserId     INT NULL,
      UpdatedByUserId     INT NULL,
      IsDeleted           BIT NOT NULL CONSTRAINT DF_fleet_Trip_IsDeleted DEFAULT(0),
      DeletedAt           DATETIME2(0) NULL,
      DeletedByUserId     INT NULL,
      RowVer              ROWVERSION NOT NULL,
      CONSTRAINT UQ_fleet_Trip_Number UNIQUE (CompanyId, TripNumber),
      CONSTRAINT CK_fleet_Trip_Status CHECK (Status IN ('PLANNED','IN_PROGRESS','COMPLETED','CANCELLED')),
      CONSTRAINT FK_fleet_Trip_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId),
      CONSTRAINT FK_fleet_Trip_Vehicle FOREIGN KEY (VehicleId) REFERENCES fleet.Vehicle(VehicleId),
      -- FK a logistics.Driver y logistics.DeliveryNote (schema pendiente de creacion)
      -- CONSTRAINT FK_fleet_Trip_Driver FOREIGN KEY (DriverId) REFERENCES logistics.Driver(DriverId),
      -- CONSTRAINT FK_fleet_Trip_DeliveryNote FOREIGN KEY (DeliveryNoteId) REFERENCES logistics.DeliveryNote(DeliveryNoteId),
      CONSTRAINT FK_fleet_Trip_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
      CONSTRAINT FK_fleet_Trip_UpdatedBy FOREIGN KEY (UpdatedByUserId) REFERENCES sec.[User](UserId),
      CONSTRAINT FK_fleet_Trip_DeletedBy FOREIGN KEY (DeletedByUserId) REFERENCES sec.[User](UserId)
    );
  END;

  -- =========================================================================
  -- 7. fleet.VehicleDocument
  -- =========================================================================
  IF OBJECT_ID('fleet.VehicleDocument', 'U') IS NULL
  BEGIN
    CREATE TABLE fleet.VehicleDocument(
      DocumentId          BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      CompanyId           INT NOT NULL,
      VehicleId           BIGINT NOT NULL,
      DocumentType        NVARCHAR(20) NOT NULL CONSTRAINT DF_fleet_VehDoc_Type DEFAULT('OTHER'),
      DocumentNumber      NVARCHAR(60) NULL,
      IssueDate           DATE NOT NULL,
      ExpiryDate          DATE NULL,
      FilePath            NVARCHAR(500) NULL,
      Notes               NVARCHAR(500) NULL,
      CreatedAt           DATETIME2(0) NOT NULL CONSTRAINT DF_fleet_VehDoc_CreatedAt DEFAULT(SYSUTCDATETIME()),
      UpdatedAt           DATETIME2(0) NOT NULL CONSTRAINT DF_fleet_VehDoc_UpdatedAt DEFAULT(SYSUTCDATETIME()),
      CreatedByUserId     INT NULL,
      UpdatedByUserId     INT NULL,
      IsDeleted           BIT NOT NULL CONSTRAINT DF_fleet_VehDoc_IsDeleted DEFAULT(0),
      DeletedAt           DATETIME2(0) NULL,
      DeletedByUserId     INT NULL,
      RowVer              ROWVERSION NOT NULL,
      CONSTRAINT CK_fleet_VehDoc_Type CHECK (DocumentType IN ('INSURANCE','TECHNICAL_REVIEW','PERMIT','TITLE','OTHER')),
      CONSTRAINT FK_fleet_VehDoc_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId),
      CONSTRAINT FK_fleet_VehDoc_Vehicle FOREIGN KEY (VehicleId) REFERENCES fleet.Vehicle(VehicleId),
      CONSTRAINT FK_fleet_VehDoc_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
      CONSTRAINT FK_fleet_VehDoc_UpdatedBy FOREIGN KEY (UpdatedByUserId) REFERENCES sec.[User](UserId),
      CONSTRAINT FK_fleet_VehDoc_DeletedBy FOREIGN KEY (DeletedByUserId) REFERENCES sec.[User](UserId)
    );
  END;

  COMMIT TRAN;
  PRINT '[13_fleet] Esquema Fleet creado correctamente.';
END TRY
BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRAN;
  PRINT '[13_fleet] ERROR: ' + ERROR_MESSAGE();
  THROW;
END CATCH;
GO
