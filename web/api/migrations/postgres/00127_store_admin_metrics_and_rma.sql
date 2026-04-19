-- +goose Up
-- FASE 3 — Admin ecommerce métricas + RMA (devoluciones).
--
-- Tablas:
--   store.ReturnRequest         (cabecera de devolución)
--   store.ReturnRequestItem     (líneas)
--
-- Funciones:
--   usp_store_admin_metrics            → dashboard agregado
--   usp_store_admin_order_detail       → detalle completo (header + lines + payments + tracking)
--   usp_store_return_request_create    → cliente solicita devolución
--   usp_store_return_request_list      → lista (filtros por customer | admin)
--   usp_store_return_request_get       → detalle
--   usp_store_return_request_set_status→ admin aprueba / rechaza / procesa
--
-- Status de devolución: requested | approved | rejected | in_transit | received | refunded

-- ─── Tablas RMA ────────────────────────────────────────
-- +goose StatementBegin
CREATE TABLE IF NOT EXISTS store."ReturnRequest" (
  "ReturnId"         bigserial PRIMARY KEY,
  "CompanyId"        integer NOT NULL,
  "OrderNumber"      varchar(60) NOT NULL,
  "CustomerCode"     varchar(24),
  "Status"           varchar(20) DEFAULT 'requested' NOT NULL,
  "Reason"           varchar(500),
  "AdminNotes"       varchar(500),
  "RefundAmount"     numeric(18,4) DEFAULT 0,
  "RefundCurrency"   varchar(20),
  "RefundMethod"     varchar(30),
  "RefundReference"  varchar(100),
  "RequestedAt"      timestamp DEFAULT (now() AT TIME ZONE 'UTC') NOT NULL,
  "UpdatedAt"        timestamp DEFAULT (now() AT TIME ZONE 'UTC') NOT NULL,
  "ProcessedAt"      timestamp,
  "ActorUser"        varchar(60)
);
CREATE INDEX IF NOT EXISTS "IX_store_ReturnRequest_Order"    ON store."ReturnRequest" ("CompanyId", "OrderNumber");
CREATE INDEX IF NOT EXISTS "IX_store_ReturnRequest_Customer" ON store."ReturnRequest" ("CompanyId", "CustomerCode");
CREATE INDEX IF NOT EXISTS "IX_store_ReturnRequest_Status"   ON store."ReturnRequest" ("CompanyId", "Status", "RequestedAt" DESC);
-- +goose StatementEnd

-- +goose StatementBegin
CREATE TABLE IF NOT EXISTS store."ReturnRequestItem" (
  "ReturnItemId" bigserial PRIMARY KEY,
  "ReturnId"     bigint NOT NULL REFERENCES store."ReturnRequest"("ReturnId") ON DELETE CASCADE,
  "LineNumber"   integer,
  "ProductCode"  varchar(60) NOT NULL,
  "ProductName"  varchar(250),
  "Quantity"     numeric(18,4) DEFAULT 1,
  "UnitPrice"    numeric(18,4) DEFAULT 0,
  "Reason"       varchar(250)
);
CREATE INDEX IF NOT EXISTS "IX_store_ReturnRequestItem_Return" ON store."ReturnRequestItem" ("ReturnId");
-- +goose StatementEnd

-- ─── Métricas admin dashboard ──────────────────────────
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_store_admin_metrics(
  p_company_id integer DEFAULT 1,
  p_from       date    DEFAULT NULL,
  p_to         date    DEFAULT NULL
)
RETURNS TABLE (
  "totalOrders"      bigint,
  "pendingOrders"    bigint,
  "paidOrders"       bigint,
  "shippedOrders"    bigint,
  "deliveredOrders"  bigint,
  "cancelledOrders"  bigint,
  "pendingReturns"   bigint,
  "totalRevenueUsd"  numeric,
  "avgTicketUsd"     numeric,
  "lastUpdated"      timestamp
)
LANGUAGE plpgsql STABLE AS $$
DECLARE
  v_from date := COALESCE(p_from, (NOW() AT TIME ZONE 'UTC')::date - INTERVAL '30 days');
  v_to   date := COALESCE(p_to,   (NOW() AT TIME ZONE 'UTC')::date);
