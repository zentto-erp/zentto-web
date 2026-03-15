/*
 * ============================================================================
 *  Archivo : usp_sec.sql
 *  Esquema : sec (seguridad y autenticacion)
 *  Base    : DatqBoxWeb
 *  Fecha   : 2026-03-14
 *
 *  Descripcion:
 *    Procedimientos almacenados de seguridad: autenticacion de usuarios,
 *    consulta de tipo/rol, acceso a modulos, gestion de empresas/sucursales,
 *    contraseñas y avatares.
 *    - usp_Sec_User_Authenticate                   : Devuelve registro del usuario (sin verificar clave).
 *    - usp_Sec_User_GetType                        : Obtiene tipo/rol del usuario.
 *    - usp_Sec_User_GetModuleAccess                : Obtiene permisos de acceso a modulos.
 *    - usp_Sec_User_ListCompanyAccesses_Default    : Lista empresas/sucursales activas (admin).
 *    - usp_Sec_User_GetCompanyAccesses             : Lista accesos empresa/sucursal de un usuario.
 *    - usp_Sec_User_EnsureDefaultCompanyAccess     : Garantiza acceso a empresa DEFAULT para un usuario.
 *    - usp_Sec_User_SetModuleAccess                : Establece permisos de modulos desde JSON.
 *    - usp_Sec_User_UpdatePassword                 : Actualiza hash de contraseña.
 *    - usp_Sec_User_GetAvatar                      : Obtiene avatar del usuario.
 *    - usp_Sec_User_SetAvatar                      : Establece o elimina avatar del usuario.
 *    - usp_Sec_User_CheckExists                    : Verifica si un usuario existe.
 *
 *  Compatibilidad:
 *    Cada SP verifica la existencia de las tablas canonicas (sec.[User]) y
 *    cae de forma transparente a las tablas legacy (dbo.Usuarios) para
 *    mantener compatibilidad VB6 -> Web.
 *
 *  Patron  : IF EXISTS DROP + CREATE (compatible SQL Server 2012)
 * ============================================================================
 */

USE DatqBoxWeb;
GO

-- =============================================================================
--  SP 1: usp_Sec_User_Authenticate
--  Descripcion : Devuelve el registro del usuario para autenticacion.
--                La verificacion de contraseña se realiza en Node.js con bcrypt.
--                Primero intenta contra sec.[User] (esquema canonico).
--                Si la tabla no existe, cae a dbo.Usuarios (tabla legacy VB6).
--  Parametros  :
--    @CodUsuario  NVARCHAR(60)  - Codigo del usuario.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Sec_User_Authenticate
    @CodUsuario  NVARCHAR(60)
AS
BEGIN
    SET NOCOUNT ON;

    -- Verificar si existe la tabla canonica sec.[User]
    IF OBJECT_ID(N'sec.User', N'U') IS NOT NULL
    BEGIN
        -- Mapeo de columnas canonicas a nombres legacy esperados por el TS
        SELECT TOP 1
               UserCode      AS Cod_Usuario,
               PasswordHash  AS Password,
               UserName      AS Nombre,
               UserType      AS Tipo,
               CanUpdate     AS Updates,
               CanCreate     AS Addnews,
               CanDelete     AS Deletes,
               CAST(CreatedByUserId AS NVARCHAR(60)) AS Creador,
               CanChangePwd       AS Cambiar,
               CanChangePrice     AS PrecioMinimo,
               CanGiveCredit      AS Credito
        FROM   sec.[User]
        WHERE  UserCode  = @CodUsuario
          AND  IsDeleted = 0;
    END
    ELSE
    BEGIN
        -- Fallback a tabla legacy dbo.Usuarios
        SELECT TOP 1
               Cod_Usuario,
               Password,
               Nombre,
               Tipo,
               Updates,
               Addnews,
               Deletes,
               Creador,
               Cambiar,
               PrecioMinimo,
               Credito
        FROM   dbo.Usuarios
        WHERE  Cod_Usuario = @CodUsuario;
    END;
END;
GO

-- =============================================================================
--  SP 2: usp_Sec_User_GetType
--  Descripcion : Devuelve el tipo/rol de un usuario dado su codigo.
--                Intenta primero con sec.[User] y luego con dbo.Usuarios.
--  Parametros  :
--    @CodUsuario  NVARCHAR(60) - Codigo del usuario.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Sec_User_GetType
    @CodUsuario  NVARCHAR(60)
