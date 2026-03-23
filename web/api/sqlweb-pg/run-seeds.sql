-- ============================================================
-- run-seeds.sql — Seeds idempotentes que se ejecutan SIEMPRE
-- Se ejecuta después de goose up en cada deploy
-- Todos los seeds usan INSERT ... ON CONFLICT o IF NOT EXISTS
-- ============================================================

\echo ''
\echo '╔══════════════════════════════════════════════════════╗'
\echo '║  Zentto — Seeds idempotentes (post-goose)            ║'
\echo '╚══════════════════════════════════════════════════════╝'
\echo ''

-- Referencia base (fiscal config, tax rates)
\echo '[1/14] Seed Reference Data...'
\i 06_seed_reference_data.sql

-- Contabilidad
\echo '[2/14] Seed Contabilidad base...'
\i 15_seed_contabilidad.sql

-- Nomina
\echo '[3/14] Seed Nomina base...'
\i 16_seed_nomina.sql

-- Ecommerce
\echo '[4/14] Seed Ecommerce base...'
\i 17_seed_ecommerce.sql

-- Países (cfg.Country — con columnas extendidas y seed VE/ES/CO/MX/US)
\echo '[5/14] Seed Countries...'
\i includes/sp/sp_cfg_country.sql

-- Estados + Lookups (cfg.State 157 registros + cfg.Lookup 28 registros)
\echo '[6/14] Seed States + Lookups...'
\i includes/sp/sp_cfg_state_lookup.sql

-- Plan de cuentas
\echo '[7/14] Seed Account Plan...'
\i includes/sp/seed_account_plan.sql

-- Contabilidad avanzada
\echo '[8/14] Seed Contabilidad avanzada...'
\i includes/sp/seed_contabilidad.sql

-- Constantes legales (LOTTT, SS, FAOV, etc.)
\echo '[9/14] Seed Constantes y Conceptos Legal...'
\i includes/sp/seed_constantes_y_conceptos_legal.sql

-- Gananciales y Deducciones
\echo '[10/14] Seed Gananciales y Deducciones...'
\i includes/sp/seed_gananciales_y_deducciones_completo.sql

-- Nomina completo (batches, vacaciones, salud ocupacional)
\echo '[11/14] Seed Nomina completo...'
\i includes/sp/seed_nomina_completo.sql

\echo '[12/14] Seed Nomina completo P2...'
\i includes/sp/seed_nomina_completo_p2.sql

-- RRHH completo
\echo '[13/14] Seed RRHH completo...'
\i includes/sp/seed_rrhh_completo.sql

-- Plantillas de reportes contables
\echo '[14/14] Seed Report Templates...'
\i includes/sp/seed_report_templates.sql

\echo ''
\echo '✓ Seeds completados exitosamente'
\echo ''
