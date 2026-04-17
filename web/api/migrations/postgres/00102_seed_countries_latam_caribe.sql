-- +goose Up

-- Seed fiscal completo LATAM + Caribe hispanohablante.
-- Datos verificados por búsqueda web (ver plan file).
--
-- Incluye 16 países nuevos + 5 existentes (UPSERT con ON CONFLICT).
-- Multi-país, multi-moneda: cada país con su moneda local, tasa vs USD,
-- régimen fiscal (IVA/ITBMS/IGV/ITBIS/IVU), autoridad tributaria, ID fiscal.
--
-- SpecialTaxRate solo aplica para impuestos especiales país-específicos
-- (ej: IGTF en Venezuela). El IVA general se maneja en fiscal.TaxRate.

-- +goose StatementBegin
INSERT INTO cfg."Country" (
  "CountryCode", "CountryName", "Iso3", "CurrencyCode", "CurrencySymbol",
  "ReferenceCurrency", "ReferenceCurrencySymbol", "DefaultExchangeRate",
  "PricesIncludeTax", "SpecialTaxRate", "SpecialTaxEnabled",
  "TaxAuthorityCode", "FiscalIdName", "TimeZoneIana", "PhonePrefix", "FlagEmoji",
  "SortOrder", "IsActive"
) VALUES
  -- América del Sur
  ('VE', 'Venezuela',          'VEN', 'VES', 'Bs',  'USD', '$', 45.0,   TRUE,  3.0, TRUE,  'SENIAT', 'RIF',             'America/Caracas',                    '+58',  E'\U0001F1FB\U0001F1EA', 10, TRUE),
  ('CO', 'Colombia',            'COL', 'COP', '$',   'USD', '$', 4000.0, FALSE, 0.0, FALSE, 'DIAN',   'NIT',             'America/Bogota',                     '+57',  E'\U0001F1E8\U0001F1F4', 20, TRUE),
  ('AR', 'Argentina',           'ARG', 'ARS', '$',   'USD', '$', 1420.0, TRUE,  0.0, FALSE, 'ARCA',   'CUIT',            'America/Argentina/Buenos_Aires',     '+54',  E'\U0001F1E6\U0001F1F7', 30, TRUE),
  ('CL', 'Chile',               'CHL', 'CLP', '$',   'USD', '$', 910.0,  TRUE,  0.0, FALSE, 'SII',    'RUT',             'America/Santiago',                   '+56',  E'\U0001F1E8\U0001F1F1', 35, TRUE),
  ('PE', 'Peru',                'PER', 'PEN', 'S/',  'USD', '$', 3.7,    TRUE,  0.0, FALSE, 'SUNAT',  'RUC',             'America/Lima',                       '+51',  E'\U0001F1F5\U0001F1EA', 40, TRUE),
  ('EC', 'Ecuador',             'ECU', 'USD', '$',   'USD', '$', 1.0,    FALSE, 0.0, FALSE, 'SRI',    'RUC',             'America/Guayaquil',                  '+593', E'\U0001F1EA\U0001F1E8', 45, TRUE),
  ('BO', 'Bolivia',             'BOL', 'BOB', 'Bs',  'USD', '$', 6.96,   TRUE,  0.0, FALSE, 'SIN',    'NIT',             'America/La_Paz',                     '+591', E'\U0001F1E7\U0001F1F4', 50, TRUE),
  ('UY', 'Uruguay',             'URY', 'UYU', '$',   'USD', '$', 40.0,   TRUE,  0.0, FALSE, 'DGI',    'RUT',             'America/Montevideo',                 '+598', E'\U0001F1FA\U0001F1FE', 55, TRUE),
  ('PY', 'Paraguay',            'PRY', 'PYG', '₲',  'USD', '$', 7500.0, TRUE,  0.0, FALSE, 'DNIT',   'RUC',             'America/Asuncion',                   '+595', E'\U0001F1F5\U0001F1FE', 60, TRUE),
  -- Centroamérica + Caribe hispanohablante
  ('MX', 'Mexico',              'MEX', 'MXN', '$',   'USD', '$', 18.0,   FALSE, 0.0, FALSE, 'SAT',    'RFC',             'America/Mexico_City',                '+52',  E'\U0001F1F2\U0001F1FD', 65, TRUE),
  ('PA', 'Panama',              'PAN', 'USD', '$',   'USD', '$', 1.0,    FALSE, 0.0, FALSE, 'DGI',    'RUC',             'America/Panama',                     '+507', E'\U0001F1F5\U0001F1E6', 70, TRUE),
  ('CR', 'Costa Rica',          'CRI', 'CRC', '₡',  'USD', '$', 510.0,  TRUE,  0.0, FALSE, 'DGT',    'Cedula Juridica', 'America/Costa_Rica',                 '+506', E'\U0001F1E8\U0001F1F7', 75, TRUE),
  ('DO', 'Republica Dominicana','DOM', 'DOP', 'RD$', 'USD', '$', 62.0,   FALSE, 0.0, FALSE, 'DGII',   'RNC',             'America/Santo_Domingo',              '+1',   E'\U0001F1E9\U0001F1F4', 80, TRUE),
  ('GT', 'Guatemala',           'GTM', 'GTQ', 'Q',   'USD', '$', 7.8,    TRUE,  0.0, FALSE, 'SAT',    'NIT',             'America/Guatemala',                  '+502', E'\U0001F1EC\U0001F1F9', 85, TRUE),
  ('HN', 'Honduras',            'HND', 'HNL', 'L',   'USD', '$', 26.5,   TRUE,  0.0, FALSE, 'SAR',    'RTN',             'America/Tegucigalpa',                '+504', E'\U0001F1ED\U0001F1F3', 90, TRUE),
  ('NI', 'Nicaragua',           'NIC', 'NIO', 'C$',  'USD', '$', 36.7,   TRUE,  0.0, FALSE, 'DGI',    'RUC',             'America/Managua',                    '+505', E'\U0001F1F3\U0001F1EE', 95, TRUE),
  ('SV', 'El Salvador',         'SLV', 'USD', '$',   'USD', '$', 1.0,    FALSE, 0.0, FALSE, 'DGII',   'NIT',             'America/El_Salvador',                '+503', E'\U0001F1F8\U0001F1FB', 100, TRUE),
  ('PR', 'Puerto Rico',         'PRI', 'USD', '$',   'USD', '$', 1.0,    FALSE, 0.0, FALSE, 'Hacienda', 'EIN',           'America/Puerto_Rico',                '+1',   E'\U0001F1F5\U0001F1F7', 105, TRUE),
  ('CU', 'Cuba',                'CUB', 'CUP', '$',   'USD', '$', 24.0,   TRUE,  0.0, FALSE, 'ONAT',   'NIT',             'America/Havana',                     '+53',  E'\U0001F1E8\U0001F1FA', 110, TRUE),
  -- Europa + Norteamérica
  ('ES', 'Espana',              'ESP', 'EUR', '€',  'USD', '$', 1.0,    TRUE,  0.0, FALSE, 'AEAT',   'NIF',             'Europe/Madrid',                      '+34',  E'\U0001F1EA\U0001F1F8', 200, TRUE),
  ('US', 'Estados Unidos',      'USA', 'USD', '$',   'EUR', '€', 1.0,    FALSE, 0.0, FALSE, 'IRS',    'EIN',             'America/New_York',                   '+1',   E'\U0001F1FA\U0001F1F8', 210, TRUE)
