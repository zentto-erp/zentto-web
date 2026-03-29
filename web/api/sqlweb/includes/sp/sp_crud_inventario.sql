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
    @CompanyId INT = NULL,
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
    IF @CompanyId IS NULL
        SET @CompanyId = (SELECT TOP 1 CompanyId FROM cfg.Company WHERE ISNULL(IsDeleted, 0) = 0 ORDER BY CompanyId);
    IF @CompanyId IS NULL SET @CompanyId = 1;

    DECLARE @Codigo NVARCHAR(15) = @xml.value('(/row/@CODIGO)[1]', 'NVARCHAR(15)');
    IF @Codigo IS NULL OR @Codigo = N''
    BEGIN
        SET @Resultado = -1;
        SET @Mensaje = N'Codigo es requerido';
        RETURN;
    END

    BEGIN TRY
        IF EXISTS (SELECT 1 FROM [master].[Product] WHERE ProductCode = @Codigo AND CompanyId = @CompanyId)
        BEGIN
            SET @Resultado = -1;
            SET @Mensaje = N'Articulo ya existe';
            RETURN;
        END

        INSERT INTO [master].[Product] (
            ProductCode, Referencia, Categoria, Marca, Tipo, Unidad, Clase, ProductName,
            StockQty, VENTA, MINIMO, MAXIMO, CostPrice, SalesPrice, PORCENTAJE,
            UBICACION, Co_Usuario, Linea, N_PARTE, Barra,
            IsService, IsActive, IsDeleted, CompanyId, Descripcion
        )
        SELECT
            @Codigo,
            NULLIF(r.value('@Referencia', 'NVARCHAR(30)'), N''),
            NULLIF(r.value('@Categoria', 'NVARCHAR(50)'), N''),
            NULLIF(r.value('@Marca', 'NVARCHAR(50)'), N''),
            NULLIF(r.value('@Tipo', 'NVARCHAR(50)'), N''),
            NULLIF(r.value('@Unidad', 'NVARCHAR(30)'), N''),
            NULLIF(r.value('@Clase', 'NVARCHAR(25)'), N''),
            NULLIF(r.value('@DESCRIPCION', 'NVARCHAR(255)'), N''),
            CASE WHEN r.value('@EXISTENCIA', 'NVARCHAR(50)') IS NULL OR r.value('@EXISTENCIA', 'NVARCHAR(50)') = '' THEN 0 ELSE CAST(r.value('@EXISTENCIA', 'NVARCHAR(50)') AS FLOAT) END,
            CASE WHEN r.value('@VENTA', 'NVARCHAR(50)') IS NULL OR r.value('@VENTA', 'NVARCHAR(50)') = '' THEN 0 ELSE CAST(r.value('@VENTA', 'NVARCHAR(50)') AS FLOAT) END,
            CASE WHEN r.value('@MINIMO', 'NVARCHAR(50)') IS NULL OR r.value('@MINIMO', 'NVARCHAR(50)') = '' THEN 0 ELSE CAST(r.value('@MINIMO', 'NVARCHAR(50)') AS FLOAT) END,
            CASE WHEN r.value('@MAXIMO', 'NVARCHAR(50)') IS NULL OR r.value('@MAXIMO', 'NVARCHAR(50)') = '' THEN 0 ELSE CAST(r.value('@MAXIMO', 'NVARCHAR(50)') AS FLOAT) END,
            CASE WHEN r.value('@PRECIO_COMPRA', 'NVARCHAR(50)') IS NULL OR r.value('@PRECIO_COMPRA', 'NVARCHAR(50)') = '' THEN 0 ELSE CAST(r.value('@PRECIO_COMPRA', 'NVARCHAR(50)') AS FLOAT) END,
            CASE WHEN r.value('@PRECIO_VENTA', 'NVARCHAR(50)') IS NULL OR r.value('@PRECIO_VENTA', 'NVARCHAR(50)') = '' THEN 0 ELSE CAST(r.value('@PRECIO_VENTA', 'NVARCHAR(50)') AS FLOAT) END,
            CASE WHEN r.value('@PORCENTAJE', 'NVARCHAR(50)') IS NULL OR r.value('@PORCENTAJE', 'NVARCHAR(50)') = '' THEN 0 ELSE CAST(r.value('@PORCENTAJE', 'NVARCHAR(50)') AS FLOAT) END,
            NULLIF(r.value('@UBICACION', 'NVARCHAR(40)'), N''),
            NULLIF(r.value('@Co_Usuario', 'NVARCHAR(10)'), N''),
            NULLIF(r.value('@Linea', 'NVARCHAR(30)'), N''),
            NULLIF(r.value('@N_PARTE', 'NVARCHAR(18)'), N''),
            NULLIF(r.value('@Barra', 'NVARCHAR(50)'), N''),
            ISNULL(CAST(NULLIF(r.value('@Servicio', 'NVARCHAR(5)'), '') AS BIT), 0),
            1, 0, @CompanyId,
            NULLIF(r.value('@Descripcion', 'NVARCHAR(MAX)'), N'')
        FROM @xml.nodes('/row') T(r);

        SET @Resultado = 1;
        SET @Mensaje = N'Articulo creado exitosamente';
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
    @CompanyId INT = NULL,
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
        IF @CompanyId IS NULL
            SET @CompanyId = (SELECT TOP 1 CompanyId FROM cfg.Company WHERE ISNULL(IsDeleted, 0) = 0 ORDER BY CompanyId);
        IF @CompanyId IS NULL SET @CompanyId = 1;

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
            Barra = COALESCE(NULLIF(r.value('@Barra', 'NVARCHAR(50)'), N''), c.Barra),
            Descripcion = COALESCE(NULLIF(r.value('@Descripcion', 'NVARCHAR(MAX)'), N''), c.Descripcion)
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