AS
BEGIN
    SET NOCOUNT ON;

    -- Verificar si existe la tabla canonica sec.[User]
    IF OBJECT_ID(N'sec.User', N'U') IS NOT NULL
    BEGIN
        SELECT UserCode   AS Cod_Usuario,
               UserType   AS Tipo
        FROM   sec.[User]
        WHERE  UserCode  = @CodUsuario
          AND  IsDeleted = 0;
    END
    ELSE
    BEGIN
        -- Fallback a tabla legacy dbo.Usuarios
        SELECT Cod_Usuario,
               Tipo
        FROM   dbo.Usuarios
        WHERE  Cod_Usuario = @CodUsuario;
    END;
END;
GO

-- =============================================================================
--  SP 3: usp_Sec_User_GetModuleAccess
--  Descripcion : Devuelve los permisos de acceso a modulos para un usuario.
--                Consulta la tabla sec.UserModuleAccess.
--  Parametros  :
--    @CodUsuario  NVARCHAR(60) - Codigo del usuario.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Sec_User_GetModuleAccess
    @CodUsuario  NVARCHAR(60)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT UserCode   AS Cod_Usuario,
           ModuleCode AS Modulo,
           IsAllowed  AS Permitido
    FROM   sec.UserModuleAccess
    WHERE  UserCode = @CodUsuario;
END;
GO

-- =============================================================================
--  SP 4: usp_Sec_User_ListCompanyAccesses_Default
--  Descripcion : Devuelve todas las empresas y sucursales activas.
--                Utilizado para usuarios administradores que tienen acceso total.
--                No recibe parametros.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Sec_User_ListCompanyAccesses_Default
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        c.CompanyId                                                AS companyId,
        c.CompanyCode                                              AS companyCode,
        ISNULL(NULLIF(c.TradeName, N''), c.LegalName)             AS companyName,
        b.BranchId                                                 AS branchId,
        b.BranchCode                                               AS branchCode,
        b.BranchName                                               AS branchName,
        UPPER(ISNULL(NULLIF(b.CountryCode, ''), c.FiscalCountryCode)) AS countryCode,
        COALESCE(
            NULLIF(ct.TimeZoneIana, N''),
            CASE UPPER(ISNULL(NULLIF(b.CountryCode, ''), c.FiscalCountryCode))
                WHEN 'ES' THEN 'Europe/Madrid'
                WHEN 'VE' THEN 'America/Caracas'
                ELSE 'UTC'
            END
        )                                                          AS timeZone,
        CAST(
            CASE WHEN c.CompanyCode = N'DEFAULT' AND b.BranchCode = N'MAIN'
                 THEN 1 ELSE 0
            END AS bit
        )                                                          AS isDefault
    FROM cfg.Company c
    INNER JOIN cfg.Branch b
        ON b.CompanyId = c.CompanyId
    LEFT JOIN cfg.Country ct
        ON ct.CountryCode = UPPER(ISNULL(NULLIF(b.CountryCode, ''), c.FiscalCountryCode))
       AND ct.IsActive = 1
    WHERE c.IsActive  = 1
      AND c.IsDeleted = 0
      AND b.IsActive  = 1
      AND b.IsDeleted = 0
    ORDER BY
        CASE WHEN c.CompanyCode = N'DEFAULT' AND b.BranchCode = N'MAIN'
             THEN 0 ELSE 1
        END,
        c.CompanyId,
        b.BranchId;
END;
GO

