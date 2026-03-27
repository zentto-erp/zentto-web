-- Fix: usp_acct_period_close, usp_acct_period_reopen, usp_acct_period_generateclosingentries
-- Change p_user_id from integer to text (service sends username string like "admin" or "API")
-- with internal try-cast to integer (NULL if not numeric)

-- ── usp_acct_period_close ──────────────────────────────────────────────────
DROP FUNCTION IF EXISTS public.usp_acct_period_close(integer, character, integer) CASCADE;
DROP FUNCTION IF EXISTS public.usp_acct_period_close(integer, character, text) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_acct_period_close(
    p_company_id  integer,
    p_period_code character,
    p_user_id     text DEFAULT NULL,
    OUT p_resultado integer,
    OUT p_mensaje   text
)
RETURNS record
LANGUAGE plpgsql
AS $function$
DECLARE
    v_period_fmt  VARCHAR(7);
    v_draft_count INTEGER;
    v_user_int    INTEGER;
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    -- Try to convert user_id to integer (NULL if username string like "admin")
    BEGIN v_user_int := p_user_id::INTEGER; EXCEPTION WHEN OTHERS THEN v_user_int := NULL; END;

    IF NOT EXISTS (
        SELECT 1 FROM acct."FiscalPeriod"
        WHERE "CompanyId" = p_company_id AND "PeriodCode" = p_period_code AND "Status" = 'OPEN'
    ) THEN
        p_mensaje := 'Periodo ' || p_period_code || ' no encontrado o no esta abierto.';
        RETURN;
    END IF;

    v_period_fmt := LEFT(p_period_code, 4) || '-' || RIGHT(p_period_code, 2);

    SELECT COUNT(*) INTO v_draft_count
    FROM acct."JournalEntry"
    WHERE "CompanyId"  = p_company_id
      AND "PeriodCode" = v_period_fmt
      AND "Status"     = 'DRAFT'
      AND "IsDeleted"  = FALSE;

    IF v_draft_count > 0 THEN
        p_mensaje := 'Existen ' || v_draft_count::TEXT
                   || ' asientos en borrador. Apruebelos o eliminelos antes de cerrar.';
        RETURN;
    END IF;

    BEGIN
        UPDATE acct."FiscalPeriod"
        SET "Status"         = 'CLOSED',
            "ClosedAt"       = (NOW() AT TIME ZONE 'UTC'),
            "ClosedByUserId" = v_user_int,
            "UpdatedAt"      = (NOW() AT TIME ZONE 'UTC')
        WHERE "CompanyId"  = p_company_id
          AND "PeriodCode" = p_period_code
          AND "Status"     = 'OPEN';

        p_resultado := 1;
        p_mensaje   := 'Periodo ' || p_period_code || ' cerrado exitosamente.';
    EXCEPTION WHEN OTHERS THEN
        p_resultado := 0;
        p_mensaje   := 'Error al cerrar periodo: ' || SQLERRM;
    END;
END;
$function$;

GRANT EXECUTE ON FUNCTION public.usp_acct_period_close(integer, character, text) TO zentto_app;

-- ── usp_acct_period_reopen ─────────────────────────────────────────────────
DROP FUNCTION IF EXISTS public.usp_acct_period_reopen(integer, character, integer) CASCADE;
DROP FUNCTION IF EXISTS public.usp_acct_period_reopen(integer, character, text) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_acct_period_reopen(
    p_company_id  integer,
    p_period_code character,
    p_user_id     text DEFAULT NULL,
    OUT p_resultado integer,
    OUT p_mensaje   text
)
RETURNS record
LANGUAGE plpgsql
AS $function$
DECLARE
    v_current_status VARCHAR(10);
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    SELECT "Status"
    INTO v_current_status
    FROM acct."FiscalPeriod"
    WHERE "CompanyId" = p_company_id AND "PeriodCode" = p_period_code;

    IF v_current_status IS NULL THEN
        p_mensaje := 'Periodo ' || p_period_code || ' no encontrado.';
        RETURN;
    END IF;

    IF v_current_status = 'LOCKED' THEN
        p_mensaje := 'Periodo ' || p_period_code || ' esta bloqueado y no puede reabrirse.';
        RETURN;
    END IF;

    IF v_current_status <> 'CLOSED' THEN
        p_mensaje := 'Periodo ' || p_period_code || ' no esta cerrado (estado actual: ' || v_current_status || ').';
        RETURN;
    END IF;

    UPDATE acct."FiscalPeriod"
    SET "Status"         = 'OPEN',
        "ClosedAt"       = NULL,
        "ClosedByUserId" = NULL,
        "UpdatedAt"      = (NOW() AT TIME ZONE 'UTC')
    WHERE "CompanyId"  = p_company_id
      AND "PeriodCode" = p_period_code
      AND "Status"     = 'CLOSED';

    p_resultado := 1;
    p_mensaje   := 'Periodo ' || p_period_code || ' reabierto exitosamente.';
