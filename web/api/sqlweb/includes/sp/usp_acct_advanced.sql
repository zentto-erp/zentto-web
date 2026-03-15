/*
 * ============================================================================
 *  Archivo : usp_acct_advanced.sql
 *  Esquema : acct (contabilidad avanzada)
 *  Base    : DatqBoxWeb
 *  Fecha   : 2026-03-15
 *
 *  Descripcion:
 *    Modulo avanzado de contabilidad: periodos fiscales, centros de costo,
 *    presupuestos, asientos recurrentes, reversion y reportes avanzados.
 *
 *  Tablas:
 *    acct.FiscalPeriod, acct.CostCenter, acct.Budget, acct.BudgetLine,
 *    acct.RecurringEntry, acct.RecurringEntryLine
 *
 *  Procedimientos (36 SPs):
 *    -- Cierre contable (6)
 *    usp_Acct_Period_List, usp_Acct_Period_EnsureYear,
 *    usp_Acct_Period_Close, usp_Acct_Period_Reopen,
 *    usp_Acct_Period_GenerateClosingEntries, usp_Acct_Period_Checklist
 *    -- Centros de costo (6)
 *    usp_Acct_CostCenter_List, usp_Acct_CostCenter_Get,
 *    usp_Acct_CostCenter_Insert, usp_Acct_CostCenter_Update,
 *    usp_Acct_CostCenter_Delete, usp_Acct_Report_PnLByCostCenter
 *    -- Presupuestos (7)
 *    usp_Acct_Budget_List, usp_Acct_Budget_Get, usp_Acct_Budget_GetLines,
 *    usp_Acct_Budget_Insert, usp_Acct_Budget_Update,
 *    usp_Acct_Budget_Delete, usp_Acct_Budget_Variance
 *    -- Asientos recurrentes (8)
 *    usp_Acct_RecurringEntry_List, usp_Acct_RecurringEntry_Get,
 *    usp_Acct_RecurringEntry_GetLines, usp_Acct_RecurringEntry_Insert,
 *    usp_Acct_RecurringEntry_Update, usp_Acct_RecurringEntry_Delete,
 *    usp_Acct_RecurringEntry_Execute, usp_Acct_RecurringEntry_GetDue
 *    -- Reversion (1)
 *    usp_Acct_Entry_Reverse
 *    -- Reportes avanzados (8)
 *    usp_Acct_Report_CashFlow, usp_Acct_Report_BalanceCompMultiPeriod,
 *    usp_Acct_Report_PnLMultiPeriod, usp_Acct_Report_AgingCxC,
 *    usp_Acct_Report_AgingCxP, usp_Acct_Report_FinancialRatios,
 *    usp_Acct_Report_TaxSummary, usp_Acct_Report_DrillDown
 *
 *  Patron  : CREATE OR ALTER (idempotente)
 * ============================================================================
 */

USE DatqBoxWeb;
GO

-- ============================================================================
-- PART 1: TABLE DDL (idempotent)
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 1. acct.FiscalPeriod
-- ---------------------------------------------------------------------------
IF OBJECT_ID('acct.FiscalPeriod', 'U') IS NULL
BEGIN
    CREATE TABLE acct.FiscalPeriod (
        FiscalPeriodId    INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        CompanyId         INT NOT NULL CONSTRAINT DF_acct_FP_CompanyId DEFAULT(1),
        PeriodCode        CHAR(6) NOT NULL,
        PeriodName        NVARCHAR(50) NULL,
        YearCode          SMALLINT NOT NULL,
        MonthCode         TINYINT NOT NULL,
        StartDate         DATE NOT NULL,
        EndDate           DATE NOT NULL,
        Status            NVARCHAR(10) NOT NULL CONSTRAINT DF_acct_FP_Status DEFAULT('OPEN'),
        ClosedAt          DATETIME2(0) NULL,
        ClosedByUserId    INT NULL,
        Notes             NVARCHAR(500) NULL,
        CreatedAt         DATETIME2(0) NOT NULL CONSTRAINT DF_acct_FP_CreatedAt DEFAULT(SYSUTCDATETIME()),
        UpdatedAt         DATETIME2(0) NOT NULL CONSTRAINT DF_acct_FP_UpdatedAt DEFAULT(SYSUTCDATETIME()),
        CONSTRAINT CK_acct_FP_Status CHECK (Status IN ('OPEN','CLOSED','LOCKED')),
        CONSTRAINT UQ_acct_FP UNIQUE (CompanyId, PeriodCode),
        CONSTRAINT FK_acct_FP_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId)
    );
END;
GO

-- ---------------------------------------------------------------------------
-- 2. acct.CostCenter
-- ---------------------------------------------------------------------------
IF OBJECT_ID('acct.CostCenter', 'U') IS NULL
BEGIN
    CREATE TABLE acct.CostCenter (
        CostCenterId        INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        CompanyId           INT NOT NULL CONSTRAINT DF_acct_CC_CompanyId DEFAULT(1),
        CostCenterCode      NVARCHAR(20) NOT NULL,
        CostCenterName      NVARCHAR(200) NOT NULL,
        ParentCostCenterId  INT NULL,
        Level               TINYINT NOT NULL CONSTRAINT DF_acct_CC_Level DEFAULT(1),
        IsActive            BIT NOT NULL CONSTRAINT DF_acct_CC_IsActive DEFAULT(1),
        IsDeleted           BIT NOT NULL CONSTRAINT DF_acct_CC_IsDeleted DEFAULT(0),
        CreatedAt           DATETIME2(0) NOT NULL CONSTRAINT DF_acct_CC_CreatedAt DEFAULT(SYSUTCDATETIME()),
        UpdatedAt           DATETIME2(0) NOT NULL CONSTRAINT DF_acct_CC_UpdatedAt DEFAULT(SYSUTCDATETIME()),
        CONSTRAINT UQ_acct_CC UNIQUE (CompanyId, CostCenterCode),
        CONSTRAINT FK_acct_CC_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId),
        CONSTRAINT FK_acct_CC_Parent FOREIGN KEY (ParentCostCenterId) REFERENCES acct.CostCenter(CostCenterId)
    );
END;
GO

-- ---------------------------------------------------------------------------
-- 3. acct.Budget + acct.BudgetLine
-- ---------------------------------------------------------------------------
IF OBJECT_ID('acct.Budget', 'U') IS NULL
BEGIN
    CREATE TABLE acct.Budget (
        BudgetId          INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        CompanyId         INT NOT NULL CONSTRAINT DF_acct_Bud_CompanyId DEFAULT(1),
        BudgetName        NVARCHAR(200) NOT NULL,
        FiscalYear        SMALLINT NOT NULL,
        CostCenterCode    NVARCHAR(20) NULL,
        Status            NVARCHAR(10) NOT NULL CONSTRAINT DF_acct_Bud_Status DEFAULT('DRAFT'),
        Notes             NVARCHAR(500) NULL,
        IsDeleted         BIT NOT NULL CONSTRAINT DF_acct_Bud_IsDeleted DEFAULT(0),
        CreatedAt         DATETIME2(0) NOT NULL CONSTRAINT DF_acct_Bud_CreatedAt DEFAULT(SYSUTCDATETIME()),
        UpdatedAt         DATETIME2(0) NOT NULL CONSTRAINT DF_acct_Bud_UpdatedAt DEFAULT(SYSUTCDATETIME()),
        CONSTRAINT CK_acct_Bud_Status CHECK (Status IN ('DRAFT','APPROVED','CLOSED')),
        CONSTRAINT FK_acct_Bud_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId)
    );
END;
GO

IF OBJECT_ID('acct.BudgetLine', 'U') IS NULL
BEGIN
    CREATE TABLE acct.BudgetLine (
        BudgetLineId  BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        BudgetId      INT NOT NULL,
        AccountCode   NVARCHAR(20) NOT NULL,
        Month01       DECIMAL(18,2) NOT NULL CONSTRAINT DF_acct_BL_M01 DEFAULT(0),
        Month02       DECIMAL(18,2) NOT NULL CONSTRAINT DF_acct_BL_M02 DEFAULT(0),
        Month03       DECIMAL(18,2) NOT NULL CONSTRAINT DF_acct_BL_M03 DEFAULT(0),
        Month04       DECIMAL(18,2) NOT NULL CONSTRAINT DF_acct_BL_M04 DEFAULT(0),
        Month05       DECIMAL(18,2) NOT NULL CONSTRAINT DF_acct_BL_M05 DEFAULT(0),
        Month06       DECIMAL(18,2) NOT NULL CONSTRAINT DF_acct_BL_M06 DEFAULT(0),
        Month07       DECIMAL(18,2) NOT NULL CONSTRAINT DF_acct_BL_M07 DEFAULT(0),
        Month08       DECIMAL(18,2) NOT NULL CONSTRAINT DF_acct_BL_M08 DEFAULT(0),
        Month09       DECIMAL(18,2) NOT NULL CONSTRAINT DF_acct_BL_M09 DEFAULT(0),
        Month10       DECIMAL(18,2) NOT NULL CONSTRAINT DF_acct_BL_M10 DEFAULT(0),
        Month11       DECIMAL(18,2) NOT NULL CONSTRAINT DF_acct_BL_M11 DEFAULT(0),
        Month12       DECIMAL(18,2) NOT NULL CONSTRAINT DF_acct_BL_M12 DEFAULT(0),
        AnnualTotal   AS (Month01+Month02+Month03+Month04+Month05+Month06
                         +Month07+Month08+Month09+Month10+Month11+Month12) PERSISTED,
        Notes         NVARCHAR(200) NULL,
        CONSTRAINT FK_acct_BL_Budget FOREIGN KEY (BudgetId) REFERENCES acct.Budget(BudgetId)
    );
END;
GO

-- ---------------------------------------------------------------------------
-- 4. acct.RecurringEntry + acct.RecurringEntryLine
-- ---------------------------------------------------------------------------
IF OBJECT_ID('acct.RecurringEntry', 'U') IS NULL
BEGIN
    CREATE TABLE acct.RecurringEntry (
        RecurringEntryId    INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        CompanyId           INT NOT NULL CONSTRAINT DF_acct_RE_CompanyId DEFAULT(1),
        TemplateName        NVARCHAR(200) NOT NULL,
        Frequency           NVARCHAR(10) NOT NULL CONSTRAINT DF_acct_RE_Freq DEFAULT('MONTHLY'),
        NextExecutionDate   DATE NOT NULL,
        LastExecutedDate    DATE NULL,
        TimesExecuted       INT NOT NULL CONSTRAINT DF_acct_RE_Times DEFAULT(0),
        MaxExecutions       INT NULL,
        TipoAsiento         NVARCHAR(20) NOT NULL CONSTRAINT DF_acct_RE_Tipo DEFAULT('DIARIO'),
        Concepto            NVARCHAR(300) NOT NULL,
        IsActive            BIT NOT NULL CONSTRAINT DF_acct_RE_IsActive DEFAULT(1),
        IsDeleted           BIT NOT NULL CONSTRAINT DF_acct_RE_IsDeleted DEFAULT(0),
        CreatedAt           DATETIME2(0) NOT NULL CONSTRAINT DF_acct_RE_CreatedAt DEFAULT(SYSUTCDATETIME()),
        CONSTRAINT CK_acct_RE_Freq CHECK (Frequency IN ('DAILY','WEEKLY','MONTHLY','QUARTERLY','YEARLY')),
        CONSTRAINT FK_acct_RE_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId)
    );
END;
GO

IF OBJECT_ID('acct.RecurringEntryLine', 'U') IS NULL
BEGIN
    CREATE TABLE acct.RecurringEntryLine (
        LineId              INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        RecurringEntryId    INT NOT NULL,
        AccountCode         NVARCHAR(20) NOT NULL,
        Description         NVARCHAR(200) NULL,
        CostCenterCode      NVARCHAR(20) NULL,
        Debit               DECIMAL(18,2) NOT NULL CONSTRAINT DF_acct_REL_Debit DEFAULT(0),
        Credit              DECIMAL(18,2) NOT NULL CONSTRAINT DF_acct_REL_Credit DEFAULT(0),
        CONSTRAINT FK_acct_REL_RE FOREIGN KEY (RecurringEntryId) REFERENCES acct.RecurringEntry(RecurringEntryId)
    );
END;
GO

-- ---------------------------------------------------------------------------
-- 5. Add CostCenterCode to acct.JournalEntryLine (if not present)
--    Column already exists in 03_accounting_core.sql but this is a safety net.
-- ---------------------------------------------------------------------------
IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID('acct.JournalEntryLine')
      AND name = 'CostCenterCode'
)
BEGIN
    ALTER TABLE acct.JournalEntryLine
        ADD CostCenterCode NVARCHAR(20) NULL;
END;
GO

PRINT N'[usp_acct_advanced] Tablas creadas / verificadas correctamente.';
GO

-- ============================================================================
-- PART 2: STORED PROCEDURES - CIERRE CONTABLE (6 SPs)
-- ============================================================================

