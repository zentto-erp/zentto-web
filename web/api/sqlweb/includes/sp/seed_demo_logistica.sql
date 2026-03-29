/*
 * seed_demo_logistica.sql
 * ───────────────────────
 * Seed de datos demo para modulo de Logistica.
 * Idempotente: verifica existencia antes de cada INSERT.
 *
 * Tablas afectadas:
 *   logistics.Carrier, logistics.Driver,
 *   logistics.GoodsReceipt, logistics.GoodsReceiptLine, logistics.GoodsReceiptSerial,
 *   logistics.GoodsReturn, logistics.GoodsReturnLine,
 *   logistics.DeliveryNote, logistics.DeliveryNoteLine, logistics.DeliveryNoteSerial
 */
USE DatqBoxWeb;
GO
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

SET NOCOUNT ON;
GO

PRINT '=== Seed demo: Logistica ===';
GO

-- ============================================================================
-- SECCION 1: logistics.Carrier  (3 transportistas)
-- ============================================================================
PRINT '>> 1. Transportistas demo...';

IF NOT EXISTS (SELECT 1 FROM logistics.Carrier WHERE CompanyId = 1 AND CarrierCode = N'TRE')
  INSERT INTO logistics.Carrier (CompanyId, CarrierCode, CarrierName, FiscalId, ContactName, Phone, Email, AddressLine, CreatedByUserId)
  VALUES (1, N'TRE', N'Transporte Rápido Express C.A.', N'J-30567890-1', N'Roberto Castillo', N'+58-212-5554001', N'operaciones@tre.com.ve', N'Av. Principal de Boleíta, Galpón 8, Caracas', 1);

IF NOT EXISTS (SELECT 1 FROM logistics.Carrier WHERE CompanyId = 1 AND CarrierCode = N'MRW')
  INSERT INTO logistics.Carrier (CompanyId, CarrierCode, CarrierName, FiscalId, ContactName, Phone, Email, AddressLine, CreatedByUserId)
  VALUES (1, N'MRW', N'MRW Venezuela C.A.', N'J-29012345-6', N'Centro de Operaciones', N'+58-212-2020101', N'empresas@mrw.com.ve', N'Av. Don Diego Cisneros, Los Ruices, Caracas', 1);

IF NOT EXISTS (SELECT 1 FROM logistics.Carrier WHERE CompanyId = 1 AND CarrierCode = N'ZOOM')
  INSERT INTO logistics.Carrier (CompanyId, CarrierCode, CarrierName, FiscalId, ContactName, Phone, Email, AddressLine, CreatedByUserId)
  VALUES (1, N'ZOOM', N'Zoom Envíos C.A.', N'J-31234567-8', N'Departamento Corporativo', N'+58-212-5557070', N'corporativo@zoom.com.ve', N'Calle Vargas, Edif. Zoom, La Candelaria, Caracas', 1);
GO

-- ============================================================================
-- SECCION 2: logistics.Driver  (4 conductores)
-- ============================================================================
PRINT '>> 2. Conductores demo...';

DECLARE @CarrierTRE BIGINT = (SELECT CarrierId FROM logistics.Carrier WHERE CompanyId = 1 AND CarrierCode = N'TRE');
DECLARE @CarrierMRW BIGINT = (SELECT CarrierId FROM logistics.Carrier WHERE CompanyId = 1 AND CarrierCode = N'MRW');
DECLARE @CarrierZOOM BIGINT = (SELECT CarrierId FROM logistics.Carrier WHERE CompanyId = 1 AND CarrierCode = N'ZOOM');

IF NOT EXISTS (SELECT 1 FROM logistics.Driver WHERE CompanyId = 1 AND DriverCode = N'DRV-001')
  INSERT INTO logistics.Driver (CompanyId, CarrierId, DriverCode, DriverName, FiscalId, LicenseNumber, LicenseExpiry, Phone, CreatedByUserId)
  VALUES (1, @CarrierTRE, N'DRV-001', N'Carlos Mendoza', N'V-18234567-0', N'LIC-CCS-045678', '2027-06-15', N'+58-414-5551001', 1);

