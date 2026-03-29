/*
 * seed_demo_inventario_avanzado.sql
 * ─────────────────────────────────
 * Seed de datos demo para modulo de Inventario Avanzado.
 * Idempotente: verifica existencia antes de cada INSERT.
 *
 * Tablas afectadas:
 *   inv.Warehouse, inv.WarehouseZone, inv.WarehouseBin,
 *   inv.ProductLot, inv.ProductSerial, inv.ProductBinStock,
 *   inv.InventoryValuationMethod, inv.StockMovement
 */
USE DatqBoxWeb;
GO
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

SET NOCOUNT ON;
GO

PRINT '=== Seed demo: Inventario Avanzado ===';
GO

-- ============================================================================
-- SECCION 1: inv.Warehouse  (3 almacenes)
-- ============================================================================
PRINT '>> 1. Almacenes demo...';

IF NOT EXISTS (SELECT 1 FROM inv.Warehouse WHERE CompanyId = 1 AND WarehouseCode = N'ALM-01')
  INSERT INTO inv.Warehouse (CompanyId, BranchId, WarehouseCode, WarehouseName, AddressLine, ContactName, Phone, CreatedByUserId)
  VALUES (1, 1, N'ALM-01', N'Almacén Principal', N'Zona Industrial La Yaguara, Galpón 12, Caracas', N'Pedro Ramírez', N'+58-212-5551001', 1);

IF NOT EXISTS (SELECT 1 FROM inv.Warehouse WHERE CompanyId = 1 AND WarehouseCode = N'ALM-02')
  INSERT INTO inv.Warehouse (CompanyId, BranchId, WarehouseCode, WarehouseName, AddressLine, ContactName, Phone, CreatedByUserId)
  VALUES (1, 1, N'ALM-02', N'Almacén Secundario', N'Av. Intercomunal, Guarenas, Galpón 5, Miranda', N'Luisa Fernández', N'+58-212-5552002', 1);

IF NOT EXISTS (SELECT 1 FROM inv.Warehouse WHERE CompanyId = 1 AND WarehouseCode = N'ALM-DEV')
  INSERT INTO inv.Warehouse (CompanyId, BranchId, WarehouseCode, WarehouseName, AddressLine, ContactName, Phone, CreatedByUserId)
  VALUES (1, 1, N'ALM-DEV', N'Almacén Devoluciones', N'Zona Industrial La Yaguara, Galpón 12-B, Caracas', N'Pedro Ramírez', N'+58-212-5551002', 1);
GO

-- ============================================================================
-- SECCION 2: inv.WarehouseZone  (4 zonas por almacen)
-- ============================================================================
PRINT '>> 2. Zonas de almacen demo...';

-- Zonas ALM-01
DECLARE @WH1 BIGINT = (SELECT WarehouseId FROM inv.Warehouse WHERE CompanyId = 1 AND WarehouseCode = N'ALM-01');
DECLARE @WH2 BIGINT = (SELECT WarehouseId FROM inv.Warehouse WHERE CompanyId = 1 AND WarehouseCode = N'ALM-02');
DECLARE @WH3 BIGINT = (SELECT WarehouseId FROM inv.Warehouse WHERE CompanyId = 1 AND WarehouseCode = N'ALM-DEV');

IF @WH1 IS NOT NULL
BEGIN
  IF NOT EXISTS (SELECT 1 FROM inv.WarehouseZone WHERE WarehouseId = @WH1 AND ZoneCode = N'RECEPCION')
    INSERT INTO inv.WarehouseZone (WarehouseId, ZoneCode, ZoneName, ZoneType, Temperature, CreatedByUserId)
    VALUES (@WH1, N'RECEPCION', N'Zona de Recepción', N'RECEIVING', N'AMBIENT', 1);

  IF NOT EXISTS (SELECT 1 FROM inv.WarehouseZone WHERE WarehouseId = @WH1 AND ZoneCode = N'ALMACENAMIENTO')
    INSERT INTO inv.WarehouseZone (WarehouseId, ZoneCode, ZoneName, ZoneType, Temperature, CreatedByUserId)
    VALUES (@WH1, N'ALMACENAMIENTO', N'Zona de Almacenamiento', N'STORAGE', N'AMBIENT', 1);

  IF NOT EXISTS (SELECT 1 FROM inv.WarehouseZone WHERE WarehouseId = @WH1 AND ZoneCode = N'PICKING')
    INSERT INTO inv.WarehouseZone (WarehouseId, ZoneCode, ZoneName, ZoneType, Temperature, CreatedByUserId)
    VALUES (@WH1, N'PICKING', N'Zona de Picking', N'PICKING', N'AMBIENT', 1);

  IF NOT EXISTS (SELECT 1 FROM inv.WarehouseZone WHERE WarehouseId = @WH1 AND ZoneCode = N'DESPACHO')
    INSERT INTO inv.WarehouseZone (WarehouseId, ZoneCode, ZoneName, ZoneType, Temperature, CreatedByUserId)
    VALUES (@WH1, N'DESPACHO', N'Zona de Despacho', N'SHIPPING', N'AMBIENT', 1);
