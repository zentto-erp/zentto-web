SET NOCOUNT ON;

/*
  Normalizacion incremental de Documentos*:
  1) agrega campos de auditoria en tablas unificadas
  2) expone vistas normalizadas con nombres de columnas canonicos (schema doc)
  Script idempotente
*/

DECLARE @tables TABLE (TableName sysname);
INSERT INTO @tables (TableName)
VALUES
  ('DocumentosVenta'),
  ('DocumentosVentaDetalle'),
  ('DocumentosVentaPago'),
  ('DocumentosCompra'),
  ('DocumentosCompraDetalle'),
  ('DocumentosCompraPago');

DECLARE @t sysname;
DECLARE c CURSOR LOCAL FAST_FORWARD FOR SELECT TableName FROM @tables;
OPEN c;
FETCH NEXT FROM c INTO @t;

WHILE @@FETCH_STATUS = 0
BEGIN
  IF COL_LENGTH('dbo.' + @t, 'CreatedAt') IS NULL
    EXEC('ALTER TABLE [dbo].[' + @t + '] ADD [CreatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_' + @t + '_CreatedAt] DEFAULT SYSUTCDATETIME() WITH VALUES;');

  IF COL_LENGTH('dbo.' + @t, 'UpdatedAt') IS NULL
    EXEC('ALTER TABLE [dbo].[' + @t + '] ADD [UpdatedAt] datetime2(3) NOT NULL CONSTRAINT [DF_' + @t + '_UpdatedAt] DEFAULT SYSUTCDATETIME() WITH VALUES;');

  IF COL_LENGTH('dbo.' + @t, 'CreatedByUserId') IS NULL
    EXEC('ALTER TABLE [dbo].[' + @t + '] ADD [CreatedByUserId] int NULL;');

  IF COL_LENGTH('dbo.' + @t, 'UpdatedByUserId') IS NULL
    EXEC('ALTER TABLE [dbo].[' + @t + '] ADD [UpdatedByUserId] int NULL;');

  IF COL_LENGTH('dbo.' + @t, 'IsDeleted') IS NULL
    EXEC('ALTER TABLE [dbo].[' + @t + '] ADD [IsDeleted] bit NOT NULL CONSTRAINT [DF_' + @t + '_IsDeleted] DEFAULT (0) WITH VALUES;');

  IF COL_LENGTH('dbo.' + @t, 'DeletedAt') IS NULL
    EXEC('ALTER TABLE [dbo].[' + @t + '] ADD [DeletedAt] datetime2(3) NULL;');

  IF COL_LENGTH('dbo.' + @t, 'DeletedByUserId') IS NULL
    EXEC('ALTER TABLE [dbo].[' + @t + '] ADD [DeletedByUserId] int NULL;');

  IF COL_LENGTH('dbo.' + @t, 'RowVer') IS NULL
    EXEC('ALTER TABLE [dbo].[' + @t + '] ADD [RowVer] rowversion;');

  FETCH NEXT FROM c INTO @t;
END

CLOSE c;
DEALLOCATE c;

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'doc')
  EXEC('CREATE SCHEMA [doc] AUTHORIZATION [dbo];');
GO

IF OBJECT_ID('[doc].[SalesDocument]', 'V') IS NOT NULL
  DROP VIEW [doc].[SalesDocument];
