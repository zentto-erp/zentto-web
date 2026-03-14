-- =============================================
-- Creacion de tablas y vistas de documentos unificados
-- Tablas reales: ar.SalesDocument*, ap.PurchaseDocument*
-- Vistas legacy: dbo.DocumentosVenta*, dbo.DocumentosCompra*
-- Vistas alias:  doc.SalesDocument*, doc.PurchaseDocument*
-- Cadena: doc.* (VIEW) -> dbo.* (VIEW) -> ar.*/ap.* (TABLE)
-- =============================================

-- =============================================================================
-- SECCION 1: TABLAS ar.* (Documentos de Venta)
-- =============================================================================

-- 1.1 ar.SalesDocument
IF NOT EXISTS (SELECT * FROM sys.tables WHERE schema_id = SCHEMA_ID('ar') AND name = 'SalesDocument')
BEGIN
    CREATE TABLE ar.SalesDocument (
        DocumentId          INT IDENTITY(1,1) NOT NULL,
        DocumentNumber      NVARCHAR(60)  NOT NULL,
        SerialType          NVARCHAR(60)  NOT NULL DEFAULT '',
        OperationType       NVARCHAR(20)  NOT NULL,

        -- Cliente
        CustomerCode        NVARCHAR(60)  NULL,
        CustomerName        NVARCHAR(255) NULL,
        FiscalId            NVARCHAR(20)  NULL,

        -- Fechas
        DocumentDate        DATETIME      NULL DEFAULT GETDATE(),
        DueDate             DATETIME      NULL,
        DocumentTime        NVARCHAR(20)  NULL DEFAULT CONVERT(NVARCHAR(8), GETDATE(), 108),

        -- Montos
        SubTotal            DECIMAL(18,4) NULL DEFAULT 0,
        TaxableAmount       DECIMAL(18,4) NULL DEFAULT 0,
        ExemptAmount        DECIMAL(18,4) NULL DEFAULT 0,
        TaxAmount           DECIMAL(18,4) NULL DEFAULT 0,
        TaxRate             DECIMAL(8,4)  NULL DEFAULT 0,
        TotalAmount         DECIMAL(18,4) NULL DEFAULT 0,
        DiscountAmount      DECIMAL(18,4) NULL DEFAULT 0,

        -- Estados
        IsVoided            BIT           NULL DEFAULT 0,
        IsPaid              NVARCHAR(1)   NULL DEFAULT 'N',
        IsInvoiced          NVARCHAR(1)   NULL DEFAULT 'N',
        IsDelivered         NVARCHAR(1)   NULL DEFAULT 'N',

        -- Documentos relacionados
        OriginDocumentNumber NVARCHAR(60) NULL,
        OriginDocumentType  NVARCHAR(20)  NULL,

        -- Informacion fiscal
        ControlNumber       NVARCHAR(60)  NULL,
        IsLegal             BIT           NULL DEFAULT 0,
        IsPrinted           BIT           NULL DEFAULT 0,

        -- Informacion adicional
        Notes               NVARCHAR(500) NULL,
        Concept             NVARCHAR(255) NULL,
        PaymentTerms        NVARCHAR(255) NULL,
        ShipToAddress       NVARCHAR(255) NULL,

        -- Vendedor y ubicacion
        SellerCode          NVARCHAR(60)  NULL,
        DepartmentCode      NVARCHAR(50)  NULL,
        LocationCode        NVARCHAR(100) NULL,

        -- Moneda
        CurrencyCode        NVARCHAR(20)  NULL DEFAULT 'BS',
        ExchangeRate        DECIMAL(18,6) NULL DEFAULT 1,

        -- Auditoria
        UserCode            NVARCHAR(60)  NULL DEFAULT 'API',
        ReportDate          DATETIME      NULL DEFAULT GETDATE(),
        HostName            NVARCHAR(255) NULL DEFAULT HOST_NAME(),

        -- Campos especificos (taller/lubricantes)
        VehiclePlate        NVARCHAR(20)  NULL,
        Mileage             INT           NULL,
        TollAmount          DECIMAL(18,4) NULL DEFAULT 0,

        -- Audit trail
        CreatedAt           DATETIME2(0)  NOT NULL DEFAULT SYSUTCDATETIME(),
        UpdatedAt           DATETIME2(0)  NOT NULL DEFAULT SYSUTCDATETIME(),
        CreatedByUserId     INT           NULL,
        UpdatedByUserId     INT           NULL,
        IsDeleted           BIT           NOT NULL DEFAULT 0,
        DeletedAt           DATETIME2(0)  NULL,
        DeletedByUserId     INT           NULL,
        RowVer              ROWVERSION    NOT NULL,

        CONSTRAINT PK_SalesDocument PRIMARY KEY (DocumentId),
        CONSTRAINT UQ_SalesDocument_NumDocOp UNIQUE (DocumentNumber, OperationType)
    );

    CREATE INDEX IX_SalesDocument_Customer ON ar.SalesDocument(CustomerCode);
    CREATE INDEX IX_SalesDocument_OpDate ON ar.SalesDocument(OperationType, DocumentDate DESC) WHERE IsDeleted = 0;
END
GO

