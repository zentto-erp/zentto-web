-- =============================================================================
-- 20_rebuild_maestros_sps.sql
-- Reconstruye todos los SPs de datos maestros para usar tablas canónicas
-- Preserva firmas idénticas de parámetros y columnas de resultado para
-- compatibilidad total con la API TypeScript existente
-- =============================================================================
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

USE DatqBoxWeb;
GO

-- Agregar ConversionFactor a master.UnitOfMeasure si no existe (compat con Cantidad legacy)
IF NOT EXISTS (
  SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = 'master' AND TABLE_NAME = 'UnitOfMeasure'
    AND COLUMN_NAME = 'ConversionFactor'
)
  ALTER TABLE master.UnitOfMeasure ADD ConversionFactor DECIMAL(18,4) NULL;
GO

PRINT '[20] Inicio rebuild de SPs maestros canónicos...';
GO

-- =============================================================================
-- SECCIÓN 1: usp_Categorias_*  →  master.Category
--   Legacy columns: Codigo (INT), Nombre (NVARCHAR), Co_Usuario (NVARCHAR)
-- =============================================================================

IF OBJECT_ID(N'usp_Categorias_List', N'P') IS NOT NULL DROP PROCEDURE usp_Categorias_List;
GO
CREATE PROCEDURE usp_Categorias_List
    @Search     NVARCHAR(100) = NULL,
    @Page       INT = 1,
    @Limit      INT = 50,
    @TotalCount INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Offset INT = (ISNULL(NULLIF(@Page,0),1) - 1) * ISNULL(NULLIF(@Limit,0),50);
    IF @Offset < 0 SET @Offset = 0;
    IF @Limit < 1 SET @Limit = 50;
    IF @Limit > 500 SET @Limit = 500;
    DECLARE @S NVARCHAR(100) = CASE WHEN @Search IS NOT NULL AND LTRIM(RTRIM(@Search)) <> N'' THEN N'%' + @Search + N'%' ELSE NULL END;
    SELECT @TotalCount = COUNT(1) FROM master.Category
    WHERE IsDeleted = 0 AND (@S IS NULL OR CategoryName LIKE @S OR CAST(CategoryId AS NVARCHAR(20)) LIKE @S);
    SELECT CategoryId AS Codigo, CategoryName AS Nombre, UserCode AS Co_Usuario
    FROM master.Category
    WHERE IsDeleted = 0 AND (@S IS NULL OR CategoryName LIKE @S OR CAST(CategoryId AS NVARCHAR(20)) LIKE @S)
    ORDER BY CategoryId OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;
END
GO

IF OBJECT_ID(N'usp_Categorias_GetByCodigo', N'P') IS NOT NULL DROP PROCEDURE usp_Categorias_GetByCodigo;
GO
CREATE PROCEDURE usp_Categorias_GetByCodigo @Codigo INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CategoryId AS Codigo, CategoryName AS Nombre, UserCode AS Co_Usuario
    FROM master.Category WHERE CategoryId = @Codigo AND IsDeleted = 0;
END
GO

IF OBJECT_ID(N'usp_Categorias_Insert', N'P') IS NOT NULL DROP PROCEDURE usp_Categorias_Insert;
GO
CREATE PROCEDURE usp_Categorias_Insert
    @RowXml      NVARCHAR(MAX),
    @Resultado   INT OUTPUT,
    @Mensaje     NVARCHAR(500) OUTPUT,
    @NuevoCodigo INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    SET @Resultado = 0; SET @Mensaje = N''; SET @NuevoCodigo = 0;
    DECLARE @x XML = CAST(@RowXml AS XML);
    DECLARE @Nombre    NVARCHAR(100) = NULLIF(@x.value('(/row/@Nombre)[1]',    'NVARCHAR(100)'), N'');
    DECLARE @CoUsuario NVARCHAR(20)  = NULLIF(@x.value('(/row/@Co_Usuario)[1]','NVARCHAR(20)'),  N'');
    BEGIN TRY
        IF @Nombre IS NULL BEGIN SET @Resultado = -1; SET @Mensaje = N'Nombre requerido'; RETURN; END
        INSERT INTO master.Category (CategoryName, UserCode) VALUES (@Nombre, @CoUsuario);
        SET @NuevoCodigo = CAST(SCOPE_IDENTITY() AS INT);
        SET @Resultado = 1; SET @Mensaje = N'OK';
    END TRY BEGIN CATCH SET @Resultado = -99; SET @Mensaje = ERROR_MESSAGE(); END CATCH
END
GO

IF OBJECT_ID(N'usp_Categorias_Update', N'P') IS NOT NULL DROP PROCEDURE usp_Categorias_Update;
GO
CREATE PROCEDURE usp_Categorias_Update
    @Codigo    INT,
    @RowXml    NVARCHAR(MAX),
    @Resultado INT OUTPUT,
    @Mensaje   NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON; SET @Resultado = 0; SET @Mensaje = N'';
    DECLARE @x XML = CAST(@RowXml AS XML);
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM master.Category WHERE CategoryId = @Codigo AND IsDeleted = 0)
        BEGIN SET @Resultado = -1; SET @Mensaje = N'Categoría no encontrada'; RETURN; END
        UPDATE master.Category SET
            CategoryName = COALESCE(NULLIF(@x.value('(/row/@Nombre)[1]',    'NVARCHAR(100)'), N''), CategoryName),
            UserCode     = COALESCE(NULLIF(@x.value('(/row/@Co_Usuario)[1]','NVARCHAR(20)'),  N''), UserCode),
            UpdatedAt    = SYSUTCDATETIME()
        WHERE CategoryId = @Codigo;
        SET @Resultado = 1; SET @Mensaje = N'OK';
    END TRY BEGIN CATCH SET @Resultado = -99; SET @Mensaje = ERROR_MESSAGE(); END CATCH
END
GO

IF OBJECT_ID(N'usp_Categorias_Delete', N'P') IS NOT NULL DROP PROCEDURE usp_Categorias_Delete;
GO
CREATE PROCEDURE usp_Categorias_Delete
    @Codigo    INT,
    @Resultado INT OUTPUT,
    @Mensaje   NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON; SET @Resultado = 0; SET @Mensaje = N'';
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM master.Category WHERE CategoryId = @Codigo AND IsDeleted = 0)
        BEGIN SET @Resultado = -1; SET @Mensaje = N'Categoría no encontrada'; RETURN; END
        UPDATE master.Category SET IsDeleted = 1, UpdatedAt = SYSUTCDATETIME() WHERE CategoryId = @Codigo;
        SET @Resultado = 1; SET @Mensaje = N'OK';
    END TRY BEGIN CATCH SET @Resultado = -99; SET @Mensaje = ERROR_MESSAGE(); END CATCH
END
GO

-- =============================================================================
-- SECCIÓN 2: usp_Marcas_*  →  master.Brand
--   Legacy columns: Codigo (INT), Descripcion (NVARCHAR)
-- =============================================================================

IF OBJECT_ID(N'usp_Marcas_List', N'P') IS NOT NULL DROP PROCEDURE usp_Marcas_List;
GO
CREATE PROCEDURE usp_Marcas_List
    @Search     NVARCHAR(100) = NULL,
    @Page       INT = 1,
    @Limit      INT = 50,
    @TotalCount INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Offset INT = (ISNULL(NULLIF(@Page,0),1) - 1) * ISNULL(NULLIF(@Limit,0),50);
    IF @Offset < 0 SET @Offset = 0; IF @Limit < 1 SET @Limit = 50; IF @Limit > 500 SET @Limit = 500;
    DECLARE @S NVARCHAR(100) = CASE WHEN @Search IS NOT NULL AND LTRIM(RTRIM(@Search)) <> N'' THEN N'%' + @Search + N'%' ELSE NULL END;
    SELECT @TotalCount = COUNT(1) FROM master.Brand
    WHERE IsDeleted = 0 AND (@S IS NULL OR BrandName LIKE @S);
    SELECT BrandId AS Codigo, BrandName AS Descripcion
    FROM master.Brand
    WHERE IsDeleted = 0 AND (@S IS NULL OR BrandName LIKE @S)
    ORDER BY BrandId OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;
END
GO

IF OBJECT_ID(N'usp_Marcas_GetByCodigo', N'P') IS NOT NULL DROP PROCEDURE usp_Marcas_GetByCodigo;
GO
CREATE PROCEDURE usp_Marcas_GetByCodigo @Codigo INT
AS BEGIN SET NOCOUNT ON;
    SELECT BrandId AS Codigo, BrandName AS Descripcion FROM master.Brand WHERE BrandId = @Codigo AND IsDeleted = 0;