IF NOT EXISTS (SELECT 1 FROM logistics.Driver WHERE CompanyId = 1 AND DriverCode = N'DRV-002')
  INSERT INTO logistics.Driver (CompanyId, CarrierId, DriverCode, DriverName, FiscalId, LicenseNumber, LicenseExpiry, Phone, CreatedByUserId)
  VALUES (1, @CarrierTRE, N'DRV-002', N'María López', N'V-20345678-1', N'LIC-CCS-056789', '2027-09-20', N'+58-424-5552002', 1);

IF NOT EXISTS (SELECT 1 FROM logistics.Driver WHERE CompanyId = 1 AND DriverCode = N'DRV-003')
  INSERT INTO logistics.Driver (CompanyId, CarrierId, DriverCode, DriverName, FiscalId, LicenseNumber, LicenseExpiry, Phone, CreatedByUserId)
  VALUES (1, @CarrierMRW, N'DRV-003', N'José Pérez', N'V-16456789-2', N'LIC-MIR-067890', '2026-12-01', N'+58-412-5553003', 1);

IF NOT EXISTS (SELECT 1 FROM logistics.Driver WHERE CompanyId = 1 AND DriverCode = N'DRV-004')
  INSERT INTO logistics.Driver (CompanyId, CarrierId, DriverCode, DriverName, FiscalId, LicenseNumber, LicenseExpiry, Phone, CreatedByUserId)
  VALUES (1, @CarrierZOOM, N'DRV-004', N'Ana Rodríguez', N'V-22567890-3', N'LIC-CCS-078901', '2028-03-10', N'+58-416-5554004', 1);
GO

-- ============================================================================
-- SECCION 3: logistics.GoodsReceipt  (2 recepciones con lineas)
-- ============================================================================
PRINT '>> 3. Recepciones de mercancia demo...';

DECLARE @WH1 BIGINT = (SELECT WarehouseId FROM inv.Warehouse WHERE CompanyId = 1 AND WarehouseCode = N'ALM-01');
DECLARE @CarrierTRE2 BIGINT = (SELECT CarrierId FROM logistics.Carrier WHERE CompanyId = 1 AND CarrierCode = N'TRE');

-- Recepcion 1: COMPLETE
IF NOT EXISTS (SELECT 1 FROM logistics.GoodsReceipt WHERE CompanyId = 1 AND ReceiptNumber = N'REC-2026-001')
  INSERT INTO logistics.GoodsReceipt (CompanyId, BranchId, ReceiptNumber, PurchaseDocumentNumber, SupplierId, WarehouseId, ReceiptDate, Status, Notes, CarrierId, DriverName, VehiclePlate, ReceivedByUserId, CreatedByUserId)
  VALUES (1, 1, N'REC-2026-001', N'OC-2026-0100', 1, @WH1, '2026-01-20 09:00:00', N'COMPLETE', N'Recepción completa de electrónicos - lote LOT-2026-001', @CarrierTRE2, N'Carlos Mendoza', N'AB123CD', 1, 1);

-- Recepcion 2: DRAFT
IF NOT EXISTS (SELECT 1 FROM logistics.GoodsReceipt WHERE CompanyId = 1 AND ReceiptNumber = N'REC-2026-002')
  INSERT INTO logistics.GoodsReceipt (CompanyId, BranchId, ReceiptNumber, PurchaseDocumentNumber, SupplierId, WarehouseId, ReceiptDate, Status, Notes, CreatedByUserId)
  VALUES (1, 1, N'REC-2026-002', N'OC-2026-0200', 2, @WH1, '2026-03-18 08:30:00', N'DRAFT', N'Pendiente de recibir - equipos de oficina', 1);
GO

-- Lineas de recepcion 1
DECLARE @GR1 BIGINT = (SELECT GoodsReceiptId FROM logistics.GoodsReceipt WHERE CompanyId = 1 AND ReceiptNumber = N'REC-2026-001');

