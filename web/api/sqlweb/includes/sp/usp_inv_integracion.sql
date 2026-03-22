-- ============================================================================
-- Inventario Avanzado — SPs de Integracion con POS, Ventas y Logistica
-- Motor: SQL Server
-- ============================================================================

-- ────────────────────────────────────────────────────────────────────────────
-- usp_Inv_Serial_ReserveForSale
-- Valida y reserva un serial al vender via POS o Factura.
-- ────────────────────────────────────────────────────────────────────────────
IF OBJECT_ID('dbo.usp_Inv_Serial_ReserveForSale', 'P') IS NOT NULL
  DROP PROCEDURE dbo.usp_Inv_Serial_ReserveForSale;
GO

CREATE PROCEDURE dbo.usp_Inv_Serial_ReserveForSale
  @CompanyId            INT,
  @ProductId            INT,
  @SerialNumber         NVARCHAR(100),
  @SalesDocumentNumber  NVARCHAR(50),
  @CustomerId           INT = NULL,
  @UserId               NVARCHAR(50)
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @SerialId INT;

  -- Buscar serial disponible
  SELECT @SerialId = SerialId
  FROM inv.ProductSerial
  WHERE CompanyId  = @CompanyId
    AND ProductId  = @ProductId
    AND SerialNumber = @SerialNumber
    AND Status = 'AVAILABLE';

  IF @SerialId IS NULL
  BEGIN
    SELECT
      CAST(0 AS INT) AS [ok],
      CAST(0 AS INT) AS [SerialId],
      N'serial_not_available' AS [reason];
    RETURN;
  END

  -- Reservar serial
  UPDATE inv.ProductSerial
  SET Status              = 'SOLD',
      SalesDocumentNumber = @SalesDocumentNumber,
      CustomerId          = @CustomerId,
      SoldAt              = SYSUTCDATETIME(),
      UpdatedBy           = @UserId,
      UpdatedAt           = SYSUTCDATETIME()
  WHERE SerialId = @SerialId;

  SELECT
    CAST(1 AS INT) AS [ok],
    @SerialId      AS [SerialId],
    N''            AS [reason];
END
GO

-- ────────────────────────────────────────────────────────────────────────────
-- usp_Inv_Lot_ValidateForSale
-- Valida que el lote no este expirado y tenga cantidad suficiente.
-- ────────────────────────────────────────────────────────────────────────────
IF OBJECT_ID('dbo.usp_Inv_Lot_ValidateForSale', 'P') IS NOT NULL
  DROP PROCEDURE dbo.usp_Inv_Lot_ValidateForSale;
GO

CREATE PROCEDURE dbo.usp_Inv_Lot_ValidateForSale
  @CompanyId  INT,
  @ProductId  INT,
  @LotId      INT = NULL,
  @Quantity   DECIMAL(18,4)
AS
BEGIN
  SET NOCOUNT ON;

  -- Si no se especifica lote, buscar el primero disponible (FEFO)
  IF @LotId IS NULL
  BEGIN
    SELECT TOP 1 @LotId = LotId
    FROM inv.ProductLot
    WHERE CompanyId = @CompanyId
      AND ProductId = @ProductId
      AND Status = 'AVAILABLE'
      AND QuantityOnHand >= @Quantity
    ORDER BY ExpiryDate ASC;
  END

  -- Si no hay lote, producto no requiere tracking de lotes
  IF @LotId IS NULL
  BEGIN
    SELECT
      CAST(1 AS INT) AS [ok],
      N''            AS [warning],
      CAST(0 AS INT) AS [expired],
      N''            AS [ExpiryDate];
    RETURN;
  END

  DECLARE @ExpiryDate DATETIME2;
  DECLARE @QtyOnHand  DECIMAL(18,4);
  DECLARE @Status     NVARCHAR(20);

  SELECT @ExpiryDate = ExpiryDate,
         @QtyOnHand  = QuantityOnHand,
         @Status     = Status
  FROM inv.ProductLot
  WHERE LotId = @LotId AND CompanyId = @CompanyId;

  -- Lote no encontrado
  IF @ExpiryDate IS NULL AND @QtyOnHand IS NULL
  BEGIN
    SELECT
      CAST(0 AS INT)     AS [ok],
      N'lot_not_found'   AS [warning],
      CAST(0 AS INT)     AS [expired],
      N''                AS [ExpiryDate];
    RETURN;
  END

  -- Verificar cantidad
  IF @QtyOnHand < @Quantity
  BEGIN
    SELECT
      CAST(0 AS INT)              AS [ok],
      N'insufficient_lot_quantity' AS [warning],
      CAST(0 AS INT)              AS [expired],
      CONVERT(NVARCHAR(10), @ExpiryDate, 120) AS [ExpiryDate];
    RETURN;
  END

  -- Verificar expiracion
  DECLARE @IsExpired BIT = 0;
  DECLARE @Warning NVARCHAR(200) = N'';

  IF @ExpiryDate IS NOT NULL AND @ExpiryDate < SYSUTCDATETIME()
  BEGIN
    SET @IsExpired = 1;
    SET @Warning = N'lot_expired';
  END
  ELSE IF @ExpiryDate IS NOT NULL AND @ExpiryDate < DATEADD(DAY, 30, SYSUTCDATETIME())
  BEGIN
    SET @Warning = N'lot_expiring_soon';
  END

  SELECT
    CASE WHEN @IsExpired = 1 THEN CAST(0 AS INT) ELSE CAST(1 AS INT) END AS [ok],
    @Warning     AS [warning],
    @IsExpired   AS [expired],
    CONVERT(NVARCHAR(10), @ExpiryDate, 120) AS [ExpiryDate];
