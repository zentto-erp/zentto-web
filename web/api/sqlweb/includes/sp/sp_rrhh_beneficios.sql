-- =============================================
-- Stored Procedures: Beneficios Laborales (LOTTT Venezuela)
-- 1. Utilidades (Profit Sharing) - Art. 131-140
-- 2. Fideicomiso / Prestaciones Sociales (Social Benefits Trust) - Art. 141-143
-- 3. Caja de Ahorro (Savings Fund)
-- Compatible con: SQL Server 2012+
-- Fechas: UTC via SYSUTCDATETIME()
-- =============================================

USE [DatqBoxWeb];
GO

-- =============================================================
-- SCHEMA: hr (ensure exists)
-- =============================================================
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'hr')
    EXEC('CREATE SCHEMA hr');
GO

-- =============================================================
-- TABLES
-- =============================================================

-- ----- 1. hr.ProfitSharing -----
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID('hr.ProfitSharing'))
BEGIN
    CREATE TABLE hr.ProfitSharing (
        ProfitSharingId     INT IDENTITY(1,1) PRIMARY KEY,
        CompanyId           INT NOT NULL,
        BranchId            INT NOT NULL,
        FiscalYear          INT NOT NULL,
        DaysGranted         INT NOT NULL,
        TotalCompanyProfits DECIMAL(18,2) NULL,
        Status              NVARCHAR(20) NOT NULL DEFAULT 'BORRADOR',
        CreatedBy           INT NULL,
        CreatedAt           DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
        ApprovedBy          INT NULL,
        ApprovedAt          DATETIME2(0) NULL,
        UpdatedAt           DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
        CONSTRAINT CK_ProfitSharing_Days CHECK (DaysGranted BETWEEN 30 AND 120),
        CONSTRAINT CK_ProfitSharing_Status CHECK (Status IN ('BORRADOR','CALCULADA','PROCESADA','CERRADA'))
    );

    CREATE UNIQUE INDEX UX_ProfitSharing_Company_Year
        ON hr.ProfitSharing (CompanyId, BranchId, FiscalYear)
        WHERE Status <> 'BORRADOR';

    CREATE INDEX IX_ProfitSharing_Status ON hr.ProfitSharing (Status);
END
GO

-- ----- 2. hr.ProfitSharingLine -----
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID('hr.ProfitSharingLine'))
BEGIN
    CREATE TABLE hr.ProfitSharingLine (
        LineId          INT IDENTITY(1,1) PRIMARY KEY,
        ProfitSharingId INT NOT NULL,
        EmployeeId      BIGINT NULL,
        EmployeeCode    NVARCHAR(24) NOT NULL,
        EmployeeName    NVARCHAR(200) NOT NULL,
        MonthlySalary   DECIMAL(18,2) NOT NULL,
        DailySalary     DECIMAL(18,2) NOT NULL,
        DaysWorked      INT NOT NULL,
        DaysEntitled    INT NOT NULL,
        GrossAmount     DECIMAL(18,2) NOT NULL,
        InceDeduction   DECIMAL(18,2) NOT NULL DEFAULT 0,
        NetAmount       DECIMAL(18,2) NOT NULL,
        IsPaid          BIT NOT NULL DEFAULT 0,
        PaidAt          DATETIME2(0) NULL,
        CONSTRAINT FK_ProfitSharingLine_Header
            FOREIGN KEY (ProfitSharingId) REFERENCES hr.ProfitSharing(ProfitSharingId)
    );

    CREATE INDEX IX_ProfitSharingLine_Header ON hr.ProfitSharingLine (ProfitSharingId);
    CREATE INDEX IX_ProfitSharingLine_Employee ON hr.ProfitSharingLine (EmployeeCode);
END
GO

-- ----- 3. hr.SocialBenefitsTrust -----
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID('hr.SocialBenefitsTrust'))
BEGIN
    CREATE TABLE hr.SocialBenefitsTrust (
        TrustId             INT IDENTITY(1,1) PRIMARY KEY,
        CompanyId           INT NOT NULL,
        EmployeeId          BIGINT NULL,
        EmployeeCode        NVARCHAR(24) NOT NULL,
        EmployeeName        NVARCHAR(200) NOT NULL,
        FiscalYear          INT NOT NULL,
        Quarter             TINYINT NOT NULL,
        DailySalary         DECIMAL(18,2) NOT NULL,
        DaysDeposited       INT NOT NULL DEFAULT 15,
        BonusDays           INT NOT NULL DEFAULT 0,
        DepositAmount       DECIMAL(18,2) NOT NULL,
        InterestRate        DECIMAL(8,5) NOT NULL DEFAULT 0,
        InterestAmount      DECIMAL(18,2) NOT NULL DEFAULT 0,
        AccumulatedBalance  DECIMAL(18,2) NOT NULL,
        Status              NVARCHAR(20) NOT NULL DEFAULT 'PENDIENTE',
        CreatedAt           DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
        UpdatedAt           DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
        CONSTRAINT CK_Trust_Quarter CHECK (Quarter BETWEEN 1 AND 4),
        CONSTRAINT CK_Trust_Status CHECK (Status IN ('PENDIENTE','DEPOSITADO','PAGADO'))
    );

    CREATE INDEX IX_Trust_Company_Year ON hr.SocialBenefitsTrust (CompanyId, FiscalYear, Quarter);
    CREATE INDEX IX_Trust_Employee ON hr.SocialBenefitsTrust (EmployeeCode, FiscalYear);
    CREATE UNIQUE INDEX UX_Trust_Employee_Quarter
        ON hr.SocialBenefitsTrust (CompanyId, EmployeeCode, FiscalYear, Quarter);
END
GO

-- ----- 4. hr.SavingsFund -----
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID('hr.SavingsFund'))
BEGIN
    CREATE TABLE hr.SavingsFund (
        SavingsFundId         INT IDENTITY(1,1) PRIMARY KEY,
        CompanyId             INT NOT NULL,
        EmployeeId            BIGINT NULL,
        EmployeeCode          NVARCHAR(24) NOT NULL,
        EmployeeName          NVARCHAR(200) NOT NULL,
        EmployeeContribution  DECIMAL(8,4) NOT NULL,
        EmployerMatch         DECIMAL(8,4) NOT NULL,
        EnrollmentDate        DATE NOT NULL,
        Status                NVARCHAR(15) NOT NULL DEFAULT 'ACTIVO',
        CreatedAt             DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
        CONSTRAINT CK_SavingsFund_Status CHECK (Status IN ('ACTIVO','SUSPENDIDO','RETIRADO'))
    );

    CREATE UNIQUE INDEX UX_SavingsFund_Employee ON hr.SavingsFund (CompanyId, EmployeeCode);
    CREATE INDEX IX_SavingsFund_Status ON hr.SavingsFund (CompanyId, Status);
END
GO

