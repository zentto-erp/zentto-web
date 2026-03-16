-- =============================================================================
-- sp_rrhh_obligaciones_legales.sql
-- Obligaciones Legales de RRHH (SSO, FAOV, INCE, TGSS, IMSS, EPS, FICA, etc.)
-- Modelo generico, agnostico de pais, orientado a configuracion.
--
-- Compatible con: SQL Server 2012+
-- NO usa: CREATE OR ALTER, FOR JSON PATH
--
-- Tablas:
--   hr.LegalObligation, hr.ObligationRiskLevel,
--   hr.EmployeeObligation, hr.ObligationFiling, hr.ObligationFilingDetail
--
-- Procedimientos:
--   1.  usp_HR_Obligation_List            - Listado paginado de obligaciones
--   2.  usp_HR_Obligation_Save            - Insertar/actualizar obligacion
--   3.  usp_HR_Obligation_GetByCountry    - Obligaciones activas por pais
--   4.  usp_HR_EmployeeObligation_Enroll  - Inscribir empleado en obligacion
--   5.  usp_HR_EmployeeObligation_Disenroll - Desinscribir empleado
--   6.  usp_HR_EmployeeObligation_GetByEmployee - Obligaciones de un empleado
--   7.  usp_HR_Filing_Generate            - Generar declaracion para un periodo
--   8.  usp_HR_Filing_GetSummary          - Cabecera + detalle de declaracion
--   9.  usp_HR_Filing_MarkFiled           - Marcar como presentada
--   10. usp_HR_Filing_List                - Listado paginado de declaraciones
--
-- Fecha creacion: 2026-03-15
-- =============================================================================
USE DatqBoxWeb;
GO
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

-- =============================================================================
-- TABLES
-- =============================================================================

-- hr.LegalObligation - Catalogo maestro de obligaciones legales
IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('hr.LegalObligation') AND type = 'U')
BEGIN
    CREATE TABLE hr.LegalObligation (
        LegalObligationId   INT             IDENTITY(1,1) NOT NULL,
        CountryCode         CHAR(2)         NOT NULL,
        Code                NVARCHAR(30)    NOT NULL,
        Name                NVARCHAR(200)   NOT NULL,
        InstitutionName     NVARCHAR(200)   NULL,
        ObligationType      NVARCHAR(20)    NOT NULL, -- CONTRIBUTION, TAX_WITHHOLDING, REPORTING, REGISTRATION
        CalculationBasis    NVARCHAR(30)    NOT NULL, -- NORMAL_SALARY, INTEGRAL_SALARY, GROSS_PAYROLL, TAXABLE_INCOME, FIXED_AMOUNT
        SalaryCap           DECIMAL(18,2)   NULL,
        SalaryCapUnit       NVARCHAR(20)    NULL,     -- CURRENCY, MIN_WAGES, UMA, SMMLV
        EmployerRate        DECIMAL(8,5)    NOT NULL DEFAULT 0,
        EmployeeRate        DECIMAL(8,5)    NOT NULL DEFAULT 0,
        RateVariableByRisk  BIT             NOT NULL DEFAULT 0,
        FilingFrequency     NVARCHAR(15)    NOT NULL, -- MONTHLY, QUARTERLY, ANNUAL, REALTIME
        FilingDeadlineRule  NVARCHAR(200)   NULL,
        EffectiveFrom       DATE            NOT NULL,
        EffectiveTo         DATE            NULL,
        IsActive            BIT             NOT NULL DEFAULT 1,
        Notes               NVARCHAR(500)   NULL,
        CreatedAt           DATETIME2(0)    NOT NULL DEFAULT SYSUTCDATETIME(),
        UpdatedAt           DATETIME2(0)    NOT NULL DEFAULT SYSUTCDATETIME(),
        CONSTRAINT PK_LegalObligation PRIMARY KEY CLUSTERED (LegalObligationId),
        CONSTRAINT UQ_LegalObligation_Country_Code_From UNIQUE (CountryCode, Code, EffectiveFrom)
    );
END
GO

-- hr.ObligationRiskLevel - Tasas variables por nivel de riesgo
IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('hr.ObligationRiskLevel') AND type = 'U')
BEGIN
    CREATE TABLE hr.ObligationRiskLevel (
        ObligationRiskLevelId   INT             IDENTITY(1,1) NOT NULL,
        LegalObligationId       INT             NOT NULL,
        RiskLevel               SMALLINT        NOT NULL,
        RiskDescription         NVARCHAR(100)   NULL,
        EmployerRate            DECIMAL(8,5)    NOT NULL DEFAULT 0,
        EmployeeRate            DECIMAL(8,5)    NOT NULL DEFAULT 0,
        CONSTRAINT PK_ObligationRiskLevel PRIMARY KEY CLUSTERED (ObligationRiskLevelId),
        CONSTRAINT FK_ObligationRiskLevel_Obligation FOREIGN KEY (LegalObligationId)
            REFERENCES hr.LegalObligation (LegalObligationId),
        CONSTRAINT UQ_ObligationRiskLevel UNIQUE (LegalObligationId, RiskLevel)
    );
END
GO

-- hr.EmployeeObligation - Inscripcion por empleado
IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('hr.EmployeeObligation') AND type = 'U')
BEGIN
    CREATE TABLE hr.EmployeeObligation (
        EmployeeObligationId    INT             IDENTITY(1,1) NOT NULL,
        EmployeeId              BIGINT          NOT NULL,
        LegalObligationId       INT             NOT NULL,
        AffiliationNumber       NVARCHAR(50)    NULL,
        InstitutionCode         NVARCHAR(50)    NULL,
        RiskLevelId             INT             NULL,
        EnrollmentDate          DATE            NOT NULL,
        DisenrollmentDate       DATE            NULL,
        Status                  NVARCHAR(15)    NOT NULL DEFAULT 'ACTIVE', -- ACTIVE, SUSPENDED, TERMINATED
        CustomRate              DECIMAL(8,5)    NULL,
        CreatedAt               DATETIME2(0)    NOT NULL DEFAULT SYSUTCDATETIME(),
        UpdatedAt               DATETIME2(0)    NOT NULL DEFAULT SYSUTCDATETIME(),
        CONSTRAINT PK_EmployeeObligation PRIMARY KEY CLUSTERED (EmployeeObligationId),
        CONSTRAINT FK_EmployeeObligation_Obligation FOREIGN KEY (LegalObligationId)
            REFERENCES hr.LegalObligation (LegalObligationId),
        CONSTRAINT FK_EmployeeObligation_RiskLevel FOREIGN KEY (RiskLevelId)
            REFERENCES hr.ObligationRiskLevel (ObligationRiskLevelId)
    );
