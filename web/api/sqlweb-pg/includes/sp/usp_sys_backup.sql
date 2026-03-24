-- ============================================================
-- usp_sys_backup.sql — Sistema de respaldos de bases de datos de tenants
-- Motor: PostgreSQL (plpgsql)
-- Paridad: web/api/sqlweb/includes/sp/usp_sys_backup.sql
-- ============================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- usp_sys_backup_tenantinfo(p_company_id)
-- Devuelve CompanyCode y DbName de un tenant para iniciar un backup.
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION usp_sys_backup_tenantinfo(
  p_company_id BIGINT
)
RETURNS TABLE(
  "CompanyCode" VARCHAR,
  "DbName"      VARCHAR
)
LANGUAGE plpgsql AS $$
BEGIN
  RETURN QUERY
  SELECT
    c."CompanyCode"::VARCHAR,
    COALESCE(td."DbName", 'zentto_tenant_' || LOWER(c."CompanyCode"))::VARCHAR AS "DbName"
  FROM cfg."Company" c
  LEFT JOIN sys."TenantDatabase" td ON td."CompanyId" = c."CompanyId"
  WHERE c."CompanyId" = p_company_id
    AND c."IsActive" = TRUE
  LIMIT 1;
END;
$$;

-- ─────────────────────────────────────────────────────────────────────────────
-- usp_sys_backup_create(p_company_id, p_db_name, p_created_by)
-- Registra un nuevo backup con Status='RUNNING'.
-- Retorna el BackupId generado.
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION usp_sys_backup_create(
  p_company_id  BIGINT,
  p_db_name     VARCHAR,
  p_created_by  VARCHAR DEFAULT 'backoffice'
)
RETURNS TABLE(
  "BackupId" BIGINT
)
LANGUAGE plpgsql AS $$
DECLARE
  v_backup_id BIGINT;
BEGIN
  INSERT INTO sys."TenantBackup" (
    "CompanyId",
    "DbName",
    "Status",
    "StartedAt",
    "CreatedBy"
  )
  VALUES (
    p_company_id,
    p_db_name,
    'RUNNING',
    NOW() AT TIME ZONE 'UTC',
    COALESCE(p_created_by, 'backoffice')
  )
  RETURNING "BackupId" INTO v_backup_id;

  RETURN QUERY SELECT v_backup_id;
END;
$$;

-- ─────────────────────────────────────────────────────────────────────────────
-- usp_sys_backup_complete(p_backup_id, p_file_path, p_file_name, p_file_size_bytes)
-- Marca un backup como DONE y registra metadatos del archivo generado.
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION usp_sys_backup_complete(
  p_backup_id        BIGINT,
  p_file_path        VARCHAR,
  p_file_name        VARCHAR,
  p_file_size_bytes  BIGINT,
  p_storage_key      VARCHAR DEFAULT NULL,
  p_storage_status   VARCHAR DEFAULT NULL
)
RETURNS TABLE(
  "ok"      BOOLEAN,
  "mensaje" VARCHAR
)
LANGUAGE plpgsql AS $$
BEGIN
  UPDATE sys."TenantBackup"
  SET
    "Status"        = 'DONE',
    "FilePath"      = p_file_path,
    "FileName"      = p_file_name,
    "FileSizeBytes" = p_file_size_bytes,
    "FileSizeMB"    = ROUND(p_file_size_bytes::NUMERIC / 1048576.0, 2),
    "CompletedAt"   = NOW() AT TIME ZONE 'UTC',
    "StorageKey"    = p_storage_key,
    "StorageStatus" = p_storage_status
  WHERE "BackupId" = p_backup_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE::BOOLEAN, 'backup_not_found'::VARCHAR;
    RETURN;
  END IF;

  RETURN QUERY SELECT TRUE::BOOLEAN, 'backup_completed'::VARCHAR;
END;
$$;

