-- =============================================================================
-- usp_doc_sales.sql
-- Procedimientos almacenados para documentos de venta (tablas canonicas doc.*)
-- Tablas: doc.SalesDocument, doc.SalesDocumentLine, doc.SalesDocumentPayment
-- Base de datos: DatqBoxWeb
--
-- Clave unica SalesDocument: (DocumentNumber, SerialType, FiscalMemoryNumber, OperationType)
-- Para WHERE simplificado se usa: DocumentNumber + OperationType
--   (SerialType defaults to '', FiscalMemoryNumber defaults to '1')
--
-- Procedimientos:
--   1. usp_Doc_SalesDocument_List          - Lista paginada con filtros
--   2. usp_Doc_SalesDocument_Get           - Obtener documento individual
--   3. usp_Doc_SalesDocument_GetDetail     - Obtener lineas de detalle
--   4. usp_Doc_SalesDocument_GetPayments   - Obtener formas de pago
--   5. usp_Doc_SalesDocument_Void          - Anular documento (transaccional)
--   6. usp_Doc_SalesDocument_InvoiceFromOrder - Facturar desde pedido (transaccional)
-- =============================================================================

USE DatqBoxWeb;
GO

-- =============================================================================
-- 1. usp_Doc_SalesDocument_List
-- Lista paginada de documentos de venta con filtros por tipo, busqueda,
-- codigo de cliente, y rango de fechas.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Doc_SalesDocument_List
    @TipoOperacion  NVARCHAR(20),
    @Search         NVARCHAR(100) = NULL,
    @Codigo         NVARCHAR(60)  = NULL,
    @FromDate       DATE          = NULL,
    @ToDate         DATE          = NULL,
    @Estado         NVARCHAR(20)  = NULL,
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
    FROM doc.SalesDocument
    WHERE OperationType = @TipoOperacion
      AND IsDeleted = 0
      AND (@Search IS NULL OR (
            DocumentNumber LIKE '%' + @Search + '%'
            OR CustomerName LIKE '%' + @Search + '%'
            OR FiscalId LIKE '%' + @Search + '%'
          ))
      AND (@Codigo IS NULL OR CustomerCode = @Codigo)
      AND (@FromDate IS NULL OR DocumentDate >= @FromDate)
      AND (@ToDate IS NULL OR DocumentDate < DATEADD(DAY, 1, @ToDate))
      AND (@Estado IS NULL OR
        CASE
          WHEN IsVoided = 1 THEN 'Anulada'
          WHEN IsPaid = 1 THEN 'Pagada'
          ELSE 'Emitida'
        END = @Estado);

    -- Obtener pagina de resultados
    SELECT *
    FROM doc.SalesDocument
    WHERE OperationType = @TipoOperacion
      AND IsDeleted = 0
      AND (@Search IS NULL OR (
            DocumentNumber LIKE '%' + @Search + '%'
            OR CustomerName LIKE '%' + @Search + '%'
            OR FiscalId LIKE '%' + @Search + '%'
          ))
      AND (@Codigo IS NULL OR CustomerCode = @Codigo)
      AND (@FromDate IS NULL OR DocumentDate >= @FromDate)
      AND (@ToDate IS NULL OR DocumentDate < DATEADD(DAY, 1, @ToDate))
      AND (@Estado IS NULL OR
        CASE
          WHEN IsVoided = 1 THEN 'Anulada'
          WHEN IsPaid = 1 THEN 'Pagada'
          ELSE 'Emitida'
        END = @Estado)
    ORDER BY DocumentDate DESC, DocumentNumber DESC
    OFFSET (@Page - 1) * @Limit ROWS
    FETCH NEXT @Limit ROWS ONLY;
END;
GO

-- =============================================================================
-- 2. usp_Doc_SalesDocument_Get
-- Obtener un documento de venta individual por numero y tipo de operacion.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Doc_SalesDocument_Get
    @TipoOperacion  NVARCHAR(20),
    @NumDoc         NVARCHAR(60)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 1 *
    FROM doc.SalesDocument
    WHERE DocumentNumber = @NumDoc
      AND OperationType = @TipoOperacion
      AND IsDeleted = 0;
END;
GO

-- =============================================================================
-- 3. usp_Doc_SalesDocument_GetDetail
-- Obtener las lineas de detalle de un documento de venta.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Doc_SalesDocument_GetDetail
    @TipoOperacion  NVARCHAR(20),
    @NumDoc         NVARCHAR(60)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT *
    FROM doc.SalesDocumentLine
    WHERE DocumentNumber = @NumDoc
      AND OperationType = @TipoOperacion
      AND IsDeleted = 0
    ORDER BY ISNULL(LineNumber, 0), LineId;
END;
GO

-- =============================================================================
-- 4. usp_Doc_SalesDocument_GetPayments
-- Obtener las formas de pago de un documento de venta.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Doc_SalesDocument_GetPayments
    @TipoOperacion  NVARCHAR(20),
    @NumDoc         NVARCHAR(60)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT *
    FROM doc.SalesDocumentPayment
    WHERE DocumentNumber = @NumDoc
      AND OperationType = @TipoOperacion
      AND IsDeleted = 0;
END;
GO