-- =============================================================================
--  SP 5: usp_Sec_User_GetCompanyAccesses
--  Descripcion : Devuelve los accesos empresa/sucursal asignados a un usuario.
--                Si la tabla sec.UserCompanyAccess no existe, retorna vacio.
--  Parametros  :
--    @CodUsuario  NVARCHAR(60) - Codigo del usuario.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Sec_User_GetCompanyAccesses
    @CodUsuario  NVARCHAR(60)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        SELECT
            a.CompanyId                                                AS companyId,
            c.CompanyCode                                              AS companyCode,
            ISNULL(NULLIF(c.TradeName, N''), c.LegalName)             AS companyName,
            a.BranchId                                                 AS branchId,
            b.BranchCode                                               AS branchCode,
            b.BranchName                                               AS branchName,
            UPPER(ISNULL(NULLIF(b.CountryCode, ''), c.FiscalCountryCode)) AS countryCode,
            COALESCE(
                NULLIF(ct.TimeZoneIana, N''),
                CASE UPPER(ISNULL(NULLIF(b.CountryCode, ''), c.FiscalCountryCode))
                    WHEN 'ES' THEN 'Europe/Madrid'
                    WHEN 'VE' THEN 'America/Caracas'
                    ELSE 'UTC'
                END
            )                                                          AS timeZone,
            a.IsDefault                                                AS isDefault
        FROM sec.UserCompanyAccess a
        INNER JOIN cfg.Company c
            ON c.CompanyId = a.CompanyId
           AND c.IsActive  = 1
           AND c.IsDeleted = 0
        INNER JOIN cfg.Branch b
            ON b.BranchId  = a.BranchId
           AND b.CompanyId = a.CompanyId
           AND b.IsActive  = 1
           AND b.IsDeleted = 0
        LEFT JOIN cfg.Country ct
            ON ct.CountryCode = UPPER(ISNULL(NULLIF(b.CountryCode, ''), c.FiscalCountryCode))
           AND ct.IsActive = 1
        WHERE UPPER(a.CodUsuario) = UPPER(@CodUsuario)
          AND a.IsActive = 1
        ORDER BY
            CASE WHEN a.IsDefault = 1 THEN 0 ELSE 1 END,
            a.CompanyId,
            a.BranchId;
    END TRY
    BEGIN CATCH
        -- Si la tabla no esta desplegada, retornar resultado vacio
        SELECT
            CAST(NULL AS INT)          AS companyId,
            CAST(NULL AS NVARCHAR(30)) AS companyCode,
            CAST(NULL AS NVARCHAR(200)) AS companyName,
            CAST(NULL AS INT)          AS branchId,
            CAST(NULL AS NVARCHAR(30)) AS branchCode,
            CAST(NULL AS NVARCHAR(200)) AS branchName,
            CAST(NULL AS NVARCHAR(10)) AS countryCode,
            CAST(NULL AS NVARCHAR(100)) AS timeZone,
            CAST(NULL AS BIT)          AS isDefault
        WHERE 1 = 0;
    END CATCH;
END;
GO

-- =============================================================================
--  SP 6: usp_Sec_User_EnsureDefaultCompanyAccess
--  Descripcion : Garantiza que el usuario tenga un registro de acceso a la
--                empresa DEFAULT / sucursal MAIN en sec.UserCompanyAccess.
--                Si la tabla no existe, no hace nada.
--  Parametros  :
--    @CodUsuario  NVARCHAR(60) - Codigo del usuario.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Sec_User_EnsureDefaultCompanyAccess
    @CodUsuario  NVARCHAR(60)
AS
BEGIN
    SET NOCOUNT ON;

    -- Solo proceder si la tabla sec.UserCompanyAccess existe
    IF OBJECT_ID(N'sec.UserCompanyAccess', N'U') IS NULL
        RETURN;

    -- Buscar la empresa DEFAULT y la sucursal MAIN
    DECLARE @CompanyId INT, @BranchId INT;

    SELECT @CompanyId = c.CompanyId,
           @BranchId  = b.BranchId
    FROM   cfg.Company c
    INNER JOIN cfg.Branch b
        ON b.CompanyId = c.CompanyId
       AND b.BranchCode = N'MAIN'
       AND b.IsActive   = 1
       AND b.IsDeleted  = 0
    WHERE  c.CompanyCode = N'DEFAULT'
      AND  c.IsActive    = 1
      AND  c.IsDeleted   = 0;

    -- Si no se encontro la empresa/sucursal, salir
    IF @CompanyId IS NULL OR @BranchId IS NULL
        RETURN;

    -- MERGE: insertar si no existe, actualizar si esta inactivo
    MERGE sec.UserCompanyAccess AS target
    USING (
        SELECT @CodUsuario AS CodUsuario,
               @CompanyId  AS CompanyId,
               @BranchId   AS BranchId
    ) AS source
    ON  UPPER(target.CodUsuario) = UPPER(source.CodUsuario)
    AND target.CompanyId         = source.CompanyId
    AND target.BranchId          = source.BranchId
    WHEN MATCHED AND target.IsActive = 0 THEN
        UPDATE SET IsActive  = 1,
                   IsDefault = 1
    WHEN NOT MATCHED THEN
        INSERT (CodUsuario, CompanyId, BranchId, IsActive, IsDefault)
        VALUES (@CodUsuario, @CompanyId, @BranchId, 1, 1);
END;
GO

