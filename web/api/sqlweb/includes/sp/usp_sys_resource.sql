-- ============================================================
-- usp_sys_resource.sql — Gestión de recursos de tenants
-- Motor: SQL Server
-- Paridad: web/api/sqlweb-pg/includes/sp/usp_sys_resource.sql
-- ============================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- usp_Sys_Resource_Audit
-- Audita el tamaño de BD y actividad de cada tenant activo.
-- Usa sys.master_files para obtener el tamaño de archivos MDF/NDF.
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR ALTER PROCEDURE dbo.usp_Sys_Resource_Audit
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE
    @CompanyId     BIGINT,
    @DbName        NVARCHAR(100),
    @DbSizeBytes   BIGINT,
    @DbSizeMB      NUMERIC(10,2),
    @LastLogin     DATETIME2,
    @UserCount     INT,
    @TenantsCount  INT = 0,
    @TotalBytes    BIGINT = 0;

  -- Cursor sobre todos los tenants activos con BD registrada
  DECLARE tenant_cur CURSOR LOCAL FAST_FORWARD FOR
    SELECT t.CompanyId, t.DbName
    FROM sys.TenantDatabase t
    WHERE t.IsActive = 1
    ORDER BY t.CompanyId;

  OPEN tenant_cur;
  FETCH NEXT FROM tenant_cur INTO @CompanyId, @DbName;

  WHILE @@FETCH_STATUS = 0
  BEGIN
    -- Tamaño de la BD usando sys.master_files (suma MDF + NDF)
    BEGIN TRY
      SELECT @DbSizeBytes = SUM(CAST(size AS BIGINT) * 8192)
      FROM sys.master_files mf
      INNER JOIN sys.databases db ON db.database_id = mf.database_id
      WHERE db.name = @DbName
        AND mf.type IN (0, 1); -- 0=data, 1=log
    END TRY
    BEGIN CATCH
      SET @DbSizeBytes = NULL;
    END CATCH;

    SET @DbSizeMB = CASE
      WHEN @DbSizeBytes IS NOT NULL THEN ROUND(CAST(@DbSizeBytes AS FLOAT) / 1048576.0, 2)
      ELSE NULL
    END;

    -- Último login del tenant desde audit.AuditLog en master
    BEGIN TRY
      SELECT @LastLogin = MAX(a.CreatedAt)
      FROM audit.AuditLog a
      WHERE a.CompanyId = @CompanyId
        AND a.ModuleName = 'auth';
    END TRY
    BEGIN CATCH
      SET @LastLogin = NULL;
    END CATCH;

    -- Conteo de usuarios activos del tenant
    BEGIN TRY
      SELECT @UserCount = COUNT(*)
      FROM sec.[User] u
      WHERE u.CompanyId = @CompanyId
        AND u.IsActive = 1
        AND u.IsDeleted = 0;
    END TRY
    BEGIN CATCH
      SET @UserCount = NULL;
    END CATCH;

    -- Insertar registro de auditoría
    INSERT INTO sys.TenantResourceLog (
      CompanyId, DbName,
      DbSizeBytes, DbSizeMB,
      TableCount, LastLoginAt,
      UserCount, RecordedAt
    ) VALUES (
      @CompanyId, @DbName,
      @DbSizeBytes, @DbSizeMB,
      NULL,         -- TableCount no aplica en SQL Server cross-db
      @LastLogin,
      @UserCount,
      GETUTCDATE()
    );

    SET @TenantsCount = @TenantsCount + 1;
    SET @TotalBytes   = @TotalBytes + ISNULL(@DbSizeBytes, 0);

    FETCH NEXT FROM tenant_cur INTO @CompanyId, @DbName;
  END;

  CLOSE tenant_cur;
  DEALLOCATE tenant_cur;

  -- Resultado
  SELECT
    @TenantsCount                              AS tenants_audited,
    ROUND(CAST(@TotalBytes AS FLOAT) / 1048576.0, 2) AS total_size_mb;
END;
GO