IF @GR1 IS NOT NULL
BEGIN
  IF NOT EXISTS (SELECT 1 FROM logistics.GoodsReceiptLine WHERE GoodsReceiptId = @GR1 AND LineNumber = 1)
    INSERT INTO logistics.GoodsReceiptLine (GoodsReceiptId, LineNumber, ProductId, ProductCode, Description, OrderedQuantity, ReceivedQuantity, RejectedQuantity, UnitCost, TotalCost, LotNumber, InspectionStatus, CreatedByUserId)
    VALUES (@GR1, 1, 1, N'PROD-001', N'TV Samsung 55" UHD', 100.000, 100.000, 0.000, 15.5000, 1550.00, N'LOT-2026-001', N'APPROVED', 1);

  IF NOT EXISTS (SELECT 1 FROM logistics.GoodsReceiptLine WHERE GoodsReceiptId = @GR1 AND LineNumber = 2)
    INSERT INTO logistics.GoodsReceiptLine (GoodsReceiptId, LineNumber, ProductId, ProductCode, Description, OrderedQuantity, ReceivedQuantity, RejectedQuantity, UnitCost, TotalCost, LotNumber, InspectionStatus, CreatedByUserId)
    VALUES (@GR1, 2, 2, N'PROD-002', N'Laptop HP ProBook 450', 50.000, 50.000, 2.000, 22.7500, 1137.50, N'LOT-2026-002', N'APPROVED', 1);

  IF NOT EXISTS (SELECT 1 FROM logistics.GoodsReceiptLine WHERE GoodsReceiptId = @GR1 AND LineNumber = 3)
    INSERT INTO logistics.GoodsReceiptLine (GoodsReceiptId, LineNumber, ProductId, ProductCode, Description, OrderedQuantity, ReceivedQuantity, RejectedQuantity, UnitCost, TotalCost, LotNumber, InspectionStatus, CreatedByUserId)
    VALUES (@GR1, 3, 3, N'PROD-003', N'Impresora Epson L3250', 30.000, 28.000, 1.000, 8.2000, 229.60, N'LOT-2026-003', N'APPROVED', 1);

  -- Seriales de la recepcion 1 (linea 1 - TVs)
  DECLARE @GRL1 BIGINT = (SELECT GoodsReceiptLineId FROM logistics.GoodsReceiptLine WHERE GoodsReceiptId = @GR1 AND LineNumber = 1);
  IF @GRL1 IS NOT NULL
  BEGIN
    IF NOT EXISTS (SELECT 1 FROM logistics.GoodsReceiptSerial WHERE GoodsReceiptLineId = @GRL1 AND SerialNumber = N'SN-TV-001')
      INSERT INTO logistics.GoodsReceiptSerial (GoodsReceiptLineId, SerialNumber, Status) VALUES (@GRL1, N'SN-TV-001', N'RECEIVED');
    IF NOT EXISTS (SELECT 1 FROM logistics.GoodsReceiptSerial WHERE GoodsReceiptLineId = @GRL1 AND SerialNumber = N'SN-TV-002')
      INSERT INTO logistics.GoodsReceiptSerial (GoodsReceiptLineId, SerialNumber, Status) VALUES (@GRL1, N'SN-TV-002', N'RECEIVED');
  END;
END;
GO

-- Lineas de recepcion 2
DECLARE @GR2 BIGINT = (SELECT GoodsReceiptId FROM logistics.GoodsReceipt WHERE CompanyId = 1 AND ReceiptNumber = N'REC-2026-002');

IF @GR2 IS NOT NULL
BEGIN
  IF NOT EXISTS (SELECT 1 FROM logistics.GoodsReceiptLine WHERE GoodsReceiptId = @GR2 AND LineNumber = 1)
    INSERT INTO logistics.GoodsReceiptLine (GoodsReceiptId, LineNumber, ProductId, ProductCode, Description, OrderedQuantity, ReceivedQuantity, UnitCost, TotalCost, InspectionStatus, CreatedByUserId)
    VALUES (@GR2, 1, 3, N'PROD-003', N'Impresora Epson L3250', 20.000, 0.000, 8.2000, 0.00, N'PENDING', 1);

  IF NOT EXISTS (SELECT 1 FROM logistics.GoodsReceiptLine WHERE GoodsReceiptId = @GR2 AND LineNumber = 2)
    INSERT INTO logistics.GoodsReceiptLine (GoodsReceiptId, LineNumber, ProductId, ProductCode, Description, OrderedQuantity, ReceivedQuantity, UnitCost, TotalCost, InspectionStatus, CreatedByUserId)
    VALUES (@GR2, 2, 4, N'PROD-004', N'Monitor LG 27" 4K', 15.000, 0.000, 35.0000, 0.00, N'PENDING', 1);

  IF NOT EXISTS (SELECT 1 FROM logistics.GoodsReceiptLine WHERE GoodsReceiptId = @GR2 AND LineNumber = 3)
    INSERT INTO logistics.GoodsReceiptLine (GoodsReceiptId, LineNumber, ProductId, ProductCode, Description, OrderedQuantity, ReceivedQuantity, UnitCost, TotalCost, InspectionStatus, CreatedByUserId)
    VALUES (@GR2, 3, 5, N'PROD-005', N'Teclado Logitech MX Keys', 40.000, 0.000, 120.0000, 0.00, N'PENDING', 1);
