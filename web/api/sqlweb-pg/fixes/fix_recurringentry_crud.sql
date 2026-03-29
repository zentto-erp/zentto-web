-- Fix: usp_acct_recurringentry_insert
-- - Rename p_tipo_asiento -> p_entry_type (service sends EntryType -> p_entry_type)
-- - Rename p_concepto -> p_concept (service sends Concept -> p_concept)
-- - Add OUT p_recurring_entry_id
-- - Fix json alias "r" -> "jrow" to avoid ambiguity

DROP FUNCTION IF EXISTS public.usp_acct_recurringentry_insert(integer, character varying, character varying, date, character varying, character varying, integer, text, integer, text) CASCADE;
DROP FUNCTION IF EXISTS public.usp_acct_recurringentry_insert(integer, character varying, character varying, date, character varying, character varying, integer, text) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_acct_recurringentry_insert(
    p_company_id          integer,
    p_template_name       character varying,
    p_frequency           character varying,
    p_next_execution_date date,
    p_entry_type          character varying,
    p_concept             character varying,
    p_max_executions      integer DEFAULT NULL::integer,
    p_lines_json          text DEFAULT NULL::text,
    OUT p_recurring_entry_id integer,
    OUT p_resultado       integer,
    OUT p_mensaje         text
)
RETURNS record
LANGUAGE plpgsql
AS $function$
DECLARE
    v_re_id      INTEGER;
    v_sum_debit  NUMERIC(18,2);
    v_sum_credit NUMERIC(18,2);
BEGIN
    p_recurring_entry_id := 0;
    p_resultado := 0;
    p_mensaje   := '';

    IF p_template_name IS NULL OR LENGTH(TRIM(p_template_name)) = 0 THEN
        p_mensaje := 'El nombre de la plantilla es obligatorio.';
        RETURN;
    END IF;

    IF p_lines_json IS NOT NULL AND LENGTH(TRIM(p_lines_json)) > 2 THEN
        SELECT COALESCE(SUM((jrow->>'debit')::NUMERIC(18,2)), 0),
               COALESCE(SUM((jrow->>'credit')::NUMERIC(18,2)), 0)
        INTO v_sum_debit, v_sum_credit
        FROM json_array_elements(p_lines_json::json) AS jrow;

        IF ABS(COALESCE(v_sum_debit, 0) - COALESCE(v_sum_credit, 0)) > 0.01 THEN
            p_mensaje := 'Las lineas no estan balanceadas (Debe=' || v_sum_debit::TEXT
                       || ', Haber=' || v_sum_credit::TEXT || ').';
            RETURN;
        END IF;
    END IF;

    BEGIN
        INSERT INTO acct."RecurringEntry" (
            "CompanyId", "TemplateName", "Frequency", "NextExecutionDate",
            "MaxExecutions", "TipoAsiento", "Concepto"
        )
        VALUES (
            p_company_id, p_template_name, p_frequency, p_next_execution_date,
            p_max_executions, p_entry_type, p_concept
        )
        RETURNING "RecurringEntryId" INTO v_re_id;

        IF p_lines_json IS NOT NULL AND LENGTH(TRIM(p_lines_json)) > 2 THEN
            INSERT INTO acct."RecurringEntryLine" (
                "RecurringEntryId", "AccountCode", "Description", "CostCenterCode", "Debit", "Credit"
            )
            SELECT v_re_id,
                   (jrow->>'accountCode')::VARCHAR(20),
                   (jrow->>'description')::VARCHAR(200),
                   (jrow->>'costCenterCode')::VARCHAR(20),
                   COALESCE((jrow->>'debit')::NUMERIC(18,2), 0),
                   COALESCE((jrow->>'credit')::NUMERIC(18,2), 0)
            FROM json_array_elements(p_lines_json::json) AS jrow;
        END IF;

        p_recurring_entry_id := v_re_id;
        p_resultado := 1;
        p_mensaje   := 'Plantilla recurrente creada con ID ' || v_re_id::TEXT || '.';
    EXCEPTION WHEN OTHERS THEN
        p_recurring_entry_id := 0;
        p_resultado := 0;
        p_mensaje   := 'Error al crear plantilla recurrente: ' || SQLERRM;
    END;
