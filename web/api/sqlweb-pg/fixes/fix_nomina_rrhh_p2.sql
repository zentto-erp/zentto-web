-- ============================================================
-- FIX SCRIPT PART 2: Remaining Nomina/RRHH Issues
-- Date: 2026-03-16
-- Agent: QA Agent 5
-- ============================================================

-- 1. Fix usp_hr_profitsharing_list: ambiguous ProfitSharingId in subqueries
DROP FUNCTION IF EXISTS public.usp_hr_profitsharing_list(INTEGER, INTEGER, VARCHAR, INTEGER, INTEGER) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_hr_profitsharing_list(
    p_company_id    INTEGER,
    p_year          INTEGER         DEFAULT NULL,
    p_status        VARCHAR(20)     DEFAULT NULL,
    p_offset        INTEGER         DEFAULT 0,
    p_limit         INTEGER         DEFAULT 50
)
RETURNS TABLE(
    p_total_count           BIGINT,
    "ProfitSharingId"       INTEGER,
    "CompanyId"             INTEGER,
    "BranchId"              INTEGER,
    "FiscalYear"            INTEGER,
    "DaysGranted"           INTEGER,
    "TotalCompanyProfits"   NUMERIC,
    "Status"                VARCHAR,
    "CreatedBy"             INTEGER,
    "CreatedAt"             TIMESTAMP,
    "ApprovedBy"            INTEGER,
    "ApprovedAt"            TIMESTAMP,
    "UpdatedAt"             TIMESTAMP,
    "TotalEmployees"        BIGINT,
    "TotalNet"              NUMERIC
)
LANGUAGE plpgsql AS $$
DECLARE
    v_ps_id INTEGER;
BEGIN
    RETURN QUERY
    SELECT
        COUNT(*) OVER()             AS p_total_count,
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
        (SELECT COUNT(*) FROM hr."ProfitSharingLine" psl WHERE psl."ProfitSharingId" = ps."ProfitSharingId")::BIGINT AS "TotalEmployees",
        COALESCE((SELECT SUM(psl2."NetAmount") FROM hr."ProfitSharingLine" psl2 WHERE psl2."ProfitSharingId" = ps."ProfitSharingId"), 0) AS "TotalNet"
    FROM hr."ProfitSharing" ps
    WHERE ps."CompanyId" = p_company_id
      AND (p_year   IS NULL OR ps."FiscalYear" = p_year)
      AND (p_status IS NULL OR ps."Status"     = p_status)
    ORDER BY ps."FiscalYear" DESC, ps."CreatedAt" DESC
    LIMIT p_limit OFFSET p_offset;
END;
$$;

