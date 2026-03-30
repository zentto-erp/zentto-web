-- =============================================
-- MOTOR DE CALCULO DE NOMINA (CANONICO) - PostgreSQL
-- Requiere: sp_nomina_sistema.sql
-- Traducido de SQL Server a PostgreSQL
-- =============================================

-- =============================================
-- Funcion: sp_Nomina_ReemplazarVariables
-- Reemplaza variables en formula por sus valores
-- =============================================
DROP FUNCTION IF EXISTS sp_nomina_reemplazar_variables(VARCHAR(80), TEXT) CASCADE;
CREATE OR REPLACE FUNCTION sp_nomina_reemplazar_variables(
  p_session_id VARCHAR(80),
  p_formula TEXT
)
RETURNS TEXT
LANGUAGE plpgsql AS $$
DECLARE
  v_result TEXT := COALESCE(p_formula,''::VARCHAR);
  rec RECORD;
BEGIN
  FOR rec IN
    SELECT "Variable", CAST("Valor" AS VARCHAR(80)) AS val
    FROM hr."PayrollCalcVariable"
    WHERE "SessionID" = p_session_id
    ORDER BY LENGTH("Variable") DESC
  LOOP
    v_result := REPLACE(v_result, rec."Variable", rec.val);
  END LOOP;

  RETURN v_result;
END;
$$;

-- =============================================
-- Funcion: sp_Nomina_EvaluarFormula
-- Evalua una formula matematica con variables
-- Retorna resultado y formula resuelta
-- =============================================
DROP FUNCTION IF EXISTS sp_nomina_evaluar_formula(VARCHAR(80), TEXT, NUMERIC(18,6), TEXT) CASCADE;
CREATE OR REPLACE FUNCTION sp_nomina_evaluar_formula(
  p_session_id VARCHAR(80),
  p_formula TEXT,
  OUT p_resultado NUMERIC(18,6),
  OUT p_formula_resuelta TEXT
)
RETURNS RECORD
LANGUAGE plpgsql AS $$
DECLARE
  v_sql TEXT;
BEGIN
  p_resultado := 0;
  p_formula_resuelta := '';

  IF p_formula IS NULL OR TRIM(p_formula) = '' THEN
    RETURN;
  END IF;

  p_formula_resuelta := sp_nomina_reemplazar_variables(p_session_id, p_formula);

  -- Solo caracteres matematicos permitidos
  IF p_formula_resuelta ~ '[^0-9\.+\-\*/\(\) ]' THEN
    p_resultado := 0;
    RETURN;
  END IF;

  v_sql := 'SELECT CAST((' || p_formula_resuelta || ') AS NUMERIC(18,6))';

  BEGIN
    EXECUTE v_sql INTO p_resultado;
    p_resultado := COALESCE(p_resultado, 0);
  EXCEPTION WHEN OTHERS THEN
    p_resultado := 0;
  END;
END;
$$;

-- =============================================
-- Funcion: sp_Nomina_CalcularConcepto
-- Calcula un concepto de nomina individual
-- =============================================
DROP FUNCTION IF EXISTS sp_nomina_calcular_concepto(VARCHAR(80), VARCHAR(32), VARCHAR(20), VARCHAR(20), NUMERIC(18,6), NUMERIC(18,6), NUMERIC(18,6), VARCHAR(200)) CASCADE;
CREATE OR REPLACE FUNCTION sp_nomina_calcular_concepto(
  p_session_id VARCHAR(80),
  p_cedula VARCHAR(32),
  p_co_concepto VARCHAR(20),
  p_co_nomina VARCHAR(20),
  p_cantidad NUMERIC(18,6) DEFAULT NULL,
  OUT p_monto NUMERIC(18,6),
  OUT p_total NUMERIC(18,6),
  OUT p_descripcion VARCHAR(200)
)
RETURNS RECORD
LANGUAGE plpgsql AS $$
DECLARE
  v_company_id INT;
  v_branch_id INT;
  v_formula TEXT;
  v_default_value NUMERIC(18,6);
  v_cantidad NUMERIC(18,6);
  v_formula_resuelta TEXT;
BEGIN
  SELECT * INTO v_company_id, v_branch_id FROM sp_nomina_get_scope();

  SELECT pc."Formula", pc."DefaultValue", pc."ConceptName"
  INTO v_formula, v_default_value, p_descripcion
  FROM hr."PayrollConcept" pc
  WHERE pc."CompanyId" = v_company_id
    AND pc."PayrollCode" = p_co_nomina
    AND pc."ConceptCode" = p_co_concepto
    AND pc."IsActive" = TRUE
  LIMIT 1;

  v_cantidad := p_cantidad;
  IF v_cantidad IS NULL OR v_cantidad <= 0 THEN v_cantidad := 1; END IF;

  IF v_formula IS NOT NULL AND TRIM(v_formula) <> '' THEN
    SELECT r.p_resultado, r.p_formula_resuelta
    INTO p_monto, v_formula_resuelta
    FROM sp_nomina_evaluar_formula(p_session_id, v_formula) r;
  ELSE
    p_monto := COALESCE(v_default_value, 0);
  END IF;

  p_monto := COALESCE(p_monto, 0);
  p_total := p_monto * v_cantidad;