BEGIN
  RETURN QUERY
  WITH base AS (
    SELECT sd.*
      FROM ar."SalesDocument" sd
     WHERE sd."OperationType" = 'PEDIDO'
       AND sd."IsDeleted" = FALSE
       AND sd."DocumentDate"::date BETWEEN v_from AND v_to
  ),
  paid AS (
    SELECT COUNT(*) AS qty, COALESCE(SUM(
      CASE WHEN "CurrencyCode" IN ('USD','US$','DOLAR','$') THEN "TotalAmount"
           ELSE "TotalAmount" / NULLIF("ExchangeRate", 0)
      END
    ), 0) AS revenue_usd
      FROM base
     WHERE "IsPaid" = 'Y' AND "IsVoided" = FALSE
  ),
  returns_pending AS (
    SELECT COUNT(*) AS qty
      FROM store."ReturnRequest"
     WHERE "CompanyId" = p_company_id
       AND "Status" IN ('requested','approved','in_transit','received')
  )
  SELECT
    (SELECT COUNT(*) FROM base)::bigint,
    (SELECT COUNT(*) FROM base WHERE "IsPaid" = 'N' AND "IsVoided" = FALSE)::bigint,
    (SELECT COUNT(*) FROM base WHERE "IsPaid" = 'Y' AND "IsDelivered" = 'N' AND "IsVoided" = FALSE)::bigint,
    (SELECT COUNT(*) FROM base WHERE "IsPaid" = 'Y' AND "IsDelivered" = 'N' AND "IsVoided" = FALSE
                              AND "Notes" ILIKE '%shipped=%')::bigint,
    (SELECT COUNT(*) FROM base WHERE "IsDelivered" = 'Y')::bigint,
    (SELECT COUNT(*) FROM base WHERE "IsVoided" = TRUE)::bigint,
    (SELECT qty FROM returns_pending)::bigint,
    (SELECT revenue_usd FROM paid),
    CASE WHEN (SELECT qty FROM paid) > 0
         THEN (SELECT revenue_usd FROM paid) / (SELECT qty FROM paid)
         ELSE 0
    END,
    (NOW() AT TIME ZONE 'UTC');
END;
$$;
-- +goose StatementEnd

-- ─── Admin order detail ────────────────────────────────
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_store_admin_order_detail(
  p_company_id   integer DEFAULT 1,
  p_order_number varchar DEFAULT NULL
)
RETURNS TABLE (
  "orderNumber"   varchar,
  "orderDate"     timestamp,
  "customerCode"  varchar,
  "customerName"  varchar,
  "fiscalId"      varchar,
  "notes"         varchar,
  "currencyCode"  varchar,
  "exchangeRate"  numeric,
  "subtotal"      numeric,
  "taxAmount"     numeric,
  "totalAmount"   numeric,
  "isPaid"        varchar,
  "isVoided"      boolean,
  "isDelivered"   varchar,
  "shipped"       boolean,
  "lineNumber"    integer,
  "productCode"   varchar,
  "productName"   varchar,
  "quantity"      numeric,
  "unitPrice"     numeric,
  "lineTotal"     numeric,
  "paymentId"     integer,
  "paymentMethod" varchar,
  "paymentRef"    varchar,
  "paymentAmount" numeric,
  "paymentDate"   timestamp,
  "eventCode"     varchar,
  "eventLabel"    varchar,
  "eventDescription" varchar,
  "eventOccurredAt"  timestamp
)
LANGUAGE plpgsql STABLE AS $$
BEGIN
  RETURN QUERY
  WITH head AS (
    SELECT * FROM ar."SalesDocument"
     WHERE "OperationType" = 'PEDIDO' AND "DocumentNumber" = p_order_number
     LIMIT 1
  )
  SELECT
    h."DocumentNumber"::varchar,
    h."DocumentDate",
    h."CustomerCode",
    h."CustomerName",
    h."FiscalId",
    h."Notes",
    h."CurrencyCode",
    h."ExchangeRate",
    h."SubTotal",
    h."TaxAmount",
    h."TotalAmount",
    h."IsPaid",
    h."IsVoided",
    h."IsDelivered",
    (h."Notes" ILIKE '%shipped=%'),
    l."LineNumber",
    l."ProductCode",
    l."Description",
    l."Quantity",
    l."UnitPrice",
    l."TotalAmount",
    pay."PaymentId",
    pay."PaymentMethod",
    pay."ReferenceNumber",
    pay."Amount",
    pay."PaymentDate",
    ev."EventCode",
    ev."EventLabel",
    ev."Description",
    ev."OccurredAt"
  FROM head h
  LEFT JOIN ar."SalesDocumentLine" l
         ON l."DocumentNumber" = h."DocumentNumber"
        AND l."SerialType"     = h."SerialType"
  LEFT JOIN ar."SalesDocumentPayment" pay
         ON pay."DocumentNumber" = h."DocumentNumber"
        AND pay."SerialType"     = h."SerialType"
  LEFT JOIN store."OrderTrackingEvent" ev
         ON ev."DocumentNumber" = h."DocumentNumber"
        AND ev."CompanyId"      = p_company_id
  ORDER BY l."LineNumber" NULLS LAST, pay."PaymentId" NULLS LAST, ev."OccurredAt" NULLS LAST;
