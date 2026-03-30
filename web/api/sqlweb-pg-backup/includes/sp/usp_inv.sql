-- ============================================================
-- DatqBoxWeb PostgreSQL - usp_inv.sql
-- Funciones de inventario avanzado: almacenes, zonas,
-- ubicaciones, lotes, seriales, stock por ubicacion, valoracion
-- y movimientos de inventario.
-- Traducido de SQL Server stored procedures a PL/pgSQL.
-- ============================================================

-- ============================================================================
--  Schema: inv
-- ============================================================================
CREATE SCHEMA IF NOT EXISTS inv;

-- ============================================================================
--  Tabla: inv."Warehouse"
-- ============================================================================
CREATE TABLE IF NOT EXISTS inv."Warehouse" (
    "WarehouseId"   INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    "CompanyId"     INT NOT NULL,
    "BranchId"      INT NOT NULL,
    "WarehouseCode" VARCHAR(20) NOT NULL,
    "WarehouseName" VARCHAR(100) NOT NULL,
    "AddressLine"   VARCHAR(250) NULL,
    "ContactName"   VARCHAR(100) NULL,
    "Phone"         VARCHAR(50) NULL,
    "IsActive"      BOOLEAN NOT NULL DEFAULT TRUE,
    "CreatedBy"     INT NULL,
    "CreatedAt"     TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "UpdatedBy"     INT NULL,
    "UpdatedAt"     TIMESTAMP NULL
);

CREATE UNIQUE INDEX IF NOT EXISTS "UX_Warehouse_Code"
    ON inv."Warehouse"("CompanyId", "WarehouseCode");

-- ============================================================================
--  Tabla: inv."WarehouseZone"
-- ============================================================================
CREATE TABLE IF NOT EXISTS inv."WarehouseZone" (
    "ZoneId"        INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    "WarehouseId"   INT NOT NULL REFERENCES inv."Warehouse"("WarehouseId"),
    "ZoneCode"      VARCHAR(20) NOT NULL,
    "ZoneName"      VARCHAR(100) NOT NULL,
    "ZoneType"      VARCHAR(30) NULL,
    "Temperature"   VARCHAR(20) NULL,
    "IsActive"      BOOLEAN NOT NULL DEFAULT TRUE,
    "CreatedBy"     INT NULL,
    "CreatedAt"     TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "UpdatedBy"     INT NULL,
    "UpdatedAt"     TIMESTAMP NULL
);

CREATE UNIQUE INDEX IF NOT EXISTS "UX_Zone_Code"
    ON inv."WarehouseZone"("WarehouseId", "ZoneCode");

-- ============================================================================
--  Tabla: inv."WarehouseBin"
-- ============================================================================
CREATE TABLE IF NOT EXISTS inv."WarehouseBin" (
    "BinId"         INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    "ZoneId"        INT NOT NULL REFERENCES inv."WarehouseZone"("ZoneId"),
    "BinCode"       VARCHAR(20) NOT NULL,
    "BinName"       VARCHAR(100) NOT NULL,
    "MaxWeight"     DECIMAL(12,2) NULL,
    "MaxVolume"     DECIMAL(12,2) NULL,
    "IsActive"      BOOLEAN NOT NULL DEFAULT TRUE,
    "CreatedBy"     INT NULL,
    "CreatedAt"     TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "UpdatedBy"     INT NULL,
    "UpdatedAt"     TIMESTAMP NULL
);

CREATE UNIQUE INDEX IF NOT EXISTS "UX_Bin_Code"
    ON inv."WarehouseBin"("ZoneId", "BinCode");

-- ============================================================================
--  Tabla: inv."ProductLot"
-- ============================================================================
CREATE TABLE IF NOT EXISTS inv."ProductLot" (
    "LotId"                 INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    "CompanyId"             INT NOT NULL,
    "ProductId"             INT NOT NULL,
    "LotNumber"             VARCHAR(50) NOT NULL,
    "ManufactureDate"       DATE NULL,
    "ExpiryDate"            DATE NULL,
    "SupplierCode"          VARCHAR(30) NULL,
    "PurchaseDocumentNumber" VARCHAR(30) NULL,
    "InitialQuantity"       DECIMAL(18,4) NOT NULL DEFAULT 0,
    "CurrentQuantity"       DECIMAL(18,4) NOT NULL DEFAULT 0,
    "UnitCost"              DECIMAL(18,4) NULL,
    "Status"                VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    "CreatedBy"             INT NULL,
    "CreatedAt"             TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC')
);

CREATE UNIQUE INDEX IF NOT EXISTS "UX_Lot_Number"
    ON inv."ProductLot"("CompanyId", "ProductId", "LotNumber");

CREATE INDEX IF NOT EXISTS "IX_Lot_Product"
    ON inv."ProductLot"("CompanyId", "ProductId", "Status");

-- ============================================================================
--  Tabla: inv."ProductSerial"
-- ============================================================================
CREATE TABLE IF NOT EXISTS inv."ProductSerial" (
    "SerialId"               INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    "CompanyId"              INT NOT NULL,
    "ProductId"              INT NOT NULL,
    "SerialNumber"           VARCHAR(100) NOT NULL,
    "LotId"                  INT NULL REFERENCES inv."ProductLot"("LotId"),
    "WarehouseId"            INT NULL REFERENCES inv."Warehouse"("WarehouseId"),
    "BinId"                  INT NULL REFERENCES inv."WarehouseBin"("BinId"),
    "Status"                 VARCHAR(20) NOT NULL DEFAULT 'AVAILABLE',
    "PurchaseDocumentNumber" VARCHAR(30) NULL,
    "SalesDocumentNumber"    VARCHAR(30) NULL,
    "CustomerId"             INT NULL,
    "UnitCost"               DECIMAL(18,4) NULL,
    "CreatedBy"              INT NULL,
    "CreatedAt"              TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "UpdatedBy"              INT NULL,
    "UpdatedAt"              TIMESTAMP NULL
);

CREATE UNIQUE INDEX IF NOT EXISTS "UX_Serial_Number"
    ON inv."ProductSerial"("CompanyId", "SerialNumber");

CREATE INDEX IF NOT EXISTS "IX_Serial_Product"
    ON inv."ProductSerial"("CompanyId", "ProductId", "Status");