-- =============================================================================
--  SP 1: usp_Acct_Period_List
--  Descripcion : Lista paginada de periodos fiscales con filtros opcionales.
--  Parametros  :
--    @CompanyId   INT              - ID de la empresa.
--    @Year        SMALLINT         - Filtrar por anio (opcional).
--    @Status      NVARCHAR(10)     - Filtrar por estado (opcional).
--    @Page        INT              - Numero de pagina (default 1).
--    @Limit       INT              - Registros por pagina (default 50).
--    @TotalCount  INT OUTPUT       - Total de registros.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Acct_Period_List
    @CompanyId   INT,
    @Year        SMALLINT      = NULL,
    @Status      NVARCHAR(10)  = NULL,
    @Page        INT           = 1,
    @Limit       INT           = 50,
    @TotalCount  INT           OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    IF @Page  < 1   SET @Page  = 1;
    IF @Limit < 1   SET @Limit = 50;
    IF @Limit > 500 SET @Limit = 500;

    SELECT @TotalCount = COUNT(*)
    FROM   acct.FiscalPeriod
    WHERE  CompanyId = @CompanyId
      AND  (@Year   IS NULL OR YearCode = @Year)
      AND  (@Status IS NULL OR Status   = @Status);

    SELECT FiscalPeriodId,
           PeriodCode,
           PeriodName,
           YearCode,
           MonthCode,
           StartDate,
           EndDate,
           Status,
           ClosedAt,
           ClosedByUserId,
           Notes
    FROM   acct.FiscalPeriod
    WHERE  CompanyId = @CompanyId
      AND  (@Year   IS NULL OR YearCode = @Year)
      AND  (@Status IS NULL OR Status   = @Status)
    ORDER BY PeriodCode
    OFFSET (@Page - 1) * @Limit ROWS
    FETCH NEXT @Limit ROWS ONLY;
END;
GO

-- =============================================================================
--  SP 2: usp_Acct_Period_EnsureYear
--  Descripcion : Crea los 12 periodos de un anio fiscal si no existen.
--  Parametros  :
--    @CompanyId  INT              - ID de la empresa.
--    @Year       SMALLINT         - Anio fiscal.
--    @Resultado  INT OUTPUT       - 1=exito, 0=error.
--    @Mensaje    NVARCHAR(500) OUTPUT - Mensaje descriptivo.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Acct_Period_EnsureYear
    @CompanyId  INT,
    @Year       SMALLINT,
    @Resultado  INT           OUTPUT,
    @Mensaje    NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @Resultado = 0;
    SET @Mensaje   = N'';

    IF @Year < 2000 OR @Year > 2099
    BEGIN
        SET @Mensaje = N'Anio fuera de rango valido (2000-2099).';
        RETURN;
    END;

    DECLARE @Existing INT;
    SELECT @Existing = COUNT(*)
    FROM   acct.FiscalPeriod
    WHERE  CompanyId = @CompanyId AND YearCode = @Year;

    IF @Existing = 12
    BEGIN
        SET @Resultado = 1;
        SET @Mensaje   = N'Los 12 periodos del anio ' + CAST(@Year AS NVARCHAR(4)) + N' ya existen.';
        RETURN;
    END;

    BEGIN TRY
        BEGIN TRAN;

        DECLARE @m TINYINT = 1;
        WHILE @m <= 12
        BEGIN
            DECLARE @Code  CHAR(6)       = CAST(@Year AS CHAR(4))
                                          + RIGHT('0' + CAST(@m AS VARCHAR(2)), 2);
            DECLARE @Start DATE          = DATEFROMPARTS(@Year, @m, 1);
            DECLARE @End   DATE          = EOMONTH(@Start);
            DECLARE @Name  NVARCHAR(50)  = DATENAME(MONTH, @Start) + N' ' + CAST(@Year AS NVARCHAR(4));

            IF NOT EXISTS (
                SELECT 1 FROM acct.FiscalPeriod
                WHERE CompanyId = @CompanyId AND PeriodCode = @Code
            )
            BEGIN
                INSERT INTO acct.FiscalPeriod
                    (CompanyId, PeriodCode, PeriodName, YearCode, MonthCode, StartDate, EndDate)
                VALUES
                    (@CompanyId, @Code, @Name, @Year, @m, @Start, @End);
            END;

            SET @m = @m + 1;
        END;

        COMMIT TRAN;
        SET @Resultado = 1;
        SET @Mensaje   = N'Periodos del anio ' + CAST(@Year AS NVARCHAR(4)) + N' creados exitosamente.';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRAN;
        SET @Resultado = 0;
        SET @Mensaje   = N'Error al crear periodos: ' + ERROR_MESSAGE();
    END CATCH;
END;
GO

-- =============================================================================
--  SP 3: usp_Acct_Period_Close
--  Descripcion : Cierra un periodo fiscal. Valida que no haya asientos borrador.
--  Parametros  :
--    @CompanyId   INT              - ID de la empresa.
--    @PeriodCode  CHAR(6)          - Codigo del periodo (YYYYMM).
--    @UserId      INT              - ID del usuario que cierra.
--    @Resultado   INT OUTPUT       - 1=exito, 0=error.
--    @Mensaje     NVARCHAR(500) OUTPUT - Mensaje descriptivo.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Acct_Period_Close
    @CompanyId   INT,
    @PeriodCode  CHAR(6),
    @UserId      INT,
    @Resultado   INT           OUTPUT,
    @Mensaje     NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @Resultado = 0;
    SET @Mensaje   = N'';

    IF NOT EXISTS (
        SELECT 1 FROM acct.FiscalPeriod
        WHERE CompanyId = @CompanyId AND PeriodCode = @PeriodCode AND Status = 'OPEN'
    )
    BEGIN
        SET @Mensaje = N'Periodo ' + @PeriodCode + N' no encontrado o no esta abierto.';
        RETURN;
    END;

    -- Validar que no haya asientos en borrador
    DECLARE @PeriodCodeFmt NVARCHAR(7) = LEFT(@PeriodCode, 4) + '-' + RIGHT(@PeriodCode, 2);
    DECLARE @DraftCount INT;
    SELECT @DraftCount = COUNT(*)
    FROM   acct.JournalEntry
    WHERE  CompanyId  = @CompanyId
      AND  PeriodCode = @PeriodCodeFmt
      AND  Status     = 'DRAFT'
      AND  IsDeleted  = 0;

    IF @DraftCount > 0
    BEGIN
        SET @Mensaje = N'Existen ' + CAST(@DraftCount AS NVARCHAR(10))
                     + N' asientos en borrador. Apruebelos o eliminelos antes de cerrar.';
        RETURN;
    END;

    BEGIN TRY
        UPDATE acct.FiscalPeriod
        SET    Status         = 'CLOSED',
               ClosedAt       = SYSUTCDATETIME(),
               ClosedByUserId = @UserId,
               UpdatedAt      = SYSUTCDATETIME()
        WHERE  CompanyId  = @CompanyId
          AND  PeriodCode = @PeriodCode
          AND  Status     = 'OPEN';

        SET @Resultado = 1;
        SET @Mensaje   = N'Periodo ' + @PeriodCode + N' cerrado exitosamente.';
    END TRY
    BEGIN CATCH
        SET @Resultado = 0;
        SET @Mensaje   = N'Error al cerrar periodo: ' + ERROR_MESSAGE();
    END CATCH;
END;
GO

-- =============================================================================
--  SP 4: usp_Acct_Period_Reopen
--  Descripcion : Reabre un periodo fiscal cerrado.
--  Parametros  :
--    @CompanyId   INT              - ID de la empresa.
--    @PeriodCode  CHAR(6)          - Codigo del periodo (YYYYMM).
--    @UserId      INT              - ID del usuario que reabre.
--    @Resultado   INT OUTPUT       - 1=exito, 0=error.
--    @Mensaje     NVARCHAR(500) OUTPUT - Mensaje descriptivo.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Acct_Period_Reopen
    @CompanyId   INT,
    @PeriodCode  CHAR(6),
    @UserId      INT,
    @Resultado   INT           OUTPUT,
    @Mensaje     NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SET @Resultado = 0;
    SET @Mensaje   = N'';

    DECLARE @CurrentStatus NVARCHAR(10);
    SELECT @CurrentStatus = Status
    FROM   acct.FiscalPeriod
    WHERE  CompanyId = @CompanyId AND PeriodCode = @PeriodCode;

    IF @CurrentStatus IS NULL
    BEGIN
        SET @Mensaje = N'Periodo ' + @PeriodCode + N' no encontrado.';
        RETURN;
    END;

    IF @CurrentStatus = 'LOCKED'
    BEGIN
        SET @Mensaje = N'Periodo ' + @PeriodCode + N' esta bloqueado y no puede reabrirse.';
        RETURN;
    END;

    IF @CurrentStatus <> 'CLOSED'
    BEGIN
        SET @Mensaje = N'Periodo ' + @PeriodCode + N' no esta cerrado (estado actual: ' + @CurrentStatus + N').';
        RETURN;
    END;

    UPDATE acct.FiscalPeriod
    SET    Status         = 'OPEN',
           ClosedAt       = NULL,
           ClosedByUserId = NULL,
           UpdatedAt      = SYSUTCDATETIME()
    WHERE  CompanyId  = @CompanyId
      AND  PeriodCode = @PeriodCode
      AND  Status     = 'CLOSED';

    SET @Resultado = 1;
    SET @Mensaje   = N'Periodo ' + @PeriodCode + N' reabierto exitosamente.';
END;
GO

