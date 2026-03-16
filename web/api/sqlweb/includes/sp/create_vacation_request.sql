-- =============================================
-- Tables: hr.VacationRequest, hr.VacationRequestDay
-- Workflow: PENDIENTE -> APROBADA -> PROCESADA (or RECHAZADA/CANCELADA)
-- =============================================

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'hr')
BEGIN
    EXEC('CREATE SCHEMA hr');
END
GO

IF NOT EXISTS (SELECT * FROM sys.tables t JOIN sys.schemas s ON t.schema_id = s.schema_id WHERE s.name = 'hr' AND t.name = 'VacationRequest')
BEGIN
    CREATE TABLE hr.VacationRequest (
        RequestId       BIGINT IDENTITY(1,1) PRIMARY KEY,
        CompanyId       INT NOT NULL DEFAULT 1,
        BranchId        INT NOT NULL DEFAULT 1,
        EmployeeCode    NVARCHAR(60) NOT NULL,
        RequestDate     DATE NOT NULL DEFAULT CAST(SYSUTCDATETIME() AS DATE),
        StartDate       DATE NOT NULL,
        EndDate         DATE NOT NULL,
        TotalDays       INT NOT NULL,
        IsPartial       BIT NOT NULL DEFAULT 0,
        Status          NVARCHAR(20) NOT NULL DEFAULT 'PENDIENTE',
        Notes           NVARCHAR(500) NULL,
        ApprovedBy      NVARCHAR(60) NULL,
        ApprovalDate    DATETIME NULL,
        RejectionReason NVARCHAR(500) NULL,
        VacationId      BIGINT NULL,
        CreatedAt       DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
        UpdatedAt       DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),

        CONSTRAINT CK_VacationRequest_Status CHECK (Status IN ('PENDIENTE','APROBADA','RECHAZADA','CANCELADA','PROCESADA')),
        CONSTRAINT CK_VacationRequest_Dates  CHECK (EndDate >= StartDate),
        CONSTRAINT CK_VacationRequest_Days   CHECK (TotalDays > 0)
    );

    CREATE NONCLUSTERED INDEX IX_VacationRequest_Employee
        ON hr.VacationRequest (CompanyId, EmployeeCode, Status);

    CREATE NONCLUSTERED INDEX IX_VacationRequest_Status
        ON hr.VacationRequest (Status, RequestDate);
END
GO

IF NOT EXISTS (SELECT * FROM sys.tables t JOIN sys.schemas s ON t.schema_id = s.schema_id WHERE s.name = 'hr' AND t.name = 'VacationRequestDay')
BEGIN
    CREATE TABLE hr.VacationRequestDay (
        DayId           BIGINT IDENTITY(1,1) PRIMARY KEY,
        RequestId       BIGINT NOT NULL REFERENCES hr.VacationRequest(RequestId),
        SelectedDate    DATE NOT NULL,
        DayType         NVARCHAR(20) NOT NULL DEFAULT 'COMPLETO',

        CONSTRAINT CK_VacationRequestDay_Type CHECK (DayType IN ('COMPLETO','MEDIO_DIA'))
    );

    CREATE NONCLUSTERED INDEX IX_VacationRequestDay_Request
        ON hr.VacationRequestDay (RequestId);
END
GO
