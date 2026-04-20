-- usp_Cms_Post_Get
-- Detalle de post por Slug+Locale.
-- Compatible SQL Server 2012+.

IF OBJECT_ID('dbo.usp_Cms_Post_Get', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_Cms_Post_Get;
GO

CREATE PROCEDURE dbo.usp_Cms_Post_Get
    @Slug   VARCHAR(200),
    @Locale VARCHAR(10) = 'es'
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 1
        p.PostId, p.CompanyId, p.Slug, p.Vertical, p.Category, p.Locale,
        p.Title, p.Excerpt, p.Body, p.CoverUrl,
        p.AuthorName, p.AuthorSlug, p.AuthorAvatar,
        p.Tags, p.ReadingMin,
        p.SeoTitle, p.SeoDescription, p.SeoImageUrl,
        p.Status, p.PublishedAt, p.CreatedAt, p.UpdatedAt
    FROM cms.Post p
    WHERE p.Slug = @Slug
      AND p.Locale = @Locale;
END
GO
