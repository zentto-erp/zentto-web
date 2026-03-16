/*
 * ============================================================================
 *  Archivo : usp_acct_equity.sql
 *  Esquema : acct (patrimonio / superavit)
 *  Base    : DatqBoxWeb
 *  Fecha   : 2026-03-15
 *
 *  Descripcion:
 *    Stored procedures para el Estado de Cambios en el Patrimonio.
 *    VE: Superavit (BA VEN-NIF 1, parrafos 106-110)
 *    ES: ECPN (PGC 3a parte, Art. 35.1.c LSC)
 *
 *  Procedimientos (5):
 *    usp_Acct_EquityMovement_List, usp_Acct_EquityMovement_Insert,
 *    usp_Acct_EquityMovement_Update, usp_Acct_EquityMovement_Delete,
 *    usp_Acct_Report_EquityChanges
 *
 *  Patron : DROP + CREATE (SQL Server 2012 compat)
 * ============================================================================
 */

USE DatqBoxWeb;
GO

-- =============================================================================
--  SP 1: usp_Acct_EquityMovement_List
-- =============================================================================
IF OBJECT_ID('dbo.usp_Acct_EquityMovement_List', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Acct_EquityMovement_List;
GO
CREATE PROCEDURE dbo.usp_Acct_EquityMovement_List
    @CompanyId  INT,
    @BranchId   INT,
    @FiscalYear SMALLINT,
    @TotalCount INT           OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT @TotalCount = COUNT(*)
    FROM   acct.EquityMovement
    WHERE  CompanyId = @CompanyId AND BranchId = @BranchId AND FiscalYear = @FiscalYear;

    SELECT EquityMovementId,
           AccountId,
           AccountCode,
           AccountName,
           MovementType,
           MovementDate,
           Amount,
           JournalEntryId,
           Description,
           CreatedAt,
           UpdatedAt
    FROM   acct.EquityMovement
    WHERE  CompanyId = @CompanyId AND BranchId = @BranchId AND FiscalYear = @FiscalYear
    ORDER BY MovementDate, AccountCode;
END;
GO

-- =============================================================================
--  SP 2: usp_Acct_EquityMovement_Insert
-- =============================================================================
IF OBJECT_ID('dbo.usp_Acct_EquityMovement_Insert', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Acct_EquityMovement_Insert;
GO
CREATE PROCEDURE dbo.usp_Acct_EquityMovement_Insert
    @CompanyId      INT,
    @BranchId       INT,
    @FiscalYear     SMALLINT,
    @AccountCode    NVARCHAR(30),
    @MovementType   NVARCHAR(30),
    @MovementDate   DATE,
    @Amount         DECIMAL(18,2),
    @JournalEntryId BIGINT         = NULL,
    @Description    NVARCHAR(400)  = NULL,
    @Resultado      INT            OUTPUT,
    @Mensaje        NVARCHAR(500)  OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Resultado = 0;
    SET @Mensaje   = N'';

    -- Buscar la cuenta patrimonial
    DECLARE @AccountId BIGINT, @AccountName NVARCHAR(200);

    SELECT TOP 1 @AccountId = AccountId, @AccountName = AccountName
    FROM   acct.Account
    WHERE  CompanyId = @CompanyId AND AccountCode = @AccountCode AND AccountType = 'C' AND IsActive = 1;

    IF @AccountId IS NULL
    BEGIN
        SET @Mensaje = CONCAT(N'Cuenta patrimonial no encontrada: ', @AccountCode);
        RETURN;
    END;

    INSERT INTO acct.EquityMovement (
        CompanyId, BranchId, FiscalYear, AccountId, AccountCode, AccountName,
        MovementType, MovementDate, Amount, JournalEntryId, Description
    )
    VALUES (
        @CompanyId, @BranchId, @FiscalYear, @AccountId, @AccountCode, @AccountName,
        @MovementType, @MovementDate, @Amount, @JournalEntryId, @Description
    );

    SET @Resultado = 1;
    SET @Mensaje   = CONCAT(N'Movimiento patrimonial registrado. ID: ', SCOPE_IDENTITY());
END;
GO

-- =============================================================================
--  SP 3: usp_Acct_EquityMovement_Update
-- =============================================================================
IF OBJECT_ID('dbo.usp_Acct_EquityMovement_Update', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Acct_EquityMovement_Update;
GO
CREATE PROCEDURE dbo.usp_Acct_EquityMovement_Update
    @CompanyId         INT,
    @EquityMovementId  INT,
    @MovementType      NVARCHAR(30)  = NULL,
    @MovementDate      DATE          = NULL,
    @Amount            DECIMAL(18,2) = NULL,
    @Description       NVARCHAR(400) = NULL,
    @Resultado         INT           OUTPUT,
    @Mensaje           NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Resultado = 0;
    SET @Mensaje   = N'';

    IF NOT EXISTS (SELECT 1 FROM acct.EquityMovement WHERE EquityMovementId = @EquityMovementId AND CompanyId = @CompanyId)
    BEGIN
        SET @Mensaje = N'Movimiento no encontrado.';
        RETURN;
    END;

    UPDATE acct.EquityMovement
    SET    MovementType = ISNULL(@MovementType, MovementType),
           MovementDate = ISNULL(@MovementDate, MovementDate),
           Amount       = ISNULL(@Amount, Amount),
           Description  = ISNULL(@Description, Description),
           UpdatedAt    = SYSUTCDATETIME()
    WHERE  EquityMovementId = @EquityMovementId;

    SET @Resultado = 1;
    SET @Mensaje   = N'Movimiento actualizado.';
END;
GO

-- =============================================================================
--  SP 4: usp_Acct_EquityMovement_Delete
-- =============================================================================
IF OBJECT_ID('dbo.usp_Acct_EquityMovement_Delete', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Acct_EquityMovement_Delete;
GO
CREATE PROCEDURE dbo.usp_Acct_EquityMovement_Delete
    @CompanyId         INT,
    @EquityMovementId  INT,
    @Resultado         INT           OUTPUT,
    @Mensaje           NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Resultado = 0;
    SET @Mensaje   = N'';

    IF NOT EXISTS (SELECT 1 FROM acct.EquityMovement WHERE EquityMovementId = @EquityMovementId AND CompanyId = @CompanyId)
    BEGIN
        SET @Mensaje = N'Movimiento no encontrado.';
        RETURN;
    END;

    DELETE FROM acct.EquityMovement
    WHERE  EquityMovementId = @EquityMovementId;

    SET @Resultado = 1;
    SET @Mensaje   = N'Movimiento eliminado.';
END;
GO

-- =============================================================================
--  SP 5: usp_Acct_Report_EquityChanges
--  Descripcion : Genera el Estado de Cambios en el Patrimonio en formato matricial.
--    Filas: cuentas patrimoniales
--    Columnas: saldo inicial + tipos de movimiento + saldo final
--  Ref VE: BA VEN-NIF 1 parrafos 106-110
--  Ref ES: PGC 3a parte - ECPN
-- =============================================================================
IF OBJECT_ID('dbo.usp_Acct_Report_EquityChanges', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Acct_Report_EquityChanges;
GO
CREATE PROCEDURE dbo.usp_Acct_Report_EquityChanges
    @CompanyId  INT,
    @BranchId   INT,
    @FiscalYear SMALLINT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @FechaInicioAnio DATE = DATEFROMPARTS(@FiscalYear, 1, 1);
    DECLARE @FechaFinAnio    DATE = DATEFROMPARTS(@FiscalYear, 12, 31);

    -- Recordset 1: Matriz de cambios por cuenta patrimonial
    SELECT a.AccountCode,
           a.AccountName,
           -- Saldo inicial (movimientos de apertura o saldo acumulado previo)
           ISNULL((
               SELECT SUM(em.Amount)
               FROM   acct.EquityMovement em
               WHERE  em.CompanyId = @CompanyId AND em.BranchId = @BranchId
                 AND  em.AccountCode = a.AccountCode
                 AND  em.FiscalYear = @FiscalYear
                 AND  em.MovementType = 'OPENING_BALANCE'
           ), 0) AS saldoInicial,
           -- Capital
           ISNULL((
               SELECT SUM(em.Amount)
               FROM   acct.EquityMovement em
               WHERE  em.CompanyId = @CompanyId AND em.BranchId = @BranchId
                 AND  em.AccountCode = a.AccountCode
                 AND  em.FiscalYear = @FiscalYear
                 AND  em.MovementType IN ('CAPITAL_INCREASE','CAPITAL_DECREASE')
           ), 0) AS capital,
           -- Reservas
           ISNULL((
               SELECT SUM(em.Amount)
               FROM   acct.EquityMovement em
               WHERE  em.CompanyId = @CompanyId AND em.BranchId = @BranchId
                 AND  em.AccountCode = a.AccountCode
                 AND  em.FiscalYear = @FiscalYear
                 AND  em.MovementType IN ('RESERVE_LEGAL','RESERVE_STATUTORY','RESERVE_VOLUNTARY')
           ), 0) AS reservas,
           -- Resultados
           ISNULL((
               SELECT SUM(em.Amount)
               FROM   acct.EquityMovement em
               WHERE  em.CompanyId = @CompanyId AND em.BranchId = @BranchId
                 AND  em.AccountCode = a.AccountCode
                 AND  em.FiscalYear = @FiscalYear
                 AND  em.MovementType IN ('NET_INCOME','NET_LOSS','RETAINED_EARNINGS','ACCUMULATED_DEFICIT')
           ), 0) AS resultados,
           -- Dividendos
           ISNULL((
               SELECT SUM(em.Amount)
               FROM   acct.EquityMovement em
               WHERE  em.CompanyId = @CompanyId AND em.BranchId = @BranchId
                 AND  em.AccountCode = a.AccountCode
                 AND  em.FiscalYear = @FiscalYear
                 AND  em.MovementType IN ('DIVIDEND_CASH','DIVIDEND_STOCK')
           ), 0) AS dividendos,
           -- Ajuste inflacion
           ISNULL((
               SELECT SUM(em.Amount)
               FROM   acct.EquityMovement em
               WHERE  em.CompanyId = @CompanyId AND em.BranchId = @BranchId
                 AND  em.AccountCode = a.AccountCode
                 AND  em.FiscalYear = @FiscalYear
                 AND  em.MovementType IN ('INFLATION_ADJUST','REVALUATION_SURPLUS')
           ), 0) AS ajusteInflacion,
           -- Otros
           ISNULL((
               SELECT SUM(em.Amount)
               FROM   acct.EquityMovement em
               WHERE  em.CompanyId = @CompanyId AND em.BranchId = @BranchId
                 AND  em.AccountCode = a.AccountCode
                 AND  em.FiscalYear = @FiscalYear
                 AND  em.MovementType = 'OTHER_COMPREHENSIVE'
           ), 0) AS otrosIntegrales,
           -- Saldo final (suma de todos)
           ISNULL((
               SELECT SUM(em.Amount)
               FROM   acct.EquityMovement em
               WHERE  em.CompanyId = @CompanyId AND em.BranchId = @BranchId
                 AND  em.AccountCode = a.AccountCode
                 AND  em.FiscalYear = @FiscalYear
           ), 0) AS saldoFinal
    FROM   acct.Account a
    WHERE  a.CompanyId   = @CompanyId
      AND  a.AccountType = 'C'  -- Patrimonio
      AND  a.IsActive    = 1
      AND  ISNULL(a.IsDeleted, 0) = 0
      AND  EXISTS (
               SELECT 1 FROM acct.EquityMovement em
               WHERE em.CompanyId = @CompanyId AND em.AccountCode = a.AccountCode AND em.FiscalYear = @FiscalYear
           )
    ORDER BY a.AccountCode;

    -- Recordset 2: Totales
    SELECT ISNULL(SUM(CASE WHEN em.MovementType = 'OPENING_BALANCE' THEN em.Amount ELSE 0 END), 0) AS totalSaldoInicial,
           ISNULL(SUM(CASE WHEN em.MovementType IN ('CAPITAL_INCREASE','CAPITAL_DECREASE') THEN em.Amount ELSE 0 END), 0) AS totalCapital,
           ISNULL(SUM(CASE WHEN em.MovementType IN ('RESERVE_LEGAL','RESERVE_STATUTORY','RESERVE_VOLUNTARY') THEN em.Amount ELSE 0 END), 0) AS totalReservas,
           ISNULL(SUM(CASE WHEN em.MovementType IN ('NET_INCOME','NET_LOSS','RETAINED_EARNINGS','ACCUMULATED_DEFICIT') THEN em.Amount ELSE 0 END), 0) AS totalResultados,
           ISNULL(SUM(CASE WHEN em.MovementType IN ('DIVIDEND_CASH','DIVIDEND_STOCK') THEN em.Amount ELSE 0 END), 0) AS totalDividendos,
           ISNULL(SUM(CASE WHEN em.MovementType IN ('INFLATION_ADJUST','REVALUATION_SURPLUS') THEN em.Amount ELSE 0 END), 0) AS totalAjusteInflacion,
           ISNULL(SUM(CASE WHEN em.MovementType = 'OTHER_COMPREHENSIVE' THEN em.Amount ELSE 0 END), 0) AS totalOtrosIntegrales,
           ISNULL(SUM(em.Amount), 0) AS totalSaldoFinal
    FROM   acct.EquityMovement em
    WHERE  em.CompanyId = @CompanyId AND em.BranchId = @BranchId AND em.FiscalYear = @FiscalYear;
END;
GO

PRINT '=== usp_acct_equity.sql completado: 5 SPs creados ===';
GO
