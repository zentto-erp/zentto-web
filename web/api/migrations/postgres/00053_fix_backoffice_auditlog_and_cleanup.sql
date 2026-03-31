-- +goose Up

-- 1. Crear schema audit si no existe
CREATE SCHEMA IF NOT EXISTS audit;

-- 2. Crear tabla audit.AuditLog si no existe (faltaba migración goose)
CREATE TABLE IF NOT EXISTS audit."AuditLog" (
    "AuditLogId" bigint NOT NULL,
    "CompanyId" integer NOT NULL DEFAULT 1,
    "BranchId" integer NOT NULL DEFAULT 1,
    "UserId" integer,
    "UserName" character varying(100),
    "ModuleName" character varying(50) NOT NULL,
    "EntityName" character varying(100) NOT NULL,
    "EntityId" character varying(50),
    "ActionType" character varying(10) NOT NULL,
    "Summary" character varying(500),
    "OldValues" text,
    "NewValues" text,
    "IpAddress" character varying(50),
    "CreatedAt" timestamp without time zone DEFAULT (now() AT TIME ZONE 'UTC') NOT NULL
);

CREATE SEQUENCE IF NOT EXISTS audit."AuditLog_AuditLogId_seq"
    START WITH 1 INCREMENT BY 1 NO MINVALUE NO MAXVALUE CACHE 1;

ALTER TABLE ONLY audit."AuditLog"
    ALTER COLUMN "AuditLogId" SET DEFAULT nextval('audit."AuditLog_AuditLogId_seq"'::regclass);

ALTER SEQUENCE audit."AuditLog_AuditLogId_seq" OWNED BY audit."AuditLog"."AuditLogId";

DO $$ BEGIN
    ALTER TABLE ONLY audit."AuditLog" ADD CONSTRAINT "AuditLog_pkey" PRIMARY KEY ("AuditLogId");
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

CREATE INDEX IF NOT EXISTS "IX_AuditLog_Company_Date"
    ON audit."AuditLog" USING btree ("CompanyId", "BranchId", "CreatedAt" DESC);
CREATE INDEX IF NOT EXISTS "IX_AuditLog_Module"
    ON audit."AuditLog" USING btree ("ModuleName", "CreatedAt" DESC);
CREATE INDEX IF NOT EXISTS "IX_AuditLog_User"
    ON audit."AuditLog" USING btree ("UserName", "CreatedAt" DESC);

-- 3. Agregar columna DeleteAfter a sys.CleanupQueue
ALTER TABLE sys."CleanupQueue"
    ADD COLUMN IF NOT EXISTS "DeleteAfter" timestamp without time zone;

-- 4. Fix: usp_sys_backoffice_tenantdetail — sys.AuditLog → audit.AuditLog, Action → ActionType
CREATE OR REPLACE FUNCTION public.usp_sys_backoffice_tenantdetail(p_company_id integer)
RETURNS TABLE(
    "CompanyId" integer, "CompanyCode" character varying, "LegalName" character varying,
    "TradeName" character varying, "OwnerEmail" character varying,
    "FiscalCountryCode" character, "BaseCurrency" character,
    "Plan" character varying, "LicenseType" character varying,
    "LicenseStatus" character varying, "LicenseKey" character varying,
    "ExpiresAt" timestamp without time zone, "PaddleSubId" character varying,
    "ContractRef" character varying, "MaxUsers" integer,
    "CreatedAt" timestamp without time zone, "UpdatedAt" timestamp without time zone,
    "UserCount" bigint, "LastLogin" timestamp without time zone,
    "TenantSubdomain" character varying, "TenantStatus" character varying
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
    (SELECT MAX(al."CreatedAt") FROM audit."AuditLog" al
     WHERE al."CompanyId" = c."CompanyId" AND al."ActionType" LIKE 'LOGIN%'),
    c."TenantSubdomain"::VARCHAR,
    c."TenantStatus"::VARCHAR
  FROM cfg."Company" c
  LEFT JOIN sys."License" l
         ON l."CompanyId" = c."CompanyId" AND l."Status" = 'ACTIVE'
  WHERE c."CompanyId" = p_company_id
    AND c."IsDeleted" = FALSE;
END; $$;

-- 5. Fix: usp_sys_backoffice_tenantlist — sys.AuditLog → audit.AuditLog, Action → ActionType
CREATE OR REPLACE FUNCTION public.usp_sys_backoffice_tenantlist(
    p_page integer DEFAULT 1,
    p_page_size integer DEFAULT 20,
    p_status character varying DEFAULT NULL::character varying,
    p_plan character varying DEFAULT NULL::character varying,
    p_search character varying DEFAULT NULL::character varying
)
RETURNS TABLE(
    "CompanyId" integer, "CompanyCode" character varying, "LegalName" character varying,
    "Plan" character varying, "LicenseType" character varying,
    "LicenseStatus" character varying, "ExpiresAt" timestamp without time zone,
    "CreatedAt" timestamp without time zone, "UserCount" bigint,
    "LastLogin" timestamp without time zone, "TotalCount" bigint
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
    LEFT JOIN audit."AuditLog" al
           ON al."CompanyId" = c."CompanyId" AND al."ActionType" LIKE 'LOGIN%'
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

-- +goose Down
DROP FUNCTION IF EXISTS public.usp_sys_backoffice_tenantlist(integer, integer, character varying, character varying, character varying);
DROP FUNCTION IF EXISTS public.usp_sys_backoffice_tenantdetail(integer);
ALTER TABLE sys."CleanupQueue" DROP COLUMN IF EXISTS "DeleteAfter";