-- =============================================================================
-- 5. usp_Doc_SalesDocument_Void
-- Anular un documento de venta. Actualiza el documento, sus lineas,
-- la cuenta por cobrar (ar.ReceivableDocument) y el saldo del cliente.
-- Operacion transaccional con XACT_ABORT.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Doc_SalesDocument_Void
    @TipoOperacion  NVARCHAR(20),
    @NumDoc         NVARCHAR(60),
    @CodUsuario     NVARCHAR(60)  = 'API',
    @Motivo         NVARCHAR(500) = ''
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @ok          BIT           = 0;
    DECLARE @numFact     NVARCHAR(60)  = @NumDoc;
    DECLARE @codCliente  NVARCHAR(60)  = NULL;
    DECLARE @mensaje     NVARCHAR(500) = '';

    -- Validar que el documento existe y no esta ya anulado
    IF NOT EXISTS (
        SELECT 1 FROM doc.SalesDocument
        WHERE DocumentNumber = @NumDoc
          AND OperationType = @TipoOperacion
          AND IsDeleted = 0
    )
    BEGIN
        SET @mensaje = 'Documento no encontrado: ' + @NumDoc + ' / ' + @TipoOperacion;
        SELECT @ok AS ok, @numFact AS numFact, @codCliente AS codCliente, @mensaje AS mensaje;
        RETURN;
    END;

    IF EXISTS (
        SELECT 1 FROM doc.SalesDocument
        WHERE DocumentNumber = @NumDoc
          AND OperationType = @TipoOperacion
          AND IsDeleted = 0
          AND IsVoided = 1
    )
    BEGIN
        SET @mensaje = 'El documento ya se encuentra anulado: ' + @NumDoc;
        SELECT @ok AS ok, @numFact AS numFact, @codCliente AS codCliente, @mensaje AS mensaje;
        RETURN;
    END;

    -- Obtener codigo de cliente
    SELECT @codCliente = CustomerCode
    FROM doc.SalesDocument
    WHERE DocumentNumber = @NumDoc
      AND OperationType = @TipoOperacion
      AND IsDeleted = 0;

    BEGIN TRAN;

        -- Anular cabecera del documento
        UPDATE doc.SalesDocument
        SET IsVoided  = 1,
            Notes     = CONCAT(ISNULL(Notes, ''), ' | ANULADO ', FORMAT(SYSUTCDATETIME(), 'yyyy-MM-dd HH:mm'),
                         ' por ', @CodUsuario,
                         CASE WHEN @Motivo <> '' THEN ' - Motivo: ' + @Motivo ELSE '' END),
            UpdatedAt = SYSUTCDATETIME()
        WHERE DocumentNumber = @NumDoc
          AND OperationType = @TipoOperacion
          AND IsDeleted = 0;

        -- Anular lineas del documento
        UPDATE doc.SalesDocumentLine
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

        -- Resolver CustomerId desde master.Customer
        DECLARE @CustomerId BIGINT = NULL;

        SELECT TOP 1 @CustomerId = CustomerId
        FROM [master].Customer
        WHERE CustomerCode = @codCliente
          AND CompanyId = @CompanyId
          AND IsDeleted = 0;

        -- Actualizar cuenta por cobrar si existe
        IF @CustomerId IS NOT NULL AND @CompanyId IS NOT NULL AND @BranchId IS NOT NULL
        BEGIN
            UPDATE ar.ReceivableDocument
            SET PendingAmount = 0,
                PaidFlag      = 1,
                Status        = 'VOIDED',
                UpdatedAt     = SYSUTCDATETIME()
            WHERE CompanyId      = @CompanyId
              AND BranchId       = @BranchId
              AND DocumentNumber = @NumDoc
              AND DocumentType   = @TipoOperacion
              AND CustomerId     = @CustomerId;

            -- Recalcular saldo total del cliente
            UPDATE [master].Customer
            SET TotalBalance = ISNULL((
                    SELECT SUM(PendingAmount)
                    FROM ar.ReceivableDocument
                    WHERE CustomerId = @CustomerId
                      AND Status <> 'VOIDED'
                ), 0),
                UpdatedAt = SYSUTCDATETIME()
            WHERE CustomerId = @CustomerId;
        END;

    COMMIT TRAN;

    SET @ok = 1;
    SET @mensaje = 'Documento anulado exitosamente: ' + @NumDoc;

    SELECT @ok AS ok, @numFact AS numFact, @codCliente AS codCliente, @mensaje AS mensaje;
END;
GO