END
GO

IF OBJECT_ID(N'usp_Marcas_Insert', N'P') IS NOT NULL DROP PROCEDURE usp_Marcas_Insert;
GO
CREATE PROCEDURE usp_Marcas_Insert
    @RowXml      NVARCHAR(MAX),
    @Resultado   INT OUTPUT,
    @Mensaje     NVARCHAR(500) OUTPUT,
    @NuevoCodigo INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    SET @Resultado = 0; SET @Mensaje = N''; SET @NuevoCodigo = 0;
    DECLARE @x XML = CAST(@RowXml AS XML);
    DECLARE @Desc NVARCHAR(100) = NULLIF(@x.value('(/row/@Descripcion)[1]','NVARCHAR(100)'),N'');
    BEGIN TRY
        IF @Desc IS NULL BEGIN SET @Resultado = -1; SET @Mensaje = N'Descripcion requerida'; RETURN; END
        INSERT INTO master.Brand (BrandName) VALUES (@Desc);
        SET @NuevoCodigo = CAST(SCOPE_IDENTITY() AS INT);
        SET @Resultado = 1; SET @Mensaje = N'OK';
    END TRY BEGIN CATCH SET @Resultado = -99; SET @Mensaje = ERROR_MESSAGE(); END CATCH
END
GO

IF OBJECT_ID(N'usp_Marcas_Update', N'P') IS NOT NULL DROP PROCEDURE usp_Marcas_Update;
GO
CREATE PROCEDURE usp_Marcas_Update
    @Codigo INT, @RowXml NVARCHAR(MAX), @Resultado INT OUTPUT, @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON; SET @Resultado = 0; SET @Mensaje = N'';
    DECLARE @x XML = CAST(@RowXml AS XML);
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM master.Brand WHERE BrandId = @Codigo AND IsDeleted = 0)
        BEGIN SET @Resultado = -1; SET @Mensaje = N'Marca no encontrada'; RETURN; END
        UPDATE master.Brand SET
            BrandName = COALESCE(NULLIF(@x.value('(/row/@Descripcion)[1]','NVARCHAR(100)'),N''), BrandName),
            UpdatedAt = SYSUTCDATETIME()
        WHERE BrandId = @Codigo;
        SET @Resultado = 1; SET @Mensaje = N'OK';
    END TRY BEGIN CATCH SET @Resultado = -99; SET @Mensaje = ERROR_MESSAGE(); END CATCH
END
GO

IF OBJECT_ID(N'usp_Marcas_Delete', N'P') IS NOT NULL DROP PROCEDURE usp_Marcas_Delete;
GO
CREATE PROCEDURE usp_Marcas_Delete
    @Codigo INT, @Resultado INT OUTPUT, @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON; SET @Resultado = 0; SET @Mensaje = N'';
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM master.Brand WHERE BrandId = @Codigo AND IsDeleted = 0)
        BEGIN SET @Resultado = -1; SET @Mensaje = N'Marca no encontrada'; RETURN; END
        UPDATE master.Brand SET IsDeleted = 1, UpdatedAt = SYSUTCDATETIME() WHERE BrandId = @Codigo;
        SET @Resultado = 1; SET @Mensaje = N'OK';
    END TRY BEGIN CATCH SET @Resultado = -99; SET @Mensaje = ERROR_MESSAGE(); END CATCH
END
GO

-- =============================================================================
-- SECCIÓN 3: usp_Almacen_*  →  master.Warehouse
--   Legacy columns: Codigo (NVARCHAR(10)), Descripcion (NVARCHAR), Tipo (NVARCHAR)
-- =============================================================================

IF OBJECT_ID(N'usp_Almacen_List', N'P') IS NOT NULL DROP PROCEDURE usp_Almacen_List;
GO
CREATE PROCEDURE usp_Almacen_List
    @Search     NVARCHAR(100) = NULL,
    @Tipo       NVARCHAR(50)  = NULL,
    @Page       INT = 1,
    @Limit      INT = 50,
    @TotalCount INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Offset INT = (ISNULL(NULLIF(@Page,0),1) - 1) * ISNULL(NULLIF(@Limit,0),50);
    IF @Offset < 0 SET @Offset = 0; IF @Limit < 1 SET @Limit = 50; IF @Limit > 500 SET @Limit = 500;
    DECLARE @S NVARCHAR(100) = CASE WHEN @Search IS NOT NULL AND LTRIM(RTRIM(@Search)) <> N'' THEN N'%' + @Search + N'%' ELSE NULL END;
    SELECT @TotalCount = COUNT(1) FROM master.Warehouse
    WHERE IsDeleted = 0
      AND (@S IS NULL OR WarehouseCode LIKE @S OR Description LIKE @S)
      AND (@Tipo IS NULL OR WarehouseType = @Tipo);
    SELECT WarehouseCode AS Codigo, Description AS Descripcion, WarehouseType AS Tipo
    FROM master.Warehouse
    WHERE IsDeleted = 0
      AND (@S IS NULL OR WarehouseCode LIKE @S OR Description LIKE @S)
      AND (@Tipo IS NULL OR WarehouseType = @Tipo)
    ORDER BY WarehouseCode OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;
END
GO

IF OBJECT_ID(N'usp_Almacen_GetByCodigo', N'P') IS NOT NULL DROP PROCEDURE usp_Almacen_GetByCodigo;
GO
CREATE PROCEDURE usp_Almacen_GetByCodigo @Codigo NVARCHAR(10)
AS BEGIN SET NOCOUNT ON;
    SELECT WarehouseCode AS Codigo, Description AS Descripcion, WarehouseType AS Tipo
    FROM master.Warehouse WHERE WarehouseCode = @Codigo AND IsDeleted = 0;
END
GO

IF OBJECT_ID(N'usp_Almacen_Insert', N'P') IS NOT NULL DROP PROCEDURE usp_Almacen_Insert;
GO
CREATE PROCEDURE usp_Almacen_Insert
    @RowXml NVARCHAR(MAX), @Resultado INT OUTPUT, @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON; SET @Resultado = 0; SET @Mensaje = N'';
    DECLARE @x XML = CAST(@RowXml AS XML);
    DECLARE @Codigo     NVARCHAR(20) = NULLIF(@x.value('(/row/@Codigo)[1]',     'NVARCHAR(20)'), N'');
    DECLARE @Desc       NVARCHAR(200)= NULLIF(@x.value('(/row/@Descripcion)[1]','NVARCHAR(200)'),N'');
    DECLARE @Tipo       NVARCHAR(20) = NULLIF(@x.value('(/row/@Tipo)[1]',       'NVARCHAR(20)'), N'');
    BEGIN TRY
        IF @Codigo IS NULL BEGIN SET @Resultado = -1; SET @Mensaje = N'Codigo requerido'; RETURN; END
        IF EXISTS (SELECT 1 FROM master.Warehouse WHERE WarehouseCode = @Codigo AND IsDeleted = 0)
        BEGIN SET @Resultado = -1; SET @Mensaje = N'Almacén ya existe'; RETURN; END
        INSERT INTO master.Warehouse (WarehouseCode, Description, WarehouseType)
        VALUES (@Codigo, COALESCE(@Desc, @Codigo), COALESCE(@Tipo, N'PRINCIPAL'));
        SET @Resultado = 1; SET @Mensaje = N'OK';
    END TRY BEGIN CATCH SET @Resultado = -99; SET @Mensaje = ERROR_MESSAGE(); END CATCH
END
GO

IF OBJECT_ID(N'usp_Almacen_Update', N'P') IS NOT NULL DROP PROCEDURE usp_Almacen_Update;
GO
CREATE PROCEDURE usp_Almacen_Update
    @Codigo NVARCHAR(10), @RowXml NVARCHAR(MAX), @Resultado INT OUTPUT, @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON; SET @Resultado = 0; SET @Mensaje = N'';
    DECLARE @x XML = CAST(@RowXml AS XML);
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM master.Warehouse WHERE WarehouseCode = @Codigo AND IsDeleted = 0)
        BEGIN SET @Resultado = -1; SET @Mensaje = N'Almacén no encontrado'; RETURN; END
        UPDATE master.Warehouse SET
            Description   = COALESCE(NULLIF(@x.value('(/row/@Descripcion)[1]','NVARCHAR(200)'),N''), Description),
            WarehouseType = COALESCE(NULLIF(@x.value('(/row/@Tipo)[1]',       'NVARCHAR(20)'), N''), WarehouseType),
            UpdatedAt     = SYSUTCDATETIME()
        WHERE WarehouseCode = @Codigo;
        SET @Resultado = 1; SET @Mensaje = N'OK';
    END TRY BEGIN CATCH SET @Resultado = -99; SET @Mensaje = ERROR_MESSAGE(); END CATCH
