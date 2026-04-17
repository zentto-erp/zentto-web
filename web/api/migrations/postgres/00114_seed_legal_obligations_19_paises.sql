-- +goose Up

-- Seed hr.LegalObligation para 19 paises.
-- Aportes patronales y del empleado (seguridad social, salud, pension, vivienda).
-- Tasas vigentes 2026 segun legislacion de cada pais.
-- Excluye ES (cubierto por migracion del agente Espana).
-- Fuente: autoridades laborales (IVSS, AFIP/ANSES, DIAN, IMSS, SUNAT, IESS, Superintendencia AFP, BPS, IPS, CSS, CCSS, TSS, IGSS, IHSS, INSS, ISSS, SSA/IRS).
-- Idempotente: DELETE + INSERT.

-- +goose StatementBegin
DELETE FROM hr."LegalObligation"
WHERE "CountryCode" IN ('VE','CO','MX','AR','CL','PE','EC','BO','UY','PY','PA','CR','DO','GT','HN','NI','SV','PR','CU','US');
-- +goose StatementEnd

-- Venezuela (IVSS, BANAVIH, INCES, Paro Forzoso)
-- +goose StatementBegin
INSERT INTO hr."LegalObligation" ("LegalObligationId","CountryCode","Code","Name","InstitutionName","ObligationType","CalculationBasis","EmployerRate","EmployeeRate","FilingFrequency","EffectiveFrom","IsActive") VALUES
  (nextval('hr."LegalObligation_LegalObligationId_seq"'),'VE','IVSS',        'Seguro Social',                 'IVSS',                          'SOCIAL',  'SALARY', 0.09000, 0.04000, 'MONTHLY', '2026-01-01', TRUE),
  (nextval('hr."LegalObligation_LegalObligationId_seq"'),'VE','RPE',         'Regimen Prestacional Empleo',   'IVSS Paro Forzoso',             'SOCIAL',  'SALARY', 0.02000, 0.00500, 'MONTHLY', '2026-01-01', TRUE),
  (nextval('hr."LegalObligation_LegalObligationId_seq"'),'VE','LPH',         'Ley Politica Habitacional',     'BANAVIH',                       'HOUSING', 'SALARY', 0.02000, 0.01000, 'MONTHLY', '2026-01-01', TRUE),
  (nextval('hr."LegalObligation_LegalObligationId_seq"'),'VE','INCES',       'Aporte INCES',                  'INCES',                         'SOCIAL',  'SALARY', 0.02000, 0.00500, 'QUARTERLY','2026-01-01', TRUE);
-- +goose StatementEnd

-- Argentina (SIPA, Obra Social, PAMI, ART, Fondo Desempleo)
-- +goose StatementBegin
INSERT INTO hr."LegalObligation" ("LegalObligationId","CountryCode","Code","Name","InstitutionName","ObligationType","CalculationBasis","EmployerRate","EmployeeRate","RateVariableByRisk","FilingFrequency","EffectiveFrom","IsActive") VALUES
  (nextval('hr."LegalObligation_LegalObligationId_seq"'),'AR','SIPA',      'Jubilacion y Pension',             'ANSES',              'SOCIAL', 'SALARY', 0.16000, 0.11000, FALSE, 'MONTHLY', '2026-01-01', TRUE),
  (nextval('hr."LegalObligation_LegalObligationId_seq"'),'AR','OS',        'Obra Social',                      'Obras Sociales',     'HEALTH', 'SALARY', 0.06000, 0.03000, FALSE, 'MONTHLY', '2026-01-01', TRUE),
  (nextval('hr."LegalObligation_LegalObligationId_seq"'),'AR','PAMI',      'Instituto Nacional Jubilados',     'PAMI INSSJP',        'HEALTH', 'SALARY', 0.02000, 0.03000, FALSE, 'MONTHLY', '2026-01-01', TRUE),
  (nextval('hr."LegalObligation_LegalObligationId_seq"'),'AR','ART',       'Aseguradora Riesgos Trabajo',      'ART',                'SOCIAL', 'SALARY', 0.02500, 0.00000, TRUE,  'MONTHLY', '2026-01-01', TRUE),
  (nextval('hr."LegalObligation_LegalObligationId_seq"'),'AR','FNE',       'Fondo Nacional de Empleo',         'ANSES',              'SOCIAL', 'SALARY', 0.01500, 0.00000, FALSE, 'MONTHLY', '2026-01-01', TRUE);
