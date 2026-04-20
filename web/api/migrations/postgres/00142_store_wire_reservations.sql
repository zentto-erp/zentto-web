-- +goose Up
-- PR A — Cablear reserve+commit en ecommerce
--
-- Problema previo (post 00123 multicurrency):
--   usp_store_order_create descontaba stock INLINE (UPDATE master."Product".StockQty)
--   e insertaba SALE_OUT en inv.StockMovement INLINE. Dos bugs:
--     1) Oversell: no había lock → dos usuarios comprando el último producto lo descargaban dos veces
--     2) Stock consumido antes del pago: carritos abandonados bloqueaban stock para siempre
--
-- Solución:
--   usp_store_order_create: RESERVA stock (no descuenta). TTL 60 min.
--     ReferenceType='ECOM_ORDER', ReferenceId=DocumentNumber.
--     Si falla la reserva de cualquier línea → RAISE EXCEPTION → rollback de toda la orden.
--
--   usp_store_order_mark_paid: tras marcar IsPaid='Y', COMMIT de las reservas
--     → genera InventoryMovement SALIDA + decrementa StockQty.
--
--   usp_store_order_cancel (nuevo): RELEASE de reservas + IsCanceled='Y'.
--
--   Cleanup cron (usp_inv_stock_cleanup_expired, ya existe) libera reservas vencidas.

