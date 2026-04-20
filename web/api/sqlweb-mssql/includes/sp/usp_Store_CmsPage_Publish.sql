-- usp_Store_CmsPage_Publish
-- Cambia status a 'published' y setea PublishedAt si no existía.

IF OBJECT_ID('dbo.usp_Store_CmsPage_Publish', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_Store_CmsPage_Publish;
GO

CREATE PROCEDURE dbo.usp_Store_CmsPage_Publish
    @CompanyId INT           = 1,
    @CmsPageId BIGINT        = NULL,
    @Resultado INT           OUTPUT,
    @Mensaje   NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE store.CmsPage
       SET Status      = N'published',
           PublishedAt = ISNULL(PublishedAt, GETUTCDATE()),
           UpdatedAt   = GETUTCDATE()
     WHERE CompanyId = @CompanyId AND CmsPageId = @CmsPageId;

    IF @@ROWCOUNT = 0
    BEGIN SET @Resultado = 0; SET @Mensaje = N'no encontrado'; END
    ELSE
    BEGIN SET @Resultado = 1; SET @Mensaje = N'publicado';     END
END
GO
