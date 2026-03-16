-- sp_nomina_calcular_antiguedad
CREATE OR REPLACE FUNCTION public.sp_nomina_calcular_antiguedad(p_session_id character varying, p_cedula character varying, p_fecha_calculo date DEFAULT NULL::date)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
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
$function$
;

-- sp_nomina_calcular_antiguedad_compat
CREATE OR REPLACE FUNCTION public.sp_nomina_calcular_antiguedad_compat(p_session_id character varying, p_cedula character varying, p_fecha_calculo date DEFAULT NULL::date)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
DECLARE
  v_fecha_calc DATE;
BEGIN
  v_fecha_calc := COALESCE(p_fecha_calculo, (NOW() AT TIME ZONE 'UTC')::DATE);
  PERFORM sp_nomina_set_variable_compat(p_session_id, 'ANTI_ANIOS', 0, 'Anios');
  PERFORM sp_nomina_set_variable_compat(p_session_id, 'ANTI_MESES', 0, 'Meses');
  PERFORM sp_nomina_set_variable_compat(p_session_id, 'ANTI_TOTAL_MESES', 0, 'Total meses');
END;
$function$
;

-- sp_nomina_calcular_concepto
CREATE OR REPLACE FUNCTION public.sp_nomina_calcular_concepto(p_session_id character varying, p_cedula character varying, p_co_concepto character varying, p_co_nomina character varying, p_cantidad numeric DEFAULT NULL::numeric, OUT p_monto numeric, OUT p_total numeric, OUT p_descripcion character varying)
 RETURNS record
 LANGUAGE plpgsql
AS $function$
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
$function$
;

-- sp_nomina_calcular_dias_vacaciones
CREATE OR REPLACE FUNCTION public.sp_nomina_calcular_dias_vacaciones(p_session_id character varying, p_cedula character varying, p_fecha_retiro date DEFAULT NULL::date, OUT p_dias_vacaciones numeric, OUT p_dias_bono_vacacional numeric)
 RETURNS record
 LANGUAGE plpgsql
AS $function$
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
$function$
;

-- sp_nomina_calcular_liquidacion
CREATE OR REPLACE FUNCTION public.sp_nomina_calcular_liquidacion(p_liquidacion_id character varying, p_cedula character varying, p_fecha_retiro date, p_causa_retiro character varying DEFAULT 'RENUNCIA'::character varying, p_co_usuario character varying DEFAULT 'API'::character varying, OUT p_resultado integer, OUT p_mensaje character varying)
 RETURNS record
 LANGUAGE plpgsql
AS $function$
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
    v_bono_salida := CASE WHEN UPPER(p_causa_retiro)::character varying = 'DESPIDO' THEN (v_salario_diario * 15) ELSE (v_salario_diario * 10) END;
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
$function$
;

-- sp_nomina_calcular_prestaciones_regimen
CREATE OR REPLACE FUNCTION public.sp_nomina_calcular_prestaciones_regimen(p_session_id character varying, p_regimen character varying, p_anios_servicio integer, p_meses_adicionales integer, p_salario_integral numeric, OUT p_prestaciones numeric, OUT p_intereses numeric)
 RETURNS record
 LANGUAGE plpgsql
AS $function$
DECLARE
  v_dias_anio NUMERIC(18,6);
  v_interes_anual NUMERIC(18,6);
  v_dias_totales NUMERIC(18,6);
BEGIN
  v_dias_anio := fn_nomina_get_variable(p_session_id, 'PREST_DIAS_ANIO');
  v_interes_anual := fn_nomina_get_variable(p_session_id, 'PREST_INTERES_ANUAL');

  IF v_dias_anio <= 0 THEN v_dias_anio := 30; END IF;
  IF v_interes_anual <= 0 THEN v_interes_anual := 0.15; END IF;

  v_dias_totales := (p_anios_servicio * v_dias_anio) + (p_meses_adicionales * (v_dias_anio / 12.0));
  p_prestaciones := p_salario_integral * v_dias_totales;
  p_intereses := p_prestaciones * v_interes_anual;

  PERFORM sp_nomina_set_variable(p_session_id, 'DIAS_PRESTACIONES', v_dias_totales, 'Dias prestaciones');
  PERFORM sp_nomina_set_variable(p_session_id, 'MONTO_PRESTACIONES', p_prestaciones, 'Monto prestaciones');
  PERFORM sp_nomina_set_variable(p_session_id, 'INTERESES_PRESTACIONES', p_intereses, 'Intereses prestaciones');
END;
$function$
;

-- sp_nomina_calcular_salarios_promedio
CREATE OR REPLACE FUNCTION public.sp_nomina_calcular_salarios_promedio(p_session_id character varying, p_cedula character varying, p_fecha_desde date, p_fecha_hasta date)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
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
$function$
;

-- sp_nomina_calcular_utilidades_regimen
CREATE OR REPLACE FUNCTION public.sp_nomina_calcular_utilidades_regimen(p_session_id character varying, p_regimen character varying, p_dias_trabajados_ano integer, p_salario_normal numeric, OUT p_utilidades numeric)
 RETURNS numeric
 LANGUAGE plpgsql
AS $function$
DECLARE
  v_dias_min NUMERIC(18,6);
  v_dias_max NUMERIC(18,6);
  v_dias_util NUMERIC(18,6);
BEGIN
  v_dias_min := fn_nomina_get_variable(p_session_id, 'DIAS_UTILIDADES_MIN');
  v_dias_max := fn_nomina_get_variable(p_session_id, 'DIAS_UTILIDADES_MAX');

  IF v_dias_min <= 0 THEN v_dias_min := 30; END IF;
  IF v_dias_max <= 0 THEN v_dias_max := 120; END IF;

  v_dias_util := CASE
    WHEN p_dias_trabajados_ano >= 365 THEN v_dias_max
    WHEN p_dias_trabajados_ano <= 0 THEN 0
    ELSE (v_dias_max * p_dias_trabajados_ano) / 365.0
  END;

  IF v_dias_util < v_dias_min AND p_dias_trabajados_ano > 0 THEN
    v_dias_util := v_dias_min;
  END IF;

  p_utilidades := p_salario_normal * v_dias_util;
  PERFORM sp_nomina_set_variable(p_session_id, 'DIAS_UTILIDADES', v_dias_util, 'Dias utilidades');
  PERFORM sp_nomina_set_variable(p_session_id, 'MONTO_UTILIDADES', p_utilidades, 'Monto utilidades');
END;
$function$
;

-- sp_nomina_calcular_vacaciones_regimen
CREATE OR REPLACE FUNCTION public.sp_nomina_calcular_vacaciones_regimen(p_session_id character varying, p_regimen character varying, p_anios_servicio integer, p_meses_periodo integer DEFAULT 12, OUT p_dias_vacaciones numeric, OUT p_dias_bono_vacacional numeric, OUT p_dias_bono_post_vacacional numeric)
 RETURNS record
 LANGUAGE plpgsql
AS $function$
DECLARE
  v_vac_base NUMERIC(18,6);
  v_bono_base NUMERIC(18,6);
BEGIN
  v_vac_base := fn_nomina_get_variable(p_session_id, 'DIAS_VACACIONES_BASE');
  v_bono_base := fn_nomina_get_variable(p_session_id, 'DIAS_BONO_VAC_BASE');

  IF v_vac_base <= 0 THEN v_vac_base := 15; END IF;
  IF v_bono_base <= 0 THEN v_bono_base := 15; END IF;

  p_dias_vacaciones := v_vac_base + CASE WHEN p_anios_servicio > 0 THEN (p_anios_servicio - 1) ELSE 0 END;
  p_dias_bono_vacacional := v_bono_base + CASE WHEN p_anios_servicio > 0 THEN (p_anios_servicio - 1) ELSE 0 END;
  p_dias_bono_post_vacacional := 0;

  PERFORM sp_nomina_set_variable(p_session_id, 'DIAS_VACACIONES', p_dias_vacaciones, 'Dias vacaciones (regimen)');
  PERFORM sp_nomina_set_variable(p_session_id, 'DIAS_BONO_VAC', p_dias_bono_vacacional, 'Dias bono vacacional (regimen)');
  PERFORM sp_nomina_set_variable(p_session_id, 'DIAS_BONO_POST_VAC', p_dias_bono_post_vacacional, 'Bono post vacacional');
END;
$function$
;

-- sp_nomina_cargar_constantes
CREATE OR REPLACE FUNCTION public.sp_nomina_cargar_constantes(p_session_id character varying)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
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
$function$
;

-- sp_nomina_cargar_constantes_desde_concepto_legal
CREATE OR REPLACE FUNCTION public.sp_nomina_cargar_constantes_desde_concepto_legal(p_session_id character varying, p_convencion character varying DEFAULT 'LOT'::character varying, p_tipo_calculo character varying DEFAULT 'MENSUAL'::character varying)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
DECLARE
  v_regimen VARCHAR(10) := UPPER(LEFT(COALESCE(p_convencion, 'LOT'), 10))::character varying;
  v_tipo_nomina VARCHAR(15) := UPPER(CASE WHEN p_tipo_calculo IN ('SEMANAL', 'QUINCENAL') THEN p_tipo_calculo ELSE 'MENSUAL' END)::character varying;
BEGIN
  PERFORM sp_nomina_cargar_constantes_regimen(p_session_id, v_regimen, v_tipo_nomina);
END;
$function$
;

-- sp_nomina_cargar_constantes_regimen
CREATE OR REPLACE FUNCTION public.sp_nomina_cargar_constantes_regimen(p_session_id character varying, p_regimen character varying DEFAULT 'LOT'::character varying, p_tipo_nomina character varying DEFAULT 'MENSUAL'::character varying)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
DECLARE
  v_company_id INT;
  v_branch_id INT;
  v_prefix VARCHAR(20) := UPPER(COALESCE(p_regimen, 'LOT'))::character varying || '_';
BEGIN
  SELECT * INTO v_company_id, v_branch_id FROM sp_nomina_get_scope();

  PERFORM sp_nomina_cargar_constantes(p_session_id);

  INSERT INTO hr."PayrollCalcVariable" ("SessionID", "Variable", "Valor", "Descripcion")
  SELECT
    p_session_id,
    REPLACE(pc."ConstantCode", v_prefix, ''),
    pc."ConstantValue",
    (pc."ConstantName" || ' [' || p_regimen || ']')
  FROM hr."PayrollConstant" pc
  WHERE pc."CompanyId" = v_company_id
    AND pc."IsActive" = TRUE
    AND pc."ConstantCode" LIKE v_prefix || '%'
    AND NOT EXISTS (
      SELECT 1
      FROM hr."PayrollCalcVariable" v
      WHERE v."SessionID" = p_session_id
        AND v."Variable" = REPLACE(pc."ConstantCode", v_prefix, '')
    );

  PERFORM sp_nomina_set_variable(p_session_id, 'REGIMEN_ID', 0, p_regimen);

  IF UPPER(p_tipo_nomina)::character varying = 'SEMANAL' THEN
    PERFORM sp_nomina_set_variable(p_session_id, 'DIAS_PERIODO', 7, 'Dias periodo semanal');
  ELSIF UPPER(p_tipo_nomina)::character varying = 'QUINCENAL' THEN
    PERFORM sp_nomina_set_variable(p_session_id, 'DIAS_PERIODO', 15, 'Dias periodo quincenal');
  END IF;
END;
$function$
;

-- sp_nomina_cerrar
CREATE OR REPLACE FUNCTION public.sp_nomina_cerrar(p_nomina character varying, p_cedula character varying DEFAULT NULL::character varying, p_co_usuario character varying DEFAULT 'API'::character varying)
 RETURNS TABLE("Resultado" integer, "Mensaje" character varying)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_company_id INT;
    v_branch_id  INT;
    v_user_id    INT := NULL;
    v_rows       INT;
BEGIN
    SELECT * INTO v_company_id, v_branch_id FROM public.sp_Nomina_GetScope();

    SELECT u."UserId" INTO v_user_id
    FROM sec."User" u
    WHERE u."UserCode" = p_co_usuario
      AND u."IsDeleted" = FALSE
    LIMIT 1;

    UPDATE hr."PayrollRun"
    SET "IsClosed"        = TRUE,
        "ClosedAt"        = NOW() AT TIME ZONE 'UTC',
        "ClosedByUserId"  = v_user_id,
        "UpdatedAt"       = NOW() AT TIME ZONE 'UTC',
        "UpdatedByUserId" = v_user_id
    WHERE "CompanyId" = v_company_id
      AND "BranchId" = v_branch_id
      AND "PayrollCode" = p_nomina
      AND (p_cedula IS NULL OR "EmployeeCode" = p_cedula)
      AND "IsClosed" = FALSE;

    GET DIAGNOSTICS v_rows = ROW_COUNT;

    RETURN QUERY SELECT 1, ('Registros cerrados: ' || v_rows::VARCHAR)::VARCHAR;
END;
$function$
;

-- sp_nomina_concepto_save
CREATE OR REPLACE FUNCTION public.sp_nomina_concepto_save(p_co_concept character varying, p_co_nomina character varying, p_nb_concepto character varying, p_formula text DEFAULT NULL::text, p_sobre character varying DEFAULT NULL::character varying, p_clase character varying DEFAULT NULL::character varying, p_tipo character varying DEFAULT NULL::character varying, p_uso character varying DEFAULT NULL::character varying, p_bonificable character varying DEFAULT NULL::character varying, p_antiguedad character varying DEFAULT NULL::character varying, p_contable character varying DEFAULT NULL::character varying, p_aplica character varying DEFAULT 'S'::character varying, p_defecto double precision DEFAULT NULL::double precision)
 RETURNS TABLE("Resultado" integer, "Mensaje" character varying)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_company_id  INT;
    v_branch_id   INT;
    v_resultado   INT := 0;
    v_mensaje     VARCHAR(500) := '';
    v_bonif       BOOLEAN;
    v_antig       BOOLEAN;
    v_aplica_flag BOOLEAN;
    v_defecto_val NUMERIC(18,6);
BEGIN
    SELECT * INTO v_company_id, v_branch_id FROM public.sp_Nomina_GetScope();

    v_bonif       := UPPER(COALESCE(p_bonificable, 'S'))::character varying IN ('S', '1');
    v_antig       := UPPER(COALESCE(p_antiguedad, 'N'))::character varying IN ('S', '1');
    v_aplica_flag := UPPER(COALESCE(p_aplica, 'S'))::character varying IN ('S', '1');
    v_defecto_val := COALESCE(p_defecto::NUMERIC(18,6), 0);

    IF EXISTS (
        SELECT 1 FROM hr."PayrollConcept"
        WHERE "CompanyId" = v_company_id
          AND "PayrollCode" = p_co_nomina
          AND "ConceptCode" = p_co_concept
          AND COALESCE("ConventionCode", '') = ''
          AND COALESCE("CalculationType", '') = ''
    ) THEN
        UPDATE hr."PayrollConcept"
        SET "ConceptName"           = p_nb_concepto,
            "Formula"               = p_formula,
            "BaseExpression"        = p_sobre,
            "ConceptClass"          = p_clase,
            "ConceptType"           = COALESCE(p_tipo, 'ASIGNACION'),
            "UsageType"             = p_uso,
            "IsBonifiable"          = v_bonif,
            "IsSeniority"           = v_antig,
            "AccountingAccountCode" = p_contable,
            "AppliesFlag"           = v_aplica_flag,
            "DefaultValue"          = v_defecto_val,
            "UpdatedAt"             = NOW() AT TIME ZONE 'UTC',
            "IsActive"              = TRUE
        WHERE "CompanyId" = v_company_id
          AND "PayrollCode" = p_co_nomina
          AND "ConceptCode" = p_co_concept
          AND COALESCE("ConventionCode", '') = ''
          AND COALESCE("CalculationType", '') = '';

        v_resultado := 1;
        v_mensaje   := 'Concepto actualizado';
    ELSE
        INSERT INTO hr."PayrollConcept" (
            "CompanyId", "PayrollCode", "ConceptCode", "ConceptName",
            "Formula", "BaseExpression", "ConceptClass", "ConceptType",
            "UsageType", "IsBonifiable", "IsSeniority",
            "AccountingAccountCode", "AppliesFlag", "DefaultValue",
            "ConventionCode", "CalculationType", "LotttArticle", "CcpClause",
            "SortOrder", "IsActive", "CreatedAt", "UpdatedAt"
        )
        VALUES (
            v_company_id, p_co_nomina, p_co_concept, p_nb_concepto,
            p_formula, p_sobre, p_clase, COALESCE(p_tipo, 'ASIGNACION'),
            p_uso, v_bonif, v_antig,
            p_contable, v_aplica_flag, v_defecto_val,
            NULL, NULL, NULL, NULL,
            0, TRUE, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'
        );

        v_resultado := 1;
        v_mensaje   := 'Concepto creado';
    END IF;

    RETURN QUERY SELECT v_resultado, v_mensaje;
END;
$function$
;

