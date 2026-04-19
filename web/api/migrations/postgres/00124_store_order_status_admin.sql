-- +goose Up
-- FASE 1.3 — Cambio de status de pedido (admin) + listado admin con filtros.
--
-- Status soportados (mapeo a columnas existentes en ar.SalesDocument):
--   shipped    → ShipToAddress sin tocar; Notes += " | shipped=YYYY-MM-DD"; columna IsDelivered queda 'N'
--   delivered  → IsDelivered = 'Y'
--   cancelled  → IsVoided = TRUE
--
-- Devuelve datos de notificación (CustomerName/email) para que el caller dispare email.

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_store_order_set_status(
  p_company_id     integer DEFAULT 1,
  p_order_number   varchar DEFAULT NULL,
  p_status         varchar DEFAULT NULL,            -- shipped|delivered|cancelled
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

  -- Token + email del Notes (fallback: customer code lookup)
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

  ELSIF LOWER(p_status) = 'delivered' THEN
    UPDATE ar."SalesDocument"
       SET "IsDelivered" = 'Y',
           "Notes"       = COALESCE("Notes", '') || ' | delivered=' || TO_CHAR(v_now, 'YYYY-MM-DD'),
           "UpdatedAt"   = v_now
     WHERE "DocumentId" = v_doc_id;

  ELSIF LOWER(p_status) = 'cancelled' THEN
    UPDATE ar."SalesDocument"
       SET "IsVoided"  = TRUE,
           "Notes"     = COALESCE("Notes", '') || ' | cancelled=' || TO_CHAR(v_now, 'YYYY-MM-DD') || '/' || p_actor_user,
           "UpdatedAt" = v_now
     WHERE "DocumentId" = v_doc_id;
  END IF;

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

-- ─────────────────────────────────────────────────────────────────
-- Listado admin (todas las órdenes — con filtros) usado por backoffice
-- ─────────────────────────────────────────────────────────────────
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_store_order_admin_list(
  p_company_id integer DEFAULT 1,
  p_status     varchar DEFAULT NULL,   -- pending|paid|shipped|delivered|cancelled
  p_from       date    DEFAULT NULL,
  p_to         date    DEFAULT NULL,
  p_search     varchar DEFAULT NULL,
  p_page       integer DEFAULT 1,
  p_limit      integer DEFAULT 25
) RETURNS TABLE (
  "TotalCount"   bigint,
  "orderNumber"  varchar,
  "orderDate"    timestamp,
  "customer"     varchar,
  "currency"     varchar,
  "total"        numeric,
  "isPaid"       varchar,
  "isVoided"     boolean,
  "isDelivered"  varchar,
  "shipped"      boolean,
  "notes"        varchar
)
LANGUAGE plpgsql STABLE AS $$
DECLARE
  v_offset int;
BEGIN
  v_offset := GREATEST((COALESCE(p_page, 1) - 1) * COALESCE(p_limit, 25), 0);

  RETURN QUERY
  WITH base AS (
    SELECT
      sd."DocumentNumber",
      sd."DocumentDate",
      sd."CustomerName",
      sd."CurrencyCode",
      sd."TotalAmount",
      sd."IsPaid",
      sd."IsVoided",
      sd."IsDelivered",
      (sd."Notes" ILIKE '%shipped=%') AS shipped,
      sd."Notes"
    FROM ar."SalesDocument" sd
    WHERE sd."OperationType" = 'PEDIDO'
      AND sd."IsDeleted" = FALSE
      AND (p_from IS NULL OR sd."DocumentDate" >= p_from)
      AND (p_to   IS NULL OR sd."DocumentDate" <  (p_to + INTERVAL '1 day'))
      AND (
        p_search IS NULL
        OR sd."DocumentNumber" ILIKE '%' || p_search || '%'
        OR sd."CustomerName"   ILIKE '%' || p_search || '%'
      )
      AND (
        p_status IS NULL OR
        (LOWER(p_status) = 'pending'   AND sd."IsPaid" = 'N' AND sd."IsVoided" = FALSE) OR
        (LOWER(p_status) = 'paid'      AND sd."IsPaid" = 'Y' AND sd."IsDelivered" = 'N' AND sd."IsVoided" = FALSE AND sd."Notes" NOT ILIKE '%shipped=%') OR
        (LOWER(p_status) = 'shipped'   AND sd."IsPaid" = 'Y' AND sd."IsDelivered" = 'N' AND sd."IsVoided" = FALSE AND sd."Notes" ILIKE '%shipped=%') OR
        (LOWER(p_status) = 'delivered' AND sd."IsDelivered" = 'Y') OR
        (LOWER(p_status) = 'cancelled' AND sd."IsVoided" = TRUE)
      )
  ),
  counted AS (
    SELECT COUNT(*) AS total FROM base
  )
  SELECT
    (SELECT total FROM counted),
    b."DocumentNumber",
    b."DocumentDate",
    b."CustomerName",
    b."CurrencyCode",
    b."TotalAmount",
    b."IsPaid",
    b."IsVoided",
    b."IsDelivered",
    b.shipped,
    b."Notes"
  FROM base b
  ORDER BY b."DocumentDate" DESC
  LIMIT COALESCE(p_limit, 25)
  OFFSET v_offset;
END;
$$;
-- +goose StatementEnd

-- +goose Down
DROP FUNCTION IF EXISTS public.usp_store_order_set_status(integer, varchar, varchar, varchar, varchar, varchar);
DROP FUNCTION IF EXISTS public.usp_store_order_admin_list(integer, varchar, date, date, varchar, integer, integer);
