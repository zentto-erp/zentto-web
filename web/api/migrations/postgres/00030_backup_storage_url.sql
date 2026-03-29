-- +goose Up

-- Agregar columnas de almacenamiento en Object Storage (Hetzner S3-compatible)
ALTER TABLE sys."TenantBackup"
  ADD COLUMN IF NOT EXISTS "StorageKey"    VARCHAR(500),   -- path en el bucket: {code}/{filename}
  ADD COLUMN IF NOT EXISTS "StorageUrl"    VARCHAR(1000),  -- URL pública o pre-signed (referencia)
  ADD COLUMN IF NOT EXISTS "StorageStatus" VARCHAR(20);    -- PENDING | UPLOADED | FAILED | null (local only)

-- +goose Down

ALTER TABLE sys."TenantBackup"
  DROP COLUMN IF EXISTS "StorageKey",
  DROP COLUMN IF EXISTS "StorageUrl",
  DROP COLUMN IF EXISTS "StorageStatus";
