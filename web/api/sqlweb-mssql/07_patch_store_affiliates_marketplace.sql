-- ============================================================
-- Patch 07: store schema — Affiliates + Marketplace (merchants)
-- SQL Server 2012+ compatible
-- Equivalente a migraciones PG:
--   00149_store_affiliate_program.sql
--   00150_store_merchant_marketplace.sql
--
-- NOTA: el marketplace usa "Merchant" (comerciante externo) para evitar
-- colisión con master.Seller (vendedor comercial del ERP).
-- ============================================================
USE zentto_dev;
GO

-- =============================================================================
-- AFFILIATES
-- =============================================================================

IF OBJECT_ID('store.AffiliateCommissionRate', 'U') IS NULL
CREATE TABLE store.AffiliateCommissionRate (
    Id           BIGINT IDENTITY(1,1) CONSTRAINT PK_store_AffiliateCommissionRate PRIMARY KEY,
    Category     NVARCHAR(80) NOT NULL CONSTRAINT UQ_AffCommRate_Category UNIQUE,
    Rate         DECIMAL(5,2) NOT NULL CONSTRAINT DF_AffCommRate_Rate DEFAULT(0),
    IsDefault    BIT NOT NULL CONSTRAINT DF_AffCommRate_IsDefault DEFAULT(0),
    CreatedAt    DATETIME NOT NULL CONSTRAINT DF_AffCommRate_CreatedAt DEFAULT(GETUTCDATE()),
    UpdatedAt    DATETIME NOT NULL CONSTRAINT DF_AffCommRate_UpdatedAt DEFAULT(GETUTCDATE())
);
GO

IF NOT EXISTS (SELECT 1 FROM store.AffiliateCommissionRate WHERE Category = N'Electrónica')
    INSERT INTO store.AffiliateCommissionRate (Category, Rate, IsDefault)
    VALUES (N'Electrónica', 3.00, 0), (N'Ropa', 5.00, 0), (N'Hogar', 7.00, 0), (N'Software', 10.00, 0), (N'default', 3.00, 1);
GO

IF OBJECT_ID('store.Affiliate', 'U') IS NULL
CREATE TABLE store.Affiliate (
    Id             BIGINT IDENTITY(1,1) CONSTRAINT PK_store_Affiliate PRIMARY KEY,
    CustomerId     INT NULL,
    CompanyId      INT NOT NULL CONSTRAINT DF_Affiliate_CompanyId DEFAULT(1),
    ReferralCode   NVARCHAR(20) NOT NULL CONSTRAINT UQ_Affiliate_ReferralCode UNIQUE,
    Status         NVARCHAR(20) NOT NULL CONSTRAINT DF_Affiliate_Status DEFAULT('pending'),
    PayoutMethod   NVARCHAR(30) NULL,
    PayoutDetails  NVARCHAR(MAX) NULL,
    TaxId          NVARCHAR(40) NULL,
    LegalName      NVARCHAR(200) NULL,
    ContactEmail   NVARCHAR(200) NULL,
    CreatedAt      DATETIME NOT NULL CONSTRAINT DF_Affiliate_CreatedAt DEFAULT(GETUTCDATE()),
    ApprovedAt     DATETIME NULL,
    ApprovedBy     NVARCHAR(60) NULL,
    CONSTRAINT CHK_Affiliate_Status CHECK (Status IN ('active','suspended','pending','rejected'))
);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_store_Affiliate_Customer' AND object_id = OBJECT_ID('store.Affiliate'))
    CREATE INDEX IX_store_Affiliate_Customer ON store.Affiliate (CompanyId, CustomerId);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_store_Affiliate_Status' AND object_id = OBJECT_ID('store.Affiliate'))
    CREATE INDEX IX_store_Affiliate_Status ON store.Affiliate (CompanyId, Status);
GO

