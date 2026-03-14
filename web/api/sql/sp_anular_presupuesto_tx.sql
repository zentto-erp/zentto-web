-- DEPRECATED: Este SP usa tablas legacy. Ver la versión canónica en el API TypeScript.
-- Referencias a dbo.Inventario actualizadas a master.Product (StockQty, ProductCode).
-- Referencias a dbo.Clientes actualizadas a master.Customer (TotalBalance, CustomerCode).
-- Tablas legacy sin migrar (Presupuestos, Detalle_Presupuestos, P_Cobrar, P_CobrarC, etc.)
-- mantienen sus nombres originales — ver TODOs en el codigo.
-- =============================================
-- Stored Procedure: Anular Presupuesto (revertir inventario y CxC tipo PRESUP)
-- Compatible con: SQL Server 2012+
-- =============================================

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_anular_presupuesto_tx')
    DROP PROCEDURE sp_anular_presupuesto_tx
GO

CREATE PROCEDURE sp_anular_presupuesto_tx
    @NumFact NVARCHAR(60),
    @CodUsuario NVARCHAR(60) = 'API',
    @Motivo NVARCHAR(500) = ''
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @FechaAnulacion DATETIME = GETDATE();
    DECLARE @CodCliente NVARCHAR(60);
    DECLARE @YaAnulada BIT;

    -- TODO: tabla Presupuestos es legacy
    SELECT @CodCliente = CODIGO, @YaAnulada = CASE WHEN ANULADA = 1 THEN 1 ELSE 0 END
    FROM Presupuestos WHERE NUM_FACT = @NumFact;

    IF @CodCliente IS NULL
    BEGIN
        RAISERROR('presupuesto_not_found', 16, 1);
        RETURN;
    END
    IF @YaAnulada = 1
    BEGIN
        RAISERROR('presupuesto_already_anulled', 16, 1);
        RETURN;
    END

    BEGIN TRY
        BEGIN TRANSACTION;

        -- ============================================
        -- 1. Marcar presupuesto como anulado
        -- TODO: tabla Presupuestos es legacy
        -- ============================================
        UPDATE Presupuestos
        SET ANULADA = 1,
            OBSERV = ISNULL(OBSERV, '') + ' [ANULADA: ' + CONVERT(NVARCHAR(20), @FechaAnulacion, 120) + ']'
        WHERE NUM_FACT = @NumFact;

        -- ============================================
        -- 2. Anular detalle
        -- TODO: tabla Detalle_Presupuestos es legacy
        -- ============================================
        UPDATE Detalle_Presupuestos SET ANULADA = 1 WHERE NUM_FACT = @NumFact;

        -- ============================================
        -- 3. Revertir master.Product (antes dbo.Inventario)
        -- ============================================
        DECLARE @Detalles TABLE (COD_SERV NVARCHAR(60), CANTIDAD FLOAT, RELACIONADA INT, COD_ALTERNO NVARCHAR(60));

        -- TODO: tabla Detalle_Presupuestos es legacy
        INSERT INTO @Detalles (COD_SERV, CANTIDAD, RELACIONADA, COD_ALTERNO)
        SELECT COD_SERV, ISNULL(CANTIDAD, 0), CASE WHEN Relacionada = 1 THEN 1 ELSE 0 END, Cod_Alterno
        FROM Detalle_Presupuestos WHERE NUM_FACT = @NumFact AND ISNULL(ANULADA, 0) = 0;

        -- Insertar movimiento de anulacion en MovInvent
        INSERT INTO MovInvent (
            DOCUMENTO, CODIGO, PRODUCT, FECHA, MOTIVO, TIPO,
            CANTIDAD_ACTUAL, CANTIDAD, CANTIDAD_NUEVA, CO_USUARIO,
            PRECIO_COMPRA, ALICUOTA, PRECIO_VENTA, ANULADA
        )
        SELECT
            @NumFact + '_ANUL',
            D.COD_SERV,
            D.COD_SERV,
            @FechaAnulacion,
            'Anulacion Presupuesto:' + @NumFact + ' - ' + @Motivo,
            'Anulacion Egreso',
            ISNULL(I.StockQty, 0),          -- columna canonica master.Product
            D.CANTIDAD,
            ISNULL(I.StockQty, 0) + D.CANTIDAD,
            @CodUsuario,
            ISNULL(I.COSTO_REFERENCIA, 0),
            0,
            ISNULL(I.SalesPrice, 0),        -- columna canonica master.Product
            0
        FROM @Detalles D
        -- Ahora se usa master.Product (antes dbo.Inventario)
        INNER JOIN master.Product I ON I.ProductCode = D.COD_SERV
        WHERE D.COD_SERV IS NOT NULL AND D.CANTIDAD > 0;

        -- Sumar de vuelta al inventario en master.Product
        ;WITH Totales AS (
            SELECT COD_SERV, SUM(CANTIDAD) AS TOTAL FROM @Detalles WHERE COD_SERV IS NOT NULL GROUP BY COD_SERV
        )
        -- Actualizar master.Product.StockQty (columna canonica, antes dbo.Inventario.EXISTENCIA)
        UPDATE I SET StockQty = ISNULL(I.StockQty, 0) + T.TOTAL
        FROM master.Product I INNER JOIN Totales T ON T.COD_SERV = I.ProductCode;

        -- Sumar de vuelta a Inventario_Aux si es relacionada
        ;WITH AuxTotales AS (
            SELECT COD_ALTERNO, SUM(CANTIDAD) AS TOTAL
            FROM @Detalles WHERE RELACIONADA = 1 AND COD_ALTERNO IS NOT NULL GROUP BY COD_ALTERNO
        )
        UPDATE IA SET CANTIDAD = ISNULL(IA.CANTIDAD, 0) + A.TOTAL
        FROM Inventario_Aux IA INNER JOIN AuxTotales A ON A.COD_ALTERNO = IA.CODIGO;

        -- ============================================
        -- 4. Anular CxC (P_Cobrar / P_CobrarC)
        -- TODO: tablas P_Cobrar y P_CobrarC son legacy
        -- ============================================
        UPDATE P_Cobrar SET PAID = 1, PEND = 0, SALDO = 0
        WHERE DOCUMENTO = @NumFact AND TIPO = 'PRESUP' AND CODIGO = @CodCliente;
        IF @@ROWCOUNT = 0
            UPDATE P_CobrarC SET PAID = 1, PEND = 0, SALDO = 0
            WHERE DOCUMENTO = @NumFact AND TIPO = 'PRESUP' AND CODIGO = @CodCliente;

        -- ============================================
        -- 5. Recalcular saldos del cliente en master.Customer (tabla canonica)
        -- Antes actualizaba dbo.Clientes.SALDO_TOT; ahora actualiza master.Customer.TotalBalance
        -- ============================================
        DECLARE @SaldoTotal FLOAT;

        -- TODO: tablas P_Cobrar y P_CobrarC son legacy
        SELECT @SaldoTotal = ISNULL(SUM(ISNULL(PEND, 0)), 0) FROM P_Cobrar WHERE CODIGO = @CodCliente AND PAID = 0;
        IF @SaldoTotal IS NULL
            SELECT @SaldoTotal = ISNULL(SUM(ISNULL(PEND, 0)), 0) FROM P_CobrarC WHERE CODIGO = @CodCliente AND PAID = 0;

        UPDATE master.Customer
        SET TotalBalance = ISNULL(@SaldoTotal, 0)
        WHERE CustomerCode = @CodCliente
          AND ISNULL(IsDeleted, 0) = 0;

        COMMIT TRANSACTION;

        SELECT CAST(1 AS BIT) AS ok, @NumFact AS numFact, @CodCliente AS codCliente, 'Presupuesto anulada' AS mensaje;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        DECLARE @Err NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@Err, 16, 1);
    END CATCH
END
GO

SELECT name, create_date FROM sys.objects WHERE type = 'P' AND name = 'sp_anular_presupuesto_tx';
