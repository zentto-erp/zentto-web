-- ============================================================
-- zentto_dev — Patch: CRM Redesign (ADR-CRM-001 B+B)
-- Tablas: crm.Company, crm.Contact, crm.Deal, crm.DealLine, crm.DealHistory
-- Compatible SQL Server 2012+ (compat level 110)
-- ============================================================
USE zentto_dev;
GO

IF SCHEMA_ID('crm') IS NULL EXEC('CREATE SCHEMA crm');
GO

-- ─────────────────────────────────────────────────────────────
-- crm.Company (tenant-aware, CompanyId es el tenant; PK interna CrmCompanyId)
-- ─────────────────────────────────────────────────────────────
IF OBJECT_ID('crm.Company', 'U') IS NULL
BEGIN
    CREATE TABLE crm.[Company] (
        CrmCompanyId     BIGINT        IDENTITY(1,1) NOT NULL PRIMARY KEY,
        CompanyId        INT           NOT NULL,
        [Name]           NVARCHAR(200) NOT NULL,
        LegalName        NVARCHAR(200) NULL,
        TaxId            VARCHAR(50)   NULL,
        Industry         VARCHAR(100)  NULL,
        [Size]           VARCHAR(20)   NULL,
        Website          VARCHAR(255)  NULL,
        Phone            VARCHAR(50)   NULL,
        Email            VARCHAR(255)  NULL,
        BillingAddress   NVARCHAR(MAX) NULL,
        ShippingAddress  NVARCHAR(MAX) NULL,
        Notes            NVARCHAR(MAX) NULL,
        IsActive         BIT           NOT NULL DEFAULT 1,
        IsDeleted        BIT           NOT NULL DEFAULT 0,
        CreatedAt        DATETIME2(3)  NOT NULL DEFAULT SYSUTCDATETIME(),
        UpdatedAt        DATETIME2(3)  NOT NULL DEFAULT SYSUTCDATETIME(),
        DeletedAt        DATETIME2(3)  NULL,
        CreatedByUserId  INT           NULL,
        UpdatedByUserId  INT           NULL,
        DeletedByUserId  INT           NULL,
        RowVer           INT           NOT NULL DEFAULT 1,
        CONSTRAINT CK_crm_Company_Size CHECK (
            [Size] IS NULL OR [Size] IN ('1-10','11-50','51-200','201-500','501-1000','1000+')
        )
    );
    CREATE INDEX IX_crm_Company_Tenant_Name ON crm.[Company] (CompanyId, [Name])
      WHERE IsDeleted = 0;
END
GO

-- ─────────────────────────────────────────────────────────────
-- crm.Contact
-- ─────────────────────────────────────────────────────────────
IF OBJECT_ID('crm.Contact', 'U') IS NULL
BEGIN
    CREATE TABLE crm.[Contact] (
        ContactId          BIGINT        IDENTITY(1,1) NOT NULL PRIMARY KEY,
        CompanyId          INT           NOT NULL,
        CrmCompanyId       BIGINT        NULL,
        FirstName          NVARCHAR(100) NOT NULL,
        LastName           NVARCHAR(100) NULL,
        Email              VARCHAR(255)  NULL,
        Phone              VARCHAR(50)   NULL,
        Mobile             VARCHAR(50)   NULL,
        Title              NVARCHAR(100) NULL,
        Department         NVARCHAR(100) NULL,
        LinkedIn           VARCHAR(255)  NULL,
        Notes              NVARCHAR(MAX) NULL,
        PromotedCustomerId BIGINT        NULL,
        IsActive           BIT           NOT NULL DEFAULT 1,
        IsDeleted          BIT           NOT NULL DEFAULT 0,
        CreatedAt          DATETIME2(3)  NOT NULL DEFAULT SYSUTCDATETIME(),
        UpdatedAt          DATETIME2(3)  NOT NULL DEFAULT SYSUTCDATETIME(),
        DeletedAt          DATETIME2(3)  NULL,
        CreatedByUserId    INT           NULL,
        UpdatedByUserId    INT           NULL,
        DeletedByUserId    INT           NULL,
        RowVer             INT           NOT NULL DEFAULT 1,
        CONSTRAINT FK_crm_Contact_Company FOREIGN KEY (CrmCompanyId)
            REFERENCES crm.[Company] (CrmCompanyId)
    );
    CREATE INDEX IX_crm_Contact_Tenant_Company ON crm.[Contact] (CompanyId, CrmCompanyId)
      WHERE IsDeleted = 0;
    CREATE INDEX IX_crm_Contact_Tenant_Email ON crm.[Contact] (CompanyId, Email)
      WHERE Email IS NOT NULL AND IsDeleted = 0;
