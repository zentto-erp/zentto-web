-- =============================================
-- ADAPTADOR CONCEPTO LEGAL -> MODELO CANONICO - PostgreSQL
-- Base: hr."PayrollConcept" (ConventionCode/CalculationType)
-- Traducido de SQL Server a PostgreSQL
-- =============================================

-- =============================================
-- Vista: vw_ConceptosPorRegimen
-- =============================================
CREATE OR REPLACE VIEW vw_conceptos_por_regimen AS
SELECT
  pc."PayrollConceptId" AS "Id",
  pc."ConventionCode" AS "Convencion",
  pc."CalculationType" AS "TipoCalculo",
  pc."ConceptCode" AS "CO_CONCEPT",
  pc."ConceptName" AS "NB_CONCEPTO",
  pc."Formula" AS "FORMULA",
  pc."BaseExpression" AS "SOBRE",
  pc."ConceptType" AS "TIPO",
  CASE WHEN pc."IsBonifiable" = TRUE THEN 'S' ELSE 'N' END AS "BONIFICABLE",
  pc."LotttArticle" AS "LOTTT_Articulo",
  pc."CcpClause" AS "CCP_Clausula",
  pc."SortOrder" AS "Orden",
  pc."IsActive" AS "Activo",
  pc."PayrollCode" AS "CO_NOMINA",
  pc."CompanyId"
FROM hr."PayrollConcept" pc
WHERE pc."ConventionCode" IS NOT NULL;

-- =============================================
-- Funcion: sp_Nomina_CargarConstantesDesdeConceptoLegal
-- =============================================
CREATE OR REPLACE FUNCTION sp_nomina_cargar_constantes_desde_concepto_legal(
  p_session_id VARCHAR(80),
  p_convencion VARCHAR(50) DEFAULT 'LOT',
  p_tipo_calculo VARCHAR(50) DEFAULT 'MENSUAL'
)
RETURNS VOID
LANGUAGE plpgsql AS $$
DECLARE
  v_regimen VARCHAR(10) := UPPER(LEFT(COALESCE(p_convencion, 'LOT'), 10));
  v_tipo_nomina VARCHAR(15) := UPPER(CASE WHEN p_tipo_calculo IN ('SEMANAL', 'QUINCENAL') THEN p_tipo_calculo ELSE 'MENSUAL' END);
BEGIN
  PERFORM sp_nomina_cargar_constantes_regimen(p_session_id, v_regimen, v_tipo_nomina);
END;
$$;

-- =============================================
-- Funcion: sp_Nomina_ProcesarEmpleadoConceptoLegal
-- =============================================
CREATE OR REPLACE FUNCTION sp_nomina_procesar_empleado_concepto_legal(
  p_nomina VARCHAR(20),
  p_cedula VARCHAR(32),
  p_fecha_inicio DATE,
  p_fecha_hasta DATE,
  p_convencion VARCHAR(50) DEFAULT NULL,
  p_tipo_calculo VARCHAR(50) DEFAULT 'MENSUAL',
  p_co_usuario VARCHAR(50) DEFAULT 'API',
  OUT p_resultado INT,
  OUT p_mensaje VARCHAR(500)
)
RETURNS RECORD
LANGUAGE plpgsql AS $$
DECLARE
  v_regimen VARCHAR(10) := UPPER(COALESCE(p_convencion, p_nomina));
BEGIN
  SELECT r.p_resultado, r.p_mensaje
  INTO p_resultado, p_mensaje
  FROM sp_nomina_procesar_empleado_regimen(
    p_nomina, p_cedula, p_fecha_inicio, p_fecha_hasta, v_regimen, p_co_usuario
  ) r;
END;
$$;

-- =============================================
-- Funcion: sp_Nomina_ConceptosLegales_List
-- =============================================
CREATE OR REPLACE FUNCTION sp_nomina_conceptos_legales_list(
  p_convencion VARCHAR(50) DEFAULT NULL,
  p_tipo_calculo VARCHAR(50) DEFAULT NULL,
  p_tipo VARCHAR(15) DEFAULT NULL,
  p_activo BOOLEAN DEFAULT TRUE
)
RETURNS TABLE (
  "Id" BIGINT,
  "Convencion" VARCHAR,
  "TipoCalculo" VARCHAR,
  "CO_CONCEPT" VARCHAR,
  "NB_CONCEPTO" VARCHAR,
  "Formula" TEXT,
  "SOBRE" TEXT,
  "TIPO" VARCHAR,
  "BONIFICABLE" VARCHAR(1),
  "LOTTT_Articulo" VARCHAR,
  "CCP_Clausula" VARCHAR,
  "Orden" INT,
  "Activo" BOOLEAN,
  "CO_NOMINA" VARCHAR
)
LANGUAGE plpgsql AS $$
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
$$;

-- =============================================
-- Funcion: sp_Nomina_ValidarFormulasConceptoLegal
-- =============================================
CREATE OR REPLACE FUNCTION sp_nomina_validar_formulas_concepto_legal(
  p_convencion VARCHAR(50) DEFAULT NULL,
  p_tipo_calculo VARCHAR(50) DEFAULT NULL
)
RETURNS TABLE (
  "Id" BIGINT,
  "CO_CONCEPT" VARCHAR,
  "NB_CONCEPTO" VARCHAR,
  "FORMULA" TEXT,
  "Error" VARCHAR(500),
  "EsValida" BOOLEAN
)
LANGUAGE plpgsql AS $$
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
$$;