-- 2. Fix usp_hr_payroll_listbatches: column LineId not BatchLineId
DROP FUNCTION IF EXISTS public.usp_hr_payroll_listbatches(INTEGER, VARCHAR, VARCHAR, INTEGER, INTEGER) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_hr_payroll_listbatches(
    p_company_id    INTEGER,
    p_payroll_code  VARCHAR(20)     DEFAULT NULL,
    p_status        VARCHAR(20)     DEFAULT NULL,
    p_offset        INTEGER         DEFAULT 0,
    p_limit         INTEGER         DEFAULT 25
)
RETURNS TABLE(
    p_total_count       BIGINT,
    "BatchId"           BIGINT,
    "CompanyId"         INTEGER,
    "BranchId"          INTEGER,
    "PayrollCode"       VARCHAR,
    "FromDate"          DATE,
    "ToDate"            DATE,
    "Status"            VARCHAR,
    "TotalEmployees"    BIGINT,
    "TotalGross"        NUMERIC,
    "TotalDeductions"   NUMERIC,
    "TotalNet"          NUMERIC,
    "CreatedBy"         INTEGER,
    "CreatedAt"         TIMESTAMP,
    "ApprovedBy"        INTEGER,
    "ApprovedAt"        TIMESTAMP,
    "UpdatedAt"         TIMESTAMP
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        COUNT(*) OVER()             AS p_total_count,
        b."BatchId",
        b."CompanyId",
        1::INTEGER                  AS "BranchId",
        b."PayrollCode",
        b."FromDate",
        b."ToDate",
        b."Status",
        COUNT(bl."LineId")          AS "TotalEmployees",
        COALESCE(SUM(CASE WHEN bl."ConceptType" = 'ASIGNACION' THEN bl."Amount" ELSE 0 END), 0) AS "TotalGross",
        COALESCE(SUM(CASE WHEN bl."ConceptType" = 'DEDUCCION'  THEN bl."Amount" ELSE 0 END), 0) AS "TotalDeductions",
        COALESCE(SUM(CASE WHEN bl."ConceptType" = 'ASIGNACION' THEN bl."Amount"
                          WHEN bl."ConceptType" = 'DEDUCCION'  THEN -bl."Amount"
                          ELSE 0 END), 0) AS "TotalNet",
        b."CreatedByUserId"         AS "CreatedBy",
        b."CreatedAt",
        b."UpdatedByUserId"         AS "ApprovedBy",
        NULL::TIMESTAMP             AS "ApprovedAt",
        b."UpdatedAt"
    FROM hr."PayrollBatch" b
    LEFT JOIN hr."PayrollBatchLine" bl ON bl."BatchId" = b."BatchId"
    WHERE b."CompanyId" = p_company_id
      AND b."IsDeleted" = FALSE
      AND (p_payroll_code IS NULL OR b."PayrollCode" = p_payroll_code)
      AND (p_status       IS NULL OR b."Status"      = p_status)
    GROUP BY b."BatchId", b."CompanyId", b."PayrollCode", b."FromDate", b."ToDate",
             b."Status", b."CreatedByUserId", b."CreatedAt", b."UpdatedByUserId", b."UpdatedAt"
    ORDER BY b."CreatedAt" DESC
    OFFSET p_offset
    LIMIT p_limit;
END;
$$;

-- 3. Fix usp_hr_savings_list: column names are EmployeeContribution and EmployerMatch (not Pct)
DROP FUNCTION IF EXISTS public.usp_hr_savings_list(INTEGER, VARCHAR, INTEGER, INTEGER) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_hr_savings_list(
    p_company_id    INTEGER,
    p_search        VARCHAR(200)    DEFAULT NULL,
    p_offset        INTEGER         DEFAULT 0,
    p_limit         INTEGER         DEFAULT 50
)
RETURNS TABLE(
    p_total_count           BIGINT,
    "SavingsFundId"         INTEGER,
    "EmployeeId"            BIGINT,
    "EmployeeCode"          VARCHAR,
    "EmployeeName"          VARCHAR,
    "EmployeeContribution"  NUMERIC,
    "EmployerMatch"         NUMERIC,
    "EnrollmentDate"        DATE,
    "Status"                VARCHAR,
    "CreatedAt"             TIMESTAMP,
    "CurrentBalance"        NUMERIC
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        COUNT(*) OVER()             AS p_total_count,
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
            SELECT SUM(sft."Amount")
            FROM hr."SavingsFundTransaction" sft
            WHERE sft."SavingsFundId" = sf."SavingsFundId"
        ), 0) AS "CurrentBalance"
    FROM hr."SavingsFund" sf
    WHERE sf."CompanyId" = p_company_id
      AND (
          p_search IS NULL
          OR sf."EmployeeCode" ILIKE '%' || p_search || '%'
          OR sf."EmployeeName" ILIKE '%' || p_search || '%'
      )
    ORDER BY sf."EmployeeName"
    LIMIT p_limit OFFSET p_offset;
END;
$$;

