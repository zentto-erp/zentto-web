/*
 * seed_demo_manufactura.sql
 * ─────────────────────────
 * Seed de datos demo para el modulo de manufactura (mfg).
 * Idempotente: verifica existencia antes de cada INSERT.
 *
 * Tablas afectadas:
 *   mfg.WorkCenter, mfg.BillOfMaterials, mfg.BOMLine,
 *   mfg.Routing, mfg.RoutingOperation,
 *   mfg.WorkOrder, mfg.WorkOrderMaterial, mfg.WorkOrderOutput
 */
USE DatqBoxWeb;
GO
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

SET NOCOUNT ON;
GO

PRINT '=== Seed demo: Manufactura (mfg) ===';
GO

-- ============================================================================
-- SECCION 1: mfg.WorkCenter  (3 centros de trabajo)
-- ============================================================================
PRINT '>> 1. Centros de trabajo...';

IF NOT EXISTS (SELECT 1 FROM mfg.WorkCenter WHERE CompanyId = 1 AND WorkCenterCode = N'WC-ENS')
  INSERT INTO mfg.WorkCenter (CompanyId, BranchId, WorkCenterCode, WorkCenterName, CostPerHour, Capacity, IsActive, CreatedByUserId, CreatedAt)
  VALUES (1, 1, N'WC-ENS', N'Linea de Ensamblaje', 15.00, 8, 1, 1, SYSUTCDATETIME());

IF NOT EXISTS (SELECT 1 FROM mfg.WorkCenter WHERE CompanyId = 1 AND WorkCenterCode = N'WC-PIN')
  INSERT INTO mfg.WorkCenter (CompanyId, BranchId, WorkCenterCode, WorkCenterName, CostPerHour, Capacity, IsActive, CreatedByUserId, CreatedAt)
  VALUES (1, 1, N'WC-PIN', N'Taller de Pintura', 12.00, 4, 1, 1, SYSUTCDATETIME());

IF NOT EXISTS (SELECT 1 FROM mfg.WorkCenter WHERE CompanyId = 1 AND WorkCenterCode = N'WC-QC')
  INSERT INTO mfg.WorkCenter (CompanyId, BranchId, WorkCenterCode, WorkCenterName, CostPerHour, Capacity, IsActive, CreatedByUserId, CreatedAt)
  VALUES (1, 1, N'WC-QC', N'Control de Calidad', 10.00, 2, 1, 1, SYSUTCDATETIME());
GO

-- ============================================================================
-- SECCION 2: mfg.BillOfMaterials  (2 listas de materiales)
-- ============================================================================
PRINT '>> 2. Listas de materiales (BOM)...';

IF NOT EXISTS (SELECT 1 FROM mfg.BillOfMaterials WHERE CompanyId = 1 AND BOMCode = N'BOM-MESA-01')
  INSERT INTO mfg.BillOfMaterials (CompanyId, BranchId, BOMCode, BOMName, Version, Status, ExpectedQty, Notes, IsActive, CreatedByUserId, CreatedAt)
  VALUES (1, 1, N'BOM-MESA-01', N'Mesa de Oficina Premium', 1, N'ACTIVE', 1.00, N'BOM para mesa de oficina con tablero de madera y patas metalicas', 1, 1, SYSUTCDATETIME());

IF NOT EXISTS (SELECT 1 FROM mfg.BillOfMaterials WHERE CompanyId = 1 AND BOMCode = N'BOM-SILLA-01')
  INSERT INTO mfg.BillOfMaterials (CompanyId, BranchId, BOMCode, BOMName, Version, Status, ExpectedQty, Notes, IsActive, CreatedByUserId, CreatedAt)
  VALUES (1, 1, N'BOM-SILLA-01', N'Silla Ergonomica', 1, N'ACTIVE', 1.00, N'BOM para silla ergonomica con base giratoria y brazos ajustables', 1, 1, SYSUTCDATETIME());
GO

-- ============================================================================
-- SECCION 3: mfg.BOMLine  (lineas de BOM)
-- ============================================================================
PRINT '>> 3. Lineas de BOM...';

-- BOM-MESA-01: 4 lineas
DECLARE @BOMIdMesa INT = (SELECT TOP 1 BillOfMaterialsId FROM mfg.BillOfMaterials WHERE CompanyId = 1 AND BOMCode = N'BOM-MESA-01');