END;
$$;
-- +goose StatementEnd

-- ─── RMA — crear solicitud de devolución (cliente) ────
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_store_return_request_create(
  p_company_id     integer DEFAULT 1,
  p_order_number   varchar DEFAULT NULL,
  p_customer_code  varchar DEFAULT NULL,
  p_reason         varchar DEFAULT NULL,
  p_items_json     jsonb   DEFAULT NULL
) RETURNS TABLE ("Resultado" integer, "Mensaje" varchar, "ReturnId" bigint)
LANGUAGE plpgsql AS $$
DECLARE
  v_ret_id     bigint;
  v_order_owner varchar(24);
  v_total       numeric(18,4);
  v_currency    varchar(20);
BEGIN
  IF p_order_number IS NULL OR p_customer_code IS NULL THEN
    RETURN QUERY SELECT 0, 'Missing arguments'::varchar, NULL::bigint;
    RETURN;
  END IF;

  -- Validar pertenencia del pedido
  SELECT sd."CustomerCode", sd."TotalAmount", sd."CurrencyCode"
    INTO v_order_owner, v_total, v_currency
    FROM ar."SalesDocument" sd
   WHERE sd."OperationType" = 'PEDIDO'
     AND sd."DocumentNumber" = p_order_number
   LIMIT 1;

  IF v_order_owner IS NULL THEN
    RETURN QUERY SELECT 0, 'Order not found'::varchar, NULL::bigint;
    RETURN;
  END IF;

  IF v_order_owner <> p_customer_code THEN
    RETURN QUERY SELECT 0, 'Order does not belong to customer'::varchar, NULL::bigint;
    RETURN;
  END IF;

  -- Evitar duplicados activos
  IF EXISTS (
    SELECT 1 FROM store."ReturnRequest"
     WHERE "CompanyId"    = p_company_id
       AND "OrderNumber"  = p_order_number
       AND "Status" NOT IN ('rejected','refunded')
  ) THEN
    RETURN QUERY SELECT 0, 'Ya existe una devolución activa para este pedido'::varchar, NULL::bigint;
    RETURN;
  END IF;

  INSERT INTO store."ReturnRequest" (
    "CompanyId", "OrderNumber", "CustomerCode", "Status", "Reason",
    "RefundAmount", "RefundCurrency", "RequestedAt", "ActorUser"
  ) VALUES (
    p_company_id, p_order_number, p_customer_code, 'requested',
    COALESCE(p_reason, ''), v_total, v_currency,
    NOW() AT TIME ZONE 'UTC', p_customer_code
  ) RETURNING "ReturnId" INTO v_ret_id;

  IF p_items_json IS NOT NULL THEN
    INSERT INTO store."ReturnRequestItem" (
      "ReturnId", "LineNumber", "ProductCode", "ProductName",
      "Quantity", "UnitPrice", "Reason"
    )
    SELECT v_ret_id,
           (it->>'lineNumber')::int,
           (it->>'productCode')::varchar(60),
           (it->>'productName')::varchar(250),
           COALESCE((it->>'quantity')::numeric, 1),
           COALESCE((it->>'unitPrice')::numeric, 0),
           (it->>'reason')::varchar(250)
      FROM jsonb_array_elements(p_items_json) AS it;
  END IF;

  -- Emitir evento en tracking del pedido
  PERFORM public.usp_store_order_tracking_add(
    p_company_id, p_order_number, 'NOTE',
    'Devolución solicitada',
    'El cliente solicitó devolución. Motivo: ' || COALESCE(p_reason, 's/d'),
    p_customer_code
  );

  RETURN QUERY SELECT 1, 'Return request created'::varchar, v_ret_id;
