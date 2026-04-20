-- +goose Up
-- Programa de afiliados + tasas de comisión por categoría.
--
-- Tablas:
--   store.Affiliate                — afiliados registrados
--   store.AffiliateClick           — tracking de clicks con referral_code
--   store.AffiliateCommission      — comisiones generadas por orden
--   store.AffiliatePayout          — lotes de pago
--   store.AffiliateCommissionRate  — tasas por categoría
--
-- Funciones:
--   usp_store_affiliate_register
--   usp_store_affiliate_get_dashboard
--   usp_store_affiliate_generate_link
--   usp_store_affiliate_track_click
--   usp_store_affiliate_attribute_order
--   usp_store_affiliate_payout_generate
--   usp_store_affiliate_commissions_list
--   usp_store_affiliate_commission_rates_list
--   usp_store_affiliate_admin_list
--   usp_store_affiliate_admin_set_status

-- ─── Tablas ──────────────────────────────────────────────
-- +goose StatementBegin
CREATE TABLE IF NOT EXISTS store."AffiliateCommissionRate" (
  "Id"          bigserial PRIMARY KEY,
  "Category"    varchar(80) NOT NULL UNIQUE,
  "Rate"        numeric(5,2) NOT NULL DEFAULT 0,
  "IsDefault"   boolean NOT NULL DEFAULT false,
  "CreatedAt"   timestamp DEFAULT (now() AT TIME ZONE 'UTC') NOT NULL,
  "UpdatedAt"   timestamp DEFAULT (now() AT TIME ZONE 'UTC') NOT NULL
);
-- +goose StatementEnd

-- +goose StatementBegin
CREATE TABLE IF NOT EXISTS store."Affiliate" (
  "Id"             bigserial PRIMARY KEY,
  "CustomerId"     integer,
  "CompanyId"      integer NOT NULL DEFAULT 1,
  "ReferralCode"   varchar(20) NOT NULL UNIQUE,
  "Status"         varchar(20) NOT NULL DEFAULT 'pending'
                   CHECK ("Status" IN ('active','suspended','pending','rejected')),
  "PayoutMethod"   varchar(30),
  "PayoutDetails"  jsonb,
  "TaxId"          varchar(40),
  "LegalName"      varchar(200),
  "ContactEmail"   varchar(200),
  "CreatedAt"      timestamp DEFAULT (now() AT TIME ZONE 'UTC') NOT NULL,
  "ApprovedAt"     timestamp,
  "ApprovedBy"     varchar(60)
);
CREATE INDEX IF NOT EXISTS "IX_store_Affiliate_Customer" ON store."Affiliate" ("CompanyId","CustomerId");
CREATE INDEX IF NOT EXISTS "IX_store_Affiliate_Status"   ON store."Affiliate" ("CompanyId","Status");
-- +goose StatementEnd

-- +goose StatementBegin
CREATE TABLE IF NOT EXISTS store."AffiliateClick" (
  "Id"             bigserial PRIMARY KEY,
  "ReferralCode"   varchar(20) NOT NULL,
  "AffiliateId"    bigint REFERENCES store."Affiliate"("Id") ON DELETE SET NULL,
  "SessionId"      varchar(100),
  "CustomerId"     integer,
  "Ip"             varchar(45),
  "UserAgent"      varchar(500),
  "Referer"        varchar(500),
  "CreatedAt"      timestamptz DEFAULT (now() AT TIME ZONE 'UTC') NOT NULL
);
CREATE INDEX IF NOT EXISTS "IX_store_AffiliateClick_Code"    ON store."AffiliateClick" ("ReferralCode","CreatedAt" DESC);
CREATE INDEX IF NOT EXISTS "IX_store_AffiliateClick_Session" ON store."AffiliateClick" ("SessionId","CreatedAt" DESC);
-- +goose StatementEnd