END
GO

-- ────────────────────────────────────────────────────────────────────────────
-- usp_Inv_GoodsReceipt_ProcessStock
-- Crea movimientos de stock al aprobar una recepcion de mercancia.
-- ────────────────────────────────────────────────────────────────────────────
IF OBJECT_ID('dbo.usp_Inv_GoodsReceipt_ProcessStock', 'P') IS NOT NULL
  DROP PROCEDURE dbo.usp_Inv_GoodsReceipt_ProcessStock;
GO

CREATE PROCEDURE dbo.usp_Inv_GoodsReceipt_ProcessStock
  @CompanyId       INT,
  @BranchId        INT,
  @GoodsReceiptId  INT,
  @UserId          NVARCHAR(50)
AS
BEGIN
  SET NOCOUNT ON;
  SET XACT_ABORT ON;

  DECLARE @MovementsCreated INT = 0;
  DECLARE @WarehouseId INT;

  -- Obtener almacen de la recepcion
  SELECT @WarehouseId = WarehouseId
  FROM logistics.GoodsReceipt
  WHERE GoodsReceiptId = @GoodsReceiptId
    AND CompanyId = @CompanyId;

  IF @WarehouseId IS NULL
  BEGIN
    SELECT CAST(0 AS INT) AS [ok], 0 AS [MovementsCreated];
    RETURN;
  END

  BEGIN TRY
    BEGIN TRANSACTION;

    -- Cursor para cada linea de recepcion
    DECLARE @ProductId INT, @Quantity DECIMAL(18,4), @BinId INT;

    DECLARE line_cursor CURSOR LOCAL FAST_FORWARD FOR
      SELECT ProductId, ReceivedQuantity, BinId
      FROM logistics.GoodsReceiptLine
      WHERE GoodsReceiptId = @GoodsReceiptId;

    OPEN line_cursor;
    FETCH NEXT FROM line_cursor INTO @ProductId, @Quantity, @BinId;

    WHILE @@FETCH_STATUS = 0
    BEGIN
      -- Insertar movimiento de stock
      INSERT INTO inv.StockMovement (
        CompanyId, BranchId, ProductId, MovementType,
        Quantity, ToWarehouseId, ToBinId,
        ReferenceType, ReferenceId,
        CreatedBy, CreatedAt
      )
      VALUES (
        @CompanyId, @BranchId, @ProductId, 'PURCHASE_IN',
        @Quantity, @WarehouseId, @BinId,
        'GOODS_RECEIPT', @GoodsReceiptId,
        @UserId, SYSUTCDATETIME()
      );

      -- Actualizar stock en bin
      IF EXISTS (
        SELECT 1 FROM inv.ProductBinStock
        WHERE CompanyId = @CompanyId AND ProductId = @ProductId
          AND WarehouseId = @WarehouseId AND ISNULL(BinId, 0) = ISNULL(@BinId, 0)
      )
      BEGIN
        UPDATE inv.ProductBinStock
        SET QuantityOnHand = QuantityOnHand + @Quantity,
            UpdatedAt = SYSUTCDATETIME()
        WHERE CompanyId = @CompanyId AND ProductId = @ProductId
          AND WarehouseId = @WarehouseId AND ISNULL(BinId, 0) = ISNULL(@BinId, 0);
      END
      ELSE
      BEGIN
        INSERT INTO inv.ProductBinStock (
          CompanyId, ProductId, WarehouseId, BinId,
          QuantityOnHand, CreatedAt
        )
        VALUES (
          @CompanyId, @ProductId, @WarehouseId, @BinId,
          @Quantity, SYSUTCDATETIME()
        );
      END

      SET @MovementsCreated = @MovementsCreated + 1;
      FETCH NEXT FROM line_cursor INTO @ProductId, @Quantity, @BinId;
    END

    CLOSE line_cursor;
    DEALLOCATE line_cursor;

    COMMIT TRANSACTION;

    SELECT CAST(1 AS INT) AS [ok], @MovementsCreated AS [MovementsCreated];
  END TRY
  BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK;
    SELECT CAST(0 AS INT) AS [ok], 0 AS [MovementsCreated];
  END CATCH
