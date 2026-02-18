-- =============================================
-- Stored Procedures CRUD: Clientes
-- Compatible con: SQL Server 2012+
-- Uso: listar, obtener por codigo, insertar, actualizar, eliminar
-- =============================================

-- ---------- 1. List (paginado con filtros) ----------
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_Clientes_List')
    DROP PROCEDURE usp_Clientes_List
GO
CREATE PROCEDURE usp_Clientes_List
    @Search NVARCHAR(100) = NULL,
    @Estado NVARCHAR(20) = NULL,
    @Vendedor NVARCHAR(60) = NULL,
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
    DECLARE @Params NVARCHAR(500) = N'@Search NVARCHAR(100), @Estado NVARCHAR(20), @Vendedor NVARCHAR(60), @Offset INT, @Limit INT, @TotalCount INT OUTPUT';

    IF @Search IS NOT NULL AND LTRIM(RTRIM(@Search)) <> N''
        SET @Where = @Where + N' AND (CODIGO LIKE @Search OR NOMBRE LIKE @Search OR RIF LIKE @Search)';
    IF @Estado IS NOT NULL AND LTRIM(RTRIM(@Estado)) <> N''
        SET @Where = @Where + N' AND ESTADO = @Estado';
    IF @Vendedor IS NOT NULL AND LTRIM(RTRIM(@Vendedor)) <> N''
        SET @Where = @Where + N' AND VENDEDOR = @Vendedor';

    IF LEN(@Where) > 0 SET @Where = N' WHERE ' + STUFF(@Where, 1, 5, N'');

    DECLARE @SearchParam NVARCHAR(100) = NULL;
    IF @Search IS NOT NULL AND LTRIM(RTRIM(@Search)) <> N''
        SET @SearchParam = N'%' + @Search + N'%';

    SET @Sql = N'
    SELECT @TotalCount = COUNT(1) FROM [dbo].[Clientes] ' + @Where + N';
    SELECT * FROM [dbo].[Clientes] ' + @Where + N'
    ORDER BY CODIGO
    OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;';

    EXEC sp_executesql @Sql, @Params,
        @Search = @SearchParam,
        @Estado = @Estado,
        @Vendedor = @Vendedor,
        @Offset = @Offset,
        @Limit = @Limit,
        @TotalCount = @TotalCount OUTPUT;
END
GO

-- ---------- 2. Get by Codigo ----------
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_Clientes_GetByCodigo')
    DROP PROCEDURE usp_Clientes_GetByCodigo
GO
CREATE PROCEDURE usp_Clientes_GetByCodigo
    @Codigo NVARCHAR(12)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM [dbo].[Clientes] WHERE CODIGO = @Codigo;
END
GO

-- ---------- 3. Insert (fila como XML) ----------
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_Clientes_Insert')
    DROP PROCEDURE usp_Clientes_Insert
GO
CREATE PROCEDURE usp_Clientes_Insert
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
        IF EXISTS (SELECT 1 FROM [dbo].[Clientes] WHERE CODIGO = @xml.value('(/row/@CODIGO)[1]', 'NVARCHAR(12)'))
        BEGIN
            SET @Resultado = -1;
            SET @Mensaje = N'Cliente ya existe';
            RETURN;
        END

        INSERT INTO [dbo].[Clientes] (
            CODIGO, NOMBRE, RIF, NIT, DIRECCION, DIRECCION1, SUCURSAL, TELEFONO,
            CONTACTO, VENDEDOR, ESTADO, CIUDAD, CPOSTAL, EMAIL, PAGINA_WWW,
            COD_USUARIO, LIMITE, CREDITO, LISTA_PRECIO
        )
        SELECT
            NULLIF(r.value('@CODIGO', 'NVARCHAR(12)'), N''),
            NULLIF(r.value('@NOMBRE', 'NVARCHAR(255)'), N''),
            NULLIF(r.value('@RIF', 'NVARCHAR(20)'), N''),
            NULLIF(r.value('@NIT', 'NVARCHAR(20)'), N''),
            NULLIF(r.value('@DIRECCION', 'NVARCHAR(255)'), N''),
            NULLIF(r.value('@DIRECCION1', 'NVARCHAR(50)'), N''),
            NULLIF(r.value('@SUCURSAL', 'NVARCHAR(50)'), N''),
            NULLIF(r.value('@TELEFONO', 'NVARCHAR(60)'), N''),
            NULLIF(r.value('@CONTACTO', 'NVARCHAR(30)'), N''),
            NULLIF(r.value('@VENDEDOR', 'NVARCHAR(4)'), N''),
            NULLIF(r.value('@ESTADO', 'NVARCHAR(20)'), N''),
            NULLIF(r.value('@CIUDAD', 'NVARCHAR(20)'), N''),
            NULLIF(r.value('@CPOSTAL', 'NVARCHAR(10)'), N''),
            NULLIF(r.value('@EMAIL', 'NVARCHAR(50)'), N''),
            NULLIF(r.value('@PAGINA_WWW', 'NVARCHAR(50)'), N''),
            NULLIF(r.value('@COD_USUARIO', 'NVARCHAR(10)'), N''),
            CASE WHEN r.value('@LIMITE', 'NVARCHAR(50)') IS NULL OR r.value('@LIMITE', 'NVARCHAR(50)') = '' THEN NULL ELSE CAST(r.value('@LIMITE', 'NVARCHAR(50)') AS FLOAT) END,
            CASE WHEN r.value('@CREDITO', 'NVARCHAR(50)') IS NULL OR r.value('@CREDITO', 'NVARCHAR(50)') = '' THEN NULL ELSE CAST(r.value('@CREDITO', 'NVARCHAR(50)') AS FLOAT) END,
            CASE WHEN r.value('@LISTA_PRECIO', 'NVARCHAR(50)') IS NULL OR r.value('@LISTA_PRECIO', 'NVARCHAR(50)') = '' THEN 0 ELSE CAST(r.value('@LISTA_PRECIO', 'NVARCHAR(50)') AS INT) END
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
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_Clientes_Update')
    DROP PROCEDURE usp_Clientes_Update
