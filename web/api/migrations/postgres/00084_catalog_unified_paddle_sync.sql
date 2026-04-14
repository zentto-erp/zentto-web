-- +goose Up
-- ══════════════════════════════════════════════════════════════════════════════
-- Catálogo unificado de planes + sincronización con Paddle
--
-- Objetivo: consolidar el ciclo "landing → registro → checkout → provisioning"
-- en un único catálogo editable desde backoffice, con Paddle como brazo de
-- cobranza. Soporta:
--   • Plan trial 30 días sin tarjeta (leads)
--   • Plan base ERP + N add-ons verticales (Hotel/Medical/Tickets/Edu/Rental)
--   • Sincronización bidireccional de IDs Paddle (product_id + price_id)
--   • Entitlements de módulos calculados como unión de items activos
--
-- Estrategia: extender cfg."PricingPlan" y sys."Subscription", añadir
-- sys."SubscriptionItem" (multi-item), extender public."Lead", crear
-- cfg."TrialUsage" para anti-abuso del trial.
-- ══════════════════════════════════════════════════════════════════════════════

-- ──────────────────────────────────────────────────────────────────────────────
-- 1) cfg."PricingPlan": extender con Paddle + addon + trial + módulos
-- ──────────────────────────────────────────────────────────────────────────────

ALTER TABLE cfg."PricingPlan"
    ADD COLUMN IF NOT EXISTS "ProductCode"         VARCHAR(50)   NOT NULL DEFAULT 'erp-core'::VARCHAR,
    ADD COLUMN IF NOT EXISTS "Description"         TEXT          NOT NULL DEFAULT ''::TEXT,
    ADD COLUMN IF NOT EXISTS "BillingCycleDefault" VARCHAR(10)   NOT NULL DEFAULT 'monthly'::VARCHAR,
    ADD COLUMN IF NOT EXISTS "IsAddon"             BOOLEAN       NOT NULL DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS "IsTrialOnly"         BOOLEAN       NOT NULL DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS "TrialDays"           INTEGER       NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS "ModuleCodes"         JSONB         NOT NULL DEFAULT '[]'::JSONB,
    ADD COLUMN IF NOT EXISTS "Limits"              JSONB         NOT NULL DEFAULT '{}'::JSONB,
    ADD COLUMN IF NOT EXISTS "SortOrder"           INTEGER       NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS "PaddleProductId"     VARCHAR(100)  NOT NULL DEFAULT ''::VARCHAR,
    ADD COLUMN IF NOT EXISTS "PaddlePriceIdMonthly" VARCHAR(100) NOT NULL DEFAULT ''::VARCHAR,
    ADD COLUMN IF NOT EXISTS "PaddlePriceIdAnnual"  VARCHAR(100) NOT NULL DEFAULT ''::VARCHAR,
    ADD COLUMN IF NOT EXISTS "PaddleSyncStatus"    VARCHAR(20)   NOT NULL DEFAULT 'draft'::VARCHAR,
    ADD COLUMN IF NOT EXISTS "PaddleSyncError"     TEXT          NOT NULL DEFAULT ''::TEXT,
    ADD COLUMN IF NOT EXISTS "PaddleSyncedAt"      TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS "UpdatedAt"           TIMESTAMPTZ   NOT NULL DEFAULT NOW();

-- Ampliar vertical para incluir rental + none (para plan trial multi-vertical)
ALTER TABLE cfg."PricingPlan" DROP CONSTRAINT IF EXISTS chk_pricing_vertical;
ALTER TABLE cfg."PricingPlan"
    ADD CONSTRAINT chk_pricing_vertical
    CHECK ("VerticalType" IN ('erp','medical','tickets','hotel','education','rental','none'));

-- Sync status permitidos
ALTER TABLE cfg."PricingPlan" DROP CONSTRAINT IF EXISTS chk_pricing_sync_status;
ALTER TABLE cfg."PricingPlan"
    ADD CONSTRAINT chk_pricing_sync_status
    CHECK ("PaddleSyncStatus" IN ('draft','syncing','synced','error','skip'));

-- Billing cycle permitido
ALTER TABLE cfg."PricingPlan" DROP CONSTRAINT IF EXISTS chk_pricing_billing_cycle;
ALTER TABLE cfg."PricingPlan"
    ADD CONSTRAINT chk_pricing_billing_cycle
    CHECK ("BillingCycleDefault" IN ('monthly','annual','both'));

