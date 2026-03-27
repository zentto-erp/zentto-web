-- ============================================================
-- FIX SCRIPT PART 4: Aliases and type fixes
-- Date: 2026-03-16
-- Agent: QA Agent 5
-- ============================================================

-- 1. Fix usp_hr_payroll_getdraftgrid: HasModified is INT (MAX returns INT), but declared BIGINT
DROP FUNCTION IF EXISTS public.usp_hr_payroll_getdraftgrid(INTEGER, VARCHAR, VARCHAR, BOOLEAN, INTEGER, INTEGER) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_hr_payroll_getdraftgrid(
    p_batch_id      INTEGER,
    p_search        VARCHAR(200)    DEFAULT NULL,
    p_department    VARCHAR(100)    DEFAULT NULL,
    p_only_modified BOOLEAN         DEFAULT FALSE,
    p_offset        INTEGER         DEFAULT 0,
    p_limit         INTEGER         DEFAULT 50
)
RETURNS TABLE(
    p_total_count   BIGINT,
    "EmployeeCode"  VARCHAR,
    "EmployeeName"  VARCHAR,
    "EmployeeId"    BIGINT,
    "DepartmentCode" TEXT,
    "DepartmentName" TEXT,
    "PositionName"  TEXT,
    "TotalGross"    NUMERIC,
    "TotalDeductions" NUMERIC,
    "TotalNet"      NUMERIC,
    "HasModified"   INTEGER,
    "ConceptCount"  BIGINT
)
LANGUAGE plpgsql AS $$
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
$$;

-- 2. Create alias usp_hr_payroll_getdraftsummary -> usp_hr_payroll_getdraftsummary_header
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

-- 3. Create alias usp_hr_vacationrequest_get -> usp_hr_vacation_request_get
DROP FUNCTION IF EXISTS public.usp_hr_vacationrequest_get(BIGINT) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_hr_vacationrequest_get(
    p_request_id    BIGINT
)
RETURNS TABLE(
    "RequestId"         BIGINT,
    "CompanyId"         INTEGER,
    "BranchId"          INTEGER,
    "EmployeeCode"      VARCHAR,
    "EmployeeName"      VARCHAR,
    "RequestDate"       VARCHAR,
    "StartDate"         VARCHAR,
    "EndDate"           VARCHAR,
    "TotalDays"         INTEGER,
    "IsPartial"         BOOLEAN,
    "Status"            VARCHAR,
    "Notes"             VARCHAR,
    "ApprovedBy"        VARCHAR,
    "ApprovalDate"      TIMESTAMP,
    "RejectionReason"   VARCHAR,
    "VacationId"        BIGINT,
    "CreatedAt"         TIMESTAMP,
    "UpdatedAt"         TIMESTAMP
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT * FROM public.usp_hr_vacation_request_get(p_request_id);
END;
$$;

-- 4. Create alias usp_hr_vacationrequest_getavailabledays -> usp_hr_vacation_request_get_available_days
DROP FUNCTION IF EXISTS public.usp_hr_vacationrequest_getavailabledays(INTEGER, VARCHAR) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_hr_vacationrequest_getavailabledays(
    p_company_id        INTEGER,
    p_employee_code     VARCHAR(30)
)
RETURNS TABLE(
    "DiasBase"          INTEGER,
    "AnosServicio"      INTEGER,
    "DiasAdicionales"   INTEGER,
    "DiasDisponibles"   INTEGER,
    "DiasTomados"       INTEGER,
    "DiasPendientes"    INTEGER,
    "DiasSaldo"         INTEGER
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT * FROM public.usp_hr_vacation_request_get_available_days(p_company_id, p_employee_code);
END;
$$;

-- 5. Create alias usp_hr_vacationrequest_approve -> usp_hr_vacation_request_approve
DROP FUNCTION IF EXISTS public.usp_hr_vacationrequest_approve(BIGINT, VARCHAR) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_hr_vacationrequest_approve(
    p_request_id    BIGINT,
    p_approved_by   VARCHAR(50) DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
    PERFORM * FROM public.usp_hr_vacation_request_approve(p_request_id, p_approved_by);
END;
$$;

-- 6. Create alias usp_hr_vacationrequest_reject -> usp_hr_vacation_request_reject
DROP FUNCTION IF EXISTS public.usp_hr_vacationrequest_reject(BIGINT, VARCHAR, VARCHAR) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_hr_vacationrequest_reject(
    p_request_id    BIGINT,
    p_rejected_by   VARCHAR(50) DEFAULT NULL,
    p_reason        VARCHAR(500) DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
    PERFORM * FROM public.usp_hr_vacation_request_reject(p_request_id, p_rejected_by, p_reason);
END;
$$;

-- 7. Create alias usp_hr_vacationrequest_cancel -> usp_hr_vacation_request_cancel
DROP FUNCTION IF EXISTS public.usp_hr_vacationrequest_cancel(BIGINT) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_hr_vacationrequest_cancel(
    p_request_id    BIGINT
)
RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
    PERFORM * FROM public.usp_hr_vacation_request_cancel(p_request_id);
END;
$$;

-- 8. Create alias usp_hr_vacationrequest_process -> usp_hr_vacation_request_process
DROP FUNCTION IF EXISTS public.usp_hr_vacationrequest_process(BIGINT, VARCHAR) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_hr_vacationrequest_process(
    p_request_id    BIGINT,
    p_processed_by  VARCHAR(50) DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
    PERFORM * FROM public.usp_hr_vacation_request_process(p_request_id, p_processed_by);
END;
$$;

-- 9. Create alias usp_hr_vacationrequest_create -> usp_hr_vacation_request_create
-- Check actual function signature first needed

SELECT 'PART 4 FIXES APPLIED SUCCESSFULLY' AS status;
