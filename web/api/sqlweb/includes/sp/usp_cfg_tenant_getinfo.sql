-- ============================================================
-- usp_Cfg_Tenant_GetInfo — SQL Server
-- ============================================================
USE DatqBoxWeb;
GO
CREATE OR ALTER PROCEDURE dbo.usp_Cfg_Tenant_GetInfo
  @CompanyId INT
AS
BEGIN
  SET NOCOUNT ON;
  SELECT
    c.CompanyId, c.CompanyCode, c.LegalName,
    c.OwnerEmail, c.Plan, c.TenantStatus,
    c.BaseCurrency, c.FiscalCountryCode,
    c.ProvisionedAt, c.PaddleSubscriptionId,
    c.IsActive,
    (SELECT COUNT(*) FROM cfg.Branch b WHERE b.CompanyId = c.CompanyId AND b.IsDeleted = 0) AS BranchCount,
    (SELECT COUNT(*) FROM sec.[User] u WHERE u.CompanyId = c.CompanyId AND u.IsDeleted = 0) AS UserCount
  FROM cfg.Company c
  WHERE c.CompanyId = @CompanyId
    AND c.IsDeleted = 0;
END;
GO
