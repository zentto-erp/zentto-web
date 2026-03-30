-- ============================================================
-- DatqBoxWeb PostgreSQL - 04_operations_core.sql
-- Tablas operativas: AR (cuentas por cobrar), AP (cuentas por
-- pagar), Fiscal, POS, Restaurante
-- ============================================================

BEGIN;

-- =========================================================
-- SCHEMA ar  (Accounts Receivable)
-- =========================================================

-- ---------------------------------------------------------
-- ar."ReceivableDocument"
-- ---------------------------------------------------------
CREATE TABLE IF NOT EXISTS ar."ReceivableDocument" (
  "ReceivableDocumentId"   BIGINT GENERATED ALWAYS AS IDENTITY NOT NULL PRIMARY KEY,
  "CompanyId"              INT NOT NULL,
  "BranchId"               INT NOT NULL,
  "CustomerId"             BIGINT NOT NULL,
  "DocumentType"           VARCHAR(20) NOT NULL,
  "DocumentNumber"         VARCHAR(120) NOT NULL,
  "IssueDate"              DATE NOT NULL,
  "DueDate"                DATE NULL,
  "CurrencyCode"           CHAR(3) NOT NULL,
  "TotalAmount"            NUMERIC(18,2) NOT NULL,
  "PendingAmount"          NUMERIC(18,2) NOT NULL,
  "PaidFlag"               BOOLEAN NOT NULL CONSTRAINT "DF_ar_RecDoc_PaidFlag" DEFAULT FALSE,
  "Status"                 VARCHAR(20) NOT NULL CONSTRAINT "DF_ar_RecDoc_Status" DEFAULT 'PENDING',
  "Notes"                  VARCHAR(500) NULL,
  "CreatedAt"              TIMESTAMP NOT NULL CONSTRAINT "DF_ar_RecDoc_CreatedAt" DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"              TIMESTAMP NOT NULL CONSTRAINT "DF_ar_RecDoc_UpdatedAt" DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId"        INT NULL,
  "UpdatedByUserId"        INT NULL,
  "RowVer"                 INT NOT NULL DEFAULT 1,
  CONSTRAINT "CK_ar_RecDoc_Status" CHECK ("Status" IN ('PENDING','PARTIAL','PAID','VOIDED')),
  CONSTRAINT "UQ_ar_RecDoc" UNIQUE ("CompanyId", "BranchId", "DocumentType", "DocumentNumber"),
  CONSTRAINT "FK_ar_RecDoc_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId"),
  CONSTRAINT "FK_ar_RecDoc_Branch" FOREIGN KEY ("BranchId") REFERENCES cfg."Branch"("BranchId"),
  CONSTRAINT "FK_ar_RecDoc_Customer" FOREIGN KEY ("CustomerId") REFERENCES master."Customer"("CustomerId"),
  CONSTRAINT "FK_ar_RecDoc_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_ar_RecDoc_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId")
);

-- ---------------------------------------------------------
-- ar."ReceivableApplication"
-- ---------------------------------------------------------
CREATE TABLE IF NOT EXISTS ar."ReceivableApplication" (
  "ReceivableApplicationId" BIGINT GENERATED ALWAYS AS IDENTITY NOT NULL PRIMARY KEY,
  "ReceivableDocumentId"    BIGINT NOT NULL,
  "ApplyDate"               DATE NOT NULL,
  "AppliedAmount"           NUMERIC(18,2) NOT NULL,
  "PaymentReference"        VARCHAR(120) NULL,
  "CreatedAt"               TIMESTAMP NOT NULL CONSTRAINT "DF_ar_RecApp_CreatedAt" DEFAULT (NOW() AT TIME ZONE 'UTC'),
  CONSTRAINT "FK_ar_RecApp_Doc" FOREIGN KEY ("ReceivableDocumentId") REFERENCES ar."ReceivableDocument"("ReceivableDocumentId")
);

-- =========================================================
-- SCHEMA ap  (Accounts Payable)
-- =========================================================

