-- usp_Cms_LandingSchema_ListVersions
-- Historial paginado de versiones de un landing (admin). Scope al tenant.
-- Compatible SQL Server 2012+.

IF OBJECT_ID('dbo.usp_Cms_LandingSchema_ListVersions', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_Cms_LandingSchema_ListVersions;
GO

CREATE PROCEDURE dbo.usp_Cms_LandingSchema_ListVersions
    @LandingSchemaId INT,
    @CompanyId       INT,
    @Limit           INT = 20,
    @Offset          INT = 0
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Total INT = 0;

    -- Verificar ownership (tenant scope)
    IF NOT EXISTS (
        SELECT 1 FROM cms.LandingSchema
        WHERE LandingSchemaId = @LandingSchemaId
          AND CompanyId       = @CompanyId
    )
    BEGIN
        SELECT TOP 0
            CAST(NULL AS INT)       AS LandingSchemaHistoryId,
            CAST(NULL AS INT)       AS LandingSchemaId,
            CAST(NULL AS INT)       AS Version,
            CAST(NULL AS DATETIME2) AS PublishedAt,
            CAST(NULL AS INT)       AS PublishedBy,
            CAST(0 AS BIGINT)       AS TotalCount;
        RETURN;
    END

    SELECT @Total = COUNT(*)
    FROM cms.LandingSchemaHistory
    WHERE LandingSchemaId = @LandingSchemaId;

    SELECT
        h.LandingSchemaHistoryId,
        h.LandingSchemaId,
        h.Version,
        h.PublishedAt,
        h.PublishedBy,
        CAST(@Total AS BIGINT) AS TotalCount
    FROM cms.LandingSchemaHistory h
    WHERE h.LandingSchemaId = @LandingSchemaId
    ORDER BY h.Version DESC, h.LandingSchemaHistoryId DESC
    OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;
END
GO
