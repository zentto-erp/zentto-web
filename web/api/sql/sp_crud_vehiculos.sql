-- =============================================
-- Stored Procedures CRUD: Vehiculos
-- Compatible con: SQL Server 2012+
-- PK: Placa nvarchar
-- =============================================

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_Vehiculos_List')
    DROP PROCEDURE usp_Vehiculos_List
GO
CREATE PROCEDURE usp_Vehiculos_List
    @Search NVARCHAR(100) = NULL,
    @Cedula NVARCHAR(20) = NULL,
    @Page INT = 1,
    @Limit INT = 50,
    @TotalCount INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Offset INT = (ISNULL(NULLIF(@Page, 0), 1) - 1) * ISNULL(NULLIF(@Limit, 0), 50);
    IF @Offset < 0 SET @Offset = 0; IF @Limit < 1 SET @Limit = 50; IF @Limit > 500 SET @Limit = 500;
    DECLARE @Where NVARCHAR(MAX) = N''; DECLARE @Sql NVARCHAR(MAX);
    DECLARE @Params NVARCHAR(600) = N'@Search NVARCHAR(100), @Cedula NVARCHAR(20), @Offset INT, @Limit INT, @TotalCount INT OUTPUT';
    IF @Search IS NOT NULL AND LTRIM(RTRIM(@Search)) <> N''
        SET @Where = @Where + N' AND (Placa LIKE @Search OR Marca LIKE @Search)';
    IF @Cedula IS NOT NULL AND LTRIM(RTRIM(@Cedula)) <> N''
        SET @Where = @Where + N' AND Cedula = @Cedula';
    IF LEN(@Where) > 0 SET @Where = N' WHERE ' + STUFF(@Where, 1, 5, N'');
    DECLARE @SearchParam NVARCHAR(100) = NULL;
    IF @Search IS NOT NULL AND LTRIM(RTRIM(@Search)) <> N''
        SET @SearchParam = N'%' + @Search + N'%';
    SET @Sql = N'SELECT @TotalCount = COUNT(1) FROM [dbo].[Vehiculos]' + @Where + N';
    SELECT Placa, Cedula, Marca, [Año] AS Anio, Cauchos FROM [dbo].[Vehiculos]' + @Where + N' ORDER BY Placa OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;';
    EXEC sp_executesql @Sql, @Params, @Search = @SearchParam, @Cedula = @Cedula, @Offset = @Offset, @Limit = @Limit, @TotalCount = @TotalCount OUTPUT;
END
GO

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_Vehiculos_GetByPlaca')
    DROP PROCEDURE usp_Vehiculos_GetByPlaca
GO
CREATE PROCEDURE usp_Vehiculos_GetByPlaca @Placa NVARCHAR(20) AS
BEGIN SET NOCOUNT ON; SELECT Placa, Cedula, Marca, [Año] AS Anio, Cauchos FROM [dbo].[Vehiculos] WHERE Placa = @Placa; END
GO

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_Vehiculos_Insert')
    DROP PROCEDURE usp_Vehiculos_Insert
GO
CREATE PROCEDURE usp_Vehiculos_Insert @RowXml NVARCHAR(MAX), @Resultado INT OUTPUT, @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON; SET @Resultado = 0; SET @Mensaje = N'';
    DECLARE @xml XML = CAST(@RowXml AS XML);
    BEGIN TRY
        IF EXISTS (SELECT 1 FROM [dbo].[Vehiculos] WHERE Placa = @xml.value('(/row/@Placa)[1]', 'NVARCHAR(20)'))
        BEGIN SET @Resultado = -1; SET @Mensaje = N'Vehiculo ya existe'; RETURN; END
        INSERT INTO [dbo].[Vehiculos] (Placa, Cedula, Marca, [Año], Cauchos)
        SELECT NULLIF(r.value('@Placa', 'NVARCHAR(20)'), N''),
               NULLIF(r.value('@Cedula', 'NVARCHAR(20)'), N''),
               NULLIF(r.value('@Marca', 'NVARCHAR(50)'), N''),
               NULLIF(r.value('@Anio', 'NVARCHAR(10)'), N''),
               NULLIF(r.value('@Cauchos', 'NVARCHAR(50)'), N'')
        FROM @xml.nodes('/row') T(r);
        SET @Resultado = 1; SET @Mensaje = N'OK';
    END TRY BEGIN CATCH SET @Resultado = -99; SET @Mensaje = ERROR_MESSAGE(); END CATCH
END
GO

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_Vehiculos_Update')
    DROP PROCEDURE usp_Vehiculos_Update
GO
CREATE PROCEDURE usp_Vehiculos_Update @Placa NVARCHAR(20), @RowXml NVARCHAR(MAX), @Resultado INT OUTPUT, @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON; SET @Resultado = 0; SET @Mensaje = N'';
    DECLARE @xml XML = CAST(@RowXml AS XML);
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM [dbo].[Vehiculos] WHERE Placa = @Placa) BEGIN SET @Resultado = -1; SET @Mensaje = N'Vehiculo no encontrado'; RETURN; END
        UPDATE v SET Cedula = COALESCE(NULLIF(r.value('@Cedula', 'NVARCHAR(20)'), N''), v.Cedula),
                     Marca = COALESCE(NULLIF(r.value('@Marca', 'NVARCHAR(50)'), N''), v.Marca),
                     [Año] = COALESCE(NULLIF(r.value('@Anio', 'NVARCHAR(10)'), N''), v.[Año]),
                     Cauchos = COALESCE(NULLIF(r.value('@Cauchos', 'NVARCHAR(50)'), N''), v.Cauchos)
        FROM [dbo].[Vehiculos] v CROSS JOIN @xml.nodes('/row') T(r) WHERE v.Placa = @Placa;
        SET @Resultado = 1; SET @Mensaje = N'OK';
    END TRY BEGIN CATCH SET @Resultado = -99; SET @Mensaje = ERROR_MESSAGE(); END CATCH
END
GO

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_Vehiculos_Delete')
    DROP PROCEDURE usp_Vehiculos_Delete
GO
CREATE PROCEDURE usp_Vehiculos_Delete @Placa NVARCHAR(20), @Resultado INT OUTPUT, @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON; SET @Resultado = 0; SET @Mensaje = N'';
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM [dbo].[Vehiculos] WHERE Placa = @Placa) BEGIN SET @Resultado = -1; SET @Mensaje = N'Vehiculo no encontrado'; RETURN; END
        DELETE FROM [dbo].[Vehiculos] WHERE Placa = @Placa; SET @Resultado = 1; SET @Mensaje = N'OK';
    END TRY BEGIN CATCH SET @Resultado = -99; SET @Mensaje = ERROR_MESSAGE(); END CATCH
END
GO

SELECT name, create_date FROM sys.objects WHERE type = 'P' AND name LIKE 'usp_Vehiculos_%';
