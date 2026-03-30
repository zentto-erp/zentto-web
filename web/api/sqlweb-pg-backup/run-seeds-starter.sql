-- ============================================================
-- run-seeds-starter.sql — Seeds STARTER (Categoria B)
-- Se ejecutan al crear BD nueva de cliente.
-- Datos iniciales minimos para operar (contabilidad, ecommerce, RBAC, etc.)
-- ============================================================

\echo ''
\echo '═══ Seeds Starter (B) — Datos iniciales para operar ═══'
\echo ''

\i 15_seed_contabilidad.sql
\i 17_seed_ecommerce.sql
\i includes/sp/seed_contabilidad.sql
\i includes/sp/seed_restaurante_componentes_recetas.sql
\i includes/sp/seed_restaurante_menu_extra.sql
\i includes/sp/seed_demo_rbac.sql
\i includes/sp/seed_demo_finanzas_contabilidad.sql

\echo '  ✓ Seeds Starter (B) completados'
