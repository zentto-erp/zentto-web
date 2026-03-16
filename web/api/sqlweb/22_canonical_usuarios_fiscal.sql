-- =============================================================================
-- 22_canonical_usuarios_fiscal.sql
-- Fix 2: dbo.Usuarios -> sec.User (ampliar tabla, migrar datos, view + triggers)
-- Fix 3: Limpiar dbo.FiscalCountryConfig / FiscalTaxRates /
--         FiscalInvoiceTypes / FiscalRecords (duplicados de fiscal.*)
--
-- Estrategia: igual que documentos/AccesoUsuarios en script 21
--   - sec.User recibe columnas legacy (UserType, CanUpdate, CanCreate, etc.)
--   - dbo.Usuarios TABLE -> VIEW sobre sec.User con nombres de columna originales
--   - INSTEAD OF INSERT / UPDATE / DELETE transparen la logica al TypeScript
--   - Cero cambios en TypeScript
-- =============================================================================
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

USE DatqBoxWeb;
GO

PRINT '[22] Inicio migracion sec.User y limpieza dbo.Fiscal*...';
GO

-- =============================================================================
-- SECCIÓN 1: AMPLIAR sec.User CON COLUMNAS LEGACY
-- =============================================================================

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('sec.User') AND name = 'UserType')
  ALTER TABLE sec.[User] ADD UserType NVARCHAR(10) NULL;
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('sec.User') AND name = 'CanUpdate')
  ALTER TABLE sec.[User] ADD CanUpdate BIT NOT NULL CONSTRAINT DF_SecUser_CanUpdate DEFAULT (1);
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('sec.User') AND name = 'CanCreate')
  ALTER TABLE sec.[User] ADD CanCreate BIT NOT NULL CONSTRAINT DF_SecUser_CanCreate DEFAULT (1);
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('sec.User') AND name = 'CanDelete')
  ALTER TABLE sec.[User] ADD CanDelete BIT NOT NULL CONSTRAINT DF_SecUser_CanDelete DEFAULT (0);
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('sec.User') AND name = 'IsCreator')
  ALTER TABLE sec.[User] ADD IsCreator BIT NOT NULL CONSTRAINT DF_SecUser_IsCreator DEFAULT (0);
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('sec.User') AND name = 'CanChangePwd')
  ALTER TABLE sec.[User] ADD CanChangePwd BIT NOT NULL CONSTRAINT DF_SecUser_CanChangePwd DEFAULT (1);
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('sec.User') AND name = 'CanChangePrice')
  ALTER TABLE sec.[User] ADD CanChangePrice BIT NOT NULL CONSTRAINT DF_SecUser_CanChangePrice DEFAULT (0);
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('sec.User') AND name = 'CanGiveCredit')
  ALTER TABLE sec.[User] ADD CanGiveCredit BIT NOT NULL CONSTRAINT DF_SecUser_CanGiveCredit DEFAULT (0);
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('sec.User') AND name = 'Avatar')
  ALTER TABLE sec.[User] ADD Avatar NVARCHAR(MAX) NULL;
GO

PRINT '[22] Columnas legacy agregadas a sec.User.';
GO

-- =============================================================================
-- SECCIÓN 2: MIGRAR DATOS dbo.Usuarios -> sec.User (MERGE idempotente)
-- =============================================================================

MERGE sec.[User] AS tgt
USING (
  SELECT
    Cod_Usuario                                          AS UserCode,
    Password                                             AS PasswordHash,
    Nombre                                               AS UserName,
    CASE WHEN Tipo IN ('ADMIN','SUP') THEN 1 ELSE 0 END  AS IsAdmin,
    CASE WHEN Tipo = 'ADMIN' THEN N'ADMIN'
         WHEN Tipo = 'SUP'   THEN N'SUP'
         ELSE N'USER' END                                AS UserType,
    ISNULL(Updates,      1)                              AS CanUpdate,
    ISNULL(Addnews,      1)                              AS CanCreate,
    ISNULL(Deletes,      0)                              AS CanDelete,
    ISNULL(Creador,      0)                              AS IsCreator,
    ISNULL(Cambiar,      1)                              AS CanChangePwd,
    ISNULL(PrecioMinimo, 0)                              AS CanChangePrice,
    ISNULL(Credito,      0)                              AS CanGiveCredit,
    Avatar
  FROM dbo.Usuarios
) AS src ON UPPER(tgt.UserCode) = UPPER(src.UserCode)
WHEN MATCHED THEN
  UPDATE SET
    tgt.PasswordHash   = src.PasswordHash,
    tgt.UserName       = src.UserName,
    tgt.IsAdmin        = src.IsAdmin,
    tgt.UserType       = src.UserType,
    tgt.CanUpdate      = src.CanUpdate,
    tgt.CanCreate      = src.CanCreate,
    tgt.CanDelete      = src.CanDelete,
    tgt.IsCreator      = src.IsCreator,
    tgt.CanChangePwd   = src.CanChangePwd,
    tgt.CanChangePrice = src.CanChangePrice,
    tgt.CanGiveCredit  = src.CanGiveCredit,
    tgt.Avatar         = src.Avatar,
    tgt.IsActive       = 1,
    tgt.UpdatedAt      = SYSUTCDATETIME()
