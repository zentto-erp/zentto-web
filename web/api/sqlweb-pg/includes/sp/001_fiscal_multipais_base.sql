-- ============================================================
-- DatqBoxWeb PostgreSQL - 001_fiscal_multipais_base.sql
-- Base fiscal multi-pais para Venezuela + Espana (Verifactu).
-- No destructivo e idempotente.
-- ============================================================

CREATE SCHEMA IF NOT EXISTS fiscal;

-- FiscalCountryConfig
CREATE TABLE IF NOT EXISTS public."FiscalCountryConfig" (
    "Id"                   INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    "EmpresaId"            INT NOT NULL,
    "SucursalId"           INT NOT NULL DEFAULT 0,
    "CountryCode"          CHAR(2) NOT NULL,
    "Currency"             VARCHAR(3) NOT NULL,
    "TaxRegime"            VARCHAR(50) NULL,
    "DefaultTaxCode"       VARCHAR(30) NULL,
    "DefaultTaxRate"       NUMERIC(5,4) NOT NULL,
    "FiscalPrinterEnabled" BOOLEAN NOT NULL DEFAULT FALSE,
    "PrinterBrand"         VARCHAR(30) NULL,
    "PrinterPort"          VARCHAR(20) NULL,
    "SenderRIF"            VARCHAR(20) NULL,
    "VerifactuEnabled"     BOOLEAN NOT NULL DEFAULT FALSE,
    "VerifactuMode"        VARCHAR(10) NULL,
    "SenderNIF"            VARCHAR(20) NULL,
    "CertificatePath"      VARCHAR(500) NULL,
    "CertificatePassword"  VARCHAR(500) NULL,
    "AEATEndpoint"         VARCHAR(500) NULL,
    "SoftwareId"           VARCHAR(100) NULL,
    "SoftwareName"         VARCHAR(200) NULL,
    "SoftwareVersion"      VARCHAR(20) NULL,
    "PosEnabled"           BOOLEAN NOT NULL DEFAULT TRUE,
    "RestaurantEnabled"    BOOLEAN NOT NULL DEFAULT TRUE,
    "IsActive"             BOOLEAN NOT NULL DEFAULT TRUE,
    "CreatedAt"            TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "UpdatedAt"            TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC')
);

CREATE UNIQUE INDEX IF NOT EXISTS "UQ_FiscalCountryConfig_Context"
    ON public."FiscalCountryConfig" ("EmpresaId", "SucursalId", "CountryCode");

-- FiscalTaxRates
CREATE TABLE IF NOT EXISTS public."FiscalTaxRates" (
    "Id"                  INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    "CountryCode"         CHAR(2) NOT NULL,
    "Code"                VARCHAR(30) NOT NULL,
    "Name"                VARCHAR(100) NOT NULL,
    "Rate"                NUMERIC(5,4) NOT NULL,
    "SurchargeRate"       NUMERIC(5,4) NULL,
    "AppliesToPOS"        BOOLEAN NOT NULL DEFAULT TRUE,
    "AppliesToRestaurant" BOOLEAN NOT NULL DEFAULT TRUE,
    "IsDefault"           BOOLEAN NOT NULL DEFAULT FALSE,
    "IsActive"            BOOLEAN NOT NULL DEFAULT TRUE,
    "SortOrder"           INT NOT NULL DEFAULT 0,
    "CreatedAt"           TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC')
);

CREATE UNIQUE INDEX IF NOT EXISTS "UQ_FiscalTaxRates_Code"
    ON public."FiscalTaxRates" ("CountryCode", "Code");

-- FiscalInvoiceTypes
CREATE TABLE IF NOT EXISTS public."FiscalInvoiceTypes" (
    "Id"                    INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    "CountryCode"           CHAR(2) NOT NULL,
    "Code"                  VARCHAR(20) NOT NULL,
    "Name"                  VARCHAR(100) NOT NULL,
    "IsRectificative"       BOOLEAN NOT NULL DEFAULT FALSE,
    "RequiresRecipientId"   BOOLEAN NOT NULL DEFAULT FALSE,
    "MaxAmount"             NUMERIC(18,2) NULL,
    "RequiresFiscalPrinter" BOOLEAN NOT NULL DEFAULT FALSE,
    "IsActive"              BOOLEAN NOT NULL DEFAULT TRUE,
    "SortOrder"             INT NOT NULL DEFAULT 0,
    "CreatedAt"             TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC')
);

