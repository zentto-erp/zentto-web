-- =============================================================================
-- 21_canonical_document_tables.sql
-- Migra las tablas de documentos de dbo.* a esquemas canónicos con nombres
-- y estructura modernos. Preserva 100% de compatibilidad hacia atrás mediante
-- VIEWS en dbo con los nombres de columna originales + INSTEAD OF triggers.
--
-- Tablas canónicas nuevas:
--   ar.SalesDocument, ar.SalesDocumentLine, ar.SalesDocumentPayment
--   ap.PurchaseDocument, ap.PurchaseDocumentLine, ap.PurchaseDocumentPayment
--   sec.UserModuleAccess
--
-- Vistas de compatibilidad (sin cambios en TypeScript):
--   dbo.DocumentosVenta, dbo.DocumentosVentaDetalle, dbo.DocumentosVentaPago
--   dbo.DocumentosCompra, dbo.DocumentosCompraDetalle, dbo.DocumentosCompraPago
--   dbo.AccesoUsuarios
-- =============================================================================
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

USE DatqBoxWeb;
GO

PRINT '[21] Inicio migracion tablas documentos a esquemas canonicos...';
GO

-- =============================================================================
-- SECCIÓN 1: TABLAS CANÓNICAS ar.* — VENTAS
-- =============================================================================

-- ar.SalesDocument  (era dbo.DocumentosVenta)
IF OBJECT_ID(N'ar.SalesDocument', N'U') IS NULL
BEGIN
  CREATE TABLE ar.SalesDocument (
    DocumentId            INT             IDENTITY(1,1) NOT NULL,
    DocumentNumber        NVARCHAR(60)    NOT NULL,
    SerialType            NVARCHAR(60)    NOT NULL CONSTRAINT DF_SalesDoc_SerialType DEFAULT (N''),
    OperationType         NVARCHAR(20)    NOT NULL,
    CustomerCode          NVARCHAR(60)    NULL,
    CustomerName          NVARCHAR(255)   NULL,
    FiscalId              NVARCHAR(20)    NULL,
    DocumentDate          DATETIME        NULL CONSTRAINT DF_SalesDoc_DocumentDate DEFAULT GETDATE(),
    DueDate               DATETIME        NULL,
    DocumentTime          NVARCHAR(20)    NULL CONSTRAINT DF_SalesDoc_DocumentTime DEFAULT (CONVERT(NVARCHAR(8), GETDATE(), 108)),
    SubTotal              DECIMAL(18,4)   NULL CONSTRAINT DF_SalesDoc_SubTotal DEFAULT (0),
    TaxableAmount         DECIMAL(18,4)   NULL CONSTRAINT DF_SalesDoc_TaxableAmount DEFAULT (0),
    ExemptAmount          DECIMAL(18,4)   NULL CONSTRAINT DF_SalesDoc_ExemptAmount DEFAULT (0),
    TaxAmount             DECIMAL(18,4)   NULL CONSTRAINT DF_SalesDoc_TaxAmount DEFAULT (0),
    TaxRate               DECIMAL(8,4)    NULL CONSTRAINT DF_SalesDoc_TaxRate DEFAULT (0),
    TotalAmount           DECIMAL(18,4)   NULL CONSTRAINT DF_SalesDoc_TotalAmount DEFAULT (0),
    DiscountAmount        DECIMAL(18,4)   NULL CONSTRAINT DF_SalesDoc_DiscountAmount DEFAULT (0),
    IsVoided              BIT             NULL CONSTRAINT DF_SalesDoc_IsVoided DEFAULT (0),
    IsPaid                NVARCHAR(1)     NULL CONSTRAINT DF_SalesDoc_IsPaid DEFAULT (N'N'),
    IsInvoiced            NVARCHAR(1)     NULL CONSTRAINT DF_SalesDoc_IsInvoiced DEFAULT (N'N'),
    IsDelivered           NVARCHAR(1)     NULL CONSTRAINT DF_SalesDoc_IsDelivered DEFAULT (N'N'),
    OriginDocumentNumber  NVARCHAR(60)    NULL,
    OriginDocumentType    NVARCHAR(20)    NULL,
    ControlNumber         NVARCHAR(60)    NULL,
    IsLegal               BIT             NULL CONSTRAINT DF_SalesDoc_IsLegal DEFAULT (0),
    IsPrinted             BIT             NULL CONSTRAINT DF_SalesDoc_IsPrinted DEFAULT (0),
    Notes                 NVARCHAR(500)   NULL,
    Concept               NVARCHAR(255)   NULL,
    PaymentTerms          NVARCHAR(255)   NULL,
    ShipToAddress         NVARCHAR(255)   NULL,
    SellerCode            NVARCHAR(60)    NULL,
    DepartmentCode        NVARCHAR(50)    NULL,
    LocationCode          NVARCHAR(100)   NULL,
    CurrencyCode          NVARCHAR(20)    NULL CONSTRAINT DF_SalesDoc_CurrencyCode DEFAULT (N'BS'),
    ExchangeRate          DECIMAL(18,6)   NULL CONSTRAINT DF_SalesDoc_ExchangeRate DEFAULT (1),
    UserCode              NVARCHAR(60)    NULL CONSTRAINT DF_SalesDoc_UserCode DEFAULT (N'API'),
    ReportDate            DATETIME        NULL CONSTRAINT DF_SalesDoc_ReportDate DEFAULT GETDATE(),
    HostName              NVARCHAR(255)   NULL CONSTRAINT DF_SalesDoc_HostName DEFAULT (HOST_NAME()),
    VehiclePlate          NVARCHAR(20)    NULL,
    Mileage               INT             NULL,
    TollAmount            DECIMAL(18,4)   NULL CONSTRAINT DF_SalesDoc_TollAmount DEFAULT (0),
    CreatedAt             DATETIME2(0)    NOT NULL CONSTRAINT DF_SalesDoc_CreatedAt DEFAULT SYSUTCDATETIME(),
    UpdatedAt             DATETIME2(0)    NOT NULL CONSTRAINT DF_SalesDoc_UpdatedAt DEFAULT SYSUTCDATETIME(),
    CreatedByUserId       INT             NULL,
    UpdatedByUserId       INT             NULL,
    IsDeleted             BIT             NOT NULL CONSTRAINT DF_SalesDoc_IsDeleted DEFAULT (0),
    DeletedAt             DATETIME2(0)    NULL,
    DeletedByUserId       INT             NULL,
    RowVer                ROWVERSION      NOT NULL,
    CONSTRAINT PK_SalesDocument PRIMARY KEY (DocumentId)
  );
  ALTER TABLE ar.SalesDocument ADD
    CONSTRAINT UQ_SalesDocument_NumDocOp UNIQUE (DocumentNumber, OperationType);
  CREATE INDEX IX_SalesDocument_OpDate
    ON ar.SalesDocument (OperationType, DocumentDate DESC) WHERE IsDeleted = 0;
  CREATE INDEX IX_SalesDocument_Customer
    ON ar.SalesDocument (CustomerCode) WHERE IsDeleted = 0;
