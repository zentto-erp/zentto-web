-- ============================================================
-- usp_sys_backup.sql — Sistema de respaldos de bases de datos de tenants
-- Motor: SQL Server
-- Paridad: web/api/sqlweb-pg/includes/sp/usp_sys_backup.sql
-- ============================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- usp_Sys_Backup_TenantInfo
-- Devuelve CompanyCode y DbName de un tenant para iniciar un backup.
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR ALTER PROCEDURE dbo.usp_Sys_Backup_TenantInfo
  @CompanyId BIGINT
AS
BEGIN
  SET NOCOUNT ON;

  SELECT
    c.CompanyCode,
    COALESCE(td.DbName, N'zentto_tenant_' + LOWER(c.CompanyCode)) AS DbName
  FROM cfg.Company c
  LEFT JOIN sys.TenantDatabase td ON td.CompanyId = c.CompanyId
  WHERE c.CompanyId = @CompanyId
    AND c.IsActive = 1;
END;
GO

-- ─────────────────────────────────────────────────────────────────────────────
-- usp_Sys_Backup_Create
-- Registra un nuevo backup con Status='RUNNING'.
-- Retorna el BackupId generado via OUTPUT.
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR ALTER PROCEDURE dbo.usp_Sys_Backup_Create
  @CompanyId  BIGINT,
  @DbName     NVARCHAR(100),
  @CreatedBy  NVARCHAR(100) = N'backoffice',
  @BackupId   BIGINT OUTPUT
AS
BEGIN
  SET NOCOUNT ON;

  INSERT INTO sys.TenantBackup (
    CompanyId,
    DbName,
    Status,
    StartedAt,
    CreatedBy
  )
  VALUES (
    @CompanyId,
    @DbName,
    N'RUNNING',
    SYSUTCDATETIME(),
    ISNULL(@CreatedBy, N'backoffice')
  );

  SET @BackupId = SCOPE_IDENTITY();
END;
GO

-- ─────────────────────────────────────────────────────────────────────────────
-- usp_Sys_Backup_Complete
-- Marca un backup como DONE y registra metadatos del archivo generado.
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR ALTER PROCEDURE dbo.usp_Sys_Backup_Complete
  @BackupId        BIGINT,
  @FilePath        NVARCHAR(500),
  @FileName        NVARCHAR(200),
  @FileSizeBytes   BIGINT,
  @Resultado       INT           OUTPUT,
  @Mensaje         NVARCHAR(500) OUTPUT
AS
BEGIN
  SET NOCOUNT ON;

  UPDATE sys.TenantBackup
  SET
    Status        = N'DONE',
    FilePath      = @FilePath,
    FileName      = @FileName,
    FileSizeBytes = @FileSizeBytes,
    FileSizeMB    = ROUND(CAST(@FileSizeBytes AS NUMERIC(18,2)) / 1048576.0, 2),
    CompletedAt   = SYSUTCDATETIME()
  WHERE BackupId = @BackupId;

  IF @@ROWCOUNT = 0
  BEGIN
    SET @Resultado = 0;
    SET @Mensaje   = N'backup_not_found';
    RETURN;
  END;

  SET @Resultado = 1;
  SET @Mensaje   = N'backup_completed';
END;
GO

-- ─────────────────────────────────────────────────────────────────────────────
-- usp_Sys_Backup_Fail
-- Marca un backup como FAILED y registra el mensaje de error.
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR ALTER PROCEDURE dbo.usp_Sys_Backup_Fail
  @BackupId      BIGINT,
  @ErrorMessage  NVARCHAR(500),
  @Resultado     INT           OUTPUT,
  @Mensaje       NVARCHAR(500) OUTPUT
AS
BEGIN
  SET NOCOUNT ON;

  UPDATE sys.TenantBackup
  SET
    Status       = N'FAILED',
    ErrorMessage = @ErrorMessage,
    CompletedAt  = SYSUTCDATETIME()
  WHERE BackupId = @BackupId;

  IF @@ROWCOUNT = 0
  BEGIN
    SET @Resultado = 0;
    SET @Mensaje   = N'backup_not_found';
    RETURN;
  END;

  SET @Resultado = 1;
  SET @Mensaje   = N'backup_failed_registered';
END;
GO

-- ─────────────────────────────────────────────────────────────────────────────
-- usp_Sys_Backup_List
-- Lista todos los backups, opcionalmente filtrado por tenant.
-- Incluye CompanyCode y LegalName via JOIN con cfg.Company.
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR ALTER PROCEDURE dbo.usp_Sys_Backup_List
  @CompanyId BIGINT = NULL
AS
BEGIN
  SET NOCOUNT ON;

  SELECT
    b.BackupId,
    b.CompanyId,
    c.CompanyCode,
    c.LegalName,
    b.DbName,
    ISNULL(b.FileName, N'')    AS FileName,
    ISNULL(b.FileSizeMB, 0)    AS FileSizeMB,
    b.Status,
    b.StartedAt,
    b.CompletedAt,
    ISNULL(b.ErrorMessage, N'') AS ErrorMessage
  FROM sys.TenantBackup b
  JOIN cfg.Company c ON c.CompanyId = b.CompanyId
  WHERE (@CompanyId IS NULL OR b.CompanyId = @CompanyId)
  ORDER BY b.StartedAt DESC;
END;
GO

-- ─────────────────────────────────────────────────────────────────────────────
-- usp_Sys_Backup_Latest_Per_Tenant
-- Devuelve el último backup (más reciente) por cada tenant activo.
-- Usado por el dashboard de backoffice.
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR ALTER PROCEDURE dbo.usp_Sys_Backup_Latest_Per_Tenant
AS
BEGIN
  SET NOCOUNT ON;

  WITH ranked AS (
    SELECT
      b.CompanyId,
      b.Status,
      b.StartedAt,
      b.FileSizeMB,
      ROW_NUMBER() OVER (
        PARTITION BY b.CompanyId
        ORDER BY b.StartedAt DESC
      ) AS rn
    FROM sys.TenantBackup b
  )
  SELECT
    c.CompanyId,
    c.CompanyCode,
    c.LegalName,
    r.StartedAt                        AS LastBackupAt,
    ISNULL(r.Status, N'NEVER')         AS LastBackupStatus,
    ISNULL(r.FileSizeMB, 0)            AS LastBackupSizeMB
  FROM cfg.Company c
  LEFT JOIN ranked r ON r.CompanyId = c.CompanyId AND r.rn = 1
  WHERE c.IsActive = 1
    AND c.TenantStatus = N'ACTIVE'
  ORDER BY c.CompanyCode;
END;
GO
