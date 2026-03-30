-- +goose Up
-- Fix: funciones RRHH con signaturas y columnas que no coinciden con la BD.
-- Usa tablas canonicas: hr.*, master."Employee"

-- =============================================
-- 1. usp_HR_Trust_List (fideicomiso)
-- =============================================
-- +goose StatementBegin
DROP FUNCTION IF EXISTS public.usp_hr_trust_list(integer, integer, smallint, character varying, character varying, integer, integer) CASCADE;
DROP FUNCTION IF EXISTS public.usp_hr_trust_list(integer, text, integer, integer) CASCADE;
DROP FUNCTION IF EXISTS public.usp_hr_trust_list(integer, integer, integer, integer) CASCADE;

CREATE OR REPLACE FUNCTION public.usp_HR_Trust_List(
    p_company_id INTEGER, p_year INTEGER DEFAULT NULL,
    p_offset INTEGER DEFAULT 0, p_limit INTEGER DEFAULT 50
) RETURNS TABLE(
    "TrustId" INTEGER, "EmployeeCode" VARCHAR, "EmployeeName" TEXT,
    "FiscalYear" INTEGER, "Quarter" SMALLINT, "Amount" NUMERIC,
    "Status" VARCHAR, "TotalCount" BIGINT
) LANGUAGE plpgsql AS $$
BEGIN
  RETURN QUERY
  SELECT t."TrustId", t."EmployeeCode", t."EmployeeName"::TEXT,
         t."FiscalYear", t."Quarter", t."DepositAmount", t."Status",
         COUNT(*) OVER()
  FROM hr."SocialBenefitsTrust" t
  WHERE t."CompanyId" = p_company_id
    AND (p_year IS NULL OR t."FiscalYear" = p_year)
  ORDER BY t."FiscalYear" DESC, t."Quarter" DESC
  OFFSET p_offset LIMIT p_limit;
END; $$;
-- +goose StatementEnd

-- =============================================
-- 2. usp_HR_Savings_List (caja-ahorro)
-- =============================================
-- +goose StatementBegin
DROP FUNCTION IF EXISTS public.usp_hr_savings_list(integer, character varying, character varying, integer, integer) CASCADE;
DROP FUNCTION IF EXISTS public.usp_hr_savings_list(integer, text, integer, integer) CASCADE;

CREATE OR REPLACE FUNCTION public.usp_HR_Savings_List(
    p_company_id INTEGER, p_search TEXT DEFAULT NULL,
    p_offset INTEGER DEFAULT 0, p_limit INTEGER DEFAULT 50
) RETURNS TABLE(
    "AccountId" INTEGER, "EmployeeCode" VARCHAR, "EmployeeName" TEXT,
    "Balance" NUMERIC, "Status" VARCHAR, "TotalCount" BIGINT
) LANGUAGE plpgsql AS $$
BEGIN
  RETURN QUERY
  SELECT s."SavingsFundId", s."EmployeeCode", s."EmployeeName"::TEXT,
         (s."EmployeeContribution" + s."EmployerMatch"), s."Status",
         COUNT(*) OVER()
  FROM hr."SavingsFund" s
  WHERE s."CompanyId" = p_company_id
    AND (p_search IS NULL OR s."EmployeeName" ILIKE '%' || p_search || '%')
  ORDER BY s."SavingsFundId" DESC
  OFFSET p_offset LIMIT p_limit;
END; $$;
-- +goose StatementEnd

-- =============================================
-- 3. usp_HR_Obligation_List (obligaciones)
-- =============================================
-- +goose StatementBegin
DROP FUNCTION IF EXISTS public.usp_hr_obligation_list(character, character varying, boolean, character varying, integer, integer) CASCADE;
DROP FUNCTION IF EXISTS public.usp_hr_obligation_list(integer, text, integer, integer) CASCADE;

CREATE OR REPLACE FUNCTION public.usp_HR_Obligation_List(
    p_company_id INTEGER, p_country_code TEXT DEFAULT NULL,
    p_offset INTEGER DEFAULT 0, p_limit INTEGER DEFAULT 50
) RETURNS TABLE(
    "ObligationId" INTEGER, "Name" TEXT, "CountryCode" CHAR(2),
    "ObligationType" VARCHAR, "EmployerRate" NUMERIC, "EmployeeRate" NUMERIC,
    "IsActive" BOOLEAN, "TotalCount" BIGINT
) LANGUAGE plpgsql AS $$
BEGIN
  RETURN QUERY
  SELECT o."LegalObligationId", o."Name"::TEXT, o."CountryCode",
         o."ObligationType", o."EmployerRate", o."EmployeeRate", o."IsActive",
         COUNT(*) OVER()
  FROM hr."LegalObligation" o
  WHERE (p_country_code IS NULL OR o."CountryCode" = p_country_code)
    AND o."IsActive" = TRUE
  ORDER BY o."Name"
  OFFSET p_offset LIMIT p_limit;
END; $$;
-- +goose StatementEnd

