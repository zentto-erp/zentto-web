-- usp_Cms_Post_Publish
-- Publica o despublica un post (status + PublishedAt).
-- Compatible SQL Server 2012+.

IF OBJECT_ID('dbo.usp_Cms_Post_Publish', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_Cms_Post_Publish;
GO

CREATE PROCEDURE dbo.usp_Cms_Post_Publish
    @PostId    INT,
    @Publish   BIT            = 1,
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

    UPDATE cms.Post
       SET Status      = CASE WHEN @Publish = 1 THEN 'published' ELSE 'draft' END,
           PublishedAt = CASE
                             WHEN @Publish = 1 AND PublishedAt IS NULL THEN SYSUTCDATETIME()
                             ELSE PublishedAt
                         END,
           UpdatedAt   = SYSUTCDATETIME()
     WHERE PostId = @PostId;

    SET @Resultado = 1;
    SET @Mensaje = CASE WHEN @Publish = 1 THEN N'post_published' ELSE N'post_unpublished' END;
END
GO
