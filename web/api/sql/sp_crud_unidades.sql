-- =============================================
-- Stored Procedures CRUD: Unidades
-- Compatible con: SQL Server 2012+
-- PK: Id int IDENTITY
-- =============================================

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_Unidades_List')
    DROP PROCEDURE usp_Unidades_List
GO
CREATE PROCEDURE usp_Unidades_List
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
        SET @Where = N' WHERE Unidad LIKE @Search';
    DECLARE @SearchParam NVARCHAR(100) = NULL;
    IF @Search IS NOT NULL AND LTRIM(RTRIM(@Search)) <> N''
        SET @SearchParam = N'%' + @Search + N'%';
    SET @Sql = N'SELECT @TotalCount = COUNT(1) FROM [dbo].[Unidades]' + @Where + N';
    SELECT * FROM [dbo].[Unidades]' + @Where + N' ORDER BY Id OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;';
    EXEC sp_executesql @Sql, @Params, @Search = @SearchParam, @Offset = @Offset, @Limit = @Limit, @TotalCount = @TotalCount OUTPUT;
END
GO

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_Unidades_GetById')
    DROP PROCEDURE usp_Unidades_GetById
GO
CREATE PROCEDURE usp_Unidades_GetById @Id INT AS
BEGIN SET NOCOUNT ON; SELECT * FROM [dbo].[Unidades] WHERE Id = @Id; END
GO

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_Unidades_Insert')
    DROP PROCEDURE usp_Unidades_Insert
GO
CREATE PROCEDURE usp_Unidades_Insert @RowXml NVARCHAR(MAX), @Resultado INT OUTPUT, @Mensaje NVARCHAR(500) OUTPUT, @NuevoId INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON; SET @Resultado = 0; SET @Mensaje = N''; SET @NuevoId = 0;
    DECLARE @xml XML = CAST(@RowXml AS XML);
    BEGIN TRY
        INSERT INTO [dbo].[Unidades] (Unidad, Cantidad)
        SELECT NULLIF(r.value('@Unidad', 'NVARCHAR(50)'), N''),
               CASE WHEN r.value('@Cantidad', 'NVARCHAR(50)') IS NULL OR r.value('@Cantidad', 'NVARCHAR(50)') = '' THEN NULL ELSE CAST(r.value('@Cantidad', 'NVARCHAR(50)') AS FLOAT) END
        FROM @xml.nodes('/row') T(r);
        SET @NuevoId = SCOPE_IDENTITY(); SET @Resultado = 1; SET @Mensaje = N'OK';
    END TRY BEGIN CATCH SET @Resultado = -99; SET @Mensaje = ERROR_MESSAGE(); END CATCH
END
GO

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_Unidades_Update')
    DROP PROCEDURE usp_Unidades_Update
GO
CREATE PROCEDURE usp_Unidades_Update @Id INT, @RowXml NVARCHAR(MAX), @Resultado INT OUTPUT, @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON; SET @Resultado = 0; SET @Mensaje = N'';
    DECLARE @xml XML = CAST(@RowXml AS XML);
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM [dbo].[Unidades] WHERE Id = @Id) BEGIN SET @Resultado = -1; SET @Mensaje = N'Unidad no encontrada'; RETURN; END
        UPDATE u SET Unidad = COALESCE(NULLIF(r.value('@Unidad', 'NVARCHAR(50)'), N''), u.Unidad),
                     Cantidad = CASE WHEN r.value('@Cantidad', 'NVARCHAR(50)') IS NULL OR r.value('@Cantidad', 'NVARCHAR(50)') = '' THEN u.Cantidad ELSE CAST(r.value('@Cantidad', 'NVARCHAR(50)') AS FLOAT) END
        FROM [dbo].[Unidades] u CROSS JOIN @xml.nodes('/row') T(r) WHERE u.Id = @Id;
        SET @Resultado = 1; SET @Mensaje = N'OK';
    END TRY BEGIN CATCH SET @Resultado = -99; SET @Mensaje = ERROR_MESSAGE(); END CATCH
END
GO

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_Unidades_Delete')
    DROP PROCEDURE usp_Unidades_Delete
GO
CREATE PROCEDURE usp_Unidades_Delete @Id INT, @Resultado INT OUTPUT, @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON; SET @Resultado = 0; SET @Mensaje = N'';
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM [dbo].[Unidades] WHERE Id = @Id) BEGIN SET @Resultado = -1; SET @Mensaje = N'Unidad no encontrada'; RETURN; END
        DELETE FROM [dbo].[Unidades] WHERE Id = @Id; SET @Resultado = 1; SET @Mensaje = N'OK';
    END TRY BEGIN CATCH SET @Resultado = -99; SET @Mensaje = ERROR_MESSAGE(); END CATCH
END
GO

SELECT name, create_date FROM sys.objects WHERE type = 'P' AND name LIKE 'usp_Unidades_%';
