-- +goose Up
-- +goose StatementBegin

-- Fix final de 00089: callSpOut convierte FullName → p_full_name (snake_case
-- con separador por cada cambio mayúscula→minúscula). La versión previa del
-- SP usaba p_fullname (sin underscore), causando "function does not exist"
-- al invocar named arg → 500 en /api/landing/register.
--
-- Soluciones:
-- 1. Drop del SP con la signatura previa (p_fullname)
-- 2. CREATE con p_full_name (snake-case correcto)

DROP FUNCTION IF EXISTS public.usp_sys_lead_upsert(VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR) CASCADE;

CREATE OR REPLACE FUNCTION public.usp_sys_lead_upsert(
  p_email     VARCHAR,
  p_full_name VARCHAR,
  p_company   VARCHAR DEFAULT NULL,
  p_country   VARCHAR DEFAULT NULL,
  p_source    VARCHAR DEFAULT 'zentto-landing',
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

  IF v_email_clean = '' OR p_full_name IS NULL OR TRIM(p_full_name) = '' THEN
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
    TRIM(p_full_name),
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
-- +goose StatementEnd
