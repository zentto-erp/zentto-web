-- +goose Up

-- ESPAÑA — Tablas Seguridad Social + seed 2026
-- Fuente: Orden de cotizacion 2026 (BOE). Ministerio Inclusion.
-- Base maxima: 5101.20 EUR/mes. Base minima = SMI + 1/6.
-- Contingencias comunes: 28.30% (23.60 empresa + 4.70 trabajador).
-- MEI: 0.90% (0.75 empresa + 0.15 trabajador).
-- FOGASA, Desempleo, AT/EP variables.

-- ─── Tabla: hr.SocialSecurityGroup ───────────────────────────────────
-- +goose StatementBegin
CREATE TABLE IF NOT EXISTS hr."SocialSecurityGroup" (
  "GroupId"      INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  "CountryCode"  CHAR(2) NOT NULL REFERENCES cfg."Country"("CountryCode"),
  "GroupCode"    VARCHAR(5) NOT NULL,
  "GroupName"    VARCHAR(100) NOT NULL,
  "Description"  VARCHAR(300),
  "SortOrder"    INTEGER NOT NULL DEFAULT 0,
  "IsActive"     BOOLEAN NOT NULL DEFAULT TRUE,
  "CreatedAt"    TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"    TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  CONSTRAINT "UQ_hr_SSGroup" UNIQUE ("CountryCode","GroupCode")
);
-- +goose StatementEnd

-- ─── Tabla: hr.SocialSecurityRate ────────────────────────────────────
-- +goose StatementBegin
CREATE TABLE IF NOT EXISTS hr."SocialSecurityRate" (
  "RateId"        BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  "CountryCode"   CHAR(2) NOT NULL REFERENCES cfg."Country"("CountryCode"),
  "TaxYear"       INTEGER NOT NULL,
  "ContingencyCode" VARCHAR(20) NOT NULL,
  "ContingencyName" VARCHAR(100) NOT NULL,
  "EmployerRate"  NUMERIC(6,4) NOT NULL DEFAULT 0,
  "EmployeeRate"  NUMERIC(6,4) NOT NULL DEFAULT 0,
  "TotalRate"     NUMERIC(6,4) GENERATED ALWAYS AS ("EmployerRate" + "EmployeeRate") STORED,
  "AppliesTo"     VARCHAR(30) NOT NULL DEFAULT 'ALL',
  "Notes"         VARCHAR(300),
  "IsActive"      BOOLEAN NOT NULL DEFAULT TRUE,
  "CreatedAt"     TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  CONSTRAINT "UQ_hr_SSRate" UNIQUE ("CountryCode","TaxYear","ContingencyCode")
);
-- +goose StatementEnd

-- ─── Tabla: hr.SocialSecurityBase ────────────────────────────────────
-- +goose StatementBegin
CREATE TABLE IF NOT EXISTS hr."SocialSecurityBase" (
  "BaseId"       BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  "CountryCode"  CHAR(2) NOT NULL REFERENCES cfg."Country"("CountryCode"),
  "TaxYear"      INTEGER NOT NULL,
  "GroupCode"    VARCHAR(5) NOT NULL,
  "MinBase"      NUMERIC(18,2) NOT NULL,
  "MaxBase"      NUMERIC(18,2) NOT NULL,
  "EffectiveDate" DATE NOT NULL,
  "IsActive"     BOOLEAN NOT NULL DEFAULT TRUE,
  "CreatedAt"    TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  CONSTRAINT "UQ_hr_SSBase" UNIQUE ("CountryCode","TaxYear","GroupCode")
);
-- +goose StatementEnd

-- ─── Seed: 11 grupos de cotizacion ES ────────────────────────────────
-- +goose StatementBegin
DELETE FROM hr."SocialSecurityGroup" WHERE "CountryCode" = 'ES';
-- +goose StatementEnd

-- +goose StatementBegin
INSERT INTO hr."SocialSecurityGroup"
  ("CountryCode","GroupCode","GroupName","Description","SortOrder","IsActive")
VALUES
  ('ES','1','Ingenieros y Licenciados','Personal directivo alta direccion',                10, TRUE),
  ('ES','2','Ingenieros Tecnicos, Peritos y Ayudantes','Titulados',                         20, TRUE),
  ('ES','3','Jefes Administrativos y de Taller','Gerentes intermedios',                     30, TRUE),
  ('ES','4','Ayudantes no Titulados','Empleados operativos',                                40, TRUE),
  ('ES','5','Oficiales Administrativos','Administrativos',                                  50, TRUE),
  ('ES','6','Subalternos','Personal auxiliar',                                              60, TRUE),
  ('ES','7','Auxiliares Administrativos','Administrativos junior',                          70, TRUE),
  ('ES','8','Oficiales de Primera y Segunda','Operarios cualificados',                      80, TRUE),
  ('ES','9','Oficiales de Tercera y Especialistas','Operarios',                             90, TRUE),
  ('ES','10','Peones','Trabajadores no cualificados',                                      100, TRUE),
  ('ES','11','Trabajadores menores 18 años','Menores edad',                                110, TRUE);
