-- +goose Up

-- Permite que cualquier tenant reciba leads en SU propio crm.Lead.
--
-- 1) cfg."PublicApiKey" — tokens por tenant para sitios externos
--    (acme.com). Formato `zk_<prefix>_<secret>`, guardamos solo hash SHA-256.
-- 2) Helpers: Create / List / Revoke / Verify.
-- 3) usp_sys_Lead_Upsert acepta p_target_company_id. Si viene null,
--    mantiene comportamiento previo (ZENTTO). Si viene resuelto por key o
--    por subdomain middleware, auto-provisiona Branch MAIN + Pipeline
--    LANDING + 6 stages para ese tenant en el primer lead.

-- +goose StatementBegin
CREATE TABLE IF NOT EXISTS cfg."PublicApiKey" (
  "KeyId"      BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"  INTEGER NOT NULL REFERENCES cfg."Company"("CompanyId"),
  "KeyPrefix"  VARCHAR(12) NOT NULL,
  "KeyHash"    VARCHAR(64) NOT NULL,
  "Label"      VARCHAR(100) NOT NULL DEFAULT 'Default',
  "Scopes"     VARCHAR(500) NOT NULL DEFAULT 'landing:lead:create',
  "IsActive"   BOOLEAN NOT NULL DEFAULT TRUE,
  "LastUsedAt" TIMESTAMP,
  "ExpiresAt"  TIMESTAMP,
  "CreatedAt"  TIMESTAMP NOT NULL DEFAULT (now() AT TIME ZONE 'UTC'),
  "CreatedByUserId" INTEGER,
  "IsDeleted"  BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE UNIQUE INDEX IF NOT EXISTS "UQ_cfg_PublicApiKey_Hash"
  ON cfg."PublicApiKey"("KeyHash") WHERE "IsDeleted" = FALSE;

CREATE INDEX IF NOT EXISTS "IX_cfg_PublicApiKey_Company"
  ON cfg."PublicApiKey"("CompanyId") WHERE "IsDeleted" = FALSE;
-- +goose StatementEnd

-- +goose StatementBegin
-- Genera una clave nueva. Devuelve p_key_plain UNA SOLA VEZ.
CREATE OR REPLACE FUNCTION cfg.usp_cfg_publicapikey_create(
  p_company_id  INTEGER,
  p_label       TEXT,
  p_user_id     INTEGER DEFAULT NULL,
  p_scopes      TEXT    DEFAULT 'landing:lead:create',
  p_expires_at  TIMESTAMP DEFAULT NULL,
  OUT p_key_id      BIGINT,
  OUT p_key_plain   TEXT,
  OUT p_key_prefix  TEXT,
  OUT p_resultado   INTEGER,
  OUT p_mensaje     VARCHAR
) RETURNS RECORD
LANGUAGE plpgsql AS $$
DECLARE
  v_prefix TEXT;
  v_secret TEXT;
  v_plain  TEXT;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM cfg."Company" WHERE "CompanyId" = p_company_id AND "IsDeleted" = FALSE) THEN
    p_resultado := 0;
    p_mensaje   := 'Company no encontrada'::VARCHAR;
    RETURN;
  END IF;

  v_prefix := 'zk_' || SUBSTRING(MD5(random()::TEXT || clock_timestamp()::TEXT) FOR 8);
  v_secret := ENCODE(gen_random_bytes(24), 'hex');
  v_plain  := v_prefix || '_' || v_secret;

  INSERT INTO cfg."PublicApiKey" ("CompanyId","KeyPrefix","KeyHash","Label","Scopes","ExpiresAt","CreatedByUserId")
  VALUES (
    p_company_id,
    v_prefix,
    ENCODE(DIGEST(v_plain, 'sha256'), 'hex'),
    COALESCE(NULLIF(TRIM(p_label), ''), 'Default'),
    COALESCE(NULLIF(TRIM(p_scopes), ''), 'landing:lead:create'),
    p_expires_at,
    p_user_id
  )
  RETURNING "KeyId" INTO p_key_id;

  p_key_plain  := v_plain;
  p_key_prefix := v_prefix;
  p_resultado  := 1;
  p_mensaje    := 'Key generada'::VARCHAR;
EXCEPTION WHEN OTHERS THEN
  p_resultado := 0;
  p_mensaje   := ('Error: ' || SQLERRM)::VARCHAR;
END;
$$;
-- +goose StatementEnd

-- +goose StatementBegin
-- Resuelve key plain → CompanyId. NULL si inválida / expirada / revocada.
CREATE OR REPLACE FUNCTION cfg.usp_cfg_publicapikey_verify(
  p_key_plain TEXT
) RETURNS INTEGER
LANGUAGE plpgsql AS $$
DECLARE
  v_hash     TEXT;
  v_company  INTEGER;
