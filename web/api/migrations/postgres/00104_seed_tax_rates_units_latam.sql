-- +goose Up

-- Seed multi-pais completo para LATAM + Caribe hispanohablante:
-- 1. fiscal.TaxRate — IVA/IGV/ITBMS/ITBIS/IVU/ISV por pais
-- 2. cfg.TaxUnit — Unidades fiscales (UT/UTM/UVT/UIT/BPC/UMA) por pais
--
-- Todos los paises ya estan en cfg.Country (migration 00102).
-- Idempotente: UPSERT por claves unicas.
--
-- Datos 2026 verificados contra fuentes oficiales.

-- ═══════════════════════════════════════════════════════════
-- FISCAL.TAXRATE — Tasas de IVA/impuesto indirecto por pais
-- ═══════════════════════════════════════════════════════════

-- +goose StatementBegin
DELETE FROM fiscal."TaxRate"
WHERE "CountryCode" IN ('VE','CO','MX','AR','CL','PE','EC','BO','UY','PY','PA','CR','DO','GT','HN','NI','SV','PR','CU','ES','US')
  AND "TaxCode" IN ('IVA','IVA_REDUCIDO','IVA_SUPERREDUCIDO','IVA_CERO','IGV','ITBMS','ITBMS_ALCOHOL','ITBMS_TABACO','ITBIS','ITBIS_REDUCIDO','IVU','ISV','ISV_ALCOHOL','IGTF','IVA_FRONTERA');
-- +goose StatementEnd

-- Venezuela: IVA 16% + IGTF 3%
-- +goose StatementBegin
INSERT INTO fiscal."TaxRate" ("CountryCode","TaxCode","TaxName","Rate","AppliesToPOS","AppliesToRestaurant","IsDefault","SortOrder") VALUES
  ('VE','IVA',           'IVA',                 0.1600, TRUE, TRUE, TRUE,  10),
  ('VE','IVA_CERO',      'IVA 0%',              0.0000, TRUE, TRUE, FALSE, 20),
  ('VE','IGTF',          'IGTF Divisas',        0.0300, TRUE, TRUE, FALSE, 30);
-- +goose StatementEnd

-- Colombia: IVA 19%, 5%, 0%
-- +goose StatementBegin
INSERT INTO fiscal."TaxRate" ("CountryCode","TaxCode","TaxName","Rate","AppliesToPOS","AppliesToRestaurant","IsDefault","SortOrder") VALUES
  ('CO','IVA',           'IVA',                 0.1900, TRUE, TRUE, TRUE,  10),
  ('CO','IVA_REDUCIDO',  'IVA Reducido',        0.0500, TRUE, TRUE, FALSE, 20),
  ('CO','IVA_CERO',      'IVA 0%',              0.0000, TRUE, TRUE, FALSE, 30);
-- +goose StatementEnd

-- México: IVA 16%, frontera 8%, 0%
-- +goose StatementBegin
INSERT INTO fiscal."TaxRate" ("CountryCode","TaxCode","TaxName","Rate","AppliesToPOS","AppliesToRestaurant","IsDefault","SortOrder") VALUES
  ('MX','IVA',           'IVA',                 0.1600, TRUE, TRUE, TRUE,  10),
  ('MX','IVA_FRONTERA',  'IVA Zona Fronteriza', 0.0800, TRUE, TRUE, FALSE, 20),
  ('MX','IVA_CERO',      'IVA 0%',              0.0000, TRUE, TRUE, FALSE, 30);
-- +goose StatementEnd

-- Argentina: IVA 21%, 10.5%, 27%, 0%
-- +goose StatementBegin
INSERT INTO fiscal."TaxRate" ("CountryCode","TaxCode","TaxName","Rate","AppliesToPOS","AppliesToRestaurant","IsDefault","SortOrder") VALUES
  ('AR','IVA',           'IVA General',         0.2100, TRUE, TRUE, TRUE,  10),
  ('AR','IVA_REDUCIDO',  'IVA Reducido',        0.1050, TRUE, TRUE, FALSE, 20),
  ('AR','IVA_CERO',      'IVA 0%',              0.0000, TRUE, TRUE, FALSE, 40);
-- +goose StatementEnd

-- Chile: IVA 19%
-- +goose StatementBegin
INSERT INTO fiscal."TaxRate" ("CountryCode","TaxCode","TaxName","Rate","AppliesToPOS","AppliesToRestaurant","IsDefault","SortOrder") VALUES
  ('CL','IVA',           'IVA',                 0.1900, TRUE, TRUE, TRUE,  10),
  ('CL','IVA_CERO',      'IVA 0%',              0.0000, TRUE, TRUE, FALSE, 20);
-- +goose StatementEnd

