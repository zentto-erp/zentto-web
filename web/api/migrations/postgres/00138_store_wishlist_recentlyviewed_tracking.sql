-- +goose Up
-- FASE 2 — Wishlist persistida + Recently viewed persistido + Order tracking timeline.
--
-- Tablas:
--   store.Wishlist            (customer favorites — sustituye localStorage cuando hay sesión)
--   store.RecentlyViewed      (historial de productos vistos — guest + customer)
--   store.OrderTrackingEvent  (timeline detallado del ciclo de vida del pedido)
--
-- Funciones:
--   usp_store_wishlist_list / toggle
--   usp_store_recently_viewed_list / track
--   usp_store_order_tracking_get / add
--
-- Hooks en SPs existentes:
--   usp_store_order_mark_paid       → emite tracking event ORDER_PAID
--   usp_store_order_set_status      → emite ORDER_SHIPPED / DELIVERED / CANCELLED

-- ─── Tablas ─────────────────────────────────────────────
-- +goose StatementBegin
CREATE TABLE IF NOT EXISTS store."Wishlist" (
  "WishlistId"   bigserial PRIMARY KEY,
  "CompanyId"    integer NOT NULL,
  "CustomerCode" varchar(24) NOT NULL,
  "ProductCode"  varchar(60) NOT NULL,
  "AddedAt"      timestamp DEFAULT (now() AT TIME ZONE 'UTC') NOT NULL,
  UNIQUE ("CompanyId", "CustomerCode", "ProductCode")
);
CREATE INDEX IF NOT EXISTS "IX_store_Wishlist_CustomerCode" ON store."Wishlist" ("CompanyId", "CustomerCode");
-- +goose StatementEnd

-- +goose StatementBegin
CREATE TABLE IF NOT EXISTS store."RecentlyViewed" (
  "RecentlyViewedId" bigserial PRIMARY KEY,
  "CompanyId"        integer NOT NULL,
  "CustomerCode"     varchar(24),                  -- NULL si es guest
  "SessionToken"     varchar(64),                  -- usado para guests; NULL para clientes logueados
  "ProductCode"      varchar(60) NOT NULL,
  "ViewedAt"         timestamp DEFAULT (now() AT TIME ZONE 'UTC') NOT NULL,
  UNIQUE ("CompanyId", "CustomerCode", "SessionToken", "ProductCode")
);
CREATE INDEX IF NOT EXISTS "IX_store_RecentlyViewed_Customer" ON store."RecentlyViewed" ("CompanyId", "CustomerCode", "ViewedAt" DESC);
CREATE INDEX IF NOT EXISTS "IX_store_RecentlyViewed_Session"  ON store."RecentlyViewed" ("CompanyId", "SessionToken", "ViewedAt" DESC);
-- +goose StatementEnd

-- +goose StatementBegin
CREATE TABLE IF NOT EXISTS store."OrderTrackingEvent" (
  "EventId"        bigserial PRIMARY KEY,
  "CompanyId"      integer NOT NULL,
  "DocumentNumber" varchar(60) NOT NULL,
  "EventCode"      varchar(40) NOT NULL,        -- ORDER_CREATED|ORDER_PAID|ORDER_SHIPPED|ORDER_DELIVERED|ORDER_CANCELLED|NOTE
  "EventLabel"     varchar(120) NOT NULL,       -- "Pedido recibido", "Pago confirmado"…
  "Description"    varchar(500),                -- detalle libre (transportista, ref de pago, etc.)
  "OccurredAt"     timestamp DEFAULT (now() AT TIME ZONE 'UTC') NOT NULL,
  "ActorUser"      varchar(60) DEFAULT 'system'
);
CREATE INDEX IF NOT EXISTS "IX_store_OrderTracking_Doc" ON store."OrderTrackingEvent" ("CompanyId", "DocumentNumber", "OccurredAt");
-- +goose StatementEnd

