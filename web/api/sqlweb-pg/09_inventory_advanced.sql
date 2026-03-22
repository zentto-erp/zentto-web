-- ============================================================
-- Zentto PostgreSQL - 09_inventory_advanced.sql
-- Schema: inv (Inventario Avanzado)
-- Tablas: Warehouse, WarehouseZone, WarehouseBin, ProductLot,
--         ProductSerial, ProductBinStock, InventoryValuationMethod,
--         InventoryValuationLayer, StockMovement
-- Traducido de SQL Server -> PostgreSQL
-- ============================================================

BEGIN;

CREATE SCHEMA IF NOT EXISTS inv;

-- ============================================================
-- 1. inv."Warehouse"  (Almacenes)
-- ============================================================
CREATE TABLE IF NOT EXISTS inv."Warehouse"(
  "WarehouseId"           BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"             INT          NOT NULL,
  "BranchId"              INT          NOT NULL,
  "WarehouseCode"         VARCHAR(30)  NOT NULL,
  "WarehouseName"         VARCHAR(150) NOT NULL,
  "AddressLine"           VARCHAR(250) NULL,
  "ContactName"           VARCHAR(120) NULL,
  "Phone"                 VARCHAR(40)  NULL,
  "IsActive"              BOOLEAN      NOT NULL DEFAULT TRUE,
  "IsDeleted"             BOOLEAN      NOT NULL DEFAULT FALSE,
  "DeletedAt"             TIMESTAMP    NULL,
  "DeletedByUserId"       INT          NULL,
  "CreatedAt"             TIMESTAMP    NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"             TIMESTAMP    NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId"       INT          NULL,
  "UpdatedByUserId"       INT          NULL,
  "RowVer"                INT          NOT NULL DEFAULT 1,
  CONSTRAINT "FK_inv_Warehouse_Company"   FOREIGN KEY ("CompanyId")       REFERENCES cfg."Company"("CompanyId"),
  CONSTRAINT "FK_inv_Warehouse_Branch"    FOREIGN KEY ("BranchId")        REFERENCES cfg."Branch"("BranchId"),
  CONSTRAINT "FK_inv_Warehouse_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_inv_Warehouse_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_inv_Warehouse_DeletedBy" FOREIGN KEY ("DeletedByUserId") REFERENCES sec."User"("UserId")
);

CREATE UNIQUE INDEX IF NOT EXISTS "UQ_inv_Warehouse_Code"
  ON inv."Warehouse" ("CompanyId", "WarehouseCode")
  WHERE "IsDeleted" = FALSE;

CREATE INDEX IF NOT EXISTS "IX_inv_Warehouse_Company"
  ON inv."Warehouse" ("CompanyId", "IsDeleted", "IsActive");

-- ============================================================
-- 2. inv."WarehouseZone"  (Zonas dentro del almacen)
-- ============================================================
CREATE TABLE IF NOT EXISTS inv."WarehouseZone"(
  "ZoneId"                BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "WarehouseId"           BIGINT       NOT NULL,
  "ZoneCode"              VARCHAR(30)  NOT NULL,
  "ZoneName"              VARCHAR(150) NOT NULL,
  "ZoneType"              VARCHAR(20)  NOT NULL DEFAULT 'STORAGE',
  "Temperature"           VARCHAR(20)  NOT NULL DEFAULT 'AMBIENT',
  "IsActive"              BOOLEAN      NOT NULL DEFAULT TRUE,
  "IsDeleted"             BOOLEAN      NOT NULL DEFAULT FALSE,
  "DeletedAt"             TIMESTAMP    NULL,
  "DeletedByUserId"       INT          NULL,
  "CreatedAt"             TIMESTAMP    NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"             TIMESTAMP    NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId"       INT          NULL,
  "UpdatedByUserId"       INT          NULL,
  "RowVer"                INT          NOT NULL DEFAULT 1,
  CONSTRAINT "CK_inv_WarehouseZone_Type" CHECK ("ZoneType" IN ('RECEIVING', 'STORAGE', 'PICKING', 'SHIPPING', 'QUARANTINE')),
  CONSTRAINT "CK_inv_WarehouseZone_Temp" CHECK ("Temperature" IN ('AMBIENT', 'COLD', 'FROZEN')),
  CONSTRAINT "FK_inv_WarehouseZone_Warehouse" FOREIGN KEY ("WarehouseId")     REFERENCES inv."Warehouse"("WarehouseId"),
  CONSTRAINT "FK_inv_WarehouseZone_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_inv_WarehouseZone_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_inv_WarehouseZone_DeletedBy" FOREIGN KEY ("DeletedByUserId") REFERENCES sec."User"("UserId")
);

