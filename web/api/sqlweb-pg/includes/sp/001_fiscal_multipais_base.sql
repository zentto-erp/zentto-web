-- ============================================
-- Script: 001_fiscal_multipais_base.sql - PostgreSQL
-- Scope : Multi-country fiscal base for Venezuela + Espana (Verifactu)
-- Notes : Non-destructive and idempotent.
-- Traducido de SQL Server a PostgreSQL
-- ============================================

-- FiscalCountryConfig
CREATE TABLE IF NOT EXISTS "FiscalCountryConfig" (
    "Id"                    SERIAL PRIMARY KEY,
    "EmpresaId"             INT NOT NULL,
    "SucursalId"            INT NOT NULL DEFAULT 0,
    "CountryCode"           CHAR(2) NOT NULL,
    "Currency"              VARCHAR(3) NOT NULL,
    "TaxRegime"             VARCHAR(50),
    "DefaultTaxCode"        VARCHAR(30),
    "DefaultTaxRate"        NUMERIC(5,4) NOT NULL,
    "FiscalPrinterEnabled"  BOOLEAN NOT NULL DEFAULT FALSE,
    "PrinterBrand"          VARCHAR(30),
    "PrinterPort"           VARCHAR(20),
    "SenderRIF"             VARCHAR(20),
    "VerifactuEnabled"      BOOLEAN NOT NULL DEFAULT FALSE,
    "VerifactuMode"         VARCHAR(10),
    "SenderNIF"             VARCHAR(20),
    "CertificatePath"       VARCHAR(500),
    "CertificatePassword"   VARCHAR(500),
    "AEATEndpoint"          VARCHAR(500),
    "SoftwareId"            VARCHAR(100),
    "SoftwareName"          VARCHAR(200),
    "SoftwareVersion"       VARCHAR(20),
    "PosEnabled"            BOOLEAN NOT NULL DEFAULT TRUE,
    "RestaurantEnabled"     BOOLEAN NOT NULL DEFAULT TRUE,
    "IsActive"              BOOLEAN NOT NULL DEFAULT TRUE,
    "CreatedAt"             TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "UpdatedAt"             TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC')
);

CREATE UNIQUE INDEX IF NOT EXISTS "UQ_FiscalCountryConfig_Context"
    ON "FiscalCountryConfig" ("EmpresaId", "SucursalId", "CountryCode");

-- FiscalTaxRates
CREATE TABLE IF NOT EXISTS "FiscalTaxRates" (
    "Id"                    SERIAL PRIMARY KEY,
    "CountryCode"           CHAR(2) NOT NULL,
    "Code"                  VARCHAR(30) NOT NULL,
    "Name"                  VARCHAR(100) NOT NULL,
    "Rate"                  NUMERIC(5,4) NOT NULL,
    "SurchargeRate"         NUMERIC(5,4),
    "AppliesToPOS"          BOOLEAN NOT NULL DEFAULT TRUE,
    "AppliesToRestaurant"   BOOLEAN NOT NULL DEFAULT TRUE,
    "IsDefault"             BOOLEAN NOT NULL DEFAULT FALSE,
    "IsActive"              BOOLEAN NOT NULL DEFAULT TRUE,
    "SortOrder"             INT NOT NULL DEFAULT 0,
    "CreatedAt"             TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC')
);

CREATE UNIQUE INDEX IF NOT EXISTS "UQ_FiscalTaxRates_Code"
    ON "FiscalTaxRates" ("CountryCode", "Code");