-- ─── Wishlist ────────────────────────────────────────────
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_store_wishlist_list(
  p_company_id    integer DEFAULT 1,
  p_customer_code varchar DEFAULT NULL
)
RETURNS TABLE (
  "productCode" varchar,
  "productName" varchar,
  "imageUrl"    varchar,
  "price"       numeric,
  "stock"       numeric,
  "addedAt"     timestamp
)
LANGUAGE sql STABLE AS $$
  SELECT
    w."ProductCode",
    p."ProductName",
    img."PublicUrl"::varchar,
    p."SalesPrice",
    p."StockQty",
    w."AddedAt"
  FROM store."Wishlist" w
  LEFT JOIN master."Product" p
         ON p."ProductCode" = w."ProductCode"
        AND p."CompanyId"   = w."CompanyId"
  LEFT JOIN LATERAL (
    SELECT ma."PublicUrl"
    FROM cfg."EntityImage" ei
    INNER JOIN cfg."MediaAsset" ma ON ma."MediaAssetId" = ei."MediaAssetId"
    WHERE ei."CompanyId"  = p."CompanyId"
      AND ei."EntityType" = 'MASTER_PRODUCT'
      AND ei."EntityId"   = p."ProductId"
      AND ei."IsDeleted"  = FALSE
      AND ei."IsActive"   = TRUE
      AND ma."IsActive"   = TRUE
    ORDER BY ei."IsPrimary" DESC, ei."SortOrder"
    LIMIT 1
  ) img ON TRUE
  WHERE w."CompanyId"    = p_company_id
    AND w."CustomerCode" = p_customer_code
  ORDER BY w."AddedAt" DESC;
$$;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_store_wishlist_toggle(
  p_company_id    integer DEFAULT 1,
  p_customer_code varchar DEFAULT NULL,
  p_product_code  varchar DEFAULT NULL
)
RETURNS TABLE ("Resultado" integer, "Mensaje" varchar, "InWishlist" boolean)
LANGUAGE plpgsql AS $$
DECLARE
  v_exists boolean;
BEGIN
  IF p_customer_code IS NULL OR p_product_code IS NULL THEN
    RETURN QUERY SELECT 0, 'Missing arguments'::varchar, FALSE;
    RETURN;
  END IF;

  SELECT EXISTS (
    SELECT 1 FROM store."Wishlist"
     WHERE "CompanyId"    = p_company_id
       AND "CustomerCode" = p_customer_code
       AND "ProductCode"  = p_product_code
  ) INTO v_exists;

  IF v_exists THEN
    DELETE FROM store."Wishlist"
     WHERE "CompanyId"    = p_company_id
       AND "CustomerCode" = p_customer_code
       AND "ProductCode"  = p_product_code;
    RETURN QUERY SELECT 1, 'Removed'::varchar, FALSE;
  ELSE
    INSERT INTO store."Wishlist" ("CompanyId", "CustomerCode", "ProductCode")
    VALUES (p_company_id, p_customer_code, p_product_code);
    RETURN QUERY SELECT 1, 'Added'::varchar, TRUE;
  END IF;
END;
$$;
-- +goose StatementEnd

