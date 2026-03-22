-- ============================================================
-- DatqBoxWeb PostgreSQL - usp_logistics.sql
-- Funciones de logistica: transportistas, conductores,
-- recepciones de mercancia, devoluciones y notas de entrega.
-- Traducido de SQL Server stored procedures a PL/pgSQL.
-- ============================================================

-- ============================================================================
--  Schema: logistics
-- ============================================================================
CREATE SCHEMA IF NOT EXISTS logistics;

-- ============================================================================
--  Tabla: logistics."Carrier"
-- ============================================================================
CREATE TABLE IF NOT EXISTS logistics."Carrier" (
    "CarrierId" BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    "CompanyId"        INT NOT NULL,
    "CarrierCode"      VARCHAR(20) NOT NULL,
    "CarrierName"      VARCHAR(100) NOT NULL,
    "FiscalId"         VARCHAR(30) NULL,
    "ContactName"      VARCHAR(100) NULL,
    "Phone"            VARCHAR(50) NULL,
    "Email"            VARCHAR(100) NULL,
    "AddressLine"      VARCHAR(250) NULL,
    "IsActive"         BOOLEAN NOT NULL DEFAULT TRUE,
    "IsDeleted"        BOOLEAN NOT NULL DEFAULT FALSE,
    "CreatedAt"        TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "UpdatedAt"        TIMESTAMP NULL,
    "CreatedByUserId"  INT NULL,
    "UpdatedByUserId"  INT NULL,
    "RowVer"           INT NOT NULL DEFAULT 1
);

CREATE UNIQUE INDEX IF NOT EXISTS "UX_Carrier_Code"
    ON logistics."Carrier"("CompanyId", "CarrierCode");

-- ============================================================================
--  Tabla: logistics."Driver"
-- ============================================================================
CREATE TABLE IF NOT EXISTS logistics."Driver" (
    "DriverId" BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    "CompanyId"        INT NOT NULL,
    "CarrierId" BIGINT NULL REFERENCES logistics."Carrier"("CarrierId"),
    "DriverCode"       VARCHAR(20) NOT NULL,
    "DriverName"       VARCHAR(100) NOT NULL,
    "FiscalId"         VARCHAR(30) NULL,
    "LicenseNumber"    VARCHAR(30) NULL,
    "LicenseExpiry"    DATE NULL,
    "Phone"            VARCHAR(50) NULL,
    "IsActive"         BOOLEAN NOT NULL DEFAULT TRUE,
    "IsDeleted"        BOOLEAN NOT NULL DEFAULT FALSE,
    "CreatedAt"        TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "UpdatedAt"        TIMESTAMP NULL,
    "CreatedByUserId"  INT NULL,
    "UpdatedByUserId"  INT NULL,
    "RowVer"           INT NOT NULL DEFAULT 1
);

CREATE UNIQUE INDEX IF NOT EXISTS "UX_Driver_Code"
    ON logistics."Driver"("CompanyId", "DriverCode");

-- ============================================================================
--  Tabla: logistics."GoodsReceipt"
-- ============================================================================
CREATE TABLE IF NOT EXISTS logistics."GoodsReceipt" (
    "GoodsReceiptId" BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    "CompanyId"             INT NOT NULL,
    "BranchId"              INT NOT NULL,
    "ReceiptNumber"         VARCHAR(20) NOT NULL,
    "PurchaseDocumentNumber" VARCHAR(30) NULL,
    "SupplierId" BIGINT NULL,
    "WarehouseId" BIGINT NOT NULL,
    "ReceiptDate" DATE NOT NULL,
    "Status"                VARCHAR(20) NOT NULL DEFAULT 'DRAFT',
    "Notes"                 VARCHAR(500) NULL,
    "CarrierId" BIGINT NULL REFERENCES logistics."Carrier"("CarrierId"),
    "DriverName"            VARCHAR(100) NULL,
    "VehiclePlate"          VARCHAR(20) NULL,
    "ReceivedByUserId"      INT NULL,
    "IsDeleted"             BOOLEAN NOT NULL DEFAULT FALSE,
    "CreatedAt"             TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "UpdatedAt"             TIMESTAMP NULL,
    "CreatedByUserId"       INT NULL,
    "UpdatedByUserId"       INT NULL,
    "RowVer"                INT NOT NULL DEFAULT 1
);

CREATE UNIQUE INDEX IF NOT EXISTS "UX_Receipt_Number"
    ON logistics."GoodsReceipt"("CompanyId", "ReceiptNumber");

CREATE INDEX IF NOT EXISTS "IX_Receipt_Date"
    ON logistics."GoodsReceipt"("CompanyId", "BranchId", "ReceiptDate" DESC);

-- ============================================================================
--  Tabla: logistics."GoodsReceiptLine"
-- ============================================================================
CREATE TABLE IF NOT EXISTS logistics."GoodsReceiptLine" (
    "GoodsReceiptLineId" INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    "GoodsReceiptId" BIGINT NOT NULL REFERENCES logistics."GoodsReceipt"("GoodsReceiptId"),
    "LineNumber"        INT NOT NULL DEFAULT 0,
    "ProductId" BIGINT NOT NULL,
    "ProductCode"       VARCHAR(30) NULL,
    "Description"       VARCHAR(250) NULL,
    "OrderedQuantity"   DECIMAL(18,4) NOT NULL DEFAULT 0,
    "ReceivedQuantity"  DECIMAL(18,4) NOT NULL DEFAULT 0,
    "RejectedQuantity"  DECIMAL(18,4) NOT NULL DEFAULT 0,
    "UnitCost"          DECIMAL(18,4) NULL,
    "TotalCost"         DECIMAL(18,4) NULL,
    "LotNumber"         VARCHAR(50) NULL,
    "ExpiryDate"        DATE NULL,
    "WarehouseId" BIGINT NULL,
    "BinId"             INT NULL,
    "InspectionStatus"  VARCHAR(20) NULL,
    "Notes"             VARCHAR(250) NULL,
    "IsDeleted"         BOOLEAN NOT NULL DEFAULT FALSE,
    "CreatedAt"         TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "UpdatedAt"         TIMESTAMP NULL,
    "CreatedByUserId"   INT NULL,
    "UpdatedByUserId"   INT NULL,
    "RowVer"            INT NOT NULL DEFAULT 1
);

-- ============================================================================
--  Tabla: logistics."GoodsReceiptSerial"
-- ============================================================================
CREATE TABLE IF NOT EXISTS logistics."GoodsReceiptSerial" (
    "Id"            INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    "LineId"        INT NOT NULL REFERENCES logistics."GoodsReceiptLine"("LineId"),
    "SerialNumber"  VARCHAR(100) NOT NULL
);

