-- +goose Up
-- FASE 1.4 — Carrito server-side persistido (sync multi-device).
--
-- store.Cart            → cabecera (customerCode opcional + cartToken siempre)
-- store.CartItem        → líneas
--
-- Funciones:
--   usp_store_cart_get
--   usp_store_cart_upsert_item
--   usp_store_cart_remove_item
--   usp_store_cart_clear
--   usp_store_cart_merge_to_customer

-- +goose StatementBegin
CREATE TABLE IF NOT EXISTS store."Cart" (
  "CartId"        bigserial PRIMARY KEY,
  "CompanyId"     integer NOT NULL,
  "CustomerCode"  varchar(24),
  "CartToken"     varchar(64) NOT NULL UNIQUE,
  "CurrencyCode"  varchar(20) DEFAULT 'USD',
  "CountryCode"   char(2),
  "ExchangeRate"  numeric(18,6) DEFAULT 1,
  "CreatedAt"     timestamp DEFAULT (now() AT TIME ZONE 'UTC') NOT NULL,
  "UpdatedAt"     timestamp DEFAULT (now() AT TIME ZONE 'UTC') NOT NULL
);
CREATE INDEX IF NOT EXISTS "IX_store_Cart_CustomerCode" ON store."Cart" ("CustomerCode");
CREATE INDEX IF NOT EXISTS "IX_store_Cart_CompanyId"    ON store."Cart" ("CompanyId");
-- +goose StatementEnd

-- +goose StatementBegin
CREATE TABLE IF NOT EXISTS store."CartItem" (
  "CartItemId"  bigserial PRIMARY KEY,
  "CartId"      bigint NOT NULL REFERENCES store."Cart"("CartId") ON DELETE CASCADE,
  "ProductCode" varchar(60) NOT NULL,
  "ProductName" varchar(250),
  "ImageUrl"    varchar(500),
  "Quantity"    numeric(18,4) NOT NULL DEFAULT 1,
  "UnitPrice"   numeric(18,4) NOT NULL DEFAULT 0,
  "TaxRate"     numeric(8,4)  DEFAULT 0,
  "AddedAt"     timestamp DEFAULT (now() AT TIME ZONE 'UTC') NOT NULL,
  UNIQUE ("CartId", "ProductCode")
);
CREATE INDEX IF NOT EXISTS "IX_store_CartItem_CartId" ON store."CartItem" ("CartId");
-- +goose StatementEnd

-- ─── usp_store_cart_get ──────────────────────────────────────────
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_store_cart_get(
  p_cart_token  varchar DEFAULT NULL,
  p_company_id  integer DEFAULT 1
)
RETURNS TABLE (
  "cartToken"     varchar,
  "customerCode"  varchar,
  "currencyCode"  varchar,
  "countryCode"   char,
  "exchangeRate"  numeric,
  "updatedAt"     timestamp,
  "productCode"   varchar,
  "productName"   varchar,
  "imageUrl"      varchar,
  "quantity"      numeric,
  "unitPrice"     numeric,
  "taxRate"       numeric
)
LANGUAGE sql STABLE AS $$
  SELECT
    c."CartToken", c."CustomerCode", c."CurrencyCode", c."CountryCode",
    c."ExchangeRate", c."UpdatedAt",
    i."ProductCode", i."ProductName", i."ImageUrl",
    i."Quantity", i."UnitPrice", i."TaxRate"
  FROM store."Cart" c
  LEFT JOIN store."CartItem" i ON i."CartId" = c."CartId"
  WHERE c."CartToken" = p_cart_token
    AND c."CompanyId" = p_company_id
  ORDER BY i."AddedAt" DESC NULLS LAST;
$$;
-- +goose StatementEnd

-- ─── usp_store_cart_upsert_item ──────────────────────────────────
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_store_cart_upsert_item(
  p_cart_token    varchar DEFAULT NULL,
  p_company_id    integer DEFAULT 1,
  p_customer_code varchar DEFAULT NULL,
  p_product_code  varchar DEFAULT NULL,
  p_product_name  varchar DEFAULT NULL,
  p_image_url     varchar DEFAULT NULL,
  p_quantity      numeric DEFAULT 1,
  p_unit_price    numeric DEFAULT 0,
  p_tax_rate      numeric DEFAULT 0,
  p_currency_code varchar DEFAULT NULL,
  p_country_code  char    DEFAULT NULL,
  p_exchange_rate numeric DEFAULT NULL
) RETURNS TABLE ("Resultado" integer, "Mensaje" varchar, "CartId" bigint)
LANGUAGE plpgsql AS $$
DECLARE
  v_cart_id bigint;
