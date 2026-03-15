-- =============================================
-- Stored Procedures: Salud Ocupacional / Occupational Health
-- Cubre: INPSASEL (VE), OSHA (US), PRL (ES), SG-SST (CO)
-- Tablas: hr.OccupationalHealth, hr.MedicalExam, hr.MedicalOrder,
--         hr.TrainingRecord, hr.SafetyCommittee, hr.SafetyCommitteeMember,
--         hr.SafetyCommitteeMeeting
-- Compatible con: SQL Server 2012+
-- =============================================
USE DatqBoxWeb;
GO
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

-- =============================================================
-- SCHEMA
-- =============================================================
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'hr')
    EXEC('CREATE SCHEMA hr');
GO

-- =============================================================
-- TABLES
-- =============================================================

-- 1) hr.OccupationalHealth
IF OBJECT_ID('hr.OccupationalHealth', 'U') IS NULL
BEGIN
    CREATE TABLE hr.OccupationalHealth (
        OccupationalHealthId    INT IDENTITY(1,1) PRIMARY KEY,
        CompanyId               INT             NOT NULL,
        CountryCode             CHAR(2)         NOT NULL,
        RecordType              NVARCHAR(25)    NOT NULL,       -- ACCIDENT, DISEASE, NEAR_MISS, INSPECTION, RISK_NOTIFICATION
        EmployeeId              BIGINT          NULL,
        EmployeeCode            NVARCHAR(24)    NULL,
        EmployeeName            NVARCHAR(200)   NULL,
        OccurrenceDate          DATETIME2(0)    NOT NULL,
        ReportDeadline          DATETIME2(0)    NULL,
        ReportedDate            DATETIME2(0)    NULL,
        Severity                NVARCHAR(15)    NULL,           -- MINOR, MODERATE, SEVERE, FATAL
        BodyPartAffected        NVARCHAR(100)   NULL,
        DaysLost                INT             NULL,
        Location                NVARCHAR(200)   NULL,
        Description             NVARCHAR(MAX)   NULL,
        RootCause               NVARCHAR(500)   NULL,
        CorrectiveAction        NVARCHAR(500)   NULL,
        InvestigationDueDate    DATE            NULL,
        InvestigationCompletedDate DATE         NULL,
        InstitutionReference    NVARCHAR(100)   NULL,
        Status                  NVARCHAR(15)    NOT NULL DEFAULT 'OPEN', -- OPEN, REPORTED, INVESTIGATING, CLOSED
        DocumentUrl             NVARCHAR(500)   NULL,
        Notes                   NVARCHAR(500)   NULL,
        CreatedBy               INT             NULL,
        CreatedAt               DATETIME2(0)    NOT NULL DEFAULT SYSUTCDATETIME(),
        UpdatedAt               DATETIME2(0)    NOT NULL DEFAULT SYSUTCDATETIME()
    );
END;
GO

-- 2) hr.MedicalExam
IF OBJECT_ID('hr.MedicalExam', 'U') IS NULL
BEGIN
    CREATE TABLE hr.MedicalExam (
        MedicalExamId   INT IDENTITY(1,1) PRIMARY KEY,
        CompanyId       INT             NOT NULL,
        EmployeeId      BIGINT          NULL,
        EmployeeCode    NVARCHAR(24)    NOT NULL,
        EmployeeName    NVARCHAR(200)   NOT NULL,
        ExamType        NVARCHAR(20)    NOT NULL,       -- PRE_EMPLOYMENT, PERIODIC, POST_VACATION, EXIT, SPECIAL
        ExamDate        DATE            NOT NULL,
        NextDueDate     DATE            NULL,
        Result          NVARCHAR(20)    NOT NULL DEFAULT 'PENDING', -- FIT, FIT_WITH_RESTRICTIONS, UNFIT, PENDING
        Restrictions    NVARCHAR(500)   NULL,
        PhysicianName   NVARCHAR(200)   NULL,
        ClinicName      NVARCHAR(200)   NULL,
        DocumentUrl     NVARCHAR(500)   NULL,
        Notes           NVARCHAR(500)   NULL,
        CreatedAt       DATETIME2(0)    NOT NULL DEFAULT SYSUTCDATETIME(),
        UpdatedAt       DATETIME2(0)    NOT NULL DEFAULT SYSUTCDATETIME()
    );
END;
GO

-- 3) hr.MedicalOrder
IF OBJECT_ID('hr.MedicalOrder', 'U') IS NULL
BEGIN
    CREATE TABLE hr.MedicalOrder (
        MedicalOrderId  INT IDENTITY(1,1) PRIMARY KEY,
        CompanyId       INT             NOT NULL,
        EmployeeId      BIGINT          NULL,
        EmployeeCode    NVARCHAR(24)    NOT NULL,
        EmployeeName    NVARCHAR(200)   NOT NULL,
        OrderType       NVARCHAR(20)    NOT NULL,       -- MEDICAL, PHARMACY, LAB, REFERRAL
        OrderDate       DATE            NOT NULL,
        Diagnosis       NVARCHAR(500)   NULL,
        PhysicianName   NVARCHAR(200)   NULL,
        Prescriptions   NVARCHAR(MAX)   NULL,
        EstimatedCost   DECIMAL(18,2)   NULL,
        ApprovedAmount  DECIMAL(18,2)   NULL,
        Status          NVARCHAR(15)    NOT NULL DEFAULT 'PENDIENTE', -- PENDIENTE, APROBADA, PROCESADA, RECHAZADA
        ApprovedBy      INT             NULL,
        ApprovedAt      DATETIME2(0)    NULL,
        DocumentUrl     NVARCHAR(500)   NULL,
        Notes           NVARCHAR(500)   NULL,
        CreatedAt       DATETIME2(0)    NOT NULL DEFAULT SYSUTCDATETIME(),
        UpdatedAt       DATETIME2(0)    NOT NULL DEFAULT SYSUTCDATETIME()
    );
END;
GO

-- 4) hr.TrainingRecord
IF OBJECT_ID('hr.TrainingRecord', 'U') IS NULL
BEGIN
    CREATE TABLE hr.TrainingRecord (
        TrainingRecordId    INT IDENTITY(1,1) PRIMARY KEY,
        CompanyId           INT             NOT NULL,
        CountryCode         CHAR(2)         NOT NULL,
        TrainingType        NVARCHAR(25)    NOT NULL,   -- SAFETY, REGULATORY, TECHNICAL, APPRENTICESHIP, INDUCTION
        Title               NVARCHAR(200)   NOT NULL,
        Provider            NVARCHAR(200)   NULL,
        StartDate           DATE            NOT NULL,
        EndDate             DATE            NULL,
        DurationHours       DECIMAL(6,2)    NOT NULL,
        EmployeeId          BIGINT          NULL,
        EmployeeCode        NVARCHAR(24)    NOT NULL,
        EmployeeName        NVARCHAR(200)   NOT NULL,
        CertificateNumber   NVARCHAR(100)   NULL,
        CertificateUrl      NVARCHAR(500)   NULL,
        Result              NVARCHAR(15)    NULL,       -- PASSED, FAILED, IN_PROGRESS, ATTENDED
        IsRegulatory        BIT             NOT NULL DEFAULT 0,
        Notes               NVARCHAR(500)   NULL,
        CreatedAt           DATETIME2(0)    NOT NULL DEFAULT SYSUTCDATETIME(),
        UpdatedAt           DATETIME2(0)    NOT NULL DEFAULT SYSUTCDATETIME()
    );
END;
GO

-- 5) hr.SafetyCommittee
IF OBJECT_ID('hr.SafetyCommittee', 'U') IS NULL
BEGIN
    CREATE TABLE hr.SafetyCommittee (
        SafetyCommitteeId   INT IDENTITY(1,1) PRIMARY KEY,
        CompanyId           INT             NOT NULL,
        CountryCode         CHAR(2)         NOT NULL,
        CommitteeName       NVARCHAR(200)   NOT NULL,
        FormationDate       DATE            NOT NULL,
        MeetingFrequency    NVARCHAR(15)    NOT NULL DEFAULT 'MONTHLY',
        IsActive            BIT             NOT NULL DEFAULT 1,
        CreatedAt           DATETIME2(0)    NOT NULL DEFAULT SYSUTCDATETIME()
    );
