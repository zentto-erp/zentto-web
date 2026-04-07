-- usp_Master_Generic_List — Lista registros de una tabla maestra con búsqueda y paginación
-- Equivalente T-SQL de usp_master_generic_list (PostgreSQL)
-- Compatible SQL Server 2012+ (OFFSET ... FETCH NEXT)

CREATE OR ALTER PROCEDURE usp_Master_Generic_List
  @CompanyId   INT            = NULL,
  @SchemaName  NVARCHAR(100)  = N'cfg',
  @TableName   NVARCHAR(100)  = NULL,
  @Search      NVARCHAR(500)  = NULL,
  @SortColumn  NVARCHAR(100)  = NULL,
  @Offset      INT            = 0,
  @Limit       INT            = 50,
  @TotalCount  INT            OUTPUT
AS
BEGIN
  SET NOCOUNT ON;

  IF @TableName IS NULL OR @TableName = ''
  BEGIN
    RAISERROR('TableName is required', 16, 1);
    RETURN;
  END

  DECLARE @sql        NVARCHAR(MAX);
  DECLARE @countSql   NVARCHAR(MAX);
  DECLARE @params     NVARCHAR(500);
  DECLARE @where      NVARCHAR(MAX) = N'(1=1)';
  DECLARE @qualified  NVARCHAR(300);
  DECLARE @schemaFixed NVARCHAR(100);
  DECLARE @sortSafe   NVARCHAR(200);

  -- Remapear schemas reservados en SQL Server
  SET @schemaFixed = CASE
    WHEN @SchemaName = 'master' THEN 'mstr'
    WHEN @SchemaName = 'sys'    THEN 'zsys'
    ELSE @SchemaName
  END;

  SET @qualified = QUOTENAME(@schemaFixed) + N'.' + QUOTENAME(@TableName);

  -- Filtro por CompanyId si la columna existe
  IF @CompanyId IS NOT NULL AND EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = @schemaFixed
      AND TABLE_NAME   = @TableName
      AND COLUMN_NAME  = N'CompanyId'
  )
    SET @where = @where + N' AND [CompanyId] = ' + CAST(@CompanyId AS NVARCHAR(20));

  -- Búsqueda en columnas nvarchar/varchar
  IF @Search IS NOT NULL AND @Search <> ''
  BEGIN
    DECLARE @searchCols NVARCHAR(MAX) = N'';
    SELECT @searchCols = @searchCols +
      CASE WHEN @searchCols <> '' THEN N' OR ' ELSE N'' END +
      N'[' + COLUMN_NAME + N'] LIKE ' + QUOTENAME(N'%' + @Search + N'%', '''')
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = @schemaFixed
      AND TABLE_NAME   = @TableName
      AND DATA_TYPE IN ('nvarchar', 'varchar', 'nchar', 'char');

    IF @searchCols <> ''
      SET @where = @where + N' AND (' + @searchCols + N')';
  END

  -- Validar columna de ordenamiento
  IF @SortColumn IS NOT NULL AND EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = @schemaFixed
      AND TABLE_NAME   = @TableName
      AND COLUMN_NAME  = @SortColumn
  )
    SET @sortSafe = QUOTENAME(@SortColumn)
  ELSE
    SELECT TOP 1 @sortSafe = QUOTENAME(COLUMN_NAME)
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = @schemaFixed
      AND TABLE_NAME   = @TableName
    ORDER BY ORDINAL_POSITION;

  -- Count
  SET @countSql = N'SELECT @cnt = COUNT(*) FROM ' + @qualified + N' WHERE ' + @where;
  SET @params   = N'@cnt INT OUTPUT';
  EXEC sp_executesql @countSql, @params, @cnt = @TotalCount OUTPUT;

  -- Datos paginados
  SET @sql =
    N'SELECT * FROM ' + @qualified + N' WHERE ' + @where +
    N' ORDER BY ' + @sortSafe +
    N' OFFSET ' + CAST(ISNULL(@Offset, 0) AS NVARCHAR) + N' ROWS' +
    N' FETCH NEXT ' + CAST(CASE WHEN ISNULL(@Limit, 50) > 500 THEN 500 ELSE ISNULL(@Limit, 50) END AS NVARCHAR) + N' ROWS ONLY';

  EXEC sp_executesql @sql;
END;
GO