-- =============================================================================
--  SP 5: usp_Acct_Period_GenerateClosingEntries
--  Descripcion : Genera asiento de cierre para un periodo. Suma cuentas I/G
--                y crea asiento zerificando contra 3.3.01 (utilidades retenidas).
--  Parametros  :
--    @CompanyId   INT              - ID de la empresa.
--    @PeriodCode  CHAR(6)          - Codigo del periodo (YYYYMM).
--    @UserId      INT              - ID del usuario.
--    @Resultado   INT OUTPUT       - 1=exito, 0=error.
--    @Mensaje     NVARCHAR(500) OUTPUT - Mensaje descriptivo.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Acct_Period_GenerateClosingEntries
    @CompanyId   INT,
    @PeriodCode  CHAR(6),
    @UserId      INT,
    @Resultado   INT           OUTPUT,
    @Mensaje     NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @Resultado = 0;
    SET @Mensaje   = N'';

    DECLARE @StartDate DATE, @EndDate DATE;
    SELECT @StartDate = StartDate, @EndDate = EndDate
    FROM   acct.FiscalPeriod
    WHERE  CompanyId = @CompanyId AND PeriodCode = @PeriodCode;

    IF @StartDate IS NULL
    BEGIN
        SET @Mensaje = N'Periodo ' + @PeriodCode + N' no encontrado.';
        RETURN;
    END;

    DECLARE @PeriodCodeFmt NVARCHAR(7) = LEFT(@PeriodCode, 4) + '-' + RIGHT(@PeriodCode, 2);

    -- Saldos de cuentas I y G en el periodo
    CREATE TABLE #ClosingSaldos (
        AccountId   BIGINT,
        AccountCode NVARCHAR(40),
        AccountType NCHAR(1),
        Saldo       DECIMAL(18,2)
    );

    INSERT INTO #ClosingSaldos (AccountId, AccountCode, AccountType, Saldo)
    SELECT a.AccountId,
           a.AccountCode,
           a.AccountType,
           SUM(jel.DebitAmount - jel.CreditAmount)
    FROM   acct.JournalEntryLine jel
    JOIN   acct.JournalEntry je ON je.JournalEntryId = jel.JournalEntryId
    JOIN   acct.Account a       ON a.AccountId       = jel.AccountId
    WHERE  je.CompanyId  = @CompanyId
      AND  je.PeriodCode = @PeriodCodeFmt
      AND  je.Status     = 'APPROVED'
      AND  je.IsDeleted  = 0
      AND  a.AccountType IN ('I', 'G')
      AND  a.IsDeleted   = 0
    GROUP BY a.AccountId, a.AccountCode, a.AccountType
    HAVING SUM(jel.DebitAmount - jel.CreditAmount) <> 0;

    IF NOT EXISTS (SELECT 1 FROM #ClosingSaldos)
    BEGIN
        DROP TABLE #ClosingSaldos;
        SET @Resultado = 1;
        SET @Mensaje   = N'No hay saldos de I/G para cerrar en el periodo ' + @PeriodCode + N'.';
        RETURN;
    END;

    BEGIN TRY
        BEGIN TRAN;

        DECLARE @SeqNum INT;
        SELECT @SeqNum = ISNULL(MAX(
            TRY_CAST(RIGHT(EntryNumber, 4) AS INT)), 0) + 1
        FROM   acct.JournalEntry
        WHERE  CompanyId = @CompanyId AND EntryType = 'CIE' AND PeriodCode = @PeriodCodeFmt;

        DECLARE @EntryNumber NVARCHAR(40) = N'CIE-' + @PeriodCode + N'-'
            + RIGHT('0000' + CAST(@SeqNum AS NVARCHAR(4)), 4);

        DECLARE @BranchId INT;
        SELECT TOP 1 @BranchId = BranchId
        FROM   cfg.Branch
        WHERE  CompanyId = @CompanyId AND IsDeleted = 0
        ORDER BY BranchId;
        IF @BranchId IS NULL SET @BranchId = 1;

        INSERT INTO acct.JournalEntry (
            CompanyId, BranchId, EntryNumber, EntryDate, PeriodCode,
            EntryType, Concept, CurrencyCode, TotalDebit, TotalCredit,
            Status, SourceModule, CreatedByUserId
        )
        VALUES (
            @CompanyId, @BranchId, @EntryNumber, @EndDate, @PeriodCodeFmt,
            'CIE', N'Asiento de cierre - Periodo ' + @PeriodCode,
            'VES', 0, 0, 'APPROVED', 'CONTABILIDAD', @UserId
        );

        DECLARE @EntryId BIGINT = SCOPE_IDENTITY();

        -- Lineas que revierten cada cuenta I/G
        INSERT INTO acct.JournalEntryLine (
            JournalEntryId, LineNumber, AccountId, AccountCodeSnapshot,
            Description, DebitAmount, CreditAmount
        )
        SELECT @EntryId,
               ROW_NUMBER() OVER (ORDER BY AccountCode),
               AccountId,
               AccountCode,
               N'Cierre ' + AccountCode,
               CASE WHEN Saldo < 0 THEN ABS(Saldo) ELSE 0 END,
               CASE WHEN Saldo > 0 THEN Saldo      ELSE 0 END
        FROM   #ClosingSaldos;

        DECLARE @LineCount INT = (SELECT COUNT(*) FROM #ClosingSaldos);

        -- Linea contra 3.3.01 utilidades retenidas
        DECLARE @RetainedAcctId BIGINT;
        SELECT TOP 1 @RetainedAcctId = AccountId
        FROM   acct.Account
        WHERE  CompanyId = @CompanyId AND AccountCode = '3.3.01' AND IsDeleted = 0;

        IF @RetainedAcctId IS NULL
        BEGIN
            SELECT TOP 1 @RetainedAcctId = AccountId
            FROM   acct.Account
            WHERE  CompanyId = @CompanyId AND AccountCode LIKE '3.3%'
              AND  AllowsPosting = 1 AND IsDeleted = 0
            ORDER BY AccountCode;
        END;

        IF @RetainedAcctId IS NOT NULL
        BEGIN
            DECLARE @NetResult DECIMAL(18,2);
            SELECT @NetResult = SUM(Saldo) FROM #ClosingSaldos;

            INSERT INTO acct.JournalEntryLine (
                JournalEntryId, LineNumber, AccountId, AccountCodeSnapshot,
                Description, DebitAmount, CreditAmount
            )
            VALUES (
                @EntryId, @LineCount + 1, @RetainedAcctId, '3.3.01',
                N'Resultado del periodo a utilidades retenidas',
                CASE WHEN @NetResult > 0 THEN @NetResult       ELSE 0 END,
                CASE WHEN @NetResult < 0 THEN ABS(@NetResult)  ELSE 0 END
            );
        END;

        -- Actualizar totales del asiento
        DECLARE @TD DECIMAL(18,2), @TC DECIMAL(18,2);
        SELECT @TD = SUM(DebitAmount), @TC = SUM(CreditAmount)
        FROM   acct.JournalEntryLine WHERE JournalEntryId = @EntryId;

        UPDATE acct.JournalEntry
        SET    TotalDebit = @TD, TotalCredit = @TC
        WHERE  JournalEntryId = @EntryId;

        DROP TABLE #ClosingSaldos;
        COMMIT TRAN;

        SET @Resultado = 1;
        SET @Mensaje   = N'Asiento de cierre ' + @EntryNumber + N' generado con '
                       + CAST(@LineCount + 1 AS NVARCHAR(10)) + N' lineas.';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRAN;
        IF OBJECT_ID('tempdb..#ClosingSaldos') IS NOT NULL DROP TABLE #ClosingSaldos;
        SET @Resultado = 0;
        SET @Mensaje   = N'Error al generar cierre: ' + ERROR_MESSAGE();
    END CATCH;
END;
GO

-- =============================================================================
--  SP 6: usp_Acct_Period_Checklist
--  Descripcion : Devuelve checklist de validacion pre-cierre de un periodo.
--  Parametros  :
--    @CompanyId   INT              - ID de la empresa.
--    @PeriodCode  CHAR(6)          - Codigo del periodo (YYYYMM).
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Acct_Period_Checklist
    @CompanyId   INT,
    @PeriodCode  CHAR(6)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @PeriodCodeFmt NVARCHAR(7) = LEFT(@PeriodCode, 4) + '-' + RIGHT(@PeriodCode, 2);

    CREATE TABLE #Checklist (
        ItemName   NVARCHAR(100),
        ItemCount  INT,
        Status     NVARCHAR(10)
    );

    -- 1. Asientos en borrador
    DECLARE @Drafts INT;
    SELECT @Drafts = COUNT(*)
    FROM   acct.JournalEntry
    WHERE  CompanyId = @CompanyId AND PeriodCode = @PeriodCodeFmt
      AND  Status = 'DRAFT' AND IsDeleted = 0;

    INSERT INTO #Checklist VALUES (
        N'Asientos en borrador', @Drafts,
        CASE WHEN @Drafts = 0 THEN 'OK' ELSE 'ERROR' END);

    -- 2. Asientos desbalanceados
    DECLARE @Unbalanced INT;
    SELECT @Unbalanced = COUNT(*)
    FROM   acct.JournalEntry
    WHERE  CompanyId = @CompanyId AND PeriodCode = @PeriodCodeFmt
      AND  Status = 'APPROVED' AND IsDeleted = 0
      AND  ABS(TotalDebit - TotalCredit) > 0.01;

    INSERT INTO #Checklist VALUES (
        N'Asientos desbalanceados', @Unbalanced,
        CASE WHEN @Unbalanced = 0 THEN 'OK' ELSE 'ERROR' END);

    -- 3. Total asientos aprobados
    DECLARE @Approved INT;
    SELECT @Approved = COUNT(*)
    FROM   acct.JournalEntry
    WHERE  CompanyId = @CompanyId AND PeriodCode = @PeriodCodeFmt
      AND  Status = 'APPROVED' AND IsDeleted = 0;

    INSERT INTO #Checklist VALUES (
        N'Asientos aprobados en periodo', @Approved,
        CASE WHEN @Approved > 0 THEN 'OK' ELSE 'WARNING' END);

    -- 4. Balance total cuadra
    DECLARE @BalDiff DECIMAL(18,2);
    SELECT @BalDiff = ABS(ISNULL(SUM(jel.DebitAmount), 0) - ISNULL(SUM(jel.CreditAmount), 0))
    FROM   acct.JournalEntryLine jel
    JOIN   acct.JournalEntry je ON je.JournalEntryId = jel.JournalEntryId
    WHERE  je.CompanyId = @CompanyId AND je.PeriodCode = @PeriodCodeFmt
      AND  je.Status = 'APPROVED' AND je.IsDeleted = 0;

    INSERT INTO #Checklist VALUES (
        N'Diferencia total debe/haber', ISNULL(CAST(@BalDiff AS INT), 0),
        CASE WHEN ISNULL(@BalDiff, 0) < 0.01 THEN 'OK' ELSE 'ERROR' END);

    SELECT ItemName, ItemCount, Status FROM #Checklist;
    DROP TABLE #Checklist;
END;
GO

-- ============================================================================
-- PART 2B: STORED PROCEDURES - CENTROS DE COSTO (6 SPs)
-- ============================================================================

-- =============================================================================
--  SP 7: usp_Acct_CostCenter_List
--  Descripcion : Lista paginada de centros de costo.
--  Parametros  :
--    @CompanyId   INT              - ID de la empresa.
--    @Search      NVARCHAR(100)    - Texto a buscar (opcional).
--    @Page        INT              - Numero de pagina (default 1).
--    @Limit       INT              - Registros por pagina (default 50).
--    @TotalCount  INT OUTPUT       - Total de registros.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Acct_CostCenter_List
    @CompanyId   INT,
    @Search      NVARCHAR(100) = NULL,
    @Page        INT           = 1,
    @Limit       INT           = 50,
    @TotalCount  INT           OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    IF @Page  < 1   SET @Page  = 1;
    IF @Limit < 1   SET @Limit = 50;
    IF @Limit > 500 SET @Limit = 500;

    SELECT @TotalCount = COUNT(*)
    FROM   acct.CostCenter
    WHERE  CompanyId = @CompanyId
      AND  IsDeleted = 0
      AND  (@Search IS NULL
            OR CostCenterCode LIKE '%' + @Search + '%'
            OR CostCenterName LIKE '%' + @Search + '%');

    SELECT CostCenterId,
           CostCenterCode,
           CostCenterName,
           ParentCostCenterId,
           Level,
           IsActive
    FROM   acct.CostCenter
    WHERE  CompanyId = @CompanyId
      AND  IsDeleted = 0
      AND  (@Search IS NULL
            OR CostCenterCode LIKE '%' + @Search + '%'
            OR CostCenterName LIKE '%' + @Search + '%')
    ORDER BY CostCenterCode
    OFFSET (@Page - 1) * @Limit ROWS
    FETCH NEXT @Limit ROWS ONLY;
END;
GO

-- =============================================================================
--  SP 8: usp_Acct_CostCenter_Get
--  Descripcion : Obtiene un centro de costo por su codigo.
--  Parametros  :
--    @CompanyId       INT              - ID de la empresa.
--    @CostCenterCode  NVARCHAR(20)     - Codigo del centro de costo.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Acct_CostCenter_Get
    @CompanyId       INT,
    @CostCenterCode  NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT cc.CostCenterId,
           cc.CostCenterCode,
           cc.CostCenterName,
           cc.ParentCostCenterId,
           p.CostCenterCode  AS ParentCode,
           p.CostCenterName  AS ParentName,
           cc.Level,
           cc.IsActive,
           cc.CreatedAt,
           cc.UpdatedAt
    FROM   acct.CostCenter cc
    LEFT JOIN acct.CostCenter p ON p.CostCenterId = cc.ParentCostCenterId
    WHERE  cc.CompanyId       = @CompanyId
      AND  cc.CostCenterCode  = @CostCenterCode
      AND  cc.IsDeleted       = 0;
END;
GO

-- =============================================================================
--  SP 9: usp_Acct_CostCenter_Insert
--  Descripcion : Inserta un nuevo centro de costo.
--  Parametros  :
--    @CompanyId       INT              - ID de la empresa.
--    @Code            NVARCHAR(20)     - Codigo.
--    @Name            NVARCHAR(200)    - Nombre.
--    @ParentCode      NVARCHAR(20)     - Codigo del padre (opcional).
--    @Resultado       INT OUTPUT       - 1=exito, 0=error.
--    @Mensaje         NVARCHAR(500) OUTPUT - Mensaje descriptivo.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Acct_CostCenter_Insert
    @CompanyId   INT,
    @Code        NVARCHAR(20),
    @Name        NVARCHAR(200),
    @ParentCode  NVARCHAR(20)  = NULL,
    @Resultado   INT           OUTPUT,
    @Mensaje     NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SET @Resultado = 0;
    SET @Mensaje   = N'';

    IF EXISTS (
        SELECT 1 FROM acct.CostCenter
        WHERE CompanyId = @CompanyId AND CostCenterCode = @Code AND IsDeleted = 0
    )
    BEGIN
        SET @Mensaje = N'Ya existe un centro de costo con el codigo ' + @Code + N'.';
        RETURN;
    END;

    DECLARE @ParentId INT = NULL;
    DECLARE @Lvl TINYINT = 1;

    IF @ParentCode IS NOT NULL
    BEGIN
        SELECT @ParentId = CostCenterId, @Lvl = Level + 1
        FROM   acct.CostCenter
        WHERE  CompanyId = @CompanyId AND CostCenterCode = @ParentCode AND IsDeleted = 0;

        IF @ParentId IS NULL
        BEGIN
            SET @Mensaje = N'Centro de costo padre ' + @ParentCode + N' no encontrado.';
            RETURN;
        END;
    END;

    BEGIN TRY
        INSERT INTO acct.CostCenter (CompanyId, CostCenterCode, CostCenterName, ParentCostCenterId, Level)
        VALUES (@CompanyId, @Code, @Name, @ParentId, @Lvl);

        SET @Resultado = 1;
        SET @Mensaje   = N'Centro de costo ' + @Code + N' creado exitosamente.';
    END TRY
    BEGIN CATCH
        SET @Resultado = 0;
        SET @Mensaje   = N'Error al crear centro de costo: ' + ERROR_MESSAGE();
    END CATCH;
END;
GO