END;
GO

-- 6) hr.SafetyCommitteeMember
IF OBJECT_ID('hr.SafetyCommitteeMember', 'U') IS NULL
BEGIN
    CREATE TABLE hr.SafetyCommitteeMember (
        MemberId            INT IDENTITY(1,1) PRIMARY KEY,
        SafetyCommitteeId   INT             NOT NULL,
        EmployeeId          BIGINT          NULL,
        EmployeeCode        NVARCHAR(24)    NOT NULL,
        EmployeeName        NVARCHAR(200)   NOT NULL,
        Role                NVARCHAR(25)    NOT NULL,   -- PRESIDENT, SECRETARY, DELEGATE, EMPLOYER_REP
        StartDate           DATE            NOT NULL,
        EndDate             DATE            NULL,
        CONSTRAINT FK_CommitteeMember_Committee FOREIGN KEY (SafetyCommitteeId)
            REFERENCES hr.SafetyCommittee (SafetyCommitteeId)
    );
END;
GO

-- 7) hr.SafetyCommitteeMeeting
IF OBJECT_ID('hr.SafetyCommitteeMeeting', 'U') IS NULL
BEGIN
    CREATE TABLE hr.SafetyCommitteeMeeting (
        MeetingId           INT IDENTITY(1,1) PRIMARY KEY,
        SafetyCommitteeId   INT             NOT NULL,
        MeetingDate         DATETIME2(0)    NOT NULL,
        MinutesUrl          NVARCHAR(500)   NULL,
        TopicsSummary       NVARCHAR(MAX)   NULL,
        ActionItems         NVARCHAR(MAX)   NULL,
        CreatedAt           DATETIME2(0)    NOT NULL DEFAULT SYSUTCDATETIME(),
        CONSTRAINT FK_CommitteeMeeting_Committee FOREIGN KEY (SafetyCommitteeId)
            REFERENCES hr.SafetyCommittee (SafetyCommitteeId)
    );
END;
GO

-- =============================================================
-- INDEXES
-- =============================================================

-- OccupationalHealth
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_OccHealth_Company_Status' AND object_id = OBJECT_ID('hr.OccupationalHealth'))
    CREATE NONCLUSTERED INDEX IX_OccHealth_Company_Status
        ON hr.OccupationalHealth (CompanyId, Status)
        INCLUDE (RecordType, OccurrenceDate, EmployeeCode, Severity);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_OccHealth_Company_RecordType' AND object_id = OBJECT_ID('hr.OccupationalHealth'))
    CREATE NONCLUSTERED INDEX IX_OccHealth_Company_RecordType
        ON hr.OccupationalHealth (CompanyId, RecordType, OccurrenceDate DESC);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_OccHealth_Employee' AND object_id = OBJECT_ID('hr.OccupationalHealth'))
    CREATE NONCLUSTERED INDEX IX_OccHealth_Employee
        ON hr.OccupationalHealth (EmployeeId)
        WHERE EmployeeId IS NOT NULL;
GO

-- MedicalExam
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_MedExam_Company_Type' AND object_id = OBJECT_ID('hr.MedicalExam'))
    CREATE NONCLUSTERED INDEX IX_MedExam_Company_Type
        ON hr.MedicalExam (CompanyId, ExamType, ExamDate DESC);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_MedExam_NextDue' AND object_id = OBJECT_ID('hr.MedicalExam'))
    CREATE NONCLUSTERED INDEX IX_MedExam_NextDue
        ON hr.MedicalExam (CompanyId, NextDueDate)
        WHERE NextDueDate IS NOT NULL;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_MedExam_Employee' AND object_id = OBJECT_ID('hr.MedicalExam'))
    CREATE NONCLUSTERED INDEX IX_MedExam_Employee
        ON hr.MedicalExam (EmployeeCode, CompanyId);
GO

-- MedicalOrder
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_MedOrder_Company_Status' AND object_id = OBJECT_ID('hr.MedicalOrder'))
    CREATE NONCLUSTERED INDEX IX_MedOrder_Company_Status
        ON hr.MedicalOrder (CompanyId, Status, OrderDate DESC);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_MedOrder_Employee' AND object_id = OBJECT_ID('hr.MedicalOrder'))
    CREATE NONCLUSTERED INDEX IX_MedOrder_Employee
        ON hr.MedicalOrder (EmployeeCode, CompanyId);
GO