END
GO

IF OBJECT_ID(N'usp_Almacen_Delete', N'P') IS NOT NULL DROP PROCEDURE usp_Almacen_Delete;
GO
CREATE PROCEDURE usp_Almacen_Delete
    @Codigo NVARCHAR(10), @Resultado INT OUTPUT, @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON; SET @Resultado = 0; SET @Mensaje = N'';
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM master.Warehouse WHERE WarehouseCode = @Codigo AND IsDeleted = 0)
        BEGIN SET @Resultado = -1; SET @Mensaje = N'Almacén no encontrado'; RETURN; END
        UPDATE master.Warehouse SET IsDeleted = 1, UpdatedAt = SYSUTCDATETIME() WHERE WarehouseCode = @Codigo;
        SET @Resultado = 1; SET @Mensaje = N'OK';
    END TRY BEGIN CATCH SET @Resultado = -99; SET @Mensaje = ERROR_MESSAGE(); END CATCH
END
GO

-- =============================================================================
-- SECCIÓN 4: usp_Lineas_*  →  master.ProductLine
--   Legacy columns: CODIGO (INT), DESCRIPCION (NVARCHAR)
-- =============================================================================

IF OBJECT_ID(N'usp_Lineas_List', N'P') IS NOT NULL DROP PROCEDURE usp_Lineas_List;
GO
CREATE PROCEDURE usp_Lineas_List
    @Search     NVARCHAR(100) = NULL,
    @Page       INT = 1,
    @Limit      INT = 50,
    @TotalCount INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Offset INT = (ISNULL(NULLIF(@Page,0),1) - 1) * ISNULL(NULLIF(@Limit,0),50);
    IF @Offset < 0 SET @Offset = 0; IF @Limit < 1 SET @Limit = 50; IF @Limit > 500 SET @Limit = 500;
    DECLARE @S NVARCHAR(100) = CASE WHEN @Search IS NOT NULL AND LTRIM(RTRIM(@Search)) <> N'' THEN N'%' + @Search + N'%' ELSE NULL END;
    SELECT @TotalCount = COUNT(1) FROM master.ProductLine
    WHERE IsDeleted = 0 AND (@S IS NULL OR LineName LIKE @S OR CAST(LineId AS NVARCHAR(20)) LIKE @S);
    SELECT LineId AS CODIGO, LineName AS DESCRIPCION
    FROM master.ProductLine
    WHERE IsDeleted = 0 AND (@S IS NULL OR LineName LIKE @S OR CAST(LineId AS NVARCHAR(20)) LIKE @S)
    ORDER BY LineId OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;
END
GO

IF OBJECT_ID(N'usp_Lineas_GetByCodigo', N'P') IS NOT NULL DROP PROCEDURE usp_Lineas_GetByCodigo;
GO
CREATE PROCEDURE usp_Lineas_GetByCodigo @Codigo INT
AS BEGIN SET NOCOUNT ON;
    SELECT LineId AS CODIGO, LineName AS DESCRIPCION FROM master.ProductLine WHERE LineId = @Codigo AND IsDeleted = 0;
END
GO

IF OBJECT_ID(N'usp_Lineas_Insert', N'P') IS NOT NULL DROP PROCEDURE usp_Lineas_Insert;
GO
CREATE PROCEDURE usp_Lineas_Insert
    @RowXml NVARCHAR(MAX), @Resultado INT OUTPUT, @Mensaje NVARCHAR(500) OUTPUT, @NuevoCodigo INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON; SET @Resultado = 0; SET @Mensaje = N''; SET @NuevoCodigo = 0;
    DECLARE @x XML = CAST(@RowXml AS XML);
    DECLARE @Desc NVARCHAR(100) = NULLIF(@x.value('(/row/@DESCRIPCION)[1]','NVARCHAR(100)'),N'');
    BEGIN TRY
        IF @Desc IS NULL BEGIN SET @Resultado = -1; SET @Mensaje = N'DESCRIPCION requerida'; RETURN; END
        -- LineCode autogenerado como secuencial formateado
        DECLARE @NextCode NVARCHAR(20) = N'L' + FORMAT((SELECT ISNULL(MAX(LineId),0)+1 FROM master.ProductLine), N'000');
        INSERT INTO master.ProductLine (LineCode, LineName) VALUES (@NextCode, @Desc);
        SET @NuevoCodigo = CAST(SCOPE_IDENTITY() AS INT);
        SET @Resultado = 1; SET @Mensaje = N'OK';
    END TRY BEGIN CATCH SET @Resultado = -99; SET @Mensaje = ERROR_MESSAGE(); END CATCH
END
GO

IF OBJECT_ID(N'usp_Lineas_Update', N'P') IS NOT NULL DROP PROCEDURE usp_Lineas_Update;
GO
CREATE PROCEDURE usp_Lineas_Update
    @Codigo INT, @RowXml NVARCHAR(MAX), @Resultado INT OUTPUT, @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON; SET @Resultado = 0; SET @Mensaje = N'';
    DECLARE @x XML = CAST(@RowXml AS XML);
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM master.ProductLine WHERE LineId = @Codigo AND IsDeleted = 0)
        BEGIN SET @Resultado = -1; SET @Mensaje = N'Linea no encontrada'; RETURN; END
        UPDATE master.ProductLine SET
            LineName  = COALESCE(NULLIF(@x.value('(/row/@DESCRIPCION)[1]','NVARCHAR(100)'),N''), LineName),
            UpdatedAt = SYSUTCDATETIME()
        WHERE LineId = @Codigo;
        SET @Resultado = 1; SET @Mensaje = N'OK';
    END TRY BEGIN CATCH SET @Resultado = -99; SET @Mensaje = ERROR_MESSAGE(); END CATCH
END
GO

IF OBJECT_ID(N'usp_Lineas_Delete', N'P') IS NOT NULL DROP PROCEDURE usp_Lineas_Delete;
GO
CREATE PROCEDURE usp_Lineas_Delete
    @Codigo INT, @Resultado INT OUTPUT, @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON; SET @Resultado = 0; SET @Mensaje = N'';
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM master.ProductLine WHERE LineId = @Codigo AND IsDeleted = 0)
        BEGIN SET @Resultado = -1; SET @Mensaje = N'Linea no encontrada'; RETURN; END
        UPDATE master.ProductLine SET IsDeleted = 1, UpdatedAt = SYSUTCDATETIME() WHERE LineId = @Codigo;
        SET @Resultado = 1; SET @Mensaje = N'OK';
    END TRY BEGIN CATCH SET @Resultado = -99; SET @Mensaje = ERROR_MESSAGE(); END CATCH
END
GO

-- =============================================================================
-- SECCIÓN 5: usp_Clases_*  →  master.ProductClass
--   Legacy columns: Codigo (INT), Descripcion (NVARCHAR(25))
-- =============================================================================

IF OBJECT_ID(N'usp_Clases_List', N'P') IS NOT NULL DROP PROCEDURE usp_Clases_List;
GO
CREATE PROCEDURE usp_Clases_List
    @Search     NVARCHAR(100) = NULL,
    @Page       INT = 1,
    @Limit      INT = 50,
    @TotalCount INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Offset INT = (ISNULL(NULLIF(@Page,0),1) - 1) * ISNULL(NULLIF(@Limit,0),50);
    IF @Offset < 0 SET @Offset = 0; IF @Limit < 1 SET @Limit = 50; IF @Limit > 500 SET @Limit = 500;
    DECLARE @S NVARCHAR(100) = CASE WHEN @Search IS NOT NULL AND LTRIM(RTRIM(@Search)) <> N'' THEN N'%' + @Search + N'%' ELSE NULL END;
    SELECT @TotalCount = COUNT(1) FROM master.ProductClass
    WHERE IsDeleted = 0 AND (@S IS NULL OR ClassName LIKE @S OR CAST(ClassId AS NVARCHAR(20)) LIKE @S);
    SELECT ClassId AS Codigo, ClassName AS Descripcion
    FROM master.ProductClass
    WHERE IsDeleted = 0 AND (@S IS NULL OR ClassName LIKE @S OR CAST(ClassId AS NVARCHAR(20)) LIKE @S)
    ORDER BY ClassId OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;
END
GO

