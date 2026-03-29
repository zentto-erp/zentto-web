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

  IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'logistics') EXEC('CREATE SCHEMA logistics');

  -- ============================================================
  -- 1. logistics.Carrier  (Transportistas / empresas de transporte)
  -- ============================================================
  IF OBJECT_ID('logistics.Carrier', 'U') IS NULL
  BEGIN
    CREATE TABLE logistics.Carrier(
      CarrierId                 BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      CompanyId                 INT NOT NULL,
      CarrierCode               NVARCHAR(20) NOT NULL,
      CarrierName               NVARCHAR(200) NOT NULL,
      FiscalId                  NVARCHAR(30) NULL,
      ContactName               NVARCHAR(200) NULL,
      Phone                     NVARCHAR(60) NULL,
      Email                     NVARCHAR(200) NULL,
      AddressLine               NVARCHAR(400) NULL,
      IsActive                  BIT NOT NULL CONSTRAINT DF_logistics_Carrier_IsActive DEFAULT(1),
      IsDeleted                 BIT NOT NULL CONSTRAINT DF_logistics_Carrier_IsDeleted DEFAULT(0),
      DeletedAt                 DATETIME2(0) NULL,
      DeletedByUserId           INT NULL,
      CreatedAt                 DATETIME2(0) NOT NULL CONSTRAINT DF_logistics_Carrier_CreatedAt DEFAULT(SYSUTCDATETIME()),
      UpdatedAt                 DATETIME2(0) NOT NULL CONSTRAINT DF_logistics_Carrier_UpdatedAt DEFAULT(SYSUTCDATETIME()),
      CreatedByUserId           INT NULL,
      UpdatedByUserId           INT NULL,
      RowVer                    ROWVERSION NOT NULL,
      CONSTRAINT UQ_logistics_Carrier_Code UNIQUE (CompanyId, CarrierCode),
      CONSTRAINT FK_logistics_Carrier_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId),
      CONSTRAINT FK_logistics_Carrier_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
      CONSTRAINT FK_logistics_Carrier_UpdatedBy FOREIGN KEY (UpdatedByUserId) REFERENCES sec.[User](UserId),
      CONSTRAINT FK_logistics_Carrier_DeletedBy FOREIGN KEY (DeletedByUserId) REFERENCES sec.[User](UserId)
    );

    CREATE INDEX IX_logistics_Carrier_Company
      ON logistics.Carrier (CompanyId, IsDeleted, IsActive);
  END;
  GO

  -- ============================================================
  -- 2. logistics.Driver  (Conductores)
  -- ============================================================
  IF OBJECT_ID('logistics.Driver', 'U') IS NULL
  BEGIN
    CREATE TABLE logistics.Driver(
      DriverId                  BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      CompanyId                 INT NOT NULL,
      CarrierId                 BIGINT NULL,
      DriverCode                NVARCHAR(20) NOT NULL,
      DriverName                NVARCHAR(200) NOT NULL,
      FiscalId                  NVARCHAR(30) NULL,
      LicenseNumber             NVARCHAR(30) NULL,
      LicenseExpiry             DATE NULL,
      Phone                     NVARCHAR(60) NULL,
      IsActive                  BIT NOT NULL CONSTRAINT DF_logistics_Driver_IsActive DEFAULT(1),
      IsDeleted                 BIT NOT NULL CONSTRAINT DF_logistics_Driver_IsDeleted DEFAULT(0),
      DeletedAt                 DATETIME2(0) NULL,
      DeletedByUserId           INT NULL,
      CreatedAt                 DATETIME2(0) NOT NULL CONSTRAINT DF_logistics_Driver_CreatedAt DEFAULT(SYSUTCDATETIME()),
      UpdatedAt                 DATETIME2(0) NOT NULL CONSTRAINT DF_logistics_Driver_UpdatedAt DEFAULT(SYSUTCDATETIME()),
      CreatedByUserId           INT NULL,
      UpdatedByUserId           INT NULL,
      RowVer                    ROWVERSION NOT NULL,
      CONSTRAINT UQ_logistics_Driver_Code UNIQUE (CompanyId, DriverCode),
      CONSTRAINT FK_logistics_Driver_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId),
      CONSTRAINT FK_logistics_Driver_Carrier FOREIGN KEY (CarrierId) REFERENCES logistics.Carrier(CarrierId),
      CONSTRAINT FK_logistics_Driver_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
      CONSTRAINT FK_logistics_Driver_UpdatedBy FOREIGN KEY (UpdatedByUserId) REFERENCES sec.[User](UserId),
      CONSTRAINT FK_logistics_Driver_DeletedBy FOREIGN KEY (DeletedByUserId) REFERENCES sec.[User](UserId)
    );

    CREATE INDEX IX_logistics_Driver_Company
      ON logistics.Driver (CompanyId, IsDeleted, IsActive);

    CREATE INDEX IX_logistics_Driver_Carrier
      ON logistics.Driver (CarrierId)
      WHERE CarrierId IS NOT NULL;
  END;
  GO

  -- ============================================================
  -- 3. logistics.GoodsReceipt  (Recepcion de mercancia)
  -- ============================================================
  IF OBJECT_ID('logistics.GoodsReceipt', 'U') IS NULL
  BEGIN
    CREATE TABLE logistics.GoodsReceipt(
      GoodsReceiptId            BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      CompanyId                 INT NOT NULL,
      BranchId                  INT NOT NULL,
      ReceiptNumber             NVARCHAR(40) NOT NULL,
      PurchaseDocumentNumber    NVARCHAR(60) NULL,
      SupplierId                BIGINT NULL,
      WarehouseId               BIGINT NOT NULL,
      ReceiptDate               DATETIME2(0) NOT NULL CONSTRAINT DF_logistics_GoodsReceipt_Date DEFAULT(SYSUTCDATETIME()),
      Status                    NVARCHAR(20) NOT NULL CONSTRAINT DF_logistics_GoodsReceipt_Status DEFAULT(N'DRAFT'),
      Notes                     NVARCHAR(500) NULL,
      CarrierId                 BIGINT NULL,
      DriverName                NVARCHAR(200) NULL,
      VehiclePlate              NVARCHAR(20) NULL,
      ReceivedByUserId          INT NULL,
      IsDeleted                 BIT NOT NULL CONSTRAINT DF_logistics_GoodsReceipt_IsDeleted DEFAULT(0),
      DeletedAt                 DATETIME2(0) NULL,
      DeletedByUserId           INT NULL,
      CreatedAt                 DATETIME2(0) NOT NULL CONSTRAINT DF_logistics_GoodsReceipt_CreatedAt DEFAULT(SYSUTCDATETIME()),
      UpdatedAt                 DATETIME2(0) NOT NULL CONSTRAINT DF_logistics_GoodsReceipt_UpdatedAt DEFAULT(SYSUTCDATETIME()),
      CreatedByUserId           INT NULL,
      UpdatedByUserId           INT NULL,
      RowVer                    ROWVERSION NOT NULL,
      CONSTRAINT CK_logistics_GoodsReceipt_Status CHECK (Status IN (N'DRAFT', N'PARTIAL', N'COMPLETE', N'VOIDED')),
      CONSTRAINT UQ_logistics_GoodsReceipt_Number UNIQUE (CompanyId, BranchId, ReceiptNumber),
      CONSTRAINT FK_logistics_GoodsReceipt_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId),
      CONSTRAINT FK_logistics_GoodsReceipt_Branch FOREIGN KEY (BranchId) REFERENCES cfg.Branch(BranchId),
      CONSTRAINT FK_logistics_GoodsReceipt_Supplier FOREIGN KEY (SupplierId) REFERENCES master.Supplier(SupplierId),
      CONSTRAINT FK_logistics_GoodsReceipt_Warehouse FOREIGN KEY (WarehouseId) REFERENCES inv.Warehouse(WarehouseId),
      CONSTRAINT FK_logistics_GoodsReceipt_Carrier FOREIGN KEY (CarrierId) REFERENCES logistics.Carrier(CarrierId),
      CONSTRAINT FK_logistics_GoodsReceipt_ReceivedBy FOREIGN KEY (ReceivedByUserId) REFERENCES sec.[User](UserId),
      CONSTRAINT FK_logistics_GoodsReceipt_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
      CONSTRAINT FK_logistics_GoodsReceipt_UpdatedBy FOREIGN KEY (UpdatedByUserId) REFERENCES sec.[User](UserId),
      CONSTRAINT FK_logistics_GoodsReceipt_DeletedBy FOREIGN KEY (DeletedByUserId) REFERENCES sec.[User](UserId)
    );

    CREATE INDEX IX_logistics_GoodsReceipt_Date
      ON logistics.GoodsReceipt (CompanyId, BranchId, ReceiptDate DESC);

    CREATE INDEX IX_logistics_GoodsReceipt_Status
      ON logistics.GoodsReceipt (CompanyId, Status);
  END;
  GO

  -- ============================================================
  -- 4. logistics.GoodsReceiptLine  (Lineas de recepcion)
  -- ============================================================
  IF OBJECT_ID('logistics.GoodsReceiptLine', 'U') IS NULL
  BEGIN
    CREATE TABLE logistics.GoodsReceiptLine(
      GoodsReceiptLineId        BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      GoodsReceiptId            BIGINT NOT NULL,
      LineNumber                INT NOT NULL,
      ProductId                 BIGINT NOT NULL,
      ProductCode               NVARCHAR(80) NULL,
      Description               NVARCHAR(250) NULL,
      OrderedQuantity           DECIMAL(18,3) NOT NULL CONSTRAINT DF_logistics_GRLine_OrdQty DEFAULT(0),
      ReceivedQuantity          DECIMAL(18,3) NOT NULL CONSTRAINT DF_logistics_GRLine_RecQty DEFAULT(0),
      RejectedQuantity          DECIMAL(18,3) NOT NULL CONSTRAINT DF_logistics_GRLine_RejQty DEFAULT(0),
      UnitCost                  DECIMAL(18,4) NOT NULL CONSTRAINT DF_logistics_GRLine_UnitCost DEFAULT(0),
      TotalCost                 DECIMAL(18,2) NOT NULL CONSTRAINT DF_logistics_GRLine_TotalCost DEFAULT(0),
      LotNumber                 NVARCHAR(60) NULL,
      ExpiryDate                DATE NULL,
      WarehouseId               BIGINT NULL,
      BinId                     BIGINT NULL,
      InspectionStatus          NVARCHAR(20) NOT NULL CONSTRAINT DF_logistics_GRLine_Inspect DEFAULT(N'PENDING'),
      Notes                     NVARCHAR(500) NULL,
      IsDeleted                 BIT NOT NULL CONSTRAINT DF_logistics_GRLine_IsDeleted DEFAULT(0),
      DeletedAt                 DATETIME2(0) NULL,
      DeletedByUserId           INT NULL,
      CreatedAt                 DATETIME2(0) NOT NULL CONSTRAINT DF_logistics_GRLine_CreatedAt DEFAULT(SYSUTCDATETIME()),
      UpdatedAt                 DATETIME2(0) NOT NULL CONSTRAINT DF_logistics_GRLine_UpdatedAt DEFAULT(SYSUTCDATETIME()),
      CreatedByUserId           INT NULL,
      UpdatedByUserId           INT NULL,
      RowVer                    ROWVERSION NOT NULL,
      CONSTRAINT CK_logistics_GRLine_Inspect CHECK (InspectionStatus IN (N'PENDING', N'APPROVED', N'REJECTED')),
      CONSTRAINT UQ_logistics_GRLine_Number UNIQUE (GoodsReceiptId, LineNumber),
      CONSTRAINT FK_logistics_GRLine_Receipt FOREIGN KEY (GoodsReceiptId) REFERENCES logistics.GoodsReceipt(GoodsReceiptId),
      CONSTRAINT FK_logistics_GRLine_Product FOREIGN KEY (ProductId) REFERENCES master.Product(ProductId),
      CONSTRAINT FK_logistics_GRLine_Warehouse FOREIGN KEY (WarehouseId) REFERENCES inv.Warehouse(WarehouseId),
      CONSTRAINT FK_logistics_GRLine_Bin FOREIGN KEY (BinId) REFERENCES inv.WarehouseBin(BinId),
      CONSTRAINT FK_logistics_GRLine_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
      CONSTRAINT FK_logistics_GRLine_UpdatedBy FOREIGN KEY (UpdatedByUserId) REFERENCES sec.[User](UserId),
      CONSTRAINT FK_logistics_GRLine_DeletedBy FOREIGN KEY (DeletedByUserId) REFERENCES sec.[User](UserId)
    );

    CREATE INDEX IX_logistics_GRLine_Receipt
      ON logistics.GoodsReceiptLine (GoodsReceiptId);
  END;
  GO

  -- ============================================================
  -- 5. logistics.GoodsReceiptSerial  (Seriales recibidos por linea)
  -- ============================================================
  IF OBJECT_ID('logistics.GoodsReceiptSerial', 'U') IS NULL
  BEGIN
    CREATE TABLE logistics.GoodsReceiptSerial(
      GoodsReceiptSerialId      BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      GoodsReceiptLineId        BIGINT NOT NULL,
      SerialNumber              NVARCHAR(100) NOT NULL,
      Status                    NVARCHAR(20) NOT NULL CONSTRAINT DF_logistics_GRSerial_Status DEFAULT(N'RECEIVED'),
      Notes                     NVARCHAR(500) NULL,
      CONSTRAINT CK_logistics_GRSerial_Status CHECK (Status IN (N'RECEIVED', N'REJECTED')),
      CONSTRAINT UQ_logistics_GRSerial UNIQUE (GoodsReceiptLineId, SerialNumber),
      CONSTRAINT FK_logistics_GRSerial_Line FOREIGN KEY (GoodsReceiptLineId) REFERENCES logistics.GoodsReceiptLine(GoodsReceiptLineId)
    );
  END;
  GO

  -- ============================================================
  -- 6. logistics.GoodsReturn  (Devolucion a proveedor)
  -- ============================================================
  IF OBJECT_ID('logistics.GoodsReturn', 'U') IS NULL
  BEGIN
    CREATE TABLE logistics.GoodsReturn(
      GoodsReturnId             BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      CompanyId                 INT NOT NULL,
      BranchId                  INT NOT NULL,
      ReturnNumber              NVARCHAR(40) NOT NULL,
      GoodsReceiptId            BIGINT NULL,
      SupplierId                BIGINT NULL,
      WarehouseId               BIGINT NOT NULL,
      ReturnDate                DATETIME2(0) NOT NULL CONSTRAINT DF_logistics_GoodsReturn_Date DEFAULT(SYSUTCDATETIME()),
      Reason                    NVARCHAR(500) NULL,
      Status                    NVARCHAR(20) NOT NULL CONSTRAINT DF_logistics_GoodsReturn_Status DEFAULT(N'DRAFT'),
      Notes                     NVARCHAR(500) NULL,
      IsDeleted                 BIT NOT NULL CONSTRAINT DF_logistics_GoodsReturn_IsDeleted DEFAULT(0),
      DeletedAt                 DATETIME2(0) NULL,
      DeletedByUserId           INT NULL,
      CreatedAt                 DATETIME2(0) NOT NULL CONSTRAINT DF_logistics_GoodsReturn_CreatedAt DEFAULT(SYSUTCDATETIME()),
      UpdatedAt                 DATETIME2(0) NOT NULL CONSTRAINT DF_logistics_GoodsReturn_UpdatedAt DEFAULT(SYSUTCDATETIME()),
      CreatedByUserId           INT NULL,
      UpdatedByUserId           INT NULL,
      RowVer                    ROWVERSION NOT NULL,
      CONSTRAINT CK_logistics_GoodsReturn_Status CHECK (Status IN (N'DRAFT', N'APPROVED', N'SHIPPED', N'VOIDED')),
      CONSTRAINT UQ_logistics_GoodsReturn_Number UNIQUE (CompanyId, BranchId, ReturnNumber),
      CONSTRAINT FK_logistics_GoodsReturn_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId),
      CONSTRAINT FK_logistics_GoodsReturn_Branch FOREIGN KEY (BranchId) REFERENCES cfg.Branch(BranchId),
      CONSTRAINT FK_logistics_GoodsReturn_Receipt FOREIGN KEY (GoodsReceiptId) REFERENCES logistics.GoodsReceipt(GoodsReceiptId),
      CONSTRAINT FK_logistics_GoodsReturn_Supplier FOREIGN KEY (SupplierId) REFERENCES master.Supplier(SupplierId),
      CONSTRAINT FK_logistics_GoodsReturn_Warehouse FOREIGN KEY (WarehouseId) REFERENCES inv.Warehouse(WarehouseId),
      CONSTRAINT FK_logistics_GoodsReturn_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
      CONSTRAINT FK_logistics_GoodsReturn_UpdatedBy FOREIGN KEY (UpdatedByUserId) REFERENCES sec.[User](UserId),
      CONSTRAINT FK_logistics_GoodsReturn_DeletedBy FOREIGN KEY (DeletedByUserId) REFERENCES sec.[User](UserId)
    );

    CREATE INDEX IX_logistics_GoodsReturn_Date
      ON logistics.GoodsReturn (CompanyId, BranchId, ReturnDate DESC);
  END;
  GO

  -- ============================================================
  -- 7. logistics.GoodsReturnLine  (Lineas de devolucion)
  -- ============================================================
  IF OBJECT_ID('logistics.GoodsReturnLine', 'U') IS NULL
  BEGIN
    CREATE TABLE logistics.GoodsReturnLine(
      GoodsReturnLineId         BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      GoodsReturnId             BIGINT NOT NULL,
      LineNumber                INT NOT NULL,
      ProductId                 BIGINT NOT NULL,
      ProductCode               NVARCHAR(80) NULL,
      Quantity                  DECIMAL(18,3) NOT NULL CONSTRAINT DF_logistics_GRtnLine_Qty DEFAULT(0),
      UnitCost                  DECIMAL(18,4) NOT NULL CONSTRAINT DF_logistics_GRtnLine_UnitCost DEFAULT(0),
      LotNumber                 NVARCHAR(60) NULL,
      SerialNumber              NVARCHAR(100) NULL,
      Reason                    NVARCHAR(500) NULL,
      IsDeleted                 BIT NOT NULL CONSTRAINT DF_logistics_GRtnLine_IsDeleted DEFAULT(0),
      DeletedAt                 DATETIME2(0) NULL,
      DeletedByUserId           INT NULL,
      CreatedAt                 DATETIME2(0) NOT NULL CONSTRAINT DF_logistics_GRtnLine_CreatedAt DEFAULT(SYSUTCDATETIME()),
      UpdatedAt                 DATETIME2(0) NOT NULL CONSTRAINT DF_logistics_GRtnLine_UpdatedAt DEFAULT(SYSUTCDATETIME()),
      CreatedByUserId           INT NULL,
      UpdatedByUserId           INT NULL,
      RowVer                    ROWVERSION NOT NULL,
      CONSTRAINT UQ_logistics_GRtnLine_Number UNIQUE (GoodsReturnId, LineNumber),
      CONSTRAINT FK_logistics_GRtnLine_Return FOREIGN KEY (GoodsReturnId) REFERENCES logistics.GoodsReturn(GoodsReturnId),
      CONSTRAINT FK_logistics_GRtnLine_Product FOREIGN KEY (ProductId) REFERENCES master.Product(ProductId),
      CONSTRAINT FK_logistics_GRtnLine_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
      CONSTRAINT FK_logistics_GRtnLine_UpdatedBy FOREIGN KEY (UpdatedByUserId) REFERENCES sec.[User](UserId),
      CONSTRAINT FK_logistics_GRtnLine_DeletedBy FOREIGN KEY (DeletedByUserId) REFERENCES sec.[User](UserId)
    );

    CREATE INDEX IX_logistics_GRtnLine_Return
      ON logistics.GoodsReturnLine (GoodsReturnId);
  END;
  GO

  -- ============================================================
  -- 8. logistics.DeliveryNote  (Nota de entrega / Albaran / Guia de despacho)
  -- ============================================================
  IF OBJECT_ID('logistics.DeliveryNote', 'U') IS NULL
  BEGIN
    CREATE TABLE logistics.DeliveryNote(
      DeliveryNoteId            BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      CompanyId                 INT NOT NULL,
      BranchId                  INT NOT NULL,
      DeliveryNumber            NVARCHAR(40) NOT NULL,
      SalesDocumentNumber       NVARCHAR(60) NULL,
      CustomerId                BIGINT NULL,
      WarehouseId               BIGINT NOT NULL,
      DeliveryDate              DATETIME2(0) NOT NULL CONSTRAINT DF_logistics_DeliveryNote_Date DEFAULT(SYSUTCDATETIME()),
      Status                    NVARCHAR(20) NOT NULL CONSTRAINT DF_logistics_DeliveryNote_Status DEFAULT(N'DRAFT'),
      CarrierId                 BIGINT NULL,
      DriverId                  BIGINT NULL,
      VehiclePlate              NVARCHAR(20) NULL,
      ShipToAddress             NVARCHAR(500) NULL,
      ShipToContact             NVARCHAR(200) NULL,
      EstimatedDelivery         DATE NULL,
      ActualDelivery            DATETIME2(0) NULL,
      DeliveredToName           NVARCHAR(200) NULL,
      DeliverySignature         NVARCHAR(MAX) NULL,
      Notes                     NVARCHAR(500) NULL,
      DispatchedByUserId        INT NULL,
      IsDeleted                 BIT NOT NULL CONSTRAINT DF_logistics_DeliveryNote_IsDeleted DEFAULT(0),
      DeletedAt                 DATETIME2(0) NULL,
      DeletedByUserId           INT NULL,
      CreatedAt                 DATETIME2(0) NOT NULL CONSTRAINT DF_logistics_DeliveryNote_CreatedAt DEFAULT(SYSUTCDATETIME()),
      UpdatedAt                 DATETIME2(0) NOT NULL CONSTRAINT DF_logistics_DeliveryNote_UpdatedAt DEFAULT(SYSUTCDATETIME()),
      CreatedByUserId           INT NULL,
      UpdatedByUserId           INT NULL,
      RowVer                    ROWVERSION NOT NULL,
      CONSTRAINT CK_logistics_DeliveryNote_Status CHECK (Status IN (
        N'DRAFT', N'PICKING', N'PACKED', N'DISPATCHED', N'IN_TRANSIT', N'DELIVERED', N'VOIDED'
      )),
      CONSTRAINT UQ_logistics_DeliveryNote_Number UNIQUE (CompanyId, BranchId, DeliveryNumber),
      CONSTRAINT FK_logistics_DeliveryNote_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId),
      CONSTRAINT FK_logistics_DeliveryNote_Branch FOREIGN KEY (BranchId) REFERENCES cfg.Branch(BranchId),
      CONSTRAINT FK_logistics_DeliveryNote_Customer FOREIGN KEY (CustomerId) REFERENCES master.Customer(CustomerId),
      CONSTRAINT FK_logistics_DeliveryNote_Warehouse FOREIGN KEY (WarehouseId) REFERENCES inv.Warehouse(WarehouseId),
      CONSTRAINT FK_logistics_DeliveryNote_Carrier FOREIGN KEY (CarrierId) REFERENCES logistics.Carrier(CarrierId),
      CONSTRAINT FK_logistics_DeliveryNote_Driver FOREIGN KEY (DriverId) REFERENCES logistics.Driver(DriverId),
      CONSTRAINT FK_logistics_DeliveryNote_DispatchedBy FOREIGN KEY (DispatchedByUserId) REFERENCES sec.[User](UserId),
      CONSTRAINT FK_logistics_DeliveryNote_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
      CONSTRAINT FK_logistics_DeliveryNote_UpdatedBy FOREIGN KEY (UpdatedByUserId) REFERENCES sec.[User](UserId),
      CONSTRAINT FK_logistics_DeliveryNote_DeletedBy FOREIGN KEY (DeletedByUserId) REFERENCES sec.[User](UserId)
    );

    CREATE INDEX IX_logistics_DeliveryNote_Date
      ON logistics.DeliveryNote (CompanyId, BranchId, DeliveryDate DESC);

    CREATE INDEX IX_logistics_DeliveryNote_Status
      ON logistics.DeliveryNote (CompanyId, Status);

    CREATE INDEX IX_logistics_DeliveryNote_Customer
      ON logistics.DeliveryNote (CompanyId, CustomerId)
      WHERE CustomerId IS NOT NULL;
  END;
  GO

  -- ============================================================
  -- 9. logistics.DeliveryNoteLine  (Lineas de nota de entrega)
  -- ============================================================
  IF OBJECT_ID('logistics.DeliveryNoteLine', 'U') IS NULL
  BEGIN
    CREATE TABLE logistics.DeliveryNoteLine(
      DeliveryNoteLineId        BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      DeliveryNoteId            BIGINT NOT NULL,
      LineNumber                INT NOT NULL,
      ProductId                 BIGINT NOT NULL,
      ProductCode               NVARCHAR(80) NULL,
      Description               NVARCHAR(250) NULL,
      Quantity                  DECIMAL(18,3) NOT NULL CONSTRAINT DF_logistics_DNLine_Qty DEFAULT(0),
      LotNumber                 NVARCHAR(60) NULL,
      WarehouseId               BIGINT NULL,
      BinId                     BIGINT NULL,
      PickedQuantity            DECIMAL(18,3) NOT NULL CONSTRAINT DF_logistics_DNLine_Picked DEFAULT(0),
      PackedQuantity            DECIMAL(18,3) NOT NULL CONSTRAINT DF_logistics_DNLine_Packed DEFAULT(0),
      Notes                     NVARCHAR(500) NULL,
      IsDeleted                 BIT NOT NULL CONSTRAINT DF_logistics_DNLine_IsDeleted DEFAULT(0),
      DeletedAt                 DATETIME2(0) NULL,
      DeletedByUserId           INT NULL,
      CreatedAt                 DATETIME2(0) NOT NULL CONSTRAINT DF_logistics_DNLine_CreatedAt DEFAULT(SYSUTCDATETIME()),
      UpdatedAt                 DATETIME2(0) NOT NULL CONSTRAINT DF_logistics_DNLine_UpdatedAt DEFAULT(SYSUTCDATETIME()),
      CreatedByUserId           INT NULL,
      UpdatedByUserId           INT NULL,
      RowVer                    ROWVERSION NOT NULL,
      CONSTRAINT UQ_logistics_DNLine_Number UNIQUE (DeliveryNoteId, LineNumber),
      CONSTRAINT FK_logistics_DNLine_Note FOREIGN KEY (DeliveryNoteId) REFERENCES logistics.DeliveryNote(DeliveryNoteId),
      CONSTRAINT FK_logistics_DNLine_Product FOREIGN KEY (ProductId) REFERENCES master.Product(ProductId),
      CONSTRAINT FK_logistics_DNLine_Warehouse FOREIGN KEY (WarehouseId) REFERENCES inv.Warehouse(WarehouseId),
      CONSTRAINT FK_logistics_DNLine_Bin FOREIGN KEY (BinId) REFERENCES inv.WarehouseBin(BinId),
      CONSTRAINT FK_logistics_DNLine_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
      CONSTRAINT FK_logistics_DNLine_UpdatedBy FOREIGN KEY (UpdatedByUserId) REFERENCES sec.[User](UserId),
      CONSTRAINT FK_logistics_DNLine_DeletedBy FOREIGN KEY (DeletedByUserId) REFERENCES sec.[User](UserId)
    );

    CREATE INDEX IX_logistics_DNLine_Note
      ON logistics.DeliveryNoteLine (DeliveryNoteId);
  END;
  GO

  -- ============================================================
  -- 10. logistics.DeliveryNoteSerial  (Seriales despachados)
  -- ============================================================
  IF OBJECT_ID('logistics.DeliveryNoteSerial', 'U') IS NULL
  BEGIN
    CREATE TABLE logistics.DeliveryNoteSerial(
      DeliveryNoteSerialId      BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      DeliveryNoteLineId        BIGINT NOT NULL,
      SerialId                  BIGINT NOT NULL,
      SerialNumber              NVARCHAR(100) NOT NULL,
      Status                    NVARCHAR(20) NOT NULL CONSTRAINT DF_logistics_DNSerial_Status DEFAULT(N'DISPATCHED'),
      CONSTRAINT CK_logistics_DNSerial_Status CHECK (Status IN (N'DISPATCHED', N'DELIVERED', N'RETURNED')),
      CONSTRAINT UQ_logistics_DNSerial UNIQUE (DeliveryNoteLineId, SerialId),
      CONSTRAINT FK_logistics_DNSerial_Line FOREIGN KEY (DeliveryNoteLineId) REFERENCES logistics.DeliveryNoteLine(DeliveryNoteLineId),
      CONSTRAINT FK_logistics_DNSerial_Serial FOREIGN KEY (SerialId) REFERENCES inv.ProductSerial(SerialId)
    );
  END;
  GO

  COMMIT TRAN;
  PRINT '10_logistics.sql — OK';
END TRY
BEGIN CATCH
  IF @@TRANCOUNT > 0 ROLLBACK TRAN;
  PRINT '10_logistics.sql — ERROR: ' + ERROR_MESSAGE();
  THROW;
END CATCH;
GO