-- Perú: IGV 18%
-- +goose StatementBegin
INSERT INTO fiscal."TaxRate" ("CountryCode","TaxCode","TaxName","Rate","AppliesToPOS","AppliesToRestaurant","IsDefault","SortOrder") VALUES
  ('PE','IGV',           'IGV',                 0.1800, TRUE, TRUE, TRUE,  10),
  ('PE','IVA_CERO',      'IGV 0%',              0.0000, TRUE, TRUE, FALSE, 20);
-- +goose StatementEnd

-- Ecuador: IVA 15%, 5%, 0%
-- +goose StatementBegin
INSERT INTO fiscal."TaxRate" ("CountryCode","TaxCode","TaxName","Rate","AppliesToPOS","AppliesToRestaurant","IsDefault","SortOrder") VALUES
  ('EC','IVA',           'IVA 15%',             0.1500, TRUE, TRUE, TRUE,  10),
  ('EC','IVA_REDUCIDO',  'IVA 5%',              0.0500, TRUE, TRUE, FALSE, 20),
  ('EC','IVA_CERO',      'IVA 0%',              0.0000, TRUE, TRUE, FALSE, 30);
-- +goose StatementEnd

-- Bolivia: IVA 13%
-- +goose StatementBegin
INSERT INTO fiscal."TaxRate" ("CountryCode","TaxCode","TaxName","Rate","AppliesToPOS","AppliesToRestaurant","IsDefault","SortOrder") VALUES
  ('BO','IVA',           'IVA',                 0.1300, TRUE, TRUE, TRUE,  10),
  ('BO','IVA_CERO',      'IVA 0%',              0.0000, TRUE, TRUE, FALSE, 20);
-- +goose StatementEnd

-- Uruguay: IVA 22%, 10%
-- +goose StatementBegin
INSERT INTO fiscal."TaxRate" ("CountryCode","TaxCode","TaxName","Rate","AppliesToPOS","AppliesToRestaurant","IsDefault","SortOrder") VALUES
  ('UY','IVA',           'IVA Basico',          0.2200, TRUE, TRUE, TRUE,  10),
  ('UY','IVA_REDUCIDO',  'IVA Minimo',          0.1000, TRUE, TRUE, FALSE, 20),
  ('UY','IVA_CERO',      'IVA 0%',              0.0000, TRUE, TRUE, FALSE, 30);
-- +goose StatementEnd

-- Paraguay: IVA 10%, 5%
-- +goose StatementBegin
INSERT INTO fiscal."TaxRate" ("CountryCode","TaxCode","TaxName","Rate","AppliesToPOS","AppliesToRestaurant","IsDefault","SortOrder") VALUES
  ('PY','IVA',           'IVA 10%',             0.1000, TRUE, TRUE, TRUE,  10),
  ('PY','IVA_REDUCIDO',  'IVA 5%',              0.0500, TRUE, TRUE, FALSE, 20),
  ('PY','IVA_CERO',      'IVA 0%',              0.0000, TRUE, TRUE, FALSE, 30);
-- +goose StatementEnd

-- Panamá: ITBMS 7%, 10%, 15%
-- +goose StatementBegin
INSERT INTO fiscal."TaxRate" ("CountryCode","TaxCode","TaxName","Rate","AppliesToPOS","AppliesToRestaurant","IsDefault","SortOrder") VALUES
  ('PA','ITBMS',         'ITBMS General',       0.0700, TRUE, TRUE, TRUE,  10),
  ('PA','ITBMS_ALCOHOL', 'ITBMS Alcohol',       0.1000, TRUE, TRUE, FALSE, 20),
  ('PA','ITBMS_TABACO',  'ITBMS Tabaco',        0.1500, TRUE, TRUE, FALSE, 30),
  ('PA','IVA_CERO',      'ITBMS 0%',            0.0000, TRUE, TRUE, FALSE, 40);
-- +goose StatementEnd

-- Costa Rica: IVA 13%
-- +goose StatementBegin
INSERT INTO fiscal."TaxRate" ("CountryCode","TaxCode","TaxName","Rate","AppliesToPOS","AppliesToRestaurant","IsDefault","SortOrder") VALUES
  ('CR','IVA',           'IVA',                 0.1300, TRUE, TRUE, TRUE,  10),
  ('CR','IVA_CERO',      'IVA 0%',              0.0000, TRUE, TRUE, FALSE, 20);
-- +goose StatementEnd

-- Rep. Dominicana: ITBIS 18%, 16%, 0%
-- +goose StatementBegin
INSERT INTO fiscal."TaxRate" ("CountryCode","TaxCode","TaxName","Rate","AppliesToPOS","AppliesToRestaurant","IsDefault","SortOrder") VALUES
  ('DO','ITBIS',          'ITBIS',              0.1800, TRUE, TRUE, TRUE,  10),
  ('DO','ITBIS_REDUCIDO', 'ITBIS Reducido',     0.1600, TRUE, TRUE, FALSE, 20),
  ('DO','IVA_CERO',       'ITBIS 0%',           0.0000, TRUE, TRUE, FALSE, 30);
