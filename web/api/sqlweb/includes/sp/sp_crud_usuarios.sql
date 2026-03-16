-- =============================================
-- Stored Procedures CRUD: Usuarios
-- Compatible con: SQL Server 2012+
-- Tabla canónica: sec.[User]
-- PK: UserCode nvarchar (legacy: Cod_Usuario)
-- ACTUALIZADO: referencias migradas de dbo.Usuarios a sec.[User]
-- =============================================

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_Usuarios_List')
    DROP PROCEDURE usp_Usuarios_List
GO
CREATE PROCEDURE usp_Usuarios_List
    @Search NVARCHAR(100) = NULL,
    @Tipo NVARCHAR(50) = NULL,
    @Page INT = 1,
    @Limit INT = 50,
    @TotalCount INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Offset INT = (ISNULL(NULLIF(@Page, 0), 1) - 1) * ISNULL(NULLIF(@Limit, 0), 50);
    IF @Offset < 0 SET @Offset = 0; IF @Limit < 1 SET @Limit = 50; IF @Limit > 500 SET @Limit = 500;
    DECLARE @Where NVARCHAR(MAX) = N' WHERE IsDeleted = 0';
    DECLARE @Sql NVARCHAR(MAX);
    DECLARE @Params NVARCHAR(600) = N'@Search NVARCHAR(100), @Tipo NVARCHAR(50), @Offset INT, @Limit INT, @TotalCount INT OUTPUT';
    IF @Search IS NOT NULL AND LTRIM(RTRIM(@Search)) <> N''
        SET @Where = @Where + N' AND (UserCode LIKE @Search OR UserName LIKE @Search)';
    IF @Tipo IS NOT NULL AND LTRIM(RTRIM(@Tipo)) <> N''
        SET @Where = @Where + N' AND UserType = @Tipo';
    DECLARE @SearchParam NVARCHAR(100) = NULL;
    IF @Search IS NOT NULL AND LTRIM(RTRIM(@Search)) <> N''
        SET @SearchParam = N'%' + @Search + N'%';
    SET @Sql = N'SELECT @TotalCount = COUNT(1) FROM sec.[User]' + @Where + N';
    SELECT UserCode AS Cod_Usuario, PasswordHash AS Password, UserName AS Nombre,
           UserType AS Tipo, CanUpdate AS Updates, CanCreate AS Addnews,
           CanDelete AS Deletes, IsCreator AS Creador, CanChangePwd AS Cambiar,
           CanChangePrice AS PrecioMinimo, CanGiveCredit AS Credito, IsAdmin, Avatar
    FROM sec.[User]' + @Where + N' ORDER BY UserCode OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;';
    EXEC sp_executesql @Sql, @Params, @Search = @SearchParam, @Tipo = @Tipo, @Offset = @Offset, @Limit = @Limit, @TotalCount = @TotalCount OUTPUT;
END
GO

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_Usuarios_GetByCodigo')
    DROP PROCEDURE usp_Usuarios_GetByCodigo
GO
CREATE PROCEDURE usp_Usuarios_GetByCodigo @CodUsuario NVARCHAR(50) AS
BEGIN
    SET NOCOUNT ON;
    SELECT UserCode AS Cod_Usuario, PasswordHash AS Password, UserName AS Nombre,
           UserType AS Tipo, CanUpdate AS Updates, CanCreate AS Addnews,
           CanDelete AS Deletes, IsCreator AS Creador, CanChangePwd AS Cambiar,
           CanChangePrice AS PrecioMinimo, CanGiveCredit AS Credito, IsAdmin, Avatar
    FROM sec.[User]
    WHERE UserCode = @CodUsuario AND IsDeleted = 0;
END
GO

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_Usuarios_Insert')
    DROP PROCEDURE usp_Usuarios_Insert
