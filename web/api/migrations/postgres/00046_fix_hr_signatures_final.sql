-- +goose Up
-- Fix definitivo: eliminar overloads HR duplicados causados por includes/sp/ con signaturas viejas.
-- Esta migracion dropea las signaturas viejas de las 9 funciones HR.
-- Las signaturas nuevas ya existen (creadas por 00045 o por run-functions.sql actualizado).

-- +goose StatementBegin
DO $$
DECLARE
  _fn text;
  _oid oid;
  _args text;
BEGIN
  -- Iterar las 9 funciones con posibles duplicados
  FOR _fn IN SELECT unnest(ARRAY[
    'usp_hr_committee_list',
    'usp_hr_medexam_list',
    'usp_hr_medorder_list',
    'usp_hr_obligation_getbycountry',
    'usp_hr_obligation_list',
    'usp_hr_occhealth_list',
    'usp_hr_savings_list',
    'usp_hr_training_list',
    'usp_hr_trust_list'
  ])
  LOOP
    -- Si hay mas de 1 overload, dropear todos excepto el mas reciente
    IF (SELECT COUNT(*) FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
        WHERE n.nspname = 'public' AND p.proname = _fn) > 1 THEN

      FOR _oid, _args IN
        SELECT p.oid, pg_get_function_identity_arguments(p.oid)
        FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
        WHERE n.nspname = 'public' AND p.proname = _fn
        ORDER BY p.oid ASC  -- oldest first
        OFFSET 0 LIMIT (
          SELECT COUNT(*) - 1 FROM pg_proc p2 JOIN pg_namespace n2 ON n2.oid = p2.pronamespace
          WHERE n2.nspname = 'public' AND p2.proname = _fn
        )
      LOOP
        EXECUTE format('DROP FUNCTION IF EXISTS public.%I(%s) CASCADE', _fn, _args);
        RAISE NOTICE 'Dropped old overload: %.%(%)', 'public', _fn, _args;
      END LOOP;
    END IF;
  END LOOP;

  -- Verificacion: no debe quedar ningun duplicado
  IF EXISTS (
    SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public' AND p.proname LIKE 'usp_%'
    GROUP BY p.proname HAVING COUNT(*) > 1
  ) THEN
    RAISE WARNING 'Aun hay funciones con overloads duplicados despues de cleanup';
  ELSE
    RAISE NOTICE 'OK: cero overloads duplicados en funciones usp_*';
  END IF;
END;
$$;
-- +goose StatementEnd

-- +goose Down
-- No-op: los overloads viejos no deben restaurarse