END
GO

-- ────────────────────────────────────────────────────────────────────────────
-- usp_Inv_DeliveryNote_ProcessStock
-- Crea movimientos de stock al despachar una nota de entrega.
-- ────────────────────────────────────────────────────────────────────────────
IF OBJECT_ID('dbo.usp_Inv_DeliveryNote_ProcessStock', 'P') IS NOT NULL
  DROP PROCEDURE dbo.usp_Inv_DeliveryNote_ProcessStock;
GO

CREATE PROCEDURE dbo.usp_Inv_DeliveryNote_ProcessStock
  @CompanyId       INT,
  @BranchId        INT,
  @DeliveryNoteId  INT,
  @UserId          NVARCHAR(50)
AS
BEGIN
  SET NOCOUNT ON;
  SET XACT_ABORT ON;

  DECLARE @MovementsCreated INT = 0;
  DECLARE @WarehouseId INT;

  -- Obtener almacen de la nota de entrega
  SELECT @WarehouseId = WarehouseId
  FROM logistics.DeliveryNote
  WHERE DeliveryNoteId = @DeliveryNoteId
    AND CompanyId = @CompanyId;

  IF @WarehouseId IS NULL
  BEGIN
    SELECT CAST(0 AS INT) AS [ok], 0 AS [MovementsCreated];
    RETURN;
  END

  BEGIN TRY
    BEGIN TRANSACTION;

    -- Procesar lineas de la nota de entrega
    DECLARE @ProductId INT, @Quantity DECIMAL(18,4), @BinId INT;

    DECLARE line_cursor CURSOR LOCAL FAST_FORWARD FOR
      SELECT ProductId, DispatchedQuantity, BinId
      FROM logistics.DeliveryNoteLine
      WHERE DeliveryNoteId = @DeliveryNoteId;

    OPEN line_cursor;
    FETCH NEXT FROM line_cursor INTO @ProductId, @Quantity, @BinId;

    WHILE @@FETCH_STATUS = 0
    BEGIN
      -- Insertar movimiento de stock (salida)
      INSERT INTO inv.StockMovement (
        CompanyId, BranchId, ProductId, MovementType,
        Quantity, FromWarehouseId, FromBinId,
        ReferenceType, ReferenceId,
        CreatedBy, CreatedAt
      )
      VALUES (
        @CompanyId, @BranchId, @ProductId, 'SALE_OUT',
        @Quantity, @WarehouseId, @BinId,
        'DELIVERY_NOTE', @DeliveryNoteId,
        @UserId, SYSUTCDATETIME()
      );

      -- Disminuir stock en bin
      UPDATE inv.ProductBinStock
      SET QuantityOnHand = QuantityOnHand - @Quantity,
          UpdatedAt = SYSUTCDATETIME()
      WHERE CompanyId = @CompanyId AND ProductId = @ProductId
        AND WarehouseId = @WarehouseId AND ISNULL(BinId, 0) = ISNULL(@BinId, 0);

      SET @MovementsCreated = @MovementsCreated + 1;
      FETCH NEXT FROM line_cursor INTO @ProductId, @Quantity, @BinId;
    END

    CLOSE line_cursor;
    DEALLOCATE line_cursor;

    -- Actualizar seriales asociados a la nota de entrega
    UPDATE inv.ProductSerial
    SET Status    = 'SOLD',
        SoldAt    = SYSUTCDATETIME(),
        UpdatedBy = @UserId,
        UpdatedAt = SYSUTCDATETIME()
    WHERE SerialId IN (
      SELECT SerialId
      FROM logistics.DeliveryNoteSerial
      WHERE DeliveryNoteId = @DeliveryNoteId
    )
    AND Status = 'AVAILABLE';

    COMMIT TRANSACTION;

    SELECT CAST(1 AS INT) AS [ok], @MovementsCreated AS [MovementsCreated];
  END TRY
  BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK;
    SELECT CAST(0 AS INT) AS [ok], 0 AS [MovementsCreated];
  END CATCH
END
GO