END
GO

-- ─────────────────────────────────────────────────────────────
-- crm.Deal
-- ─────────────────────────────────────────────────────────────
IF OBJECT_ID('crm.Deal', 'U') IS NULL
BEGIN
    CREATE TABLE crm.[Deal] (
        DealId             BIGINT        IDENTITY(1,1) NOT NULL PRIMARY KEY,
        CompanyId          INT           NOT NULL,
        BranchId           INT           NOT NULL DEFAULT 1,
        ContactId          BIGINT        NULL,
        CrmCompanyId       BIGINT        NULL,
        PipelineId         BIGINT        NOT NULL,
        StageId            BIGINT        NOT NULL,
        OwnerAgentId       BIGINT        NULL,
        AssignedToUserId   INT           NULL,
        [Name]             NVARCHAR(255) NOT NULL,
        [Value]            DECIMAL(18,2) NOT NULL DEFAULT 0,
        Currency           VARCHAR(3)    NOT NULL DEFAULT 'USD',
        Probability        DECIMAL(5,2)  NULL,
        ExpectedCloseDate  DATE          NULL,
        ActualCloseDate    DATE          NULL,
        [Status]           VARCHAR(20)   NOT NULL DEFAULT 'OPEN',
        WonLostReason      NVARCHAR(500) NULL,
        Priority           VARCHAR(10)   NOT NULL DEFAULT 'MEDIUM',
        Source             VARCHAR(50)   NULL,
        Notes              NVARCHAR(MAX) NULL,
        Tags               VARCHAR(500)  NULL,
        SourceLeadId       BIGINT        NULL,
        IsDeleted          BIT           NOT NULL DEFAULT 0,
        CreatedAt          DATETIME2(3)  NOT NULL DEFAULT SYSUTCDATETIME(),
        UpdatedAt          DATETIME2(3)  NOT NULL DEFAULT SYSUTCDATETIME(),
        ClosedAt           DATETIME2(3)  NULL,
        DeletedAt          DATETIME2(3)  NULL,
        CreatedByUserId    INT           NULL,
        UpdatedByUserId    INT           NULL,
        DeletedByUserId    INT           NULL,
        RowVer             INT           NOT NULL DEFAULT 1,
        CONSTRAINT CK_crm_Deal_Status      CHECK ([Status] IN ('OPEN','WON','LOST','ABANDONED')),
        CONSTRAINT CK_crm_Deal_Priority    CHECK (Priority IN ('URGENT','HIGH','MEDIUM','LOW')),
        CONSTRAINT CK_crm_Deal_Probability CHECK (Probability IS NULL OR (Probability BETWEEN 0 AND 100)),
        CONSTRAINT FK_crm_Deal_Contact FOREIGN KEY (ContactId)
            REFERENCES crm.[Contact] (ContactId),
        CONSTRAINT FK_crm_Deal_Company FOREIGN KEY (CrmCompanyId)
            REFERENCES crm.[Company] (CrmCompanyId)
    );
    CREATE INDEX IX_crm_Deal_Tenant_Stage   ON crm.[Deal] (CompanyId, StageId)
      WHERE IsDeleted = 0;
    CREATE INDEX IX_crm_Deal_Contact        ON crm.[Deal] (ContactId)
      WHERE IsDeleted = 0;
    CREATE INDEX IX_crm_Deal_CrmCompany     ON crm.[Deal] (CrmCompanyId)
      WHERE IsDeleted = 0;