-- +goose StatementEnd

-- Colombia (Salud EPS, Pension, ARL, Parafiscales SENA/ICBF/Caja)
-- +goose StatementBegin
INSERT INTO hr."LegalObligation" ("LegalObligationId","CountryCode","Code","Name","InstitutionName","ObligationType","CalculationBasis","EmployerRate","EmployeeRate","RateVariableByRisk","FilingFrequency","EffectiveFrom","IsActive") VALUES
  (nextval('hr."LegalObligation_LegalObligationId_seq"'),'CO','SALUD',    'Salud',                           'EPS',                 'HEALTH', 'SALARY', 0.08500, 0.04000, FALSE, 'MONTHLY', '2026-01-01', TRUE),
  (nextval('hr."LegalObligation_LegalObligationId_seq"'),'CO','PENSION',  'Pension',                         'Fondo Pensiones',     'SOCIAL', 'SALARY', 0.12000, 0.04000, FALSE, 'MONTHLY', '2026-01-01', TRUE),
  (nextval('hr."LegalObligation_LegalObligationId_seq"'),'CO','ARL',      'Riesgos Laborales',               'ARL',                 'SOCIAL', 'SALARY', 0.00522, 0.00000, TRUE,  'MONTHLY', '2026-01-01', TRUE),
  (nextval('hr."LegalObligation_LegalObligationId_seq"'),'CO','SENA',     'Aporte Parafiscal SENA',          'SENA',                'SOCIAL', 'SALARY', 0.02000, 0.00000, FALSE, 'MONTHLY', '2026-01-01', TRUE),
  (nextval('hr."LegalObligation_LegalObligationId_seq"'),'CO','ICBF',     'Aporte Parafiscal ICBF',          'ICBF',                'SOCIAL', 'SALARY', 0.03000, 0.00000, FALSE, 'MONTHLY', '2026-01-01', TRUE),
  (nextval('hr."LegalObligation_LegalObligationId_seq"'),'CO','CCF',      'Caja de Compensacion Familiar',   'Caja Compensacion',   'SOCIAL', 'SALARY', 0.04000, 0.00000, FALSE, 'MONTHLY', '2026-01-01', TRUE);
-- +goose StatementEnd

-- Mexico (IMSS Cuotas Obrero-Patronales, INFONAVIT, SAR/AFORE)
-- +goose StatementBegin
INSERT INTO hr."LegalObligation" ("LegalObligationId","CountryCode","Code","Name","InstitutionName","ObligationType","CalculationBasis","EmployerRate","EmployeeRate","FilingFrequency","EffectiveFrom","IsActive") VALUES
  (nextval('hr."LegalObligation_LegalObligationId_seq"'),'MX','IMSS',      'Cuotas Obrero-Patronales IMSS',  'IMSS',      'SOCIAL',  'SALARY', 0.17150, 0.02375, 'MONTHLY',    '2026-01-01', TRUE),
  (nextval('hr."LegalObligation_LegalObligationId_seq"'),'MX','INFONAVIT', 'Aporte Vivienda INFONAVIT',      'INFONAVIT', 'HOUSING', 'SALARY', 0.05000, 0.00000, 'BIMONTHLY',  '2026-01-01', TRUE),
  (nextval('hr."LegalObligation_LegalObligationId_seq"'),'MX','SAR',       'Sistema Ahorro Retiro',          'AFORE',     'SOCIAL',  'SALARY', 0.02000, 0.00000, 'BIMONTHLY',  '2026-01-01', TRUE);
-- +goose StatementEnd

