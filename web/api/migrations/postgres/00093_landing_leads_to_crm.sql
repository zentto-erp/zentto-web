-- +goose Up

-- Integración landing → CRM:
--  1) public."Lead" gana columnas Topic, Message, Phone.
--  2) Se garantiza un Branch + Pipeline "LANDING" con stages para el tenant
--     principal (Company con CompanyCode='ZENTTO'). Si no existe, no se crea
--     nada (la migración es idempotente y defensiva).
--  3) usp_sys_Lead_Upsert acepta p_topic/p_message/p_phone y, además del
--     upsert en public."Lead", crea un crm."Lead" en el pipeline LANDING del
--     tenant ZENTTO con stage PROSPECT (primera etapa). El email+source
--     sigue siendo la llave natural para idempotencia.

-- +goose StatementBegin
ALTER TABLE public."Lead"
  ADD COLUMN IF NOT EXISTS "Topic"   VARCHAR(40),
  ADD COLUMN IF NOT EXISTS "Message" TEXT,
  ADD COLUMN IF NOT EXISTS "Phone"   VARCHAR(40);
-- +goose StatementEnd

-- +goose StatementBegin
DO $$
DECLARE
  v_company_id    INTEGER;
  v_branch_id     INTEGER;
  v_pipeline_id   BIGINT;
  v_has_stages    BOOLEAN;
BEGIN
  SELECT "CompanyId" INTO v_company_id
  FROM cfg."Company"
  WHERE "CompanyCode" = 'ZENTTO' AND "IsDeleted" = FALSE
  LIMIT 1;

  IF v_company_id IS NULL THEN
    RAISE NOTICE 'Tenant ZENTTO no encontrado — skip seed de pipeline/stages';
    RETURN;
  END IF;

  -- Branch MAIN (crm.Lead requiere BranchId NOT NULL)
  SELECT "BranchId" INTO v_branch_id
  FROM cfg."Branch"
  WHERE "CompanyId" = v_company_id AND "IsDeleted" = FALSE
  ORDER BY "BranchId" LIMIT 1;

  IF v_branch_id IS NULL THEN
    INSERT INTO cfg."Branch" ("CompanyId", "BranchCode", "BranchName", "IsActive")
    VALUES (v_company_id, 'MAIN', 'Principal', TRUE)
    RETURNING "BranchId" INTO v_branch_id;
  END IF;

  -- Pipeline LANDING (IsDefault=true si no hay otro default)
  SELECT "PipelineId" INTO v_pipeline_id
  FROM crm."Pipeline"
  WHERE "CompanyId" = v_company_id
    AND "PipelineCode" = 'LANDING'
    AND "IsDeleted" = FALSE
  LIMIT 1;

  IF v_pipeline_id IS NULL THEN
    INSERT INTO crm."Pipeline" ("CompanyId", "PipelineCode", "PipelineName", "IsDefault", "IsActive")
    VALUES (
      v_company_id,
      'LANDING',
      'Landing Leads',
      NOT EXISTS (SELECT 1 FROM crm."Pipeline" WHERE "CompanyId" = v_company_id AND "IsDefault" = TRUE AND "IsDeleted" = FALSE),
      TRUE
    )
    RETURNING "PipelineId" INTO v_pipeline_id;
  END IF;

  SELECT EXISTS (SELECT 1 FROM crm."PipelineStage" WHERE "PipelineId" = v_pipeline_id AND "IsDeleted" = FALSE)
    INTO v_has_stages;

  IF NOT v_has_stages THEN
    INSERT INTO crm."PipelineStage" ("PipelineId", "StageCode", "StageName", "StageOrder", "Probability", "DaysExpected", "Color", "IsClosed", "IsWon", "IsActive")
    VALUES
      (v_pipeline_id, 'PROSPECT',    'Prospecto',    1, 10.00,  3, '#60a5fa', FALSE, FALSE, TRUE),
      (v_pipeline_id, 'CONTACTED',   'Contactado',   2, 25.00,  5, '#818cf8', FALSE, FALSE, TRUE),
      (v_pipeline_id, 'QUALIFIED',   'Calificado',   3, 50.00,  7, '#a855f7', FALSE, FALSE, TRUE),
      (v_pipeline_id, 'PROPOSAL',    'Propuesta',    4, 70.00, 10, '#f59e0b', FALSE, FALSE, TRUE),
      (v_pipeline_id, 'CLOSED_WON',  'Ganado',       5, 100.00, 0, '#10b981', TRUE,  TRUE,  TRUE),
      (v_pipeline_id, 'CLOSED_LOST', 'Perdido',      6, 0.00,   0, '#ef4444', TRUE,  FALSE, TRUE);
  END IF;
