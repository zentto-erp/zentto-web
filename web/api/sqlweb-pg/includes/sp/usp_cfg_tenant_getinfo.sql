-- ============================================================
-- usp_Cfg_Tenant_GetInfo — obtiene info del tenant por CompanyId
-- ============================================================
DROP FUNCTION IF EXISTS usp_Cfg_Tenant_GetInfo(INT) CASCADE;

DROP FUNCTION IF EXISTS usp_Cfg_Tenant_GetInfo(p_company_id INT)
RETURNS TABLE(
  "CompanyId"            INT,
  "CompanyCode"          VARCHAR,
  "LegalName"            VARCHAR,
  "OwnerEmail"           VARCHAR,
  "Plan"                 VARCHAR,
  "TenantStatus"         VARCHAR,
  "BaseCurrency"         CHAR(3),
  "FiscalCountryCode"    CHAR(2),
  "ProvisionedAt"        TIMESTAMP,
  "PaddleSubscriptionId" VARCHAR,
  "TenantSubdomain"      VARCHAR,
  "IsActive"             BOOLEAN,
  "BranchCount"          BIGINT,
  "UserCount"            BIGINT
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
    c."BaseCurrency",
    c."FiscalCountryCode",
    c."ProvisionedAt",
    c."PaddleSubscriptionId",
    c."TenantSubdomain",
    c."IsActive",
    (SELECT COUNT(*) FROM cfg."Branch" b WHERE b."CompanyId" = c."CompanyId" AND b."IsDeleted" = FALSE),
    (SELECT COUNT(*) FROM sec."User" u WHERE u."CompanyId" = c."CompanyId" AND u."IsDeleted" = FALSE)
  FROM cfg."Company" c
  WHERE c."CompanyId" = p_company_id
    AND c."IsDeleted" = FALSE;
END;
$$;
