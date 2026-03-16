/*
 * ============================================================================
 *  Archivo : usp_cfg.sql
 *  Esquema : cfg (configuracion de la aplicacion)
 *  Base    : DatqBoxWeb
 *  Fecha   : 2026-03-14
 *
 *  Descripcion:
 *    Procedimientos almacenados para gestion de configuracion del sistema.
 *    - usp_Cfg_ResolveContext             : Resuelve contexto empresa/sucursal/usuario.
 *    - usp_Cfg_AppSetting_List            : Lista todas las configuraciones.
 *    - usp_Cfg_AppSetting_ListByModule    : Lista configuraciones por modulo.
 *    - usp_Cfg_AppSetting_ListWithMeta    : Lista configuraciones con metadatos completos.
 *    - usp_Cfg_AppSetting_Upsert          : Inserta o actualiza una configuracion.
 *    - usp_Cfg_AppSetting_ListModules     : Lista modulos distintos.
 *    - usp_Cfg_AppSetting_ListValueTypes  : Lista tipos de valor distintos.
 *
 *  Tabla principal: cfg.AppSetting
 *    Columnas: SettingId, CompanyId, Module, SettingKey, SettingValue, ValueType,
 *              Description, IsReadOnly, UpdatedAt, UpdatedByUserId
 *
 *  Patron  : CREATE OR ALTER (idempotente)
 * ============================================================================
 */

USE DatqBoxWeb;
GO

-- =============================================================================
--  SP 1: usp_Cfg_ResolveContext
--  Descripcion : Resuelve el contexto de operacion devolviendo CompanyId,
--                BranchId y opcionalmente UserId.  Se usa como paso inicial
--                en llamadas de API para determinar la empresa y sucursal activa.
--  Parametros  :
--    @UserCode  NVARCHAR(60) = NULL  - Codigo de usuario (opcional).
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Cfg_ResolveContext
    @UserCode  NVARCHAR(60) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @CompanyId INT;
    DECLARE @BranchId  INT;
    DECLARE @UserId    INT = NULL;

    -- Obtener la empresa por defecto (prioriza CompanyCode = 'DEFAULT')
    SELECT TOP 1 @CompanyId = CompanyId
    FROM   cfg.Company
    WHERE  IsDeleted = 0
    ORDER BY
        CASE WHEN CompanyCode = 'DEFAULT' THEN 0 ELSE 1 END,
        CompanyId;

    -- Obtener la sucursal principal de la empresa
    SELECT TOP 1 @BranchId = BranchId
    FROM   cfg.Branch
    WHERE  CompanyId = @CompanyId
      AND  IsDeleted = 0
    ORDER BY
        CASE WHEN BranchCode = 'MAIN' THEN 0 ELSE 1 END,
        BranchId;

    -- Si se proporciono codigo de usuario, resolver UserId
    IF @UserCode IS NOT NULL
    BEGIN
        SELECT TOP 1 @UserId = UserId
        FROM   sec.[User]
        WHERE  UserCode  = @UserCode
          AND  IsDeleted = 0;
    END;

    -- Devolver fila unica con el contexto resuelto
    SELECT
        @CompanyId AS CompanyId,
        @BranchId  AS BranchId,
        @UserId    AS UserId;
END;
GO

-- =============================================================================
--  SP 2: usp_Cfg_AppSetting_List
--  Descripcion : Devuelve todas las configuraciones de cfg.AppSetting
--                para una empresa, ordenadas por modulo y clave.
--  Parametros  :
--    @CompanyId  INT - Identificador de la empresa.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Cfg_AppSetting_List
    @CompanyId  INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT SettingId,
           Module,
           SettingKey,
           SettingValue,
           ValueType,
           Description,
           UpdatedAt
    FROM   cfg.AppSetting
    WHERE  CompanyId = @CompanyId
    ORDER BY Module, SettingKey;
END;
GO

-- =============================================================================
--  SP 3: usp_Cfg_AppSetting_ListByModule
--  Descripcion : Devuelve las configuraciones filtradas por empresa y modulo.
--  Parametros  :
--    @CompanyId  INT          - Identificador de la empresa.
--    @Module     NVARCHAR(60) - Nombre del modulo.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Cfg_AppSetting_ListByModule
    @CompanyId  INT,
    @Module     NVARCHAR(60)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT SettingId,
           Module,
           SettingKey,
           SettingValue,
           ValueType,
           Description,
           UpdatedAt
    FROM   cfg.AppSetting
    WHERE  CompanyId = @CompanyId
      AND  Module    = @Module
    ORDER BY SettingKey;
END;
GO