WHEN NOT MATCHED THEN
  INSERT (UserCode, PasswordHash, UserName, IsAdmin, IsActive, UserType,
          CanUpdate, CanCreate, CanDelete, IsCreator, CanChangePwd, CanChangePrice,
          CanGiveCredit, Avatar, CreatedAt, UpdatedAt, IsDeleted)
  VALUES (src.UserCode, src.PasswordHash, src.UserName, src.IsAdmin, 1, src.UserType,
          src.CanUpdate, src.CanCreate, src.CanDelete, src.IsCreator, src.CanChangePwd,
          src.CanChangePrice, src.CanGiveCredit, src.Avatar,
          SYSUTCDATETIME(), SYSUTCDATETIME(), 0);
GO

PRINT '[22] Usuarios migrados a sec.User.';
GO

-- =============================================================================
-- SECCIÓN 3: SOLTAR FKs QUE APUNTAN A dbo.Usuarios (tabla)
-- =============================================================================

IF OBJECT_ID('sec.FK_sec_AuthToken_Usuarios',  'F') IS NOT NULL
  ALTER TABLE sec.AuthToken DROP CONSTRAINT FK_sec_AuthToken_Usuarios;
GO
IF OBJECT_ID('sec.FK_sec_AuthIdentity_Usuarios', 'F') IS NOT NULL
  ALTER TABLE sec.AuthIdentity DROP CONSTRAINT FK_sec_AuthIdentity_Usuarios;
GO
IF OBJECT_ID('sec.FK_SupervisorBiometricCredential_SupervisorUser', 'F') IS NOT NULL
  ALTER TABLE sec.SupervisorBiometricCredential DROP CONSTRAINT FK_SupervisorBiometricCredential_SupervisorUser;
GO

-- =============================================================================
-- SECCIÓN 4: DROP dbo.Usuarios (tabla)
-- =============================================================================

IF OBJECT_ID('dbo.Usuarios', 'U') IS NOT NULL
  DROP TABLE dbo.Usuarios;
GO

PRINT '[22] dbo.Usuarios tabla eliminada.';
GO

-- =============================================================================
-- SECCIÓN 5: VIEW dbo.Usuarios -> sec.User (mismos nombres de columna legacy)
-- =============================================================================

IF OBJECT_ID('dbo.Usuarios', 'V') IS NOT NULL
  DROP VIEW dbo.Usuarios;
GO

CREATE VIEW dbo.Usuarios AS
SELECT
  UserCode          AS Cod_Usuario,
  PasswordHash      AS Password,
  UserName          AS Nombre,
  UserType          AS Tipo,
  CanUpdate         AS Updates,
  CanCreate         AS Addnews,
  CanDelete         AS Deletes,
  IsCreator         AS Creador,
  CanChangePwd      AS Cambiar,
  CanChangePrice    AS PrecioMinimo,
  CanGiveCredit     AS Credito,
  IsAdmin,
  Avatar
FROM sec.[User]
WHERE IsDeleted = 0;
GO

-- =============================================================================
-- SECCIÓN 6: TRIGGERS INSTEAD OF sobre dbo.Usuarios
-- =============================================================================

-- ---- INSTEAD OF INSERT ---------------------------------------------------
IF OBJECT_ID('dbo.trg_Usuarios_IOI', 'TR') IS NOT NULL
  DROP TRIGGER dbo.trg_Usuarios_IOI;
GO

CREATE TRIGGER dbo.trg_Usuarios_IOI
ON dbo.Usuarios
INSTEAD OF INSERT
AS
BEGIN
  SET NOCOUNT ON;
  INSERT INTO sec.[User] (
    UserCode, PasswordHash, UserName, IsAdmin, IsActive,
    UserType, CanUpdate, CanCreate, CanDelete, IsCreator,
    CanChangePwd, CanChangePrice, CanGiveCredit, Avatar,
    CreatedAt, UpdatedAt, IsDeleted
  )
  SELECT
    i.Cod_Usuario,
    i.Password,
    i.Nombre,
    ISNULL(i.IsAdmin,       0),
    1,
    ISNULL(i.Tipo,          N'USER'),
    ISNULL(i.Updates,       1),
    ISNULL(i.Addnews,       1),
    ISNULL(i.Deletes,       0),
    ISNULL(i.Creador,       0),
    ISNULL(i.Cambiar,       1),
    ISNULL(i.PrecioMinimo,  0),
    ISNULL(i.Credito,       0),
    i.Avatar,
    SYSUTCDATETIME(),
    SYSUTCDATETIME(),
    0
  FROM INSERTED i;