-- =============================================================================
--  SP 10: usp_Acct_CostCenter_Update
--  Descripcion : Actualiza un centro de costo existente.
--  Parametros  :
--    @CompanyId       INT              - ID de la empresa.
--    @Code            NVARCHAR(20)     - Codigo del centro a actualizar.
--    @Name            NVARCHAR(200)    - Nuevo nombre.
--    @ParentCode      NVARCHAR(20)     - Nuevo codigo padre (opcional).
--    @Resultado       INT OUTPUT       - 1=exito, 0=error.
--    @Mensaje         NVARCHAR(500) OUTPUT - Mensaje descriptivo.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Acct_CostCenter_Update
    @CompanyId   INT,
    @Code        NVARCHAR(20),
    @Name        NVARCHAR(200),
    @ParentCode  NVARCHAR(20)  = NULL,
    @Resultado   INT           OUTPUT,
    @Mensaje     NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SET @Resultado = 0;
    SET @Mensaje   = N'';

    IF NOT EXISTS (
        SELECT 1 FROM acct.CostCenter
        WHERE CompanyId = @CompanyId AND CostCenterCode = @Code AND IsDeleted = 0
    )
    BEGIN
        SET @Mensaje = N'Centro de costo ' + @Code + N' no encontrado.';
        RETURN;
    END;

    DECLARE @ParentId INT = NULL;
    DECLARE @Lvl TINYINT = 1;

    IF @ParentCode IS NOT NULL
    BEGIN
        SELECT @ParentId = CostCenterId, @Lvl = Level + 1
        FROM   acct.CostCenter
        WHERE  CompanyId = @CompanyId AND CostCenterCode = @ParentCode AND IsDeleted = 0;

        IF @ParentId IS NULL
        BEGIN
            SET @Mensaje = N'Centro de costo padre ' + @ParentCode + N' no encontrado.';
            RETURN;
        END;
    END;

    BEGIN TRY
        UPDATE acct.CostCenter
        SET    CostCenterName     = @Name,
               ParentCostCenterId = @ParentId,
               Level              = @Lvl,
               UpdatedAt          = SYSUTCDATETIME()
        WHERE  CompanyId       = @CompanyId
          AND  CostCenterCode  = @Code
          AND  IsDeleted       = 0;

        SET @Resultado = 1;
        SET @Mensaje   = N'Centro de costo ' + @Code + N' actualizado exitosamente.';
    END TRY
    BEGIN CATCH
        SET @Resultado = 0;
        SET @Mensaje   = N'Error al actualizar centro de costo: ' + ERROR_MESSAGE();
    END CATCH;
END;
GO

-- =============================================================================
--  SP 11: usp_Acct_CostCenter_Delete
--  Descripcion : Eliminacion logica de un centro de costo. Valida sin hijos.
--  Parametros  :
--    @CompanyId       INT              - ID de la empresa.
--    @Code            NVARCHAR(20)     - Codigo del centro a eliminar.
--    @Resultado       INT OUTPUT       - 1=exito, 0=error.
--    @Mensaje         NVARCHAR(500) OUTPUT - Mensaje descriptivo.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Acct_CostCenter_Delete
    @CompanyId   INT,
    @Code        NVARCHAR(20),
    @Resultado   INT           OUTPUT,
    @Mensaje     NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SET @Resultado = 0;
    SET @Mensaje   = N'';

    DECLARE @CcId INT;
    SELECT @CcId = CostCenterId
    FROM   acct.CostCenter
    WHERE  CompanyId = @CompanyId AND CostCenterCode = @Code AND IsDeleted = 0;

    IF @CcId IS NULL
    BEGIN
        SET @Mensaje = N'Centro de costo ' + @Code + N' no encontrado.';
        RETURN;
    END;

    -- Validar que no tenga hijos activos
    IF EXISTS (
        SELECT 1 FROM acct.CostCenter
        WHERE ParentCostCenterId = @CcId AND IsDeleted = 0
    )
    BEGIN
        SET @Mensaje = N'No se puede eliminar: el centro de costo tiene hijos activos.';
        RETURN;
    END;

    BEGIN TRY
        UPDATE acct.CostCenter
        SET    IsDeleted = 1,
               IsActive  = 0,
               UpdatedAt = SYSUTCDATETIME()
        WHERE  CostCenterId = @CcId;

        SET @Resultado = 1;
        SET @Mensaje   = N'Centro de costo ' + @Code + N' eliminado exitosamente.';
    END TRY
    BEGIN CATCH
        SET @Resultado = 0;
        SET @Mensaje   = N'Error al eliminar centro de costo: ' + ERROR_MESSAGE();
    END CATCH;
END;
GO

-- =============================================================================
--  SP 12: usp_Acct_Report_PnLByCostCenter
--  Descripcion : Estado de resultados agrupado por centro de costo.
--  Parametros  :
--    @CompanyId   INT              - ID de la empresa.
--    @FechaDesde  DATE             - Fecha inicio.
--    @FechaHasta  DATE             - Fecha fin.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Acct_Report_PnLByCostCenter
    @CompanyId   INT,
    @FechaDesde  DATE,
    @FechaHasta  DATE
AS
BEGIN
    SET NOCOUNT ON;

    SELECT ISNULL(jel.CostCenterCode, N'SIN-CC') AS CostCenterCode,
           ISNULL(cc.CostCenterName, N'Sin centro de costo') AS CostCenterName,
           a.AccountCode,
           a.AccountName,
           a.AccountType,
           SUM(jel.DebitAmount)  AS TotalDebit,
           SUM(jel.CreditAmount) AS TotalCredit,
           CASE
               WHEN a.AccountType = 'I' THEN SUM(jel.CreditAmount) - SUM(jel.DebitAmount)
               WHEN a.AccountType = 'G' THEN SUM(jel.DebitAmount)  - SUM(jel.CreditAmount)
               ELSE SUM(jel.DebitAmount) - SUM(jel.CreditAmount)
           END AS Saldo
    FROM   acct.JournalEntryLine jel
    JOIN   acct.JournalEntry je ON je.JournalEntryId = jel.JournalEntryId
    JOIN   acct.Account a       ON a.AccountId       = jel.AccountId
    LEFT JOIN acct.CostCenter cc ON cc.CostCenterCode = jel.CostCenterCode
                                AND cc.CompanyId       = @CompanyId
                                AND cc.IsDeleted       = 0
    WHERE  je.CompanyId  = @CompanyId
      AND  je.EntryDate  >= @FechaDesde
      AND  je.EntryDate  <= @FechaHasta
      AND  je.Status     = 'APPROVED'
      AND  je.IsDeleted  = 0
      AND  a.AccountType IN ('I', 'G')
      AND  a.IsDeleted   = 0
    GROUP BY jel.CostCenterCode, cc.CostCenterName,
             a.AccountCode, a.AccountName, a.AccountType
    ORDER BY jel.CostCenterCode, a.AccountCode;
END;
GO

-- ============================================================================
-- PART 2C: STORED PROCEDURES - PRESUPUESTOS (7 SPs)
-- ============================================================================

-- =============================================================================
--  SP 13: usp_Acct_Budget_List
--  Descripcion : Lista paginada de presupuestos.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Acct_Budget_List
    @CompanyId   INT,
    @FiscalYear  SMALLINT      = NULL,
    @Status      NVARCHAR(10)  = NULL,
    @Page        INT           = 1,
    @Limit       INT           = 50,
    @TotalCount  INT           OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    IF @Page  < 1   SET @Page  = 1;
    IF @Limit < 1   SET @Limit = 50;
    IF @Limit > 500 SET @Limit = 500;

    SELECT @TotalCount = COUNT(*)
    FROM   acct.Budget
    WHERE  CompanyId = @CompanyId
      AND  IsDeleted = 0
      AND  (@FiscalYear IS NULL OR FiscalYear = @FiscalYear)
      AND  (@Status     IS NULL OR Status     = @Status);

    SELECT BudgetId,
           BudgetName,
           FiscalYear,
           CostCenterCode,
           Status,
           Notes,
           CreatedAt,
           UpdatedAt
    FROM   acct.Budget
    WHERE  CompanyId = @CompanyId
      AND  IsDeleted = 0
      AND  (@FiscalYear IS NULL OR FiscalYear = @FiscalYear)
      AND  (@Status     IS NULL OR Status     = @Status)
    ORDER BY FiscalYear DESC, BudgetName
    OFFSET (@Page - 1) * @Limit ROWS
    FETCH NEXT @Limit ROWS ONLY;
END;
GO

-- =============================================================================
--  SP 14: usp_Acct_Budget_Get
--  Descripcion : Obtiene un presupuesto por su ID.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Acct_Budget_Get
    @CompanyId  INT,
    @BudgetId   INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT BudgetId,
           BudgetName,
           FiscalYear,
           CostCenterCode,
           Status,
           Notes,
           CreatedAt,
           UpdatedAt
    FROM   acct.Budget
    WHERE  CompanyId = @CompanyId
      AND  BudgetId  = @BudgetId
      AND  IsDeleted = 0;
END;
GO

-- =============================================================================
--  SP 15: usp_Acct_Budget_GetLines
--  Descripcion : Obtiene las lineas de un presupuesto.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Acct_Budget_GetLines
    @BudgetId  INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT bl.BudgetLineId,
           bl.AccountCode,
           a.AccountName,
           bl.Month01, bl.Month02, bl.Month03, bl.Month04,
           bl.Month05, bl.Month06, bl.Month07, bl.Month08,
           bl.Month09, bl.Month10, bl.Month11, bl.Month12,
           bl.AnnualTotal,
           bl.Notes
    FROM   acct.BudgetLine bl
    LEFT JOIN acct.Account a ON a.AccountCode = bl.AccountCode AND a.IsDeleted = 0
    WHERE  bl.BudgetId = @BudgetId
    ORDER BY bl.AccountCode;
END;
GO

-- =============================================================================
--  SP 16: usp_Acct_Budget_Insert
--  Descripcion : Inserta un presupuesto con sus lineas via OPENJSON.
--  LinesJson format: [{"accountCode":"5.1.01","month01":100,...,"month12":100,"notes":""}]
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Acct_Budget_Insert
    @CompanyId       INT,
    @Name            NVARCHAR(200),
    @FiscalYear      SMALLINT,
    @CostCenterCode  NVARCHAR(20)  = NULL,
    @LinesJson       NVARCHAR(MAX),
    @Resultado       INT           OUTPUT,
    @Mensaje         NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @Resultado = 0;
    SET @Mensaje   = N'';

    IF @Name IS NULL OR LEN(LTRIM(@Name)) = 0
    BEGIN
        SET @Mensaje = N'El nombre del presupuesto es obligatorio.';
        RETURN;
    END;

    BEGIN TRY
        BEGIN TRAN;

        INSERT INTO acct.Budget (CompanyId, BudgetName, FiscalYear, CostCenterCode)
        VALUES (@CompanyId, @Name, @FiscalYear, @CostCenterCode);

        DECLARE @BudgetId INT = SCOPE_IDENTITY();

        INSERT INTO acct.BudgetLine (
            BudgetId, AccountCode,
            Month01, Month02, Month03, Month04, Month05, Month06,
            Month07, Month08, Month09, Month10, Month11, Month12, Notes
        )
        SELECT @BudgetId,
               j.AccountCode,
               ISNULL(j.Month01, 0), ISNULL(j.Month02, 0), ISNULL(j.Month03, 0),
               ISNULL(j.Month04, 0), ISNULL(j.Month05, 0), ISNULL(j.Month06, 0),
               ISNULL(j.Month07, 0), ISNULL(j.Month08, 0), ISNULL(j.Month09, 0),
               ISNULL(j.Month10, 0), ISNULL(j.Month11, 0), ISNULL(j.Month12, 0),
               j.Notes
        FROM OPENJSON(@LinesJson) WITH (
            AccountCode NVARCHAR(20) '$.accountCode',
            Month01     DECIMAL(18,2) '$.month01',
            Month02     DECIMAL(18,2) '$.month02',
            Month03     DECIMAL(18,2) '$.month03',
            Month04     DECIMAL(18,2) '$.month04',
            Month05     DECIMAL(18,2) '$.month05',
            Month06     DECIMAL(18,2) '$.month06',
            Month07     DECIMAL(18,2) '$.month07',
            Month08     DECIMAL(18,2) '$.month08',
            Month09     DECIMAL(18,2) '$.month09',
            Month10     DECIMAL(18,2) '$.month10',
            Month11     DECIMAL(18,2) '$.month11',
            Month12     DECIMAL(18,2) '$.month12',
            Notes       NVARCHAR(200) '$.notes'
        ) j;

        COMMIT TRAN;
        SET @Resultado = 1;
        SET @Mensaje   = N'Presupuesto creado con ID ' + CAST(@BudgetId AS NVARCHAR(10)) + N'.';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRAN;
        SET @Resultado = 0;
        SET @Mensaje   = N'Error al crear presupuesto: ' + ERROR_MESSAGE();
    END CATCH;
END;
GO

