-- +goose Up

IF COL_LENGTH('sys.TenantBackup', 'StorageKey') IS NULL
  ALTER TABLE sys.TenantBackup ADD StorageKey    NVARCHAR(500)  NULL;
IF COL_LENGTH('sys.TenantBackup', 'StorageUrl') IS NULL
  ALTER TABLE sys.TenantBackup ADD StorageUrl    NVARCHAR(1000) NULL;
IF COL_LENGTH('sys.TenantBackup', 'StorageStatus') IS NULL
  ALTER TABLE sys.TenantBackup ADD StorageStatus NVARCHAR(20)   NULL;

-- +goose Down

ALTER TABLE sys.TenantBackup DROP COLUMN StorageKey;
ALTER TABLE sys.TenantBackup DROP COLUMN StorageUrl;
ALTER TABLE sys.TenantBackup DROP COLUMN StorageStatus;
