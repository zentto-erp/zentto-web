-- =============================================
-- Stored Procedure: Emitir Presupuesto (100% canónico)
-- Tablas: ar.SalesDocument, ar.SalesDocumentLine, ar.SalesDocumentPayment
-- CxC: ar.ReceivableDocument
-- Inventario: master.Product, master.InventoryMovement, master.AlternateStock
-- Depósitos: acct.BankDeposit
-- Clientes: master.Customer
-- OperationType: PRESUP
-- Compatible con: SQL Server 2012+
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

    -- Parsear cabecera (soporta nodos <presupuesto> y <factura> por compat)
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
    SET @SerialTipo = ISNULL(NULLIF(@fx.value('(/presupuesto/@SERIALTIPO)[1]', 'nvarchar(60)'), ''), '');
    IF @SerialTipo = '' SET @SerialTipo = ISNULL(NULLIF(@fx.value('(/factura/@SERIALTIPO)[1]', 'nvarchar(60)'), ''), '');
    SET @TipoOrden = ISNULL(NULLIF(@fx.value('(/presupuesto/@Tipo_orden)[1]', 'nvarchar(80)'), ''), '');
    IF @TipoOrden = '' SET @TipoOrden = ISNULL(NULLIF(@fx.value('(/presupuesto/@TIPO_ORDEN)[1]', 'nvarchar(80)'), ''), '');
    IF @TipoOrden = '' SET @TipoOrden = ISNULL(NULLIF(@fx.value('(/factura/@TIPO_ORDEN)[1]', 'nvarchar(80)'), ''), '1');
    SET @Observ = NULLIF(@fx.value('(/presupuesto/@OBSERV)[1]', 'nvarchar(4000)'), '');
    IF @Observ IS NULL SET @Observ = NULLIF(@fx.value('(/factura/@OBSERV)[1]', 'nvarchar(4000)'), '');
    SET @FechaStr = NULLIF(@fx.value('(/presupuesto/@FECHA)[1]', 'nvarchar(50)'), '');
    IF @FechaStr IS NULL SET @FechaStr = NULLIF(@fx.value('(/factura/@FECHA)[1]', 'nvarchar(50)'), '');
    SET @FechaReporteStr = NULLIF(@fx.value('(/presupuesto/@FECHA_REPORTE)[1]', 'nvarchar(50)'), '');
    IF @FechaReporteStr IS NULL SET @FechaReporteStr = NULLIF(@fx.value('(/factura/@FECHA_REPORTE)[1]', 'nvarchar(50)'), '');
    SET @Fecha = CASE WHEN ISDATE(@FechaStr) = 1 THEN CAST(@FechaStr AS DATETIME) ELSE SYSUTCDATETIME() END;
    SET @FechaReporte = CASE WHEN ISDATE(@FechaReporteStr) = 1 THEN CAST(@FechaReporteStr AS DATETIME) ELSE @Fecha END;
    SET @Total = CASE WHEN NULLIF(@fx.value('(/presupuesto/@TOTAL)[1]', 'nvarchar(50)'), '') IS NULL
        THEN (CASE WHEN NULLIF(@fx.value('(/factura/@TOTAL)[1]', 'nvarchar(50)'), '') IS NULL THEN 0 ELSE CAST(@fx.value('(/factura/@TOTAL)[1]', 'nvarchar(50)') AS DECIMAL(18,4)) END)
        ELSE CAST(@fx.value('(/presupuesto/@TOTAL)[1]', 'nvarchar(50)') AS DECIMAL(18,4)) END;

    IF @NumFact IS NULL OR LTRIM(RTRIM(@NumFact)) = ''
    BEGIN RAISERROR('missing_num_fact', 16, 1); RETURN; END

    -- Resolver IDs canónicos
    DECLARE @DefaultCompanyId INT = 1, @DefaultBranchId INT = 1, @CustomerId BIGINT;
    SELECT TOP 1 @DefaultCompanyId = CompanyId FROM cfg.Company WHERE CompanyCode = N'DEFAULT';
    SELECT TOP 1 @DefaultBranchId = BranchId FROM cfg.Branch WHERE CompanyId = @DefaultCompanyId AND BranchCode = N'MAIN';
    IF @Codigo IS NOT NULL
        SELECT TOP 1 @CustomerId = CustomerId FROM master.Customer WHERE CustomerCode = @Codigo AND ISNULL(IsDeleted, 0) = 0;

    BEGIN TRY
        IF @@TRANCOUNT = 0 BEGIN BEGIN TRAN; SET @StartedTran = 1; END
        ELSE SAVE TRANSACTION @SaveName;

        -- 1. Cabecera → ar.SalesDocument (OperationType='PRESUP')
        INSERT INTO ar.SalesDocument (
            DocumentNumber, SerialType, FiscalMemoryNumber, OperationType,
            CustomerCode, DocumentDate, ReportDate, PaymentTerms,
            TotalAmount, UserCode, Notes
        )
        VALUES (
            @NumFact, @SerialTipo, @TipoOrden, 'PRESUP',
            @Codigo, @Fecha, @FechaReporte, @Pago,
            @Total, @CodUsuario, @Observ
        );

        -- 2. Detalle → ar.SalesDocumentLine
        INSERT INTO ar.SalesDocumentLine (
            DocumentNumber, SerialType, FiscalMemoryNumber, OperationType,
            ProductCode, Quantity, UnitPrice, TaxRate, TotalAmount,
            DiscountedPrice, RelatedRef, AlternateCode
        )
        SELECT
            CASE WHEN NULLIF(T.X.value('@NUM_FACT', 'nvarchar(60)'), '') IS NULL THEN @NumFact ELSE T.X.value('@NUM_FACT', 'nvarchar(60)') END,
            CASE WHEN NULLIF(T.X.value('@SERIALTIPO', 'nvarchar(60)'), '') IS NULL THEN @SerialTipo ELSE T.X.value('@SERIALTIPO', 'nvarchar(60)') END,
            @TipoOrden, 'PRESUP',
            NULLIF(T.X.value('@COD_SERV', 'nvarchar(60)'), ''),
            CASE WHEN NULLIF(T.X.value('@CANTIDAD', 'nvarchar(50)'), '') IS NULL THEN 0 ELSE CAST(T.X.value('@CANTIDAD', 'nvarchar(50)') AS DECIMAL(18,4)) END,
            CASE WHEN NULLIF(T.X.value('@PRECIO', 'nvarchar(50)'), '') IS NULL THEN 0 ELSE CAST(T.X.value('@PRECIO', 'nvarchar(50)') AS DECIMAL(18,4)) END,
            CASE WHEN NULLIF(T.X.value('@ALICUOTA', 'nvarchar(50)'), '') IS NULL THEN 0 ELSE CAST(T.X.value('@ALICUOTA', 'nvarchar(50)') AS DECIMAL(18,4)) END,
            CASE WHEN NULLIF(T.X.value('@TOTAL', 'nvarchar(50)'), '') IS NULL
                 THEN (CASE WHEN NULLIF(T.X.value('@PRECIO', 'nvarchar(50)'), '') IS NULL THEN 0 ELSE CAST(T.X.value('@PRECIO', 'nvarchar(50)') AS DECIMAL(18,4)) END) * (CASE WHEN NULLIF(T.X.value('@CANTIDAD', 'nvarchar(50)'), '') IS NULL THEN 0 ELSE CAST(T.X.value('@CANTIDAD', 'nvarchar(50)') AS DECIMAL(18,4)) END)
                 ELSE CAST(T.X.value('@TOTAL', 'nvarchar(50)') AS DECIMAL(18,4)) END,
            CASE WHEN NULLIF(T.X.value('@PRECIO_DESCUENTO', 'nvarchar(50)'), '') IS NULL THEN CASE WHEN NULLIF(T.X.value('@PRECIO', 'nvarchar(50)'), '') IS NULL THEN 0 ELSE CAST(T.X.value('@PRECIO', 'nvarchar(50)') AS DECIMAL(18,4)) END ELSE CAST(T.X.value('@PRECIO_DESCUENTO', 'nvarchar(50)') AS DECIMAL(18,4)) END,
            CASE WHEN NULLIF(T.X.value('@RELACIONADA', 'nvarchar(10)'), '') IS NULL THEN '0' ELSE T.X.value('@RELACIONADA', 'nvarchar(10)') END,
            NULLIF(T.X.value('@COD_ALTERNO', 'nvarchar(60)'), '')
        FROM @dx.nodes('/detalles/row') T(X);

        -- 3. Formas de pago
        DECLARE @Memoria NVARCHAR(80) = @TipoOrden;
        DECLARE @MontoEfectivo DECIMAL(18,4) = 0, @MontoCheque DECIMAL(18,4) = 0;
        DECLARE @MontoTarjeta DECIMAL(18,4) = 0, @SaldoPendiente DECIMAL(18,4) = 0;
        DECLARE @NumTarjeta NVARCHAR(60) = N'0', @Cta NVARCHAR(80) = N' ';
        DECLARE @BancoCheque NVARCHAR(120) = N' ', @BancoTarjeta NVARCHAR(120) = N' ';

        IF @px IS NOT NULL
        BEGIN
            DELETE FROM ar.SalesDocumentPayment
             WHERE DocumentNumber = @NumFact AND FiscalMemoryNumber = @Memoria
               AND SerialType = @SerialTipo AND OperationType = 'PRESUP';

            INSERT INTO ar.SalesDocumentPayment (
                ExchangeRate, PaymentMethod, DocumentNumber, Amount,
                BankCode, ReferenceNumber, PaymentDate, PaymentNumber,
                FiscalMemoryNumber, SerialType, OperationType
            )
            SELECT
                CASE WHEN NULLIF(N.X.value('@tasacambio', 'nvarchar(50)'), '') IS NULL THEN 1 ELSE CAST(N.X.value('@tasacambio', 'nvarchar(50)') AS DECIMAL(18,6)) END,
                NULLIF(N.X.value('@tipo', 'nvarchar(60)'), ''), @NumFact,
                CASE WHEN NULLIF(N.X.value('@monto', 'nvarchar(50)'), '') IS NULL THEN 0 ELSE CAST(N.X.value('@monto', 'nvarchar(50)') AS DECIMAL(18,4)) END,
                CASE WHEN NULLIF(N.X.value('@banco', 'nvarchar(120)'), '') IS NULL THEN ' ' ELSE N.X.value('@banco', 'nvarchar(120)') END,
                CASE WHEN NULLIF(N.X.value('@cuenta', 'nvarchar(120)'), '') IS NULL THEN ' ' ELSE N.X.value('@cuenta', 'nvarchar(120)') END,
                @Fecha,
                CASE WHEN NULLIF(N.X.value('@numero', 'nvarchar(80)'), '') IS NULL THEN '0' ELSE N.X.value('@numero', 'nvarchar(80)') END,
                @Memoria, @SerialTipo, 'PRESUP'
            FROM @px.nodes('/formasPago/row') N(X);

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

            -- Depósitos cheque → acct.BankDeposit
            INSERT INTO acct.BankDeposit (Amount, CheckNumber, BankAccount, CustomerCode, IsRelated, BankName, DocumentRef, OperationType)
            SELECT FP.Monto, FP.Numero, FP.Cuenta, @Codigo, 0, FP.Banco, @NumFact, 'PRESUP'
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

        UPDATE ar.SalesDocument
           SET IsPaid = @Cancelada, ReportDate = @FechaReporte, UpdatedAt = SYSUTCDATETIME()
         WHERE DocumentNumber = @NumFact AND OperationType = 'PRESUP';

        -- 4. CxC → ar.ReceivableDocument
        IF @GenerarCxC = 1 AND @CustomerId IS NOT NULL AND (@Pago = 'CREDITO' OR @SaldoPendiente > 0)
        BEGIN
            DELETE FROM ar.ReceivableDocument
             WHERE CompanyId = @DefaultCompanyId AND BranchId = @DefaultBranchId
               AND DocumentType = 'PRESUP' AND DocumentNumber = @NumFact;

            INSERT INTO ar.ReceivableDocument (
                CompanyId, BranchId, CustomerId, DocumentType, DocumentNumber,
                IssueDate, CurrencyCode, TotalAmount, PendingAmount, PaidFlag, Status
            )
            VALUES (
                @DefaultCompanyId, @DefaultBranchId, @CustomerId, 'PRESUP', @NumFact,
                CAST(@Fecha AS DATE), 'VES', @SaldoPendiente, @SaldoPendiente, 0, 'PENDING'
            );
        END

        -- 5. Inventario → master.Product + master.InventoryMovement
        IF @ActualizarInventario = 1
        BEGIN
            INSERT INTO master.InventoryMovement (CompanyId, ProductCode, DocumentRef, MovementType, MovementDate, Quantity, UnitCost, TotalCost, Notes)
            SELECT @DefaultCompanyId, D.COD_SERV, @NumFact, 'SALIDA', CAST(@Fecha AS DATE),
                D.CANTIDAD, ISNULL(I.COSTO_REFERENCIA, 0), D.CANTIDAD * ISNULL(I.COSTO_REFERENCIA, 0),
                'Presup:' + @NumFact
            FROM (SELECT NULLIF(X.value('@COD_SERV', 'nvarchar(60)'), '') AS COD_SERV,
                CASE WHEN NULLIF(X.value('@CANTIDAD', 'nvarchar(50)'), '') IS NULL THEN 0 ELSE CAST(X.value('@CANTIDAD', 'nvarchar(50)') AS DECIMAL(18,4)) END AS CANTIDAD
                FROM @dx.nodes('/detalles/row') N(X)) D
            INNER JOIN master.Product I ON I.ProductCode = D.COD_SERV WHERE D.COD_SERV IS NOT NULL AND D.CANTIDAD > 0;

            ;WITH RawD AS (SELECT NULLIF(N.X.value('@COD_SERV', 'nvarchar(60)'), '') AS COD_SERV,
                CASE WHEN NULLIF(N.X.value('@CANTIDAD', 'nvarchar(50)'), '') IS NULL THEN 0 ELSE CAST(N.X.value('@CANTIDAD', 'nvarchar(50)') AS DECIMAL(18,4)) END AS CANTIDAD FROM @dx.nodes('/detalles/row') N(X)),
            X AS (SELECT COD_SERV, SUM(CANTIDAD) AS TOTAL FROM RawD GROUP BY COD_SERV)
            UPDATE I SET I.StockQty = ISNULL(I.StockQty, 0) - X.TOTAL FROM master.Product I INNER JOIN X ON X.COD_SERV = I.ProductCode;

            ;WITH RawA AS (SELECT NULLIF(N.X.value('@COD_ALTERNO', 'nvarchar(60)'), '') AS COD_ALTERNO,
                CASE WHEN NULLIF(N.X.value('@CANTIDAD', 'nvarchar(50)'), '') IS NULL THEN 0 ELSE CAST(N.X.value('@CANTIDAD', 'nvarchar(50)') AS DECIMAL(18,4)) END AS CANTIDAD,
                CASE WHEN NULLIF(N.X.value('@RELACIONADA', 'nvarchar(10)'), '') IS NULL THEN 0 ELSE CAST(N.X.value('@RELACIONADA', 'nvarchar(10)') AS INT) END AS RELACIONADA FROM @dx.nodes('/detalles/row') N(X)),
            X AS (SELECT COD_ALTERNO, SUM(CANTIDAD) AS TOTAL FROM RawA WHERE RELACIONADA = 1 GROUP BY COD_ALTERNO)
            UPDATE A SET A.StockQty = ISNULL(A.StockQty, 0) - X.TOTAL FROM master.AlternateStock A INNER JOIN X ON X.COD_ALTERNO = A.ProductCode;
        END

        -- 6. Saldos → master.Customer.TotalBalance
        IF @ActualizarSaldosCliente = 1 AND @CustomerId IS NOT NULL
        BEGIN
            UPDATE master.Customer
               SET TotalBalance = ISNULL((
                   SELECT SUM(PendingAmount) FROM ar.ReceivableDocument
                   WHERE CustomerId = @CustomerId AND Status <> 'VOIDED' AND PaidFlag = 0
               ), 0)
             WHERE CustomerId = @CustomerId AND ISNULL(IsDeleted, 0) = 0;
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
