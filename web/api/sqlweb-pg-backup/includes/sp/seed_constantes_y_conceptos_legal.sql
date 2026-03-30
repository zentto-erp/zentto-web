-- ============================================================
-- DatqBoxWeb PostgreSQL - seed_constantes_y_conceptos_legal.sql
-- Wrapper canonico: constantes nomina Venezuela + conceptos
-- legales por convenio (hr.PayrollConstant + hr.PayrollConcept)
-- ============================================================

-- ── PARTE 1: Constantes nomina Venezuela ──

DO $$
DECLARE
  v_CompanyId INT;
BEGIN
  SELECT "CompanyId" INTO v_CompanyId
  FROM cfg."Company"
  WHERE "IsDeleted" = FALSE
  ORDER BY CASE WHEN "CompanyCode" = 'DEFAULT' THEN 0 ELSE 1 END, "CompanyId"
  LIMIT 1;

  IF v_CompanyId IS NULL THEN
    RAISE EXCEPTION 'No existe cfg.Company activa para sembrar constantes nomina';
  END IF;

  -- Upsert constantes
  INSERT INTO hr."PayrollConstant" (
    "CompanyId", "ConstantCode", "ConstantName", "ConstantValue",
    "SourceName", "IsActive", "CreatedAt", "UpdatedAt"
  )
  VALUES
    (v_CompanyId, 'SALARIO_DIARIO',         'Salario diario base',            0.000000, 'VE_BASE', TRUE, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'),
    (v_CompanyId, 'HORAS_MES',              'Horas laborales mensuales',    240.000000, 'VE_BASE', TRUE, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'),
    (v_CompanyId, 'PCT_SSO',                'Porcentaje SSO empleado',        0.040000, 'VE_BASE', TRUE, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'),
    (v_CompanyId, 'PCT_FAOV',               'Porcentaje FAOV empleado',       0.010000, 'VE_BASE', TRUE, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'),
    (v_CompanyId, 'PCT_LRPE',               'Porcentaje LRPE empleado',       0.005000, 'VE_BASE', TRUE, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'),
    (v_CompanyId, 'RECARGO_HE',             'Recargo hora extra',             1.500000, 'VE_BASE', TRUE, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'),
    (v_CompanyId, 'RECARGO_NOCTURNO',       'Recargo nocturno',               1.300000, 'VE_BASE', TRUE, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'),
    (v_CompanyId, 'RECARGO_DESCANSO',       'Recargo descanso trabajado',     1.500000, 'VE_BASE', TRUE, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'),
    (v_CompanyId, 'RECARGO_FERIADO',        'Recargo feriado trabajado',      2.000000, 'VE_BASE', TRUE, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'),
    (v_CompanyId, 'DIAS_VACACIONES_BASE',   'Dias vacaciones base',          15.000000, 'VE_BASE', TRUE, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'),
    (v_CompanyId, 'DIAS_BONO_VAC_BASE',     'Dias bono vacacional base',     15.000000, 'VE_BASE', TRUE, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'),
    (v_CompanyId, 'DIAS_UTILIDADES_MIN',    'Dias utilidades minimo',        30.000000, 'VE_BASE', TRUE, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'),
    (v_CompanyId, 'DIAS_UTILIDADES_MAX',    'Dias utilidades maximo',       120.000000, 'VE_BASE', TRUE, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'),
    (v_CompanyId, 'PREST_DIAS_ANIO',        'Dias prestaciones por ano',     30.000000, 'VE_BASE', TRUE, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'),
    (v_CompanyId, 'PREST_INTERES_ANUAL',    'Interes anual prestaciones',     0.150000, 'VE_BASE', TRUE, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'),

    (v_CompanyId, 'LOT_DIAS_VACACIONES_BASE', 'LOTTT: dias vacaciones base',   15.000000, 'REGIMEN:LOT',   TRUE, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'),
    (v_CompanyId, 'LOT_DIAS_BONO_VAC_BASE',   'LOTTT: dias bono vacacional base', 15.000000, 'REGIMEN:LOT', TRUE, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'),
    (v_CompanyId, 'LOT_DIAS_UTILIDADES',       'LOTTT: dias utilidades referencia', 30.000000, 'REGIMEN:LOT', TRUE, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'),

    (v_CompanyId, 'PETRO_DIAS_VACACIONES_BASE', 'Petrolero: dias vacaciones base',  34.000000, 'REGIMEN:PETRO', TRUE, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'),
    (v_CompanyId, 'PETRO_DIAS_BONO_VAC_BASE',   'Petrolero: bono vacacional base',  55.000000, 'REGIMEN:PETRO', TRUE, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'),
    (v_CompanyId, 'PETRO_DIAS_UTILIDADES',       'Petrolero: dias utilidades',      120.000000, 'REGIMEN:PETRO', TRUE, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'),

    (v_CompanyId, 'CONST_DIAS_VACACIONES_BASE', 'Construccion: dias vacaciones base', 20.000000, 'REGIMEN:CONST', TRUE, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'),
    (v_CompanyId, 'CONST_DIAS_BONO_VAC_BASE',   'Construccion: bono vacacional base', 30.000000, 'REGIMEN:CONST', TRUE, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'),
    (v_CompanyId, 'CONST_DIAS_UTILIDADES',       'Construccion: dias utilidades',      60.000000, 'REGIMEN:CONST', TRUE, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC')
  ON CONFLICT ("CompanyId", "ConstantCode") DO UPDATE SET
    "ConstantName"  = EXCLUDED."ConstantName",
    "ConstantValue" = EXCLUDED."ConstantValue",
    "SourceName"    = EXCLUDED."SourceName",
    "IsActive"      = TRUE,
    "UpdatedAt"     = NOW() AT TIME ZONE 'UTC';

  RAISE NOTICE 'Constantes de nomina Venezuela sembradas/actualizadas en hr.PayrollConstant';
END $$;

-- ── PARTE 2: Conceptos por convenio ──

DO $$
DECLARE
  v_CompanyId INT;
BEGIN
  SELECT "CompanyId" INTO v_CompanyId
  FROM cfg."Company"
  WHERE "IsDeleted" = FALSE
  ORDER BY CASE WHEN "CompanyCode" = 'DEFAULT' THEN 0 ELSE 1 END, "CompanyId"
  LIMIT 1;

  IF v_CompanyId IS NULL THEN
    RAISE EXCEPTION 'No existe cfg.Company activa para sembrar conceptos nomina';
  END IF;

  -- Upsert PayrollType
  INSERT INTO hr."PayrollType" (
    "CompanyId", "PayrollCode", "PayrollName", "IsActive", "CreatedAt", "UpdatedAt"
  )
  VALUES
    (v_CompanyId, 'LOT',   'Nomina LOTTT',          TRUE, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'),
    (v_CompanyId, 'PETRO', 'Nomina CCT Petrolero',  TRUE, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'),
    (v_CompanyId, 'CONST', 'Nomina Construccion',    TRUE, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC')
  ON CONFLICT ("CompanyId", "PayrollCode") DO UPDATE SET
    "PayrollName" = EXCLUDED."PayrollName",
    "IsActive"    = TRUE,
    "UpdatedAt"   = NOW() AT TIME ZONE 'UTC';

  -- Upsert PayrollConcept
  INSERT INTO hr."PayrollConcept" (
    "CompanyId", "PayrollCode", "ConceptCode", "ConceptName", "Formula",
    "BaseExpression", "ConceptClass", "ConceptType", "UsageType",
    "IsBonifiable", "IsSeniority", "AccountingAccountCode", "AppliesFlag",
    "DefaultValue", "ConventionCode", "CalculationType", "LotttArticle",
    "CcpClause", "SortOrder", "IsActive", "CreatedAt", "UpdatedAt"
  )
  VALUES
    -- LOTTT mensual
    (v_CompanyId, 'LOT', 'ASIG_BASE', 'Salario base mensual',  'SUELDO',                     NULL, 'SALARIO',     'ASIGNACION', 'T', TRUE,  FALSE, NULL, TRUE, 0.00, 'LOT', 'MENSUAL',     NULL, NULL, 10, TRUE, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'),
    (v_CompanyId, 'LOT', 'DED_SSO',   'Deduccion SSO',         'SUELDO * PCT_SSO',            NULL, 'LEGAL',       'DEDUCCION',  'T', FALSE, FALSE, NULL, TRUE, 0.00, 'LOT', 'MENSUAL',     NULL, NULL, 90, TRUE, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'),
    (v_CompanyId, 'LOT', 'DED_FAOV',  'Deduccion FAOV',        'TOTAL_ASIGNACIONES * PCT_FAOV', NULL, 'LEGAL',     'DEDUCCION',  'T', FALSE, FALSE, NULL, TRUE, 0.00, 'LOT', 'MENSUAL',     NULL, NULL, 91, TRUE, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'),
    (v_CompanyId, 'LOT', 'DED_LRPE',  'Deduccion LRPE',        'SUELDO * PCT_LRPE',           NULL, 'LEGAL',       'DEDUCCION',  'T', FALSE, FALSE, NULL, TRUE, 0.00, 'LOT', 'MENSUAL',     NULL, NULL, 92, TRUE, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'),

    -- LOTTT vacaciones
    (v_CompanyId, 'LOT', 'VAC_PAGO',  'Pago vacaciones',       'SALARIO_DIARIO * DIAS_VACACIONES', NULL, 'VACACIONES', 'ASIGNACION', 'T', TRUE, FALSE, NULL, TRUE, 0.00, 'LOT', 'VACACIONES',  NULL, NULL, 10, TRUE, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'),
    (v_CompanyId, 'LOT', 'VAC_BONO',  'Bono vacacional',       'SALARIO_DIARIO * DIAS_BONO_VAC',   NULL, 'VACACIONES', 'ASIGNACION', 'T', TRUE, FALSE, NULL, TRUE, 0.00, 'LOT', 'VACACIONES',  NULL, NULL, 20, TRUE, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'),

    -- LOTTT liquidacion
    (v_CompanyId, 'LOT', 'LIQ_PREST', 'Prestaciones',          'SALARIO_DIARIO * PREST_DIAS_ANIO',       NULL, 'LIQUIDACION', 'ASIGNACION', 'T', TRUE, FALSE, NULL, TRUE, 0.00, 'LOT', 'LIQUIDACION', NULL, NULL, 10, TRUE, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'),
    (v_CompanyId, 'LOT', 'LIQ_VAC',   'Vacaciones pendientes', 'SALARIO_DIARIO * DIAS_VACACIONES_BASE',  NULL, 'LIQUIDACION', 'ASIGNACION', 'T', TRUE, FALSE, NULL, TRUE, 0.00, 'LOT', 'LIQUIDACION', NULL, NULL, 20, TRUE, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'),

    -- Petrolero mensual
    (v_CompanyId, 'PETRO', 'ASIG_BASE',  'Salario base mensual petrolero', 'SUELDO',              NULL, 'SALARIO', 'ASIGNACION', 'T', TRUE,  FALSE, NULL, TRUE, 0.00, 'PETRO', 'MENSUAL', NULL, NULL, 10, TRUE, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'),
    (v_CompanyId, 'PETRO', 'BONO_PETRO', 'Bono petrolero',                'SALARIO_DIARIO * 10',  NULL, 'BONO',    'ASIGNACION', 'T', TRUE,  FALSE, NULL, TRUE, 0.00, 'PETRO', 'MENSUAL', NULL, NULL, 20, TRUE, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'),
    (v_CompanyId, 'PETRO', 'DED_SSO',    'Deduccion SSO',                 'SUELDO * PCT_SSO',     NULL, 'LEGAL',   'DEDUCCION',  'T', FALSE, FALSE, NULL, TRUE, 0.00, 'PETRO', 'MENSUAL', NULL, NULL, 90, TRUE, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'),

    -- Construccion mensual
    (v_CompanyId, 'CONST', 'ASIG_BASE',  'Salario base construccion', 'SUELDO',              NULL, 'SALARIO', 'ASIGNACION', 'T', TRUE,  FALSE, NULL, TRUE, 0.00, 'CONST', 'MENSUAL', NULL, NULL, 10, TRUE, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'),
    (v_CompanyId, 'CONST', 'BONO_CONST', 'Bono construccion',         'SALARIO_DIARIO * 5',  NULL, 'BONO',    'ASIGNACION', 'T', TRUE,  FALSE, NULL, TRUE, 0.00, 'CONST', 'MENSUAL', NULL, NULL, 20, TRUE, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'),
    (v_CompanyId, 'CONST', 'DED_SSO',    'Deduccion SSO',             'SUELDO * PCT_SSO',    NULL, 'LEGAL',   'DEDUCCION',  'T', FALSE, FALSE, NULL, TRUE, 0.00, 'CONST', 'MENSUAL', NULL, NULL, 90, TRUE, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC')

  ON CONFLICT ("CompanyId", "PayrollCode", "ConceptCode", "ConventionCode", "CalculationType") DO UPDATE SET
    "ConceptName"           = EXCLUDED."ConceptName",
    "Formula"               = EXCLUDED."Formula",
    "BaseExpression"        = NULL,
    "ConceptClass"          = EXCLUDED."ConceptClass",
    "ConceptType"           = EXCLUDED."ConceptType",
    "UsageType"             = 'T',
    "IsBonifiable"          = CASE WHEN EXCLUDED."ConceptType" = 'ASIGNACION' THEN TRUE ELSE FALSE END,
    "IsSeniority"           = FALSE,
    "AccountingAccountCode" = NULL,
    "AppliesFlag"           = TRUE,
    "DefaultValue"          = EXCLUDED."DefaultValue",
    "SortOrder"             = EXCLUDED."SortOrder",
    "IsActive"              = TRUE,
    "UpdatedAt"             = NOW() AT TIME ZONE 'UTC';

  RAISE NOTICE 'Conceptos por convenio sembrados/actualizados en hr.PayrollConcept';
END $$;
