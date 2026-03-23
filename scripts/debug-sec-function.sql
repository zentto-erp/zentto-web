-- Debug: verificar función sec_user_listcompanyaccesses_default
\echo '=== Verificar existencia de funciones ==='
SELECT p.proname, pg_get_function_result(p.oid) as return_type
FROM pg_proc p
WHERE p.proname LIKE 'usp_sec_user_listcompanyaccesses%'
ORDER BY p.proname;

\echo '=== Verificar columnas de tablas ==='
SELECT table_schema, table_name, column_name, data_type
FROM information_schema.columns
WHERE (table_schema = 'cfg' AND table_name IN ('Company', 'Branch', 'Country'))
   OR (table_schema = 'sec' AND table_name = 'UserCompanyAccess')
ORDER BY table_schema, table_name, ordinal_position;

\echo '=== Intentar llamar la función ==='
SELECT * FROM usp_sec_user_listcompanyaccesses_default() LIMIT 3;

\echo '=== goose_db_version ==='
SELECT * FROM public.goose_db_version ORDER BY id;
