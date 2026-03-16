SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;

-- =============================================
-- Script: Export all VIEW definitions
-- Database: DatqBoxWeb
-- =============================================

DECLARE @schema NVARCHAR(128), @name NVARCHAR(128), @object_id INT;
DECLARE @def NVARCHAR(MAX);

DECLARE v_cursor CURSOR LOCAL FAST_FORWARD FOR
    SELECT s.name, v.name, v.object_id
    FROM sys.views v
    JOIN sys.schemas s ON v.schema_id = s.schema_id
    WHERE v.is_ms_shipped = 0
    ORDER BY s.name, v.name;

OPEN v_cursor;
FETCH NEXT FROM v_cursor INTO @schema, @name, @object_id;

WHILE @@FETCH_STATUS = 0
BEGIN
    PRINT '-- =============================================';
    PRINT '-- VIEW: ' + @schema + '.' + @name;
    PRINT '-- =============================================';
    PRINT 'SET QUOTED_IDENTIFIER ON;';
    PRINT 'SET ANSI_NULLS ON;';
    PRINT 'GO';

    SET @def = OBJECT_DEFINITION(@object_id);

    IF @def IS NOT NULL
    BEGIN
        -- PRINT has 4000 char limit, so we need to chunk it
        DECLARE @pos INT = 1;
        DECLARE @len INT = LEN(@def);
        DECLARE @chunk NVARCHAR(4000);
        DECLARE @nl INT;

        WHILE @pos <= @len
        BEGIN
            SET @chunk = SUBSTRING(@def, @pos, 4000);
            -- Try to break at last newline within chunk
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

    FETCH NEXT FROM v_cursor INTO @schema, @name, @object_id;
END;

CLOSE v_cursor;
DEALLOCATE v_cursor;
