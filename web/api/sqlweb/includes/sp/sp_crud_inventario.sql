-- =============================================
-- Stored Procedures CRUD: Inventario (Productos)
-- Compatible con: SQL Server 2012+
-- Tabla canonica: master.Product (antes dbo.Inventario)
-- PK: ProductCode NVARCHAR(15) unico por CompanyId
-- Filtros: Search, Categoria, Marca, Linea, Tipo, Clase
--
-- La descripcion completa de un articulo se compone de:
--   Categoria + Tipo + ProductName + Marca + Clase
-- El campo Linea actua como departamento (ej: REPUESTOS)
-- =============================================

-- ---------- 1. List (paginado con filtros y descripcion compuesta) ----------
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_Inventario_List')
    DROP PROCEDURE usp_Inventario_List
GO
CREATE PROCEDURE usp_Inventario_List
    @Search     NVARCHAR(100) = NULL,
    @Categoria  NVARCHAR(50)  = NULL,
    @Marca      NVARCHAR(50)  = NULL,
    @Linea      NVARCHAR(30)  = NULL,
    @Tipo       NVARCHAR(50)  = NULL,
    @Clase      NVARCHAR(25)  = NULL,
    @Page       INT = 1,
    @Limit      INT = 50,
    @TotalCount INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Offset INT = (ISNULL(NULLIF(@Page, 0), 1) - 1) * ISNULL(NULLIF(@Limit, 0), 50);
    IF @Offset < 0 SET @Offset = 0;
    IF @Limit < 1  SET @Limit = 50;
    IF @Limit > 500 SET @Limit = 500;

    -- Construir clausula WHERE dinamica
    DECLARE @Where NVARCHAR(MAX) = N'';
    DECLARE @Sql   NVARCHAR(MAX);
    DECLARE @Params NVARCHAR(1000) = N'@Search NVARCHAR(100), @Categoria NVARCHAR(50), @Marca NVARCHAR(50), @Linea NVARCHAR(30), @Tipo NVARCHAR(50), @Clase NVARCHAR(25), @Offset INT, @Limit INT, @TotalCount INT OUTPUT';

    -- Filtro base: solo registros no eliminados
    SET @Where = N' AND ISNULL(IsDeleted, 0) = 0';

    -- Busqueda libre: busca en ProductCode, Referencia y todos los campos descriptivos
    IF @Search IS NOT NULL AND LTRIM(RTRIM(@Search)) <> N''
        SET @Where = @Where + N' AND (ProductCode LIKE @Search OR Referencia LIKE @Search OR ProductName LIKE @Search OR Categoria LIKE @Search OR Tipo LIKE @Search OR Marca LIKE @Search OR Clase LIKE @Search OR Linea LIKE @Search)';

    -- Filtros exactos por campo
    IF @Categoria IS NOT NULL AND LTRIM(RTRIM(@Categoria)) <> N''
        SET @Where = @Where + N' AND Categoria = @Categoria';
    IF @Marca IS NOT NULL AND LTRIM(RTRIM(@Marca)) <> N''
        SET @Where = @Where + N' AND Marca = @Marca';
    IF @Linea IS NOT NULL AND LTRIM(RTRIM(@Linea)) <> N''
        SET @Where = @Where + N' AND Linea = @Linea';
    IF @Tipo IS NOT NULL AND LTRIM(RTRIM(@Tipo)) <> N''
        SET @Where = @Where + N' AND Tipo = @Tipo';
    IF @Clase IS NOT NULL AND LTRIM(RTRIM(@Clase)) <> N''
        SET @Where = @Where + N' AND Clase = @Clase';

    SET @Where = N' WHERE ' + STUFF(@Where, 1, 5, N'');

    -- Preparar parametro de busqueda con comodines
    DECLARE @SearchParam NVARCHAR(100) = NULL;
    IF @Search IS NOT NULL AND LTRIM(RTRIM(@Search)) <> N''
        SET @SearchParam = N'%' + @Search + N'%';

    -- Descripcion compuesta: CATEGORIA + TIPO + ProductName + MARCA + CLASE
    -- Se usa LTRIM/RTRIM para eliminar espacios sobrantes
    DECLARE @DescExpr NVARCHAR(500) = N'
        LTRIM(RTRIM(
            ISNULL(RTRIM(Categoria), '''') +
            CASE WHEN RTRIM(ISNULL(Tipo, '''')) <> '''' THEN '' '' + RTRIM(Tipo) ELSE '''' END +
            CASE WHEN RTRIM(ISNULL(ProductName, '''')) <> '''' THEN '' '' + RTRIM(ProductName) ELSE '''' END +
            CASE WHEN RTRIM(ISNULL(Marca, '''')) <> '''' THEN '' '' + RTRIM(Marca) ELSE '''' END +
            CASE WHEN RTRIM(ISNULL(Clase, '''')) <> '''' THEN '' '' + RTRIM(Clase) ELSE '''' END
        ))';

    -- Contar total
    SET @Sql = N'SELECT @TotalCount = COUNT(1) FROM [master].[Product] ' + @Where + N';';

    -- Seleccionar con campo DescripcionCompleta calculado y aliases para compatibilidad
    SET @Sql = @Sql + N'
    SELECT *,
           ProductCode   AS CODIGO,
           ProductName   AS DESCRIPCION,
           StockQty      AS EXISTENCIA,
           SalesPrice    AS PRECIO,
           CostPrice     AS COSTO,
           IsService     AS Servicio,
           ' + @DescExpr + N' AS DescripcionCompleta
    FROM [master].[Product] ' + @Where + N'
    ORDER BY ProductCode
    OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;';

    EXEC sp_executesql @Sql, @Params,
        @Search    = @SearchParam,
        @Categoria = @Categoria,
        @Marca     = @Marca,
        @Linea     = @Linea,
        @Tipo      = @Tipo,
        @Clase     = @Clase,
        @Offset    = @Offset,
        @Limit     = @Limit,
        @TotalCount = @TotalCount OUTPUT;
END
GO

-- ---------- 2. Get by Codigo (incluye DescripcionCompleta) ----------
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_Inventario_GetByCodigo')
    DROP PROCEDURE usp_Inventario_GetByCodigo
GO
CREATE PROCEDURE usp_Inventario_GetByCodigo
    @Codigo NVARCHAR(15)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT *,
           ProductCode  AS CODIGO,
           ProductName  AS DESCRIPCION,
           StockQty     AS EXISTENCIA,
           SalesPrice   AS PRECIO,
           CostPrice    AS COSTO,
           IsService    AS Servicio,
           LTRIM(RTRIM(
               ISNULL(RTRIM(Categoria), '') +
               CASE WHEN RTRIM(ISNULL(Tipo, '')) <> '' THEN ' ' + RTRIM(Tipo) ELSE '' END +
               CASE WHEN RTRIM(ISNULL(ProductName, '')) <> '' THEN ' ' + RTRIM(ProductName) ELSE '' END +
               CASE WHEN RTRIM(ISNULL(Marca, '')) <> '' THEN ' ' + RTRIM(Marca) ELSE '' END +
               CASE WHEN RTRIM(ISNULL(Clase, '')) <> '' THEN ' ' + RTRIM(Clase) ELSE '' END
           )) AS DescripcionCompleta
    FROM [master].[Product]
    WHERE ProductCode = @Codigo
      AND ISNULL(IsDeleted, 0) = 0;
END
GO

-- ---------- 3. Insert (columnas principales segun schema canonico) ----------
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_Inventario_Insert')
    DROP PROCEDURE usp_Inventario_Insert
GO
CREATE PROCEDURE usp_Inventario_Insert
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
    DECLARE @CompanyId INT = (SELECT TOP 1 CompanyId FROM cfg.Company WHERE ISNULL(IsDeleted, 0) = 0 ORDER BY CompanyId);
    IF @CompanyId IS NULL SET @CompanyId = 1;

    BEGIN TRY
        IF EXISTS (SELECT 1 FROM [master].[Product] WHERE ProductCode = @xml.value('(/row/@CODIGO)[1]', 'NVARCHAR(15)') AND CompanyId = @CompanyId)
        BEGIN
            SET @Resultado = -1;
            SET @Mensaje = N'Articulo ya existe';
            RETURN;
        END

        INSERT INTO [master].[Product] (
            ProductCode, Referencia, Categoria, Marca, Tipo, Unidad, Clase, ProductName,
            StockQty, VENTA, MINIMO, MAXIMO, CostPrice, SalesPrice, PORCENTAJE,
            UBICACION, Co_Usuario, Linea, N_PARTE, Barra,
            IsService, IsActive, IsDeleted, CompanyId
        )
        SELECT
            NULLIF(r.value('@CODIGO', 'NVARCHAR(15)'), N''),
            NULLIF(r.value('@Referencia', 'NVARCHAR(30)'), N''),
            NULLIF(r.value('@Categoria', 'NVARCHAR(50)'), N''),
            NULLIF(r.value('@Marca', 'NVARCHAR(50)'), N''),
            NULLIF(r.value('@Tipo', 'NVARCHAR(50)'), N''),
            NULLIF(r.value('@Unidad', 'NVARCHAR(30)'), N''),
            NULLIF(r.value('@Clase', 'NVARCHAR(25)'), N''),
            NULLIF(r.value('@DESCRIPCION', 'NVARCHAR(255)'), N''),
            CASE WHEN r.value('@EXISTENCIA', 'NVARCHAR(50)') IS NULL OR r.value('@EXISTENCIA', 'NVARCHAR(50)') = '' THEN NULL ELSE CAST(r.value('@EXISTENCIA', 'NVARCHAR(50)') AS FLOAT) END,
            CASE WHEN r.value('@VENTA', 'NVARCHAR(50)') IS NULL OR r.value('@VENTA', 'NVARCHAR(50)') = '' THEN NULL ELSE CAST(r.value('@VENTA', 'NVARCHAR(50)') AS FLOAT) END,
            CASE WHEN r.value('@MINIMO', 'NVARCHAR(50)') IS NULL OR r.value('@MINIMO', 'NVARCHAR(50)') = '' THEN NULL ELSE CAST(r.value('@MINIMO', 'NVARCHAR(50)') AS FLOAT) END,
            CASE WHEN r.value('@MAXIMO', 'NVARCHAR(50)') IS NULL OR r.value('@MAXIMO', 'NVARCHAR(50)') = '' THEN NULL ELSE CAST(r.value('@MAXIMO', 'NVARCHAR(50)') AS FLOAT) END,
            CASE WHEN r.value('@PRECIO_COMPRA', 'NVARCHAR(50)') IS NULL OR r.value('@PRECIO_COMPRA', 'NVARCHAR(50)') = '' THEN NULL ELSE CAST(r.value('@PRECIO_COMPRA', 'NVARCHAR(50)') AS FLOAT) END,
            CASE WHEN r.value('@PRECIO_VENTA', 'NVARCHAR(50)') IS NULL OR r.value('@PRECIO_VENTA', 'NVARCHAR(50)') = '' THEN NULL ELSE CAST(r.value('@PRECIO_VENTA', 'NVARCHAR(50)') AS FLOAT) END,
            CASE WHEN r.value('@PORCENTAJE', 'NVARCHAR(50)') IS NULL OR r.value('@PORCENTAJE', 'NVARCHAR(50)') = '' THEN NULL ELSE CAST(r.value('@PORCENTAJE', 'NVARCHAR(50)') AS FLOAT) END,
            NULLIF(r.value('@UBICACION', 'NVARCHAR(40)'), N''),
            NULLIF(r.value('@Co_Usuario', 'NVARCHAR(10)'), N''),
            NULLIF(r.value('@Linea', 'NVARCHAR(30)'), N''),
            NULLIF(r.value('@N_PARTE', 'NVARCHAR(18)'), N''),
            NULLIF(r.value('@Barra', 'NVARCHAR(50)'), N''),
            ISNULL(CAST(NULLIF(r.value('@Servicio', 'NVARCHAR(5)'), '') AS BIT), 0),  -- IsService
            1,  -- IsActive
            0,  -- IsDeleted
            @CompanyId
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
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_Inventario_Update')
    DROP PROCEDURE usp_Inventario_Update
GO
CREATE PROCEDURE usp_Inventario_Update
    @Codigo NVARCHAR(15),
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
        IF NOT EXISTS (SELECT 1 FROM [master].[Product] WHERE ProductCode = @Codigo AND ISNULL(IsDeleted, 0) = 0)
        BEGIN
            SET @Resultado = -1;
            SET @Mensaje = N'Articulo no encontrado';
            RETURN;
        END

        UPDATE c SET
            Referencia = COALESCE(NULLIF(r.value('@Referencia', 'NVARCHAR(30)'), N''), c.Referencia),
            Categoria = COALESCE(NULLIF(r.value('@Categoria', 'NVARCHAR(50)'), N''), c.Categoria),
            Marca = COALESCE(NULLIF(r.value('@Marca', 'NVARCHAR(50)'), N''), c.Marca),
            Tipo = COALESCE(NULLIF(r.value('@Tipo', 'NVARCHAR(50)'), N''), c.Tipo),
            Unidad = COALESCE(NULLIF(r.value('@Unidad', 'NVARCHAR(30)'), N''), c.Unidad),
            Clase = COALESCE(NULLIF(r.value('@Clase', 'NVARCHAR(25)'), N''), c.Clase),
            ProductName = COALESCE(NULLIF(r.value('@DESCRIPCION', 'NVARCHAR(255)'), N''), c.ProductName),
            StockQty = CASE WHEN r.value('@EXISTENCIA', 'NVARCHAR(50)') IS NULL OR r.value('@EXISTENCIA', 'NVARCHAR(50)') = '' THEN c.StockQty ELSE CAST(r.value('@EXISTENCIA', 'NVARCHAR(50)') AS FLOAT) END,
            VENTA = CASE WHEN r.value('@VENTA', 'NVARCHAR(50)') IS NULL OR r.value('@VENTA', 'NVARCHAR(50)') = '' THEN c.VENTA ELSE CAST(r.value('@VENTA', 'NVARCHAR(50)') AS FLOAT) END,
            MINIMO = CASE WHEN r.value('@MINIMO', 'NVARCHAR(50)') IS NULL OR r.value('@MINIMO', 'NVARCHAR(50)') = '' THEN c.MINIMO ELSE CAST(r.value('@MINIMO', 'NVARCHAR(50)') AS FLOAT) END,
            MAXIMO = CASE WHEN r.value('@MAXIMO', 'NVARCHAR(50)') IS NULL OR r.value('@MAXIMO', 'NVARCHAR(50)') = '' THEN c.MAXIMO ELSE CAST(r.value('@MAXIMO', 'NVARCHAR(50)') AS FLOAT) END,
            CostPrice = CASE WHEN r.value('@PRECIO_COMPRA', 'NVARCHAR(50)') IS NULL OR r.value('@PRECIO_COMPRA', 'NVARCHAR(50)') = '' THEN c.CostPrice ELSE CAST(r.value('@PRECIO_COMPRA', 'NVARCHAR(50)') AS FLOAT) END,
            SalesPrice = CASE WHEN r.value('@PRECIO_VENTA', 'NVARCHAR(50)') IS NULL OR r.value('@PRECIO_VENTA', 'NVARCHAR(50)') = '' THEN c.SalesPrice ELSE CAST(r.value('@PRECIO_VENTA', 'NVARCHAR(50)') AS FLOAT) END,
            PORCENTAJE = CASE WHEN r.value('@PORCENTAJE', 'NVARCHAR(50)') IS NULL OR r.value('@PORCENTAJE', 'NVARCHAR(50)') = '' THEN c.PORCENTAJE ELSE CAST(r.value('@PORCENTAJE', 'NVARCHAR(50)') AS FLOAT) END,
            UBICACION = COALESCE(NULLIF(r.value('@UBICACION', 'NVARCHAR(40)'), N''), c.UBICACION),
            Co_Usuario = COALESCE(NULLIF(r.value('@Co_Usuario', 'NVARCHAR(10)'), N''), c.Co_Usuario),
            Linea = COALESCE(NULLIF(r.value('@Linea', 'NVARCHAR(30)'), N''), c.Linea),
            N_PARTE = COALESCE(NULLIF(r.value('@N_PARTE', 'NVARCHAR(18)'), N''), c.N_PARTE),
            Barra = COALESCE(NULLIF(r.value('@Barra', 'NVARCHAR(50)'), N''), c.Barra)
        FROM [master].[Product] c
        CROSS JOIN @xml.nodes('/row') T(r)
        WHERE c.ProductCode = @Codigo AND ISNULL(c.IsDeleted, 0) = 0;

        SET @Resultado = 1;
        SET @Mensaje = N'OK';
    END TRY
    BEGIN CATCH
        SET @Resultado = -99;
        SET @Mensaje = ERROR_MESSAGE();
    END CATCH
END
GO

-- ---------- 5. Delete (soft delete via IsDeleted) ----------
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_Inventario_Delete')
    DROP PROCEDURE usp_Inventario_Delete
GO
CREATE PROCEDURE usp_Inventario_Delete
    @Codigo NVARCHAR(15),
    @Resultado INT OUTPUT,
    @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Resultado = 0;
    SET @Mensaje = N'';

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM [master].[Product] WHERE ProductCode = @Codigo AND ISNULL(IsDeleted, 0) = 0)
        BEGIN
            SET @Resultado = -1;
            SET @Mensaje = N'Articulo no encontrado';
            RETURN;
        END

        UPDATE [master].[Product]
        SET IsDeleted = 1, IsActive = 0
        WHERE ProductCode = @Codigo;

        SET @Resultado = 1;
        SET @Mensaje = N'OK';
    END TRY
    BEGIN CATCH
        SET @Resultado = -99;
        SET @Mensaje = ERROR_MESSAGE();
    END CATCH
END
GO

SELECT name, create_date FROM sys.objects WHERE type = 'P' AND name LIKE 'usp_Inventario_%';
