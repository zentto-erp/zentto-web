SET NOCOUNT ON;
GO

-- =============================================================================
-- add_audit_and_normalized_views_documentos_unificado.sql
-- ACTUALIZADO: dbo.Documentos* son ahora VIEWs sobre ar.* / ap.* canónicos
--   (script 21_canonical_document_tables.sql ejecutado).
--
-- Las vistas doc.* se reescriben para apuntar directamente a las tablas
-- canónicas ar.* / ap.*, eliminando la doble indirección.
--
-- El cursor original que agregaba columnas de auditoría a dbo.Documentos*
-- ha sido eliminado: esas tablas son ahora VIEWs y no se pueden alterar
-- con ADD COLUMN.  Las columnas de auditoría ya existen en ar.* / ap.*.
-- =============================================================================

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'doc')
  EXEC('CREATE SCHEMA [doc] AUTHORIZATION [dbo];');
GO

-- =============================================================================
-- doc.SalesDocument  (canónico: ar.SalesDocument)
-- =============================================================================
IF OBJECT_ID('[doc].[SalesDocument]', 'V') IS NOT NULL
  DROP VIEW [doc].[SalesDocument];
GO
CREATE VIEW [doc].[SalesDocument]
AS
SELECT
  sd.[DocumentId],
  sd.[DocumentNumber],
  sd.[SerialType],
  sd.[OperationType]          AS [DocumentType],
  sd.[CustomerCode],
  sd.[CustomerName],
  sd.[FiscalId],
  sd.[DocumentDate]           AS [IssueDate],
  sd.[DueDate],
  sd.[SubTotal]               AS [Subtotal],
  sd.[TaxableAmount],
  sd.[ExemptAmount],
  sd.[TaxAmount],
  sd.[TaxRate],
  sd.[TotalAmount],
  sd.[DiscountAmount],
  sd.[IsVoided],
  sd.[IsPaid]                 AS [IsCanceled],
  sd.[IsInvoiced],
  sd.[IsDelivered],
  sd.[OriginDocumentNumber]   AS [SourceDocumentNumber],
  sd.[OriginDocumentType]     AS [SourceDocumentType],
  sd.[ControlNumber],
  sd.[Notes],
  sd.[Concept],
  sd.[CurrencyCode],
  sd.[ExchangeRate],
  sd.[UserCode]               AS [LegacyUserCode],
  sd.[CreatedAt],
  sd.[UpdatedAt],
  sd.[CreatedByUserId],
  sd.[UpdatedByUserId],
  sd.[IsDeleted],
  sd.[DeletedAt],
  sd.[DeletedByUserId],
  sd.[RowVer]
FROM ar.SalesDocument sd;
GO

-- =============================================================================
-- doc.SalesDocumentLine  (canónico: ar.SalesDocumentLine)
-- =============================================================================
IF OBJECT_ID('[doc].[SalesDocumentLine]', 'V') IS NOT NULL
  DROP VIEW [doc].[SalesDocumentLine];
GO
CREATE VIEW [doc].[SalesDocumentLine]
AS
SELECT
  sdl.[LineId],
  sdl.[DocumentNumber],
  sdl.[OperationType]         AS [DocumentType],
  sdl.[LineNumber],
  sdl.[ProductCode],
  sdl.[Description],
  sdl.[AlternateCode],
  sdl.[Quantity],
  sdl.[UnitPrice],
  sdl.[DiscountedPrice]       AS [DiscountUnitPrice],
  sdl.[UnitCost],
  sdl.[SubTotal]              AS [Subtotal],
  sdl.[DiscountAmount],
  sdl.[TotalAmount]           AS [LineTotal],
  sdl.[TaxRate],
  sdl.[TaxAmount],
  sdl.[IsVoided],
  sdl.[CreatedAt],
  sdl.[UpdatedAt],
  sdl.[CreatedByUserId],
  sdl.[UpdatedByUserId],
  sdl.[IsDeleted],
  sdl.[DeletedAt],
  sdl.[DeletedByUserId],
  sdl.[RowVer]
FROM ar.SalesDocumentLine sdl;
GO

-- =============================================================================
-- doc.SalesDocumentPayment  (canónico: ar.SalesDocumentPayment)
-- =============================================================================
IF OBJECT_ID('[doc].[SalesDocumentPayment]', 'V') IS NOT NULL
  DROP VIEW [doc].[SalesDocumentPayment];
