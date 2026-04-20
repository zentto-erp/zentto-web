-- usp_Cms_Post_Delete
-- Elimina un post por PostId.
-- Compatible SQL Server 2012+.

IF OBJECT_ID('dbo.usp_Cms_Post_Delete', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_Cms_Post_Delete;
GO

CREATE PROCEDURE dbo.usp_Cms_Post_Delete
    @PostId    INT,
    @Resultado INT            OUTPUT,
    @Mensaje   NVARCHAR(500)  OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM cms.Post WHERE PostId = @PostId)
    BEGIN
        SET @Resultado = 0;
        SET @Mensaje = N'post_not_found';
        RETURN;
    END

    DELETE FROM cms.Post WHERE PostId = @PostId;

    SET @Resultado = 1;
    SET @Mensaje = N'post_deleted';
END
GO
