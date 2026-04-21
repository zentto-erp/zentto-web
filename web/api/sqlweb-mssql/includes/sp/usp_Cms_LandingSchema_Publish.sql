-- usp_Cms_LandingSchema_Publish
-- Copia DraftSchema → PublishedSchema + incrementa Version + inserta snapshot en History.
-- Compatible SQL Server 2012+.

IF OBJECT_ID('dbo.usp_Cms_LandingSchema_Publish', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_Cms_LandingSchema_Publish;
GO

CREATE PROCEDURE dbo.usp_Cms_LandingSchema_Publish
    @LandingSchemaId INT,
    @CompanyId       INT,
    @UserId          INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        DECLARE @Draft      NVARCHAR(MAX);
        DECLARE @Theme      NVARCHAR(MAX);
        DECLARE @Seo        NVARCHAR(MAX);
        DECLARE @NewVersion INT;

        SELECT TOP 1
            @Draft      = l.DraftSchema,
            @Theme      = l.ThemeTokens,
            @Seo        = l.SeoMeta,
            @NewVersion = l.Version + 1
        FROM cms.LandingSchema l
        WHERE l.LandingSchemaId = @LandingSchemaId
          AND l.CompanyId       = @CompanyId;

        IF @Draft IS NULL
        BEGIN
            SELECT CAST(0 AS BIT) AS ok, N'landing_not_found' AS mensaje, CAST(0 AS INT) AS Version;
            RETURN;
        END

        BEGIN TRANSACTION;

            UPDATE cms.LandingSchema SET
                PublishedSchema = @Draft,
                Version         = @NewVersion,
                Status          = 'published',
                PublishedAt     = SYSUTCDATETIME(),
                PublishedBy     = @UserId,
                UpdatedAt       = SYSUTCDATETIME(),
                UpdatedBy       = @UserId
            WHERE LandingSchemaId = @LandingSchemaId
              AND CompanyId       = @CompanyId;

            INSERT INTO cms.LandingSchemaHistory (
                LandingSchemaId, Version, [Schema], ThemeTokens, SeoMeta,
                PublishedAt, PublishedBy
            ) VALUES (
                @LandingSchemaId, @NewVersion, @Draft, @Theme, @Seo,
                SYSUTCDATETIME(), @UserId
            );

        COMMIT TRANSACTION;

        SELECT CAST(1 AS BIT) AS ok, N'landing_published' AS mensaje, @NewVersion AS Version;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SELECT CAST(0 AS BIT) AS ok, LEFT(ERROR_MESSAGE(), 500) AS mensaje, CAST(0 AS INT) AS Version;
    END CATCH
END
GO
