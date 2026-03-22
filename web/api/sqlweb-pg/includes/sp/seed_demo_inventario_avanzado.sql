/*
 * seed_demo_inventario_avanzado.sql (PostgreSQL)
 * ───────────────────────────────────────────────
 * Seed de datos demo para modulo de Inventario Avanzado.
 * Idempotente: WHERE NOT EXISTS / ON CONFLICT DO NOTHING.
 *
 * Tablas afectadas:
 *   inv."Warehouse", inv."WarehouseZone", inv."WarehouseBin",
 *   inv."ProductLot", inv."ProductSerial", inv."ProductBinStock",
 *   inv."InventoryValuationMethod", inv."StockMovement"
 */

DO $$
DECLARE
  v_company_id  INT := 1;
  v_branch_id   INT := 1;
  v_user_id     INT := 1;
  v_wh1         BIGINT;
  v_wh2         BIGINT;
  v_wh_dev      BIGINT;
  v_zone_rec    BIGINT;
  v_zone_alm    BIGINT;
  v_zone_pic    BIGINT;
  v_zone_des    BIGINT;
  v_bin_a01     BIGINT;
  v_bin_a02     BIGINT;
  v_bin_a03     BIGINT;
BEGIN
  RAISE NOTICE '=== Seed demo: Inventario Avanzado ===';

  -- ============================================================================
  -- SECCION 1: inv."Warehouse" (3 almacenes)
  -- ============================================================================
  RAISE NOTICE '>> 1. Almacenes demo...';

  INSERT INTO inv."Warehouse" ("CompanyId", "BranchId", "WarehouseCode", "WarehouseName", "AddressLine", "ContactName", "Phone", "CreatedByUserId")
  SELECT v_company_id, v_branch_id, 'ALM-01', 'Almacén Principal', 'Zona Industrial La Yaguara, Galpón 12, Caracas', 'Pedro Ramírez', '+58-212-5551001', v_user_id
  WHERE NOT EXISTS (SELECT 1 FROM inv."Warehouse" WHERE "CompanyId" = v_company_id AND "WarehouseCode" = 'ALM-01' AND "IsDeleted" = FALSE);

  INSERT INTO inv."Warehouse" ("CompanyId", "BranchId", "WarehouseCode", "WarehouseName", "AddressLine", "ContactName", "Phone", "CreatedByUserId")
  SELECT v_company_id, v_branch_id, 'ALM-02', 'Almacén Secundario', 'Av. Intercomunal, Guarenas, Galpón 5, Miranda', 'Luisa Fernández', '+58-212-5552002', v_user_id
  WHERE NOT EXISTS (SELECT 1 FROM inv."Warehouse" WHERE "CompanyId" = v_company_id AND "WarehouseCode" = 'ALM-02' AND "IsDeleted" = FALSE);

  INSERT INTO inv."Warehouse" ("CompanyId", "BranchId", "WarehouseCode", "WarehouseName", "AddressLine", "ContactName", "Phone", "CreatedByUserId")
  SELECT v_company_id, v_branch_id, 'ALM-DEV', 'Almacén Devoluciones', 'Zona Industrial La Yaguara, Galpón 12-B, Caracas', 'Pedro Ramírez', '+58-212-5551002', v_user_id
  WHERE NOT EXISTS (SELECT 1 FROM inv."Warehouse" WHERE "CompanyId" = v_company_id AND "WarehouseCode" = 'ALM-DEV' AND "IsDeleted" = FALSE);

  -- Obtener IDs de almacenes
  SELECT "WarehouseId" INTO v_wh1 FROM inv."Warehouse" WHERE "CompanyId" = v_company_id AND "WarehouseCode" = 'ALM-01' AND "IsDeleted" = FALSE LIMIT 1;
  SELECT "WarehouseId" INTO v_wh2 FROM inv."Warehouse" WHERE "CompanyId" = v_company_id AND "WarehouseCode" = 'ALM-02' AND "IsDeleted" = FALSE LIMIT 1;
  SELECT "WarehouseId" INTO v_wh_dev FROM inv."Warehouse" WHERE "CompanyId" = v_company_id AND "WarehouseCode" = 'ALM-DEV' AND "IsDeleted" = FALSE LIMIT 1;

  -- ============================================================================
  -- SECCION 2: inv."WarehouseZone" (4 zonas por almacen)
  -- ============================================================================
  RAISE NOTICE '>> 2. Zonas de almacen demo...';

  -- Zonas ALM-01
  IF v_wh1 IS NOT NULL THEN
    INSERT INTO inv."WarehouseZone" ("WarehouseId", "ZoneCode", "ZoneName", "ZoneType", "Temperature", "CreatedByUserId")
    SELECT v_wh1, 'RECEPCION', 'Zona de Recepción', 'RECEIVING', 'AMBIENT', v_user_id
    WHERE NOT EXISTS (SELECT 1 FROM inv."WarehouseZone" WHERE "WarehouseId" = v_wh1 AND "ZoneCode" = 'RECEPCION');

    INSERT INTO inv."WarehouseZone" ("WarehouseId", "ZoneCode", "ZoneName", "ZoneType", "Temperature", "CreatedByUserId")
    SELECT v_wh1, 'ALMACENAMIENTO', 'Zona de Almacenamiento', 'STORAGE', 'AMBIENT', v_user_id
    WHERE NOT EXISTS (SELECT 1 FROM inv."WarehouseZone" WHERE "WarehouseId" = v_wh1 AND "ZoneCode" = 'ALMACENAMIENTO');

    INSERT INTO inv."WarehouseZone" ("WarehouseId", "ZoneCode", "ZoneName", "ZoneType", "Temperature", "CreatedByUserId")
    SELECT v_wh1, 'PICKING', 'Zona de Picking', 'PICKING', 'AMBIENT', v_user_id
    WHERE NOT EXISTS (SELECT 1 FROM inv."WarehouseZone" WHERE "WarehouseId" = v_wh1 AND "ZoneCode" = 'PICKING');

    INSERT INTO inv."WarehouseZone" ("WarehouseId", "ZoneCode", "ZoneName", "ZoneType", "Temperature", "CreatedByUserId")
    SELECT v_wh1, 'DESPACHO', 'Zona de Despacho', 'SHIPPING', 'AMBIENT', v_user_id
    WHERE NOT EXISTS (SELECT 1 FROM inv."WarehouseZone" WHERE "WarehouseId" = v_wh1 AND "ZoneCode" = 'DESPACHO');
  END IF;

  -- Zonas ALM-02
  IF v_wh2 IS NOT NULL THEN
    INSERT INTO inv."WarehouseZone" ("WarehouseId", "ZoneCode", "ZoneName", "ZoneType", "Temperature", "CreatedByUserId")
    SELECT v_wh2, 'RECEPCION', 'Zona de Recepción', 'RECEIVING', 'AMBIENT', v_user_id
    WHERE NOT EXISTS (SELECT 1 FROM inv."WarehouseZone" WHERE "WarehouseId" = v_wh2 AND "ZoneCode" = 'RECEPCION');

    INSERT INTO inv."WarehouseZone" ("WarehouseId", "ZoneCode", "ZoneName", "ZoneType", "Temperature", "CreatedByUserId")
    SELECT v_wh2, 'ALMACENAMIENTO', 'Zona de Almacenamiento', 'STORAGE', 'COLD', v_user_id
    WHERE NOT EXISTS (SELECT 1 FROM inv."WarehouseZone" WHERE "WarehouseId" = v_wh2 AND "ZoneCode" = 'ALMACENAMIENTO');

    INSERT INTO inv."WarehouseZone" ("WarehouseId", "ZoneCode", "ZoneName", "ZoneType", "Temperature", "CreatedByUserId")
    SELECT v_wh2, 'PICKING', 'Zona de Picking', 'PICKING', 'COLD', v_user_id
    WHERE NOT EXISTS (SELECT 1 FROM inv."WarehouseZone" WHERE "WarehouseId" = v_wh2 AND "ZoneCode" = 'PICKING');

    INSERT INTO inv."WarehouseZone" ("WarehouseId", "ZoneCode", "ZoneName", "ZoneType", "Temperature", "CreatedByUserId")
    SELECT v_wh2, 'DESPACHO', 'Zona de Despacho', 'SHIPPING', 'AMBIENT', v_user_id
    WHERE NOT EXISTS (SELECT 1 FROM inv."WarehouseZone" WHERE "WarehouseId" = v_wh2 AND "ZoneCode" = 'DESPACHO');
  END IF;

  -- Zonas ALM-DEV
  IF v_wh_dev IS NOT NULL THEN
    INSERT INTO inv."WarehouseZone" ("WarehouseId", "ZoneCode", "ZoneName", "ZoneType", "Temperature", "CreatedByUserId")
    SELECT v_wh_dev, 'RECEPCION', 'Zona de Recepción Devoluciones', 'RECEIVING', 'AMBIENT', v_user_id
    WHERE NOT EXISTS (SELECT 1 FROM inv."WarehouseZone" WHERE "WarehouseId" = v_wh_dev AND "ZoneCode" = 'RECEPCION');

    INSERT INTO inv."WarehouseZone" ("WarehouseId", "ZoneCode", "ZoneName", "ZoneType", "Temperature", "CreatedByUserId")
    SELECT v_wh_dev, 'ALMACENAMIENTO', 'Zona de Almacenamiento Devoluciones', 'STORAGE', 'AMBIENT', v_user_id
    WHERE NOT EXISTS (SELECT 1 FROM inv."WarehouseZone" WHERE "WarehouseId" = v_wh_dev AND "ZoneCode" = 'ALMACENAMIENTO');

    INSERT INTO inv."WarehouseZone" ("WarehouseId", "ZoneCode", "ZoneName", "ZoneType", "Temperature", "CreatedByUserId")
    SELECT v_wh_dev, 'PICKING', 'Zona de Inspección', 'PICKING', 'AMBIENT', v_user_id
    WHERE NOT EXISTS (SELECT 1 FROM inv."WarehouseZone" WHERE "WarehouseId" = v_wh_dev AND "ZoneCode" = 'PICKING');

    INSERT INTO inv."WarehouseZone" ("WarehouseId", "ZoneCode", "ZoneName", "ZoneType", "Temperature", "CreatedByUserId")
    SELECT v_wh_dev, 'DESPACHO', 'Zona de Despacho Devoluciones', 'SHIPPING', 'AMBIENT', v_user_id
    WHERE NOT EXISTS (SELECT 1 FROM inv."WarehouseZone" WHERE "WarehouseId" = v_wh_dev AND "ZoneCode" = 'DESPACHO');
  END IF;

  -- ============================================================================
  -- SECCION 3: inv."WarehouseBin" (3 bins por zona en ALM-01)
  -- ============================================================================
  RAISE NOTICE '>> 3. Ubicaciones (bins) demo...';

  IF v_wh1 IS NOT NULL THEN
    SELECT "ZoneId" INTO v_zone_rec FROM inv."WarehouseZone" WHERE "WarehouseId" = v_wh1 AND "ZoneCode" = 'RECEPCION' LIMIT 1;
    SELECT "ZoneId" INTO v_zone_alm FROM inv."WarehouseZone" WHERE "WarehouseId" = v_wh1 AND "ZoneCode" = 'ALMACENAMIENTO' LIMIT 1;
    SELECT "ZoneId" INTO v_zone_pic FROM inv."WarehouseZone" WHERE "WarehouseId" = v_wh1 AND "ZoneCode" = 'PICKING' LIMIT 1;
    SELECT "ZoneId" INTO v_zone_des FROM inv."WarehouseZone" WHERE "WarehouseId" = v_wh1 AND "ZoneCode" = 'DESPACHO' LIMIT 1;

    -- Bins Recepcion
    IF v_zone_rec IS NOT NULL THEN
      INSERT INTO inv."WarehouseBin" ("ZoneId", "BinCode", "BinName", "MaxWeight", "MaxVolume", "CreatedByUserId")
      SELECT v_zone_rec, 'R-01-01', 'Recepción Rack 1 Nivel 1', 500.00, 2.50, v_user_id
      WHERE NOT EXISTS (SELECT 1 FROM inv."WarehouseBin" WHERE "ZoneId" = v_zone_rec AND "BinCode" = 'R-01-01');

      INSERT INTO inv."WarehouseBin" ("ZoneId", "BinCode", "BinName", "MaxWeight", "MaxVolume", "CreatedByUserId")
      SELECT v_zone_rec, 'R-01-02', 'Recepción Rack 1 Nivel 2', 500.00, 2.50, v_user_id
      WHERE NOT EXISTS (SELECT 1 FROM inv."WarehouseBin" WHERE "ZoneId" = v_zone_rec AND "BinCode" = 'R-01-02');

      INSERT INTO inv."WarehouseBin" ("ZoneId", "BinCode", "BinName", "MaxWeight", "MaxVolume", "CreatedByUserId")
      SELECT v_zone_rec, 'R-01-03', 'Recepción Rack 1 Nivel 3', 300.00, 1.80, v_user_id
      WHERE NOT EXISTS (SELECT 1 FROM inv."WarehouseBin" WHERE "ZoneId" = v_zone_rec AND "BinCode" = 'R-01-03');
    END IF;

    -- Bins Almacenamiento
    IF v_zone_alm IS NOT NULL THEN
      INSERT INTO inv."WarehouseBin" ("ZoneId", "BinCode", "BinName", "MaxWeight", "MaxVolume", "CreatedByUserId")
      SELECT v_zone_alm, 'A-01-01', 'Almacén Rack A Nivel 1', 1000.00, 5.00, v_user_id
      WHERE NOT EXISTS (SELECT 1 FROM inv."WarehouseBin" WHERE "ZoneId" = v_zone_alm AND "BinCode" = 'A-01-01');

      INSERT INTO inv."WarehouseBin" ("ZoneId", "BinCode", "BinName", "MaxWeight", "MaxVolume", "CreatedByUserId")
      SELECT v_zone_alm, 'A-01-02', 'Almacén Rack A Nivel 2', 1000.00, 5.00, v_user_id
      WHERE NOT EXISTS (SELECT 1 FROM inv."WarehouseBin" WHERE "ZoneId" = v_zone_alm AND "BinCode" = 'A-01-02');

      INSERT INTO inv."WarehouseBin" ("ZoneId", "BinCode", "BinName", "MaxWeight", "MaxVolume", "CreatedByUserId")
      SELECT v_zone_alm, 'A-01-03', 'Almacén Rack A Nivel 3', 800.00, 4.00, v_user_id
      WHERE NOT EXISTS (SELECT 1 FROM inv."WarehouseBin" WHERE "ZoneId" = v_zone_alm AND "BinCode" = 'A-01-03');
    END IF;

    -- Bins Picking
    IF v_zone_pic IS NOT NULL THEN
      INSERT INTO inv."WarehouseBin" ("ZoneId", "BinCode", "BinName", "MaxWeight", "MaxVolume", "CreatedByUserId")
      SELECT v_zone_pic, 'P-01-01', 'Picking Estante 1', 200.00, 1.20, v_user_id
      WHERE NOT EXISTS (SELECT 1 FROM inv."WarehouseBin" WHERE "ZoneId" = v_zone_pic AND "BinCode" = 'P-01-01');

      INSERT INTO inv."WarehouseBin" ("ZoneId", "BinCode", "BinName", "MaxWeight", "MaxVolume", "CreatedByUserId")
      SELECT v_zone_pic, 'P-01-02', 'Picking Estante 2', 200.00, 1.20, v_user_id
      WHERE NOT EXISTS (SELECT 1 FROM inv."WarehouseBin" WHERE "ZoneId" = v_zone_pic AND "BinCode" = 'P-01-02');

      INSERT INTO inv."WarehouseBin" ("ZoneId", "BinCode", "BinName", "MaxWeight", "MaxVolume", "CreatedByUserId")
      SELECT v_zone_pic, 'P-01-03', 'Picking Estante 3', 200.00, 1.20, v_user_id
      WHERE NOT EXISTS (SELECT 1 FROM inv."WarehouseBin" WHERE "ZoneId" = v_zone_pic AND "BinCode" = 'P-01-03');
    END IF;

    -- Bins Despacho
    IF v_zone_des IS NOT NULL THEN
      INSERT INTO inv."WarehouseBin" ("ZoneId", "BinCode", "BinName", "MaxWeight", "MaxVolume", "CreatedByUserId")
      SELECT v_zone_des, 'D-01-01', 'Despacho Bahía 1', 2000.00, 10.00, v_user_id
      WHERE NOT EXISTS (SELECT 1 FROM inv."WarehouseBin" WHERE "ZoneId" = v_zone_des AND "BinCode" = 'D-01-01');

      INSERT INTO inv."WarehouseBin" ("ZoneId", "BinCode", "BinName", "MaxWeight", "MaxVolume", "CreatedByUserId")
      SELECT v_zone_des, 'D-01-02', 'Despacho Bahía 2', 2000.00, 10.00, v_user_id
      WHERE NOT EXISTS (SELECT 1 FROM inv."WarehouseBin" WHERE "ZoneId" = v_zone_des AND "BinCode" = 'D-01-02');

      INSERT INTO inv."WarehouseBin" ("ZoneId", "BinCode", "BinName", "MaxWeight", "MaxVolume", "CreatedByUserId")
      SELECT v_zone_des, 'D-01-03', 'Despacho Bahía 3', 1500.00, 8.00, v_user_id
      WHERE NOT EXISTS (SELECT 1 FROM inv."WarehouseBin" WHERE "ZoneId" = v_zone_des AND "BinCode" = 'D-01-03');
    END IF;
  END IF;

  -- ============================================================================
  -- SECCION 4: inv."ProductLot" (5 lotes)
  -- ============================================================================
  RAISE NOTICE '>> 4. Lotes de productos demo...';

  INSERT INTO inv."ProductLot" ("CompanyId", "ProductId", "LotNumber", "ManufactureDate", "ExpiryDate", "SupplierCode", "PurchaseDocumentNumber", "InitialQuantity", "CurrentQuantity", "UnitCost", "Status", "Notes", "CreatedByUserId")
  SELECT v_company_id, 1, 'LOT-2026-001', '2026-01-15', '2027-01-15', 'PROV-001', 'OC-2026-0100', 500.000, 320.000, 15.5000, 'ACTIVE', 'Lote de productos electrónicos - stock vigente', v_user_id
  WHERE NOT EXISTS (SELECT 1 FROM inv."ProductLot" WHERE "CompanyId" = v_company_id AND "ProductId" = 1 AND "LotNumber" = 'LOT-2026-001');

  INSERT INTO inv."ProductLot" ("CompanyId", "ProductId", "LotNumber", "ManufactureDate", "ExpiryDate", "SupplierCode", "PurchaseDocumentNumber", "InitialQuantity", "CurrentQuantity", "UnitCost", "Status", "Notes", "CreatedByUserId")
  SELECT v_company_id, 2, 'LOT-2026-002', '2025-06-01', '2026-02-01', 'PROV-002', 'OC-2025-0450', 200.000, 0.000, 22.7500, 'EXPIRED', 'Lote vencido - pendiente destruccion', v_user_id
  WHERE NOT EXISTS (SELECT 1 FROM inv."ProductLot" WHERE "CompanyId" = v_company_id AND "ProductId" = 2 AND "LotNumber" = 'LOT-2026-002');

  INSERT INTO inv."ProductLot" ("CompanyId", "ProductId", "LotNumber", "ManufactureDate", "ExpiryDate", "SupplierCode", "PurchaseDocumentNumber", "InitialQuantity", "CurrentQuantity", "UnitCost", "Status", "Notes", "CreatedByUserId")
  SELECT v_company_id, 3, 'LOT-2026-003', '2026-02-10', '2028-02-10', 'PROV-001', 'OC-2026-0155', 1000.000, 875.000, 8.2000, 'ACTIVE', 'Lote de insumos de oficina', v_user_id
  WHERE NOT EXISTS (SELECT 1 FROM inv."ProductLot" WHERE "CompanyId" = v_company_id AND "ProductId" = 3 AND "LotNumber" = 'LOT-2026-003');

  INSERT INTO inv."ProductLot" ("CompanyId", "ProductId", "LotNumber", "ManufactureDate", "ExpiryDate", "SupplierCode", "PurchaseDocumentNumber", "InitialQuantity", "CurrentQuantity", "UnitCost", "Status", "Notes", "CreatedByUserId")
  SELECT v_company_id, 4, 'LOT-2026-004', '2025-11-20', '2026-05-20', 'PROV-003', 'OC-2025-0890', 300.000, 45.000, 35.0000, 'ACTIVE', 'Lote proximo a vencer - priorizar despacho', v_user_id
  WHERE NOT EXISTS (SELECT 1 FROM inv."ProductLot" WHERE "CompanyId" = v_company_id AND "ProductId" = 4 AND "LotNumber" = 'LOT-2026-004');

  INSERT INTO inv."ProductLot" ("CompanyId", "ProductId", "LotNumber", "ManufactureDate", "ExpiryDate", "SupplierCode", "PurchaseDocumentNumber", "InitialQuantity", "CurrentQuantity", "UnitCost", "Status", "Notes", "CreatedByUserId")
  SELECT v_company_id, 5, 'LOT-2026-005', '2026-03-01', '2029-03-01', 'PROV-002', 'OC-2026-0200', 150.000, 150.000, 120.0000, 'ACTIVE', 'Lote de equipos nuevos sin despachar', v_user_id
  WHERE NOT EXISTS (SELECT 1 FROM inv."ProductLot" WHERE "CompanyId" = v_company_id AND "ProductId" = 5 AND "LotNumber" = 'LOT-2026-005');

  -- ============================================================================
  -- SECCION 5: inv."ProductSerial" (8 seriales)
  -- ============================================================================
  RAISE NOTICE '>> 5. Seriales de productos demo...';

  -- TV Samsung 55" - Disponible
  INSERT INTO inv."ProductSerial" ("CompanyId", "ProductId", "SerialNumber", "WarehouseId", "Status", "PurchaseDocumentNumber", "Notes", "CreatedByUserId")
  SELECT v_company_id, 1, 'SN-TV-001', v_wh1, 'AVAILABLE', 'OC-2026-0100', 'TV Samsung 55 pulgadas - en stock', v_user_id
  WHERE NOT EXISTS (SELECT 1 FROM inv."ProductSerial" WHERE "CompanyId" = v_company_id AND "ProductId" = 1 AND "SerialNumber" = 'SN-TV-001');

  -- TV Samsung 55" - Vendido
  INSERT INTO inv."ProductSerial" ("CompanyId", "ProductId", "SerialNumber", "WarehouseId", "Status", "PurchaseDocumentNumber", "SalesDocumentNumber", "CustomerId", "SoldAt", "Notes", "CreatedByUserId")
  SELECT v_company_id, 1, 'SN-TV-002', NULL, 'SOLD', 'OC-2026-0100', 'FAC-2026-0050', 1, '2026-03-10 14:30:00'::TIMESTAMP, 'Vendido a cliente CLT001', v_user_id
  WHERE NOT EXISTS (SELECT 1 FROM inv."ProductSerial" WHERE "CompanyId" = v_company_id AND "ProductId" = 1 AND "SerialNumber" = 'SN-TV-002');

  -- Laptop HP - Disponible
  INSERT INTO inv."ProductSerial" ("CompanyId", "ProductId", "SerialNumber", "WarehouseId", "Status", "PurchaseDocumentNumber", "WarrantyExpiry", "Notes", "CreatedByUserId")
  SELECT v_company_id, 2, 'SN-LAP-001', v_wh1, 'AVAILABLE', 'OC-2025-0450', '2027-06-01', 'Laptop HP ProBook 450 G10', v_user_id
  WHERE NOT EXISTS (SELECT 1 FROM inv."ProductSerial" WHERE "CompanyId" = v_company_id AND "ProductId" = 2 AND "SerialNumber" = 'SN-LAP-001');

  -- Laptop HP - Devuelto
  INSERT INTO inv."ProductSerial" ("CompanyId", "ProductId", "SerialNumber", "WarehouseId", "Status", "PurchaseDocumentNumber", "SalesDocumentNumber", "CustomerId", "Notes", "CreatedByUserId")
  SELECT v_company_id, 2, 'SN-LAP-002', v_wh_dev, 'RETURNED', 'OC-2025-0450', 'FAC-2026-0035', 2, 'Devuelto por cliente - falla de pantalla', v_user_id
  WHERE NOT EXISTS (SELECT 1 FROM inv."ProductSerial" WHERE "CompanyId" = v_company_id AND "ProductId" = 2 AND "SerialNumber" = 'SN-LAP-002');

  -- Impresora Epson - Disponible
  INSERT INTO inv."ProductSerial" ("CompanyId", "ProductId", "SerialNumber", "WarehouseId", "Status", "PurchaseDocumentNumber", "Notes", "CreatedByUserId")
  SELECT v_company_id, 3, 'SN-IMP-001', v_wh1, 'AVAILABLE', 'OC-2026-0155', 'Impresora Epson L3250 multifuncional', v_user_id
  WHERE NOT EXISTS (SELECT 1 FROM inv."ProductSerial" WHERE "CompanyId" = v_company_id AND "ProductId" = 3 AND "SerialNumber" = 'SN-IMP-001');

  -- Impresora Epson - Defectuosa
  INSERT INTO inv."ProductSerial" ("CompanyId", "ProductId", "SerialNumber", "WarehouseId", "Status", "PurchaseDocumentNumber", "Notes", "CreatedByUserId")
  SELECT v_company_id, 3, 'SN-IMP-002', v_wh_dev, 'DEFECTIVE', 'OC-2026-0155', 'Defecto de fabrica - cabezal obstruido', v_user_id
  WHERE NOT EXISTS (SELECT 1 FROM inv."ProductSerial" WHERE "CompanyId" = v_company_id AND "ProductId" = 3 AND "SerialNumber" = 'SN-IMP-002');

  -- Monitor LG - Vendido
  INSERT INTO inv."ProductSerial" ("CompanyId", "ProductId", "SerialNumber", "WarehouseId", "Status", "PurchaseDocumentNumber", "SalesDocumentNumber", "CustomerId", "SoldAt", "Notes", "CreatedByUserId")
  SELECT v_company_id, 4, 'SN-MON-001', NULL, 'SOLD', 'OC-2025-0890', 'FAC-2026-0042', 3, '2026-02-28 10:15:00'::TIMESTAMP, 'Monitor LG 27" 4K vendido', v_user_id
  WHERE NOT EXISTS (SELECT 1 FROM inv."ProductSerial" WHERE "CompanyId" = v_company_id AND "ProductId" = 4 AND "SerialNumber" = 'SN-MON-001');

  -- Teclado Logitech - Disponible
  INSERT INTO inv."ProductSerial" ("CompanyId", "ProductId", "SerialNumber", "WarehouseId", "Status", "PurchaseDocumentNumber", "Notes", "CreatedByUserId")
  SELECT v_company_id, 5, 'SN-TEC-001', v_wh1, 'AVAILABLE', 'OC-2026-0200', 'Teclado Logitech MX Keys wireless', v_user_id
  WHERE NOT EXISTS (SELECT 1 FROM inv."ProductSerial" WHERE "CompanyId" = v_company_id AND "ProductId" = 5 AND "SerialNumber" = 'SN-TEC-001');

  -- ============================================================================
  -- SECCION 6: inv."ProductBinStock" (5 registros en ALM-01)
  -- ============================================================================
  RAISE NOTICE '>> 6. Stock por ubicacion demo...';

  IF v_wh1 IS NOT NULL AND v_zone_alm IS NOT NULL THEN
    SELECT "BinId" INTO v_bin_a01 FROM inv."WarehouseBin" WHERE "ZoneId" = v_zone_alm AND "BinCode" = 'A-01-01' LIMIT 1;
    SELECT "BinId" INTO v_bin_a02 FROM inv."WarehouseBin" WHERE "ZoneId" = v_zone_alm AND "BinCode" = 'A-01-02' LIMIT 1;
    SELECT "BinId" INTO v_bin_a03 FROM inv."WarehouseBin" WHERE "ZoneId" = v_zone_alm AND "BinCode" = 'A-01-03' LIMIT 1;

    IF v_bin_a01 IS NOT NULL THEN
      INSERT INTO inv."ProductBinStock" ("CompanyId", "ProductId", "WarehouseId", "BinId", "QuantityOnHand", "QuantityReserved", "LastCountDate", "CreatedByUserId")
      SELECT v_company_id, 1, v_wh1, v_bin_a01, 50.000, 5.000, '2026-03-15', v_user_id
      WHERE NOT EXISTS (SELECT 1 FROM inv."ProductBinStock" WHERE "CompanyId" = v_company_id AND "ProductId" = 1 AND "WarehouseId" = v_wh1 AND "BinId" = v_bin_a01 AND "IsDeleted" = FALSE);

      INSERT INTO inv."ProductBinStock" ("CompanyId", "ProductId", "WarehouseId", "BinId", "QuantityOnHand", "QuantityReserved", "LastCountDate", "CreatedByUserId")
      SELECT v_company_id, 2, v_wh1, v_bin_a01, 25.000, 3.000, '2026-03-15', v_user_id
      WHERE NOT EXISTS (SELECT 1 FROM inv."ProductBinStock" WHERE "CompanyId" = v_company_id AND "ProductId" = 2 AND "WarehouseId" = v_wh1 AND "BinId" = v_bin_a01 AND "IsDeleted" = FALSE);
    END IF;

    IF v_bin_a02 IS NOT NULL THEN
      INSERT INTO inv."ProductBinStock" ("CompanyId", "ProductId", "WarehouseId", "BinId", "QuantityOnHand", "QuantityReserved", "LastCountDate", "CreatedByUserId")
      SELECT v_company_id, 3, v_wh1, v_bin_a02, 200.000, 10.000, '2026-03-15', v_user_id
      WHERE NOT EXISTS (SELECT 1 FROM inv."ProductBinStock" WHERE "CompanyId" = v_company_id AND "ProductId" = 3 AND "WarehouseId" = v_wh1 AND "BinId" = v_bin_a02 AND "IsDeleted" = FALSE);

      INSERT INTO inv."ProductBinStock" ("CompanyId", "ProductId", "WarehouseId", "BinId", "QuantityOnHand", "QuantityReserved", "LastCountDate", "CreatedByUserId")
      SELECT v_company_id, 4, v_wh1, v_bin_a02, 45.000, 0.000, '2026-03-15', v_user_id
      WHERE NOT EXISTS (SELECT 1 FROM inv."ProductBinStock" WHERE "CompanyId" = v_company_id AND "ProductId" = 4 AND "WarehouseId" = v_wh1 AND "BinId" = v_bin_a02 AND "IsDeleted" = FALSE);
    END IF;

    IF v_bin_a03 IS NOT NULL THEN
      INSERT INTO inv."ProductBinStock" ("CompanyId", "ProductId", "WarehouseId", "BinId", "QuantityOnHand", "QuantityReserved", "LastCountDate", "CreatedByUserId")
      SELECT v_company_id, 5, v_wh1, v_bin_a03, 150.000, 20.000, '2026-03-15', v_user_id
      WHERE NOT EXISTS (SELECT 1 FROM inv."ProductBinStock" WHERE "CompanyId" = v_company_id AND "ProductId" = 5 AND "WarehouseId" = v_wh1 AND "BinId" = v_bin_a03 AND "IsDeleted" = FALSE);
    END IF;
  END IF;

  -- ============================================================================
  -- SECCION 7: inv."InventoryValuationMethod" (3 metodos)
  -- ============================================================================
  RAISE NOTICE '>> 7. Metodos de valoracion demo...';

  INSERT INTO inv."InventoryValuationMethod" ("CompanyId", "ProductId", "Method", "CreatedByUserId")
  SELECT v_company_id, 1, 'FIFO', v_user_id
  WHERE NOT EXISTS (SELECT 1 FROM inv."InventoryValuationMethod" WHERE "CompanyId" = v_company_id AND "ProductId" = 1 AND "IsDeleted" = FALSE);

  INSERT INTO inv."InventoryValuationMethod" ("CompanyId", "ProductId", "Method", "CreatedByUserId")
  SELECT v_company_id, 2, 'WEIGHTED_AVG', v_user_id
  WHERE NOT EXISTS (SELECT 1 FROM inv."InventoryValuationMethod" WHERE "CompanyId" = v_company_id AND "ProductId" = 2 AND "IsDeleted" = FALSE);

  INSERT INTO inv."InventoryValuationMethod" ("CompanyId", "ProductId", "Method", "CreatedByUserId")
  SELECT v_company_id, 3, 'LAST_COST', v_user_id
  WHERE NOT EXISTS (SELECT 1 FROM inv."InventoryValuationMethod" WHERE "CompanyId" = v_company_id AND "ProductId" = 3 AND "IsDeleted" = FALSE);

  -- ============================================================================
  -- SECCION 8: inv."StockMovement" (5 movimientos)
  -- ============================================================================
  RAISE NOTICE '>> 8. Movimientos de stock demo...';

  -- Entrada por compra
  INSERT INTO inv."StockMovement" ("CompanyId", "BranchId", "ProductId", "ToWarehouseId", "MovementType", "Quantity", "UnitCost", "TotalCost", "SourceDocumentType", "SourceDocumentNumber", "Notes", "MovementDate", "CreatedByUserId")
  SELECT v_company_id, v_branch_id, 1, v_wh1, 'PURCHASE_IN', 500.000, 15.5000, 7750.00, 'PURCHASE', 'OC-2026-0100', 'Ingreso por orden de compra - lote LOT-2026-001', '2026-01-20 09:00:00'::TIMESTAMP, v_user_id
  WHERE NOT EXISTS (SELECT 1 FROM inv."StockMovement" WHERE "CompanyId" = v_company_id AND "SourceDocumentNumber" = 'OC-2026-0100' AND "MovementType" = 'PURCHASE_IN');

  -- Salida por venta
  INSERT INTO inv."StockMovement" ("CompanyId", "BranchId", "ProductId", "FromWarehouseId", "MovementType", "Quantity", "UnitCost", "TotalCost", "SourceDocumentType", "SourceDocumentNumber", "Notes", "MovementDate", "CreatedByUserId")
  SELECT v_company_id, v_branch_id, 1, v_wh1, 'SALE_OUT', 10.000, 15.5000, 155.00, 'INVOICE', 'FAC-2026-0050', 'Despacho por factura de venta', '2026-03-10 14:30:00'::TIMESTAMP, v_user_id
  WHERE NOT EXISTS (SELECT 1 FROM inv."StockMovement" WHERE "CompanyId" = v_company_id AND "SourceDocumentNumber" = 'FAC-2026-0050' AND "MovementType" = 'SALE_OUT');

  -- Transferencia entre almacenes
  INSERT INTO inv."StockMovement" ("CompanyId", "BranchId", "ProductId", "FromWarehouseId", "ToWarehouseId", "MovementType", "Quantity", "UnitCost", "TotalCost", "SourceDocumentType", "SourceDocumentNumber", "Notes", "MovementDate", "CreatedByUserId")
  SELECT v_company_id, v_branch_id, 3, v_wh1, v_wh2, 'TRANSFER', 50.000, 8.2000, 410.00, 'TRANSFER', 'TRF-2026-0010', 'Transferencia de insumos a almacen secundario', '2026-02-15 11:00:00'::TIMESTAMP, v_user_id
  WHERE NOT EXISTS (SELECT 1 FROM inv."StockMovement" WHERE "CompanyId" = v_company_id AND "SourceDocumentNumber" = 'TRF-2026-0010' AND "MovementType" = 'TRANSFER');

  -- Ajuste de inventario
  INSERT INTO inv."StockMovement" ("CompanyId", "BranchId", "ProductId", "FromWarehouseId", "MovementType", "Quantity", "UnitCost", "TotalCost", "SourceDocumentType", "SourceDocumentNumber", "Notes", "MovementDate", "CreatedByUserId")
  SELECT v_company_id, v_branch_id, 4, v_wh1, 'ADJUSTMENT', -5.000, 35.0000, -175.00, 'ADJUSTMENT', 'AJU-2026-0003', 'Ajuste por diferencia en conteo fisico', '2026-03-01 16:00:00'::TIMESTAMP, v_user_id
  WHERE NOT EXISTS (SELECT 1 FROM inv."StockMovement" WHERE "CompanyId" = v_company_id AND "SourceDocumentNumber" = 'AJU-2026-0003' AND "MovementType" = 'ADJUSTMENT');

  -- Devolucion de cliente
  INSERT INTO inv."StockMovement" ("CompanyId", "BranchId", "ProductId", "ToWarehouseId", "MovementType", "Quantity", "UnitCost", "TotalCost", "SourceDocumentType", "SourceDocumentNumber", "Notes", "MovementDate", "CreatedByUserId")
  SELECT v_company_id, v_branch_id, 2, v_wh_dev, 'RETURN_IN', 1.000, 22.7500, 22.75, 'RETURN', 'DEV-2026-0001', 'Devolucion de cliente por falla de pantalla - laptop SN-LAP-002', '2026-03-05 09:45:00'::TIMESTAMP, v_user_id
  WHERE NOT EXISTS (SELECT 1 FROM inv."StockMovement" WHERE "CompanyId" = v_company_id AND "SourceDocumentNumber" = 'DEV-2026-0001' AND "MovementType" = 'RETURN_IN');

  RAISE NOTICE '=== Seed demo: Inventario Avanzado — COMPLETO ===';
END $$;
