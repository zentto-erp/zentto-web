-- ============================================================
-- DatqBoxWeb PostgreSQL - verify_migration.sql
-- Verificación de objetos creados
-- ============================================================

\echo ''
\echo '--- Conteo de objetos por tipo ---'

SELECT 'Schemas' AS "Tipo", COUNT(*)::TEXT AS "Cantidad"
FROM information_schema.schemata
WHERE schema_name IN ('sec','cfg','master','acct','ar','ap','doc','pos','rest',
                       'fiscal','fin','hr','pay','audit','store')

UNION ALL

SELECT 'Tablas', COUNT(*)::TEXT
FROM information_schema.tables
WHERE table_schema IN ('sec','cfg','master','acct','ar','ap','doc','pos','rest',
                        'fiscal','fin','hr','pay','audit','store','public')
AND table_type = 'BASE TABLE'

UNION ALL

SELECT 'Funciones', COUNT(*)::TEXT
FROM information_schema.routines
WHERE routine_schema = 'public'
AND routine_type = 'FUNCTION'
AND (routine_name LIKE 'usp_%' OR routine_name LIKE 'sp_%'
     OR routine_name LIKE 'trg_%' OR routine_name LIKE 'try_cast_%'
     OR routine_name IN ('isnumeric','isdate','format_date','nullif_empty'))

UNION ALL

SELECT 'Vistas', COUNT(*)::TEXT
FROM information_schema.views
WHERE table_schema IN ('public','sec','cfg','master','acct','ar','ap','doc',
                        'pos','rest','fiscal','fin','hr','pay','audit','store')

UNION ALL

SELECT 'Indices', COUNT(*)::TEXT
FROM pg_indexes
WHERE schemaname IN ('sec','cfg','master','acct','ar','ap','doc','pos','rest',
                      'fiscal','fin','hr','pay','audit','store','public')
AND indexname NOT LIKE '%_pkey'

UNION ALL

SELECT 'Triggers', COUNT(*)::TEXT
FROM information_schema.triggers
WHERE trigger_schema IN ('sec','cfg','master','acct','ar','ap','doc','pos','rest',
                          'fiscal','fin','hr','pay','audit','store','public');

\echo ''
\echo '--- Tablas por schema ---'
SELECT table_schema AS "Schema", COUNT(*) AS "Tablas"
FROM information_schema.tables
WHERE table_schema IN ('sec','cfg','master','acct','ar','ap','doc','pos','rest',
                        'fiscal','fin','hr','pay','audit','store','public')
AND table_type = 'BASE TABLE'
GROUP BY table_schema
ORDER BY table_schema;

\echo ''
\echo '--- Funciones tipo SP ---'
SELECT COUNT(*) AS "Total funciones SP"
FROM information_schema.routines
WHERE routine_schema = 'public'
AND routine_type = 'FUNCTION'
AND (routine_name LIKE 'usp_%' OR routine_name LIKE 'sp_%');

\echo ''
\echo '--- Test HealthCheck ---'
SELECT * FROM usp_Sys_HealthCheck();

\echo ''
\echo '--- Verificacion completa ---'