-- Peru (EsSalud, ONP/AFP, SCTR)
-- +goose StatementBegin
INSERT INTO hr."LegalObligation" ("LegalObligationId","CountryCode","Code","Name","InstitutionName","ObligationType","CalculationBasis","EmployerRate","EmployeeRate","RateVariableByRisk","FilingFrequency","EffectiveFrom","IsActive") VALUES
  (nextval('hr."LegalObligation_LegalObligationId_seq"'),'PE','ESSALUD', 'Seguro Social de Salud',          'EsSalud',       'HEALTH', 'SALARY', 0.09000, 0.00000, FALSE, 'MONTHLY', '2026-01-01', TRUE),
  (nextval('hr."LegalObligation_LegalObligationId_seq"'),'PE','ONP',     'Sistema Nacional de Pensiones',   'ONP',           'SOCIAL', 'SALARY', 0.00000, 0.13000, FALSE, 'MONTHLY', '2026-01-01', TRUE),
  (nextval('hr."LegalObligation_LegalObligationId_seq"'),'PE','AFP',     'AFP Capitalizacion Individual',   'AFP',           'SOCIAL', 'SALARY', 0.00000, 0.10000, FALSE, 'MONTHLY', '2026-01-01', TRUE),
  (nextval('hr."LegalObligation_LegalObligationId_seq"'),'PE','SCTR',    'Seguro Complementario Riesgo',    'EsSalud/Privada','SOCIAL','SALARY', 0.01500, 0.00000, TRUE,  'MONTHLY', '2026-01-01', TRUE);
-- +goose StatementEnd

-- Ecuador (IESS)
-- +goose StatementBegin
INSERT INTO hr."LegalObligation" ("LegalObligationId","CountryCode","Code","Name","InstitutionName","ObligationType","CalculationBasis","EmployerRate","EmployeeRate","FilingFrequency","EffectiveFrom","IsActive") VALUES
  (nextval('hr."LegalObligation_LegalObligationId_seq"'),'EC','IESS_PAT',  'Aporte Patronal IESS',         'IESS',  'SOCIAL', 'SALARY', 0.11150, 0.00000, 'MONTHLY', '2026-01-01', TRUE),
  (nextval('hr."LegalObligation_LegalObligationId_seq"'),'EC','IESS_IND',  'Aporte Individual IESS',       'IESS',  'SOCIAL', 'SALARY', 0.00000, 0.09450, 'MONTHLY', '2026-01-01', TRUE),
  (nextval('hr."LegalObligation_LegalObligationId_seq"'),'EC','FR',        'Fondo de Reserva',             'IESS',  'SOCIAL', 'SALARY', 0.08330, 0.00000, 'MONTHLY', '2026-01-01', TRUE);
-- +goose StatementEnd

-- Chile (AFP, Fonasa/Isapre, Seguro Cesantia, SIS, Mutualidad)
-- +goose StatementBegin
INSERT INTO hr."LegalObligation" ("LegalObligationId","CountryCode","Code","Name","InstitutionName","ObligationType","CalculationBasis","EmployerRate","EmployeeRate","RateVariableByRisk","FilingFrequency","EffectiveFrom","IsActive") VALUES
  (nextval('hr."LegalObligation_LegalObligationId_seq"'),'CL','AFP',      'Capitalizacion Individual AFP','AFP',               'SOCIAL', 'SALARY', 0.00000, 0.11480, FALSE, 'MONTHLY', '2026-01-01', TRUE),
  (nextval('hr."LegalObligation_LegalObligationId_seq"'),'CL','FONASA',   'Salud FONASA o Isapre',        'FONASA/Isapre',     'HEALTH', 'SALARY', 0.00000, 0.07000, FALSE, 'MONTHLY', '2026-01-01', TRUE),
  (nextval('hr."LegalObligation_LegalObligationId_seq"'),'CL','CES_IND',  'Seguro Cesantia Indefinido',   'AFC',               'SOCIAL', 'SALARY', 0.02400, 0.00600, FALSE, 'MONTHLY', '2026-01-01', TRUE),
  (nextval('hr."LegalObligation_LegalObligationId_seq"'),'CL','SIS',      'Seguro Invalidez y Sobreviven','AFP',               'SOCIAL', 'SALARY', 0.01880, 0.00000, FALSE, 'MONTHLY', '2026-01-01', TRUE),
  (nextval('hr."LegalObligation_LegalObligationId_seq"'),'CL','MUT',      'Mutualidad Accidentes Trabajo','ACHS/Mutual/IST',   'SOCIAL', 'SALARY', 0.01530, 0.00000, TRUE,  'MONTHLY', '2026-01-01', TRUE);
