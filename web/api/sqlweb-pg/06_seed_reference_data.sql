-- ============================================================
-- DatqBoxWeb PostgreSQL - 06_seed_reference_data.sql
-- Seeds de FiscalCountryConfig, FiscalTaxRates, FiscalInvoiceTypes
-- para Venezuela (VE) y Espana (ES)
-- ============================================================

BEGIN;

DO $$
DECLARE
  v_DefaultCompanyId INT;
  v_DefaultBranchId  INT;
BEGIN
  SELECT "CompanyId" INTO v_DefaultCompanyId
    FROM cfg."Company" WHERE "CompanyCode" = 'DEFAULT' LIMIT 1;
  SELECT "BranchId" INTO v_DefaultBranchId
    FROM cfg."Branch"
    WHERE "CompanyId" = v_DefaultCompanyId AND "BranchCode" = 'MAIN' LIMIT 1;

  IF v_DefaultCompanyId IS NULL OR v_DefaultBranchId IS NULL THEN
    RAISE EXCEPTION 'Missing DEFAULT company/MAIN branch.';
  END IF;

  -- ============================================================
  -- FiscalCountryConfig - Venezuela
  -- ============================================================
  INSERT INTO public."FiscalCountryConfig" (
    "EmpresaId", "SucursalId", "CountryCode", "Currency", "TaxRegime",
    "DefaultTaxCode", "DefaultTaxRate", "FiscalPrinterEnabled", "VerifactuEnabled",
    "VerifactuMode", "SenderRIF", "PosEnabled", "RestaurantEnabled", "IsActive"
  )
  VALUES (
    v_DefaultCompanyId, v_DefaultBranchId, 'VE', 'VES', 'GENERAL',
    'IVA_GENERAL', 0.1600, TRUE, FALSE,
    'manual', 'J-00000000-0', TRUE, TRUE, TRUE
  )
  ON CONFLICT ("EmpresaId", "SucursalId", "CountryCode") DO NOTHING;

  -- ============================================================
  -- FiscalCountryConfig - Espana
  -- ============================================================
  INSERT INTO public."FiscalCountryConfig" (
    "EmpresaId", "SucursalId", "CountryCode", "Currency", "TaxRegime",
    "DefaultTaxCode", "DefaultTaxRate", "FiscalPrinterEnabled", "VerifactuEnabled",
    "VerifactuMode", "AEATEndpoint", "SenderNIF",
    "PosEnabled", "RestaurantEnabled", "IsActive"
  )
  VALUES (
    v_DefaultCompanyId, v_DefaultBranchId, 'ES', 'EUR', 'GENERAL',
    'IVA_REDUCIDO', 0.1000, FALSE, TRUE,
    'manual',
    'https://www1.agenciatributaria.gob.es/wlpl/TIKE-CONT/ws/SistemaFacturacion/RegistroFacturacion',
    'B12345678',
    TRUE, TRUE, TRUE
  )
  ON CONFLICT ("EmpresaId", "SucursalId", "CountryCode") DO NOTHING;

END $$;

-- ============================================================
-- FiscalTaxRates - Venezuela
-- ============================================================
INSERT INTO public."FiscalTaxRates" ("CountryCode", "Code", "Name", "Rate", "AppliesToPOS", "AppliesToRestaurant", "IsDefault", "SortOrder")
VALUES ('VE', 'IVA_GENERAL',   'IVA General',   0.1600, TRUE, TRUE, TRUE, 10)
ON CONFLICT ("CountryCode", "Code") DO NOTHING;

INSERT INTO public."FiscalTaxRates" ("CountryCode", "Code", "Name", "Rate", "AppliesToPOS", "AppliesToRestaurant", "IsDefault", "SortOrder")
VALUES ('VE', 'IVA_REDUCIDO',  'IVA Reducido',  0.0800, TRUE, TRUE, FALSE, 20)
ON CONFLICT ("CountryCode", "Code") DO NOTHING;

INSERT INTO public."FiscalTaxRates" ("CountryCode", "Code", "Name", "Rate", "AppliesToPOS", "AppliesToRestaurant", "IsDefault", "SortOrder")
VALUES ('VE', 'IVA_ADICIONAL', 'IVA Adicional', 0.3100, TRUE, FALSE, FALSE, 30)
ON CONFLICT ("CountryCode", "Code") DO NOTHING;

