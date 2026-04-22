-- 13_patch_cms_contact_submission.sql
-- CMS Contact Submissions · equivalente T-SQL de la migración goose
-- 00168_cms_contact_submission.sql. Persiste mensajes del ContactFormAdapter.
USE zentto_dev;
GO

-- ── Tabla ────────────────────────────────────────────────────────────────────
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'ContactSubmission' AND schema_id = SCHEMA_ID('cms'))
BEGIN
    CREATE TABLE cms.[ContactSubmission] (
        ContactSubmissionId INT            IDENTITY(1,1) PRIMARY KEY,
        CompanyId           INT            NOT NULL,
        Vertical            VARCHAR(50)    NOT NULL,
        Slug                VARCHAR(100)   NOT NULL CONSTRAINT DF_cms_ContactSubmission_Slug DEFAULT ('contacto'),
        Name                NVARCHAR(200)  NOT NULL,
        Email               VARCHAR(200)   NOT NULL,
        Subject             NVARCHAR(200)  NOT NULL CONSTRAINT DF_cms_ContactSubmission_Subject DEFAULT (''),
        Message             NVARCHAR(MAX)  NOT NULL,
        IpAddress           VARCHAR(45)    NULL,
        UserAgent           NVARCHAR(MAX)  NULL,
        Status              VARCHAR(20)    NOT NULL CONSTRAINT DF_cms_ContactSubmission_Status DEFAULT ('pending'),
        CreatedAt           DATETIME2      NOT NULL CONSTRAINT DF_cms_ContactSubmission_CreatedAt DEFAULT (SYSUTCDATETIME())
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'ix_cms_contactsubmission_company_created' AND object_id = OBJECT_ID('cms.ContactSubmission'))
    CREATE INDEX ix_cms_contactsubmission_company_created
        ON cms.[ContactSubmission] (CompanyId, CreatedAt DESC);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'ix_cms_contactsubmission_vertical_status' AND object_id = OBJECT_ID('cms.ContactSubmission'))
    CREATE INDEX ix_cms_contactsubmission_vertical_status
        ON cms.[ContactSubmission] (Vertical, Status);
GO