END;

-- Zonas ALM-02
IF @WH2 IS NOT NULL
BEGIN
  IF NOT EXISTS (SELECT 1 FROM inv.WarehouseZone WHERE WarehouseId = @WH2 AND ZoneCode = N'RECEPCION')
    INSERT INTO inv.WarehouseZone (WarehouseId, ZoneCode, ZoneName, ZoneType, Temperature, CreatedByUserId)
    VALUES (@WH2, N'RECEPCION', N'Zona de Recepción', N'RECEIVING', N'AMBIENT', 1);

  IF NOT EXISTS (SELECT 1 FROM inv.WarehouseZone WHERE WarehouseId = @WH2 AND ZoneCode = N'ALMACENAMIENTO')
    INSERT INTO inv.WarehouseZone (WarehouseId, ZoneCode, ZoneName, ZoneType, Temperature, CreatedByUserId)
    VALUES (@WH2, N'ALMACENAMIENTO', N'Zona de Almacenamiento', N'STORAGE', N'COLD', 1);

  IF NOT EXISTS (SELECT 1 FROM inv.WarehouseZone WHERE WarehouseId = @WH2 AND ZoneCode = N'PICKING')
    INSERT INTO inv.WarehouseZone (WarehouseId, ZoneCode, ZoneName, ZoneType, Temperature, CreatedByUserId)
    VALUES (@WH2, N'PICKING', N'Zona de Picking', N'PICKING', N'COLD', 1);

  IF NOT EXISTS (SELECT 1 FROM inv.WarehouseZone WHERE WarehouseId = @WH2 AND ZoneCode = N'DESPACHO')
    INSERT INTO inv.WarehouseZone (WarehouseId, ZoneCode, ZoneName, ZoneType, Temperature, CreatedByUserId)
    VALUES (@WH2, N'DESPACHO', N'Zona de Despacho', N'SHIPPING', N'AMBIENT', 1);
END;

-- Zonas ALM-DEV
IF @WH3 IS NOT NULL
BEGIN
  IF NOT EXISTS (SELECT 1 FROM inv.WarehouseZone WHERE WarehouseId = @WH3 AND ZoneCode = N'RECEPCION')
    INSERT INTO inv.WarehouseZone (WarehouseId, ZoneCode, ZoneName, ZoneType, Temperature, CreatedByUserId)
    VALUES (@WH3, N'RECEPCION', N'Zona de Recepción Devoluciones', N'RECEIVING', N'AMBIENT', 1);

  IF NOT EXISTS (SELECT 1 FROM inv.WarehouseZone WHERE WarehouseId = @WH3 AND ZoneCode = N'ALMACENAMIENTO')
    INSERT INTO inv.WarehouseZone (WarehouseId, ZoneCode, ZoneName, ZoneType, Temperature, CreatedByUserId)
    VALUES (@WH3, N'ALMACENAMIENTO', N'Zona de Almacenamiento Devoluciones', N'STORAGE', N'AMBIENT', 1);

  IF NOT EXISTS (SELECT 1 FROM inv.WarehouseZone WHERE WarehouseId = @WH3 AND ZoneCode = N'PICKING')
    INSERT INTO inv.WarehouseZone (WarehouseId, ZoneCode, ZoneName, ZoneType, Temperature, CreatedByUserId)
    VALUES (@WH3, N'PICKING', N'Zona de Inspección', N'PICKING', N'AMBIENT', 1);

  IF NOT EXISTS (SELECT 1 FROM inv.WarehouseZone WHERE WarehouseId = @WH3 AND ZoneCode = N'DESPACHO')
    INSERT INTO inv.WarehouseZone (WarehouseId, ZoneCode, ZoneName, ZoneType, Temperature, CreatedByUserId)
    VALUES (@WH3, N'DESPACHO', N'Zona de Despacho Devoluciones', N'SHIPPING', N'AMBIENT', 1);
