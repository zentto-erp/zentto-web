/*
 * seed_demo_manufactura.sql (PostgreSQL)
 * ──────────────────────────────────────
 * Seed de datos demo para el modulo de manufactura (mfg).
 * Idempotente: ON CONFLICT DO NOTHING / WHERE NOT EXISTS.
 *
 * Tablas afectadas:
 *   mfg."WorkCenter", mfg."BillOfMaterials", mfg."BOMLine",
 *   mfg."Routing", mfg."WorkOrder", mfg."WorkOrderMaterial", mfg."WorkOrderOutput"
 */

DO $$
DECLARE
  v_bom_mesa     BIGINT;
  v_bom_silla    BIGINT;
  v_wc_ens       BIGINT;
  v_wc_pin       BIGINT;
  v_wc_qc        BIGINT;
  v_wo_1         BIGINT;
  v_prod_ids     BIGINT[];
  v_prod_1       BIGINT;
  v_prod_2       BIGINT;
  v_prod_3       BIGINT;
  v_wh_id        BIGINT;
BEGIN
  RAISE NOTICE '=== Seed demo: Manufactura (mfg) ===';

  -- Obtener IDs de referencia
  SELECT "WarehouseId" INTO v_wh_id FROM inv."Warehouse" WHERE "CompanyId" = 1 AND "WarehouseCode" = 'ALM-01' LIMIT 1;

  -- Usar los primeros 3 productos disponibles como componentes
  SELECT ARRAY(SELECT "ProductId" FROM master."Product" WHERE "CompanyId" = 1 AND "IsDeleted" = FALSE ORDER BY "ProductId" LIMIT 3)
  INTO v_prod_ids;

  v_prod_1 := v_prod_ids[1];
  v_prod_2 := COALESCE(v_prod_ids[2], v_prod_ids[1]);
  v_prod_3 := COALESCE(v_prod_ids[3], v_prod_ids[1]);

  IF v_wh_id IS NULL OR v_prod_1 IS NULL THEN
    RAISE NOTICE 'Faltan almacen o productos — abortando seed manufactura';
    RETURN;
  END IF;

  -- ============================================================================
  -- SECCION 1: mfg."WorkCenter"  (3 centros de trabajo)
  -- ============================================================================
  RAISE NOTICE '>> 1. Centros de trabajo...';

  INSERT INTO mfg."WorkCenter" ("CompanyId", "WorkCenterCode", "WorkCenterName", "CostPerHour", "Capacity", "IsActive", "CreatedByUserId")
  VALUES (1, 'WC-ENS', 'Linea de Ensamblaje', 15.00, 8, TRUE, 1)
  ON CONFLICT ("CompanyId", "WorkCenterCode") DO NOTHING;

  INSERT INTO mfg."WorkCenter" ("CompanyId", "WorkCenterCode", "WorkCenterName", "CostPerHour", "Capacity", "IsActive", "CreatedByUserId")
  VALUES (1, 'WC-PIN', 'Taller de Pintura', 12.00, 4, TRUE, 1)
  ON CONFLICT ("CompanyId", "WorkCenterCode") DO NOTHING;

  INSERT INTO mfg."WorkCenter" ("CompanyId", "WorkCenterCode", "WorkCenterName", "CostPerHour", "Capacity", "IsActive", "CreatedByUserId")
  VALUES (1, 'WC-QC', 'Control de Calidad', 10.00, 2, TRUE, 1)
  ON CONFLICT ("CompanyId", "WorkCenterCode") DO NOTHING;

  SELECT "WorkCenterId" INTO v_wc_ens FROM mfg."WorkCenter" WHERE "CompanyId" = 1 AND "WorkCenterCode" = 'WC-ENS' LIMIT 1;
  SELECT "WorkCenterId" INTO v_wc_pin FROM mfg."WorkCenter" WHERE "CompanyId" = 1 AND "WorkCenterCode" = 'WC-PIN' LIMIT 1;
  SELECT "WorkCenterId" INTO v_wc_qc  FROM mfg."WorkCenter" WHERE "CompanyId" = 1 AND "WorkCenterCode" = 'WC-QC'  LIMIT 1;

  -- ============================================================================
  -- SECCION 2: mfg."BillOfMaterials"  (2 BOMs)
  -- ============================================================================
  RAISE NOTICE '>> 2. Listas de materiales (BOM)...';

  INSERT INTO mfg."BillOfMaterials" ("CompanyId", "BOMCode", "BOMName", "ProductId", "OutputQuantity", "UnitOfMeasure", "Version", "Status", "Notes", "IsActive", "CreatedByUserId")
  VALUES (1, 'BOM-PROD-01', 'BOM Producto Principal', v_prod_1, 1.000, 'UND', 1, 'ACTIVE', 'Lista de materiales para produccion demo', TRUE, 1)
  ON CONFLICT ("CompanyId", "BOMCode") DO NOTHING;

  INSERT INTO mfg."BillOfMaterials" ("CompanyId", "BOMCode", "BOMName", "ProductId", "OutputQuantity", "UnitOfMeasure", "Version", "Status", "Notes", "IsActive", "CreatedByUserId")
  VALUES (1, 'BOM-PROD-02', 'BOM Producto Secundario', v_prod_2, 1.000, 'UND', 1, 'ACTIVE', 'Lista de materiales para produccion demo 2', TRUE, 1)
  ON CONFLICT ("CompanyId", "BOMCode") DO NOTHING;

  SELECT "BOMId" INTO v_bom_mesa  FROM mfg."BillOfMaterials" WHERE "CompanyId" = 1 AND "BOMCode" = 'BOM-PROD-01' LIMIT 1;
  SELECT "BOMId" INTO v_bom_silla FROM mfg."BillOfMaterials" WHERE "CompanyId" = 1 AND "BOMCode" = 'BOM-PROD-02' LIMIT 1;

  -- ============================================================================
  -- SECCION 3: mfg."BOMLine"  (lineas con FK a products reales)
  -- ============================================================================
  RAISE NOTICE '>> 3. Lineas de BOM...';

  IF v_bom_mesa IS NOT NULL THEN
    INSERT INTO mfg."BOMLine" ("BOMId", "LineNumber", "ComponentProductId", "Quantity", "UnitOfMeasure", "WastePercent", "Notes")
    SELECT v_bom_mesa, 10, v_prod_2, 2.000, 'UND', 0, 'Componente principal'
    WHERE NOT EXISTS (SELECT 1 FROM mfg."BOMLine" WHERE "BOMId" = v_bom_mesa AND "LineNumber" = 10);

    INSERT INTO mfg."BOMLine" ("BOMId", "LineNumber", "ComponentProductId", "Quantity", "UnitOfMeasure", "WastePercent", "Notes")
    SELECT v_bom_mesa, 20, v_prod_3, 4.000, 'UND', 5, 'Componente secundario'
    WHERE NOT EXISTS (SELECT 1 FROM mfg."BOMLine" WHERE "BOMId" = v_bom_mesa AND "LineNumber" = 20);
  END IF;

  IF v_bom_silla IS NOT NULL THEN
    INSERT INTO mfg."BOMLine" ("BOMId", "LineNumber", "ComponentProductId", "Quantity", "UnitOfMeasure", "WastePercent", "Notes")
    SELECT v_bom_silla, 10, v_prod_1, 1.000, 'UND', 0, 'Componente base'
    WHERE NOT EXISTS (SELECT 1 FROM mfg."BOMLine" WHERE "BOMId" = v_bom_silla AND "LineNumber" = 10);

    INSERT INTO mfg."BOMLine" ("BOMId", "LineNumber", "ComponentProductId", "Quantity", "UnitOfMeasure", "WastePercent", "Notes")
    SELECT v_bom_silla, 20, v_prod_3, 2.000, 'UND', 3, 'Componente accesorio'
    WHERE NOT EXISTS (SELECT 1 FROM mfg."BOMLine" WHERE "BOMId" = v_bom_silla AND "LineNumber" = 20);
  END IF;

  -- ============================================================================
  -- SECCION 4: mfg."Routing"  (operaciones de produccion por BOM)
  -- ============================================================================
  RAISE NOTICE '>> 4. Operaciones de produccion...';

  IF v_bom_mesa IS NOT NULL AND v_wc_ens IS NOT NULL THEN
    INSERT INTO mfg."Routing" ("BOMId", "OperationNumber", "OperationName", "WorkCenterId", "SetupTimeMinutes", "RunTimeMinutes", "Notes")
    VALUES (v_bom_mesa, 10, 'Preparacion', v_wc_ens, 30, 45, 'Preparacion de materiales')
    ON CONFLICT ("BOMId", "OperationNumber") DO NOTHING;

    INSERT INTO mfg."Routing" ("BOMId", "OperationNumber", "OperationName", "WorkCenterId", "SetupTimeMinutes", "RunTimeMinutes", "Notes")
    VALUES (v_bom_mesa, 20, 'Proceso', v_wc_pin, 15, 60, 'Procesamiento principal')
    ON CONFLICT ("BOMId", "OperationNumber") DO NOTHING;

    INSERT INTO mfg."Routing" ("BOMId", "OperationNumber", "OperationName", "WorkCenterId", "SetupTimeMinutes", "RunTimeMinutes", "Notes")
    VALUES (v_bom_mesa, 30, 'Inspeccion', v_wc_qc, 0, 15, 'Control de calidad')
    ON CONFLICT ("BOMId", "OperationNumber") DO NOTHING;
  END IF;

  IF v_bom_silla IS NOT NULL AND v_wc_ens IS NOT NULL THEN
    INSERT INTO mfg."Routing" ("BOMId", "OperationNumber", "OperationName", "WorkCenterId", "SetupTimeMinutes", "RunTimeMinutes", "Notes")
    VALUES (v_bom_silla, 10, 'Ensamble', v_wc_ens, 20, 40, 'Ensamblaje de componentes')
    ON CONFLICT ("BOMId", "OperationNumber") DO NOTHING;

    INSERT INTO mfg."Routing" ("BOMId", "OperationNumber", "OperationName", "WorkCenterId", "SetupTimeMinutes", "RunTimeMinutes", "Notes")
    VALUES (v_bom_silla, 20, 'Inspeccion', v_wc_qc, 0, 20, 'Control de calidad final')
    ON CONFLICT ("BOMId", "OperationNumber") DO NOTHING;
  END IF;

  -- ============================================================================
  -- SECCION 5: mfg."WorkOrder"  (2 ordenes de trabajo)
  -- ============================================================================
  RAISE NOTICE '>> 5. Ordenes de trabajo...';

  INSERT INTO mfg."WorkOrder" ("CompanyId", "BranchId", "WorkOrderNumber", "BOMId", "ProductId", "PlannedQuantity", "Status",
    "WarehouseId", "PlannedStartDate", "PlannedEndDate", "ActualStartDate", "ActualEndDate", "Notes", "CreatedByUserId")
  SELECT 1, 1, 'WO-2026-001', v_bom_mesa, v_prod_1, 10.000, 'COMPLETED',
    v_wh_id,
    (NOW() AT TIME ZONE 'UTC') - INTERVAL '14 days', (NOW() AT TIME ZONE 'UTC') - INTERVAL '7 days',
    (NOW() AT TIME ZONE 'UTC') - INTERVAL '14 days', (NOW() AT TIME ZONE 'UTC') - INTERVAL '8 days',
    'Orden completada - lote produccion marzo 2026', 1
  WHERE v_bom_mesa IS NOT NULL
    AND NOT EXISTS (SELECT 1 FROM mfg."WorkOrder" WHERE "CompanyId" = 1 AND "WorkOrderNumber" = 'WO-2026-001');

  INSERT INTO mfg."WorkOrder" ("CompanyId", "BranchId", "WorkOrderNumber", "BOMId", "ProductId", "PlannedQuantity", "Status",
    "WarehouseId", "PlannedStartDate", "PlannedEndDate", "ActualStartDate", "Notes", "CreatedByUserId")
  SELECT 1, 1, 'WO-2026-002', v_bom_silla, v_prod_2, 5.000, 'IN_PROGRESS',
    v_wh_id,
    NOW() AT TIME ZONE 'UTC', (NOW() AT TIME ZONE 'UTC') + INTERVAL '7 days',
    NOW() AT TIME ZONE 'UTC',
    'En produccion - pedido cliente', 1
  WHERE v_bom_silla IS NOT NULL
    AND NOT EXISTS (SELECT 1 FROM mfg."WorkOrder" WHERE "CompanyId" = 1 AND "WorkOrderNumber" = 'WO-2026-002');

  -- ============================================================================
  -- SECCION 6: mfg."WorkOrderMaterial"  (materiales consumidos WO-001)
  -- ============================================================================
  RAISE NOTICE '>> 6. Materiales consumidos...';

  SELECT "WorkOrderId" INTO v_wo_1 FROM mfg."WorkOrder" WHERE "CompanyId" = 1 AND "WorkOrderNumber" = 'WO-2026-001' LIMIT 1;

  IF v_wo_1 IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mfg."WorkOrderMaterial" WHERE "WorkOrderId" = v_wo_1) THEN
    INSERT INTO mfg."WorkOrderMaterial" ("WorkOrderId", "LineNumber", "ProductId", "PlannedQuantity", "ConsumedQuantity", "UnitOfMeasure", "Notes")
    VALUES (v_wo_1, 1, v_prod_2, 20.000, 20.000, 'UND', 'Componente principal - sin desperdicio');

    INSERT INTO mfg."WorkOrderMaterial" ("WorkOrderId", "LineNumber", "ProductId", "PlannedQuantity", "ConsumedQuantity", "UnitOfMeasure", "Notes")
    VALUES (v_wo_1, 2, v_prod_3, 40.000, 41.000, 'UND', 'Componente secundario - 1 unidad extra');
  END IF;

  -- ============================================================================
  -- SECCION 7: mfg."WorkOrderOutput"  (produccion terminada WO-001)
  -- ============================================================================
  RAISE NOTICE '>> 7. Produccion terminada...';

  IF v_wo_1 IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mfg."WorkOrderOutput" WHERE "WorkOrderId" = v_wo_1) THEN
    INSERT INTO mfg."WorkOrderOutput" ("WorkOrderId", "ProductId", "Quantity", "UnitOfMeasure", "WarehouseId", "IsScrap", "Notes", "CreatedByUserId", "ProducedAt")
    VALUES (v_wo_1, v_prod_1, 10.000, 'UND', v_wh_id, FALSE, 'Lote completo sin defectos', 1, (NOW() AT TIME ZONE 'UTC') - INTERVAL '8 days');
  END IF;

  RAISE NOTICE '=== Seed manufactura completado ===';
END $$;