END;
GO

-- ar.SalesDocumentLine  (era dbo.DocumentosVentaDetalle)
IF OBJECT_ID(N'ar.SalesDocumentLine', N'U') IS NULL
BEGIN
  CREATE TABLE ar.SalesDocumentLine (
    LineId            INT             IDENTITY(1,1) NOT NULL,
    DocumentNumber    NVARCHAR(60)    NOT NULL,
    OperationType     NVARCHAR(20)    NOT NULL,
    LineNumber        INT             NULL CONSTRAINT DF_SalesDocLine_LineNumber DEFAULT (0),
    ProductCode       NVARCHAR(60)    NULL,
    Description       NVARCHAR(255)   NULL,
    AlternateCode     NVARCHAR(60)    NULL,
    Quantity          DECIMAL(18,4)   NULL CONSTRAINT DF_SalesDocLine_Quantity DEFAULT (0),
    UnitPrice         DECIMAL(18,4)   NULL CONSTRAINT DF_SalesDocLine_UnitPrice DEFAULT (0),
    DiscountedPrice   DECIMAL(18,4)   NULL,
    UnitCost          DECIMAL(18,4)   NULL CONSTRAINT DF_SalesDocLine_UnitCost DEFAULT (0),
    SubTotal          DECIMAL(18,4)   NULL CONSTRAINT DF_SalesDocLine_SubTotal DEFAULT (0),
    DiscountAmount    DECIMAL(18,4)   NULL CONSTRAINT DF_SalesDocLine_DiscountAmount DEFAULT (0),
    TotalAmount       DECIMAL(18,4)   NULL CONSTRAINT DF_SalesDocLine_TotalAmount DEFAULT (0),
    TaxRate           DECIMAL(8,4)    NULL CONSTRAINT DF_SalesDocLine_TaxRate DEFAULT (0),
    TaxAmount         DECIMAL(18,4)   NULL CONSTRAINT DF_SalesDocLine_TaxAmount DEFAULT (0),
    IsVoided          BIT             NULL CONSTRAINT DF_SalesDocLine_IsVoided DEFAULT (0),
    RelatedRef        NVARCHAR(10)    NULL CONSTRAINT DF_SalesDocLine_RelatedRef DEFAULT (N'0'),
    UserCode          NVARCHAR(60)    NULL CONSTRAINT DF_SalesDocLine_UserCode DEFAULT (N'API'),
    LineDate          DATETIME        NULL CONSTRAINT DF_SalesDocLine_LineDate DEFAULT GETDATE(),
    CreatedAt         DATETIME2(0)    NOT NULL CONSTRAINT DF_SalesDocLine_CreatedAt DEFAULT SYSUTCDATETIME(),
    UpdatedAt         DATETIME2(0)    NOT NULL CONSTRAINT DF_SalesDocLine_UpdatedAt DEFAULT SYSUTCDATETIME(),
    CreatedByUserId   INT             NULL,
    UpdatedByUserId   INT             NULL,
    IsDeleted         BIT             NOT NULL CONSTRAINT DF_SalesDocLine_IsDeleted DEFAULT (0),
    DeletedAt         DATETIME2(0)    NULL,
    DeletedByUserId   INT             NULL,
    RowVer            ROWVERSION      NOT NULL,
    CONSTRAINT PK_SalesDocumentLine PRIMARY KEY (LineId),
    CONSTRAINT FK_SalesDocLine_SalesDoc FOREIGN KEY (DocumentNumber, OperationType)
      REFERENCES ar.SalesDocument (DocumentNumber, OperationType)
  );
  CREATE INDEX IX_SalesDocLine_DocNum
    ON ar.SalesDocumentLine (DocumentNumber, OperationType) WHERE IsDeleted = 0;
END;
GO

-- ar.SalesDocumentPayment  (era dbo.DocumentosVentaPago)
IF OBJECT_ID(N'ar.SalesDocumentPayment', N'U') IS NULL
BEGIN
  CREATE TABLE ar.SalesDocumentPayment (
    PaymentId         INT             IDENTITY(1,1) NOT NULL,
    DocumentNumber    NVARCHAR(60)    NOT NULL,
    OperationType     NVARCHAR(20)    NOT NULL CONSTRAINT DF_SalesDocPay_OpType DEFAULT (N'FACT'),
    PaymentMethod     NVARCHAR(30)    NULL,
    BankCode          NVARCHAR(60)    NULL,
    PaymentNumber     NVARCHAR(60)    NULL,
    Amount            DECIMAL(18,4)   NULL CONSTRAINT DF_SalesDocPay_Amount DEFAULT (0),
    AmountBs          DECIMAL(18,4)   NULL CONSTRAINT DF_SalesDocPay_AmountBs DEFAULT (0),
    ExchangeRate      DECIMAL(18,6)   NULL CONSTRAINT DF_SalesDocPay_ExchangeRate DEFAULT (1),
    PaymentDate       DATETIME        NULL CONSTRAINT DF_SalesDocPay_PaymentDate DEFAULT GETDATE(),
    DueDate           DATETIME        NULL,
    ReferenceNumber   NVARCHAR(100)   NULL,
    UserCode          NVARCHAR(60)    NULL CONSTRAINT DF_SalesDocPay_UserCode DEFAULT (N'API'),
    CreatedAt         DATETIME2(0)    NOT NULL CONSTRAINT DF_SalesDocPay_CreatedAt DEFAULT SYSUTCDATETIME(),
    UpdatedAt         DATETIME2(0)    NOT NULL CONSTRAINT DF_SalesDocPay_UpdatedAt DEFAULT SYSUTCDATETIME(),
    CreatedByUserId   INT             NULL,
    UpdatedByUserId   INT             NULL,
    IsDeleted         BIT             NOT NULL CONSTRAINT DF_SalesDocPay_IsDeleted DEFAULT (0),
    DeletedAt         DATETIME2(0)    NULL,
    DeletedByUserId   INT             NULL,
    RowVer            ROWVERSION      NOT NULL,
    CONSTRAINT PK_SalesDocumentPayment PRIMARY KEY (PaymentId),
    CONSTRAINT FK_SalesDocPay_SalesDoc FOREIGN KEY (DocumentNumber, OperationType)
      REFERENCES ar.SalesDocument (DocumentNumber, OperationType)
  );
  CREATE INDEX IX_SalesDocPayment_DocNum
    ON ar.SalesDocumentPayment (DocumentNumber, OperationType) WHERE IsDeleted = 0;
END;
GO