-- ----- 5. hr.SavingsFundTransaction -----
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID('hr.SavingsFundTransaction'))
BEGIN
    CREATE TABLE hr.SavingsFundTransaction (
        TransactionId   INT IDENTITY(1,1) PRIMARY KEY,
        SavingsFundId   INT NOT NULL,
        TransactionDate DATE NOT NULL,
        TransactionType NVARCHAR(20) NOT NULL,
        Amount          DECIMAL(18,2) NOT NULL,
        Balance         DECIMAL(18,2) NOT NULL,
        Reference       NVARCHAR(100) NULL,
        PayrollBatchId  INT NULL,
        Notes           NVARCHAR(500) NULL,
        CreatedAt       DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
        CONSTRAINT FK_SavingsTx_Fund
            FOREIGN KEY (SavingsFundId) REFERENCES hr.SavingsFund(SavingsFundId),
        CONSTRAINT CK_SavingsTx_Type CHECK (TransactionType IN (
            'APORTE_EMPLEADO','APORTE_PATRONAL','RETIRO','PRESTAMO','PAGO_PRESTAMO','INTERES'
        ))
    );

    CREATE INDEX IX_SavingsTx_Fund ON hr.SavingsFundTransaction (SavingsFundId, TransactionDate);
    CREATE INDEX IX_SavingsTx_Type ON hr.SavingsFundTransaction (TransactionType);
END
GO

-- ----- 6. hr.SavingsLoan -----
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID('hr.SavingsLoan'))
BEGIN
    CREATE TABLE hr.SavingsLoan (
        LoanId              INT IDENTITY(1,1) PRIMARY KEY,
        SavingsFundId       INT NOT NULL,
        EmployeeCode        NVARCHAR(24) NOT NULL,
        RequestDate         DATE NOT NULL,
        ApprovedDate        DATE NULL,
        LoanAmount          DECIMAL(18,2) NOT NULL,
        InterestRate        DECIMAL(8,5) NOT NULL DEFAULT 0,
        TotalPayable        DECIMAL(18,2) NOT NULL,
        MonthlyPayment      DECIMAL(18,2) NOT NULL,
        InstallmentsTotal   INT NOT NULL,
        InstallmentsPaid    INT NOT NULL DEFAULT 0,
        OutstandingBalance  DECIMAL(18,2) NOT NULL,
        Status              NVARCHAR(15) NOT NULL DEFAULT 'SOLICITADO',
        ApprovedBy          INT NULL,
        Notes               NVARCHAR(500) NULL,
        CreatedAt           DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
        UpdatedAt           DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
        CONSTRAINT FK_SavingsLoan_Fund
            FOREIGN KEY (SavingsFundId) REFERENCES hr.SavingsFund(SavingsFundId),
        CONSTRAINT CK_SavingsLoan_Status CHECK (Status IN ('SOLICITADO','APROBADO','ACTIVO','PAGADO','RECHAZADO'))
    );

    CREATE INDEX IX_SavingsLoan_Fund ON hr.SavingsLoan (SavingsFundId);
    CREATE INDEX IX_SavingsLoan_Employee ON hr.SavingsLoan (EmployeeCode);
    CREATE INDEX IX_SavingsLoan_Status ON hr.SavingsLoan (Status);
END
GO

-- =============================================================
-- STORED PROCEDURES: UTILIDADES (Profit Sharing)
-- =============================================================

-- =============================================================
-- 1) usp_HR_ProfitSharing_Generate
-- =============================================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_HR_ProfitSharing_Generate')
    DROP PROCEDURE usp_HR_ProfitSharing_Generate
GO

CREATE PROCEDURE usp_HR_ProfitSharing_Generate
    @CompanyId          INT,
    @BranchId           INT,
    @FiscalYear         INT,
    @DaysGranted        INT,
    @TotalCompanyProfits DECIMAL(18,2) = NULL,
    @CreatedBy          INT = NULL,
    @Resultado          INT OUTPUT,
    @Mensaje            NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Resultado = 0;
    SET @Mensaje = '';

    -- Validar rango de dias
    IF @DaysGranted < 30 OR @DaysGranted > 120
    BEGIN
        SET @Resultado = -1;
        SET @Mensaje = 'Los dias otorgados deben estar entre 30 y 120 (LOTTT Art. 131).';
        RETURN;
    END

    -- Validar que no exista uno ya calculado/procesado para el mismo ano
    IF EXISTS (
        SELECT 1 FROM hr.ProfitSharing
        WHERE CompanyId = @CompanyId AND BranchId = @BranchId AND FiscalYear = @FiscalYear
          AND Status IN ('CALCULADA','PROCESADA','CERRADA')
    )
    BEGIN
        SET @Resultado = -2;
        SET @Mensaje = 'Ya existe un calculo de utilidades procesado para este ano fiscal.';
        RETURN;
    END

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Eliminar borrador previo si existe
        DECLARE @OldId INT;
        SELECT @OldId = ProfitSharingId FROM hr.ProfitSharing
        WHERE CompanyId = @CompanyId AND BranchId = @BranchId AND FiscalYear = @FiscalYear
          AND Status = 'BORRADOR';

        IF @OldId IS NOT NULL
        BEGIN
            DELETE FROM hr.ProfitSharingLine WHERE ProfitSharingId = @OldId;
            DELETE FROM hr.ProfitSharing WHERE ProfitSharingId = @OldId;
        END

        -- Crear cabecera
        INSERT INTO hr.ProfitSharing (CompanyId, BranchId, FiscalYear, DaysGranted, TotalCompanyProfits, Status, CreatedBy)
        VALUES (@CompanyId, @BranchId, @FiscalYear, @DaysGranted, @TotalCompanyProfits, 'CALCULADA', @CreatedBy);

        DECLARE @ProfitSharingId INT = SCOPE_IDENTITY();

        -- Fecha inicio y fin del ano fiscal
        DECLARE @YearStart DATE = CAST(CAST(@FiscalYear AS VARCHAR(4)) + '-01-01' AS DATE);
        DECLARE @YearEnd DATE   = CAST(CAST(@FiscalYear AS VARCHAR(4)) + '-12-31' AS DATE);
        DECLARE @TotalDaysInYear INT = DATEDIFF(DAY, @YearStart, @YearEnd) + 1;

        -- Calcular lineas por empleado activo
        INSERT INTO hr.ProfitSharingLine (
            ProfitSharingId, EmployeeId, EmployeeCode, EmployeeName,
            MonthlySalary, DailySalary, DaysWorked, DaysEntitled,
            GrossAmount, InceDeduction, NetAmount
        )
        SELECT
            @ProfitSharingId,
            e.EmployeeId,
            e.EmployeeCode,
            e.EmployeeName,
            e.MonthlySalary,
            ROUND(e.MonthlySalary / 30.0, 2) AS DailySalary,
            -- Dias trabajados: desde mayor(fecha ingreso, inicio ano) hasta menor(hoy, fin ano)
            DATEDIFF(DAY,
                CASE WHEN e.HireDate > @YearStart THEN e.HireDate ELSE @YearStart END,
                CASE WHEN e.TerminationDate IS NOT NULL AND e.TerminationDate < @YearEnd
                     THEN e.TerminationDate ELSE @YearEnd END
            ) + 1 AS DaysWorked,
            -- Dias proporcionales = (DaysWorked / TotalDaysInYear) * DaysGranted
            ROUND(
                CAST(
                    (DATEDIFF(DAY,
                        CASE WHEN e.HireDate > @YearStart THEN e.HireDate ELSE @YearStart END,
                        CASE WHEN e.TerminationDate IS NOT NULL AND e.TerminationDate < @YearEnd
                             THEN e.TerminationDate ELSE @YearEnd END
                    ) + 1) AS DECIMAL(18,4)
                ) / CAST(@TotalDaysInYear AS DECIMAL(18,4)) * @DaysGranted
            , 2) AS DaysEntitled,
            -- GrossAmount = DailySalary * DaysEntitled
            ROUND(
                (e.MonthlySalary / 30.0) *
                ROUND(
                    CAST(
                        (DATEDIFF(DAY,
                            CASE WHEN e.HireDate > @YearStart THEN e.HireDate ELSE @YearStart END,
                            CASE WHEN e.TerminationDate IS NOT NULL AND e.TerminationDate < @YearEnd
                                 THEN e.TerminationDate ELSE @YearEnd END
                        ) + 1) AS DECIMAL(18,4)
                    ) / CAST(@TotalDaysInYear AS DECIMAL(18,4)) * @DaysGranted
                , 2)
            , 2) AS GrossAmount,
            -- INCE: 0.5% del monto bruto
            ROUND(
                (e.MonthlySalary / 30.0) *
                ROUND(
                    CAST(
                        (DATEDIFF(DAY,
                            CASE WHEN e.HireDate > @YearStart THEN e.HireDate ELSE @YearStart END,
                            CASE WHEN e.TerminationDate IS NOT NULL AND e.TerminationDate < @YearEnd
                                 THEN e.TerminationDate ELSE @YearEnd END
                        ) + 1) AS DECIMAL(18,4)
                    ) / CAST(@TotalDaysInYear AS DECIMAL(18,4)) * @DaysGranted
                , 2) * 0.005
            , 2) AS InceDeduction,
            -- NetAmount = GrossAmount - InceDeduction
            ROUND(
                (e.MonthlySalary / 30.0) *
                ROUND(
                    CAST(
                        (DATEDIFF(DAY,
                            CASE WHEN e.HireDate > @YearStart THEN e.HireDate ELSE @YearStart END,
                            CASE WHEN e.TerminationDate IS NOT NULL AND e.TerminationDate < @YearEnd
                                 THEN e.TerminationDate ELSE @YearEnd END
                        ) + 1) AS DECIMAL(18,4)
                    ) / CAST(@TotalDaysInYear AS DECIMAL(18,4)) * @DaysGranted
                , 2)
            , 2)
            -
            ROUND(
                (e.MonthlySalary / 30.0) *
                ROUND(
                    CAST(
                        (DATEDIFF(DAY,
                            CASE WHEN e.HireDate > @YearStart THEN e.HireDate ELSE @YearStart END,
                            CASE WHEN e.TerminationDate IS NOT NULL AND e.TerminationDate < @YearEnd
                                 THEN e.TerminationDate ELSE @YearEnd END
                        ) + 1) AS DECIMAL(18,4)
                    ) / CAST(@TotalDaysInYear AS DECIMAL(18,4)) * @DaysGranted
                , 2) * 0.005
            , 2) AS NetAmount
        FROM master.Employee e
        WHERE e.CompanyId = @CompanyId
          AND e.BranchId = @BranchId
          AND e.Status = 'ACTIVO'
          AND e.HireDate <= @YearEnd
          AND (e.TerminationDate IS NULL OR e.TerminationDate >= @YearStart);

        COMMIT TRANSACTION;

        SET @Resultado = @ProfitSharingId;
        SET @Mensaje = 'Utilidades generadas exitosamente.';

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SET @Resultado = -99;
        SET @Mensaje = ERROR_MESSAGE();
    END CATCH