GO
CREATE VIEW [doc].[SalesDocument]
AS
SELECT
  dv.[ID] AS [DocumentId],
  dv.[NUM_DOC] AS [DocumentNumber],
  dv.[SERIALTIPO] AS [SerialType],
  dv.[TIPO_OPERACION] AS [DocumentType],
  dv.[CODIGO] AS [CustomerCode],
  dv.[NOMBRE] AS [CustomerName],
  dv.[RIF] AS [FiscalId],
  dv.[FECHA] AS [IssueDate],
  dv.[FECHA_VENCE] AS [DueDate],
  dv.[SUBTOTAL] AS [Subtotal],
  dv.[MONTO_GRA] AS [TaxableAmount],
  dv.[MONTO_EXE] AS [ExemptAmount],
  dv.[IVA] AS [TaxAmount],
  dv.[ALICUOTA] AS [TaxRate],
  dv.[TOTAL] AS [TotalAmount],
  dv.[DESCUENTO] AS [DiscountAmount],
  dv.[ANULADA] AS [IsVoided],
  dv.[CANCELADA] AS [IsCanceled],
  dv.[FACTURADA] AS [IsInvoiced],
  dv.[ENTREGADA] AS [IsDelivered],
  dv.[DOC_ORIGEN] AS [SourceDocumentNumber],
  dv.[TIPO_DOC_ORIGEN] AS [SourceDocumentType],
  dv.[NUM_CONTROL] AS [ControlNumber],
  dv.[OBSERV] AS [Notes],
  dv.[CONCEPTO] AS [Concept],
  dv.[MONEDA] AS [CurrencyCode],
  dv.[TASA_CAMBIO] AS [ExchangeRate],
  dv.[COD_USUARIO] AS [LegacyUserCode],
  dv.[CreatedAt],
  dv.[UpdatedAt],
  dv.[CreatedByUserId],
  dv.[UpdatedByUserId],
  dv.[IsDeleted],
  dv.[DeletedAt],
  dv.[DeletedByUserId],
  dv.[RowVer]
FROM [dbo].[DocumentosVenta] dv;
GO

IF OBJECT_ID('[doc].[SalesDocumentLine]', 'V') IS NOT NULL
  DROP VIEW [doc].[SalesDocumentLine];
GO
CREATE VIEW [doc].[SalesDocumentLine]
AS
SELECT
  d.[ID] AS [LineId],
  d.[NUM_DOC] AS [DocumentNumber],
  d.[TIPO_OPERACION] AS [DocumentType],
  d.[RENGLON] AS [LineNumber],
  d.[COD_SERV] AS [ProductCode],
  d.[DESCRIPCION] AS [Description],
  d.[COD_ALTERNO] AS [AlternateCode],
  d.[CANTIDAD] AS [Quantity],
  d.[PRECIO] AS [UnitPrice],
  d.[PRECIO_DESCUENTO] AS [DiscountUnitPrice],
  d.[COSTO] AS [UnitCost],
  d.[SUBTOTAL] AS [Subtotal],
  d.[DESCUENTO] AS [DiscountAmount],
  d.[TOTAL] AS [LineTotal],
  d.[ALICUOTA] AS [TaxRate],
  d.[MONTO_IVA] AS [TaxAmount],
  d.[ANULADA] AS [IsVoided],
  d.[CreatedAt],
  d.[UpdatedAt],
  d.[CreatedByUserId],
  d.[UpdatedByUserId],
  d.[IsDeleted],
  d.[DeletedAt],
  d.[DeletedByUserId],
  d.[RowVer]
FROM [dbo].[DocumentosVentaDetalle] d;
GO

IF OBJECT_ID('[doc].[SalesDocumentPayment]', 'V') IS NOT NULL
  DROP VIEW [doc].[SalesDocumentPayment];
GO
CREATE VIEW [doc].[SalesDocumentPayment]
AS
SELECT
  p.[ID] AS [PaymentId],
  p.[NUM_DOC] AS [DocumentNumber],
  p.[TIPO_OPERACION] AS [DocumentType],
  p.[TIPO_PAGO] AS [PaymentType],
  p.[BANCO] AS [BankCode],
  p.[NUMERO] AS [ReferenceNumber],
  p.[MONTO] AS [Amount],
  p.[MONTO_BS] AS [AmountLocal],
  p.[TASA_CAMBIO] AS [ExchangeRate],
  p.[FECHA] AS [ApplyDate],
  p.[FECHA_VENCE] AS [DueDate],
  p.[REFERENCIA] AS [PaymentReference],
  p.[CreatedAt],
  p.[UpdatedAt],
  p.[CreatedByUserId],
  p.[UpdatedByUserId],
  p.[IsDeleted],
  p.[DeletedAt],
  p.[DeletedByUserId],
  p.[RowVer]
FROM [dbo].[DocumentosVentaPago] p;
GO

IF OBJECT_ID('[doc].[PurchaseDocument]', 'V') IS NOT NULL
  DROP VIEW [doc].[PurchaseDocument];
