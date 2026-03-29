-- ============================================================
-- SPs para alertas automáticas y notificaciones del sistema
-- Compatible con SQL Server
-- ============================================================

-- Insertar notificación
IF OBJECT_ID('dbo.usp_Sys_Notificacion_Insert', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Sys_Notificacion_Insert;
GO
CREATE PROCEDURE dbo.usp_Sys_Notificacion_Insert
    @Tipo NVARCHAR(20),
    @Titulo NVARCHAR(100),
    @Mensaje NVARCHAR(500),
    @UsuarioId NVARCHAR(20) = NULL,
    @RutaNavegacion NVARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- Evitar duplicados recientes (misma alerta en últimas 4 horas)
    IF EXISTS (
        SELECT 1 FROM dbo.Sys_Notificaciones
        WHERE Titulo = @Titulo
          AND (UsuarioId = @UsuarioId OR (UsuarioId IS NULL AND @UsuarioId IS NULL))
          AND Leido = 0
          AND FechaCreacion > DATEADD(HOUR, -4, GETDATE())
    )
    BEGIN
        SELECT 0 AS Id, 'duplicado_reciente' AS Mensaje;
        RETURN;
    END

    INSERT INTO dbo.Sys_Notificaciones (Tipo, Titulo, Mensaje, UsuarioId, RutaNavegacion)
    VALUES (@Tipo, @Titulo, @Mensaje, @UsuarioId, @RutaNavegacion);

    SELECT SCOPE_IDENTITY() AS Id, 'ok' AS Mensaje;
END
GO

-- Alerta: Facturas vencidas (CxC)
IF OBJECT_ID('dbo.usp_Sys_Alert_FacturasVencidas', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Sys_Alert_FacturasVencidas;
GO
CREATE PROCEDURE dbo.usp_Sys_Alert_FacturasVencidas
AS
BEGIN
    SET NOCOUNT ON;

    IF OBJECT_ID('ar.ReceivableDocument', 'U') IS NOT NULL
    BEGIN
        SELECT
            COUNT(*) AS cantidad,
            ISNULL(SUM(PendingAmount), 0) AS montoTotal
        FROM ar.ReceivableDocument
        WHERE Status IN ('PENDING', 'PARTIAL')
          AND DueDate < GETDATE()
          AND IsVoided = 0;
    END
    ELSE
    BEGIN
        SELECT 0 AS cantidad, 0.00 AS montoTotal;
    END
END
GO

-- Alerta: Stock bajo
IF OBJECT_ID('dbo.usp_Sys_Alert_StockBajo', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Sys_Alert_StockBajo;
GO
CREATE PROCEDURE dbo.usp_Sys_Alert_StockBajo
AS
BEGIN
    SET NOCOUNT ON;

    IF OBJECT_ID('dbo.Articulos', 'U') IS NOT NULL
    BEGIN
        SELECT COUNT(*) AS cantidad
        FROM dbo.Articulos
        WHERE ISNULL(Existencia, 0) <= ISNULL(StockMinimo, 0)
          AND StockMinimo > 0
          AND ISNULL(Inactivo, 0) = 0;
    END
    ELSE
    BEGIN
        SELECT 0 AS cantidad;
    END
END
GO

-- Alerta: CxP por vencer (próximos 7 días)
IF OBJECT_ID('dbo.usp_Sys_Alert_CxpPorVencer', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Sys_Alert_CxpPorVencer;
GO
CREATE PROCEDURE dbo.usp_Sys_Alert_CxpPorVencer
AS
BEGIN
    SET NOCOUNT ON;

    IF OBJECT_ID('ap.PayableDocument', 'U') IS NOT NULL
    BEGIN
        SELECT
            COUNT(*) AS cantidad,
            ISNULL(SUM(PendingAmount), 0) AS montoTotal
        FROM ap.PayableDocument
        WHERE Status IN ('PENDING', 'PARTIAL')
          AND DueDate BETWEEN GETDATE() AND DATEADD(DAY, 7, GETDATE())
          AND IsVoided = 0;
    END
    ELSE
    BEGIN
        SELECT 0 AS cantidad, 0.00 AS montoTotal;
    END
END
GO

-- Alerta: Conciliación bancaria pendiente
IF OBJECT_ID('dbo.usp_Sys_Alert_ConciliacionPendiente', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Sys_Alert_ConciliacionPendiente;
GO
CREATE PROCEDURE dbo.usp_Sys_Alert_ConciliacionPendiente
AS
BEGIN
    SET NOCOUNT ON;

    IF OBJECT_ID('bank.BankAccount', 'U') IS NOT NULL
    BEGIN
        DECLARE @mes INT = MONTH(GETDATE()), @anio INT = YEAR(GETDATE());

        SELECT COUNT(*) AS cantidad
        FROM bank.BankAccount ba
        WHERE ba.IsActive = 1
          AND NOT EXISTS (
              SELECT 1 FROM bank.Reconciliation r
              WHERE r.BankAccountId = ba.BankAccountId
                AND MONTH(r.ClosedAt) = @mes AND YEAR(r.ClosedAt) = @anio
                AND r.Status = 'CERRADA'
          );
    END
    ELSE
    BEGIN
        SELECT 0 AS cantidad;
    END
END
GO

-- Alerta: Nómina sin procesar
IF OBJECT_ID('dbo.usp_Sys_Alert_NominaPendiente', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Sys_Alert_NominaPendiente;
GO
CREATE PROCEDURE dbo.usp_Sys_Alert_NominaPendiente
AS
BEGIN
    SET NOCOUNT ON;

    IF OBJECT_ID('hr.PayrollBatch', 'U') IS NOT NULL
    BEGIN
        DECLARE @mes INT = MONTH(GETDATE()), @anio INT = YEAR(GETDATE());

        SELECT CASE
            WHEN NOT EXISTS (
                SELECT 1 FROM hr.PayrollBatch
                WHERE MONTH(CreatedAt) = @mes AND YEAR(CreatedAt) = @anio
                  AND Status IN ('PROCESADA', 'APROBADA')
            ) THEN 1
            ELSE 0
        END AS pendiente;
    END
    ELSE
    BEGIN
        SELECT 0 AS pendiente;
    END
END
GO

-- Alerta: Asientos en borrador
IF OBJECT_ID('dbo.usp_Sys_Alert_AsientosBorrador', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Sys_Alert_AsientosBorrador;
GO
CREATE PROCEDURE dbo.usp_Sys_Alert_AsientosBorrador
AS
BEGIN
    SET NOCOUNT ON;

    IF OBJECT_ID('acct.JournalEntry', 'U') IS NOT NULL
    BEGIN
        SELECT COUNT(*) AS cantidad
        FROM acct.JournalEntry
        WHERE Status = 'DRAFT';
    END
    ELSE
    BEGIN
        SELECT 0 AS cantidad;
    END
END
GO

-- Alerta: Solicitudes de vacaciones pendientes
IF OBJECT_ID('dbo.usp_Sys_Alert_VacacionesPendientes', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Sys_Alert_VacacionesPendientes;
GO
CREATE PROCEDURE dbo.usp_Sys_Alert_VacacionesPendientes
AS
BEGIN
    SET NOCOUNT ON;

    IF OBJECT_ID('hr.VacationRequest', 'U') IS NOT NULL
    BEGIN
        SELECT COUNT(*) AS cantidad
        FROM hr.VacationRequest
        WHERE Status = 'SOLICITADA';
    END
    ELSE
    BEGIN
        SELECT 0 AS cantidad;
    END
END
GO

-- Insertar tarea (con deduplicación: no crear si ya existe tarea con mismo título no completada)
IF OBJECT_ID('dbo.usp_Sys_Tarea_Insert', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Sys_Tarea_Insert;
GO
CREATE PROCEDURE dbo.usp_Sys_Tarea_Insert
    @Titulo NVARCHAR(200),
    @Descripcion NVARCHAR(500) = NULL,
    @Color NVARCHAR(30) = 'blue',
    @AsignadoA NVARCHAR(50) = NULL,
    @FechaVencimiento DATETIME = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- Deduplicación: no crear si ya existe tarea con mismo título no completada
    IF EXISTS (
        SELECT 1 FROM dbo.Sys_Tareas
        WHERE Titulo = @Titulo
          AND Completado = 0
    )
    BEGIN
        SELECT 0 AS Id, 'duplicado_tarea_activa' AS Mensaje;
        RETURN;
    END

    INSERT INTO dbo.Sys_Tareas (Titulo, Descripcion, Color, AsignadoA, FechaVencimiento)
    VALUES (@Titulo, @Descripcion, @Color, @AsignadoA, @FechaVencimiento);

    SELECT SCOPE_IDENTITY() AS Id, 'ok' AS Mensaje;
END
GO