END
GO

-- ─────────────────────────────────────────────────────────────
-- crm.DealLine
-- ─────────────────────────────────────────────────────────────
IF OBJECT_ID('crm.DealLine', 'U') IS NULL
BEGIN
    CREATE TABLE crm.[DealLine] (
        LineId      BIGINT        IDENTITY(1,1) NOT NULL PRIMARY KEY,
        DealId      BIGINT        NOT NULL,
        ProductId   BIGINT        NULL,
        Description NVARCHAR(500) NOT NULL,
        Quantity    DECIMAL(18,4) NOT NULL DEFAULT 1,
        UnitPrice   DECIMAL(18,2) NOT NULL DEFAULT 0,
        Discount    DECIMAL(5,2)  NOT NULL DEFAULT 0,
        TotalPrice  DECIMAL(18,2) NOT NULL DEFAULT 0,
        SortOrder   INT           NOT NULL DEFAULT 0,
        CreatedAt   DATETIME2(3)  NOT NULL DEFAULT SYSUTCDATETIME(),
        CONSTRAINT FK_crm_DealLine_Deal FOREIGN KEY (DealId)
            REFERENCES crm.[Deal] (DealId) ON DELETE CASCADE
    );
    CREATE INDEX IX_crm_DealLine_Deal ON crm.[DealLine] (DealId);
END
GO

-- ─────────────────────────────────────────────────────────────
-- crm.DealHistory
-- ─────────────────────────────────────────────────────────────
IF OBJECT_ID('crm.DealHistory', 'U') IS NULL
BEGIN
    CREATE TABLE crm.[DealHistory] (
        HistoryId    BIGINT        IDENTITY(1,1) NOT NULL PRIMARY KEY,
        DealId       BIGINT        NOT NULL,
        ChangeType   VARCHAR(30)   NOT NULL,
        OldValue     NVARCHAR(MAX) NULL,
        NewValue     NVARCHAR(MAX) NULL,
        Notes        NVARCHAR(MAX) NULL,
        UserId       INT           NULL,
        ChangedAt    DATETIME2(3)  NOT NULL DEFAULT SYSUTCDATETIME(),
        CONSTRAINT CK_crm_DealHistory_Type CHECK (
            ChangeType IN ('CREATED','STAGE_CHANGE','VALUE_CHANGE','OWNER_CHANGE',
                           'STATUS_CHANGE','NOTE','WON','LOST','REOPEN','BACKFILL')
        ),
        CONSTRAINT FK_crm_DealHistory_Deal FOREIGN KEY (DealId)
            REFERENCES crm.[Deal] (DealId) ON DELETE CASCADE
    );
    CREATE INDEX IX_crm_DealHistory_Deal ON crm.[DealHistory] (DealId, ChangedAt DESC);
END
GO

-- ─────────────────────────────────────────────────────────────
-- crm.Lead — ampliar CHECK de Status + agregar ConvertedToDealId.
-- Solo si la tabla ya existe en el schema (nivelacion SQL Server a PG).
-- ─────────────────────────────────────────────────────────────
IF OBJECT_ID('crm.Lead', 'U') IS NOT NULL
BEGIN
    IF COL_LENGTH('crm.Lead', 'ConvertedToDealId') IS NULL
        ALTER TABLE crm.[Lead] ADD ConvertedToDealId BIGINT NULL;

    -- Drop old CHECK si existe con el nombre CK_crm_Lead_Status
    IF EXISTS (
        SELECT 1 FROM sys.check_constraints
         WHERE [name] = 'CK_crm_Lead_Status'
           AND parent_object_id = OBJECT_ID('crm.Lead')
    )
        ALTER TABLE crm.[Lead] DROP CONSTRAINT CK_crm_Lead_Status;

    ALTER TABLE crm.[Lead]
        ADD CONSTRAINT CK_crm_Lead_Status CHECK (
            [Status] IN ('OPEN','WON','LOST','ARCHIVED',
                         'NEW','CONTACTED','QUALIFIED','DISQUALIFIED','CONVERTED')
        );
END
GO
