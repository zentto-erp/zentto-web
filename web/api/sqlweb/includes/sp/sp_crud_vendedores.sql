-- =============================================
-- Stored Procedures CRUD: Vendedores
-- Compatible con: SQL Server 2012+
-- Tabla canonica: master.Seller (antes dbo.Vendedor)
-- PK: SellerCode unico por CompanyId
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

    -- Filtro base: solo registros no eliminados
    SET @Where = N' AND ISNULL(IsDeleted, 0) = 0';

    IF @Search IS NOT NULL AND LTRIM(RTRIM(@Search)) <> N''
        SET @Where = @Where + N' AND (SellerCode LIKE @Search OR SellerName LIKE @Search OR Email LIKE @Search)';
    IF @Status IS NOT NULL
        SET @Where = @Where + N' AND IsActive = @Status';
    IF @Tipo IS NOT NULL AND LTRIM(RTRIM(@Tipo)) <> N''
        SET @Where = @Where + N' AND Tipo = @Tipo';

    SET @Where = N' WHERE ' + STUFF(@Where, 1, 5, N'');

    DECLARE @SearchParam NVARCHAR(100) = NULL;
    IF @Search IS NOT NULL AND LTRIM(RTRIM(@Search)) <> N''
        SET @SearchParam = N'%' + @Search + N'%';

    SET @Sql = N'
    SELECT @TotalCount = COUNT(1) FROM [master].[Seller] ' + @Where + N';
    SELECT
        SellerCode  AS Codigo,
        SellerName  AS Nombre,
        Commission  AS Comision,
        IsActive    AS Status,
        IsActive, IsDeleted, CompanyId,
        SellerCode, SellerName, Commission,
        Direccion, Telefonos, Email, Tipo, Clave,
        RangoVentasUno, ComisionVentasUno,
        RangoVentasDos, ComisionVentasDos,
        RangoVentasTres, ComisionVentasTres,
        RangoVentasCuatro, ComisionVentasCuatro
    FROM [master].[Seller] ' + @Where + N'
    ORDER BY SellerCode
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
    SELECT
        SellerCode  AS Codigo,
        SellerName  AS Nombre,
        Commission  AS Comision,
        IsActive    AS Status,
        IsActive, IsDeleted, CompanyId,
        SellerCode, SellerName, Commission,
        Direccion, Telefonos, Email, Tipo, Clave,
        RangoVentasUno, ComisionVentasUno,
        RangoVentasDos, ComisionVentasDos,
        RangoVentasTres, ComisionVentasTres,
        RangoVentasCuatro, ComisionVentasCuatro
    FROM [master].[Seller]
    WHERE SellerCode = @Codigo
      AND ISNULL(IsDeleted, 0) = 0;
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
    DECLARE @CompanyId INT = (SELECT TOP 1 CompanyId FROM cfg.Company WHERE ISNULL(IsDeleted, 0) = 0 ORDER BY CompanyId);
    IF @CompanyId IS NULL SET @CompanyId = 1;

    BEGIN TRY
        IF EXISTS (SELECT 1 FROM [master].[Seller] WHERE SellerCode = @xml.value('(/row/@Codigo)[1]', 'NVARCHAR(10)') AND CompanyId = @CompanyId)
        BEGIN
            SET @Resultado = -1;
            SET @Mensaje = N'Vendedor ya existe';
            RETURN;
        END

        INSERT INTO [master].[Seller] (
            SellerCode, SellerName, Commission, Direccion, Telefonos, Email,
            RangoVentasUno, ComisionVentasUno,
            RangoVentasDos, ComisionVentasDos,
            RangoVentasTres, ComisionVentasTres,
            RangoVentasCuatro, ComisionVentasCuatro,
            IsActive, Tipo, Clave, IsDeleted, CompanyId
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
            NULLIF(r.value('@clave', 'NVARCHAR(50)'), N''),
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
        IF NOT EXISTS (SELECT 1 FROM [master].[Seller] WHERE SellerCode = @Codigo AND ISNULL(IsDeleted, 0) = 0)
        BEGIN
            SET @Resultado = -1;
            SET @Mensaje = N'Vendedor no encontrado';
            RETURN;
        END

        UPDATE v SET
            SellerName = COALESCE(NULLIF(r.value('@Nombre', 'NVARCHAR(100)'), N''), v.SellerName),
            Commission = CASE WHEN r.value('@Comision', 'NVARCHAR(50)') IS NULL OR r.value('@Comision', 'NVARCHAR(50)') = '' THEN v.Commission ELSE CAST(r.value('@Comision', 'NVARCHAR(50)') AS FLOAT) END,
            Direccion = COALESCE(NULLIF(r.value('@Direccion', 'NVARCHAR(255)'), N''), v.Direccion),
            Telefonos = COALESCE(NULLIF(r.value('@Telefonos', 'NVARCHAR(60)'), N''), v.Telefonos),
            Email = COALESCE(NULLIF(r.value('@Email', 'NVARCHAR(100)'), N''), v.Email),
            IsActive = ISNULL(r.value('@Status', 'BIT'), v.IsActive),
            Tipo = COALESCE(NULLIF(r.value('@Tipo', 'NVARCHAR(50)'), N''), v.Tipo),
            Clave = COALESCE(NULLIF(r.value('@clave', 'NVARCHAR(50)'), N''), v.Clave)
        FROM [master].[Seller] v
        CROSS JOIN @xml.nodes('/row') T(r)
        WHERE v.SellerCode = @Codigo AND ISNULL(v.IsDeleted, 0) = 0;

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
        IF NOT EXISTS (SELECT 1 FROM [master].[Seller] WHERE SellerCode = @Codigo AND ISNULL(IsDeleted, 0) = 0)
        BEGIN
            SET @Resultado = -1;
            SET @Mensaje = N'Vendedor no encontrado';
            RETURN;
        END

        UPDATE [master].[Seller]
        SET IsDeleted = 1, IsActive = 0
        WHERE SellerCode = @Codigo;

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
