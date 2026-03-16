-- =============================================================================
--  Archivo : usp_acct_equity.sql  (PostgreSQL)
--  Auto-convertido desde T-SQL (SQL Server) a PL/pgSQL
--  Fecha de conversion: 2026-03-16
--  Fuente original: web/api/sqlweb/includes/sp/usp_acct_equity.sql
--
--  Esquema : acct (patrimonio / superavit)
--  Descripcion:
--    Stored procedures para el Estado de Cambios en el Patrimonio.
--    VE: Superavit (BA VEN-NIF 1, parrafos 106-110)
--    ES: ECPN (PGC 3a parte, Art. 35.1.c LSC)
--
--  Funciones (5):
--    usp_Acct_EquityMovement_List, usp_Acct_EquityMovement_Insert,
--    usp_Acct_EquityMovement_Update, usp_Acct_EquityMovement_Delete,
--    usp_Acct_Report_EquityChanges
-- =============================================================================

-- =============================================================================
--  SP 1: usp_Acct_EquityMovement_List
-- =============================================================================
CREATE OR REPLACE FUNCTION usp_Acct_EquityMovement_List(
    p_company_id  INTEGER,
    p_branch_id   INTEGER,
    p_fiscal_year SMALLINT
)
RETURNS TABLE(
    p_total_count     BIGINT,
    "EquityMovementId" BIGINT,
    "AccountId"        BIGINT,
    "AccountCode"      VARCHAR(30),
    "AccountName"      VARCHAR(200),
    "MovementType"     VARCHAR(30),
    "MovementDate"     DATE,
    "Amount"           NUMERIC(18,2),
    "JournalEntryId"   BIGINT,
    "Description"      VARCHAR(400),
    "CreatedAt"        TIMESTAMP,
    "UpdatedAt"        TIMESTAMP
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_total_count BIGINT;
BEGIN
    SELECT COUNT(*)
    INTO v_total_count
    FROM acct."EquityMovement"
    WHERE "CompanyId" = p_company_id
      AND "BranchId"  = p_branch_id
      AND "FiscalYear" = p_fiscal_year;

    RETURN QUERY
    SELECT v_total_count,
           "EquityMovementId",
           "AccountId",
           "AccountCode",
           "AccountName",
           "MovementType",
           "MovementDate",
           "Amount",
           "JournalEntryId",
           "Description",
           "CreatedAt",
           "UpdatedAt"
    FROM acct."EquityMovement"
    WHERE "CompanyId"  = p_company_id
      AND "BranchId"   = p_branch_id
      AND "FiscalYear" = p_fiscal_year
    ORDER BY "MovementDate", "AccountCode";
END;
$$;

-- =============================================================================
--  SP 2: usp_Acct_EquityMovement_Insert
-- =============================================================================
CREATE OR REPLACE FUNCTION usp_Acct_EquityMovement_Insert(
    p_company_id        INTEGER,
    p_branch_id         INTEGER,
    p_fiscal_year       SMALLINT,
    p_account_code      VARCHAR(30),
    p_movement_type     VARCHAR(30),
    p_movement_date     DATE,
    p_amount            NUMERIC(18,2),
    p_journal_entry_id  BIGINT   DEFAULT NULL,
    p_description       VARCHAR(400) DEFAULT NULL,
    OUT p_resultado      INTEGER,
    OUT p_mensaje        TEXT
)
RETURNS RECORD
LANGUAGE plpgsql
AS $$
DECLARE
    v_account_id   BIGINT;
    v_account_name VARCHAR(200);
    v_new_id       BIGINT;
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    -- Buscar la cuenta patrimonial
    SELECT "AccountId", "AccountName"
    INTO v_account_id, v_account_name
    FROM acct."Account"
    WHERE "CompanyId"   = p_company_id
      AND "AccountCode" = p_account_code
      AND "AccountType" = 'C'
      AND "IsActive"    = TRUE
    LIMIT 1;

    IF v_account_id IS NULL THEN
        p_mensaje := 'Cuenta patrimonial no encontrada: ' || p_account_code;
        RETURN;
    END IF;

    INSERT INTO acct."EquityMovement" (
        "CompanyId", "BranchId", "FiscalYear", "AccountId", "AccountCode", "AccountName",
        "MovementType", "MovementDate", "Amount", "JournalEntryId", "Description"
    )
    VALUES (
        p_company_id, p_branch_id, p_fiscal_year, v_account_id, p_account_code, v_account_name,
        p_movement_type, p_movement_date, p_amount, p_journal_entry_id, p_description
    )
    RETURNING "EquityMovementId" INTO v_new_id;

    p_resultado := 1;
    p_mensaje   := 'Movimiento patrimonial registrado. ID: ' || v_new_id::TEXT;
END;
$$;

-- =============================================================================
--  SP 3: usp_Acct_EquityMovement_Update
-- =============================================================================
CREATE OR REPLACE FUNCTION usp_Acct_EquityMovement_Update(
    p_company_id          INTEGER,
    p_equity_movement_id  INTEGER,
    p_movement_type       VARCHAR(30)   DEFAULT NULL,
    p_movement_date       DATE          DEFAULT NULL,
    p_amount              NUMERIC(18,2) DEFAULT NULL,
    p_description         VARCHAR(400)  DEFAULT NULL,
    OUT p_resultado        INTEGER,
    OUT p_mensaje          TEXT
)
RETURNS RECORD
LANGUAGE plpgsql
AS $$
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    IF NOT EXISTS (
        SELECT 1 FROM acct."EquityMovement"
        WHERE "EquityMovementId" = p_equity_movement_id
          AND "CompanyId"        = p_company_id
    ) THEN
        p_mensaje := 'Movimiento no encontrado.';
        RETURN;
    END IF;

    UPDATE acct."EquityMovement"
    SET "MovementType" = COALESCE(p_movement_type, "MovementType"),
        "MovementDate" = COALESCE(p_movement_date, "MovementDate"),
        "Amount"       = COALESCE(p_amount, "Amount"),
        "Description"  = COALESCE(p_description, "Description"),
        "UpdatedAt"    = (NOW() AT TIME ZONE 'UTC')
    WHERE "EquityMovementId" = p_equity_movement_id;

    p_resultado := 1;
    p_mensaje   := 'Movimiento actualizado.';
END;
$$;

-- =============================================================================
--  SP 4: usp_Acct_EquityMovement_Delete
-- =============================================================================
CREATE OR REPLACE FUNCTION usp_Acct_EquityMovement_Delete(
    p_company_id          INTEGER,
    p_equity_movement_id  INTEGER,
    OUT p_resultado        INTEGER,
    OUT p_mensaje          TEXT
)
RETURNS RECORD
LANGUAGE plpgsql
AS $$
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    IF NOT EXISTS (
        SELECT 1 FROM acct."EquityMovement"
        WHERE "EquityMovementId" = p_equity_movement_id
          AND "CompanyId"        = p_company_id
    ) THEN
        p_mensaje := 'Movimiento no encontrado.';
        RETURN;
    END IF;

    DELETE FROM acct."EquityMovement"
    WHERE "EquityMovementId" = p_equity_movement_id;

    p_resultado := 1;
    p_mensaje   := 'Movimiento eliminado.';
END;
$$;

-- =============================================================================
--  SP 5: usp_Acct_Report_EquityChanges
--  Descripcion : Genera el Estado de Cambios en el Patrimonio en formato matricial.
--    Filas: cuentas patrimoniales
--    Columnas: saldo inicial + tipos de movimiento + saldo final
--  Ref VE: BA VEN-NIF 1 parrafos 106-110
--  Ref ES: PGC 3a parte - ECPN
--
--  Retorna dos conjuntos de datos via RETURNS TABLE (primer recordset = detalle).
--  Para el segundo recordset (totales) usar usp_Acct_Report_EquityChanges_Totals.
-- =============================================================================
CREATE OR REPLACE FUNCTION usp_Acct_Report_EquityChanges(
    p_company_id  INTEGER,
    p_branch_id   INTEGER,
    p_fiscal_year SMALLINT
)
RETURNS TABLE(
    "AccountCode"        VARCHAR(30),
    "AccountName"        VARCHAR(200),
    "saldoInicial"       NUMERIC(18,2),
    "capital"            NUMERIC(18,2),
    "reservas"           NUMERIC(18,2),
    "resultados"         NUMERIC(18,2),
    "dividendos"         NUMERIC(18,2),
    "ajusteInflacion"    NUMERIC(18,2),
    "otrosIntegrales"    NUMERIC(18,2),
    "saldoFinal"         NUMERIC(18,2)
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT a."AccountCode",
           a."AccountName",
           -- Saldo inicial
           COALESCE((
               SELECT SUM(em."Amount")
               FROM acct."EquityMovement" em
               WHERE em."CompanyId"    = p_company_id
                 AND em."BranchId"     = p_branch_id
                 AND em."AccountCode"  = a."AccountCode"
                 AND em."FiscalYear"   = p_fiscal_year
                 AND em."MovementType" = 'OPENING_BALANCE'
           ), 0) AS "saldoInicial",
           -- Capital
           COALESCE((
               SELECT SUM(em."Amount")
               FROM acct."EquityMovement" em
               WHERE em."CompanyId"    = p_company_id
                 AND em."BranchId"     = p_branch_id
                 AND em."AccountCode"  = a."AccountCode"
                 AND em."FiscalYear"   = p_fiscal_year
                 AND em."MovementType" IN ('CAPITAL_INCREASE','CAPITAL_DECREASE')
           ), 0) AS "capital",
           -- Reservas
           COALESCE((
               SELECT SUM(em."Amount")
               FROM acct."EquityMovement" em
               WHERE em."CompanyId"    = p_company_id
                 AND em."BranchId"     = p_branch_id
                 AND em."AccountCode"  = a."AccountCode"
                 AND em."FiscalYear"   = p_fiscal_year
                 AND em."MovementType" IN ('RESERVE_LEGAL','RESERVE_STATUTORY','RESERVE_VOLUNTARY')
           ), 0) AS "reservas",
           -- Resultados
           COALESCE((
               SELECT SUM(em."Amount")
               FROM acct."EquityMovement" em
               WHERE em."CompanyId"    = p_company_id
                 AND em."BranchId"     = p_branch_id
                 AND em."AccountCode"  = a."AccountCode"
                 AND em."FiscalYear"   = p_fiscal_year
                 AND em."MovementType" IN ('NET_INCOME','NET_LOSS','RETAINED_EARNINGS','ACCUMULATED_DEFICIT')
           ), 0) AS "resultados",
           -- Dividendos
           COALESCE((
               SELECT SUM(em."Amount")
               FROM acct."EquityMovement" em
               WHERE em."CompanyId"    = p_company_id
                 AND em."BranchId"     = p_branch_id
                 AND em."AccountCode"  = a."AccountCode"
                 AND em."FiscalYear"   = p_fiscal_year
                 AND em."MovementType" IN ('DIVIDEND_CASH','DIVIDEND_STOCK')
           ), 0) AS "dividendos",
           -- Ajuste inflacion
           COALESCE((
               SELECT SUM(em."Amount")
               FROM acct."EquityMovement" em
               WHERE em."CompanyId"    = p_company_id
                 AND em."BranchId"     = p_branch_id
                 AND em."AccountCode"  = a."AccountCode"
                 AND em."FiscalYear"   = p_fiscal_year
                 AND em."MovementType" IN ('INFLATION_ADJUST','REVALUATION_SURPLUS')
           ), 0) AS "ajusteInflacion",
           -- Otros integrales
           COALESCE((
               SELECT SUM(em."Amount")
               FROM acct."EquityMovement" em
               WHERE em."CompanyId"    = p_company_id
                 AND em."BranchId"     = p_branch_id
                 AND em."AccountCode"  = a."AccountCode"
                 AND em."FiscalYear"   = p_fiscal_year
                 AND em."MovementType" = 'OTHER_COMPREHENSIVE'
           ), 0) AS "otrosIntegrales",
           -- Saldo final
           COALESCE((
               SELECT SUM(em."Amount")
               FROM acct."EquityMovement" em
               WHERE em."CompanyId"   = p_company_id
                 AND em."BranchId"    = p_branch_id
                 AND em."AccountCode" = a."AccountCode"
                 AND em."FiscalYear"  = p_fiscal_year
           ), 0) AS "saldoFinal"
    FROM acct."Account" a
    WHERE a."CompanyId"   = p_company_id
      AND a."AccountType" = 'C'
      AND a."IsActive"    = TRUE
      AND COALESCE(a."IsDeleted", FALSE) = FALSE
      AND EXISTS (
              SELECT 1 FROM acct."EquityMovement" em
              WHERE em."CompanyId"   = p_company_id
                AND em."AccountCode" = a."AccountCode"
                AND em."FiscalYear"  = p_fiscal_year
          )
    ORDER BY a."AccountCode";
END;
$$;

-- Funcion auxiliar: totales del reporte de cambios en el patrimonio
CREATE OR REPLACE FUNCTION usp_Acct_Report_EquityChanges_Totals(
    p_company_id  INTEGER,
    p_branch_id   INTEGER,
    p_fiscal_year SMALLINT
)
RETURNS TABLE(
    "totalSaldoInicial"     NUMERIC(18,2),
    "totalCapital"          NUMERIC(18,2),
    "totalReservas"         NUMERIC(18,2),
    "totalResultados"       NUMERIC(18,2),
    "totalDividendos"       NUMERIC(18,2),
    "totalAjusteInflacion"  NUMERIC(18,2),
    "totalOtrosIntegrales"  NUMERIC(18,2),
    "totalSaldoFinal"       NUMERIC(18,2)
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        COALESCE(SUM(CASE WHEN em."MovementType" = 'OPENING_BALANCE' THEN em."Amount" ELSE 0 END), 0),
        COALESCE(SUM(CASE WHEN em."MovementType" IN ('CAPITAL_INCREASE','CAPITAL_DECREASE') THEN em."Amount" ELSE 0 END), 0),
        COALESCE(SUM(CASE WHEN em."MovementType" IN ('RESERVE_LEGAL','RESERVE_STATUTORY','RESERVE_VOLUNTARY') THEN em."Amount" ELSE 0 END), 0),
        COALESCE(SUM(CASE WHEN em."MovementType" IN ('NET_INCOME','NET_LOSS','RETAINED_EARNINGS','ACCUMULATED_DEFICIT') THEN em."Amount" ELSE 0 END), 0),
        COALESCE(SUM(CASE WHEN em."MovementType" IN ('DIVIDEND_CASH','DIVIDEND_STOCK') THEN em."Amount" ELSE 0 END), 0),
        COALESCE(SUM(CASE WHEN em."MovementType" IN ('INFLATION_ADJUST','REVALUATION_SURPLUS') THEN em."Amount" ELSE 0 END), 0),
        COALESCE(SUM(CASE WHEN em."MovementType" = 'OTHER_COMPREHENSIVE' THEN em."Amount" ELSE 0 END), 0),
        COALESCE(SUM(em."Amount"), 0)
    FROM acct."EquityMovement" em
    WHERE em."CompanyId" = p_company_id
      AND em."BranchId"  = p_branch_id
      AND em."FiscalYear" = p_fiscal_year;
END;
$$;