-- ─── Recently viewed ─────────────────────────────────────
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_store_recently_viewed_list(
  p_company_id    integer DEFAULT 1,
  p_customer_code varchar DEFAULT NULL,
  p_session_token varchar DEFAULT NULL,
  p_limit         integer DEFAULT 12
)
RETURNS TABLE (
  "productCode" varchar,
  "productName" varchar,
  "imageUrl"    varchar,
  "price"       numeric,
  "stock"       numeric,
  "viewedAt"    timestamp
)
LANGUAGE sql STABLE AS $$
  SELECT
    rv."ProductCode",
    p."ProductName",
    img."PublicUrl"::varchar,
    p."SalesPrice",
    p."StockQty",
    rv."ViewedAt"
  FROM store."RecentlyViewed" rv
  LEFT JOIN master."Product" p
         ON p."ProductCode" = rv."ProductCode"
        AND p."CompanyId"   = rv."CompanyId"
  LEFT JOIN LATERAL (
    SELECT ma."PublicUrl"
    FROM cfg."EntityImage" ei
    INNER JOIN cfg."MediaAsset" ma ON ma."MediaAssetId" = ei."MediaAssetId"
    WHERE ei."CompanyId"  = p."CompanyId"
      AND ei."EntityType" = 'MASTER_PRODUCT'
      AND ei."EntityId"   = p."ProductId"
      AND ei."IsDeleted"  = FALSE
      AND ei."IsActive"   = TRUE
      AND ma."IsActive"   = TRUE
    ORDER BY ei."IsPrimary" DESC, ei."SortOrder"
    LIMIT 1
  ) img ON TRUE
  WHERE rv."CompanyId" = p_company_id
    AND (
      (p_customer_code IS NOT NULL AND rv."CustomerCode" = p_customer_code) OR
      (p_customer_code IS NULL AND p_session_token IS NOT NULL AND rv."SessionToken" = p_session_token)
    )
  ORDER BY rv."ViewedAt" DESC
  LIMIT GREATEST(p_limit, 1);
$$;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_store_recently_viewed_track(
  p_company_id    integer DEFAULT 1,
  p_customer_code varchar DEFAULT NULL,
  p_session_token varchar DEFAULT NULL,
  p_product_code  varchar DEFAULT NULL,
  p_keep_last     integer DEFAULT 50
)
RETURNS TABLE ("Resultado" integer, "Mensaje" varchar)
LANGUAGE plpgsql AS $$
DECLARE
  v_threshold timestamp;
BEGIN
  IF p_product_code IS NULL OR (p_customer_code IS NULL AND p_session_token IS NULL) THEN
    RETURN QUERY SELECT 0, 'Missing key (customer_code or session_token) or product_code'::varchar;
    RETURN;
  END IF;

  -- Upsert: refrescar timestamp si ya existe el (key, product)
  INSERT INTO store."RecentlyViewed" ("CompanyId", "CustomerCode", "SessionToken", "ProductCode", "ViewedAt")
  VALUES (p_company_id, p_customer_code, p_session_token, p_product_code, NOW() AT TIME ZONE 'UTC')
  ON CONFLICT ("CompanyId", "CustomerCode", "SessionToken", "ProductCode") DO UPDATE
    SET "ViewedAt" = NOW() AT TIME ZONE 'UTC';

  -- Trim: mantener solo los últimos p_keep_last por key
  WITH ranked AS (
    SELECT "RecentlyViewedId",
           ROW_NUMBER() OVER (ORDER BY "ViewedAt" DESC) AS rn
      FROM store."RecentlyViewed"
     WHERE "CompanyId" = p_company_id
       AND (
         (p_customer_code IS NOT NULL AND "CustomerCode" = p_customer_code) OR
         (p_customer_code IS NULL AND "SessionToken" = p_session_token)
       )
  )
  DELETE FROM store."RecentlyViewed"
   WHERE "RecentlyViewedId" IN (SELECT "RecentlyViewedId" FROM ranked WHERE rn > p_keep_last);

  RETURN QUERY SELECT 1, 'OK'::varchar;
EXCEPTION WHEN OTHERS THEN
  RETURN QUERY SELECT -99, SQLERRM::varchar;
END;
$$;
-- +goose StatementEnd