-- ---------------------------------------------------------
-- ap."PayableDocument"
-- ---------------------------------------------------------
CREATE TABLE IF NOT EXISTS ap."PayableDocument" (
  "PayableDocumentId"      BIGINT GENERATED ALWAYS AS IDENTITY NOT NULL PRIMARY KEY,
  "CompanyId"              INT NOT NULL,
  "BranchId"               INT NOT NULL,
  "SupplierId"             BIGINT NOT NULL,
  "DocumentType"           VARCHAR(20) NOT NULL,
  "DocumentNumber"         VARCHAR(120) NOT NULL,
  "IssueDate"              DATE NOT NULL,
  "DueDate"                DATE NULL,
  "CurrencyCode"           CHAR(3) NOT NULL,
  "TotalAmount"            NUMERIC(18,2) NOT NULL,
  "PendingAmount"          NUMERIC(18,2) NOT NULL,
  "PaidFlag"               BOOLEAN NOT NULL CONSTRAINT "DF_ap_PayDoc_PaidFlag" DEFAULT FALSE,
  "Status"                 VARCHAR(20) NOT NULL CONSTRAINT "DF_ap_PayDoc_Status" DEFAULT 'PENDING',
  "Notes"                  VARCHAR(500) NULL,
  "CreatedAt"              TIMESTAMP NOT NULL CONSTRAINT "DF_ap_PayDoc_CreatedAt" DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"              TIMESTAMP NOT NULL CONSTRAINT "DF_ap_PayDoc_UpdatedAt" DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId"        INT NULL,
  "UpdatedByUserId"        INT NULL,
  "RowVer"                 INT NOT NULL DEFAULT 1,
  CONSTRAINT "CK_ap_PayDoc_Status" CHECK ("Status" IN ('PENDING','PARTIAL','PAID','VOIDED')),
  CONSTRAINT "UQ_ap_PayDoc" UNIQUE ("CompanyId", "BranchId", "DocumentType", "DocumentNumber"),
  CONSTRAINT "FK_ap_PayDoc_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId"),
  CONSTRAINT "FK_ap_PayDoc_Branch" FOREIGN KEY ("BranchId") REFERENCES cfg."Branch"("BranchId"),
  CONSTRAINT "FK_ap_PayDoc_Supplier" FOREIGN KEY ("SupplierId") REFERENCES master."Supplier"("SupplierId"),
  CONSTRAINT "FK_ap_PayDoc_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_ap_PayDoc_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId")
);

-- ---------------------------------------------------------
-- ap."PayableApplication"
-- ---------------------------------------------------------
CREATE TABLE IF NOT EXISTS ap."PayableApplication" (
  "PayableApplicationId"   BIGINT GENERATED ALWAYS AS IDENTITY NOT NULL PRIMARY KEY,
  "PayableDocumentId"      BIGINT NOT NULL,
  "ApplyDate"              DATE NOT NULL,
  "AppliedAmount"          NUMERIC(18,2) NOT NULL,
  "PaymentReference"       VARCHAR(120) NULL,
  "CreatedAt"              TIMESTAMP NOT NULL CONSTRAINT "DF_ap_PayApp_CreatedAt" DEFAULT (NOW() AT TIME ZONE 'UTC'),
  CONSTRAINT "FK_ap_PayApp_Doc" FOREIGN KEY ("PayableDocumentId") REFERENCES ap."PayableDocument"("PayableDocumentId")
);

-- =========================================================
-- SCHEMA fiscal
-- =========================================================

