-- =============================================
-- Tabla sys.Lead — Leads de landing page
-- =============================================
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'sys' AND TABLE_NAME = 'Lead')
BEGIN
    CREATE TABLE sys.Lead (
        LeadId      INT IDENTITY(1,1) PRIMARY KEY,
        Email       NVARCHAR(255) NOT NULL,
        FullName    NVARCHAR(255) NOT NULL,
        Company     NVARCHAR(255) NULL,
        Country     NVARCHAR(10)  NULL,
        Source      NVARCHAR(100) NOT NULL DEFAULT 'zentto-landing',
        CreatedAt   DATETIME2     NOT NULL DEFAULT SYSUTCDATETIME(),
        UpdatedAt   DATETIME2     NOT NULL DEFAULT SYSUTCDATETIME(),

        CONSTRAINT UQ_Lead_Email UNIQUE (Email)
    );
END;
GO
