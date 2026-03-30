-- ============================================================
-- run-seeds.sql — Ejecuta TODOS los seeds (para zentto_demo)
-- Para BDs de clientes, usar run-seeds-config.sql solamente
-- ============================================================

\echo ''
\echo '╔══════════════════════════════════════════════════════╗'
\echo '║  Zentto — Seeds completos (Config + Starter + Demo)  ║'
\echo '╚══════════════════════════════════════════════════════╝'
\echo ''

\i run-seeds-config.sql
\i run-seeds-starter.sql
\i run-seeds-demo.sql

\echo ''
\echo '✓ Todos los seeds completados'
\echo ''
