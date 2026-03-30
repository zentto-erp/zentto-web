/*
 * seed_demo_logistica.sql (PostgreSQL)
 * ─────────────────────────────────────
 * Seed de datos demo para modulo de Logistica.
 * Idempotente: WHERE NOT EXISTS.
 *
 * Tablas afectadas:
 *   logistics."Carrier", logistics."Driver",
 *   logistics."GoodsReceipt", logistics."GoodsReceiptLine", logistics."GoodsReceiptSerial",
 *   logistics."GoodsReturn", logistics."GoodsReturnLine",
 *   logistics."DeliveryNote", logistics."DeliveryNoteLine", logistics."DeliveryNoteSerial"
 */

DO $$
DECLARE
  v_company_id    INT := 1;
  v_branch_id     INT := 1;
  v_user_id       INT := 1;
  v_carrier_tre   BIGINT;
  v_carrier_mrw   BIGINT;
  v_carrier_zoom  BIGINT;
  v_driver_1      BIGINT;
  v_driver_3      BIGINT;
  v_wh1           BIGINT;
  v_gr1           BIGINT;
  v_gr2           BIGINT;
  v_grl1          BIGINT;
  v_grtn1         BIGINT;
  v_dn1           BIGINT;
  v_dn2           BIGINT;
  v_dn3           BIGINT;
  v_dnl1          BIGINT;
  v_serial_tv2    BIGINT;