CREATE UNIQUE INDEX IF NOT EXISTS "UQ_FiscalInvoiceTypes_Code"
    ON public."FiscalInvoiceTypes" ("CountryCode", "Code");

-- FiscalRecords
CREATE TABLE IF NOT EXISTS public."FiscalRecords" (
    "Id"                  BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    "EmpresaId"           INT NOT NULL,
    "SucursalId"          INT NOT NULL DEFAULT 0,
    "CountryCode"         CHAR(2) NOT NULL,
    "InvoiceId"           INT NOT NULL,
    "InvoiceType"         VARCHAR(20) NOT NULL,
    "InvoiceNumber"       VARCHAR(50) NOT NULL,
    "InvoiceDate"         DATE NOT NULL,
    "RecipientId"         VARCHAR(20) NULL,
    "TotalAmount"         NUMERIC(18,2) NOT NULL,
    "RecordHash"          VARCHAR(64) NOT NULL,
    "PreviousRecordHash"  VARCHAR(64) NULL,
    "XmlContent"          JSONB NULL,
    "DigitalSignature"    TEXT NULL,
    "QRCodeData"          VARCHAR(500) NULL,
    "SentToAuthority"     BOOLEAN NOT NULL DEFAULT FALSE,
    "SentAt"              TIMESTAMP NULL,
    "AuthorityResponse"   JSONB NULL,
    "AuthorityStatus"     VARCHAR(20) NULL,
    "FiscalPrinterSerial" VARCHAR(30) NULL,
    "FiscalControlNumber" VARCHAR(30) NULL,
    "ZReportNumber"       INT NULL,
    "CreatedAt"           TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC')
);

CREATE INDEX IF NOT EXISTS "IX_FiscalRecords_Chain"
    ON public."FiscalRecords" ("EmpresaId", "SucursalId", "CountryCode", "Id");

-- Seed: Tax rates VE
INSERT INTO public."FiscalTaxRates" ("CountryCode", "Code", "Name", "Rate", "AppliesToPOS", "AppliesToRestaurant", "IsDefault", "SortOrder")
SELECT v.* FROM (VALUES
    ('VE', 'IVA_GENERAL',   'IVA General',   0.1600, TRUE, TRUE, TRUE,  10),
    ('VE', 'IVA_REDUCIDO',  'IVA Reducido',  0.0800, TRUE, TRUE, FALSE, 20),
    ('VE', 'IVA_ADICIONAL', 'IVA Adicional', 0.3100, TRUE, FALSE,FALSE, 30),
    ('VE', 'EXENTO',        'Exento',        0.0000, TRUE, TRUE, FALSE, 40)
) AS v("CountryCode", "Code", "Name", "Rate", "AppliesToPOS", "AppliesToRestaurant", "IsDefault", "SortOrder")
WHERE NOT EXISTS (SELECT 1 FROM public."FiscalTaxRates" WHERE "CountryCode" = v."CountryCode" AND "Code" = v."Code");

-- Seed: Tax rates ES
INSERT INTO public."FiscalTaxRates" ("CountryCode", "Code", "Name", "Rate", "AppliesToPOS", "AppliesToRestaurant", "IsDefault", "SortOrder")
SELECT v.* FROM (VALUES
    ('ES', 'IVA_GENERAL',        'IVA General',        0.2100, TRUE, FALSE, TRUE,  10),
    ('ES', 'IVA_REDUCIDO',       'IVA Reducido',       0.1000, TRUE, TRUE,  FALSE, 20),
    ('ES', 'IVA_SUPERREDUCIDO',  'IVA Superreducido',  0.0400, TRUE, FALSE, FALSE, 30),
    ('ES', 'EXENTO',             'Exento',             0.0000, TRUE, TRUE,  FALSE, 40)
) AS v("CountryCode", "Code", "Name", "Rate", "AppliesToPOS", "AppliesToRestaurant", "IsDefault", "SortOrder")
WHERE NOT EXISTS (SELECT 1 FROM public."FiscalTaxRates" WHERE "CountryCode" = v."CountryCode" AND "Code" = v."Code");