-- FiscalInvoiceTypes
CREATE TABLE IF NOT EXISTS "FiscalInvoiceTypes" (
    "Id"                      SERIAL PRIMARY KEY,
    "CountryCode"             CHAR(2) NOT NULL,
    "Code"                    VARCHAR(20) NOT NULL,
    "Name"                    VARCHAR(100) NOT NULL,
    "IsRectificative"         BOOLEAN NOT NULL DEFAULT FALSE,
    "RequiresRecipientId"     BOOLEAN NOT NULL DEFAULT FALSE,
    "MaxAmount"               NUMERIC(18,2),
    "RequiresFiscalPrinter"   BOOLEAN NOT NULL DEFAULT FALSE,
    "IsActive"                BOOLEAN NOT NULL DEFAULT TRUE,
    "SortOrder"               INT NOT NULL DEFAULT 0,
    "CreatedAt"               TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC')
);

CREATE UNIQUE INDEX IF NOT EXISTS "UQ_FiscalInvoiceTypes_Code"
    ON "FiscalInvoiceTypes" ("CountryCode", "Code");

-- FiscalRecords
CREATE TABLE IF NOT EXISTS "FiscalRecords" (
    "Id"                    BIGSERIAL PRIMARY KEY,
    "EmpresaId"             INT NOT NULL,
    "SucursalId"            INT NOT NULL DEFAULT 0,
    "CountryCode"           CHAR(2) NOT NULL,
    "InvoiceId"             INT NOT NULL,
    "InvoiceType"           VARCHAR(20) NOT NULL,
    "InvoiceNumber"         VARCHAR(50) NOT NULL,
    "InvoiceDate"           DATE NOT NULL,
    "RecipientId"           VARCHAR(20),
    "TotalAmount"           NUMERIC(18,2) NOT NULL,
    "RecordHash"            VARCHAR(64) NOT NULL,
    "PreviousRecordHash"    VARCHAR(64),
    "XmlContent"            TEXT,
    "DigitalSignature"      TEXT,
    "QRCodeData"            VARCHAR(500),
    "SentToAuthority"       BOOLEAN NOT NULL DEFAULT FALSE,
    "SentAt"                TIMESTAMP,
    "AuthorityResponse"     TEXT,
    "AuthorityStatus"       VARCHAR(20),
    "FiscalPrinterSerial"   VARCHAR(30),
    "FiscalControlNumber"   VARCHAR(30),
    "ZReportNumber"         INT,
    "CreatedAt"             TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC')
);

CREATE INDEX IF NOT EXISTS "IX_FiscalRecords_Chain"
    ON "FiscalRecords" ("EmpresaId", "SucursalId", "CountryCode", "Id");

-- ============================================
-- SEED: Tax rates VE
-- ============================================
INSERT INTO "FiscalTaxRates" ("CountryCode", "Code", "Name", "Rate", "AppliesToPOS", "AppliesToRestaurant", "IsDefault", "SortOrder")
VALUES ('VE', 'IVA_GENERAL', 'IVA General', 0.1600, TRUE, TRUE, TRUE, 10)
ON CONFLICT ("CountryCode", "Code") DO NOTHING;

INSERT INTO "FiscalTaxRates" ("CountryCode", "Code", "Name", "Rate", "AppliesToPOS", "AppliesToRestaurant", "IsDefault", "SortOrder")
VALUES ('VE', 'IVA_REDUCIDO', 'IVA Reducido', 0.0800, TRUE, TRUE, FALSE, 20)
ON CONFLICT ("CountryCode", "Code") DO NOTHING;

INSERT INTO "FiscalTaxRates" ("CountryCode", "Code", "Name", "Rate", "AppliesToPOS", "AppliesToRestaurant", "IsDefault", "SortOrder")
VALUES ('VE', 'IVA_ADICIONAL', 'IVA Adicional', 0.3100, TRUE, FALSE, FALSE, 30)
ON CONFLICT ("CountryCode", "Code") DO NOTHING;

INSERT INTO "FiscalTaxRates" ("CountryCode", "Code", "Name", "Rate", "AppliesToPOS", "AppliesToRestaurant", "IsDefault", "SortOrder")
VALUES ('VE', 'EXENTO', 'Exento', 0.0000, TRUE, TRUE, FALSE, 40)
ON CONFLICT ("CountryCode", "Code") DO NOTHING;