END;
$function$;

GRANT EXECUTE ON FUNCTION public.usp_acct_period_reopen(integer, character, text) TO zentto_app;

-- ── usp_acct_period_generateclosingentries ──────────────────────────────────
DROP FUNCTION IF EXISTS public.usp_acct_period_generateclosingentries(integer, character, integer) CASCADE;
DROP FUNCTION IF EXISTS public.usp_acct_period_generateclosingentries(integer, character, text) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_acct_period_generateclosingentries(
    p_company_id  integer,
    p_period_code character,
    p_user_id     text DEFAULT NULL,
    OUT p_resultado integer,
    OUT p_mensaje   text
)
RETURNS record
LANGUAGE plpgsql
AS $function$
DECLARE
    v_start_date      DATE;
    v_end_date        DATE;
    v_period_fmt      VARCHAR(7);
    v_seq_num         INTEGER;
    v_entry_number    VARCHAR(40);
    v_branch_id       INTEGER;
    v_entry_id        BIGINT;
    v_line_count      INTEGER;
    v_retained_acct   BIGINT;
    v_net_result      NUMERIC(18,2);
    v_td              NUMERIC(18,2);
    v_tc              NUMERIC(18,2);
    v_user_int        INTEGER;
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    -- Try to convert user_id to integer (NULL if username string like "admin")
    BEGIN v_user_int := p_user_id::INTEGER; EXCEPTION WHEN OTHERS THEN v_user_int := NULL; END;

    SELECT "StartDate", "EndDate"
    INTO v_start_date, v_end_date
    FROM acct."FiscalPeriod"
    WHERE "CompanyId" = p_company_id AND "PeriodCode" = p_period_code;

    IF v_start_date IS NULL THEN
        p_mensaje := 'Periodo ' || p_period_code || ' no encontrado.';
        RETURN;
    END IF;

    v_period_fmt := LEFT(p_period_code, 4) || '-' || RIGHT(p_period_code, 2);

    -- Saldos de cuentas I y G en el periodo
    CREATE TEMP TABLE _closing_saldos (
        "AccountId"   BIGINT,
        "AccountCode" VARCHAR(40),
        "AccountType" CHAR(1),
        "Saldo"       NUMERIC(18,2)
    ) ON COMMIT DROP;

    INSERT INTO _closing_saldos ("AccountId", "AccountCode", "AccountType", "Saldo")
    SELECT a."AccountId",
           a."AccountCode",
           a."AccountType",
           SUM(jel."DebitAmount" - jel."CreditAmount")
    FROM acct."JournalEntryLine" jel
    JOIN acct."JournalEntry" je ON je."JournalEntryId" = jel."JournalEntryId"
    JOIN acct."Account" a       ON a."AccountId"       = jel."AccountId"
    WHERE je."CompanyId"  = p_company_id
      AND je."PeriodCode" = v_period_fmt
      AND je."Status"     = 'APPROVED'
      AND je."IsDeleted"  = FALSE
      AND a."AccountType" IN ('I', 'G')
      AND COALESCE(a."IsDeleted", FALSE) = FALSE
    GROUP BY a."AccountId", a."AccountCode", a."AccountType"
    HAVING SUM(jel."DebitAmount" - jel."CreditAmount") <> 0;

    IF NOT EXISTS (SELECT 1 FROM _closing_saldos) THEN
        p_resultado := 1;
        p_mensaje   := 'No hay saldos de I/G para cerrar en el periodo ' || p_period_code || '.';
        RETURN;
    END IF;

    BEGIN
        SELECT COALESCE(MAX(
            CAST(RIGHT("EntryNumber", 4) AS INTEGER)
        ), 0) + 1
        INTO v_seq_num
        FROM acct."JournalEntry"
        WHERE "CompanyId" = p_company_id AND "EntryType" = 'CIE' AND "PeriodCode" = v_period_fmt;

        v_entry_number := 'CIE-' || p_period_code || '-' || LPAD(v_seq_num::TEXT, 4, '0');

        SELECT "BranchId" INTO v_branch_id
        FROM cfg."Branch"
        WHERE "CompanyId" = p_company_id AND "IsDeleted" = FALSE
        ORDER BY "BranchId"
        LIMIT 1;

        IF v_branch_id IS NULL THEN v_branch_id := 1; END IF;

        INSERT INTO acct."JournalEntry" (
            "CompanyId", "BranchId", "EntryNumber", "EntryDate", "PeriodCode",
            "EntryType", "Concept", "CurrencyCode", "TotalDebit", "TotalCredit",
            "Status", "SourceModule", "CreatedByUserId"
        )
        VALUES (
            p_company_id, v_branch_id, v_entry_number, v_end_date, v_period_fmt,
            'CIE', 'Asiento de cierre - Periodo ' || p_period_code,
            'VES', 0, 0, 'APPROVED', 'CONTABILIDAD', v_user_int
        )
        RETURNING "JournalEntryId" INTO v_entry_id;

        -- Lineas que revierten cada cuenta I/G
        INSERT INTO acct."JournalEntryLine" (
            "JournalEntryId", "LineNumber", "AccountId", "AccountCodeSnapshot",
            "Description", "DebitAmount", "CreditAmount"
        )
        SELECT v_entry_id,
               ROW_NUMBER() OVER (ORDER BY "AccountCode"),
               "AccountId",
               "AccountCode",
               'Cierre ' || "AccountCode",
               CASE WHEN "Saldo" < 0 THEN ABS("Saldo") ELSE 0 END,
               CASE WHEN "Saldo" > 0 THEN "Saldo"      ELSE 0 END
        FROM _closing_saldos;

        SELECT COUNT(*) INTO v_line_count FROM _closing_saldos;

        -- Determinar resultado neto (I - G)
        SELECT COALESCE(SUM(CASE WHEN "AccountType" = 'I' THEN -"Saldo" ELSE "Saldo" END), 0)
        INTO v_net_result
        FROM _closing_saldos;

        -- Cuenta de utilidades retenidas
        SELECT a."AccountId" INTO v_retained_acct
        FROM acct."Account" a
        WHERE a."CompanyId"  = p_company_id
          AND a."AccountType" = 'P'
          AND a."AccountCode" LIKE '3%'
          AND a."AllowsPosting" = TRUE
          AND a."IsDeleted" = FALSE
        ORDER BY a."AccountCode"
        LIMIT 1;

        IF v_retained_acct IS NOT NULL THEN
            SELECT "AccountCode" INTO v_entry_number
            FROM acct."Account"
            WHERE "AccountId" = v_retained_acct;

            v_td := CASE WHEN v_net_result < 0 THEN ABS(v_net_result) ELSE 0 END;
            v_tc := CASE WHEN v_net_result > 0 THEN v_net_result      ELSE 0 END;

            INSERT INTO acct."JournalEntryLine" (
                "JournalEntryId", "LineNumber", "AccountId", "AccountCodeSnapshot",
                "Description", "DebitAmount", "CreditAmount"
            )
            VALUES (
                v_entry_id,
                v_line_count + 1,
                v_retained_acct,
                v_entry_number,
                'Resultado del ejercicio',
                v_td, v_tc
            );
        END IF;

        -- Actualizar totales del asiento
        SELECT SUM("DebitAmount"), SUM("CreditAmount")
        INTO v_td, v_tc
        FROM acct."JournalEntryLine"
        WHERE "JournalEntryId" = v_entry_id;

        UPDATE acct."JournalEntry"
        SET "TotalDebit"  = COALESCE(v_td, 0),
            "TotalCredit" = COALESCE(v_tc, 0)
        WHERE "JournalEntryId" = v_entry_id;

        p_resultado := 1;
        p_mensaje   := 'Asiento de cierre generado: ' || v_entry_number || '.';
    EXCEPTION WHEN OTHERS THEN
        p_resultado := 0;
        p_mensaje   := 'Error al generar cierre: ' || SQLERRM;
    END;
END;
$function$;

GRANT EXECUTE ON FUNCTION public.usp_acct_period_generateclosingentries(integer, character, text) TO zentto_app;
