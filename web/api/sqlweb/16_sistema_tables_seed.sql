SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

USE DatqBoxWeb;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

BEGIN TRY
  BEGIN TRAN;

  IF OBJECT_ID(N'dbo.Sys_Notificaciones', N'U') IS NULL
  BEGIN
    CREATE TABLE dbo.Sys_Notificaciones (
      Id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      UsuarioId NVARCHAR(50) NULL,
      Tipo NVARCHAR(30) NOT NULL CONSTRAINT DF_Sys_Notificaciones_Tipo DEFAULT (N'info'),
      Titulo NVARCHAR(150) NOT NULL,
      Mensaje NVARCHAR(500) NOT NULL,
      RutaNavegacion NVARCHAR(200) NULL,
      Leido BIT NOT NULL CONSTRAINT DF_Sys_Notificaciones_Leido DEFAULT (0),
      FechaCreacion DATETIME2(0) NOT NULL CONSTRAINT DF_Sys_Notificaciones_Fecha DEFAULT SYSUTCDATETIME()
    );

    CREATE INDEX IX_Sys_Notificaciones_UsuarioLeidoFecha
      ON dbo.Sys_Notificaciones (UsuarioId, Leido, FechaCreacion DESC);
  END;

  IF OBJECT_ID(N'dbo.Sys_Tareas', N'U') IS NULL
  BEGIN
    CREATE TABLE dbo.Sys_Tareas (
      Id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      Titulo NVARCHAR(150) NOT NULL,
      Descripcion NVARCHAR(500) NULL,
      Progreso INT NOT NULL CONSTRAINT DF_Sys_Tareas_Progreso DEFAULT (0),
      Color NVARCHAR(20) NOT NULL CONSTRAINT DF_Sys_Tareas_Color DEFAULT (N'primary'),
      AsignadoA NVARCHAR(50) NULL,
      FechaVencimiento DATETIME2(0) NULL,
      Completado BIT NOT NULL CONSTRAINT DF_Sys_Tareas_Completado DEFAULT (0),
      FechaCreacion DATETIME2(0) NOT NULL CONSTRAINT DF_Sys_Tareas_Fecha DEFAULT SYSUTCDATETIME()
    );

    CREATE INDEX IX_Sys_Tareas_AsignadoCompletadoFecha
      ON dbo.Sys_Tareas (AsignadoA, Completado, FechaCreacion DESC);
  END;

  IF OBJECT_ID(N'dbo.Sys_Mensajes', N'U') IS NULL
  BEGIN
    CREATE TABLE dbo.Sys_Mensajes (
      Id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      DestinatarioId NVARCHAR(50) NOT NULL,
      RemitenteId NVARCHAR(50) NULL,
      RemitenteNombre NVARCHAR(120) NULL,
      Asunto NVARCHAR(150) NOT NULL,
      Cuerpo NVARCHAR(MAX) NOT NULL,
      Leido BIT NOT NULL CONSTRAINT DF_Sys_Mensajes_Leido DEFAULT (0),
      FechaEnvio DATETIME2(0) NOT NULL CONSTRAINT DF_Sys_Mensajes_Fecha DEFAULT SYSUTCDATETIME()
    );

    CREATE INDEX IX_Sys_Mensajes_DestinatarioLeidoFecha
      ON dbo.Sys_Mensajes (DestinatarioId, Leido, FechaEnvio DESC);
  END;

  IF NOT EXISTS (SELECT 1 FROM dbo.Sys_Notificaciones)
  BEGIN
    INSERT INTO dbo.Sys_Notificaciones (UsuarioId, Tipo, Titulo, Mensaje, RutaNavegacion, Leido)
    VALUES
      (NULL, N'info', N'Sistema inicializado', N'El modulo de sistema fue configurado correctamente.', N'/dashboard', 0),
      (N'SUP', N'success', N'Acceso administrador', N'Bienvenido al panel administrativo.', N'/dashboard', 0);
  END;

  IF NOT EXISTS (SELECT 1 FROM dbo.Sys_Tareas)
  BEGIN
    INSERT INTO dbo.Sys_Tareas (Titulo, Descripcion, Progreso, Color, AsignadoA, FechaVencimiento, Completado)
    VALUES
      (N'Revisar apertura de caja', N'Validar montos iniciales de caja principal.', 25, N'warning', NULL, DATEADD(DAY, 1, SYSUTCDATETIME()), 0),
      (N'Validar configuracion fiscal', N'Confirmar datos fiscales activos para la empresa.', 60, N'info', N'SUP', DATEADD(DAY, 2, SYSUTCDATETIME()), 0);
  END;

  IF NOT EXISTS (SELECT 1 FROM dbo.Sys_Mensajes)
  BEGIN
    INSERT INTO dbo.Sys_Mensajes (DestinatarioId, RemitenteId, RemitenteNombre, Asunto, Cuerpo, Leido)
    VALUES
      (N'admin', N'SYSTEM', N'Sistema', N'Bienvenido', N'Tu buzon de mensajes esta activo.', 0),
      (N'SUP', N'SYSTEM', N'Sistema', N'Acceso habilitado', N'La cuenta SUP esta operativa.', 0);
  END;

  COMMIT TRAN;
END TRY
BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRAN;
  THROW;
END CATCH;
GO

