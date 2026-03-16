SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;

-- Export all table structures
SELECT 
    s.name AS [schema],
    t.name AS [table],
    c.column_id AS col_order,
    c.name AS col_name,
    UPPER(tp.name) AS col_type,
    CASE 
        WHEN tp.name IN ('varchar','nvarchar','char','nchar') THEN CASE WHEN c.max_length = -1 THEN 'MAX' ELSE CAST(CASE WHEN tp.name LIKE 'n%' THEN c.max_length/2 ELSE c.max_length END AS VARCHAR(10)) END
        WHEN tp.name IN ('decimal','numeric') THEN CAST(c.precision AS VARCHAR(10)) + ',' + CAST(c.scale AS VARCHAR(10))
        WHEN tp.name = 'datetime2' THEN CAST(c.scale AS VARCHAR(2))
        ELSE ''
    END AS col_size,
    c.is_identity,
    c.is_nullable,
    dc.definition AS default_val
FROM sys.tables t
INNER JOIN sys.schemas s ON s.schema_id = t.schema_id
INNER JOIN sys.columns c ON c.object_id = t.object_id
INNER JOIN sys.types tp ON tp.user_type_id = c.user_type_id
LEFT JOIN sys.default_constraints dc ON dc.parent_object_id = c.object_id AND dc.parent_column_id = c.column_id
WHERE s.name NOT IN ('sys','INFORMATION_SCHEMA')
ORDER BY s.name, t.name, c.column_id;