-- ---------------------------------------------------------
-- fiscal."CountryConfig"
-- ---------------------------------------------------------
CREATE TABLE IF NOT EXISTS fiscal."CountryConfig" (
  "CountryConfigId"         BIGINT GENERATED ALWAYS AS IDENTITY NOT NULL PRIMARY KEY,
  "CompanyId"               INT NOT NULL,
  "BranchId"                INT NOT NULL,
  "CountryCode"             CHAR(2) NOT NULL,
  "Currency"                CHAR(3) NOT NULL,
  "TaxRegime"               VARCHAR(50) NULL,
  "DefaultTaxCode"          VARCHAR(30) NULL,
  "DefaultTaxRate"          NUMERIC(9,4) NOT NULL,
  "FiscalPrinterEnabled"    BOOLEAN NOT NULL CONSTRAINT "DF_fiscal_CountryCfg_Printer" DEFAULT FALSE,
  "PrinterBrand"            VARCHAR(30) NULL,
  "PrinterPort"             VARCHAR(20) NULL,
  "VerifactuEnabled"        BOOLEAN NOT NULL CONSTRAINT "DF_fiscal_CountryCfg_Verifactu" DEFAULT FALSE,
  "VerifactuMode"           VARCHAR(10) NULL,
  "CertificatePath"         VARCHAR(500) NULL,
  "CertificatePassword"     VARCHAR(255) NULL,
  "AEATEndpoint"            VARCHAR(500) NULL,
  "SenderNIF"               VARCHAR(20) NULL,
  "SenderRIF"               VARCHAR(20) NULL,
  "SoftwareId"              VARCHAR(100) NULL,
  "SoftwareName"            VARCHAR(200) NULL,
  "SoftwareVersion"         VARCHAR(20) NULL,
  "PosEnabled"              BOOLEAN NOT NULL CONSTRAINT "DF_fiscal_CountryCfg_PosEnabled" DEFAULT TRUE,
  "RestaurantEnabled"       BOOLEAN NOT NULL CONSTRAINT "DF_fiscal_CountryCfg_RestEnabled" DEFAULT TRUE,
  "IsActive"                BOOLEAN NOT NULL CONSTRAINT "DF_fiscal_CountryCfg_IsActive" DEFAULT TRUE,
  "CreatedAt"               TIMESTAMP NOT NULL CONSTRAINT "DF_fiscal_CountryCfg_CreatedAt" DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"               TIMESTAMP NOT NULL CONSTRAINT "DF_fiscal_CountryCfg_UpdatedAt" DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId"         INT NULL,
  "UpdatedByUserId"         INT NULL,
  "RowVer"                  INT NOT NULL DEFAULT 1,
  CONSTRAINT "CK_fiscal_CountryCfg_VerifactuMode" CHECK ("VerifactuMode" IN ('auto','manual') OR "VerifactuMode" IS NULL),
  CONSTRAINT "UQ_fiscal_CountryCfg" UNIQUE ("CompanyId", "BranchId", "CountryCode"),
  CONSTRAINT "FK_fiscal_CountryCfg_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId"),
  CONSTRAINT "FK_fiscal_CountryCfg_Branch" FOREIGN KEY ("BranchId") REFERENCES cfg."Branch"("BranchId"),
  CONSTRAINT "FK_fiscal_CountryCfg_Country" FOREIGN KEY ("CountryCode") REFERENCES cfg."Country"("CountryCode"),
  CONSTRAINT "FK_fiscal_CountryCfg_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_fiscal_CountryCfg_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId")
);

-- ---------------------------------------------------------
-- fiscal."TaxRate"
-- ---------------------------------------------------------
CREATE TABLE IF NOT EXISTS fiscal."TaxRate" (
  "TaxRateId"               BIGINT GENERATED ALWAYS AS IDENTITY NOT NULL PRIMARY KEY,
  "CountryCode"             CHAR(2) NOT NULL,
  "TaxCode"                 VARCHAR(30) NOT NULL,
  "TaxName"                 VARCHAR(120) NOT NULL,
  "Rate"                    NUMERIC(9,4) NOT NULL,
  "SurchargeRate"           NUMERIC(9,4) NULL,
  "AppliesToPOS"            BOOLEAN NOT NULL CONSTRAINT "DF_fiscal_TaxRate_AppliesToPOS" DEFAULT TRUE,
  "AppliesToRestaurant"     BOOLEAN NOT NULL CONSTRAINT "DF_fiscal_TaxRate_AppliesToRest" DEFAULT TRUE,
  "IsDefault"               BOOLEAN NOT NULL CONSTRAINT "DF_fiscal_TaxRate_IsDefault" DEFAULT FALSE,
  "IsActive"                BOOLEAN NOT NULL CONSTRAINT "DF_fiscal_TaxRate_IsActive" DEFAULT TRUE,
  "SortOrder"               INT NOT NULL CONSTRAINT "DF_fiscal_TaxRate_Sort" DEFAULT 0,
  "CreatedAt"               TIMESTAMP NOT NULL CONSTRAINT "DF_fiscal_TaxRate_CreatedAt" DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"               TIMESTAMP NOT NULL CONSTRAINT "DF_fiscal_TaxRate_UpdatedAt" DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId"         INT NULL,
  "UpdatedByUserId"         INT NULL,
  "RowVer"                  INT NOT NULL DEFAULT 1,
  CONSTRAINT "CK_fiscal_TaxRate_Rate" CHECK ("Rate" >= 0 AND "Rate" <= 1),
  CONSTRAINT "CK_fiscal_TaxRate_Surcharge" CHECK ("SurchargeRate" IS NULL OR ("SurchargeRate" >= 0 AND "SurchargeRate" <= 1)),
  CONSTRAINT "UQ_fiscal_TaxRate" UNIQUE ("CountryCode", "TaxCode"),
  CONSTRAINT "FK_fiscal_TaxRate_Country" FOREIGN KEY ("CountryCode") REFERENCES cfg."Country"("CountryCode"),
  CONSTRAINT "FK_fiscal_TaxRate_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_fiscal_TaxRate_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId")
);

