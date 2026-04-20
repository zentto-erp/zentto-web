-- usp_Store_CmsPage_Delete
-- Elimina página CMS por id.

IF OBJECT_ID('dbo.usp_Store_CmsPage_Delete', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_Store_CmsPage_Delete;
GO

CREATE PROCEDURE dbo.usp_Store_CmsPage_Delete
    @CompanyId INT           = 1,
    @CmsPageId BIGINT        = NULL,
    @Resultado INT           OUTPUT,
    @Mensaje   NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM store.CmsPage
     WHERE CompanyId = @CompanyId AND CmsPageId = @CmsPageId;

    IF @@ROWCOUNT = 0
    BEGIN SET @Resultado = 0; SET @Mensaje = N'no encontrado'; END
    ELSE
    BEGIN SET @Resultado = 1; SET @Mensaje = N'eliminado';     END
END
GO