CREATE INDEX IF NOT EXISTS "IX_inv_WarehouseZone_Warehouse"
  ON inv."WarehouseZone" ("WarehouseId", "IsDeleted", "IsActive");

-- ============================================================
-- 3. inv."WarehouseBin"  (Ubicaciones — estantes, racks)
-- ============================================================
CREATE TABLE IF NOT EXISTS inv."WarehouseBin"(
  "BinId"                 BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "ZoneId"                BIGINT        NOT NULL,
  "BinCode"               VARCHAR(30)   NOT NULL,
  "BinName"               VARCHAR(100)  NULL,
  "MaxWeight"             DECIMAL(18,2) NULL,
  "MaxVolume"             DECIMAL(18,4) NULL,
  "IsActive"              BOOLEAN       NOT NULL DEFAULT TRUE,
  "IsDeleted"             BOOLEAN       NOT NULL DEFAULT FALSE,
  "DeletedAt"             TIMESTAMP     NULL,
  "DeletedByUserId"       INT           NULL,
  "CreatedAt"             TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"             TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId"       INT           NULL,
  "UpdatedByUserId"       INT           NULL,
  "RowVer"                INT           NOT NULL DEFAULT 1,
  CONSTRAINT "FK_inv_WarehouseBin_Zone"      FOREIGN KEY ("ZoneId")          REFERENCES inv."WarehouseZone"("ZoneId"),
  CONSTRAINT "FK_inv_WarehouseBin_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_inv_WarehouseBin_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_inv_WarehouseBin_DeletedBy" FOREIGN KEY ("DeletedByUserId") REFERENCES sec."User"("UserId")
);

CREATE INDEX IF NOT EXISTS "IX_inv_WarehouseBin_Zone"
  ON inv."WarehouseBin" ("ZoneId", "IsDeleted", "IsActive");

-- ============================================================
-- 4. inv."ProductLot"  (Lotes de productos)
-- ============================================================
CREATE TABLE IF NOT EXISTS inv."ProductLot"(
  "LotId"                  BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"              INT           NOT NULL,
  "ProductId"              BIGINT        NOT NULL,
  "LotNumber"              VARCHAR(60)   NOT NULL,
  "ManufactureDate"        DATE          NULL,
  "ExpiryDate"             DATE          NULL,
  "SupplierCode"           VARCHAR(24)   NULL,
  "PurchaseDocumentNumber" VARCHAR(60)   NULL,
  "InitialQuantity"        DECIMAL(18,4) NOT NULL DEFAULT 0,
  "CurrentQuantity"        DECIMAL(18,4) NOT NULL DEFAULT 0,
  "UnitCost"               DECIMAL(18,4) NOT NULL DEFAULT 0,
  "Status"                 VARCHAR(20)   NOT NULL DEFAULT 'ACTIVE',
  "Notes"                  VARCHAR(500)  NULL,
  "IsDeleted"              BOOLEAN       NOT NULL DEFAULT FALSE,
  "DeletedAt"              TIMESTAMP     NULL,
  "DeletedByUserId"        INT           NULL,
  "CreatedAt"              TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"              TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId"        INT           NULL,
  "UpdatedByUserId"        INT           NULL,
  "RowVer"                 INT           NOT NULL DEFAULT 1,
  CONSTRAINT "CK_inv_ProductLot_Status" CHECK ("Status" IN ('ACTIVE', 'DEPLETED', 'EXPIRED', 'QUARANTINE', 'BLOCKED')),
  CONSTRAINT "FK_inv_ProductLot_Company"   FOREIGN KEY ("CompanyId")       REFERENCES cfg."Company"("CompanyId"),
  CONSTRAINT "FK_inv_ProductLot_Product"   FOREIGN KEY ("ProductId")       REFERENCES master."Product"("ProductId"),
  CONSTRAINT "FK_inv_ProductLot_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_inv_ProductLot_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_inv_ProductLot_DeletedBy" FOREIGN KEY ("DeletedByUserId") REFERENCES sec."User"("UserId")
);

