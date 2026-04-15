-- +goose Up
-- ══════════════════════════════════════════════════════════════════════════════
-- Hardening del pipeline de provisioning de tenants:
--   B1) sys.WebhookEvent — dedup de webhooks Paddle (evita doble provisioning)
--   B3) sec.PasswordResetToken — magic-link para set-password en welcome email
--   F3) sys.ProvisioningJob — tracking de provisioning incompleto/fallido para
--                             reintentos automáticos
-- ══════════════════════════════════════════════════════════════════════════════

-- ──────────────────────────────────────────────────────────────────────────────
-- B1) Dedup de webhooks Paddle
-- ──────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS sys."WebhookEvent" (
    "EventId"      VARCHAR(100) PRIMARY KEY,
    "EventType"    VARCHAR(60)  NOT NULL,
    "Source"       VARCHAR(30)  NOT NULL DEFAULT 'paddle'::VARCHAR,
    "ReceivedAt"   TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    "ProcessedAt"  TIMESTAMPTZ,
    "Status"       VARCHAR(20)  NOT NULL DEFAULT 'pending'::VARCHAR,
    "CompanyId"    INTEGER,
    "ErrorMessage" TEXT         NOT NULL DEFAULT ''::TEXT,
    "PayloadHash"  VARCHAR(64)  NOT NULL DEFAULT ''::VARCHAR,
    CONSTRAINT chk_webhook_event_status CHECK ("Status" IN ('pending','processing','done','error','skipped'))
);

CREATE INDEX IF NOT EXISTS idx_webhook_event_status ON sys."WebhookEvent" ("Status", "ReceivedAt");
CREATE INDEX IF NOT EXISTS idx_webhook_event_company ON sys."WebhookEvent" ("CompanyId");

-- usp_sys_webhook_event_dedup: intenta registrar evento. Devuelve was_new=true
-- si era nuevo (caller debe procesar), false si ya se había recibido (skip).
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION usp_sys_webhook_event_dedup(
    p_event_id     VARCHAR,
    p_event_type   VARCHAR,
    p_source       VARCHAR DEFAULT 'paddle',
    p_payload_hash VARCHAR DEFAULT ''
)
RETURNS TABLE("was_new" BOOLEAN, "previous_status" VARCHAR)
LANGUAGE plpgsql AS $$
DECLARE
    v_existing VARCHAR;
BEGIN
    SELECT "Status" INTO v_existing
      FROM sys."WebhookEvent"
     WHERE "EventId" = p_event_id;

    IF v_existing IS NOT NULL THEN
        RETURN QUERY SELECT FALSE, v_existing::VARCHAR;
        RETURN;
    END IF;

    INSERT INTO sys."WebhookEvent" ("EventId","EventType","Source","PayloadHash","Status")
    VALUES (p_event_id, p_event_type, p_source, COALESCE(p_payload_hash,''), 'processing');

    RETURN QUERY SELECT TRUE, NULL::VARCHAR;
END;
$$;
-- +goose StatementEnd

-- usp_sys_webhook_event_complete: marca evento como done/error con companyId y mensaje
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION usp_sys_webhook_event_complete(
    p_event_id     VARCHAR,
    p_status       VARCHAR,
    p_company_id   INTEGER DEFAULT NULL,
    p_error_message TEXT   DEFAULT ''
)
RETURNS TABLE("ok" BOOLEAN)
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE sys."WebhookEvent" SET
        "Status"       = p_status,
        "ProcessedAt"  = NOW(),
        "CompanyId"    = COALESCE(p_company_id, "CompanyId"),
        "ErrorMessage" = COALESCE(p_error_message, '')
    WHERE "EventId" = p_event_id;
    RETURN QUERY SELECT TRUE;
END;
$$;
-- +goose StatementEnd

