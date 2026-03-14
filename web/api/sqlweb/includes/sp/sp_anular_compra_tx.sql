-- DEPRECATED: Este SP usa tablas legacy. Ver la versión canónica en el API TypeScript.
-- Referencias a dbo.Inventario actualizadas a master.Product (StockQty, ProductCode, SalesPrice).
-- Referencias a dbo.Proveedores actualizadas a master.Supplier (TotalBalance, SupplierCode).
-- Tablas legacy sin migrar (Compras, Detalle_Compras, P_Pagar, etc.)
-- mantienen sus nombres originales — ver TODOs en el codigo.
-- =============================================
-- Stored Procedure: Anular Compra
-- Descripción: Anula una compra revertiendo inventario y CxP
-- Compatible con: SQL Server 2012+
-- =============================================

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_anular_compra_tx')
    DROP PROCEDURE sp_anular_compra_tx
GO

CREATE PROCEDURE sp_anular_compra_tx
    @NumFact NVARCHAR(60),
    @CodUsuario NVARCHAR(60) = 'API',
    @Motivo NVARCHAR(500) = ''
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @FechaAnulacion DATETIME;
    DECLARE @CodProveedor NVARCHAR(60);
    DECLARE @FechaCompra DATETIME;
    DECLARE @YaAnulada BIT;

    BEGIN TRY
        SET @FechaAnulacion = GETDATE();

        -- ============================================
        -- 1. Validar que la compra existe
        -- TODO: tabla Compras es legacy
        -- ============================================
        SELECT
            @CodProveedor = COD_PROVEEDOR,
            @FechaCompra = FECHA,
            @YaAnulada = CASE WHEN ANULADA = 1 OR ANULADA = '1' THEN 1 ELSE 0 END
        FROM Compras
        WHERE NUM_FACT = @NumFact;

        IF @CodProveedor IS NULL
        BEGIN
            RAISERROR('compra_not_found', 16, 1);
            RETURN;
        END

        IF @YaAnulada = 1
        BEGIN
            RAISERROR('compra_already_anulled', 16, 1);
            RETURN;
        END

        BEGIN TRANSACTION;

        -- ============================================
        -- 2. Marcar compra como anulada
        -- TODO: tabla Compras es legacy
        -- ============================================
        UPDATE Compras
        SET ANULADA = 1,
            CONCEPTO = ISNULL(CONCEPTO, '') + ' [ANULADA: ' + CONVERT(NVARCHAR(20), @FechaAnulacion, 120) + ']'
        WHERE NUM_FACT = @NumFact;

        -- ============================================
        -- 3. Anular detalle
        -- TODO: tabla Detalle_Compras es legacy
        -- ============================================
        UPDATE Detalle_Compras
        SET ANULADA = 1
        WHERE NUM_FACT = @NumFact;

        -- ============================================
        -- 4. Revertir master.Product (antes dbo.Inventario) — restar lo que se había sumado
        -- ============================================
        DECLARE @Detalles TABLE (
            CODIGO NVARCHAR(60),
            CANTIDAD FLOAT
        );

        -- TODO: tabla Detalle_Compras es legacy
        INSERT INTO @Detalles (CODIGO, CANTIDAD)
        SELECT
            CODIGO,
            ISNULL(CANTIDAD, 0)
        FROM Detalle_Compras
        WHERE NUM_FACT = @NumFact
          AND ISNULL(ANULADA, 0) = 0;

        -- Insertar movimiento de anulación en MovInvent
        INSERT INTO MovInvent (
            DOCUMENTO, CODIGO, PRODUCT, FECHA, MOTIVO, TIPO,
            CANTIDAD_ACTUAL, CANTIDAD, CANTIDAD_NUEVA, CO_USUARIO,
            PRECIO_COMPRA, ALICUOTA, PRECIO_VENTA, ANULADA
        )
        SELECT
            @NumFact + '_ANUL',
            D.CODIGO,
            D.CODIGO,
            @FechaAnulacion,
            'Anulacion Compra:' + @NumFact + ' - ' + @Motivo,
            'Anulacion Ingreso',
            ISNULL(I.StockQty, 0),          -- columna canonica master.Product
            D.CANTIDAD,
            ISNULL(I.StockQty, 0) - D.CANTIDAD,
            @CodUsuario,
            ISNULL(I.COSTO_REFERENCIA, 0),
            0,
            ISNULL(I.SalesPrice, 0),        -- columna canonica master.Product
            0
        FROM @Detalles D
        -- Ahora se usa master.Product (antes dbo.Inventario)
        INNER JOIN master.Product I ON I.ProductCode = D.CODIGO
        WHERE D.CODIGO IS NOT NULL AND D.CANTIDAD > 0;

        -- Restar del inventario en master.Product.StockQty (revertir el ingreso)
        -- Antes: UPDATE Inventario SET EXISTENCIA = ... FROM Inventario ... ON I.CODIGO = T.CODIGO
        ;WITH Totales AS (
            SELECT CODIGO, SUM(CANTIDAD) AS TOTAL
            FROM @Detalles
            WHERE CODIGO IS NOT NULL
            GROUP BY CODIGO
        )
        UPDATE I
        SET StockQty = ISNULL(I.StockQty, 0) - T.TOTAL
        FROM master.Product I
        INNER JOIN Totales T ON T.CODIGO = I.ProductCode;

        -- ============================================
        -- 5. Anular CxP (marcar como anulada en P_Pagar)
        -- TODO: tabla P_Pagar es legacy
        -- ============================================
        UPDATE P_Pagar
        SET PAID = 1,
            PEND = 0,
            SALDO = 0
        WHERE DOCUMENTO = @NumFact
          AND TIPO = 'FACT'
          AND CODIGO = @CodProveedor;

        -- ============================================
        -- 6. Recalcular saldos del proveedor en master.Supplier (tabla canonica)
        -- Antes actualizaba dbo.Proveedores.SALDO_TOT; ahora actualiza master.Supplier.TotalBalance
        -- ============================================
        DECLARE @SaldoTotal FLOAT;

        -- TODO: tabla P_Pagar es legacy
        SELECT @SaldoTotal = ISNULL(SUM(ISNULL(PEND, 0)), 0)
        FROM P_Pagar
        WHERE CODIGO = @CodProveedor
        AND PAID = 0;

        UPDATE master.Supplier
        SET TotalBalance = @SaldoTotal
        WHERE SupplierCode = @CodProveedor
          AND ISNULL(IsDeleted, 0) = 0;

        COMMIT TRANSACTION;

        -- Retornar resultado
        SELECT
            CAST(1 AS BIT) AS ok,
            @NumFact AS numFact,
            @CodProveedor AS codProveedor,
            'Compra anulada exitosamente' AS mensaje;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @Err NVARCHAR(4000);
        SET @Err = ERROR_MESSAGE();
        RAISERROR(@Err, 16, 1);
    END CATCH
END
GO

-- Verificar creación
SELECT name, create_date FROM sys.objects WHERE type = 'P' AND name = 'sp_anular_compra_tx';