INSERT INTO public."FiscalTaxRates" ("CountryCode", "Code", "Name", "Rate", "AppliesToPOS", "AppliesToRestaurant", "IsDefault", "SortOrder")
VALUES ('VE', 'EXENTO',        'Exento',        0.0000, TRUE, TRUE, FALSE, 40)
ON CONFLICT ("CountryCode", "Code") DO NOTHING;

-- ============================================================
-- FiscalTaxRates - Espana
-- ============================================================
INSERT INTO public."FiscalTaxRates" ("CountryCode", "Code", "Name", "Rate", "AppliesToPOS", "AppliesToRestaurant", "IsDefault", "SortOrder")
VALUES ('ES', 'IVA_GENERAL',        'IVA General',        0.2100, TRUE, FALSE, TRUE, 10)
ON CONFLICT ("CountryCode", "Code") DO NOTHING;

INSERT INTO public."FiscalTaxRates" ("CountryCode", "Code", "Name", "Rate", "AppliesToPOS", "AppliesToRestaurant", "IsDefault", "SortOrder")
VALUES ('ES', 'IVA_REDUCIDO',       'IVA Reducido',       0.1000, TRUE, TRUE, FALSE, 20)
ON CONFLICT ("CountryCode", "Code") DO NOTHING;

INSERT INTO public."FiscalTaxRates" ("CountryCode", "Code", "Name", "Rate", "AppliesToPOS", "AppliesToRestaurant", "IsDefault", "SortOrder")
VALUES ('ES', 'IVA_SUPERREDUCIDO',  'IVA Superreducido',  0.0400, TRUE, FALSE, FALSE, 30)
ON CONFLICT ("CountryCode", "Code") DO NOTHING;

INSERT INTO public."FiscalTaxRates" ("CountryCode", "Code", "Name", "Rate", "AppliesToPOS", "AppliesToRestaurant", "IsDefault", "SortOrder")
VALUES ('ES', 'EXENTO',             'Exento',             0.0000, TRUE, TRUE, FALSE, 40)
ON CONFLICT ("CountryCode", "Code") DO NOTHING;

INSERT INTO public."FiscalTaxRates" ("CountryCode", "Code", "Name", "Rate", "SurchargeRate", "AppliesToPOS", "AppliesToRestaurant", "IsDefault", "SortOrder")
VALUES ('ES', 'RE_GENERAL',         'Recargo Equivalencia General',        0.0520, 0.0520, TRUE, FALSE, FALSE, 50)
ON CONFLICT ("CountryCode", "Code") DO NOTHING;

INSERT INTO public."FiscalTaxRates" ("CountryCode", "Code", "Name", "Rate", "SurchargeRate", "AppliesToPOS", "AppliesToRestaurant", "IsDefault", "SortOrder")
VALUES ('ES', 'RE_REDUCIDO',        'Recargo Equivalencia Reducido',       0.0140, 0.0140, TRUE, FALSE, FALSE, 60)
ON CONFLICT ("CountryCode", "Code") DO NOTHING;

INSERT INTO public."FiscalTaxRates" ("CountryCode", "Code", "Name", "Rate", "SurchargeRate", "AppliesToPOS", "AppliesToRestaurant", "IsDefault", "SortOrder")
VALUES ('ES', 'RE_SUPERREDUCIDO',   'Recargo Equivalencia Superreducido',  0.0050, 0.0050, FALSE, FALSE, FALSE, 70)
ON CONFLICT ("CountryCode", "Code") DO NOTHING;

-- ============================================================
-- FiscalInvoiceTypes - Venezuela
-- ============================================================
INSERT INTO public."FiscalInvoiceTypes" ("CountryCode", "Code", "Name", "IsRectificative", "RequiresRecipientId", "RequiresFiscalPrinter", "SortOrder")
VALUES ('VE', 'FACTURA',      'Factura Fiscal',           FALSE, TRUE,  TRUE,  10)
ON CONFLICT ("CountryCode", "Code") DO NOTHING;

INSERT INTO public."FiscalInvoiceTypes" ("CountryCode", "Code", "Name", "IsRectificative", "RequiresRecipientId", "RequiresFiscalPrinter", "SortOrder")
VALUES ('VE', 'NOTA_CREDITO', 'Nota de Credito Fiscal',   TRUE,  TRUE,  TRUE,  20)
ON CONFLICT ("CountryCode", "Code") DO NOTHING;