-- =============================================
-- Stored Procedures: Movimientos de Inventario
-- Tabla: master.InventoryMovement
-- Depende de: master.Product, master.Warehouse
-- =============================================

-- Agregar columnas de almacen si no existen
IF COL_LENGTH('master.InventoryMovement', 'WarehouseFrom') IS NULL
    ALTER TABLE [master].[InventoryMovement] ADD WarehouseFrom NVARCHAR(20) NULL;
GO
IF COL_LENGTH('master.InventoryMovement', 'WarehouseTo') IS NULL
    ALTER TABLE [master].[InventoryMovement] ADD WarehouseTo NVARCHAR(20) NULL;
GO

-- ---------- 6. Movimiento Insert (ENTRADA/SALIDA/AJUSTE/TRASLADO) ----------
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_Inventario_Movimiento_Insert')
    DROP PROCEDURE usp_Inventario_Movimiento_Insert
GO
SET QUOTED_IDENTIFIER ON
SET ANSI_NULLS ON
GO
CREATE PROCEDURE usp_Inventario_Movimiento_Insert
    @CompanyId      INT = 1,
    @ProductCode    NVARCHAR(80),
    @MovementType   NVARCHAR(20),          -- ENTRADA | SALIDA | AJUSTE | TRASLADO
    @Quantity       DECIMAL(18,4),
    @UnitCost       DECIMAL(18,4) = 0,
    @DocumentRef    NVARCHAR(60)  = NULL,
    @WarehouseFrom  NVARCHAR(20)  = NULL,
    @WarehouseTo    NVARCHAR(20)  = NULL,
    @Notes          NVARCHAR(300) = NULL,
    @UserId         INT = NULL,
    @Resultado      INT OUTPUT,
    @Mensaje        NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET @Resultado = 0;
    SET @Mensaje = N'';

    DECLARE @ProductName NVARCHAR(250), @CurrentStock DECIMAL(18,4), @CostPrice DECIMAL(18,4);

    SELECT @ProductName = ProductName,
           @CurrentStock = ISNULL(StockQty, 0),
           @CostPrice    = ISNULL(CostPrice, 0)
    FROM [master].[Product]
    WHERE ProductCode = @ProductCode AND CompanyId = @CompanyId AND ISNULL(IsDeleted, 0) = 0;

    IF @ProductName IS NULL
    BEGIN
        SET @Resultado = -1;
        SET @Mensaje = N'Producto no encontrado: ' + @ProductCode;
        RETURN;
    END

    IF @UnitCost = 0 SET @UnitCost = @CostPrice;
    SET @Quantity = ABS(@Quantity);

    BEGIN TRY
        BEGIN TRANSACTION;

        IF @MovementType = N'TRASLADO'
        BEGIN
            IF @WarehouseFrom IS NULL OR @WarehouseTo IS NULL
            BEGIN
                SET @Resultado = -2;
                SET @Mensaje = N'Traslado requiere almacen origen y destino';
                ROLLBACK; RETURN;
            END

            IF @CurrentStock < @Quantity
            BEGIN
                SET @Resultado = -3;
                SET @Mensaje = N'Stock insuficiente. Disponible: ' + CAST(@CurrentStock AS NVARCHAR(20));
                ROLLBACK; RETURN;
            END

            DECLARE @DocRef NVARCHAR(60) = ISNULL(@DocumentRef,
                N'TRASL-' + CONVERT(NVARCHAR(8), SYSUTCDATETIME(), 112) + N'-' +
                LEFT(REPLACE(CAST(NEWID() AS NVARCHAR(36)), N'-', N''), 6));

            -- Movimiento SALIDA del almacen origen
            INSERT INTO [master].[InventoryMovement]
                (CompanyId, ProductCode, ProductName, MovementType, MovementDate,
                 Quantity, UnitCost, TotalCost, DocumentRef, WarehouseFrom, WarehouseTo,
                 Notes, CreatedByUserId)
            VALUES
                (@CompanyId, @ProductCode, @ProductName, N'SALIDA', CAST(SYSUTCDATETIME() AS DATE),
                 @Quantity, @UnitCost, @Quantity * @UnitCost, @DocRef, @WarehouseFrom, NULL,
                 N'Traslado a ' + @WarehouseTo + CASE WHEN @Notes IS NOT NULL THEN N'. ' + @Notes ELSE N'' END,
                 @UserId);

            -- Movimiento ENTRADA al almacen destino
            INSERT INTO [master].[InventoryMovement]
                (CompanyId, ProductCode, ProductName, MovementType, MovementDate,
                 Quantity, UnitCost, TotalCost, DocumentRef, WarehouseFrom, WarehouseTo,
                 Notes, CreatedByUserId)
            VALUES
                (@CompanyId, @ProductCode, @ProductName, N'ENTRADA', CAST(SYSUTCDATETIME() AS DATE),
                 @Quantity, @UnitCost, @Quantity * @UnitCost, @DocRef, NULL, @WarehouseTo,
                 N'Traslado desde ' + @WarehouseFrom + CASE WHEN @Notes IS NOT NULL THEN N'. ' + @Notes ELSE N'' END,
                 @UserId);

            -- Stock neto no cambia (traslado es movimiento interno entre almacenes)
        END
        ELSE
        BEGIN
            -- Movimiento normal: ENTRADA, SALIDA, AJUSTE
            IF @MovementType = N'SALIDA' AND @CurrentStock < @Quantity
            BEGIN
                SET @Resultado = -3;
                SET @Mensaje = N'Stock insuficiente. Disponible: ' + CAST(@CurrentStock AS NVARCHAR(20));
                ROLLBACK; RETURN;
            END

            INSERT INTO [master].[InventoryMovement]
                (CompanyId, ProductCode, ProductName, MovementType, MovementDate,
                 Quantity, UnitCost, TotalCost, DocumentRef, WarehouseFrom, WarehouseTo,
                 Notes, CreatedByUserId)
            VALUES
                (@CompanyId, @ProductCode, @ProductName, @MovementType, CAST(SYSUTCDATETIME() AS DATE),
                 @Quantity, @UnitCost, @Quantity * @UnitCost, @DocumentRef, @WarehouseFrom, @WarehouseTo,
                 @Notes, @UserId);

            -- Actualizar stock en master.Product
            IF @MovementType IN (N'ENTRADA', N'AJUSTE')
                UPDATE [master].[Product]
                SET StockQty = ISNULL(StockQty, 0) + @Quantity
                WHERE ProductCode = @ProductCode AND CompanyId = @CompanyId;
            ELSE IF @MovementType = N'SALIDA'
                UPDATE [master].[Product]
                SET StockQty = ISNULL(StockQty, 0) - @Quantity
                WHERE ProductCode = @ProductCode AND CompanyId = @CompanyId;
        END

        COMMIT;
        SET @Resultado = 1;
        SET @Mensaje = N'OK';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        SET @Resultado = -99;
        SET @Mensaje = ERROR_MESSAGE();
    END CATCH
