-- ============================================================
-- usp_sys_backoffice.sql ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â SPs de backoffice para gestiÃƒÆ’Ã‚Â³n de tenants
-- Motor: PostgreSQL (plpgsql)
-- Paridad: web/api/sqlweb/includes/sp/usp_sys_backoffice.sql
-- ============================================================

-- ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ usp_Sys_Backoffice_TenantList ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬

DROP FUNCTION IF EXISTS usp_sys_backoffice_tenantlist(INT, INT, VARCHAR, VARCHAR, VARCHAR) CASCADE;

CREATE OR REPLACE FUNCTION usp_sys_backoffice_tenantlist(
  p_page      INT     DEFAULT 1,
  p_page_size INT     DEFAULT 20,
  p_status    VARCHAR DEFAULT NULL,
  p_plan      VARCHAR DEFAULT NULL,
  p_search    VARCHAR DEFAULT NULL
)
RETURNS TABLE(
  "CompanyId"     INT,
  "CompanyCode"   VARCHAR,
  "LegalName"     VARCHAR,
  "Plan"          VARCHAR,
  "LicenseType"   VARCHAR,
  "LicenseStatus" VARCHAR,
  "ExpiresAt"     TIMESTAMP,
  "CreatedAt"     TIMESTAMP,
  "UserCount"     BIGINT,
  "LastLogin"     TIMESTAMP,
  "TotalCount"    BIGINT
)
LANGUAGE plpgsql AS $$
DECLARE
  v_offset INT := (COALESCE(p_page, 1) - 1) * COALESCE(p_page_size, 20);
  v_limit  INT := COALESCE(p_page_size, 20);
BEGIN
  RETURN QUERY
  WITH filtered AS (
    SELECT
      c."CompanyId",
      c."CompanyCode"::VARCHAR,
      c."LegalName"::VARCHAR,
      c."Plan"::VARCHAR,
      l."LicenseType"::VARCHAR,
      l."Status"::VARCHAR     AS license_status,
      l."ExpiresAt",
      c."CreatedAt",
      COUNT(DISTINCT u."UserId") AS user_count,
      MAX(al."CreatedAt")         AS last_login,
      COUNT(*) OVER ()            AS total_count
    FROM cfg."Company" c
    LEFT JOIN sys."License" l
           ON l."CompanyId" = c."CompanyId" AND l."Status" = 'ACTIVE'
    LEFT JOIN sec."User" u
           ON u."CompanyId" = c."CompanyId" AND u."IsDeleted" = FALSE
    LEFT JOIN sys."AuditLog" al
           ON al."CompanyId" = c."CompanyId" AND al."Action" LIKE 'auth.login%'
    WHERE c."IsDeleted" = FALSE
      AND (p_status IS NULL OR l."Status" = p_status)
      AND (p_plan   IS NULL OR UPPER(c."Plan") = UPPER(p_plan))
      AND (p_search IS NULL OR
           c."LegalName"   ILIKE '%' || p_search || '%' OR
           c."CompanyCode" ILIKE '%' || p_search || '%')
    GROUP BY c."CompanyId", c."CompanyCode", c."LegalName", c."Plan",
             l."LicenseType", l."Status", l."ExpiresAt", c."CreatedAt"
  )
  SELECT
    f."CompanyId",
    f."CompanyCode",
    f."LegalName",
    f."Plan",
    f."LicenseType",
    f.license_status,
    f."ExpiresAt",
    f."CreatedAt",
    f.user_count,
    f.last_login,
    f.total_count
  FROM filtered f
  ORDER BY f."CreatedAt" DESC
  LIMIT v_limit OFFSET v_offset;
END; $$;

-- ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ usp_Sys_Backoffice_TenantDetail ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬

DROP FUNCTION IF EXISTS usp_sys_backoffice_tenantdetail(INT) CASCADE;