IF OBJECT_ID('store.AffiliateClick', 'U') IS NULL
CREATE TABLE store.AffiliateClick (
    Id             BIGINT IDENTITY(1,1) CONSTRAINT PK_store_AffiliateClick PRIMARY KEY,
    ReferralCode   NVARCHAR(20) NOT NULL,
    AffiliateId    BIGINT NULL CONSTRAINT FK_AffClick_Affiliate REFERENCES store.Affiliate(Id),
    SessionId      NVARCHAR(100) NULL,
    CustomerId     INT NULL,
    Ip             NVARCHAR(45) NULL,
    UserAgent      NVARCHAR(500) NULL,
    Referer        NVARCHAR(500) NULL,
    CreatedAt      DATETIMEOFFSET NOT NULL CONSTRAINT DF_AffClick_CreatedAt DEFAULT(SYSDATETIMEOFFSET())
);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_store_AffClick_Code' AND object_id = OBJECT_ID('store.AffiliateClick'))
    CREATE INDEX IX_store_AffClick_Code ON store.AffiliateClick (ReferralCode, CreatedAt DESC);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_store_AffClick_Session' AND object_id = OBJECT_ID('store.AffiliateClick'))
    CREATE INDEX IX_store_AffClick_Session ON store.AffiliateClick (SessionId, CreatedAt DESC);
GO

IF OBJECT_ID('store.AffiliateCommission', 'U') IS NULL
CREATE TABLE store.AffiliateCommission (
    Id                BIGINT IDENTITY(1,1) CONSTRAINT PK_store_AffiliateCommission PRIMARY KEY,
    AffiliateId       BIGINT NOT NULL CONSTRAINT FK_AffCommission_Affiliate REFERENCES store.Affiliate(Id),
    CompanyId         INT NOT NULL CONSTRAINT DF_AffCommission_CompanyId DEFAULT(1),
    OrderNumber       NVARCHAR(60) NOT NULL,
    Rate              DECIMAL(5,2) NOT NULL,
    Category          NVARCHAR(80) NULL,
    CommissionAmount  DECIMAL(14,2) NOT NULL CONSTRAINT DF_AffCommission_Amount DEFAULT(0),
    CurrencyCode      CHAR(3) NOT NULL CONSTRAINT DF_AffCommission_Currency DEFAULT('USD'),
    Status            NVARCHAR(20) NOT NULL CONSTRAINT DF_AffCommission_Status DEFAULT('pending'),
    ClickId           BIGINT NULL CONSTRAINT FK_AffCommission_Click REFERENCES store.AffiliateClick(Id),
    PayoutId          BIGINT NULL,
    CreatedAt         DATETIME NOT NULL CONSTRAINT DF_AffCommission_CreatedAt DEFAULT(GETUTCDATE()),
    ApprovedAt        DATETIME NULL,
    PaidAt            DATETIME NULL,
    CONSTRAINT CHK_AffCommission_Status CHECK (Status IN ('pending','approved','paid','reversed'))
);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_store_AffCommission_Aff' AND object_id = OBJECT_ID('store.AffiliateCommission'))
    CREATE INDEX IX_store_AffCommission_Aff ON store.AffiliateCommission (AffiliateId, Status, CreatedAt DESC);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_store_AffCommission_Order' AND object_id = OBJECT_ID('store.AffiliateCommission'))
    CREATE INDEX IX_store_AffCommission_Order ON store.AffiliateCommission (CompanyId, OrderNumber);
GO

