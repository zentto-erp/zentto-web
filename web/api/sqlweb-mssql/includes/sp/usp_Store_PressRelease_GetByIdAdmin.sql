-- usp_Store_PressRelease_GetByIdAdmin
-- Admin detalle cualquier status.

IF OBJECT_ID('dbo.usp_Store_PressRelease_GetByIdAdmin', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_Store_PressRelease_GetByIdAdmin;
GO

CREATE PROCEDURE dbo.usp_Store_PressRelease_GetByIdAdmin
    @CompanyId       INT    = 1,
    @PressReleaseId  BIGINT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT
        PressReleaseId,
        Slug,
        Title,
        Excerpt,
        Body,
        CoverImageUrl,
        Tags,
        Status,
        PublishedAt,
        UpdatedAt,
        CreatedAt
      FROM store.PressRelease
     WHERE CompanyId      = @CompanyId
       AND PressReleaseId = @PressReleaseId;
END
GO