-- =============================================================================
--  SP 17: usp_Acct_Budget_Update
--  Descripcion : Actualiza un presupuesto y reemplaza sus lineas.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Acct_Budget_Update
    @CompanyId   INT,
    @BudgetId    INT,
    @Name        NVARCHAR(200),
    @LinesJson   NVARCHAR(MAX),
    @Resultado   INT           OUTPUT,
    @Mensaje     NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @Resultado = 0;
    SET @Mensaje   = N'';

    IF NOT EXISTS (
        SELECT 1 FROM acct.Budget
        WHERE CompanyId = @CompanyId AND BudgetId = @BudgetId AND IsDeleted = 0
    )
    BEGIN
        SET @Mensaje = N'Presupuesto no encontrado.';
        RETURN;
    END;

    BEGIN TRY
        BEGIN TRAN;

        UPDATE acct.Budget
        SET    BudgetName = @Name,
               UpdatedAt  = SYSUTCDATETIME()
        WHERE  BudgetId = @BudgetId;

        DELETE FROM acct.BudgetLine WHERE BudgetId = @BudgetId;

        INSERT INTO acct.BudgetLine (
            BudgetId, AccountCode,
            Month01, Month02, Month03, Month04, Month05, Month06,
            Month07, Month08, Month09, Month10, Month11, Month12, Notes
        )
        SELECT @BudgetId,
               j.AccountCode,
               ISNULL(j.Month01, 0), ISNULL(j.Month02, 0), ISNULL(j.Month03, 0),
               ISNULL(j.Month04, 0), ISNULL(j.Month05, 0), ISNULL(j.Month06, 0),
               ISNULL(j.Month07, 0), ISNULL(j.Month08, 0), ISNULL(j.Month09, 0),
               ISNULL(j.Month10, 0), ISNULL(j.Month11, 0), ISNULL(j.Month12, 0),
               j.Notes
        FROM OPENJSON(@LinesJson) WITH (
            AccountCode NVARCHAR(20) '$.accountCode',
            Month01     DECIMAL(18,2) '$.month01',
            Month02     DECIMAL(18,2) '$.month02',
            Month03     DECIMAL(18,2) '$.month03',
            Month04     DECIMAL(18,2) '$.month04',
            Month05     DECIMAL(18,2) '$.month05',
            Month06     DECIMAL(18,2) '$.month06',
            Month07     DECIMAL(18,2) '$.month07',
            Month08     DECIMAL(18,2) '$.month08',
            Month09     DECIMAL(18,2) '$.month09',
            Month10     DECIMAL(18,2) '$.month10',
            Month11     DECIMAL(18,2) '$.month11',
            Month12     DECIMAL(18,2) '$.month12',
            Notes       NVARCHAR(200) '$.notes'
        ) j;

        COMMIT TRAN;
        SET @Resultado = 1;
        SET @Mensaje   = N'Presupuesto actualizado exitosamente.';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRAN;
        SET @Resultado = 0;
        SET @Mensaje   = N'Error al actualizar presupuesto: ' + ERROR_MESSAGE();
    END CATCH;
END;
GO

-- =============================================================================
--  SP 18: usp_Acct_Budget_Delete
--  Descripcion : Eliminacion logica de un presupuesto.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Acct_Budget_Delete
    @CompanyId   INT,
    @BudgetId    INT,
    @Resultado   INT           OUTPUT,
    @Mensaje     NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SET @Resultado = 0;
    SET @Mensaje   = N'';

    IF NOT EXISTS (
        SELECT 1 FROM acct.Budget
        WHERE CompanyId = @CompanyId AND BudgetId = @BudgetId AND IsDeleted = 0
    )
    BEGIN
        SET @Mensaje = N'Presupuesto no encontrado.';
        RETURN;
    END;

    UPDATE acct.Budget
    SET    IsDeleted = 1,
           UpdatedAt = SYSUTCDATETIME()
    WHERE  BudgetId = @BudgetId;

    SET @Resultado = 1;
    SET @Mensaje   = N'Presupuesto eliminado exitosamente.';
END;
GO

-- =============================================================================
--  SP 19: usp_Acct_Budget_Variance
--  Descripcion : Compara presupuesto vs real para cada linea.
--  Parametros  :
--    @CompanyId   INT              - ID de la empresa.
--    @BudgetId    INT              - ID del presupuesto.
--    @FechaDesde  DATE             - Fecha inicio del rango real.
--    @FechaHasta  DATE             - Fecha fin del rango real.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Acct_Budget_Variance
    @CompanyId   INT,
    @BudgetId    INT,
    @FechaDesde  DATE,
    @FechaHasta  DATE
AS
BEGIN
    SET NOCOUNT ON;

    SELECT bl.AccountCode,
           a.AccountName,
           bl.AnnualTotal AS BudgetAmount,
           ISNULL(act.ActualAmount, 0) AS ActualAmount,
           bl.AnnualTotal - ISNULL(act.ActualAmount, 0) AS Variance,
           CASE
               WHEN bl.AnnualTotal = 0 THEN 0
               ELSE ROUND((bl.AnnualTotal - ISNULL(act.ActualAmount, 0)) / bl.AnnualTotal * 100, 2)
           END AS VariancePct
    FROM   acct.BudgetLine bl
    LEFT JOIN acct.Account a ON a.AccountCode = bl.AccountCode
                            AND a.CompanyId   = @CompanyId
                            AND a.IsDeleted   = 0
    LEFT JOIN (
        SELECT jel.AccountCodeSnapshot AS AccountCode,
               SUM(jel.DebitAmount - jel.CreditAmount) AS ActualAmount
        FROM   acct.JournalEntryLine jel
        JOIN   acct.JournalEntry je ON je.JournalEntryId = jel.JournalEntryId
        WHERE  je.CompanyId  = @CompanyId
          AND  je.EntryDate  >= @FechaDesde
          AND  je.EntryDate  <= @FechaHasta
          AND  je.Status     = 'APPROVED'
          AND  je.IsDeleted  = 0
        GROUP BY jel.AccountCodeSnapshot
    ) act ON act.AccountCode = bl.AccountCode
    WHERE  bl.BudgetId = @BudgetId
    ORDER BY bl.AccountCode;
END;
GO

-- ============================================================================
-- PART 2D: STORED PROCEDURES - ASIENTOS RECURRENTES (8 SPs)
-- ============================================================================

-- =============================================================================
--  SP 20: usp_Acct_RecurringEntry_List
--  Descripcion : Lista paginada de plantillas de asientos recurrentes.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Acct_RecurringEntry_List
    @CompanyId   INT,
    @IsActive    BIT           = NULL,
    @Page        INT           = 1,
    @Limit       INT           = 50,
    @TotalCount  INT           OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    IF @Page  < 1   SET @Page  = 1;
    IF @Limit < 1   SET @Limit = 50;
    IF @Limit > 500 SET @Limit = 500;

    SELECT @TotalCount = COUNT(*)
    FROM   acct.RecurringEntry
    WHERE  CompanyId = @CompanyId
      AND  IsDeleted = 0
      AND  (@IsActive IS NULL OR IsActive = @IsActive);

    SELECT RecurringEntryId,
           TemplateName,
           Frequency,
           NextExecutionDate,
           LastExecutedDate,
           TimesExecuted,
           MaxExecutions,
           TipoAsiento,
           Concepto,
           IsActive
    FROM   acct.RecurringEntry
    WHERE  CompanyId = @CompanyId
      AND  IsDeleted = 0
      AND  (@IsActive IS NULL OR IsActive = @IsActive)
    ORDER BY NextExecutionDate
    OFFSET (@Page - 1) * @Limit ROWS
    FETCH NEXT @Limit ROWS ONLY;
END;
GO

-- =============================================================================
--  SP 21: usp_Acct_RecurringEntry_Get
--  Descripcion : Obtiene una plantilla recurrente por su ID.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Acct_RecurringEntry_Get
    @CompanyId         INT,
    @RecurringEntryId  INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT RecurringEntryId,
           TemplateName,
           Frequency,
           NextExecutionDate,
           LastExecutedDate,
           TimesExecuted,
           MaxExecutions,
           TipoAsiento,
           Concepto,
           IsActive,
           CreatedAt
    FROM   acct.RecurringEntry
    WHERE  CompanyId        = @CompanyId
      AND  RecurringEntryId = @RecurringEntryId
      AND  IsDeleted        = 0;
END;
GO

-- =============================================================================
--  SP 22: usp_Acct_RecurringEntry_GetLines
--  Descripcion : Obtiene las lineas de una plantilla recurrente.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Acct_RecurringEntry_GetLines
    @RecurringEntryId  INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT rel.LineId,
           rel.AccountCode,
           a.AccountName,
           rel.Description,
           rel.CostCenterCode,
           rel.Debit,
           rel.Credit
    FROM   acct.RecurringEntryLine rel
    LEFT JOIN acct.Account a ON a.AccountCode = rel.AccountCode AND a.IsDeleted = 0
    WHERE  rel.RecurringEntryId = @RecurringEntryId
    ORDER BY rel.LineId;
END;
GO

-- =============================================================================
--  SP 23: usp_Acct_RecurringEntry_Insert
--  Descripcion : Inserta plantilla recurrente con lineas via OPENJSON.
--  LinesJson: [{"accountCode":"5.1.01","description":"...","costCenterCode":null,"debit":100,"credit":0}]
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Acct_RecurringEntry_Insert
    @CompanyId          INT,
    @TemplateName       NVARCHAR(200),
    @Frequency          NVARCHAR(10),
    @NextExecutionDate  DATE,
    @TipoAsiento        NVARCHAR(20),
    @Concepto           NVARCHAR(300),
    @MaxExecutions      INT            = NULL,
    @LinesJson          NVARCHAR(MAX),
    @Resultado          INT            OUTPUT,
    @Mensaje            NVARCHAR(500)  OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @Resultado = 0;
    SET @Mensaje   = N'';

    IF @TemplateName IS NULL OR LEN(LTRIM(@TemplateName)) = 0
    BEGIN
        SET @Mensaje = N'El nombre de la plantilla es obligatorio.';
        RETURN;
    END;

    -- Validar que debito = credito en las lineas
    DECLARE @SumDebit  DECIMAL(18,2);
    DECLARE @SumCredit DECIMAL(18,2);

    SELECT @SumDebit  = SUM(ISNULL(j.Debit, 0)),
           @SumCredit = SUM(ISNULL(j.Credit, 0))
    FROM OPENJSON(@LinesJson) WITH (
        Debit  DECIMAL(18,2) '$.debit',
        Credit DECIMAL(18,2) '$.credit'
    ) j;

    IF ABS(ISNULL(@SumDebit, 0) - ISNULL(@SumCredit, 0)) > 0.01
    BEGIN
        SET @Mensaje = N'Las lineas no estan balanceadas (Debe=' + CAST(@SumDebit AS NVARCHAR(20))
                     + N', Haber=' + CAST(@SumCredit AS NVARCHAR(20)) + N').';
        RETURN;
    END;

    BEGIN TRY
        BEGIN TRAN;

        INSERT INTO acct.RecurringEntry (
            CompanyId, TemplateName, Frequency, NextExecutionDate,
            MaxExecutions, TipoAsiento, Concepto
        )
        VALUES (
            @CompanyId, @TemplateName, @Frequency, @NextExecutionDate,
            @MaxExecutions, @TipoAsiento, @Concepto
        );

        DECLARE @ReId INT = SCOPE_IDENTITY();

        INSERT INTO acct.RecurringEntryLine (
            RecurringEntryId, AccountCode, Description, CostCenterCode, Debit, Credit
        )
        SELECT @ReId,
               j.AccountCode,
               j.Description,
               j.CostCenterCode,
               ISNULL(j.Debit, 0),
               ISNULL(j.Credit, 0)
        FROM OPENJSON(@LinesJson) WITH (
            AccountCode    NVARCHAR(20)  '$.accountCode',
            Description    NVARCHAR(200) '$.description',
            CostCenterCode NVARCHAR(20)  '$.costCenterCode',
            Debit          DECIMAL(18,2) '$.debit',
            Credit         DECIMAL(18,2) '$.credit'
        ) j;

        COMMIT TRAN;
        SET @Resultado = 1;
        SET @Mensaje   = N'Plantilla recurrente creada con ID ' + CAST(@ReId AS NVARCHAR(10)) + N'.';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRAN;
        SET @Resultado = 0;
        SET @Mensaje   = N'Error al crear plantilla recurrente: ' + ERROR_MESSAGE();
    END CATCH;
END;
GO

-- =============================================================================
--  SP 24: usp_Acct_RecurringEntry_Update
--  Descripcion : Actualiza plantilla recurrente y reemplaza sus lineas.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Acct_RecurringEntry_Update
    @CompanyId          INT,
    @RecurringEntryId   INT,
    @TemplateName       NVARCHAR(200),
    @Frequency          NVARCHAR(10),
    @NextExecutionDate  DATE,
    @Concepto           NVARCHAR(300),
    @MaxExecutions      INT            = NULL,
    @LinesJson          NVARCHAR(MAX),
    @Resultado          INT            OUTPUT,
    @Mensaje            NVARCHAR(500)  OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @Resultado = 0;
    SET @Mensaje   = N'';

    IF NOT EXISTS (
        SELECT 1 FROM acct.RecurringEntry
        WHERE CompanyId = @CompanyId AND RecurringEntryId = @RecurringEntryId AND IsDeleted = 0
    )
    BEGIN
        SET @Mensaje = N'Plantilla recurrente no encontrada.';
        RETURN;
    END;

    BEGIN TRY
        BEGIN TRAN;

        UPDATE acct.RecurringEntry
        SET    TemplateName       = @TemplateName,
               Frequency          = @Frequency,
               NextExecutionDate  = @NextExecutionDate,
               Concepto           = @Concepto,
               MaxExecutions      = @MaxExecutions
        WHERE  RecurringEntryId = @RecurringEntryId;

        DELETE FROM acct.RecurringEntryLine WHERE RecurringEntryId = @RecurringEntryId;

        INSERT INTO acct.RecurringEntryLine (
            RecurringEntryId, AccountCode, Description, CostCenterCode, Debit, Credit
        )
        SELECT @RecurringEntryId,
               j.AccountCode,
               j.Description,
               j.CostCenterCode,
               ISNULL(j.Debit, 0),
               ISNULL(j.Credit, 0)
        FROM OPENJSON(@LinesJson) WITH (
            AccountCode    NVARCHAR(20)  '$.accountCode',
            Description    NVARCHAR(200) '$.description',
            CostCenterCode NVARCHAR(20)  '$.costCenterCode',
            Debit          DECIMAL(18,2) '$.debit',
            Credit         DECIMAL(18,2) '$.credit'
        ) j;

        COMMIT TRAN;
        SET @Resultado = 1;
        SET @Mensaje   = N'Plantilla recurrente actualizada exitosamente.';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRAN;
        SET @Resultado = 0;
        SET @Mensaje   = N'Error al actualizar plantilla: ' + ERROR_MESSAGE();
    END CATCH;
