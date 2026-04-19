-- +goose Up
-- FASE 1.2 — Multi-moneda activa para storefront ecommerce.
--
-- 1. usp_store_storefront_countries_list      → países activos (selector header)
-- 2. usp_store_storefront_currencies_list     → monedas activas con tasa vs base de la company
-- 3. usp_store_storefront_country_get         → país + currency + tax default (regla fiscal)
-- 4. usp_store_order_create (REPLACE)         → recibe p_currency_code + p_exchange_rate
--
-- Reusa: cfg.Country, cfg.Currency, cfg.ExchangeRateDaily, fiscal.TaxRate (IsDefault),
-- cfg.Company (FiscalCountryCode, BaseCurrency).
--
-- Bug-fix incluido: usp_store_order_create antes escribía en doc."SalesDocument"
-- (vista legacy → public."DocumentosVenta"), por eso el SP de mark_paid (que busca
-- en ar."SalesDocument") nunca encontraba la orden. Ahora persiste en las tablas
-- canónicas ar."SalesDocument" / ar."SalesDocumentLine".

-- ─────────────────────────────────────────────────────────────────
-- 1) Países activos (para selector)
-- ─────────────────────────────────────────────────────────────────
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_store_storefront_countries_list()
RETURNS TABLE (
  "countryCode"    char(2),
  "countryName"    varchar,
  "currencyCode"   char(3),
  "currencySymbol" varchar,
  "phonePrefix"    varchar,
  "flagEmoji"      varchar,
  "sortOrder"      integer
)
LANGUAGE sql STABLE AS $$
  SELECT "CountryCode", "CountryName", "CurrencyCode", "CurrencySymbol",
         "PhonePrefix", "FlagEmoji", "SortOrder"
    FROM cfg."Country"
   WHERE "IsActive" = TRUE
   ORDER BY "SortOrder", "CountryName";
$$;
-- +goose StatementEnd

-- ─────────────────────────────────────────────────────────────────
-- 2) Monedas activas con tasa contra base de la company
-- ─────────────────────────────────────────────────────────────────
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_store_storefront_currencies_list(
  p_company_id integer DEFAULT 1
)
RETURNS TABLE (
  "currencyCode"   char(3),
  "currencyName"   varchar,
  "symbol"         varchar,
  "rateToBase"     numeric,
  "isBase"         boolean,
  "rateDate"       date
)
LANGUAGE plpgsql STABLE AS $$
DECLARE
  v_base_currency char(3);
  v_base_country  char(2);
BEGIN
  SELECT "BaseCurrency", "FiscalCountryCode"
    INTO v_base_currency, v_base_country
    FROM cfg."Company"
   WHERE "CompanyId" = p_company_id;

  IF v_base_currency IS NULL THEN
    v_base_currency := 'USD';
  END IF;

  RETURN QUERY
  WITH latest AS (
    SELECT DISTINCT ON ("CurrencyCode") "CurrencyCode", "RateToBase", "RateDate"
      FROM cfg."ExchangeRateDaily"
     ORDER BY "CurrencyCode", "RateDate" DESC
  )
  SELECT cur."CurrencyCode",
         cur."CurrencyName",
         COALESCE(cur."Symbol", co."CurrencySymbol", cur."CurrencyCode"::varchar)::varchar,
         COALESCE(l."RateToBase", co."DefaultExchangeRate", 1.0)::numeric AS "rateToBase",
         (cur."CurrencyCode" = v_base_currency)                          AS "isBase",
         COALESCE(l."RateDate", CURRENT_DATE)                             AS "rateDate"
    FROM cfg."Currency" cur
    LEFT JOIN latest l    ON l."CurrencyCode"  = cur."CurrencyCode"
    LEFT JOIN cfg."Country" co
           ON co."CurrencyCode" = cur."CurrencyCode"
          AND co."IsActive"     = TRUE
   WHERE cur."IsActive" = TRUE
   ORDER BY (cur."CurrencyCode" = v_base_currency) DESC, cur."CurrencyCode";
END;
$$;
-- +goose StatementEnd