CREATE UNIQUE INDEX IF NOT EXISTS "UQ_inv_ProductLot"
  ON inv."ProductLot" ("CompanyId", "ProductId", "LotNumber")
  WHERE "IsDeleted" = FALSE;

CREATE INDEX IF NOT EXISTS "IX_inv_ProductLot_Product"
  ON inv."ProductLot" ("CompanyId", "ProductId", "Status");

CREATE INDEX IF NOT EXISTS "IX_inv_ProductLot_Expiry"
  ON inv."ProductLot" ("CompanyId", "ExpiryDate")
  WHERE "ExpiryDate" IS NOT NULL AND "IsDeleted" = FALSE AND "Status" = 'ACTIVE';

-- ============================================================
-- 5. inv."ProductSerial"  (Seriales individuales)
-- ============================================================
CREATE TABLE IF NOT EXISTS inv."ProductSerial"(
  "SerialId"               BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"              INT          NOT NULL,
  "ProductId"              BIGINT       NOT NULL,
  "LotId"                  BIGINT       NULL,
  "SerialNumber"           VARCHAR(100) NOT NULL,
  "WarehouseId"            BIGINT       NULL,
  "BinId"                  BIGINT       NULL,
  "Status"                 VARCHAR(20)  NOT NULL DEFAULT 'AVAILABLE',
  "PurchaseDocumentNumber" VARCHAR(60)  NULL,
  "SalesDocumentNumber"    VARCHAR(60)  NULL,
  "CustomerId"             BIGINT       NULL,
  "SoldAt"                 TIMESTAMP    NULL,
  "WarrantyExpiry"         DATE         NULL,
  "Notes"                  VARCHAR(500) NULL,
  "IsDeleted"              BOOLEAN      NOT NULL DEFAULT FALSE,
  "DeletedAt"              TIMESTAMP    NULL,
  "DeletedByUserId"        INT          NULL,
  "CreatedAt"              TIMESTAMP    NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"              TIMESTAMP    NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId"        INT          NULL,
  "UpdatedByUserId"        INT          NULL,
  "RowVer"                 INT          NOT NULL DEFAULT 1,
  CONSTRAINT "CK_inv_ProductSerial_Status" CHECK ("Status" IN ('AVAILABLE', 'RESERVED', 'SOLD', 'RETURNED', 'DEFECTIVE', 'SCRAPPED')),
  CONSTRAINT "FK_inv_ProductSerial_Company"   FOREIGN KEY ("CompanyId")       REFERENCES cfg."Company"("CompanyId"),
  CONSTRAINT "FK_inv_ProductSerial_Product"   FOREIGN KEY ("ProductId")       REFERENCES master."Product"("ProductId"),
  CONSTRAINT "FK_inv_ProductSerial_Lot"       FOREIGN KEY ("LotId")           REFERENCES inv."ProductLot"("LotId"),
  CONSTRAINT "FK_inv_ProductSerial_Warehouse" FOREIGN KEY ("WarehouseId")     REFERENCES inv."Warehouse"("WarehouseId"),
  CONSTRAINT "FK_inv_ProductSerial_Bin"       FOREIGN KEY ("BinId")           REFERENCES inv."WarehouseBin"("BinId"),
  CONSTRAINT "FK_inv_ProductSerial_Customer"  FOREIGN KEY ("CustomerId")      REFERENCES master."Customer"("CustomerId"),
  CONSTRAINT "FK_inv_ProductSerial_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_inv_ProductSerial_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_inv_ProductSerial_DeletedBy" FOREIGN KEY ("DeletedByUserId") REFERENCES sec."User"("UserId")
);

