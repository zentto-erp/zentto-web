-- Fix: usp_acct_budget_get - column reference "BudgetId" is ambiguous
DROP FUNCTION IF EXISTS public.usp_acct_budget_get(integer, integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_acct_budget_get(
    p_company_id integer,
    p_budget_id  integer
)
RETURNS TABLE(
    "BudgetId"       integer,
    "BudgetName"     character varying,
    "FiscalYear"     smallint,
    "CostCenterCode" character varying,
    "Status"         character varying,
    "Notes"          character varying,
    "CreatedAt"      timestamp without time zone,
    "UpdatedAt"      timestamp without time zone
)
LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT b."BudgetId",
           b."BudgetName",
           b."FiscalYear",
           b."CostCenterCode",
           b."Status",
           b."Notes",
           b."CreatedAt",
           b."UpdatedAt"
    FROM acct."Budget" b
    WHERE b."CompanyId" = p_company_id
      AND b."BudgetId"  = p_budget_id
      AND b."IsDeleted" = FALSE;
END;
$function$;

GRANT EXECUTE ON FUNCTION public.usp_acct_budget_get(integer, integer) TO zentto_app;

-- Fix: usp_acct_budget_insert
-- - Rename p_name -> p_budget_name (service sends BudgetName -> p_budget_name)
-- - Add OUT p_budget_id
-- - Accept lines JSON with periodCode/amount format (service sends: {accountCode, periodCode, amount})
-- - Convert periodCode (e.g. "202601") month number to put amount in correct Month field
DROP FUNCTION IF EXISTS public.usp_acct_budget_insert(integer, character varying, smallint, character varying, text, integer, text) CASCADE;
DROP FUNCTION IF EXISTS public.usp_acct_budget_insert(integer, character varying, smallint, character varying, text) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_acct_budget_insert(
    p_company_id      integer,
    p_budget_name     character varying,
    p_fiscal_year     smallint,
    p_cost_center_code character varying DEFAULT NULL::character varying,
    p_lines_json      text DEFAULT NULL::text,
    OUT p_budget_id   integer,
    OUT p_resultado   integer,
    OUT p_mensaje     text
)
RETURNS record
LANGUAGE plpgsql
AS $function$
DECLARE
    v_budget_id INTEGER;
    r           JSON;
    v_month     INTEGER;
    v_amount    NUMERIC(18,2);
    v_months    NUMERIC(18,2)[] := ARRAY[0,0,0,0,0,0,0,0,0,0,0,0];
BEGIN
    p_budget_id := 0;
    p_resultado := 0;
    p_mensaje   := '';

    IF p_budget_name IS NULL OR LENGTH(TRIM(p_budget_name)) = 0 THEN
        p_mensaje := 'El nombre del presupuesto es obligatorio.';
        RETURN;
    END IF;

    BEGIN
        INSERT INTO acct."Budget" ("CompanyId", "BudgetName", "FiscalYear", "CostCenterCode")
        VALUES (p_company_id, p_budget_name, p_fiscal_year, p_cost_center_code)
        RETURNING "BudgetId" INTO v_budget_id;

        IF p_lines_json IS NOT NULL AND LENGTH(TRIM(p_lines_json)) > 2 THEN
            -- Group lines by accountCode, accumulating amounts per month
            INSERT INTO acct."BudgetLine" (
                "BudgetId", "AccountCode",
                "Month01", "Month02", "Month03", "Month04", "Month05", "Month06",
                "Month07", "Month08", "Month09", "Month10", "Month11", "Month12",
                "AnnualTotal", "Notes"
            )
            SELECT v_budget_id,
                   grp."AccountCode",
                   COALESCE(SUM(CASE WHEN grp."Month" = 1  THEN grp."Amount" ELSE 0 END), 0),
                   COALESCE(SUM(CASE WHEN grp."Month" = 2  THEN grp."Amount" ELSE 0 END), 0),
                   COALESCE(SUM(CASE WHEN grp."Month" = 3  THEN grp."Amount" ELSE 0 END), 0),
                   COALESCE(SUM(CASE WHEN grp."Month" = 4  THEN grp."Amount" ELSE 0 END), 0),
                   COALESCE(SUM(CASE WHEN grp."Month" = 5  THEN grp."Amount" ELSE 0 END), 0),
                   COALESCE(SUM(CASE WHEN grp."Month" = 6  THEN grp."Amount" ELSE 0 END), 0),
                   COALESCE(SUM(CASE WHEN grp."Month" = 7  THEN grp."Amount" ELSE 0 END), 0),
                   COALESCE(SUM(CASE WHEN grp."Month" = 8  THEN grp."Amount" ELSE 0 END), 0),
                   COALESCE(SUM(CASE WHEN grp."Month" = 9  THEN grp."Amount" ELSE 0 END), 0),
                   COALESCE(SUM(CASE WHEN grp."Month" = 10 THEN grp."Amount" ELSE 0 END), 0),
                   COALESCE(SUM(CASE WHEN grp."Month" = 11 THEN grp."Amount" ELSE 0 END), 0),
                   COALESCE(SUM(CASE WHEN grp."Month" = 12 THEN grp."Amount" ELSE 0 END), 0),
                   COALESCE(SUM(grp."Amount"), 0),
                   MAX(grp."Notes")
            FROM (
                SELECT (r->>'accountCode')::VARCHAR(20) AS "AccountCode",
                       -- periodCode is YYYYMM (e.g. 202601), extract month
                       CASE
                           WHEN r->>'periodCode' IS NOT NULL AND LENGTH(r->>'periodCode') = 6
                           THEN CAST(RIGHT(r->>'periodCode', 2) AS INTEGER)
                           ELSE 1
                       END AS "Month",
                       COALESCE((r->>'amount')::NUMERIC(18,2), 0) AS "Amount",
                       (r->>'notes')::VARCHAR(200) AS "Notes"
                FROM json_array_elements(p_lines_json::json) AS r
            ) grp
            GROUP BY grp."AccountCode";
        END IF;

        p_budget_id := v_budget_id;
        p_resultado := 1;
        p_mensaje   := 'Presupuesto creado con ID ' || v_budget_id::TEXT || '.';
    EXCEPTION WHEN OTHERS THEN
        p_budget_id := 0;
        p_resultado := 0;
        p_mensaje   := 'Error al crear presupuesto: ' || SQLERRM;
    END;
END;
$function$;

GRANT EXECUTE ON FUNCTION public.usp_acct_budget_insert(integer, character varying, smallint, character varying, text) TO zentto_app;

-- Fix: usp_acct_budget_update
-- - Rename p_name -> p_budget_name (service sends BudgetName -> p_budget_name)
-- - Accept lines JSON with periodCode/amount format
-- - Make p_budget_name and p_lines_json optional (DEFAULT NULL)
DROP FUNCTION IF EXISTS public.usp_acct_budget_update(integer, integer, character varying, text, integer, text) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_acct_budget_update(
    p_company_id  integer,
    p_budget_id   integer,
    p_budget_name character varying DEFAULT NULL::character varying,
    p_lines_json  text DEFAULT NULL::text,
    OUT p_resultado integer,
    OUT p_mensaje   text
)
RETURNS record
LANGUAGE plpgsql
AS $function$
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    IF NOT EXISTS (
        SELECT 1 FROM acct."Budget"
        WHERE "CompanyId" = p_company_id AND "BudgetId" = p_budget_id AND "IsDeleted" = FALSE
    ) THEN
        p_mensaje := 'Presupuesto no encontrado.';
        RETURN;
    END IF;

    BEGIN
        IF p_budget_name IS NOT NULL THEN
            UPDATE acct."Budget"
            SET "BudgetName" = p_budget_name,
                "UpdatedAt"  = (NOW() AT TIME ZONE 'UTC')
            WHERE "BudgetId" = p_budget_id;
        END IF;

        IF p_lines_json IS NOT NULL AND LENGTH(TRIM(p_lines_json)) > 2 THEN
            DELETE FROM acct."BudgetLine" WHERE "BudgetId" = p_budget_id;

            INSERT INTO acct."BudgetLine" (
                "BudgetId", "AccountCode",
                "Month01", "Month02", "Month03", "Month04", "Month05", "Month06",
                "Month07", "Month08", "Month09", "Month10", "Month11", "Month12",
                "AnnualTotal", "Notes"
            )
            SELECT p_budget_id,
                   grp."AccountCode",
                   COALESCE(SUM(CASE WHEN grp."Month" = 1  THEN grp."Amount" ELSE 0 END), 0),
                   COALESCE(SUM(CASE WHEN grp."Month" = 2  THEN grp."Amount" ELSE 0 END), 0),
                   COALESCE(SUM(CASE WHEN grp."Month" = 3  THEN grp."Amount" ELSE 0 END), 0),
                   COALESCE(SUM(CASE WHEN grp."Month" = 4  THEN grp."Amount" ELSE 0 END), 0),
                   COALESCE(SUM(CASE WHEN grp."Month" = 5  THEN grp."Amount" ELSE 0 END), 0),
                   COALESCE(SUM(CASE WHEN grp."Month" = 6  THEN grp."Amount" ELSE 0 END), 0),
                   COALESCE(SUM(CASE WHEN grp."Month" = 7  THEN grp."Amount" ELSE 0 END), 0),
                   COALESCE(SUM(CASE WHEN grp."Month" = 8  THEN grp."Amount" ELSE 0 END), 0),
                   COALESCE(SUM(CASE WHEN grp."Month" = 9  THEN grp."Amount" ELSE 0 END), 0),
                   COALESCE(SUM(CASE WHEN grp."Month" = 10 THEN grp."Amount" ELSE 0 END), 0),
                   COALESCE(SUM(CASE WHEN grp."Month" = 11 THEN grp."Amount" ELSE 0 END), 0),
                   COALESCE(SUM(CASE WHEN grp."Month" = 12 THEN grp."Amount" ELSE 0 END), 0),
                   COALESCE(SUM(grp."Amount"), 0),
                   MAX(grp."Notes")
            FROM (
                SELECT (r->>'accountCode')::VARCHAR(20) AS "AccountCode",
                       CASE
                           WHEN r->>'periodCode' IS NOT NULL AND LENGTH(r->>'periodCode') = 6
                           THEN CAST(RIGHT(r->>'periodCode', 2) AS INTEGER)
                           ELSE 1
                       END AS "Month",
                       COALESCE((r->>'amount')::NUMERIC(18,2), 0) AS "Amount",
                       (r->>'notes')::VARCHAR(200) AS "Notes"
                FROM json_array_elements(p_lines_json::json) AS r
            ) grp
            GROUP BY grp."AccountCode";
        END IF;

        p_resultado := 1;
        p_mensaje   := 'Presupuesto actualizado exitosamente.';
    EXCEPTION WHEN OTHERS THEN
        p_resultado := 0;
        p_mensaje   := 'Error al actualizar presupuesto: ' || SQLERRM;
    END;
END;
$function$;

GRANT EXECUTE ON FUNCTION public.usp_acct_budget_update(integer, integer, character varying, text) TO zentto_app;