GO
CREATE VIEW [doc].[SalesDocumentPayment]
AS
SELECT
  p.[PaymentId],
  p.[DocumentNumber],
  p.[OperationType]           AS [DocumentType],
  p.[PaymentMethod]           AS [PaymentType],
  p.[BankCode],
  p.[PaymentNumber]           AS [ReferenceNumber],
  p.[Amount],
  p.[AmountBs]                AS [AmountLocal],
  p.[ExchangeRate],
  p.[PaymentDate]             AS [ApplyDate],
  p.[DueDate],
  p.[ReferenceNumber]         AS [PaymentReference],
  p.[CreatedAt],
  p.[UpdatedAt],
  p.[CreatedByUserId],
  p.[UpdatedByUserId],
  p.[IsDeleted],
  p.[DeletedAt],
  p.[DeletedByUserId],
  p.[RowVer]
FROM ar.SalesDocumentPayment p;
GO

-- =============================================================================
-- doc.PurchaseDocument  (canónico: ap.PurchaseDocument)
-- =============================================================================
IF OBJECT_ID('[doc].[PurchaseDocument]', 'V') IS NOT NULL
  DROP VIEW [doc].[PurchaseDocument];
GO
CREATE VIEW [doc].[PurchaseDocument]
AS
SELECT
  dc.[DocumentId],
  dc.[DocumentNumber],
  dc.[SerialType],
  dc.[OperationType]          AS [DocumentType],
  dc.[SupplierCode],
  dc.[SupplierName],
  dc.[FiscalId],
  dc.[DocumentDate]           AS [IssueDate],
  dc.[DueDate],
  dc.[SubTotal]               AS [Subtotal],
  dc.[TaxableAmount],
  dc.[ExemptAmount],
  dc.[TaxAmount],
  dc.[TaxRate],
  dc.[TotalAmount],
  dc.[DiscountAmount],
  dc.[IsVoided],
  dc.[IsPaid]                 AS [IsCanceled],
  dc.[OriginDocumentNumber]   AS [SourceDocumentNumber],
  dc.[ControlNumber],
  dc.[Notes],
  dc.[Concept],
  dc.[CurrencyCode],
  dc.[ExchangeRate],
  dc.[UserCode]               AS [LegacyUserCode],
  dc.[CreatedAt],
  dc.[UpdatedAt],
  dc.[CreatedByUserId],
  dc.[UpdatedByUserId],
  dc.[IsDeleted],
  dc.[DeletedAt],
  dc.[DeletedByUserId],
  dc.[RowVer]
FROM ap.PurchaseDocument dc;
GO

-- =============================================================================
-- doc.PurchaseDocumentLine  (canónico: ap.PurchaseDocumentLine)
-- =============================================================================
IF OBJECT_ID('[doc].[PurchaseDocumentLine]', 'V') IS NOT NULL
  DROP VIEW [doc].[PurchaseDocumentLine];
GO
CREATE VIEW [doc].[PurchaseDocumentLine]
AS
SELECT
  d.[LineId],
  d.[DocumentNumber],
  d.[OperationType]           AS [DocumentType],
  d.[LineNumber],
  d.[ProductCode],
  d.[Description],
  d.[Quantity],
  d.[UnitPrice],
  d.[UnitCost],
  d.[SubTotal]                AS [Subtotal],
  d.[DiscountAmount],
  d.[TotalAmount]             AS [LineTotal],
  d.[TaxRate],
  d.[TaxAmount],
  d.[IsVoided],
  d.[CreatedAt],
  d.[UpdatedAt],
  d.[CreatedByUserId],
  d.[UpdatedByUserId],
  d.[IsDeleted],
  d.[DeletedAt],
  d.[DeletedByUserId],
  d.[RowVer]
FROM ap.PurchaseDocumentLine d;
GO

-- =============================================================================
-- doc.PurchaseDocumentPayment  (canónico: ap.PurchaseDocumentPayment)
-- =============================================================================
IF OBJECT_ID('[doc].[PurchaseDocumentPayment]', 'V') IS NOT NULL
  DROP VIEW [doc].[PurchaseDocumentPayment];
GO
CREATE VIEW [doc].[PurchaseDocumentPayment]
AS
SELECT
  p.[PaymentId],
  p.[DocumentNumber],
  p.[OperationType]           AS [DocumentType],
  p.[PaymentMethod]           AS [PaymentType],
  p.[BankCode],
  p.[PaymentNumber]           AS [ReferenceNumber],
  p.[Amount],
  p.[PaymentDate]             AS [ApplyDate],
  p.[DueDate],
  p.[ReferenceNumber]         AS [PaymentReference],
  p.[CreatedAt],
  p.[UpdatedAt],
  p.[CreatedByUserId],
  p.[UpdatedByUserId],
  p.[IsDeleted],
  p.[DeletedAt],
  p.[DeletedByUserId],
  p.[RowVer]
FROM ap.PurchaseDocumentPayment p;
GO
