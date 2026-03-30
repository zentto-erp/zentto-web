-- ============================================================
-- FIX SCRIPT PART 3: Final remaining issues
-- Date: 2026-03-16
-- Agent: QA Agent 5
-- ============================================================

-- 1. Fix usp_hr_committee_list: SafetyCommitteeMember has no IsActive column
-- The table only has: MemberId, SafetyCommitteeId, EmployeeId, EmployeeCode, EmployeeName, Role, StartDate, EndDate
-- Active = no EndDate (or EndDate in future)
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
        (SELECT COUNT(*) FROM hr."SafetyCommitteeMember" scm
         WHERE scm."SafetyCommitteeId" = sc."SafetyCommitteeId"
           AND (scm."EndDate" IS NULL OR scm."EndDate" >= CURRENT_DATE))::BIGINT AS "ActiveMemberCount",
        (SELECT COUNT(*) FROM hr."SafetyCommitteeMeeting" scmt
         WHERE scmt."SafetyCommitteeId" = sc."SafetyCommitteeId")::BIGINT AS "TotalMeetings"
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

-- 2. Fix usp_hr_medexam_getpending: CompanyId ambiguous in CTE
-- The RETURNS TABLE has "CompanyId" column which conflicts with WHERE clause
DROP FUNCTION IF EXISTS public.usp_hr_medexam_getpending(INTEGER, DATE, INTEGER, INTEGER, INTEGER) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_hr_medexam_getpending(
    p_company_id    INTEGER,
    p_as_of_date    DATE            DEFAULT NULL,
    p_days_ahead    INTEGER         DEFAULT 30,
    p_page          INTEGER         DEFAULT 1,
    p_limit         INTEGER         DEFAULT 50
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
    "IsOverdue"     BOOLEAN,
    "DaysUntilDue"  INTEGER
)
LANGUAGE plpgsql AS $$
DECLARE
    v_as_of_date DATE;
    v_offset     INTEGER;
BEGIN
    v_as_of_date := COALESCE(p_as_of_date, CAST((NOW() AT TIME ZONE 'UTC') AS DATE));
    IF p_page  < 1   THEN p_page  := 1;   END IF;
    IF p_limit < 1   THEN p_limit := 50;  END IF;
    IF p_limit > 500 THEN p_limit := 500; END IF;
    v_offset := (p_page - 1) * p_limit;

    RETURN QUERY
    WITH "LatestExam" AS (
        SELECT me.*,
               ROW_NUMBER() OVER (PARTITION BY me."EmployeeCode" ORDER BY me."ExamDate" DESC) AS rn
        FROM hr."MedicalExam" me
        WHERE me."CompanyId"   = p_company_id
          AND me."ExamType"    = 'PERIODIC'
          AND me."NextDueDate" IS NOT NULL
          AND me."NextDueDate" <= v_as_of_date + p_days_ahead
    )
    SELECT
        COUNT(*) OVER()                             AS p_total_count,
        le."MedicalExamId",
        le."CompanyId",
        le."EmployeeId",
        le."EmployeeCode",
        le."EmployeeName",
        le."ExamType",
        le."ExamDate",
        le."NextDueDate",
        le."Result",
        le."Restrictions",
        le."PhysicianName",
        le."ClinicName",
        (le."NextDueDate" < v_as_of_date)           AS "IsOverdue",
        (le."NextDueDate" - v_as_of_date)::INTEGER  AS "DaysUntilDue"
    FROM "LatestExam" le
    WHERE rn = 1
    ORDER BY le."NextDueDate" ASC
    LIMIT p_limit OFFSET v_offset;
END;
$$;

-- 3. Fix sp_nomina_conceptos_list: still failing?
-- Drop/recreate using sp_nomina_get_scope (with underscore)
DROP FUNCTION IF EXISTS public.sp_nomina_conceptos_list(VARCHAR, VARCHAR, VARCHAR, INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION public.sp_nomina_conceptos_list(
    p_co_nomina VARCHAR(20)  DEFAULT NULL,
    p_tipo      VARCHAR(20)  DEFAULT NULL,
    p_search    VARCHAR(120) DEFAULT NULL,
    p_page      INT          DEFAULT 1,
    p_limit     INT          DEFAULT 50
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
LANGUAGE plpgsql AS $$
DECLARE
    v_company_id INT;
    v_branch_id  INT;
    v_offset     INT;
    v_total      INT;
BEGIN
    v_offset := (p_page - 1) * p_limit;

    SELECT gs.p_company_id, gs.p_branch_id
    INTO v_company_id, v_branch_id
    FROM public.sp_nomina_get_scope() gs;

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
        v_total::INT,
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
        pc."DefaultValue"::DOUBLE PRECISION,
        pc."ConventionCode",
        pc."CalculationType",
        pc."SortOrder"::INT,
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

SELECT 'PART 3 FIXES APPLIED SUCCESSFULLY' AS status;