END
GO

-- ---------- 7. Movimientos List (paginado con filtros) ----------
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_Inventario_Movimiento_List')
    DROP PROCEDURE usp_Inventario_Movimiento_List
GO
CREATE PROCEDURE usp_Inventario_Movimiento_List
    @CompanyId      INT = 1,
    @Search         NVARCHAR(100) = NULL,
    @ProductCode    NVARCHAR(80)  = NULL,
    @MovementType   NVARCHAR(20)  = NULL,
    @WarehouseCode  NVARCHAR(20)  = NULL,
    @FechaDesde     DATE = NULL,
    @FechaHasta     DATE = NULL,
    @Page           INT = 1,
    @Limit          INT = 50,
    @TotalCount     INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Offset INT = (ISNULL(NULLIF(@Page, 0), 1) - 1) * ISNULL(NULLIF(@Limit, 0), 50);
    IF @Offset < 0 SET @Offset = 0;
    IF @Limit < 1  SET @Limit = 50;
    IF @Limit > 500 SET @Limit = 500;

    SELECT @TotalCount = COUNT(1)
    FROM [master].[InventoryMovement]
    WHERE CompanyId = @CompanyId
      AND ISNULL(IsDeleted, 0) = 0
      AND (@Search IS NULL OR ProductCode LIKE N'%' + @Search + N'%'
           OR ProductName LIKE N'%' + @Search + N'%'
           OR DocumentRef LIKE N'%' + @Search + N'%')
      AND (@ProductCode IS NULL OR ProductCode = @ProductCode)
      AND (@MovementType IS NULL OR MovementType = @MovementType)
      AND (@WarehouseCode IS NULL OR WarehouseFrom = @WarehouseCode OR WarehouseTo = @WarehouseCode)
      AND (@FechaDesde IS NULL OR MovementDate >= @FechaDesde)
      AND (@FechaHasta IS NULL OR MovementDate <= @FechaHasta);

    SELECT
        MovementId, ProductCode, ProductName, MovementType, MovementDate,
        Quantity, UnitCost, TotalCost, DocumentRef,
        WarehouseFrom, WarehouseTo, Notes, CreatedAt, CreatedByUserId
    FROM [master].[InventoryMovement]
    WHERE CompanyId = @CompanyId
      AND ISNULL(IsDeleted, 0) = 0
      AND (@Search IS NULL OR ProductCode LIKE N'%' + @Search + N'%'
           OR ProductName LIKE N'%' + @Search + N'%'
           OR DocumentRef LIKE N'%' + @Search + N'%')
      AND (@ProductCode IS NULL OR ProductCode = @ProductCode)
      AND (@MovementType IS NULL OR MovementType = @MovementType)
      AND (@WarehouseCode IS NULL OR WarehouseFrom = @WarehouseCode OR WarehouseTo = @WarehouseCode)
      AND (@FechaDesde IS NULL OR MovementDate >= @FechaDesde)
      AND (@FechaHasta IS NULL OR MovementDate <= @FechaHasta)
    ORDER BY CreatedAt DESC
    OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;