-- 1.2 ar.SalesDocumentLine
IF NOT EXISTS (SELECT * FROM sys.tables WHERE schema_id = SCHEMA_ID('ar') AND name = 'SalesDocumentLine')
BEGIN
    CREATE TABLE ar.SalesDocumentLine (
        LineId              INT IDENTITY(1,1) NOT NULL,
        DocumentNumber      NVARCHAR(60)  NOT NULL,
        OperationType       NVARCHAR(20)  NOT NULL,
        LineNumber          INT           NULL DEFAULT 0,

        -- Producto
        ProductCode         NVARCHAR(60)  NULL,
        Description         NVARCHAR(255) NULL,
        AlternateCode       NVARCHAR(60)  NULL,

        -- Cantidades y precios
        Quantity            DECIMAL(18,4) NULL DEFAULT 0,
        UnitPrice           DECIMAL(18,4) NULL DEFAULT 0,
        DiscountedPrice     DECIMAL(18,4) NULL DEFAULT 0,
        UnitCost            DECIMAL(18,4) NULL DEFAULT 0,

        -- Totales
        SubTotal            DECIMAL(18,4) NULL DEFAULT 0,
        DiscountAmount      DECIMAL(18,4) NULL DEFAULT 0,
        TotalAmount         DECIMAL(18,4) NULL DEFAULT 0,

        -- IVA
        TaxRate             DECIMAL(8,4)  NULL DEFAULT 0,
        TaxAmount           DECIMAL(18,4) NULL DEFAULT 0,

        -- Estados
        IsVoided            BIT           NULL DEFAULT 0,
        RelatedRef          NVARCHAR(10)  NULL DEFAULT '0',

        -- Auditoria
        UserCode            NVARCHAR(60)  NULL DEFAULT 'API',
        LineDate            DATETIME      NULL DEFAULT GETDATE(),

        -- Audit trail
        CreatedAt           DATETIME2(0)  NOT NULL DEFAULT SYSUTCDATETIME(),
        UpdatedAt           DATETIME2(0)  NOT NULL DEFAULT SYSUTCDATETIME(),
        CreatedByUserId     INT           NULL,
        UpdatedByUserId     INT           NULL,
        IsDeleted           BIT           NOT NULL DEFAULT 0,
        DeletedAt           DATETIME2(0)  NULL,
        DeletedByUserId     INT           NULL,
        RowVer              ROWVERSION    NOT NULL,

        CONSTRAINT PK_SalesDocumentLine PRIMARY KEY (LineId)
    );

    CREATE INDEX IX_SalesDocLine_DocKey ON ar.SalesDocumentLine(DocumentNumber, OperationType) WHERE IsDeleted = 0;
    CREATE INDEX IX_SalesDocLine_Product ON ar.SalesDocumentLine(ProductCode);
END
GO

-- 1.3 ar.SalesDocumentPayment
IF NOT EXISTS (SELECT * FROM sys.tables WHERE schema_id = SCHEMA_ID('ar') AND name = 'SalesDocumentPayment')
BEGIN
    CREATE TABLE ar.SalesDocumentPayment (
        PaymentId           INT IDENTITY(1,1) NOT NULL,
        DocumentNumber      NVARCHAR(60)  NOT NULL,
        OperationType       NVARCHAR(20)  NOT NULL DEFAULT 'FACT',

        -- Forma de pago
        PaymentMethod       NVARCHAR(30)  NULL,
        BankCode            NVARCHAR(60)  NULL,
        PaymentNumber       NVARCHAR(60)  NULL,

        -- Montos
        Amount              DECIMAL(18,4) NULL DEFAULT 0,
        AmountBs            DECIMAL(18,4) NULL DEFAULT 0,
        ExchangeRate        DECIMAL(18,6) NULL DEFAULT 1,

        -- Fechas
        PaymentDate         DATETIME      NULL DEFAULT GETDATE(),
        DueDate             DATETIME      NULL,

        -- Referencias
        ReferenceNumber     NVARCHAR(100) NULL,
        UserCode            NVARCHAR(60)  NULL DEFAULT 'API',

        -- Audit trail
        CreatedAt           DATETIME2(0)  NOT NULL DEFAULT SYSUTCDATETIME(),
        UpdatedAt           DATETIME2(0)  NOT NULL DEFAULT SYSUTCDATETIME(),
        CreatedByUserId     INT           NULL,
        UpdatedByUserId     INT           NULL,
        IsDeleted           BIT           NOT NULL DEFAULT 0,
        DeletedAt           DATETIME2(0)  NULL,
        DeletedByUserId     INT           NULL,
        RowVer              ROWVERSION    NOT NULL,

        CONSTRAINT PK_SalesDocumentPayment PRIMARY KEY (PaymentId)
    );

    CREATE INDEX IX_SalesDocPay_DocKey ON ar.SalesDocumentPayment(DocumentNumber, OperationType) WHERE IsDeleted = 0;
END
GO

-- =============================================================================
-- SECCION 2: TABLAS ap.* (Documentos de Compra)
-- =============================================================================