END;
GO

-- ============================================================================
-- SECCION 3: inv.WarehouseBin  (3 bins por zona en ALM-01)
-- ============================================================================
PRINT '>> 3. Ubicaciones (bins) demo...';

DECLARE @WH1B BIGINT = (SELECT WarehouseId FROM inv.Warehouse WHERE CompanyId = 1 AND WarehouseCode = N'ALM-01');

IF @WH1B IS NOT NULL
BEGIN
  DECLARE @ZoneRec BIGINT = (SELECT ZoneId FROM inv.WarehouseZone WHERE WarehouseId = @WH1B AND ZoneCode = N'RECEPCION');
  DECLARE @ZoneAlm BIGINT = (SELECT ZoneId FROM inv.WarehouseZone WHERE WarehouseId = @WH1B AND ZoneCode = N'ALMACENAMIENTO');
  DECLARE @ZonePic BIGINT = (SELECT ZoneId FROM inv.WarehouseZone WHERE WarehouseId = @WH1B AND ZoneCode = N'PICKING');
  DECLARE @ZoneDes BIGINT = (SELECT ZoneId FROM inv.WarehouseZone WHERE WarehouseId = @WH1B AND ZoneCode = N'DESPACHO');

  -- Bins Recepcion
  IF @ZoneRec IS NOT NULL
  BEGIN
    IF NOT EXISTS (SELECT 1 FROM inv.WarehouseBin WHERE ZoneId = @ZoneRec AND BinCode = N'R-01-01')
      INSERT INTO inv.WarehouseBin (ZoneId, BinCode, BinName, MaxWeight, MaxVolume, CreatedByUserId) VALUES (@ZoneRec, N'R-01-01', N'Recepción Rack 1 Nivel 1', 500.00, 2.50, 1);
    IF NOT EXISTS (SELECT 1 FROM inv.WarehouseBin WHERE ZoneId = @ZoneRec AND BinCode = N'R-01-02')
      INSERT INTO inv.WarehouseBin (ZoneId, BinCode, BinName, MaxWeight, MaxVolume, CreatedByUserId) VALUES (@ZoneRec, N'R-01-02', N'Recepción Rack 1 Nivel 2', 500.00, 2.50, 1);
    IF NOT EXISTS (SELECT 1 FROM inv.WarehouseBin WHERE ZoneId = @ZoneRec AND BinCode = N'R-01-03')
      INSERT INTO inv.WarehouseBin (ZoneId, BinCode, BinName, MaxWeight, MaxVolume, CreatedByUserId) VALUES (@ZoneRec, N'R-01-03', N'Recepción Rack 1 Nivel 3', 300.00, 1.80, 1);
  END;

  -- Bins Almacenamiento
  IF @ZoneAlm IS NOT NULL
  BEGIN
    IF NOT EXISTS (SELECT 1 FROM inv.WarehouseBin WHERE ZoneId = @ZoneAlm AND BinCode = N'A-01-01')
      INSERT INTO inv.WarehouseBin (ZoneId, BinCode, BinName, MaxWeight, MaxVolume, CreatedByUserId) VALUES (@ZoneAlm, N'A-01-01', N'Almacén Rack A Nivel 1', 1000.00, 5.00, 1);
    IF NOT EXISTS (SELECT 1 FROM inv.WarehouseBin WHERE ZoneId = @ZoneAlm AND BinCode = N'A-01-02')
      INSERT INTO inv.WarehouseBin (ZoneId, BinCode, BinName, MaxWeight, MaxVolume, CreatedByUserId) VALUES (@ZoneAlm, N'A-01-02', N'Almacén Rack A Nivel 2', 1000.00, 5.00, 1);
    IF NOT EXISTS (SELECT 1 FROM inv.WarehouseBin WHERE ZoneId = @ZoneAlm AND BinCode = N'A-01-03')
      INSERT INTO inv.WarehouseBin (ZoneId, BinCode, BinName, MaxWeight, MaxVolume, CreatedByUserId) VALUES (@ZoneAlm, N'A-01-03', N'Almacén Rack A Nivel 3', 800.00, 4.00, 1);
  END;

  -- Bins Picking
  IF @ZonePic IS NOT NULL
  BEGIN
    IF NOT EXISTS (SELECT 1 FROM inv.WarehouseBin WHERE ZoneId = @ZonePic AND BinCode = N'P-01-01')
      INSERT INTO inv.WarehouseBin (ZoneId, BinCode, BinName, MaxWeight, MaxVolume, CreatedByUserId) VALUES (@ZonePic, N'P-01-01', N'Picking Estante 1', 200.00, 1.20, 1);
    IF NOT EXISTS (SELECT 1 FROM inv.WarehouseBin WHERE ZoneId = @ZonePic AND BinCode = N'P-01-02')
      INSERT INTO inv.WarehouseBin (ZoneId, BinCode, BinName, MaxWeight, MaxVolume, CreatedByUserId) VALUES (@ZonePic, N'P-01-02', N'Picking Estante 2', 200.00, 1.20, 1);
    IF NOT EXISTS (SELECT 1 FROM inv.WarehouseBin WHERE ZoneId = @ZonePic AND BinCode = N'P-01-03')
      INSERT INTO inv.WarehouseBin (ZoneId, BinCode, BinName, MaxWeight, MaxVolume, CreatedByUserId) VALUES (@ZonePic, N'P-01-03', N'Picking Estante 3', 200.00, 1.20, 1);
  END;

  -- Bins Despacho
  IF @ZoneDes IS NOT NULL
  BEGIN
    IF NOT EXISTS (SELECT 1 FROM inv.WarehouseBin WHERE ZoneId = @ZoneDes AND BinCode = N'D-01-01')
      INSERT INTO inv.WarehouseBin (ZoneId, BinCode, BinName, MaxWeight, MaxVolume, CreatedByUserId) VALUES (@ZoneDes, N'D-01-01', N'Despacho Bahía 1', 2000.00, 10.00, 1);
    IF NOT EXISTS (SELECT 1 FROM inv.WarehouseBin WHERE ZoneId = @ZoneDes AND BinCode = N'D-01-02')
      INSERT INTO inv.WarehouseBin (ZoneId, BinCode, BinName, MaxWeight, MaxVolume, CreatedByUserId) VALUES (@ZoneDes, N'D-01-02', N'Despacho Bahía 2', 2000.00, 10.00, 1);
    IF NOT EXISTS (SELECT 1 FROM inv.WarehouseBin WHERE ZoneId = @ZoneDes AND BinCode = N'D-01-03')
      INSERT INTO inv.WarehouseBin (ZoneId, BinCode, BinName, MaxWeight, MaxVolume, CreatedByUserId) VALUES (@ZoneDes, N'D-01-03', N'Despacho Bahía 3', 1500.00, 8.00, 1);
  END;
