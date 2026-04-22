-- usp_Store_PressRelease_Upsert
-- Insert/Update press release. En T-SQL los tags van como CSV (NVARCHAR).

IF OBJECT_ID('dbo.usp_Store_PressRelease_Upsert', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_Store_PressRelease_Upsert;
GO

CREATE PROCEDURE dbo.usp_Store_PressRelease_Upsert
    @CompanyId      INT            = 1,
    @PressReleaseId BIGINT         = NULL,
    @Slug           NVARCHAR(160)  = NULL,
    @Title          NVARCHAR(240)  = NULL,
    @Excerpt        NVARCHAR(600)  = NULL,
    @Body           NVARCHAR(MAX)  = NULL,
    @CoverImageUrl  NVARCHAR(500)  = NULL,
    @Tags           NVARCHAR(1000) = NULL,
    @Status         NVARCHAR(20)   = N'draft',
    @Resultado      INT            OUTPUT,
    @Mensaje        NVARCHAR(500)  OUTPUT,
    @OutPressReleaseId     BIGINT         OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        IF @Slug IS NULL OR LTRIM(RTRIM(@Slug)) = N''
        BEGIN SET @Resultado = 0; SET @Mensaje = N'slug requerido';  SET @OutPressReleaseId = NULL; RETURN; END
        IF @Title IS NULL OR LTRIM(RTRIM(@Title)) = N''
        BEGIN SET @Resultado = 0; SET @Mensaje = N'title requerido'; SET @OutPressReleaseId = NULL; RETURN; END
        IF @Status NOT IN (N'draft', N'published', N'archived')
        BEGIN SET @Resultado = 0; SET @Mensaje = N'status invalido'; SET @OutPressReleaseId = NULL; RETURN; END

        DECLARE @id BIGINT = @PressReleaseId;
        IF @id IS NULL
        BEGIN
            SELECT TOP 1 @id = PressReleaseId
              FROM store.PressRelease
             WHERE CompanyId = @CompanyId AND Slug = @Slug;
        END

        IF @id IS NULL
        BEGIN
            INSERT INTO store.PressRelease (CompanyId, Slug, Title, Excerpt, Body, CoverImageUrl, Tags, Status, PublishedAt, UpdatedAt, CreatedAt)
            VALUES (
                @CompanyId, @Slug, @Title, @Excerpt, @Body, @CoverImageUrl, @Tags, @Status,
                CASE WHEN @Status = N'published' THEN GETUTCDATE() ELSE NULL END,
                GETUTCDATE(), GETUTCDATE()
            );
            SET @OutPressReleaseId = CAST(SCOPE_IDENTITY() AS BIGINT);
            SET @Resultado = 1; SET @Mensaje = N'creado';
        END
        ELSE
        BEGIN
            UPDATE store.PressRelease
               SET Slug          = @Slug,
                   Title         = @Title,
                   Excerpt       = @Excerpt,
                   Body          = @Body,
                   CoverImageUrl = @CoverImageUrl,
                   Tags          = ISNULL(@Tags, Tags),
                   Status        = @Status,
                   PublishedAt   = CASE
                                     WHEN @Status = N'published' AND PublishedAt IS NULL THEN GETUTCDATE()
                                     WHEN @Status <> N'published' THEN NULL
                                     ELSE PublishedAt
                                   END,
                   UpdatedAt     = GETUTCDATE()
             WHERE CompanyId = @CompanyId AND PressReleaseId = @id;
            SET @OutPressReleaseId = @id;
            SET @Resultado = 1; SET @Mensaje = N'actualizado';
        END
    END TRY
    BEGIN CATCH
        SET @Resultado = 0;
        SET @Mensaje   = LEFT(ERROR_MESSAGE(), 500);
        SET @OutPressReleaseId = NULL;
    END CATCH
END
GO
