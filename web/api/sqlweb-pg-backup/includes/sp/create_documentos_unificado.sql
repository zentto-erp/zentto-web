-- ============================================================
-- DatqBoxWeb PostgreSQL - create_documentos_unificado.sql
-- Creacion de tablas y vistas de documentos unificados.
-- Tablas reales: ar.SalesDocument*, ap.PurchaseDocument*
-- Vistas legacy: public.DocumentosVenta*, public.DocumentosCompra*
-- Vistas alias:  doc.SalesDocument*, doc.PurchaseDocument*
-- ============================================================

CREATE SCHEMA IF NOT EXISTS ar;
CREATE SCHEMA IF NOT EXISTS ap;
CREATE SCHEMA IF NOT EXISTS doc;
CREATE SCHEMA IF NOT EXISTS acct;
CREATE SCHEMA IF NOT EXISTS master;

-- =============================================================================
-- SECCION 1: TABLAS ar.* (Documentos de Venta)
-- =============================================================================

-- 1.1 ar.SalesDocument
CREATE TABLE IF NOT EXISTS ar."SalesDocument" (
    "DocumentId"          INT GENERATED ALWAYS AS IDENTITY NOT NULL,
    "DocumentNumber"      VARCHAR(60)   NOT NULL,
    "SerialType"          VARCHAR(60)   NOT NULL DEFAULT '',
    "FiscalMemoryNumber"  VARCHAR(80)   NULL DEFAULT '',
    "OperationType"       VARCHAR(20)   NOT NULL,
    "CustomerCode"        VARCHAR(60)   NULL,
    "CustomerName"        VARCHAR(255)  NULL,
    "FiscalId"            VARCHAR(20)   NULL,
    "DocumentDate"        TIMESTAMP     NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "DueDate"             TIMESTAMP     NULL,
    "DocumentTime"        VARCHAR(20)   NULL DEFAULT TO_CHAR(NOW() AT TIME ZONE 'UTC', 'HH24:MI:SS'),
    "SubTotal"            NUMERIC(18,4) NULL DEFAULT 0,
    "TaxableAmount"       NUMERIC(18,4) NULL DEFAULT 0,
    "ExemptAmount"        NUMERIC(18,4) NULL DEFAULT 0,
    "TaxAmount"           NUMERIC(18,4) NULL DEFAULT 0,
    "TaxRate"             NUMERIC(8,4)  NULL DEFAULT 0,
    "TotalAmount"         NUMERIC(18,4) NULL DEFAULT 0,
    "DiscountAmount"      NUMERIC(18,4) NULL DEFAULT 0,
    "IsVoided"            BOOLEAN       NULL DEFAULT FALSE,
    "IsPaid"              VARCHAR(1)    NULL DEFAULT 'N',
    "IsInvoiced"          VARCHAR(1)    NULL DEFAULT 'N',
    "IsDelivered"         VARCHAR(1)    NULL DEFAULT 'N',
    "OriginDocumentNumber" VARCHAR(60)  NULL,
    "OriginDocumentType"  VARCHAR(20)   NULL,
    "ControlNumber"       VARCHAR(60)   NULL,
    "IsLegal"             BOOLEAN       NULL DEFAULT FALSE,
    "IsPrinted"           BOOLEAN       NULL DEFAULT FALSE,
    "Notes"               VARCHAR(500)  NULL,
    "Concept"             VARCHAR(255)  NULL,
    "PaymentTerms"        VARCHAR(255)  NULL,
    "ShipToAddress"       VARCHAR(255)  NULL,
    "SellerCode"          VARCHAR(60)   NULL,
    "DepartmentCode"      VARCHAR(50)   NULL,
    "LocationCode"        VARCHAR(100)  NULL,
    "CurrencyCode"        VARCHAR(20)   NULL DEFAULT 'BS',
    "ExchangeRate"        NUMERIC(18,6) NULL DEFAULT 1,
    "UserCode"            VARCHAR(60)   NULL DEFAULT 'API',
    "ReportDate"          TIMESTAMP     NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "HostName"            VARCHAR(255)  NULL,
    "VehiclePlate"        VARCHAR(20)   NULL,
    "Mileage"             INT           NULL,
    "TollAmount"          NUMERIC(18,4) NULL DEFAULT 0,
    "CreatedAt"           TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "UpdatedAt"           TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "CreatedByUserId"     INT           NULL,
    "UpdatedByUserId"     INT           NULL,
    "IsDeleted"           BOOLEAN       NOT NULL DEFAULT FALSE,
    "DeletedAt"           TIMESTAMP     NULL,
    "DeletedByUserId"     INT           NULL,
    CONSTRAINT "PK_SalesDocument" PRIMARY KEY ("DocumentId"),
    CONSTRAINT "UQ_SalesDocument_NumDocOp" UNIQUE ("DocumentNumber", "OperationType")
);

