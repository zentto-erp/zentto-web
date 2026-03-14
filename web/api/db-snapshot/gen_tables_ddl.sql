SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;

-- =============================================
-- Script: Generate CREATE TABLE DDL for all tables
-- Database: DatqBoxWeb
-- =============================================

DECLARE @schema NVARCHAR(128), @table NVARCHAR(128), @object_id INT;
DECLARE @line NVARCHAR(4000);
DECLARE @first_col BIT;

DECLARE table_cursor CURSOR LOCAL FAST_FORWARD FOR
    SELECT s.name AS schema_name, t.name AS table_name, t.object_id
    FROM sys.tables t
    JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE t.is_ms_shipped = 0
    ORDER BY s.name, t.name;

OPEN table_cursor;
FETCH NEXT FROM table_cursor INTO @schema, @table, @object_id;

WHILE @@FETCH_STATUS = 0
BEGIN
    -- Table header
    PRINT '-- =============================================';
    PRINT '-- TABLE: ' + @schema + '.' + @table;
    PRINT '-- =============================================';
    PRINT 'CREATE TABLE [' + @schema + '].[' + @table + '] (';

    -- Columns one by one
    SET @first_col = 1;
    DECLARE col_cursor CURSOR LOCAL FAST_FORWARD FOR
        SELECT
            CASE WHEN c.column_id > 1 THEN '   ,' ELSE '    ' END +
            '[' + c.name + '] ' +
            UPPER(tp.name) +
            CASE
                WHEN tp.name IN ('varchar','nvarchar','char','nchar','binary','varbinary')
                    THEN '(' + CASE WHEN c.max_length = -1 THEN 'MAX' ELSE CAST(
                        CASE WHEN tp.name IN ('nvarchar','nchar') THEN c.max_length/2 ELSE c.max_length END AS VARCHAR(10))
                    END + ')'
                WHEN tp.name IN ('decimal','numeric')
                    THEN '(' + CAST(c.precision AS VARCHAR(10)) + ',' + CAST(c.scale AS VARCHAR(10)) + ')'
                WHEN tp.name IN ('datetime2','datetimeoffset','time')
                    THEN '(' + CAST(c.scale AS VARCHAR(10)) + ')'
                ELSE ''
            END +
            CASE WHEN c.is_identity = 1
                THEN ' IDENTITY(' + CAST(IDENT_SEED(@schema + '.' + @table) AS VARCHAR(20)) + ',' + CAST(IDENT_INCR(@schema + '.' + @table) AS VARCHAR(20)) + ')'
                ELSE ''
            END +
            CASE WHEN c.is_nullable = 0 THEN ' NOT NULL' ELSE ' NULL' END +
            CASE WHEN dc.definition IS NOT NULL THEN ' DEFAULT ' + dc.definition ELSE '' END
        FROM sys.columns c
        JOIN sys.types tp ON c.user_type_id = tp.user_type_id
        LEFT JOIN sys.default_constraints dc ON dc.parent_object_id = c.object_id AND dc.parent_column_id = c.column_id
        WHERE c.object_id = @object_id
        ORDER BY c.column_id;

    OPEN col_cursor;
    FETCH NEXT FROM col_cursor INTO @line;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        PRINT @line;
        FETCH NEXT FROM col_cursor INTO @line;
    END;
    CLOSE col_cursor;
    DEALLOCATE col_cursor;

    -- Primary Key constraints
    DECLARE pk_cursor CURSOR LOCAL FAST_FORWARD FOR
        SELECT
            '   ,CONSTRAINT [' + kc.name + '] PRIMARY KEY ' +
            CASE WHEN i.type = 1 THEN 'CLUSTERED' ELSE 'NONCLUSTERED' END +
            ' (' +
            STUFF((
                SELECT ', [' + col.name + ']' + CASE WHEN ic2.is_descending_key = 1 THEN ' DESC' ELSE '' END
                FROM sys.index_columns ic2
                JOIN sys.columns col ON col.object_id = ic2.object_id AND col.column_id = ic2.column_id
                WHERE ic2.object_id = i.object_id AND ic2.index_id = i.index_id AND ic2.is_included_column = 0
                ORDER BY ic2.key_ordinal
                FOR XML PATH('')
            ), 1, 2, '') +
            ')'
        FROM sys.key_constraints kc
        JOIN sys.indexes i ON i.object_id = kc.parent_object_id AND i.name = kc.name
        WHERE kc.parent_object_id = @object_id AND kc.type = 'PK';

    OPEN pk_cursor;
    FETCH NEXT FROM pk_cursor INTO @line;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        PRINT @line;
        FETCH NEXT FROM pk_cursor INTO @line;
    END;
    CLOSE pk_cursor;
    DEALLOCATE pk_cursor;

    -- Unique constraints
    DECLARE uq_cursor CURSOR LOCAL FAST_FORWARD FOR
        SELECT
            '   ,CONSTRAINT [' + kc.name + '] UNIQUE ' +
            CASE WHEN i.type = 1 THEN 'CLUSTERED' ELSE 'NONCLUSTERED' END +
            ' (' +
            STUFF((
                SELECT ', [' + col.name + ']' + CASE WHEN ic2.is_descending_key = 1 THEN ' DESC' ELSE '' END
                FROM sys.index_columns ic2
                JOIN sys.columns col ON col.object_id = ic2.object_id AND col.column_id = ic2.column_id
                WHERE ic2.object_id = i.object_id AND ic2.index_id = i.index_id AND ic2.is_included_column = 0
                ORDER BY ic2.key_ordinal
                FOR XML PATH('')
            ), 1, 2, '') +
            ')'
        FROM sys.key_constraints kc
        JOIN sys.indexes i ON i.object_id = kc.parent_object_id AND i.name = kc.name
        WHERE kc.parent_object_id = @object_id AND kc.type = 'UQ';

    OPEN uq_cursor;
    FETCH NEXT FROM uq_cursor INTO @line;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        PRINT @line;
        FETCH NEXT FROM uq_cursor INTO @line;
    END;
    CLOSE uq_cursor;
    DEALLOCATE uq_cursor;

    -- Check constraints
    DECLARE ck_cursor CURSOR LOCAL FAST_FORWARD FOR
        SELECT '   ,CONSTRAINT [' + cc.name + '] CHECK ' + cc.definition
        FROM sys.check_constraints cc
        WHERE cc.parent_object_id = @object_id;

    OPEN ck_cursor;
    FETCH NEXT FROM ck_cursor INTO @line;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        PRINT @line;
        FETCH NEXT FROM ck_cursor INTO @line;
    END;
    CLOSE ck_cursor;
    DEALLOCATE ck_cursor;

    PRINT ');';
    PRINT 'GO';

    -- Foreign Keys (as ALTER TABLE after CREATE TABLE)
    DECLARE fk_cursor CURSOR LOCAL FAST_FORWARD FOR
        SELECT
            'ALTER TABLE [' + @schema + '].[' + @table + '] ADD CONSTRAINT [' + fk.name + '] FOREIGN KEY (' +
            STUFF((
                SELECT ', [' + COL_NAME(fkc.parent_object_id, fkc.parent_column_id) + ']'
                FROM sys.foreign_key_columns fkc
                WHERE fkc.constraint_object_id = fk.object_id
                ORDER BY fkc.constraint_column_id
                FOR XML PATH('')
            ), 1, 2, '') +
            ') REFERENCES [' + OBJECT_SCHEMA_NAME(fk.referenced_object_id) + '].[' + OBJECT_NAME(fk.referenced_object_id) + '] (' +
            STUFF((
                SELECT ', [' + COL_NAME(fkc.referenced_object_id, fkc.referenced_column_id) + ']'
                FROM sys.foreign_key_columns fkc
                WHERE fkc.constraint_object_id = fk.object_id
                ORDER BY fkc.constraint_column_id
                FOR XML PATH('')
            ), 1, 2, '') +
            ')' +
            CASE WHEN fk.delete_referential_action > 0
                THEN ' ON DELETE ' + CASE fk.delete_referential_action WHEN 1 THEN 'CASCADE' WHEN 2 THEN 'SET NULL' WHEN 3 THEN 'SET DEFAULT' END
                ELSE '' END +
            CASE WHEN fk.update_referential_action > 0
                THEN ' ON UPDATE ' + CASE fk.update_referential_action WHEN 1 THEN 'CASCADE' WHEN 2 THEN 'SET NULL' WHEN 3 THEN 'SET DEFAULT' END
                ELSE '' END +
            ';'
        FROM sys.foreign_keys fk
        WHERE fk.parent_object_id = @object_id;

    OPEN fk_cursor;
    FETCH NEXT FROM fk_cursor INTO @line;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        PRINT @line;
        PRINT 'GO';
        FETCH NEXT FROM fk_cursor INTO @line;
    END;
    CLOSE fk_cursor;
    DEALLOCATE fk_cursor;

    -- Non-clustered indexes (non PK, non UQ)
    DECLARE idx_cursor CURSOR LOCAL FAST_FORWARD FOR
        SELECT
            'CREATE ' +
            CASE WHEN i.is_unique = 1 THEN 'UNIQUE ' ELSE '' END +
            'NONCLUSTERED INDEX [' + i.name + '] ON [' + @schema + '].[' + @table + '] (' +
            STUFF((
                SELECT ', [' + col.name + ']' + CASE WHEN ic2.is_descending_key = 1 THEN ' DESC' ELSE ' ASC' END
                FROM sys.index_columns ic2
                JOIN sys.columns col ON col.object_id = ic2.object_id AND col.column_id = ic2.column_id
                WHERE ic2.object_id = i.object_id AND ic2.index_id = i.index_id AND ic2.is_included_column = 0
                ORDER BY ic2.key_ordinal
                FOR XML PATH('')
            ), 1, 2, '') +
            ')' +
            ISNULL(' INCLUDE (' +
                STUFF((
                    SELECT ', [' + col.name + ']'
                    FROM sys.index_columns ic2
                    JOIN sys.columns col ON col.object_id = ic2.object_id AND col.column_id = ic2.column_id
                    WHERE ic2.object_id = i.object_id AND ic2.index_id = i.index_id AND ic2.is_included_column = 1
                    ORDER BY ic2.index_column_id
                    FOR XML PATH('')
                ), 1, 2, '') +
            ')', '') +
            CASE WHEN i.has_filter = 1 THEN ' WHERE ' + i.filter_definition ELSE '' END +
            ';'
        FROM sys.indexes i
        WHERE i.object_id = @object_id
          AND i.type = 2  -- NONCLUSTERED
          AND i.is_primary_key = 0
          AND i.is_unique_constraint = 0
          AND i.name IS NOT NULL;

    OPEN idx_cursor;
    FETCH NEXT FROM idx_cursor INTO @line;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        PRINT @line;
        PRINT 'GO';
        FETCH NEXT FROM idx_cursor INTO @line;
    END;
    CLOSE idx_cursor;
    DEALLOCATE idx_cursor;

    PRINT '';
    PRINT '';

    FETCH NEXT FROM table_cursor INTO @schema, @table, @object_id;
END;

CLOSE table_cursor;
DEALLOCATE table_cursor;