-- ---------------------------------------------------------
-- fiscal."InvoiceType"
-- ---------------------------------------------------------
CREATE TABLE IF NOT EXISTS fiscal."InvoiceType" (
  "InvoiceTypeId"           BIGINT GENERATED ALWAYS AS IDENTITY NOT NULL PRIMARY KEY,
  "CountryCode"             CHAR(2) NOT NULL,
  "InvoiceTypeCode"         VARCHAR(20) NOT NULL,
  "InvoiceTypeName"         VARCHAR(120) NOT NULL,
  "IsRectificative"         BOOLEAN NOT NULL CONSTRAINT "DF_fiscal_InvType_Rect" DEFAULT FALSE,
  "RequiresRecipientId"     BOOLEAN NOT NULL CONSTRAINT "DF_fiscal_InvType_ReqRcpt" DEFAULT FALSE,
  "MaxAmount"               NUMERIC(18,2) NULL,
  "RequiresFiscalPrinter"   BOOLEAN NOT NULL CONSTRAINT "DF_fiscal_InvType_ReqPrinter" DEFAULT FALSE,
  "IsActive"                BOOLEAN NOT NULL CONSTRAINT "DF_fiscal_InvType_IsActive" DEFAULT TRUE,
  "SortOrder"               INT NOT NULL CONSTRAINT "DF_fiscal_InvType_Sort" DEFAULT 0,
  "CreatedAt"               TIMESTAMP NOT NULL CONSTRAINT "DF_fiscal_InvType_CreatedAt" DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"               TIMESTAMP NOT NULL CONSTRAINT "DF_fiscal_InvType_UpdatedAt" DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId"         INT NULL,
  "UpdatedByUserId"         INT NULL,
  "RowVer"                  INT NOT NULL DEFAULT 1,
  CONSTRAINT "UQ_fiscal_InvType" UNIQUE ("CountryCode", "InvoiceTypeCode"),
  CONSTRAINT "FK_fiscal_InvType_Country" FOREIGN KEY ("CountryCode") REFERENCES cfg."Country"("CountryCode"),
  CONSTRAINT "FK_fiscal_InvType_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_fiscal_InvType_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId")
);

-- ---------------------------------------------------------
-- fiscal."Record"
-- ---------------------------------------------------------
CREATE TABLE IF NOT EXISTS fiscal."Record" (
  "FiscalRecordId"          BIGINT GENERATED ALWAYS AS IDENTITY NOT NULL PRIMARY KEY,
  "CompanyId"               INT NOT NULL,
  "BranchId"                INT NOT NULL,
  "CountryCode"             CHAR(2) NOT NULL,
  "InvoiceId"               INT NOT NULL,
  "InvoiceType"             VARCHAR(20) NOT NULL,
  "InvoiceNumber"           VARCHAR(50) NOT NULL,
  "InvoiceDate"             DATE NOT NULL,
  "RecipientId"             VARCHAR(20) NULL,
  "TotalAmount"             NUMERIC(18,2) NOT NULL,
  "RecordHash"              VARCHAR(64) NOT NULL,
  "PreviousRecordHash"      VARCHAR(64) NULL,
  "XmlContent"              TEXT NULL,
  "DigitalSignature"        TEXT NULL,
  "QRCodeData"              VARCHAR(800) NULL,
  "SentToAuthority"         BOOLEAN NOT NULL CONSTRAINT "DF_fiscal_Record_Sent" DEFAULT FALSE,
  "SentAt"                  TIMESTAMP NULL,
  "AuthorityResponse"       TEXT NULL,
  "AuthorityStatus"         VARCHAR(20) NULL,
  "FiscalPrinterSerial"     VARCHAR(30) NULL,
  "FiscalControlNumber"     VARCHAR(30) NULL,
  "ZReportNumber"           INT NULL,
  "CreatedAt"               TIMESTAMP NOT NULL CONSTRAINT "DF_fiscal_Record_CreatedAt" DEFAULT (NOW() AT TIME ZONE 'UTC'),
  CONSTRAINT "UQ_fiscal_Record_Hash" UNIQUE ("RecordHash"),
  CONSTRAINT "FK_fiscal_Record_CountryCfg" FOREIGN KEY ("CompanyId", "BranchId", "CountryCode") REFERENCES fiscal."CountryConfig"("CompanyId", "BranchId", "CountryCode"),
  CONSTRAINT "FK_fiscal_Record_PrevHash" FOREIGN KEY ("PreviousRecordHash") REFERENCES fiscal."Record"("RecordHash")
);

