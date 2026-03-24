-- ============================================================
-- usp_byoc.sql — Funciones BYOC Deploy Jobs + Onboarding Tokens
-- Motor: PostgreSQL (plpgsql)
-- Paridad: web/api/sqlweb/includes/sp/usp_byoc.sql
-- ============================================================

-- SP: crear job
CREATE OR REPLACE FUNCTION usp_sys_byocjob_create(
  p_company_id   BIGINT,
  p_provider     VARCHAR(30),
  p_domain       VARCHAR(255),
  p_region       VARCHAR(50)  DEFAULT NULL,
  p_server_size  VARCHAR(50)  DEFAULT NULL
)
RETURNS TABLE("JobId" BIGINT)
LANGUAGE plpgsql AS $$
DECLARE v_job_id BIGINT;
BEGIN
  INSERT INTO sys."ByocDeployJob" ("CompanyId", "Provider", "Status", "DeployConfig", "StartedAt")
  VALUES (
    p_company_id,
    p_provider,
    'PENDING',
    jsonb_build_object('domain', p_domain, 'region', p_region, 'serverSize', p_server_size),
    NOW()
  )
  RETURNING "JobId" INTO v_job_id;
  RETURN QUERY SELECT v_job_id;
END; $$;

-- SP: actualizar status del job
CREATE OR REPLACE FUNCTION usp_sys_byocjob_updatestatus(
  p_job_id         BIGINT,
  p_status         VARCHAR(20),
  p_server_ip      VARCHAR(45)  DEFAULT NULL,
  p_tenant_url     VARCHAR(255) DEFAULT NULL,
  p_log_line       TEXT         DEFAULT NULL,
  p_error_message  TEXT         DEFAULT NULL
)
RETURNS TABLE("ok" INT)
LANGUAGE plpgsql AS $$
BEGIN
  UPDATE sys."ByocDeployJob"
  SET "Status"       = p_status,
      "ServerIp"     = COALESCE(p_server_ip, "ServerIp"),
      "TenantUrl"    = COALESCE(p_tenant_url, "TenantUrl"),
      "LogOutput"    = CASE WHEN p_log_line IS NOT NULL
                            THEN COALESCE("LogOutput", '') || E'\n' || p_log_line
                            ELSE "LogOutput" END,
      "ErrorMessage" = COALESCE(p_error_message, "ErrorMessage"),
      "CompletedAt"  = CASE WHEN p_status IN ('DONE','FAILED') THEN NOW() ELSE "CompletedAt" END
  WHERE "JobId" = p_job_id;
  RETURN QUERY SELECT 1;
END; $$;

-- SP: append de log al job
CREATE OR REPLACE FUNCTION usp_sys_byocjob_appendlog(
  p_job_id   BIGINT,
  p_log_line TEXT
)
RETURNS TABLE("ok" INT)
LANGUAGE plpgsql AS $$
BEGIN
  UPDATE sys."ByocDeployJob"
  SET "LogOutput" = COALESCE("LogOutput", '') || E'\n' || p_log_line
  WHERE "JobId" = p_job_id;
  RETURN QUERY SELECT 1;
END; $$;

-- SP: obtener job
CREATE OR REPLACE FUNCTION usp_sys_byocjob_get(p_job_id BIGINT)
RETURNS TABLE(
  "JobId" BIGINT, "CompanyId" BIGINT, "Provider" VARCHAR,
  "Status" VARCHAR, "ServerIp" VARCHAR, "TenantUrl" VARCHAR,
  "LogOutput" TEXT, "ErrorMessage" TEXT,
  "StartedAt" TIMESTAMP, "CompletedAt" TIMESTAMP, "CreatedAt" TIMESTAMP
)
LANGUAGE plpgsql AS $$
BEGIN
  RETURN QUERY SELECT
    j."JobId", j."CompanyId", j."Provider"::VARCHAR,
    j."Status"::VARCHAR, j."ServerIp"::VARCHAR, j."TenantUrl"::VARCHAR,
    j."LogOutput", j."ErrorMessage", j."StartedAt", j."CompletedAt", j."CreatedAt"
  FROM sys."ByocDeployJob" j WHERE j."JobId" = p_job_id;
END; $$;

-- SP: listar jobs de un tenant
CREATE OR REPLACE FUNCTION usp_sys_byocjob_list(p_company_id BIGINT)
RETURNS TABLE(
  "JobId" BIGINT, "Provider" VARCHAR, "Status" VARCHAR,
  "ServerIp" VARCHAR, "TenantUrl" VARCHAR, "CreatedAt" TIMESTAMP
)
LANGUAGE plpgsql AS $$
BEGIN
  RETURN QUERY SELECT
    j."JobId", j."Provider"::VARCHAR, j."Status"::VARCHAR,
    j."ServerIp"::VARCHAR, j."TenantUrl"::VARCHAR, j."CreatedAt"
  FROM sys."ByocDeployJob" j
  WHERE j."CompanyId" = p_company_id
  ORDER BY j."CreatedAt" DESC;
END; $$;

-- SP: crear token de onboarding
CREATE OR REPLACE FUNCTION usp_sys_onboardingtoken_create(
  p_company_id  BIGINT,
  p_token       VARCHAR(64),
  p_expires_at  TIMESTAMP
)
RETURNS TABLE("TokenId" BIGINT)
LANGUAGE plpgsql AS $$
DECLARE v_id BIGINT;
BEGIN
  INSERT INTO sys."OnboardingToken" ("CompanyId", "Token", "DeployType", "ExpiresAt")
  VALUES (p_company_id, p_token, 'byoc', p_expires_at)
  RETURNING "TokenId" INTO v_id;
  RETURN QUERY SELECT v_id;
END; $$;

-- SP: validar y consumir token de onboarding
CREATE OR REPLACE FUNCTION usp_sys_onboardingtoken_validate(p_token VARCHAR(64))
RETURNS TABLE("CompanyId" BIGINT, "DeployType" VARCHAR, "ok" INT, "reason" VARCHAR)
LANGUAGE plpgsql AS $$
DECLARE
  v_company_id  BIGINT;
  v_deploy_type VARCHAR(20);
  v_expires_at  TIMESTAMP;
  v_used_at     TIMESTAMP;
BEGIN
  SELECT "CompanyId", "DeployType", "ExpiresAt", "UsedAt"
  INTO v_company_id, v_deploy_type, v_expires_at, v_used_at
  FROM sys."OnboardingToken"
  WHERE "Token" = p_token;

  IF v_company_id IS NULL THEN
    RETURN QUERY SELECT 0::BIGINT, ''::VARCHAR, 0, 'token_not_found'::VARCHAR;
    RETURN;
  END IF;
  IF v_used_at IS NOT NULL THEN
    RETURN QUERY SELECT 0::BIGINT, ''::VARCHAR, 0, 'token_already_used'::VARCHAR;
    RETURN;
  END IF;
  IF v_expires_at < NOW() THEN
    RETURN QUERY SELECT 0::BIGINT, ''::VARCHAR, 0, 'token_expired'::VARCHAR;
    RETURN;
  END IF;

  UPDATE sys."OnboardingToken" SET "UsedAt" = NOW() WHERE "Token" = p_token;
  RETURN QUERY SELECT v_company_id, v_deploy_type::VARCHAR, 1, ''::VARCHAR;
END; $$;
