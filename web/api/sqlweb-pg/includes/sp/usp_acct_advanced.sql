-- =============================================================================
--  Archivo : usp_acct_advanced.sql  (PostgreSQL)
--  Auto-convertido desde T-SQL (SQL Server) a PL/pgSQL
--  Fecha de conversion: 2026-03-16
--  Fuente original: web/api/sqlweb/includes/sp/usp_acct_advanced.sql
--
--  Esquema : acct (contabilidad avanzada)
--  Tablas  :
--    acct.FiscalPeriod, acct.CostCenter, acct.Budget, acct.BudgetLine,
--    acct.RecurringEntry, acct.RecurringEntryLine
--
--  Funciones (36):
--    Periodos (6): usp_Acct_Period_List, usp_Acct_Period_EnsureYear,
--      usp_Acct_Period_Close, usp_Acct_Period_Reopen,
--      usp_Acct_Period_GenerateClosingEntries, usp_Acct_Period_Checklist
--    Centros de costo (6): usp_Acct_CostCenter_List, usp_Acct_CostCenter_Get,
--      usp_Acct_CostCenter_Insert, usp_Acct_CostCenter_Update,
--      usp_Acct_CostCenter_Delete, usp_Acct_Report_PnLByCostCenter
--    Presupuestos (7): usp_Acct_Budget_List, usp_Acct_Budget_Get,
--      usp_Acct_Budget_GetLines, usp_Acct_Budget_Insert, usp_Acct_Budget_Update,
--      usp_Acct_Budget_Delete, usp_Acct_Budget_Variance
--    Recurrentes (8): usp_Acct_RecurringEntry_List, usp_Acct_RecurringEntry_Get,
--      usp_Acct_RecurringEntry_GetLines, usp_Acct_RecurringEntry_Insert,
--      usp_Acct_RecurringEntry_Update, usp_Acct_RecurringEntry_Delete,
--      usp_Acct_RecurringEntry_Execute, usp_Acct_RecurringEntry_GetDue
--    Reversion (1): usp_Acct_Entry_Reverse
--    Reportes avanzados (8): usp_Acct_Report_CashFlow,
--      usp_Acct_Report_BalanceCompMultiPeriod, usp_Acct_Report_PnLMultiPeriod,
--      usp_Acct_Report_AgingCxC, usp_Acct_Report_AgingCxP,
--      usp_Acct_Report_FinancialRatios, usp_Acct_Report_TaxSummary,
--      usp_Acct_Report_DrillDown
-- =============================================================================

-- ============================================================================
-- PART 1: TABLE DDL (idempotent)
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 1. acct.FiscalPeriod
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS acct."FiscalPeriod" (
    "FiscalPeriodId"  INTEGER       GENERATED ALWAYS AS IDENTITY NOT NULL PRIMARY KEY,
    "CompanyId"       INTEGER       NOT NULL DEFAULT 1,
    "PeriodCode"      CHAR(6)       NOT NULL,
    "PeriodName"      VARCHAR(50)   NULL,
    "YearCode"        SMALLINT      NOT NULL,
    "MonthCode"       SMALLINT      NOT NULL,
    "StartDate"       DATE          NOT NULL,
    "EndDate"         DATE          NOT NULL,
    "Status"          VARCHAR(10)   NOT NULL DEFAULT 'OPEN',
    "ClosedAt"        TIMESTAMP     NULL,
    "ClosedByUserId"  INTEGER       NULL,
    "Notes"           VARCHAR(500)  NULL,
    "CreatedAt"       TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "UpdatedAt"       TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    CONSTRAINT CK_acct_FP_Status CHECK ("Status" IN ('OPEN','CLOSED','LOCKED')),
    CONSTRAINT UQ_acct_FP UNIQUE ("CompanyId", "PeriodCode"),
    CONSTRAINT FK_acct_FP_Company FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId")
);

-- ---------------------------------------------------------------------------
-- 2. acct.CostCenter
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS acct."CostCenter" (
    "CostCenterId"        INTEGER       GENERATED ALWAYS AS IDENTITY NOT NULL PRIMARY KEY,
    "CompanyId"           INTEGER       NOT NULL DEFAULT 1,
    "CostCenterCode"      VARCHAR(20)   NOT NULL,
    "CostCenterName"      VARCHAR(200)  NOT NULL,
    "ParentCostCenterId"  INTEGER       NULL,
    "Level"               SMALLINT      NOT NULL DEFAULT 1,
    "IsActive"            BOOLEAN       NOT NULL DEFAULT TRUE,
    "IsDeleted"           BOOLEAN       NOT NULL DEFAULT FALSE,
    "CreatedAt"           TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "UpdatedAt"           TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    CONSTRAINT UQ_acct_CC UNIQUE ("CompanyId", "CostCenterCode"),
    CONSTRAINT FK_acct_CC_Company FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId"),
    CONSTRAINT FK_acct_CC_Parent FOREIGN KEY ("ParentCostCenterId") REFERENCES acct."CostCenter"("CostCenterId")
);

-- ---------------------------------------------------------------------------
-- 3. acct.Budget + acct.BudgetLine
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS acct."Budget" (
    "BudgetId"        INTEGER       GENERATED ALWAYS AS IDENTITY NOT NULL PRIMARY KEY,
    "CompanyId"       INTEGER       NOT NULL DEFAULT 1,
    "BudgetName"      VARCHAR(200)  NOT NULL,
    "FiscalYear"      SMALLINT      NOT NULL,
    "CostCenterCode"  VARCHAR(20)   NULL,
    "Status"          VARCHAR(10)   NOT NULL DEFAULT 'DRAFT',
    "Notes"           VARCHAR(500)  NULL,
    "IsDeleted"       BOOLEAN       NOT NULL DEFAULT FALSE,
    "CreatedAt"       TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "UpdatedAt"       TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    CONSTRAINT CK_acct_Bud_Status CHECK ("Status" IN ('DRAFT','APPROVED','CLOSED')),
    CONSTRAINT FK_acct_Bud_Company FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId")
);

CREATE TABLE IF NOT EXISTS acct."BudgetLine" (
    "BudgetLineId"  BIGINT          GENERATED ALWAYS AS IDENTITY NOT NULL PRIMARY KEY,
    "BudgetId"      INTEGER         NOT NULL,
    "AccountCode"   VARCHAR(20)     NOT NULL,
    "Month01"       NUMERIC(18,2)   NOT NULL DEFAULT 0,
    "Month02"       NUMERIC(18,2)   NOT NULL DEFAULT 0,
    "Month03"       NUMERIC(18,2)   NOT NULL DEFAULT 0,
    "Month04"       NUMERIC(18,2)   NOT NULL DEFAULT 0,
    "Month05"       NUMERIC(18,2)   NOT NULL DEFAULT 0,
    "Month06"       NUMERIC(18,2)   NOT NULL DEFAULT 0,
    "Month07"       NUMERIC(18,2)   NOT NULL DEFAULT 0,
    "Month08"       NUMERIC(18,2)   NOT NULL DEFAULT 0,
    "Month09"       NUMERIC(18,2)   NOT NULL DEFAULT 0,
    "Month10"       NUMERIC(18,2)   NOT NULL DEFAULT 0,
    "Month11"       NUMERIC(18,2)   NOT NULL DEFAULT 0,
    "Month12"       NUMERIC(18,2)   NOT NULL DEFAULT 0,
    -- AnnualTotal generada (PostgreSQL no soporta columnas calculadas persistidas como SQL Server,
    -- se usa una columna GENERATED ALWAYS AS para compatibilidad)
    "AnnualTotal"   NUMERIC(18,2)   GENERATED ALWAYS AS
                        ("Month01"+"Month02"+"Month03"+"Month04"+"Month05"+"Month06"
                        +"Month07"+"Month08"+"Month09"+"Month10"+"Month11"+"Month12") STORED,
    "Notes"         VARCHAR(200)    NULL,
    CONSTRAINT FK_acct_BL_Budget FOREIGN KEY ("BudgetId") REFERENCES acct."Budget"("BudgetId")
);

-- ---------------------------------------------------------------------------
-- 4. acct.RecurringEntry + acct.RecurringEntryLine
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS acct."RecurringEntry" (
    "RecurringEntryId"    INTEGER       GENERATED ALWAYS AS IDENTITY NOT NULL PRIMARY KEY,
    "CompanyId"           INTEGER       NOT NULL DEFAULT 1,
    "TemplateName"        VARCHAR(200)  NOT NULL,
    "Frequency"           VARCHAR(10)   NOT NULL DEFAULT 'MONTHLY',
    "NextExecutionDate"   DATE          NOT NULL,
    "LastExecutedDate"    DATE          NULL,
    "TimesExecuted"       INTEGER       NOT NULL DEFAULT 0,
    "MaxExecutions"       INTEGER       NULL,
    "TipoAsiento"         VARCHAR(20)   NOT NULL DEFAULT 'DIARIO',
    "Concepto"            VARCHAR(300)  NOT NULL,
    "IsActive"            BOOLEAN       NOT NULL DEFAULT TRUE,
    "IsDeleted"           BOOLEAN       NOT NULL DEFAULT FALSE,
    "CreatedAt"           TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    CONSTRAINT CK_acct_RE_Freq CHECK ("Frequency" IN ('DAILY','WEEKLY','MONTHLY','QUARTERLY','YEARLY')),
    CONSTRAINT FK_acct_RE_Company FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId")
);

CREATE TABLE IF NOT EXISTS acct."RecurringEntryLine" (
    "LineId"              INTEGER       GENERATED ALWAYS AS IDENTITY NOT NULL PRIMARY KEY,
    "RecurringEntryId"    INTEGER       NOT NULL,
    "AccountCode"         VARCHAR(20)   NOT NULL,
    "Description"         VARCHAR(200)  NULL,
    "CostCenterCode"      VARCHAR(20)   NULL,
    "Debit"               NUMERIC(18,2) NOT NULL DEFAULT 0,
    "Credit"              NUMERIC(18,2) NOT NULL DEFAULT 0,
    CONSTRAINT FK_acct_REL_RE FOREIGN KEY ("RecurringEntryId") REFERENCES acct."RecurringEntry"("RecurringEntryId")
);

-- ---------------------------------------------------------------------------
-- 5. Add CostCenterCode to acct.JournalEntryLine (if not present)
-- ---------------------------------------------------------------------------
ALTER TABLE acct."JournalEntryLine"
    ADD COLUMN IF NOT EXISTS "CostCenterCode" VARCHAR(20) NULL;

-- ============================================================================
-- PART 2: STORED PROCEDURES - CIERRE CONTABLE (6 SPs)
-- ============================================================================

