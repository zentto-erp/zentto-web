-- ============================================================
-- usp_sys_backoffice.sql — SPs de backoffice para gestión de tenants
-- Motor: SQL Server
-- Paridad: web/api/sqlweb-pg/includes/sp/usp_sys_backoffice.sql
-- ============================================================

GO

-- ─── usp_Sys_Backoffice_TenantList ───────────────────────────────────────────

CREATE OR ALTER PROCEDURE dbo.usp_Sys_Backoffice_TenantList
  @Page     INT           = 1,
  @PageSize INT           = 20,
  @Status   NVARCHAR(20)  = NULL,
  @Plan     NVARCHAR(30)  = NULL,
  @Search   NVARCHAR(200) = NULL
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @Offset INT = (@Page - 1) * @PageSize;

  WITH filtered AS (
    SELECT
      c.CompanyId,
      c.CompanyCode,
      c.LegalName,
      c.Plan,
      l.LicenseType,
      l.Status         AS LicenseStatus,
      l.ExpiresAt,
      c.CreatedAt,
      (SELECT COUNT(*) FROM sec.[User] u
       WHERE u.CompanyId = c.CompanyId AND u.IsDeleted = 0) AS UserCount,
      (SELECT MAX(al.CreatedAt) FROM sys.AuditLog al
       WHERE al.CompanyId = c.CompanyId AND al.Action LIKE 'auth.login%') AS LastLogin,
      COUNT(*) OVER () AS TotalCount
    FROM cfg.Company c
    LEFT JOIN sys.License l
           ON l.CompanyId = c.CompanyId AND l.Status = 'ACTIVE'
    WHERE c.IsDeleted = 0
      AND (@Status IS NULL OR l.Status = @Status)
      AND (@Plan   IS NULL OR UPPER(c.Plan) = UPPER(@Plan))
      AND (@Search IS NULL OR c.LegalName LIKE '%' + @Search + '%'
                           OR c.CompanyCode LIKE '%' + @Search + '%')
  )
  SELECT
    CompanyId, CompanyCode, LegalName, Plan,
    LicenseType, LicenseStatus, ExpiresAt, CreatedAt,
    UserCount, LastLogin, TotalCount
  FROM filtered
  ORDER BY CreatedAt DESC
  OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY;
END
GO

-- ─── usp_Sys_Backoffice_TenantDetail ─────────────────────────────────────────

CREATE OR ALTER PROCEDURE dbo.usp_Sys_Backoffice_TenantDetail
  @CompanyId INT
AS
BEGIN
  SET NOCOUNT ON;
  SELECT
    c.CompanyId, c.CompanyCode, c.LegalName, c.TradeName,
    c.OwnerEmail, c.FiscalCountryCode, c.BaseCurrency, c.Plan,
    l.LicenseType, l.Status AS LicenseStatus, l.LicenseKey,
    l.ExpiresAt, l.PaddleSubId, l.ContractRef, l.MaxUsers,
    c.CreatedAt, c.UpdatedAt,
    (SELECT COUNT(*) FROM sec.[User] u
     WHERE u.CompanyId = c.CompanyId AND u.IsDeleted = 0) AS UserCount,
    (SELECT MAX(al.CreatedAt) FROM sys.AuditLog al
     WHERE al.CompanyId = c.CompanyId AND al.Action LIKE 'auth.login%') AS LastLogin,
    c.TenantSubdomain, c.TenantStatus
  FROM cfg.Company c
  LEFT JOIN sys.License l
         ON l.CompanyId = c.CompanyId AND l.Status = 'ACTIVE'
  WHERE c.CompanyId = @CompanyId
    AND c.IsDeleted = 0;
END
GO

-- ─── usp_Sys_Backoffice_RevenueMetrics ───────────────────────────────────────

CREATE OR ALTER PROCEDURE dbo.usp_Sys_Backoffice_RevenueMetrics
AS
BEGIN
  SET NOCOUNT ON;
  SELECT
    ISNULL(UPPER(c.Plan), 'FREE')        AS Plan,
    ISNULL(l.LicenseType, 'NONE')        AS LicenseType,
    COUNT(DISTINCT c.CompanyId)          AS TenantCount,
    COUNT(DISTINCT c.CompanyId) * CASE UPPER(c.Plan)
      WHEN 'STARTER'    THEN 29.00
      WHEN 'PRO'        THEN 79.00
      WHEN 'ENTERPRISE' THEN 0.00
      ELSE 0.00
    END                                  AS EstimatedMRR
  FROM cfg.Company c
  LEFT JOIN sys.License l
         ON l.CompanyId = c.CompanyId AND l.Status = 'ACTIVE'
  WHERE c.IsDeleted = 0
    AND c.IsActive = 1
  GROUP BY UPPER(c.Plan), l.LicenseType
  ORDER BY EstimatedMRR DESC;
END
GO
