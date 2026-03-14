-- =============================================
-- Stored Procedures CRUD: Almacen
-- Compatible con: SQL Server 2012+
-- Tabla canonica: master.Warehouse (antes dbo.Almacen / dbo.Almacenes)
-- PK: WarehouseCode unico por CompanyId
-- =============================================

-- ---------- 1. List (paginado con filtros) ----------
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_Almacen_List')
    DROP PROCEDURE usp_Almacen_List
GO
CREATE PROCEDURE usp_Almacen_List
    @Search NVARCHAR(100) = NULL,
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
    DECLARE @Params NVARCHAR(500) = N'@Search NVARCHAR(100), @Tipo NVARCHAR(50), @Offset INT, @Limit INT, @TotalCount INT OUTPUT';

    -- Filtro base: solo registros no eliminados
    SET @Where = N' AND ISNULL(IsDeleted, 0) = 0';

    IF @Search IS NOT NULL AND LTRIM(RTRIM(@Search)) <> N''
        SET @Where = @Where + N' AND (WarehouseCode LIKE @Search OR Description LIKE @Search)';
    IF @Tipo IS NOT NULL AND LTRIM(RTRIM(@Tipo)) <> N''
        SET @Where = @Where + N' AND WarehouseType = @Tipo';

    SET @Where = N' WHERE ' + STUFF(@Where, 1, 5, N'');

    DECLARE @SearchParam NVARCHAR(100) = NULL;
    IF @Search IS NOT NULL AND LTRIM(RTRIM(@Search)) <> N''
        SET @SearchParam = N'%' + @Search + N'%';

    SET @Sql = N'
    SELECT @TotalCount = COUNT(1) FROM [master].[Warehouse] ' + @Where + N';
    SELECT
        WarehouseCode  AS Codigo,
        Description    AS Descripcion,
        WarehouseType  AS Tipo,
        IsActive,
        IsDeleted,
        CompanyId,
        WarehouseCode, Description, WarehouseType
    FROM [master].[Warehouse] ' + @Where + N'
    ORDER BY WarehouseCode
    OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;';

    EXEC sp_executesql @Sql, @Params,
        @Search = @SearchParam,
        @Tipo = @Tipo,
        @Offset = @Offset,
        @Limit = @Limit,
        @TotalCount = @TotalCount OUTPUT;
END
GO

-- ---------- 2. Get by Codigo ----------
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_Almacen_GetByCodigo')
    DROP PROCEDURE usp_Almacen_GetByCodigo
GO
CREATE PROCEDURE usp_Almacen_GetByCodigo
    @Codigo NVARCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT
        WarehouseCode  AS Codigo,
        Description    AS Descripcion,
        WarehouseType  AS Tipo,
        IsActive,
        IsDeleted,
        CompanyId,
        WarehouseCode, Description, WarehouseType
    FROM [master].[Warehouse]
    WHERE WarehouseCode = @Codigo
      AND ISNULL(IsDeleted, 0) = 0;
END
GO

-- ---------- 3. Insert ----------
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_Almacen_Insert')
    DROP PROCEDURE usp_Almacen_Insert
GO
CREATE PROCEDURE usp_Almacen_Insert
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
        IF EXISTS (SELECT 1 FROM [master].[Warehouse] WHERE WarehouseCode = @xml.value('(/row/@Codigo)[1]', 'NVARCHAR(10)') AND CompanyId = @CompanyId)
        BEGIN
            SET @Resultado = -1;
            SET @Mensaje = N'Almacen ya existe';
            RETURN;
        END

        INSERT INTO [master].[Warehouse] (
            WarehouseCode, Description, WarehouseType,
            IsActive, IsDeleted, CompanyId
        )
        SELECT
            NULLIF(r.value('@Codigo', 'NVARCHAR(10)'), N''),
            NULLIF(r.value('@Descripcion', 'NVARCHAR(100)'), N''),
            NULLIF(r.value('@Tipo', 'NVARCHAR(50)'), N''),
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
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_Almacen_Update')
    DROP PROCEDURE usp_Almacen_Update
GO
CREATE PROCEDURE usp_Almacen_Update
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
        IF NOT EXISTS (SELECT 1 FROM [master].[Warehouse] WHERE WarehouseCode = @Codigo AND ISNULL(IsDeleted, 0) = 0)
        BEGIN
            SET @Resultado = -1;
            SET @Mensaje = N'Almacen no encontrado';
            RETURN;
        END

        UPDATE a SET
            Description = COALESCE(NULLIF(r.value('@Descripcion', 'NVARCHAR(100)'), N''), a.Description),
            WarehouseType = COALESCE(NULLIF(r.value('@Tipo', 'NVARCHAR(50)'), N''), a.WarehouseType)
        FROM [master].[Warehouse] a
        CROSS JOIN @xml.nodes('/row') T(r)
        WHERE a.WarehouseCode = @Codigo AND ISNULL(a.IsDeleted, 0) = 0;

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
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_Almacen_Delete')
    DROP PROCEDURE usp_Almacen_Delete
GO
CREATE PROCEDURE usp_Almacen_Delete
    @Codigo NVARCHAR(10),
    @Resultado INT OUTPUT,
    @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Resultado = 0;
    SET @Mensaje = N'';

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM [master].[Warehouse] WHERE WarehouseCode = @Codigo AND ISNULL(IsDeleted, 0) = 0)
        BEGIN
            SET @Resultado = -1;
            SET @Mensaje = N'Almacen no encontrado';
            RETURN;
        END

        UPDATE [master].[Warehouse]
        SET IsDeleted = 1, IsActive = 0
        WHERE WarehouseCode = @Codigo;

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
SELECT name, create_date FROM sys.objects WHERE type = 'P' AND name LIKE 'usp_Almacen_%';
