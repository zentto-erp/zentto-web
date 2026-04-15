-- +goose Up

-- Sistema de webhooks por-tenant: cierra el loop del event bus para que
-- tenants clientes reciban eventos (crm.lead.created, hotel.reservation.*,
-- etc.) en su propio sistema sin pollear el API.
--
-- Flujo:
--   1. Admin del tenant registra webhook (URL + secret + filtro).
--   2. El consumer Kafka en zentto-web API (webhook-dispatcher.ts) recibe
--      cada evento del topic zentto.<tenant>.<event>.
--   3. Resuelve webhooks activos del tenant que matcheen el eventType.
--   4. POST al URL con header `X-Zentto-Signature: sha256=<hmac>` del body.
--   5. Registra la delivery en TenantWebhookDelivery para audit + retry.

-- +goose StatementBegin
CREATE TABLE IF NOT EXISTS cfg."TenantWebhook" (
  "WebhookId"      BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"      INTEGER NOT NULL REFERENCES cfg."Company"("CompanyId"),
  "Url"            VARCHAR(500) NOT NULL,
  "SecretHash"     VARCHAR(64)  NOT NULL,  -- SHA-256 del secret plain
  "Label"          VARCHAR(100) NOT NULL DEFAULT 'default',
  -- CSV con patterns tipo "crm.lead.*,hotel.reservation.confirmed".
  -- '*' suelto = todos los eventos del tenant.
  "EventFilter"    VARCHAR(1000) NOT NULL DEFAULT '*',
  "IsActive"       BOOLEAN NOT NULL DEFAULT TRUE,
  "ConsecutiveFailures" INTEGER NOT NULL DEFAULT 0,
  "DisabledReason" VARCHAR(500),
  "LastDeliveredAt" TIMESTAMP,
  "CreatedAt"      TIMESTAMP NOT NULL DEFAULT (now() AT TIME ZONE 'UTC'),
  "CreatedByUserId" INTEGER,
  "IsDeleted"      BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE INDEX IF NOT EXISTS "IX_cfg_TenantWebhook_Company_Active"
  ON cfg."TenantWebhook"("CompanyId") WHERE "IsActive" = TRUE AND "IsDeleted" = FALSE;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE TABLE IF NOT EXISTS cfg."TenantWebhookDelivery" (
  "DeliveryId"   BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "WebhookId"    BIGINT NOT NULL REFERENCES cfg."TenantWebhook"("WebhookId"),
  "EventId"      VARCHAR(80) NOT NULL,
  "EventType"    VARCHAR(100) NOT NULL,
  "Topic"        VARCHAR(200) NOT NULL,
  "Status"       VARCHAR(20) NOT NULL CHECK ("Status" IN ('pending','success','failed','dlq')),
  "HttpStatus"   INTEGER,
  "AttemptCount" INTEGER NOT NULL DEFAULT 0,
  "LastError"    VARCHAR(500),
  "PayloadSize"  INTEGER,
  "StartedAt"    TIMESTAMP NOT NULL DEFAULT (now() AT TIME ZONE 'UTC'),
  "CompletedAt"  TIMESTAMP
);

CREATE INDEX IF NOT EXISTS "IX_TWD_Webhook_Started"
  ON cfg."TenantWebhookDelivery"("WebhookId", "StartedAt" DESC);
CREATE INDEX IF NOT EXISTS "IX_TWD_Status"
  ON cfg."TenantWebhookDelivery"("Status") WHERE "Status" IN ('pending','dlq');
-- Dedup — mismo event/webhook no se entrega 2 veces.
CREATE UNIQUE INDEX IF NOT EXISTS "UQ_TWD_Webhook_Event"
  ON cfg."TenantWebhookDelivery"("WebhookId", "EventId");
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION cfg.usp_cfg_tenantwebhook_create(
  p_company_id    INTEGER,
  p_url           TEXT,
  p_label         TEXT DEFAULT 'default',
  p_event_filter  TEXT DEFAULT '*',
  p_user_id       INTEGER DEFAULT NULL,
  OUT p_webhook_id BIGINT,
  OUT p_secret    TEXT,
  OUT p_resultado INTEGER,
  OUT p_mensaje   VARCHAR
) RETURNS RECORD
LANGUAGE plpgsql AS $$
DECLARE
  v_secret TEXT;
BEGIN
  IF p_url IS NULL OR TRIM(p_url) = '' THEN
    p_resultado := 0; p_mensaje := 'URL requerida'::VARCHAR; RETURN;
  END IF;
  IF p_url !~ '^https?://' THEN
    p_resultado := 0; p_mensaje := 'URL debe empezar con http:// o https://'::VARCHAR; RETURN;
  END IF;

  v_secret := 'zws_' || ENCODE(gen_random_bytes(32), 'hex');

  INSERT INTO cfg."TenantWebhook" ("CompanyId","Url","SecretHash","Label","EventFilter","CreatedByUserId")
  VALUES (
    p_company_id,
    TRIM(p_url),
    ENCODE(DIGEST(v_secret, 'sha256'), 'hex'),
    COALESCE(NULLIF(TRIM(p_label), ''), 'default'),
    COALESCE(NULLIF(TRIM(p_event_filter), ''), '*'),
    p_user_id
  )
  RETURNING "WebhookId" INTO p_webhook_id;

  p_secret := v_secret;
  p_resultado := 1;
  p_mensaje := 'Webhook registrado'::VARCHAR;
EXCEPTION WHEN OTHERS THEN
  p_resultado := 0;
  p_mensaje := ('Error: ' || SQLERRM)::VARCHAR;
END;
$$;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION cfg.usp_cfg_tenantwebhook_list(
  p_company_id INTEGER
) RETURNS TABLE(
  "WebhookId"      BIGINT,
  "Url"            VARCHAR,
  "Label"          VARCHAR,
  "EventFilter"    VARCHAR,
  "IsActive"       BOOLEAN,
  "ConsecutiveFailures" INTEGER,
  "DisabledReason" VARCHAR,
  "LastDeliveredAt" TIMESTAMP,
  "CreatedAt"      TIMESTAMP
)
LANGUAGE plpgsql AS $$
BEGIN
  RETURN QUERY
  SELECT w."WebhookId", w."Url", w."Label", w."EventFilter",
         w."IsActive", w."ConsecutiveFailures", w."DisabledReason",
         w."LastDeliveredAt", w."CreatedAt"
  FROM cfg."TenantWebhook" w
  WHERE w."CompanyId" = p_company_id AND w."IsDeleted" = FALSE
  ORDER BY w."CreatedAt" DESC;
END;
$$;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION cfg.usp_cfg_tenantwebhook_revoke(
  p_webhook_id BIGINT,
  p_company_id INTEGER,
  OUT p_resultado INTEGER,
  OUT p_mensaje   VARCHAR
) RETURNS RECORD
LANGUAGE plpgsql AS $$
BEGIN
  UPDATE cfg."TenantWebhook"
  SET "IsActive" = FALSE, "IsDeleted" = TRUE
  WHERE "WebhookId" = p_webhook_id AND "CompanyId" = p_company_id AND "IsDeleted" = FALSE;

  IF NOT FOUND THEN
    p_resultado := 0; p_mensaje := 'Webhook no encontrado o ya revocado'::VARCHAR; RETURN;
  END IF;
  p_resultado := 1; p_mensaje := 'Webhook revocado'::VARCHAR;
END;
$$;
-- +goose StatementEnd

-- +goose StatementBegin
-- Resuelve webhooks activos que matcheen un eventType para un tenant.
-- Devuelve también el secret hash + url para que el consumer firme y POSTee.
CREATE OR REPLACE FUNCTION cfg.usp_cfg_tenantwebhook_resolve(
  p_company_id INTEGER,
  p_event_type TEXT
) RETURNS TABLE(
  "WebhookId"  BIGINT,
  "Url"        VARCHAR,
  "SecretHash" VARCHAR,
  "EventFilter" VARCHAR
)
LANGUAGE plpgsql AS $$
BEGIN
  RETURN QUERY
  SELECT w."WebhookId", w."Url", w."SecretHash", w."EventFilter"
  FROM cfg."TenantWebhook" w
  WHERE w."CompanyId" = p_company_id
    AND w."IsActive" = TRUE
    AND w."IsDeleted" = FALSE
    -- Match trivial: '*' solo = todo; si no, comparar prefijos/patterns via
    -- string_to_array + LIKE. Matching fino en la app (JS) por flexibilidad.
    AND (
      w."EventFilter" = '*'
      OR position('*' in w."EventFilter") > 0
      OR position(p_event_type in w."EventFilter") > 0
    );
END;
$$;
-- +goose StatementEnd

-- +goose StatementBegin
-- Registra una delivery (idempotente: UNIQUE (WebhookId, EventId)).
CREATE OR REPLACE FUNCTION cfg.usp_cfg_tenantwebhook_delivery_record(
  p_webhook_id BIGINT,
  p_event_id   TEXT,
  p_event_type TEXT,
  p_topic      TEXT,
  p_status     TEXT,
  p_http_status INTEGER,
  p_attempt_count INTEGER,
  p_last_error TEXT,
  p_payload_size INTEGER,
  OUT p_delivery_id BIGINT,
  OUT p_resultado   INTEGER,
  OUT p_mensaje     VARCHAR
) RETURNS RECORD
LANGUAGE plpgsql AS $$
BEGIN
  INSERT INTO cfg."TenantWebhookDelivery" (
    "WebhookId","EventId","EventType","Topic","Status","HttpStatus",
    "AttemptCount","LastError","PayloadSize","CompletedAt"
  ) VALUES (
    p_webhook_id, p_event_id, p_event_type, p_topic, p_status, p_http_status,
    COALESCE(p_attempt_count, 0),
    LEFT(COALESCE(p_last_error, ''), 500),
    p_payload_size,
    CASE WHEN p_status IN ('success','failed','dlq') THEN (now() AT TIME ZONE 'UTC') END
  )
  ON CONFLICT ("WebhookId", "EventId") DO UPDATE SET
    "Status" = EXCLUDED."Status",
    "HttpStatus" = EXCLUDED."HttpStatus",
    "AttemptCount" = EXCLUDED."AttemptCount",
    "LastError" = EXCLUDED."LastError",
    "CompletedAt" = EXCLUDED."CompletedAt"
  RETURNING "DeliveryId" INTO p_delivery_id;

  -- Actualizar stats del webhook
  IF p_status = 'success' THEN
    UPDATE cfg."TenantWebhook"
    SET "ConsecutiveFailures" = 0, "LastDeliveredAt" = (now() AT TIME ZONE 'UTC'), "DisabledReason" = NULL
    WHERE "WebhookId" = p_webhook_id;
  ELSIF p_status IN ('failed','dlq') THEN
    UPDATE cfg."TenantWebhook"
    SET "ConsecutiveFailures" = "ConsecutiveFailures" + 1,
        -- Autodesactivar tras 10 fallos consecutivos — evita spam a URL muerta.
        "IsActive" = CASE WHEN "ConsecutiveFailures" + 1 >= 10 THEN FALSE ELSE "IsActive" END,
        "DisabledReason" = CASE WHEN "ConsecutiveFailures" + 1 >= 10 THEN LEFT(p_last_error, 500) ELSE "DisabledReason" END
    WHERE "WebhookId" = p_webhook_id;
  END IF;

  p_resultado := 1;
  p_mensaje := 'Delivery registrada'::VARCHAR;
END;
$$;
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
DROP FUNCTION IF EXISTS cfg.usp_cfg_tenantwebhook_delivery_record(BIGINT, TEXT, TEXT, TEXT, TEXT, INTEGER, INTEGER, TEXT, INTEGER);
DROP FUNCTION IF EXISTS cfg.usp_cfg_tenantwebhook_resolve(INTEGER, TEXT);
DROP FUNCTION IF EXISTS cfg.usp_cfg_tenantwebhook_revoke(BIGINT, INTEGER);
DROP FUNCTION IF EXISTS cfg.usp_cfg_tenantwebhook_list(INTEGER);
DROP FUNCTION IF EXISTS cfg.usp_cfg_tenantwebhook_create(INTEGER, TEXT, TEXT, TEXT, INTEGER);
DROP TABLE IF EXISTS cfg."TenantWebhookDelivery";
DROP TABLE IF EXISTS cfg."TenantWebhook";
-- +goose StatementEnd