END;
$$;

-- =============================================
-- Funcion: sp_Nomina_ProcesarEmpleado
-- Procesa la nomina completa de un empleado
-- =============================================
DROP FUNCTION IF EXISTS sp_nomina_procesar_empleado(VARCHAR(20), VARCHAR(32), DATE, DATE, VARCHAR(50), INT, VARCHAR(500)) CASCADE;
CREATE OR REPLACE FUNCTION sp_nomina_procesar_empleado(
  p_nomina VARCHAR(20),
  p_cedula VARCHAR(32),
  p_fecha_inicio DATE,
  p_fecha_hasta DATE,
  p_co_usuario VARCHAR(50) DEFAULT 'API',
  OUT p_resultado INT,
  OUT p_mensaje VARCHAR(500)
)
RETURNS RECORD
LANGUAGE plpgsql AS $$
DECLARE
  v_company_id INT;
  v_branch_id INT;
  v_user_id INT := NULL;
  v_employee_id BIGINT;
  v_employee_name VARCHAR(120);
  v_run_id BIGINT;
  v_session_id VARCHAR(80);
  v_asig NUMERIC(18,6) := 0;
  v_ded NUMERIC(18,6) := 0;
  v_neto NUMERIC(18,6) := 0;
  rec RECORD;
  v_monto NUMERIC(18,6);
  v_total NUMERIC(18,6);
  v_desc VARCHAR(200);
  v_var_code VARCHAR(120);
  v_var_total NUMERIC(18,6);
  v_var_desc VARCHAR(255);
BEGIN
  p_resultado := 0;
  p_mensaje := '';
  v_session_id := p_nomina || '_' || p_cedula || '_' || to_char(NOW() AT TIME ZONE 'UTC', 'YYYYMMDD');

  BEGIN
    SELECT * INTO v_company_id, v_branch_id FROM sp_nomina_get_scope();

    SELECT u."UserId" INTO v_user_id
    FROM sec."User" u
    WHERE u."UserCode" = p_co_usuario AND u."IsDeleted" = FALSE
    LIMIT 1;

    SELECT e."EmployeeId", e."EmployeeName"
    INTO v_employee_id, v_employee_name
    FROM master."Employee" e
    WHERE e."CompanyId" = v_company_id
      AND e."EmployeeCode" = p_cedula
      AND e."IsDeleted" = FALSE
      AND e."IsActive" = TRUE
    LIMIT 1;

    IF v_employee_id IS NULL THEN
      p_resultado := 0;
      p_mensaje := 'Empleado no encontrado o inactivo en master.Employee';
      RETURN;
    END IF;

    PERFORM sp_nomina_preparar_variables_base(v_session_id, p_cedula, p_nomina, p_fecha_inicio, p_fecha_hasta);

    SELECT pr."PayrollRunId" INTO v_run_id
    FROM hr."PayrollRun" pr
    WHERE pr."CompanyId" = v_company_id
      AND pr."BranchId" = v_branch_id
      AND pr."PayrollCode" = p_nomina
      AND pr."EmployeeCode" = p_cedula
      AND pr."DateFrom" = p_fecha_inicio
      AND pr."DateTo" = p_fecha_hasta
      AND pr."RunSource" = 'SP_LEGACY_COMPAT'
    ORDER BY pr."PayrollRunId" DESC
    LIMIT 1;

    IF v_run_id IS NULL THEN
      INSERT INTO hr."PayrollRun" (
        "CompanyId", "BranchId", "PayrollCode", "EmployeeId", "EmployeeCode", "EmployeeName",
        "ProcessDate", "DateFrom", "DateTo", "TotalAssignments", "TotalDeductions", "NetTotal",
        "IsClosed", "PayrollTypeName", "RunSource", "CreatedAt", "UpdatedAt", "CreatedByUserId", "UpdatedByUserId"
      )
      VALUES (
        v_company_id, v_branch_id, p_nomina, v_employee_id, p_cedula, v_employee_name,
        (NOW() AT TIME ZONE 'UTC')::DATE, p_fecha_inicio, p_fecha_hasta, 0, 0, 0,
        FALSE, 'COMPAT', 'SP_LEGACY_COMPAT', NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC', v_user_id, v_user_id
      )
      RETURNING "PayrollRunId" INTO v_run_id;
    ELSE
      UPDATE hr."PayrollRun"
      SET "UpdatedAt" = NOW() AT TIME ZONE 'UTC',
          "UpdatedByUserId" = v_user_id,
          "ProcessDate" = (NOW() AT TIME ZONE 'UTC')::DATE
      WHERE "PayrollRunId" = v_run_id;

      DELETE FROM hr."PayrollRunLine" WHERE "PayrollRunId" = v_run_id;
    END IF;

    -- Iterar conceptos (reemplaza CURSOR)
    FOR rec IN
      SELECT "ConceptCode", "ConceptName", "ConceptType", "AccountingAccountCode"
      FROM hr."PayrollConcept"
      WHERE "CompanyId" = v_company_id
        AND "PayrollCode" = p_nomina
        AND "IsActive" = TRUE
      ORDER BY "SortOrder", "ConceptCode"
    LOOP
      SELECT r.p_monto, r.p_total, r.p_descripcion
      INTO v_monto, v_total, v_desc
      FROM sp_nomina_calcular_concepto(
        v_session_id, p_cedula, rec."ConceptCode", p_nomina, 1
      ) r;

      INSERT INTO hr."PayrollRunLine" (
        "PayrollRunId", "ConceptCode", "ConceptName", "ConceptType",
        "Quantity", "Amount", "Total", "DescriptionText", "AccountingAccountCode", "CreatedAt"
      )
      VALUES (
        v_run_id, rec."ConceptCode", COALESCE(rec."ConceptName", v_desc), COALESCE(rec."ConceptType", 'ASIGNACION'),
        1, COALESCE(v_monto, 0), COALESCE(v_total, 0), v_desc, rec."AccountingAccountCode", NOW() AT TIME ZONE 'UTC'
      );

      IF UPPER(COALESCE(rec."ConceptType",''::VARCHAR)) = 'DEDUCCION' THEN
        v_ded := v_ded + COALESCE(v_total, 0);
      ELSE
        v_asig := v_asig + COALESCE(v_total, 0);
        -- Actualizar TOTAL_ASIGNACIONES para que deducciones legales
        -- (ej. FAOV) puedan calcular sobre gananciales (LOTTT Art. 172)
        PERFORM sp_nomina_set_variable(v_session_id, 'TOTAL_ASIGNACIONES', v_asig, 'Total asignaciones acumuladas');
      END IF;

      v_var_code := 'C' || rec."ConceptCode";
      v_var_total := COALESCE(v_total, 0);
      v_var_desc := COALESCE(rec."ConceptName", v_desc);
      PERFORM sp_nomina_set_variable(v_session_id, v_var_code, v_var_total, v_var_desc);
    END LOOP;

    v_neto := v_asig - v_ded;

    UPDATE hr."PayrollRun"
    SET "TotalAssignments" = v_asig,
        "TotalDeductions" = v_ded,
        "NetTotal" = v_neto,
        "UpdatedAt" = NOW() AT TIME ZONE 'UTC',
        "UpdatedByUserId" = v_user_id
    WHERE "PayrollRunId" = v_run_id;

    PERFORM sp_nomina_limpiar_variables(v_session_id);

    p_resultado := 1;
    p_mensaje := 'Procesado canonico. Asig=' || CAST(v_asig AS VARCHAR(40)) || ' Ded=' || CAST(v_ded AS VARCHAR(40)) || ' Neto=' || CAST(v_neto AS VARCHAR(40));

  EXCEPTION WHEN OTHERS THEN
    PERFORM sp_nomina_limpiar_variables(v_session_id);
    p_resultado := 0;
    p_mensaje := SQLERRM;
  END;