-- sp_nomina_conceptos_legales_list
CREATE OR REPLACE FUNCTION public.sp_nomina_conceptos_legales_list(p_convencion character varying DEFAULT NULL::character varying, p_tipo_calculo character varying DEFAULT NULL::character varying, p_tipo character varying DEFAULT NULL::character varying, p_activo boolean DEFAULT true)
 RETURNS TABLE("Id" bigint, "Convencion" character varying, "TipoCalculo" character varying, "CO_CONCEPT" character varying, "NB_CONCEPTO" character varying, "Formula" character varying, "SOBRE" character varying, "TIPO" character varying, "BONIFICABLE" character varying, "LOTTT_Articulo" character varying, "CCP_Clausula" character varying, "Orden" integer, "Activo" boolean, "CO_NOMINA" character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
  RETURN QUERY
  SELECT
    pc."PayrollConceptId" AS "Id",
    pc."ConventionCode" AS "Convencion",
    pc."CalculationType" AS "TipoCalculo",
    pc."ConceptCode" AS "CO_CONCEPT",
    pc."ConceptName" AS "NB_CONCEPTO",
    pc."Formula"::TEXT AS "Formula",
    pc."BaseExpression"::TEXT AS "SOBRE",
    pc."ConceptType" AS "TIPO",
    CASE WHEN pc."IsBonifiable" = TRUE THEN 'S'::VARCHAR(1) ELSE 'N'::VARCHAR(1) END AS "BONIFICABLE",
    pc."LotttArticle" AS "LOTTT_Articulo",
    pc."CcpClause" AS "CCP_Clausula",
    pc."SortOrder" AS "Orden",
    pc."IsActive" AS "Activo",
    pc."PayrollCode" AS "CO_NOMINA"
  FROM hr."PayrollConcept" pc
  WHERE pc."ConventionCode" IS NOT NULL
    AND (p_convencion IS NULL OR pc."ConventionCode" = p_convencion)
    AND (p_tipo_calculo IS NULL OR pc."CalculationType" = p_tipo_calculo)
    AND (p_tipo IS NULL OR pc."ConceptType" = p_tipo)
    AND (p_activo IS NULL OR pc."IsActive" = p_activo)
  ORDER BY pc."ConventionCode", pc."CalculationType", pc."SortOrder", pc."ConceptCode";
END;
$function$
;

-- sp_nomina_conceptos_list
CREATE OR REPLACE FUNCTION public.sp_nomina_conceptos_list(p_co_nomina character varying DEFAULT NULL::character varying, p_tipo character varying DEFAULT NULL::character varying, p_search character varying DEFAULT NULL::character varying, p_page integer DEFAULT 1, p_limit integer DEFAULT 50)
 RETURNS TABLE("TotalCount" integer, "Codigo" character varying, "CodigoNomina" character varying, "Nombre" character varying, "Formula" character varying, "Sobre" character varying, "Clase" character varying, "Tipo" character varying, "Uso" character varying, "Bonificable" character varying, "Antiguedad" character varying, "Contable" character varying, "Aplica" character varying, "Defecto" double precision, "Convencion" character varying, "TipoCalculo" character varying, "Orden" integer, "Activo" boolean)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_company_id INT;
    v_branch_id  INT;
    v_offset     INT;
    v_total      INT;
BEGIN
    v_offset := (p_page - 1) * p_limit;

    SELECT * INTO v_company_id, v_branch_id FROM public.sp_Nomina_GetScope();

    SELECT COUNT(1) INTO v_total
    FROM hr."PayrollConcept" pc
    WHERE pc."CompanyId" = v_company_id
      AND (p_co_nomina IS NULL OR pc."PayrollCode" = p_co_nomina)
      AND (p_tipo IS NULL OR pc."ConceptType" = p_tipo)
      AND (
          p_search IS NULL
          OR pc."ConceptName" ILIKE '%' || p_search || '%'
          OR pc."ConceptCode" ILIKE '%' || p_search || '%'
      );

    RETURN QUERY
    SELECT
        v_total,
        pc."ConceptCode",
        pc."PayrollCode",
        pc."ConceptName",
        pc."Formula",
        pc."BaseExpression",
        pc."ConceptClass",
        pc."ConceptType",
        pc."UsageType",
        CASE WHEN pc."IsBonifiable" THEN 'S' ELSE 'N' END,
        CASE WHEN pc."IsSeniority"  THEN 'S' ELSE 'N' END,
        pc."AccountingAccountCode",
        CASE WHEN pc."AppliesFlag"  THEN 'S' ELSE 'N' END,
        pc."DefaultValue"::DOUBLE PRECISION,
        pc."ConventionCode",
        pc."CalculationType",
        pc."SortOrder",
        pc."IsActive"
    FROM hr."PayrollConcept" pc
    WHERE pc."CompanyId" = v_company_id
      AND (p_co_nomina IS NULL OR pc."PayrollCode" = p_co_nomina)
      AND (p_tipo IS NULL OR pc."ConceptType" = p_tipo)
      AND (
          p_search IS NULL
          OR pc."ConceptName" ILIKE '%' || p_search || '%'
          OR pc."ConceptCode" ILIKE '%' || p_search || '%'
      )
    ORDER BY pc."PayrollCode", pc."SortOrder", pc."ConceptCode"
    LIMIT p_limit OFFSET v_offset;
END;
$function$
;

-- sp_nomina_constante_save
CREATE OR REPLACE FUNCTION public.sp_nomina_constante_save(p_codigo character varying, p_nombre character varying DEFAULT NULL::character varying, p_valor double precision DEFAULT NULL::double precision, p_origen character varying DEFAULT NULL::character varying)
 RETURNS TABLE("Resultado" integer, "Mensaje" character varying)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_company_id INT;
    v_branch_id  INT;
    v_resultado  INT := 0;
    v_mensaje    VARCHAR(500) := '';
BEGIN
    SELECT * INTO v_company_id, v_branch_id FROM public.sp_Nomina_GetScope();

    IF EXISTS (
        SELECT 1 FROM hr."PayrollConstant"
        WHERE "CompanyId" = v_company_id
          AND "ConstantCode" = p_codigo
    ) THEN
        UPDATE hr."PayrollConstant"
        SET "ConstantName"  = COALESCE(p_nombre, "ConstantName"),
            "ConstantValue" = COALESCE(p_valor::NUMERIC(18,6), "ConstantValue"),
            "SourceName"    = COALESCE(p_origen, "SourceName"),
            "IsActive"      = TRUE,
            "UpdatedAt"     = NOW() AT TIME ZONE 'UTC'
        WHERE "CompanyId" = v_company_id
          AND "ConstantCode" = p_codigo;

        v_resultado := 1;
        v_mensaje   := 'Constante actualizada';
    ELSE
        INSERT INTO hr."PayrollConstant" (
            "CompanyId", "ConstantCode", "ConstantName", "ConstantValue", "SourceName",
            "IsActive", "CreatedAt", "UpdatedAt"
        )
        VALUES (
            v_company_id,
            p_codigo,
            COALESCE(p_nombre, p_codigo),
            COALESCE(p_valor::NUMERIC(18,6), 0),
            p_origen,
            TRUE,
            NOW() AT TIME ZONE 'UTC',
            NOW() AT TIME ZONE 'UTC'
        );

        v_resultado := 1;
        v_mensaje   := 'Constante creada';
    END IF;

    RETURN QUERY SELECT v_resultado, v_mensaje;
END;
$function$
;

-- sp_nomina_constantes_list
CREATE OR REPLACE FUNCTION public.sp_nomina_constantes_list(p_page integer DEFAULT 1, p_limit integer DEFAULT 50)
 RETURNS TABLE("TotalCount" integer, "Codigo" character varying, "Nombre" character varying, "Valor" numeric, "Origen" character varying, "IsActive" boolean)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_company_id INT;
    v_branch_id  INT;
    v_offset     INT;
    v_total      INT;
BEGIN
    v_offset := (p_page - 1) * p_limit;

    SELECT * INTO v_company_id, v_branch_id FROM public.sp_Nomina_GetScope();

    SELECT COUNT(1) INTO v_total
    FROM hr."PayrollConstant" pc
    WHERE pc."CompanyId" = v_company_id;

    RETURN QUERY
    SELECT
        v_total,
        pc."ConstantCode",
        pc."ConstantName",
        pc."ConstantValue",
        pc."SourceName",
        pc."IsActive"
    FROM hr."PayrollConstant" pc
    WHERE pc."CompanyId" = v_company_id
    ORDER BY pc."ConstantCode"
    LIMIT p_limit OFFSET v_offset;
END;
$function$
;

-- sp_nomina_evaluar_formula
CREATE OR REPLACE FUNCTION public.sp_nomina_evaluar_formula(p_session_id character varying, p_formula text, OUT p_resultado numeric, OUT p_formula_resuelta text)
 RETURNS record
 LANGUAGE plpgsql
AS $function$
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
$function$
;

-- sp_nomina_get
CREATE OR REPLACE FUNCTION public.sp_nomina_get(p_nomina character varying, p_cedula character varying)
 RETURNS TABLE("PayrollRunId" bigint, "NOMINA" character varying, "CEDULA" character varying, "NombreEmpleado" character varying, "FECHA" timestamp without time zone, "INICIO" date, "HASTA" date, "ASIGNACION" numeric, "DEDUCCION" numeric, "TOTAL" numeric, "CERRADA" boolean, "TipoNomina" character varying)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_company_id INT;
    v_branch_id  INT;
BEGIN
    SELECT * INTO v_company_id, v_branch_id FROM public.sp_Nomina_GetScope();

    RETURN QUERY
    SELECT
        pr."PayrollRunId",
        pr."PayrollCode",
        pr."EmployeeCode",
        pr."EmployeeName",
        pr."ProcessDate",
        pr."DateFrom",
        pr."DateTo",
        pr."TotalAssignments",
        pr."TotalDeductions",
        pr."NetTotal",
        pr."IsClosed",
        pr."PayrollTypeName"
    FROM hr."PayrollRun" pr
    WHERE pr."CompanyId" = v_company_id
      AND pr."BranchId" = v_branch_id
      AND pr."PayrollCode" = p_nomina
      AND pr."EmployeeCode" = p_cedula
    ORDER BY pr."ProcessDate" DESC, pr."PayrollRunId" DESC
    LIMIT 1;
END;
$function$
;

-- sp_nomina_get_lines
CREATE OR REPLACE FUNCTION public.sp_nomina_get_lines(p_nomina character varying, p_cedula character varying)
 RETURNS TABLE("PayrollRunLineId" bigint, "CO_CONCEPTO" character varying, "NombreConcepto" character varying, "TIPO" character varying, "CANTIDAD" numeric, "MONTO" numeric, "Total" numeric)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_company_id INT;
    v_branch_id  INT;
    v_run_id     BIGINT;
BEGIN
    SELECT * INTO v_company_id, v_branch_id FROM public.sp_Nomina_GetScope();

    SELECT pr."PayrollRunId" INTO v_run_id
    FROM hr."PayrollRun" pr
    WHERE pr."CompanyId" = v_company_id
      AND pr."BranchId" = v_branch_id
      AND pr."PayrollCode" = p_nomina
      AND pr."EmployeeCode" = p_cedula
    ORDER BY pr."ProcessDate" DESC, pr."PayrollRunId" DESC
    LIMIT 1;

    RETURN QUERY
    SELECT
        rl."PayrollRunLineId",
        rl."ConceptCode",
        rl."ConceptName",
        rl."ConceptType",
        rl."Quantity",
        rl."Amount",
        rl."Total"
    FROM hr."PayrollRunLine" rl
    WHERE rl."PayrollRunId" = v_run_id
    ORDER BY rl."PayrollRunLineId";
END;
$function$
;

-- sp_nomina_get_liquidacion_header
CREATE OR REPLACE FUNCTION public.sp_nomina_get_liquidacion_header(p_liquidacion_id character varying)
 RETURNS TABLE("SettlementProcessId" bigint, "SettlementCode" character varying, "Cedula" character varying, "NombreEmpleado" character varying, "RetirementDate" date, "RetirementCause" character varying, "TotalAmount" numeric, "CreatedAt" timestamp without time zone, "UpdatedAt" timestamp without time zone)
 LANGUAGE plpgsql
AS $function$
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
$function$
;

-- sp_nomina_get_liquidacion_lines
CREATE OR REPLACE FUNCTION public.sp_nomina_get_liquidacion_lines(p_liquidacion_id character varying)
 RETURNS TABLE("SettlementProcessLineId" bigint, "ConceptCode" character varying, "ConceptName" character varying, "Amount" numeric, "CreatedAt" timestamp without time zone)
 LANGUAGE plpgsql
AS $function$
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
$function$
;

-- sp_nomina_get_liquidacion_totals
CREATE OR REPLACE FUNCTION public.sp_nomina_get_liquidacion_totals(p_liquidacion_id character varying)
 RETURNS TABLE("TotalAsignaciones" numeric, "TotalDeducciones" numeric, "TotalNeto" numeric)
 LANGUAGE plpgsql
AS $function$
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
$function$
;

-- sp_nomina_get_scope
CREATE OR REPLACE FUNCTION public.sp_nomina_get_scope(OUT p_company_id integer, OUT p_branch_id integer)
 RETURNS record
 LANGUAGE plpgsql
AS $function$
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
$function$
;

-- sp_nomina_limpiar_variables
CREATE OR REPLACE FUNCTION public.sp_nomina_limpiar_variables(p_session_id character varying)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
  DELETE FROM hr."PayrollCalcVariable" WHERE "SessionID" = p_session_id;
END;
$function$
;

-- sp_nomina_limpiar_variables_compat
CREATE OR REPLACE FUNCTION public.sp_nomina_limpiar_variables_compat(p_session_id character varying)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
  DELETE FROM hr."PayrollCalcVariable" WHERE "SessionID" = p_session_id;
END;
$function$
;

-- sp_nomina_liquidaciones_list
CREATE OR REPLACE FUNCTION public.sp_nomina_liquidaciones_list(p_cedula character varying DEFAULT NULL::character varying, p_page integer DEFAULT 1, p_limit integer DEFAULT 50)
 RETURNS TABLE("TotalCount" integer, "SettlementProcessId" bigint, "Liquidacion" character varying, "Cedula" character varying, "NombreEmpleado" character varying, "FechaRetiro" date, "CausaRetiro" character varying, "TotalLiquidacion" numeric, "FechaCalculo" timestamp without time zone)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_company_id INT;
    v_branch_id  INT;
    v_offset     INT;
    v_total      INT;
BEGIN
    v_offset := (p_page - 1) * p_limit;

    SELECT * INTO v_company_id, v_branch_id FROM public.sp_Nomina_GetScope();

    SELECT COUNT(1) INTO v_total
    FROM hr."SettlementProcess" sp
    WHERE sp."CompanyId" = v_company_id
      AND sp."BranchId" = v_branch_id
      AND (p_cedula IS NULL OR sp."EmployeeCode" = p_cedula);

    RETURN QUERY
    SELECT
        v_total,
        sp."SettlementProcessId",
        sp."SettlementCode",
        sp."EmployeeCode",
        sp."EmployeeName",
        sp."RetirementDate",
        sp."RetirementCause",
        sp."TotalAmount",
        sp."CreatedAt"
    FROM hr."SettlementProcess" sp
    WHERE sp."CompanyId" = v_company_id
      AND sp."BranchId" = v_branch_id
      AND (p_cedula IS NULL OR sp."EmployeeCode" = p_cedula)
    ORDER BY sp."CreatedAt" DESC, sp."SettlementProcessId" DESC
    LIMIT p_limit OFFSET v_offset;
END;
$function$
;

-- sp_nomina_list
CREATE OR REPLACE FUNCTION public.sp_nomina_list(p_nomina character varying DEFAULT NULL::character varying, p_cedula character varying DEFAULT NULL::character varying, p_fecha_desde date DEFAULT NULL::date, p_fecha_hasta date DEFAULT NULL::date, p_solo_abiertas boolean DEFAULT false, p_page integer DEFAULT 1, p_limit integer DEFAULT 50)
 RETURNS TABLE("TotalCount" integer, "PayrollRunId" bigint, "NOMINA" character varying, "CEDULA" character varying, "NOMBRE" character varying, "FECHA" timestamp without time zone, "INICIO" date, "HASTA" date, "ASIGNACION" numeric, "DEDUCCION" numeric, "TOTAL" numeric, "CERRADA" boolean, "TipoNomina" character varying)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_company_id INT;
    v_branch_id  INT;
    v_offset     INT;
    v_total      INT;
BEGIN
    v_offset := (p_page - 1) * p_limit;

    SELECT * INTO v_company_id, v_branch_id FROM public.sp_Nomina_GetScope();

    SELECT COUNT(1) INTO v_total
    FROM hr."PayrollRun" pr
    WHERE pr."CompanyId" = v_company_id
      AND pr."BranchId" = v_branch_id
      AND (p_nomina IS NULL OR pr."PayrollCode" = p_nomina)
      AND (p_cedula IS NULL OR pr."EmployeeCode" = p_cedula)
      AND (p_fecha_desde IS NULL OR pr."DateFrom" >= p_fecha_desde)
      AND (p_fecha_hasta IS NULL OR pr."DateTo" <= p_fecha_hasta)
      AND (NOT p_solo_abiertas OR pr."IsClosed" = FALSE);

    RETURN QUERY
    SELECT
        v_total,
        pr."PayrollRunId",
        pr."PayrollCode",
        pr."EmployeeCode",
        pr."EmployeeName",
        pr."ProcessDate",
        pr."DateFrom",
        pr."DateTo",
        pr."TotalAssignments",
        pr."TotalDeductions",
        pr."NetTotal",
        pr."IsClosed",
        pr."PayrollTypeName"
    FROM hr."PayrollRun" pr
    WHERE pr."CompanyId" = v_company_id
      AND pr."BranchId" = v_branch_id
      AND (p_nomina IS NULL OR pr."PayrollCode" = p_nomina)
      AND (p_cedula IS NULL OR pr."EmployeeCode" = p_cedula)
      AND (p_fecha_desde IS NULL OR pr."DateFrom" >= p_fecha_desde)
      AND (p_fecha_hasta IS NULL OR pr."DateTo" <= p_fecha_hasta)
      AND (NOT p_solo_abiertas OR pr."IsClosed" = FALSE)
    ORDER BY pr."ProcessDate" DESC, pr."PayrollRunId" DESC
    LIMIT p_limit OFFSET v_offset;
END;
$function$
;

-- sp_nomina_preparar_variables_base
CREATE OR REPLACE FUNCTION public.sp_nomina_preparar_variables_base(p_session_id character varying, p_cedula character varying, p_nomina character varying, p_fecha_inicio date, p_fecha_hasta date)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
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
$function$
;

-- sp_nomina_preparar_variables_regimen
CREATE OR REPLACE FUNCTION public.sp_nomina_preparar_variables_regimen(p_session_id character varying, p_cedula character varying, p_nomina character varying, p_tipo_nomina character varying, p_regimen character varying DEFAULT NULL::character varying, p_fecha_inicio date DEFAULT NULL::date, p_fecha_hasta date DEFAULT NULL::date)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
DECLARE
  v_reg VARCHAR(10) := UPPER(COALESCE(p_regimen, p_nomina))::character varying;
BEGIN
  IF v_reg = '' THEN v_reg := 'LOT'; END IF;

  PERFORM sp_nomina_preparar_variables_base(p_session_id, p_cedula, p_nomina, p_fecha_inicio, p_fecha_hasta);
  PERFORM sp_nomina_cargar_constantes_regimen(p_session_id, v_reg, p_tipo_nomina);
END;
$function$
;

-- sp_nomina_procesar_empleado
CREATE OR REPLACE FUNCTION public.sp_nomina_procesar_empleado(p_nomina character varying, p_cedula character varying, p_fecha_inicio date, p_fecha_hasta date, p_co_usuario character varying DEFAULT 'API'::character varying, OUT p_resultado integer, OUT p_mensaje character varying)
 RETURNS record
 LANGUAGE plpgsql
AS $function$
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

      IF UPPER(COALESCE(rec."ConceptType", ''))::character varying = 'DEDUCCION' THEN
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
$function$
;

-- sp_nomina_procesar_empleado_concepto_legal
CREATE OR REPLACE FUNCTION public.sp_nomina_procesar_empleado_concepto_legal(p_nomina character varying, p_cedula character varying, p_fecha_inicio date, p_fecha_hasta date, p_convencion character varying DEFAULT NULL::character varying, p_tipo_calculo character varying DEFAULT 'MENSUAL'::character varying, p_co_usuario character varying DEFAULT 'API'::character varying, OUT p_resultado integer, OUT p_mensaje character varying)
 RETURNS record
 LANGUAGE plpgsql
AS $function$
DECLARE
  v_regimen VARCHAR(10) := UPPER(COALESCE(p_convencion, p_nomina))::character varying;
BEGIN
  SELECT r.p_resultado, r.p_mensaje
  INTO p_resultado, p_mensaje
  FROM sp_nomina_procesar_empleado_regimen(
    p_nomina, p_cedula, p_fecha_inicio, p_fecha_hasta, v_regimen, p_co_usuario
  ) r;
END;
$function$
;

-- sp_nomina_procesar_empleado_regimen
CREATE OR REPLACE FUNCTION public.sp_nomina_procesar_empleado_regimen(p_nomina character varying, p_cedula character varying, p_fecha_inicio date, p_fecha_hasta date, p_regimen character varying DEFAULT NULL::character varying, p_co_usuario character varying DEFAULT 'API'::character varying, OUT p_resultado integer, OUT p_mensaje character varying)
 RETURNS record
 LANGUAGE plpgsql
AS $function$
DECLARE
  v_reg VARCHAR(10) := UPPER(COALESCE(p_regimen, p_nomina))::character varying;
  v_tipo_calculo VARCHAR(20) := 'MENSUAL';
  v_session_id VARCHAR(80) := p_nomina || '_' || p_cedula || '_' || to_char(NOW() AT TIME ZONE 'UTC', 'YYYYMMDD');
  v_nomina_proceso VARCHAR(20);
BEGIN
  IF UPPER(p_nomina)::character varying LIKE '%VAC%' THEN v_tipo_calculo := 'VACACIONES'; END IF;
  IF UPPER(p_nomina)::character varying LIKE '%LIQ%' THEN v_tipo_calculo := 'LIQUIDACION'; END IF;

  -- Reusar procesamiento base canonico
  v_nomina_proceso := CASE WHEN v_reg IS NULL OR v_reg = '' THEN p_nomina ELSE v_reg END;

  SELECT r.p_resultado, r.p_mensaje
  INTO p_resultado, p_mensaje
  FROM sp_nomina_procesar_empleado(
    v_nomina_proceso, p_cedula, p_fecha_inicio, p_fecha_hasta, p_co_usuario
  ) r;

  IF p_resultado = 1 THEN
    PERFORM sp_nomina_set_variable(v_session_id, 'TIPO_CALCULO_ID', 0, v_tipo_calculo);
  END IF;
END;
$function$
;

-- sp_nomina_procesar_nomina
CREATE OR REPLACE FUNCTION public.sp_nomina_procesar_nomina(p_nomina character varying, p_fecha_inicio date, p_fecha_hasta date, p_co_usuario character varying DEFAULT 'API'::character varying, p_solo_activos boolean DEFAULT true, OUT p_procesados integer, OUT p_errores integer, OUT p_mensaje character varying)
 RETURNS record
 LANGUAGE plpgsql
AS $function$
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
$function$
;

-- sp_nomina_procesar_vacaciones
CREATE OR REPLACE FUNCTION public.sp_nomina_procesar_vacaciones(p_vacacion_id character varying, p_cedula character varying, p_fecha_inicio date, p_fecha_hasta date, p_fecha_reintegro date DEFAULT NULL::date, p_co_usuario character varying DEFAULT 'API'::character varying, OUT p_resultado integer, OUT p_mensaje character varying)
 RETURNS record
 LANGUAGE plpgsql
AS $function$
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
$function$
;

-- sp_nomina_reemplazar_variables
CREATE OR REPLACE FUNCTION public.sp_nomina_reemplazar_variables(p_session_id character varying, p_formula text)
 RETURNS text
 LANGUAGE plpgsql
AS $function$
DECLARE
  v_result TEXT := COALESCE(p_formula, '');
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
$function$
;

-- sp_nomina_set_variable
CREATE OR REPLACE FUNCTION public.sp_nomina_set_variable(p_session_id character varying, p_variable character varying, p_valor numeric, p_descripcion character varying DEFAULT NULL::character varying)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
  INSERT INTO hr."PayrollCalcVariable" ("SessionID", "Variable", "Valor", "Descripcion")
  VALUES (p_session_id, p_variable, p_valor, p_descripcion)
  ON CONFLICT ("SessionID", "Variable") DO UPDATE SET
    "Valor" = EXCLUDED."Valor",
    "Descripcion" = EXCLUDED."Descripcion",
    "UpdatedAt" = NOW() AT TIME ZONE 'UTC';
END;
$function$
;

-- sp_nomina_set_variable_compat
CREATE OR REPLACE FUNCTION public.sp_nomina_set_variable_compat(p_session_id character varying, p_variable character varying, p_valor numeric, p_descripcion character varying DEFAULT NULL::character varying)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
  INSERT INTO hr."PayrollCalcVariable" ("SessionID", "Variable", "Valor", "Descripcion")
  VALUES (p_session_id, p_variable, p_valor, p_descripcion)
  ON CONFLICT ("SessionID", "Variable") DO UPDATE SET
    "Valor" = EXCLUDED."Valor",
    "Descripcion" = EXCLUDED."Descripcion",
    "UpdatedAt" = NOW() AT TIME ZONE 'UTC';
END;
$function$
;

-- sp_nomina_vacaciones_get
CREATE OR REPLACE FUNCTION public.sp_nomina_vacaciones_get(p_vacacion_id character varying)
 RETURNS TABLE("VacationProcessId" bigint, "VacationCode" character varying, "CompanyId" integer, "BranchId" integer, "EmployeeCode" character varying, "EmployeeName" character varying, "StartDate" date, "EndDate" date, "ReintegrationDate" date, "ProcessDate" timestamp without time zone, "TotalAmount" numeric, "CalculatedAmount" numeric)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        vp."VacationProcessId",
        vp."VacationCode",
        vp."CompanyId",
        vp."BranchId",
        vp."EmployeeCode",
        vp."EmployeeName",
        vp."StartDate",
        vp."EndDate",
        vp."ReintegrationDate",
        vp."ProcessDate",
        vp."TotalAmount",
        vp."CalculatedAmount"
    FROM hr."VacationProcess" vp
    WHERE vp."VacationCode" = p_vacacion_id
    LIMIT 1;
END;
$function$
;

-- sp_nomina_vacaciones_get_lines
CREATE OR REPLACE FUNCTION public.sp_nomina_vacaciones_get_lines(p_vacacion_id character varying)
 RETURNS TABLE("VacationProcessLineId" bigint, "VacationProcessId" bigint, "ConceptCode" character varying, "ConceptName" character varying, "Quantity" numeric, "Amount" numeric, "Total" numeric)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        vl."VacationProcessLineId",
        vl."VacationProcessId",
        vl."ConceptCode",
        vl."ConceptName",
        vl."Quantity",
        vl."Amount",
        vl."Total"
    FROM hr."VacationProcessLine" vl
    INNER JOIN hr."VacationProcess" vp ON vp."VacationProcessId" = vl."VacationProcessId"
    WHERE vp."VacationCode" = p_vacacion_id
    ORDER BY vl."VacationProcessLineId";
END;
$function$
;

-- sp_nomina_vacaciones_list
CREATE OR REPLACE FUNCTION public.sp_nomina_vacaciones_list(p_cedula character varying DEFAULT NULL::character varying, p_page integer DEFAULT 1, p_limit integer DEFAULT 50)
 RETURNS TABLE("TotalCount" integer, "VacationProcessId" bigint, "Vacacion" character varying, "Cedula" character varying, "NombreEmpleado" character varying, "Inicio" date, "Hasta" date, "Reintegro" date, "Fecha_Calculo" timestamp without time zone, "Total" numeric, "TotalCalculado" numeric)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_company_id INT;
    v_branch_id  INT;
    v_offset     INT;
    v_total      INT;
BEGIN
    v_offset := (p_page - 1) * p_limit;

    SELECT * INTO v_company_id, v_branch_id FROM public.sp_Nomina_GetScope();

    SELECT COUNT(1) INTO v_total
    FROM hr."VacationProcess" vp
    WHERE vp."CompanyId" = v_company_id
      AND vp."BranchId" = v_branch_id
      AND (p_cedula IS NULL OR vp."EmployeeCode" = p_cedula);

    RETURN QUERY
    SELECT
        v_total,
        vp."VacationProcessId",
        vp."VacationCode",
        vp."EmployeeCode",
        vp."EmployeeName",
        vp."StartDate",
        vp."EndDate",
        vp."ReintegrationDate",
        vp."ProcessDate",
        vp."TotalAmount",
        vp."CalculatedAmount"
    FROM hr."VacationProcess" vp
    WHERE vp."CompanyId" = v_company_id
      AND vp."BranchId" = v_branch_id
      AND (p_cedula IS NULL OR vp."EmployeeCode" = p_cedula)
    ORDER BY vp."ProcessDate" DESC, vp."VacationProcessId" DESC
    LIMIT p_limit OFFSET v_offset;
END;
$function$
;

-- sp_nomina_validar_formulas_concepto_legal
CREATE OR REPLACE FUNCTION public.sp_nomina_validar_formulas_concepto_legal(p_convencion character varying DEFAULT NULL::character varying, p_tipo_calculo character varying DEFAULT NULL::character varying)
 RETURNS TABLE("Id" bigint, "CO_CONCEPT" character varying, "NB_CONCEPTO" character varying, "FORMULA" character varying, "Error" character varying, "EsValida" boolean)
 LANGUAGE plpgsql
AS $function$
DECLARE
  rec RECORD;
  v_result NUMERIC(18,6);
  v_formula_resuelta TEXT;
  v_session_test VARCHAR(80) := 'TEST_' || to_char(NOW() AT TIME ZONE 'UTC', 'YYYYMMDD');
BEGIN
  -- Crear tabla temporal para resultados
  CREATE TEMP TABLE IF NOT EXISTS tmp_resultados (
    "Id" BIGINT,
    "CO_CONCEPT" VARCHAR(20),
    "NB_CONCEPTO" VARCHAR(120),
    "FORMULA" TEXT,
    "Error" VARCHAR(500),
    "EsValida" BOOLEAN
  ) ON COMMIT DROP;

  DELETE FROM tmp_resultados;

  PERFORM sp_nomina_limpiar_variables(v_session_test);
  PERFORM sp_nomina_set_variable(v_session_test, 'SUELDO', 30000, 'Test');
  PERFORM sp_nomina_set_variable(v_session_test, 'SALARIO_DIARIO', 1000, 'Test');
  PERFORM sp_nomina_set_variable(v_session_test, 'DIAS_PERIODO', 30, 'Test');
  PERFORM sp_nomina_set_variable(v_session_test, 'PCT_SSO', 0.04, 'Test');

  FOR rec IN
    SELECT "PayrollConceptId", "ConceptCode", "ConceptName", "Formula"
    FROM hr."PayrollConcept"
    WHERE "ConventionCode" IS NOT NULL
      AND (p_convencion IS NULL OR "ConventionCode" = p_convencion)
      AND (p_tipo_calculo IS NULL OR "CalculationType" = p_tipo_calculo)
      AND "IsActive" = TRUE
    ORDER BY "ConventionCode", "CalculationType", "SortOrder", "ConceptCode"
  LOOP
    IF rec."Formula" IS NULL OR TRIM(rec."Formula") = '' THEN
      INSERT INTO tmp_resultados VALUES (rec."PayrollConceptId", rec."ConceptCode", rec."ConceptName", rec."Formula", 'Sin formula (usa valor por defecto)', TRUE);
    ELSIF rec."Formula" ~ '[^A-Za-z0-9_\.+\-\*/\(\) ]' THEN
      INSERT INTO tmp_resultados VALUES (rec."PayrollConceptId", rec."ConceptCode", rec."ConceptName", rec."Formula", 'Contiene caracteres no permitidos', FALSE);
    ELSE
      BEGIN
        SELECT r.p_resultado, r.p_formula_resuelta
        INTO v_result, v_formula_resuelta
        FROM sp_nomina_evaluar_formula(v_session_test, rec."Formula") r;

        INSERT INTO tmp_resultados VALUES (rec."PayrollConceptId", rec."ConceptCode", rec."ConceptName", rec."Formula", NULL, TRUE);
      EXCEPTION WHEN OTHERS THEN
        INSERT INTO tmp_resultados VALUES (rec."PayrollConceptId", rec."ConceptCode", rec."ConceptName", rec."Formula", SQLERRM, FALSE);
      END;
    END IF;
  END LOOP;

  PERFORM sp_nomina_limpiar_variables(v_session_test);

  RETURN QUERY SELECT t."Id", t."CO_CONCEPT", t."NB_CONCEPTO", t."FORMULA", t."Error", t."EsValida"
  FROM tmp_resultados t
  ORDER BY t."EsValida" ASC, t."CO_CONCEPT";
END;
$function$
;

-- usp_empleados_delete
CREATE OR REPLACE FUNCTION public.usp_empleados_delete(p_cedula character varying)
 RETURNS TABLE("Resultado" integer, "Mensaje" character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public."Empleados" WHERE "CEDULA" = p_cedula) THEN
        RETURN QUERY SELECT -1, 'Empleado no encontrado'::VARCHAR(500);
        RETURN;
    END IF;

    DELETE FROM public."Empleados" WHERE "CEDULA" = p_cedula;

    RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
END;
$function$
;

-- usp_empleados_getbycedula
CREATE OR REPLACE FUNCTION public.usp_empleados_getbycedula(p_cedula character varying)
 RETURNS TABLE("CEDULA" character varying, "GRUPO" character varying, "NOMBRE" character varying, "DIRECCION" character varying, "TELEFONO" character varying, "NACIMIENTO" timestamp without time zone, "CARGO" character varying, "NOMINA" character varying, "SUELDO" double precision, "INGRESO" timestamp without time zone, "RETIRO" timestamp without time zone, "STATUS" character varying, "COMISION" double precision, "UTILIDAD" double precision, "CO_Usuario" character varying, "SEXO" character varying, "NACIONALIDAD" character varying, "Autoriza" boolean, "Apodo" character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        e."CEDULA",
        e."GRUPO",
        e."NOMBRE",
        e."DIRECCION",
        e."TELEFONO",
        e."NACIMIENTO",
        e."CARGO",
        e."NOMINA",
        e."SUELDO",
        e."INGRESO",
        e."RETIRO",
        e."STATUS",
        e."COMISION",
        e."UTILIDAD",
        e."CO_Usuario",
        e."SEXO",
        e."NACIONALIDAD",
        e."Autoriza",
        e."Apodo"
    FROM public."Empleados" e
    WHERE e."CEDULA" = p_cedula;
END;
$function$
;

-- usp_empleados_insert
CREATE OR REPLACE FUNCTION public.usp_empleados_insert(p_row_json jsonb)
 RETURNS TABLE("Resultado" integer, "Mensaje" character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
    -- Verificar duplicado
    IF EXISTS (
        SELECT 1 FROM public."Empleados"
        WHERE "CEDULA" = (p_row_json->>'CEDULA')
    ) THEN
        RETURN QUERY SELECT -1, 'Empleado ya existe'::VARCHAR(500);
        RETURN;
    END IF;

    INSERT INTO public."Empleados" (
        "CEDULA", "GRUPO", "NOMBRE", "DIRECCION", "TELEFONO", "NACIMIENTO",
        "CARGO", "NOMINA", "SUELDO", "INGRESO", "RETIRO", "STATUS",
        "COMISION", "UTILIDAD", "CO_Usuario", "SEXO", "NACIONALIDAD",
        "Autoriza", "Apodo"
    ) VALUES (
        NULLIF(p_row_json->>'CEDULA', ''::character varying),
        NULLIF(p_row_json->>'GRUPO', ''::character varying),
        NULLIF(p_row_json->>'NOMBRE', ''::character varying),
        NULLIF(p_row_json->>'DIRECCION', ''::character varying),
        NULLIF(p_row_json->>'TELEFONO', ''::character varying),
        CASE WHEN COALESCE(p_row_json->>'NACIMIENTO', '') = '' THEN NULL
             ELSE (p_row_json->>'NACIMIENTO')::TIMESTAMP END,
        NULLIF(p_row_json->>'CARGO', ''::character varying),
        NULLIF(p_row_json->>'NOMINA', ''::character varying),
        CASE WHEN COALESCE(p_row_json->>'SUELDO', '') = '' THEN NULL
             ELSE (p_row_json->>'SUELDO')::DOUBLE PRECISION END,
        CASE WHEN COALESCE(p_row_json->>'INGRESO', '') = '' THEN NULL
             ELSE (p_row_json->>'INGRESO')::TIMESTAMP END,
        CASE WHEN COALESCE(p_row_json->>'RETIRO', '') = '' THEN NULL
             ELSE (p_row_json->>'RETIRO')::TIMESTAMP END,
        NULLIF(p_row_json->>'STATUS', ''::character varying),
        CASE WHEN COALESCE(p_row_json->>'COMISION', '') = '' THEN NULL
             ELSE (p_row_json->>'COMISION')::DOUBLE PRECISION END,
        CASE WHEN COALESCE(p_row_json->>'UTILIDAD', '') = '' THEN NULL
             ELSE (p_row_json->>'UTILIDAD')::DOUBLE PRECISION END,
        NULLIF(p_row_json->>'CO_Usuario', ''::character varying),
        NULLIF(p_row_json->>'SEXO', ''::character varying),
        NULLIF(p_row_json->>'NACIONALIDAD', ''::character varying),
        COALESCE((p_row_json->>'Autoriza')::BOOLEAN, FALSE),
        NULLIF(p_row_json->>'Apodo', ''::character varying)
    );

    RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
END;
$function$
;

-- usp_empleados_list
CREATE OR REPLACE FUNCTION public.usp_empleados_list(p_search character varying DEFAULT NULL::character varying, p_grupo character varying DEFAULT NULL::character varying, p_status character varying DEFAULT NULL::character varying, p_page integer DEFAULT 1, p_limit integer DEFAULT 50)
 RETURNS TABLE("TotalCount" integer, "CEDULA" character varying, "GRUPO" character varying, "NOMBRE" character varying, "DIRECCION" character varying, "TELEFONO" character varying, "NACIMIENTO" timestamp without time zone, "CARGO" character varying, "NOMINA" character varying, "SUELDO" double precision, "INGRESO" timestamp without time zone, "RETIRO" timestamp without time zone, "STATUS" character varying, "COMISION" double precision, "UTILIDAD" double precision, "CO_Usuario" character varying, "SEXO" character varying, "NACIONALIDAD" character varying, "Autoriza" boolean, "Apodo" character varying)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_offset  INT;
    v_limit   INT;
    v_search  VARCHAR(100);
    v_total   INT;
BEGIN
    v_limit  := COALESCE(NULLIF(p_limit, 0), 50)::character varying;
    IF v_limit < 1 THEN v_limit := 50; END IF;
    IF v_limit > 500 THEN v_limit := 500; END IF;
    v_offset := (COALESCE(NULLIF(p_page, 0), 1)::character varying - 1) * v_limit;
    IF v_offset < 0 THEN v_offset := 0; END IF;

    v_search := NULL;
    IF p_search IS NOT NULL AND TRIM(p_search) <> '' THEN
        v_search := '%' || p_search || '%';
    END IF;

    -- Contar total
    SELECT COUNT(1) INTO v_total
    FROM public."Empleados" e
    WHERE (v_search IS NULL OR e."CEDULA" LIKE v_search OR e."NOMBRE" LIKE v_search OR e."CARGO" LIKE v_search)
      AND (p_grupo IS NULL OR TRIM(p_grupo) = '' OR e."GRUPO" = p_grupo)
      AND (p_status IS NULL OR TRIM(p_status) = '' OR e."STATUS" = p_status);

    -- Devolver filas
    RETURN QUERY
    SELECT
        v_total,
        e."CEDULA",
        e."GRUPO",
        e."NOMBRE",
        e."DIRECCION",
        e."TELEFONO",
        e."NACIMIENTO",
        e."CARGO",
        e."NOMINA",
        e."SUELDO",
        e."INGRESO",
        e."RETIRO",
        e."STATUS",
        e."COMISION",
        e."UTILIDAD",
        e."CO_Usuario",
        e."SEXO",
        e."NACIONALIDAD",
        e."Autoriza",
        e."Apodo"
    FROM public."Empleados" e
    WHERE (v_search IS NULL OR e."CEDULA" LIKE v_search OR e."NOMBRE" LIKE v_search OR e."CARGO" LIKE v_search)
      AND (p_grupo IS NULL OR TRIM(p_grupo) = '' OR e."GRUPO" = p_grupo)
      AND (p_status IS NULL OR TRIM(p_status) = '' OR e."STATUS" = p_status)
    ORDER BY e."NOMBRE"
    LIMIT v_limit OFFSET v_offset;
END;
$function$
;

-- usp_empleados_update
CREATE OR REPLACE FUNCTION public.usp_empleados_update(p_cedula character varying, p_row_json jsonb)
 RETURNS TABLE("Resultado" integer, "Mensaje" character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public."Empleados" WHERE "CEDULA" = p_cedula) THEN
        RETURN QUERY SELECT -1, 'Empleado no encontrado'::VARCHAR(500);
        RETURN;
    END IF;

    UPDATE public."Empleados" SET
        "GRUPO"        = COALESCE(NULLIF(p_row_json->>'GRUPO', ''::character varying), "GRUPO")::character varying,
        "NOMBRE"       = COALESCE(NULLIF(p_row_json->>'NOMBRE', ''::character varying), "NOMBRE")::character varying,
        "DIRECCION"    = COALESCE(NULLIF(p_row_json->>'DIRECCION', ''::character varying), "DIRECCION")::character varying,
        "TELEFONO"     = COALESCE(NULLIF(p_row_json->>'TELEFONO', ''::character varying), "TELEFONO")::character varying,
        "CARGO"        = COALESCE(NULLIF(p_row_json->>'CARGO', ''::character varying), "CARGO")::character varying,
        "NOMINA"       = COALESCE(NULLIF(p_row_json->>'NOMINA', ''::character varying), "NOMINA")::character varying,
        "SUELDO"       = CASE WHEN COALESCE(p_row_json->>'SUELDO', '') = '' THEN "SUELDO"
                              ELSE (p_row_json->>'SUELDO')::DOUBLE PRECISION END,
        "STATUS"       = COALESCE(NULLIF(p_row_json->>'STATUS', ''::character varying), "STATUS")::character varying,
        "COMISION"     = CASE WHEN COALESCE(p_row_json->>'COMISION', '') = '' THEN "COMISION"
                              ELSE (p_row_json->>'COMISION')::DOUBLE PRECISION END,
        "SEXO"         = COALESCE(NULLIF(p_row_json->>'SEXO', ''::character varying), "SEXO")::character varying,
        "NACIONALIDAD" = COALESCE(NULLIF(p_row_json->>'NACIONALIDAD', ''::character varying), "NACIONALIDAD")::character varying,
        "Autoriza"     = COALESCE((p_row_json->>'Autoriza')::BOOLEAN, "Autoriza")
    WHERE "CEDULA" = p_cedula;

    RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
END;
$function$
;

-- usp_hr_committee_addmember
CREATE OR REPLACE FUNCTION public.usp_hr_committee_addmember(p_safety_committee_id integer, p_company_id integer, p_employee_id bigint DEFAULT NULL::bigint, p_employee_code character varying DEFAULT NULL::character varying, p_employee_name character varying DEFAULT NULL::character varying, p_role character varying DEFAULT NULL::character varying, p_start_date date DEFAULT NULL::date, p_end_date date DEFAULT NULL::date, OUT p_resultado integer, OUT p_mensaje character varying)
 RETURNS record
 LANGUAGE plpgsql
AS $function$
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    IF p_role NOT IN ('PRESIDENT','SECRETARY','DELEGATE','EMPLOYER_REP') THEN
        p_resultado := -1;
        p_mensaje   := 'Rol no válido.';
        RETURN;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM hr."SafetyCommittee"
        WHERE "SafetyCommitteeId" = p_safety_committee_id AND "CompanyId" = p_company_id
    ) THEN
        p_resultado := -1;
        p_mensaje   := 'Comité no encontrado.';
        RETURN;
    END IF;

    IF EXISTS (
        SELECT 1 FROM hr."SafetyCommitteeMember"
        WHERE "SafetyCommitteeId" = p_safety_committee_id
          AND "EmployeeCode" = p_employee_code
          AND ("EndDate" IS NULL OR "EndDate" >= p_start_date)
    ) THEN
        p_resultado := -1;
        p_mensaje   := 'El empleado ya es miembro activo de este comité.';
        RETURN;
    END IF;

    BEGIN
        INSERT INTO hr."SafetyCommitteeMember" (
            "SafetyCommitteeId", "EmployeeId", "EmployeeCode", "EmployeeName",
            "Role", "StartDate", "EndDate"
        )
        VALUES (
            p_safety_committee_id, p_employee_id, p_employee_code, p_employee_name,
            p_role, p_start_date, p_end_date
        )
        RETURNING "MemberId" INTO p_resultado;

        p_mensaje := 'Miembro agregado exitosamente al comité.';

    EXCEPTION WHEN OTHERS THEN
        p_resultado := -1;
        p_mensaje   := SQLERRM;
    END;
END;
$function$
;

-- usp_hr_committee_getmeetings
CREATE OR REPLACE FUNCTION public.usp_hr_committee_getmeetings(p_safety_committee_id integer, p_company_id integer, p_from_date date DEFAULT NULL::date, p_to_date date DEFAULT NULL::date, p_page integer DEFAULT 1, p_limit integer DEFAULT 50)
 RETURNS TABLE(p_total_count bigint, "MeetingId" integer, "SafetyCommitteeId" integer, "MeetingDate" date, "MinutesUrl" character varying, "TopicsSummary" character varying, "ActionItems" character varying, "CreatedAt" timestamp without time zone, "CommitteeName" character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
    IF p_page  < 1   THEN p_page  := 1;   END IF;
    IF p_limit < 1   THEN p_limit := 50;  END IF;
    IF p_limit > 500 THEN p_limit := 500; END IF;

    -- Verificar que el comité pertenece a la empresa
    IF NOT EXISTS (
        SELECT 1 FROM hr."SafetyCommittee"
        WHERE "SafetyCommitteeId" = p_safety_committee_id AND "CompanyId" = p_company_id
    ) THEN
        RETURN;
    END IF;

    RETURN QUERY
    SELECT
        COUNT(*) OVER()         AS p_total_count,
        m."MeetingId",
        m."SafetyCommitteeId",
        m."MeetingDate",
        m."MinutesUrl",
        m."TopicsSummary",
        m."ActionItems",
        m."CreatedAt",
        sc."CommitteeName"
    FROM hr."SafetyCommitteeMeeting" m
    INNER JOIN hr."SafetyCommittee" sc ON sc."SafetyCommitteeId" = m."SafetyCommitteeId"
    WHERE m."SafetyCommitteeId" = p_safety_committee_id
      AND (p_from_date IS NULL OR m."MeetingDate" >= p_from_date)
      AND (p_to_date   IS NULL OR m."MeetingDate" <= p_to_date)
    ORDER BY m."MeetingDate" DESC
    LIMIT p_limit OFFSET (p_page - 1) * p_limit;
END;
$function$
;

-- usp_hr_committee_list
CREATE OR REPLACE FUNCTION public.usp_hr_committee_list(p_company_id integer, p_country_code character DEFAULT NULL::bpchar, p_is_active boolean DEFAULT NULL::boolean, p_page integer DEFAULT 1, p_limit integer DEFAULT 50)
 RETURNS TABLE(p_total_count bigint, "SafetyCommitteeId" integer, "CompanyId" integer, "CountryCode" character, "CommitteeName" character varying, "FormationDate" date, "MeetingFrequency" character varying, "IsActive" boolean, "CreatedAt" timestamp without time zone, "ActiveMemberCount" bigint, "TotalMeetings" bigint)
 LANGUAGE plpgsql
AS $function$
BEGIN
    IF p_page  < 1   THEN p_page  := 1;   END IF;
    IF p_limit < 1   THEN p_limit := 50;  END IF;
    IF p_limit > 500 THEN p_limit := 500; END IF;

    RETURN QUERY
    SELECT
        COUNT(*) OVER()         AS p_total_count,
        sc."SafetyCommitteeId",
        sc."CompanyId",
        sc."CountryCode",
        sc."CommitteeName",
        sc."FormationDate",
        sc."MeetingFrequency",
        sc."IsActive",
        sc."CreatedAt",
        (
            SELECT COUNT(*) FROM hr."SafetyCommitteeMember" m
            WHERE m."SafetyCommitteeId" = sc."SafetyCommitteeId"
              AND (m."EndDate" IS NULL OR m."EndDate" >= CAST((NOW() AT TIME ZONE 'UTC') AS DATE))
        )::BIGINT AS "ActiveMemberCount",
        (
            SELECT COUNT(*) FROM hr."SafetyCommitteeMeeting" mt
            WHERE mt."SafetyCommitteeId" = sc."SafetyCommitteeId"
        )::BIGINT AS "TotalMeetings"
    FROM hr."SafetyCommittee" sc
    WHERE sc."CompanyId" = p_company_id
      AND (p_country_code IS NULL OR sc."CountryCode" = p_country_code)
      AND (p_is_active    IS NULL OR sc."IsActive"    = p_is_active)
    ORDER BY sc."IsActive" DESC, sc."FormationDate" DESC
    LIMIT p_limit OFFSET (p_page - 1) * p_limit;
END;
$function$
;

-- usp_hr_committee_recordmeeting
CREATE OR REPLACE FUNCTION public.usp_hr_committee_recordmeeting(p_safety_committee_id integer, p_company_id integer, p_meeting_date timestamp without time zone, p_minutes_url character varying DEFAULT NULL::character varying, p_topics_summary text DEFAULT NULL::text, p_action_items text DEFAULT NULL::text, OUT p_resultado integer, OUT p_mensaje character varying)
 RETURNS record
 LANGUAGE plpgsql
AS $function$
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    IF NOT EXISTS (
        SELECT 1 FROM hr."SafetyCommittee"
        WHERE "SafetyCommitteeId" = p_safety_committee_id AND "CompanyId" = p_company_id
    ) THEN
        p_resultado := -1;
        p_mensaje   := 'Comité no encontrado.';
        RETURN;
    END IF;

    BEGIN
        INSERT INTO hr."SafetyCommitteeMeeting" (
            "SafetyCommitteeId", "MeetingDate", "MinutesUrl",
            "TopicsSummary", "ActionItems", "CreatedAt"
        )
        VALUES (
            p_safety_committee_id, p_meeting_date, p_minutes_url,
            p_topics_summary, p_action_items,
            (NOW() AT TIME ZONE 'UTC')
        )
        RETURNING "MeetingId" INTO p_resultado;

        p_mensaje := 'Reunión registrada exitosamente.';

    EXCEPTION WHEN OTHERS THEN
        p_resultado := -1;
        p_mensaje   := SQLERRM;
    END;
END;
$function$
;

-- usp_hr_committee_removemember
CREATE OR REPLACE FUNCTION public.usp_hr_committee_removemember(p_member_id integer, p_safety_committee_id integer, p_company_id integer, p_end_date date DEFAULT NULL::date, OUT p_resultado integer, OUT p_mensaje character varying)
 RETURNS record
 LANGUAGE plpgsql
AS $function$
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    IF p_end_date IS NULL THEN
        p_end_date := CAST((NOW() AT TIME ZONE 'UTC') AS DATE);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM hr."SafetyCommittee"
        WHERE "SafetyCommitteeId" = p_safety_committee_id AND "CompanyId" = p_company_id
    ) THEN
        p_resultado := -1;
        p_mensaje   := 'Comité no encontrado.';
        RETURN;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM hr."SafetyCommitteeMember"
        WHERE "MemberId" = p_member_id AND "SafetyCommitteeId" = p_safety_committee_id
    ) THEN
        p_resultado := -1;
        p_mensaje   := 'Miembro no encontrado en este comité.';
        RETURN;
    END IF;

    BEGIN
        UPDATE hr."SafetyCommitteeMember"
        SET "EndDate" = p_end_date
        WHERE "MemberId" = p_member_id
          AND "SafetyCommitteeId" = p_safety_committee_id;

        p_resultado := p_member_id;
        p_mensaje   := 'Miembro removido del comité exitosamente.';

    EXCEPTION WHEN OTHERS THEN
        p_resultado := -1;
        p_mensaje   := SQLERRM;
    END;
END;
$function$
;

-- usp_hr_committee_save
CREATE OR REPLACE FUNCTION public.usp_hr_committee_save(p_safety_committee_id integer DEFAULT NULL::integer, p_company_id integer DEFAULT NULL::integer, p_country_code character DEFAULT NULL::bpchar, p_committee_name character varying DEFAULT NULL::character varying, p_formation_date date DEFAULT NULL::date, p_meeting_frequency character varying DEFAULT 'MONTHLY'::character varying, p_is_active boolean DEFAULT true, OUT p_resultado integer, OUT p_mensaje character varying)
 RETURNS record
 LANGUAGE plpgsql
AS $function$
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    BEGIN
        IF p_safety_committee_id IS NULL THEN
            INSERT INTO hr."SafetyCommittee" (
                "CompanyId", "CountryCode", "CommitteeName",
                "FormationDate", "MeetingFrequency", "IsActive", "CreatedAt"
            )
            VALUES (
                p_company_id, p_country_code, p_committee_name,
                p_formation_date, p_meeting_frequency, p_is_active,
                (NOW() AT TIME ZONE 'UTC')
            )
            RETURNING "SafetyCommitteeId" INTO p_resultado;

            p_mensaje := 'Comité de seguridad creado exitosamente.';
        ELSE
            IF NOT EXISTS (
                SELECT 1 FROM hr."SafetyCommittee"
                WHERE "SafetyCommitteeId" = p_safety_committee_id AND "CompanyId" = p_company_id
            ) THEN
                p_resultado := -1;
                p_mensaje   := 'Comité no encontrado.';
                RETURN;
            END IF;

            UPDATE hr."SafetyCommittee"
            SET
                "CountryCode"      = p_country_code,
                "CommitteeName"    = p_committee_name,
                "FormationDate"    = p_formation_date,
                "MeetingFrequency" = p_meeting_frequency,
                "IsActive"         = p_is_active
            WHERE "SafetyCommitteeId" = p_safety_committee_id
              AND "CompanyId" = p_company_id;

            p_resultado := p_safety_committee_id;
            p_mensaje   := 'Comité de seguridad actualizado exitosamente.';
        END IF;

    EXCEPTION WHEN OTHERS THEN
        p_resultado := -1;
        p_mensaje   := SQLERRM;
    END;
END;
$function$
;

-- usp_hr_documenttemplate_delete
CREATE OR REPLACE FUNCTION public.usp_hr_documenttemplate_delete(p_company_id integer, p_template_code character varying, OUT p_resultado integer, OUT p_mensaje text)
 RETURNS record
 LANGUAGE plpgsql
AS $function$
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    IF EXISTS (
        SELECT 1 FROM hr."DocumentTemplate"
        WHERE "CompanyId"    = p_company_id
          AND "TemplateCode" = p_template_code
          AND "IsSystem"     = TRUE
    ) THEN
        p_resultado := -1;
        p_mensaje   := 'No se puede eliminar una plantilla del sistema.';
        RETURN;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM hr."DocumentTemplate"
        WHERE "CompanyId"    = p_company_id
          AND "TemplateCode" = p_template_code
    ) THEN
        p_resultado := -2;
        p_mensaje   := 'Plantilla no encontrada.';
        RETURN;
    END IF;

    DELETE FROM hr."DocumentTemplate"
    WHERE "CompanyId"    = p_company_id
      AND "TemplateCode" = p_template_code;

    p_resultado := 1;
    p_mensaje   := 'Plantilla eliminada correctamente.';
