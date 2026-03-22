/*
 * usp_mfg_integracion.sql (PostgreSQL)
 * Integración Manufactura ↔ Inventario
 */

CREATE OR REPLACE FUNCTION usp_mfg_workorder_processstock(
  p_company_id INT,
  p_branch_id INT,
  p_work_order_id BIGINT,
  p_user_id INT
)
RETURNS TABLE("ok" INT, "materialsConsumed" INT, "outputCreated" INT, "mensaje" VARCHAR)
LANGUAGE plpgsql AS $$
DECLARE
  v_product_id BIGINT;
  v_completed_qty NUMERIC(18,3);
  v_warehouse_id BIGINT;
  v_materials_consumed INT := 0;
  v_output_created INT := 0;
  v_total_material_cost NUMERIC(18,2);
  v_wo_number VARCHAR(40);
BEGIN
  SELECT "ProductId", "CompletedQuantity", "WarehouseId"
  INTO v_product_id, v_completed_qty, v_warehouse_id
  FROM mfg."WorkOrder"
  WHERE "WorkOrderId" = p_work_order_id AND "CompanyId" = p_company_id;

  IF v_product_id IS NULL THEN
    RETURN QUERY SELECT 0, 0, 0, 'orden_no_encontrada'::VARCHAR;
    RETURN;
  END IF;

  SELECT "WorkOrderNumber" INTO v_wo_number
  FROM mfg."WorkOrder" WHERE "WorkOrderId" = p_work_order_id;

  -- 1. Consumir materiales
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'inv' AND table_name = 'StockMovement') THEN
    INSERT INTO inv."StockMovement" (
      "CompanyId", "BranchId", "ProductId", "FromWarehouseId",
      "MovementType", "Quantity", "UnitCost", "TotalCost",
      "SourceDocumentType", "SourceDocumentNumber", "Notes",
      "MovementDate", "CreatedByUserId", "CreatedAt"
    )
    SELECT
      p_company_id, p_branch_id, wom."ProductId", v_warehouse_id,
      'PRODUCTION_OUT', wom."ConsumedQuantity", wom."UnitCost",
      ROUND(wom."ConsumedQuantity" * wom."UnitCost", 2),
      'WORK_ORDER', v_wo_number,
      'Consumo para orden ' || v_wo_number,
      NOW() AT TIME ZONE 'UTC', p_user_id, NOW() AT TIME ZONE 'UTC'
    FROM mfg."WorkOrderMaterial" wom
    WHERE wom."WorkOrderId" = p_work_order_id
      AND wom."ConsumedQuantity" > 0;

    GET DIAGNOSTICS v_materials_consumed = ROW_COUNT;

    -- 2. Producir terminado
    IF v_completed_qty > 0 THEN
      SELECT COALESCE(SUM(ROUND("ConsumedQuantity" * "UnitCost", 2)), 0)
      INTO v_total_material_cost
      FROM mfg."WorkOrderMaterial" WHERE "WorkOrderId" = p_work_order_id;

      INSERT INTO inv."StockMovement" (
        "CompanyId", "BranchId", "ProductId", "ToWarehouseId",
        "MovementType", "Quantity", "UnitCost", "TotalCost",
        "SourceDocumentType", "SourceDocumentNumber", "Notes",
        "MovementDate", "CreatedByUserId", "CreatedAt"
      ) VALUES (
        p_company_id, p_branch_id, v_product_id, v_warehouse_id,
        'PRODUCTION_IN', v_completed_qty,
        CASE WHEN v_completed_qty > 0 THEN ROUND(v_total_material_cost / v_completed_qty, 4) ELSE 0 END,
        v_total_material_cost,
        'WORK_ORDER', v_wo_number,
        'Producción terminada',
        NOW() AT TIME ZONE 'UTC', p_user_id, NOW() AT TIME ZONE 'UTC'
      );

      v_output_created := 1;
    END IF;
  END IF;

  RETURN QUERY SELECT 1, v_materials_consumed, v_output_created, 'ok'::VARCHAR;
END;
$$;