BEGIN
  RAISE NOTICE '=== Seed demo: Logistica ===';

  -- ============================================================================
  -- SECCION 1: logistics."Carrier" (3 transportistas)
  -- ============================================================================
  RAISE NOTICE '>> 1. Transportistas demo...';

  INSERT INTO logistics."Carrier" ("CompanyId", "CarrierCode", "CarrierName", "FiscalId", "ContactName", "Phone", "Email", "AddressLine", "CreatedByUserId")
  SELECT v_company_id, 'TRE', 'Transporte Rápido Express C.A.', 'J-30567890-1', 'Roberto Castillo', '+58-212-5554001', 'operaciones@tre.com.ve', 'Av. Principal de Boleíta, Galpón 8, Caracas', v_user_id
  WHERE NOT EXISTS (SELECT 1 FROM logistics."Carrier" WHERE "CompanyId" = v_company_id AND "CarrierCode" = 'TRE' AND "IsDeleted" = FALSE);

  INSERT INTO logistics."Carrier" ("CompanyId", "CarrierCode", "CarrierName", "FiscalId", "ContactName", "Phone", "Email", "AddressLine", "CreatedByUserId")
  SELECT v_company_id, 'MRW', 'MRW Venezuela C.A.', 'J-29012345-6', 'Centro de Operaciones', '+58-212-2020101', 'empresas@mrw.com.ve', 'Av. Don Diego Cisneros, Los Ruices, Caracas', v_user_id
  WHERE NOT EXISTS (SELECT 1 FROM logistics."Carrier" WHERE "CompanyId" = v_company_id AND "CarrierCode" = 'MRW' AND "IsDeleted" = FALSE);

  INSERT INTO logistics."Carrier" ("CompanyId", "CarrierCode", "CarrierName", "FiscalId", "ContactName", "Phone", "Email", "AddressLine", "CreatedByUserId")
  SELECT v_company_id, 'ZOOM', 'Zoom Envíos C.A.', 'J-31234567-8', 'Departamento Corporativo', '+58-212-5557070', 'corporativo@zoom.com.ve', 'Calle Vargas, Edif. Zoom, La Candelaria, Caracas', v_user_id
  WHERE NOT EXISTS (SELECT 1 FROM logistics."Carrier" WHERE "CompanyId" = v_company_id AND "CarrierCode" = 'ZOOM' AND "IsDeleted" = FALSE);

  SELECT "CarrierId" INTO v_carrier_tre FROM logistics."Carrier" WHERE "CompanyId" = v_company_id AND "CarrierCode" = 'TRE' AND "IsDeleted" = FALSE LIMIT 1;
  SELECT "CarrierId" INTO v_carrier_mrw FROM logistics."Carrier" WHERE "CompanyId" = v_company_id AND "CarrierCode" = 'MRW' AND "IsDeleted" = FALSE LIMIT 1;
  SELECT "CarrierId" INTO v_carrier_zoom FROM logistics."Carrier" WHERE "CompanyId" = v_company_id AND "CarrierCode" = 'ZOOM' AND "IsDeleted" = FALSE LIMIT 1;

  -- ============================================================================
  -- SECCION 2: logistics."Driver" (4 conductores)
  -- ============================================================================
  RAISE NOTICE '>> 2. Conductores demo...';

  INSERT INTO logistics."Driver" ("CompanyId", "CarrierId", "DriverCode", "DriverName", "FiscalId", "LicenseNumber", "LicenseExpiry", "Phone", "CreatedByUserId")
  SELECT v_company_id, v_carrier_tre, 'DRV-001', 'Carlos Mendoza', 'V-18234567-0', 'LIC-CCS-045678', '2027-06-15', '+58-414-5551001', v_user_id
  WHERE NOT EXISTS (SELECT 1 FROM logistics."Driver" WHERE "CompanyId" = v_company_id AND "DriverCode" = 'DRV-001' AND "IsDeleted" = FALSE);

  INSERT INTO logistics."Driver" ("CompanyId", "CarrierId", "DriverCode", "DriverName", "FiscalId", "LicenseNumber", "LicenseExpiry", "Phone", "CreatedByUserId")
  SELECT v_company_id, v_carrier_tre, 'DRV-002', 'María López', 'V-20345678-1', 'LIC-CCS-056789', '2027-09-20', '+58-424-5552002', v_user_id
  WHERE NOT EXISTS (SELECT 1 FROM logistics."Driver" WHERE "CompanyId" = v_company_id AND "DriverCode" = 'DRV-002' AND "IsDeleted" = FALSE);

  INSERT INTO logistics."Driver" ("CompanyId", "CarrierId", "DriverCode", "DriverName", "FiscalId", "LicenseNumber", "LicenseExpiry", "Phone", "CreatedByUserId")
  SELECT v_company_id, v_carrier_mrw, 'DRV-003', 'José Pérez', 'V-16456789-2', 'LIC-MIR-067890', '2026-12-01', '+58-412-5553003', v_user_id
  WHERE NOT EXISTS (SELECT 1 FROM logistics."Driver" WHERE "CompanyId" = v_company_id AND "DriverCode" = 'DRV-003' AND "IsDeleted" = FALSE);

  INSERT INTO logistics."Driver" ("CompanyId", "CarrierId", "DriverCode", "DriverName", "FiscalId", "LicenseNumber", "LicenseExpiry", "Phone", "CreatedByUserId")
  SELECT v_company_id, v_carrier_zoom, 'DRV-004', 'Ana Rodríguez', 'V-22567890-3', 'LIC-CCS-078901', '2028-03-10', '+58-416-5554004', v_user_id
  WHERE NOT EXISTS (SELECT 1 FROM logistics."Driver" WHERE "CompanyId" = v_company_id AND "DriverCode" = 'DRV-004' AND "IsDeleted" = FALSE);

  SELECT "DriverId" INTO v_driver_1 FROM logistics."Driver" WHERE "CompanyId" = v_company_id AND "DriverCode" = 'DRV-001' AND "IsDeleted" = FALSE LIMIT 1;
  SELECT "DriverId" INTO v_driver_3 FROM logistics."Driver" WHERE "CompanyId" = v_company_id AND "DriverCode" = 'DRV-003' AND "IsDeleted" = FALSE LIMIT 1;

  -- Obtener almacen
  SELECT "WarehouseId" INTO v_wh1 FROM inv."Warehouse" WHERE "CompanyId" = v_company_id AND "WarehouseCode" = 'ALM-01' AND "IsDeleted" = FALSE LIMIT 1;

  -- ============================================================================
  -- SECCION 3: logistics."GoodsReceipt" (2 recepciones con lineas)
  -- ============================================================================
  RAISE NOTICE '>> 3. Recepciones de mercancia demo...';

  -- Recepcion 1: COMPLETE
  INSERT INTO logistics."GoodsReceipt" ("CompanyId", "BranchId", "ReceiptNumber", "PurchaseDocumentNumber", "SupplierId", "WarehouseId", "ReceiptDate", "Status", "Notes", "CarrierId", "DriverName", "VehiclePlate", "ReceivedByUserId", "CreatedByUserId")
  SELECT v_company_id, v_branch_id, 'REC-2026-001', 'OC-2026-0100', 1, v_wh1, '2026-01-20', 'COMPLETE', 'Recepción completa de electrónicos - lote LOT-2026-001', v_carrier_tre, 'Carlos Mendoza', 'AB123CD', v_user_id, v_user_id
  WHERE NOT EXISTS (SELECT 1 FROM logistics."GoodsReceipt" WHERE "CompanyId" = v_company_id AND "ReceiptNumber" = 'REC-2026-001' AND "IsDeleted" = FALSE);

  -- Recepcion 2: DRAFT
  INSERT INTO logistics."GoodsReceipt" ("CompanyId", "BranchId", "ReceiptNumber", "PurchaseDocumentNumber", "SupplierId", "WarehouseId", "ReceiptDate", "Status", "Notes", "CreatedByUserId")
  SELECT v_company_id, v_branch_id, 'REC-2026-002', 'OC-2026-0200', 2, v_wh1, '2026-03-18', 'DRAFT', 'Pendiente de recibir - equipos de oficina', v_user_id
  WHERE NOT EXISTS (SELECT 1 FROM logistics."GoodsReceipt" WHERE "CompanyId" = v_company_id AND "ReceiptNumber" = 'REC-2026-002' AND "IsDeleted" = FALSE);

  SELECT "GoodsReceiptId" INTO v_gr1 FROM logistics."GoodsReceipt" WHERE "CompanyId" = v_company_id AND "ReceiptNumber" = 'REC-2026-001' AND "IsDeleted" = FALSE LIMIT 1;
  SELECT "GoodsReceiptId" INTO v_gr2 FROM logistics."GoodsReceipt" WHERE "CompanyId" = v_company_id AND "ReceiptNumber" = 'REC-2026-002' AND "IsDeleted" = FALSE LIMIT 1;

  -- Lineas recepcion 1
  IF v_gr1 IS NOT NULL THEN
    INSERT INTO logistics."GoodsReceiptLine" ("GoodsReceiptId", "LineNumber", "ProductId", "ProductCode", "Description", "OrderedQuantity", "ReceivedQuantity", "RejectedQuantity", "UnitCost", "TotalCost", "LotNumber", "InspectionStatus", "CreatedByUserId")
    SELECT v_gr1, 1, 1, 'PROD-001', 'TV Samsung 55" UHD', 100.000, 100.000, 0.000, 15.5000, 1550.00, 'LOT-2026-001', 'APPROVED', v_user_id
    WHERE NOT EXISTS (SELECT 1 FROM logistics."GoodsReceiptLine" WHERE "GoodsReceiptId" = v_gr1 AND "LineNumber" = 1);

    INSERT INTO logistics."GoodsReceiptLine" ("GoodsReceiptId", "LineNumber", "ProductId", "ProductCode", "Description", "OrderedQuantity", "ReceivedQuantity", "RejectedQuantity", "UnitCost", "TotalCost", "LotNumber", "InspectionStatus", "CreatedByUserId")
    SELECT v_gr1, 2, 2, 'PROD-002', 'Laptop HP ProBook 450', 50.000, 50.000, 2.000, 22.7500, 1137.50, 'LOT-2026-002', 'APPROVED', v_user_id
    WHERE NOT EXISTS (SELECT 1 FROM logistics."GoodsReceiptLine" WHERE "GoodsReceiptId" = v_gr1 AND "LineNumber" = 2);

    INSERT INTO logistics."GoodsReceiptLine" ("GoodsReceiptId", "LineNumber", "ProductId", "ProductCode", "Description", "OrderedQuantity", "ReceivedQuantity", "RejectedQuantity", "UnitCost", "TotalCost", "LotNumber", "InspectionStatus", "CreatedByUserId")
    SELECT v_gr1, 3, 3, 'PROD-003', 'Impresora Epson L3250', 30.000, 28.000, 1.000, 8.2000, 229.60, 'LOT-2026-003', 'APPROVED', v_user_id
    WHERE NOT EXISTS (SELECT 1 FROM logistics."GoodsReceiptLine" WHERE "GoodsReceiptId" = v_gr1 AND "LineNumber" = 3);

    -- Seriales recepcion 1 (linea 1)
    SELECT "GoodsReceiptLineId" INTO v_grl1 FROM logistics."GoodsReceiptLine" WHERE "GoodsReceiptId" = v_gr1 AND "LineNumber" = 1 LIMIT 1;
    IF v_grl1 IS NOT NULL THEN
      INSERT INTO logistics."GoodsReceiptSerial" ("GoodsReceiptLineId", "SerialNumber", "Status")
      SELECT v_grl1, 'SN-TV-001', 'RECEIVED'
      WHERE NOT EXISTS (SELECT 1 FROM logistics."GoodsReceiptSerial" WHERE "GoodsReceiptLineId" = v_grl1 AND "SerialNumber" = 'SN-TV-001');

      INSERT INTO logistics."GoodsReceiptSerial" ("GoodsReceiptLineId", "SerialNumber", "Status")
      SELECT v_grl1, 'SN-TV-002', 'RECEIVED'
      WHERE NOT EXISTS (SELECT 1 FROM logistics."GoodsReceiptSerial" WHERE "GoodsReceiptLineId" = v_grl1 AND "SerialNumber" = 'SN-TV-002');
    END IF;
  END IF;

  -- Lineas recepcion 2
  IF v_gr2 IS NOT NULL THEN
    INSERT INTO logistics."GoodsReceiptLine" ("GoodsReceiptId", "LineNumber", "ProductId", "ProductCode", "Description", "OrderedQuantity", "ReceivedQuantity", "UnitCost", "TotalCost", "InspectionStatus", "CreatedByUserId")
    SELECT v_gr2, 1, 3, 'PROD-003', 'Impresora Epson L3250', 20.000, 0.000, 8.2000, 0.00, 'PENDING', v_user_id
    WHERE NOT EXISTS (SELECT 1 FROM logistics."GoodsReceiptLine" WHERE "GoodsReceiptId" = v_gr2 AND "LineNumber" = 1);

    INSERT INTO logistics."GoodsReceiptLine" ("GoodsReceiptId", "LineNumber", "ProductId", "ProductCode", "Description", "OrderedQuantity", "ReceivedQuantity", "UnitCost", "TotalCost", "InspectionStatus", "CreatedByUserId")
    SELECT v_gr2, 2, 4, 'PROD-004', 'Monitor LG 27" 4K', 15.000, 0.000, 35.0000, 0.00, 'PENDING', v_user_id
    WHERE NOT EXISTS (SELECT 1 FROM logistics."GoodsReceiptLine" WHERE "GoodsReceiptId" = v_gr2 AND "LineNumber" = 2);

    INSERT INTO logistics."GoodsReceiptLine" ("GoodsReceiptId", "LineNumber", "ProductId", "ProductCode", "Description", "OrderedQuantity", "ReceivedQuantity", "UnitCost", "TotalCost", "InspectionStatus", "CreatedByUserId")
    SELECT v_gr2, 3, 5, 'PROD-005', 'Teclado Logitech MX Keys', 40.000, 0.000, 120.0000, 0.00, 'PENDING', v_user_id
    WHERE NOT EXISTS (SELECT 1 FROM logistics."GoodsReceiptLine" WHERE "GoodsReceiptId" = v_gr2 AND "LineNumber" = 3);
  END IF;

  -- ============================================================================
  -- SECCION 4: logistics."GoodsReturn" (1 devolucion)
  -- ============================================================================
  RAISE NOTICE '>> 4. Devolucion a proveedor demo...';

  INSERT INTO logistics."GoodsReturn" ("CompanyId", "BranchId", "ReturnNumber", "GoodsReceiptId", "SupplierId", "WarehouseId", "ReturnDate", "Reason", "Status", "Notes", "CreatedByUserId")
  SELECT v_company_id, v_branch_id, 'DEV-PROV-2026-001', v_gr1, 1, v_wh1, '2026-02-05', 'Producto defectuoso - impresora con cabezal obstruido', 'APPROVED', 'Devolucion aprobada - esperando retiro por transporte', v_user_id
  WHERE NOT EXISTS (SELECT 1 FROM logistics."GoodsReturn" WHERE "CompanyId" = v_company_id AND "ReturnNumber" = 'DEV-PROV-2026-001' AND "IsDeleted" = FALSE);

  SELECT "GoodsReturnId" INTO v_grtn1 FROM logistics."GoodsReturn" WHERE "CompanyId" = v_company_id AND "ReturnNumber" = 'DEV-PROV-2026-001' AND "IsDeleted" = FALSE LIMIT 1;
  IF v_grtn1 IS NOT NULL THEN
    INSERT INTO logistics."GoodsReturnLine" ("GoodsReturnId", "LineNumber", "ProductId", "ProductCode", "Quantity", "UnitCost", "SerialNumber", "Reason", "CreatedByUserId")
    SELECT v_grtn1, 1, 3, 'PROD-003', 1.000, 8.2000, 'SN-IMP-002', 'Cabezal de impresion obstruido de fabrica', v_user_id
    WHERE NOT EXISTS (SELECT 1 FROM logistics."GoodsReturnLine" WHERE "GoodsReturnId" = v_grtn1 AND "LineNumber" = 1);
  END IF;

  -- ============================================================================
  -- SECCION 5: logistics."DeliveryNote" (3 notas de entrega con lineas)
  -- ============================================================================
  RAISE NOTICE '>> 5. Notas de entrega demo...';

  -- Entrega 1: DELIVERED
  INSERT INTO logistics."DeliveryNote" ("CompanyId", "BranchId", "DeliveryNumber", "SalesDocumentNumber", "CustomerId", "WarehouseId", "DeliveryDate", "Status", "CarrierId", "DriverId", "VehiclePlate", "ShipToAddress", "ShipToContact", "EstimatedDelivery", "ActualDelivery", "DeliveredToName", "Notes", "DispatchedByUserId", "CreatedByUserId")
  SELECT v_company_id, v_branch_id, 'ENT-2026-001', 'FAC-2026-0050', 1, v_wh1, '2026-03-10', 'DELIVERED', v_carrier_tre, v_driver_1, 'AB123CD', 'Av. Libertador, Torre Delta, Piso 8, Caracas', 'Ing. Juan García', '2026-03-11', '2026-03-11', 'Recibido por: Ing. Juan García (C.I. V-12345678)', 'Entrega completada sin novedades', v_user_id, v_user_id
  WHERE NOT EXISTS (SELECT 1 FROM logistics."DeliveryNote" WHERE "CompanyId" = v_company_id AND "DeliveryNumber" = 'ENT-2026-001' AND "IsDeleted" = FALSE);

  -- Entrega 2: DISPATCHED
  INSERT INTO logistics."DeliveryNote" ("CompanyId", "BranchId", "DeliveryNumber", "SalesDocumentNumber", "CustomerId", "WarehouseId", "DeliveryDate", "Status", "CarrierId", "DriverId", "VehiclePlate", "ShipToAddress", "ShipToContact", "EstimatedDelivery", "Notes", "DispatchedByUserId", "CreatedByUserId")
  SELECT v_company_id, v_branch_id, 'ENT-2026-002', 'FAC-2026-0055', 2, v_wh1, '2026-03-20', 'DISPATCHED', v_carrier_mrw, v_driver_3, 'XY789ZW', 'Urb. El Paraíso, Calle 4, Casa 12, Maracaibo', 'María del Carmen Rodríguez', '2026-03-22', 'En camino a Maracaibo - transporte MRW', v_user_id, v_user_id
  WHERE NOT EXISTS (SELECT 1 FROM logistics."DeliveryNote" WHERE "CompanyId" = v_company_id AND "DeliveryNumber" = 'ENT-2026-002' AND "IsDeleted" = FALSE);

  -- Entrega 3: DRAFT
  INSERT INTO logistics."DeliveryNote" ("CompanyId", "BranchId", "DeliveryNumber", "SalesDocumentNumber", "CustomerId", "WarehouseId", "DeliveryDate", "Status", "ShipToAddress", "ShipToContact", "Notes", "CreatedByUserId")
  SELECT v_company_id, v_branch_id, 'ENT-2026-003', 'FAC-2026-0060', 3, v_wh1, '2026-03-22', 'DRAFT', 'Zona Industrial Los Montones, Galpón 3, Barcelona', 'Grupo Alimenticio Oriente', 'Pendiente de picking y asignacion de transporte', v_user_id
  WHERE NOT EXISTS (SELECT 1 FROM logistics."DeliveryNote" WHERE "CompanyId" = v_company_id AND "DeliveryNumber" = 'ENT-2026-003' AND "IsDeleted" = FALSE);

  SELECT "DeliveryNoteId" INTO v_dn1 FROM logistics."DeliveryNote" WHERE "CompanyId" = v_company_id AND "DeliveryNumber" = 'ENT-2026-001' AND "IsDeleted" = FALSE LIMIT 1;
  SELECT "DeliveryNoteId" INTO v_dn2 FROM logistics."DeliveryNote" WHERE "CompanyId" = v_company_id AND "DeliveryNumber" = 'ENT-2026-002' AND "IsDeleted" = FALSE LIMIT 1;
  SELECT "DeliveryNoteId" INTO v_dn3 FROM logistics."DeliveryNote" WHERE "CompanyId" = v_company_id AND "DeliveryNumber" = 'ENT-2026-003' AND "IsDeleted" = FALSE LIMIT 1;

  -- Lineas entrega 1 (DELIVERED)
  IF v_dn1 IS NOT NULL THEN
    INSERT INTO logistics."DeliveryNoteLine" ("DeliveryNoteId", "LineNumber", "ProductId", "ProductCode", "Description", "Quantity", "PickedQuantity", "PackedQuantity", "CreatedByUserId")
    SELECT v_dn1, 1, 1, 'PROD-001', 'TV Samsung 55" UHD', 5.000, 5.000, 5.000, v_user_id
    WHERE NOT EXISTS (SELECT 1 FROM logistics."DeliveryNoteLine" WHERE "DeliveryNoteId" = v_dn1 AND "LineNumber" = 1);

    INSERT INTO logistics."DeliveryNoteLine" ("DeliveryNoteId", "LineNumber", "ProductId", "ProductCode", "Description", "Quantity", "PickedQuantity", "PackedQuantity", "CreatedByUserId")
    SELECT v_dn1, 2, 4, 'PROD-004', 'Monitor LG 27" 4K', 3.000, 3.000, 3.000, v_user_id
    WHERE NOT EXISTS (SELECT 1 FROM logistics."DeliveryNoteLine" WHERE "DeliveryNoteId" = v_dn1 AND "LineNumber" = 2);

    -- Seriales despachados entrega 1
    SELECT "DeliveryNoteLineId" INTO v_dnl1 FROM logistics."DeliveryNoteLine" WHERE "DeliveryNoteId" = v_dn1 AND "LineNumber" = 1 LIMIT 1;
    SELECT "SerialId" INTO v_serial_tv2 FROM inv."ProductSerial" WHERE "CompanyId" = v_company_id AND "SerialNumber" = 'SN-TV-002' LIMIT 1;

    IF v_dnl1 IS NOT NULL AND v_serial_tv2 IS NOT NULL THEN
      INSERT INTO logistics."DeliveryNoteSerial" ("DeliveryNoteLineId", "SerialId", "SerialNumber", "Status")
      SELECT v_dnl1, v_serial_tv2, 'SN-TV-002', 'DELIVERED'
      WHERE NOT EXISTS (SELECT 1 FROM logistics."DeliveryNoteSerial" WHERE "DeliveryNoteLineId" = v_dnl1 AND "SerialId" = v_serial_tv2);
    END IF;
  END IF;

  -- Lineas entrega 2 (DISPATCHED)
  IF v_dn2 IS NOT NULL THEN
    INSERT INTO logistics."DeliveryNoteLine" ("DeliveryNoteId", "LineNumber", "ProductId", "ProductCode", "Description", "Quantity", "PickedQuantity", "PackedQuantity", "CreatedByUserId")
    SELECT v_dn2, 1, 2, 'PROD-002', 'Laptop HP ProBook 450', 2.000, 2.000, 2.000, v_user_id
    WHERE NOT EXISTS (SELECT 1 FROM logistics."DeliveryNoteLine" WHERE "DeliveryNoteId" = v_dn2 AND "LineNumber" = 1);

    INSERT INTO logistics."DeliveryNoteLine" ("DeliveryNoteId", "LineNumber", "ProductId", "ProductCode", "Description", "Quantity", "PickedQuantity", "PackedQuantity", "CreatedByUserId")
    SELECT v_dn2, 2, 5, 'PROD-005', 'Teclado Logitech MX Keys', 4.000, 4.000, 4.000, v_user_id
    WHERE NOT EXISTS (SELECT 1 FROM logistics."DeliveryNoteLine" WHERE "DeliveryNoteId" = v_dn2 AND "LineNumber" = 2);
  END IF;

  -- Lineas entrega 3 (DRAFT)
  IF v_dn3 IS NOT NULL THEN
    INSERT INTO logistics."DeliveryNoteLine" ("DeliveryNoteId", "LineNumber", "ProductId", "ProductCode", "Description", "Quantity", "PickedQuantity", "PackedQuantity", "CreatedByUserId")
    SELECT v_dn3, 1, 1, 'PROD-001', 'TV Samsung 55" UHD', 10.000, 0.000, 0.000, v_user_id
    WHERE NOT EXISTS (SELECT 1 FROM logistics."DeliveryNoteLine" WHERE "DeliveryNoteId" = v_dn3 AND "LineNumber" = 1);

    INSERT INTO logistics."DeliveryNoteLine" ("DeliveryNoteId", "LineNumber", "ProductId", "ProductCode", "Description", "Quantity", "PickedQuantity", "PackedQuantity", "CreatedByUserId")
    SELECT v_dn3, 2, 3, 'PROD-003', 'Impresora Epson L3250', 5.000, 0.000, 0.000, v_user_id
    WHERE NOT EXISTS (SELECT 1 FROM logistics."DeliveryNoteLine" WHERE "DeliveryNoteId" = v_dn3 AND "LineNumber" = 2);

    INSERT INTO logistics."DeliveryNoteLine" ("DeliveryNoteId", "LineNumber", "ProductId", "ProductCode", "Description", "Quantity", "PickedQuantity", "PackedQuantity", "CreatedByUserId")
    SELECT v_dn3, 3, 5, 'PROD-005', 'Teclado Logitech MX Keys', 8.000, 0.000, 0.000, v_user_id
    WHERE NOT EXISTS (SELECT 1 FROM logistics."DeliveryNoteLine" WHERE "DeliveryNoteId" = v_dn3 AND "LineNumber" = 3);
  END IF;

  RAISE NOTICE '=== Seed demo: Logistica — COMPLETO ===';
END $$;
