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
        -- ============================================
        UPDATE Compras
        SET ANULADA = 1,
            CONCEPTO = ISNULL(CONCEPTO, '') + ' [ANULADA: ' + CONVERT(NVARCHAR(20), @FechaAnulacion, 120) + ']'
        WHERE NUM_FACT = @NumFact;
        
        -- ============================================
        -- 3. Anular detalle
        -- ============================================
        UPDATE Detalle_Compras
        SET ANULADA = 1
        WHERE NUM_FACT = @NumFact;
        
        -- ============================================
        -- 4. Revertir Inventario (restar lo que se había sumado)
        -- ============================================
        -- Obtener detalles de la compra para revertir
        DECLARE @Detalles TABLE (
            CODIGO NVARCHAR(60),
            CANTIDAD FLOAT
        );
        
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
            ISNULL(I.EXISTENCIA, 0),
            D.CANTIDAD,
            ISNULL(I.EXISTENCIA, 0) - D.CANTIDAD,
            @CodUsuario,
            ISNULL(I.COSTO_REFERENCIA, 0),
            0,
            ISNULL(I.PRECIO_VENTA, 0),
            0
        FROM @Detalles D
        INNER JOIN Inventario I ON I.CODIGO = D.CODIGO
        WHERE D.CODIGO IS NOT NULL AND D.CANTIDAD > 0;
        
        -- Restar del inventario (revertir el ingreso)
        ;WITH Totales AS (
            SELECT CODIGO, SUM(CANTIDAD) AS TOTAL
            FROM @Detalles
            WHERE CODIGO IS NOT NULL
            GROUP BY CODIGO
        )
        UPDATE I 
        SET EXISTENCIA = ISNULL(I.EXISTENCIA, 0) - T.TOTAL
        FROM Inventario I
        INNER JOIN Totales T ON T.CODIGO = I.CODIGO;
        
        -- ============================================
        -- 5. Anular CxP (marcar como anulada en P_Pagar)
        -- ============================================
        -- Marcar como anulada (no eliminar, mantener historial)
        UPDATE P_Pagar
        SET PAID = 1,
            PEND = 0,
            SALDO = 0
        WHERE DOCUMENTO = @NumFact
          AND TIPO = 'FACT'
          AND CODIGO = @CodProveedor;
        
        -- ============================================
        -- 6. Recalcular saldos del proveedor
        -- ============================================
        DECLARE @SaldoTotal FLOAT;
        
        SELECT @SaldoTotal = ISNULL(SUM(ISNULL(PEND, 0)), 0)
        FROM P_Pagar 
        WHERE CODIGO = @CodProveedor 
        AND PAID = 0;
        
        UPDATE Proveedores 
        SET SALDO_TOT = @SaldoTotal,
            SALDO_30 = @SaldoTotal
        WHERE CODIGO = @CodProveedor;
        
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
