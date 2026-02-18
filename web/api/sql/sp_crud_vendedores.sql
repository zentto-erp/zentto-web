-- =============================================
-- Stored Procedures CRUD: Vendedores
-- Compatible con: SQL Server 2012+
-- PK: Codigo nvarchar
-- =============================================

-- ---------- 1. List (paginado con filtros) ----------
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_Vendedores_List')
    DROP PROCEDURE usp_Vendedores_List
GO
CREATE PROCEDURE usp_Vendedores_List
    @Search NVARCHAR(100) = NULL,
    @Status BIT = NULL,
    @Tipo NVARCHAR(50) = NULL,
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
    DECLARE @Params NVARCHAR(600) = N'@Search NVARCHAR(100), @Status BIT, @Tipo NVARCHAR(50), @Offset INT, @Limit INT, @TotalCount INT OUTPUT';

    IF @Search IS NOT NULL AND LTRIM(RTRIM(@Search)) <> N''
        SET @Where = @Where + N' AND (Codigo LIKE @Search OR Nombre LIKE @Search OR Email LIKE @Search)';
    IF @Status IS NOT NULL
        SET @Where = @Where + N' AND Status = @Status';
    IF @Tipo IS NOT NULL AND LTRIM(RTRIM(@Tipo)) <> N''
        SET @Where = @Where + N' AND Tipo = @Tipo';

    IF LEN(@Where) > 0 SET @Where = N' WHERE ' + STUFF(@Where, 1, 5, N'');

    DECLARE @SearchParam NVARCHAR(100) = NULL;
    IF @Search IS NOT NULL AND LTRIM(RTRIM(@Search)) <> N''
        SET @SearchParam = N'%' + @Search + N'%';

    SET @Sql = N'
    SELECT @TotalCount = COUNT(1) FROM [dbo].[Vendedor] ' + @Where + N';
    SELECT * FROM [dbo].[Vendedor] ' + @Where + N'
    ORDER BY Codigo
    OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;';

    EXEC sp_executesql @Sql, @Params,
        @Search = @SearchParam,
        @Status = @Status,
        @Tipo = @Tipo,
        @Offset = @Offset,
        @Limit = @Limit,
        @TotalCount = @TotalCount OUTPUT;
END
GO

-- ---------- 2. Get by Codigo ----------
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_Vendedores_GetByCodigo')
    DROP PROCEDURE usp_Vendedores_GetByCodigo
GO
CREATE PROCEDURE usp_Vendedores_GetByCodigo
    @Codigo NVARCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM [dbo].[Vendedor] WHERE Codigo = @Codigo;
END
GO

-- ---------- 3. Insert ----------
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_Vendedores_Insert')
    DROP PROCEDURE usp_Vendedores_Insert
