-- ============================================================
-- usp_Cfg_Tenant_SetSubdomain
-- Actualiza el subdomain de un tenant
-- ============================================================
IF OBJECT_ID('dbo.usp_Cfg_Tenant_SetSubdomain', 'P') IS NOT NULL
  DROP PROCEDURE dbo.usp_Cfg_Tenant_SetSubdomain;
GO

CREATE PROCEDURE dbo.usp_Cfg_Tenant_SetSubdomain
  @CompanyId  INT,
  @Subdomain  NVARCHAR(63),
  @Resultado  INT           = 0 OUTPUT,
  @Mensaje    NVARCHAR(500) = '' OUTPUT
AS
BEGIN
  SET NOCOUNT ON;

  UPDATE cfg.Company
  SET TenantSubdomain = LOWER(@Subdomain)
  WHERE CompanyId = @CompanyId;

  SET @Resultado = 1;
  SET @Mensaje = N'SUBDOMAIN_SET';
END;
GO

-- ============================================================
-- usp_Cfg_Tenant_ResolveByEmail
-- Resuelve un tenant por el email del owner (billing success)
-- ============================================================
IF OBJECT_ID('dbo.usp_Cfg_Tenant_ResolveByEmail', 'P') IS NOT NULL
  DROP PROCEDURE dbo.usp_Cfg_Tenant_ResolveByEmail;
GO

CREATE PROCEDURE dbo.usp_Cfg_Tenant_ResolveByEmail
  @Email NVARCHAR(150)
AS
BEGIN
  SET NOCOUNT ON;

  SELECT TOP 1
    c.CompanyId,
    c.CompanyCode,
    c.LegalName,
    c.OwnerEmail,
    c.[Plan],
    c.TenantStatus,
    c.TenantSubdomain,
    c.IsActive
  FROM cfg.Company c
  WHERE LOWER(c.OwnerEmail) = LOWER(@Email)
    AND c.IsDeleted = 0
    AND c.TenantStatus = N'ACTIVE'
  ORDER BY c.ProvisionedAt DESC;
END;
GO

-- ============================================================
-- usp_Cfg_Tenant_ResolveSubdomain
-- Resuelve un tenant por su subdomain (para routing multi-tenant)
-- ============================================================
IF OBJECT_ID('dbo.usp_Cfg_Tenant_ResolveSubdomain', 'P') IS NOT NULL
  DROP PROCEDURE dbo.usp_Cfg_Tenant_ResolveSubdomain;
GO

CREATE PROCEDURE dbo.usp_Cfg_Tenant_ResolveSubdomain
  @Subdomain NVARCHAR(63)
AS
BEGIN
  SET NOCOUNT ON;

  SELECT TOP 1
    c.CompanyId,
    c.CompanyCode,
    c.LegalName,
    c.[Plan],
    c.TenantStatus,
    c.TenantSubdomain,
    c.IsActive
  FROM cfg.Company c
  WHERE LOWER(c.TenantSubdomain) = LOWER(@Subdomain)
    AND c.IsDeleted = 0
    AND c.IsActive = 1
    AND c.TenantStatus = N'ACTIVE';
END;
GO
