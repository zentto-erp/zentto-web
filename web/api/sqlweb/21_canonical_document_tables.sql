-- =============================================================================
-- 21_canonical_document_tables.sql
-- Las tablas doc.SalesDocument, doc.PurchaseDocument, etc. se crean en
-- create_documentos_unificado.sql (incluido desde script 10).
--
-- Este script:
--   1. Limpia tablas dbo.Documentos* legacy si existen (reemplazadas por doc.*)
--   2. Crea sec.UserModuleAccess + vista dbo.AccesoUsuarios
-- =============================================================================
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

USE DatqBoxWeb;
GO

PRINT '[21] Inicio: limpieza legacy + sec.UserModuleAccess...';
GO

-- =============================================================================
-- SECCIÓN 1: LIMPIEZA DE TABLAS dbo.Documentos* LEGACY
-- Si existen como tablas físicas, se eliminan (reemplazadas por doc.*)
-- =============================================================================

-- Eliminar FKs primero (pueden existir de versiones anteriores)
IF OBJECT_ID(N'FK_DocVentaDet_DocVenta')   IS NOT NULL ALTER TABLE dbo.DocumentosVentaDetalle  DROP CONSTRAINT FK_DocVentaDet_DocVenta;
IF OBJECT_ID(N'FK_DocVentaPago_DocVenta')  IS NOT NULL ALTER TABLE dbo.DocumentosVentaPago     DROP CONSTRAINT FK_DocVentaPago_DocVenta;
IF OBJECT_ID(N'FK_DocCompraDet_DocCompra') IS NOT NULL ALTER TABLE dbo.DocumentosCompraDetalle DROP CONSTRAINT FK_DocCompraDet_DocCompra;
IF OBJECT_ID(N'FK_DocCompraPago_DocCompra')IS NOT NULL ALTER TABLE dbo.DocumentosCompraPago    DROP CONSTRAINT FK_DocCompraPago_DocCompra;
GO

-- Solo eliminar si son TABLAS (N'U'); si fueran vistas (N'V') no tocar
IF OBJECT_ID(N'dbo.DocumentosVentaDetalle', N'U') IS NOT NULL DROP TABLE dbo.DocumentosVentaDetalle;
IF OBJECT_ID(N'dbo.DocumentosVentaPago',    N'U') IS NOT NULL DROP TABLE dbo.DocumentosVentaPago;
IF OBJECT_ID(N'dbo.DocumentosVenta',        N'U') IS NOT NULL DROP TABLE dbo.DocumentosVenta;
IF OBJECT_ID(N'dbo.DocumentosCompraDetalle',N'U') IS NOT NULL DROP TABLE dbo.DocumentosCompraDetalle;
IF OBJECT_ID(N'dbo.DocumentosCompraPago',   N'U') IS NOT NULL DROP TABLE dbo.DocumentosCompraPago;
IF OBJECT_ID(N'dbo.DocumentosCompra',       N'U') IS NOT NULL DROP TABLE dbo.DocumentosCompra;
GO

-- =============================================================================
-- SECCIÓN 2: sec.UserModuleAccess (permisos de módulos)
-- =============================================================================

IF OBJECT_ID(N'sec.UserModuleAccess', N'U') IS NULL
BEGIN
  CREATE TABLE sec.UserModuleAccess (
    AccessId    INT           IDENTITY(1,1) NOT NULL,
    UserCode    NVARCHAR(20)  NOT NULL,
    ModuleCode  NVARCHAR(60)  NOT NULL,
    IsAllowed   BIT           NOT NULL CONSTRAINT DF_UserModuleAccess_IsAllowed DEFAULT (1),
    CreatedAt   DATETIME2(0)  NOT NULL CONSTRAINT DF_UserModuleAccess_CreatedAt DEFAULT SYSUTCDATETIME(),
    UpdatedAt   DATETIME2(0)  NOT NULL CONSTRAINT DF_UserModuleAccess_UpdatedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_UserModuleAccess PRIMARY KEY (AccessId),
    CONSTRAINT UQ_UserModuleAccess UNIQUE (UserCode, ModuleCode)
  );
END;
GO

-- Si AccesoUsuarios existe como tabla legacy, migrar datos y reemplazar por vista
IF OBJECT_ID(N'dbo.AccesoUsuarios', N'U') IS NOT NULL
BEGIN
  INSERT INTO sec.UserModuleAccess (UserCode, ModuleCode, IsAllowed, CreatedAt, UpdatedAt)
  SELECT Cod_Usuario, Modulo, Permitido, SYSUTCDATETIME(), SYSUTCDATETIME()
  FROM dbo.AccesoUsuarios a
  WHERE NOT EXISTS (
    SELECT 1 FROM sec.UserModuleAccess m
    WHERE m.UserCode = a.Cod_Usuario AND m.ModuleCode = a.Modulo
  );
  DROP TABLE dbo.AccesoUsuarios;
END;
GO

-- Vista de compatibilidad
IF OBJECT_ID(N'dbo.AccesoUsuarios', N'V') IS NULL
BEGIN
  EXEC(N'
    CREATE VIEW dbo.AccesoUsuarios AS
    SELECT UserCode AS Cod_Usuario, ModuleCode AS Modulo, IsAllowed AS Permitido, CreatedAt, UpdatedAt
    FROM sec.UserModuleAccess;
  ');
END;
GO

PRINT '[21] Limpieza legacy + sec.UserModuleAccess completado.';
GO