ON CONFLICT ("CountryCode") DO UPDATE SET
  "CountryName"              = EXCLUDED."CountryName",
  "Iso3"                     = EXCLUDED."Iso3",
  "CurrencyCode"             = EXCLUDED."CurrencyCode",
  "CurrencySymbol"           = EXCLUDED."CurrencySymbol",
  "ReferenceCurrency"        = EXCLUDED."ReferenceCurrency",
  "ReferenceCurrencySymbol"  = EXCLUDED."ReferenceCurrencySymbol",
  "DefaultExchangeRate"      = EXCLUDED."DefaultExchangeRate",
  "PricesIncludeTax"         = EXCLUDED."PricesIncludeTax",
  "SpecialTaxRate"           = EXCLUDED."SpecialTaxRate",
  "SpecialTaxEnabled"        = EXCLUDED."SpecialTaxEnabled",
  "TaxAuthorityCode"         = EXCLUDED."TaxAuthorityCode",
  "FiscalIdName"             = EXCLUDED."FiscalIdName",
  "TimeZoneIana"             = EXCLUDED."TimeZoneIana",
  "PhonePrefix"              = EXCLUDED."PhonePrefix",
  "FlagEmoji"                = EXCLUDED."FlagEmoji",
  "SortOrder"                = EXCLUDED."SortOrder",
  "IsActive"                 = EXCLUDED."IsActive",
  "UpdatedAt"                = NOW();
-- +goose StatementEnd

-- +goose Down
-- No rollback — los datos fiscales son referencia y no deben revertirse.
-- +goose StatementBegin
SELECT 1;
-- +goose StatementEnd