CREATE INDEX IF NOT EXISTS "IX_SalesDocument_Customer" ON ar."SalesDocument" ("CustomerCode");
CREATE INDEX IF NOT EXISTS "IX_SalesDocument_OpDate" ON ar."SalesDocument" ("OperationType", "DocumentDate" DESC) WHERE "IsDeleted" = FALSE;

-- 1.2 ar.SalesDocumentLine
CREATE TABLE IF NOT EXISTS ar."SalesDocumentLine" (
    "LineId"              INT GENERATED ALWAYS AS IDENTITY NOT NULL,
    "DocumentNumber"      VARCHAR(60)   NOT NULL,
    "SerialType"          VARCHAR(60)   NOT NULL DEFAULT '',
    "FiscalMemoryNumber"  VARCHAR(80)   NULL DEFAULT '',
    "OperationType"       VARCHAR(20)   NOT NULL,
    "LineNumber"          INT           NULL DEFAULT 0,
    "ProductCode"         VARCHAR(60)   NULL,
    "Description"         VARCHAR(255)  NULL,
    "AlternateCode"       VARCHAR(60)   NULL,
    "Quantity"            NUMERIC(18,4) NULL DEFAULT 0,
    "UnitPrice"           NUMERIC(18,4) NULL DEFAULT 0,
    "DiscountedPrice"     NUMERIC(18,4) NULL DEFAULT 0,
    "UnitCost"            NUMERIC(18,4) NULL DEFAULT 0,
    "SubTotal"            NUMERIC(18,4) NULL DEFAULT 0,
    "DiscountAmount"      NUMERIC(18,4) NULL DEFAULT 0,
    "TotalAmount"         NUMERIC(18,4) NULL DEFAULT 0,
    "TaxRate"             NUMERIC(8,4)  NULL DEFAULT 0,
    "TaxAmount"           NUMERIC(18,4) NULL DEFAULT 0,
    "IsVoided"            BOOLEAN       NULL DEFAULT FALSE,
    "RelatedRef"          VARCHAR(10)   NULL DEFAULT '0',
    "UserCode"            VARCHAR(60)   NULL DEFAULT 'API',
    "LineDate"            TIMESTAMP     NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "CreatedAt"           TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "UpdatedAt"           TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "CreatedByUserId"     INT           NULL,
    "UpdatedByUserId"     INT           NULL,
    "IsDeleted"           BOOLEAN       NOT NULL DEFAULT FALSE,
    "DeletedAt"           TIMESTAMP     NULL,
    "DeletedByUserId"     INT           NULL,
    CONSTRAINT "PK_SalesDocumentLine" PRIMARY KEY ("LineId")
);

CREATE INDEX IF NOT EXISTS "IX_SalesDocLine_DocKey" ON ar."SalesDocumentLine" ("DocumentNumber", "OperationType") WHERE "IsDeleted" = FALSE;
CREATE INDEX IF NOT EXISTS "IX_SalesDocLine_Product" ON ar."SalesDocumentLine" ("ProductCode");

-- 1.3 ar.SalesDocumentPayment
CREATE TABLE IF NOT EXISTS ar."SalesDocumentPayment" (
    "PaymentId"           INT GENERATED ALWAYS AS IDENTITY NOT NULL,
    "DocumentNumber"      VARCHAR(60)   NOT NULL,
    "SerialType"          VARCHAR(60)   NOT NULL DEFAULT '',
    "FiscalMemoryNumber"  VARCHAR(80)   NULL DEFAULT '',
    "OperationType"       VARCHAR(20)   NOT NULL DEFAULT 'FACT',
    "PaymentMethod"       VARCHAR(30)   NULL,
    "BankCode"            VARCHAR(60)   NULL,
    "PaymentNumber"       VARCHAR(60)   NULL,
    "Amount"              NUMERIC(18,4) NULL DEFAULT 0,
    "AmountBs"            NUMERIC(18,4) NULL DEFAULT 0,
    "ExchangeRate"        NUMERIC(18,6) NULL DEFAULT 1,
    "PaymentDate"         TIMESTAMP     NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "DueDate"             TIMESTAMP     NULL,
    "ReferenceNumber"     VARCHAR(100)  NULL,
    "UserCode"            VARCHAR(60)   NULL DEFAULT 'API',
    "CreatedAt"           TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "UpdatedAt"           TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "CreatedByUserId"     INT           NULL,
    "UpdatedByUserId"     INT           NULL,
    "IsDeleted"           BOOLEAN       NOT NULL DEFAULT FALSE,
    "DeletedAt"           TIMESTAMP     NULL,
    "DeletedByUserId"     INT           NULL,
    CONSTRAINT "PK_SalesDocumentPayment" PRIMARY KEY ("PaymentId")
);

CREATE INDEX IF NOT EXISTS "IX_SalesDocPay_DocKey" ON ar."SalesDocumentPayment" ("DocumentNumber", "OperationType") WHERE "IsDeleted" = FALSE;

-- =============================================================================
-- SECCION 2: TABLAS ap.* (Documentos de Compra)
-- =============================================================================

