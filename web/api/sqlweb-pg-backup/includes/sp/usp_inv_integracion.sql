-- ============================================================================
-- Inventario Avanzado â€” Funciones de Integracion con POS, Ventas y Logistica
-- Motor: PostgreSQL
-- ============================================================================

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- usp_Inv_Serial_ReserveForSale
-- Valida y reserva un serial al vender via POS o Factura.
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
CREATE OR REPLACE FUNCTION usp_inv_serial_reserveforsale(
  p_company_id            INT,
  p_product_id            BIGINT,
  p_serial_number         VARCHAR(100),
  p_sales_document_number VARCHAR(50),
  p_customer_id           BIGINT DEFAULT NULL,
  p_user_id               VARCHAR(50) DEFAULT 'API'
)
RETURNS TABLE("ok" INT, "SerialId" INT, "reason" VARCHAR) AS $$
DECLARE
  v_serial_id INT;
BEGIN
  -- Buscar serial disponible
  SELECT s."SerialId" INTO v_serial_id
  FROM inv."ProductSerial" s
  WHERE s."CompanyId"    = p_company_id
    AND s."ProductId"    = p_product_id
    AND s."SerialNumber" = p_serial_number
    AND s."Status"       = 'AVAILABLE';

  IF v_serial_id IS NULL THEN
    RETURN QUERY SELECT 0, 0, 'serial_not_available'::VARCHAR;
    RETURN;
  END IF;

  -- Reservar serial
  UPDATE inv."ProductSerial"
  SET "Status"              = 'SOLD',
      "SalesDocumentNumber" = p_sales_document_number,
      "CustomerId"          = p_customer_id,
      "SoldAt"              = NOW() AT TIME ZONE 'UTC',
      "UpdatedBy"           = p_user_id,
      "UpdatedAt"           = NOW() AT TIME ZONE 'UTC'
  WHERE "SerialId" = v_serial_id;

  RETURN QUERY SELECT 1, v_serial_id, ''::VARCHAR;
END;
$$ LANGUAGE plpgsql;

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- usp_Inv_Lot_ValidateForSale
-- Valida que el lote no este expirado y tenga cantidad suficiente.
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
CREATE OR REPLACE FUNCTION usp_inv_lot_validateforsale(
  p_company_id INT,
  p_product_id BIGINT,
  p_lot_id     INT DEFAULT NULL,
  p_quantity   NUMERIC(18,4) DEFAULT 0
)
RETURNS TABLE("ok" INT, "warning" VARCHAR, "expired" INT, "ExpiryDate" VARCHAR) AS $$
DECLARE
  v_lot_id      INT := p_lot_id;
  v_expiry_date TIMESTAMP;
  v_qty_on_hand NUMERIC(18,4);
  v_status      VARCHAR(20);
  v_is_expired  INT := 0;
  v_warning     VARCHAR(200) := '';
BEGIN
  -- Si no se especifica lote, buscar el primero disponible (FEFO)
  IF v_lot_id IS NULL THEN
    SELECT l."LotId" INTO v_lot_id
    FROM inv."ProductLot" l
    WHERE l."CompanyId"      = p_company_id
      AND l."ProductId"      = p_product_id
      AND l."Status"         = 'AVAILABLE'
      AND l."QuantityOnHand" >= p_quantity
    ORDER BY l."ExpiryDate" ASC
    LIMIT 1;
  END IF;

  -- Si no hay lote, producto no requiere tracking de lotes
  IF v_lot_id IS NULL THEN
    RETURN QUERY SELECT 1, ''::VARCHAR, 0, ''::VARCHAR;
    RETURN;
  END IF;

  SELECT l."ExpiryDate", l."QuantityOnHand", l."Status"
  INTO v_expiry_date, v_qty_on_hand, v_status
  FROM inv."ProductLot" l
  WHERE l."LotId" = v_lot_id AND l."CompanyId" = p_company_id;

  -- Lote no encontrado
  IF NOT FOUND THEN
    RETURN QUERY SELECT 0, 'lot_not_found'::VARCHAR, 0, ''::VARCHAR;
    RETURN;
  END IF;

  -- Verificar cantidad
  IF v_qty_on_hand < p_quantity THEN
    RETURN QUERY SELECT 0, 'insufficient_lot_quantity'::VARCHAR, 0,
      COALESCE(TO_CHAR(v_expiry_date, 'YYYY-MM-DD'),''::VARCHAR)::VARCHAR;
    RETURN;
  END IF;

  -- Verificar expiracion
  IF v_expiry_date IS NOT NULL AND v_expiry_date < (NOW() AT TIME ZONE 'UTC') THEN
    v_is_expired := 1;
    v_warning := 'lot_expired';
  ELSIF v_expiry_date IS NOT NULL AND v_expiry_date < ((NOW() AT TIME ZONE 'UTC') + INTERVAL '30 days') THEN
    v_warning := 'lot_expiring_soon';
  END IF;

  RETURN QUERY SELECT
    CASE WHEN v_is_expired = 1 THEN 0 ELSE 1 END,
    v_warning::VARCHAR,
    v_is_expired,
    COALESCE(TO_CHAR(v_expiry_date, 'YYYY-MM-DD'),''::VARCHAR)::VARCHAR;
END;
$$ LANGUAGE plpgsql;

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- usp_Inv_GoodsReceipt_ProcessStock
-- Crea movimientos de stock al aprobar una recepcion de mercancia.
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
CREATE OR REPLACE FUNCTION usp_inv_goodsreceipt_processstock(
  p_company_id       INT,
  p_branch_id        INT,
  p_goods_receipt_id INT,
  p_user_id          VARCHAR(50) DEFAULT 'API'
)
RETURNS TABLE("ok" INT, "MovementsCreated" INT) AS $$
DECLARE
  v_warehouse_id      INT;
  v_movements_created INT := 0;
  rec                 RECORD;