-- +goose StatementEnd

-- Bolivia (CNS, AFP AP/AN/CI, Pro-Vivienda, Aporte Solidario)
-- +goose StatementBegin
INSERT INTO hr."LegalObligation" ("LegalObligationId","CountryCode","Code","Name","InstitutionName","ObligationType","CalculationBasis","EmployerRate","EmployeeRate","FilingFrequency","EffectiveFrom","IsActive") VALUES
  (nextval('hr."LegalObligation_LegalObligationId_seq"'),'BO','CNS',      'Caja Nacional de Salud',       'CNS',         'HEALTH',  'SALARY', 0.10000, 0.00000, 'MONTHLY', '2026-01-01', TRUE),
  (nextval('hr."LegalObligation_LegalObligationId_seq"'),'BO','AFP_CI',   'AFP Capitalizacion Individual','AFP',         'SOCIAL',  'SALARY', 0.00000, 0.10000, 'MONTHLY', '2026-01-01', TRUE),
  (nextval('hr."LegalObligation_LegalObligationId_seq"'),'BO','AFP_AS',   'Aporte Solidario',             'AFP',         'SOCIAL',  'SALARY', 0.03000, 0.00500, 'MONTHLY', '2026-01-01', TRUE),
  (nextval('hr."LegalObligation_LegalObligationId_seq"'),'BO','PROVIVIENDA','Pro-Vivienda',               'Pro-Vivienda','HOUSING', 'SALARY', 0.02000, 0.00000, 'MONTHLY', '2026-01-01', TRUE);
-- +goose StatementEnd

-- Uruguay (BPS, FONASA, FRL)
-- +goose StatementBegin
INSERT INTO hr."LegalObligation" ("LegalObligationId","CountryCode","Code","Name","InstitutionName","ObligationType","CalculationBasis","EmployerRate","EmployeeRate","FilingFrequency","EffectiveFrom","IsActive") VALUES
  (nextval('hr."LegalObligation_LegalObligationId_seq"'),'UY','BPS_JUB',  'Aporte Jubilatorio BPS',       'BPS',    'SOCIAL', 'SALARY', 0.07500, 0.15000, 'MONTHLY', '2026-01-01', TRUE),
  (nextval('hr."LegalObligation_LegalObligationId_seq"'),'UY','FONASA',   'Seguro Nacional de Salud',     'FONASA', 'HEALTH', 'SALARY', 0.05000, 0.04500, 'MONTHLY', '2026-01-01', TRUE),
  (nextval('hr."LegalObligation_LegalObligationId_seq"'),'UY','FRL',      'Fondo Reconversion Laboral',   'BPS',    'SOCIAL', 'SALARY', 0.00100, 0.00125, 'MONTHLY', '2026-01-01', TRUE);
-- +goose StatementEnd

-- Paraguay (IPS)
-- +goose StatementBegin
INSERT INTO hr."LegalObligation" ("LegalObligationId","CountryCode","Code","Name","InstitutionName","ObligationType","CalculationBasis","EmployerRate","EmployeeRate","FilingFrequency","EffectiveFrom","IsActive") VALUES
  (nextval('hr."LegalObligation_LegalObligationId_seq"'),'PY','IPS',      'Instituto Prevision Social',   'IPS',    'SOCIAL', 'SALARY', 0.16500, 0.09000, 'MONTHLY', '2026-01-01', TRUE);
