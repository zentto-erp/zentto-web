-- =============================================
-- Stored Procedures para Documentos Unificados
-- Adaptados a la estructura existente de tablas
-- =============================================

-- =============================================
-- 1. EMITIR DOCUMENTO DE VENTA
-- =============================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_emitir_documento_venta_tx')
    DROP PROCEDURE sp_emitir_documento_venta_tx
GO

CREATE PROCEDURE sp_emitir_documento_venta_tx
    @TipoOperacion NVARCHAR(20),
    @DocXml NVARCHAR(MAX),
    @DetalleXml NVARCHAR(MAX),
    @PagosXml NVARCHAR(MAX) = NULL,
    @CodUsuario NVARCHAR(60) = 'API',
    @ActualizarInventario BIT = 1,
    @GenerarCxC BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    
    IF @TipoOperacion NOT IN ('FACT', 'PRESUP', 'PEDIDO', 'COTIZ', 'NOTACRED', 'NOTADEB', 'NOTA_ENTREGA')
    BEGIN
        RAISERROR('tipo_operacion_invalido', 16, 1);
        RETURN;
    END
    
    DECLARE @dx XML = CAST(@DocXml AS XML);
    DECLARE @det XML = CAST(@DetalleXml AS XML);
    
    DECLARE @NumFact NVARCHAR(60) = NULLIF(@dx.value('(/doc/@NUM_FACT)[1]', 'nvarchar(60)'), '');
    DECLARE @SerialTipo NVARCHAR(60) = ISNULL(NULLIF(@dx.value('(/doc/@SERIALTIPO)[1]', 'nvarchar(60)'), ''), '');
    DECLARE @TipoOrden NVARCHAR(6) = ISNULL(NULLIF(@dx.value('(/doc/@Tipo_Orden)[1]', 'nvarchar(6)'), ''), '');
    DECLARE @Codigo NVARCHAR(12) = NULLIF(@dx.value('(/doc/@CODIGO)[1]', 'nvarchar(12)'), '');
    DECLARE @FechaStr NVARCHAR(50) = NULLIF(@dx.value('(/doc/@FECHA)[1]', 'nvarchar(50)'), '');
    DECLARE @Fecha DATETIME = CASE WHEN ISDATE(@FechaStr) = 1 THEN CAST(@FechaStr AS DATETIME) ELSE GETDATE() END;
    DECLARE @TotalStr NVARCHAR(50) = NULLIF(@dx.value('(/doc/@TOTAL)[1]', 'nvarchar(50)'), '');
    DECLARE @Total DECIMAL(18,4) = CASE WHEN ISNUMERIC(@TotalStr) = 1 THEN CAST(@TotalStr AS DECIMAL(18,4)) ELSE 0 END;
    DECLARE @Observ NVARCHAR(4000) = NULLIF(@dx.value('(/doc/@OBSERV)[1]', 'nvarchar(4000)'), '');
    DECLARE @CodUsuarioDoc NVARCHAR(60) = ISNULL(NULLIF(@dx.value('(/doc/@COD_USUARIO)[1]', 'nvarchar(60)'), ''), @CodUsuario);
    DECLARE @MontoEfectStr NVARCHAR(50) = NULLIF(@dx.value('(/doc/@Monto_Efect)[1]', 'nvarchar(50)'), '');
    DECLARE @MontoEfect DECIMAL(18,4) = CASE WHEN ISNUMERIC(@MontoEfectStr) = 1 THEN CAST(@MontoEfectStr AS DECIMAL(18,4)) ELSE 0 END;
    DECLARE @MontoChequeStr NVARCHAR(50) = NULLIF(@dx.value('(/doc/@Monto_Cheque)[1]', 'nvarchar(50)'), '');
    DECLARE @MontoCheque DECIMAL(18,4) = CASE WHEN ISNUMERIC(@MontoChequeStr) = 1 THEN CAST(@MontoChequeStr AS DECIMAL(18,4)) ELSE 0 END;
    DECLARE @MontoTarjetaStr NVARCHAR(50) = NULLIF(@dx.value('(/doc/@Monto_Tarjeta)[1]', 'nvarchar(50)'), '');
    DECLARE @MontoTarjeta DECIMAL(18,4) = CASE WHEN ISNUMERIC(@MontoTarjetaStr) = 1 THEN CAST(@MontoTarjetaStr AS DECIMAL(18,4)) ELSE 0 END;
    DECLARE @BancoCheque NVARCHAR(120) = NULLIF(@dx.value('(/doc/@BANCO_CHEQUE)[1]', 'nvarchar(120)'), '');
    DECLARE @BancoTarjeta NVARCHAR(120) = NULLIF(@dx.value('(/doc/@Banco_Tarjeta)[1]', 'nvarchar(120)'), '');
    DECLARE @Tarjeta NVARCHAR(60) = NULLIF(@dx.value('(/doc/@Tarjeta)[1]', 'nvarchar(60)'), '');
    DECLARE @Cta NVARCHAR(80) = NULLIF(@dx.value('(/doc/@Cta)[1]', 'nvarchar(80)'), '');
    
    IF @NumFact IS NULL
    BEGIN
        RAISERROR('num_fact_requerido', 16, 1);
        RETURN;
    END
    
    IF EXISTS (SELECT 1 FROM DocumentosVenta WHERE NUM_FACT = @NumFact)
    BEGIN
        RAISERROR('documento_ya_existe', 16, 1);
        RETURN;
    END
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Insertar cabecera
        INSERT INTO DocumentosVenta (
            NUM_FACT, SERIALTIPO, Tipo_Orden, TIPO_OPERACION, CODIGO,
            FECHA, FECHA_REPORTE, TOTAL, COD_USUARIO, OBSERV,
            CANCELADA, Monto_Efect, Monto_Cheque, Monto_Tarjeta,
            BANCO_CHEQUE, Banco_Tarjeta, Tarjeta, Cta
        )
        VALUES (
            @NumFact, @SerialTipo, @TipoOrden, @TipoOperacion, @Codigo,
            @Fecha, GETDATE(), @Total, @CodUsuarioDoc, @Observ,
            'N', @MontoEfect, @MontoCheque, @MontoTarjeta,
            @BancoCheque, @BancoTarjeta, @Tarjeta, @Cta
        );
        
        -- Insertar detalle
        INSERT INTO DocumentosVentaDetalle (
            NUM_FACT, SERIALTIPO, Tipo_Orden, COD_SERV,
            CANTIDAD, PRECIO, ALICUOTA, TOTAL, PRECIO_DESCUENTO, Relacionada, Cod_Alterno
        )
        SELECT 
            @NumFact, @SerialTipo, @TipoOrden,
            NULLIF(X.value('@COD_SERV', 'nvarchar(80)'), ''),
            CASE WHEN NULLIF(X.value('@CANTIDAD', 'nvarchar(50)'), '') IS NULL THEN 0 ELSE CAST(X.value('@CANTIDAD', 'nvarchar(50)') AS DECIMAL(18,4)) END,
            CASE WHEN NULLIF(X.value('@PRECIO', 'nvarchar(50)'), '') IS NULL THEN 0 ELSE CAST(X.value('@PRECIO', 'nvarchar(50)') AS DECIMAL(18,4)) END,
            CASE WHEN NULLIF(X.value('@ALICUOTA', 'nvarchar(50)'), '') IS NULL THEN 0 ELSE CAST(X.value('@ALICUOTA', 'nvarchar(50)') AS DECIMAL(18,4)) END,
            CASE WHEN NULLIF(X.value('@TOTAL', 'nvarchar(50)'), '') IS NULL THEN 0 ELSE CAST(X.value('@TOTAL', 'nvarchar(50)') AS DECIMAL(18,4)) END,
            CASE WHEN NULLIF(X.value('@PRECIO_DESCUENTO', 'nvarchar(50)'), '') IS NULL THEN 0 ELSE CAST(X.value('@PRECIO_DESCUENTO', 'nvarchar(50)') AS DECIMAL(18,4)) END,
            CASE WHEN NULLIF(X.value('@Relacionada', 'nvarchar(10)'), '') IS NULL THEN 0 ELSE CAST(X.value('@Relacionada', 'nvarchar(10)') AS INT) END,
            NULLIF(X.value('@Cod_Alterno', 'nvarchar(60)'), '')
        FROM @det.nodes('/detalles/row') T(X);
        
        -- Insertar pagos si aplica
        IF @PagosXml IS NOT NULL
        BEGIN
            DECLARE @pag XML = CAST(@PagosXml AS XML);
            INSERT INTO DocumentosVentaPago (NUM_DOC, TIPO_OPERACION, TIPO_PAGO, BANCO, NUMERO, MONTO, FECHA, CO_USUARIO)
            SELECT 
                @NumFact, @TipoOperacion,
                NULLIF(X.value('@TIPO_PAGO', 'nvarchar(30)'), ''),
                NULLIF(X.value('@BANCO', 'nvarchar(60)'), ''),
                NULLIF(X.value('@NUMERO', 'nvarchar(60)'), ''),
                CASE WHEN NULLIF(X.value('@MONTO', 'nvarchar(50)'), '') IS NULL THEN 0 ELSE CAST(X.value('@MONTO', 'nvarchar(50)') AS FLOAT) END,
                @Fecha, @CodUsuario
            FROM @pag.nodes('/pagos/row') T(X);
        END
        
        -- Generar CxC si es FACTURA
        IF @GenerarCxC = 1 AND @TipoOperacion = 'FACT'
        BEGIN
            INSERT INTO P_Cobrar (CODIGO, FECHA, DOCUMENTO, DEBE, HABER, SALDO, TIPO, OBS, COD_USUARIO)
            SELECT @Codigo, @Fecha, @NumFact, @Total, 0, @Total, @TipoOperacion, 'CxC generada desde documento', @CodUsuario
            WHERE NOT EXISTS (SELECT 1 FROM P_Cobrar WHERE DOCUMENTO = @NumFact);
        END
        
        COMMIT TRANSACTION;
        
        SELECT CAST(1 AS BIT) AS ok, @NumFact AS numFact, @TipoOperacion AS tipoOperacion, @Total AS total;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        DECLARE @Err NVARCHAR(4000);
        SET @Err = ERROR_MESSAGE();
        RAISERROR(@Err, 16, 1);
    END CATCH
