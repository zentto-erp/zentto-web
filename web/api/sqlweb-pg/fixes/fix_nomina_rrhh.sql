-- ============================================================
-- FIX SCRIPT: Nomina/RRHH PostgreSQL Function Mismatches
-- Date: 2026-03-16
-- Agent: QA Agent 5
-- ============================================================

-- 1. Create alias sp_nomina_getscope -> sp_nomina_get_scope
DROP FUNCTION IF EXISTS public.sp_nomina_getscope() CASCADE;
CREATE OR REPLACE FUNCTION public.sp_nomina_getscope(
    OUT p_company_id INTEGER,
    OUT p_branch_id INTEGER
)
LANGUAGE plpgsql AS $$
BEGIN
    SELECT gs.p_company_id, gs.p_branch_id
    INTO p_company_id, p_branch_id
    FROM public.sp_nomina_get_scope() gs;
END;
$$;

-- 2. Fix usp_hr_payroll_listbatches - PayrollBatch has no BranchId, aggregates, CreatedBy, ApprovedBy
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
        COUNT(bl."BatchLineId")     AS "TotalEmployees",
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

-- 3. Fix usp_hr_profitsharing_list: use p_year instead of p_fiscal_year
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
        (SELECT COUNT(*) FROM hr."ProfitSharingLine" WHERE "ProfitSharingId" = ps."ProfitSharingId")::BIGINT AS "TotalEmployees",
        COALESCE((SELECT SUM("NetAmount") FROM hr."ProfitSharingLine" WHERE "ProfitSharingId" = ps."ProfitSharingId"), 0) AS "TotalNet"
    FROM hr."ProfitSharing" ps
    WHERE ps."CompanyId" = p_company_id
      AND (p_year   IS NULL OR ps."FiscalYear" = p_year)
      AND (p_status IS NULL OR ps."Status"     = p_status)
    ORDER BY ps."FiscalYear" DESC, ps."CreatedAt" DESC
    LIMIT p_limit OFFSET p_offset;
END;
$$;