-- +goose StatementBegin
CREATE TABLE IF NOT EXISTS store."AffiliateCommission" (
  "Id"                bigserial PRIMARY KEY,
  "AffiliateId"       bigint NOT NULL REFERENCES store."Affiliate"("Id"),
  "CompanyId"         integer NOT NULL DEFAULT 1,
  "OrderNumber"       varchar(60) NOT NULL,
  "Rate"              numeric(5,2) NOT NULL,
  "Category"          varchar(80),
  "CommissionAmount"  numeric(14,2) NOT NULL DEFAULT 0,
  "CurrencyCode"      char(3) NOT NULL DEFAULT 'USD',
  "Status"            varchar(20) NOT NULL DEFAULT 'pending'
                      CHECK ("Status" IN ('pending','approved','paid','reversed')),
  "ClickId"           bigint REFERENCES store."AffiliateClick"("Id") ON DELETE SET NULL,
  "PayoutId"          bigint,
  "CreatedAt"         timestamp DEFAULT (now() AT TIME ZONE 'UTC') NOT NULL,
  "ApprovedAt"        timestamp,
  "PaidAt"            timestamp
);
CREATE INDEX IF NOT EXISTS "IX_store_AffCommission_Aff"    ON store."AffiliateCommission" ("AffiliateId","Status","CreatedAt" DESC);
CREATE INDEX IF NOT EXISTS "IX_store_AffCommission_Order"  ON store."AffiliateCommission" ("CompanyId","OrderNumber");
-- +goose StatementEnd

-- +goose StatementBegin
CREATE TABLE IF NOT EXISTS store."AffiliatePayout" (
  "Id"              bigserial PRIMARY KEY,
  "AffiliateId"     bigint NOT NULL REFERENCES store."Affiliate"("Id"),
  "CompanyId"       integer NOT NULL DEFAULT 1,
  "PeriodStart"     date NOT NULL,
  "PeriodEnd"       date NOT NULL,
  "TotalAmount"     numeric(14,2) NOT NULL DEFAULT 0,
  "CurrencyCode"    char(3) NOT NULL DEFAULT 'USD',
  "Status"          varchar(20) NOT NULL DEFAULT 'pending'
                    CHECK ("Status" IN ('pending','processing','paid','failed')),
  "PaidAt"          timestamp,
  "TransactionRef"  varchar(100),
  "CreatedAt"       timestamp DEFAULT (now() AT TIME ZONE 'UTC') NOT NULL
);
CREATE INDEX IF NOT EXISTS "IX_store_AffPayout_Aff" ON store."AffiliatePayout" ("AffiliateId","Status","PeriodEnd" DESC);
-- +goose StatementEnd

-- ─── Seed de tasas por categoría ─────────────────────────
-- +goose StatementBegin
INSERT INTO store."AffiliateCommissionRate" ("Category","Rate","IsDefault")
VALUES
  ('Electrónica', 3.00, false),
  ('Ropa',        5.00, false),
  ('Hogar',       7.00, false),
  ('Software',   10.00, false),
  ('default',     3.00, true)
ON CONFLICT ("Category") DO NOTHING;
-- +goose StatementEnd

-- ─── usp_store_affiliate_register ────────────────────────
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_store_affiliate_register(
  p_company_id     integer,
  p_customer_id    integer,
  p_legal_name     varchar,
  p_tax_id         varchar,
  p_contact_email  varchar,
  p_payout_method  varchar,
  p_payout_details jsonb
)
RETURNS TABLE("ok" boolean, "mensaje" text, "referralCode" varchar, "affiliateId" bigint)
LANGUAGE plpgsql AS $$
DECLARE
  v_code      varchar(20);
  v_id        bigint;
  v_exists    bigint;
BEGIN
  IF p_customer_id IS NULL THEN
    RETURN QUERY SELECT false, 'customer_id requerido'::text, NULL::varchar, NULL::bigint;
    RETURN;
  END IF;

  SELECT "Id", "ReferralCode" INTO v_id, v_code
    FROM store."Affiliate"
   WHERE "CompanyId" = p_company_id AND "CustomerId" = p_customer_id
   LIMIT 1;

  IF v_id IS NOT NULL THEN
    RETURN QUERY SELECT true, 'Ya eres afiliado'::text, v_code, v_id;
    RETURN;
  END IF;

  -- Generar código único tipo ZEN-XXXXXX (alfanumérico)
  LOOP
    v_code := 'ZEN-' || UPPER(SUBSTRING(MD5(random()::text || clock_timestamp()::text) FROM 1 FOR 8));
    SELECT COUNT(*) INTO v_exists FROM store."Affiliate" WHERE "ReferralCode" = v_code;
    EXIT WHEN v_exists = 0;
  END LOOP;

  INSERT INTO store."Affiliate" (
    "CompanyId","CustomerId","ReferralCode","Status",
    "PayoutMethod","PayoutDetails","TaxId","LegalName","ContactEmail"
  )
  VALUES (
    p_company_id, p_customer_id, v_code, 'pending',
    p_payout_method, p_payout_details, p_tax_id, p_legal_name, p_contact_email
  )
  RETURNING "Id" INTO v_id;

  RETURN QUERY SELECT true, 'Aplicación recibida. Te notificaremos cuando sea aprobada.'::text, v_code, v_id;