-- 2.1 ap.PurchaseDocument
CREATE TABLE IF NOT EXISTS ap."PurchaseDocument" (
    "DocumentId"          INT GENERATED ALWAYS AS IDENTITY NOT NULL,
    "DocumentNumber"      VARCHAR(60)   NOT NULL,
    "SerialType"          VARCHAR(60)   NOT NULL DEFAULT '',
    "FiscalMemoryNumber"  VARCHAR(80)   NULL DEFAULT '',
    "OperationType"       VARCHAR(20)   NOT NULL DEFAULT 'COMPRA',
    "SupplierCode"        VARCHAR(60)   NULL,
    "SupplierName"        VARCHAR(255)  NULL,
    "FiscalId"            VARCHAR(15)   NULL,
    "DocumentDate"        TIMESTAMP     NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "DueDate"             TIMESTAMP     NULL,
    "ReceiptDate"         TIMESTAMP     NULL,
    "PaymentDate"         TIMESTAMP     NULL,
    "DocumentTime"        VARCHAR(20)   NULL DEFAULT TO_CHAR(NOW() AT TIME ZONE 'UTC', 'HH24:MI:SS'),
    "SubTotal"            NUMERIC(18,4) NULL DEFAULT 0,
    "TaxableAmount"       NUMERIC(18,4) NULL DEFAULT 0,
    "ExemptAmount"        NUMERIC(18,4) NULL DEFAULT 0,
    "TaxAmount"           NUMERIC(18,4) NULL DEFAULT 0,
    "TaxRate"             NUMERIC(8,4)  NULL DEFAULT 0,
    "TotalAmount"         NUMERIC(18,4) NULL DEFAULT 0,
    "ExemptTotalAmount"   NUMERIC(18,4) NULL DEFAULT 0,
    "DiscountAmount"      NUMERIC(18,4) NULL DEFAULT 0,
    "IsVoided"            BOOLEAN       NULL DEFAULT FALSE,
    "IsPaid"              VARCHAR(1)    NULL DEFAULT 'N',
    "IsReceived"          VARCHAR(1)    NULL DEFAULT 'N',
    "IsLegal"             BOOLEAN       NULL DEFAULT FALSE,
    "OriginDocumentNumber" VARCHAR(60)  NULL,
    "ControlNumber"       VARCHAR(60)   NULL,
    "VoucherNumber"       VARCHAR(50)   NULL,
    "VoucherDate"         TIMESTAMP     NULL,
    "RetainedTax"         NUMERIC(18,4) NULL DEFAULT 0,
    "IsrCode"             VARCHAR(50)   NULL,
    "IsrAmount"           NUMERIC(18,4) NULL DEFAULT 0,
    "IsrSubjectAmount"    NUMERIC(18,4) NULL DEFAULT 0,
    "RetentionRate"       NUMERIC(8,4)  NULL DEFAULT 0,
    "ImportAmount"        NUMERIC(18,4) NULL DEFAULT 0,
    "ImportTax"           NUMERIC(18,4) NULL DEFAULT 0,
    "ImportBase"          NUMERIC(18,4) NULL DEFAULT 0,
    "FreightAmount"       NUMERIC(18,4) NULL DEFAULT 0,
    "Concept"             VARCHAR(255)  NULL,
    "Notes"               VARCHAR(500)  NULL,
    "OrderNumber"         VARCHAR(20)   NULL,
    "ReceivedBy"          VARCHAR(20)   NULL,
    "WarehouseCode"       VARCHAR(50)   NULL,
    "CurrencyCode"        VARCHAR(20)   NULL DEFAULT 'BS',
    "ExchangeRate"        NUMERIC(18,6) NULL DEFAULT 1,
    "UsdAmount"           NUMERIC(18,4) NULL DEFAULT 0,
    "UserCode"            VARCHAR(60)   NULL DEFAULT 'API',
    "ShortUserCode"       VARCHAR(10)   NULL,
    "ReportDate"          TIMESTAMP     NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "HostName"            VARCHAR(255)  NULL,
    "CreatedAt"           TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "UpdatedAt"           TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "CreatedByUserId"     INT           NULL,
    "UpdatedByUserId"     INT           NULL,
    "IsDeleted"           BOOLEAN       NOT NULL DEFAULT FALSE,
    "DeletedAt"           TIMESTAMP     NULL,
    "DeletedByUserId"     INT           NULL,
    CONSTRAINT "PK_PurchaseDocument" PRIMARY KEY ("DocumentId"),
    CONSTRAINT "UQ_PurchaseDocument_NumDocOp" UNIQUE ("DocumentNumber", "OperationType")
);

CREATE INDEX IF NOT EXISTS "IX_PurchaseDocument_Supplier" ON ap."PurchaseDocument" ("SupplierCode");
CREATE INDEX IF NOT EXISTS "IX_PurchaseDocument_OpDate" ON ap."PurchaseDocument" ("OperationType", "DocumentDate") WHERE "IsDeleted" = FALSE;

