-- ============================================================
-- Zentto PostgreSQL - 10_logistics.sql
-- Schema: logistics (Logistica)
-- Tablas: Carrier, Driver, GoodsReceipt, GoodsReceiptLine,
--         GoodsReceiptSerial, GoodsReturn, GoodsReturnLine,
--         DeliveryNote, DeliveryNoteLine, DeliveryNoteSerial
-- ============================================================

BEGIN;

CREATE SCHEMA IF NOT EXISTS logistics;

-- ============================================================
-- 1. logistics.Carrier (Transportistas)
-- ============================================================
CREATE TABLE IF NOT EXISTS logistics."Carrier" (
  "CarrierId"       BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"       INT           NOT NULL,
  "CarrierCode"     VARCHAR(30)   NOT NULL,
  "CarrierName"     VARCHAR(150)  NOT NULL,
  "FiscalId"        VARCHAR(30)   NULL,
  "ContactName"     VARCHAR(120)  NULL,
  "Phone"           VARCHAR(40)   NULL,
  "Email"           VARCHAR(150)  NULL,
  "AddressLine"     VARCHAR(250)  NULL,
  "IsActive"        BOOLEAN       NOT NULL DEFAULT TRUE,
  "IsDeleted"       BOOLEAN       NOT NULL DEFAULT FALSE,
  "CreatedAt"       TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"       TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId" INT           NULL,
  "UpdatedByUserId" INT           NULL,
  "RowVer"          INT           NOT NULL DEFAULT 1
);

CREATE UNIQUE INDEX IF NOT EXISTS "UQ_Carrier_CompanyCode"
  ON logistics."Carrier" ("CompanyId", "CarrierCode") WHERE "IsDeleted" = FALSE;

CREATE INDEX IF NOT EXISTS "IX_Carrier_CompanyActive"
  ON logistics."Carrier" ("CompanyId", "IsDeleted", "IsActive");

-- ============================================================
-- 2. logistics.Driver (Conductores)
-- ============================================================
CREATE TABLE IF NOT EXISTS logistics."Driver" (
  "DriverId"        BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"       INT           NOT NULL,
  "CarrierId"       BIGINT        NULL REFERENCES logistics."Carrier" ("CarrierId"),
  "DriverCode"      VARCHAR(30)   NOT NULL,
  "DriverName"      VARCHAR(150)  NOT NULL,
  "FiscalId"        VARCHAR(30)   NULL,
  "LicenseNumber"   VARCHAR(40)   NULL,
  "LicenseExpiry"   DATE          NULL,
  "Phone"           VARCHAR(40)   NULL,
  "IsActive"        BOOLEAN       NOT NULL DEFAULT TRUE,
  "IsDeleted"       BOOLEAN       NOT NULL DEFAULT FALSE,
  "CreatedAt"       TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"       TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId" INT           NULL,
  "UpdatedByUserId" INT           NULL,
  "RowVer"          INT           NOT NULL DEFAULT 1
);

CREATE UNIQUE INDEX IF NOT EXISTS "UQ_Driver_CompanyCode"
  ON logistics."Driver" ("CompanyId", "DriverCode") WHERE "IsDeleted" = FALSE;

CREATE INDEX IF NOT EXISTS "IX_Driver_CompanyActive"
  ON logistics."Driver" ("CompanyId", "IsDeleted", "IsActive");

CREATE INDEX IF NOT EXISTS "IX_Driver_Carrier"
  ON logistics."Driver" ("CarrierId") WHERE "IsDeleted" = FALSE;