-- =============================================================================
-- SECCIÓN 2: TABLAS CANÓNICAS ap.* — COMPRAS
-- =============================================================================

-- ap.PurchaseDocument  (era dbo.DocumentosCompra)
IF OBJECT_ID(N'ap.PurchaseDocument', N'U') IS NULL
BEGIN
  CREATE TABLE ap.PurchaseDocument (
    DocumentId            INT             IDENTITY(1,1) NOT NULL,
    DocumentNumber        NVARCHAR(60)    NOT NULL,
    SerialType            NVARCHAR(60)    NOT NULL CONSTRAINT DF_PurchDoc_SerialType DEFAULT (N''),
    OperationType         NVARCHAR(20)    NOT NULL CONSTRAINT DF_PurchDoc_OperationType DEFAULT (N'COMPRA'),
    SupplierCode          NVARCHAR(60)    NULL,
    SupplierName          NVARCHAR(255)   NULL,
    FiscalId              NVARCHAR(15)    NULL,
    DocumentDate          DATETIME        NULL CONSTRAINT DF_PurchDoc_DocumentDate DEFAULT GETDATE(),
    DueDate               DATETIME        NULL,
    ReceiptDate           DATETIME        NULL,
    PaymentDate           DATETIME        NULL,
    DocumentTime          NVARCHAR(20)    NULL CONSTRAINT DF_PurchDoc_DocumentTime DEFAULT (CONVERT(NVARCHAR(8), GETDATE(), 108)),
    SubTotal              DECIMAL(18,4)   NULL CONSTRAINT DF_PurchDoc_SubTotal DEFAULT (0),
    TaxableAmount         DECIMAL(18,4)   NULL CONSTRAINT DF_PurchDoc_TaxableAmount DEFAULT (0),
    ExemptAmount          DECIMAL(18,4)   NULL CONSTRAINT DF_PurchDoc_ExemptAmount DEFAULT (0),
    TaxAmount             DECIMAL(18,4)   NULL CONSTRAINT DF_PurchDoc_TaxAmount DEFAULT (0),
    TaxRate               DECIMAL(8,4)    NULL CONSTRAINT DF_PurchDoc_TaxRate DEFAULT (0),
    TotalAmount           DECIMAL(18,4)   NULL CONSTRAINT DF_PurchDoc_TotalAmount DEFAULT (0),
    ExemptTotalAmount     DECIMAL(18,4)   NULL CONSTRAINT DF_PurchDoc_ExemptTotalAmount DEFAULT (0),
    DiscountAmount        DECIMAL(18,4)   NULL CONSTRAINT DF_PurchDoc_DiscountAmount DEFAULT (0),
    IsVoided              BIT             NULL CONSTRAINT DF_PurchDoc_IsVoided DEFAULT (0),
    IsPaid                NVARCHAR(1)     NULL CONSTRAINT DF_PurchDoc_IsPaid DEFAULT (N'N'),
    IsReceived            NVARCHAR(1)     NULL CONSTRAINT DF_PurchDoc_IsReceived DEFAULT (N'N'),
    IsLegal               BIT             NULL CONSTRAINT DF_PurchDoc_IsLegal DEFAULT (0),
    OriginDocumentNumber  NVARCHAR(60)    NULL,
    ControlNumber         NVARCHAR(60)    NULL,
    VoucherNumber         NVARCHAR(50)    NULL,
    VoucherDate           DATETIME        NULL,
    RetainedTax           DECIMAL(18,4)   NULL CONSTRAINT DF_PurchDoc_RetainedTax DEFAULT (0),
    IsrCode               NVARCHAR(50)    NULL,
    IsrAmount             DECIMAL(18,4)   NULL CONSTRAINT DF_PurchDoc_IsrAmount DEFAULT (0),
    IsrSubjectAmount      DECIMAL(18,4)   NULL CONSTRAINT DF_PurchDoc_IsrSubjectAmount DEFAULT (0),
    RetentionRate         DECIMAL(8,4)    NULL CONSTRAINT DF_PurchDoc_RetentionRate DEFAULT (0),
    ImportAmount          DECIMAL(18,4)   NULL CONSTRAINT DF_PurchDoc_ImportAmount DEFAULT (0),
    ImportTax             DECIMAL(18,4)   NULL CONSTRAINT DF_PurchDoc_ImportTax DEFAULT (0),
    ImportBase            DECIMAL(18,4)   NULL CONSTRAINT DF_PurchDoc_ImportBase DEFAULT (0),
    FreightAmount         DECIMAL(18,4)   NULL CONSTRAINT DF_PurchDoc_FreightAmount DEFAULT (0),
    Concept               NVARCHAR(255)   NULL,
    Notes                 NVARCHAR(500)   NULL,
    OrderNumber           NVARCHAR(20)    NULL,
    ReceivedBy            NVARCHAR(20)    NULL,
    WarehouseCode         NVARCHAR(50)    NULL,
    CurrencyCode          NVARCHAR(20)    NULL CONSTRAINT DF_PurchDoc_CurrencyCode DEFAULT (N'BS'),
    ExchangeRate          DECIMAL(18,6)   NULL CONSTRAINT DF_PurchDoc_ExchangeRate DEFAULT (1),
    UsdAmount             DECIMAL(18,4)   NULL CONSTRAINT DF_PurchDoc_UsdAmount DEFAULT (0),
    UserCode              NVARCHAR(60)    NULL CONSTRAINT DF_PurchDoc_UserCode DEFAULT (N'API'),
    ShortUserCode         NVARCHAR(10)    NULL,
    ReportDate            DATETIME        NULL CONSTRAINT DF_PurchDoc_ReportDate DEFAULT GETDATE(),
    HostName              NVARCHAR(255)   NULL CONSTRAINT DF_PurchDoc_HostName DEFAULT (HOST_NAME()),
    CreatedAt             DATETIME2(0)    NOT NULL CONSTRAINT DF_PurchDoc_CreatedAt DEFAULT SYSUTCDATETIME(),
    UpdatedAt             DATETIME2(0)    NOT NULL CONSTRAINT DF_PurchDoc_UpdatedAt DEFAULT SYSUTCDATETIME(),
    CreatedByUserId       INT             NULL,
    UpdatedByUserId       INT             NULL,
    IsDeleted             BIT             NOT NULL CONSTRAINT DF_PurchDoc_IsDeleted DEFAULT (0),
    DeletedAt             DATETIME2(0)    NULL,
    DeletedByUserId       INT             NULL,
    RowVer                ROWVERSION      NOT NULL,
    CONSTRAINT PK_PurchaseDocument PRIMARY KEY (DocumentId)
  );
  ALTER TABLE ap.PurchaseDocument ADD
    CONSTRAINT UQ_PurchaseDocument_NumDocOp UNIQUE (DocumentNumber, OperationType);
  CREATE INDEX IX_PurchaseDocument_OpDate
    ON ap.PurchaseDocument (OperationType, DocumentDate DESC) WHERE IsDeleted = 0;
  CREATE INDEX IX_PurchaseDocument_Supplier
    ON ap.PurchaseDocument (SupplierCode) WHERE IsDeleted = 0;
