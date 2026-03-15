-- =============================================
-- Índice FULLTEXT para búsqueda rápida en Inventario
-- Compatible con: SQL Server 2012+
-- 
-- Crea un catálogo e índice fulltext sobre los campos descriptivos
-- de la tabla Inventario para búsquedas rápidas en +64k registros.
-- Este índice sirve como respaldo cuando Redis no está disponible.
-- =============================================

-- 1. Verificar si ya existe un catálogo fulltext
IF NOT EXISTS (
    SELECT 1 FROM sys.fulltext_catalogs WHERE name = 'FT_Inventario'
)
BEGIN
    CREATE FULLTEXT CATALOG FT_Inventario AS DEFAULT;
    PRINT 'Catálogo FT_Inventario creado';
END
ELSE
    PRINT 'Catálogo FT_Inventario ya existe';
GO

-- 2. Verificar si la tabla tiene un índice único (necesario para fulltext)
-- La tabla Inventario usa CODIGO como PK. Verificamos el nombre del índice.
DECLARE @pkName NVARCHAR(200);
SELECT @pkName = i.name
FROM sys.indexes i
WHERE i.object_id = OBJECT_ID('Inventario')
  AND i.is_primary_key = 1;

IF @pkName IS NULL
BEGIN
    -- Si no hay PK, verificar si hay índice único en CODIGO
    SELECT @pkName = i.name
    FROM sys.indexes i
    INNER JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
    INNER JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
    WHERE i.object_id = OBJECT_ID('Inventario')
      AND i.is_unique = 1
      AND c.name = 'CODIGO';
END

-- Si encontramos un índice, mostrar su nombre
IF @pkName IS NOT NULL
BEGIN
    PRINT 'Índice único encontrado: ' + @pkName;

    -- 3. Verificar si ya existe un índice fulltext en la tabla
    IF NOT EXISTS (
        SELECT 1 FROM sys.fulltext_indexes WHERE object_id = OBJECT_ID('Inventario')
    )
    BEGIN
        -- Crear índice fulltext usando SQL dinámico para usar el nombre del índice
        DECLARE @sql NVARCHAR(MAX);
        SET @sql = N'CREATE FULLTEXT INDEX ON Inventario (
            CODIGO LANGUAGE 3082,
            Referencia LANGUAGE 3082,
            Categoria LANGUAGE 3082,
            Marca LANGUAGE 3082,
            Tipo LANGUAGE 3082,
            Clase LANGUAGE 3082,
            DESCRIPCION LANGUAGE 3082,
            Linea LANGUAGE 3082,
            Barra LANGUAGE 3082
        ) KEY INDEX ' + QUOTENAME(@pkName) + N'
        ON FT_Inventario
        WITH CHANGE_TRACKING AUTO';

        EXEC sp_executesql @sql;
        PRINT 'Índice FULLTEXT creado en Inventario';
    END
    ELSE
        PRINT 'Índice FULLTEXT ya existe en Inventario';
END
ELSE
BEGIN
    PRINT 'ADVERTENCIA: No se encontró índice único en Inventario. No se puede crear FULLTEXT.';
    PRINT 'Crear primero: CREATE UNIQUE INDEX UX_Inventario_CODIGO ON Inventario(CODIGO)';
END
GO

-- 4. Verificar que el índice se creó correctamente
SELECT
    t.name AS Tabla,
    i.name AS IndiceFulltext,
    c.name AS CatalogoFulltext,
    fi.change_tracking_state_desc AS EstadoSeguimiento
FROM sys.fulltext_indexes fi
INNER JOIN sys.tables t ON fi.object_id = t.object_id
INNER JOIN sys.fulltext_catalogs c ON fi.fulltext_catalog_id = c.fulltext_catalog_id
INNER JOIN sys.indexes i ON fi.unique_index_id = i.index_id AND fi.object_id = i.object_id
WHERE t.name = 'Inventario';
GO