IF OBJECT_ID(N'usp_Clases_GetByCodigo', N'P') IS NOT NULL DROP PROCEDURE usp_Clases_GetByCodigo;
GO
CREATE PROCEDURE usp_Clases_GetByCodigo @Codigo INT
AS BEGIN SET NOCOUNT ON;
    SELECT ClassId AS Codigo, ClassName AS Descripcion FROM master.ProductClass WHERE ClassId = @Codigo AND IsDeleted = 0;
END
GO

IF OBJECT_ID(N'usp_Clases_Insert', N'P') IS NOT NULL DROP PROCEDURE usp_Clases_Insert;
GO
CREATE PROCEDURE usp_Clases_Insert
    @RowXml NVARCHAR(MAX), @Resultado INT OUTPUT, @Mensaje NVARCHAR(500) OUTPUT, @NuevoCodigo INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON; SET @Resultado = 0; SET @Mensaje = N''; SET @NuevoCodigo = 0;
    DECLARE @x XML = CAST(@RowXml AS XML);
    DECLARE @Desc NVARCHAR(100) = NULLIF(@x.value('(/row/@Descripcion)[1]','NVARCHAR(100)'),N'');
    BEGIN TRY
        IF @Desc IS NULL BEGIN SET @Resultado = -1; SET @Mensaje = N'Descripcion requerida'; RETURN; END
        DECLARE @CCode NVARCHAR(20) = N'C' + FORMAT((SELECT ISNULL(MAX(ClassId),0)+1 FROM master.ProductClass), N'000');
        INSERT INTO master.ProductClass (ClassCode, ClassName) VALUES (@CCode, @Desc);
        SET @NuevoCodigo = CAST(SCOPE_IDENTITY() AS INT);
        SET @Resultado = 1; SET @Mensaje = N'OK';
    END TRY BEGIN CATCH SET @Resultado = -99; SET @Mensaje = ERROR_MESSAGE(); END CATCH
END
GO

IF OBJECT_ID(N'usp_Clases_Update', N'P') IS NOT NULL DROP PROCEDURE usp_Clases_Update;
GO
CREATE PROCEDURE usp_Clases_Update
    @Codigo INT, @RowXml NVARCHAR(MAX), @Resultado INT OUTPUT, @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON; SET @Resultado = 0; SET @Mensaje = N'';
    DECLARE @x XML = CAST(@RowXml AS XML);
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM master.ProductClass WHERE ClassId = @Codigo AND IsDeleted = 0)
        BEGIN SET @Resultado = -1; SET @Mensaje = N'Clase no encontrada'; RETURN; END
        UPDATE master.ProductClass SET
            ClassName = COALESCE(NULLIF(@x.value('(/row/@Descripcion)[1]','NVARCHAR(100)'),N''), ClassName),
            UpdatedAt = SYSUTCDATETIME()
        WHERE ClassId = @Codigo;
        SET @Resultado = 1; SET @Mensaje = N'OK';
    END TRY BEGIN CATCH SET @Resultado = -99; SET @Mensaje = ERROR_MESSAGE(); END CATCH
END
GO

IF OBJECT_ID(N'usp_Clases_Delete', N'P') IS NOT NULL DROP PROCEDURE usp_Clases_Delete;
GO
CREATE PROCEDURE usp_Clases_Delete
    @Codigo INT, @Resultado INT OUTPUT, @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON; SET @Resultado = 0; SET @Mensaje = N'';
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM master.ProductClass WHERE ClassId = @Codigo AND IsDeleted = 0)
        BEGIN SET @Resultado = -1; SET @Mensaje = N'Clase no encontrada'; RETURN; END
        UPDATE master.ProductClass SET IsDeleted = 1, UpdatedAt = SYSUTCDATETIME() WHERE ClassId = @Codigo;
        SET @Resultado = 1; SET @Mensaje = N'OK';
    END TRY BEGIN CATCH SET @Resultado = -99; SET @Mensaje = ERROR_MESSAGE(); END CATCH
END
GO

-- =============================================================================
-- SECCIÓN 6: usp_Grupos_*  →  master.ProductGroup
--   Legacy columns: Codigo (INT), Descripcion, Co_Usuario, Porcentaje (FLOAT)
-- =============================================================================

IF OBJECT_ID(N'usp_Grupos_List', N'P') IS NOT NULL DROP PROCEDURE usp_Grupos_List;
GO
CREATE PROCEDURE usp_Grupos_List
    @Search     NVARCHAR(100) = NULL,
    @Page       INT = 1,
    @Limit      INT = 50,
    @TotalCount INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Offset INT = (ISNULL(NULLIF(@Page,0),1) - 1) * ISNULL(NULLIF(@Limit,0),50);
    IF @Offset < 0 SET @Offset = 0; IF @Limit < 1 SET @Limit = 50; IF @Limit > 500 SET @Limit = 500;
    DECLARE @S NVARCHAR(100) = CASE WHEN @Search IS NOT NULL AND LTRIM(RTRIM(@Search)) <> N'' THEN N'%' + @Search + N'%' ELSE NULL END;
    SELECT @TotalCount = COUNT(1) FROM master.ProductGroup
    WHERE IsDeleted = 0 AND (@S IS NULL OR GroupName LIKE @S OR CAST(GroupId AS NVARCHAR(20)) LIKE @S);
    SELECT GroupId AS Codigo, GroupName AS Descripcion,
           CAST(NULL AS NVARCHAR(10)) AS Co_Usuario,
           CAST(0.0 AS FLOAT) AS Porcentaje
    FROM master.ProductGroup
    WHERE IsDeleted = 0 AND (@S IS NULL OR GroupName LIKE @S OR CAST(GroupId AS NVARCHAR(20)) LIKE @S)
    ORDER BY GroupId OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;
END
GO

IF OBJECT_ID(N'usp_Grupos_GetByCodigo', N'P') IS NOT NULL DROP PROCEDURE usp_Grupos_GetByCodigo;
GO
CREATE PROCEDURE usp_Grupos_GetByCodigo @Codigo INT
AS BEGIN SET NOCOUNT ON;
    SELECT GroupId AS Codigo, GroupName AS Descripcion,
           CAST(NULL AS NVARCHAR(10)) AS Co_Usuario,
           CAST(0.0 AS FLOAT) AS Porcentaje
    FROM master.ProductGroup WHERE GroupId = @Codigo AND IsDeleted = 0;
END
GO

IF OBJECT_ID(N'usp_Grupos_Insert', N'P') IS NOT NULL DROP PROCEDURE usp_Grupos_Insert;
GO
CREATE PROCEDURE usp_Grupos_Insert
    @RowXml NVARCHAR(MAX), @Resultado INT OUTPUT, @Mensaje NVARCHAR(500) OUTPUT, @NuevoCodigo INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON; SET @Resultado = 0; SET @Mensaje = N''; SET @NuevoCodigo = 0;
    DECLARE @x XML = CAST(@RowXml AS XML);
    DECLARE @Desc NVARCHAR(100) = NULLIF(@x.value('(/row/@Descripcion)[1]','NVARCHAR(100)'),N'');
    BEGIN TRY
        IF @Desc IS NULL BEGIN SET @Resultado = -1; SET @Mensaje = N'Descripcion requerida'; RETURN; END
        DECLARE @GCode NVARCHAR(20) = N'G' + FORMAT((SELECT ISNULL(MAX(GroupId),0)+1 FROM master.ProductGroup), N'000');
        INSERT INTO master.ProductGroup (GroupCode, GroupName) VALUES (@GCode, @Desc);
        SET @NuevoCodigo = CAST(SCOPE_IDENTITY() AS INT);
        SET @Resultado = 1; SET @Mensaje = N'OK';
    END TRY BEGIN CATCH SET @Resultado = -99; SET @Mensaje = ERROR_MESSAGE(); END CATCH
END
GO

IF OBJECT_ID(N'usp_Grupos_Update', N'P') IS NOT NULL DROP PROCEDURE usp_Grupos_Update;
GO
CREATE PROCEDURE usp_Grupos_Update
    @Codigo INT, @RowXml NVARCHAR(MAX), @Resultado INT OUTPUT, @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON; SET @Resultado = 0; SET @Mensaje = N'';
    DECLARE @x XML = CAST(@RowXml AS XML);
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM master.ProductGroup WHERE GroupId = @Codigo AND IsDeleted = 0)
        BEGIN SET @Resultado = -1; SET @Mensaje = N'Grupo no encontrado'; RETURN; END
        UPDATE master.ProductGroup SET
            GroupName = COALESCE(NULLIF(@x.value('(/row/@Descripcion)[1]','NVARCHAR(100)'),N''), GroupName),
            UpdatedAt = SYSUTCDATETIME()
        WHERE GroupId = @Codigo;
        SET @Resultado = 1; SET @Mensaje = N'OK';
    END TRY BEGIN CATCH SET @Resultado = -99; SET @Mensaje = ERROR_MESSAGE(); END CATCH
