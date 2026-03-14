SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;

-- =============================================
-- Index Summary for DatqBoxWeb (non-PK indexes)
-- =============================================

PRINT '================================================================';
PRINT '  INDEX SUMMARY - DatqBoxWeb (non-PK)';
PRINT '================================================================';
PRINT '';

SELECT
    SCHEMA_NAME(t.schema_id) + '.' + t.name AS [Table],
    i.name AS [Index Name],
    CASE
        WHEN i.is_unique = 1 AND i.is_unique_constraint = 1 THEN 'UNIQUE CONSTRAINT'
        WHEN i.is_unique = 1 THEN 'UNIQUE INDEX'
        ELSE 'INDEX'
    END AS [Type],
    CASE i.type
        WHEN 1 THEN 'CLUSTERED'
        WHEN 2 THEN 'NONCLUSTERED'
        WHEN 5 THEN 'CLUSTERED COLUMNSTORE'
        WHEN 6 THEN 'NONCLUSTERED COLUMNSTORE'
        ELSE 'OTHER'
    END AS [Index Type],
    STUFF((
        SELECT ', ' + col.name + CASE WHEN ic2.is_descending_key = 1 THEN ' DESC' ELSE ' ASC' END
        FROM sys.index_columns ic2
        JOIN sys.columns col ON col.object_id = ic2.object_id AND col.column_id = ic2.column_id
        WHERE ic2.object_id = i.object_id AND ic2.index_id = i.index_id AND ic2.is_included_column = 0
        ORDER BY ic2.key_ordinal
        FOR XML PATH('')
    ), 1, 2, '') AS [Key Columns],
    ISNULL(STUFF((
        SELECT ', ' + col.name
        FROM sys.index_columns ic2
        JOIN sys.columns col ON col.object_id = ic2.object_id AND col.column_id = ic2.column_id
        WHERE ic2.object_id = i.object_id AND ic2.index_id = i.index_id AND ic2.is_included_column = 1
        ORDER BY ic2.index_column_id
        FOR XML PATH('')
    ), 1, 2, ''), '') AS [Included Columns],
    ISNULL(i.filter_definition, '') AS [Filter]
FROM sys.indexes i
JOIN sys.tables t ON t.object_id = i.object_id
WHERE i.is_primary_key = 0
  AND i.type > 0  -- skip heaps
  AND i.name IS NOT NULL
  AND t.is_ms_shipped = 0
ORDER BY SCHEMA_NAME(t.schema_id), t.name, i.name;
