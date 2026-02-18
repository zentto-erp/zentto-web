-- =============================================
-- Stored Procedure: Emitir Documento de Compra (Unificado)
-- Maneja: ORDEN, COMPRA
-- Compatible con: SQL Server 2012+
-- =============================================

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_emitir_documento_compra_tx')
    DROP PROCEDURE sp_emitir_documento_compra_tx
GO

CREATE PROCEDURE sp_emitir_documento_compra_tx
    @TipoOperacion NVARCHAR(20),          -- ORDEN, COMPRA
    @DocXml NVARCHAR(MAX),                -- Datos del documento
    @DetalleXml NVARCHAR(MAX),            -- Líneas del documento
    @PagosXml NVARCHAR(MAX) = NULL,       -- Formas de pago (opcional)
    @CodUsuario NVARCHAR(60) = 'API',
    @ActualizarInventario BIT = 1,        -- Para COMPRA (ingresar)
    @GenerarCxP BIT = 1                   -- Solo para COMPRA
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    
    -- Validar tipo de operación
    IF @TipoOperacion NOT IN ('ORDEN', 'COMPRA')
    BEGIN
        RAISERROR('tipo_operacion_invalido', 16, 1);
        RETURN;
    END
    
    DECLARE @dx XML = CAST(@DocXml AS XML);
    DECLARE @det XML = CAST(@DetalleXml AS XML);
    DECLARE @pag XML = NULL;
    IF @PagosXml IS NOT NULL SET @pag = CAST(@PagosXml AS XML);
    
    -- Extraer campos principales
    DECLARE @NumDoc NVARCHAR(60) = NULLIF(@dx.value('(/doc/@NUM_DOC)[1]', 'nvarchar(60)'), '');
    DECLARE @SerialTipo NVARCHAR(60) = ISNULL(NULLIF(@dx.value('(/doc/@SERIALTIPO)[1]', 'nvarchar(60)'), ''), '');
    DECLARE @CodProveedor NVARCHAR(60) = NULLIF(@dx.value('(/doc/@COD_PROVEEDOR)[1]', 'nvarchar(60)'), '');
    DECLARE @Nombre NVARCHAR(255) = NULLIF(@dx.value('(/doc/@NOMBRE)[1]', 'nvarchar(255)'), '');
    DECLARE @Rif NVARCHAR(15) = NULLIF(@dx.value('(/doc/@RIF)[1]', 'nvarchar(15)'), '');
    DECLARE @FechaStr NVARCHAR(50) = NULLIF(@dx.value('(/doc/@FECHA)[1]', 'nvarchar(50)'), '');
    DECLARE @Fecha DATETIME = CASE WHEN ISDATE(@FechaStr) = 1 THEN CAST(@FechaStr AS DATETIME) ELSE GETDATE() END;
    DECLARE @FechaVenceStr NVARCHAR(50) = NULLIF(@dx.value('(/doc/@FECHA_VENCE)[1]', 'nvarchar(50)'), '');
    DECLARE @FechaVence DATETIME = CASE WHEN ISDATE(@FechaVenceStr) = 1 THEN CAST(@FechaVenceStr AS DATETIME) ELSE NULL END;
    DECLARE @FechaReciboStr NVARCHAR(50) = NULLIF(@dx.value('(/doc/@FECHA_RECIBO)[1]', 'nvarchar(50)'), '');
    DECLARE @FechaRecibo DATETIME = CASE WHEN ISDATE(@FechaReciboStr) = 1 THEN CAST(@FechaReciboStr AS DATETIME) ELSE NULL END;
    DECLARE @Observ NVARCHAR(500) = NULLIF(@dx.value('(/doc/@OBSERV)[1]', 'nvarchar(500)'), '');
    DECLARE @Concepto NVARCHAR(255) = NULLIF(@dx.value('(/doc/@CONCEPTO)[1]', 'nvarchar(255)'), '');
    DECLARE @NumControl NVARCHAR(60) = NULLIF(@dx.value('(/doc/@NUM_CONTROL)[1]', 'nvarchar(60)'), '');
    DECLARE @DocOrigen NVARCHAR(60) = NULLIF(@dx.value('(/doc/@DOC_ORIGEN)[1]', 'nvarchar(60)'), '');
    DECLARE @Almacen NVARCHAR(50) = NULLIF(@dx.value('(/doc/@ALMACEN)[1]', 'nvarchar(50)'), '');
    DECLARE @PrecioDollarStr NVARCHAR(50) = NULLIF(@dx.value('(/doc/@PRECIO_DOLLAR)[1]', 'nvarchar(50)'), '');
    DECLARE @PrecioDollar FLOAT = CASE WHEN ISNUMERIC(@PrecioDollarStr) = 1 THEN CAST(@PrecioDollarStr AS FLOAT) ELSE 0 END;
    DECLARE @Moneda NVARCHAR(20) = ISNULL(NULLIF(@dx.value('(/doc/@MONEDA)[1]', 'nvarchar(20)'), ''), 'BS');
    DECLARE @TasaStr NVARCHAR(50) = NULLIF(@dx.value('(/doc/@TASA_CAMBIO)[1]', 'nvarchar(50)'), '');
    DECLARE @TasaCambio FLOAT = CASE WHEN ISNUMERIC(@TasaStr) = 1 THEN CAST(@TasaStr AS FLOAT) ELSE 1 END;
    
    -- Retenciones
    DECLARE @IvaRetenidoStr NVARCHAR(50) = NULLIF(@dx.value('(/doc/@IVA_RETENIDO)[1]', 'nvarchar(50)'), '');
    DECLARE @IvaRetenido FLOAT = CASE WHEN ISNUMERIC(@IvaRetenidoStr) = 1 THEN CAST(@IvaRetenidoStr AS FLOAT) ELSE 0 END;
    DECLARE @MontoIslrStr NVARCHAR(50) = NULLIF(@dx.value('(/doc/@MONTO_ISLR)[1]', 'nvarchar(50)'), '');
    DECLARE @MontoIslr FLOAT = CASE WHEN ISNUMERIC(@MontoIslrStr) = 1 THEN CAST(@MontoIslrStr AS FLOAT) ELSE 0 END;
    DECLARE @Islr NVARCHAR(50) = NULLIF(@dx.value('(/doc/@ISLR)[1]', 'nvarchar(50)'), '');
    
    IF @NumDoc IS NULL
    BEGIN
        RAISERROR('num_doc_requerido', 16, 1);
        RETURN;
    END
    
    -- Verificar duplicado
    IF EXISTS (SELECT 1 FROM DocumentosCompra WHERE NUM_DOC = @NumDoc AND TIPO_OPERACION = @TipoOperacion)
    BEGIN
        RAISERROR('documento_ya_existe', 16, 1);
        RETURN;
    END
    
    -- Variables para cálculos
    DECLARE @SubTotal FLOAT = 0;
    DECLARE @MontoIva FLOAT = 0;
    DECLARE @Total FLOAT = 0;
    DECLARE @MontoGra FLOAT = 0;
    DECLARE @MontoExe FLOAT = 0;
    DECLARE @Alicuota FLOAT = 0;
    DECLARE @Exento FLOAT = 0;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- 1. Insertar detalle temporal para cálculos
        DECLARE @DetalleTemp TABLE (
            RENGLON INT,
            COD_SERV NVARCHAR(60),
            DESCRIPCION NVARCHAR(255),
            CANTIDAD FLOAT,
            PRECIO FLOAT,
            COSTO FLOAT,
            ALICUOTA FLOAT,
            SUBTOTAL FLOAT,
            MONTO_IVA FLOAT,
            TOTAL FLOAT
        );
        
        INSERT INTO @DetalleTemp (RENGLON, COD_SERV, DESCRIPCION, CANTIDAD, PRECIO, COSTO, ALICUOTA, SUBTOTAL, MONTO_IVA, TOTAL)
        SELECT 
            ROW_NUMBER() OVER (ORDER BY (SELECT NULL)),
            NULLIF(X.value('@COD_SERV', 'nvarchar(60)'), ''),
            NULLIF(X.value('@DESCRIPCION', 'nvarchar(255)'), ''),
            ISNULL(CASE WHEN NULLIF(X.value('@CANTIDAD', 'nvarchar(50)'), '') IS NULL THEN 0 ELSE CAST(X.value('@CANTIDAD', 'nvarchar(50)') AS FLOAT) END, 0),
            ISNULL(CASE WHEN NULLIF(X.value('@PRECIO', 'nvarchar(50)'), '') IS NULL THEN 0 ELSE CAST(X.value('@PRECIO', 'nvarchar(50)') AS FLOAT) END, 0),
            ISNULL(CASE WHEN NULLIF(X.value('@COSTO', 'nvarchar(50)'), '') IS NULL THEN 0 ELSE CAST(X.value('@COSTO', 'nvarchar(50)') AS FLOAT) END, 0),
            ISNULL(CASE WHEN NULLIF(X.value('@ALICUOTA', 'nvarchar(50)'), '') IS NULL THEN 0 ELSE CAST(X.value('@ALICUOTA', 'nvarchar(50)') AS FLOAT) END, 0),
            0, 0, 0
        FROM @det.nodes('/detalles/row') T(X);
        
        -- Calcular totales por línea
        UPDATE @DetalleTemp SET
            SUBTOTAL = CANTIDAD * PRECIO,
            MONTO_IVA = CASE WHEN ALICUOTA > 0 THEN CANTIDAD * PRECIO * (ALICUOTA/100) ELSE 0 END,
            TOTAL = CANTIDAD * PRECIO * (1 + CASE WHEN ALICUOTA > 0 THEN ALICUOTA/100 ELSE 0 END);
        
        -- Calcular totales del documento
        SELECT @SubTotal = SUM(SUBTOTAL), @MontoIva = SUM(MONTO_IVA), @Total = SUM(TOTAL),
               @MontoGra = SUM(CASE WHEN ALICUOTA > 0 THEN SUBTOTAL ELSE 0 END),
               @MontoExe = SUM(CASE WHEN ALICUOTA = 0 THEN SUBTOTAL ELSE 0 END),
               @Exento = SUM(CASE WHEN ALICUOTA = 0 THEN SUBTOTAL ELSE 0 END),
               @Alicuota = MAX(ALICUOTA)
        FROM @DetalleTemp;
        
        -- 2. Insertar cabecera
        INSERT INTO DocumentosCompra (
            NUM_DOC, SERIALTIPO, TIPO_OPERACION, COD_PROVEEDOR, NOMBRE, RIF,
            FECHA, FECHA_VENCE, FECHA_RECIBO, HORA,
            SUBTOTAL, MONTO_GRA, MONTO_EXE, EXENTO, IVA, ALICUOTA, TOTAL,
            ANULADA, CANCELADA, RECIBIDA,
            DOC_ORIGEN, NUM_CONTROL, LEGAL,
            CONCEPTO, OBSERV, ALMACEN,
            IVA_RETENIDO, ISLR, MONTO_ISLR,
            MONEDA, TASA_CAMBIO, PRECIO_DOLLAR,
            COD_USUARIO, FECHA_REPORTE
        )
        VALUES (
            @NumDoc, @SerialTipo, @TipoOperacion, @CodProveedor, @Nombre, @Rif,
            @Fecha, @FechaVence, @FechaRecibo, CONVERT(NVARCHAR(8), GETDATE(), 108),
            @SubTotal, @MontoGra, @MontoExe, @Exento, @MontoIva, @Alicuota, @Total,
            0, 'N', 
            CASE WHEN @TipoOperacion = 'ORDEN' THEN 'N' ELSE NULL END,
            @DocOrigen, @NumControl, 
            CASE WHEN @TipoOperacion = 'COMPRA' THEN 1 ELSE 0 END,
            @Concepto, @Observ, @Almacen,
            @IvaRetenido, @Islr, @MontoIslr,
            @Moneda, @TasaCambio, @PrecioDollar,
            @CodUsuario, GETDATE()
        );
        
        -- 3. Insertar detalle
        INSERT INTO DocumentosCompraDetalle (
            NUM_DOC, TIPO_OPERACION, RENGLON, COD_SERV, DESCRIPCION,
            CANTIDAD, PRECIO, COSTO, ALICUOTA,
            SUBTOTAL, MONTO_IVA, TOTAL,
            CO_USUARIO, FECHA
        )
        SELECT @NumDoc, @TipoOperacion, RENGLON, COD_SERV, DESCRIPCION,
               CANTIDAD, PRECIO, COSTO, ALICUOTA,
               SUBTOTAL, MONTO_IVA, TOTAL,
               @CodUsuario, @Fecha
        FROM @DetalleTemp;
        
        -- 4. Insertar formas de pago (si aplica)
        IF @PagosXml IS NOT NULL AND EXISTS (SELECT 1 FROM @pag.nodes('/pagos/row') T(X))
        BEGIN
            INSERT INTO DocumentosCompraPago (
                NUM_DOC, TIPO_OPERACION, TIPO_PAGO, BANCO, NUMERO, MONTO, FECHA, CO_USUARIO
            )
            SELECT 
                @NumDoc, @TipoOperacion,
                NULLIF(X.value('@TIPO_PAGO', 'nvarchar(30)'), ''),
                NULLIF(X.value('@BANCO', 'nvarchar(60)'), ''),
                NULLIF(X.value('@NUMERO', 'nvarchar(60)'), ''),
                ISNULL(CASE WHEN NULLIF(X.value('@MONTO', 'nvarchar(50)'), '') IS NULL THEN 0 ELSE CAST(X.value('@MONTO', 'nvarchar(50)') AS FLOAT) END, 0),
                @Fecha, @CodUsuario
            FROM @pag.nodes('/pagos/row') T(X);
        END
        
        -- 5. Actualizar inventario (para COMPRA)
        IF @ActualizarInventario = 1 AND @TipoOperacion = 'COMPRA'
        BEGIN
            -- Actualizar costos y existencias
            ;WITH Costos AS (
                SELECT COD_SERV, 
                       SUM(CANTIDAD) AS TOTAL_CANT,
                       AVG(PRECIO) AS AVG_PRECIO
                FROM @DetalleTemp
                WHERE COD_SERV IS NOT NULL
                GROUP BY COD_SERV
            )
            UPDATE I SET 
                EXISTENCIA = ISNULL(I.EXISTENCIA, 0) + C.TOTAL_CANT,
                COSTO_REFERENCIA = C.AVG_PRECIO,
                ULTIMO_COSTO = C.AVG_PRECIO
            FROM Inventario I
            INNER JOIN Costos C ON C.COD_SERV = I.CODIGO;
            
            -- Registrar movimiento (costo al momento de la operación para reporte SENIAT)
            INSERT INTO MovInvent (CODIGO, PRODUCT, DOCUMENTO, FECHA, MOTIVO, TIPO,
                CANTIDAD_ACTUAL, CANTIDAD, CANTIDAD_NUEVA, CO_USUARIO,
                PRECIO_COMPRA, ALICUOTA, PRECIO_VENTA)
            SELECT D.COD_SERV, D.COD_SERV, @NumDoc, @Fecha, 
                'COMPRA:' + @NumDoc, 'Ingreso',
                ISNULL(I.EXISTENCIA, 0) - D.CANTIDAD,
                D.CANTIDAD,
                ISNULL(I.EXISTENCIA, 0),
                @CodUsuario,
                ISNULL(D.PRECIO, D.COSTO),
                ISNULL(D.ALICUOTA, 0),
                ISNULL(I.PRECIO_VENTA, 0)
            FROM @DetalleTemp D
            INNER JOIN Inventario I ON I.CODIGO = D.COD_SERV
            WHERE D.COD_SERV IS NOT NULL;
        END
        
        -- 6. Generar CxP (solo para COMPRA)
        IF @GenerarCxP = 1 AND @TipoOperacion = 'COMPRA'
        BEGIN
            INSERT INTO P_Pagar (CODIGO, FACTURA, FECHA, FECHA_VENCE, TOTAL, ABONO, SALDO,
                TIPO, DOCUMENTO, REFERENCIA, OBSERVACION, 
                FECHA_E, COD_USUARIO, ANULADA, CANCELADA)
            SELECT @CodProveedor, @NumDoc, @Fecha, @FechaVence, @Total, 0, @Total,
                'COMPRA', @NumDoc, @NumControl, @Observ,
                @Fecha, @CodUsuario, 0, 'N'
            WHERE NOT EXISTS (SELECT 1 FROM P_Pagar WHERE FACTURA = @NumDoc);
        END
        
        -- 7. Actualizar orden si se está recibiendo como compra
        IF @DocOrigen IS NOT NULL AND @TipoOperacion = 'COMPRA'
        BEGIN
            UPDATE DocumentosCompra SET 
                RECIBIDA = 'S'
            WHERE NUM_DOC = @DocOrigen AND TIPO_OPERACION = 'ORDEN';
        END
        
        COMMIT TRANSACTION;
        
        SELECT CAST(1 AS BIT) AS ok, @NumDoc AS numDoc, @TipoOperacion AS tipoOperacion,
               @Total AS total, (SELECT COUNT(1) FROM @DetalleTemp) AS lineas;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        DECLARE @Err NVARCHAR(4000);
        SET @Err = ERROR_MESSAGE();
        RAISERROR(@Err, 16, 1);
    END CATCH
END
GO

SELECT name, create_date FROM sys.objects WHERE type = 'P' AND name = 'sp_emitir_documento_compra_tx';
