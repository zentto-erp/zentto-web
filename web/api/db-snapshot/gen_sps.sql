SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;

-- =============================================
-- Script: Export all Stored Procedure definitions
-- Database: DatqBoxWeb
-- =============================================

DECLARE @schema NVARCHAR(128), @name NVARCHAR(128), @object_id INT;
DECLARE @def NVARCHAR(MAX);

DECLARE sp_cursor CURSOR LOCAL FAST_FORWARD FOR
    SELECT s.name, p.name, p.object_id
    FROM sys.procedures p
    JOIN sys.schemas s ON p.schema_id = s.schema_id
    WHERE p.is_ms_shipped = 0
    ORDER BY s.name, p.name;

OPEN sp_cursor;
FETCH NEXT FROM sp_cursor INTO @schema, @name, @object_id;

WHILE @@FETCH_STATUS = 0
BEGIN
    PRINT '-- =============================================';
    PRINT '-- STORED PROCEDURE: ' + @schema + '.' + @name;
    PRINT '-- =============================================';
    PRINT 'SET QUOTED_IDENTIFIER ON;';
    PRINT 'SET ANSI_NULLS ON;';
    PRINT 'GO';

    SET @def = OBJECT_DEFINITION(@object_id);

    IF @def IS NOT NULL
    BEGIN
        DECLARE @pos INT = 1;
        DECLARE @len INT = LEN(@def);
        DECLARE @chunk NVARCHAR(4000);
        DECLARE @nl INT;

        WHILE @pos <= @len
        BEGIN
            SET @chunk = SUBSTRING(@def, @pos, 4000);
            IF @pos + 4000 <= @len
            BEGIN
                SET @nl = 4000 - CHARINDEX(CHAR(10), REVERSE(@chunk));
                IF @nl > 0 AND @nl < 4000
                BEGIN
                    SET @chunk = SUBSTRING(@def, @pos, @nl);
                    SET @pos = @pos + @nl;
                END
                ELSE
                    SET @pos = @pos + 4000;
            END
            ELSE
                SET @pos = @len + 1;

            PRINT @chunk;
        END;
    END
    ELSE
        PRINT '-- (definition not available - encrypted or permission denied)';

    PRINT 'GO';
    PRINT '';
    PRINT '';

    FETCH NEXT FROM sp_cursor INTO @schema, @name, @object_id;
END;

CLOSE sp_cursor;
DEALLOCATE sp_cursor;
