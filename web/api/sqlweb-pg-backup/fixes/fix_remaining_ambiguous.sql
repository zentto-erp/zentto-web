-- Fix: usp_acct_period_checklist - column reference 'Status' is ambiguous
DROP FUNCTION IF EXISTS public.usp_acct_period_checklist(integer, character) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_acct_period_checklist(
    p_company_id integer,
    p_period_code character
)
RETURNS TABLE("ItemName" character varying, "ItemCount" integer, "Status" character varying)
LANGUAGE plpgsql
AS $function$
DECLARE
    v_period_fmt  VARCHAR(7);
    v_drafts      INTEGER;
    v_unbalanced  INTEGER;
    v_approved    INTEGER;
    v_bal_diff    NUMERIC(18,2);
BEGIN
    v_period_fmt := LEFT(p_period_code, 4) || '-' || RIGHT(p_period_code, 2);

    -- 1. Asientos en borrador
    SELECT COUNT(*) INTO v_drafts
    FROM acct."JournalEntry" je1
    WHERE je1."CompanyId" = p_company_id AND je1."PeriodCode" = v_period_fmt
      AND je1."Status" = 'DRAFT' AND je1."IsDeleted" = FALSE;

    RETURN QUERY SELECT
        'Asientos en borrador'::VARCHAR(100),
        v_drafts,
        CASE WHEN v_drafts = 0 THEN 'OK'::VARCHAR(10) ELSE 'ERROR'::VARCHAR(10) END;

    -- 2. Asientos desbalanceados
    SELECT COUNT(*) INTO v_unbalanced
    FROM acct."JournalEntry" je2
    WHERE je2."CompanyId" = p_company_id AND je2."PeriodCode" = v_period_fmt
      AND je2."Status" = 'APPROVED' AND je2."IsDeleted" = FALSE
      AND ABS(je2."TotalDebit" - je2."TotalCredit") > 0.01;

    RETURN QUERY SELECT
        'Asientos desbalanceados'::VARCHAR(100),
        v_unbalanced,
        CASE WHEN v_unbalanced = 0 THEN 'OK'::VARCHAR(10) ELSE 'ERROR'::VARCHAR(10) END;

    -- 3. Total asientos aprobados
    SELECT COUNT(*) INTO v_approved
    FROM acct."JournalEntry" je3
    WHERE je3."CompanyId" = p_company_id AND je3."PeriodCode" = v_period_fmt
      AND je3."Status" = 'APPROVED' AND je3."IsDeleted" = FALSE;

    RETURN QUERY SELECT
        'Asientos aprobados en periodo'::VARCHAR(100),
        v_approved,
        CASE WHEN v_approved > 0 THEN 'OK'::VARCHAR(10) ELSE 'WARNING'::VARCHAR(10) END;

    -- 4. Balance total cuadra
    SELECT ABS(COALESCE(SUM(jel."DebitAmount"), 0) - COALESCE(SUM(jel."CreditAmount"), 0))
    INTO v_bal_diff
    FROM acct."JournalEntryLine" jel
    JOIN acct."JournalEntry" je ON je."JournalEntryId" = jel."JournalEntryId"
    WHERE je."CompanyId" = p_company_id AND je."PeriodCode" = v_period_fmt
      AND je."Status" = 'APPROVED' AND je."IsDeleted" = FALSE;

    RETURN QUERY SELECT
        'Diferencia total debe/haber'::VARCHAR(100),
        COALESCE(v_bal_diff, 0)::INTEGER,
        CASE WHEN COALESCE(v_bal_diff, 0) < 0.01 THEN 'OK'::VARCHAR(10) ELSE 'ERROR'::VARCHAR(10) END;
END;
$function$;

-- Grant execute to app user
GRANT EXECUTE ON FUNCTION public.usp_acct_period_checklist(integer, character) TO zentto_app;

