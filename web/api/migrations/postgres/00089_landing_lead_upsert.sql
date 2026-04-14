-- +goose Up
-- +goose StatementBegin

-- Fix del SP usp_sys_lead_upsert: la versión previa devolvía TABLE(ok,mensaje)
-- y el API (callSpOut en landing/service.ts) espera OUT params (Resultado,
-- Mensaje). El mismatch causaba 500 en /api/landing/register.
--
-- La tabla public."Lead" ya existe en baseline (003_tables.sql) — reusamos.
-- Añadimos UNIQUE (Email, Source) para hacer el upsert idempotente correcto.

-- Drop del SP previo (cualquier signatura)
DROP FUNCTION IF EXISTS public.usp_sys_lead_upsert(character varying, character varying, character varying, character varying, character varying) CASCADE;

-- +goose StatementEnd

-- +goose StatementBegin
-- Unique constraint para permitir ON CONFLICT upsert (si no existe ya)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'UQ_Lead_Email_Source' AND conrelid = 'public."Lead"'::regclass
  ) THEN
    -- Limpia duplicados previos (mantiene el más reciente) antes de agregar el unique
    DELETE FROM public."Lead" a USING public."Lead" b
    WHERE a."LeadId" < b."LeadId"
      AND a."Email" = b."Email"
      AND COALESCE(a."Source",'') = COALESCE(b."Source",'');
    ALTER TABLE public."Lead" ADD CONSTRAINT "UQ_Lead_Email_Source" UNIQUE ("Email", "Source");
  END IF;
END $$;
-- +goose StatementEnd

-- +goose StatementBegin
-- Recreate con OUT params compatible con callSpOut()
CREATE OR REPLACE FUNCTION public.usp_sys_lead_upsert(
  p_email    VARCHAR,
  p_fullname VARCHAR,
  p_company  VARCHAR DEFAULT NULL,
  p_country  VARCHAR DEFAULT NULL,
  p_source   VARCHAR DEFAULT 'zentto-landing',
  OUT p_resultado INTEGER,
  OUT p_mensaje   VARCHAR
) RETURNS RECORD
LANGUAGE plpgsql
AS $$
DECLARE
  v_email_clean  VARCHAR;
  v_source_clean VARCHAR;
BEGIN
  v_email_clean  := LOWER(TRIM(COALESCE(p_email, '')));
  v_source_clean := COALESCE(NULLIF(TRIM(p_source), ''), 'zentto-landing');

  IF v_email_clean = '' OR p_fullname IS NULL OR TRIM(p_fullname) = '' THEN
    p_resultado := 0;
    p_mensaje   := 'Email y nombre son obligatorios'::VARCHAR;
    RETURN;
  END IF;

  IF v_email_clean !~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$' THEN
    p_resultado := 0;
    p_mensaje   := 'Email inválido'::VARCHAR;
    RETURN;
  END IF;

  INSERT INTO public."Lead" ("Email", "FullName", "Company", "Country", "Source")
  VALUES (
    v_email_clean,
    TRIM(p_fullname),
    NULLIF(TRIM(COALESCE(p_company, '')), ''),
    NULLIF(TRIM(COALESCE(p_country, '')), ''),
    v_source_clean
  )
  ON CONFLICT ("Email", "Source") DO UPDATE SET
    "FullName"  = EXCLUDED."FullName",
    "Company"   = COALESCE(EXCLUDED."Company", public."Lead"."Company"),
    "Country"   = COALESCE(EXCLUDED."Country", public."Lead"."Country"),
    "UpdatedAt" = (now() AT TIME ZONE 'UTC');

  p_resultado := 1;
  p_mensaje   := 'Lead registrado'::VARCHAR;
EXCEPTION WHEN OTHERS THEN
  p_resultado := 0;
  p_mensaje   := ('Error: ' || SQLERRM)::VARCHAR;
END;
$$;
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
DROP FUNCTION IF EXISTS public.usp_sys_lead_upsert(VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR);
ALTER TABLE public."Lead" DROP CONSTRAINT IF EXISTS "UQ_Lead_Email_Source";
-- +goose StatementEnd