EXCEPTION WHEN OTHERS THEN
  RETURN QUERY SELECT -99, SQLERRM::varchar, NULL::bigint;
END;
$$;
-- +goose StatementEnd

-- ─── RMA — list ────────────────────────────────────────
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_store_return_request_list(
  p_company_id    integer DEFAULT 1,
  p_customer_code varchar DEFAULT NULL,     -- NULL = admin (todos)
  p_status        varchar DEFAULT NULL,
  p_page          integer DEFAULT 1,
  p_limit         integer DEFAULT 25
)
RETURNS TABLE (
  "TotalCount"     bigint,
  "returnId"       bigint,
  "orderNumber"    varchar,
  "customerCode"   varchar,
  "status"         varchar,
  "reason"         varchar,
  "refundAmount"   numeric,
  "refundCurrency" varchar,
  "requestedAt"    timestamp,
  "processedAt"    timestamp,
  "itemCount"      bigint
)
LANGUAGE plpgsql STABLE AS $$
DECLARE
  v_offset int := GREATEST((COALESCE(p_page, 1) - 1) * COALESCE(p_limit, 25), 0);
BEGIN
  RETURN QUERY
  WITH base AS (
    SELECT r.*
      FROM store."ReturnRequest" r
     WHERE r."CompanyId" = p_company_id
       AND (p_customer_code IS NULL OR r."CustomerCode" = p_customer_code)
       AND (p_status IS NULL OR r."Status" = LOWER(p_status))
  ),
  counted AS ( SELECT COUNT(*) AS total FROM base )
  SELECT
    (SELECT total FROM counted),
    b."ReturnId",
    b."OrderNumber",
    b."CustomerCode",
    b."Status",
    b."Reason",
    b."RefundAmount",
    b."RefundCurrency",
    b."RequestedAt",
    b."ProcessedAt",
    (SELECT COUNT(*) FROM store."ReturnRequestItem" i WHERE i."ReturnId" = b."ReturnId")
  FROM base b
  ORDER BY b."RequestedAt" DESC
  LIMIT COALESCE(p_limit, 25)
  OFFSET v_offset;
END;
$$;
-- +goose StatementEnd

-- ─── RMA — detalle ─────────────────────────────────────
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_store_return_request_get(
  p_company_id integer DEFAULT 1,
  p_return_id  bigint  DEFAULT NULL
)
RETURNS TABLE (
  "returnId"       bigint,
  "orderNumber"    varchar,
  "customerCode"   varchar,
  "status"         varchar,
  "reason"         varchar,
  "adminNotes"     varchar,
  "refundAmount"   numeric,
  "refundCurrency" varchar,
  "refundMethod"   varchar,
  "refundReference" varchar,
  "requestedAt"    timestamp,
  "processedAt"    timestamp,
  "lineNumber"     integer,
  "productCode"    varchar,
  "productName"    varchar,
  "quantity"       numeric,
  "unitPrice"      numeric,
  "itemReason"     varchar
)
LANGUAGE sql STABLE AS $$
  SELECT
    r."ReturnId", r."OrderNumber", r."CustomerCode", r."Status",
    r."Reason", r."AdminNotes", r."RefundAmount", r."RefundCurrency",
    r."RefundMethod", r."RefundReference", r."RequestedAt", r."ProcessedAt",
    i."LineNumber", i."ProductCode", i."ProductName",
    i."Quantity", i."UnitPrice", i."Reason"
  FROM store."ReturnRequest" r
  LEFT JOIN store."ReturnRequestItem" i ON i."ReturnId" = r."ReturnId"
  WHERE r."CompanyId" = p_company_id
    AND r."ReturnId"  = p_return_id
  ORDER BY i."LineNumber";
