-- usp_Cms_Page_Publish
-- Publica o despublica una página.
-- Compatible SQL Server 2012+.

IF OBJECT_ID('dbo.usp_Cms_Page_Publish', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_Cms_Page_Publish;
GO

CREATE PROCEDURE dbo.usp_Cms_Page_Publish
    @PageId    INT,
    @Publish   BIT            = 1,
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

    UPDATE cms.Page
       SET Status      = CASE WHEN @Publish = 1 THEN 'published' ELSE 'draft' END,
           PublishedAt = CASE
                             WHEN @Publish = 1 AND PublishedAt IS NULL THEN SYSUTCDATETIME()
                             ELSE PublishedAt
                         END,
           UpdatedAt   = SYSUTCDATETIME()
     WHERE PageId = @PageId;

    SET @Resultado = 1;
    SET @Mensaje = CASE WHEN @Publish = 1 THEN N'page_published' ELSE N'page_unpublished' END;
END
GO
