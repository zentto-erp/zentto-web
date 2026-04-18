-- +goose Up

-- ESPAÑA — CNAE (Codigo Nacional Actividades Economicas) + conceptos nomina ES
-- Fuente CNAE: RD 475/2007 (CNAE-2009, vigente).
-- Fuente conceptos: Ley Estatuto Trabajadores + Orden cotizacion.

-- ─── Tabla: cfg.ActivityCode (CNAE) ──────────────────────────────────
-- +goose StatementBegin
CREATE TABLE IF NOT EXISTS cfg."ActivityCode" (
  "ActivityCodeId"  INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  "CountryCode"     CHAR(2) NOT NULL REFERENCES cfg."Country"("CountryCode"),
  "Code"            VARCHAR(20) NOT NULL,
  "Level"           VARCHAR(20) NOT NULL,
  "ParentCode"      VARCHAR(20),
  "Description"     VARCHAR(300) NOT NULL,
  "Classification"  VARCHAR(50),
  "SortOrder"       INTEGER NOT NULL DEFAULT 0,
  "IsActive"        BOOLEAN NOT NULL DEFAULT TRUE,
  "CreatedAt"       TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  CONSTRAINT "UQ_cfg_ActivityCode" UNIQUE ("CountryCode","Code")
);
-- +goose StatementEnd

-- ─── Seed: CNAE-2009 secciones (nivel A-U) + divisiones principales ──
-- +goose StatementBegin
DELETE FROM cfg."ActivityCode" WHERE "CountryCode" = 'ES';
-- +goose StatementEnd

-- Secciones CNAE (21 secciones A-U)
-- +goose StatementBegin
INSERT INTO cfg."ActivityCode" ("CountryCode","Code","Level","Description","Classification","SortOrder","IsActive") VALUES
  ('ES','A','SECTION','Agricultura, ganaderia, silvicultura y pesca',              'CNAE-2009',  10, TRUE),
  ('ES','B','SECTION','Industrias extractivas',                                      'CNAE-2009',  20, TRUE),
  ('ES','C','SECTION','Industria manufacturera',                                     'CNAE-2009',  30, TRUE),
  ('ES','D','SECTION','Suministro de energia electrica, gas, vapor y aire',         'CNAE-2009',  40, TRUE),
  ('ES','E','SECTION','Suministro de agua, actividades de saneamiento',             'CNAE-2009',  50, TRUE),
  ('ES','F','SECTION','Construccion',                                                'CNAE-2009',  60, TRUE),
  ('ES','G','SECTION','Comercio al por mayor y al por menor; reparacion vehiculos', 'CNAE-2009',  70, TRUE),
  ('ES','H','SECTION','Transporte y almacenamiento',                                 'CNAE-2009',  80, TRUE),
  ('ES','I','SECTION','Hosteleria',                                                  'CNAE-2009',  90, TRUE),
  ('ES','J','SECTION','Informacion y comunicaciones',                                'CNAE-2009', 100, TRUE),
  ('ES','K','SECTION','Actividades financieras y de seguros',                        'CNAE-2009', 110, TRUE),
  ('ES','L','SECTION','Actividades inmobiliarias',                                   'CNAE-2009', 120, TRUE),
  ('ES','M','SECTION','Actividades profesionales, cientificas y tecnicas',           'CNAE-2009', 130, TRUE),
  ('ES','N','SECTION','Actividades administrativas y servicios auxiliares',          'CNAE-2009', 140, TRUE),
  ('ES','O','SECTION','Administracion Publica y defensa',                            'CNAE-2009', 150, TRUE),
  ('ES','P','SECTION','Educacion',                                                   'CNAE-2009', 160, TRUE),
  ('ES','Q','SECTION','Actividades sanitarias y de servicios sociales',              'CNAE-2009', 170, TRUE),
  ('ES','R','SECTION','Actividades artisticas, recreativas y de entretenimiento',    'CNAE-2009', 180, TRUE),
  ('ES','S','SECTION','Otros servicios',                                             'CNAE-2009', 190, TRUE),
  ('ES','T','SECTION','Actividades de los hogares como empleadores',                 'CNAE-2009', 200, TRUE),
  ('ES','U','SECTION','Actividades organizaciones extraterritoriales',               'CNAE-2009', 210, TRUE);