-- 2.1 ap.PurchaseDocument
IF NOT EXISTS (SELECT * FROM sys.tables WHERE schema_id = SCHEMA_ID('ap') AND name = 'PurchaseDocument')
BEGIN
    CREATE TABLE ap.PurchaseDocument (
        DocumentId          INT IDENTITY(1,1) NOT NULL,
        DocumentNumber      NVARCHAR(60)  NOT NULL,
        SerialType          NVARCHAR(60)  NOT NULL DEFAULT '',
        OperationType       NVARCHAR(20)  NOT NULL DEFAULT 'COMPRA',

        -- Proveedor
        SupplierCode        NVARCHAR(60)  NULL,
        SupplierName        NVARCHAR(255) NULL,
        FiscalId            NVARCHAR(15)  NULL,

        -- Fechas
        DocumentDate        DATETIME      NULL DEFAULT GETDATE(),
        DueDate             DATETIME      NULL,
        ReceiptDate         DATETIME      NULL,
        PaymentDate         DATETIME      NULL,
        DocumentTime        NVARCHAR(20)  NULL DEFAULT CONVERT(NVARCHAR(8), GETDATE(), 108),

        -- Montos
        SubTotal            DECIMAL(18,4) NULL DEFAULT 0,
        TaxableAmount       DECIMAL(18,4) NULL DEFAULT 0,
        ExemptAmount        DECIMAL(18,4) NULL DEFAULT 0,
        TaxAmount           DECIMAL(18,4) NULL DEFAULT 0,
        TaxRate             DECIMAL(8,4)  NULL DEFAULT 0,
        TotalAmount         DECIMAL(18,4) NULL DEFAULT 0,
        ExemptTotalAmount   DECIMAL(18,4) NULL DEFAULT 0,
        DiscountAmount      DECIMAL(18,4) NULL DEFAULT 0,

        -- Estados
        IsVoided            BIT           NULL DEFAULT 0,
        IsPaid              NVARCHAR(1)   NULL DEFAULT 'N',
        IsReceived          NVARCHAR(1)   NULL DEFAULT 'N',
        IsLegal             BIT           NULL DEFAULT 0,

        -- Documentos relacionados
        OriginDocumentNumber NVARCHAR(60) NULL,

        -- Informacion fiscal compra
        ControlNumber       NVARCHAR(60)  NULL,
        VoucherNumber       NVARCHAR(50)  NULL,
        VoucherDate         DATETIME      NULL,

        -- Retenciones
        RetainedTax         DECIMAL(18,4) NULL DEFAULT 0,
        IsrCode             NVARCHAR(50)  NULL,
        IsrAmount           DECIMAL(18,4) NULL DEFAULT 0,
        IsrSubjectAmount    DECIMAL(18,4) NULL DEFAULT 0,
        RetentionRate       DECIMAL(8,4)  NULL DEFAULT 0,

        -- Importacion
        ImportAmount        DECIMAL(18,4) NULL DEFAULT 0,
        ImportTax           DECIMAL(18,4) NULL DEFAULT 0,
        ImportBase          DECIMAL(18,4) NULL DEFAULT 0,
        FreightAmount       DECIMAL(18,4) NULL DEFAULT 0,

        -- Informacion adicional
        Concept             NVARCHAR(255) NULL,
        Notes               NVARCHAR(500) NULL,
        OrderNumber         NVARCHAR(20)  NULL,
        ReceivedBy          NVARCHAR(20)  NULL,
        WarehouseCode       NVARCHAR(50)  NULL,

        -- Moneda
        CurrencyCode        NVARCHAR(20)  NULL DEFAULT 'BS',
        ExchangeRate        DECIMAL(18,6) NULL DEFAULT 1,
        UsdAmount           DECIMAL(18,4) NULL DEFAULT 0,

        -- Auditoria
        UserCode            NVARCHAR(60)  NULL DEFAULT 'API',
        ShortUserCode       NVARCHAR(10)  NULL,
        ReportDate          DATETIME      NULL DEFAULT GETDATE(),
        HostName            NVARCHAR(255) NULL DEFAULT HOST_NAME(),

        -- Audit trail
        CreatedAt           DATETIME2(0)  NOT NULL DEFAULT SYSUTCDATETIME(),
        UpdatedAt           DATETIME2(0)  NOT NULL DEFAULT SYSUTCDATETIME(),
        CreatedByUserId     INT           NULL,
        UpdatedByUserId     INT           NULL,
        IsDeleted           BIT           NOT NULL DEFAULT 0,
        DeletedAt           DATETIME2(0)  NULL,
        DeletedByUserId     INT           NULL,
        RowVer              ROWVERSION    NOT NULL,

        CONSTRAINT PK_PurchaseDocument PRIMARY KEY (DocumentId),
        CONSTRAINT UQ_PurchaseDocument_NumDocOp UNIQUE (DocumentNumber, OperationType)
    );

    CREATE INDEX IX_PurchaseDocument_Supplier ON ap.PurchaseDocument(SupplierCode);
    CREATE INDEX IX_PurchaseDocument_OpDate ON ap.PurchaseDocument(OperationType, DocumentDate) WHERE IsDeleted = 0;
END
GO

