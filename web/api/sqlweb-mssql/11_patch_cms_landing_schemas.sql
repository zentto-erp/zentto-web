-- 11_patch_cms_landing_schemas.sql
-- CMS Landing Schemas (equivalente T-SQL de 00161_cms_landing_schemas.sql).
-- Persistencia de LandingConfig JSON por tenant/vertical/slug/locale + versioning + preview token.
-- Compatible SQL Server 2012+.
USE zentto_dev;
GO

-- ── Schema cms (idempotente con 07_patch_cms.sql) ─────────────────────────────
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'cms')
    EXEC('CREATE SCHEMA cms');
GO

-- ── Tabla cms.LandingSchema ───────────────────────────────────────────────────
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'LandingSchema' AND schema_id = SCHEMA_ID('cms'))
BEGIN
    CREATE TABLE cms.LandingSchema (
        LandingSchemaId  INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        CompanyId        INT              NOT NULL,
        Vertical         VARCHAR(50)      NOT NULL,
        Slug             VARCHAR(100)     NOT NULL CONSTRAINT DF_cms_LandingSchema_Slug DEFAULT 'default',
        Locale           VARCHAR(10)      NOT NULL CONSTRAINT DF_cms_LandingSchema_Locale DEFAULT 'es',
        DraftSchema      NVARCHAR(MAX)    NOT NULL,
        PublishedSchema  NVARCHAR(MAX)    NULL,
        ThemeTokens      NVARCHAR(MAX)    NULL,
        SeoMeta          NVARCHAR(MAX)    NULL,
        Version          INT              NOT NULL CONSTRAINT DF_cms_LandingSchema_Version DEFAULT 1,
        Status           VARCHAR(20)      NOT NULL CONSTRAINT DF_cms_LandingSchema_Status DEFAULT 'draft',
        PreviewToken     VARCHAR(64)      NULL,
        PublishedAt      DATETIME2        NULL,
        PublishedBy      INT              NULL,
        CreatedAt        DATETIME2        NOT NULL CONSTRAINT DF_cms_LandingSchema_CreatedAt DEFAULT SYSUTCDATETIME(),
        CreatedBy        INT              NULL,
        UpdatedAt        DATETIME2        NOT NULL CONSTRAINT DF_cms_LandingSchema_UpdatedAt DEFAULT SYSUTCDATETIME(),
        UpdatedBy        INT              NULL,
        CONSTRAINT UQ_cms_LandingSchema_Company_Vertical_Slug_Locale
            UNIQUE (CompanyId, Vertical, Slug, Locale),
        CONSTRAINT CK_cms_LandingSchema_Status
            CHECK (Status IN ('draft','published','archived'))
    );

    CREATE INDEX IX_cms_LandingSchema_Company_Vertical
        ON cms.LandingSchema (CompanyId, Vertical, Status);

    -- Filtered index: solo filas con PreviewToken NOT NULL.
    CREATE INDEX IX_cms_LandingSchema_PreviewToken
        ON cms.LandingSchema (PreviewToken)
        WHERE PreviewToken IS NOT NULL;
END
GO

-- ── Tabla cms.LandingSchemaHistory ────────────────────────────────────────────
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'LandingSchemaHistory' AND schema_id = SCHEMA_ID('cms'))
BEGIN
    CREATE TABLE cms.LandingSchemaHistory (
        LandingSchemaHistoryId  INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        LandingSchemaId         INT               NOT NULL,
        Version                 INT               NOT NULL,
        [Schema]                NVARCHAR(MAX)     NOT NULL,
        ThemeTokens             NVARCHAR(MAX)     NULL,
        SeoMeta                 NVARCHAR(MAX)     NULL,
        PublishedAt             DATETIME2         NOT NULL CONSTRAINT DF_cms_LandingSchemaHistory_PublishedAt DEFAULT SYSUTCDATETIME(),
        PublishedBy             INT               NULL,
        CONSTRAINT FK_cms_LandingSchemaHistory_LandingSchema
            FOREIGN KEY (LandingSchemaId) REFERENCES cms.LandingSchema (LandingSchemaId)
            ON DELETE CASCADE
    );

    CREATE INDEX IX_cms_LandingSchemaHistory_Schema_Version
        ON cms.LandingSchemaHistory (LandingSchemaId, Version DESC);
END
GO