CREATE INDEX IF NOT EXISTS idx_pricing_plan_product    ON cfg."PricingPlan" ("ProductCode", "IsActive");
CREATE INDEX IF NOT EXISTS idx_pricing_plan_paddle     ON cfg."PricingPlan" ("PaddlePriceIdMonthly") WHERE "PaddlePriceIdMonthly" <> '';
CREATE INDEX IF NOT EXISTS idx_pricing_plan_paddle_ann ON cfg."PricingPlan" ("PaddlePriceIdAnnual")  WHERE "PaddlePriceIdAnnual" <> '';
CREATE INDEX IF NOT EXISTS idx_pricing_plan_addon      ON cfg."PricingPlan" ("IsAddon", "IsActive");

-- ──────────────────────────────────────────────────────────────────────────────
-- 2) sys."Subscription": extender para soportar trial + source
-- ──────────────────────────────────────────────────────────────────────────────

ALTER TABLE sys."Subscription"
    ADD COLUMN IF NOT EXISTS "Source"       VARCHAR(20)  NOT NULL DEFAULT 'paddle'::VARCHAR,
    ADD COLUMN IF NOT EXISTS "TrialEndsAt"  TIMESTAMP,
    ADD COLUMN IF NOT EXISTS "ExpiredAt"    TIMESTAMP;

ALTER TABLE sys."Subscription" DROP CONSTRAINT IF EXISTS chk_subscription_source;
ALTER TABLE sys."Subscription"
    ADD CONSTRAINT chk_subscription_source
    CHECK ("Source" IN ('paddle','trial','manual'));

ALTER TABLE sys."Subscription" DROP CONSTRAINT IF EXISTS chk_subscription_status;
ALTER TABLE sys."Subscription"
    ADD CONSTRAINT chk_subscription_status
    CHECK ("Status" IN ('trialing','active','past_due','paused','cancelled','expired'));

-- Permitir PaddleSubscriptionId vacío para trials (antes era NOT NULL sin default)
ALTER TABLE sys."Subscription" ALTER COLUMN "PaddleSubscriptionId" SET DEFAULT '';

CREATE INDEX IF NOT EXISTS idx_subscription_company_status ON sys."Subscription" ("CompanyId", "Status");
CREATE INDEX IF NOT EXISTS idx_subscription_trial_ends     ON sys."Subscription" ("TrialEndsAt") WHERE "Status" = 'trialing';

-- ──────────────────────────────────────────────────────────────────────────────
-- 3) sys."SubscriptionItem": items de una suscripción (base + addons)
-- ──────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS sys."SubscriptionItem" (
    "SubscriptionItemId"       SERIAL        PRIMARY KEY,
    "SubscriptionId"           INTEGER       NOT NULL REFERENCES sys."Subscription"("SubscriptionId") ON DELETE CASCADE,
    "CompanyId"                INTEGER       NOT NULL,
    "PricingPlanId"            INTEGER       NOT NULL REFERENCES cfg."PricingPlan"("PricingPlanId"),
    "Quantity"                 INTEGER       NOT NULL DEFAULT 1,
    "PaddleSubscriptionItemId" VARCHAR(100)  NOT NULL DEFAULT ''::VARCHAR,
    "PaddlePriceId"            VARCHAR(100)  NOT NULL DEFAULT ''::VARCHAR,
    "UnitPrice"                NUMERIC(12,2) NOT NULL DEFAULT 0,
    "BillingCycle"             VARCHAR(10)   NOT NULL DEFAULT 'monthly'::VARCHAR,
    "Status"                   VARCHAR(20)   NOT NULL DEFAULT 'active'::VARCHAR,
    "AddedAt"                  TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    "RemovedAt"                TIMESTAMPTZ,
    CONSTRAINT chk_subitem_status CHECK ("Status" IN ('active','removed','paused')),
    CONSTRAINT chk_subitem_cycle  CHECK ("BillingCycle" IN ('monthly','annual'))
);

CREATE INDEX IF NOT EXISTS idx_subitem_subscription ON sys."SubscriptionItem" ("SubscriptionId", "Status");
CREATE INDEX IF NOT EXISTS idx_subitem_company_active ON sys."SubscriptionItem" ("CompanyId") WHERE "Status" = 'active';
CREATE INDEX IF NOT EXISTS idx_subitem_paddle        ON sys."SubscriptionItem" ("PaddleSubscriptionItemId") WHERE "PaddleSubscriptionItemId" <> '';

-- ──────────────────────────────────────────────────────────────────────────────
-- 4) public."Lead": extender para captura desde registro + UTM + conversión
-- ──────────────────────────────────────────────────────────────────────────────