END
GO

IF OBJECT_ID(N'usp_Grupos_Delete', N'P') IS NOT NULL DROP PROCEDURE usp_Grupos_Delete;
GO
CREATE PROCEDURE usp_Grupos_Delete
    @Codigo INT, @Resultado INT OUTPUT, @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON; SET @Resultado = 0; SET @Mensaje = N'';
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM master.ProductGroup WHERE GroupId = @Codigo AND IsDeleted = 0)
        BEGIN SET @Resultado = -1; SET @Mensaje = N'Grupo no encontrado'; RETURN; END
        UPDATE master.ProductGroup SET IsDeleted = 1, UpdatedAt = SYSUTCDATETIME() WHERE GroupId = @Codigo;
        SET @Resultado = 1; SET @Mensaje = N'OK';
    END TRY BEGIN CATCH SET @Resultado = -99; SET @Mensaje = ERROR_MESSAGE(); END CATCH
END
GO

-- =============================================================================
-- SECCIÓN 7: usp_Tipos_*  →  master.ProductType
--   Legacy columns: Codigo (INT), Nombre, Categoria, Co_Usuario
-- =============================================================================

IF OBJECT_ID(N'usp_Tipos_List', N'P') IS NOT NULL DROP PROCEDURE usp_Tipos_List;
GO
CREATE PROCEDURE usp_Tipos_List
    @Search     NVARCHAR(100) = NULL,
    @Page       INT = 1,
    @Limit      INT = 50,
    @TotalCount INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Offset INT = (ISNULL(NULLIF(@Page,0),1) - 1) * ISNULL(NULLIF(@Limit,0),50);
    IF @Offset < 0 SET @Offset = 0; IF @Limit < 1 SET @Limit = 50; IF @Limit > 500 SET @Limit = 500;
    DECLARE @S NVARCHAR(100) = CASE WHEN @Search IS NOT NULL AND LTRIM(RTRIM(@Search)) <> N'' THEN N'%' + @Search + N'%' ELSE NULL END;
    SELECT @TotalCount = COUNT(1) FROM master.ProductType
    WHERE IsDeleted = 0 AND (@S IS NULL OR TypeName LIKE @S OR CategoryCode LIKE @S OR CAST(TypeId AS NVARCHAR(20)) LIKE @S);
    SELECT TypeId AS Codigo, TypeName AS Nombre, CategoryCode AS Categoria,
           CAST(NULL AS NVARCHAR(10)) AS Co_Usuario
    FROM master.ProductType
    WHERE IsDeleted = 0 AND (@S IS NULL OR TypeName LIKE @S OR CategoryCode LIKE @S OR CAST(TypeId AS NVARCHAR(20)) LIKE @S)
    ORDER BY TypeId OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;
END
GO

IF OBJECT_ID(N'usp_Tipos_GetByCodigo', N'P') IS NOT NULL DROP PROCEDURE usp_Tipos_GetByCodigo;
GO
CREATE PROCEDURE usp_Tipos_GetByCodigo @Codigo INT
AS BEGIN SET NOCOUNT ON;
    SELECT TypeId AS Codigo, TypeName AS Nombre, CategoryCode AS Categoria,
           CAST(NULL AS NVARCHAR(10)) AS Co_Usuario
    FROM master.ProductType WHERE TypeId = @Codigo AND IsDeleted = 0;
END
GO

IF OBJECT_ID(N'usp_Tipos_Insert', N'P') IS NOT NULL DROP PROCEDURE usp_Tipos_Insert;
GO
CREATE PROCEDURE usp_Tipos_Insert
    @RowXml NVARCHAR(MAX), @Resultado INT OUTPUT, @Mensaje NVARCHAR(500) OUTPUT, @NuevoCodigo INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON; SET @Resultado = 0; SET @Mensaje = N''; SET @NuevoCodigo = 0;
    DECLARE @x XML = CAST(@RowXml AS XML);
    DECLARE @Nombre   NVARCHAR(100) = NULLIF(@x.value('(/row/@Nombre)[1]',   'NVARCHAR(100)'),N'');
    DECLARE @Categoria NVARCHAR(50) = NULLIF(@x.value('(/row/@Categoria)[1]','NVARCHAR(50)'), N'');
    BEGIN TRY
        IF @Nombre IS NULL BEGIN SET @Resultado = -1; SET @Mensaje = N'Nombre requerido'; RETURN; END
        DECLARE @TCode NVARCHAR(20) = N'T' + FORMAT((SELECT ISNULL(MAX(TypeId),0)+1 FROM master.ProductType), N'000');
        INSERT INTO master.ProductType (TypeCode, TypeName, CategoryCode) VALUES (@TCode, @Nombre, @Categoria);
        SET @NuevoCodigo = CAST(SCOPE_IDENTITY() AS INT);
        SET @Resultado = 1; SET @Mensaje = N'OK';
    END TRY BEGIN CATCH SET @Resultado = -99; SET @Mensaje = ERROR_MESSAGE(); END CATCH
END
GO

IF OBJECT_ID(N'usp_Tipos_Update', N'P') IS NOT NULL DROP PROCEDURE usp_Tipos_Update;
GO
CREATE PROCEDURE usp_Tipos_Update
    @Codigo INT, @RowXml NVARCHAR(MAX), @Resultado INT OUTPUT, @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON; SET @Resultado = 0; SET @Mensaje = N'';
    DECLARE @x XML = CAST(@RowXml AS XML);
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM master.ProductType WHERE TypeId = @Codigo AND IsDeleted = 0)
        BEGIN SET @Resultado = -1; SET @Mensaje = N'Tipo no encontrado'; RETURN; END
        UPDATE master.ProductType SET
            TypeName     = COALESCE(NULLIF(@x.value('(/row/@Nombre)[1]',   'NVARCHAR(100)'),N''), TypeName),
            CategoryCode = COALESCE(NULLIF(@x.value('(/row/@Categoria)[1]','NVARCHAR(50)'), N''), CategoryCode),
            UpdatedAt    = SYSUTCDATETIME()
        WHERE TypeId = @Codigo;
        SET @Resultado = 1; SET @Mensaje = N'OK';
    END TRY BEGIN CATCH SET @Resultado = -99; SET @Mensaje = ERROR_MESSAGE(); END CATCH
END
GO

IF OBJECT_ID(N'usp_Tipos_Delete', N'P') IS NOT NULL DROP PROCEDURE usp_Tipos_Delete;
GO
CREATE PROCEDURE usp_Tipos_Delete
    @Codigo INT, @Resultado INT OUTPUT, @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON; SET @Resultado = 0; SET @Mensaje = N'';
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM master.ProductType WHERE TypeId = @Codigo AND IsDeleted = 0)
        BEGIN SET @Resultado = -1; SET @Mensaje = N'Tipo no encontrado'; RETURN; END
        UPDATE master.ProductType SET IsDeleted = 1, UpdatedAt = SYSUTCDATETIME() WHERE TypeId = @Codigo;
        SET @Resultado = 1; SET @Mensaje = N'OK';
    END TRY BEGIN CATCH SET @Resultado = -99; SET @Mensaje = ERROR_MESSAGE(); END CATCH
END
GO

-- =============================================================================
-- SECCIÓN 8: usp_Unidades_*  →  master.UnitOfMeasure
--   Legacy columns: Id (INT), Unidad (NVARCHAR), Cantidad (FLOAT)
--   Nota: GetById usa @Id (no @Codigo)
-- =============================================================================