END
GO

-- hr.ObligationFiling - Declaraciones presentadas
IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('hr.ObligationFiling') AND type = 'U')
BEGIN
    CREATE TABLE hr.ObligationFiling (
        ObligationFilingId      INT             IDENTITY(1,1) NOT NULL,
        CompanyId               INT             NOT NULL,
        LegalObligationId       INT             NOT NULL,
        FilingPeriodStart       DATE            NOT NULL,
        FilingPeriodEnd         DATE            NOT NULL,
        DueDate                 DATE            NOT NULL,
        FiledDate               DATE            NULL,
        ConfirmationNumber      NVARCHAR(100)   NULL,
        TotalEmployerAmount     DECIMAL(18,2)   NOT NULL DEFAULT 0,
        TotalEmployeeAmount     DECIMAL(18,2)   NOT NULL DEFAULT 0,
        TotalAmount             DECIMAL(18,2)   NOT NULL DEFAULT 0,
        EmployeeCount           INT             NOT NULL DEFAULT 0,
        Status                  NVARCHAR(15)    NOT NULL DEFAULT 'PENDING', -- PENDING, FILED, PAID, LATE, REJECTED
        FiledByUserId           INT             NULL,
        DocumentUrl             NVARCHAR(500)   NULL,
        Notes                   NVARCHAR(500)   NULL,
        CreatedAt               DATETIME2(0)    NOT NULL DEFAULT SYSUTCDATETIME(),
        UpdatedAt               DATETIME2(0)    NOT NULL DEFAULT SYSUTCDATETIME(),
        CONSTRAINT PK_ObligationFiling PRIMARY KEY CLUSTERED (ObligationFilingId),
        CONSTRAINT FK_ObligationFiling_Obligation FOREIGN KEY (LegalObligationId)
            REFERENCES hr.LegalObligation (LegalObligationId)
    );
END
GO

-- hr.ObligationFilingDetail - Detalle por empleado
IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('hr.ObligationFilingDetail') AND type = 'U')
BEGIN
    CREATE TABLE hr.ObligationFilingDetail (
        DetailId                INT             IDENTITY(1,1) NOT NULL,
        ObligationFilingId      INT             NOT NULL,
        EmployeeId              BIGINT          NOT NULL,
        BaseSalary              DECIMAL(18,2)   NOT NULL DEFAULT 0,
        EmployerAmount          DECIMAL(18,2)   NOT NULL DEFAULT 0,
        EmployeeAmount          DECIMAL(18,2)   NOT NULL DEFAULT 0,
        DaysWorked              SMALLINT        NULL,
        NoveltyType             NVARCHAR(20)    NULL, -- ENROLLMENT, WITHDRAWAL, SALARY_CHANGE, LEAVE, NONE
        CONSTRAINT PK_ObligationFilingDetail PRIMARY KEY CLUSTERED (DetailId),
        CONSTRAINT FK_ObligationFilingDetail_Filing FOREIGN KEY (ObligationFilingId)
            REFERENCES hr.ObligationFiling (ObligationFilingId),
        CONSTRAINT UQ_ObligationFilingDetail UNIQUE (ObligationFilingId, EmployeeId)
    );
END
GO