ALTER TABLE public."Lead"
    ADD COLUMN IF NOT EXISTS "VerticalInterest"      VARCHAR(30)   NOT NULL DEFAULT ''::VARCHAR,
    ADD COLUMN IF NOT EXISTS "PlanSlug"              VARCHAR(80)   NOT NULL DEFAULT ''::VARCHAR,
    ADD COLUMN IF NOT EXISTS "AddonSlugs"            JSONB         NOT NULL DEFAULT '[]'::JSONB,
    ADD COLUMN IF NOT EXISTS "UtmSource"             VARCHAR(100)  NOT NULL DEFAULT ''::VARCHAR,
    ADD COLUMN IF NOT EXISTS "UtmMedium"             VARCHAR(100)  NOT NULL DEFAULT ''::VARCHAR,
    ADD COLUMN IF NOT EXISTS "UtmCampaign"           VARCHAR(100)  NOT NULL DEFAULT ''::VARCHAR,
    ADD COLUMN IF NOT EXISTS "IntendedSubdomain"     VARCHAR(63)   NOT NULL DEFAULT ''::VARCHAR,
    ADD COLUMN IF NOT EXISTS "ConvertedToCompanyId"  INTEGER       NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS "ConvertedAt"           TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS "Status"                VARCHAR(20)   NOT NULL DEFAULT 'new'::VARCHAR;

ALTER TABLE public."Lead" DROP CONSTRAINT IF EXISTS chk_lead_status;
ALTER TABLE public."Lead"
    ADD CONSTRAINT chk_lead_status
    CHECK ("Status" IN ('new','contacted','trial_started','converted','lost'));

CREATE INDEX IF NOT EXISTS idx_lead_status_created ON public."Lead" ("Status", "CreatedAt" DESC);
CREATE INDEX IF NOT EXISTS idx_lead_converted      ON public."Lead" ("ConvertedToCompanyId") WHERE "ConvertedToCompanyId" > 0;

-- ──────────────────────────────────────────────────────────────────────────────
-- 5) cfg."TrialUsage": control anti-abuso de trials gratuitos
-- ──────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS cfg."TrialUsage" (
    "TrialUsageId"   SERIAL       PRIMARY KEY,
    "Email"          VARCHAR(200) NOT NULL,
    "ProductCode"    VARCHAR(50)  NOT NULL,
    "CompanyId"      INTEGER      NOT NULL DEFAULT 0,
    "PricingPlanId"  INTEGER      NOT NULL REFERENCES cfg."PricingPlan"("PricingPlanId"),
    "StartedAt"      TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    "ExpiresAt"      TIMESTAMPTZ  NOT NULL,
    "ConvertedAt"    TIMESTAMPTZ,
    "CancelledAt"    TIMESTAMPTZ
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_trialusage_email_product ON cfg."TrialUsage" (LOWER("Email"), "ProductCode");
CREATE INDEX IF NOT EXISTS idx_trialusage_expires ON cfg."TrialUsage" ("ExpiresAt") WHERE "ConvertedAt" IS NULL AND "CancelledAt" IS NULL;

-- ──────────────────────────────────────────────────────────────────────────────
-- 6) Seed del catálogo unificado (precios ~50% debajo de mercado, introductorios)
--
-- Productos:
--   erp-core     → base (trial 30d, basic, pro, enterprise)
--   medical      → add-on (clinic, hospital)
--   tickets      → add-on (basic, pro)
--   hotel        → add-on (pyme, chain)
--   education    → add-on (academy, university)
--   rental       → add-on (pyme, pro)
--
-- Límites pensados para lo que el sistema tenant soporta hoy:
--   users    = usuarios activos en sec."User"
--   branches = sucursales en master."Branch"
--   warehouses = almacenes en inv."Warehouse"
--   storage_gb = tamaño permitido de BD tenant (Hetzner CX33 ~80GB total)
--   invoices_month = topes de facturación electrónica por mes
--   transactions_month = topes genéricos para transacciones (0 = ilimitado)
--
-- Los precios se pueden cambiar desde backoffice; al cambiar se resincronizan
-- con Paddle (archivePrice + createPrice).
--
-- Referencia competitiva (USA/LatAm):
--   QuickBooks Online Simple Start $30 → Plus $90 → Advanced $200
--   Odoo Standard $25/user → Custom $37.40/user
--   Cloudbeds Hotel $100-$600 → Mews Basic $8-$15/room
--   Mindbody Medical $129-$379
-- Estrategia: entrar 40-55% por debajo para captar LatAm.
-- ──────────────────────────────────────────────────────────────────────────────

-- ==== ERP CORE (plan base) ====

