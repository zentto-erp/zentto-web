-- usp_Cms_Post_List
-- Lista paginada de posts. Filtros opcionales por vertical/category/status; locale obligatorio.
-- Compatible SQL Server 2012+. @TotalCount OUTPUT para paginación.

IF OBJECT_ID('dbo.usp_Cms_Post_List', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_Cms_Post_List;
GO

CREATE PROCEDURE dbo.usp_Cms_Post_List
    @Vertical     VARCHAR(50)  = NULL,
    @Category     VARCHAR(50)  = NULL,
    @Locale       VARCHAR(10)  = 'es',
    @Status       VARCHAR(20)  = 'published',
    @Limit        INT          = 20,
    @Offset       INT          = 0,
    @TotalCount   INT          OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT @TotalCount = COUNT(*)
    FROM cms.Post p
    WHERE (@Vertical IS NULL OR p.Vertical = @Vertical)
      AND (@Category IS NULL OR p.Category = @Category)
      AND p.Locale = @Locale
      AND (@Status IS NULL OR p.Status = @Status);

    SELECT
        p.PostId, p.CompanyId, p.Slug, p.Vertical, p.Category, p.Locale,
        p.Title, p.Excerpt, p.CoverUrl,
        p.AuthorName, p.AuthorSlug, p.AuthorAvatar,
        p.Tags, p.ReadingMin, p.Status, p.PublishedAt
    FROM cms.Post p
    WHERE (@Vertical IS NULL OR p.Vertical = @Vertical)
      AND (@Category IS NULL OR p.Category = @Category)
      AND p.Locale = @Locale
      AND (@Status IS NULL OR p.Status = @Status)
    ORDER BY COALESCE(p.PublishedAt, p.CreatedAt) DESC, p.PostId DESC
    OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;
END
GO
