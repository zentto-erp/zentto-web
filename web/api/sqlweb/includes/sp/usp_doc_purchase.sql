-- =============================================================================
-- usp_doc_purchase.sql
-- Procedimientos almacenados para documentos de compra (tablas canonicas doc.*)
-- Tablas: doc.PurchaseDocument, doc.PurchaseDocumentLine, doc.PurchaseDocumentPayment
-- Base de datos: DatqBoxWeb
--
-- Clave unica PurchaseDocument: (DocumentNumber, OperationType)
--
-- Procedimientos:
--   1. usp_Doc_PurchaseDocument_List           - Lista paginada con filtros
--   2. usp_Doc_PurchaseDocument_Get            - Obtener documento individual
--   3. usp_Doc_PurchaseDocument_GetDetail      - Obtener lineas de detalle
--   4. usp_Doc_PurchaseDocument_GetPayments    - Obtener formas de pago
--   5. usp_Doc_PurchaseDocument_GetIndicadores - Obtener indicadores del documento
--   6. usp_Doc_PurchaseDocument_Void           - Anular documento (transaccional)
--   7. usp_Doc_PurchaseDocument_ReceiveOrder   - Marcar orden como recibida
-- =============================================================================

USE DatqBoxWeb;
GO

-- =============================================================================
-- 1. usp_Doc_PurchaseDocument_List
-- Lista paginada de documentos de compra con filtros por tipo, busqueda,
-- codigo de proveedor, y rango de fechas.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Doc_PurchaseDocument_List
    @TipoOperacion  NVARCHAR(20)  = 'COMPRA',
    @Search         NVARCHAR(100) = NULL,
    @Codigo         NVARCHAR(60)  = NULL,
    @FromDate       DATE          = NULL,
    @ToDate         DATE          = NULL,
    @Page           INT           = 1,
    @Limit          INT           = 50,
    @TotalCount     INT           OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Validar parametros de paginacion
    IF @Page < 1 SET @Page = 1;
    IF @Limit < 1 SET @Limit = 50;
    IF @Limit > 500 SET @Limit = 500;

    -- Contar total de registros que coinciden con los filtros
    SELECT @TotalCount = COUNT(*)
    FROM doc.PurchaseDocument
    WHERE OperationType = @TipoOperacion
      AND IsDeleted = 0
      AND (@Search IS NULL OR (
            DocumentNumber LIKE '%' + @Search + '%'
            OR SupplierName LIKE '%' + @Search + '%'
            OR FiscalId LIKE '%' + @Search + '%'
          ))
      AND (@Codigo IS NULL OR SupplierCode = @Codigo)
      AND (@FromDate IS NULL OR DocumentDate >= @FromDate)
      AND (@ToDate IS NULL OR DocumentDate < DATEADD(DAY, 1, @ToDate));

    -- Obtener pagina de resultados
    SELECT *
    FROM doc.PurchaseDocument
    WHERE OperationType = @TipoOperacion
      AND IsDeleted = 0
      AND (@Search IS NULL OR (
            DocumentNumber LIKE '%' + @Search + '%'
            OR SupplierName LIKE '%' + @Search + '%'
            OR FiscalId LIKE '%' + @Search + '%'
          ))
      AND (@Codigo IS NULL OR SupplierCode = @Codigo)
      AND (@FromDate IS NULL OR DocumentDate >= @FromDate)
      AND (@ToDate IS NULL OR DocumentDate < DATEADD(DAY, 1, @ToDate))
    ORDER BY DocumentDate DESC, DocumentNumber DESC
    OFFSET (@Page - 1) * @Limit ROWS
    FETCH NEXT @Limit ROWS ONLY;
END;
GO

-- =============================================================================
-- 2. usp_Doc_PurchaseDocument_Get
-- Obtener un documento de compra individual por numero y tipo de operacion.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Doc_PurchaseDocument_Get
    @TipoOperacion  NVARCHAR(20),
    @NumDoc         NVARCHAR(60)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 1 *
    FROM doc.PurchaseDocument
    WHERE DocumentNumber = @NumDoc
      AND OperationType = @TipoOperacion
      AND IsDeleted = 0;
END;
GO

-- =============================================================================
-- 3. usp_Doc_PurchaseDocument_GetDetail
-- Obtener las lineas de detalle de un documento de compra.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Doc_PurchaseDocument_GetDetail
    @TipoOperacion  NVARCHAR(20),
    @NumDoc         NVARCHAR(60)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT *
    FROM doc.PurchaseDocumentLine
    WHERE DocumentNumber = @NumDoc
      AND OperationType = @TipoOperacion
      AND IsDeleted = 0
    ORDER BY ISNULL(LineNumber, 0), LineId;
END;
GO

-- =============================================================================
-- 4. usp_Doc_PurchaseDocument_GetPayments
-- Obtener las formas de pago de un documento de compra.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Doc_PurchaseDocument_GetPayments
    @TipoOperacion  NVARCHAR(20),
    @NumDoc         NVARCHAR(60)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT *
    FROM doc.PurchaseDocumentPayment
    WHERE DocumentNumber = @NumDoc
      AND OperationType = @TipoOperacion
      AND IsDeleted = 0;
END;
GO

-- =============================================================================
-- 5. usp_Doc_PurchaseDocument_GetIndicadores
-- Obtener indicadores clave de un documento de compra:
-- IsVoided, IsPaid, IsReceived.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Doc_PurchaseDocument_GetIndicadores
    @TipoOperacion  NVARCHAR(20),
    @NumDoc         NVARCHAR(60)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        IsVoided,
        IsPaid,
        IsReceived
    FROM doc.PurchaseDocument
    WHERE DocumentNumber = @NumDoc
      AND OperationType = @TipoOperacion
      AND IsDeleted = 0;