$$;
-- +goose StatementEnd

-- ─── RMA — cambio de status (admin) ────────────────────
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_store_return_request_set_status(
  p_company_id      integer DEFAULT 1,
  p_return_id       bigint  DEFAULT NULL,
  p_status          varchar DEFAULT NULL,
  p_admin_notes     varchar DEFAULT NULL,
  p_refund_method   varchar DEFAULT NULL,
  p_refund_reference varchar DEFAULT NULL,
  p_actor_user      varchar DEFAULT 'admin'
) RETURNS TABLE (
  "Resultado"   integer,
  "Mensaje"     varchar,
  "OrderNumber" varchar,
  "CustomerCode" varchar
)
LANGUAGE plpgsql AS $$
DECLARE
  v_order    varchar(60);
  v_customer varchar(24);
BEGIN
  IF p_return_id IS NULL OR p_status IS NULL THEN
    RETURN QUERY SELECT 0, 'Missing arguments'::varchar, NULL::varchar, NULL::varchar;
    RETURN;
  END IF;

  IF LOWER(p_status) NOT IN ('requested','approved','rejected','in_transit','received','refunded') THEN
    RETURN QUERY SELECT 0, ('Invalid status ' || p_status)::varchar, NULL::varchar, NULL::varchar;
    RETURN;
  END IF;

  SELECT "OrderNumber", "CustomerCode"
    INTO v_order, v_customer
    FROM store."ReturnRequest"
   WHERE "CompanyId" = p_company_id AND "ReturnId" = p_return_id;

  IF v_order IS NULL THEN
    RETURN QUERY SELECT 0, 'Return not found'::varchar, NULL::varchar, NULL::varchar;
    RETURN;
  END IF;

  UPDATE store."ReturnRequest"
     SET "Status"          = LOWER(p_status),
         "AdminNotes"      = COALESCE(p_admin_notes, "AdminNotes"),
         "RefundMethod"    = COALESCE(p_refund_method, "RefundMethod"),
         "RefundReference" = COALESCE(p_refund_reference, "RefundReference"),
         "UpdatedAt"       = NOW() AT TIME ZONE 'UTC',
         "ProcessedAt"     = CASE WHEN LOWER(p_status) IN ('refunded','rejected')
                                  THEN NOW() AT TIME ZONE 'UTC'
                                  ELSE "ProcessedAt" END,
         "ActorUser"       = p_actor_user
   WHERE "CompanyId" = p_company_id AND "ReturnId" = p_return_id;

  PERFORM public.usp_store_order_tracking_add(
    p_company_id, v_order, 'NOTE',
    'Devolución: ' || LOWER(p_status),
    COALESCE(p_admin_notes, ''),
    p_actor_user
  );

  RETURN QUERY SELECT 1, ('Return marked as ' || p_status)::varchar, v_order, v_customer;
EXCEPTION WHEN OTHERS THEN
  RETURN QUERY SELECT -99, SQLERRM::varchar, NULL::varchar, NULL::varchar;
END;
$$;
-- +goose StatementEnd


-- +goose Down
DROP FUNCTION IF EXISTS public.usp_store_return_request_set_status(integer, bigint, varchar, varchar, varchar, varchar, varchar);
DROP FUNCTION IF EXISTS public.usp_store_return_request_get(integer, bigint);
DROP FUNCTION IF EXISTS public.usp_store_return_request_list(integer, varchar, varchar, integer, integer);
DROP FUNCTION IF EXISTS public.usp_store_return_request_create(integer, varchar, varchar, varchar, jsonb);
DROP FUNCTION IF EXISTS public.usp_store_admin_order_detail(integer, varchar);
DROP FUNCTION IF EXISTS public.usp_store_admin_metrics(integer, date, date);
DROP TABLE IF EXISTS store."ReturnRequestItem";
DROP TABLE IF EXISTS store."ReturnRequest";