GO
CREATE VIEW [doc].[PurchaseDocument]
AS
SELECT
  dc.[ID] AS [DocumentId],
  dc.[NUM_DOC] AS [DocumentNumber],
  dc.[SERIALTIPO] AS [SerialType],
  dc.[TIPO_OPERACION] AS [DocumentType],
  dc.[COD_PROVEEDOR] AS [SupplierCode],
  dc.[NOMBRE] AS [SupplierName],
  dc.[RIF] AS [FiscalId],
  dc.[FECHA] AS [IssueDate],
  dc.[FECHA_VENCE] AS [DueDate],
  dc.[SUBTOTAL] AS [Subtotal],
  dc.[MONTO_GRA] AS [TaxableAmount],
  dc.[MONTO_EXE] AS [ExemptAmount],
  dc.[IVA] AS [TaxAmount],
  dc.[ALICUOTA] AS [TaxRate],
  dc.[TOTAL] AS [TotalAmount],
  dc.[DESCUENTO] AS [DiscountAmount],
  dc.[ANULADA] AS [IsVoided],
  dc.[CANCELADA] AS [IsCanceled],
  dc.[DOC_ORIGEN] AS [SourceDocumentNumber],
  dc.[NUM_CONTROL] AS [ControlNumber],
  dc.[OBSERV] AS [Notes],
  dc.[CONCEPTO] AS [Concept],
  dc.[MONEDA] AS [CurrencyCode],
  dc.[TASA_CAMBIO] AS [ExchangeRate],
  dc.[COD_USUARIO] AS [LegacyUserCode],
  dc.[CreatedAt],
  dc.[UpdatedAt],
  dc.[CreatedByUserId],
  dc.[UpdatedByUserId],
  dc.[IsDeleted],
  dc.[DeletedAt],
  dc.[DeletedByUserId],
  dc.[RowVer]
FROM [dbo].[DocumentosCompra] dc;
GO

IF OBJECT_ID('[doc].[PurchaseDocumentLine]', 'V') IS NOT NULL
  DROP VIEW [doc].[PurchaseDocumentLine];
GO
CREATE VIEW [doc].[PurchaseDocumentLine]
AS
SELECT
  d.[ID] AS [LineId],
  d.[NUM_DOC] AS [DocumentNumber],
  d.[TIPO_OPERACION] AS [DocumentType],
  d.[RENGLON] AS [LineNumber],
  d.[COD_SERV] AS [ProductCode],
  d.[DESCRIPCION] AS [Description],
  d.[CANTIDAD] AS [Quantity],
  d.[PRECIO] AS [UnitPrice],
  d.[COSTO] AS [UnitCost],
  d.[SUBTOTAL] AS [Subtotal],
  d.[DESCUENTO] AS [DiscountAmount],
  d.[TOTAL] AS [LineTotal],
  d.[ALICUOTA] AS [TaxRate],
  d.[MONTO_IVA] AS [TaxAmount],
  d.[ANULADA] AS [IsVoided],
  d.[CreatedAt],
  d.[UpdatedAt],
  d.[CreatedByUserId],
  d.[UpdatedByUserId],
  d.[IsDeleted],
  d.[DeletedAt],
  d.[DeletedByUserId],
  d.[RowVer]
FROM [dbo].[DocumentosCompraDetalle] d;
GO

IF OBJECT_ID('[doc].[PurchaseDocumentPayment]', 'V') IS NOT NULL
  DROP VIEW [doc].[PurchaseDocumentPayment];
GO
CREATE VIEW [doc].[PurchaseDocumentPayment]
AS
SELECT
  p.[ID] AS [PaymentId],
  p.[NUM_DOC] AS [DocumentNumber],
  p.[TIPO_OPERACION] AS [DocumentType],
  p.[TIPO_PAGO] AS [PaymentType],
  p.[BANCO] AS [BankCode],
  p.[NUMERO] AS [ReferenceNumber],
  p.[MONTO] AS [Amount],
  p.[FECHA] AS [ApplyDate],
  p.[FECHA_VENCE] AS [DueDate],
  p.[REFERENCIA] AS [PaymentReference],
  p.[CreatedAt],
  p.[UpdatedAt],
  p.[CreatedByUserId],
  p.[UpdatedByUserId],
  p.[IsDeleted],
  p.[DeletedAt],
  p.[DeletedByUserId],
  p.[RowVer]
FROM [dbo].[DocumentosCompraPago] p;
GO