END;
$$;
-- +goose StatementEnd

-- ─── usp_store_affiliate_get_dashboard ───────────────────
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_store_affiliate_get_dashboard(
  p_company_id  integer,
  p_customer_id integer
)
RETURNS TABLE(
  "affiliateId"       bigint,
  "referralCode"      varchar,
  "status"            varchar,
  "legalName"         varchar,
  "clicksTotal"       bigint,
  "conversions"       bigint,
  "pendingAmount"     numeric,
  "approvedAmount"    numeric,
  "paidAmount"        numeric,
  "totalEarned"       numeric,
  "currencyCode"      char,
  "monthlyJson"       jsonb
)
LANGUAGE plpgsql STABLE AS $$
DECLARE
  v_id   bigint;
  v_code varchar(20);
BEGIN
  SELECT "Id","ReferralCode" INTO v_id, v_code
    FROM store."Affiliate"
   WHERE "CompanyId" = p_company_id AND "CustomerId" = p_customer_id;

  IF v_id IS NULL THEN
    RETURN;
  END IF;

  RETURN QUERY
  WITH clicks AS (
    SELECT COUNT(*)::bigint AS total
      FROM store."AffiliateClick"
     WHERE "ReferralCode" = v_code
       AND "CreatedAt" > (now() AT TIME ZONE 'UTC') - INTERVAL '12 months'
  ),
  comm AS (
    SELECT
      COUNT(*) FILTER (WHERE "Status" IN ('approved','paid'))::bigint AS conv,
      COALESCE(SUM("CommissionAmount") FILTER (WHERE "Status" = 'pending'), 0) AS pend,
      COALESCE(SUM("CommissionAmount") FILTER (WHERE "Status" = 'approved'), 0) AS appr,
      COALESCE(SUM("CommissionAmount") FILTER (WHERE "Status" = 'paid'), 0)     AS paid
      FROM store."AffiliateCommission"
     WHERE "AffiliateId" = v_id
  ),
  monthly AS (
    SELECT jsonb_agg(row_to_json(m) ORDER BY m.mon)::jsonb AS data
      FROM (
        SELECT to_char(date_trunc('month', "CreatedAt"), 'YYYY-MM') AS mon,
               COALESCE(SUM("CommissionAmount"),0) AS amount
          FROM store."AffiliateCommission"
         WHERE "AffiliateId" = v_id
           AND "CreatedAt" > (now() AT TIME ZONE 'UTC') - INTERVAL '6 months'
         GROUP BY 1
      ) m
  )
  SELECT
    v_id,
    v_code,
    (SELECT "Status" FROM store."Affiliate" WHERE "Id" = v_id)::varchar,
    (SELECT "LegalName" FROM store."Affiliate" WHERE "Id" = v_id)::varchar,
    (SELECT total FROM clicks),
    (SELECT conv FROM comm),
    (SELECT pend FROM comm),
    (SELECT appr FROM comm),
    (SELECT paid FROM comm),
    ((SELECT pend FROM comm) + (SELECT appr FROM comm) + (SELECT paid FROM comm))::numeric,
    'USD'::char,
    COALESCE((SELECT data FROM monthly), '[]'::jsonb);
END;
$$;
-- +goose StatementEnd

-- ─── usp_store_affiliate_track_click ─────────────────────
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_store_affiliate_track_click(
  p_referral_code varchar,
  p_session_id    varchar,
  p_ip            varchar,
  p_user_agent    varchar,
  p_referer       varchar
)
RETURNS TABLE("ok" boolean, "clickId" bigint)
LANGUAGE plpgsql AS $$
DECLARE
  v_aff_id bigint;
  v_id     bigint;
