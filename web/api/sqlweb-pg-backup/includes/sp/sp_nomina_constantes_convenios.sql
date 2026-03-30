-- =============================================
-- SEMILLA DE CONCEPTOS POR CONVENIO (CANONICO) - PostgreSQL
-- Tabla objetivo: hr."PayrollConcept"
-- Traducido de SQL Server a PostgreSQL
-- =============================================

DO $$
DECLARE
  v_company_id INT;
BEGIN
  SELECT "CompanyId" INTO v_company_id
  FROM cfg."Company"
  WHERE "IsDeleted" = FALSE
  ORDER BY CASE WHEN "CompanyCode" = 'DEFAULT' THEN 0 ELSE 1 END, "CompanyId"
  LIMIT 1;

  IF v_company_id IS NULL THEN
    RAISE EXCEPTION 'No existe cfg.Company activa para sembrar conceptos nomina';
  END IF;

  -- Seed PayrollType
  INSERT INTO hr."PayrollType" ("CompanyId", "PayrollCode", "PayrollName", "IsActive", "CreatedAt", "UpdatedAt")
  VALUES
    (v_company_id, 'LOT', 'Nomina LOTTT', TRUE, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'),
    (v_company_id, 'PETRO', 'Nomina CCT Petrolero', TRUE, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'),
    (v_company_id, 'CONST', 'Nomina Construccion', TRUE, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC')
  ON CONFLICT ("CompanyId", "PayrollCode") DO UPDATE SET
    "PayrollName" = EXCLUDED."PayrollName",
    "IsActive" = TRUE,
    "UpdatedAt" = NOW() AT TIME ZONE 'UTC';

  -- Seed PayrollConcept
  -- LOTTT mensual
  INSERT INTO hr."PayrollConcept" (
    "CompanyId", "PayrollCode", "ConceptCode", "ConceptName", "Formula", "BaseExpression",
    "ConceptClass", "ConceptType", "UsageType", "IsBonifiable", "IsSeniority",
    "AccountingAccountCode", "AppliesFlag", "DefaultValue", "ConventionCode",
    "CalculationType", "LotttArticle", "CcpClause", "SortOrder", "IsActive",
    "CreatedAt", "UpdatedAt"
  )
  VALUES
    (v_company_id, 'LOT', 'ASIG_BASE', 'Salario base mensual', 'SUELDO', NULL,
     'SALARIO', 'ASIGNACION', 'T', TRUE, FALSE, NULL, TRUE, 0.00, 'LOT',
     'MENSUAL', NULL, NULL, 10, TRUE, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'),

    (v_company_id, 'LOT', 'DED_SSO', 'Deduccion SSO', 'SUELDO * PCT_SSO', NULL,
     'LEGAL', 'DEDUCCION', 'T', FALSE, FALSE, NULL, TRUE, 0.00, 'LOT',
     'MENSUAL', NULL, NULL, 90, TRUE, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'),

    (v_company_id, 'LOT', 'DED_FAOV', 'Deduccion FAOV', 'TOTAL_ASIGNACIONES * PCT_FAOV', NULL,
     'LEGAL', 'DEDUCCION', 'T', FALSE, FALSE, NULL, TRUE, 0.00, 'LOT',
     'MENSUAL', NULL, NULL, 91, TRUE, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'),

    (v_company_id, 'LOT', 'DED_LRPE', 'Deduccion LRPE', 'SUELDO * PCT_LRPE', NULL,
     'LEGAL', 'DEDUCCION', 'T', FALSE, FALSE, NULL, TRUE, 0.00, 'LOT',
     'MENSUAL', NULL, NULL, 92, TRUE, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'),

    -- LOTTT vacaciones
    (v_company_id, 'LOT', 'VAC_PAGO', 'Pago vacaciones', 'SALARIO_DIARIO * DIAS_VACACIONES', NULL,
     'VACACIONES', 'ASIGNACION', 'T', TRUE, FALSE, NULL, TRUE, 0.00, 'LOT',
     'VACACIONES', NULL, NULL, 10, TRUE, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'),

    (v_company_id, 'LOT', 'VAC_BONO', 'Bono vacacional', 'SALARIO_DIARIO * DIAS_BONO_VAC', NULL,
     'VACACIONES', 'ASIGNACION', 'T', TRUE, FALSE, NULL, TRUE, 0.00, 'LOT',
     'VACACIONES', NULL, NULL, 20, TRUE, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'),

    -- LOTTT liquidacion
    (v_company_id, 'LOT', 'LIQ_PREST', 'Prestaciones', 'SALARIO_DIARIO * PREST_DIAS_ANIO', NULL,
     'LIQUIDACION', 'ASIGNACION', 'T', TRUE, FALSE, NULL, TRUE, 0.00, 'LOT',
     'LIQUIDACION', NULL, NULL, 10, TRUE, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'),

    (v_company_id, 'LOT', 'LIQ_VAC', 'Vacaciones pendientes', 'SALARIO_DIARIO * DIAS_VACACIONES_BASE', NULL,
     'LIQUIDACION', 'ASIGNACION', 'T', TRUE, FALSE, NULL, TRUE, 0.00, 'LOT',
     'LIQUIDACION', NULL, NULL, 20, TRUE, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'),

    -- Petrolero mensual
    (v_company_id, 'PETRO', 'ASIG_BASE', 'Salario base mensual petrolero', 'SUELDO', NULL,
     'SALARIO', 'ASIGNACION', 'T', TRUE, FALSE, NULL, TRUE, 0.00, 'PETRO',
     'MENSUAL', NULL, NULL, 10, TRUE, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'),

    (v_company_id, 'PETRO', 'BONO_PETRO', 'Bono petrolero', 'SALARIO_DIARIO * 10', NULL,
     'BONO', 'ASIGNACION', 'T', TRUE, FALSE, NULL, TRUE, 0.00, 'PETRO',
     'MENSUAL', NULL, NULL, 20, TRUE, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'),

    (v_company_id, 'PETRO', 'DED_SSO', 'Deduccion SSO', 'SUELDO * PCT_SSO', NULL,
     'LEGAL', 'DEDUCCION', 'T', FALSE, FALSE, NULL, TRUE, 0.00, 'PETRO',
     'MENSUAL', NULL, NULL, 90, TRUE, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'),

    -- Construccion mensual
    (v_company_id, 'CONST', 'ASIG_BASE', 'Salario base construccion', 'SUELDO', NULL,
     'SALARIO', 'ASIGNACION', 'T', TRUE, FALSE, NULL, TRUE, 0.00, 'CONST',
     'MENSUAL', NULL, NULL, 10, TRUE, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'),

    (v_company_id, 'CONST', 'BONO_CONST', 'Bono construccion', 'SALARIO_DIARIO * 5', NULL,
     'BONO', 'ASIGNACION', 'T', TRUE, FALSE, NULL, TRUE, 0.00, 'CONST',
     'MENSUAL', NULL, NULL, 20, TRUE, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'),

    (v_company_id, 'CONST', 'DED_SSO', 'Deduccion SSO', 'SUELDO * PCT_SSO', NULL,
     'LEGAL', 'DEDUCCION', 'T', FALSE, FALSE, NULL, TRUE, 0.00, 'CONST',
     'MENSUAL', NULL, NULL, 90, TRUE, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC')

  ON CONFLICT ("CompanyId", "PayrollCode", "ConceptCode", "ConventionCode", "CalculationType")
  DO UPDATE SET
    "ConceptName" = EXCLUDED."ConceptName",
    "Formula" = EXCLUDED."Formula",
    "BaseExpression" = NULL,
    "ConceptClass" = EXCLUDED."ConceptClass",
    "ConceptType" = EXCLUDED."ConceptType",
    "UsageType" = 'T',
    "IsBonifiable" = CASE WHEN EXCLUDED."ConceptType" = 'ASIGNACION' THEN TRUE ELSE FALSE END,
    "IsSeniority" = FALSE,
    "AccountingAccountCode" = NULL,
    "AppliesFlag" = TRUE,
    "DefaultValue" = EXCLUDED."DefaultValue",
    "SortOrder" = EXCLUDED."SortOrder",
    "IsActive" = TRUE,
    "UpdatedAt" = NOW() AT TIME ZONE 'UTC';

  RAISE NOTICE 'Conceptos por convenio sembrados/actualizados en hr.PayrollConcept';
END;
$$;