-- 2.2 ap.PurchaseDocumentLine
CREATE TABLE IF NOT EXISTS ap."PurchaseDocumentLine" (
    "LineId"              INT GENERATED ALWAYS AS IDENTITY NOT NULL,
    "DocumentNumber"      VARCHAR(60)   NOT NULL,
    "SerialType"          VARCHAR(60)   NOT NULL DEFAULT '',
    "FiscalMemoryNumber"  VARCHAR(80)   NULL DEFAULT '',
    "OperationType"       VARCHAR(20)   NOT NULL DEFAULT 'COMPRA',
    "LineNumber"          INT           NULL DEFAULT 0,
    "ProductCode"         VARCHAR(60)   NULL,
    "Description"         VARCHAR(255)  NULL,
    "Quantity"            NUMERIC(18,4) NULL DEFAULT 0,
    "UnitPrice"           NUMERIC(18,4) NULL DEFAULT 0,
    "UnitCost"            NUMERIC(18,4) NULL DEFAULT 0,
    "SubTotal"            NUMERIC(18,4) NULL DEFAULT 0,
    "DiscountAmount"      NUMERIC(18,4) NULL DEFAULT 0,
    "TotalAmount"         NUMERIC(18,4) NULL DEFAULT 0,
    "TaxRate"             NUMERIC(8,4)  NULL DEFAULT 0,
    "TaxAmount"           NUMERIC(18,4) NULL DEFAULT 0,
    "IsVoided"            BOOLEAN       NULL DEFAULT FALSE,
    "UserCode"            VARCHAR(60)   NULL DEFAULT 'API',
    "LineDate"            TIMESTAMP     NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "CreatedAt"           TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "UpdatedAt"           TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "CreatedByUserId"     INT           NULL,
    "UpdatedByUserId"     INT           NULL,
    "IsDeleted"           BOOLEAN       NOT NULL DEFAULT FALSE,
    "DeletedAt"           TIMESTAMP     NULL,
    "DeletedByUserId"     INT           NULL,
    CONSTRAINT "PK_PurchaseDocumentLine" PRIMARY KEY ("LineId")
);

CREATE INDEX IF NOT EXISTS "IX_PurchDocLine_DocKey" ON ap."PurchaseDocumentLine" ("DocumentNumber", "OperationType") WHERE "IsDeleted" = FALSE;
CREATE INDEX IF NOT EXISTS "IX_PurchDocLine_Product" ON ap."PurchaseDocumentLine" ("ProductCode");

-- 2.3 ap.PurchaseDocumentPayment
CREATE TABLE IF NOT EXISTS ap."PurchaseDocumentPayment" (
    "PaymentId"           INT GENERATED ALWAYS AS IDENTITY NOT NULL,
    "DocumentNumber"      VARCHAR(60)   NOT NULL,
    "SerialType"          VARCHAR(60)   NOT NULL DEFAULT '',
    "FiscalMemoryNumber"  VARCHAR(80)   NULL DEFAULT '',
    "OperationType"       VARCHAR(20)   NOT NULL DEFAULT 'COMPRA',
    "PaymentMethod"       VARCHAR(30)   NULL,
    "BankCode"            VARCHAR(60)   NULL,
    "PaymentNumber"       VARCHAR(60)   NULL,
    "Amount"              NUMERIC(18,4) NULL DEFAULT 0,
    "PaymentDate"         TIMESTAMP     NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "DueDate"             TIMESTAMP     NULL,
    "ReferenceNumber"     VARCHAR(100)  NULL,
    "UserCode"            VARCHAR(60)   NULL DEFAULT 'API',
    "CreatedAt"           TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "UpdatedAt"           TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "CreatedByUserId"     INT           NULL,
    "UpdatedByUserId"     INT           NULL,
    "IsDeleted"           BOOLEAN       NOT NULL DEFAULT FALSE,
    "DeletedAt"           TIMESTAMP     NULL,
    "DeletedByUserId"     INT           NULL,
    CONSTRAINT "PK_PurchaseDocumentPayment" PRIMARY KEY ("PaymentId")
);

CREATE INDEX IF NOT EXISTS "IX_PurchDocPay_DocKey" ON ap."PurchaseDocumentPayment" ("DocumentNumber", "OperationType") WHERE "IsDeleted" = FALSE;

-- =============================================================================
-- SECCION 3: VISTAS public.Documentos* (compatibilidad legacy)
-- =============================================================================