-- 4. Fix usp_hr_trust_list: use p_year instead of p_fiscal_year
DROP FUNCTION IF EXISTS public.usp_hr_trust_list(INTEGER, INTEGER, INTEGER, INTEGER) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_hr_trust_list(
    p_company_id    INTEGER,
    p_year          INTEGER         DEFAULT NULL,
    p_offset        INTEGER         DEFAULT 0,
    p_limit         INTEGER         DEFAULT 50
)
RETURNS TABLE(
    p_total_count           BIGINT,
    "TrustId"               INTEGER,
    "EmployeeId"            BIGINT,
    "EmployeeCode"          VARCHAR,
    "EmployeeName"          VARCHAR,
    "FiscalYear"            INTEGER,
    "Quarter"               SMALLINT,
    "DailySalary"           NUMERIC,
    "DaysDeposited"         INTEGER,
    "BonusDays"             INTEGER,
    "DepositAmount"         NUMERIC,
    "InterestRate"          NUMERIC,
    "InterestAmount"        NUMERIC,
    "AccumulatedBalance"    NUMERIC,
    "Status"                VARCHAR,
    "CreatedAt"             TIMESTAMP
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        COUNT(*) OVER()             AS p_total_count,
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
      AND (p_year IS NULL OR t."FiscalYear" = p_year)
    ORDER BY t."FiscalYear" DESC, t."Quarter" DESC, t."EmployeeCode"
    LIMIT p_limit OFFSET p_offset;
END;
$$;

-- 5. Fix usp_hr_savings_list: accept p_search (fuzzy match)
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
        sf."EmployeeContributionPct",
        sf."EmployerMatchPct",
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

-- 6. Fix usp_hr_committee_list: accept p_search and p_offset/p_limit
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
        (SELECT COUNT(*) FROM hr."SafetyCommitteeMember" WHERE "SafetyCommitteeId" = sc."SafetyCommitteeId" AND "IsActive" = TRUE)::BIGINT AS "ActiveMemberCount",
        (SELECT COUNT(*) FROM hr."SafetyCommitteeMeeting" WHERE "SafetyCommitteeId" = sc."SafetyCommitteeId")::BIGINT AS "TotalMeetings"
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

-- 7. Fix usp_hr_occhealth_list: use p_offset-based pagination
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
    "Description"               VARCHAR,
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

-- 8. Fix usp_hr_medexam_list: use p_offset-based pagination
DROP FUNCTION IF EXISTS public.usp_hr_medexam_list(INTEGER, VARCHAR, VARCHAR, INTEGER, INTEGER) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_hr_medexam_list(
    p_company_id        INTEGER,
    p_employee_code     VARCHAR(30)     DEFAULT NULL,
    p_exam_type         VARCHAR(50)     DEFAULT NULL,
    p_offset            INTEGER         DEFAULT 0,
    p_limit             INTEGER         DEFAULT 50
)
RETURNS TABLE(
    p_total_count   BIGINT,
    "MedicalExamId" INTEGER,
    "CompanyId"     INTEGER,
    "EmployeeId"    BIGINT,
    "EmployeeCode"  VARCHAR,
    "EmployeeName"  VARCHAR,
    "ExamType"      VARCHAR,
    "ExamDate"      DATE,
    "NextDueDate"   DATE,
    "Result"        VARCHAR,
    "Restrictions"  VARCHAR,
    "PhysicianName" VARCHAR,
    "ClinicName"    VARCHAR,
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
        me."MedicalExamId",
        me."CompanyId",
        me."EmployeeId",
        me."EmployeeCode",
        me."EmployeeName",
        me."ExamType",
        me."ExamDate",
        me."NextDueDate",
        me."Result",
        me."Restrictions",
        me."PhysicianName",
        me."ClinicName",
        me."DocumentUrl",
        me."Notes",
        me."CreatedAt",
        me."UpdatedAt"
    FROM hr."MedicalExam" me
    WHERE me."CompanyId" = p_company_id
      AND (p_employee_code IS NULL OR me."EmployeeCode" = p_employee_code)
      AND (p_exam_type     IS NULL OR me."ExamType"     = p_exam_type)
    ORDER BY me."ExamDate" DESC
    LIMIT p_limit OFFSET p_offset;
END;
$$;

-- 9. Fix usp_hr_medorder_list: use p_offset-based pagination
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
    "Prescriptions" VARCHAR,
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

-- 10. Fix usp_hr_training_list: accept p_search and p_offset/p_limit
DROP FUNCTION IF EXISTS public.usp_hr_training_list(INTEGER, VARCHAR, INTEGER, INTEGER) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_hr_training_list(
    p_company_id        INTEGER,
    p_search            VARCHAR(200)    DEFAULT NULL,
    p_offset            INTEGER         DEFAULT 0,
    p_limit             INTEGER         DEFAULT 50
)
RETURNS TABLE(
    p_total_count       BIGINT,
    "TrainingRecordId"  INTEGER,
    "CompanyId"         INTEGER,
    "CountryCode"       CHARACTER,
    "TrainingType"      VARCHAR,
    "Title"             VARCHAR,
    "Provider"          VARCHAR,
    "StartDate"         DATE,
    "EndDate"           DATE,
    "DurationHours"     NUMERIC,
    "EmployeeId"        BIGINT,
    "EmployeeCode"      VARCHAR,
    "EmployeeName"      VARCHAR,
    "CertificateNumber" VARCHAR,
    "CertificateUrl"    VARCHAR,
    "Result"            VARCHAR,
    "IsRegulatory"      BOOLEAN,
    "Notes"             VARCHAR,
    "CreatedAt"         TIMESTAMP,
    "UpdatedAt"         TIMESTAMP
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        COUNT(*) OVER()     AS p_total_count,
        tr."TrainingRecordId",
        tr."CompanyId",
        tr."CountryCode",
        tr."TrainingType",
        tr."Title",
        tr."Provider",
        tr."StartDate",
        tr."EndDate",
        tr."DurationHours",
        tr."EmployeeId",
        tr."EmployeeCode",
        tr."EmployeeName",
        tr."CertificateNumber",
        tr."CertificateUrl",
        tr."Result",
        tr."IsRegulatory",
        tr."Notes",
        tr."CreatedAt",
        tr."UpdatedAt"
    FROM hr."TrainingRecord" tr
    WHERE tr."CompanyId" = p_company_id
      AND (
          p_search IS NULL
          OR tr."Title"        ILIKE '%' || p_search || '%'
          OR tr."EmployeeName" ILIKE '%' || p_search || '%'
          OR tr."TrainingType" ILIKE '%' || p_search || '%'
      )
    ORDER BY tr."StartDate" DESC
    LIMIT p_limit OFFSET p_offset;
END;
$$;

-- 11. Fix usp_hr_obligation_list: accept p_company_id and p_offset/p_limit
DROP FUNCTION IF EXISTS public.usp_hr_obligation_list(INTEGER, VARCHAR, INTEGER, INTEGER) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_hr_obligation_list(
    p_company_id        INTEGER,
    p_country_code      VARCHAR(5)      DEFAULT NULL,
    p_offset            INTEGER         DEFAULT 0,
    p_limit             INTEGER         DEFAULT 50
)
RETURNS TABLE(
    p_total_count           BIGINT,
    "LegalObligationId"     INTEGER,
    "CountryCode"           CHARACTER,
    "Code"                  VARCHAR,
    "Name"                  VARCHAR,
    "InstitutionName"       VARCHAR,
    "ObligationType"        VARCHAR,
    "CalculationBasis"      VARCHAR,
    "SalaryCap"             NUMERIC,
    "SalaryCapUnit"         VARCHAR,
    "EmployerRate"          NUMERIC,
    "EmployeeRate"          NUMERIC,
    "RateVariableByRisk"    BOOLEAN,
    "FilingFrequency"       VARCHAR,
    "FilingDeadlineRule"    VARCHAR,
    "EffectiveFrom"         DATE,
    "EffectiveTo"           DATE,
    "IsActive"              BOOLEAN,
    "Notes"                 VARCHAR
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        COUNT(*) OVER()     AS p_total_count,
        lo."LegalObligationId",
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
        lo."IsActive",
        lo."Notes"
    FROM hr."LegalObligation" lo
    WHERE lo."IsActive" = TRUE
      AND (p_country_code IS NULL OR lo."CountryCode" = p_country_code::CHARACTER)
    ORDER BY lo."CountryCode", lo."Name"
    LIMIT p_limit OFFSET p_offset;
END;
$$;

SELECT 'ALL FIXES APPLIED SUCCESSFULLY' AS status;
