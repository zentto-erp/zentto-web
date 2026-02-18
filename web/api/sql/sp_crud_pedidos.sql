-- =============================================
-- Stored Procedures: Pedidos (List + Get)
-- PK: NUM_FACT nvarchar(20). Filtros: search, codigo
-- =============================================

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_Pedidos_List')
    DROP PROCEDURE usp_Pedidos_List
GO
CREATE PROCEDURE usp_Pedidos_List
    @Search NVARCHAR(100) = NULL,
    @Codigo NVARCHAR(10) = NULL,
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
    DECLARE @Params NVARCHAR(400) = N'@Search NVARCHAR(100), @Codigo NVARCHAR(10), @Offset INT, @Limit INT, @TotalCount INT OUTPUT';

    IF @Search IS NOT NULL AND LTRIM(RTRIM(@Search)) <> N''
        SET @Where = @Where + N' AND (NUM_FACT LIKE @Search OR NOMBRE LIKE @Search OR RIF LIKE @Search)';
    IF @Codigo IS NOT NULL AND LTRIM(RTRIM(@Codigo)) <> N''
        SET @Where = @Where + N' AND CODIGO = @Codigo';

    IF LEN(@Where) > 0 SET @Where = N' WHERE ' + STUFF(@Where, 1, 5, N'');

    DECLARE @SearchParam NVARCHAR(100) = NULL;
    IF @Search IS NOT NULL AND LTRIM(RTRIM(@Search)) <> N''
        SET @SearchParam = N'%' + @Search + N'%';

    SET @Sql = N'
    SELECT @TotalCount = COUNT(1) FROM [dbo].[Pedidos] ' + @Where + N';
    SELECT * FROM [dbo].[Pedidos] ' + @Where + N'
    ORDER BY FECHA DESC
    OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;';

    EXEC sp_executesql @Sql, @Params,
        @Search = @SearchParam,
        @Codigo = @Codigo,
        @Offset = @Offset,
        @Limit = @Limit,
        @TotalCount = @TotalCount OUTPUT;
END
GO

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_Pedidos_GetByNumFact')
    DROP PROCEDURE usp_Pedidos_GetByNumFact
GO
CREATE PROCEDURE usp_Pedidos_GetByNumFact
    @NumFact NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM [dbo].[Pedidos] WHERE NUM_FACT = @NumFact;
END
GO

SELECT name, create_date FROM sys.objects WHERE type = 'P' AND name LIKE 'usp_Pedidos_%';
