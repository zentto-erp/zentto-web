-- ============================================================
-- usp_Cfg_Tenant_SetSubdomain
-- Actualiza el subdomain de un tenant
-- ============================================================
DROP FUNCTION IF EXISTS usp_Cfg_Tenant_SetSubdomain(INT, VARCHAR) CASCADE;

CREATE OR REPLACE FUNCTION usp_Cfg_Tenant_SetSubdomain(
  p_company_id INT,
  p_subdomain  VARCHAR(63)
)
RETURNS TABLE("ok" BOOLEAN, "mensaje" VARCHAR)
LANGUAGE plpgsql AS $$
BEGIN
  UPDATE cfg."Company"
  SET "TenantSubdomain" = LOWER(p_subdomain)
  WHERE "CompanyId" = p_company_id;

  RETURN QUERY SELECT TRUE, 'SUBDOMAIN_SET'::VARCHAR;
END;
$$;

-- ============================================================
-- usp_Cfg_Tenant_ResolveByEmail
-- Resuelve un tenant por el email del owner (billing success)
-- ============================================================
DROP FUNCTION IF EXISTS usp_Cfg_Tenant_ResolveByEmail(VARCHAR) CASCADE;

CREATE OR REPLACE FUNCTION usp_Cfg_Tenant_ResolveByEmail(
  p_email VARCHAR(150)
)
RETURNS TABLE(
  "CompanyId"         INT,
  "CompanyCode"       VARCHAR,
  "LegalName"         VARCHAR,
  "OwnerEmail"        VARCHAR,
  "Plan"              VARCHAR,
  "TenantStatus"      VARCHAR,
  "TenantSubdomain"   VARCHAR,
  "IsActive"          BOOLEAN
)
LANGUAGE plpgsql AS $$
BEGIN
  RETURN QUERY
  SELECT
    c."CompanyId",
    c."CompanyCode",
    c."LegalName",
    c."OwnerEmail",
    c."Plan",
    c."TenantStatus",
    c."TenantSubdomain",
    c."IsActive"
  FROM cfg."Company" c
  WHERE LOWER(c."OwnerEmail") = LOWER(p_email)
    AND c."IsDeleted" = FALSE
    AND c."TenantStatus" = 'ACTIVE'
  ORDER BY c."ProvisionedAt" DESC
  LIMIT 1;
END;
$$;

-- ============================================================
-- usp_Cfg_Tenant_ResolveSubdomain
-- Resuelve un tenant por su subdomain (para routing multi-tenant)
-- ============================================================
DROP FUNCTION IF EXISTS usp_Cfg_Tenant_ResolveSubdomain(VARCHAR) CASCADE;

CREATE OR REPLACE FUNCTION usp_Cfg_Tenant_ResolveSubdomain(
  p_subdomain VARCHAR(63)
)
RETURNS TABLE(
  "CompanyId"         INT,
  "CompanyCode"       VARCHAR,
  "LegalName"         VARCHAR,
  "Plan"              VARCHAR,
  "TenantStatus"      VARCHAR,
  "TenantSubdomain"   VARCHAR,
  "IsActive"          BOOLEAN
)
LANGUAGE plpgsql AS $$
BEGIN
  RETURN QUERY
  SELECT
    c."CompanyId",
    c."CompanyCode",
    c."LegalName",
    c."Plan",
    c."TenantStatus",
    c."TenantSubdomain",
    c."IsActive"
  FROM cfg."Company" c
  WHERE LOWER(c."TenantSubdomain") = LOWER(p_subdomain)
    AND c."IsDeleted" = FALSE
    AND c."IsActive" = TRUE
    AND c."TenantStatus" = 'ACTIVE'
  LIMIT 1;
END;
$$;