END
GO

-- =============================================================
-- 2) usp_HR_ProfitSharing_GetSummary
-- =============================================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_HR_ProfitSharing_GetSummary')
    DROP PROCEDURE usp_HR_ProfitSharing_GetSummary
GO

CREATE PROCEDURE usp_HR_ProfitSharing_GetSummary
    @ProfitSharingId INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Cabecera
    SELECT
        ps.ProfitSharingId,
        ps.CompanyId,
        ps.BranchId,
        ps.FiscalYear,
        ps.DaysGranted,
        ps.TotalCompanyProfits,
        ps.Status,
        ps.CreatedBy,
        ps.CreatedAt,
        ps.ApprovedBy,
        ps.ApprovedAt,
        ps.UpdatedAt,
        (SELECT COUNT(*) FROM hr.ProfitSharingLine WHERE ProfitSharingId = ps.ProfitSharingId) AS TotalEmployees,
        (SELECT ISNULL(SUM(GrossAmount), 0) FROM hr.ProfitSharingLine WHERE ProfitSharingId = ps.ProfitSharingId) AS TotalGross,
        (SELECT ISNULL(SUM(InceDeduction), 0) FROM hr.ProfitSharingLine WHERE ProfitSharingId = ps.ProfitSharingId) AS TotalInce,
        (SELECT ISNULL(SUM(NetAmount), 0) FROM hr.ProfitSharingLine WHERE ProfitSharingId = ps.ProfitSharingId) AS TotalNet
    FROM hr.ProfitSharing ps
    WHERE ps.ProfitSharingId = @ProfitSharingId;

    -- Lineas de detalle
    SELECT
        l.LineId,
        l.EmployeeId,
        l.EmployeeCode,
        l.EmployeeName,
        l.MonthlySalary,
        l.DailySalary,
        l.DaysWorked,
        l.DaysEntitled,
        l.GrossAmount,
        l.InceDeduction,
        l.NetAmount,
        l.IsPaid,
        l.PaidAt
    FROM hr.ProfitSharingLine l
    WHERE l.ProfitSharingId = @ProfitSharingId
    ORDER BY l.EmployeeName;
END
GO

-- =============================================================
-- 3) usp_HR_ProfitSharing_Approve
-- =============================================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_HR_ProfitSharing_Approve')
    DROP PROCEDURE usp_HR_ProfitSharing_Approve
GO

CREATE PROCEDURE usp_HR_ProfitSharing_Approve
    @ProfitSharingId    INT,
    @ApprovedBy         INT,
    @Resultado          INT OUTPUT,
    @Mensaje            NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Resultado = 0;
    SET @Mensaje = '';

    DECLARE @CurrentStatus NVARCHAR(20);
    SELECT @CurrentStatus = Status FROM hr.ProfitSharing WHERE ProfitSharingId = @ProfitSharingId;

    IF @CurrentStatus IS NULL
    BEGIN
        SET @Resultado = -1;
        SET @Mensaje = 'Registro de utilidades no encontrado.';
        RETURN;
    END

    IF @CurrentStatus <> 'CALCULADA'
    BEGIN
        SET @Resultado = -2;
        SET @Mensaje = 'Solo se pueden aprobar utilidades en estado CALCULADA. Estado actual: ' + @CurrentStatus;
        RETURN;
    END

    UPDATE hr.ProfitSharing
    SET Status     = 'PROCESADA',
        ApprovedBy = @ApprovedBy,
        ApprovedAt = SYSUTCDATETIME(),
        UpdatedAt  = SYSUTCDATETIME()
    WHERE ProfitSharingId = @ProfitSharingId;

    SET @Resultado = @ProfitSharingId;
    SET @Mensaje = 'Utilidades aprobadas exitosamente.';
END
GO

-- =============================================================
-- 4) usp_HR_ProfitSharing_List
-- =============================================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_HR_ProfitSharing_List')
    DROP PROCEDURE usp_HR_ProfitSharing_List
GO