END;
$function$
;

-- usp_hr_documenttemplate_get
CREATE OR REPLACE FUNCTION public.usp_hr_documenttemplate_get(p_company_id integer, p_template_code character varying)
 RETURNS TABLE("TemplateId" integer, "TemplateCode" character varying, "TemplateName" character varying, "TemplateType" character varying, "CountryCode" character, "PayrollCode" character varying, "ContentMD" character varying, "IsDefault" boolean, "IsSystem" boolean, "IsActive" boolean, "CreatedAt" timestamp without time zone, "UpdatedAt" timestamp without time zone)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        t."TemplateId",
        t."TemplateCode",
        t."TemplateName",
        t."TemplateType",
        t."CountryCode",
        t."PayrollCode",
        t."ContentMD",
        t."IsDefault",
        t."IsSystem",
        t."IsActive",
        t."CreatedAt",
        t."UpdatedAt"
    FROM hr."DocumentTemplate" t
    WHERE t."CompanyId"    = p_company_id
      AND t."TemplateCode" = p_template_code;
END;
$function$
;

-- usp_hr_documenttemplate_list
CREATE OR REPLACE FUNCTION public.usp_hr_documenttemplate_list(p_company_id integer, p_country_code character DEFAULT NULL::bpchar, p_template_type character varying DEFAULT NULL::character varying)
 RETURNS TABLE("TemplateId" integer, "TemplateCode" character varying, "TemplateName" character varying, "TemplateType" character varying, "CountryCode" character, "PayrollCode" character varying, "IsDefault" boolean, "IsSystem" boolean, "IsActive" boolean, "UpdatedAt" timestamp without time zone)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        t."TemplateId",
        t."TemplateCode",
        t."TemplateName",
        t."TemplateType",
        t."CountryCode",
        t."PayrollCode",
        t."IsDefault",
        t."IsSystem",
        t."IsActive",
        t."UpdatedAt"
    FROM hr."DocumentTemplate" t
    WHERE t."CompanyId" = p_company_id
      AND t."IsActive"  = TRUE
      AND (p_country_code  IS NULL OR t."CountryCode"  = p_country_code)
      AND (p_template_type IS NULL OR t."TemplateType" = p_template_type)
    ORDER BY t."CountryCode", t."TemplateType", t."TemplateName";
END;
$function$
;

-- usp_hr_documenttemplate_save
CREATE OR REPLACE FUNCTION public.usp_hr_documenttemplate_save(p_company_id integer, p_template_code character varying, p_template_name character varying, p_template_type character varying, p_country_code character, p_content_md text, p_payroll_code character varying DEFAULT NULL::character varying, p_is_default boolean DEFAULT true, OUT p_resultado integer, OUT p_mensaje text)
 RETURNS record
 LANGUAGE plpgsql