-- ─────────────────────────────────────────────────────────────────
-- 3) País por código → currency + tax default + regla fiscal
-- ─────────────────────────────────────────────────────────────────
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_store_storefront_country_get(
  p_country_code char(2) DEFAULT 'VE'
)
RETURNS TABLE (
  "countryCode"        char(2),
  "countryName"        varchar,
  "currencyCode"       char(3),
  "currencySymbol"     varchar,
  "referenceCurrency"  char(3),
  "defaultExchangeRate" numeric,
  "pricesIncludeTax"   boolean,
  "specialTaxRate"     numeric,
  "specialTaxEnabled"  boolean,
  "taxAuthorityCode"   varchar,
  "fiscalIdName"       varchar,
  "timeZoneIana"       varchar,
  "phonePrefix"        varchar,
  "flagEmoji"          varchar,
  "defaultTaxCode"     varchar,
  "defaultTaxName"     varchar,
  "defaultTaxRate"     numeric
)
LANGUAGE sql STABLE AS $$
  SELECT
    co."CountryCode",
    co."CountryName",
    co."CurrencyCode",
    co."CurrencySymbol",
    co."ReferenceCurrency",
    co."DefaultExchangeRate",
    co."PricesIncludeTax",
    co."SpecialTaxRate",
    co."SpecialTaxEnabled",
    co."TaxAuthorityCode",
    co."FiscalIdName",
    co."TimeZoneIana",
    co."PhonePrefix",
    co."FlagEmoji",
    tx."TaxCode"::varchar,
    tx."TaxName"::varchar,
    COALESCE(tx."Rate", 0)::numeric
  FROM cfg."Country" co
  LEFT JOIN LATERAL (
    SELECT "TaxCode", "TaxName", "Rate"
      FROM fiscal."TaxRate"
     WHERE "CountryCode" = co."CountryCode"
       AND "IsDefault"   = TRUE
     ORDER BY "SortOrder"
     LIMIT 1
  ) tx ON TRUE
  WHERE co."CountryCode" = UPPER(p_country_code)
    AND co."IsActive"    = TRUE;
$$;
-- +goose StatementEnd

-- ─────────────────────────────────────────────────────────────────
-- 4) usp_store_order_create — multi-moneda + persistencia en ar.*
-- ─────────────────────────────────────────────────────────────────
-- +goose StatementBegin
DROP FUNCTION IF EXISTS public.usp_store_order_create(
  integer, integer, varchar, varchar, varchar, varchar, varchar, varchar,
  varchar, jsonb, integer, integer, varchar, integer, varchar, varchar
);
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_store_order_create(
  p_company_id            integer DEFAULT 1,
  p_branch_id             integer DEFAULT 1,
  p_customer_code         varchar DEFAULT NULL,
  p_customer_name         varchar DEFAULT NULL,
  p_customer_email        varchar DEFAULT NULL,
  p_fiscal_id             varchar DEFAULT NULL,
  p_phone                 varchar DEFAULT NULL,
  p_address               varchar DEFAULT NULL,
  p_notes                 varchar DEFAULT NULL,
  p_items_json            jsonb   DEFAULT NULL,
  p_address_id            integer DEFAULT NULL,
  p_payment_method_id     integer DEFAULT NULL,
  p_payment_method_type   varchar DEFAULT NULL,
  p_billing_address_id    integer DEFAULT NULL,
  p_shipping_address_text varchar DEFAULT NULL,
  p_billing_address_text  varchar DEFAULT NULL,
  p_currency_code         varchar DEFAULT NULL,   -- nuevo
  p_exchange_rate         numeric DEFAULT NULL    -- nuevo
) RETURNS TABLE (
  "OrderNumber" varchar,
  "OrderToken"  varchar,
  "Resultado"   integer,
  "Mensaje"     varchar
)
LANGUAGE plpgsql AS $$
DECLARE
  v_order_number  varchar(60);
  v_order_token   varchar(100);
  v_today         varchar(8);
  v_seq           int;
  v_total_sub     numeric(18,4);
  v_total_tax     numeric(18,4);
  v_doc_id        int;
  v_currency      varchar(20);
  v_rate          numeric(18,6);