-- =============================================================================
--  SP 1: usp_Acct_Period_List
-- =============================================================================
DROP FUNCTION IF EXISTS usp_Acct_Period_List(INTEGER, SMALLINT, VARCHAR(10), INTEGER, INTEGER) CASCADE;
CREATE OR REPLACE FUNCTION usp_Acct_Period_List(
    p_company_id  INTEGER,
    p_year        SMALLINT     DEFAULT NULL,
    p_status      VARCHAR(10)  DEFAULT NULL,
    p_page        INTEGER      DEFAULT 1,
    p_limit       INTEGER      DEFAULT 50
)
RETURNS TABLE(
    p_total_count    BIGINT,
    "FiscalPeriodId" INTEGER,
    "PeriodCode"     CHAR(6),
    "PeriodName"     VARCHAR(50),
    "YearCode"       SMALLINT,
    "MonthCode"      SMALLINT,
    "StartDate"      DATE,
    "EndDate"        DATE,
    "Status"         VARCHAR(10),
    "ClosedAt"       TIMESTAMP,
    "ClosedByUserId" INTEGER,
    "Notes"          VARCHAR(500)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_total_count BIGINT;
BEGIN
    IF p_page  < 1   THEN p_page  := 1;   END IF;
    IF p_limit < 1   THEN p_limit := 50;  END IF;
    IF p_limit > 500 THEN p_limit := 500; END IF;

    SELECT COUNT(*)
    INTO v_total_count
    FROM acct."FiscalPeriod" fp
    WHERE fp."CompanyId" = p_company_id
      AND (p_year   IS NULL OR fp."YearCode" = p_year)
      AND (p_status IS NULL OR fp."Status"   = p_status);

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
$$;

-- =============================================================================
--  SP 2: usp_Acct_Period_EnsureYear
-- =============================================================================
DROP FUNCTION IF EXISTS usp_Acct_Period_EnsureYear(INTEGER, SMALLINT, INTEGER, TEXT) CASCADE;
CREATE OR REPLACE FUNCTION usp_Acct_Period_EnsureYear(
    p_company_id  INTEGER,
    p_year        SMALLINT,
    OUT p_resultado INTEGER,
    OUT p_mensaje   TEXT
)
RETURNS RECORD
LANGUAGE plpgsql
AS $$
DECLARE
    v_existing INTEGER;
    m_val      INTEGER;
    v_code     CHAR(6);
    v_start    DATE;
    v_end      DATE;
    v_name     VARCHAR(50);
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    IF p_year < 2000 OR p_year > 2099 THEN
        p_mensaje := 'Anio fuera de rango valido (2000-2099).';
        RETURN;
    END IF;

    SELECT COUNT(*)
    INTO v_existing
    FROM acct."FiscalPeriod"
    WHERE "CompanyId" = p_company_id AND "YearCode" = p_year;

    IF v_existing = 12 THEN
        p_resultado := 1;
        p_mensaje   := 'Los 12 periodos del anio ' || p_year::TEXT || ' ya existen.';
        RETURN;
    END IF;

    BEGIN
        FOR m_val IN 1..12 LOOP
            v_code  := LPAD(p_year::TEXT, 4, '0') || LPAD(m_val::TEXT, 2, '0');
            v_start := MAKE_DATE(p_year::INTEGER, m_val, 1);
            v_end   := (DATE_TRUNC('month', v_start) + INTERVAL '1 month - 1 day')::DATE;
            v_name  := TO_CHAR(v_start, 'Month') || ' ' || p_year::TEXT;

            IF NOT EXISTS (
                SELECT 1 FROM acct."FiscalPeriod"
                WHERE "CompanyId" = p_company_id AND "PeriodCode" = v_code
            ) THEN
                INSERT INTO acct."FiscalPeriod"
                    ("CompanyId", "PeriodCode", "PeriodName", "YearCode", "MonthCode", "StartDate", "EndDate")
                VALUES
                    (p_company_id, v_code, v_name, p_year, m_val, v_start, v_end);
            END IF;
        END LOOP;

        p_resultado := 1;
        p_mensaje   := 'Periodos del anio ' || p_year::TEXT || ' creados exitosamente.';
    EXCEPTION WHEN OTHERS THEN
        p_resultado := 0;
        p_mensaje   := 'Error al crear periodos: ' || SQLERRM;
    END;
END;
$$;

-- =============================================================================
--  SP 3: usp_Acct_Period_Close
-- =============================================================================
DROP FUNCTION IF EXISTS usp_Acct_Period_Close(INTEGER, CHAR(6), INTEGER, INTEGER, TEXT) CASCADE;
CREATE OR REPLACE FUNCTION usp_Acct_Period_Close(
    p_company_id  INTEGER,
    p_period_code CHAR(6),
    p_user_id     INTEGER,
    OUT p_resultado INTEGER,
    OUT p_mensaje   TEXT
)
RETURNS RECORD
LANGUAGE plpgsql
AS $$
DECLARE
    v_period_fmt VARCHAR(7);
    v_draft_count INTEGER;
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

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
            "ClosedByUserId" = p_user_id,
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
$$;

-- =============================================================================
--  SP 4: usp_Acct_Period_Reopen
-- =============================================================================
DROP FUNCTION IF EXISTS usp_Acct_Period_Reopen(INTEGER, CHAR(6), INTEGER, INTEGER, TEXT) CASCADE;
CREATE OR REPLACE FUNCTION usp_Acct_Period_Reopen(
    p_company_id  INTEGER,
    p_period_code CHAR(6),
    p_user_id     INTEGER,
    OUT p_resultado INTEGER,
    OUT p_mensaje   TEXT
)
RETURNS RECORD
LANGUAGE plpgsql
AS $$
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
$$;

-- =============================================================================
--  SP 5: usp_Acct_Period_GenerateClosingEntries
-- =============================================================================
DROP FUNCTION IF EXISTS usp_Acct_Period_GenerateClosingEntries(INTEGER, CHAR(6), INTEGER, INTEGER, TEXT) CASCADE;
CREATE OR REPLACE FUNCTION usp_Acct_Period_GenerateClosingEntries(
    p_company_id  INTEGER,
    p_period_code CHAR(6),
    p_user_id     INTEGER,
    OUT p_resultado INTEGER,
    OUT p_mensaje   TEXT
)
RETURNS RECORD
LANGUAGE plpgsql
AS $$
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
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

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
            'VES', 0, 0, 'APPROVED', 'CONTABILIDAD', p_user_id
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

        -- Linea contra 3.3.01 utilidades retenidas
        SELECT "AccountId" INTO v_retained_acct
        FROM acct."Account"
        WHERE "CompanyId" = p_company_id AND "AccountCode" = '3.3.01' AND COALESCE("IsDeleted", FALSE) = FALSE
        LIMIT 1;

        IF v_retained_acct IS NULL THEN
            SELECT "AccountId" INTO v_retained_acct
            FROM acct."Account"
            WHERE "CompanyId" = p_company_id AND "AccountCode" LIKE '3.3%'
              AND "AllowsPosting" = TRUE AND COALESCE("IsDeleted", FALSE) = FALSE
            ORDER BY "AccountCode"
            LIMIT 1;
        END IF;

        IF v_retained_acct IS NOT NULL THEN
            SELECT SUM("Saldo") INTO v_net_result FROM _closing_saldos;

            INSERT INTO acct."JournalEntryLine" (
                "JournalEntryId", "LineNumber", "AccountId", "AccountCodeSnapshot",
                "Description", "DebitAmount", "CreditAmount"
            )
            VALUES (
                v_entry_id, v_line_count + 1, v_retained_acct, '3.3.01',
                'Resultado del periodo a utilidades retenidas',
                CASE WHEN v_net_result > 0 THEN v_net_result        ELSE 0 END,
                CASE WHEN v_net_result < 0 THEN ABS(v_net_result)   ELSE 0 END
            );
        END IF;

        -- Actualizar totales del asiento
        SELECT SUM("DebitAmount"), SUM("CreditAmount")
        INTO v_td, v_tc
        FROM acct."JournalEntryLine" WHERE "JournalEntryId" = v_entry_id;

        UPDATE acct."JournalEntry"
        SET "TotalDebit" = v_td, "TotalCredit" = v_tc
        WHERE "JournalEntryId" = v_entry_id;

        p_resultado := 1;
        p_mensaje   := 'Asiento de cierre ' || v_entry_number || ' generado con '
                     || (v_line_count + 1)::TEXT || ' lineas.';
    EXCEPTION WHEN OTHERS THEN
        p_resultado := 0;
        p_mensaje   := 'Error al generar cierre: ' || SQLERRM;
    END;
END;
$$;

-- =============================================================================
--  SP 6: usp_Acct_Period_Checklist
-- =============================================================================
DROP FUNCTION IF EXISTS usp_Acct_Period_Checklist(INTEGER, CHAR(6)) CASCADE;
CREATE OR REPLACE FUNCTION usp_Acct_Period_Checklist(
    p_company_id  INTEGER,
    p_period_code CHAR(6)
)
RETURNS TABLE(
    "ItemName"  VARCHAR(100),
    "ItemCount" INTEGER,
    "Status"    VARCHAR(10)
)
LANGUAGE plpgsql
AS $$
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
    FROM acct."JournalEntry"
    WHERE "CompanyId" = p_company_id AND "PeriodCode" = v_period_fmt
      AND "Status" = 'DRAFT' AND "IsDeleted" = FALSE;

    RETURN QUERY SELECT
        'Asientos en borrador'::VARCHAR(100),
        v_drafts,
        CASE WHEN v_drafts = 0 THEN 'OK'::VARCHAR(10) ELSE 'ERROR'::VARCHAR(10) END;

    -- 2. Asientos desbalanceados
    SELECT COUNT(*) INTO v_unbalanced
    FROM acct."JournalEntry"
    WHERE "CompanyId" = p_company_id AND "PeriodCode" = v_period_fmt
      AND "Status" = 'APPROVED' AND "IsDeleted" = FALSE
      AND ABS("TotalDebit" - "TotalCredit") > 0.01;

    RETURN QUERY SELECT
        'Asientos desbalanceados'::VARCHAR(100),
        v_unbalanced,
        CASE WHEN v_unbalanced = 0 THEN 'OK'::VARCHAR(10) ELSE 'ERROR'::VARCHAR(10) END;

    -- 3. Total asientos aprobados
    SELECT COUNT(*) INTO v_approved
    FROM acct."JournalEntry"
    WHERE "CompanyId" = p_company_id AND "PeriodCode" = v_period_fmt
      AND "Status" = 'APPROVED' AND "IsDeleted" = FALSE;

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
$$;

-- ============================================================================
-- PART 2B: CENTROS DE COSTO (6 SPs)
-- ============================================================================

-- =============================================================================
--  SP 7: usp_Acct_CostCenter_List
-- =============================================================================
DROP FUNCTION IF EXISTS usp_Acct_CostCenter_List(INTEGER, VARCHAR(100), INTEGER, INTEGER) CASCADE;
CREATE OR REPLACE FUNCTION usp_Acct_CostCenter_List(
    p_company_id INTEGER,
    p_search     VARCHAR(100) DEFAULT NULL,
    p_page       INTEGER      DEFAULT 1,
    p_limit      INTEGER      DEFAULT 50
)
RETURNS TABLE(
    p_total_count       BIGINT,
    "CostCenterId"      INTEGER,
    "CostCenterCode"    VARCHAR(20),
    "CostCenterName"    VARCHAR(200),
    "ParentCostCenterId" INTEGER,
    "Level"             SMALLINT,
    "IsActive"          BOOLEAN
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_total_count BIGINT;
BEGIN
    IF p_page  < 1   THEN p_page  := 1;   END IF;
    IF p_limit < 1   THEN p_limit := 50;  END IF;
    IF p_limit > 500 THEN p_limit := 500; END IF;

    SELECT COUNT(*)
    INTO v_total_count
    FROM acct."CostCenter" cc
    WHERE cc."CompanyId" = p_company_id
      AND cc."IsDeleted" = FALSE
      AND (p_search IS NULL
           OR cc."CostCenterCode" ILIKE '%' || p_search || '%'
           OR cc."CostCenterName" ILIKE '%' || p_search || '%');

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
$$;

-- =============================================================================
--  SP 8: usp_Acct_CostCenter_Get
-- =============================================================================
DROP FUNCTION IF EXISTS usp_Acct_CostCenter_Get(INTEGER, VARCHAR(20)) CASCADE;
CREATE OR REPLACE FUNCTION usp_Acct_CostCenter_Get(
    p_company_id      INTEGER,
    p_cost_center_code VARCHAR(20)
)
RETURNS TABLE(
    "CostCenterId"        INTEGER,
    "CostCenterCode"      VARCHAR(20),
    "CostCenterName"      VARCHAR(200),
    "ParentCostCenterId"  INTEGER,
    "ParentCode"          VARCHAR(20),
    "ParentName"          VARCHAR(200),
    "Level"               SMALLINT,
    "IsActive"            BOOLEAN,
    "CreatedAt"           TIMESTAMP,
    "UpdatedAt"           TIMESTAMP
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT cc."CostCenterId",
           cc."CostCenterCode",
           cc."CostCenterName",
           cc."ParentCostCenterId",
           p."CostCenterCode"  AS "ParentCode",
           p."CostCenterName"  AS "ParentName",
           cc."Level",
           cc."IsActive",
           cc."CreatedAt",
           cc."UpdatedAt"
    FROM acct."CostCenter" cc
    LEFT JOIN acct."CostCenter" p ON p."CostCenterId" = cc."ParentCostCenterId"
    WHERE cc."CompanyId"      = p_company_id
      AND cc."CostCenterCode" = p_cost_center_code
      AND cc."IsDeleted"      = FALSE;
END;
$$;

-- =============================================================================
--  SP 9: usp_Acct_CostCenter_Insert
-- =============================================================================
DROP FUNCTION IF EXISTS usp_Acct_CostCenter_Insert(INTEGER, VARCHAR(20), VARCHAR(200), VARCHAR(20)) CASCADE;
CREATE OR REPLACE FUNCTION usp_Acct_CostCenter_Insert(
    p_company_id  INTEGER,
    p_code        VARCHAR(20),
    p_name        VARCHAR(200),
    p_parent_code VARCHAR(20)  DEFAULT NULL,
    OUT p_resultado INTEGER,
    OUT p_mensaje   TEXT
)
RETURNS RECORD
LANGUAGE plpgsql
AS $$
DECLARE
    v_parent_id INTEGER;
    v_lvl       SMALLINT;
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    IF EXISTS (
        SELECT 1 FROM acct."CostCenter"
        WHERE "CompanyId" = p_company_id AND "CostCenterCode" = p_code AND "IsDeleted" = FALSE
    ) THEN
        p_mensaje := 'Ya existe un centro de costo con el codigo ' || p_code || '.';
        RETURN;
    END IF;

    v_parent_id := NULL;
    v_lvl       := 1;

    IF p_parent_code IS NOT NULL THEN
        SELECT "CostCenterId", "Level" + 1
        INTO v_parent_id, v_lvl
        FROM acct."CostCenter"
        WHERE "CompanyId" = p_company_id AND "CostCenterCode" = p_parent_code AND "IsDeleted" = FALSE;

        IF v_parent_id IS NULL THEN
            p_mensaje := 'Centro de costo padre ' || p_parent_code || ' no encontrado.';
            RETURN;
        END IF;
    END IF;

    BEGIN
        INSERT INTO acct."CostCenter" ("CompanyId", "CostCenterCode", "CostCenterName", "ParentCostCenterId", "Level")
        VALUES (p_company_id, p_code, p_name, v_parent_id, v_lvl);

        p_resultado := 1;
        p_mensaje   := 'Centro de costo ' || p_code || ' creado exitosamente.';
    EXCEPTION WHEN OTHERS THEN
        p_resultado := 0;
        p_mensaje   := 'Error al crear centro de costo: ' || SQLERRM;
    END;
END;
$$;

-- =============================================================================
--  SP 10: usp_Acct_CostCenter_Update
-- =============================================================================
DROP FUNCTION IF EXISTS usp_Acct_CostCenter_Update(INTEGER, VARCHAR(20), VARCHAR(200), VARCHAR(20)) CASCADE;
CREATE OR REPLACE FUNCTION usp_Acct_CostCenter_Update(
    p_company_id  INTEGER,
    p_code        VARCHAR(20),
    p_name        VARCHAR(200),
    p_parent_code VARCHAR(20)  DEFAULT NULL,
    OUT p_resultado INTEGER,
    OUT p_mensaje   TEXT
)
RETURNS RECORD
LANGUAGE plpgsql
AS $$
DECLARE
    v_parent_id INTEGER;
    v_lvl       SMALLINT;
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    IF NOT EXISTS (
        SELECT 1 FROM acct."CostCenter"
        WHERE "CompanyId" = p_company_id AND "CostCenterCode" = p_code AND "IsDeleted" = FALSE
    ) THEN
        p_mensaje := 'Centro de costo ' || p_code || ' no encontrado.';
        RETURN;
    END IF;

    v_parent_id := NULL;
    v_lvl       := 1;

    IF p_parent_code IS NOT NULL THEN
        SELECT "CostCenterId", "Level" + 1
        INTO v_parent_id, v_lvl
        FROM acct."CostCenter"
        WHERE "CompanyId" = p_company_id AND "CostCenterCode" = p_parent_code AND "IsDeleted" = FALSE;

        IF v_parent_id IS NULL THEN
            p_mensaje := 'Centro de costo padre ' || p_parent_code || ' no encontrado.';
            RETURN;
        END IF;
    END IF;

    BEGIN
        UPDATE acct."CostCenter"
        SET "CostCenterName"     = p_name,
            "ParentCostCenterId" = v_parent_id,
            "Level"              = v_lvl,
            "UpdatedAt"          = (NOW() AT TIME ZONE 'UTC')
        WHERE "CompanyId"      = p_company_id
          AND "CostCenterCode" = p_code
          AND "IsDeleted"      = FALSE;

        p_resultado := 1;
        p_mensaje   := 'Centro de costo ' || p_code || ' actualizado exitosamente.';
    EXCEPTION WHEN OTHERS THEN
        p_resultado := 0;
        p_mensaje   := 'Error al actualizar centro de costo: ' || SQLERRM;
    END;
END;
$$;

-- =============================================================================
--  SP 11: usp_Acct_CostCenter_Delete
-- =============================================================================
DROP FUNCTION IF EXISTS usp_Acct_CostCenter_Delete(INTEGER, VARCHAR(20)) CASCADE;
CREATE OR REPLACE FUNCTION usp_Acct_CostCenter_Delete(
    p_company_id INTEGER,
    p_code       VARCHAR(20),
    OUT p_resultado INTEGER,
    OUT p_mensaje   TEXT
)
RETURNS RECORD
LANGUAGE plpgsql
AS $$
DECLARE
    v_cc_id INTEGER;
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    SELECT "CostCenterId"
    INTO v_cc_id
    FROM acct."CostCenter"
    WHERE "CompanyId" = p_company_id AND "CostCenterCode" = p_code AND "IsDeleted" = FALSE;

    IF v_cc_id IS NULL THEN
        p_mensaje := 'Centro de costo ' || p_code || ' no encontrado.';
        RETURN;
    END IF;

    IF EXISTS (
        SELECT 1 FROM acct."CostCenter"
        WHERE "ParentCostCenterId" = v_cc_id AND "IsDeleted" = FALSE
    ) THEN
        p_mensaje := 'No se puede eliminar: el centro de costo tiene hijos activos.';
        RETURN;
    END IF;

    BEGIN
        UPDATE acct."CostCenter"
        SET "IsDeleted" = TRUE,
            "IsActive"  = FALSE,
            "UpdatedAt" = (NOW() AT TIME ZONE 'UTC')
        WHERE "CostCenterId" = v_cc_id;

        p_resultado := 1;
        p_mensaje   := 'Centro de costo ' || p_code || ' eliminado exitosamente.';
    EXCEPTION WHEN OTHERS THEN
        p_resultado := 0;
        p_mensaje   := 'Error al eliminar centro de costo: ' || SQLERRM;
    END;
END;
$$;

-- =============================================================================
--  SP 12: usp_Acct_Report_PnLByCostCenter
-- =============================================================================
DROP FUNCTION IF EXISTS usp_Acct_Report_PnLByCostCenter(INTEGER, DATE, DATE) CASCADE;
CREATE OR REPLACE FUNCTION usp_Acct_Report_PnLByCostCenter(
    p_company_id INTEGER,
    p_fecha_desde DATE,
    p_fecha_hasta DATE
)
RETURNS TABLE(
    "CostCenterCode" VARCHAR(20),
    "CostCenterName" VARCHAR(200),
    "AccountCode"    VARCHAR(40),
    "AccountName"    VARCHAR(200),
    "AccountType"    CHAR(1),
    "TotalDebit"     NUMERIC(18,2),
    "TotalCredit"    NUMERIC(18,2),
    "Saldo"          NUMERIC(18,2)
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT COALESCE(jel."CostCenterCode", 'SIN-CC')::VARCHAR(20) AS "CostCenterCode",
           COALESCE(cc."CostCenterName", 'Sin centro de costo')::VARCHAR(200) AS "CostCenterName",
           a."AccountCode",
           a."AccountName",
           a."AccountType",
           SUM(jel."DebitAmount")  AS "TotalDebit",
           SUM(jel."CreditAmount") AS "TotalCredit",
           CASE
               WHEN a."AccountType" = 'I' THEN SUM(jel."CreditAmount") - SUM(jel."DebitAmount")
               WHEN a."AccountType" = 'G' THEN SUM(jel."DebitAmount")  - SUM(jel."CreditAmount")
               ELSE SUM(jel."DebitAmount") - SUM(jel."CreditAmount")
           END AS "Saldo"
    FROM acct."JournalEntryLine" jel
    JOIN acct."JournalEntry" je ON je."JournalEntryId" = jel."JournalEntryId"
    JOIN acct."Account" a       ON a."AccountId"       = jel."AccountId"
    LEFT JOIN acct."CostCenter" cc ON cc."CostCenterCode" = jel."CostCenterCode"
                                   AND cc."CompanyId"     = p_company_id
                                   AND cc."IsDeleted"     = FALSE
    WHERE je."CompanyId"  = p_company_id
      AND je."EntryDate"  >= p_fecha_desde
      AND je."EntryDate"  <= p_fecha_hasta
      AND je."Status"     = 'APPROVED'
      AND je."IsDeleted"  = FALSE
      AND a."AccountType" IN ('I', 'G')
      AND COALESCE(a."IsDeleted", FALSE) = FALSE
    GROUP BY jel."CostCenterCode", cc."CostCenterName",
             a."AccountCode", a."AccountName", a."AccountType"
    ORDER BY jel."CostCenterCode", a."AccountCode";
END;
$$;

-- ============================================================================
-- PART 2C: PRESUPUESTOS (7 SPs)
-- ============================================================================

-- =============================================================================
--  SP 13: usp_Acct_Budget_List
-- =============================================================================
DROP FUNCTION IF EXISTS usp_Acct_Budget_List(INTEGER, SMALLINT, VARCHAR(10), INTEGER, INTEGER) CASCADE;
CREATE OR REPLACE FUNCTION usp_Acct_Budget_List(
    p_company_id INTEGER,
    p_fiscal_year SMALLINT    DEFAULT NULL,
    p_status      VARCHAR(10) DEFAULT NULL,
    p_page        INTEGER     DEFAULT 1,
    p_limit       INTEGER     DEFAULT 50
)
RETURNS TABLE(
    p_total_count    BIGINT,
    "BudgetId"       INTEGER,
    "BudgetName"     VARCHAR(200),
    "FiscalYear"     SMALLINT,
    "CostCenterCode" VARCHAR(20),
    "Status"         VARCHAR(10),
    "Notes"          VARCHAR(500),
    "CreatedAt"      TIMESTAMP,
    "UpdatedAt"      TIMESTAMP
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_total_count BIGINT;
BEGIN
    IF p_page  < 1   THEN p_page  := 1;   END IF;
    IF p_limit < 1   THEN p_limit := 50;  END IF;
    IF p_limit > 500 THEN p_limit := 500; END IF;

    SELECT COUNT(*)
    INTO v_total_count
    FROM acct."Budget" b
    WHERE b."CompanyId" = p_company_id
      AND b."IsDeleted" = FALSE
      AND (p_fiscal_year IS NULL OR b."FiscalYear" = p_fiscal_year)
      AND (p_status      IS NULL OR b."Status"     = p_status);

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
$$;

-- =============================================================================
--  SP 14: usp_Acct_Budget_Get
-- =============================================================================
DROP FUNCTION IF EXISTS usp_Acct_Budget_Get(INTEGER, INTEGER) CASCADE;
CREATE OR REPLACE FUNCTION usp_Acct_Budget_Get(
    p_company_id INTEGER,
    p_budget_id  INTEGER
)
RETURNS TABLE(
    "BudgetId"       INTEGER,
    "BudgetName"     VARCHAR(200),
    "FiscalYear"     SMALLINT,
    "CostCenterCode" VARCHAR(20),
    "Status"         VARCHAR(10),
    "Notes"          VARCHAR(500),
    "CreatedAt"      TIMESTAMP,
    "UpdatedAt"      TIMESTAMP
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT "BudgetId",
           "BudgetName",
           "FiscalYear",
           "CostCenterCode",
           "Status",
           "Notes",
           "CreatedAt",
           "UpdatedAt"
    FROM acct."Budget"
    WHERE "CompanyId" = p_company_id
      AND "BudgetId"  = p_budget_id
      AND "IsDeleted" = FALSE;
END;
$$;

-- =============================================================================
--  SP 15: usp_Acct_Budget_GetLines
-- =============================================================================
DROP FUNCTION IF EXISTS usp_Acct_Budget_GetLines(INTEGER) CASCADE;
CREATE OR REPLACE FUNCTION usp_Acct_Budget_GetLines(
    p_budget_id INTEGER
)
RETURNS TABLE(
    "BudgetLineId" BIGINT,
    "AccountCode"  VARCHAR(20),
    "AccountName"  VARCHAR(200),
    "Month01"      NUMERIC(18,2),
    "Month02"      NUMERIC(18,2),
    "Month03"      NUMERIC(18,2),
    "Month04"      NUMERIC(18,2),
    "Month05"      NUMERIC(18,2),
    "Month06"      NUMERIC(18,2),
    "Month07"      NUMERIC(18,2),
    "Month08"      NUMERIC(18,2),
    "Month09"      NUMERIC(18,2),
    "Month10"      NUMERIC(18,2),
    "Month11"      NUMERIC(18,2),
    "Month12"      NUMERIC(18,2),
    "AnnualTotal"  NUMERIC(18,2),
    "Notes"        VARCHAR(200)
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT bl."BudgetLineId",
           bl."AccountCode",
           a."AccountName",
           bl."Month01", bl."Month02", bl."Month03", bl."Month04",
           bl."Month05", bl."Month06", bl."Month07", bl."Month08",
           bl."Month09", bl."Month10", bl."Month11", bl."Month12",
           bl."AnnualTotal",
           bl."Notes"
    FROM acct."BudgetLine" bl
    LEFT JOIN acct."Account" a ON a."AccountCode" = bl."AccountCode" AND COALESCE(a."IsDeleted", FALSE) = FALSE
    WHERE bl."BudgetId" = p_budget_id
    ORDER BY bl."AccountCode";
END;
$$;

-- =============================================================================
--  SP 16: usp_Acct_Budget_Insert
--  LinesJson: [{"accountCode":"5.1.01","month01":100,...,"month12":100,"notes":""}]
-- =============================================================================
DROP FUNCTION IF EXISTS usp_Acct_Budget_Insert(INTEGER, VARCHAR(200), SMALLINT, VARCHAR(20), TEXT, INTEGER, TEXT) CASCADE;
CREATE OR REPLACE FUNCTION usp_Acct_Budget_Insert(
    p_company_id      INTEGER,
    p_name            VARCHAR(200),
    p_fiscal_year     SMALLINT,
    p_cost_center_code VARCHAR(20)  DEFAULT NULL,
    p_lines_json      TEXT         DEFAULT NULL,
    OUT p_resultado   INTEGER,
    OUT p_mensaje     TEXT
)
RETURNS RECORD
LANGUAGE plpgsql
AS $$
DECLARE
    v_budget_id INTEGER;
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    IF p_name IS NULL OR LENGTH(TRIM(p_name)) = 0 THEN
        p_mensaje := 'El nombre del presupuesto es obligatorio.';
        RETURN;
    END IF;

    BEGIN
        INSERT INTO acct."Budget" ("CompanyId", "BudgetName", "FiscalYear", "CostCenterCode")
        VALUES (p_company_id, p_name, p_fiscal_year, p_cost_center_code)
        RETURNING "BudgetId" INTO v_budget_id;

        INSERT INTO acct."BudgetLine" (
            "BudgetId", "AccountCode",
            "Month01", "Month02", "Month03", "Month04", "Month05", "Month06",
            "Month07", "Month08", "Month09", "Month10", "Month11", "Month12", "Notes"
        )
        SELECT v_budget_id,
               (r->>'accountCode')::VARCHAR(20),
               COALESCE((r->>'month01')::NUMERIC(18,2), 0),
               COALESCE((r->>'month02')::NUMERIC(18,2), 0),
               COALESCE((r->>'month03')::NUMERIC(18,2), 0),
               COALESCE((r->>'month04')::NUMERIC(18,2), 0),
               COALESCE((r->>'month05')::NUMERIC(18,2), 0),
               COALESCE((r->>'month06')::NUMERIC(18,2), 0),
               COALESCE((r->>'month07')::NUMERIC(18,2), 0),
               COALESCE((r->>'month08')::NUMERIC(18,2), 0),
               COALESCE((r->>'month09')::NUMERIC(18,2), 0),
               COALESCE((r->>'month10')::NUMERIC(18,2), 0),
               COALESCE((r->>'month11')::NUMERIC(18,2), 0),
               COALESCE((r->>'month12')::NUMERIC(18,2), 0),
               (r->>'notes')::VARCHAR(200)
        FROM json_array_elements(p_lines_json::json) AS r;

        p_resultado := 1;
        p_mensaje   := 'Presupuesto creado con ID ' || v_budget_id::TEXT || '.';
    EXCEPTION WHEN OTHERS THEN
        p_resultado := 0;
        p_mensaje   := 'Error al crear presupuesto: ' || SQLERRM;
    END;
END;
$$;

-- =============================================================================
--  SP 17: usp_Acct_Budget_Update
-- =============================================================================
DROP FUNCTION IF EXISTS usp_Acct_Budget_Update(INTEGER, INTEGER, VARCHAR(200), TEXT, INTEGER, TEXT) CASCADE;
CREATE OR REPLACE FUNCTION usp_Acct_Budget_Update(
    p_company_id INTEGER,
    p_budget_id  INTEGER,
    p_name       VARCHAR(200),
    p_lines_json TEXT,
    OUT p_resultado INTEGER,
    OUT p_mensaje   TEXT
)
RETURNS RECORD
LANGUAGE plpgsql
AS $$
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
        UPDATE acct."Budget"
        SET "BudgetName" = p_name,
            "UpdatedAt"  = (NOW() AT TIME ZONE 'UTC')
        WHERE "BudgetId" = p_budget_id;

        DELETE FROM acct."BudgetLine" WHERE "BudgetId" = p_budget_id;

        INSERT INTO acct."BudgetLine" (
            "BudgetId", "AccountCode",
            "Month01", "Month02", "Month03", "Month04", "Month05", "Month06",
            "Month07", "Month08", "Month09", "Month10", "Month11", "Month12", "Notes"
        )
        SELECT p_budget_id,
               (r->>'accountCode')::VARCHAR(20),
               COALESCE((r->>'month01')::NUMERIC(18,2), 0),
               COALESCE((r->>'month02')::NUMERIC(18,2), 0),
               COALESCE((r->>'month03')::NUMERIC(18,2), 0),
               COALESCE((r->>'month04')::NUMERIC(18,2), 0),
               COALESCE((r->>'month05')::NUMERIC(18,2), 0),
               COALESCE((r->>'month06')::NUMERIC(18,2), 0),
               COALESCE((r->>'month07')::NUMERIC(18,2), 0),
               COALESCE((r->>'month08')::NUMERIC(18,2), 0),
               COALESCE((r->>'month09')::NUMERIC(18,2), 0),
               COALESCE((r->>'month10')::NUMERIC(18,2), 0),
               COALESCE((r->>'month11')::NUMERIC(18,2), 0),
               COALESCE((r->>'month12')::NUMERIC(18,2), 0),
               (r->>'notes')::VARCHAR(200)
        FROM json_array_elements(p_lines_json::json) AS r;

        p_resultado := 1;
        p_mensaje   := 'Presupuesto actualizado exitosamente.';
    EXCEPTION WHEN OTHERS THEN
        p_resultado := 0;
        p_mensaje   := 'Error al actualizar presupuesto: ' || SQLERRM;
    END;
END;
$$;

-- =============================================================================
--  SP 18: usp_Acct_Budget_Delete
-- =============================================================================
DROP FUNCTION IF EXISTS usp_Acct_Budget_Delete(INTEGER, INTEGER, INTEGER, TEXT) CASCADE;
CREATE OR REPLACE FUNCTION usp_Acct_Budget_Delete(
    p_company_id INTEGER,
    p_budget_id  INTEGER,
    OUT p_resultado INTEGER,
    OUT p_mensaje   TEXT
)
RETURNS RECORD
LANGUAGE plpgsql
AS $$
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

    UPDATE acct."Budget"
    SET "IsDeleted" = TRUE,
        "UpdatedAt" = (NOW() AT TIME ZONE 'UTC')
    WHERE "BudgetId" = p_budget_id;

    p_resultado := 1;
    p_mensaje   := 'Presupuesto eliminado exitosamente.';
END;
$$;

-- =============================================================================
--  SP 19: usp_Acct_Budget_Variance
-- =============================================================================
DROP FUNCTION IF EXISTS usp_Acct_Budget_Variance(INTEGER, INTEGER, DATE, DATE) CASCADE;
CREATE OR REPLACE FUNCTION usp_Acct_Budget_Variance(
    p_company_id  INTEGER,
    p_budget_id   INTEGER,
    p_fecha_desde DATE,
    p_fecha_hasta DATE
)
RETURNS TABLE(
    "AccountCode"   VARCHAR(20),
    "AccountName"   VARCHAR(200),
    "BudgetAmount"  NUMERIC(18,2),
    "ActualAmount"  NUMERIC(18,2),
    "Variance"      NUMERIC(18,2),
    "VariancePct"   NUMERIC(10,2)
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT bl."AccountCode",
           a."AccountName",
           bl."AnnualTotal" AS "BudgetAmount",
           COALESCE(act."ActualAmount", 0) AS "ActualAmount",
           bl."AnnualTotal" - COALESCE(act."ActualAmount", 0) AS "Variance",
           CASE
               WHEN bl."AnnualTotal" = 0 THEN 0
               ELSE ROUND((bl."AnnualTotal" - COALESCE(act."ActualAmount", 0)) / bl."AnnualTotal" * 100, 2)
           END AS "VariancePct"
    FROM acct."BudgetLine" bl
    LEFT JOIN acct."Account" a ON a."AccountCode" = bl."AccountCode"
                               AND a."CompanyId"  = p_company_id
                               AND COALESCE(a."IsDeleted", FALSE) = FALSE
    LEFT JOIN (
        SELECT jel."AccountCodeSnapshot" AS "AccountCode",
               SUM(jel."DebitAmount" - jel."CreditAmount") AS "ActualAmount"
        FROM acct."JournalEntryLine" jel
        JOIN acct."JournalEntry" je ON je."JournalEntryId" = jel."JournalEntryId"
        WHERE je."CompanyId"  = p_company_id
          AND je."EntryDate"  >= p_fecha_desde
          AND je."EntryDate"  <= p_fecha_hasta
          AND je."Status"     = 'APPROVED'
          AND je."IsDeleted"  = FALSE
        GROUP BY jel."AccountCodeSnapshot"
    ) act ON act."AccountCode" = bl."AccountCode"
    WHERE bl."BudgetId" = p_budget_id
    ORDER BY bl."AccountCode";
END;
$$;

-- ============================================================================
-- PART 2D: ASIENTOS RECURRENTES (8 SPs)
-- ============================================================================

-- =============================================================================
--  SP 20: usp_Acct_RecurringEntry_List
-- =============================================================================
DROP FUNCTION IF EXISTS usp_Acct_RecurringEntry_List(INTEGER, BOOLEAN, INTEGER, INTEGER) CASCADE;
CREATE OR REPLACE FUNCTION usp_Acct_RecurringEntry_List(
    p_company_id INTEGER,
    p_is_active  BOOLEAN  DEFAULT NULL,
    p_page       INTEGER  DEFAULT 1,
    p_limit      INTEGER  DEFAULT 50
)
RETURNS TABLE(
    p_total_count       BIGINT,
    "RecurringEntryId"  INTEGER,
    "TemplateName"      VARCHAR(200),
    "Frequency"         VARCHAR(10),
    "NextExecutionDate" DATE,
    "LastExecutedDate"  DATE,
    "TimesExecuted"     INTEGER,
    "MaxExecutions"     INTEGER,
    "TipoAsiento"       VARCHAR(20),
    "Concepto"          VARCHAR(300),
    "IsActive"          BOOLEAN
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_total_count BIGINT;
BEGIN
    IF p_page  < 1   THEN p_page  := 1;   END IF;
    IF p_limit < 1   THEN p_limit := 50;  END IF;
    IF p_limit > 500 THEN p_limit := 500; END IF;

    SELECT COUNT(*)
    INTO v_total_count
    FROM acct."RecurringEntry" re
    WHERE re."CompanyId" = p_company_id
      AND re."IsDeleted" = FALSE
      AND (p_is_active IS NULL OR re."IsActive" = p_is_active);

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
$$;

-- =============================================================================
--  SP 21: usp_Acct_RecurringEntry_Get
-- =============================================================================
DROP FUNCTION IF EXISTS usp_Acct_RecurringEntry_Get(INTEGER, INTEGER) CASCADE;
CREATE OR REPLACE FUNCTION usp_Acct_RecurringEntry_Get(
    p_company_id        INTEGER,
    p_recurring_entry_id INTEGER
)
RETURNS TABLE(
    "RecurringEntryId"   INTEGER,
    "TemplateName"       VARCHAR(200),
    "Frequency"          VARCHAR(10),
    "NextExecutionDate"  DATE,
    "LastExecutedDate"   DATE,
    "TimesExecuted"      INTEGER,
    "MaxExecutions"      INTEGER,
    "TipoAsiento"        VARCHAR(20),
    "Concepto"           VARCHAR(300),
    "IsActive"           BOOLEAN,
    "CreatedAt"          TIMESTAMP
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT "RecurringEntryId",
           "TemplateName",
           "Frequency",
           "NextExecutionDate",
           "LastExecutedDate",
           "TimesExecuted",
           "MaxExecutions",
           "TipoAsiento",
           "Concepto",
           "IsActive",
           "CreatedAt"
    FROM acct."RecurringEntry"
    WHERE "CompanyId"        = p_company_id
      AND "RecurringEntryId" = p_recurring_entry_id
      AND "IsDeleted"        = FALSE;
END;
$$;

-- =============================================================================
--  SP 22: usp_Acct_RecurringEntry_GetLines
-- =============================================================================
DROP FUNCTION IF EXISTS usp_Acct_RecurringEntry_GetLines(INTEGER) CASCADE;
CREATE OR REPLACE FUNCTION usp_Acct_RecurringEntry_GetLines(
    p_recurring_entry_id INTEGER
)
RETURNS TABLE(
    "LineId"          INTEGER,
    "AccountCode"     VARCHAR(20),
    "AccountName"     VARCHAR(200),
    "Description"     VARCHAR(200),
    "CostCenterCode"  VARCHAR(20),
    "Debit"           NUMERIC(18,2),
    "Credit"          NUMERIC(18,2)
)
LANGUAGE plpgsql
AS $$
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
    LEFT JOIN acct."Account" a ON a."AccountCode" = rel."AccountCode" AND COALESCE(a."IsDeleted", FALSE) = FALSE
    WHERE rel."RecurringEntryId" = p_recurring_entry_id
    ORDER BY rel."LineId";
END;
$$;

-- =============================================================================
--  SP 23: usp_Acct_RecurringEntry_Insert
--  LinesJson: [{"accountCode":"5.1.01","description":"...","costCenterCode":null,"debit":100,"credit":0}]
-- =============================================================================
DROP FUNCTION IF EXISTS usp_Acct_RecurringEntry_Insert(INTEGER, VARCHAR(200), VARCHAR(10), DATE, VARCHAR(20), VARCHAR(300), INTEGER, TEXT, INTEGER, TEXT) CASCADE;
CREATE OR REPLACE FUNCTION usp_Acct_RecurringEntry_Insert(
    p_company_id          INTEGER,
    p_template_name       VARCHAR(200),
    p_frequency           VARCHAR(10),
    p_next_execution_date DATE,
    p_tipo_asiento        VARCHAR(20),
    p_concepto            VARCHAR(300),
    p_max_executions      INTEGER     DEFAULT NULL,
    p_lines_json          TEXT        DEFAULT NULL,
    OUT p_resultado       INTEGER,
    OUT p_mensaje         TEXT
)
RETURNS RECORD
LANGUAGE plpgsql
AS $$
DECLARE
    v_re_id     INTEGER;
    v_sum_debit NUMERIC(18,2);
    v_sum_credit NUMERIC(18,2);
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    IF p_template_name IS NULL OR LENGTH(TRIM(p_template_name)) = 0 THEN
        p_mensaje := 'El nombre de la plantilla es obligatorio.';
        RETURN;
    END IF;

    -- Validar que debito = credito en las lineas
    SELECT COALESCE(SUM((r->>'debit')::NUMERIC(18,2)), 0),
           COALESCE(SUM((r->>'credit')::NUMERIC(18,2)), 0)
    INTO v_sum_debit, v_sum_credit
    FROM json_array_elements(p_lines_json::json) AS r;

    IF ABS(COALESCE(v_sum_debit, 0) - COALESCE(v_sum_credit, 0)) > 0.01 THEN
        p_mensaje := 'Las lineas no estan balanceadas (Debe=' || v_sum_debit::TEXT
                   || ', Haber=' || v_sum_credit::TEXT || ').';
        RETURN;
    END IF;

    BEGIN
        INSERT INTO acct."RecurringEntry" (
            "CompanyId", "TemplateName", "Frequency", "NextExecutionDate",
            "MaxExecutions", "TipoAsiento", "Concepto"
        )
        VALUES (
            p_company_id, p_template_name, p_frequency, p_next_execution_date,
            p_max_executions, p_tipo_asiento, p_concepto
        )
        RETURNING "RecurringEntryId" INTO v_re_id;

        INSERT INTO acct."RecurringEntryLine" (
            "RecurringEntryId", "AccountCode", "Description", "CostCenterCode", "Debit", "Credit"
        )
        SELECT v_re_id,
               (r->>'accountCode')::VARCHAR(20),
               (r->>'description')::VARCHAR(200),
               (r->>'costCenterCode')::VARCHAR(20),
               COALESCE((r->>'debit')::NUMERIC(18,2), 0),
               COALESCE((r->>'credit')::NUMERIC(18,2), 0)
        FROM json_array_elements(p_lines_json::json) AS r;

        p_resultado := 1;
        p_mensaje   := 'Plantilla recurrente creada con ID ' || v_re_id::TEXT || '.';
    EXCEPTION WHEN OTHERS THEN
        p_resultado := 0;
        p_mensaje   := 'Error al crear plantilla recurrente: ' || SQLERRM;
    END;
END;
$$;

-- =============================================================================
--  SP 24: usp_Acct_RecurringEntry_Update
-- =============================================================================
DROP FUNCTION IF EXISTS usp_Acct_RecurringEntry_Update(INTEGER, INTEGER, VARCHAR(200), VARCHAR(10), DATE, VARCHAR(300), INTEGER, TEXT, INTEGER, TEXT) CASCADE;
CREATE OR REPLACE FUNCTION usp_Acct_RecurringEntry_Update(
    p_company_id          INTEGER,
    p_recurring_entry_id  INTEGER,
    p_template_name       VARCHAR(200),
    p_frequency           VARCHAR(10),
    p_next_execution_date DATE,
    p_concepto            VARCHAR(300),
    p_max_executions      INTEGER     DEFAULT NULL,
    p_lines_json          TEXT        DEFAULT NULL,
    OUT p_resultado       INTEGER,
    OUT p_mensaje         TEXT
)
RETURNS RECORD
LANGUAGE plpgsql
AS $$
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
        SET "TemplateName"      = p_template_name,
            "Frequency"         = p_frequency,
            "NextExecutionDate" = p_next_execution_date,
            "Concepto"          = p_concepto,
            "MaxExecutions"     = p_max_executions
        WHERE "RecurringEntryId" = p_recurring_entry_id;

        DELETE FROM acct."RecurringEntryLine" WHERE "RecurringEntryId" = p_recurring_entry_id;

        INSERT INTO acct."RecurringEntryLine" (
            "RecurringEntryId", "AccountCode", "Description", "CostCenterCode", "Debit", "Credit"
        )
        SELECT p_recurring_entry_id,
               (r->>'accountCode')::VARCHAR(20),
               (r->>'description')::VARCHAR(200),
               (r->>'costCenterCode')::VARCHAR(20),
               COALESCE((r->>'debit')::NUMERIC(18,2), 0),
               COALESCE((r->>'credit')::NUMERIC(18,2), 0)
        FROM json_array_elements(p_lines_json::json) AS r;

        p_resultado := 1;
        p_mensaje   := 'Plantilla recurrente actualizada exitosamente.';
    EXCEPTION WHEN OTHERS THEN
        p_resultado := 0;
        p_mensaje   := 'Error al actualizar plantilla: ' || SQLERRM;
    END;
END;
$$;

-- =============================================================================
--  SP 25: usp_Acct_RecurringEntry_Delete
-- =============================================================================
DROP FUNCTION IF EXISTS usp_Acct_RecurringEntry_Delete(INTEGER, INTEGER, INTEGER, TEXT) CASCADE;
CREATE OR REPLACE FUNCTION usp_Acct_RecurringEntry_Delete(
    p_company_id         INTEGER,
    p_recurring_entry_id INTEGER,
    OUT p_resultado      INTEGER,
    OUT p_mensaje        TEXT
)
RETURNS RECORD
LANGUAGE plpgsql
AS $$
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

    UPDATE acct."RecurringEntry"
    SET "IsDeleted" = TRUE,
        "IsActive"  = FALSE
    WHERE "RecurringEntryId" = p_recurring_entry_id;

    p_resultado := 1;
    p_mensaje   := 'Plantilla recurrente eliminada exitosamente.';
END;
$$;

-- =============================================================================
--  SP 26: usp_Acct_RecurringEntry_Execute
-- =============================================================================
DROP FUNCTION IF EXISTS usp_Acct_RecurringEntry_Execute(INTEGER, INTEGER, DATE, INTEGER, INTEGER, TEXT) CASCADE;
CREATE OR REPLACE FUNCTION usp_Acct_RecurringEntry_Execute(
    p_company_id         INTEGER,
    p_recurring_entry_id INTEGER,
    p_execution_date     DATE,
    p_user_id            INTEGER,
    OUT p_resultado      INTEGER,
    OUT p_mensaje        TEXT
)
RETURNS RECORD
LANGUAGE plpgsql
AS $$
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
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

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
            || REPLACE(v_period_fmt, '-',''::VARCHAR) || '-'
            || LPAD(v_seq_num::TEXT, 6, '0');

        INSERT INTO acct."JournalEntry" (
            "CompanyId", "BranchId", "EntryNumber", "EntryDate", "PeriodCode",
            "EntryType", "Concept", "CurrencyCode", "TotalDebit", "TotalCredit",
            "Status", "SourceModule", "CreatedByUserId"
        )
        VALUES (
            p_company_id, v_branch_id, v_entry_number, p_execution_date, v_period_fmt,
            v_tipo_asiento, v_concepto || ' [Recurrente: ' || v_template_name || ']',
            'VES', 0, 0, 'APPROVED', 'RECURRENTE', p_user_id
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

        p_resultado := 1;
        p_mensaje   := 'Asiento ' || v_entry_number || ' generado desde plantilla recurrente.';
    EXCEPTION WHEN OTHERS THEN
        p_resultado := 0;
        p_mensaje   := 'Error al ejecutar recurrente: ' || SQLERRM;
    END;
END;
$$;

-- =============================================================================
--  SP 27: usp_Acct_RecurringEntry_GetDue
-- =============================================================================
DROP FUNCTION IF EXISTS usp_Acct_RecurringEntry_GetDue(INTEGER) CASCADE;
CREATE OR REPLACE FUNCTION usp_Acct_RecurringEntry_GetDue(
    p_company_id INTEGER
)
RETURNS TABLE(
    "RecurringEntryId"   INTEGER,
    "TemplateName"       VARCHAR(200),
    "Frequency"          VARCHAR(10),
    "NextExecutionDate"  DATE,
    "LastExecutedDate"   DATE,
    "TimesExecuted"      INTEGER,
    "MaxExecutions"      INTEGER,
    "TipoAsiento"        VARCHAR(20),
    "Concepto"           VARCHAR(300)
)
LANGUAGE plpgsql
AS $$
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
$$;

-- ============================================================================
-- PART 2E: REVERSION (1 SP)
-- ============================================================================

-- =============================================================================
--  SP 28: usp_Acct_Entry_Reverse
-- =============================================================================
DROP FUNCTION IF EXISTS usp_Acct_Entry_Reverse(INTEGER, INTEGER, DATE, INTEGER, VARCHAR(300), INTEGER, TEXT) CASCADE;
CREATE OR REPLACE FUNCTION usp_Acct_Entry_Reverse(
    p_company_id INTEGER,
    p_entry_id   INTEGER,
    p_fecha      DATE,
    p_user_id    INTEGER,
    p_motivo     VARCHAR(300),
    OUT p_resultado INTEGER,
    OUT p_mensaje   TEXT
)
RETURNS RECORD
LANGUAGE plpgsql
AS $$
DECLARE
    v_orig_number   VARCHAR(40);
    v_orig_type     VARCHAR(20);
    v_orig_concept  VARCHAR(400);
    v_orig_currency CHAR(3);
    v_orig_rate     NUMERIC(18,6);
    v_branch_id     INTEGER;
    v_period_fmt    VARCHAR(7);
    v_rev_number    VARCHAR(40);
    v_new_entry_id  BIGINT;
    v_td            NUMERIC(18,2);
    v_tc            NUMERIC(18,2);
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    SELECT "EntryNumber", "EntryType", "Concept", "CurrencyCode",
           "ExchangeRate", "BranchId"
    INTO v_orig_number, v_orig_type, v_orig_concept, v_orig_currency,
         v_orig_rate, v_branch_id
    FROM acct."JournalEntry"
    WHERE "CompanyId"      = p_company_id
      AND "JournalEntryId" = p_entry_id
      AND "Status"         = 'APPROVED'
      AND "IsDeleted"      = FALSE;

    IF v_orig_number IS NULL THEN
        p_mensaje := 'Asiento original no encontrado o no esta aprobado.';
        RETURN;
    END IF;

    BEGIN
        v_period_fmt := TO_CHAR(p_fecha, 'YYYY') || '-' || TO_CHAR(p_fecha, 'MM');
        v_rev_number := 'REV-' || v_orig_number;

        INSERT INTO acct."JournalEntry" (
            "CompanyId", "BranchId", "EntryNumber", "EntryDate", "PeriodCode",
            "EntryType", "ReferenceNumber", "Concept", "CurrencyCode", "ExchangeRate",
            "TotalDebit", "TotalCredit", "Status", "SourceModule", "CreatedByUserId"
        )
        VALUES (
            p_company_id, v_branch_id, v_rev_number, p_fecha, v_period_fmt,
            'REV', v_orig_number,
            'REVERSION de ' || v_orig_number || ': ' || COALESCE(p_motivo,''::VARCHAR),
            v_orig_currency, v_orig_rate, 0, 0, 'APPROVED', 'CONTABILIDAD', p_user_id
        )
        RETURNING "JournalEntryId" INTO v_new_entry_id;

        -- Insertar lineas con Debe/Haber invertidos
        INSERT INTO acct."JournalEntryLine" (
            "JournalEntryId", "LineNumber", "AccountId", "AccountCodeSnapshot",
            "Description", "DebitAmount", "CreditAmount", "CostCenterCode"
        )
        SELECT v_new_entry_id,
               "LineNumber",
               "AccountId",
               "AccountCodeSnapshot",
               'REV: ' || COALESCE("Description",''::VARCHAR),
               "CreditAmount",   -- invertido
               "DebitAmount",    -- invertido
               "CostCenterCode"
        FROM acct."JournalEntryLine"
        WHERE "JournalEntryId" = p_entry_id;

        SELECT SUM("DebitAmount"), SUM("CreditAmount")
        INTO v_td, v_tc
        FROM acct."JournalEntryLine" WHERE "JournalEntryId" = v_new_entry_id;

        UPDATE acct."JournalEntry"
        SET "TotalDebit" = COALESCE(v_td, 0), "TotalCredit" = COALESCE(v_tc, 0)
        WHERE "JournalEntryId" = v_new_entry_id;

        p_resultado := 1;
        p_mensaje   := 'Asiento de reversion ' || v_rev_number || ' creado exitosamente.';
    EXCEPTION WHEN OTHERS THEN
        p_resultado := 0;
        p_mensaje   := 'Error al revertir asiento: ' || SQLERRM;
    END;
END;
$$;

-- ============================================================================
-- PART 2F: REPORTES AVANZADOS (8 SPs)
-- ============================================================================

-- =============================================================================
--  SP 29: usp_Acct_Report_CashFlow
-- =============================================================================
DROP FUNCTION IF EXISTS usp_Acct_Report_CashFlow(INTEGER, DATE, DATE) CASCADE;
CREATE OR REPLACE FUNCTION usp_Acct_Report_CashFlow(
    p_company_id  INTEGER,
    p_fecha_desde DATE,
    p_fecha_hasta DATE
)
RETURNS TABLE(
    "Category"    VARCHAR(20),
    "AccountCode" VARCHAR(40),
    "AccountName" VARCHAR(200),
    "Amount"      NUMERIC(18,2)
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT CASE
               WHEN a."AccountType" IN ('I', 'G') THEN 'OPERACION'
               WHEN a."AccountType" = 'A' AND a."AccountLevel" >= 3
                    AND a."AccountCode" LIKE '1.2%' THEN 'INVERSION'
               WHEN a."AccountType" = 'P' AND a."AccountCode" LIKE '2.2%' THEN 'FINANCIAMIENTO'
               WHEN a."AccountType" = 'C' THEN 'FINANCIAMIENTO'
               ELSE 'OPERACION'
           END::VARCHAR(20) AS "Category",
           a."AccountCode",
           a."AccountName",
           SUM(jel."DebitAmount" - jel."CreditAmount") AS "Amount"
    FROM acct."JournalEntryLine" jel
    JOIN acct."JournalEntry" je ON je."JournalEntryId" = jel."JournalEntryId"
    JOIN acct."Account" a       ON a."AccountId"       = jel."AccountId"
    WHERE je."CompanyId"  = p_company_id
      AND je."EntryDate"  >= p_fecha_desde
      AND je."EntryDate"  <= p_fecha_hasta
      AND je."Status"     = 'APPROVED'
      AND je."IsDeleted"  = FALSE
      AND COALESCE(a."IsDeleted", FALSE) = FALSE
    GROUP BY CASE
                 WHEN a."AccountType" IN ('I', 'G') THEN 'OPERACION'
                 WHEN a."AccountType" = 'A' AND a."AccountLevel" >= 3
                      AND a."AccountCode" LIKE '1.2%' THEN 'INVERSION'
                 WHEN a."AccountType" = 'P' AND a."AccountCode" LIKE '2.2%' THEN 'FINANCIAMIENTO'
                 WHEN a."AccountType" = 'C' THEN 'FINANCIAMIENTO'
                 ELSE 'OPERACION'
             END,
             a."AccountCode", a."AccountName"
    HAVING SUM(jel."DebitAmount" - jel."CreditAmount") <> 0
    ORDER BY 1, a."AccountCode";
END;
$$;

-- =============================================================================
--  SP 30: usp_Acct_Report_BalanceCompMultiPeriod
--  Nota PG: PIVOT dinamico no existe en PostgreSQL. Se usa SQL dinamico con
--           columnas calculadas via EXECUTE. El resultado es un JSON con los
--           periodos como claves. Para cada periodo se usa unnest/crosstab.
--  Input: p_periodos = periodos separados por coma, e.g. '202601,202602,202603'
-- =============================================================================
DROP FUNCTION IF EXISTS usp_Acct_Report_BalanceCompMultiPeriod(INTEGER, VARCHAR(200)) CASCADE;
CREATE OR REPLACE FUNCTION usp_Acct_Report_BalanceCompMultiPeriod(
    p_company_id INTEGER,
    p_periodos   VARCHAR(200)
)
RETURNS TABLE(
    "AccountCode" VARCHAR(40),
    "AccountName" VARCHAR(200),
    "AccountType" CHAR(1),
    "PeriodCode"  VARCHAR(7),
    "Saldo"       NUMERIC(18,2)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_period_list VARCHAR(7)[];
    v_period_fmt  VARCHAR(7);
    p             TEXT;
BEGIN
    -- Parsear periodos: convertir '202601' a '2026-01'
    v_period_list := ARRAY[]::VARCHAR(7)[];

    FOR p IN
        SELECT TRIM(e) FROM unnest(string_to_array(p_periodos, ',')) AS e
        WHERE LENGTH(TRIM(e)) = 6
    LOOP
        v_period_fmt := LEFT(p, 4) || '-' || RIGHT(p, 2);
        v_period_list := v_period_list || v_period_fmt::VARCHAR(7);
    END LOOP;

    IF array_length(v_period_list, 1) IS NULL THEN
        RETURN;
    END IF;

    RETURN QUERY
    SELECT a."AccountCode",
           a."AccountName",
           a."AccountType",
           je."PeriodCode",
           SUM(jel."DebitAmount" - jel."CreditAmount") AS "Saldo"
    FROM acct."JournalEntryLine" jel
    JOIN acct."JournalEntry" je ON je."JournalEntryId" = jel."JournalEntryId"
    JOIN acct."Account" a       ON a."AccountId"       = jel."AccountId"
    WHERE je."CompanyId" = p_company_id
      AND je."PeriodCode" = ANY(v_period_list)
      AND je."Status"     = 'APPROVED'
      AND je."IsDeleted"  = FALSE
      AND COALESCE(a."IsDeleted", FALSE) = FALSE
    GROUP BY a."AccountCode", a."AccountName", a."AccountType", je."PeriodCode"
    ORDER BY a."AccountCode", je."PeriodCode";
END;
$$;

-- =============================================================================
--  SP 31: usp_Acct_Report_PnLMultiPeriod
--  Nota PG: igual que BalanceCompMultiPeriod, devuelve filas planas
--           (AccountCode, AccountType, PeriodCode, Saldo). El pivot lo
--           realiza la capa de presentacion.
-- =============================================================================
DROP FUNCTION IF EXISTS usp_Acct_Report_PnLMultiPeriod(INTEGER, VARCHAR(200)) CASCADE;
CREATE OR REPLACE FUNCTION usp_Acct_Report_PnLMultiPeriod(
    p_company_id INTEGER,
    p_periodos   VARCHAR(200)
)
RETURNS TABLE(
    "AccountCode" VARCHAR(40),
    "AccountName" VARCHAR(200),
    "AccountType" CHAR(1),
    "PeriodCode"  VARCHAR(7),
    "Saldo"       NUMERIC(18,2)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_period_list VARCHAR(7)[];
    v_period_fmt  VARCHAR(7);
    p             TEXT;
BEGIN
    v_period_list := ARRAY[]::VARCHAR(7)[];

    FOR p IN
        SELECT TRIM(e) FROM unnest(string_to_array(p_periodos, ',')) AS e
        WHERE LENGTH(TRIM(e)) = 6
    LOOP
        v_period_fmt := LEFT(p, 4) || '-' || RIGHT(p, 2);
        v_period_list := v_period_list || v_period_fmt::VARCHAR(7);
    END LOOP;

    IF array_length(v_period_list, 1) IS NULL THEN
        RETURN;
    END IF;

    RETURN QUERY
    SELECT a."AccountCode",
           a."AccountName",
           a."AccountType",
           je."PeriodCode",
           CASE
               WHEN a."AccountType" = 'I' THEN SUM(jel."CreditAmount" - jel."DebitAmount")
               ELSE SUM(jel."DebitAmount" - jel."CreditAmount")
           END AS "Saldo"
    FROM acct."JournalEntryLine" jel
    JOIN acct."JournalEntry" je ON je."JournalEntryId" = jel."JournalEntryId"
    JOIN acct."Account" a       ON a."AccountId"       = jel."AccountId"
    WHERE je."CompanyId"  = p_company_id
      AND je."PeriodCode" = ANY(v_period_list)
      AND je."Status"     = 'APPROVED'
      AND je."IsDeleted"  = FALSE
      AND a."AccountType" IN ('I', 'G')
      AND COALESCE(a."IsDeleted", FALSE) = FALSE
    GROUP BY a."AccountCode", a."AccountName", a."AccountType", je."PeriodCode"
    ORDER BY a."AccountCode", je."PeriodCode";
END;
$$;

-- =============================================================================
--  SP 32: usp_Acct_Report_AgingCxC
-- =============================================================================
DROP FUNCTION IF EXISTS usp_Acct_Report_AgingCxC(INTEGER, DATE) CASCADE;
CREATE OR REPLACE FUNCTION usp_Acct_Report_AgingCxC(
    p_company_id INTEGER,
    p_fecha_corte DATE
)
RETURNS TABLE(
    "EntityCode"    VARCHAR(50),
    "EntityType"    VARCHAR(20),
    "Current_0_30"  NUMERIC(18,2),
    "Days_31_60"    NUMERIC(18,2),
    "Days_61_90"    NUMERIC(18,2),
    "Days_90_Plus"  NUMERIC(18,2),
    "Total"         NUMERIC(18,2)
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT jel."AuxiliaryCode" AS "EntityCode",
           jel."AuxiliaryType" AS "EntityType",
           SUM(CASE WHEN (p_fecha_corte - je."EntryDate") BETWEEN 0  AND 30  THEN jel."DebitAmount" - jel."CreditAmount" ELSE 0 END) AS "Current_0_30",
           SUM(CASE WHEN (p_fecha_corte - je."EntryDate") BETWEEN 31 AND 60  THEN jel."DebitAmount" - jel."CreditAmount" ELSE 0 END) AS "Days_31_60",
           SUM(CASE WHEN (p_fecha_corte - je."EntryDate") BETWEEN 61 AND 90  THEN jel."DebitAmount" - jel."CreditAmount" ELSE 0 END) AS "Days_61_90",
           SUM(CASE WHEN (p_fecha_corte - je."EntryDate") > 90               THEN jel."DebitAmount" - jel."CreditAmount" ELSE 0 END) AS "Days_90_Plus",
           SUM(jel."DebitAmount" - jel."CreditAmount") AS "Total"
    FROM acct."JournalEntryLine" jel
    JOIN acct."JournalEntry" je ON je."JournalEntryId" = jel."JournalEntryId"
    JOIN acct."Account" a       ON a."AccountId"       = jel."AccountId"
    WHERE je."CompanyId"  = p_company_id
      AND je."EntryDate"  <= p_fecha_corte
      AND je."Status"     = 'APPROVED'
      AND je."IsDeleted"  = FALSE
      AND COALESCE(a."IsDeleted", FALSE) = FALSE
      AND (a."AccountCode" LIKE '1.2%' OR (a."AccountType" = 'A' AND a."AccountCode" LIKE '1.1.2%'))
    GROUP BY jel."AuxiliaryCode", jel."AuxiliaryType"
    HAVING SUM(jel."DebitAmount" - jel."CreditAmount") <> 0
    ORDER BY SUM(jel."DebitAmount" - jel."CreditAmount") DESC;
END;
$$;

-- =============================================================================
--  SP 33: usp_Acct_Report_AgingCxP
-- =============================================================================
DROP FUNCTION IF EXISTS usp_Acct_Report_AgingCxP(INTEGER, DATE) CASCADE;
CREATE OR REPLACE FUNCTION usp_Acct_Report_AgingCxP(
    p_company_id  INTEGER,
    p_fecha_corte DATE
)
RETURNS TABLE(
    "EntityCode"    VARCHAR(50),
    "EntityType"    VARCHAR(20),
    "Current_0_30"  NUMERIC(18,2),
    "Days_31_60"    NUMERIC(18,2),
    "Days_61_90"    NUMERIC(18,2),
    "Days_90_Plus"  NUMERIC(18,2),
    "Total"         NUMERIC(18,2)
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT jel."AuxiliaryCode" AS "EntityCode",
           jel."AuxiliaryType" AS "EntityType",
           SUM(CASE WHEN (p_fecha_corte - je."EntryDate") BETWEEN 0  AND 30  THEN jel."CreditAmount" - jel."DebitAmount" ELSE 0 END) AS "Current_0_30",
           SUM(CASE WHEN (p_fecha_corte - je."EntryDate") BETWEEN 31 AND 60  THEN jel."CreditAmount" - jel."DebitAmount" ELSE 0 END) AS "Days_31_60",
           SUM(CASE WHEN (p_fecha_corte - je."EntryDate") BETWEEN 61 AND 90  THEN jel."CreditAmount" - jel."DebitAmount" ELSE 0 END) AS "Days_61_90",
           SUM(CASE WHEN (p_fecha_corte - je."EntryDate") > 90               THEN jel."CreditAmount" - jel."DebitAmount" ELSE 0 END) AS "Days_90_Plus",
           SUM(jel."CreditAmount" - jel."DebitAmount") AS "Total"
    FROM acct."JournalEntryLine" jel
    JOIN acct."JournalEntry" je ON je."JournalEntryId" = jel."JournalEntryId"
    JOIN acct."Account" a       ON a."AccountId"       = jel."AccountId"
    WHERE je."CompanyId"  = p_company_id
      AND je."EntryDate"  <= p_fecha_corte
      AND je."Status"     = 'APPROVED'
      AND je."IsDeleted"  = FALSE
      AND COALESCE(a."IsDeleted", FALSE) = FALSE
      AND a."AccountCode" LIKE '2.1%'
    GROUP BY jel."AuxiliaryCode", jel."AuxiliaryType"
    HAVING SUM(jel."CreditAmount" - jel."DebitAmount") <> 0
    ORDER BY SUM(jel."CreditAmount" - jel."DebitAmount") DESC;
END;
$$;

-- =============================================================================
--  SP 34: usp_Acct_Report_FinancialRatios
-- =============================================================================
DROP FUNCTION IF EXISTS usp_Acct_Report_FinancialRatios(INTEGER, DATE) CASCADE;
CREATE OR REPLACE FUNCTION usp_Acct_Report_FinancialRatios(
    p_company_id  INTEGER,
    p_fecha_corte DATE
)
RETURNS TABLE(
    "RatioName"  VARCHAR(50),
    "RatioValue" NUMERIC(18,4),
    "Category"   VARCHAR(20)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_activo_corriente    NUMERIC(18,2) := 0;
    v_activo_nocorriente  NUMERIC(18,2) := 0;
    v_pasivo_corriente    NUMERIC(18,2) := 0;
    v_pasivo_nocorriente  NUMERIC(18,2) := 0;
    v_patrimonio          NUMERIC(18,2) := 0;
    v_ingresos            NUMERIC(18,2) := 0;
    v_costo_ventas        NUMERIC(18,2) := 0;
    v_gastos              NUMERIC(18,2) := 0;
    v_inventario          NUMERIC(18,2) := 0;
    v_total_pasivo        NUMERIC(18,2);
    v_utilidad_bruta      NUMERIC(18,2);
    v_utilidad_neta       NUMERIC(18,2);
BEGIN
    SELECT
        COALESCE(SUM(CASE WHEN a."AccountCode" LIKE '1.1%'   THEN jel."DebitAmount" - jel."CreditAmount" ELSE 0 END), 0),
        COALESCE(SUM(CASE WHEN a."AccountCode" LIKE '1.2%'   THEN jel."DebitAmount" - jel."CreditAmount" ELSE 0 END), 0),
        COALESCE(SUM(CASE WHEN a."AccountCode" LIKE '2.1%'   THEN jel."CreditAmount" - jel."DebitAmount" ELSE 0 END), 0),
        COALESCE(SUM(CASE WHEN a."AccountCode" LIKE '2.2%'   THEN jel."CreditAmount" - jel."DebitAmount" ELSE 0 END), 0),
        COALESCE(SUM(CASE WHEN a."AccountType" = 'C'         THEN jel."CreditAmount" - jel."DebitAmount" ELSE 0 END), 0),
        COALESCE(SUM(CASE WHEN a."AccountType" = 'I'         THEN jel."CreditAmount" - jel."DebitAmount" ELSE 0 END), 0),
        COALESCE(SUM(CASE WHEN a."AccountCode" LIKE '5.1%'   THEN jel."DebitAmount" - jel."CreditAmount" ELSE 0 END), 0),
        COALESCE(SUM(CASE WHEN a."AccountType" = 'G'         THEN jel."DebitAmount" - jel."CreditAmount" ELSE 0 END), 0),
        COALESCE(SUM(CASE WHEN a."AccountCode" LIKE '1.1.3%' THEN jel."DebitAmount" - jel."CreditAmount" ELSE 0 END), 0)
    INTO v_activo_corriente, v_activo_nocorriente,
         v_pasivo_corriente, v_pasivo_nocorriente,
         v_patrimonio, v_ingresos, v_costo_ventas, v_gastos, v_inventario
    FROM acct."JournalEntryLine" jel
    JOIN acct."JournalEntry" je ON je."JournalEntryId" = jel."JournalEntryId"
    JOIN acct."Account" a       ON a."AccountId"       = jel."AccountId"
    WHERE je."CompanyId"  = p_company_id
      AND je."EntryDate"  <= p_fecha_corte
      AND je."Status"     = 'APPROVED'
      AND je."IsDeleted"  = FALSE
      AND COALESCE(a."IsDeleted", FALSE) = FALSE;

    v_total_pasivo   := COALESCE(v_pasivo_corriente, 0) + COALESCE(v_pasivo_nocorriente, 0);
    v_utilidad_bruta := COALESCE(v_ingresos, 0) - COALESCE(v_costo_ventas, 0);
    v_utilidad_neta  := COALESCE(v_ingresos, 0) - COALESCE(v_gastos, 0);

    RETURN QUERY
    SELECT 'CurrentRatio'::VARCHAR(50),
           CASE WHEN COALESCE(v_pasivo_corriente, 0) = 0 THEN 0
                ELSE ROUND(COALESCE(v_activo_corriente, 0) / v_pasivo_corriente, 4)
           END,
           'LIQUIDEZ'::VARCHAR(20)
    UNION ALL
    SELECT 'QuickRatio',
           CASE WHEN COALESCE(v_pasivo_corriente, 0) = 0 THEN 0
                ELSE ROUND((COALESCE(v_activo_corriente, 0) - COALESCE(v_inventario, 0)) / v_pasivo_corriente, 4)
           END,
           'LIQUIDEZ'
    UNION ALL
    SELECT 'DebtToEquity',
           CASE WHEN COALESCE(v_patrimonio, 0) = 0 THEN 0
                ELSE ROUND(v_total_pasivo / v_patrimonio, 4)
           END,
           'APALANCAMIENTO'
    UNION ALL
    SELECT 'GrossMargin',
           CASE WHEN COALESCE(v_ingresos, 0) = 0 THEN 0
                ELSE ROUND(v_utilidad_bruta / v_ingresos * 100, 2)
           END,
           'RENTABILIDAD'
    UNION ALL
    SELECT 'NetMargin',
           CASE WHEN COALESCE(v_ingresos, 0) = 0 THEN 0
                ELSE ROUND(v_utilidad_neta / v_ingresos * 100, 2)
           END,
           'RENTABILIDAD'
    UNION ALL
    SELECT 'WorkingCapital',
           (COALESCE(v_activo_corriente, 0) - COALESCE(v_pasivo_corriente, 0))::NUMERIC(18,4),
           'LIQUIDEZ';
END;
$$;

-- =============================================================================
--  SP 35: usp_Acct_Report_TaxSummary
-- =============================================================================
DROP FUNCTION IF EXISTS usp_Acct_Report_TaxSummary(INTEGER, DATE, DATE) CASCADE;
CREATE OR REPLACE FUNCTION usp_Acct_Report_TaxSummary(
    p_company_id  INTEGER,
    p_fecha_desde DATE,
    p_fecha_hasta DATE
)
RETURNS TABLE(
    "TaxAccountCode" VARCHAR(40),
    "TaxType"        VARCHAR(200),
    "DebitTotal"     NUMERIC(18,2),
    "CreditTotal"    NUMERIC(18,2),
    "TaxAmount"      NUMERIC(18,2),
    "BaseAmount"     NUMERIC(18,2),
    "TotalAmount"    NUMERIC(18,2)
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT a."AccountCode" AS "TaxAccountCode",
           a."AccountName" AS "TaxType",
           SUM(jel."DebitAmount")  AS "DebitTotal",
           SUM(jel."CreditAmount") AS "CreditTotal",
           SUM(jel."CreditAmount" - jel."DebitAmount") AS "TaxAmount",
           (SELECT SUM(jel2."DebitAmount" - jel2."CreditAmount")
            FROM acct."JournalEntryLine" jel2
            JOIN acct."Account" a2 ON a2."AccountId" = jel2."AccountId"
            WHERE jel2."JournalEntryId" IN (
                SELECT DISTINCT jel3."JournalEntryId"
                FROM acct."JournalEntryLine" jel3
                WHERE jel3."AccountId" = a."AccountId"
                  AND jel3."JournalEntryId" = jel."JournalEntryId"
            )
              AND a2."AccountCode" NOT LIKE '2.4%'
              AND a2."AccountType" IN ('G', 'A')
           ) AS "BaseAmount",
           SUM(jel."CreditAmount" - jel."DebitAmount")
           + COALESCE((SELECT SUM(jel2."DebitAmount" - jel2."CreditAmount")
                       FROM acct."JournalEntryLine" jel2
                       JOIN acct."Account" a2 ON a2."AccountId" = jel2."AccountId"
                       WHERE jel2."JournalEntryId" IN (
                           SELECT DISTINCT jel3."JournalEntryId"
                           FROM acct."JournalEntryLine" jel3
                           WHERE jel3."AccountId" = a."AccountId"
                       )
                         AND a2."AccountCode" NOT LIKE '2.4%'
                         AND a2."AccountType" IN ('G', 'A')
           ), 0) AS "TotalAmount"
    FROM acct."JournalEntryLine" jel
    JOIN acct."JournalEntry" je ON je."JournalEntryId" = jel."JournalEntryId"
    JOIN acct."Account" a       ON a."AccountId"       = jel."AccountId"
    WHERE je."CompanyId"  = p_company_id
      AND je."EntryDate"  >= p_fecha_desde
      AND je."EntryDate"  <= p_fecha_hasta
      AND je."Status"     = 'APPROVED'
      AND je."IsDeleted"  = FALSE
      AND COALESCE(a."IsDeleted", FALSE) = FALSE
      AND a."AccountCode" LIKE '2.4%'
    GROUP BY a."AccountId", a."AccountCode", a."AccountName", jel."JournalEntryId"
    ORDER BY a."AccountCode";
END;
$$;

-- =============================================================================
--  SP 36: usp_Acct_Report_DrillDown
-- =============================================================================
DROP FUNCTION IF EXISTS usp_Acct_Report_DrillDown(INTEGER, VARCHAR(20), DATE, DATE, INTEGER, INTEGER) CASCADE;
CREATE OR REPLACE FUNCTION usp_Acct_Report_DrillDown(
    p_company_id  INTEGER,
    p_account_code VARCHAR(20),
    p_fecha_desde  DATE,
    p_fecha_hasta  DATE,
    p_page         INTEGER DEFAULT 1,
    p_limit        INTEGER DEFAULT 50
)
RETURNS TABLE(
    p_total_count    BIGINT,
    "EntryId"        BIGINT,
    "EntryDate"      DATE,
    "EntryNumber"    VARCHAR(40),
    "EntryType"      VARCHAR(20),
    "Concept"        VARCHAR(400),
    "Status"         VARCHAR(20),
    "LineDescription" VARCHAR(400),
    "Debit"          NUMERIC(18,2),
    "Credit"         NUMERIC(18,2),
    "CostCenterCode" VARCHAR(20),
    "RunningBalance" NUMERIC(18,2)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_account_id     BIGINT;
    v_saldo_anterior NUMERIC(18,2);
    v_total_count    BIGINT;
BEGIN
    IF p_page  < 1   THEN p_page  := 1;   END IF;
    IF p_limit < 1   THEN p_limit := 50;  END IF;
    IF p_limit > 500 THEN p_limit := 500; END IF;

    SELECT "AccountId" INTO v_account_id
    FROM acct."Account"
    WHERE "CompanyId" = p_company_id AND "AccountCode" = p_account_code AND COALESCE("IsDeleted", FALSE) = FALSE
    LIMIT 1;

    IF v_account_id IS NULL THEN
        v_total_count := 0;
        RETURN;
    END IF;

    SELECT COUNT(*)
    INTO v_total_count
    FROM acct."JournalEntryLine" jel
    JOIN acct."JournalEntry" je ON je."JournalEntryId" = jel."JournalEntryId"
    WHERE jel."AccountId" = v_account_id
      AND je."CompanyId"  = p_company_id
      AND je."EntryDate"  >= p_fecha_desde
      AND je."EntryDate"  <= p_fecha_hasta
      AND je."Status"     = 'APPROVED'
      AND je."IsDeleted"  = FALSE;

    -- Saldo anterior al rango
    SELECT COALESCE(SUM(jel."DebitAmount" - jel."CreditAmount"), 0)
    INTO v_saldo_anterior
    FROM acct."JournalEntryLine" jel
    JOIN acct."JournalEntry" je ON je."JournalEntryId" = jel."JournalEntryId"
    WHERE jel."AccountId" = v_account_id
      AND je."CompanyId"  = p_company_id
      AND je."EntryDate"  < p_fecha_desde
      AND je."Status"     = 'APPROVED'
      AND je."IsDeleted"  = FALSE;

    RETURN QUERY
    SELECT v_total_count,
           je."JournalEntryId" AS "EntryId",
           je."EntryDate",
           je."EntryNumber",
           je."EntryType",
           je."Concept",
           je."Status",
           jel."Description" AS "LineDescription",
           jel."DebitAmount"  AS "Debit",
           jel."CreditAmount" AS "Credit",
           jel."CostCenterCode",
           v_saldo_anterior + SUM(jel."DebitAmount" - jel."CreditAmount")
               OVER (ORDER BY je."EntryDate", je."JournalEntryId", jel."LineNumber"
                     ROWS UNBOUNDED PRECEDING) AS "RunningBalance"
    FROM acct."JournalEntryLine" jel
    JOIN acct."JournalEntry" je ON je."JournalEntryId" = jel."JournalEntryId"
    WHERE jel."AccountId" = v_account_id
      AND je."CompanyId"  = p_company_id
      AND je."EntryDate"  >= p_fecha_desde
      AND je."EntryDate"  <= p_fecha_hasta
      AND je."Status"     = 'APPROVED'
      AND je."IsDeleted"  = FALSE
    ORDER BY je."EntryDate", je."JournalEntryId", jel."LineNumber"
    LIMIT p_limit OFFSET (p_page - 1) * p_limit;
END;
$$;
