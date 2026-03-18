-- ============================================================
-- Tablas y funciones de Billing/Subscription (SaaS via Paddle)
-- Schema: sys
-- ============================================================

-- ── Tabla sys.BillingEvent ──
CREATE TABLE IF NOT EXISTS sys."BillingEvent" (
  "BillingEventId"    INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"         INT NULL,
  "EventType"         VARCHAR(80) NOT NULL,
  "PaddleEventId"     VARCHAR(100) NULL,
  "Payload"           TEXT NULL,
  "CreatedAt"         TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC')
);

CREATE INDEX IF NOT EXISTS idx_billing_event_company
  ON sys."BillingEvent" ("CompanyId", "CreatedAt");

-- ── Tabla sys.Subscription ──
CREATE TABLE IF NOT EXISTS sys."Subscription" (
  "SubscriptionId"        INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"             INT NULL,
  "PaddleSubscriptionId"  VARCHAR(100) NOT NULL UNIQUE,
  "PaddleCustomerId"      VARCHAR(100) NULL,
  "PriceId"               VARCHAR(100) NULL,
  "PlanName"              VARCHAR(100) NULL,
  "Status"                VARCHAR(30)  NOT NULL DEFAULT 'active',
  "CurrentPeriodStart"    TIMESTAMP NULL,
  "CurrentPeriodEnd"      TIMESTAMP NULL,
  "CancelledAt"           TIMESTAMP NULL,
  "TenantSubdomain"       VARCHAR(63) NULL,
  "CreatedAt"             TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"             TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC')
);

CREATE INDEX IF NOT EXISTS idx_subscription_company
  ON sys."Subscription" ("CompanyId");

-- ============================================================
-- usp_sys_BillingEvent_Insert
-- Registra un evento de billing en la tabla de auditoria
-- ============================================================
DROP FUNCTION IF EXISTS usp_sys_BillingEvent_Insert(INT, VARCHAR, VARCHAR, TEXT) CASCADE;
CREATE OR REPLACE FUNCTION usp_sys_BillingEvent_Insert(
  p_company_id       INT           DEFAULT NULL,
  p_event_type       VARCHAR(80)   DEFAULT '',
  p_paddle_event_id  VARCHAR(100)  DEFAULT NULL,
  p_payload          TEXT          DEFAULT NULL
)
RETURNS TABLE("ok" BOOLEAN, "mensaje" VARCHAR)
LANGUAGE plpgsql AS $$
DECLARE
  v_id INT;
BEGIN
  INSERT INTO sys."BillingEvent" (
    "CompanyId", "EventType", "PaddleEventId", "Payload"
  ) VALUES (
    p_company_id, p_event_type, p_paddle_event_id, p_payload
  ) RETURNING "BillingEventId" INTO v_id;

  RETURN QUERY SELECT TRUE, ('BILLING_EVENT_INSERTED:' || v_id)::VARCHAR;
END;
$$;