END
GO

-- =============================================
-- 2. EMITIR DOCUMENTO DE COMPRA
-- =============================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_emitir_documento_compra_tx')
    DROP PROCEDURE sp_emitir_documento_compra_tx
GO

CREATE PROCEDURE sp_emitir_documento_compra_tx
    @TipoOperacion NVARCHAR(20),
    @DocXml NVARCHAR(MAX),
    @DetalleXml NVARCHAR(MAX),
    @PagosXml NVARCHAR(MAX) = NULL,
    @CodUsuario NVARCHAR(60) = 'API',
    @ActualizarInventario BIT = 1,
    @GenerarCxP BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    
    IF @TipoOperacion NOT IN ('ORDEN', 'COMPRA')
    BEGIN
        RAISERROR('tipo_operacion_invalido', 16, 1);
        RETURN;
    END
    
    DECLARE @dx XML = CAST(@DocXml AS XML);
    DECLARE @det XML = CAST(@DetalleXml AS XML);
    
    DECLARE @NumFact NVARCHAR(60) = NULLIF(@dx.value('(/doc/@NUM_FACT)[1]', 'nvarchar(60)'), '');
    DECLARE @CodProveedor NVARCHAR(10) = NULLIF(@dx.value('(/doc/@COD_PROVEEDOR)[1]', 'nvarchar(10)'), '');
    DECLARE @SerialTipo NVARCHAR(60) = ISNULL(NULLIF(@dx.value('(/doc/@SERIALTIPO)[1]', 'nvarchar(60)'), ''), '');
    DECLARE @TipoOrden NVARCHAR(6) = ISNULL(NULLIF(@dx.value('(/doc/@Tipo_Orden)[1]', 'nvarchar(6)'), ''), '');
    DECLARE @FechaStr NVARCHAR(50) = NULLIF(@dx.value('(/doc/@FECHA)[1]', 'nvarchar(50)'), '');
    DECLARE @Fecha DATETIME = CASE WHEN ISDATE(@FechaStr) = 1 THEN CAST(@FechaStr AS DATETIME) ELSE GETDATE() END;
    DECLARE @TotalStr NVARCHAR(50) = NULLIF(@dx.value('(/doc/@TOTAL)[1]', 'nvarchar(50)'), '');
    DECLARE @Total DECIMAL(18,4) = CASE WHEN ISNUMERIC(@TotalStr) = 1 THEN CAST(@TotalStr AS DECIMAL(18,4)) ELSE 0 END;
    DECLARE @Observ NVARCHAR(500) = NULLIF(@dx.value('(/doc/@CONCEPTO)[1]', 'nvarchar(500)'), '');
    DECLARE @Nombre NVARCHAR(200) = NULLIF(@dx.value('(/doc/@NOMBRE)[1]', 'nvarchar(200)'), '');
    DECLARE @Rif NVARCHAR(50) = NULLIF(@dx.value('(/doc/@RIF)[1]', 'nvarchar(50)'), '');
    DECLARE @Tipo NVARCHAR(30) = NULLIF(@dx.value('(/doc/@TIPO)[1]', 'nvarchar(30)'), '');
    
    IF @NumFact IS NULL
    BEGIN
        RAISERROR('num_fact_requerido', 16, 1);
        RETURN;
    END
    
    IF EXISTS (SELECT 1 FROM DocumentosCompra WHERE NUM_FACT = @NumFact)
    BEGIN
        RAISERROR('documento_ya_existe', 16, 1);
        RETURN;
    END
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Insertar cabecera
        INSERT INTO DocumentosCompra (NUM_FACT, COD_PROVEEDOR, TIPO_OPERACION, FECHA, NOMBRE, RIF, TOTAL, TIPO, CONCEPTO, COD_USUARIO, SERIALTIPO, Tipo_Orden, ANULADA)
        VALUES (@NumFact, @CodProveedor, @TipoOperacion, @Fecha, @Nombre, @Rif, @Total, @Tipo, @Observ, @CodUsuario, @SerialTipo, @TipoOrden, 0);
        
        -- Insertar detalle
        INSERT INTO DocumentosCompraDetalle (NUM_FACT, COD_PROVEEDOR, CODIGO, Referencia, DESCRIPCION, FECHA, CANTIDAD, PRECIO_COSTO, Alicuota, Co_Usuario)
        SELECT 
            @NumFact, @CodProveedor,
            NULLIF(X.value('@CODIGO', 'nvarchar(80)'), ''),
            NULLIF(X.value('@Referencia', 'nvarchar(60)'), ''),
            NULLIF(X.value('@DESCRIPCION', 'nvarchar(200)'), ''),
            @Fecha,
            CASE WHEN NULLIF(X.value('@CANTIDAD', 'nvarchar(50)'), '') IS NULL THEN 0 ELSE CAST(X.value('@CANTIDAD', 'nvarchar(50)') AS DECIMAL(18,4)) END,
            CASE WHEN NULLIF(X.value('@PRECIO_COSTO', 'nvarchar(50)'), '') IS NULL THEN 0 ELSE CAST(X.value('@PRECIO_COSTO', 'nvarchar(50)') AS DECIMAL(18,4)) END,
            CASE WHEN NULLIF(X.value('@Alicuota', 'nvarchar(50)'), '') IS NULL THEN 0 ELSE CAST(X.value('@Alicuota', 'nvarchar(50)') AS DECIMAL(18,4)) END,
            @CodUsuario
        FROM @det.nodes('/detalles/row') T(X);
        
        -- Insertar pagos si aplica
        IF @PagosXml IS NOT NULL
        BEGIN
            DECLARE @pag XML = CAST(@PagosXml AS XML);
            INSERT INTO DocumentosCompraPago (NUM_DOC, TIPO_OPERACION, TIPO_PAGO, BANCO, NUMERO, MONTO, FECHA, CO_USUARIO)
            SELECT 
                @NumFact, @TipoOperacion,
                NULLIF(X.value('@TIPO_PAGO', 'nvarchar(30)'), ''),
                NULLIF(X.value('@BANCO', 'nvarchar(60)'), ''),
                NULLIF(X.value('@NUMERO', 'nvarchar(60)'), ''),
                CASE WHEN NULLIF(X.value('@MONTO', 'nvarchar(50)'), '') IS NULL THEN 0 ELSE CAST(X.value('@MONTO', 'nvarchar(50)') AS FLOAT) END,
                @Fecha, @CodUsuario
            FROM @pag.nodes('/pagos/row') T(X);
        END
        
        -- Generar CxP si es COMPRA
        IF @GenerarCxP = 1 AND @TipoOperacion = 'COMPRA'
        BEGIN
            INSERT INTO P_Pagar (CODIGO, FECHA, DOCUMENTO, DEBE, HABER, SALDO, TIPO, OBS, Cod_usuario)
            SELECT @CodProveedor, @Fecha, @NumFact, @Total, 0, @Total, 'COMPRA', 'CxP generada desde documento', @CodUsuario
            WHERE NOT EXISTS (SELECT 1 FROM P_Pagar WHERE DOCUMENTO = @NumFact);
        END
        
        COMMIT TRANSACTION;
        
        SELECT CAST(1 AS BIT) AS ok, @NumFact AS numFact, @TipoOperacion AS tipoOperacion, @Total AS total;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        DECLARE @Err NVARCHAR(4000);
        SET @Err = ERROR_MESSAGE();
        RAISERROR(@Err, 16, 1);
    END CATCH
