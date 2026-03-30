-- ============================================================
-- run-seeds-config.sql — Seeds de CONFIGURACION (Categoria A)
-- Se ejecutan en TODAS las BDs, cada deploy.
-- Datos de referencia del sistema (paises, estados, plan de cuentas, etc.)
-- ============================================================

\echo ''
\echo '═══ Seeds Config (A) — Datos de referencia del sistema ═══'
\echo ''

\i 06_seed_reference_data.sql
\i includes/sp/sp_cfg_country.sql
\i includes/sp/sp_cfg_state_lookup.sql
\i includes/sp/seed_account_plan.sql
\i includes/sp/seed_constantes_y_conceptos_legal.sql
\i includes/sp/seed_report_templates.sql

\echo '  ✓ Seeds Config (A) completados'
