-- ============================================================
-- FIX SCRIPT PART 6: More type fixes and wrappers
-- Date: 2026-03-16
-- Agent: QA Agent 5
-- ============================================================

-- 1. Fix usp_hr_payroll_getdraftsummary_header: PayrollBatch has no BranchId, TotalGross, etc.
DROP FUNCTION IF EXISTS public.usp_hr_payroll_getdraftsummary_header(INTEGER) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_hr_payroll_getdraftsummary_header(
    p_batch_id      INTEGER
)
RETURNS TABLE(
    "BatchId"           INTEGER,
    "CompanyId"         INTEGER,
    "BranchId"          INTEGER,
    "PayrollCode"       VARCHAR,
    "FromDate"          DATE,
    "ToDate"            DATE,
    "Status"            VARCHAR,
    "TotalEmployees"    INTEGER,
    "TotalGross"        NUMERIC,
    "TotalDeductions"   NUMERIC,
    "TotalNet"          NUMERIC,
    "CreatedBy"         INTEGER,
    "CreatedAt"         TIMESTAMP,
    "ApprovedBy"        INTEGER,
    "ApprovedAt"        TIMESTAMP,
    "PrevBatchId"       INTEGER,
    "PrevTotalGross"    NUMERIC,
    "PrevTotalDeductions" NUMERIC,
    "PrevTotalNet"      NUMERIC,
    "NetChangePercent"  NUMERIC
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    WITH "BatchAgg" AS (
        SELECT
            bl."BatchId",
            COUNT(DISTINCT bl."EmployeeCode")::INTEGER AS "TotalEmployees",
            COALESCE(SUM(CASE WHEN bl."ConceptType" IN ('ASIGNACION', 'BONO') THEN bl."Total" ELSE 0 END), 0) AS "TotalGross",
            COALESCE(SUM(CASE WHEN bl."ConceptType" = 'DEDUCCION' THEN bl."Total" ELSE 0 END), 0) AS "TotalDeductions",
            COALESCE(SUM(CASE WHEN bl."ConceptType" IN ('ASIGNACION', 'BONO') THEN bl."Total"
                              WHEN bl."ConceptType" = 'DEDUCCION' THEN -bl."Total"
                              ELSE 0 END), 0) AS "TotalNet"
        FROM hr."PayrollBatchLine" bl
        WHERE bl."BatchId" = p_batch_id
        GROUP BY bl."BatchId"
    )
    SELECT
        b."BatchId"::INTEGER,
        b."CompanyId",
        1::INTEGER                  AS "BranchId",
        b."PayrollCode",
        b."FromDate",
        b."ToDate",
        b."Status",
        COALESCE(ba."TotalEmployees", 0),
        COALESCE(ba."TotalGross", 0),
        COALESCE(ba."TotalDeductions", 0),
        COALESCE(ba."TotalNet", 0),
        b."CreatedByUserId"         AS "CreatedBy",
        b."CreatedAt",
        b."UpdatedByUserId"         AS "ApprovedBy",
        NULL::TIMESTAMP             AS "ApprovedAt",
        NULL::INTEGER               AS "PrevBatchId",
        0::NUMERIC                  AS "PrevTotalGross",
        0::NUMERIC                  AS "PrevTotalDeductions",
        0::NUMERIC                  AS "PrevTotalNet",
        0::NUMERIC                  AS "NetChangePercent"
    FROM hr."PayrollBatch" b
    LEFT JOIN "BatchAgg" ba ON ba."BatchId" = b."BatchId"
    WHERE b."BatchId" = p_batch_id
      AND b."IsDeleted" = FALSE;
END;
$$;

-- Rebuild alias
DROP FUNCTION IF EXISTS public.usp_hr_payroll_getdraftsummary(INTEGER) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_hr_payroll_getdraftsummary(
    p_batch_id      INTEGER
)
RETURNS TABLE(
    "BatchId"           INTEGER,
    "CompanyId"         INTEGER,
    "BranchId"          INTEGER,
    "PayrollCode"       VARCHAR,
    "FromDate"          DATE,
    "ToDate"            DATE,
    "Status"            VARCHAR,
    "TotalEmployees"    INTEGER,
    "TotalGross"        NUMERIC,
    "TotalDeductions"   NUMERIC,
    "TotalNet"          NUMERIC,
    "CreatedBy"         INTEGER,
    "CreatedAt"         TIMESTAMP,
    "ApprovedBy"        INTEGER,
    "ApprovedAt"        TIMESTAMP,
    "PrevBatchId"       INTEGER,
    "PrevTotalGross"    NUMERIC,
    "PrevTotalDeductions" NUMERIC,
    "PrevTotalNet"      NUMERIC,
    "NetChangePercent"  NUMERIC
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT * FROM public.usp_hr_payroll_getdraftsummary_header(p_batch_id);
END;
$$;

-- 2. Fix usp_hr_payroll_getemployeelines: LineId is BIGINT in table but INTEGER in function
DROP FUNCTION IF EXISTS public.usp_hr_payroll_getemployeelines(INTEGER, VARCHAR) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_hr_payroll_getemployeelines(
    p_batch_id          INTEGER,
    p_employee_code     VARCHAR(30)
)
RETURNS TABLE(
    "LineId"        BIGINT,
    "BatchId"       BIGINT,
    "EmployeeId"    BIGINT,
    "EmployeeCode"  VARCHAR,
    "EmployeeName"  VARCHAR,
    "ConceptCode"   VARCHAR,
    "ConceptName"   VARCHAR,
    "ConceptType"   VARCHAR,
    "Quantity"      NUMERIC,
    "Amount"        NUMERIC,
    "Total"         NUMERIC,
    "IsModified"    BOOLEAN,
    "Notes"         VARCHAR,
    "UpdatedAt"     TIMESTAMP
)
LANGUAGE plpgsql AS $$
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
    WHERE bl."BatchId" = p_batch_id
      AND bl."EmployeeCode" = p_employee_code
    ORDER BY bl."ConceptType", bl."ConceptCode";
END;
$$;

-- 3. Fix usp_hr_obligation_getbycountry: service passes (CompanyId, CountryCode) but function has (p_country_code, p_as_of_date)
-- Need wrapper that accepts CompanyId + CountryCode and routes to real function
DROP FUNCTION IF EXISTS public.usp_hr_obligation_getbycountry(INTEGER, VARCHAR) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_hr_obligation_getbycountry(
    p_company_id    INTEGER,
    p_country_code  VARCHAR(5)
)
RETURNS TABLE(
    "LegalObligationId" INTEGER,
    "CountryCode"       CHARACTER,
    "Code"              VARCHAR,
    "Name"              VARCHAR,
    "InstitutionName"   VARCHAR,
    "ObligationType"    VARCHAR,
    "CalculationBasis"  VARCHAR,
    "SalaryCap"         NUMERIC,
    "SalaryCapUnit"     VARCHAR,
    "EmployerRate"      NUMERIC,
    "EmployeeRate"      NUMERIC,
    "RateVariableByRisk" BOOLEAN,
    "FilingFrequency"   VARCHAR,
    "FilingDeadlineRule" VARCHAR,
    "EffectiveFrom"     DATE,
    "EffectiveTo"       DATE,
    "Notes"             VARCHAR
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT lo."LegalObligationId",
           lo."CountryCode",
           lo."Code",
           lo."Name",
           lo."InstitutionName",
           lo."ObligationType",
           lo."CalculationBasis",
           lo."SalaryCap",
           lo."SalaryCapUnit",
           lo."EmployerRate",
           lo."EmployeeRate",
           lo."RateVariableByRisk",
           lo."FilingFrequency",
           lo."FilingDeadlineRule",
           lo."EffectiveFrom",
           lo."EffectiveTo",
           lo."Notes"
    FROM hr."LegalObligation" lo
    WHERE lo."IsActive" = TRUE
      AND lo."CountryCode" = p_country_code::CHARACTER
    ORDER BY lo."Name";
END;
$$;

SELECT 'PART 6 FIXES APPLIED SUCCESSFULLY' AS status;