END;
GO

-- ============================================================================
-- SECCION 4: inv.ProductLot  (5 lotes)
-- ============================================================================
PRINT '>> 4. Lotes de productos demo...';

IF NOT EXISTS (SELECT 1 FROM inv.ProductLot WHERE CompanyId = 1 AND LotNumber = N'LOT-2026-001')
  INSERT INTO inv.ProductLot (CompanyId, ProductId, LotNumber, ManufactureDate, ExpiryDate, SupplierCode, PurchaseDocumentNumber, InitialQuantity, CurrentQuantity, UnitCost, Status, Notes, CreatedByUserId)
  VALUES (1, 1, N'LOT-2026-001', '2026-01-15', '2027-01-15', N'PROV-001', N'OC-2026-0100', 500.000, 320.000, 15.5000, N'ACTIVE', N'Lote de productos electrónicos - stock vigente', 1);

IF NOT EXISTS (SELECT 1 FROM inv.ProductLot WHERE CompanyId = 1 AND LotNumber = N'LOT-2026-002')
  INSERT INTO inv.ProductLot (CompanyId, ProductId, LotNumber, ManufactureDate, ExpiryDate, SupplierCode, PurchaseDocumentNumber, InitialQuantity, CurrentQuantity, UnitCost, Status, Notes, CreatedByUserId)
  VALUES (1, 2, N'LOT-2026-002', '2025-06-01', '2026-02-01', N'PROV-002', N'OC-2025-0450', 200.000, 0.000, 22.7500, N'EXPIRED', N'Lote vencido - pendiente destruccion', 1);

