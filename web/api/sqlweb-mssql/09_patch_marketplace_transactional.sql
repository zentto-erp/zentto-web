-- ============================================================
-- Patch 09: Marketplace transactional fixes — store.MerchantCommission
-- SQL Server 2012+ compatible
-- Equivalente a migración PG:
--   00157_marketplace_transactional_fixes.sql
--
-- Cierra 3 bloqueadores P0 del audit marketplace-flow-audit.md:
--   1. Tabla store.MerchantCommission (análoga a store.AffiliateCommission)
--      con AffiliateDeduction + NetZenttoRevenue (fix negocio afiliado+merchant).
--   2. Columna ar.SalesDocumentLine.MerchantId (idempotente — 07 ya la creó).
-- ============================================================
USE zentto_dev;
GO

-- Tabla store.MerchantCommission
IF OBJECT_ID('store.MerchantCommission', 'U') IS NULL
CREATE TABLE store.MerchantCommission (
    Id                  BIGINT IDENTITY(1,1) CONSTRAINT PK_store_MerchantCommission PRIMARY KEY,
    CompanyId           INT NOT NULL CONSTRAINT DF_MerchantCommission_CompanyId DEFAULT(1),
    MerchantId          BIGINT NOT NULL CONSTRAINT FK_MerchantCommission_Merchant REFERENCES store.Merchant(Id),
    OrderNumber         NVARCHAR(60) NOT NULL,
    OrderLineId         INT NULL,
    ProductCode         NVARCHAR(64) NULL,
    Category            NVARCHAR(80) NULL,
    GrossAmount         DECIMAL(14,2) NOT NULL CONSTRAINT DF_MerchantCommission_Gross DEFAULT(0),
    CommissionRate      DECIMAL(5,2)  NOT NULL CONSTRAINT DF_MerchantCommission_Rate DEFAULT(0),
    CommissionAmount    DECIMAL(14,2) NOT NULL CONSTRAINT DF_MerchantCommission_Amount DEFAULT(0),
    MerchantEarning     DECIMAL(14,2) NOT NULL CONSTRAINT DF_MerchantCommission_Earning DEFAULT(0),
    AffiliateDeduction  DECIMAL(14,2) NOT NULL CONSTRAINT DF_MerchantCommission_AffDed DEFAULT(0),
    NetZenttoRevenue    DECIMAL(14,2) NOT NULL CONSTRAINT DF_MerchantCommission_NetZ DEFAULT(0),
    CurrencyCode        CHAR(3) NOT NULL CONSTRAINT DF_MerchantCommission_Currency DEFAULT('USD'),
    Status              NVARCHAR(20) NOT NULL CONSTRAINT DF_MerchantCommission_Status DEFAULT('pending'),
    PayoutId            BIGINT NULL,
    CreatedAt           DATETIME NOT NULL CONSTRAINT DF_MerchantCommission_CreatedAt DEFAULT(GETUTCDATE()),
    ApprovedAt          DATETIME NULL,
    PaidAt              DATETIME NULL,
    CONSTRAINT CHK_MerchantCommission_Status CHECK (Status IN ('pending','approved','paid','reversed'))
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_store_MerchantCommission_MerchantStatus' AND object_id = OBJECT_ID('store.MerchantCommission'))
    CREATE INDEX IX_store_MerchantCommission_MerchantStatus
        ON store.MerchantCommission (MerchantId, Status, CreatedAt DESC);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_store_MerchantCommission_Order' AND object_id = OBJECT_ID('store.MerchantCommission'))
    CREATE INDEX IX_store_MerchantCommission_Order
        ON store.MerchantCommission (CompanyId, OrderNumber);
GO

-- Columna ar.SalesDocumentLine.MerchantId (idempotente)
IF COL_LENGTH('ar.SalesDocumentLine', 'MerchantId') IS NULL
    ALTER TABLE ar.SalesDocumentLine ADD MerchantId BIGINT NULL;
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_ar_SalesDocLine_Merchant' AND object_id = OBJECT_ID('ar.SalesDocumentLine'))
    CREATE INDEX IX_ar_SalesDocLine_Merchant ON ar.SalesDocumentLine (MerchantId) WHERE MerchantId IS NOT NULL;
GO
