-- =============================================
-- Stored Procedures CRUD: Proveedores
-- Compatible con: SQL Server 2012+
-- Tabla canonica: master.Supplier (antes dbo.Proveedores)
-- =============================================

-- ---------- 1. List (paginado con filtros) ----------
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_Proveedores_List')
    DROP PROCEDURE usp_Proveedores_List
GO
CREATE PROCEDURE usp_Proveedores_List
    @Search NVARCHAR(100) = NULL,
    @Estado NVARCHAR(60) = NULL,
    @Vendedor NVARCHAR(2) = NULL,
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
    DECLARE @Params NVARCHAR(500) = N'@Search NVARCHAR(100), @Estado NVARCHAR(60), @Vendedor NVARCHAR(2), @Offset INT, @Limit INT, @TotalCount INT OUTPUT';

    -- Filtro base: solo registros activos no eliminados
    SET @Where = N' AND ISNULL(IsDeleted, 0) = 0';

    IF @Search IS NOT NULL AND LTRIM(RTRIM(@Search)) <> N''
        SET @Where = @Where + N' AND (SupplierCode LIKE @Search OR SupplierName LIKE @Search OR FiscalId LIKE @Search)';
    IF @Estado IS NOT NULL AND LTRIM(RTRIM(@Estado)) <> N''
        SET @Where = @Where + N' AND ESTADO = @Estado';
    IF @Vendedor IS NOT NULL AND LTRIM(RTRIM(@Vendedor)) <> N''
        SET @Where = @Where + N' AND VENDEDOR = @Vendedor';

    SET @Where = N' WHERE ' + STUFF(@Where, 1, 5, N'');

    DECLARE @SearchParam NVARCHAR(100) = NULL;
    IF @Search IS NOT NULL AND LTRIM(RTRIM(@Search)) <> N''
        SET @SearchParam = N'%' + @Search + N'%';

    SET @Sql = N'
    SELECT @TotalCount = COUNT(1) FROM [master].[Supplier] ' + @Where + N';
    SELECT
        SupplierCode  AS CODIGO,
        SupplierName  AS NOMBRE,
        FiscalId      AS RIF,
        TotalBalance  AS SALDO_TOT,
        CreditLimit   AS LIMITE,
        IsActive,
        IsDeleted,
        CompanyId,
        SupplierCode, SupplierName, FiscalId, TotalBalance, CreditLimit,
        NIT, Direccion, Direccion1, Sucursal, Telefono, Fax,
        Contacto, VENDEDOR, ESTADO, Ciudad, CodPostal, Email, PaginaWww,
        CodUsuario, Credito, ListaPrecio, Notas
    FROM [master].[Supplier] ' + @Where + N'
    ORDER BY SupplierCode
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
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_Proveedores_GetByCodigo')
    DROP PROCEDURE usp_Proveedores_GetByCodigo
GO
CREATE PROCEDURE usp_Proveedores_GetByCodigo
    @Codigo NVARCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT
        SupplierCode  AS CODIGO,
        SupplierName  AS NOMBRE,
        FiscalId      AS RIF,
        TotalBalance  AS SALDO_TOT,
        CreditLimit   AS LIMITE,
        IsActive,
        IsDeleted,
        CompanyId,
        SupplierCode, SupplierName, FiscalId, TotalBalance, CreditLimit,
        NIT, Direccion, Direccion1, Sucursal, Telefono, Fax,
        Contacto, VENDEDOR, ESTADO, Ciudad, CodPostal, Email, PaginaWww,
        CodUsuario, Credito, ListaPrecio, Notas
    FROM [master].[Supplier]
    WHERE SupplierCode = @Codigo
      AND ISNULL(IsDeleted, 0) = 0;
END
GO

-- ---------- 3. Insert (fila como XML) ----------
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_Proveedores_Insert')
    DROP PROCEDURE usp_Proveedores_Insert