BEGIN
  IF p_key_plain IS NULL OR TRIM(p_key_plain) = '' THEN
    RETURN NULL;
  END IF;

  v_hash := ENCODE(DIGEST(TRIM(p_key_plain), 'sha256'), 'hex');

  SELECT "CompanyId" INTO v_company
  FROM cfg."PublicApiKey"
  WHERE "KeyHash" = v_hash
    AND "IsActive" = TRUE
    AND "IsDeleted" = FALSE
    AND ("ExpiresAt" IS NULL OR "ExpiresAt" > (now() AT TIME ZONE 'UTC'))
  LIMIT 1;

  IF v_company IS NOT NULL THEN
    UPDATE cfg."PublicApiKey"
    SET "LastUsedAt" = (now() AT TIME ZONE 'UTC')
    WHERE "KeyHash" = v_hash;
  END IF;

  RETURN v_company;
END;
$$;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION cfg.usp_cfg_publicapikey_list(
  p_company_id INTEGER
) RETURNS TABLE(
  "KeyId"      BIGINT,
  "KeyPrefix"  VARCHAR,
  "Label"      VARCHAR,
  "Scopes"     VARCHAR,
  "IsActive"   BOOLEAN,
  "LastUsedAt" TIMESTAMP,
  "ExpiresAt"  TIMESTAMP,
  "CreatedAt"  TIMESTAMP
)
LANGUAGE plpgsql AS $$
BEGIN
  RETURN QUERY
  SELECT k."KeyId", k."KeyPrefix", k."Label", k."Scopes", k."IsActive",
         k."LastUsedAt", k."ExpiresAt", k."CreatedAt"
  FROM cfg."PublicApiKey" k
  WHERE k."CompanyId" = p_company_id
    AND k."IsDeleted" = FALSE
  ORDER BY k."CreatedAt" DESC;
END;
$$;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION cfg.usp_cfg_publicapikey_revoke(
  p_key_id     BIGINT,
  p_company_id INTEGER,
  OUT p_resultado INTEGER,
  OUT p_mensaje   VARCHAR
) RETURNS RECORD
LANGUAGE plpgsql AS $$
BEGIN
  UPDATE cfg."PublicApiKey"
  SET "IsActive" = FALSE,
      "IsDeleted" = TRUE
  WHERE "KeyId" = p_key_id
    AND "CompanyId" = p_company_id
    AND "IsDeleted" = FALSE;

  IF NOT FOUND THEN
    p_resultado := 0;
    p_mensaje   := 'Key no encontrada o ya revocada'::VARCHAR;
    RETURN;
  END IF;

  p_resultado := 1;
  p_mensaje   := 'Key revocada'::VARCHAR;
EXCEPTION WHEN OTHERS THEN
  p_resultado := 0;
  p_mensaje   := ('Error: ' || SQLERRM)::VARCHAR;
END;
$$;
-- +goose StatementEnd

-- +goose StatementBegin
-- Reemplaza usp_sys_Lead_Upsert: acepta p_target_company_id opcional.
-- Si null, usa ZENTTO (CompanyCode='ZENTTO') como antes.
-- Si set, auto-provisiona pipeline LANDING para ese tenant.
DROP FUNCTION IF EXISTS public.usp_sys_lead_upsert(TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT) CASCADE;