IF @BOMIdMesa IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mfg.BOMLine WHERE BillOfMaterialsId = @BOMIdMesa AND LineNumber = 10)
BEGIN
  INSERT INTO mfg.BOMLine (BillOfMaterialsId, LineNumber, ComponentName, ComponentCode, Quantity, UnitOfMeasure, Notes)
  VALUES (@BOMIdMesa, 10, N'Tablero madera', N'MAT-TAB-01', 2.00, N'UND', N'Tablero de madera MDF 120x60cm');

  INSERT INTO mfg.BOMLine (BillOfMaterialsId, LineNumber, ComponentName, ComponentCode, Quantity, UnitOfMeasure, Notes)
  VALUES (@BOMIdMesa, 20, N'Patas metalicas', N'MAT-PAT-01', 4.00, N'UND', N'Pata metalica tubular 72cm');

  INSERT INTO mfg.BOMLine (BillOfMaterialsId, LineNumber, ComponentName, ComponentCode, Quantity, UnitOfMeasure, Notes)
  VALUES (@BOMIdMesa, 30, N'Tornillos', N'MAT-TOR-01', 16.00, N'UND', N'Tornillo autorroscante 3/4 pulgada');

  INSERT INTO mfg.BOMLine (BillOfMaterialsId, LineNumber, ComponentName, ComponentCode, Quantity, UnitOfMeasure, Notes)
  VALUES (@BOMIdMesa, 40, N'Pintura', N'MAT-PIN-01', 0.50, N'LTS', N'Pintura acrilica color nogal');
END;

-- BOM-SILLA-01: 5 lineas
DECLARE @BOMIdSilla INT = (SELECT TOP 1 BillOfMaterialsId FROM mfg.BillOfMaterials WHERE CompanyId = 1 AND BOMCode = N'BOM-SILLA-01');

IF @BOMIdSilla IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mfg.BOMLine WHERE BillOfMaterialsId = @BOMIdSilla AND LineNumber = 10)
BEGIN
  INSERT INTO mfg.BOMLine (BillOfMaterialsId, LineNumber, ComponentName, ComponentCode, Quantity, UnitOfMeasure, Notes)
  VALUES (@BOMIdSilla, 10, N'Asiento tapizado', N'MAT-ASI-01', 1.00, N'UND', N'Asiento con espuma de alta densidad y tela mesh');

  INSERT INTO mfg.BOMLine (BillOfMaterialsId, LineNumber, ComponentName, ComponentCode, Quantity, UnitOfMeasure, Notes)
  VALUES (@BOMIdSilla, 20, N'Respaldo', N'MAT-RES-01', 1.00, N'UND', N'Respaldo ergonomico con soporte lumbar');

  INSERT INTO mfg.BOMLine (BillOfMaterialsId, LineNumber, ComponentName, ComponentCode, Quantity, UnitOfMeasure, Notes)
  VALUES (@BOMIdSilla, 30, N'Base giratoria', N'MAT-BAS-01', 1.00, N'UND', N'Base de 5 puntas con mecanismo giratorio');

  INSERT INTO mfg.BOMLine (BillOfMaterialsId, LineNumber, ComponentName, ComponentCode, Quantity, UnitOfMeasure, Notes)
  VALUES (@BOMIdSilla, 40, N'Ruedas', N'MAT-RUE-01', 5.00, N'UND', N'Rueda de nylon 50mm con freno');

  INSERT INTO mfg.BOMLine (BillOfMaterialsId, LineNumber, ComponentName, ComponentCode, Quantity, UnitOfMeasure, Notes)
  VALUES (@BOMIdSilla, 50, N'Brazos', N'MAT-BRA-01', 2.00, N'UND', N'Brazo ajustable con almohadilla');
END;
GO

-- ============================================================================
-- SECCION 4: mfg.Routing + mfg.RoutingOperation  (ruta para BOM-MESA-01)
-- ============================================================================
PRINT '>> 4. Rutas de produccion...';

DECLARE @BOMIdMesa2 INT = (SELECT TOP 1 BillOfMaterialsId FROM mfg.BillOfMaterials WHERE CompanyId = 1 AND BOMCode = N'BOM-MESA-01');
DECLARE @WCEns INT = (SELECT TOP 1 WorkCenterId FROM mfg.WorkCenter WHERE CompanyId = 1 AND WorkCenterCode = N'WC-ENS');
DECLARE @WCPin INT = (SELECT TOP 1 WorkCenterId FROM mfg.WorkCenter WHERE CompanyId = 1 AND WorkCenterCode = N'WC-PIN');
DECLARE @WCQC INT = (SELECT TOP 1 WorkCenterId FROM mfg.WorkCenter WHERE CompanyId = 1 AND WorkCenterCode = N'WC-QC');

