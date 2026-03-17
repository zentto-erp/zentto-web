-- Fix: Remove AnnualTotal from INSERT/UPDATE in budget functions (it's a computed column)

-- ── usp_acct_budget_insert ──────────────────────────────────────────────────
DROP FUNCTION IF EXISTS public.usp_acct_budget_insert(integer, character varying, smallint, character varying, text, integer, integer, text) CASCADE;
DROP FUNCTION IF EXISTS public.usp_acct_budget_insert(integer, character varying, smallint, character varying, text) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_acct_budget_insert(
    p_company_id       integer,
    p_budget_name      character varying,
    p_fiscal_year      smallint,
    p_cost_center_code character varying DEFAULT NULL::character varying,
    p_lines_json       text DEFAULT NULL::text,
    OUT p_budget_id    integer,
    OUT p_resultado    integer,
    OUT p_mensaje      text
)
RETURNS record
LANGUAGE plpgsql
AS $function$
DECLARE
    v_budget_id INTEGER;
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
            INSERT INTO acct."BudgetLine" (
                "BudgetId", "AccountCode",
                "Month01", "Month02", "Month03", "Month04", "Month05", "Month06",
                "Month07", "Month08", "Month09", "Month10", "Month11", "Month12",
                "Notes"
            )
            SELECT v_budget_id,
                   grp.ac,
                   COALESCE(SUM(CASE WHEN grp.mo = 1  THEN grp.amt ELSE 0 END), 0),
                   COALESCE(SUM(CASE WHEN grp.mo = 2  THEN grp.amt ELSE 0 END), 0),
                   COALESCE(SUM(CASE WHEN grp.mo = 3  THEN grp.amt ELSE 0 END), 0),
                   COALESCE(SUM(CASE WHEN grp.mo = 4  THEN grp.amt ELSE 0 END), 0),
                   COALESCE(SUM(CASE WHEN grp.mo = 5  THEN grp.amt ELSE 0 END), 0),
                   COALESCE(SUM(CASE WHEN grp.mo = 6  THEN grp.amt ELSE 0 END), 0),
                   COALESCE(SUM(CASE WHEN grp.mo = 7  THEN grp.amt ELSE 0 END), 0),
                   COALESCE(SUM(CASE WHEN grp.mo = 8  THEN grp.amt ELSE 0 END), 0),
                   COALESCE(SUM(CASE WHEN grp.mo = 9  THEN grp.amt ELSE 0 END), 0),
                   COALESCE(SUM(CASE WHEN grp.mo = 10 THEN grp.amt ELSE 0 END), 0),
                   COALESCE(SUM(CASE WHEN grp.mo = 11 THEN grp.amt ELSE 0 END), 0),
                   COALESCE(SUM(CASE WHEN grp.mo = 12 THEN grp.amt ELSE 0 END), 0),
                   MAX(grp.nt)
            FROM (
                SELECT (jrow->>'accountCode')::VARCHAR(20) AS ac,
                       CASE
                           WHEN jrow->>'periodCode' IS NOT NULL AND LENGTH(jrow->>'periodCode') = 6
                           THEN CAST(RIGHT(jrow->>'periodCode', 2) AS INTEGER)
                           ELSE 1
                       END AS mo,
                       COALESCE((jrow->>'amount')::NUMERIC(18,2), 0) AS amt,
                       (jrow->>'notes')::VARCHAR(200) AS nt
                FROM json_array_elements(p_lines_json::json) AS jrow
            ) grp
            GROUP BY grp.ac;
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

-- ── usp_acct_budget_update ──────────────────────────────────────────────────
DROP FUNCTION IF EXISTS public.usp_acct_budget_update(integer, integer, character varying, text, integer, text) CASCADE;
DROP FUNCTION IF EXISTS public.usp_acct_budget_update(integer, integer, character varying, text) CASCADE;
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
                "Notes"
            )
            SELECT p_budget_id,
                   grp.ac,
                   COALESCE(SUM(CASE WHEN grp.mo = 1  THEN grp.amt ELSE 0 END), 0),
                   COALESCE(SUM(CASE WHEN grp.mo = 2  THEN grp.amt ELSE 0 END), 0),
                   COALESCE(SUM(CASE WHEN grp.mo = 3  THEN grp.amt ELSE 0 END), 0),
                   COALESCE(SUM(CASE WHEN grp.mo = 4  THEN grp.amt ELSE 0 END), 0),
                   COALESCE(SUM(CASE WHEN grp.mo = 5  THEN grp.amt ELSE 0 END), 0),
                   COALESCE(SUM(CASE WHEN grp.mo = 6  THEN grp.amt ELSE 0 END), 0),
                   COALESCE(SUM(CASE WHEN grp.mo = 7  THEN grp.amt ELSE 0 END), 0),
                   COALESCE(SUM(CASE WHEN grp.mo = 8  THEN grp.amt ELSE 0 END), 0),
                   COALESCE(SUM(CASE WHEN grp.mo = 9  THEN grp.amt ELSE 0 END), 0),
                   COALESCE(SUM(CASE WHEN grp.mo = 10 THEN grp.amt ELSE 0 END), 0),
                   COALESCE(SUM(CASE WHEN grp.mo = 11 THEN grp.amt ELSE 0 END), 0),
                   COALESCE(SUM(CASE WHEN grp.mo = 12 THEN grp.amt ELSE 0 END), 0),
                   MAX(grp.nt)
            FROM (
                SELECT (jrow->>'accountCode')::VARCHAR(20) AS ac,
                       CASE
                           WHEN jrow->>'periodCode' IS NOT NULL AND LENGTH(jrow->>'periodCode') = 6
                           THEN CAST(RIGHT(jrow->>'periodCode', 2) AS INTEGER)
                           ELSE 1
                       END AS mo,
                       COALESCE((jrow->>'amount')::NUMERIC(18,2), 0) AS amt,
                       (jrow->>'notes')::VARCHAR(200) AS nt
                FROM json_array_elements(p_lines_json::json) AS jrow
            ) grp
            GROUP BY grp.ac;
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
