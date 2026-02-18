-- =============================================
-- Stored Procedures CRUD: Usuarios
-- Compatible con: SQL Server 2012+
-- PK: Cod_Usuario nvarchar
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
    DECLARE @Where NVARCHAR(MAX) = N''; DECLARE @Sql NVARCHAR(MAX);
    DECLARE @Params NVARCHAR(600) = N'@Search NVARCHAR(100), @Tipo NVARCHAR(50), @Offset INT, @Limit INT, @TotalCount INT OUTPUT';
    IF @Search IS NOT NULL AND LTRIM(RTRIM(@Search)) <> N''
        SET @Where = @Where + N' AND (Cod_Usuario LIKE @Search OR Nombre LIKE @Search)';
    IF @Tipo IS NOT NULL AND LTRIM(RTRIM(@Tipo)) <> N''
        SET @Where = @Where + N' AND Tipo = @Tipo';
    IF LEN(@Where) > 0 SET @Where = N' WHERE ' + STUFF(@Where, 1, 5, N'');
    DECLARE @SearchParam NVARCHAR(100) = NULL;
    IF @Search IS NOT NULL AND LTRIM(RTRIM(@Search)) <> N''
        SET @SearchParam = N'%' + @Search + N'%';
    SET @Sql = N'SELECT @TotalCount = COUNT(1) FROM [dbo].[Usuarios]' + @Where + N';
    SELECT * FROM [dbo].[Usuarios]' + @Where + N' ORDER BY Cod_Usuario OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;';
    EXEC sp_executesql @Sql, @Params, @Search = @SearchParam, @Tipo = @Tipo, @Offset = @Offset, @Limit = @Limit, @TotalCount = @TotalCount OUTPUT;
END
GO

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_Usuarios_GetByCodigo')
    DROP PROCEDURE usp_Usuarios_GetByCodigo
GO
CREATE PROCEDURE usp_Usuarios_GetByCodigo @CodUsuario NVARCHAR(10) AS
BEGIN SET NOCOUNT ON; SELECT * FROM [dbo].[Usuarios] WHERE Cod_Usuario = @CodUsuario; END
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
        IF EXISTS (SELECT 1 FROM [dbo].[Usuarios] WHERE Cod_Usuario = @xml.value('(/row/@Cod_Usuario)[1]', 'NVARCHAR(10)'))
        BEGIN SET @Resultado = -1; SET @Mensaje = N'Usuario ya existe'; RETURN; END
        INSERT INTO [dbo].[Usuarios] (Cod_Usuario, Password, Nombre, Tipo, Updates, Addnews, Deletes, Creador, Cambiar, PrecioMinimo, Credito)
        SELECT NULLIF(r.value('@Cod_Usuario', 'NVARCHAR(10)'), N''),
               NULLIF(r.value('@Password', 'NVARCHAR(50)'), N''),
               NULLIF(r.value('@Nombre', 'NVARCHAR(100)'), N''),
               NULLIF(r.value('@Tipo', 'NVARCHAR(50)'), N''),
               ISNULL(r.value('@Updates', 'BIT'), 0),
               ISNULL(r.value('@Addnews', 'BIT'), 0),
               ISNULL(r.value('@Deletes', 'BIT'), 0),
               ISNULL(r.value('@Creador', 'BIT'), 0),
               ISNULL(r.value('@Cambiar', 'BIT'), 0),
               ISNULL(r.value('@PrecioMinimo', 'BIT'), 0),
               ISNULL(r.value('@Credito', 'BIT'), 0)
        FROM @xml.nodes('/row') T(r);
        SET @Resultado = 1; SET @Mensaje = N'OK';
    END TRY BEGIN CATCH SET @Resultado = -99; SET @Mensaje = ERROR_MESSAGE(); END CATCH
END
GO

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_Usuarios_Update')
    DROP PROCEDURE usp_Usuarios_Update
GO
CREATE PROCEDURE usp_Usuarios_Update @CodUsuario NVARCHAR(10), @RowXml NVARCHAR(MAX), @Resultado INT OUTPUT, @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON; SET @Resultado = 0; SET @Mensaje = N'';
    DECLARE @xml XML = CAST(@RowXml AS XML);
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM [dbo].[Usuarios] WHERE Cod_Usuario = @CodUsuario) BEGIN SET @Resultado = -1; SET @Mensaje = N'Usuario no encontrado'; RETURN; END
        UPDATE u SET Password = COALESCE(NULLIF(r.value('@Password', 'NVARCHAR(255)'), N''), u.Password),
                     Nombre = COALESCE(NULLIF(r.value('@Nombre', 'NVARCHAR(50)'), N''), u.Nombre),
                     Tipo = COALESCE(NULLIF(r.value('@Tipo', 'NVARCHAR(10)'), N''), u.Tipo),
                     IsAdmin = ISNULL(r.value('@IsAdmin', 'BIT'), u.IsAdmin),
                     Updates = ISNULL(r.value('@Updates', 'BIT'), u.Updates),
                     Addnews = ISNULL(r.value('@Addnews', 'BIT'), u.Addnews),
                     Deletes = ISNULL(r.value('@Deletes', 'BIT'), u.Deletes),
                     Creador = ISNULL(r.value('@Creador', 'BIT'), u.Creador),
                     Cambiar = ISNULL(r.value('@Cambiar', 'BIT'), u.Cambiar),
                     PrecioMinimo = ISNULL(r.value('@PrecioMinimo', 'BIT'), u.PrecioMinimo),
                     Credito = ISNULL(r.value('@Credito', 'BIT'), u.Credito)
        FROM [dbo].[Usuarios] u CROSS JOIN @xml.nodes('/row') T(r) WHERE u.Cod_Usuario = @CodUsuario;
        SET @Resultado = 1; SET @Mensaje = N'OK';
    END TRY BEGIN CATCH SET @Resultado = -99; SET @Mensaje = ERROR_MESSAGE(); END CATCH
END
GO

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_Usuarios_Delete')
    DROP PROCEDURE usp_Usuarios_Delete
GO
CREATE PROCEDURE usp_Usuarios_Delete @CodUsuario NVARCHAR(10), @Resultado INT OUTPUT, @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON; SET @Resultado = 0; SET @Mensaje = N'';
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM [dbo].[Usuarios] WHERE Cod_Usuario = @CodUsuario) BEGIN SET @Resultado = -1; SET @Mensaje = N'Usuario no encontrado'; RETURN; END
        DELETE FROM [dbo].[Usuarios] WHERE Cod_Usuario = @CodUsuario; SET @Resultado = 1; SET @Mensaje = N'OK';
    END TRY BEGIN CATCH SET @Resultado = -99; SET @Mensaje = ERROR_MESSAGE(); END CATCH
END
GO

SELECT name, create_date FROM sys.objects WHERE type = 'P' AND name LIKE 'usp_Usuarios_%';
