-- =============================================
-- Stored Procedures CRUD: Bancos
-- Compatible con: SQL Server 2012+
-- PK: Nombre nvarchar
-- =============================================

-- ---------- 1. List (paginado con filtros) ----------
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_Bancos_List')
    DROP PROCEDURE usp_Bancos_List
GO
CREATE PROCEDURE usp_Bancos_List
    @Search NVARCHAR(100) = NULL,
    @Page INT = 1,
    @Limit INT = 50,
    @TotalCount INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Offset INT = (ISNULL(NULLIF(@Page, 0), 1) - 1) * ISNULL(NULLIF(@Limit, 0), 50);
    IF @Offset < 0 SET @Offset = 0;
    IF @Limit < 1 SET @Limit = 50;
    IF @Limit > 500 SET @Limit = 500;

    DECLARE @Where NVARCHAR(MAX) = N'';
    DECLARE @Sql NVARCHAR(MAX);
    DECLARE @Params NVARCHAR(500) = N'@Search NVARCHAR(100), @Offset INT, @Limit INT, @TotalCount INT OUTPUT';

    IF @Search IS NOT NULL AND LTRIM(RTRIM(@Search)) <> N''
        SET @Where = @Where + N' AND (Nombre LIKE @Search OR Contacto LIKE @Search)';

    IF LEN(@Where) > 0 SET @Where = N' WHERE ' + STUFF(@Where, 1, 5, N'');

    DECLARE @SearchParam NVARCHAR(100) = NULL;
    IF @Search IS NOT NULL AND LTRIM(RTRIM(@Search)) <> N''
        SET @SearchParam = N'%' + @Search + N'%';

    SET @Sql = N'
    SELECT @TotalCount = COUNT(1) FROM [dbo].[Bancos] ' + @Where + N';
    SELECT * FROM [dbo].[Bancos] ' + @Where + N'
    ORDER BY Nombre
    OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;';

    EXEC sp_executesql @Sql, @Params,
        @Search = @SearchParam,
        @Offset = @Offset,
        @Limit = @Limit,
        @TotalCount = @TotalCount OUTPUT;
END
GO

-- ---------- 2. Get by Nombre ----------
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_Bancos_GetByNombre')
    DROP PROCEDURE usp_Bancos_GetByNombre
GO
CREATE PROCEDURE usp_Bancos_GetByNombre
    @Nombre NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM [dbo].[Bancos] WHERE Nombre = @Nombre;
END
GO

-- ---------- 3. Insert ----------
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_Bancos_Insert')
    DROP PROCEDURE usp_Bancos_Insert
GO
CREATE PROCEDURE usp_Bancos_Insert
    @RowXml NVARCHAR(MAX),
    @Resultado INT OUTPUT,
    @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET @Resultado = 0;
    SET @Mensaje = N'';

    DECLARE @xml XML = CAST(@RowXml AS XML);

    BEGIN TRY
        IF EXISTS (SELECT 1 FROM [dbo].[Bancos] WHERE Nombre = @xml.value('(/row/@Nombre)[1]', 'NVARCHAR(50)'))
        BEGIN
            SET @Resultado = -1;
            SET @Mensaje = N'Banco ya existe';
            RETURN;
        END

        INSERT INTO [dbo].[Bancos] (
            Nombre, Contacto, Direccion, Telefonos, Co_Usuario
        )
        SELECT
            NULLIF(r.value('@Nombre', 'NVARCHAR(50)'), N''),
            NULLIF(r.value('@Contacto', 'NVARCHAR(50)'), N''),
            NULLIF(r.value('@Direccion', 'NVARCHAR(255)'), N''),
            NULLIF(r.value('@Telefonos', 'NVARCHAR(60)'), N''),
            NULLIF(r.value('@Co_Usuario', 'NVARCHAR(10)'), N'')
        FROM @xml.nodes('/row') T(r);

        SET @Resultado = 1;
        SET @Mensaje = N'OK';
    END TRY
    BEGIN CATCH
        SET @Resultado = -99;
        SET @Mensaje = ERROR_MESSAGE();
    END CATCH
END
GO

-- ---------- 4. Update ----------
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_Bancos_Update')
    DROP PROCEDURE usp_Bancos_Update
GO
CREATE PROCEDURE usp_Bancos_Update
    @Nombre NVARCHAR(50),
    @RowXml NVARCHAR(MAX),
    @Resultado INT OUTPUT,
    @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Resultado = 0;
    SET @Mensaje = N'';

    DECLARE @xml XML = CAST(@RowXml AS XML);

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM [dbo].[Bancos] WHERE Nombre = @Nombre)
        BEGIN
            SET @Resultado = -1;
            SET @Mensaje = N'Banco no encontrado';
            RETURN;
        END

        UPDATE b SET
            Contacto = COALESCE(NULLIF(r.value('@Contacto', 'NVARCHAR(50)'), N''), b.Contacto),
            Direccion = COALESCE(NULLIF(r.value('@Direccion', 'NVARCHAR(255)'), N''), b.Direccion),
            Telefonos = COALESCE(NULLIF(r.value('@Telefonos', 'NVARCHAR(60)'), N''), b.Telefonos),
            Co_Usuario = COALESCE(NULLIF(r.value('@Co_Usuario', 'NVARCHAR(10)'), N''), b.Co_Usuario)
        FROM [dbo].[Bancos] b
        CROSS JOIN @xml.nodes('/row') T(r)
        WHERE b.Nombre = @Nombre;

        SET @Resultado = 1;
        SET @Mensaje = N'OK';
    END TRY
    BEGIN CATCH
        SET @Resultado = -99;
        SET @Mensaje = ERROR_MESSAGE();
    END CATCH
END
GO

-- ---------- 5. Delete ----------
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_Bancos_Delete')
    DROP PROCEDURE usp_Bancos_Delete
GO
CREATE PROCEDURE usp_Bancos_Delete
    @Nombre NVARCHAR(50),
    @Resultado INT OUTPUT,
    @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Resultado = 0;
    SET @Mensaje = N'';

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM [dbo].[Bancos] WHERE Nombre = @Nombre)
        BEGIN
            SET @Resultado = -1;
            SET @Mensaje = N'Banco no encontrado';
            RETURN;
        END

        DELETE FROM [dbo].[Bancos] WHERE Nombre = @Nombre;
        SET @Resultado = 1;
        SET @Mensaje = N'OK';
    END TRY
    BEGIN CATCH
        SET @Resultado = -99;
        SET @Mensaje = ERROR_MESSAGE();
    END CATCH
END
GO

-- Verificar
SELECT name, create_date FROM sys.objects WHERE type = 'P' AND name LIKE 'usp_Bancos_%';
