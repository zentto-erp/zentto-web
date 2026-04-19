-- usp_CRM_SavedView_List
-- Lista vistas guardadas del usuario + vistas compartidas del mismo tenant.
-- Compatible SQL Server 2012+.

IF OBJECT_ID('dbo.usp_CRM_SavedView_List', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_CRM_SavedView_List;
GO

CREATE PROCEDURE dbo.usp_CRM_SavedView_List
    @CompanyId INT,
    @UserId    INT,
    @Entity    VARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        sv.ViewId,
        sv.CompanyId,
        sv.UserId,
        sv.Entity,
        sv.Name,
        sv.FilterJson,
        sv.ColumnsJson,
        sv.SortJson,
        sv.IsShared,
        sv.IsDefault,
        CASE WHEN sv.UserId = @UserId THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END AS IsOwner,
        sv.CreatedAt,
        sv.UpdatedAt
    FROM crm.SavedView sv
    WHERE sv.CompanyId = @CompanyId
      AND (@Entity IS NULL OR sv.Entity = @Entity)
      AND (sv.UserId = @UserId OR sv.IsShared = 1)
    ORDER BY sv.Entity, sv.IsDefault DESC, sv.Name;
END
GO
