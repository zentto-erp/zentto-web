-- +goose Up
-- Fix: 9 funciones HR tienen overloads duplicados (2 versiones cada una).
-- Dropeamos TODAS las versiones y recrea solo la correcta via run_all.sql.
-- Las versiones correctas se recrean automaticamente por el entrypoint de goose.

-- +goose StatementBegin
DO $$
DECLARE
  fn_name text;
  fn_oid oid;
  fn_args text;
  drop_cmd text;
BEGIN
  FOR fn_name IN
    SELECT unnest(ARRAY[
      'usp_hr_committee_list',
      'usp_hr_medexam_list',
      'usp_hr_medorder_list',
      'usp_hr_obligation_getbycountry',
      'usp_hr_obligation_list',
      'usp_hr_occhealth_list',
      'usp_hr_savings_list',
      'usp_hr_training_list',
      'usp_hr_trust_list'
    ])
  LOOP
    FOR fn_oid, fn_args IN
      SELECT p.oid, pg_get_function_identity_arguments(p.oid)
      FROM pg_proc p
      JOIN pg_namespace n ON p.pronamespace = n.oid
      WHERE n.nspname = 'public'
        AND p.proname = fn_name
    LOOP
      drop_cmd := format('DROP FUNCTION IF EXISTS public.%I(%s) CASCADE', fn_name, fn_args);
      RAISE NOTICE '%', drop_cmd;
      EXECUTE drop_cmd;
    END LOOP;
  END LOOP;
END;
$$;
-- +goose StatementEnd

-- Recreate the correct (single) version of each function.
-- These match the signatures used by the API routes.

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_hr_committee_list(
  p_company_id integer,
  p_search text DEFAULT NULL,
  p_offset integer DEFAULT 0,
  p_limit integer DEFAULT 50
)
RETURNS TABLE("CommitteeId" integer, "Name" text, "Type" text, "CreatedDate" date, "IsActive" boolean, "MemberCount" integer, "TotalCount" bigint)
LANGUAGE plpgsql AS $fn$
BEGIN
  RETURN QUERY
  SELECT c.committee_id, c.name, c.committee_type, c.created_date, c.is_active,
         COALESCE(c.member_count, 0)::integer,
         COUNT(*) OVER()
  FROM hr.committees c
  WHERE c.company_id = p_company_id
    AND (p_search IS NULL OR c.name ILIKE '%' || p_search || '%')
  ORDER BY c.committee_id DESC
  OFFSET p_offset LIMIT p_limit;
END;
$fn$;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_hr_medexam_list(
  p_company_id integer,
  p_search text DEFAULT NULL,
  p_offset integer DEFAULT 0,
  p_limit integer DEFAULT 50
)
RETURNS TABLE("ExamId" integer, "EmployeeCode" text, "EmployeeName" text, "ExamType" text, "ExamDate" date, "Result" text, "TotalCount" bigint)
LANGUAGE plpgsql AS $fn$
BEGIN
  RETURN QUERY
  SELECT e.exam_id, e.employee_code, e.employee_name, e.exam_type, e.exam_date, e.result,
         COUNT(*) OVER()
  FROM hr.medical_exams e
  WHERE e.company_id = p_company_id
    AND (p_search IS NULL OR e.employee_name ILIKE '%' || p_search || '%')
  ORDER BY e.exam_date DESC
  OFFSET p_offset LIMIT p_limit;
END;
$fn$;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_hr_medorder_list(
  p_company_id integer,
  p_search text DEFAULT NULL,
  p_offset integer DEFAULT 0,
  p_limit integer DEFAULT 50
)
RETURNS TABLE("OrderId" integer, "EmployeeCode" text, "EmployeeName" text, "OrderType" text, "OrderDate" date, "Status" text, "TotalCount" bigint)
LANGUAGE plpgsql AS $fn$
BEGIN
  RETURN QUERY
  SELECT o.order_id, o.employee_code, o.employee_name, o.order_type, o.order_date, o.status,
         COUNT(*) OVER()
  FROM hr.medical_orders o
  WHERE o.company_id = p_company_id
    AND (p_search IS NULL OR o.employee_name ILIKE '%' || p_search || '%')
  ORDER BY o.order_date DESC
  OFFSET p_offset LIMIT p_limit;
END;
$fn$;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_hr_obligation_getbycountry(
  p_country_code character DEFAULT NULL,
  p_ref_date date DEFAULT CURRENT_DATE
)
RETURNS TABLE("ObligationId" integer, "Name" text, "CountryCode" character, "DueDate" date, "Amount" numeric, "Status" text)
LANGUAGE plpgsql AS $fn$
BEGIN
  RETURN QUERY
  SELECT o.obligation_id, o.name, o.country_code, o.due_date, o.amount, o.status
  FROM hr.obligations o
  WHERE (p_country_code IS NULL OR o.country_code = p_country_code)
    AND (p_ref_date IS NULL OR o.due_date >= p_ref_date - interval '90 days')
  ORDER BY o.due_date;