IF @BOMIdMesa2 IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mfg.Routing WHERE CompanyId = 1 AND RoutingCode = N'RUT-MESA-01')
BEGIN
  INSERT INTO mfg.Routing (CompanyId, BranchId, RoutingCode, RoutingName, BillOfMaterialsId, IsActive, CreatedByUserId, CreatedAt)
  VALUES (1, 1, N'RUT-MESA-01', N'Ruta produccion Mesa de Oficina', @BOMIdMesa2, 1, 1, SYSUTCDATETIME());

  DECLARE @RoutingId INT = SCOPE_IDENTITY();

  INSERT INTO mfg.RoutingOperation (RoutingId, OperationNumber, OperationName, WorkCenterId, SetupTimeMinutes, RunTimeMinutes, Notes)
  VALUES (@RoutingId, 10, N'Corte', @WCEns, 30, 45, N'Corte de tableros y patas a medida');

  INSERT INTO mfg.RoutingOperation (RoutingId, OperationNumber, OperationName, WorkCenterId, SetupTimeMinutes, RunTimeMinutes, Notes)
  VALUES (@RoutingId, 20, N'Pintura', @WCPin, 15, 60, N'Aplicacion de pintura y secado');

  INSERT INTO mfg.RoutingOperation (RoutingId, OperationNumber, OperationName, WorkCenterId, SetupTimeMinutes, RunTimeMinutes, Notes)
  VALUES (@RoutingId, 30, N'Ensamble', @WCEns, 10, 30, N'Ensamblaje de componentes');

  INSERT INTO mfg.RoutingOperation (RoutingId, OperationNumber, OperationName, WorkCenterId, SetupTimeMinutes, RunTimeMinutes, Notes)
  VALUES (@RoutingId, 40, N'Inspeccion', @WCQC, 0, 15, N'Inspeccion de calidad final');
END;

-- Ruta para silla
DECLARE @BOMIdSilla2 INT = (SELECT TOP 1 BillOfMaterialsId FROM mfg.BillOfMaterials WHERE CompanyId = 1 AND BOMCode = N'BOM-SILLA-01');

IF @BOMIdSilla2 IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mfg.Routing WHERE CompanyId = 1 AND RoutingCode = N'RUT-SILLA-01')
BEGIN
  INSERT INTO mfg.Routing (CompanyId, BranchId, RoutingCode, RoutingName, BillOfMaterialsId, IsActive, CreatedByUserId, CreatedAt)
  VALUES (1, 1, N'RUT-SILLA-01', N'Ruta produccion Silla Ergonomica', @BOMIdSilla2, 1, 1, SYSUTCDATETIME());

  DECLARE @RoutingIdSilla INT = SCOPE_IDENTITY();

  INSERT INTO mfg.RoutingOperation (RoutingId, OperationNumber, OperationName, WorkCenterId, SetupTimeMinutes, RunTimeMinutes, Notes)
  VALUES (@RoutingIdSilla, 10, N'Preparacion', @WCEns, 20, 40, N'Preparacion de componentes');

  INSERT INTO mfg.RoutingOperation (RoutingId, OperationNumber, OperationName, WorkCenterId, SetupTimeMinutes, RunTimeMinutes, Notes)
  VALUES (@RoutingIdSilla, 20, N'Ensamble', @WCEns, 15, 50, N'Ensamblaje de base, asiento y respaldo');

  INSERT INTO mfg.RoutingOperation (RoutingId, OperationNumber, OperationName, WorkCenterId, SetupTimeMinutes, RunTimeMinutes, Notes)
  VALUES (@RoutingIdSilla, 30, N'Inspeccion', @WCQC, 0, 20, N'Control de calidad y ajuste final');
END;
GO

-- ============================================================================
-- SECCION 5: mfg.WorkOrder  (2 ordenes de trabajo)
-- ============================================================================
PRINT '>> 5. Ordenes de trabajo...';

DECLARE @BOMIdMesa3 INT = (SELECT TOP 1 BillOfMaterialsId FROM mfg.BillOfMaterials WHERE CompanyId = 1 AND BOMCode = N'BOM-MESA-01');
DECLARE @BOMIdSilla3 INT = (SELECT TOP 1 BillOfMaterialsId FROM mfg.BillOfMaterials WHERE CompanyId = 1 AND BOMCode = N'BOM-SILLA-01');
DECLARE @RoutingMesa INT = (SELECT TOP 1 RoutingId FROM mfg.Routing WHERE CompanyId = 1 AND RoutingCode = N'RUT-MESA-01');
DECLARE @RoutingSilla INT = (SELECT TOP 1 RoutingId FROM mfg.Routing WHERE CompanyId = 1 AND RoutingCode = N'RUT-SILLA-01');

