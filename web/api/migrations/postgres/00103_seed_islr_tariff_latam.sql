-- +goose Up

-- Seed de tablas ISLR/Impuesto a la Renta para paises LATAM.
-- La tabla fiscal.ISLRTariff ya soporta CountryCode — permite filtros por pais.
-- Cada pais usa su propia unidad (UT/UTM/UVT/UIT/BPC/moneda local),
-- por lo que BracketFrom/BracketTo son decimales genericos.
--
-- Datos 2026 verificados por busqueda web contra fuentes oficiales:
-- AR (ARCA), CL (SII), CO (DIAN), PE (SUNAT), EC (SRI), UY (DGI),
-- CR (Hacienda), MX (SAT Anexo 8 RMF), ES (AEAT), DO (DGII), US (IRS).
--
-- VE ya esta poblada por seed anterior (NO se toca).
-- Idempotente: DELETE previo por (CountryCode, TaxYear) + INSERT.

-- +goose StatementBegin
DELETE FROM fiscal."ISLRTariff"
WHERE "TaxYear" = 2026
  AND "CountryCode" IN ('AR', 'CL', 'CO', 'PE', 'EC', 'UY', 'CR', 'MX', 'ES', 'DO', 'BO', 'GT', 'HN', 'NI', 'PA', 'PY', 'SV', 'PR', 'CU', 'US');
-- +goose StatementEnd

-- ─── ARGENTINA (AR) — Ganancias Personas Fisicas (ARS anual) ─────────
-- Fuente: ARCA (ex-AFIP) Tabla Art 94 LIG ene-jun 2026
-- +goose StatementBegin
INSERT INTO fiscal."ISLRTariff" ("CountryCode", "TaxYear", "BracketFrom", "BracketTo", "Rate", "Subtrahend", "IsActive") VALUES
  ('AR', 2026, 0.00,        2000030.09,   5.00,  0.00,          TRUE),
  ('AR', 2026, 2000030.09,  4000060.18,   9.00,  100001.50,     TRUE),
  ('AR', 2026, 4000060.18,  6000090.27,  12.00,  220007.31,     TRUE),
  ('AR', 2026, 6000090.27, 12000180.54,  15.00,  400015.81,     TRUE),
  ('AR', 2026,12000180.54, 18000270.81,  19.00,  880030.25,     TRUE),
  ('AR', 2026,18000270.81, 36000541.62,  23.00, 1600053.28,     TRUE),
  ('AR', 2026,36000541.62, 54000812.43,  27.00, 3040074.81,     TRUE),
  ('AR', 2026,54000812.43, 60750913.96,  31.00, 5200102.56,     TRUE),
  ('AR', 2026,60750913.96, NULL,         35.00, 7630137.25,     TRUE);
-- +goose StatementEnd

-- ─── CHILE (CL) — Impuesto Unico 2da Categoria (en UTM mensual) ──────
-- Fuente: SII, Art 43 Ley Impuesto a la Renta
-- +goose StatementBegin
INSERT INTO fiscal."ISLRTariff" ("CountryCode", "TaxYear", "BracketFrom", "BracketTo", "Rate", "Subtrahend", "IsActive") VALUES
  ('CL', 2026,   0.00,  13.50,  0.00,  0.00,   TRUE),
  ('CL', 2026,  13.50,  30.00,  4.00,  0.54,   TRUE),
  ('CL', 2026,  30.00,  50.00,  8.00,  1.74,   TRUE),
  ('CL', 2026,  50.00,  70.00, 13.50,  4.49,   TRUE),
  ('CL', 2026,  70.00,  90.00, 23.00, 11.14,   TRUE),
  ('CL', 2026,  90.00, 120.00, 30.40, 17.80,   TRUE),
  ('CL', 2026, 120.00, 310.00, 35.00, 23.32,   TRUE),
  ('CL', 2026, 310.00, NULL,   40.00, 38.82,   TRUE);
-- +goose StatementEnd