UPDATE cfg."PricingPlan" SET
    "Name" = 'Básico', "ProductCode" = 'erp-core', "SortOrder" = 20,
    "MonthlyPrice" = 14.99, "AnnualPrice" = 149.00,
    "MaxUsers" = 3, "MaxTransactions" = 500,
    "Description" = 'Ideal para pequeñas empresas que inician su digitalización. Facturación, inventario, POS.',
    "Features" = '["3 usuarios","1 sucursal","1 almacén","Facturación electrónica (200/mes)","POS (1 caja)","Contabilidad básica","5 GB almacenamiento","Soporte por email"]'::JSONB,
    "ModuleCodes" = '["dashboard","facturas","clientes","inventario","articulos","reportes","abonos","cxc","compras","cxp","bancos","conciliaciones","pos","documentos-electronicos"]'::JSONB,
    "Limits" = '{"users":3,"branches":1,"warehouses":1,"storage_gb":5,"invoices_month":200,"transactions_month":500,"api_calls_day":1000,"pos_cashiers":1}'::JSONB
WHERE "Slug" = 'erp-starter';

UPDATE cfg."PricingPlan" SET
    "Name" = 'Profesional', "ProductCode" = 'erp-core', "SortOrder" = 30,
    "MonthlyPrice" = 39.99, "AnnualPrice" = 399.00,
    "MaxUsers" = 15, "MaxTransactions" = 0,
    "Description" = 'Para empresas en crecimiento: contabilidad completa, nómina, CRM, POS & Restaurante.',
    "Features" = '["15 usuarios","3 sucursales","5 almacenes","Facturación ilimitada","Contabilidad completa + asientos automáticos","Nómina (hasta 50 empleados)","POS & Restaurante","Ecommerce integrado","50 GB almacenamiento","Soporte prioritario (chat + email)","API REST"]'::JSONB,
    "ModuleCodes" = '["dashboard","facturas","clientes","inventario","articulos","reportes","abonos","cxc","compras","cxp","bancos","conciliaciones","pos","documentos-electronicos","contabilidad","nomina","crm","pos-avanzado","restaurante","ecommerce","shipping","multi-sucursal","multi-almacen","asientos-automaticos"]'::JSONB,
    "Limits" = '{"users":15,"branches":3,"warehouses":5,"storage_gb":50,"invoices_month":0,"transactions_month":0,"api_calls_day":25000,"pos_cashiers":5,"payroll_employees":50}'::JSONB
WHERE "Slug" = 'erp-professional';

UPDATE cfg."PricingPlan" SET
    "Name" = 'Enterprise', "ProductCode" = 'erp-core', "SortOrder" = 40,
    "MonthlyPrice" = 99.99, "AnnualPrice" = 999.00,
    "MaxUsers" = 50, "MaxTransactions" = 0,
    "Description" = 'Soluciones avanzadas: manufactura, flota, API ilimitada, SLA y soporte 24/7.',
    "Features" = '["50 usuarios","Multi-empresa y multi-sucursal ilimitado","Almacenes ilimitados","SLA garantizado 99.9%","Nómina ilimitada","Manufactura y gestión de flota","200 GB almacenamiento","Soporte 24/7 dedicado","Módulos a medida","Integración con sistemas legados","Gerente de cuenta dedicado"]'::JSONB,
    "ModuleCodes" = '["dashboard","facturas","clientes","inventario","articulos","reportes","abonos","cxc","compras","cxp","bancos","conciliaciones","pos","documentos-electronicos","contabilidad","nomina","crm","pos-avanzado","restaurante","ecommerce","shipping","multi-sucursal","multi-almacen","asientos-automaticos","manufactura","fleet","api-ilimitada","soporte-24x7","white-label"]'::JSONB,
    "Limits" = '{"users":50,"branches":0,"warehouses":0,"storage_gb":200,"invoices_month":0,"transactions_month":0,"api_calls_day":0,"pos_cashiers":0,"payroll_employees":0}'::JSONB
WHERE "Slug" = 'erp-enterprise';

-- ==== MEDICAL (add-on) ====

UPDATE cfg."PricingPlan" SET
    "Name" = 'Clínica', "IsAddon" = TRUE, "ProductCode" = 'medical', "SortOrder" = 10,
    "MonthlyPrice" = 24.99, "AnnualPrice" = 249.00,
    "MaxUsers" = 10, "MaxTransactions" = 2000,
    "Description" = 'Citas, pacientes, recetas, historia clínica y chat médico para consultorios.',
    "Features" = '["10 usuarios","Citas y agenda","Pacientes e historia clínica","Recetas digitales","Chat médico","10 GB almacenamiento"]'::JSONB,
    "ModuleCodes" = '["medical-citas","medical-pacientes","medical-recetas","medical-historia","medical-chat"]'::JSONB,
    "Limits" = '{"users":10,"branches":1,"patients":2000,"storage_gb":10,"appointments_month":2000}'::JSONB
WHERE "Slug" = 'medical-clinic';

