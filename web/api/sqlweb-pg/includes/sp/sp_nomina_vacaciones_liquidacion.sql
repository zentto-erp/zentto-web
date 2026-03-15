-- =============================================
-- VACACIONES Y LIQUIDACION (CANONICO) - PostgreSQL
-- Traducido de SQL Server a PostgreSQL
-- =============================================

-- =============================================
-- Funcion: sp_Nomina_CalcularSalariosPromedio
-- =============================================
CREATE OR REPLACE FUNCTION sp_nomina_calcular_salarios_promedio(
  p_session_id VARCHAR(80),
  p_cedula VARCHAR(32),
  p_fecha_desde DATE,
  p_fecha_hasta DATE
)
RETURNS VOID
LANGUAGE plpgsql AS $$
DECLARE
  v_salario_diario NUMERIC(18,6);
  v_base_util NUMERIC(18,6);
  v_salario_normal NUMERIC(18,6);
  v_salario_integral NUMERIC(18,6);
  v_dias INT;
BEGIN
  v_salario_diario := fn_nomina_get_variable(p_session_id, 'SALARIO_DIARIO');
  v_base_util := fn_nomina_get_variable(p_session_id, 'DIAS_UTILIDADES_MIN');
  v_dias := (p_fecha_hasta - p_fecha_desde) + 1;

  IF v_salario_diario <= 0 THEN v_salario_diario := 0; END IF;
  IF v_base_util <= 0 THEN v_base_util := 30; END IF;

  v_salario_normal := v_salario_diario;
  v_salario_integral := v_salario_diario + (v_salario_diario * (v_base_util / 360.0));

  PERFORM sp_nomina_set_variable(p_session_id, 'SALARIO_NORMAL', v_salario_normal, 'Salario promedio diario');
  PERFORM sp_nomina_set_variable(p_session_id, 'SALARIO_INTEGRAL', v_salario_integral, 'Salario integral diario');
  PERFORM sp_nomina_set_variable(p_session_id, 'BASE_UTIL', v_base_util, 'Base de utilidad');
  PERFORM sp_nomina_set_variable(p_session_id, 'DIAS_CALCULO', v_dias, 'Dias del calculo');
END;
$$;

-- =============================================
-- Funcion: sp_Nomina_CalcularDiasVacaciones
-- =============================================
CREATE OR REPLACE FUNCTION sp_nomina_calcular_dias_vacaciones(
  p_session_id VARCHAR(80),
  p_cedula VARCHAR(32),
  p_fecha_retiro DATE DEFAULT NULL,
  OUT p_dias_vacaciones NUMERIC(18,6),
  OUT p_dias_bono_vacacional NUMERIC(18,6)
)
RETURNS RECORD
LANGUAGE plpgsql AS $$
DECLARE
  v_fecha_retiro DATE;
  v_company_id INT;
  v_branch_id INT;
  v_hire_date DATE;
  v_years INT := 0;
  v_base_vac NUMERIC(18,6);
  v_base_bono NUMERIC(18,6);
BEGIN
  v_fecha_retiro := COALESCE(p_fecha_retiro, (NOW() AT TIME ZONE 'UTC')::DATE);

  v_base_vac := fn_nomina_get_variable(p_session_id, 'DIAS_VACACIONES_BASE');
  v_base_bono := fn_nomina_get_variable(p_session_id, 'DIAS_BONO_VAC_BASE');

  SELECT * INTO v_company_id, v_branch_id FROM sp_nomina_get_scope();

  SELECT e."HireDate" INTO v_hire_date
  FROM master."Employee" e
  WHERE e."CompanyId" = v_company_id
    AND e."EmployeeCode" = p_cedula
    AND e."IsDeleted" = FALSE
  LIMIT 1;

  IF v_base_vac <= 0 THEN v_base_vac := 15; END IF;
  IF v_base_bono <= 0 THEN v_base_bono := 15; END IF;

  IF v_hire_date IS NOT NULL THEN
    v_years := EXTRACT(YEAR FROM AGE(v_fecha_retiro, v_hire_date))::INT;
  END IF;

  IF v_years < 0 THEN v_years := 0; END IF;

  p_dias_vacaciones := v_base_vac + CASE WHEN v_years > 0 THEN (v_years - 1) ELSE 0 END;
  p_dias_bono_vacacional := v_base_bono + CASE WHEN v_years > 0 THEN (v_years - 1) ELSE 0 END;

  PERFORM sp_nomina_set_variable(p_session_id, 'DIAS_VACACIONES', p_dias_vacaciones, 'Dias vacaciones calculados');
  PERFORM sp_nomina_set_variable(p_session_id, 'DIAS_BONO_VAC', p_dias_bono_vacacional, 'Dias bono vacacional calculados');
