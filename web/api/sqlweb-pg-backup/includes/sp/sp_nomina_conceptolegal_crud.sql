-- ============================================================================
-- sp_nomina_conceptolegal_crud.sql
-- Funciones PostgreSQL para conceptos legales de nÃ³mina
-- Equivalentes a usp_HR_LegalConcept_* en SQL Server (usp_misc.sql)
-- ============================================================================

-- =============================================================================
-- 1. usp_HR_LegalConcept_List
--    Lista conceptos legales con filtros opcionales.
-- =============================================================================
-- Nuclear drop: query pg_proc to find ALL overloads and drop them
DO $$
DECLARE _oid OID;
BEGIN
  FOR _oid IN
    SELECT p.oid FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public' AND p.proname = 'usp_hr_legalconcept_list'
  LOOP
    EXECUTE format('DROP FUNCTION IF EXISTS %s CASCADE', _oid::regprocedure);
  END LOOP;
END $$;
CREATE OR REPLACE FUNCTION public.usp_hr_legalconcept_list(
    p_company_id       INT,
    p_convention_code  VARCHAR  DEFAULT NULL,
    p_calculation_type VARCHAR  DEFAULT NULL,
    p_concept_type     VARCHAR  DEFAULT NULL,
    p_solo_activos     INT      DEFAULT 1
)
RETURNS TABLE(
    "id"            BIGINT,
    "convencion"    VARCHAR,
    "tipoCalculo"   VARCHAR,
    "coConcept"     VARCHAR,
    "nbConcepto"    VARCHAR,
    "formula"       VARCHAR,
    "sobre"         VARCHAR,
    "tipo"          VARCHAR,
    "bonificable"   VARCHAR,
    "lotttArticulo" VARCHAR,
    "ccpClausula"   VARCHAR,
    "orden"         INT,
    "activo"        BOOLEAN
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        c."PayrollConceptId"::BIGINT,
        c."ConventionCode"::VARCHAR,
        c."CalculationType"::VARCHAR,
        c."ConceptCode"::VARCHAR,
        c."ConceptName"::VARCHAR,
        c."Formula"::VARCHAR,
        c."BaseExpression"::VARCHAR,
        c."ConceptType"::VARCHAR,
        CASE WHEN c."IsBonifiable" THEN 'S' ELSE 'N' END::VARCHAR,
        c."LotttArticle"::VARCHAR,
        c."CcpClause"::VARCHAR,
        c."SortOrder"::INT,
        c."IsActive"
    FROM hr."PayrollConcept" c
    WHERE c."CompanyId" = p_company_id
      AND c."ConventionCode" IS NOT NULL
      AND (p_solo_activos = 0 OR c."IsActive" = TRUE)
      AND (p_convention_code IS NULL OR c."ConventionCode" = p_convention_code)
      AND (p_calculation_type IS NULL OR c."CalculationType" = p_calculation_type)
      AND (p_concept_type IS NULL OR c."ConceptType" = p_concept_type)
    ORDER BY c."ConventionCode", c."CalculationType", c."SortOrder", c."ConceptCode";
END;
$$;

-- =============================================================================
-- 2. usp_HR_LegalConcept_ValidateFormulas
--    Retorna conceptos activos con su formula y default para validaciÃ³n.
-- =============================================================================
DROP FUNCTION IF EXISTS public.usp_hr_legalconcept_validateformulas(INT, VARCHAR(30), VARCHAR(30)) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_hr_legalconcept_validateformulas(
    p_company_id       INT,
    p_convention_code  VARCHAR(30)  DEFAULT NULL,
    p_calculation_type VARCHAR(30)  DEFAULT NULL
)
RETURNS TABLE(
    "coConcept"    VARCHAR(20),
    "nbConcepto"   VARCHAR(120),
    "formula"      VARCHAR(500),
    "defaultValue" NUMERIC(18,4)
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        c."ConceptCode",
        c."ConceptName",
        c."Formula",
        c."DefaultValue"
    FROM hr."PayrollConcept" c
    WHERE c."CompanyId" = p_company_id
      AND c."ConventionCode" IS NOT NULL
      AND c."IsActive" = TRUE
      AND (p_convention_code IS NULL OR c."ConventionCode" = p_convention_code)
      AND (p_calculation_type IS NULL OR c."CalculationType" = p_calculation_type)
    ORDER BY c."SortOrder", c."ConceptCode";
END;
$$;

-- =============================================================================
-- 3. usp_HR_LegalConcept_ListConventions
--    Resumen de convenciones disponibles con conteo por tipo de cÃ¡lculo.
-- =============================================================================
DROP FUNCTION IF EXISTS public.usp_hr_legalconcept_listconventions(INT) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_hr_legalconcept_listconventions(
    p_company_id INT
)
RETURNS TABLE(
    "Convencion"            VARCHAR(50),
    "TotalConceptos"        BIGINT,
    "ConceptosMensual"      BIGINT,
    "ConceptosVacaciones"   BIGINT,
    "ConceptosLiquidacion"  BIGINT,
    "OrdenInicio"           INT,
    "OrdenFin"              INT
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        c."ConventionCode",
        COUNT(1),
        COUNT(CASE WHEN c."CalculationType" = 'MENSUAL' THEN 1 END),
        COUNT(CASE WHEN c."CalculationType" = 'VACACIONES' THEN 1 END),
        COUNT(CASE WHEN c."CalculationType" = 'LIQUIDACION' THEN 1 END),
        MIN(c."SortOrder"),
        MAX(c."SortOrder")
    FROM hr."PayrollConcept" c
    WHERE c."CompanyId" = p_company_id
      AND c."IsActive" = TRUE
      AND c."ConventionCode" IS NOT NULL
    GROUP BY c."ConventionCode"
    ORDER BY c."ConventionCode";
END;
$$;

DO $$ BEGIN RAISE NOTICE 'sp_nomina_conceptolegal_crud.sql â€” funciones creadas'; END $$;