-- ============================================================
-- 3. logistics.GoodsReceipt (Recepcion de mercancia)
-- ============================================================
CREATE TABLE IF NOT EXISTS logistics."GoodsReceipt" (
  "GoodsReceiptId"         BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"              INT           NOT NULL,
  "BranchId"               INT           NOT NULL,
  "ReceiptNumber"          VARCHAR(40)   NOT NULL,
  "PurchaseDocumentNumber" VARCHAR(60)   NULL,
  "SupplierId"             BIGINT        NOT NULL,
  "WarehouseId"            BIGINT        NOT NULL,
  "ReceiptDate"            DATE          NOT NULL,
  "Status"                 VARCHAR(20)   NOT NULL DEFAULT 'DRAFT'
                           CHECK ("Status" IN ('DRAFT','PARTIAL','COMPLETE','VOIDED')),
  "Notes"                  VARCHAR(500)  NULL,
  "CarrierId"              BIGINT        NULL,
  "DriverName"             VARCHAR(150)  NULL,
  "VehiclePlate"           VARCHAR(20)   NULL,
  "ReceivedByUserId"       INT           NULL,
  "IsDeleted"              BOOLEAN       NOT NULL DEFAULT FALSE,
  "CreatedAt"              TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"              TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId"        INT           NULL,
  "UpdatedByUserId"        INT           NULL,
  "RowVer"                 INT           NOT NULL DEFAULT 1
);

CREATE UNIQUE INDEX IF NOT EXISTS "UQ_GoodsReceipt_Number"
  ON logistics."GoodsReceipt" ("CompanyId", "BranchId", "ReceiptNumber") WHERE "IsDeleted" = FALSE;

CREATE INDEX IF NOT EXISTS "IX_GoodsReceipt_Date"
  ON logistics."GoodsReceipt" ("CompanyId", "ReceiptDate" DESC);

CREATE INDEX IF NOT EXISTS "IX_GoodsReceipt_Status"
  ON logistics."GoodsReceipt" ("CompanyId", "Status") WHERE "IsDeleted" = FALSE AND "Status" <> 'VOIDED';

-- ============================================================
-- 4. logistics.GoodsReceiptLine (Lineas de recepcion)
-- ============================================================
CREATE TABLE IF NOT EXISTS logistics."GoodsReceiptLine" (
  "GoodsReceiptLineId" BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "GoodsReceiptId"     BIGINT        NOT NULL REFERENCES logistics."GoodsReceipt" ("GoodsReceiptId"),
  "LineNumber"         INT           NOT NULL,
  "ProductId"          BIGINT        NOT NULL,
  "ProductCode"        VARCHAR(40)   NOT NULL,
  "Description"        VARCHAR(250)  NULL,
  "OrderedQuantity"    DECIMAL(18,4) NOT NULL,
  "ReceivedQuantity"   DECIMAL(18,4) NOT NULL,
  "RejectedQuantity"   DECIMAL(18,4) NOT NULL DEFAULT 0,
  "UnitCost"           DECIMAL(18,4) NOT NULL,
  "TotalCost"          DECIMAL(18,2) NOT NULL,
  "LotNumber"          VARCHAR(60)   NULL,
  "ExpiryDate"         DATE          NULL,
  "WarehouseId"        BIGINT        NULL,
  "BinId"              BIGINT        NULL,
  "InspectionStatus"   VARCHAR(20)   NOT NULL DEFAULT 'PENDING'
                       CHECK ("InspectionStatus" IN ('PENDING','APPROVED','REJECTED')),
  "Notes"              VARCHAR(500)  NULL,
  "IsDeleted"          BOOLEAN       NOT NULL DEFAULT FALSE,
  "CreatedAt"          TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"          TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId"    INT           NULL,
  "UpdatedByUserId"    INT           NULL,
  "RowVer"             INT           NOT NULL DEFAULT 1
);

CREATE INDEX IF NOT EXISTS "IX_GoodsReceiptLine_Receipt"
  ON logistics."GoodsReceiptLine" ("GoodsReceiptId", "LineNumber");

-- ============================================================
-- 5. logistics.GoodsReceiptSerial (Seriales recibidos)
-- ============================================================
CREATE TABLE IF NOT EXISTS logistics."GoodsReceiptSerial" (
  "GoodsReceiptSerialId" BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "GoodsReceiptLineId"   BIGINT        NOT NULL REFERENCES logistics."GoodsReceiptLine" ("GoodsReceiptLineId"),
  "SerialNumber"         VARCHAR(100)  NOT NULL,
  "Status"               VARCHAR(20)   NOT NULL DEFAULT 'RECEIVED'
                         CHECK ("Status" IN ('RECEIVED','REJECTED')),
  "Notes"                VARCHAR(250)  NULL
);

