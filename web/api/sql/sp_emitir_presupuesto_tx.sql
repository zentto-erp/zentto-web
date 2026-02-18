-- =============================================
-- Stored Procedure: Emitir Presupuesto (transaccional)
-- Misma lógica que facturas: clientes, CxC, formas de pago, inventario, MovInvent
-- Tablas: Presupuestos, Detalle_Presupuestos. Compatible SQL Server 2012+
-- =============================================

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_emitir_presupuesto_tx')
    DROP PROCEDURE sp_emitir_presupuesto_tx
GO

CREATE PROCEDURE [dbo].[sp_emitir_presupuesto_tx]
    @PresupuestoXml NVARCHAR(MAX),
    @DetalleXml NVARCHAR(MAX),
    @FormasPagoXml NVARCHAR(MAX) = NULL,
    @ActualizarInventario BIT = 1,
    @GenerarCxC BIT = 1,
    @CxcTable NVARCHAR(20) = N'P_Cobrar',
    @FormaPagoTable NVARCHAR(128) = N'Detalle_FormaPagoCotizacion',
    @ActualizarSaldosCliente BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

    DECLARE @StartedTran BIT = 0;
    DECLARE @SaveName SYSNAME = N'sp_emitir_presupuesto_tx_save';
    DECLARE @fx XML = CAST(@PresupuestoXml AS XML);
    DECLARE @dx XML = CAST(@DetalleXml AS XML);
    DECLARE @px XML;
    IF @FormasPagoXml IS NOT NULL AND LTRIM(RTRIM(@FormasPagoXml)) <> ''
        SET @px = CAST(@FormasPagoXml AS XML);

    DECLARE @NumFact NVARCHAR(60), @Codigo NVARCHAR(60), @Pago NVARCHAR(30), @CodUsuario NVARCHAR(60);
    DECLARE @SerialTipo NVARCHAR(60), @TipoOrden NVARCHAR(80), @Observ NVARCHAR(4000);
    DECLARE @FechaStr NVARCHAR(50), @FechaReporteStr NVARCHAR(50), @Fecha DATETIME, @FechaReporte DATETIME, @Total DECIMAL(18,4);

    SET @NumFact = NULLIF(@fx.value('(/presupuesto/@NUM_FACT)[1]', 'nvarchar(60)'), '');
    IF @NumFact IS NULL SET @NumFact = NULLIF(@fx.value('(/factura/@NUM_FACT)[1]', 'nvarchar(60)'), '');
    SET @Codigo = NULLIF(@fx.value('(/presupuesto/@CODIGO)[1]', 'nvarchar(60)'), '');
    IF @Codigo IS NULL SET @Codigo = NULLIF(@fx.value('(/factura/@CODIGO)[1]', 'nvarchar(60)'), '');
    SET @Pago = UPPER(ISNULL(NULLIF(@fx.value('(/presupuesto/@PAGO)[1]', 'nvarchar(30)'), ''), ''));
    IF @Pago = '' SET @Pago = UPPER(ISNULL(NULLIF(@fx.value('(/factura/@PAGO)[1]', 'nvarchar(30)'), ''), ''));
    SET @CodUsuario = ISNULL(NULLIF(@fx.value('(/presupuesto/@COD_USUARIO)[1]', 'nvarchar(60)'), ''), 'API');
    IF @CodUsuario = 'API' SET @CodUsuario = ISNULL(NULLIF(@fx.value('(/factura/@COD_USUARIO)[1]', 'nvarchar(60)'), ''), 'API');
    -- SERIALTIPO = serial máquina fiscal; Tipo_Orden = número de memoria física (1, 2, ... si se reemplaza la memoria)
    SET @SerialTipo = ISNULL(NULLIF(@fx.value('(/presupuesto/@SERIALTIPO)[1]', 'nvarchar(60)'), ''), '');
    IF @SerialTipo = '' SET @SerialTipo = ISNULL(NULLIF(@fx.value('(/factura/@SERIALTIPO)[1]', 'nvarchar(60)'), ''), '');
    SET @TipoOrden = ISNULL(NULLIF(@fx.value('(/presupuesto/@Tipo_orden)[1]', 'nvarchar(80)'), ''), '');
    IF @TipoOrden = '' SET @TipoOrden = ISNULL(NULLIF(@fx.value('(/presupuesto/@TIPO_ORDEN)[1]', 'nvarchar(80)'), ''), '');
    IF @TipoOrden = '' SET @TipoOrden = ISNULL(NULLIF(@fx.value('(/factura/@TIPO_ORDEN)[1]', 'nvarchar(80)'), ''), '');
    SET @Observ = NULLIF(@fx.value('(/presupuesto/@OBSERV)[1]', 'nvarchar(4000)'), '');
    IF @Observ IS NULL SET @Observ = NULLIF(@fx.value('(/factura/@OBSERV)[1]', 'nvarchar(4000)'), '');
    SET @FechaStr = NULLIF(@fx.value('(/presupuesto/@FECHA)[1]', 'nvarchar(50)'), '');
    IF @FechaStr IS NULL SET @FechaStr = NULLIF(@fx.value('(/factura/@FECHA)[1]', 'nvarchar(50)'), '');
    SET @FechaReporteStr = NULLIF(@fx.value('(/presupuesto/@FECHA_REPORTE)[1]', 'nvarchar(50)'), '');
    IF @FechaReporteStr IS NULL SET @FechaReporteStr = NULLIF(@fx.value('(/factura/@FECHA_REPORTE)[1]', 'nvarchar(50)'), '');
    SET @Fecha = CASE WHEN ISDATE(@FechaStr) = 1 THEN CAST(@FechaStr AS DATETIME) ELSE GETDATE() END;
    SET @FechaReporte = CASE WHEN ISDATE(@FechaReporteStr) = 1 THEN CAST(@FechaReporteStr AS DATETIME) ELSE @Fecha END;
    SET @Total = CASE WHEN NULLIF(@fx.value('(/presupuesto/@TOTAL)[1]', 'nvarchar(50)'), '') IS NULL
        THEN (CASE WHEN NULLIF(@fx.value('(/factura/@TOTAL)[1]', 'nvarchar(50)'), '') IS NULL THEN 0 ELSE CAST(@fx.value('(/factura/@TOTAL)[1]', 'nvarchar(50)') AS DECIMAL(18,4)) END)
        ELSE CAST(@fx.value('(/presupuesto/@TOTAL)[1]', 'nvarchar(50)') AS DECIMAL(18,4)) END;

    IF @NumFact IS NULL OR LTRIM(RTRIM(@NumFact)) = ''
    BEGIN
        RAISERROR('missing_num_fact', 16, 1);
        RETURN;
    END

    IF @CxcTable NOT IN (N'P_Cobrar', N'P_CobrarC') SET @CxcTable = N'P_Cobrar';
    IF @FormaPagoTable NOT IN (N'Detalle_FormaPagoFacturas', N'Detalle_FormaPagoCotizacion') SET @FormaPagoTable = N'Detalle_FormaPagoCotizacion';

    BEGIN TRY
        IF @@TRANCOUNT = 0 BEGIN BEGIN TRAN; SET @StartedTran = 1; END
        ELSE SAVE TRANSACTION @SaveName;

        INSERT INTO dbo.Presupuestos (NUM_FACT, CODIGO, FECHA, FECHA_REPORTE, PAGO, TOTAL, COD_USUARIO, SERIALTIPO, Tipo_orden, OBSERV)
        VALUES (@NumFact, @Codigo, @Fecha, @FechaReporte, @Pago, @Total, @CodUsuario, @SerialTipo, @TipoOrden, @Observ);

        INSERT INTO dbo.Detalle_Presupuestos (NUM_FACT, SERIALTIPO, COD_SERV, CANTIDAD, PRECIO, ALICUOTA, TOTAL, PRECIO_DESCUENTO, Relacionada, Cod_Alterno)
        SELECT
            CASE WHEN NULLIF(T.X.value('@NUM_FACT', 'nvarchar(60)'), '') IS NULL THEN @NumFact ELSE T.X.value('@NUM_FACT', 'nvarchar(60)') END,
            CASE WHEN NULLIF(T.X.value('@SERIALTIPO', 'nvarchar(60)'), '') IS NULL THEN @SerialTipo ELSE T.X.value('@SERIALTIPO', 'nvarchar(60)') END,
            NULLIF(T.X.value('@COD_SERV', 'nvarchar(60)'), ''),
            CASE WHEN NULLIF(T.X.value('@CANTIDAD', 'nvarchar(50)'), '') IS NULL THEN 0 ELSE CAST(T.X.value('@CANTIDAD', 'nvarchar(50)') AS DECIMAL(18,4)) END,
            CASE WHEN NULLIF(T.X.value('@PRECIO', 'nvarchar(50)'), '') IS NULL THEN 0 ELSE CAST(T.X.value('@PRECIO', 'nvarchar(50)') AS DECIMAL(18,4)) END,
            CASE WHEN NULLIF(T.X.value('@ALICUOTA', 'nvarchar(50)'), '') IS NULL THEN 0 ELSE CAST(T.X.value('@ALICUOTA', 'nvarchar(50)') AS DECIMAL(18,4)) END,
            CASE WHEN NULLIF(T.X.value('@TOTAL', 'nvarchar(50)'), '') IS NULL
                 THEN (CASE WHEN NULLIF(T.X.value('@PRECIO', 'nvarchar(50)'), '') IS NULL THEN 0 ELSE CAST(T.X.value('@PRECIO', 'nvarchar(50)') AS DECIMAL(18,4)) END) * (CASE WHEN NULLIF(T.X.value('@CANTIDAD', 'nvarchar(50)'), '') IS NULL THEN 0 ELSE CAST(T.X.value('@CANTIDAD', 'nvarchar(50)') AS DECIMAL(18,4)) END)
                 ELSE CAST(T.X.value('@TOTAL', 'nvarchar(50)') AS DECIMAL(18,4)) END,
            CASE WHEN NULLIF(T.X.value('@PRECIO_DESCUENTO', 'nvarchar(50)'), '') IS NULL THEN CASE WHEN NULLIF(T.X.value('@PRECIO', 'nvarchar(50)'), '') IS NULL THEN 0 ELSE CAST(T.X.value('@PRECIO', 'nvarchar(50)') AS DECIMAL(18,4)) END ELSE CAST(T.X.value('@PRECIO_DESCUENTO', 'nvarchar(50)') AS DECIMAL(18,4)) END,
            CASE WHEN NULLIF(T.X.value('@RELACIONADA', 'nvarchar(10)'), '') IS NULL THEN 0 ELSE CAST(T.X.value('@RELACIONADA', 'nvarchar(10)') AS INT) END,
            NULLIF(T.X.value('@COD_ALTERNO', 'nvarchar(60)'), '')
        FROM @dx.nodes('/detalles/row') T(X);

        DECLARE @Memoria NVARCHAR(80) = @TipoOrden;
        DECLARE @MontoEfectivo DECIMAL(18,4) = 0, @MontoCheque DECIMAL(18,4) = 0, @MontoTarjeta DECIMAL(18,4) = 0, @SaldoPendiente DECIMAL(18,4) = 0;
        DECLARE @NumTarjeta NVARCHAR(60) = N'0', @Cta NVARCHAR(80) = N' ', @BancoCheque NVARCHAR(120) = N' ', @BancoTarjeta NVARCHAR(120) = N' ';

        IF @px IS NOT NULL
        BEGIN
            DECLARE @sqlForma NVARCHAR(MAX) = N'
                DELETE FROM dbo.' + QUOTENAME(@FormaPagoTable) + N' WHERE NUM_FACT = @pNumFact AND MEMORIA = @pMemoria AND SERIALFISCAL = @pSerial;
                INSERT INTO dbo.' + QUOTENAME(@FormaPagoTable) + N' (tasacambio, TIPO, NUM_FACT, MONTO, BANCO, CUENTA, FECHA_RETENCION, NUMERO, MEMORIA, SERIALFISCAL)
                SELECT
                    CASE WHEN NULLIF(N.X.value(''@tasacambio'', ''nvarchar(50)''), '''') IS NULL THEN 1 ELSE CAST(N.X.value(''@tasacambio'', ''nvarchar(50)'') AS DECIMAL(18,6)) END,
                    NULLIF(N.X.value(''@tipo'', ''nvarchar(60)''), ''''),
                    @pNumFact,
                    CASE WHEN NULLIF(N.X.value(''@monto'', ''nvarchar(50)''), '''') IS NULL THEN 0 ELSE CAST(N.X.value(''@monto'', ''nvarchar(50)'') AS DECIMAL(18,4)) END,
                    CASE WHEN NULLIF(N.X.value(''@banco'', ''nvarchar(120)''), '''') IS NULL THEN '' '' ELSE N.X.value(''@banco'', ''nvarchar(120)'') END,
                    CASE WHEN NULLIF(N.X.value(''@cuenta'', ''nvarchar(120)''), '''') IS NULL THEN '' '' ELSE N.X.value(''@cuenta'', ''nvarchar(120)'') END,
                    @pFecha,
                    CASE WHEN NULLIF(N.X.value(''@numero'', ''nvarchar(80)''), '''') IS NULL THEN ''0'' ELSE N.X.value(''@numero'', ''nvarchar(80)'') END,
                    @pMemoria, @pSerial
                FROM @pXml.nodes(''/formasPago/row'') N(X);';
            EXEC sp_executesql @sqlForma, N'@pNumFact nvarchar(60), @pMemoria nvarchar(80), @pSerial nvarchar(60), @pFecha datetime, @pXml xml',
                @pNumFact = @NumFact, @pMemoria = @Memoria, @pSerial = @SerialTipo, @pFecha = @Fecha, @pXml = @px;

            ;WITH FP AS (
                SELECT UPPER(CASE WHEN NULLIF(N.X.value('@tipo', 'nvarchar(60)'), '') IS NULL THEN '' ELSE N.X.value('@tipo', 'nvarchar(60)') END) AS Tipo,
                    CASE WHEN NULLIF(N.X.value('@monto', 'nvarchar(50)'), '') IS NULL THEN 0 ELSE CAST(N.X.value('@monto', 'nvarchar(50)') AS DECIMAL(18,4)) END AS Monto,
                    CASE WHEN NULLIF(N.X.value('@banco', 'nvarchar(120)'), '') IS NULL THEN ' ' ELSE N.X.value('@banco', 'nvarchar(120)') END AS Banco,
                    CASE WHEN NULLIF(N.X.value('@cuenta', 'nvarchar(120)'), '') IS NULL THEN ' ' ELSE N.X.value('@cuenta', 'nvarchar(120)') END AS Cuenta,
                    CASE WHEN NULLIF(N.X.value('@numero', 'nvarchar(80)'), '') IS NULL THEN '0' ELSE N.X.value('@numero', 'nvarchar(80)') END AS Numero
                FROM @px.nodes('/formasPago/row') N(X))
            SELECT @MontoEfectivo = ISNULL(SUM(CASE WHEN Tipo = 'EFECTIVO' THEN Monto ELSE 0 END), 0),
                @MontoCheque = ISNULL(SUM(CASE WHEN Tipo = 'CHEQUE' THEN Monto ELSE 0 END), 0),
                @MontoTarjeta = ISNULL(SUM(CASE WHEN Tipo LIKE 'TARJETA%' OR Tipo LIKE 'TICKET%' THEN Monto ELSE 0 END), 0),
                @SaldoPendiente = ISNULL(SUM(CASE WHEN Tipo = 'SALDO PENDIENTE' THEN Monto ELSE 0 END), 0),
                @Cta = ISNULL(MAX(CASE WHEN Tipo = 'CHEQUE' THEN Cuenta END), @Cta),
                @BancoCheque = ISNULL(MAX(CASE WHEN Tipo = 'CHEQUE' THEN Banco END), @BancoCheque),
                @BancoTarjeta = ISNULL(MAX(CASE WHEN Tipo LIKE 'TARJETA%' OR Tipo LIKE 'TICKET%' THEN Banco END), @BancoTarjeta),
                @NumTarjeta = ISNULL(MAX(CASE WHEN Tipo LIKE 'TARJETA%' OR Tipo LIKE 'TICKET%' THEN Numero END), @NumTarjeta)
            FROM FP;

            INSERT INTO dbo.DETALLE_DEPOSITO (TOTAL, CHEQUE, CTA_BANCO, CLIENTE, RELACIONADA, BANCO)
            SELECT FP.Monto, FP.Numero, FP.Cuenta, @Codigo, 0, FP.Banco
            FROM (SELECT UPPER(CASE WHEN NULLIF(N.X.value('@tipo', 'nvarchar(60)'), '') IS NULL THEN '' ELSE N.X.value('@tipo', 'nvarchar(60)') END) AS Tipo,
                CASE WHEN NULLIF(N.X.value('@monto', 'nvarchar(50)'), '') IS NULL THEN 0 ELSE CAST(N.X.value('@monto', 'nvarchar(50)') AS DECIMAL(18,4)) END AS Monto,
                CASE WHEN NULLIF(N.X.value('@banco', 'nvarchar(120)'), '') IS NULL THEN ' ' ELSE N.X.value('@banco', 'nvarchar(120)') END AS Banco,
                CASE WHEN NULLIF(N.X.value('@cuenta', 'nvarchar(120)'), '') IS NULL THEN ' ' ELSE N.X.value('@cuenta', 'nvarchar(120)') END AS Cuenta,
                CASE WHEN NULLIF(N.X.value('@numero', 'nvarchar(80)'), '') IS NULL THEN '0' ELSE N.X.value('@numero', 'nvarchar(80)') END AS Numero
                FROM @px.nodes('/formasPago/row') N(X)) FP
            WHERE FP.Tipo = 'CHEQUE';
        END

        DECLARE @Abono DECIMAL(18,4) = @Total - @SaldoPendiente;
        DECLARE @Cancelada CHAR(1) = CASE WHEN @SaldoPendiente > 0 THEN 'N' ELSE 'S' END;

        UPDATE dbo.Presupuestos
        SET Monto_Efect = @MontoEfectivo, Monto_Cheque = @MontoCheque, Monto_Tarjeta = @MontoTarjeta,
            Abono = @Abono, Saldo = @SaldoPendiente, Tarjeta = @NumTarjeta, Cta = @Cta,
            BANCO_CHEQUE = @BancoCheque, Banco_Tarjeta = @BancoTarjeta,
            CANCELADA = @Cancelada, FECHA_REPORTE = @FechaReporte
        WHERE NUM_FACT = @NumFact;

        IF @GenerarCxC = 1 AND (@Pago = 'CREDITO' OR @SaldoPendiente > 0)
        BEGIN
            DECLARE @SaldoPrevio DECIMAL(18,4) = 0;
            DECLARE @sqlCxc NVARCHAR(MAX) = N'
                DELETE FROM dbo.' + QUOTENAME(@CxcTable) + N' WHERE CODIGO = @codigo AND DOCUMENTO = @numFact AND TIPO = ''PRESUP'';
                SELECT TOP 1 @saldoPrevioOut = ISNULL(SALDO, 0) FROM dbo.' + QUOTENAME(@CxcTable) + N' WHERE CODIGO = @codigo ORDER BY FECHA DESC;
                INSERT INTO dbo.' + QUOTENAME(@CxcTable) + N' (CODIGO, COD_USUARIO, FECHA, DOCUMENTO, DEBE, PEND, SALDO, TIPO, SERIALTIPO, Tipo_Orden)
                VALUES (@codigo, @codUsuario, @fecha, @numFact, @debe, @pend, ISNULL(@saldoPrevioOut,0) + @pend, ''PRESUP'', @serialTipo, @tipoOrden);';
            EXEC sp_executesql @sqlCxc, N'@codigo nvarchar(60), @numFact nvarchar(60), @codUsuario nvarchar(60), @fecha datetime, @debe decimal(18,4), @pend decimal(18,4), @saldoPrevioOut decimal(18,4) OUTPUT, @serialTipo nvarchar(60), @tipoOrden nvarchar(80)',
                @codigo = @Codigo, @numFact = @NumFact, @codUsuario = @CodUsuario, @fecha = @Fecha, @debe = @SaldoPendiente, @pend = @SaldoPendiente, @saldoPrevioOut = @SaldoPrevio OUTPUT, @serialTipo = @SerialTipo, @tipoOrden = @TipoOrden;
        END

        IF @ActualizarInventario = 1
        BEGIN
            INSERT INTO dbo.MovInvent (CODIGO, PRODUCT, DOCUMENTO, FECHA, MOTIVO, TIPO, CANTIDAD_ACTUAL, CANTIDAD, CANTIDAD_NUEVA, CO_USUARIO, PRECIO_COMPRA, ALICUOTA, PRECIO_VENTA)
            SELECT D.COD_SERV, D.COD_SERV, @NumFact, @Fecha, 'Presup:' + @NumFact, 'Egreso',
                ISNULL(I.EXISTENCIA, 0), D.CANTIDAD, ISNULL(I.EXISTENCIA, 0) - D.CANTIDAD, @CodUsuario, ISNULL(I.COSTO_REFERENCIA, 0), D.ALICUOTA, D.PRECIO
            FROM (SELECT NULLIF(X.value('@COD_SERV', 'nvarchar(60)'), '') AS COD_SERV,
                CASE WHEN NULLIF(X.value('@CANTIDAD', 'nvarchar(50)'), '') IS NULL THEN 0 ELSE CAST(X.value('@CANTIDAD', 'nvarchar(50)') AS DECIMAL(18,4)) END AS CANTIDAD,
                CASE WHEN NULLIF(X.value('@PRECIO', 'nvarchar(50)'), '') IS NULL THEN 0 ELSE CAST(X.value('@PRECIO', 'nvarchar(50)') AS DECIMAL(18,4)) END AS PRECIO,
                CASE WHEN NULLIF(X.value('@ALICUOTA', 'nvarchar(50)'), '') IS NULL THEN 0 ELSE CAST(X.value('@ALICUOTA', 'nvarchar(50)') AS DECIMAL(18,4)) END AS ALICUOTA
                FROM @dx.nodes('/detalles/row') N(X)) D
            INNER JOIN dbo.Inventario I ON I.CODIGO = D.COD_SERV WHERE D.COD_SERV IS NOT NULL AND D.CANTIDAD > 0;

            ;WITH RawD AS (SELECT NULLIF(N.X.value('@COD_SERV', 'nvarchar(60)'), '') AS COD_SERV,
                CASE WHEN NULLIF(N.X.value('@CANTIDAD', 'nvarchar(50)'), '') IS NULL THEN 0 ELSE CAST(N.X.value('@CANTIDAD', 'nvarchar(50)') AS DECIMAL(18,4)) END AS CANTIDAD FROM @dx.nodes('/detalles/row') N(X)),
            X AS (SELECT COD_SERV, SUM(CANTIDAD) AS TOTAL FROM RawD GROUP BY COD_SERV)
            UPDATE I SET I.EXISTENCIA = ISNULL(I.EXISTENCIA, 0) - X.TOTAL FROM dbo.Inventario I INNER JOIN X ON X.COD_SERV = I.CODIGO;

            ;WITH RawA AS (SELECT NULLIF(N.X.value('@COD_ALTERNO', 'nvarchar(60)'), '') AS COD_ALTERNO,
                CASE WHEN NULLIF(N.X.value('@CANTIDAD', 'nvarchar(50)'), '') IS NULL THEN 0 ELSE CAST(N.X.value('@CANTIDAD', 'nvarchar(50)') AS DECIMAL(18,4)) END AS CANTIDAD,
                CASE WHEN NULLIF(N.X.value('@RELACIONADA', 'nvarchar(10)'), '') IS NULL THEN 0 ELSE CAST(N.X.value('@RELACIONADA', 'nvarchar(10)') AS INT) END AS RELACIONADA FROM @dx.nodes('/detalles/row') N(X)),
            X AS (SELECT COD_ALTERNO, SUM(CANTIDAD) AS TOTAL FROM RawA WHERE RELACIONADA = 1 GROUP BY COD_ALTERNO)
            UPDATE IA SET IA.CANTIDAD = ISNULL(IA.CANTIDAD, 0) - X.TOTAL FROM dbo.Inventario_Aux IA INNER JOIN X ON X.COD_ALTERNO = IA.CODIGO;
        END

        IF @ActualizarSaldosCliente = 1 AND @Codigo IS NOT NULL AND LTRIM(RTRIM(@Codigo)) <> ''
        BEGIN
            DECLARE @sqlSaldo NVARCHAR(MAX);
            IF @CxcTable = N'P_CobrarC'
                SET @sqlSaldo = N';WITH A AS (SELECT ISNULL(SUM(CASE WHEN TIPO = ''PRESUP'' THEN PEND ELSE 0 END), 0) AS SALDO_TOT,
                    ISNULL(SUM(CASE WHEN TIPO = ''PRESUP'' AND DATEDIFF(DAY, FECHA, GETDATE()) <= 30 THEN PEND ELSE 0 END), 0) AS SALDO_30,
                    ISNULL(SUM(CASE WHEN TIPO = ''PRESUP'' AND DATEDIFF(DAY, FECHA, GETDATE()) > 30 AND DATEDIFF(DAY, FECHA, GETDATE()) <= 60 THEN PEND ELSE 0 END), 0) AS SALDO_60,
                    ISNULL(SUM(CASE WHEN TIPO = ''PRESUP'' AND DATEDIFF(DAY, FECHA, GETDATE()) > 60 AND DATEDIFF(DAY, FECHA, GETDATE()) <= 90 THEN PEND ELSE 0 END), 0) AS SALDO_90,
                    ISNULL(SUM(CASE WHEN TIPO = ''PRESUP'' AND DATEDIFF(DAY, FECHA, GETDATE()) > 90 THEN PEND ELSE 0 END), 0) AS SALDO_91 FROM dbo.P_CobrarC WHERE CODIGO = @codigo)
                    UPDATE C SET SALDO_TOTC = A.SALDO_TOT, SALDO_30C = A.SALDO_30, SALDO_60C = A.SALDO_60, SALDO_90C = A.SALDO_90, SALDO_91C = A.SALDO_91 FROM dbo.Clientes C CROSS JOIN A WHERE C.CODIGO = @codigo;';
            ELSE
                SET @sqlSaldo = N';WITH A AS (SELECT ISNULL(SUM(CASE WHEN TIPO = ''PRESUP'' THEN PEND ELSE 0 END), 0) AS SALDO_TOT,
                    ISNULL(SUM(CASE WHEN TIPO = ''PRESUP'' AND DATEDIFF(DAY, FECHA, GETDATE()) <= 30 THEN PEND ELSE 0 END), 0) AS SALDO_30,
                    ISNULL(SUM(CASE WHEN TIPO = ''PRESUP'' AND DATEDIFF(DAY, FECHA, GETDATE()) > 30 AND DATEDIFF(DAY, FECHA, GETDATE()) <= 60 THEN PEND ELSE 0 END), 0) AS SALDO_60,
                    ISNULL(SUM(CASE WHEN TIPO = ''PRESUP'' AND DATEDIFF(DAY, FECHA, GETDATE()) > 60 AND DATEDIFF(DAY, FECHA, GETDATE()) <= 90 THEN PEND ELSE 0 END), 0) AS SALDO_90,
                    ISNULL(SUM(CASE WHEN TIPO = ''PRESUP'' AND DATEDIFF(DAY, FECHA, GETDATE()) > 90 THEN PEND ELSE 0 END), 0) AS SALDO_91 FROM dbo.P_Cobrar WHERE CODIGO = @codigo)
                    UPDATE C SET SALDO_TOT = A.SALDO_TOT, SALDO_30 = A.SALDO_30, SALDO_60 = A.SALDO_60, SALDO_90 = A.SALDO_90, SALDO_91 = A.SALDO_91 FROM dbo.Clientes C CROSS JOIN A WHERE C.CODIGO = @codigo;';
            EXEC sp_executesql @sqlSaldo, N'@codigo nvarchar(60)', @codigo = @Codigo;
        END

        IF @StartedTran = 1 AND XACT_STATE() = 1 COMMIT TRAN;

        SELECT CAST(1 AS BIT) AS ok, @NumFact AS numFact, (SELECT COUNT(1) FROM @dx.nodes('/detalles/row') D(X)) AS detalleRows,
            @MontoEfectivo AS montoEfectivo, @MontoCheque AS montoCheque, @MontoTarjeta AS montoTarjeta, @SaldoPendiente AS saldoPendiente, @Abono AS abono;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 BEGIN
            IF @StartedTran = 1 ROLLBACK TRAN;
            ELSE ROLLBACK TRANSACTION @SaveName;
        END
        DECLARE @Err NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@Err, 16, 1);
    END CATCH
END
GO

SELECT name, create_date FROM sys.objects WHERE type = 'P' AND name = 'sp_emitir_presupuesto_tx';
