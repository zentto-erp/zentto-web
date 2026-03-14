SET NOCOUNT ON;

SELECT 
    '-- TABLE: ' + s.name + '.' + t.name + CHAR(13) + CHAR(10) +
    STUFF((
        SELECT CHAR(13) + CHAR(10) + '  ' + c.name + ' ' + 
            UPPER(tp.name) +
            CASE 
                WHEN tp.name IN ('varchar','nvarchar','char','nchar') THEN '(' + CASE WHEN c.max_length = -1 THEN 'MAX' ELSE CAST(CASE WHEN tp.name LIKE 'n%' THEN c.max_length/2 ELSE c.max_length END AS VARCHAR(10)) END + ')'
                WHEN tp.name IN ('decimal','numeric') THEN '(' + CAST(c.precision AS VARCHAR(10)) + ',' + CAST(c.scale AS VARCHAR(10)) + ')'
                WHEN tp.name = 'datetime2' THEN '(' + CAST(c.scale AS VARCHAR(2)) + ')'
                ELSE ''
            END +
            CASE WHEN c.is_identity = 1 THEN ' IDENTITY' ELSE '' END +
            CASE WHEN c.is_nullable = 0 THEN ' NOT NULL' ELSE ' NULL' END +
            CASE WHEN dc.definition IS NOT NULL THEN ' DEFAULT' + dc.definition ELSE '' END
        FROM sys.columns c
        INNER JOIN sys.types tp ON tp.user_type_id = c.user_type_id
        LEFT JOIN sys.default_constraints dc ON dc.parent_object_id = c.object_id AND dc.parent_column_id = c.column_id
        WHERE c.object_id = t.object_id
        ORDER BY c.column_id
        FOR XML PATH(''), TYPE
    ).value('.', 'NVARCHAR(MAX)'), 1, 2, '') + CHAR(13) + CHAR(10) +
    ISNULL('  PK: ' + STUFF((
        SELECT ', ' + COL_NAME(ic.object_id, ic.column_id)
        FROM sys.indexes i
        INNER JOIN sys.index_columns ic ON ic.object_id = i.object_id AND ic.index_id = i.index_id
        WHERE i.object_id = t.object_id AND i.is_primary_key = 1
        ORDER BY ic.key_ordinal
        FOR XML PATH('')
    ), 1, 2, ''), '') + CHAR(13) + CHAR(10)
FROM sys.tables t
INNER JOIN sys.schemas s ON s.schema_id = t.schema_id
WHERE s.name NOT IN ('sys','INFORMATION_SCHEMA')
ORDER BY s.name, t.name;
