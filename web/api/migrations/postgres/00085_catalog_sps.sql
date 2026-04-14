-- +goose Up
-- ══════════════════════════════════════════════════════════════════════════════
-- SPs del catálogo unificado y suscripciones multi-item
-- Complementa migración 00084. Todos devuelven VARCHAR (no TEXT) en columnas
-- string para compatibilidad con pg driver de la API (regla PG varchar cast).
-- ══════════════════════════════════════════════════════════════════════════════

-- ──────────────────────────────────────────────────────────────────────────────
-- CATÁLOGO — lectura pública
-- ──────────────────────────────────────────────────────────────────────────────

-- usp_cfg_catalog_list: planes activos filtrados por vertical o producto
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION usp_cfg_catalog_list(
    p_vertical_type VARCHAR DEFAULT NULL,
    p_product_code  VARCHAR DEFAULT NULL,
    p_include_trial BOOLEAN DEFAULT TRUE
)
RETURNS TABLE(
    "PricingPlanId"        INTEGER,
    "Name"                 VARCHAR,
    "Slug"                 VARCHAR,
    "VerticalType"         VARCHAR,
    "ProductCode"          VARCHAR,
    "Description"          TEXT,
    "MonthlyPrice"         NUMERIC,
    "AnnualPrice"          NUMERIC,
    "BillingCycleDefault"  VARCHAR,
    "MaxUsers"             INTEGER,
    "MaxTransactions"      INTEGER,
    "Features"             JSONB,
    "ModuleCodes"          JSONB,
    "Limits"               JSONB,
    "IsAddon"              BOOLEAN,
    "IsTrialOnly"          BOOLEAN,
    "TrialDays"            INTEGER,
    "SortOrder"            INTEGER,
    "PaddlePriceIdMonthly" VARCHAR,
    "PaddlePriceIdAnnual"  VARCHAR,
    "PaddleSyncStatus"     VARCHAR,
    "IsActive"             BOOLEAN
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        p."PricingPlanId",
        p."Name"::VARCHAR,
        p."Slug"::VARCHAR,
        p."VerticalType"::VARCHAR,
        p."ProductCode"::VARCHAR,
        p."Description",
        p."MonthlyPrice",
        p."AnnualPrice",
        p."BillingCycleDefault"::VARCHAR,
        p."MaxUsers",
        p."MaxTransactions",
        p."Features",
        p."ModuleCodes",
        p."Limits",
        p."IsAddon",
        p."IsTrialOnly",
        p."TrialDays",
        p."SortOrder",
        p."PaddlePriceIdMonthly"::VARCHAR,
        p."PaddlePriceIdAnnual"::VARCHAR,
        p."PaddleSyncStatus"::VARCHAR,
        p."IsActive"
    FROM cfg."PricingPlan" p
    WHERE p."IsActive" = TRUE
      AND (p_vertical_type IS NULL OR p."VerticalType" = p_vertical_type)
      AND (p_product_code  IS NULL OR p."ProductCode"  = p_product_code)
      AND (p_include_trial OR p."IsTrialOnly" = FALSE)
    ORDER BY p."ProductCode", p."SortOrder", p."MonthlyPrice" ASC;
END;
$$;
-- +goose StatementEnd

-- usp_cfg_plan_get_by_slug: detalle de un plan por slug
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION usp_cfg_plan_get_by_slug(
    p_slug VARCHAR
)
RETURNS TABLE(
    "PricingPlanId"        INTEGER,
    "Name"                 VARCHAR,
    "Slug"                 VARCHAR,
    "VerticalType"         VARCHAR,
    "ProductCode"          VARCHAR,
    "Description"          TEXT,
    "MonthlyPrice"         NUMERIC,
    "AnnualPrice"          NUMERIC,
    "BillingCycleDefault"  VARCHAR,
    "MaxUsers"             INTEGER,
    "MaxTransactions"      INTEGER,
    "Features"             JSONB,
    "ModuleCodes"          JSONB,
    "Limits"               JSONB,
    "IsAddon"              BOOLEAN,
    "IsTrialOnly"          BOOLEAN,
    "TrialDays"            INTEGER,
    "PaddleProductId"      VARCHAR,
    "PaddlePriceIdMonthly" VARCHAR,
    "PaddlePriceIdAnnual"  VARCHAR,
    "PaddleSyncStatus"     VARCHAR,
    "IsActive"             BOOLEAN
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        p."PricingPlanId",
        p."Name"::VARCHAR, p."Slug"::VARCHAR,
        p."VerticalType"::VARCHAR, p."ProductCode"::VARCHAR,
        p."Description",
        p."MonthlyPrice", p."AnnualPrice",
        p."BillingCycleDefault"::VARCHAR,
        p."MaxUsers", p."MaxTransactions",
        p."Features", p."ModuleCodes", p."Limits",
        p."IsAddon", p."IsTrialOnly", p."TrialDays",
        p."PaddleProductId"::VARCHAR,
        p."PaddlePriceIdMonthly"::VARCHAR,
        p."PaddlePriceIdAnnual"::VARCHAR,
        p."PaddleSyncStatus"::VARCHAR,
        p."IsActive"
    FROM cfg."PricingPlan" p
    WHERE p."Slug" = p_slug;
END;
$$;
-- +goose StatementEnd

-- usp_cfg_plan_get_by_paddle_price_id: lookup desde webhook Paddle
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION usp_cfg_plan_get_by_paddle_price_id(
    p_paddle_price_id VARCHAR
)
RETURNS TABLE(
    "PricingPlanId" INTEGER,
    "Slug"          VARCHAR,
    "ProductCode"   VARCHAR,
    "VerticalType"  VARCHAR,
    "IsAddon"       BOOLEAN,
    "BillingCycle"  VARCHAR,
    "ModuleCodes"   JSONB,
    "Limits"        JSONB,
    "MonthlyPrice"  NUMERIC,
    "AnnualPrice"   NUMERIC
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        p."PricingPlanId",
        p."Slug"::VARCHAR,
        p."ProductCode"::VARCHAR,
        p."VerticalType"::VARCHAR,
        p."IsAddon",
        (CASE
            WHEN p."PaddlePriceIdMonthly" = p_paddle_price_id THEN 'monthly'
            WHEN p."PaddlePriceIdAnnual"  = p_paddle_price_id THEN 'annual'
            ELSE 'monthly'
         END)::VARCHAR,
        p."ModuleCodes",
        p."Limits",
        p."MonthlyPrice",
        p."AnnualPrice"
    FROM cfg."PricingPlan" p
    WHERE p."PaddlePriceIdMonthly" = p_paddle_price_id
       OR p."PaddlePriceIdAnnual"  = p_paddle_price_id
    LIMIT 1;
END;
$$;
-- +goose StatementEnd

-- ──────────────────────────────────────────────────────────────────────────────
-- CATÁLOGO — backoffice CRUD
-- ──────────────────────────────────────────────────────────────────────────────

-- usp_cfg_plan_upsert: crear o actualizar un plan desde backoffice
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION usp_cfg_plan_upsert(
    p_slug                   VARCHAR,
    p_name                   VARCHAR,
    p_vertical_type          VARCHAR,
    p_product_code           VARCHAR,
    p_description            TEXT,
    p_monthly_price          NUMERIC,
    p_annual_price           NUMERIC,
    p_billing_cycle_default  VARCHAR,
    p_max_users              INTEGER,
    p_max_transactions       INTEGER,
    p_features               JSONB,
    p_module_codes           JSONB,
    p_limits                 JSONB,
    p_is_addon               BOOLEAN,
    p_is_trial_only          BOOLEAN,
    p_trial_days             INTEGER,
    p_sort_order             INTEGER,
    p_is_active              BOOLEAN
)
RETURNS TABLE("ok" BOOLEAN, "mensaje" VARCHAR, "PricingPlanId" INTEGER, "RequiresPaddleSync" BOOLEAN)
LANGUAGE plpgsql AS $$
DECLARE
    v_plan_id      INTEGER;
    v_old_monthly  NUMERIC;
    v_old_annual   NUMERIC;
    v_requires_sync BOOLEAN := FALSE;
BEGIN
    SELECT "PricingPlanId", "MonthlyPrice", "AnnualPrice"
      INTO v_plan_id, v_old_monthly, v_old_annual
      FROM cfg."PricingPlan" WHERE "Slug" = p_slug;

    IF v_plan_id IS NULL THEN
        INSERT INTO cfg."PricingPlan" (
            "Name", "Slug", "VerticalType", "ProductCode", "Description",
            "MonthlyPrice", "AnnualPrice", "BillingCycleDefault",
            "MaxUsers", "MaxTransactions", "Features", "ModuleCodes", "Limits",
            "IsAddon", "IsTrialOnly", "TrialDays",
            "SortOrder", "IsActive",
            "PaddleSyncStatus"
        ) VALUES (
            p_name, p_slug, p_vertical_type, p_product_code, p_description,
            p_monthly_price, p_annual_price, p_billing_cycle_default,
            p_max_users, p_max_transactions, p_features, p_module_codes, p_limits,
            p_is_addon, p_is_trial_only, p_trial_days,
            p_sort_order, p_is_active,
            CASE WHEN p_is_trial_only THEN 'skip' ELSE 'draft' END
        ) RETURNING "PricingPlanId" INTO v_plan_id;

        v_requires_sync := NOT p_is_trial_only;
        RETURN QUERY SELECT TRUE, 'Plan creado'::VARCHAR, v_plan_id, v_requires_sync;
        RETURN;
    END IF;

    UPDATE cfg."PricingPlan" SET
        "Name" = p_name,
        "VerticalType" = p_vertical_type,
        "ProductCode"  = p_product_code,
        "Description"  = p_description,
        "MonthlyPrice" = p_monthly_price,
        "AnnualPrice"  = p_annual_price,
        "BillingCycleDefault" = p_billing_cycle_default,
        "MaxUsers" = p_max_users,
        "MaxTransactions" = p_max_transactions,
        "Features" = p_features,
        "ModuleCodes" = p_module_codes,
        "Limits" = p_limits,
        "IsAddon" = p_is_addon,
        "IsTrialOnly" = p_is_trial_only,
        "TrialDays" = p_trial_days,
        "SortOrder" = p_sort_order,
        "IsActive"  = p_is_active,
        -- Si cambió el precio → requiere resync con Paddle (archivePrice + createPrice)
        "PaddleSyncStatus" = CASE
            WHEN p_is_trial_only THEN 'skip'
            WHEN v_old_monthly <> p_monthly_price OR v_old_annual <> p_annual_price THEN 'draft'
            ELSE "PaddleSyncStatus"
        END
    WHERE "PricingPlanId" = v_plan_id;

    v_requires_sync := NOT p_is_trial_only AND (v_old_monthly <> p_monthly_price OR v_old_annual <> p_annual_price);
    RETURN QUERY SELECT TRUE, 'Plan actualizado'::VARCHAR, v_plan_id, v_requires_sync;
END;
$$;
-- +goose StatementEnd

-- usp_cfg_plan_set_paddle_ids: callback post-sync con IDs de Paddle
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION usp_cfg_plan_set_paddle_ids(
    p_plan_id                INTEGER,
    p_paddle_product_id      VARCHAR,
    p_paddle_price_monthly   VARCHAR,
    p_paddle_price_annual    VARCHAR,
    p_sync_status            VARCHAR,
    p_sync_error             TEXT DEFAULT ''
)
RETURNS TABLE("ok" BOOLEAN, "mensaje" VARCHAR)
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE cfg."PricingPlan" SET
        "PaddleProductId" = COALESCE(p_paddle_product_id, "PaddleProductId"),
        "PaddlePriceIdMonthly" = COALESCE(p_paddle_price_monthly, "PaddlePriceIdMonthly"),
        "PaddlePriceIdAnnual"  = COALESCE(p_paddle_price_annual,  "PaddlePriceIdAnnual"),
        "PaddleSyncStatus" = p_sync_status,
        "PaddleSyncError"  = COALESCE(p_sync_error, ''),
        "PaddleSyncedAt"   = CASE WHEN p_sync_status = 'synced' THEN NOW() ELSE "PaddleSyncedAt" END
    WHERE "PricingPlanId" = p_plan_id;

    IF NOT FOUND THEN
        RETURN QUERY SELECT FALSE, 'Plan no encontrado'::VARCHAR;
        RETURN;
    END IF;
    RETURN QUERY SELECT TRUE, 'Plan sincronizado'::VARCHAR;
END;
$$;
-- +goose StatementEnd

-- usp_cfg_plan_list_pending_sync: planes que necesitan sync con Paddle
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION usp_cfg_plan_list_pending_sync()
RETURNS TABLE(
    "PricingPlanId"        INTEGER,
    "Slug"                 VARCHAR,
    "Name"                 VARCHAR,
    "ProductCode"          VARCHAR,
    "MonthlyPrice"         NUMERIC,
    "AnnualPrice"          NUMERIC,
    "PaddleProductId"      VARCHAR,
    "PaddlePriceIdMonthly" VARCHAR,
    "PaddlePriceIdAnnual"  VARCHAR,
    "PaddleSyncStatus"     VARCHAR
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        p."PricingPlanId",
        p."Slug"::VARCHAR, p."Name"::VARCHAR, p."ProductCode"::VARCHAR,
        p."MonthlyPrice", p."AnnualPrice",
        p."PaddleProductId"::VARCHAR,
        p."PaddlePriceIdMonthly"::VARCHAR,
        p."PaddlePriceIdAnnual"::VARCHAR,
        p."PaddleSyncStatus"::VARCHAR
    FROM cfg."PricingPlan" p
    WHERE p."IsActive" = TRUE
      AND p."IsTrialOnly" = FALSE
      AND p."PaddleSyncStatus" IN ('draft','error')
    ORDER BY p."SortOrder";
END;
$$;
-- +goose StatementEnd

-- ──────────────────────────────────────────────────────────────────────────────
-- SUBDOMAIN CHECK (público, para registro)
-- ──────────────────────────────────────────────────────────────────────────────

-- usp_cfg_subdomain_check: devuelve disponibilidad de un slug
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION usp_cfg_subdomain_check(
    p_slug VARCHAR
)
RETURNS TABLE("available" BOOLEAN, "mensaje" VARCHAR)
LANGUAGE plpgsql AS $$
DECLARE
    v_count     INTEGER;
    v_reserved  TEXT[] := ARRAY[
        'www','app','api','auth','admin','backoffice','docs','docs2','dev',
        'appdev','apidev','authdev','notify','vault','mail','elastic','kibana',
        'broker','store','staging','test','demo','static','cdn','assets','img',
        'blog','support','help','status','stress','report','pay','payments'
    ];
BEGIN
    -- Formato: 3-63 chars, a-z0-9, guiones intermedios
    IF p_slug IS NULL OR LENGTH(p_slug) < 3 OR LENGTH(p_slug) > 63
       OR p_slug !~ '^[a-z0-9]([a-z0-9-]*[a-z0-9])?$' THEN
        RETURN QUERY SELECT FALSE, 'Formato inválido (3-63 caracteres, minúsculas/números/guiones)'::VARCHAR;
        RETURN;
    END IF;

    IF p_slug = ANY(v_reserved) THEN
        RETURN QUERY SELECT FALSE, 'Subdominio reservado'::VARCHAR;
        RETURN;
    END IF;

    SELECT COUNT(*) INTO v_count
      FROM mstr."Company"
     WHERE LOWER("TenantSubdomain") = p_slug;

    IF v_count > 0 THEN
        RETURN QUERY SELECT FALSE, 'Subdominio ocupado'::VARCHAR;
        RETURN;
    END IF;

    RETURN QUERY SELECT TRUE, 'Disponible'::VARCHAR;
END;
$$;
-- +goose StatementEnd

-- ──────────────────────────────────────────────────────────────────────────────
-- LEADS (embudo landing → tenant)
-- ──────────────────────────────────────────────────────────────────────────────

-- usp_public_lead_upsert: registra/actualiza lead desde registro o landing
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION usp_public_lead_upsert(
    p_email               VARCHAR,
    p_full_name           VARCHAR,
    p_company             VARCHAR,
    p_country             VARCHAR,
    p_source              VARCHAR,
    p_vertical_interest   VARCHAR,
    p_plan_slug           VARCHAR,
    p_addon_slugs         JSONB,
    p_intended_subdomain  VARCHAR,
    p_utm_source          VARCHAR,
    p_utm_medium          VARCHAR,
    p_utm_campaign        VARCHAR
)
RETURNS TABLE("ok" BOOLEAN, "mensaje" VARCHAR, "LeadId" INTEGER)
LANGUAGE plpgsql AS $$
DECLARE
    v_lead_id INTEGER;
BEGIN
    INSERT INTO public."Lead" (
        "Email", "FullName", "Company", "Country", "Source",
        "VerticalInterest", "PlanSlug", "AddonSlugs", "IntendedSubdomain",
        "UtmSource", "UtmMedium", "UtmCampaign",
        "Status", "CreatedAt", "UpdatedAt"
    ) VALUES (
        LOWER(p_email), COALESCE(p_full_name,''), COALESCE(p_company,''),
        COALESCE(p_country,''), COALESCE(p_source,'registro'),
        COALESCE(p_vertical_interest,''), COALESCE(p_plan_slug,''),
        COALESCE(p_addon_slugs,'[]'::JSONB), COALESCE(p_intended_subdomain,''),
        COALESCE(p_utm_source,''), COALESCE(p_utm_medium,''), COALESCE(p_utm_campaign,''),
        'new', NOW(), NOW()
    )
    ON CONFLICT ("Email") DO UPDATE SET
        "FullName"          = COALESCE(NULLIF(EXCLUDED."FullName",''),          public."Lead"."FullName"),
        "Company"           = COALESCE(NULLIF(EXCLUDED."Company",''),           public."Lead"."Company"),
        "Country"           = COALESCE(NULLIF(EXCLUDED."Country",''),           public."Lead"."Country"),
        "Source"            = COALESCE(NULLIF(EXCLUDED."Source",''),            public."Lead"."Source"),
        "VerticalInterest"  = COALESCE(NULLIF(EXCLUDED."VerticalInterest",''),  public."Lead"."VerticalInterest"),
        "PlanSlug"          = COALESCE(NULLIF(EXCLUDED."PlanSlug",''),          public."Lead"."PlanSlug"),
        "AddonSlugs"        = EXCLUDED."AddonSlugs",
        "IntendedSubdomain" = COALESCE(NULLIF(EXCLUDED."IntendedSubdomain",''), public."Lead"."IntendedSubdomain"),
        "UtmSource"         = COALESCE(NULLIF(EXCLUDED."UtmSource",''),         public."Lead"."UtmSource"),
        "UtmMedium"         = COALESCE(NULLIF(EXCLUDED."UtmMedium",''),         public."Lead"."UtmMedium"),
        "UtmCampaign"       = COALESCE(NULLIF(EXCLUDED."UtmCampaign",''),       public."Lead"."UtmCampaign"),
        "UpdatedAt"         = NOW()
    RETURNING "LeadId" INTO v_lead_id;

    RETURN QUERY SELECT TRUE, 'Lead registrado'::VARCHAR, v_lead_id;
END;
$$;
-- +goose StatementEnd

-- usp_public_lead_mark_converted: cierra el embudo cuando se crea el tenant
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION usp_public_lead_mark_converted(
    p_email      VARCHAR,
    p_company_id INTEGER
)
RETURNS TABLE("ok" BOOLEAN, "mensaje" VARCHAR)
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE public."Lead" SET
        "Status" = 'converted',
        "ConvertedToCompanyId" = p_company_id,
        "ConvertedAt" = NOW(),
        "UpdatedAt"   = NOW()
    WHERE LOWER("Email") = LOWER(p_email);

    RETURN QUERY SELECT TRUE, 'Lead convertido'::VARCHAR;
END;
$$;
-- +goose StatementEnd

-- ──────────────────────────────────────────────────────────────────────────────
-- TRIALS (anti-abuso por email+producto)
-- ──────────────────────────────────────────────────────────────────────────────

-- usp_cfg_trial_check: devuelve si un email puede iniciar trial de un producto
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION usp_cfg_trial_check(
    p_email        VARCHAR,
    p_product_code VARCHAR
)
RETURNS TABLE("available" BOOLEAN, "mensaje" VARCHAR, "PreviousExpiresAt" TIMESTAMPTZ)
LANGUAGE plpgsql AS $$
DECLARE
    v_expires TIMESTAMPTZ;
BEGIN
    SELECT "ExpiresAt" INTO v_expires
      FROM cfg."TrialUsage"
     WHERE LOWER("Email") = LOWER(p_email)
       AND "ProductCode"  = p_product_code
     LIMIT 1;

    IF v_expires IS NULL THEN
        RETURN QUERY SELECT TRUE, 'Trial disponible'::VARCHAR, NULL::TIMESTAMPTZ;
        RETURN;
    END IF;

    RETURN QUERY SELECT FALSE, 'Ya usaste trial de este producto'::VARCHAR, v_expires;
END;
$$;
-- +goose StatementEnd

-- usp_cfg_trial_start: registra el uso de trial (una vez por email+producto)
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION usp_cfg_trial_start(
    p_email          VARCHAR,
    p_product_code   VARCHAR,
    p_pricing_plan_id INTEGER,
    p_company_id     INTEGER,
    p_trial_days     INTEGER
)
RETURNS TABLE("ok" BOOLEAN, "mensaje" VARCHAR, "ExpiresAt" TIMESTAMPTZ)
LANGUAGE plpgsql AS $$
DECLARE
    v_expires TIMESTAMPTZ;
BEGIN
    v_expires := NOW() + (p_trial_days || ' days')::INTERVAL;

    INSERT INTO cfg."TrialUsage" (
        "Email", "ProductCode", "CompanyId", "PricingPlanId",
        "StartedAt", "ExpiresAt"
    ) VALUES (
        LOWER(p_email), p_product_code, p_company_id, p_pricing_plan_id,
        NOW(), v_expires
    )
    ON CONFLICT (LOWER("Email"), "ProductCode") DO NOTHING;

    IF NOT FOUND THEN
        RETURN QUERY SELECT FALSE, 'Ya existe un trial previo'::VARCHAR, NULL::TIMESTAMPTZ;
        RETURN;
    END IF;

    RETURN QUERY SELECT TRUE, 'Trial iniciado'::VARCHAR, v_expires;
END;
$$;
-- +goose StatementEnd

-- ──────────────────────────────────────────────────────────────────────────────
-- SUBSCRIPTIONS y SUBSCRIPTION ITEMS (multi-item)
-- ──────────────────────────────────────────────────────────────────────────────

-- usp_sys_subscription_create: crea una suscripción (trial o paddle)
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

-- usp_sys_subscription_item_add: añade un item a una suscripción (base o addon)
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

-- usp_sys_subscription_item_remove: quita un item (cancelar addon)
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION usp_sys_subscription_item_remove(
    p_subscription_item_id INTEGER
)
RETURNS TABLE("ok" BOOLEAN, "mensaje" VARCHAR)
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE sys."SubscriptionItem" SET
        "Status"    = 'removed',
        "RemovedAt" = NOW()
    WHERE "SubscriptionItemId" = p_subscription_item_id
      AND "Status" = 'active';

    IF NOT FOUND THEN
        RETURN QUERY SELECT FALSE, 'Item no encontrado o ya removido'::VARCHAR;
        RETURN;
    END IF;
    RETURN QUERY SELECT TRUE, 'Item removido'::VARCHAR;
END;
$$;
-- +goose StatementEnd

-- usp_sys_subscription_get_by_company: estado actual del tenant con items
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION usp_sys_subscription_get_by_company(
    p_company_id INTEGER
)
RETURNS TABLE(
    "SubscriptionId"        INTEGER,
    "CompanyId"             INTEGER,
    "Source"                VARCHAR,
    "Status"                VARCHAR,
    "PaddleSubscriptionId"  VARCHAR,
    "PaddleCustomerId"      VARCHAR,
    "CurrentPeriodStart"    TIMESTAMP,
    "CurrentPeriodEnd"      TIMESTAMP,
    "TrialEndsAt"           TIMESTAMP,
    "CancelledAt"           TIMESTAMP,
    "ItemsJson"             JSONB
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        s."SubscriptionId",
        s."CompanyId",
        s."Source"::VARCHAR,
        s."Status"::VARCHAR,
        s."PaddleSubscriptionId"::VARCHAR,
        s."PaddleCustomerId"::VARCHAR,
        s."CurrentPeriodStart",
        s."CurrentPeriodEnd",
        s."TrialEndsAt",
        s."CancelledAt",
        COALESCE((
            SELECT jsonb_agg(jsonb_build_object(
                'SubscriptionItemId',       i."SubscriptionItemId",
                'PricingPlanId',            i."PricingPlanId",
                'PlanSlug',                 p."Slug",
                'PlanName',                 p."Name",
                'ProductCode',              p."ProductCode",
                'VerticalType',             p."VerticalType",
                'IsAddon',                  p."IsAddon",
                'Quantity',                 i."Quantity",
                'UnitPrice',                i."UnitPrice",
                'BillingCycle',             i."BillingCycle",
                'PaddleSubscriptionItemId', i."PaddleSubscriptionItemId",
                'Status',                   i."Status",
                'AddedAt',                  i."AddedAt"
            ))
            FROM sys."SubscriptionItem" i
            JOIN cfg."PricingPlan" p ON p."PricingPlanId" = i."PricingPlanId"
            WHERE i."SubscriptionId" = s."SubscriptionId" AND i."Status" = 'active'
        ), '[]'::JSONB) AS "ItemsJson"
    FROM sys."Subscription" s
    WHERE s."CompanyId" = p_company_id
    ORDER BY s."CreatedAt" DESC
    LIMIT 1;
END;
$$;
-- +goose StatementEnd

-- usp_sys_subscription_get_by_paddle_id: para webhook lookup
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION usp_sys_subscription_get_by_paddle_id(
    p_paddle_subscription_id VARCHAR
)
RETURNS TABLE(
    "SubscriptionId" INTEGER,
    "CompanyId"      INTEGER,
    "Source"         VARCHAR,
    "Status"         VARCHAR
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT s."SubscriptionId", s."CompanyId", s."Source"::VARCHAR, s."Status"::VARCHAR
      FROM sys."Subscription" s
     WHERE s."PaddleSubscriptionId" = p_paddle_subscription_id
     LIMIT 1;
END;
$$;
-- +goose StatementEnd

-- usp_sys_subscription_update_status: actualiza estado y período (webhook updates)
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION usp_sys_subscription_update_status(
    p_subscription_id        INTEGER,
    p_status                 VARCHAR,
    p_current_period_start   TIMESTAMP,
    p_current_period_end     TIMESTAMP,
    p_cancelled_at           TIMESTAMP
)
RETURNS TABLE("ok" BOOLEAN, "mensaje" VARCHAR)
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE sys."Subscription" SET
        "Status"             = COALESCE(p_status, "Status"),
        "CurrentPeriodStart" = COALESCE(p_current_period_start, "CurrentPeriodStart"),
        "CurrentPeriodEnd"   = COALESCE(p_current_period_end,   "CurrentPeriodEnd"),
        "CancelledAt"        = COALESCE(p_cancelled_at,         "CancelledAt"),
        "UpdatedAt"          = NOW()
    WHERE "SubscriptionId" = p_subscription_id;

    RETURN QUERY SELECT TRUE, 'Estado actualizado'::VARCHAR;
END;
$$;
-- +goose StatementEnd

-- usp_sys_subscription_entitlements: unión de ModuleCodes de items activos
-- Devuelve un JSONB array con los códigos únicos de módulo activos del tenant.
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION usp_sys_subscription_entitlements(
    p_company_id INTEGER
)
RETURNS TABLE(
    "CompanyId"    INTEGER,
    "ModuleCodes"  JSONB,
    "Plans"        JSONB,
    "ExpiresAt"    TIMESTAMP,
    "IsActive"     BOOLEAN
)
LANGUAGE plpgsql AS $$
DECLARE
    v_sub RECORD;
BEGIN
    SELECT s."SubscriptionId", s."Status", s."CurrentPeriodEnd", s."TrialEndsAt", s."Source"
      INTO v_sub
      FROM sys."Subscription" s
     WHERE s."CompanyId" = p_company_id
     ORDER BY s."CreatedAt" DESC
     LIMIT 1;

    IF v_sub IS NULL THEN
        RETURN QUERY SELECT p_company_id, '[]'::JSONB, '[]'::JSONB, NULL::TIMESTAMP, FALSE;
        RETURN;
    END IF;

    RETURN QUERY
    SELECT
        p_company_id,
        COALESCE((
            SELECT jsonb_agg(DISTINCT m)
              FROM sys."SubscriptionItem" i
              JOIN cfg."PricingPlan" pp ON pp."PricingPlanId" = i."PricingPlanId"
             CROSS JOIN LATERAL jsonb_array_elements_text(pp."ModuleCodes") AS m
             WHERE i."SubscriptionId" = v_sub."SubscriptionId" AND i."Status" = 'active'
        ), '[]'::JSONB) AS "ModuleCodes",
        COALESCE((
            SELECT jsonb_agg(pp."Slug")
              FROM sys."SubscriptionItem" i
              JOIN cfg."PricingPlan" pp ON pp."PricingPlanId" = i."PricingPlanId"
             WHERE i."SubscriptionId" = v_sub."SubscriptionId" AND i."Status" = 'active'
        ), '[]'::JSONB) AS "Plans",
        COALESCE(v_sub."TrialEndsAt", v_sub."CurrentPeriodEnd") AS "ExpiresAt",
        (v_sub."Status" IN ('active','trialing')) AS "IsActive";
END;
$$;
-- +goose StatementEnd


-- +goose Down
DROP FUNCTION IF EXISTS usp_sys_subscription_entitlements(INTEGER);
DROP FUNCTION IF EXISTS usp_sys_subscription_update_status(INTEGER, VARCHAR, TIMESTAMP, TIMESTAMP, TIMESTAMP);
DROP FUNCTION IF EXISTS usp_sys_subscription_get_by_paddle_id(VARCHAR);
DROP FUNCTION IF EXISTS usp_sys_subscription_get_by_company(INTEGER);
DROP FUNCTION IF EXISTS usp_sys_subscription_item_remove(INTEGER);
DROP FUNCTION IF EXISTS usp_sys_subscription_item_add(INTEGER, INTEGER, INTEGER, INTEGER, VARCHAR, VARCHAR, NUMERIC, VARCHAR);
DROP FUNCTION IF EXISTS usp_sys_subscription_create(INTEGER, VARCHAR, VARCHAR, VARCHAR, VARCHAR, TIMESTAMP, TIMESTAMP, TIMESTAMP, VARCHAR);
DROP FUNCTION IF EXISTS usp_cfg_trial_start(VARCHAR, VARCHAR, INTEGER, INTEGER, INTEGER);
DROP FUNCTION IF EXISTS usp_cfg_trial_check(VARCHAR, VARCHAR);
DROP FUNCTION IF EXISTS usp_public_lead_mark_converted(VARCHAR, INTEGER);
DROP FUNCTION IF EXISTS usp_public_lead_upsert(VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, JSONB, VARCHAR, VARCHAR, VARCHAR, VARCHAR);
DROP FUNCTION IF EXISTS usp_cfg_subdomain_check(VARCHAR);
DROP FUNCTION IF EXISTS usp_cfg_plan_list_pending_sync();
DROP FUNCTION IF EXISTS usp_cfg_plan_set_paddle_ids(INTEGER, VARCHAR, VARCHAR, VARCHAR, VARCHAR, TEXT);
DROP FUNCTION IF EXISTS usp_cfg_plan_upsert(VARCHAR, VARCHAR, VARCHAR, VARCHAR, TEXT, NUMERIC, NUMERIC, VARCHAR, INTEGER, INTEGER, JSONB, JSONB, JSONB, BOOLEAN, BOOLEAN, INTEGER, INTEGER, BOOLEAN);
DROP FUNCTION IF EXISTS usp_cfg_plan_get_by_paddle_price_id(VARCHAR);
DROP FUNCTION IF EXISTS usp_cfg_plan_get_by_slug(VARCHAR);
DROP FUNCTION IF EXISTS usp_cfg_catalog_list(VARCHAR, VARCHAR, BOOLEAN);