END
GO

-- =============================================
-- 3. LISTAR DOCUMENTOS VENTA
-- =============================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_DocumentosVenta_List')
    DROP PROCEDURE sp_DocumentosVenta_List
GO

CREATE PROCEDURE sp_DocumentosVenta_List
    @TipoOperacion NVARCHAR(20) = NULL,
    @Search NVARCHAR(100) = NULL,
    @Codigo NVARCHAR(12) = NULL,
    @Desde DATE = NULL,
    @Hasta DATE = NULL,
    @Anulada BIT = NULL,
    @Page INT = 1,
    @Limit INT = 50,
    @TotalCount INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Offset INT = (@Page - 1) * @Limit;
    
    SELECT @TotalCount = COUNT(1) FROM DocumentosVenta
    WHERE (@TipoOperacion IS NULL OR TIPO_OPERACION = @TipoOperacion)
      AND (@Search IS NULL OR NUM_FACT LIKE '%' + @Search + '%' OR OBSERV LIKE '%' + @Search + '%')
      AND (@Codigo IS NULL OR CODIGO = @Codigo)
      AND (@Desde IS NULL OR CAST(FECHA AS DATE) >= @Desde)
      AND (@Hasta IS NULL OR CAST(FECHA AS DATE) <= @Hasta)
      AND (@Anulada IS NULL OR CASE WHEN FECHA_ANULA IS NULL THEN 0 ELSE 1 END = @Anulada);
    
    SELECT *, 
        CASE WHEN FECHA_ANULA IS NOT NULL THEN 'ANULADO' WHEN CANCELADA = 'S' THEN 'CANCELADO' ELSE 'PENDIENTE' END AS ESTADO
    FROM DocumentosVenta
    WHERE (@TipoOperacion IS NULL OR TIPO_OPERACION = @TipoOperacion)
      AND (@Search IS NULL OR NUM_FACT LIKE '%' + @Search + '%' OR OBSERV LIKE '%' + @Search + '%')
      AND (@Codigo IS NULL OR CODIGO = @Codigo)
      AND (@Desde IS NULL OR CAST(FECHA AS DATE) >= @Desde)
      AND (@Hasta IS NULL OR CAST(FECHA AS DATE) <= @Hasta)
      AND (@Anulada IS NULL OR CASE WHEN FECHA_ANULA IS NULL THEN 0 ELSE 1 END = @Anulada)
    ORDER BY FECHA DESC
    OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;
