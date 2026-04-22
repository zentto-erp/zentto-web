-- usp_Cms_LandingSchema_GetById
-- Admin: detalle completo (Draft + Published + metadata). Scope al CompanyId.
-- Compatible SQL Server 2012+.

IF OBJECT_ID('dbo.usp_Cms_LandingSchema_GetById', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_Cms_LandingSchema_GetById;
GO

CREATE PROCEDURE dbo.usp_Cms_LandingSchema_GetById
    @LandingSchemaId INT,
    @CompanyId       INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 1
        l.LandingSchemaId, l.CompanyId, l.Vertical, l.Slug, l.Locale,
        l.DraftSchema, l.PublishedSchema, l.ThemeTokens, l.SeoMeta,
        l.Version, l.Status, l.PreviewToken,
        l.PublishedAt, l.PublishedBy,
        l.CreatedAt, l.CreatedBy,
        l.UpdatedAt, l.UpdatedBy
    FROM cms.LandingSchema l
    WHERE l.LandingSchemaId = @LandingSchemaId
      AND l.CompanyId       = @CompanyId;
END
GO
