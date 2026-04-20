-- ============================================================
-- Patch 07: store schema — CMS Pages + Press Releases + Contact
-- SQL Server 2012+ compatible
-- Equivalente de migración 00147_store_cms_pages_and_press.sql (PG)
-- ============================================================
USE zentto_dev;
GO

-- ── store.CmsPage ─────────────────────────────────────────────────────────────
IF OBJECT_ID('store.CmsPage', 'U') IS NULL
CREATE TABLE store.CmsPage (
    CmsPageId    BIGINT        NOT NULL IDENTITY(1,1) CONSTRAINT PK_store_CmsPage PRIMARY KEY,
    CompanyId    INT           NOT NULL CONSTRAINT DF_store_CmsPage_CompanyId DEFAULT(1),
    Slug         NVARCHAR(120) NOT NULL,
    Title        NVARCHAR(200) NOT NULL,
    Subtitle     NVARCHAR(300) NULL,
    TemplateKey  NVARCHAR(80)  NULL,
    Config       NVARCHAR(MAX) NOT NULL CONSTRAINT DF_store_CmsPage_Config DEFAULT(N'{"sections":[]}'),
    Seo          NVARCHAR(MAX) NOT NULL CONSTRAINT DF_store_CmsPage_Seo    DEFAULT(N'{}'),
    Status       NVARCHAR(20)  NOT NULL CONSTRAINT DF_store_CmsPage_Status DEFAULT(N'draft'),
    PublishedAt  DATETIME      NULL,
    CreatedAt    DATETIME      NOT NULL CONSTRAINT DF_store_CmsPage_Created DEFAULT(GETUTCDATE()),
    UpdatedAt    DATETIME      NOT NULL CONSTRAINT DF_store_CmsPage_Updated DEFAULT(GETUTCDATE()),
    CONSTRAINT UK_store_CmsPage_CompanySlug UNIQUE (CompanyId, Slug),
    CONSTRAINT CK_store_CmsPage_Status CHECK (Status IN (N'draft', N'published', N'archived'))
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_store_CmsPage_CompanyStatus' AND object_id = OBJECT_ID('store.CmsPage'))
    CREATE INDEX IX_store_CmsPage_CompanyStatus ON store.CmsPage (CompanyId, Status, Slug);
GO

-- ── store.PressRelease ────────────────────────────────────────────────────────
IF OBJECT_ID('store.PressRelease', 'U') IS NULL
CREATE TABLE store.PressRelease (
    PressReleaseId BIGINT        NOT NULL IDENTITY(1,1) CONSTRAINT PK_store_PressRelease PRIMARY KEY,
    CompanyId      INT           NOT NULL CONSTRAINT DF_store_PressRelease_CompanyId DEFAULT(1),
    Slug           NVARCHAR(160) NOT NULL,
    Title          NVARCHAR(240) NOT NULL,
    Excerpt        NVARCHAR(600) NULL,
    Body           NVARCHAR(MAX) NULL,
    CoverImageUrl  NVARCHAR(500) NULL,
    -- Tags como texto separado por comas (SQL Server 2012 no soporta arrays)
    Tags           NVARCHAR(1000) NULL,
    Status         NVARCHAR(20)  NOT NULL CONSTRAINT DF_store_PressRelease_Status DEFAULT(N'draft'),
    PublishedAt    DATETIME      NULL,
    CreatedAt      DATETIME      NOT NULL CONSTRAINT DF_store_PressRelease_Created DEFAULT(GETUTCDATE()),
    UpdatedAt      DATETIME      NOT NULL CONSTRAINT DF_store_PressRelease_Updated DEFAULT(GETUTCDATE()),
    CONSTRAINT UK_store_PressRelease_CompanySlug UNIQUE (CompanyId, Slug),
    CONSTRAINT CK_store_PressRelease_Status CHECK (Status IN (N'draft', N'published', N'archived'))
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_store_PressRelease_Status' AND object_id = OBJECT_ID('store.PressRelease'))
    CREATE INDEX IX_store_PressRelease_Status ON store.PressRelease (CompanyId, Status, PublishedAt DESC);
GO

-- ── store.ContactMessage ──────────────────────────────────────────────────────
IF OBJECT_ID('store.ContactMessage', 'U') IS NULL
CREATE TABLE store.ContactMessage (
    ContactMessageId BIGINT        NOT NULL IDENTITY(1,1) CONSTRAINT PK_store_ContactMessage PRIMARY KEY,
    CompanyId        INT           NOT NULL CONSTRAINT DF_store_ContactMessage_CompanyId DEFAULT(1),
    Name             NVARCHAR(160) NOT NULL,
    Email            NVARCHAR(240) NOT NULL,
    Phone            NVARCHAR(40)  NULL,
    Subject          NVARCHAR(240) NULL,
    Message          NVARCHAR(MAX) NOT NULL,
    Source           NVARCHAR(60)  CONSTRAINT DF_store_ContactMessage_Source DEFAULT(N'contact'),
    Status           NVARCHAR(20)  NOT NULL CONSTRAINT DF_store_ContactMessage_Status DEFAULT(N'new'),
    CreatedAt        DATETIME      NOT NULL CONSTRAINT DF_store_ContactMessage_Created DEFAULT(GETUTCDATE()),
    CONSTRAINT CK_store_ContactMessage_Status CHECK (Status IN (N'new', N'read', N'replied', N'archived'))
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_store_ContactMessage_CompanyStatus' AND object_id = OBJECT_ID('store.ContactMessage'))
    CREATE INDEX IX_store_ContactMessage_CompanyStatus ON store.ContactMessage (CompanyId, Status, CreatedAt DESC);
GO
