-- ============================================================
-- run-seeds-demo.sql — Seeds DEMO (Categoria C)
-- Solo para zentto_demo. Datos ficticios para sandbox.
-- ============================================================

\echo ''
\echo '═══ Seeds Demo (C) — Datos ficticios para sandbox ═══'
\echo ''

\i includes/sp/seed_demo_clientes_documentos.sql
\i includes/sp/seed_demo_ecommerce_pos.sql
\i includes/sp/seed_nomina_completo.sql
\i includes/sp/seed_nomina_completo_p2.sql
\i includes/sp/seed_rrhh_completo.sql
\i includes/sp/seed_demo_crm.sql
\i includes/sp/seed_demo_inventario_avanzado.sql
\i includes/sp/seed_demo_logistica.sql
\i includes/sp/seed_demo_manufactura.sql
\i includes/sp/seed_demo_flota.sql
\i includes/sp/seed_demo_users.sql
\i includes/sp/seed_live_data.sql

\echo '  ✓ Seeds Demo (C) completados'