-- ============================================================================
--  Tabla: logistics."GoodsReturn"
-- ============================================================================
CREATE TABLE IF NOT EXISTS logistics."GoodsReturn" (
    "GoodsReturnId" BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    "CompanyId"         INT NOT NULL,
    "BranchId"          INT NOT NULL,
    "ReturnNumber"      VARCHAR(20) NOT NULL,
    "GoodsReceiptId" BIGINT NULL REFERENCES logistics."GoodsReceipt"("GoodsReceiptId"),
    "SupplierId" BIGINT NULL,
    "WarehouseId" BIGINT NOT NULL,
    "ReturnDate" DATE NOT NULL,
    "Reason"            VARCHAR(250) NULL,
    "Status"            VARCHAR(20) NOT NULL DEFAULT 'DRAFT',
    "Notes"             VARCHAR(500) NULL,
    "IsDeleted"         BOOLEAN NOT NULL DEFAULT FALSE,
    "CreatedAt"         TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "UpdatedAt"         TIMESTAMP NULL,
    "CreatedByUserId"   INT NULL,
    "UpdatedByUserId"   INT NULL,
    "RowVer"            INT NOT NULL DEFAULT 1
);

CREATE UNIQUE INDEX IF NOT EXISTS "UX_Return_Number"
    ON logistics."GoodsReturn"("CompanyId", "ReturnNumber");

-- ============================================================================
--  Tabla: logistics."GoodsReturnLine"
-- ============================================================================
CREATE TABLE IF NOT EXISTS logistics."GoodsReturnLine" (
    "LineId"            INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    "GoodsReturnId" BIGINT NOT NULL REFERENCES logistics."GoodsReturn"("GoodsReturnId"),
    "ProductId" BIGINT NOT NULL,
    "Quantity"          DECIMAL(18,4) NOT NULL DEFAULT 0,
    "UnitCost"          DECIMAL(18,4) NULL,
    "LotNumber"         VARCHAR(50) NULL,
    "SerialNumber"      VARCHAR(100) NULL,
    "Notes"             VARCHAR(250) NULL
);

-- ============================================================================
--  Tabla: logistics."DeliveryNote"
-- ============================================================================
CREATE TABLE IF NOT EXISTS logistics."DeliveryNote" (
    "DeliveryNoteId" BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    "CompanyId"             INT NOT NULL,
    "BranchId"              INT NOT NULL,
    "DeliveryNumber"        VARCHAR(20) NOT NULL,
    "SalesDocumentNumber"   VARCHAR(30) NULL,
    "CustomerId" BIGINT NULL,
    "WarehouseId" BIGINT NOT NULL,
    "DeliveryDate" DATE NOT NULL,
    "Status"                VARCHAR(20) NOT NULL DEFAULT 'DRAFT',
    "CarrierId" BIGINT NULL REFERENCES logistics."Carrier"("CarrierId"),
    "DriverId" BIGINT NULL REFERENCES logistics."Driver"("DriverId"),
    "VehiclePlate"          VARCHAR(20) NULL,
    "ShipToAddress"         VARCHAR(500) NULL,
    "ShipToContact"         VARCHAR(100) NULL,
    "EstimatedDelivery" DATE NULL,
    "ActualDelivery" DATE NULL,
    "DeliveredToName"       VARCHAR(100) NULL,
    "DeliverySignature"     TEXT NULL,
    "Notes"                 VARCHAR(500) NULL,
    "DispatchedByUserId"    INT NULL,
    "IsDeleted"             BOOLEAN NOT NULL DEFAULT FALSE,
    "CreatedAt"             TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "UpdatedAt"             TIMESTAMP NULL,
    "CreatedByUserId"       INT NULL,
    "UpdatedByUserId"       INT NULL,
    "RowVer"                INT NOT NULL DEFAULT 1
);

CREATE UNIQUE INDEX IF NOT EXISTS "UX_Delivery_Number"
    ON logistics."DeliveryNote"("CompanyId", "DeliveryNumber");

CREATE INDEX IF NOT EXISTS "IX_Delivery_Date"
    ON logistics."DeliveryNote"("CompanyId", "BranchId", "DeliveryDate" DESC);

-- ============================================================================
--  Tabla: logistics."DeliveryNoteLine"
-- ============================================================================
CREATE TABLE IF NOT EXISTS logistics."DeliveryNoteLine" (
    "LineId"            INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    "DeliveryNoteId" BIGINT NOT NULL REFERENCES logistics."DeliveryNote"("DeliveryNoteId"),
    "ProductId" BIGINT NOT NULL,
    "Quantity"          DECIMAL(18,4) NOT NULL DEFAULT 0,
    "UnitCost"          DECIMAL(18,4) NULL,
    "LotNumber"         VARCHAR(50) NULL,
    "BinId"             INT NULL,
    "Notes"             VARCHAR(250) NULL
);

-- ============================================================================
--  Tabla: logistics."DeliveryNoteSerial"
-- ============================================================================
CREATE TABLE IF NOT EXISTS logistics."DeliveryNoteSerial" (
    "Id"            INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    "LineId"        INT NOT NULL REFERENCES logistics."DeliveryNoteLine"("LineId"),
    "SerialNumber"  VARCHAR(100) NOT NULL
);