END
GO

-- ---------- 8. Dashboard Inventario (metricas) ----------
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_Inventario_Dashboard')
    DROP PROCEDURE usp_Inventario_Dashboard
GO
CREATE PROCEDURE usp_Inventario_Dashboard
    @CompanyId INT = 1
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        (SELECT COUNT(1) FROM [master].[Product]
         WHERE CompanyId = @CompanyId AND ISNULL(IsDeleted, 0) = 0
        ) AS TotalArticulos,

        (SELECT COUNT(1) FROM [master].[Product]
         WHERE CompanyId = @CompanyId AND ISNULL(IsDeleted, 0) = 0
           AND ISNULL(StockQty, 0) <= 0
        ) AS BajoStock,

        (SELECT COUNT(DISTINCT CategoryCode) FROM [master].[Product]
         WHERE CompanyId = @CompanyId AND ISNULL(IsDeleted, 0) = 0
           AND CategoryCode IS NOT NULL AND CategoryCode <> N''
        ) AS TotalCategorias,

        (SELECT ISNULL(SUM(ISNULL(StockQty, 0) * ISNULL(CostPrice, 0)), 0)
         FROM [master].[Product]
         WHERE CompanyId = @CompanyId AND ISNULL(IsDeleted, 0) = 0
        ) AS ValorInventario,

        (SELECT COUNT(1) FROM [master].[InventoryMovement]
         WHERE CompanyId = @CompanyId AND ISNULL(IsDeleted, 0) = 0
           AND MovementDate >= DATEADD(DAY, 1 - DAY(CAST(SYSUTCDATETIME() AS DATE)),
                                       CAST(SYSUTCDATETIME() AS DATE))
        ) AS MovimientosMes;
