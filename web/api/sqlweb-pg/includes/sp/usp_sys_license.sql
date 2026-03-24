-- ============================================================
-- usp_sys_license.sql — Licencias Zentto (validate / create / renew / revoke)
-- Motor: PostgreSQL (plpgsql)
-- Paridad: web/api/sqlweb/includes/sp/usp_sys_license.sql
-- ============================================================

-- SP: validar licencia por companyCode + licenseKey
CREATE OR REPLACE FUNCTION usp_sys_license_validate(
  p_company_code VARCHAR,
  p_license_key  VARCHAR
)
RETURNS TABLE(
  "ok"            BOOLEAN,
  "reason"        VARCHAR,
  "plan"          VARCHAR,
  "modules"       TEXT,
  "expires_at"    TIMESTAMP,
  "days_remaining" INT,
  "company_name"  VARCHAR,
  "license_type"  VARCHAR
)
LANGUAGE plpgsql AS $$
DECLARE
  v_company_id   BIGINT;
  v_company_name VARCHAR(200);
  v_is_active    BOOLEAN;
  v_license_id   BIGINT;
  v_license_key  VARCHAR(64);
  v_status       VARCHAR(20);
  v_license_type VARCHAR(20);
  v_plan         VARCHAR(30);
  v_expires_at   TIMESTAMP;
  v_modules_json TEXT;
  v_days_rem     INT;
BEGIN
  -- Buscar empresa
  SELECT "CompanyId", "CompanyName", "IsActive"
  INTO v_company_id, v_company_name, v_is_active
  FROM cfg."Company"
  WHERE "CompanyCode" = p_company_code
  LIMIT 1;

  IF v_company_id IS NULL THEN
    RETURN QUERY SELECT FALSE, 'COMPANY_NOT_FOUND'::VARCHAR, ''::VARCHAR,
      ''::TEXT, NULL::TIMESTAMP, NULL::INT, ''::VARCHAR, ''::VARCHAR;
    RETURN;
  END IF;

  IF NOT v_is_active THEN
    RETURN QUERY SELECT FALSE, 'COMPANY_INACTIVE'::VARCHAR, ''::VARCHAR,
      ''::TEXT, NULL::TIMESTAMP, NULL::INT, v_company_name::VARCHAR, ''::VARCHAR;
    RETURN;
  END IF;

  -- Buscar licencia activa de la empresa
  SELECT "LicenseId", "LicenseKey", "Status", "LicenseType", "Plan", "ExpiresAt"
  INTO v_license_id, v_license_key, v_status, v_license_type, v_plan, v_expires_at
  FROM sys."License"
  WHERE "CompanyId" = v_company_id
    AND "Status" = 'ACTIVE'
  ORDER BY "CreatedAt" DESC
  LIMIT 1;

  IF v_license_id IS NULL THEN
    RETURN QUERY SELECT FALSE, 'LICENSE_NOT_FOUND'::VARCHAR, ''::VARCHAR,
      ''::TEXT, NULL::TIMESTAMP, NULL::INT, v_company_name::VARCHAR, ''::VARCHAR;
    RETURN;
  END IF;

  -- Verificar que la key coincide
  IF v_license_key <> p_license_key THEN
    RETURN QUERY SELECT FALSE, 'LICENSE_INVALID_KEY'::VARCHAR, ''::VARCHAR,
      ''::TEXT, NULL::TIMESTAMP, NULL::INT, v_company_name::VARCHAR, ''::VARCHAR;
    RETURN;
  END IF;

  -- Verificar estado
  IF v_status = 'SUSPENDED' THEN
    RETURN QUERY SELECT FALSE, 'LICENSE_SUSPENDED'::VARCHAR, v_plan::VARCHAR,
      ''::TEXT, v_expires_at, NULL::INT, v_company_name::VARCHAR, v_license_type::VARCHAR;
    RETURN;
  END IF;

  -- Verificar expiración (solo para SUBSCRIPTION y TRIAL)
  IF v_license_type NOT IN ('LIFETIME', 'INTERNAL') AND v_expires_at IS NOT NULL THEN
    IF v_expires_at < NOW() THEN
      RETURN QUERY SELECT FALSE, 'LICENSE_EXPIRED'::VARCHAR, v_plan::VARCHAR,
        ''::TEXT, v_expires_at, 0, v_company_name::VARCHAR, v_license_type::VARCHAR;
      RETURN;
    END IF;
  END IF;

  -- Calcular días restantes (NULL si no expira)
  IF v_expires_at IS NOT NULL THEN
    v_days_rem := EXTRACT(DAY FROM v_expires_at - NOW())::INT;
  ELSE
    v_days_rem := NULL;
  END IF;

  -- Obtener módulos del plan como JSON string
  SELECT array_to_json(array_agg(m."ModuleCode" ORDER BY m."SortOrder"))::TEXT
  INTO v_modules_json
  FROM usp_cfg_plan_getmodules(v_plan) m;

  RETURN QUERY SELECT
    TRUE,
    'OK'::VARCHAR,
    v_plan::VARCHAR,
    COALESCE(v_modules_json, '[]'::TEXT),
    v_expires_at,
    v_days_rem,
    v_company_name::VARCHAR,
    v_license_type::VARCHAR;