IF NOT EXISTS (SELECT 1 FROM inv.ProductLot WHERE CompanyId = 1 AND LotNumber = N'LOT-2026-003')
  INSERT INTO inv.ProductLot (CompanyId, ProductId, LotNumber, ManufactureDate, ExpiryDate, SupplierCode, PurchaseDocumentNumber, InitialQuantity, CurrentQuantity, UnitCost, Status, Notes, CreatedByUserId)
  VALUES (1, 3, N'LOT-2026-003', '2026-02-10', '2028-02-10', N'PROV-001', N'OC-2026-0155', 1000.000, 875.000, 8.2000, N'ACTIVE', N'Lote de insumos de oficina', 1);

IF NOT EXISTS (SELECT 1 FROM inv.ProductLot WHERE CompanyId = 1 AND LotNumber = N'LOT-2026-004')
  INSERT INTO inv.ProductLot (CompanyId, ProductId, LotNumber, ManufactureDate, ExpiryDate, SupplierCode, PurchaseDocumentNumber, InitialQuantity, CurrentQuantity, UnitCost, Status, Notes, CreatedByUserId)
  VALUES (1, 4, N'LOT-2026-004', '2025-11-20', '2026-05-20', N'PROV-003', N'OC-2025-0890', 300.000, 45.000, 35.0000, N'ACTIVE', N'Lote proximo a vencer - priorizar despacho', 1);

IF NOT EXISTS (SELECT 1 FROM inv.ProductLot WHERE CompanyId = 1 AND LotNumber = N'LOT-2026-005')
  INSERT INTO inv.ProductLot (CompanyId, ProductId, LotNumber, ManufactureDate, ExpiryDate, SupplierCode, PurchaseDocumentNumber, InitialQuantity, CurrentQuantity, UnitCost, Status, Notes, CreatedByUserId)
  VALUES (1, 5, N'LOT-2026-005', '2026-03-01', '2029-03-01', N'PROV-002', N'OC-2026-0200', 150.000, 150.000, 120.0000, N'ACTIVE', N'Lote de equipos nuevos sin despachar', 1);
GO

-- ============================================================================
-- SECCION 5: inv.ProductSerial  (8 seriales)
-- ============================================================================
PRINT '>> 5. Seriales de productos demo...';

DECLARE @WH1S BIGINT = (SELECT WarehouseId FROM inv.Warehouse WHERE CompanyId = 1 AND WarehouseCode = N'ALM-01');
DECLARE @WH_DEV BIGINT = (SELECT WarehouseId FROM inv.Warehouse WHERE CompanyId = 1 AND WarehouseCode = N'ALM-DEV');

-- TV Samsung 55" - Disponible
IF NOT EXISTS (SELECT 1 FROM inv.ProductSerial WHERE CompanyId = 1 AND SerialNumber = N'SN-TV-001')
  INSERT INTO inv.ProductSerial (CompanyId, ProductId, SerialNumber, WarehouseId, Status, PurchaseDocumentNumber, Notes, CreatedByUserId)
  VALUES (1, 1, N'SN-TV-001', @WH1S, N'AVAILABLE', N'OC-2026-0100', N'TV Samsung 55 pulgadas - en stock', 1);

-- TV Samsung 55" - Vendido
IF NOT EXISTS (SELECT 1 FROM inv.ProductSerial WHERE CompanyId = 1 AND SerialNumber = N'SN-TV-002')
  INSERT INTO inv.ProductSerial (CompanyId, ProductId, SerialNumber, WarehouseId, Status, PurchaseDocumentNumber, SalesDocumentNumber, CustomerId, SoldAt, Notes, CreatedByUserId)
  VALUES (1, 1, N'SN-TV-002', NULL, N'SOLD', N'OC-2026-0100', N'FAC-2026-0050', 1, '2026-03-10 14:30:00', N'Vendido a cliente CLT001', 1);

-- Laptop HP - Disponible
IF NOT EXISTS (SELECT 1 FROM inv.ProductSerial WHERE CompanyId = 1 AND SerialNumber = N'SN-LAP-001')
  INSERT INTO inv.ProductSerial (CompanyId, ProductId, SerialNumber, WarehouseId, Status, PurchaseDocumentNumber, WarrantyExpiry, Notes, CreatedByUserId)
  VALUES (1, 2, N'SN-LAP-001', @WH1S, N'AVAILABLE', N'OC-2025-0450', '2027-06-01', N'Laptop HP ProBook 450 G10', 1);