-- WO-2026-001: Mesa, COMPLETED
IF NOT EXISTS (SELECT 1 FROM mfg.WorkOrder WHERE CompanyId = 1 AND WorkOrderCode = N'WO-2026-001')
  INSERT INTO mfg.WorkOrder (CompanyId, BranchId, WorkOrderCode, WorkOrderName, BillOfMaterialsId, RoutingId, Quantity, Status,
    PlannedStartDate, PlannedEndDate, ActualStartDate, ActualEndDate, Notes, CreatedByUserId, CreatedAt)
  VALUES (1, 1, N'WO-2026-001', N'Mesa de Oficina Premium x10', @BOMIdMesa3, @RoutingMesa, 10, N'COMPLETED',
    DATEADD(DAY, -14, SYSUTCDATETIME()), DATEADD(DAY, -7, SYSUTCDATETIME()),
    DATEADD(DAY, -14, SYSUTCDATETIME()), DATEADD(DAY, -8, SYSUTCDATETIME()),
    N'Orden completada - lote produccion marzo 2026', 1, SYSUTCDATETIME());

-- WO-2026-002: Silla, IN_PROGRESS
IF NOT EXISTS (SELECT 1 FROM mfg.WorkOrder WHERE CompanyId = 1 AND WorkOrderCode = N'WO-2026-002')
  INSERT INTO mfg.WorkOrder (CompanyId, BranchId, WorkOrderCode, WorkOrderName, BillOfMaterialsId, RoutingId, Quantity, Status,
    PlannedStartDate, PlannedEndDate, ActualStartDate, ActualEndDate, Notes, CreatedByUserId, CreatedAt)
  VALUES (1, 1, N'WO-2026-002', N'Silla Ergonomica x5', @BOMIdSilla3, @RoutingSilla, 5, N'IN_PROGRESS',
    CAST(SYSUTCDATETIME() AS DATE), DATEADD(DAY, 7, SYSUTCDATETIME()),
    CAST(SYSUTCDATETIME() AS DATE), NULL,
    N'En produccion - pedido cliente CLT004', 1, SYSUTCDATETIME());
GO

-- ============================================================================
-- SECCION 6: mfg.WorkOrderMaterial  (materiales consumidos WO-001)
-- ============================================================================
PRINT '>> 6. Materiales consumidos en ordenes...';

DECLARE @WOId1 INT = (SELECT TOP 1 WorkOrderId FROM mfg.WorkOrder WHERE CompanyId = 1 AND WorkOrderCode = N'WO-2026-001');

IF @WOId1 IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mfg.WorkOrderMaterial WHERE WorkOrderId = @WOId1)
BEGIN
  INSERT INTO mfg.WorkOrderMaterial (WorkOrderId, ComponentCode, ComponentName, PlannedQty, ConsumedQty, UnitOfMeasure, Notes)
  VALUES (@WOId1, N'MAT-TAB-01', N'Tablero madera', 20.00, 20.00, N'UND', N'Sin desperdicio');

  INSERT INTO mfg.WorkOrderMaterial (WorkOrderId, ComponentCode, ComponentName, PlannedQty, ConsumedQty, UnitOfMeasure, Notes)
  VALUES (@WOId1, N'MAT-PAT-01', N'Patas metalicas', 40.00, 41.00, N'UND', N'1 pata defectuosa reemplazada');

  INSERT INTO mfg.WorkOrderMaterial (WorkOrderId, ComponentCode, ComponentName, PlannedQty, ConsumedQty, UnitOfMeasure, Notes)
  VALUES (@WOId1, N'MAT-TOR-01', N'Tornillos', 160.00, 165.00, N'UND', N'5 tornillos adicionales por reposicion');

  INSERT INTO mfg.WorkOrderMaterial (WorkOrderId, ComponentCode, ComponentName, PlannedQty, ConsumedQty, UnitOfMeasure, Notes)
  VALUES (@WOId1, N'MAT-PIN-01', N'Pintura', 5.00, 5.20, N'LTS', N'Ligero exceso en acabado');
END;
GO

-- ============================================================================
-- SECCION 7: mfg.WorkOrderOutput  (produccion terminada WO-001)
-- ============================================================================
PRINT '>> 7. Produccion terminada...';

DECLARE @WOId2 INT = (SELECT TOP 1 WorkOrderId FROM mfg.WorkOrder WHERE CompanyId = 1 AND WorkOrderCode = N'WO-2026-001');

IF @WOId2 IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mfg.WorkOrderOutput WHERE WorkOrderId = @WOId2)
  INSERT INTO mfg.WorkOrderOutput (WorkOrderId, OutputQty, GoodQty, DefectQty, OutputDate, Notes, CreatedByUserId, CreatedAt)
  VALUES (@WOId2, 10.00, 10.00, 0.00, DATEADD(DAY, -8, SYSUTCDATETIME()), N'Lote completo sin defectos', 1, SYSUTCDATETIME());
GO

PRINT '=== Seed manufactura completado ===';
GO