-- 2.2 ap.PurchaseDocumentLine
IF NOT EXISTS (SELECT * FROM sys.tables WHERE schema_id = SCHEMA_ID('ap') AND name = 'PurchaseDocumentLine')
BEGIN
    CREATE TABLE ap.PurchaseDocumentLine (
        LineId              INT IDENTITY(1,1) NOT NULL,
        DocumentNumber      NVARCHAR(60)  NOT NULL,
        OperationType       NVARCHAR(20)  NOT NULL DEFAULT 'COMPRA',
        LineNumber          INT           NULL DEFAULT 0,

        -- Producto
        ProductCode         NVARCHAR(60)  NULL,
        Description         NVARCHAR(255) NULL,

        -- Cantidades y precios
        Quantity            DECIMAL(18,4) NULL DEFAULT 0,
        UnitPrice           DECIMAL(18,4) NULL DEFAULT 0,
        UnitCost            DECIMAL(18,4) NULL DEFAULT 0,

        -- Totales
        SubTotal            DECIMAL(18,4) NULL DEFAULT 0,
        DiscountAmount      DECIMAL(18,4) NULL DEFAULT 0,
        TotalAmount         DECIMAL(18,4) NULL DEFAULT 0,

        -- IVA
        TaxRate             DECIMAL(8,4)  NULL DEFAULT 0,
        TaxAmount           DECIMAL(18,4) NULL DEFAULT 0,

        -- Estados
        IsVoided            BIT           NULL DEFAULT 0,

        -- Auditoria
        UserCode            NVARCHAR(60)  NULL DEFAULT 'API',
        LineDate            DATETIME      NULL DEFAULT GETDATE(),

        -- Audit trail
        CreatedAt           DATETIME2(0)  NOT NULL DEFAULT SYSUTCDATETIME(),
        UpdatedAt           DATETIME2(0)  NOT NULL DEFAULT SYSUTCDATETIME(),
        CreatedByUserId     INT           NULL,
        UpdatedByUserId     INT           NULL,
        IsDeleted           BIT           NOT NULL DEFAULT 0,
        DeletedAt           DATETIME2(0)  NULL,
        DeletedByUserId     INT           NULL,
        RowVer              ROWVERSION    NOT NULL,

        CONSTRAINT PK_PurchaseDocumentLine PRIMARY KEY (LineId)
    );

    CREATE INDEX IX_PurchDocLine_DocKey ON ap.PurchaseDocumentLine(DocumentNumber, OperationType) WHERE IsDeleted = 0;
    CREATE INDEX IX_PurchDocLine_Product ON ap.PurchaseDocumentLine(ProductCode);
END
GO

-- 2.3 ap.PurchaseDocumentPayment
IF NOT EXISTS (SELECT * FROM sys.tables WHERE schema_id = SCHEMA_ID('ap') AND name = 'PurchaseDocumentPayment')
BEGIN
    CREATE TABLE ap.PurchaseDocumentPayment (
        PaymentId           INT IDENTITY(1,1) NOT NULL,
        DocumentNumber      NVARCHAR(60)  NOT NULL,
        OperationType       NVARCHAR(20)  NOT NULL DEFAULT 'COMPRA',

        PaymentMethod       NVARCHAR(30)  NULL,
        BankCode            NVARCHAR(60)  NULL,
        PaymentNumber       NVARCHAR(60)  NULL,

        Amount              DECIMAL(18,4) NULL DEFAULT 0,
        PaymentDate         DATETIME      NULL DEFAULT GETDATE(),
        DueDate             DATETIME      NULL,

        ReferenceNumber     NVARCHAR(100) NULL,
        UserCode            NVARCHAR(60)  NULL DEFAULT 'API',

        -- Audit trail
        CreatedAt           DATETIME2(0)  NOT NULL DEFAULT SYSUTCDATETIME(),
        UpdatedAt           DATETIME2(0)  NOT NULL DEFAULT SYSUTCDATETIME(),
        CreatedByUserId     INT           NULL,
        UpdatedByUserId     INT           NULL,
        IsDeleted           BIT           NOT NULL DEFAULT 0,
        DeletedAt           DATETIME2(0)  NULL,
        DeletedByUserId     INT           NULL,
        RowVer              ROWVERSION    NOT NULL,

        CONSTRAINT PK_PurchaseDocumentPayment PRIMARY KEY (PaymentId)
    );

    CREATE INDEX IX_PurchDocPay_DocKey ON ap.PurchaseDocumentPayment(DocumentNumber, OperationType) WHERE IsDeleted = 0;
END
GO

-- =============================================================================
-- SECCION 3: VISTAS dbo.Documentos* (compatibilidad legacy, alias espanol)
-- Cadena: dbo.DocumentosVenta -> ar.SalesDocument
-- =============================================================================

IF OBJECT_ID('dbo.DocumentosVenta', 'V') IS NOT NULL DROP VIEW dbo.DocumentosVenta;
GO
CREATE VIEW dbo.DocumentosVenta AS
SELECT
    DocumentId                     AS ID,
    DocumentNumber                 AS NUM_DOC,
    SerialType                     AS SERIALTIPO,
    OperationType                  AS TIPO_OPERACION,
    CustomerCode                   AS CODIGO,
    CustomerName                   AS NOMBRE,
    FiscalId                       AS RIF,
    DocumentDate                   AS FECHA,
    DueDate                        AS FECHA_VENCE,
    DocumentTime                   AS HORA,
    CAST(SubTotal       AS FLOAT)  AS SUBTOTAL,
    CAST(TaxableAmount  AS FLOAT)  AS MONTO_GRA,
    CAST(ExemptAmount   AS FLOAT)  AS MONTO_EXE,
    CAST(TaxAmount      AS FLOAT)  AS IVA,
    CAST(TaxRate        AS FLOAT)  AS ALICUOTA,
    CAST(TotalAmount    AS FLOAT)  AS TOTAL,
    CAST(DiscountAmount AS FLOAT)  AS DESCUENTO,
    IsVoided                       AS ANULADA,
    IsPaid                         AS CANCELADA,
    IsInvoiced                     AS FACTURADA,
    IsDelivered                    AS ENTREGADA,
    OriginDocumentNumber           AS DOC_ORIGEN,
    OriginDocumentType             AS TIPO_DOC_ORIGEN,
    ControlNumber                  AS NUM_CONTROL,
    IsLegal                        AS LEGAL,
    IsPrinted                      AS IMPRESA,
    Notes                          AS OBSERV,
    Concept                        AS CONCEPTO,
    PaymentTerms                   AS TERMINOS,
    ShipToAddress                  AS DESPACHAR,
    SellerCode                     AS VENDEDOR,
    DepartmentCode                 AS DEPARTAMENTO,
    LocationCode                   AS LOCACION,
    CurrencyCode                   AS MONEDA,
    CAST(ExchangeRate   AS FLOAT)  AS TASA_CAMBIO,
    UserCode                       AS COD_USUARIO,
    ReportDate                     AS FECHA_REPORTE,
    HostName                       AS COMPUTER,
    VehiclePlate                   AS PLACAS,
    Mileage                        AS KILOMETROS,
    CAST(TollAmount     AS FLOAT)  AS PEAJE,
    CreatedAt, UpdatedAt, CreatedByUserId, UpdatedByUserId,
    IsDeleted, DeletedAt, DeletedByUserId,
    RowVer