-- Seed: Recargo Equivalencia ES (con SurchargeRate)
INSERT INTO public."FiscalTaxRates" ("CountryCode", "Code", "Name", "Rate", "SurchargeRate", "AppliesToPOS", "AppliesToRestaurant", "IsDefault", "SortOrder")
SELECT v.* FROM (VALUES
    ('ES', 'RE_GENERAL',        'Recargo Equivalencia General',        0.0520, 0.0520, TRUE, FALSE, FALSE, 50),
    ('ES', 'RE_REDUCIDO',       'Recargo Equivalencia Reducido',       0.0140, 0.0140, TRUE, FALSE, FALSE, 60),
    ('ES', 'RE_SUPERREDUCIDO',  'Recargo Equivalencia Superreducido',  0.0050, 0.0050, TRUE, FALSE, FALSE, 70)
) AS v("CountryCode", "Code", "Name", "Rate", "SurchargeRate", "AppliesToPOS", "AppliesToRestaurant", "IsDefault", "SortOrder")
WHERE NOT EXISTS (SELECT 1 FROM public."FiscalTaxRates" WHERE "CountryCode" = v."CountryCode" AND "Code" = v."Code");

-- Seed: Invoice types VE
INSERT INTO public."FiscalInvoiceTypes" ("CountryCode", "Code", "Name", "IsRectificative", "RequiresRecipientId", "MaxAmount", "RequiresFiscalPrinter", "SortOrder")
SELECT v.* FROM (VALUES
    ('VE', 'FACTURA',      'Factura Fiscal',           FALSE, TRUE, NULL::NUMERIC,    TRUE,  10),
    ('VE', 'NOTA_CREDITO', 'Nota de Credito Fiscal',   TRUE,  TRUE, NULL::NUMERIC,    TRUE,  20),
    ('VE', 'NOTA_DEBITO',  'Nota de Debito Fiscal',    FALSE, TRUE, NULL::NUMERIC,    TRUE,  30)
) AS v("CountryCode", "Code", "Name", "IsRectificative", "RequiresRecipientId", "MaxAmount", "RequiresFiscalPrinter", "SortOrder")
WHERE NOT EXISTS (SELECT 1 FROM public."FiscalInvoiceTypes" WHERE "CountryCode" = v."CountryCode" AND "Code" = v."Code");

-- Seed: Invoice types ES
INSERT INTO public."FiscalInvoiceTypes" ("CountryCode", "Code", "Name", "IsRectificative", "RequiresRecipientId", "MaxAmount", "RequiresFiscalPrinter", "SortOrder")
SELECT v.* FROM (VALUES
    ('ES', 'F1', 'Factura Completa',                FALSE, TRUE,  NULL::NUMERIC,    FALSE, 10),
    ('ES', 'F2', 'Factura Simplificada',            FALSE, FALSE, 3000.00,        FALSE, 20),
    ('ES', 'F3', 'Factura Sustitucion Simplificada',FALSE, TRUE,  NULL::NUMERIC,    FALSE, 30),
    ('ES', 'R1', 'Rectificativa R1',                TRUE,  TRUE,  NULL::NUMERIC,    FALSE, 40),
    ('ES', 'R2', 'Rectificativa R2',                TRUE,  TRUE,  NULL::NUMERIC,    FALSE, 50),
    ('ES', 'R3', 'Rectificativa R3',                TRUE,  TRUE,  NULL::NUMERIC,    FALSE, 60),
    ('ES', 'R4', 'Rectificativa R4',                TRUE,  TRUE,  NULL::NUMERIC,    FALSE, 70),
    ('ES', 'R5', 'Rectificativa R5',                TRUE,  FALSE, NULL::NUMERIC,    FALSE, 80)
) AS v("CountryCode", "Code", "Name", "IsRectificative", "RequiresRecipientId", "MaxAmount", "RequiresFiscalPrinter", "SortOrder")
WHERE NOT EXISTS (SELECT 1 FROM public."FiscalInvoiceTypes" WHERE "CountryCode" = v."CountryCode" AND "Code" = v."Code");