-- ──────────────────────────────────────────────────────────────────────────────
-- B3) Magic-link tokens para set-password (welcome email seguro, sin password
--     plaintext en el correo).
--
-- Vive en BD master (no en tenant) porque se usa antes de que el tenant
-- exista físicamente en su BD. CompanyId apunta al Company recién provisionado.
-- ──────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS sec."PasswordResetToken" (
    "TokenId"     SERIAL       PRIMARY KEY,
    "Token"       VARCHAR(120) NOT NULL,
    "CompanyId"   INTEGER      NOT NULL,
    "UserCode"    VARCHAR(50)  NOT NULL,
    "Email"       VARCHAR(200) NOT NULL,
    "Purpose"     VARCHAR(40)  NOT NULL DEFAULT 'set_password'::VARCHAR,
    "CreatedAt"   TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    "ExpiresAt"   TIMESTAMPTZ  NOT NULL,
    "ConsumedAt"  TIMESTAMPTZ,
    "CreatedFromIp" VARCHAR(45) NOT NULL DEFAULT ''::VARCHAR,
    CONSTRAINT chk_password_reset_purpose CHECK ("Purpose" IN ('set_password','reset_password'))
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_password_reset_token ON sec."PasswordResetToken" ("Token");
CREATE INDEX IF NOT EXISTS idx_password_reset_company ON sec."PasswordResetToken" ("CompanyId");
CREATE INDEX IF NOT EXISTS idx_password_reset_email ON sec."PasswordResetToken" (LOWER("Email"));

-- usp_sec_password_reset_token_create: genera nuevo token (caller pasa el Token random)
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION usp_sec_password_reset_token_create(
    p_token       VARCHAR,
    p_company_id  INTEGER,
    p_user_code   VARCHAR,
    p_email       VARCHAR,
    p_purpose     VARCHAR DEFAULT 'set_password',
    p_ttl_hours   INTEGER DEFAULT 24,
    p_from_ip     VARCHAR DEFAULT ''
)
RETURNS TABLE("ok" BOOLEAN, "TokenId" INTEGER, "ExpiresAt" TIMESTAMPTZ)
LANGUAGE plpgsql AS $$
DECLARE
    v_id INTEGER;
    v_expires TIMESTAMPTZ;
BEGIN
    v_expires := NOW() + (p_ttl_hours || ' hours')::INTERVAL;
    INSERT INTO sec."PasswordResetToken" ("Token","CompanyId","UserCode","Email","Purpose","ExpiresAt","CreatedFromIp")
    VALUES (p_token, p_company_id, p_user_code, LOWER(p_email), p_purpose, v_expires, COALESCE(p_from_ip,''))
    RETURNING "TokenId" INTO v_id;
    RETURN QUERY SELECT TRUE, v_id, v_expires;
END;
$$;
-- +goose StatementEnd

-- usp_sec_password_reset_token_consume: valida + consume token (uso único)
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION usp_sec_password_reset_token_consume(
    p_token VARCHAR
)
RETURNS TABLE(
    "ok"         BOOLEAN,
    "mensaje"    VARCHAR,
    "CompanyId"  INTEGER,
    "UserCode"   VARCHAR,
    "Email"      VARCHAR
)
LANGUAGE plpgsql AS $$
DECLARE
    v_row RECORD;
BEGIN
    SELECT t."TokenId", t."CompanyId", t."UserCode", t."Email", t."ExpiresAt", t."ConsumedAt"
      INTO v_row
      FROM sec."PasswordResetToken" t
     WHERE t."Token" = p_token
     LIMIT 1;

    IF v_row IS NULL THEN
        RETURN QUERY SELECT FALSE, 'token_invalid'::VARCHAR, NULL::INTEGER, NULL::VARCHAR, NULL::VARCHAR;
        RETURN;
    END IF;
    IF v_row."ConsumedAt" IS NOT NULL THEN
        RETURN QUERY SELECT FALSE, 'token_used'::VARCHAR, v_row."CompanyId", v_row."UserCode"::VARCHAR, v_row."Email"::VARCHAR;
        RETURN;
    END IF;
    IF v_row."ExpiresAt" < NOW() THEN
        RETURN QUERY SELECT FALSE, 'token_expired'::VARCHAR, v_row."CompanyId", v_row."UserCode"::VARCHAR, v_row."Email"::VARCHAR;
        RETURN;
    END IF;

    UPDATE sec."PasswordResetToken" SET "ConsumedAt" = NOW() WHERE "TokenId" = v_row."TokenId";

    RETURN QUERY SELECT TRUE, 'ok'::VARCHAR, v_row."CompanyId", v_row."UserCode"::VARCHAR, v_row."Email"::VARCHAR;
END;
$$;
-- +goose StatementEnd

-- usp_sec_user_set_password_by_magic_link: cambia password de un user del tenant.
-- Llamado desde POST /v1/auth/set-password después de consumir el magic-link.
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION usp_sec_user_set_password_by_magic_link(
    p_company_id    INTEGER,
    p_user_code     VARCHAR,
    p_password_hash VARCHAR
)
RETURNS TABLE("ok" BOOLEAN, "mensaje" VARCHAR)
LANGUAGE plpgsql AS $$
DECLARE
    v_count INTEGER;
BEGIN
    UPDATE sec."User" SET
        "PasswordHash" = p_password_hash,
        "UpdatedAt"    = NOW()
    WHERE "CompanyId" = p_company_id AND "UserCode" = p_user_code;
    GET DIAGNOSTICS v_count = ROW_COUNT;
    IF v_count = 0 THEN
        RETURN QUERY SELECT FALSE, 'user_not_found'::VARCHAR;
        RETURN;
    END IF;
    RETURN QUERY SELECT TRUE, 'password_updated'::VARCHAR;
END;
$$;
-- +goose StatementEnd

-- ──────────────────────────────────────────────────────────────────────────────
-- F3) ProvisioningJob — tracking de provisioning incompleto / fallos para
-- reintento automático por un job worker (cron / sweeper).
-- ──────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS sys."ProvisioningJob" (
    "JobId"          SERIAL       PRIMARY KEY,
    "CompanyId"      INTEGER      NOT NULL,
    "CompanyCode"    VARCHAR(50)  NOT NULL,
    "Step"           VARCHAR(50)  NOT NULL,
    "Status"         VARCHAR(20)  NOT NULL DEFAULT 'pending'::VARCHAR,
    "Attempts"       INTEGER      NOT NULL DEFAULT 0,
    "MaxAttempts"    INTEGER      NOT NULL DEFAULT 5,
    "LastError"      TEXT         NOT NULL DEFAULT ''::TEXT,
    "ScheduledAt"    TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    "StartedAt"      TIMESTAMPTZ,
    "CompletedAt"    TIMESTAMPTZ,
    "PayloadJson"    JSONB        NOT NULL DEFAULT '{}'::JSONB,
    CONSTRAINT chk_provisioning_job_status CHECK ("Status" IN ('pending','running','done','error','dead'))
);