IF OBJECT_ID('store.AffiliatePayout', 'U') IS NULL
CREATE TABLE store.AffiliatePayout (
    Id              BIGINT IDENTITY(1,1) CONSTRAINT PK_store_AffiliatePayout PRIMARY KEY,
    AffiliateId     BIGINT NOT NULL CONSTRAINT FK_AffPayout_Affiliate REFERENCES store.Affiliate(Id),
    CompanyId       INT NOT NULL CONSTRAINT DF_AffPayout_CompanyId DEFAULT(1),
    PeriodStart     DATE NOT NULL,
    PeriodEnd       DATE NOT NULL,
    TotalAmount     DECIMAL(14,2) NOT NULL CONSTRAINT DF_AffPayout_Amount DEFAULT(0),
    CurrencyCode    CHAR(3) NOT NULL CONSTRAINT DF_AffPayout_Currency DEFAULT('USD'),
    Status          NVARCHAR(20) NOT NULL CONSTRAINT DF_AffPayout_Status DEFAULT('pending'),
    PaidAt          DATETIME NULL,
    TransactionRef  NVARCHAR(100) NULL,
    CreatedAt       DATETIME NOT NULL CONSTRAINT DF_AffPayout_CreatedAt DEFAULT(GETUTCDATE()),
    CONSTRAINT CHK_AffPayout_Status CHECK (Status IN ('pending','processing','paid','failed'))
);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_store_AffPayout_Aff' AND object_id = OBJECT_ID('store.AffiliatePayout'))
    CREATE INDEX IX_store_AffPayout_Aff ON store.AffiliatePayout (AffiliateId, Status, PeriodEnd DESC);
GO

-- =============================================================================
-- MARKETPLACE (merchants) — comerciantes externos del marketplace
-- Se usa "Merchant" en lugar de "Seller" para evitar colisión con
-- master.Seller (vendedor comercial del ERP en baseline 005_functions.sql).
-- =============================================================================

IF OBJECT_ID('store.Merchant', 'U') IS NULL
CREATE TABLE store.Merchant (
    Id              BIGINT IDENTITY(1,1) CONSTRAINT PK_store_Merchant PRIMARY KEY,
    CompanyId       INT NOT NULL CONSTRAINT DF_Merchant_CompanyId DEFAULT(1),
    CustomerId      INT NULL,
    LegalName       NVARCHAR(200) NOT NULL,
    TaxId           NVARCHAR(40) NULL,
    StoreSlug       NVARCHAR(80) NOT NULL CONSTRAINT UQ_Merchant_Slug UNIQUE,
    Description     NVARCHAR(MAX) NULL,
    LogoUrl         NVARCHAR(500) NULL,
    BannerUrl       NVARCHAR(500) NULL,
    ContactEmail    NVARCHAR(200) NULL,
    ContactPhone    NVARCHAR(40) NULL,
    Status          NVARCHAR(20) NOT NULL CONSTRAINT DF_Merchant_Status DEFAULT('pending'),
    CommissionRate  DECIMAL(5,2) NOT NULL CONSTRAINT DF_Merchant_CommRate DEFAULT(15.00),
    PayoutMethod    NVARCHAR(30) NULL,
    PayoutDetails   NVARCHAR(MAX) NULL,
    RejectionReason NVARCHAR(500) NULL,
    CreatedAt       DATETIME NOT NULL CONSTRAINT DF_Merchant_CreatedAt DEFAULT(GETUTCDATE()),
    ApprovedAt      DATETIME NULL,
    ApprovedBy      NVARCHAR(60) NULL,
    CONSTRAINT CHK_Merchant_Status CHECK (Status IN ('pending','approved','suspended','rejected'))
);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_store_Merchant_Status' AND object_id = OBJECT_ID('store.Merchant'))
    CREATE INDEX IX_store_Merchant_Status ON store.Merchant (CompanyId, Status);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_store_Merchant_Customer' AND object_id = OBJECT_ID('store.Merchant'))
    CREATE INDEX IX_store_Merchant_Customer ON store.Merchant (CompanyId, CustomerId);
GO