GO
CREATE PROCEDURE usp_Usuarios_Insert @RowXml NVARCHAR(MAX), @Resultado INT OUTPUT, @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON; SET @Resultado = 0; SET @Mensaje = N'';
    DECLARE @xml XML = CAST(@RowXml AS XML);
    BEGIN TRY
        IF EXISTS (SELECT 1 FROM sec.[User] WHERE UserCode = @xml.value('(/row/@Cod_Usuario)[1]', 'NVARCHAR(50)') AND IsDeleted = 0)
        BEGIN SET @Resultado = -1; SET @Mensaje = N'Usuario ya existe'; RETURN; END
        INSERT INTO sec.[User] (UserCode, PasswordHash, UserName, UserType,
                                CanUpdate, CanCreate, CanDelete, IsCreator,
                                CanChangePwd, CanChangePrice, CanGiveCredit,
                                IsAdmin, IsActive, CreatedAt, UpdatedAt, IsDeleted)
        SELECT NULLIF(r.value('@Cod_Usuario', 'NVARCHAR(50)'), N''),
               NULLIF(r.value('@Password', 'NVARCHAR(255)'), N''),
               NULLIF(r.value('@Nombre', 'NVARCHAR(100)'), N''),
               ISNULL(NULLIF(r.value('@Tipo', 'NVARCHAR(10)'), N''), N'USER'),
               ISNULL(r.value('@Updates', 'BIT'), 1),
               ISNULL(r.value('@Addnews', 'BIT'), 1),
               ISNULL(r.value('@Deletes', 'BIT'), 0),
               ISNULL(r.value('@Creador', 'BIT'), 0),
               ISNULL(r.value('@Cambiar', 'BIT'), 1),
               ISNULL(r.value('@PrecioMinimo', 'BIT'), 0),
               ISNULL(r.value('@Credito', 'BIT'), 0),
               ISNULL(r.value('@IsAdmin', 'BIT'), 0),
               1,
               SYSUTCDATETIME(), SYSUTCDATETIME(), 0
        FROM @xml.nodes('/row') T(r);
        SET @Resultado = 1; SET @Mensaje = N'OK';
    END TRY BEGIN CATCH SET @Resultado = -99; SET @Mensaje = ERROR_MESSAGE(); END CATCH
END
GO

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_Usuarios_Update')
    DROP PROCEDURE usp_Usuarios_Update
GO
CREATE PROCEDURE usp_Usuarios_Update @CodUsuario NVARCHAR(50), @RowXml NVARCHAR(MAX), @Resultado INT OUTPUT, @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON; SET @Resultado = 0; SET @Mensaje = N'';
    DECLARE @xml XML = CAST(@RowXml AS XML);
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM sec.[User] WHERE UserCode = @CodUsuario AND IsDeleted = 0)
        BEGIN SET @Resultado = -1; SET @Mensaje = N'Usuario no encontrado'; RETURN; END
        UPDATE u
        SET PasswordHash   = COALESCE(NULLIF(r.value('@Password',     'NVARCHAR(255)'), N''), u.PasswordHash),
            UserName       = COALESCE(NULLIF(r.value('@Nombre',       'NVARCHAR(100)'), N''), u.UserName),
            UserType       = COALESCE(NULLIF(r.value('@Tipo',         'NVARCHAR(10)'),  N''), u.UserType),
            IsAdmin        = ISNULL(r.value('@IsAdmin',    'BIT'), u.IsAdmin),
            CanUpdate      = ISNULL(r.value('@Updates',    'BIT'), u.CanUpdate),
            CanCreate      = ISNULL(r.value('@Addnews',    'BIT'), u.CanCreate),
            CanDelete      = ISNULL(r.value('@Deletes',    'BIT'), u.CanDelete),
            IsCreator      = ISNULL(r.value('@Creador',    'BIT'), u.IsCreator),
            CanChangePwd   = ISNULL(r.value('@Cambiar',    'BIT'), u.CanChangePwd),
            CanChangePrice = ISNULL(r.value('@PrecioMinimo','BIT'), u.CanChangePrice),
            CanGiveCredit  = ISNULL(r.value('@Credito',    'BIT'), u.CanGiveCredit),
            UpdatedAt      = SYSUTCDATETIME()
        FROM sec.[User] u
        CROSS JOIN @xml.nodes('/row') T(r)
        WHERE u.UserCode = @CodUsuario AND u.IsDeleted = 0;
        SET @Resultado = 1; SET @Mensaje = N'OK';
    END TRY BEGIN CATCH SET @Resultado = -99; SET @Mensaje = ERROR_MESSAGE(); END CATCH
END
GO

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_Usuarios_Delete')
    DROP PROCEDURE usp_Usuarios_Delete
GO
CREATE PROCEDURE usp_Usuarios_Delete @CodUsuario NVARCHAR(50), @Resultado INT OUTPUT, @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON; SET @Resultado = 0; SET @Mensaje = N'';
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM sec.[User] WHERE UserCode = @CodUsuario AND IsDeleted = 0)
        BEGIN SET @Resultado = -1; SET @Mensaje = N'Usuario no encontrado'; RETURN; END
        -- Soft delete via sec.[User] (equivale a IsDeleted=1, IsActive=0)
        UPDATE sec.[User]
        SET IsDeleted = 1, IsActive = 0, DeletedAt = SYSUTCDATETIME(), UpdatedAt = SYSUTCDATETIME()
        WHERE UserCode = @CodUsuario AND IsDeleted = 0;
        SET @Resultado = 1; SET @Mensaje = N'OK';
    END TRY BEGIN CATCH SET @Resultado = -99; SET @Mensaje = ERROR_MESSAGE(); END CATCH
END
GO

SELECT name, create_date FROM sys.objects WHERE type = 'P' AND name LIKE 'usp_Usuarios_%';