-- Laptop HP - Devuelto
IF NOT EXISTS (SELECT 1 FROM inv.ProductSerial WHERE CompanyId = 1 AND SerialNumber = N'SN-LAP-002')
  INSERT INTO inv.ProductSerial (CompanyId, ProductId, SerialNumber, WarehouseId, Status, PurchaseDocumentNumber, SalesDocumentNumber, CustomerId, Notes, CreatedByUserId)
  VALUES (1, 2, N'SN-LAP-002', @WH_DEV, N'RETURNED', N'OC-2025-0450', N'FAC-2026-0035', 2, N'Devuelto por cliente - falla de pantalla', 1);

-- Impresora Epson - Disponible
IF NOT EXISTS (SELECT 1 FROM inv.ProductSerial WHERE CompanyId = 1 AND SerialNumber = N'SN-IMP-001')
  INSERT INTO inv.ProductSerial (CompanyId, ProductId, SerialNumber, WarehouseId, Status, PurchaseDocumentNumber, Notes, CreatedByUserId)
  VALUES (1, 3, N'SN-IMP-001', @WH1S, N'AVAILABLE', N'OC-2026-0155', N'Impresora Epson L3250 multifuncional', 1);

-- Impresora Epson - Defectuosa
IF NOT EXISTS (SELECT 1 FROM inv.ProductSerial WHERE CompanyId = 1 AND SerialNumber = N'SN-IMP-002')
  INSERT INTO inv.ProductSerial (CompanyId, ProductId, SerialNumber, WarehouseId, Status, PurchaseDocumentNumber, Notes, CreatedByUserId)
  VALUES (1, 3, N'SN-IMP-002', @WH_DEV, N'DEFECTIVE', N'OC-2026-0155', N'Defecto de fabrica - cabezal obstruido', 1);

-- Monitor LG - Vendido
IF NOT EXISTS (SELECT 1 FROM inv.ProductSerial WHERE CompanyId = 1 AND SerialNumber = N'SN-MON-001')
  INSERT INTO inv.ProductSerial (CompanyId, ProductId, SerialNumber, WarehouseId, Status, PurchaseDocumentNumber, SalesDocumentNumber, CustomerId, SoldAt, Notes, CreatedByUserId)
  VALUES (1, 4, N'SN-MON-001', NULL, N'SOLD', N'OC-2025-0890', N'FAC-2026-0042', 3, '2026-02-28 10:15:00', N'Monitor LG 27" 4K vendido', 1);

-- Teclado Logitech - Disponible
IF NOT EXISTS (SELECT 1 FROM inv.ProductSerial WHERE CompanyId = 1 AND SerialNumber = N'SN-TEC-001')
  INSERT INTO inv.ProductSerial (CompanyId, ProductId, SerialNumber, WarehouseId, Status, PurchaseDocumentNumber, Notes, CreatedByUserId)
  VALUES (1, 5, N'SN-TEC-001', @WH1S, N'AVAILABLE', N'OC-2026-0200', N'Teclado Logitech MX Keys wireless', 1);
GO

-- ============================================================================
-- SECCION 6: inv.ProductBinStock  (5 registros en ALM-01)
-- ============================================================================
PRINT '>> 6. Stock por ubicacion demo...';

DECLARE @WH1PBS BIGINT = (SELECT WarehouseId FROM inv.Warehouse WHERE CompanyId = 1 AND WarehouseCode = N'ALM-01');
DECLARE @ZoneAlmPBS BIGINT = (SELECT ZoneId FROM inv.WarehouseZone WHERE WarehouseId = @WH1PBS AND ZoneCode = N'ALMACENAMIENTO');
DECLARE @BinA01 BIGINT, @BinA02 BIGINT, @BinA03 BIGINT;