-- TrainingRecord
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Training_Company_Type' AND object_id = OBJECT_ID('hr.TrainingRecord'))
    CREATE NONCLUSTERED INDEX IX_Training_Company_Type
        ON hr.TrainingRecord (CompanyId, TrainingType, StartDate DESC);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Training_Employee' AND object_id = OBJECT_ID('hr.TrainingRecord'))
    CREATE NONCLUSTERED INDEX IX_Training_Employee
        ON hr.TrainingRecord (EmployeeCode, CompanyId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Training_Regulatory' AND object_id = OBJECT_ID('hr.TrainingRecord'))
    CREATE NONCLUSTERED INDEX IX_Training_Regulatory
        ON hr.TrainingRecord (CompanyId, IsRegulatory)
        WHERE IsRegulatory = 1;
GO

-- SafetyCommittee
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Committee_Company' AND object_id = OBJECT_ID('hr.SafetyCommittee'))
    CREATE NONCLUSTERED INDEX IX_Committee_Company
        ON hr.SafetyCommittee (CompanyId, IsActive);
GO

-- SafetyCommitteeMember
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_CommitteeMember_Committee' AND object_id = OBJECT_ID('hr.SafetyCommitteeMember'))
    CREATE NONCLUSTERED INDEX IX_CommitteeMember_Committee
        ON hr.SafetyCommitteeMember (SafetyCommitteeId);
GO

-- SafetyCommitteeMeeting
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_CommitteeMeeting_Committee' AND object_id = OBJECT_ID('hr.SafetyCommitteeMeeting'))
    CREATE NONCLUSTERED INDEX IX_CommitteeMeeting_Committee
        ON hr.SafetyCommitteeMeeting (SafetyCommitteeId, MeetingDate DESC);
GO


-- =============================================================
-- =============================================================
-- STORED PROCEDURES
-- =============================================================
-- =============================================================


-- =============================================================
-- 1) usp_HR_OccHealth_Create
-- =============================================================
IF OBJECT_ID('dbo.usp_HR_OccHealth_Create', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_HR_OccHealth_Create;
GO

CREATE PROCEDURE dbo.usp_HR_OccHealth_Create
    @CompanyId              INT,
    @CountryCode            CHAR(2),
    @RecordType             NVARCHAR(25),
    @EmployeeId             BIGINT          = NULL,
    @EmployeeCode           NVARCHAR(24)    = NULL,
    @EmployeeName           NVARCHAR(200)   = NULL,
    @OccurrenceDate         DATETIME2(0),
    @ReportDeadline         DATETIME2(0)    = NULL,
    @ReportedDate           DATETIME2(0)    = NULL,
    @Severity               NVARCHAR(15)    = NULL,
    @BodyPartAffected       NVARCHAR(100)   = NULL,
    @DaysLost               INT             = NULL,
    @Location               NVARCHAR(200)   = NULL,
    @Description            NVARCHAR(MAX)   = NULL,
    @RootCause              NVARCHAR(500)   = NULL,
    @CorrectiveAction       NVARCHAR(500)   = NULL,
    @InvestigationDueDate   DATE            = NULL,
    @InstitutionReference   NVARCHAR(100)   = NULL,
    @DocumentUrl            NVARCHAR(500)   = NULL,
    @Notes                  NVARCHAR(500)   = NULL,
    @CreatedBy              INT             = NULL,
    @Resultado              INT             OUTPUT,
    @Mensaje                NVARCHAR(500)   OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Resultado = 0;
    SET @Mensaje   = '';

    IF @RecordType NOT IN ('ACCIDENT','DISEASE','NEAR_MISS','INSPECTION','RISK_NOTIFICATION')
    BEGIN
        SET @Resultado = -1;
        SET @Mensaje   = 'Tipo de registro no valido.';
        RETURN;
    END

    IF @Severity IS NOT NULL AND @Severity NOT IN ('MINOR','MODERATE','SEVERE','FATAL')
    BEGIN
        SET @Resultado = -1;
        SET @Mensaje   = 'Severidad no valida.';
        RETURN;
    END

    BEGIN TRY
        INSERT INTO hr.OccupationalHealth (
            CompanyId, CountryCode, RecordType,
            EmployeeId, EmployeeCode, EmployeeName,
            OccurrenceDate, ReportDeadline, ReportedDate,
            Severity, BodyPartAffected, DaysLost,
            Location, Description, RootCause, CorrectiveAction,
            InvestigationDueDate, InstitutionReference,
            Status, DocumentUrl, Notes, CreatedBy,
            CreatedAt, UpdatedAt
        )
        VALUES (
            @CompanyId, @CountryCode, @RecordType,
            @EmployeeId, @EmployeeCode, @EmployeeName,
            @OccurrenceDate, @ReportDeadline, @ReportedDate,
            @Severity, @BodyPartAffected, @DaysLost,
            @Location, @Description, @RootCause, @CorrectiveAction,
            @InvestigationDueDate, @InstitutionReference,
            'OPEN', @DocumentUrl, @Notes, @CreatedBy,
            SYSUTCDATETIME(), SYSUTCDATETIME()
        );

        SET @Resultado = SCOPE_IDENTITY();
        SET @Mensaje   = 'Registro de salud ocupacional creado exitosamente.';
    END TRY
    BEGIN CATCH
        SET @Resultado = -1;
        SET @Mensaje   = ERROR_MESSAGE();
    END CATCH
END;
GO


-- =============================================================
-- 2) usp_HR_OccHealth_Update
-- =============================================================
IF OBJECT_ID('dbo.usp_HR_OccHealth_Update', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_HR_OccHealth_Update;
GO

CREATE PROCEDURE dbo.usp_HR_OccHealth_Update
    @OccupationalHealthId       INT,
    @CompanyId                  INT,
    @ReportedDate               DATETIME2(0)    = NULL,
    @Severity                   NVARCHAR(15)    = NULL,
    @BodyPartAffected           NVARCHAR(100)   = NULL,
    @DaysLost                   INT             = NULL,
    @Location                   NVARCHAR(200)   = NULL,
    @Description                NVARCHAR(MAX)   = NULL,
    @RootCause                  NVARCHAR(500)   = NULL,
    @CorrectiveAction           NVARCHAR(500)   = NULL,
    @InvestigationDueDate       DATE            = NULL,
    @InvestigationCompletedDate DATE            = NULL,
    @InstitutionReference       NVARCHAR(100)   = NULL,
    @Status                     NVARCHAR(15)    = NULL,
    @DocumentUrl                NVARCHAR(500)   = NULL,
    @Notes                      NVARCHAR(500)   = NULL,
    @Resultado                  INT             OUTPUT,
    @Mensaje                    NVARCHAR(500)   OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Resultado = 0;
    SET @Mensaje   = '';

    IF NOT EXISTS (SELECT 1 FROM hr.OccupationalHealth
                   WHERE OccupationalHealthId = @OccupationalHealthId AND CompanyId = @CompanyId)
    BEGIN
        SET @Resultado = -1;
        SET @Mensaje   = 'Registro no encontrado.';
        RETURN;
    END

    IF @Status IS NOT NULL AND @Status NOT IN ('OPEN','REPORTED','INVESTIGATING','CLOSED')
    BEGIN
        SET @Resultado = -1;
        SET @Mensaje   = 'Estado no valido.';
        RETURN;
    END

    IF @Severity IS NOT NULL AND @Severity NOT IN ('MINOR','MODERATE','SEVERE','FATAL')
    BEGIN
        SET @Resultado = -1;
        SET @Mensaje   = 'Severidad no valida.';
        RETURN;
    END

    BEGIN TRY
        UPDATE hr.OccupationalHealth
        SET
            ReportedDate               = ISNULL(@ReportedDate, ReportedDate),
            Severity                   = ISNULL(@Severity, Severity),
            BodyPartAffected           = ISNULL(@BodyPartAffected, BodyPartAffected),
            DaysLost                   = ISNULL(@DaysLost, DaysLost),
            Location                   = ISNULL(@Location, Location),
            Description                = ISNULL(@Description, Description),
            RootCause                  = ISNULL(@RootCause, RootCause),
            CorrectiveAction           = ISNULL(@CorrectiveAction, CorrectiveAction),
            InvestigationDueDate       = ISNULL(@InvestigationDueDate, InvestigationDueDate),
            InvestigationCompletedDate = ISNULL(@InvestigationCompletedDate, InvestigationCompletedDate),
            InstitutionReference       = ISNULL(@InstitutionReference, InstitutionReference),
            Status                     = ISNULL(@Status, Status),
            DocumentUrl                = ISNULL(@DocumentUrl, DocumentUrl),
            Notes                      = ISNULL(@Notes, Notes),
            UpdatedAt                  = SYSUTCDATETIME()
        WHERE OccupationalHealthId = @OccupationalHealthId
          AND CompanyId = @CompanyId;

        SET @Resultado = @OccupationalHealthId;
        SET @Mensaje   = 'Registro actualizado exitosamente.';
    END TRY
    BEGIN CATCH
        SET @Resultado = -1;
        SET @Mensaje   = ERROR_MESSAGE();
    END CATCH
END;
GO


-- =============================================================
-- 3) usp_HR_OccHealth_List
-- =============================================================
IF OBJECT_ID('dbo.usp_HR_OccHealth_List', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_HR_OccHealth_List;
GO

CREATE PROCEDURE dbo.usp_HR_OccHealth_List
    @CompanyId      INT,
    @RecordType     NVARCHAR(25)    = NULL,
    @Status         NVARCHAR(15)    = NULL,
    @EmployeeCode   NVARCHAR(24)    = NULL,
    @CountryCode    CHAR(2)         = NULL,
    @FromDate       DATE            = NULL,
    @ToDate         DATE            = NULL,
    @Page           INT             = 1,
    @Limit          INT             = 50,
    @TotalCount     INT             OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    IF @Page  < 1   SET @Page  = 1;
    IF @Limit < 1   SET @Limit = 50;
    IF @Limit > 500 SET @Limit = 500;

    SELECT @TotalCount = COUNT(*)
    FROM hr.OccupationalHealth
    WHERE CompanyId = @CompanyId
      AND (@RecordType   IS NULL OR RecordType   = @RecordType)
      AND (@Status       IS NULL OR Status       = @Status)
      AND (@EmployeeCode IS NULL OR EmployeeCode = @EmployeeCode)
      AND (@CountryCode  IS NULL OR CountryCode  = @CountryCode)
      AND (@FromDate     IS NULL OR OccurrenceDate >= @FromDate)
      AND (@ToDate       IS NULL OR OccurrenceDate <= @ToDate);

    SELECT
        OccupationalHealthId,
        CompanyId,
        CountryCode,
        RecordType,
        EmployeeId,
        EmployeeCode,
        EmployeeName,
        OccurrenceDate,
        ReportDeadline,
        ReportedDate,
        Severity,
        BodyPartAffected,
        DaysLost,
        Location,
        Description,
        RootCause,
        CorrectiveAction,
        InvestigationDueDate,
        InvestigationCompletedDate,
        InstitutionReference,
        Status,
        DocumentUrl,
        Notes,
        CreatedBy,
        CreatedAt,
        UpdatedAt
    FROM hr.OccupationalHealth
    WHERE CompanyId = @CompanyId
      AND (@RecordType   IS NULL OR RecordType   = @RecordType)
      AND (@Status       IS NULL OR Status       = @Status)
      AND (@EmployeeCode IS NULL OR EmployeeCode = @EmployeeCode)
      AND (@CountryCode  IS NULL OR CountryCode  = @CountryCode)
      AND (@FromDate     IS NULL OR OccurrenceDate >= @FromDate)
      AND (@ToDate       IS NULL OR OccurrenceDate <= @ToDate)
    ORDER BY OccurrenceDate DESC, OccupationalHealthId DESC
    OFFSET ((@Page - 1) * @Limit) ROWS
    FETCH NEXT @Limit ROWS ONLY;
END;
GO


-- =============================================================
-- 4) usp_HR_OccHealth_Get
-- =============================================================
IF OBJECT_ID('dbo.usp_HR_OccHealth_Get', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_HR_OccHealth_Get;
GO

CREATE PROCEDURE dbo.usp_HR_OccHealth_Get
    @OccupationalHealthId   INT,
    @CompanyId              INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        OccupationalHealthId,
        CompanyId,
        CountryCode,
        RecordType,
        EmployeeId,
        EmployeeCode,
        EmployeeName,
        OccurrenceDate,
        ReportDeadline,
        ReportedDate,
        Severity,
        BodyPartAffected,
        DaysLost,
        Location,
        Description,
        RootCause,
        CorrectiveAction,
        InvestigationDueDate,
        InvestigationCompletedDate,
        InstitutionReference,
        Status,
        DocumentUrl,
        Notes,
        CreatedBy,
        CreatedAt,
        UpdatedAt
    FROM hr.OccupationalHealth
    WHERE OccupationalHealthId = @OccupationalHealthId
      AND CompanyId = @CompanyId;
END;
GO


-- =============================================================
-- 5) usp_HR_MedExam_Save
-- =============================================================
IF OBJECT_ID('dbo.usp_HR_MedExam_Save', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_HR_MedExam_Save;
GO

CREATE PROCEDURE dbo.usp_HR_MedExam_Save
    @MedicalExamId  INT             = NULL,  -- NULL = INSERT, otherwise UPDATE
    @CompanyId      INT,
    @EmployeeId     BIGINT          = NULL,
    @EmployeeCode   NVARCHAR(24),
    @EmployeeName   NVARCHAR(200),
    @ExamType       NVARCHAR(20),
    @ExamDate       DATE,
    @NextDueDate    DATE            = NULL,
    @Result         NVARCHAR(20)    = 'PENDING',
    @Restrictions   NVARCHAR(500)   = NULL,
    @PhysicianName  NVARCHAR(200)   = NULL,
    @ClinicName     NVARCHAR(200)   = NULL,
    @DocumentUrl    NVARCHAR(500)   = NULL,
    @Notes          NVARCHAR(500)   = NULL,
    @Resultado      INT             OUTPUT,
    @Mensaje        NVARCHAR(500)   OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Resultado = 0;
    SET @Mensaje   = '';

    IF @ExamType NOT IN ('PRE_EMPLOYMENT','PERIODIC','POST_VACATION','EXIT','SPECIAL')
    BEGIN
        SET @Resultado = -1;
        SET @Mensaje   = 'Tipo de examen no valido.';
        RETURN;
    END

    IF @Result NOT IN ('FIT','FIT_WITH_RESTRICTIONS','UNFIT','PENDING')
    BEGIN
        SET @Resultado = -1;
        SET @Mensaje   = 'Resultado de examen no valido.';
        RETURN;
    END

    BEGIN TRY
        IF @MedicalExamId IS NULL
        BEGIN
            -- INSERT
            INSERT INTO hr.MedicalExam (
                CompanyId, EmployeeId, EmployeeCode, EmployeeName,
                ExamType, ExamDate, NextDueDate, Result,
                Restrictions, PhysicianName, ClinicName,
                DocumentUrl, Notes, CreatedAt, UpdatedAt
            )
            VALUES (
                @CompanyId, @EmployeeId, @EmployeeCode, @EmployeeName,
                @ExamType, @ExamDate, @NextDueDate, @Result,
                @Restrictions, @PhysicianName, @ClinicName,
                @DocumentUrl, @Notes, SYSUTCDATETIME(), SYSUTCDATETIME()
            );

            SET @Resultado = SCOPE_IDENTITY();
            SET @Mensaje   = 'Examen medico creado exitosamente.';
        END
        ELSE
        BEGIN
            -- UPDATE
            IF NOT EXISTS (SELECT 1 FROM hr.MedicalExam
                           WHERE MedicalExamId = @MedicalExamId AND CompanyId = @CompanyId)
            BEGIN
                SET @Resultado = -1;
                SET @Mensaje   = 'Examen medico no encontrado.';
                RETURN;
            END

            UPDATE hr.MedicalExam
            SET
                EmployeeId    = ISNULL(@EmployeeId, EmployeeId),
                EmployeeCode  = @EmployeeCode,
                EmployeeName  = @EmployeeName,
                ExamType      = @ExamType,
                ExamDate      = @ExamDate,
                NextDueDate   = @NextDueDate,
                Result        = @Result,
                Restrictions  = @Restrictions,
                PhysicianName = @PhysicianName,
                ClinicName    = @ClinicName,
                DocumentUrl   = @DocumentUrl,
                Notes         = @Notes,
                UpdatedAt     = SYSUTCDATETIME()
            WHERE MedicalExamId = @MedicalExamId
              AND CompanyId = @CompanyId;

            SET @Resultado = @MedicalExamId;
            SET @Mensaje   = 'Examen medico actualizado exitosamente.';
        END
    END TRY
    BEGIN CATCH
        SET @Resultado = -1;
        SET @Mensaje   = ERROR_MESSAGE();
    END CATCH
END;
GO


-- =============================================================
-- 6) usp_HR_MedExam_List
-- =============================================================
IF OBJECT_ID('dbo.usp_HR_MedExam_List', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_HR_MedExam_List;
GO

CREATE PROCEDURE dbo.usp_HR_MedExam_List
    @CompanyId      INT,
    @ExamType       NVARCHAR(20)    = NULL,
    @Result         NVARCHAR(20)    = NULL,
    @EmployeeCode   NVARCHAR(24)    = NULL,
    @FromDate       DATE            = NULL,
    @ToDate         DATE            = NULL,
    @Page           INT             = 1,
    @Limit          INT             = 50,
    @TotalCount     INT             OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    IF @Page  < 1   SET @Page  = 1;
    IF @Limit < 1   SET @Limit = 50;
    IF @Limit > 500 SET @Limit = 500;

    SELECT @TotalCount = COUNT(*)
    FROM hr.MedicalExam
    WHERE CompanyId = @CompanyId
      AND (@ExamType     IS NULL OR ExamType     = @ExamType)
      AND (@Result       IS NULL OR Result       = @Result)
      AND (@EmployeeCode IS NULL OR EmployeeCode = @EmployeeCode)
      AND (@FromDate     IS NULL OR ExamDate    >= @FromDate)
      AND (@ToDate       IS NULL OR ExamDate    <= @ToDate);

    SELECT
        MedicalExamId,
        CompanyId,
        EmployeeId,
        EmployeeCode,
        EmployeeName,
        ExamType,
        ExamDate,
        NextDueDate,
        Result,
        Restrictions,
        PhysicianName,
        ClinicName,
        DocumentUrl,
        Notes,
        CreatedAt,
        UpdatedAt
    FROM hr.MedicalExam
    WHERE CompanyId = @CompanyId
      AND (@ExamType     IS NULL OR ExamType     = @ExamType)
      AND (@Result       IS NULL OR Result       = @Result)
      AND (@EmployeeCode IS NULL OR EmployeeCode = @EmployeeCode)
      AND (@FromDate     IS NULL OR ExamDate    >= @FromDate)
      AND (@ToDate       IS NULL OR ExamDate    <= @ToDate)
    ORDER BY ExamDate DESC, MedicalExamId DESC
    OFFSET ((@Page - 1) * @Limit) ROWS
    FETCH NEXT @Limit ROWS ONLY;
END;
GO


-- =============================================================
-- 7) usp_HR_MedExam_GetPending
--    Empleados con examenes periodicos vencidos o por vencer
-- =============================================================
IF OBJECT_ID('dbo.usp_HR_MedExam_GetPending', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_HR_MedExam_GetPending;
GO

CREATE PROCEDURE dbo.usp_HR_MedExam_GetPending
    @CompanyId      INT,
    @AsOfDate       DATE            = NULL,  -- NULL = today UTC
    @DaysAhead      INT             = 30,    -- Include exams due within N days
    @Page           INT             = 1,
    @Limit          INT             = 50,
    @TotalCount     INT             OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    IF @AsOfDate IS NULL SET @AsOfDate = CAST(SYSUTCDATETIME() AS DATE);
    IF @Page  < 1   SET @Page  = 1;
    IF @Limit < 1   SET @Limit = 50;
    IF @Limit > 500 SET @Limit = 500;

    -- Find the latest periodic exam per employee, where NextDueDate <= @AsOfDate + @DaysAhead
    SELECT @TotalCount = COUNT(*)
    FROM (
        SELECT EmployeeCode,
               ROW_NUMBER() OVER (PARTITION BY EmployeeCode ORDER BY ExamDate DESC) AS rn
        FROM hr.MedicalExam
        WHERE CompanyId = @CompanyId
          AND ExamType = 'PERIODIC'
          AND NextDueDate IS NOT NULL
          AND NextDueDate <= DATEADD(DAY, @DaysAhead, @AsOfDate)
    ) sub
    WHERE sub.rn = 1;

    ;WITH LatestExam AS (
        SELECT *,
               ROW_NUMBER() OVER (PARTITION BY EmployeeCode ORDER BY ExamDate DESC) AS rn
        FROM hr.MedicalExam
        WHERE CompanyId = @CompanyId
          AND ExamType = 'PERIODIC'
          AND NextDueDate IS NOT NULL
          AND NextDueDate <= DATEADD(DAY, @DaysAhead, @AsOfDate)
    )
    SELECT
        MedicalExamId,
        CompanyId,
        EmployeeId,
        EmployeeCode,
        EmployeeName,
        ExamType,
        ExamDate,
        NextDueDate,
        Result,
        Restrictions,
        PhysicianName,
        ClinicName,
        CASE WHEN NextDueDate < @AsOfDate THEN 1 ELSE 0 END AS IsOverdue,
        DATEDIFF(DAY, @AsOfDate, NextDueDate) AS DaysUntilDue
    FROM LatestExam
    WHERE rn = 1
    ORDER BY NextDueDate ASC
    OFFSET ((@Page - 1) * @Limit) ROWS
    FETCH NEXT @Limit ROWS ONLY;
END;
GO


-- =============================================================
-- 8) usp_HR_MedOrder_Create
-- =============================================================
IF OBJECT_ID('dbo.usp_HR_MedOrder_Create', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_HR_MedOrder_Create;
GO

CREATE PROCEDURE dbo.usp_HR_MedOrder_Create
    @CompanyId      INT,
    @EmployeeId     BIGINT          = NULL,
    @EmployeeCode   NVARCHAR(24),
    @EmployeeName   NVARCHAR(200),
    @OrderType      NVARCHAR(20),
    @OrderDate      DATE,
    @Diagnosis      NVARCHAR(500)   = NULL,
    @PhysicianName  NVARCHAR(200)   = NULL,
    @Prescriptions  NVARCHAR(MAX)   = NULL,
    @EstimatedCost  DECIMAL(18,2)   = NULL,
    @DocumentUrl    NVARCHAR(500)   = NULL,
    @Notes          NVARCHAR(500)   = NULL,
    @Resultado      INT             OUTPUT,
    @Mensaje        NVARCHAR(500)   OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Resultado = 0;
    SET @Mensaje   = '';

    IF @OrderType NOT IN ('MEDICAL','PHARMACY','LAB','REFERRAL')
    BEGIN
        SET @Resultado = -1;
        SET @Mensaje   = 'Tipo de orden no valido.';
        RETURN;
    END

    BEGIN TRY
        INSERT INTO hr.MedicalOrder (
            CompanyId, EmployeeId, EmployeeCode, EmployeeName,
            OrderType, OrderDate, Diagnosis, PhysicianName,
            Prescriptions, EstimatedCost, Status,
            DocumentUrl, Notes, CreatedAt, UpdatedAt
        )
        VALUES (
            @CompanyId, @EmployeeId, @EmployeeCode, @EmployeeName,
            @OrderType, @OrderDate, @Diagnosis, @PhysicianName,
            @Prescriptions, @EstimatedCost, 'PENDIENTE',
            @DocumentUrl, @Notes, SYSUTCDATETIME(), SYSUTCDATETIME()
        );

        SET @Resultado = SCOPE_IDENTITY();
        SET @Mensaje   = 'Orden medica creada exitosamente.';
    END TRY
    BEGIN CATCH
        SET @Resultado = -1;
        SET @Mensaje   = ERROR_MESSAGE();
    END CATCH
END;
GO


-- =============================================================
-- 9) usp_HR_MedOrder_Approve
-- =============================================================
IF OBJECT_ID('dbo.usp_HR_MedOrder_Approve', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_HR_MedOrder_Approve;
GO

CREATE PROCEDURE dbo.usp_HR_MedOrder_Approve
    @MedicalOrderId INT,
    @CompanyId      INT,
    @Action         NVARCHAR(15),       -- APROBADA, RECHAZADA
    @ApprovedAmount DECIMAL(18,2)   = NULL,
    @ApprovedBy     INT,
    @Notes          NVARCHAR(500)   = NULL,
    @Resultado      INT             OUTPUT,
    @Mensaje        NVARCHAR(500)   OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Resultado = 0;
    SET @Mensaje   = '';

    IF @Action NOT IN ('APROBADA','RECHAZADA')
    BEGIN
        SET @Resultado = -1;
        SET @Mensaje   = 'Accion no valida. Use APROBADA o RECHAZADA.';
        RETURN;
    END

    IF NOT EXISTS (SELECT 1 FROM hr.MedicalOrder
                   WHERE MedicalOrderId = @MedicalOrderId AND CompanyId = @CompanyId)
    BEGIN
        SET @Resultado = -1;
        SET @Mensaje   = 'Orden medica no encontrada.';
        RETURN;
    END

    -- Verify order is still pending
    IF NOT EXISTS (SELECT 1 FROM hr.MedicalOrder
                   WHERE MedicalOrderId = @MedicalOrderId AND CompanyId = @CompanyId
                     AND Status = 'PENDIENTE')
    BEGIN
        SET @Resultado = -1;
        SET @Mensaje   = 'La orden no esta en estado PENDIENTE.';
        RETURN;
    END

    BEGIN TRY
        UPDATE hr.MedicalOrder
        SET
            Status         = @Action,
            ApprovedAmount = CASE WHEN @Action = 'APROBADA' THEN ISNULL(@ApprovedAmount, EstimatedCost) ELSE NULL END,
            ApprovedBy     = @ApprovedBy,
            ApprovedAt     = SYSUTCDATETIME(),
            Notes          = ISNULL(@Notes, Notes),
            UpdatedAt      = SYSUTCDATETIME()
        WHERE MedicalOrderId = @MedicalOrderId
          AND CompanyId = @CompanyId;

        SET @Resultado = @MedicalOrderId;
        SET @Mensaje   = CASE WHEN @Action = 'APROBADA'
                              THEN 'Orden medica aprobada exitosamente.'
                              ELSE 'Orden medica rechazada.' END;
    END TRY
    BEGIN CATCH
        SET @Resultado = -1;
        SET @Mensaje   = ERROR_MESSAGE();
    END CATCH
END;
GO


-- =============================================================
-- 10) usp_HR_MedOrder_List
-- =============================================================
IF OBJECT_ID('dbo.usp_HR_MedOrder_List', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_HR_MedOrder_List;
GO

CREATE PROCEDURE dbo.usp_HR_MedOrder_List
    @CompanyId      INT,
    @OrderType      NVARCHAR(20)    = NULL,
    @Status         NVARCHAR(15)    = NULL,
    @EmployeeCode   NVARCHAR(24)    = NULL,
    @FromDate       DATE            = NULL,
    @ToDate         DATE            = NULL,
    @Page           INT             = 1,
    @Limit          INT             = 50,
    @TotalCount     INT             OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    IF @Page  < 1   SET @Page  = 1;
    IF @Limit < 1   SET @Limit = 50;
    IF @Limit > 500 SET @Limit = 500;

    SELECT @TotalCount = COUNT(*)
    FROM hr.MedicalOrder
    WHERE CompanyId = @CompanyId
      AND (@OrderType    IS NULL OR OrderType    = @OrderType)
      AND (@Status       IS NULL OR Status       = @Status)
      AND (@EmployeeCode IS NULL OR EmployeeCode = @EmployeeCode)
      AND (@FromDate     IS NULL OR OrderDate   >= @FromDate)
      AND (@ToDate       IS NULL OR OrderDate   <= @ToDate);

    SELECT
        MedicalOrderId,
        CompanyId,
        EmployeeId,
        EmployeeCode,
        EmployeeName,
        OrderType,
        OrderDate,
        Diagnosis,
        PhysicianName,
        Prescriptions,
        EstimatedCost,
        ApprovedAmount,
        Status,
        ApprovedBy,
        ApprovedAt,
        DocumentUrl,
        Notes,
        CreatedAt,
        UpdatedAt
    FROM hr.MedicalOrder
    WHERE CompanyId = @CompanyId
      AND (@OrderType    IS NULL OR OrderType    = @OrderType)
      AND (@Status       IS NULL OR Status       = @Status)
      AND (@EmployeeCode IS NULL OR EmployeeCode = @EmployeeCode)
      AND (@FromDate     IS NULL OR OrderDate   >= @FromDate)
      AND (@ToDate       IS NULL OR OrderDate   <= @ToDate)
    ORDER BY OrderDate DESC, MedicalOrderId DESC
    OFFSET ((@Page - 1) * @Limit) ROWS
    FETCH NEXT @Limit ROWS ONLY;
END;
GO


-- =============================================================
-- 11) usp_HR_Training_Save
-- =============================================================
IF OBJECT_ID('dbo.usp_HR_Training_Save', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_HR_Training_Save;
GO

CREATE PROCEDURE dbo.usp_HR_Training_Save
    @TrainingRecordId   INT             = NULL,  -- NULL = INSERT
    @CompanyId          INT,
    @CountryCode        CHAR(2),
    @TrainingType       NVARCHAR(25),
    @Title              NVARCHAR(200),
    @Provider           NVARCHAR(200)   = NULL,
    @StartDate          DATE,
    @EndDate            DATE            = NULL,
    @DurationHours      DECIMAL(6,2),
    @EmployeeId         BIGINT          = NULL,
    @EmployeeCode       NVARCHAR(24),
    @EmployeeName       NVARCHAR(200),
    @CertificateNumber  NVARCHAR(100)   = NULL,
    @CertificateUrl     NVARCHAR(500)   = NULL,
    @Result             NVARCHAR(15)    = NULL,
    @IsRegulatory       BIT             = 0,
    @Notes              NVARCHAR(500)   = NULL,
    @Resultado          INT             OUTPUT,
    @Mensaje            NVARCHAR(500)   OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Resultado = 0;
    SET @Mensaje   = '';

    IF @TrainingType NOT IN ('SAFETY','REGULATORY','TECHNICAL','APPRENTICESHIP','INDUCTION')
    BEGIN
        SET @Resultado = -1;
        SET @Mensaje   = 'Tipo de capacitacion no valido.';
        RETURN;
    END

    IF @Result IS NOT NULL AND @Result NOT IN ('PASSED','FAILED','IN_PROGRESS','ATTENDED')
    BEGIN
        SET @Resultado = -1;
        SET @Mensaje   = 'Resultado no valido.';
        RETURN;
    END

    IF @DurationHours <= 0
    BEGIN
        SET @Resultado = -1;
        SET @Mensaje   = 'La duracion en horas debe ser mayor a cero.';
        RETURN;
    END

    BEGIN TRY
        IF @TrainingRecordId IS NULL
        BEGIN
            INSERT INTO hr.TrainingRecord (
                CompanyId, CountryCode, TrainingType, Title, Provider,
                StartDate, EndDate, DurationHours,
                EmployeeId, EmployeeCode, EmployeeName,
                CertificateNumber, CertificateUrl, Result,
                IsRegulatory, Notes, CreatedAt, UpdatedAt
            )
            VALUES (
                @CompanyId, @CountryCode, @TrainingType, @Title, @Provider,
                @StartDate, @EndDate, @DurationHours,
                @EmployeeId, @EmployeeCode, @EmployeeName,
                @CertificateNumber, @CertificateUrl, @Result,
                @IsRegulatory, @Notes, SYSUTCDATETIME(), SYSUTCDATETIME()
            );

            SET @Resultado = SCOPE_IDENTITY();
            SET @Mensaje   = 'Registro de capacitacion creado exitosamente.';
        END
        ELSE
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM hr.TrainingRecord
                           WHERE TrainingRecordId = @TrainingRecordId AND CompanyId = @CompanyId)
            BEGIN
                SET @Resultado = -1;
                SET @Mensaje   = 'Registro de capacitacion no encontrado.';
                RETURN;
            END

            UPDATE hr.TrainingRecord
            SET
                CountryCode       = @CountryCode,
                TrainingType      = @TrainingType,
                Title             = @Title,
                Provider          = @Provider,
                StartDate         = @StartDate,
                EndDate           = @EndDate,
                DurationHours     = @DurationHours,
                EmployeeId        = ISNULL(@EmployeeId, EmployeeId),
                EmployeeCode      = @EmployeeCode,
                EmployeeName      = @EmployeeName,
                CertificateNumber = @CertificateNumber,
                CertificateUrl    = @CertificateUrl,
                Result            = @Result,
                IsRegulatory      = @IsRegulatory,
                Notes             = @Notes,
                UpdatedAt         = SYSUTCDATETIME()
            WHERE TrainingRecordId = @TrainingRecordId
              AND CompanyId = @CompanyId;

            SET @Resultado = @TrainingRecordId;
            SET @Mensaje   = 'Registro de capacitacion actualizado exitosamente.';
        END
    END TRY
    BEGIN CATCH
        SET @Resultado = -1;
        SET @Mensaje   = ERROR_MESSAGE();
    END CATCH
