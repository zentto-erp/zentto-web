-- +goose Up
-- Fix: "SubscriptionId" y "SubscriptionItemId" ambiguous en SPs de suscripción.
-- RETURNS TABLE define output columns con los mismos nombres que columnas de la tabla,
-- causando conflicto en RETURNING clause.
-- Solución: #variable_conflict use_column (preferir columna de tabla sobre output var).

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION usp_sys_subscription_create(
    p_company_id              INTEGER,
    p_source                  VARCHAR,
    p_paddle_subscription_id  VARCHAR,
    p_paddle_customer_id      VARCHAR,
    p_status                  VARCHAR,
    p_current_period_start    TIMESTAMP,
    p_current_period_end      TIMESTAMP,
    p_trial_ends_at           TIMESTAMP,
    p_tenant_subdomain        VARCHAR
)
RETURNS TABLE("ok" BOOLEAN, "mensaje" VARCHAR, "SubscriptionId" INTEGER)
LANGUAGE plpgsql AS $body$
#variable_conflict use_column
DECLARE
    v_sub_id INTEGER;
BEGIN
    INSERT INTO sys."Subscription" (
        "CompanyId", "Source",
        "PaddleSubscriptionId", "PaddleCustomerId",
        "Status", "CurrentPeriodStart", "CurrentPeriodEnd",
        "TrialEndsAt", "TenantSubdomain"
    ) VALUES (
        p_company_id, COALESCE(p_source,'paddle'),
        COALESCE(p_paddle_subscription_id,''), COALESCE(p_paddle_customer_id,''),
        COALESCE(p_status,'active'), p_current_period_start, p_current_period_end,
        p_trial_ends_at, COALESCE(p_tenant_subdomain,'')
    )
    RETURNING "SubscriptionId" INTO v_sub_id;

    RETURN QUERY SELECT TRUE, 'Suscripción creada'::VARCHAR, v_sub_id;
END;
$body$;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION usp_sys_subscription_item_add(
    p_subscription_id           INTEGER,
    p_company_id                INTEGER,
    p_pricing_plan_id           INTEGER,
    p_quantity                  INTEGER,
    p_paddle_subscription_item_id VARCHAR,
    p_paddle_price_id           VARCHAR,
    p_unit_price                NUMERIC,
    p_billing_cycle             VARCHAR
)
RETURNS TABLE("ok" BOOLEAN, "mensaje" VARCHAR, "SubscriptionItemId" INTEGER)
LANGUAGE plpgsql AS $body$
#variable_conflict use_column
DECLARE
    v_item_id INTEGER;
BEGIN
    INSERT INTO sys."SubscriptionItem" (
        "SubscriptionId", "CompanyId", "PricingPlanId", "Quantity",
        "PaddleSubscriptionItemId", "PaddlePriceId",
        "UnitPrice", "BillingCycle", "Status", "AddedAt"
    ) VALUES (
        p_subscription_id, p_company_id, p_pricing_plan_id, COALESCE(p_quantity,1),
        COALESCE(p_paddle_subscription_item_id,''), COALESCE(p_paddle_price_id,''),
        COALESCE(p_unit_price,0), COALESCE(p_billing_cycle,'monthly'),
        'active', NOW()
    )
    RETURNING "SubscriptionItemId" INTO v_item_id;

    RETURN QUERY SELECT TRUE, 'Item añadido'::VARCHAR, v_item_id;
END;
$body$;
-- +goose StatementEnd


-- +goose Down
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION usp_sys_subscription_create(
    p_company_id              INTEGER,
    p_source                  VARCHAR,
    p_paddle_subscription_id  VARCHAR,
    p_paddle_customer_id      VARCHAR,
    p_status                  VARCHAR,
    p_current_period_start    TIMESTAMP,
    p_current_period_end      TIMESTAMP,
    p_trial_ends_at           TIMESTAMP,
    p_tenant_subdomain        VARCHAR
)
RETURNS TABLE("ok" BOOLEAN, "mensaje" VARCHAR, "SubscriptionId" INTEGER)
LANGUAGE plpgsql AS $$
DECLARE
    v_sub_id INTEGER;
BEGIN
    INSERT INTO sys."Subscription" (
        "CompanyId", "Source",
        "PaddleSubscriptionId", "PaddleCustomerId",
        "Status", "CurrentPeriodStart", "CurrentPeriodEnd",
        "TrialEndsAt", "TenantSubdomain"
    ) VALUES (
        p_company_id, COALESCE(p_source,'paddle'),
        COALESCE(p_paddle_subscription_id,''), COALESCE(p_paddle_customer_id,''),
        COALESCE(p_status,'active'), p_current_period_start, p_current_period_end,
        p_trial_ends_at, COALESCE(p_tenant_subdomain,'')
    )
    RETURNING "SubscriptionId" INTO v_sub_id;

    RETURN QUERY SELECT TRUE, 'Suscripción creada'::VARCHAR, v_sub_id;
END;
$$;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION usp_sys_subscription_item_add(
    p_subscription_id           INTEGER,
    p_company_id                INTEGER,
    p_pricing_plan_id           INTEGER,
    p_quantity                  INTEGER,
    p_paddle_subscription_item_id VARCHAR,
    p_paddle_price_id           VARCHAR,
    p_unit_price                NUMERIC,
    p_billing_cycle             VARCHAR
)
RETURNS TABLE("ok" BOOLEAN, "mensaje" VARCHAR, "SubscriptionItemId" INTEGER)
LANGUAGE plpgsql AS $$
DECLARE
    v_item_id INTEGER;
BEGIN
    INSERT INTO sys."SubscriptionItem" (
        "SubscriptionId", "CompanyId", "PricingPlanId", "Quantity",
        "PaddleSubscriptionItemId", "PaddlePriceId",
        "UnitPrice", "BillingCycle", "Status", "AddedAt"
    ) VALUES (
        p_subscription_id, p_company_id, p_pricing_plan_id, COALESCE(p_quantity,1),
        COALESCE(p_paddle_subscription_item_id,''), COALESCE(p_paddle_price_id,''),
        COALESCE(p_unit_price,0), COALESCE(p_billing_cycle,'monthly'),
        'active', NOW()
    )
    RETURNING "SubscriptionItemId" INTO v_item_id;

    RETURN QUERY SELECT TRUE, 'Item añadido'::VARCHAR, v_item_id;
END;
$$;
-- +goose StatementEnd