-- ============================================================================
--  Tabla: inv."ProductBinStock"
-- ============================================================================
CREATE TABLE IF NOT EXISTS inv."ProductBinStock" (
    "ProductBinStockId" INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    "CompanyId"         INT NOT NULL,
    "ProductId"         INT NOT NULL,
    "WarehouseId"       INT NOT NULL REFERENCES inv."Warehouse"("WarehouseId"),
    "ZoneId"            INT NULL REFERENCES inv."WarehouseZone"("ZoneId"),
    "BinId"             INT NULL REFERENCES inv."WarehouseBin"("BinId"),
    "LotId"             INT NULL REFERENCES inv."ProductLot"("LotId"),
    "Quantity"          DECIMAL(18,4) NOT NULL DEFAULT 0,
    "ReservedQuantity"  DECIMAL(18,4) NOT NULL DEFAULT 0,
    "UpdatedAt"         TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC')
);

CREATE UNIQUE INDEX IF NOT EXISTS "UX_BinStock"
    ON inv."ProductBinStock"("CompanyId", "ProductId", "WarehouseId",
        COALESCE("BinId", 0), COALESCE("LotId", 0));

-- ============================================================================
--  Tabla: inv."InventoryValuationMethod"
-- ============================================================================
CREATE TABLE IF NOT EXISTS inv."InventoryValuationMethod" (
    "ValuationMethodId" INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    "CompanyId"         INT NOT NULL,
    "ProductId"         INT NOT NULL,
    "Method"            VARCHAR(20) NOT NULL DEFAULT 'WEIGHTED_AVG',
    "StandardCost"      DECIMAL(18,4) NULL,
    "UpdatedBy"         INT NULL,
    "UpdatedAt"         TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC')
);

CREATE UNIQUE INDEX IF NOT EXISTS "UX_Valuation"
    ON inv."InventoryValuationMethod"("CompanyId", "ProductId");

-- ============================================================================
--  Tabla: inv."StockMovement"
-- ============================================================================
CREATE TABLE IF NOT EXISTS inv."StockMovement" (
    "MovementId"            INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    "CompanyId"             INT NOT NULL,
    "BranchId"              INT NOT NULL,
    "ProductId"             INT NOT NULL,
    "LotId"                 INT NULL REFERENCES inv."ProductLot"("LotId"),
    "SerialId"              INT NULL REFERENCES inv."ProductSerial"("SerialId"),
    "FromWarehouseId"       INT NULL REFERENCES inv."Warehouse"("WarehouseId"),
    "ToWarehouseId"         INT NULL REFERENCES inv."Warehouse"("WarehouseId"),
    "FromBinId"             INT NULL REFERENCES inv."WarehouseBin"("BinId"),
    "ToBinId"               INT NULL REFERENCES inv."WarehouseBin"("BinId"),
    "MovementType"          VARCHAR(30) NOT NULL,
    "Quantity"              DECIMAL(18,4) NOT NULL,
    "UnitCost"              DECIMAL(18,4) NULL,
    "SourceDocumentType"    VARCHAR(30) NULL,
    "SourceDocumentNumber"  VARCHAR(30) NULL,
    "Notes"                 VARCHAR(500) NULL,
    "CreatedBy"             INT NULL,
    "CreatedAt"             TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC')
);

CREATE INDEX IF NOT EXISTS "IX_Movement_Company"
    ON inv."StockMovement"("CompanyId", "CreatedAt" DESC);

CREATE INDEX IF NOT EXISTS "IX_Movement_Product"
    ON inv."StockMovement"("CompanyId", "ProductId", "CreatedAt" DESC);