-- =============================================================================
-- 6. usp_Doc_SalesDocument_InvoiceFromOrder
-- Convertir un PEDIDO en FACTURA. Copia cabecera, lineas e inserta formas
-- de pago desde JSON opcional. Marca el pedido como facturado.
-- Operacion transaccional con XACT_ABORT.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Doc_SalesDocument_InvoiceFromOrder
    @NumDocPedido   NVARCHAR(60),
    @NumDocFactura  NVARCHAR(60),
    @FormasPagoJson NVARCHAR(MAX) = NULL,
    @CodUsuario     NVARCHAR(60)  = 'API'
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @ok      BIT           = 0;
    DECLARE @pedido  NVARCHAR(60)  = @NumDocPedido;
    DECLARE @factura NVARCHAR(60)  = @NumDocFactura;
    DECLARE @mensaje NVARCHAR(500) = '';

    -- Validar que el pedido existe
    IF NOT EXISTS (
        SELECT 1 FROM doc.SalesDocument
        WHERE DocumentNumber = @NumDocPedido
          AND OperationType = 'PEDIDO'
          AND IsDeleted = 0
    )
    BEGIN
        SET @mensaje = 'Pedido no encontrado: ' + @NumDocPedido;
        SELECT @ok AS ok, @pedido AS pedido, @factura AS factura, @mensaje AS mensaje;
        RETURN;
    END;

    -- Validar que el pedido no esta anulado
    IF EXISTS (
        SELECT 1 FROM doc.SalesDocument
        WHERE DocumentNumber = @NumDocPedido
          AND OperationType = 'PEDIDO'
          AND IsDeleted = 0
          AND IsVoided = 1
    )
    BEGIN
        SET @mensaje = 'El pedido esta anulado y no puede facturarse: ' + @NumDocPedido;
        SELECT @ok AS ok, @pedido AS pedido, @factura AS factura, @mensaje AS mensaje;
        RETURN;
    END;

    -- Validar que el pedido no fue ya facturado
    IF EXISTS (
        SELECT 1 FROM doc.SalesDocument
        WHERE DocumentNumber = @NumDocPedido
          AND OperationType = 'PEDIDO'
          AND IsDeleted = 0
          AND IsInvoiced = 'S'
    )
    BEGIN
        SET @mensaje = 'El pedido ya fue facturado previamente: ' + @NumDocPedido;
        SELECT @ok AS ok, @pedido AS pedido, @factura AS factura, @mensaje AS mensaje;
        RETURN;
    END;

    BEGIN TRAN;

        -- Copiar cabecera del pedido como nueva factura
        INSERT INTO doc.SalesDocument (
            DocumentNumber, SerialType, FiscalMemoryNumber, OperationType,
            CustomerCode, CustomerName, FiscalId,
            DocumentDate, DueDate, DocumentTime,
            SubTotal, TaxableAmount, ExemptAmount, TaxAmount, TaxRate, TotalAmount, DiscountAmount,
            IsVoided, IsPaid, IsInvoiced, IsDelivered,
            OriginDocumentNumber, OriginDocumentType,
            ControlNumber, IsLegal, IsPrinted,
            Notes, Concept, PaymentTerms, ShipToAddress,
            SellerCode, DepartmentCode, LocationCode,
            CurrencyCode, ExchangeRate,
            UserCode, ReportDate, HostName,
            VehiclePlate, Mileage, TollAmount,
            CreatedAt, UpdatedAt
        )
        SELECT
            @NumDocFactura,                     -- DocumentNumber (nueva factura)
            SerialType,
            FiscalMemoryNumber,
            'FACT',                             -- OperationType
            CustomerCode, CustomerName, FiscalId,
            SYSUTCDATETIME(),                          -- DocumentDate (fecha actual)
            DueDate,
            CONVERT(NVARCHAR(8), SYSUTCDATETIME(), 108), -- DocumentTime
            SubTotal, TaxableAmount, ExemptAmount, TaxAmount, TaxRate, TotalAmount, DiscountAmount,
            0,                                  -- IsVoided = No
            'N',                                -- IsPaid
            'N',                                -- IsInvoiced
            'N',                                -- IsDelivered
            @NumDocPedido,                      -- OriginDocumentNumber
            'PEDIDO',                           -- OriginDocumentType
            ControlNumber, IsLegal, 0,          -- IsPrinted = No
            Notes, Concept, PaymentTerms, ShipToAddress,
            SellerCode, DepartmentCode, LocationCode,
            CurrencyCode, ExchangeRate,
            @CodUsuario,                        -- UserCode
            SYSUTCDATETIME(),
            HOST_NAME(),
            VehiclePlate, Mileage, TollAmount,
            SYSUTCDATETIME(), SYSUTCDATETIME()
        FROM doc.SalesDocument
        WHERE DocumentNumber = @NumDocPedido
          AND OperationType = 'PEDIDO'
          AND IsDeleted = 0;

        -- Copiar lineas del pedido a la factura
        INSERT INTO doc.SalesDocumentLine (
            DocumentNumber, SerialType, FiscalMemoryNumber, OperationType,
            LineNumber, ProductCode, Description, AlternateCode,
            Quantity, UnitPrice, DiscountedPrice, UnitCost,
            SubTotal, DiscountAmount, TotalAmount,
            TaxRate, TaxAmount,
            IsVoided, RelatedRef,
            UserCode, LineDate,
            CreatedAt, UpdatedAt
        )
        SELECT
            @NumDocFactura,                     -- DocumentNumber (nueva factura)
            SerialType,
            FiscalMemoryNumber,
            'FACT',                             -- OperationType
            LineNumber, ProductCode, Description, AlternateCode,
            Quantity, UnitPrice, DiscountedPrice, UnitCost,
            SubTotal, DiscountAmount, TotalAmount,
            TaxRate, TaxAmount,
            0,                                  -- IsVoided = No
            RelatedRef,
            @CodUsuario,
            SYSUTCDATETIME(),
            SYSUTCDATETIME(), SYSUTCDATETIME()
        FROM doc.SalesDocumentLine
        WHERE DocumentNumber = @NumDocPedido
          AND OperationType = 'PEDIDO'
          AND IsDeleted = 0;

        -- Insertar formas de pago desde JSON si se proporcionaron
        IF @FormasPagoJson IS NOT NULL AND LEN(@FormasPagoJson) > 2
        BEGIN
            INSERT INTO doc.SalesDocumentPayment (
                DocumentNumber, SerialType, FiscalMemoryNumber, OperationType,
                PaymentMethod, BankCode, PaymentNumber,
                Amount, AmountBs, ExchangeRate,
                PaymentDate, DueDate,
                ReferenceNumber, UserCode,
                CreatedAt, UpdatedAt
            )
            SELECT
                @NumDocFactura,
                ISNULL(j.SerialType, ''),
                ISNULL(j.FiscalMemoryNumber, '1'),
                'FACT',
                j.PaymentMethod,
                j.BankCode,
                j.PaymentNumber,
                ISNULL(j.Amount, 0),
                ISNULL(j.AmountBs, 0),
                ISNULL(j.ExchangeRate, 1),
                ISNULL(j.PaymentDate, SYSUTCDATETIME()),
                j.DueDate,
                j.ReferenceNumber,
                @CodUsuario,
                SYSUTCDATETIME(), SYSUTCDATETIME()
            FROM OPENJSON(@FormasPagoJson)
            WITH (
                SerialType          NVARCHAR(60)  '$.serialType',
                FiscalMemoryNumber  NVARCHAR(10)  '$.fiscalMemoryNumber',
                PaymentMethod       NVARCHAR(30)  '$.paymentMethod',
                BankCode            NVARCHAR(60)  '$.bankCode',
                PaymentNumber       NVARCHAR(60)  '$.paymentNumber',
                Amount              FLOAT         '$.amount',
                AmountBs            FLOAT         '$.amountBs',
                ExchangeRate        FLOAT         '$.exchangeRate',
                PaymentDate         DATETIME      '$.paymentDate',
                DueDate             DATETIME      '$.dueDate',
                ReferenceNumber     NVARCHAR(100) '$.referenceNumber'
            ) AS j;
        END;

        -- Marcar el pedido como facturado
        UPDATE doc.SalesDocument
        SET IsInvoiced = 'S',
            Notes      = CONCAT(ISNULL(Notes, ''), ' | Facturado como ', @NumDocFactura,
                          ' el ', FORMAT(SYSUTCDATETIME(), 'yyyy-MM-dd HH:mm'),
                          ' por ', @CodUsuario),
            UpdatedAt  = SYSUTCDATETIME()
        WHERE DocumentNumber = @NumDocPedido
          AND OperationType = 'PEDIDO'
          AND IsDeleted = 0;

    COMMIT TRAN;

    SET @ok = 1;
    SET @mensaje = 'Factura ' + @NumDocFactura + ' generada exitosamente desde pedido ' + @NumDocPedido;

    SELECT @ok AS ok, @pedido AS pedido, @factura AS factura, @mensaje AS mensaje;