GO
CREATE PROCEDURE usp_Proveedores_Insert
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
        IF EXISTS (SELECT 1 FROM [master].[Supplier] WHERE SupplierCode = @xml.value('(/row/@CODIGO)[1]', 'NVARCHAR(10)') AND CompanyId = @CompanyId)
        BEGIN
            SET @Resultado = -1;
            SET @Mensaje = N'Proveedor ya existe';
            RETURN;
        END

        INSERT INTO [master].[Supplier] (
            SupplierCode, SupplierName, FiscalId, NIT, Direccion, Direccion1, Sucursal, Telefono, Fax,
            Contacto, VENDEDOR, ESTADO, Ciudad, CodPostal, Email, PaginaWww,
            CodUsuario, CreditLimit, Credito, ListaPrecio, Notas,
            IsActive, IsDeleted, CompanyId
        )
        SELECT
            NULLIF(r.value('@CODIGO', 'NVARCHAR(10)'), N''),
            NULLIF(r.value('@NOMBRE', 'NVARCHAR(255)'), N''),
            NULLIF(r.value('@RIF', 'NVARCHAR(20)'), N''),
            NULLIF(r.value('@NIT', 'NVARCHAR(20)'), N''),
            NULLIF(r.value('@DIRECCION', 'NVARCHAR(255)'), N''),
            NULLIF(r.value('@DIRECCION1', 'NVARCHAR(255)'), N''),
            NULLIF(r.value('@SUCURSAL', 'NVARCHAR(50)'), N''),
            NULLIF(r.value('@TELEFONO', 'NVARCHAR(60)'), N''),
            NULLIF(r.value('@FAX', 'NVARCHAR(10)'), N''),
            NULLIF(r.value('@CONTACTO', 'NVARCHAR(30)'), N''),
            NULLIF(r.value('@VENDEDOR', 'NVARCHAR(2)'), N''),
            NULLIF(r.value('@ESTADO', 'NVARCHAR(60)'), N''),
            NULLIF(r.value('@CIUDAD', 'NVARCHAR(30)'), N''),
            NULLIF(r.value('@CPOSTAL', 'NVARCHAR(10)'), N''),
            NULLIF(r.value('@EMAIL', 'NVARCHAR(50)'), N''),
            NULLIF(r.value('@PAGINA_WWW', 'NVARCHAR(50)'), N''),
            NULLIF(r.value('@COD_USUARIO', 'NVARCHAR(10)'), N''),
            CASE WHEN r.value('@LIMITE', 'NVARCHAR(50)') IS NULL OR r.value('@LIMITE', 'NVARCHAR(50)') = '' THEN NULL ELSE CAST(r.value('@LIMITE', 'NVARCHAR(50)') AS FLOAT) END,
            CASE WHEN r.value('@CREDITO', 'NVARCHAR(50)') IS NULL OR r.value('@CREDITO', 'NVARCHAR(50)') = '' THEN NULL ELSE CAST(r.value('@CREDITO', 'NVARCHAR(50)') AS FLOAT) END,
            CASE WHEN r.value('@LISTA_PRECIO', 'NVARCHAR(50)') IS NULL OR r.value('@LISTA_PRECIO', 'NVARCHAR(50)') = '' THEN 0 ELSE CAST(r.value('@LISTA_PRECIO', 'NVARCHAR(50)') AS INT) END,
            NULLIF(r.value('@NOTAS', 'NVARCHAR(50)'), N''),
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
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_Proveedores_Update')
    DROP PROCEDURE usp_Proveedores_Update