IF OBJECT_ID('store.MerchantProduct', 'U') IS NULL
CREATE TABLE store.MerchantProduct (
    Id             BIGINT IDENTITY(1,1) CONSTRAINT PK_store_MerchantProduct PRIMARY KEY,
    MerchantId     BIGINT NOT NULL CONSTRAINT FK_MerchantProduct_Merchant REFERENCES store.Merchant(Id),
    CompanyId      INT NOT NULL CONSTRAINT DF_MerchantProduct_CompanyId DEFAULT(1),
    ProductCode    NVARCHAR(64) NOT NULL,
    Name           NVARCHAR(250) NOT NULL,
    Description    NVARCHAR(MAX) NULL,
    Price          DECIMAL(18,4) NOT NULL CONSTRAINT DF_MerchantProduct_Price DEFAULT(0),
    Stock          DECIMAL(18,4) NOT NULL CONSTRAINT DF_MerchantProduct_Stock DEFAULT(0),
    Category       NVARCHAR(80) NULL,
    ImageUrl       NVARCHAR(500) NULL,
    Status         NVARCHAR(20) NOT NULL CONSTRAINT DF_MerchantProduct_Status DEFAULT('draft'),
    ReviewNotes    NVARCHAR(MAX) NULL,
    CreatedAt      DATETIME NOT NULL CONSTRAINT DF_MerchantProduct_CreatedAt DEFAULT(GETUTCDATE()),
    UpdatedAt      DATETIME NOT NULL CONSTRAINT DF_MerchantProduct_UpdatedAt DEFAULT(GETUTCDATE()),
    ReviewedAt     DATETIME NULL,
    ReviewedBy     NVARCHAR(60) NULL,
    CONSTRAINT CHK_MerchantProduct_Status CHECK (Status IN ('draft','pending_review','approved','rejected'))
);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_store_MerchantProduct_Merchant' AND object_id = OBJECT_ID('store.MerchantProduct'))
    CREATE INDEX IX_store_MerchantProduct_Merchant ON store.MerchantProduct (MerchantId, Status);
GO

IF OBJECT_ID('store.MerchantPayout', 'U') IS NULL
CREATE TABLE store.MerchantPayout (
    Id                BIGINT IDENTITY(1,1) CONSTRAINT PK_store_MerchantPayout PRIMARY KEY,
    MerchantId        BIGINT NOT NULL CONSTRAINT FK_MerchantPayout_Merchant REFERENCES store.Merchant(Id),
    CompanyId         INT NOT NULL CONSTRAINT DF_MerchantPayout_CompanyId DEFAULT(1),
    PeriodStart       DATE NOT NULL,
    PeriodEnd         DATE NOT NULL,
    GrossAmount       DECIMAL(14,2) NOT NULL CONSTRAINT DF_MerchantPayout_Gross DEFAULT(0),
    CommissionAmount  DECIMAL(14,2) NOT NULL CONSTRAINT DF_MerchantPayout_Comm DEFAULT(0),
    NetAmount         DECIMAL(14,2) NOT NULL CONSTRAINT DF_MerchantPayout_Net DEFAULT(0),
    CurrencyCode      CHAR(3) NOT NULL CONSTRAINT DF_MerchantPayout_Currency DEFAULT('USD'),
    Status            NVARCHAR(20) NOT NULL CONSTRAINT DF_MerchantPayout_Status DEFAULT('pending'),
    PaidAt            DATETIME NULL,
    TransactionRef    NVARCHAR(100) NULL,
    CreatedAt         DATETIME NOT NULL CONSTRAINT DF_MerchantPayout_CreatedAt DEFAULT(GETUTCDATE()),
    CONSTRAINT CHK_MerchantPayout_Status CHECK (Status IN ('pending','processing','paid','failed'))
);
GO

-- Extender ar.SalesDocumentLine con MerchantId (marketplace attribution)
IF COL_LENGTH('ar.SalesDocumentLine', 'MerchantId') IS NULL
    ALTER TABLE ar.SalesDocumentLine ADD MerchantId BIGINT NULL;
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_ar_SalesDocLine_Merchant' AND object_id = OBJECT_ID('ar.SalesDocumentLine'))
    CREATE INDEX IX_ar_SalesDocLine_Merchant ON ar.SalesDocumentLine (MerchantId) WHERE MerchantId IS NOT NULL;
GO