-- ─── COLOMBIA (CO) — Renta Personas Naturales (en UVT anual) ─────────
-- Fuente: DIAN Art 241 Estatuto Tributario. UVT 2026 = COP $52.374
-- +goose StatementBegin
INSERT INTO fiscal."ISLRTariff" ("CountryCode", "TaxYear", "BracketFrom", "BracketTo", "Rate", "Subtrahend", "IsActive") VALUES
  ('CO', 2026,      0.00,   1090.00,  0.00,     0.00,   TRUE),
  ('CO', 2026,   1090.00,   1700.00, 19.00,   207.10,   TRUE),
  ('CO', 2026,   1700.00,   4100.00, 28.00,   360.10,   TRUE),
  ('CO', 2026,   4100.00,   8670.00, 33.00,   565.10,   TRUE),
  ('CO', 2026,   8670.00,  18970.00, 35.00,   738.50,   TRUE),
  ('CO', 2026,  18970.00,  31000.00, 37.00,  1117.90,   TRUE),
  ('CO', 2026,  31000.00,  NULL,     39.00,  1737.90,   TRUE);
-- +goose StatementEnd

-- ─── PERU (PE) — Renta 5ta Categoria (en UIT anual) ──────────────────
-- Fuente: SUNAT. UIT 2026 = S/ 5,500 (DS 316-2024-EF)
-- +goose StatementBegin
INSERT INTO fiscal."ISLRTariff" ("CountryCode", "TaxYear", "BracketFrom", "BracketTo", "Rate", "Subtrahend", "IsActive") VALUES
  ('PE', 2026,   0.00,   5.00,  8.00,   0.00,   TRUE),
  ('PE', 2026,   5.00,  20.00, 14.00,   0.30,   TRUE),
  ('PE', 2026,  20.00,  35.00, 17.00,   0.90,   TRUE),
  ('PE', 2026,  35.00,  45.00, 20.00,   1.95,   TRUE),
  ('PE', 2026,  45.00,  NULL, 30.00,   6.45,   TRUE);
-- +goose StatementEnd

-- ─── ECUADOR (EC) — Impuesto Renta (USD anual) ───────────────────────
-- Fuente: SRI Resolucion NAC-DGERCGC25-00000043
-- +goose StatementBegin
INSERT INTO fiscal."ISLRTariff" ("CountryCode", "TaxYear", "BracketFrom", "BracketTo", "Rate", "Subtrahend", "IsActive") VALUES
  ('EC', 2026,      0.00,  12208.00,  0.00,      0.00,  TRUE),
  ('EC', 2026,  12208.00,  15549.00,  5.00,    610.40,  TRUE),
  ('EC', 2026,  15549.00,  20188.00, 10.00,   1387.85,  TRUE),
  ('EC', 2026,  20188.00,  26366.00, 12.00,   1791.61,  TRUE),
  ('EC', 2026,  26366.00,  39648.00, 15.00,   2786.31,  TRUE),
  ('EC', 2026,  39648.00,  52905.00, 20.00,   4768.71,  TRUE),
  ('EC', 2026,  52905.00,  66157.00, 25.00,   7092.96,  TRUE),
  ('EC', 2026,  66157.00,  88147.00, 30.00,  10400.81,  TRUE),
  ('EC', 2026,  88147.00, 117471.00, 35.00,  14808.31,  TRUE),
  ('EC', 2026, 117471.00,      NULL, 37.00,  17157.23,  TRUE);
-- +goose StatementEnd