CREATE INDEX IF NOT EXISTS idx_provisioning_job_pending ON sys."ProvisioningJob" ("Status", "ScheduledAt") WHERE "Status" = 'pending';
CREATE INDEX IF NOT EXISTS idx_provisioning_job_company ON sys."ProvisioningJob" ("CompanyId", "Step");

-- usp_sys_provisioning_job_enqueue: crea o actualiza job (idempotente por Company+Step)
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION usp_sys_provisioning_job_enqueue(
    p_company_id   INTEGER,
    p_company_code VARCHAR,
    p_step         VARCHAR,
    p_payload_json JSONB DEFAULT '{}'::JSONB
)
RETURNS TABLE("ok" BOOLEAN, "JobId" INTEGER)
LANGUAGE plpgsql AS $$
DECLARE
    v_id INTEGER;
BEGIN
    SELECT "JobId" INTO v_id
      FROM sys."ProvisioningJob"
     WHERE "CompanyId" = p_company_id AND "Step" = p_step
       AND "Status" IN ('pending','running','error');

    IF v_id IS NOT NULL THEN
        UPDATE sys."ProvisioningJob" SET
            "PayloadJson" = p_payload_json,
            "ScheduledAt" = NOW()
        WHERE "JobId" = v_id;
        RETURN QUERY SELECT TRUE, v_id;
        RETURN;
    END IF;

    INSERT INTO sys."ProvisioningJob" ("CompanyId","CompanyCode","Step","PayloadJson")
    VALUES (p_company_id, p_company_code, p_step, p_payload_json)
    RETURNING "JobId" INTO v_id;
    RETURN QUERY SELECT TRUE, v_id;
