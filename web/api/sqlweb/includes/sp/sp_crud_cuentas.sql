-- =============================================
-- Stored Procedures CRUD: Cuentas
-- Compatible con: SQL Server 2012+
-- PK: COD_CUENTA nvarchar
-- =============================================

-- ---------- 1. List (paginado con filtros) ----------
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_Cuentas_List')
    DROP PROCEDURE usp_Cuentas_List
GO
CREATE PROCEDURE usp_Cuentas_List
    @Search NVARCHAR(100) = NULL,
    @Tipo NVARCHAR(50) = NULL,
    @Grupo NVARCHAR(50) = NULL,
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
    DECLARE @Params NVARCHAR(600) = N'@Search NVARCHAR(100), @Tipo NVARCHAR(50), @Grupo NVARCHAR(50), @Offset INT, @Limit INT, @TotalCount INT OUTPUT';

    IF @Search IS NOT NULL AND LTRIM(RTRIM(@Search)) <> N''
        SET @Where = @Where + N' AND (COD_CUENTA LIKE @Search OR DESCRIPCION LIKE @Search)';
    IF @Tipo IS NOT NULL AND LTRIM(RTRIM(@Tipo)) <> N''
        SET @Where = @Where + N' AND TIPO = @Tipo';
    IF @Grupo IS NOT NULL AND LTRIM(RTRIM(@Grupo)) <> N''
        SET @Where = @Where + N' AND grupo = @Grupo';

    IF LEN(@Where) > 0 SET @Where = N' WHERE ' + STUFF(@Where, 1, 5, N'');

    DECLARE @SearchParam NVARCHAR(100) = NULL;
    IF @Search IS NOT NULL AND LTRIM(RTRIM(@Search)) <> N''
        SET @SearchParam = N'%' + @Search + N'%';

    SET @Sql = N'
    SELECT @TotalCount = COUNT(1) FROM [dbo].[Cuentas] ' + @Where + N';
    SELECT * FROM [dbo].[Cuentas] ' + @Where + N'
    ORDER BY COD_CUENTA
    OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;';

    EXEC sp_executesql @Sql, @Params,
        @Search = @SearchParam,
        @Tipo = @Tipo,
        @Grupo = @Grupo,
        @Offset = @Offset,
        @Limit = @Limit,
        @TotalCount = @TotalCount OUTPUT;
END
GO

-- ---------- 2. Get by Codigo ----------
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_Cuentas_GetByCodigo')
    DROP PROCEDURE usp_Cuentas_GetByCodigo
GO
CREATE PROCEDURE usp_Cuentas_GetByCodigo
    @CodCuenta NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM [dbo].[Cuentas] WHERE COD_CUENTA = @CodCuenta;
END
GO

-- ---------- 3. Insert ----------
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_Cuentas_Insert')
    DROP PROCEDURE usp_Cuentas_Insert
