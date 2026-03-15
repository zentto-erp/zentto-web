-- =============================================
-- Creacion de tablas de documentos unificados - PostgreSQL
-- Tablas reales: ar."SalesDocument"*, ap."PurchaseDocument"*
-- Traducido de SQL Server a PostgreSQL
-- =============================================

-- =============================================================================
-- SECCION 1: TABLAS ar.* (Documentos de Venta)
-- =============================================================================

CREATE SCHEMA IF NOT EXISTS ar;
CREATE SCHEMA IF NOT EXISTS ap;
CREATE SCHEMA IF NOT EXISTS acct;
CREATE SCHEMA IF NOT EXISTS doc;

-- 1.1 ar."SalesDocument"
CREATE TABLE IF NOT EXISTS ar."SalesDocument" (
    "DocumentId"          SERIAL NOT NULL,
    "DocumentNumber"      VARCHAR(60)  NOT NULL,
    "SerialType"          VARCHAR(60)  NOT NULL DEFAULT '',
    "FiscalMemoryNumber"  VARCHAR(80)  DEFAULT '',
    "OperationType"       VARCHAR(20)  NOT NULL,
    "CustomerCode"        VARCHAR(60),
    "CustomerName"        VARCHAR(255),
    "FiscalId"            VARCHAR(20),
    "DocumentDate"        TIMESTAMP    DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "DueDate"             TIMESTAMP,
    "DocumentTime"        VARCHAR(20)  DEFAULT TO_CHAR(NOW() AT TIME ZONE 'UTC', 'HH24:MI:SS'),
    "SubTotal"            NUMERIC(18,4) DEFAULT 0,
    "TaxableAmount"       NUMERIC(18,4) DEFAULT 0,
    "ExemptAmount"        NUMERIC(18,4) DEFAULT 0,
    "TaxAmount"           NUMERIC(18,4) DEFAULT 0,
    "TaxRate"             NUMERIC(8,4)  DEFAULT 0,
    "TotalAmount"         NUMERIC(18,4) DEFAULT 0,
    "DiscountAmount"      NUMERIC(18,4) DEFAULT 0,
    "IsVoided"            BOOLEAN       DEFAULT FALSE,
    "IsPaid"              VARCHAR(1)    DEFAULT 'N',
    "IsInvoiced"          VARCHAR(1)    DEFAULT 'N',
    "IsDelivered"         VARCHAR(1)    DEFAULT 'N',
    "OriginDocumentNumber" VARCHAR(60),
    "OriginDocumentType"  VARCHAR(20),
    "ControlNumber"       VARCHAR(60),
    "IsLegal"             BOOLEAN       DEFAULT FALSE,
    "IsPrinted"           BOOLEAN       DEFAULT FALSE,
    "Notes"               VARCHAR(500),
    "Concept"             VARCHAR(255),
    "PaymentTerms"        VARCHAR(255),
    "ShipToAddress"       VARCHAR(255),
    "SellerCode"          VARCHAR(60),
    "DepartmentCode"      VARCHAR(50),
    "LocationCode"        VARCHAR(100),
    "CurrencyCode"        VARCHAR(20)   DEFAULT 'BS',
    "ExchangeRate"        NUMERIC(18,6) DEFAULT 1,
    "UserCode"            VARCHAR(60)   DEFAULT 'API',
    "ReportDate"          TIMESTAMP     DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "HostName"            VARCHAR(255)  DEFAULT inet_client_addr()::TEXT,
    "VehiclePlate"        VARCHAR(20),
    "Mileage"             INT,
    "TollAmount"          NUMERIC(18,4) DEFAULT 0,
    "CreatedAt"           TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "UpdatedAt"           TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "CreatedByUserId"     INT,
    "UpdatedByUserId"     INT,
    "IsDeleted"           BOOLEAN       NOT NULL DEFAULT FALSE,
    "DeletedAt"           TIMESTAMP,
    "DeletedByUserId"     INT,
    CONSTRAINT "PK_SalesDocument" PRIMARY KEY ("DocumentId"),
    CONSTRAINT "UQ_SalesDocument_NumDocOp" UNIQUE ("DocumentNumber", "OperationType")
);

CREATE INDEX IF NOT EXISTS "IX_SalesDocument_Customer" ON ar."SalesDocument"("CustomerCode");
CREATE INDEX IF NOT EXISTS "IX_SalesDocument_OpDate" ON ar."SalesDocument"("OperationType", "DocumentDate" DESC) WHERE "IsDeleted" = FALSE;