IF @ZoneAlmPBS IS NOT NULL
BEGIN
  SET @BinA01 = (SELECT BinId FROM inv.WarehouseBin WHERE ZoneId = @ZoneAlmPBS AND BinCode = N'A-01-01');
  SET @BinA02 = (SELECT BinId FROM inv.WarehouseBin WHERE ZoneId = @ZoneAlmPBS AND BinCode = N'A-01-02');
  SET @BinA03 = (SELECT BinId FROM inv.WarehouseBin WHERE ZoneId = @ZoneAlmPBS AND BinCode = N'A-01-03');

  IF @BinA01 IS NOT NULL AND NOT EXISTS (SELECT 1 FROM inv.ProductBinStock WHERE CompanyId = 1 AND ProductId = 1 AND WarehouseId = @WH1PBS AND BinId = @BinA01)
    INSERT INTO inv.ProductBinStock (CompanyId, ProductId, WarehouseId, BinId, QuantityOnHand, QuantityReserved, LastCountDate, CreatedByUserId)
    VALUES (1, 1, @WH1PBS, @BinA01, 50.000, 5.000, '2026-03-15', 1);

  IF @BinA01 IS NOT NULL AND NOT EXISTS (SELECT 1 FROM inv.ProductBinStock WHERE CompanyId = 1 AND ProductId = 2 AND WarehouseId = @WH1PBS AND BinId = @BinA01)
    INSERT INTO inv.ProductBinStock (CompanyId, ProductId, WarehouseId, BinId, QuantityOnHand, QuantityReserved, LastCountDate, CreatedByUserId)
    VALUES (1, 2, @WH1PBS, @BinA01, 25.000, 3.000, '2026-03-15', 1);

  IF @BinA02 IS NOT NULL AND NOT EXISTS (SELECT 1 FROM inv.ProductBinStock WHERE CompanyId = 1 AND ProductId = 3 AND WarehouseId = @WH1PBS AND BinId = @BinA02)
    INSERT INTO inv.ProductBinStock (CompanyId, ProductId, WarehouseId, BinId, QuantityOnHand, QuantityReserved, LastCountDate, CreatedByUserId)
    VALUES (1, 3, @WH1PBS, @BinA02, 200.000, 10.000, '2026-03-15', 1);

  IF @BinA02 IS NOT NULL AND NOT EXISTS (SELECT 1 FROM inv.ProductBinStock WHERE CompanyId = 1 AND ProductId = 4 AND WarehouseId = @WH1PBS AND BinId = @BinA02)
    INSERT INTO inv.ProductBinStock (CompanyId, ProductId, WarehouseId, BinId, QuantityOnHand, QuantityReserved, LastCountDate, CreatedByUserId)
    VALUES (1, 4, @WH1PBS, @BinA02, 45.000, 0.000, '2026-03-15', 1);

  IF @BinA03 IS NOT NULL AND NOT EXISTS (SELECT 1 FROM inv.ProductBinStock WHERE CompanyId = 1 AND ProductId = 5 AND WarehouseId = @WH1PBS AND BinId = @BinA03)
    INSERT INTO inv.ProductBinStock (CompanyId, ProductId, WarehouseId, BinId, QuantityOnHand, QuantityReserved, LastCountDate, CreatedByUserId)
    VALUES (1, 5, @WH1PBS, @BinA03, 150.000, 20.000, '2026-03-15', 1);
END;
GO

-- ============================================================================
-- SECCION 7: inv.InventoryValuationMethod  (3 metodos)
-- ============================================================================
PRINT '>> 7. Metodos de valoracion demo...';

IF NOT EXISTS (SELECT 1 FROM inv.InventoryValuationMethod WHERE CompanyId = 1 AND ProductId = 1)
  INSERT INTO inv.InventoryValuationMethod (CompanyId, ProductId, Method, CreatedByUserId)
  VALUES (1, 1, N'FIFO', 1);

IF NOT EXISTS (SELECT 1 FROM inv.InventoryValuationMethod WHERE CompanyId = 1 AND ProductId = 2)
  INSERT INTO inv.InventoryValuationMethod (CompanyId, ProductId, Method, CreatedByUserId)
  VALUES (1, 2, N'WEIGHTED_AVG', 1);

IF NOT EXISTS (SELECT 1 FROM inv.InventoryValuationMethod WHERE CompanyId = 1 AND ProductId = 3)
  INSERT INTO inv.InventoryValuationMethod (CompanyId, ProductId, Method, CreatedByUserId)
  VALUES (1, 3, N'LAST_COST', 1);
GO

-- ============================================================================
-- SECCION 8: inv.StockMovement  (5 movimientos)
-- ============================================================================
PRINT '>> 8. Movimientos de stock demo...';