CREATE UNIQUE INDEX IF NOT EXISTS "UQ_inv_ProductSerial"
  ON inv."ProductSerial" ("CompanyId", "ProductId", "SerialNumber")
  WHERE "IsDeleted" = FALSE;

CREATE INDEX IF NOT EXISTS "IX_inv_ProductSerial_Product"
  ON inv."ProductSerial" ("CompanyId", "ProductId", "Status");

CREATE INDEX IF NOT EXISTS "IX_inv_ProductSerial_Warehouse"
  ON inv."ProductSerial" ("WarehouseId", "Status")
  WHERE "IsDeleted" = FALSE AND "Status" = 'AVAILABLE';

-- ============================================================
-- 6. inv."ProductBinStock"  (Stock por ubicacion)
-- Nota: QuantityAvailable es columna normal (no computed/generated).
-- Debe ser mantenida por triggers o stored procedures.
-- ============================================================
CREATE TABLE IF NOT EXISTS inv."ProductBinStock"(
  "ProductBinStockId"     BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"             INT           NOT NULL,
  "ProductId"             BIGINT        NOT NULL,
  "WarehouseId"           BIGINT        NOT NULL,
  "BinId"                 BIGINT        NULL,
  "LotId"                 BIGINT        NULL,
  "QuantityOnHand"        DECIMAL(18,4) NOT NULL DEFAULT 0,
  "QuantityReserved"      DECIMAL(18,4) NOT NULL DEFAULT 0,
  "QuantityAvailable"     DECIMAL(18,4) NOT NULL DEFAULT 0,
  "LastCountDate"         DATE          NULL,
  "IsDeleted"             BOOLEAN       NOT NULL DEFAULT FALSE,
  "DeletedAt"             TIMESTAMP     NULL,
  "DeletedByUserId"       INT           NULL,
  "CreatedAt"             TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"             TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId"       INT           NULL,
  "UpdatedByUserId"       INT           NULL,
  "RowVer"                INT           NOT NULL DEFAULT 1,
  CONSTRAINT "FK_inv_ProductBinStock_Company"   FOREIGN KEY ("CompanyId")       REFERENCES cfg."Company"("CompanyId"),
  CONSTRAINT "FK_inv_ProductBinStock_Product"   FOREIGN KEY ("ProductId")       REFERENCES master."Product"("ProductId"),
  CONSTRAINT "FK_inv_ProductBinStock_Warehouse" FOREIGN KEY ("WarehouseId")     REFERENCES inv."Warehouse"("WarehouseId"),
  CONSTRAINT "FK_inv_ProductBinStock_Bin"       FOREIGN KEY ("BinId")           REFERENCES inv."WarehouseBin"("BinId"),
  CONSTRAINT "FK_inv_ProductBinStock_Lot"       FOREIGN KEY ("LotId")           REFERENCES inv."ProductLot"("LotId"),
  CONSTRAINT "FK_inv_ProductBinStock_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_inv_ProductBinStock_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_inv_ProductBinStock_DeletedBy" FOREIGN KEY ("DeletedByUserId") REFERENCES sec."User"("UserId")
);

CREATE UNIQUE INDEX IF NOT EXISTS "UX_inv_ProductBinStock_Location"
  ON inv."ProductBinStock" ("CompanyId", "ProductId", "WarehouseId", COALESCE("BinId", 0), COALESCE("LotId", 0));

CREATE INDEX IF NOT EXISTS "IX_inv_ProductBinStock_Warehouse"
  ON inv."ProductBinStock" ("WarehouseId", "ProductId")
  WHERE "IsDeleted" = FALSE;