END;
GO

-- ============================================================================
-- SECCION 4: logistics.GoodsReturn  (1 devolucion)
-- ============================================================================
PRINT '>> 4. Devolucion a proveedor demo...';

DECLARE @WH1R BIGINT = (SELECT WarehouseId FROM inv.Warehouse WHERE CompanyId = 1 AND WarehouseCode = N'ALM-01');
DECLARE @GR1R BIGINT = (SELECT GoodsReceiptId FROM logistics.GoodsReceipt WHERE CompanyId = 1 AND ReceiptNumber = N'REC-2026-001');

IF NOT EXISTS (SELECT 1 FROM logistics.GoodsReturn WHERE CompanyId = 1 AND ReturnNumber = N'DEV-PROV-2026-001')
  INSERT INTO logistics.GoodsReturn (CompanyId, BranchId, ReturnNumber, GoodsReceiptId, SupplierId, WarehouseId, ReturnDate, Reason, Status, Notes, CreatedByUserId)
  VALUES (1, 1, N'DEV-PROV-2026-001', @GR1R, 1, @WH1R, '2026-02-05 10:00:00', N'Producto defectuoso - impresora con cabezal obstruido', N'APPROVED', N'Devolucion aprobada - esperando retiro por transporte', 1);

DECLARE @GRtn1 BIGINT = (SELECT GoodsReturnId FROM logistics.GoodsReturn WHERE CompanyId = 1 AND ReturnNumber = N'DEV-PROV-2026-001');
IF @GRtn1 IS NOT NULL
BEGIN
  IF NOT EXISTS (SELECT 1 FROM logistics.GoodsReturnLine WHERE GoodsReturnId = @GRtn1 AND LineNumber = 1)
    INSERT INTO logistics.GoodsReturnLine (GoodsReturnId, LineNumber, ProductId, ProductCode, Quantity, UnitCost, SerialNumber, Reason, CreatedByUserId)
    VALUES (@GRtn1, 1, 3, N'PROD-003', 1.000, 8.2000, N'SN-IMP-002', N'Cabezal de impresion obstruido de fabrica', 1);
END;
GO

-- ============================================================================
-- SECCION 5: logistics.DeliveryNote  (3 notas de entrega con lineas)
-- ============================================================================
PRINT '>> 5. Notas de entrega demo...';

DECLARE @WH1D BIGINT = (SELECT WarehouseId FROM inv.Warehouse WHERE CompanyId = 1 AND WarehouseCode = N'ALM-01');
DECLARE @CarrierTRE3 BIGINT = (SELECT CarrierId FROM logistics.Carrier WHERE CompanyId = 1 AND CarrierCode = N'TRE');
DECLARE @CarrierMRW3 BIGINT = (SELECT CarrierId FROM logistics.Carrier WHERE CompanyId = 1 AND CarrierCode = N'MRW');
DECLARE @DriverDRV1 BIGINT = (SELECT DriverId FROM logistics.Driver WHERE CompanyId = 1 AND DriverCode = N'DRV-001');
DECLARE @DriverDRV3 BIGINT = (SELECT DriverId FROM logistics.Driver WHERE CompanyId = 1 AND DriverCode = N'DRV-003');

