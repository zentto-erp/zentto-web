-- =============================================
-- Stored Procedures CRUD: Categorias
-- Compatible con: SQL Server 2012+
-- PK: Codigo int (IDENTITY)
-- =============================================

-- ---------- 1. List (paginado con filtros) ----------
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_Categorias_List')
    DROP PROCEDURE usp_Categorias_List
GO
CREATE PROCEDURE usp_Categorias_List
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
        SET @Where = @Where + N' AND (Nombre LIKE @Search OR Codigo LIKE @Search)';

    IF LEN(@Where) > 0 SET @Where = N' WHERE ' + STUFF(@Where, 1, 5, N'');

    DECLARE @SearchParam NVARCHAR(100) = NULL;
    IF @Search IS NOT NULL AND LTRIM(RTRIM(@Search)) <> N''
        SET @SearchParam = N'%' + @Search + N'%';

    SET @Sql = N'
    SELECT @TotalCount = COUNT(1) FROM [dbo].[Categoria] ' + @Where + N';
    SELECT * FROM [dbo].[Categoria] ' + @Where + N'
    ORDER BY Codigo
    OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;';

    EXEC sp_executesql @Sql, @Params,
        @Search = @SearchParam,
        @Offset = @Offset,
        @Limit = @Limit,
        @TotalCount = @TotalCount OUTPUT;
END
GO

-- ---------- 2. Get by Codigo ----------
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_Categorias_GetByCodigo')
    DROP PROCEDURE usp_Categorias_GetByCodigo
GO
CREATE PROCEDURE usp_Categorias_GetByCodigo
    @Codigo INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM [dbo].[Categoria] WHERE Codigo = @Codigo;
END
GO

-- ---------- 3. Insert ----------
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_Categorias_Insert')
    DROP PROCEDURE usp_Categorias_Insert
GO
CREATE PROCEDURE usp_Categorias_Insert
    @RowXml NVARCHAR(MAX),
    @Resultado INT OUTPUT,
    @Mensaje NVARCHAR(500) OUTPUT,
    @NuevoCodigo INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET @Resultado = 0;
    SET @Mensaje = N'';
    SET @NuevoCodigo = 0;

    DECLARE @xml XML = CAST(@RowXml AS XML);

    BEGIN TRY
        INSERT INTO [dbo].[Categoria] (
            Nombre, Co_Usuario
        )
        SELECT
            NULLIF(r.value('@Nombre', 'NVARCHAR(50)'), N''),
            NULLIF(r.value('@Co_Usuario', 'NVARCHAR(10)'), N'')
        FROM @xml.nodes('/row') T(r);

        SET @NuevoCodigo = SCOPE_IDENTITY();
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
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_Categorias_Update')
    DROP PROCEDURE usp_Categorias_Update
GO
CREATE PROCEDURE usp_Categorias_Update
    @Codigo INT,
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
        IF NOT EXISTS (SELECT 1 FROM [dbo].[Categoria] WHERE Codigo = @Codigo)
        BEGIN
            SET @Resultado = -1;
            SET @Mensaje = N'Categoría no encontrada';
            RETURN;
        END

        UPDATE c SET
            Nombre = COALESCE(NULLIF(r.value('@Nombre', 'NVARCHAR(50)'), N''), c.Nombre),
            Co_Usuario = COALESCE(NULLIF(r.value('@Co_Usuario', 'NVARCHAR(10)'), N''), c.Co_Usuario)
        FROM [dbo].[Categoria] c
        CROSS JOIN @xml.nodes('/row') T(r)
        WHERE c.Codigo = @Codigo;

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
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_Categorias_Delete')
    DROP PROCEDURE usp_Categorias_Delete
GO
CREATE PROCEDURE usp_Categorias_Delete
    @Codigo INT,
    @Resultado INT OUTPUT,
    @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Resultado = 0;
    SET @Mensaje = N'';

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM [dbo].[Categoria] WHERE Codigo = @Codigo)
        BEGIN
            SET @Resultado = -1;
            SET @Mensaje = N'Categoría no encontrada';
            RETURN;
        END

        DELETE FROM [dbo].[Categoria] WHERE Codigo = @Codigo;
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
SELECT name, create_date FROM sys.objects WHERE type = 'P' AND name LIKE 'usp_Categorias_%';
