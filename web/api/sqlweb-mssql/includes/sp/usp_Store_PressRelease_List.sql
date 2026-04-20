-- usp_Store_PressRelease_List
-- Lista comunicados de prensa con filtro opcional de status + paginado.

IF OBJECT_ID('dbo.usp_Store_PressRelease_List', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_Store_PressRelease_List;
GO

CREATE PROCEDURE dbo.usp_Store_PressRelease_List
    @CompanyId  INT           = 1,
    @Status     NVARCHAR(20)  = NULL,
    @Page       INT           = 1,
    @Limit      INT           = 20,
    @TotalCount INT           OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @offset INT = (CASE WHEN @Page < 1 THEN 0 ELSE (@Page - 1) END) * (CASE WHEN @Limit < 1 THEN 1 ELSE @Limit END);
    DECLARE @lim INT = CASE WHEN @Limit < 1 THEN 1 ELSE @Limit END;

    SELECT @TotalCount = COUNT(*)
      FROM store.PressRelease
     WHERE CompanyId = @CompanyId
       AND (@Status IS NULL OR Status = @Status);

    SELECT
        PressReleaseId,
        Slug,
        Title,
        Excerpt,
        CoverImageUrl,
        Tags,
        Status,
        PublishedAt,
        UpdatedAt,
        CreatedAt
      FROM store.PressRelease
     WHERE CompanyId = @CompanyId
       AND (@Status IS NULL OR Status = @Status)
     ORDER BY ISNULL(PublishedAt, CreatedAt) DESC
     OFFSET @offset ROWS FETCH NEXT @lim ROWS ONLY;
END
GO