END
GO

-- =============================================
-- 4. LISTAR DOCUMENTOS COMPRA
-- =============================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_DocumentosCompra_List')
    DROP PROCEDURE sp_DocumentosCompra_List
GO

CREATE PROCEDURE sp_DocumentosCompra_List
    @TipoOperacion NVARCHAR(20) = NULL,
    @Search NVARCHAR(100) = NULL,
    @CodProveedor NVARCHAR(10) = NULL,
    @Desde DATE = NULL,
    @Hasta DATE = NULL,
    @Anulada BIT = NULL,
    @Page INT = 1,
    @Limit INT = 50,
    @TotalCount INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Offset INT = (@Page - 1) * @Limit;
    
    SELECT @TotalCount = COUNT(1) FROM DocumentosCompra
    WHERE (@TipoOperacion IS NULL OR TIPO_OPERACION = @TipoOperacion)
      AND (@Search IS NULL OR NUM_FACT LIKE '%' + @Search + '%' OR NOMBRE LIKE '%' + @Search + '%')
      AND (@CodProveedor IS NULL OR COD_PROVEEDOR = @CodProveedor)
      AND (@Desde IS NULL OR CAST(FECHA AS DATE) >= @Desde)
      AND (@Hasta IS NULL OR CAST(FECHA AS DATE) <= @Hasta)
      AND (@Anulada IS NULL OR ANULADA = @Anulada);
    
    SELECT *, 
        CASE WHEN ANULADA = 1 THEN 'ANULADO' ELSE 'PENDIENTE' END AS ESTADO
    FROM DocumentosCompra
    WHERE (@TipoOperacion IS NULL OR TIPO_OPERACION = @TipoOperacion)
      AND (@Search IS NULL OR NUM_FACT LIKE '%' + @Search + '%' OR NOMBRE LIKE '%' + @Search + '%')
      AND (@CodProveedor IS NULL OR COD_PROVEEDOR = @CodProveedor)
      AND (@Desde IS NULL OR CAST(FECHA AS DATE) >= @Desde)
      AND (@Hasta IS NULL OR CAST(FECHA AS DATE) <= @Hasta)
      AND (@Anulada IS NULL OR ANULADA = @Anulada)
    ORDER BY FECHA DESC
    OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;