END;
GO

-- =============================================================================
-- 7. usp_Doc_SalesDocument_Upsert
-- Insertar o reemplazar un documento de venta completo (cabecera, detalle,
-- formas de pago). Para tipos FACT/NOTADEB/NOTACRED sincroniza la cuenta
-- por cobrar (ar.ReceivableDocument) y actualiza el saldo del cliente.
-- Reemplaza la logica TS de upsertDocumentoVentaTx + syncReceivableDocumentTx.
-- Operacion transaccional con XACT_ABORT.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Doc_SalesDocument_Upsert
    @TipoOperacion   NVARCHAR(20),
    @HeaderJson      NVARCHAR(MAX),
    @DetailJson      NVARCHAR(MAX),
    @PaymentsJson    NVARCHAR(MAX)  = NULL,
    @DocOrigen       NVARCHAR(60)   = NULL,
    @TipoDocOrigen   NVARCHAR(20)   = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @ok             BIT            = 0;
    DECLARE @numDoc         NVARCHAR(60);
    DECLARE @detalleRows    INT            = 0;
    DECLARE @formasPagoRows INT            = 0;
    DECLARE @pendingAmount  DECIMAL(18,4)  = 0;
    DECLARE @mensaje        NVARCHAR(500)  = '';

    -- =========================================================================
    -- 1. Parsear cabecera desde JSON
    -- =========================================================================
    DECLARE @SerialType             NVARCHAR(60);
    DECLARE @FiscalMemoryNumber     NVARCHAR(10);
    DECLARE @CustomerCode           NVARCHAR(60);
    DECLARE @CustomerName           NVARCHAR(200);
    DECLARE @FiscalId               NVARCHAR(60);
    DECLARE @DocumentDate           DATETIME;
    DECLARE @DueDate                DATETIME;
    DECLARE @DocumentTime           NVARCHAR(20);
    DECLARE @SubTotal               DECIMAL(18,4);
    DECLARE @TaxableAmount          DECIMAL(18,4);
    DECLARE @ExemptAmount           DECIMAL(18,4);
    DECLARE @TaxAmount              DECIMAL(18,4);
    DECLARE @TaxRate                DECIMAL(8,4);
    DECLARE @TotalAmount            DECIMAL(18,4);
    DECLARE @DiscountAmount         DECIMAL(18,4);
    DECLARE @IsVoided               BIT;
    DECLARE @IsPaid                 NVARCHAR(10);
    DECLARE @IsInvoiced             NVARCHAR(10);
    DECLARE @IsDelivered            NVARCHAR(10);
    DECLARE @OriginDocumentNumber   NVARCHAR(60);
    DECLARE @OriginDocumentType     NVARCHAR(20);
    DECLARE @ControlNumber          NVARCHAR(60);
    DECLARE @IsLegal                NVARCHAR(10);
    DECLARE @IsPrinted              BIT;
    DECLARE @Notes                  NVARCHAR(MAX);
    DECLARE @Concept                NVARCHAR(200);
    DECLARE @PaymentTerms           NVARCHAR(100);
    DECLARE @ShipToAddress          NVARCHAR(500);
    DECLARE @SellerCode             NVARCHAR(60);
    DECLARE @DepartmentCode         NVARCHAR(60);
    DECLARE @LocationCode           NVARCHAR(60);
    DECLARE @CurrencyCode           NVARCHAR(10);
    DECLARE @ExchangeRate           DECIMAL(18,6);
    DECLARE @UserCode               NVARCHAR(60);
    DECLARE @ReportDate             DATETIME;
    DECLARE @HostName               NVARCHAR(100);
    DECLARE @VehiclePlate           NVARCHAR(30);
    DECLARE @Mileage                DECIMAL(18,2);
    DECLARE @TollAmount             DECIMAL(18,4);

    SELECT
        @numDoc               = JSON_VALUE(@HeaderJson, '$.DocumentNumber'),
        @SerialType           = ISNULL(JSON_VALUE(@HeaderJson, '$.SerialType'), ''),
        @FiscalMemoryNumber   = ISNULL(JSON_VALUE(@HeaderJson, '$.FiscalMemoryNumber'), '1'),
        @CustomerCode         = JSON_VALUE(@HeaderJson, '$.CustomerCode'),
        @CustomerName         = JSON_VALUE(@HeaderJson, '$.CustomerName'),
        @FiscalId             = JSON_VALUE(@HeaderJson, '$.FiscalId'),
        @DocumentDate         = ISNULL(TRY_CAST(JSON_VALUE(@HeaderJson, '$.DocumentDate') AS DATETIME), SYSUTCDATETIME()),
        @DueDate              = TRY_CAST(JSON_VALUE(@HeaderJson, '$.DueDate') AS DATETIME),
        @DocumentTime         = JSON_VALUE(@HeaderJson, '$.DocumentTime'),
        @SubTotal             = ISNULL(TRY_CAST(JSON_VALUE(@HeaderJson, '$.SubTotal') AS DECIMAL(18,4)), 0),
        @TaxableAmount        = TRY_CAST(JSON_VALUE(@HeaderJson, '$.TaxableAmount') AS DECIMAL(18,4)),
        @ExemptAmount         = TRY_CAST(JSON_VALUE(@HeaderJson, '$.ExemptAmount') AS DECIMAL(18,4)),
        @TaxAmount            = ISNULL(TRY_CAST(JSON_VALUE(@HeaderJson, '$.TaxAmount') AS DECIMAL(18,4)), 0),
        @TaxRate              = ISNULL(TRY_CAST(JSON_VALUE(@HeaderJson, '$.TaxRate') AS DECIMAL(8,4)), 0),
        @TotalAmount          = ISNULL(TRY_CAST(JSON_VALUE(@HeaderJson, '$.TotalAmount') AS DECIMAL(18,4)), 0),
        @DiscountAmount       = TRY_CAST(JSON_VALUE(@HeaderJson, '$.DiscountAmount') AS DECIMAL(18,4)),
        @IsVoided             = ISNULL(TRY_CAST(JSON_VALUE(@HeaderJson, '$.IsVoided') AS BIT), 0),
        @IsPaid               = ISNULL(JSON_VALUE(@HeaderJson, '$.IsPaid'), 'N'),
        @IsInvoiced           = ISNULL(JSON_VALUE(@HeaderJson, '$.IsInvoiced'), 'N'),
        @IsDelivered          = ISNULL(JSON_VALUE(@HeaderJson, '$.IsDelivered'), 'N'),
        @OriginDocumentNumber = COALESCE(@DocOrigen, JSON_VALUE(@HeaderJson, '$.OriginDocumentNumber')),
        @OriginDocumentType   = COALESCE(@TipoDocOrigen, JSON_VALUE(@HeaderJson, '$.OriginDocumentType')),
        @ControlNumber        = JSON_VALUE(@HeaderJson, '$.ControlNumber'),
        @IsLegal              = JSON_VALUE(@HeaderJson, '$.IsLegal'),
        @IsPrinted            = TRY_CAST(JSON_VALUE(@HeaderJson, '$.IsPrinted') AS BIT),
        @Notes                = JSON_VALUE(@HeaderJson, '$.Notes'),
        @Concept              = JSON_VALUE(@HeaderJson, '$.Concept'),
        @PaymentTerms         = JSON_VALUE(@HeaderJson, '$.PaymentTerms'),
        @ShipToAddress        = JSON_VALUE(@HeaderJson, '$.ShipToAddress'),
        @SellerCode           = JSON_VALUE(@HeaderJson, '$.SellerCode'),
        @DepartmentCode       = JSON_VALUE(@HeaderJson, '$.DepartmentCode'),
        @LocationCode         = JSON_VALUE(@HeaderJson, '$.LocationCode'),
        @CurrencyCode         = JSON_VALUE(@HeaderJson, '$.CurrencyCode'),
        @ExchangeRate         = TRY_CAST(JSON_VALUE(@HeaderJson, '$.ExchangeRate') AS DECIMAL(18,6)),
        @UserCode             = JSON_VALUE(@HeaderJson, '$.UserCode'),
        @ReportDate           = ISNULL(TRY_CAST(JSON_VALUE(@HeaderJson, '$.ReportDate') AS DATETIME), SYSUTCDATETIME()),
        @HostName             = JSON_VALUE(@HeaderJson, '$.HostName'),
        @VehiclePlate         = JSON_VALUE(@HeaderJson, '$.VehiclePlate'),
        @Mileage              = TRY_CAST(JSON_VALUE(@HeaderJson, '$.Mileage') AS DECIMAL(18,2)),
        @TollAmount           = TRY_CAST(JSON_VALUE(@HeaderJson, '$.TollAmount') AS DECIMAL(18,4));

    -- 2. Validar DocumentNumber
    IF @numDoc IS NULL OR LTRIM(RTRIM(@numDoc)) = ''
    BEGIN
        SET @mensaje = 'DocumentNumber es requerido en el JSON de cabecera';
        SELECT @ok AS ok, @numDoc AS numDoc, @detalleRows AS detalleRows,
               @formasPagoRows AS formasPagoRows, @pendingAmount AS pendingAmount, @mensaje AS mensaje;
        RETURN;
    END;

    SET @numDoc = LTRIM(RTRIM(@numDoc));

    -- =========================================================================
    -- 3. Transaccion principal
    -- =========================================================================
    BEGIN TRAN;

        -- 3a. DELETE existente (detalle, pagos, cabecera)
        DELETE FROM doc.SalesDocumentLine
        WHERE DocumentNumber = @numDoc
          AND OperationType = @TipoOperacion;

        DELETE FROM doc.SalesDocumentPayment
        WHERE DocumentNumber = @numDoc
          AND OperationType = @TipoOperacion;

        DELETE FROM doc.SalesDocument
        WHERE DocumentNumber = @numDoc
          AND OperationType = @TipoOperacion;

        -- 3b. INSERT cabecera
        INSERT INTO doc.SalesDocument (
            DocumentNumber, SerialType, FiscalMemoryNumber, OperationType,
            CustomerCode, CustomerName, FiscalId,
            DocumentDate, DueDate, DocumentTime,
            SubTotal, TaxableAmount, ExemptAmount, TaxAmount, TaxRate,
            TotalAmount, DiscountAmount,
            IsVoided, IsPaid, IsInvoiced, IsDelivered,
            OriginDocumentNumber, OriginDocumentType,
            ControlNumber, IsLegal, IsPrinted,
            Notes, Concept, PaymentTerms, ShipToAddress,
            SellerCode, DepartmentCode, LocationCode,
            CurrencyCode, ExchangeRate,
            UserCode, ReportDate, HostName,
            VehiclePlate, Mileage, TollAmount,
            CreatedAt, UpdatedAt, IsDeleted
        )
        VALUES (
            @numDoc, @SerialType, @FiscalMemoryNumber, @TipoOperacion,
            @CustomerCode, @CustomerName, @FiscalId,
            @DocumentDate, @DueDate, @DocumentTime,
            @SubTotal, @TaxableAmount, @ExemptAmount, @TaxAmount, @TaxRate,
            @TotalAmount, @DiscountAmount,
            @IsVoided, @IsPaid, @IsInvoiced, @IsDelivered,
            @OriginDocumentNumber, @OriginDocumentType,
            @ControlNumber, @IsLegal, @IsPrinted,
            @Notes, @Concept, @PaymentTerms, @ShipToAddress,
            @SellerCode, @DepartmentCode, @LocationCode,
            @CurrencyCode, @ExchangeRate,
            @UserCode, @ReportDate, @HostName,
            @VehiclePlate, @Mileage, @TollAmount,
            SYSUTCDATETIME(), SYSUTCDATETIME(), 0
        );

        -- 3c. INSERT lineas de detalle desde JSON
        IF @DetailJson IS NOT NULL AND LEN(@DetailJson) > 2
        BEGIN
            INSERT INTO doc.SalesDocumentLine (
                DocumentNumber, SerialType, FiscalMemoryNumber, OperationType,
                LineNumber, ProductCode, Description, AlternateCode,
                Quantity, UnitPrice, DiscountedPrice, UnitCost,
                SubTotal, DiscountAmount, TotalAmount,
                TaxRate, TaxAmount,
                IsVoided, RelatedRef,
                UserCode, LineDate,
                CreatedAt, UpdatedAt, IsDeleted
            )
            SELECT
                @numDoc,
                ISNULL(j.SerialType, @SerialType),
                ISNULL(j.FiscalMemoryNumber, @FiscalMemoryNumber),
                @TipoOperacion,
                j.LineNumber,
                j.ProductCode,
                j.Description,
                j.AlternateCode,
                ISNULL(j.Quantity, 0),
                ISNULL(j.UnitPrice, 0),
                j.DiscountedPrice,
                j.UnitCost,
                ISNULL(j.SubTotal, 0),
                ISNULL(j.DiscountAmount, 0),
                ISNULL(j.TotalAmount, 0),
                ISNULL(j.TaxRate, 0),
                ISNULL(j.TaxAmount, 0),
                ISNULL(j.IsVoided, 0),
                j.RelatedRef,
                ISNULL(j.UserCode, @UserCode),
                ISNULL(j.LineDate, SYSUTCDATETIME()),
                SYSUTCDATETIME(), SYSUTCDATETIME(), 0
            FROM OPENJSON(@DetailJson)
            WITH (
                SerialType          NVARCHAR(60)   '$.SerialType',
                FiscalMemoryNumber  NVARCHAR(10)   '$.FiscalMemoryNumber',
                LineNumber          INT            '$.LineNumber',
                ProductCode         NVARCHAR(60)   '$.ProductCode',
                Description         NVARCHAR(500)  '$.Description',
                AlternateCode       NVARCHAR(60)   '$.AlternateCode',
                Quantity            DECIMAL(18,4)  '$.Quantity',
                UnitPrice           DECIMAL(18,4)  '$.UnitPrice',
                DiscountedPrice     DECIMAL(18,4)  '$.DiscountedPrice',
                UnitCost            DECIMAL(18,4)  '$.UnitCost',
                SubTotal            DECIMAL(18,4)  '$.SubTotal',
                DiscountAmount      DECIMAL(18,4)  '$.DiscountAmount',
                TotalAmount         DECIMAL(18,4)  '$.TotalAmount',
                TaxRate             DECIMAL(8,4)   '$.TaxRate',
                TaxAmount           DECIMAL(18,4)  '$.TaxAmount',
                IsVoided            BIT            '$.IsVoided',
                RelatedRef          NVARCHAR(100)  '$.RelatedRef',
                UserCode            NVARCHAR(60)   '$.UserCode',
                LineDate            DATETIME       '$.LineDate'
            ) AS j;

            SET @detalleRows = @@ROWCOUNT;
        END;

        -- 3d. INSERT formas de pago desde JSON
        IF @PaymentsJson IS NOT NULL AND LEN(@PaymentsJson) > 2
        BEGIN
            INSERT INTO doc.SalesDocumentPayment (
                DocumentNumber, SerialType, FiscalMemoryNumber, OperationType,
                PaymentMethod, BankCode, PaymentNumber,
                Amount, AmountBs, ExchangeRate,
                PaymentDate, DueDate,
                ReferenceNumber, UserCode,
                CreatedAt, UpdatedAt, IsDeleted
            )
            SELECT
                @numDoc,
                ISNULL(j.SerialType, @SerialType),
                ISNULL(j.FiscalMemoryNumber, @FiscalMemoryNumber),
                @TipoOperacion,
                j.PaymentMethod,
                j.BankCode,
                j.PaymentNumber,
                ISNULL(j.Amount, 0),
                ISNULL(j.AmountBs, 0),
                ISNULL(j.ExchangeRate, 1),
                ISNULL(j.PaymentDate, SYSUTCDATETIME()),
                j.DueDate,
                j.ReferenceNumber,
                ISNULL(j.UserCode, @UserCode),
                SYSUTCDATETIME(), SYSUTCDATETIME(), 0
            FROM OPENJSON(@PaymentsJson)
            WITH (
                SerialType          NVARCHAR(60)   '$.SerialType',
                FiscalMemoryNumber  NVARCHAR(10)   '$.FiscalMemoryNumber',
                PaymentMethod       NVARCHAR(30)   '$.PaymentMethod',
                BankCode            NVARCHAR(60)   '$.BankCode',
                PaymentNumber       NVARCHAR(60)   '$.PaymentNumber',
                Amount              DECIMAL(18,4)  '$.Amount',
                AmountBs            DECIMAL(18,4)  '$.AmountBs',
                ExchangeRate        DECIMAL(18,6)  '$.ExchangeRate',
                PaymentDate         DATETIME       '$.PaymentDate',
                DueDate             DATETIME       '$.DueDate',
                ReferenceNumber     NVARCHAR(100)  '$.ReferenceNumber',
                UserCode            NVARCHAR(60)   '$.UserCode'
            ) AS j;

            SET @formasPagoRows = @@ROWCOUNT;
        END;

        -- 3e. Sincronizar cuenta por cobrar para FACT/NOTADEB/NOTACRED
        IF @TipoOperacion IN ('FACT', 'NOTADEB', 'NOTACRED')
        BEGIN
            DECLARE @codCliente NVARCHAR(60) = LTRIM(RTRIM(ISNULL(@CustomerCode, '')));

            IF @codCliente <> ''
            BEGIN
                -- Resolver contexto canonico: CompanyId, BranchId
                DECLARE @CompanyId INT;
                DECLARE @BranchId  INT;

                SELECT TOP 1 @CompanyId = c.CompanyId
                FROM cfg.Company c
                WHERE c.IsDeleted = 0 AND c.IsActive = 1
                ORDER BY CASE WHEN c.CompanyCode = 'DEFAULT' THEN 0 ELSE 1 END, c.CompanyId;

                SELECT TOP 1 @BranchId = b.BranchId
                FROM cfg.Branch b
                WHERE b.CompanyId = @CompanyId AND b.IsDeleted = 0 AND b.IsActive = 1
                ORDER BY CASE WHEN b.BranchCode = 'MAIN' THEN 0 ELSE 1 END, b.BranchId;

                -- Resolver CustomerId
                DECLARE @CustomerId BIGINT = NULL;

                SELECT TOP 1 @CustomerId = CustomerId
                FROM [master].Customer
                WHERE CustomerCode = @codCliente
                  AND CompanyId = @CompanyId
                  AND IsDeleted = 0;

                IF @CustomerId IS NOT NULL AND @CompanyId IS NOT NULL AND @BranchId IS NOT NULL
                BEGIN
                    -- Calcular monto pendiente
                    -- Si IsPaid = 'S', pendiente = 0
                    -- Si no, pendiente = TotalAmount - SUM(pagos sin SALDO)
                    IF UPPER(@IsPaid) = 'S'
                        SET @pendingAmount = 0;
                    ELSE
                    BEGIN
                        DECLARE @totalPagado DECIMAL(18,4) = 0;

                        IF @PaymentsJson IS NOT NULL AND LEN(@PaymentsJson) > 2
                        BEGIN
                            SELECT @totalPagado = ISNULL(SUM(ISNULL(j.Amount, 0)), 0)
                            FROM OPENJSON(@PaymentsJson)
                            WITH (
                                PaymentMethod NVARCHAR(30) '$.PaymentMethod',
                                Amount        DECIMAL(18,4) '$.Amount'
                            ) AS j
                            WHERE UPPER(ISNULL(j.PaymentMethod, '')) NOT LIKE '%SALDO%';
                        END;

                        SET @pendingAmount = CASE
                            WHEN @TotalAmount - @totalPagado > 0 THEN @TotalAmount - @totalPagado
                            ELSE 0
                        END;
                    END;

                    -- Determinar status
                    DECLARE @arStatus NVARCHAR(20);
                    SET @arStatus = CASE
                        WHEN @pendingAmount <= 0              THEN 'PAID'
                        WHEN @pendingAmount < @TotalAmount    THEN 'PARTIAL'
                        ELSE                                       'PENDING'
                    END;

                    DECLARE @arPaidFlag BIT = CASE WHEN @pendingAmount <= 0 THEN 1 ELSE 0 END;

                    -- Resolver UserId opcional
                    DECLARE @UserId INT = NULL;

                    IF @UserCode IS NOT NULL AND @UserCode <> ''
                    BEGIN
                        SELECT TOP 1 @UserId = UserId
                        FROM sec.[User]
                        WHERE UserCode = @UserCode
                          AND IsDeleted = 0;
                    END;

                    -- Upsert ar.ReceivableDocument
                    IF EXISTS (
                        SELECT 1 FROM ar.ReceivableDocument
                        WHERE CompanyId = @CompanyId
                          AND BranchId  = @BranchId
                          AND DocumentType   = @TipoOperacion
                          AND DocumentNumber = @numDoc
                    )
                    BEGIN
                        UPDATE ar.ReceivableDocument
                        SET CustomerId     = @CustomerId,
                            IssueDate      = @DocumentDate,
                            DueDate        = ISNULL(@DueDate, @DocumentDate),
                            TotalAmount    = @TotalAmount,
                            PendingAmount  = @pendingAmount,
                            PaidFlag       = @arPaidFlag,
                            Status         = @arStatus,
                            Notes          = @Notes,
                            UpdatedAt      = SYSUTCDATETIME(),
                            UpdatedByUserId = @UserId
                        WHERE CompanyId      = @CompanyId
                          AND BranchId       = @BranchId
                          AND DocumentType   = @TipoOperacion
                          AND DocumentNumber = @numDoc;
                    END
                    ELSE
                    BEGIN
                        INSERT INTO ar.ReceivableDocument (
                            CompanyId, BranchId, CustomerId, DocumentType, DocumentNumber,
                            IssueDate, DueDate, CurrencyCode,
                            TotalAmount, PendingAmount, PaidFlag, Status, Notes,
                            CreatedAt, UpdatedAt, CreatedByUserId, UpdatedByUserId
                        )
                        VALUES (
                            @CompanyId, @BranchId, @CustomerId, @TipoOperacion, @numDoc,
                            @DocumentDate, ISNULL(@DueDate, @DocumentDate), ISNULL(@CurrencyCode, 'USD'),
                            @TotalAmount, @pendingAmount, @arPaidFlag, @arStatus, @Notes,
                            SYSUTCDATETIME(), SYSUTCDATETIME(), @UserId, @UserId
                        );
                    END;

                    -- Actualizar saldo del cliente
                    EXEC dbo.usp_Master_Customer_UpdateBalance
                        @CustomerId      = @CustomerId,
                        @UpdatedByUserId = @UserId;
                END;
            END;
        END;

    COMMIT TRAN;

    -- =========================================================================
    -- 4. Resultado
    -- =========================================================================
    SET @ok = 1;

    SELECT @ok AS ok,
           @numDoc AS numDoc,
           @detalleRows AS detalleRows,
           @formasPagoRows AS formasPagoRows,
           @pendingAmount AS pendingAmount;
END;
GO
