-- Fix: usp_acct_recurringentry_execute
-- - Change p_user_id from integer to text (service sends username string)
-- - Add OUT p_asiento_id bigint (service expects AsientoId output)
DROP FUNCTION IF EXISTS public.usp_acct_recurringentry_execute(integer, integer, date, integer, integer, text) CASCADE;
DROP FUNCTION IF EXISTS public.usp_acct_recurringentry_execute(integer, integer, date, text, integer, text) CASCADE;
DROP FUNCTION IF EXISTS public.usp_acct_recurringentry_execute(integer, integer, date, integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_acct_recurringentry_execute(
    p_company_id          integer,
    p_recurring_entry_id  integer,
    p_execution_date      date,
    p_user_id             text DEFAULT NULL,
    OUT p_asiento_id      bigint,
    OUT p_resultado       integer,
    OUT p_mensaje         text
)
RETURNS record
LANGUAGE plpgsql
AS $function$
DECLARE
    v_template_name VARCHAR(200);
    v_frequency     VARCHAR(10);
    v_tipo_asiento  VARCHAR(20);
    v_concepto      VARCHAR(300);
    v_max_exec      INTEGER;
    v_times_exec    INTEGER;
    v_is_active     BOOLEAN;
    v_period_fmt    VARCHAR(7);
    v_branch_id     INTEGER;
    v_seq_num       INTEGER;
    v_entry_number  VARCHAR(40);
    v_entry_id      BIGINT;
    v_td            NUMERIC(18,2);
    v_tc            NUMERIC(18,2);
    v_next_date     DATE;
    v_user_int      INTEGER;
BEGIN
    p_asiento_id := 0;
    p_resultado  := 0;
    p_mensaje    := '';

    -- Try to convert user_id to integer (NULL if username string like "admin")
    BEGIN v_user_int := p_user_id::INTEGER; EXCEPTION WHEN OTHERS THEN v_user_int := NULL; END;

    SELECT "TemplateName", "Frequency", "TipoAsiento", "Concepto",
           "MaxExecutions", "TimesExecuted", "IsActive"
    INTO v_template_name, v_frequency, v_tipo_asiento, v_concepto,
         v_max_exec, v_times_exec, v_is_active
    FROM acct."RecurringEntry"
    WHERE "CompanyId" = p_company_id AND "RecurringEntryId" = p_recurring_entry_id AND "IsDeleted" = FALSE;

    IF v_template_name IS NULL THEN
        p_mensaje := 'Plantilla recurrente no encontrada.';
        RETURN;
    END IF;

    IF NOT v_is_active THEN
        p_mensaje := 'La plantilla esta inactiva.';
        RETURN;
    END IF;

    IF v_max_exec IS NOT NULL AND v_times_exec >= v_max_exec THEN
        p_mensaje := 'La plantilla alcanzo el maximo de ejecuciones (' || v_max_exec::TEXT || ').';
        RETURN;
    END IF;

    BEGIN
        v_period_fmt := TO_CHAR(p_execution_date, 'YYYY') || '-' || TO_CHAR(p_execution_date, 'MM');

        SELECT "BranchId" INTO v_branch_id
        FROM cfg."Branch"
        WHERE "CompanyId" = p_company_id AND "IsDeleted" = FALSE
        ORDER BY "BranchId"
        LIMIT 1;
        IF v_branch_id IS NULL THEN v_branch_id := 1; END IF;

        SELECT COALESCE(MAX(
            CAST(RIGHT("EntryNumber", 6) AS INTEGER)
        ), 0) + 1
        INTO v_seq_num
        FROM acct."JournalEntry"
        WHERE "CompanyId" = p_company_id AND "EntryType" = v_tipo_asiento AND "PeriodCode" = v_period_fmt;

        v_entry_number := v_tipo_asiento || '-'
            || REPLACE(v_period_fmt, '-', '') || '-'
            || LPAD(v_seq_num::TEXT, 6, '0');

        INSERT INTO acct."JournalEntry" (
            "CompanyId", "BranchId", "EntryNumber", "EntryDate", "PeriodCode",
            "EntryType", "Concept", "CurrencyCode", "TotalDebit", "TotalCredit",
            "Status", "SourceModule", "CreatedByUserId"
        )
        VALUES (
            p_company_id, v_branch_id, v_entry_number, p_execution_date, v_period_fmt,
            v_tipo_asiento, v_concepto || ' [Recurrente: ' || v_template_name || ']',
            'VES', 0, 0, 'APPROVED', 'RECURRENTE', v_user_int
        )
        RETURNING "JournalEntryId" INTO v_entry_id;

        INSERT INTO acct."JournalEntryLine" (
            "JournalEntryId", "LineNumber", "AccountId", "AccountCodeSnapshot",
            "Description", "DebitAmount", "CreditAmount", "CostCenterCode"
        )
        SELECT v_entry_id,
               ROW_NUMBER() OVER (ORDER BY rel."LineId"),
               a."AccountId",
               rel."AccountCode",
               rel."Description",
               rel."Debit",
               rel."Credit",
               rel."CostCenterCode"
        FROM acct."RecurringEntryLine" rel
        JOIN acct."Account" a ON a."AccountCode" = rel."AccountCode"
                              AND a."CompanyId"  = p_company_id
                              AND COALESCE(a."IsDeleted", FALSE) = FALSE
        WHERE rel."RecurringEntryId" = p_recurring_entry_id;

        SELECT SUM("DebitAmount"), SUM("CreditAmount")
        INTO v_td, v_tc
        FROM acct."JournalEntryLine" WHERE "JournalEntryId" = v_entry_id;

        UPDATE acct."JournalEntry"
        SET "TotalDebit" = COALESCE(v_td, 0), "TotalCredit" = COALESCE(v_tc, 0)
        WHERE "JournalEntryId" = v_entry_id;

        -- Calcular siguiente fecha de ejecucion
        v_next_date := CASE v_frequency
            WHEN 'DAILY'     THEN p_execution_date + INTERVAL '1 day'
            WHEN 'WEEKLY'    THEN p_execution_date + INTERVAL '1 week'
            WHEN 'MONTHLY'   THEN p_execution_date + INTERVAL '1 month'
            WHEN 'QUARTERLY' THEN p_execution_date + INTERVAL '3 months'
            WHEN 'YEARLY'    THEN p_execution_date + INTERVAL '1 year'
            ELSE p_execution_date + INTERVAL '1 month'
        END;

        UPDATE acct."RecurringEntry"
        SET "NextExecutionDate" = v_next_date,
            "LastExecutedDate"  = p_execution_date,
            "TimesExecuted"     = "TimesExecuted" + 1,
            "IsActive"          = CASE
                WHEN "MaxExecutions" IS NOT NULL AND "TimesExecuted" + 1 >= "MaxExecutions" THEN FALSE
                ELSE TRUE
            END
        WHERE "RecurringEntryId" = p_recurring_entry_id;

        p_asiento_id := v_entry_id;
        p_resultado  := 1;
        p_mensaje    := 'Asiento ' || v_entry_number || ' generado desde plantilla recurrente.';
    EXCEPTION WHEN OTHERS THEN
        p_asiento_id := 0;
        p_resultado  := 0;
        p_mensaje    := 'Error al ejecutar recurrente: ' || SQLERRM;
    END;
END;
$function$;

GRANT EXECUTE ON FUNCTION public.usp_acct_recurringentry_execute(integer, integer, date, text) TO zentto_app;