-- +goose StatementEnd

-- Panama (CSS, Seguro Educativo, Riesgos Profesionales)
-- +goose StatementBegin
INSERT INTO hr."LegalObligation" ("LegalObligationId","CountryCode","Code","Name","InstitutionName","ObligationType","CalculationBasis","EmployerRate","EmployeeRate","RateVariableByRisk","FilingFrequency","EffectiveFrom","IsActive") VALUES
  (nextval('hr."LegalObligation_LegalObligationId_seq"'),'PA','CSS',      'Caja de Seguro Social',        'CSS',   'SOCIAL', 'SALARY', 0.12250, 0.09750, FALSE, 'MONTHLY', '2026-01-01', TRUE),
  (nextval('hr."LegalObligation_LegalObligationId_seq"'),'PA','SEDU',     'Seguro Educativo',             'CSS',   'SOCIAL', 'SALARY', 0.01500, 0.01250, FALSE, 'MONTHLY', '2026-01-01', TRUE),
  (nextval('hr."LegalObligation_LegalObligationId_seq"'),'PA','RPROF',    'Riesgos Profesionales',        'CSS',   'SOCIAL', 'SALARY', 0.01500, 0.00000, TRUE,  'MONTHLY', '2026-01-01', TRUE);
-- +goose StatementEnd

-- Costa Rica (CCSS, INS Riesgos)
-- +goose StatementBegin
INSERT INTO hr."LegalObligation" ("LegalObligationId","CountryCode","Code","Name","InstitutionName","ObligationType","CalculationBasis","EmployerRate","EmployeeRate","FilingFrequency","EffectiveFrom","IsActive") VALUES
  (nextval('hr."LegalObligation_LegalObligationId_seq"'),'CR','CCSS',     'Caja Costarricense Seguro Social','CCSS', 'SOCIAL', 'SALARY', 0.26670, 0.10670, 'MONTHLY', '2026-01-01', TRUE),
  (nextval('hr."LegalObligation_LegalObligationId_seq"'),'CR','INS',      'INS Riesgos del Trabajo',         'INS',  'SOCIAL', 'SALARY', 0.01000, 0.00000, 'MONTHLY', '2026-01-01', TRUE);
-- +goose StatementEnd

-- Republica Dominicana (TSS: SFS, AFP, SRL)
-- +goose StatementBegin
INSERT INTO hr."LegalObligation" ("LegalObligationId","CountryCode","Code","Name","InstitutionName","ObligationType","CalculationBasis","EmployerRate","EmployeeRate","FilingFrequency","EffectiveFrom","IsActive") VALUES
  (nextval('hr."LegalObligation_LegalObligationId_seq"'),'DO','SFS',      'Seguro Familiar de Salud',     'TSS',  'HEALTH', 'SALARY', 0.07090, 0.03040, 'MONTHLY', '2026-01-01', TRUE),
  (nextval('hr."LegalObligation_LegalObligationId_seq"'),'DO','AFP',      'Fondo de Pensiones',           'TSS',  'SOCIAL', 'SALARY', 0.07100, 0.02870, 'MONTHLY', '2026-01-01', TRUE),
  (nextval('hr."LegalObligation_LegalObligationId_seq"'),'DO','SRL',      'Seguro de Riesgos Laborales',  'TSS',  'SOCIAL', 'SALARY', 0.01300, 0.00000, 'MONTHLY', '2026-01-01', TRUE);
-- +goose StatementEnd

