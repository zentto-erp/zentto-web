/*
 * ============================================================================
 *  Archivo : usp_audit.sql
 *  Esquema : audit (auditoria y registros fiscales)
 *  Base    : DatqBoxWeb
 *  Fecha   : 2026-03-14
 *
 *  Descripcion:
 *    Procedimientos almacenados de auditoria: insercion de logs, consultas
 *    paginadas, detalle individual, dashboard de resumen y listado de
 *    registros fiscales.
 *    - usp_Audit_Log_Insert           : Inserta un registro de auditoria.
 *    - usp_Audit_Log_List             : Lista paginada con filtros opcionales.
 *    - usp_Audit_Log_GetById          : Detalle completo de un registro.
 *    - usp_Audit_Dashboard_Resumen    : Dashboard con totales, top modulos y
 *                                       ultimos logs.
 *    - usp_Audit_FiscalRecord_List    : Lista paginada de registros fiscales.
 *
 *  Compatibilidad:
 *    SQL Server 2012+. No se usan funciones de SQL 2016+ (JSON_VALUE,
 *    OPENJSON, STRING_AGG, CREATE OR ALTER, etc.).
 *
 *  Patron  : IF EXISTS DROP + CREATE PROCEDURE (SQL Server 2012)
 * ============================================================================
 */

USE DatqBoxWeb;
GO

-- ============================================================================
--  Schema: audit
-- ============================================================================
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'audit')
    EXEC('CREATE SCHEMA audit');
GO

-- ============================================================================
--  Tabla: audit.AuditLog
-- ============================================================================
IF OBJECT_ID('audit.AuditLog', 'U') IS NULL
BEGIN
    CREATE TABLE audit.AuditLog (
        AuditLogId    BIGINT IDENTITY(1,1) PRIMARY KEY,
        CompanyId     INT NOT NULL,
        BranchId      INT NOT NULL,
        UserId        INT NULL,
        UserName      NVARCHAR(100) NULL,
        ModuleName    NVARCHAR(50) NOT NULL,
        EntityName    NVARCHAR(100) NOT NULL,
        EntityId      NVARCHAR(50) NULL,
        ActionType    VARCHAR(10) NOT NULL,       -- CREATE, UPDATE, DELETE, VOID, LOGIN
        Summary       NVARCHAR(500) NULL,
        OldValues     NVARCHAR(MAX) NULL,
        NewValues     NVARCHAR(MAX) NULL,
        IpAddress     NVARCHAR(50) NULL,
        CreatedAt     DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME()
    );

    CREATE NONCLUSTERED INDEX IX_AuditLog_Company_Date
        ON audit.AuditLog(CompanyId, BranchId, CreatedAt DESC);

    CREATE NONCLUSTERED INDEX IX_AuditLog_Module
        ON audit.AuditLog(ModuleName, CreatedAt DESC);

    CREATE NONCLUSTERED INDEX IX_AuditLog_User
        ON audit.AuditLog(UserName, CreatedAt DESC);
END;
GO

