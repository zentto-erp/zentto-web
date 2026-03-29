-- ============================================================
-- 00028_tenant_resource_management.sql — Gestión de recursos de tenants
-- Motor: SQL Server
-- Paridad: web/api/migrations/postgres/00028_tenant_resource_management.sql
-- ============================================================

-- ─── sys.TenantResourceLog ────────────────────────────────────────────────────
-- Historial de uso de recursos por tenant (se llena diariamente por job)
IF NOT EXISTS (
  SELECT 1 FROM INFORMATION_SCHEMA.TABLES
  WHERE TABLE_SCHEMA = 'sys' AND TABLE_NAME = 'TenantResourceLog'
)
BEGIN
  CREATE TABLE sys.TenantResourceLog (
    LogId         BIGINT IDENTITY(1,1) PRIMARY KEY,
    CompanyId     BIGINT NOT NULL,
    DbName        NVARCHAR(100) NULL,
    DbSizeBytes   BIGINT NULL,        -- tamaño de la BD en bytes
    DbSizeMB      NUMERIC(10,2) NULL, -- calculado
    TableCount    INT NULL,
    LastLoginAt   DATETIME2 NULL,     -- último login del tenant
    UserCount     INT NULL,
    RecordedAt    DATETIME2 NOT NULL DEFAULT GETUTCDATE()
  );

  CREATE INDEX idx_resource_log_company  ON sys.TenantResourceLog (CompanyId);
  CREATE INDEX idx_resource_log_recorded ON sys.TenantResourceLog (RecordedAt DESC);
END
GO

-- ─── sys.CleanupQueue ─────────────────────────────────────────────────────────
-- Tenants marcados para limpieza con estado del proceso
IF NOT EXISTS (
  SELECT 1 FROM INFORMATION_SCHEMA.TABLES
  WHERE TABLE_SCHEMA = 'sys' AND TABLE_NAME = 'CleanupQueue'
)
BEGIN
  CREATE TABLE sys.CleanupQueue (
    QueueId       BIGINT IDENTITY(1,1) PRIMARY KEY,
    CompanyId     BIGINT NOT NULL,
    Reason        NVARCHAR(50) NOT NULL,
                  -- TRIAL_EXPIRED | CANCELLED_90D | SUSPENDED_180D | MANUAL
    FlaggedAt     DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    FlaggedBy     NVARCHAR(100) DEFAULT 'auto',
    Status        NVARCHAR(20) NOT NULL DEFAULT 'PENDING',
                  -- PENDING | NOTIFIED | ARCHIVED | DELETED | CANCELLED
    DbName        NVARCHAR(100) NULL,
    DbSizeBytes   BIGINT NULL,
    NotifiedAt    DATETIME2 NULL,     -- cuándo se envió email de aviso al cliente
    DeleteAfter   DATETIME2 NULL,     -- fecha mínima para borrar (30 días desde flagged)
    ProcessedAt   DATETIME2 NULL,
    Notes         NVARCHAR(MAX) NULL,
    CONSTRAINT UQ_CleanupQueue_CompanyId UNIQUE (CompanyId)
  );

  CREATE INDEX idx_cleanup_status ON sys.CleanupQueue (Status)
    WHERE Status = 'PENDING';
END
GO

-- ─── sys.License: agregar columna ConvertedFromTrial ─────────────────────────
IF COL_LENGTH('sys.License', 'ConvertedFromTrial') IS NULL
BEGIN
  ALTER TABLE sys.License ADD ConvertedFromTrial BIT NOT NULL DEFAULT 0;
END
GO

-- ─── SEED: Zentto como primer tenant (INTERNAL, LIFETIME) ────────────────────
-- Solo insertar si ZENTTO no existe
IF NOT EXISTS (SELECT 1 FROM cfg.Company WHERE CompanyCode = 'ZENTTO')
BEGIN
  INSERT INTO cfg.Company (
    CompanyCode, LegalName, TradeName,
    FiscalCountryCode, BaseCurrency,
    Plan, TenantStatus, IsActive,
    OwnerEmail, TenantSubdomain, CreatedAt
  ) VALUES (
    'ZENTTO', 'Zentto ERP S.A.', 'Zentto',
    'VE', 'USD',
    'ENTERPRISE', 'ACTIVE', 1,
    'admin@zentto.net', 'app', GETUTCDATE()
  );
END
GO

-- Licencia INTERNAL LIFETIME para Zentto
IF NOT EXISTS (
  SELECT 1 FROM sys.License l
  INNER JOIN cfg.Company c ON c.CompanyId = l.CompanyId
  WHERE c.CompanyCode = 'ZENTTO' AND l.LicenseType = 'INTERNAL'
)
BEGIN
  DECLARE @ZenttoCompanyId BIGINT;
  SELECT @ZenttoCompanyId = CompanyId FROM cfg.Company WHERE CompanyCode = 'ZENTTO';

  IF @ZenttoCompanyId IS NOT NULL
  BEGIN
    INSERT INTO sys.License (
      CompanyId, LicenseType, Plan, LicenseKey, Status,
      StartsAt, ExpiresAt, Notes
    ) VALUES (
      @ZenttoCompanyId,
      'INTERNAL', 'ENTERPRISE',
      CONVERT(NVARCHAR(64), HASHBYTES('MD5', 'zentto-internal-license-forever'), 2),
      'ACTIVE', GETUTCDATE(), NULL,
      N'Licencia interna Zentto — nunca expira'
    );

    -- Actualizar LicenseKey en Company
    UPDATE cfg.Company
    SET LicenseKey = CONVERT(NVARCHAR(64), HASHBYTES('MD5', 'zentto-internal-license-forever'), 2)
    WHERE CompanyId = @ZenttoCompanyId
      AND LicenseKey IS NULL;
  END
END
GO