END
GO

-- ---------- 9. Libro de Inventario (reporte por rango de fechas) ----------
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_Inventario_LibroInventario')
    DROP PROCEDURE usp_Inventario_LibroInventario
GO
CREATE PROCEDURE usp_Inventario_LibroInventario
    @CompanyId      INT = 1,
    @FechaDesde     DATE,
    @FechaHasta     DATE,
    @ProductCode    NVARCHAR(80) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- CTE: calcular entradas/salidas por producto en el rango
    ;WITH MovsByProduct AS (
        SELECT
            ProductCode,
            SUM(CASE WHEN MovementType IN (N'ENTRADA', N'AJUSTE') THEN Quantity ELSE 0 END) AS EntradasDesde,
            SUM(CASE WHEN MovementType = N'SALIDA' THEN Quantity ELSE 0 END) AS SalidasDesde,
            SUM(CASE WHEN MovementType IN (N'ENTRADA', N'AJUSTE') AND MovementDate <= @FechaHasta THEN Quantity ELSE 0 END) AS Entradas,
            SUM(CASE WHEN MovementType = N'SALIDA' AND MovementDate <= @FechaHasta THEN Quantity ELSE 0 END) AS Salidas
        FROM [master].[InventoryMovement]
        WHERE CompanyId = @CompanyId
          AND ISNULL(IsDeleted, 0) = 0
          AND MovementDate >= @FechaDesde
        GROUP BY ProductCode
    )
    SELECT
        p.ProductCode   AS CODIGO,
        p.ProductName   AS DESCRIPCION,
        LTRIM(RTRIM(
            ISNULL(RTRIM(p.CategoryCode), N'') +
            CASE WHEN RTRIM(ISNULL(p.ProductName, N'')) <> N'' THEN N' ' + RTRIM(p.ProductName) ELSE N'' END
        )) AS DescripcionCompleta,
        ISNULL(p.StockQty, 0) - ISNULL(m.EntradasDesde, 0) + ISNULL(m.SalidasDesde, 0) AS StockInicial,
        ISNULL(m.Entradas, 0) AS Entradas,
        ISNULL(m.Salidas, 0)  AS Salidas,
        (ISNULL(p.StockQty, 0) - ISNULL(m.EntradasDesde, 0) + ISNULL(m.SalidasDesde, 0))
            + ISNULL(m.Entradas, 0) - ISNULL(m.Salidas, 0) AS StockFinal,
        ISNULL(p.CostPrice, 0) AS CostoUnitario,
        p.UnitCode AS Unidad
    FROM [master].[Product] p
    LEFT JOIN MovsByProduct m ON m.ProductCode = p.ProductCode
    WHERE p.CompanyId = @CompanyId
      AND ISNULL(p.IsDeleted, 0) = 0
      AND (@ProductCode IS NULL OR p.ProductCode = @ProductCode)
    ORDER BY p.ProductCode;
END
GO

SELECT name, create_date FROM sys.objects WHERE type = 'P' AND name LIKE 'usp_Inventario_%';