-- Trigger para mantener QuantityAvailable sincronizado
CREATE OR REPLACE FUNCTION inv.trg_product_bin_stock_available()
RETURNS TRIGGER AS $$
BEGIN
  NEW."QuantityAvailable" := NEW."QuantityOnHand" - NEW."QuantityReserved";
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS "TR_inv_ProductBinStock_Available" ON inv."ProductBinStock";
CREATE TRIGGER "TR_inv_ProductBinStock_Available"
  BEFORE INSERT OR UPDATE OF "QuantityOnHand", "QuantityReserved"
  ON inv."ProductBinStock"
  FOR EACH ROW
  EXECUTE FUNCTION inv.trg_product_bin_stock_available();

-- ============================================================
-- 7. inv."InventoryValuationMethod"  (Metodo de valoracion)
-- ============================================================
CREATE TABLE IF NOT EXISTS inv."InventoryValuationMethod"(
  "ValuationMethodId"     BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"             INT           NOT NULL,
  "ProductId"             BIGINT        NOT NULL,
  "Method"                VARCHAR(20)   NOT NULL DEFAULT 'WEIGHTED_AVG',
  "StandardCost"          DECIMAL(18,4) NULL,
  "IsDeleted"             BOOLEAN       NOT NULL DEFAULT FALSE,
  "DeletedAt"             TIMESTAMP     NULL,
  "DeletedByUserId"       INT           NULL,
  "CreatedAt"             TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"             TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId"       INT           NULL,
  "UpdatedByUserId"       INT           NULL,
  "RowVer"                INT           NOT NULL DEFAULT 1,
  CONSTRAINT "CK_inv_ValMethod_Method" CHECK ("Method" IN ('FIFO', 'LIFO', 'WEIGHTED_AVG', 'LAST_COST', 'STANDARD')),
  CONSTRAINT "FK_inv_ValMethod_Company"   FOREIGN KEY ("CompanyId")       REFERENCES cfg."Company"("CompanyId"),
  CONSTRAINT "FK_inv_ValMethod_Product"   FOREIGN KEY ("ProductId")       REFERENCES master."Product"("ProductId"),
  CONSTRAINT "FK_inv_ValMethod_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_inv_ValMethod_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_inv_ValMethod_DeletedBy" FOREIGN KEY ("DeletedByUserId") REFERENCES sec."User"("UserId")
);

CREATE UNIQUE INDEX IF NOT EXISTS "UQ_inv_ValMethod_Product"
  ON inv."InventoryValuationMethod" ("CompanyId", "ProductId")
  WHERE "IsDeleted" = FALSE;

-- ============================================================
-- 8. inv."InventoryValuationLayer"  (Capas de costo FIFO/LIFO)
-- ============================================================
CREATE TABLE IF NOT EXISTS inv."InventoryValuationLayer"(
  "LayerId"               BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"             INT           NOT NULL,
  "ProductId"             BIGINT        NOT NULL,
  "LotId"                 BIGINT        NULL,
  "LayerDate"             DATE          NOT NULL,
  "RemainingQuantity"     DECIMAL(18,4) NOT NULL DEFAULT 0,
  "UnitCost"              DECIMAL(18,4) NOT NULL DEFAULT 0,
  "SourceDocumentType"    VARCHAR(30)   NULL,
  "SourceDocumentNumber"  VARCHAR(60)   NULL,
  "CreatedAt"             TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  CONSTRAINT "FK_inv_ValLayer_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId"),
  CONSTRAINT "FK_inv_ValLayer_Product" FOREIGN KEY ("ProductId") REFERENCES master."Product"("ProductId"),
  CONSTRAINT "FK_inv_ValLayer_Lot"     FOREIGN KEY ("LotId")     REFERENCES inv."ProductLot"("LotId")
);

CREATE INDEX IF NOT EXISTS "IX_inv_ValLayer_Product"
  ON inv."InventoryValuationLayer" ("CompanyId", "ProductId", "LayerDate");

CREATE INDEX IF NOT EXISTS "IX_inv_ValLayer_Remaining"
  ON inv."InventoryValuationLayer" ("CompanyId", "ProductId")
  WHERE "RemainingQuantity" > 0;