END;
GO

-- =============================================================================
-- 6. usp_Doc_PurchaseDocument_Void
-- Anular un documento de compra. Actualiza el documento, sus lineas,
-- la cuenta por pagar (ap.PayableDocument) y el saldo del proveedor.
-- Operacion transaccional con XACT_ABORT.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Doc_PurchaseDocument_Void
    @TipoOperacion  NVARCHAR(20),
    @NumDoc         NVARCHAR(60),
    @CodUsuario     NVARCHAR(60)  = 'API',
    @Motivo         NVARCHAR(500) = ''
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @ok            BIT           = 0;
    DECLARE @numDoc_out    NVARCHAR(60)  = @NumDoc;
    DECLARE @codProveedor  NVARCHAR(60)  = NULL;
    DECLARE @mensaje       NVARCHAR(500) = '';

    -- Validar que el documento existe y no esta ya anulado
    IF NOT EXISTS (
        SELECT 1 FROM doc.PurchaseDocument
        WHERE DocumentNumber = @NumDoc
          AND OperationType = @TipoOperacion
          AND IsDeleted = 0
    )
    BEGIN
        SET @mensaje = 'Documento no encontrado: ' + @NumDoc + ' / ' + @TipoOperacion;
        SELECT @ok AS ok, @numDoc_out AS numDoc, @codProveedor AS codProveedor, @mensaje AS mensaje;
        RETURN;
    END;

    IF EXISTS (
        SELECT 1 FROM doc.PurchaseDocument
        WHERE DocumentNumber = @NumDoc
          AND OperationType = @TipoOperacion
          AND IsDeleted = 0
          AND IsVoided = 1
    )
    BEGIN
        SET @mensaje = 'El documento ya se encuentra anulado: ' + @NumDoc;
        SELECT @ok AS ok, @numDoc_out AS numDoc, @codProveedor AS codProveedor, @mensaje AS mensaje;
        RETURN;
    END;

    -- Obtener codigo de proveedor
    SELECT @codProveedor = SupplierCode
    FROM doc.PurchaseDocument
    WHERE DocumentNumber = @NumDoc
      AND OperationType = @TipoOperacion
      AND IsDeleted = 0;

    BEGIN TRAN;

        -- Anular cabecera del documento
        UPDATE doc.PurchaseDocument
        SET IsVoided  = 1,
            Notes     = CONCAT(ISNULL(Notes, ''), ' | ANULADO ', FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm'),
                         ' por ', @CodUsuario,
                         CASE WHEN @Motivo <> '' THEN ' - Motivo: ' + @Motivo ELSE '' END),
            UpdatedAt = SYSUTCDATETIME()
        WHERE DocumentNumber = @NumDoc
          AND OperationType = @TipoOperacion
          AND IsDeleted = 0;

        -- Anular lineas del documento
        UPDATE doc.PurchaseDocumentLine
        SET IsVoided  = 1,
            UpdatedAt = SYSUTCDATETIME()
        WHERE DocumentNumber = @NumDoc
          AND OperationType = @TipoOperacion
          AND IsDeleted = 0;

        -- Resolver contexto: CompanyId y BranchId
        DECLARE @CompanyId INT;
        DECLARE @BranchId  INT;

        SELECT TOP 1 @CompanyId = c.CompanyId
        FROM cfg.Company c
        WHERE c.IsDeleted = 0 AND c.IsActive = 1
        ORDER BY c.CompanyId;

        SELECT TOP 1 @BranchId = b.BranchId
        FROM cfg.Branch b
        WHERE b.CompanyId = @CompanyId AND b.IsDeleted = 0 AND b.IsActive = 1
        ORDER BY b.BranchId;

        -- Resolver SupplierId desde master.Supplier
        DECLARE @SupplierId BIGINT = NULL;

        SELECT TOP 1 @SupplierId = SupplierId
        FROM [master].Supplier
        WHERE SupplierCode = @codProveedor
          AND CompanyId = @CompanyId
          AND IsDeleted = 0;

        -- Actualizar cuenta por pagar si existe
        IF @SupplierId IS NOT NULL AND @CompanyId IS NOT NULL AND @BranchId IS NOT NULL
        BEGIN
            UPDATE ap.PayableDocument
            SET PendingAmount = 0,
                PaidFlag      = 1,
                Status        = 'VOIDED',
                UpdatedAt     = SYSUTCDATETIME()
            WHERE CompanyId      = @CompanyId
              AND BranchId       = @BranchId
              AND DocumentNumber = @NumDoc
              AND DocumentType   = @TipoOperacion
              AND SupplierId     = @SupplierId;

            -- Recalcular saldo total del proveedor
            UPDATE [master].Supplier
            SET TotalBalance = ISNULL((
                    SELECT SUM(PendingAmount)
                    FROM ap.PayableDocument
                    WHERE SupplierId = @SupplierId
                      AND Status <> 'VOIDED'
                ), 0),
                UpdatedAt = SYSUTCDATETIME()
            WHERE SupplierId = @SupplierId;
        END;

    COMMIT TRAN;

    SET @ok = 1;
    SET @mensaje = 'Documento anulado exitosamente: ' + @NumDoc;

    SELECT @ok AS ok, @numDoc_out AS numDoc, @codProveedor AS codProveedor, @mensaje AS mensaje;
END;
GO