-- 4. Fix usp_hr_committee_list: ambiguous SafetyCommitteeId in subqueries
DROP FUNCTION IF EXISTS public.usp_hr_committee_list(INTEGER, VARCHAR, INTEGER, INTEGER) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_hr_committee_list(
    p_company_id    INTEGER,
    p_search        VARCHAR(200)    DEFAULT NULL,
    p_offset        INTEGER         DEFAULT 0,
    p_limit         INTEGER         DEFAULT 50
)
RETURNS TABLE(
    p_total_count       BIGINT,
    "SafetyCommitteeId" INTEGER,
    "CompanyId"         INTEGER,
    "CountryCode"       CHARACTER,
    "CommitteeName"     VARCHAR,
    "FormationDate"     DATE,
    "MeetingFrequency"  VARCHAR,
    "IsActive"          BOOLEAN,
    "CreatedAt"         TIMESTAMP,
    "ActiveMemberCount" BIGINT,
    "TotalMeetings"     BIGINT
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        COUNT(*) OVER()             AS p_total_count,
        sc."SafetyCommitteeId",
        sc."CompanyId",
        sc."CountryCode",
        sc."CommitteeName",
        sc."FormationDate",
        sc."MeetingFrequency",
        sc."IsActive",
        sc."CreatedAt",
        (SELECT COUNT(*) FROM hr."SafetyCommitteeMember" scm WHERE scm."SafetyCommitteeId" = sc."SafetyCommitteeId" AND scm."IsActive" = TRUE)::BIGINT AS "ActiveMemberCount",
        (SELECT COUNT(*) FROM hr."SafetyCommitteeMeeting" scmt WHERE scmt."SafetyCommitteeId" = sc."SafetyCommitteeId")::BIGINT AS "TotalMeetings"
    FROM hr."SafetyCommittee" sc
    WHERE sc."CompanyId" = p_company_id
      AND (
          p_search IS NULL
          OR sc."CommitteeName" ILIKE '%' || p_search || '%'
      )
    ORDER BY sc."CommitteeName"
    LIMIT p_limit OFFSET p_offset;
END;
$$;

-- 5. Fix usp_hr_occhealth_list: Description is TEXT, cast to VARCHAR
DROP FUNCTION IF EXISTS public.usp_hr_occhealth_list(INTEGER, VARCHAR, VARCHAR, INTEGER, INTEGER) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_hr_occhealth_list(
    p_company_id        INTEGER,
    p_employee_code     VARCHAR(30)     DEFAULT NULL,
    p_record_type       VARCHAR(50)     DEFAULT NULL,
    p_offset            INTEGER         DEFAULT 0,
    p_limit             INTEGER         DEFAULT 50
)
RETURNS TABLE(
    p_total_count               BIGINT,
    "OccupationalHealthId"      INTEGER,
    "CompanyId"                 INTEGER,
    "CountryCode"               CHARACTER,
    "RecordType"                VARCHAR,
    "EmployeeId"                BIGINT,
    "EmployeeCode"              VARCHAR,
    "EmployeeName"              VARCHAR,
    "OccurrenceDate"            TIMESTAMP,
    "ReportDeadline"            TIMESTAMP,
    "ReportedDate"              TIMESTAMP,
    "Severity"                  VARCHAR,
    "BodyPartAffected"          VARCHAR,
    "DaysLost"                  INTEGER,
    "Location"                  VARCHAR,
    "Description"               TEXT,
    "RootCause"                 VARCHAR,
    "CorrectiveAction"          VARCHAR,
    "InvestigationDueDate"      DATE,
    "InvestigationCompletedDate" DATE,
    "InstitutionReference"      VARCHAR,
    "Status"                    VARCHAR,
    "DocumentUrl"               VARCHAR,
    "Notes"                     VARCHAR,
    "CreatedBy"                 INTEGER,
    "CreatedAt"                 TIMESTAMP,
    "UpdatedAt"                 TIMESTAMP
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        COUNT(*) OVER()             AS p_total_count,
        oh."OccupationalHealthId",
        oh."CompanyId",
        oh."CountryCode",
        oh."RecordType",
        oh."EmployeeId",
        oh."EmployeeCode",
        oh."EmployeeName",
        oh."OccurrenceDate",
        oh."ReportDeadline",
        oh."ReportedDate",
        oh."Severity",
        oh."BodyPartAffected",
        oh."DaysLost",
        oh."Location",
        oh."Description",
        oh."RootCause",
        oh."CorrectiveAction",
        oh."InvestigationDueDate",
        oh."InvestigationCompletedDate",
        oh."InstitutionReference",
        oh."Status",
        oh."DocumentUrl",
        oh."Notes",
        oh."CreatedBy",
        oh."CreatedAt",
        oh."UpdatedAt"
    FROM hr."OccupationalHealth" oh
    WHERE oh."CompanyId" = p_company_id
      AND (p_employee_code IS NULL OR oh."EmployeeCode" = p_employee_code)
      AND (p_record_type   IS NULL OR oh."RecordType"   = p_record_type)
    ORDER BY oh."OccurrenceDate" DESC
    LIMIT p_limit OFFSET p_offset;
END;
$$;

-- 6. Fix usp_hr_medorder_list: Prescriptions is TEXT, cast to TEXT in RETURNS TABLE
DROP FUNCTION IF EXISTS public.usp_hr_medorder_list(INTEGER, VARCHAR, VARCHAR, INTEGER, INTEGER) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_hr_medorder_list(
    p_company_id        INTEGER,
    p_employee_code     VARCHAR(30)     DEFAULT NULL,
    p_status            VARCHAR(20)     DEFAULT NULL,
    p_offset            INTEGER         DEFAULT 0,
    p_limit             INTEGER         DEFAULT 50
)
RETURNS TABLE(
    p_total_count   BIGINT,
    "MedicalOrderId" INTEGER,
    "CompanyId"     INTEGER,
    "EmployeeId"    BIGINT,
    "EmployeeCode"  VARCHAR,
    "EmployeeName"  VARCHAR,
    "OrderType"     VARCHAR,
    "OrderDate"     DATE,
    "Diagnosis"     VARCHAR,
    "PhysicianName" VARCHAR,
    "Prescriptions" TEXT,
    "EstimatedCost" NUMERIC,
    "ApprovedAmount" NUMERIC,
    "Status"        VARCHAR,
    "ApprovedBy"    INTEGER,
    "ApprovedAt"    TIMESTAMP,
    "DocumentUrl"   VARCHAR,
    "Notes"         VARCHAR,
    "CreatedAt"     TIMESTAMP,
    "UpdatedAt"     TIMESTAMP
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        COUNT(*) OVER()     AS p_total_count,
        mo."MedicalOrderId",
        mo."CompanyId",
        mo."EmployeeId",
        mo."EmployeeCode",
        mo."EmployeeName",
        mo."OrderType",
        mo."OrderDate",
        mo."Diagnosis",
        mo."PhysicianName",
        mo."Prescriptions",
        mo."EstimatedCost",
        mo."ApprovedAmount",
        mo."Status",
        mo."ApprovedBy",
        mo."ApprovedAt",
        mo."DocumentUrl",
        mo."Notes",
        mo."CreatedAt",
        mo."UpdatedAt"
    FROM hr."MedicalOrder" mo
    WHERE mo."CompanyId" = p_company_id
      AND (p_employee_code IS NULL OR mo."EmployeeCode" = p_employee_code)
      AND (p_status        IS NULL OR mo."Status"       = p_status)
    ORDER BY mo."OrderDate" DESC
    LIMIT p_limit OFFSET p_offset;
END;
$$;

-- 7. Create alias usp_hr_vacationrequest_list -> usp_hr_vacation_request_list
-- Service calls "usp_HR_VacationRequest_List" -> lowercased "usp_hr_vacationrequest_list"
-- But function on server is "usp_hr_vacation_request_list" (extra underscore)
DROP FUNCTION IF EXISTS public.usp_hr_vacationrequest_list(INTEGER, VARCHAR, VARCHAR, INTEGER, INTEGER) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_hr_vacationrequest_list(
    p_company_id        INTEGER,
    p_employee_code     VARCHAR(30)     DEFAULT NULL,
    p_status            VARCHAR(20)     DEFAULT NULL,
    p_offset            INTEGER         DEFAULT 0,
    p_limit             INTEGER         DEFAULT 50
)
RETURNS TABLE(
    "RequestId"         BIGINT,
    "EmployeeCode"      VARCHAR,
    "EmployeeName"      VARCHAR,
    "RequestDate"       VARCHAR,
    "StartDate"         VARCHAR,
    "EndDate"           VARCHAR,
    "TotalDays"         INTEGER,
    "IsPartial"         BOOLEAN,
    "Status"            VARCHAR,
    "ApprovedBy"        VARCHAR,
    "Notes"             VARCHAR,
    "RejectionReason"   VARCHAR,
    "CreatedAt"         TIMESTAMP,
    "TotalCount"        INTEGER
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT * FROM public.usp_hr_vacation_request_list(
        p_company_id,
        p_employee_code,
        p_status,
        p_offset,
        p_limit
    );
END;
$$;

-- 8. Fix sp_nomina_conceptos_list: Formula col is VARCHAR(500) in table,
-- but function RETURNS TABLE declares it as TEXT - PG strict type check fails
-- Drop and recreate with correct types
DROP FUNCTION IF EXISTS public.sp_nomina_conceptos_list(VARCHAR, VARCHAR, VARCHAR, INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION public.sp_nomina_conceptos_list(
    p_co_nomina VARCHAR(20) DEFAULT NULL,
    p_tipo      VARCHAR(20) DEFAULT NULL,
    p_search    VARCHAR(120) DEFAULT NULL,
    p_page      INT DEFAULT 1,
    p_limit     INT DEFAULT 50
)
RETURNS TABLE(
    "TotalCount"   INT,
    "Codigo"       VARCHAR,
    "CodigoNomina" VARCHAR,
    "Nombre"       VARCHAR,
    "Formula"      VARCHAR,
    "Sobre"        VARCHAR,
    "Clase"        VARCHAR,
    "Tipo"         VARCHAR,
    "Uso"          VARCHAR,
    "Bonificable"  VARCHAR,
    "Antiguedad"   VARCHAR,
    "Contable"     VARCHAR,
    "Aplica"       VARCHAR,
    "Defecto"      DOUBLE PRECISION,
    "Convencion"   VARCHAR,
    "TipoCalculo"  VARCHAR,
    "Orden"        INT,
    "Activo"       BOOLEAN
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_company_id INT;
    v_branch_id  INT;
    v_offset     INT;
    v_total      INT;
BEGIN
    v_offset := (p_page - 1) * p_limit;

    SELECT gs.p_company_id, gs.p_branch_id INTO v_company_id, v_branch_id FROM public.sp_nomina_get_scope() gs;

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
$$;

SELECT 'PART 2 FIXES APPLIED SUCCESSFULLY' AS status;