END;
GO

-- ap.PurchaseDocumentLine  (era dbo.DocumentosCompraDetalle)
IF OBJECT_ID(N'ap.PurchaseDocumentLine', N'U') IS NULL
BEGIN
  CREATE TABLE ap.PurchaseDocumentLine (
    LineId            INT             IDENTITY(1,1) NOT NULL,
    DocumentNumber    NVARCHAR(60)    NOT NULL,
    OperationType     NVARCHAR(20)    NOT NULL CONSTRAINT DF_PurchDocLine_OpType DEFAULT (N'COMPRA'),
    LineNumber        INT             NULL CONSTRAINT DF_PurchDocLine_LineNumber DEFAULT (0),
    ProductCode       NVARCHAR(60)    NULL,
    Description       NVARCHAR(255)   NULL,
    Quantity          DECIMAL(18,4)   NULL CONSTRAINT DF_PurchDocLine_Quantity DEFAULT (0),
    UnitPrice         DECIMAL(18,4)   NULL CONSTRAINT DF_PurchDocLine_UnitPrice DEFAULT (0),
    UnitCost          DECIMAL(18,4)   NULL CONSTRAINT DF_PurchDocLine_UnitCost DEFAULT (0),
    SubTotal          DECIMAL(18,4)   NULL CONSTRAINT DF_PurchDocLine_SubTotal DEFAULT (0),
    DiscountAmount    DECIMAL(18,4)   NULL CONSTRAINT DF_PurchDocLine_DiscountAmount DEFAULT (0),
    TotalAmount       DECIMAL(18,4)   NULL CONSTRAINT DF_PurchDocLine_TotalAmount DEFAULT (0),
    TaxRate           DECIMAL(8,4)    NULL CONSTRAINT DF_PurchDocLine_TaxRate DEFAULT (0),
    TaxAmount         DECIMAL(18,4)   NULL CONSTRAINT DF_PurchDocLine_TaxAmount DEFAULT (0),
    IsVoided          BIT             NULL CONSTRAINT DF_PurchDocLine_IsVoided DEFAULT (0),
    UserCode          NVARCHAR(60)    NULL CONSTRAINT DF_PurchDocLine_UserCode DEFAULT (N'API'),
    LineDate          DATETIME        NULL CONSTRAINT DF_PurchDocLine_LineDate DEFAULT GETDATE(),
    CreatedAt         DATETIME2(0)    NOT NULL CONSTRAINT DF_PurchDocLine_CreatedAt DEFAULT SYSUTCDATETIME(),
    UpdatedAt         DATETIME2(0)    NOT NULL CONSTRAINT DF_PurchDocLine_UpdatedAt DEFAULT SYSUTCDATETIME(),
    CreatedByUserId   INT             NULL,
    UpdatedByUserId   INT             NULL,
    IsDeleted         BIT             NOT NULL CONSTRAINT DF_PurchDocLine_IsDeleted DEFAULT (0),
    DeletedAt         DATETIME2(0)    NULL,
    DeletedByUserId   INT             NULL,
    RowVer            ROWVERSION      NOT NULL,
    CONSTRAINT PK_PurchaseDocumentLine PRIMARY KEY (LineId),
    CONSTRAINT FK_PurchDocLine_PurchDoc FOREIGN KEY (DocumentNumber, OperationType)
      REFERENCES ap.PurchaseDocument (DocumentNumber, OperationType)
  );
  CREATE INDEX IX_PurchaseDocLine_DocNum
    ON ap.PurchaseDocumentLine (DocumentNumber, OperationType) WHERE IsDeleted = 0;
END;
GO

-- ap.PurchaseDocumentPayment  (era dbo.DocumentosCompraPago)
IF OBJECT_ID(N'ap.PurchaseDocumentPayment', N'U') IS NULL
BEGIN
  CREATE TABLE ap.PurchaseDocumentPayment (
    PaymentId         INT             IDENTITY(1,1) NOT NULL,
    DocumentNumber    NVARCHAR(60)    NOT NULL,
    OperationType     NVARCHAR(20)    NOT NULL CONSTRAINT DF_PurchDocPay_OpType DEFAULT (N'COMPRA'),
    PaymentMethod     NVARCHAR(30)    NULL,
    BankCode          NVARCHAR(60)    NULL,
    PaymentNumber     NVARCHAR(60)    NULL,
    Amount            DECIMAL(18,4)   NULL CONSTRAINT DF_PurchDocPay_Amount DEFAULT (0),
    PaymentDate       DATETIME        NULL CONSTRAINT DF_PurchDocPay_PaymentDate DEFAULT GETDATE(),
    DueDate           DATETIME        NULL,
    ReferenceNumber   NVARCHAR(100)   NULL,
    UserCode          NVARCHAR(60)    NULL CONSTRAINT DF_PurchDocPay_UserCode DEFAULT (N'API'),
    CreatedAt         DATETIME2(0)    NOT NULL CONSTRAINT DF_PurchDocPay_CreatedAt DEFAULT SYSUTCDATETIME(),
    UpdatedAt         DATETIME2(0)    NOT NULL CONSTRAINT DF_PurchDocPay_UpdatedAt DEFAULT SYSUTCDATETIME(),
    CreatedByUserId   INT             NULL,
    UpdatedByUserId   INT             NULL,
    IsDeleted         BIT             NOT NULL CONSTRAINT DF_PurchDocPay_IsDeleted DEFAULT (0),
    DeletedAt         DATETIME2(0)    NULL,
    DeletedByUserId   INT             NULL,
    RowVer            ROWVERSION      NOT NULL,
    CONSTRAINT PK_PurchaseDocumentPayment PRIMARY KEY (PaymentId),
    CONSTRAINT FK_PurchDocPay_PurchDoc FOREIGN KEY (DocumentNumber, OperationType)
      REFERENCES ap.PurchaseDocument (DocumentNumber, OperationType)
  );
  CREATE INDEX IX_PurchaseDocPayment_DocNum
    ON ap.PurchaseDocumentPayment (DocumentNumber, OperationType) WHERE IsDeleted = 0;
END;
GO

-- =============================================================================
-- SECCIÓN 3: sec.UserModuleAccess  (era dbo.AccesoUsuarios)
-- =============================================================================

