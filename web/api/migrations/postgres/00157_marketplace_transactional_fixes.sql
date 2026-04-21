-- +goose Up
-- Fix crítico marketplace — cierra 3 bloqueadores P0 de docs/architecture/marketplace-flow-audit.md
--
-- 1. Tabla store.MerchantCommission (análoga a AffiliateCommission) con granularidad
--    línea-a-línea + campos AffiliateDeduction y NetZenttoRevenue.
-- 2. Asegurar ar.SalesDocumentLine."MerchantId" (idempotente — 00151 ya la creó pero
--    dejamos el ADD IF NOT EXISTS por robustez para ambientes que ejecutaron Ola 4
--    de forma parcial).
-- 3. usp_store_order_populate_merchants — popula MerchantId por línea según el
--    store.MerchantProduct que tiene el mismo ProductCode. Post-proceso del checkout.
-- 4. usp_store_merchant_commission_generate — genera registros en MerchantCommission
--    para cada línea con MerchantId. Aplica el fix afiliado+merchant:
--      AffiliateDeduction = MIN(affiliate_commission_per_line, CommissionAmount_zentto)
--      NetZenttoRevenue   = CommissionAmount - AffiliateDeduction  (nunca negativo)
-- 5. usp_store_merchant_payout_generate — análogo al de afiliados.
--    Agrupa approved por merchant + currency, crea MerchantPayout, marca commissions paid.

-- ─── 1. Tabla store.MerchantCommission ───────────────────
-- +goose StatementBegin
CREATE TABLE IF NOT EXISTS store."MerchantCommission" (
  "Id"                 bigserial PRIMARY KEY,
  "CompanyId"          integer NOT NULL DEFAULT 1,
  "MerchantId"         bigint NOT NULL REFERENCES store."Merchant"("Id"),
  "OrderNumber"        varchar(60) NOT NULL,
  "OrderLineId"        integer,           -- FK lógica a ar.SalesDocumentLine.LineId
  "ProductCode"        varchar(64),
  "Category"           varchar(80),
  "GrossAmount"        numeric(14,2) NOT NULL DEFAULT 0,      -- valor de la línea (subtotal)
  "CommissionRate"     numeric(5,2)  NOT NULL DEFAULT 0,      -- % retenido por Zentto
  "CommissionAmount"   numeric(14,2) NOT NULL DEFAULT 0,      -- lo que Zentto retiene bruto
  "MerchantEarning"    numeric(14,2) NOT NULL DEFAULT 0,      -- lo que corresponde al merchant
  "AffiliateDeduction" numeric(14,2) NOT NULL DEFAULT 0,      -- afiliado se descuenta de la commission
  "NetZenttoRevenue"   numeric(14,2) NOT NULL DEFAULT 0,      -- CommissionAmount - AffiliateDeduction
  "CurrencyCode"       char(3) NOT NULL DEFAULT 'USD',
  "Status"             varchar(20) NOT NULL DEFAULT 'pending'
                       CHECK ("Status" IN ('pending','approved','paid','reversed')),
  "PayoutId"           bigint,
  "CreatedAt"          timestamp DEFAULT (now() AT TIME ZONE 'UTC') NOT NULL,
  "ApprovedAt"         timestamp,
  "PaidAt"             timestamp
);
CREATE INDEX IF NOT EXISTS "IX_store_MerchantCommission_MerchantStatus"
  ON store."MerchantCommission" ("MerchantId","Status","CreatedAt" DESC);
CREATE INDEX IF NOT EXISTS "IX_store_MerchantCommission_Order"
  ON store."MerchantCommission" ("CompanyId","OrderNumber");
-- +goose StatementEnd

-- ─── 2. Asegurar MerchantId en SalesDocumentLine (idempotente) ───
-- +goose StatementBegin
ALTER TABLE IF EXISTS ar."SalesDocumentLine"
  ADD COLUMN IF NOT EXISTS "MerchantId" bigint NULL;
CREATE INDEX IF NOT EXISTS "IX_ar_SalesDocumentLine_MerchantId"
  ON ar."SalesDocumentLine" ("MerchantId") WHERE "MerchantId" IS NOT NULL;
-- +goose StatementEnd

-- ─── 3. usp_store_order_populate_merchants ───────────────
-- Popula MerchantId en SalesDocumentLine según el MerchantProduct que coincide por ProductCode.
-- Idempotente: solo actualiza líneas con MerchantId NULL.
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_store_order_populate_merchants(
  p_company_id   integer,
  p_order_number varchar
)
RETURNS TABLE("ok" boolean, "mensaje" text, "linesUpdated" integer)
LANGUAGE plpgsql AS $$
DECLARE
  v_count integer := 0;
BEGIN
  UPDATE ar."SalesDocumentLine" l
     SET "MerchantId" = mp."MerchantId"
    FROM store."MerchantProduct" mp
   WHERE l."DocumentNumber" = p_order_number
     AND l."ProductCode"    = mp."ProductCode"
     AND mp."CompanyId"     = p_company_id
     AND mp."Status"        = 'approved'
     AND l."MerchantId" IS NULL;
  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN QUERY SELECT true, 'ok'::text, v_count;