CREATE OR REPLACE VIEW public."DocumentosVenta" AS
SELECT
    "DocumentId" AS "ID", "DocumentNumber" AS "NUM_DOC", "SerialType" AS "SERIALTIPO",
    "FiscalMemoryNumber" AS "MEMORIA", "OperationType" AS "TIPO_OPERACION",
    "CustomerCode" AS "CODIGO", "CustomerName" AS "NOMBRE", "FiscalId" AS "RIF",
    "DocumentDate" AS "FECHA", "DueDate" AS "FECHA_VENCE", "DocumentTime" AS "HORA",
    "SubTotal"::DOUBLE PRECISION AS "SUBTOTAL", "TaxableAmount"::DOUBLE PRECISION AS "MONTO_GRA",
    "ExemptAmount"::DOUBLE PRECISION AS "MONTO_EXE", "TaxAmount"::DOUBLE PRECISION AS "IVA",
    "TaxRate"::DOUBLE PRECISION AS "ALICUOTA", "TotalAmount"::DOUBLE PRECISION AS "TOTAL",
    "DiscountAmount"::DOUBLE PRECISION AS "DESCUENTO",
    "IsVoided" AS "ANULADA", "IsPaid" AS "CANCELADA", "IsInvoiced" AS "FACTURADA",
    "IsDelivered" AS "ENTREGADA", "OriginDocumentNumber" AS "DOC_ORIGEN",
    "OriginDocumentType" AS "TIPO_DOC_ORIGEN", "ControlNumber" AS "NUM_CONTROL",
    "IsLegal" AS "LEGAL", "IsPrinted" AS "IMPRESA", "Notes" AS "OBSERV",
    "Concept" AS "CONCEPTO", "PaymentTerms" AS "TERMINOS", "ShipToAddress" AS "DESPACHAR",
    "SellerCode" AS "VENDEDOR", "DepartmentCode" AS "DEPARTAMENTO",
    "LocationCode" AS "LOCACION", "CurrencyCode" AS "MONEDA",
    "ExchangeRate"::DOUBLE PRECISION AS "TASA_CAMBIO",
    "UserCode" AS "COD_USUARIO", "ReportDate" AS "FECHA_REPORTE", "HostName" AS "COMPUTER",
    "VehiclePlate" AS "PLACAS", "Mileage" AS "KILOMETROS",
    "TollAmount"::DOUBLE PRECISION AS "PEAJE",
    "CreatedAt", "UpdatedAt", "CreatedByUserId", "UpdatedByUserId",
    "IsDeleted", "DeletedAt", "DeletedByUserId"
FROM ar."SalesDocument";

CREATE OR REPLACE VIEW public."DocumentosVentaDetalle" AS
SELECT
    "LineId" AS "ID", "DocumentNumber" AS "NUM_DOC", "SerialType" AS "SERIALTIPO",
    "FiscalMemoryNumber" AS "MEMORIA", "OperationType" AS "TIPO_OPERACION",
    "LineNumber" AS "RENGLON", "ProductCode" AS "COD_SERV", "Description" AS "DESCRIPCION",
    "AlternateCode" AS "COD_ALTERNO",
    "Quantity"::DOUBLE PRECISION AS "CANTIDAD", "UnitPrice"::DOUBLE PRECISION AS "PRECIO",
    "DiscountedPrice"::DOUBLE PRECISION AS "PRECIO_DESCUENTO",
    "UnitCost"::DOUBLE PRECISION AS "COSTO", "SubTotal"::DOUBLE PRECISION AS "SUBTOTAL",
    "DiscountAmount"::DOUBLE PRECISION AS "DESCUENTO",
    "TotalAmount"::DOUBLE PRECISION AS "TOTAL", "TaxRate"::DOUBLE PRECISION AS "ALICUOTA",
    "TaxAmount"::DOUBLE PRECISION AS "MONTO_IVA",
    "IsVoided" AS "ANULADA", "RelatedRef" AS "RELACIONADA",
    "UserCode" AS "CO_USUARIO", "LineDate" AS "FECHA",
    "CreatedAt", "UpdatedAt", "CreatedByUserId", "UpdatedByUserId",
    "IsDeleted", "DeletedAt", "DeletedByUserId"
FROM ar."SalesDocumentLine";

CREATE OR REPLACE VIEW public."DocumentosVentaPago" AS
SELECT
    "PaymentId" AS "ID", "DocumentNumber" AS "NUM_DOC", "SerialType" AS "SERIALTIPO",
    "FiscalMemoryNumber" AS "MEMORIA", "OperationType" AS "TIPO_OPERACION",
    "PaymentMethod" AS "TIPO_PAGO", "BankCode" AS "BANCO", "PaymentNumber" AS "NUMERO",
    "Amount"::DOUBLE PRECISION AS "MONTO", "AmountBs"::DOUBLE PRECISION AS "MONTO_BS",
    "ExchangeRate"::DOUBLE PRECISION AS "TASA_CAMBIO",
    "PaymentDate" AS "FECHA", "DueDate" AS "FECHA_VENCE",
    "ReferenceNumber" AS "REFERENCIA", "UserCode" AS "CO_USUARIO",
    "CreatedAt", "UpdatedAt", "CreatedByUserId", "UpdatedByUserId",
    "IsDeleted", "DeletedAt", "DeletedByUserId"
FROM ar."SalesDocumentPayment";

