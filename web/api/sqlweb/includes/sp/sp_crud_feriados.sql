-- =============================================
-- Stored Procedures CRUD: Feriados
-- Compatible con: SQL Server 2012+
-- PK: Fecha datetime
-- =============================================

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_Feriados_List')
    DROP PROCEDURE usp_Feriados_List
GO
CREATE PROCEDURE usp_Feriados_List
    @Search NVARCHAR(100) = NULL,
    @Anio INT = NULL,
    @Page INT = 1,
    @Limit INT = 50,
    @TotalCount INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Offset INT = (ISNULL(NULLIF(@Page, 0), 1) - 1) * ISNULL(NULLIF(@Limit, 0), 50);
    IF @Offset < 0 SET @Offset = 0; IF @Limit < 1 SET @Limit = 50; IF @Limit > 500 SET @Limit = 500;
    DECLARE @Where NVARCHAR(MAX) = N''; DECLARE @Sql NVARCHAR(MAX);
    DECLARE @Params NVARCHAR(600) = N'@Search NVARCHAR(100), @Anio INT, @Offset INT, @Limit INT, @TotalCount INT OUTPUT';
    IF @Search IS NOT NULL AND LTRIM(RTRIM(@Search)) <> N''
        SET @Where = @Where + N' AND Descripcion LIKE @Search';
    IF @Anio IS NOT NULL
        SET @Where = @Where + N' AND YEAR(Fecha) = @Anio';
    IF LEN(@Where) > 0 SET @Where = N' WHERE ' + STUFF(@Where, 1, 5, N'');
    DECLARE @SearchParam NVARCHAR(100) = NULL;
    IF @Search IS NOT NULL AND LTRIM(RTRIM(@Search)) <> N''
        SET @SearchParam = N'%' + @Search + N'%';
    SET @Sql = N'SELECT @TotalCount = COUNT(1) FROM [dbo].[Feriados]' + @Where + N';
    SELECT * FROM [dbo].[Feriados]' + @Where + N' ORDER BY Fecha OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;';
    EXEC sp_executesql @Sql, @Params, @Search = @SearchParam, @Anio = @Anio, @Offset = @Offset, @Limit = @Limit, @TotalCount = @TotalCount OUTPUT;
END
GO

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_Feriados_GetByFecha')
    DROP PROCEDURE usp_Feriados_GetByFecha
GO
CREATE PROCEDURE usp_Feriados_GetByFecha @Fecha DATE AS
BEGIN SET NOCOUNT ON; SELECT * FROM [dbo].[Feriados] WHERE CAST(Fecha AS DATE) = @Fecha; END
GO

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_Feriados_Insert')
    DROP PROCEDURE usp_Feriados_Insert
GO
CREATE PROCEDURE usp_Feriados_Insert @RowXml NVARCHAR(MAX), @Resultado INT OUTPUT, @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON; SET @Resultado = 0; SET @Mensaje = N'';
    DECLARE @xml XML = CAST(@RowXml AS XML);
    BEGIN TRY
        DECLARE @Fecha DATE = @xml.value('(/row/@Fecha)[1]', 'DATE');
        IF EXISTS (SELECT 1 FROM [dbo].[Feriados] WHERE CAST(Fecha AS DATE) = @Fecha)
        BEGIN SET @Resultado = -1; SET @Mensaje = N'Feriado ya existe para esta fecha'; RETURN; END
        INSERT INTO [dbo].[Feriados] (Fecha, Descripcion)
        SELECT @Fecha, NULLIF(r.value('@Descripcion', 'NVARCHAR(100)'), N'')
        FROM @xml.nodes('/row') T(r);
        SET @Resultado = 1; SET @Mensaje = N'OK';
    END TRY BEGIN CATCH SET @Resultado = -99; SET @Mensaje = ERROR_MESSAGE(); END CATCH
END
GO

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_Feriados_Update')
    DROP PROCEDURE usp_Feriados_Update
GO
CREATE PROCEDURE usp_Feriados_Update @Fecha DATE, @RowXml NVARCHAR(MAX), @Resultado INT OUTPUT, @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON; SET @Resultado = 0; SET @Mensaje = N'';
    DECLARE @xml XML = CAST(@RowXml AS XML);
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM [dbo].[Feriados] WHERE CAST(Fecha AS DATE) = @Fecha) BEGIN SET @Resultado = -1; SET @Mensaje = N'Feriado no encontrado'; RETURN; END
        UPDATE f SET Descripcion = COALESCE(NULLIF(r.value('@Descripcion', 'NVARCHAR(100)'), N''), f.Descripcion)
        FROM [dbo].[Feriados] f CROSS JOIN @xml.nodes('/row') T(r) WHERE CAST(f.Fecha AS DATE) = @Fecha;
        SET @Resultado = 1; SET @Mensaje = N'OK';
    END TRY BEGIN CATCH SET @Resultado = -99; SET @Mensaje = ERROR_MESSAGE(); END CATCH
END
GO

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_Feriados_Delete')
    DROP PROCEDURE usp_Feriados_Delete
GO
CREATE PROCEDURE usp_Feriados_Delete @Fecha DATE, @Resultado INT OUTPUT, @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON; SET @Resultado = 0; SET @Mensaje = N'';
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM [dbo].[Feriados] WHERE CAST(Fecha AS DATE) = @Fecha) BEGIN SET @Resultado = -1; SET @Mensaje = N'Feriado no encontrado'; RETURN; END
        DELETE FROM [dbo].[Feriados] WHERE CAST(Fecha AS DATE) = @Fecha; SET @Resultado = 1; SET @Mensaje = N'OK';
    END TRY BEGIN CATCH SET @Resultado = -99; SET @Mensaje = ERROR_MESSAGE(); END CATCH
END
GO

SELECT name, create_date FROM sys.objects WHERE type = 'P' AND name LIKE 'usp_Feriados_%';