-- ─────────────────────────────────────────────────────────────────────────────
-- usp_Sys_Cleanup_Scan
-- Detecta automáticamente tenants candidatos a limpieza según 3 reglas.
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR ALTER PROCEDURE dbo.usp_Sys_Cleanup_Scan
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @NewCandidates INT = 0, @TotalPending INT;

  -- ── Regla 1: TRIAL_EXPIRED ─────────────────────────────────────────────────
  INSERT INTO sys.CleanupQueue (
    CompanyId, Reason, FlaggedAt, FlaggedBy,
    Status, DbName, DbSizeBytes, DeleteAfter
  )
  SELECT DISTINCT
    c.CompanyId,
    'TRIAL_EXPIRED',
    GETUTCDATE(),
    'auto',
    'PENDING',
    t.DbName,
    NULL,
    DATEADD(DAY, 30, GETUTCDATE())
  FROM cfg.Company c
  INNER JOIN sys.License l
    ON l.CompanyId = c.CompanyId
   AND l.LicenseType = 'TRIAL'
   AND l.Status IN ('EXPIRED', 'CANCELLED')
   AND l.ExpiresAt < DATEADD(DAY, -30, GETUTCDATE())
   AND ISNULL(l.ConvertedFromTrial, 0) = 0
  LEFT JOIN sys.TenantDatabase t ON t.CompanyId = c.CompanyId
  WHERE c.Plan = 'FREE'
    AND c.IsActive = 1
    AND c.IsDeleted = 0
    AND NOT EXISTS (
      SELECT 1 FROM sys.CleanupQueue q WHERE q.CompanyId = c.CompanyId
    );

  SET @NewCandidates = @NewCandidates + @@ROWCOUNT;

  -- ── Regla 2: CANCELLED_90D ─────────────────────────────────────────────────
  INSERT INTO sys.CleanupQueue (
    CompanyId, Reason, FlaggedAt, FlaggedBy,
    Status, DbName, DbSizeBytes, DeleteAfter
  )
  SELECT DISTINCT
    c.CompanyId,
    'CANCELLED_90D',
    GETUTCDATE(),
    'auto',
    'PENDING',
    t.DbName,
    NULL,
    DATEADD(DAY, 30, GETUTCDATE())
  FROM cfg.Company c
  INNER JOIN sys.License l
    ON l.CompanyId = c.CompanyId
   AND l.Status = 'CANCELLED'
   AND l.UpdatedAt < DATEADD(DAY, -90, GETUTCDATE())
  LEFT JOIN sys.TenantDatabase t ON t.CompanyId = c.CompanyId
  WHERE c.IsActive = 1
    AND c.IsDeleted = 0
    AND NOT EXISTS (
      SELECT 1 FROM sys.License la
      WHERE la.CompanyId = c.CompanyId
        AND la.Status = 'ACTIVE'
        AND la.LicenseType = 'INTERNAL'
    )
    AND NOT EXISTS (
      SELECT 1 FROM sys.CleanupQueue q WHERE q.CompanyId = c.CompanyId
    );

  SET @NewCandidates = @NewCandidates + @@ROWCOUNT;

  -- ── Regla 3: SUSPENDED_180D ────────────────────────────────────────────────
  INSERT INTO sys.CleanupQueue (
    CompanyId, Reason, FlaggedAt, FlaggedBy,
    Status, DbName, DbSizeBytes, DeleteAfter
  )
  SELECT DISTINCT
    c.CompanyId,
    'SUSPENDED_180D',
    GETUTCDATE(),
    'auto',
    'PENDING',
    t.DbName,
    NULL,
    DATEADD(DAY, 30, GETUTCDATE())
  FROM cfg.Company c
  LEFT JOIN sys.TenantDatabase t ON t.CompanyId = c.CompanyId
  WHERE c.TenantStatus = 'SUSPENDED'
    AND c.UpdatedAt < DATEADD(DAY, -180, GETUTCDATE())
    AND c.IsDeleted = 0
    AND NOT EXISTS (
      SELECT 1 FROM sys.CleanupQueue q WHERE q.CompanyId = c.CompanyId
    );

  SET @NewCandidates = @NewCandidates + @@ROWCOUNT;

  -- Total PENDING tras el scan
  SELECT @TotalPending = COUNT(*)
  FROM sys.CleanupQueue
  WHERE Status = 'PENDING';

  SELECT @NewCandidates AS new_candidates, @TotalPending AS total_pending;
END;
GO

-- ─────────────────────────────────────────────────────────────────────────────
-- usp_Sys_Cleanup_List
-- Lista la cola de limpieza con información del tenant.
-- @Status NULL = todos los estados
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR ALTER PROCEDURE dbo.usp_Sys_Cleanup_List
  @Status NVARCHAR(20) = NULL
