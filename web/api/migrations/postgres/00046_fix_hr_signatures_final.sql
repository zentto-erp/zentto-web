-- +goose Up
-- Fix definitivo: eliminar TODOS los overloads duplicados no intencionales.
--
-- Overloads INTENCIONALES (se preservan):
--   - usp_ap_payable_applypayment (TEXT + JSONB) — xml_compat
--   - usp_ar_receivable_applypayment (TEXT + JSONB) — xml_compat
--   - usp_hr_payroll_upsertrun (TEXT + JSONB) — xml_compat
--   - usp_hr_committee_save (core + service wrapper)
--   - usp_hr_medexam_save (core + service wrapper)
--   - usp_hr_occhealth_create (core + service wrapper)
--   - usp_hr_training_save (core + service wrapper)
--
-- Todo lo demas con COUNT(*) > 1 se limpia conservando el mas reciente.

-- +goose StatementBegin
DO $$
DECLARE
  _fn text;
  _cnt integer;
  _oid oid;
  _args text;
  _keep_oid oid;
  _total_dropped integer := 0;
  -- Funciones con overloads intencionales (no tocar)
  _intentional text[] := ARRAY[
    'usp_ap_payable_applypayment',
    'usp_ar_receivable_applypayment',
    'usp_hr_payroll_upsertrun',
    'usp_hr_committee_save',
    'usp_hr_medexam_save',
    'usp_hr_occhealth_create',
    'usp_hr_training_save'
  ];
BEGIN
  -- Buscar TODAS las funciones usp_* y sp_* con overloads
  FOR _fn, _cnt IN
    SELECT p.proname, COUNT(*)
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public'
      AND (p.proname LIKE 'usp\_%' OR p.proname LIKE 'sp\_%')
    GROUP BY p.proname
    HAVING COUNT(*) > 1
    ORDER BY p.proname
  LOOP
    -- Saltar overloads intencionales
    IF _fn = ANY(_intentional) THEN
      RAISE NOTICE 'SKIP (intencional): % (% versiones)', _fn, _cnt;
      CONTINUE;
    END IF;

    -- Conservar la version mas reciente (mayor OID), dropear el resto
    SELECT MAX(p.oid) INTO _keep_oid
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public' AND p.proname = _fn;

    FOR _oid, _args IN
      SELECT p.oid, pg_get_function_identity_arguments(p.oid)
      FROM pg_proc p
      JOIN pg_namespace n ON n.oid = p.pronamespace
      WHERE n.nspname = 'public' AND p.proname = _fn AND p.oid != _keep_oid
    LOOP
      EXECUTE format('DROP FUNCTION IF EXISTS public.%I(%s) CASCADE', _fn, _args);
      RAISE NOTICE 'DROPPED: %(%)', _fn, _args;
      _total_dropped := _total_dropped + 1;
    END LOOP;
  END LOOP;

  RAISE NOTICE '--- Total overloads eliminados: % ---', _total_dropped;

  -- Verificacion final
  IF EXISTS (
    SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public'
      AND (p.proname LIKE 'usp\_%' OR p.proname LIKE 'sp\_%')
      AND p.proname != ALL(_intentional)
    GROUP BY p.proname HAVING COUNT(*) > 1
  ) THEN
    RAISE WARNING 'ATENCION: aun hay overloads no intencionales';
  ELSE
    RAISE NOTICE 'OK: cero overloads duplicados no intencionales';
  END IF;
END;
$$;
-- +goose StatementEnd

-- +goose Down
-- No-op