-- ============================================================
-- 6. logistics.GoodsReturn (Devolucion de mercancia)
-- ============================================================
CREATE TABLE IF NOT EXISTS logistics."GoodsReturn" (
  "GoodsReturnId"   BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"       INT           NOT NULL,
  "BranchId"        INT           NOT NULL,
  "ReturnNumber"    VARCHAR(40)   NOT NULL,
  "GoodsReceiptId"  BIGINT        NULL REFERENCES logistics."GoodsReceipt" ("GoodsReceiptId"),
  "SupplierId"      BIGINT        NOT NULL,
  "WarehouseId"     BIGINT        NOT NULL,
  "ReturnDate"      DATE          NOT NULL,
  "Reason"          VARCHAR(500)  NULL,
  "Status"          VARCHAR(20)   NOT NULL DEFAULT 'DRAFT'
                    CHECK ("Status" IN ('DRAFT','APPROVED','SHIPPED','VOIDED')),
  "Notes"           VARCHAR(500)  NULL,
  "IsDeleted"       BOOLEAN       NOT NULL DEFAULT FALSE,
  "CreatedAt"       TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"       TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId" INT           NULL,
  "UpdatedByUserId" INT           NULL,
  "RowVer"          INT           NOT NULL DEFAULT 1
);

CREATE UNIQUE INDEX IF NOT EXISTS "UQ_GoodsReturn_Number"
  ON logistics."GoodsReturn" ("CompanyId", "BranchId", "ReturnNumber") WHERE "IsDeleted" = FALSE;

CREATE INDEX IF NOT EXISTS "IX_GoodsReturn_Date"
  ON logistics."GoodsReturn" ("CompanyId", "ReturnDate" DESC);

-- ============================================================
-- 7. logistics.GoodsReturnLine (Lineas de devolucion)
-- ============================================================
CREATE TABLE IF NOT EXISTS logistics."GoodsReturnLine" (
  "GoodsReturnLineId" BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "GoodsReturnId"     BIGINT        NOT NULL REFERENCES logistics."GoodsReturn" ("GoodsReturnId"),
  "LineNumber"        INT           NOT NULL,
  "ProductId"         BIGINT        NOT NULL,
  "ProductCode"       VARCHAR(40)   NOT NULL,
  "Quantity"          DECIMAL(18,4) NOT NULL,
  "UnitCost"          DECIMAL(18,4) NOT NULL,
  "LotNumber"         VARCHAR(60)   NULL,
  "SerialNumber"      VARCHAR(100)  NULL,
  "Reason"            VARCHAR(250)  NULL,
  "IsDeleted"         BOOLEAN       NOT NULL DEFAULT FALSE,
  "CreatedAt"         TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"         TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId"   INT           NULL,
  "UpdatedByUserId"   INT           NULL,
  "RowVer"            INT           NOT NULL DEFAULT 1
);

CREATE INDEX IF NOT EXISTS "IX_GoodsReturnLine_Return"
  ON logistics."GoodsReturnLine" ("GoodsReturnId", "LineNumber");

-- ============================================================
-- 8. logistics.DeliveryNote (Notas de entrega / guias de despacho)
-- ============================================================
CREATE TABLE IF NOT EXISTS logistics."DeliveryNote" (
  "DeliveryNoteId"       BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"            INT           NOT NULL,
  "BranchId"             INT           NOT NULL,
  "DeliveryNumber"       VARCHAR(40)   NOT NULL,
  "SalesDocumentNumber"  VARCHAR(60)   NULL,
  "CustomerId"           BIGINT        NOT NULL,
  "WarehouseId"          BIGINT        NOT NULL,
  "DeliveryDate"         DATE          NOT NULL,
  "Status"               VARCHAR(20)   NOT NULL DEFAULT 'DRAFT'
                         CHECK ("Status" IN ('DRAFT','PICKING','PACKED','DISPATCHED','IN_TRANSIT','DELIVERED','VOIDED')),
  "CarrierId"            BIGINT        NULL REFERENCES logistics."Carrier" ("CarrierId"),
  "DriverId"             BIGINT        NULL REFERENCES logistics."Driver" ("DriverId"),
  "VehiclePlate"         VARCHAR(20)   NULL,
  "ShipToAddress"        VARCHAR(500)  NULL,
  "ShipToContact"        VARCHAR(150)  NULL,
  "EstimatedDelivery"    DATE          NULL,
  "ActualDelivery"       DATE          NULL,
  "DeliveredToName"      VARCHAR(150)  NULL,
  "DeliverySignature"    VARCHAR(500)  NULL,
  "Notes"                VARCHAR(500)  NULL,
  "DispatchedByUserId"   INT           NULL,
  "IsDeleted"            BOOLEAN       NOT NULL DEFAULT FALSE,
  "CreatedAt"            TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"            TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId"      INT           NULL,
  "UpdatedByUserId"      INT           NULL,
  "RowVer"               INT           NOT NULL DEFAULT 1
);