UPDATE cfg."PricingPlan" SET
    "Name" = 'Hospital', "IsAddon" = TRUE, "ProductCode" = 'medical', "SortOrder" = 20,
    "MonthlyPrice" = 74.99, "AnnualPrice" = 749.00,
    "MaxUsers" = 50, "MaxTransactions" = 20000,
    "Description" = 'Clínica + multi-sede, laboratorio, facturación médica y reportes regulatorios.',
    "Features" = '["50 usuarios","Multi-sede ilimitada","Laboratorio","Facturación médica","Reportes avanzados","100 GB almacenamiento"]'::JSONB,
    "ModuleCodes" = '["medical-citas","medical-pacientes","medical-recetas","medical-historia","medical-chat","medical-multisite","medical-lab","medical-billing","medical-reports-advanced"]'::JSONB,
    "Limits" = '{"users":50,"branches":0,"patients":0,"storage_gb":100,"appointments_month":0}'::JSONB
WHERE "Slug" = 'medical-hospital';

-- ==== TICKETS (add-on) ====

UPDATE cfg."PricingPlan" SET
    "Name" = 'Tickets Básico', "IsAddon" = TRUE, "ProductCode" = 'tickets', "SortOrder" = 10,
    "MonthlyPrice" = 9.99, "AnnualPrice" = 99.00,
    "MaxUsers" = 3, "MaxTransactions" = 500,
    "Description" = 'Venta de tickets con QR y dashboard básico para eventos pequeños.',
    "Features" = '["3 usuarios","Venta de tickets","QR en ticket","Dashboard básico","500 tickets/mes"]'::JSONB,
    "ModuleCodes" = '["tickets-sales","tickets-qr","tickets-dashboard"]'::JSONB,
    "Limits" = '{"users":3,"events_active":3,"tickets_month":500,"storage_gb":2}'::JSONB
WHERE "Slug" = 'tickets-basic';

UPDATE cfg."PricingPlan" SET
    "Name" = 'Tickets Pro', "IsAddon" = TRUE, "ProductCode" = 'tickets', "SortOrder" = 20,
    "MonthlyPrice" = 29.99, "AnnualPrice" = 299.00,
    "MaxUsers" = 10, "MaxTransactions" = 5000,
    "Description" = 'Multi-evento, reportes avanzados, API completa, mapas de asientos.',
    "Features" = '["10 usuarios","Eventos ilimitados","Mapas de asientos","Reportes","API REST","5000 tickets/mes"]'::JSONB,
    "ModuleCodes" = '["tickets-sales","tickets-qr","tickets-dashboard","tickets-multi-event","tickets-reports","tickets-api","tickets-seat-map"]'::JSONB,
    "Limits" = '{"users":10,"events_active":0,"tickets_month":5000,"storage_gb":20,"api_calls_day":10000}'::JSONB
WHERE "Slug" = 'tickets-pro';

-- ==== HOTEL (add-on) ====

UPDATE cfg."PricingPlan" SET
    "Name" = 'Hotel Pyme', "IsAddon" = TRUE, "ProductCode" = 'hotel', "SortOrder" = 10,
    "MonthlyPrice" = 19.99, "AnnualPrice" = 199.00,
    "MaxUsers" = 5, "MaxTransactions" = 1000,
    "Description" = 'Reservas, huéspedes, housekeeping y check-in/out para hoteles boutique.',
    "Features" = '["5 usuarios","Hasta 30 habitaciones","Reservas y calendario","Check-in/out","Housekeeping","Huéspedes"]'::JSONB,
    "ModuleCodes" = '["hotel-reservas","hotel-huespedes","hotel-housekeeping","hotel-checkin"]'::JSONB,
    "Limits" = '{"users":5,"rooms":30,"properties":1,"storage_gb":10,"bookings_month":1000}'::JSONB
WHERE "Slug" = 'hotel-pyme';

UPDATE cfg."PricingPlan" SET
    "Name" = 'Hotel Chain', "IsAddon" = TRUE, "ProductCode" = 'hotel', "SortOrder" = 20,
    "MonthlyPrice" = 64.99, "AnnualPrice" = 649.00,
    "MaxUsers" = 30, "MaxTransactions" = 10000,
    "Description" = 'Multi-propiedad, revenue management y channel manager para cadenas hoteleras.',
    "Features" = '["30 usuarios","Propiedades ilimitadas","Revenue management","Channel manager","Reportes","100 GB almacenamiento"]'::JSONB,
    "ModuleCodes" = '["hotel-reservas","hotel-huespedes","hotel-housekeeping","hotel-checkin","hotel-multi-property","hotel-revenue","hotel-channel-manager"]'::JSONB,
    "Limits" = '{"users":30,"rooms":0,"properties":0,"storage_gb":100,"bookings_month":0}'::JSONB
WHERE "Slug" = 'hotel-chain';

-- ==== EDUCATION (add-on) ====