-- SEED: Tax rates ES
INSERT INTO "FiscalTaxRates" ("CountryCode", "Code", "Name", "Rate", "AppliesToPOS", "AppliesToRestaurant", "IsDefault", "SortOrder")
VALUES ('ES', 'IVA_GENERAL', 'IVA General', 0.2100, TRUE, FALSE, TRUE, 10)
ON CONFLICT ("CountryCode", "Code") DO NOTHING;

INSERT INTO "FiscalTaxRates" ("CountryCode", "Code", "Name", "Rate", "AppliesToPOS", "AppliesToRestaurant", "IsDefault", "SortOrder")
VALUES ('ES', 'IVA_REDUCIDO', 'IVA Reducido', 0.1000, TRUE, TRUE, FALSE, 20)
ON CONFLICT ("CountryCode", "Code") DO NOTHING;

INSERT INTO "FiscalTaxRates" ("CountryCode", "Code", "Name", "Rate", "AppliesToPOS", "AppliesToRestaurant", "IsDefault", "SortOrder")
VALUES ('ES', 'IVA_SUPERREDUCIDO', 'IVA Superreducido', 0.0400, TRUE, FALSE, FALSE, 30)
ON CONFLICT ("CountryCode", "Code") DO NOTHING;

INSERT INTO "FiscalTaxRates" ("CountryCode", "Code", "Name", "Rate", "AppliesToPOS", "AppliesToRestaurant", "IsDefault", "SortOrder")
VALUES ('ES', 'EXENTO', 'Exento', 0.0000, TRUE, TRUE, FALSE, 40)
ON CONFLICT ("CountryCode", "Code") DO NOTHING;

INSERT INTO "FiscalTaxRates" ("CountryCode", "Code", "Name", "Rate", "SurchargeRate", "AppliesToPOS", "AppliesToRestaurant", "IsDefault", "SortOrder")
VALUES ('ES', 'RE_GENERAL', 'Recargo Equivalencia General', 0.0520, 0.0520, TRUE, FALSE, FALSE, 50)
ON CONFLICT ("CountryCode", "Code") DO NOTHING;

INSERT INTO "FiscalTaxRates" ("CountryCode", "Code", "Name", "Rate", "SurchargeRate", "AppliesToPOS", "AppliesToRestaurant", "IsDefault", "SortOrder")
VALUES ('ES', 'RE_REDUCIDO', 'Recargo Equivalencia Reducido', 0.0140, 0.0140, TRUE, FALSE, FALSE, 60)
ON CONFLICT ("CountryCode", "Code") DO NOTHING;

INSERT INTO "FiscalTaxRates" ("CountryCode", "Code", "Name", "Rate", "SurchargeRate", "AppliesToPOS", "AppliesToRestaurant", "IsDefault", "SortOrder")
VALUES ('ES', 'RE_SUPERREDUCIDO', 'Recargo Equivalencia Superreducido', 0.0050, 0.0050, TRUE, FALSE, FALSE, 70)
ON CONFLICT ("CountryCode", "Code") DO NOTHING;

-- ============================================
-- SEED: Invoice types VE
-- ============================================
INSERT INTO "FiscalInvoiceTypes" ("CountryCode", "Code", "Name", "IsRectificative", "RequiresRecipientId", "MaxAmount", "RequiresFiscalPrinter", "SortOrder")
VALUES ('VE', 'FACTURA', 'Factura Fiscal', FALSE, TRUE, NULL, TRUE, 10)
ON CONFLICT ("CountryCode", "Code") DO NOTHING;

INSERT INTO "FiscalInvoiceTypes" ("CountryCode", "Code", "Name", "IsRectificative", "RequiresRecipientId", "MaxAmount", "RequiresFiscalPrinter", "SortOrder")
VALUES ('VE', 'NOTA_CREDITO', 'Nota de Credito Fiscal', TRUE, TRUE, NULL, TRUE, 20)
ON CONFLICT ("CountryCode", "Code") DO NOTHING;

