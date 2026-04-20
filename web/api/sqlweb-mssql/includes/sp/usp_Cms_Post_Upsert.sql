-- usp_Cms_Post_Upsert
-- Insert/Update de post. PostId NULL o 0 = crear.
-- Compatible SQL Server 2012+.

IF OBJECT_ID('dbo.usp_Cms_Post_Upsert', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_Cms_Post_Upsert;
GO

CREATE PROCEDURE dbo.usp_Cms_Post_Upsert
    @PostId         INT            = NULL,
    @CompanyId      INT            = 1,
    @Slug           VARCHAR(200)   = NULL,
    @Vertical       VARCHAR(50)    = 'corporate',
    @Category       VARCHAR(50)    = 'producto',
    @Locale         VARCHAR(10)    = 'es',
    @Title          NVARCHAR(300)  = NULL,
    @Excerpt        NVARCHAR(500)  = '',
    @Body           NVARCHAR(MAX)  = N'',
    @CoverUrl       VARCHAR(500)   = '',
    @AuthorName     NVARCHAR(200)  = '',
    @AuthorSlug     VARCHAR(100)   = '',
    @AuthorAvatar   VARCHAR(500)   = '',
    @Tags           VARCHAR(500)   = '',
    @ReadingMin     INT            = 5,
    @SeoTitle       NVARCHAR(300)  = '',
    @SeoDescription NVARCHAR(500)  = '',
    @SeoImageUrl    VARCHAR(500)   = '',
    @Resultado      INT            OUTPUT,
    @Mensaje        NVARCHAR(500)  OUTPUT,
    @OutPostId      INT            OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF @Slug IS NULL OR LTRIM(RTRIM(@Slug)) = ''
        BEGIN
            SET @Resultado = 0;
            SET @Mensaje = N'slug_required';
            SET @OutPostId = NULL;
            RETURN;
        END

        IF @Title IS NULL OR LTRIM(RTRIM(@Title)) = ''
        BEGIN
            SET @Resultado = 0;
            SET @Mensaje = N'title_required';
            SET @OutPostId = NULL;
            RETURN;
        END

        IF @PostId IS NULL OR @PostId = 0
        BEGIN
            INSERT INTO cms.Post (
                CompanyId, Slug, Vertical, Category, Locale,
                Title, Excerpt, Body, CoverUrl,
                AuthorName, AuthorSlug, AuthorAvatar,
                Tags, ReadingMin,
                SeoTitle, SeoDescription, SeoImageUrl
            ) VALUES (
                @CompanyId, @Slug, @Vertical, @Category, @Locale,
                @Title, @Excerpt, @Body, @CoverUrl,
                @AuthorName, @AuthorSlug, @AuthorAvatar,
                @Tags, @ReadingMin,
                @SeoTitle, @SeoDescription, @SeoImageUrl
            );

            SET @OutPostId = CAST(SCOPE_IDENTITY() AS INT);
            SET @Resultado = 1;
            SET @Mensaje = N'post_created';
        END
        ELSE
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM cms.Post WHERE PostId = @PostId)
            BEGIN
                SET @Resultado = 0;
                SET @Mensaje = N'post_not_found';
                SET @OutPostId = NULL;
                RETURN;
            END

            UPDATE cms.Post SET
                Slug           = @Slug,
                Vertical       = @Vertical,
                Category       = @Category,
                Locale         = @Locale,
                Title          = @Title,
                Excerpt        = @Excerpt,
                Body           = @Body,
                CoverUrl       = @CoverUrl,
                AuthorName     = @AuthorName,
                AuthorSlug     = @AuthorSlug,
                AuthorAvatar   = @AuthorAvatar,
                Tags           = @Tags,
                ReadingMin     = @ReadingMin,
                SeoTitle       = @SeoTitle,
                SeoDescription = @SeoDescription,
                SeoImageUrl    = @SeoImageUrl,
                UpdatedAt      = SYSUTCDATETIME()
            WHERE PostId = @PostId;

            SET @OutPostId = @PostId;
            SET @Resultado = 1;
            SET @Mensaje = N'post_updated';
        END
    END TRY
    BEGIN CATCH
        SET @Resultado = 0;
        SET @Mensaje = LEFT(ERROR_MESSAGE(), 500);
        SET @OutPostId = NULL;
    END CATCH
END
GO
