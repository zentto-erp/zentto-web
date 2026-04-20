-- usp_Cms_Page_Delete
-- Elimina una página por PageId.
-- Compatible SQL Server 2012+.

IF OBJECT_ID('dbo.usp_Cms_Page_Delete', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_Cms_Page_Delete;
GO

CREATE PROCEDURE dbo.usp_Cms_Page_Delete
    @PageId    INT,
    @Resultado INT            OUTPUT,
    @Mensaje   NVARCHAR(500)  OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM cms.Page WHERE PageId = @PageId)
    BEGIN
        SET @Resultado = 0;
        SET @Mensaje = N'page_not_found';
        RETURN;
    END

    DELETE FROM cms.Page WHERE PageId = @PageId;

    SET @Resultado = 1;
    SET @Mensaje = N'page_deleted';
END
GO