END;
$$;
-- +goose StatementEnd

-- usp_sys_provisioning_job_complete: marca como done/error/dead
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION usp_sys_provisioning_job_complete(
    p_job_id       INTEGER,
    p_status       VARCHAR,
    p_error        TEXT DEFAULT ''
)
RETURNS TABLE("ok" BOOLEAN)
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE sys."ProvisioningJob" SET
        "Status"       = p_status,
        "CompletedAt"  = CASE WHEN p_status IN ('done','dead') THEN NOW() ELSE "CompletedAt" END,
        "Attempts"     = "Attempts" + 1,
        "LastError"    = COALESCE(p_error, '')
    WHERE "JobId" = p_job_id;
    RETURN QUERY SELECT TRUE;
END;
$$;
-- +goose StatementEnd

-- usp_sys_provisioning_job_pending: cola de jobs pendientes (para sweeper)
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION usp_sys_provisioning_job_pending(
    p_max_rows INTEGER DEFAULT 50
)
RETURNS TABLE(
    "JobId"        INTEGER,
    "CompanyId"    INTEGER,
    "CompanyCode"  VARCHAR,
    "Step"         VARCHAR,
    "Attempts"     INTEGER,
    "MaxAttempts"  INTEGER,
    "PayloadJson"  JSONB,
    "LastError"    TEXT
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT j."JobId", j."CompanyId", j."CompanyCode"::VARCHAR, j."Step"::VARCHAR,
           j."Attempts", j."MaxAttempts", j."PayloadJson", j."LastError"
      FROM sys."ProvisioningJob" j
     WHERE j."Status" = 'pending'
       AND j."Attempts" < j."MaxAttempts"
       AND j."ScheduledAt" <= NOW()
     ORDER BY j."ScheduledAt"
     LIMIT p_max_rows;
END;
$$;
-- +goose StatementEnd

-- +goose Down
DROP FUNCTION IF EXISTS usp_sys_provisioning_job_pending(INTEGER);
DROP FUNCTION IF EXISTS usp_sys_provisioning_job_complete(INTEGER, VARCHAR, TEXT);
DROP FUNCTION IF EXISTS usp_sys_provisioning_job_enqueue(INTEGER, VARCHAR, VARCHAR, JSONB);
DROP TABLE IF EXISTS sys."ProvisioningJob";

DROP FUNCTION IF EXISTS usp_sec_user_set_password_by_magic_link(INTEGER, VARCHAR, VARCHAR);
DROP FUNCTION IF EXISTS usp_sec_password_reset_token_consume(VARCHAR);
DROP FUNCTION IF EXISTS usp_sec_password_reset_token_create(VARCHAR, INTEGER, VARCHAR, VARCHAR, VARCHAR, INTEGER, VARCHAR);
DROP TABLE IF EXISTS sec."PasswordResetToken";

DROP FUNCTION IF EXISTS usp_sys_webhook_event_complete(VARCHAR, VARCHAR, INTEGER, TEXT);
DROP FUNCTION IF EXISTS usp_sys_webhook_event_dedup(VARCHAR, VARCHAR, VARCHAR, VARCHAR);
DROP TABLE IF EXISTS sys."WebhookEvent";