GO
CREATE PROCEDURE usp_Cuentas_Insert
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
        IF EXISTS (SELECT 1 FROM [dbo].[Cuentas] WHERE COD_CUENTA = @xml.value('(/row/@COD_CUENTA)[1]', 'NVARCHAR(50)'))
        BEGIN
            SET @Resultado = -1;
            SET @Mensaje = N'Cuenta ya existe';
            RETURN;
        END

        INSERT INTO [dbo].[Cuentas] (
            COD_CUENTA, DESCRIPCION, TIPO, PRESUPUESTO, SALDO, COD_USUARIO, grupo, LINEA, USO, Nivel, Porcentaje
        )
        SELECT
            NULLIF(r.value('@COD_CUENTA', 'NVARCHAR(50)'), N''),
            NULLIF(r.value('@DESCRIPCION', 'NVARCHAR(100)'), N''),
            NULLIF(r.value('@TIPO', 'NVARCHAR(50)'), N''),
            CASE WHEN r.value('@PRESUPUESTO', 'NVARCHAR(50)') IS NULL OR r.value('@PRESUPUESTO', 'NVARCHAR(50)') = '' THEN NULL ELSE CAST(r.value('@PRESUPUESTO', 'NVARCHAR(50)') AS INT) END,
            CASE WHEN r.value('@SALDO', 'NVARCHAR(50)') IS NULL OR r.value('@SALDO', 'NVARCHAR(50)') = '' THEN NULL ELSE CAST(r.value('@SALDO', 'NVARCHAR(50)') AS INT) END,
            NULLIF(r.value('@COD_USUARIO', 'NVARCHAR(10)'), N''),
            NULLIF(r.value('@grupo', 'NVARCHAR(50)'), N''),
            NULLIF(r.value('@LINEA', 'NVARCHAR(50)'), N''),
            NULLIF(r.value('@USO', 'NVARCHAR(50)'), N''),
            CASE WHEN r.value('@Nivel', 'NVARCHAR(50)') IS NULL OR r.value('@Nivel', 'NVARCHAR(50)') = '' THEN NULL ELSE CAST(r.value('@Nivel', 'NVARCHAR(50)') AS INT) END,
            CASE WHEN r.value('@Porcentaje', 'NVARCHAR(50)') IS NULL OR r.value('@Porcentaje', 'NVARCHAR(50)') = '' THEN NULL ELSE CAST(r.value('@Porcentaje', 'NVARCHAR(50)') AS FLOAT) END
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
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_Cuentas_Update')
    DROP PROCEDURE usp_Cuentas_Update
GO
CREATE PROCEDURE usp_Cuentas_Update
    @CodCuenta NVARCHAR(50),
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
        IF NOT EXISTS (SELECT 1 FROM [dbo].[Cuentas] WHERE COD_CUENTA = @CodCuenta)
        BEGIN
            SET @Resultado = -1;
            SET @Mensaje = N'Cuenta no encontrada';
            RETURN;
        END

        UPDATE c SET
            DESCRIPCION = COALESCE(NULLIF(r.value('@DESCRIPCION', 'NVARCHAR(100)'), N''), c.DESCRIPCION),
            TIPO = COALESCE(NULLIF(r.value('@TIPO', 'NVARCHAR(50)'), N''), c.TIPO),
            grupo = COALESCE(NULLIF(r.value('@grupo', 'NVARCHAR(50)'), N''), c.grupo),
            LINEA = COALESCE(NULLIF(r.value('@LINEA', 'NVARCHAR(50)'), N''), c.LINEA),
            USO = COALESCE(NULLIF(r.value('@USO', 'NVARCHAR(50)'), N''), c.USO),
            Nivel = CASE WHEN r.value('@Nivel', 'NVARCHAR(50)') IS NULL OR r.value('@Nivel', 'NVARCHAR(50)') = '' THEN c.Nivel ELSE CAST(r.value('@Nivel', 'NVARCHAR(50)') AS INT) END,
            Porcentaje = CASE WHEN r.value('@Porcentaje', 'NVARCHAR(50)') IS NULL OR r.value('@Porcentaje', 'NVARCHAR(50)') = '' THEN c.Porcentaje ELSE CAST(r.value('@Porcentaje', 'NVARCHAR(50)') AS FLOAT) END
        FROM [dbo].[Cuentas] c
        CROSS JOIN @xml.nodes('/row') T(r)
        WHERE c.COD_CUENTA = @CodCuenta;

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
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_Cuentas_Delete')
    DROP PROCEDURE usp_Cuentas_Delete
GO
CREATE PROCEDURE usp_Cuentas_Delete
    @CodCuenta NVARCHAR(50),
    @Resultado INT OUTPUT,
    @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Resultado = 0;
    SET @Mensaje = N'';

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM [dbo].[Cuentas] WHERE COD_CUENTA = @CodCuenta)
        BEGIN
            SET @Resultado = -1;
            SET @Mensaje = N'Cuenta no encontrada';
            RETURN;
        END

        DELETE FROM [dbo].[Cuentas] WHERE COD_CUENTA = @CodCuenta;
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
SELECT name, create_date FROM sys.objects WHERE type = 'P' AND name LIKE 'usp_Cuentas_%';