BEGIN
  SELECT "Id" INTO v_aff_id FROM store."Affiliate" WHERE "ReferralCode" = p_referral_code AND "Status" = 'active';
  IF v_aff_id IS NULL THEN
    RETURN QUERY SELECT false, NULL::bigint;
    RETURN;
  END IF;

  INSERT INTO store."AffiliateClick" (
    "ReferralCode","AffiliateId","SessionId","Ip","UserAgent","Referer"
  )
  VALUES (
    p_referral_code, v_aff_id, p_session_id,
    LEFT(COALESCE(p_ip,''), 45),
    LEFT(COALESCE(p_user_agent,''), 500),
    LEFT(COALESCE(p_referer,''), 500)
  )
  RETURNING "Id" INTO v_id;

  RETURN QUERY SELECT true, v_id;
END;
$$;
-- +goose StatementEnd

-- ─── usp_store_affiliate_attribute_order ─────────────────
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_store_affiliate_attribute_order(
  p_company_id   integer,
  p_order_number varchar,
  p_referral_code varchar,
  p_session_id   varchar,
  p_order_amount numeric,
  p_currency     varchar
)
RETURNS TABLE("ok" boolean, "mensaje" text, "commissionAmount" numeric)
LANGUAGE plpgsql AS $$
DECLARE
  v_aff_id   bigint;
  v_click_id bigint;
  v_rate     numeric(5,2);
  v_category varchar(80);
  v_amount   numeric(14,2);
BEGIN
  -- 1. Buscar afiliado
  SELECT "Id" INTO v_aff_id
    FROM store."Affiliate"
   WHERE "ReferralCode" = p_referral_code AND "Status" = 'active';

  IF v_aff_id IS NULL THEN
    RETURN QUERY SELECT false, 'Afiliado inactivo o no encontrado'::text, 0::numeric;
    RETURN;
  END IF;

  -- 2. Evitar doble atribución para la misma orden
  IF EXISTS (
    SELECT 1 FROM store."AffiliateCommission"
     WHERE "CompanyId" = p_company_id AND "OrderNumber" = p_order_number
  ) THEN
    RETURN QUERY SELECT false, 'Orden ya atribuida'::text, 0::numeric;
    RETURN;
  END IF;

  -- 3. Buscar click activo (últimos 30 días) por session_id + referral_code
  SELECT "Id" INTO v_click_id
    FROM store."AffiliateClick"
   WHERE "ReferralCode" = p_referral_code
     AND ("SessionId" = p_session_id OR p_session_id IS NULL)
     AND "CreatedAt" > (now() AT TIME ZONE 'UTC') - INTERVAL '30 days'
   ORDER BY "CreatedAt" DESC
   LIMIT 1;

  -- 4. Determinar categoría mayoritaria de la orden y tasa
  SELECT p."Category", COALESCE(MAX(cr."Rate"), def."Rate")
    INTO v_category, v_rate
    FROM ar."SalesDocumentLine" l
    LEFT JOIN master."Product" p ON p."ProductCode" = l."ProductCode"
    LEFT JOIN store."AffiliateCommissionRate" cr ON lower(cr."Category") = lower(COALESCE(p."Category",''))
    CROSS JOIN (SELECT "Rate" FROM store."AffiliateCommissionRate" WHERE "IsDefault" = true LIMIT 1) def
   WHERE l."DocumentNumber" = p_order_number
   GROUP BY p."Category", def."Rate"
   ORDER BY COUNT(*) DESC
   LIMIT 1;

  IF v_rate IS NULL THEN
    SELECT "Rate", 'default' INTO v_rate, v_category
      FROM store."AffiliateCommissionRate"
     WHERE "IsDefault" = true
     LIMIT 1;
  END IF;

  v_amount := ROUND(p_order_amount * v_rate / 100.0, 2);

  INSERT INTO store."AffiliateCommission" (
    "AffiliateId","CompanyId","OrderNumber","Rate","Category",
    "CommissionAmount","CurrencyCode","Status","ClickId"
  )
  VALUES (
    v_aff_id, p_company_id, p_order_number, v_rate, COALESCE(v_category,'default'),
    v_amount, COALESCE(p_currency,'USD'), 'pending', v_click_id
  );

  RETURN QUERY SELECT true, 'Comisión registrada'::text, v_amount;
END;
$$;
-- +goose StatementEnd