END;
GO


-- =============================================================
-- 12) usp_HR_Training_List
-- =============================================================
IF OBJECT_ID('dbo.usp_HR_Training_List', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_HR_Training_List;
GO

CREATE PROCEDURE dbo.usp_HR_Training_List
    @CompanyId      INT,
    @TrainingType   NVARCHAR(25)    = NULL,
    @EmployeeCode   NVARCHAR(24)    = NULL,
    @CountryCode    CHAR(2)         = NULL,
    @IsRegulatory   BIT             = NULL,
    @Result         NVARCHAR(15)    = NULL,
    @FromDate       DATE            = NULL,
    @ToDate         DATE            = NULL,
    @Page           INT             = 1,
    @Limit          INT             = 50,
    @TotalCount     INT             OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    IF @Page  < 1   SET @Page  = 1;
    IF @Limit < 1   SET @Limit = 50;
    IF @Limit > 500 SET @Limit = 500;

    SELECT @TotalCount = COUNT(*)
    FROM hr.TrainingRecord
    WHERE CompanyId = @CompanyId
      AND (@TrainingType  IS NULL OR TrainingType  = @TrainingType)
      AND (@EmployeeCode  IS NULL OR EmployeeCode  = @EmployeeCode)
      AND (@CountryCode   IS NULL OR CountryCode   = @CountryCode)
      AND (@IsRegulatory  IS NULL OR IsRegulatory   = @IsRegulatory)
      AND (@Result        IS NULL OR Result         = @Result)
      AND (@FromDate      IS NULL OR StartDate     >= @FromDate)
      AND (@ToDate        IS NULL OR StartDate     <= @ToDate);

    SELECT
        TrainingRecordId,
        CompanyId,
        CountryCode,
        TrainingType,
        Title,
        Provider,
        StartDate,
        EndDate,
        DurationHours,
        EmployeeId,
        EmployeeCode,
        EmployeeName,
        CertificateNumber,
        CertificateUrl,
        Result,
        IsRegulatory,
        Notes,
        CreatedAt,
        UpdatedAt
    FROM hr.TrainingRecord
    WHERE CompanyId = @CompanyId
      AND (@TrainingType  IS NULL OR TrainingType  = @TrainingType)
      AND (@EmployeeCode  IS NULL OR EmployeeCode  = @EmployeeCode)
      AND (@CountryCode   IS NULL OR CountryCode   = @CountryCode)
      AND (@IsRegulatory  IS NULL OR IsRegulatory   = @IsRegulatory)
      AND (@Result        IS NULL OR Result         = @Result)
      AND (@FromDate      IS NULL OR StartDate     >= @FromDate)
      AND (@ToDate        IS NULL OR StartDate     <= @ToDate)
    ORDER BY StartDate DESC, TrainingRecordId DESC
    OFFSET ((@Page - 1) * @Limit) ROWS
    FETCH NEXT @Limit ROWS ONLY;
END;
GO


-- =============================================================
-- 13) usp_HR_Training_GetEmployeeCertifications
-- =============================================================
IF OBJECT_ID('dbo.usp_HR_Training_GetEmployeeCertifications', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_HR_Training_GetEmployeeCertifications;
GO

CREATE PROCEDURE dbo.usp_HR_Training_GetEmployeeCertifications
    @CompanyId      INT,
    @EmployeeCode   NVARCHAR(24)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        TrainingRecordId,
        CompanyId,
        CountryCode,
        TrainingType,
        Title,
        Provider,
        StartDate,
        EndDate,
        DurationHours,
        EmployeeId,
        EmployeeCode,
        EmployeeName,
        CertificateNumber,
        CertificateUrl,
        Result,
        IsRegulatory,
        Notes,
        CreatedAt,
        UpdatedAt
    FROM hr.TrainingRecord
    WHERE CompanyId    = @CompanyId
      AND EmployeeCode = @EmployeeCode
      AND Result       = 'PASSED'
      AND CertificateNumber IS NOT NULL
    ORDER BY StartDate DESC;
END;
GO


-- =============================================================
-- 14) usp_HR_Committee_Save
-- =============================================================
IF OBJECT_ID('dbo.usp_HR_Committee_Save', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_HR_Committee_Save;
GO

CREATE PROCEDURE dbo.usp_HR_Committee_Save
    @SafetyCommitteeId  INT             = NULL,  -- NULL = INSERT
    @CompanyId          INT,
    @CountryCode        CHAR(2),
    @CommitteeName      NVARCHAR(200),
    @FormationDate      DATE,
    @MeetingFrequency   NVARCHAR(15)    = 'MONTHLY',
    @IsActive           BIT             = 1,
    @Resultado          INT             OUTPUT,
    @Mensaje            NVARCHAR(500)   OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Resultado = 0;
    SET @Mensaje   = '';

    BEGIN TRY
        IF @SafetyCommitteeId IS NULL
        BEGIN
            INSERT INTO hr.SafetyCommittee (
                CompanyId, CountryCode, CommitteeName,
                FormationDate, MeetingFrequency, IsActive, CreatedAt
            )
            VALUES (
                @CompanyId, @CountryCode, @CommitteeName,
                @FormationDate, @MeetingFrequency, @IsActive, SYSUTCDATETIME()
            );

            SET @Resultado = SCOPE_IDENTITY();
            SET @Mensaje   = 'Comite de seguridad creado exitosamente.';
        END
        ELSE
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM hr.SafetyCommittee
                           WHERE SafetyCommitteeId = @SafetyCommitteeId AND CompanyId = @CompanyId)
            BEGIN
                SET @Resultado = -1;
                SET @Mensaje   = 'Comite no encontrado.';
                RETURN;
            END

            UPDATE hr.SafetyCommittee
            SET
                CountryCode      = @CountryCode,
                CommitteeName    = @CommitteeName,
                FormationDate    = @FormationDate,
                MeetingFrequency = @MeetingFrequency,
                IsActive         = @IsActive
            WHERE SafetyCommitteeId = @SafetyCommitteeId
              AND CompanyId = @CompanyId;

            SET @Resultado = @SafetyCommitteeId;
            SET @Mensaje   = 'Comite de seguridad actualizado exitosamente.';
        END
    END TRY
    BEGIN CATCH
        SET @Resultado = -1;
        SET @Mensaje   = ERROR_MESSAGE();
    END CATCH
