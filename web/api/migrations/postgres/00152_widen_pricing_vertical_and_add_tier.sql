-- +goose Up
-- ══════════════════════════════════════════════════════════════════════════════
-- Lanzamiento multinicho (Lote 1.B) — paso 1/2
-- Ampliar chk_pricing_vertical con los nichos nuevos del plan y añadir
-- columna cfg."PricingPlan"."Tier" que materializa la taxonomía comercial
-- (core / bundle / addon / enterprise) documentada en
-- docs/lanzamiento/MATRIZ_COMERCIAL_V1.md.
--
-- Decisión de alcance: solo PostgreSQL. SQL Server se reconstruye en plan
-- dedicado posterior. Ver docs/lanzamiento/DECISIONES.md §D-002.
-- ══════════════════════════════════════════════════════════════════════════════

-- 1) Ampliar vertical: sumar pos, restaurante, ecommerce, crm, contabilidad,
--    inmobiliario. Se preservan los 7 valores existentes (erp, medical, tickets,
--    hotel, education, rental, none). Ver docs/lanzamiento/DECISIONES.md §D-004.
ALTER TABLE cfg."PricingPlan" DROP CONSTRAINT IF EXISTS chk_pricing_vertical;
ALTER TABLE cfg."PricingPlan"
    ADD CONSTRAINT chk_pricing_vertical
    CHECK ("VerticalType" IN (
        'erp','medical','tickets','hotel','education','rental','none',
        'pos','restaurante','ecommerce','crm','contabilidad','inmobiliario'
    ));

-- 2) Columna Tier: taxonomía comercial.
--    Nullable para no forzar backfill inmediato de planes legacy.
--    Los seeds del Lote 1.C rellenarán Tier para los planes del Lote 1 (10 ofertas).
ALTER TABLE cfg."PricingPlan"
    ADD COLUMN IF NOT EXISTS "Tier" VARCHAR(20) NULL;

ALTER TABLE cfg."PricingPlan" DROP CONSTRAINT IF EXISTS chk_pricing_tier;
ALTER TABLE cfg."PricingPlan"
    ADD CONSTRAINT chk_pricing_tier
    CHECK ("Tier" IS NULL OR "Tier" IN ('core','bundle','addon','enterprise'));

CREATE INDEX IF NOT EXISTS idx_pricing_plan_tier
    ON cfg."PricingPlan" ("Tier", "IsActive")
    WHERE "Tier" IS NOT NULL;

-- +goose Down
-- ══════════════════════════════════════════════════════════════════════════════
-- Down: revierte ambos cambios. Si hay filas con Tier no-nulo o con
-- VerticalType nuevos, la reversión fallará — limpiar antes de bajar.
-- ══════════════════════════════════════════════════════════════════════════════

DROP INDEX IF EXISTS idx_pricing_plan_tier;

ALTER TABLE cfg."PricingPlan" DROP CONSTRAINT IF EXISTS chk_pricing_tier;
ALTER TABLE cfg."PricingPlan" DROP COLUMN IF EXISTS "Tier";

ALTER TABLE cfg."PricingPlan" DROP CONSTRAINT IF EXISTS chk_pricing_vertical;
ALTER TABLE cfg."PricingPlan"
    ADD CONSTRAINT chk_pricing_vertical
    CHECK ("VerticalType" IN (
        'erp','medical','tickets','hotel','education','rental','none'
    ));