-- ─── usp_store_affiliate_commissions_list ────────────────
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_store_affiliate_commissions_list(
  p_company_id  integer,
  p_customer_id integer,
  p_status      varchar,
  p_page        integer,
  p_limit       integer
)
RETURNS TABLE(
  "id"             bigint,
  "orderNumber"    varchar,
  "rate"           numeric,
  "category"       varchar,
  "commissionAmount" numeric,
  "currencyCode"   char,
  "status"         varchar,
  "createdAt"      timestamp,
  "paidAt"         timestamp,
  "TotalCount"     bigint
)
LANGUAGE plpgsql STABLE AS $$
DECLARE
  v_aff_id bigint;
  v_page   integer := GREATEST(COALESCE(p_page,1), 1);
  v_limit  integer := LEAST(GREATEST(COALESCE(p_limit,20),1), 100);
  v_offset integer := (v_page - 1) * v_limit;
BEGIN
  SELECT "Id" INTO v_aff_id
    FROM store."Affiliate"
   WHERE "CompanyId" = p_company_id AND "CustomerId" = p_customer_id;
  IF v_aff_id IS NULL THEN
    RETURN;
  END IF;

  RETURN QUERY
  SELECT
    c."Id", c."OrderNumber", c."Rate", c."Category",
    c."CommissionAmount", c."CurrencyCode", c."Status",
    c."CreatedAt", c."PaidAt",
    COUNT(*) OVER()::bigint
  FROM store."AffiliateCommission" c
  WHERE c."AffiliateId" = v_aff_id
    AND (p_status IS NULL OR c."Status" = p_status)
  ORDER BY c."CreatedAt" DESC
  OFFSET v_offset LIMIT v_limit;
END;
$$;
-- +goose StatementEnd

-- ─── usp_store_affiliate_commission_rates_list ───────────
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_store_affiliate_commission_rates_list()
RETURNS TABLE("category" varchar, "rate" numeric, "isDefault" boolean)
LANGUAGE plpgsql STABLE AS $$
BEGIN
  RETURN QUERY
    SELECT "Category", "Rate", "IsDefault"
      FROM store."AffiliateCommissionRate"
     WHERE "IsDefault" = false
     ORDER BY "Rate" ASC;
END;
$$;
-- +goose StatementEnd

-- ─── usp_store_affiliate_admin_list ──────────────────────
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_store_affiliate_admin_list(
  p_company_id integer,
  p_status     varchar,
  p_page       integer,
  p_limit      integer
)
RETURNS TABLE(
  "id"            bigint,
  "referralCode"  varchar,
  "customerId"    integer,
  "legalName"     varchar,
  "contactEmail"  varchar,
  "status"        varchar,
  "taxId"         varchar,
  "createdAt"     timestamp,
  "approvedAt"    timestamp,
  "pendingAmount" numeric,
  "paidAmount"    numeric,
  "TotalCount"    bigint
)
LANGUAGE plpgsql STABLE AS $$
DECLARE
  v_page   integer := GREATEST(COALESCE(p_page,1), 1);
  v_limit  integer := LEAST(GREATEST(COALESCE(p_limit,20),1), 100);
  v_offset integer := (v_page - 1) * v_limit;
BEGIN
  RETURN QUERY
  SELECT
    a."Id", a."ReferralCode", a."CustomerId", a."LegalName", a."ContactEmail",
    a."Status", a."TaxId", a."CreatedAt", a."ApprovedAt",
    COALESCE((SELECT SUM("CommissionAmount") FROM store."AffiliateCommission" WHERE "AffiliateId" = a."Id" AND "Status" = 'pending'), 0),
    COALESCE((SELECT SUM("CommissionAmount") FROM store."AffiliateCommission" WHERE "AffiliateId" = a."Id" AND "Status" = 'paid'), 0),
    COUNT(*) OVER()::bigint
  FROM store."Affiliate" a
  WHERE a."CompanyId" = p_company_id
    AND (p_status IS NULL OR a."Status" = p_status)
  ORDER BY a."CreatedAt" DESC
  OFFSET v_offset LIMIT v_limit;
END;
$$;
-- +goose StatementEnd

-- ─── usp_store_affiliate_admin_set_status ────────────────
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_store_affiliate_admin_set_status(
  p_company_id   integer,
  p_affiliate_id bigint,
  p_status       varchar,
  p_actor        varchar
)
RETURNS TABLE("ok" boolean, "mensaje" text)
LANGUAGE plpgsql AS $$
BEGIN
  IF p_status NOT IN ('active','suspended','pending','rejected') THEN
    RETURN QUERY SELECT false, 'Status inválido'::text;
    RETURN;
  END IF;

  UPDATE store."Affiliate"
     SET "Status" = p_status,
         "ApprovedAt" = CASE WHEN p_status = 'active' THEN (now() AT TIME ZONE 'UTC') ELSE "ApprovedAt" END,
         "ApprovedBy" = CASE WHEN p_status = 'active' THEN p_actor ELSE "ApprovedBy" END
   WHERE "Id" = p_affiliate_id AND "CompanyId" = p_company_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'Afiliado no encontrado'::text;
    RETURN;
  END IF;

  RETURN QUERY SELECT true, 'Estado actualizado'::text;