IF OBJECT_ID(N'sec.UserModuleAccess', N'U') IS NULL
BEGIN
  CREATE TABLE sec.UserModuleAccess (
    AccessId    INT           IDENTITY(1,1) NOT NULL,
    UserCode    NVARCHAR(20)  NOT NULL,
    ModuleCode  NVARCHAR(60)  NOT NULL,
    IsAllowed   BIT           NOT NULL CONSTRAINT DF_UserModuleAccess_IsAllowed DEFAULT (1),
    CreatedAt   DATETIME2(0)  NOT NULL CONSTRAINT DF_UserModuleAccess_CreatedAt DEFAULT SYSUTCDATETIME(),
    UpdatedAt   DATETIME2(0)  NOT NULL CONSTRAINT DF_UserModuleAccess_UpdatedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_UserModuleAccess PRIMARY KEY (AccessId),
    CONSTRAINT UQ_UserModuleAccess UNIQUE (UserCode, ModuleCode)
  );
END;
GO

-- Migrar datos de dbo.AccesoUsuarios → sec.UserModuleAccess
IF EXISTS (SELECT 1 FROM dbo.AccesoUsuarios)
BEGIN
  SET IDENTITY_INSERT sec.UserModuleAccess OFF;
  INSERT INTO sec.UserModuleAccess (UserCode, ModuleCode, IsAllowed, CreatedAt, UpdatedAt)
  SELECT Cod_Usuario, Modulo, Permitido, CreatedAt, UpdatedAt
  FROM dbo.AccesoUsuarios
  WHERE NOT EXISTS (
    SELECT 1 FROM sec.UserModuleAccess m
    WHERE m.UserCode = dbo.AccesoUsuarios.Cod_Usuario
      AND m.ModuleCode = dbo.AccesoUsuarios.Modulo
  );
END;
GO

-- =============================================================================
-- SECCIÓN 4: ELIMINAR TABLAS dbo.* ANTIGUAS (vacías)
-- Orden: detalle/pago primero (FK dependientes), luego cabeceras
-- =============================================================================

-- Eliminar FKs primero
IF OBJECT_ID(N'FK_DocVentaDet_DocVenta') IS NOT NULL
  ALTER TABLE dbo.DocumentosVentaDetalle DROP CONSTRAINT FK_DocVentaDet_DocVenta;
IF OBJECT_ID(N'FK_DocVentaPago_DocVenta') IS NOT NULL
  ALTER TABLE dbo.DocumentosVentaPago DROP CONSTRAINT FK_DocVentaPago_DocVenta;
IF OBJECT_ID(N'FK_DocCompraDet_DocCompra') IS NOT NULL
  ALTER TABLE dbo.DocumentosCompraDetalle DROP CONSTRAINT FK_DocCompraDet_DocCompra;
IF OBJECT_ID(N'FK_DocCompraPago_DocCompra') IS NOT NULL
  ALTER TABLE dbo.DocumentosCompraPago DROP CONSTRAINT FK_DocCompraPago_DocCompra;
GO

IF OBJECT_ID(N'dbo.DocumentosVentaDetalle', N'U') IS NOT NULL DROP TABLE dbo.DocumentosVentaDetalle;
IF OBJECT_ID(N'dbo.DocumentosVentaPago',    N'U') IS NOT NULL DROP TABLE dbo.DocumentosVentaPago;
IF OBJECT_ID(N'dbo.DocumentosVenta',        N'U') IS NOT NULL DROP TABLE dbo.DocumentosVenta;
IF OBJECT_ID(N'dbo.DocumentosCompraDetalle',N'U') IS NOT NULL DROP TABLE dbo.DocumentosCompraDetalle;
IF OBJECT_ID(N'dbo.DocumentosCompraPago',   N'U') IS NOT NULL DROP TABLE dbo.DocumentosCompraPago;
IF OBJECT_ID(N'dbo.DocumentosCompra',       N'U') IS NOT NULL DROP TABLE dbo.DocumentosCompra;
IF OBJECT_ID(N'dbo.AccesoUsuarios',         N'U') IS NOT NULL DROP TABLE dbo.AccesoUsuarios;
GO

-- =============================================================================
-- SECCIÓN 5: VISTAS DE COMPATIBILIDAD dbo.* → canónicas
-- Exponen los nombres de columna originales para que el código TypeScript
-- no necesite cambios (INFORMATION_SCHEMA.COLUMNS las devuelve correctamente)
-- =============================================================================

-- --- dbo.DocumentosVenta ---
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

-- --- dbo.DocumentosVentaDetalle ---
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

-- --- dbo.DocumentosVentaPago ---
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

-- --- dbo.DocumentosCompra ---
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

-- --- dbo.DocumentosCompraDetalle ---
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

-- --- dbo.DocumentosCompraPago ---
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

-- --- dbo.AccesoUsuarios ---
CREATE VIEW dbo.AccesoUsuarios AS
SELECT
    UserCode   AS Cod_Usuario,
    ModuleCode AS Modulo,
    IsAllowed  AS Permitido,
    CreatedAt,
    UpdatedAt
FROM sec.UserModuleAccess;
GO

-- =============================================================================
-- SECCIÓN 6: INSTEAD OF TRIGGERS para DML a través de las vistas
-- Los triggers mapean columnas legacy → columnas canónicas
-- =============================================================================

-- -----------------------------------------------------------------------
-- dbo.DocumentosVenta — INSERT
-- -----------------------------------------------------------------------
CREATE TRIGGER trg_DocumentosVenta_IOI ON dbo.DocumentosVenta
INSTEAD OF INSERT AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO ar.SalesDocument (
        DocumentNumber, SerialType, OperationType, CustomerCode, CustomerName, FiscalId,
        DocumentDate, DueDate, DocumentTime, SubTotal, TaxableAmount, ExemptAmount,
        TaxAmount, TaxRate, TotalAmount, DiscountAmount, IsVoided, IsPaid, IsInvoiced,
        IsDelivered, OriginDocumentNumber, OriginDocumentType, ControlNumber, IsLegal,
        IsPrinted, Notes, Concept, PaymentTerms, ShipToAddress, SellerCode, DepartmentCode,
        LocationCode, CurrencyCode, ExchangeRate, UserCode, ReportDate, HostName,
        VehiclePlate, Mileage, TollAmount, CreatedByUserId, UpdatedByUserId
    )
    SELECT
        NUM_DOC, SERIALTIPO, TIPO_OPERACION, CODIGO, NOMBRE, RIF,
        FECHA, FECHA_VENCE, HORA, SUBTOTAL, MONTO_GRA, MONTO_EXE,
        IVA, ALICUOTA, TOTAL, DESCUENTO, ANULADA, CANCELADA, FACTURADA,
        ENTREGADA, DOC_ORIGEN, TIPO_DOC_ORIGEN, NUM_CONTROL, LEGAL,
        IMPRESA, OBSERV, CONCEPTO, TERMINOS, DESPACHAR, VENDEDOR, DEPARTAMENTO,
        LOCACION, MONEDA, TASA_CAMBIO, COD_USUARIO, FECHA_REPORTE, COMPUTER,
        PLACAS, KILOMETROS, PEAJE, CreatedByUserId, UpdatedByUserId
    FROM INSERTED;
