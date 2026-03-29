-- +goose Up

CREATE TABLE IF NOT EXISTS sys."TenantBackup" (
  "BackupId"        BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"       BIGINT NOT NULL,
  "DbName"          VARCHAR(100) NOT NULL,
  "FilePath"        VARCHAR(500),
  "FileName"        VARCHAR(200),
  "FileSizeBytes"   BIGINT,
  "FileSizeMB"      NUMERIC(10,2),
  "Status"          VARCHAR(20) NOT NULL DEFAULT 'PENDING',
                    -- PENDING | RUNNING | DONE | FAILED
  "StartedAt"       TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CompletedAt"     TIMESTAMP,
  "ErrorMessage"    TEXT,
  "CreatedBy"       VARCHAR(100) DEFAULT 'backoffice',
  "Notes"           TEXT
);

CREATE INDEX IF NOT EXISTS idx_backup_company ON sys."TenantBackup" ("CompanyId");
CREATE INDEX IF NOT EXISTS idx_backup_status  ON sys."TenantBackup" ("Status");

-- +goose Down
DROP TABLE IF EXISTS sys."TenantBackup";