FROM ar.SalesDocument;
GO

IF OBJECT_ID('dbo.DocumentosVentaDetalle', 'V') IS NOT NULL DROP VIEW dbo.DocumentosVentaDetalle;
GO
CREATE VIEW dbo.DocumentosVentaDetalle AS
SELECT
    LineId                             AS ID,
    DocumentNumber                     AS NUM_DOC,
    OperationType                      AS TIPO_OPERACION,
    LineNumber                         AS RENGLON,
    ProductCode                        AS COD_SERV,
    Description                        AS DESCRIPCION,
    AlternateCode                      AS COD_ALTERNO,
    CAST(Quantity       AS FLOAT)      AS CANTIDAD,
    CAST(UnitPrice      AS FLOAT)      AS PRECIO,
    CAST(DiscountedPrice AS FLOAT)     AS PRECIO_DESCUENTO,
    CAST(UnitCost       AS FLOAT)      AS COSTO,
    CAST(SubTotal       AS FLOAT)      AS SUBTOTAL,
    CAST(DiscountAmount AS FLOAT)      AS DESCUENTO,
    CAST(TotalAmount    AS FLOAT)      AS TOTAL,
    CAST(TaxRate        AS FLOAT)      AS ALICUOTA,
    CAST(TaxAmount      AS FLOAT)      AS MONTO_IVA,
    IsVoided                           AS ANULADA,
    RelatedRef                         AS RELACIONADA,
    UserCode                           AS CO_USUARIO,
    LineDate                           AS FECHA,
    CreatedAt, UpdatedAt, CreatedByUserId, UpdatedByUserId,
    IsDeleted, DeletedAt, DeletedByUserId,
    RowVer
FROM ar.SalesDocumentLine;
GO

IF OBJECT_ID('dbo.DocumentosVentaPago', 'V') IS NOT NULL DROP VIEW dbo.DocumentosVentaPago;
GO
CREATE VIEW dbo.DocumentosVentaPago AS
SELECT
    PaymentId                          AS ID,
    DocumentNumber                     AS NUM_DOC,
    OperationType                      AS TIPO_OPERACION,
    PaymentMethod                      AS TIPO_PAGO,
    BankCode                           AS BANCO,
    PaymentNumber                      AS NUMERO,
    CAST(Amount         AS FLOAT)      AS MONTO,
    CAST(AmountBs       AS FLOAT)      AS MONTO_BS,
    CAST(ExchangeRate   AS FLOAT)      AS TASA_CAMBIO,
    PaymentDate                        AS FECHA,
    DueDate                            AS FECHA_VENCE,
    ReferenceNumber                    AS REFERENCIA,
    UserCode                           AS CO_USUARIO,
    CreatedAt, UpdatedAt, CreatedByUserId, UpdatedByUserId,
    IsDeleted, DeletedAt, DeletedByUserId,
    RowVer
FROM ar.SalesDocumentPayment;
GO

IF OBJECT_ID('dbo.DocumentosCompra', 'V') IS NOT NULL DROP VIEW dbo.DocumentosCompra;
GO
CREATE VIEW dbo.DocumentosCompra AS
SELECT
    DocumentId                     AS ID,
    DocumentNumber                 AS NUM_DOC,
    SerialType                     AS SERIALTIPO,
    OperationType                  AS TIPO_OPERACION,
    SupplierCode                   AS COD_PROVEEDOR,
    SupplierName                   AS NOMBRE,
    FiscalId                       AS RIF,
    DocumentDate                   AS FECHA,
    DueDate                        AS FECHA_VENCE,
    ReceiptDate                    AS FECHA_RECIBO,
    PaymentDate                    AS FECHA_PAGO,
    DocumentTime                   AS HORA,
    CAST(SubTotal           AS FLOAT)  AS SUBTOTAL,
    CAST(TaxableAmount      AS FLOAT)  AS MONTO_GRA,
    CAST(ExemptAmount       AS FLOAT)  AS MONTO_EXE,
    CAST(TaxAmount          AS FLOAT)  AS IVA,
    CAST(TaxRate            AS FLOAT)  AS ALICUOTA,
    CAST(TotalAmount        AS FLOAT)  AS TOTAL,
    CAST(ExemptTotalAmount  AS FLOAT)  AS EXENTO,
    CAST(DiscountAmount     AS FLOAT)  AS DESCUENTO,
    IsVoided                           AS ANULADA,
    IsPaid                             AS CANCELADA,
    IsReceived                         AS RECIBIDA,
    IsLegal                            AS LEGAL,
    OriginDocumentNumber               AS DOC_ORIGEN,
    ControlNumber                      AS NUM_CONTROL,
    VoucherNumber                      AS NRO_COMPROBANTE,
    VoucherDate                        AS FECHA_COMPROBANTE,
    CAST(RetainedTax        AS FLOAT)  AS IVA_RETENIDO,
    IsrCode                            AS ISLR,
    CAST(IsrAmount          AS FLOAT)  AS MONTO_ISLR,
    IsrCode                            AS CODIGO_ISLR,
    CAST(IsrSubjectAmount   AS FLOAT)  AS SUJETO_ISLR,
    CAST(RetentionRate      AS FLOAT)  AS TASA_RETENCION,
    CAST(ImportAmount       AS FLOAT)  AS IMPORTACION,
    CAST(ImportTax          AS FLOAT)  AS IVA_IMPORT,
    CAST(ImportBase         AS FLOAT)  AS BASE_IMPORT,
    CAST(FreightAmount      AS FLOAT)  AS FLETE,
    Concept                            AS CONCEPTO,
    Notes                              AS OBSERV,
    OrderNumber                        AS PEDIDO,
    ReceivedBy                         AS RECIBIDO,
    WarehouseCode                      AS ALMACEN,
    CurrencyCode                       AS MONEDA,
    CAST(ExchangeRate       AS FLOAT)  AS TASA_CAMBIO,
    CAST(UsdAmount          AS FLOAT)  AS PRECIO_DOLLAR,
    UserCode                           AS COD_USUARIO,
    ShortUserCode                      AS CO_USUARIO,
    ReportDate                         AS FECHA_REPORTE,
    HostName                           AS COMPUTER,
    CreatedAt, UpdatedAt, CreatedByUserId, UpdatedByUserId,
    IsDeleted, DeletedAt, DeletedByUserId,
    RowVer