-- ============================================================================
--  SP: usp_Inv_Warehouse_List
-- ============================================================================
DROP FUNCTION IF EXISTS usp_Inv_Warehouse_List(INT, VARCHAR, INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_Inv_Warehouse_List(
    p_company_id    INT,
    p_search        VARCHAR(100)    DEFAULT NULL,
    p_page          INT             DEFAULT 1,
    p_limit         INT             DEFAULT 50
)
RETURNS TABLE (
    "WarehouseId"   INT,
    "CompanyId"     INT,
    "BranchId"      INT,
    "WarehouseCode" VARCHAR,
    "WarehouseName" VARCHAR,
    "AddressLine"   VARCHAR,
    "ContactName"   VARCHAR,
    "Phone"         VARCHAR,
    "IsActive"      BOOLEAN,
    "CreatedAt"     TIMESTAMP,
    "UpdatedAt"     TIMESTAMP,
    "TotalCount"    BIGINT
) LANGUAGE plpgsql AS $$
DECLARE
    v_total BIGINT;
BEGIN
    SELECT COUNT(*) INTO v_total
    FROM inv."Warehouse"
    WHERE "CompanyId" = p_company_id
      AND (p_search IS NULL
           OR "WarehouseCode" ILIKE '%' || p_search || '%'
           OR "WarehouseName" ILIKE '%' || p_search || '%');

    RETURN QUERY
    SELECT w."WarehouseId", w."CompanyId", w."BranchId", w."WarehouseCode", w."WarehouseName",
           w."AddressLine", w."ContactName", w."Phone", w."IsActive", w."CreatedAt", w."UpdatedAt",
           v_total
    FROM inv."Warehouse" w
    WHERE w."CompanyId" = p_company_id
      AND (p_search IS NULL
           OR w."WarehouseCode" ILIKE '%' || p_search || '%'
           OR w."WarehouseName" ILIKE '%' || p_search || '%')
    ORDER BY w."WarehouseName"
    OFFSET (p_page - 1) * p_limit LIMIT p_limit;
END;
$$;

-- ============================================================================
--  SP: usp_Inv_Warehouse_Get
-- ============================================================================
DROP FUNCTION IF EXISTS usp_Inv_Warehouse_Get(INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_Inv_Warehouse_Get(
    p_company_id    INT,
    p_warehouse_id  INT
)
RETURNS TABLE (
    "WarehouseId"   INT,
    "CompanyId"     INT,
    "BranchId"      INT,
    "WarehouseCode" VARCHAR,
    "WarehouseName" VARCHAR,
    "AddressLine"   VARCHAR,
    "ContactName"   VARCHAR,
    "Phone"         VARCHAR,
    "IsActive"      BOOLEAN,
    "CreatedAt"     TIMESTAMP,
    "UpdatedAt"     TIMESTAMP
) LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT w."WarehouseId", w."CompanyId", w."BranchId", w."WarehouseCode", w."WarehouseName",
           w."AddressLine", w."ContactName", w."Phone", w."IsActive", w."CreatedAt", w."UpdatedAt"
    FROM inv."Warehouse" w
    WHERE w."CompanyId" = p_company_id AND w."WarehouseId" = p_warehouse_id;
END;
$$;

-- ============================================================================
--  SP: usp_Inv_Warehouse_Upsert
-- ============================================================================
DROP FUNCTION IF EXISTS usp_Inv_Warehouse_Upsert(INT, INT, INT, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, BOOLEAN, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_Inv_Warehouse_Upsert(
    p_company_id      INT,
    p_branch_id       INT,
    p_warehouse_id    INT            DEFAULT NULL,
    p_warehouse_code  VARCHAR(20)    DEFAULT NULL,
    p_warehouse_name  VARCHAR(100)   DEFAULT NULL,
    p_address_line    VARCHAR(250)   DEFAULT NULL,
    p_contact_name    VARCHAR(100)   DEFAULT NULL,
    p_phone           VARCHAR(50)    DEFAULT NULL,
    p_is_active       BOOLEAN        DEFAULT TRUE,
    p_user_id         INT            DEFAULT NULL
)
RETURNS TABLE ("ok" INT, "mensaje" VARCHAR, "WarehouseId" INT)
LANGUAGE plpgsql AS $$
DECLARE
    v_id INT;
BEGIN
    -- Validar codigo unico
    IF EXISTS (
        SELECT 1 FROM inv."Warehouse"
        WHERE "CompanyId" = p_company_id
          AND "WarehouseCode" = p_warehouse_code
          AND (p_warehouse_id IS NULL OR "WarehouseId" <> p_warehouse_id)
    ) THEN
        RETURN QUERY SELECT 0, 'El codigo de almacen ya existe'::VARCHAR, NULL::INT;
        RETURN;
    END IF;

    IF p_warehouse_id IS NULL THEN
        INSERT INTO inv."Warehouse" ("CompanyId", "BranchId", "WarehouseCode", "WarehouseName",
            "AddressLine", "ContactName", "Phone", "IsActive", "CreatedBy", "CreatedAt")
        VALUES (p_company_id, p_branch_id, p_warehouse_code, p_warehouse_name,
            p_address_line, p_contact_name, p_phone, p_is_active, p_user_id, NOW() AT TIME ZONE 'UTC')
        RETURNING "WarehouseId" INTO v_id;

        RETURN QUERY SELECT 1, 'Almacen creado'::VARCHAR, v_id;
    ELSE
        UPDATE inv."Warehouse"
        SET "WarehouseCode" = p_warehouse_code,
            "WarehouseName" = p_warehouse_name,
            "AddressLine"   = p_address_line,
            "ContactName"   = p_contact_name,
            "Phone"         = p_phone,
            "IsActive"      = p_is_active,
            "UpdatedBy"     = p_user_id,
            "UpdatedAt"     = NOW() AT TIME ZONE 'UTC'
        WHERE "WarehouseId" = p_warehouse_id AND "CompanyId" = p_company_id;

        RETURN QUERY SELECT 1, 'Almacen actualizado'::VARCHAR, p_warehouse_id;
    END IF;
END;
$$;

-- ============================================================================
--  SP: usp_Inv_Zone_List
-- ============================================================================
DROP FUNCTION IF EXISTS usp_Inv_Zone_List(INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_Inv_Zone_List(
    p_warehouse_id INT
)
RETURNS TABLE (
    "ZoneId"        INT,
    "WarehouseId"   INT,
    "ZoneCode"      VARCHAR,
    "ZoneName"      VARCHAR,
    "ZoneType"      VARCHAR,
    "Temperature"   VARCHAR,
    "IsActive"      BOOLEAN,
    "CreatedAt"     TIMESTAMP,
    "UpdatedAt"     TIMESTAMP
) LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT z."ZoneId", z."WarehouseId", z."ZoneCode", z."ZoneName",
           z."ZoneType", z."Temperature", z."IsActive", z."CreatedAt", z."UpdatedAt"
    FROM inv."WarehouseZone" z
    WHERE z."WarehouseId" = p_warehouse_id
    ORDER BY z."ZoneCode";
END;
$$;

-- ============================================================================
--  SP: usp_Inv_Zone_Upsert
-- ============================================================================
DROP FUNCTION IF EXISTS usp_Inv_Zone_Upsert(INT, INT, VARCHAR, VARCHAR, VARCHAR, VARCHAR, BOOLEAN, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_Inv_Zone_Upsert(
    p_zone_id       INT            DEFAULT NULL,
    p_warehouse_id  INT            DEFAULT NULL,
    p_zone_code     VARCHAR(20)    DEFAULT NULL,
    p_zone_name     VARCHAR(100)   DEFAULT NULL,
    p_zone_type     VARCHAR(30)    DEFAULT NULL,
    p_temperature   VARCHAR(20)    DEFAULT NULL,
    p_is_active     BOOLEAN        DEFAULT TRUE,
    p_user_id       INT            DEFAULT NULL
)
RETURNS TABLE ("ok" INT, "mensaje" VARCHAR)
LANGUAGE plpgsql AS $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM inv."WarehouseZone"
        WHERE "WarehouseId" = p_warehouse_id
          AND "ZoneCode" = p_zone_code
          AND (p_zone_id IS NULL OR "ZoneId" <> p_zone_id)
    ) THEN
        RETURN QUERY SELECT 0, 'El codigo de zona ya existe en este almacen'::VARCHAR;
        RETURN;
    END IF;

    IF p_zone_id IS NULL THEN
        INSERT INTO inv."WarehouseZone" ("WarehouseId", "ZoneCode", "ZoneName", "ZoneType",
            "Temperature", "IsActive", "CreatedBy", "CreatedAt")
        VALUES (p_warehouse_id, p_zone_code, p_zone_name, p_zone_type,
            p_temperature, p_is_active, p_user_id, NOW() AT TIME ZONE 'UTC');

        RETURN QUERY SELECT 1, 'Zona creada'::VARCHAR;
    ELSE
        UPDATE inv."WarehouseZone"
        SET "ZoneCode"    = p_zone_code,
            "ZoneName"    = p_zone_name,
            "ZoneType"    = p_zone_type,
            "Temperature" = p_temperature,
            "IsActive"    = p_is_active,
            "UpdatedBy"   = p_user_id,
            "UpdatedAt"   = NOW() AT TIME ZONE 'UTC'
        WHERE "ZoneId" = p_zone_id;

        RETURN QUERY SELECT 1, 'Zona actualizada'::VARCHAR;
    END IF;
END;
$$;

-- ============================================================================
--  SP: usp_Inv_Bin_List
-- ============================================================================
DROP FUNCTION IF EXISTS usp_Inv_Bin_List(INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_Inv_Bin_List(
    p_zone_id INT
)
RETURNS TABLE (
    "BinId"     INT,
    "ZoneId"    INT,
    "BinCode"   VARCHAR,
    "BinName"   VARCHAR,
    "MaxWeight" DECIMAL,
    "MaxVolume" DECIMAL,
    "IsActive"  BOOLEAN,
    "CreatedAt" TIMESTAMP,
    "UpdatedAt" TIMESTAMP
) LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT b."BinId", b."ZoneId", b."BinCode", b."BinName",
           b."MaxWeight", b."MaxVolume", b."IsActive", b."CreatedAt", b."UpdatedAt"
    FROM inv."WarehouseBin" b
    WHERE b."ZoneId" = p_zone_id
    ORDER BY b."BinCode";
END;
$$;

-- ============================================================================
--  SP: usp_Inv_Bin_Upsert
-- ============================================================================
DROP FUNCTION IF EXISTS usp_Inv_Bin_Upsert(INT, INT, VARCHAR, VARCHAR, DECIMAL, DECIMAL, BOOLEAN, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_Inv_Bin_Upsert(
    p_bin_id     INT             DEFAULT NULL,
    p_zone_id    INT             DEFAULT NULL,
    p_bin_code   VARCHAR(20)     DEFAULT NULL,
    p_bin_name   VARCHAR(100)    DEFAULT NULL,
    p_max_weight DECIMAL(12,2)   DEFAULT NULL,
    p_max_volume DECIMAL(12,2)   DEFAULT NULL,
    p_is_active  BOOLEAN         DEFAULT TRUE,
    p_user_id    INT             DEFAULT NULL
)
RETURNS TABLE ("ok" INT, "mensaje" VARCHAR)
LANGUAGE plpgsql AS $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM inv."WarehouseBin"
        WHERE "ZoneId" = p_zone_id
          AND "BinCode" = p_bin_code
          AND (p_bin_id IS NULL OR "BinId" <> p_bin_id)
    ) THEN
        RETURN QUERY SELECT 0, 'El codigo de ubicacion ya existe en esta zona'::VARCHAR;
        RETURN;
    END IF;

    IF p_bin_id IS NULL THEN
        INSERT INTO inv."WarehouseBin" ("ZoneId", "BinCode", "BinName", "MaxWeight",
            "MaxVolume", "IsActive", "CreatedBy", "CreatedAt")
        VALUES (p_zone_id, p_bin_code, p_bin_name, p_max_weight,
            p_max_volume, p_is_active, p_user_id, NOW() AT TIME ZONE 'UTC');

        RETURN QUERY SELECT 1, 'Ubicacion creada'::VARCHAR;
    ELSE
        UPDATE inv."WarehouseBin"
        SET "BinCode"   = p_bin_code,
            "BinName"   = p_bin_name,
            "MaxWeight" = p_max_weight,
            "MaxVolume" = p_max_volume,
            "IsActive"  = p_is_active,
            "UpdatedBy" = p_user_id,
            "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
        WHERE "BinId" = p_bin_id;

        RETURN QUERY SELECT 1, 'Ubicacion actualizada'::VARCHAR;
    END IF;
END;
$$;

-- ============================================================================
--  SP: usp_Inv_Lot_List
-- ============================================================================
DROP FUNCTION IF EXISTS usp_Inv_Lot_List(INT, INT, VARCHAR, INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_Inv_Lot_List(
    p_company_id INT,
    p_product_id BIGINT       DEFAULT NULL,
    p_status     VARCHAR(20)  DEFAULT NULL,
    p_page       INT          DEFAULT 1,
    p_limit      INT          DEFAULT 50
)
RETURNS TABLE (
    "LotId"                 BIGINT,
    "CompanyId"             INT,
    "ProductId"             BIGINT,
    "LotNumber"             VARCHAR,
    "ManufactureDate"       DATE,
    "ExpiryDate"            DATE,
    "SupplierCode"          VARCHAR,
    "PurchaseDocumentNumber" VARCHAR,
    "InitialQuantity"       DECIMAL,
    "CurrentQuantity"       DECIMAL,
    "UnitCost"              DECIMAL,
    "Status"                VARCHAR,
    "CreatedAt"             TIMESTAMP,
    "TotalCount"            BIGINT
) LANGUAGE plpgsql AS $$
DECLARE
    v_total BIGINT;
BEGIN
    SELECT COUNT(*) INTO v_total
    FROM inv."ProductLot" pl
    WHERE pl."CompanyId" = p_company_id
      AND (p_product_id IS NULL OR pl."ProductId" = p_product_id)
      AND (p_status IS NULL OR pl."Status" = p_status);

    RETURN QUERY
    SELECT l."LotId", l."CompanyId", l."ProductId", l."LotNumber",
           l."ManufactureDate", l."ExpiryDate", l."SupplierCode",
           l."PurchaseDocumentNumber", l."InitialQuantity", l."CurrentQuantity",
           l."UnitCost", l."Status", l."CreatedAt",
           v_total
    FROM inv."ProductLot" l
    WHERE l."CompanyId" = p_company_id
      AND (p_product_id IS NULL OR l."ProductId" = p_product_id)
      AND (p_status IS NULL OR l."Status" = p_status)
    ORDER BY l."CreatedAt" DESC
    OFFSET (p_page - 1) * p_limit LIMIT p_limit;
END;
$$;

-- ============================================================================
--  SP: usp_Inv_Lot_Get
-- ============================================================================
DROP FUNCTION IF EXISTS usp_Inv_Lot_Get(INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_Inv_Lot_Get(
    p_lot_id BIGINT
)
RETURNS TABLE (
    "LotId"                 BIGINT,
    "CompanyId"             INT,
    "ProductId"             BIGINT,
    "LotNumber"             VARCHAR,
    "ManufactureDate"       DATE,
    "ExpiryDate"            DATE,
    "SupplierCode"          VARCHAR,
    "PurchaseDocumentNumber" VARCHAR,
    "InitialQuantity"       DECIMAL,
    "CurrentQuantity"       DECIMAL,
    "UnitCost"              DECIMAL,
    "Status"                VARCHAR,
    "CreatedAt"             TIMESTAMP
) LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT l."LotId", l."CompanyId", l."ProductId", l."LotNumber",
           l."ManufactureDate", l."ExpiryDate", l."SupplierCode",
           l."PurchaseDocumentNumber", l."InitialQuantity", l."CurrentQuantity",
           l."UnitCost", l."Status", l."CreatedAt"
    FROM inv."ProductLot" l
    WHERE l."LotId" = p_lot_id;
END;
$$;

-- ============================================================================
--  SP: usp_Inv_Lot_Create
-- ============================================================================
DROP FUNCTION IF EXISTS usp_Inv_Lot_Create(INT, INT, VARCHAR, DATE, DATE, VARCHAR, VARCHAR, DECIMAL, DECIMAL, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_Inv_Lot_Create(
    p_company_id              INT,
    p_product_id              BIGINT,
    p_lot_number              VARCHAR(50),
    p_manufacture_date        DATE            DEFAULT NULL,
    p_expiry_date             DATE            DEFAULT NULL,
    p_supplier_code           VARCHAR(30)     DEFAULT NULL,
    p_purchase_document_number VARCHAR(30)    DEFAULT NULL,
    p_initial_quantity        DECIMAL(18,4)   DEFAULT 0,
    p_unit_cost               DECIMAL(18,4)   DEFAULT NULL,
    p_user_id                 INT             DEFAULT NULL
)
RETURNS TABLE ("ok" INT, "mensaje" VARCHAR, "LotId" INT)
LANGUAGE plpgsql AS $$
DECLARE
    v_id INT;
BEGIN
    IF EXISTS (
        SELECT 1 FROM inv."ProductLot"
        WHERE "CompanyId" = p_company_id AND "ProductId" = p_product_id AND "LotNumber" = p_lot_number
    ) THEN
        RETURN QUERY SELECT 0, 'El numero de lote ya existe para este producto'::VARCHAR, NULL::INT;
        RETURN;
    END IF;

    INSERT INTO inv."ProductLot" ("CompanyId", "ProductId", "LotNumber", "ManufactureDate", "ExpiryDate",
        "SupplierCode", "PurchaseDocumentNumber", "InitialQuantity", "CurrentQuantity", "UnitCost",
        "Status", "CreatedBy", "CreatedAt")
    VALUES (p_company_id, p_product_id, p_lot_number, p_manufacture_date, p_expiry_date,
        p_supplier_code, p_purchase_document_number, p_initial_quantity, p_initial_quantity, p_unit_cost,
        'ACTIVE', p_user_id, NOW() AT TIME ZONE 'UTC')
    RETURNING "LotId" INTO v_id;

    RETURN QUERY SELECT 1, 'Lote creado'::VARCHAR, v_id;
END;
$$;

-- ============================================================================
--  SP: usp_Inv_Serial_List
-- ============================================================================
DROP FUNCTION IF EXISTS usp_Inv_Serial_List(INT, INT, VARCHAR, VARCHAR, INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_Inv_Serial_List(
    p_company_id    INT,
    p_product_id    BIGINT          DEFAULT NULL,
    p_status        VARCHAR(20)     DEFAULT NULL,
    p_search        VARCHAR(100)    DEFAULT NULL,
    p_page          INT             DEFAULT 1,
    p_limit         INT             DEFAULT 50
)
RETURNS TABLE (
    "SerialId"              BIGINT,
    "CompanyId"             INT,
    "ProductId"             BIGINT,
    "SerialNumber"          VARCHAR,
    "LotId"                 BIGINT,
    "WarehouseId"           BIGINT,
    "BinId"                 BIGINT,
    "Status"                VARCHAR,
    "PurchaseDocumentNumber" VARCHAR,
    "SalesDocumentNumber"   VARCHAR,
    "CustomerId"            BIGINT,
    "CreatedAt"             TIMESTAMP,
    "UpdatedAt"             TIMESTAMP,
    "WarehouseName"         VARCHAR,
    "BinCode"               VARCHAR,
    "TotalCount"            BIGINT
) LANGUAGE plpgsql AS $$
DECLARE
    v_total BIGINT;
BEGIN
    SELECT COUNT(*) INTO v_total
    FROM inv."ProductSerial" ps
    WHERE ps."CompanyId" = p_company_id
      AND (p_product_id IS NULL OR ps."ProductId" = p_product_id)
      AND (p_status IS NULL OR ps."Status" = p_status)
      AND (p_search IS NULL OR ps."SerialNumber" ILIKE '%' || p_search || '%');

    RETURN QUERY
    SELECT s."SerialId", s."CompanyId", s."ProductId", s."SerialNumber", s."LotId",
           s."WarehouseId", s."BinId", s."Status",
           s."PurchaseDocumentNumber", s."SalesDocumentNumber", s."CustomerId",
           s."CreatedAt", s."UpdatedAt",
           w."WarehouseName", b."BinCode",
           v_total
    FROM inv."ProductSerial" s
    LEFT JOIN inv."Warehouse" w ON s."WarehouseId" = w."WarehouseId"
    LEFT JOIN inv."WarehouseBin" b ON s."BinId" = b."BinId"
    WHERE s."CompanyId" = p_company_id
      AND (p_product_id IS NULL OR s."ProductId" = p_product_id)
      AND (p_status IS NULL OR s."Status" = p_status)
      AND (p_search IS NULL OR s."SerialNumber" ILIKE '%' || p_search || '%')
    ORDER BY s."CreatedAt" DESC
    OFFSET (p_page - 1) * p_limit LIMIT p_limit;
END;
$$;

-- ============================================================================
--  SP: usp_Inv_Serial_Get
--  Nota: PG no soporta multiples resultsets. Se retorna el header.
--  El historial se obtiene via usp_Inv_Movement_List filtrando por SerialId.
-- ============================================================================
DROP FUNCTION IF EXISTS usp_Inv_Serial_Get(BIGINT) CASCADE;
CREATE OR REPLACE FUNCTION usp_Inv_Serial_Get(
    p_serial_id BIGINT
)
RETURNS TABLE (
    "SerialId"              BIGINT,
    "CompanyId"             INT,
    "ProductId"             BIGINT,
    "SerialNumber"          VARCHAR,
    "LotId"                 BIGINT,
    "WarehouseId"           BIGINT,
    "BinId"                 BIGINT,
    "Status"                VARCHAR,
    "PurchaseDocumentNumber" VARCHAR,
    "SalesDocumentNumber"   VARCHAR,
    "CustomerId"            BIGINT,
    "CreatedAt"             TIMESTAMP,
    "UpdatedAt"             TIMESTAMP,
    "WarehouseName"         VARCHAR,
    "BinCode"               VARCHAR,
    "LotNumber"             VARCHAR
) LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT s."SerialId", s."CompanyId", s."ProductId", s."SerialNumber", s."LotId",
           s."WarehouseId", s."BinId", s."Status",
           s."PurchaseDocumentNumber", s."SalesDocumentNumber", s."CustomerId",
           s."CreatedAt", s."UpdatedAt",
           w."WarehouseName", b."BinCode", l."LotNumber"
    FROM inv."ProductSerial" s
    LEFT JOIN inv."Warehouse" w ON s."WarehouseId" = w."WarehouseId"
    LEFT JOIN inv."WarehouseBin" b ON s."BinId" = b."BinId"
    LEFT JOIN inv."ProductLot" l ON s."LotId" = l."LotId"
    WHERE s."SerialId" = p_serial_id;
END;
$$;

-- ============================================================================
--  SP: usp_Inv_Serial_Register
-- ============================================================================
DROP FUNCTION IF EXISTS usp_Inv_Serial_Register(INT, BIGINT, VARCHAR, BIGINT, BIGINT, BIGINT, VARCHAR, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_Inv_Serial_Register(
    p_company_id              INT,
    p_product_id              BIGINT,
    p_serial_number           VARCHAR(100),
    p_lot_id                  BIGINT          DEFAULT NULL,
    p_warehouse_id            BIGINT          DEFAULT NULL,
    p_bin_id                  BIGINT          DEFAULT NULL,
    p_purchase_document_number VARCHAR(60)    DEFAULT NULL,
    p_user_id                 INT             DEFAULT NULL
)
RETURNS TABLE ("ok" INT, "mensaje" VARCHAR, "SerialId" BIGINT)
LANGUAGE plpgsql AS $$
DECLARE
    v_id BIGINT;
BEGIN
    IF EXISTS (
        SELECT 1 FROM inv."ProductSerial"
        WHERE "CompanyId" = p_company_id AND "SerialNumber" = p_serial_number
    ) THEN
        RETURN QUERY SELECT 0, 'El numero de serie ya existe'::VARCHAR, NULL::BIGINT;
        RETURN;
    END IF;

    INSERT INTO inv."ProductSerial" ("CompanyId", "ProductId", "SerialNumber", "LotId", "WarehouseId",
        "BinId", "Status", "PurchaseDocumentNumber", "CreatedByUserId", "CreatedAt")
    VALUES (p_company_id, p_product_id, p_serial_number, p_lot_id, p_warehouse_id,
        p_bin_id, 'AVAILABLE', p_purchase_document_number, p_user_id, NOW() AT TIME ZONE 'UTC')
    RETURNING "SerialId" INTO v_id;

    RETURN QUERY SELECT 1, 'Serial registrado'::VARCHAR, v_id;
END;
$$;

-- ============================================================================
--  SP: usp_Inv_Serial_UpdateStatus
-- ============================================================================
DROP FUNCTION IF EXISTS usp_Inv_Serial_UpdateStatus(INT, VARCHAR, VARCHAR, INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_Inv_Serial_UpdateStatus(
    p_serial_id              INT,
    p_status                 VARCHAR(20),
    p_sales_document_number  VARCHAR(30)    DEFAULT NULL,
    p_customer_id            BIGINT         DEFAULT NULL,
    p_user_id                INT            DEFAULT NULL
)
RETURNS TABLE ("ok" INT, "mensaje" VARCHAR)
LANGUAGE plpgsql AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM inv."ProductSerial" WHERE "SerialId" = p_serial_id) THEN
        RETURN QUERY SELECT 0, 'Serial no encontrado'::VARCHAR;
        RETURN;
    END IF;

    UPDATE inv."ProductSerial"
    SET "Status"               = p_status,
        "SalesDocumentNumber"  = COALESCE(p_sales_document_number, "SalesDocumentNumber"),
        "CustomerId"           = COALESCE(p_customer_id, "CustomerId"),
        "UpdatedBy"            = p_user_id,
        "UpdatedAt"            = NOW() AT TIME ZONE 'UTC'
    WHERE "SerialId" = p_serial_id;

    RETURN QUERY SELECT 1, 'Estado de serial actualizado'::VARCHAR;
END;
$$;

-- ============================================================================
--  SP: usp_Inv_BinStock_List
-- ============================================================================
DROP FUNCTION IF EXISTS usp_Inv_BinStock_List(INT, INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_Inv_BinStock_List(
    p_company_id    INT,
    p_warehouse_id  INT     DEFAULT NULL,
    p_product_id    BIGINT  DEFAULT NULL
)
RETURNS TABLE (
    "ProductBinStockId" INT,
    "CompanyId"         INT,
    "ProductId"         BIGINT,
    "WarehouseId"       INT,
    "ZoneId"            INT,
    "BinId"             INT,
    "LotId"             INT,
    "Quantity"          DECIMAL,
    "ReservedQuantity"  DECIMAL,
    "AvailableQuantity" DECIMAL,
    "WarehouseName"     VARCHAR,
    "WarehouseCode"     VARCHAR,
    "ZoneName"          VARCHAR,
    "ZoneCode"          VARCHAR,
    "BinName"           VARCHAR,
    "BinCode"           VARCHAR,
    "LotNumber"         VARCHAR
) LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT bs."ProductBinStockId", bs."CompanyId", bs."ProductId",
           bs."WarehouseId", bs."ZoneId", bs."BinId", bs."LotId",
           bs."Quantity", bs."ReservedQuantity",
           (bs."Quantity" - bs."ReservedQuantity"),
           w."WarehouseName", w."WarehouseCode",
           z."ZoneName", z."ZoneCode",
           b."BinName", b."BinCode",
           l."LotNumber"
    FROM inv."ProductBinStock" bs
    INNER JOIN inv."Warehouse" w ON bs."WarehouseId" = w."WarehouseId"
    LEFT JOIN inv."WarehouseZone" z ON bs."ZoneId" = z."ZoneId"
    LEFT JOIN inv."WarehouseBin" b ON bs."BinId" = b."BinId"
    LEFT JOIN inv."ProductLot" l ON bs."LotId" = l."LotId"
    WHERE bs."CompanyId" = p_company_id
      AND (p_warehouse_id IS NULL OR bs."WarehouseId" = p_warehouse_id)
      AND (p_product_id IS NULL OR bs."ProductId" = p_product_id)
    ORDER BY w."WarehouseName", z."ZoneCode", b."BinCode";
END;
$$;

-- ============================================================================
--  SP: usp_Inv_Valuation_GetMethod
-- ============================================================================
DROP FUNCTION IF EXISTS usp_Inv_Valuation_GetMethod(INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_Inv_Valuation_GetMethod(
    p_company_id INT,
    p_product_id BIGINT
)
RETURNS TABLE (
    "ValuationMethodId" INT,
    "CompanyId"         INT,
    "ProductId"         BIGINT,
    "Method"            VARCHAR,
    "StandardCost"      DECIMAL,
    "UpdatedAt"         TIMESTAMP
) LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT v."ValuationMethodId", v."CompanyId", v."ProductId", v."Method",
           v."StandardCost", v."UpdatedAt"
    FROM inv."InventoryValuationMethod" v
    WHERE v."CompanyId" = p_company_id AND v."ProductId" = p_product_id;
END;
$$;

-- ============================================================================
--  SP: usp_Inv_Valuation_SetMethod
-- ============================================================================
DROP FUNCTION IF EXISTS usp_Inv_Valuation_SetMethod(INT, INT, VARCHAR, DECIMAL, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_Inv_Valuation_SetMethod(
    p_company_id    INT,
    p_product_id    BIGINT,
    p_method        VARCHAR(20),
    p_standard_cost DECIMAL(18,4)   DEFAULT NULL,
    p_user_id       INT             DEFAULT NULL
)
RETURNS TABLE ("ok" INT, "mensaje" VARCHAR)
LANGUAGE plpgsql AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM inv."InventoryValuationMethod" WHERE "CompanyId" = p_company_id AND "ProductId" = p_product_id) THEN
        UPDATE inv."InventoryValuationMethod"
        SET "Method"       = p_method,
            "StandardCost" = p_standard_cost,
            "UpdatedBy"    = p_user_id,
            "UpdatedAt"    = NOW() AT TIME ZONE 'UTC'
        WHERE "CompanyId" = p_company_id AND "ProductId" = p_product_id;
    ELSE
        INSERT INTO inv."InventoryValuationMethod" ("CompanyId", "ProductId", "Method", "StandardCost", "UpdatedBy", "UpdatedAt")
        VALUES (p_company_id, p_product_id, p_method, p_standard_cost, p_user_id, NOW() AT TIME ZONE 'UTC');
    END IF;

    RETURN QUERY SELECT 1, 'Metodo de valoracion actualizado'::VARCHAR;
END;
$$;

-- ============================================================================
--  SP: usp_Inv_Movement_List
-- ============================================================================
DROP FUNCTION IF EXISTS usp_Inv_Movement_List(INT, INT, INT, VARCHAR, DATE, DATE, INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_Inv_Movement_List(
    p_company_id      INT,
    p_product_id      BIGINT        DEFAULT NULL,
    p_warehouse_id    INT           DEFAULT NULL,
    p_movement_type   VARCHAR(30)   DEFAULT NULL,
    p_fecha_desde     DATE          DEFAULT NULL,
    p_fecha_hasta     DATE          DEFAULT NULL,
    p_page            INT           DEFAULT 1,
    p_limit           INT           DEFAULT 50
)
RETURNS TABLE (
    "MovementId"            BIGINT,
    "CompanyId"             INT,
    "BranchId"              INT,
    "ProductId"             BIGINT,
    "LotId"                 INT,
    "SerialId"              INT,
    "FromWarehouseId"       INT,
    "ToWarehouseId"         INT,
    "FromBinId"             INT,
    "ToBinId"               INT,
    "MovementType"          VARCHAR,
    "Quantity"              DECIMAL,
    "UnitCost"              DECIMAL,
    "SourceDocumentType"    VARCHAR,
    "SourceDocumentNumber"  VARCHAR,
    "Notes"                 VARCHAR,
    "CreatedAt"             TIMESTAMP,
    "FromWarehouseName"     VARCHAR,
    "ToWarehouseName"       VARCHAR,
    "TotalCount"            BIGINT
) LANGUAGE plpgsql AS $$
DECLARE
    v_total BIGINT;
BEGIN
    SELECT COUNT(*) INTO v_total
    FROM inv."StockMovement"
    WHERE "CompanyId" = p_company_id
      AND (p_product_id IS NULL OR "ProductId" = p_product_id)
      AND (p_warehouse_id IS NULL OR "FromWarehouseId" = p_warehouse_id OR "ToWarehouseId" = p_warehouse_id)
      AND (p_movement_type IS NULL OR "MovementType" = p_movement_type)
      AND (p_fecha_desde IS NULL OR "CreatedAt"::DATE >= p_fecha_desde)
      AND (p_fecha_hasta IS NULL OR "CreatedAt"::DATE <= p_fecha_hasta);

    RETURN QUERY
    SELECT m."MovementId", m."CompanyId", m."BranchId", m."ProductId",
           m."LotId", m."SerialId",
           m."FromWarehouseId", m."ToWarehouseId", m."FromBinId", m."ToBinId",
           m."MovementType", m."Quantity", m."UnitCost",
           m."SourceDocumentType", m."SourceDocumentNumber", m."Notes", m."CreatedAt",
           fw."WarehouseName",
           tw."WarehouseName",
           v_total
    FROM inv."StockMovement" m
    LEFT JOIN inv."Warehouse" fw ON m."FromWarehouseId" = fw."WarehouseId"
    LEFT JOIN inv."Warehouse" tw ON m."ToWarehouseId" = tw."WarehouseId"
    WHERE m."CompanyId" = p_company_id
      AND (p_product_id IS NULL OR m."ProductId" = p_product_id)
      AND (p_warehouse_id IS NULL OR m."FromWarehouseId" = p_warehouse_id OR m."ToWarehouseId" = p_warehouse_id)
      AND (p_movement_type IS NULL OR m."MovementType" = p_movement_type)
      AND (p_fecha_desde IS NULL OR m."CreatedAt"::DATE >= p_fecha_desde)
      AND (p_fecha_hasta IS NULL OR m."CreatedAt"::DATE <= p_fecha_hasta)
    ORDER BY m."CreatedAt" DESC
    OFFSET (p_page - 1) * p_limit LIMIT p_limit;
END;
$$;

-- ============================================================================
--  SP: usp_Inv_Movement_Create
-- ============================================================================
DROP FUNCTION IF EXISTS usp_Inv_Movement_Create(INT, INT, INT, INT, INT, INT, INT, INT, INT, VARCHAR, DECIMAL, DECIMAL, VARCHAR, VARCHAR, VARCHAR, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_Inv_Movement_Create(
    p_company_id              INT,
    p_branch_id               INT,
    p_product_id              BIGINT,
    p_lot_id                  INT             DEFAULT NULL,
    p_serial_id               INT             DEFAULT NULL,
    p_from_warehouse_id       INT             DEFAULT NULL,
    p_to_warehouse_id         INT             DEFAULT NULL,
    p_from_bin_id             INT             DEFAULT NULL,
    p_to_bin_id               INT             DEFAULT NULL,
    p_movement_type           VARCHAR(30)     DEFAULT NULL,
    p_quantity                DECIMAL(18,4)   DEFAULT 0,
    p_unit_cost               DECIMAL(18,4)   DEFAULT NULL,
    p_source_document_type    VARCHAR(30)     DEFAULT NULL,
    p_source_document_number  VARCHAR(30)     DEFAULT NULL,
    p_notes                   VARCHAR(500)    DEFAULT NULL,
    p_user_id                 INT             DEFAULT NULL
)
RETURNS TABLE ("ok" INT, "mensaje" VARCHAR, "MovementId" BIGINT)
LANGUAGE plpgsql AS $$
DECLARE
    v_id INT;
    v_to_zone_id INT;
BEGIN
    INSERT INTO inv."StockMovement" ("CompanyId", "BranchId", "ProductId", "LotId", "SerialId",
        "FromWarehouseId", "ToWarehouseId", "FromBinId", "ToBinId",
        "MovementType", "Quantity", "UnitCost",
        "SourceDocumentType", "SourceDocumentNumber", "Notes", "CreatedBy", "CreatedAt")
    VALUES (p_company_id, p_branch_id, p_product_id, p_lot_id, p_serial_id,
        p_from_warehouse_id, p_to_warehouse_id, p_from_bin_id, p_to_bin_id,
        p_movement_type, p_quantity, p_unit_cost,
        p_source_document_type, p_source_document_number, p_notes, p_user_id, NOW() AT TIME ZONE 'UTC')
    RETURNING "MovementId" INTO v_id;

    -- Actualizar stock en ubicacion destino (si aplica)
    IF p_to_warehouse_id IS NOT NULL THEN
        SELECT "ZoneId" INTO v_to_zone_id FROM inv."WarehouseBin" WHERE "BinId" = p_to_bin_id;

        IF EXISTS (
            SELECT 1 FROM inv."ProductBinStock"
            WHERE "CompanyId" = p_company_id AND "ProductId" = p_product_id
              AND "WarehouseId" = p_to_warehouse_id
              AND COALESCE("ZoneId", 0) = COALESCE(v_to_zone_id, 0)
              AND COALESCE("BinId", 0) = COALESCE(p_to_bin_id, 0)
              AND COALESCE("LotId", 0) = COALESCE(p_lot_id, 0)
        ) THEN
            UPDATE inv."ProductBinStock"
            SET "Quantity"  = "Quantity" + p_quantity,
                "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
            WHERE "CompanyId" = p_company_id AND "ProductId" = p_product_id
              AND "WarehouseId" = p_to_warehouse_id
              AND COALESCE("ZoneId", 0) = COALESCE(v_to_zone_id, 0)
              AND COALESCE("BinId", 0) = COALESCE(p_to_bin_id, 0)
              AND COALESCE("LotId", 0) = COALESCE(p_lot_id, 0);
        ELSE
            INSERT INTO inv."ProductBinStock" ("CompanyId", "ProductId", "WarehouseId", "ZoneId", "BinId", "LotId", "Quantity", "ReservedQuantity", "UpdatedAt")
            VALUES (p_company_id, p_product_id, p_to_warehouse_id, v_to_zone_id, p_to_bin_id, p_lot_id, p_quantity, 0, NOW() AT TIME ZONE 'UTC');
        END IF;
    END IF;

    -- Descontar stock de ubicacion origen (si aplica)
    IF p_from_warehouse_id IS NOT NULL THEN
        UPDATE inv."ProductBinStock"
        SET "Quantity"  = "Quantity" - p_quantity,
            "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
        WHERE "CompanyId" = p_company_id AND "ProductId" = p_product_id
          AND "WarehouseId" = p_from_warehouse_id
          AND COALESCE("BinId", 0) = COALESCE(p_from_bin_id, 0)
          AND COALESCE("LotId", 0) = COALESCE(p_lot_id, 0);
    END IF;

    RETURN QUERY SELECT 1, 'Movimiento registrado'::VARCHAR, v_id;
END;
$$;