-- Entrega 1: DELIVERED
IF NOT EXISTS (SELECT 1 FROM logistics.DeliveryNote WHERE CompanyId = 1 AND DeliveryNumber = N'ENT-2026-001')
  INSERT INTO logistics.DeliveryNote (CompanyId, BranchId, DeliveryNumber, SalesDocumentNumber, CustomerId, WarehouseId, DeliveryDate, Status, CarrierId, DriverId, VehiclePlate, ShipToAddress, ShipToContact, EstimatedDelivery, ActualDelivery, DeliveredToName, Notes, DispatchedByUserId, CreatedByUserId)
  VALUES (1, 1, N'ENT-2026-001', N'FAC-2026-0050', 1, @WH1D, '2026-03-10 10:00:00', N'DELIVERED', @CarrierTRE3, @DriverDRV1, N'AB123CD', N'Av. Libertador, Torre Delta, Piso 8, Caracas', N'Ing. Juan García', '2026-03-11', '2026-03-11 14:20:00', N'Recibido por: Ing. Juan García (C.I. V-12345678)', N'Entrega completada sin novedades', 1, 1);

-- Entrega 2: DISPATCHED
IF NOT EXISTS (SELECT 1 FROM logistics.DeliveryNote WHERE CompanyId = 1 AND DeliveryNumber = N'ENT-2026-002')
  INSERT INTO logistics.DeliveryNote (CompanyId, BranchId, DeliveryNumber, SalesDocumentNumber, CustomerId, WarehouseId, DeliveryDate, Status, CarrierId, DriverId, VehiclePlate, ShipToAddress, ShipToContact, EstimatedDelivery, Notes, DispatchedByUserId, CreatedByUserId)
  VALUES (1, 1, N'ENT-2026-002', N'FAC-2026-0055', 2, @WH1D, '2026-03-20 08:00:00', N'DISPATCHED', @CarrierMRW3, @DriverDRV3, N'XY789ZW', N'Urb. El Paraíso, Calle 4, Casa 12, Maracaibo', N'María del Carmen Rodríguez', '2026-03-22', N'En camino a Maracaibo - transporte MRW', 1, 1);

-- Entrega 3: DRAFT
IF NOT EXISTS (SELECT 1 FROM logistics.DeliveryNote WHERE CompanyId = 1 AND DeliveryNumber = N'ENT-2026-003')
  INSERT INTO logistics.DeliveryNote (CompanyId, BranchId, DeliveryNumber, SalesDocumentNumber, CustomerId, WarehouseId, DeliveryDate, Status, ShipToAddress, ShipToContact, Notes, CreatedByUserId)
  VALUES (1, 1, N'ENT-2026-003', N'FAC-2026-0060', 3, @WH1D, '2026-03-22 00:00:00', N'DRAFT', N'Zona Industrial Los Montones, Galpón 3, Barcelona', N'Grupo Alimenticio Oriente', N'Pendiente de picking y asignacion de transporte', 1);
GO

-- Lineas de entrega 1 (DELIVERED)
DECLARE @DN1 BIGINT = (SELECT DeliveryNoteId FROM logistics.DeliveryNote WHERE CompanyId = 1 AND DeliveryNumber = N'ENT-2026-001');
IF @DN1 IS NOT NULL
BEGIN
  IF NOT EXISTS (SELECT 1 FROM logistics.DeliveryNoteLine WHERE DeliveryNoteId = @DN1 AND LineNumber = 1)
    INSERT INTO logistics.DeliveryNoteLine (DeliveryNoteId, LineNumber, ProductId, ProductCode, Description, Quantity, PickedQuantity, PackedQuantity, CreatedByUserId)
    VALUES (@DN1, 1, 1, N'PROD-001', N'TV Samsung 55" UHD', 5.000, 5.000, 5.000, 1);

  IF NOT EXISTS (SELECT 1 FROM logistics.DeliveryNoteLine WHERE DeliveryNoteId = @DN1 AND LineNumber = 2)
    INSERT INTO logistics.DeliveryNoteLine (DeliveryNoteId, LineNumber, ProductId, ProductCode, Description, Quantity, PickedQuantity, PackedQuantity, CreatedByUserId)
    VALUES (@DN1, 2, 4, N'PROD-004', N'Monitor LG 27" 4K', 3.000, 3.000, 3.000, 1);

  -- Seriales despachados en entrega 1 (linea 1 - TV)
  DECLARE @DNL1 BIGINT = (SELECT DeliveryNoteLineId FROM logistics.DeliveryNoteLine WHERE DeliveryNoteId = @DN1 AND LineNumber = 1);
  DECLARE @SerialTV2 BIGINT = (SELECT SerialId FROM inv.ProductSerial WHERE CompanyId = 1 AND SerialNumber = N'SN-TV-002');

  IF @DNL1 IS NOT NULL AND @SerialTV2 IS NOT NULL
  BEGIN
    IF NOT EXISTS (SELECT 1 FROM logistics.DeliveryNoteSerial WHERE DeliveryNoteLineId = @DNL1 AND SerialId = @SerialTV2)
      INSERT INTO logistics.DeliveryNoteSerial (DeliveryNoteLineId, SerialId, SerialNumber, Status)
      VALUES (@DNL1, @SerialTV2, N'SN-TV-002', N'DELIVERED');
  END;