END;
$$;
-- +goose StatementEnd

-- ─── 4. usp_store_merchant_commission_generate ───────────
-- Para cada línea de la orden con MerchantId set, genera un registro en MerchantCommission.
-- Aplica el fix negocio afiliado+merchant: la commission del afiliado se DESCUENTA del
-- CommissionAmount retenido por Zentto, no del total bruto.
--
-- Fórmula por línea:
--   GrossAmount        = l.SubTotal (valor bruto de la línea)
--   CommissionRate     = merchant.CommissionRate (plano hoy; categoría en Ola E)
--   CommissionAmount   = GrossAmount * rate / 100
--   MerchantEarning    = GrossAmount - CommissionAmount
--   AffiliateDeduction = MIN(affiliate_per_line, CommissionAmount)  ← nunca más que lo retenido
--   NetZenttoRevenue   = CommissionAmount - AffiliateDeduction
--
-- p_affiliate_commission_amount se prorratea entre las líneas con merchant.
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_store_merchant_commission_generate(
  p_company_id                   integer,
  p_order_number                 varchar,
  p_affiliate_commission_amount  numeric DEFAULT 0
)
RETURNS TABLE(
  "ok"                   boolean,
  "mensaje"              text,
  "commissionsCreated"   integer,
  "totalMerchantEarning" numeric,
  "totalZenttoRevenue"   numeric
)
LANGUAGE plpgsql AS $$
DECLARE
  v_count                integer := 0;
  v_total_earning        numeric(14,2) := 0;
  v_total_zentto         numeric(14,2) := 0;
  v_lines_total          integer := 0;
  v_affiliate_per_line   numeric(14,2) := 0;
  v_affiliate_remaining  numeric(14,2) := COALESCE(p_affiliate_commission_amount, 0);
  v_currency             char(3);
  rec                    record;
  v_rate                 numeric(5,2);
  v_commission           numeric(14,2);
  v_earning              numeric(14,2);
  v_affiliate_deduction  numeric(14,2);
  v_net_zentto           numeric(14,2);
BEGIN
  -- Moneda: del SalesDocument (fuente única).
  SELECT COALESCE("CurrencyCode",'USD')
    INTO v_currency
    FROM ar."SalesDocument"
   WHERE "DocumentNumber" = p_order_number
   LIMIT 1;
  IF v_currency IS NULL THEN v_currency := 'USD'; END IF;

  -- Idempotencia: si ya hay commissions para esta orden, no duplicar.
  IF EXISTS (
    SELECT 1 FROM store."MerchantCommission"
     WHERE "CompanyId" = p_company_id AND "OrderNumber" = p_order_number
  ) THEN
    RETURN QUERY SELECT false, 'Orden ya tiene commissions generadas'::text, 0, 0::numeric, 0::numeric;
    RETURN;
  END IF;

  -- Contar líneas con merchant → prorrateo afiliado.
  SELECT COUNT(*)
    INTO v_lines_total
    FROM ar."SalesDocumentLine" l
   WHERE l."DocumentNumber" = p_order_number
     AND l."MerchantId" IS NOT NULL
     AND COALESCE(l."IsVoided", false) = false;

  IF v_lines_total = 0 THEN
    RETURN QUERY SELECT true, 'Sin líneas de merchant en la orden'::text, 0, 0::numeric, 0::numeric;
    RETURN;
  END IF;

  IF v_affiliate_remaining > 0 THEN
    v_affiliate_per_line := ROUND(v_affiliate_remaining / v_lines_total, 2);
  END IF;

  FOR rec IN
    SELECT l."LineId"       AS line_id,
           l."MerchantId"   AS merchant_id,
           l."ProductCode"  AS product_code,
           mp."Category"    AS category,
           COALESCE(l."SubTotal", 0) AS gross,
           m."CommissionRate" AS merchant_rate
      FROM ar."SalesDocumentLine" l
      JOIN store."Merchant" m ON m."Id" = l."MerchantId"
      LEFT JOIN store."MerchantProduct" mp
        ON mp."CompanyId"  = p_company_id
       AND mp."MerchantId" = l."MerchantId"
       AND mp."ProductCode" = l."ProductCode"
     WHERE l."DocumentNumber" = p_order_number
       AND l."MerchantId" IS NOT NULL
       AND COALESCE(l."IsVoided", false) = false
     ORDER BY l."LineId"
  LOOP
    v_rate       := COALESCE(rec.merchant_rate, 12.00);  -- fallback 12%
    v_commission := ROUND(rec.gross * v_rate / 100.0, 2);
    v_earning    := ROUND(rec.gross - v_commission, 2);

    -- Afiliado: nunca descontar más de lo que Zentto retiene en la línea.
    -- Además: el prorrateo puede dejar residuo; consumimos lo que quede del pool.
    v_affiliate_deduction := LEAST(v_affiliate_per_line, v_commission);
    v_affiliate_deduction := LEAST(v_affiliate_deduction, v_affiliate_remaining);
    IF v_affiliate_deduction < 0 THEN v_affiliate_deduction := 0; END IF;
    v_affiliate_remaining := v_affiliate_remaining - v_affiliate_deduction;

    v_net_zentto := v_commission - v_affiliate_deduction;
    IF v_net_zentto < 0 THEN v_net_zentto := 0; END IF;

    INSERT INTO store."MerchantCommission" (
      "CompanyId","MerchantId","OrderNumber","OrderLineId","ProductCode","Category",
      "GrossAmount","CommissionRate","CommissionAmount","MerchantEarning",
      "AffiliateDeduction","NetZenttoRevenue","CurrencyCode","Status"
    )
    VALUES (
      p_company_id, rec.merchant_id, p_order_number, rec.line_id,
      rec.product_code, rec.category,
      rec.gross, v_rate, v_commission, v_earning,
      v_affiliate_deduction, v_net_zentto, v_currency, 'pending'
    );

    v_count := v_count + 1;
    v_total_earning := v_total_earning + v_earning;
    v_total_zentto  := v_total_zentto  + v_net_zentto;
  END LOOP;

  RETURN QUERY SELECT true,
    format('%s commission(es) creada(s) — merchant_earning=%s zentto_net=%s',
           v_count, v_total_earning, v_total_zentto)::text,
    v_count, v_total_earning, v_total_zentto;