CREATE PROCEDURE usp_HR_ProfitSharing_List
    @CompanyId   INT,
    @BranchId    INT = NULL,
    @FiscalYear  INT = NULL,
    @Status      NVARCHAR(20) = NULL,
    @Offset      INT = 0,
    @Limit       INT = 50,
    @TotalCount  INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT @TotalCount = COUNT(*)
    FROM hr.ProfitSharing ps
    WHERE ps.CompanyId = @CompanyId
      AND (@BranchId IS NULL OR ps.BranchId = @BranchId)
      AND (@FiscalYear IS NULL OR ps.FiscalYear = @FiscalYear)
      AND (@Status IS NULL OR ps.Status = @Status);

    SELECT
        ps.ProfitSharingId,
        ps.CompanyId,
        ps.BranchId,
        ps.FiscalYear,
        ps.DaysGranted,
        ps.TotalCompanyProfits,
        ps.Status,
        ps.CreatedBy,
        ps.CreatedAt,
        ps.ApprovedBy,
        ps.ApprovedAt,
        ps.UpdatedAt,
        (SELECT COUNT(*) FROM hr.ProfitSharingLine WHERE ProfitSharingId = ps.ProfitSharingId) AS TotalEmployees,
        (SELECT ISNULL(SUM(NetAmount), 0) FROM hr.ProfitSharingLine WHERE ProfitSharingId = ps.ProfitSharingId) AS TotalNet
    FROM hr.ProfitSharing ps
    WHERE ps.CompanyId = @CompanyId
      AND (@BranchId IS NULL OR ps.BranchId = @BranchId)
      AND (@FiscalYear IS NULL OR ps.FiscalYear = @FiscalYear)
      AND (@Status IS NULL OR ps.Status = @Status)
    ORDER BY ps.FiscalYear DESC, ps.CreatedAt DESC
    OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;
END
GO

-- =============================================================
-- STORED PROCEDURES: FIDEICOMISO / PRESTACIONES SOCIALES
-- =============================================================

-- =============================================================
-- 5) usp_HR_Trust_CalculateQuarter
-- =============================================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_HR_Trust_CalculateQuarter')
    DROP PROCEDURE usp_HR_Trust_CalculateQuarter
GO

CREATE PROCEDURE usp_HR_Trust_CalculateQuarter
    @CompanyId      INT,
    @FiscalYear     INT,
    @Quarter        TINYINT,
    @InterestRate   DECIMAL(8,5) = 0,
    @Resultado      INT OUTPUT,
    @Mensaje        NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Resultado = 0;
    SET @Mensaje = '';

    IF @Quarter < 1 OR @Quarter > 4
    BEGIN
        SET @Resultado = -1;
        SET @Mensaje = 'El trimestre debe estar entre 1 y 4.';
        RETURN;
    END

    -- Verificar que no exista calculo previo para este trimestre
    IF EXISTS (
        SELECT 1 FROM hr.SocialBenefitsTrust
        WHERE CompanyId = @CompanyId AND FiscalYear = @FiscalYear AND Quarter = @Quarter
    )
    BEGIN
        SET @Resultado = -2;
        SET @Mensaje = 'Ya existe un calculo para el trimestre ' + CAST(@Quarter AS VARCHAR(1)) + ' del ano ' + CAST(@FiscalYear AS VARCHAR(4)) + '.';
        RETURN;
    END

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Para cada empleado activo, calcular deposito trimestral
        -- LOTTT: 15 dias de salario por trimestre
        -- Despues del primer ano: 2 dias adicionales por ano (max 30 extra)
        INSERT INTO hr.SocialBenefitsTrust (
            CompanyId, EmployeeId, EmployeeCode, EmployeeName,
            FiscalYear, Quarter, DailySalary,
            DaysDeposited, BonusDays, DepositAmount,
            InterestRate, InterestAmount, AccumulatedBalance, Status
        )
        SELECT
            @CompanyId,
            e.EmployeeId,
            e.EmployeeCode,
            e.EmployeeName,
            @FiscalYear,
            @Quarter,
            ROUND(e.MonthlySalary / 30.0, 2) AS DailySalary,
            15 AS DaysDeposited,
            -- Bonus: 2 dias por cada ano despues del primero, max 30
            CASE
                WHEN @Quarter = 4 AND DATEDIFF(YEAR, e.HireDate, CAST(CAST(@FiscalYear AS VARCHAR(4)) + '-12-31' AS DATE)) > 1
                THEN CASE
                    WHEN (DATEDIFF(YEAR, e.HireDate, CAST(CAST(@FiscalYear AS VARCHAR(4)) + '-12-31' AS DATE)) - 1) * 2 > 30
                    THEN 30
                    ELSE (DATEDIFF(YEAR, e.HireDate, CAST(CAST(@FiscalYear AS VARCHAR(4)) + '-12-31' AS DATE)) - 1) * 2
                END
                ELSE 0
            END AS BonusDays,
            -- DepositAmount = DailySalary * (15 + BonusDays)
            ROUND(
                (e.MonthlySalary / 30.0) * (
                    15 +
                    CASE
                        WHEN @Quarter = 4 AND DATEDIFF(YEAR, e.HireDate, CAST(CAST(@FiscalYear AS VARCHAR(4)) + '-12-31' AS DATE)) > 1
                        THEN CASE
                            WHEN (DATEDIFF(YEAR, e.HireDate, CAST(CAST(@FiscalYear AS VARCHAR(4)) + '-12-31' AS DATE)) - 1) * 2 > 30
                            THEN 30
                            ELSE (DATEDIFF(YEAR, e.HireDate, CAST(CAST(@FiscalYear AS VARCHAR(4)) + '-12-31' AS DATE)) - 1) * 2
                        END
                        ELSE 0
                    END
                )
            , 2) AS DepositAmount,
            @InterestRate,
            -- InterestAmount = saldo acumulado anterior * tasa / 4
            ROUND(
                ISNULL((
                    SELECT TOP 1 t.AccumulatedBalance
                    FROM hr.SocialBenefitsTrust t
                    WHERE t.CompanyId = @CompanyId
                      AND t.EmployeeCode = e.EmployeeCode
                      AND (t.FiscalYear < @FiscalYear OR (t.FiscalYear = @FiscalYear AND t.Quarter < @Quarter))
                    ORDER BY t.FiscalYear DESC, t.Quarter DESC
                ), 0) * (@InterestRate / 100.0) / 4.0
            , 2) AS InterestAmount,
            -- AccumulatedBalance = saldo anterior + deposito + interes
            ISNULL((
                SELECT TOP 1 t.AccumulatedBalance
                FROM hr.SocialBenefitsTrust t
                WHERE t.CompanyId = @CompanyId
                  AND t.EmployeeCode = e.EmployeeCode
                  AND (t.FiscalYear < @FiscalYear OR (t.FiscalYear = @FiscalYear AND t.Quarter < @Quarter))
                ORDER BY t.FiscalYear DESC, t.Quarter DESC
            ), 0)
            +
            ROUND(
                (e.MonthlySalary / 30.0) * (
                    15 +
                    CASE
                        WHEN @Quarter = 4 AND DATEDIFF(YEAR, e.HireDate, CAST(CAST(@FiscalYear AS VARCHAR(4)) + '-12-31' AS DATE)) > 1
                        THEN CASE
                            WHEN (DATEDIFF(YEAR, e.HireDate, CAST(CAST(@FiscalYear AS VARCHAR(4)) + '-12-31' AS DATE)) - 1) * 2 > 30
                            THEN 30
                            ELSE (DATEDIFF(YEAR, e.HireDate, CAST(CAST(@FiscalYear AS VARCHAR(4)) + '-12-31' AS DATE)) - 1) * 2
                        END
                        ELSE 0
                    END
                )
            , 2)
            +
            ROUND(
                ISNULL((
                    SELECT TOP 1 t2.AccumulatedBalance
                    FROM hr.SocialBenefitsTrust t2
                    WHERE t2.CompanyId = @CompanyId
                      AND t2.EmployeeCode = e.EmployeeCode
                      AND (t2.FiscalYear < @FiscalYear OR (t2.FiscalYear = @FiscalYear AND t2.Quarter < @Quarter))
                    ORDER BY t2.FiscalYear DESC, t2.Quarter DESC
                ), 0) * (@InterestRate / 100.0) / 4.0
            , 2) AS AccumulatedBalance,
            'PENDIENTE'
        FROM master.Employee e
        WHERE e.CompanyId = @CompanyId
          AND e.Status = 'ACTIVO'
          AND e.HireDate <= CAST(CAST(@FiscalYear AS VARCHAR(4)) + '-' + RIGHT('0' + CAST(@Quarter * 3 AS VARCHAR(2)), 2) + '-28' AS DATE);

        DECLARE @Inserted INT = @@ROWCOUNT;

        COMMIT TRANSACTION;

        SET @Resultado = @Inserted;
        SET @Mensaje = 'Fideicomiso calculado para ' + CAST(@Inserted AS VARCHAR(10)) + ' empleados.';

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SET @Resultado = -99;
        SET @Mensaje = ERROR_MESSAGE();
    END CATCH