-- +goose StatementEnd

-- ─── Seed: Tipos cotizacion 2026 ES ──────────────────────────────────
-- +goose StatementBegin
DELETE FROM hr."SocialSecurityRate" WHERE "CountryCode" = 'ES' AND "TaxYear" = 2026;
-- +goose StatementEnd

-- +goose StatementBegin
INSERT INTO hr."SocialSecurityRate"
  ("CountryCode","TaxYear","ContingencyCode","ContingencyName","EmployerRate","EmployeeRate","AppliesTo","Notes","IsActive")
VALUES
  ('ES',2026,'CONT_COMUNES',     'Contingencias Comunes',                 0.2360, 0.0470, 'ALL',        'Cotizacion principal SS',                              TRUE),
  ('ES',2026,'MEI',              'Mecanismo Equidad Intergeneracional',   0.0075, 0.0015, 'ALL',        'Sube desde 0.80% a 0.90% en 2026',                     TRUE),
  ('ES',2026,'DESEMPLEO_INDEF',  'Desempleo Contrato Indefinido',         0.0550, 0.0155, 'INDEFINIDO', 'Trabajadores con contrato indefinido',                 TRUE),
  ('ES',2026,'DESEMPLEO_TEMP',   'Desempleo Contrato Temporal',           0.0670, 0.0160, 'TEMPORAL',   'Trabajadores con contrato temporal',                   TRUE),
  ('ES',2026,'FORMACION_PROF',   'Formacion Profesional',                 0.0060, 0.0010, 'ALL',        'FP dual',                                              TRUE),
  ('ES',2026,'FOGASA',           'Fondo Garantia Salarial',               0.0020, 0.0000, 'ALL',        'Solo empresa',                                         TRUE),
  ('ES',2026,'AT_EP_MIN',        'Accidentes Trabajo/Enfermedad Prof (min)',0.0090,0.0000, 'ALL',        'Variable segun actividad 0.9%-7.15%',                  TRUE),
  ('ES',2026,'AT_EP_MAX',        'Accidentes Trabajo/Enfermedad Prof (max)',0.0715,0.0000, 'ALL',        'Actividades alto riesgo (mineria, construccion)',     TRUE),
  ('ES',2026,'HORAS_EXTRA_FM',   'Horas extras fuerza mayor',             0.1200, 0.0200, 'ALL',        'Solo por fuerza mayor',                                TRUE),
  ('ES',2026,'HORAS_EXTRA_OTRAS','Horas extras resto',                    0.2340, 0.0470, 'ALL',        'Horas extras no fuerza mayor',                         TRUE);
-- +goose StatementEnd

-- ─── Seed: Bases cotizacion 2026 por grupo ───────────────────────────
-- Base maxima: 5101.20 EUR/mes (igual para todos los grupos)
-- Base minima: varia por grupo (fuente BOE Orden cotizacion 2026)
-- +goose StatementBegin
DELETE FROM hr."SocialSecurityBase" WHERE "CountryCode" = 'ES' AND "TaxYear" = 2026;
-- +goose StatementEnd

-- +goose StatementBegin
INSERT INTO hr."SocialSecurityBase"
  ("CountryCode","TaxYear","GroupCode","MinBase","MaxBase","EffectiveDate","IsActive")
VALUES
  ('ES',2026,'1',  1847.40, 5101.20, '2026-01-01', TRUE),
  ('ES',2026,'2',  1532.40, 5101.20, '2026-01-01', TRUE),
  ('ES',2026,'3',  1332.90, 5101.20, '2026-01-01', TRUE),
  ('ES',2026,'4',  1323.00, 5101.20, '2026-01-01', TRUE),
  ('ES',2026,'5',  1323.00, 5101.20, '2026-01-01', TRUE),
  ('ES',2026,'6',  1323.00, 5101.20, '2026-01-01', TRUE),
  ('ES',2026,'7',  1323.00, 5101.20, '2026-01-01', TRUE),
  ('ES',2026,'8',    44.10,  170.04, '2026-01-01', TRUE),
  ('ES',2026,'9',    44.10,  170.04, '2026-01-01', TRUE),
  ('ES',2026,'10',   44.10,  170.04, '2026-01-01', TRUE),
  ('ES',2026,'11',   44.10,  170.04, '2026-01-01', TRUE);
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
DROP TABLE IF EXISTS hr."SocialSecurityBase";
DROP TABLE IF EXISTS hr."SocialSecurityRate";
DROP TABLE IF EXISTS hr."SocialSecurityGroup";
-- +goose StatementEnd