CREATE UNIQUE INDEX IF NOT EXISTS "UQ_DeliveryNote_Number"
  ON logistics."DeliveryNote" ("CompanyId", "BranchId", "DeliveryNumber") WHERE "IsDeleted" = FALSE;

CREATE INDEX IF NOT EXISTS "IX_DeliveryNote_Date"
  ON logistics."DeliveryNote" ("CompanyId", "DeliveryDate" DESC);

CREATE INDEX IF NOT EXISTS "IX_DeliveryNote_ActiveStatus"
  ON logistics."DeliveryNote" ("CompanyId", "Status")
  WHERE "IsDeleted" = FALSE AND "Status" NOT IN ('DELIVERED','VOIDED');

CREATE INDEX IF NOT EXISTS "IX_DeliveryNote_Customer"
  ON logistics."DeliveryNote" ("CustomerId") WHERE "IsDeleted" = FALSE;

-- ============================================================
-- 9. logistics.DeliveryNoteLine (Lineas de nota de entrega)
-- ============================================================
CREATE TABLE IF NOT EXISTS logistics."DeliveryNoteLine" (
  "DeliveryNoteLineId" BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "DeliveryNoteId"     BIGINT        NOT NULL REFERENCES logistics."DeliveryNote" ("DeliveryNoteId"),
  "LineNumber"         INT           NOT NULL,
  "ProductId"          BIGINT        NOT NULL,
  "ProductCode"        VARCHAR(40)   NOT NULL,
  "Description"        VARCHAR(250)  NULL,
  "Quantity"           DECIMAL(18,4) NOT NULL,
  "LotNumber"          VARCHAR(60)   NULL,
  "WarehouseId"        BIGINT        NULL,
  "BinId"              BIGINT        NULL,
  "PickedQuantity"     DECIMAL(18,4) NOT NULL DEFAULT 0,
  "PackedQuantity"     DECIMAL(18,4) NOT NULL DEFAULT 0,
  "Notes"              VARCHAR(500)  NULL,
  "IsDeleted"          BOOLEAN       NOT NULL DEFAULT FALSE,
  "CreatedAt"          TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"          TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId"    INT           NULL,
  "UpdatedByUserId"    INT           NULL,
  "RowVer"             INT           NOT NULL DEFAULT 1
);

CREATE INDEX IF NOT EXISTS "IX_DeliveryNoteLine_Note"
  ON logistics."DeliveryNoteLine" ("DeliveryNoteId", "LineNumber");

-- ============================================================
-- 10. logistics.DeliveryNoteSerial (Seriales despachados)
-- ============================================================
CREATE TABLE IF NOT EXISTS logistics."DeliveryNoteSerial" (
  "DeliveryNoteSerialId" BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "DeliveryNoteLineId"   BIGINT        NOT NULL REFERENCES logistics."DeliveryNoteLine" ("DeliveryNoteLineId"),
  "SerialId"             BIGINT        NULL,
  "SerialNumber"         VARCHAR(100)  NOT NULL,
  "Status"               VARCHAR(20)   NOT NULL DEFAULT 'DISPATCHED'
                         CHECK ("Status" IN ('DISPATCHED','DELIVERED','RETURNED'))
);

COMMIT;

DO $$ BEGIN RAISE NOTICE '>>> 10_logistics.sql ejecutado correctamente <<<'; END $$;