-- ─── Order tracking events ──────────────────────────────
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_store_order_tracking_add(
  p_company_id     integer DEFAULT 1,
  p_document_number varchar DEFAULT NULL,
  p_event_code     varchar DEFAULT NULL,
  p_event_label    varchar DEFAULT NULL,
  p_description    varchar DEFAULT NULL,
  p_actor_user     varchar DEFAULT 'system'
) RETURNS TABLE ("Resultado" integer, "Mensaje" varchar)
LANGUAGE plpgsql AS $$
BEGIN
  IF p_document_number IS NULL OR p_event_code IS NULL THEN
    RETURN QUERY SELECT 0, 'Missing arguments'::varchar;
    RETURN;
  END IF;

  INSERT INTO store."OrderTrackingEvent" (
    "CompanyId", "DocumentNumber", "EventCode", "EventLabel", "Description", "ActorUser"
  ) VALUES (
    p_company_id, p_document_number, p_event_code,
    COALESCE(p_event_label, p_event_code), p_description, COALESCE(p_actor_user, 'system')
  );

  RETURN QUERY SELECT 1, 'OK'::varchar;
EXCEPTION WHEN OTHERS THEN
  RETURN QUERY SELECT -99, SQLERRM::varchar;
END;
$$;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_store_order_tracking_get(
  p_company_id   integer DEFAULT 1,
  p_order_token  varchar DEFAULT NULL,
  p_order_number varchar DEFAULT NULL
)
RETURNS TABLE (
  "documentNumber" varchar,
  "eventCode"      varchar,
  "eventLabel"     varchar,
  "description"    varchar,
  "occurredAt"     timestamp,
  "actorUser"      varchar
)
LANGUAGE plpgsql STABLE AS $$
DECLARE
  v_doc varchar(60);
BEGIN
  IF p_order_number IS NOT NULL AND length(p_order_number) > 0 THEN
    v_doc := p_order_number;
  ELSIF p_order_token IS NOT NULL AND length(p_order_token) > 0 THEN
    SELECT "DocumentNumber" INTO v_doc
      FROM ar."SalesDocument"
     WHERE "OperationType" = 'PEDIDO'
       AND "Notes" ILIKE '%token=' || p_order_token || '%'
     LIMIT 1;
  END IF;

  IF v_doc IS NULL THEN
    RETURN;
  END IF;

  RETURN QUERY
  SELECT
    e."DocumentNumber",
    e."EventCode",
    e."EventLabel",
    e."Description",
    e."OccurredAt",
    e."ActorUser"
  FROM store."OrderTrackingEvent" e
  WHERE e."CompanyId"     = p_company_id
    AND e."DocumentNumber" = v_doc
  ORDER BY e."OccurredAt";
END;
$$;
-- +goose StatementEnd

-- ─── Hooks: emitir eventos en mark_paid + set_status ─────
-- Reemplazo de usp_store_order_mark_paid añadiendo evento ORDER_PAID.
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_store_order_mark_paid(
  p_company_id     integer DEFAULT 1,
  p_order_token    varchar DEFAULT '',
  p_payment_ref    varchar DEFAULT '',
  p_payment_method varchar DEFAULT 'online'
) RETURNS TABLE("Resultado" integer, "Mensaje" character varying)
LANGUAGE plpgsql AS $$
DECLARE
  v_doc_number  varchar(60);
  v_serial_type varchar(60);
  v_total       numeric(18,4);
  v_existing    integer;
  v_new_id      integer;