-- =============================================
-- 4. usp_HR_OccHealth_List (salud-ocupacional)
-- =============================================
-- +goose StatementBegin
DROP FUNCTION IF EXISTS public.usp_hr_occhealth_list(integer, character varying, character varying, character varying, character, date, date, integer, integer) CASCADE;
DROP FUNCTION IF EXISTS public.usp_hr_occhealth_list(integer, text, integer, integer) CASCADE;
DROP FUNCTION IF EXISTS public.usp_hr_occhealth_list(integer, text, text, integer, integer) CASCADE;

CREATE OR REPLACE FUNCTION public.usp_HR_OccHealth_List(
    p_company_id INTEGER, p_employee_code TEXT DEFAULT NULL,
    p_record_type TEXT DEFAULT NULL,
    p_offset INTEGER DEFAULT 0, p_limit INTEGER DEFAULT 50
) RETURNS TABLE(
    "RecordId" INTEGER, "EmployeeCode" VARCHAR, "EmployeeName" TEXT,
    "RecordType" VARCHAR, "RecordDate" TIMESTAMP, "Status" VARCHAR, "TotalCount" BIGINT
) LANGUAGE plpgsql AS $$
BEGIN
  RETURN QUERY
  SELECT o."OccupationalHealthId", o."EmployeeCode", o."EmployeeName"::TEXT,
         o."RecordType", o."OccurrenceDate", o."Status",
         COUNT(*) OVER()
  FROM hr."OccupationalHealth" o
  WHERE o."CompanyId" = p_company_id
    AND (p_employee_code IS NULL OR o."EmployeeCode" = p_employee_code)
    AND (p_record_type IS NULL OR o."RecordType" = p_record_type)
  ORDER BY o."OccurrenceDate" DESC
  OFFSET p_offset LIMIT p_limit;
END; $$;
-- +goose StatementEnd

-- =============================================
-- 5. usp_HR_MedExam_List (examenes-medicos)
-- =============================================
-- +goose StatementBegin
DROP FUNCTION IF EXISTS public.usp_hr_medexam_list(integer, character varying, character varying, character varying, date, date, integer, integer) CASCADE;
DROP FUNCTION IF EXISTS public.usp_hr_medexam_list(integer, text, integer, integer) CASCADE;
DROP FUNCTION IF EXISTS public.usp_hr_medexam_list(integer, text, text, integer, integer) CASCADE;

CREATE OR REPLACE FUNCTION public.usp_HR_MedExam_List(
    p_company_id INTEGER, p_employee_code TEXT DEFAULT NULL,
    p_exam_type TEXT DEFAULT NULL,
    p_offset INTEGER DEFAULT 0, p_limit INTEGER DEFAULT 50
) RETURNS TABLE(
    "ExamId" INTEGER, "EmployeeCode" VARCHAR, "EmployeeName" TEXT,
    "ExamType" VARCHAR, "ExamDate" DATE, "Result" VARCHAR, "TotalCount" BIGINT
) LANGUAGE plpgsql AS $$
BEGIN
  RETURN QUERY
  SELECT m."MedicalExamId", m."EmployeeCode", m."EmployeeName"::TEXT,
         m."ExamType", m."ExamDate", m."Result",
         COUNT(*) OVER()
  FROM hr."MedicalExam" m
  WHERE m."CompanyId" = p_company_id
    AND (p_employee_code IS NULL OR m."EmployeeCode" = p_employee_code)
    AND (p_exam_type IS NULL OR m."ExamType" = p_exam_type)
  ORDER BY m."ExamDate" DESC
  OFFSET p_offset LIMIT p_limit;
END; $$;
-- +goose StatementEnd

-- =============================================
-- 6. usp_HR_MedOrder_List (ordenes-medicas)
-- =============================================
-- +goose StatementBegin
DROP FUNCTION IF EXISTS public.usp_hr_medorder_list(integer, character varying, character varying, character varying, date, date, integer, integer) CASCADE;
DROP FUNCTION IF EXISTS public.usp_hr_medorder_list(integer, text, integer, integer) CASCADE;
DROP FUNCTION IF EXISTS public.usp_hr_medorder_list(integer, text, text, integer, integer) CASCADE;

CREATE OR REPLACE FUNCTION public.usp_HR_MedOrder_List(
    p_company_id INTEGER, p_employee_code TEXT DEFAULT NULL,
    p_status TEXT DEFAULT NULL,
    p_offset INTEGER DEFAULT 0, p_limit INTEGER DEFAULT 50
) RETURNS TABLE(
    "OrderId" INTEGER, "EmployeeCode" VARCHAR, "EmployeeName" TEXT,
    "OrderType" VARCHAR, "OrderDate" DATE, "Status" VARCHAR, "TotalCount" BIGINT
) LANGUAGE plpgsql AS $$
BEGIN
  RETURN QUERY
  SELECT m."MedicalOrderId", m."EmployeeCode", m."EmployeeName"::TEXT,
         m."OrderType", m."OrderDate", m."Status",
         COUNT(*) OVER()
  FROM hr."MedicalOrder" m
  WHERE m."CompanyId" = p_company_id
    AND (p_employee_code IS NULL OR m."EmployeeCode" = p_employee_code)
    AND (p_status IS NULL OR m."Status" = p_status)
  ORDER BY m."OrderDate" DESC
  OFFSET p_offset LIMIT p_limit;