GO
CREATE PROCEDURE usp_Vendedores_Insert
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
        IF EXISTS (SELECT 1 FROM [dbo].[Vendedor] WHERE Codigo = @xml.value('(/row/@Codigo)[1]', 'NVARCHAR(10)'))
        BEGIN
            SET @Resultado = -1;
            SET @Mensaje = N'Vendedor ya existe';
            RETURN;
        END

        INSERT INTO [dbo].[Vendedor] (
            Codigo, Nombre, Comision, Direccion, Telefonos, Email,
            [Rango_ventas_Uno], [Comision_ ventas_Uno],
            [Rango_ventas_dos], [Comision_ ventas_dos],
            [Rango_ventas_tres], [Comision_ ventas_tres],
            [Rango_ventas_Cuatro], [Comision_ ventas_Cuatro],
            Status, Tipo, clave
        )
        SELECT
            NULLIF(r.value('@Codigo', 'NVARCHAR(10)'), N''),
            NULLIF(r.value('@Nombre', 'NVARCHAR(100)'), N''),
            CASE WHEN r.value('@Comision', 'NVARCHAR(50)') IS NULL OR r.value('@Comision', 'NVARCHAR(50)') = '' THEN NULL ELSE CAST(r.value('@Comision', 'NVARCHAR(50)') AS FLOAT) END,
            NULLIF(r.value('@Direccion', 'NVARCHAR(255)'), N''),
            NULLIF(r.value('@Telefonos', 'NVARCHAR(60)'), N''),
            NULLIF(r.value('@Email', 'NVARCHAR(100)'), N''),
            CASE WHEN r.value('@Rango_ventas_Uno', 'NVARCHAR(50)') IS NULL OR r.value('@Rango_ventas_Uno', 'NVARCHAR(50)') = '' THEN NULL ELSE CAST(r.value('@Rango_ventas_Uno', 'NVARCHAR(50)') AS FLOAT) END,
            CASE WHEN r.value('@Comision_ventas_Uno', 'NVARCHAR(50)') IS NULL OR r.value('@Comision_ventas_Uno', 'NVARCHAR(50)') = '' THEN NULL ELSE CAST(r.value('@Comision_ventas_Uno', 'NVARCHAR(50)') AS FLOAT) END,
            CASE WHEN r.value('@Rango_ventas_dos', 'NVARCHAR(50)') IS NULL OR r.value('@Rango_ventas_dos', 'NVARCHAR(50)') = '' THEN NULL ELSE CAST(r.value('@Rango_ventas_dos', 'NVARCHAR(50)') AS FLOAT) END,
            CASE WHEN r.value('@Comision_ventas_dos', 'NVARCHAR(50)') IS NULL OR r.value('@Comision_ventas_dos', 'NVARCHAR(50)') = '' THEN NULL ELSE CAST(r.value('@Comision_ventas_dos', 'NVARCHAR(50)') AS FLOAT) END,
            CASE WHEN r.value('@Rango_ventas_tres', 'NVARCHAR(50)') IS NULL OR r.value('@Rango_ventas_tres', 'NVARCHAR(50)') = '' THEN NULL ELSE CAST(r.value('@Rango_ventas_tres', 'NVARCHAR(50)') AS FLOAT) END,
            CASE WHEN r.value('@Comision_ventas_tres', 'NVARCHAR(50)') IS NULL OR r.value('@Comision_ventas_tres', 'NVARCHAR(50)') = '' THEN NULL ELSE CAST(r.value('@Comision_ventas_tres', 'NVARCHAR(50)') AS FLOAT) END,
            CASE WHEN r.value('@Rango_ventas_Cuatro', 'NVARCHAR(50)') IS NULL OR r.value('@Rango_ventas_Cuatro', 'NVARCHAR(50)') = '' THEN NULL ELSE CAST(r.value('@Rango_ventas_Cuatro', 'NVARCHAR(50)') AS FLOAT) END,
            CASE WHEN r.value('@Comision_ventas_Cuatro', 'NVARCHAR(50)') IS NULL OR r.value('@Comision_ventas_Cuatro', 'NVARCHAR(50)') = '' THEN NULL ELSE CAST(r.value('@Comision_ventas_Cuatro', 'NVARCHAR(50)') AS FLOAT) END,
            ISNULL(r.value('@Status', 'BIT'), 1),
            NULLIF(r.value('@Tipo', 'NVARCHAR(50)'), N''),
            NULLIF(r.value('@clave', 'NVARCHAR(50)'), N'')
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
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_Vendedores_Update')
    DROP PROCEDURE usp_Vendedores_Update
GO
CREATE PROCEDURE usp_Vendedores_Update
    @Codigo NVARCHAR(10),
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
        IF NOT EXISTS (SELECT 1 FROM [dbo].[Vendedor] WHERE Codigo = @Codigo)
        BEGIN
            SET @Resultado = -1;
            SET @Mensaje = N'Vendedor no encontrado';
            RETURN;
        END

        UPDATE v SET
            Nombre = COALESCE(NULLIF(r.value('@Nombre', 'NVARCHAR(100)'), N''), v.Nombre),
            Comision = CASE WHEN r.value('@Comision', 'NVARCHAR(50)') IS NULL OR r.value('@Comision', 'NVARCHAR(50)') = '' THEN v.Comision ELSE CAST(r.value('@Comision', 'NVARCHAR(50)') AS FLOAT) END,
            Direccion = COALESCE(NULLIF(r.value('@Direccion', 'NVARCHAR(255)'), N''), v.Direccion),
            Telefonos = COALESCE(NULLIF(r.value('@Telefonos', 'NVARCHAR(60)'), N''), v.Telefonos),
            Email = COALESCE(NULLIF(r.value('@Email', 'NVARCHAR(100)'), N''), v.Email),
            Status = ISNULL(r.value('@Status', 'BIT'), v.Status),
            Tipo = COALESCE(NULLIF(r.value('@Tipo', 'NVARCHAR(50)'), N''), v.Tipo),
            clave = COALESCE(NULLIF(r.value('@clave', 'NVARCHAR(50)'), N''), v.clave)
        FROM [dbo].[Vendedor] v
        CROSS JOIN @xml.nodes('/row') T(r)
        WHERE v.Codigo = @Codigo;

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
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_Vendedores_Delete')
    DROP PROCEDURE usp_Vendedores_Delete
GO
CREATE PROCEDURE usp_Vendedores_Delete
    @Codigo NVARCHAR(10),
    @Resultado INT OUTPUT,
    @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Resultado = 0;
    SET @Mensaje = N'';

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM [dbo].[Vendedor] WHERE Codigo = @Codigo)
        BEGIN
            SET @Resultado = -1;
            SET @Mensaje = N'Vendedor no encontrado';
            RETURN;
        END

        DELETE FROM [dbo].[Vendedor] WHERE Codigo = @Codigo;
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
SELECT name, create_date FROM sys.objects WHERE type = 'P' AND name LIKE 'usp_Vendedores_%';