END; $$;

-- SP: crear licencia para un tenant
CREATE OR REPLACE FUNCTION usp_sys_license_create(
  p_company_id     BIGINT,
  p_license_type   VARCHAR DEFAULT 'SUBSCRIPTION',
  p_plan           VARCHAR DEFAULT 'STARTER',
  p_expires_at     TIMESTAMP DEFAULT NULL,
  p_paddle_sub_id  VARCHAR DEFAULT NULL,
  p_contract_ref   VARCHAR DEFAULT NULL,
  p_max_users      INT DEFAULT NULL,
  p_notes          TEXT DEFAULT NULL
)
RETURNS TABLE("LicenseId" BIGINT, "LicenseKey" VARCHAR, "ok" BOOLEAN)
LANGUAGE plpgsql AS $$
DECLARE
  v_license_id  BIGINT;
  v_license_key VARCHAR(64);
  v_apply_ok    BOOLEAN;
BEGIN
  -- Generar license key: hex de 32 bytes (usa md5 + random como fallback universal)
  v_license_key := md5(random()::TEXT || clock_timestamp()::TEXT || p_company_id::TEXT)
                || md5(random()::TEXT || clock_timestamp()::TEXT);
  -- Truncar a 64 chars
  v_license_key := LEFT(v_license_key, 64);

  -- Insertar licencia
  INSERT INTO sys."License" (
    "CompanyId", "LicenseType", "Plan", "LicenseKey", "Status",
    "StartsAt", "ExpiresAt", "PaddleSubId", "ContractRef",
    "MaxUsers", "Notes"
  ) VALUES (
    p_company_id, p_license_type, p_plan, v_license_key, 'ACTIVE',
    NOW(), p_expires_at, p_paddle_sub_id, p_contract_ref,
    p_max_users, p_notes
  )
  RETURNING "LicenseId" INTO v_license_id;

  -- Actualizar LicenseKey en cfg.Company
  UPDATE cfg."Company"
  SET "LicenseKey" = v_license_key
  WHERE "CompanyId" = p_company_id;

  -- Aplicar módulos al admin del tenant
  SELECT r."ok" INTO v_apply_ok
  FROM usp_cfg_plan_applymodules(p_company_id::INT, p_plan) r;

  RETURN QUERY SELECT v_license_id, v_license_key::VARCHAR, TRUE;
END; $$;

-- SP: renovar licencia
CREATE OR REPLACE FUNCTION usp_sys_license_renew(
  p_license_id     BIGINT,
  p_new_expires_at TIMESTAMP
)
RETURNS TABLE("ok" BOOLEAN)
LANGUAGE plpgsql AS $$
BEGIN
  UPDATE sys."License"
  SET "ExpiresAt"  = p_new_expires_at,
      "Status"     = 'ACTIVE',
      "UpdatedAt"  = NOW()
  WHERE "LicenseId" = p_license_id;

  RETURN QUERY SELECT TRUE;
END; $$;

-- SP: revocar licencia
CREATE OR REPLACE FUNCTION usp_sys_license_revoke(
  p_license_id BIGINT,
  p_reason     VARCHAR DEFAULT NULL
)
RETURNS TABLE("ok" BOOLEAN)
LANGUAGE plpgsql AS $$
BEGIN
  UPDATE sys."License"
  SET "Status"    = 'CANCELLED',
      "Notes"     = CASE
                      WHEN p_reason IS NOT NULL
                      THEN COALESCE("Notes", '') || E'\n[REVOKED] ' || p_reason
                      ELSE COALESCE("Notes", '') || E'\n[REVOKED]'
                    END,
      "UpdatedAt" = NOW()
  WHERE "LicenseId" = p_license_id;

  RETURN QUERY SELECT TRUE;
END; $$;
