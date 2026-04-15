-- +goose Up
-- +goose StatementBegin

-- Fix #3 de usp_sys_lead_upsert: el pg driver pasa strings JS como tipo
-- 'unknown' y PG no puede match named args contra parámetros VARCHAR.
-- Error producido: SQLSTATE 42883 "function usp_sys_lead_upsert(p_email
-- => unknown, ...) does not exist".
--
-- Fix: cambiar parámetros a TEXT. PG castea unknown→text automáticamente,
-- y TEXT es funcionalmente equivalente a VARCHAR sin límite.

DROP FUNCTION IF EXISTS public.usp_sys_lead_upsert(VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS public.usp_sys_lead_upsert(TEXT, TEXT, TEXT, TEXT, TEXT) CASCADE;

CREATE OR REPLACE FUNCTION public.usp_sys_lead_upsert(
  p_email     TEXT,
  p_full_name TEXT,
  p_company   TEXT DEFAULT NULL,
  p_country   TEXT DEFAULT NULL,
  p_source    TEXT DEFAULT 'zentto-landing',
  OUT p_resultado INTEGER,
  OUT p_mensaje   VARCHAR
) RETURNS RECORD
LANGUAGE plpgsql
AS $$
DECLARE
  v_email_clean  TEXT;
  v_source_clean TEXT;
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

-- Y mientras tocamos: revertimos el debug de routes.ts en el PR siguiente.

-- +goose Down
-- +goose StatementBegin
DROP FUNCTION IF EXISTS public.usp_sys_lead_upsert(TEXT, TEXT, TEXT, TEXT, TEXT);
-- +goose StatementEnd