UPDATE cfg."PricingPlan" SET
    "Name" = 'Academia', "IsAddon" = TRUE, "ProductCode" = 'education', "SortOrder" = 10,
    "MonthlyPrice" = 14.99, "AnnualPrice" = 149.00,
    "MaxUsers" = 5, "MaxTransactions" = 1000,
    "Description" = 'Estudiantes, cursos, asistencia, notas y comunicados para academias.',
    "Features" = '["5 usuarios","Hasta 300 estudiantes","Cursos","Asistencia","Notas","Comunicados"]'::JSONB,
    "ModuleCodes" = '["edu-students","edu-courses","edu-attendance","edu-grades","edu-communications"]'::JSONB,
    "Limits" = '{"users":5,"students":300,"campuses":1,"storage_gb":10,"courses_active":20}'::JSONB
WHERE "Slug" = 'edu-academy';

UPDATE cfg."PricingPlan" SET
    "Name" = 'Universidad', "IsAddon" = TRUE, "ProductCode" = 'education', "SortOrder" = 20,
    "MonthlyPrice" = 49.99, "AnnualPrice" = 499.00,
    "MaxUsers" = 30, "MaxTransactions" = 10000,
    "Description" = 'Multi-sede, inscripciones online y reportes regulatorios.',
    "Features" = '["30 usuarios","Estudiantes ilimitados","Multi-sede","Inscripciones online","Reportes regulatorios","100 GB almacenamiento"]'::JSONB,
    "ModuleCodes" = '["edu-students","edu-courses","edu-attendance","edu-grades","edu-communications","edu-multisite","edu-enrollment-online","edu-regulatory-reports"]'::JSONB,
    "Limits" = '{"users":30,"students":0,"campuses":0,"storage_gb":100,"courses_active":0}'::JSONB
WHERE "Slug" = 'edu-university';

-- ==== PLAN TRIAL 30 DÍAS (gratis, sin tarjeta) ====
-- Da acceso al plan Profesional por 30 días. Un email = un trial por producto.

INSERT INTO cfg."PricingPlan" (
    "Name", "Slug", "VerticalType", "ProductCode",
    "MonthlyPrice", "AnnualPrice", "MaxUsers", "MaxTransactions",
    "Description", "Features", "ModuleCodes", "Limits",
    "IsAddon", "IsTrialOnly", "TrialDays",
    "SortOrder", "BillingCycleDefault", "PaddleSyncStatus"
) VALUES (
    'Prueba 30 días', 'erp-trial-30d', 'none', 'erp-core',
    0, 0, 5, 1000,
    'Prueba gratuita de 30 días con todos los módulos del plan Profesional. Sin tarjeta de crédito.',
    '["Todos los módulos del Pro","5 usuarios","30 días","Sin tarjeta de crédito","Soporte por email"]'::JSONB,
    '["dashboard","facturas","clientes","inventario","articulos","reportes","abonos","cxc","compras","cxp","bancos","conciliaciones","pos","documentos-electronicos","contabilidad","nomina","crm"]'::JSONB,
    '{"users":5,"branches":1,"warehouses":2,"storage_gb":5,"invoices_month":200,"transactions_month":1000,"api_calls_day":2000,"pos_cashiers":2,"payroll_employees":10}'::JSONB,
    FALSE, TRUE, 30,
    10, 'monthly', 'skip'
) ON CONFLICT ("Slug") DO UPDATE SET
    "Name"         = EXCLUDED."Name",
    "Description"  = EXCLUDED."Description",
    "IsTrialOnly"  = EXCLUDED."IsTrialOnly",
    "TrialDays"    = EXCLUDED."TrialDays",
    "Features"     = EXCLUDED."Features",
    "ModuleCodes"  = EXCLUDED."ModuleCodes",
    "Limits"       = EXCLUDED."Limits",
    "SortOrder"    = EXCLUDED."SortOrder",
    "PaddleSyncStatus" = EXCLUDED."PaddleSyncStatus",
    "UpdatedAt"    = NOW();

-- ==== TRIALS POR VERTICAL (14 días, estrategia vertical-first) ====
-- Captan leads directo en cada vertical. Luego convierten al plan pago del mismo
-- vertical, y desde ahí se les propone upsell al ERP.