-- ─────────────────────────────────────────────────────────────────────────────
-- usp_sys_backup_fail(p_backup_id, p_error_message)
-- Marca un backup como FAILED y registra el mensaje de error.
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION usp_sys_backup_fail(
  p_backup_id      BIGINT,
  p_error_message  VARCHAR
)
RETURNS TABLE(
  "ok"      BOOLEAN,
  "mensaje" VARCHAR
)
LANGUAGE plpgsql AS $$
BEGIN
  UPDATE sys."TenantBackup"
  SET
    "Status"       = 'FAILED',
    "ErrorMessage" = p_error_message,
    "CompletedAt"  = NOW() AT TIME ZONE 'UTC'
  WHERE "BackupId" = p_backup_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE::BOOLEAN, 'backup_not_found'::VARCHAR;
    RETURN;
  END IF;

  RETURN QUERY SELECT TRUE::BOOLEAN, 'backup_failed_registered'::VARCHAR;
END;
$$;

-- ─────────────────────────────────────────────────────────────────────────────
-- usp_sys_backup_list(p_company_id)
-- Lista todos los backups, opcionalmente filtrado por tenant.
-- Incluye CompanyCode y LegalName via JOIN con cfg."Company".
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION usp_sys_backup_list(
  p_company_id BIGINT DEFAULT NULL
)
RETURNS TABLE(
  "BackupId"     BIGINT,
  "CompanyId"    BIGINT,
  "CompanyCode"  VARCHAR,
  "LegalName"    VARCHAR,
  "DbName"       VARCHAR,
  "FileName"     VARCHAR,
  "FileSizeMB"   NUMERIC,
  "Status"       VARCHAR,
  "StartedAt"    TIMESTAMP,
  "CompletedAt"  TIMESTAMP,
  "ErrorMessage" VARCHAR
)
LANGUAGE plpgsql AS $$
BEGIN
  RETURN QUERY
  SELECT
    b."BackupId",
    b."CompanyId",
    c."CompanyCode"::VARCHAR,
    c."LegalName"::VARCHAR,
    b."DbName"::VARCHAR,
    COALESCE(b."FileName", '')::VARCHAR    AS "FileName",
    COALESCE(b."FileSizeMB", 0)            AS "FileSizeMB",
    b."Status"::VARCHAR,
    b."StartedAt",
    b."CompletedAt",
    COALESCE(b."ErrorMessage", '')::VARCHAR AS "ErrorMessage"
  FROM sys."TenantBackup" b
  JOIN cfg."Company" c ON c."CompanyId" = b."CompanyId"
  WHERE (p_company_id IS NULL OR b."CompanyId" = p_company_id)
  ORDER BY b."StartedAt" DESC;
END;
$$;

-- ─────────────────────────────────────────────────────────────────────────────
-- usp_sys_backup_latest_per_tenant()
-- Devuelve el último backup (más reciente) por cada tenant.
-- Usado por el dashboard de backoffice.
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION usp_sys_backup_latest_per_tenant()
RETURNS TABLE(
  "CompanyId"          BIGINT,
  "CompanyCode"        VARCHAR,
  "LegalName"          VARCHAR,
  "LastBackupAt"       TIMESTAMP,
  "LastBackupStatus"   VARCHAR,
  "LastBackupSizeMB"   NUMERIC
)
LANGUAGE plpgsql AS $$
BEGIN
  RETURN QUERY
  WITH ranked AS (
    SELECT
      b."CompanyId",
      b."Status",
      b."StartedAt",
      b."FileSizeMB",
      ROW_NUMBER() OVER (
        PARTITION BY b."CompanyId"
        ORDER BY b."StartedAt" DESC
      ) AS rn
    FROM sys."TenantBackup" b
  )
  SELECT
    c."CompanyId",
    c."CompanyCode"::VARCHAR,
    c."LegalName"::VARCHAR,
    r."StartedAt"                              AS "LastBackupAt",
    COALESCE(r."Status", 'NEVER')::VARCHAR     AS "LastBackupStatus",
    COALESCE(r."FileSizeMB", 0)                AS "LastBackupSizeMB"
  FROM cfg."Company" c
  LEFT JOIN ranked r ON r."CompanyId" = c."CompanyId" AND r.rn = 1
  WHERE c."IsActive" = TRUE
    AND c."TenantStatus" = 'ACTIVE'
  ORDER BY c."CompanyCode";
END;
$$;
