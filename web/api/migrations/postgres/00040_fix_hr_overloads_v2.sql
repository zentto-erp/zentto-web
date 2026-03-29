-- +goose Up
-- +goose StatementBegin
-- Elimina overloads duplicados de funciones HR creados por run-functions.sql
-- después de que goose aplicó migraciones 33/34
DO $$
DECLARE
  fn_name TEXT;
  fn_oid OID;
  fn_args TEXT;
  keep_oid OID;
BEGIN
  FOR fn_name IN
    SELECT p.proname
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public'
      AND p.proname LIKE 'usp_hr_%'
    GROUP BY p.proname
    HAVING COUNT(*) > 1
  LOOP
    SELECT MAX(p.oid) INTO keep_oid
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public' AND p.proname = fn_name;

    FOR fn_oid, fn_args IN
      SELECT p.oid, pg_get_function_identity_arguments(p.oid)
      FROM pg_proc p
      JOIN pg_namespace n ON n.oid = p.pronamespace
      WHERE n.nspname = 'public' AND p.proname = fn_name AND p.oid <> keep_oid
    LOOP
      EXECUTE format('DROP FUNCTION IF EXISTS public.%I(%s) CASCADE', fn_name, fn_args);
    END LOOP;
  END LOOP;
END $$;
-- +goose StatementEnd

-- +goose Down
-- No-op: solo limpieza de duplicados
