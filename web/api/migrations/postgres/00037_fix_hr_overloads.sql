-- +goose Up
-- ===========================================================================
-- 00037_fix_hr_overloads.sql
-- Elimina overloads duplicados de funciones RRHH creados por migraciones 33/34
-- ===========================================================================

-- +goose StatementBegin
DO $$
DECLARE
    fn_name TEXT;
    fn_oid OID;
    fn_args TEXT;
    keep_oid OID;
BEGIN
    -- Para cada función usp_* con más de 1 overload, mantener solo la más reciente
    FOR fn_name IN
        SELECT p.proname
        FROM pg_proc p
        JOIN pg_namespace n ON n.oid = p.pronamespace
        WHERE n.nspname = 'public' AND p.proname LIKE 'usp_%'
        GROUP BY p.proname
        HAVING COUNT(*) > 1
    LOOP
        -- Mantener el overload con mayor OID (el más reciente)
        SELECT MAX(p.oid) INTO keep_oid
        FROM pg_proc p
        JOIN pg_namespace n ON n.oid = p.pronamespace
        WHERE n.nspname = 'public' AND p.proname = fn_name;

        -- Eliminar los overloads viejos
        FOR fn_oid, fn_args IN
            SELECT p.oid, pg_get_function_identity_arguments(p.oid)
            FROM pg_proc p
            JOIN pg_namespace n ON n.oid = p.pronamespace
            WHERE n.nspname = 'public' AND p.proname = fn_name AND p.oid <> keep_oid
        LOOP
            EXECUTE format('DROP FUNCTION IF EXISTS public.%I(%s) CASCADE', fn_name, fn_args);
            RAISE NOTICE 'Dropped overload: %.%(%)', 'public', fn_name, fn_args;
        END LOOP;
    END LOOP;
END;
$$;
-- +goose StatementEnd

-- +goose Down
-- No rollback needed (idempotent cleanup)