-- =============================================================================
-- 7. usp_Doc_PurchaseDocument_ReceiveOrder
-- Marcar una orden de compra como recibida.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Doc_PurchaseDocument_ReceiveOrder
    @NumDoc      NVARCHAR(60),
    @CodUsuario  NVARCHAR(60) = 'API'
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (
        SELECT 1 FROM doc.PurchaseDocument
        WHERE DocumentNumber = @NumDoc
          AND OperationType = 'ORDEN'
          AND IsDeleted = 0
    )
    BEGIN
        SELECT
            CAST(0 AS BIT) AS ok,
            @NumDoc AS numDoc,
            'Orden de compra no encontrada: ' + @NumDoc AS mensaje;
        RETURN;
    END;

    IF EXISTS (
        SELECT 1 FROM doc.PurchaseDocument
        WHERE DocumentNumber = @NumDoc
          AND OperationType = 'ORDEN'
          AND IsDeleted = 0
          AND IsVoided = 1
    )
    BEGIN
        SELECT
            CAST(0 AS BIT) AS ok,
            @NumDoc AS numDoc,
            'La orden esta anulada y no puede marcarse como recibida: ' + @NumDoc AS mensaje;
        RETURN;
    END;

    UPDATE doc.PurchaseDocument
    SET IsReceived = 'S',
        Notes      = CONCAT(ISNULL(Notes, ''), ' | Recibido ', FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm'),
                      ' por ', @CodUsuario),
        UpdatedAt  = SYSUTCDATETIME()
    WHERE DocumentNumber = @NumDoc
      AND OperationType = 'ORDEN'
      AND IsDeleted = 0;

    SELECT
        CAST(1 AS BIT) AS ok,
        @NumDoc AS numDoc,
        'Orden marcada como recibida exitosamente: ' + @NumDoc AS mensaje;
END;
GO

