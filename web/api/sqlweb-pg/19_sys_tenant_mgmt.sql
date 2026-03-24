-- 19_sys_tenant_mgmt.sql
-- Schema sys + tablas de gestión de tenants
-- Refleja migraciones 00002, 00027, 00028, 00029, 00030

CREATE SCHEMA IF NOT EXISTS sys;

-- ─── sys."TenantDatabase" (migración 00002) ───────────────────────────────────
CREATE TABLE IF NOT EXISTS sys."TenantDatabase" (
  "TenantDbId"    INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"     INT NOT NULL,
  "CompanyCode"   VARCHAR(20) NOT NULL,
  "DbName"        VARCHAR(63) NOT NULL,
  "DbHost"        VARCHAR(255) DEFAULT NULL,
  "DbPort"        INT DEFAULT NULL,
  "DbUser"        VARCHAR(63) DEFAULT NULL,
  "DbPassword"    VARCHAR(255) DEFAULT NULL,
  "PoolMin"       INT NOT NULL DEFAULT 0,
  "PoolMax"       INT NOT NULL DEFAULT 5,
  "IsActive"      BOOLEAN NOT NULL DEFAULT TRUE,
  "IsDemo"        BOOLEAN NOT NULL DEFAULT FALSE,
  "ProvisionedAt" TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "LastMigration" VARCHAR(100) NULL,
  "CreatedAt"     TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  CONSTRAINT "UQ_sys_TenantDatabase_CompanyId" UNIQUE ("CompanyId"),
  CONSTRAINT "UQ_sys_TenantDatabase_DbName" UNIQUE ("DbName")
);

