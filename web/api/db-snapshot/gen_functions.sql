SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;

-- =============================================
-- Script: Export all Function definitions
-- Database: DatqBoxWeb
-- =============================================

DECLARE @schema NVARCHAR(128), @name NVARCHAR(128), @object_id INT, @type_desc NVARCHAR(60);
DECLARE @def NVARCHAR(MAX);

DECLARE fn_cursor CURSOR LOCAL FAST_FORWARD FOR
    SELECT s.name, o.name, o.object_id, o.type_desc
    FROM sys.objects o
    JOIN sys.schemas s ON o.schema_id = s.schema_id
    WHERE o.type IN ('FN','IF','TF','AF')  -- Scalar, Inline Table, Table-Valued, Aggregate
      AND o.is_ms_shipped = 0
    ORDER BY s.name, o.name;

OPEN fn_cursor;
FETCH NEXT FROM fn_cursor INTO @schema, @name, @object_id, @type_desc;

WHILE @@FETCH_STATUS = 0
BEGIN
    PRINT '-- =============================================';
    PRINT '-- FUNCTION: ' + @schema + '.' + @name + ' (' + @type_desc + ')';
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

    FETCH NEXT FROM fn_cursor INTO @schema, @name, @object_id, @type_desc;
END;

CLOSE fn_cursor;
DEALLOCATE fn_cursor;
