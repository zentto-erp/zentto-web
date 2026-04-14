-- +goose Up
-- +goose StatementBegin

-- Tabla de leads capturados desde la landing / widget de chat / formularios públicos.
-- NO es multi-tenant (CompanyId=0) porque se captura ANTES de provisioning.
-- Un backoffice user los promueve luego a crm.Lead con el pipeline adecuado.
CREATE TABLE IF NOT EXISTS public."LandingLead" (
  "LandingLeadId" BIGSERIAL PRIMARY KEY,
  "Email" VARCHAR(150) NOT NULL,
  "FullName" VARCHAR(200) NOT NULL,
  "Company" VARCHAR(500),
  "Country" VARCHAR(10),
  "Source" VARCHAR(80) NOT NULL DEFAULT 'zentto-landing',
  "Status" VARCHAR(20) NOT NULL DEFAULT 'NEW',
  "Notes" TEXT,
  "IpAddress" VARCHAR(45),
  "UserAgent" VARCHAR(500),
  "ContactedAt" TIMESTAMP,
  "ConvertedToLeadId" BIGINT,
  "CreatedAt" TIMESTAMP NOT NULL DEFAULT (now() AT TIME ZONE 'UTC'),
  "UpdatedAt" TIMESTAMP NOT NULL DEFAULT (now() AT TIME ZONE 'UTC'),
  CONSTRAINT "UQ_LandingLead_Email_Source" UNIQUE ("Email", "Source")
);

CREATE INDEX IF NOT EXISTS "IX_LandingLead_Email" ON public."LandingLead" ("Email");
CREATE INDEX IF NOT EXISTS "IX_LandingLead_Source" ON public."LandingLead" ("Source");
CREATE INDEX IF NOT EXISTS "IX_LandingLead_CreatedAt" ON public."LandingLead" ("CreatedAt" DESC);

-- +goose StatementEnd

-- +goose StatementBegin
-- Upsert idempotente por (Email, Source): si el mismo lead viene varias veces,
-- actualizamos FullName / Company / Country. Devuelve Resultado=1 OK, 0 error.
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
  v_email_clean VARCHAR;
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

  INSERT INTO public."LandingLead" ("Email", "FullName", "Company", "Country", "Source")
  VALUES (
    v_email_clean,
    TRIM(p_fullname),
    NULLIF(TRIM(COALESCE(p_company, '')), ''),
    NULLIF(TRIM(COALESCE(p_country, '')), ''),
    v_source_clean
  )
  ON CONFLICT ("Email", "Source") DO UPDATE SET
    "FullName"  = EXCLUDED."FullName",
    "Company"   = COALESCE(EXCLUDED."Company", public."LandingLead"."Company"),
    "Country"   = COALESCE(EXCLUDED."Country", public."LandingLead"."Country"),
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
DROP TABLE IF EXISTS public."LandingLead";
-- +goose StatementEnd
