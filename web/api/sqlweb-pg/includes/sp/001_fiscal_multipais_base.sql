-- ============================================================
-- DatqBoxWeb PostgreSQL - 001_fiscal_multipais_base.sql
-- Base fiscal multi-pais para Venezuela + Espana (Verifactu).
-- No destructivo e idempotente.
-- ============================================================

CREATE SCHEMA IF NOT EXISTS fiscal;

-- NOTA: Tablas legacy public.* eliminadas (2026-03-16).
-- Usar fiscal.CountryConfig, fiscal.TaxRate, fiscal.InvoiceType, fiscal.Record.
-- Tablas eliminadas: FiscalCountryConfig, FiscalTaxRates, FiscalInvoiceTypes, FiscalRecords.

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