END;
GO

-- =============================================================================
--  SP 25: usp_Acct_RecurringEntry_Delete
--  Descripcion : Eliminacion logica de una plantilla recurrente.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Acct_RecurringEntry_Delete
    @CompanyId          INT,
    @RecurringEntryId   INT,
    @Resultado          INT           OUTPUT,
    @Mensaje            NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SET @Resultado = 0;
    SET @Mensaje   = N'';

    IF NOT EXISTS (
        SELECT 1 FROM acct.RecurringEntry
        WHERE CompanyId = @CompanyId AND RecurringEntryId = @RecurringEntryId AND IsDeleted = 0
    )
    BEGIN
        SET @Mensaje = N'Plantilla recurrente no encontrada.';
        RETURN;
    END;

    UPDATE acct.RecurringEntry
    SET    IsDeleted = 1,
           IsActive  = 0
    WHERE  RecurringEntryId = @RecurringEntryId;

    SET @Resultado = 1;
    SET @Mensaje   = N'Plantilla recurrente eliminada exitosamente.';
END;
GO

-- =============================================================================
--  SP 26: usp_Acct_RecurringEntry_Execute
--  Descripcion : Ejecuta una plantilla recurrente, creando un asiento real.
--                Actualiza NextExecutionDate e incrementa TimesExecuted.
--  Parametros  :
--    @CompanyId          INT          - ID de la empresa.
--    @RecurringEntryId   INT          - ID de la plantilla.
--    @ExecutionDate      DATE         - Fecha del asiento a generar.
--    @UserId             INT          - ID del usuario que ejecuta.
--    @Resultado          INT OUTPUT   - 1=exito, 0=error.
--    @Mensaje            NVARCHAR(500) OUTPUT - Mensaje descriptivo.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Acct_RecurringEntry_Execute
    @CompanyId          INT,
    @RecurringEntryId   INT,
    @ExecutionDate      DATE,
    @UserId             INT,
    @Resultado          INT           OUTPUT,
    @Mensaje            NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @Resultado = 0;
    SET @Mensaje   = N'';

    -- Leer plantilla
    DECLARE @TemplateName NVARCHAR(200), @Frequency NVARCHAR(10),
            @TipoAsiento NVARCHAR(20), @Concepto NVARCHAR(300),
            @MaxExec INT, @TimesExec INT, @IsActive BIT;

    SELECT @TemplateName = TemplateName, @Frequency = Frequency,
           @TipoAsiento  = TipoAsiento,  @Concepto  = Concepto,
           @MaxExec      = MaxExecutions, @TimesExec = TimesExecuted,
           @IsActive     = IsActive
    FROM   acct.RecurringEntry
    WHERE  CompanyId = @CompanyId AND RecurringEntryId = @RecurringEntryId AND IsDeleted = 0;

    IF @TemplateName IS NULL
    BEGIN
        SET @Mensaje = N'Plantilla recurrente no encontrada.';
        RETURN;
    END;

    IF @IsActive = 0
    BEGIN
        SET @Mensaje = N'La plantilla esta inactiva.';
        RETURN;
    END;

    IF @MaxExec IS NOT NULL AND @TimesExec >= @MaxExec
    BEGIN
        SET @Mensaje = N'La plantilla alcanzo el maximo de ejecuciones (' + CAST(@MaxExec AS NVARCHAR(10)) + N').';
        RETURN;
    END;

    BEGIN TRY
        BEGIN TRAN;

        -- PeriodCode
        DECLARE @PeriodCodeFmt NVARCHAR(7) = LEFT(CONVERT(CHAR(10), @ExecutionDate, 120), 4)
            + '-' + SUBSTRING(CONVERT(CHAR(10), @ExecutionDate, 120), 6, 2);

        -- Generar numero de asiento
        DECLARE @BranchId INT;
        SELECT TOP 1 @BranchId = BranchId
        FROM   cfg.Branch WHERE CompanyId = @CompanyId AND IsDeleted = 0 ORDER BY BranchId;
        IF @BranchId IS NULL SET @BranchId = 1;

        DECLARE @SeqNum INT;
        SELECT @SeqNum = ISNULL(MAX(TRY_CAST(RIGHT(EntryNumber, 6) AS INT)), 0) + 1
        FROM   acct.JournalEntry
        WHERE  CompanyId = @CompanyId AND EntryType = @TipoAsiento AND PeriodCode = @PeriodCodeFmt;

        DECLARE @EntryNumber NVARCHAR(40) = @TipoAsiento + N'-'
            + REPLACE(@PeriodCodeFmt, '-', '') + N'-'
            + RIGHT('000000' + CAST(@SeqNum AS NVARCHAR(6)), 6);

        -- Insertar cabecera
        INSERT INTO acct.JournalEntry (
            CompanyId, BranchId, EntryNumber, EntryDate, PeriodCode,
            EntryType, Concept, CurrencyCode, TotalDebit, TotalCredit,
            Status, SourceModule, CreatedByUserId
        )
        VALUES (
            @CompanyId, @BranchId, @EntryNumber, @ExecutionDate, @PeriodCodeFmt,
            @TipoAsiento, @Concepto + N' [Recurrente: ' + @TemplateName + N']',
            'VES', 0, 0, 'APPROVED', 'RECURRENTE', @UserId
        );

        DECLARE @EntryId BIGINT = SCOPE_IDENTITY();

        -- Insertar lineas desde la plantilla
        INSERT INTO acct.JournalEntryLine (
            JournalEntryId, LineNumber, AccountId, AccountCodeSnapshot,
            Description, DebitAmount, CreditAmount, CostCenterCode
        )
        SELECT @EntryId,
               ROW_NUMBER() OVER (ORDER BY rel.LineId),
               a.AccountId,
               rel.AccountCode,
               rel.Description,
               rel.Debit,
               rel.Credit,
               rel.CostCenterCode
        FROM   acct.RecurringEntryLine rel
        JOIN   acct.Account a ON a.AccountCode = rel.AccountCode
                             AND a.CompanyId   = @CompanyId
                             AND a.IsDeleted   = 0
        WHERE  rel.RecurringEntryId = @RecurringEntryId;

        -- Actualizar totales
        DECLARE @TD DECIMAL(18,2), @TC DECIMAL(18,2);
        SELECT @TD = SUM(DebitAmount), @TC = SUM(CreditAmount)
        FROM   acct.JournalEntryLine WHERE JournalEntryId = @EntryId;

        UPDATE acct.JournalEntry
        SET    TotalDebit = ISNULL(@TD, 0), TotalCredit = ISNULL(@TC, 0)
        WHERE  JournalEntryId = @EntryId;

        -- Calcular siguiente fecha de ejecucion
        DECLARE @NextDate DATE;
        SET @NextDate = CASE @Frequency
            WHEN 'DAILY'     THEN DATEADD(DAY, 1, @ExecutionDate)
            WHEN 'WEEKLY'    THEN DATEADD(WEEK, 1, @ExecutionDate)
            WHEN 'MONTHLY'   THEN DATEADD(MONTH, 1, @ExecutionDate)
            WHEN 'QUARTERLY' THEN DATEADD(QUARTER, 1, @ExecutionDate)
            WHEN 'YEARLY'    THEN DATEADD(YEAR, 1, @ExecutionDate)
            ELSE DATEADD(MONTH, 1, @ExecutionDate)
        END;

        -- Actualizar plantilla
        UPDATE acct.RecurringEntry
        SET    NextExecutionDate = @NextDate,
               LastExecutedDate  = @ExecutionDate,
               TimesExecuted     = TimesExecuted + 1,
               IsActive          = CASE
                   WHEN MaxExecutions IS NOT NULL AND TimesExecuted + 1 >= MaxExecutions THEN 0
                   ELSE 1
               END
        WHERE  RecurringEntryId = @RecurringEntryId;

        COMMIT TRAN;
        SET @Resultado = 1;
        SET @Mensaje   = N'Asiento ' + @EntryNumber + N' generado desde plantilla recurrente.';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRAN;
        SET @Resultado = 0;
        SET @Mensaje   = N'Error al ejecutar recurrente: ' + ERROR_MESSAGE();
    END CATCH;
END;
GO

-- =============================================================================
--  SP 27: usp_Acct_RecurringEntry_GetDue
--  Descripcion : Devuelve plantillas recurrentes cuya fecha <= hoy y estan activas.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Acct_RecurringEntry_GetDue
    @CompanyId  INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT RecurringEntryId,
           TemplateName,
           Frequency,
           NextExecutionDate,
           LastExecutedDate,
           TimesExecuted,
           MaxExecutions,
           TipoAsiento,
           Concepto
    FROM   acct.RecurringEntry
    WHERE  CompanyId          = @CompanyId
      AND  IsActive           = 1
      AND  IsDeleted          = 0
      AND  NextExecutionDate <= CAST(SYSUTCDATETIME() AS DATE)
      AND  (MaxExecutions IS NULL OR TimesExecuted < MaxExecutions)
    ORDER BY NextExecutionDate;
END;
GO

-- ============================================================================
-- PART 2E: REVERSION (1 SP)
-- ============================================================================

-- =============================================================================
--  SP 28: usp_Acct_Entry_Reverse
--  Descripcion : Crea un asiento de reversion (Debe/Haber invertidos).
--  Parametros  :
--    @CompanyId   INT              - ID de la empresa.
--    @EntryId     INT              - ID del asiento original.
--    @Fecha       DATE             - Fecha del asiento de reversion.
--    @UserId      INT              - ID del usuario.
--    @Motivo      NVARCHAR(300)    - Motivo de la reversion.
--    @Resultado   INT OUTPUT       - 1=exito, 0=error.
--    @Mensaje     NVARCHAR(500) OUTPUT - Mensaje descriptivo.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Acct_Entry_Reverse
    @CompanyId   INT,
    @EntryId     INT,
    @Fecha       DATE,
    @UserId      INT,
    @Motivo      NVARCHAR(300),
    @Resultado   INT           OUTPUT,
    @Mensaje     NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @Resultado = 0;
    SET @Mensaje   = N'';

    -- Leer asiento original
    DECLARE @OrigNumber NVARCHAR(40), @OrigType NVARCHAR(20), @OrigConcept NVARCHAR(400),
            @OrigCurrency CHAR(3), @OrigRate DECIMAL(18,6), @BranchId INT;

    SELECT @OrigNumber  = EntryNumber, @OrigType    = EntryType,
           @OrigConcept = Concept,     @OrigCurrency = CurrencyCode,
           @OrigRate    = ExchangeRate, @BranchId    = BranchId
    FROM   acct.JournalEntry
    WHERE  CompanyId      = @CompanyId
      AND  JournalEntryId = @EntryId
      AND  Status         = 'APPROVED'
      AND  IsDeleted      = 0;

    IF @OrigNumber IS NULL
    BEGIN
        SET @Mensaje = N'Asiento original no encontrado o no esta aprobado.';
        RETURN;
    END;

    BEGIN TRY
        BEGIN TRAN;

        DECLARE @PeriodCodeFmt NVARCHAR(7) = LEFT(CONVERT(CHAR(10), @Fecha, 120), 4)
            + '-' + SUBSTRING(CONVERT(CHAR(10), @Fecha, 120), 6, 2);

        DECLARE @RevNumber NVARCHAR(40) = N'REV-' + @OrigNumber;

        -- Insertar asiento de reversion
        INSERT INTO acct.JournalEntry (
            CompanyId, BranchId, EntryNumber, EntryDate, PeriodCode,
            EntryType, ReferenceNumber, Concept, CurrencyCode, ExchangeRate,
            TotalDebit, TotalCredit, Status, SourceModule, CreatedByUserId
        )
        VALUES (
            @CompanyId, @BranchId, @RevNumber, @Fecha, @PeriodCodeFmt,
            'REV', @OrigNumber,
            N'REVERSION de ' + @OrigNumber + N': ' + ISNULL(@Motivo, N''),
            @OrigCurrency, @OrigRate, 0, 0, 'APPROVED', 'CONTABILIDAD', @UserId
        );

        DECLARE @NewEntryId BIGINT = SCOPE_IDENTITY();

        -- Insertar lineas con Debe/Haber invertidos
        INSERT INTO acct.JournalEntryLine (
            JournalEntryId, LineNumber, AccountId, AccountCodeSnapshot,
            Description, DebitAmount, CreditAmount, CostCenterCode
        )
        SELECT @NewEntryId,
               LineNumber,
               AccountId,
               AccountCodeSnapshot,
               N'REV: ' + ISNULL(Description, N''),
               CreditAmount,   -- invertido
               DebitAmount,     -- invertido
               CostCenterCode
        FROM   acct.JournalEntryLine
        WHERE  JournalEntryId = @EntryId;

        -- Actualizar totales
        DECLARE @TD DECIMAL(18,2), @TC DECIMAL(18,2);
        SELECT @TD = SUM(DebitAmount), @TC = SUM(CreditAmount)
        FROM   acct.JournalEntryLine WHERE JournalEntryId = @NewEntryId;

        UPDATE acct.JournalEntry
        SET    TotalDebit = ISNULL(@TD, 0), TotalCredit = ISNULL(@TC, 0)
        WHERE  JournalEntryId = @NewEntryId;

        COMMIT TRAN;
        SET @Resultado = 1;
        SET @Mensaje   = N'Asiento de reversion ' + @RevNumber + N' creado exitosamente.';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRAN;
        SET @Resultado = 0;
        SET @Mensaje   = N'Error al revertir asiento: ' + ERROR_MESSAGE();
    END CATCH;
