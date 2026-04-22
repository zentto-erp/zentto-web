-- usp_Cms_LandingSchema_GetPublished
-- Lectura pública (SSG/SSR) del PublishedSchema. Scope por CompanyId/Vertical/Slug/Locale.
-- Compatible SQL Server 2012+.

IF OBJECT_ID('dbo.usp_Cms_LandingSchema_GetPublished', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_Cms_LandingSchema_GetPublished;
GO

CREATE PROCEDURE dbo.usp_Cms_LandingSchema_GetPublished
    @CompanyId  INT,
    @Vertical   VARCHAR(50),
    @Slug       VARCHAR(100) = 'default',
    @Locale     VARCHAR(10)  = 'es'
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 1
        l.LandingSchemaId, l.CompanyId, l.Vertical, l.Slug, l.Locale,
        l.PublishedSchema AS [Schema],
        l.ThemeTokens, l.SeoMeta,
        l.Version, l.Status, l.PublishedAt, l.UpdatedAt
    FROM cms.LandingSchema l
    WHERE l.CompanyId = @CompanyId
      AND l.Vertical  = @Vertical
      AND l.Slug      = @Slug
      AND l.Locale    = @Locale
      AND l.Status    = 'published'
      AND l.PublishedSchema IS NOT NULL;
END
GO
