-- usp_Store_CmsPage_Upsert
-- Insert/Update CMS page. Si @CmsPageId es NULL, busca por slug, sino inserta.

IF OBJECT_ID('dbo.usp_Store_CmsPage_Upsert', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_Store_CmsPage_Upsert;
GO

CREATE PROCEDURE dbo.usp_Store_CmsPage_Upsert
    @CompanyId   INT           = 1,
    @CmsPageId   BIGINT        = NULL,
    @Slug        NVARCHAR(120) = NULL,
    @Title       NVARCHAR(200) = NULL,
    @Subtitle    NVARCHAR(300) = NULL,
    @TemplateKey NVARCHAR(80)  = NULL,
    @Config      NVARCHAR(MAX) = NULL,
    @Seo         NVARCHAR(MAX) = NULL,
    @Status      NVARCHAR(20)  = N'draft',
    @Resultado   INT           OUTPUT,
    @Mensaje     NVARCHAR(500) OUTPUT,
    @OutCmsPageId BIGINT       OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF @Slug IS NULL OR LTRIM(RTRIM(@Slug)) = N''
        BEGIN
            SET @Resultado = 0; SET @Mensaje = N'slug requerido'; SET @OutCmsPageId = NULL; RETURN;
        END
        IF @Title IS NULL OR LTRIM(RTRIM(@Title)) = N''
        BEGIN
            SET @Resultado = 0; SET @Mensaje = N'title requerido'; SET @OutCmsPageId = NULL; RETURN;
        END
        IF @Status NOT IN (N'draft', N'published', N'archived')
        BEGIN
            SET @Resultado = 0; SET @Mensaje = N'status invalido'; SET @OutCmsPageId = NULL; RETURN;
        END

        DECLARE @id BIGINT = @CmsPageId;
        IF @id IS NULL
        BEGIN
            SELECT TOP 1 @id = CmsPageId
              FROM store.CmsPage
             WHERE CompanyId = @CompanyId AND Slug = @Slug;
        END

        IF @id IS NULL
        BEGIN
            INSERT INTO store.CmsPage (CompanyId, Slug, Title, Subtitle, TemplateKey, Config, Seo, Status, PublishedAt, UpdatedAt, CreatedAt)
            VALUES (
                @CompanyId, @Slug, @Title, @Subtitle, @TemplateKey,
                ISNULL(@Config, N'{"sections":[]}'),
                ISNULL(@Seo,    N'{}'),
                @Status,
                CASE WHEN @Status = N'published' THEN GETUTCDATE() ELSE NULL END,
                GETUTCDATE(), GETUTCDATE()
            );
            SET @OutCmsPageId = CAST(SCOPE_IDENTITY() AS BIGINT);
            SET @Resultado = 1; SET @Mensaje = N'creado';
        END
        ELSE
        BEGIN
            UPDATE store.CmsPage
               SET Slug        = @Slug,
                   Title       = @Title,
                   Subtitle    = @Subtitle,
                   TemplateKey = @TemplateKey,
                   Config      = ISNULL(@Config, Config),
                   Seo         = ISNULL(@Seo,    Seo),
                   Status      = @Status,
                   PublishedAt = CASE
                                   WHEN @Status = N'published' AND PublishedAt IS NULL THEN GETUTCDATE()
                                   WHEN @Status <> N'published' THEN NULL
                                   ELSE PublishedAt
                                 END,
                   UpdatedAt   = GETUTCDATE()
             WHERE CompanyId = @CompanyId AND CmsPageId = @id;
            SET @OutCmsPageId = @id;
            SET @Resultado = 1; SET @Mensaje = N'actualizado';
        END
    END TRY
    BEGIN CATCH
        SET @Resultado = 0;
        SET @Mensaje = LEFT(ERROR_MESSAGE(), 500);
        SET @OutCmsPageId = NULL;
    END CATCH
END
GO