AS
BEGIN
  SET NOCOUNT ON;

  SELECT
    c.CompanyId,
    c.CompanyCode,
    c.LegalName,
    c.Plan,
    q.Reason,
    q.Status,
    q.FlaggedAt,
    q.DeleteAfter,
    rl.DbSizeMB,
    rl.LastLoginAt,
    CASE
      WHEN q.DeleteAfter IS NULL THEN NULL
      ELSE DATEDIFF(DAY, GETUTCDATE(), q.DeleteAfter)
    END AS DaysUntilDelete
  FROM sys.CleanupQueue q
  INNER JOIN cfg.Company c ON c.CompanyId = q.CompanyId
  OUTER APPLY (
    -- Último registro de recursos del tenant
    SELECT TOP 1 r.DbSizeMB, r.LastLoginAt
    FROM sys.TenantResourceLog r
    WHERE r.CompanyId = q.CompanyId
    ORDER BY r.RecordedAt DESC
  ) rl
  WHERE (@Status IS NULL OR q.Status = @Status)
  ORDER BY q.FlaggedAt DESC;
END;
GO

-- ─────────────────────────────────────────────────────────────────────────────
-- usp_Sys_Cleanup_Process
-- Procesa una entrada de la cola de limpieza.
-- @Action: 'CANCEL' | 'NOTIFY' | 'ARCHIVE' | 'CONFIRM_DELETE'
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR ALTER PROCEDURE dbo.usp_Sys_Cleanup_Process
  @QueueId BIGINT,
  @Action  NVARCHAR(20)
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE
    @CurrentStatus NVARCHAR(20),
    @CompanyId     BIGINT;

  -- Obtener registro actual
  SELECT @CurrentStatus = q.Status, @CompanyId = q.CompanyId
  FROM sys.CleanupQueue q
  WHERE q.QueueId = @QueueId;

  IF @CompanyId IS NULL
  BEGIN
    SELECT 0 AS ok, 'QUEUE_NOT_FOUND' AS mensaje;
    RETURN;
  END;

  IF @Action = 'CANCEL'
  BEGIN
    IF @CurrentStatus = 'DELETED'
    BEGIN
      SELECT 0 AS ok, 'CANNOT_CANCEL_DELETED' AS mensaje;
      RETURN;
    END;
    UPDATE sys.CleanupQueue
    SET Status = 'CANCELLED', ProcessedAt = GETUTCDATE()
    WHERE QueueId = @QueueId;
    SELECT 1 AS ok, 'CANCELLED' AS mensaje;
    RETURN;
  END;

  IF @Action = 'NOTIFY'
  BEGIN
    IF @CurrentStatus NOT IN ('PENDING')
    BEGIN
      SELECT 0 AS ok, CONCAT('INVALID_STATUS_FOR_NOTIFY:', @CurrentStatus) AS mensaje;
      RETURN;
    END;
    UPDATE sys.CleanupQueue
    SET Status = 'NOTIFIED', NotifiedAt = GETUTCDATE()
    WHERE QueueId = @QueueId;
    SELECT 1 AS ok, 'NOTIFIED' AS mensaje;
    RETURN;
  END;

  IF @Action = 'ARCHIVE'
  BEGIN
    IF @CurrentStatus NOT IN ('PENDING', 'NOTIFIED')
    BEGIN
      SELECT 0 AS ok, CONCAT('INVALID_STATUS_FOR_ARCHIVE:', @CurrentStatus) AS mensaje;
      RETURN;
    END;
    UPDATE sys.CleanupQueue
    SET Status = 'ARCHIVED', ProcessedAt = GETUTCDATE()
    WHERE QueueId = @QueueId;
    SELECT 1 AS ok, 'ARCHIVED' AS mensaje;
    RETURN;
  END;

  IF @Action = 'CONFIRM_DELETE'
  BEGIN
    IF @CurrentStatus NOT IN ('PENDING', 'NOTIFIED', 'ARCHIVED')
    BEGIN
      SELECT 0 AS ok, CONCAT('INVALID_STATUS_FOR_DELETE:', @CurrentStatus) AS mensaje;
      RETURN;
    END;
    -- Solo marcar: el job Node.js hace el DROP DATABASE real
    UPDATE sys.CleanupQueue
    SET Status = 'DELETED', ProcessedAt = GETUTCDATE()
    WHERE QueueId = @QueueId;

    -- Marcar empresa como inactiva y eliminada
    UPDATE cfg.Company
    SET IsActive      = 0,
        IsDeleted     = 1,
        DeletedAt     = GETUTCDATE(),
        TenantStatus  = 'CANCELLED'
    WHERE CompanyId = @CompanyId;

    SELECT 1 AS ok, 'CONFIRM_DELETE_OK' AS mensaje;
    RETURN;
  END;

  -- Acción desconocida
  SELECT 0 AS ok, CONCAT('UNKNOWN_ACTION:', ISNULL(@Action, 'NULL')) AS mensaje;
END;
GO
