-- ============================================================
-- DatqBoxWeb PostgreSQL - 14_fulltext_search.sql
-- Fulltext search con tsvector + indice GIN
-- ============================================================

-- Columna de busqueda en master."Product"
ALTER TABLE master."Product" ADD COLUMN IF NOT EXISTS "SearchVector" TSVECTOR;

-- Trigger para actualizar SearchVector automaticamente
CREATE OR REPLACE FUNCTION trg_product_search_vector()
RETURNS TRIGGER AS $$
BEGIN
    NEW."SearchVector" :=
        setweight(to_tsvector('spanish', COALESCE(NEW."ProductCode", '')), 'A') ||
        setweight(to_tsvector('spanish', COALESCE(NEW."ProductName", '')), 'A') ||
        setweight(to_tsvector('spanish', COALESCE(NEW."CategoryCode", '')), 'B') ||
        setweight(to_tsvector('spanish', COALESCE(NEW."UnitCode", '')), 'C');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS "trg_master_Product_search" ON master."Product";
CREATE TRIGGER "trg_master_Product_search"
    BEFORE INSERT OR UPDATE ON master."Product"
    FOR EACH ROW EXECUTE FUNCTION trg_product_search_vector();

-- Indice GIN para busqueda rapida
CREATE INDEX IF NOT EXISTS "IX_master_Product_fulltext"
    ON master."Product" USING GIN ("SearchVector");

-- Indice trigram para busqueda fuzzy por codigo
CREATE INDEX IF NOT EXISTS "IX_master_Product_code_trgm"
    ON master."Product" USING GIN ("ProductCode" gin_trgm_ops);
