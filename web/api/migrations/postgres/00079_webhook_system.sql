-- +goose Up
-- Webhook system: endpoints + deliveries + CRUD SPs

-- ═══════════════════════════════════════════════════════════════════════════════
-- Schema: platform (webhooks vive en el schema de plataforma)
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE SCHEMA IF NOT EXISTS platform;

-- ═══════════════════════════════════════════════════════════════════════════════
-- Tabla: platform."WebhookEndpoint"
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS platform."WebhookEndpoint" (
    "WebhookEndpointId"  BIGSERIAL       PRIMARY KEY,
    "CompanyId"          INT             NOT NULL,
    "Url"                VARCHAR(2048)   NOT NULL,
    "Secret"             VARCHAR(512)    NOT NULL,
    "Events"             TEXT[]          NOT NULL DEFAULT '{}',
    "Description"        VARCHAR(500)    NULL,
    "IsActive"           BOOLEAN         NOT NULL DEFAULT TRUE,
    "CreatedAtUtc"       TIMESTAMPTZ     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "UpdatedAtUtc"       TIMESTAMPTZ     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC')
);

CREATE INDEX IF NOT EXISTS "IX_WebhookEndpoint_CompanyId"
    ON platform."WebhookEndpoint" ("CompanyId");

CREATE INDEX IF NOT EXISTS "IX_WebhookEndpoint_CompanyId_Active"
    ON platform."WebhookEndpoint" ("CompanyId") WHERE "IsActive" = TRUE;

-- ═══════════════════════════════════════════════════════════════════════════════
-- Tabla: platform."WebhookDelivery"
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS platform."WebhookDelivery" (
    "WebhookDeliveryId"   BIGSERIAL       PRIMARY KEY,
    "WebhookEndpointId"   BIGINT          NOT NULL REFERENCES platform."WebhookEndpoint"("WebhookEndpointId") ON DELETE CASCADE,
    "EventType"           VARCHAR(100)    NOT NULL,
    "Payload"             JSONB           NOT NULL DEFAULT '{}',
    "Status"              VARCHAR(20)     NOT NULL DEFAULT 'pending',
    "ResponseCode"        INT             NULL,
    "ResponseBody"        TEXT            NULL,
    "Attempts"            INT             NOT NULL DEFAULT 0,
    "MaxAttempts"         INT             NOT NULL DEFAULT 5,
    "NextRetryAtUtc"      TIMESTAMPTZ     NULL,
    "CreatedAtUtc"        TIMESTAMPTZ     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "CompletedAtUtc"      TIMESTAMPTZ     NULL,
    CONSTRAINT "CK_WebhookDelivery_Status" CHECK ("Status" IN ('pending', 'success', 'failed'))
);

CREATE INDEX IF NOT EXISTS "IX_WebhookDelivery_EndpointId"
    ON platform."WebhookDelivery" ("WebhookEndpointId");

CREATE INDEX IF NOT EXISTS "IX_WebhookDelivery_Pending"
    ON platform."WebhookDelivery" ("Status", "NextRetryAtUtc")
    WHERE "Status" = 'pending';

-- ═══════════════════════════════════════════════════════════════════════════════
-- SP: usp_Platform_WebhookEndpoint_Create
-- ═══════════════════════════════════════════════════════════════════════════════

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_platform_webhookendpoint_create(
    p_company_id   INT,
    p_url          VARCHAR,
    p_secret       VARCHAR,
    p_events       TEXT[],
    p_description  VARCHAR DEFAULT NULL
) RETURNS TABLE(
    "ok"      BOOLEAN,
    "mensaje" VARCHAR,
    "WebhookEndpointId" BIGINT
)
LANGUAGE plpgsql AS $$
DECLARE
    v_id BIGINT;
BEGIN
    INSERT INTO platform."WebhookEndpoint" (
        "CompanyId", "Url", "Secret", "Events", "Description",
        "IsActive", "CreatedAtUtc", "UpdatedAtUtc"
    ) VALUES (
        p_company_id, p_url, p_secret, p_events, p_description,
        TRUE, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'
    )
    RETURNING "WebhookEndpointId" INTO v_id;

    RETURN QUERY SELECT TRUE, 'Webhook creado'::VARCHAR, v_id;
END;
$$;