-- =============================================================================
-- 1. usp_store_order_create — reserva en lugar de descontar
-- =============================================================================
-- +goose StatementBegin
DROP FUNCTION IF EXISTS public.usp_store_order_create(
  integer, integer, varchar, varchar, varchar, varchar, varchar, varchar,
  varchar, jsonb, integer, integer, varchar, integer, varchar, varchar,
  varchar, numeric
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
  p_currency_code         varchar DEFAULT NULL,
  p_exchange_rate         numeric DEFAULT NULL,
  p_reserve_ttl_minutes   integer DEFAULT 60
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
  v_item          jsonb;
  v_resv          record;
BEGIN
  v_today := TO_CHAR(NOW() AT TIME ZONE 'UTC', 'YYYYMMDD');

  v_currency := COALESCE(NULLIF(UPPER(p_currency_code), ''), 'USD');
  v_rate     := COALESCE(p_exchange_rate, 1.0);

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

  -- Totales
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

  -- RESERVAR stock por cada línea (antes de consumir).
  -- Si alguna reserva falla → EXCEPTION → toda la tx hace rollback (cabecera + líneas).
  FOR v_item IN
    SELECT item FROM jsonb_array_elements(COALESCE(p_items_json, '[]'::jsonb)) AS item
  LOOP
    SELECT * INTO v_resv
      FROM usp_inv_stock_reserve(
        p_company_id,
        (v_item->>'pc')::VARCHAR,
        (v_item->>'qty')::NUMERIC,
        'ECOM_ORDER'::VARCHAR,
        v_order_number::VARCHAR,
        p_reserve_ttl_minutes,
        NULL::INTEGER
      );

    IF NOT v_resv.ok THEN
      RAISE EXCEPTION 'Reserva falló para producto %: % (disponible=%)',
        v_item->>'pc', v_resv.mensaje, v_resv."Disponible";
    END IF;
  END LOOP;

  RETURN QUERY SELECT v_order_number, v_order_token, 1, 'Pedido creado exitosamente'::varchar;

EXCEPTION WHEN OTHERS THEN
  RETURN QUERY SELECT NULL::varchar, NULL::varchar, -99, SQLERRM::varchar;
END;
$$;
-- +goose StatementEnd


-- =============================================================================
-- 2. usp_store_order_mark_paid — commit de reservas al confirmar pago
-- =============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_store_order_mark_paid(
    p_company_id     INTEGER DEFAULT 1,
    p_order_token    VARCHAR DEFAULT '',
    p_payment_ref    VARCHAR DEFAULT '',
    p_payment_method VARCHAR DEFAULT 'online'
) RETURNS TABLE("Resultado" INTEGER, "Mensaje" VARCHAR)
LANGUAGE plpgsql AS $$
DECLARE
    v_doc_number   VARCHAR(60);
    v_serial_type  VARCHAR(60);
    v_total        NUMERIC(18,4);
    v_existing     INTEGER;
    v_new_id       INTEGER;
    v_resv_rec     RECORD;
    v_commits      INTEGER := 0;
    v_commit_res   RECORD;
BEGIN
    -- 1. Buscar SalesDocument por token
    SELECT "DocumentNumber", "SerialType", "TotalAmount"
      INTO v_doc_number, v_serial_type, v_total
      FROM ar."SalesDocument"
     WHERE "Notes" ILIKE '%token=' || p_order_token || '%'
       AND "OperationType" = 'PEDIDO'
     LIMIT 1;

    IF v_doc_number IS NULL THEN
        RETURN QUERY SELECT 0, ('Order not found for token ' || p_order_token)::VARCHAR;
        RETURN;
    END IF;

    -- 2. Idempotencia
    SELECT COUNT(*)::INT INTO v_existing
      FROM ar."SalesDocumentPayment"
     WHERE "DocumentNumber"   = v_doc_number
       AND "SerialType"       = v_serial_type
       AND "ReferenceNumber"  = p_payment_ref;

    IF v_existing > 0 THEN
        RETURN QUERY SELECT 1, 'Already processed (idempotent)'::VARCHAR;
        RETURN;
    END IF;

    -- 3. Insertar pago
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

    -- 4. Marcar documento pagado
    UPDATE ar."SalesDocument"
       SET "IsPaid"    = 'Y',
           "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
     WHERE "DocumentNumber" = v_doc_number
       AND "SerialType"     = v_serial_type;

    -- 5. Commit de reservas activas → genera movimiento + decrementa stock
    FOR v_resv_rec IN
        SELECT r."ReservationId"
          FROM inv."StockReservation" r
         WHERE r."CompanyId"     = p_company_id
           AND r."ReferenceType" = 'ECOM_ORDER'
           AND r."ReferenceId"   = v_doc_number
           AND r."IsCommitted"   = FALSE
           AND r."IsReleased"    = FALSE
    LOOP
        SELECT * INTO v_commit_res
          FROM usp_inv_stock_commit(v_resv_rec."ReservationId", p_company_id, 0::NUMERIC, NULL::INTEGER);
        IF v_commit_res.ok THEN
            v_commits := v_commits + 1;
        END IF;
    END LOOP;

    RETURN QUERY SELECT 1,
        ('Order ' || v_doc_number || ' marked as paid. Stock commits: ' || v_commits::TEXT)::VARCHAR;
END;
$$;
-- +goose StatementEnd


-- =============================================================================
-- 3. usp_store_order_cancel — libera reservas + marca IsCanceled='Y'
-- =============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_store_order_cancel(
    p_company_id   INTEGER,
    p_order_number VARCHAR,
    p_user_id      INTEGER DEFAULT NULL,
    p_reason       VARCHAR DEFAULT NULL
) RETURNS TABLE("Resultado" INTEGER, "Mensaje" VARCHAR, "ReservasLiberadas" INTEGER)
LANGUAGE plpgsql AS $$
DECLARE
    v_exists      INTEGER;
    v_is_paid     VARCHAR(1);
    v_resv_rec    RECORD;
    v_released    INTEGER := 0;
    v_release_res RECORD;
BEGIN
    -- Validar que exista y no esté pagado
    SELECT COUNT(*)::INT, MAX(COALESCE("IsPaid", 'N'))
      INTO v_exists, v_is_paid
      FROM ar."SalesDocument"
     WHERE "DocumentNumber" = p_order_number
       AND "OperationType"  = 'PEDIDO';

    IF v_exists = 0 THEN
        RETURN QUERY SELECT 0, ('Order ' || p_order_number || ' not found')::VARCHAR, 0;
        RETURN;
    END IF;

    IF v_is_paid = 'Y' THEN
        RETURN QUERY SELECT 0, 'Cannot cancel: order already paid'::VARCHAR, 0;
        RETURN;
    END IF;

    -- Liberar reservas
    FOR v_resv_rec IN
        SELECT r."ReservationId"
          FROM inv."StockReservation" r
         WHERE r."CompanyId"     = p_company_id
           AND r."ReferenceType" = 'ECOM_ORDER'
           AND r."ReferenceId"   = p_order_number
           AND r."IsCommitted"   = FALSE
           AND r."IsReleased"    = FALSE
    LOOP
        SELECT * INTO v_release_res
          FROM usp_inv_stock_release(v_resv_rec."ReservationId", p_company_id);
        IF v_release_res.ok THEN
            v_released := v_released + 1;
        END IF;
    END LOOP;

    -- Marcar cancelado
    UPDATE ar."SalesDocument"
       SET "IsCanceled" = 'Y',
           "Notes"      = COALESCE("Notes", '') || ' | canceled=' || NOW()::TEXT ||
                          CASE WHEN p_reason IS NOT NULL THEN ' reason=' || p_reason ELSE '' END,
           "UpdatedAt"  = NOW() AT TIME ZONE 'UTC'
     WHERE "DocumentNumber" = p_order_number
       AND "OperationType"  = 'PEDIDO';

    RETURN QUERY SELECT 1,
        ('Order ' || p_order_number || ' canceled. Reservas liberadas: ' || v_released::TEXT)::VARCHAR,
        v_released;
END;
$$;
-- +goose StatementEnd


-- +goose Down
-- +goose StatementBegin
DROP FUNCTION IF EXISTS public.usp_store_order_cancel(INTEGER, VARCHAR, INTEGER, VARCHAR);
-- usp_store_order_create y usp_store_order_mark_paid se mantienen.
-- Para revertir completamente, restaurar las versiones previas desde 00122 + 00123.
-- +goose StatementEnd