-- =============================================================================
-- INDEXES
-- =============================================================================

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_LegalObligation_Country_Active')
    CREATE NONCLUSTERED INDEX IX_LegalObligation_Country_Active
        ON hr.LegalObligation (CountryCode, IsActive)
        INCLUDE (Code, Name, ObligationType, EmployerRate, EmployeeRate, EffectiveFrom, EffectiveTo);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_EmployeeObligation_Employee')
    CREATE NONCLUSTERED INDEX IX_EmployeeObligation_Employee
        ON hr.EmployeeObligation (EmployeeId, Status)
        INCLUDE (LegalObligationId, EnrollmentDate, DisenrollmentDate);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_EmployeeObligation_Obligation')
    CREATE NONCLUSTERED INDEX IX_EmployeeObligation_Obligation
        ON hr.EmployeeObligation (LegalObligationId, Status)
        INCLUDE (EmployeeId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_ObligationFiling_Company_Period')
    CREATE NONCLUSTERED INDEX IX_ObligationFiling_Company_Period
        ON hr.ObligationFiling (CompanyId, LegalObligationId, FilingPeriodStart, FilingPeriodEnd)
        INCLUDE (Status, TotalAmount);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_ObligationFiling_Status')
    CREATE NONCLUSTERED INDEX IX_ObligationFiling_Status
        ON hr.ObligationFiling (Status, DueDate)
        INCLUDE (CompanyId, LegalObligationId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_ObligationFilingDetail_Filing')
    CREATE NONCLUSTERED INDEX IX_ObligationFilingDetail_Filing
        ON hr.ObligationFilingDetail (ObligationFilingId)
        INCLUDE (EmployeeId, EmployerAmount, EmployeeAmount);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_ObligationFilingDetail_Employee')
    CREATE NONCLUSTERED INDEX IX_ObligationFilingDetail_Employee
        ON hr.ObligationFilingDetail (EmployeeId)
        INCLUDE (ObligationFilingId, BaseSalary, EmployerAmount, EmployeeAmount);
GO

-- =============================================================================
-- 1. usp_HR_Obligation_List
--    Listado paginado de obligaciones, filtrado por pais.
-- =============================================================================
IF OBJECT_ID('dbo.usp_HR_Obligation_List', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_HR_Obligation_List;
GO

CREATE PROCEDURE dbo.usp_HR_Obligation_List
    @CountryCode    CHAR(2)         = NULL,
    @ObligationType NVARCHAR(20)    = NULL,
    @IsActive       BIT             = NULL,
    @Search         NVARCHAR(100)   = NULL,
    @Page           INT             = 1,
    @Limit          INT             = 50,
    @TotalCount     INT             OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    IF @Page < 1 SET @Page = 1;
    IF @Limit < 1 SET @Limit = 50;
    IF @Limit > 500 SET @Limit = 500;

    SELECT @TotalCount = COUNT(*)
    FROM hr.LegalObligation
    WHERE (@CountryCode    IS NULL OR CountryCode    = @CountryCode)
      AND (@ObligationType IS NULL OR ObligationType = @ObligationType)
      AND (@IsActive       IS NULL OR IsActive       = @IsActive)
      AND (@Search         IS NULL OR Name LIKE '%' + @Search + '%' OR Code LIKE '%' + @Search + '%');

    SELECT
        LegalObligationId,
        CountryCode,
        Code,
        Name,
        InstitutionName,
        ObligationType,
        CalculationBasis,
        SalaryCap,
        SalaryCapUnit,
        EmployerRate,
        EmployeeRate,
        RateVariableByRisk,
        FilingFrequency,
        FilingDeadlineRule,
        EffectiveFrom,
        EffectiveTo,
        IsActive,
        Notes
    FROM hr.LegalObligation
    WHERE (@CountryCode    IS NULL OR CountryCode    = @CountryCode)
      AND (@ObligationType IS NULL OR ObligationType = @ObligationType)
      AND (@IsActive       IS NULL OR IsActive       = @IsActive)
      AND (@Search         IS NULL OR Name LIKE '%' + @Search + '%' OR Code LIKE '%' + @Search + '%')
    ORDER BY CountryCode, Code
    OFFSET (@Page - 1) * @Limit ROWS
    FETCH NEXT @Limit ROWS ONLY;
END
GO

-- =============================================================================
-- 2. usp_HR_Obligation_Save
--    Insertar o actualizar una obligacion legal (configuracion administrativa).
-- =============================================================================
IF OBJECT_ID('dbo.usp_HR_Obligation_Save', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_HR_Obligation_Save;
GO

CREATE PROCEDURE dbo.usp_HR_Obligation_Save
    @LegalObligationId  INT             = NULL,  -- NULL = insert, >0 = update
    @CountryCode        CHAR(2),
    @Code               NVARCHAR(30),
    @Name               NVARCHAR(200),
    @InstitutionName    NVARCHAR(200)   = NULL,
    @ObligationType     NVARCHAR(20),
    @CalculationBasis   NVARCHAR(30),
    @SalaryCap          DECIMAL(18,2)   = NULL,
    @SalaryCapUnit      NVARCHAR(20)    = NULL,
    @EmployerRate       DECIMAL(8,5)    = 0,
    @EmployeeRate       DECIMAL(8,5)    = 0,
    @RateVariableByRisk BIT             = 0,
    @FilingFrequency    NVARCHAR(15),
    @FilingDeadlineRule  NVARCHAR(200)   = NULL,
    @EffectiveFrom      DATE,
    @EffectiveTo        DATE            = NULL,
    @IsActive           BIT             = 1,
    @Notes              NVARCHAR(500)   = NULL,
    @Resultado          INT             OUTPUT,
    @Mensaje            NVARCHAR(500)   OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Resultado = 0;
    SET @Mensaje = '';

    -- Validaciones
    IF @CountryCode IS NULL OR LEN(LTRIM(@CountryCode)) = 0
    BEGIN
        SET @Resultado = -1;
        SET @Mensaje = 'El codigo de pais es obligatorio.';
        RETURN;
    END

    IF @Code IS NULL OR LEN(LTRIM(@Code)) = 0
    BEGIN
        SET @Resultado = -1;
        SET @Mensaje = 'El codigo de obligacion es obligatorio.';
        RETURN;
    END

    IF @ObligationType NOT IN ('CONTRIBUTION', 'TAX_WITHHOLDING', 'REPORTING', 'REGISTRATION')
    BEGIN
        SET @Resultado = -1;
        SET @Mensaje = 'Tipo de obligacion no valido. Use: CONTRIBUTION, TAX_WITHHOLDING, REPORTING, REGISTRATION.';
        RETURN;
    END

    IF @CalculationBasis NOT IN ('NORMAL_SALARY', 'INTEGRAL_SALARY', 'GROSS_PAYROLL', 'TAXABLE_INCOME', 'FIXED_AMOUNT')
    BEGIN
        SET @Resultado = -1;
        SET @Mensaje = 'Base de calculo no valida.';
        RETURN;
    END

    IF @FilingFrequency NOT IN ('MONTHLY', 'QUARTERLY', 'ANNUAL', 'REALTIME')
    BEGIN
        SET @Resultado = -1;
        SET @Mensaje = 'Frecuencia de presentacion no valida.';
        RETURN;
    END

    BEGIN TRY
        IF @LegalObligationId IS NULL OR @LegalObligationId = 0
        BEGIN
            -- Verificar duplicado
            IF EXISTS (
                SELECT 1 FROM hr.LegalObligation
                WHERE CountryCode = @CountryCode AND Code = @Code AND EffectiveFrom = @EffectiveFrom
            )
            BEGIN
                SET @Resultado = -2;
                SET @Mensaje = 'Ya existe una obligacion con ese codigo y fecha de vigencia para el pais indicado.';
                RETURN;
            END

            INSERT INTO hr.LegalObligation (
                CountryCode, Code, Name, InstitutionName, ObligationType,
                CalculationBasis, SalaryCap, SalaryCapUnit, EmployerRate, EmployeeRate,
                RateVariableByRisk, FilingFrequency, FilingDeadlineRule,
                EffectiveFrom, EffectiveTo, IsActive, Notes, CreatedAt, UpdatedAt
            )
            VALUES (
                @CountryCode, @Code, @Name, @InstitutionName, @ObligationType,
                @CalculationBasis, @SalaryCap, @SalaryCapUnit, @EmployerRate, @EmployeeRate,
                @RateVariableByRisk, @FilingFrequency, @FilingDeadlineRule,
                @EffectiveFrom, @EffectiveTo, @IsActive, @Notes, SYSUTCDATETIME(), SYSUTCDATETIME()
            );

            SET @Resultado = SCOPE_IDENTITY();
            SET @Mensaje = 'Obligacion legal creada exitosamente.';
        END
        ELSE
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM hr.LegalObligation WHERE LegalObligationId = @LegalObligationId)
            BEGIN
                SET @Resultado = -3;
                SET @Mensaje = 'No se encontro la obligacion legal con el ID indicado.';
                RETURN;
            END

            -- Verificar duplicado excluyendo el registro actual
            IF EXISTS (
                SELECT 1 FROM hr.LegalObligation
                WHERE CountryCode = @CountryCode AND Code = @Code AND EffectiveFrom = @EffectiveFrom
                  AND LegalObligationId <> @LegalObligationId
            )
            BEGIN
                SET @Resultado = -2;
                SET @Mensaje = 'Ya existe otra obligacion con ese codigo y fecha de vigencia para el pais indicado.';
                RETURN;
            END

            UPDATE hr.LegalObligation SET
                CountryCode         = @CountryCode,
                Code                = @Code,
                Name                = @Name,
                InstitutionName     = @InstitutionName,
                ObligationType      = @ObligationType,
                CalculationBasis    = @CalculationBasis,
                SalaryCap           = @SalaryCap,
                SalaryCapUnit       = @SalaryCapUnit,
                EmployerRate        = @EmployerRate,
                EmployeeRate        = @EmployeeRate,
                RateVariableByRisk  = @RateVariableByRisk,
                FilingFrequency     = @FilingFrequency,
                FilingDeadlineRule  = @FilingDeadlineRule,
                EffectiveFrom       = @EffectiveFrom,
                EffectiveTo         = @EffectiveTo,
                IsActive            = @IsActive,
                Notes               = @Notes,
                UpdatedAt           = SYSUTCDATETIME()
            WHERE LegalObligationId = @LegalObligationId;

            SET @Resultado = @LegalObligationId;
            SET @Mensaje = 'Obligacion legal actualizada exitosamente.';
        END
    END TRY
    BEGIN CATCH
        SET @Resultado = -99;
        SET @Mensaje = ERROR_MESSAGE();
    END CATCH
END
GO

-- =============================================================================
-- 3. usp_HR_Obligation_GetByCountry
--    Obtener todas las obligaciones activas y vigentes para un pais.
-- =============================================================================
IF OBJECT_ID('dbo.usp_HR_Obligation_GetByCountry', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_HR_Obligation_GetByCountry;
GO

CREATE PROCEDURE dbo.usp_HR_Obligation_GetByCountry
    @CountryCode    CHAR(2),
    @AsOfDate       DATE = NULL  -- Fecha de referencia para vigencia
AS
BEGIN
    SET NOCOUNT ON;

    IF @AsOfDate IS NULL
        SET @AsOfDate = CAST(SYSUTCDATETIME() AS DATE);

    SELECT
        o.LegalObligationId,
        o.CountryCode,
        o.Code,
        o.Name,
        o.InstitutionName,
        o.ObligationType,
        o.CalculationBasis,
        o.SalaryCap,
        o.SalaryCapUnit,
        o.EmployerRate,
        o.EmployeeRate,
        o.RateVariableByRisk,
        o.FilingFrequency,
        o.FilingDeadlineRule,
        o.EffectiveFrom,
        o.EffectiveTo,
        o.Notes
    FROM hr.LegalObligation o
    WHERE o.CountryCode = @CountryCode
      AND o.IsActive = 1
      AND o.EffectiveFrom <= @AsOfDate
      AND (o.EffectiveTo IS NULL OR o.EffectiveTo >= @AsOfDate)
    ORDER BY o.Code;
END
GO

-- =============================================================================
-- 4. usp_HR_EmployeeObligation_Enroll
--    Inscribir un empleado en una obligacion legal.
-- =============================================================================
IF OBJECT_ID('dbo.usp_HR_EmployeeObligation_Enroll', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_HR_EmployeeObligation_Enroll;
GO

CREATE PROCEDURE dbo.usp_HR_EmployeeObligation_Enroll
    @EmployeeId         BIGINT,
    @LegalObligationId  INT,
    @AffiliationNumber  NVARCHAR(50)    = NULL,
    @InstitutionCode    NVARCHAR(50)    = NULL,
    @RiskLevelId        INT             = NULL,
    @EnrollmentDate     DATE,
    @CustomRate         DECIMAL(8,5)    = NULL,
    @Resultado          INT             OUTPUT,
    @Mensaje            NVARCHAR(500)   OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Resultado = 0;
    SET @Mensaje = '';

    -- Validar que la obligacion existe y esta activa
    IF NOT EXISTS (
        SELECT 1 FROM hr.LegalObligation
        WHERE LegalObligationId = @LegalObligationId AND IsActive = 1
    )
    BEGIN
        SET @Resultado = -1;
        SET @Mensaje = 'La obligacion legal no existe o no esta activa.';
        RETURN;
    END

    -- Validar que no exista una inscripcion activa duplicada
    IF EXISTS (
        SELECT 1 FROM hr.EmployeeObligation
        WHERE EmployeeId = @EmployeeId
          AND LegalObligationId = @LegalObligationId
          AND Status = 'ACTIVE'
    )
    BEGIN
        SET @Resultado = -2;
        SET @Mensaje = 'El empleado ya tiene una inscripcion activa en esta obligacion.';
        RETURN;
    END

    -- Validar nivel de riesgo si se proporciona
    IF @RiskLevelId IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM hr.ObligationRiskLevel
        WHERE ObligationRiskLevelId = @RiskLevelId AND LegalObligationId = @LegalObligationId
    )
    BEGIN
        SET @Resultado = -3;
        SET @Mensaje = 'El nivel de riesgo indicado no corresponde a esta obligacion.';
        RETURN;
    END

    BEGIN TRY
        INSERT INTO hr.EmployeeObligation (
            EmployeeId, LegalObligationId, AffiliationNumber, InstitutionCode,
            RiskLevelId, EnrollmentDate, Status, CustomRate, CreatedAt, UpdatedAt
        )
        VALUES (
            @EmployeeId, @LegalObligationId, @AffiliationNumber, @InstitutionCode,
            @RiskLevelId, @EnrollmentDate, 'ACTIVE', @CustomRate, SYSUTCDATETIME(), SYSUTCDATETIME()
        );

        SET @Resultado = SCOPE_IDENTITY();
        SET @Mensaje = 'Empleado inscrito exitosamente en la obligacion.';
    END TRY
    BEGIN CATCH
        SET @Resultado = -99;
        SET @Mensaje = ERROR_MESSAGE();
    END CATCH
END
GO

-- =============================================================================
-- 5. usp_HR_EmployeeObligation_Disenroll
--    Desinscribir empleado (establecer fecha de retiro y estado TERMINATED).
-- =============================================================================
IF OBJECT_ID('dbo.usp_HR_EmployeeObligation_Disenroll', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_HR_EmployeeObligation_Disenroll;
GO

CREATE PROCEDURE dbo.usp_HR_EmployeeObligation_Disenroll
    @EmployeeObligationId   INT,
    @DisenrollmentDate      DATE,
    @Resultado              INT             OUTPUT,
    @Mensaje                NVARCHAR(500)   OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Resultado = 0;
    SET @Mensaje = '';

    DECLARE @CurrentStatus NVARCHAR(15);
    DECLARE @EnrollDate DATE;

    SELECT @CurrentStatus = Status, @EnrollDate = EnrollmentDate
    FROM hr.EmployeeObligation
    WHERE EmployeeObligationId = @EmployeeObligationId;

    IF @CurrentStatus IS NULL
    BEGIN
        SET @Resultado = -1;
        SET @Mensaje = 'No se encontro la inscripcion indicada.';
        RETURN;
    END

    IF @CurrentStatus <> 'ACTIVE'
    BEGIN
        SET @Resultado = -2;
        SET @Mensaje = 'La inscripcion no esta activa. Estado actual: ' + @CurrentStatus;
        RETURN;
    END

    IF @DisenrollmentDate < @EnrollDate
    BEGIN
        SET @Resultado = -3;
        SET @Mensaje = 'La fecha de retiro no puede ser anterior a la fecha de inscripcion.';
        RETURN;
    END

    BEGIN TRY
        UPDATE hr.EmployeeObligation SET
            DisenrollmentDate = @DisenrollmentDate,
            Status = 'TERMINATED',
            UpdatedAt = SYSUTCDATETIME()
        WHERE EmployeeObligationId = @EmployeeObligationId;

        SET @Resultado = @EmployeeObligationId;
        SET @Mensaje = 'Empleado desinscrito exitosamente.';
    END TRY
    BEGIN CATCH
        SET @Resultado = -99;
        SET @Mensaje = ERROR_MESSAGE();
    END CATCH
END
GO

-- =============================================================================
-- 6. usp_HR_EmployeeObligation_GetByEmployee
--    Obtener todas las obligaciones de un empleado.
-- =============================================================================
IF OBJECT_ID('dbo.usp_HR_EmployeeObligation_GetByEmployee', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_HR_EmployeeObligation_GetByEmployee;
GO

CREATE PROCEDURE dbo.usp_HR_EmployeeObligation_GetByEmployee
    @EmployeeId     BIGINT,
    @StatusFilter   NVARCHAR(15)    = NULL,  -- NULL = todos, ACTIVE, TERMINATED, SUSPENDED
    @TotalCount     INT             OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT @TotalCount = COUNT(*)
    FROM hr.EmployeeObligation
    WHERE EmployeeId = @EmployeeId
      AND (@StatusFilter IS NULL OR Status = @StatusFilter);

    SELECT
        eo.EmployeeObligationId,
        eo.EmployeeId,
        eo.LegalObligationId,
        lo.CountryCode,
        lo.Code,
        lo.Name AS ObligationName,
        lo.InstitutionName,
        lo.ObligationType,
        lo.CalculationBasis,
        eo.AffiliationNumber,
        eo.InstitutionCode,
        eo.RiskLevelId,
        rl.RiskLevel,
        rl.RiskDescription,
        eo.EnrollmentDate,
        eo.DisenrollmentDate,
        eo.Status,
        eo.CustomRate,
        COALESCE(eo.CustomRate, rl.EmployerRate, lo.EmployerRate) AS EffectiveEmployerRate,
        COALESCE(CASE WHEN eo.CustomRate IS NOT NULL THEN lo.EmployeeRate ELSE NULL END,
                 rl.EmployeeRate, lo.EmployeeRate) AS EffectiveEmployeeRate
    FROM hr.EmployeeObligation eo
    INNER JOIN hr.LegalObligation lo ON lo.LegalObligationId = eo.LegalObligationId
    LEFT JOIN hr.ObligationRiskLevel rl ON rl.ObligationRiskLevelId = eo.RiskLevelId
    WHERE eo.EmployeeId = @EmployeeId
      AND (@StatusFilter IS NULL OR eo.Status = @StatusFilter)
    ORDER BY lo.CountryCode, lo.Code;
END
GO

-- =============================================================================
-- 7. usp_HR_Filing_Generate
--    Generar una declaracion para un periodo: calcula montos para todos los
--    empleados inscritos usando las tasas de la obligacion.
-- =============================================================================
IF OBJECT_ID('dbo.usp_HR_Filing_Generate', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_HR_Filing_Generate;
GO

CREATE PROCEDURE dbo.usp_HR_Filing_Generate
    @CompanyId          INT,
    @LegalObligationId  INT,
    @FilingPeriodStart  DATE,
    @FilingPeriodEnd    DATE,
    @DueDate            DATE,
    @Resultado          INT             OUTPUT,
    @Mensaje            NVARCHAR(500)   OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Resultado = 0;
    SET @Mensaje = '';

    -- Validar que la obligacion existe
    IF NOT EXISTS (
        SELECT 1 FROM hr.LegalObligation
        WHERE LegalObligationId = @LegalObligationId AND IsActive = 1
    )
    BEGIN
        SET @Resultado = -1;
        SET @Mensaje = 'La obligacion legal no existe o no esta activa.';
        RETURN;
    END

    -- Validar que no exista ya una declaracion para el mismo periodo
    IF EXISTS (
        SELECT 1 FROM hr.ObligationFiling
        WHERE CompanyId = @CompanyId
          AND LegalObligationId = @LegalObligationId
          AND FilingPeriodStart = @FilingPeriodStart
          AND FilingPeriodEnd = @FilingPeriodEnd
          AND Status <> 'REJECTED'
    )
    BEGIN
        SET @Resultado = -2;
        SET @Mensaje = 'Ya existe una declaracion para este periodo y obligacion.';
        RETURN;
    END

    IF @FilingPeriodEnd < @FilingPeriodStart
    BEGIN
        SET @Resultado = -3;
        SET @Mensaje = 'La fecha fin del periodo no puede ser anterior a la fecha inicio.';
        RETURN;
    END

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Obtener tasas base de la obligacion
        DECLARE @BaseEmployerRate DECIMAL(8,5);
        DECLARE @BaseEmployeeRate DECIMAL(8,5);
        DECLARE @CalcBasis NVARCHAR(30);
        DECLARE @Cap DECIMAL(18,2);

        SELECT
            @BaseEmployerRate = EmployerRate,
            @BaseEmployeeRate = EmployeeRate,
            @CalcBasis = CalculationBasis,
            @Cap = SalaryCap
        FROM hr.LegalObligation
        WHERE LegalObligationId = @LegalObligationId;

        -- Crear la cabecera
        INSERT INTO hr.ObligationFiling (
            CompanyId, LegalObligationId, FilingPeriodStart, FilingPeriodEnd,
            DueDate, Status, CreatedAt, UpdatedAt
        )
        VALUES (
            @CompanyId, @LegalObligationId, @FilingPeriodStart, @FilingPeriodEnd,
            @DueDate, 'PENDING', SYSUTCDATETIME(), SYSUTCDATETIME()
        );

        DECLARE @FilingId INT = SCOPE_IDENTITY();

        -- Insertar detalle por cada empleado inscrito activo en el periodo
        -- Tasa efectiva: CustomRate > RiskLevel > Base
        INSERT INTO hr.ObligationFilingDetail (
            ObligationFilingId, EmployeeId, BaseSalary, EmployerAmount, EmployeeAmount,
            DaysWorked, NoveltyType
        )
        SELECT
            @FilingId,
            eo.EmployeeId,
            ISNULL((
                SELECT TOP 1 prl.Amount
                FROM hr.PayrollRun pr
                INNER JOIN hr.PayrollRunLine prl ON prl.PayrollRunId = pr.PayrollRunId
                WHERE pr.EmployeeId = e.EmployeeId AND prl.ConceptCode = 'SALARIO_BASE'
                ORDER BY pr.CreatedAt DESC
            ), 0) AS BaseSalary,
            -- Monto patronal: salario * tasa efectiva patronal / 100
            ROUND(
                CASE WHEN @Cap IS NOT NULL AND ISNULL((
                    SELECT TOP 1 prl.Amount
                    FROM hr.PayrollRun pr
                    INNER JOIN hr.PayrollRunLine prl ON prl.PayrollRunId = pr.PayrollRunId
                    WHERE pr.EmployeeId = e.EmployeeId AND prl.ConceptCode = 'SALARIO_BASE'
                    ORDER BY pr.CreatedAt DESC
                ), 0) > @Cap
                     THEN @Cap
                     ELSE ISNULL((
                        SELECT TOP 1 prl.Amount
                        FROM hr.PayrollRun pr
                        INNER JOIN hr.PayrollRunLine prl ON prl.PayrollRunId = pr.PayrollRunId
                        WHERE pr.EmployeeId = e.EmployeeId AND prl.ConceptCode = 'SALARIO_BASE'
                        ORDER BY pr.CreatedAt DESC
                     ), 0)
                END
                * COALESCE(eo.CustomRate, rl.EmployerRate, @BaseEmployerRate) / 100.0,
            2) AS EmployerAmount,
            -- Monto empleado: salario * tasa efectiva empleado / 100
            ROUND(
                CASE WHEN @Cap IS NOT NULL AND ISNULL((
                    SELECT TOP 1 prl.Amount
                    FROM hr.PayrollRun pr
                    INNER JOIN hr.PayrollRunLine prl ON prl.PayrollRunId = pr.PayrollRunId
                    WHERE pr.EmployeeId = e.EmployeeId AND prl.ConceptCode = 'SALARIO_BASE'
                    ORDER BY pr.CreatedAt DESC
                ), 0) > @Cap
                     THEN @Cap
                     ELSE ISNULL((
                        SELECT TOP 1 prl.Amount
                        FROM hr.PayrollRun pr
                        INNER JOIN hr.PayrollRunLine prl ON prl.PayrollRunId = pr.PayrollRunId
                        WHERE pr.EmployeeId = e.EmployeeId AND prl.ConceptCode = 'SALARIO_BASE'
                        ORDER BY pr.CreatedAt DESC
                     ), 0)
                END
                * COALESCE(rl.EmployeeRate, @BaseEmployeeRate) / 100.0,
            2) AS EmployeeAmount,
            30 AS DaysWorked,  -- Default; idealmente se calcula por novedades
            CASE
                WHEN eo.EnrollmentDate BETWEEN @FilingPeriodStart AND @FilingPeriodEnd THEN 'ENROLLMENT'
                WHEN eo.DisenrollmentDate BETWEEN @FilingPeriodStart AND @FilingPeriodEnd THEN 'WITHDRAWAL'
                ELSE 'NONE'
            END AS NoveltyType
        FROM hr.EmployeeObligation eo
        INNER JOIN master.Employee e ON e.EmployeeId = eo.EmployeeId
        LEFT JOIN hr.ObligationRiskLevel rl ON rl.ObligationRiskLevelId = eo.RiskLevelId
        WHERE eo.LegalObligationId = @LegalObligationId
          AND eo.Status IN ('ACTIVE', 'SUSPENDED')
          AND eo.EnrollmentDate <= @FilingPeriodEnd
          AND (eo.DisenrollmentDate IS NULL OR eo.DisenrollmentDate >= @FilingPeriodStart);

        -- Actualizar totales en la cabecera
        DECLARE @TotEmployer DECIMAL(18,2) = 0;
        DECLARE @TotEmployee DECIMAL(18,2) = 0;
        DECLARE @EmpCount INT = 0;

        SELECT
            @TotEmployer = ISNULL(SUM(EmployerAmount), 0),
            @TotEmployee = ISNULL(SUM(EmployeeAmount), 0),
            @EmpCount    = COUNT(*)
        FROM hr.ObligationFilingDetail
        WHERE ObligationFilingId = @FilingId;

        UPDATE hr.ObligationFiling SET
            TotalEmployerAmount = @TotEmployer,
            TotalEmployeeAmount = @TotEmployee,
            TotalAmount         = @TotEmployer + @TotEmployee,
            EmployeeCount       = @EmpCount,
            UpdatedAt           = SYSUTCDATETIME()
        WHERE ObligationFilingId = @FilingId;

        COMMIT TRANSACTION;

        SET @Resultado = @FilingId;
        SET @Mensaje = 'Declaracion generada exitosamente con ' + CAST(@EmpCount AS NVARCHAR(10)) + ' empleado(s).';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SET @Resultado = -99;
        SET @Mensaje = ERROR_MESSAGE();
    END CATCH
END
GO

-- =============================================================================
-- 8. usp_HR_Filing_GetSummary
--    Obtener cabecera y detalles de una declaracion.
-- =============================================================================
IF OBJECT_ID('dbo.usp_HR_Filing_GetSummary', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_HR_Filing_GetSummary;
GO

CREATE PROCEDURE dbo.usp_HR_Filing_GetSummary
    @ObligationFilingId INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Resultado 1: Cabecera
    SELECT
        f.ObligationFilingId,
        f.CompanyId,
        f.LegalObligationId,
        lo.CountryCode,
        lo.Code AS ObligationCode,
        lo.Name AS ObligationName,
        lo.InstitutionName,
        lo.ObligationType,
        lo.CalculationBasis,
        lo.EmployerRate AS BaseEmployerRate,
        lo.EmployeeRate AS BaseEmployeeRate,
        f.FilingPeriodStart,
        f.FilingPeriodEnd,
        f.DueDate,
        f.FiledDate,
        f.ConfirmationNumber,
        f.TotalEmployerAmount,
        f.TotalEmployeeAmount,
        f.TotalAmount,
        f.EmployeeCount,
        f.Status,
        f.FiledByUserId,
        f.DocumentUrl,
        f.Notes,
        f.CreatedAt,
        f.UpdatedAt
    FROM hr.ObligationFiling f
    INNER JOIN hr.LegalObligation lo ON lo.LegalObligationId = f.LegalObligationId
    WHERE f.ObligationFilingId = @ObligationFilingId;

    -- Resultado 2: Detalle por empleado
    SELECT
        d.DetailId,
        d.ObligationFilingId,
        d.EmployeeId,
        e.EmployeeCode,
        e.EmployeeName,
        d.BaseSalary,
        d.EmployerAmount,
        d.EmployeeAmount,
        d.EmployerAmount + d.EmployeeAmount AS TotalAmount,
        d.DaysWorked,
        d.NoveltyType
    FROM hr.ObligationFilingDetail d
    INNER JOIN master.Employee e ON e.EmployeeId = d.EmployeeId
    WHERE d.ObligationFilingId = @ObligationFilingId
    ORDER BY e.EmployeeName;
END
GO

-- =============================================================================
-- 9. usp_HR_Filing_MarkFiled
--    Marcar una declaracion como presentada (FILED).
-- =============================================================================
IF OBJECT_ID('dbo.usp_HR_Filing_MarkFiled', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_HR_Filing_MarkFiled;
GO

CREATE PROCEDURE dbo.usp_HR_Filing_MarkFiled
    @ObligationFilingId INT,
    @FiledDate          DATE            = NULL,
    @ConfirmationNumber NVARCHAR(100)   = NULL,
    @FiledByUserId      INT             = NULL,
    @DocumentUrl        NVARCHAR(500)   = NULL,
    @Notes              NVARCHAR(500)   = NULL,
    @Resultado          INT             OUTPUT,
    @Mensaje            NVARCHAR(500)   OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Resultado = 0;
    SET @Mensaje = '';

    DECLARE @CurrentStatus NVARCHAR(15);

    SELECT @CurrentStatus = Status
    FROM hr.ObligationFiling
    WHERE ObligationFilingId = @ObligationFilingId;

    IF @CurrentStatus IS NULL
    BEGIN
        SET @Resultado = -1;
        SET @Mensaje = 'No se encontro la declaracion indicada.';
        RETURN;
    END

    IF @CurrentStatus NOT IN ('PENDING', 'LATE', 'REJECTED')
    BEGIN
        SET @Resultado = -2;
        SET @Mensaje = 'Solo se pueden marcar como presentadas las declaraciones en estado PENDING, LATE o REJECTED. Estado actual: ' + @CurrentStatus;
        RETURN;
    END

    IF @FiledDate IS NULL
        SET @FiledDate = CAST(SYSUTCDATETIME() AS DATE);

    BEGIN TRY
        UPDATE hr.ObligationFiling SET
            Status              = 'FILED',
            FiledDate           = @FiledDate,
            ConfirmationNumber  = @ConfirmationNumber,
            FiledByUserId       = @FiledByUserId,
            DocumentUrl         = @DocumentUrl,
            Notes               = COALESCE(@Notes, Notes),
            UpdatedAt           = SYSUTCDATETIME()
        WHERE ObligationFilingId = @ObligationFilingId;

        SET @Resultado = @ObligationFilingId;
        SET @Mensaje = 'Declaracion marcada como presentada exitosamente.';
    END TRY
    BEGIN CATCH
        SET @Resultado = -99;
        SET @Mensaje = ERROR_MESSAGE();
    END CATCH
END
GO

-- =============================================================================
-- 10. usp_HR_Filing_List
--     Listado paginado de declaraciones.
-- =============================================================================
IF OBJECT_ID('dbo.usp_HR_Filing_List', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_HR_Filing_List;
GO

CREATE PROCEDURE dbo.usp_HR_Filing_List
    @CompanyId          INT             = NULL,
    @LegalObligationId  INT             = NULL,
    @CountryCode        CHAR(2)         = NULL,
    @Status             NVARCHAR(15)    = NULL,
    @FromDate           DATE            = NULL,
    @ToDate             DATE            = NULL,
    @Page               INT             = 1,
    @Limit              INT             = 50,
    @TotalCount         INT             OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    IF @Page < 1 SET @Page = 1;
    IF @Limit < 1 SET @Limit = 50;
    IF @Limit > 500 SET @Limit = 500;

    SELECT @TotalCount = COUNT(*)
    FROM hr.ObligationFiling f
    INNER JOIN hr.LegalObligation lo ON lo.LegalObligationId = f.LegalObligationId
    WHERE (@CompanyId          IS NULL OR f.CompanyId          = @CompanyId)
      AND (@LegalObligationId  IS NULL OR f.LegalObligationId  = @LegalObligationId)
      AND (@CountryCode        IS NULL OR lo.CountryCode        = @CountryCode)
      AND (@Status             IS NULL OR f.Status              = @Status)
      AND (@FromDate           IS NULL OR f.FilingPeriodStart  >= @FromDate)
      AND (@ToDate             IS NULL OR f.FilingPeriodEnd    <= @ToDate);

    SELECT
        f.ObligationFilingId,
        f.CompanyId,
        f.LegalObligationId,
        lo.CountryCode,
        lo.Code AS ObligationCode,
        lo.Name AS ObligationName,
        lo.InstitutionName,
        f.FilingPeriodStart,
        f.FilingPeriodEnd,
        f.DueDate,
        f.FiledDate,
        f.ConfirmationNumber,
        f.TotalEmployerAmount,
        f.TotalEmployeeAmount,
        f.TotalAmount,
        f.EmployeeCount,
        f.Status,
        f.CreatedAt
    FROM hr.ObligationFiling f
    INNER JOIN hr.LegalObligation lo ON lo.LegalObligationId = f.LegalObligationId
    WHERE (@CompanyId          IS NULL OR f.CompanyId          = @CompanyId)
      AND (@LegalObligationId  IS NULL OR f.LegalObligationId  = @LegalObligationId)
      AND (@CountryCode        IS NULL OR lo.CountryCode        = @CountryCode)
      AND (@Status             IS NULL OR f.Status              = @Status)
      AND (@FromDate           IS NULL OR f.FilingPeriodStart  >= @FromDate)
      AND (@ToDate             IS NULL OR f.FilingPeriodEnd    <= @ToDate)
    ORDER BY f.FilingPeriodStart DESC, lo.Code
    OFFSET (@Page - 1) * @Limit ROWS
    FETCH NEXT @Limit ROWS ONLY;
END
GO

-- =============================================================================
-- SEED DATA - Obligaciones legales de Venezuela (VE)
-- =============================================================================
PRINT '=== Insertando seed data de obligaciones legales VE ===';

-- VE_SSO: Seguro Social Obligatorio / IVSS
IF NOT EXISTS (SELECT 1 FROM hr.LegalObligation WHERE CountryCode = 'VE' AND Code = 'VE_SSO')
BEGIN
    INSERT INTO hr.LegalObligation (
        CountryCode, Code, Name, InstitutionName, ObligationType,
        CalculationBasis, SalaryCap, SalaryCapUnit, EmployerRate, EmployeeRate,
        RateVariableByRisk, FilingFrequency, FilingDeadlineRule,
        EffectiveFrom, IsActive, Notes
    )
    VALUES (
        'VE', 'VE_SSO', 'Seguro Social Obligatorio', 'IVSS', 'CONTRIBUTION',
        'NORMAL_SALARY', 5, 'MIN_WAGES', 9.00000, 4.00000,
        1, 'MONTHLY', 'Primeros 5 dias habiles del mes siguiente',
        '2000-01-01', 1, 'Tasa base clase I. Consultar tabla de riesgo para clases II-IV.'
    );
END

-- VE_FAOV: Fondo de Ahorro Obligatorio para la Vivienda / BANAVIH
IF NOT EXISTS (SELECT 1 FROM hr.LegalObligation WHERE CountryCode = 'VE' AND Code = 'VE_FAOV')
BEGIN
    INSERT INTO hr.LegalObligation (
        CountryCode, Code, Name, InstitutionName, ObligationType,
        CalculationBasis, EmployerRate, EmployeeRate,
        RateVariableByRisk, FilingFrequency, FilingDeadlineRule,
        EffectiveFrom, IsActive, Notes
    )
    VALUES (
        'VE', 'VE_FAOV', 'Fondo de Ahorro Obligatorio para la Vivienda', 'BANAVIH', 'CONTRIBUTION',
        'INTEGRAL_SALARY', 2.00000, 1.00000,
        0, 'MONTHLY', 'Primeros 5 dias habiles del mes siguiente',
        '2000-01-01', 1, 'Base: salario integral (salario + alicuota utilidades + alicuota vacaciones).'
    );
END

-- VE_LRPE: Regimen Prestacional de Empleo (Paro Forzoso)
IF NOT EXISTS (SELECT 1 FROM hr.LegalObligation WHERE CountryCode = 'VE' AND Code = 'VE_LRPE')
BEGIN
    INSERT INTO hr.LegalObligation (
        CountryCode, Code, Name, InstitutionName, ObligationType,
        CalculationBasis, EmployerRate, EmployeeRate,
        RateVariableByRisk, FilingFrequency, FilingDeadlineRule,
        EffectiveFrom, IsActive, Notes
    )
    VALUES (
        'VE', 'VE_LRPE', 'Regimen Prestacional de Empleo (Paro Forzoso)', 'IVSS', 'CONTRIBUTION',
        'NORMAL_SALARY', 2.00000, 0.50000,
        0, 'MONTHLY', 'Primeros 5 dias habiles del mes siguiente',
        '2000-01-01', 1, 'Paro forzoso - Ley del Regimen Prestacional de Empleo.'
    );
END

-- VE_INCE: Instituto Nacional de Capacitacion y Educacion Socialista
IF NOT EXISTS (SELECT 1 FROM hr.LegalObligation WHERE CountryCode = 'VE' AND Code = 'VE_INCE')
BEGIN
    INSERT INTO hr.LegalObligation (
        CountryCode, Code, Name, InstitutionName, ObligationType,
        CalculationBasis, EmployerRate, EmployeeRate,
        RateVariableByRisk, FilingFrequency, FilingDeadlineRule,
        EffectiveFrom, IsActive, Notes
    )
    VALUES (
        'VE', 'VE_INCE', 'INCE - Aporte Patronal', 'INCE', 'CONTRIBUTION',
        'GROSS_PAYROLL', 2.00000, 0.00000,
        0, 'QUARTERLY', 'Dentro de los 5 dias habiles despues del cierre del trimestre',
        '2000-01-01', 1, 'Empleado aporta 0.5% sobre utilidades (manejado por separado en nomina).'
    );
END

-- VE_SSO Niveles de riesgo (clases I a IV)
DECLARE @SsoId INT;
SELECT @SsoId = LegalObligationId FROM hr.LegalObligation WHERE CountryCode = 'VE' AND Code = 'VE_SSO';

IF @SsoId IS NOT NULL
BEGIN
    IF NOT EXISTS (SELECT 1 FROM hr.ObligationRiskLevel WHERE LegalObligationId = @SsoId AND RiskLevel = 1)
        INSERT INTO hr.ObligationRiskLevel (LegalObligationId, RiskLevel, RiskDescription, EmployerRate, EmployeeRate)
        VALUES (@SsoId, 1, 'Riesgo minimo', 9.00000, 4.00000);

    IF NOT EXISTS (SELECT 1 FROM hr.ObligationRiskLevel WHERE LegalObligationId = @SsoId AND RiskLevel = 2)
        INSERT INTO hr.ObligationRiskLevel (LegalObligationId, RiskLevel, RiskDescription, EmployerRate, EmployeeRate)
        VALUES (@SsoId, 2, 'Riesgo medio', 10.00000, 4.00000);

    IF NOT EXISTS (SELECT 1 FROM hr.ObligationRiskLevel WHERE LegalObligationId = @SsoId AND RiskLevel = 3)
        INSERT INTO hr.ObligationRiskLevel (LegalObligationId, RiskLevel, RiskDescription, EmployerRate, EmployeeRate)
        VALUES (@SsoId, 3, 'Riesgo alto', 11.00000, 4.00000);

    IF NOT EXISTS (SELECT 1 FROM hr.ObligationRiskLevel WHERE LegalObligationId = @SsoId AND RiskLevel = 4)
        INSERT INTO hr.ObligationRiskLevel (LegalObligationId, RiskLevel, RiskDescription, EmployerRate, EmployeeRate)
        VALUES (@SsoId, 4, 'Riesgo maximo', 12.00000, 4.00000);
END

PRINT '=== Seed data VE completado ===';
GO

PRINT '=== sp_rrhh_obligaciones_legales.sql ejecutado exitosamente ===';
GO
