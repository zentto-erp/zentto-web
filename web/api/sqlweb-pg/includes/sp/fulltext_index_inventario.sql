-- ============================================================
-- DatqBoxWeb PostgreSQL - fulltext_index_inventario.sql
-- Indice de busqueda de texto completo (tsvector/GIN) para
-- busqueda rapida en Inventario. Equivalente PostgreSQL al
-- catalogo FULLTEXT de SQL Server sobre campos descriptivos.
-- Este indice sirve como respaldo cuando Redis no esta disponible.
-- ============================================================

DO $fts$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = 'public' AND table_name = 'Inventario'
    ) THEN
        -- 1. Agregar columna tsvector si no existe
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.columns
            WHERE table_schema = 'public'
              AND table_name = 'Inventario'
              AND column_name = 'ts_search'
        ) THEN
            ALTER TABLE public."Inventario"
                ADD COLUMN "ts_search" TSVECTOR;
            RAISE NOTICE 'Columna ts_search agregada a Inventario';
        END IF;

        -- 2. Crear indice GIN
        IF NOT EXISTS (
            SELECT 1 FROM pg_indexes
            WHERE schemaname = 'public'
              AND tablename = 'Inventario'
              AND indexname = 'IX_Inventario_FTS'
        ) THEN
            CREATE INDEX "IX_Inventario_FTS"
                ON public."Inventario"
                USING GIN ("ts_search");
            RAISE NOTICE 'Indice GIN IX_Inventario_FTS creado';
        END IF;

        -- 3. Poblar la columna tsvector (spanish = LANGUAGE 3082)
        UPDATE public."Inventario"
        SET "ts_search" =
            SETWEIGHT(TO_TSVECTOR('spanish', COALESCE("CODIGO", '')),      'A') ||
            SETWEIGHT(TO_TSVECTOR('spanish', COALESCE("Referencia", '')),  'B') ||
            SETWEIGHT(TO_TSVECTOR('spanish', COALESCE("DESCRIPCION", '')), 'A') ||
            SETWEIGHT(TO_TSVECTOR('spanish', COALESCE("Categoria", '')),   'C') ||
            SETWEIGHT(TO_TSVECTOR('spanish', COALESCE("Marca", '')),       'C') ||
            SETWEIGHT(TO_TSVECTOR('spanish', COALESCE("Tipo", '')),        'C') ||
            SETWEIGHT(TO_TSVECTOR('spanish', COALESCE("Clase", '')),       'D') ||
            SETWEIGHT(TO_TSVECTOR('spanish', COALESCE("Linea", '')),       'C') ||
            SETWEIGHT(TO_TSVECTOR('spanish', COALESCE("Barra", '')),       'B')
        WHERE "ts_search" IS NULL;

        -- 4. Trigger para mantenimiento automatico (= CHANGE_TRACKING AUTO)
        CREATE OR REPLACE FUNCTION public.fn_inventario_ts_update()
        RETURNS TRIGGER
        LANGUAGE plpgsql
        AS $fn$
        BEGIN
            NEW."ts_search" :=
                SETWEIGHT(TO_TSVECTOR('spanish', COALESCE(NEW."CODIGO", '')),      'A') ||
                SETWEIGHT(TO_TSVECTOR('spanish', COALESCE(NEW."Referencia", '')),  'B') ||
                SETWEIGHT(TO_TSVECTOR('spanish', COALESCE(NEW."DESCRIPCION", '')), 'A') ||
                SETWEIGHT(TO_TSVECTOR('spanish', COALESCE(NEW."Categoria", '')),   'C') ||
                SETWEIGHT(TO_TSVECTOR('spanish', COALESCE(NEW."Marca", '')),       'C') ||
                SETWEIGHT(TO_TSVECTOR('spanish', COALESCE(NEW."Tipo", '')),        'C') ||
                SETWEIGHT(TO_TSVECTOR('spanish', COALESCE(NEW."Clase", '')),       'D') ||
                SETWEIGHT(TO_TSVECTOR('spanish', COALESCE(NEW."Linea", '')),       'C') ||
                SETWEIGHT(TO_TSVECTOR('spanish', COALESCE(NEW."Barra", '')),       'B');
            RETURN NEW;
        END;
        $fn$;

        DROP TRIGGER IF EXISTS "trg_inventario_ts_update" ON public."Inventario";
        CREATE TRIGGER "trg_inventario_ts_update"
            BEFORE INSERT OR UPDATE OF "CODIGO", "Referencia", "DESCRIPCION",
                "Categoria", "Marca", "Tipo", "Clase", "Linea", "Barra"
            ON public."Inventario"
            FOR EACH ROW
            EXECUTE FUNCTION public.fn_inventario_ts_update();

        RAISE NOTICE 'Trigger trg_inventario_ts_update creado';
    ELSE
        RAISE NOTICE 'ADVERTENCIA: Tabla Inventario no encontrada. No se puede crear indice FTS.';
    END IF;
END;
$fts$;

-- Ejemplo de consulta:
-- SELECT * FROM public."Inventario"
-- WHERE "ts_search" @@ PLAINTO_TSQUERY('spanish', 'aceite motor');
