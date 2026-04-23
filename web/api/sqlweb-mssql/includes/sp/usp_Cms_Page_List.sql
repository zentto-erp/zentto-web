-- usp_Cms_Page_List
-- Lista páginas institucionales (acerca, prensa, recursos, legales).
-- Filtro opcional por Vertical y PageType.
-- Compatible SQL Server 2012+.

IF OBJECT_ID('dbo.usp_Cms_Page_List', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_Cms_Page_List;
GO

CREATE PROCEDURE dbo.usp_Cms_Page_List
    @Vertical VARCHAR(50) = NULL,
    @Locale   VARCHAR(10) = 'es',
    @Status   VARCHAR(20) = 'published',
    @PageType VARCHAR(30) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        p.PageId, p.CompanyId, p.Slug, p.Vertical, p.PageType, p.Locale,
        p.Title, p.Status, p.PublishedAt, p.UpdatedAt
    FROM cms.[Page] p
    WHERE (@Vertical IS NULL OR p.Vertical = @Vertical)
      AND p.Locale = @Locale
      AND (@Status IS NULL OR p.Status = @Status)
      AND (@PageType IS NULL OR p.PageType = @PageType)
    ORDER BY p.PageType, p.Slug;
END
GO