FROM ap.PurchaseDocument;
GO

IF OBJECT_ID('dbo.DocumentosCompraDetalle', 'V') IS NOT NULL DROP VIEW dbo.DocumentosCompraDetalle;
GO
CREATE VIEW dbo.DocumentosCompraDetalle AS
SELECT
    LineId                         AS ID,
    DocumentNumber                 AS NUM_DOC,
    OperationType                  AS TIPO_OPERACION,
    LineNumber                     AS RENGLON,
    ProductCode                    AS COD_SERV,
    Description                    AS DESCRIPCION,
    CAST(Quantity       AS FLOAT)  AS CANTIDAD,
    CAST(UnitPrice      AS FLOAT)  AS PRECIO,
    CAST(UnitCost       AS FLOAT)  AS COSTO,
    CAST(SubTotal       AS FLOAT)  AS SUBTOTAL,
    CAST(DiscountAmount AS FLOAT)  AS DESCUENTO,
    CAST(TotalAmount    AS FLOAT)  AS TOTAL,
    CAST(TaxRate        AS FLOAT)  AS ALICUOTA,
    CAST(TaxAmount      AS FLOAT)  AS MONTO_IVA,
    IsVoided                       AS ANULADA,
    UserCode                       AS CO_USUARIO,
    LineDate                       AS FECHA,
    CreatedAt, UpdatedAt, CreatedByUserId, UpdatedByUserId,
    IsDeleted, DeletedAt, DeletedByUserId,
    RowVer
FROM ap.PurchaseDocumentLine;
GO

IF OBJECT_ID('dbo.DocumentosCompraPago', 'V') IS NOT NULL DROP VIEW dbo.DocumentosCompraPago;
GO
CREATE VIEW dbo.DocumentosCompraPago AS
SELECT
    PaymentId                      AS ID,
    DocumentNumber                 AS NUM_DOC,
    OperationType                  AS TIPO_OPERACION,
    PaymentMethod                  AS TIPO_PAGO,
    BankCode                       AS BANCO,
    PaymentNumber                  AS NUMERO,
    CAST(Amount         AS FLOAT)  AS MONTO,
    PaymentDate                    AS FECHA,
    DueDate                        AS FECHA_VENCE,
    ReferenceNumber                AS REFERENCIA,
    UserCode                       AS CO_USUARIO,
    CreatedAt, UpdatedAt, CreatedByUserId, UpdatedByUserId,
    IsDeleted, DeletedAt, DeletedByUserId,
    RowVer
FROM ap.PurchaseDocumentPayment;
GO

-- =============================================================================
-- SECCION 4: VISTAS doc.* (alias ingles sobre dbo.*)
-- Cadena: doc.SalesDocument -> dbo.DocumentosVenta -> ar.SalesDocument
-- =============================================================================

IF OBJECT_ID('doc.SalesDocument', 'V') IS NOT NULL DROP VIEW doc.SalesDocument;
IF OBJECT_ID('doc.SalesDocument', 'U') IS NOT NULL DROP TABLE doc.SalesDocumentPayment, doc.SalesDocumentLine, doc.SalesDocument;
GO
CREATE VIEW doc.SalesDocument AS
SELECT
    dv.ID              AS DocumentId,
    dv.NUM_DOC         AS DocumentNumber,
    dv.SERIALTIPO      AS SerialType,
    dv.TIPO_OPERACION  AS OperationType,
    dv.CODIGO          AS CustomerCode,
    dv.NOMBRE          AS CustomerName,
    dv.RIF             AS FiscalId,
    dv.FECHA           AS IssueDate,
    dv.FECHA_VENCE     AS DueDate,
    dv.HORA            AS DocumentTime,
    dv.SUBTOTAL        AS Subtotal,
    dv.MONTO_GRA       AS TaxableAmount,
    dv.MONTO_EXE       AS ExemptAmount,
    dv.IVA             AS TaxAmount,
    dv.ALICUOTA        AS TaxRate,
    dv.TOTAL           AS TotalAmount,
    dv.DESCUENTO       AS DiscountAmount,
    dv.ANULADA         AS IsVoided,
    dv.CANCELADA       AS IsCanceled,
    dv.FACTURADA       AS IsInvoiced,
    dv.ENTREGADA       AS IsDelivered,
    dv.DOC_ORIGEN      AS SourceDocumentNumber,
    dv.TIPO_DOC_ORIGEN AS SourceDocumentType,
    dv.NUM_CONTROL     AS ControlNumber,
    dv.OBSERV          AS Notes,
    dv.CONCEPTO        AS Concept,
    dv.MONEDA          AS CurrencyCode,
    dv.TASA_CAMBIO     AS ExchangeRate,
    dv.COD_USUARIO     AS LegacyUserCode,
    dv.CreatedAt,
    dv.UpdatedAt,
    dv.CreatedByUserId,
    dv.UpdatedByUserId,
    dv.IsDeleted,
    dv.DeletedAt,
    dv.DeletedByUserId,
    dv.RowVer
