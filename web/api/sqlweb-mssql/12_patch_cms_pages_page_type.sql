-- 12_patch_cms_pages_page_type.sql
-- CMS Pages · agrega columna PageType a cms.Page para distinguir páginas
-- corporativas por propósito (about / contact / press / legal-terms /
-- legal-privacy / case-study / custom).
--
-- Equivalente T-SQL de la migración goose 00167_cms_pages_page_type.sql.
-- Ejecutar sobre zentto_dev después de los patches anteriores (01..11).
USE zentto_dev;
GO

-- ── Columna PageType ─────────────────────────────────────────────────────────
IF NOT EXISTS (
    SELECT 1
    FROM sys.columns
    WHERE object_id = OBJECT_ID('cms.Page')
      AND name = 'PageType'
)
    ALTER TABLE cms.[Page]
        ADD PageType VARCHAR(30) NOT NULL CONSTRAINT DF_cms_Page_PageType DEFAULT 'custom';
GO

-- ── CHECK constraint ─────────────────────────────────────────────────────────
IF EXISTS (
    SELECT 1
    FROM sys.check_constraints
    WHERE name = 'ck_cms_page_page_type' AND parent_object_id = OBJECT_ID('cms.Page')
)
    ALTER TABLE cms.[Page] DROP CONSTRAINT ck_cms_page_page_type;
GO

ALTER TABLE cms.[Page]
    ADD CONSTRAINT ck_cms_page_page_type
    CHECK (PageType IN (
        'about',
        'contact',
        'press',
        'legal-terms',
        'legal-privacy',
        'case-study',
        'custom'
    ));
GO

-- ── Índice por (CompanyId, Vertical, PageType) ───────────────────────────────
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'ix_cms_page_company_vertical_type'
      AND object_id = OBJECT_ID('cms.Page')
)
    CREATE INDEX ix_cms_page_company_vertical_type
        ON cms.[Page] (CompanyId, Vertical, PageType);
GO
