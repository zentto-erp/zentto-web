-- Fix: usp_acct_recurringentry_getdue - column reference "RecurringEntryId" is ambiguous
DROP FUNCTION IF EXISTS public.usp_acct_recurringentry_getdue(integer) CASCADE;
DROP FUNCTION IF EXISTS public.usp_acct_recurringentry_getdue(p_company_id integer)
RETURNS TABLE(
    "RecurringEntryId"   integer,
    "TemplateName"       character varying,
    "Frequency"          character varying,
    "NextExecutionDate"  date,
    "LastExecutedDate"   date,
    "TimesExecuted"      integer,
    "MaxExecutions"      integer,
    "TipoAsiento"        character varying,
    "Concepto"           character varying
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
           re."Concepto"
    FROM acct."RecurringEntry" re
    WHERE re."CompanyId"          = p_company_id
      AND re."IsActive"           = TRUE
      AND re."IsDeleted"          = FALSE
      AND re."NextExecutionDate" <= (NOW() AT TIME ZONE 'UTC')::DATE
      AND (re."MaxExecutions" IS NULL OR re."TimesExecuted" < re."MaxExecutions")
    ORDER BY re."NextExecutionDate";
END;
$function$;

GRANT EXECUTE ON FUNCTION public.usp_acct_recurringentry_getdue(integer) TO zentto_app;