-- Guatemala (IGSS, IRTRA, INTECAP)
-- +goose StatementBegin
INSERT INTO hr."LegalObligation" ("LegalObligationId","CountryCode","Code","Name","InstitutionName","ObligationType","CalculationBasis","EmployerRate","EmployeeRate","FilingFrequency","EffectiveFrom","IsActive") VALUES
  (nextval('hr."LegalObligation_LegalObligationId_seq"'),'GT','IGSS',     'Instituto Guatemalteco Seguridad Social','IGSS',   'SOCIAL', 'SALARY', 0.10670, 0.04830, 'MONTHLY', '2026-01-01', TRUE),
  (nextval('hr."LegalObligation_LegalObligationId_seq"'),'GT','IRTRA',    'Recreacion Trabajadores',                 'IRTRA',  'SOCIAL', 'SALARY', 0.01000, 0.00000, 'MONTHLY', '2026-01-01', TRUE),
  (nextval('hr."LegalObligation_LegalObligationId_seq"'),'GT','INTECAP',  'Capacitacion y Productividad',            'INTECAP','SOCIAL', 'SALARY', 0.01000, 0.00000, 'MONTHLY', '2026-01-01', TRUE);
-- +goose StatementEnd

-- Honduras (IHSS, RAP, INFOP)
-- +goose StatementBegin
INSERT INTO hr."LegalObligation" ("LegalObligationId","CountryCode","Code","Name","InstitutionName","ObligationType","CalculationBasis","EmployerRate","EmployeeRate","FilingFrequency","EffectiveFrom","IsActive") VALUES
  (nextval('hr."LegalObligation_LegalObligationId_seq"'),'HN','IHSS_EM',  'IHSS Enfermedad y Maternidad', 'IHSS',   'HEALTH',  'SALARY', 0.05000, 0.02500, 'MONTHLY', '2026-01-01', TRUE),
  (nextval('hr."LegalObligation_LegalObligationId_seq"'),'HN','IHSS_IVM', 'IHSS Invalidez Vejez Muerte',  'IHSS',   'SOCIAL',  'SALARY', 0.03500, 0.02500, 'MONTHLY', '2026-01-01', TRUE),
  (nextval('hr."LegalObligation_LegalObligationId_seq"'),'HN','RAP',      'Regimen Aportaciones Privado', 'RAP',    'HOUSING', 'SALARY', 0.01500, 0.01500, 'MONTHLY', '2026-01-01', TRUE),
  (nextval('hr."LegalObligation_LegalObligationId_seq"'),'HN','INFOP',    'Formacion Profesional',        'INFOP',  'SOCIAL',  'SALARY', 0.01000, 0.00000, 'MONTHLY', '2026-01-01', TRUE);
-- +goose StatementEnd

-- Nicaragua (INSS IVM, INSS VIC, INATEC)
-- +goose StatementBegin
INSERT INTO hr."LegalObligation" ("LegalObligationId","CountryCode","Code","Name","InstitutionName","ObligationType","CalculationBasis","EmployerRate","EmployeeRate","FilingFrequency","EffectiveFrom","IsActive") VALUES
  (nextval('hr."LegalObligation_LegalObligationId_seq"'),'NI','INSS',     'Regimen Integral INSS',        'INSS',    'SOCIAL', 'SALARY', 0.21500, 0.07000, 'MONTHLY', '2026-01-01', TRUE),
  (nextval('hr."LegalObligation_LegalObligationId_seq"'),'NI','INATEC',   'Instituto Nacional Tecnologico','INATEC', 'SOCIAL', 'SALARY', 0.02000, 0.00000, 'MONTHLY', '2026-01-01', TRUE);
-- +goose StatementEnd

-- El Salvador (ISSS, AFP, INPEP)
-- +goose StatementBegin
INSERT INTO hr."LegalObligation" ("LegalObligationId","CountryCode","Code","Name","InstitutionName","ObligationType","CalculationBasis","EmployerRate","EmployeeRate","FilingFrequency","EffectiveFrom","IsActive") VALUES
  (nextval('hr."LegalObligation_LegalObligationId_seq"'),'SV','ISSS',     'Instituto Salvadoreno Seguro Social','ISSS','HEALTH', 'SALARY', 0.07500, 0.03000, 'MONTHLY', '2026-01-01', TRUE),
  (nextval('hr."LegalObligation_LegalObligationId_seq"'),'SV','AFP',      'Administradora Fondos Pensiones',    'AFP', 'SOCIAL', 'SALARY', 0.07750, 0.07250, 'MONTHLY', '2026-01-01', TRUE);