-- =============================================================================
-- 8. usp_Doc_PurchaseDocument_Upsert
-- Crea o reemplaza un documento de compra completo (cabecera + detalle + pagos).
-- Reemplaza la logica de upsertDocumentoCompraTx + syncPayableDocumentTx del TS.
-- Para tipo COMPRA sincroniza ap.PayableDocument y recalcula saldo proveedor.
-- Operacion transaccional con XACT_ABORT.
--
-- Retorna: ok, numDoc, detalleRows, formasPagoRows, pendingAmount
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Doc_PurchaseDocument_Upsert
    @TipoOperacion  NVARCHAR(20),
    @HeaderJson     NVARCHAR(MAX),
    @DetailJson     NVARCHAR(MAX),
    @PaymentsJson   NVARCHAR(MAX) = NULL,
    @DocOrigen      NVARCHAR(60)  = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- Variables de resultado
    DECLARE @ok             BIT           = 0;
    DECLARE @numDoc         NVARCHAR(60);
    DECLARE @detalleRows    INT           = 0;
    DECLARE @formasPagoRows INT           = 0;
    DECLARE @pendingAmount  FLOAT         = 0;

    -- Parsear cabecera desde JSON
    SELECT
        @numDoc = LTRIM(RTRIM(j.DocumentNumber))
    FROM OPENJSON(@HeaderJson)
    WITH (
        DocumentNumber  NVARCHAR(60)  '$.DocumentNumber'
    ) AS j;

    -- Validar numero de documento
    IF @numDoc IS NULL OR @numDoc = ''
    BEGIN
        SELECT
            @ok             AS ok,
            @numDoc         AS numDoc,
            @detalleRows    AS detalleRows,
            @formasPagoRows AS formasPagoRows,
            @pendingAmount  AS pendingAmount,
            'Numero de documento requerido (DocumentNumber)' AS mensaje;
        RETURN;
    END;

    BEGIN TRAN;

        -- ---------------------------------------------------------------
        -- 1. Eliminar datos existentes (detalle, pagos, cabecera)
        -- ---------------------------------------------------------------
        DELETE FROM doc.PurchaseDocumentPayment
        WHERE DocumentNumber = @numDoc AND OperationType = @TipoOperacion;

        DELETE FROM doc.PurchaseDocumentLine
        WHERE DocumentNumber = @numDoc AND OperationType = @TipoOperacion;

        DELETE FROM doc.PurchaseDocument
        WHERE DocumentNumber = @numDoc AND OperationType = @TipoOperacion;

        -- ---------------------------------------------------------------
        -- 2. INSERT cabecera desde JSON
        -- ---------------------------------------------------------------
        INSERT INTO doc.PurchaseDocument (
            DocumentNumber, SerialType, OperationType,
            SupplierCode, SupplierName, FiscalId,
            DocumentDate, DueDate, ReceiptDate, PaymentDate, DocumentTime,
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
            @numDoc,
            ISNULL(j.SerialType, ''),
            @TipoOperacion,
            j.SupplierCode,
            j.SupplierName,
            j.FiscalId,
            ISNULL(j.DocumentDate, GETDATE()),
            j.DueDate,
            j.ReceiptDate,
            j.PaymentDate,
            ISNULL(j.DocumentTime, CONVERT(NVARCHAR(8), GETDATE(), 108)),
            ISNULL(j.SubTotal, 0),
            ISNULL(j.TaxableAmount, 0),
            ISNULL(j.ExemptAmount, 0),
            ISNULL(j.TaxAmount, 0),
            ISNULL(j.TaxRate, 0),
            ISNULL(j.TotalAmount, 0),
            ISNULL(j.DiscountAmount, 0),
            ISNULL(j.IsVoided, 0),
            ISNULL(j.IsPaid, 'N'),
            ISNULL(j.IsReceived, 'N'),
            ISNULL(j.IsLegal, 0),
            COALESCE(@DocOrigen, j.OriginDocumentNumber),
            j.ControlNumber,
            j.WithholdingCertNumber,
            j.WithholdingCertDate,
            ISNULL(j.WithheldTaxAmount, 0),
            j.IncomeTaxCode,
            ISNULL(j.IncomeTaxAmount, 0),
            j.IncomeTaxPercent,
            ISNULL(j.IsSubjectToIncomeTax, 0),
            ISNULL(j.WithholdingRate, 0),
            ISNULL(j.IsImport, 0),
            ISNULL(j.ImportTaxAmount, 0),
            ISNULL(j.ImportTaxBase, 0),
            ISNULL(j.FreightAmount, 0),
            j.Notes,
            j.Concept,
            j.OrderNumber,
            j.ReceivedBy,
            j.WarehouseCode,
            ISNULL(j.CurrencyCode, 'BS'),
            ISNULL(j.ExchangeRate, 1),
            ISNULL(j.DollarPrice, 0),
            ISNULL(j.UserCode, 'API'),
            j.ShortUserCode,
            ISNULL(j.ReportDate, GETDATE()),
            ISNULL(j.HostName, HOST_NAME()),
            SYSUTCDATETIME(),
            SYSUTCDATETIME()
        FROM OPENJSON(@HeaderJson)
        WITH (
            SerialType              NVARCHAR(60)   '$.SerialType',
            SupplierCode            NVARCHAR(60)   '$.SupplierCode',
            SupplierName            NVARCHAR(255)  '$.SupplierName',
            FiscalId                NVARCHAR(15)   '$.FiscalId',
            DocumentDate            DATETIME       '$.DocumentDate',
            DueDate                 DATETIME       '$.DueDate',
            ReceiptDate             DATETIME       '$.ReceiptDate',
            PaymentDate             DATETIME       '$.PaymentDate',
            DocumentTime            NVARCHAR(20)   '$.DocumentTime',
            SubTotal                FLOAT          '$.SubTotal',
            TaxableAmount           FLOAT          '$.TaxableAmount',
            ExemptAmount            FLOAT          '$.ExemptAmount',
            TaxAmount               FLOAT          '$.TaxAmount',
            TaxRate                 FLOAT          '$.TaxRate',
            TotalAmount             FLOAT          '$.TotalAmount',
            DiscountAmount          FLOAT          '$.DiscountAmount',
            IsVoided                BIT            '$.IsVoided',
            IsPaid                  NVARCHAR(1)    '$.IsPaid',
            IsReceived              NVARCHAR(1)    '$.IsReceived',
            IsLegal                 BIT            '$.IsLegal',
            OriginDocumentNumber    NVARCHAR(60)   '$.OriginDocumentNumber',
            ControlNumber           NVARCHAR(60)   '$.ControlNumber',
            WithholdingCertNumber   NVARCHAR(50)   '$.WithholdingCertNumber',
            WithholdingCertDate     DATETIME       '$.WithholdingCertDate',
            WithheldTaxAmount       FLOAT          '$.WithheldTaxAmount',
            IncomeTaxCode           NVARCHAR(50)   '$.IncomeTaxCode',
            IncomeTaxAmount         FLOAT          '$.IncomeTaxAmount',
            IncomeTaxPercent        NVARCHAR(50)   '$.IncomeTaxPercent',
            IsSubjectToIncomeTax    FLOAT          '$.IsSubjectToIncomeTax',
            WithholdingRate         FLOAT          '$.WithholdingRate',
            IsImport                FLOAT          '$.IsImport',
            ImportTaxAmount         FLOAT          '$.ImportTaxAmount',
            ImportTaxBase           FLOAT          '$.ImportTaxBase',
            FreightAmount           FLOAT          '$.FreightAmount',
            Notes                   NVARCHAR(500)  '$.Notes',
            Concept                 NVARCHAR(255)  '$.Concept',
            OrderNumber             NVARCHAR(20)   '$.OrderNumber',
            ReceivedBy              NVARCHAR(20)   '$.ReceivedBy',
            WarehouseCode           NVARCHAR(50)   '$.WarehouseCode',
            CurrencyCode            NVARCHAR(20)   '$.CurrencyCode',
            ExchangeRate            FLOAT          '$.ExchangeRate',
            DollarPrice             FLOAT          '$.DollarPrice',
            UserCode                NVARCHAR(60)   '$.UserCode',
            ShortUserCode           NVARCHAR(10)   '$.ShortUserCode',
            ReportDate              DATETIME       '$.ReportDate',
            HostName                NVARCHAR(255)  '$.HostName'
        ) AS j;

        -- ---------------------------------------------------------------
        -- 3. INSERT lineas de detalle desde JSON
        -- ---------------------------------------------------------------
        INSERT INTO doc.PurchaseDocumentLine (
            DocumentNumber, OperationType, LineNumber,
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
            j.LineNumber,
            j.ProductCode,
            j.Description,
            ISNULL(j.Quantity, 0),
            ISNULL(j.UnitPrice, 0),
            ISNULL(j.UnitCost, 0),
            ISNULL(j.SubTotal, 0),
            ISNULL(j.DiscountAmount, 0),
            ISNULL(j.TotalAmount, 0),
            ISNULL(j.TaxRate, 0),
            ISNULL(j.TaxAmount, 0),
            ISNULL(j.IsVoided, 0),
            j.UserCode,
            ISNULL(j.LineDate, GETDATE()),
            SYSUTCDATETIME(),
            SYSUTCDATETIME()
        FROM OPENJSON(@DetailJson)
        WITH (
            LineNumber      INT            '$.LineNumber',
            ProductCode     NVARCHAR(60)   '$.ProductCode',
            Description     NVARCHAR(255)  '$.Description',
            Quantity        FLOAT          '$.Quantity',
            UnitPrice       FLOAT          '$.UnitPrice',
            UnitCost        FLOAT          '$.UnitCost',
            SubTotal        FLOAT          '$.SubTotal',
            DiscountAmount  FLOAT          '$.DiscountAmount',
            TotalAmount     FLOAT          '$.TotalAmount',
            TaxRate         FLOAT          '$.TaxRate',
            TaxAmount       FLOAT          '$.TaxAmount',
            IsVoided        BIT            '$.IsVoided',
            UserCode        NVARCHAR(60)   '$.UserCode',
            LineDate        DATETIME       '$.LineDate'
        ) AS j;

        SET @detalleRows = @@ROWCOUNT;

        -- ---------------------------------------------------------------
        -- 4. INSERT formas de pago desde JSON (si se proporcionaron)
        -- ---------------------------------------------------------------
        IF @PaymentsJson IS NOT NULL AND LEN(@PaymentsJson) > 2
        BEGIN
            INSERT INTO doc.PurchaseDocumentPayment (
                DocumentNumber, OperationType,
                PaymentMethod, BankCode, PaymentNumber,
                Amount, PaymentDate, DueDate,
                ReferenceNumber, UserCode,
                CreatedAt, UpdatedAt
            )
            SELECT
                @numDoc,
                @TipoOperacion,
                j.PaymentMethod,
                j.BankCode,
                j.PaymentNumber,
                ISNULL(j.Amount, 0),
                ISNULL(j.PaymentDate, GETDATE()),
                j.DueDate,
                j.ReferenceNumber,
                j.UserCode,
                SYSUTCDATETIME(),
                SYSUTCDATETIME()
            FROM OPENJSON(@PaymentsJson)
            WITH (
                PaymentMethod   NVARCHAR(30)   '$.PaymentMethod',
                BankCode        NVARCHAR(60)   '$.BankCode',
                PaymentNumber   NVARCHAR(60)   '$.PaymentNumber',
                Amount          FLOAT          '$.Amount',
                PaymentDate     DATETIME       '$.PaymentDate',
                DueDate         DATETIME       '$.DueDate',
                ReferenceNumber NVARCHAR(100)  '$.ReferenceNumber',
                UserCode        NVARCHAR(60)   '$.UserCode'
            ) AS j;

            SET @formasPagoRows = @@ROWCOUNT;
        END;

        -- ---------------------------------------------------------------
        -- 5. Sincronizar ap.PayableDocument para tipo COMPRA
        -- ---------------------------------------------------------------
        IF @TipoOperacion = 'COMPRA'
        BEGIN
            DECLARE @totalAmount     FLOAT;
            DECLARE @supplierCode    NVARCHAR(60);
            DECLARE @isPaid          NVARCHAR(1);
            DECLARE @docDate         DATETIME;
            DECLARE @notes           NVARCHAR(500);
            DECLARE @userCode        NVARCHAR(60);

            -- Leer valores de la cabecera recien insertada
            SELECT
                @totalAmount  = TotalAmount,
                @supplierCode = SupplierCode,
                @isPaid       = ISNULL(IsPaid, 'N'),
                @docDate      = DocumentDate,
                @notes        = Notes,
                @userCode     = UserCode
            FROM doc.PurchaseDocument
            WHERE DocumentNumber = @numDoc
              AND OperationType = @TipoOperacion;

            -- Calcular monto pendiente
            SET @pendingAmount = CASE WHEN UPPER(@isPaid) = 'S' THEN 0 ELSE @totalAmount END;

            -- Solo sincronizar si hay proveedor
            IF @supplierCode IS NOT NULL AND LTRIM(RTRIM(@supplierCode)) <> ''
            BEGIN
                -- Resolver contexto canonico
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
                    FROM sec.[User]
                    WHERE UserCode = @userCode AND IsDeleted = 0;
                END;

                -- Resolver SupplierId
                DECLARE @SupplierId BIGINT = NULL;

                SELECT TOP 1 @SupplierId = SupplierId
                FROM [master].Supplier
                WHERE SupplierCode = @supplierCode
                  AND CompanyId = @CompanyId
                  AND IsDeleted = 0;

                IF @SupplierId IS NOT NULL AND @CompanyId IS NOT NULL AND @BranchId IS NOT NULL
                BEGIN
                    -- Calcular status del documento por pagar
                    DECLARE @safePending FLOAT = CASE WHEN @pendingAmount < 0 THEN 0 ELSE @pendingAmount END;
                    DECLARE @status NVARCHAR(20) = CASE
                        WHEN @safePending <= 0 THEN 'PAID'
                        WHEN @safePending < @totalAmount THEN 'PARTIAL'
                        ELSE 'PENDING'
                    END;

                    -- Verificar si ya existe documento por pagar
                    DECLARE @existingPayableId BIGINT = NULL;

                    SELECT TOP 1 @existingPayableId = PayableDocumentId
                    FROM ap.PayableDocument
                    WHERE CompanyId      = @CompanyId
                      AND BranchId       = @BranchId
                      AND DocumentType   = @TipoOperacion
                      AND DocumentNumber = @numDoc;

                    IF @existingPayableId IS NOT NULL
                    BEGIN
                        UPDATE ap.PayableDocument
                        SET SupplierId       = @SupplierId,
                            IssueDate        = @docDate,
                            DueDate          = @docDate,
                            TotalAmount      = @totalAmount,
                            PendingAmount    = @safePending,
                            PaidFlag         = CASE WHEN @safePending <= 0 THEN 1 ELSE 0 END,
                            Status           = @status,
                            Notes            = @notes,
                            UpdatedAt        = SYSUTCDATETIME(),
                            UpdatedByUserId  = @UserId
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

                    -- Recalcular saldo total del proveedor
                    EXEC dbo.usp_Master_Supplier_UpdateBalance
                        @SupplierId      = @SupplierId,
                        @UpdatedByUserId = @UserId;
                END;
            END;
        END;

    COMMIT TRAN;

    SET @ok = 1;

    SELECT
        @ok             AS ok,
        @numDoc         AS numDoc,
        @detalleRows    AS detalleRows,
        @formasPagoRows AS formasPagoRows,
        @pendingAmount  AS pendingAmount;
END;
GO

-- =============================================================================
-- 9. usp_Doc_PurchaseDocument_ConvertOrder
-- Convierte una orden de compra en un documento de compra.
-- Copia cabecera y lineas de la orden, crea la compra, marca la orden como
-- recibida, y sincroniza ap.PayableDocument.
-- Operacion transaccional con XACT_ABORT.
--
-- Retorna: ok, orden, compra, detalleRows, formasPagoRows, pendingAmount, mensaje
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Doc_PurchaseDocument_ConvertOrder
    @NumDocOrden         NVARCHAR(60),
    @NumDocCompra        NVARCHAR(60),
    @CompraOverrideJson  NVARCHAR(MAX) = NULL,
    @DetalleJson         NVARCHAR(MAX) = NULL,
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

    -- Validar parametros
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

    -- Validar que la orden existe
    IF NOT EXISTS (
        SELECT 1 FROM doc.PurchaseDocument
        WHERE DocumentNumber = @NumDocOrden
          AND OperationType = 'ORDEN'
          AND IsDeleted = 0
    )
    BEGIN
        SET @mensaje = 'Orden de compra no encontrada: ' + @NumDocOrden;
        SELECT @ok AS ok, @NumDocOrden AS orden, @NumDocCompra AS compra,
               @detalleRows AS detalleRows, @formasPagoRows AS formasPagoRows,
               @pendingAmount AS pendingAmount, @mensaje AS mensaje;
        RETURN;
    END;

    -- Validar que la orden no esta anulada
    IF EXISTS (
        SELECT 1 FROM doc.PurchaseDocument
        WHERE DocumentNumber = @NumDocOrden
          AND OperationType = 'ORDEN'
          AND IsDeleted = 0
          AND IsVoided = 1
    )
    BEGIN
        SET @mensaje = 'La orden esta anulada y no puede convertirse: ' + @NumDocOrden;
        SELECT @ok AS ok, @NumDocOrden AS orden, @NumDocCompra AS compra,
               @detalleRows AS detalleRows, @formasPagoRows AS formasPagoRows,
               @pendingAmount AS pendingAmount, @mensaje AS mensaje;
        RETURN;
    END;

    BEGIN TRAN;

        -- ---------------------------------------------------------------
        -- 1. Eliminar compra existente si la hubiera (idempotente)
        -- ---------------------------------------------------------------
        DELETE FROM doc.PurchaseDocumentPayment
        WHERE DocumentNumber = @NumDocCompra AND OperationType = 'COMPRA';

        DELETE FROM doc.PurchaseDocumentLine
        WHERE DocumentNumber = @NumDocCompra AND OperationType = 'COMPRA';

        DELETE FROM doc.PurchaseDocument
        WHERE DocumentNumber = @NumDocCompra AND OperationType = 'COMPRA';

        -- ---------------------------------------------------------------
        -- 2. Copiar cabecera de la orden como nueva compra
        --    Se aplican overrides del JSON si se proporcionaron
        -- ---------------------------------------------------------------
        INSERT INTO doc.PurchaseDocument (
            DocumentNumber, SerialType, OperationType,
            SupplierCode, SupplierName, FiscalId,
            DocumentDate, DueDate, ReceiptDate, PaymentDate, DocumentTime,
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
            COALESCE(ov.SupplierCode, o.SupplierCode),
            COALESCE(ov.SupplierName, o.SupplierName),
            COALESCE(ov.FiscalId, o.FiscalId),
            ISNULL(ov.DocumentDate, GETDATE()),
            COALESCE(ov.DueDate, o.DueDate),
            COALESCE(ov.ReceiptDate, o.ReceiptDate),
            COALESCE(ov.PaymentDate, o.PaymentDate),
            ISNULL(ov.DocumentTime, CONVERT(NVARCHAR(8), GETDATE(), 108)),
            COALESCE(ov.SubTotal, o.SubTotal),
            COALESCE(ov.TaxableAmount, o.TaxableAmount),
            COALESCE(ov.ExemptAmount, o.ExemptAmount),
            COALESCE(ov.TaxAmount, o.TaxAmount),
            COALESCE(ov.TaxRate, o.TaxRate),
            COALESCE(ov.TotalAmount, o.TotalAmount),
            COALESCE(ov.DiscountAmount, o.DiscountAmount),
            0,                                              -- IsVoided = No
            ISNULL(ov.IsPaid, 'N'),
            'N',                                            -- IsReceived
            COALESCE(ov.IsLegal, o.IsLegal),
            @NumDocOrden,                                   -- OriginDocumentNumber
            COALESCE(ov.ControlNumber, o.ControlNumber),
            o.VoucherNumber,
            o.VoucherDate,
            o.RetainedTax,
            o.IsrCode,
            o.IsrAmount,
            o.IsrSubjectCode,
            o.IsrSubjectAmount,
            o.RetentionRate,
            o.ImportAmount,
            o.ImportTax,
            o.ImportBase,
            o.FreightAmount,
            COALESCE(ov.Notes, o.Notes),
            o.Concept,
            o.OrderNumber,
            o.ReceivedBy,
            COALESCE(ov.WarehouseCode, o.WarehouseCode),
            ISNULL(o.CurrencyCode, 'BS'),
            ISNULL(o.ExchangeRate, 1),
            o.UsdAmount,
            @CodUsuario,
            o.ShortUserCode,
            GETDATE(),
            HOST_NAME(),
            SYSUTCDATETIME(),
            SYSUTCDATETIME()
        FROM doc.PurchaseDocument o
        OUTER APPLY (
            SELECT *
            FROM OPENJSON(ISNULL(@CompraOverrideJson, '{}'))
            WITH (
                SupplierCode    NVARCHAR(60)   '$.SupplierCode',
                SupplierName    NVARCHAR(255)  '$.SupplierName',
                FiscalId        NVARCHAR(15)   '$.FiscalId',
                DocumentDate    DATETIME       '$.DocumentDate',
                DueDate         DATETIME       '$.DueDate',
                ReceiptDate     DATETIME       '$.ReceiptDate',
                PaymentDate     DATETIME       '$.PaymentDate',
                DocumentTime    NVARCHAR(20)   '$.DocumentTime',
                SubTotal        FLOAT          '$.SubTotal',
                TaxableAmount   FLOAT          '$.TaxableAmount',
                ExemptAmount    FLOAT          '$.ExemptAmount',
                TaxAmount       FLOAT          '$.TaxAmount',
                TaxRate         FLOAT          '$.TaxRate',
                TotalAmount     FLOAT          '$.TotalAmount',
                DiscountAmount  FLOAT          '$.DiscountAmount',
                IsPaid          NVARCHAR(1)    '$.IsPaid',
                IsLegal         BIT            '$.IsLegal',
                ControlNumber   NVARCHAR(60)   '$.ControlNumber',
                Notes           NVARCHAR(500)  '$.Notes',
                WarehouseCode   NVARCHAR(50)   '$.WarehouseCode'
            )
        ) AS ov
        WHERE o.DocumentNumber = @NumDocOrden
          AND o.OperationType = 'ORDEN'
          AND o.IsDeleted = 0;

        -- ---------------------------------------------------------------
        -- 3. Copiar lineas de detalle (desde JSON o desde la orden)
        -- ---------------------------------------------------------------
        IF @DetalleJson IS NOT NULL AND LEN(@DetalleJson) > 2
        BEGIN
            -- Usar detalle proporcionado
            INSERT INTO doc.PurchaseDocumentLine (
                DocumentNumber, OperationType, LineNumber,
                ProductCode, Description,
                Quantity, UnitPrice, UnitCost,
                SubTotal, DiscountAmount, TotalAmount,
                TaxRate, TaxAmount,
                IsVoided, UserCode, LineDate,
                CreatedAt, UpdatedAt
            )
            SELECT
                @NumDocCompra,
                'COMPRA',
                j.LineNumber,
                j.ProductCode,
                j.Description,
                ISNULL(j.Quantity, 0),
                ISNULL(j.UnitPrice, 0),
                ISNULL(j.UnitCost, 0),
                ISNULL(j.SubTotal, 0),
                ISNULL(j.DiscountAmount, 0),
                ISNULL(j.TotalAmount, 0),
                ISNULL(j.TaxRate, 0),
                ISNULL(j.TaxAmount, 0),
                ISNULL(j.IsVoided, 0),
                @CodUsuario,
                GETDATE(),
                SYSUTCDATETIME(),
                SYSUTCDATETIME()
            FROM OPENJSON(@DetalleJson)
            WITH (
                LineNumber      INT            '$.LineNumber',
                ProductCode     NVARCHAR(60)   '$.ProductCode',
                Description     NVARCHAR(255)  '$.Description',
                Quantity        FLOAT          '$.Quantity',
                UnitPrice       FLOAT          '$.UnitPrice',
                UnitCost        FLOAT          '$.UnitCost',
                SubTotal        FLOAT          '$.SubTotal',
                DiscountAmount  FLOAT          '$.DiscountAmount',
                TotalAmount     FLOAT          '$.TotalAmount',
                TaxRate         FLOAT          '$.TaxRate',
                TaxAmount       FLOAT          '$.TaxAmount',
                IsVoided        BIT            '$.IsVoided'
            ) AS j;

            SET @detalleRows = @@ROWCOUNT;
        END
        ELSE
        BEGIN
            -- Copiar lineas de la orden
            INSERT INTO doc.PurchaseDocumentLine (
                DocumentNumber, OperationType, LineNumber,
                ProductCode, Description,
                Quantity, UnitPrice, UnitCost,
                SubTotal, DiscountAmount, TotalAmount,
                TaxRate, TaxAmount,
                IsVoided, UserCode, LineDate,
                CreatedAt, UpdatedAt
            )
            SELECT
                @NumDocCompra,
                'COMPRA',
                ol.LineNumber,
                ol.ProductCode,
                ol.Description,
                ol.Quantity,
                ol.UnitPrice,
                ol.UnitCost,
                ol.SubTotal,
                ol.DiscountAmount,
                ol.TotalAmount,
                ol.TaxRate,
                ol.TaxAmount,
                0,                          -- IsVoided = No
                @CodUsuario,
                GETDATE(),
                SYSUTCDATETIME(),
                SYSUTCDATETIME()
            FROM doc.PurchaseDocumentLine ol
            WHERE ol.DocumentNumber = @NumDocOrden
              AND ol.OperationType = 'ORDEN'
              AND ol.IsDeleted = 0;

            SET @detalleRows = @@ROWCOUNT;
        END;

        -- Validar que se copiaron lineas
        IF @detalleRows = 0
        BEGIN
            ROLLBACK TRAN;
            SET @mensaje = 'La orden no tiene lineas de detalle: ' + @NumDocOrden;
            SELECT @ok AS ok, @NumDocOrden AS orden, @NumDocCompra AS compra,
                   @detalleRows AS detalleRows, @formasPagoRows AS formasPagoRows,
                   @pendingAmount AS pendingAmount, @mensaje AS mensaje;
            RETURN;
        END;

        -- ---------------------------------------------------------------
        -- 4. Marcar la orden como recibida
        -- ---------------------------------------------------------------
        UPDATE doc.PurchaseDocument
        SET IsReceived = 'S',
            Notes      = CONCAT(ISNULL(Notes, ''), ' | Convertida a compra ', @NumDocCompra,
                          ' el ', FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm'),
                          ' por ', @CodUsuario),
            UpdatedAt  = SYSUTCDATETIME()
        WHERE DocumentNumber = @NumDocOrden
          AND OperationType = 'ORDEN'
          AND IsDeleted = 0;

        -- ---------------------------------------------------------------
        -- 5. Sincronizar ap.PayableDocument para la compra creada
        -- ---------------------------------------------------------------
        DECLARE @cTotalAmount   FLOAT;
        DECLARE @cSupplierCode  NVARCHAR(60);
        DECLARE @cIsPaid        NVARCHAR(1);
        DECLARE @cDocDate       DATETIME;
        DECLARE @cNotes         NVARCHAR(500);

        SELECT
            @cTotalAmount  = TotalAmount,
            @cSupplierCode = SupplierCode,
            @cIsPaid       = ISNULL(IsPaid, 'N'),
            @cDocDate      = DocumentDate,
            @cNotes        = Notes
        FROM doc.PurchaseDocument
        WHERE DocumentNumber = @NumDocCompra
          AND OperationType = 'COMPRA';

        SET @pendingAmount = CASE WHEN UPPER(@cIsPaid) = 'S' THEN 0 ELSE @cTotalAmount END;

        IF @cSupplierCode IS NOT NULL AND LTRIM(RTRIM(@cSupplierCode)) <> ''
        BEGIN
            DECLARE @cCompanyId INT;
            DECLARE @cBranchId  INT;
            DECLARE @cUserId    INT = NULL;

            SELECT TOP 1 @cCompanyId = c.CompanyId
            FROM cfg.Company c
            WHERE c.IsDeleted = 0 AND c.IsActive = 1
            ORDER BY CASE WHEN c.CompanyCode = 'DEFAULT' THEN 0 ELSE 1 END, c.CompanyId;

            SELECT TOP 1 @cBranchId = b.BranchId
            FROM cfg.Branch b
            WHERE b.CompanyId = @cCompanyId AND b.IsDeleted = 0 AND b.IsActive = 1
            ORDER BY CASE WHEN b.BranchCode = 'MAIN' THEN 0 ELSE 1 END, b.BranchId;

            SELECT TOP 1 @cUserId = UserId
            FROM sec.[User]
            WHERE UserCode = @CodUsuario AND IsDeleted = 0;

            DECLARE @cSupplierId BIGINT = NULL;

            SELECT TOP 1 @cSupplierId = SupplierId
            FROM [master].Supplier
            WHERE SupplierCode = @cSupplierCode
              AND CompanyId = @cCompanyId
              AND IsDeleted = 0;

            IF @cSupplierId IS NOT NULL AND @cCompanyId IS NOT NULL AND @cBranchId IS NOT NULL
            BEGIN
                DECLARE @cSafePending FLOAT = CASE WHEN @pendingAmount < 0 THEN 0 ELSE @pendingAmount END;
                DECLARE @cStatus NVARCHAR(20) = CASE
                    WHEN @cSafePending <= 0 THEN 'PAID'
                    WHEN @cSafePending < @cTotalAmount THEN 'PARTIAL'
                    ELSE 'PENDING'
                END;

                -- Verificar si ya existe
                DECLARE @cExistingPayableId BIGINT = NULL;

                SELECT TOP 1 @cExistingPayableId = PayableDocumentId
                FROM ap.PayableDocument
                WHERE CompanyId      = @cCompanyId
                  AND BranchId       = @cBranchId
                  AND DocumentType   = 'COMPRA'
                  AND DocumentNumber = @NumDocCompra;

                IF @cExistingPayableId IS NOT NULL
                BEGIN
                    UPDATE ap.PayableDocument
                    SET SupplierId       = @cSupplierId,
                        IssueDate        = @cDocDate,
                        DueDate          = @cDocDate,
                        TotalAmount      = @cTotalAmount,
                        PendingAmount    = @cSafePending,
                        PaidFlag         = CASE WHEN @cSafePending <= 0 THEN 1 ELSE 0 END,
                        Status           = @cStatus,
                        Notes            = @cNotes,
                        UpdatedAt        = SYSUTCDATETIME(),
                        UpdatedByUserId  = @cUserId
                    WHERE PayableDocumentId = @cExistingPayableId;
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
                        @cCompanyId, @cBranchId, @cSupplierId,
                        'COMPRA', @NumDocCompra,
                        @cDocDate, @cDocDate, 'USD',
                        @cTotalAmount, @cSafePending,
                        CASE WHEN @cSafePending <= 0 THEN 1 ELSE 0 END,
                        @cStatus, @cNotes,
                        SYSUTCDATETIME(), SYSUTCDATETIME(), @cUserId, @cUserId
                    );
                END;

                -- Recalcular saldo total del proveedor
                EXEC dbo.usp_Master_Supplier_UpdateBalance
                    @SupplierId      = @cSupplierId,
                    @UpdatedByUserId = @cUserId;
            END;
        END;

    COMMIT TRAN;

    SET @ok = 1;
    SET @mensaje = 'Compra ' + @NumDocCompra + ' generada exitosamente desde orden ' + @NumDocOrden;

    SELECT
        @ok             AS ok,
        @NumDocOrden    AS orden,
        @NumDocCompra   AS compra,
        @detalleRows    AS detalleRows,
        @formasPagoRows AS formasPagoRows,
        @pendingAmount  AS pendingAmount,
        @mensaje        AS mensaje;
END;
GO
