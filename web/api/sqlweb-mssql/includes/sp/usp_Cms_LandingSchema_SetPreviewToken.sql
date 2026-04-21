-- usp_Cms_LandingSchema_SetPreviewToken
-- Rota (o limpia con NULL/'') el PreviewToken de un landing.
-- Compatible SQL Server 2012+.

IF OBJECT_ID('dbo.usp_Cms_LandingSchema_SetPreviewToken', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_Cms_LandingSchema_SetPreviewToken;
GO

CREATE PROCEDURE dbo.usp_Cms_LandingSchema_SetPreviewToken
    @LandingSchemaId INT,
    @CompanyId       INT,
    @Token           VARCHAR(64) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Normalized VARCHAR(64) = NULLIF(LTRIM(RTRIM(ISNULL(@Token, ''))), '');

    UPDATE cms.LandingSchema
       SET PreviewToken = @Normalized,
           UpdatedAt    = SYSUTCDATETIME()
     WHERE LandingSchemaId = @LandingSchemaId
       AND CompanyId       = @CompanyId;

    IF @@ROWCOUNT = 0
        SELECT CAST(0 AS BIT) AS ok, N'landing_not_found' AS mensaje, CAST(NULL AS VARCHAR(64)) AS PreviewToken;
    ELSE
        SELECT CAST(1 AS BIT) AS ok, N'preview_token_set' AS mensaje, @Normalized AS PreviewToken;
END
GO