-- 1.2 ar."SalesDocumentLine"
CREATE TABLE IF NOT EXISTS ar."SalesDocumentLine" (
    "LineId"              SERIAL NOT NULL,
    "DocumentNumber"      VARCHAR(60)  NOT NULL,
    "SerialType"          VARCHAR(60)  NOT NULL DEFAULT '',
    "FiscalMemoryNumber"  VARCHAR(80)  DEFAULT '',
    "OperationType"       VARCHAR(20)  NOT NULL,
    "LineNumber"          INT           DEFAULT 0,
    "ProductCode"         VARCHAR(60),
    "Description"         VARCHAR(255),
    "AlternateCode"       VARCHAR(60),
    "Quantity"            NUMERIC(18,4) DEFAULT 0,
    "UnitPrice"           NUMERIC(18,4) DEFAULT 0,
    "DiscountedPrice"     NUMERIC(18,4) DEFAULT 0,
    "UnitCost"            NUMERIC(18,4) DEFAULT 0,
    "SubTotal"            NUMERIC(18,4) DEFAULT 0,
    "DiscountAmount"      NUMERIC(18,4) DEFAULT 0,
    "TotalAmount"         NUMERIC(18,4) DEFAULT 0,
    "TaxRate"             NUMERIC(8,4)  DEFAULT 0,
    "TaxAmount"           NUMERIC(18,4) DEFAULT 0,
    "IsVoided"            BOOLEAN       DEFAULT FALSE,
    "RelatedRef"          VARCHAR(10)   DEFAULT '0',
    "UserCode"            VARCHAR(60)   DEFAULT 'API',
    "LineDate"            TIMESTAMP     DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "CreatedAt"           TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "UpdatedAt"           TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "CreatedByUserId"     INT,
    "UpdatedByUserId"     INT,
    "IsDeleted"           BOOLEAN       NOT NULL DEFAULT FALSE,
    "DeletedAt"           TIMESTAMP,
    "DeletedByUserId"     INT,
    CONSTRAINT "PK_SalesDocumentLine" PRIMARY KEY ("LineId")
);

CREATE INDEX IF NOT EXISTS "IX_SalesDocLine_DocKey" ON ar."SalesDocumentLine"("DocumentNumber", "OperationType") WHERE "IsDeleted" = FALSE;
CREATE INDEX IF NOT EXISTS "IX_SalesDocLine_Product" ON ar."SalesDocumentLine"("ProductCode");

-- 1.3 ar."SalesDocumentPayment"
CREATE TABLE IF NOT EXISTS ar."SalesDocumentPayment" (
    "PaymentId"           SERIAL NOT NULL,
    "DocumentNumber"      VARCHAR(60)  NOT NULL,
    "SerialType"          VARCHAR(60)  NOT NULL DEFAULT '',
    "FiscalMemoryNumber"  VARCHAR(80)  DEFAULT '',
    "OperationType"       VARCHAR(20)  NOT NULL DEFAULT 'FACT',
    "PaymentMethod"       VARCHAR(30),
    "BankCode"            VARCHAR(60),
    "PaymentNumber"       VARCHAR(60),
    "Amount"              NUMERIC(18,4) DEFAULT 0,
    "AmountBs"            NUMERIC(18,4) DEFAULT 0,
    "ExchangeRate"        NUMERIC(18,6) DEFAULT 1,
    "PaymentDate"         TIMESTAMP     DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "DueDate"             TIMESTAMP,
    "ReferenceNumber"     VARCHAR(100),
    "UserCode"            VARCHAR(60)   DEFAULT 'API',
    "CreatedAt"           TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "UpdatedAt"           TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "CreatedByUserId"     INT,
    "UpdatedByUserId"     INT,
    "IsDeleted"           BOOLEAN       NOT NULL DEFAULT FALSE,
    "DeletedAt"           TIMESTAMP,
    "DeletedByUserId"     INT,
    CONSTRAINT "PK_SalesDocumentPayment" PRIMARY KEY ("PaymentId")
);

CREATE INDEX IF NOT EXISTS "IX_SalesDocPay_DocKey" ON ar."SalesDocumentPayment"("DocumentNumber", "OperationType") WHERE "IsDeleted" = FALSE;

-- =============================================================================
-- SECCION 2: TABLAS ap.* (Documentos de Compra)
-- =============================================================================

