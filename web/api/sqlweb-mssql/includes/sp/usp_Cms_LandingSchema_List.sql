-- usp_Cms_LandingSchema_List
-- Admin: lista landings del tenant con filtros y paginación.
-- Compatible SQL Server 2012+.

IF OBJECT_ID('dbo.usp_Cms_LandingSchema_List', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_Cms_LandingSchema_List;
GO

CREATE PROCEDURE dbo.usp_Cms_LandingSchema_List
    @CompanyId  INT         = 1,
    @Vertical   VARCHAR(50) = NULL,
    @Status     VARCHAR(20) = NULL,
    @Limit      INT         = 50,
    @Offset     INT         = 0
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Total INT;
    SELECT @Total = COUNT(*)
    FROM cms.LandingSchema l
    WHERE l.CompanyId = @CompanyId
      AND (@Vertical IS NULL OR l.Vertical = @Vertical)
      AND (@Status   IS NULL OR l.Status   = @Status);

    SELECT
        l.LandingSchemaId, l.CompanyId, l.Vertical, l.Slug, l.Locale,
        l.Version, l.Status, l.PublishedAt, l.UpdatedAt,
        CAST(@Total AS BIGINT) AS TotalCount
    FROM cms.LandingSchema l
    WHERE l.CompanyId = @CompanyId
      AND (@Vertical IS NULL OR l.Vertical = @Vertical)
      AND (@Status   IS NULL OR l.Status   = @Status)
    ORDER BY l.UpdatedAt DESC, l.LandingSchemaId DESC
    OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;
END
GO
