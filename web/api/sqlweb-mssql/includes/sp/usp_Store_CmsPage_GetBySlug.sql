-- usp_Store_CmsPage_GetBySlug
-- Página CMS pública: solo retorna si Status='published'.

IF OBJECT_ID('dbo.usp_Store_CmsPage_GetBySlug', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_Store_CmsPage_GetBySlug;
GO

CREATE PROCEDURE dbo.usp_Store_CmsPage_GetBySlug
    @CompanyId INT           = 1,
    @Slug      NVARCHAR(120) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT
        CmsPageId,
        Slug,
        Title,
        Subtitle,
        TemplateKey,
        Config,
        Seo,
        Status,
        PublishedAt,
        UpdatedAt
      FROM store.CmsPage
     WHERE CompanyId = @CompanyId
       AND Slug      = @Slug
       AND Status    = N'published';
END
GO