-- ─── URUGUAY (UY) — IRPF (en BPC mensual) ────────────────────────────
-- Fuente: DGI/BPS. BPC 2026 = UYU $6.864
-- +goose StatementBegin
INSERT INTO fiscal."ISLRTariff" ("CountryCode", "TaxYear", "BracketFrom", "BracketTo", "Rate", "Subtrahend", "IsActive") VALUES
  ('UY', 2026,   0.00,    7.00,  0.00,   0.00,   TRUE),
  ('UY', 2026,   7.00,   10.00, 10.00,   0.70,   TRUE),
  ('UY', 2026,  10.00,   15.00, 15.00,   1.20,   TRUE),
  ('UY', 2026,  15.00,   30.00, 24.00,   2.55,   TRUE),
  ('UY', 2026,  30.00,   50.00, 25.00,   2.85,   TRUE),
  ('UY', 2026,  50.00,   81.00, 27.00,   3.85,   TRUE),
  ('UY', 2026,  81.00,  115.00, 31.00,   7.09,   TRUE),
  ('UY', 2026, 115.00,   NULL,  36.00,  12.84,   TRUE);
-- +goose StatementEnd

-- ─── COSTA RICA (CR) — Impuesto Salario (CRC mensual) ────────────────
-- Fuente: Hacienda Decreto 45333-H
-- +goose StatementBegin
INSERT INTO fiscal."ISLRTariff" ("CountryCode", "TaxYear", "BracketFrom", "BracketTo", "Rate", "Subtrahend", "IsActive") VALUES
  ('CR', 2026,       0.00,   918000.00,   0.00,        0.00, TRUE),
  ('CR', 2026,  918000.00,  1352000.00,  10.00,    91800.00, TRUE),
  ('CR', 2026, 1352000.00,  2373000.00,  15.00,   159400.00, TRUE),
  ('CR', 2026, 2373000.00,  4745000.00,  20.00,   278050.00, TRUE),
  ('CR', 2026, 4745000.00,       NULL,   25.00,   515300.00, TRUE);
-- +goose StatementEnd

-- ─── BOLIVIA (BO) — RC-IVA (tasa unica 13%) ──────────────────────────
-- +goose StatementBegin
INSERT INTO fiscal."ISLRTariff" ("CountryCode", "TaxYear", "BracketFrom", "BracketTo", "Rate", "Subtrahend", "IsActive") VALUES
  ('BO', 2026, 0.00, NULL, 13.00, 0.00, TRUE);
-- +goose StatementEnd

-- ─── EL SALVADOR (SV) — ISR tramos (USD mensual) ─────────────────────
-- +goose StatementBegin
INSERT INTO fiscal."ISLRTariff" ("CountryCode", "TaxYear", "BracketFrom", "BracketTo", "Rate", "Subtrahend", "IsActive") VALUES
  ('SV', 2026,    0.00,  472.00,  0.00,   0.00,  TRUE),
  ('SV', 2026,  472.00,  895.24, 10.00,  17.67,  TRUE),
  ('SV', 2026,  895.24, 2038.10, 20.00, 107.19,  TRUE),
  ('SV', 2026, 2038.10,   NULL,  30.00, 311.00,  TRUE);
-- +goose StatementEnd

-- ─── PANAMA (PA) — Impuesto Renta (USD anual) ────────────────────────
-- +goose StatementBegin
INSERT INTO fiscal."ISLRTariff" ("CountryCode", "TaxYear", "BracketFrom", "BracketTo", "Rate", "Subtrahend", "IsActive") VALUES
  ('PA', 2026,      0.00,  11000.00,  0.00,     0.00, TRUE),
  ('PA', 2026,  11000.00,  50000.00, 15.00,  1650.00, TRUE),
  ('PA', 2026,  50000.00,    NULL,   25.00,  6650.00, TRUE);
-- +goose StatementEnd

-- ─── REPUBLICA DOMINICANA (DO) — ISR Asalariados (DOP anual) ─────────
-- +goose StatementBegin
INSERT INTO fiscal."ISLRTariff" ("CountryCode", "TaxYear", "BracketFrom", "BracketTo", "Rate", "Subtrahend", "IsActive") VALUES
  ('DO', 2026,       0.00,   416220.00,  0.00,        0.00, TRUE),
  ('DO', 2026,  416220.01,   624329.00, 15.00,    62433.00, TRUE),
  ('DO', 2026,  624329.01,   867123.00, 20.00,    93649.35, TRUE),
  ('DO', 2026,  867123.01,       NULL,  25.00,   137005.30, TRUE);