FROM dbo.DocumentosVenta dv;
GO

IF OBJECT_ID('doc.SalesDocumentLine', 'V') IS NOT NULL DROP VIEW doc.SalesDocumentLine;
IF OBJECT_ID('doc.SalesDocumentLine', 'U') IS NOT NULL DROP TABLE doc.SalesDocumentLine;
GO
CREATE VIEW doc.SalesDocumentLine AS
SELECT
    d.ID               AS LineId,
    d.NUM_DOC          AS DocumentNumber,
    d.TIPO_OPERACION   AS DocumentType,
    d.RENGLON          AS LineNumber,
    d.COD_SERV         AS ProductCode,
    d.DESCRIPCION      AS Description,
    d.COD_ALTERNO      AS AlternateCode,
    d.CANTIDAD         AS Quantity,
    d.PRECIO           AS UnitPrice,
    d.PRECIO_DESCUENTO AS DiscountUnitPrice,
    d.COSTO            AS UnitCost,
    d.SUBTOTAL         AS Subtotal,
    d.DESCUENTO        AS DiscountAmount,
    d.TOTAL            AS LineTotal,
    d.ALICUOTA         AS TaxRate,
    d.MONTO_IVA        AS TaxAmount,
    d.ANULADA          AS IsVoided,
    d.CreatedAt,
    d.UpdatedAt,
    d.CreatedByUserId,
    d.UpdatedByUserId,
    d.IsDeleted,
    d.DeletedAt,
    d.DeletedByUserId,
    d.RowVer
FROM dbo.DocumentosVentaDetalle d;
GO

IF OBJECT_ID('doc.SalesDocumentPayment', 'V') IS NOT NULL DROP VIEW doc.SalesDocumentPayment;
IF OBJECT_ID('doc.SalesDocumentPayment', 'U') IS NOT NULL DROP TABLE doc.SalesDocumentPayment;
GO
CREATE VIEW doc.SalesDocumentPayment AS
SELECT
    p.ID               AS PaymentId,
    p.NUM_DOC          AS DocumentNumber,
    p.TIPO_OPERACION   AS DocumentType,
    p.TIPO_PAGO        AS PaymentType,
    p.BANCO            AS BankCode,
    p.NUMERO           AS ReferenceNumber,
    p.MONTO            AS Amount,
    p.MONTO_BS         AS AmountLocal,
    p.TASA_CAMBIO      AS ExchangeRate,
    p.FECHA            AS ApplyDate,
    p.FECHA_VENCE      AS DueDate,
    p.REFERENCIA       AS PaymentReference,
    p.CreatedAt,
    p.UpdatedAt,
    p.CreatedByUserId,
    p.UpdatedByUserId,
    p.IsDeleted,
    p.DeletedAt,
    p.DeletedByUserId,
    p.RowVer
FROM dbo.DocumentosVentaPago p;
GO

IF OBJECT_ID('doc.PurchaseDocument', 'V') IS NOT NULL DROP VIEW doc.PurchaseDocument;
IF OBJECT_ID('doc.PurchaseDocument', 'U') IS NOT NULL DROP TABLE doc.PurchaseDocumentPayment, doc.PurchaseDocumentLine, doc.PurchaseDocument;
GO
CREATE VIEW doc.PurchaseDocument AS
SELECT
    dc.ID              AS DocumentId,
    dc.NUM_DOC         AS DocumentNumber,
    dc.SERIALTIPO      AS SerialType,
    dc.TIPO_OPERACION  AS DocumentType,
    dc.COD_PROVEEDOR   AS SupplierCode,
    dc.NOMBRE          AS SupplierName,
    dc.RIF             AS FiscalId,
    dc.FECHA           AS IssueDate,
    dc.FECHA_VENCE     AS DueDate,
    dc.SUBTOTAL        AS Subtotal,
    dc.MONTO_GRA       AS TaxableAmount,
    dc.MONTO_EXE       AS ExemptAmount,
    dc.IVA             AS TaxAmount,
    dc.ALICUOTA        AS TaxRate,
    dc.TOTAL           AS TotalAmount,
    dc.DESCUENTO       AS DiscountAmount,
    dc.ANULADA         AS IsVoided,
    dc.CANCELADA       AS IsCanceled,
    dc.OBSERV          AS Notes,
    dc.CONCEPTO        AS Concept,
    dc.MONEDA          AS CurrencyCode,
    dc.TASA_CAMBIO     AS ExchangeRate,
    dc.COD_USUARIO     AS LegacyUserCode,
    dc.CreatedAt,
    dc.UpdatedAt,
    dc.CreatedByUserId,
    dc.UpdatedByUserId,
    dc.IsDeleted,
    dc.DeletedAt,
    dc.DeletedByUserId,
    dc.RowVer