END;
GO

-- ---- INSTEAD OF UPDATE ---------------------------------------------------
IF OBJECT_ID('dbo.trg_Usuarios_IOU', 'TR') IS NOT NULL
  DROP TRIGGER dbo.trg_Usuarios_IOU;
GO

CREATE TRIGGER dbo.trg_Usuarios_IOU
ON dbo.Usuarios
INSTEAD OF UPDATE
AS
BEGIN
  SET NOCOUNT ON;
  -- INSERTED contains final values (SET results OR current values for non-SET cols)
  UPDATE u
  SET
    u.PasswordHash   = i.Password,
    u.UserName       = i.Nombre,
    u.UserType       = i.Tipo,
    u.IsAdmin        = i.IsAdmin,
    u.CanUpdate      = i.Updates,
    u.CanCreate      = i.Addnews,
    u.CanDelete      = i.Deletes,
    u.IsCreator      = i.Creador,
    u.CanChangePwd   = i.Cambiar,
    u.CanChangePrice = i.PrecioMinimo,
    u.CanGiveCredit  = i.Credito,
    u.Avatar         = i.Avatar,
    u.UpdatedAt      = SYSUTCDATETIME()
  FROM sec.[User] u
  INNER JOIN INSERTED i ON UPPER(u.UserCode) = UPPER(i.Cod_Usuario)
  WHERE u.IsDeleted = 0;
END;
GO

-- ---- INSTEAD OF DELETE  (soft-delete en sec.User) -----------------------
IF OBJECT_ID('dbo.trg_Usuarios_IOD', 'TR') IS NOT NULL
  DROP TRIGGER dbo.trg_Usuarios_IOD;
GO

CREATE TRIGGER dbo.trg_Usuarios_IOD
ON dbo.Usuarios
INSTEAD OF DELETE
AS
BEGIN
  SET NOCOUNT ON;
  UPDATE u
  SET
    u.IsDeleted = 1,
    u.IsActive  = 0,
    u.DeletedAt = SYSUTCDATETIME(),
    u.UpdatedAt = SYSUTCDATETIME()
  FROM sec.[User] u
  INNER JOIN DELETED d ON UPPER(u.UserCode) = UPPER(d.Cod_Usuario)
  WHERE u.IsDeleted = 0;
END;
GO

PRINT '[22] VIEW dbo.Usuarios y triggers IOI/IOU/IOD creados.';
GO

-- =============================================================================
-- SECCIÓN 7: LIMPIAR dbo.Fiscal* (duplicados de fiscal.*)
--   Los datos son identicos. Los triggers de sincronizacion caen con las tablas.
-- =============================================================================

-- Verificar que no haya FKs dependientes antes de borrar
IF NOT EXISTS (
  SELECT 1 FROM sys.foreign_keys
  WHERE referenced_object_id IN (
    OBJECT_ID('dbo.FiscalCountryConfig'),
    OBJECT_ID('dbo.FiscalTaxRates'),
    OBJECT_ID('dbo.FiscalInvoiceTypes'),
    OBJECT_ID('dbo.FiscalRecords')
  )
)
BEGIN
  IF OBJECT_ID('dbo.FiscalCountryConfig', 'U') IS NOT NULL  DROP TABLE dbo.FiscalCountryConfig;
  IF OBJECT_ID('dbo.FiscalTaxRates',      'U') IS NOT NULL  DROP TABLE dbo.FiscalTaxRates;
  IF OBJECT_ID('dbo.FiscalInvoiceTypes',  'U') IS NOT NULL  DROP TABLE dbo.FiscalInvoiceTypes;
  IF OBJECT_ID('dbo.FiscalRecords',       'U') IS NOT NULL  DROP TABLE dbo.FiscalRecords;
  PRINT '[22] Tablas dbo.Fiscal* eliminadas (duplicados de fiscal.* schema).';
END
ELSE
BEGIN
  PRINT '[22] AVISO: dbo.Fiscal* tiene dependencias FK - no eliminadas. Revisar manualmente.';
END;
GO

PRINT '[22] Migracion sec.User y limpieza dbo.Fiscal* completadas correctamente.';
GO
