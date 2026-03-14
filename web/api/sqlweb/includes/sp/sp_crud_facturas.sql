-- =============================================
-- Stored Procedures: Facturas (solo List + Get; emitir usa sp_emitir_factura_tx)
-- Migrado a ar.SalesDocument (OperationType = 'FACT')
-- Compatible con: SQL Server 2012+
-- =============================================

-- ---------- 1. List (paginado: documentNumber, userCode, from, to) ----------
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_Facturas_List')
    DROP PROCEDURE usp_Facturas_List
GO
CREATE PROCEDURE usp_Facturas_List
    @NumFact NVARCHAR(60) = NULL,
    @CodUsuario NVARCHAR(60) = NULL,
    @From DATE = NULL,
    @To DATE = NULL,
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

    DECLARE @Where NVARCHAR(MAX) = N' WHERE OperationType = ''FACT'' AND IsDeleted = 0';
    DECLARE @Sql NVARCHAR(MAX);
    DECLARE @Params NVARCHAR(500) = N'@NumFact NVARCHAR(60), @CodUsuario NVARCHAR(60), @From DATE, @To DATE, @Offset INT, @Limit INT, @TotalCount INT OUTPUT';

    IF @NumFact IS NOT NULL AND LTRIM(RTRIM(@NumFact)) <> N''
        SET @Where = @Where + N' AND DocumentNumber = @NumFact';
    IF @CodUsuario IS NOT NULL AND LTRIM(RTRIM(@CodUsuario)) <> N''
        SET @Where = @Where + N' AND UserCode = @CodUsuario';
    IF @From IS NOT NULL
        SET @Where = @Where + N' AND DocumentDate >= @From';
    IF @To IS NOT NULL
        SET @Where = @Where + N' AND DocumentDate <= @To';

    SET @Sql = N'
    SELECT @TotalCount = COUNT(1) FROM ar.SalesDocument' + @Where + N';
    SELECT * FROM ar.SalesDocument' + @Where + N'
    ORDER BY DocumentDate DESC
    OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;';

    EXEC sp_executesql @Sql, @Params,
        @NumFact = @NumFact,
        @CodUsuario = @CodUsuario,
        @From = @From,
        @To = @To,
        @Offset = @Offset,
        @Limit = @Limit,
        @TotalCount = @TotalCount OUTPUT;
END
GO

-- ---------- 2. Get by DocumentNumber ----------
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_Facturas_GetByNumFact')
    DROP PROCEDURE usp_Facturas_GetByNumFact
GO
CREATE PROCEDURE usp_Facturas_GetByNumFact
    @NumFact NVARCHAR(60)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM ar.SalesDocument
     WHERE DocumentNumber = @NumFact
       AND OperationType = 'FACT'
       AND IsDeleted = 0;
END
GO

SELECT name, create_date FROM sys.objects WHERE type = 'P' AND name LIKE 'usp_Facturas_%';