-- =============================================================================
--  SP 4: usp_Cfg_AppSetting_ListWithMeta
--  Descripcion : Devuelve todas las columnas de cfg.AppSetting, opcionalmente
--                filtradas por modulo.  Pensado para pantallas de administracion
--                que necesitan metadatos completos (incluye IsReadOnly).
--  Parametros  :
--    @CompanyId  INT                - Identificador de la empresa.
--    @Module     NVARCHAR(60) = NULL - Filtro opcional por modulo.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Cfg_AppSetting_ListWithMeta
    @CompanyId  INT,
    @Module     NVARCHAR(60) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT SettingId,
           Module,
           SettingKey,
           SettingValue,
           ValueType,
           Description,
           IsReadOnly,
           UpdatedAt
    FROM   cfg.AppSetting
    WHERE  CompanyId = @CompanyId
      AND  (@Module IS NULL OR Module = @Module)
    ORDER BY Module, SettingKey;
END;
GO

-- =============================================================================
--  SP 5: usp_Cfg_AppSetting_Upsert
--  Descripcion : Inserta o actualiza una configuracion en cfg.AppSetting.
--                Si ya existe la combinacion (CompanyId, Module, SettingKey),
--                actualiza; de lo contrario inserta un registro nuevo.
--  Parametros  :
--    @CompanyId     INT                   - Identificador de la empresa.
--    @Module        NVARCHAR(60)          - Modulo de la configuracion.
--    @SettingKey    NVARCHAR(128)         - Clave de la configuracion.
--    @SettingValue  NVARCHAR(MAX)         - Valor de la configuracion.
--    @ValueType     NVARCHAR(30)  = NULL  - Tipo de dato del valor (opcional).
--    @Description   NVARCHAR(500) = NULL  - Descripcion (opcional).
--    @UserId        INT           = NULL  - Usuario que realiza el cambio (opcional).
--    @Resultado     INT           OUTPUT  - 0 = exito, <>0 = error.
--    @Mensaje       NVARCHAR(500) OUTPUT  - Mensaje descriptivo del resultado.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Cfg_AppSetting_Upsert
    @CompanyId     INT,
    @Module        NVARCHAR(60),
    @SettingKey    NVARCHAR(128),
    @SettingValue  NVARCHAR(MAX),
    @ValueType     NVARCHAR(30)  = NULL,
    @Description   NVARCHAR(500) = NULL,
    @UserId        INT           = NULL,
    @Resultado     INT           OUTPUT,
    @Mensaje       NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        IF EXISTS (
            SELECT 1
            FROM   cfg.AppSetting
            WHERE  CompanyId  = @CompanyId
              AND  Module     = @Module
              AND  SettingKey = @SettingKey
        )
        BEGIN
            -- Actualizar registro existente
            UPDATE cfg.AppSetting
            SET    SettingValue     = @SettingValue,
                   ValueType       = ISNULL(@ValueType, ValueType),
                   Description     = ISNULL(@Description, Description),
                   UpdatedAt       = SYSUTCDATETIME(),
                   UpdatedByUserId = @UserId
            WHERE  CompanyId  = @CompanyId
              AND  Module     = @Module
              AND  SettingKey = @SettingKey;

            SET @Resultado = 0;
            SET @Mensaje   = N'Configuracion actualizada correctamente.';
        END
        ELSE
        BEGIN
            -- Insertar nuevo registro
            INSERT INTO cfg.AppSetting
                (CompanyId, Module, SettingKey, SettingValue, ValueType, Description,
                 UpdatedAt, UpdatedByUserId)
            VALUES
                (@CompanyId, @Module, @SettingKey, @SettingValue, @ValueType, @Description,
                 SYSUTCDATETIME(), @UserId);

            SET @Resultado = 0;
            SET @Mensaje   = N'Configuracion insertada correctamente.';
        END;
    END TRY
    BEGIN CATCH
        SET @Resultado = ERROR_NUMBER();
        SET @Mensaje   = ERROR_MESSAGE();
    END CATCH;
END;
GO

-- =============================================================================
--  SP 6: usp_Cfg_AppSetting_ListModules
--  Descripcion : Devuelve la lista de modulos distintos presentes en
--                cfg.AppSetting para una empresa.  Util para llenar
--                combos/filtros en la UI.
--  Parametros  :
--    @CompanyId  INT - Identificador de la empresa.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Cfg_AppSetting_ListModules
    @CompanyId  INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT DISTINCT Module
    FROM   cfg.AppSetting
    WHERE  CompanyId = @CompanyId
    ORDER BY Module;
END;
GO

-- =============================================================================
--  SP 7: usp_Cfg_AppSetting_ListValueTypes
--  Descripcion : Devuelve la lista de tipos de valor distintos registrados.
--                Excluye valores NULL.
--  Parametros  : Ninguno.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Cfg_AppSetting_ListValueTypes
AS
BEGIN
    SET NOCOUNT ON;

    SELECT DISTINCT ValueType
    FROM   cfg.AppSetting
    WHERE  ValueType IS NOT NULL
    ORDER BY ValueType;
END;
GO
