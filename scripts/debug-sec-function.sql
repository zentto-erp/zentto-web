-- Debug v2: buscar TODAS las funciones que contengan "listcompanyaccesses"
\echo '=== TODAS las funciones con listcompanyaccesses ==='
SELECT p.oid, n.nspname as schema, p.proname as name,
       pg_get_function_identity_arguments(p.oid) as args,
       pg_get_function_result(p.oid) as return_type
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE p.proname ILIKE '%listcompanyaccesses%'
   OR p.proname ILIKE '%getcompanyaccesses%'
ORDER BY n.nspname, p.proname;

\echo '=== Probar SELECT * FROM usp_sec_user_listcompanyaccesses_default() ==='
SELECT * FROM usp_sec_user_listcompanyaccesses_default() LIMIT 2;

\echo '=== Probar SELECT * FROM usp_Sec_User_ListCompanyAccesses_Default() ==='
SELECT * FROM usp_Sec_User_ListCompanyAccesses_Default() LIMIT 2;

\echo '=== goose_db_version ==='
SELECT * FROM public.goose_db_version ORDER BY id;
