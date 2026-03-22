/*
 * seed_demo_manufactura.sql (PostgreSQL)
 * ──────────────────────────────────────
 * Seed de datos demo para el modulo de manufactura (mfg).
 * Idempotente: ON CONFLICT DO NOTHING / WHERE NOT EXISTS.
 *
 * Tablas afectadas:
 *   mfg."WorkCenter", mfg."BillOfMaterials", mfg."BOMLine",
 *   mfg."Routing", mfg."RoutingOperation",
 *   mfg."WorkOrder", mfg."WorkOrderMaterial", mfg."WorkOrderOutput"
 */

DO $$
DECLARE
  v_bom_mesa   INT;
  v_bom_silla  INT;
  v_wc_ens     INT;
  v_wc_pin     INT;
  v_wc_qc      INT;
  v_routing_mesa  INT;
  v_routing_silla INT;
  v_wo_1       INT;
BEGIN
  RAISE NOTICE '=== Seed demo: Manufactura (mfg) ===';

  -- ============================================================================
  -- SECCION 1: mfg."WorkCenter"  (3 centros de trabajo)
  -- ============================================================================
  RAISE NOTICE '>> 1. Centros de trabajo...';

  INSERT INTO mfg."WorkCenter" ("CompanyId", "BranchId", "WorkCenterCode", "WorkCenterName", "CostPerHour", "Capacity", "IsActive", "CreatedByUserId", "CreatedAt")
  VALUES (1, 1, 'WC-ENS', 'Linea de Ensamblaje', 15.00, 8, TRUE, 1, NOW() AT TIME ZONE 'UTC')
  ON CONFLICT ("CompanyId", "WorkCenterCode") DO NOTHING;

  INSERT INTO mfg."WorkCenter" ("CompanyId", "BranchId", "WorkCenterCode", "WorkCenterName", "CostPerHour", "Capacity", "IsActive", "CreatedByUserId", "CreatedAt")
  VALUES (1, 1, 'WC-PIN', 'Taller de Pintura', 12.00, 4, TRUE, 1, NOW() AT TIME ZONE 'UTC')
  ON CONFLICT ("CompanyId", "WorkCenterCode") DO NOTHING;

  INSERT INTO mfg."WorkCenter" ("CompanyId", "BranchId", "WorkCenterCode", "WorkCenterName", "CostPerHour", "Capacity", "IsActive", "CreatedByUserId", "CreatedAt")
  VALUES (1, 1, 'WC-QC', 'Control de Calidad', 10.00, 2, TRUE, 1, NOW() AT TIME ZONE 'UTC')
  ON CONFLICT ("CompanyId", "WorkCenterCode") DO NOTHING;

  -- ============================================================================
  -- SECCION 2: mfg."BillOfMaterials"  (2 listas de materiales)
  -- ============================================================================
  RAISE NOTICE '>> 2. Listas de materiales (BOM)...';

  INSERT INTO mfg."BillOfMaterials" ("CompanyId", "BranchId", "BOMCode", "BOMName", "Version", "Status", "ExpectedQty", "Notes", "IsActive", "CreatedByUserId", "CreatedAt")
  VALUES (1, 1, 'BOM-MESA-01', 'Mesa de Oficina Premium', 1, 'ACTIVE', 1.00, 'BOM para mesa de oficina con tablero de madera y patas metalicas', TRUE, 1, NOW() AT TIME ZONE 'UTC')
  ON CONFLICT ("CompanyId", "BOMCode") DO NOTHING;

  INSERT INTO mfg."BillOfMaterials" ("CompanyId", "BranchId", "BOMCode", "BOMName", "Version", "Status", "ExpectedQty", "Notes", "IsActive", "CreatedByUserId", "CreatedAt")
  VALUES (1, 1, 'BOM-SILLA-01', 'Silla Ergonomica', 1, 'ACTIVE', 1.00, 'BOM para silla ergonomica con base giratoria y brazos ajustables', TRUE, 1, NOW() AT TIME ZONE 'UTC')
  ON CONFLICT ("CompanyId", "BOMCode") DO NOTHING;

  -- ============================================================================
  -- SECCION 3: mfg."BOMLine"  (lineas de BOM)
  -- ============================================================================
  RAISE NOTICE '>> 3. Lineas de BOM...';

  SELECT "BillOfMaterialsId" INTO v_bom_mesa FROM mfg."BillOfMaterials" WHERE "CompanyId" = 1 AND "BOMCode" = 'BOM-MESA-01' LIMIT 1;
  SELECT "BillOfMaterialsId" INTO v_bom_silla FROM mfg."BillOfMaterials" WHERE "CompanyId" = 1 AND "BOMCode" = 'BOM-SILLA-01' LIMIT 1;

  -- BOM-MESA-01: 4 lineas
  IF v_bom_mesa IS NOT NULL THEN
    INSERT INTO mfg."BOMLine" ("BillOfMaterialsId", "LineNumber", "ComponentName", "ComponentCode", "Quantity", "UnitOfMeasure", "Notes")
    SELECT v_bom_mesa, 10, 'Tablero madera', 'MAT-TAB-01', 2.00, 'UND', 'Tablero de madera MDF 120x60cm'
    WHERE NOT EXISTS (SELECT 1 FROM mfg."BOMLine" WHERE "BillOfMaterialsId" = v_bom_mesa AND "LineNumber" = 10);

    INSERT INTO mfg."BOMLine" ("BillOfMaterialsId", "LineNumber", "ComponentName", "ComponentCode", "Quantity", "UnitOfMeasure", "Notes")
    SELECT v_bom_mesa, 20, 'Patas metalicas', 'MAT-PAT-01', 4.00, 'UND', 'Pata metalica tubular 72cm'
    WHERE NOT EXISTS (SELECT 1 FROM mfg."BOMLine" WHERE "BillOfMaterialsId" = v_bom_mesa AND "LineNumber" = 20);

    INSERT INTO mfg."BOMLine" ("BillOfMaterialsId", "LineNumber", "ComponentName", "ComponentCode", "Quantity", "UnitOfMeasure", "Notes")
    SELECT v_bom_mesa, 30, 'Tornillos', 'MAT-TOR-01', 16.00, 'UND', 'Tornillo autorroscante 3/4 pulgada'
    WHERE NOT EXISTS (SELECT 1 FROM mfg."BOMLine" WHERE "BillOfMaterialsId" = v_bom_mesa AND "LineNumber" = 30);

    INSERT INTO mfg."BOMLine" ("BillOfMaterialsId", "LineNumber", "ComponentName", "ComponentCode", "Quantity", "UnitOfMeasure", "Notes")
    SELECT v_bom_mesa, 40, 'Pintura', 'MAT-PIN-01', 0.50, 'LTS', 'Pintura acrilica color nogal'
    WHERE NOT EXISTS (SELECT 1 FROM mfg."BOMLine" WHERE "BillOfMaterialsId" = v_bom_mesa AND "LineNumber" = 40);
  END IF;

  -- BOM-SILLA-01: 5 lineas
  IF v_bom_silla IS NOT NULL THEN
    INSERT INTO mfg."BOMLine" ("BillOfMaterialsId", "LineNumber", "ComponentName", "ComponentCode", "Quantity", "UnitOfMeasure", "Notes")
    SELECT v_bom_silla, 10, 'Asiento tapizado', 'MAT-ASI-01', 1.00, 'UND', 'Asiento con espuma de alta densidad y tela mesh'
    WHERE NOT EXISTS (SELECT 1 FROM mfg."BOMLine" WHERE "BillOfMaterialsId" = v_bom_silla AND "LineNumber" = 10);

    INSERT INTO mfg."BOMLine" ("BillOfMaterialsId", "LineNumber", "ComponentName", "ComponentCode", "Quantity", "UnitOfMeasure", "Notes")
    SELECT v_bom_silla, 20, 'Respaldo', 'MAT-RES-01', 1.00, 'UND', 'Respaldo ergonomico con soporte lumbar'
    WHERE NOT EXISTS (SELECT 1 FROM mfg."BOMLine" WHERE "BillOfMaterialsId" = v_bom_silla AND "LineNumber" = 20);

    INSERT INTO mfg."BOMLine" ("BillOfMaterialsId", "LineNumber", "ComponentName", "ComponentCode", "Quantity", "UnitOfMeasure", "Notes")
    SELECT v_bom_silla, 30, 'Base giratoria', 'MAT-BAS-01', 1.00, 'UND', 'Base de 5 puntas con mecanismo giratorio'
    WHERE NOT EXISTS (SELECT 1 FROM mfg."BOMLine" WHERE "BillOfMaterialsId" = v_bom_silla AND "LineNumber" = 30);

    INSERT INTO mfg."BOMLine" ("BillOfMaterialsId", "LineNumber", "ComponentName", "ComponentCode", "Quantity", "UnitOfMeasure", "Notes")
    SELECT v_bom_silla, 40, 'Ruedas', 'MAT-RUE-01', 5.00, 'UND', 'Rueda de nylon 50mm con freno'
    WHERE NOT EXISTS (SELECT 1 FROM mfg."BOMLine" WHERE "BillOfMaterialsId" = v_bom_silla AND "LineNumber" = 40);

    INSERT INTO mfg."BOMLine" ("BillOfMaterialsId", "LineNumber", "ComponentName", "ComponentCode", "Quantity", "UnitOfMeasure", "Notes")
    SELECT v_bom_silla, 50, 'Brazos', 'MAT-BRA-01', 2.00, 'UND', 'Brazo ajustable con almohadilla'
    WHERE NOT EXISTS (SELECT 1 FROM mfg."BOMLine" WHERE "BillOfMaterialsId" = v_bom_silla AND "LineNumber" = 50);
  END IF;

  -- ============================================================================
  -- SECCION 4: mfg."Routing" + mfg."RoutingOperation"
  -- ============================================================================
  RAISE NOTICE '>> 4. Rutas de produccion...';

  SELECT "WorkCenterId" INTO v_wc_ens FROM mfg."WorkCenter" WHERE "CompanyId" = 1 AND "WorkCenterCode" = 'WC-ENS' LIMIT 1;
  SELECT "WorkCenterId" INTO v_wc_pin FROM mfg."WorkCenter" WHERE "CompanyId" = 1 AND "WorkCenterCode" = 'WC-PIN' LIMIT 1;
  SELECT "WorkCenterId" INTO v_wc_qc  FROM mfg."WorkCenter" WHERE "CompanyId" = 1 AND "WorkCenterCode" = 'WC-QC'  LIMIT 1;

  -- Ruta Mesa
  IF v_bom_mesa IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mfg."Routing" WHERE "CompanyId" = 1 AND "RoutingCode" = 'RUT-MESA-01') THEN
    INSERT INTO mfg."Routing" ("CompanyId", "BranchId", "RoutingCode", "RoutingName", "BillOfMaterialsId", "IsActive", "CreatedByUserId", "CreatedAt")
    VALUES (1, 1, 'RUT-MESA-01', 'Ruta produccion Mesa de Oficina', v_bom_mesa, TRUE, 1, NOW() AT TIME ZONE 'UTC');

    SELECT "RoutingId" INTO v_routing_mesa FROM mfg."Routing" WHERE "CompanyId" = 1 AND "RoutingCode" = 'RUT-MESA-01' LIMIT 1;

    INSERT INTO mfg."RoutingOperation" ("RoutingId", "OperationNumber", "OperationName", "WorkCenterId", "SetupTimeMinutes", "RunTimeMinutes", "Notes")
    VALUES (v_routing_mesa, 10, 'Corte', v_wc_ens, 30, 45, 'Corte de tableros y patas a medida');

    INSERT INTO mfg."RoutingOperation" ("RoutingId", "OperationNumber", "OperationName", "WorkCenterId", "SetupTimeMinutes", "RunTimeMinutes", "Notes")
    VALUES (v_routing_mesa, 20, 'Pintura', v_wc_pin, 15, 60, 'Aplicacion de pintura y secado');

    INSERT INTO mfg."RoutingOperation" ("RoutingId", "OperationNumber", "OperationName", "WorkCenterId", "SetupTimeMinutes", "RunTimeMinutes", "Notes")
    VALUES (v_routing_mesa, 30, 'Ensamble', v_wc_ens, 10, 30, 'Ensamblaje de componentes');

    INSERT INTO mfg."RoutingOperation" ("RoutingId", "OperationNumber", "OperationName", "WorkCenterId", "SetupTimeMinutes", "RunTimeMinutes", "Notes")
    VALUES (v_routing_mesa, 40, 'Inspeccion', v_wc_qc, 0, 15, 'Inspeccion de calidad final');
  END IF;

  -- Ruta Silla
  IF v_bom_silla IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mfg."Routing" WHERE "CompanyId" = 1 AND "RoutingCode" = 'RUT-SILLA-01') THEN
    INSERT INTO mfg."Routing" ("CompanyId", "BranchId", "RoutingCode", "RoutingName", "BillOfMaterialsId", "IsActive", "CreatedByUserId", "CreatedAt")
    VALUES (1, 1, 'RUT-SILLA-01', 'Ruta produccion Silla Ergonomica', v_bom_silla, TRUE, 1, NOW() AT TIME ZONE 'UTC');

    SELECT "RoutingId" INTO v_routing_silla FROM mfg."Routing" WHERE "CompanyId" = 1 AND "RoutingCode" = 'RUT-SILLA-01' LIMIT 1;

    INSERT INTO mfg."RoutingOperation" ("RoutingId", "OperationNumber", "OperationName", "WorkCenterId", "SetupTimeMinutes", "RunTimeMinutes", "Notes")
    VALUES (v_routing_silla, 10, 'Preparacion', v_wc_ens, 20, 40, 'Preparacion de componentes');

    INSERT INTO mfg."RoutingOperation" ("RoutingId", "OperationNumber", "OperationName", "WorkCenterId", "SetupTimeMinutes", "RunTimeMinutes", "Notes")
    VALUES (v_routing_silla, 20, 'Ensamble', v_wc_ens, 15, 50, 'Ensamblaje de base, asiento y respaldo');

    INSERT INTO mfg."RoutingOperation" ("RoutingId", "OperationNumber", "OperationName", "WorkCenterId", "SetupTimeMinutes", "RunTimeMinutes", "Notes")
    VALUES (v_routing_silla, 30, 'Inspeccion', v_wc_qc, 0, 20, 'Control de calidad y ajuste final');
  END IF;

  -- ============================================================================
  -- SECCION 5: mfg."WorkOrder"  (2 ordenes de trabajo)
  -- ============================================================================
  RAISE NOTICE '>> 5. Ordenes de trabajo...';

  SELECT "RoutingId" INTO v_routing_mesa FROM mfg."Routing" WHERE "CompanyId" = 1 AND "RoutingCode" = 'RUT-MESA-01' LIMIT 1;
  SELECT "RoutingId" INTO v_routing_silla FROM mfg."Routing" WHERE "CompanyId" = 1 AND "RoutingCode" = 'RUT-SILLA-01' LIMIT 1;

  -- WO-2026-001: Mesa, COMPLETED
  INSERT INTO mfg."WorkOrder" ("CompanyId", "BranchId", "WorkOrderCode", "WorkOrderName", "BillOfMaterialsId", "RoutingId", "Quantity", "Status",
    "PlannedStartDate", "PlannedEndDate", "ActualStartDate", "ActualEndDate", "Notes", "CreatedByUserId", "CreatedAt")
  SELECT 1, 1, 'WO-2026-001', 'Mesa de Oficina Premium x10', v_bom_mesa, v_routing_mesa, 10, 'COMPLETED',
    (NOW() AT TIME ZONE 'UTC') - INTERVAL '14 days', (NOW() AT TIME ZONE 'UTC') - INTERVAL '7 days',
    (NOW() AT TIME ZONE 'UTC') - INTERVAL '14 days', (NOW() AT TIME ZONE 'UTC') - INTERVAL '8 days',
    'Orden completada - lote produccion marzo 2026', 1, NOW() AT TIME ZONE 'UTC'
  WHERE NOT EXISTS (SELECT 1 FROM mfg."WorkOrder" WHERE "CompanyId" = 1 AND "WorkOrderCode" = 'WO-2026-001');

  -- WO-2026-002: Silla, IN_PROGRESS
  INSERT INTO mfg."WorkOrder" ("CompanyId", "BranchId", "WorkOrderCode", "WorkOrderName", "BillOfMaterialsId", "RoutingId", "Quantity", "Status",
    "PlannedStartDate", "PlannedEndDate", "ActualStartDate", "ActualEndDate", "Notes", "CreatedByUserId", "CreatedAt")
  SELECT 1, 1, 'WO-2026-002', 'Silla Ergonomica x5', v_bom_silla, v_routing_silla, 5, 'IN_PROGRESS',
    CURRENT_DATE, (NOW() AT TIME ZONE 'UTC') + INTERVAL '7 days',
    CURRENT_DATE, NULL,
    'En produccion - pedido cliente CLT004', 1, NOW() AT TIME ZONE 'UTC'
  WHERE NOT EXISTS (SELECT 1 FROM mfg."WorkOrder" WHERE "CompanyId" = 1 AND "WorkOrderCode" = 'WO-2026-002');

  -- ============================================================================
  -- SECCION 6: mfg."WorkOrderMaterial"  (materiales consumidos WO-001)
  -- ============================================================================
  RAISE NOTICE '>> 6. Materiales consumidos en ordenes...';

  SELECT "WorkOrderId" INTO v_wo_1 FROM mfg."WorkOrder" WHERE "CompanyId" = 1 AND "WorkOrderCode" = 'WO-2026-001' LIMIT 1;

  IF v_wo_1 IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mfg."WorkOrderMaterial" WHERE "WorkOrderId" = v_wo_1) THEN
    INSERT INTO mfg."WorkOrderMaterial" ("WorkOrderId", "ComponentCode", "ComponentName", "PlannedQty", "ConsumedQty", "UnitOfMeasure", "Notes")
    VALUES (v_wo_1, 'MAT-TAB-01', 'Tablero madera', 20.00, 20.00, 'UND', 'Sin desperdicio');

    INSERT INTO mfg."WorkOrderMaterial" ("WorkOrderId", "ComponentCode", "ComponentName", "PlannedQty", "ConsumedQty", "UnitOfMeasure", "Notes")
    VALUES (v_wo_1, 'MAT-PAT-01', 'Patas metalicas', 40.00, 41.00, 'UND', '1 pata defectuosa reemplazada');

    INSERT INTO mfg."WorkOrderMaterial" ("WorkOrderId", "ComponentCode", "ComponentName", "PlannedQty", "ConsumedQty", "UnitOfMeasure", "Notes")
    VALUES (v_wo_1, 'MAT-TOR-01', 'Tornillos', 160.00, 165.00, 'UND', '5 tornillos adicionales por reposicion');

    INSERT INTO mfg."WorkOrderMaterial" ("WorkOrderId", "ComponentCode", "ComponentName", "PlannedQty", "ConsumedQty", "UnitOfMeasure", "Notes")
    VALUES (v_wo_1, 'MAT-PIN-01', 'Pintura', 5.00, 5.20, 'LTS', 'Ligero exceso en acabado');
  END IF;

  -- ============================================================================
  -- SECCION 7: mfg."WorkOrderOutput"  (produccion terminada WO-001)
  -- ============================================================================
  RAISE NOTICE '>> 7. Produccion terminada...';

  IF v_wo_1 IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mfg."WorkOrderOutput" WHERE "WorkOrderId" = v_wo_1) THEN
    INSERT INTO mfg."WorkOrderOutput" ("WorkOrderId", "OutputQty", "GoodQty", "DefectQty", "OutputDate", "Notes", "CreatedByUserId", "CreatedAt")
    VALUES (v_wo_1, 10.00, 10.00, 0.00, (NOW() AT TIME ZONE 'UTC') - INTERVAL '8 days', 'Lote completo sin defectos', 1, NOW() AT TIME ZONE 'UTC');
  END IF;

  RAISE NOTICE '=== Seed manufactura completado ===';
END $$;