END;
$function$;

GRANT EXECUTE ON FUNCTION public.usp_acct_recurringentry_insert(integer, character varying, character varying, date, character varying, character varying, integer, text) TO zentto_app;

-- Fix: usp_acct_recurringentry_update
-- - Rename p_concepto -> p_concept
-- - Add p_entry_type (optional) for updating TipoAsiento
-- - Add p_is_active (optional) for updating IsActive
-- - Make p_template_name, p_frequency, p_next_execution_date, p_concept optional (DEFAULT NULL)
DROP FUNCTION IF EXISTS public.usp_acct_recurringentry_update(integer, integer, character varying, character varying, date, character varying, integer, text, integer, text) CASCADE;
DROP FUNCTION IF EXISTS public.usp_acct_recurringentry_update(integer, integer, character varying, character varying, date, character varying, integer, text) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_acct_recurringentry_update(
    p_company_id           integer,
    p_recurring_entry_id   integer,
    p_template_name        character varying DEFAULT NULL::character varying,
    p_frequency            character varying DEFAULT NULL::character varying,
    p_next_execution_date  date DEFAULT NULL::date,
    p_concept              character varying DEFAULT NULL::character varying,
    p_max_executions       integer DEFAULT NULL::integer,
    p_lines_json           text DEFAULT NULL::text,
    p_entry_type           character varying DEFAULT NULL::character varying,
    p_is_active            boolean DEFAULT NULL::boolean,
    OUT p_resultado        integer,
    OUT p_mensaje          text
)
RETURNS record
LANGUAGE plpgsql
AS $function$
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    IF NOT EXISTS (
        SELECT 1 FROM acct."RecurringEntry"
        WHERE "CompanyId" = p_company_id AND "RecurringEntryId" = p_recurring_entry_id AND "IsDeleted" = FALSE
    ) THEN
        p_mensaje := 'Plantilla recurrente no encontrada.';
        RETURN;
    END IF;

    BEGIN
        UPDATE acct."RecurringEntry"
        SET "TemplateName"      = COALESCE(p_template_name,       "TemplateName"),
            "Frequency"         = COALESCE(p_frequency,           "Frequency"),
            "NextExecutionDate" = COALESCE(p_next_execution_date, "NextExecutionDate"),
            "Concepto"          = COALESCE(p_concept,             "Concepto"),
            "TipoAsiento"       = COALESCE(p_entry_type,          "TipoAsiento"),
            "MaxExecutions"     = COALESCE(p_max_executions,      "MaxExecutions"),
            "IsActive"          = COALESCE(p_is_active,           "IsActive")
        WHERE "RecurringEntryId" = p_recurring_entry_id;

        IF p_lines_json IS NOT NULL AND LENGTH(TRIM(p_lines_json)) > 2 THEN
            DELETE FROM acct."RecurringEntryLine" WHERE "RecurringEntryId" = p_recurring_entry_id;

            INSERT INTO acct."RecurringEntryLine" (
                "RecurringEntryId", "AccountCode", "Description", "CostCenterCode", "Debit", "Credit"
            )
            SELECT p_recurring_entry_id,
                   (jrow->>'accountCode')::VARCHAR(20),
                   (jrow->>'description')::VARCHAR(200),
                   (jrow->>'costCenterCode')::VARCHAR(20),
                   COALESCE((jrow->>'debit')::NUMERIC(18,2), 0),
                   COALESCE((jrow->>'credit')::NUMERIC(18,2), 0)
            FROM json_array_elements(p_lines_json::json) AS jrow;
        END IF;

        p_resultado := 1;
        p_mensaje   := 'Plantilla recurrente actualizada exitosamente.';
    EXCEPTION WHEN OTHERS THEN
        p_resultado := 0;
        p_mensaje   := 'Error al actualizar plantilla: ' || SQLERRM;
    END;
END;
$function$;

GRANT EXECUTE ON FUNCTION public.usp_acct_recurringentry_update(integer, integer, character varying, character varying, date, character varying, integer, text, character varying, boolean) TO zentto_app;