CREATE OR REPLACE VIEW public."DocumentosCompra" AS
SELECT
    "DocumentId" AS "ID", "DocumentNumber" AS "NUM_DOC", "SerialType" AS "SERIALTIPO",
    "FiscalMemoryNumber" AS "MEMORIA", "OperationType" AS "TIPO_OPERACION",
    "SupplierCode" AS "COD_PROVEEDOR", "SupplierName" AS "NOMBRE", "FiscalId" AS "RIF",
    "DocumentDate" AS "FECHA", "DueDate" AS "FECHA_VENCE",
    "ReceiptDate" AS "FECHA_RECIBO", "PaymentDate" AS "FECHA_PAGO",
    "DocumentTime" AS "HORA",
    "SubTotal"::DOUBLE PRECISION AS "SUBTOTAL", "TaxableAmount"::DOUBLE PRECISION AS "MONTO_GRA",
    "ExemptAmount"::DOUBLE PRECISION AS "MONTO_EXE", "TaxAmount"::DOUBLE PRECISION AS "IVA",
    "TaxRate"::DOUBLE PRECISION AS "ALICUOTA", "TotalAmount"::DOUBLE PRECISION AS "TOTAL",
    "ExemptTotalAmount"::DOUBLE PRECISION AS "EXENTO",
    "DiscountAmount"::DOUBLE PRECISION AS "DESCUENTO",
    "IsVoided" AS "ANULADA", "IsPaid" AS "CANCELADA", "IsReceived" AS "RECIBIDA",
    "IsLegal" AS "LEGAL", "OriginDocumentNumber" AS "DOC_ORIGEN",
    "ControlNumber" AS "NUM_CONTROL", "VoucherNumber" AS "NRO_COMPROBANTE",
    "VoucherDate" AS "FECHA_COMPROBANTE",
    "RetainedTax"::DOUBLE PRECISION AS "IVA_RETENIDO",
    "IsrCode" AS "ISLR", "IsrAmount"::DOUBLE PRECISION AS "MONTO_ISLR",
    "IsrCode" AS "CODIGO_ISLR", "IsrSubjectAmount"::DOUBLE PRECISION AS "SUJETO_ISLR",
    "RetentionRate"::DOUBLE PRECISION AS "TASA_RETENCION",
    "ImportAmount"::DOUBLE PRECISION AS "IMPORTACION",
    "ImportTax"::DOUBLE PRECISION AS "IVA_IMPORT",
    "ImportBase"::DOUBLE PRECISION AS "BASE_IMPORT",
    "FreightAmount"::DOUBLE PRECISION AS "FLETE",
    "Concept" AS "CONCEPTO", "Notes" AS "OBSERV", "OrderNumber" AS "PEDIDO",
    "ReceivedBy" AS "RECIBIDO", "WarehouseCode" AS "ALMACEN",
    "CurrencyCode" AS "MONEDA", "ExchangeRate"::DOUBLE PRECISION AS "TASA_CAMBIO",
    "UsdAmount"::DOUBLE PRECISION AS "PRECIO_DOLLAR",
    "UserCode" AS "COD_USUARIO", "ShortUserCode" AS "CO_USUARIO",
    "ReportDate" AS "FECHA_REPORTE", "HostName" AS "COMPUTER",
    "CreatedAt", "UpdatedAt", "CreatedByUserId", "UpdatedByUserId",
    "IsDeleted", "DeletedAt", "DeletedByUserId"
FROM ap."PurchaseDocument";

CREATE OR REPLACE VIEW public."DocumentosCompraDetalle" AS
SELECT
    "LineId" AS "ID", "DocumentNumber" AS "NUM_DOC", "SerialType" AS "SERIALTIPO",
    "FiscalMemoryNumber" AS "MEMORIA", "OperationType" AS "TIPO_OPERACION",
    "LineNumber" AS "RENGLON", "ProductCode" AS "COD_SERV", "Description" AS "DESCRIPCION",
    "Quantity"::DOUBLE PRECISION AS "CANTIDAD", "UnitPrice"::DOUBLE PRECISION AS "PRECIO",
    "UnitCost"::DOUBLE PRECISION AS "COSTO", "SubTotal"::DOUBLE PRECISION AS "SUBTOTAL",
    "DiscountAmount"::DOUBLE PRECISION AS "DESCUENTO",
    "TotalAmount"::DOUBLE PRECISION AS "TOTAL", "TaxRate"::DOUBLE PRECISION AS "ALICUOTA",
    "TaxAmount"::DOUBLE PRECISION AS "MONTO_IVA",
    "IsVoided" AS "ANULADA", "UserCode" AS "CO_USUARIO", "LineDate" AS "FECHA",
    "CreatedAt", "UpdatedAt", "CreatedByUserId", "UpdatedByUserId",
    "IsDeleted", "DeletedAt", "DeletedByUserId"
FROM ap."PurchaseDocumentLine";