BEGIN
  SELECT "DocumentNumber", "SerialType", "TotalAmount"
    INTO v_doc_number, v_serial_type, v_total
    FROM ar."SalesDocument"
   WHERE "Notes" ILIKE '%token=' || p_order_token || '%'
     AND "OperationType" = 'PEDIDO'
   LIMIT 1;

  IF v_doc_number IS NULL THEN
    RETURN QUERY SELECT 0, ('Order not found for token ' || p_order_token)::varchar;
    RETURN;
  END IF;

  SELECT COUNT(*)::int INTO v_existing
    FROM ar."SalesDocumentPayment"
   WHERE "DocumentNumber" = v_doc_number
     AND "SerialType"     = v_serial_type
     AND "ReferenceNumber" = p_payment_ref;

  IF v_existing > 0 THEN
    RETURN QUERY SELECT 1, 'Already processed (idempotent)'::varchar;
    RETURN;
  END IF;

  SELECT COALESCE(MAX("PaymentId"), 0) + 1 INTO v_new_id FROM ar."SalesDocumentPayment";

  INSERT INTO ar."SalesDocumentPayment" (
    "PaymentId", "DocumentNumber", "SerialType", "OperationType",
    "PaymentMethod", "Amount", "AmountBs", "ExchangeRate",
    "PaymentDate", "ReferenceNumber", "UserCode"
  ) VALUES (
    v_new_id, v_doc_number, v_serial_type, 'PEDIDO',
    p_payment_method, v_total, v_total, 1.0,
    NOW() AT TIME ZONE 'UTC', p_payment_ref, 'PAYMENTS_MICROSERVICE'
  );

  UPDATE ar."SalesDocument"
     SET "IsPaid"    = 'Y',
         "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
   WHERE "DocumentNumber" = v_doc_number
     AND "SerialType"     = v_serial_type;

  -- Emit tracking event
  PERFORM public.usp_store_order_tracking_add(
    p_company_id, v_doc_number, 'ORDER_PAID', 'Pago confirmado',
    'Ref ' || COALESCE(p_payment_ref, '') || ' (' || COALESCE(p_payment_method, 'online') || ')',
    'PAYMENTS_MICROSERVICE'
  );

  RETURN QUERY SELECT 1, ('Order ' || v_doc_number || ' marked as paid')::varchar;
END;
$$;
-- +goose StatementEnd

-- Reemplazo de usp_store_order_set_status añadiendo evento por status.
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_store_order_set_status(
  p_company_id     integer DEFAULT 1,
  p_order_number   varchar DEFAULT NULL,
  p_status         varchar DEFAULT NULL,
  p_carrier        varchar DEFAULT NULL,
  p_tracking_no    varchar DEFAULT NULL,
  p_actor_user     varchar DEFAULT 'admin'
) RETURNS TABLE (
  "Resultado"     integer,
  "Mensaje"       varchar,
  "CustomerName"  varchar,
  "CustomerEmail" varchar,
  "OrderToken"    varchar,
  "TotalAmount"   numeric,
  "CurrencyCode"  varchar
)
LANGUAGE plpgsql AS $$
DECLARE
  v_doc_id      int;
  v_serial      varchar(60);
  v_notes       varchar(500);
  v_token       varchar(100);
  v_email       varchar(255);
  v_name        varchar(255);
  v_total       numeric(18,4);
  v_currency    varchar(20);
  v_now         timestamp;
  v_event_code  varchar(40);
  v_event_label varchar(120);
  v_event_desc  varchar(500);
