-- =============================================
-- CALCULO POR REGIMEN (CANONICO) - PostgreSQL
-- Traducido de SQL Server a PostgreSQL
-- =============================================

-- =============================================
-- Funcion: sp_Nomina_CargarConstantesRegimen
-- =============================================
DROP FUNCTION IF EXISTS sp_nomina_cargar_constantes_regimen(VARCHAR(80), VARCHAR(10), VARCHAR(15)) CASCADE;
CREATE OR REPLACE FUNCTION sp_nomina_cargar_constantes_regimen(
  p_session_id VARCHAR(80),
  p_regimen VARCHAR(10) DEFAULT 'LOT',
  p_tipo_nomina VARCHAR(15) DEFAULT 'MENSUAL'
)
RETURNS VOID
LANGUAGE plpgsql AS $$
DECLARE
  v_company_id INT;
  v_branch_id INT;
  v_prefix VARCHAR(20) := UPPER(COALESCE(p_regimen, 'LOT')) || '_';
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

  IF UPPER(p_tipo_nomina) = 'SEMANAL' THEN
    PERFORM sp_nomina_set_variable(p_session_id, 'DIAS_PERIODO', 7, 'Dias periodo semanal');
  ELSIF UPPER(p_tipo_nomina) = 'QUINCENAL' THEN
    PERFORM sp_nomina_set_variable(p_session_id, 'DIAS_PERIODO', 15, 'Dias periodo quincenal');
  END IF;
END;
$$;

-- =============================================
-- Funcion: sp_Nomina_CalcularVacacionesRegimen
-- =============================================
DROP FUNCTION IF EXISTS sp_nomina_calcular_vacaciones_regimen(VARCHAR(80), VARCHAR(10), INT, INT, NUMERIC(18,6), NUMERIC(18,6), NUMERIC(18,6)) CASCADE;
CREATE OR REPLACE FUNCTION sp_nomina_calcular_vacaciones_regimen(
  p_session_id VARCHAR(80),
  p_regimen VARCHAR(10),
  p_anios_servicio INT,
  p_meses_periodo INT DEFAULT 12,
  OUT p_dias_vacaciones NUMERIC(18,6),
  OUT p_dias_bono_vacacional NUMERIC(18,6),
  OUT p_dias_bono_post_vacacional NUMERIC(18,6)
)
RETURNS RECORD
LANGUAGE plpgsql AS $$
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
$$;

-- =============================================
-- Funcion: sp_Nomina_CalcularUtilidadesRegimen
-- =============================================
DROP FUNCTION IF EXISTS sp_nomina_calcular_utilidades_regimen(VARCHAR(80), VARCHAR(10), INT, NUMERIC(18,6), NUMERIC(18,6)) CASCADE;
CREATE OR REPLACE FUNCTION sp_nomina_calcular_utilidades_regimen(
  p_session_id VARCHAR(80),
  p_regimen VARCHAR(10),
  p_dias_trabajados_ano INT,
  p_salario_normal NUMERIC(18,6),
  OUT p_utilidades NUMERIC(18,6)
)
RETURNS NUMERIC(18,6)
LANGUAGE plpgsql AS $$
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
$$;

-- =============================================
-- Funcion: sp_Nomina_CalcularPrestacionesRegimen
-- =============================================
DROP FUNCTION IF EXISTS sp_nomina_calcular_prestaciones_regimen(VARCHAR(80), VARCHAR(10), INT, INT, NUMERIC(18,6), NUMERIC(18,6), NUMERIC(18,6)) CASCADE;
CREATE OR REPLACE FUNCTION sp_nomina_calcular_prestaciones_regimen(
  p_session_id VARCHAR(80),
  p_regimen VARCHAR(10),
  p_anios_servicio INT,
  p_meses_adicionales INT,
  p_salario_integral NUMERIC(18,6),
  OUT p_prestaciones NUMERIC(18,6),
  OUT p_intereses NUMERIC(18,6)
)
RETURNS RECORD
LANGUAGE plpgsql AS $$
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
$$;

-- =============================================
-- Funcion: sp_Nomina_PrepararVariablesRegimen
-- =============================================
DROP FUNCTION IF EXISTS sp_nomina_preparar_variables_regimen(VARCHAR(80), VARCHAR(32), VARCHAR(20), VARCHAR(15), VARCHAR(10), DATE, DATE) CASCADE;
CREATE OR REPLACE FUNCTION sp_nomina_preparar_variables_regimen(
  p_session_id VARCHAR(80),
  p_cedula VARCHAR(32),
  p_nomina VARCHAR(20),
  p_tipo_nomina VARCHAR(15),
  p_regimen VARCHAR(10) DEFAULT NULL,
  p_fecha_inicio DATE DEFAULT NULL,
  p_fecha_hasta DATE DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql AS $$
DECLARE
  v_reg VARCHAR(10) := UPPER(COALESCE(p_regimen, p_nomina));
BEGIN
  IF v_reg = '' THEN v_reg := 'LOT'; END IF;

  PERFORM sp_nomina_preparar_variables_base(p_session_id, p_cedula, p_nomina, p_fecha_inicio, p_fecha_hasta);
  PERFORM sp_nomina_cargar_constantes_regimen(p_session_id, v_reg, p_tipo_nomina);
END;
$$;

-- =============================================
-- Funcion: sp_Nomina_ProcesarEmpleadoRegimen
-- =============================================
DROP FUNCTION IF EXISTS sp_nomina_procesar_empleado_regimen(VARCHAR(20), VARCHAR(32), DATE, DATE, VARCHAR(10), VARCHAR(50), INT, VARCHAR(500)) CASCADE;
CREATE OR REPLACE FUNCTION sp_nomina_procesar_empleado_regimen(
  p_nomina VARCHAR(20),
  p_cedula VARCHAR(32),
  p_fecha_inicio DATE,
  p_fecha_hasta DATE,
  p_regimen VARCHAR(10) DEFAULT NULL,
  p_co_usuario VARCHAR(50) DEFAULT 'API',
  OUT p_resultado INT,
  OUT p_mensaje VARCHAR(500)
)
RETURNS RECORD
LANGUAGE plpgsql AS $$
DECLARE
  v_reg VARCHAR(10) := UPPER(COALESCE(p_regimen, p_nomina));
  v_tipo_calculo VARCHAR(20) := 'MENSUAL';
  v_session_id VARCHAR(80) := p_nomina || '_' || p_cedula || '_' || to_char(NOW() AT TIME ZONE 'UTC', 'YYYYMMDD');
  v_nomina_proceso VARCHAR(20);
BEGIN
  IF UPPER(p_nomina) LIKE '%VAC%' THEN v_tipo_calculo := 'VACACIONES'; END IF;
  IF UPPER(p_nomina) LIKE '%LIQ%' THEN v_tipo_calculo := 'LIQUIDACION'; END IF;

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
$$;
