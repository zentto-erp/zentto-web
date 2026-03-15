-- DEPRECATED: Este SP usa tablas legacy. Ver la versión canónica en el API TypeScript.
-- Referencias a dbo.Inventario actualizadas a master.Product (StockQty, ProductCode, SalesPrice).
-- Tablas legacy sin migrar (DocumentosVenta, DocumentosVentaDetalle, P_Cobrar, etc.)
-- mantienen sus nombres originales — ver TODOs en el codigo.
-- =============================================
-- Stored Procedure: Anular Documento de Venta (Unificado)
-- Maneja: FACT, PRESUP, PEDIDO, COTIZ, NOTACRED, NOTADEB, NOTA_ENTREGA
-- Compatible con: SQL Server 2012+
-- =============================================

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_anular_documento_venta_tx')
    DROP PROCEDURE sp_anular_documento_venta_tx
GO

CREATE PROCEDURE sp_anular_documento_venta_tx
    @NumDoc NVARCHAR(60),
    @TipoOperacion NVARCHAR(20),
    @CodUsuario NVARCHAR(60) = 'API',
    @Motivo NVARCHAR(500) = '',
    @RevertirInventario BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @FechaAnulacion DATETIME = SYSUTCDATETIME();
    DECLARE @YaAnulado BIT;
    DECLARE @FechaDoc DATETIME;

    -- Verificar existencia
    -- TODO: tabla DocumentosVenta es legacy
    SELECT @YaAnulado = ANULADA, @FechaDoc = FECHA
    FROM DocumentosVenta
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

    -- Validaciones específicas por tipo
    -- TODO: tabla DocumentosVenta es legacy
    IF @TipoOperacion = 'PEDIDO' AND EXISTS (SELECT 1 FROM DocumentosVenta WHERE DOC_ORIGEN = @NumDoc AND ANULADA = 0)
    BEGIN
        RAISERROR('pedido_tiene_factura_asociada', 16, 1);
        RETURN;
    END

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Cargar detalle antes de marcar anulado (para reversión de inventario)
        -- TODO: tabla DocumentosVentaDetalle es legacy
        DECLARE @Detalles TABLE (COD_SERV NVARCHAR(60), CANTIDAD FLOAT, PRECIO FLOAT, ALICUOTA FLOAT);
        IF @RevertirInventario = 1 AND @TipoOperacion IN ('PEDIDO', 'NOTA_ENTREGA')
            INSERT INTO @Detalles
            SELECT COD_SERV, ISNULL(CANTIDAD, 0), ISNULL(PRECIO, 0), ISNULL(ALICUOTA, 0)
            FROM DocumentosVentaDetalle
            WHERE NUM_DOC = @NumDoc AND TIPO_OPERACION = @TipoOperacion AND ISNULL(ANULADA, 0) = 0;

        -- Marcar como anulado
        -- TODO: tabla DocumentosVenta es legacy
        UPDATE DocumentosVenta SET
            ANULADA = 1,
            OBSERV = ISNULL(OBSERV, '') + ' [ANULADO: ' + CONVERT(NVARCHAR(20), @FechaAnulacion, 120) + ISNULL(' - ' + @Motivo, '') + ']'
        WHERE NUM_DOC = @NumDoc AND TIPO_OPERACION = @TipoOperacion;

        -- Anular detalle
        -- TODO: tabla DocumentosVentaDetalle es legacy
        UPDATE DocumentosVentaDetalle SET ANULADA = 1
        WHERE NUM_DOC = @NumDoc AND TIPO_OPERACION = @TipoOperacion;

        -- ============================================
        -- Reversar inventario en master.Product (antes dbo.Inventario) si aplica
        -- ============================================
        IF @RevertirInventario = 1 AND @TipoOperacion IN ('PEDIDO', 'NOTA_ENTREGA')
        BEGIN
            -- Devolver inventario en master.Product.StockQty (antes dbo.Inventario.EXISTENCIA)
            ;WITH Totales AS (
                SELECT COD_SERV, SUM(CANTIDAD) AS TOTAL
                FROM @Detalles
                WHERE COD_SERV IS NOT NULL
                GROUP BY COD_SERV
            )
            -- Ahora se usa master.Product (antes dbo.Inventario)
            UPDATE I SET StockQty = ISNULL(I.StockQty, 0) + T.TOTAL
            FROM master.Product I
            INNER JOIN Totales T ON T.COD_SERV = I.ProductCode;

            -- Registrar movimiento de reversión
            INSERT INTO MovInvent (CODIGO, PRODUCT, DOCUMENTO, FECHA, MOTIVO, TIPO,
                CANTIDAD_ACTUAL, CANTIDAD, CANTIDAD_NUEVA, CO_USUARIO,
                PRECIO_COMPRA, ALICUOTA, PRECIO_VENTA)
            SELECT D.COD_SERV, D.COD_SERV, @NumDoc + '_ANUL', @FechaAnulacion,
                'Anulacion ' + @TipoOperacion + ':' + @NumDoc, 'Ingreso',
                ISNULL(I.StockQty, 0) - D.CANTIDAD,     -- columna canonica master.Product
                D.CANTIDAD,
                ISNULL(I.StockQty, 0),                  -- columna canonica master.Product
                @CodUsuario,
                ISNULL(I.COSTO_REFERENCIA, 0),
                ISNULL(D.ALICUOTA, 0),
                ISNULL(D.PRECIO, 0)
            FROM @Detalles D
            -- Ahora se usa master.Product (antes dbo.Inventario)
            INNER JOIN master.Product I ON I.ProductCode = D.COD_SERV
            WHERE D.COD_SERV IS NOT NULL AND D.CANTIDAD > 0;
        END

        -- Reversar CxC si era factura
        -- TODO: tabla P_Cobrar es legacy
        IF @TipoOperacion = 'FACT'
        BEGIN
            UPDATE P_Cobrar SET
                ANULADA = 1,
                SALDO = 0,
                OBSERVACION = ISNULL(OBSERVACION, '') + ' [ANULADO]'
            WHERE FACTURA = @NumDoc AND ANULADA = 0;

            -- Insertar nota de crédito automática si es necesario para el fiscal
            -- (esto dependerá de requerimientos específicos del impresor fiscal)
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

SELECT name, create_date FROM sys.objects WHERE type = 'P' AND name = 'sp_anular_documento_venta_tx';