GO
CREATE PROCEDURE usp_Clientes_Update
    @Codigo NVARCHAR(12),
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
        IF NOT EXISTS (SELECT 1 FROM [dbo].[Clientes] WHERE CODIGO = @Codigo)
        BEGIN
            SET @Resultado = -1;
            SET @Mensaje = N'Cliente no encontrado';
            RETURN;
        END

        UPDATE c SET
            NOMBRE = COALESCE(NULLIF(r.value('@NOMBRE', 'NVARCHAR(255)'), N''), c.NOMBRE),
            RIF = COALESCE(NULLIF(r.value('@RIF', 'NVARCHAR(20)'), N''), c.RIF),
            NIT = COALESCE(NULLIF(r.value('@NIT', 'NVARCHAR(20)'), N''), c.NIT),
            DIRECCION = COALESCE(NULLIF(r.value('@DIRECCION', 'NVARCHAR(255)'), N''), c.DIRECCION),
            DIRECCION1 = COALESCE(NULLIF(r.value('@DIRECCION1', 'NVARCHAR(50)'), N''), c.DIRECCION1),
            SUCURSAL = COALESCE(NULLIF(r.value('@SUCURSAL', 'NVARCHAR(50)'), N''), c.SUCURSAL),
            TELEFONO = COALESCE(NULLIF(r.value('@TELEFONO', 'NVARCHAR(60)'), N''), c.TELEFONO),
            CONTACTO = COALESCE(NULLIF(r.value('@CONTACTO', 'NVARCHAR(30)'), N''), c.CONTACTO),
            VENDEDOR = COALESCE(NULLIF(r.value('@VENDEDOR', 'NVARCHAR(4)'), N''), c.VENDEDOR),
            ESTADO = COALESCE(NULLIF(r.value('@ESTADO', 'NVARCHAR(20)'), N''), c.ESTADO),
            CIUDAD = COALESCE(NULLIF(r.value('@CIUDAD', 'NVARCHAR(20)'), N''), c.CIUDAD),
            CPOSTAL = COALESCE(NULLIF(r.value('@CPOSTAL', 'NVARCHAR(10)'), N''), c.CPOSTAL),
            EMAIL = COALESCE(NULLIF(r.value('@EMAIL', 'NVARCHAR(50)'), N''), c.EMAIL),
            PAGINA_WWW = COALESCE(NULLIF(r.value('@PAGINA_WWW', 'NVARCHAR(50)'), N''), c.PAGINA_WWW),
            COD_USUARIO = COALESCE(NULLIF(r.value('@COD_USUARIO', 'NVARCHAR(10)'), N''), c.COD_USUARIO),
            LIMITE = CASE WHEN r.value('@LIMITE', 'NVARCHAR(50)') IS NULL OR r.value('@LIMITE', 'NVARCHAR(50)') = '' THEN c.LIMITE ELSE CAST(r.value('@LIMITE', 'NVARCHAR(50)') AS FLOAT) END,
            CREDITO = CASE WHEN r.value('@CREDITO', 'NVARCHAR(50)') IS NULL OR r.value('@CREDITO', 'NVARCHAR(50)') = '' THEN c.CREDITO ELSE CAST(r.value('@CREDITO', 'NVARCHAR(50)') AS FLOAT) END,
            LISTA_PRECIO = CASE WHEN r.value('@LISTA_PRECIO', 'NVARCHAR(50)') IS NULL OR r.value('@LISTA_PRECIO', 'NVARCHAR(50)') = '' THEN c.LISTA_PRECIO ELSE CAST(r.value('@LISTA_PRECIO', 'NVARCHAR(50)') AS INT) END
        FROM [dbo].[Clientes] c
        CROSS JOIN @xml.nodes('/row') T(r)
        WHERE c.CODIGO = @Codigo;

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
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_Clientes_Delete')
    DROP PROCEDURE usp_Clientes_Delete
GO
CREATE PROCEDURE usp_Clientes_Delete
    @Codigo NVARCHAR(12),
    @Resultado INT OUTPUT,
    @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Resultado = 0;
    SET @Mensaje = N'';

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM [dbo].[Clientes] WHERE CODIGO = @Codigo)
        BEGIN
            SET @Resultado = -1;
            SET @Mensaje = N'Cliente no encontrado';
            RETURN;
        END

        DELETE FROM [dbo].[Clientes] WHERE CODIGO = @Codigo;
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
SELECT name, create_date FROM sys.objects WHERE type = 'P' AND name LIKE 'usp_Clientes_%';