END $$;
-- +goose StatementEnd

-- +goose StatementBegin
DROP FUNCTION IF EXISTS public.usp_sys_lead_upsert(TEXT, TEXT, TEXT, TEXT, TEXT) CASCADE;
DROP FUNCTION IF EXISTS public.usp_sys_lead_upsert(TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT) CASCADE;

CREATE OR REPLACE FUNCTION public.usp_sys_lead_upsert(
  p_email     TEXT,
  p_full_name TEXT,
  p_company   TEXT DEFAULT NULL,
  p_country   TEXT DEFAULT NULL,
  p_source    TEXT DEFAULT 'zentto-landing',
  p_topic     TEXT DEFAULT NULL,
  p_message   TEXT DEFAULT NULL,
  p_phone     TEXT DEFAULT NULL,
  OUT p_resultado INTEGER,
  OUT p_mensaje   VARCHAR
) RETURNS RECORD
LANGUAGE plpgsql
AS $$
DECLARE
  v_email        TEXT;
  v_source       TEXT;
  v_topic        TEXT;
  v_phone        TEXT;
  v_message      TEXT;
  v_company_id   INTEGER;
  v_branch_id    INTEGER;
  v_pipeline_id  BIGINT;
  v_stage_id     BIGINT;
  v_crm_lead_id  BIGINT;
  v_lead_code    VARCHAR(40);
  v_contact_name VARCHAR(200);
  v_tags         VARCHAR(500);
