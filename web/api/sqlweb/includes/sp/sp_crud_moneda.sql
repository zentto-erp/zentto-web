-- =============================================
-- Stored Procedures CRUD: Moneda
-- Compatible con: SQL Server 2012+
-- PK: Nombre nvarchar
-- =============================================

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_Moneda_List')
    DROP PROCEDURE usp_Moneda_List
GO
CREATE PROCEDURE usp_Moneda_List
    @Search NVARCHAR(100) = NULL,
    @Page INT = 1,
    @Limit INT = 50,
    @TotalCount INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Offset INT = (ISNULL(NULLIF(@Page, 0), 1) - 1) * ISNULL(NULLIF(@Limit, 0), 50);
    IF @Offset < 0 SET @Offset = 0; IF @Limit < 1 SET @Limit = 50; IF @Limit > 500 SET @Limit = 500;
    DECLARE @Where NVARCHAR(MAX) = N''; DECLARE @Sql NVARCHAR(MAX);
    DECLARE @Params NVARCHAR(500) = N'@Search NVARCHAR(100), @Offset INT, @Limit INT, @TotalCount INT OUTPUT';
    IF @Search IS NOT NULL AND LTRIM(RTRIM(@Search)) <> N''
        SET @Where = N' WHERE Nombre LIKE @Search OR Simbolo LIKE @Search';
    DECLARE @SearchParam NVARCHAR(100) = NULL;
    IF @Search IS NOT NULL AND LTRIM(RTRIM(@Search)) <> N''
        SET @SearchParam = N'%' + @Search + N'%';
    SET @Sql = N'SELECT @TotalCount = COUNT(1) FROM [dbo].[Moneda]' + @Where + N';
    SELECT * FROM [dbo].[Moneda]' + @Where + N' ORDER BY Nombre OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;';
    EXEC sp_executesql @Sql, @Params, @Search = @SearchParam, @Offset = @Offset, @Limit = @Limit, @TotalCount = @TotalCount OUTPUT;
END
GO

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_Moneda_GetByNombre')
    DROP PROCEDURE usp_Moneda_GetByNombre
GO
CREATE PROCEDURE usp_Moneda_GetByNombre @Nombre NVARCHAR(50) AS
BEGIN SET NOCOUNT ON; SELECT * FROM [dbo].[Moneda] WHERE Nombre = @Nombre; END
GO

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_Moneda_Insert')
    DROP PROCEDURE usp_Moneda_Insert
GO
CREATE PROCEDURE usp_Moneda_Insert @RowXml NVARCHAR(MAX), @Resultado INT OUTPUT, @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON; SET @Resultado = 0; SET @Mensaje = N'';
    DECLARE @xml XML = CAST(@RowXml AS XML);
    BEGIN TRY
        IF EXISTS (SELECT 1 FROM [dbo].[Moneda] WHERE Nombre = @xml.value('(/row/@Nombre)[1]', 'NVARCHAR(50)'))
        BEGIN SET @Resultado = -1; SET @Mensaje = N'Moneda ya existe'; RETURN; END
        INSERT INTO [dbo].[Moneda] (Nombre, Simbolo, Tasa_Local, Local_Tasa, Local)
        SELECT NULLIF(r.value('@Nombre', 'NVARCHAR(50)'), N''),
               NULLIF(r.value('@Simbolo', 'NVARCHAR(10)'), N''),
               CASE WHEN r.value('@Tasa_Local', 'NVARCHAR(50)') IS NULL OR r.value('@Tasa_Local', 'NVARCHAR(50)') = '' THEN NULL ELSE CAST(r.value('@Tasa_Local', 'NVARCHAR(50)') AS FLOAT) END,
               CASE WHEN r.value('@Local_Tasa', 'NVARCHAR(50)') IS NULL OR r.value('@Local_Tasa', 'NVARCHAR(50)') = '' THEN NULL ELSE CAST(r.value('@Local_Tasa', 'NVARCHAR(50)') AS FLOAT) END,
               NULLIF(r.value('@Local', 'NVARCHAR(10)'), N'')
        FROM @xml.nodes('/row') T(r);
        SET @Resultado = 1; SET @Mensaje = N'OK';
    END TRY BEGIN CATCH SET @Resultado = -99; SET @Mensaje = ERROR_MESSAGE(); END CATCH
END
GO

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_Moneda_Update')
    DROP PROCEDURE usp_Moneda_Update
GO
CREATE PROCEDURE usp_Moneda_Update @Nombre NVARCHAR(50), @RowXml NVARCHAR(MAX), @Resultado INT OUTPUT, @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON; SET @Resultado = 0; SET @Mensaje = N'';
    DECLARE @xml XML = CAST(@RowXml AS XML);
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM [dbo].[Moneda] WHERE Nombre = @Nombre) BEGIN SET @Resultado = -1; SET @Mensaje = N'Moneda no encontrada'; RETURN; END
        UPDATE m SET Simbolo = COALESCE(NULLIF(r.value('@Simbolo', 'NVARCHAR(10)'), N''), m.Simbolo),
                     Tasa_Local = CASE WHEN r.value('@Tasa_Local', 'NVARCHAR(50)') IS NULL OR r.value('@Tasa_Local', 'NVARCHAR(50)') = '' THEN m.Tasa_Local ELSE CAST(r.value('@Tasa_Local', 'NVARCHAR(50)') AS FLOAT) END,
                     Local_Tasa = CASE WHEN r.value('@Local_Tasa', 'NVARCHAR(50)') IS NULL OR r.value('@Local_Tasa', 'NVARCHAR(50)') = '' THEN m.Local_Tasa ELSE CAST(r.value('@Local_Tasa', 'NVARCHAR(50)') AS FLOAT) END,
                     Local = COALESCE(NULLIF(r.value('@Local', 'NVARCHAR(10)'), N''), m.Local)
        FROM [dbo].[Moneda] m CROSS JOIN @xml.nodes('/row') T(r) WHERE m.Nombre = @Nombre;
        SET @Resultado = 1; SET @Mensaje = N'OK';
    END TRY BEGIN CATCH SET @Resultado = -99; SET @Mensaje = ERROR_MESSAGE(); END CATCH
END
GO

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_Moneda_Delete')
    DROP PROCEDURE usp_Moneda_Delete
GO
CREATE PROCEDURE usp_Moneda_Delete @Nombre NVARCHAR(50), @Resultado INT OUTPUT, @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON; SET @Resultado = 0; SET @Mensaje = N'';
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM [dbo].[Moneda] WHERE Nombre = @Nombre) BEGIN SET @Resultado = -1; SET @Mensaje = N'Moneda no encontrada'; RETURN; END
        DELETE FROM [dbo].[Moneda] WHERE Nombre = @Nombre; SET @Resultado = 1; SET @Mensaje = N'OK';
    END TRY BEGIN CATCH SET @Resultado = -99; SET @Mensaje = ERROR_MESSAGE(); END CATCH
END
GO

SELECT name, create_date FROM sys.objects WHERE type = 'P' AND name LIKE 'usp_Moneda_%';
