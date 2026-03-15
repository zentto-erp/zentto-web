USE DatqBoxWeb;
GO

-- #############################################################################
-- usp_xml_compat.sql
-- Stored procedures reescritos para compatibilidad SQL Server 2012.
-- Reemplaza OPENJSON / JSON_VALUE (SQL 2016+) por XML XQuery (.nodes/.value).
-- Formato XML esperado:
--   Objeto unico : <row Key1="val1" Key2="val2" />
--   Array         : <root><row K1="v1"/><row K1="v2"/></root>
-- #############################################################################

-- =============================================================================
-- SP 1: usp_Doc_PurchaseDocument_Upsert (SQL 2012 compatible - XML)
-- Crea o reemplaza un documento de compra completo (cabecera + detalle + pagos).
-- Para tipo COMPRA sincroniza ap.PayableDocument y recalcula saldo proveedor.
-- =============================================================================
IF OBJECT_ID('dbo.usp_Doc_PurchaseDocument_Upsert', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_Doc_PurchaseDocument_Upsert;
GO
CREATE PROCEDURE dbo.usp_Doc_PurchaseDocument_Upsert
    @TipoOperacion  NVARCHAR(20),
    @HeaderXml      NVARCHAR(MAX),
    @DetailXml      NVARCHAR(MAX),
    @PaymentsXml    NVARCHAR(MAX) = NULL,
    @DocOrigen      NVARCHAR(60)  = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @ok             BIT           = 0;
    DECLARE @numDoc         NVARCHAR(60);
    DECLARE @detalleRows    INT           = 0;
    DECLARE @formasPagoRows INT           = 0;
    DECLARE @pendingAmount  FLOAT         = 0;

    -- Parse XML
    DECLARE @hXml XML = CAST(@HeaderXml AS XML);

    -- Get document number from header
    SET @numDoc = LTRIM(RTRIM(@hXml.value('(/row/@DocumentNumber)[1]', 'NVARCHAR(60)')));

    IF @numDoc IS NULL OR @numDoc = ''
    BEGIN
        SELECT @ok AS ok, @numDoc AS numDoc, @detalleRows AS detalleRows,
               @formasPagoRows AS formasPagoRows, @pendingAmount AS pendingAmount,
               'Numero de documento requerido (DocumentNumber)' AS mensaje;
        RETURN;
    END;

    BEGIN TRAN;

        -- 1. Delete existing (idempotent)
        DELETE FROM doc.PurchaseDocumentPayment WHERE DocumentNumber = @numDoc AND DocumentType = @TipoOperacion;
        DELETE FROM doc.PurchaseDocumentLine WHERE DocumentNumber = @numDoc AND DocumentType = @TipoOperacion;
        DELETE FROM doc.PurchaseDocument WHERE DocumentNumber = @numDoc AND DocumentType = @TipoOperacion;

        -- 2. INSERT header from XML
        INSERT INTO doc.PurchaseDocument (
            DocumentNumber, SerialType, DocumentType,
            SupplierCode, SupplierName, FiscalId,
            IssueDate, DueDate, ReceiptDate, PaymentDate, DocumentTime,
            SubTotal, TaxableAmount, ExemptAmount, TaxAmount, TaxRate,
            TotalAmount, DiscountAmount,
            IsVoided, IsPaid, IsReceived, IsLegal,
            OriginDocumentNumber, ControlNumber,
            VoucherNumber, VoucherDate, RetainedTax,
            IsrCode, IsrAmount, IsrSubjectCode, IsrSubjectAmount, RetentionRate,
            ImportAmount, ImportTax, ImportBase, FreightAmount,
            Notes, Concept, OrderNumber, ReceivedBy, WarehouseCode,
            CurrencyCode, ExchangeRate, UsdAmount,
            UserCode, ShortUserCode, ReportDate, HostName,
            CreatedAt, UpdatedAt
        )
        VALUES (
            @numDoc,
            ISNULL(@hXml.value('(/row/@SerialType)[1]', 'NVARCHAR(60)'), ''),
            @TipoOperacion,
            @hXml.value('(/row/@SupplierCode)[1]', 'NVARCHAR(60)'),
            @hXml.value('(/row/@SupplierName)[1]', 'NVARCHAR(255)'),
            @hXml.value('(/row/@FiscalId)[1]', 'NVARCHAR(15)'),
            ISNULL(TRY_CAST(@hXml.value('(/row/@IssueDate)[1]', 'NVARCHAR(50)') AS DATETIME), SYSUTCDATETIME()),
            TRY_CAST(@hXml.value('(/row/@DueDate)[1]', 'NVARCHAR(50)') AS DATETIME),
            TRY_CAST(@hXml.value('(/row/@ReceiptDate)[1]', 'NVARCHAR(50)') AS DATETIME),
            TRY_CAST(@hXml.value('(/row/@PaymentDate)[1]', 'NVARCHAR(50)') AS DATETIME),
            ISNULL(@hXml.value('(/row/@DocumentTime)[1]', 'NVARCHAR(20)'), CONVERT(NVARCHAR(8), SYSUTCDATETIME(), 108)),
            ISNULL(@hXml.value('(/row/@SubTotal)[1]', 'FLOAT'), 0),
            ISNULL(@hXml.value('(/row/@TaxableAmount)[1]', 'FLOAT'), 0),
            ISNULL(@hXml.value('(/row/@ExemptAmount)[1]', 'FLOAT'), 0),
            ISNULL(@hXml.value('(/row/@TaxAmount)[1]', 'FLOAT'), 0),
            ISNULL(@hXml.value('(/row/@TaxRate)[1]', 'FLOAT'), 0),
            ISNULL(@hXml.value('(/row/@TotalAmount)[1]', 'FLOAT'), 0),
            ISNULL(@hXml.value('(/row/@DiscountAmount)[1]', 'FLOAT'), 0),
            ISNULL(@hXml.value('(/row/@IsVoided)[1]', 'BIT'), 0),
            ISNULL(@hXml.value('(/row/@IsPaid)[1]', 'NVARCHAR(1)'), 'N'),
            ISNULL(@hXml.value('(/row/@IsReceived)[1]', 'NVARCHAR(1)'), 'N'),
            ISNULL(@hXml.value('(/row/@IsLegal)[1]', 'BIT'), 0),
            COALESCE(@DocOrigen, @hXml.value('(/row/@OriginDocumentNumber)[1]', 'NVARCHAR(60)')),
            @hXml.value('(/row/@ControlNumber)[1]', 'NVARCHAR(60)'),
            @hXml.value('(/row/@WithholdingCertNumber)[1]', 'NVARCHAR(50)'),
            TRY_CAST(@hXml.value('(/row/@WithholdingCertDate)[1]', 'NVARCHAR(50)') AS DATETIME),
            ISNULL(@hXml.value('(/row/@WithheldTaxAmount)[1]', 'FLOAT'), 0),
            @hXml.value('(/row/@IncomeTaxCode)[1]', 'NVARCHAR(50)'),
            ISNULL(@hXml.value('(/row/@IncomeTaxAmount)[1]', 'FLOAT'), 0),
            @hXml.value('(/row/@IncomeTaxPercent)[1]', 'NVARCHAR(50)'),
            ISNULL(@hXml.value('(/row/@IsSubjectToIncomeTax)[1]', 'FLOAT'), 0),
            ISNULL(@hXml.value('(/row/@WithholdingRate)[1]', 'FLOAT'), 0),
            ISNULL(@hXml.value('(/row/@IsImport)[1]', 'FLOAT'), 0),
            ISNULL(@hXml.value('(/row/@ImportTaxAmount)[1]', 'FLOAT'), 0),
            ISNULL(@hXml.value('(/row/@ImportTaxBase)[1]', 'FLOAT'), 0),
            ISNULL(@hXml.value('(/row/@FreightAmount)[1]', 'FLOAT'), 0),
            @hXml.value('(/row/@Notes)[1]', 'NVARCHAR(500)'),
            @hXml.value('(/row/@Concept)[1]', 'NVARCHAR(255)'),
            @hXml.value('(/row/@OrderNumber)[1]', 'NVARCHAR(20)'),
            @hXml.value('(/row/@ReceivedBy)[1]', 'NVARCHAR(20)'),
            @hXml.value('(/row/@WarehouseCode)[1]', 'NVARCHAR(50)'),
            ISNULL(@hXml.value('(/row/@CurrencyCode)[1]', 'NVARCHAR(20)'), 'BS'),
            ISNULL(@hXml.value('(/row/@ExchangeRate)[1]', 'FLOAT'), 1),
            ISNULL(@hXml.value('(/row/@DollarPrice)[1]', 'FLOAT'), 0),
            ISNULL(@hXml.value('(/row/@UserCode)[1]', 'NVARCHAR(60)'), 'API'),
            @hXml.value('(/row/@ShortUserCode)[1]', 'NVARCHAR(10)'),
            ISNULL(TRY_CAST(@hXml.value('(/row/@ReportDate)[1]', 'NVARCHAR(50)') AS DATETIME), SYSUTCDATETIME()),
            ISNULL(@hXml.value('(/row/@HostName)[1]', 'NVARCHAR(255)'), HOST_NAME()),
            SYSUTCDATETIME(),
            SYSUTCDATETIME()
        );

        -- 3. INSERT detail lines from XML
        DECLARE @dXml XML = CAST(@DetailXml AS XML);

        INSERT INTO doc.PurchaseDocumentLine (
            DocumentNumber, DocumentType, LineNumber,
            ProductCode, Description,
            Quantity, UnitPrice, UnitCost,
            SubTotal, DiscountAmount, TotalAmount,
            TaxRate, TaxAmount,
            IsVoided, UserCode, LineDate,
            CreatedAt, UpdatedAt
        )
        SELECT
            @numDoc,
            @TipoOperacion,
            r.value('@LineNumber', 'INT'),
            r.value('@ProductCode', 'NVARCHAR(60)'),
            r.value('@Description', 'NVARCHAR(255)'),
            ISNULL(r.value('@Quantity', 'FLOAT'), 0),
            ISNULL(r.value('@UnitPrice', 'FLOAT'), 0),
            ISNULL(r.value('@UnitCost', 'FLOAT'), 0),
            ISNULL(r.value('@SubTotal', 'FLOAT'), 0),
            ISNULL(r.value('@DiscountAmount', 'FLOAT'), 0),
            ISNULL(r.value('@TotalAmount', 'FLOAT'), 0),
            ISNULL(r.value('@TaxRate', 'FLOAT'), 0),
            ISNULL(r.value('@TaxAmount', 'FLOAT'), 0),
            ISNULL(r.value('@IsVoided', 'BIT'), 0),
            r.value('@UserCode', 'NVARCHAR(60)'),
            ISNULL(TRY_CAST(r.value('@LineDate', 'NVARCHAR(50)') AS DATETIME), SYSUTCDATETIME()),
            SYSUTCDATETIME(),
            SYSUTCDATETIME()
        FROM @dXml.nodes('/root/row') AS T(r);

        SET @detalleRows = @@ROWCOUNT;

        -- 4. INSERT payments from XML (if provided)
        IF @PaymentsXml IS NOT NULL AND LEN(@PaymentsXml) > 10
        BEGIN
            DECLARE @pXml XML = CAST(@PaymentsXml AS XML);

            INSERT INTO doc.PurchaseDocumentPayment (
                DocumentNumber, DocumentType,
                PaymentMethod, BankCode, PaymentNumber,
                Amount, PaymentDate, DueDate,
                ReferenceNumber, UserCode,
                CreatedAt, UpdatedAt
            )
            SELECT
                @numDoc,
                @TipoOperacion,
                r.value('@PaymentMethod', 'NVARCHAR(30)'),
                r.value('@BankCode', 'NVARCHAR(60)'),
                r.value('@PaymentNumber', 'NVARCHAR(60)'),
                ISNULL(r.value('@Amount', 'FLOAT'), 0),
                ISNULL(TRY_CAST(r.value('@PaymentDate', 'NVARCHAR(50)') AS DATETIME), SYSUTCDATETIME()),
                TRY_CAST(r.value('@DueDate', 'NVARCHAR(50)') AS DATETIME),
                r.value('@ReferenceNumber', 'NVARCHAR(100)'),
                r.value('@UserCode', 'NVARCHAR(60)'),
                SYSUTCDATETIME(),
                SYSUTCDATETIME()
            FROM @pXml.nodes('/root/row') AS T(r);

            SET @formasPagoRows = @@ROWCOUNT;
        END;

        -- 5. Sync ap.PayableDocument for COMPRA
        IF @TipoOperacion = 'COMPRA'
        BEGIN
            DECLARE @totalAmount     FLOAT;
            DECLARE @supplierCode    NVARCHAR(60);
            DECLARE @isPaid          NVARCHAR(1);
            DECLARE @docDate         DATETIME;
            DECLARE @notes           NVARCHAR(500);
            DECLARE @userCode        NVARCHAR(60);

            SELECT
                @totalAmount  = TotalAmount,
                @supplierCode = SupplierCode,
                @isPaid       = ISNULL(IsPaid, 'N'),
                @docDate      = IssueDate,
                @notes        = Notes,
                @userCode     = UserCode
            FROM doc.PurchaseDocument
            WHERE DocumentNumber = @numDoc AND DocumentType = @TipoOperacion;

            SET @pendingAmount = CASE WHEN UPPER(@isPaid) = 'S' THEN 0 ELSE @totalAmount END;

            IF @supplierCode IS NOT NULL AND LTRIM(RTRIM(@supplierCode)) <> ''
            BEGIN
                DECLARE @CompanyId INT;
                DECLARE @BranchId  INT;
                DECLARE @UserId    INT = NULL;

                SELECT TOP 1 @CompanyId = c.CompanyId
                FROM cfg.Company c
                WHERE c.IsDeleted = 0 AND c.IsActive = 1
                ORDER BY CASE WHEN c.CompanyCode = 'DEFAULT' THEN 0 ELSE 1 END, c.CompanyId;

                SELECT TOP 1 @BranchId = b.BranchId
                FROM cfg.Branch b
                WHERE b.CompanyId = @CompanyId AND b.IsDeleted = 0 AND b.IsActive = 1
                ORDER BY CASE WHEN b.BranchCode = 'MAIN' THEN 0 ELSE 1 END, b.BranchId;

                IF @userCode IS NOT NULL
                BEGIN
                    SELECT TOP 1 @UserId = UserId
                    FROM sec.[User] WHERE UserCode = @userCode AND IsDeleted = 0;
                END;

                DECLARE @SupplierId BIGINT = NULL;
                SELECT TOP 1 @SupplierId = SupplierId
                FROM [master].Supplier
                WHERE SupplierCode = @supplierCode AND CompanyId = @CompanyId AND IsDeleted = 0;

                IF @SupplierId IS NOT NULL AND @CompanyId IS NOT NULL AND @BranchId IS NOT NULL
                BEGIN
                    DECLARE @safePending FLOAT = CASE WHEN @pendingAmount < 0 THEN 0 ELSE @pendingAmount END;
                    DECLARE @status NVARCHAR(20) = CASE
                        WHEN @safePending <= 0 THEN 'PAID'
                        WHEN @safePending < @totalAmount THEN 'PARTIAL'
                        ELSE 'PENDING'
                    END;

                    DECLARE @existingPayableId BIGINT = NULL;
                    SELECT TOP 1 @existingPayableId = PayableDocumentId
                    FROM ap.PayableDocument
                    WHERE CompanyId = @CompanyId AND BranchId = @BranchId
                      AND DocumentType = @TipoOperacion AND DocumentNumber = @numDoc;

                    IF @existingPayableId IS NOT NULL
                    BEGIN
                        UPDATE ap.PayableDocument
                        SET SupplierId = @SupplierId, IssueDate = @docDate, DueDate = @docDate,
                            TotalAmount = @totalAmount, PendingAmount = @safePending,
                            PaidFlag = CASE WHEN @safePending <= 0 THEN 1 ELSE 0 END,
                            Status = @status, Notes = @notes,
                            UpdatedAt = SYSUTCDATETIME(), UpdatedByUserId = @UserId
                        WHERE PayableDocumentId = @existingPayableId;
                    END
                    ELSE
                    BEGIN
                        INSERT INTO ap.PayableDocument (
                            CompanyId, BranchId, SupplierId,
                            DocumentType, DocumentNumber,
                            IssueDate, DueDate, CurrencyCode,
                            TotalAmount, PendingAmount, PaidFlag, Status, Notes,
                            CreatedAt, UpdatedAt, CreatedByUserId, UpdatedByUserId
                        )
                        VALUES (
                            @CompanyId, @BranchId, @SupplierId,
                            @TipoOperacion, @numDoc,
                            @docDate, @docDate, 'USD',
                            @totalAmount, @safePending,
                            CASE WHEN @safePending <= 0 THEN 1 ELSE 0 END,
                            @status, @notes,
                            SYSUTCDATETIME(), SYSUTCDATETIME(), @UserId, @UserId
                        );
                    END;

                    EXEC dbo.usp_Master_Supplier_UpdateBalance
                        @SupplierId = @SupplierId, @UpdatedByUserId = @UserId;
                END;
            END;
        END;

    COMMIT TRAN;
    SET @ok = 1;

    SELECT @ok AS ok, @numDoc AS numDoc, @detalleRows AS detalleRows,
           @formasPagoRows AS formasPagoRows, @pendingAmount AS pendingAmount;
END;
GO


-- =============================================================================
-- SP 2: usp_Doc_PurchaseDocument_ConvertOrder (SQL 2012 compatible - XML)
-- Convierte una orden de compra en un documento de compra.
-- =============================================================================
IF OBJECT_ID('dbo.usp_Doc_PurchaseDocument_ConvertOrder', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_Doc_PurchaseDocument_ConvertOrder;
GO
CREATE PROCEDURE dbo.usp_Doc_PurchaseDocument_ConvertOrder
    @NumDocOrden         NVARCHAR(60),
    @NumDocCompra        NVARCHAR(60),
    @CompraOverrideXml   NVARCHAR(MAX) = NULL,
    @DetalleXml          NVARCHAR(MAX) = NULL,
    @CodUsuario          NVARCHAR(60)  = 'API'
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @ok             BIT           = 0;
    DECLARE @mensaje        NVARCHAR(500) = '';
    DECLARE @detalleRows    INT           = 0;
    DECLARE @formasPagoRows INT           = 0;
    DECLARE @pendingAmount  FLOAT         = 0;

    -- Validate params
    IF @NumDocOrden IS NULL OR LTRIM(RTRIM(@NumDocOrden)) = ''
    BEGIN
        SET @mensaje = 'Numero de orden requerido (@NumDocOrden)';
        SELECT @ok AS ok, @NumDocOrden AS orden, @NumDocCompra AS compra,
               @detalleRows AS detalleRows, @formasPagoRows AS formasPagoRows,
               @pendingAmount AS pendingAmount, @mensaje AS mensaje;
        RETURN;
    END;

    IF @NumDocCompra IS NULL OR LTRIM(RTRIM(@NumDocCompra)) = ''
    BEGIN
        SET @mensaje = 'Numero de compra requerido (@NumDocCompra)';
        SELECT @ok AS ok, @NumDocOrden AS orden, @NumDocCompra AS compra,
               @detalleRows AS detalleRows, @formasPagoRows AS formasPagoRows,
               @pendingAmount AS pendingAmount, @mensaje AS mensaje;
        RETURN;
    END;

    IF NOT EXISTS (SELECT 1 FROM doc.PurchaseDocument WHERE DocumentNumber = @NumDocOrden AND DocumentType = 'ORDEN' AND IsDeleted = 0)
    BEGIN
        SET @mensaje = 'Orden de compra no encontrada: ' + @NumDocOrden;
        SELECT @ok AS ok, @NumDocOrden AS orden, @NumDocCompra AS compra,
               @detalleRows AS detalleRows, @formasPagoRows AS formasPagoRows,
               @pendingAmount AS pendingAmount, @mensaje AS mensaje;
        RETURN;
    END;

    IF EXISTS (SELECT 1 FROM doc.PurchaseDocument WHERE DocumentNumber = @NumDocOrden AND DocumentType = 'ORDEN' AND IsDeleted = 0 AND IsVoided = 1)
    BEGIN
        SET @mensaje = 'La orden esta anulada y no puede convertirse: ' + @NumDocOrden;
        SELECT @ok AS ok, @NumDocOrden AS orden, @NumDocCompra AS compra,
               @detalleRows AS detalleRows, @formasPagoRows AS formasPagoRows,
               @pendingAmount AS pendingAmount, @mensaje AS mensaje;
        RETURN;
    END;

    -- Parse override XML if provided
    DECLARE @ovXml XML = NULL;
    IF @CompraOverrideXml IS NOT NULL AND LEN(@CompraOverrideXml) > 5
        SET @ovXml = CAST(@CompraOverrideXml AS XML);

    BEGIN TRAN;

        -- 1. Delete existing purchase (idempotent)
        DELETE FROM doc.PurchaseDocumentPayment WHERE DocumentNumber = @NumDocCompra AND DocumentType = 'COMPRA';
        DELETE FROM doc.PurchaseDocumentLine WHERE DocumentNumber = @NumDocCompra AND DocumentType = 'COMPRA';
        DELETE FROM doc.PurchaseDocument WHERE DocumentNumber = @NumDocCompra AND DocumentType = 'COMPRA';

        -- 2. Copy header from order with overrides
        INSERT INTO doc.PurchaseDocument (
            DocumentNumber, SerialType, DocumentType,
            SupplierCode, SupplierName, FiscalId,
            IssueDate, DueDate, ReceiptDate, PaymentDate, DocumentTime,
            SubTotal, TaxableAmount, ExemptAmount, TaxAmount, TaxRate,
            TotalAmount, DiscountAmount,
            IsVoided, IsPaid, IsReceived, IsLegal,
            OriginDocumentNumber, ControlNumber,
            VoucherNumber, VoucherDate, RetainedTax,
            IsrCode, IsrAmount, IsrSubjectCode, IsrSubjectAmount, RetentionRate,
            ImportAmount, ImportTax, ImportBase, FreightAmount,
            Notes, Concept, OrderNumber, ReceivedBy, WarehouseCode,
            CurrencyCode, ExchangeRate, UsdAmount,
            UserCode, ShortUserCode, ReportDate, HostName,
            CreatedAt, UpdatedAt
        )
        SELECT
            @NumDocCompra,
            o.SerialType,
            'COMPRA',
            COALESCE(CASE WHEN @ovXml IS NOT NULL THEN @ovXml.value('(/row/@SupplierCode)[1]', 'NVARCHAR(60)') END, o.SupplierCode),
            COALESCE(CASE WHEN @ovXml IS NOT NULL THEN @ovXml.value('(/row/@SupplierName)[1]', 'NVARCHAR(255)') END, o.SupplierName),
            COALESCE(CASE WHEN @ovXml IS NOT NULL THEN @ovXml.value('(/row/@FiscalId)[1]', 'NVARCHAR(15)') END, o.FiscalId),
            ISNULL(CASE WHEN @ovXml IS NOT NULL THEN TRY_CAST(@ovXml.value('(/row/@IssueDate)[1]', 'NVARCHAR(50)') AS DATETIME) END, SYSUTCDATETIME()),
            COALESCE(CASE WHEN @ovXml IS NOT NULL THEN TRY_CAST(@ovXml.value('(/row/@DueDate)[1]', 'NVARCHAR(50)') AS DATETIME) END, o.DueDate),
            COALESCE(CASE WHEN @ovXml IS NOT NULL THEN TRY_CAST(@ovXml.value('(/row/@ReceiptDate)[1]', 'NVARCHAR(50)') AS DATETIME) END, o.ReceiptDate),
            COALESCE(CASE WHEN @ovXml IS NOT NULL THEN TRY_CAST(@ovXml.value('(/row/@PaymentDate)[1]', 'NVARCHAR(50)') AS DATETIME) END, o.PaymentDate),
            ISNULL(CASE WHEN @ovXml IS NOT NULL THEN @ovXml.value('(/row/@DocumentTime)[1]', 'NVARCHAR(20)') END, CONVERT(NVARCHAR(8), SYSUTCDATETIME(), 108)),
            COALESCE(CASE WHEN @ovXml IS NOT NULL THEN @ovXml.value('(/row/@SubTotal)[1]', 'FLOAT') END, o.SubTotal),
            COALESCE(CASE WHEN @ovXml IS NOT NULL THEN @ovXml.value('(/row/@TaxableAmount)[1]', 'FLOAT') END, o.TaxableAmount),
            COALESCE(CASE WHEN @ovXml IS NOT NULL THEN @ovXml.value('(/row/@ExemptAmount)[1]', 'FLOAT') END, o.ExemptAmount),
            COALESCE(CASE WHEN @ovXml IS NOT NULL THEN @ovXml.value('(/row/@TaxAmount)[1]', 'FLOAT') END, o.TaxAmount),
            COALESCE(CASE WHEN @ovXml IS NOT NULL THEN @ovXml.value('(/row/@TaxRate)[1]', 'FLOAT') END, o.TaxRate),
            COALESCE(CASE WHEN @ovXml IS NOT NULL THEN @ovXml.value('(/row/@TotalAmount)[1]', 'FLOAT') END, o.TotalAmount),
            COALESCE(CASE WHEN @ovXml IS NOT NULL THEN @ovXml.value('(/row/@DiscountAmount)[1]', 'FLOAT') END, o.DiscountAmount),
            0,
            ISNULL(CASE WHEN @ovXml IS NOT NULL THEN @ovXml.value('(/row/@IsPaid)[1]', 'NVARCHAR(1)') END, 'N'),
            'N',
            COALESCE(CASE WHEN @ovXml IS NOT NULL THEN @ovXml.value('(/row/@IsLegal)[1]', 'BIT') END, o.IsLegal),
            @NumDocOrden,
            COALESCE(CASE WHEN @ovXml IS NOT NULL THEN @ovXml.value('(/row/@ControlNumber)[1]', 'NVARCHAR(60)') END, o.ControlNumber),
            o.VoucherNumber, o.VoucherDate, o.RetainedTax,
            o.IsrCode, o.IsrAmount, o.IsrSubjectCode, o.IsrSubjectAmount, o.RetentionRate,
            o.ImportAmount, o.ImportTax, o.ImportBase, o.FreightAmount,
            COALESCE(CASE WHEN @ovXml IS NOT NULL THEN @ovXml.value('(/row/@Notes)[1]', 'NVARCHAR(500)') END, o.Notes),
            o.Concept, o.OrderNumber, o.ReceivedBy,
            COALESCE(CASE WHEN @ovXml IS NOT NULL THEN @ovXml.value('(/row/@WarehouseCode)[1]', 'NVARCHAR(50)') END, o.WarehouseCode),
            ISNULL(o.CurrencyCode, 'BS'),
            ISNULL(o.ExchangeRate, 1),
            o.UsdAmount,
            @CodUsuario,
            o.ShortUserCode,
            SYSUTCDATETIME(),
            HOST_NAME(),
            SYSUTCDATETIME(),
            SYSUTCDATETIME()
        FROM doc.PurchaseDocument o
        WHERE o.DocumentNumber = @NumDocOrden AND o.DocumentType = 'ORDEN' AND o.IsDeleted = 0;

        -- 3. Copy detail lines (from XML or from order)
        IF @DetalleXml IS NOT NULL AND LEN(@DetalleXml) > 10
        BEGIN
            DECLARE @detXml XML = CAST(@DetalleXml AS XML);

            INSERT INTO doc.PurchaseDocumentLine (
                DocumentNumber, DocumentType, LineNumber,
                ProductCode, Description,
                Quantity, UnitPrice, UnitCost,
                SubTotal, DiscountAmount, TotalAmount,
                TaxRate, TaxAmount,
                IsVoided, UserCode, LineDate,
                CreatedAt, UpdatedAt
            )
            SELECT
                @NumDocCompra, 'COMPRA',
                r.value('@LineNumber', 'INT'),
                r.value('@ProductCode', 'NVARCHAR(60)'),
                r.value('@Description', 'NVARCHAR(255)'),
                ISNULL(r.value('@Quantity', 'FLOAT'), 0),
                ISNULL(r.value('@UnitPrice', 'FLOAT'), 0),
                ISNULL(r.value('@UnitCost', 'FLOAT'), 0),
                ISNULL(r.value('@SubTotal', 'FLOAT'), 0),
                ISNULL(r.value('@DiscountAmount', 'FLOAT'), 0),
                ISNULL(r.value('@TotalAmount', 'FLOAT'), 0),
                ISNULL(r.value('@TaxRate', 'FLOAT'), 0),
                ISNULL(r.value('@TaxAmount', 'FLOAT'), 0),
                ISNULL(r.value('@IsVoided', 'BIT'), 0),
                @CodUsuario,
                SYSUTCDATETIME(),
                SYSUTCDATETIME(),
                SYSUTCDATETIME()
            FROM @detXml.nodes('/root/row') AS T(r);

            SET @detalleRows = @@ROWCOUNT;
        END
        ELSE
        BEGIN
            INSERT INTO doc.PurchaseDocumentLine (
                DocumentNumber, DocumentType, LineNumber,
                ProductCode, Description,
                Quantity, UnitPrice, UnitCost,
                SubTotal, DiscountAmount, TotalAmount,
                TaxRate, TaxAmount,
                IsVoided, UserCode, LineDate,
                CreatedAt, UpdatedAt
            )
            SELECT
                @NumDocCompra, 'COMPRA',
                ol.LineNumber, ol.ProductCode, ol.Description,
                ol.Quantity, ol.UnitPrice, ol.UnitCost,
                ol.SubTotal, ol.DiscountAmount, ol.TotalAmount,
                ol.TaxRate, ol.TaxAmount,
                0, @CodUsuario, SYSUTCDATETIME(),
                SYSUTCDATETIME(), SYSUTCDATETIME()
            FROM doc.PurchaseDocumentLine ol
            WHERE ol.DocumentNumber = @NumDocOrden AND ol.DocumentType = 'ORDEN' AND ol.IsDeleted = 0;

            SET @detalleRows = @@ROWCOUNT;
        END;

        IF @detalleRows = 0
        BEGIN
            ROLLBACK TRAN;
            SET @mensaje = 'La orden no tiene lineas de detalle: ' + @NumDocOrden;
            SELECT @ok AS ok, @NumDocOrden AS orden, @NumDocCompra AS compra,
                   @detalleRows AS detalleRows, @formasPagoRows AS formasPagoRows,
                   @pendingAmount AS pendingAmount, @mensaje AS mensaje;
            RETURN;
        END;

        -- 4. Mark order as received
        UPDATE doc.PurchaseDocument
        SET IsReceived = 'S',
            Notes = CONCAT(ISNULL(Notes, ''), ' | Convertida a compra ', @NumDocCompra,
                    ' el ', FORMAT(SYSUTCDATETIME(), 'yyyy-MM-dd HH:mm'), ' por ', @CodUsuario),
            UpdatedAt = SYSUTCDATETIME()
        WHERE DocumentNumber = @NumDocOrden AND DocumentType = 'ORDEN' AND IsDeleted = 0;

        -- 5. Sync ap.PayableDocument
        DECLARE @cTotalAmount   FLOAT;
        DECLARE @cSupplierCode  NVARCHAR(60);
        DECLARE @cIsPaid        NVARCHAR(1);
        DECLARE @cDocDate       DATETIME;
        DECLARE @cNotes         NVARCHAR(500);

        SELECT
            @cTotalAmount  = TotalAmount, @cSupplierCode = SupplierCode,
            @cIsPaid       = ISNULL(IsPaid, 'N'), @cDocDate = IssueDate, @cNotes = Notes
        FROM doc.PurchaseDocument
        WHERE DocumentNumber = @NumDocCompra AND DocumentType = 'COMPRA';

        SET @pendingAmount = CASE WHEN UPPER(@cIsPaid) = 'S' THEN 0 ELSE @cTotalAmount END;

        IF @cSupplierCode IS NOT NULL AND LTRIM(RTRIM(@cSupplierCode)) <> ''
        BEGIN
            DECLARE @cCompanyId INT;
            DECLARE @cBranchId  INT;
            DECLARE @cUserId    INT = NULL;

            SELECT TOP 1 @cCompanyId = c.CompanyId FROM cfg.Company c
            WHERE c.IsDeleted = 0 AND c.IsActive = 1
            ORDER BY CASE WHEN c.CompanyCode = 'DEFAULT' THEN 0 ELSE 1 END, c.CompanyId;

            SELECT TOP 1 @cBranchId = b.BranchId FROM cfg.Branch b
            WHERE b.CompanyId = @cCompanyId AND b.IsDeleted = 0 AND b.IsActive = 1
            ORDER BY CASE WHEN b.BranchCode = 'MAIN' THEN 0 ELSE 1 END, b.BranchId;

            SELECT TOP 1 @cUserId = UserId FROM sec.[User]
            WHERE UserCode = @CodUsuario AND IsDeleted = 0;

            DECLARE @cSupplierId BIGINT = NULL;
            SELECT TOP 1 @cSupplierId = SupplierId FROM [master].Supplier
            WHERE SupplierCode = @cSupplierCode AND CompanyId = @cCompanyId AND IsDeleted = 0;

            IF @cSupplierId IS NOT NULL AND @cCompanyId IS NOT NULL AND @cBranchId IS NOT NULL
            BEGIN
                DECLARE @cSafePending FLOAT = CASE WHEN @pendingAmount < 0 THEN 0 ELSE @pendingAmount END;
                DECLARE @cStatus NVARCHAR(20) = CASE
                    WHEN @cSafePending <= 0 THEN 'PAID'
                    WHEN @cSafePending < @cTotalAmount THEN 'PARTIAL'
                    ELSE 'PENDING'
                END;

                DECLARE @cExistingPayableId BIGINT = NULL;
                SELECT TOP 1 @cExistingPayableId = PayableDocumentId
                FROM ap.PayableDocument
                WHERE CompanyId = @cCompanyId AND BranchId = @cBranchId
                  AND DocumentType = 'COMPRA' AND DocumentNumber = @NumDocCompra;

                IF @cExistingPayableId IS NOT NULL
                BEGIN
                    UPDATE ap.PayableDocument
                    SET SupplierId = @cSupplierId, IssueDate = @cDocDate, DueDate = @cDocDate,
                        TotalAmount = @cTotalAmount, PendingAmount = @cSafePending,
                        PaidFlag = CASE WHEN @cSafePending <= 0 THEN 1 ELSE 0 END,
                        Status = @cStatus, Notes = @cNotes,
                        UpdatedAt = SYSUTCDATETIME(), UpdatedByUserId = @cUserId
                    WHERE PayableDocumentId = @cExistingPayableId;
                END
                ELSE
                BEGIN
                    INSERT INTO ap.PayableDocument (
                        CompanyId, BranchId, SupplierId, DocumentType, DocumentNumber,
                        IssueDate, DueDate, CurrencyCode, TotalAmount, PendingAmount,
                        PaidFlag, Status, Notes,
                        CreatedAt, UpdatedAt, CreatedByUserId, UpdatedByUserId
                    )
                    VALUES (
                        @cCompanyId, @cBranchId, @cSupplierId, 'COMPRA', @NumDocCompra,
                        @cDocDate, @cDocDate, 'USD', @cTotalAmount, @cSafePending,
                        CASE WHEN @cSafePending <= 0 THEN 1 ELSE 0 END,
                        @cStatus, @cNotes,
                        SYSUTCDATETIME(), SYSUTCDATETIME(), @cUserId, @cUserId
                    );
                END;

                EXEC dbo.usp_Master_Supplier_UpdateBalance
                    @SupplierId = @cSupplierId, @UpdatedByUserId = @cUserId;
            END;
        END;

    COMMIT TRAN;
    SET @ok = 1;

    SELECT @ok AS ok, @NumDocOrden AS orden, @NumDocCompra AS compra,
           @detalleRows AS detalleRows, @formasPagoRows AS formasPagoRows,
           @pendingAmount AS pendingAmount, '' AS mensaje;
END;
GO


-- =============================================================================
-- SP 3: usp_AR_Receivable_ApplyPayment (SQL 2012 compatible - XML)
-- Aplica un cobro transaccional a documentos CxC de un cliente.
-- =============================================================================
IF OBJECT_ID('dbo.usp_AR_Receivable_ApplyPayment', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_AR_Receivable_ApplyPayment;
GO
CREATE PROCEDURE dbo.usp_AR_Receivable_ApplyPayment
    @CodCliente      NVARCHAR(24),
    @Fecha           DATE             = NULL,
    @RequestId       NVARCHAR(120)    = NULL,
    @NumRecibo       NVARCHAR(120),
    @DocumentosXml   NVARCHAR(MAX),
    @Resultado       INT              OUTPUT,
    @Mensaje         NVARCHAR(500)    OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @CustomerId BIGINT;
    DECLARE @ApplyDate  DATE = COALESCE(@Fecha, CAST(SYSUTCDATETIME() AS DATE));
    DECLARE @Applied    DECIMAL(18,2) = 0;

    SELECT TOP 1 @CustomerId = CustomerId
    FROM [master].Customer WHERE CustomerCode = @CodCliente AND IsDeleted = 0;

    IF @CustomerId IS NULL OR @CustomerId <= 0
    BEGIN
        SET @Resultado = -1;
        SET @Mensaje = N'Cliente no encontrado en esquema canonico';
        RETURN;
    END;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @Docs TABLE (
            TipoDoc       NVARCHAR(20),
            NumDoc        NVARCHAR(120),
            MontoAplicar  DECIMAL(18,2)
        );

        -- Parse XML array
        DECLARE @xDoc XML = CAST(@DocumentosXml AS XML);

        INSERT INTO @Docs (TipoDoc, NumDoc, MontoAplicar)
        SELECT
            r.value('@tipoDoc', 'NVARCHAR(20)'),
            r.value('@numDoc', 'NVARCHAR(120)'),
            r.value('@montoAplicar', 'DECIMAL(18,2)')
        FROM @xDoc.nodes('/root/row') AS T(r);

        DECLARE @TipoDoc NVARCHAR(20), @NumDoc NVARCHAR(120), @MontoAplicar DECIMAL(18,2);
        DECLARE @DocId BIGINT, @Pending DECIMAL(18,2), @ApplyAmount DECIMAL(18,2);

        DECLARE doc_cursor CURSOR LOCAL FAST_FORWARD FOR
            SELECT TipoDoc, NumDoc, MontoAplicar FROM @Docs;

        OPEN doc_cursor;
        FETCH NEXT FROM doc_cursor INTO @TipoDoc, @NumDoc, @MontoAplicar;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            SET @DocId = NULL;
            SET @Pending = NULL;

            SELECT TOP 1 @DocId = ReceivableDocumentId, @Pending = PendingAmount
            FROM ar.ReceivableDocument WITH (UPDLOCK, ROWLOCK)
            WHERE CustomerId = @CustomerId AND DocumentType = @TipoDoc
              AND DocumentNumber = @NumDoc AND Status <> 'VOIDED'
            ORDER BY ReceivableDocumentId DESC;

            SET @ApplyAmount = CASE
                WHEN @Pending IS NULL THEN 0
                WHEN @MontoAplicar < @Pending THEN @MontoAplicar
                ELSE @Pending
            END;

            IF @ApplyAmount > 0 AND @DocId IS NOT NULL
            BEGIN
                INSERT INTO ar.ReceivableApplication (
                    ReceivableDocumentId, ApplyDate, AppliedAmount, PaymentReference
                ) VALUES (@DocId, @ApplyDate, @ApplyAmount, CONCAT(@RequestId, N':', @NumRecibo));

                UPDATE ar.ReceivableDocument
                SET PendingAmount = CASE WHEN PendingAmount - @ApplyAmount < 0 THEN 0
                                         ELSE PendingAmount - @ApplyAmount END,
                    PaidFlag = CASE WHEN PendingAmount - @ApplyAmount <= 0 THEN 1 ELSE 0 END,
                    Status = CASE
                               WHEN PendingAmount - @ApplyAmount <= 0 THEN 'PAID'
                               WHEN PendingAmount - @ApplyAmount < TotalAmount THEN 'PARTIAL'
                               ELSE 'PENDING'
                             END,
                    UpdatedAt = SYSUTCDATETIME()
                WHERE ReceivableDocumentId = @DocId;

                SET @Applied = @Applied + @ApplyAmount;
            END;

            FETCH NEXT FROM doc_cursor INTO @TipoDoc, @NumDoc, @MontoAplicar;
        END;

        CLOSE doc_cursor;
        DEALLOCATE doc_cursor;

        IF @Applied <= 0
        BEGIN
            ROLLBACK TRANSACTION;
            SET @Resultado = -2;
            SET @Mensaje = N'No hay montos aplicables para cobrar';
            RETURN;
        END;

        UPDATE [master].Customer
        SET TotalBalance = (
                SELECT ISNULL(SUM(PendingAmount), 0) FROM ar.ReceivableDocument
                WHERE CustomerId = @CustomerId AND Status <> 'VOIDED'
            ),
            UpdatedAt = SYSUTCDATETIME()
        WHERE CustomerId = @CustomerId;

        COMMIT TRANSACTION;
        SET @Resultado = 1;
        SET @Mensaje = N'Cobro aplicado exitosamente. Monto: ' + CAST(@Applied AS NVARCHAR(30));
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SET @Resultado = -99;
        SET @Mensaje = N'Error en cobro: ' + ERROR_MESSAGE();
    END CATCH;
END;
GO


-- =============================================================================
-- SP 4: usp_AP_Payable_ApplyPayment (SQL 2012 compatible - XML)
-- Aplica un pago transaccional a documentos CxP de un proveedor.
-- =============================================================================
IF OBJECT_ID('dbo.usp_AP_Payable_ApplyPayment', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_AP_Payable_ApplyPayment;
GO
CREATE PROCEDURE dbo.usp_AP_Payable_ApplyPayment
    @CodProveedor    NVARCHAR(24),
    @Fecha           DATE             = NULL,
    @RequestId       NVARCHAR(120)    = NULL,
    @NumPago         NVARCHAR(120),
    @DocumentosXml   NVARCHAR(MAX),
    @Resultado       INT              OUTPUT,
    @Mensaje         NVARCHAR(500)    OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @SupplierId BIGINT;
    DECLARE @ApplyDate  DATE = COALESCE(@Fecha, CAST(SYSUTCDATETIME() AS DATE));
    DECLARE @Applied    DECIMAL(18,2) = 0;

    SELECT TOP 1 @SupplierId = SupplierId
    FROM [master].Supplier WHERE SupplierCode = @CodProveedor AND IsDeleted = 0;

    IF @SupplierId IS NULL OR @SupplierId <= 0
    BEGIN
        SET @Resultado = -1;
        SET @Mensaje = N'Proveedor no encontrado en esquema canonico';
        RETURN;
    END;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @Docs TABLE (
            TipoDoc       NVARCHAR(20),
            NumDoc        NVARCHAR(120),
            MontoAplicar  DECIMAL(18,2)
        );

        DECLARE @xDoc XML = CAST(@DocumentosXml AS XML);

        INSERT INTO @Docs (TipoDoc, NumDoc, MontoAplicar)
        SELECT
            r.value('@tipoDoc', 'NVARCHAR(20)'),
            r.value('@numDoc', 'NVARCHAR(120)'),
            r.value('@montoAplicar', 'DECIMAL(18,2)')
        FROM @xDoc.nodes('/root/row') AS T(r);

        DECLARE @TipoDoc NVARCHAR(20), @NumDoc NVARCHAR(120), @MontoAplicar DECIMAL(18,2);
        DECLARE @DocId BIGINT, @Pending DECIMAL(18,2), @ApplyAmount DECIMAL(18,2);

        DECLARE doc_cursor CURSOR LOCAL FAST_FORWARD FOR
            SELECT TipoDoc, NumDoc, MontoAplicar FROM @Docs;

        OPEN doc_cursor;
        FETCH NEXT FROM doc_cursor INTO @TipoDoc, @NumDoc, @MontoAplicar;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            SET @DocId = NULL;
            SET @Pending = NULL;

            SELECT TOP 1 @DocId = PayableDocumentId, @Pending = PendingAmount
            FROM ap.PayableDocument WITH (UPDLOCK, ROWLOCK)
            WHERE SupplierId = @SupplierId AND DocumentType = @TipoDoc
              AND DocumentNumber = @NumDoc AND Status <> 'VOIDED'
            ORDER BY PayableDocumentId DESC;

            SET @ApplyAmount = CASE
                WHEN @Pending IS NULL THEN 0
                WHEN @MontoAplicar < @Pending THEN @MontoAplicar
                ELSE @Pending
            END;

            IF @ApplyAmount > 0 AND @DocId IS NOT NULL
            BEGIN
                INSERT INTO ap.PayableApplication (
                    PayableDocumentId, ApplyDate, AppliedAmount, PaymentReference
                ) VALUES (@DocId, @ApplyDate, @ApplyAmount, CONCAT(@RequestId, N':', @NumPago));

                UPDATE ap.PayableDocument
                SET PendingAmount = CASE WHEN PendingAmount - @ApplyAmount < 0 THEN 0
                                         ELSE PendingAmount - @ApplyAmount END,
                    PaidFlag = CASE WHEN PendingAmount - @ApplyAmount <= 0 THEN 1 ELSE 0 END,
                    Status = CASE
                               WHEN PendingAmount - @ApplyAmount <= 0 THEN 'PAID'
                               WHEN PendingAmount - @ApplyAmount < TotalAmount THEN 'PARTIAL'
                               ELSE 'PENDING'
                             END,
                    UpdatedAt = SYSUTCDATETIME()
                WHERE PayableDocumentId = @DocId;

                SET @Applied = @Applied + @ApplyAmount;
            END;

            FETCH NEXT FROM doc_cursor INTO @TipoDoc, @NumDoc, @MontoAplicar;
        END;

        CLOSE doc_cursor;
        DEALLOCATE doc_cursor;

        IF @Applied <= 0
        BEGIN
            ROLLBACK TRANSACTION;
            SET @Resultado = -2;
            SET @Mensaje = N'No hay montos aplicables para pagar';
            RETURN;
        END;

        UPDATE [master].Supplier
        SET TotalBalance = (
                SELECT ISNULL(SUM(PendingAmount), 0) FROM ap.PayableDocument
                WHERE SupplierId = @SupplierId AND Status <> 'VOIDED'
            ),
            UpdatedAt = SYSUTCDATETIME()
        WHERE SupplierId = @SupplierId;

        COMMIT TRANSACTION;
        SET @Resultado = 1;
        SET @Mensaje = N'Pago aplicado exitosamente. Monto: ' + CAST(@Applied AS NVARCHAR(30));
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SET @Resultado = -99;
        SET @Mensaje = N'Error en pago: ' + ERROR_MESSAGE();
    END CATCH;
END;
GO


-- =============================================================================
-- SP 5: usp_HR_Payroll_UpsertRun (SQL 2012 compatible - XML)
-- Inserta o actualiza un PayrollRun con sus lineas (XML en lugar de JSON).
-- Las lineas se pasan como XML para compatibilidad SQL Server 2012.
-- =============================================================================
IF OBJECT_ID('dbo.usp_HR_Payroll_UpsertRun', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_HR_Payroll_UpsertRun;
GO
CREATE PROCEDURE dbo.usp_HR_Payroll_UpsertRun
    @CompanyId         INT,
    @BranchId          INT,
    @PayrollCode       NVARCHAR(15),
    @EmployeeId        BIGINT,
    @EmployeeCode      NVARCHAR(24),
    @EmployeeName      NVARCHAR(200),
    @FromDate          DATE,
    @ToDate            DATE,
    @TotalAssignments  DECIMAL(18,2),
    @TotalDeductions   DECIMAL(18,2),
    @NetTotal          DECIMAL(18,2),
    @PayrollTypeName   NVARCHAR(50)  = NULL,
    @UserId            INT           = NULL,
    @LinesXml          NVARCHAR(MAX) = NULL,
    @Resultado         INT           OUTPUT,
    @Mensaje           NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @RunId BIGINT;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Buscar run existente
        SELECT TOP 1 @RunId = PayrollRunId
        FROM hr.PayrollRun
        WHERE CompanyId    = @CompanyId
          AND BranchId     = @BranchId
          AND PayrollCode  = @PayrollCode
          AND EmployeeCode = @EmployeeCode
          AND DateFrom     = @FromDate
          AND DateTo       = @ToDate
          AND RunSource    = N'MANUAL'
        ORDER BY PayrollRunId DESC;

        IF @RunId IS NOT NULL
        BEGIN
            UPDATE hr.PayrollRun
            SET ProcessDate      = CAST(SYSUTCDATETIME() AS DATE),
                TotalAssignments = @TotalAssignments,
                TotalDeductions  = @TotalDeductions,
                NetTotal         = @NetTotal,
                PayrollTypeName  = COALESCE(@PayrollTypeName, PayrollTypeName),
                UpdatedAt        = SYSUTCDATETIME(),
                UpdatedByUserId  = @UserId
            WHERE PayrollRunId = @RunId;

            DELETE FROM hr.PayrollRunLine WHERE PayrollRunId = @RunId;
        END
        ELSE
        BEGIN
            INSERT INTO hr.PayrollRun (
                CompanyId, BranchId, PayrollCode, EmployeeId, EmployeeCode,
                EmployeeName, PositionName, ProcessDate, DateFrom, DateTo,
                TotalAssignments, TotalDeductions, NetTotal, PayrollTypeName,
                RunSource, CreatedByUserId, UpdatedByUserId
            )
            VALUES (
                @CompanyId, @BranchId, @PayrollCode, @EmployeeId, @EmployeeCode,
                @EmployeeName, NULL, CAST(SYSUTCDATETIME() AS DATE), @FromDate, @ToDate,
                @TotalAssignments, @TotalDeductions, @NetTotal, @PayrollTypeName,
                N'MANUAL', @UserId, @UserId
            );

            SET @RunId = SCOPE_IDENTITY();
        END;

        -- Insertar lineas desde XML (reemplaza OPENJSON)
        IF @LinesXml IS NOT NULL AND LEN(@LinesXml) > 2
        BEGIN
            DECLARE @lXml XML = CAST(@LinesXml AS XML);

            INSERT INTO hr.PayrollRunLine (
                PayrollRunId, ConceptCode, ConceptName, ConceptType,
                Quantity, Amount, Total, DescriptionText, AccountingAccountCode
            )
            SELECT
                @RunId,
                r.value('@code', 'NVARCHAR(30)'),
                r.value('@name', 'NVARCHAR(200)'),
                r.value('@type', 'NVARCHAR(20)'),
                CAST(r.value('@quantity', 'NVARCHAR(30)') AS DECIMAL(18,4)),
                CAST(r.value('@amount', 'NVARCHAR(30)') AS DECIMAL(18,4)),
                CAST(r.value('@total', 'NVARCHAR(30)') AS DECIMAL(18,2)),
                r.value('@description', 'NVARCHAR(500)'),
                r.value('@account', 'NVARCHAR(30)')
            FROM @lXml.nodes('/root/row') AS T(r);
        END;

        COMMIT TRANSACTION;

        SET @Resultado = 1;
        SET @Mensaje = N'ok';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SET @Resultado = -99;
        SET @Mensaje = N'Error en upsert run: ' + ERROR_MESSAGE();
    END CATCH;
END;
GO


-- =============================================================================
-- SP 6: usp_Sys_HeaderDetailTx (SQL 2012 compatible - XML)
-- Generic header+detail transaction insert.
-- =============================================================================
IF OBJECT_ID('dbo.usp_Sys_HeaderDetailTx', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_Sys_HeaderDetailTx;
GO
CREATE PROCEDURE dbo.usp_Sys_HeaderDetailTx
    @HeaderTable   NVARCHAR(260),
    @DetailTable   NVARCHAR(260),
    @HeaderXml     NVARCHAR(MAX),
    @DetailsXml    NVARCHAR(MAX),
    @LinkFieldsCsv NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRANSACTION;
    BEGIN TRY
        DECLARE @hXml XML = CAST(@HeaderXml AS XML);
        DECLARE @dXml XML = CAST(@DetailsXml AS XML);

        -- Build header INSERT dynamically from XML attributes
        DECLARE @HCols NVARCHAR(MAX) = '';
        DECLARE @HVals NVARCHAR(MAX) = '';

        SELECT
            @HCols = @HCols + CASE WHEN LEN(@HCols) > 0 THEN ', ' ELSE '' END
                + QUOTENAME(a.value('local-name(.)', 'NVARCHAR(128)')),
            @HVals = @HVals + CASE WHEN LEN(@HVals) > 0 THEN ', ' ELSE '' END
                + 'N''' + REPLACE(a.value('.', 'NVARCHAR(MAX)'), '''', '''''') + ''''
        FROM @hXml.nodes('/row/@*') AS T(a);

        DECLARE @InsertHeaderSql NVARCHAR(MAX) = 'INSERT INTO ' + @HeaderTable + ' (' + @HCols + ') VALUES (' + @HVals + ')';
        EXEC sp_executesql @InsertHeaderSql;

        -- Count detail rows
        DECLARE @DetailCount INT = @dXml.value('count(/root/row)', 'INT');
        DECLARE @DetailIdx INT = 1;
        DECLARE @DCols NVARCHAR(MAX);
        DECLARE @DVals NVARCHAR(MAX);
        DECLARE @rowXml XML;
        DECLARE @InsertDetailSql NVARCHAR(MAX);

        -- Process each detail row
        WHILE @DetailIdx <= @DetailCount
        BEGIN
            SET @DCols = '';
            SET @DVals = '';

            -- Extract this row
            SET @rowXml = @dXml.query('(/root/row[position()=sql:variable("@DetailIdx")])[1]');

            -- If link fields, add header values for missing attributes
            IF @LinkFieldsCsv IS NOT NULL AND LEN(@LinkFieldsCsv) > 0
            BEGIN
                DECLARE @lf NVARCHAR(128);
                DECLARE @lfPos INT = 1;
                DECLARE @lfEnd INT;
                DECLARE @csvLen INT = LEN(@LinkFieldsCsv);
                DECLARE @detailVal NVARCHAR(MAX);
                DECLARE @hVal NVARCHAR(MAX);

                WHILE @lfPos <= @csvLen
                BEGIN
                    SET @lfEnd = CHARINDEX(',', @LinkFieldsCsv, @lfPos);
                    IF @lfEnd = 0 SET @lfEnd = @csvLen + 1;
                    SET @lf = LTRIM(RTRIM(SUBSTRING(@LinkFieldsCsv, @lfPos, @lfEnd - @lfPos)));
                    SET @lfPos = @lfEnd + 1;

                    -- Check if attribute exists in detail row
                    SET @detailVal = @rowXml.value('(/row/@*[local-name()=sql:variable("@lf")])[1]', 'NVARCHAR(MAX)');

                    IF @detailVal IS NULL
                    BEGIN
                        SET @hVal = @hXml.value('(/row/@*[local-name()=sql:variable("@lf")])[1]', 'NVARCHAR(MAX)');
                        IF @hVal IS NOT NULL
                        BEGIN
                            -- Inject header attribute into detail row XML
                            DECLARE @escapedHVal NVARCHAR(MAX) = REPLACE(REPLACE(REPLACE(REPLACE(@hVal, '&', '&amp;'), '"', '&quot;'), '<', '&lt;'), '>', '&gt;');
                            SET @rowXml = CAST(
                                REPLACE(CAST(@rowXml AS NVARCHAR(MAX)), '<row ', '<row ' + @lf + '="' + @escapedHVal + '" ')
                            AS XML);
                        END;
                    END;
                END;
            END;

            -- Build INSERT from row attributes
            SELECT
                @DCols = @DCols + CASE WHEN LEN(@DCols) > 0 THEN ', ' ELSE '' END
                    + QUOTENAME(a.value('local-name(.)', 'NVARCHAR(128)')),
                @DVals = @DVals + CASE WHEN LEN(@DVals) > 0 THEN ', ' ELSE '' END
                    + 'N''' + REPLACE(a.value('.', 'NVARCHAR(MAX)'), '''', '''''') + ''''
            FROM @rowXml.nodes('/row/@*') AS T(a);

            IF LEN(@DCols) > 0
            BEGIN
                SET @InsertDetailSql = 'INSERT INTO ' + @DetailTable + ' (' + @DCols + ') VALUES (' + @DVals + ')';
                EXEC sp_executesql @InsertDetailSql;
            END;

            SET @DetailIdx = @DetailIdx + 1;
        END;

        COMMIT TRANSACTION;
        SELECT 1 AS ok, @DetailCount AS detailRows;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO
