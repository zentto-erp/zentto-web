-- =============================================
-- SISTEMA BASE DE NOMINA (CANONICO) - PostgreSQL
-- Modelo objetivo: hr.* + master."Employee"
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
  CONSTRAINT "PK_PayrollCalcVariable" PRIMARY KEY ("SessionID", "Variable")
);

-- =============================================
-- Funcion: fn_EvaluarExpr
-- =============================================
DROP FUNCTION IF EXISTS fn_evaluar_expr(TEXT) CASCADE;
DROP FUNCTION IF EXISTS fn_evaluar_expr(p_expr TEXT)
RETURNS NUMERIC(18,6)
LANGUAGE plpgsql AS $$
BEGIN
  RETURN CAST(p_expr AS NUMERIC(18,6));
EXCEPTION WHEN OTHERS THEN
  RETURN NULL;
END;
$$;

-- =============================================
-- Funcion: fn_Nomina_GetVariable
-- =============================================
DROP FUNCTION IF EXISTS fn_nomina_get_variable(VARCHAR(80), VARCHAR(120)) CASCADE;
CREATE OR REPLACE FUNCTION fn_nomina_get_variable(
  p_session_id VARCHAR(80),
  p_variable VARCHAR(120)
)
RETURNS NUMERIC(18,6)
LANGUAGE plpgsql AS $$
DECLARE
  v_valor NUMERIC(18,6) := 0;
BEGIN
  SELECT "Valor" INTO v_valor
  FROM hr."PayrollCalcVariable"
  WHERE "SessionID" = p_session_id AND "Variable" = p_variable
  LIMIT 1;

  RETURN COALESCE(v_valor, 0);
END;
$$;

-- =============================================
-- Funcion: fn_Nomina_ContarFeriados
-- =============================================
DROP FUNCTION IF EXISTS fn_nomina_contar_feriados(DATE, DATE) CASCADE;
CREATE OR REPLACE FUNCTION fn_nomina_contar_feriados(
  p_fecha_desde DATE,
  p_fecha_hasta DATE
)
RETURNS INT
LANGUAGE plpgsql AS $$
BEGIN
  -- En DatqBoxWeb canonico no se depende de tabla Feriados legacy.
  -- Se deja en 0 y puede ser reemplazado por catalogo canonico si se incorpora.
  RETURN 0;
END;
$$;

-- =============================================
-- Funcion: fn_Nomina_ContarDomingos
-- =============================================
DROP FUNCTION IF EXISTS fn_nomina_contar_domingos(DATE, DATE) CASCADE;
CREATE OR REPLACE FUNCTION fn_nomina_contar_domingos(
  p_fecha_desde DATE,
  p_fecha_hasta DATE
)
RETURNS INT
LANGUAGE plpgsql AS $$
DECLARE
  v_actual DATE := p_fecha_desde;
  v_domingos INT := 0;
BEGIN
  WHILE v_actual <= p_fecha_hasta LOOP
    IF EXTRACT(DOW FROM v_actual) = 0 THEN
      v_domingos := v_domingos + 1;
    END IF;
    v_actual := v_actual + INTERVAL '1 day';
  END LOOP;

  RETURN v_domingos;
END;
$$;

