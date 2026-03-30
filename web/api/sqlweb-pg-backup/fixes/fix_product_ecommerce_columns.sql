-- ============================================================
-- fix_product_ecommerce_columns.sql  (PostgreSQL)
-- Agrega columnas ecommerce faltantes a master."Product"
-- Estas columnas existen en SQL Server pero nunca se migraron
-- al DDL de PostgreSQL via ALTER TABLE.
-- Aplicar en CADA base de datos de tenant:
--   psql -U postgres -d <tenant_db> -f fix_product_ecommerce_columns.sql
-- ============================================================

BEGIN;

ALTER TABLE master."Product"
  ADD COLUMN IF NOT EXISTS "LongDescription"    TEXT NULL,
  ADD COLUMN IF NOT EXISTS "WeightKg"           NUMERIC(10,3) NULL,
  ADD COLUMN IF NOT EXISTS "WidthCm"            NUMERIC(10,2) NULL,
  ADD COLUMN IF NOT EXISTS "HeightCm"           NUMERIC(10,2) NULL,
  ADD COLUMN IF NOT EXISTS "DepthCm"            NUMERIC(10,2) NULL,
  ADD COLUMN IF NOT EXISTS "WarrantyMonths"     INT NULL,
  ADD COLUMN IF NOT EXISTS "BarCode"            VARCHAR(50) NULL,
  ADD COLUMN IF NOT EXISTS "Slug"               VARCHAR(200) NULL;

COMMIT;

\echo '✅ fix_product_ecommerce_columns.sql aplicado correctamente'