-- +goose StatementEnd

-- Divisiones principales (2 digitos) mas comunes por sector
-- +goose StatementBegin
INSERT INTO cfg."ActivityCode" ("CountryCode","Code","Level","ParentCode","Description","Classification","SortOrder","IsActive") VALUES
  ('ES','01','DIVISION','A','Agricultura, ganaderia, caza y servicios relacionados', 'CNAE-2009', 11, TRUE),
  ('ES','03','DIVISION','A','Pesca y acuicultura',                                   'CNAE-2009', 13, TRUE),
  ('ES','10','DIVISION','C','Industria de la alimentacion',                          'CNAE-2009', 31, TRUE),
  ('ES','11','DIVISION','C','Fabricacion de bebidas',                                'CNAE-2009', 32, TRUE),
  ('ES','41','DIVISION','F','Construccion de edificios',                             'CNAE-2009', 61, TRUE),
  ('ES','43','DIVISION','F','Actividades de construccion especializada',             'CNAE-2009', 63, TRUE),
  ('ES','45','DIVISION','G','Venta y reparacion de vehiculos',                       'CNAE-2009', 71, TRUE),
  ('ES','46','DIVISION','G','Comercio al por mayor',                                 'CNAE-2009', 72, TRUE),
  ('ES','47','DIVISION','G','Comercio al por menor',                                 'CNAE-2009', 73, TRUE),
  ('ES','55','DIVISION','I','Servicios de alojamiento',                              'CNAE-2009', 91, TRUE),
  ('ES','56','DIVISION','I','Servicios de comidas y bebidas (Restauracion)',         'CNAE-2009', 92, TRUE),
  ('ES','62','DIVISION','J','Programacion, consultoria informatica',                 'CNAE-2009',101, TRUE),
  ('ES','63','DIVISION','J','Servicios de informacion',                              'CNAE-2009',102, TRUE),
  ('ES','64','DIVISION','K','Servicios financieros',                                 'CNAE-2009',111, TRUE),
  ('ES','66','DIVISION','K','Actividades auxiliares a seguros',                      'CNAE-2009',113, TRUE),
  ('ES','68','DIVISION','L','Actividades inmobiliarias',                             'CNAE-2009',121, TRUE),
  ('ES','69','DIVISION','M','Actividades juridicas y contabilidad',                  'CNAE-2009',131, TRUE),
  ('ES','70','DIVISION','M','Consultoria de gestion empresarial',                    'CNAE-2009',132, TRUE),
  ('ES','73','DIVISION','M','Publicidad y estudios de mercado',                      'CNAE-2009',133, TRUE),
  ('ES','85','DIVISION','P','Educacion',                                             'CNAE-2009',161, TRUE),
  ('ES','86','DIVISION','Q','Actividades sanitarias',                                'CNAE-2009',171, TRUE),
  ('ES','96','DIVISION','S','Otros servicios personales',                            'CNAE-2009',191, TRUE);
-- +goose StatementEnd