BEGIN
  -- Obtener almacen de la recepcion
  SELECT gr."WarehouseId" INTO v_warehouse_id
  FROM logistics."GoodsReceipt" gr
  WHERE gr."GoodsReceiptId" = p_goods_receipt_id
    AND gr."CompanyId" = p_company_id;

  IF v_warehouse_id IS NULL THEN
    RETURN QUERY SELECT 0, 0;
    RETURN;
  END IF;

  FOR rec IN
    SELECT grl."ProductId", grl."ReceivedQuantity", grl."BinId"
    FROM logistics."GoodsReceiptLine" grl
    WHERE grl."GoodsReceiptId" = p_goods_receipt_id
  LOOP
    -- Insertar movimiento de stock
    INSERT INTO inv."StockMovement" (
      "CompanyId", "BranchId", "ProductId", "MovementType",
      "Quantity", "ToWarehouseId", "ToBinId",
      "ReferenceType", "ReferenceId",
      "CreatedBy", "CreatedAt"
    )
    VALUES (
      p_company_id, p_branch_id, rec."ProductId", 'PURCHASE_IN',
      rec."ReceivedQuantity", v_warehouse_id, rec."BinId",
      'GOODS_RECEIPT', p_goods_receipt_id,
      p_user_id, NOW() AT TIME ZONE 'UTC'
    );

    -- Actualizar stock en bin (upsert)
    INSERT INTO inv."ProductBinStock" (
      "CompanyId", "ProductId", "WarehouseId", "BinId",
      "QuantityOnHand", "CreatedAt"
    )
    VALUES (
      p_company_id, rec."ProductId", v_warehouse_id, rec."BinId",
      rec."ReceivedQuantity", NOW() AT TIME ZONE 'UTC'
    )
    ON CONFLICT ("CompanyId", "ProductId", "WarehouseId", COALESCE("BinId", 0))
    DO UPDATE SET
      "QuantityOnHand" = inv."ProductBinStock"."QuantityOnHand" + EXCLUDED."QuantityOnHand",
      "UpdatedAt"      = NOW() AT TIME ZONE 'UTC';

    v_movements_created := v_movements_created + 1;
  END LOOP;

  RETURN QUERY SELECT 1, v_movements_created;
END;
$$ LANGUAGE plpgsql;

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- usp_Inv_DeliveryNote_ProcessStock
-- Crea movimientos de stock al despachar una nota de entrega.
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
CREATE OR REPLACE FUNCTION usp_inv_deliverynote_processstock(
  p_company_id       INT,
  p_branch_id        INT,
  p_delivery_note_id INT,
  p_user_id          VARCHAR(50) DEFAULT 'API'
)
RETURNS TABLE("ok" INT, "MovementsCreated" INT) AS $$
DECLARE
  v_warehouse_id      INT;
  v_movements_created INT := 0;
  rec                 RECORD;
BEGIN
  -- Obtener almacen de la nota de entrega
  SELECT dn."WarehouseId" INTO v_warehouse_id
  FROM logistics."DeliveryNote" dn
  WHERE dn."DeliveryNoteId" = p_delivery_note_id
    AND dn."CompanyId" = p_company_id;

  IF v_warehouse_id IS NULL THEN
    RETURN QUERY SELECT 0, 0;
    RETURN;
  END IF;

  FOR rec IN
    SELECT dnl."ProductId", dnl."DispatchedQuantity", dnl."BinId"
    FROM logistics."DeliveryNoteLine" dnl
    WHERE dnl."DeliveryNoteId" = p_delivery_note_id
  LOOP
    -- Insertar movimiento de stock (salida)
    INSERT INTO inv."StockMovement" (
      "CompanyId", "BranchId", "ProductId", "MovementType",
      "Quantity", "FromWarehouseId", "FromBinId",
      "ReferenceType", "ReferenceId",
      "CreatedBy", "CreatedAt"
    )
    VALUES (
      p_company_id, p_branch_id, rec."ProductId", 'SALE_OUT',
      rec."DispatchedQuantity", v_warehouse_id, rec."BinId",
      'DELIVERY_NOTE', p_delivery_note_id,
      p_user_id, NOW() AT TIME ZONE 'UTC'
    );

    -- Disminuir stock en bin
    UPDATE inv."ProductBinStock"
    SET "QuantityOnHand" = "QuantityOnHand" - rec."DispatchedQuantity",
        "UpdatedAt"      = NOW() AT TIME ZONE 'UTC'
    WHERE "CompanyId"   = p_company_id
      AND "ProductId"   = rec."ProductId"
      AND "WarehouseId" = v_warehouse_id
      AND COALESCE("BinId", 0) = COALESCE(rec."BinId", 0);

    v_movements_created := v_movements_created + 1;
  END LOOP;

  -- Actualizar seriales asociados a la nota de entrega
  UPDATE inv."ProductSerial"
  SET "Status"    = 'SOLD',
      "SoldAt"    = NOW() AT TIME ZONE 'UTC',
      "UpdatedBy" = p_user_id,
      "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
  WHERE "SerialId" IN (
    SELECT dns."SerialId"
    FROM logistics."DeliveryNoteSerial" dns
    WHERE dns."DeliveryNoteId" = p_delivery_note_id
  )
  AND "Status" = 'AVAILABLE';

  RETURN QUERY SELECT 1, v_movements_created;
END;
$$ LANGUAGE plpgsql;