-- ─── sys."License" (migración 00027) ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS sys."License" (
  "LicenseId"         BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"         BIGINT NOT NULL,
  "LicenseType"       VARCHAR(20) NOT NULL DEFAULT 'SUBSCRIPTION',
  "Plan"              VARCHAR(30) NOT NULL DEFAULT 'STARTER',
  "LicenseKey"        VARCHAR(64) NOT NULL UNIQUE,
  "Status"            VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
  "StartsAt"          TIMESTAMP NOT NULL DEFAULT NOW(),
  "ExpiresAt"         TIMESTAMP,
  "PaddleSubId"       VARCHAR(100),
  "ContractRef"       VARCHAR(100),
  "MaxUsers"          INT,
  "MaxBranches"       INT,
  "Notes"             TEXT,
  "ConvertedFromTrial" BOOLEAN DEFAULT FALSE,
  "CreatedAt"         TIMESTAMP NOT NULL DEFAULT NOW(),
  "UpdatedAt"         TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_license_company ON sys."License" ("CompanyId");
CREATE INDEX IF NOT EXISTS idx_license_key     ON sys."License" ("LicenseKey");

-- ─── sys."TenantResourceLog" (migración 00028) ───────────────────────────────
CREATE TABLE IF NOT EXISTS sys."TenantResourceLog" (
  "LogId"       BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"   BIGINT NOT NULL,
  "DbName"      VARCHAR(100),
  "DbSizeBytes" BIGINT,
  "DbSizeMB"    NUMERIC(10,2),
  "TableCount"  INT,
  "LastLoginAt" TIMESTAMP,
  "UserCount"   INT,
  "RecordedAt"  TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_resource_log_company  ON sys."TenantResourceLog" ("CompanyId");
CREATE INDEX IF NOT EXISTS idx_resource_log_recorded ON sys."TenantResourceLog" ("RecordedAt" DESC);

-- ─── sys."CleanupQueue" (migración 00028) ────────────────────────────────────
CREATE TABLE IF NOT EXISTS sys."CleanupQueue" (
  "QueueId"       BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"     BIGINT NOT NULL UNIQUE,
  "Reason"        VARCHAR(50) NOT NULL,
  "FlaggedAt"     TIMESTAMP NOT NULL DEFAULT NOW(),
  "FlaggedBy"     VARCHAR(100) DEFAULT 'auto',
  "Status"        VARCHAR(20) NOT NULL DEFAULT 'PENDING',
  "NotifiedAt"    TIMESTAMP,
  "ArchivedAt"    TIMESTAMP,
  "DeletedAt"     TIMESTAMP,
  "Notes"         TEXT
);

CREATE INDEX IF NOT EXISTS idx_cleanup_status ON sys."CleanupQueue" ("Status") WHERE "Status" = 'PENDING';

-- ─── sys."TenantBackup" (migraciones 00029/00030) ────────────────────────────
CREATE TABLE IF NOT EXISTS sys."TenantBackup" (
  "BackupId"      BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"     BIGINT NOT NULL,
  "DbName"        VARCHAR(100) NOT NULL,
  "FilePath"      VARCHAR(500),
  "FileName"      VARCHAR(200),
  "FileSizeBytes" BIGINT,
  "FileSizeMB"    NUMERIC(10,2),
  "Status"        VARCHAR(20) NOT NULL DEFAULT 'PENDING',
  "StartedAt"     TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CompletedAt"   TIMESTAMP,
  "ErrorMessage"  TEXT,
  "CreatedBy"     VARCHAR(100) DEFAULT 'backoffice',
  "Notes"         TEXT,
  "StorageKey"    VARCHAR(500),
  "StorageUrl"    VARCHAR(1000),
  "StorageStatus" VARCHAR(20) DEFAULT 'LOCAL_ONLY'
);

CREATE INDEX IF NOT EXISTS idx_backup_company ON sys."TenantBackup" ("CompanyId");
CREATE INDEX IF NOT EXISTS idx_backup_status  ON sys."TenantBackup" ("Status");

-- ─── SEED: cfg.Company agregar columna LicenseKey si no existe ────────────────
ALTER TABLE cfg."Company" ADD COLUMN IF NOT EXISTS "LicenseKey"      VARCHAR(64);
ALTER TABLE cfg."Company" ADD COLUMN IF NOT EXISTS "Plan"            VARCHAR(30);
ALTER TABLE cfg."Company" ADD COLUMN IF NOT EXISTS "TenantStatus"    VARCHAR(20);
ALTER TABLE cfg."Company" ADD COLUMN IF NOT EXISTS "OwnerEmail"      VARCHAR(255);
ALTER TABLE cfg."Company" ADD COLUMN IF NOT EXISTS "TenantSubdomain" VARCHAR(100);

-- ─── SEED: Zentto como primer tenant (interno) ────────────────────────────────
-- Inserta la empresa Zentto si no existe (primer tenant del sistema)
INSERT INTO cfg."Company" (
  "CompanyCode", "LegalName", "TradeName",
  "FiscalCountryCode", "BaseCurrency",
  "Plan", "TenantStatus", "IsActive",
  "OwnerEmail", "TenantSubdomain", "CreatedAt"
)
SELECT
  'ZENTTO', 'Zentto ERP S.A.', 'Zentto',
  'VE', 'USD',
  'ENTERPRISE', 'ACTIVE', TRUE,
  'admin@zentto.net', 'app', NOW()
WHERE NOT EXISTS (SELECT 1 FROM cfg."Company" WHERE "CompanyCode" = 'ZENTTO')
ON CONFLICT ("CompanyCode") DO NOTHING;

-- ─── SEED: TenantDatabase — BD demo apunta a la BD actual ────────────────────
INSERT INTO sys."TenantDatabase" ("CompanyId", "CompanyCode", "DbName", "IsDemo")
VALUES (0, 'DEMO', current_database(), TRUE)
ON CONFLICT ("CompanyId") DO UPDATE SET "DbName" = EXCLUDED."DbName";

-- TenantDatabase para la empresa DEFAULT (primer tenant real)
INSERT INTO sys."TenantDatabase" ("CompanyId", "CompanyCode", "DbName", "IsDemo")
SELECT c."CompanyId", c."CompanyCode", current_database(), FALSE
FROM cfg."Company" c
WHERE c."CompanyCode" = 'DEFAULT'
  AND NOT EXISTS (
    SELECT 1 FROM sys."TenantDatabase" t WHERE t."CompanyCode" = 'DEFAULT'
  )
ON CONFLICT ("CompanyId") DO NOTHING;

-- TenantDatabase para Zentto (tenant interno)
INSERT INTO sys."TenantDatabase" ("CompanyId", "CompanyCode", "DbName", "IsDemo")
SELECT c."CompanyId", c."CompanyCode", current_database(), FALSE
FROM cfg."Company" c
WHERE c."CompanyCode" = 'ZENTTO'
  AND NOT EXISTS (
    SELECT 1 FROM sys."TenantDatabase" t WHERE t."CompanyCode" = 'ZENTTO'
  )
ON CONFLICT ("CompanyId") DO NOTHING;

-- ─── SEED: sys.License — licencia INTERNAL LIFETIME para Zentto ──────────────
INSERT INTO sys."License" (
  "CompanyId", "LicenseType", "Plan", "LicenseKey", "Status",
  "StartsAt", "ExpiresAt", "Notes"
)
SELECT
  c."CompanyId",
  'INTERNAL', 'ENTERPRISE',
  md5('zentto-internal-license-forever'),
  'ACTIVE', NOW(), NULL,
  'Licencia interna Zentto — nunca expira'
FROM cfg."Company" c
WHERE c."CompanyCode" = 'ZENTTO'
  AND NOT EXISTS (
    SELECT 1 FROM sys."License" l
    WHERE l."CompanyId" = c."CompanyId"
      AND l."LicenseType" = 'INTERNAL'
  )
ON CONFLICT DO NOTHING;

-- Actualizar LicenseKey en cfg.Company para Zentto
UPDATE cfg."Company"
SET "LicenseKey" = md5('zentto-internal-license-forever')
WHERE "CompanyCode" = 'ZENTTO'
  AND "LicenseKey" IS NULL;
