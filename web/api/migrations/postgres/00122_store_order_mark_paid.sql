-- +goose Up
-- SP idempotente para marcar orden ecommerce como pagada (recibido del callback
-- del microservicio zentto-payments cuando un pago se confirma).
--
-- Lógica:
--  1. Buscar SalesDocument por OrderToken (almacenado en campo Notes con prefijo "token=")
--  2. Si ya hay un SalesDocumentPayment con ese ReferenceNumber → idempotente, skip
--  3. INSERT pago en ar.SalesDocumentPayment
--  4. UPDATE ar.SalesDocument SET IsPaid='Y'

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
  -- 1. Buscar el SalesDocument que tiene este token en Notes
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

  -- 2. Idempotencia: si ya hay payment con ese ReferenceNumber, no duplicar
  SELECT COUNT(*)::int INTO v_existing
    FROM ar."SalesDocumentPayment"
   WHERE "DocumentNumber" = v_doc_number
     AND "SerialType"     = v_serial_type
     AND "ReferenceNumber" = p_payment_ref;

  IF v_existing > 0 THEN
    RETURN QUERY SELECT 1, 'Already processed (idempotent)'::varchar;
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

  -- 4. Marcar documento como pagado
  UPDATE ar."SalesDocument"
     SET "IsPaid"    = 'Y',
         "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
   WHERE "DocumentNumber" = v_doc_number
     AND "SerialType"     = v_serial_type;

  RETURN QUERY SELECT 1, ('Order ' || v_doc_number || ' marked as paid')::varchar;
END;
$$;
-- +goose StatementEnd

-- +goose Down
DROP FUNCTION IF EXISTS public.usp_store_order_mark_paid(integer, varchar, varchar, varchar);