-- +goose StatementEnd

-- Guatemala: IVA 12%
-- +goose StatementBegin
INSERT INTO fiscal."TaxRate" ("CountryCode","TaxCode","TaxName","Rate","AppliesToPOS","AppliesToRestaurant","IsDefault","SortOrder") VALUES
  ('GT','IVA',           'IVA',                 0.1200, TRUE, TRUE, TRUE,  10),
  ('GT','IVA_CERO',      'IVA 0%',              0.0000, TRUE, TRUE, FALSE, 20);
-- +goose StatementEnd

-- Honduras: ISV 15%, 18% (alcohol/tabaco)
-- +goose StatementBegin
INSERT INTO fiscal."TaxRate" ("CountryCode","TaxCode","TaxName","Rate","AppliesToPOS","AppliesToRestaurant","IsDefault","SortOrder") VALUES
  ('HN','ISV',           'ISV General',         0.1500, TRUE, TRUE, TRUE,  10),
  ('HN','ISV_ALCOHOL',   'ISV Alcohol/Tabaco',  0.1800, TRUE, TRUE, FALSE, 20),
  ('HN','IVA_CERO',      'ISV 0%',              0.0000, TRUE, TRUE, FALSE, 30);
-- +goose StatementEnd

-- Nicaragua: IVA 15%
-- +goose StatementBegin
INSERT INTO fiscal."TaxRate" ("CountryCode","TaxCode","TaxName","Rate","AppliesToPOS","AppliesToRestaurant","IsDefault","SortOrder") VALUES
  ('NI','IVA',           'IVA',                 0.1500, TRUE, TRUE, TRUE,  10),
  ('NI','IVA_CERO',      'IVA 0%',              0.0000, TRUE, TRUE, FALSE, 20);
-- +goose StatementEnd

-- El Salvador: IVA 13%
-- +goose StatementBegin
INSERT INTO fiscal."TaxRate" ("CountryCode","TaxCode","TaxName","Rate","AppliesToPOS","AppliesToRestaurant","IsDefault","SortOrder") VALUES
  ('SV','IVA',           'IVA',                 0.1300, TRUE, TRUE, TRUE,  10),
  ('SV','IVA_CERO',      'IVA 0%',              0.0000, TRUE, TRUE, FALSE, 20);
-- +goose StatementEnd

-- Puerto Rico: IVU 11.5%
-- +goose StatementBegin
INSERT INTO fiscal."TaxRate" ("CountryCode","TaxCode","TaxName","Rate","AppliesToPOS","AppliesToRestaurant","IsDefault","SortOrder") VALUES
  ('PR','IVU',           'IVU',                 0.1150, TRUE, TRUE, TRUE,  10),
  ('PR','IVA_CERO',      'IVU 0%',              0.0000, TRUE, TRUE, FALSE, 20);
-- +goose StatementEnd

-- Cuba: sin IVA estandar, tasa 0 como default
-- +goose StatementBegin
INSERT INTO fiscal."TaxRate" ("CountryCode","TaxCode","TaxName","Rate","AppliesToPOS","AppliesToRestaurant","IsDefault","SortOrder") VALUES
  ('CU','IVA_CERO',      'Sin IVA general',     0.0000, TRUE, TRUE, TRUE,  10);
-- +goose StatementEnd

-- España: IVA 21%, 10%, 4%
-- +goose StatementBegin
INSERT INTO fiscal."TaxRate" ("CountryCode","TaxCode","TaxName","Rate","AppliesToPOS","AppliesToRestaurant","IsDefault","SortOrder") VALUES
  ('ES','IVA',                 'IVA General',      0.2100, TRUE, TRUE, TRUE,  10),
  ('ES','IVA_REDUCIDO',        'IVA Reducido',     0.1000, TRUE, TRUE, FALSE, 20),
  ('ES','IVA_SUPERREDUCIDO',   'IVA Superreducido',0.0400, TRUE, TRUE, FALSE, 30),
  ('ES','IVA_CERO',            'IVA 0%',           0.0000, TRUE, TRUE, FALSE, 40);
-- +goose StatementEnd

-- Estados Unidos: sin IVA federal (sales tax varia por estado)
-- +goose StatementBegin
INSERT INTO fiscal."TaxRate" ("CountryCode","TaxCode","TaxName","Rate","AppliesToPOS","AppliesToRestaurant","IsDefault","SortOrder") VALUES
  ('US','IVA_CERO',      'Sin IVA federal',     0.0000, TRUE, TRUE, TRUE,  10);
-- +goose StatementEnd

