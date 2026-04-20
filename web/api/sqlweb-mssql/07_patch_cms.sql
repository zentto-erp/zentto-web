-- 07_patch_cms.sql
-- CMS Foundation: schema cms + tablas Post + Page (ADR-CMS-001).
-- Compatible SQL Server 2012+.

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'cms')
    EXEC('CREATE SCHEMA cms');
GO

-- ── Tabla cms.Post ────────────────────────────────────────────────────────────
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'Post' AND schema_id = SCHEMA_ID('cms'))
BEGIN
    CREATE TABLE cms.Post (
        PostId          INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        CompanyId       INT              NOT NULL CONSTRAINT DF_cms_Post_CompanyId DEFAULT 1,
        Slug            VARCHAR(200)     NOT NULL,
        Vertical        VARCHAR(50)      NOT NULL,
        Category        VARCHAR(50)      NOT NULL,
        Locale          VARCHAR(10)      NOT NULL CONSTRAINT DF_cms_Post_Locale DEFAULT 'es',
        Title           NVARCHAR(300)    NOT NULL,
        Excerpt         NVARCHAR(500)    NOT NULL CONSTRAINT DF_cms_Post_Excerpt DEFAULT '',
        Body            NVARCHAR(MAX)    NOT NULL,
        CoverUrl        VARCHAR(500)     NOT NULL CONSTRAINT DF_cms_Post_CoverUrl DEFAULT '',
        AuthorName      NVARCHAR(200)    NOT NULL CONSTRAINT DF_cms_Post_AuthorName DEFAULT '',
        AuthorSlug      VARCHAR(100)     NOT NULL CONSTRAINT DF_cms_Post_AuthorSlug DEFAULT '',
        AuthorAvatar    VARCHAR(500)     NOT NULL CONSTRAINT DF_cms_Post_AuthorAvatar DEFAULT '',
        Tags            VARCHAR(500)     NOT NULL CONSTRAINT DF_cms_Post_Tags DEFAULT '',
        ReadingMin      INT              NOT NULL CONSTRAINT DF_cms_Post_ReadingMin DEFAULT 5,
        SeoTitle        NVARCHAR(300)    NOT NULL CONSTRAINT DF_cms_Post_SeoTitle DEFAULT '',
        SeoDescription  NVARCHAR(500)    NOT NULL CONSTRAINT DF_cms_Post_SeoDescription DEFAULT '',
        SeoImageUrl     VARCHAR(500)     NOT NULL CONSTRAINT DF_cms_Post_SeoImageUrl DEFAULT '',
        Status          VARCHAR(20)      NOT NULL CONSTRAINT DF_cms_Post_Status DEFAULT 'draft',
        PublishedAt     DATETIME2 NULL,
        CreatedAt       DATETIME2        NOT NULL CONSTRAINT DF_cms_Post_CreatedAt DEFAULT SYSUTCDATETIME(),
        UpdatedAt       DATETIME2        NOT NULL CONSTRAINT DF_cms_Post_UpdatedAt DEFAULT SYSUTCDATETIME(),
        CONSTRAINT UQ_cms_Post_Slug_Locale UNIQUE (Slug, Locale),
        CONSTRAINT CK_cms_Post_Status CHECK (Status IN ('draft','published','archived'))
    );

    CREATE INDEX IX_cms_Post_Vertical     ON cms.Post (Vertical);
    CREATE INDEX IX_cms_Post_Category     ON cms.Post (Category);
    CREATE INDEX IX_cms_Post_Status       ON cms.Post (Status);
    CREATE INDEX IX_cms_Post_PublishedAt  ON cms.Post (PublishedAt DESC);
    CREATE INDEX IX_cms_Post_CompanyId    ON cms.Post (CompanyId);
END
GO

-- ── Tabla cms.Page ────────────────────────────────────────────────────────────
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'Page' AND schema_id = SCHEMA_ID('cms'))
BEGIN
    CREATE TABLE cms.Page (
        PageId          INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        CompanyId       INT              NOT NULL CONSTRAINT DF_cms_Page_CompanyId DEFAULT 1,
        Slug            VARCHAR(100)     NOT NULL,
        Vertical        VARCHAR(50)      NOT NULL CONSTRAINT DF_cms_Page_Vertical DEFAULT 'corporate',
        Locale          VARCHAR(10)      NOT NULL CONSTRAINT DF_cms_Page_Locale DEFAULT 'es',
        Title           NVARCHAR(300)    NOT NULL,
        Body            NVARCHAR(MAX)    NOT NULL,
        Meta            NVARCHAR(MAX)    NOT NULL CONSTRAINT DF_cms_Page_Meta DEFAULT N'{}',
        SeoTitle        NVARCHAR(300)    NOT NULL CONSTRAINT DF_cms_Page_SeoTitle DEFAULT '',
        SeoDescription  NVARCHAR(500)    NOT NULL CONSTRAINT DF_cms_Page_SeoDescription DEFAULT '',
        Status          VARCHAR(20)      NOT NULL CONSTRAINT DF_cms_Page_Status DEFAULT 'draft',
        PublishedAt     DATETIME2 NULL,
        CreatedAt       DATETIME2        NOT NULL CONSTRAINT DF_cms_Page_CreatedAt DEFAULT SYSUTCDATETIME(),
        UpdatedAt       DATETIME2        NOT NULL CONSTRAINT DF_cms_Page_UpdatedAt DEFAULT SYSUTCDATETIME(),
        CONSTRAINT UQ_cms_Page_Slug_Vertical_Locale UNIQUE (Slug, Vertical, Locale),
        CONSTRAINT CK_cms_Page_Status CHECK (Status IN ('draft','published','archived'))
    );

    CREATE INDEX IX_cms_Page_Vertical ON cms.Page (Vertical);
    CREATE INDEX IX_cms_Page_Status   ON cms.Page (Status);
END
GO
