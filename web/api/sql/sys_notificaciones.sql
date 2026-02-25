-- Tablas para notificaciones, tareas y mensajes
-- Compatible con SQL Server

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Sys_Notificaciones]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[Sys_Notificaciones] (
        [Id] INT IDENTITY(1,1) PRIMARY KEY,
        [Tipo] NVARCHAR(20) NOT NULL, -- info, success, warning, error
        [Titulo] NVARCHAR(100) NOT NULL,
        [Mensaje] NVARCHAR(500) NOT NULL,
        [Leido] BIT NOT NULL DEFAULT 0,
        [UsuarioId] NVARCHAR(20) NULL, -- Si es null es global
        [FechaCreacion] DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        [RutaNavegacion] NVARCHAR(200) NULL
    );
END
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Sys_Tareas]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[Sys_Tareas] (
        [Id] INT IDENTITY(1,1) PRIMARY KEY,
        [Titulo] NVARCHAR(100) NOT NULL,
        [Descripcion] NVARCHAR(500) NULL,
        [Progreso] INT NOT NULL DEFAULT 0, -- 0 al 100
        [Color] NVARCHAR(20) NOT NULL DEFAULT 'primary', -- primary, secondary, error, info, success, warning
        [AsignadoA] NVARCHAR(20) NULL,
        [FechaVencimiento] DATETIME NULL,
        [Completado] BIT NOT NULL DEFAULT 0,
        [FechaCreacion] DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
    );
END
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Sys_Mensajes]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[Sys_Mensajes] (
        [Id] INT IDENTITY(1,1) PRIMARY KEY,
        [RemitenteId] NVARCHAR(20) NOT NULL,
        [RemitenteNombre] NVARCHAR(100) NOT NULL,
        [DestinatarioId] NVARCHAR(20) NOT NULL,
        [Asunto] NVARCHAR(100) NOT NULL,
        [Cuerpo] NVARCHAR(MAX) NOT NULL,
        [Leido] BIT NOT NULL DEFAULT 0,
        [FechaEnvio] DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
    );
END
GO