END;
GO

-- ============================================================================
-- PART 2F: REPORTES AVANZADOS (8 SPs)
-- ============================================================================

-- =============================================================================
--  SP 29: usp_Acct_Report_CashFlow
--  Descripcion : Reporte de flujo de efectivo clasificado por categoria.
--  Parametros  :
--    @CompanyId   INT              - ID de la empresa.
--    @FechaDesde  DATE             - Fecha inicio.
--    @FechaHasta  DATE             - Fecha fin.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Acct_Report_CashFlow
    @CompanyId   INT,
    @FechaDesde  DATE,
    @FechaHasta  DATE
AS
BEGIN
    SET NOCOUNT ON;

    SELECT CASE
               WHEN a.AccountType IN ('I', 'G') THEN N'OPERACION'
               WHEN a.AccountType = 'A' AND a.AccountLevel >= 3
                    AND a.AccountCode LIKE '1.2%' THEN N'INVERSION'
               WHEN a.AccountType = 'P' AND a.AccountCode LIKE '2.2%' THEN N'FINANCIAMIENTO'
               WHEN a.AccountType = 'C' THEN N'FINANCIAMIENTO'
               ELSE N'OPERACION'
           END AS Category,
           a.AccountCode,
           a.AccountName,
           SUM(jel.DebitAmount - jel.CreditAmount) AS Amount
    FROM   acct.JournalEntryLine jel
    JOIN   acct.JournalEntry je ON je.JournalEntryId = jel.JournalEntryId
    JOIN   acct.Account a       ON a.AccountId       = jel.AccountId
    WHERE  je.CompanyId  = @CompanyId
      AND  je.EntryDate  >= @FechaDesde
      AND  je.EntryDate  <= @FechaHasta
      AND  je.Status     = 'APPROVED'
      AND  je.IsDeleted  = 0
      AND  a.IsDeleted   = 0
    GROUP BY CASE
                 WHEN a.AccountType IN ('I', 'G') THEN N'OPERACION'
                 WHEN a.AccountType = 'A' AND a.AccountLevel >= 3
                      AND a.AccountCode LIKE '1.2%' THEN N'INVERSION'
                 WHEN a.AccountType = 'P' AND a.AccountCode LIKE '2.2%' THEN N'FINANCIAMIENTO'
                 WHEN a.AccountType = 'C' THEN N'FINANCIAMIENTO'
                 ELSE N'OPERACION'
             END,
             a.AccountCode, a.AccountName
    HAVING SUM(jel.DebitAmount - jel.CreditAmount) <> 0
    ORDER BY Category, a.AccountCode;
END;
GO

-- =============================================================================
--  SP 30: usp_Acct_Report_BalanceCompMultiPeriod
--  Descripcion : Balance comparativo multi-periodo. Recibe periodos separados
--                por coma (YYYYMM). Genera columnas dinamicas via PIVOT.
--  Parametros  :
--    @CompanyId  INT              - ID de la empresa.
--    @Periodos   NVARCHAR(200)    - Periodos separados por coma, e.g. '202601,202602,202603'.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Acct_Report_BalanceCompMultiPeriod
    @CompanyId  INT,
    @Periodos   NVARCHAR(200)