END
GO

-- =============================================================
-- 6) usp_HR_Trust_GetEmployeeBalance
-- =============================================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_HR_Trust_GetEmployeeBalance')
    DROP PROCEDURE usp_HR_Trust_GetEmployeeBalance
GO

CREATE PROCEDURE usp_HR_Trust_GetEmployeeBalance
    @CompanyId      INT,
    @EmployeeCode   NVARCHAR(24)
AS
BEGIN
    SET NOCOUNT ON;

    -- Saldo acumulado actual
    SELECT TOP 1
        t.EmployeeCode,
        t.EmployeeName,
        t.AccumulatedBalance AS CurrentBalance,
        t.FiscalYear AS LastFiscalYear,
        t.Quarter AS LastQuarter
    FROM hr.SocialBenefitsTrust t
    WHERE t.CompanyId = @CompanyId AND t.EmployeeCode = @EmployeeCode
    ORDER BY t.FiscalYear DESC, t.Quarter DESC;

    -- Historial completo
    SELECT
        t.TrustId,
        t.FiscalYear,
        t.Quarter,
        t.DailySalary,
        t.DaysDeposited,
        t.BonusDays,
        t.DepositAmount,
        t.InterestRate,
        t.InterestAmount,
        t.AccumulatedBalance,
        t.Status,
        t.CreatedAt
    FROM hr.SocialBenefitsTrust t
    WHERE t.CompanyId = @CompanyId AND t.EmployeeCode = @EmployeeCode
    ORDER BY t.FiscalYear, t.Quarter;
END
GO

-- =============================================================
-- 7) usp_HR_Trust_GetSummary
-- =============================================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_HR_Trust_GetSummary')
    DROP PROCEDURE usp_HR_Trust_GetSummary
GO

CREATE PROCEDURE usp_HR_Trust_GetSummary
    @CompanyId      INT,
    @FiscalYear     INT,
    @Quarter        TINYINT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        COUNT(*) AS TotalEmployees,
        SUM(t.DepositAmount) AS TotalDeposits,
        SUM(t.InterestAmount) AS TotalInterest,
        SUM(t.BonusDays) AS TotalBonusDays,
        SUM(t.AccumulatedBalance) AS TotalAccumulatedBalance,
        t.Status
    FROM hr.SocialBenefitsTrust t
    WHERE t.CompanyId = @CompanyId AND t.FiscalYear = @FiscalYear AND t.Quarter = @Quarter
    GROUP BY t.Status;

    -- Detalle por empleado
    SELECT
        t.TrustId,
        t.EmployeeCode,
        t.EmployeeName,
        t.DailySalary,
        t.DaysDeposited,
        t.BonusDays,
        t.DepositAmount,
        t.InterestRate,
        t.InterestAmount,
        t.AccumulatedBalance,
        t.Status
    FROM hr.SocialBenefitsTrust t
    WHERE t.CompanyId = @CompanyId AND t.FiscalYear = @FiscalYear AND t.Quarter = @Quarter
    ORDER BY t.EmployeeName;
END
GO

-- =============================================================
-- 8) usp_HR_Trust_List
-- =============================================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_HR_Trust_List')
    DROP PROCEDURE usp_HR_Trust_List
GO

CREATE PROCEDURE usp_HR_Trust_List
    @CompanyId      INT,
    @FiscalYear     INT = NULL,
    @Quarter        TINYINT = NULL,
    @EmployeeCode   NVARCHAR(24) = NULL,
    @Status         NVARCHAR(20) = NULL,
    @Offset         INT = 0,
    @Limit          INT = 50,
    @TotalCount     INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT @TotalCount = COUNT(*)
    FROM hr.SocialBenefitsTrust t
    WHERE t.CompanyId = @CompanyId
      AND (@FiscalYear IS NULL OR t.FiscalYear = @FiscalYear)
      AND (@Quarter IS NULL OR t.Quarter = @Quarter)
      AND (@EmployeeCode IS NULL OR t.EmployeeCode = @EmployeeCode)
      AND (@Status IS NULL OR t.Status = @Status);

    SELECT
        t.TrustId,
        t.EmployeeId,
        t.EmployeeCode,
        t.EmployeeName,
        t.FiscalYear,
        t.Quarter,
        t.DailySalary,
        t.DaysDeposited,
        t.BonusDays,
        t.DepositAmount,
        t.InterestRate,
        t.InterestAmount,
        t.AccumulatedBalance,
        t.Status,
        t.CreatedAt
    FROM hr.SocialBenefitsTrust t
    WHERE t.CompanyId = @CompanyId
      AND (@FiscalYear IS NULL OR t.FiscalYear = @FiscalYear)
      AND (@Quarter IS NULL OR t.Quarter = @Quarter)
      AND (@EmployeeCode IS NULL OR t.EmployeeCode = @EmployeeCode)
      AND (@Status IS NULL OR t.Status = @Status)
    ORDER BY t.FiscalYear DESC, t.Quarter DESC, t.EmployeeName
    OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;
END
GO

-- =============================================================
-- STORED PROCEDURES: CAJA DE AHORRO (Savings Fund)
-- =============================================================

-- =============================================================
-- 9) usp_HR_Savings_Enroll
-- =============================================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_HR_Savings_Enroll')
    DROP PROCEDURE usp_HR_Savings_Enroll
GO