END;
$$;
-- +goose StatementEnd

-- ─── usp_store_affiliate_admin_commissions_list ──────────
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_store_affiliate_admin_commissions_list(
  p_company_id integer,
  p_status     varchar,
  p_page       integer,
  p_limit      integer
)
RETURNS TABLE(
  "id"               bigint,
  "affiliateId"      bigint,
  "referralCode"     varchar,
  "legalName"        varchar,
  "orderNumber"      varchar,
  "rate"             numeric,
  "category"         varchar,
  "commissionAmount" numeric,
  "currencyCode"     char,
  "status"           varchar,
  "createdAt"        timestamp,
  "TotalCount"       bigint
)
LANGUAGE plpgsql STABLE AS $$
DECLARE
  v_page   integer := GREATEST(COALESCE(p_page,1), 1);
  v_limit  integer := LEAST(GREATEST(COALESCE(p_limit,20),1), 100);
  v_offset integer := (v_page - 1) * v_limit;
BEGIN
  RETURN QUERY
  SELECT
    c."Id", c."AffiliateId", a."ReferralCode", a."LegalName",
    c."OrderNumber", c."Rate", c."Category",
    c."CommissionAmount", c."CurrencyCode", c."Status", c."CreatedAt",
    COUNT(*) OVER()::bigint
  FROM store."AffiliateCommission" c
  JOIN store."Affiliate" a ON a."Id" = c."AffiliateId"
  WHERE c."CompanyId" = p_company_id
    AND (p_status IS NULL OR c."Status" = p_status)
  ORDER BY c."CreatedAt" DESC
  OFFSET v_offset LIMIT v_limit;
END;
$$;
-- +goose StatementEnd

-- ─── usp_store_affiliate_payout_generate ─────────────────
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_store_affiliate_payout_generate(
  p_company_id integer,
  p_from       date,
  p_to         date
)
RETURNS TABLE("ok" boolean, "mensaje" text, "payoutsCreated" integer, "totalAmount" numeric)
LANGUAGE plpgsql AS $$
DECLARE
  v_from date := COALESCE(p_from, date_trunc('month', (now() AT TIME ZONE 'UTC'))::date - INTERVAL '1 month');
  v_to   date := COALESCE(p_to,   date_trunc('month', (now() AT TIME ZONE 'UTC'))::date - INTERVAL '1 day');
  v_count integer := 0;
  v_total numeric := 0;
  rec     record;
  v_payout_id bigint;
BEGIN
  FOR rec IN
    SELECT "AffiliateId", SUM("CommissionAmount") AS total
      FROM store."AffiliateCommission"
     WHERE "CompanyId" = p_company_id
       AND "Status" = 'approved'
       AND "CreatedAt"::date BETWEEN v_from AND v_to
     GROUP BY "AffiliateId"
     HAVING SUM("CommissionAmount") > 0
  LOOP
    INSERT INTO store."AffiliatePayout" (
      "AffiliateId","CompanyId","PeriodStart","PeriodEnd","TotalAmount","Status"
    )
    VALUES (rec."AffiliateId", p_company_id, v_from, v_to, rec.total, 'pending')
    RETURNING "Id" INTO v_payout_id;

    UPDATE store."AffiliateCommission"
       SET "Status" = 'paid', "PaidAt" = (now() AT TIME ZONE 'UTC'), "PayoutId" = v_payout_id
     WHERE "CompanyId" = p_company_id
       AND "AffiliateId" = rec."AffiliateId"
       AND "Status" = 'approved'
       AND "CreatedAt"::date BETWEEN v_from AND v_to;

    v_count := v_count + 1;
    v_total := v_total + rec.total;
  END LOOP;

  RETURN QUERY SELECT true,
    format('%s payout(s) generado(s) por %s período %s a %s', v_count, v_total, v_from, v_to)::text,
    v_count, v_total;
END;
$$;
-- +goose StatementEnd