END;
$fn$;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_hr_obligation_list(
  p_company_id integer,
  p_search text DEFAULT NULL,
  p_offset integer DEFAULT 0,
  p_limit integer DEFAULT 50
)
RETURNS TABLE("ObligationId" integer, "Name" text, "CountryCode" text, "DueDate" date, "Amount" numeric, "Status" text, "TotalCount" bigint)
LANGUAGE plpgsql AS $fn$
BEGIN
  RETURN QUERY
  SELECT o.obligation_id, o.name, o.country_code::text, o.due_date, o.amount, o.status,
         COUNT(*) OVER()
  FROM hr.obligations o
  WHERE o.company_id = p_company_id
    AND (p_search IS NULL OR o.name ILIKE '%' || p_search || '%')
  ORDER BY o.due_date DESC
  OFFSET p_offset LIMIT p_limit;
END;
$fn$;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_hr_occhealth_list(
  p_company_id integer,
  p_search text DEFAULT NULL,
  p_offset integer DEFAULT 0,
  p_limit integer DEFAULT 50
)
RETURNS TABLE("RecordId" integer, "EmployeeCode" text, "EmployeeName" text, "RecordType" text, "RecordDate" date, "Status" text, "TotalCount" bigint)
LANGUAGE plpgsql AS $fn$
BEGIN
  RETURN QUERY
  SELECT r.record_id, r.employee_code, r.employee_name, r.record_type, r.record_date, r.status,
         COUNT(*) OVER()
  FROM hr.occupational_health r
  WHERE r.company_id = p_company_id
    AND (p_search IS NULL OR r.employee_name ILIKE '%' || p_search || '%')
  ORDER BY r.record_date DESC
  OFFSET p_offset LIMIT p_limit;
END;
$fn$;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_hr_savings_list(
  p_company_id integer,
  p_search text DEFAULT NULL,
  p_offset integer DEFAULT 0,
  p_limit integer DEFAULT 50
)
RETURNS TABLE("AccountId" integer, "EmployeeCode" text, "EmployeeName" text, "Balance" numeric, "Status" text, "TotalCount" bigint)
LANGUAGE plpgsql AS $fn$
BEGIN
  RETURN QUERY
  SELECT a.account_id, a.employee_code, a.employee_name, a.balance, a.status,
         COUNT(*) OVER()
  FROM hr.savings_accounts a
  WHERE a.company_id = p_company_id
    AND (p_search IS NULL OR a.employee_name ILIKE '%' || p_search || '%')
  ORDER BY a.account_id DESC
  OFFSET p_offset LIMIT p_limit;
END;
$fn$;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_hr_training_list(
  p_company_id integer,
  p_search text DEFAULT NULL,
  p_offset integer DEFAULT 0,
  p_limit integer DEFAULT 50
)
RETURNS TABLE("TrainingId" integer, "Title" text, "TrainingType" text, "StartDate" date, "EndDate" date, "Status" text, "TotalCount" bigint)
LANGUAGE plpgsql AS $fn$
BEGIN
  RETURN QUERY
  SELECT t.training_id, t.title, t.training_type, t.start_date, t.end_date, t.status,
         COUNT(*) OVER()
  FROM hr.trainings t
  WHERE t.company_id = p_company_id
    AND (p_search IS NULL OR t.title ILIKE '%' || p_search || '%')
  ORDER BY t.start_date DESC
  OFFSET p_offset LIMIT p_limit;
END;
$fn$;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_hr_trust_list(
  p_company_id integer,
  p_search text DEFAULT NULL,
  p_offset integer DEFAULT 0,
  p_limit integer DEFAULT 50
)
RETURNS TABLE("TrustId" integer, "EmployeeCode" text, "EmployeeName" text, "FiscalYear" integer, "Quarter" smallint, "Amount" numeric, "Status" text, "TotalCount" bigint)
LANGUAGE plpgsql AS $fn$
BEGIN
  RETURN QUERY
  SELECT t.trust_id, t.employee_code, t.employee_name, t.fiscal_year, t.quarter, t.amount, t.status,
         COUNT(*) OVER()
  FROM hr.trust_fund t
  WHERE t.company_id = p_company_id
    AND (p_search IS NULL OR t.employee_name ILIKE '%' || p_search || '%')
  ORDER BY t.fiscal_year DESC, t.quarter DESC
  OFFSET p_offset LIMIT p_limit;
END;
$fn$;
-- +goose StatementEnd

-- +goose Down
-- No-op