-- +goose StatementEnd

-- ─── GUATEMALA (GT) — ISR Asalariados (GTQ anual) ────────────────────
-- +goose StatementBegin
INSERT INTO fiscal."ISLRTariff" ("CountryCode", "TaxYear", "BracketFrom", "BracketTo", "Rate", "Subtrahend", "IsActive") VALUES
  ('GT', 2026,      0.00,  300000.00,  5.00,     0.00, TRUE),
  ('GT', 2026, 300000.00,      NULL,   7.00, 15000.00, TRUE);
-- +goose StatementEnd

-- ─── HONDURAS (HN) — ISR (HNL anual) ─────────────────────────────────
-- +goose StatementBegin
INSERT INTO fiscal."ISLRTariff" ("CountryCode", "TaxYear", "BracketFrom", "BracketTo", "Rate", "Subtrahend", "IsActive") VALUES
  ('HN', 2026,        0.00,   221472.20,   0.00,         0.00, TRUE),
  ('HN', 2026,   221472.20,   337423.26,  15.00,     33220.83, TRUE),
  ('HN', 2026,   337423.26,   784981.10,  20.00,     50091.99, TRUE),
  ('HN', 2026,   784981.10,       NULL,   25.00,    128590.10, TRUE);
-- +goose StatementEnd

-- ─── NICARAGUA (NI) — IR Asalariados (NIO anual) ─────────────────────
-- +goose StatementBegin
INSERT INTO fiscal."ISLRTariff" ("CountryCode", "TaxYear", "BracketFrom", "BracketTo", "Rate", "Subtrahend", "IsActive") VALUES
  ('NI', 2026,         0.00,   100000.00,   0.00,        0.00, TRUE),
  ('NI', 2026,    100000.00,   200000.00,  15.00,    15000.00, TRUE),
  ('NI', 2026,    200000.00,   350000.00,  20.00,    25000.00, TRUE),
  ('NI', 2026,    350000.00,   500000.00,  25.00,    42500.00, TRUE),
  ('NI', 2026,    500000.00,       NULL,   30.00,    67500.00, TRUE);
-- +goose StatementEnd

-- ─── PARAGUAY (PY) — IRP (PYG anual) ─────────────────────────────────
-- +goose StatementBegin
INSERT INTO fiscal."ISLRTariff" ("CountryCode", "TaxYear", "BracketFrom", "BracketTo", "Rate", "Subtrahend", "IsActive") VALUES
  ('PY', 2026,          0.00,   50000000.00,   8.00,         0.00, TRUE),
  ('PY', 2026,   50000000.00,  150000000.00,   9.00,    500000.00, TRUE),
  ('PY', 2026,  150000000.00,       NULL,     10.00,   2000000.00, TRUE);
-- +goose StatementEnd

-- ─── CUBA (CU) — Tasa unica 15% ──────────────────────────────────────
-- +goose StatementBegin
INSERT INTO fiscal."ISLRTariff" ("CountryCode", "TaxYear", "BracketFrom", "BracketTo", "Rate", "Subtrahend", "IsActive") VALUES
  ('CU', 2026, 0.00, NULL, 15.00, 0.00, TRUE);
-- +goose StatementEnd

-- ─── ESPANA (ES) — IRPF estatal (EUR anual) ──────────────────────────
-- +goose StatementBegin
INSERT INTO fiscal."ISLRTariff" ("CountryCode", "TaxYear", "BracketFrom", "BracketTo", "Rate", "Subtrahend", "IsActive") VALUES
  ('ES', 2026,      0.00,   12450.00,   9.50,      0.00,  TRUE),
  ('ES', 2026,  12450.00,   20200.00,  12.00,    311.25,  TRUE),
  ('ES', 2026,  20200.00,   35200.00,  15.00,    917.25,  TRUE),
  ('ES', 2026,  35200.00,   60000.00,  18.50,   2149.25,  TRUE),
  ('ES', 2026,  60000.00,  300000.00,  22.50,   4549.25,  TRUE),
  ('ES', 2026, 300000.00,      NULL,   24.50,  10549.25,  TRUE);
