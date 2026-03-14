-- DEPRECATED: Este SP usa tablas legacy. Ver la versión canónica en el API TypeScript.
-- Referencias a dbo.Inventario actualizadas a master.Product (StockQty, ProductCode, SalesPrice).
-- Tablas legacy sin migrar (DocumentosCompra, DocumentosCompraDetalle, P_Pagar, etc.)
-- mantienen sus nombres originales — ver TODOs en el codigo.
-- =============================================
-- Stored Procedure: Anular Documento de Compra (Unificado)
-- Maneja: ORDEN, COMPRA
-- Compatible con: SQL Server 2012+
-- =============================================

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_anular_documento_compra_tx')
    DROP PROCEDURE sp_anular_documento_compra_tx
GO

CREATE PROCEDURE sp_anular_documento_compra_tx
    @NumDoc NVARCHAR(60),
    @TipoOperacion NVARCHAR(20),
    @CodUsuario NVARCHAR(60) = 'API',
    @Motivo NVARCHAR(500) = '',
    @RevertirInventario BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @FechaAnulacion DATETIME = GETDATE();
    DECLARE @YaAnulado BIT;

    -- Verificar existencia
    -- TODO: tabla DocumentosCompra es legacy
    SELECT @YaAnulado = ANULADA
    FROM DocumentosCompra
    WHERE NUM_DOC = @NumDoc AND TIPO_OPERACION = @TipoOperacion;

    IF @YaAnulado IS NULL
    BEGIN
        RAISERROR('documento_no_encontrado', 16, 1);
        RETURN;
    END

    IF @YaAnulado = 1
    BEGIN
        RAISERROR('documento_ya_anulado', 16, 1);
        RETURN;
    END

    -- Validaciones específicas
    -- TODO: tabla DocumentosCompra es legacy
    IF @TipoOperacion = 'ORDEN' AND EXISTS (SELECT 1 FROM DocumentosCompra WHERE DOC_ORIGEN = @NumDoc AND TIPO_OPERACION = 'COMPRA' AND ANULADA = 0)
    BEGIN
        RAISERROR('orden_tiene_compra_asociada', 16, 1);
        RETURN;
    END

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Cargar detalle antes de marcar anulado (para reversión de inventario)
        -- TODO: tabla DocumentosCompraDetalle es legacy
        DECLARE @Detalles TABLE (COD_SERV NVARCHAR(60), CANTIDAD FLOAT, PRECIO FLOAT);
        IF @RevertirInventario = 1 AND @TipoOperacion = 'COMPRA'
            INSERT INTO @Detalles
            SELECT COD_SERV, ISNULL(CANTIDAD, 0), ISNULL(PRECIO, ISNULL(COSTO, 0))
            FROM DocumentosCompraDetalle
            WHERE NUM_DOC = @NumDoc AND TIPO_OPERACION = @TipoOperacion AND ISNULL(ANULADA, 0) = 0;

        -- Marcar como anulado
        -- TODO: tabla DocumentosCompra es legacy
        UPDATE DocumentosCompra SET
            ANULADA = 1,
            OBSERV = ISNULL(OBSERV, '') + ' [ANULADO: ' + CONVERT(NVARCHAR(20), @FechaAnulacion, 120) + ISNULL(' - ' + @Motivo, '') + ']'
        WHERE NUM_DOC = @NumDoc AND TIPO_OPERACION = @TipoOperacion;

        -- Anular detalle
        -- TODO: tabla DocumentosCompraDetalle es legacy
        UPDATE DocumentosCompraDetalle SET ANULADA = 1
        WHERE NUM_DOC = @NumDoc AND TIPO_OPERACION = @TipoOperacion;

        -- ============================================
        -- Reversar inventario en master.Product (antes dbo.Inventario) si era compra
        -- ============================================
        IF @RevertirInventario = 1 AND @TipoOperacion = 'COMPRA'
        BEGIN
            -- Restar inventario en master.Product.StockQty (antes dbo.Inventario.EXISTENCIA)
            ;WITH Totales AS (
                SELECT COD_SERV, SUM(CANTIDAD) AS TOTAL
                FROM @Detalles
                WHERE COD_SERV IS NOT NULL
                GROUP BY COD_SERV
            )
            -- Ahora se usa master.Product (antes dbo.Inventario)
            UPDATE I SET StockQty = ISNULL(I.StockQty, 0) - T.TOTAL
            FROM master.Product I
            INNER JOIN Totales T ON T.COD_SERV = I.ProductCode;

            -- Registrar movimiento de reversión
            INSERT INTO MovInvent (CODIGO, PRODUCT, DOCUMENTO, FECHA, MOTIVO, TIPO,
                CANTIDAD_ACTUAL, CANTIDAD, CANTIDAD_NUEVA, CO_USUARIO,
                PRECIO_COMPRA, ALICUOTA, PRECIO_VENTA)
            SELECT D.COD_SERV, D.COD_SERV, @NumDoc + '_ANUL', @FechaAnulacion,
                'Anulacion COMPRA:' + @NumDoc, 'Egreso',
                ISNULL(I.StockQty, 0) + D.CANTIDAD,     -- columna canonica master.Product
                D.CANTIDAD,
                ISNULL(I.StockQty, 0),                  -- columna canonica master.Product
                @CodUsuario,
                ISNULL(D.PRECIO, 0),
                0,
                ISNULL(I.SalesPrice, 0)                 -- columna canonica master.Product
            FROM @Detalles D
            -- Ahora se usa master.Product (antes dbo.Inventario)
            INNER JOIN master.Product I ON I.ProductCode = D.COD_SERV
            WHERE D.COD_SERV IS NOT NULL AND D.CANTIDAD > 0;
        END

        -- Reversar CxP si era compra
        -- TODO: tabla P_Pagar es legacy
        IF @TipoOperacion = 'COMPRA'
        BEGIN
            UPDATE P_Pagar SET
                ANULADA = 1,
                SALDO = 0,
                OBSERVACION = ISNULL(OBSERVACION, '') + ' [ANULADO]'
            WHERE FACTURA = @NumDoc AND ANULADA = 0;
        END

        COMMIT TRANSACTION;

        SELECT CAST(1 AS BIT) AS ok, @NumDoc AS numDoc, @TipoOperacion AS tipoOperacion,
               'Documento anulado' AS mensaje, @RevertirInventario AS inventarioRevertido;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        DECLARE @Err NVARCHAR(4000);
        SET @Err = ERROR_MESSAGE();
        RAISERROR(@Err, 16, 1);
    END CATCH
END
GO

SELECT name, create_date FROM sys.objects WHERE type = 'P' AND name = 'sp_anular_documento_compra_tx';