IF OBJECT_ID(N'usp_Unidades_List', N'P') IS NOT NULL DROP PROCEDURE usp_Unidades_List;
GO
CREATE PROCEDURE usp_Unidades_List
    @Search     NVARCHAR(100) = NULL,
    @Page       INT = 1,
    @Limit      INT = 50,
    @TotalCount INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Offset INT = (ISNULL(NULLIF(@Page,0),1) - 1) * ISNULL(NULLIF(@Limit,0),50);
    IF @Offset < 0 SET @Offset = 0; IF @Limit < 1 SET @Limit = 50; IF @Limit > 500 SET @Limit = 500;
    DECLARE @S NVARCHAR(100) = CASE WHEN @Search IS NOT NULL AND LTRIM(RTRIM(@Search)) <> N'' THEN N'%' + @Search + N'%' ELSE NULL END;
    SELECT @TotalCount = COUNT(1) FROM master.UnitOfMeasure
    WHERE IsDeleted = 0 AND (@S IS NULL OR UnitCode LIKE @S OR Description LIKE @S);
    SELECT UnitId AS Id, UnitCode AS Unidad, ConversionFactor AS Cantidad
    FROM master.UnitOfMeasure
    WHERE IsDeleted = 0 AND (@S IS NULL OR UnitCode LIKE @S OR Description LIKE @S)
    ORDER BY UnitId OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;
END
GO

IF OBJECT_ID(N'usp_Unidades_GetById', N'P') IS NOT NULL DROP PROCEDURE usp_Unidades_GetById;
GO
CREATE PROCEDURE usp_Unidades_GetById @Id INT
AS BEGIN SET NOCOUNT ON;
    SELECT UnitId AS Id, UnitCode AS Unidad, ConversionFactor AS Cantidad
    FROM master.UnitOfMeasure WHERE UnitId = @Id AND IsDeleted = 0;
END
GO

IF OBJECT_ID(N'usp_Unidades_Insert', N'P') IS NOT NULL DROP PROCEDURE usp_Unidades_Insert;
GO
CREATE PROCEDURE usp_Unidades_Insert
    @RowXml NVARCHAR(MAX), @Resultado INT OUTPUT, @Mensaje NVARCHAR(500) OUTPUT, @NuevoId INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON; SET @Resultado = 0; SET @Mensaje = N''; SET @NuevoId = 0;
    DECLARE @x XML = CAST(@RowXml AS XML);
    DECLARE @Unidad   NVARCHAR(20) = NULLIF(@x.value('(/row/@Unidad)[1]',  'NVARCHAR(20)'),N'');
    DECLARE @CantStr  NVARCHAR(50) = NULLIF(@x.value('(/row/@Cantidad)[1]','NVARCHAR(50)'),N'');
    DECLARE @Cantidad DECIMAL(18,4) = CASE WHEN ISNUMERIC(@CantStr) = 1 THEN CAST(@CantStr AS DECIMAL(18,4)) ELSE NULL END;
    BEGIN TRY
        IF @Unidad IS NULL BEGIN SET @Resultado = -1; SET @Mensaje = N'Unidad requerida'; RETURN; END
        INSERT INTO master.UnitOfMeasure (UnitCode, Description, ConversionFactor)
        VALUES (@Unidad, @Unidad, @Cantidad);
        SET @NuevoId = CAST(SCOPE_IDENTITY() AS INT);
        SET @Resultado = 1; SET @Mensaje = N'OK';
    END TRY BEGIN CATCH SET @Resultado = -99; SET @Mensaje = ERROR_MESSAGE(); END CATCH
END
GO

IF OBJECT_ID(N'usp_Unidades_Update', N'P') IS NOT NULL DROP PROCEDURE usp_Unidades_Update;
GO
CREATE PROCEDURE usp_Unidades_Update
    @Id INT, @RowXml NVARCHAR(MAX), @Resultado INT OUTPUT, @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON; SET @Resultado = 0; SET @Mensaje = N'';
    DECLARE @x XML = CAST(@RowXml AS XML);
    DECLARE @CantStr  NVARCHAR(50) = NULLIF(@x.value('(/row/@Cantidad)[1]','NVARCHAR(50)'),N'');
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM master.UnitOfMeasure WHERE UnitId = @Id AND IsDeleted = 0)
        BEGIN SET @Resultado = -1; SET @Mensaje = N'Unidad no encontrada'; RETURN; END
        UPDATE master.UnitOfMeasure SET
            UnitCode         = COALESCE(NULLIF(@x.value('(/row/@Unidad)[1]','NVARCHAR(20)'),N''), UnitCode),
            Description      = COALESCE(NULLIF(@x.value('(/row/@Unidad)[1]','NVARCHAR(20)'),N''), Description),
            ConversionFactor = CASE WHEN @CantStr IS NULL THEN ConversionFactor
                                    WHEN ISNUMERIC(@CantStr) = 1 THEN CAST(@CantStr AS DECIMAL(18,4))
                                    ELSE ConversionFactor END,
            UpdatedAt        = SYSUTCDATETIME()
        WHERE UnitId = @Id;
        SET @Resultado = 1; SET @Mensaje = N'OK';
    END TRY BEGIN CATCH SET @Resultado = -99; SET @Mensaje = ERROR_MESSAGE(); END CATCH
END
GO

IF OBJECT_ID(N'usp_Unidades_Delete', N'P') IS NOT NULL DROP PROCEDURE usp_Unidades_Delete;
GO
CREATE PROCEDURE usp_Unidades_Delete
    @Id INT, @Resultado INT OUTPUT, @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON; SET @Resultado = 0; SET @Mensaje = N'';
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM master.UnitOfMeasure WHERE UnitId = @Id AND IsDeleted = 0)
        BEGIN SET @Resultado = -1; SET @Mensaje = N'Unidad no encontrada'; RETURN; END
        UPDATE master.UnitOfMeasure SET IsDeleted = 1, UpdatedAt = SYSUTCDATETIME() WHERE UnitId = @Id;
        SET @Resultado = 1; SET @Mensaje = N'OK';
    END TRY BEGIN CATCH SET @Resultado = -99; SET @Mensaje = ERROR_MESSAGE(); END CATCH
END
GO

-- =============================================================================
-- SECCIÓN 9: usp_Vendedores_*  →  master.Seller
--   Legacy columns: Codigo(NVARCHAR), Nombre, Comision, Direccion, Telefonos,
--                   Email, Status, Tipo, clave  + Rangos de comisión (ignored)
-- =============================================================================

IF OBJECT_ID(N'usp_Vendedores_List', N'P') IS NOT NULL DROP PROCEDURE usp_Vendedores_List;
GO
CREATE PROCEDURE usp_Vendedores_List
    @Search     NVARCHAR(100) = NULL,
    @Status     BIT  = NULL,
    @Tipo       NVARCHAR(50) = NULL,
    @Page       INT = 1,
    @Limit      INT = 50,
    @TotalCount INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Offset INT = (ISNULL(NULLIF(@Page,0),1) - 1) * ISNULL(NULLIF(@Limit,0),50);
    IF @Offset < 0 SET @Offset = 0; IF @Limit < 1 SET @Limit = 50; IF @Limit > 500 SET @Limit = 500;
    DECLARE @S NVARCHAR(100) = CASE WHEN @Search IS NOT NULL AND LTRIM(RTRIM(@Search)) <> N'' THEN N'%' + @Search + N'%' ELSE NULL END;
    SELECT @TotalCount = COUNT(1) FROM master.Seller
    WHERE IsDeleted = 0
      AND (@S IS NULL OR SellerCode LIKE @S OR SellerName LIKE @S OR Email LIKE @S)
      AND (@Status IS NULL OR IsActive = @Status)
      AND (@Tipo IS NULL OR SellerType = @Tipo);
    SELECT
        SellerCode AS Codigo,
        SellerName AS Nombre,
        CAST(Commission AS FLOAT) AS Comision,
        Address AS Direccion,
        Phone AS Telefonos,
        Email,
        IsActive AS Status,
        SellerType AS Tipo,
        CAST(NULL AS NVARCHAR(50)) AS clave,
        CAST(NULL AS FLOAT) AS Rango_ventas_Uno,
        CAST(NULL AS FLOAT) AS [Comision_ ventas_Uno],
        CAST(NULL AS FLOAT) AS Rango_ventas_dos,
        CAST(NULL AS FLOAT) AS [Comision_ ventas_dos],
        CAST(NULL AS FLOAT) AS Rango_ventas_tres,
        CAST(NULL AS FLOAT) AS [Comision_ ventas_tres],
        CAST(NULL AS FLOAT) AS Rango_ventas_Cuatro,
        CAST(NULL AS FLOAT) AS [Comision_ ventas_Cuatro]
    FROM master.Seller
    WHERE IsDeleted = 0
      AND (@S IS NULL OR SellerCode LIKE @S OR SellerName LIKE @S OR Email LIKE @S)
      AND (@Status IS NULL OR IsActive = @Status)
      AND (@Tipo IS NULL OR SellerType = @Tipo)
    ORDER BY SellerCode OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;
END
GO