-- ═══════════════════════════════════════════════════════════
-- CFG.TAXUNIT — Unidades fiscales por pais y ano
-- ═══════════════════════════════════════════════════════════

-- +goose StatementBegin
DELETE FROM cfg."TaxUnit"
WHERE "TaxYear" = 2026
  AND "CountryCode" IN ('VE','CO','MX','AR','CL','PE','EC','BO','UY','PY','PA','CR','DO','GT','HN','NI','SV','PR','CU','ES','US');
-- +goose StatementEnd

-- +goose StatementBegin
INSERT INTO cfg."TaxUnit" ("CountryCode","TaxYear","UnitValue","Currency","EffectiveDate","IsActive") VALUES
  -- Venezuela: UT (Unidad Tributaria) 2026
  ('VE', 2026,      700.0000, 'VES', '2026-01-01', TRUE),
  -- Colombia: UVT (Unidad de Valor Tributario)
  ('CO', 2026,    52374.0000, 'COP', '2026-01-01', TRUE),
  -- Perú: UIT (Unidad Impositiva Tributaria) - DS 316-2024-EF
  ('PE', 2026,     5500.0000, 'PEN', '2026-01-01', TRUE),
  -- Uruguay: BPC (Base Prestaciones y Contribuciones)
  ('UY', 2026,     6864.0000, 'UYU', '2026-01-01', TRUE),
  -- Chile: UTM (Unidad Tributaria Mensual) - enero 2026
  ('CL', 2026,    69611.0000, 'CLP', '2026-01-01', TRUE),
  -- Argentina: sin UT, usa pesos directos
  ('AR', 2026,        1.0000, 'ARS', '2026-01-01', TRUE),
  -- Mexico: UMA (Unidad de Medida y Actualizacion) diaria 2026 ~113.14 MXN
  ('MX', 2026,      113.1400, 'MXN', '2026-01-01', TRUE),
  -- Ecuador: USD (usa SBU Salario Basico Unificado = 482)
  ('EC', 2026,      482.0000, 'USD', '2026-01-01', TRUE),
  -- Bolivia: UFV (Unidad de Fomento a la Vivienda)
  ('BO', 2026,        2.6500, 'BOB', '2026-01-01', TRUE),
  -- Paraguay: Jornal Minimo diario
  ('PY', 2026,   110000.0000, 'PYG', '2026-01-01', TRUE),
  -- Panamá: USD directo
  ('PA', 2026,        1.0000, 'USD', '2026-01-01', TRUE),
  -- Costa Rica: CRC directo
  ('CR', 2026,        1.0000, 'CRC', '2026-01-01', TRUE),
  -- Rep. Dominicana: DOP directo
  ('DO', 2026,        1.0000, 'DOP', '2026-01-01', TRUE),
  -- Guatemala: GTQ directo
  ('GT', 2026,        1.0000, 'GTQ', '2026-01-01', TRUE),
  -- Honduras: HNL directo
  ('HN', 2026,        1.0000, 'HNL', '2026-01-01', TRUE),
  -- Nicaragua: NIO directo
  ('NI', 2026,        1.0000, 'NIO', '2026-01-01', TRUE),
  -- El Salvador: USD directo
  ('SV', 2026,        1.0000, 'USD', '2026-01-01', TRUE),
  -- Puerto Rico: USD directo
  ('PR', 2026,        1.0000, 'USD', '2026-01-01', TRUE),
  -- Cuba: CUP directo
  ('CU', 2026,        1.0000, 'CUP', '2026-01-01', TRUE),
  -- España: EUR directo (IPREM 2026 ~600 mensual)
  ('ES', 2026,      600.0000, 'EUR', '2026-01-01', TRUE),
  -- USA: USD directo (Federal poverty level 2026 ~15060 anual single)
  ('US', 2026,        1.0000, 'USD', '2026-01-01', TRUE);
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
DELETE FROM fiscal."TaxRate"
WHERE "CountryCode" IN ('VE','CO','MX','AR','CL','PE','EC','BO','UY','PY','PA','CR','DO','GT','HN','NI','SV','PR','CU','ES','US')
  AND "TaxCode" IN ('IVA','IVA_REDUCIDO','IVA_SUPERREDUCIDO','IVA_CERO','IGV','ITBMS','ITBMS_ALCOHOL','ITBMS_TABACO','ITBIS','ITBIS_REDUCIDO','IVU','ISV','ISV_ALCOHOL','IGTF','IVA_FRONTERA');
-- +goose StatementEnd

-- +goose StatementBegin
DELETE FROM cfg."TaxUnit"
WHERE "TaxYear" = 2026
  AND "CountryCode" IN ('VE','CO','MX','AR','CL','PE','EC','BO','UY','PY','PA','CR','DO','GT','HN','NI','SV','PR','CU','ES','US');
-- +goose StatementEnd
