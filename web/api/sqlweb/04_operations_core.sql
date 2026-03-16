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

  IF OBJECT_ID('ar.ReceivableDocument', 'U') IS NULL
  BEGIN
    CREATE TABLE ar.ReceivableDocument(
      ReceivableDocumentId     BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      CompanyId                INT NOT NULL,
      BranchId                 INT NOT NULL,
      CustomerId               BIGINT NOT NULL,
      DocumentType             NVARCHAR(20) NOT NULL,
      DocumentNumber           NVARCHAR(120) NOT NULL,
      IssueDate                DATE NOT NULL,
      DueDate                  DATE NULL,
      CurrencyCode             CHAR(3) NOT NULL,
      TotalAmount              DECIMAL(18,2) NOT NULL,
      PendingAmount            DECIMAL(18,2) NOT NULL,
      PaidFlag                 BIT NOT NULL CONSTRAINT DF_ar_RecDoc_PaidFlag DEFAULT(0),
      Status                   NVARCHAR(20) NOT NULL CONSTRAINT DF_ar_RecDoc_Status DEFAULT('PENDING'),
      Notes                    NVARCHAR(500) NULL,
      CreatedAt                DATETIME2(0) NOT NULL CONSTRAINT DF_ar_RecDoc_CreatedAt DEFAULT(SYSUTCDATETIME()),
      UpdatedAt                DATETIME2(0) NOT NULL CONSTRAINT DF_ar_RecDoc_UpdatedAt DEFAULT(SYSUTCDATETIME()),
      CreatedByUserId          INT NULL,
      UpdatedByUserId          INT NULL,
      RowVer                   ROWVERSION NOT NULL,
      CONSTRAINT CK_ar_RecDoc_Status CHECK (Status IN ('PENDING','PARTIAL','PAID','VOIDED')),
      CONSTRAINT UQ_ar_RecDoc UNIQUE (CompanyId, BranchId, DocumentType, DocumentNumber),
      CONSTRAINT FK_ar_RecDoc_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId),
      CONSTRAINT FK_ar_RecDoc_Branch FOREIGN KEY (BranchId) REFERENCES cfg.Branch(BranchId),
      CONSTRAINT FK_ar_RecDoc_Customer FOREIGN KEY (CustomerId) REFERENCES [master].Customer(CustomerId),
      CONSTRAINT FK_ar_RecDoc_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
      CONSTRAINT FK_ar_RecDoc_UpdatedBy FOREIGN KEY (UpdatedByUserId) REFERENCES sec.[User](UserId)
    );
  END;

  IF OBJECT_ID('ar.ReceivableApplication', 'U') IS NULL
  BEGIN
    CREATE TABLE ar.ReceivableApplication(
      ReceivableApplicationId   BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      ReceivableDocumentId      BIGINT NOT NULL,
      ApplyDate                 DATE NOT NULL,
      AppliedAmount             DECIMAL(18,2) NOT NULL,
      PaymentReference          NVARCHAR(120) NULL,
      CreatedAt                 DATETIME2(0) NOT NULL CONSTRAINT DF_ar_RecApp_CreatedAt DEFAULT(SYSUTCDATETIME()),
      CONSTRAINT FK_ar_RecApp_Doc FOREIGN KEY (ReceivableDocumentId) REFERENCES ar.ReceivableDocument(ReceivableDocumentId)
    );
  END;

  IF OBJECT_ID('ap.PayableDocument', 'U') IS NULL
  BEGIN
    CREATE TABLE ap.PayableDocument(
      PayableDocumentId        BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      CompanyId                INT NOT NULL,
      BranchId                 INT NOT NULL,
      SupplierId               BIGINT NOT NULL,
      DocumentType             NVARCHAR(20) NOT NULL,
      DocumentNumber           NVARCHAR(120) NOT NULL,
      IssueDate                DATE NOT NULL,
      DueDate                  DATE NULL,
      CurrencyCode             CHAR(3) NOT NULL,
      TotalAmount              DECIMAL(18,2) NOT NULL,
      PendingAmount            DECIMAL(18,2) NOT NULL,
      PaidFlag                 BIT NOT NULL CONSTRAINT DF_ap_PayDoc_PaidFlag DEFAULT(0),
      Status                   NVARCHAR(20) NOT NULL CONSTRAINT DF_ap_PayDoc_Status DEFAULT('PENDING'),
      Notes                    NVARCHAR(500) NULL,
      CreatedAt                DATETIME2(0) NOT NULL CONSTRAINT DF_ap_PayDoc_CreatedAt DEFAULT(SYSUTCDATETIME()),
      UpdatedAt                DATETIME2(0) NOT NULL CONSTRAINT DF_ap_PayDoc_UpdatedAt DEFAULT(SYSUTCDATETIME()),
      CreatedByUserId          INT NULL,
      UpdatedByUserId          INT NULL,
      RowVer                   ROWVERSION NOT NULL,
      CONSTRAINT CK_ap_PayDoc_Status CHECK (Status IN ('PENDING','PARTIAL','PAID','VOIDED')),
      CONSTRAINT UQ_ap_PayDoc UNIQUE (CompanyId, BranchId, DocumentType, DocumentNumber),
      CONSTRAINT FK_ap_PayDoc_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId),
      CONSTRAINT FK_ap_PayDoc_Branch FOREIGN KEY (BranchId) REFERENCES cfg.Branch(BranchId),
      CONSTRAINT FK_ap_PayDoc_Supplier FOREIGN KEY (SupplierId) REFERENCES [master].Supplier(SupplierId),
      CONSTRAINT FK_ap_PayDoc_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
      CONSTRAINT FK_ap_PayDoc_UpdatedBy FOREIGN KEY (UpdatedByUserId) REFERENCES sec.[User](UserId)
    );
  END;

  IF OBJECT_ID('ap.PayableApplication', 'U') IS NULL
  BEGIN
    CREATE TABLE ap.PayableApplication(
      PayableApplicationId      BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      PayableDocumentId         BIGINT NOT NULL,
      ApplyDate                 DATE NOT NULL,
      AppliedAmount             DECIMAL(18,2) NOT NULL,
      PaymentReference          NVARCHAR(120) NULL,
      CreatedAt                 DATETIME2(0) NOT NULL CONSTRAINT DF_ap_PayApp_CreatedAt DEFAULT(SYSUTCDATETIME()),
      CONSTRAINT FK_ap_PayApp_Doc FOREIGN KEY (PayableDocumentId) REFERENCES ap.PayableDocument(PayableDocumentId)
    );
  END;

  IF OBJECT_ID('fiscal.CountryConfig', 'U') IS NULL
  BEGIN
    CREATE TABLE fiscal.CountryConfig(
      CountryConfigId           BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      CompanyId                 INT NOT NULL,
      BranchId                  INT NOT NULL,
      CountryCode               CHAR(2) NOT NULL,
      Currency                  CHAR(3) NOT NULL,
      TaxRegime                 NVARCHAR(50) NULL,
      DefaultTaxCode            NVARCHAR(30) NULL,
      DefaultTaxRate            DECIMAL(9,4) NOT NULL,
      FiscalPrinterEnabled      BIT NOT NULL CONSTRAINT DF_fiscal_CountryCfg_Printer DEFAULT(0),
      PrinterBrand              NVARCHAR(30) NULL,
      PrinterPort               NVARCHAR(20) NULL,
      VerifactuEnabled          BIT NOT NULL CONSTRAINT DF_fiscal_CountryCfg_Verifactu DEFAULT(0),
      VerifactuMode             NVARCHAR(10) NULL,
      CertificatePath           NVARCHAR(500) NULL,
      CertificatePassword       NVARCHAR(255) NULL,
      AEATEndpoint              NVARCHAR(500) NULL,
      SenderNIF                 NVARCHAR(20) NULL,
      SenderRIF                 NVARCHAR(20) NULL,
      SoftwareId                NVARCHAR(100) NULL,
      SoftwareName              NVARCHAR(200) NULL,
      SoftwareVersion           NVARCHAR(20) NULL,
      PosEnabled                BIT NOT NULL CONSTRAINT DF_fiscal_CountryCfg_PosEnabled DEFAULT(1),
      RestaurantEnabled         BIT NOT NULL CONSTRAINT DF_fiscal_CountryCfg_RestEnabled DEFAULT(1),
      IsActive                  BIT NOT NULL CONSTRAINT DF_fiscal_CountryCfg_IsActive DEFAULT(1),
      CreatedAt                 DATETIME2(0) NOT NULL CONSTRAINT DF_fiscal_CountryCfg_CreatedAt DEFAULT(SYSUTCDATETIME()),
      UpdatedAt                 DATETIME2(0) NOT NULL CONSTRAINT DF_fiscal_CountryCfg_UpdatedAt DEFAULT(SYSUTCDATETIME()),
      CreatedByUserId           INT NULL,
      UpdatedByUserId           INT NULL,
      RowVer                    ROWVERSION NOT NULL,
      CONSTRAINT CK_fiscal_CountryCfg_VerifactuMode CHECK (VerifactuMode IN ('auto','manual') OR VerifactuMode IS NULL),
      CONSTRAINT UQ_fiscal_CountryCfg UNIQUE (CompanyId, BranchId, CountryCode),
      CONSTRAINT FK_fiscal_CountryCfg_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId),
      CONSTRAINT FK_fiscal_CountryCfg_Branch FOREIGN KEY (BranchId) REFERENCES cfg.Branch(BranchId),
      CONSTRAINT FK_fiscal_CountryCfg_Country FOREIGN KEY (CountryCode) REFERENCES cfg.Country(CountryCode),
      CONSTRAINT FK_fiscal_CountryCfg_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
      CONSTRAINT FK_fiscal_CountryCfg_UpdatedBy FOREIGN KEY (UpdatedByUserId) REFERENCES sec.[User](UserId)
    );
  END;

  IF OBJECT_ID('fiscal.TaxRate', 'U') IS NULL
  BEGIN
    CREATE TABLE fiscal.TaxRate(
      TaxRateId                 BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      CountryCode               CHAR(2) NOT NULL,
      TaxCode                   NVARCHAR(30) NOT NULL,
      TaxName                   NVARCHAR(120) NOT NULL,
      Rate                      DECIMAL(9,4) NOT NULL,
      SurchargeRate             DECIMAL(9,4) NULL,
      AppliesToPOS              BIT NOT NULL CONSTRAINT DF_fiscal_TaxRate_AppliesToPOS DEFAULT(1),
      AppliesToRestaurant       BIT NOT NULL CONSTRAINT DF_fiscal_TaxRate_AppliesToRest DEFAULT(1),
      IsDefault                 BIT NOT NULL CONSTRAINT DF_fiscal_TaxRate_IsDefault DEFAULT(0),
      IsActive                  BIT NOT NULL CONSTRAINT DF_fiscal_TaxRate_IsActive DEFAULT(1),
      SortOrder                 INT NOT NULL CONSTRAINT DF_fiscal_TaxRate_Sort DEFAULT(0),
      CreatedAt                 DATETIME2(0) NOT NULL CONSTRAINT DF_fiscal_TaxRate_CreatedAt DEFAULT(SYSUTCDATETIME()),
      UpdatedAt                 DATETIME2(0) NOT NULL CONSTRAINT DF_fiscal_TaxRate_UpdatedAt DEFAULT(SYSUTCDATETIME()),
      CreatedByUserId           INT NULL,
      UpdatedByUserId           INT NULL,
      RowVer                    ROWVERSION NOT NULL,
      CONSTRAINT CK_fiscal_TaxRate_Rate CHECK (Rate >= 0 AND Rate <= 1),
      CONSTRAINT CK_fiscal_TaxRate_Surcharge CHECK (SurchargeRate IS NULL OR (SurchargeRate >= 0 AND SurchargeRate <= 1)),
      CONSTRAINT UQ_fiscal_TaxRate UNIQUE (CountryCode, TaxCode),
      CONSTRAINT FK_fiscal_TaxRate_Country FOREIGN KEY (CountryCode) REFERENCES cfg.Country(CountryCode),
      CONSTRAINT FK_fiscal_TaxRate_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
      CONSTRAINT FK_fiscal_TaxRate_UpdatedBy FOREIGN KEY (UpdatedByUserId) REFERENCES sec.[User](UserId)
    );
  END;

  IF OBJECT_ID('fiscal.InvoiceType', 'U') IS NULL
  BEGIN
    CREATE TABLE fiscal.InvoiceType(
      InvoiceTypeId             BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      CountryCode               CHAR(2) NOT NULL,
      InvoiceTypeCode           NVARCHAR(20) NOT NULL,
      InvoiceTypeName           NVARCHAR(120) NOT NULL,
      IsRectificative           BIT NOT NULL CONSTRAINT DF_fiscal_InvType_Rect DEFAULT(0),
      RequiresRecipientId       BIT NOT NULL CONSTRAINT DF_fiscal_InvType_ReqRcpt DEFAULT(0),
      MaxAmount                 DECIMAL(18,2) NULL,
      RequiresFiscalPrinter     BIT NOT NULL CONSTRAINT DF_fiscal_InvType_ReqPrinter DEFAULT(0),
      IsActive                  BIT NOT NULL CONSTRAINT DF_fiscal_InvType_IsActive DEFAULT(1),
      SortOrder                 INT NOT NULL CONSTRAINT DF_fiscal_InvType_Sort DEFAULT(0),
      CreatedAt                 DATETIME2(0) NOT NULL CONSTRAINT DF_fiscal_InvType_CreatedAt DEFAULT(SYSUTCDATETIME()),
      UpdatedAt                 DATETIME2(0) NOT NULL CONSTRAINT DF_fiscal_InvType_UpdatedAt DEFAULT(SYSUTCDATETIME()),
      CreatedByUserId           INT NULL,
      UpdatedByUserId           INT NULL,
      RowVer                    ROWVERSION NOT NULL,
      CONSTRAINT UQ_fiscal_InvType UNIQUE (CountryCode, InvoiceTypeCode),
      CONSTRAINT FK_fiscal_InvType_Country FOREIGN KEY (CountryCode) REFERENCES cfg.Country(CountryCode),
      CONSTRAINT FK_fiscal_InvType_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
      CONSTRAINT FK_fiscal_InvType_UpdatedBy FOREIGN KEY (UpdatedByUserId) REFERENCES sec.[User](UserId)
    );
  END;

  IF OBJECT_ID('fiscal.Record', 'U') IS NULL
  BEGIN
    CREATE TABLE fiscal.Record(
      FiscalRecordId            BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      CompanyId                 INT NOT NULL,
      BranchId                  INT NOT NULL,
      CountryCode               CHAR(2) NOT NULL,
      InvoiceId                 INT NOT NULL,
      InvoiceType               NVARCHAR(20) NOT NULL,
      InvoiceNumber             NVARCHAR(50) NOT NULL,
      InvoiceDate               DATE NOT NULL,
      RecipientId               NVARCHAR(20) NULL,
      TotalAmount               DECIMAL(18,2) NOT NULL,
      RecordHash                VARCHAR(64) NOT NULL,
      PreviousRecordHash        VARCHAR(64) NULL,
      XmlContent                NVARCHAR(MAX) NULL,
      DigitalSignature          NVARCHAR(MAX) NULL,
      QRCodeData                NVARCHAR(800) NULL,
      SentToAuthority           BIT NOT NULL CONSTRAINT DF_fiscal_Record_Sent DEFAULT(0),
      SentAt                    DATETIME2(0) NULL,
      AuthorityResponse         NVARCHAR(MAX) NULL,
      AuthorityStatus           NVARCHAR(20) NULL,
      FiscalPrinterSerial       NVARCHAR(30) NULL,
      FiscalControlNumber       NVARCHAR(30) NULL,
      ZReportNumber             INT NULL,
      CreatedAt                 DATETIME2(0) NOT NULL CONSTRAINT DF_fiscal_Record_CreatedAt DEFAULT(SYSUTCDATETIME()),
      CONSTRAINT UQ_fiscal_Record_Hash UNIQUE (RecordHash),
      CONSTRAINT FK_fiscal_Record_CountryCfg FOREIGN KEY (CompanyId, BranchId, CountryCode) REFERENCES fiscal.CountryConfig(CompanyId, BranchId, CountryCode),
      CONSTRAINT FK_fiscal_Record_PrevHash FOREIGN KEY (PreviousRecordHash) REFERENCES fiscal.Record(RecordHash)
    );

    CREATE INDEX IX_fiscal_Record_Search
      ON fiscal.Record (CompanyId, BranchId, CountryCode, FiscalRecordId DESC);
  END;

  IF OBJECT_ID('pos.WaitTicket', 'U') IS NULL
  BEGIN
    CREATE TABLE pos.WaitTicket(
      WaitTicketId              BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      CompanyId                 INT NOT NULL,
      BranchId                  INT NOT NULL,
      CountryCode               CHAR(2) NOT NULL,
      CashRegisterCode          NVARCHAR(10) NOT NULL,
      StationName               NVARCHAR(50) NULL,
      CreatedByUserId           INT NULL,
      CustomerId                BIGINT NULL,
      CustomerCode              NVARCHAR(24) NULL,
      CustomerName              NVARCHAR(200) NULL,
      CustomerFiscalId          NVARCHAR(30) NULL,
      PriceTier                 NVARCHAR(20) NOT NULL CONSTRAINT DF_pos_WaitTicket_PriceTier DEFAULT('DETAIL'),
      Reason                    NVARCHAR(200) NULL,
      NetAmount                 DECIMAL(18,2) NOT NULL CONSTRAINT DF_pos_WaitTicket_Net DEFAULT(0),
      DiscountAmount            DECIMAL(18,2) NOT NULL CONSTRAINT DF_pos_WaitTicket_Discount DEFAULT(0),
      TaxAmount                 DECIMAL(18,2) NOT NULL CONSTRAINT DF_pos_WaitTicket_Tax DEFAULT(0),
      TotalAmount               DECIMAL(18,2) NOT NULL CONSTRAINT DF_pos_WaitTicket_Total DEFAULT(0),
      Status                    NVARCHAR(20) NOT NULL CONSTRAINT DF_pos_WaitTicket_Status DEFAULT('WAITING'),
      RecoveredByUserId         INT NULL,
      RecoveredAtRegister       NVARCHAR(10) NULL,
      RecoveredAt               DATETIME2(0) NULL,
      CreatedAt                 DATETIME2(0) NOT NULL CONSTRAINT DF_pos_WaitTicket_CreatedAt DEFAULT(SYSUTCDATETIME()),
      UpdatedAt                 DATETIME2(0) NOT NULL CONSTRAINT DF_pos_WaitTicket_UpdatedAt DEFAULT(SYSUTCDATETIME()),
      RowVer                    ROWVERSION NOT NULL,
      CONSTRAINT CK_pos_WaitTicket_Status CHECK (Status IN ('WAITING','RECOVERED','VOIDED')),
      CONSTRAINT FK_pos_WaitTicket_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId),
      CONSTRAINT FK_pos_WaitTicket_Branch FOREIGN KEY (BranchId) REFERENCES cfg.Branch(BranchId),
      CONSTRAINT FK_pos_WaitTicket_Country FOREIGN KEY (CountryCode) REFERENCES cfg.Country(CountryCode),
      CONSTRAINT FK_pos_WaitTicket_Customer FOREIGN KEY (CustomerId) REFERENCES [master].Customer(CustomerId),
      CONSTRAINT FK_pos_WaitTicket_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
      CONSTRAINT FK_pos_WaitTicket_RecoveredBy FOREIGN KEY (RecoveredByUserId) REFERENCES sec.[User](UserId)
    );
  END;

  IF OBJECT_ID('pos.WaitTicketLine', 'U') IS NULL
  BEGIN
    CREATE TABLE pos.WaitTicketLine(
      WaitTicketLineId          BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      WaitTicketId              BIGINT NOT NULL,
      LineNumber                INT NOT NULL,
      CountryCode               CHAR(2) NOT NULL,
      ProductId                 BIGINT NULL,
      ProductCode               NVARCHAR(80) NOT NULL,
      ProductName               NVARCHAR(250) NOT NULL,
      Quantity                  DECIMAL(10,3) NOT NULL,
      UnitPrice                 DECIMAL(18,2) NOT NULL,
      DiscountAmount            DECIMAL(18,2) NOT NULL CONSTRAINT DF_pos_WaitTicketLine_Discount DEFAULT(0),
      TaxCode                   NVARCHAR(30) NOT NULL,
      TaxRate                   DECIMAL(9,4) NOT NULL,
      NetAmount                 DECIMAL(18,2) NOT NULL,
      TaxAmount                 DECIMAL(18,2) NOT NULL,
      TotalAmount               DECIMAL(18,2) NOT NULL,
      CreatedAt                 DATETIME2(0) NOT NULL CONSTRAINT DF_pos_WaitTicketLine_CreatedAt DEFAULT(SYSUTCDATETIME()),
      CONSTRAINT UQ_pos_WaitTicketLine UNIQUE (WaitTicketId, LineNumber),
      CONSTRAINT FK_pos_WaitTicketLine_WaitTicket FOREIGN KEY (WaitTicketId) REFERENCES pos.WaitTicket(WaitTicketId) ON DELETE CASCADE,
      CONSTRAINT FK_pos_WaitTicketLine_Product FOREIGN KEY (ProductId) REFERENCES [master].Product(ProductId),
      CONSTRAINT FK_pos_WaitTicketLine_Tax FOREIGN KEY (CountryCode, TaxCode) REFERENCES fiscal.TaxRate(CountryCode, TaxCode)
    );
  END;

  IF OBJECT_ID('pos.SaleTicket', 'U') IS NULL
  BEGIN
    CREATE TABLE pos.SaleTicket(
      SaleTicketId              BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      CompanyId                 INT NOT NULL,
      BranchId                  INT NOT NULL,
      CountryCode               CHAR(2) NOT NULL,
      InvoiceNumber             NVARCHAR(20) NOT NULL,
      CashRegisterCode          NVARCHAR(10) NOT NULL,
      SoldByUserId              INT NULL,
      CustomerId                BIGINT NULL,
      CustomerCode              NVARCHAR(24) NULL,
      CustomerName              NVARCHAR(200) NULL,
      CustomerFiscalId          NVARCHAR(30) NULL,
      PriceTier                 NVARCHAR(20) NOT NULL CONSTRAINT DF_pos_SaleTicket_PriceTier DEFAULT('DETAIL'),
      PaymentMethod             NVARCHAR(50) NULL,
      FiscalPayload             NVARCHAR(MAX) NULL,
      WaitTicketId              BIGINT NULL,
      NetAmount                 DECIMAL(18,2) NOT NULL CONSTRAINT DF_pos_SaleTicket_Net DEFAULT(0),
      DiscountAmount            DECIMAL(18,2) NOT NULL CONSTRAINT DF_pos_SaleTicket_Discount DEFAULT(0),
      TaxAmount                 DECIMAL(18,2) NOT NULL CONSTRAINT DF_pos_SaleTicket_Tax DEFAULT(0),
      TotalAmount               DECIMAL(18,2) NOT NULL CONSTRAINT DF_pos_SaleTicket_Total DEFAULT(0),
      SoldAt                    DATETIME2(0) NOT NULL CONSTRAINT DF_pos_SaleTicket_SoldAt DEFAULT(SYSUTCDATETIME()),
      RowVer                    ROWVERSION NOT NULL,
      CONSTRAINT UQ_pos_SaleTicket UNIQUE (CompanyId, BranchId, InvoiceNumber),
      CONSTRAINT FK_pos_SaleTicket_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId),
      CONSTRAINT FK_pos_SaleTicket_Branch FOREIGN KEY (BranchId) REFERENCES cfg.Branch(BranchId),
      CONSTRAINT FK_pos_SaleTicket_Country FOREIGN KEY (CountryCode) REFERENCES cfg.Country(CountryCode),
      CONSTRAINT FK_pos_SaleTicket_Customer FOREIGN KEY (CustomerId) REFERENCES [master].Customer(CustomerId),
      CONSTRAINT FK_pos_SaleTicket_WaitTicket FOREIGN KEY (WaitTicketId) REFERENCES pos.WaitTicket(WaitTicketId),
      CONSTRAINT FK_pos_SaleTicket_SoldBy FOREIGN KEY (SoldByUserId) REFERENCES sec.[User](UserId)
    );
  END;

  IF OBJECT_ID('pos.SaleTicketLine', 'U') IS NULL
  BEGIN
    CREATE TABLE pos.SaleTicketLine(
      SaleTicketLineId          BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      SaleTicketId              BIGINT NOT NULL,
      LineNumber                INT NOT NULL,
      CountryCode               CHAR(2) NOT NULL,
      ProductId                 BIGINT NULL,
      ProductCode               NVARCHAR(80) NOT NULL,
      ProductName               NVARCHAR(250) NOT NULL,
      Quantity                  DECIMAL(10,3) NOT NULL,
      UnitPrice                 DECIMAL(18,2) NOT NULL,
      DiscountAmount            DECIMAL(18,2) NOT NULL CONSTRAINT DF_pos_SaleTicketLine_Discount DEFAULT(0),
      TaxCode                   NVARCHAR(30) NOT NULL,
      TaxRate                   DECIMAL(9,4) NOT NULL,
      NetAmount                 DECIMAL(18,2) NOT NULL,
      TaxAmount                 DECIMAL(18,2) NOT NULL,
      TotalAmount               DECIMAL(18,2) NOT NULL,
      CONSTRAINT UQ_pos_SaleTicketLine UNIQUE (SaleTicketId, LineNumber),
      CONSTRAINT FK_pos_SaleTicketLine_SaleTicket FOREIGN KEY (SaleTicketId) REFERENCES pos.SaleTicket(SaleTicketId) ON DELETE CASCADE,
      CONSTRAINT FK_pos_SaleTicketLine_Product FOREIGN KEY (ProductId) REFERENCES [master].Product(ProductId),
      CONSTRAINT FK_pos_SaleTicketLine_Tax FOREIGN KEY (CountryCode, TaxCode) REFERENCES fiscal.TaxRate(CountryCode, TaxCode)
    );
  END;

  IF OBJECT_ID('rest.OrderTicket', 'U') IS NULL
  BEGIN
    CREATE TABLE rest.OrderTicket(
      OrderTicketId             BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      CompanyId                 INT NOT NULL,
      BranchId                  INT NOT NULL,
      CountryCode               CHAR(2) NOT NULL,
      TableNumber               NVARCHAR(20) NULL,
      OpenedByUserId            INT NULL,
      ClosedByUserId            INT NULL,
      CustomerName              NVARCHAR(200) NULL,
      CustomerFiscalId          NVARCHAR(30) NULL,
      Status                    NVARCHAR(20) NOT NULL CONSTRAINT DF_rest_OrderTicket_Status DEFAULT('OPEN'),
      NetAmount                 DECIMAL(18,2) NOT NULL CONSTRAINT DF_rest_OrderTicket_Net DEFAULT(0),
      TaxAmount                 DECIMAL(18,2) NOT NULL CONSTRAINT DF_rest_OrderTicket_Tax DEFAULT(0),
      TotalAmount               DECIMAL(18,2) NOT NULL CONSTRAINT DF_rest_OrderTicket_Total DEFAULT(0),
      OpenedAt                  DATETIME2(0) NOT NULL CONSTRAINT DF_rest_OrderTicket_OpenedAt DEFAULT(SYSUTCDATETIME()),
      ClosedAt                  DATETIME2(0) NULL,
      RowVer                    ROWVERSION NOT NULL,
      CONSTRAINT CK_rest_OrderTicket_Status CHECK (Status IN ('OPEN','SENT','CLOSED','VOIDED')),
      CONSTRAINT FK_rest_OrderTicket_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId),
      CONSTRAINT FK_rest_OrderTicket_Branch FOREIGN KEY (BranchId) REFERENCES cfg.Branch(BranchId),
      CONSTRAINT FK_rest_OrderTicket_Country FOREIGN KEY (CountryCode) REFERENCES cfg.Country(CountryCode),
      CONSTRAINT FK_rest_OrderTicket_OpenedBy FOREIGN KEY (OpenedByUserId) REFERENCES sec.[User](UserId),
      CONSTRAINT FK_rest_OrderTicket_ClosedBy FOREIGN KEY (ClosedByUserId) REFERENCES sec.[User](UserId)
    );
  END;

  IF OBJECT_ID('rest.OrderTicketLine', 'U') IS NULL
  BEGIN
    CREATE TABLE rest.OrderTicketLine(
      OrderTicketLineId         BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      OrderTicketId             BIGINT NOT NULL,
      LineNumber                INT NOT NULL,
      CountryCode               CHAR(2) NOT NULL,
      ProductId                 BIGINT NULL,
      ProductCode               NVARCHAR(80) NOT NULL,
      ProductName               NVARCHAR(250) NOT NULL,
      Quantity                  DECIMAL(10,3) NOT NULL,
      UnitPrice                 DECIMAL(18,2) NOT NULL,
      TaxCode                   NVARCHAR(30) NOT NULL,
      TaxRate                   DECIMAL(9,4) NOT NULL,
      NetAmount                 DECIMAL(18,2) NOT NULL,
      TaxAmount                 DECIMAL(18,2) NOT NULL,
      TotalAmount               DECIMAL(18,2) NOT NULL,
      Notes                     NVARCHAR(300) NULL,
      CONSTRAINT UQ_rest_OrderTicketLine UNIQUE (OrderTicketId, LineNumber),
      CONSTRAINT FK_rest_OrderTicketLine_Order FOREIGN KEY (OrderTicketId) REFERENCES rest.OrderTicket(OrderTicketId) ON DELETE CASCADE,
      CONSTRAINT FK_rest_OrderTicketLine_Product FOREIGN KEY (ProductId) REFERENCES [master].Product(ProductId),
      CONSTRAINT FK_rest_OrderTicketLine_Tax FOREIGN KEY (CountryCode, TaxCode) REFERENCES fiscal.TaxRate(CountryCode, TaxCode)
    );
  END;

  COMMIT TRAN;
END TRY
BEGIN CATCH
  IF @@TRANCOUNT > 0 ROLLBACK TRAN;
  DECLARE @Err NVARCHAR(4000) = ERROR_MESSAGE();
  RAISERROR('Error 04_operations_core.sql: %s',16,1,@Err);
END CATCH;
GO