IF OBJECT_ID(N'usp_Vendedores_GetByCodigo', N'P') IS NOT NULL DROP PROCEDURE usp_Vendedores_GetByCodigo;
GO
CREATE PROCEDURE usp_Vendedores_GetByCodigo @Codigo NVARCHAR(10)
AS BEGIN SET NOCOUNT ON;
    SELECT SellerCode AS Codigo, SellerName AS Nombre, CAST(Commission AS FLOAT) AS Comision,
           Address AS Direccion, Phone AS Telefonos, Email, IsActive AS Status, SellerType AS Tipo,
           CAST(NULL AS NVARCHAR(50)) AS clave
    FROM master.Seller WHERE SellerCode = @Codigo AND IsDeleted = 0;
END
GO

IF OBJECT_ID(N'usp_Vendedores_Insert', N'P') IS NOT NULL DROP PROCEDURE usp_Vendedores_Insert;
GO
CREATE PROCEDURE usp_Vendedores_Insert
    @RowXml NVARCHAR(MAX), @Resultado INT OUTPUT, @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON; SET @Resultado = 0; SET @Mensaje = N'';
    DECLARE @x XML = CAST(@RowXml AS XML);
    DECLARE @Codigo   NVARCHAR(10) = NULLIF(@x.value('(/row/@Codigo)[1]',   'NVARCHAR(10)'), N'');
    DECLARE @Nombre   NVARCHAR(120)= NULLIF(@x.value('(/row/@Nombre)[1]',   'NVARCHAR(120)'),N'');
    DECLARE @ComStr   NVARCHAR(50) = NULLIF(@x.value('(/row/@Comision)[1]', 'NVARCHAR(50)'), N'');
    DECLARE @Direccion NVARCHAR(250)= NULLIF(@x.value('(/row/@Direccion)[1]','NVARCHAR(250)'),N'');
    DECLARE @Telef    NVARCHAR(60) = NULLIF(@x.value('(/row/@Telefonos)[1]','NVARCHAR(60)'), N'');
    DECLARE @Email    NVARCHAR(150)= NULLIF(@x.value('(/row/@Email)[1]',    'NVARCHAR(150)'),N'');
    DECLARE @Status   BIT          = ISNULL(@x.value('(/row/@Status)[1]',   'BIT'),           1);
    DECLARE @Tipo     NVARCHAR(20) = ISNULL(NULLIF(@x.value('(/row/@Tipo)[1]','NVARCHAR(20)'),N''), N'INTERNO');
    DECLARE @Comision DECIMAL(5,2) = CASE WHEN ISNUMERIC(@ComStr) = 1 THEN CAST(@ComStr AS DECIMAL(5,2)) ELSE 0 END;
    BEGIN TRY
        IF @Codigo IS NULL BEGIN SET @Resultado = -1; SET @Mensaje = N'Codigo requerido'; RETURN; END
        IF EXISTS (SELECT 1 FROM master.Seller WHERE SellerCode = @Codigo AND IsDeleted = 0)
        BEGIN SET @Resultado = -1; SET @Mensaje = N'Vendedor ya existe'; RETURN; END
        INSERT INTO master.Seller (SellerCode, SellerName, Commission, Address, Phone, Email, IsActive, SellerType)
        VALUES (@Codigo, COALESCE(@Nombre, @Codigo), @Comision, @Direccion, @Telef, @Email, @Status, @Tipo);
        SET @Resultado = 1; SET @Mensaje = N'OK';
    END TRY BEGIN CATCH SET @Resultado = -99; SET @Mensaje = ERROR_MESSAGE(); END CATCH
END
GO

IF OBJECT_ID(N'usp_Vendedores_Update', N'P') IS NOT NULL DROP PROCEDURE usp_Vendedores_Update;
GO
CREATE PROCEDURE usp_Vendedores_Update
    @Codigo NVARCHAR(10), @RowXml NVARCHAR(MAX), @Resultado INT OUTPUT, @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON; SET @Resultado = 0; SET @Mensaje = N'';
    DECLARE @x XML = CAST(@RowXml AS XML);
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM master.Seller WHERE SellerCode = @Codigo AND IsDeleted = 0)
        BEGIN SET @Resultado = -1; SET @Mensaje = N'Vendedor no encontrado'; RETURN; END
        DECLARE @ComStr NVARCHAR(50) = NULLIF(@x.value('(/row/@Comision)[1]','NVARCHAR(50)'),N'');
        UPDATE master.Seller SET
            SellerName = COALESCE(NULLIF(@x.value('(/row/@Nombre)[1]',    'NVARCHAR(120)'),N''), SellerName),
            Commission = CASE WHEN @ComStr IS NULL THEN Commission
                              WHEN ISNUMERIC(@ComStr) = 1 THEN CAST(@ComStr AS DECIMAL(5,2))
                              ELSE Commission END,
            Address    = COALESCE(NULLIF(@x.value('(/row/@Direccion)[1]', 'NVARCHAR(250)'),N''), Address),
            Phone      = COALESCE(NULLIF(@x.value('(/row/@Telefonos)[1]','NVARCHAR(60)'), N''), Phone),
            Email      = COALESCE(NULLIF(@x.value('(/row/@Email)[1]',    'NVARCHAR(150)'),N''), Email),
            IsActive   = ISNULL(@x.value('(/row/@Status)[1]','BIT'), IsActive),
            SellerType = COALESCE(NULLIF(@x.value('(/row/@Tipo)[1]',     'NVARCHAR(20)'), N''), SellerType),
            UpdatedAt  = SYSUTCDATETIME()
        WHERE SellerCode = @Codigo;
        SET @Resultado = 1; SET @Mensaje = N'OK';
    END TRY BEGIN CATCH SET @Resultado = -99; SET @Mensaje = ERROR_MESSAGE(); END CATCH
END
GO

IF OBJECT_ID(N'usp_Vendedores_Delete', N'P') IS NOT NULL DROP PROCEDURE usp_Vendedores_Delete;
GO
CREATE PROCEDURE usp_Vendedores_Delete
    @Codigo NVARCHAR(10), @Resultado INT OUTPUT, @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON; SET @Resultado = 0; SET @Mensaje = N'';
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM master.Seller WHERE SellerCode = @Codigo AND IsDeleted = 0)
        BEGIN SET @Resultado = -1; SET @Mensaje = N'Vendedor no encontrado'; RETURN; END
        UPDATE master.Seller SET IsDeleted = 1, UpdatedAt = SYSUTCDATETIME() WHERE SellerCode = @Codigo;
        SET @Resultado = 1; SET @Mensaje = N'OK';
    END TRY BEGIN CATCH SET @Resultado = -99; SET @Mensaje = ERROR_MESSAGE(); END CATCH
END
GO

-- =============================================================================
-- SECCIÓN 10: usp_CentroCosto_*  →  master.CostCenter
--   Legacy columns: Codigo (NVARCHAR(50)), Descripcion, Presupuestado, Saldo_Real
-- =============================================================================

IF OBJECT_ID(N'usp_CentroCosto_List', N'P') IS NOT NULL DROP PROCEDURE usp_CentroCosto_List;
GO
CREATE PROCEDURE usp_CentroCosto_List
    @Search     NVARCHAR(100) = NULL,
    @Page       INT = 1,
    @Limit      INT = 50,
    @TotalCount INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Offset INT = (ISNULL(NULLIF(@Page,0),1) - 1) * ISNULL(NULLIF(@Limit,0),50);
    IF @Offset < 0 SET @Offset = 0; IF @Limit < 1 SET @Limit = 50; IF @Limit > 500 SET @Limit = 500;
    DECLARE @S NVARCHAR(100) = CASE WHEN @Search IS NOT NULL AND LTRIM(RTRIM(@Search)) <> N'' THEN N'%' + @Search + N'%' ELSE NULL END;
    SELECT @TotalCount = COUNT(1) FROM master.CostCenter
    WHERE IsDeleted = 0 AND (@S IS NULL OR CostCenterCode LIKE @S OR CostCenterName LIKE @S);
    SELECT CostCenterCode AS Codigo, CostCenterName AS Descripcion,
           CAST(NULL AS NVARCHAR(50)) AS Presupuestado,
           CAST(NULL AS NVARCHAR(50)) AS Saldo_Real
    FROM master.CostCenter
    WHERE IsDeleted = 0 AND (@S IS NULL OR CostCenterCode LIKE @S OR CostCenterName LIKE @S)
    ORDER BY CostCenterCode OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;
END
GO