END;
GO

-- dbo.DocumentosVenta — UPDATE
CREATE TRIGGER trg_DocumentosVenta_IOU ON dbo.DocumentosVenta
INSTEAD OF UPDATE AS
BEGIN
    SET NOCOUNT ON;
    UPDATE t SET
        DocumentNumber = i.NUM_DOC, SerialType = i.SERIALTIPO, OperationType = i.TIPO_OPERACION,
        CustomerCode = i.CODIGO, CustomerName = i.NOMBRE, FiscalId = i.RIF,
        DocumentDate = i.FECHA, DueDate = i.FECHA_VENCE, DocumentTime = i.HORA,
        SubTotal = i.SUBTOTAL, TaxableAmount = i.MONTO_GRA, ExemptAmount = i.MONTO_EXE,
        TaxAmount = i.IVA, TaxRate = i.ALICUOTA, TotalAmount = i.TOTAL,
        DiscountAmount = i.DESCUENTO, IsVoided = i.ANULADA, IsPaid = i.CANCELADA,
        IsInvoiced = i.FACTURADA, IsDelivered = i.ENTREGADA,
        OriginDocumentNumber = i.DOC_ORIGEN, OriginDocumentType = i.TIPO_DOC_ORIGEN,
        ControlNumber = i.NUM_CONTROL, IsLegal = i.LEGAL, IsPrinted = i.IMPRESA,
        Notes = i.OBSERV, Concept = i.CONCEPTO, PaymentTerms = i.TERMINOS,
        ShipToAddress = i.DESPACHAR, SellerCode = i.VENDEDOR, DepartmentCode = i.DEPARTAMENTO,
        LocationCode = i.LOCACION, CurrencyCode = i.MONEDA, ExchangeRate = i.TASA_CAMBIO,
        UserCode = i.COD_USUARIO, ReportDate = i.FECHA_REPORTE, HostName = i.COMPUTER,
        VehiclePlate = i.PLACAS, Mileage = i.KILOMETROS, TollAmount = i.PEAJE,
        UpdatedAt = SYSUTCDATETIME(), UpdatedByUserId = i.UpdatedByUserId,
        IsDeleted = i.IsDeleted, DeletedAt = i.DeletedAt, DeletedByUserId = i.DeletedByUserId
    FROM ar.SalesDocument t JOIN INSERTED i ON t.DocumentId = i.ID;
END;
GO

-- dbo.DocumentosVenta — DELETE
CREATE TRIGGER trg_DocumentosVenta_IOD ON dbo.DocumentosVenta
INSTEAD OF DELETE AS
BEGIN
    SET NOCOUNT ON;
    UPDATE ar.SalesDocument SET
        IsDeleted = 1, DeletedAt = SYSUTCDATETIME()
    WHERE DocumentId IN (SELECT ID FROM DELETED);
END;
GO

-- -----------------------------------------------------------------------
-- dbo.DocumentosVentaDetalle — INSERT
-- -----------------------------------------------------------------------
CREATE TRIGGER trg_DocumentosVentaDetalle_IOI ON dbo.DocumentosVentaDetalle
INSTEAD OF INSERT AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO ar.SalesDocumentLine (
        DocumentNumber, OperationType, LineNumber, ProductCode, Description, AlternateCode,
        Quantity, UnitPrice, DiscountedPrice, UnitCost, SubTotal, DiscountAmount,
        TotalAmount, TaxRate, TaxAmount, IsVoided, RelatedRef, UserCode, LineDate,
        CreatedByUserId, UpdatedByUserId
    )
    SELECT
        NUM_DOC, TIPO_OPERACION, RENGLON, COD_SERV, DESCRIPCION, COD_ALTERNO,
        CANTIDAD, PRECIO, PRECIO_DESCUENTO, COSTO, SUBTOTAL, DESCUENTO,
        TOTAL, ALICUOTA, MONTO_IVA, ANULADA, RELACIONADA, CO_USUARIO, FECHA,
        CreatedByUserId, UpdatedByUserId
    FROM INSERTED;
END;
GO

CREATE TRIGGER trg_DocumentosVentaDetalle_IOU ON dbo.DocumentosVentaDetalle
INSTEAD OF UPDATE AS
BEGIN
    SET NOCOUNT ON;
    UPDATE t SET
        DocumentNumber = i.NUM_DOC, OperationType = i.TIPO_OPERACION, LineNumber = i.RENGLON,
        ProductCode = i.COD_SERV, Description = i.DESCRIPCION, AlternateCode = i.COD_ALTERNO,
        Quantity = i.CANTIDAD, UnitPrice = i.PRECIO, DiscountedPrice = i.PRECIO_DESCUENTO,
        UnitCost = i.COSTO, SubTotal = i.SUBTOTAL, DiscountAmount = i.DESCUENTO,
        TotalAmount = i.TOTAL, TaxRate = i.ALICUOTA, TaxAmount = i.MONTO_IVA,
        IsVoided = i.ANULADA, RelatedRef = i.RELACIONADA, UserCode = i.CO_USUARIO,
        LineDate = i.FECHA, UpdatedAt = SYSUTCDATETIME()
    FROM ar.SalesDocumentLine t JOIN INSERTED i ON t.LineId = i.ID;
END;
GO

CREATE TRIGGER trg_DocumentosVentaDetalle_IOD ON dbo.DocumentosVentaDetalle
INSTEAD OF DELETE AS
BEGIN
    SET NOCOUNT ON;
    UPDATE ar.SalesDocumentLine SET IsDeleted = 1, DeletedAt = SYSUTCDATETIME()
    WHERE LineId IN (SELECT ID FROM DELETED);
END;
GO

-- -----------------------------------------------------------------------
-- dbo.DocumentosVentaPago — INSERT
-- -----------------------------------------------------------------------
CREATE TRIGGER trg_DocumentosVentaPago_IOI ON dbo.DocumentosVentaPago
INSTEAD OF INSERT AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO ar.SalesDocumentPayment (
        DocumentNumber, OperationType, PaymentMethod, BankCode, PaymentNumber,
        Amount, AmountBs, ExchangeRate, PaymentDate, DueDate, ReferenceNumber, UserCode,
        CreatedByUserId, UpdatedByUserId
    )
    SELECT
        NUM_DOC, TIPO_OPERACION, TIPO_PAGO, BANCO, NUMERO,
        MONTO, MONTO_BS, TASA_CAMBIO, FECHA, FECHA_VENCE, REFERENCIA, CO_USUARIO,
        CreatedByUserId, UpdatedByUserId
    FROM INSERTED;