AS $function$
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    -- Proteger plantillas del sistema
    IF EXISTS (
        SELECT 1 FROM hr."DocumentTemplate"
        WHERE "CompanyId"    = p_company_id
          AND "TemplateCode" = p_template_code
          AND "IsSystem"     = TRUE
    ) THEN
        p_resultado := -1;
        p_mensaje   := 'No se puede modificar una plantilla del sistema.';
        RETURN;
    END IF;

    -- MERGE equivalente en PostgreSQL usando INSERT ... ON CONFLICT
    INSERT INTO hr."DocumentTemplate" (
        "CompanyId", "TemplateCode", "TemplateName", "TemplateType",
        "CountryCode", "PayrollCode", "ContentMD", "IsDefault",
        "IsSystem", "IsActive", "CreatedAt", "UpdatedAt"
    )
    VALUES (
        p_company_id, p_template_code, p_template_name, p_template_type,
        p_country_code, p_payroll_code, p_content_md, p_is_default,
        FALSE, TRUE,
        (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
    )
    ON CONFLICT ("CompanyId", "TemplateCode") DO UPDATE
    SET "TemplateName" = EXCLUDED."TemplateName",
        "TemplateType" = EXCLUDED."TemplateType",
        "CountryCode"  = EXCLUDED."CountryCode",
        "PayrollCode"  = EXCLUDED."PayrollCode",
        "ContentMD"    = EXCLUDED."ContentMD",
        "IsDefault"    = EXCLUDED."IsDefault",
        "IsSystem"     = FALSE,
        "UpdatedAt"    = (NOW() AT TIME ZONE 'UTC');

    p_resultado := 1;
    p_mensaje   := 'Plantilla guardada correctamente.';
END;
$function$
;

-- usp_hr_employee_count
CREATE OR REPLACE FUNCTION public.usp_hr_employee_count(p_company_id integer, p_search character varying DEFAULT NULL::character varying, p_status character varying DEFAULT NULL::character varying)
 RETURNS TABLE(total bigint)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT COUNT(1)
    FROM master."Employee"
    WHERE "CompanyId" = p_company_id
      AND COALESCE("IsDeleted", FALSE) = FALSE
      AND (p_search IS NULL OR ("EmployeeCode" ILIKE '%' || p_search || '%' OR "EmployeeName" ILIKE '%' || p_search || '%' OR "FiscalId" ILIKE '%' || p_search || '%'))
      AND (p_status IS NULL
           OR (p_status = 'ACTIVO' AND "IsActive" = TRUE)
           OR (p_status = 'INACTIVO' AND "IsActive" = FALSE));
END;
$function$
;

-- usp_hr_employee_delete
CREATE OR REPLACE FUNCTION public.usp_hr_employee_delete(p_company_id integer, p_cedula character varying)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
    UPDATE master."Employee"
    SET "IsDeleted" = TRUE, "IsActive" = FALSE,
        "DeletedAt" = NOW() AT TIME ZONE 'UTC', "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
    WHERE "CompanyId" = p_company_id AND "EmployeeCode" = p_cedula AND COALESCE("IsDeleted", FALSE) = FALSE;
END;
$function$
;

-- usp_hr_employee_existsbycode
CREATE OR REPLACE FUNCTION public.usp_hr_employee_existsbycode(p_company_id integer, p_code character varying)
 RETURNS TABLE("EmployeeId" bigint)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT e."EmployeeId"
    FROM master."Employee" e
    WHERE e."CompanyId" = p_company_id AND e."EmployeeCode" = p_code AND COALESCE(e."IsDeleted", FALSE) = FALSE
    LIMIT 1;
END;
$function$
;

-- usp_hr_employee_getbycode
CREATE OR REPLACE FUNCTION public.usp_hr_employee_getbycode(p_company_id integer, p_cedula character varying)
 RETURNS TABLE("EmployeeCode" character varying, "EmployeeName" character varying, "FiscalId" character varying, "HireDate" date, "TerminationDate" date, "IsActive" boolean)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT e."EmployeeCode", e."EmployeeName", e."FiscalId", e."HireDate", e."TerminationDate", e."IsActive"
    FROM master."Employee" e
    WHERE e."CompanyId" = p_company_id AND e."EmployeeCode" = p_cedula AND COALESCE(e."IsDeleted", FALSE) = FALSE
    LIMIT 1;
END;
$function$
;

-- usp_hr_employee_getdefaultcompany
CREATE OR REPLACE FUNCTION public.usp_hr_employee_getdefaultcompany()
 RETURNS TABLE("CompanyId" integer)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT c."CompanyId"
    FROM cfg."Company" c
    WHERE c."IsDeleted" = FALSE
    ORDER BY CASE WHEN c."CompanyCode" = 'DEFAULT' THEN 0 ELSE 1 END, c."CompanyId"
    LIMIT 1;
END;
$function$
;

-- usp_hr_employee_insert
CREATE OR REPLACE FUNCTION public.usp_hr_employee_insert(p_company_id integer, p_code character varying, p_name character varying, p_fiscal_id character varying DEFAULT NULL::character varying, p_hire_date date DEFAULT NULL::date, p_termination_date date DEFAULT NULL::date, p_is_active boolean DEFAULT true)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
    INSERT INTO master."Employee"
        ("CompanyId", "EmployeeCode", "EmployeeName", "FiscalId", "HireDate", "TerminationDate", "IsActive", "CreatedAt", "UpdatedAt", "IsDeleted")
    VALUES
        (p_company_id, p_code, p_name, p_fiscal_id, COALESCE(p_hire_date, (NOW() AT TIME ZONE 'UTC')::DATE), p_termination_date, p_is_active, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC', FALSE);
END;
$function$
;

-- usp_hr_employee_list
CREATE OR REPLACE FUNCTION public.usp_hr_employee_list(p_company_id integer, p_search character varying DEFAULT NULL::character varying, p_status character varying DEFAULT NULL::character varying, p_offset integer DEFAULT 0, p_limit integer DEFAULT 50)
 RETURNS TABLE("EmployeeCode" character varying, "EmployeeName" character varying, "FiscalId" character varying, "HireDate" date, "TerminationDate" date, "IsActive" boolean)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT e."EmployeeCode", e."EmployeeName", e."FiscalId",
           e."HireDate", e."TerminationDate", e."IsActive"
    FROM master."Employee" e
    WHERE e."CompanyId" = p_company_id
      AND COALESCE(e."IsDeleted", FALSE) = FALSE
      AND (p_search IS NULL OR (e."EmployeeCode" ILIKE '%' || p_search || '%' OR e."EmployeeName" ILIKE '%' || p_search || '%' OR e."FiscalId" ILIKE '%' || p_search || '%'))
      AND (p_status IS NULL
           OR (p_status = 'ACTIVO' AND e."IsActive" = TRUE)
           OR (p_status = 'INACTIVO' AND e."IsActive" = FALSE))
    ORDER BY e."EmployeeCode"
    LIMIT p_limit OFFSET p_offset;
END;
$function$
;

-- usp_hr_employee_update
CREATE OR REPLACE FUNCTION public.usp_hr_employee_update(p_company_id integer, p_cedula character varying, p_name character varying DEFAULT NULL::character varying, p_fiscal_id character varying DEFAULT NULL::character varying, p_hire_date date DEFAULT NULL::date, p_termination_date date DEFAULT NULL::date, p_is_active boolean DEFAULT NULL::boolean)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
    UPDATE master."Employee"
    SET "EmployeeName"   = COALESCE(p_name, "EmployeeName"),
        "FiscalId"       = COALESCE(p_fiscal_id, "FiscalId"),
        "HireDate"       = COALESCE(p_hire_date, "HireDate"),
        "TerminationDate"= COALESCE(p_termination_date, "TerminationDate"),
        "IsActive"       = COALESCE(p_is_active, "IsActive"),
        "UpdatedAt"      = NOW() AT TIME ZONE 'UTC'
    WHERE "CompanyId"    = p_company_id
      AND "EmployeeCode" = p_cedula
      AND COALESCE("IsDeleted", FALSE) = FALSE;
END;
$function$
;

-- usp_hr_employeeobligation_disenroll
CREATE OR REPLACE FUNCTION public.usp_hr_employeeobligation_disenroll(p_employee_obligation_id integer, p_disenrollment_date date, OUT p_resultado integer, OUT p_mensaje character varying)
 RETURNS record
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_current_status    VARCHAR(15);
    v_enroll_date       DATE;
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    SELECT "Status", "EnrollmentDate"
    INTO v_current_status, v_enroll_date
    FROM hr."EmployeeObligation"
    WHERE "EmployeeObligationId" = p_employee_obligation_id;

    IF v_current_status IS NULL THEN
        p_resultado := -1;
        p_mensaje   := 'No se encontró la inscripción indicada.';
        RETURN;
    END IF;

    IF v_current_status <> 'ACTIVE' THEN
        p_resultado := -2;
        p_mensaje   := 'La inscripción no está activa. Estado actual: ' || v_current_status;
        RETURN;
    END IF;

    IF p_disenrollment_date < v_enroll_date THEN
        p_resultado := -3;
        p_mensaje   := 'La fecha de retiro no puede ser anterior a la fecha de inscripción.';
        RETURN;
    END IF;

    BEGIN
        UPDATE hr."EmployeeObligation" SET
            "DisenrollmentDate" = p_disenrollment_date,
            "Status"            = 'TERMINATED',
            "UpdatedAt"         = (NOW() AT TIME ZONE 'UTC')
        WHERE "EmployeeObligationId" = p_employee_obligation_id;

        p_resultado := p_employee_obligation_id;
        p_mensaje   := 'Empleado desinscrito exitosamente.';

    EXCEPTION WHEN OTHERS THEN
        p_resultado := -99;
        p_mensaje   := SQLERRM;
    END;
END;
$function$
;

-- usp_hr_employeeobligation_enroll
CREATE OR REPLACE FUNCTION public.usp_hr_employeeobligation_enroll(p_employee_id bigint, p_legal_obligation_id integer, p_affiliation_number character varying DEFAULT NULL::character varying, p_institution_code character varying DEFAULT NULL::character varying, p_risk_level_id integer DEFAULT NULL::integer, p_enrollment_date date DEFAULT NULL::date, p_custom_rate numeric DEFAULT NULL::numeric, OUT p_resultado integer, OUT p_mensaje character varying)
 RETURNS record
 LANGUAGE plpgsql
AS $function$
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    IF NOT EXISTS (
        SELECT 1 FROM hr."LegalObligation"
        WHERE "LegalObligationId" = p_legal_obligation_id AND "IsActive" = TRUE
    ) THEN
        p_resultado := -1;
        p_mensaje   := 'La obligación legal no existe o no está activa.';
        RETURN;
    END IF;

    IF EXISTS (
        SELECT 1 FROM hr."EmployeeObligation"
        WHERE "EmployeeId"          = p_employee_id
          AND "LegalObligationId"   = p_legal_obligation_id
          AND "Status"              = 'ACTIVE'
    ) THEN
        p_resultado := -2;
        p_mensaje   := 'El empleado ya tiene una inscripción activa en esta obligación.';
        RETURN;
    END IF;

    IF p_risk_level_id IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM hr."ObligationRiskLevel"
        WHERE "ObligationRiskLevelId" = p_risk_level_id
          AND "LegalObligationId"     = p_legal_obligation_id
    ) THEN
        p_resultado := -3;
        p_mensaje   := 'El nivel de riesgo indicado no corresponde a esta obligación.';
        RETURN;
    END IF;

    BEGIN
        INSERT INTO hr."EmployeeObligation" (
            "EmployeeId", "LegalObligationId", "AffiliationNumber", "InstitutionCode",
            "RiskLevelId", "EnrollmentDate", "Status", "CustomRate", "CreatedAt", "UpdatedAt"
        )
        VALUES (
            p_employee_id, p_legal_obligation_id, p_affiliation_number, p_institution_code,
            p_risk_level_id, p_enrollment_date, 'ACTIVE', p_custom_rate,
            (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
        )
        RETURNING "EmployeeObligationId" INTO p_resultado;

        p_mensaje := 'Empleado inscrito exitosamente en la obligación.';

    EXCEPTION WHEN OTHERS THEN
        p_resultado := -99;
        p_mensaje   := SQLERRM;
    END;
END;
$function$
;

-- usp_hr_employeeobligation_getbyemployee
CREATE OR REPLACE FUNCTION public.usp_hr_employeeobligation_getbyemployee(p_employee_id bigint, p_status_filter character varying DEFAULT NULL::character varying)
 RETURNS TABLE(p_total_count bigint, "EmployeeObligationId" integer, "EmployeeId" bigint, "LegalObligationId" integer, "CountryCode" character, "Code" character varying, "ObligationName" character varying, "InstitutionName" character varying, "ObligationType" character varying, "CalculationBasis" character varying, "AffiliationNumber" character varying, "InstitutionCode" character varying, "RiskLevelId" integer, "RiskLevel" smallint, "RiskDescription" character varying, "EnrollmentDate" date, "DisenrollmentDate" date, "Status" character varying, "CustomRate" numeric, "EffectiveEmployerRate" numeric, "EffectiveEmployeeRate" numeric)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        COUNT(*) OVER()                                                         AS p_total_count,
        eo."EmployeeObligationId",
        eo."EmployeeId",
        eo."LegalObligationId",
        lo."CountryCode",
        lo."Code",
        lo."Name"                               AS "ObligationName",
        lo."InstitutionName",
        lo."ObligationType",
        lo."CalculationBasis",
        eo."AffiliationNumber",
        eo."InstitutionCode",
        eo."RiskLevelId",
        rl."RiskLevel",
        rl."RiskDescription",
        eo."EnrollmentDate",
        eo."DisenrollmentDate",
        eo."Status",
        eo."CustomRate",
        COALESCE(eo."CustomRate", rl."EmployerRate", lo."EmployerRate")         AS "EffectiveEmployerRate",
        COALESCE(
            CASE WHEN eo."CustomRate" IS NOT NULL THEN lo."EmployeeRate" ELSE NULL END,
            rl."EmployeeRate",
            lo."EmployeeRate"
        )                                                                       AS "EffectiveEmployeeRate"
    FROM hr."EmployeeObligation" eo
    INNER JOIN hr."LegalObligation" lo ON lo."LegalObligationId" = eo."LegalObligationId"
    LEFT JOIN  hr."ObligationRiskLevel" rl ON rl."ObligationRiskLevelId" = eo."RiskLevelId"
    WHERE eo."EmployeeId" = p_employee_id
      AND (p_status_filter IS NULL OR eo."Status" = p_status_filter)
    ORDER BY lo."CountryCode", lo."Code";
END;
$function$
;

-- usp_hr_filing_generate
CREATE OR REPLACE FUNCTION public.usp_hr_filing_generate(p_company_id integer, p_legal_obligation_id integer, p_filing_period_start date, p_filing_period_end date, p_due_date date, OUT p_resultado integer, OUT p_mensaje character varying)
 RETURNS record
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_base_employer_rate    NUMERIC(8,5);
    v_base_employee_rate    NUMERIC(8,5);
    v_cap                   NUMERIC(18,2);
    v_filing_id             INTEGER;
    v_tot_employer          NUMERIC(18,2);
    v_tot_employee          NUMERIC(18,2);
    v_emp_count             INTEGER;
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    IF NOT EXISTS (
        SELECT 1 FROM hr."LegalObligation"
        WHERE "LegalObligationId" = p_legal_obligation_id AND "IsActive" = TRUE
    ) THEN
        p_resultado := -1;
        p_mensaje   := 'La obligación legal no existe o no está activa.';
        RETURN;
    END IF;

    IF EXISTS (
        SELECT 1 FROM hr."ObligationFiling"
        WHERE "CompanyId"           = p_company_id
          AND "LegalObligationId"   = p_legal_obligation_id
          AND "FilingPeriodStart"   = p_filing_period_start
          AND "FilingPeriodEnd"     = p_filing_period_end
          AND "Status"             <> 'REJECTED'
    ) THEN
        p_resultado := -2;
        p_mensaje   := 'Ya existe una declaración para este período y obligación.';
        RETURN;
    END IF;

    IF p_filing_period_end < p_filing_period_start THEN
        p_resultado := -3;
        p_mensaje   := 'La fecha fin del período no puede ser anterior a la fecha inicio.';
        RETURN;
    END IF;

    BEGIN
        SELECT "EmployerRate", "EmployeeRate", "SalaryCap"
        INTO v_base_employer_rate, v_base_employee_rate, v_cap
        FROM hr."LegalObligation"
        WHERE "LegalObligationId" = p_legal_obligation_id;

        INSERT INTO hr."ObligationFiling" (
            "CompanyId", "LegalObligationId",
            "FilingPeriodStart", "FilingPeriodEnd",
            "DueDate", "Status", "CreatedAt", "UpdatedAt"
        )
        VALUES (
            p_company_id, p_legal_obligation_id,
            p_filing_period_start, p_filing_period_end,
            p_due_date, 'PENDING',
            (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
        )
        RETURNING "ObligationFilingId" INTO v_filing_id;

        INSERT INTO hr."ObligationFilingDetail" (
            "ObligationFilingId", "EmployeeId", "BaseSalary",
            "EmployerAmount", "EmployeeAmount", "DaysWorked", "NoveltyType"
        )
        SELECT
            v_filing_id,
            eo."EmployeeId",
            COALESCE((
                SELECT prl."Amount"
                FROM hr."PayrollRun" pr
                INNER JOIN hr."PayrollRunLine" prl ON prl."PayrollRunId" = pr."PayrollRunId"
                WHERE pr."EmployeeId" = e."EmployeeId" AND prl."ConceptCode" = 'SALARIO_BASE'
                ORDER BY pr."CreatedAt" DESC
                LIMIT 1
            ), 0) AS "BaseSalary",
            ROUND(
                CASE
                    WHEN v_cap IS NOT NULL
                     AND COALESCE((
                            SELECT prl."Amount"
                            FROM hr."PayrollRun" pr
                            INNER JOIN hr."PayrollRunLine" prl ON prl."PayrollRunId" = pr."PayrollRunId"
                            WHERE pr."EmployeeId" = e."EmployeeId" AND prl."ConceptCode" = 'SALARIO_BASE'
                            ORDER BY pr."CreatedAt" DESC LIMIT 1
                         ), 0) > v_cap
                    THEN v_cap
                    ELSE COALESCE((
                            SELECT prl."Amount"
                            FROM hr."PayrollRun" pr
                            INNER JOIN hr."PayrollRunLine" prl ON prl."PayrollRunId" = pr."PayrollRunId"
                            WHERE pr."EmployeeId" = e."EmployeeId" AND prl."ConceptCode" = 'SALARIO_BASE'
                            ORDER BY pr."CreatedAt" DESC LIMIT 1
                         ), 0)
                END
                * COALESCE(eo."CustomRate", rl."EmployerRate", v_base_employer_rate) / 100.0,
            2) AS "EmployerAmount",
            ROUND(
                CASE
                    WHEN v_cap IS NOT NULL
                     AND COALESCE((
                            SELECT prl."Amount"
                            FROM hr."PayrollRun" pr
                            INNER JOIN hr."PayrollRunLine" prl ON prl."PayrollRunId" = pr."PayrollRunId"
                            WHERE pr."EmployeeId" = e."EmployeeId" AND prl."ConceptCode" = 'SALARIO_BASE'
                            ORDER BY pr."CreatedAt" DESC LIMIT 1
                         ), 0) > v_cap
                    THEN v_cap
                    ELSE COALESCE((
                            SELECT prl."Amount"
                            FROM hr."PayrollRun" pr
                            INNER JOIN hr."PayrollRunLine" prl ON prl."PayrollRunId" = pr."PayrollRunId"
                            WHERE pr."EmployeeId" = e."EmployeeId" AND prl."ConceptCode" = 'SALARIO_BASE'
                            ORDER BY pr."CreatedAt" DESC LIMIT 1
                         ), 0)
                END
                * COALESCE(rl."EmployeeRate", v_base_employee_rate) / 100.0,
            2) AS "EmployeeAmount",
            30 AS "DaysWorked",
            CASE
                WHEN eo."EnrollmentDate"     BETWEEN p_filing_period_start AND p_filing_period_end THEN 'ENROLLMENT'
                WHEN eo."DisenrollmentDate"  BETWEEN p_filing_period_start AND p_filing_period_end THEN 'WITHDRAWAL'
                ELSE 'NONE'
            END AS "NoveltyType"
        FROM hr."EmployeeObligation" eo
        INNER JOIN master."Employee" e ON e."EmployeeId" = eo."EmployeeId"
        LEFT JOIN  hr."ObligationRiskLevel" rl ON rl."ObligationRiskLevelId" = eo."RiskLevelId"
        WHERE eo."LegalObligationId" = p_legal_obligation_id
          AND eo."Status" IN ('ACTIVE','SUSPENDED')
          AND eo."EnrollmentDate" <= p_filing_period_end
          AND (eo."DisenrollmentDate" IS NULL OR eo."DisenrollmentDate" >= p_filing_period_start);

        SELECT
            COALESCE(SUM("EmployerAmount"), 0),
            COALESCE(SUM("EmployeeAmount"), 0),
            COUNT(*)
        INTO v_tot_employer, v_tot_employee, v_emp_count
        FROM hr."ObligationFilingDetail"
        WHERE "ObligationFilingId" = v_filing_id;

        UPDATE hr."ObligationFiling" SET
            "TotalEmployerAmount"   = v_tot_employer,
            "TotalEmployeeAmount"   = v_tot_employee,
            "TotalAmount"           = v_tot_employer + v_tot_employee,
            "EmployeeCount"         = v_emp_count,
            "UpdatedAt"             = (NOW() AT TIME ZONE 'UTC')
        WHERE "ObligationFilingId" = v_filing_id;

        p_resultado := v_filing_id;
        p_mensaje   := 'Declaración generada exitosamente con ' || v_emp_count::TEXT || ' empleado(s).';

    EXCEPTION WHEN OTHERS THEN
        p_resultado := -99;
        p_mensaje   := SQLERRM;
    END;
END;
$function$
;

-- usp_hr_filing_getsummary
CREATE OR REPLACE FUNCTION public.usp_hr_filing_getsummary(p_obligation_filing_id integer)
 RETURNS TABLE(result_type character varying, row_data jsonb)
 LANGUAGE plpgsql
AS $function$
BEGIN
    -- Cabecera
    RETURN QUERY
    SELECT
        'HEADER'::TEXT,
        jsonb_build_object(
            'ObligationFilingId',   f."ObligationFilingId",
            'CompanyId',            f."CompanyId",
            'LegalObligationId',    f."LegalObligationId",
            'CountryCode',          lo."CountryCode",
            'ObligationCode',       lo."Code",
            'ObligationName',       lo."Name",
            'InstitutionName',      lo."InstitutionName",
            'ObligationType',       lo."ObligationType",
            'CalculationBasis',     lo."CalculationBasis",
            'BaseEmployerRate',     lo."EmployerRate",
            'BaseEmployeeRate',     lo."EmployeeRate",
            'FilingPeriodStart',    f."FilingPeriodStart",
            'FilingPeriodEnd',      f."FilingPeriodEnd",
            'DueDate',              f."DueDate",
            'FiledDate',            f."FiledDate",
            'ConfirmationNumber',   f."ConfirmationNumber",
            'TotalEmployerAmount',  f."TotalEmployerAmount",
            'TotalEmployeeAmount',  f."TotalEmployeeAmount",
            'TotalAmount',          f."TotalAmount",
            'EmployeeCount',        f."EmployeeCount",
            'Status',               f."Status",
            'FiledByUserId',        f."FiledByUserId",
            'DocumentUrl',          f."DocumentUrl",
            'Notes',                f."Notes",
            'CreatedAt',            f."CreatedAt",
            'UpdatedAt',            f."UpdatedAt"
        )
    FROM hr."ObligationFiling" f
    INNER JOIN hr."LegalObligation" lo ON lo."LegalObligationId" = f."LegalObligationId"
    WHERE f."ObligationFilingId" = p_obligation_filing_id;

    -- Detalle
    RETURN QUERY
    SELECT
        'DETAIL'::TEXT,
        jsonb_build_object(
            'DetailId',             d."DetailId",
            'ObligationFilingId',   d."ObligationFilingId",
            'EmployeeId',           d."EmployeeId",
            'EmployeeCode',         e."EmployeeCode",
            'EmployeeName',         e."EmployeeName",
            'BaseSalary',           d."BaseSalary",
            'EmployerAmount',       d."EmployerAmount",
            'EmployeeAmount',       d."EmployeeAmount",
            'TotalAmount',          d."EmployerAmount" + d."EmployeeAmount",
            'DaysWorked',           d."DaysWorked",
            'NoveltyType',          d."NoveltyType"
        )
    FROM hr."ObligationFilingDetail" d
    INNER JOIN master."Employee" e ON e."EmployeeId" = d."EmployeeId"
    WHERE d."ObligationFilingId" = p_obligation_filing_id
    ORDER BY e."EmployeeName";
END;
$function$
;

-- usp_hr_filing_list
CREATE OR REPLACE FUNCTION public.usp_hr_filing_list(p_company_id integer DEFAULT NULL::integer, p_legal_obligation_id integer DEFAULT NULL::integer, p_country_code character DEFAULT NULL::bpchar, p_status character varying DEFAULT NULL::character varying, p_from_date date DEFAULT NULL::date, p_to_date date DEFAULT NULL::date, p_page integer DEFAULT 1, p_limit integer DEFAULT 50)
 RETURNS TABLE(p_total_count bigint, "ObligationFilingId" integer, "CompanyId" integer, "LegalObligationId" integer, "CountryCode" character, "ObligationCode" character varying, "ObligationName" character varying, "InstitutionName" character varying, "FilingPeriodStart" date, "FilingPeriodEnd" date, "DueDate" date, "FiledDate" date, "ConfirmationNumber" character varying, "TotalEmployerAmount" numeric, "TotalEmployeeAmount" numeric, "TotalAmount" numeric, "EmployeeCount" integer, "Status" character varying, "CreatedAt" timestamp without time zone)
 LANGUAGE plpgsql
AS $function$
BEGIN
    IF p_page  < 1   THEN p_page  := 1;   END IF;
    IF p_limit < 1   THEN p_limit := 50;  END IF;
    IF p_limit > 500 THEN p_limit := 500; END IF;

    RETURN QUERY
    SELECT
        COUNT(*) OVER()         AS p_total_count,
        f."ObligationFilingId",
        f."CompanyId",
        f."LegalObligationId",
        lo."CountryCode",
        lo."Code"               AS "ObligationCode",
        lo."Name"               AS "ObligationName",
        lo."InstitutionName",
        f."FilingPeriodStart",
        f."FilingPeriodEnd",
        f."DueDate",
        f."FiledDate",
        f."ConfirmationNumber",
        f."TotalEmployerAmount",
        f."TotalEmployeeAmount",
        f."TotalAmount",
        f."EmployeeCount",
        f."Status",
        f."CreatedAt"
    FROM hr."ObligationFiling" f
    INNER JOIN hr."LegalObligation" lo ON lo."LegalObligationId" = f."LegalObligationId"
    WHERE (p_company_id          IS NULL OR f."CompanyId"          = p_company_id)
      AND (p_legal_obligation_id IS NULL OR f."LegalObligationId"  = p_legal_obligation_id)
      AND (p_country_code        IS NULL OR lo."CountryCode"       = p_country_code)
      AND (p_status              IS NULL OR f."Status"             = p_status)
      AND (p_from_date           IS NULL OR f."FilingPeriodStart" >= p_from_date)
      AND (p_to_date             IS NULL OR f."FilingPeriodEnd"   <= p_to_date)
    ORDER BY f."FilingPeriodStart" DESC, lo."Code"
    LIMIT p_limit OFFSET (p_page - 1) * p_limit;
END;
$function$
;

-- usp_hr_filing_markfiled
CREATE OR REPLACE FUNCTION public.usp_hr_filing_markfiled(p_obligation_filing_id integer, p_filed_date date DEFAULT NULL::date, p_confirmation_number character varying DEFAULT NULL::character varying, p_filed_by_user_id integer DEFAULT NULL::integer, p_document_url character varying DEFAULT NULL::character varying, p_notes character varying DEFAULT NULL::character varying, OUT p_resultado integer, OUT p_mensaje character varying)
 RETURNS record
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_current_status VARCHAR(15);
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    SELECT "Status"
    INTO v_current_status
    FROM hr."ObligationFiling"
    WHERE "ObligationFilingId" = p_obligation_filing_id;

    IF v_current_status IS NULL THEN
        p_resultado := -1;
        p_mensaje   := 'No se encontró la declaración indicada.';
        RETURN;
    END IF;

    IF v_current_status NOT IN ('PENDING','LATE','REJECTED') THEN
        p_resultado := -2;
        p_mensaje   := 'Solo se pueden marcar como presentadas las declaraciones en estado PENDING, LATE o REJECTED. Estado actual: ' || v_current_status;
        RETURN;
    END IF;

    IF p_filed_date IS NULL THEN
        p_filed_date := CAST((NOW() AT TIME ZONE 'UTC') AS DATE);
    END IF;

    BEGIN
        UPDATE hr."ObligationFiling" SET
            "Status"                = 'FILED',
            "FiledDate"             = p_filed_date,
            "ConfirmationNumber"    = p_confirmation_number,
            "FiledByUserId"         = p_filed_by_user_id,
            "DocumentUrl"           = p_document_url,
            "Notes"                 = COALESCE(p_notes, "Notes"),
            "UpdatedAt"             = (NOW() AT TIME ZONE 'UTC')
        WHERE "ObligationFilingId" = p_obligation_filing_id;

        p_resultado := p_obligation_filing_id;
        p_mensaje   := 'Declaración marcada como presentada exitosamente.';

    EXCEPTION WHEN OTHERS THEN
        p_resultado := -99;
        p_mensaje   := SQLERRM;
    END;
END;
$function$
;

-- usp_hr_legalconcept_list
CREATE OR REPLACE FUNCTION public.usp_hr_legalconcept_list(p_company_id integer, p_convention_code character varying DEFAULT NULL::character varying, p_calculation_type character varying DEFAULT NULL::character varying, p_concept_type character varying DEFAULT NULL::character varying, p_solo_activos boolean DEFAULT true)
 RETURNS TABLE(id bigint, convencion character varying, "tipoCalculo" character varying, "coConcept" character varying, "nbConcepto" character varying, formula character varying, sobre character varying, tipo character varying, bonificable character varying, "lotttArticulo" character varying, "ccpClausula" character varying, orden integer, activo boolean)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        pc."PayrollConceptId", pc."ConventionCode", pc."CalculationType",
        pc."ConceptCode", pc."ConceptName", pc."Formula",
        pc."BaseExpression", pc."ConceptType",
        CASE WHEN pc."IsBonifiable" THEN 'S' ELSE 'N' END,
        pc."LotttArticle", pc."CcpClause",
        pc."SortOrder", pc."IsActive"
    FROM hr."PayrollConcept" pc
    WHERE pc."CompanyId" = p_company_id
      AND pc."ConventionCode" IS NOT NULL
      AND (NOT p_solo_activos OR pc."IsActive" = TRUE)
      AND (p_convention_code IS NULL OR pc."ConventionCode" = p_convention_code)
      AND (p_calculation_type IS NULL OR pc."CalculationType" = p_calculation_type)
      AND (p_concept_type IS NULL OR pc."ConceptType" = p_concept_type)
    ORDER BY pc."ConventionCode", pc."CalculationType", pc."SortOrder", pc."ConceptCode";
END;
$function$
;

-- usp_hr_legalconcept_listconventions
CREATE OR REPLACE FUNCTION public.usp_hr_legalconcept_listconventions(p_company_id integer)
 RETURNS TABLE("Convencion" character varying, "TotalConceptos" bigint, "ConceptosMensual" bigint, "ConceptosVacaciones" bigint, "ConceptosLiquidacion" bigint, "OrdenInicio" integer, "OrdenFin" integer)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        pc."ConventionCode",
        COUNT(1),
        COUNT(CASE WHEN pc."CalculationType" = 'MENSUAL' THEN 1 END),
        COUNT(CASE WHEN pc."CalculationType" = 'VACACIONES' THEN 1 END),
        COUNT(CASE WHEN pc."CalculationType" = 'LIQUIDACION' THEN 1 END),
        MIN(pc."SortOrder"),
        MAX(pc."SortOrder")
    FROM hr."PayrollConcept" pc
    WHERE pc."CompanyId" = p_company_id
      AND pc."IsActive" = TRUE
      AND pc."ConventionCode" IS NOT NULL
    GROUP BY pc."ConventionCode"
    ORDER BY pc."ConventionCode";
END;
$function$
;

-- usp_hr_legalconcept_validateformulas
CREATE OR REPLACE FUNCTION public.usp_hr_legalconcept_validateformulas(p_company_id integer, p_convention_code character varying DEFAULT NULL::character varying, p_calculation_type character varying DEFAULT NULL::character varying)
 RETURNS TABLE("coConcept" character varying, "nbConcepto" character varying, formula character varying, "defaultValue" numeric)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        pc."ConceptCode", pc."ConceptName", pc."Formula", pc."DefaultValue"
    FROM hr."PayrollConcept" pc
    WHERE pc."CompanyId" = p_company_id
      AND pc."ConventionCode" IS NOT NULL
      AND pc."IsActive" = TRUE
      AND (p_convention_code IS NULL OR pc."ConventionCode" = p_convention_code)
      AND (p_calculation_type IS NULL OR pc."CalculationType" = p_calculation_type)
    ORDER BY pc."SortOrder", pc."ConceptCode";
END;
$function$
;

-- usp_hr_medexam_getpending
CREATE OR REPLACE FUNCTION public.usp_hr_medexam_getpending(p_company_id integer, p_as_of_date date DEFAULT NULL::date, p_days_ahead integer DEFAULT 30, p_page integer DEFAULT 1, p_limit integer DEFAULT 50)
 RETURNS TABLE(p_total_count bigint, "MedicalExamId" integer, "CompanyId" integer, "EmployeeId" bigint, "EmployeeCode" character varying, "EmployeeName" character varying, "ExamType" character varying, "ExamDate" date, "NextDueDate" date, "Result" character varying, "Restrictions" character varying, "PhysicianName" character varying, "ClinicName" character varying, "IsOverdue" boolean, "DaysUntilDue" integer)
 LANGUAGE plpgsql
AS $function$
BEGIN
    IF p_as_of_date IS NULL THEN p_as_of_date := CAST((NOW() AT TIME ZONE 'UTC') AS DATE); END IF;
    IF p_page  < 1   THEN p_page  := 1;   END IF;
    IF p_limit < 1   THEN p_limit := 50;  END IF;
    IF p_limit > 500 THEN p_limit := 500; END IF;

    RETURN QUERY
    WITH "LatestExam" AS (
        SELECT *,
               ROW_NUMBER() OVER (PARTITION BY "EmployeeCode" ORDER BY "ExamDate" DESC) AS rn
        FROM hr."MedicalExam"
        WHERE "CompanyId"  = p_company_id
          AND "ExamType"   = 'PERIODIC'
          AND "NextDueDate" IS NOT NULL
          AND "NextDueDate" <= p_as_of_date + p_days_ahead
    )
    SELECT
        COUNT(*) OVER()                                     AS p_total_count,
        "MedicalExamId",
        "CompanyId",
        "EmployeeId",
        "EmployeeCode",
        "EmployeeName",
        "ExamType",
        "ExamDate",
        "NextDueDate",
        "Result",
        "Restrictions",
        "PhysicianName",
        "ClinicName",
        ("NextDueDate" < p_as_of_date)                     AS "IsOverdue",
        ("NextDueDate" - p_as_of_date)::INTEGER            AS "DaysUntilDue"
    FROM "LatestExam"
    WHERE rn = 1
    ORDER BY "NextDueDate" ASC
    LIMIT p_limit OFFSET (p_page - 1) * p_limit;
END;
$function$
;

-- usp_hr_medexam_list
CREATE OR REPLACE FUNCTION public.usp_hr_medexam_list(p_company_id integer, p_exam_type character varying DEFAULT NULL::character varying, p_result character varying DEFAULT NULL::character varying, p_employee_code character varying DEFAULT NULL::character varying, p_from_date date DEFAULT NULL::date, p_to_date date DEFAULT NULL::date, p_page integer DEFAULT 1, p_limit integer DEFAULT 50)
 RETURNS TABLE(p_total_count bigint, "MedicalExamId" integer, "CompanyId" integer, "EmployeeId" bigint, "EmployeeCode" character varying, "EmployeeName" character varying, "ExamType" character varying, "ExamDate" date, "NextDueDate" date, "Result" character varying, "Restrictions" character varying, "PhysicianName" character varying, "ClinicName" character varying, "DocumentUrl" character varying, "Notes" character varying, "CreatedAt" timestamp without time zone, "UpdatedAt" timestamp without time zone)
 LANGUAGE plpgsql
AS $function$
BEGIN
    IF p_page  < 1   THEN p_page  := 1;   END IF;
    IF p_limit < 1   THEN p_limit := 50;  END IF;
    IF p_limit > 500 THEN p_limit := 500; END IF;

    RETURN QUERY
    SELECT
        COUNT(*) OVER()         AS p_total_count,
        "MedicalExamId",
        "CompanyId",
        "EmployeeId",
        "EmployeeCode",
        "EmployeeName",
        "ExamType",
        "ExamDate",
        "NextDueDate",
        "Result",
        "Restrictions",
        "PhysicianName",
        "ClinicName",
        "DocumentUrl",
        "Notes",
        "CreatedAt",
        "UpdatedAt"
    FROM hr."MedicalExam"
    WHERE "CompanyId" = p_company_id
      AND (p_exam_type     IS NULL OR "ExamType"     = p_exam_type)
      AND (p_result        IS NULL OR "Result"        = p_result)
      AND (p_employee_code IS NULL OR "EmployeeCode"  = p_employee_code)
      AND (p_from_date     IS NULL OR "ExamDate"     >= p_from_date)
      AND (p_to_date       IS NULL OR "ExamDate"     <= p_to_date)
    ORDER BY "ExamDate" DESC, "MedicalExamId" DESC
    LIMIT p_limit OFFSET (p_page - 1) * p_limit;
END;
$function$
;

-- usp_hr_medexam_save
CREATE OR REPLACE FUNCTION public.usp_hr_medexam_save(p_medical_exam_id integer DEFAULT NULL::integer, p_company_id integer DEFAULT NULL::integer, p_employee_id bigint DEFAULT NULL::bigint, p_employee_code character varying DEFAULT NULL::character varying, p_employee_name character varying DEFAULT NULL::character varying, p_exam_type character varying DEFAULT NULL::character varying, p_exam_date date DEFAULT NULL::date, p_next_due_date date DEFAULT NULL::date, p_result character varying DEFAULT 'PENDING'::character varying, p_restrictions character varying DEFAULT NULL::character varying, p_physician_name character varying DEFAULT NULL::character varying, p_clinic_name character varying DEFAULT NULL::character varying, p_document_url character varying DEFAULT NULL::character varying, p_notes character varying DEFAULT NULL::character varying, OUT p_resultado integer, OUT p_mensaje character varying)
 RETURNS record
 LANGUAGE plpgsql
AS $function$
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    IF p_exam_type NOT IN ('PRE_EMPLOYMENT','PERIODIC','POST_VACATION','EXIT','SPECIAL') THEN
        p_resultado := -1;
        p_mensaje   := 'Tipo de examen no válido.';
        RETURN;
    END IF;

    IF p_result NOT IN ('FIT','FIT_WITH_RESTRICTIONS','UNFIT','PENDING') THEN
        p_resultado := -1;
        p_mensaje   := 'Resultado de examen no válido.';
        RETURN;
    END IF;

    BEGIN
        IF p_medical_exam_id IS NULL THEN
            INSERT INTO hr."MedicalExam" (
                "CompanyId", "EmployeeId", "EmployeeCode", "EmployeeName",
                "ExamType", "ExamDate", "NextDueDate", "Result",
                "Restrictions", "PhysicianName", "ClinicName",
                "DocumentUrl", "Notes", "CreatedAt", "UpdatedAt"
            )
            VALUES (
                p_company_id, p_employee_id, p_employee_code, p_employee_name,
                p_exam_type, p_exam_date, p_next_due_date, p_result,
                p_restrictions, p_physician_name, p_clinic_name,
                p_document_url, p_notes,
                (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
            )
            RETURNING "MedicalExamId" INTO p_resultado;

            p_mensaje := 'Examen médico creado exitosamente.';
        ELSE
            IF NOT EXISTS (
                SELECT 1 FROM hr."MedicalExam"
                WHERE "MedicalExamId" = p_medical_exam_id AND "CompanyId" = p_company_id
            ) THEN
                p_resultado := -1;
                p_mensaje   := 'Examen médico no encontrado.';
                RETURN;
            END IF;

            UPDATE hr."MedicalExam"
            SET
                "EmployeeId"    = COALESCE(p_employee_id, "EmployeeId"),
                "EmployeeCode"  = p_employee_code,
                "EmployeeName"  = p_employee_name,
                "ExamType"      = p_exam_type,
                "ExamDate"      = p_exam_date,
                "NextDueDate"   = p_next_due_date,
                "Result"        = p_result,
                "Restrictions"  = p_restrictions,
                "PhysicianName" = p_physician_name,
                "ClinicName"    = p_clinic_name,
                "DocumentUrl"   = p_document_url,
                "Notes"         = p_notes,
                "UpdatedAt"     = (NOW() AT TIME ZONE 'UTC')
            WHERE "MedicalExamId" = p_medical_exam_id
              AND "CompanyId" = p_company_id;

            p_resultado := p_medical_exam_id;
            p_mensaje   := 'Examen médico actualizado exitosamente.';
        END IF;

    EXCEPTION WHEN OTHERS THEN
        p_resultado := -1;
        p_mensaje   := SQLERRM;
    END;
END;
$function$
;

-- usp_hr_medorder_approve
CREATE OR REPLACE FUNCTION public.usp_hr_medorder_approve(p_medical_order_id integer, p_company_id integer, p_action character varying, p_approved_amount numeric DEFAULT NULL::numeric, p_approved_by integer DEFAULT NULL::integer, p_notes character varying DEFAULT NULL::character varying, OUT p_resultado integer, OUT p_mensaje character varying)
 RETURNS record
 LANGUAGE plpgsql
AS $function$
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    IF p_action NOT IN ('APROBADA','RECHAZADA') THEN
        p_resultado := -1;
        p_mensaje   := 'Acción no válida. Use APROBADA o RECHAZADA.';
        RETURN;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM hr."MedicalOrder"
        WHERE "MedicalOrderId" = p_medical_order_id AND "CompanyId" = p_company_id
    ) THEN
        p_resultado := -1;
        p_mensaje   := 'Orden médica no encontrada.';
        RETURN;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM hr."MedicalOrder"
        WHERE "MedicalOrderId" = p_medical_order_id AND "CompanyId" = p_company_id
          AND "Status" = 'PENDIENTE'
    ) THEN
        p_resultado := -1;
        p_mensaje   := 'La orden no está en estado PENDIENTE.';
        RETURN;
    END IF;

    BEGIN
        UPDATE hr."MedicalOrder"
        SET
            "Status"         = p_action,
            "ApprovedAmount" = CASE WHEN p_action = 'APROBADA'
                                    THEN COALESCE(p_approved_amount, "EstimatedCost")
                                    ELSE NULL END,
            "ApprovedBy"     = p_approved_by,
            "ApprovedAt"     = (NOW() AT TIME ZONE 'UTC'),
            "Notes"          = COALESCE(p_notes, "Notes"),
            "UpdatedAt"      = (NOW() AT TIME ZONE 'UTC')
        WHERE "MedicalOrderId" = p_medical_order_id
          AND "CompanyId" = p_company_id;

        p_resultado := p_medical_order_id;
        p_mensaje   := CASE WHEN p_action = 'APROBADA'
                            THEN 'Orden médica aprobada exitosamente.'
                            ELSE 'Orden médica rechazada.' END;

    EXCEPTION WHEN OTHERS THEN
        p_resultado := -1;
        p_mensaje   := SQLERRM;
    END;
END;
$function$
;

-- usp_hr_medorder_create
CREATE OR REPLACE FUNCTION public.usp_hr_medorder_create(p_company_id integer, p_employee_id bigint DEFAULT NULL::bigint, p_employee_code character varying DEFAULT NULL::character varying, p_employee_name character varying DEFAULT NULL::character varying, p_order_type character varying DEFAULT NULL::character varying, p_order_date date DEFAULT NULL::date, p_diagnosis character varying DEFAULT NULL::character varying, p_physician_name character varying DEFAULT NULL::character varying, p_prescriptions text DEFAULT NULL::text, p_estimated_cost numeric DEFAULT NULL::numeric, p_document_url character varying DEFAULT NULL::character varying, p_notes character varying DEFAULT NULL::character varying, OUT p_resultado integer, OUT p_mensaje character varying)
 RETURNS record
 LANGUAGE plpgsql
AS $function$
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    IF p_order_type NOT IN ('MEDICAL','PHARMACY','LAB','REFERRAL') THEN
        p_resultado := -1;
        p_mensaje   := 'Tipo de orden no válido.';
        RETURN;
    END IF;

    BEGIN
        INSERT INTO hr."MedicalOrder" (
            "CompanyId", "EmployeeId", "EmployeeCode", "EmployeeName",
            "OrderType", "OrderDate", "Diagnosis", "PhysicianName",
            "Prescriptions", "EstimatedCost", "Status",
            "DocumentUrl", "Notes", "CreatedAt", "UpdatedAt"
        )
        VALUES (
            p_company_id, p_employee_id, p_employee_code, p_employee_name,
            p_order_type, p_order_date, p_diagnosis, p_physician_name,
            p_prescriptions, p_estimated_cost, 'PENDIENTE',
            p_document_url, p_notes,
            (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
        )
        RETURNING "MedicalOrderId" INTO p_resultado;

        p_mensaje := 'Orden médica creada exitosamente.';

    EXCEPTION WHEN OTHERS THEN
        p_resultado := -1;
        p_mensaje   := SQLERRM;
    END;
END;
$function$
;

-- usp_hr_medorder_list
CREATE OR REPLACE FUNCTION public.usp_hr_medorder_list(p_company_id integer, p_order_type character varying DEFAULT NULL::character varying, p_status character varying DEFAULT NULL::character varying, p_employee_code character varying DEFAULT NULL::character varying, p_from_date date DEFAULT NULL::date, p_to_date date DEFAULT NULL::date, p_page integer DEFAULT 1, p_limit integer DEFAULT 50)
 RETURNS TABLE(p_total_count bigint, "MedicalOrderId" integer, "CompanyId" integer, "EmployeeId" bigint, "EmployeeCode" character varying, "EmployeeName" character varying, "OrderType" character varying, "OrderDate" date, "Diagnosis" character varying, "PhysicianName" character varying, "Prescriptions" character varying, "EstimatedCost" numeric, "ApprovedAmount" numeric, "Status" character varying, "ApprovedBy" integer, "ApprovedAt" timestamp without time zone, "DocumentUrl" character varying, "Notes" character varying, "CreatedAt" timestamp without time zone, "UpdatedAt" timestamp without time zone)
 LANGUAGE plpgsql
AS $function$
BEGIN
    IF p_page  < 1   THEN p_page  := 1;   END IF;
    IF p_limit < 1   THEN p_limit := 50;  END IF;
    IF p_limit > 500 THEN p_limit := 500; END IF;

    RETURN QUERY
    SELECT
        COUNT(*) OVER()         AS p_total_count,
        "MedicalOrderId",
        "CompanyId",
        "EmployeeId",
        "EmployeeCode",
        "EmployeeName",
        "OrderType",
        "OrderDate",
        "Diagnosis",
        "PhysicianName",
        "Prescriptions",
        "EstimatedCost",
        "ApprovedAmount",
        "Status",
        "ApprovedBy",
        "ApprovedAt",
        "DocumentUrl",
        "Notes",
        "CreatedAt",
        "UpdatedAt"
    FROM hr."MedicalOrder"
    WHERE "CompanyId" = p_company_id
      AND (p_order_type    IS NULL OR "OrderType"    = p_order_type)
      AND (p_status        IS NULL OR "Status"        = p_status)
      AND (p_employee_code IS NULL OR "EmployeeCode"  = p_employee_code)
      AND (p_from_date     IS NULL OR "OrderDate"    >= p_from_date)
      AND (p_to_date       IS NULL OR "OrderDate"    <= p_to_date)
    ORDER BY "OrderDate" DESC, "MedicalOrderId" DESC
    LIMIT p_limit OFFSET (p_page - 1) * p_limit;
END;
$function$
;

-- usp_hr_obligation_getbycountry
CREATE OR REPLACE FUNCTION public.usp_hr_obligation_getbycountry(p_country_code character, p_as_of_date date DEFAULT NULL::date)
 RETURNS TABLE("LegalObligationId" integer, "CountryCode" character, "Code" character varying, "Name" character varying, "InstitutionName" character varying, "ObligationType" character varying, "CalculationBasis" character varying, "SalaryCap" numeric, "SalaryCapUnit" character varying, "EmployerRate" numeric, "EmployeeRate" numeric, "RateVariableByRisk" boolean, "FilingFrequency" character varying, "FilingDeadlineRule" character varying, "EffectiveFrom" date, "EffectiveTo" date, "Notes" character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
    IF p_as_of_date IS NULL THEN
        p_as_of_date := CAST((NOW() AT TIME ZONE 'UTC') AS DATE);
    END IF;

    RETURN QUERY
    SELECT
        o."LegalObligationId",
        o."CountryCode",
        o."Code",
        o."Name",
        o."InstitutionName",
        o."ObligationType",
        o."CalculationBasis",
        o."SalaryCap",
        o."SalaryCapUnit",
        o."EmployerRate",
        o."EmployeeRate",
        o."RateVariableByRisk",
        o."FilingFrequency",
        o."FilingDeadlineRule",
        o."EffectiveFrom",
        o."EffectiveTo",
        o."Notes"
    FROM hr."LegalObligation" o
    WHERE o."CountryCode" = p_country_code
      AND o."IsActive" = TRUE
      AND o."EffectiveFrom" <= p_as_of_date
      AND (o."EffectiveTo" IS NULL OR o."EffectiveTo" >= p_as_of_date)
    ORDER BY o."Code";
END;
$function$
;

-- usp_hr_obligation_list
CREATE OR REPLACE FUNCTION public.usp_hr_obligation_list(p_country_code character DEFAULT NULL::bpchar, p_obligation_type character varying DEFAULT NULL::character varying, p_is_active boolean DEFAULT NULL::boolean, p_search character varying DEFAULT NULL::character varying, p_page integer DEFAULT 1, p_limit integer DEFAULT 50)
 RETURNS TABLE(p_total_count bigint, "LegalObligationId" integer, "CountryCode" character, "Code" character varying, "Name" character varying, "InstitutionName" character varying, "ObligationType" character varying, "CalculationBasis" character varying, "SalaryCap" numeric, "SalaryCapUnit" character varying, "EmployerRate" numeric, "EmployeeRate" numeric, "RateVariableByRisk" boolean, "FilingFrequency" character varying, "FilingDeadlineRule" character varying, "EffectiveFrom" date, "EffectiveTo" date, "IsActive" boolean, "Notes" character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
    IF p_page  < 1   THEN p_page  := 1;   END IF;
    IF p_limit < 1   THEN p_limit := 50;  END IF;
    IF p_limit > 500 THEN p_limit := 500; END IF;

    RETURN QUERY
    SELECT
        COUNT(*) OVER()         AS p_total_count,
        "LegalObligationId",
        "CountryCode",
        "Code",
        "Name",
        "InstitutionName",
        "ObligationType",
        "CalculationBasis",
        "SalaryCap",
        "SalaryCapUnit",
        "EmployerRate",
        "EmployeeRate",
        "RateVariableByRisk",
        "FilingFrequency",
        "FilingDeadlineRule",
        "EffectiveFrom",
        "EffectiveTo",
        "IsActive",
        "Notes"
    FROM hr."LegalObligation"
    WHERE (p_country_code    IS NULL OR "CountryCode"    = p_country_code)
      AND (p_obligation_type IS NULL OR "ObligationType" = p_obligation_type)
      AND (p_is_active       IS NULL OR "IsActive"       = p_is_active)
      AND (p_search          IS NULL OR "Name" ILIKE '%' || p_search || '%'
                                     OR "Code" ILIKE '%' || p_search || '%')
    ORDER BY "CountryCode", "Code"
    LIMIT p_limit OFFSET (p_page - 1) * p_limit;
END;
$function$
;

-- usp_hr_obligation_save
CREATE OR REPLACE FUNCTION public.usp_hr_obligation_save(p_legal_obligation_id integer DEFAULT NULL::integer, p_country_code character DEFAULT NULL::bpchar, p_code character varying DEFAULT NULL::character varying, p_name character varying DEFAULT NULL::character varying, p_institution_name character varying DEFAULT NULL::character varying, p_obligation_type character varying DEFAULT NULL::character varying, p_calculation_basis character varying DEFAULT NULL::character varying, p_salary_cap numeric DEFAULT NULL::numeric, p_salary_cap_unit character varying DEFAULT NULL::character varying, p_employer_rate numeric DEFAULT 0, p_employee_rate numeric DEFAULT 0, p_rate_variable_by_risk boolean DEFAULT false, p_filing_frequency character varying DEFAULT NULL::character varying, p_filing_deadline_rule character varying DEFAULT NULL::character varying, p_effective_from date DEFAULT NULL::date, p_effective_to date DEFAULT NULL::date, p_is_active boolean DEFAULT true, p_notes character varying DEFAULT NULL::character varying, OUT p_resultado integer, OUT p_mensaje character varying)
 RETURNS record
 LANGUAGE plpgsql
AS $function$
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    -- Validaciones
    IF p_country_code IS NULL OR LENGTH(TRIM(p_country_code)) = 0 THEN
        p_resultado := -1;
        p_mensaje   := 'El código de país es obligatorio.';
        RETURN;
    END IF;

    IF p_code IS NULL OR LENGTH(TRIM(p_code)) = 0 THEN
        p_resultado := -1;
        p_mensaje   := 'El código de obligación es obligatorio.';
        RETURN;
    END IF;

    IF p_obligation_type NOT IN ('CONTRIBUTION','TAX_WITHHOLDING','REPORTING','REGISTRATION') THEN
        p_resultado := -1;
        p_mensaje   := 'Tipo de obligación no válido. Use: CONTRIBUTION, TAX_WITHHOLDING, REPORTING, REGISTRATION.';
        RETURN;
    END IF;

    IF p_calculation_basis NOT IN ('NORMAL_SALARY','INTEGRAL_SALARY','GROSS_PAYROLL','TAXABLE_INCOME','FIXED_AMOUNT') THEN
        p_resultado := -1;
        p_mensaje   := 'Base de cálculo no válida.';
        RETURN;
    END IF;

    IF p_filing_frequency NOT IN ('MONTHLY','QUARTERLY','ANNUAL','REALTIME') THEN
        p_resultado := -1;
        p_mensaje   := 'Frecuencia de presentación no válida.';
        RETURN;
    END IF;

    BEGIN
        IF p_legal_obligation_id IS NULL OR p_legal_obligation_id = 0 THEN
            -- Verificar duplicado
            IF EXISTS (
                SELECT 1 FROM hr."LegalObligation"
                WHERE "CountryCode" = p_country_code
                  AND "Code" = p_code
                  AND "EffectiveFrom" = p_effective_from
            ) THEN
                p_resultado := -2;
                p_mensaje   := 'Ya existe una obligación con ese código y fecha de vigencia para el país indicado.';
                RETURN;
            END IF;

            INSERT INTO hr."LegalObligation" (
                "CountryCode", "Code", "Name", "InstitutionName", "ObligationType",
                "CalculationBasis", "SalaryCap", "SalaryCapUnit", "EmployerRate", "EmployeeRate",
                "RateVariableByRisk", "FilingFrequency", "FilingDeadlineRule",
                "EffectiveFrom", "EffectiveTo", "IsActive", "Notes",
                "CreatedAt", "UpdatedAt"
            )
            VALUES (
                p_country_code, p_code, p_name, p_institution_name, p_obligation_type,
                p_calculation_basis, p_salary_cap, p_salary_cap_unit, p_employer_rate, p_employee_rate,
                p_rate_variable_by_risk, p_filing_frequency, p_filing_deadline_rule,
                p_effective_from, p_effective_to, p_is_active, p_notes,
                (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
            )
            RETURNING "LegalObligationId" INTO p_resultado;

            p_mensaje := 'Obligación legal creada exitosamente.';

        ELSE
            IF NOT EXISTS (SELECT 1 FROM hr."LegalObligation" WHERE "LegalObligationId" = p_legal_obligation_id) THEN
                p_resultado := -3;
                p_mensaje   := 'No se encontró la obligación legal con el ID indicado.';
                RETURN;
            END IF;

            -- Verificar duplicado excluyendo el registro actual
            IF EXISTS (
                SELECT 1 FROM hr."LegalObligation"
                WHERE "CountryCode" = p_country_code
                  AND "Code" = p_code
                  AND "EffectiveFrom" = p_effective_from
                  AND "LegalObligationId" <> p_legal_obligation_id
            ) THEN
                p_resultado := -2;
                p_mensaje   := 'Ya existe otra obligación con ese código y fecha de vigencia para el país indicado.';
                RETURN;
            END IF;

            UPDATE hr."LegalObligation" SET
                "CountryCode"           = p_country_code,
                "Code"                  = p_code,
                "Name"                  = p_name,
                "InstitutionName"       = p_institution_name,
                "ObligationType"        = p_obligation_type,
                "CalculationBasis"      = p_calculation_basis,
                "SalaryCap"             = p_salary_cap,
                "SalaryCapUnit"         = p_salary_cap_unit,
                "EmployerRate"          = p_employer_rate,
                "EmployeeRate"          = p_employee_rate,
                "RateVariableByRisk"    = p_rate_variable_by_risk,
                "FilingFrequency"       = p_filing_frequency,
                "FilingDeadlineRule"    = p_filing_deadline_rule,
                "EffectiveFrom"         = p_effective_from,
                "EffectiveTo"           = p_effective_to,
                "IsActive"              = p_is_active,
                "Notes"                 = p_notes,
                "UpdatedAt"             = (NOW() AT TIME ZONE 'UTC')
            WHERE "LegalObligationId" = p_legal_obligation_id;

            p_resultado := p_legal_obligation_id;
            p_mensaje   := 'Obligación legal actualizada exitosamente.';
        END IF;

    EXCEPTION WHEN OTHERS THEN
        p_resultado := -99;
        p_mensaje   := SQLERRM;
    END;
END;
$function$
;

-- usp_hr_occhealth_create
CREATE OR REPLACE FUNCTION public.usp_hr_occhealth_create(p_company_id integer, p_country_code character, p_record_type character varying, p_employee_id bigint DEFAULT NULL::bigint, p_employee_code character varying DEFAULT NULL::character varying, p_employee_name character varying DEFAULT NULL::character varying, p_occurrence_date timestamp without time zone DEFAULT NULL::timestamp without time zone, p_report_deadline timestamp without time zone DEFAULT NULL::timestamp without time zone, p_reported_date timestamp without time zone DEFAULT NULL::timestamp without time zone, p_severity character varying DEFAULT NULL::character varying, p_body_part_affected character varying DEFAULT NULL::character varying, p_days_lost integer DEFAULT NULL::integer, p_location character varying DEFAULT NULL::character varying, p_description text DEFAULT NULL::text, p_root_cause character varying DEFAULT NULL::character varying, p_corrective_action character varying DEFAULT NULL::character varying, p_investigation_due_date date DEFAULT NULL::date, p_institution_reference character varying DEFAULT NULL::character varying, p_document_url character varying DEFAULT NULL::character varying, p_notes character varying DEFAULT NULL::character varying, p_created_by integer DEFAULT NULL::integer, OUT p_resultado integer, OUT p_mensaje character varying)
 RETURNS record
 LANGUAGE plpgsql
AS $function$
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    IF p_record_type NOT IN ('ACCIDENT','DISEASE','NEAR_MISS','INSPECTION','RISK_NOTIFICATION') THEN
        p_resultado := -1;
        p_mensaje   := 'Tipo de registro no válido.';
        RETURN;
    END IF;

    IF p_severity IS NOT NULL AND p_severity NOT IN ('MINOR','MODERATE','SEVERE','FATAL') THEN
        p_resultado := -1;
        p_mensaje   := 'Severidad no válida.';
        RETURN;
    END IF;

    BEGIN
        INSERT INTO hr."OccupationalHealth" (
            "CompanyId", "CountryCode", "RecordType",
            "EmployeeId", "EmployeeCode", "EmployeeName",
            "OccurrenceDate", "ReportDeadline", "ReportedDate",
            "Severity", "BodyPartAffected", "DaysLost",
            "Location", "Description", "RootCause", "CorrectiveAction",
            "InvestigationDueDate", "InstitutionReference",
            "Status", "DocumentUrl", "Notes", "CreatedBy",
            "CreatedAt", "UpdatedAt"
        )
        VALUES (
            p_company_id, p_country_code, p_record_type,
            p_employee_id, p_employee_code, p_employee_name,
            p_occurrence_date, p_report_deadline, p_reported_date,
            p_severity, p_body_part_affected, p_days_lost,
            p_location, p_description, p_root_cause, p_corrective_action,
            p_investigation_due_date, p_institution_reference,
            'OPEN', p_document_url, p_notes, p_created_by,
            (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
        )
        RETURNING "OccupationalHealthId" INTO p_resultado;

        p_mensaje := 'Registro de salud ocupacional creado exitosamente.';

    EXCEPTION WHEN OTHERS THEN
        p_resultado := -1;
        p_mensaje   := SQLERRM;
    END;
END;
$function$
;

-- usp_hr_occhealth_get
CREATE OR REPLACE FUNCTION public.usp_hr_occhealth_get(p_occupational_health_id integer, p_company_id integer)
 RETURNS TABLE("OccupationalHealthId" integer, "CompanyId" integer, "CountryCode" character, "RecordType" character varying, "EmployeeId" bigint, "EmployeeCode" character varying, "EmployeeName" character varying, "OccurrenceDate" timestamp without time zone, "ReportDeadline" timestamp without time zone, "ReportedDate" timestamp without time zone, "Severity" character varying, "BodyPartAffected" character varying, "DaysLost" integer, "Location" character varying, "Description" character varying, "RootCause" character varying, "CorrectiveAction" character varying, "InvestigationDueDate" date, "InvestigationCompletedDate" date, "InstitutionReference" character varying, "Status" character varying, "DocumentUrl" character varying, "Notes" character varying, "CreatedBy" integer, "CreatedAt" timestamp without time zone, "UpdatedAt" timestamp without time zone)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        o."OccupationalHealthId",
        o."CompanyId",
        o."CountryCode",
        o."RecordType",
        o."EmployeeId",
        o."EmployeeCode",
        o."EmployeeName",
        o."OccurrenceDate",
        o."ReportDeadline",
        o."ReportedDate",
        o."Severity",
        o."BodyPartAffected",
        o."DaysLost",
        o."Location",
        o."Description",
        o."RootCause",
        o."CorrectiveAction",
        o."InvestigationDueDate",
        o."InvestigationCompletedDate",
        o."InstitutionReference",
        o."Status",
        o."DocumentUrl",
        o."Notes",
        o."CreatedBy",
        o."CreatedAt",
        o."UpdatedAt"
    FROM hr."OccupationalHealth" o
    WHERE o."OccupationalHealthId" = p_occupational_health_id
      AND o."CompanyId" = p_company_id;
END;
$function$
;

-- usp_hr_occhealth_list
CREATE OR REPLACE FUNCTION public.usp_hr_occhealth_list(p_company_id integer, p_record_type character varying DEFAULT NULL::character varying, p_status character varying DEFAULT NULL::character varying, p_employee_code character varying DEFAULT NULL::character varying, p_country_code character DEFAULT NULL::bpchar, p_from_date date DEFAULT NULL::date, p_to_date date DEFAULT NULL::date, p_page integer DEFAULT 1, p_limit integer DEFAULT 50)
 RETURNS TABLE(p_total_count bigint, "OccupationalHealthId" integer, "CompanyId" integer, "CountryCode" character, "RecordType" character varying, "EmployeeId" bigint, "EmployeeCode" character varying, "EmployeeName" character varying, "OccurrenceDate" timestamp without time zone, "ReportDeadline" timestamp without time zone, "ReportedDate" timestamp without time zone, "Severity" character varying, "BodyPartAffected" character varying, "DaysLost" integer, "Location" character varying, "Description" character varying, "RootCause" character varying, "CorrectiveAction" character varying, "InvestigationDueDate" date, "InvestigationCompletedDate" date, "InstitutionReference" character varying, "Status" character varying, "DocumentUrl" character varying, "Notes" character varying, "CreatedBy" integer, "CreatedAt" timestamp without time zone, "UpdatedAt" timestamp without time zone)
 LANGUAGE plpgsql
AS $function$
BEGIN
    IF p_page  < 1   THEN p_page  := 1;   END IF;
    IF p_limit < 1   THEN p_limit := 50;  END IF;
    IF p_limit > 500 THEN p_limit := 500; END IF;

    RETURN QUERY
    SELECT
        COUNT(*) OVER()         AS p_total_count,
        "OccupationalHealthId",
        "CompanyId",
        "CountryCode",
        "RecordType",
        "EmployeeId",
        "EmployeeCode",
        "EmployeeName",
        "OccurrenceDate",
        "ReportDeadline",
        "ReportedDate",
        "Severity",
        "BodyPartAffected",
        "DaysLost",
        "Location",
        "Description",
        "RootCause",
        "CorrectiveAction",
        "InvestigationDueDate",
        "InvestigationCompletedDate",
        "InstitutionReference",
        "Status",
        "DocumentUrl",
        "Notes",
        "CreatedBy",
        "CreatedAt",
        "UpdatedAt"
    FROM hr."OccupationalHealth"
    WHERE "CompanyId" = p_company_id
      AND (p_record_type   IS NULL OR "RecordType"   = p_record_type)
      AND (p_status        IS NULL OR "Status"        = p_status)
      AND (p_employee_code IS NULL OR "EmployeeCode"  = p_employee_code)
      AND (p_country_code  IS NULL OR "CountryCode"   = p_country_code)
      AND (p_from_date     IS NULL OR "OccurrenceDate" >= p_from_date)
      AND (p_to_date       IS NULL OR "OccurrenceDate" <= p_to_date)
    ORDER BY "OccurrenceDate" DESC, "OccupationalHealthId" DESC
    LIMIT p_limit OFFSET (p_page - 1) * p_limit;
END;
$function$
;

-- usp_hr_occhealth_update
CREATE OR REPLACE FUNCTION public.usp_hr_occhealth_update(p_occupational_health_id integer, p_company_id integer, p_reported_date timestamp without time zone DEFAULT NULL::timestamp without time zone, p_severity character varying DEFAULT NULL::character varying, p_body_part_affected character varying DEFAULT NULL::character varying, p_days_lost integer DEFAULT NULL::integer, p_location character varying DEFAULT NULL::character varying, p_description text DEFAULT NULL::text, p_root_cause character varying DEFAULT NULL::character varying, p_corrective_action character varying DEFAULT NULL::character varying, p_investigation_due_date date DEFAULT NULL::date, p_investigation_completed_date date DEFAULT NULL::date, p_institution_reference character varying DEFAULT NULL::character varying, p_status character varying DEFAULT NULL::character varying, p_document_url character varying DEFAULT NULL::character varying, p_notes character varying DEFAULT NULL::character varying, OUT p_resultado integer, OUT p_mensaje character varying)
 RETURNS record
 LANGUAGE plpgsql
AS $function$
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    IF NOT EXISTS (
        SELECT 1 FROM hr."OccupationalHealth"
        WHERE "OccupationalHealthId" = p_occupational_health_id AND "CompanyId" = p_company_id
    ) THEN
        p_resultado := -1;
        p_mensaje   := 'Registro no encontrado.';
        RETURN;
    END IF;

    IF p_status IS NOT NULL AND p_status NOT IN ('OPEN','REPORTED','INVESTIGATING','CLOSED') THEN
        p_resultado := -1;
        p_mensaje   := 'Estado no válido.';
        RETURN;
    END IF;

    IF p_severity IS NOT NULL AND p_severity NOT IN ('MINOR','MODERATE','SEVERE','FATAL') THEN
        p_resultado := -1;
        p_mensaje   := 'Severidad no válida.';
        RETURN;
    END IF;

    BEGIN
        UPDATE hr."OccupationalHealth"
        SET
            "ReportedDate"               = COALESCE(p_reported_date,              "ReportedDate"),
            "Severity"                   = COALESCE(p_severity,                   "Severity"),
            "BodyPartAffected"           = COALESCE(p_body_part_affected,         "BodyPartAffected"),
            "DaysLost"                   = COALESCE(p_days_lost,                  "DaysLost"),
            "Location"                   = COALESCE(p_location,                   "Location"),
            "Description"                = COALESCE(p_description,                "Description"),
            "RootCause"                  = COALESCE(p_root_cause,                 "RootCause"),
            "CorrectiveAction"           = COALESCE(p_corrective_action,          "CorrectiveAction"),
            "InvestigationDueDate"       = COALESCE(p_investigation_due_date,     "InvestigationDueDate"),
            "InvestigationCompletedDate" = COALESCE(p_investigation_completed_date, "InvestigationCompletedDate"),
            "InstitutionReference"       = COALESCE(p_institution_reference,      "InstitutionReference"),
            "Status"                     = COALESCE(p_status,                     "Status"),
            "DocumentUrl"                = COALESCE(p_document_url,               "DocumentUrl"),
            "Notes"                      = COALESCE(p_notes,                      "Notes"),
            "UpdatedAt"                  = (NOW() AT TIME ZONE 'UTC')
        WHERE "OccupationalHealthId" = p_occupational_health_id
          AND "CompanyId" = p_company_id;

        p_resultado := p_occupational_health_id;
        p_mensaje   := 'Registro actualizado exitosamente.';

    EXCEPTION WHEN OTHERS THEN
        p_resultado := -1;
        p_mensaje   := SQLERRM;
    END;
END;
$function$
;

-- usp_hr_payroll_approvedraft
CREATE OR REPLACE FUNCTION public.usp_hr_payroll_approvedraft(p_batch_id integer, p_approved_by integer, p_user_id integer, OUT p_resultado integer, OUT p_mensaje text)
 RETURNS record
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_current_status VARCHAR(20);
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    SELECT "Status"
    INTO v_current_status
    FROM hr."PayrollBatch"
    WHERE "BatchId" = p_batch_id;

    IF v_current_status IS NULL THEN
        p_resultado := -1;
        p_mensaje   := 'Lote no encontrado.';
        RETURN;
    END IF;

    IF v_current_status NOT IN ('BORRADOR', 'EN_REVISION') THEN
        p_resultado := -2;
        p_mensaje   := 'Solo se pueden aprobar lotes en estado BORRADOR o EN_REVISION. Estado actual: ' || v_current_status;
        RETURN;
    END IF;

    -- Verificar que el lote tiene líneas
    IF NOT EXISTS (SELECT 1 FROM hr."PayrollBatchLine" WHERE "BatchId" = p_batch_id) THEN
        p_resultado := -3;
        p_mensaje   := 'No se puede aprobar un lote sin líneas.';
        RETURN;
    END IF;

    BEGIN
        UPDATE hr."PayrollBatch"
        SET "Status"     = 'APROBADA',
            "ApprovedBy" = p_approved_by,
            "ApprovedAt" = (NOW() AT TIME ZONE 'UTC'),
            "UpdatedAt"  = (NOW() AT TIME ZONE 'UTC')
        WHERE "BatchId" = p_batch_id;

        p_resultado := 1;
        p_mensaje   := 'Lote aprobado exitosamente.';

    EXCEPTION WHEN OTHERS THEN
        p_resultado := -99;
        p_mensaje   := 'Error: ' || SQLERRM;
    END;
END;
$function$
;

-- usp_hr_payroll_batchaddline
CREATE OR REPLACE FUNCTION public.usp_hr_payroll_batchaddline(p_batch_id integer, p_employee_code character varying, p_concept_code character varying, p_concept_name character varying, p_concept_type character varying, p_quantity numeric, p_amount numeric, p_user_id integer, OUT p_resultado integer, OUT p_mensaje text)
 RETURNS record
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_employee_name VARCHAR(200);
    v_employee_id   BIGINT;
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    -- Validar batch en BORRADOR
    IF NOT EXISTS (
        SELECT 1 FROM hr."PayrollBatch"
        WHERE "BatchId" = p_batch_id AND "Status" = 'BORRADOR'
    ) THEN
        p_resultado := -1;
        p_mensaje   := 'El lote no existe o no está en estado BORRADOR.';
        RETURN;
    END IF;

    -- Obtener nombre del empleado
    SELECT COALESCE(e."EmployeeName", ''), e."EmployeeId"
    INTO v_employee_name, v_employee_id
    FROM master."Employee" e
    WHERE e."EmployeeCode" = p_employee_code
      AND e."IsActive"     = TRUE
    LIMIT 1;

    IF v_employee_name IS NULL THEN
        -- Intentar obtener de líneas existentes del batch
        SELECT bl."EmployeeName", bl."EmployeeId"
        INTO v_employee_name, v_employee_id
        FROM hr."PayrollBatchLine" bl
        WHERE bl."BatchId"      = p_batch_id
          AND bl."EmployeeCode" = p_employee_code
        LIMIT 1;
    END IF;

    IF v_employee_name IS NULL THEN
        p_resultado := -2;
        p_mensaje   := 'Empleado no encontrado.';
        RETURN;
    END IF;

    -- Verificar que no exista ya ese concepto para el empleado en este lote
    IF EXISTS (
        SELECT 1 FROM hr."PayrollBatchLine"
        WHERE "BatchId"      = p_batch_id
          AND "EmployeeCode" = p_employee_code
          AND "ConceptCode"  = p_concept_code
    ) THEN
        p_resultado := -3;
        p_mensaje   := 'El concepto ya existe para este empleado en el lote.';
        RETURN;
    END IF;

    BEGIN
        INSERT INTO hr."PayrollBatchLine" (
            "BatchId", "EmployeeId", "EmployeeCode", "EmployeeName",
            "ConceptCode", "ConceptName", "ConceptType",
            "Quantity", "Amount", "Total", "IsModified", "UpdatedAt"
        )
        VALUES (
            p_batch_id, v_employee_id, p_employee_code, v_employee_name,
            p_concept_code, p_concept_name, p_concept_type,
            p_quantity, p_amount, p_quantity * p_amount, TRUE,
            (NOW() AT TIME ZONE 'UTC')
        );

        -- Recalcular totales del batch
        UPDATE hr."PayrollBatch"
        SET "TotalEmployees" = (SELECT COUNT(DISTINCT "EmployeeCode") FROM hr."PayrollBatchLine" WHERE "BatchId" = p_batch_id),
            "TotalGross"     = COALESCE((SELECT SUM("Total") FROM hr."PayrollBatchLine" WHERE "BatchId" = p_batch_id AND "ConceptType" IN ('ASIGNACION', 'BONO')), 0),
            "TotalDeductions"= COALESCE((SELECT SUM("Total") FROM hr."PayrollBatchLine" WHERE "BatchId" = p_batch_id AND "ConceptType" = 'DEDUCCION'), 0),
            "TotalNet"       = COALESCE((SELECT SUM("Total") FROM hr."PayrollBatchLine" WHERE "BatchId" = p_batch_id AND "ConceptType" IN ('ASIGNACION', 'BONO')), 0)
                             - COALESCE((SELECT SUM("Total") FROM hr."PayrollBatchLine" WHERE "BatchId" = p_batch_id AND "ConceptType" = 'DEDUCCION'), 0),
            "UpdatedAt"      = (NOW() AT TIME ZONE 'UTC')
        WHERE "BatchId" = p_batch_id;

        p_resultado := 1;
        p_mensaje   := 'Línea agregada correctamente.';

    EXCEPTION WHEN OTHERS THEN
        p_resultado := -99;
        p_mensaje   := 'Error: ' || SQLERRM;
    END;
END;
$function$
;

-- usp_hr_payroll_batchbulkupdate
CREATE OR REPLACE FUNCTION public.usp_hr_payroll_batchbulkupdate(p_batch_id integer, p_concept_code character varying, p_concept_type character varying, p_amount numeric, p_user_id integer, p_employee_codes text DEFAULT NULL::text, OUT p_affected_count integer, OUT p_resultado integer, OUT p_mensaje text)
 RETURNS record
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_count INTEGER;
BEGIN
    p_affected_count := 0;
    p_resultado      := 0;
    p_mensaje        := '';

    -- Validar batch en BORRADOR
    IF NOT EXISTS (
        SELECT 1 FROM hr."PayrollBatch"
        WHERE "BatchId" = p_batch_id AND "Status" = 'BORRADOR'
    ) THEN
        p_resultado := -1;
        p_mensaje   := 'El lote no existe o no está en estado BORRADOR.';
        RETURN;
    END IF;

    BEGIN
        -- Actualizar líneas existentes que coincidan
        UPDATE hr."PayrollBatchLine" bl
        SET "Amount"     = p_amount,
            "Total"      = bl."Quantity" * p_amount,
            "IsModified" = TRUE,
            "UpdatedAt"  = (NOW() AT TIME ZONE 'UTC')
        WHERE bl."BatchId"     = p_batch_id
          AND bl."ConceptCode" = p_concept_code
          AND bl."ConceptType" = p_concept_type
          AND (
              p_employee_codes IS NULL
              OR bl."EmployeeCode" IN (
                  SELECT t.code
                  FROM json_to_recordset(p_employee_codes::json) AS t(code VARCHAR(24))
              )
          );

        GET DIAGNOSTICS v_count = ROW_COUNT;
        p_affected_count := v_count;

        -- Recalcular totales del batch
        UPDATE hr."PayrollBatch"
        SET "TotalGross"     = COALESCE((SELECT SUM("Total") FROM hr."PayrollBatchLine" WHERE "BatchId" = p_batch_id AND "ConceptType" IN ('ASIGNACION', 'BONO')), 0),
            "TotalDeductions"= COALESCE((SELECT SUM("Total") FROM hr."PayrollBatchLine" WHERE "BatchId" = p_batch_id AND "ConceptType" = 'DEDUCCION'), 0),
            "TotalNet"       = COALESCE((SELECT SUM("Total") FROM hr."PayrollBatchLine" WHERE "BatchId" = p_batch_id AND "ConceptType" IN ('ASIGNACION', 'BONO')), 0)
                             - COALESCE((SELECT SUM("Total") FROM hr."PayrollBatchLine" WHERE "BatchId" = p_batch_id AND "ConceptType" = 'DEDUCCION'), 0),
            "UpdatedAt"      = (NOW() AT TIME ZONE 'UTC')
        WHERE "BatchId" = p_batch_id;

        p_resultado := 1;
        p_mensaje   := p_affected_count::TEXT || ' líneas actualizadas.';

    EXCEPTION WHEN OTHERS THEN
        p_resultado := -99;
        p_mensaje   := 'Error: ' || SQLERRM;
    END;
END;
$function$
;

-- usp_hr_payroll_batchremoveline
CREATE OR REPLACE FUNCTION public.usp_hr_payroll_batchremoveline(p_line_id integer, p_user_id integer, OUT p_resultado integer, OUT p_mensaje text)
 RETURNS record
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_batch_id INTEGER;
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    SELECT bl."BatchId"
    INTO v_batch_id
    FROM hr."PayrollBatchLine" bl
    INNER JOIN hr."PayrollBatch" b ON b."BatchId" = bl."BatchId"
    WHERE bl."LineId" = p_line_id
      AND b."Status"  = 'BORRADOR';

    IF v_batch_id IS NULL THEN
        p_resultado := -1;
        p_mensaje   := 'Línea no encontrada o el lote no está en estado BORRADOR.';
        RETURN;
    END IF;

    BEGIN
        DELETE FROM hr."PayrollBatchLine" WHERE "LineId" = p_line_id;

        -- Recalcular totales del batch
        UPDATE hr."PayrollBatch"
        SET "TotalEmployees" = (SELECT COUNT(DISTINCT "EmployeeCode") FROM hr."PayrollBatchLine" WHERE "BatchId" = v_batch_id),
            "TotalGross"     = COALESCE((SELECT SUM("Total") FROM hr."PayrollBatchLine" WHERE "BatchId" = v_batch_id AND "ConceptType" IN ('ASIGNACION', 'BONO')), 0),
            "TotalDeductions"= COALESCE((SELECT SUM("Total") FROM hr."PayrollBatchLine" WHERE "BatchId" = v_batch_id AND "ConceptType" = 'DEDUCCION'), 0),
            "TotalNet"       = COALESCE((SELECT SUM("Total") FROM hr."PayrollBatchLine" WHERE "BatchId" = v_batch_id AND "ConceptType" IN ('ASIGNACION', 'BONO')), 0)
                             - COALESCE((SELECT SUM("Total") FROM hr."PayrollBatchLine" WHERE "BatchId" = v_batch_id AND "ConceptType" = 'DEDUCCION'), 0),
            "UpdatedAt"      = (NOW() AT TIME ZONE 'UTC')
        WHERE "BatchId" = v_batch_id;

        p_resultado := 1;
        p_mensaje   := 'Línea eliminada correctamente.';

    EXCEPTION WHEN OTHERS THEN
        p_resultado := -99;
        p_mensaje   := 'Error: ' || SQLERRM;
    END;
END;
$function$
;

-- usp_hr_payroll_closerun
CREATE OR REPLACE FUNCTION public.usp_hr_payroll_closerun(p_company_id integer, p_payroll_code character varying, p_employee_code character varying DEFAULT NULL::character varying, p_user_id integer DEFAULT NULL::integer)
 RETURNS TABLE("Resultado" integer, "Mensaje" character varying)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_affected INT;
BEGIN
    UPDATE hr."PayrollRun"
    SET "IsClosed"        = TRUE,
        "ClosedAt"        = NOW() AT TIME ZONE 'UTC',
        "ClosedByUserId"  = p_user_id,
        "UpdatedAt"       = NOW() AT TIME ZONE 'UTC',
        "UpdatedByUserId" = p_user_id
    WHERE "CompanyId"   = p_company_id
      AND "PayrollCode" = p_payroll_code
      AND "IsClosed"    = FALSE
      AND (p_employee_code IS NULL OR "EmployeeCode" = p_employee_code);

    GET DIAGNOSTICS v_affected = ROW_COUNT;

    IF v_affected > 0 THEN
        RETURN QUERY SELECT v_affected, 'Nomina cerrada'::TEXT;
    ELSE
        RETURN QUERY SELECT 0, 'No se encontraron registros abiertos'::TEXT;
    END IF;
END;
$function$
;

-- usp_hr_payroll_ensureemployee
CREATE OR REPLACE FUNCTION public.usp_hr_payroll_ensureemployee(p_company_id integer, p_document character varying, p_user_id integer DEFAULT NULL::integer)
 RETURNS TABLE("employeeId" bigint, "employeeCode" character varying, "employeeName" character varying, "hireDate" date)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_exists BOOLEAN;
BEGIN
    SELECT EXISTS (
        SELECT 1 FROM master."Employee"
        WHERE "CompanyId" = p_company_id AND "IsDeleted" = FALSE
          AND ("EmployeeCode" = p_document OR "FiscalId" = p_document)
    ) INTO v_exists;

    IF v_exists THEN
        RETURN QUERY
        SELECT e."EmployeeId", e."EmployeeCode", e."EmployeeName", e."HireDate"
        FROM master."Employee" e
        WHERE e."CompanyId" = p_company_id AND e."IsDeleted" = FALSE
          AND (e."EmployeeCode" = p_document OR e."FiscalId" = p_document)
        ORDER BY e."EmployeeId"
        LIMIT 1;
        RETURN;
    END IF;

    RETURN QUERY
    INSERT INTO master."Employee" (
        "CompanyId", "EmployeeCode", "EmployeeName", "FiscalId",
        "HireDate", "IsActive", "CreatedByUserId", "UpdatedByUserId"
    )
    VALUES (
        p_company_id, p_document, 'Empleado ' || p_document, p_document,
        (NOW() AT TIME ZONE 'UTC')::DATE, TRUE, p_user_id, p_user_id
    )
    RETURNING "EmployeeId", "EmployeeCode", "EmployeeName", "HireDate";
END;
$function$
;

-- usp_hr_payroll_ensuretype
CREATE OR REPLACE FUNCTION public.usp_hr_payroll_ensuretype(p_company_id integer, p_payroll_code character varying, p_user_id integer DEFAULT NULL::integer)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM hr."PayrollType"
        WHERE "CompanyId" = p_company_id AND "PayrollCode" = p_payroll_code
    ) THEN
        INSERT INTO hr."PayrollType" ("CompanyId", "PayrollCode", "PayrollName", "IsActive", "CreatedByUserId", "UpdatedByUserId")
        VALUES (p_company_id, p_payroll_code, 'Nomina ' || p_payroll_code, TRUE, p_user_id, p_user_id);
    END IF;
END;
$function$
;

-- usp_hr_payroll_generatedraft
CREATE OR REPLACE FUNCTION public.usp_hr_payroll_generatedraft(p_company_id integer, p_branch_id integer, p_payroll_code character varying, p_from_date date, p_to_date date, p_user_id integer, p_department_filter character varying DEFAULT NULL::character varying, OUT p_batch_id integer, OUT p_resultado integer, OUT p_mensaje text)
 RETURNS record
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_emp_count INTEGER := 0;
BEGIN
    p_resultado := 0;
    p_mensaje   := '';
    p_batch_id  := 0;

    -- Validaciones básicas
    IF p_from_date >= p_to_date THEN
        p_resultado := -1;
        p_mensaje   := 'La fecha desde debe ser menor que la fecha hasta.';
        RETURN;
    END IF;

    -- Verificar que no exista un batch BORRADOR duplicado para el mismo período
    IF EXISTS (
        SELECT 1 FROM hr."PayrollBatch"
        WHERE "CompanyId"   = p_company_id
          AND "BranchId"    = p_branch_id
          AND "PayrollCode" = p_payroll_code
          AND "FromDate"    = p_from_date
          AND "ToDate"      = p_to_date
          AND "Status"      = 'BORRADOR'
    ) THEN
        p_resultado := -2;
        p_mensaje   := 'Ya existe un borrador de nómina para este período y tipo.';
        RETURN;
    END IF;

    BEGIN
        -- Crear el batch
        INSERT INTO hr."PayrollBatch" (
            "CompanyId", "BranchId", "PayrollCode", "FromDate", "ToDate",
            "Status", "CreatedBy"
        )
        VALUES (
            p_company_id, p_branch_id, p_payroll_code, p_from_date, p_to_date,
            'BORRADOR', p_user_id
        )
        RETURNING "BatchId" INTO p_batch_id;

        -- Insertar líneas por cada empleado activo + cada concepto activo de la nómina
        INSERT INTO hr."PayrollBatchLine" (
            "BatchId", "EmployeeId", "EmployeeCode", "EmployeeName",
            "ConceptCode", "ConceptName", "ConceptType",
            "Quantity", "Amount", "Total"
        )
        SELECT
            p_batch_id,
            e."EmployeeId",
            e."EmployeeCode",
            COALESCE(e."EmployeeName", ''),
            pc."ConceptCode",
            pc."ConceptName",
            pc."ConceptType",
            1,
            COALESCE(pc."DefaultValue", 0),
            COALESCE(pc."DefaultValue", 0)
        FROM master."Employee" e
        CROSS JOIN hr."PayrollConcept" pc
        WHERE e."CompanyId"    = p_company_id
          AND e."IsActive"     = TRUE
          AND pc."CompanyId"   = p_company_id
          AND pc."PayrollCode" = p_payroll_code
          AND pc."IsActive"    = TRUE;

        SELECT COUNT(DISTINCT "EmployeeCode")
        INTO v_emp_count
        FROM hr."PayrollBatchLine"
        WHERE "BatchId" = p_batch_id;

        -- Actualizar totales del batch
        UPDATE hr."PayrollBatch"
        SET "TotalEmployees" = v_emp_count,
            "TotalGross"     = COALESCE((SELECT SUM("Total") FROM hr."PayrollBatchLine" WHERE "BatchId" = p_batch_id AND "ConceptType" IN ('ASIGNACION', 'BONO')), 0),
            "TotalDeductions"= COALESCE((SELECT SUM("Total") FROM hr."PayrollBatchLine" WHERE "BatchId" = p_batch_id AND "ConceptType" = 'DEDUCCION'), 0),
            "TotalNet"       = COALESCE((SELECT SUM("Total") FROM hr."PayrollBatchLine" WHERE "BatchId" = p_batch_id AND "ConceptType" IN ('ASIGNACION', 'BONO')), 0)
                             - COALESCE((SELECT SUM("Total") FROM hr."PayrollBatchLine" WHERE "BatchId" = p_batch_id AND "ConceptType" = 'DEDUCCION'), 0),
            "UpdatedAt"      = (NOW() AT TIME ZONE 'UTC')
        WHERE "BatchId" = p_batch_id;

        p_resultado := 1;
        p_mensaje   := 'Borrador generado exitosamente con ' || v_emp_count::TEXT || ' empleados.';

    EXCEPTION WHEN OTHERS THEN
        p_resultado := -99;
        p_mensaje   := 'Error: ' || SQLERRM;
    END;
END;
$function$
;

-- usp_hr_payroll_getconstant
CREATE OR REPLACE FUNCTION public.usp_hr_payroll_getconstant(p_company_id integer, p_code character varying)
 RETURNS TABLE(value numeric)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT pc."ConstantValue"
    FROM hr."PayrollConstant" pc
    WHERE pc."CompanyId" = p_company_id
      AND pc."ConstantCode" = p_code
      AND pc."IsActive" = TRUE
    ORDER BY pc."PayrollConstantId" DESC
    LIMIT 1;
END;
$function$
;

-- usp_hr_payroll_getdraftgrid
CREATE OR REPLACE FUNCTION public.usp_hr_payroll_getdraftgrid(p_batch_id integer, p_search character varying DEFAULT NULL::character varying, p_department character varying DEFAULT NULL::character varying, p_only_modified boolean DEFAULT false, p_offset integer DEFAULT 0, p_limit integer DEFAULT 50)
 RETURNS TABLE(p_total_count bigint, "EmployeeCode" character varying, "EmployeeName" character varying, "EmployeeId" bigint, "DepartmentCode" character varying, "DepartmentName" character varying, "PositionName" character varying, "TotalGross" numeric, "TotalDeductions" numeric, "TotalNet" numeric, "HasModified" bigint, "ConceptCount" bigint)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    WITH "EmployeeSummary" AS (
        SELECT
            bl."EmployeeCode",
            bl."EmployeeName",
            bl."EmployeeId",
            SUM(CASE WHEN bl."ConceptType" IN ('ASIGNACION', 'BONO') THEN bl."Total" ELSE 0 END) AS "TotalGross",
            SUM(CASE WHEN bl."ConceptType" = 'DEDUCCION' THEN bl."Total" ELSE 0 END)              AS "TotalDeductions",
            SUM(CASE WHEN bl."ConceptType" IN ('ASIGNACION', 'BONO') THEN bl."Total" ELSE 0 END)
            - SUM(CASE WHEN bl."ConceptType" = 'DEDUCCION' THEN bl."Total" ELSE 0 END)            AS "TotalNet",
            MAX(CASE WHEN bl."IsModified" THEN 1 ELSE 0 END)                                      AS "HasModified",
            COUNT(*)                                                                                AS "ConceptCount"
        FROM hr."PayrollBatchLine" bl
        WHERE bl."BatchId" = p_batch_id
        GROUP BY bl."EmployeeCode", bl."EmployeeName", bl."EmployeeId"
    ), "Filtered" AS (
        SELECT es.*
        FROM "EmployeeSummary" es
        WHERE (p_search IS NULL
               OR es."EmployeeCode" ILIKE '%' || p_search || '%'
               OR es."EmployeeName" ILIKE '%' || p_search || '%')
          AND (NOT p_only_modified OR es."HasModified" = 1)
    )
    SELECT
        COUNT(*) OVER()       AS p_total_count,
        f."EmployeeCode",
        f."EmployeeName",
        f."EmployeeId",
        ''::TEXT              AS "DepartmentCode",
        ''::TEXT              AS "DepartmentName",
        ''::TEXT              AS "PositionName",
        f."TotalGross",
        f."TotalDeductions",
        f."TotalNet",
        f."HasModified",
        f."ConceptCount"
    FROM "Filtered" f
    ORDER BY f."EmployeeName"
    OFFSET p_offset
    LIMIT p_limit;
END;
$function$
;

-- usp_hr_payroll_getdraftsummary_alerts
CREATE OR REPLACE FUNCTION public.usp_hr_payroll_getdraftsummary_alerts(p_batch_id integer)
 RETURNS TABLE("AlertType" character varying, "EmployeeCode" character varying, "EmployeeName" character varying, "AlertMessage" character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        alerts."AlertType",
        alerts."EmployeeCode",
        alerts."EmployeeName",
        alerts."AlertMessage"
    FROM (
        -- Empleados sin asignaciones
        SELECT
            'SIN_ASIGNACIONES'::TEXT                               AS "AlertType",
            bl."EmployeeCode",
            bl."EmployeeName",
            'El empleado no tiene conceptos de asignación.'::TEXT  AS "AlertMessage"
        FROM hr."PayrollBatchLine" bl
        WHERE bl."BatchId" = p_batch_id
        GROUP BY bl."EmployeeCode", bl."EmployeeName"
        HAVING SUM(CASE WHEN bl."ConceptType" IN ('ASIGNACION', 'BONO') THEN 1 ELSE 0 END) = 0

        UNION ALL

        -- Empleados con neto negativo
        SELECT
            'NETO_NEGATIVO'::TEXT AS "AlertType",
            bl."EmployeeCode",
            bl."EmployeeName",
            ('El neto del empleado es negativo: ' ||
             (SUM(CASE WHEN bl."ConceptType" IN ('ASIGNACION', 'BONO') THEN bl."Total" ELSE 0 END)
            - SUM(CASE WHEN bl."ConceptType" = 'DEDUCCION' THEN bl."Total" ELSE 0 END))::TEXT
            )::TEXT AS "AlertMessage"
        FROM hr."PayrollBatchLine" bl
        WHERE bl."BatchId" = p_batch_id
        GROUP BY bl."EmployeeCode", bl."EmployeeName"
        HAVING (SUM(CASE WHEN bl."ConceptType" IN ('ASIGNACION', 'BONO') THEN bl."Total" ELSE 0 END)
              - SUM(CASE WHEN bl."ConceptType" = 'DEDUCCION' THEN bl."Total" ELSE 0 END)) < 0

        UNION ALL

        -- Líneas con monto cero
        SELECT
            'MONTO_CERO'::TEXT AS "AlertType",
            bl."EmployeeCode",
            bl."EmployeeName",
            ('Concepto ' || bl."ConceptCode" || ' tiene monto cero.')::TEXT AS "AlertMessage"
        FROM hr."PayrollBatchLine" bl
        WHERE bl."BatchId"     = p_batch_id
          AND bl."Total"       = 0
          AND bl."ConceptType" IN ('ASIGNACION', 'BONO')

    ) alerts
    ORDER BY alerts."AlertType", alerts."EmployeeCode";
END;
$function$
;

-- usp_hr_payroll_getdraftsummary_bydept
CREATE OR REPLACE FUNCTION public.usp_hr_payroll_getdraftsummary_bydept(p_batch_id integer)
 RETURNS TABLE("DepartmentCode" character varying, "DepartmentName" character varying, "EmployeeCount" bigint, "DeptGross" numeric, "DeptDeductions" numeric, "DeptNet" numeric)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        'GENERAL'::TEXT                                                          AS "DepartmentCode",
        'General'::TEXT                                                          AS "DepartmentName",
        COUNT(DISTINCT bl."EmployeeCode")                                        AS "EmployeeCount",
        COALESCE(SUM(CASE WHEN bl."ConceptType" IN ('ASIGNACION', 'BONO') THEN bl."Total" ELSE 0 END), 0) AS "DeptGross",
        COALESCE(SUM(CASE WHEN bl."ConceptType" = 'DEDUCCION' THEN bl."Total" ELSE 0 END), 0)             AS "DeptDeductions",
        COALESCE(SUM(CASE WHEN bl."ConceptType" IN ('ASIGNACION', 'BONO') THEN bl."Total" ELSE 0 END), 0)
        - COALESCE(SUM(CASE WHEN bl."ConceptType" = 'DEDUCCION' THEN bl."Total" ELSE 0 END), 0)           AS "DeptNet"
    FROM hr."PayrollBatchLine" bl
    WHERE bl."BatchId" = p_batch_id;
END;
$function$
;

-- usp_hr_payroll_getdraftsummary_header
CREATE OR REPLACE FUNCTION public.usp_hr_payroll_getdraftsummary_header(p_batch_id integer)
 RETURNS TABLE("BatchId" integer, "CompanyId" integer, "BranchId" integer, "PayrollCode" character varying, "FromDate" date, "ToDate" date, "Status" character varying, "TotalEmployees" integer, "TotalGross" numeric, "TotalDeductions" numeric, "TotalNet" numeric, "CreatedBy" integer, "CreatedAt" timestamp without time zone, "ApprovedBy" integer, "ApprovedAt" timestamp without time zone, "PrevBatchId" integer, "PrevTotalGross" numeric, "PrevTotalDeductions" numeric, "PrevTotalNet" numeric, "NetChangePercent" numeric)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        b."BatchId",
        b."CompanyId",
        b."BranchId",
        b."PayrollCode",
        b."FromDate",
        b."ToDate",
        b."Status",
        b."TotalEmployees",
        b."TotalGross",
        b."TotalDeductions",
        b."TotalNet",
        b."CreatedBy",
        b."CreatedAt",
        b."ApprovedBy",
        b."ApprovedAt",
        prev."PrevBatchId",
        prev."PrevTotalGross",
        prev."PrevTotalDeductions",
        prev."PrevTotalNet",
        CASE WHEN prev."PrevTotalNet" > 0
             THEN CAST(((b."TotalNet" - prev."PrevTotalNet") / prev."PrevTotalNet") * 100 AS NUMERIC(8,2))
             ELSE 0::NUMERIC(8,2)
        END AS "NetChangePercent"
    FROM hr."PayrollBatch" b
    LEFT JOIN LATERAL (
        SELECT
            pb."BatchId"          AS "PrevBatchId",
            pb."TotalGross"       AS "PrevTotalGross",
            pb."TotalDeductions"  AS "PrevTotalDeductions",
            pb."TotalNet"         AS "PrevTotalNet"
        FROM hr."PayrollBatch" pb
        WHERE pb."CompanyId"   = b."CompanyId"
          AND pb."BranchId"    = b."BranchId"
          AND pb."PayrollCode" = b."PayrollCode"
          AND pb."ToDate"      < b."FromDate"
          AND pb."Status"      IN ('PROCESADA', 'CERRADA')
        ORDER BY pb."ToDate" DESC
        LIMIT 1
    ) prev ON TRUE
    WHERE b."BatchId" = p_batch_id;
END;
$function$
;

-- usp_hr_payroll_getemployeelines
CREATE OR REPLACE FUNCTION public.usp_hr_payroll_getemployeelines(p_batch_id integer, p_employee_code character varying)
 RETURNS TABLE("LineId" integer, "BatchId" integer, "EmployeeId" bigint, "EmployeeCode" character varying, "EmployeeName" character varying, "ConceptCode" character varying, "ConceptName" character varying, "ConceptType" character varying, "Quantity" numeric, "Amount" numeric, "Total" numeric, "IsModified" boolean, "Notes" character varying, "UpdatedAt" timestamp without time zone)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        bl."LineId",
        bl."BatchId",
        bl."EmployeeId",
        bl."EmployeeCode",
        bl."EmployeeName",
        bl."ConceptCode",
        bl."ConceptName",
        bl."ConceptType",
        bl."Quantity",
        bl."Amount",
        bl."Total",
        bl."IsModified",
        bl."Notes",
        bl."UpdatedAt"
    FROM hr."PayrollBatchLine" bl
    WHERE bl."BatchId"      = p_batch_id
      AND bl."EmployeeCode" = p_employee_code
    ORDER BY
        CASE bl."ConceptType"
            WHEN 'ASIGNACION' THEN 1
            WHEN 'BONO'       THEN 2
            WHEN 'DEDUCCION'  THEN 3
        END,
        bl."ConceptCode";
END;
$function$
;

-- usp_hr_payroll_getrunheader
CREATE OR REPLACE FUNCTION public.usp_hr_payroll_getrunheader(p_company_id integer, p_payroll_code character varying, p_employee_code character varying)
 RETURNS TABLE("runId" bigint, nomina character varying, cedula character varying, "nombreEmpleado" character varying, cargo character varying, "fechaProceso" date, "fechaInicio" date, "fechaHasta" date, "totalAsignaciones" numeric, "totalDeducciones" numeric, "totalNeto" numeric, cerrada boolean, "tipoNomina" character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        pr."PayrollRunId", pr."PayrollCode", pr."EmployeeCode",
        pr."EmployeeName", pr."PositionName", pr."ProcessDate",
        pr."DateFrom", pr."DateTo",
        pr."TotalAssignments", pr."TotalDeductions", pr."NetTotal",
        pr."IsClosed", pr."PayrollTypeName"
    FROM hr."PayrollRun" pr
    WHERE pr."CompanyId"    = p_company_id
      AND pr."PayrollCode"  = p_payroll_code
      AND pr."EmployeeCode" = p_employee_code
    ORDER BY pr."ProcessDate" DESC, pr."PayrollRunId" DESC
    LIMIT 1;
END;
$function$
;

-- usp_hr_payroll_getrunlines
CREATE OR REPLACE FUNCTION public.usp_hr_payroll_getrunlines(p_run_id bigint)
 RETURNS TABLE("coConcepto" character varying, "nombreConcepto" character varying, "tipoConcepto" character varying, cantidad numeric, monto numeric, total numeric, descripcion character varying, "cuentaContable" character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        rl."ConceptCode", rl."ConceptName", rl."ConceptType",
        rl."Quantity", rl."Amount", rl."Total",
        rl."DescriptionText", rl."AccountingAccountCode"
    FROM hr."PayrollRunLine" rl
    WHERE rl."PayrollRunId" = p_run_id
    ORDER BY rl."PayrollRunLineId";
END;
$function$
;

-- usp_hr_payroll_getsettlementheader
CREATE OR REPLACE FUNCTION public.usp_hr_payroll_getsettlementheader(p_company_id integer, p_settlement_code character varying)
 RETURNS TABLE(id bigint, total numeric)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT sp."SettlementProcessId", sp."TotalAmount"
    FROM hr."SettlementProcess" sp
    WHERE sp."CompanyId" = p_company_id AND sp."SettlementCode" = p_settlement_code
    LIMIT 1;
END;
$function$
;

-- usp_hr_payroll_getsettlementlines
CREATE OR REPLACE FUNCTION public.usp_hr_payroll_getsettlementlines(p_settlement_process_id bigint)
 RETURNS TABLE(codigo character varying, nombre character varying, monto numeric)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT sl."ConceptCode", sl."ConceptName", sl."Amount"
    FROM hr."SettlementProcessLine" sl
    WHERE sl."SettlementProcessId" = p_settlement_process_id
    ORDER BY sl."SettlementProcessLineId";
END;
$function$
;

-- usp_hr_payroll_getvacationheader
CREATE OR REPLACE FUNCTION public.usp_hr_payroll_getvacationheader(p_company_id integer, p_vacation_code character varying)
 RETURNS TABLE(id bigint, vacacion character varying, cedula character varying, "nombreEmpleado" character varying, inicio date, hasta date, reintegro date, "fechaCalculo" date, total numeric, "totalCalculado" numeric)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        vp."VacationProcessId", vp."VacationCode", vp."EmployeeCode",
        vp."EmployeeName", vp."StartDate", vp."EndDate",
        vp."ReintegrationDate", vp."ProcessDate",
        vp."TotalAmount", vp."CalculatedAmount"
    FROM hr."VacationProcess" vp
    WHERE vp."CompanyId" = p_company_id AND vp."VacationCode" = p_vacation_code
    LIMIT 1;
END;
$function$
;

-- usp_hr_payroll_getvacationlines
CREATE OR REPLACE FUNCTION public.usp_hr_payroll_getvacationlines(p_vacation_process_id bigint)
 RETURNS TABLE(codigo character varying, nombre character varying, monto numeric)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT vl."ConceptCode", vl."ConceptName", vl."Amount"
    FROM hr."VacationProcessLine" vl
    WHERE vl."VacationProcessId" = p_vacation_process_id
    ORDER BY vl."VacationProcessLineId";
END;
$function$
;

-- usp_hr_payroll_listactiveemployees
CREATE OR REPLACE FUNCTION public.usp_hr_payroll_listactiveemployees(p_company_id integer, p_solo_activos boolean DEFAULT true)
 RETURNS TABLE("employeeCode" character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT e."EmployeeCode"
    FROM master."Employee" e
    WHERE e."CompanyId" = p_company_id
      AND e."IsDeleted" = FALSE
      AND (NOT p_solo_activos OR e."IsActive" = TRUE)
    ORDER BY e."EmployeeCode";
END;
$function$
;

-- usp_hr_payroll_listbatches
CREATE OR REPLACE FUNCTION public.usp_hr_payroll_listbatches(p_company_id integer, p_payroll_code character varying DEFAULT NULL::character varying, p_status character varying DEFAULT NULL::character varying, p_offset integer DEFAULT 0, p_limit integer DEFAULT 25)
 RETURNS TABLE(p_total_count bigint, "BatchId" integer, "CompanyId" integer, "BranchId" integer, "PayrollCode" character varying, "FromDate" date, "ToDate" date, "Status" character varying, "TotalEmployees" integer, "TotalGross" numeric, "TotalDeductions" numeric, "TotalNet" numeric, "CreatedBy" integer, "CreatedAt" timestamp without time zone, "ApprovedBy" integer, "ApprovedAt" timestamp without time zone, "UpdatedAt" timestamp without time zone)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        COUNT(*) OVER()  AS p_total_count,
        b."BatchId",
        b."CompanyId",
        b."BranchId",
        b."PayrollCode",
        b."FromDate",
        b."ToDate",
        b."Status",
        b."TotalEmployees",
        b."TotalGross",
        b."TotalDeductions",
        b."TotalNet",
        b."CreatedBy",
        b."CreatedAt",
        b."ApprovedBy",
        b."ApprovedAt",
        b."UpdatedAt"
    FROM hr."PayrollBatch" b
    WHERE b."CompanyId" = p_company_id
      AND (p_payroll_code IS NULL OR b."PayrollCode" = p_payroll_code)
      AND (p_status       IS NULL OR b."Status"      = p_status)
    ORDER BY b."CreatedAt" DESC
    OFFSET p_offset
    LIMIT p_limit;
END;
$function$
;

-- usp_hr_payroll_listconcepts
CREATE OR REPLACE FUNCTION public.usp_hr_payroll_listconcepts(p_company_id integer, p_payroll_code character varying DEFAULT NULL::character varying, p_concept_type character varying DEFAULT NULL::character varying, p_search character varying DEFAULT NULL::character varying, p_offset integer DEFAULT 0, p_limit integer DEFAULT 50)
 RETURNS TABLE("TotalCount" bigint, codigo character varying, "codigoNomina" character varying, nombre character varying, formula character varying, sobre character varying, clase character varying, tipo character varying, uso character varying, bonificable character varying, "esAntiguedad" character varying, "cuentaContable" character varying, aplica character varying, "valorDefecto" numeric)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_total BIGINT;
    v_search_pat VARCHAR(202) := CASE WHEN p_search IS NOT NULL THEN '%' || p_search || '%' ELSE NULL END;
BEGIN
    SELECT COUNT(1) INTO v_total
    FROM hr."PayrollConcept"
    WHERE "CompanyId" = p_company_id
      AND "IsActive" = TRUE
      AND (p_payroll_code IS NULL OR "PayrollCode" = p_payroll_code)
      AND (p_concept_type IS NULL OR "ConceptType" = p_concept_type)
      AND (v_search_pat IS NULL OR ("ConceptCode" ILIKE v_search_pat OR "ConceptName" ILIKE v_search_pat));

    RETURN QUERY
    SELECT
        v_total,
        pc."ConceptCode", pc."PayrollCode", pc."ConceptName",
        pc."Formula", pc."BaseExpression", pc."ConceptClass",
        pc."ConceptType", pc."UsageType",
        CASE WHEN pc."IsBonifiable" THEN 'S' ELSE 'N' END,
        CASE WHEN pc."IsSeniority" THEN 'S' ELSE 'N' END,
        pc."AccountingAccountCode",
        CASE WHEN pc."AppliesFlag" THEN 'S' ELSE 'N' END,
        pc."DefaultValue"
    FROM hr."PayrollConcept" pc
    WHERE pc."CompanyId" = p_company_id
      AND pc."IsActive" = TRUE
      AND (p_payroll_code IS NULL OR pc."PayrollCode" = p_payroll_code)
      AND (p_concept_type IS NULL OR pc."ConceptType" = p_concept_type)
      AND (v_search_pat IS NULL OR (pc."ConceptCode" ILIKE v_search_pat OR pc."ConceptName" ILIKE v_search_pat))
    ORDER BY pc."PayrollCode", pc."SortOrder", pc."ConceptCode"
    LIMIT p_limit OFFSET p_offset;
END;
$function$
;

-- usp_hr_payroll_listconstants
CREATE OR REPLACE FUNCTION public.usp_hr_payroll_listconstants(p_company_id integer, p_offset integer DEFAULT 0, p_limit integer DEFAULT 50)
 RETURNS TABLE("TotalCount" bigint, codigo character varying, nombre character varying, valor numeric, origen character varying, activo boolean)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_total BIGINT;
BEGIN
    SELECT COUNT(1) INTO v_total
    FROM hr."PayrollConstant"
    WHERE "CompanyId" = p_company_id;

    RETURN QUERY
    SELECT
        v_total,
        pc."ConstantCode", pc."ConstantName", pc."ConstantValue",
        pc."SourceName", pc."IsActive"
    FROM hr."PayrollConstant" pc
    WHERE pc."CompanyId" = p_company_id
    ORDER BY pc."ConstantCode"
    LIMIT p_limit OFFSET p_offset;
END;
$function$
;

-- usp_hr_payroll_listruns
CREATE OR REPLACE FUNCTION public.usp_hr_payroll_listruns(p_company_id integer, p_payroll_code character varying DEFAULT NULL::character varying, p_employee_code character varying DEFAULT NULL::character varying, p_from_date date DEFAULT NULL::date, p_to_date date DEFAULT NULL::date, p_solo_abiertas boolean DEFAULT false, p_offset integer DEFAULT 0, p_limit integer DEFAULT 50)
 RETURNS TABLE("TotalCount" bigint, nomina character varying, cedula character varying, "nombreEmpleado" character varying, cargo character varying, "fechaProceso" date, "fechaInicio" date, "fechaHasta" date, "totalAsignaciones" numeric, "totalDeducciones" numeric, "totalNeto" numeric, cerrada boolean, "tipoNomina" character varying)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_total BIGINT;
BEGIN
    SELECT COUNT(1) INTO v_total
    FROM hr."PayrollRun"
    WHERE "CompanyId" = p_company_id
      AND (p_payroll_code IS NULL OR "PayrollCode" = p_payroll_code)
      AND (p_employee_code IS NULL OR "EmployeeCode" = p_employee_code)
      AND (p_from_date IS NULL OR "DateFrom" >= p_from_date)
      AND (p_to_date IS NULL OR "DateTo" <= p_to_date)
      AND (NOT p_solo_abiertas OR "IsClosed" = FALSE);

    RETURN QUERY
    SELECT
        v_total,
        pr."PayrollCode", pr."EmployeeCode", pr."EmployeeName",
        pr."PositionName", pr."ProcessDate", pr."DateFrom", pr."DateTo",
        pr."TotalAssignments", pr."TotalDeductions", pr."NetTotal",
        pr."IsClosed", pr."PayrollTypeName"
    FROM hr."PayrollRun" pr
    WHERE pr."CompanyId" = p_company_id
      AND (p_payroll_code IS NULL OR pr."PayrollCode" = p_payroll_code)
      AND (p_employee_code IS NULL OR pr."EmployeeCode" = p_employee_code)
      AND (p_from_date IS NULL OR pr."DateFrom" >= p_from_date)
      AND (p_to_date IS NULL OR pr."DateTo" <= p_to_date)
      AND (NOT p_solo_abiertas OR pr."IsClosed" = FALSE)
    ORDER BY pr."ProcessDate" DESC, pr."PayrollRunId" DESC
    LIMIT p_limit OFFSET p_offset;
END;
$function$
;

-- usp_hr_payroll_listsettlements
CREATE OR REPLACE FUNCTION public.usp_hr_payroll_listsettlements(p_company_id integer, p_employee_code character varying DEFAULT NULL::character varying, p_offset integer DEFAULT 0, p_limit integer DEFAULT 50)
 RETURNS TABLE("TotalCount" bigint, liquidacion character varying, cedula character varying, "nombreEmpleado" character varying, "fechaRetiro" date, "causaRetiro" character varying, total numeric)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_total BIGINT;
BEGIN
    SELECT COUNT(1) INTO v_total
    FROM hr."SettlementProcess"
    WHERE "CompanyId" = p_company_id
      AND (p_employee_code IS NULL OR "EmployeeCode" = p_employee_code);

    RETURN QUERY
    SELECT
        v_total,
        sp."SettlementCode", sp."EmployeeCode", sp."EmployeeName",
        sp."RetirementDate", sp."RetirementCause", sp."TotalAmount"
    FROM hr."SettlementProcess" sp
    WHERE sp."CompanyId" = p_company_id
      AND (p_employee_code IS NULL OR sp."EmployeeCode" = p_employee_code)
    ORDER BY sp."SettlementProcessId" DESC
    LIMIT p_limit OFFSET p_offset;
END;
$function$
;

-- usp_hr_payroll_listvacations
CREATE OR REPLACE FUNCTION public.usp_hr_payroll_listvacations(p_company_id integer, p_employee_code character varying DEFAULT NULL::character varying, p_offset integer DEFAULT 0, p_limit integer DEFAULT 50)
 RETURNS TABLE("TotalCount" bigint, vacacion character varying, cedula character varying, "nombreEmpleado" character varying, inicio date, hasta date, reintegro date, "fechaCalculo" date, total numeric, "totalCalculado" numeric)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_total BIGINT;
BEGIN
    SELECT COUNT(1) INTO v_total
    FROM hr."VacationProcess"
    WHERE "CompanyId" = p_company_id
      AND (p_employee_code IS NULL OR "EmployeeCode" = p_employee_code);

    RETURN QUERY
    SELECT
        v_total,
        vp."VacationCode", vp."EmployeeCode", vp."EmployeeName",
        vp."StartDate", vp."EndDate", vp."ReintegrationDate",
        vp."ProcessDate", vp."TotalAmount", vp."CalculatedAmount"
    FROM hr."VacationProcess" vp
    WHERE vp."CompanyId" = p_company_id
      AND (p_employee_code IS NULL OR vp."EmployeeCode" = p_employee_code)
    ORDER BY vp."VacationProcessId" DESC
    LIMIT p_limit OFFSET p_offset;
END;
$function$
;

-- usp_hr_payroll_loadconceptsforrun
CREATE OR REPLACE FUNCTION public.usp_hr_payroll_loadconceptsforrun(p_company_id integer, p_payroll_code character varying, p_concept_type character varying DEFAULT NULL::character varying, p_convention_code character varying DEFAULT NULL::character varying, p_calculation_type character varying DEFAULT NULL::character varying, p_solo_legales boolean DEFAULT false)
 RETURNS TABLE("conceptCode" character varying, "conceptName" character varying, "conceptType" character varying, "defaultValue" numeric, formula character varying, "accountingAccountCode" character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        pc."ConceptCode", pc."ConceptName", pc."ConceptType",
        pc."DefaultValue", pc."Formula", pc."AccountingAccountCode"
    FROM hr."PayrollConcept" pc
    WHERE pc."CompanyId"   = p_company_id
      AND pc."PayrollCode" = p_payroll_code
      AND pc."IsActive"    = TRUE
      AND pc."AppliesFlag" = TRUE
      AND (p_concept_type IS NULL OR pc."ConceptType" = p_concept_type)
      AND (
            (p_solo_legales AND (
                (p_convention_code IS NOT NULL AND pc."ConventionCode" = p_convention_code)
                OR
                (p_convention_code IS NULL AND pc."ConventionCode" IS NOT NULL)
            ))
            OR
            (NOT p_solo_legales AND (
                (p_convention_code IS NOT NULL AND (pc."ConventionCode" = p_convention_code OR pc."ConventionCode" IS NULL))
                OR
                (p_convention_code IS NULL)
            ))
          )
      AND (p_calculation_type IS NULL OR pc."CalculationType" = p_calculation_type OR pc."CalculationType" IS NULL)
    ORDER BY pc."SortOrder", pc."ConceptCode";
END;
$function$
;

-- usp_hr_payroll_processbatch
CREATE OR REPLACE FUNCTION public.usp_hr_payroll_processbatch(p_batch_id integer, p_user_id integer, OUT p_procesados integer, OUT p_errores integer, OUT p_resultado integer, OUT p_mensaje text)
 RETURNS record
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_company_id   INTEGER;
    v_branch_id    INTEGER;
    v_payroll_code VARCHAR(15);
    v_from_date    DATE;
    v_to_date      DATE;
    v_status       VARCHAR(20);

    v_emp_code   VARCHAR(24);
    v_emp_name   VARCHAR(200);
    v_emp_id     BIGINT;
    v_emp_gross  NUMERIC(18,2);
    v_emp_deduct NUMERIC(18,2);
    v_emp_net    NUMERIC(18,2);

    v_run_res    INTEGER;
    v_run_msg    TEXT;
    v_lines_json TEXT;

    emp_rec RECORD;
BEGIN
    p_procesados := 0;
    p_errores    := 0;
    p_resultado  := 0;
    p_mensaje    := '';

    -- Validar estado
    SELECT "CompanyId", "BranchId", "PayrollCode", "FromDate", "ToDate", "Status"
    INTO v_company_id, v_branch_id, v_payroll_code, v_from_date, v_to_date, v_status
    FROM hr."PayrollBatch"
    WHERE "BatchId" = p_batch_id;

    IF v_status IS NULL THEN
        p_resultado := -1;
        p_mensaje   := 'Lote no encontrado.';
        RETURN;
    END IF;

    IF v_status <> 'APROBADA' THEN
        p_resultado := -2;
        p_mensaje   := 'Solo se pueden procesar lotes en estado APROBADA. Estado actual: ' || v_status;
        RETURN;
    END IF;

    BEGIN
        -- Iterar empleados en el lote (equivalente al cursor T-SQL)
        FOR emp_rec IN
            SELECT
                "EmployeeCode",
                MAX("EmployeeName")                                                                                           AS "EmployeeName",
                MAX("EmployeeId")                                                                                             AS "EmployeeId",
                COALESCE(SUM(CASE WHEN "ConceptType" IN ('ASIGNACION', 'BONO') THEN "Total" ELSE 0 END), 0)                  AS "EmpGross",
                COALESCE(SUM(CASE WHEN "ConceptType" = 'DEDUCCION' THEN "Total" ELSE 0 END), 0)                              AS "EmpDeduct",
                COALESCE(SUM(CASE WHEN "ConceptType" IN ('ASIGNACION', 'BONO') THEN "Total" ELSE 0 END), 0)
                - COALESCE(SUM(CASE WHEN "ConceptType" = 'DEDUCCION' THEN "Total" ELSE 0 END), 0)                            AS "EmpNet"
            FROM hr."PayrollBatchLine"
            WHERE "BatchId" = p_batch_id
            GROUP BY "EmployeeCode"
        LOOP
            -- Construir JSON de líneas para este empleado
            SELECT json_agg(
                json_build_object(
                    'code',        "ConceptCode",
                    'name',        "ConceptName",
                    'type',        "ConceptType",
                    'qty',         "Quantity",
                    'amount',      "Amount",
                    'total',       "Total",
                    'description', COALESCE("Notes", '')
                )
            )::TEXT
            INTO v_lines_json
            FROM hr."PayrollBatchLine"
            WHERE "BatchId"      = p_batch_id
              AND "EmployeeCode" = emp_rec."EmployeeCode";

            BEGIN
                SELECT r.p_resultado, r.p_mensaje
                INTO v_run_res, v_run_msg
                FROM public.usp_HR_Payroll_UpsertRun(
                    p_company_id        => v_company_id,
                    p_branch_id         => v_branch_id,
                    p_payroll_code      => v_payroll_code,
                    p_employee_id       => emp_rec."EmployeeId",
                    p_employee_code     => emp_rec."EmployeeCode",
                    p_employee_name     => emp_rec."EmployeeName",
                    p_from_date         => v_from_date,
                    p_to_date           => v_to_date,
                    p_total_assignments => emp_rec."EmpGross",
                    p_total_deductions  => emp_rec."EmpDeduct",
                    p_net_total         => emp_rec."EmpNet",
                    p_payroll_type_name => NULL,
                    p_user_id           => p_user_id,
                    p_lines_json        => v_lines_json
                ) r;

                IF v_run_res > 0 THEN
                    p_procesados := p_procesados + 1;
                ELSE
                    p_errores := p_errores + 1;
                END IF;

            EXCEPTION WHEN OTHERS THEN
                p_errores := p_errores + 1;
            END;
        END LOOP;

        -- Actualizar estado del batch
        UPDATE hr."PayrollBatch"
        SET "Status"    = 'PROCESADA',
            "UpdatedAt" = (NOW() AT TIME ZONE 'UTC')
        WHERE "BatchId" = p_batch_id;

        p_resultado := 1;
        p_mensaje   := 'Lote procesado: ' || p_procesados::TEXT || ' empleados procesados, '
                     || p_errores::TEXT || ' errores.';

    EXCEPTION WHEN OTHERS THEN
        p_resultado := -99;
        p_mensaje   := 'Error: ' || SQLERRM;
    END;
END;
$function$
;

-- usp_hr_payroll_resolvescope
CREATE OR REPLACE FUNCTION public.usp_hr_payroll_resolvescope()
 RETURNS TABLE("companyId" integer, "branchId" integer, "systemUserId" integer)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        c."CompanyId",
        b."BranchId",
        su."UserId"
    FROM cfg."Company" c
    INNER JOIN cfg."Branch" b
        ON b."CompanyId" = c."CompanyId"
       AND b."BranchCode" = 'MAIN'
    LEFT JOIN sec."User" su
        ON su."UserCode" = 'SYSTEM'
    WHERE c."CompanyCode" = 'DEFAULT'
    ORDER BY c."CompanyId", b."BranchId"
    LIMIT 1;
END;
$function$
;

-- usp_hr_payroll_resolveuser
CREATE OR REPLACE FUNCTION public.usp_hr_payroll_resolveuser(p_user_code character varying DEFAULT NULL::character varying)
 RETURNS TABLE("userId" integer)
 LANGUAGE plpgsql
AS $function$
BEGIN
    IF p_user_code IS NOT NULL AND TRIM(p_user_code) <> '' THEN
        RETURN QUERY
        SELECT u."UserId"
        FROM sec."User" u
        WHERE UPPER(u."UserCode")::character varying = UPPER(p_user_code)::character varying
        ORDER BY u."UserId"
        LIMIT 1;
        RETURN;
    END IF;

    RETURN QUERY
    SELECT u."UserId"
    FROM sec."User" u
    WHERE u."UserCode" = 'SYSTEM'
    ORDER BY u."UserId"
    LIMIT 1;
END;
$function$
;

-- usp_hr_payroll_saveconcept
CREATE OR REPLACE FUNCTION public.usp_hr_payroll_saveconcept(p_company_id integer, p_payroll_code character varying, p_concept_code character varying, p_concept_name character varying, p_formula character varying DEFAULT NULL::character varying, p_base_expression character varying DEFAULT NULL::character varying, p_concept_class character varying DEFAULT NULL::character varying, p_concept_type character varying DEFAULT 'ASIGNACION'::character varying, p_usage_type character varying DEFAULT NULL::character varying, p_is_bonifiable boolean DEFAULT false, p_is_seniority boolean DEFAULT false, p_accounting_account_code character varying DEFAULT NULL::character varying, p_applies_flag boolean DEFAULT true, p_default_value numeric DEFAULT 0, p_user_id integer DEFAULT NULL::integer)
 RETURNS TABLE("Resultado" integer, "Mensaje" character varying)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_existing_id BIGINT;
BEGIN
    SELECT "PayrollConceptId" INTO v_existing_id
    FROM hr."PayrollConcept"
    WHERE "CompanyId" = p_company_id
      AND "PayrollCode" = p_payroll_code
      AND "ConceptCode" = p_concept_code
      AND "ConventionCode" IS NULL
      AND "CalculationType" IS NULL
    ORDER BY "PayrollConceptId"
    LIMIT 1;

    IF v_existing_id IS NOT NULL THEN
        UPDATE hr."PayrollConcept"
        SET "ConceptName"           = p_concept_name,
            "Formula"               = p_formula,
            "BaseExpression"        = p_base_expression,
            "ConceptClass"          = p_concept_class,
            "ConceptType"           = p_concept_type,
            "UsageType"             = p_usage_type,
            "IsBonifiable"          = p_is_bonifiable,
            "IsSeniority"           = p_is_seniority,
            "AccountingAccountCode" = p_accounting_account_code,
            "AppliesFlag"           = p_applies_flag,
            "DefaultValue"          = p_default_value,
            "UpdatedAt"             = NOW() AT TIME ZONE 'UTC',
            "UpdatedByUserId"       = p_user_id
        WHERE "PayrollConceptId" = v_existing_id;
    ELSE
        INSERT INTO hr."PayrollConcept" (
            "CompanyId", "PayrollCode", "ConceptCode", "ConceptName",
            "Formula", "BaseExpression", "ConceptClass", "ConceptType",
            "UsageType", "IsBonifiable", "IsSeniority", "AccountingAccountCode",
            "AppliesFlag", "DefaultValue", "ConventionCode", "CalculationType",
            "SortOrder", "IsActive", "CreatedByUserId", "UpdatedByUserId"
        )
        VALUES (
            p_company_id, p_payroll_code, p_concept_code, p_concept_name,
            p_formula, p_base_expression, p_concept_class, p_concept_type,
            p_usage_type, p_is_bonifiable, p_is_seniority, p_accounting_account_code,
            p_applies_flag, p_default_value, NULL, NULL,
            0, TRUE, p_user_id, p_user_id
        );
    END IF;

    RETURN QUERY SELECT 1, 'Concepto guardado'::TEXT;
END;
$function$
;

-- usp_hr_payroll_saveconstant
CREATE OR REPLACE FUNCTION public.usp_hr_payroll_saveconstant(p_company_id integer, p_code character varying, p_name character varying DEFAULT NULL::character varying, p_value numeric DEFAULT NULL::numeric, p_source_name character varying DEFAULT NULL::character varying, p_user_id integer DEFAULT NULL::integer)
 RETURNS TABLE("Resultado" integer, "Mensaje" character varying)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_existing_id BIGINT;
BEGIN
    SELECT "PayrollConstantId" INTO v_existing_id
    FROM hr."PayrollConstant"
    WHERE "CompanyId" = p_company_id AND "ConstantCode" = p_code
    LIMIT 1;

    IF v_existing_id IS NOT NULL THEN
        UPDATE hr."PayrollConstant"
        SET "ConstantName"  = COALESCE(p_name, "ConstantName"),
            "ConstantValue" = COALESCE(p_value, "ConstantValue"),
            "SourceName"    = COALESCE(p_source_name, "SourceName"),
            "UpdatedAt"     = NOW() AT TIME ZONE 'UTC',
            "UpdatedByUserId" = p_user_id
        WHERE "PayrollConstantId" = v_existing_id;
    ELSE
        INSERT INTO hr."PayrollConstant" (
            "CompanyId", "ConstantCode", "ConstantName", "ConstantValue",
            "SourceName", "IsActive", "CreatedByUserId", "UpdatedByUserId"
        )
        VALUES (
            p_company_id, p_code, COALESCE(p_name, p_code), COALESCE(p_value, 0),
            p_source_name, TRUE, p_user_id, p_user_id
        );
    END IF;

    RETURN QUERY SELECT 1, 'Constante guardada'::TEXT;
END;
$function$
;

-- usp_hr_payroll_savedraftline
CREATE OR REPLACE FUNCTION public.usp_hr_payroll_savedraftline(p_line_id integer, p_quantity numeric, p_amount numeric, p_user_id integer, p_notes character varying DEFAULT NULL::character varying, OUT p_resultado integer, OUT p_mensaje text)
 RETURNS record
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_batch_id INTEGER;
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    -- Validar que la línea existe y pertenece a un batch en BORRADOR
    SELECT bl."BatchId"
    INTO v_batch_id
    FROM hr."PayrollBatchLine" bl
    INNER JOIN hr."PayrollBatch" b ON b."BatchId" = bl."BatchId"
    WHERE bl."LineId" = p_line_id
      AND b."Status"  = 'BORRADOR';

    IF v_batch_id IS NULL THEN
        p_resultado := -1;
        p_mensaje   := 'Línea no encontrada o el lote no está en estado BORRADOR.';
        RETURN;
    END IF;

    BEGIN
        UPDATE hr."PayrollBatchLine"
        SET "Quantity"   = p_quantity,
            "Amount"     = p_amount,
            "Total"      = p_quantity * p_amount,
            "IsModified" = TRUE,
            "Notes"      = p_notes,
            "UpdatedAt"  = (NOW() AT TIME ZONE 'UTC')
        WHERE "LineId" = p_line_id;

        -- Recalcular totales del batch
        UPDATE hr."PayrollBatch"
        SET "TotalGross"     = COALESCE((SELECT SUM("Total") FROM hr."PayrollBatchLine" WHERE "BatchId" = v_batch_id AND "ConceptType" IN ('ASIGNACION', 'BONO')), 0),
            "TotalDeductions"= COALESCE((SELECT SUM("Total") FROM hr."PayrollBatchLine" WHERE "BatchId" = v_batch_id AND "ConceptType" = 'DEDUCCION'), 0),
            "TotalNet"       = COALESCE((SELECT SUM("Total") FROM hr."PayrollBatchLine" WHERE "BatchId" = v_batch_id AND "ConceptType" IN ('ASIGNACION', 'BONO')), 0)
                             - COALESCE((SELECT SUM("Total") FROM hr."PayrollBatchLine" WHERE "BatchId" = v_batch_id AND "ConceptType" = 'DEDUCCION'), 0),
            "UpdatedAt"      = (NOW() AT TIME ZONE 'UTC')
        WHERE "BatchId" = v_batch_id;

        p_resultado := 1;
        p_mensaje   := 'Línea actualizada correctamente.';

    EXCEPTION WHEN OTHERS THEN
        p_resultado := -99;
        p_mensaje   := 'Error: ' || SQLERRM;
    END;
END;
$function$
;

-- usp_hr_payroll_upsertrun
CREATE OR REPLACE FUNCTION public.usp_hr_payroll_upsertrun(p_company_id integer, p_branch_id integer, p_payroll_code character varying, p_employee_id bigint, p_employee_code character varying, p_employee_name character varying, p_from_date date, p_to_date date, p_total_assignments numeric, p_total_deductions numeric, p_net_total numeric, p_payroll_type_name character varying DEFAULT NULL::character varying, p_user_id integer DEFAULT NULL::integer, p_lines_json text DEFAULT NULL::text)
 RETURNS TABLE("Resultado" integer, "Mensaje" character varying)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_run_id BIGINT;
BEGIN
    -- Buscar run existente
    SELECT "PayrollRunId" INTO v_run_id
    FROM hr."PayrollRun"
    WHERE "CompanyId"    = p_company_id
      AND "BranchId"     = p_branch_id
      AND "PayrollCode"  = p_payroll_code
      AND "EmployeeCode" = p_employee_code
      AND "DateFrom"     = p_from_date
      AND "DateTo"       = p_to_date
      AND "RunSource"    = 'MANUAL'
    ORDER BY "PayrollRunId" DESC
    LIMIT 1;

    IF v_run_id IS NOT NULL THEN
        UPDATE hr."PayrollRun"
        SET "ProcessDate"      = (NOW() AT TIME ZONE 'UTC')::DATE,
            "TotalAssignments" = p_total_assignments,
            "TotalDeductions"  = p_total_deductions,
            "NetTotal"         = p_net_total,
            "PayrollTypeName"  = COALESCE(p_payroll_type_name, "PayrollTypeName"),
            "UpdatedAt"        = NOW() AT TIME ZONE 'UTC',
            "UpdatedByUserId"  = p_user_id
        WHERE "PayrollRunId" = v_run_id;

        DELETE FROM hr."PayrollRunLine" WHERE "PayrollRunId" = v_run_id;
    ELSE
        INSERT INTO hr."PayrollRun" (
            "CompanyId", "BranchId", "PayrollCode", "EmployeeId", "EmployeeCode",
            "EmployeeName", "PositionName", "ProcessDate", "DateFrom", "DateTo",
            "TotalAssignments", "TotalDeductions", "NetTotal", "PayrollTypeName",
            "RunSource", "CreatedByUserId", "UpdatedByUserId"
        )
        VALUES (
            p_company_id, p_branch_id, p_payroll_code, p_employee_id, p_employee_code,
            p_employee_name, NULL, (NOW() AT TIME ZONE 'UTC')::DATE, p_from_date, p_to_date,
            p_total_assignments, p_total_deductions, p_net_total, p_payroll_type_name,
            'MANUAL', p_user_id, p_user_id
        )
        RETURNING "PayrollRunId" INTO v_run_id;
    END IF;

    -- Insertar lineas desde JSON
    IF p_lines_json IS NOT NULL AND LENGTH(p_lines_json) > 2 THEN
        INSERT INTO hr."PayrollRunLine" (
            "PayrollRunId", "ConceptCode", "ConceptName", "ConceptType",
            "Quantity", "Amount", "Total", "DescriptionText", "AccountingAccountCode"
        )
        SELECT
            v_run_id,
            elem->>'code',
            elem->>'name',
            elem->>'type',
            (elem->>'quantity')::NUMERIC(18,4),
            (elem->>'amount')::NUMERIC(18,4),
            (elem->>'total')::NUMERIC(18,2),
            elem->>'description',
            elem->>'account'
        FROM jsonb_array_elements(p_lines_json::JSONB) AS elem;
    END IF;

    RETURN QUERY SELECT 1, 'ok'::TEXT;

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, ('Error en upsert run: ' || SQLERRM)::TEXT;
END;
$function$
;

-- usp_hr_payroll_upsertrun
CREATE OR REPLACE FUNCTION public.usp_hr_payroll_upsertrun(p_company_id integer, p_branch_id integer, p_payroll_code character varying, p_employee_id bigint, p_employee_code character varying, p_employee_name character varying, p_from_date date, p_to_date date, p_total_assignments numeric, p_total_deductions numeric, p_net_total numeric, p_payroll_type_name character varying DEFAULT NULL::character varying, p_user_id integer DEFAULT NULL::integer, p_lines_json jsonb DEFAULT NULL::jsonb)
 RETURNS TABLE("Resultado" integer, "Mensaje" character varying)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_run_id BIGINT;
BEGIN
    -- Buscar run existente
    SELECT pr."PayrollRunId" INTO v_run_id
    FROM hr."PayrollRun" pr
    WHERE pr."CompanyId"    = p_company_id
      AND pr."BranchId"     = p_branch_id
      AND pr."PayrollCode"  = p_payroll_code
      AND pr."EmployeeCode" = p_employee_code
      AND pr."DateFrom"     = p_from_date
      AND pr."DateTo"       = p_to_date
      AND pr."RunSource"    = 'MANUAL'
    ORDER BY pr."PayrollRunId" DESC
    LIMIT 1;

    IF v_run_id IS NOT NULL THEN
        UPDATE hr."PayrollRun"
        SET "ProcessDate"      = (NOW() AT TIME ZONE 'UTC')::DATE,
            "TotalAssignments" = p_total_assignments,
            "TotalDeductions"  = p_total_deductions,
            "NetTotal"         = p_net_total,
            "PayrollTypeName"  = COALESCE(p_payroll_type_name, "PayrollTypeName"),
            "UpdatedAt"        = NOW() AT TIME ZONE 'UTC',
            "UpdatedByUserId"  = p_user_id
        WHERE "PayrollRunId" = v_run_id;

        DELETE FROM hr."PayrollRunLine" WHERE "PayrollRunId" = v_run_id;
    ELSE
        INSERT INTO hr."PayrollRun" (
            "CompanyId", "BranchId", "PayrollCode", "EmployeeId", "EmployeeCode",
            "EmployeeName", "PositionName", "ProcessDate", "DateFrom", "DateTo",
            "TotalAssignments", "TotalDeductions", "NetTotal", "PayrollTypeName",
            "RunSource", "CreatedByUserId", "UpdatedByUserId"
        )
        VALUES (
            p_company_id, p_branch_id, p_payroll_code, p_employee_id, p_employee_code,
            p_employee_name, NULL, (NOW() AT TIME ZONE 'UTC')::DATE, p_from_date, p_to_date,
            p_total_assignments, p_total_deductions, p_net_total, p_payroll_type_name,
            'MANUAL', p_user_id, p_user_id
        )
        RETURNING "PayrollRunId" INTO v_run_id;
    END IF;

    -- Insertar lineas desde JSONB
    IF p_lines_json IS NOT NULL AND jsonb_array_length(p_lines_json) > 0 THEN
        INSERT INTO hr."PayrollRunLine" (
            "PayrollRunId", "ConceptCode", "ConceptName", "ConceptType",
            "Quantity", "Amount", "Total", "DescriptionText", "AccountingAccountCode"
        )
        SELECT
            v_run_id,
            r->>'code',
            r->>'name',
            r->>'type',
            (r->>'quantity')::NUMERIC(18,4),
            (r->>'amount')::NUMERIC(18,4),
            (r->>'total')::NUMERIC(18,2),
            r->>'description',
            r->>'account'
        FROM jsonb_array_elements(p_lines_json) AS r;
    END IF;

    RETURN QUERY SELECT 1, 'ok'::VARCHAR(500);

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, ('Error en upsert run: ' || SQLERRM)::VARCHAR(500);
END;
$function$
;

-- usp_hr_payroll_upsertsettlement
CREATE OR REPLACE FUNCTION public.usp_hr_payroll_upsertsettlement(p_company_id integer, p_branch_id integer, p_settlement_code character varying, p_employee_id bigint, p_employee_code character varying, p_employee_name character varying, p_retirement_date date, p_retirement_cause character varying DEFAULT NULL::character varying, p_total_amount numeric DEFAULT 0, p_prestaciones numeric DEFAULT 0, p_vac_pendientes numeric DEFAULT 0, p_bono_salida numeric DEFAULT 0, p_user_id integer DEFAULT NULL::integer)
 RETURNS TABLE("Resultado" integer, "Mensaje" character varying)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_settlement_id BIGINT;
BEGIN
    SELECT "SettlementProcessId" INTO v_settlement_id
    FROM hr."SettlementProcess"
    WHERE "CompanyId" = p_company_id AND "SettlementCode" = p_settlement_code
    LIMIT 1;

    IF v_settlement_id IS NOT NULL THEN
        UPDATE hr."SettlementProcess"
        SET "EmployeeId"      = p_employee_id,
            "EmployeeCode"    = p_employee_code,
            "EmployeeName"    = p_employee_name,
            "RetirementDate"  = p_retirement_date,
            "RetirementCause" = p_retirement_cause,
            "TotalAmount"     = p_total_amount,
            "UpdatedAt"       = NOW() AT TIME ZONE 'UTC',
            "UpdatedByUserId" = p_user_id
        WHERE "SettlementProcessId" = v_settlement_id;
    ELSE
        INSERT INTO hr."SettlementProcess" (
            "CompanyId", "BranchId", "SettlementCode", "EmployeeId", "EmployeeCode",
            "EmployeeName", "RetirementDate", "RetirementCause", "TotalAmount",
            "CreatedByUserId", "UpdatedByUserId"
        )
        VALUES (
            p_company_id, p_branch_id, p_settlement_code, p_employee_id, p_employee_code,
            p_employee_name, p_retirement_date, p_retirement_cause, p_total_amount,
            p_user_id, p_user_id
        )
        RETURNING "SettlementProcessId" INTO v_settlement_id;
    END IF;

    DELETE FROM hr."SettlementProcessLine" WHERE "SettlementProcessId" = v_settlement_id;

    INSERT INTO hr."SettlementProcessLine" ("SettlementProcessId", "ConceptCode", "ConceptName", "Amount")
    VALUES
        (v_settlement_id, 'PRESTACIONES', 'Prestaciones sociales', p_prestaciones),
        (v_settlement_id, 'VACACIONES_PEND', 'Vacaciones pendientes', p_vac_pendientes),
        (v_settlement_id, 'BONO_SALIDA', 'Bono de salida', p_bono_salida);

    RETURN QUERY SELECT 1, 'ok'::TEXT;
END;
$function$
;

-- usp_hr_payroll_upsertvacation
CREATE OR REPLACE FUNCTION public.usp_hr_payroll_upsertvacation(p_company_id integer, p_branch_id integer, p_vacation_code character varying, p_employee_id bigint, p_employee_code character varying, p_employee_name character varying, p_start_date date, p_end_date date, p_reintegration_date date DEFAULT NULL::date, p_total_amount numeric DEFAULT 0, p_user_id integer DEFAULT NULL::integer)
 RETURNS TABLE("Resultado" integer, "Mensaje" character varying)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_vacation_id BIGINT;
BEGIN
    SELECT "VacationProcessId" INTO v_vacation_id
    FROM hr."VacationProcess"
    WHERE "CompanyId" = p_company_id AND "VacationCode" = p_vacation_code
    LIMIT 1;

    IF v_vacation_id IS NOT NULL THEN
        UPDATE hr."VacationProcess"
        SET "EmployeeId"         = p_employee_id,
            "EmployeeCode"       = p_employee_code,
            "EmployeeName"       = p_employee_name,
            "StartDate"          = p_start_date,
            "EndDate"            = p_end_date,
            "ReintegrationDate"  = p_reintegration_date,
            "ProcessDate"        = (NOW() AT TIME ZONE 'UTC')::DATE,
            "TotalAmount"        = p_total_amount,
            "CalculatedAmount"   = p_total_amount,
            "UpdatedAt"          = NOW() AT TIME ZONE 'UTC',
            "UpdatedByUserId"    = p_user_id
        WHERE "VacationProcessId" = v_vacation_id;
    ELSE
        INSERT INTO hr."VacationProcess" (
            "CompanyId", "BranchId", "VacationCode", "EmployeeId", "EmployeeCode",
            "EmployeeName", "StartDate", "EndDate", "ReintegrationDate",
            "ProcessDate", "TotalAmount", "CalculatedAmount",
            "CreatedByUserId", "UpdatedByUserId"
        )
        VALUES (
            p_company_id, p_branch_id, p_vacation_code, p_employee_id, p_employee_code,
            p_employee_name, p_start_date, p_end_date, p_reintegration_date,
            (NOW() AT TIME ZONE 'UTC')::DATE, p_total_amount, p_total_amount,
            p_user_id, p_user_id
        )
        RETURNING "VacationProcessId" INTO v_vacation_id;
    END IF;

    DELETE FROM hr."VacationProcessLine" WHERE "VacationProcessId" = v_vacation_id;

    INSERT INTO hr."VacationProcessLine" ("VacationProcessId", "ConceptCode", "ConceptName", "Amount")
    VALUES (v_vacation_id, 'VACACIONES', 'Pago de vacaciones', p_total_amount);

    RETURN QUERY SELECT 1, 'ok'::TEXT;
END;
$function$
;

-- usp_hr_profitsharing_approve
CREATE OR REPLACE FUNCTION public.usp_hr_profitsharing_approve(p_profit_sharing_id integer, p_approved_by integer, OUT p_resultado integer, OUT p_mensaje character varying)
 RETURNS record
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_current_status VARCHAR(20);
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    SELECT "Status" INTO v_current_status
    FROM hr."ProfitSharing"
    WHERE "ProfitSharingId" = p_profit_sharing_id;

    IF v_current_status IS NULL THEN
        p_resultado := -1;
        p_mensaje   := 'Registro de utilidades no encontrado.';
        RETURN;
    END IF;

    IF v_current_status <> 'CALCULADA' THEN
        p_resultado := -2;
        p_mensaje   := 'Solo se pueden aprobar utilidades en estado CALCULADA. Estado actual: ' || v_current_status;
        RETURN;
    END IF;

    UPDATE hr."ProfitSharing"
    SET "Status"     = 'PROCESADA',
        "ApprovedBy" = p_approved_by,
        "ApprovedAt" = (NOW() AT TIME ZONE 'UTC'),
        "UpdatedAt"  = (NOW() AT TIME ZONE 'UTC')
    WHERE "ProfitSharingId" = p_profit_sharing_id;

    p_resultado := p_profit_sharing_id;
    p_mensaje   := 'Utilidades aprobadas exitosamente.';
END;
$function$
;

-- usp_hr_profitsharing_generate
CREATE OR REPLACE FUNCTION public.usp_hr_profitsharing_generate(p_company_id integer, p_branch_id integer, p_fiscal_year integer, p_days_granted integer, p_total_company_profits numeric DEFAULT NULL::numeric, p_created_by integer DEFAULT NULL::integer, OUT p_resultado integer, OUT p_mensaje character varying)
 RETURNS record
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_old_id            INTEGER;
    v_ps_id             INTEGER;
    v_year_start        DATE;
    v_year_end          DATE;
    v_total_days        INTEGER;
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    IF p_days_granted < 30 OR p_days_granted > 120 THEN
        p_resultado := -1;
        p_mensaje   := 'Los días otorgados deben estar entre 30 y 120 (LOTTT Art. 131).';
        RETURN;
    END IF;

    IF EXISTS (
        SELECT 1 FROM hr."ProfitSharing"
        WHERE "CompanyId" = p_company_id AND "BranchId" = p_branch_id AND "FiscalYear" = p_fiscal_year
          AND "Status" IN ('CALCULADA','PROCESADA','CERRADA')
    ) THEN
        p_resultado := -2;
        p_mensaje   := 'Ya existe un cálculo de utilidades procesado para este año fiscal.';
        RETURN;
    END IF;

    BEGIN
        v_year_start     := MAKE_DATE(p_fiscal_year, 1, 1);
        v_year_end       := MAKE_DATE(p_fiscal_year, 12, 31);
        v_total_days     := (v_year_end - v_year_start) + 1;

        -- Eliminar borrador previo si existe
        SELECT "ProfitSharingId" INTO v_old_id
        FROM hr."ProfitSharing"
        WHERE "CompanyId" = p_company_id AND "BranchId" = p_branch_id
          AND "FiscalYear" = p_fiscal_year AND "Status" = 'BORRADOR';

        IF v_old_id IS NOT NULL THEN
            DELETE FROM hr."ProfitSharingLine" WHERE "ProfitSharingId" = v_old_id;
            DELETE FROM hr."ProfitSharing"     WHERE "ProfitSharingId" = v_old_id;
        END IF;

        INSERT INTO hr."ProfitSharing" (
            "CompanyId", "BranchId", "FiscalYear", "DaysGranted",
            "TotalCompanyProfits", "Status", "CreatedBy", "CreatedAt", "UpdatedAt"
        )
        VALUES (
            p_company_id, p_branch_id, p_fiscal_year, p_days_granted,
            p_total_company_profits, 'CALCULADA', p_created_by,
            (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
        )
        RETURNING "ProfitSharingId" INTO v_ps_id;

        INSERT INTO hr."ProfitSharingLine" (
            "ProfitSharingId", "EmployeeId", "EmployeeCode", "EmployeeName",
            "MonthlySalary", "DailySalary", "DaysWorked", "DaysEntitled",
            "GrossAmount", "InceDeduction", "NetAmount"
        )
        SELECT
            v_ps_id,
            e."EmployeeId",
            e."EmployeeCode",
            e."EmployeeName",
            COALESCE((
                SELECT prl."Amount"
                FROM hr."PayrollRun" pr
                INNER JOIN hr."PayrollRunLine" prl ON prl."PayrollRunId" = pr."PayrollRunId"
                WHERE pr."EmployeeId" = e."EmployeeId" AND prl."ConceptCode" = 'SALARIO_BASE'
                ORDER BY pr."CreatedAt" DESC LIMIT 1
            ), 0) AS "MonthlySalary",
            ROUND(COALESCE((
                SELECT prl."Amount"
                FROM hr."PayrollRun" pr
                INNER JOIN hr."PayrollRunLine" prl ON prl."PayrollRunId" = pr."PayrollRunId"
                WHERE pr."EmployeeId" = e."EmployeeId" AND prl."ConceptCode" = 'SALARIO_BASE'
                ORDER BY pr."CreatedAt" DESC LIMIT 1
            ), 0) / 30.0, 2) AS "DailySalary",
            -- DaysWorked: desde mayor(HireDate, YearStart) hasta menor(hoy, YearEnd)
            (LEAST(COALESCE(e."TerminationDate", v_year_end), v_year_end)
             - GREATEST(e."HireDate", v_year_start) + 1)::INTEGER AS "DaysWorked",
            -- DaysEntitled = (DaysWorked / TotalDays) * DaysGranted
            ROUND(
                (LEAST(COALESCE(e."TerminationDate", v_year_end), v_year_end)
                 - GREATEST(e."HireDate", v_year_start) + 1)::NUMERIC
                / v_total_days::NUMERIC * p_days_granted,
            2) AS "DaysEntitled",
            -- GrossAmount = DailySalary * DaysEntitled
            ROUND(
                (COALESCE((
                    SELECT prl."Amount"
                    FROM hr."PayrollRun" pr
                    INNER JOIN hr."PayrollRunLine" prl ON prl."PayrollRunId" = pr."PayrollRunId"
                    WHERE pr."EmployeeId" = e."EmployeeId" AND prl."ConceptCode" = 'SALARIO_BASE'
                    ORDER BY pr."CreatedAt" DESC LIMIT 1
                ), 0) / 30.0)
                * ROUND(
                    (LEAST(COALESCE(e."TerminationDate", v_year_end), v_year_end)
                     - GREATEST(e."HireDate", v_year_start) + 1)::NUMERIC
                    / v_total_days::NUMERIC * p_days_granted,
                2),
            2) AS "GrossAmount",
            -- InceDeduction = GrossAmount * 0.5%
            ROUND(
                (COALESCE((
                    SELECT prl."Amount"
                    FROM hr."PayrollRun" pr
                    INNER JOIN hr."PayrollRunLine" prl ON prl."PayrollRunId" = pr."PayrollRunId"
                    WHERE pr."EmployeeId" = e."EmployeeId" AND prl."ConceptCode" = 'SALARIO_BASE'
                    ORDER BY pr."CreatedAt" DESC LIMIT 1
                ), 0) / 30.0)
                * ROUND(
                    (LEAST(COALESCE(e."TerminationDate", v_year_end), v_year_end)
                     - GREATEST(e."HireDate", v_year_start) + 1)::NUMERIC
                    / v_total_days::NUMERIC * p_days_granted,
                2) * 0.005,
            2) AS "InceDeduction",
            -- NetAmount = GrossAmount - InceDeduction
            ROUND(
                (COALESCE((
                    SELECT prl."Amount"
                    FROM hr."PayrollRun" pr
                    INNER JOIN hr."PayrollRunLine" prl ON prl."PayrollRunId" = pr."PayrollRunId"
                    WHERE pr."EmployeeId" = e."EmployeeId" AND prl."ConceptCode" = 'SALARIO_BASE'
                    ORDER BY pr."CreatedAt" DESC LIMIT 1
                ), 0) / 30.0)
                * ROUND(
                    (LEAST(COALESCE(e."TerminationDate", v_year_end), v_year_end)
                     - GREATEST(e."HireDate", v_year_start) + 1)::NUMERIC
                    / v_total_days::NUMERIC * p_days_granted,
                2)
                -
                ROUND(
                    (COALESCE((
                        SELECT prl."Amount"
                        FROM hr."PayrollRun" pr
                        INNER JOIN hr."PayrollRunLine" prl ON prl."PayrollRunId" = pr."PayrollRunId"
                        WHERE pr."EmployeeId" = e."EmployeeId" AND prl."ConceptCode" = 'SALARIO_BASE'
                        ORDER BY pr."CreatedAt" DESC LIMIT 1
                    ), 0) / 30.0)
                    * ROUND(
                        (LEAST(COALESCE(e."TerminationDate", v_year_end), v_year_end)
                         - GREATEST(e."HireDate", v_year_start) + 1)::NUMERIC
                        / v_total_days::NUMERIC * p_days_granted,
                    2) * 0.005,
                2),
            2) AS "NetAmount"
        FROM master."Employee" e
        WHERE e."CompanyId" = p_company_id
          AND e."IsActive" = TRUE
          AND e."HireDate" <= v_year_end
          AND (e."TerminationDate" IS NULL OR e."TerminationDate" >= v_year_start);

        p_resultado := v_ps_id;
        p_mensaje   := 'Utilidades generadas exitosamente.';

    EXCEPTION WHEN OTHERS THEN
        p_resultado := -99;
        p_mensaje   := SQLERRM;
    END;
END;
$function$
;

-- usp_hr_profitsharing_getsummary
CREATE OR REPLACE FUNCTION public.usp_hr_profitsharing_getsummary(p_profit_sharing_id integer)
 RETURNS TABLE(result_type character varying, row_data jsonb)
 LANGUAGE plpgsql
AS $function$
BEGIN
    -- Cabecera
    RETURN QUERY
    SELECT
        'HEADER'::TEXT,
        jsonb_build_object(
            'ProfitSharingId',      ps."ProfitSharingId",
            'CompanyId',            ps."CompanyId",
            'BranchId',             ps."BranchId",
            'FiscalYear',           ps."FiscalYear",
            'DaysGranted',          ps."DaysGranted",
            'TotalCompanyProfits',  ps."TotalCompanyProfits",
            'Status',               ps."Status",
            'CreatedBy',            ps."CreatedBy",
            'CreatedAt',            ps."CreatedAt",
            'ApprovedBy',           ps."ApprovedBy",
            'ApprovedAt',           ps."ApprovedAt",
            'UpdatedAt',            ps."UpdatedAt",
            'TotalEmployees',       (SELECT COUNT(*) FROM hr."ProfitSharingLine" WHERE "ProfitSharingId" = ps."ProfitSharingId"),
            'TotalGross',           COALESCE((SELECT SUM("GrossAmount") FROM hr."ProfitSharingLine" WHERE "ProfitSharingId" = ps."ProfitSharingId"), 0),
            'TotalInce',            COALESCE((SELECT SUM("InceDeduction") FROM hr."ProfitSharingLine" WHERE "ProfitSharingId" = ps."ProfitSharingId"), 0),
            'TotalNet',             COALESCE((SELECT SUM("NetAmount") FROM hr."ProfitSharingLine" WHERE "ProfitSharingId" = ps."ProfitSharingId"), 0)
        )
    FROM hr."ProfitSharing" ps
    WHERE ps."ProfitSharingId" = p_profit_sharing_id;

    -- Detalle
    RETURN QUERY
    SELECT
        'DETAIL'::TEXT,
        jsonb_build_object(
            'LineId',           l."LineId",
            'EmployeeId',       l."EmployeeId",
            'EmployeeCode',     l."EmployeeCode",
            'EmployeeName',     l."EmployeeName",
            'MonthlySalary',    l."MonthlySalary",
            'DailySalary',      l."DailySalary",
            'DaysWorked',       l."DaysWorked",
            'DaysEntitled',     l."DaysEntitled",
            'GrossAmount',      l."GrossAmount",
            'InceDeduction',    l."InceDeduction",
            'NetAmount',        l."NetAmount",
            'IsPaid',           l."IsPaid",
            'PaidAt',           l."PaidAt"
        )
    FROM hr."ProfitSharingLine" l
    WHERE l."ProfitSharingId" = p_profit_sharing_id
    ORDER BY l."EmployeeName";
END;
$function$
;

-- usp_hr_profitsharing_list
CREATE OR REPLACE FUNCTION public.usp_hr_profitsharing_list(p_company_id integer, p_branch_id integer DEFAULT NULL::integer, p_fiscal_year integer DEFAULT NULL::integer, p_status character varying DEFAULT NULL::character varying, p_offset integer DEFAULT 0, p_limit integer DEFAULT 50)
 RETURNS TABLE(p_total_count bigint, "ProfitSharingId" integer, "CompanyId" integer, "BranchId" integer, "FiscalYear" integer, "DaysGranted" integer, "TotalCompanyProfits" numeric, "Status" character varying, "CreatedBy" integer, "CreatedAt" timestamp without time zone, "ApprovedBy" integer, "ApprovedAt" timestamp without time zone, "UpdatedAt" timestamp without time zone, "TotalEmployees" bigint, "TotalNet" numeric)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        COUNT(*) OVER()                                                                                           AS p_total_count,
        ps."ProfitSharingId",
        ps."CompanyId",
        ps."BranchId",
        ps."FiscalYear",
        ps."DaysGranted",
        ps."TotalCompanyProfits",
        ps."Status",
        ps."CreatedBy",
        ps."CreatedAt",
        ps."ApprovedBy",
        ps."ApprovedAt",
        ps."UpdatedAt",
        (SELECT COUNT(*) FROM hr."ProfitSharingLine" WHERE "ProfitSharingId" = ps."ProfitSharingId")::BIGINT     AS "TotalEmployees",
        COALESCE((SELECT SUM("NetAmount") FROM hr."ProfitSharingLine" WHERE "ProfitSharingId" = ps."ProfitSharingId"), 0) AS "TotalNet"
    FROM hr."ProfitSharing" ps
    WHERE ps."CompanyId" = p_company_id
      AND (p_branch_id   IS NULL OR ps."BranchId"   = p_branch_id)
      AND (p_fiscal_year IS NULL OR ps."FiscalYear"  = p_fiscal_year)
      AND (p_status      IS NULL OR ps."Status"      = p_status)
    ORDER BY ps."FiscalYear" DESC, ps."CreatedAt" DESC
    LIMIT p_limit OFFSET p_offset;
END;
$function$
;

-- usp_hr_savings_approveloan
CREATE OR REPLACE FUNCTION public.usp_hr_savings_approveloan(p_loan_id integer, p_approved boolean, p_approved_by integer, p_notes character varying DEFAULT NULL::character varying, OUT p_resultado integer, OUT p_mensaje character varying)
 RETURNS record
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_current_status    VARCHAR(15);
    v_fund_id           INTEGER;
    v_loan_amount       NUMERIC(18,2);
    v_cur_balance       NUMERIC(18,2);
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    SELECT "Status", "SavingsFundId", "LoanAmount"
    INTO v_current_status, v_fund_id, v_loan_amount
    FROM hr."SavingsLoan"
    WHERE "LoanId" = p_loan_id;

    IF v_current_status IS NULL THEN
        p_resultado := -1;
        p_mensaje   := 'Préstamo no encontrado.';
        RETURN;
    END IF;

    IF v_current_status <> 'SOLICITADO' THEN
        p_resultado := -2;
        p_mensaje   := 'Solo se pueden aprobar/rechazar préstamos en estado SOLICITADO. Estado actual: ' || v_current_status;
        RETURN;
    END IF;

    BEGIN
        IF p_approved THEN
            UPDATE hr."SavingsLoan"
            SET "Status"        = 'ACTIVO',
                "ApprovedDate"  = CAST((NOW() AT TIME ZONE 'UTC') AS DATE),
                "ApprovedBy"    = p_approved_by,
                "Notes"         = COALESCE(p_notes, "Notes"),
                "UpdatedAt"     = (NOW() AT TIME ZONE 'UTC')
            WHERE "LoanId" = p_loan_id;

            SELECT COALESCE((
                SELECT "Balance" FROM hr."SavingsFundTransaction"
                WHERE "SavingsFundId" = v_fund_id
                ORDER BY "TransactionId" DESC LIMIT 1
            ), 0)
            INTO v_cur_balance;

            v_cur_balance := v_cur_balance - v_loan_amount;

            INSERT INTO hr."SavingsFundTransaction" (
                "SavingsFundId", "TransactionDate", "TransactionType",
                "Amount", "Balance", "Reference", "Notes", "CreatedAt"
            )
            VALUES (
                v_fund_id,
                CAST((NOW() AT TIME ZONE 'UTC') AS DATE),
                'PRESTAMO',
                v_loan_amount,
                v_cur_balance,
                'Desembolso préstamo #' || p_loan_id::TEXT,
                'Aprobado por usuario ' || p_approved_by::TEXT,
                (NOW() AT TIME ZONE 'UTC')
            );

            p_mensaje := 'Préstamo aprobado y desembolsado exitosamente.';
        ELSE
            UPDATE hr."SavingsLoan"
            SET "Status"    = 'RECHAZADO',
                "ApprovedBy" = p_approved_by,
                "Notes"      = COALESCE(p_notes, "Notes"),
                "UpdatedAt"  = (NOW() AT TIME ZONE 'UTC')
            WHERE "LoanId" = p_loan_id;

            p_mensaje := 'Préstamo rechazado.';
        END IF;

        p_resultado := p_loan_id;

    EXCEPTION WHEN OTHERS THEN
        p_resultado := -99;
        p_mensaje   := SQLERRM;
    END;
END;
$function$
;

-- usp_hr_savings_enroll
CREATE OR REPLACE FUNCTION public.usp_hr_savings_enroll(p_company_id integer, p_employee_id bigint DEFAULT NULL::bigint, p_employee_code character varying DEFAULT NULL::character varying, p_employee_name character varying DEFAULT NULL::character varying, p_employee_contribution numeric DEFAULT NULL::numeric, p_employer_match numeric DEFAULT NULL::numeric, p_enrollment_date date DEFAULT NULL::date, OUT p_resultado integer, OUT p_mensaje character varying)
 RETURNS record
 LANGUAGE plpgsql
AS $function$
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    IF EXISTS (
        SELECT 1 FROM hr."SavingsFund"
        WHERE "CompanyId" = p_company_id AND "EmployeeCode" = p_employee_code AND "Status" = 'ACTIVO'
    ) THEN
        p_resultado := -1;
        p_mensaje   := 'El empleado ya está inscrito en la caja de ahorro.';
        RETURN;
    END IF;

    IF p_employee_contribution <= 0 OR p_employer_match < 0 THEN
        p_resultado := -2;
        p_mensaje   := 'El porcentaje de aporte del empleado debe ser mayor a cero.';
        RETURN;
    END IF;

    BEGIN
        INSERT INTO hr."SavingsFund" (
            "CompanyId", "EmployeeId", "EmployeeCode", "EmployeeName",
            "EmployeeContribution", "EmployerMatch", "EnrollmentDate", "Status", "CreatedAt"
        )
        VALUES (
            p_company_id, p_employee_id, p_employee_code, p_employee_name,
            p_employee_contribution, p_employer_match, p_enrollment_date, 'ACTIVO',
            (NOW() AT TIME ZONE 'UTC')
        )
        RETURNING "SavingsFundId" INTO p_resultado;

        p_mensaje := 'Empleado inscrito en caja de ahorro exitosamente.';

    EXCEPTION WHEN OTHERS THEN
        p_resultado := -99;
        p_mensaje   := SQLERRM;
    END;
END;
$function$
;

-- usp_hr_savings_getbalance
CREATE OR REPLACE FUNCTION public.usp_hr_savings_getbalance(p_company_id integer, p_employee_code character varying)
 RETURNS TABLE(result_type character varying, row_data jsonb)
 LANGUAGE plpgsql
AS $function$
BEGIN
    -- Datos del fondo
    RETURN QUERY
    SELECT
        'FUND'::TEXT,
        jsonb_build_object(
            'SavingsFundId',        sf."SavingsFundId",
            'EmployeeCode',         sf."EmployeeCode",
            'EmployeeName',         sf."EmployeeName",
            'EmployeeContribution', sf."EmployeeContribution",
            'EmployerMatch',        sf."EmployerMatch",
            'EnrollmentDate',       sf."EnrollmentDate",
            'Status',               sf."Status",
            'CurrentBalance',       COALESCE((
                                        SELECT "Balance" FROM hr."SavingsFundTransaction"
                                        WHERE "SavingsFundId" = sf."SavingsFundId"
                                        ORDER BY "TransactionId" DESC LIMIT 1
                                    ), 0)
        )
    FROM hr."SavingsFund" sf
    WHERE sf."CompanyId" = p_company_id AND sf."EmployeeCode" = p_employee_code;

    -- Historial de transacciones
    RETURN QUERY
    SELECT
        'TRANSACTION'::TEXT,
        jsonb_build_object(
            'TransactionId',    tx."TransactionId",
            'TransactionDate',  tx."TransactionDate",
            'TransactionType',  tx."TransactionType",
            'Amount',           tx."Amount",
            'Balance',          tx."Balance",
            'Reference',        tx."Reference",
            'PayrollBatchId',   tx."PayrollBatchId",
            'Notes',            tx."Notes",
            'CreatedAt',        tx."CreatedAt"
        )
    FROM hr."SavingsFundTransaction" tx
    INNER JOIN hr."SavingsFund" sf ON sf."SavingsFundId" = tx."SavingsFundId"
    WHERE sf."CompanyId" = p_company_id AND sf."EmployeeCode" = p_employee_code
    ORDER BY tx."TransactionDate" DESC, tx."TransactionId" DESC;
END;
$function$
;

-- usp_hr_savings_list
CREATE OR REPLACE FUNCTION public.usp_hr_savings_list(p_company_id integer, p_status character varying DEFAULT NULL::character varying, p_employee_code character varying DEFAULT NULL::character varying, p_offset integer DEFAULT 0, p_limit integer DEFAULT 50)
 RETURNS TABLE(p_total_count bigint, "SavingsFundId" integer, "EmployeeId" bigint, "EmployeeCode" character varying, "EmployeeName" character varying, "EmployeeContribution" numeric, "EmployerMatch" numeric, "EnrollmentDate" date, "Status" character varying, "CreatedAt" timestamp without time zone, "CurrentBalance" numeric)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        COUNT(*) OVER()         AS p_total_count,
        sf."SavingsFundId",
        sf."EmployeeId",
        sf."EmployeeCode",
        sf."EmployeeName",
        sf."EmployeeContribution",
        sf."EmployerMatch",
        sf."EnrollmentDate",
        sf."Status",
        sf."CreatedAt",
        COALESCE((
            SELECT "Balance" FROM hr."SavingsFundTransaction"
            WHERE "SavingsFundId" = sf."SavingsFundId"
            ORDER BY "TransactionId" DESC LIMIT 1
        ), 0::NUMERIC) AS "CurrentBalance"
    FROM hr."SavingsFund" sf
    WHERE sf."CompanyId" = p_company_id
      AND (p_status        IS NULL OR sf."Status"       = p_status)
      AND (p_employee_code IS NULL OR sf."EmployeeCode" = p_employee_code)
    ORDER BY sf."EmployeeName"
    LIMIT p_limit OFFSET p_offset;
END;
$function$
;

-- usp_hr_savings_loanlist
CREATE OR REPLACE FUNCTION public.usp_hr_savings_loanlist(p_company_id integer, p_status character varying DEFAULT NULL::character varying, p_employee_code character varying DEFAULT NULL::character varying, p_offset integer DEFAULT 0, p_limit integer DEFAULT 50)
 RETURNS TABLE(p_total_count bigint, "LoanId" integer, "SavingsFundId" integer, "EmployeeCode" character varying, "EmployeeName" character varying, "RequestDate" date, "ApprovedDate" date, "LoanAmount" numeric, "InterestRate" numeric, "TotalPayable" numeric, "MonthlyPayment" numeric, "InstallmentsTotal" integer, "InstallmentsPaid" integer, "OutstandingBalance" numeric, "Status" character varying, "ApprovedBy" integer, "Notes" character varying, "CreatedAt" timestamp without time zone)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        COUNT(*) OVER()         AS p_total_count,
        sl."LoanId",
        sl."SavingsFundId",
        sl."EmployeeCode",
        sf."EmployeeName",
        sl."RequestDate",
        sl."ApprovedDate",
        sl."LoanAmount",
        sl."InterestRate",
        sl."TotalPayable",
        sl."MonthlyPayment",
        sl."InstallmentsTotal",
        sl."InstallmentsPaid",
        sl."OutstandingBalance",
        sl."Status",
        sl."ApprovedBy",
        sl."Notes",
        sl."CreatedAt"
    FROM hr."SavingsLoan" sl
    INNER JOIN hr."SavingsFund" sf ON sf."SavingsFundId" = sl."SavingsFundId"
    WHERE sf."CompanyId" = p_company_id
      AND (p_status        IS NULL OR sl."Status"       = p_status)
      AND (p_employee_code IS NULL OR sl."EmployeeCode" = p_employee_code)
    ORDER BY sl."RequestDate" DESC, sl."LoanId" DESC
    LIMIT p_limit OFFSET p_offset;
END;
$function$
;

-- usp_hr_savings_processloanpayment
CREATE OR REPLACE FUNCTION public.usp_hr_savings_processloanpayment(p_loan_id integer, p_payment_amount numeric DEFAULT NULL::numeric, p_payment_date date DEFAULT NULL::date, p_payroll_batch_id integer DEFAULT NULL::integer, OUT p_resultado integer, OUT p_mensaje character varying)
 RETURNS record
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_fund_id           INTEGER;
    v_monthly_payment   NUMERIC(18,2);
    v_outstanding       NUMERIC(18,2);
    v_inst_paid         INTEGER;
    v_inst_total        INTEGER;
    v_current_status    VARCHAR(15);
    v_cur_balance       NUMERIC(18,2);
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    SELECT "SavingsFundId", "MonthlyPayment", "OutstandingBalance",
           "InstallmentsPaid", "InstallmentsTotal", "Status"
    INTO v_fund_id, v_monthly_payment, v_outstanding,
         v_inst_paid, v_inst_total, v_current_status
    FROM hr."SavingsLoan"
    WHERE "LoanId" = p_loan_id;

    IF v_current_status IS NULL THEN
        p_resultado := -1;
        p_mensaje   := 'Préstamo no encontrado.';
        RETURN;
    END IF;

    IF v_current_status <> 'ACTIVO' THEN
        p_resultado := -2;
        p_mensaje   := 'Solo se pueden registrar pagos en préstamos ACTIVOS. Estado actual: ' || v_current_status;
        RETURN;
    END IF;

    IF p_payment_amount IS NULL THEN p_payment_amount := v_monthly_payment; END IF;
    IF p_payment_date   IS NULL THEN p_payment_date   := CAST((NOW() AT TIME ZONE 'UTC') AS DATE); END IF;

    IF p_payment_amount > v_outstanding THEN
        p_payment_amount := v_outstanding;
    END IF;

    BEGIN
        v_outstanding := v_outstanding - p_payment_amount;
        v_inst_paid   := v_inst_paid + 1;

        UPDATE hr."SavingsLoan"
        SET "OutstandingBalance"  = v_outstanding,
            "InstallmentsPaid"    = v_inst_paid,
            "Status"              = CASE WHEN v_outstanding <= 0 THEN 'PAGADO' ELSE 'ACTIVO' END,
            "UpdatedAt"           = (NOW() AT TIME ZONE 'UTC')
        WHERE "LoanId" = p_loan_id;

        SELECT COALESCE((
            SELECT "Balance" FROM hr."SavingsFundTransaction"
            WHERE "SavingsFundId" = v_fund_id
            ORDER BY "TransactionId" DESC LIMIT 1
        ), 0)
        INTO v_cur_balance;

        v_cur_balance := v_cur_balance + p_payment_amount;

        INSERT INTO hr."SavingsFundTransaction" (
            "SavingsFundId", "TransactionDate", "TransactionType",
            "Amount", "Balance", "Reference", "PayrollBatchId", "Notes", "CreatedAt"
        )
        VALUES (
            v_fund_id,
            p_payment_date,
            'PAGO_PRESTAMO',
            p_payment_amount,
            v_cur_balance,
            'Pago cuota ' || v_inst_paid::TEXT || '/' || v_inst_total::TEXT || ' préstamo #' || p_loan_id::TEXT,
            p_payroll_batch_id,
            CASE WHEN v_outstanding <= 0 THEN 'Préstamo liquidado' ELSE NULL END,
            (NOW() AT TIME ZONE 'UTC')
        );

        p_resultado := p_loan_id;
        IF v_outstanding <= 0 THEN
            p_mensaje := 'Préstamo liquidado exitosamente.';
        ELSE
            p_mensaje := 'Pago registrado. Saldo pendiente: ' || v_outstanding::TEXT;
        END IF;

    EXCEPTION WHEN OTHERS THEN
        p_resultado := -99;
        p_mensaje   := SQLERRM;
    END;
END;
$function$
;

-- usp_hr_savings_processmonthly
CREATE OR REPLACE FUNCTION public.usp_hr_savings_processmonthly(p_company_id integer, p_process_date date, p_payroll_batch_id integer DEFAULT NULL::integer, OUT p_resultado integer, OUT p_mensaje character varying)
 RETURNS record
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_fund_id       INTEGER;
    v_emp_code      VARCHAR(24);
    v_emp_contrib   NUMERIC(8,4);
    v_match_pct     NUMERIC(8,4);
    v_salary        NUMERIC(18,2);
    v_emp_amount    NUMERIC(18,2);
    v_match_amount  NUMERIC(18,2);
    v_cur_balance   NUMERIC(18,2);
    v_processed     INTEGER := 0;
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    BEGIN
        FOR v_fund_id, v_emp_code, v_emp_contrib, v_match_pct IN
            SELECT sf."SavingsFundId", sf."EmployeeCode", sf."EmployeeContribution", sf."EmployerMatch"
            FROM hr."SavingsFund" sf
            WHERE sf."CompanyId" = p_company_id AND sf."Status" = 'ACTIVO'
        LOOP
            SELECT COALESCE((
                SELECT prl."Amount"
                FROM hr."PayrollRun" pr
                INNER JOIN hr."PayrollRunLine" prl ON prl."PayrollRunId" = pr."PayrollRunId"
                WHERE pr."EmployeeId" = e."EmployeeId" AND prl."ConceptCode" = 'SALARIO_BASE'
                ORDER BY pr."CreatedAt" DESC LIMIT 1
            ), 0)
            INTO v_salary
            FROM master."Employee" e
            WHERE e."CompanyId" = p_company_id AND e."EmployeeCode" = v_emp_code AND e."IsActive" = TRUE;

            IF v_salary IS NOT NULL AND v_salary > 0 THEN
                v_emp_amount   := ROUND(v_salary * v_emp_contrib / 100.0, 2);
                v_match_amount := ROUND(v_salary * v_match_pct  / 100.0, 2);

                SELECT COALESCE((
                    SELECT "Balance" FROM hr."SavingsFundTransaction"
                    WHERE "SavingsFundId" = v_fund_id
                    ORDER BY "TransactionId" DESC LIMIT 1
                ), 0)
                INTO v_cur_balance;

                v_cur_balance := v_cur_balance + v_emp_amount;
                INSERT INTO hr."SavingsFundTransaction" (
                    "SavingsFundId", "TransactionDate", "TransactionType",
                    "Amount", "Balance", "Reference", "PayrollBatchId", "CreatedAt"
                )
                VALUES (
                    v_fund_id, p_process_date, 'APORTE_EMPLEADO',
                    v_emp_amount, v_cur_balance,
                    'Aporte mensual ' || TO_CHAR(p_process_date, 'YYYY-MM'),
                    p_payroll_batch_id,
                    (NOW() AT TIME ZONE 'UTC')
                );

                v_cur_balance := v_cur_balance + v_match_amount;
                INSERT INTO hr."SavingsFundTransaction" (
                    "SavingsFundId", "TransactionDate", "TransactionType",
                    "Amount", "Balance", "Reference", "PayrollBatchId", "CreatedAt"
                )
                VALUES (
                    v_fund_id, p_process_date, 'APORTE_PATRONAL',
                    v_match_amount, v_cur_balance,
                    'Aporte patronal ' || TO_CHAR(p_process_date, 'YYYY-MM'),
                    p_payroll_batch_id,
                    (NOW() AT TIME ZONE 'UTC')
                );

                v_processed := v_processed + 1;
            END IF;
        END LOOP;

        p_resultado := v_processed;
        p_mensaje   := 'Aportes procesados para ' || v_processed::TEXT || ' miembros.';

    EXCEPTION WHEN OTHERS THEN
        p_resultado := -99;
        p_mensaje   := SQLERRM;
    END;
END;
$function$
;

-- usp_hr_savings_requestloan
CREATE OR REPLACE FUNCTION public.usp_hr_savings_requestloan(p_company_id integer, p_employee_code character varying, p_loan_amount numeric, p_interest_rate numeric DEFAULT 0, p_installments_total integer DEFAULT NULL::integer, p_notes character varying DEFAULT NULL::character varying, OUT p_resultado integer, OUT p_mensaje character varying)
 RETURNS record
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_fund_id       INTEGER;
    v_total_payable NUMERIC(18,2);
    v_monthly_pmt   NUMERIC(18,2);
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    SELECT "SavingsFundId" INTO v_fund_id
    FROM hr."SavingsFund"
    WHERE "CompanyId" = p_company_id AND "EmployeeCode" = p_employee_code AND "Status" = 'ACTIVO';

    IF v_fund_id IS NULL THEN
        p_resultado := -1;
        p_mensaje   := 'El empleado no tiene una cuenta activa en caja de ahorro.';
        RETURN;
    END IF;

    IF EXISTS (
        SELECT 1 FROM hr."SavingsLoan"
        WHERE "SavingsFundId" = v_fund_id AND "Status" IN ('SOLICITADO','APROBADO','ACTIVO')
    ) THEN
        p_resultado := -2;
        p_mensaje   := 'El empleado ya tiene un préstamo activo o pendiente.';
        RETURN;
    END IF;

    IF p_loan_amount <= 0 THEN
        p_resultado := -3;
        p_mensaje   := 'El monto del préstamo debe ser mayor a cero.';
        RETURN;
    END IF;

    IF p_installments_total <= 0 THEN
        p_resultado := -4;
        p_mensaje   := 'El número de cuotas debe ser mayor a cero.';
        RETURN;
    END IF;

    v_total_payable := ROUND(p_loan_amount * (1 + p_interest_rate / 100.0), 2);
    v_monthly_pmt   := ROUND(v_total_payable / p_installments_total, 2);

    BEGIN
        INSERT INTO hr."SavingsLoan" (
            "SavingsFundId", "EmployeeCode", "RequestDate",
            "LoanAmount", "InterestRate", "TotalPayable", "MonthlyPayment",
            "InstallmentsTotal", "InstallmentsPaid", "OutstandingBalance",
            "Status", "Notes", "CreatedAt", "UpdatedAt"
        )
        VALUES (
            v_fund_id, p_employee_code, CAST((NOW() AT TIME ZONE 'UTC') AS DATE),
            p_loan_amount, p_interest_rate, v_total_payable, v_monthly_pmt,
            p_installments_total, 0, v_total_payable,
            'SOLICITADO', p_notes,
            (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
        )
        RETURNING "LoanId" INTO p_resultado;

        p_mensaje := 'Solicitud de préstamo registrada exitosamente.';

    EXCEPTION WHEN OTHERS THEN
        p_resultado := -99;
        p_mensaje   := SQLERRM;
    END;
END;
$function$
;

-- usp_hr_training_getemployeecertifications
CREATE OR REPLACE FUNCTION public.usp_hr_training_getemployeecertifications(p_company_id integer, p_employee_code character varying)
 RETURNS TABLE("TrainingRecordId" integer, "CompanyId" integer, "CountryCode" character, "TrainingType" character varying, "Title" character varying, "Provider" character varying, "StartDate" date, "EndDate" date, "DurationHours" numeric, "EmployeeId" bigint, "EmployeeCode" character varying, "EmployeeName" character varying, "CertificateNumber" character varying, "CertificateUrl" character varying, "Result" character varying, "IsRegulatory" boolean, "Notes" character varying, "CreatedAt" timestamp without time zone, "UpdatedAt" timestamp without time zone)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        t."TrainingRecordId",
        t."CompanyId",
        t."CountryCode",
        t."TrainingType",
        t."Title",
        t."Provider",
        t."StartDate",
        t."EndDate",
        t."DurationHours",
        t."EmployeeId",
        t."EmployeeCode",
        t."EmployeeName",
        t."CertificateNumber",
        t."CertificateUrl",
        t."Result",
        t."IsRegulatory",
        t."Notes",
        t."CreatedAt",
        t."UpdatedAt"
    FROM hr."TrainingRecord" t
    WHERE t."CompanyId"         = p_company_id
      AND t."EmployeeCode"      = p_employee_code
      AND t."Result"            = 'PASSED'
      AND t."CertificateNumber" IS NOT NULL
    ORDER BY t."StartDate" DESC;
END;
$function$
;

-- usp_hr_training_list
CREATE OR REPLACE FUNCTION public.usp_hr_training_list(p_company_id integer, p_training_type character varying DEFAULT NULL::character varying, p_employee_code character varying DEFAULT NULL::character varying, p_country_code character DEFAULT NULL::bpchar, p_is_regulatory boolean DEFAULT NULL::boolean, p_result character varying DEFAULT NULL::character varying, p_from_date date DEFAULT NULL::date, p_to_date date DEFAULT NULL::date, p_page integer DEFAULT 1, p_limit integer DEFAULT 50)
 RETURNS TABLE(p_total_count bigint, "TrainingRecordId" integer, "CompanyId" integer, "CountryCode" character, "TrainingType" character varying, "Title" character varying, "Provider" character varying, "StartDate" date, "EndDate" date, "DurationHours" numeric, "EmployeeId" bigint, "EmployeeCode" character varying, "EmployeeName" character varying, "CertificateNumber" character varying, "CertificateUrl" character varying, "Result" character varying, "IsRegulatory" boolean, "Notes" character varying, "CreatedAt" timestamp without time zone, "UpdatedAt" timestamp without time zone)
 LANGUAGE plpgsql
AS $function$
BEGIN
    IF p_page  < 1   THEN p_page  := 1;   END IF;
    IF p_limit < 1   THEN p_limit := 50;  END IF;
    IF p_limit > 500 THEN p_limit := 500; END IF;

    RETURN QUERY
    SELECT
        COUNT(*) OVER()         AS p_total_count,
        "TrainingRecordId",
        "CompanyId",
        "CountryCode",
        "TrainingType",
        "Title",
        "Provider",
        "StartDate",
        "EndDate",
        "DurationHours",
        "EmployeeId",
        "EmployeeCode",
        "EmployeeName",
        "CertificateNumber",
        "CertificateUrl",
        "Result",
        "IsRegulatory",
        "Notes",
        "CreatedAt",
        "UpdatedAt"
    FROM hr."TrainingRecord"
    WHERE "CompanyId" = p_company_id
      AND (p_training_type IS NULL OR "TrainingType" = p_training_type)
      AND (p_employee_code IS NULL OR "EmployeeCode" = p_employee_code)
      AND (p_country_code  IS NULL OR "CountryCode"  = p_country_code)
      AND (p_is_regulatory IS NULL OR "IsRegulatory" = p_is_regulatory)
      AND (p_result        IS NULL OR "Result"        = p_result)
      AND (p_from_date     IS NULL OR "StartDate"    >= p_from_date)
      AND (p_to_date       IS NULL OR "StartDate"    <= p_to_date)
    ORDER BY "StartDate" DESC, "TrainingRecordId" DESC
    LIMIT p_limit OFFSET (p_page - 1) * p_limit;
END;
$function$
;

-- usp_hr_training_save
CREATE OR REPLACE FUNCTION public.usp_hr_training_save(p_training_record_id integer DEFAULT NULL::integer, p_company_id integer DEFAULT NULL::integer, p_country_code character DEFAULT NULL::bpchar, p_training_type character varying DEFAULT NULL::character varying, p_title character varying DEFAULT NULL::character varying, p_provider character varying DEFAULT NULL::character varying, p_start_date date DEFAULT NULL::date, p_end_date date DEFAULT NULL::date, p_duration_hours numeric DEFAULT NULL::numeric, p_employee_id bigint DEFAULT NULL::bigint, p_employee_code character varying DEFAULT NULL::character varying, p_employee_name character varying DEFAULT NULL::character varying, p_certificate_number character varying DEFAULT NULL::character varying, p_certificate_url character varying DEFAULT NULL::character varying, p_result character varying DEFAULT NULL::character varying, p_is_regulatory boolean DEFAULT false, p_notes character varying DEFAULT NULL::character varying, OUT p_resultado integer, OUT p_mensaje character varying)
 RETURNS record
 LANGUAGE plpgsql
AS $function$
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    IF p_training_type NOT IN ('SAFETY','REGULATORY','TECHNICAL','APPRENTICESHIP','INDUCTION') THEN
        p_resultado := -1;
        p_mensaje   := 'Tipo de capacitación no válido.';
        RETURN;
    END IF;

    IF p_result IS NOT NULL AND p_result NOT IN ('PASSED','FAILED','IN_PROGRESS','ATTENDED') THEN
        p_resultado := -1;
        p_mensaje   := 'Resultado no válido.';
        RETURN;
    END IF;

    IF p_duration_hours <= 0 THEN
        p_resultado := -1;
        p_mensaje   := 'La duración en horas debe ser mayor a cero.';
        RETURN;
    END IF;

    BEGIN
        IF p_training_record_id IS NULL THEN
            INSERT INTO hr."TrainingRecord" (
                "CompanyId", "CountryCode", "TrainingType", "Title", "Provider",
                "StartDate", "EndDate", "DurationHours",
                "EmployeeId", "EmployeeCode", "EmployeeName",
                "CertificateNumber", "CertificateUrl", "Result",
                "IsRegulatory", "Notes", "CreatedAt", "UpdatedAt"
            )
            VALUES (
                p_company_id, p_country_code, p_training_type, p_title, p_provider,
                p_start_date, p_end_date, p_duration_hours,
                p_employee_id, p_employee_code, p_employee_name,
                p_certificate_number, p_certificate_url, p_result,
                p_is_regulatory, p_notes,
                (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
            )
            RETURNING "TrainingRecordId" INTO p_resultado;

            p_mensaje := 'Registro de capacitación creado exitosamente.';
        ELSE
            IF NOT EXISTS (
                SELECT 1 FROM hr."TrainingRecord"
                WHERE "TrainingRecordId" = p_training_record_id AND "CompanyId" = p_company_id
            ) THEN
                p_resultado := -1;
                p_mensaje   := 'Registro de capacitación no encontrado.';
                RETURN;
            END IF;

            UPDATE hr."TrainingRecord"
            SET
                "CountryCode"       = p_country_code,
                "TrainingType"      = p_training_type,
                "Title"             = p_title,
                "Provider"          = p_provider,
                "StartDate"         = p_start_date,
                "EndDate"           = p_end_date,
                "DurationHours"     = p_duration_hours,
                "EmployeeId"        = COALESCE(p_employee_id, "EmployeeId"),
                "EmployeeCode"      = p_employee_code,
                "EmployeeName"      = p_employee_name,
                "CertificateNumber" = p_certificate_number,
                "CertificateUrl"    = p_certificate_url,
                "Result"            = p_result,
                "IsRegulatory"      = p_is_regulatory,
                "Notes"             = p_notes,
                "UpdatedAt"         = (NOW() AT TIME ZONE 'UTC')
            WHERE "TrainingRecordId" = p_training_record_id
              AND "CompanyId" = p_company_id;

            p_resultado := p_training_record_id;
            p_mensaje   := 'Registro de capacitación actualizado exitosamente.';
        END IF;

    EXCEPTION WHEN OTHERS THEN
        p_resultado := -1;
        p_mensaje   := SQLERRM;
    END;
END;
$function$
;

-- usp_hr_trust_calculatequarter
CREATE OR REPLACE FUNCTION public.usp_hr_trust_calculatequarter(p_company_id integer, p_fiscal_year integer, p_quarter smallint, p_interest_rate numeric DEFAULT 0, OUT p_resultado integer, OUT p_mensaje character varying)
 RETURNS record
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_inserted      INTEGER;
    v_year_end_str  TEXT;
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    IF p_quarter < 1 OR p_quarter > 4 THEN
        p_resultado := -1;
        p_mensaje   := 'El trimestre debe estar entre 1 y 4.';
        RETURN;
    END IF;

    IF EXISTS (
        SELECT 1 FROM hr."SocialBenefitsTrust"
        WHERE "CompanyId" = p_company_id AND "FiscalYear" = p_fiscal_year AND "Quarter" = p_quarter
    ) THEN
        p_resultado := -2;
        p_mensaje   := 'Ya existe un cálculo para el trimestre ' || p_quarter::TEXT || ' del año ' || p_fiscal_year::TEXT || '.';
        RETURN;
    END IF;

    v_year_end_str := p_fiscal_year::TEXT || '-12-31';

    BEGIN
        INSERT INTO hr."SocialBenefitsTrust" (
            "CompanyId", "EmployeeId", "EmployeeCode", "EmployeeName",
            "FiscalYear", "Quarter", "DailySalary",
            "DaysDeposited", "BonusDays", "DepositAmount",
            "InterestRate", "InterestAmount", "AccumulatedBalance", "Status",
            "CreatedAt", "UpdatedAt"
        )
        SELECT
            p_company_id,
            e."EmployeeId",
            e."EmployeeCode",
            e."EmployeeName",
            p_fiscal_year,
            p_quarter,
            ROUND(COALESCE((
                SELECT prl."Amount"
                FROM hr."PayrollRun" pr
                INNER JOIN hr."PayrollRunLine" prl ON prl."PayrollRunId" = pr."PayrollRunId"
                WHERE pr."EmployeeId" = e."EmployeeId" AND prl."ConceptCode" = 'SALARIO_BASE'
                ORDER BY pr."CreatedAt" DESC LIMIT 1
            ), 0) / 30.0, 2) AS "DailySalary",
            15 AS "DaysDeposited",
            -- BonusDays: 2 días por cada año después del primero, max 30, solo en Q4
            CASE
                WHEN p_quarter = 4
                 AND DATE_PART('year', v_year_end_str::DATE) - DATE_PART('year', e."HireDate") > 1
                THEN LEAST(
                    (DATE_PART('year', v_year_end_str::DATE) - DATE_PART('year', e."HireDate") - 1)::INTEGER * 2,
                    30
                )
                ELSE 0
            END AS "BonusDays",
            -- DepositAmount = DailySalary * (15 + BonusDays)
            ROUND(
                COALESCE((
                    SELECT prl."Amount"
                    FROM hr."PayrollRun" pr
                    INNER JOIN hr."PayrollRunLine" prl ON prl."PayrollRunId" = pr."PayrollRunId"
                    WHERE pr."EmployeeId" = e."EmployeeId" AND prl."ConceptCode" = 'SALARIO_BASE'
                    ORDER BY pr."CreatedAt" DESC LIMIT 1
                ), 0) / 30.0
                * (15 + CASE
                    WHEN p_quarter = 4
                     AND DATE_PART('year', v_year_end_str::DATE) - DATE_PART('year', e."HireDate") > 1
                    THEN LEAST(
                        (DATE_PART('year', v_year_end_str::DATE) - DATE_PART('year', e."HireDate") - 1)::INTEGER * 2,
                        30
                    )
                    ELSE 0
                   END),
            2) AS "DepositAmount",
            p_interest_rate,
            -- InterestAmount = saldo acumulado anterior * tasa / 4
            ROUND(
                COALESCE((
                    SELECT t."AccumulatedBalance"
                    FROM hr."SocialBenefitsTrust" t
                    WHERE t."CompanyId" = p_company_id
                      AND t."EmployeeCode" = e."EmployeeCode"
                      AND (t."FiscalYear" < p_fiscal_year
                           OR (t."FiscalYear" = p_fiscal_year AND t."Quarter" < p_quarter))
                    ORDER BY t."FiscalYear" DESC, t."Quarter" DESC
                    LIMIT 1
                ), 0) * (p_interest_rate / 100.0) / 4.0,
            2) AS "InterestAmount",
            -- AccumulatedBalance = saldo anterior + deposito + interes
            COALESCE((
                SELECT t."AccumulatedBalance"
                FROM hr."SocialBenefitsTrust" t
                WHERE t."CompanyId" = p_company_id
                  AND t."EmployeeCode" = e."EmployeeCode"
                  AND (t."FiscalYear" < p_fiscal_year
                       OR (t."FiscalYear" = p_fiscal_year AND t."Quarter" < p_quarter))
                ORDER BY t."FiscalYear" DESC, t."Quarter" DESC
                LIMIT 1
            ), 0)
            +
            ROUND(
                COALESCE((
                    SELECT prl."Amount"
                    FROM hr."PayrollRun" pr
                    INNER JOIN hr."PayrollRunLine" prl ON prl."PayrollRunId" = pr."PayrollRunId"
                    WHERE pr."EmployeeId" = e."EmployeeId" AND prl."ConceptCode" = 'SALARIO_BASE'
                    ORDER BY pr."CreatedAt" DESC LIMIT 1
                ), 0) / 30.0
                * (15 + CASE
                    WHEN p_quarter = 4
                     AND DATE_PART('year', v_year_end_str::DATE) - DATE_PART('year', e."HireDate") > 1
                    THEN LEAST(
                        (DATE_PART('year', v_year_end_str::DATE) - DATE_PART('year', e."HireDate") - 1)::INTEGER * 2,
                        30
                    )
                    ELSE 0
                   END),
            2)
            +
            ROUND(
                COALESCE((
                    SELECT t."AccumulatedBalance"
                    FROM hr."SocialBenefitsTrust" t
                    WHERE t."CompanyId" = p_company_id
                      AND t."EmployeeCode" = e."EmployeeCode"
                      AND (t."FiscalYear" < p_fiscal_year
                           OR (t."FiscalYear" = p_fiscal_year AND t."Quarter" < p_quarter))
                    ORDER BY t."FiscalYear" DESC, t."Quarter" DESC
                    LIMIT 1
                ), 0) * (p_interest_rate / 100.0) / 4.0,
            2) AS "AccumulatedBalance",
            'PENDIENTE',
            (NOW() AT TIME ZONE 'UTC'),
            (NOW() AT TIME ZONE 'UTC')
        FROM master."Employee" e
        WHERE e."CompanyId" = p_company_id
          AND e."IsActive" = TRUE
          AND e."HireDate" <= MAKE_DATE(p_fiscal_year, p_quarter * 3, 28);

        GET DIAGNOSTICS v_inserted = ROW_COUNT;

        p_resultado := v_inserted;
        p_mensaje   := 'Fideicomiso calculado para ' || v_inserted::TEXT || ' empleados.';

    EXCEPTION WHEN OTHERS THEN
        p_resultado := -99;
        p_mensaje   := SQLERRM;
    END;
END;
$function$
;

-- usp_hr_trust_getemployeebalance
CREATE OR REPLACE FUNCTION public.usp_hr_trust_getemployeebalance(p_company_id integer, p_employee_code character varying)
 RETURNS TABLE(result_type character varying, row_data jsonb)
 LANGUAGE plpgsql
AS $function$
BEGIN
    -- Saldo actual (1 fila)
    RETURN QUERY
    SELECT
        'BALANCE'::TEXT,
        jsonb_build_object(
            'EmployeeCode',     t."EmployeeCode",
            'EmployeeName',     t."EmployeeName",
            'CurrentBalance',   t."AccumulatedBalance",
            'LastFiscalYear',   t."FiscalYear",
            'LastQuarter',      t."Quarter"
        )
    FROM hr."SocialBenefitsTrust" t
    WHERE t."CompanyId" = p_company_id AND t."EmployeeCode" = p_employee_code
    ORDER BY t."FiscalYear" DESC, t."Quarter" DESC
    LIMIT 1;

    -- Historial
    RETURN QUERY
    SELECT
        'HISTORY'::TEXT,
        jsonb_build_object(
            'TrustId',              t."TrustId",
            'FiscalYear',           t."FiscalYear",
            'Quarter',              t."Quarter",
            'DailySalary',          t."DailySalary",
            'DaysDeposited',        t."DaysDeposited",
            'BonusDays',            t."BonusDays",
            'DepositAmount',        t."DepositAmount",
            'InterestRate',         t."InterestRate",
            'InterestAmount',       t."InterestAmount",
            'AccumulatedBalance',   t."AccumulatedBalance",
            'Status',               t."Status",
            'CreatedAt',            t."CreatedAt"
        )
    FROM hr."SocialBenefitsTrust" t
    WHERE t."CompanyId" = p_company_id AND t."EmployeeCode" = p_employee_code
    ORDER BY t."FiscalYear", t."Quarter";
END;
$function$
;

-- usp_hr_trust_getsummary
CREATE OR REPLACE FUNCTION public.usp_hr_trust_getsummary(p_company_id integer, p_fiscal_year integer, p_quarter smallint)
 RETURNS TABLE(result_type character varying, row_data jsonb)
 LANGUAGE plpgsql
AS $function$
BEGIN
    -- Resumen por estado
    RETURN QUERY
    SELECT
        'SUMMARY'::TEXT,
        jsonb_build_object(
            'TotalEmployees',           COUNT(*),
            'TotalDeposits',            SUM(t."DepositAmount"),
            'TotalInterest',            SUM(t."InterestAmount"),
            'TotalBonusDays',           SUM(t."BonusDays"),
            'TotalAccumulatedBalance',  SUM(t."AccumulatedBalance"),
            'Status',                   t."Status"
        )
    FROM hr."SocialBenefitsTrust" t
    WHERE t."CompanyId" = p_company_id AND t."FiscalYear" = p_fiscal_year AND t."Quarter" = p_quarter
    GROUP BY t."Status";

    -- Detalle por empleado
    RETURN QUERY
    SELECT
        'DETAIL'::TEXT,
        jsonb_build_object(
            'TrustId',              t."TrustId",
            'EmployeeCode',         t."EmployeeCode",
            'EmployeeName',         t."EmployeeName",
            'DailySalary',          t."DailySalary",
            'DaysDeposited',        t."DaysDeposited",
            'BonusDays',            t."BonusDays",
            'DepositAmount',        t."DepositAmount",
            'InterestRate',         t."InterestRate",
            'InterestAmount',       t."InterestAmount",
            'AccumulatedBalance',   t."AccumulatedBalance",
            'Status',               t."Status"
        )
    FROM hr."SocialBenefitsTrust" t
    WHERE t."CompanyId" = p_company_id AND t."FiscalYear" = p_fiscal_year AND t."Quarter" = p_quarter
    ORDER BY t."EmployeeName";
END;
$function$
;

-- usp_hr_trust_list
CREATE OR REPLACE FUNCTION public.usp_hr_trust_list(p_company_id integer, p_fiscal_year integer DEFAULT NULL::integer, p_quarter smallint DEFAULT NULL::smallint, p_employee_code character varying DEFAULT NULL::character varying, p_status character varying DEFAULT NULL::character varying, p_offset integer DEFAULT 0, p_limit integer DEFAULT 50)
 RETURNS TABLE(p_total_count bigint, "TrustId" integer, "EmployeeId" bigint, "EmployeeCode" character varying, "EmployeeName" character varying, "FiscalYear" integer, "Quarter" smallint, "DailySalary" numeric, "DaysDeposited" integer, "BonusDays" integer, "DepositAmount" numeric, "InterestRate" numeric, "InterestAmount" numeric, "AccumulatedBalance" numeric, "Status" character varying, "CreatedAt" timestamp without time zone)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        COUNT(*) OVER()         AS p_total_count,
        t."TrustId",
        t."EmployeeId",
        t."EmployeeCode",
        t."EmployeeName",
        t."FiscalYear",
        t."Quarter",
        t."DailySalary",
        t."DaysDeposited",
        t."BonusDays",
        t."DepositAmount",
        t."InterestRate",
        t."InterestAmount",
        t."AccumulatedBalance",
        t."Status",
        t."CreatedAt"
    FROM hr."SocialBenefitsTrust" t
    WHERE t."CompanyId" = p_company_id
      AND (p_fiscal_year   IS NULL OR t."FiscalYear"    = p_fiscal_year)
      AND (p_quarter       IS NULL OR t."Quarter"        = p_quarter)
      AND (p_employee_code IS NULL OR t."EmployeeCode"   = p_employee_code)
      AND (p_status        IS NULL OR t."Status"         = p_status)
    ORDER BY t."FiscalYear" DESC, t."Quarter" DESC, t."EmployeeName"
    LIMIT p_limit OFFSET p_offset;
END;
$function$
;

-- usp_hr_vacation_request_approve
CREATE OR REPLACE FUNCTION public.usp_hr_vacation_request_approve(p_request_id bigint, p_approved_by character varying)
 RETURNS TABLE("RequestId" bigint, "Status" character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM hr."VacationRequest"
         WHERE "RequestId" = p_request_id AND "Status" = 'PENDIENTE'
    ) THEN
        RAISE EXCEPTION 'Solo se pueden aprobar solicitudes en estado PENDIENTE.'
            USING ERRCODE = 'P0001';
    END IF;

    UPDATE hr."VacationRequest"
       SET "Status"       = 'APROBADA',
           "ApprovedBy"   = p_approved_by,
           "ApprovalDate" = NOW() AT TIME ZONE 'UTC',
           "UpdatedAt"    = NOW() AT TIME ZONE 'UTC'
     WHERE "RequestId" = p_request_id
       AND "Status" = 'PENDIENTE';

    RETURN QUERY SELECT p_request_id, 'APROBADA'::VARCHAR;
END;
$function$
;

-- usp_hr_vacation_request_cancel
CREATE OR REPLACE FUNCTION public.usp_hr_vacation_request_cancel(p_request_id bigint)
 RETURNS TABLE("RequestId" bigint, "Status" character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM hr."VacationRequest"
         WHERE "RequestId" = p_request_id AND "Status" = 'PENDIENTE'
    ) THEN
        RAISE EXCEPTION 'Solo se pueden cancelar solicitudes en estado PENDIENTE.'
            USING ERRCODE = 'P0001';
    END IF;

    UPDATE hr."VacationRequest"
       SET "Status"    = 'CANCELADA',
           "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
     WHERE "RequestId" = p_request_id
       AND "Status" = 'PENDIENTE';

    RETURN QUERY SELECT p_request_id, 'CANCELADA'::VARCHAR;
END;
$function$
;

-- usp_hr_vacation_request_create
CREATE OR REPLACE FUNCTION public.usp_hr_vacation_request_create(p_company_id integer, p_branch_id integer, p_employee_code character varying, p_start_date date, p_end_date date, p_total_days integer, p_is_partial boolean, p_notes character varying, p_days jsonb DEFAULT NULL::jsonb)
 RETURNS TABLE("RequestId" bigint)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_request_id BIGINT;
BEGIN
    IF p_end_date < p_start_date THEN
        RAISE EXCEPTION 'La fecha fin no puede ser anterior a la fecha inicio.'
            USING ERRCODE = 'P0001';
    END IF;

    IF p_total_days <= 0 THEN
        RAISE EXCEPTION 'El total de dias debe ser mayor a cero.'
            USING ERRCODE = 'P0001';
    END IF;

    INSERT INTO hr."VacationRequest" (
        "CompanyId", "BranchId", "EmployeeCode",
        "StartDate", "EndDate", "TotalDays",
        "IsPartial", "Notes"
    )
    VALUES (
        p_company_id, p_branch_id, p_employee_code,
        p_start_date, p_end_date, p_total_days,
        p_is_partial, p_notes
    )
    RETURNING "RequestId" INTO v_request_id;

    -- Insertar dias desde JSONB: [{"dt":"2026-03-16", "tp":"COMPLETO"}, ...]
    IF p_days IS NOT NULL AND jsonb_array_length(p_days) > 0 THEN
        INSERT INTO hr."VacationRequestDay" ("RequestId", "SelectedDate", "DayType")
        SELECT
            v_request_id,
            (elem->>'dt')::DATE,
            COALESCE(NULLIF(elem->>'tp', ''::character varying), 'COMPLETO')::character varying
          FROM jsonb_array_elements(p_days) AS elem
         WHERE elem->>'dt' IS NOT NULL;
    END IF;

    RETURN QUERY SELECT v_request_id;
END;
$function$
;

-- usp_hr_vacation_request_get
CREATE OR REPLACE FUNCTION public.usp_hr_vacation_request_get(p_request_id bigint)
 RETURNS TABLE("RequestId" bigint, "CompanyId" integer, "BranchId" integer, "EmployeeCode" character varying, "EmployeeName" character varying, "RequestDate" character varying, "StartDate" character varying, "EndDate" character varying, "TotalDays" integer, "IsPartial" boolean, "Status" character varying, "Notes" character varying, "ApprovedBy" character varying, "ApprovalDate" timestamp without time zone, "RejectionReason" character varying, "VacationId" bigint, "CreatedAt" timestamp without time zone, "UpdatedAt" timestamp without time zone)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        vr."RequestId",
        vr."CompanyId",
        vr."BranchId",
        vr."EmployeeCode"::VARCHAR,
        COALESCE(e."EmployeeName", vr."EmployeeCode")::VARCHAR AS "EmployeeName",
        TO_CHAR(vr."RequestDate", 'YYYY-MM-DD')::VARCHAR       AS "RequestDate",
        TO_CHAR(vr."StartDate", 'YYYY-MM-DD')::VARCHAR         AS "StartDate",
        TO_CHAR(vr."EndDate", 'YYYY-MM-DD')::VARCHAR           AS "EndDate",
        vr."TotalDays",
        vr."IsPartial",
        vr."Status"::VARCHAR,
        vr."Notes"::VARCHAR,
        vr."ApprovedBy"::VARCHAR,
        vr."ApprovalDate",
        vr."RejectionReason"::VARCHAR,
        vr."VacationId",
        vr."CreatedAt",
        vr."UpdatedAt"
      FROM hr."VacationRequest" vr
      LEFT JOIN master."Employee" e
        ON e."CompanyId" = vr."CompanyId"
       AND e."EmployeeCode" = vr."EmployeeCode"
     WHERE vr."RequestId" = p_request_id;
END;
$function$
;

-- usp_hr_vacation_request_get_available_days
CREATE OR REPLACE FUNCTION public.usp_hr_vacation_request_get_available_days(p_company_id integer, p_employee_code character varying)
 RETURNS TABLE("DiasBase" integer, "AnosServicio" integer, "DiasAdicionales" integer, "DiasDisponibles" integer, "DiasTomados" integer, "DiasPendientes" integer, "DiasSaldo" integer)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_hire_date         DATE;
    v_anos_servicio     INT;
    v_dias_base         INT := 15;
    v_dias_adicionales  INT;
    v_dias_disponibles  INT;
    v_dias_tomados      INT;
    v_dias_pendientes   INT;
BEGIN
    SELECT e."HireDate"
      INTO v_hire_date
      FROM master."Employee" e
     WHERE e."CompanyId" = p_company_id
       AND e."EmployeeCode" = p_employee_code
       AND COALESCE(e."IsDeleted", FALSE) = FALSE;

    IF v_hire_date IS NULL THEN
        RETURN QUERY SELECT
            v_dias_base,
            0,
            0,
            v_dias_base,
            0,
            0,
            v_dias_base;
        RETURN;
    END IF;

    -- Calcular anos de servicio
    v_anos_servicio := EXTRACT(YEAR FROM age(NOW() AT TIME ZONE 'UTC', v_hire_date))::INT;
    IF v_anos_servicio < 0 THEN
        v_anos_servicio := 0;
    END IF;

    v_dias_adicionales := v_anos_servicio;
    v_dias_disponibles := v_dias_base + v_dias_adicionales;

    -- Dias ya procesados (disfrutados) en el ano actual
    SELECT COALESCE(SUM((vp."EndDate" - vp."StartDate") + 1), 0)
      INTO v_dias_tomados
      FROM hr."VacationProcess" vp
     WHERE vp."CompanyId" = p_company_id
       AND vp."EmployeeCode" = p_employee_code
       AND EXTRACT(YEAR FROM vp."StartDate") = EXTRACT(YEAR FROM (NOW() AT TIME ZONE 'UTC'));

    -- Dias en solicitudes pendientes o aprobadas
    SELECT COALESCE(SUM(vr."TotalDays"), 0)
      INTO v_dias_pendientes
      FROM hr."VacationRequest" vr
     WHERE vr."CompanyId" = p_company_id
       AND vr."EmployeeCode" = p_employee_code
       AND vr."Status" IN ('PENDIENTE', 'APROBADA');

    RETURN QUERY SELECT
        v_dias_base,
        v_anos_servicio,
        v_dias_adicionales,
        v_dias_disponibles,
        v_dias_tomados,
        v_dias_pendientes,
        (v_dias_disponibles - COALESCE(v_dias_tomados, 0) - COALESCE(v_dias_pendientes, 0));
END;
$function$
;

-- usp_hr_vacation_request_get_days
CREATE OR REPLACE FUNCTION public.usp_hr_vacation_request_get_days(p_request_id bigint)
 RETURNS TABLE("DayId" bigint, "RequestId" bigint, "SelectedDate" character varying, "DayType" character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        d."DayId",
        d."RequestId",
        TO_CHAR(d."SelectedDate", 'YYYY-MM-DD')::VARCHAR AS "SelectedDate",
        d."DayType"::VARCHAR
      FROM hr."VacationRequestDay" d
     WHERE d."RequestId" = p_request_id
     ORDER BY d."SelectedDate";
END;
$function$
;

-- usp_hr_vacation_request_list
CREATE OR REPLACE FUNCTION public.usp_hr_vacation_request_list(p_company_id integer, p_employee_code character varying DEFAULT NULL::character varying, p_status character varying DEFAULT NULL::character varying, p_offset integer DEFAULT 0, p_limit integer DEFAULT 50)
 RETURNS TABLE("RequestId" bigint, "EmployeeCode" character varying, "EmployeeName" character varying, "RequestDate" character varying, "StartDate" character varying, "EndDate" character varying, "TotalDays" integer, "IsPartial" boolean, "Status" character varying, "ApprovedBy" character varying, "Notes" character varying, "RejectionReason" character varying, "CreatedAt" timestamp without time zone, "TotalCount" integer)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_total_count INT;
BEGIN
    SELECT COUNT(*)
      INTO v_total_count
      FROM hr."VacationRequest" vr
     WHERE vr."CompanyId" = p_company_id
       AND (p_employee_code IS NULL OR vr."EmployeeCode" = p_employee_code)
       AND (p_status IS NULL OR vr."Status" = p_status);

    RETURN QUERY
    SELECT
        vr."RequestId",
        vr."EmployeeCode"::VARCHAR,
        COALESCE(e."EmployeeName", vr."EmployeeCode")::VARCHAR AS "EmployeeName",
        TO_CHAR(vr."RequestDate", 'YYYY-MM-DD')::VARCHAR       AS "RequestDate",
        TO_CHAR(vr."StartDate", 'YYYY-MM-DD')::VARCHAR         AS "StartDate",
        TO_CHAR(vr."EndDate", 'YYYY-MM-DD')::VARCHAR           AS "EndDate",
        vr."TotalDays",
        vr."IsPartial",
        vr."Status"::VARCHAR,
        vr."ApprovedBy"::VARCHAR,
        vr."Notes"::VARCHAR,
        vr."RejectionReason"::VARCHAR,
        vr."CreatedAt",
        v_total_count
      FROM hr."VacationRequest" vr
      LEFT JOIN master."Employee" e
        ON e."CompanyId" = vr."CompanyId"
       AND e."EmployeeCode" = vr."EmployeeCode"
     WHERE vr."CompanyId" = p_company_id
       AND (p_employee_code IS NULL OR vr."EmployeeCode" = p_employee_code)
       AND (p_status IS NULL OR vr."Status" = p_status)
     ORDER BY vr."RequestDate" DESC, vr."RequestId" DESC
     LIMIT p_limit
    OFFSET p_offset;
END;
$function$
;

-- usp_hr_vacation_request_process
CREATE OR REPLACE FUNCTION public.usp_hr_vacation_request_process(p_request_id bigint, p_vacation_id bigint)
 RETURNS TABLE("RequestId" bigint, "Status" character varying, "VacationId" bigint)
 LANGUAGE plpgsql
AS $function$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM hr."VacationRequest"
         WHERE "RequestId" = p_request_id AND "Status" = 'APROBADA'
    ) THEN
        RAISE EXCEPTION 'Solo se pueden procesar solicitudes en estado APROBADA.'
            USING ERRCODE = 'P0001';
    END IF;

    UPDATE hr."VacationRequest"
       SET "Status"     = 'PROCESADA',
           "VacationId" = p_vacation_id,
           "UpdatedAt"  = NOW() AT TIME ZONE 'UTC'
     WHERE "RequestId" = p_request_id
       AND "Status" = 'APROBADA';

    RETURN QUERY SELECT p_request_id, 'PROCESADA'::VARCHAR, p_vacation_id;
END;
$function$
;

-- usp_hr_vacation_request_reject
CREATE OR REPLACE FUNCTION public.usp_hr_vacation_request_reject(p_request_id bigint, p_approved_by character varying, p_rejection_reason character varying)
 RETURNS TABLE("RequestId" bigint, "Status" character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM hr."VacationRequest"
         WHERE "RequestId" = p_request_id AND "Status" = 'PENDIENTE'
    ) THEN
        RAISE EXCEPTION 'Solo se pueden rechazar solicitudes en estado PENDIENTE.'
            USING ERRCODE = 'P0001';
    END IF;

    UPDATE hr."VacationRequest"
       SET "Status"          = 'RECHAZADA',
           "ApprovedBy"      = p_approved_by,
           "ApprovalDate"    = NOW() AT TIME ZONE 'UTC',
           "RejectionReason" = p_rejection_reason,
           "UpdatedAt"       = NOW() AT TIME ZONE 'UTC'
     WHERE "RequestId" = p_request_id
       AND "Status" = 'PENDIENTE';

    RETURN QUERY SELECT p_request_id, 'RECHAZADA'::VARCHAR;
END;
$function$
;