-- Fix: usp_acct_recurringentry_list - column reference 'IsActive' is ambiguous
DROP FUNCTION IF EXISTS public.usp_acct_recurringentry_list(integer, boolean, integer, integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_acct_recurringentry_list(
    p_company_id integer,
    p_is_active boolean DEFAULT NULL::boolean,
    p_page integer DEFAULT 1,
    p_limit integer DEFAULT 50
)
RETURNS TABLE(
    p_total_count bigint,
    "RecurringEntryId" integer,
    "TemplateName" character varying,
    "Frequency" character varying,
    "NextExecutionDate" date,
    "LastExecutedDate" date,
    "TimesExecuted" integer,
    "MaxExecutions" integer,
    "TipoAsiento" character varying,
    "Concepto" character varying,
    "IsActive" boolean
)
LANGUAGE plpgsql
AS $function$
DECLARE
    v_total_count BIGINT;
BEGIN
    IF p_page  < 1   THEN p_page  := 1;   END IF;
    IF p_limit < 1   THEN p_limit := 50;  END IF;
    IF p_limit > 500 THEN p_limit := 500; END IF;

    SELECT COUNT(*)
    INTO v_total_count
    FROM acct."RecurringEntry" re2
    WHERE re2."CompanyId" = p_company_id
      AND re2."IsDeleted" = FALSE
      AND (p_is_active IS NULL OR re2."IsActive" = p_is_active);

    RETURN QUERY
    SELECT v_total_count,
           re."RecurringEntryId",
           re."TemplateName",
           re."Frequency",
           re."NextExecutionDate",
           re."LastExecutedDate",
           re."TimesExecuted",
           re."MaxExecutions",
           re."TipoAsiento",
           re."Concepto",
           re."IsActive"
    FROM acct."RecurringEntry" re
    WHERE re."CompanyId" = p_company_id
      AND re."IsDeleted" = FALSE
      AND (p_is_active IS NULL OR re."IsActive" = p_is_active)
    ORDER BY re."NextExecutionDate"
    LIMIT p_limit OFFSET (p_page - 1) * p_limit;
END;
$function$;

-- Grant execute to app user
GRANT EXECUTE ON FUNCTION public.usp_acct_recurringentry_list(integer, boolean, integer, integer) TO zentto_app;

-- Fix: usp_acct_budget_list - column references 'FiscalYear' and 'Status' are ambiguous
DROP FUNCTION IF EXISTS public.usp_acct_budget_list(integer, smallint, character varying, integer, integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_acct_budget_list(
    p_company_id integer,
    p_fiscal_year smallint DEFAULT NULL::smallint,
    p_status character varying DEFAULT NULL::character varying,
    p_page integer DEFAULT 1,
    p_limit integer DEFAULT 50
)
RETURNS TABLE(
    p_total_count bigint,
    "BudgetId" integer,
    "BudgetName" character varying,
    "FiscalYear" smallint,
    "CostCenterCode" character varying,
    "Status" character varying,
    "Notes" character varying,
    "CreatedAt" timestamp without time zone,
    "UpdatedAt" timestamp without time zone
)
LANGUAGE plpgsql
AS $function$
DECLARE
    v_total_count BIGINT;
BEGIN
    IF p_page  < 1   THEN p_page  := 1;   END IF;
    IF p_limit < 1   THEN p_limit := 50;  END IF;
    IF p_limit > 500 THEN p_limit := 500; END IF;

    SELECT COUNT(*)
    INTO v_total_count
    FROM acct."Budget" b2
    WHERE b2."CompanyId" = p_company_id
      AND b2."IsDeleted" = FALSE
      AND (p_fiscal_year IS NULL OR b2."FiscalYear" = p_fiscal_year)
      AND (p_status      IS NULL OR b2."Status"     = p_status);

    RETURN QUERY
    SELECT v_total_count,
           b."BudgetId",
           b."BudgetName",
           b."FiscalYear",
           b."CostCenterCode",
           b."Status",
           b."Notes",
           b."CreatedAt",
           b."UpdatedAt"
    FROM acct."Budget" b
    WHERE b."CompanyId" = p_company_id
      AND b."IsDeleted" = FALSE
      AND (p_fiscal_year IS NULL OR b."FiscalYear" = p_fiscal_year)
      AND (p_status      IS NULL OR b."Status"     = p_status)
    ORDER BY b."FiscalYear" DESC, b."BudgetName"
    LIMIT p_limit OFFSET (p_page - 1) * p_limit;
END;
$function$;

-- Grant execute to app user
GRANT EXECUTE ON FUNCTION public.usp_acct_budget_list(integer, smallint, character varying, integer, integer) TO zentto_app;
