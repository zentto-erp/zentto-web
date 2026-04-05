-- 04_patch_iam_rbac.sql
-- Adds IAM/RBAC tables for SQL Server: PlanDefinition, PlanModule,
-- audit.IamChangeLog, and columns on zsys.License.
-- Compatible SQL Server 2012+

-- =============================================================================
-- 1. Add columns to zsys.License (if not exist)
-- =============================================================================
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('zsys.License') AND name = 'MaxCompanies')
    ALTER TABLE zsys.License ADD MaxCompanies INT NULL;
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('zsys.License') AND name = 'MultiCompanyEnabled')
    ALTER TABLE zsys.License ADD MultiCompanyEnabled BIT DEFAULT 1;
GO

-- =============================================================================
-- 2. cfg.PlanDefinition
-- =============================================================================
IF OBJECT_ID('cfg.PlanDefinition', 'U') IS NULL
BEGIN
    CREATE TABLE cfg.PlanDefinition (
        PlanCode           VARCHAR(30)    NOT NULL PRIMARY KEY,
        PlanName           NVARCHAR(100)  NOT NULL,
        MaxUsers           INT            NULL,
        MaxCompanies       INT            NULL,
        MaxBranches        INT            NULL,
        MultiCompanyEnabled BIT           DEFAULT 0,
        MonthlyPriceUsd    DECIMAL(10,2)  NULL,
        AnnualPriceUsd     DECIMAL(10,2)  NULL,
        IsActive           BIT            DEFAULT 1,
        SortOrder          INT            DEFAULT 0,
        CreatedAt          DATETIME       DEFAULT GETUTCDATE(),
        UpdatedAt          DATETIME       DEFAULT GETUTCDATE()
    );
END
GO

-- =============================================================================
-- 3. cfg.PlanModule
-- =============================================================================
IF OBJECT_ID('cfg.PlanModule', 'U') IS NULL
BEGIN
    CREATE TABLE cfg.PlanModule (
        PlanModuleId  INT IDENTITY(1,1) PRIMARY KEY,
        PlanCode      VARCHAR(30)  NOT NULL REFERENCES cfg.PlanDefinition(PlanCode),
        ModuleCode    VARCHAR(60)  NOT NULL,
        IsIncluded    BIT          DEFAULT 1,
        CONSTRAINT UQ_PlanModule UNIQUE (PlanCode, ModuleCode)
    );
END
GO

-- =============================================================================
-- 4. audit.IamChangeLog
-- =============================================================================
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'audit')
    EXEC('CREATE SCHEMA audit');
GO

IF OBJECT_ID('audit.IamChangeLog', 'U') IS NULL
BEGIN
    CREATE TABLE audit.IamChangeLog (
        IamChangeId     BIGINT IDENTITY(1,1) PRIMARY KEY,
        CompanyId       INT           NOT NULL,
        ChangeType      VARCHAR(50)   NOT NULL,
        EntityType      VARCHAR(50)   NOT NULL,
        EntityId        VARCHAR(50)   NULL,
        OldValue        NVARCHAR(MAX) NULL,
        NewValue        NVARCHAR(MAX) NULL,
        ChangedByUserId INT           NOT NULL,
        ChangedAt       DATETIME      DEFAULT GETUTCDATE(),
        IpAddress       VARCHAR(50)   NULL,
        UserAgent       VARCHAR(500)  NULL
    );

    CREATE NONCLUSTERED INDEX IX_IamChangeLog_Company
        ON audit.IamChangeLog (CompanyId, ChangedAt DESC);

    CREATE NONCLUSTERED INDEX IX_IamChangeLog_Type
        ON audit.IamChangeLog (ChangeType, ChangedAt DESC);
END
GO

-- =============================================================================
-- 5. Seed PlanDefinition
-- =============================================================================
MERGE cfg.PlanDefinition AS tgt
USING (VALUES
    ('FREE',       N'Gratuito',      2,    1,    1,    0, 0,      0),
    ('STARTER',    N'Iniciador',     5,    1,    2,    0, 29.99,  299.99),
    ('PRO',        N'Profesional',  15,    3,    5,    1, 79.99,  799.99),
    ('ENTERPRISE', N'Empresarial', NULL, NULL, NULL,   1, 199.99, 1999.99)
) AS src (PlanCode, PlanName, MaxUsers, MaxCompanies, MaxBranches, MultiCompanyEnabled, MonthlyPriceUsd, AnnualPriceUsd)
ON tgt.PlanCode = src.PlanCode
WHEN MATCHED THEN UPDATE SET
    PlanName = src.PlanName, MaxUsers = src.MaxUsers, MaxCompanies = src.MaxCompanies,
    MaxBranches = src.MaxBranches, MultiCompanyEnabled = src.MultiCompanyEnabled,
    MonthlyPriceUsd = src.MonthlyPriceUsd, AnnualPriceUsd = src.AnnualPriceUsd,
    UpdatedAt = GETUTCDATE()
WHEN NOT MATCHED THEN INSERT (PlanCode, PlanName, MaxUsers, MaxCompanies, MaxBranches, MultiCompanyEnabled, MonthlyPriceUsd, AnnualPriceUsd, IsActive, SortOrder)
    VALUES (src.PlanCode, src.PlanName, src.MaxUsers, src.MaxCompanies, src.MaxBranches, src.MultiCompanyEnabled, src.MonthlyPriceUsd, src.AnnualPriceUsd, 1, 0);
GO