-- 2.1 ap."PurchaseDocument"
CREATE TABLE IF NOT EXISTS ap."PurchaseDocument" (
    "DocumentId"          SERIAL NOT NULL,
    "DocumentNumber"      VARCHAR(60)  NOT NULL,
    "SerialType"          VARCHAR(60)  NOT NULL DEFAULT '',
    "FiscalMemoryNumber"  VARCHAR(80)  DEFAULT '',
    "OperationType"       VARCHAR(20)  NOT NULL DEFAULT 'COMPRA',
    "SupplierCode"        VARCHAR(60),
    "SupplierName"        VARCHAR(255),
    "FiscalId"            VARCHAR(15),
    "DocumentDate"        TIMESTAMP     DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "DueDate"             TIMESTAMP,
    "ReceiptDate"         TIMESTAMP,
    "PaymentDate"         TIMESTAMP,
    "DocumentTime"        VARCHAR(20)   DEFAULT TO_CHAR(NOW() AT TIME ZONE 'UTC', 'HH24:MI:SS'),
    "SubTotal"            NUMERIC(18,4) DEFAULT 0,
    "TaxableAmount"       NUMERIC(18,4) DEFAULT 0,
    "ExemptAmount"        NUMERIC(18,4) DEFAULT 0,
    "TaxAmount"           NUMERIC(18,4) DEFAULT 0,
    "TaxRate"             NUMERIC(8,4)  DEFAULT 0,
    "TotalAmount"         NUMERIC(18,4) DEFAULT 0,
    "ExemptTotalAmount"   NUMERIC(18,4) DEFAULT 0,
    "DiscountAmount"      NUMERIC(18,4) DEFAULT 0,
    "IsVoided"            BOOLEAN       DEFAULT FALSE,
    "IsPaid"              VARCHAR(1)    DEFAULT 'N',
    "IsReceived"          VARCHAR(1)    DEFAULT 'N',
    "IsLegal"             BOOLEAN       DEFAULT FALSE,
    "OriginDocumentNumber" VARCHAR(60),
    "ControlNumber"       VARCHAR(60),
    "VoucherNumber"       VARCHAR(50),
    "VoucherDate"         TIMESTAMP,
    "RetainedTax"         NUMERIC(18,4) DEFAULT 0,
    "IsrCode"             VARCHAR(50),
    "IsrAmount"           NUMERIC(18,4) DEFAULT 0,
    "IsrSubjectAmount"    NUMERIC(18,4) DEFAULT 0,
    "RetentionRate"       NUMERIC(8,4)  DEFAULT 0,
    "ImportAmount"        NUMERIC(18,4) DEFAULT 0,
    "ImportTax"           NUMERIC(18,4) DEFAULT 0,
    "ImportBase"          NUMERIC(18,4) DEFAULT 0,
    "FreightAmount"       NUMERIC(18,4) DEFAULT 0,
    "Concept"             VARCHAR(255),
    "Notes"               VARCHAR(500),
    "OrderNumber"         VARCHAR(20),
    "ReceivedBy"          VARCHAR(20),
    "WarehouseCode"       VARCHAR(50),
    "CurrencyCode"        VARCHAR(20)   DEFAULT 'BS',
    "ExchangeRate"        NUMERIC(18,6) DEFAULT 1,
    "UsdAmount"           NUMERIC(18,4) DEFAULT 0,
    "UserCode"            VARCHAR(60)   DEFAULT 'API',
    "ShortUserCode"       VARCHAR(10),
    "ReportDate"          TIMESTAMP     DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "HostName"            VARCHAR(255)  DEFAULT inet_client_addr()::TEXT,
    "CreatedAt"           TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "UpdatedAt"           TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "CreatedByUserId"     INT,
    "UpdatedByUserId"     INT,
    "IsDeleted"           BOOLEAN       NOT NULL DEFAULT FALSE,
    "DeletedAt"           TIMESTAMP,
    "DeletedByUserId"     INT,
    CONSTRAINT "PK_PurchaseDocument" PRIMARY KEY ("DocumentId"),
    CONSTRAINT "UQ_PurchaseDocument_NumDocOp" UNIQUE ("DocumentNumber", "OperationType")
);

CREATE INDEX IF NOT EXISTS "IX_PurchaseDocument_Supplier" ON ap."PurchaseDocument"("SupplierCode");
CREATE INDEX IF NOT EXISTS "IX_PurchaseDocument_OpDate" ON ap."PurchaseDocument"("OperationType", "DocumentDate") WHERE "IsDeleted" = FALSE;