END
GO

-- =============================================
-- 5. ANULAR DOCUMENTO VENTA
-- =============================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_anular_documento_venta_tx')
    DROP PROCEDURE sp_anular_documento_venta_tx
GO

CREATE PROCEDURE sp_anular_documento_venta_tx
    @NumFact NVARCHAR(60),
    @TipoOperacion NVARCHAR(20) = NULL,
    @CodUsuario NVARCHAR(60) = 'API',
    @Motivo NVARCHAR(500) = ''
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    
    IF NOT EXISTS (SELECT 1 FROM DocumentosVenta WHERE NUM_FACT = @NumFact)
    BEGIN
        RAISERROR('documento_no_encontrado', 16, 1);
        RETURN;
    END
    
    IF EXISTS (SELECT 1 FROM DocumentosVenta WHERE NUM_FACT = @NumFact AND FECHA_ANULA IS NOT NULL)
    BEGIN
        RAISERROR('documento_ya_anulado', 16, 1);
        RETURN;
    END
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        UPDATE DocumentosVenta SET 
            FECHA_ANULA = GETDATE(),
            MOTIVO_ANULA = @Motivo
        WHERE NUM_FACT = @NumFact;
        
        -- Anular en CxC si existe
        IF @TipoOperacion = 'FACT'
        BEGIN
            UPDATE P_Cobrar SET SALDO = 0, PAID = 1, OBS = CAST(OBS AS NVARCHAR(MAX)) + ' [ANULADO]' WHERE DOCUMENTO = @NumFact;
        END
        
        COMMIT TRANSACTION;
        
        SELECT CAST(1 AS BIT) AS ok, @NumFact AS numFact, 'Documento anulado' AS mensaje;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        DECLARE @Err NVARCHAR(4000);
        SET @Err = ERROR_MESSAGE();
        RAISERROR(@Err, 16, 1);
    END CATCH
