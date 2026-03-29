-- +goose Up

-- ─── sys."TenantResourceLog" ──────────────────────────────────────────────────
-- Historial de uso de recursos por tenant (se llena diariamente por job)
CREATE TABLE IF NOT EXISTS sys."TenantResourceLog" (
  "LogId"         BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"     BIGINT NOT NULL,
  "DbName"        VARCHAR(100),
  "DbSizeBytes"   BIGINT,           -- tamaño de la BD en bytes
  "DbSizeMB"      NUMERIC(10,2),    -- calculado
  "TableCount"    INT,
  "LastLoginAt"   TIMESTAMP,        -- último login del tenant
  "UserCount"     INT,
  "RecordedAt"    TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_resource_log_company  ON sys."TenantResourceLog" ("CompanyId");
CREATE INDEX IF NOT EXISTS idx_resource_log_recorded ON sys."TenantResourceLog" ("RecordedAt" DESC);

-- ─── sys."CleanupQueue" ───────────────────────────────────────────────────────
-- Tenants marcados para limpieza con estado del proceso
CREATE TABLE IF NOT EXISTS sys."CleanupQueue" (
  "QueueId"       BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"     BIGINT NOT NULL UNIQUE,
  "Reason"        VARCHAR(50) NOT NULL,
                  -- TRIAL_EXPIRED | CANCELLED_90D | SUSPENDED_180D | MANUAL
  "FlaggedAt"     TIMESTAMP NOT NULL DEFAULT NOW(),
  "FlaggedBy"     VARCHAR(100) DEFAULT 'auto',
  "Status"        VARCHAR(20) NOT NULL DEFAULT 'PENDING',
                  -- PENDING | NOTIFIED | ARCHIVED | DELETED | CANCELLED
  "DbName"        VARCHAR(100),
  "DbSizeBytes"   BIGINT,
  "NotifiedAt"    TIMESTAMP,        -- cuándo se envió email de aviso al cliente
  "DeleteAfter"   TIMESTAMP,        -- fecha mínima para borrar (30 días desde flagged)
  "ProcessedAt"   TIMESTAMP,
  "Notes"         TEXT
);

CREATE INDEX IF NOT EXISTS idx_cleanup_status ON sys."CleanupQueue" ("Status") WHERE "Status" = 'PENDING';

-- ─── sys."License": agregar columna para saber si fue creada de trial ─────────
ALTER TABLE sys."License" ADD COLUMN IF NOT EXISTS "ConvertedFromTrial" BOOLEAN DEFAULT FALSE;

-- ─── SEED: Zentto como primer tenant (INTERNAL, LIFETIME, todos los módulos) ──
-- IMPORTANTE: Solo insertar si CompanyId=1 no existe
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

-- Licencia INTERNAL LIFETIME para Zentto
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

-- Actualizar LicenseKey en Company
UPDATE cfg."Company" c
SET "LicenseKey" = md5('zentto-internal-license-forever')
WHERE c."CompanyCode" = 'ZENTTO'
  AND c."LicenseKey" IS NULL;

-- +goose Down
DROP TABLE IF EXISTS sys."CleanupQueue";
DROP TABLE IF EXISTS sys."TenantResourceLog";
ALTER TABLE sys."License" DROP COLUMN IF EXISTS "ConvertedFromTrial";
DELETE FROM sys."License"
  WHERE "CompanyId" = (SELECT "CompanyId" FROM cfg."Company" WHERE "CompanyCode" = 'ZENTTO')
    AND "LicenseType" = 'INTERNAL';
DELETE FROM cfg."Company" WHERE "CompanyCode" = 'ZENTTO';