IF OBJECT_ID(N'usp_CentroCosto_GetByCodigo', N'P') IS NOT NULL DROP PROCEDURE usp_CentroCosto_GetByCodigo;
GO
CREATE PROCEDURE usp_CentroCosto_GetByCodigo @Codigo NVARCHAR(50)
AS BEGIN SET NOCOUNT ON;
    SELECT CostCenterCode AS Codigo, CostCenterName AS Descripcion,
           CAST(NULL AS NVARCHAR(50)) AS Presupuestado,
           CAST(NULL AS NVARCHAR(50)) AS Saldo_Real
    FROM master.CostCenter WHERE CostCenterCode = @Codigo AND IsDeleted = 0;
END
GO

IF OBJECT_ID(N'usp_CentroCosto_Insert', N'P') IS NOT NULL DROP PROCEDURE usp_CentroCosto_Insert;
GO
CREATE PROCEDURE usp_CentroCosto_Insert
    @RowXml NVARCHAR(MAX), @Resultado INT OUTPUT, @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON; SET @Resultado = 0; SET @Mensaje = N'';
    DECLARE @x XML = CAST(@RowXml AS XML);
    DECLARE @Codigo NVARCHAR(20) = NULLIF(@x.value('(/row/@Codigo)[1]',     'NVARCHAR(20)'),N'');
    DECLARE @Desc   NVARCHAR(100)= NULLIF(@x.value('(/row/@Descripcion)[1]','NVARCHAR(100)'),N'');
    BEGIN TRY
        IF @Codigo IS NULL BEGIN SET @Resultado = -1; SET @Mensaje = N'Codigo requerido'; RETURN; END
        IF EXISTS (SELECT 1 FROM master.CostCenter WHERE CostCenterCode = @Codigo AND IsDeleted = 0)
        BEGIN SET @Resultado = -1; SET @Mensaje = N'Centro de costo ya existe'; RETURN; END
        INSERT INTO master.CostCenter (CostCenterCode, CostCenterName)
        VALUES (@Codigo, COALESCE(@Desc, @Codigo));
        SET @Resultado = 1; SET @Mensaje = N'OK';
    END TRY BEGIN CATCH SET @Resultado = -99; SET @Mensaje = ERROR_MESSAGE(); END CATCH
END
GO

IF OBJECT_ID(N'usp_CentroCosto_Update', N'P') IS NOT NULL DROP PROCEDURE usp_CentroCosto_Update;
GO
CREATE PROCEDURE usp_CentroCosto_Update
    @Codigo NVARCHAR(50), @RowXml NVARCHAR(MAX), @Resultado INT OUTPUT, @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON; SET @Resultado = 0; SET @Mensaje = N'';
    DECLARE @x XML = CAST(@RowXml AS XML);
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM master.CostCenter WHERE CostCenterCode = @Codigo AND IsDeleted = 0)
        BEGIN SET @Resultado = -1; SET @Mensaje = N'Centro de costo no encontrado'; RETURN; END
        UPDATE master.CostCenter SET
            CostCenterName = COALESCE(NULLIF(@x.value('(/row/@Descripcion)[1]','NVARCHAR(100)'),N''), CostCenterName),
            UpdatedAt      = SYSUTCDATETIME()
        WHERE CostCenterCode = @Codigo;
        SET @Resultado = 1; SET @Mensaje = N'OK';
    END TRY BEGIN CATCH SET @Resultado = -99; SET @Mensaje = ERROR_MESSAGE(); END CATCH
END
GO

IF OBJECT_ID(N'usp_CentroCosto_Delete', N'P') IS NOT NULL DROP PROCEDURE usp_CentroCosto_Delete;
GO
CREATE PROCEDURE usp_CentroCosto_Delete
    @Codigo NVARCHAR(50), @Resultado INT OUTPUT, @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON; SET @Resultado = 0; SET @Mensaje = N'';
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM master.CostCenter WHERE CostCenterCode = @Codigo AND IsDeleted = 0)
        BEGIN SET @Resultado = -1; SET @Mensaje = N'Centro de costo no encontrado'; RETURN; END
        UPDATE master.CostCenter SET IsDeleted = 1, UpdatedAt = SYSUTCDATETIME() WHERE CostCenterCode = @Codigo;
        SET @Resultado = 1; SET @Mensaje = N'OK';
    END TRY BEGIN CATCH SET @Resultado = -99; SET @Mensaje = ERROR_MESSAGE(); END CATCH
END
GO

-- =============================================================================
-- SECCIÓN 11: usp_Empresa_Get / usp_Empresa_Update
--   → cfg.Company JOIN cfg.CompanyProfile (CompanyId = 1 = empresa principal)
--   Legacy columns: Empresa, RIF, Nit, Telefono, Direccion, Rifs
-- =============================================================================

IF OBJECT_ID(N'usp_Empresa_Get', N'P') IS NOT NULL DROP PROCEDURE usp_Empresa_Get;
GO
CREATE PROCEDURE usp_Empresa_Get
AS
BEGIN
    SET NOCOUNT ON;
    SELECT TOP 1
        c.LegalName    AS Empresa,
        c.FiscalId     AS RIF,
        cp.NitCode     AS Nit,
        cp.Phone       AS Telefono,
        cp.AddressLine AS Direccion,
        cp.AltFiscalId AS Rifs
    FROM cfg.Company c
    LEFT JOIN cfg.CompanyProfile cp ON cp.CompanyId = c.CompanyId
    WHERE c.IsDeleted = 0
    ORDER BY c.CompanyId;
END
GO

IF OBJECT_ID(N'usp_Empresa_Update', N'P') IS NOT NULL DROP PROCEDURE usp_Empresa_Update;
GO
CREATE PROCEDURE usp_Empresa_Update
    @RowXml    NVARCHAR(MAX),
    @Resultado INT OUTPUT,
    @Mensaje   NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON; SET @Resultado = 0; SET @Mensaje = N'';
    DECLARE @x XML = CAST(@RowXml AS XML);
    BEGIN TRY
        DECLARE @CompanyId INT;
        SELECT TOP 1 @CompanyId = CompanyId FROM cfg.Company WHERE IsDeleted = 0 ORDER BY CompanyId;
        IF @CompanyId IS NULL BEGIN SET @Resultado = -1; SET @Mensaje = N'Empresa no encontrada'; RETURN; END

        -- Actualizar cfg.Company
        UPDATE cfg.Company SET
            LegalName  = COALESCE(NULLIF(@x.value('(/row/@Empresa)[1]','NVARCHAR(200)'),N''), LegalName),
            FiscalId   = COALESCE(NULLIF(@x.value('(/row/@RIF)[1]',    'NVARCHAR(30)'), N''), FiscalId),
            UpdatedAt  = SYSUTCDATETIME()
        WHERE CompanyId = @CompanyId;

        -- Actualizar o crear cfg.CompanyProfile
        IF EXISTS (SELECT 1 FROM cfg.CompanyProfile WHERE CompanyId = @CompanyId)
        BEGIN
            UPDATE cfg.CompanyProfile SET
                NitCode    = COALESCE(NULLIF(@x.value('(/row/@Nit)[1]',      'NVARCHAR(50)'), N''), NitCode),
                Phone      = COALESCE(NULLIF(@x.value('(/row/@Telefono)[1]', 'NVARCHAR(60)'), N''), Phone),
                AddressLine= COALESCE(NULLIF(@x.value('(/row/@Direccion)[1]','NVARCHAR(250)'),N''), AddressLine),
                AltFiscalId= COALESCE(NULLIF(@x.value('(/row/@Rifs)[1]',    'NVARCHAR(50)'), N''), AltFiscalId),
                UpdatedAt  = SYSUTCDATETIME()
            WHERE CompanyId = @CompanyId;
        END
        ELSE
        BEGIN
            INSERT INTO cfg.CompanyProfile (CompanyId, NitCode, Phone, AddressLine, AltFiscalId)
            VALUES (
                @CompanyId,
                NULLIF(@x.value('(/row/@Nit)[1]',      'NVARCHAR(50)'), N''),
                NULLIF(@x.value('(/row/@Telefono)[1]', 'NVARCHAR(60)'), N''),
                NULLIF(@x.value('(/row/@Direccion)[1]','NVARCHAR(250)'),N''),
                NULLIF(@x.value('(/row/@Rifs)[1]',     'NVARCHAR(50)'), N'')
            );
        END

        SET @Resultado = 1; SET @Mensaje = N'OK';
    END TRY BEGIN CATCH SET @Resultado = -99; SET @Mensaje = ERROR_MESSAGE(); END CATCH
END
GO

PRINT '[20] SPs maestros canónicos reconstruidos correctamente.';
GO