END
GO

-- =============================================
-- 6. ANULAR DOCUMENTO COMPRA
-- =============================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_anular_documento_compra_tx')
    DROP PROCEDURE sp_anular_documento_compra_tx
GO

CREATE PROCEDURE sp_anular_documento_compra_tx
    @NumFact NVARCHAR(60),
    @TipoOperacion NVARCHAR(20) = NULL,
    @CodUsuario NVARCHAR(60) = 'API',
    @Motivo NVARCHAR(500) = ''
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    
    IF NOT EXISTS (SELECT 1 FROM DocumentosCompra WHERE NUM_FACT = @NumFact)
    BEGIN
        RAISERROR('documento_no_encontrado', 16, 1);
        RETURN;
    END
    
    IF EXISTS (SELECT 1 FROM DocumentosCompra WHERE NUM_FACT = @NumFact AND ANULADA = 1)
    BEGIN
        RAISERROR('documento_ya_anulado', 16, 1);
        RETURN;
    END
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        UPDATE DocumentosCompra SET ANULADA = 1 WHERE NUM_FACT = @NumFact;
        
        -- Anular en CxP si existe
        IF @TipoOperacion = 'COMPRA'
        BEGIN
            UPDATE P_Pagar SET SALDO = 0, PAID = 1, OBS = CAST(OBS AS NVARCHAR(MAX)) + ' [ANULADO]' WHERE DOCUMENTO = @NumFact;
        END
        
        COMMIT TRANSACTION;
        
        SELECT CAST(1 AS BIT) AS ok, @NumFact AS numFact, 'Documento anulado' AS mensaje;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        DECLARE @Err NVARCHAR(4000);
        SET @Err = ERROR_MESSAGE();
        RAISERROR(@Err, 16, 1);
    END CATCH
END
GO

SELECT name, create_date FROM sys.objects WHERE type = 'P' AND name LIKE '%documento%' ORDER BY name;
