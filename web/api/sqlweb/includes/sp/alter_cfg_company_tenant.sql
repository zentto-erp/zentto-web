-- ============================================================
-- Multi-tenant: agregar columnas de suscripción a cfg.Company
-- SQL Server — idempotente con IF NOT EXISTS
-- ============================================================
USE DatqBoxWeb;
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('cfg.Company') AND name = 'Plan')
    ALTER TABLE cfg.Company ADD Plan NVARCHAR(30) NOT NULL DEFAULT 'FREE';
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('cfg.Company') AND name = 'TenantStatus')
    ALTER TABLE cfg.Company ADD TenantStatus NVARCHAR(20) NOT NULL DEFAULT 'ACTIVE';
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('cfg.Company') AND name = 'OwnerEmail')
    ALTER TABLE cfg.Company ADD OwnerEmail NVARCHAR(150) NULL;
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('cfg.Company') AND name = 'ProvisionedAt')
    ALTER TABLE cfg.Company ADD ProvisionedAt DATETIME2 NULL;
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('cfg.Company') AND name = 'PaddleSubscriptionId')
    ALTER TABLE cfg.Company ADD PaddleSubscriptionId NVARCHAR(100) NULL;
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID('cfg.Company') AND name = 'IX_cfg_Company_OwnerEmail')
    CREATE INDEX IX_cfg_Company_OwnerEmail ON cfg.Company(OwnerEmail) WHERE OwnerEmail IS NOT NULL;
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID('cfg.Company') AND name = 'IX_cfg_Company_TenantStatus')
    CREATE INDEX IX_cfg_Company_TenantStatus ON cfg.Company(TenantStatus);
GO
