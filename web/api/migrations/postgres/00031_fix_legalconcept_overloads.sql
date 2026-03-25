-- +goose Up
-- +goose StatementBegin
-- Fix: DROP ALL overloads of usp_hr_legalconcept_list to avoid "function is not unique"
-- The pg driver sends all params as 'unknown' type, so PG can't pick which overload to use.

-- Nuclear drop: query pg_proc to find ALL overloads and drop them
DO $$
DECLARE
  _oid OID;
BEGIN
  FOR _oid IN
    SELECT p.oid
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public'
      AND p.proname = 'usp_hr_legalconcept_list'
  LOOP
    EXECUTE format('DROP FUNCTION IF EXISTS %s CASCADE', _oid::regprocedure);
  END LOOP;
END $$;

-- Recreate single canonical version
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
LANGUAGE plpgsql AS $fn$
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
$fn$;
-- +goose StatementEnd

-- +goose Down
DROP FUNCTION IF EXISTS public.usp_hr_legalconcept_list(INT, VARCHAR, VARCHAR, VARCHAR, INT) CASCADE;