-- ─── Tabla: hr.PayrollConceptTemplate (catalogo global por pais) ─────
-- hr.PayrollConcept ya existe pero es por CompanyId. Creamos un catalogo
-- de plantillas por pais que sirve como base para provisioning.
-- +goose StatementBegin
CREATE TABLE IF NOT EXISTS hr."PayrollConceptTemplate" (
  "TemplateId"        INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  "CountryCode"       CHAR(2) NOT NULL REFERENCES cfg."Country"("CountryCode"),
  "ConceptCode"       VARCHAR(20) NOT NULL,
  "ConceptName"       VARCHAR(120) NOT NULL,
  "ConceptType"       VARCHAR(15) NOT NULL,
  "ConceptClass"      VARCHAR(30),
  "Formula"           VARCHAR(500),
  "LegalReference"    VARCHAR(100),
  "AppliesToRegimen"  VARCHAR(30),
  "IsActive"          BOOLEAN NOT NULL DEFAULT TRUE,
  "SortOrder"         INTEGER NOT NULL DEFAULT 0,
  "CreatedAt"         TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  CONSTRAINT "UQ_hr_PCTemplate" UNIQUE ("CountryCode","ConceptCode")
);
-- +goose StatementEnd

-- ─── Seed: Conceptos nomina ES 2026 ──────────────────────────────────
-- +goose StatementBegin
DELETE FROM hr."PayrollConceptTemplate" WHERE "CountryCode" = 'ES';
-- +goose StatementEnd

-- +goose StatementBegin
INSERT INTO hr."PayrollConceptTemplate"
  ("CountryCode","ConceptCode","ConceptName","ConceptType","ConceptClass","LegalReference","AppliesToRegimen","SortOrder","IsActive")
