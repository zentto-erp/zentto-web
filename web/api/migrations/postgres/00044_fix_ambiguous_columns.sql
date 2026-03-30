-- +goose Up
-- Fix columnas ambiguas en SPs fiscales, inventario avanzado e inflacion
-- + Fix firma usp_tipos_list (tabla legacy → canonical)

-- usp_Fiscal_Declaration_List: agregar alias d. a fiscal.TaxDeclaration
-- +goose StatementBegin
DROP FUNCTION IF EXISTS usp_Fiscal_Declaration_List(INTEGER, VARCHAR(30), INTEGER, VARCHAR(20), INTEGER, INTEGER) CASCADE;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION usp_Fiscal_Declaration_List(
    p_company_id       INTEGER,
    p_declaration_type VARCHAR(30) DEFAULT NULL,
    p_year             INTEGER     DEFAULT NULL,
    p_status           VARCHAR(20) DEFAULT NULL,
    p_page             INTEGER     DEFAULT 1,
    p_limit            INTEGER     DEFAULT 50
)
RETURNS TABLE(
    p_total_count        BIGINT,
    "DeclarationId"      BIGINT,
    "CompanyId"          INTEGER,
    "BranchId"           INTEGER,
    "CountryCode"        VARCHAR(2),
    "DeclarationType"    VARCHAR(30),
    "PeriodCode"         VARCHAR(7),
    "PeriodStart"        DATE,
    "PeriodEnd"          DATE,
    "SalesBase"          NUMERIC(18,2),
    "SalesTax"           NUMERIC(18,2),
    "PurchasesBase"      NUMERIC(18,2),
    "PurchasesTax"       NUMERIC(18,2),
    "TaxableBase"        NUMERIC(18,2),
    "TaxAmount"          NUMERIC(18,2),
    "WithholdingsCredit" NUMERIC(18,2),
    "PreviousBalance"    NUMERIC(18,2),
    "NetPayable"         NUMERIC(18,2),
    "Status"             VARCHAR(20),
    "SubmittedAt"        TIMESTAMP,
    "SubmittedFile"      VARCHAR(500),
    "AuthorityResponse"  TEXT,
    "PaidAt"             TIMESTAMP,
    "PaymentReference"   VARCHAR(100),
    "JournalEntryId"     BIGINT,
    "Notes"              VARCHAR(1000),
    "CreatedBy"          VARCHAR(40),
    "UpdatedBy"          VARCHAR(40),
    "CreatedAt"          TIMESTAMP,
    "UpdatedAt"          TIMESTAMP
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_page  < 1   THEN p_page  := 1;  END IF;
    IF p_limit < 1   THEN p_limit := 50; END IF;
    IF p_limit > 500 THEN p_limit := 500; END IF;

    RETURN QUERY
    SELECT COUNT(*) OVER()  AS p_total_count,
           d."DeclarationId", d."CompanyId", d."BranchId", d."CountryCode",
           d."DeclarationType", d."PeriodCode", d."PeriodStart", d."PeriodEnd",
           d."SalesBase", d."SalesTax", d."PurchasesBase", d."PurchasesTax",
           d."TaxableBase", d."TaxAmount", d."WithholdingsCredit",
           d."PreviousBalance", d."NetPayable", d."Status",
           d."SubmittedAt", d."SubmittedFile", d."AuthorityResponse",
           d."PaidAt", d."PaymentReference", d."JournalEntryId", d."Notes",
           d."CreatedBy", d."UpdatedBy", d."CreatedAt", d."UpdatedAt"
    FROM fiscal."TaxDeclaration" d
    WHERE d."CompanyId" = p_company_id
      AND (p_declaration_type IS NULL OR d."DeclarationType" = p_declaration_type)
      AND (p_year IS NULL OR LEFT(d."PeriodCode", 4) = CAST(p_year AS VARCHAR(4)))
      AND (p_status IS NULL OR d."Status" = p_status)
    ORDER BY d."PeriodCode" DESC
    LIMIT p_limit OFFSET (p_page - 1) * p_limit;
END;
$$;
-- +goose StatementEnd

-- +goose StatementBegin
DROP FUNCTION IF EXISTS usp_Fiscal_Withholding_List(INTEGER, VARCHAR(20), VARCHAR(7), VARCHAR(2), INTEGER, INTEGER) CASCADE;
-- +goose StatementEnd
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION usp_Fiscal_Withholding_List(
    p_company_id       INTEGER,
    p_withholding_type VARCHAR(20) DEFAULT NULL,
    p_period_code      VARCHAR(7)  DEFAULT NULL,
    p_country_code     VARCHAR(2)  DEFAULT NULL,
    p_page             INTEGER     DEFAULT 1,
    p_limit            INTEGER     DEFAULT 50
)
RETURNS TABLE(
    p_total_count       BIGINT,
    "VoucherId"         BIGINT,
    "CompanyId"         INTEGER,
    "VoucherNumber"     VARCHAR(40),
    "VoucherDate"       DATE,
    "WithholdingType"   VARCHAR(20),
    "ThirdPartyId"      VARCHAR(40),
    "ThirdPartyName"    VARCHAR(200),
    "DocumentNumber"    VARCHAR(60),
    "DocumentDate"      DATE,
    "TaxableBase"       NUMERIC(18,2),
    "WithholdingRate"   NUMERIC(5,2),
    "WithholdingAmount" NUMERIC(18,2),
    "PeriodCode"        VARCHAR(7),
    "Status"            VARCHAR(20),
    "CountryCode"       VARCHAR(2),
    "JournalEntryId"    BIGINT,
    "CreatedBy"         VARCHAR(40),
    "CreatedAt"         TIMESTAMP
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_page  < 1   THEN p_page  := 1;  END IF;
    IF p_limit < 1   THEN p_limit := 50; END IF;
    IF p_limit > 500 THEN p_limit := 500; END IF;

    RETURN QUERY
    SELECT COUNT(*) OVER()  AS p_total_count,
           v."VoucherId", v."CompanyId", v."VoucherNumber", v."VoucherDate",
           v."WithholdingType", v."ThirdPartyId", v."ThirdPartyName",
           v."DocumentNumber", v."DocumentDate", v."TaxableBase",
           v."WithholdingRate", v."WithholdingAmount", v."PeriodCode",
           v."Status", v."CountryCode", v."JournalEntryId",
           v."CreatedBy", v."CreatedAt"
    FROM fiscal."WithholdingVoucher" v
    WHERE v."CompanyId" = p_company_id
      AND (p_withholding_type IS NULL OR v."WithholdingType" = p_withholding_type)
      AND (p_period_code      IS NULL OR v."PeriodCode"      = p_period_code)
      AND (p_country_code     IS NULL OR v."CountryCode"     = p_country_code)
    ORDER BY v."VoucherDate" DESC
    LIMIT p_limit OFFSET (p_page - 1) * p_limit;
END;
$$;
-- +goose StatementEnd

-- +goose StatementBegin
DROP FUNCTION IF EXISTS usp_Acct_InflationIndex_List(INTEGER, CHAR(2), VARCHAR(30), SMALLINT, SMALLINT) CASCADE;
-- +goose StatementEnd
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION usp_Acct_InflationIndex_List(
    p_company_id   INTEGER,
    p_country_code CHAR(2)      DEFAULT 'VE',
    p_index_name   VARCHAR(30)  DEFAULT 'INPC',
    p_year_from    SMALLINT     DEFAULT NULL,
    p_year_to      SMALLINT     DEFAULT NULL
)
RETURNS TABLE(
    p_total_count      BIGINT,
    "InflationIndexId" INTEGER,
    "CountryCode"      CHAR(2),
    "IndexName"        VARCHAR(30),
    "PeriodCode"       CHAR(6),
    "IndexValue"       NUMERIC(18,6),
    "SourceReference"  VARCHAR(200),
    "CreatedAt"        TIMESTAMP,
    "UpdatedAt"        TIMESTAMP
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT COUNT(*) OVER()          AS p_total_count,
           i."InflationIndexId",
           i."CountryCode",
           i."IndexName",
           i."PeriodCode",
           i."IndexValue",
           i."SourceReference",
           i."CreatedAt",
           i."UpdatedAt"
    FROM acct."InflationIndex" i
    WHERE i."CompanyId"   = p_company_id
      AND i."CountryCode" = p_country_code
      AND i."IndexName"   = p_index_name
      AND (p_year_from IS NULL OR CAST(LEFT(i."PeriodCode", 4) AS SMALLINT) >= p_year_from)
      AND (p_year_to   IS NULL OR CAST(LEFT(i."PeriodCode", 4) AS SMALLINT) <= p_year_to)
    ORDER BY i."PeriodCode";
END;
$$;
-- +goose StatementEnd

-- +goose StatementBegin
DROP FUNCTION IF EXISTS usp_Inv_Serial_List(INT, BIGINT, VARCHAR(20), VARCHAR(100), INT, INT) CASCADE;
-- +goose StatementEnd
-- +goose StatementBegin
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
-- +goose StatementEnd

-- +goose StatementBegin
DROP FUNCTION IF EXISTS usp_Inv_Lot_List(INT, BIGINT, VARCHAR(20), INT, INT) CASCADE;
-- +goose StatementEnd
-- +goose StatementBegin
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
-- +goose StatementEnd

-- +goose StatementBegin
-- +goose StatementEnd
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION usp_tipos_list(
    p_company_id INT          DEFAULT 1,
    p_search     VARCHAR(100) DEFAULT NULL,
    p_categoria  VARCHAR(50)  DEFAULT NULL,
    p_page       INT          DEFAULT 1,
    p_limit      INT          DEFAULT 50
)
RETURNS TABLE(
    "Codigo"     INT,
    "Nombre"     VARCHAR(100),
    "Categoria"  VARCHAR(50),
    "Co_Usuario" VARCHAR(10),
    "TotalCount" BIGINT
)
LANGUAGE plpgsql AS $$
DECLARE
    v_offset INT;
    v_total  BIGINT;
BEGIN
    v_offset := (COALESCE(NULLIF(p_page, 0), 1) - 1) * COALESCE(NULLIF(p_limit, 0), 50);
    IF v_offset < 0  THEN v_offset := 0;   END IF;
    IF p_limit  < 1  THEN p_limit  := 50;  END IF;
    IF p_limit  > 500 THEN p_limit := 500; END IF;

    SELECT COUNT(1) INTO v_total
    FROM master."ProductType" tc
    WHERE tc."IsDeleted" = FALSE
      AND tc."CompanyId" = p_company_id
      AND (p_search IS NULL
           OR CAST(tc."TypeId" AS VARCHAR(20)) LIKE '%' || p_search || '%'
           OR tc."TypeName" ILIKE '%' || p_search || '%'
           OR tc."TypeCode" ILIKE '%' || p_search || '%')
      AND (p_categoria IS NULL OR tc."CategoryCode" = p_categoria);

    RETURN QUERY
    SELECT
        t."TypeId",
        t."TypeName",
        t."CategoryCode"::VARCHAR(50),
        NULL::VARCHAR(10)  AS "Co_Usuario",
        v_total            AS "TotalCount"
    FROM master."ProductType" t
    WHERE t."IsDeleted" = FALSE
      AND t."CompanyId" = p_company_id
      AND (p_search IS NULL
           OR CAST(t."TypeId" AS VARCHAR(20)) LIKE '%' || p_search || '%'
           OR t."TypeName" ILIKE '%' || p_search || '%'
           OR t."TypeCode" ILIKE '%' || p_search || '%')
      AND (p_categoria IS NULL OR t."CategoryCode" = p_categoria)
    ORDER BY t."TypeId"
    LIMIT p_limit OFFSET v_offset;
END;
$$;
-- +goose StatementEnd

-- +goose Down
-- No-op: CREATE OR REPLACE es idempotente