BEGIN
  v_email   := LOWER(TRIM(COALESCE(p_email, '')));
  v_source  := COALESCE(NULLIF(TRIM(p_source), ''), 'zentto-landing');
  v_topic   := NULLIF(TRIM(COALESCE(p_topic, '')), '');
  v_phone   := NULLIF(TRIM(COALESCE(p_phone, '')), '');
  v_message := NULLIF(TRIM(COALESCE(p_message, '')), '');

  IF v_email = '' OR p_full_name IS NULL OR TRIM(p_full_name) = '' THEN
    p_resultado := 0;
    p_mensaje   := 'Email y nombre son obligatorios'::VARCHAR;
    RETURN;
  END IF;

  IF v_email !~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$' THEN
    p_resultado := 0;
    p_mensaje   := 'Email inválido'::VARCHAR;
    RETURN;
  END IF;

  -- 1) public."Lead" — registro público idempotente por (Email, Source)
  INSERT INTO public."Lead" (
    "Email","FullName","Company","Country","Source","Topic","Message","Phone"
  )
  VALUES (
    v_email,
    TRIM(p_full_name),
    NULLIF(TRIM(COALESCE(p_company, '')), ''),
    NULLIF(TRIM(COALESCE(p_country, '')), ''),
    v_source,
    v_topic,
    v_message,
    v_phone
  )
  ON CONFLICT ("Email", "Source") DO UPDATE SET
    "FullName"  = EXCLUDED."FullName",
    "Company"   = COALESCE(EXCLUDED."Company", public."Lead"."Company"),
    "Country"   = COALESCE(EXCLUDED."Country", public."Lead"."Country"),
    "Topic"     = COALESCE(EXCLUDED."Topic",   public."Lead"."Topic"),
    "Message"   = COALESCE(EXCLUDED."Message", public."Lead"."Message"),
    "Phone"     = COALESCE(EXCLUDED."Phone",   public."Lead"."Phone"),
    "UpdatedAt" = (now() AT TIME ZONE 'UTC');

  -- 2) crm."Lead" — aparece en el CRM del tenant principal (ZENTTO)
  SELECT c."CompanyId" INTO v_company_id
  FROM cfg."Company" c
  WHERE c."CompanyCode" = 'ZENTTO' AND c."IsDeleted" = FALSE
  LIMIT 1;

  IF v_company_id IS NOT NULL THEN
    SELECT p."PipelineId" INTO v_pipeline_id
    FROM crm."Pipeline" p
    WHERE p."CompanyId" = v_company_id
      AND p."PipelineCode" = 'LANDING'
      AND p."IsDeleted" = FALSE
    LIMIT 1;

    IF v_pipeline_id IS NOT NULL THEN
      SELECT s."StageId" INTO v_stage_id
      FROM crm."PipelineStage" s
      WHERE s."PipelineId" = v_pipeline_id
        AND s."StageCode"  = 'PROSPECT'
        AND s."IsDeleted" = FALSE
      LIMIT 1;

      SELECT b."BranchId" INTO v_branch_id
      FROM cfg."Branch" b
      WHERE b."CompanyId" = v_company_id AND b."IsDeleted" = FALSE
      ORDER BY b."BranchId" LIMIT 1;

      IF v_stage_id IS NOT NULL AND v_branch_id IS NOT NULL THEN
        v_contact_name := LEFT(TRIM(p_full_name), 200);
        v_tags := NULLIF(array_to_string(ARRAY(
          SELECT x FROM UNNEST(ARRAY[v_source, v_topic]) AS t(x) WHERE x IS NOT NULL AND x <> ''
        ), ','), '');

        -- Reusar el lead si ya existe (mismo email dentro del pipeline LANDING)
        SELECT l."LeadId" INTO v_crm_lead_id
        FROM crm."Lead" l
        WHERE l."CompanyId"  = v_company_id
          AND l."PipelineId" = v_pipeline_id
          AND LOWER(l."Email") = v_email
          AND l."IsDeleted"  = FALSE
        LIMIT 1;

        IF v_crm_lead_id IS NULL THEN
          v_lead_code := 'LND-' || TO_CHAR(now() AT TIME ZONE 'UTC', 'YYYYMMDD-HH24MISS')
                              || '-' || SUBSTRING(MD5(v_email || v_source) FOR 6);

          INSERT INTO crm."Lead" (
            "CompanyId","BranchId","PipelineId","StageId","LeadCode",
            "ContactName","CompanyName","Email","Phone","Source","Notes","Tags",
            "Priority","Status"
          ) VALUES (
            v_company_id, v_branch_id, v_pipeline_id, v_stage_id, v_lead_code,
            v_contact_name,
            NULLIF(TRIM(COALESCE(p_company, '')), ''),
            v_email,
            v_phone,
            'WEB',
            v_message,
            v_tags,
            'MEDIUM',
            'OPEN'
          );
        ELSE
          UPDATE crm."Lead" SET
            "ContactName" = COALESCE(v_contact_name, "ContactName"),
            "CompanyName" = COALESCE(NULLIF(TRIM(COALESCE(p_company, '')), ''), "CompanyName"),
            "Phone"       = COALESCE(v_phone, "Phone"),
            "Notes"       = COALESCE(v_message, "Notes"),
            "Tags"        = COALESCE(v_tags, "Tags"),
            "UpdatedAt"   = (now() AT TIME ZONE 'UTC')
          WHERE "LeadId" = v_crm_lead_id;
        END IF;
      END IF;
    END IF;
  END IF;

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
DROP FUNCTION IF EXISTS public.usp_sys_lead_upsert(TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT);

ALTER TABLE public."Lead"
  DROP COLUMN IF EXISTS "Topic",
  DROP COLUMN IF EXISTS "Message",
  DROP COLUMN IF EXISTS "Phone";
-- +goose StatementEnd