CREATE INDEX IF NOT EXISTS "IX_fiscal_Record_Search"
  ON fiscal."Record" ("CompanyId", "BranchId", "CountryCode", "FiscalRecordId" DESC);

-- =========================================================
-- SCHEMA pos  (Point of Sale)
-- =========================================================

-- ---------------------------------------------------------
-- pos."WaitTicket"
-- ---------------------------------------------------------
CREATE TABLE IF NOT EXISTS pos."WaitTicket" (
  "WaitTicketId"            BIGINT GENERATED ALWAYS AS IDENTITY NOT NULL PRIMARY KEY,
  "CompanyId"               INT NOT NULL,
  "BranchId"                INT NOT NULL,
  "CountryCode"             CHAR(2) NOT NULL,
  "CashRegisterCode"        VARCHAR(10) NOT NULL,
  "StationName"             VARCHAR(50) NULL,
  "CreatedByUserId"         INT NULL,
  "CustomerId"              BIGINT NULL,
  "CustomerCode"            VARCHAR(24) NULL,
  "CustomerName"            VARCHAR(200) NULL,
  "CustomerFiscalId"        VARCHAR(30) NULL,
  "PriceTier"               VARCHAR(20) NOT NULL CONSTRAINT "DF_pos_WaitTicket_PriceTier" DEFAULT 'DETAIL',
  "Reason"                  VARCHAR(200) NULL,
  "NetAmount"               NUMERIC(18,2) NOT NULL CONSTRAINT "DF_pos_WaitTicket_Net" DEFAULT 0,
  "DiscountAmount"          NUMERIC(18,2) NOT NULL CONSTRAINT "DF_pos_WaitTicket_Discount" DEFAULT 0,
  "TaxAmount"               NUMERIC(18,2) NOT NULL CONSTRAINT "DF_pos_WaitTicket_Tax" DEFAULT 0,
  "TotalAmount"             NUMERIC(18,2) NOT NULL CONSTRAINT "DF_pos_WaitTicket_Total" DEFAULT 0,
  "Status"                  VARCHAR(20) NOT NULL CONSTRAINT "DF_pos_WaitTicket_Status" DEFAULT 'WAITING',
  "RecoveredByUserId"       INT NULL,
  "RecoveredAtRegister"     VARCHAR(10) NULL,
  "RecoveredAt"             TIMESTAMP NULL,
  "CreatedAt"               TIMESTAMP NOT NULL CONSTRAINT "DF_pos_WaitTicket_CreatedAt" DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"               TIMESTAMP NOT NULL CONSTRAINT "DF_pos_WaitTicket_UpdatedAt" DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "RowVer"                  INT NOT NULL DEFAULT 1,
  CONSTRAINT "CK_pos_WaitTicket_Status" CHECK ("Status" IN ('WAITING','RECOVERED','VOIDED')),
  CONSTRAINT "FK_pos_WaitTicket_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId"),
  CONSTRAINT "FK_pos_WaitTicket_Branch" FOREIGN KEY ("BranchId") REFERENCES cfg."Branch"("BranchId"),
  CONSTRAINT "FK_pos_WaitTicket_Country" FOREIGN KEY ("CountryCode") REFERENCES cfg."Country"("CountryCode"),
  CONSTRAINT "FK_pos_WaitTicket_Customer" FOREIGN KEY ("CustomerId") REFERENCES master."Customer"("CustomerId"),
  CONSTRAINT "FK_pos_WaitTicket_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_pos_WaitTicket_RecoveredBy" FOREIGN KEY ("RecoveredByUserId") REFERENCES sec."User"("UserId")
);