-- =============================================================================
--  SP 7: usp_Sec_User_SetModuleAccess
--  Descripcion : Establece los permisos de acceso a modulos de un usuario
--                a partir de un JSON. Reemplaza todos los registros existentes.
--  Parametros  :
--    @CodUsuario   NVARCHAR(60)   - Codigo del usuario.
--    @ModulesJson  NVARCHAR(MAX)  - Array JSON de {modulo, permitido}.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Sec_User_SetModuleAccess
    @CodUsuario   NVARCHAR(60),
    @ModulesJson  NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    -- Eliminar permisos actuales del usuario
    DELETE FROM sec.UserModuleAccess
    WHERE  UserCode = @CodUsuario;

    -- Insertar nuevos permisos desde el JSON (compatible SQL 2012)
    -- El JSON se parsea en Node.js y se pasa como XML
    -- Fallback: si @ModulesJson es XML, parsearlo
    BEGIN TRY
        DECLARE @xml XML = CAST(@ModulesJson AS XML);
        INSERT INTO sec.UserModuleAccess (UserCode, ModuleCode, IsAllowed)
        SELECT @CodUsuario,
               n.value('(modulo)[1]', 'NVARCHAR(60)'),
               n.value('(permitido)[1]', 'BIT')
        FROM   @xml.nodes('/modules/m') AS t(n);
    END TRY
    BEGIN CATCH
        -- Si no es XML valido, ignorar (el caller debe enviar XML)
        RETURN;
    END CATCH;
END;
GO

-- =============================================================================
--  SP 8: usp_Sec_User_UpdatePassword
--  Descripcion : Actualiza el hash de contraseña de un usuario.
--                Intenta primero en sec.[User] y luego en dbo.Usuarios.
--  Parametros  :
--    @CodUsuario   NVARCHAR(60)   - Codigo del usuario.
--    @PasswordHash NVARCHAR(255)  - Nuevo hash bcrypt de la contraseña.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Sec_User_UpdatePassword
    @CodUsuario   NVARCHAR(60),
    @PasswordHash NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;

    -- Intentar actualizar en la tabla canonica sec.[User]
    IF OBJECT_ID(N'sec.User', N'U') IS NOT NULL
    BEGIN
        UPDATE sec.[User]
        SET    PasswordHash = @PasswordHash
        WHERE  UserCode  = @CodUsuario
          AND  IsDeleted = 0;
    END

    -- Actualizar tambien en la tabla legacy dbo.Usuarios (mantener sincronizado)
    UPDATE dbo.Usuarios
    SET    Password = @PasswordHash
    WHERE  Cod_Usuario = @CodUsuario;
END;
GO

-- =============================================================================
--  SP 9: usp_Sec_User_GetAvatar
--  Descripcion : Obtiene el avatar (base64 o URL) de un usuario.
--                Usa TRY/CATCH por si la columna Avatar no existe.
--  Parametros  :
--    @CodUsuario  NVARCHAR(60) - Codigo del usuario.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Sec_User_GetAvatar
    @CodUsuario  NVARCHAR(60)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        SELECT TOP 1 Avatar
        FROM   dbo.Usuarios
        WHERE  Cod_Usuario = @CodUsuario;
    END TRY
    BEGIN CATCH
        -- La columna Avatar podria no existir en instalaciones antiguas
        SELECT CAST(NULL AS NVARCHAR(MAX)) AS Avatar
        WHERE  1 = 0;
    END CATCH;
END;
GO

-- =============================================================================
--  SP 10: usp_Sec_User_SetAvatar
--  Descripcion : Establece o elimina el avatar de un usuario.
--                Pasar NULL en @Avatar para eliminar.
--                Usa TRY/CATCH por si la columna Avatar no existe.
--  Parametros  :
--    @CodUsuario  NVARCHAR(60)   - Codigo del usuario.
--    @Avatar      NVARCHAR(MAX)  - Datos del avatar (NULL = eliminar).
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Sec_User_SetAvatar
    @CodUsuario  NVARCHAR(60),
    @Avatar      NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        UPDATE dbo.Usuarios
        SET    Avatar = @Avatar
        WHERE  Cod_Usuario = @CodUsuario;
    END TRY
    BEGIN CATCH
        -- La columna Avatar podria no existir en instalaciones antiguas
        -- No hacer nada, simplemente ignorar el error
        RETURN;
    END CATCH;
END;
GO

-- =============================================================================
--  SP 11: usp_Sec_User_CheckExists
--  Descripcion : Verifica si un usuario existe en la tabla dbo.Usuarios.
--                Retorna el registro si existe, resultado vacio si no.
--  Parametros  :
--    @CodUsuario  NVARCHAR(60) - Codigo del usuario.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Sec_User_CheckExists
    @CodUsuario  NVARCHAR(60)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 1 Cod_Usuario
    FROM   dbo.Usuarios
    WHERE  Cod_Usuario = @CodUsuario;
END;
GO