END;
$$;
-- +goose StatementEnd

-- ─── 5. usp_store_merchant_payout_generate ───────────────
-- Análogo a usp_store_affiliate_payout_generate: agrupa commissions approved por
-- merchant + currency + período y crea un MerchantPayout. Marca commissions paid.
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_store_merchant_payout_generate(
  p_company_id integer,
  p_from       date,
  p_to         date
)
RETURNS TABLE("ok" boolean, "mensaje" text, "payoutsCreated" integer, "totalAmount" numeric)
LANGUAGE plpgsql AS $$
DECLARE
  v_from      date := COALESCE(p_from, date_trunc('month', (now() AT TIME ZONE 'UTC'))::date - INTERVAL '1 month');
  v_to        date := COALESCE(p_to,   date_trunc('month', (now() AT TIME ZONE 'UTC'))::date - INTERVAL '1 day');
  v_count     integer := 0;
  v_total     numeric(14,2) := 0;
  v_payout_id bigint;
  rec         record;
BEGIN
  FOR rec IN
    SELECT "MerchantId",
           "CurrencyCode",
           SUM("GrossAmount")      AS gross,
           SUM("CommissionAmount") AS commission,
           SUM("MerchantEarning")  AS net_merchant
      FROM store."MerchantCommission"
     WHERE "CompanyId" = p_company_id
       AND "Status"    = 'approved'
       AND "CreatedAt"::date BETWEEN v_from AND v_to
     GROUP BY "MerchantId","CurrencyCode"
    HAVING SUM("MerchantEarning") > 0
  LOOP
    INSERT INTO store."MerchantPayout" (
      "MerchantId","CompanyId","PeriodStart","PeriodEnd",
      "GrossAmount","CommissionAmount","NetAmount","CurrencyCode","Status"
    )
    VALUES (
      rec."MerchantId", p_company_id, v_from, v_to,
      rec.gross, rec.commission, rec.net_merchant, rec."CurrencyCode", 'pending'
    )
    RETURNING "Id" INTO v_payout_id;

    UPDATE store."MerchantCommission"
       SET "Status"   = 'paid',
           "PaidAt"   = (now() AT TIME ZONE 'UTC'),
           "PayoutId" = v_payout_id
     WHERE "CompanyId"    = p_company_id
       AND "MerchantId"   = rec."MerchantId"
       AND "CurrencyCode" = rec."CurrencyCode"
       AND "Status"       = 'approved'
       AND "CreatedAt"::date BETWEEN v_from AND v_to;

    v_count := v_count + 1;
    v_total := v_total + rec.net_merchant;
  END LOOP;

  RETURN QUERY SELECT true,
    format('%s payout(s) merchant generado(s) por %s — período %s a %s',
           v_count, v_total, v_from, v_to)::text,
    v_count, v_total;
END;
$$;
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
DROP FUNCTION IF EXISTS public.usp_store_merchant_payout_generate(integer,date,date);
DROP FUNCTION IF EXISTS public.usp_store_merchant_commission_generate(integer,varchar,numeric);
DROP FUNCTION IF EXISTS public.usp_store_order_populate_merchants(integer,varchar);
DROP TABLE IF EXISTS store."MerchantCommission";
-- No se dropea la columna ar.SalesDocumentLine.MerchantId porque la creó 00151.
-- +goose StatementEnd
