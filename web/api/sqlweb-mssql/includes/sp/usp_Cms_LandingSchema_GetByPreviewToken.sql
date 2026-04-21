-- usp_Cms_LandingSchema_GetByPreviewToken
-- Público sin auth: devuelve DraftSchema si el token UUID coincide.
-- Útil para preview cross-subdomain donde la cookie httpOnly de zentto.net no llega.
-- Compatible SQL Server 2012+.

IF OBJECT_ID('dbo.usp_Cms_LandingSchema_GetByPreviewToken', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_Cms_LandingSchema_GetByPreviewToken;
GO

CREATE PROCEDURE dbo.usp_Cms_LandingSchema_GetByPreviewToken
    @PreviewToken VARCHAR(64)
AS
BEGIN
    SET NOCOUNT ON;

    IF @PreviewToken IS NULL OR LTRIM(RTRIM(@PreviewToken)) = ''
    BEGIN
        SELECT TOP 0
            CAST(NULL AS INT)         AS LandingSchemaId,
            CAST(NULL AS INT)         AS CompanyId,
            CAST(NULL AS VARCHAR(50)) AS Vertical,
            CAST(NULL AS VARCHAR(100))AS Slug,
            CAST(NULL AS VARCHAR(10)) AS Locale,
            CAST(NULL AS NVARCHAR(MAX)) AS [Schema],
            CAST(NULL AS NVARCHAR(MAX)) AS ThemeTokens,
            CAST(NULL AS NVARCHAR(MAX)) AS SeoMeta,
            CAST(NULL AS INT)         AS Version,
            CAST(NULL AS VARCHAR(20)) AS Status,
            CAST(NULL AS DATETIME2)   AS UpdatedAt;
        RETURN;
    END

    SELECT TOP 1
        l.LandingSchemaId, l.CompanyId, l.Vertical, l.Slug, l.Locale,
        l.DraftSchema AS [Schema],
        l.ThemeTokens, l.SeoMeta,
        l.Version, l.Status, l.UpdatedAt
    FROM cms.LandingSchema l
    WHERE l.PreviewToken = @PreviewToken;
END
GO
