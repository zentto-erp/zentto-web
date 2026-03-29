SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

USE DatqBoxWeb;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

BEGIN TRY
  BEGIN TRAN;

  IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'inv') EXEC('CREATE SCHEMA inv');

  -- ============================================================
  -- 1. inv.Warehouse  (Almacenes — version canonica)
  -- ============================================================
  IF OBJECT_ID('inv.Warehouse', 'U') IS NULL
  BEGIN
    CREATE TABLE inv.Warehouse(
      WarehouseId               BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      CompanyId                 INT NOT NULL,
      BranchId                  INT NOT NULL,
      WarehouseCode             NVARCHAR(20) NOT NULL,
      WarehouseName             NVARCHAR(200) NOT NULL,
      AddressLine               NVARCHAR(400) NULL,
      ContactName               NVARCHAR(200) NULL,
      Phone                     NVARCHAR(60) NULL,
      IsActive                  BIT NOT NULL CONSTRAINT DF_inv_Warehouse_IsActive DEFAULT(1),
      IsDeleted                 BIT NOT NULL CONSTRAINT DF_inv_Warehouse_IsDeleted DEFAULT(0),
      DeletedAt                 DATETIME2(0) NULL,
      DeletedByUserId           INT NULL,
      CreatedAt                 DATETIME2(0) NOT NULL CONSTRAINT DF_inv_Warehouse_CreatedAt DEFAULT(SYSUTCDATETIME()),
      UpdatedAt                 DATETIME2(0) NOT NULL CONSTRAINT DF_inv_Warehouse_UpdatedAt DEFAULT(SYSUTCDATETIME()),
      CreatedByUserId           INT NULL,
      UpdatedByUserId           INT NULL,
      RowVer                    ROWVERSION NOT NULL,
      CONSTRAINT UQ_inv_Warehouse_Code UNIQUE (CompanyId, WarehouseCode),
      CONSTRAINT FK_inv_Warehouse_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId),
      CONSTRAINT FK_inv_Warehouse_Branch FOREIGN KEY (BranchId) REFERENCES cfg.Branch(BranchId),
      CONSTRAINT FK_inv_Warehouse_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
      CONSTRAINT FK_inv_Warehouse_UpdatedBy FOREIGN KEY (UpdatedByUserId) REFERENCES sec.[User](UserId),
      CONSTRAINT FK_inv_Warehouse_DeletedBy FOREIGN KEY (DeletedByUserId) REFERENCES sec.[User](UserId)
    );

    CREATE INDEX IX_inv_Warehouse_Company
      ON inv.Warehouse (CompanyId, IsDeleted, IsActive);
  END;
  GO

  -- ============================================================
  -- 2. inv.WarehouseZone  (Zonas dentro del almacen)
  -- ============================================================
  IF OBJECT_ID('inv.WarehouseZone', 'U') IS NULL
  BEGIN
    CREATE TABLE inv.WarehouseZone(
      ZoneId                    BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      WarehouseId               BIGINT NOT NULL,
      ZoneCode                  NVARCHAR(20) NOT NULL,
      ZoneName                  NVARCHAR(200) NOT NULL,
      ZoneType                  NVARCHAR(20) NOT NULL CONSTRAINT DF_inv_WarehouseZone_Type DEFAULT(N'STORAGE'),
      Temperature               NVARCHAR(20) NOT NULL CONSTRAINT DF_inv_WarehouseZone_Temp DEFAULT(N'AMBIENT'),
      IsActive                  BIT NOT NULL CONSTRAINT DF_inv_WarehouseZone_IsActive DEFAULT(1),
      IsDeleted                 BIT NOT NULL CONSTRAINT DF_inv_WarehouseZone_IsDeleted DEFAULT(0),
      DeletedAt                 DATETIME2(0) NULL,
      DeletedByUserId           INT NULL,
      CreatedAt                 DATETIME2(0) NOT NULL CONSTRAINT DF_inv_WarehouseZone_CreatedAt DEFAULT(SYSUTCDATETIME()),
      UpdatedAt                 DATETIME2(0) NOT NULL CONSTRAINT DF_inv_WarehouseZone_UpdatedAt DEFAULT(SYSUTCDATETIME()),
      CreatedByUserId           INT NULL,
      UpdatedByUserId           INT NULL,
      RowVer                    ROWVERSION NOT NULL,
      CONSTRAINT CK_inv_WarehouseZone_Type CHECK (ZoneType IN (N'RECEIVING', N'STORAGE', N'PICKING', N'SHIPPING', N'QUARANTINE')),
      CONSTRAINT CK_inv_WarehouseZone_Temp CHECK (Temperature IN (N'AMBIENT', N'COLD', N'FROZEN')),
      CONSTRAINT UQ_inv_WarehouseZone_Code UNIQUE (WarehouseId, ZoneCode),
      CONSTRAINT FK_inv_WarehouseZone_Warehouse FOREIGN KEY (WarehouseId) REFERENCES inv.Warehouse(WarehouseId),
      CONSTRAINT FK_inv_WarehouseZone_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
      CONSTRAINT FK_inv_WarehouseZone_UpdatedBy FOREIGN KEY (UpdatedByUserId) REFERENCES sec.[User](UserId),
      CONSTRAINT FK_inv_WarehouseZone_DeletedBy FOREIGN KEY (DeletedByUserId) REFERENCES sec.[User](UserId)
    );

    CREATE INDEX IX_inv_WarehouseZone_Warehouse
      ON inv.WarehouseZone (WarehouseId, IsDeleted, IsActive);
  END;
  GO

  -- ============================================================
  -- 3. inv.WarehouseBin  (Ubicaciones — estantes, racks)
  -- ============================================================
  IF OBJECT_ID('inv.WarehouseBin', 'U') IS NULL
  BEGIN
    CREATE TABLE inv.WarehouseBin(
      BinId                     BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      ZoneId                    BIGINT NOT NULL,
      BinCode                   NVARCHAR(30) NOT NULL,
      BinName                   NVARCHAR(200) NULL,
      MaxWeight                 DECIMAL(18,2) NULL,
      MaxVolume                 DECIMAL(18,2) NULL,
      IsActive                  BIT NOT NULL CONSTRAINT DF_inv_WarehouseBin_IsActive DEFAULT(1),
      IsDeleted                 BIT NOT NULL CONSTRAINT DF_inv_WarehouseBin_IsDeleted DEFAULT(0),
      DeletedAt                 DATETIME2(0) NULL,
      DeletedByUserId           INT NULL,
      CreatedAt                 DATETIME2(0) NOT NULL CONSTRAINT DF_inv_WarehouseBin_CreatedAt DEFAULT(SYSUTCDATETIME()),
      UpdatedAt                 DATETIME2(0) NOT NULL CONSTRAINT DF_inv_WarehouseBin_UpdatedAt DEFAULT(SYSUTCDATETIME()),
      CreatedByUserId           INT NULL,
      UpdatedByUserId           INT NULL,
      RowVer                    ROWVERSION NOT NULL,
      CONSTRAINT UQ_inv_WarehouseBin_Code UNIQUE (ZoneId, BinCode),
      CONSTRAINT FK_inv_WarehouseBin_Zone FOREIGN KEY (ZoneId) REFERENCES inv.WarehouseZone(ZoneId),
      CONSTRAINT FK_inv_WarehouseBin_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
      CONSTRAINT FK_inv_WarehouseBin_UpdatedBy FOREIGN KEY (UpdatedByUserId) REFERENCES sec.[User](UserId),
      CONSTRAINT FK_inv_WarehouseBin_DeletedBy FOREIGN KEY (DeletedByUserId) REFERENCES sec.[User](UserId)
    );

    CREATE INDEX IX_inv_WarehouseBin_Zone
      ON inv.WarehouseBin (ZoneId, IsDeleted, IsActive);
  END;
  GO

  -- ============================================================
  -- 4. inv.ProductLot  (Lotes de productos)
  -- ============================================================
  IF OBJECT_ID('inv.ProductLot', 'U') IS NULL
  BEGIN
    CREATE TABLE inv.ProductLot(
      LotId                     BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      CompanyId                 INT NOT NULL,
      ProductId                 BIGINT NOT NULL,
      LotNumber                 NVARCHAR(60) NOT NULL,
      ManufactureDate           DATE NULL,
      ExpiryDate                DATE NULL,
      SupplierCode              NVARCHAR(24) NULL,
      PurchaseDocumentNumber    NVARCHAR(60) NULL,
      InitialQuantity           DECIMAL(18,3) NOT NULL CONSTRAINT DF_inv_ProductLot_InitQty DEFAULT(0),
      CurrentQuantity           DECIMAL(18,3) NOT NULL CONSTRAINT DF_inv_ProductLot_CurrQty DEFAULT(0),
      UnitCost                  DECIMAL(18,4) NOT NULL CONSTRAINT DF_inv_ProductLot_UnitCost DEFAULT(0),
      Status                    NVARCHAR(20) NOT NULL CONSTRAINT DF_inv_ProductLot_Status DEFAULT(N'ACTIVE'),
      Notes                     NVARCHAR(500) NULL,
      IsDeleted                 BIT NOT NULL CONSTRAINT DF_inv_ProductLot_IsDeleted DEFAULT(0),
      DeletedAt                 DATETIME2(0) NULL,
      DeletedByUserId           INT NULL,
      CreatedAt                 DATETIME2(0) NOT NULL CONSTRAINT DF_inv_ProductLot_CreatedAt DEFAULT(SYSUTCDATETIME()),
      UpdatedAt                 DATETIME2(0) NOT NULL CONSTRAINT DF_inv_ProductLot_UpdatedAt DEFAULT(SYSUTCDATETIME()),
      CreatedByUserId           INT NULL,
      UpdatedByUserId           INT NULL,
      RowVer                    ROWVERSION NOT NULL,
      CONSTRAINT CK_inv_ProductLot_Status CHECK (Status IN (N'ACTIVE', N'DEPLETED', N'EXPIRED', N'QUARANTINE', N'BLOCKED')),
      CONSTRAINT UQ_inv_ProductLot UNIQUE (CompanyId, ProductId, LotNumber),
      CONSTRAINT FK_inv_ProductLot_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId),
      CONSTRAINT FK_inv_ProductLot_Product FOREIGN KEY (ProductId) REFERENCES master.Product(ProductId),
      CONSTRAINT FK_inv_ProductLot_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
      CONSTRAINT FK_inv_ProductLot_UpdatedBy FOREIGN KEY (UpdatedByUserId) REFERENCES sec.[User](UserId),
      CONSTRAINT FK_inv_ProductLot_DeletedBy FOREIGN KEY (DeletedByUserId) REFERENCES sec.[User](UserId)
    );

    CREATE INDEX IX_inv_ProductLot_Product
      ON inv.ProductLot (CompanyId, ProductId, Status);

    CREATE INDEX IX_inv_ProductLot_Expiry
      ON inv.ProductLot (CompanyId, ExpiryDate)
      WHERE ExpiryDate IS NOT NULL AND Status = N'ACTIVE';
  END;
  GO

  -- ============================================================
  -- 5. inv.ProductSerial  (Seriales individuales)
  -- ============================================================
  IF OBJECT_ID('inv.ProductSerial', 'U') IS NULL
  BEGIN
    CREATE TABLE inv.ProductSerial(
      SerialId                  BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      CompanyId                 INT NOT NULL,
      ProductId                 BIGINT NOT NULL,
      LotId                     BIGINT NULL,
      SerialNumber              NVARCHAR(100) NOT NULL,
      WarehouseId               BIGINT NULL,
      BinId                     BIGINT NULL,
      Status                    NVARCHAR(20) NOT NULL CONSTRAINT DF_inv_ProductSerial_Status DEFAULT(N'AVAILABLE'),
      PurchaseDocumentNumber    NVARCHAR(60) NULL,
      SalesDocumentNumber       NVARCHAR(60) NULL,
      CustomerId                BIGINT NULL,
      SoldAt                    DATETIME2(0) NULL,
      WarrantyExpiry            DATE NULL,
      Notes                     NVARCHAR(500) NULL,
      IsDeleted                 BIT NOT NULL CONSTRAINT DF_inv_ProductSerial_IsDeleted DEFAULT(0),
      DeletedAt                 DATETIME2(0) NULL,
      DeletedByUserId           INT NULL,
      CreatedAt                 DATETIME2(0) NOT NULL CONSTRAINT DF_inv_ProductSerial_CreatedAt DEFAULT(SYSUTCDATETIME()),
      UpdatedAt                 DATETIME2(0) NOT NULL CONSTRAINT DF_inv_ProductSerial_UpdatedAt DEFAULT(SYSUTCDATETIME()),
      CreatedByUserId           INT NULL,
      UpdatedByUserId           INT NULL,
      RowVer                    ROWVERSION NOT NULL,
      CONSTRAINT CK_inv_ProductSerial_Status CHECK (Status IN (N'AVAILABLE', N'RESERVED', N'SOLD', N'RETURNED', N'DEFECTIVE', N'SCRAPPED')),
      CONSTRAINT UQ_inv_ProductSerial UNIQUE (CompanyId, ProductId, SerialNumber),
      CONSTRAINT FK_inv_ProductSerial_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId),
      CONSTRAINT FK_inv_ProductSerial_Product FOREIGN KEY (ProductId) REFERENCES master.Product(ProductId),
      CONSTRAINT FK_inv_ProductSerial_Lot FOREIGN KEY (LotId) REFERENCES inv.ProductLot(LotId),
      CONSTRAINT FK_inv_ProductSerial_Warehouse FOREIGN KEY (WarehouseId) REFERENCES inv.Warehouse(WarehouseId),
      CONSTRAINT FK_inv_ProductSerial_Bin FOREIGN KEY (BinId) REFERENCES inv.WarehouseBin(BinId),
      CONSTRAINT FK_inv_ProductSerial_Customer FOREIGN KEY (CustomerId) REFERENCES master.Customer(CustomerId),
      CONSTRAINT FK_inv_ProductSerial_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
      CONSTRAINT FK_inv_ProductSerial_UpdatedBy FOREIGN KEY (UpdatedByUserId) REFERENCES sec.[User](UserId),
      CONSTRAINT FK_inv_ProductSerial_DeletedBy FOREIGN KEY (DeletedByUserId) REFERENCES sec.[User](UserId)
    );

    CREATE INDEX IX_inv_ProductSerial_Product
      ON inv.ProductSerial (CompanyId, ProductId, Status);

    CREATE INDEX IX_inv_ProductSerial_Warehouse
      ON inv.ProductSerial (WarehouseId, Status)
      WHERE WarehouseId IS NOT NULL;
  END;
  GO

  -- ============================================================
  -- 6. inv.ProductBinStock  (Stock por ubicacion)
  -- ============================================================
  IF OBJECT_ID('inv.ProductBinStock', 'U') IS NULL
  BEGIN
    CREATE TABLE inv.ProductBinStock(
      ProductBinStockId         BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      CompanyId                 INT NOT NULL,
      ProductId                 BIGINT NOT NULL,
      WarehouseId               BIGINT NOT NULL,
      BinId                     BIGINT NULL,
      LotId                     BIGINT NULL,
      QuantityOnHand            DECIMAL(18,3) NOT NULL CONSTRAINT DF_inv_ProductBinStock_OnHand DEFAULT(0),
      QuantityReserved          DECIMAL(18,3) NOT NULL CONSTRAINT DF_inv_ProductBinStock_Reserved DEFAULT(0),
      QuantityAvailable         AS (QuantityOnHand - QuantityReserved) PERSISTED,
      LastCountDate             DATETIME2(0) NULL,
      IsDeleted                 BIT NOT NULL CONSTRAINT DF_inv_ProductBinStock_IsDeleted DEFAULT(0),
      DeletedAt                 DATETIME2(0) NULL,
      DeletedByUserId           INT NULL,
      CreatedAt                 DATETIME2(0) NOT NULL CONSTRAINT DF_inv_ProductBinStock_CreatedAt DEFAULT(SYSUTCDATETIME()),
      UpdatedAt                 DATETIME2(0) NOT NULL CONSTRAINT DF_inv_ProductBinStock_UpdatedAt DEFAULT(SYSUTCDATETIME()),
      CreatedByUserId           INT NULL,
      UpdatedByUserId           INT NULL,
      RowVer                    ROWVERSION NOT NULL,
      CONSTRAINT FK_inv_ProductBinStock_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId),
      CONSTRAINT FK_inv_ProductBinStock_Product FOREIGN KEY (ProductId) REFERENCES master.Product(ProductId),
      CONSTRAINT FK_inv_ProductBinStock_Warehouse FOREIGN KEY (WarehouseId) REFERENCES inv.Warehouse(WarehouseId),
      CONSTRAINT FK_inv_ProductBinStock_Bin FOREIGN KEY (BinId) REFERENCES inv.WarehouseBin(BinId),
      CONSTRAINT FK_inv_ProductBinStock_Lot FOREIGN KEY (LotId) REFERENCES inv.ProductLot(LotId),
      CONSTRAINT FK_inv_ProductBinStock_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
      CONSTRAINT FK_inv_ProductBinStock_UpdatedBy FOREIGN KEY (UpdatedByUserId) REFERENCES sec.[User](UserId),
      CONSTRAINT FK_inv_ProductBinStock_DeletedBy FOREIGN KEY (DeletedByUserId) REFERENCES sec.[User](UserId)
    );

    CREATE UNIQUE INDEX UX_inv_ProductBinStock_Location
      ON inv.ProductBinStock (CompanyId, ProductId, WarehouseId, ISNULL(BinId, 0), ISNULL(LotId, 0))
      WHERE IsDeleted = 0;

    CREATE INDEX IX_inv_ProductBinStock_Warehouse
      ON inv.ProductBinStock (CompanyId, WarehouseId, ProductId);
  END;
  GO

  -- ============================================================
  -- 7. inv.InventoryValuationMethod  (Metodo de valoracion)
  -- ============================================================
  IF OBJECT_ID('inv.InventoryValuationMethod', 'U') IS NULL
  BEGIN
    CREATE TABLE inv.InventoryValuationMethod(
      ValuationMethodId         BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      CompanyId                 INT NOT NULL,
      ProductId                 BIGINT NOT NULL,
      Method                    NVARCHAR(20) NOT NULL CONSTRAINT DF_inv_ValMethod_Method DEFAULT(N'WEIGHTED_AVG'),
      StandardCost              DECIMAL(18,4) NULL,
      IsDeleted                 BIT NOT NULL CONSTRAINT DF_inv_ValMethod_IsDeleted DEFAULT(0),
      DeletedAt                 DATETIME2(0) NULL,
      DeletedByUserId           INT NULL,
      CreatedAt                 DATETIME2(0) NOT NULL CONSTRAINT DF_inv_ValMethod_CreatedAt DEFAULT(SYSUTCDATETIME()),
      UpdatedAt                 DATETIME2(0) NOT NULL CONSTRAINT DF_inv_ValMethod_UpdatedAt DEFAULT(SYSUTCDATETIME()),
      CreatedByUserId           INT NULL,
      UpdatedByUserId           INT NULL,
      RowVer                    ROWVERSION NOT NULL,
      CONSTRAINT CK_inv_ValMethod_Method CHECK (Method IN (N'FIFO', N'LIFO', N'WEIGHTED_AVG', N'LAST_COST', N'STANDARD')),
      CONSTRAINT UQ_inv_ValMethod_Product UNIQUE (CompanyId, ProductId),
      CONSTRAINT FK_inv_ValMethod_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId),
      CONSTRAINT FK_inv_ValMethod_Product FOREIGN KEY (ProductId) REFERENCES master.Product(ProductId),
      CONSTRAINT FK_inv_ValMethod_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
      CONSTRAINT FK_inv_ValMethod_UpdatedBy FOREIGN KEY (UpdatedByUserId) REFERENCES sec.[User](UserId),
      CONSTRAINT FK_inv_ValMethod_DeletedBy FOREIGN KEY (DeletedByUserId) REFERENCES sec.[User](UserId)
    );
  END;
  GO

  -- ============================================================
  -- 8. inv.InventoryValuationLayer  (Capas de costo FIFO/LIFO)
  -- ============================================================
  IF OBJECT_ID('inv.InventoryValuationLayer', 'U') IS NULL
  BEGIN
    CREATE TABLE inv.InventoryValuationLayer(
      LayerId                   BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      CompanyId                 INT NOT NULL,
      ProductId                 BIGINT NOT NULL,
      LotId                     BIGINT NULL,
      LayerDate                 DATE NOT NULL,
      RemainingQuantity         DECIMAL(18,3) NOT NULL CONSTRAINT DF_inv_ValLayer_RemQty DEFAULT(0),
      UnitCost                  DECIMAL(18,4) NOT NULL CONSTRAINT DF_inv_ValLayer_UnitCost DEFAULT(0),
      SourceDocumentType        NVARCHAR(20) NULL,
      SourceDocumentNumber      NVARCHAR(60) NULL,
      CreatedAt                 DATETIME2(0) NOT NULL CONSTRAINT DF_inv_ValLayer_CreatedAt DEFAULT(SYSUTCDATETIME()),
      CONSTRAINT FK_inv_ValLayer_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId),
      CONSTRAINT FK_inv_ValLayer_Product FOREIGN KEY (ProductId) REFERENCES master.Product(ProductId),
      CONSTRAINT FK_inv_ValLayer_Lot FOREIGN KEY (LotId) REFERENCES inv.ProductLot(LotId)
    );

    CREATE INDEX IX_inv_ValLayer_Product
      ON inv.InventoryValuationLayer (CompanyId, ProductId, LayerDate);

    CREATE INDEX IX_inv_ValLayer_Remaining
      ON inv.InventoryValuationLayer (CompanyId, ProductId, LayerDate)
      WHERE RemainingQuantity > 0;
  END;
  GO

  -- ============================================================
  -- 9. inv.StockMovement  (Movimientos de stock detallados)
  -- ============================================================
  IF OBJECT_ID('inv.StockMovement', 'U') IS NULL
  BEGIN
    CREATE TABLE inv.StockMovement(
      MovementId                BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      CompanyId                 INT NOT NULL,
      BranchId                  INT NOT NULL,
      ProductId                 BIGINT NOT NULL,
      LotId                     BIGINT NULL,
      SerialId                  BIGINT NULL,
      FromWarehouseId           BIGINT NULL,
      ToWarehouseId             BIGINT NULL,
      FromBinId                 BIGINT NULL,
      ToBinId                   BIGINT NULL,
      MovementType              NVARCHAR(20) NOT NULL,
      Quantity                  DECIMAL(18,3) NOT NULL,
      UnitCost                  DECIMAL(18,4) NOT NULL CONSTRAINT DF_inv_StockMovement_UnitCost DEFAULT(0),
      TotalCost                 DECIMAL(18,2) NOT NULL CONSTRAINT DF_inv_StockMovement_TotalCost DEFAULT(0),
      SourceDocumentType        NVARCHAR(20) NULL,
      SourceDocumentNumber      NVARCHAR(60) NULL,
      Notes                     NVARCHAR(500) NULL,
      MovementDate              DATETIME2(0) NOT NULL CONSTRAINT DF_inv_StockMovement_Date DEFAULT(SYSUTCDATETIME()),
      CreatedByUserId           INT NULL,
      CreatedAt                 DATETIME2(0) NOT NULL CONSTRAINT DF_inv_StockMovement_CreatedAt DEFAULT(SYSUTCDATETIME()),
      CONSTRAINT CK_inv_StockMovement_Type CHECK (MovementType IN (
        N'PURCHASE_IN', N'SALE_OUT', N'TRANSFER', N'ADJUSTMENT',
        N'RETURN_IN', N'RETURN_OUT', N'PRODUCTION_IN', N'PRODUCTION_OUT', N'SCRAP'
      )),
      CONSTRAINT FK_inv_StockMovement_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId),
      CONSTRAINT FK_inv_StockMovement_Branch FOREIGN KEY (BranchId) REFERENCES cfg.Branch(BranchId),
      CONSTRAINT FK_inv_StockMovement_Product FOREIGN KEY (ProductId) REFERENCES master.Product(ProductId),
      CONSTRAINT FK_inv_StockMovement_Lot FOREIGN KEY (LotId) REFERENCES inv.ProductLot(LotId),
      CONSTRAINT FK_inv_StockMovement_Serial FOREIGN KEY (SerialId) REFERENCES inv.ProductSerial(SerialId),
      CONSTRAINT FK_inv_StockMovement_FromWH FOREIGN KEY (FromWarehouseId) REFERENCES inv.Warehouse(WarehouseId),
      CONSTRAINT FK_inv_StockMovement_ToWH FOREIGN KEY (ToWarehouseId) REFERENCES inv.Warehouse(WarehouseId),
      CONSTRAINT FK_inv_StockMovement_FromBin FOREIGN KEY (FromBinId) REFERENCES inv.WarehouseBin(BinId),
      CONSTRAINT FK_inv_StockMovement_ToBin FOREIGN KEY (ToBinId) REFERENCES inv.WarehouseBin(BinId),
      CONSTRAINT FK_inv_StockMovement_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId)
    );

    CREATE INDEX IX_inv_StockMovement_Product
      ON inv.StockMovement (CompanyId, ProductId, MovementDate DESC);

    CREATE INDEX IX_inv_StockMovement_Date
      ON inv.StockMovement (CompanyId, BranchId, MovementDate DESC);

    CREATE INDEX IX_inv_StockMovement_Type
      ON inv.StockMovement (CompanyId, MovementType, MovementDate DESC);
  END;
  GO

  COMMIT TRAN;
  PRINT '09_inventory_advanced.sql — OK';
END TRY
BEGIN CATCH
  IF @@TRANCOUNT > 0 ROLLBACK TRAN;
  PRINT '09_inventory_advanced.sql — ERROR: ' + ERROR_MESSAGE();
  THROW;
END CATCH;
GO