INSERT INTO public."FiscalInvoiceTypes" ("CountryCode", "Code", "Name", "IsRectificative", "RequiresRecipientId", "RequiresFiscalPrinter", "SortOrder")
VALUES ('VE', 'NOTA_DEBITO',  'Nota de Debito Fiscal',    FALSE, TRUE,  TRUE,  30)
ON CONFLICT ("CountryCode", "Code") DO NOTHING;

INSERT INTO public."FiscalInvoiceTypes" ("CountryCode", "Code", "Name", "IsRectificative", "RequiresRecipientId", "RequiresFiscalPrinter", "SortOrder")
VALUES ('VE', 'NOTA_ENTREGA', 'Nota de Entrega',          FALSE, FALSE, FALSE, 40)
ON CONFLICT ("CountryCode", "Code") DO NOTHING;

-- ============================================================
-- FiscalInvoiceTypes - Espana
-- ============================================================
INSERT INTO public."FiscalInvoiceTypes" ("CountryCode", "Code", "Name", "IsRectificative", "RequiresRecipientId", "MaxAmount", "RequiresFiscalPrinter", "SortOrder")
VALUES ('ES', 'F1', 'Factura Completa',                 FALSE, TRUE,  NULL,   FALSE, 10)
ON CONFLICT ("CountryCode", "Code") DO NOTHING;

INSERT INTO public."FiscalInvoiceTypes" ("CountryCode", "Code", "Name", "IsRectificative", "RequiresRecipientId", "MaxAmount", "RequiresFiscalPrinter", "SortOrder")
VALUES ('ES', 'F2', 'Factura Simplificada',             FALSE, FALSE, 400.00, FALSE, 20)
ON CONFLICT ("CountryCode", "Code") DO NOTHING;

INSERT INTO public."FiscalInvoiceTypes" ("CountryCode", "Code", "Name", "IsRectificative", "RequiresRecipientId", "MaxAmount", "RequiresFiscalPrinter", "SortOrder")
VALUES ('ES', 'F3', 'Factura Sustitucion Simplificada', FALSE, TRUE,  NULL,   FALSE, 30)
ON CONFLICT ("CountryCode", "Code") DO NOTHING;

INSERT INTO public."FiscalInvoiceTypes" ("CountryCode", "Code", "Name", "IsRectificative", "RequiresRecipientId", "MaxAmount", "RequiresFiscalPrinter", "SortOrder")
VALUES ('ES', 'R1', 'Rectificativa R1',                 TRUE,  TRUE,  NULL,   FALSE, 40)
ON CONFLICT ("CountryCode", "Code") DO NOTHING;

INSERT INTO public."FiscalInvoiceTypes" ("CountryCode", "Code", "Name", "IsRectificative", "RequiresRecipientId", "MaxAmount", "RequiresFiscalPrinter", "SortOrder")
VALUES ('ES', 'R2', 'Rectificativa R2',                 TRUE,  TRUE,  NULL,   FALSE, 50)
ON CONFLICT ("CountryCode", "Code") DO NOTHING;

INSERT INTO public."FiscalInvoiceTypes" ("CountryCode", "Code", "Name", "IsRectificative", "RequiresRecipientId", "MaxAmount", "RequiresFiscalPrinter", "SortOrder")
VALUES ('ES', 'R3', 'Rectificativa R3',                 TRUE,  TRUE,  NULL,   FALSE, 60)
ON CONFLICT ("CountryCode", "Code") DO NOTHING;

INSERT INTO public."FiscalInvoiceTypes" ("CountryCode", "Code", "Name", "IsRectificative", "RequiresRecipientId", "MaxAmount", "RequiresFiscalPrinter", "SortOrder")
VALUES ('ES', 'R4', 'Rectificativa R4',                 TRUE,  TRUE,  NULL,   FALSE, 70)
ON CONFLICT ("CountryCode", "Code") DO NOTHING;

INSERT INTO public."FiscalInvoiceTypes" ("CountryCode", "Code", "Name", "IsRectificative", "RequiresRecipientId", "MaxAmount", "RequiresFiscalPrinter", "SortOrder")
VALUES ('ES', 'R5', 'Rectificativa R5',                 TRUE,  FALSE, NULL,   FALSE, 80)
ON CONFLICT ("CountryCode", "Code") DO NOTHING;

COMMIT;