INSERT INTO "FiscalInvoiceTypes" ("CountryCode", "Code", "Name", "IsRectificative", "RequiresRecipientId", "MaxAmount", "RequiresFiscalPrinter", "SortOrder")
VALUES ('VE', 'NOTA_DEBITO', 'Nota de Debito Fiscal', FALSE, TRUE, NULL, TRUE, 30)
ON CONFLICT ("CountryCode", "Code") DO NOTHING;

-- SEED: Invoice types ES
INSERT INTO "FiscalInvoiceTypes" ("CountryCode", "Code", "Name", "IsRectificative", "RequiresRecipientId", "MaxAmount", "RequiresFiscalPrinter", "SortOrder")
VALUES ('ES', 'F1', 'Factura Completa', FALSE, TRUE, NULL, FALSE, 10)
ON CONFLICT ("CountryCode", "Code") DO NOTHING;

INSERT INTO "FiscalInvoiceTypes" ("CountryCode", "Code", "Name", "IsRectificative", "RequiresRecipientId", "MaxAmount", "RequiresFiscalPrinter", "SortOrder")
VALUES ('ES', 'F2', 'Factura Simplificada', FALSE, FALSE, 3000.00, FALSE, 20)
ON CONFLICT ("CountryCode", "Code") DO NOTHING;

INSERT INTO "FiscalInvoiceTypes" ("CountryCode", "Code", "Name", "IsRectificative", "RequiresRecipientId", "MaxAmount", "RequiresFiscalPrinter", "SortOrder")
VALUES ('ES', 'F3', 'Factura Sustitucion Simplificada', FALSE, TRUE, NULL, FALSE, 30)
ON CONFLICT ("CountryCode", "Code") DO NOTHING;

INSERT INTO "FiscalInvoiceTypes" ("CountryCode", "Code", "Name", "IsRectificative", "RequiresRecipientId", "MaxAmount", "RequiresFiscalPrinter", "SortOrder")
VALUES ('ES', 'R1', 'Rectificativa R1', TRUE, TRUE, NULL, FALSE, 40)
ON CONFLICT ("CountryCode", "Code") DO NOTHING;

INSERT INTO "FiscalInvoiceTypes" ("CountryCode", "Code", "Name", "IsRectificative", "RequiresRecipientId", "MaxAmount", "RequiresFiscalPrinter", "SortOrder")
VALUES ('ES', 'R2', 'Rectificativa R2', TRUE, TRUE, NULL, FALSE, 50)
ON CONFLICT ("CountryCode", "Code") DO NOTHING;

INSERT INTO "FiscalInvoiceTypes" ("CountryCode", "Code", "Name", "IsRectificative", "RequiresRecipientId", "MaxAmount", "RequiresFiscalPrinter", "SortOrder")
VALUES ('ES', 'R3', 'Rectificativa R3', TRUE, TRUE, NULL, FALSE, 60)
ON CONFLICT ("CountryCode", "Code") DO NOTHING;

INSERT INTO "FiscalInvoiceTypes" ("CountryCode", "Code", "Name", "IsRectificative", "RequiresRecipientId", "MaxAmount", "RequiresFiscalPrinter", "SortOrder")
VALUES ('ES', 'R4', 'Rectificativa R4', TRUE, TRUE, NULL, FALSE, 70)
ON CONFLICT ("CountryCode", "Code") DO NOTHING;

INSERT INTO "FiscalInvoiceTypes" ("CountryCode", "Code", "Name", "IsRectificative", "RequiresRecipientId", "MaxAmount", "RequiresFiscalPrinter", "SortOrder")
VALUES ('ES', 'R5', 'Rectificativa R5', TRUE, FALSE, NULL, FALSE, 80)
ON CONFLICT ("CountryCode", "Code") DO NOTHING;