-- ============================================================================
--  SP: usp_Logistics_Carrier_List
-- ============================================================================
DROP FUNCTION IF EXISTS usp_Logistics_Carrier_List(INT, VARCHAR, INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_Logistics_Carrier_List(
    p_company_id    INT,
    p_search        VARCHAR(100)    DEFAULT NULL,
    p_page          INT             DEFAULT 1,
    p_limit         INT             DEFAULT 50
)
RETURNS TABLE (
    "CarrierId" BIGINT,
    "CompanyId"     INT,
    "CarrierCode"   VARCHAR,
    "CarrierName"   VARCHAR,
    "FiscalId"      VARCHAR,
    "ContactName"   VARCHAR,
    "Phone"         VARCHAR,
    "Email"         VARCHAR,
    "AddressLine"   VARCHAR,
    "IsActive"      BOOLEAN,
    "CreatedAt"     TIMESTAMP,
    "UpdatedAt"     TIMESTAMP,
    "TotalCount"    BIGINT
) LANGUAGE plpgsql AS $$
DECLARE
    v_total BIGINT;
BEGIN
    SELECT COUNT(*) INTO v_total
    FROM logistics."Carrier" c
    WHERE c."CompanyId" = p_company_id
      AND c."IsDeleted" = FALSE
      AND (p_search IS NULL
           OR c."CarrierCode" ILIKE '%' || p_search || '%'
           OR c."CarrierName" ILIKE '%' || p_search || '%'
           OR c."FiscalId" ILIKE '%' || p_search || '%');

    RETURN QUERY
    SELECT c."CarrierId", c."CompanyId", c."CarrierCode", c."CarrierName", c."FiscalId",
           c."ContactName", c."Phone", c."Email", c."AddressLine", c."IsActive",
           c."CreatedAt", c."UpdatedAt",
           v_total
    FROM logistics."Carrier" c
    WHERE c."CompanyId" = p_company_id
      AND c."IsDeleted" = FALSE
      AND (p_search IS NULL
           OR c."CarrierCode" ILIKE '%' || p_search || '%'
           OR c."CarrierName" ILIKE '%' || p_search || '%'
           OR c."FiscalId" ILIKE '%' || p_search || '%')
    ORDER BY c."CarrierName"
    OFFSET (p_page - 1) * p_limit LIMIT p_limit;
END;
$$;

-- ============================================================================
--  SP: usp_Logistics_Carrier_Upsert
-- ============================================================================
DROP FUNCTION IF EXISTS usp_Logistics_Carrier_Upsert(INT, INT, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, BOOLEAN, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_Logistics_Carrier_Upsert(
    p_company_id    INT,
    p_carrier_id    INT             DEFAULT NULL,
    p_carrier_code  VARCHAR(20)     DEFAULT NULL,
    p_carrier_name  VARCHAR(100)    DEFAULT NULL,
    p_fiscal_id     VARCHAR(30)     DEFAULT NULL,
    p_contact_name  VARCHAR(100)    DEFAULT NULL,
    p_phone         VARCHAR(50)     DEFAULT NULL,
    p_email         VARCHAR(100)    DEFAULT NULL,
    p_address_line  VARCHAR(250)    DEFAULT NULL,
    p_is_active     BOOLEAN         DEFAULT TRUE,
    p_user_id       INT             DEFAULT NULL
)
RETURNS TABLE ("ok" INT, "mensaje" VARCHAR)
LANGUAGE plpgsql AS $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM logistics."Carrier"
        WHERE "CompanyId" = p_company_id AND "CarrierCode" = p_carrier_code
          AND "IsDeleted" = FALSE
          AND (p_carrier_id IS NULL OR "CarrierId" <> p_carrier_id)
    ) THEN
        RETURN QUERY SELECT 0, 'El codigo de transportista ya existe'::VARCHAR;
        RETURN;
    END IF;

    IF p_carrier_id IS NULL THEN
        INSERT INTO logistics."Carrier" ("CompanyId", "CarrierCode", "CarrierName", "FiscalId",
            "ContactName", "Phone", "Email", "AddressLine", "IsActive", "CreatedByUserId", "UpdatedByUserId", "CreatedAt", "UpdatedAt")
        VALUES (p_company_id, p_carrier_code, p_carrier_name, p_fiscal_id,
            p_contact_name, p_phone, p_email, p_address_line, p_is_active, p_user_id, p_user_id, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC');

        RETURN QUERY SELECT 1, 'Transportista creado'::VARCHAR;
    ELSE
        UPDATE logistics."Carrier"
        SET "CarrierCode" = p_carrier_code,
            "CarrierName" = p_carrier_name,
            "FiscalId"    = p_fiscal_id,
            "ContactName" = p_contact_name,
            "Phone"       = p_phone,
            "Email"       = p_email,
            "AddressLine" = p_address_line,
            "IsActive"    = p_is_active,
            "UpdatedByUserId" = p_user_id,
            "UpdatedAt"       = NOW() AT TIME ZONE 'UTC'
        WHERE "CarrierId" = p_carrier_id AND "CompanyId" = p_company_id;

        RETURN QUERY SELECT 1, 'Transportista actualizado'::VARCHAR;
    END IF;
END;
$$;

-- ============================================================================
--  SP: usp_Logistics_Driver_List
-- ============================================================================
DROP FUNCTION IF EXISTS usp_Logistics_Driver_List(INT, INT, VARCHAR, INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_Logistics_Driver_List(
    p_company_id    INT,
    p_carrier_id    INT             DEFAULT NULL,
    p_search        VARCHAR(100)    DEFAULT NULL,
    p_page          INT             DEFAULT 1,
    p_limit         INT             DEFAULT 50
)
RETURNS TABLE (
    "DriverId" BIGINT,
    "CompanyId"     INT,
    "CarrierId" BIGINT,
    "DriverCode"    VARCHAR,
    "DriverName"    VARCHAR,
    "FiscalId"      VARCHAR,
    "LicenseNumber" VARCHAR,
    "LicenseExpiry" DATE,
    "Phone"         VARCHAR,
    "IsActive"      BOOLEAN,
    "CreatedAt"     TIMESTAMP,
    "UpdatedAt"     TIMESTAMP,
    "CarrierName"   VARCHAR,
    "TotalCount"    BIGINT
) LANGUAGE plpgsql AS $$
DECLARE
    v_total BIGINT;
BEGIN
    SELECT COUNT(*) INTO v_total
    FROM logistics."Driver" d
    WHERE c."CompanyId" = p_company_id
      AND "IsDeleted" = FALSE
      AND (p_carrier_id IS NULL OR "CarrierId" = p_carrier_id)
      AND (p_search IS NULL
           OR "DriverCode" ILIKE '%' || p_search || '%'
           OR "DriverName" ILIKE '%' || p_search || '%');

    RETURN QUERY
    SELECT d."DriverId", d."CompanyId", d."CarrierId", d."DriverCode", d."DriverName",
           d."FiscalId", d."LicenseNumber", d."LicenseExpiry", d."Phone", d."IsActive",
           d."CreatedAt", d."UpdatedAt",
           c."CarrierName",
           v_total
    FROM logistics."Driver" d
    LEFT JOIN logistics."Carrier" c ON d."CarrierId" = c."CarrierId"
    WHERE d."CompanyId" = p_company_id
      AND d."IsDeleted" = FALSE
      AND (p_carrier_id IS NULL OR d."CarrierId" = p_carrier_id)
      AND (p_search IS NULL
           OR d."DriverCode" ILIKE '%' || p_search || '%'
           OR d."DriverName" ILIKE '%' || p_search || '%')
    ORDER BY d."DriverName"
    OFFSET (p_page - 1) * p_limit LIMIT p_limit;
END;
$$;

-- ============================================================================
--  SP: usp_Logistics_Driver_Upsert
-- ============================================================================
DROP FUNCTION IF EXISTS usp_Logistics_Driver_Upsert(INT, INT, INT, VARCHAR, VARCHAR, VARCHAR, VARCHAR, DATE, VARCHAR, BOOLEAN, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_Logistics_Driver_Upsert(
    p_company_id      INT,
    p_driver_id       INT             DEFAULT NULL,
    p_carrier_id      INT             DEFAULT NULL,
    p_driver_code     VARCHAR(20)     DEFAULT NULL,
    p_driver_name     VARCHAR(100)    DEFAULT NULL,
    p_fiscal_id       VARCHAR(30)     DEFAULT NULL,
    p_license_number  VARCHAR(30)     DEFAULT NULL,
    p_license_expiry  DATE            DEFAULT NULL,
    p_phone           VARCHAR(50)     DEFAULT NULL,
    p_is_active       BOOLEAN         DEFAULT TRUE,
    p_user_id         INT             DEFAULT NULL
)
RETURNS TABLE ("ok" INT, "mensaje" VARCHAR)
LANGUAGE plpgsql AS $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM logistics."Driver" d
        WHERE "CompanyId" = p_company_id AND "DriverCode" = p_driver_code
          AND "IsDeleted" = FALSE
          AND (p_driver_id IS NULL OR "DriverId" <> p_driver_id)
    ) THEN
        RETURN QUERY SELECT 0, 'El codigo de conductor ya existe'::VARCHAR;
        RETURN;
    END IF;

    IF p_driver_id IS NULL THEN
        INSERT INTO logistics."Driver" ("CompanyId", "CarrierId", "DriverCode", "DriverName",
            "FiscalId", "LicenseNumber", "LicenseExpiry", "Phone", "IsActive", "CreatedByUserId", "UpdatedByUserId", "CreatedAt", "UpdatedAt")
        VALUES (p_company_id, p_carrier_id, p_driver_code, p_driver_name,
            p_fiscal_id, p_license_number, p_license_expiry, p_phone, p_is_active, p_user_id, p_user_id, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC');

        RETURN QUERY SELECT 1, 'Conductor creado'::VARCHAR;
    ELSE
        UPDATE logistics."Driver"
        SET "CarrierId"      = p_carrier_id,
            "DriverCode"     = p_driver_code,
            "DriverName"     = p_driver_name,
            "FiscalId"       = p_fiscal_id,
            "LicenseNumber"  = p_license_number,
            "LicenseExpiry"  = p_license_expiry,
            "Phone"          = p_phone,
            "IsActive"       = p_is_active,
            "UpdatedByUserId" = p_user_id,
            "UpdatedAt"       = NOW() AT TIME ZONE 'UTC'
        WHERE "DriverId" = p_driver_id AND "CompanyId" = p_company_id;

        RETURN QUERY SELECT 1, 'Conductor actualizado'::VARCHAR;
    END IF;
END;
$$;

-- ============================================================================
--  SP: usp_Logistics_GoodsReceipt_List
-- ============================================================================
DROP FUNCTION IF EXISTS usp_Logistics_GoodsReceipt_List(INT, INT, INT, VARCHAR, DATE, DATE, INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_Logistics_GoodsReceipt_List(
    p_company_id    INT,
    p_branch_id     INT,
    p_supplier_id   INT             DEFAULT NULL,
    p_status        VARCHAR(20)     DEFAULT NULL,
    p_fecha_desde   DATE            DEFAULT NULL,
    p_fecha_hasta   DATE            DEFAULT NULL,
    p_page          INT             DEFAULT 1,
    p_limit         INT             DEFAULT 50
)
RETURNS TABLE (
    "GoodsReceiptId" BIGINT,
    "CompanyId"             INT,
    "BranchId"              INT,
    "ReceiptNumber"         VARCHAR,
    "PurchaseDocumentNumber" VARCHAR,
    "SupplierId" BIGINT,
    "WarehouseId" BIGINT,
    "ReceiptDate" DATE,
    "CarrierId" BIGINT,
    "DriverName"            VARCHAR,
    "VehiclePlate"          VARCHAR,
    "Notes"                 VARCHAR,
    "Status"                VARCHAR,
    "CreatedAt"             TIMESTAMP,
    "UpdatedAt"             TIMESTAMP,
    "CarrierName"           VARCHAR,
    "TotalCount"            BIGINT
) LANGUAGE plpgsql AS $$
DECLARE
    v_total BIGINT;
BEGIN
    SELECT COUNT(*) INTO v_total
    FROM logistics."GoodsReceipt" gr
    WHERE grt."CompanyId" = p_company_id AND grt."BranchId" = p_branch_id
      AND "IsDeleted" = FALSE
      AND (p_supplier_id IS NULL OR gr."SupplierId" = p_supplier_id)
      AND (p_status IS NULL OR "Status" = p_status)
      AND (p_fecha_desde IS NULL OR "ReceiptDate"::DATE >= p_fecha_desde)
      AND (p_fecha_hasta IS NULL OR "ReceiptDate"::DATE <= p_fecha_hasta);

    RETURN QUERY
    SELECT gr."GoodsReceiptId", gr."CompanyId", gr."BranchId", gr."ReceiptNumber",
           gr."PurchaseDocumentNumber", gr."SupplierId", gr."WarehouseId",
           gr."ReceiptDate", gr."CarrierId", gr."DriverName", gr."VehiclePlate",
           gr."Notes", gr."Status", gr."CreatedAt", gr."UpdatedAt",
           c."CarrierName",
           v_total
    FROM logistics."GoodsReceipt" gr
    LEFT JOIN logistics."Carrier" c ON gr."CarrierId" = c."CarrierId"
    WHERE grt."CompanyId" = p_company_id AND grt."BranchId" = p_branch_id
      AND gr."IsDeleted" = FALSE
      AND (p_supplier_id IS NULL OR gr."SupplierId" = p_supplier_id)
      AND (p_status IS NULL OR gr."Status" = p_status)
      AND (p_fecha_desde IS NULL OR gr."ReceiptDate"::DATE >= p_fecha_desde)
      AND (p_fecha_hasta IS NULL OR gr."ReceiptDate"::DATE <= p_fecha_hasta)
    ORDER BY gr."ReceiptDate" DESC
    OFFSET (p_page - 1) * p_limit LIMIT p_limit;
END;
$$;

-- ============================================================================
--  SP: usp_Logistics_GoodsReceipt_Get
--  PG no soporta multiples resultsets — retorna header + lines via JSON.
-- ============================================================================
DROP FUNCTION IF EXISTS usp_Logistics_GoodsReceipt_Get(INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_Logistics_GoodsReceipt_Get(
    p_goods_receipt_id INT
)
RETURNS TABLE (
    "GoodsReceiptId" BIGINT,
    "CompanyId"             INT,
    "BranchId"              INT,
    "ReceiptNumber"         VARCHAR,
    "PurchaseDocumentNumber" VARCHAR,
    "SupplierId" BIGINT,
    "WarehouseId" BIGINT,
    "ReceiptDate" DATE,
    "CarrierId" BIGINT,
    "DriverName"            VARCHAR,
    "VehiclePlate"          VARCHAR,
    "Notes"                 VARCHAR,
    "Status"                VARCHAR,
    "CreatedAt"             TIMESTAMP,
    "UpdatedAt"             TIMESTAMP,
    "CarrierName"           VARCHAR,
    "Lines"                 JSONB
) LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT gr."GoodsReceiptId", gr."CompanyId", gr."BranchId", gr."ReceiptNumber",
           gr."PurchaseDocumentNumber", gr."SupplierId", gr."WarehouseId",
           gr."ReceiptDate", gr."CarrierId", gr."DriverName", gr."VehiclePlate",
           gr."Notes", gr."Status", gr."CreatedAt", gr."UpdatedAt",
           c."CarrierName",
           COALESCE((
               SELECT jsonb_agg(jsonb_build_object(
                   'GoodsReceiptLineId', l."GoodsReceiptLineId",
                   'LineNumber', l."LineNumber",
                   'ProductId', l."ProductId",
                   'ProductCode', l."ProductCode",
                   'Description', l."Description",
                   'OrderedQuantity', l."OrderedQuantity",
                   'ReceivedQuantity', l."ReceivedQuantity",
                   'RejectedQuantity', l."RejectedQuantity",
                   'UnitCost', l."UnitCost",
                   'TotalCost', l."TotalCost",
                   'LotNumber', l."LotNumber",
                   'ExpiryDate', l."ExpiryDate",
                   'WarehouseId', l."WarehouseId",
                   'BinId', l."BinId",
                   'InspectionStatus', l."InspectionStatus",
                   'Notes', l."Notes"
               ) ORDER BY l."LineNumber")
               FROM logistics."GoodsReceiptLine" l
               WHERE l."GoodsReceiptId" = gr."GoodsReceiptId"
           ), '[]'::JSONB)
    FROM logistics."GoodsReceipt" gr
    LEFT JOIN logistics."Carrier" c ON gr."CarrierId" = c."CarrierId"
    WHERE gr."GoodsReceiptId" = p_goods_receipt_id AND gr."IsDeleted" = FALSE;
END;
$$;

-- ============================================================================
--  SP: usp_Logistics_GoodsReceipt_Create
-- ============================================================================
DROP FUNCTION IF EXISTS usp_Logistics_GoodsReceipt_Create(INT, INT, VARCHAR, INT, INT, TIMESTAMP, INT, VARCHAR, VARCHAR, VARCHAR, TEXT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_Logistics_GoodsReceipt_Create(
    p_company_id              INT,
    p_branch_id               INT,
    p_purchase_document_number VARCHAR(30)    DEFAULT NULL,
    p_supplier_id             INT             DEFAULT NULL,
    p_warehouse_id            INT             DEFAULT NULL,
    p_receipt_date            TIMESTAMP       DEFAULT NULL,
    p_carrier_id              INT             DEFAULT NULL,
    p_driver_name             VARCHAR(100)    DEFAULT NULL,
    p_vehicle_plate           VARCHAR(20)     DEFAULT NULL,
    p_notes                   VARCHAR(500)    DEFAULT NULL,
    p_lines_json              TEXT            DEFAULT '[]',
    p_user_id                 INT             DEFAULT NULL
)
RETURNS TABLE ("ok" INT, "mensaje" VARCHAR, "GoodsReceiptId" BIGINT, "ReceiptNumber" VARCHAR)
LANGUAGE plpgsql AS $$
DECLARE
    v_receipt_number VARCHAR(20);
    v_new_id INT;
    v_seq INT;
    v_line JSONB;
BEGIN
    SELECT COALESCE(MAX(CAST(RIGHT("ReceiptNumber", 8) AS INT)), 0) + 1
    INTO v_seq
    FROM logistics."GoodsReceipt" gr
    WHERE c."CompanyId" = p_company_id;

    v_receipt_number := 'REC-' || LPAD(v_seq::TEXT, 8, '0');

    INSERT INTO logistics."GoodsReceipt" ("CompanyId", "BranchId", "ReceiptNumber",
        "PurchaseDocumentNumber", "SupplierId", "WarehouseId", "ReceiptDate",
        "CarrierId", "DriverName", "VehiclePlate", "Notes",
        "Status", "CreatedByUserId", "UpdatedByUserId", "CreatedAt", "UpdatedAt")
    VALUES (p_company_id, p_branch_id, v_receipt_number,
        p_purchase_document_number, p_supplier_id, p_warehouse_id, p_receipt_date,
        p_carrier_id, p_driver_name, p_vehicle_plate, p_notes,
        'DRAFT', p_user_id, p_user_id, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC')
    RETURNING "GoodsReceiptId" INTO v_new_id;

    FOR v_line IN SELECT * FROM jsonb_array_elements(p_lines_json::JSONB)
    LOOP
        INSERT INTO logistics."GoodsReceiptLine" ("GoodsReceiptId", "LineNumber", "ProductId",
            "ProductCode", "Description", "OrderedQuantity", "ReceivedQuantity", "RejectedQuantity",
            "UnitCost", "TotalCost", "LotNumber", "ExpiryDate", "WarehouseId", "BinId",
            "InspectionStatus", "Notes", "CreatedByUserId", "CreatedAt")
        VALUES (v_new_id,
            COALESCE((v_line->>'LineNumber')::INT, 0),
            (v_line->>'ProductId')::INT,
            v_line->>'ProductCode',
            v_line->>'Description',
            COALESCE((v_line->>'OrderedQuantity')::DECIMAL, 0),
            COALESCE((v_line->>'ReceivedQuantity')::DECIMAL, 0),
            COALESCE((v_line->>'RejectedQuantity')::DECIMAL, 0),
            (v_line->>'UnitCost')::DECIMAL,
            (v_line->>'TotalCost')::DECIMAL,
            v_line->>'LotNumber',
            (v_line->>'ExpiryDate')::DATE,
            (v_line->>'WarehouseId')::INT,
            (v_line->>'BinId')::INT,
            v_line->>'InspectionStatus',
            v_line->>'Notes',
            p_user_id,
            NOW() AT TIME ZONE 'UTC');
    END LOOP;

    RETURN QUERY SELECT 1, 'Recepcion creada'::VARCHAR, v_new_id, v_receipt_number;
END;
$$;

-- ============================================================================
--  SP: usp_Logistics_GoodsReceipt_Approve
-- ============================================================================
DROP FUNCTION IF EXISTS usp_Logistics_GoodsReceipt_Approve(INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_Logistics_GoodsReceipt_Approve(
    p_goods_receipt_id INT,
    p_user_id          INT DEFAULT NULL
)
RETURNS TABLE ("ok" INT, "mensaje" VARCHAR)
LANGUAGE plpgsql AS $$
DECLARE
    v_company_id INT;
    v_branch_id INT;
    v_warehouse_id INT;
    v_receipt_number VARCHAR(20);
BEGIN
    SELECT "CompanyId", "BranchId", "WarehouseId", "ReceiptNumber"
    INTO v_company_id, v_branch_id, v_warehouse_id, v_receipt_number
    FROM logistics."GoodsReceipt" gr
    WHERE "GoodsReceiptId" = p_goods_receipt_id AND "Status" = 'DRAFT';

    IF v_company_id IS NULL THEN
        RETURN QUERY SELECT 0, 'Recepcion no encontrada o ya aprobada'::VARCHAR;
        RETURN;
    END IF;

    UPDATE logistics."GoodsReceipt"
    SET "Status" = 'COMPLETE', "UpdatedByUserId" = p_user_id, "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
    WHERE "GoodsReceiptId" = p_goods_receipt_id;

    INSERT INTO inv."StockMovement" ("CompanyId", "BranchId", "ProductId", "ToWarehouseId", "ToBinId",
        "MovementType", "Quantity", "UnitCost", "SourceDocumentType", "SourceDocumentNumber",
        "CreatedByUserId", "CreatedAt")
    SELECT v_company_id, v_branch_id, l."ProductId", v_warehouse_id, l."BinId",
           'PURCHASE_IN', l."ReceivedQuantity", l."UnitCost", 'GOODS_RECEIPT',
           v_receipt_number, p_user_id, NOW() AT TIME ZONE 'UTC'
    FROM logistics."GoodsReceiptLine" l
    WHERE l."GoodsReceiptId" = p_goods_receipt_id AND l."ReceivedQuantity" > 0;

    RETURN QUERY SELECT 1, 'Recepcion aprobada y movimientos de inventario generados'::VARCHAR;
END;
$$;

-- ============================================================================
--  SP: usp_Logistics_GoodsReturn_List
-- ============================================================================
DROP FUNCTION IF EXISTS usp_Logistics_GoodsReturn_List(INT, INT, VARCHAR, INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_Logistics_GoodsReturn_List(
    p_company_id    INT,
    p_branch_id     INT,
    p_status        VARCHAR(20)     DEFAULT NULL,
    p_page          INT             DEFAULT 1,
    p_limit         INT             DEFAULT 50
)
RETURNS TABLE (
    "GoodsReturnId" BIGINT,
    "CompanyId"         INT,
    "BranchId"          INT,
    "ReturnNumber"      VARCHAR,
    "GoodsReceiptId" BIGINT,
    "SupplierId" BIGINT,
    "WarehouseId" BIGINT,
    "ReturnDate" DATE,
    "Reason"            VARCHAR,
    "Status"            VARCHAR,
    "Notes"             VARCHAR,
    "CreatedAt"         TIMESTAMP,
    "UpdatedAt"         TIMESTAMP,
    "TotalCount"        BIGINT
) LANGUAGE plpgsql AS $$
DECLARE
    v_total BIGINT;
BEGIN
    SELECT COUNT(*) INTO v_total
    FROM logistics."GoodsReturn" grt
    WHERE grt."CompanyId" = p_company_id AND grt."BranchId" = p_branch_id
      AND "IsDeleted" = FALSE
      AND (p_status IS NULL OR "Status" = p_status);

    RETURN QUERY
    SELECT r."GoodsReturnId", r."CompanyId", r."BranchId", r."ReturnNumber",
           r."GoodsReceiptId", r."SupplierId", r."WarehouseId", r."ReturnDate",
           r."Reason", r."Status", r."Notes", r."CreatedAt", r."UpdatedAt",
           v_total
    FROM logistics."GoodsReturn" r
    WHERE r."CompanyId" = p_company_id AND r."BranchId" = p_branch_id
      AND r."IsDeleted" = FALSE
      AND (p_status IS NULL OR r."Status" = p_status)
    ORDER BY r."ReturnDate" DESC
    OFFSET (p_page - 1) * p_limit LIMIT p_limit;
END;
$$;

-- ============================================================================
--  SP: usp_Logistics_GoodsReturn_Create
-- ============================================================================
DROP FUNCTION IF EXISTS usp_Logistics_GoodsReturn_Create(INT, INT, INT, INT, INT, TIMESTAMP, VARCHAR, TEXT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_Logistics_GoodsReturn_Create(
    p_company_id      INT,
    p_branch_id       INT,
    p_goods_receipt_id INT            DEFAULT NULL,
    p_supplier_id     INT             DEFAULT NULL,
    p_warehouse_id    INT             DEFAULT NULL,
    p_return_date     TIMESTAMP       DEFAULT NULL,
    p_reason          VARCHAR(250)    DEFAULT NULL,
    p_lines_json      TEXT            DEFAULT '[]',
    p_user_id         INT             DEFAULT NULL
)
RETURNS TABLE ("ok" INT, "mensaje" VARCHAR, "ReturnNumber" VARCHAR)
LANGUAGE plpgsql AS $$
DECLARE
    v_return_number VARCHAR(20);
    v_new_id INT;
    v_seq INT;
    v_line JSONB;
BEGIN
    SELECT COALESCE(MAX(CAST(RIGHT("ReturnNumber", 8) AS INT)), 0) + 1
    INTO v_seq
    FROM logistics."GoodsReturn" grt
    WHERE c."CompanyId" = p_company_id;

    v_return_number := 'DEV-' || LPAD(v_seq::TEXT, 8, '0');

    INSERT INTO logistics."GoodsReturn" ("CompanyId", "BranchId", "ReturnNumber",
        "GoodsReceiptId", "SupplierId", "WarehouseId", "ReturnDate", "Reason",
        "Status", "CreatedByUserId", "UpdatedByUserId", "CreatedAt", "UpdatedAt")
    VALUES (p_company_id, p_branch_id, v_return_number,
        p_goods_receipt_id, p_supplier_id, p_warehouse_id, p_return_date, p_reason,
        'DRAFT', p_user_id, p_user_id, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC')
    RETURNING "GoodsReturnId" INTO v_new_id;

    FOR v_line IN SELECT * FROM jsonb_array_elements(p_lines_json::JSONB)
    LOOP
        INSERT INTO logistics."GoodsReturnLine" ("GoodsReturnId", "ProductId",
            "Quantity", "UnitCost", "LotNumber", "SerialNumber", "Notes")
        VALUES (v_new_id,
            (v_line->>'ProductId')::INT,
            COALESCE((v_line->>'Quantity')::DECIMAL, 0),
            (v_line->>'UnitCost')::DECIMAL,
            v_line->>'LotNumber',
            v_line->>'SerialNumber',
            v_line->>'Notes');
    END LOOP;

    RETURN QUERY SELECT 1, 'Devolucion creada'::VARCHAR, v_return_number;
END;
$$;

-- ============================================================================
--  SP: usp_Logistics_GoodsReturn_Approve
-- ============================================================================
DROP FUNCTION IF EXISTS usp_Logistics_GoodsReturn_Approve(INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_Logistics_GoodsReturn_Approve(
    p_goods_return_id INT,
    p_user_id         INT DEFAULT NULL
)
RETURNS TABLE ("ok" INT, "mensaje" VARCHAR)
LANGUAGE plpgsql AS $$
DECLARE
    v_company_id INT;
    v_branch_id INT;
    v_warehouse_id INT;
    v_return_number VARCHAR(20);
BEGIN
    SELECT "CompanyId", "BranchId", "WarehouseId", "ReturnNumber"
    INTO v_company_id, v_branch_id, v_warehouse_id, v_return_number
    FROM logistics."GoodsReturn" grt
    WHERE "GoodsReturnId" = p_goods_return_id AND "Status" = 'DRAFT';

    IF v_company_id IS NULL THEN
        RETURN QUERY SELECT 0, 'Devolucion no encontrada o ya aprobada'::VARCHAR;
        RETURN;
    END IF;

    UPDATE logistics."GoodsReturn"
    SET "Status" = 'COMPLETE', "UpdatedByUserId" = p_user_id, "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
    WHERE "GoodsReturnId" = p_goods_return_id;

    INSERT INTO inv."StockMovement" ("CompanyId", "BranchId", "ProductId", "FromWarehouseId",
        "MovementType", "Quantity", "UnitCost", "SourceDocumentType", "SourceDocumentNumber",
        "CreatedByUserId", "CreatedAt")
    SELECT v_company_id, v_branch_id, l."ProductId", v_warehouse_id,
           'RETURN_OUT', l."Quantity", l."UnitCost", 'GOODS_RETURN',
           v_return_number, p_user_id, NOW() AT TIME ZONE 'UTC'
    FROM logistics."GoodsReturnLine" l
    WHERE l."GoodsReturnId" = p_goods_return_id AND l."Quantity" > 0;

    RETURN QUERY SELECT 1, 'Devolucion aprobada y movimientos de inventario generados'::VARCHAR;
END;
$$;

-- ============================================================================
--  SP: usp_Logistics_DeliveryNote_List
-- ============================================================================
DROP FUNCTION IF EXISTS usp_Logistics_DeliveryNote_List(INT, INT, INT, VARCHAR, DATE, DATE, INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_Logistics_DeliveryNote_List(
    p_company_id    INT,
    p_branch_id     INT,
    p_customer_id   INT             DEFAULT NULL,
    p_status        VARCHAR(20)     DEFAULT NULL,
    p_fecha_desde   DATE            DEFAULT NULL,
    p_fecha_hasta   DATE            DEFAULT NULL,
    p_page          INT             DEFAULT 1,
    p_limit         INT             DEFAULT 50
)
RETURNS TABLE (
    "DeliveryNoteId" BIGINT,
    "CompanyId"             INT,
    "BranchId"              INT,
    "DeliveryNumber"        VARCHAR,
    "SalesDocumentNumber"   VARCHAR,
    "CustomerId" BIGINT,
    "WarehouseId" BIGINT,
    "DeliveryDate" DATE,
    "CarrierId" BIGINT,
    "DriverId" BIGINT,
    "VehiclePlate"          VARCHAR,
    "ShipToAddress"         VARCHAR,
    "ShipToContact"         VARCHAR,
    "EstimatedDelivery" DATE,
    "ActualDelivery" DATE,
    "Status"                VARCHAR,
    "DeliveredToName"       VARCHAR,
    "CreatedAt"             TIMESTAMP,
    "UpdatedAt"             TIMESTAMP,
    "CarrierName"           VARCHAR,
    "DriverName"            VARCHAR,
    "TotalCount"            BIGINT
) LANGUAGE plpgsql AS $$
DECLARE
    v_total BIGINT;
BEGIN
    SELECT COUNT(*) INTO v_total
    FROM logistics."DeliveryNote" dn
    WHERE grt."CompanyId" = p_company_id AND grt."BranchId" = p_branch_id
      AND "IsDeleted" = FALSE
      AND (p_customer_id IS NULL OR "CustomerId" = p_customer_id)
      AND (p_status IS NULL OR "Status" = p_status)
      AND (p_fecha_desde IS NULL OR "DeliveryDate"::DATE >= p_fecha_desde)
      AND (p_fecha_hasta IS NULL OR "DeliveryDate"::DATE <= p_fecha_hasta);

    RETURN QUERY
    SELECT dn."DeliveryNoteId", dn."CompanyId", dn."BranchId", dn."DeliveryNumber",
           dn."SalesDocumentNumber", dn."CustomerId", dn."WarehouseId",
           dn."DeliveryDate", dn."CarrierId", dn."DriverId", dn."VehiclePlate",
           dn."ShipToAddress", dn."ShipToContact", dn."EstimatedDelivery",
           dn."ActualDelivery",
           dn."Status", dn."DeliveredToName", dn."CreatedAt", dn."UpdatedAt",
           c."CarrierName", d."DriverName",
           v_total
    FROM logistics."DeliveryNote" dn
    LEFT JOIN logistics."Carrier" c ON dn."CarrierId" = c."CarrierId"
    LEFT JOIN logistics."Driver" d ON dn."DriverId" = d."DriverId"
    WHERE dn."CompanyId" = p_company_id AND dn."BranchId" = p_branch_id
      AND dn."IsDeleted" = FALSE
      AND (p_customer_id IS NULL OR dn."CustomerId" = p_customer_id)
      AND (p_status IS NULL OR dn."Status" = p_status)
      AND (p_fecha_desde IS NULL OR dn."DeliveryDate"::DATE >= p_fecha_desde)
      AND (p_fecha_hasta IS NULL OR dn."DeliveryDate"::DATE <= p_fecha_hasta)
    ORDER BY dn."DeliveryDate" DESC
    OFFSET (p_page - 1) * p_limit LIMIT p_limit;
END;
$$;

-- ============================================================================
--  SP: usp_Logistics_DeliveryNote_Get
-- ============================================================================
DROP FUNCTION IF EXISTS usp_Logistics_DeliveryNote_Get(INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_Logistics_DeliveryNote_Get(
    p_delivery_note_id INT
)
RETURNS TABLE (
    "DeliveryNoteId" BIGINT,
    "CompanyId"             INT,
    "BranchId"              INT,
    "DeliveryNumber"        VARCHAR,
    "SalesDocumentNumber"   VARCHAR,
    "CustomerId" BIGINT,
    "WarehouseId" BIGINT,
    "DeliveryDate" DATE,
    "CarrierId" BIGINT,
    "DriverId" BIGINT,
    "VehiclePlate"          VARCHAR,
    "ShipToAddress"         VARCHAR,
    "ShipToContact"         VARCHAR,
    "EstimatedDelivery" DATE,
    "ActualDelivery" DATE,
    "Status"                VARCHAR,
    "DeliveredToName"       VARCHAR,
    "DeliverySignature"     TEXT,
    "Notes"                 VARCHAR,
    "CreatedAt"             TIMESTAMP,
    "UpdatedAt"             TIMESTAMP,
    "CarrierName"           VARCHAR,
    "DriverName"            VARCHAR,
    "Lines"                 JSONB,
    "Serials"               JSONB
) LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT dn."DeliveryNoteId", dn."CompanyId", dn."BranchId", dn."DeliveryNumber",
           dn."SalesDocumentNumber", dn."CustomerId", dn."WarehouseId",
           dn."DeliveryDate", dn."CarrierId", dn."DriverId", dn."VehiclePlate",
           dn."ShipToAddress", dn."ShipToContact", dn."EstimatedDelivery",
           dn."ActualDelivery",
           dn."Status", dn."DeliveredToName", dn."DeliverySignature",
           dn."Notes",
           dn."CreatedAt", dn."UpdatedAt",
           c."CarrierName", d."DriverName",
           COALESCE((
               SELECT jsonb_agg(jsonb_build_object(
                   'LineId', l."LineId",
                   'ProductId', l."ProductId",
                   'Quantity', l."Quantity",
                   'UnitCost', l."UnitCost",
                   'LotNumber', l."LotNumber",
                   'BinId', l."BinId",
                   'Notes', l."Notes"
               ) ORDER BY l."LineId")
               FROM logistics."DeliveryNoteLine" l
               WHERE l."DeliveryNoteId" = dn."DeliveryNoteId"
           ), '[]'::JSONB),
           COALESCE((
               SELECT jsonb_agg(jsonb_build_object(
                   'Id', s."Id",
                   'LineId', s."LineId",
                   'SerialNumber', s."SerialNumber"
               ))
               FROM logistics."DeliveryNoteSerial" s
               INNER JOIN logistics."DeliveryNoteLine" l2 ON s."LineId" = l2."LineId"
               WHERE l2."DeliveryNoteId" = dn."DeliveryNoteId"
           ), '[]'::JSONB)
    FROM logistics."DeliveryNote" dn
    LEFT JOIN logistics."Carrier" c ON dn."CarrierId" = c."CarrierId"
    LEFT JOIN logistics."Driver" d ON dn."DriverId" = d."DriverId"
    WHERE dn."DeliveryNoteId" = p_delivery_note_id AND dn."IsDeleted" = FALSE;
END;
$$;

-- ============================================================================
--  SP: usp_Logistics_DeliveryNote_Create
-- ============================================================================
DROP FUNCTION IF EXISTS usp_Logistics_DeliveryNote_Create(INT, INT, VARCHAR, INT, INT, TIMESTAMP, INT, INT, VARCHAR, VARCHAR, VARCHAR, TIMESTAMP, TEXT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_Logistics_DeliveryNote_Create(
    p_company_id            INT,
    p_branch_id             INT,
    p_sales_document_number VARCHAR(30)     DEFAULT NULL,
    p_customer_id           INT             DEFAULT NULL,
    p_warehouse_id          INT             DEFAULT NULL,
    p_delivery_date         TIMESTAMP       DEFAULT NULL,
    p_carrier_id            INT             DEFAULT NULL,
    p_driver_id             INT             DEFAULT NULL,
    p_vehicle_plate         VARCHAR(20)     DEFAULT NULL,
    p_ship_to_address       VARCHAR(500)    DEFAULT NULL,
    p_ship_to_contact       VARCHAR(100)    DEFAULT NULL,
    p_estimated_delivery    TIMESTAMP       DEFAULT NULL,
    p_lines_json            TEXT            DEFAULT '[]',
    p_user_id               INT             DEFAULT NULL
)
RETURNS TABLE ("ok" INT, "mensaje" VARCHAR, "DeliveryNoteId" BIGINT, "DeliveryNumber" VARCHAR)
LANGUAGE plpgsql AS $$
DECLARE
    v_delivery_number VARCHAR(20);
    v_new_id INT;
    v_seq INT;
    v_line JSONB;
BEGIN
    SELECT COALESCE(MAX(CAST(RIGHT("DeliveryNumber", 8) AS INT)), 0) + 1
    INTO v_seq
    FROM logistics."DeliveryNote" dn
    WHERE c."CompanyId" = p_company_id;

    v_delivery_number := 'NDE-' || LPAD(v_seq::TEXT, 8, '0');

    INSERT INTO logistics."DeliveryNote" ("CompanyId", "BranchId", "DeliveryNumber",
        "SalesDocumentNumber", "CustomerId", "WarehouseId", "DeliveryDate",
        "CarrierId", "DriverId", "VehiclePlate",
        "ShipToAddress", "ShipToContact", "EstimatedDelivery",
        "Status", "CreatedByUserId", "UpdatedByUserId", "CreatedAt", "UpdatedAt")
    VALUES (p_company_id, p_branch_id, v_delivery_number,
        p_sales_document_number, p_customer_id, p_warehouse_id, p_delivery_date,
        p_carrier_id, p_driver_id, p_vehicle_plate,
        p_ship_to_address, p_ship_to_contact, p_estimated_delivery,
        'DRAFT', p_user_id, p_user_id, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC')
    RETURNING "DeliveryNoteId" INTO v_new_id;

    FOR v_line IN SELECT * FROM jsonb_array_elements(p_lines_json::JSONB)
    LOOP
        INSERT INTO logistics."DeliveryNoteLine" ("DeliveryNoteId", "ProductId",
            "Quantity", "UnitCost", "LotNumber", "BinId", "Notes")
        VALUES (v_new_id,
            (v_line->>'ProductId')::INT,
            COALESCE((v_line->>'Quantity')::DECIMAL, 0),
            (v_line->>'UnitCost')::DECIMAL,
            v_line->>'LotNumber',
            (v_line->>'BinId')::INT,
            v_line->>'Notes');
    END LOOP;

    RETURN QUERY SELECT 1, 'Nota de entrega creada'::VARCHAR, v_new_id, v_delivery_number;
END;
$$;

-- ============================================================================
--  SP: usp_Logistics_DeliveryNote_Dispatch
-- ============================================================================
DROP FUNCTION IF EXISTS usp_Logistics_DeliveryNote_Dispatch(INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_Logistics_DeliveryNote_Dispatch(
    p_delivery_note_id INT,
    p_user_id          INT DEFAULT NULL
)
RETURNS TABLE ("ok" INT, "mensaje" VARCHAR)
LANGUAGE plpgsql AS $$
DECLARE
    v_company_id INT;
    v_branch_id INT;
    v_warehouse_id INT;
    v_delivery_number VARCHAR(20);
BEGIN
    SELECT "CompanyId", "BranchId", "WarehouseId", "DeliveryNumber"
    INTO v_company_id, v_branch_id, v_warehouse_id, v_delivery_number
    FROM logistics."DeliveryNote" dn
    WHERE "DeliveryNoteId" = p_delivery_note_id AND "Status" = 'DRAFT';

    IF v_company_id IS NULL THEN
        RETURN QUERY SELECT 0, 'Nota de entrega no encontrada o no esta en borrador'::VARCHAR;
        RETURN;
    END IF;

    UPDATE logistics."DeliveryNote"
    SET "Status" = 'DISPATCHED', "DispatchedByUserId" = p_user_id, "UpdatedByUserId" = p_user_id, "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
    WHERE "DeliveryNoteId" = p_delivery_note_id;

    INSERT INTO inv."StockMovement" ("CompanyId", "BranchId", "ProductId", "FromWarehouseId", "FromBinId",
        "MovementType", "Quantity", "UnitCost", "SourceDocumentType", "SourceDocumentNumber",
        "CreatedByUserId", "CreatedAt")
    SELECT v_company_id, v_branch_id, l."ProductId", v_warehouse_id, l."BinId",
           'SALE_OUT', l."Quantity", l."UnitCost", 'DELIVERY_NOTE',
           v_delivery_number, p_user_id, NOW() AT TIME ZONE 'UTC'
    FROM logistics."DeliveryNoteLine" l
    WHERE l."DeliveryNoteId" = p_delivery_note_id AND l."Quantity" > 0;

    RETURN QUERY SELECT 1, 'Nota de entrega despachada y movimientos de inventario generados'::VARCHAR;
END;
$$;

-- ============================================================================
--  SP: usp_Logistics_DeliveryNote_Deliver
-- ============================================================================
DROP FUNCTION IF EXISTS usp_Logistics_DeliveryNote_Deliver(INT, VARCHAR, TEXT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_Logistics_DeliveryNote_Deliver(
    p_delivery_note_id  INT,
    p_delivered_to_name VARCHAR(100)    DEFAULT NULL,
    p_delivery_signature TEXT           DEFAULT NULL,
    p_user_id           INT             DEFAULT NULL
)
RETURNS TABLE ("ok" INT, "mensaje" VARCHAR)
LANGUAGE plpgsql AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM logistics."DeliveryNote" dn
        WHERE "DeliveryNoteId" = p_delivery_note_id AND "Status" = 'DISPATCHED'
    ) THEN
        RETURN QUERY SELECT 0, 'Nota de entrega no encontrada o no esta despachada'::VARCHAR;
        RETURN;
    END IF;

    UPDATE logistics."DeliveryNote"
    SET "Status" = 'DELIVERED',
        "DeliveredToName" = p_delivered_to_name,
        "DeliverySignature" = p_delivery_signature,
        "ActualDelivery" = NOW() AT TIME ZONE 'UTC',
        "UpdatedByUserId" = p_user_id,
        "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
    WHERE "DeliveryNoteId" = p_delivery_note_id;

    RETURN QUERY SELECT 1, 'Entrega confirmada'::VARCHAR;
END;
$$;
