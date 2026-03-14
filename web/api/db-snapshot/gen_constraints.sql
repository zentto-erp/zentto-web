SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;

-- =============================================
-- Constraints Summary for DatqBoxWeb
-- =============================================

PRINT '================================================================';
PRINT '  CONSTRAINTS SUMMARY - DatqBoxWeb';
PRINT '================================================================';
PRINT '';

-- PRIMARY KEYS
PRINT '----------------------------------------------------------------';
PRINT '  PRIMARY KEY CONSTRAINTS';
PRINT '----------------------------------------------------------------';

SELECT
    SCHEMA_NAME(t.schema_id) + '.' + t.name AS [Table],
    kc.name AS [Constraint],
    STUFF((
        SELECT ', ' + col.name
        FROM sys.index_columns ic2
        JOIN sys.columns col ON col.object_id = ic2.object_id AND col.column_id = ic2.column_id
        WHERE ic2.object_id = i.object_id AND ic2.index_id = i.index_id AND ic2.is_included_column = 0
        ORDER BY ic2.key_ordinal
        FOR XML PATH('')
    ), 1, 2, '') AS [Columns],
    CASE WHEN i.type = 1 THEN 'CLUSTERED' ELSE 'NONCLUSTERED' END AS [Type]
FROM sys.key_constraints kc
JOIN sys.tables t ON t.object_id = kc.parent_object_id
JOIN sys.indexes i ON i.object_id = kc.parent_object_id AND i.name = kc.name
WHERE kc.type = 'PK'
ORDER BY SCHEMA_NAME(t.schema_id), t.name;

PRINT '';

-- UNIQUE CONSTRAINTS
PRINT '----------------------------------------------------------------';
PRINT '  UNIQUE CONSTRAINTS';
PRINT '----------------------------------------------------------------';

SELECT
    SCHEMA_NAME(t.schema_id) + '.' + t.name AS [Table],
    kc.name AS [Constraint],
    STUFF((
        SELECT ', ' + col.name
        FROM sys.index_columns ic2
        JOIN sys.columns col ON col.object_id = ic2.object_id AND col.column_id = ic2.column_id
        WHERE ic2.object_id = i.object_id AND ic2.index_id = i.index_id AND ic2.is_included_column = 0
        ORDER BY ic2.key_ordinal
        FOR XML PATH('')
    ), 1, 2, '') AS [Columns]
FROM sys.key_constraints kc
JOIN sys.tables t ON t.object_id = kc.parent_object_id
JOIN sys.indexes i ON i.object_id = kc.parent_object_id AND i.name = kc.name
WHERE kc.type = 'UQ'
ORDER BY SCHEMA_NAME(t.schema_id), t.name;

PRINT '';

-- FOREIGN KEY CONSTRAINTS
PRINT '----------------------------------------------------------------';
PRINT '  FOREIGN KEY CONSTRAINTS';
PRINT '----------------------------------------------------------------';

SELECT
    SCHEMA_NAME(t.schema_id) + '.' + t.name AS [Parent Table],
    fk.name AS [FK Name],
    STUFF((
        SELECT ', ' + COL_NAME(fkc.parent_object_id, fkc.parent_column_id)
        FROM sys.foreign_key_columns fkc
        WHERE fkc.constraint_object_id = fk.object_id
        ORDER BY fkc.constraint_column_id
        FOR XML PATH('')
    ), 1, 2, '') AS [Parent Columns],
    OBJECT_SCHEMA_NAME(fk.referenced_object_id) + '.' + OBJECT_NAME(fk.referenced_object_id) AS [Referenced Table],
    STUFF((
        SELECT ', ' + COL_NAME(fkc.referenced_object_id, fkc.referenced_column_id)
        FROM sys.foreign_key_columns fkc
        WHERE fkc.constraint_object_id = fk.object_id
        ORDER BY fkc.constraint_column_id
        FOR XML PATH('')
    ), 1, 2, '') AS [Referenced Columns],
    CASE fk.delete_referential_action WHEN 0 THEN 'NO ACTION' WHEN 1 THEN 'CASCADE' WHEN 2 THEN 'SET NULL' WHEN 3 THEN 'SET DEFAULT' END AS [On Delete],
    CASE fk.update_referential_action WHEN 0 THEN 'NO ACTION' WHEN 1 THEN 'CASCADE' WHEN 2 THEN 'SET NULL' WHEN 3 THEN 'SET DEFAULT' END AS [On Update]
FROM sys.foreign_keys fk
JOIN sys.tables t ON t.object_id = fk.parent_object_id
ORDER BY SCHEMA_NAME(t.schema_id), t.name, fk.name;

PRINT '';

-- CHECK CONSTRAINTS
PRINT '----------------------------------------------------------------';
PRINT '  CHECK CONSTRAINTS';
PRINT '----------------------------------------------------------------';

SELECT
    SCHEMA_NAME(t.schema_id) + '.' + t.name AS [Table],
    cc.name AS [Constraint],
    cc.definition AS [Definition]
FROM sys.check_constraints cc
JOIN sys.tables t ON t.object_id = cc.parent_object_id
ORDER BY SCHEMA_NAME(t.schema_id), t.name, cc.name;

-- DEFAULT CONSTRAINTS
PRINT '';
PRINT '----------------------------------------------------------------';
PRINT '  DEFAULT CONSTRAINTS';
PRINT '----------------------------------------------------------------';

SELECT
    SCHEMA_NAME(t.schema_id) + '.' + t.name AS [Table],
    dc.name AS [Constraint],
    COL_NAME(dc.parent_object_id, dc.parent_column_id) AS [Column],
    dc.definition AS [Definition]
FROM sys.default_constraints dc
JOIN sys.tables t ON t.object_id = dc.parent_object_id
ORDER BY SCHEMA_NAME(t.schema_id), t.name, dc.name;