CREATE PROCEDURE usp_HR_Savings_Enroll
    @CompanyId              INT,
    @EmployeeId             BIGINT = NULL,
    @EmployeeCode           NVARCHAR(24),
    @EmployeeName           NVARCHAR(200),
    @EmployeeContribution   DECIMAL(8,4),
    @EmployerMatch          DECIMAL(8,4),
    @EnrollmentDate         DATE,
    @Resultado              INT OUTPUT,
    @Mensaje                NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Resultado = 0;
    SET @Mensaje = '';

    -- Validar que no exista inscripcion activa
    IF EXISTS (
        SELECT 1 FROM hr.SavingsFund
        WHERE CompanyId = @CompanyId AND EmployeeCode = @EmployeeCode AND Status = 'ACTIVO'
    )
    BEGIN
        SET @Resultado = -1;
        SET @Mensaje = 'El empleado ya esta inscrito en la caja de ahorro.';
        RETURN;
    END

    -- Validar porcentajes
    IF @EmployeeContribution <= 0 OR @EmployerMatch < 0
    BEGIN
        SET @Resultado = -2;
        SET @Mensaje = 'El porcentaje de aporte del empleado debe ser mayor a cero.';
        RETURN;
    END

    BEGIN TRY
        INSERT INTO hr.SavingsFund (
            CompanyId, EmployeeId, EmployeeCode, EmployeeName,
            EmployeeContribution, EmployerMatch, EnrollmentDate, Status
        )
        VALUES (
            @CompanyId, @EmployeeId, @EmployeeCode, @EmployeeName,
            @EmployeeContribution, @EmployerMatch, @EnrollmentDate, 'ACTIVO'
        );

        SET @Resultado = SCOPE_IDENTITY();
        SET @Mensaje = 'Empleado inscrito en caja de ahorro exitosamente.';

    END TRY
    BEGIN CATCH
        SET @Resultado = -99;
        SET @Mensaje = ERROR_MESSAGE();
    END CATCH
END
GO

-- =============================================================
-- 10) usp_HR_Savings_ProcessMonthly
-- =============================================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_HR_Savings_ProcessMonthly')
    DROP PROCEDURE usp_HR_Savings_ProcessMonthly
GO

CREATE PROCEDURE usp_HR_Savings_ProcessMonthly
    @CompanyId      INT,
    @ProcessDate    DATE,
    @PayrollBatchId INT = NULL,
    @Resultado      INT OUTPUT,
    @Mensaje        NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Resultado = 0;
    SET @Mensaje = '';

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @Processed INT = 0;

        -- Cursor para cada miembro activo
        DECLARE @FundId INT, @EmpCode NVARCHAR(24), @EmpContrib DECIMAL(8,4), @MatchPct DECIMAL(8,4);
        DECLARE @Salary DECIMAL(18,2), @EmpAmount DECIMAL(18,2), @MatchAmount DECIMAL(18,2), @CurBalance DECIMAL(18,2);

        DECLARE fund_cursor CURSOR LOCAL FAST_FORWARD FOR
            SELECT sf.SavingsFundId, sf.EmployeeCode, sf.EmployeeContribution, sf.EmployerMatch
            FROM hr.SavingsFund sf
            WHERE sf.CompanyId = @CompanyId AND sf.Status = 'ACTIVO';

        OPEN fund_cursor;
        FETCH NEXT FROM fund_cursor INTO @FundId, @EmpCode, @EmpContrib, @MatchPct;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- Obtener salario del empleado
            SELECT @Salary = e.MonthlySalary
            FROM master.Employee e
            WHERE e.CompanyId = @CompanyId AND e.EmployeeCode = @EmpCode AND e.Status = 'ACTIVO';

            IF @Salary IS NOT NULL AND @Salary > 0
            BEGIN
                SET @EmpAmount = ROUND(@Salary * @EmpContrib / 100.0, 2);
                SET @MatchAmount = ROUND(@Salary * @MatchPct / 100.0, 2);

                -- Obtener saldo actual
                SELECT @CurBalance = ISNULL(
                    (SELECT TOP 1 Balance FROM hr.SavingsFundTransaction
                     WHERE SavingsFundId = @FundId ORDER BY TransactionId DESC), 0);

                -- Aporte empleado
                SET @CurBalance = @CurBalance + @EmpAmount;
                INSERT INTO hr.SavingsFundTransaction (
                    SavingsFundId, TransactionDate, TransactionType, Amount, Balance, Reference, PayrollBatchId
                )
                VALUES (@FundId, @ProcessDate, 'APORTE_EMPLEADO', @EmpAmount, @CurBalance,
                        'Aporte mensual ' + CONVERT(NVARCHAR(7), @ProcessDate, 120), @PayrollBatchId);

                -- Aporte patronal
                SET @CurBalance = @CurBalance + @MatchAmount;
                INSERT INTO hr.SavingsFundTransaction (
                    SavingsFundId, TransactionDate, TransactionType, Amount, Balance, Reference, PayrollBatchId
                )
                VALUES (@FundId, @ProcessDate, 'APORTE_PATRONAL', @MatchAmount, @CurBalance,
                        'Aporte patronal ' + CONVERT(NVARCHAR(7), @ProcessDate, 120), @PayrollBatchId);

                SET @Processed = @Processed + 1;
            END

            FETCH NEXT FROM fund_cursor INTO @FundId, @EmpCode, @EmpContrib, @MatchPct;
        END

        CLOSE fund_cursor;
        DEALLOCATE fund_cursor;

        COMMIT TRANSACTION;

        SET @Resultado = @Processed;
        SET @Mensaje = 'Aportes procesados para ' + CAST(@Processed AS VARCHAR(10)) + ' miembros.';

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        IF CURSOR_STATUS('local', 'fund_cursor') >= 0
        BEGIN
            CLOSE fund_cursor;
            DEALLOCATE fund_cursor;
        END
        SET @Resultado = -99;
        SET @Mensaje = ERROR_MESSAGE();
    END CATCH
END
GO

-- =============================================================
-- 11) usp_HR_Savings_GetBalance
-- =============================================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_HR_Savings_GetBalance')
    DROP PROCEDURE usp_HR_Savings_GetBalance
GO

CREATE PROCEDURE usp_HR_Savings_GetBalance
    @CompanyId      INT,
    @EmployeeCode   NVARCHAR(24)
AS
BEGIN
    SET NOCOUNT ON;

    -- Datos del fondo
    SELECT
        sf.SavingsFundId,
        sf.EmployeeCode,
        sf.EmployeeName,
        sf.EmployeeContribution,
        sf.EmployerMatch,
        sf.EnrollmentDate,
        sf.Status,
        ISNULL((
            SELECT TOP 1 Balance FROM hr.SavingsFundTransaction
            WHERE SavingsFundId = sf.SavingsFundId ORDER BY TransactionId DESC
        ), 0) AS CurrentBalance
    FROM hr.SavingsFund sf
    WHERE sf.CompanyId = @CompanyId AND sf.EmployeeCode = @EmployeeCode;

    -- Historial de transacciones
    SELECT
        tx.TransactionId,
        tx.TransactionDate,
        tx.TransactionType,
        tx.Amount,
        tx.Balance,
        tx.Reference,
        tx.PayrollBatchId,
        tx.Notes,
        tx.CreatedAt
    FROM hr.SavingsFundTransaction tx
    INNER JOIN hr.SavingsFund sf ON sf.SavingsFundId = tx.SavingsFundId
    WHERE sf.CompanyId = @CompanyId AND sf.EmployeeCode = @EmployeeCode
    ORDER BY tx.TransactionDate DESC, tx.TransactionId DESC;