END;
GO

-- Lineas de entrega 2 (DISPATCHED)
DECLARE @DN2 BIGINT = (SELECT DeliveryNoteId FROM logistics.DeliveryNote WHERE CompanyId = 1 AND DeliveryNumber = N'ENT-2026-002');
IF @DN2 IS NOT NULL
BEGIN
  IF NOT EXISTS (SELECT 1 FROM logistics.DeliveryNoteLine WHERE DeliveryNoteId = @DN2 AND LineNumber = 1)
    INSERT INTO logistics.DeliveryNoteLine (DeliveryNoteId, LineNumber, ProductId, ProductCode, Description, Quantity, PickedQuantity, PackedQuantity, CreatedByUserId)
    VALUES (@DN2, 1, 2, N'PROD-002', N'Laptop HP ProBook 450', 2.000, 2.000, 2.000, 1);

  IF NOT EXISTS (SELECT 1 FROM logistics.DeliveryNoteLine WHERE DeliveryNoteId = @DN2 AND LineNumber = 2)
    INSERT INTO logistics.DeliveryNoteLine (DeliveryNoteId, LineNumber, ProductId, ProductCode, Description, Quantity, PickedQuantity, PackedQuantity, CreatedByUserId)
    VALUES (@DN2, 2, 5, N'PROD-005', N'Teclado Logitech MX Keys', 4.000, 4.000, 4.000, 1);
END;
GO

-- Lineas de entrega 3 (DRAFT)
DECLARE @DN3 BIGINT = (SELECT DeliveryNoteId FROM logistics.DeliveryNote WHERE CompanyId = 1 AND DeliveryNumber = N'ENT-2026-003');
IF @DN3 IS NOT NULL
BEGIN
  IF NOT EXISTS (SELECT 1 FROM logistics.DeliveryNoteLine WHERE DeliveryNoteId = @DN3 AND LineNumber = 1)
    INSERT INTO logistics.DeliveryNoteLine (DeliveryNoteId, LineNumber, ProductId, ProductCode, Description, Quantity, PickedQuantity, PackedQuantity, CreatedByUserId)
    VALUES (@DN3, 1, 1, N'PROD-001', N'TV Samsung 55" UHD', 10.000, 0.000, 0.000, 1);

  IF NOT EXISTS (SELECT 1 FROM logistics.DeliveryNoteLine WHERE DeliveryNoteId = @DN3 AND LineNumber = 2)
    INSERT INTO logistics.DeliveryNoteLine (DeliveryNoteId, LineNumber, ProductId, ProductCode, Description, Quantity, PickedQuantity, PackedQuantity, CreatedByUserId)
    VALUES (@DN3, 2, 3, N'PROD-003', N'Impresora Epson L3250', 5.000, 0.000, 0.000, 1);

  IF NOT EXISTS (SELECT 1 FROM logistics.DeliveryNoteLine WHERE DeliveryNoteId = @DN3 AND LineNumber = 3)
    INSERT INTO logistics.DeliveryNoteLine (DeliveryNoteId, LineNumber, ProductId, ProductCode, Description, Quantity, PickedQuantity, PackedQuantity, CreatedByUserId)
    VALUES (@DN3, 3, 5, N'PROD-005', N'Teclado Logitech MX Keys', 8.000, 0.000, 0.000, 1);
END;
GO

PRINT '=== Seed demo: Logistica — COMPLETO ===';
GO
