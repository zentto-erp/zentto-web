-- usp_Cms_LandingSchema_UpsertDraft
-- Editor admin: crea o actualiza el DraftSchema sin publicar.
-- Devuelve recordset con columnas (ok, mensaje, LandingSchemaId) para paridad con PG.
-- Compatible SQL Server 2012+.

IF OBJECT_ID('dbo.usp_Cms_LandingSchema_UpsertDraft', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_Cms_LandingSchema_UpsertDraft;
GO

CREATE PROCEDURE dbo.usp_Cms_LandingSchema_UpsertDraft
    @LandingSchemaId   INT            = NULL,
    @CompanyId         INT            = 1,
    @Vertical          VARCHAR(50)    = NULL,
    @Slug              VARCHAR(100)   = 'default',
    @Locale            VARCHAR(10)    = 'es',
    @DraftSchema       NVARCHAR(MAX)  = NULL,
    @ThemeTokens       NVARCHAR(MAX)  = NULL,
    @SeoMeta           NVARCHAR(MAX)  = NULL,
    @UserId            INT            = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF @Vertical IS NULL OR LTRIM(RTRIM(@Vertical)) = ''
        BEGIN
            SELECT CAST(0 AS BIT) AS ok, N'vertical_required' AS mensaje, CAST(NULL AS INT) AS LandingSchemaId;
            RETURN;
        END

        IF @DraftSchema IS NULL
        BEGIN
            SELECT CAST(0 AS BIT) AS ok, N'draft_schema_required' AS mensaje, CAST(NULL AS INT) AS LandingSchemaId;
            RETURN;
        END

        DECLARE @ExistingId INT;

        IF @LandingSchemaId IS NULL OR @LandingSchemaId = 0
        BEGIN
            -- Reuse existing row by (CompanyId, Vertical, Slug, Locale)
            SELECT TOP 1 @ExistingId = LandingSchemaId
            FROM cms.LandingSchema
            WHERE CompanyId = @CompanyId
              AND Vertical  = @Vertical
              AND Slug      = @Slug
              AND Locale    = @Locale;

            IF @ExistingId IS NOT NULL
            BEGIN
                UPDATE cms.LandingSchema SET
                    DraftSchema = @DraftSchema,
                    ThemeTokens = COALESCE(@ThemeTokens, ThemeTokens),
                    SeoMeta     = COALESCE(@SeoMeta, SeoMeta),
                    UpdatedAt   = SYSUTCDATETIME(),
                    UpdatedBy   = @UserId
                WHERE LandingSchemaId = @ExistingId;

                SELECT CAST(1 AS BIT) AS ok, N'landing_draft_updated' AS mensaje, @ExistingId AS LandingSchemaId;
                RETURN;
            END

            INSERT INTO cms.LandingSchema (
                CompanyId, Vertical, Slug, Locale,
                DraftSchema, ThemeTokens, SeoMeta,
                Status, CreatedBy, UpdatedBy
            ) VALUES (
                @CompanyId, @Vertical, @Slug, @Locale,
                @DraftSchema, @ThemeTokens, @SeoMeta,
                'draft', @UserId, @UserId
            );

            SELECT CAST(1 AS BIT) AS ok, N'landing_draft_created' AS mensaje, CAST(SCOPE_IDENTITY() AS INT) AS LandingSchemaId;
        END
        ELSE
        BEGIN
            UPDATE cms.LandingSchema SET
                DraftSchema = @DraftSchema,
                ThemeTokens = COALESCE(@ThemeTokens, ThemeTokens),
                SeoMeta     = COALESCE(@SeoMeta, SeoMeta),
                UpdatedAt   = SYSUTCDATETIME(),
                UpdatedBy   = @UserId
            WHERE LandingSchemaId = @LandingSchemaId
              AND CompanyId       = @CompanyId;

            IF @@ROWCOUNT = 0
            BEGIN
                SELECT CAST(0 AS BIT) AS ok, N'landing_not_found' AS mensaje, CAST(NULL AS INT) AS LandingSchemaId;
                RETURN;
            END

            SELECT CAST(1 AS BIT) AS ok, N'landing_draft_updated' AS mensaje, @LandingSchemaId AS LandingSchemaId;
        END
    END TRY
    BEGIN CATCH
        SELECT CAST(0 AS BIT) AS ok, LEFT(ERROR_MESSAGE(), 500) AS mensaje, CAST(NULL AS INT) AS LandingSchemaId;
    END CATCH
END
GO
