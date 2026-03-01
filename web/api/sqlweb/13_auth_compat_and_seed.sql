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

  DECLARE @SupPasswordHash NVARCHAR(255) = N'$2b$12$BhkamabgAeGlVHbgIhRlFub7yRhkbw6YNDrZWH6MHZe60EKHGGbmK';
  DECLARE @OperadorPasswordHash NVARCHAR(255) = N'$2b$12$zWPJUWpTGmnoHWNEkIPx7u606qRsEE1WUy9/sJnvfoQD5QkDR7BVi';

  IF OBJECT_ID(N'dbo.AccesoUsuarios', N'U') IS NULL
  BEGIN
    CREATE TABLE dbo.AccesoUsuarios (
      Cod_Usuario NVARCHAR(20) NOT NULL,
      Modulo NVARCHAR(60) NOT NULL,
      Permitido BIT NOT NULL CONSTRAINT DF_AccesoUsuarios_Permitido DEFAULT (1),
      CreatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_AccesoUsuarios_CreatedAt DEFAULT SYSUTCDATETIME(),
      UpdatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_AccesoUsuarios_UpdatedAt DEFAULT SYSUTCDATETIME(),
      CONSTRAINT PK_AccesoUsuarios PRIMARY KEY (Cod_Usuario, Modulo)
    );
  END;

  IF EXISTS (
    SELECT 1
    FROM sys.columns
    WHERE object_id = OBJECT_ID(N'dbo.Usuarios')
      AND name = N'Password'
      AND max_length < 200
  )
  BEGIN
    ALTER TABLE dbo.Usuarios ALTER COLUMN [Password] NVARCHAR(255) NULL;
  END;

  IF NOT EXISTS (SELECT 1 FROM dbo.Usuarios WHERE Cod_Usuario = N'SUP')
  BEGIN
    INSERT INTO dbo.Usuarios (
      Cod_Usuario, [Password], Nombre, Tipo,
      Updates, Addnews, Deletes, Creador, Cambiar, PrecioMinimo, Credito, IsAdmin
    )
    VALUES (
      N'SUP', @SupPasswordHash, N'Super Administrador', N'ADMIN',
      1, 1, 1, 1, 1, 1, 1, 1
    );
  END
  ELSE
  BEGIN
    UPDATE dbo.Usuarios
    SET [Password] = @SupPasswordHash,
        Nombre = N'Super Administrador',
        Tipo = N'ADMIN',
        Updates = 1,
        Addnews = 1,
        Deletes = 1,
        Creador = 1,
        Cambiar = 1,
        PrecioMinimo = 1,
        Credito = 1,
        IsAdmin = 1
    WHERE Cod_Usuario = N'SUP';
  END;

  IF NOT EXISTS (SELECT 1 FROM dbo.Usuarios WHERE Cod_Usuario = N'OPERADOR')
  BEGIN
    INSERT INTO dbo.Usuarios (
      Cod_Usuario, [Password], Nombre, Tipo,
      Updates, Addnews, Deletes, Creador, Cambiar, PrecioMinimo, Credito, IsAdmin
    )
    VALUES (
      N'OPERADOR', @OperadorPasswordHash, N'Operador Restaurante', N'USER',
      1, 1, 0, 0, 1, 0, 0, 0
    );
  END;
  ELSE
  BEGIN
    UPDATE dbo.Usuarios
    SET [Password] = @OperadorPasswordHash,
        Nombre = N'Operador Restaurante',
        Tipo = N'USER',
        Updates = 1,
        Addnews = 1,
        Deletes = 0,
        Creador = 0,
        Cambiar = 1,
        PrecioMinimo = 0,
        Credito = 0,
        IsAdmin = 0
    WHERE Cod_Usuario = N'OPERADOR';
  END;

  IF OBJECT_ID(N'sec.[User]', N'U') IS NOT NULL
  BEGIN
    IF NOT EXISTS (SELECT 1 FROM sec.[User] WHERE UserCode = N'SUP' AND IsDeleted = 0)
    BEGIN
      DECLARE @SystemUserId INT = (
        SELECT TOP 1 UserId FROM sec.[User] WHERE UserCode = N'SYSTEM' ORDER BY UserId
      );

      INSERT INTO sec.[User] (
        UserCode,
        UserName,
        Email,
        IsAdmin,
        IsActive,
        CreatedByUserId,
        UpdatedByUserId
      )
      VALUES (
        N'SUP',
        N'Super Administrador',
        N'sup@datqbox.local',
        1,
        1,
        @SystemUserId,
        @SystemUserId
      );
    END;
  END;

  IF NOT EXISTS (SELECT 1 FROM dbo.AccesoUsuarios WHERE Cod_Usuario = N'OPERADOR')
  BEGIN
    INSERT INTO dbo.AccesoUsuarios (Cod_Usuario, Modulo, Permitido)
    VALUES
      (N'OPERADOR', N'dashboard', 1),
      (N'OPERADOR', N'facturas', 1),
      (N'OPERADOR', N'clientes', 1),
      (N'OPERADOR', N'inventario', 1),
      (N'OPERADOR', N'articulos', 1),
      (N'OPERADOR', N'pagos', 1),
      (N'OPERADOR', N'abonos', 1),
      (N'OPERADOR', N'pos', 1),
      (N'OPERADOR', N'restaurante', 1),
      (N'OPERADOR', N'reportes', 1);
  END;

  COMMIT TRAN;
END TRY
BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRAN;
  THROW;
END CATCH;
GO
