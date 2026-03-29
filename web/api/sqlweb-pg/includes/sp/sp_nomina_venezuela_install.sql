-- =============================================
-- INSTALADOR NOMINA VENEZUELA (CANONICO) - PostgreSQL
-- Compatibilidad de nombres sp_Nomina_* sin tablas legacy
-- Traducido de SQL Server a PostgreSQL
-- =============================================

CREATE SCHEMA IF NOT EXISTS hr;

CREATE TABLE IF NOT EXISTS hr."PayrollCalcVariable" (
  "SessionID" VARCHAR(80) NOT NULL,
  "Variable" VARCHAR(120) NOT NULL,
  "Valor" NUMERIC(18,6) NOT NULL DEFAULT 0,
  "Descripcion" VARCHAR(255) NULL,
  "CreatedAt" TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt" TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  CONSTRAINT "PK_PCV" PRIMARY KEY ("SessionID", "Variable")
);

-- Wrappers de compatibilidad por si aun no se ejecuto sp_nomina_sistema.sql
-- En PG usamos CREATE OR REPLACE que es idempotente

DROP FUNCTION IF EXISTS sp_nomina_limpiar_variables_compat(VARCHAR(80)) CASCADE;
CREATE OR REPLACE FUNCTION sp_nomina_limpiar_variables_compat(
  p_session_id VARCHAR(80)
)
RETURNS VOID
LANGUAGE plpgsql AS $$
BEGIN
  DELETE FROM hr."PayrollCalcVariable" WHERE "SessionID" = p_session_id;
END;
$$;

DROP FUNCTION IF EXISTS sp_nomina_set_variable_compat(VARCHAR(80), VARCHAR(120), NUMERIC(18,6), VARCHAR(255)) CASCADE;
CREATE OR REPLACE FUNCTION sp_nomina_set_variable_compat(
  p_session_id VARCHAR(80),
  p_variable VARCHAR(120),
  p_valor NUMERIC(18,6),
  p_descripcion VARCHAR(255) DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql AS $$
BEGIN
  INSERT INTO hr."PayrollCalcVariable" ("SessionID", "Variable", "Valor", "Descripcion")
  VALUES (p_session_id, p_variable, p_valor, p_descripcion)
  ON CONFLICT ("SessionID", "Variable") DO UPDATE SET
    "Valor" = EXCLUDED."Valor",
    "Descripcion" = EXCLUDED."Descripcion",
    "UpdatedAt" = NOW() AT TIME ZONE 'UTC';
END;
$$;

DROP FUNCTION IF EXISTS sp_nomina_calcular_antiguedad_compat(VARCHAR(80), VARCHAR(32), DATE) CASCADE;
CREATE OR REPLACE FUNCTION sp_nomina_calcular_antiguedad_compat(
  p_session_id VARCHAR(80),
  p_cedula VARCHAR(32),
  p_fecha_calculo DATE DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql AS $$
DECLARE
  v_fecha_calc DATE;
BEGIN
  v_fecha_calc := COALESCE(p_fecha_calculo, (NOW() AT TIME ZONE 'UTC')::DATE);
  PERFORM sp_nomina_set_variable_compat(p_session_id, 'ANTI_ANIOS', 0, 'Anios');
  PERFORM sp_nomina_set_variable_compat(p_session_id, 'ANTI_MESES', 0, 'Meses');
  PERFORM sp_nomina_set_variable_compat(p_session_id, 'ANTI_TOTAL_MESES', 0, 'Total meses');
END;
$$;

-- Semilla de constantes base para Venezuela (idempotente)
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
    RAISE EXCEPTION 'No existe cfg.Company activa';
  END IF;

  INSERT INTO hr."PayrollConstant" ("CompanyId", "ConstantCode", "ConstantName", "ConstantValue", "SourceName", "IsActive", "CreatedAt", "UpdatedAt")
  VALUES
    (v_company_id, 'SALARIO_DIARIO', 'Salario diario base', 0.00, 'VE_INSTALL', TRUE, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'),
    (v_company_id, 'HORAS_MES', 'Horas laborales mensuales', 240.00, 'VE_INSTALL', TRUE, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'),
    (v_company_id, 'PCT_SSO', 'Porcentaje SSO empleado', 0.040000, 'VE_INSTALL', TRUE, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'),
    (v_company_id, 'PCT_FAOV', 'Porcentaje FAOV empleado', 0.010000, 'VE_INSTALL', TRUE, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'),
    (v_company_id, 'PCT_LRPE', 'Porcentaje LRPE empleado', 0.005000, 'VE_INSTALL', TRUE, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'),
    (v_company_id, 'DIAS_VACACIONES_BASE', 'Dias vacaciones base', 15.000000, 'VE_INSTALL', TRUE, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'),
    (v_company_id, 'DIAS_BONO_VAC_BASE', 'Dias bono vacacional base', 15.000000, 'VE_INSTALL', TRUE, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'),
    (v_company_id, 'DIAS_UTILIDADES_MIN', 'Dias utilidades minimo', 30.000000, 'VE_INSTALL', TRUE, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'),
    (v_company_id, 'DIAS_UTILIDADES_MAX', 'Dias utilidades maximo', 120.000000, 'VE_INSTALL', TRUE, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC')
  ON CONFLICT ("CompanyId", "ConstantCode") DO UPDATE SET
    "ConstantName" = EXCLUDED."ConstantName",
    "ConstantValue" = EXCLUDED."ConstantValue",
    "SourceName" = EXCLUDED."SourceName",
    "IsActive" = TRUE,
    "UpdatedAt" = NOW() AT TIME ZONE 'UTC';

  RAISE NOTICE 'Instalacion canonica de nomina completada.';
END;
$$;

-- Verificacion de conteos
SELECT 'PayrollType' AS "Objeto", COUNT(1) AS "Total" FROM hr."PayrollType"
UNION ALL SELECT 'PayrollConstant', COUNT(1) FROM hr."PayrollConstant"
UNION ALL SELECT 'PayrollConcept', COUNT(1) FROM hr."PayrollConcept"
UNION ALL SELECT 'PayrollRun', COUNT(1) FROM hr."PayrollRun"
UNION ALL SELECT 'PayrollCalcVariable', COUNT(1) FROM hr."PayrollCalcVariable";