INSERT INTO cfg."PricingPlan" (
    "Name", "Slug", "VerticalType", "ProductCode",
    "MonthlyPrice", "AnnualPrice", "MaxUsers", "MaxTransactions",
    "Description", "Features", "ModuleCodes", "Limits",
    "IsAddon", "IsTrialOnly", "TrialDays",
    "SortOrder", "BillingCycleDefault", "PaddleSyncStatus"
) VALUES
  ('Prueba Medical 14 días', 'medical-trial-14d', 'medical', 'medical',
    0, 0, 5, 500,
    'Prueba gratuita de 14 días con los módulos del plan Clínica. Sin tarjeta.',
    '["Módulos del plan Clínica","5 usuarios","14 días","Sin tarjeta"]'::JSONB,
    '["medical-citas","medical-pacientes","medical-recetas","medical-historia","medical-chat"]'::JSONB,
    '{"users":5,"branches":1,"patients":500,"storage_gb":3,"appointments_month":500}'::JSONB,
    FALSE, TRUE, 14, 5, 'monthly', 'skip'),

  ('Prueba Hotel 14 días', 'hotel-trial-14d', 'hotel', 'hotel',
    0, 0, 3, 200,
    'Prueba gratuita de 14 días con los módulos del plan Hotel Pyme. Sin tarjeta.',
    '["Módulos del plan Pyme","3 usuarios","14 días","Hasta 10 habitaciones"]'::JSONB,
    '["hotel-reservas","hotel-huespedes","hotel-housekeeping","hotel-checkin"]'::JSONB,
    '{"users":3,"rooms":10,"properties":1,"storage_gb":3,"bookings_month":200}'::JSONB,
    FALSE, TRUE, 14, 5, 'monthly', 'skip'),

  ('Prueba Tickets 14 días', 'tickets-trial-14d', 'tickets', 'tickets',
    0, 0, 2, 100,
    'Prueba gratuita de 14 días con los módulos del plan Tickets Básico. Sin tarjeta.',
    '["Módulos del plan Básico","2 usuarios","14 días","100 tickets"]'::JSONB,
    '["tickets-sales","tickets-qr","tickets-dashboard"]'::JSONB,
    '{"users":2,"events_active":2,"tickets_month":100,"storage_gb":1}'::JSONB,
    FALSE, TRUE, 14, 5, 'monthly', 'skip'),

  ('Prueba Educación 14 días', 'edu-trial-14d', 'education', 'education',
    0, 0, 3, 200,
    'Prueba gratuita de 14 días con los módulos del plan Academia. Sin tarjeta.',
    '["Módulos del plan Academia","3 usuarios","14 días","Hasta 50 estudiantes"]'::JSONB,
    '["edu-students","edu-courses","edu-attendance","edu-grades","edu-communications"]'::JSONB,
    '{"users":3,"students":50,"campuses":1,"storage_gb":3,"courses_active":5}'::JSONB,
    FALSE, TRUE, 14, 5, 'monthly', 'skip'),

  ('Prueba Rental 14 días', 'rental-trial-14d', 'rental', 'rental',
    0, 0, 3, 200,
    'Prueba gratuita de 14 días con los módulos del plan Rental Pyme. Sin tarjeta.',
    '["Módulos del plan Pyme","3 usuarios","14 días","Hasta 10 unidades"]'::JSONB,
    '["rental-bookings","rental-contracts","rental-deposits","rental-inventory"]'::JSONB,
    '{"users":3,"units":10,"contracts_active":20,"storage_gb":3,"bookings_month":200}'::JSONB,
    FALSE, TRUE, 14, 5, 'monthly', 'skip')
ON CONFLICT ("Slug") DO UPDATE SET
    "Name"         = EXCLUDED."Name",
    "Description"  = EXCLUDED."Description",
    "IsTrialOnly"  = EXCLUDED."IsTrialOnly",
    "TrialDays"    = EXCLUDED."TrialDays",
    "Features"     = EXCLUDED."Features",
    "ModuleCodes"  = EXCLUDED."ModuleCodes",
    "Limits"       = EXCLUDED."Limits",
    "SortOrder"    = EXCLUDED."SortOrder",
    "PaddleSyncStatus" = EXCLUDED."PaddleSyncStatus",
    "UpdatedAt"    = NOW();

-- ==== RENTAL (add-on nuevo, no existía) ====

INSERT INTO cfg."PricingPlan" (
    "Name", "Slug", "VerticalType", "ProductCode",
    "MonthlyPrice", "AnnualPrice", "MaxUsers", "MaxTransactions",
    "Description", "Features", "ModuleCodes", "Limits",
    "IsAddon", "IsTrialOnly", "TrialDays",
    "SortOrder", "BillingCycleDefault", "PaddleSyncStatus"
) VALUES
  ('Rental Pyme', 'rental-pyme', 'rental', 'rental',
    19.99, 199.00, 5, 1000,
    'Alquileres de corto plazo, contratos, depósitos e inventario.',
    '["5 usuarios","Alquileres","Contratos","Depósitos","Inventario","10 GB almacenamiento"]'::JSONB,
    '["rental-bookings","rental-contracts","rental-deposits","rental-inventory"]'::JSONB,
    '{"users":5,"units":50,"contracts_active":100,"storage_gb":10,"bookings_month":1000}'::JSONB,
    TRUE, FALSE, 0, 10, 'monthly', 'draft'),
  ('Rental Pro', 'rental-pro', 'rental', 'rental',
    49.99, 499.00, 20, 10000,
    'Multi-flota, reportes avanzados, integración con ERP.',
    '["20 usuarios","Flotas ilimitadas","Reportes","Integración ERP","50 GB almacenamiento"]'::JSONB,
    '["rental-bookings","rental-contracts","rental-deposits","rental-inventory","rental-multi-fleet","rental-reports","rental-erp-link"]'::JSONB,
    '{"users":20,"units":0,"contracts_active":0,"storage_gb":50,"bookings_month":0}'::JSONB,
    TRUE, FALSE, 0, 20, 'monthly', 'draft')
