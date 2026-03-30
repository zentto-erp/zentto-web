-- ============================================================
-- 002_product_ecommerce_columns.sql
-- Agrega columnas ecommerce faltantes a master."Product"
-- Estas columnas existen en SQL Server pero faltaban en PG.
-- Idempotente: usa ADD COLUMN IF NOT EXISTS
-- ============================================================

ALTER TABLE master."Product"
  ADD COLUMN IF NOT EXISTS "LongDescription"  TEXT NULL,
  ADD COLUMN IF NOT EXISTS "WeightKg"         NUMERIC(10,3) NULL,
  ADD COLUMN IF NOT EXISTS "WidthCm"          NUMERIC(10,2) NULL,
  ADD COLUMN IF NOT EXISTS "HeightCm"         NUMERIC(10,2) NULL,
  ADD COLUMN IF NOT EXISTS "DepthCm"          NUMERIC(10,2) NULL,
  ADD COLUMN IF NOT EXISTS "WarrantyMonths"   INT NULL,
  ADD COLUMN IF NOT EXISTS "BarCode"          VARCHAR(50) NULL,
  ADD COLUMN IF NOT EXISTS "Slug"             VARCHAR(200) NULL;
