-- Fix: usp_acct_costcenter_list - ambiguous column references
DROP FUNCTION IF EXISTS public.usp_acct_costcenter_list(integer, character varying, integer, integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_acct_costcenter_list(
    p_company_id integer,
    p_search character varying DEFAULT NULL::character varying,
    p_page integer DEFAULT 1,
    p_limit integer DEFAULT 50
)
RETURNS TABLE(
    p_total_count bigint,
    "CostCenterId" integer,
    "CostCenterCode" character varying,
    "CostCenterName" character varying,
    "ParentCostCenterId" integer,
    "Level" smallint,
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
    FROM acct."CostCenter" cc2
    WHERE cc2."CompanyId" = p_company_id
      AND cc2."IsDeleted" = FALSE
      AND (p_search IS NULL
           OR cc2."CostCenterCode" ILIKE '%' || p_search || '%'
           OR cc2."CostCenterName" ILIKE '%' || p_search || '%');

    RETURN QUERY
    SELECT v_total_count,
           cc."CostCenterId",
           cc."CostCenterCode",
           cc."CostCenterName",
           cc."ParentCostCenterId",
           cc."Level",
           cc."IsActive"
    FROM acct."CostCenter" cc
    WHERE cc."CompanyId" = p_company_id
      AND cc."IsDeleted" = FALSE
      AND (p_search IS NULL
           OR cc."CostCenterCode" ILIKE '%' || p_search || '%'
           OR cc."CostCenterName" ILIKE '%' || p_search || '%')
    ORDER BY cc."CostCenterCode"
    LIMIT p_limit OFFSET (p_page - 1) * p_limit;
END;
$function$;

-- Fix: usp_acct_period_list - ambiguous column references
DROP FUNCTION IF EXISTS public.usp_acct_period_list(integer, smallint, character varying, integer, integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_acct_period_list(
    p_company_id integer,
    p_year smallint DEFAULT NULL::smallint,
    p_status character varying DEFAULT NULL::character varying,
    p_page integer DEFAULT 1,
    p_limit integer DEFAULT 50
)
RETURNS TABLE(
    p_total_count bigint,
    "FiscalPeriodId" integer,
    "PeriodCode" character(6),
    "PeriodName" character varying,
    "YearCode" smallint,
    "MonthCode" smallint,
    "StartDate" date,
    "EndDate" date,
    "Status" character varying,
    "ClosedAt" timestamp without time zone,
    "ClosedByUserId" integer,
    "Notes" character varying
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
    FROM acct."FiscalPeriod" fp2
    WHERE fp2."CompanyId" = p_company_id
      AND (p_year   IS NULL OR fp2."YearCode" = p_year)
      AND (p_status IS NULL OR fp2."Status"   = p_status);

    RETURN QUERY
    SELECT v_total_count,
           fp."FiscalPeriodId",
           fp."PeriodCode",
           fp."PeriodName",
           fp."YearCode",
           fp."MonthCode",
           fp."StartDate",
           fp."EndDate",
           fp."Status",
           fp."ClosedAt",
           fp."ClosedByUserId",
           fp."Notes"
    FROM acct."FiscalPeriod" fp
    WHERE fp."CompanyId" = p_company_id
      AND (p_year   IS NULL OR fp."YearCode" = p_year)
      AND (p_status IS NULL OR fp."Status"   = p_status)
    ORDER BY fp."PeriodCode"
    LIMIT p_limit OFFSET (p_page - 1) * p_limit;
END;
$function$;