-- 2.2 ap."PurchaseDocumentLine"
CREATE TABLE IF NOT EXISTS ap."PurchaseDocumentLine" (
    "LineId"              SERIAL NOT NULL,
    "DocumentNumber"      VARCHAR(60)  NOT NULL,
    "SerialType"          VARCHAR(60)  NOT NULL DEFAULT '',
    "FiscalMemoryNumber"  VARCHAR(80)  DEFAULT '',
    "OperationType"       VARCHAR(20)  NOT NULL DEFAULT 'COMPRA',
    "LineNumber"          INT           DEFAULT 0,
    "ProductCode"         VARCHAR(60),
    "Description"         VARCHAR(255),
    "Quantity"            NUMERIC(18,4) DEFAULT 0,
    "UnitPrice"           NUMERIC(18,4) DEFAULT 0,
    "UnitCost"            NUMERIC(18,4) DEFAULT 0,
    "SubTotal"            NUMERIC(18,4) DEFAULT 0,
    "DiscountAmount"      NUMERIC(18,4) DEFAULT 0,
    "TotalAmount"         NUMERIC(18,4) DEFAULT 0,
    "TaxRate"             NUMERIC(8,4)  DEFAULT 0,
    "TaxAmount"           NUMERIC(18,4) DEFAULT 0,
    "IsVoided"            BOOLEAN       DEFAULT FALSE,
    "UserCode"            VARCHAR(60)   DEFAULT 'API',
    "LineDate"            TIMESTAMP     DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "CreatedAt"           TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "UpdatedAt"           TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "CreatedByUserId"     INT,
    "UpdatedByUserId"     INT,
    "IsDeleted"           BOOLEAN       NOT NULL DEFAULT FALSE,
    "DeletedAt"           TIMESTAMP,
    "DeletedByUserId"     INT,
    CONSTRAINT "PK_PurchaseDocumentLine" PRIMARY KEY ("LineId")
);

CREATE INDEX IF NOT EXISTS "IX_PurchDocLine_DocKey" ON ap."PurchaseDocumentLine"("DocumentNumber", "OperationType") WHERE "IsDeleted" = FALSE;
CREATE INDEX IF NOT EXISTS "IX_PurchDocLine_Product" ON ap."PurchaseDocumentLine"("ProductCode");

-- 2.3 ap."PurchaseDocumentPayment"
CREATE TABLE IF NOT EXISTS ap."PurchaseDocumentPayment" (
    "PaymentId"           SERIAL NOT NULL,
    "DocumentNumber"      VARCHAR(60)  NOT NULL,
    "SerialType"          VARCHAR(60)  NOT NULL DEFAULT '',
    "FiscalMemoryNumber"  VARCHAR(80)  DEFAULT '',
    "OperationType"       VARCHAR(20)  NOT NULL DEFAULT 'COMPRA',
    "PaymentMethod"       VARCHAR(30),
    "BankCode"            VARCHAR(60),
    "PaymentNumber"       VARCHAR(60),
    "Amount"              NUMERIC(18,4) DEFAULT 0,
    "PaymentDate"         TIMESTAMP     DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "DueDate"             TIMESTAMP,
    "ReferenceNumber"     VARCHAR(100),
    "UserCode"            VARCHAR(60)   DEFAULT 'API',
    "CreatedAt"           TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "UpdatedAt"           TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "CreatedByUserId"     INT,
    "UpdatedByUserId"     INT,
    "IsDeleted"           BOOLEAN       NOT NULL DEFAULT FALSE,
    "DeletedAt"           TIMESTAMP,
    "DeletedByUserId"     INT,
    CONSTRAINT "PK_PurchaseDocumentPayment" PRIMARY KEY ("PaymentId")
);

CREATE INDEX IF NOT EXISTS "IX_PurchDocPay_DocKey" ON ap."PurchaseDocumentPayment"("DocumentNumber", "OperationType") WHERE "IsDeleted" = FALSE;

-- =============================================================================
-- SECCION 5: TABLAS AUXILIARES (canonicas nuevas)
-- =============================================================================

-- 5.1 acct."BankDeposit"
CREATE TABLE IF NOT EXISTS acct."BankDeposit" (
    "BankDepositId"       SERIAL PRIMARY KEY,
    "Amount"              NUMERIC(18,4) NOT NULL DEFAULT 0,
    "CheckNumber"         VARCHAR(80),
    "BankAccount"         VARCHAR(120),
    "CustomerCode"        VARCHAR(60),
    "IsRelated"           BOOLEAN NOT NULL DEFAULT FALSE,
    "BankName"            VARCHAR(120),
    "DocumentRef"         VARCHAR(60),
    "OperationType"       VARCHAR(20),
    "CreatedAt"           TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "UpdatedAt"           TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "CreatedByUserId"     INT,
    "IsDeleted"           BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE INDEX IF NOT EXISTS "IX_BankDeposit_Customer" ON acct."BankDeposit"("CustomerCode") WHERE "IsDeleted" = FALSE;

-- 5.2 master."AlternateStock"
CREATE SCHEMA IF NOT EXISTS master;

CREATE TABLE IF NOT EXISTS master."AlternateStock" (
    "AlternateStockId"    SERIAL PRIMARY KEY,
    "ProductCode"         VARCHAR(80)  NOT NULL,
    "StockQty"            NUMERIC(18,4) NOT NULL DEFAULT 0,
    "CreatedAt"           TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "UpdatedAt"           TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "IsDeleted"           BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT "UQ_AlternateStock_ProductCode" UNIQUE ("ProductCode")
);
