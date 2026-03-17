-- Fix: usp_acct_recurringentry_get - column reference "RecurringEntryId" is ambiguous
DROP FUNCTION IF EXISTS public.usp_acct_recurringentry_get(integer, integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_acct_recurringentry_get(
    p_company_id          integer,
    p_recurring_entry_id  integer
)
RETURNS TABLE(
    "RecurringEntryId"   integer,
    "TemplateName"       character varying,
    "Frequency"          character varying,
    "NextExecutionDate"  date,
    "LastExecutedDate"   date,
    "TimesExecuted"      integer,
    "MaxExecutions"      integer,
    "TipoAsiento"        character varying,
    "Concepto"           character varying,
    "IsActive"           boolean,
    "CreatedAt"          timestamp without time zone
)
LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT re."RecurringEntryId",
           re."TemplateName",
           re."Frequency",
           re."NextExecutionDate",
           re."LastExecutedDate",
           re."TimesExecuted",
           re."MaxExecutions",
           re."TipoAsiento",
           re."Concepto",
           re."IsActive",
           re."CreatedAt"
    FROM acct."RecurringEntry" re
    WHERE re."CompanyId"        = p_company_id
      AND re."RecurringEntryId" = p_recurring_entry_id
      AND re."IsDeleted"        = FALSE;
END;
$function$;

GRANT EXECUTE ON FUNCTION public.usp_acct_recurringentry_get(integer, integer) TO zentto_app;

-- Fix: usp_acct_recurringentry_getlines - add p_company_id param (service sends CompanyId too)
DROP FUNCTION IF EXISTS public.usp_acct_recurringentry_getlines(integer) CASCADE;
DROP FUNCTION IF EXISTS public.usp_acct_recurringentry_getlines(integer, integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_acct_recurringentry_getlines(
    p_company_id          integer,
    p_recurring_entry_id  integer
)
RETURNS TABLE(
    "LineId"           integer,
    "AccountCode"      character varying,
    "AccountName"      character varying,
    "Description"      character varying,
    "CostCenterCode"   character varying,
    "Debit"            numeric,
    "Credit"           numeric
)
LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT rel."LineId",
           rel."AccountCode",
           a."AccountName",
           rel."Description",
           rel."CostCenterCode",
           rel."Debit",
           rel."Credit"
    FROM acct."RecurringEntryLine" rel
    LEFT JOIN acct."Account" a ON a."AccountCode" = rel."AccountCode"
                               AND a."CompanyId" = p_company_id
                               AND COALESCE(a."IsDeleted", FALSE) = FALSE
    WHERE rel."RecurringEntryId" = p_recurring_entry_id
    ORDER BY rel."LineId";
END;
$function$;

GRANT EXECUTE ON FUNCTION public.usp_acct_recurringentry_getlines(integer, integer) TO zentto_app;