END;
GO


-- =============================================================
-- 15) usp_HR_Committee_AddMember
-- =============================================================
IF OBJECT_ID('dbo.usp_HR_Committee_AddMember', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_HR_Committee_AddMember;
GO

CREATE PROCEDURE dbo.usp_HR_Committee_AddMember
    @SafetyCommitteeId  INT,
    @CompanyId          INT,
    @EmployeeId         BIGINT          = NULL,
    @EmployeeCode       NVARCHAR(24),
    @EmployeeName       NVARCHAR(200),
    @Role               NVARCHAR(25),
    @StartDate          DATE,
    @EndDate            DATE            = NULL,
    @Resultado          INT             OUTPUT,
    @Mensaje            NVARCHAR(500)   OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Resultado = 0;
    SET @Mensaje   = '';

    IF @Role NOT IN ('PRESIDENT','SECRETARY','DELEGATE','EMPLOYER_REP')
    BEGIN
        SET @Resultado = -1;
        SET @Mensaje   = 'Rol no valido.';
        RETURN;
    END

    -- Verify committee exists and belongs to company
    IF NOT EXISTS (SELECT 1 FROM hr.SafetyCommittee
                   WHERE SafetyCommitteeId = @SafetyCommitteeId AND CompanyId = @CompanyId)
    BEGIN
        SET @Resultado = -1;
        SET @Mensaje   = 'Comite no encontrado.';
        RETURN;
    END

    -- Check duplicate active member
    IF EXISTS (SELECT 1 FROM hr.SafetyCommitteeMember
               WHERE SafetyCommitteeId = @SafetyCommitteeId
                 AND EmployeeCode = @EmployeeCode
                 AND (EndDate IS NULL OR EndDate >= @StartDate))
    BEGIN
        SET @Resultado = -1;
        SET @Mensaje   = 'El empleado ya es miembro activo de este comite.';
        RETURN;
    END

    BEGIN TRY
        INSERT INTO hr.SafetyCommitteeMember (
            SafetyCommitteeId, EmployeeId, EmployeeCode, EmployeeName,
            Role, StartDate, EndDate
        )
        VALUES (
            @SafetyCommitteeId, @EmployeeId, @EmployeeCode, @EmployeeName,
            @Role, @StartDate, @EndDate
        );

        SET @Resultado = SCOPE_IDENTITY();
        SET @Mensaje   = 'Miembro agregado exitosamente al comite.';
    END TRY
    BEGIN CATCH
        SET @Resultado = -1;
        SET @Mensaje   = ERROR_MESSAGE();
    END CATCH
END;
GO


-- =============================================================
-- 16) usp_HR_Committee_RemoveMember
-- =============================================================
IF OBJECT_ID('dbo.usp_HR_Committee_RemoveMember', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_HR_Committee_RemoveMember;
GO

CREATE PROCEDURE dbo.usp_HR_Committee_RemoveMember
    @MemberId           INT,
    @SafetyCommitteeId  INT,
    @CompanyId          INT,
    @EndDate            DATE            = NULL,  -- NULL = today UTC
    @Resultado          INT             OUTPUT,
    @Mensaje            NVARCHAR(500)   OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Resultado = 0;
    SET @Mensaje   = '';

    IF @EndDate IS NULL SET @EndDate = CAST(SYSUTCDATETIME() AS DATE);

    -- Verify committee belongs to company
    IF NOT EXISTS (SELECT 1 FROM hr.SafetyCommittee
                   WHERE SafetyCommitteeId = @SafetyCommitteeId AND CompanyId = @CompanyId)
    BEGIN
        SET @Resultado = -1;
        SET @Mensaje   = 'Comite no encontrado.';
        RETURN;
    END

    IF NOT EXISTS (SELECT 1 FROM hr.SafetyCommitteeMember
                   WHERE MemberId = @MemberId AND SafetyCommitteeId = @SafetyCommitteeId)
    BEGIN
        SET @Resultado = -1;
        SET @Mensaje   = 'Miembro no encontrado en este comite.';
        RETURN;
    END

    BEGIN TRY
        UPDATE hr.SafetyCommitteeMember
        SET EndDate = @EndDate
        WHERE MemberId = @MemberId
          AND SafetyCommitteeId = @SafetyCommitteeId;

        SET @Resultado = @MemberId;
        SET @Mensaje   = 'Miembro removido del comite exitosamente.';
    END TRY
    BEGIN CATCH
        SET @Resultado = -1;
        SET @Mensaje   = ERROR_MESSAGE();
    END CATCH
END;
GO


-- =============================================================
-- 17) usp_HR_Committee_RecordMeeting
-- =============================================================
IF OBJECT_ID('dbo.usp_HR_Committee_RecordMeeting', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_HR_Committee_RecordMeeting;
GO

CREATE PROCEDURE dbo.usp_HR_Committee_RecordMeeting
    @SafetyCommitteeId  INT,
    @CompanyId          INT,
    @MeetingDate        DATETIME2(0),
    @MinutesUrl         NVARCHAR(500)   = NULL,
    @TopicsSummary      NVARCHAR(MAX)   = NULL,
    @ActionItems        NVARCHAR(MAX)   = NULL,
    @Resultado          INT             OUTPUT,
    @Mensaje            NVARCHAR(500)   OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Resultado = 0;
    SET @Mensaje   = '';

    -- Verify committee belongs to company
    IF NOT EXISTS (SELECT 1 FROM hr.SafetyCommittee
                   WHERE SafetyCommitteeId = @SafetyCommitteeId AND CompanyId = @CompanyId)
    BEGIN
        SET @Resultado = -1;
        SET @Mensaje   = 'Comite no encontrado.';
        RETURN;
    END

    BEGIN TRY
        INSERT INTO hr.SafetyCommitteeMeeting (
            SafetyCommitteeId, MeetingDate, MinutesUrl,
            TopicsSummary, ActionItems, CreatedAt
        )
        VALUES (
            @SafetyCommitteeId, @MeetingDate, @MinutesUrl,
            @TopicsSummary, @ActionItems, SYSUTCDATETIME()
        );

        SET @Resultado = SCOPE_IDENTITY();
        SET @Mensaje   = 'Reunion registrada exitosamente.';
    END TRY
    BEGIN CATCH
        SET @Resultado = -1;
        SET @Mensaje   = ERROR_MESSAGE();
    END CATCH
END;
GO


-- =============================================================
-- 18) usp_HR_Committee_List
-- =============================================================
IF OBJECT_ID('dbo.usp_HR_Committee_List', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_HR_Committee_List;
GO

CREATE PROCEDURE dbo.usp_HR_Committee_List
    @CompanyId      INT,
    @CountryCode    CHAR(2)     = NULL,
    @IsActive       BIT         = NULL,
    @Page           INT         = 1,
    @Limit          INT         = 50,
    @TotalCount     INT         OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    IF @Page  < 1   SET @Page  = 1;
    IF @Limit < 1   SET @Limit = 50;
    IF @Limit > 500 SET @Limit = 500;

    SELECT @TotalCount = COUNT(*)
    FROM hr.SafetyCommittee
    WHERE CompanyId = @CompanyId
      AND (@CountryCode IS NULL OR CountryCode = @CountryCode)
      AND (@IsActive    IS NULL OR IsActive    = @IsActive);

    SELECT
        sc.SafetyCommitteeId,
        sc.CompanyId,
        sc.CountryCode,
        sc.CommitteeName,
        sc.FormationDate,
        sc.MeetingFrequency,
        sc.IsActive,
        sc.CreatedAt,
        (SELECT COUNT(*) FROM hr.SafetyCommitteeMember m
         WHERE m.SafetyCommitteeId = sc.SafetyCommitteeId
           AND (m.EndDate IS NULL OR m.EndDate >= CAST(SYSUTCDATETIME() AS DATE))) AS ActiveMemberCount,
        (SELECT COUNT(*) FROM hr.SafetyCommitteeMeeting mt
         WHERE mt.SafetyCommitteeId = sc.SafetyCommitteeId) AS TotalMeetings
    FROM hr.SafetyCommittee sc
    WHERE sc.CompanyId = @CompanyId
      AND (@CountryCode IS NULL OR sc.CountryCode = @CountryCode)
      AND (@IsActive    IS NULL OR sc.IsActive    = @IsActive)
    ORDER BY sc.IsActive DESC, sc.FormationDate DESC
    OFFSET ((@Page - 1) * @Limit) ROWS
    FETCH NEXT @Limit ROWS ONLY;
END;
GO


-- =============================================================
-- 19) usp_HR_Committee_GetMeetings
-- =============================================================
IF OBJECT_ID('dbo.usp_HR_Committee_GetMeetings', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_HR_Committee_GetMeetings;
GO

CREATE PROCEDURE dbo.usp_HR_Committee_GetMeetings
    @SafetyCommitteeId  INT,
    @CompanyId          INT,
    @FromDate           DATE    = NULL,
    @ToDate             DATE    = NULL,
    @Page               INT     = 1,
    @Limit              INT     = 50,
    @TotalCount         INT     OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    IF @Page  < 1   SET @Page  = 1;
    IF @Limit < 1   SET @Limit = 50;
    IF @Limit > 500 SET @Limit = 500;

    -- Verify committee belongs to company
    IF NOT EXISTS (SELECT 1 FROM hr.SafetyCommittee
                   WHERE SafetyCommitteeId = @SafetyCommitteeId AND CompanyId = @CompanyId)
    BEGIN
        SET @TotalCount = 0;
        RETURN;
    END

    SELECT @TotalCount = COUNT(*)
    FROM hr.SafetyCommitteeMeeting
    WHERE SafetyCommitteeId = @SafetyCommitteeId
      AND (@FromDate IS NULL OR MeetingDate >= @FromDate)
      AND (@ToDate   IS NULL OR MeetingDate <= @ToDate);

    SELECT
        m.MeetingId,
        m.SafetyCommitteeId,
        m.MeetingDate,
        m.MinutesUrl,
        m.TopicsSummary,
        m.ActionItems,
        m.CreatedAt,
        sc.CommitteeName
    FROM hr.SafetyCommitteeMeeting m
    INNER JOIN hr.SafetyCommittee sc ON sc.SafetyCommitteeId = m.SafetyCommitteeId
    WHERE m.SafetyCommitteeId = @SafetyCommitteeId
      AND (@FromDate IS NULL OR m.MeetingDate >= @FromDate)
      AND (@ToDate   IS NULL OR m.MeetingDate <= @ToDate)
    ORDER BY m.MeetingDate DESC
    OFFSET ((@Page - 1) * @Limit) ROWS
    FETCH NEXT @Limit ROWS ONLY;
END;
GO


-- =============================================================
PRINT '>>> sp_rrhh_salud_ocupacional.sql ejecutado correctamente <<<';
PRINT '>>> Tablas: hr.OccupationalHealth, hr.MedicalExam, hr.MedicalOrder, hr.TrainingRecord, hr.SafetyCommittee, hr.SafetyCommitteeMember, hr.SafetyCommitteeMeeting';
PRINT '>>> SPs: usp_HR_OccHealth_Create/Update/List/Get, usp_HR_MedExam_Save/List/GetPending, usp_HR_MedOrder_Create/Approve/List, usp_HR_Training_Save/List/GetEmployeeCertifications, usp_HR_Committee_Save/AddMember/RemoveMember/RecordMeeting/List/GetMeetings';
GO