FROM dbo.DocumentosCompra dc;
GO

IF OBJECT_ID('doc.PurchaseDocumentLine', 'V') IS NOT NULL DROP VIEW doc.PurchaseDocumentLine;
IF OBJECT_ID('doc.PurchaseDocumentLine', 'U') IS NOT NULL DROP TABLE doc.PurchaseDocumentLine;
GO
CREATE VIEW doc.PurchaseDocumentLine AS
SELECT
    d.ID               AS LineId,
    d.NUM_DOC          AS DocumentNumber,
    d.TIPO_OPERACION   AS DocumentType,
    d.RENGLON          AS LineNumber,
    d.COD_SERV         AS ProductCode,
    d.DESCRIPCION      AS Description,
    d.CANTIDAD         AS Quantity,
    d.PRECIO           AS UnitPrice,
    d.COSTO            AS UnitCost,
    d.SUBTOTAL         AS Subtotal,
    d.DESCUENTO        AS DiscountAmount,
    d.TOTAL            AS LineTotal,
    d.ALICUOTA         AS TaxRate,
    d.MONTO_IVA        AS TaxAmount,
    d.ANULADA          AS IsVoided,
    d.CreatedAt,
    d.UpdatedAt,
    d.CreatedByUserId,
    d.UpdatedByUserId,
    d.IsDeleted,
    d.DeletedAt,
    d.DeletedByUserId,
    d.RowVer
FROM dbo.DocumentosCompraDetalle d;
GO

IF OBJECT_ID('doc.PurchaseDocumentPayment', 'V') IS NOT NULL DROP VIEW doc.PurchaseDocumentPayment;
IF OBJECT_ID('doc.PurchaseDocumentPayment', 'U') IS NOT NULL DROP TABLE doc.PurchaseDocumentPayment;
GO
CREATE VIEW doc.PurchaseDocumentPayment AS
SELECT
    p.ID               AS PaymentId,
    p.NUM_DOC          AS DocumentNumber,
    p.TIPO_OPERACION   AS DocumentType,
    p.TIPO_PAGO        AS PaymentType,
    p.BANCO            AS BankCode,
    p.NUMERO           AS ReferenceNumber,
    p.MONTO            AS Amount,
    p.FECHA            AS ApplyDate,
    p.FECHA_VENCE      AS DueDate,
    p.REFERENCIA       AS PaymentReference,
    p.CreatedAt,
    p.UpdatedAt,
    p.CreatedByUserId,
    p.UpdatedByUserId,
    p.IsDeleted,
    p.DeletedAt,
    p.DeletedByUserId,
    p.RowVer
FROM dbo.DocumentosCompraPago p;
GO

-- =============================================================================
-- SECCION 5: TABLAS AUXILIARES (canonicas nuevas)
-- =============================================================================

-- 5.1 acct.BankDeposit (reemplaza dbo.DETALLE_DEPOSITO)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE schema_id = SCHEMA_ID('acct') AND name = 'BankDeposit')
BEGIN
    CREATE TABLE acct.BankDeposit (
        BankDepositId       INT IDENTITY(1,1) PRIMARY KEY,
        Amount              DECIMAL(18,4) NOT NULL DEFAULT 0,
        CheckNumber         NVARCHAR(80)  NULL,
        BankAccount         NVARCHAR(120) NULL,
        CustomerCode        NVARCHAR(60)  NULL,
        IsRelated           BIT           NOT NULL DEFAULT 0,
        BankName            NVARCHAR(120) NULL,
        DocumentRef         NVARCHAR(60)  NULL,
        OperationType       NVARCHAR(20)  NULL,
        CreatedAt           DATETIME2(0)  NOT NULL DEFAULT SYSUTCDATETIME(),
        UpdatedAt           DATETIME2(0)  NOT NULL DEFAULT SYSUTCDATETIME(),
        CreatedByUserId     INT           NULL,
        IsDeleted           BIT           NOT NULL DEFAULT 0,
        RowVer              ROWVERSION    NOT NULL
    );

    CREATE INDEX IX_BankDeposit_Customer ON acct.BankDeposit(CustomerCode) WHERE IsDeleted = 0;
END
GO

-- 5.2 master.AlternateStock (reemplaza dbo.Inventario_Aux)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE schema_id = SCHEMA_ID('master') AND name = 'AlternateStock')
BEGIN
    CREATE TABLE master.AlternateStock (
        AlternateStockId    INT IDENTITY(1,1) PRIMARY KEY,
        ProductCode         NVARCHAR(80)  NOT NULL,
        StockQty            DECIMAL(18,4) NOT NULL DEFAULT 0,
        CreatedAt           DATETIME2(0)  NOT NULL DEFAULT SYSUTCDATETIME(),
        UpdatedAt           DATETIME2(0)  NOT NULL DEFAULT SYSUTCDATETIME(),
        IsDeleted           BIT           NOT NULL DEFAULT 0,
        RowVer              ROWVERSION    NOT NULL,
        CONSTRAINT UQ_AlternateStock_ProductCode UNIQUE (ProductCode)
    );
END
GO

SELECT 'Tablas ar.*, ap.*, vistas dbo.*, doc.*, tablas auxiliares creadas exitosamente' AS mensaje;
GO