-- +goose StatementEnd

-- Cuba (Seguridad Social estatal)
-- +goose StatementBegin
INSERT INTO hr."LegalObligation" ("LegalObligationId","CountryCode","Code","Name","InstitutionName","ObligationType","CalculationBasis","EmployerRate","EmployeeRate","FilingFrequency","EffectiveFrom","IsActive") VALUES
  (nextval('hr."LegalObligation_LegalObligationId_seq"'),'CU','SS',       'Seguridad Social',             'INASS',  'SOCIAL', 'SALARY', 0.12500, 0.00000, 'MONTHLY', '2026-01-01', TRUE);
-- +goose StatementEnd

-- Puerto Rico (FICA Social Security, Medicare, FUTA, SUTA, SINOT)
-- +goose StatementBegin
INSERT INTO hr."LegalObligation" ("LegalObligationId","CountryCode","Code","Name","InstitutionName","ObligationType","CalculationBasis","EmployerRate","EmployeeRate","FilingFrequency","EffectiveFrom","IsActive") VALUES
  (nextval('hr."LegalObligation_LegalObligationId_seq"'),'PR','FICA',     'FICA Social Security',         'SSA',             'SOCIAL', 'SALARY', 0.06200, 0.06200, 'QUARTERLY', '2026-01-01', TRUE),
  (nextval('hr."LegalObligation_LegalObligationId_seq"'),'PR','MEDICARE', 'Medicare',                     'IRS',             'HEALTH', 'SALARY', 0.01450, 0.01450, 'QUARTERLY', '2026-01-01', TRUE),
  (nextval('hr."LegalObligation_LegalObligationId_seq"'),'PR','FUTA',     'Federal Unemployment Tax',     'IRS',             'SOCIAL', 'SALARY', 0.00600, 0.00000, 'QUARTERLY', '2026-01-01', TRUE),
  (nextval('hr."LegalObligation_LegalObligationId_seq"'),'PR','SINOT',    'Seguro Incapacidad No Ocupacional','Dept. Trabajo','HEALTH','SALARY', 0.00300, 0.00300, 'QUARTERLY', '2026-01-01', TRUE);
-- +goose StatementEnd

-- Estados Unidos (FICA, Medicare, FUTA, SUTA variable por estado)
-- +goose StatementBegin
INSERT INTO hr."LegalObligation" ("LegalObligationId","CountryCode","Code","Name","InstitutionName","ObligationType","CalculationBasis","EmployerRate","EmployeeRate","RateVariableByRisk","FilingFrequency","EffectiveFrom","IsActive") VALUES
  (nextval('hr."LegalObligation_LegalObligationId_seq"'),'US','FICA',     'FICA Social Security',         'SSA',     'SOCIAL', 'SALARY', 0.06200, 0.06200, FALSE, 'QUARTERLY', '2026-01-01', TRUE),
  (nextval('hr."LegalObligation_LegalObligationId_seq"'),'US','MEDICARE', 'Medicare',                     'IRS',     'HEALTH', 'SALARY', 0.01450, 0.01450, FALSE, 'QUARTERLY', '2026-01-01', TRUE),
  (nextval('hr."LegalObligation_LegalObligationId_seq"'),'US','FUTA',     'Federal Unemployment Tax Act', 'IRS',     'SOCIAL', 'SALARY', 0.00600, 0.00000, FALSE, 'QUARTERLY', '2026-01-01', TRUE),
  (nextval('hr."LegalObligation_LegalObligationId_seq"'),'US','SUTA',     'State Unemployment Tax',       'State',   'SOCIAL', 'SALARY', 0.03000, 0.00000, TRUE,  'QUARTERLY', '2026-01-01', TRUE);
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
DELETE FROM hr."LegalObligation"
WHERE "CountryCode" IN ('VE','CO','MX','AR','CL','PE','EC','BO','UY','PY','PA','CR','DO','GT','HN','NI','SV','PR','CU','US');
-- +goose StatementEnd
