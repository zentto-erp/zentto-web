-- usp_CRM_SavedView_Detail
-- Detalle de una vista por ViewId con tenant+visibility guard.
-- Compatible SQL Server 2012+.

IF OBJECT_ID('dbo.usp_CRM_SavedView_Detail', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_CRM_SavedView_Detail;
GO

CREATE PROCEDURE dbo.usp_CRM_SavedView_Detail
    @CompanyId INT,
    @UserId    INT,
    @ViewId    BIGINT
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
    WHERE sv.ViewId    = @ViewId
      AND sv.CompanyId = @CompanyId
      AND (sv.UserId = @UserId OR sv.IsShared = 1);
END
GO