END;
$$;

-- =============================================
-- Funcion: sp_Nomina_ProcesarNomina
-- Procesa la nomina para todos los empleados
-- =============================================
DROP FUNCTION IF EXISTS sp_nomina_procesar_nomina(VARCHAR(20), DATE, DATE, VARCHAR(50), BOOLEAN, INT, INT, VARCHAR(500)) CASCADE;
CREATE OR REPLACE FUNCTION sp_nomina_procesar_nomina(
  p_nomina VARCHAR(20),
  p_fecha_inicio DATE,
  p_fecha_hasta DATE,
  p_co_usuario VARCHAR(50) DEFAULT 'API',
  p_solo_activos BOOLEAN DEFAULT TRUE,
  OUT p_procesados INT,
  OUT p_errores INT,
  OUT p_mensaje VARCHAR(500)
)
RETURNS RECORD
LANGUAGE plpgsql AS $$
DECLARE
  v_company_id INT;
  v_branch_id INT;
  v_cedula VARCHAR(32);
  v_res INT;
  v_msg VARCHAR(500);
  rec RECORD;
BEGIN
  p_procesados := 0;
  p_errores := 0;
  p_mensaje := '';

  SELECT * INTO v_company_id, v_branch_id FROM sp_nomina_get_scope();

  FOR rec IN
    SELECT e."EmployeeCode"
    FROM master."Employee" e
    WHERE e."CompanyId" = v_company_id
      AND e."IsDeleted" = FALSE
      AND (p_solo_activos = FALSE OR e."IsActive" = TRUE)
    ORDER BY e."EmployeeCode"
  LOOP
    SELECT r.p_resultado, r.p_mensaje
    INTO v_res, v_msg
    FROM sp_nomina_procesar_empleado(
      p_nomina, rec."EmployeeCode", p_fecha_inicio, p_fecha_hasta, p_co_usuario
    ) r;

    IF v_res = 1 THEN
      p_procesados := p_procesados + 1;
    ELSE
      p_errores := p_errores + 1;
    END IF;
  END LOOP;

  p_mensaje := 'Proceso completado. Procesados=' || CAST(p_procesados AS VARCHAR(20)) || ' Errores=' || CAST(p_errores AS VARCHAR(20));
END;
$$;