DECLARE @WH1M BIGINT = (SELECT WarehouseId FROM inv.Warehouse WHERE CompanyId = 1 AND WarehouseCode = N'ALM-01');
DECLARE @WH2M BIGINT = (SELECT WarehouseId FROM inv.Warehouse WHERE CompanyId = 1 AND WarehouseCode = N'ALM-02');
DECLARE @WH_DEVM BIGINT = (SELECT WarehouseId FROM inv.Warehouse WHERE CompanyId = 1 AND WarehouseCode = N'ALM-DEV');

-- Entrada por compra
IF NOT EXISTS (SELECT 1 FROM inv.StockMovement WHERE CompanyId = 1 AND SourceDocumentNumber = N'OC-2026-0100' AND MovementType = N'PURCHASE_IN')
  INSERT INTO inv.StockMovement (CompanyId, BranchId, ProductId, ToWarehouseId, MovementType, Quantity, UnitCost, TotalCost, SourceDocumentType, SourceDocumentNumber, Notes, MovementDate, CreatedByUserId)
  VALUES (1, 1, 1, @WH1M, N'PURCHASE_IN', 500.000, 15.5000, 7750.00, N'PURCHASE', N'OC-2026-0100', N'Ingreso por orden de compra - lote LOT-2026-001', '2026-01-20 09:00:00', 1);

-- Salida por venta
IF NOT EXISTS (SELECT 1 FROM inv.StockMovement WHERE CompanyId = 1 AND SourceDocumentNumber = N'FAC-2026-0050' AND MovementType = N'SALE_OUT')
  INSERT INTO inv.StockMovement (CompanyId, BranchId, ProductId, FromWarehouseId, MovementType, Quantity, UnitCost, TotalCost, SourceDocumentType, SourceDocumentNumber, Notes, MovementDate, CreatedByUserId)
  VALUES (1, 1, 1, @WH1M, N'SALE_OUT', 10.000, 15.5000, 155.00, N'INVOICE', N'FAC-2026-0050', N'Despacho por factura de venta', '2026-03-10 14:30:00', 1);

-- Transferencia entre almacenes
IF NOT EXISTS (SELECT 1 FROM inv.StockMovement WHERE CompanyId = 1 AND SourceDocumentNumber = N'TRF-2026-0010' AND MovementType = N'TRANSFER')
  INSERT INTO inv.StockMovement (CompanyId, BranchId, ProductId, FromWarehouseId, ToWarehouseId, MovementType, Quantity, UnitCost, TotalCost, SourceDocumentType, SourceDocumentNumber, Notes, MovementDate, CreatedByUserId)
  VALUES (1, 1, 3, @WH1M, @WH2M, N'TRANSFER', 50.000, 8.2000, 410.00, N'TRANSFER', N'TRF-2026-0010', N'Transferencia de insumos a almacen secundario', '2026-02-15 11:00:00', 1);

-- Ajuste de inventario
IF NOT EXISTS (SELECT 1 FROM inv.StockMovement WHERE CompanyId = 1 AND SourceDocumentNumber = N'AJU-2026-0003' AND MovementType = N'ADJUSTMENT')
  INSERT INTO inv.StockMovement (CompanyId, BranchId, ProductId, FromWarehouseId, MovementType, Quantity, UnitCost, TotalCost, SourceDocumentType, SourceDocumentNumber, Notes, MovementDate, CreatedByUserId)
  VALUES (1, 1, 4, @WH1M, N'ADJUSTMENT', -5.000, 35.0000, -175.00, N'ADJUSTMENT', N'AJU-2026-0003', N'Ajuste por diferencia en conteo fisico', '2026-03-01 16:00:00', 1);

-- Devolucion de cliente
IF NOT EXISTS (SELECT 1 FROM inv.StockMovement WHERE CompanyId = 1 AND SourceDocumentNumber = N'DEV-2026-0001' AND MovementType = N'RETURN_IN')
  INSERT INTO inv.StockMovement (CompanyId, BranchId, ProductId, ToWarehouseId, MovementType, Quantity, UnitCost, TotalCost, SourceDocumentType, SourceDocumentNumber, Notes, MovementDate, CreatedByUserId)
  VALUES (1, 1, 2, @WH_DEVM, N'RETURN_IN', 1.000, 22.7500, 22.75, N'RETURN', N'DEV-2026-0001', N'Devolucion de cliente por falla de pantalla - laptop SN-LAP-002', '2026-03-05 09:45:00', 1);
GO

PRINT '=== Seed demo: Inventario Avanzado — COMPLETO ===';
GO