-- =============================================================================
--  SP 1: usp_Audit_Log_Insert
--  Descripcion : Inserta un registro en audit.AuditLog y retorna el
--                AuditLogId generado via SCOPE_IDENTITY().
--  Parametros  :
--    @CompanyId    INT              - ID de empresa (requerido).
--    @BranchId     INT              - ID de sucursal (requerido).
--    @UserId       INT              - ID de usuario (opcional).
--    @UserName     NVARCHAR(100)    - Nombre de usuario (opcional).
--    @ModuleName   NVARCHAR(50)     - Modulo origen (requerido).
--    @EntityName   NVARCHAR(100)    - Entidad afectada (requerido).
--    @EntityId     NVARCHAR(50)     - ID de la entidad (opcional).
--    @ActionType   VARCHAR(10)      - Tipo de accion (requerido).
--    @Summary      NVARCHAR(500)    - Resumen legible (opcional).
--    @OldValues    NVARCHAR(MAX)    - Valores anteriores (opcional).
--    @NewValues    NVARCHAR(MAX)    - Valores nuevos (opcional).
--    @IpAddress    NVARCHAR(50)     - Direccion IP (opcional).
-- =============================================================================
IF OBJECT_ID('dbo.usp_Audit_Log_Insert', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_Audit_Log_Insert;
GO
CREATE PROCEDURE dbo.usp_Audit_Log_Insert
    @CompanyId    INT,
    @BranchId     INT,
    @UserId       INT            = NULL,
    @UserName     NVARCHAR(100)  = NULL,
    @ModuleName   NVARCHAR(50),
    @EntityName   NVARCHAR(100),
    @EntityId     NVARCHAR(50)   = NULL,
    @ActionType   VARCHAR(10),
    @Summary      NVARCHAR(500)  = NULL,
    @OldValues    NVARCHAR(MAX)  = NULL,
    @NewValues    NVARCHAR(MAX)  = NULL,
    @IpAddress    NVARCHAR(50)   = NULL
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO audit.AuditLog (
        CompanyId, BranchId, UserId, UserName,
        ModuleName, EntityName, EntityId, ActionType,
        Summary, OldValues, NewValues, IpAddress
    )
    VALUES (
        @CompanyId, @BranchId, @UserId, @UserName,
        @ModuleName, @EntityName, @EntityId, @ActionType,
        @Summary, @OldValues, @NewValues, @IpAddress
    );

    SELECT CAST(SCOPE_IDENTITY() AS BIGINT) AS AuditLogId;
END;
GO

-- =============================================================================
--  SP 2: usp_Audit_Log_List
--  Descripcion : Retorna lista paginada de registros de auditoria con filtros
--                opcionales. Devuelve 2 recordsets: total count y registros.
--  Parametros  :
--    @CompanyId    INT              - ID de empresa (requerido).
--    @BranchId     INT              - ID de sucursal (requerido).
--    @FechaDesde   DATE             - Fecha inicio del rango (opcional).
--    @FechaHasta   DATE             - Fecha fin del rango (opcional).
--    @ModuleName   NVARCHAR(50)     - Filtro por modulo (opcional).
--    @UserName     NVARCHAR(100)    - Filtro por usuario (opcional).
--    @ActionType   VARCHAR(10)      - Filtro por tipo de accion (opcional).
--    @EntityName   NVARCHAR(100)    - Filtro por entidad (opcional).
--    @Search       NVARCHAR(200)    - Busqueda en Summary (opcional).
--    @Page         INT              - Numero de pagina (default 1).
--    @Limit        INT              - Registros por pagina (default 50).
-- =============================================================================
IF OBJECT_ID('dbo.usp_Audit_Log_List', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_Audit_Log_List;
GO
CREATE PROCEDURE dbo.usp_Audit_Log_List
    @CompanyId    INT,
    @BranchId     INT,
    @FechaDesde   DATE           = NULL,
    @FechaHasta   DATE           = NULL,
    @ModuleName   NVARCHAR(50)   = NULL,
    @UserName     NVARCHAR(100)  = NULL,
    @ActionType   VARCHAR(10)    = NULL,
    @EntityName   NVARCHAR(100)  = NULL,
    @Search       NVARCHAR(200)  = NULL,
    @Page         INT            = 1,
    @Limit        INT            = 50
AS
BEGIN
    SET NOCOUNT ON;

    -- Validar paginacion
    IF @Page < 1 SET @Page = 1;
    IF @Limit < 1 SET @Limit = 50;
    IF @Limit > 500 SET @Limit = 500;

    DECLARE @Offset INT = (@Page - 1) * @Limit;

    -- Recordset 1: Total count
    SELECT COUNT(*) AS TotalCount
    FROM   audit.AuditLog
    WHERE  CompanyId = @CompanyId
      AND  BranchId  = @BranchId
      AND  (@FechaDesde IS NULL OR CAST(CreatedAt AS DATE) >= @FechaDesde)
      AND  (@FechaHasta IS NULL OR CAST(CreatedAt AS DATE) <= @FechaHasta)
      AND  (@ModuleName IS NULL OR ModuleName = @ModuleName)
      AND  (@UserName   IS NULL OR UserName   = @UserName)
      AND  (@ActionType IS NULL OR ActionType = @ActionType)
      AND  (@EntityName IS NULL OR EntityName = @EntityName)
      AND  (@Search     IS NULL OR Summary LIKE '%' + @Search + '%');

    -- Recordset 2: Registros paginados
    SELECT AuditLogId,
           CompanyId,
           BranchId,
           UserId,
           UserName,
           ModuleName,
           EntityName,
           EntityId,
           ActionType,
           Summary,
           IpAddress,
           CreatedAt
    FROM   audit.AuditLog
    WHERE  CompanyId = @CompanyId
      AND  BranchId  = @BranchId
      AND  (@FechaDesde IS NULL OR CAST(CreatedAt AS DATE) >= @FechaDesde)
      AND  (@FechaHasta IS NULL OR CAST(CreatedAt AS DATE) <= @FechaHasta)
      AND  (@ModuleName IS NULL OR ModuleName = @ModuleName)
      AND  (@UserName   IS NULL OR UserName   = @UserName)
      AND  (@ActionType IS NULL OR ActionType = @ActionType)
      AND  (@EntityName IS NULL OR EntityName = @EntityName)
      AND  (@Search     IS NULL OR Summary LIKE '%' + @Search + '%')
    ORDER BY CreatedAt DESC
    OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;
END;
GO

-- =============================================================================
--  SP 3: usp_Audit_Log_GetById
--  Descripcion : Retorna el registro completo de auditoria incluyendo
--                OldValues y NewValues.
--  Parametros  :
--    @AuditLogId  BIGINT  - ID del registro de auditoria.
-- =============================================================================
IF OBJECT_ID('dbo.usp_Audit_Log_GetById', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_Audit_Log_GetById;
GO
CREATE PROCEDURE dbo.usp_Audit_Log_GetById
    @AuditLogId  BIGINT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT AuditLogId,
           CompanyId,
           BranchId,
           UserId,
           UserName,
           ModuleName,
           EntityName,
           EntityId,
           ActionType,
           Summary,
           OldValues,
           NewValues,
           IpAddress,
           CreatedAt
    FROM   audit.AuditLog
    WHERE  AuditLogId = @AuditLogId;
END;
GO

-- =============================================================================
--  SP 4: usp_Audit_Dashboard_Resumen
--  Descripcion : Dashboard de auditoria. Retorna 3 recordsets:
--                1. Totales generales (total, por tipo de accion, ultimas 24h).
--                2. TOP 10 modulos con mayor actividad en el rango.
--                3. Ultimos 10 registros de auditoria.
--  Parametros  :
--    @CompanyId    INT   - ID de empresa (requerido).
--    @BranchId     INT   - ID de sucursal (requerido).
--    @FechaDesde   DATE  - Fecha inicio del rango (requerido).
--    @FechaHasta   DATE  - Fecha fin del rango (requerido).
-- =============================================================================
IF OBJECT_ID('dbo.usp_Audit_Dashboard_Resumen', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_Audit_Dashboard_Resumen;
GO
CREATE PROCEDURE dbo.usp_Audit_Dashboard_Resumen
    @CompanyId    INT,
    @BranchId     INT,
    @FechaDesde   DATE,
    @FechaHasta   DATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Recordset 1: Totales generales
    SELECT
        COUNT(*)                                                           AS totalLogs,
        SUM(CASE WHEN ActionType = 'CREATE' THEN 1 ELSE 0 END)            AS totalCreates,
        SUM(CASE WHEN ActionType = 'UPDATE' THEN 1 ELSE 0 END)            AS totalUpdates,
        SUM(CASE WHEN ActionType = 'DELETE' THEN 1 ELSE 0 END)            AS totalDeletes,
        SUM(CASE WHEN ActionType = 'VOID'   THEN 1 ELSE 0 END)            AS totalVoids,
        SUM(CASE WHEN ActionType = 'LOGIN'  THEN 1 ELSE 0 END)            AS totalLogins,
        SUM(CASE WHEN CreatedAt >= DATEADD(HOUR, -24, SYSUTCDATETIME())
                 THEN 1 ELSE 0 END)                                        AS logsUltimas24h
    FROM   audit.AuditLog
    WHERE  CompanyId = @CompanyId
      AND  BranchId  = @BranchId
      AND  CAST(CreatedAt AS DATE) >= @FechaDesde
      AND  CAST(CreatedAt AS DATE) <= @FechaHasta;

    -- Recordset 2: TOP 10 modulos con mayor actividad
    SELECT TOP 10
           ModuleName,
           COUNT(*) AS Total
    FROM   audit.AuditLog
    WHERE  CompanyId = @CompanyId
      AND  BranchId  = @BranchId
      AND  CAST(CreatedAt AS DATE) >= @FechaDesde
      AND  CAST(CreatedAt AS DATE) <= @FechaHasta
    GROUP BY ModuleName
    ORDER BY Total DESC;

    -- Recordset 3: Ultimos 10 registros de auditoria
    SELECT TOP 10
           AuditLogId,
           CreatedAt,
           UserName,
           ModuleName,
           ActionType,
           EntityName,
           Summary
    FROM   audit.AuditLog
    WHERE  CompanyId = @CompanyId
      AND  BranchId  = @BranchId
      AND  CAST(CreatedAt AS DATE) >= @FechaDesde
      AND  CAST(CreatedAt AS DATE) <= @FechaHasta
    ORDER BY CreatedAt DESC;
END;
GO

-- =============================================================================
--  SP 5: usp_Audit_FiscalRecord_List
--  Descripcion : Lista paginada de registros fiscales desde fiscal.Record.
--                Si la tabla fiscal.Record no existe, retorna conjuntos vacios
--                para mantener compatibilidad con el frontend.
--  Parametros  :
--    @CompanyId    INT   - ID de empresa (requerido).
--    @BranchId     INT   - ID de sucursal (requerido).
--    @FechaDesde   DATE  - Fecha inicio del rango (opcional).
--    @FechaHasta   DATE  - Fecha fin del rango (opcional).
--    @Page         INT   - Numero de pagina (default 1).
--    @Limit        INT   - Registros por pagina (default 50).
-- =============================================================================
IF OBJECT_ID('dbo.usp_Audit_FiscalRecord_List', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_Audit_FiscalRecord_List;
GO
CREATE PROCEDURE dbo.usp_Audit_FiscalRecord_List
    @CompanyId    INT,
    @BranchId     INT,
    @FechaDesde   DATE  = NULL,
    @FechaHasta   DATE  = NULL,
    @Page         INT   = 1,
    @Limit        INT   = 50
AS
BEGIN
    SET NOCOUNT ON;

    -- Validar paginacion
    IF @Page < 1 SET @Page = 1;
    IF @Limit < 1 SET @Limit = 50;
    IF @Limit > 500 SET @Limit = 500;

    DECLARE @Offset INT = (@Page - 1) * @Limit;

    -- Verificar si existe la tabla fiscal.Record
    IF OBJECT_ID('fiscal.Record', 'U') IS NOT NULL
    BEGIN
        DECLARE @sql   NVARCHAR(MAX);
        DECLARE @where NVARCHAR(500);
        DECLARE @params NVARCHAR(500);

        SET @params = N'@pCompanyId INT, @pBranchId INT, @pFechaDesde DATE, @pFechaHasta DATE, @pOffset INT, @pLimit INT';

        SET @where = N' WHERE CompanyId = @pCompanyId AND BranchId = @pBranchId';
        IF @FechaDesde IS NOT NULL
            SET @where = @where + N' AND CAST(CreatedAt AS DATE) >= @pFechaDesde';
        IF @FechaHasta IS NOT NULL
            SET @where = @where + N' AND CAST(CreatedAt AS DATE) <= @pFechaHasta';

        -- Recordset 1: Total count
        SET @sql = N'SELECT COUNT(*) AS TotalCount FROM fiscal.Record' + @where;
        EXEC sp_executesql @sql, @params,
            @pCompanyId = @CompanyId, @pBranchId = @BranchId,
            @pFechaDesde = @FechaDesde, @pFechaHasta = @FechaHasta,
            @pOffset = @Offset, @pLimit = @Limit;

        -- Recordset 2: Registros paginados
        SET @sql = N'SELECT FiscalRecordId, InvoiceId, InvoiceNumber, InvoiceDate,
                            InvoiceType, RecordHash, SentToAuthority, AuthorityStatus,
                            CountryCode, CreatedAt
                     FROM   fiscal.Record' + @where +
                   N' ORDER BY CreatedAt DESC
                     OFFSET @pOffset ROWS FETCH NEXT @pLimit ROWS ONLY';
        EXEC sp_executesql @sql, @params,
            @pCompanyId = @CompanyId, @pBranchId = @BranchId,
            @pFechaDesde = @FechaDesde, @pFechaHasta = @FechaHasta,
            @pOffset = @Offset, @pLimit = @Limit;
    END
    ELSE
    BEGIN
        -- La tabla fiscal.Record no existe: retornar conjuntos vacios
        SELECT 0 AS TotalCount;

        SELECT CAST(NULL AS INT)          AS FiscalRecordId,
               CAST(NULL AS INT)          AS InvoiceId,
               CAST(NULL AS NVARCHAR(50)) AS InvoiceNumber,
               CAST(NULL AS DATE)         AS InvoiceDate,
               CAST(NULL AS NVARCHAR(20)) AS InvoiceType,
               CAST(NULL AS NVARCHAR(64)) AS RecordHash,
               CAST(NULL AS BIT)          AS SentToAuthority,
               CAST(NULL AS NVARCHAR(50)) AS AuthorityStatus,
               CAST(NULL AS VARCHAR(3))   AS CountryCode,
               CAST(NULL AS DATETIME2(0)) AS CreatedAt
        WHERE  1 = 0;
    END;
END;
GO