GO
CREATE PROCEDURE usp_Proveedores_Update
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
        IF NOT EXISTS (SELECT 1 FROM [master].[Supplier] WHERE SupplierCode = @Codigo AND ISNULL(IsDeleted, 0) = 0)
        BEGIN
            SET @Resultado = -1;
            SET @Mensaje = N'Proveedor no encontrado';
            RETURN;
        END

        UPDATE c SET
            SupplierName = COALESCE(NULLIF(r.value('@NOMBRE', 'NVARCHAR(255)'), N''), c.SupplierName),
            FiscalId = COALESCE(NULLIF(r.value('@RIF', 'NVARCHAR(20)'), N''), c.FiscalId),
            NIT = COALESCE(NULLIF(r.value('@NIT', 'NVARCHAR(20)'), N''), c.NIT),
            Direccion = COALESCE(NULLIF(r.value('@DIRECCION', 'NVARCHAR(255)'), N''), c.Direccion),
            Direccion1 = COALESCE(NULLIF(r.value('@DIRECCION1', 'NVARCHAR(255)'), N''), c.Direccion1),
            Sucursal = COALESCE(NULLIF(r.value('@SUCURSAL', 'NVARCHAR(50)'), N''), c.Sucursal),
            Telefono = COALESCE(NULLIF(r.value('@TELEFONO', 'NVARCHAR(60)'), N''), c.Telefono),
            Fax = COALESCE(NULLIF(r.value('@FAX', 'NVARCHAR(10)'), N''), c.Fax),
            Contacto = COALESCE(NULLIF(r.value('@CONTACTO', 'NVARCHAR(30)'), N''), c.Contacto),
            VENDEDOR = COALESCE(NULLIF(r.value('@VENDEDOR', 'NVARCHAR(2)'), N''), c.VENDEDOR),
            ESTADO = COALESCE(NULLIF(r.value('@ESTADO', 'NVARCHAR(60)'), N''), c.ESTADO),
            Ciudad = COALESCE(NULLIF(r.value('@CIUDAD', 'NVARCHAR(30)'), N''), c.Ciudad),
            CodPostal = COALESCE(NULLIF(r.value('@CPOSTAL', 'NVARCHAR(10)'), N''), c.CodPostal),
            Email = COALESCE(NULLIF(r.value('@EMAIL', 'NVARCHAR(50)'), N''), c.Email),
            PaginaWww = COALESCE(NULLIF(r.value('@PAGINA_WWW', 'NVARCHAR(50)'), N''), c.PaginaWww),
            CodUsuario = COALESCE(NULLIF(r.value('@COD_USUARIO', 'NVARCHAR(10)'), N''), c.CodUsuario),
            CreditLimit = CASE WHEN r.value('@LIMITE', 'NVARCHAR(50)') IS NULL OR r.value('@LIMITE', 'NVARCHAR(50)') = '' THEN c.CreditLimit ELSE CAST(r.value('@LIMITE', 'NVARCHAR(50)') AS FLOAT) END,
            Credito = CASE WHEN r.value('@CREDITO', 'NVARCHAR(50)') IS NULL OR r.value('@CREDITO', 'NVARCHAR(50)') = '' THEN c.Credito ELSE CAST(r.value('@CREDITO', 'NVARCHAR(50)') AS FLOAT) END,
            ListaPrecio = CASE WHEN r.value('@LISTA_PRECIO', 'NVARCHAR(50)') IS NULL OR r.value('@LISTA_PRECIO', 'NVARCHAR(50)') = '' THEN c.ListaPrecio ELSE CAST(r.value('@LISTA_PRECIO', 'NVARCHAR(50)') AS INT) END,
            Notas = COALESCE(NULLIF(r.value('@NOTAS', 'NVARCHAR(50)'), N''), c.Notas)
        FROM [master].[Supplier] c
        CROSS JOIN @xml.nodes('/row') T(r)
        WHERE c.SupplierCode = @Codigo AND ISNULL(c.IsDeleted, 0) = 0;

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
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_Proveedores_Delete')
    DROP PROCEDURE usp_Proveedores_Delete
GO
CREATE PROCEDURE usp_Proveedores_Delete
    @Codigo NVARCHAR(10),
    @Resultado INT OUTPUT,
    @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Resultado = 0;
    SET @Mensaje = N'';

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM [master].[Supplier] WHERE SupplierCode = @Codigo AND ISNULL(IsDeleted, 0) = 0)
        BEGIN
            SET @Resultado = -1;
            SET @Mensaje = N'Proveedor no encontrado';
            RETURN;
        END

        UPDATE [master].[Supplier]
        SET IsDeleted = 1, IsActive = 0
        WHERE SupplierCode = @Codigo;

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
SELECT name, create_date FROM sys.objects WHERE type = 'P' AND name LIKE 'usp_Proveedores_%';
