-- usp_Store_CmsPage_List
-- Lista páginas CMS con filtro opcional de status + paginado.
-- SQL Server 2012+ (OFFSET ... FETCH).

IF OBJECT_ID('dbo.usp_Store_CmsPage_List', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_Store_CmsPage_List;
GO

CREATE PROCEDURE dbo.usp_Store_CmsPage_List
    @CompanyId  INT           = 1,
    @Status     NVARCHAR(20)  = NULL,
    @Page       INT           = 1,
    @Limit      INT           = 50,
    @TotalCount INT           OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @offset INT = (CASE WHEN @Page < 1 THEN 0 ELSE (@Page - 1) END) * (CASE WHEN @Limit < 1 THEN 1 ELSE @Limit END);
    DECLARE @lim INT = CASE WHEN @Limit < 1 THEN 1 ELSE @Limit END;

    SELECT @TotalCount = COUNT(*)
      FROM store.CmsPage
     WHERE CompanyId = @CompanyId
       AND (@Status IS NULL OR Status = @Status);

    SELECT
        CmsPageId,
        Slug,
        Title,
        Subtitle,
        TemplateKey,
        Status,
        PublishedAt,
        UpdatedAt,
        CreatedAt
      FROM store.CmsPage
     WHERE CompanyId = @CompanyId
       AND (@Status IS NULL OR Status = @Status)
     ORDER BY UpdatedAt DESC
     OFFSET @offset ROWS FETCH NEXT @lim ROWS ONLY;
END
GO