END;
$$;

-- =============================================
-- Funcion: sp_Nomina_ProcesarVacaciones
-- =============================================
CREATE OR REPLACE FUNCTION sp_nomina_procesar_vacaciones(
  p_vacacion_id VARCHAR(50),
  p_cedula VARCHAR(32),
  p_fecha_inicio DATE,
  p_fecha_hasta DATE,
  p_fecha_reintegro DATE DEFAULT NULL,
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
  v_session_id VARCHAR(80) := 'VAC_' || p_vacacion_id;
  v_dias_vac NUMERIC(18,6);
  v_dias_bono NUMERIC(18,6);
  v_salario_integral NUMERIC(18,6);
  v_monto_vac NUMERIC(18,6);
  v_monto_bono NUMERIC(18,6);
  v_total NUMERIC(18,6);
  v_vacation_process_id BIGINT;
  v_fecha_desde_salarios DATE;
BEGIN
  p_resultado := 0;
  p_mensaje := '';

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
      p_mensaje := 'Empleado no encontrado o inactivo';
      RETURN;
    END IF;

    v_fecha_desde_salarios := p_fecha_inicio - INTERVAL '3 months';

    PERFORM sp_nomina_preparar_variables_base(v_session_id, p_cedula, 'VACACIONES', p_fecha_inicio, p_fecha_hasta);
    PERFORM sp_nomina_calcular_salarios_promedio(v_session_id, p_cedula, v_fecha_desde_salarios::DATE, p_fecha_inicio);

    SELECT r.p_dias_vacaciones, r.p_dias_bono_vacacional
    INTO v_dias_vac, v_dias_bono
    FROM sp_nomina_calcular_dias_vacaciones(v_session_id, p_cedula, NULL) r;

    v_salario_integral := fn_nomina_get_variable(v_session_id, 'SALARIO_INTEGRAL');
    IF v_salario_integral <= 0 THEN
      v_salario_integral := fn_nomina_get_variable(v_session_id, 'SALARIO_DIARIO');
    END IF;

    v_monto_vac := v_salario_integral * COALESCE(v_dias_vac, 0);
    v_monto_bono := v_salario_integral * COALESCE(v_dias_bono, 0);
    v_total := v_monto_vac + v_monto_bono;

    SELECT vp."VacationProcessId" INTO v_vacation_process_id
    FROM hr."VacationProcess" vp
    WHERE vp."CompanyId" = v_company_id
      AND vp."BranchId" = v_branch_id
      AND vp."VacationCode" = p_vacacion_id
    ORDER BY vp."VacationProcessId" DESC
    LIMIT 1;

    IF v_vacation_process_id IS NULL THEN
      INSERT INTO hr."VacationProcess" (
        "CompanyId", "BranchId", "VacationCode", "EmployeeId", "EmployeeCode", "EmployeeName",
        "StartDate", "EndDate", "ReintegrationDate", "ProcessDate",
        "TotalAmount", "CalculatedAmount",
        "CreatedAt", "UpdatedAt", "CreatedByUserId", "UpdatedByUserId"
      )
      VALUES (
        v_company_id, v_branch_id, p_vacacion_id, v_employee_id, p_cedula, v_employee_name,
        p_fecha_inicio, p_fecha_hasta, p_fecha_reintegro, (NOW() AT TIME ZONE 'UTC')::DATE,
        v_total, v_total,
        NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC', v_user_id, v_user_id
      )
      RETURNING "VacationProcessId" INTO v_vacation_process_id;
    ELSE
      UPDATE hr."VacationProcess"
      SET "EmployeeId" = v_employee_id,
          "EmployeeCode" = p_cedula,
          "EmployeeName" = v_employee_name,
          "StartDate" = p_fecha_inicio,
          "EndDate" = p_fecha_hasta,
          "ReintegrationDate" = p_fecha_reintegro,
          "ProcessDate" = (NOW() AT TIME ZONE 'UTC')::DATE,
          "TotalAmount" = v_total,
          "CalculatedAmount" = v_total,
          "UpdatedAt" = NOW() AT TIME ZONE 'UTC',
          "UpdatedByUserId" = v_user_id
      WHERE "VacationProcessId" = v_vacation_process_id;

      DELETE FROM hr."VacationProcessLine" WHERE "VacationProcessId" = v_vacation_process_id;
    END IF;

    INSERT INTO hr."VacationProcessLine" ("VacationProcessId", "ConceptCode", "ConceptName", "Amount", "CreatedAt")
    VALUES
      (v_vacation_process_id, 'VAC_PAGO', 'Pago vacaciones', v_monto_vac, NOW() AT TIME ZONE 'UTC'),
      (v_vacation_process_id, 'VAC_BONO', 'Bono vacacional', v_monto_bono, NOW() AT TIME ZONE 'UTC');

    PERFORM sp_nomina_limpiar_variables(v_session_id);

    p_resultado := 1;
    p_mensaje := 'Vacaciones procesadas. Total=' || CAST(v_total AS VARCHAR(40));

  EXCEPTION WHEN OTHERS THEN
    PERFORM sp_nomina_limpiar_variables(v_session_id);
    p_resultado := 0;
    p_mensaje := SQLERRM;
  END;
END;
$$;

-- =============================================
-- Funcion: sp_Nomina_CalcularLiquidacion
-- =============================================
CREATE OR REPLACE FUNCTION sp_nomina_calcular_liquidacion(
  p_liquidacion_id VARCHAR(50),
  p_cedula VARCHAR(32),
  p_fecha_retiro DATE,
  p_causa_retiro VARCHAR(50) DEFAULT 'RENUNCIA',
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
  v_hire_date DATE;
  v_session_id VARCHAR(80) := 'LIQ_' || p_liquidacion_id;
  v_service_years INT := 0;
  v_salario_diario NUMERIC(18,6);
  v_prestaciones NUMERIC(18,6);
  v_vac_pendientes NUMERIC(18,6);
  v_bono_salida NUMERIC(18,6);
  v_total NUMERIC(18,6);
  v_settlement_process_id BIGINT;
  v_fecha_desde_base DATE;
BEGIN
  p_resultado := 0;
  p_mensaje := '';

  BEGIN
    SELECT * INTO v_company_id, v_branch_id FROM sp_nomina_get_scope();

    SELECT u."UserId" INTO v_user_id
    FROM sec."User" u
    WHERE u."UserCode" = p_co_usuario AND u."IsDeleted" = FALSE
    LIMIT 1;

    SELECT e."EmployeeId", e."EmployeeName", e."HireDate"
    INTO v_employee_id, v_employee_name, v_hire_date
    FROM master."Employee" e
    WHERE e."CompanyId" = v_company_id
      AND e."EmployeeCode" = p_cedula
      AND e."IsDeleted" = FALSE
    LIMIT 1;

    IF v_employee_id IS NULL THEN
      p_mensaje := 'Empleado no encontrado';
      RETURN;
    END IF;

    v_fecha_desde_base := p_fecha_retiro - INTERVAL '1 month';
    PERFORM sp_nomina_preparar_variables_base(v_session_id, p_cedula, 'LIQUIDACION', v_fecha_desde_base::DATE, p_fecha_retiro);
    v_salario_diario := fn_nomina_get_variable(v_session_id, 'SALARIO_DIARIO');

    IF v_hire_date IS NOT NULL THEN
      v_service_years := EXTRACT(YEAR FROM AGE(p_fecha_retiro, v_hire_date))::INT;
    END IF;

    IF v_service_years < 0 THEN v_service_years := 0; END IF;
    IF v_salario_diario < 0 THEN v_salario_diario := 0; END IF;

    v_prestaciones := v_service_years * v_salario_diario * 30;
    v_vac_pendientes := v_salario_diario * 15;
    v_bono_salida := CASE WHEN UPPER(p_causa_retiro) = 'DESPIDO' THEN (v_salario_diario * 15) ELSE (v_salario_diario * 10) END;
    v_total := v_prestaciones + v_vac_pendientes + v_bono_salida;

    SELECT sp."SettlementProcessId" INTO v_settlement_process_id
    FROM hr."SettlementProcess" sp
    WHERE sp."CompanyId" = v_company_id
      AND sp."BranchId" = v_branch_id
      AND sp."SettlementCode" = p_liquidacion_id
    ORDER BY sp."SettlementProcessId" DESC
    LIMIT 1;

    IF v_settlement_process_id IS NULL THEN
      INSERT INTO hr."SettlementProcess" (
        "CompanyId", "BranchId", "SettlementCode", "EmployeeId", "EmployeeCode", "EmployeeName",
        "RetirementDate", "RetirementCause", "TotalAmount",
        "CreatedAt", "UpdatedAt", "CreatedByUserId", "UpdatedByUserId"
      )
      VALUES (
        v_company_id, v_branch_id, p_liquidacion_id, v_employee_id, p_cedula, v_employee_name,
        p_fecha_retiro, p_causa_retiro, v_total,
        NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC', v_user_id, v_user_id
      )
      RETURNING "SettlementProcessId" INTO v_settlement_process_id;
    ELSE
      UPDATE hr."SettlementProcess"
      SET "EmployeeId" = v_employee_id,
          "EmployeeCode" = p_cedula,
          "EmployeeName" = v_employee_name,
          "RetirementDate" = p_fecha_retiro,
          "RetirementCause" = p_causa_retiro,
          "TotalAmount" = v_total,
          "UpdatedAt" = NOW() AT TIME ZONE 'UTC',
          "UpdatedByUserId" = v_user_id
      WHERE "SettlementProcessId" = v_settlement_process_id;

      DELETE FROM hr."SettlementProcessLine" WHERE "SettlementProcessId" = v_settlement_process_id;
    END IF;

    INSERT INTO hr."SettlementProcessLine" ("SettlementProcessId", "ConceptCode", "ConceptName", "Amount", "CreatedAt")
    VALUES
      (v_settlement_process_id, 'LIQ_PREST', 'Prestaciones', v_prestaciones, NOW() AT TIME ZONE 'UTC'),
      (v_settlement_process_id, 'LIQ_VAC', 'Vacaciones pendientes', v_vac_pendientes, NOW() AT TIME ZONE 'UTC'),
      (v_settlement_process_id, 'LIQ_BONO', 'Bono de salida', v_bono_salida, NOW() AT TIME ZONE 'UTC');

    PERFORM sp_nomina_limpiar_variables(v_session_id);

    p_resultado := 1;
    p_mensaje := 'Liquidacion calculada. Total=' || CAST(v_total AS VARCHAR(40));

  EXCEPTION WHEN OTHERS THEN
    PERFORM sp_nomina_limpiar_variables(v_session_id);
    p_resultado := 0;
    p_mensaje := SQLERRM;
  END;
END;
$$;

-- =============================================
-- Funcion: sp_Nomina_GetLiquidacion
-- Retorna header, lineas y totales
-- =============================================
CREATE OR REPLACE FUNCTION sp_nomina_get_liquidacion_header(
  p_liquidacion_id VARCHAR(50)
)
RETURNS TABLE (
  "SettlementProcessId" BIGINT,
  "SettlementCode" VARCHAR,
  "Cedula" VARCHAR,
  "NombreEmpleado" VARCHAR,
  "RetirementDate" DATE,
  "RetirementCause" VARCHAR,
  "TotalAmount" NUMERIC,
  "CreatedAt" TIMESTAMP,
  "UpdatedAt" TIMESTAMP
)
LANGUAGE plpgsql AS $$
BEGIN
  RETURN QUERY
  SELECT
    sp."SettlementProcessId",
    sp."SettlementCode",
    sp."EmployeeCode" AS "Cedula",
    sp."EmployeeName" AS "NombreEmpleado",
    sp."RetirementDate",
    sp."RetirementCause",
    sp."TotalAmount",
    sp."CreatedAt",
    sp."UpdatedAt"
  FROM hr."SettlementProcess" sp
  WHERE sp."SettlementCode" = p_liquidacion_id
  ORDER BY sp."SettlementProcessId" DESC
  LIMIT 1;
END;
$$;

CREATE OR REPLACE FUNCTION sp_nomina_get_liquidacion_lines(
  p_liquidacion_id VARCHAR(50)
)
RETURNS TABLE (
  "SettlementProcessLineId" BIGINT,
  "ConceptCode" VARCHAR,
  "ConceptName" VARCHAR,
  "Amount" NUMERIC,
  "CreatedAt" TIMESTAMP
)
LANGUAGE plpgsql AS $$
BEGIN
  RETURN QUERY
  SELECT
    sl."SettlementProcessLineId",
    sl."ConceptCode",
    sl."ConceptName",
    sl."Amount",
    sl."CreatedAt"
  FROM hr."SettlementProcessLine" sl
  INNER JOIN hr."SettlementProcess" sp ON sp."SettlementProcessId" = sl."SettlementProcessId"
  WHERE sp."SettlementCode" = p_liquidacion_id
  ORDER BY sl."SettlementProcessLineId";
END;
$$;

CREATE OR REPLACE FUNCTION sp_nomina_get_liquidacion_totals(
  p_liquidacion_id VARCHAR(50)
)
RETURNS TABLE (
  "TotalAsignaciones" NUMERIC,
  "TotalDeducciones" NUMERIC,
  "TotalNeto" NUMERIC
)
LANGUAGE plpgsql AS $$
BEGIN
  RETURN QUERY
  SELECT
    SUM(CASE WHEN sl."Amount" > 0 THEN sl."Amount" ELSE 0 END) AS "TotalAsignaciones",
    SUM(CASE WHEN sl."Amount" < 0 THEN sl."Amount" ELSE 0 END) AS "TotalDeducciones",
    SUM(sl."Amount") AS "TotalNeto"
  FROM hr."SettlementProcessLine" sl
  INNER JOIN hr."SettlementProcess" sp ON sp."SettlementProcessId" = sl."SettlementProcessId"
  WHERE sp."SettlementCode" = p_liquidacion_id;
END;
$$;