ON CONFLICT ("Slug") DO NOTHING;

-- Marcar planes como sync pendiente para que backoffice los suba a Paddle
UPDATE cfg."PricingPlan"
   SET "PaddleSyncStatus" = 'draft', "UpdatedAt" = NOW()
 WHERE "Slug" IN (
       'erp-starter','erp-professional','erp-enterprise',
       'medical-clinic','medical-hospital',
       'tickets-basic','tickets-pro',
       'hotel-pyme','hotel-chain',
       'edu-academy','edu-university',
       'rental-pyme','rental-pro'
 )
 AND "PaddlePriceIdMonthly" = '';

-- ──────────────────────────────────────────────────────────────────────────────
-- 7) Trigger: UpdatedAt automático en cfg."PricingPlan"
-- ──────────────────────────────────────────────────────────────────────────────

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION cfg_pricing_plan_set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    NEW."UpdatedAt" = NOW();
    RETURN NEW;
END;
$$;
-- +goose StatementEnd

DROP TRIGGER IF EXISTS trg_pricing_plan_updated ON cfg."PricingPlan";
CREATE TRIGGER trg_pricing_plan_updated
    BEFORE UPDATE ON cfg."PricingPlan"
    FOR EACH ROW EXECUTE FUNCTION cfg_pricing_plan_set_updated_at();


-- +goose Down
DROP TRIGGER IF EXISTS trg_pricing_plan_updated ON cfg."PricingPlan";
DROP FUNCTION IF EXISTS cfg_pricing_plan_set_updated_at();
DROP TABLE IF EXISTS cfg."TrialUsage";
DROP TABLE IF EXISTS sys."SubscriptionItem";

ALTER TABLE public."Lead"
    DROP COLUMN IF EXISTS "Status",
    DROP COLUMN IF EXISTS "ConvertedAt",
    DROP COLUMN IF EXISTS "ConvertedToCompanyId",
    DROP COLUMN IF EXISTS "IntendedSubdomain",
    DROP COLUMN IF EXISTS "UtmCampaign",
    DROP COLUMN IF EXISTS "UtmMedium",
    DROP COLUMN IF EXISTS "UtmSource",
    DROP COLUMN IF EXISTS "AddonSlugs",
    DROP COLUMN IF EXISTS "PlanSlug",
    DROP COLUMN IF EXISTS "VerticalInterest";

ALTER TABLE sys."Subscription"
    DROP CONSTRAINT IF EXISTS chk_subscription_status,
    DROP CONSTRAINT IF EXISTS chk_subscription_source,
    DROP COLUMN IF EXISTS "ExpiredAt",
    DROP COLUMN IF EXISTS "TrialEndsAt",
    DROP COLUMN IF EXISTS "Source";

ALTER TABLE cfg."PricingPlan"
    DROP CONSTRAINT IF EXISTS chk_pricing_billing_cycle,
    DROP CONSTRAINT IF EXISTS chk_pricing_sync_status,
    DROP COLUMN IF EXISTS "UpdatedAt",
    DROP COLUMN IF EXISTS "PaddleSyncedAt",
    DROP COLUMN IF EXISTS "PaddleSyncError",
    DROP COLUMN IF EXISTS "PaddleSyncStatus",
    DROP COLUMN IF EXISTS "PaddlePriceIdAnnual",
    DROP COLUMN IF EXISTS "PaddlePriceIdMonthly",
    DROP COLUMN IF EXISTS "PaddleProductId",
    DROP COLUMN IF EXISTS "SortOrder",
    DROP COLUMN IF EXISTS "Limits",
    DROP COLUMN IF EXISTS "ModuleCodes",
    DROP COLUMN IF EXISTS "TrialDays",
    DROP COLUMN IF EXISTS "IsTrialOnly",
    DROP COLUMN IF EXISTS "IsAddon",
    DROP COLUMN IF EXISTS "BillingCycleDefault",
    DROP COLUMN IF EXISTS "Description",
    DROP COLUMN IF EXISTS "ProductCode";