-- ============================================================
-- 9. inv."StockMovement"  (Movimientos de stock detallados)
-- ============================================================
CREATE TABLE IF NOT EXISTS inv."StockMovement"(
  "MovementId"            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"             INT           NOT NULL,
  "BranchId"              INT           NOT NULL,
  "ProductId"             BIGINT        NOT NULL,
  "LotId"                 BIGINT        NULL,
  "SerialId"              BIGINT        NULL,
  "FromWarehouseId"       BIGINT        NULL,
  "ToWarehouseId"         BIGINT        NULL,
  "FromBinId"             BIGINT        NULL,
  "ToBinId"               BIGINT        NULL,
  "MovementType"          VARCHAR(20)   NOT NULL,
  "Quantity"              DECIMAL(18,4) NOT NULL,
  "UnitCost"              DECIMAL(18,4) NOT NULL DEFAULT 0,
  "TotalCost"             DECIMAL(18,2) NOT NULL DEFAULT 0,
  "SourceDocumentType"    VARCHAR(30)   NULL,
  "SourceDocumentNumber"  VARCHAR(60)   NULL,
  "Notes"                 VARCHAR(500)  NULL,
  "MovementDate"          TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId"       INT           NULL,
  "CreatedAt"             TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  CONSTRAINT "CK_inv_StockMovement_Type" CHECK ("MovementType" IN (
    'PURCHASE_IN', 'SALE_OUT', 'TRANSFER', 'ADJUSTMENT',
    'RETURN_IN', 'RETURN_OUT', 'PRODUCTION_IN', 'PRODUCTION_OUT', 'SCRAP'
  )),
  CONSTRAINT "FK_inv_StockMovement_Company"   FOREIGN KEY ("CompanyId")       REFERENCES cfg."Company"("CompanyId"),
  CONSTRAINT "FK_inv_StockMovement_Branch"    FOREIGN KEY ("BranchId")        REFERENCES cfg."Branch"("BranchId"),
  CONSTRAINT "FK_inv_StockMovement_Product"   FOREIGN KEY ("ProductId")       REFERENCES master."Product"("ProductId"),
  CONSTRAINT "FK_inv_StockMovement_Lot"       FOREIGN KEY ("LotId")           REFERENCES inv."ProductLot"("LotId"),
  CONSTRAINT "FK_inv_StockMovement_Serial"    FOREIGN KEY ("SerialId")        REFERENCES inv."ProductSerial"("SerialId"),
  CONSTRAINT "FK_inv_StockMovement_FromWH"    FOREIGN KEY ("FromWarehouseId") REFERENCES inv."Warehouse"("WarehouseId"),
  CONSTRAINT "FK_inv_StockMovement_ToWH"      FOREIGN KEY ("ToWarehouseId")   REFERENCES inv."Warehouse"("WarehouseId"),
  CONSTRAINT "FK_inv_StockMovement_FromBin"   FOREIGN KEY ("FromBinId")       REFERENCES inv."WarehouseBin"("BinId"),
  CONSTRAINT "FK_inv_StockMovement_ToBin"     FOREIGN KEY ("ToBinId")         REFERENCES inv."WarehouseBin"("BinId"),
  CONSTRAINT "FK_inv_StockMovement_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId")
);

CREATE INDEX IF NOT EXISTS "IX_inv_StockMovement_Product"
  ON inv."StockMovement" ("CompanyId", "ProductId", "MovementDate" DESC);

CREATE INDEX IF NOT EXISTS "IX_inv_StockMovement_Date"
  ON inv."StockMovement" ("CompanyId", "MovementDate" DESC);

CREATE INDEX IF NOT EXISTS "IX_inv_StockMovement_Type"
  ON inv."StockMovement" ("CompanyId", "MovementType", "MovementDate" DESC);

COMMIT;

DO $$ BEGIN RAISE NOTICE '>>> 09_inventory_advanced.sql ejecutado correctamente <<<'; END $$;