-- ---------------------------------------------------------
-- pos."WaitTicketLine"
-- ---------------------------------------------------------
CREATE TABLE IF NOT EXISTS pos."WaitTicketLine" (
  "WaitTicketLineId"        BIGINT GENERATED ALWAYS AS IDENTITY NOT NULL PRIMARY KEY,
  "WaitTicketId"            BIGINT NOT NULL,
  "LineNumber"              INT NOT NULL,
  "CountryCode"             CHAR(2) NOT NULL,
  "ProductId"               BIGINT NULL,
  "ProductCode"             VARCHAR(80) NOT NULL,
  "ProductName"             VARCHAR(250) NOT NULL,
  "Quantity"                NUMERIC(10,3) NOT NULL,
  "UnitPrice"               NUMERIC(18,2) NOT NULL,
  "DiscountAmount"          NUMERIC(18,2) NOT NULL CONSTRAINT "DF_pos_WaitTicketLine_Discount" DEFAULT 0,
  "TaxCode"                 VARCHAR(30) NOT NULL,
  "TaxRate"                 NUMERIC(9,4) NOT NULL,
  "NetAmount"               NUMERIC(18,2) NOT NULL,
  "TaxAmount"               NUMERIC(18,2) NOT NULL,
  "TotalAmount"             NUMERIC(18,2) NOT NULL,
  "CreatedAt"               TIMESTAMP NOT NULL CONSTRAINT "DF_pos_WaitTicketLine_CreatedAt" DEFAULT (NOW() AT TIME ZONE 'UTC'),
  CONSTRAINT "UQ_pos_WaitTicketLine" UNIQUE ("WaitTicketId", "LineNumber"),
  CONSTRAINT "FK_pos_WaitTicketLine_WaitTicket" FOREIGN KEY ("WaitTicketId") REFERENCES pos."WaitTicket"("WaitTicketId") ON DELETE CASCADE,
  CONSTRAINT "FK_pos_WaitTicketLine_Product" FOREIGN KEY ("ProductId") REFERENCES master."Product"("ProductId"),
  CONSTRAINT "FK_pos_WaitTicketLine_Tax" FOREIGN KEY ("CountryCode", "TaxCode") REFERENCES fiscal."TaxRate"("CountryCode", "TaxCode")
);

-- ---------------------------------------------------------
-- pos."SaleTicket"
-- ---------------------------------------------------------
CREATE TABLE IF NOT EXISTS pos."SaleTicket" (
  "SaleTicketId"            BIGINT GENERATED ALWAYS AS IDENTITY NOT NULL PRIMARY KEY,
  "CompanyId"               INT NOT NULL,
  "BranchId"                INT NOT NULL,
  "CountryCode"             CHAR(2) NOT NULL,
  "InvoiceNumber"           VARCHAR(20) NOT NULL,
  "CashRegisterCode"        VARCHAR(10) NOT NULL,
  "SoldByUserId"            INT NULL,
  "CustomerId"              BIGINT NULL,
  "CustomerCode"            VARCHAR(24) NULL,
  "CustomerName"            VARCHAR(200) NULL,
  "CustomerFiscalId"        VARCHAR(30) NULL,
  "PriceTier"               VARCHAR(20) NOT NULL CONSTRAINT "DF_pos_SaleTicket_PriceTier" DEFAULT 'DETAIL',
  "PaymentMethod"           VARCHAR(50) NULL,
  "FiscalPayload"           TEXT NULL,
  "WaitTicketId"            BIGINT NULL,
  "NetAmount"               NUMERIC(18,2) NOT NULL CONSTRAINT "DF_pos_SaleTicket_Net" DEFAULT 0,
  "DiscountAmount"          NUMERIC(18,2) NOT NULL CONSTRAINT "DF_pos_SaleTicket_Discount" DEFAULT 0,
  "TaxAmount"               NUMERIC(18,2) NOT NULL CONSTRAINT "DF_pos_SaleTicket_Tax" DEFAULT 0,
  "TotalAmount"             NUMERIC(18,2) NOT NULL CONSTRAINT "DF_pos_SaleTicket_Total" DEFAULT 0,
  "SoldAt"                  TIMESTAMP NOT NULL CONSTRAINT "DF_pos_SaleTicket_SoldAt" DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "RowVer"                  INT NOT NULL DEFAULT 1,
  CONSTRAINT "UQ_pos_SaleTicket" UNIQUE ("CompanyId", "BranchId", "InvoiceNumber"),
  CONSTRAINT "FK_pos_SaleTicket_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId"),
  CONSTRAINT "FK_pos_SaleTicket_Branch" FOREIGN KEY ("BranchId") REFERENCES cfg."Branch"("BranchId"),
  CONSTRAINT "FK_pos_SaleTicket_Country" FOREIGN KEY ("CountryCode") REFERENCES cfg."Country"("CountryCode"),
  CONSTRAINT "FK_pos_SaleTicket_Customer" FOREIGN KEY ("CustomerId") REFERENCES master."Customer"("CustomerId"),
  CONSTRAINT "FK_pos_SaleTicket_WaitTicket" FOREIGN KEY ("WaitTicketId") REFERENCES pos."WaitTicket"("WaitTicketId"),
  CONSTRAINT "FK_pos_SaleTicket_SoldBy" FOREIGN KEY ("SoldByUserId") REFERENCES sec."User"("UserId")
);

