-- usp_Cms_Page_Get
-- Detalle de página por Slug + Vertical + Locale. Devuelve PageType en el row.
-- Compatible SQL Server 2012+.

IF OBJECT_ID('dbo.usp_Cms_Page_Get', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_Cms_Page_Get;
GO

CREATE PROCEDURE dbo.usp_Cms_Page_Get
    @Slug     VARCHAR(100),
    @Vertical VARCHAR(50)  = 'corporate',
    @Locale   VARCHAR(10)  = 'es'
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 1
        p.PageId, p.CompanyId, p.Slug, p.Vertical, p.PageType, p.Locale,
        p.Title, p.Body, p.Meta,
        p.SeoTitle, p.SeoDescription,
        p.Status, p.PublishedAt, p.CreatedAt, p.UpdatedAt
    FROM cms.[Page] p
    WHERE p.Slug = @Slug
      AND p.Vertical = @Vertical
      AND p.Locale = @Locale;
END
GO
