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

        UPDATE Presupuestos SET ANULADA = 1, OBSERV = ISNULL(OBSERV, '') + ' [ANULADA: ' + CONVERT(NVARCHAR(20), @FechaAnulacion, 120) + ']' WHERE NUM_FACT = @NumFact;
        UPDATE Detalle_Presupuestos SET ANULADA = 1 WHERE NUM_FACT = @NumFact;

        DECLARE @Detalles TABLE (COD_SERV NVARCHAR(60), CANTIDAD FLOAT, RELACIONADA INT, COD_ALTERNO NVARCHAR(60));
        INSERT INTO @Detalles (COD_SERV, CANTIDAD, RELACIONADA, COD_ALTERNO)
        SELECT COD_SERV, ISNULL(CANTIDAD, 0), CASE WHEN Relacionada = 1 THEN 1 ELSE 0 END, Cod_Alterno
        FROM Detalle_Presupuestos WHERE NUM_FACT = @NumFact AND ISNULL(ANULADA, 0) = 0;

        INSERT INTO MovInvent (DOCUMENTO, CODIGO, PRODUCT, FECHA, MOTIVO, TIPO, CANTIDAD_ACTUAL, CANTIDAD, CANTIDAD_NUEVA, CO_USUARIO, PRECIO_COMPRA, ALICUOTA, PRECIO_VENTA, ANULADA)
        SELECT @NumFact + '_ANUL', D.COD_SERV, D.COD_SERV, @FechaAnulacion, 'Anulacion Presupuesto:' + @NumFact + ' - ' + @Motivo, 'Anulacion Egreso',
            ISNULL(I.EXISTENCIA, 0), D.CANTIDAD, ISNULL(I.EXISTENCIA, 0) + D.CANTIDAD, @CodUsuario, ISNULL(I.COSTO_REFERENCIA, 0), 0, ISNULL(I.PRECIO_VENTA, 0), 0
        FROM @Detalles D INNER JOIN Inventario I ON I.CODIGO = D.COD_SERV WHERE D.COD_SERV IS NOT NULL AND D.CANTIDAD > 0;

        ;WITH Totales AS (SELECT COD_SERV, SUM(CANTIDAD) AS TOTAL FROM @Detalles WHERE COD_SERV IS NOT NULL GROUP BY COD_SERV)
        UPDATE I SET EXISTENCIA = ISNULL(I.EXISTENCIA, 0) + T.TOTAL FROM Inventario I INNER JOIN Totales T ON T.COD_SERV = I.CODIGO;

        ;WITH AuxTotales AS (SELECT COD_ALTERNO, SUM(CANTIDAD) AS TOTAL FROM @Detalles WHERE RELACIONADA = 1 AND COD_ALTERNO IS NOT NULL GROUP BY COD_ALTERNO)
        UPDATE IA SET CANTIDAD = ISNULL(IA.CANTIDAD, 0) + A.TOTAL FROM Inventario_Aux IA INNER JOIN AuxTotales A ON A.COD_ALTERNO = IA.CODIGO;

        UPDATE P_Cobrar SET PAID = 1, PEND = 0, SALDO = 0 WHERE DOCUMENTO = @NumFact AND TIPO = 'PRESUP' AND CODIGO = @CodCliente;
        IF @@ROWCOUNT = 0
            UPDATE P_CobrarC SET PAID = 1, PEND = 0, SALDO = 0 WHERE DOCUMENTO = @NumFact AND TIPO = 'PRESUP' AND CODIGO = @CodCliente;

        DECLARE @SaldoTotal FLOAT;
        SELECT @SaldoTotal = ISNULL(SUM(ISNULL(PEND, 0)), 0) FROM P_Cobrar WHERE CODIGO = @CodCliente AND PAID = 0;
        IF @SaldoTotal IS NULL
            SELECT @SaldoTotal = ISNULL(SUM(ISNULL(PEND, 0)), 0) FROM P_CobrarC WHERE CODIGO = @CodCliente AND PAID = 0;
        UPDATE Clientes SET SALDO_TOT = ISNULL(@SaldoTotal, 0), SALDO_30 = ISNULL(@SaldoTotal, 0) WHERE CODIGO = @CodCliente;

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