-- =============================================
-- Funcion: sp_Nomina_GetScope
-- Retorna CompanyId y BranchId
-- =============================================
DROP FUNCTION IF EXISTS sp_nomina_get_scope(INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION sp_nomina_get_scope(
  OUT p_company_id INT,
  OUT p_branch_id INT
)
RETURNS RECORD
LANGUAGE plpgsql AS $$
BEGIN
  SELECT c."CompanyId" INTO p_company_id
  FROM cfg."Company" c
  WHERE c."IsDeleted" = FALSE
  ORDER BY CASE WHEN c."CompanyCode" = 'DEFAULT' THEN 0 ELSE 1 END, c."CompanyId"
  LIMIT 1;

  IF p_company_id IS NULL THEN
    RAISE EXCEPTION 'No existe cfg.Company activa para nomina';
  END IF;

  SELECT b."BranchId" INTO p_branch_id
  FROM cfg."Branch" b
  WHERE b."CompanyId" = p_company_id
    AND b."IsDeleted" = FALSE
  ORDER BY CASE WHEN b."BranchCode" = 'MAIN' THEN 0 ELSE 1 END, b."BranchId"
  LIMIT 1;

  IF p_branch_id IS NULL THEN
    RAISE EXCEPTION 'No existe cfg.Branch activa para nomina';
  END IF;
END;
$$;

-- =============================================
-- Funcion: sp_Nomina_LimpiarVariables
-- =============================================
DROP FUNCTION IF EXISTS sp_nomina_limpiar_variables(VARCHAR(80)) CASCADE;
CREATE OR REPLACE FUNCTION sp_nomina_limpiar_variables(
  p_session_id VARCHAR(80)
)
RETURNS VOID
LANGUAGE plpgsql AS $$
BEGIN
  DELETE FROM hr."PayrollCalcVariable" WHERE "SessionID" = p_session_id;
END;
$$;

-- =============================================
-- Funcion: sp_Nomina_SetVariable
-- =============================================
DROP FUNCTION IF EXISTS sp_nomina_set_variable(VARCHAR(80), VARCHAR(120), NUMERIC(18,6), VARCHAR(255)) CASCADE;
CREATE OR REPLACE FUNCTION sp_nomina_set_variable(
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

-- =============================================
-- Funcion: sp_Nomina_CargarConstantes
-- =============================================
DROP FUNCTION IF EXISTS sp_nomina_cargar_constantes(VARCHAR(80)) CASCADE;
CREATE OR REPLACE FUNCTION sp_nomina_cargar_constantes(
  p_session_id VARCHAR(80)
)
RETURNS VOID
LANGUAGE plpgsql AS $$
DECLARE
  v_company_id INT;
  v_branch_id INT;
BEGIN
  SELECT * INTO v_company_id, v_branch_id FROM sp_nomina_get_scope();

  INSERT INTO hr."PayrollCalcVariable" ("SessionID", "Variable", "Valor", "Descripcion")
  SELECT
    p_session_id,
    pc."ConstantCode",
    pc."ConstantValue",
    pc."ConstantName"
  FROM hr."PayrollConstant" pc
  WHERE pc."CompanyId" = v_company_id
    AND pc."IsActive" = TRUE
    AND NOT EXISTS (
      SELECT 1
      FROM hr."PayrollCalcVariable" v
      WHERE v."SessionID" = p_session_id
        AND v."Variable" = pc."ConstantCode"
    );
END;
$$;

-- =============================================
-- Funcion: sp_Nomina_CalcularAntiguedad
-- =============================================
DROP FUNCTION IF EXISTS sp_nomina_calcular_antiguedad(VARCHAR(80), VARCHAR(32), DATE) CASCADE;
CREATE OR REPLACE FUNCTION sp_nomina_calcular_antiguedad(
  p_session_id VARCHAR(80),
  p_cedula VARCHAR(32),
  p_fecha_calculo DATE DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql AS $$
DECLARE
  v_company_id INT;
  v_branch_id INT;
  v_fecha_ingreso DATE;
  v_dias INT := 0;
  v_anios INT := 0;
  v_meses INT := 0;
  v_total_meses INT := 0;
  v_fecha_calc DATE;
BEGIN
  v_fecha_calc := COALESCE(p_fecha_calculo, (NOW() AT TIME ZONE 'UTC')::DATE);

  SELECT * INTO v_company_id, v_branch_id FROM sp_nomina_get_scope();

  SELECT e."HireDate" INTO v_fecha_ingreso
  FROM master."Employee" e
  WHERE e."CompanyId" = v_company_id
    AND e."EmployeeCode" = p_cedula
    AND e."IsDeleted" = FALSE
  LIMIT 1;

  IF v_fecha_ingreso IS NOT NULL THEN
    v_dias := v_fecha_calc - v_fecha_ingreso;
    v_anios := v_dias / 365;
    v_meses := (v_dias % 365) / 30;
    v_total_meses := EXTRACT(YEAR FROM AGE(v_fecha_calc, v_fecha_ingreso)) * 12
                   + EXTRACT(MONTH FROM AGE(v_fecha_calc, v_fecha_ingreso));
  END IF;

  PERFORM sp_nomina_set_variable(p_session_id, 'ANTI_ANIOS', v_anios, 'Anios de antiguedad');
  PERFORM sp_nomina_set_variable(p_session_id, 'ANTI_MESES', v_meses, 'Meses de antiguedad');
  PERFORM sp_nomina_set_variable(p_session_id, 'ANTI_DIAS', v_dias, 'Dias de antiguedad');
  PERFORM sp_nomina_set_variable(p_session_id, 'ANTI_TOTAL_MESES', v_total_meses, 'Total meses de antiguedad');
END;
$$;

-- =============================================
-- Funcion: sp_Nomina_PrepararVariablesBase
-- =============================================
DROP FUNCTION IF EXISTS sp_nomina_preparar_variables_base(VARCHAR(80), VARCHAR(32), VARCHAR(20), DATE, DATE) CASCADE;
CREATE OR REPLACE FUNCTION sp_nomina_preparar_variables_base(
  p_session_id VARCHAR(80),
  p_cedula VARCHAR(32),
  p_nomina VARCHAR(20),
  p_fecha_inicio DATE,
  p_fecha_hasta DATE
)
RETURNS VOID
LANGUAGE plpgsql AS $$
DECLARE
  v_company_id INT;
  v_branch_id INT;
  v_dias_periodo INT;
  v_feriados INT;
  v_domingos INT;
  v_salario_diario NUMERIC(18,6);
  v_sueldo NUMERIC(18,6);
  v_salario_hora NUMERIC(18,6);
  v_fecha_inicio_num INT;
  v_fecha_hasta_num INT;
BEGIN
  SELECT * INTO v_company_id, v_branch_id FROM sp_nomina_get_scope();

  PERFORM sp_nomina_limpiar_variables(p_session_id);
  PERFORM sp_nomina_cargar_constantes(p_session_id);

  v_dias_periodo := (p_fecha_hasta - p_fecha_inicio) + 1;
  v_feriados := fn_nomina_contar_feriados(p_fecha_inicio, p_fecha_hasta);
  v_domingos := fn_nomina_contar_domingos(p_fecha_inicio, p_fecha_hasta);

  SELECT pc."ConstantValue" INTO v_salario_diario
  FROM hr."PayrollConstant" pc
  WHERE pc."CompanyId" = v_company_id
    AND pc."ConstantCode" = 'SALARIO_DIARIO'
    AND pc."IsActive" = TRUE;

  IF v_salario_diario IS NULL THEN v_salario_diario := 0; END IF;
  v_sueldo := v_salario_diario * 30;
  v_salario_hora := v_salario_diario / 8.0;
  v_fecha_inicio_num := CAST(to_char(p_fecha_inicio, 'YYYYMMDD') AS INT);
  v_fecha_hasta_num := CAST(to_char(p_fecha_hasta, 'YYYYMMDD') AS INT);

  PERFORM sp_nomina_set_variable(p_session_id, 'FECHA_INICIO_NUM', v_fecha_inicio_num, 'Fecha inicio (yyyymmdd)');
  PERFORM sp_nomina_set_variable(p_session_id, 'FECHA_HASTA_NUM', v_fecha_hasta_num, 'Fecha hasta (yyyymmdd)');
  PERFORM sp_nomina_set_variable(p_session_id, 'DIAS_PERIODO', v_dias_periodo, 'Dias del periodo');
  PERFORM sp_nomina_set_variable(p_session_id, 'FERIADOS', v_feriados, 'Feriados del periodo');
  PERFORM sp_nomina_set_variable(p_session_id, 'DOMINGOS', v_domingos, 'Domingos del periodo');
  PERFORM sp_nomina_set_variable(p_session_id, 'SUELDO', v_sueldo, 'Sueldo mensual referencial');
  PERFORM sp_nomina_set_variable(p_session_id, 'SALARIO_DIARIO', v_salario_diario, 'Salario diario referencial');
  PERFORM sp_nomina_set_variable(p_session_id, 'SALARIO_HORA', v_salario_hora, 'Salario hora referencial');
  PERFORM sp_nomina_set_variable(p_session_id, 'HORAS_MES', 240, 'Horas laborales referenciales');

  PERFORM sp_nomina_calcular_antiguedad(p_session_id, p_cedula, p_fecha_hasta);
END;
$$;