-- ---------------------------------------------------------
-- pos."SaleTicketLine"
-- ---------------------------------------------------------
CREATE TABLE IF NOT EXISTS pos."SaleTicketLine" (
  "SaleTicketLineId"        BIGINT GENERATED ALWAYS AS IDENTITY NOT NULL PRIMARY KEY,
  "SaleTicketId"            BIGINT NOT NULL,
  "LineNumber"              INT NOT NULL,
  "CountryCode"             CHAR(2) NOT NULL,
  "ProductId"               BIGINT NULL,
  "ProductCode"             VARCHAR(80) NOT NULL,
  "ProductName"             VARCHAR(250) NOT NULL,
  "Quantity"                NUMERIC(10,3) NOT NULL,
  "UnitPrice"               NUMERIC(18,2) NOT NULL,
  "DiscountAmount"          NUMERIC(18,2) NOT NULL CONSTRAINT "DF_pos_SaleTicketLine_Discount" DEFAULT 0,
  "TaxCode"                 VARCHAR(30) NOT NULL,
  "TaxRate"                 NUMERIC(9,4) NOT NULL,
  "NetAmount"               NUMERIC(18,2) NOT NULL,
  "TaxAmount"               NUMERIC(18,2) NOT NULL,
  "TotalAmount"             NUMERIC(18,2) NOT NULL,
  CONSTRAINT "UQ_pos_SaleTicketLine" UNIQUE ("SaleTicketId", "LineNumber"),
  CONSTRAINT "FK_pos_SaleTicketLine_SaleTicket" FOREIGN KEY ("SaleTicketId") REFERENCES pos."SaleTicket"("SaleTicketId") ON DELETE CASCADE,
  CONSTRAINT "FK_pos_SaleTicketLine_Product" FOREIGN KEY ("ProductId") REFERENCES master."Product"("ProductId"),
  CONSTRAINT "FK_pos_SaleTicketLine_Tax" FOREIGN KEY ("CountryCode", "TaxCode") REFERENCES fiscal."TaxRate"("CountryCode", "TaxCode")
);

-- =========================================================
-- SCHEMA rest  (Restaurant)
-- =========================================================