END; $$;
-- +goose StatementEnd

-- =============================================
-- 7. usp_HR_Training_List (capacitacion)
-- =============================================
-- +goose StatementBegin
DROP FUNCTION IF EXISTS public.usp_hr_training_list(integer, character varying, character varying, character, boolean, character varying, date, date, integer, integer) CASCADE;
DROP FUNCTION IF EXISTS public.usp_hr_training_list(integer, text, integer, integer) CASCADE;

CREATE OR REPLACE FUNCTION public.usp_HR_Training_List(
    p_company_id INTEGER, p_search TEXT DEFAULT NULL,
    p_offset INTEGER DEFAULT 0, p_limit INTEGER DEFAULT 50
) RETURNS TABLE(
    "TrainingId" INTEGER, "Title" TEXT, "TrainingType" VARCHAR,
    "StartDate" DATE, "EndDate" DATE, "Status" VARCHAR, "TotalCount" BIGINT
) LANGUAGE plpgsql AS $$
BEGIN
  RETURN QUERY
  SELECT t."TrainingRecordId", t."Title"::TEXT, t."TrainingType",
         t."StartDate", t."EndDate", COALESCE(t."Result", 'PENDING')::VARCHAR,
         COUNT(*) OVER()
  FROM hr."TrainingRecord" t
  WHERE t."CompanyId" = p_company_id
    AND (p_search IS NULL OR t."Title" ILIKE '%' || p_search || '%')
  ORDER BY t."StartDate" DESC
  OFFSET p_offset LIMIT p_limit;
END; $$;
-- +goose StatementEnd

-- =============================================
-- 8. usp_HR_Committee_List (comites)
-- =============================================
-- +goose StatementBegin
DROP FUNCTION IF EXISTS public.usp_hr_committee_list(integer, character, boolean, integer, integer) CASCADE;
DROP FUNCTION IF EXISTS public.usp_hr_committee_list(integer, text, integer, integer) CASCADE;

CREATE OR REPLACE FUNCTION public.usp_HR_Committee_List(
    p_company_id INTEGER, p_search TEXT DEFAULT NULL,
    p_offset INTEGER DEFAULT 0, p_limit INTEGER DEFAULT 50
) RETURNS TABLE(
    "CommitteeId" INTEGER, "Name" TEXT, "Type" VARCHAR,
    "CreatedDate" DATE, "IsActive" BOOLEAN,
    "MemberCount" INTEGER, "TotalCount" BIGINT
) LANGUAGE plpgsql AS $$
BEGIN
  RETURN QUERY
  SELECT c."SafetyCommitteeId", c."CommitteeName"::TEXT, c."MeetingFrequency",
         c."FormationDate"::DATE, c."IsActive",
         (SELECT COUNT(*)::INTEGER FROM hr."SafetyCommitteeMember" m WHERE m."SafetyCommitteeId" = c."SafetyCommitteeId"),
         COUNT(*) OVER()
  FROM hr."SafetyCommittee" c
  WHERE c."CompanyId" = p_company_id
    AND (p_search IS NULL OR c."CommitteeName" ILIKE '%' || p_search || '%')
  ORDER BY c."SafetyCommitteeId" DESC
  OFFSET p_offset LIMIT p_limit;
END; $$;
-- +goose StatementEnd

-- =============================================
-- 9. usp_HR_Obligation_GetByCountry
-- =============================================
-- +goose StatementBegin
DROP FUNCTION IF EXISTS public.usp_hr_obligation_getbycountry(character, date) CASCADE;
DROP FUNCTION IF EXISTS public.usp_hr_obligation_getbycountry(character, integer) CASCADE;

CREATE OR REPLACE FUNCTION public.usp_HR_Obligation_GetByCountry(
    p_country_code CHARACTER DEFAULT NULL,
    p_ref_date DATE DEFAULT CURRENT_DATE
) RETURNS TABLE(
    "ObligationId" INTEGER, "Name" TEXT, "CountryCode" CHAR(2),
    "ObligationType" VARCHAR, "EmployerRate" NUMERIC, "EmployeeRate" NUMERIC,
    "IsActive" BOOLEAN
) LANGUAGE plpgsql AS $$
BEGIN
  RETURN QUERY
  SELECT o."LegalObligationId", o."Name"::TEXT, o."CountryCode",
         o."ObligationType", o."EmployerRate", o."EmployeeRate", o."IsActive"
  FROM hr."LegalObligation" o
  WHERE (p_country_code IS NULL OR o."CountryCode" = p_country_code)
    AND o."IsActive" = TRUE
    AND (o."EffectiveFrom" IS NULL OR o."EffectiveFrom" <= p_ref_date)
    AND (o."EffectiveTo" IS NULL OR o."EffectiveTo" >= p_ref_date)
  ORDER BY o."Name";
END; $$;
-- +goose StatementEnd

-- +goose Down
-- No-op
