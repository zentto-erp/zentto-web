-- +goose Up

-- Fix: CompanyId integer vs bigint mismatch en usp_sys_backup_latest_per_tenant
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_sys_backup_latest_per_tenant()
RETURNS TABLE("CompanyId" bigint, "CompanyCode" character varying, "LegalName" character varying, "LastBackupAt" timestamp without time zone, "LastBackupStatus" character varying, "LastBackupSizeMB" numeric)
LANGUAGE plpgsql AS $fn$
BEGIN
  RETURN QUERY
  WITH ranked AS (
    SELECT
      b."CompanyId",
      b."Status",
      b."StartedAt",
      b."FileSizeMB",
      ROW_NUMBER() OVER (PARTITION BY b."CompanyId" ORDER BY b."StartedAt" DESC) AS rn
    FROM sys."TenantBackup" b
  )
  SELECT
    c."CompanyId"::BIGINT,
    c."CompanyCode"::VARCHAR,
    c."LegalName"::VARCHAR,
    r."StartedAt" AS "LastBackupAt",
    COALESCE(r."Status", 'NEVER')::VARCHAR AS "LastBackupStatus",
    COALESCE(r."FileSizeMB", 0) AS "LastBackupSizeMB"
  FROM cfg."Company" c
  LEFT JOIN ranked r ON r."CompanyId" = c."CompanyId" AND r.rn = 1
  WHERE c."IsActive" = TRUE
    AND c."TenantStatus" = 'ACTIVE'
  ORDER BY c."CompanyCode";
END;
$fn$;
-- +goose StatementEnd

-- +goose Down
SELECT 1;