-- ═══════════════════════════════════════════════════════════════════════════════
-- SP: usp_Platform_WebhookEndpoint_List
-- ═══════════════════════════════════════════════════════════════════════════════

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_platform_webhookendpoint_list(
    p_company_id INT
) RETURNS TABLE(
    "WebhookEndpointId"  BIGINT,
    "CompanyId"          INT,
    "Url"                VARCHAR,
    "Events"             TEXT[],
    "Description"        VARCHAR,
    "IsActive"           BOOLEAN,
    "CreatedAtUtc"       TIMESTAMPTZ,
    "UpdatedAtUtc"       TIMESTAMPTZ
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        e."WebhookEndpointId",
        e."CompanyId",
        e."Url"::VARCHAR,
        e."Events",
        e."Description"::VARCHAR,
        e."IsActive",
        e."CreatedAtUtc",
        e."UpdatedAtUtc"
    FROM platform."WebhookEndpoint" e
    WHERE e."CompanyId" = p_company_id
    ORDER BY e."CreatedAtUtc" DESC;
END;
$$;

-- ═══════════════════════════════════════════════════════════════════════════════
-- SP: usp_Platform_WebhookEndpoint_GetById
-- ═══════════════════════════════════════════════════════════════════════════════

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_platform_webhookendpoint_getbyid(
    p_company_id          INT,
    p_webhook_endpoint_id BIGINT
) RETURNS TABLE(
    "WebhookEndpointId"  BIGINT,
    "CompanyId"          INT,
    "Url"                VARCHAR,
    "Secret"             VARCHAR,
    "Events"             TEXT[],
    "Description"        VARCHAR,
    "IsActive"           BOOLEAN,
    "CreatedAtUtc"       TIMESTAMPTZ,
    "UpdatedAtUtc"       TIMESTAMPTZ
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        e."WebhookEndpointId",
        e."CompanyId",
        e."Url"::VARCHAR,
        e."Secret"::VARCHAR,
        e."Events",
        e."Description"::VARCHAR,
        e."IsActive",
        e."CreatedAtUtc",
        e."UpdatedAtUtc"
    FROM platform."WebhookEndpoint" e
    WHERE e."WebhookEndpointId" = p_webhook_endpoint_id
      AND e."CompanyId" = p_company_id;
END;
$$;

-- ═══════════════════════════════════════════════════════════════════════════════
-- SP: usp_Platform_WebhookEndpoint_Update
-- ═══════════════════════════════════════════════════════════════════════════════

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_platform_webhookendpoint_update(
    p_company_id          INT,
    p_webhook_endpoint_id BIGINT,
    p_url                 VARCHAR DEFAULT NULL,
    p_secret              VARCHAR DEFAULT NULL,
    p_events              TEXT[]  DEFAULT NULL,
    p_description         VARCHAR DEFAULT NULL,
    p_is_active           BOOLEAN DEFAULT NULL
) RETURNS TABLE(
    "ok"      BOOLEAN,
    "mensaje" VARCHAR
)
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE platform."WebhookEndpoint"
    SET
        "Url"         = COALESCE(p_url, "Url"),
        "Secret"      = COALESCE(p_secret, "Secret"),
        "Events"      = COALESCE(p_events, "Events"),
        "Description" = COALESCE(p_description, "Description"),
        "IsActive"    = COALESCE(p_is_active, "IsActive"),
        "UpdatedAtUtc" = NOW() AT TIME ZONE 'UTC'
    WHERE "WebhookEndpointId" = p_webhook_endpoint_id
      AND "CompanyId" = p_company_id;

    IF NOT FOUND THEN
        RETURN QUERY SELECT FALSE, 'Webhook no encontrado'::VARCHAR;
        RETURN;
    END IF;

    RETURN QUERY SELECT TRUE, 'Webhook actualizado'::VARCHAR;
END;
$$;

-- ═══════════════════════════════════════════════════════════════════════════════
-- SP: usp_Platform_WebhookEndpoint_Delete
-- ═══════════════════════════════════════════════════════════════════════════════

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_platform_webhookendpoint_delete(
    p_company_id          INT,
    p_webhook_endpoint_id BIGINT
) RETURNS TABLE(
    "ok"      BOOLEAN,
    "mensaje" VARCHAR
)
LANGUAGE plpgsql AS $$
BEGIN
    DELETE FROM platform."WebhookEndpoint"
    WHERE "WebhookEndpointId" = p_webhook_endpoint_id
      AND "CompanyId" = p_company_id;

    IF NOT FOUND THEN
        RETURN QUERY SELECT FALSE, 'Webhook no encontrado'::VARCHAR;
        RETURN;
    END IF;

    RETURN QUERY SELECT TRUE, 'Webhook eliminado'::VARCHAR;
END;
$$;

-- ═══════════════════════════════════════════════════════════════════════════════
-- SP: usp_Platform_WebhookEndpoint_ListByEvent
-- Busca endpoints activos suscritos a un event type para un tenant
-- ═══════════════════════════════════════════════════════════════════════════════

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_platform_webhookendpoint_listbyevent(
    p_company_id  INT,
    p_event_type  VARCHAR
) RETURNS TABLE(
    "WebhookEndpointId"  BIGINT,
    "Url"                VARCHAR,
    "Secret"             VARCHAR
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        e."WebhookEndpointId",
        e."Url"::VARCHAR,
        e."Secret"::VARCHAR
    FROM platform."WebhookEndpoint" e
    WHERE e."CompanyId" = p_company_id
      AND e."IsActive" = TRUE
      AND (p_event_type = ANY(e."Events") OR '*' = ANY(e."Events"));
END;
$$;

-- ═══════════════════════════════════════════════════════════════════════════════
-- SP: usp_Platform_WebhookDelivery_Create
-- ═══════════════════════════════════════════════════════════════════════════════

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_platform_webhookdelivery_create(
    p_webhook_endpoint_id BIGINT,
    p_event_type          VARCHAR,
    p_payload             JSONB
) RETURNS TABLE(
    "WebhookDeliveryId" BIGINT
)
LANGUAGE plpgsql AS $$
DECLARE
    v_id BIGINT;
BEGIN
    INSERT INTO platform."WebhookDelivery" (
        "WebhookEndpointId", "EventType", "Payload",
        "Status", "Attempts", "MaxAttempts",
        "NextRetryAtUtc", "CreatedAtUtc"
    ) VALUES (
        p_webhook_endpoint_id, p_event_type, p_payload,
        'pending', 0, 5,
        NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'
    )
    RETURNING "WebhookDeliveryId" INTO v_id;

    RETURN QUERY SELECT v_id;
END;
$$;

-- ═══════════════════════════════════════════════════════════════════════════════
-- SP: usp_Platform_WebhookDelivery_UpdateStatus
-- ═══════════════════════════════════════════════════════════════════════════════

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_platform_webhookdelivery_updatestatus(
    p_webhook_delivery_id BIGINT,
    p_status              VARCHAR,
    p_response_code       INT DEFAULT NULL,
    p_response_body       TEXT DEFAULT NULL,
    p_next_retry_at_utc   TIMESTAMPTZ DEFAULT NULL
) RETURNS TABLE(
    "ok" BOOLEAN,
    "mensaje" VARCHAR
)
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE platform."WebhookDelivery"
    SET
        "Status"        = p_status,
        "ResponseCode"  = p_response_code,
        "ResponseBody"  = LEFT(p_response_body, 4000),
        "Attempts"      = "Attempts" + 1,
        "NextRetryAtUtc" = p_next_retry_at_utc,
        "CompletedAtUtc" = CASE WHEN p_status IN ('success', 'failed') AND p_next_retry_at_utc IS NULL
                                THEN NOW() AT TIME ZONE 'UTC'
                                ELSE "CompletedAtUtc" END
    WHERE "WebhookDeliveryId" = p_webhook_delivery_id;

    IF NOT FOUND THEN
        RETURN QUERY SELECT FALSE, 'Delivery no encontrado'::VARCHAR;
        RETURN;
    END IF;

    RETURN QUERY SELECT TRUE, 'Delivery actualizado'::VARCHAR;
END;
$$;

-- ═══════════════════════════════════════════════════════════════════════════════
-- SP: usp_Platform_WebhookDelivery_ListByEndpoint
-- ═══════════════════════════════════════════════════════════════════════════════

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_platform_webhookdelivery_listbyendpoint(
    p_company_id          INT,
    p_webhook_endpoint_id BIGINT,
    p_page_number         INT DEFAULT 1,
    p_page_size           INT DEFAULT 50
) RETURNS TABLE(
    "WebhookDeliveryId"   BIGINT,
    "WebhookEndpointId"   BIGINT,
    "EventType"           VARCHAR,
    "Payload"             JSONB,
    "Status"              VARCHAR,
    "ResponseCode"        INT,
    "Attempts"            INT,
    "MaxAttempts"         INT,
    "NextRetryAtUtc"      TIMESTAMPTZ,
    "CreatedAtUtc"        TIMESTAMPTZ,
    "CompletedAtUtc"      TIMESTAMPTZ,
    "TotalCount"          BIGINT
)
LANGUAGE plpgsql AS $$
DECLARE
    v_total BIGINT;
    v_offset INT;
BEGIN
    v_offset := (p_page_number - 1) * p_page_size;

    SELECT COUNT(*) INTO v_total
    FROM platform."WebhookDelivery" d
    JOIN platform."WebhookEndpoint" e ON e."WebhookEndpointId" = d."WebhookEndpointId"
    WHERE d."WebhookEndpointId" = p_webhook_endpoint_id
      AND e."CompanyId" = p_company_id;

    RETURN QUERY
    SELECT
        d."WebhookDeliveryId",
        d."WebhookEndpointId",
        d."EventType"::VARCHAR,
        d."Payload",
        d."Status"::VARCHAR,
        d."ResponseCode",
        d."Attempts",
        d."MaxAttempts",
        d."NextRetryAtUtc",
        d."CreatedAtUtc",
        d."CompletedAtUtc",
        v_total
    FROM platform."WebhookDelivery" d
    JOIN platform."WebhookEndpoint" e ON e."WebhookEndpointId" = d."WebhookEndpointId"
    WHERE d."WebhookEndpointId" = p_webhook_endpoint_id
      AND e."CompanyId" = p_company_id
    ORDER BY d."CreatedAtUtc" DESC
    LIMIT p_page_size OFFSET v_offset;
END;
$$;

-- ═══════════════════════════════════════════════════════════════════════════════
-- SP: usp_Platform_WebhookDelivery_ListPendingRetries
-- Para el job de retry: busca deliveries pendientes cuyo next_retry ya pasó
-- ═══════════════════════════════════════════════════════════════════════════════

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_platform_webhookdelivery_listpendingretries(
    p_limit INT DEFAULT 100
) RETURNS TABLE(
    "WebhookDeliveryId"   BIGINT,
    "WebhookEndpointId"   BIGINT,
    "Url"                 VARCHAR,
    "Secret"              VARCHAR,
    "EventType"           VARCHAR,
    "Payload"             JSONB,
    "Attempts"            INT,
    "MaxAttempts"         INT
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        d."WebhookDeliveryId",
        d."WebhookEndpointId",
        e."Url"::VARCHAR,
        e."Secret"::VARCHAR,
        d."EventType"::VARCHAR,
        d."Payload",
        d."Attempts",
        d."MaxAttempts"
    FROM platform."WebhookDelivery" d
    JOIN platform."WebhookEndpoint" e ON e."WebhookEndpointId" = d."WebhookEndpointId"
    WHERE d."Status" = 'pending'
      AND e."IsActive" = TRUE
      AND d."Attempts" < d."MaxAttempts"
      AND d."NextRetryAtUtc" <= NOW() AT TIME ZONE 'UTC'
    ORDER BY d."NextRetryAtUtc" ASC
    LIMIT p_limit;
END;
$$;

-- +goose Down

DROP FUNCTION IF EXISTS public.usp_platform_webhookdelivery_listpendingretries(INT);
DROP FUNCTION IF EXISTS public.usp_platform_webhookdelivery_listbyendpoint(INT, BIGINT, INT, INT);
DROP FUNCTION IF EXISTS public.usp_platform_webhookdelivery_updatestatus(BIGINT, VARCHAR, INT, TEXT, TIMESTAMPTZ);
DROP FUNCTION IF EXISTS public.usp_platform_webhookdelivery_create(BIGINT, VARCHAR, JSONB);
DROP FUNCTION IF EXISTS public.usp_platform_webhookendpoint_listbyevent(INT, VARCHAR);
DROP FUNCTION IF EXISTS public.usp_platform_webhookendpoint_delete(INT, BIGINT);
DROP FUNCTION IF EXISTS public.usp_platform_webhookendpoint_update(INT, BIGINT, VARCHAR, VARCHAR, TEXT[], VARCHAR, BOOLEAN);
DROP FUNCTION IF EXISTS public.usp_platform_webhookendpoint_getbyid(INT, BIGINT);
DROP FUNCTION IF EXISTS public.usp_platform_webhookendpoint_list(INT);
DROP FUNCTION IF EXISTS public.usp_platform_webhookendpoint_create(INT, VARCHAR, VARCHAR, TEXT[], VARCHAR);
DROP TABLE IF EXISTS platform."WebhookDelivery";
DROP TABLE IF EXISTS platform."WebhookEndpoint";
