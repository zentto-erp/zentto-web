-- =============================================
-- Stored Procedure: Emitir Documento de Venta (Unificado)
-- Maneja: FACT, PRESUP, PEDIDO, COTIZ, NOTACRED, NOTADEB, NOTA_ENTREGA
-- Compatible con: SQL Server 2012+
-- =============================================

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_emitir_documento_venta_tx')
    DROP PROCEDURE sp_emitir_documento_venta_tx
GO

CREATE PROCEDURE sp_emitir_documento_venta_tx
    @TipoOperacion NVARCHAR(20),          -- FACT, PRESUP, PEDIDO, COTIZ, NOTACRED, NOTADEB, NOTA_ENTREGA
    @DocXml NVARCHAR(MAX),                -- Datos del documento
    @DetalleXml NVARCHAR(MAX),            -- Líneas del documento
    @PagosXml NVARCHAR(MAX) = NULL,       -- Formas de pago (opcional, para FACT)
    @CodUsuario NVARCHAR(60) = 'API',
    @ActualizarInventario BIT = 1,        -- Para PEDIDO, NOTA_ENTREGA (comprometer/egresar)
    @GenerarCxC BIT = 1                   -- Solo para FACT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    
    -- Validar tipo de operación
    IF @TipoOperacion NOT IN ('FACT', 'PRESUP', 'PEDIDO', 'COTIZ', 'NOTACRED', 'NOTADEB', 'NOTA_ENTREGA')
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
    DECLARE @Codigo NVARCHAR(60) = NULLIF(@dx.value('(/doc/@CODIGO)[1]', 'nvarchar(60)'), '');
    DECLARE @Nombre NVARCHAR(255) = NULLIF(@dx.value('(/doc/@NOMBRE)[1]', 'nvarchar(255)'), '');
    DECLARE @Rif NVARCHAR(20) = NULLIF(@dx.value('(/doc/@RIF)[1]', 'nvarchar(20)'), '');
    DECLARE @FechaStr NVARCHAR(50) = NULLIF(@dx.value('(/doc/@FECHA)[1]', 'nvarchar(50)'), '');
    DECLARE @Fecha DATETIME = CASE WHEN ISDATE(@FechaStr) = 1 THEN CAST(@FechaStr AS DATETIME) ELSE GETDATE() END;
    DECLARE @FechaVenceStr NVARCHAR(50) = NULLIF(@dx.value('(/doc/@FECHA_VENCE)[1]', 'nvarchar(50)'), '');
    DECLARE @FechaVence DATETIME = CASE WHEN ISDATE(@FechaVenceStr) = 1 THEN CAST(@FechaVenceStr AS DATETIME) ELSE NULL END;
    DECLARE @Observ NVARCHAR(500) = NULLIF(@dx.value('(/doc/@OBSERV)[1]', 'nvarchar(500)'), '');
    DECLARE @Vendedor NVARCHAR(60) = NULLIF(@dx.value('(/doc/@VENDEDOR)[1]', 'nvarchar(60)'), '');
    DECLARE @DocOrigen NVARCHAR(60) = NULLIF(@dx.value('(/doc/@DOC_ORIGEN)[1]', 'nvarchar(60)'), '');
    DECLARE @TipoDocOrigen NVARCHAR(20) = NULLIF(@dx.value('(/doc/@TIPO_DOC_ORIGEN)[1]', 'nvarchar(20)'), '');
    DECLARE @NumControl NVARCHAR(60) = NULLIF(@dx.value('(/doc/@NUM_CONTROL)[1]', 'nvarchar(60)'), '');
    DECLARE @Terminos NVARCHAR(255) = NULLIF(@dx.value('(/doc/@TERMINOS)[1]', 'nvarchar(255)'), '');
    DECLARE @Moneda NVARCHAR(20) = ISNULL(NULLIF(@dx.value('(/doc/@MONEDA)[1]', 'nvarchar(20)'), ''), 'BS');
    DECLARE @TasaStr NVARCHAR(50) = NULLIF(@dx.value('(/doc/@TASA_CAMBIO)[1]', 'nvarchar(50)'), '');
    DECLARE @TasaCambio FLOAT = CASE WHEN ISNUMERIC(@TasaStr) = 1 THEN CAST(@TasaStr AS FLOAT) ELSE 1 END;
    DECLARE @DescuentoStr NVARCHAR(50) = NULLIF(@dx.value('(/doc/@DESCUENTO)[1]', 'nvarchar(50)'), '');
    DECLARE @Descuento FLOAT = CASE WHEN ISNUMERIC(@DescuentoStr) = 1 THEN CAST(@DescuentoStr AS FLOAT) ELSE 0 END;
    DECLARE @Placas NVARCHAR(20) = NULLIF(@dx.value('(/doc/@PLACAS)[1]', 'nvarchar(20)'), '');
    DECLARE @KilometrosStr NVARCHAR(50) = NULLIF(@dx.value('(/doc/@KILOMETROS)[1]', 'nvarchar(50)'), '');
    DECLARE @Kilometros INT = CASE WHEN ISNUMERIC(@KilometrosStr) = 1 THEN CAST(@KilometrosStr AS INT) ELSE NULL END;
    
    IF @NumDoc IS NULL
    BEGIN
        RAISERROR('num_doc_requerido', 16, 1);
        RETURN;
    END
    
    -- Verificar duplicado
    IF EXISTS (SELECT 1 FROM DocumentosVenta WHERE NUM_DOC = @NumDoc AND TIPO_OPERACION = @TipoOperacion)
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
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- 1. Insertar detalle temporal para cálculos
        DECLARE @DetalleTemp TABLE (
            RENGLON INT,
            COD_SERV NVARCHAR(60),
            DESCRIPCION NVARCHAR(255),
            CANTIDAD FLOAT,
            PRECIO FLOAT,
            PRECIO_DESC FLOAT,
            ALICUOTA FLOAT,
            SUBTOTAL FLOAT,
            MONTO_IVA FLOAT,
            TOTAL FLOAT
        );
        
        INSERT INTO @DetalleTemp (RENGLON, COD_SERV, DESCRIPCION, CANTIDAD, PRECIO, PRECIO_DESC, ALICUOTA, SUBTOTAL, MONTO_IVA, TOTAL)
        SELECT 
            ROW_NUMBER() OVER (ORDER BY (SELECT NULL)),
            NULLIF(X.value('@COD_SERV', 'nvarchar(60)'), ''),
            NULLIF(X.value('@DESCRIPCION', 'nvarchar(255)'), ''),
            ISNULL(CASE WHEN NULLIF(X.value('@CANTIDAD', 'nvarchar(50)'), '') IS NULL THEN 0 ELSE CAST(X.value('@CANTIDAD', 'nvarchar(50)') AS FLOAT) END, 0),
            ISNULL(CASE WHEN NULLIF(X.value('@PRECIO', 'nvarchar(50)'), '') IS NULL THEN 0 ELSE CAST(X.value('@PRECIO', 'nvarchar(50)') AS FLOAT) END, 0),
            ISNULL(CASE WHEN NULLIF(X.value('@PRECIO_DESCUENTO', 'nvarchar(50)'), '') IS NULL THEN 0 ELSE CAST(X.value('@PRECIO_DESCUENTO', 'nvarchar(50)') AS FLOAT) END, 0),
            ISNULL(CASE WHEN NULLIF(X.value('@ALICUOTA', 'nvarchar(50)'), '') IS NULL THEN 0 ELSE CAST(X.value('@ALICUOTA', 'nvarchar(50)') AS FLOAT) END, 0),
            0, 0, 0
        FROM @det.nodes('/detalles/row') T(X);
        
        -- Calcular totales por línea
        UPDATE @DetalleTemp SET
            SUBTOTAL = CANTIDAD * CASE WHEN PRECIO_DESC > 0 THEN PRECIO_DESC ELSE PRECIO END,
            MONTO_IVA = CASE WHEN ALICUOTA > 0 THEN CANTIDAD * CASE WHEN PRECIO_DESC > 0 THEN PRECIO_DESC ELSE PRECIO END * (ALICUOTA/100) ELSE 0 END,
            TOTAL = CANTIDAD * CASE WHEN PRECIO_DESC > 0 THEN PRECIO_DESC ELSE PRECIO END * (1 + CASE WHEN ALICUOTA > 0 THEN ALICUOTA/100 ELSE 0 END);
        
        -- Calcular totales del documento
        SELECT @SubTotal = SUM(SUBTOTAL), @MontoIva = SUM(MONTO_IVA), @Total = SUM(TOTAL),
               @MontoGra = SUM(CASE WHEN ALICUOTA > 0 THEN SUBTOTAL ELSE 0 END),
               @MontoExe = SUM(CASE WHEN ALICUOTA = 0 THEN SUBTOTAL ELSE 0 END),
               @Alicuota = MAX(ALICUOTA)
        FROM @DetalleTemp;
        
        -- Aplicar descuento global
        IF @Descuento > 0
        BEGIN
            SET @SubTotal = @SubTotal * (1 - @Descuento/100);
            SET @MontoIva = @MontoIva * (1 - @Descuento/100);
            SET @Total = @SubTotal + @MontoIva;
        END
        
        -- 2. Insertar cabecera
        INSERT INTO DocumentosVenta (
            NUM_DOC, SERIALTIPO, TIPO_OPERACION, CODIGO, NOMBRE, RIF,
            FECHA, FECHA_VENCE, HORA,
            SUBTOTAL, MONTO_GRA, MONTO_EXE, IVA, ALICUOTA, TOTAL, DESCUENTO,
            ANULADA, CANCELADA, FACTURADA, ENTREGADA,
            DOC_ORIGEN, TIPO_DOC_ORIGEN, NUM_CONTROL, LEGAL,
            OBSERV, TERMINOS, VENDEDOR,
            MONEDA, TASA_CAMBIO,
            PLACAS, KILOMETROS,
            COD_USUARIO, FECHA_REPORTE
        )
        VALUES (
            @NumDoc, @SerialTipo, @TipoOperacion, @Codigo, @Nombre, @Rif,
            @Fecha, @FechaVence, CONVERT(NVARCHAR(8), GETDATE(), 108),
            @SubTotal, @MontoGra, @MontoExe, @MontoIva, @Alicuota, @Total, @Descuento,
            0, 'N', 
            CASE WHEN @TipoOperacion = 'PEDIDO' THEN 'N' ELSE NULL END,
            CASE WHEN @TipoOperacion = 'NOTA_ENTREGA' THEN 'N' ELSE NULL END,
            @DocOrigen, @TipoDocOrigen, @NumControl, 
            CASE WHEN @TipoOperacion = 'FACT' THEN 1 ELSE 0 END,
            @Observ, @Terminos, @Vendedor,
            @Moneda, @TasaCambio,
            @Placas, @Kilometros,
            @CodUsuario, GETDATE()
        );
        
        -- 3. Insertar detalle
        INSERT INTO DocumentosVentaDetalle (
            NUM_DOC, TIPO_OPERACION, RENGLON, COD_SERV, DESCRIPCION,
            CANTIDAD, PRECIO, PRECIO_DESCUENTO, ALICUOTA,
            SUBTOTAL, MONTO_IVA, TOTAL,
            CO_USUARIO, FECHA
        )
        SELECT @NumDoc, @TipoOperacion, RENGLON, COD_SERV, DESCRIPCION,
               CANTIDAD, PRECIO, PRECIO_DESC, ALICUOTA,
               SUBTOTAL, MONTO_IVA, TOTAL,
               @CodUsuario, @Fecha
        FROM @DetalleTemp;
        
        -- 4. Insertar formas de pago (si aplica)
        IF @PagosXml IS NOT NULL AND EXISTS (SELECT 1 FROM @pag.nodes('/pagos/row') T(X))
        BEGIN
            INSERT INTO DocumentosVentaPago (
                NUM_DOC, TIPO_OPERACION, TIPO_PAGO, BANCO, NUMERO, MONTO, TASA_CAMBIO, FECHA, CO_USUARIO
            )
            SELECT 
                @NumDoc, @TipoOperacion,
                NULLIF(X.value('@TIPO_PAGO', 'nvarchar(30)'), ''),
                NULLIF(X.value('@BANCO', 'nvarchar(60)'), ''),
                NULLIF(X.value('@NUMERO', 'nvarchar(60)'), ''),
                ISNULL(CASE WHEN NULLIF(X.value('@MONTO', 'nvarchar(50)'), '') IS NULL THEN 0 ELSE CAST(X.value('@MONTO', 'nvarchar(50)') AS FLOAT) END, 0),
                ISNULL(CASE WHEN NULLIF(X.value('@TASA_CAMBIO', 'nvarchar(50)'), '') IS NULL THEN @TasaCambio ELSE CAST(X.value('@TASA_CAMBIO', 'nvarchar(50)') AS FLOAT) END, 1),
                @Fecha, @CodUsuario
            FROM @pag.nodes('/pagos/row') T(X);
        END
        
        -- 5. Actualizar inventario (para PEDIDO, NOTA_ENTREGA, NOTACRED que afecta stock)
        IF @ActualizarInventario = 1 AND @TipoOperacion IN ('PEDIDO', 'NOTA_ENTREGA')
        BEGIN
            -- Descontar inventario
            ;WITH Totales AS (
                SELECT COD_SERV, SUM(CANTIDAD) AS TOTAL_CANT
                FROM @DetalleTemp
                WHERE COD_SERV IS NOT NULL
                GROUP BY COD_SERV
            )
            UPDATE I SET EXISTENCIA = ISNULL(I.EXISTENCIA, 0) - T.TOTAL_CANT
            FROM Inventario I
            INNER JOIN Totales T ON T.COD_SERV = I.CODIGO;
            
            -- Registrar movimiento (costo y precio venta al momento de la operación para reporte SENIAT)
            INSERT INTO MovInvent (CODIGO, PRODUCT, DOCUMENTO, FECHA, MOTIVO, TIPO,
                CANTIDAD_ACTUAL, CANTIDAD, CANTIDAD_NUEVA, CO_USUARIO,
                PRECIO_COMPRA, ALICUOTA, PRECIO_VENTA)
            SELECT D.COD_SERV, D.COD_SERV, @NumDoc, @Fecha, 
                @TipoOperacion + ':' + @NumDoc, 
                CASE @TipoOperacion WHEN 'NOTACRED' THEN 'Ingreso' ELSE 'Egreso' END,
                ISNULL(I.EXISTENCIA, 0) + D.CANTIDAD * CASE WHEN @TipoOperacion = 'NOTACRED' THEN -1 ELSE 1 END,
                D.CANTIDAD,
                ISNULL(I.EXISTENCIA, 0),
                @CodUsuario,
                ISNULL(I.COSTO_REFERENCIA, I.ULTIMO_COSTO),
                ISNULL(D.ALICUOTA, 0),
                D.PRECIO
            FROM @DetalleTemp D
            INNER JOIN Inventario I ON I.CODIGO = D.COD_SERV
            WHERE D.COD_SERV IS NOT NULL;
        END
        
        -- 6. Generar CxC (solo para FACT)
        IF @GenerarCxC = 1 AND @TipoOperacion = 'FACT'
        BEGIN
            INSERT INTO P_Cobrar (CODIGO, FACTURA, FECHA, FECHA_VENCE, TOTAL, ABONO, SALDO,
                TIPO, DOCUMENTO, NUMERO, REFERENCIA, OBSERVACION, 
                FECHA_E, COD_USUARIO, SERIALTIPO, ANULADA)
            SELECT @Codigo, @NumDoc, @Fecha, @FechaVence, @Total, 0, @Total,
                @TipoOperacion, @SerialTipo, @NumDoc, @NumControl, @Observ,
                @Fecha, @CodUsuario, @SerialTipo, 0
            WHERE NOT EXISTS (SELECT 1 FROM P_Cobrar WHERE FACTURA = @NumDoc);
        END
        
        -- 7. Actualizar documento origen si aplica (ej: Pedido -> Factura)
        IF @DocOrigen IS NOT NULL AND @TipoDocOrigen IS NOT NULL
        BEGIN
            UPDATE DocumentosVenta SET 
                FACTURADA = 'S',
                DOC_ORIGEN = @DocOrigen
            WHERE NUM_DOC = @DocOrigen AND TIPO_OPERACION = @TipoDocOrigen;
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

SELECT name, create_date FROM sys.objects WHERE type = 'P' AND name = 'sp_emitir_documento_venta_tx';