BEGIN
  IF p_order_number IS NULL OR p_status IS NULL THEN
    RETURN QUERY SELECT 0, 'Missing arguments'::varchar, NULL::varchar, NULL::varchar, NULL::varchar, NULL::numeric, NULL::varchar;
    RETURN;
  END IF;

  IF LOWER(p_status) NOT IN ('shipped','delivered','cancelled') THEN
    RETURN QUERY SELECT 0, ('Unsupported status ' || p_status)::varchar, NULL::varchar, NULL::varchar, NULL::varchar, NULL::numeric, NULL::varchar;
    RETURN;
  END IF;

  SELECT "DocumentId", "SerialType", "Notes", "CustomerName", "TotalAmount", "CurrencyCode"
    INTO v_doc_id, v_serial, v_notes, v_name, v_total, v_currency
    FROM ar."SalesDocument"
   WHERE "OperationType" = 'PEDIDO'
     AND "DocumentNumber" = p_order_number
   LIMIT 1;

  IF v_doc_id IS NULL THEN
    RETURN QUERY SELECT 0, ('Order ' || p_order_number || ' not found')::varchar, NULL::varchar, NULL::varchar, NULL::varchar, NULL::numeric, NULL::varchar;
    RETURN;
  END IF;

  v_token := SUBSTRING(v_notes FROM 'token=([0-9a-f]+)');

  SELECT "Email"
    INTO v_email
    FROM master."Customer" c
    JOIN ar."SalesDocument" sd ON sd."CustomerCode" = c."CustomerCode"
   WHERE sd."DocumentNumber" = p_order_number
     AND sd."OperationType"  = 'PEDIDO'
   LIMIT 1;

  v_now := NOW() AT TIME ZONE 'UTC';

  IF LOWER(p_status) = 'shipped' THEN
    UPDATE ar."SalesDocument"
       SET "Notes"     = COALESCE("Notes", '') ||
                         ' | shipped=' || TO_CHAR(v_now, 'YYYY-MM-DD') ||
                         CASE WHEN p_carrier IS NOT NULL THEN '/' || p_carrier ELSE '' END ||
                         CASE WHEN p_tracking_no IS NOT NULL THEN '/' || p_tracking_no ELSE '' END,
           "UpdatedAt" = v_now
     WHERE "DocumentId" = v_doc_id;

    v_event_code  := 'ORDER_SHIPPED';
    v_event_label := 'Pedido enviado';
    v_event_desc  := COALESCE(p_carrier, '') ||
                     CASE WHEN p_tracking_no IS NOT NULL THEN ' — guía ' || p_tracking_no ELSE '' END;

  ELSIF LOWER(p_status) = 'delivered' THEN
    UPDATE ar."SalesDocument"
       SET "IsDelivered" = 'Y',
           "Notes"       = COALESCE("Notes", '') || ' | delivered=' || TO_CHAR(v_now, 'YYYY-MM-DD'),
           "UpdatedAt"   = v_now
     WHERE "DocumentId" = v_doc_id;

    v_event_code  := 'ORDER_DELIVERED';
    v_event_label := 'Pedido entregado';
    v_event_desc  := NULL;

  ELSIF LOWER(p_status) = 'cancelled' THEN
    UPDATE ar."SalesDocument"
       SET "IsVoided"  = TRUE,
           "Notes"     = COALESCE("Notes", '') || ' | cancelled=' || TO_CHAR(v_now, 'YYYY-MM-DD') || '/' || p_actor_user,
           "UpdatedAt" = v_now
     WHERE "DocumentId" = v_doc_id;

    v_event_code  := 'ORDER_CANCELLED';
    v_event_label := 'Pedido cancelado';
    v_event_desc  := 'Cancelado por ' || COALESCE(p_actor_user, 'system');
  END IF;

  PERFORM public.usp_store_order_tracking_add(
    p_company_id, p_order_number, v_event_code, v_event_label, v_event_desc, p_actor_user
  );

  RETURN QUERY SELECT
    1,
    ('Order ' || p_order_number || ' marked as ' || p_status)::varchar,
    v_name,
    v_email,
    v_token,
    v_total,
    v_currency;

EXCEPTION WHEN OTHERS THEN
  RETURN QUERY SELECT -99, SQLERRM::varchar, NULL::varchar, NULL::varchar, NULL::varchar, NULL::numeric, NULL::varchar;
END;
$$;
-- +goose StatementEnd


-- +goose Down
DROP FUNCTION IF EXISTS public.usp_store_order_tracking_get(integer, varchar, varchar);
DROP FUNCTION IF EXISTS public.usp_store_order_tracking_add(integer, varchar, varchar, varchar, varchar, varchar);
DROP FUNCTION IF EXISTS public.usp_store_recently_viewed_track(integer, varchar, varchar, varchar, integer);
DROP FUNCTION IF EXISTS public.usp_store_recently_viewed_list(integer, varchar, varchar, integer);
DROP FUNCTION IF EXISTS public.usp_store_wishlist_toggle(integer, varchar, varchar);
DROP FUNCTION IF EXISTS public.usp_store_wishlist_list(integer, varchar);
DROP TABLE IF EXISTS store."OrderTrackingEvent";
DROP TABLE IF EXISTS store."RecentlyViewed";
DROP TABLE IF EXISTS store."Wishlist";
