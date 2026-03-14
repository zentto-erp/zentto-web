-- =============================================
-- Stored Procedure: Anular Pedido (Transaccional)
-- Descripcion: Anula un pedido y reversa el inventario comprometido
-- Compatible con: SQL Server 2012+
-- =============================================

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_anular_pedido_tx')
    DROP PROCEDURE sp_anular_pedido_tx
GO

CREATE PROCEDURE sp_anular_pedido_tx
    @NumPedido NVARCHAR(60),
    @CodUsuario NVARCHAR(60) = 'API',
    @Motivo NVARCHAR(500) = ''
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @FechaAnulacion DATETIME = GETDATE();
    DECLARE @YaAnulado BIT;
    
    SELECT @YaAnulado = CASE WHEN ANULADA = 1 OR ANULADA = '1' THEN 1 ELSE 0 END
    FROM Pedidos WHERE NUM_FACT = @NumPedido;
    
    IF @YaAnulado IS NULL BEGIN RAISERROR('pedido_not_found', 16, 1); RETURN; END
    IF @YaAnulado = 1 BEGIN RAISERROR('pedido_already_anulled', 16, 1); RETURN; END
    
    BEGIN TRANSACTION;
    
    UPDATE Pedidos SET ANULADA = 1, OBSERV = ISNULL(OBSERV, '') + ' [ANULADO: ' + CONVERT(NVARCHAR(20), @FechaAnulacion, 120) + ']'
    WHERE NUM_FACT = @NumPedido;
    UPDATE Detalle_Pedidos SET ANULADA = 1 WHERE NUM_FACT = @NumPedido;
    
    -- Reversar inventario
    DECLARE @Detalles TABLE (COD_SERV NVARCHAR(60), CANTIDAD FLOAT);
    INSERT INTO @Detalles SELECT COD_SERV, ISNULL(CANTIDAD, 0) FROM Detalle_Pedidos WHERE NUM_FACT = @NumPedido AND ISNULL(ANULADA, 0) = 0;
    
    INSERT INTO MovInvent (DOCUMENTO, CODIGO, PRODUCT, FECHA, MOTIVO, TIPO, CANTIDAD_ACTUAL, CANTIDAD, CANTIDAD_NUEVA, CO_USUARIO)
    SELECT @NumPedido + '_ANUL', D.COD_SERV, D.COD_SERV, @FechaAnulacion, 'Anulacion Pedido:' + @NumPedido, 'Anulacion Pedido',
           ISNULL(I.EXISTENCIA, 0), D.CANTIDAD, ISNULL(I.EXISTENCIA, 0) + D.CANTIDAD, @CodUsuario
    FROM @Detalles D INNER JOIN Inventario I ON I.CODIGO = D.COD_SERV WHERE D.COD_SERV IS NOT NULL AND D.CANTIDAD > 0;
    
    ;WITH Totales AS (SELECT COD_SERV, SUM(CANTIDAD) AS TOTAL FROM @Detalles WHERE COD_SERV IS NOT NULL GROUP BY COD_SERV)
    UPDATE I SET EXISTENCIA = ISNULL(I.EXISTENCIA, 0) + T.TOTAL FROM Inventario I INNER JOIN Totales T ON T.COD_SERV = I.CODIGO;
    
    COMMIT TRANSACTION;
    
    SELECT CAST(1 AS BIT) AS ok, @NumPedido AS numPedido, 'Pedido anulado' AS mensaje;
END
GO

SELECT name, create_date FROM sys.objects WHERE type = 'P' AND name = 'sp_anular_pedido_tx';