BEGIN
  IF p_cart_token IS NULL OR p_product_code IS NULL THEN
    RETURN QUERY SELECT 0, 'Missing cart_token or product_code'::varchar, NULL::bigint;
    RETURN;
  END IF;

  -- Crear cart si no existe
  INSERT INTO store."Cart" ("CompanyId", "CustomerCode", "CartToken",
                            "CurrencyCode", "CountryCode", "ExchangeRate")
  VALUES (p_company_id, p_customer_code, p_cart_token,
          COALESCE(p_currency_code, 'USD'), p_country_code, COALESCE(p_exchange_rate, 1.0))
  ON CONFLICT ("CartToken") DO UPDATE
    SET "CustomerCode"  = COALESCE(EXCLUDED."CustomerCode", store."Cart"."CustomerCode"),
        "CurrencyCode"  = COALESCE(EXCLUDED."CurrencyCode", store."Cart"."CurrencyCode"),
        "CountryCode"   = COALESCE(EXCLUDED."CountryCode",  store."Cart"."CountryCode"),
        "ExchangeRate"  = COALESCE(EXCLUDED."ExchangeRate", store."Cart"."ExchangeRate"),
        "UpdatedAt"     = NOW() AT TIME ZONE 'UTC'
  RETURNING "CartId" INTO v_cart_id;

  IF v_cart_id IS NULL THEN
    SELECT "CartId" INTO v_cart_id FROM store."Cart" WHERE "CartToken" = p_cart_token;
  END IF;

  IF p_quantity <= 0 THEN
    DELETE FROM store."CartItem" WHERE "CartId" = v_cart_id AND "ProductCode" = p_product_code;
  ELSE
    INSERT INTO store."CartItem" ("CartId", "ProductCode", "ProductName", "ImageUrl",
                                  "Quantity", "UnitPrice", "TaxRate")
    VALUES (v_cart_id, p_product_code, p_product_name, p_image_url,
            p_quantity, p_unit_price, COALESCE(p_tax_rate, 0))
    ON CONFLICT ("CartId", "ProductCode") DO UPDATE
      SET "Quantity"    = EXCLUDED."Quantity",
          "UnitPrice"   = EXCLUDED."UnitPrice",
          "TaxRate"     = COALESCE(EXCLUDED."TaxRate", store."CartItem"."TaxRate"),
          "ProductName" = COALESCE(EXCLUDED."ProductName", store."CartItem"."ProductName"),
          "ImageUrl"    = COALESCE(EXCLUDED."ImageUrl", store."CartItem"."ImageUrl");
  END IF;

  UPDATE store."Cart" SET "UpdatedAt" = NOW() AT TIME ZONE 'UTC' WHERE "CartId" = v_cart_id;

  RETURN QUERY SELECT 1, 'OK'::varchar, v_cart_id;
EXCEPTION WHEN OTHERS THEN
  RETURN QUERY SELECT -99, SQLERRM::varchar, NULL::bigint;
END;
$$;
-- +goose StatementEnd

-- ─── usp_store_cart_remove_item ─────────────────────────────────
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_store_cart_remove_item(
  p_cart_token   varchar DEFAULT NULL,
  p_company_id   integer DEFAULT 1,
  p_product_code varchar DEFAULT NULL
) RETURNS TABLE ("Resultado" integer, "Mensaje" varchar)
LANGUAGE plpgsql AS $$
DECLARE
  v_cart_id bigint;
BEGIN
  SELECT "CartId" INTO v_cart_id FROM store."Cart"
    WHERE "CartToken" = p_cart_token AND "CompanyId" = p_company_id;
  IF v_cart_id IS NULL THEN
    RETURN QUERY SELECT 0, 'Cart not found'::varchar;
    RETURN;
  END IF;

  DELETE FROM store."CartItem" WHERE "CartId" = v_cart_id AND "ProductCode" = p_product_code;
  UPDATE store."Cart" SET "UpdatedAt" = NOW() AT TIME ZONE 'UTC' WHERE "CartId" = v_cart_id;

  RETURN QUERY SELECT 1, 'OK'::varchar;
END;
$$;
-- +goose StatementEnd

-- ─── usp_store_cart_clear ──────────────────────────────────────
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_store_cart_clear(
  p_cart_token varchar DEFAULT NULL,
  p_company_id integer DEFAULT 1
) RETURNS TABLE ("Resultado" integer, "Mensaje" varchar)
LANGUAGE plpgsql AS $$
DECLARE
  v_cart_id bigint;