BEGIN
  v_today := TO_CHAR(NOW() AT TIME ZONE 'UTC', 'YYYYMMDD');

  -- Resolver moneda y tasa
  v_currency := COALESCE(NULLIF(UPPER(p_currency_code), ''), 'USD');
  v_rate     := COALESCE(p_exchange_rate, 1.0);

  -- Numerador diario (ECOM-YYYYMMDD-NNNN)
  SELECT COALESCE(MAX(
           CASE WHEN RIGHT("DocumentNumber", 4) ~ '^\d+$'
                THEN RIGHT("DocumentNumber", 4)::INT ELSE 0 END
         ), 0) + 1
    INTO v_seq
    FROM ar."SalesDocument"
   WHERE "OperationType" = 'PEDIDO'
     AND "DocumentNumber" LIKE 'ECOM-' || v_today || '-%';

  v_order_number := 'ECOM-' || v_today || '-' || LPAD(v_seq::TEXT, 4, '0');
  v_order_token  := LOWER(REPLACE(gen_random_uuid()::TEXT, '-', ''));

  -- Totales desde JSON
  SELECT COALESCE(SUM((item->>'st')::NUMERIC(18,4)), 0),
         COALESCE(SUM((item->>'ta')::NUMERIC(18,4)), 0)
    INTO v_total_sub, v_total_tax
    FROM jsonb_array_elements(COALESCE(p_items_json, '[]'::jsonb)) AS item;

  -- Cabecera
  SELECT COALESCE(MAX("DocumentId"), 0) + 1 INTO v_doc_id FROM ar."SalesDocument";

  INSERT INTO ar."SalesDocument" (
    "DocumentId", "DocumentNumber", "SerialType", "OperationType",
    "CustomerCode", "CustomerName", "FiscalId",
    "DocumentDate", "DocumentTime",
    "SubTotal", "TaxableAmount", "ExemptAmount",
    "TaxAmount", "TotalAmount", "DiscountAmount",
    "IsVoided", "IsPaid", "IsInvoiced", "IsDelivered",
    "Notes", "CurrencyCode", "ExchangeRate",
    "ShipToAddress",
    "CreatedAt", "UpdatedAt", "IsDeleted"
  ) VALUES (
    v_doc_id, v_order_number, 'ECOM', 'PEDIDO',
    p_customer_code, p_customer_name, COALESCE(p_fiscal_id, ''),
    NOW() AT TIME ZONE 'UTC', TO_CHAR(NOW() AT TIME ZONE 'UTC', 'HH24:MI:SS'),
    v_total_sub, v_total_sub, 0,
    v_total_tax, v_total_sub + v_total_tax, 0,
    FALSE, 'N', 'N', 'N',
    COALESCE(p_notes, '') || ' | token=' || v_order_token,
    v_currency, v_rate,
    COALESCE(p_shipping_address_text, p_address),
    NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC', FALSE
  );

  -- Líneas
  INSERT INTO ar."SalesDocumentLine" (
    "LineId", "DocumentNumber", "SerialType", "OperationType",
    "LineNumber", "ProductCode", "Description",
    "Quantity", "UnitPrice", "DiscountedPrice", "UnitCost",
    "SubTotal", "DiscountAmount", "TotalAmount",
    "TaxRate", "TaxAmount", "IsVoided",
    "CreatedAt", "UpdatedAt", "IsDeleted"
  )
  SELECT
    (COALESCE((SELECT MAX("LineId") FROM ar."SalesDocumentLine"), 0)
       + ROW_NUMBER() OVER ())::int,
    v_order_number, 'ECOM', 'PEDIDO',
    ROW_NUMBER() OVER ()::int,
    (item->>'pc')::varchar(60),
    (item->>'pn')::varchar(255),
    (item->>'qty')::numeric(18,4),
    (item->>'up')::numeric(18,4),
    (item->>'up')::numeric(18,4),
    0,
    (item->>'st')::numeric(18,4),
    0,
    (item->>'st')::numeric(18,4) + (item->>'ta')::numeric(18,4),
    (item->>'tr')::numeric(8,4),
    (item->>'ta')::numeric(18,4),
    FALSE,
    NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC', FALSE
  FROM jsonb_array_elements(COALESCE(p_items_json, '[]'::jsonb)) AS item;

  -- Descontar stock (tolerante a tabla inexistente)
  BEGIN
    UPDATE master."Product" pr
       SET "StockQty" = pr."StockQty" - d.qty
      FROM (
        SELECT (item->>'pc')::varchar(80) AS pc,
               SUM((item->>'qty')::numeric) AS qty
          FROM jsonb_array_elements(p_items_json) AS item
         GROUP BY (item->>'pc')
      ) d
     WHERE d.pc = pr."ProductCode" AND pr."CompanyId" = p_company_id;
  EXCEPTION WHEN undefined_column OR undefined_table THEN
    NULL;
  END;

  -- Movimiento de inventario (best-effort)
  BEGIN
    INSERT INTO inv."StockMovement" (
      "CompanyId", "BranchId", "ProductId",
      "MovementType", "Quantity", "UnitCost", "TotalCost",
      "SourceDocumentType", "SourceDocumentNumber",
      "Notes", "MovementDate", "CreatedAt"
    )
    SELECT
      p_company_id, p_branch_id, pr."ProductId",
      'SALE_OUT',
      (item->>'qty')::numeric(18,4),
      COALESCE(pr."CostPrice", pr."SalesPrice", 0),
      (item->>'qty')::numeric(18,4) * COALESCE(pr."CostPrice", pr."SalesPrice", 0),
      'ECOM_PEDIDO', v_order_number,
      'Pedido ecommerce',
      NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'
    FROM jsonb_array_elements(p_items_json) AS item
    INNER JOIN master."Product" pr
            ON pr."ProductCode" = (item->>'pc')
           AND pr."CompanyId"   = p_company_id;
  EXCEPTION WHEN undefined_table OR undefined_column THEN
    NULL;
  END;

  RETURN QUERY SELECT v_order_number, v_order_token, 1, 'Pedido creado exitosamente'::varchar;

EXCEPTION WHEN OTHERS THEN
  RETURN QUERY SELECT NULL::varchar, NULL::varchar, -99, SQLERRM::varchar;
END;
$$;
-- +goose StatementEnd


-- +goose Down
DROP FUNCTION IF EXISTS public.usp_store_storefront_countries_list();
DROP FUNCTION IF EXISTS public.usp_store_storefront_currencies_list(integer);
DROP FUNCTION IF EXISTS public.usp_store_storefront_country_get(char);
DROP FUNCTION IF EXISTS public.usp_store_order_create(
  integer, integer, varchar, varchar, varchar, varchar, varchar, varchar,
  varchar, jsonb, integer, integer, varchar, integer, varchar, varchar,
  varchar, numeric
);
