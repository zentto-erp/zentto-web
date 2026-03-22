/*
 * usp_mfg_integracion.sql
 * Integración Manufactura ↔ Inventario
 * Al completar orden: consume materiales + produce terminado via StockMovement
 */

IF OBJECT_ID('dbo.usp_Mfg_WorkOrder_ProcessStock', 'P') IS NOT NULL
  DROP PROCEDURE dbo.usp_Mfg_WorkOrder_ProcessStock;
GO

CREATE PROCEDURE dbo.usp_Mfg_WorkOrder_ProcessStock
  @CompanyId INT,
  @BranchId INT,
  @WorkOrderId BIGINT,
  @UserId INT
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @materialsConsumed INT = 0;
  DECLARE @outputCreated INT = 0;
  DECLARE @productId BIGINT;
  DECLARE @completedQty DECIMAL(18,3);
  DECLARE @warehouseId BIGINT;

  -- Obtener datos de la orden
  SELECT @productId = ProductId,
         @completedQty = CompletedQuantity,
         @warehouseId = WarehouseId
  FROM mfg.WorkOrder
  WHERE WorkOrderId = @WorkOrderId AND CompanyId = @CompanyId;

  IF @productId IS NULL
  BEGIN
    SELECT 0 AS ok, 0 AS materialsConsumed, 0 AS outputCreated, 'orden_no_encontrada' AS mensaje;
    RETURN;
  END

  -- 1. Consumir materiales (PRODUCTION_OUT por cada material)
  IF OBJECT_ID('inv.StockMovement', 'U') IS NOT NULL
  BEGIN
    INSERT INTO inv.StockMovement (
      CompanyId, BranchId, ProductId, FromWarehouseId,
      MovementType, Quantity, UnitCost, TotalCost,
      SourceDocumentType, SourceDocumentNumber, Notes,
      MovementDate, CreatedByUserId, CreatedAt
    )
    SELECT
      @CompanyId, @BranchId, wom.ProductId, @warehouseId,
      'PRODUCTION_OUT', wom.ConsumedQuantity, wom.UnitCost,
      ROUND(wom.ConsumedQuantity * wom.UnitCost, 2),
      'WORK_ORDER', wo.WorkOrderNumber,
      'Consumo para orden ' + wo.WorkOrderNumber,
      SYSUTCDATETIME(), @UserId, SYSUTCDATETIME()
    FROM mfg.WorkOrderMaterial wom
    INNER JOIN mfg.WorkOrder wo ON wo.WorkOrderId = wom.WorkOrderId
    WHERE wom.WorkOrderId = @WorkOrderId
      AND wom.ConsumedQuantity > 0;

    SET @materialsConsumed = @@ROWCOUNT;

    -- 2. Producir terminado (PRODUCTION_IN)
    IF @completedQty > 0
    BEGIN
      DECLARE @totalMaterialCost DECIMAL(18,2);
      SELECT @totalMaterialCost = ISNULL(SUM(ROUND(ConsumedQuantity * UnitCost, 2)), 0)
      FROM mfg.WorkOrderMaterial WHERE WorkOrderId = @WorkOrderId;

      INSERT INTO inv.StockMovement (
        CompanyId, BranchId, ProductId, ToWarehouseId,
        MovementType, Quantity, UnitCost, TotalCost,
        SourceDocumentType, SourceDocumentNumber, Notes,
        MovementDate, CreatedByUserId, CreatedAt
      ) VALUES (
        @CompanyId, @BranchId, @productId, @warehouseId,
        'PRODUCTION_IN', @completedQty,
        CASE WHEN @completedQty > 0 THEN ROUND(@totalMaterialCost / @completedQty, 4) ELSE 0 END,
        @totalMaterialCost,
        'WORK_ORDER',
        (SELECT WorkOrderNumber FROM mfg.WorkOrder WHERE WorkOrderId = @WorkOrderId),
        'Producción terminada',
        SYSUTCDATETIME(), @UserId, SYSUTCDATETIME()
      );

      SET @outputCreated = 1;
    END
  END

  SELECT 1 AS ok, @materialsConsumed AS materialsConsumed, @outputCreated AS outputCreated, 'ok' AS mensaje;
END
GO