BEGIN
  SELECT "CartId" INTO v_cart_id FROM store."Cart"
    WHERE "CartToken" = p_cart_token AND "CompanyId" = p_company_id;
  IF v_cart_id IS NULL THEN
    RETURN QUERY SELECT 0, 'Cart not found'::varchar;
    RETURN;
  END IF;
  DELETE FROM store."CartItem" WHERE "CartId" = v_cart_id;
  UPDATE store."Cart" SET "UpdatedAt" = NOW() AT TIME ZONE 'UTC' WHERE "CartId" = v_cart_id;
  RETURN QUERY SELECT 1, 'OK'::varchar;
END;
$$;
-- +goose StatementEnd

-- ─── usp_store_cart_merge_to_customer ──────────────────────────
-- Asocia el cart de un guest a un customer existente. Si el customer ya
-- tiene cart, fusiona los ítems (suma cantidades) y elimina el guest cart.
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_store_cart_merge_to_customer(
  p_cart_token    varchar DEFAULT NULL,
  p_company_id    integer DEFAULT 1,
  p_customer_code varchar DEFAULT NULL
) RETURNS TABLE ("Resultado" integer, "Mensaje" varchar, "MergedCartToken" varchar)
LANGUAGE plpgsql AS $$
DECLARE
  v_guest_cart bigint;
  v_cust_cart  bigint;
  v_cust_token varchar(64);
BEGIN
  SELECT "CartId" INTO v_guest_cart
    FROM store."Cart"
   WHERE "CartToken" = p_cart_token AND "CompanyId" = p_company_id;
  IF v_guest_cart IS NULL THEN
    RETURN QUERY SELECT 0, 'Guest cart not found'::varchar, NULL::varchar;
    RETURN;
  END IF;

  SELECT "CartId", "CartToken"
    INTO v_cust_cart, v_cust_token
    FROM store."Cart"
   WHERE "CustomerCode" = p_customer_code AND "CompanyId" = p_company_id
   ORDER BY "UpdatedAt" DESC
   LIMIT 1;

  IF v_cust_cart IS NULL THEN
    -- No hay cart del customer → asignar el guest cart al customer
    UPDATE store."Cart"
       SET "CustomerCode" = p_customer_code,
           "UpdatedAt"    = NOW() AT TIME ZONE 'UTC'
     WHERE "CartId" = v_guest_cart;
    RETURN QUERY SELECT 1, 'Guest cart assigned to customer'::varchar, p_cart_token;
    RETURN;
  END IF;

  -- Merge: por cada item del guest, sumar al customer
  INSERT INTO store."CartItem" ("CartId", "ProductCode", "ProductName", "ImageUrl",
                                "Quantity", "UnitPrice", "TaxRate")
  SELECT v_cust_cart, gi."ProductCode", gi."ProductName", gi."ImageUrl",
         gi."Quantity", gi."UnitPrice", gi."TaxRate"
    FROM store."CartItem" gi
   WHERE gi."CartId" = v_guest_cart
  ON CONFLICT ("CartId", "ProductCode") DO UPDATE
    SET "Quantity"    = store."CartItem"."Quantity" + EXCLUDED."Quantity",
        "ProductName" = COALESCE(EXCLUDED."ProductName", store."CartItem"."ProductName"),
        "ImageUrl"    = COALESCE(EXCLUDED."ImageUrl", store."CartItem"."ImageUrl");

  -- Eliminar guest cart (CASCADE elimina los items)
  DELETE FROM store."Cart" WHERE "CartId" = v_guest_cart;

  UPDATE store."Cart" SET "UpdatedAt" = NOW() AT TIME ZONE 'UTC' WHERE "CartId" = v_cust_cart;

  RETURN QUERY SELECT 1, 'Carts merged'::varchar, v_cust_token;
END;
$$;
-- +goose StatementEnd


-- +goose Down
DROP FUNCTION IF EXISTS public.usp_store_cart_merge_to_customer(varchar, integer, varchar);
DROP FUNCTION IF EXISTS public.usp_store_cart_clear(varchar, integer);
DROP FUNCTION IF EXISTS public.usp_store_cart_remove_item(varchar, integer, varchar);
DROP FUNCTION IF EXISTS public.usp_store_cart_upsert_item(
  varchar, integer, varchar, varchar, varchar, varchar, numeric, numeric, numeric, varchar, char, numeric
);
DROP FUNCTION IF EXISTS public.usp_store_cart_get(varchar, integer);
DROP TABLE IF EXISTS store."CartItem";
DROP TABLE IF EXISTS store."Cart";