-- ============================================================
-- usp_sys_Subscription_Upsert
-- Crea o actualiza una suscripcion de Paddle
-- ============================================================
DROP FUNCTION IF EXISTS usp_sys_Subscription_Upsert(
  INT, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR
) CASCADE;
CREATE OR REPLACE FUNCTION usp_sys_Subscription_Upsert(
  p_company_id              INT           DEFAULT NULL,
  p_paddle_subscription_id  VARCHAR(100)  DEFAULT NULL,
  p_paddle_customer_id      VARCHAR(100)  DEFAULT NULL,
  p_price_id                VARCHAR(100)  DEFAULT NULL,
  p_plan_name               VARCHAR(100)  DEFAULT NULL,
  p_status                  VARCHAR(30)   DEFAULT 'active',
  p_current_period_start    VARCHAR       DEFAULT NULL,
  p_current_period_end      VARCHAR       DEFAULT NULL,
  p_cancelled_at            VARCHAR       DEFAULT NULL
)
RETURNS TABLE("ok" BOOLEAN, "mensaje" VARCHAR)
LANGUAGE plpgsql AS $$
BEGIN
  IF p_paddle_subscription_id IS NULL THEN
    RETURN QUERY SELECT FALSE, 'PADDLE_SUBSCRIPTION_ID_REQUIRED'::VARCHAR;
    RETURN;
  END IF;

  INSERT INTO sys."Subscription" (
    "CompanyId", "PaddleSubscriptionId", "PaddleCustomerId",
    "PriceId", "PlanName", "Status",
    "CurrentPeriodStart", "CurrentPeriodEnd", "CancelledAt",
    "UpdatedAt"
  ) VALUES (
    p_company_id,
    p_paddle_subscription_id,
    p_paddle_customer_id,
    p_price_id,
    p_plan_name,
    COALESCE(p_status, 'active'),
    CASE WHEN p_current_period_start IS NOT NULL
         THEN p_current_period_start::TIMESTAMP ELSE NULL END,
    CASE WHEN p_current_period_end IS NOT NULL
         THEN p_current_period_end::TIMESTAMP ELSE NULL END,
    CASE WHEN p_cancelled_at IS NOT NULL
         THEN p_cancelled_at::TIMESTAMP ELSE NULL END,
    NOW() AT TIME ZONE 'UTC'
  )
  ON CONFLICT ("PaddleSubscriptionId") DO UPDATE SET
    "PriceId"             = COALESCE(EXCLUDED."PriceId", sys."Subscription"."PriceId"),
    "PlanName"            = COALESCE(EXCLUDED."PlanName", sys."Subscription"."PlanName"),
    "Status"              = COALESCE(EXCLUDED."Status", sys."Subscription"."Status"),
    "CurrentPeriodStart"  = COALESCE(EXCLUDED."CurrentPeriodStart", sys."Subscription"."CurrentPeriodStart"),
    "CurrentPeriodEnd"    = COALESCE(EXCLUDED."CurrentPeriodEnd", sys."Subscription"."CurrentPeriodEnd"),
    "CancelledAt"         = COALESCE(EXCLUDED."CancelledAt", sys."Subscription"."CancelledAt"),
    "CompanyId"           = COALESCE(EXCLUDED."CompanyId", sys."Subscription"."CompanyId"),
    "PaddleCustomerId"    = COALESCE(EXCLUDED."PaddleCustomerId", sys."Subscription"."PaddleCustomerId"),
    "UpdatedAt"           = NOW() AT TIME ZONE 'UTC';

  RETURN QUERY SELECT TRUE, 'SUBSCRIPTION_UPSERTED'::VARCHAR;
END;
$$;

-- ============================================================
-- usp_sys_Subscription_GetByCompany
-- Obtiene la suscripcion activa de una empresa
-- ============================================================
DROP FUNCTION IF EXISTS usp_sys_Subscription_GetByCompany(INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_sys_Subscription_GetByCompany(
  p_company_id INT DEFAULT NULL
)
RETURNS TABLE(
  "SubscriptionId"        INT,
  "CompanyId"             INT,
  "PaddleSubscriptionId"  VARCHAR,
  "PaddleCustomerId"      VARCHAR,
  "PriceId"               VARCHAR,
  "PlanName"              VARCHAR,
  "Status"                VARCHAR,
  "CurrentPeriodStart"    TIMESTAMP,
  "CurrentPeriodEnd"      TIMESTAMP,
  "CancelledAt"           TIMESTAMP,
  "TenantSubdomain"       VARCHAR,
  "CreatedAt"             TIMESTAMP
)
LANGUAGE plpgsql AS $$
BEGIN
  RETURN QUERY
  SELECT
    s."SubscriptionId", s."CompanyId",
    s."PaddleSubscriptionId"::VARCHAR, s."PaddleCustomerId"::VARCHAR,
    s."PriceId"::VARCHAR, s."PlanName"::VARCHAR, s."Status"::VARCHAR,
    s."CurrentPeriodStart", s."CurrentPeriodEnd",
    s."CancelledAt", s."TenantSubdomain"::VARCHAR, s."CreatedAt"
  FROM sys."Subscription" s
  WHERE s."CompanyId" = p_company_id
  ORDER BY s."CreatedAt" DESC
  LIMIT 1;
END;
$$;