VALUES
  -- Devengos / Asignaciones
  ('ES','SAL_BASE',        'Salario Base',                          'ASIGNACION','DEVENGO_SALARIAL',  'Art. 26.3 ET',          'GENERAL',    10, TRUE),
  ('ES','PLUS_CONVENIO',   'Plus de Convenio',                      'ASIGNACION','DEVENGO_SALARIAL',  'Convenio Colectivo',    'GENERAL',    20, TRUE),
  ('ES','PLUS_ANTIGUEDAD', 'Plus de Antiguedad',                    'ASIGNACION','DEVENGO_SALARIAL',  'Convenio Colectivo',    'GENERAL',    30, TRUE),
  ('ES','PAGA_VERANO',     'Paga Extraordinaria Verano',            'ASIGNACION','PAGA_EXTRA',        'Art. 31 ET',            'GENERAL',    40, TRUE),
  ('ES','PAGA_NAVIDAD',    'Paga Extraordinaria Navidad',           'ASIGNACION','PAGA_EXTRA',        'Art. 31 ET',            'GENERAL',    50, TRUE),
  ('ES','PLUS_TRANSPORTE', 'Plus Transporte',                       'ASIGNACION','DEVENGO_NOSAL',     'Art. 26.2 ET',          'GENERAL',    60, TRUE),
  ('ES','DIETAS',          'Dietas',                                'ASIGNACION','DEVENGO_NOSAL',     'Art. 26.2 ET',          'GENERAL',    70, TRUE),
  ('ES','PLUS_NOCTURNO',   'Plus Nocturnidad',                      'ASIGNACION','DEVENGO_SALARIAL',  'Art. 36 ET',            'GENERAL',    80, TRUE),
  ('ES','PLUS_PELIGROSO',  'Plus Peligrosidad',                     'ASIGNACION','DEVENGO_SALARIAL',  'Convenio Colectivo',    'GENERAL',    90, TRUE),
  ('ES','PLUS_TOXICIDAD',  'Plus Toxicidad',                        'ASIGNACION','DEVENGO_SALARIAL',  'Convenio Colectivo',    'GENERAL',   100, TRUE),
  ('ES','PLUS_IDIOMAS',    'Plus Idiomas',                          'ASIGNACION','DEVENGO_SALARIAL',  'Convenio Colectivo',    'GENERAL',   110, TRUE),
  ('ES','HORA_EXTRA_NORM', 'Hora Extra Normal',                     'ASIGNACION','HORA_EXTRA',        'Art. 35 ET',            'GENERAL',   120, TRUE),
  ('ES','HORA_EXTRA_FM',   'Hora Extra Fuerza Mayor',               'ASIGNACION','HORA_EXTRA',        'Art. 35 ET',            'GENERAL',   130, TRUE),
  ('ES','COMISIONES',      'Comisiones',                            'ASIGNACION','DEVENGO_SALARIAL',  'Art. 29 ET',            'GENERAL',   140, TRUE),
  ('ES','INCENTIVOS',      'Incentivos de Produccion',              'ASIGNACION','DEVENGO_SALARIAL',  'Convenio Colectivo',    'GENERAL',   150, TRUE),
  ('ES','IT_COMUNES',      'Incapacidad Temporal (Comunes)',        'ASIGNACION','IT',                'RD Legislativo 8/2015', 'GENERAL',   160, TRUE),
  ('ES','IT_ATEP',         'Incapacidad Temporal (AT/EP)',          'ASIGNACION','IT',                'RD Legislativo 8/2015', 'GENERAL',   170, TRUE),
  ('ES','MATERNIDAD',      'Prestacion Maternidad/Paternidad',      'ASIGNACION','PERMISO',           'Art. 177 LGSS',         'GENERAL',   180, TRUE),
  -- Deducciones
  ('ES','RET_IRPF',        'Retencion IRPF',                        'DEDUCCION', 'TRIBUTARIA',        'Ley 35/2006 IRPF',      'GENERAL',   500, TRUE),
  ('ES','COT_SS_COMUNES',  'Cotizacion SS Contingencias Comunes',   'DEDUCCION', 'SEGURIDAD_SOCIAL',  'Orden cotizacion',      'GENERAL',   510, TRUE),
  ('ES','COT_SS_DESEMP',   'Cotizacion SS Desempleo',               'DEDUCCION', 'SEGURIDAD_SOCIAL',  'Orden cotizacion',      'GENERAL',   520, TRUE),
  ('ES','COT_SS_FP',       'Cotizacion SS Formacion Profesional',   'DEDUCCION', 'SEGURIDAD_SOCIAL',  'Orden cotizacion',      'GENERAL',   530, TRUE),
  ('ES','COT_SS_MEI',      'Cotizacion Mecanismo Equidad Intergen', 'DEDUCCION', 'SEGURIDAD_SOCIAL',  'Ley 21/2021',           'GENERAL',   540, TRUE),
  ('ES','COT_SS_HORAS_EX', 'Cotizacion SS Horas Extras',            'DEDUCCION', 'SEGURIDAD_SOCIAL',  'Orden cotizacion',      'GENERAL',   550, TRUE),
  ('ES','ANTICIPO',        'Anticipo',                              'DEDUCCION', 'OTROS',             'Art. 29.1 ET',          'GENERAL',   560, TRUE),
  ('ES','PRESTAMO',        'Prestamo Empresa',                      'DEDUCCION', 'OTROS',             'Acuerdo privado',       'GENERAL',   570, TRUE),
  ('ES','EMBARGO',         'Embargo Judicial',                      'DEDUCCION', 'JUDICIAL',          'Art. 607 LEC',          'GENERAL',   580, TRUE),
  -- Finiquito e indemnizaciones
  ('ES','FINIQUITO',       'Finiquito',                             'ASIGNACION','FINIQUITO',         'Art. 49 ET',            'GENERAL',   900, TRUE),
  ('ES','INDEM_DESPIDO',   'Indemnizacion por Despido',             'ASIGNACION','INDEMNIZACION',     'Art. 56 ET',            'GENERAL',   910, TRUE),
  ('ES','INDEM_CESE',      'Indemnizacion por Cese',                'ASIGNACION','INDEMNIZACION',     'Art. 49 ET',            'GENERAL',   920, TRUE),
  ('ES','VACACIONES_NO_DISF','Vacaciones No Disfrutadas',           'ASIGNACION','FINIQUITO',         'Art. 38 ET',            'GENERAL',   930, TRUE);
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
DROP TABLE IF EXISTS hr."PayrollConceptTemplate";
DROP TABLE IF EXISTS cfg."ActivityCode";
-- +goose StatementEnd