AS
BEGIN
    SET NOCOUNT ON;

    -- Parsear periodos a tabla
    CREATE TABLE #Periodos (PeriodCode NVARCHAR(7));

    INSERT INTO #Periodos (PeriodCode)
    SELECT LTRIM(RTRIM(
        LEFT(value, 4) + '-' + RIGHT(LTRIM(RTRIM(value)), 2)
    ))
    FROM STRING_SPLIT(@Periodos, ',')
    WHERE LEN(LTRIM(RTRIM(value))) = 6;

    -- Construir query dinamico con PIVOT
    DECLARE @Cols NVARCHAR(MAX) = N'';
    DECLARE @ColsSelect NVARCHAR(MAX) = N'';

    SELECT @Cols = @Cols + N',' + QUOTENAME(PeriodCode),
           @ColsSelect = @ColsSelect + N',ISNULL(' + QUOTENAME(PeriodCode) + N',0) AS ' + QUOTENAME(PeriodCode)
    FROM   #Periodos ORDER BY PeriodCode;

    SET @Cols = STUFF(@Cols, 1, 1, N'');
    SET @ColsSelect = STUFF(@ColsSelect, 1, 1, N'');

    IF @Cols = N''
    BEGIN
        DROP TABLE #Periodos;
        RETURN;
    END;

    DECLARE @SQL NVARCHAR(MAX) = N'
    SELECT AccountCode, AccountName, AccountType ' + @ColsSelect + N'
    FROM (
        SELECT a.AccountCode, a.AccountName, a.AccountType,
               je.PeriodCode,
               SUM(jel.DebitAmount - jel.CreditAmount) AS Saldo
        FROM   acct.JournalEntryLine jel
        JOIN   acct.JournalEntry je ON je.JournalEntryId = jel.JournalEntryId
        JOIN   acct.Account a       ON a.AccountId       = jel.AccountId
        WHERE  je.CompanyId = @cid
          AND  je.PeriodCode IN (SELECT PeriodCode FROM #Periodos)
          AND  je.Status     = ''APPROVED''
          AND  je.IsDeleted  = 0
          AND  a.IsDeleted   = 0
        GROUP BY a.AccountCode, a.AccountName, a.AccountType, je.PeriodCode
    ) src
    PIVOT (SUM(Saldo) FOR PeriodCode IN (' + @Cols + N')) pvt
    ORDER BY AccountCode';

    EXEC sp_executesql @SQL, N'@cid INT', @cid = @CompanyId;

    DROP TABLE #Periodos;
END;
GO

-- =============================================================================
--  SP 31: usp_Acct_Report_PnLMultiPeriod
--  Descripcion : Estado de resultados multi-periodo (solo cuentas I/G).
--  Parametros  :
--    @CompanyId  INT              - ID de la empresa.
--    @Periodos   NVARCHAR(200)    - Periodos separados por coma (YYYYMM).
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Acct_Report_PnLMultiPeriod
    @CompanyId  INT,
    @Periodos   NVARCHAR(200)
AS
BEGIN
    SET NOCOUNT ON;

    CREATE TABLE #Periodos (PeriodCode NVARCHAR(7));

    INSERT INTO #Periodos (PeriodCode)
    SELECT LTRIM(RTRIM(
        LEFT(value, 4) + '-' + RIGHT(LTRIM(RTRIM(value)), 2)
    ))
    FROM STRING_SPLIT(@Periodos, ',')
    WHERE LEN(LTRIM(RTRIM(value))) = 6;

    DECLARE @Cols NVARCHAR(MAX) = N'';
    DECLARE @ColsSelect NVARCHAR(MAX) = N'';

    SELECT @Cols = @Cols + N',' + QUOTENAME(PeriodCode),
           @ColsSelect = @ColsSelect + N',ISNULL(' + QUOTENAME(PeriodCode) + N',0) AS ' + QUOTENAME(PeriodCode)
    FROM   #Periodos ORDER BY PeriodCode;

    SET @Cols = STUFF(@Cols, 1, 1, N'');
    SET @ColsSelect = STUFF(@ColsSelect, 1, 1, N'');

    IF @Cols = N''
    BEGIN
        DROP TABLE #Periodos;
        RETURN;
    END;

    DECLARE @SQL NVARCHAR(MAX) = N'
    SELECT AccountCode, AccountName, AccountType ' + @ColsSelect + N'
    FROM (
        SELECT a.AccountCode, a.AccountName, a.AccountType,
               je.PeriodCode,
               CASE
                   WHEN a.AccountType = ''I'' THEN SUM(jel.CreditAmount - jel.DebitAmount)
                   ELSE SUM(jel.DebitAmount - jel.CreditAmount)
               END AS Saldo
        FROM   acct.JournalEntryLine jel
        JOIN   acct.JournalEntry je ON je.JournalEntryId = jel.JournalEntryId
        JOIN   acct.Account a       ON a.AccountId       = jel.AccountId
        WHERE  je.CompanyId = @cid
          AND  je.PeriodCode IN (SELECT PeriodCode FROM #Periodos)
          AND  je.Status     = ''APPROVED''
          AND  je.IsDeleted  = 0
          AND  a.AccountType IN (''I'', ''G'')
          AND  a.IsDeleted   = 0
        GROUP BY a.AccountCode, a.AccountName, a.AccountType, je.PeriodCode
    ) src
    PIVOT (SUM(Saldo) FOR PeriodCode IN (' + @Cols + N')) pvt
    ORDER BY AccountCode';

    EXEC sp_executesql @SQL, N'@cid INT', @cid = @CompanyId;

    DROP TABLE #Periodos;
END;
GO

-- =============================================================================
--  SP 32: usp_Acct_Report_AgingCxC
--  Descripcion : Antigüedad de cuentas por cobrar desde asientos contables.
--                Agrupa por auxiliar, buckets: Corriente(0-30), 31-60, 61-90, 90+.
--  Parametros  :
--    @CompanyId   INT              - ID de la empresa.
--    @FechaCorte  DATE             - Fecha de corte para calculo de edad.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Acct_Report_AgingCxC
    @CompanyId   INT,
    @FechaCorte  DATE
AS
BEGIN
    SET NOCOUNT ON;

    SELECT jel.AuxiliaryCode AS EntityCode,
           jel.AuxiliaryType AS EntityType,
           SUM(CASE WHEN DATEDIFF(DAY, je.EntryDate, @FechaCorte) BETWEEN 0  AND 30  THEN jel.DebitAmount - jel.CreditAmount ELSE 0 END) AS Current_0_30,
           SUM(CASE WHEN DATEDIFF(DAY, je.EntryDate, @FechaCorte) BETWEEN 31 AND 60  THEN jel.DebitAmount - jel.CreditAmount ELSE 0 END) AS Days_31_60,
           SUM(CASE WHEN DATEDIFF(DAY, je.EntryDate, @FechaCorte) BETWEEN 61 AND 90  THEN jel.DebitAmount - jel.CreditAmount ELSE 0 END) AS Days_61_90,
           SUM(CASE WHEN DATEDIFF(DAY, je.EntryDate, @FechaCorte) > 90               THEN jel.DebitAmount - jel.CreditAmount ELSE 0 END) AS Days_90_Plus,
           SUM(jel.DebitAmount - jel.CreditAmount) AS Total
    FROM   acct.JournalEntryLine jel
    JOIN   acct.JournalEntry je ON je.JournalEntryId = jel.JournalEntryId
    JOIN   acct.Account a       ON a.AccountId       = jel.AccountId
    WHERE  je.CompanyId  = @CompanyId
      AND  je.EntryDate  <= @FechaCorte
      AND  je.Status     = 'APPROVED'
      AND  je.IsDeleted  = 0
      AND  a.IsDeleted   = 0
      AND  (a.AccountCode LIKE '1.2%' OR (a.AccountType = 'A' AND a.AccountCode LIKE '1.1.2%'))
    GROUP BY jel.AuxiliaryCode, jel.AuxiliaryType
    HAVING SUM(jel.DebitAmount - jel.CreditAmount) <> 0
    ORDER BY Total DESC;
END;
GO

-- =============================================================================
--  SP 33: usp_Acct_Report_AgingCxP
--  Descripcion : Antigüedad de cuentas por pagar desde asientos contables.
--  Parametros  :
--    @CompanyId   INT              - ID de la empresa.
--    @FechaCorte  DATE             - Fecha de corte.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Acct_Report_AgingCxP
    @CompanyId   INT,
    @FechaCorte  DATE
AS
BEGIN
    SET NOCOUNT ON;

    SELECT jel.AuxiliaryCode AS EntityCode,
           jel.AuxiliaryType AS EntityType,
           SUM(CASE WHEN DATEDIFF(DAY, je.EntryDate, @FechaCorte) BETWEEN 0  AND 30  THEN jel.CreditAmount - jel.DebitAmount ELSE 0 END) AS Current_0_30,
           SUM(CASE WHEN DATEDIFF(DAY, je.EntryDate, @FechaCorte) BETWEEN 31 AND 60  THEN jel.CreditAmount - jel.DebitAmount ELSE 0 END) AS Days_31_60,
           SUM(CASE WHEN DATEDIFF(DAY, je.EntryDate, @FechaCorte) BETWEEN 61 AND 90  THEN jel.CreditAmount - jel.DebitAmount ELSE 0 END) AS Days_61_90,
           SUM(CASE WHEN DATEDIFF(DAY, je.EntryDate, @FechaCorte) > 90               THEN jel.CreditAmount - jel.DebitAmount ELSE 0 END) AS Days_90_Plus,
           SUM(jel.CreditAmount - jel.DebitAmount) AS Total
    FROM   acct.JournalEntryLine jel
    JOIN   acct.JournalEntry je ON je.JournalEntryId = jel.JournalEntryId
    JOIN   acct.Account a       ON a.AccountId       = jel.AccountId
    WHERE  je.CompanyId  = @CompanyId
      AND  je.EntryDate  <= @FechaCorte
      AND  je.Status     = 'APPROVED'
      AND  je.IsDeleted  = 0
      AND  a.IsDeleted   = 0
      AND  a.AccountCode LIKE '2.1%'
    GROUP BY jel.AuxiliaryCode, jel.AuxiliaryType
    HAVING SUM(jel.CreditAmount - jel.DebitAmount) <> 0
    ORDER BY Total DESC;
END;
GO

-- =============================================================================
--  SP 34: usp_Acct_Report_FinancialRatios
--  Descripcion : Calcula ratios financieros clave a una fecha de corte.
--                CurrentRatio, QuickRatio, DebtToEquity, GrossMargin,
--                NetMargin, WorkingCapital.
--  Parametros  :
--    @CompanyId   INT              - ID de la empresa.
--    @FechaCorte  DATE             - Fecha de corte.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Acct_Report_FinancialRatios
    @CompanyId   INT,
    @FechaCorte  DATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Acumular saldos por tipo de cuenta
    DECLARE @ActivoCorriente   DECIMAL(18,2) = 0;
    DECLARE @ActivoNoCorriente DECIMAL(18,2) = 0;
    DECLARE @PasivoCorriente   DECIMAL(18,2) = 0;
    DECLARE @PasivoNoCorriente DECIMAL(18,2) = 0;
    DECLARE @Patrimonio        DECIMAL(18,2) = 0;
    DECLARE @Ingresos          DECIMAL(18,2) = 0;
    DECLARE @CostoVentas       DECIMAL(18,2) = 0;
    DECLARE @Gastos            DECIMAL(18,2) = 0;
    DECLARE @Inventario        DECIMAL(18,2) = 0;

    SELECT
        @ActivoCorriente   = SUM(CASE WHEN a.AccountCode LIKE '1.1%' THEN jel.DebitAmount - jel.CreditAmount ELSE 0 END),
        @ActivoNoCorriente = SUM(CASE WHEN a.AccountCode LIKE '1.2%' THEN jel.DebitAmount - jel.CreditAmount ELSE 0 END),
        @PasivoCorriente   = SUM(CASE WHEN a.AccountCode LIKE '2.1%' THEN jel.CreditAmount - jel.DebitAmount ELSE 0 END),
        @PasivoNoCorriente = SUM(CASE WHEN a.AccountCode LIKE '2.2%' THEN jel.CreditAmount - jel.DebitAmount ELSE 0 END),
        @Patrimonio        = SUM(CASE WHEN a.AccountType = 'C'       THEN jel.CreditAmount - jel.DebitAmount ELSE 0 END),
        @Ingresos          = SUM(CASE WHEN a.AccountType = 'I'       THEN jel.CreditAmount - jel.DebitAmount ELSE 0 END),
        @CostoVentas       = SUM(CASE WHEN a.AccountCode LIKE '5.1%' THEN jel.DebitAmount - jel.CreditAmount ELSE 0 END),
        @Gastos            = SUM(CASE WHEN a.AccountType = 'G'       THEN jel.DebitAmount - jel.CreditAmount ELSE 0 END),
        @Inventario        = SUM(CASE WHEN a.AccountCode LIKE '1.1.3%' THEN jel.DebitAmount - jel.CreditAmount ELSE 0 END)
    FROM   acct.JournalEntryLine jel
    JOIN   acct.JournalEntry je ON je.JournalEntryId = jel.JournalEntryId
    JOIN   acct.Account a       ON a.AccountId       = jel.AccountId
    WHERE  je.CompanyId  = @CompanyId
      AND  je.EntryDate  <= @FechaCorte
      AND  je.Status     = 'APPROVED'
      AND  je.IsDeleted  = 0
      AND  a.IsDeleted   = 0;

    DECLARE @TotalPasivo DECIMAL(18,2) = ISNULL(@PasivoCorriente, 0) + ISNULL(@PasivoNoCorriente, 0);
    DECLARE @UtilidadBruta DECIMAL(18,2) = ISNULL(@Ingresos, 0) - ISNULL(@CostoVentas, 0);
    DECLARE @UtilidadNeta  DECIMAL(18,2) = ISNULL(@Ingresos, 0) - ISNULL(@Gastos, 0);

    SELECT N'CurrentRatio' AS RatioName,
           CASE WHEN ISNULL(@PasivoCorriente, 0) = 0 THEN 0
                ELSE ROUND(ISNULL(@ActivoCorriente, 0) / @PasivoCorriente, 4)
           END AS RatioValue,
           N'LIQUIDEZ' AS Category
    UNION ALL
    SELECT N'QuickRatio',
           CASE WHEN ISNULL(@PasivoCorriente, 0) = 0 THEN 0
                ELSE ROUND((ISNULL(@ActivoCorriente, 0) - ISNULL(@Inventario, 0)) / @PasivoCorriente, 4)
           END,
           N'LIQUIDEZ'
    UNION ALL
    SELECT N'DebtToEquity',
           CASE WHEN ISNULL(@Patrimonio, 0) = 0 THEN 0
                ELSE ROUND(@TotalPasivo / @Patrimonio, 4)
           END,
           N'APALANCAMIENTO'
    UNION ALL
    SELECT N'GrossMargin',
           CASE WHEN ISNULL(@Ingresos, 0) = 0 THEN 0
                ELSE ROUND(@UtilidadBruta / @Ingresos * 100, 2)
           END,
           N'RENTABILIDAD'
    UNION ALL
    SELECT N'NetMargin',
           CASE WHEN ISNULL(@Ingresos, 0) = 0 THEN 0
                ELSE ROUND(@UtilidadNeta / @Ingresos * 100, 2)
           END,
           N'RENTABILIDAD'
    UNION ALL
    SELECT N'WorkingCapital',
           ISNULL(@ActivoCorriente, 0) - ISNULL(@PasivoCorriente, 0),
           N'LIQUIDEZ';
END;
GO

-- =============================================================================
--  SP 35: usp_Acct_Report_TaxSummary
--  Descripcion : Resumen de impuestos por tipo, agrupando cuentas de impuestos.
--  Parametros  :
--    @CompanyId   INT              - ID de la empresa.
--    @FechaDesde  DATE             - Fecha inicio.
--    @FechaHasta  DATE             - Fecha fin.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Acct_Report_TaxSummary
    @CompanyId   INT,
    @FechaDesde  DATE,
    @FechaHasta  DATE
AS
BEGIN
    SET NOCOUNT ON;

    SELECT a.AccountCode AS TaxAccountCode,
           a.AccountName AS TaxType,
           SUM(jel.DebitAmount)  AS DebitTotal,
           SUM(jel.CreditAmount) AS CreditTotal,
           SUM(jel.CreditAmount - jel.DebitAmount) AS TaxAmount,
           -- Estimar base imponible (asumiendo IVA en la misma entrada)
           (SELECT SUM(jel2.DebitAmount - jel2.CreditAmount)
            FROM   acct.JournalEntryLine jel2
            JOIN   acct.Account a2 ON a2.AccountId = jel2.AccountId
            WHERE  jel2.JournalEntryId IN (
                SELECT DISTINCT jel3.JournalEntryId
                FROM   acct.JournalEntryLine jel3
                WHERE  jel3.AccountId = a.AccountId
                  AND  jel3.JournalEntryId = jel.JournalEntryId
            )
              AND  a2.AccountCode NOT LIKE '2.4%'
              AND  a2.AccountType IN ('G', 'A')
           ) AS BaseAmount,
           SUM(jel.CreditAmount - jel.DebitAmount)
           + ISNULL((SELECT SUM(jel2.DebitAmount - jel2.CreditAmount)
                     FROM   acct.JournalEntryLine jel2
                     JOIN   acct.Account a2 ON a2.AccountId = jel2.AccountId
                     WHERE  jel2.JournalEntryId IN (
                         SELECT DISTINCT jel3.JournalEntryId
                         FROM   acct.JournalEntryLine jel3
                         WHERE  jel3.AccountId = a.AccountId
                     )
                       AND  a2.AccountCode NOT LIKE '2.4%'
                       AND  a2.AccountType IN ('G', 'A')
           ), 0) AS TotalAmount
    FROM   acct.JournalEntryLine jel
    JOIN   acct.JournalEntry je ON je.JournalEntryId = jel.JournalEntryId
    JOIN   acct.Account a       ON a.AccountId       = jel.AccountId
    WHERE  je.CompanyId  = @CompanyId
      AND  je.EntryDate  >= @FechaDesde
      AND  je.EntryDate  <= @FechaHasta
      AND  je.Status     = 'APPROVED'
      AND  je.IsDeleted  = 0
      AND  a.IsDeleted   = 0
      AND  a.AccountCode LIKE '2.4%'
    GROUP BY a.AccountId, a.AccountCode, a.AccountName, jel.JournalEntryId
    ORDER BY a.AccountCode;
END;
GO

-- =============================================================================
--  SP 36: usp_Acct_Report_DrillDown
--  Descripcion : Detalle de movimientos de una cuenta con informacion completa
--                del asiento y saldo acumulado.
--  Parametros  :
--    @CompanyId    INT              - ID de la empresa.
--    @AccountCode  NVARCHAR(20)     - Codigo de la cuenta.
--    @FechaDesde   DATE             - Fecha inicio.
--    @FechaHasta   DATE             - Fecha fin.
--    @Page         INT              - Numero de pagina (default 1).
--    @Limit        INT              - Registros por pagina (default 50).
--    @TotalCount   INT OUTPUT       - Total de registros.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Acct_Report_DrillDown
    @CompanyId    INT,
    @AccountCode  NVARCHAR(20),
    @FechaDesde   DATE,
    @FechaHasta   DATE,
    @Page         INT           = 1,
    @Limit        INT           = 50,
    @TotalCount   INT           OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    IF @Page  < 1   SET @Page  = 1;
    IF @Limit < 1   SET @Limit = 50;
    IF @Limit > 500 SET @Limit = 500;

    -- Obtener AccountId
    DECLARE @AccountId BIGINT;
    SELECT TOP 1 @AccountId = AccountId
    FROM   acct.Account
    WHERE  CompanyId = @CompanyId AND AccountCode = @AccountCode AND IsDeleted = 0;

    IF @AccountId IS NULL
    BEGIN
        SET @TotalCount = 0;
        RETURN;
    END;

    -- Contar total
    SELECT @TotalCount = COUNT(*)
    FROM   acct.JournalEntryLine jel
    JOIN   acct.JournalEntry je ON je.JournalEntryId = jel.JournalEntryId
    WHERE  jel.AccountId = @AccountId
      AND  je.CompanyId  = @CompanyId
      AND  je.EntryDate  >= @FechaDesde
      AND  je.EntryDate  <= @FechaHasta
      AND  je.Status     = 'APPROVED'
      AND  je.IsDeleted  = 0;

    -- Saldo anterior al rango
    DECLARE @SaldoAnterior DECIMAL(18,2) = 0;
    SELECT @SaldoAnterior = ISNULL(SUM(jel.DebitAmount - jel.CreditAmount), 0)
    FROM   acct.JournalEntryLine jel
    JOIN   acct.JournalEntry je ON je.JournalEntryId = jel.JournalEntryId
    WHERE  jel.AccountId = @AccountId
      AND  je.CompanyId  = @CompanyId
      AND  je.EntryDate  < @FechaDesde
      AND  je.Status     = 'APPROVED'
      AND  je.IsDeleted  = 0;

    -- Detalle con running balance
    SELECT je.JournalEntryId AS EntryId,
           je.EntryDate,
           je.EntryNumber,
           je.EntryType,
           je.Concept,
           je.Status,
           jel.Description AS LineDescription,
           jel.DebitAmount  AS Debit,
           jel.CreditAmount AS Credit,
           jel.CostCenterCode,
           @SaldoAnterior + SUM(jel.DebitAmount - jel.CreditAmount)
               OVER (ORDER BY je.EntryDate, je.JournalEntryId, jel.LineNumber
                     ROWS UNBOUNDED PRECEDING) AS RunningBalance
    FROM   acct.JournalEntryLine jel
    JOIN   acct.JournalEntry je ON je.JournalEntryId = jel.JournalEntryId
    WHERE  jel.AccountId = @AccountId
      AND  je.CompanyId  = @CompanyId
      AND  je.EntryDate  >= @FechaDesde
      AND  je.EntryDate  <= @FechaHasta
      AND  je.Status     = 'APPROVED'
      AND  je.IsDeleted  = 0
    ORDER BY je.EntryDate, je.JournalEntryId, jel.LineNumber
    OFFSET (@Page - 1) * @Limit ROWS
    FETCH NEXT @Limit ROWS ONLY;
END;
GO

PRINT N'[usp_acct_advanced] Todos los procedimientos creados exitosamente (36 SPs).';
GO