END;
GO

CREATE TRIGGER trg_DocumentosVentaPago_IOU ON dbo.DocumentosVentaPago
INSTEAD OF UPDATE AS
BEGIN
    SET NOCOUNT ON;
    UPDATE t SET
        DocumentNumber = i.NUM_DOC, OperationType = i.TIPO_OPERACION,
        PaymentMethod = i.TIPO_PAGO, BankCode = i.BANCO, PaymentNumber = i.NUMERO,
        Amount = i.MONTO, AmountBs = i.MONTO_BS, ExchangeRate = i.TASA_CAMBIO,
        PaymentDate = i.FECHA, DueDate = i.FECHA_VENCE, ReferenceNumber = i.REFERENCIA,
        UserCode = i.CO_USUARIO, UpdatedAt = SYSUTCDATETIME()
    FROM ar.SalesDocumentPayment t JOIN INSERTED i ON t.PaymentId = i.ID;
END;
GO

CREATE TRIGGER trg_DocumentosVentaPago_IOD ON dbo.DocumentosVentaPago
INSTEAD OF DELETE AS
BEGIN
    SET NOCOUNT ON;
    UPDATE ar.SalesDocumentPayment SET IsDeleted = 1, DeletedAt = SYSUTCDATETIME()
    WHERE PaymentId IN (SELECT ID FROM DELETED);
END;
GO

-- -----------------------------------------------------------------------
-- dbo.DocumentosCompra — INSERT
-- -----------------------------------------------------------------------
CREATE TRIGGER trg_DocumentosCompra_IOI ON dbo.DocumentosCompra
INSTEAD OF INSERT AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO ap.PurchaseDocument (
        DocumentNumber, SerialType, OperationType, SupplierCode, SupplierName, FiscalId,
        DocumentDate, DueDate, ReceiptDate, PaymentDate, DocumentTime,
        SubTotal, TaxableAmount, ExemptAmount, TaxAmount, TaxRate, TotalAmount,
        ExemptTotalAmount, DiscountAmount, IsVoided, IsPaid, IsReceived, IsLegal,
        OriginDocumentNumber, ControlNumber, VoucherNumber, VoucherDate,
        RetainedTax, IsrCode, IsrAmount, IsrSubjectAmount, RetentionRate,
        ImportAmount, ImportTax, ImportBase, FreightAmount, Concept, Notes,
        OrderNumber, ReceivedBy, WarehouseCode, CurrencyCode, ExchangeRate,
        UsdAmount, UserCode, ShortUserCode, ReportDate, HostName,
        CreatedByUserId, UpdatedByUserId
    )
    SELECT
        NUM_DOC, SERIALTIPO, TIPO_OPERACION, COD_PROVEEDOR, NOMBRE, RIF,
        FECHA, FECHA_VENCE, FECHA_RECIBO, FECHA_PAGO, HORA,
        SUBTOTAL, MONTO_GRA, MONTO_EXE, IVA, ALICUOTA, TOTAL,
        EXENTO, DESCUENTO, ANULADA, CANCELADA, RECIBIDA, LEGAL,
        DOC_ORIGEN, NUM_CONTROL, NRO_COMPROBANTE, FECHA_COMPROBANTE,
        IVA_RETENIDO, ISLR, MONTO_ISLR, SUJETO_ISLR, TASA_RETENCION,
        IMPORTACION, IVA_IMPORT, BASE_IMPORT, FLETE, CONCEPTO, OBSERV,
        PEDIDO, RECIBIDO, ALMACEN, MONEDA, TASA_CAMBIO,
        PRECIO_DOLLAR, COD_USUARIO, CO_USUARIO, FECHA_REPORTE, COMPUTER,
        CreatedByUserId, UpdatedByUserId
    FROM INSERTED;
END;
GO

CREATE TRIGGER trg_DocumentosCompra_IOU ON dbo.DocumentosCompra
INSTEAD OF UPDATE AS
BEGIN
    SET NOCOUNT ON;
    UPDATE t SET
        DocumentNumber = i.NUM_DOC, SerialType = i.SERIALTIPO, OperationType = i.TIPO_OPERACION,
        SupplierCode = i.COD_PROVEEDOR, SupplierName = i.NOMBRE, FiscalId = i.RIF,
        DocumentDate = i.FECHA, DueDate = i.FECHA_VENCE, ReceiptDate = i.FECHA_RECIBO,
        PaymentDate = i.FECHA_PAGO, DocumentTime = i.HORA,
        SubTotal = i.SUBTOTAL, TaxableAmount = i.MONTO_GRA, ExemptAmount = i.MONTO_EXE,
        TaxAmount = i.IVA, TaxRate = i.ALICUOTA, TotalAmount = i.TOTAL,
        ExemptTotalAmount = i.EXENTO, DiscountAmount = i.DESCUENTO,
        IsVoided = i.ANULADA, IsPaid = i.CANCELADA, IsReceived = i.RECIBIDA, IsLegal = i.LEGAL,
        OriginDocumentNumber = i.DOC_ORIGEN, ControlNumber = i.NUM_CONTROL,
        VoucherNumber = i.NRO_COMPROBANTE, VoucherDate = i.FECHA_COMPROBANTE,
        RetainedTax = i.IVA_RETENIDO, IsrCode = i.ISLR, IsrAmount = i.MONTO_ISLR,
        IsrSubjectAmount = i.SUJETO_ISLR, RetentionRate = i.TASA_RETENCION,
        ImportAmount = i.IMPORTACION, ImportTax = i.IVA_IMPORT, ImportBase = i.BASE_IMPORT,
        FreightAmount = i.FLETE, Concept = i.CONCEPTO, Notes = i.OBSERV,
        OrderNumber = i.PEDIDO, ReceivedBy = i.RECIBIDO, WarehouseCode = i.ALMACEN,
        CurrencyCode = i.MONEDA, ExchangeRate = i.TASA_CAMBIO, UsdAmount = i.PRECIO_DOLLAR,
        UserCode = i.COD_USUARIO, ShortUserCode = i.CO_USUARIO,
        ReportDate = i.FECHA_REPORTE, HostName = i.COMPUTER,
        UpdatedAt = SYSUTCDATETIME(), UpdatedByUserId = i.UpdatedByUserId,
        IsDeleted = i.IsDeleted, DeletedAt = i.DeletedAt, DeletedByUserId = i.DeletedByUserId
    FROM ap.PurchaseDocument t JOIN INSERTED i ON t.DocumentId = i.ID;
END;
GO

CREATE TRIGGER trg_DocumentosCompra_IOD ON dbo.DocumentosCompra
INSTEAD OF DELETE AS
BEGIN
    SET NOCOUNT ON;
    UPDATE ap.PurchaseDocument SET IsDeleted = 1, DeletedAt = SYSUTCDATETIME()
    WHERE DocumentId IN (SELECT ID FROM DELETED);
