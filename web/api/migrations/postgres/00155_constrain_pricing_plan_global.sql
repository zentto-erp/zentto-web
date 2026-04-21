-- +goose Up
-- ══════════════════════════════════════════════════════════════════════════════
-- Lote 2.C — cierre gap G-07 del audit del Lote 1 multinicho.
--
-- Motivo: los SPs de lectura (usp_cfg_pricing_plan_list, _get,
-- usp_cfg_catalog_list, usp_cfg_plan_get_by_slug, _get_by_paddle_price_id) NO
-- filtran por "CompanyId". Eso significa que cualquier fila con "CompanyId"
-- distinto de 0 quedaría expuesta en endpoints públicos de pricing/catalog.
--
-- Hoy el riesgo es solo teórico: todos los seeds y el UPSERT del backoffice
-- (usp_cfg_plan_upsert) guardan "CompanyId=0". Pero la arquitectura permite
-- un leak futuro si alguien introduce un plan con "CompanyId<>0" por error.
--
-- Acción: constraint CHECK que fuerza el invariante "CompanyId = 0". Si en el
-- futuro se quiere soportar "planes por tenant", se baja el constraint y se
-- añade filtrado explícito por "CompanyId" en los SPs y endpoints. Hasta
-- entonces, los planes son globales.
--
-- Solo PostgreSQL (decisión D-002, docs/lanzamiento/DECISIONES.md).
-- ══════════════════════════════════════════════════════════════════════════════

-- Salvaguarda: si existen filas con CompanyId<>0 (ninguna hoy según audit),
-- el ADD CONSTRAINT fallará. El deploy-dev-api entonces reporta error
-- claro y permite limpiar los datos manualmente antes de re-ejecutar.

ALTER TABLE cfg."PricingPlan" DROP CONSTRAINT IF EXISTS chk_pricing_plan_global;
ALTER TABLE cfg."PricingPlan"
    ADD CONSTRAINT chk_pricing_plan_global
    CHECK ("CompanyId" = 0);

-- Comentario explicativo en la columna para documentar el invariante.
COMMENT ON COLUMN cfg."PricingPlan"."CompanyId" IS
'Reservado. Invariante enforced por chk_pricing_plan_global: siempre 0 (plan global). Si en el futuro se soporta planes por tenant, bajar el constraint y filtrar por CompanyId en SPs públicos.';

-- +goose Down
-- Revierte el constraint. NO revierte el comment (no hace daño dejarlo).
ALTER TABLE cfg."PricingPlan" DROP CONSTRAINT IF EXISTS chk_pricing_plan_global;
