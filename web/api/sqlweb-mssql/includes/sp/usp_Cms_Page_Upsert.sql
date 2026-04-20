-- usp_Cms_Page_Upsert
-- Insert/Update de página institucional. PageId NULL o 0 = crear.
-- Compatible SQL Server 2012+.

IF OBJECT_ID('dbo.usp_Cms_Page_Upsert', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_Cms_Page_Upsert;
GO

CREATE PROCEDURE dbo.usp_Cms_Page_Upsert
    @PageId         INT            = NULL,
    @CompanyId      INT            = 1,
    @Slug           VARCHAR(100)   = NULL,
    @Vertical       VARCHAR(50)    = 'corporate',
    @Locale         VARCHAR(10)    = 'es',
    @Title          NVARCHAR(300)  = NULL,
    @Body           NVARCHAR(MAX)  = N'',
    @Meta           NVARCHAR(MAX)  = N'{}',
    @SeoTitle       NVARCHAR(300)  = '',
    @SeoDescription NVARCHAR(500)  = '',
    @Resultado      INT            OUTPUT,
    @Mensaje        NVARCHAR(500)  OUTPUT,
    @OutPageId      INT            OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF @Slug IS NULL OR LTRIM(RTRIM(@Slug)) = ''
        BEGIN
            SET @Resultado = 0;
            SET @Mensaje = N'slug_required';
            SET @OutPageId = NULL;
            RETURN;
        END

        IF @Title IS NULL OR LTRIM(RTRIM(@Title)) = ''
        BEGIN
            SET @Resultado = 0;
            SET @Mensaje = N'title_required';
            SET @OutPageId = NULL;
            RETURN;
        END

        IF @PageId IS NULL OR @PageId = 0
        BEGIN
            INSERT INTO cms.Page (
                CompanyId, Slug, Vertical, Locale,
                Title, Body, Meta,
                SeoTitle, SeoDescription
            ) VALUES (
                @CompanyId, @Slug, @Vertical, @Locale,
                @Title, @Body, @Meta,
                @SeoTitle, @SeoDescription
            );

            SET @OutPageId = CAST(SCOPE_IDENTITY() AS INT);
            SET @Resultado = 1;
            SET @Mensaje = N'page_created';
        END
        ELSE
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM cms.Page WHERE PageId = @PageId)
            BEGIN
                SET @Resultado = 0;
                SET @Mensaje = N'page_not_found';
                SET @OutPageId = NULL;
                RETURN;
            END

            UPDATE cms.Page SET
                Slug           = @Slug,
                Vertical       = @Vertical,
                Locale         = @Locale,
                Title          = @Title,
                Body           = @Body,
                Meta           = @Meta,
                SeoTitle       = @SeoTitle,
                SeoDescription = @SeoDescription,
                UpdatedAt      = SYSUTCDATETIME()
            WHERE PageId = @PageId;

            SET @OutPageId = @PageId;
            SET @Resultado = 1;
            SET @Mensaje = N'page_updated';
        END
    END TRY
    BEGIN CATCH
        SET @Resultado = 0;
        SET @Mensaje = LEFT(ERROR_MESSAGE(), 500);
        SET @OutPageId = NULL;
    END CATCH
END
GO