CREATE OR REPLACE FUNCTION public.usp_sys_lead_upsert(
  p_email             TEXT,
  p_full_name         TEXT,
  p_company           TEXT DEFAULT NULL,
  p_country           TEXT DEFAULT NULL,
  p_source            TEXT DEFAULT 'zentto-landing',
  p_topic             TEXT DEFAULT NULL,
  p_message           TEXT DEFAULT NULL,
  p_phone             TEXT DEFAULT NULL,
  p_target_company_id INTEGER DEFAULT NULL,
  OUT p_resultado INTEGER,
  OUT p_mensaje   VARCHAR
) RETURNS RECORD
LANGUAGE plpgsql AS $$
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
  v_has_default  BOOLEAN;
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

  -- 1) public.Lead siempre
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

  -- 2) Resolver CompanyId destino
  IF p_target_company_id IS NOT NULL THEN
    SELECT "CompanyId" INTO v_company_id
    FROM cfg."Company"
    WHERE "CompanyId" = p_target_company_id AND "IsDeleted" = FALSE;
  ELSE
    SELECT "CompanyId" INTO v_company_id
    FROM cfg."Company"
    WHERE "CompanyCode" = 'ZENTTO' AND "IsDeleted" = FALSE
    LIMIT 1;
  END IF;

  IF v_company_id IS NULL THEN
    p_resultado := 1;
    p_mensaje   := 'Lead registrado (sin destino CRM)'::VARCHAR;
    RETURN;
  END IF;

  -- 3) Auto-provisionar pipeline LANDING + stages + branch del tenant destino
  SELECT "PipelineId" INTO v_pipeline_id
  FROM crm."Pipeline"
  WHERE "CompanyId" = v_company_id AND "PipelineCode" = 'LANDING' AND "IsDeleted" = FALSE
  LIMIT 1;

  IF v_pipeline_id IS NULL THEN
    SELECT EXISTS(SELECT 1 FROM crm."Pipeline" WHERE "CompanyId" = v_company_id AND "IsDefault" = TRUE AND "IsDeleted" = FALSE)
      INTO v_has_default;

    INSERT INTO crm."Pipeline" ("CompanyId","PipelineCode","PipelineName","IsDefault","IsActive")
    VALUES (v_company_id, 'LANDING', 'Landing Leads', NOT v_has_default, TRUE)
    RETURNING "PipelineId" INTO v_pipeline_id;

    INSERT INTO crm."PipelineStage" ("PipelineId","StageCode","StageName","StageOrder","Probability","DaysExpected","Color","IsClosed","IsWon","IsActive")
    VALUES
      (v_pipeline_id, 'PROSPECT',    'Prospecto',    1, 10.00,  3, '#60a5fa', FALSE, FALSE, TRUE),
      (v_pipeline_id, 'CONTACTED',   'Contactado',   2, 25.00,  5, '#818cf8', FALSE, FALSE, TRUE),
      (v_pipeline_id, 'QUALIFIED',   'Calificado',   3, 50.00,  7, '#a855f7', FALSE, FALSE, TRUE),
      (v_pipeline_id, 'PROPOSAL',    'Propuesta',    4, 70.00, 10, '#f59e0b', FALSE, FALSE, TRUE),
      (v_pipeline_id, 'CLOSED_WON',  'Ganado',       5, 100.00, 0, '#10b981', TRUE,  TRUE,  TRUE),
      (v_pipeline_id, 'CLOSED_LOST', 'Perdido',      6, 0.00,   0, '#ef4444', TRUE,  FALSE, TRUE);
  END IF;

  SELECT "StageId" INTO v_stage_id
  FROM crm."PipelineStage"
  WHERE "PipelineId" = v_pipeline_id AND "StageCode" = 'PROSPECT' AND "IsDeleted" = FALSE
  LIMIT 1;

  SELECT "BranchId" INTO v_branch_id
  FROM cfg."Branch"
  WHERE "CompanyId" = v_company_id AND "IsDeleted" = FALSE
  ORDER BY "BranchId" LIMIT 1;

  IF v_branch_id IS NULL THEN
    INSERT INTO cfg."Branch" ("CompanyId","BranchCode","BranchName","IsActive")
    VALUES (v_company_id, 'MAIN', 'Principal', TRUE)
    RETURNING "BranchId" INTO v_branch_id;
  END IF;

  IF v_stage_id IS NULL THEN
    p_resultado := 1;
    p_mensaje   := 'Lead registrado (stage PROSPECT no disponible)'::VARCHAR;
    RETURN;
  END IF;

  v_contact_name := LEFT(TRIM(p_full_name), 200);
  v_tags := NULLIF(array_to_string(ARRAY(
    SELECT x FROM UNNEST(ARRAY[v_source, v_topic]) AS t(x) WHERE x IS NOT NULL AND x <> ''
  ), ','), '');

  SELECT "LeadId" INTO v_crm_lead_id
  FROM crm."Lead"
  WHERE "CompanyId" = v_company_id
    AND "PipelineId" = v_pipeline_id
    AND LOWER("Email") = v_email
    AND "IsDeleted" = FALSE
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
      v_email, v_phone,
      'WEB',
      v_message, v_tags,
      'MEDIUM', 'OPEN'
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
DROP FUNCTION IF EXISTS public.usp_sys_lead_upsert(TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, INTEGER);
DROP FUNCTION IF EXISTS cfg.usp_cfg_publicapikey_revoke(BIGINT, INTEGER);
DROP FUNCTION IF EXISTS cfg.usp_cfg_publicapikey_list(INTEGER);
DROP FUNCTION IF EXISTS cfg.usp_cfg_publicapikey_verify(TEXT);
DROP FUNCTION IF EXISTS cfg.usp_cfg_publicapikey_create(INTEGER, TEXT, INTEGER, TEXT, TIMESTAMP);
DROP TABLE IF EXISTS cfg."PublicApiKey";
-- +goose StatementEnd