END
GO

-- =============================================================
-- 12) usp_HR_Savings_RequestLoan
-- =============================================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_HR_Savings_RequestLoan')
    DROP PROCEDURE usp_HR_Savings_RequestLoan
GO

CREATE PROCEDURE usp_HR_Savings_RequestLoan
    @CompanyId          INT,
    @EmployeeCode       NVARCHAR(24),
    @LoanAmount         DECIMAL(18,2),
    @InterestRate       DECIMAL(8,5) = 0,
    @InstallmentsTotal  INT,
    @Notes              NVARCHAR(500) = NULL,
    @Resultado          INT OUTPUT,
    @Mensaje            NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Resultado = 0;
    SET @Mensaje = '';

    -- Buscar fondo activo
    DECLARE @FundId INT;
    SELECT @FundId = SavingsFundId FROM hr.SavingsFund
    WHERE CompanyId = @CompanyId AND EmployeeCode = @EmployeeCode AND Status = 'ACTIVO';

    IF @FundId IS NULL
    BEGIN
        SET @Resultado = -1;
        SET @Mensaje = 'El empleado no tiene una cuenta activa en caja de ahorro.';
        RETURN;
    END

    -- Verificar que no tenga prestamos activos
    IF EXISTS (
        SELECT 1 FROM hr.SavingsLoan
        WHERE SavingsFundId = @FundId AND Status IN ('SOLICITADO','APROBADO','ACTIVO')
    )
    BEGIN
        SET @Resultado = -2;
        SET @Mensaje = 'El empleado ya tiene un prestamo activo o pendiente.';
        RETURN;
    END

    -- Validar monto y cuotas
    IF @LoanAmount <= 0
    BEGIN
        SET @Resultado = -3;
        SET @Mensaje = 'El monto del prestamo debe ser mayor a cero.';
        RETURN;
    END

    IF @InstallmentsTotal <= 0
    BEGIN
        SET @Resultado = -4;
        SET @Mensaje = 'El numero de cuotas debe ser mayor a cero.';
        RETURN;
    END

    DECLARE @TotalPayable DECIMAL(18,2) = ROUND(@LoanAmount * (1 + @InterestRate / 100.0), 2);
    DECLARE @MonthlyPayment DECIMAL(18,2) = ROUND(@TotalPayable / @InstallmentsTotal, 2);

    BEGIN TRY
        INSERT INTO hr.SavingsLoan (
            SavingsFundId, EmployeeCode, RequestDate, LoanAmount,
            InterestRate, TotalPayable, MonthlyPayment,
            InstallmentsTotal, InstallmentsPaid, OutstandingBalance,
            Status, Notes
        )
        VALUES (
            @FundId, @EmployeeCode, CAST(SYSUTCDATETIME() AS DATE), @LoanAmount,
            @InterestRate, @TotalPayable, @MonthlyPayment,
            @InstallmentsTotal, 0, @TotalPayable,
            'SOLICITADO', @Notes
        );

        SET @Resultado = SCOPE_IDENTITY();
        SET @Mensaje = 'Solicitud de prestamo registrada exitosamente.';

    END TRY
    BEGIN CATCH
        SET @Resultado = -99;
        SET @Mensaje = ERROR_MESSAGE();
    END CATCH
END
GO

-- =============================================================
-- 13) usp_HR_Savings_ApproveLoan
-- =============================================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_HR_Savings_ApproveLoan')
    DROP PROCEDURE usp_HR_Savings_ApproveLoan
GO

CREATE PROCEDURE usp_HR_Savings_ApproveLoan
    @LoanId         INT,
    @Approved       BIT,
    @ApprovedBy     INT,
    @Notes          NVARCHAR(500) = NULL,
    @Resultado      INT OUTPUT,
    @Mensaje        NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Resultado = 0;
    SET @Mensaje = '';

    DECLARE @CurrentStatus NVARCHAR(15), @FundId INT, @LoanAmount DECIMAL(18,2);

    SELECT @CurrentStatus = Status, @FundId = SavingsFundId, @LoanAmount = LoanAmount
    FROM hr.SavingsLoan WHERE LoanId = @LoanId;

    IF @CurrentStatus IS NULL
    BEGIN
        SET @Resultado = -1;
        SET @Mensaje = 'Prestamo no encontrado.';
        RETURN;
    END

    IF @CurrentStatus <> 'SOLICITADO'
    BEGIN
        SET @Resultado = -2;
        SET @Mensaje = 'Solo se pueden aprobar/rechazar prestamos en estado SOLICITADO. Estado actual: ' + @CurrentStatus;
        RETURN;
    END

    BEGIN TRY
        BEGIN TRANSACTION;

        IF @Approved = 1
        BEGIN
            UPDATE hr.SavingsLoan
            SET Status       = 'ACTIVO',
                ApprovedDate = CAST(SYSUTCDATETIME() AS DATE),
                ApprovedBy   = @ApprovedBy,
                Notes        = ISNULL(@Notes, Notes),
                UpdatedAt    = SYSUTCDATETIME()
            WHERE LoanId = @LoanId;

            -- Registrar desembolso como transaccion de prestamo
            DECLARE @CurBalance DECIMAL(18,2);
            SELECT @CurBalance = ISNULL(
                (SELECT TOP 1 Balance FROM hr.SavingsFundTransaction
                 WHERE SavingsFundId = @FundId ORDER BY TransactionId DESC), 0);

            SET @CurBalance = @CurBalance - @LoanAmount;

            INSERT INTO hr.SavingsFundTransaction (
                SavingsFundId, TransactionDate, TransactionType, Amount, Balance, Reference, Notes
            )
            VALUES (@FundId, CAST(SYSUTCDATETIME() AS DATE), 'PRESTAMO', @LoanAmount, @CurBalance,
                    'Desembolso prestamo #' + CAST(@LoanId AS VARCHAR(10)),
                    'Aprobado por usuario ' + CAST(@ApprovedBy AS VARCHAR(10)));

            SET @Mensaje = 'Prestamo aprobado y desembolsado exitosamente.';
        END
        ELSE
        BEGIN
            UPDATE hr.SavingsLoan
            SET Status    = 'RECHAZADO',
                ApprovedBy = @ApprovedBy,
                Notes      = ISNULL(@Notes, Notes),
                UpdatedAt  = SYSUTCDATETIME()
            WHERE LoanId = @LoanId;

            SET @Mensaje = 'Prestamo rechazado.';
        END

        COMMIT TRANSACTION;

        SET @Resultado = @LoanId;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SET @Resultado = -99;
        SET @Mensaje = ERROR_MESSAGE();
    END CATCH
END
GO

-- =============================================================
-- 14) usp_HR_Savings_ProcessLoanPayment
-- =============================================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_HR_Savings_ProcessLoanPayment')
    DROP PROCEDURE usp_HR_Savings_ProcessLoanPayment
GO

