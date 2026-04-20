-- 07_patch_store_admin_writes.sql
-- Columnas y tablas adicionales para el backoffice ecommerce.
-- Agrega columnas SEO + publicación en mstr.Product y moderación en store.ProductReview.
-- También crea cfg.MediaAsset / cfg.EntityImage si no existen (para el Images_Set SP).
-- Compatible SQL Server 2012+ (compat level 110).

SET NOCOUNT ON;
GO

-- ─── mstr.Product: columnas SEO + publicación store ───
IF COL_LENGTH('mstr.Product', 'MetaTitle') IS NULL
    ALTER TABLE mstr.Product ADD MetaTitle NVARCHAR(200) NULL;
GO

IF COL_LENGTH('mstr.Product', 'MetaDescription') IS NULL
    ALTER TABLE mstr.Product ADD MetaDescription NVARCHAR(320) NULL;
GO

IF COL_LENGTH('mstr.Product', 'IsPublishedStore') IS NULL
    ALTER TABLE mstr.Product ADD IsPublishedStore BIT NOT NULL CONSTRAINT DF_master_Product_IsPublishedStore DEFAULT 0;
GO

IF COL_LENGTH('mstr.Product', 'PublishedAt') IS NULL
    ALTER TABLE mstr.Product ADD PublishedAt DATETIME2(0) NULL;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_master_Product_PublishedStore' AND object_id = OBJECT_ID('mstr.Product'))
    CREATE INDEX IX_master_Product_PublishedStore ON mstr.Product (CompanyId, IsPublishedStore, PublishedAt DESC) WHERE IsDeleted = 0;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UQ_master_Product_Slug_Company' AND object_id = OBJECT_ID('mstr.Product'))
    CREATE UNIQUE INDEX UQ_master_Product_Slug_Company ON mstr.Product (CompanyId, Slug) WHERE Slug IS NOT NULL AND IsDeleted = 0;
GO

-- ─── store.ProductReview: moderación ──────────────────
IF COL_LENGTH('store.ProductReview', 'Status') IS NULL
BEGIN
    ALTER TABLE store.ProductReview
        ADD [Status] NVARCHAR(20) NOT NULL CONSTRAINT DF_ProductReview_Status DEFAULT 'pending';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_ProductReview_Status')
    ALTER TABLE store.ProductReview
        ADD CONSTRAINT CK_ProductReview_Status CHECK ([Status] IN ('pending', 'approved', 'rejected'));
GO

IF COL_LENGTH('store.ProductReview', 'ModeratedAt') IS NULL
    ALTER TABLE store.ProductReview ADD ModeratedAt DATETIME2(0) NULL;
GO

IF COL_LENGTH('store.ProductReview', 'ModeratorUser') IS NULL
    ALTER TABLE store.ProductReview ADD ModeratorUser NVARCHAR(60) NULL;
GO

-- Sincronizar Status con IsApproved para datos existentes (solo una vez)
UPDATE store.ProductReview
   SET [Status] = CASE WHEN IsApproved = 1 THEN 'approved' ELSE 'pending' END
 WHERE [Status] = 'pending' AND IsApproved = 1;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_ProductReview_Status' AND object_id = OBJECT_ID('store.ProductReview'))
    CREATE INDEX IX_ProductReview_Status ON store.ProductReview (CompanyId, [Status], CreatedAt DESC);
GO

-- ─── cfg.MediaAsset / cfg.EntityImage ──────────────────
IF SCHEMA_ID('cfg') IS NULL
    EXEC('CREATE SCHEMA cfg');
GO

IF OBJECT_ID('cfg.MediaAsset', 'U') IS NULL
CREATE TABLE cfg.MediaAsset (
    MediaAssetId     BIGINT IDENTITY(1,1) PRIMARY KEY,
    CompanyId        INT             NOT NULL,
    BranchId         INT             NOT NULL DEFAULT 1,
    StorageProvider  NVARCHAR(30)     NOT NULL DEFAULT 'external',
    StorageKey       NVARCHAR(500)    NOT NULL,
    PublicUrl        NVARCHAR(500)    NOT NULL,
    OriginalFileName NVARCHAR(255)    NULL,
    MimeType         NVARCHAR(100)    NULL,
    FileExtension    NVARCHAR(10)     NULL,
    FileSizeBytes    BIGINT          NOT NULL DEFAULT 0,
    AltText          NVARCHAR(255)    NULL,
    WidthPx          INT             NULL,
    HeightPx         INT             NULL,
    IsActive         BIT             NOT NULL DEFAULT 1,
    IsDeleted        BIT             NOT NULL DEFAULT 0,
    CreatedAt        DATETIME2(0)       NOT NULL DEFAULT SYSUTCDATETIME(),
    UpdatedAt        DATETIME2(0)       NOT NULL DEFAULT SYSUTCDATETIME()
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_MediaAsset_Company_Url' AND object_id = OBJECT_ID('cfg.MediaAsset'))
    CREATE INDEX IX_MediaAsset_Company_Url ON cfg.MediaAsset (CompanyId, PublicUrl) WHERE IsDeleted = 0;
GO

IF OBJECT_ID('cfg.EntityImage', 'U') IS NULL
CREATE TABLE cfg.EntityImage (
    EntityImageId BIGINT IDENTITY(1,1) PRIMARY KEY,
    CompanyId     INT             NOT NULL,
    BranchId      INT             NOT NULL DEFAULT 1,
    EntityType    NVARCHAR(50)     NOT NULL,
    EntityId      BIGINT          NOT NULL,
    MediaAssetId  BIGINT          NOT NULL,
    RoleCode      NVARCHAR(50)     NOT NULL DEFAULT 'PRODUCT_IMAGE',
    SortOrder     INT             NOT NULL DEFAULT 0,
    IsPrimary     BIT             NOT NULL DEFAULT 0,
    IsActive      BIT             NOT NULL DEFAULT 1,
    IsDeleted     BIT             NOT NULL DEFAULT 0,
    CreatedAt     DATETIME2(0)       NOT NULL DEFAULT SYSUTCDATETIME(),
    UpdatedAt     DATETIME2(0)       NOT NULL DEFAULT SYSUTCDATETIME()
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_EntityImage_Entity' AND object_id = OBJECT_ID('cfg.EntityImage'))
    CREATE INDEX IX_EntityImage_Entity ON cfg.EntityImage (CompanyId, EntityType, EntityId, IsDeleted, IsActive);
GO

PRINT '07_patch_store_admin_writes: OK';
GO