END;
GO

-- -----------------------------------------------------------------------
-- dbo.DocumentosCompraDetalle — INSERT / UPDATE / DELETE
-- -----------------------------------------------------------------------
CREATE TRIGGER trg_DocumentosCompraDetalle_IOI ON dbo.DocumentosCompraDetalle
INSTEAD OF INSERT AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO ap.PurchaseDocumentLine (
        DocumentNumber, OperationType, LineNumber, ProductCode, Description,
        Quantity, UnitPrice, UnitCost, SubTotal, DiscountAmount,
        TotalAmount, TaxRate, TaxAmount, IsVoided, UserCode, LineDate,
        CreatedByUserId, UpdatedByUserId
    )
    SELECT
        NUM_DOC, TIPO_OPERACION, RENGLON, COD_SERV, DESCRIPCION,
        CANTIDAD, PRECIO, COSTO, SUBTOTAL, DESCUENTO,
        TOTAL, ALICUOTA, MONTO_IVA, ANULADA, CO_USUARIO, FECHA,
        CreatedByUserId, UpdatedByUserId
    FROM INSERTED;
END;
GO

CREATE TRIGGER trg_DocumentosCompraDetalle_IOU ON dbo.DocumentosCompraDetalle
INSTEAD OF UPDATE AS
BEGIN
    SET NOCOUNT ON;
    UPDATE t SET
        DocumentNumber = i.NUM_DOC, OperationType = i.TIPO_OPERACION, LineNumber = i.RENGLON,
        ProductCode = i.COD_SERV, Description = i.DESCRIPCION,
        Quantity = i.CANTIDAD, UnitPrice = i.PRECIO, UnitCost = i.COSTO,
        SubTotal = i.SUBTOTAL, DiscountAmount = i.DESCUENTO, TotalAmount = i.TOTAL,
        TaxRate = i.ALICUOTA, TaxAmount = i.MONTO_IVA, IsVoided = i.ANULADA,
        UserCode = i.CO_USUARIO, LineDate = i.FECHA, UpdatedAt = SYSUTCDATETIME()
    FROM ap.PurchaseDocumentLine t JOIN INSERTED i ON t.LineId = i.ID;
END;
GO

CREATE TRIGGER trg_DocumentosCompraDetalle_IOD ON dbo.DocumentosCompraDetalle
INSTEAD OF DELETE AS
BEGIN
    SET NOCOUNT ON;
    UPDATE ap.PurchaseDocumentLine SET IsDeleted = 1, DeletedAt = SYSUTCDATETIME()
    WHERE LineId IN (SELECT ID FROM DELETED);
END;
GO

-- -----------------------------------------------------------------------
-- dbo.DocumentosCompraPago — INSERT / UPDATE / DELETE
-- -----------------------------------------------------------------------
CREATE TRIGGER trg_DocumentosCompraPago_IOI ON dbo.DocumentosCompraPago
INSTEAD OF INSERT AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO ap.PurchaseDocumentPayment (
        DocumentNumber, OperationType, PaymentMethod, BankCode, PaymentNumber,
        Amount, PaymentDate, DueDate, ReferenceNumber, UserCode,
        CreatedByUserId, UpdatedByUserId
    )
    SELECT
        NUM_DOC, TIPO_OPERACION, TIPO_PAGO, BANCO, NUMERO,
        MONTO, FECHA, FECHA_VENCE, REFERENCIA, CO_USUARIO,
        CreatedByUserId, UpdatedByUserId
    FROM INSERTED;
END;
GO

CREATE TRIGGER trg_DocumentosCompraPago_IOU ON dbo.DocumentosCompraPago
INSTEAD OF UPDATE AS
BEGIN
    SET NOCOUNT ON;
    UPDATE t SET
        DocumentNumber = i.NUM_DOC, OperationType = i.TIPO_OPERACION,
        PaymentMethod = i.TIPO_PAGO, BankCode = i.BANCO, PaymentNumber = i.NUMERO,
        Amount = i.MONTO, PaymentDate = i.FECHA, DueDate = i.FECHA_VENCE,
        ReferenceNumber = i.REFERENCIA, UserCode = i.CO_USUARIO,
        UpdatedAt = SYSUTCDATETIME()
    FROM ap.PurchaseDocumentPayment t JOIN INSERTED i ON t.PaymentId = i.ID;
END;
GO

CREATE TRIGGER trg_DocumentosCompraPago_IOD ON dbo.DocumentosCompraPago
INSTEAD OF DELETE AS
BEGIN
    SET NOCOUNT ON;
    UPDATE ap.PurchaseDocumentPayment SET IsDeleted = 1, DeletedAt = SYSUTCDATETIME()
    WHERE PaymentId IN (SELECT ID FROM DELETED);
END;
GO

-- -----------------------------------------------------------------------
-- dbo.AccesoUsuarios — INSERT / UPDATE / DELETE
-- -----------------------------------------------------------------------
CREATE TRIGGER trg_AccesoUsuarios_IOI ON dbo.AccesoUsuarios
INSTEAD OF INSERT AS
BEGIN
    SET NOCOUNT ON;
    -- MERGE para upsert (PK compuesta UserCode+ModuleCode)
    MERGE sec.UserModuleAccess AS t
    USING (SELECT Cod_Usuario, Modulo, Permitido FROM INSERTED) AS s
      ON t.UserCode = s.Cod_Usuario AND t.ModuleCode = s.Modulo
    WHEN MATCHED THEN
      UPDATE SET IsAllowed = s.Permitido, UpdatedAt = SYSUTCDATETIME()
    WHEN NOT MATCHED THEN
      INSERT (UserCode, ModuleCode, IsAllowed) VALUES (s.Cod_Usuario, s.Modulo, s.Permitido);
END;
GO

CREATE TRIGGER trg_AccesoUsuarios_IOU ON dbo.AccesoUsuarios
INSTEAD OF UPDATE AS
BEGIN
    SET NOCOUNT ON;
    UPDATE sec.UserModuleAccess SET
        IsAllowed = i.Permitido, UpdatedAt = SYSUTCDATETIME()
    FROM sec.UserModuleAccess m JOIN INSERTED i ON m.UserCode = i.Cod_Usuario AND m.ModuleCode = i.Modulo;
END;
GO

CREATE TRIGGER trg_AccesoUsuarios_IOD ON dbo.AccesoUsuarios
INSTEAD OF DELETE AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM sec.UserModuleAccess
    WHERE UserCode IN (SELECT Cod_Usuario FROM DELETED)
      AND ModuleCode IN (SELECT Modulo FROM DELETED);
END;
GO

PRINT '[21] Tablas canonicas de documentos y vistas de compatibilidad creadas correctamente.';
GO