CREATE OR REPLACE VIEW public."DocumentosCompraPago" AS
SELECT
    "PaymentId" AS "ID", "DocumentNumber" AS "NUM_DOC", "SerialType" AS "SERIALTIPO",
    "FiscalMemoryNumber" AS "MEMORIA", "OperationType" AS "TIPO_OPERACION",
    "PaymentMethod" AS "TIPO_PAGO", "BankCode" AS "BANCO", "PaymentNumber" AS "NUMERO",
    "Amount"::DOUBLE PRECISION AS "MONTO",
    "PaymentDate" AS "FECHA", "DueDate" AS "FECHA_VENCE",
    "ReferenceNumber" AS "REFERENCIA", "UserCode" AS "CO_USUARIO",
    "CreatedAt", "UpdatedAt", "CreatedByUserId", "UpdatedByUserId",
    "IsDeleted", "DeletedAt", "DeletedByUserId"
FROM ap."PurchaseDocumentPayment";

-- =============================================================================
-- SECCION 4: VISTAS doc.* (alias ingles)
-- =============================================================================

CREATE OR REPLACE VIEW doc."SalesDocument" AS
SELECT
    "ID" AS "DocumentId", "NUM_DOC" AS "DocumentNumber", "SERIALTIPO" AS "SerialType",
    "MEMORIA" AS "FiscalMemoryNumber", "TIPO_OPERACION" AS "OperationType",
    "CODIGO" AS "CustomerCode", "NOMBRE" AS "CustomerName", "RIF" AS "FiscalId",
    "FECHA" AS "IssueDate", "FECHA_VENCE" AS "DueDate", "HORA" AS "DocumentTime",
    "SUBTOTAL" AS "Subtotal", "MONTO_GRA" AS "TaxableAmount", "MONTO_EXE" AS "ExemptAmount",
    "IVA" AS "TaxAmount", "ALICUOTA" AS "TaxRate", "TOTAL" AS "TotalAmount",
    "DESCUENTO" AS "DiscountAmount", "ANULADA" AS "IsVoided", "CANCELADA" AS "IsCanceled",
    "FACTURADA" AS "IsInvoiced", "ENTREGADA" AS "IsDelivered",
    "DOC_ORIGEN" AS "SourceDocumentNumber", "TIPO_DOC_ORIGEN" AS "SourceDocumentType",
    "NUM_CONTROL" AS "ControlNumber", "OBSERV" AS "Notes", "CONCEPTO" AS "Concept",
    "MONEDA" AS "CurrencyCode", "TASA_CAMBIO" AS "ExchangeRate",
    "COD_USUARIO" AS "LegacyUserCode",
    "CreatedAt", "UpdatedAt", "CreatedByUserId", "UpdatedByUserId",
    "IsDeleted", "DeletedAt", "DeletedByUserId"
FROM public."DocumentosVenta";

CREATE OR REPLACE VIEW doc."SalesDocumentLine" AS
SELECT
    "ID" AS "LineId", "NUM_DOC" AS "DocumentNumber", "SERIALTIPO" AS "SerialType",
    "MEMORIA" AS "FiscalMemoryNumber", "TIPO_OPERACION" AS "DocumentType",
    "RENGLON" AS "LineNumber", "COD_SERV" AS "ProductCode", "DESCRIPCION" AS "Description",
    "COD_ALTERNO" AS "AlternateCode", "CANTIDAD" AS "Quantity", "PRECIO" AS "UnitPrice",
    "PRECIO_DESCUENTO" AS "DiscountUnitPrice", "COSTO" AS "UnitCost",
    "SUBTOTAL" AS "Subtotal", "DESCUENTO" AS "DiscountAmount", "TOTAL" AS "LineTotal",
    "ALICUOTA" AS "TaxRate", "MONTO_IVA" AS "TaxAmount", "ANULADA" AS "IsVoided",
    "CreatedAt", "UpdatedAt", "CreatedByUserId", "UpdatedByUserId",
    "IsDeleted", "DeletedAt", "DeletedByUserId"
FROM public."DocumentosVentaDetalle";

CREATE OR REPLACE VIEW doc."SalesDocumentPayment" AS
SELECT
    "ID" AS "PaymentId", "NUM_DOC" AS "DocumentNumber", "SERIALTIPO" AS "SerialType",
    "MEMORIA" AS "FiscalMemoryNumber", "TIPO_OPERACION" AS "DocumentType",
    "TIPO_PAGO" AS "PaymentType", "BANCO" AS "BankCode", "NUMERO" AS "ReferenceNumber",
    "MONTO" AS "Amount", "MONTO_BS" AS "AmountLocal", "TASA_CAMBIO" AS "ExchangeRate",
    "FECHA" AS "ApplyDate", "FECHA_VENCE" AS "DueDate", "REFERENCIA" AS "PaymentReference",
    "CreatedAt", "UpdatedAt", "CreatedByUserId", "UpdatedByUserId",
    "IsDeleted", "DeletedAt", "DeletedByUserId"
FROM public."DocumentosVentaPago";