CREATE PROCEDURE usp_HR_Savings_ProcessLoanPayment
    @LoanId         INT,
    @PaymentAmount  DECIMAL(18,2) = NULL,  -- NULL = cuota mensual
    @PaymentDate    DATE = NULL,
    @PayrollBatchId INT = NULL,
    @Resultado      INT OUTPUT,
    @Mensaje        NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Resultado = 0;
    SET @Mensaje = '';

    DECLARE @FundId INT, @MonthlyPayment DECIMAL(18,2), @Outstanding DECIMAL(18,2);
    DECLARE @InstPaid INT, @InstTotal INT, @CurrentStatus NVARCHAR(15);

    SELECT @FundId = SavingsFundId, @MonthlyPayment = MonthlyPayment,
           @Outstanding = OutstandingBalance, @InstPaid = InstallmentsPaid,
           @InstTotal = InstallmentsTotal, @CurrentStatus = Status
    FROM hr.SavingsLoan WHERE LoanId = @LoanId;

    IF @CurrentStatus IS NULL
    BEGIN
        SET @Resultado = -1;
        SET @Mensaje = 'Prestamo no encontrado.';
        RETURN;
    END

    IF @CurrentStatus <> 'ACTIVO'
    BEGIN
        SET @Resultado = -2;
        SET @Mensaje = 'Solo se pueden registrar pagos en prestamos ACTIVOS. Estado actual: ' + @CurrentStatus;
        RETURN;
    END

    -- Si no se especifica monto, usar cuota mensual
    IF @PaymentAmount IS NULL SET @PaymentAmount = @MonthlyPayment;
    IF @PaymentDate IS NULL SET @PaymentDate = CAST(SYSUTCDATETIME() AS DATE);

    -- No pagar mas de lo pendiente
    IF @PaymentAmount > @Outstanding SET @PaymentAmount = @Outstanding;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Actualizar saldo del prestamo
        SET @Outstanding = @Outstanding - @PaymentAmount;
        SET @InstPaid = @InstPaid + 1;

        UPDATE hr.SavingsLoan
        SET OutstandingBalance = @Outstanding,
            InstallmentsPaid   = @InstPaid,
            Status             = CASE WHEN @Outstanding <= 0 THEN 'PAGADO' ELSE 'ACTIVO' END,
            UpdatedAt          = SYSUTCDATETIME()
        WHERE LoanId = @LoanId;

        -- Registrar transaccion de pago
        DECLARE @CurBalance DECIMAL(18,2);
        SELECT @CurBalance = ISNULL(
            (SELECT TOP 1 Balance FROM hr.SavingsFundTransaction
             WHERE SavingsFundId = @FundId ORDER BY TransactionId DESC), 0);

        SET @CurBalance = @CurBalance + @PaymentAmount;

        INSERT INTO hr.SavingsFundTransaction (
            SavingsFundId, TransactionDate, TransactionType, Amount, Balance,
            Reference, PayrollBatchId, Notes
        )
        VALUES (@FundId, @PaymentDate, 'PAGO_PRESTAMO', @PaymentAmount, @CurBalance,
                'Pago cuota ' + CAST(@InstPaid AS VARCHAR(5)) + '/' + CAST(@InstTotal AS VARCHAR(5)) + ' prestamo #' + CAST(@LoanId AS VARCHAR(10)),
                @PayrollBatchId,
                CASE WHEN @Outstanding <= 0 THEN 'Prestamo liquidado' ELSE NULL END);

        COMMIT TRANSACTION;

        SET @Resultado = @LoanId;
        IF @Outstanding <= 0
            SET @Mensaje = 'Prestamo liquidado exitosamente.';
        ELSE
            SET @Mensaje = 'Pago registrado. Saldo pendiente: ' + CAST(@Outstanding AS VARCHAR(20));

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SET @Resultado = -99;
        SET @Mensaje = ERROR_MESSAGE();
    END CATCH
END
GO

-- =============================================================
-- 15) usp_HR_Savings_List
-- =============================================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_HR_Savings_List')
    DROP PROCEDURE usp_HR_Savings_List
GO

CREATE PROCEDURE usp_HR_Savings_List
    @CompanyId      INT,
    @Status         NVARCHAR(15) = NULL,
    @EmployeeCode   NVARCHAR(24) = NULL,
    @Offset         INT = 0,
    @Limit          INT = 50,
    @TotalCount     INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT @TotalCount = COUNT(*)
    FROM hr.SavingsFund sf
    WHERE sf.CompanyId = @CompanyId
      AND (@Status IS NULL OR sf.Status = @Status)
      AND (@EmployeeCode IS NULL OR sf.EmployeeCode = @EmployeeCode);

    SELECT
        sf.SavingsFundId,
        sf.EmployeeId,
        sf.EmployeeCode,
        sf.EmployeeName,
        sf.EmployeeContribution,
        sf.EmployerMatch,
        sf.EnrollmentDate,
        sf.Status,
        sf.CreatedAt,
        ISNULL((
            SELECT TOP 1 Balance FROM hr.SavingsFundTransaction
            WHERE SavingsFundId = sf.SavingsFundId ORDER BY TransactionId DESC
        ), 0) AS CurrentBalance
    FROM hr.SavingsFund sf
    WHERE sf.CompanyId = @CompanyId
      AND (@Status IS NULL OR sf.Status = @Status)
      AND (@EmployeeCode IS NULL OR sf.EmployeeCode = @EmployeeCode)
    ORDER BY sf.EmployeeName
    OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;
END
GO

-- =============================================================
-- 16) usp_HR_Savings_LoanList
-- =============================================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_HR_Savings_LoanList')
    DROP PROCEDURE usp_HR_Savings_LoanList
GO

CREATE PROCEDURE usp_HR_Savings_LoanList
    @CompanyId      INT,
    @Status         NVARCHAR(15) = NULL,
    @EmployeeCode   NVARCHAR(24) = NULL,
    @Offset         INT = 0,
    @Limit          INT = 50,
    @TotalCount     INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT @TotalCount = COUNT(*)
    FROM hr.SavingsLoan sl
    INNER JOIN hr.SavingsFund sf ON sf.SavingsFundId = sl.SavingsFundId
    WHERE sf.CompanyId = @CompanyId
      AND (@Status IS NULL OR sl.Status = @Status)
      AND (@EmployeeCode IS NULL OR sl.EmployeeCode = @EmployeeCode);

    SELECT
        sl.LoanId,
        sl.SavingsFundId,
        sl.EmployeeCode,
        sf.EmployeeName,
        sl.RequestDate,
        sl.ApprovedDate,
        sl.LoanAmount,
        sl.InterestRate,
        sl.TotalPayable,
        sl.MonthlyPayment,
        sl.InstallmentsTotal,
        sl.InstallmentsPaid,
        sl.OutstandingBalance,
        sl.Status,
        sl.ApprovedBy,
        sl.Notes,
        sl.CreatedAt
    FROM hr.SavingsLoan sl
    INNER JOIN hr.SavingsFund sf ON sf.SavingsFundId = sl.SavingsFundId
    WHERE sf.CompanyId = @CompanyId
      AND (@Status IS NULL OR sl.Status = @Status)
      AND (@EmployeeCode IS NULL OR sl.EmployeeCode = @EmployeeCode)
    ORDER BY sl.RequestDate DESC, sl.LoanId DESC
    OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;
END
GO

-- =============================================================
PRINT '>>> sp_rrhh_beneficios.sql ejecutado correctamente: Tablas + 16 SPs de Beneficios Laborales (Utilidades, Fideicomiso, Caja de Ahorro)';
GO
