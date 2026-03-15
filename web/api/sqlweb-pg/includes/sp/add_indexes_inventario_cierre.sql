-- ============================================================
-- DatqBoxWeb PostgreSQL - add_indexes_inventario_cierre.sql
-- Indices para acelerar consultas de inventario.
-- NOTA: MovInvent/MovInventMes son tablas legacy que no se
-- migran a PostgreSQL. Solo se crean indices sobre tablas
-- canonicas existentes.
-- ============================================================

-- master.Product: indice por ProductCode (columnas covering)
CREATE INDEX IF NOT EXISTS "IX_Product_ProductCode"
    ON master."Product" ("ProductCode")
    INCLUDE ("ProductName", "StockQty", "CostPrice", "SalesPrice");
