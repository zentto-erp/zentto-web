-- =============================================
-- Stored Procedures: Compras (List + Get; emitir usa sp_emitir_compra_tx)
-- Compatible con: SQL Server 2012+
-- PK: NUM_FACT nvarchar(25). Filtros: search, proveedor, estado, fechaDesde, fechaHasta
-- =============================================

-- ---------- 1. List (paginado con filtros) ----------
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_Compras_List')
    DROP PROCEDURE usp_Compras_List
GO
CREATE PROCEDURE usp_Compras_List
    @Search NVARCHAR(100) = NULL,
    @Proveedor NVARCHAR(10) = NULL,
    @Estado NVARCHAR(50) = NULL,
    @FechaDesde DATE = NULL,
    @FechaHasta DATE = NULL,
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
    DECLARE @Params NVARCHAR(600) = N'@Search NVARCHAR(100), @Proveedor NVARCHAR(10), @Estado NVARCHAR(50), @FechaDesde DATE, @FechaHasta DATE, @Offset INT, @Limit INT, @TotalCount INT OUTPUT';

    IF @Search IS NOT NULL AND LTRIM(RTRIM(@Search)) <> N''
        SET @Where = @Where + N' AND (NUM_FACT LIKE @Search OR NOMBRE LIKE @Search OR RIF LIKE @Search)';
    IF @Proveedor IS NOT NULL AND LTRIM(RTRIM(@Proveedor)) <> N''
        SET @Where = @Where + N' AND COD_PROVEEDOR = @Proveedor';
    IF @Estado IS NOT NULL AND LTRIM(RTRIM(@Estado)) <> N''
        SET @Where = @Where + N' AND TIPO = @Estado';
    IF @FechaDesde IS NOT NULL
        SET @Where = @Where + N' AND FECHA >= @FechaDesde';
    IF @FechaHasta IS NOT NULL
        SET @Where = @Where + N' AND FECHA <= @FechaHasta';

    IF LEN(@Where) > 0 SET @Where = N' WHERE ' + STUFF(@Where, 1, 5, N'');

    DECLARE @SearchParam NVARCHAR(100) = NULL;
    IF @Search IS NOT NULL AND LTRIM(RTRIM(@Search)) <> N''
        SET @SearchParam = N'%' + @Search + N'%';

    SET @Sql = N'
    SELECT @TotalCount = COUNT(1) FROM [dbo].[Compras] ' + @Where + N';
    SELECT * FROM [dbo].[Compras] ' + @Where + N'
    ORDER BY FECHA DESC
    OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;';

    EXEC sp_executesql @Sql, @Params,
        @Search = @SearchParam,
        @Proveedor = @Proveedor,
        @Estado = @Estado,
        @FechaDesde = @FechaDesde,
        @FechaHasta = @FechaHasta,
        @Offset = @Offset,
        @Limit = @Limit,
        @TotalCount = @TotalCount OUTPUT;
END
GO

-- ---------- 2. Get by NUM_FACT ----------
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_Compras_GetByNumFact')
    DROP PROCEDURE usp_Compras_GetByNumFact
GO
CREATE PROCEDURE usp_Compras_GetByNumFact
    @NumFact NVARCHAR(25)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM [dbo].[Compras] WHERE NUM_FACT = @NumFact;
END
GO

SELECT name, create_date FROM sys.objects WHERE type = 'P' AND name LIKE 'usp_Compras_%';