CREATE OR REPLACE FUNCTION usp_sys_backoffice_tenantdetail(p_company_id INT)
RETURNS TABLE(
  "CompanyId"        INT,
  "CompanyCode"      VARCHAR,
  "LegalName"        VARCHAR,
  "TradeName"        VARCHAR,
  "OwnerEmail"       VARCHAR,
  "FiscalCountryCode" CHAR(2),
  "BaseCurrency"     CHAR(3),
  "Plan"             VARCHAR,
  "LicenseType"      VARCHAR,
  "LicenseStatus"    VARCHAR,
  "LicenseKey"       VARCHAR,
  "ExpiresAt"        TIMESTAMP,
  "PaddleSubId"      VARCHAR,
  "ContractRef"      VARCHAR,
  "MaxUsers"         INT,
  "CreatedAt"        TIMESTAMP,
  "UpdatedAt"        TIMESTAMP,
  "UserCount"        BIGINT,
  "LastLogin"        TIMESTAMP,
  "TenantSubdomain"  VARCHAR,
  "TenantStatus"     VARCHAR
)
LANGUAGE plpgsql AS $$
BEGIN
  RETURN QUERY
  SELECT
    c."CompanyId",
    c."CompanyCode"::VARCHAR,
    c."LegalName"::VARCHAR,
    c."TradeName"::VARCHAR,
    c."OwnerEmail"::VARCHAR,
    c."FiscalCountryCode",
    c."BaseCurrency",
    c."Plan"::VARCHAR,
    l."LicenseType"::VARCHAR,
    l."Status"::VARCHAR,
    l."LicenseKey"::VARCHAR,
    l."ExpiresAt",
    l."PaddleSubId"::VARCHAR,
    l."ContractRef"::VARCHAR,
    l."MaxUsers",
    c."CreatedAt",
    c."UpdatedAt",
    (SELECT COUNT(*) FROM sec."User" u
     WHERE u."CompanyId" = c."CompanyId" AND u."IsDeleted" = FALSE),
    (SELECT MAX(al."CreatedAt") FROM sys."AuditLog" al
     WHERE al."CompanyId" = c."CompanyId" AND al."Action" LIKE 'auth.login%'),
    c."TenantSubdomain"::VARCHAR,
    c."TenantStatus"::VARCHAR
  FROM cfg."Company" c
  LEFT JOIN sys."License" l
         ON l."CompanyId" = c."CompanyId" AND l."Status" = 'ACTIVE'
  WHERE c."CompanyId" = p_company_id
    AND c."IsDeleted" = FALSE;
END; $$;

-- ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ usp_Sys_Backoffice_RevenueMetrics ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬

DROP FUNCTION IF EXISTS usp_sys_backoffice_revenuemetrics() CASCADE;

CREATE OR REPLACE FUNCTION usp_sys_backoffice_revenuemetrics()
RETURNS TABLE(
  "Plan"          VARCHAR,
  "LicenseType"   VARCHAR,
  "TenantCount"   BIGINT,
  "EstimatedMRR"  NUMERIC
)
LANGUAGE plpgsql AS $$
BEGIN
  RETURN QUERY
  SELECT
    COALESCE(UPPER(c."Plan"), 'FREE')::VARCHAR          AS plan,
    COALESCE(l."LicenseType", 'NONE')::VARCHAR          AS license_type,
    COUNT(DISTINCT c."CompanyId")                       AS tenant_count,
    -- MRR estimado por plan (precios de referencia USD)
    COUNT(DISTINCT c."CompanyId") * CASE UPPER(c."Plan")
      WHEN 'STARTER'    THEN 29.00
      WHEN 'PRO'        THEN 79.00
      WHEN 'ENTERPRISE' THEN 0.00   -- contrato negociado, no MRR fijo
      ELSE 0.00
    END                                                  AS estimated_mrr
  FROM cfg."Company" c
  LEFT JOIN sys."License" l
         ON l."CompanyId" = c."CompanyId" AND l."Status" = 'ACTIVE'
  WHERE c."IsDeleted" = FALSE
    AND c."IsActive" = TRUE
  GROUP BY UPPER(c."Plan"), l."LicenseType"
  ORDER BY estimated_mrr DESC;
END; $$;