-- ─── usp_store_affiliate_admin_commissions_bulk_status ───
-- Bulk-approve / bulk-mark-paid para panel de liquidación mensual.
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_store_affiliate_admin_commissions_bulk_status(
  p_company_id integer,
  p_ids        bigint[],
  p_status     varchar,
  p_actor      varchar
)
RETURNS TABLE("ok" boolean, "mensaje" text, "updated" integer)
LANGUAGE plpgsql AS $$
DECLARE
  v_count integer := 0;
BEGIN
  IF p_status NOT IN ('approved','paid','reversed') THEN
    RETURN QUERY SELECT false, 'Status inválido (solo approved/paid/reversed)'::text, 0;
    RETURN;
  END IF;
  IF p_ids IS NULL OR array_length(p_ids, 1) IS NULL THEN
    RETURN QUERY SELECT false, 'Sin comisiones seleccionadas'::text, 0;
    RETURN;
  END IF;

  UPDATE store."AffiliateCommission"
     SET "Status"     = p_status,
         "ApprovedAt" = CASE WHEN p_status = 'approved' AND "ApprovedAt" IS NULL
                             THEN (now() AT TIME ZONE 'UTC') ELSE "ApprovedAt" END,
         "PaidAt"     = CASE WHEN p_status = 'paid' AND "PaidAt" IS NULL
                             THEN (now() AT TIME ZONE 'UTC') ELSE "PaidAt" END
   WHERE "CompanyId" = p_company_id
     AND "Id" = ANY(p_ids);

  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN QUERY SELECT true, format('%s comisión(es) actualizada(s) a %s por %s', v_count, p_status, p_actor)::text, v_count;
END;
$$;
-- +goose StatementEnd

-- ─── Seeds: 3 afiliados ejemplo para QA / demo ───────────
-- +goose StatementBegin
INSERT INTO store."Affiliate" (
  "CompanyId","CustomerId","ReferralCode","Status","PayoutMethod",
  "LegalName","ContactEmail","TaxId","ApprovedAt","ApprovedBy"
)
VALUES
  (1, NULL, 'DEMO001', 'active',    'paypal',
   'Ana Creadora',    'ana.demo@example.com',    'V-18555111', (now() AT TIME ZONE 'UTC'), 'system'),
  (1, NULL, 'DEMO002', 'pending',   'transferencia',
   'Carlos Influencer','carlos.demo@example.com', 'V-17888222', NULL, NULL),
  (1, NULL, 'DEMO003', 'suspended', 'usdt',
   'Marta Review',    'marta.demo@example.com',  'V-16444333', (now() AT TIME ZONE 'UTC') - INTERVAL '90 days', 'system')
ON CONFLICT ("ReferralCode") DO NOTHING;
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
DROP FUNCTION IF EXISTS public.usp_store_affiliate_admin_commissions_bulk_status(integer,bigint[],varchar,varchar);
DROP FUNCTION IF EXISTS public.usp_store_affiliate_payout_generate(integer,date,date);
DROP FUNCTION IF EXISTS public.usp_store_affiliate_admin_commissions_list(integer,varchar,integer,integer);
DROP FUNCTION IF EXISTS public.usp_store_affiliate_admin_set_status(integer,bigint,varchar,varchar);
DROP FUNCTION IF EXISTS public.usp_store_affiliate_admin_list(integer,varchar,integer,integer);
DROP FUNCTION IF EXISTS public.usp_store_affiliate_commission_rates_list();
DROP FUNCTION IF EXISTS public.usp_store_affiliate_commissions_list(integer,integer,varchar,integer,integer);
DROP FUNCTION IF EXISTS public.usp_store_affiliate_attribute_order(integer,varchar,varchar,varchar,numeric,varchar);
DROP FUNCTION IF EXISTS public.usp_store_affiliate_track_click(varchar,varchar,varchar,varchar,varchar);
DROP FUNCTION IF EXISTS public.usp_store_affiliate_get_dashboard(integer,integer);
DROP FUNCTION IF EXISTS public.usp_store_affiliate_register(integer,integer,varchar,varchar,varchar,varchar,jsonb);
DROP TABLE IF EXISTS store."AffiliatePayout";
DROP TABLE IF EXISTS store."AffiliateCommission";
DROP TABLE IF EXISTS store."AffiliateClick";
DROP TABLE IF EXISTS store."Affiliate";
DROP TABLE IF EXISTS store."AffiliateCommissionRate";
-- +goose StatementEnd
