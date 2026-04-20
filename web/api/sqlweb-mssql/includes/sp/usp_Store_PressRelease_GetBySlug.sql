-- usp_Store_PressRelease_GetBySlug
-- Comunicado público: solo published.

IF OBJECT_ID('dbo.usp_Store_PressRelease_GetBySlug', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_Store_PressRelease_GetBySlug;
GO

CREATE PROCEDURE dbo.usp_Store_PressRelease_GetBySlug
    @CompanyId INT           = 1,
    @Slug      NVARCHAR(160) = NULL
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
        UpdatedAt
      FROM store.PressRelease
     WHERE CompanyId = @CompanyId
       AND Slug      = @Slug
       AND Status    = N'published';
END
GO
