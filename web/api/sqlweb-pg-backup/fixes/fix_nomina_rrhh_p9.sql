-- ============================================================
-- FIX SCRIPT PART 9: Final remaining fixes
-- Date: 2026-03-16
-- Agent: QA Agent 5
-- ============================================================

-- 1. Fix usp_hr_payroll_listconcepts: CASE WHEN returns TEXT, but TABLE declares VARCHAR
-- Add ::VARCHAR casts to all CASE expressions.
DROP FUNCTION IF EXISTS public.usp_hr_payroll_listconcepts(
    INTEGER, VARCHAR, VARCHAR, VARCHAR, INTEGER, INTEGER
) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_hr_payroll_listconcepts(
    p_company_id    INTEGER,
    p_payroll_code  VARCHAR(30)     DEFAULT NULL,
    p_concept_type  VARCHAR(15)     DEFAULT NULL,
    p_search        VARCHAR(200)    DEFAULT NULL,
    p_offset        INTEGER         DEFAULT 0,
    p_limit         INTEGER         DEFAULT 50
)
RETURNS TABLE(
    "TotalCount"    BIGINT,
    "codigo"        VARCHAR,
    "codigoNomina"  VARCHAR,
    "nombre"        VARCHAR,
    "formula"       VARCHAR,
    "sobre"         VARCHAR,
    "clase"         VARCHAR,
    "tipo"          VARCHAR,
    "uso"           VARCHAR,
    "bonificable"   VARCHAR,
    "esAntiguedad"  VARCHAR,
    "cuentaContable" VARCHAR,
    "aplica"        VARCHAR,
    "valorDefecto"  NUMERIC
)
LANGUAGE plpgsql AS $$
DECLARE
    v_total      BIGINT;
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
        pc."ConceptCode",
        pc."PayrollCode",
        pc."ConceptName",
        pc."Formula",
        pc."BaseExpression",
        pc."ConceptClass",
        pc."ConceptType",
        pc."UsageType",
        CASE WHEN pc."IsBonifiable" THEN 'S'::VARCHAR ELSE 'N'::VARCHAR END,
        CASE WHEN pc."IsSeniority"  THEN 'S'::VARCHAR ELSE 'N'::VARCHAR END,
        pc."AccountingAccountCode",
        CASE WHEN pc."AppliesFlag"  THEN 'S'::VARCHAR ELSE 'N'::VARCHAR END,
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
$$;


-- 2. Fix usp_hr_filing_list: service sends p_obligation_id (not p_legal_obligation_id)
--    and p_offset/p_limit (not p_page/p_limit).
-- Underlying function signature: p_company_id, p_legal_obligation_id, p_country_code,
--   p_status, p_from_date, p_to_date, p_page, p_limit
-- Wrapper receives: p_company_id, p_obligation_id, p_status, p_offset, p_limit
-- Strategy: Drop the 8-param version, create a 5-param wrapper with the full query inlined.

DROP FUNCTION IF EXISTS public.usp_hr_filing_list(
    INTEGER, INTEGER, CHAR, VARCHAR, DATE, DATE, INTEGER, INTEGER
) CASCADE;
DROP FUNCTION IF EXISTS public.usp_hr_filing_list(
    INTEGER, INTEGER, VARCHAR, INTEGER, INTEGER
) CASCADE;
DROP FUNCTION IF EXISTS public.usp_hr_filing_list_internal(
    INTEGER, INTEGER, CHAR, VARCHAR, DATE, DATE, INTEGER, INTEGER
) CASCADE;

CREATE OR REPLACE FUNCTION public.usp_hr_filing_list(
    p_company_id    INTEGER,
    p_obligation_id INTEGER     DEFAULT NULL,
    p_status        VARCHAR     DEFAULT NULL,
    p_offset        INTEGER     DEFAULT 0,
    p_limit         INTEGER     DEFAULT 50
)
RETURNS TABLE(
    p_total_count           BIGINT,
    "ObligationFilingId"    INTEGER,
    "CompanyId"             INTEGER,
    "LegalObligationId"     INTEGER,
    "CountryCode"           CHAR(2),
    "ObligationCode"        VARCHAR,
    "ObligationName"        VARCHAR,
    "InstitutionName"       VARCHAR,
    "FilingPeriodStart"     DATE,
    "FilingPeriodEnd"       DATE,
    "DueDate"               DATE,
    "FiledDate"             DATE,
    "ConfirmationNumber"    VARCHAR,
    "TotalEmployerAmount"   NUMERIC,
    "TotalEmployeeAmount"   NUMERIC,
    "TotalAmount"           NUMERIC,
    "EmployeeCount"         INTEGER,
    "Status"                VARCHAR,
    "CreatedAt"             TIMESTAMP
)
LANGUAGE plpgsql AS $$
BEGIN
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
    WHERE (p_company_id    IS NULL OR f."CompanyId"         = p_company_id)
      AND (p_obligation_id IS NULL OR f."LegalObligationId" = p_obligation_id)
      AND (p_status        IS NULL OR f."Status"            = p_status)
    ORDER BY f."FilingPeriodStart" DESC, lo."Code"
    LIMIT p_limit OFFSET p_offset;
END;
$$;


SELECT 'PART 9 FIXES APPLIED SUCCESSFULLY' AS status;