-- ---------------------------------------------------------
-- rest."OrderTicket"
-- ---------------------------------------------------------
CREATE TABLE IF NOT EXISTS rest."OrderTicket" (
  "OrderTicketId"           BIGINT GENERATED ALWAYS AS IDENTITY NOT NULL PRIMARY KEY,
  "CompanyId"               INT NOT NULL,
  "BranchId"                INT NOT NULL,
  "CountryCode"             CHAR(2) NOT NULL,
  "TableNumber"             VARCHAR(20) NULL,
  "OpenedByUserId"          INT NULL,
  "ClosedByUserId"          INT NULL,
  "CustomerName"            VARCHAR(200) NULL,
  "CustomerFiscalId"        VARCHAR(30) NULL,
  "Status"                  VARCHAR(20) NOT NULL CONSTRAINT "DF_rest_OrderTicket_Status" DEFAULT 'OPEN',
  "NetAmount"               NUMERIC(18,2) NOT NULL CONSTRAINT "DF_rest_OrderTicket_Net" DEFAULT 0,
  "TaxAmount"               NUMERIC(18,2) NOT NULL CONSTRAINT "DF_rest_OrderTicket_Tax" DEFAULT 0,
  "TotalAmount"             NUMERIC(18,2) NOT NULL CONSTRAINT "DF_rest_OrderTicket_Total" DEFAULT 0,
  "OpenedAt"                TIMESTAMP NOT NULL CONSTRAINT "DF_rest_OrderTicket_OpenedAt" DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "ClosedAt"                TIMESTAMP NULL,
  "UpdatedAt"               TIMESTAMP NOT NULL CONSTRAINT "DF_rest_OrderTicket_UpdatedAt" DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "RowVer"                  INT NOT NULL DEFAULT 1,
  CONSTRAINT "CK_rest_OrderTicket_Status" CHECK ("Status" IN ('OPEN','SENT','CLOSED','VOIDED')),
  CONSTRAINT "FK_rest_OrderTicket_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId"),
  CONSTRAINT "FK_rest_OrderTicket_Branch" FOREIGN KEY ("BranchId") REFERENCES cfg."Branch"("BranchId"),
  CONSTRAINT "FK_rest_OrderTicket_Country" FOREIGN KEY ("CountryCode") REFERENCES cfg."Country"("CountryCode"),
  CONSTRAINT "FK_rest_OrderTicket_OpenedBy" FOREIGN KEY ("OpenedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_rest_OrderTicket_ClosedBy" FOREIGN KEY ("ClosedByUserId") REFERENCES sec."User"("UserId")
);

-- ---------------------------------------------------------
-- rest."OrderTicketLine"
-- ---------------------------------------------------------
CREATE TABLE IF NOT EXISTS rest."OrderTicketLine" (
  "OrderTicketLineId"       BIGINT GENERATED ALWAYS AS IDENTITY NOT NULL PRIMARY KEY,
  "OrderTicketId"           BIGINT NOT NULL,
  "LineNumber"              INT NOT NULL,
  "CountryCode"             CHAR(2) NOT NULL,
  "ProductId"               BIGINT NULL,
  "ProductCode"             VARCHAR(80) NOT NULL,
  "ProductName"             VARCHAR(250) NOT NULL,
  "Quantity"                NUMERIC(10,3) NOT NULL,
  "UnitPrice"               NUMERIC(18,2) NOT NULL,
  "TaxCode"                 VARCHAR(30) NOT NULL,
  "TaxRate"                 NUMERIC(9,4) NOT NULL,
  "NetAmount"               NUMERIC(18,2) NOT NULL,
  "TaxAmount"               NUMERIC(18,2) NOT NULL,
  "TotalAmount"             NUMERIC(18,2) NOT NULL,
  "Notes"                   VARCHAR(300) NULL,
  "CreatedAt"               TIMESTAMP NOT NULL CONSTRAINT "DF_rest_OrderTicketLine_CreatedAt" DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"               TIMESTAMP NOT NULL CONSTRAINT "DF_rest_OrderTicketLine_UpdatedAt" DEFAULT (NOW() AT TIME ZONE 'UTC'),
  CONSTRAINT "UQ_rest_OrderTicketLine" UNIQUE ("OrderTicketId", "LineNumber"),
  CONSTRAINT "FK_rest_OrderTicketLine_Order" FOREIGN KEY ("OrderTicketId") REFERENCES rest."OrderTicket"("OrderTicketId") ON DELETE CASCADE,
  CONSTRAINT "FK_rest_OrderTicketLine_Product" FOREIGN KEY ("ProductId") REFERENCES master."Product"("ProductId"),
  CONSTRAINT "FK_rest_OrderTicketLine_Tax" FOREIGN KEY ("CountryCode", "TaxCode") REFERENCES fiscal."TaxRate"("CountryCode", "TaxCode")
);

COMMIT;
