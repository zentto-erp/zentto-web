-- usp_Store_CmsPage_GetByIdAdmin
-- Detalle admin de página CMS (cualquier status).

IF OBJECT_ID('dbo.usp_Store_CmsPage_GetByIdAdmin', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_Store_CmsPage_GetByIdAdmin;
GO

CREATE PROCEDURE dbo.usp_Store_CmsPage_GetByIdAdmin
    @CompanyId  INT    = 1,
    @CmsPageId  BIGINT = NULL
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
        UpdatedAt,
        CreatedAt
      FROM store.CmsPage
     WHERE CompanyId = @CompanyId
       AND CmsPageId = @CmsPageId;
END
GO