CREATE OR REPLACE VIEW doc."PurchaseDocument" AS
SELECT
    "ID" AS "DocumentId", "NUM_DOC" AS "DocumentNumber", "SERIALTIPO" AS "SerialType",
    "MEMORIA" AS "FiscalMemoryNumber", "TIPO_OPERACION" AS "DocumentType",
    "COD_PROVEEDOR" AS "SupplierCode", "NOMBRE" AS "SupplierName", "RIF" AS "FiscalId",
    "FECHA" AS "IssueDate", "FECHA_VENCE" AS "DueDate",
    "SUBTOTAL" AS "Subtotal", "MONTO_GRA" AS "TaxableAmount", "MONTO_EXE" AS "ExemptAmount",
    "IVA" AS "TaxAmount", "ALICUOTA" AS "TaxRate", "TOTAL" AS "TotalAmount",
    "DESCUENTO" AS "DiscountAmount", "ANULADA" AS "IsVoided", "CANCELADA" AS "IsCanceled",
    "OBSERV" AS "Notes", "CONCEPTO" AS "Concept",
    "MONEDA" AS "CurrencyCode", "TASA_CAMBIO" AS "ExchangeRate",
    "COD_USUARIO" AS "LegacyUserCode",
    "CreatedAt", "UpdatedAt", "CreatedByUserId", "UpdatedByUserId",
    "IsDeleted", "DeletedAt", "DeletedByUserId"
FROM public."DocumentosCompra";

CREATE OR REPLACE VIEW doc."PurchaseDocumentLine" AS
SELECT
    "ID" AS "LineId", "NUM_DOC" AS "DocumentNumber", "SERIALTIPO" AS "SerialType",
    "MEMORIA" AS "FiscalMemoryNumber", "TIPO_OPERACION" AS "DocumentType",
    "RENGLON" AS "LineNumber", "COD_SERV" AS "ProductCode", "DESCRIPCION" AS "Description",
    "CANTIDAD" AS "Quantity", "PRECIO" AS "UnitPrice", "COSTO" AS "UnitCost",
    "SUBTOTAL" AS "Subtotal", "DESCUENTO" AS "DiscountAmount", "TOTAL" AS "LineTotal",
    "ALICUOTA" AS "TaxRate", "MONTO_IVA" AS "TaxAmount", "ANULADA" AS "IsVoided",
    "CreatedAt", "UpdatedAt", "CreatedByUserId", "UpdatedByUserId",
    "IsDeleted", "DeletedAt", "DeletedByUserId"
FROM public."DocumentosCompraDetalle";

CREATE OR REPLACE VIEW doc."PurchaseDocumentPayment" AS
SELECT
    "ID" AS "PaymentId", "NUM_DOC" AS "DocumentNumber", "SERIALTIPO" AS "SerialType",
    "MEMORIA" AS "FiscalMemoryNumber", "TIPO_OPERACION" AS "DocumentType",
    "TIPO_PAGO" AS "PaymentType", "BANCO" AS "BankCode", "NUMERO" AS "ReferenceNumber",
    "MONTO" AS "Amount", "FECHA" AS "ApplyDate", "FECHA_VENCE" AS "DueDate",
    "REFERENCIA" AS "PaymentReference",
    "CreatedAt", "UpdatedAt", "CreatedByUserId", "UpdatedByUserId",
    "IsDeleted", "DeletedAt", "DeletedByUserId"
FROM public."DocumentosCompraPago";

-- =============================================================================
-- SECCION 5: TABLAS AUXILIARES
-- =============================================================================

-- 5.1 acct.BankDeposit
CREATE TABLE IF NOT EXISTS acct."BankDeposit" (
    "BankDepositId"   INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    "Amount"          NUMERIC(18,4) NOT NULL DEFAULT 0,
    "CheckNumber"     VARCHAR(80)   NULL,
    "BankAccount"     VARCHAR(120)  NULL,
    "CustomerCode"    VARCHAR(60)   NULL,
    "IsRelated"       BOOLEAN       NOT NULL DEFAULT FALSE,
    "BankName"        VARCHAR(120)  NULL,
    "DocumentRef"     VARCHAR(60)   NULL,
    "OperationType"   VARCHAR(20)   NULL,
    "CreatedAt"       TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "UpdatedAt"       TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "CreatedByUserId" INT           NULL,
    "IsDeleted"       BOOLEAN       NOT NULL DEFAULT FALSE
);

CREATE INDEX IF NOT EXISTS "IX_BankDeposit_Customer" ON acct."BankDeposit" ("CustomerCode") WHERE "IsDeleted" = FALSE;

-- 5.2 master.AlternateStock
CREATE TABLE IF NOT EXISTS master."AlternateStock" (
    "AlternateStockId" INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    "ProductCode"      VARCHAR(80)   NOT NULL,
    "StockQty"         NUMERIC(18,4) NOT NULL DEFAULT 0,
    "CreatedAt"        TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "UpdatedAt"        TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "IsDeleted"        BOOLEAN       NOT NULL DEFAULT FALSE,
    CONSTRAINT "UQ_AlternateStock_ProductCode" UNIQUE ("ProductCode")
);