-- +goose StatementEnd

-- ─── ESTADOS UNIDOS (US) — Federal Single (USD anual) ────────────────
-- +goose StatementBegin
INSERT INTO fiscal."ISLRTariff" ("CountryCode", "TaxYear", "BracketFrom", "BracketTo", "Rate", "Subtrahend", "IsActive") VALUES
  ('US', 2026,      0.00,   11600.00,  10.00,      0.00,  TRUE),
  ('US', 2026,  11600.00,   47150.00,  12.00,    232.00,  TRUE),
  ('US', 2026,  47150.00,  100525.00,  22.00,   4948.50,  TRUE),
  ('US', 2026, 100525.00,  191950.00,  24.00,   6959.00,  TRUE),
  ('US', 2026, 191950.00,  243725.00,  32.00,  22313.00,  TRUE),
  ('US', 2026, 243725.00,  609350.00,  35.00,  29625.75,  TRUE),
  ('US', 2026, 609350.00,      NULL,   37.00,  41810.25,  TRUE);
-- +goose StatementEnd

-- ─── MEXICO (MX) — ISR Art 96 mensual (MXN) ──────────────────────────
-- Fuente: SAT Anexo 8 RMF 2026
-- +goose StatementBegin
INSERT INTO fiscal."ISLRTariff" ("CountryCode", "TaxYear", "BracketFrom", "BracketTo", "Rate", "Subtrahend", "IsActive") VALUES
  ('MX', 2026,       0.01,     8952.49,  1.92,       0.00, TRUE),
  ('MX', 2026,    8952.50,    75984.55,  6.40,     171.88, TRUE),
  ('MX', 2026,   75984.56,   133536.07, 10.88,    4461.94, TRUE),
  ('MX', 2026,  133536.08,   155229.80, 16.00,   11723.55, TRUE),
  ('MX', 2026,  155229.81,   185852.57, 17.92,   15194.16, TRUE),
  ('MX', 2026,  185852.58,   374837.88, 21.36,   20682.62, TRUE),
  ('MX', 2026,  374837.89,   590795.99, 23.52,   61130.52, TRUE),
  ('MX', 2026,  590795.99,  1127926.84, 30.00,  111901.62, TRUE),
  ('MX', 2026, 1127926.85,  1503902.46, 32.00,  273040.71, TRUE),
  ('MX', 2026, 1503902.47,  4511707.37, 34.00,  393353.74, TRUE),
  ('MX', 2026, 4511707.38,       NULL,  35.00, 1416007.62, TRUE);
-- +goose StatementEnd

-- ─── PUERTO RICO (PR) — Impuesto Ingresos (USD anual) ────────────────
-- +goose StatementBegin
INSERT INTO fiscal."ISLRTariff" ("CountryCode", "TaxYear", "BracketFrom", "BracketTo", "Rate", "Subtrahend", "IsActive") VALUES
  ('PR', 2026,      0.00,    9000.00,   0.00,      0.00, TRUE),
  ('PR', 2026,   9000.00,   25000.00,   7.00,    630.00, TRUE),
  ('PR', 2026,  25000.00,   41500.00,  14.00,   2380.00, TRUE),
  ('PR', 2026,  41500.00,   61500.00,  25.00,   6945.00, TRUE),
  ('PR', 2026,  61500.00,      NULL,   33.00,  11865.00, TRUE);
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
DELETE FROM fiscal."ISLRTariff"
WHERE "TaxYear" = 2026
  AND "CountryCode" IN ('AR', 'CL', 'CO', 'PE', 'EC', 'UY', 'CR', 'MX', 'ES', 'DO', 'BO', 'GT', 'HN', 'NI', 'PA', 'PY', 'SV', 'PR', 'CU', 'US');
-- +goose StatementEnd
