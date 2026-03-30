-- ============================================================
-- DatqBoxWeb PostgreSQL - usp_ecommerce.sql
-- Funciones para Tienda Online (E-commerce): catalogo publico,
-- detalle de producto, categorias, marcas, clientes, pedidos,
-- resenas, direcciones y metodos de pago.
-- Traducido de SQL Server stored procedures a PL/pgSQL.
-- ============================================================

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- 0. Esquema y tabla de resenas
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
CREATE SCHEMA IF NOT EXISTS store;

CREATE TABLE IF NOT EXISTS store."ProductReview" (
    "ReviewId"       SERIAL PRIMARY KEY,
    "CompanyId"      INT NOT NULL DEFAULT 1,
    "ProductCode"    VARCHAR(80) NOT NULL,
    "Rating"         INT NOT NULL CHECK ("Rating" BETWEEN 1 AND 5),
    "Title"          VARCHAR(200) NULL,
    "Comment"        VARCHAR(2000) NOT NULL,
    "ReviewerName"   VARCHAR(200) NOT NULL DEFAULT 'Cliente',
    "ReviewerEmail"  VARCHAR(150) NULL,
    "IsVerified"     BOOLEAN NOT NULL DEFAULT FALSE,
    "IsApproved"     BOOLEAN NOT NULL DEFAULT TRUE,
    "IsDeleted"      BOOLEAN NOT NULL DEFAULT FALSE,
    "CreatedAt"      TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC')
);

CREATE INDEX IF NOT EXISTS "IX_ProductReview_Product"
    ON store."ProductReview" ("CompanyId", "ProductCode", "IsDeleted", "IsApproved");

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- 0c. Tabla store."ProductHighlight"
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
CREATE TABLE IF NOT EXISTS store."ProductHighlight" (
    "HighlightId"    SERIAL PRIMARY KEY,
    "CompanyId"      INT NOT NULL DEFAULT 1,
    "ProductCode"    VARCHAR(80) NOT NULL,
    "SortOrder"      INT NOT NULL DEFAULT 0,
    "HighlightText"  VARCHAR(500) NOT NULL,
    "IsActive"       BOOLEAN NOT NULL DEFAULT TRUE,
    "CreatedAt"      TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC')
);

CREATE INDEX IF NOT EXISTS "IX_ProductHighlight_Product"
    ON store."ProductHighlight" ("CompanyId", "ProductCode", "IsActive");

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- 0d. Tabla store."ProductSpec"
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
CREATE TABLE IF NOT EXISTS store."ProductSpec" (
    "SpecId"         SERIAL PRIMARY KEY,
    "CompanyId"      INT NOT NULL DEFAULT 1,
    "ProductCode"    VARCHAR(80) NOT NULL,
    "SpecGroup"      VARCHAR(100) NOT NULL DEFAULT 'General',
    "SpecKey"        VARCHAR(100) NOT NULL,
    "SpecValue"      VARCHAR(500) NOT NULL,
    "SortOrder"      INT NOT NULL DEFAULT 0,
    "IsActive"       BOOLEAN NOT NULL DEFAULT TRUE,
    "CreatedAt"      TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC')
);

CREATE INDEX IF NOT EXISTS "IX_ProductSpec_Product"
    ON store."ProductSpec" ("CompanyId", "ProductCode", "IsActive");

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- 14. Tabla master."CustomerAddress"
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
CREATE TABLE IF NOT EXISTS master."CustomerAddress" (
    "AddressId"       SERIAL PRIMARY KEY,
    "CompanyId"       INT NOT NULL DEFAULT 1,
    "CustomerCode"    VARCHAR(24) NOT NULL,
    "Label"           VARCHAR(50) NOT NULL,
    "RecipientName"   VARCHAR(200) NOT NULL,
    "Phone"           VARCHAR(40) NULL,
    "AddressLine"     VARCHAR(300) NOT NULL,
    "City"            VARCHAR(100) NULL,
    "State"           VARCHAR(100) NULL,
    "ZipCode"         VARCHAR(20) NULL,
    "Country"         VARCHAR(50) NOT NULL DEFAULT 'Venezuela',
    "Instructions"    VARCHAR(300) NULL,
    "IsDefault"       BOOLEAN NOT NULL DEFAULT FALSE,
    "IsDeleted"       BOOLEAN NOT NULL DEFAULT FALSE,
    "CreatedAt"       TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "UpdatedAt"       TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC')
);

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- 15. Tabla master."CustomerPaymentMethod"
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
CREATE TABLE IF NOT EXISTS master."CustomerPaymentMethod" (
    "PaymentMethodId" SERIAL PRIMARY KEY,
    "CompanyId"       INT NOT NULL DEFAULT 1,
    "CustomerCode"    VARCHAR(24) NOT NULL,
    "MethodType"      VARCHAR(30) NOT NULL,
    "Label"           VARCHAR(50) NOT NULL,
    "BankName"        VARCHAR(100) NULL,
    "AccountPhone"    VARCHAR(40) NULL,
    "AccountNumber"   VARCHAR(40) NULL,
    "AccountEmail"    VARCHAR(150) NULL,
    "HolderName"      VARCHAR(200) NULL,
    "HolderFiscalId"  VARCHAR(30) NULL,
    "CardType"        VARCHAR(20) NULL,
    "CardLast4"       VARCHAR(4) NULL,
    "CardExpiry"      VARCHAR(7) NULL,
    "IsDefault"       BOOLEAN NOT NULL DEFAULT FALSE,
    "IsDeleted"       BOOLEAN NOT NULL DEFAULT FALSE,
    "CreatedAt"       TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "UpdatedAt"       TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC')
);


-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- 1. Catalogo publico de productos (con rating)
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
DROP FUNCTION IF EXISTS usp_Store_Product_List(INT, INT, VARCHAR(200), VARCHAR(100), VARCHAR(100), NUMERIC(18,2), NUMERIC(18,2), INT, BOOLEAN, VARCHAR(30), INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_Store_Product_List(
    p_company_id    INT            DEFAULT 1,
    p_branch_id     INT            DEFAULT 1,
    p_search        VARCHAR(200)   DEFAULT NULL,
    p_category      VARCHAR(100)   DEFAULT NULL,
    p_brand         VARCHAR(100)   DEFAULT NULL,
    p_price_min     NUMERIC(18,2)  DEFAULT NULL,
    p_price_max     NUMERIC(18,2)  DEFAULT NULL,
    p_min_rating    INT            DEFAULT NULL,
    p_in_stock_only BOOLEAN        DEFAULT TRUE,
    p_sort_by       VARCHAR(30)    DEFAULT 'name',
    p_page          INT            DEFAULT 1,
    p_limit         INT            DEFAULT 24
)
RETURNS TABLE(
    "TotalCount"       BIGINT,
    "id"               BIGINT,
    "code"             VARCHAR(80),
    "name"             VARCHAR(250),
    "fullDescription"  VARCHAR(500),
    "shortDescription" VARCHAR(500),
    "category"         VARCHAR(100),
    "categoryName"     VARCHAR(200),
    "brandCode"        VARCHAR(20),
    "brandName"        VARCHAR(200),
    "price"            NUMERIC(18,2),
    "compareAtPrice"   NUMERIC(18,2),
    "stock"            NUMERIC(18,4),
    "isService"        BOOLEAN,
    "taxRate"          NUMERIC(18,6),
    "imageUrl"         VARCHAR(500),
    "avgRating"        DOUBLE PRECISION,
    "reviewCount"      INT
)
LANGUAGE plpgsql AS $$
DECLARE
    v_offset         INT := (GREATEST(p_page, 1) - 1) * p_limit;
    v_search_pattern VARCHAR(202) := CASE
        WHEN p_search IS NOT NULL AND TRIM(p_search) <> '' THEN '%' || TRIM(p_search) || '%'
        ELSE NULL END;
    v_total          BIGINT;
BEGIN
    -- Calcular total
    SELECT COUNT(*) INTO v_total
    FROM master."Product" p
    LEFT JOIN (
        SELECT r."CompanyId", r."ProductCode",
               AVG(r."Rating"::DOUBLE PRECISION) AS "AvgRating",
               COUNT(*) AS "ReviewCount"
        FROM store."ProductReview" r
        WHERE r."IsDeleted" = FALSE AND r."IsApproved" = TRUE
        GROUP BY r."CompanyId", r."ProductCode"
    ) rv ON rv."CompanyId" = p."CompanyId" AND rv."ProductCode" = p."ProductCode"
    WHERE p."CompanyId"  = p_company_id
      AND p."IsDeleted"  = FALSE
      AND p."IsActive"   = TRUE
      AND (NOT p_in_stock_only OR p."StockQty" > 0 OR p."IsService" = TRUE)
      AND (v_search_pattern IS NULL OR p."ProductCode" LIKE v_search_pattern
           OR p."ProductName" LIKE v_search_pattern OR p."CategoryCode" LIKE v_search_pattern)
      AND (p_category IS NULL OR p."CategoryCode" = p_category)
      AND (p_brand IS NULL OR p."BrandCode" = p_brand)
      AND (p_price_min IS NULL OR p."SalesPrice" >= p_price_min)
      AND (p_price_max IS NULL OR p."SalesPrice" <= p_price_max)
      AND (p_min_rating IS NULL OR COALESCE(rv."AvgRating", 0) >= p_min_rating);

    RETURN QUERY
    SELECT v_total,
        p."ProductId"::BIGINT,
        p."ProductCode"::VARCHAR(80),
        p."ProductName"::VARCHAR(250),
        COALESCE(p."ShortDescription", p."ProductName")::VARCHAR(500),
        p."ShortDescription"::VARCHAR(500),
        p."CategoryCode"::VARCHAR(100),
        c."CategoryName"::VARCHAR(200),
        p."BrandCode"::VARCHAR(20),
        b."BrandName"::VARCHAR(200),
        p."SalesPrice",
        p."CompareAtPrice",
        p."StockQty",
        p."IsService",
        CASE WHEN p."DefaultTaxRate" > 1 THEN p."DefaultTaxRate" / 100.0
             ELSE COALESCE(p."DefaultTaxRate", 0) END,
        img."PublicUrl"::VARCHAR(500),
        COALESCE(rv."AvgRating", 0),
        COALESCE(rv."ReviewCount", 0)::INT
    FROM master."Product" p
    LEFT JOIN master."Category" c
        ON c."CategoryCode" = p."CategoryCode" AND c."CompanyId" = p."CompanyId" AND c."IsDeleted" = FALSE
    LEFT JOIN master."Brand" b
        ON b."BrandCode" = p."BrandCode" AND b."CompanyId" = p."CompanyId" AND b."IsDeleted" = FALSE
    LEFT JOIN LATERAL (
        SELECT ma."PublicUrl"
        FROM cfg."EntityImage" ei
        INNER JOIN cfg."MediaAsset" ma ON ma."MediaAssetId" = ei."MediaAssetId"
        WHERE ei."CompanyId"   = p."CompanyId"
          AND ei."BranchId"    = p_branch_id
          AND ei."EntityType"  = 'MASTER_PRODUCT'
          AND ei."EntityId"    = p."ProductId"
          AND ei."IsDeleted"   = FALSE
          AND ei."IsActive"    = TRUE
          AND ma."IsDeleted"   = FALSE
          AND ma."IsActive"    = TRUE
        ORDER BY CASE WHEN ei."IsPrimary" = TRUE THEN 0 ELSE 1 END, ei."SortOrder", ei."EntityImageId"
        LIMIT 1
    ) img ON TRUE
    LEFT JOIN (
        SELECT r."CompanyId", r."ProductCode",
               AVG(r."Rating"::DOUBLE PRECISION) AS "AvgRating",
               COUNT(*)::INT AS "ReviewCount"
        FROM store."ProductReview" r
        WHERE r."IsDeleted" = FALSE AND r."IsApproved" = TRUE
        GROUP BY r."CompanyId", r."ProductCode"
    ) rv ON rv."CompanyId" = p."CompanyId" AND rv."ProductCode" = p."ProductCode"
    WHERE p."CompanyId"  = p_company_id
      AND p."IsDeleted"  = FALSE
      AND p."IsActive"   = TRUE
      AND (NOT p_in_stock_only OR p."StockQty" > 0 OR p."IsService" = TRUE)
      AND (v_search_pattern IS NULL OR p."ProductCode" LIKE v_search_pattern
           OR p."ProductName" LIKE v_search_pattern OR p."CategoryCode" LIKE v_search_pattern)
      AND (p_category IS NULL OR p."CategoryCode" = p_category)
      AND (p_brand IS NULL OR p."BrandCode" = p_brand)
      AND (p_price_min IS NULL OR p."SalesPrice" >= p_price_min)
      AND (p_price_max IS NULL OR p."SalesPrice" <= p_price_max)
      AND (p_min_rating IS NULL OR COALESCE(rv."AvgRating", 0) >= p_min_rating)
    ORDER BY
        CASE WHEN p_sort_by = 'name'       THEN p."ProductName" END ASC,
        CASE WHEN p_sort_by = 'price_asc'  THEN p."SalesPrice"  END ASC,
        CASE WHEN p_sort_by = 'price_desc' THEN p."SalesPrice"  END DESC,
        CASE WHEN p_sort_by = 'rating'     THEN rv."AvgRating"  END DESC,
        CASE WHEN p_sort_by = 'newest'     THEN p."ProductId"   END DESC,
        CASE WHEN p_sort_by = 'bestseller' THEN rv."ReviewCount" END DESC,
        p."ProductName" ASC
    LIMIT p_limit OFFSET v_offset;
END;
$$;

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- 2. Detalle de producto por codigo (recordset 1: producto)
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
DROP FUNCTION IF EXISTS usp_Store_Product_GetByCode(INT, INT, VARCHAR(80)) CASCADE;
CREATE OR REPLACE FUNCTION usp_Store_Product_GetByCode(
    p_company_id  INT           DEFAULT 1,
    p_branch_id   INT           DEFAULT 1,
    p_code        VARCHAR(80)   DEFAULT NULL
)
RETURNS TABLE(
    "id"               BIGINT,
    "code"             VARCHAR(80),
    "name"             VARCHAR(250),
    "fullDescription"  TEXT,
    "shortDescription" VARCHAR(500),
    "longDescription"  TEXT,
    "category"         VARCHAR(100),
    "categoryName"     VARCHAR(200),
    "brandCode"        VARCHAR(20),
    "brandName"        VARCHAR(200),
    "price"            NUMERIC(18,2),
    "compareAtPrice"   NUMERIC(18,2),
    "costPrice"        NUMERIC(18,2),
    "stock"            NUMERIC(18,4),
    "isService"        BOOLEAN,
    "unitCode"         VARCHAR(20),
    "taxRate"          NUMERIC(18,6),
    "weightKg"         NUMERIC(10,3),
    "widthCm"          NUMERIC(10,2),
    "heightCm"         NUMERIC(10,2),
    "depthCm"          NUMERIC(10,2),
    "warrantyMonths"   INT,
    "barCode"          VARCHAR(50),
    "slug"             VARCHAR(200),
    "avgRating"        DOUBLE PRECISION,
    "reviewCount"      INT
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        p."ProductId"::BIGINT,
        p."ProductCode"::VARCHAR(80),
        p."ProductName"::VARCHAR(250),
        COALESCE(p."ShortDescription", p."ProductName")::TEXT,
        p."ShortDescription"::VARCHAR(500),
        p."LongDescription"::TEXT,
        p."CategoryCode"::VARCHAR(100),
        c."CategoryName"::VARCHAR(200),
        p."BrandCode"::VARCHAR(20),
        b."BrandName"::VARCHAR(200),
        p."SalesPrice",
        p."CompareAtPrice",
        p."CostPrice",
        p."StockQty",
        p."IsService",
        p."UnitCode"::VARCHAR(20),
        CASE WHEN p."DefaultTaxRate" > 1 THEN p."DefaultTaxRate" / 100.0
             ELSE COALESCE(p."DefaultTaxRate", 0) END,
        p."WeightKg",
        p."WidthCm",
        p."HeightCm",
        p."DepthCm",
        p."WarrantyMonths",
        p."BarCode"::VARCHAR(50),
        p."Slug"::VARCHAR(200),
        COALESCE(rv."AvgRating", 0),
        COALESCE(rv."ReviewCount", 0)::INT
    FROM master."Product" p
    LEFT JOIN master."Category" c ON c."CategoryCode" = p."CategoryCode" AND c."CompanyId" = p."CompanyId" AND c."IsDeleted" = FALSE
    LEFT JOIN master."Brand" b ON b."BrandCode" = p."BrandCode" AND b."CompanyId" = p."CompanyId" AND b."IsDeleted" = FALSE
    LEFT JOIN LATERAL (
        SELECT
            AVG(r."Rating"::DOUBLE PRECISION) AS "AvgRating",
            COUNT(*)::INT AS "ReviewCount"
        FROM store."ProductReview" r
        WHERE r."CompanyId" = p."CompanyId"
          AND r."ProductCode" = p."ProductCode"
          AND r."IsDeleted" = FALSE AND r."IsApproved" = TRUE
    ) rv ON TRUE
    WHERE p."CompanyId"   = p_company_id
      AND p."IsDeleted"   = FALSE
      AND p."IsActive"    = TRUE
      AND p."ProductCode" = p_code
    LIMIT 1;
END;
$$;

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- 2b. Imagenes del producto
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
DROP FUNCTION IF EXISTS usp_Store_Product_GetImages(INT, INT, VARCHAR(80)) CASCADE;
CREATE OR REPLACE FUNCTION usp_Store_Product_GetImages(
    p_company_id  INT           DEFAULT 1,
    p_branch_id   INT           DEFAULT 1,
    p_code        VARCHAR(80)   DEFAULT NULL
)
RETURNS TABLE(
    "id"          BIGINT,
    "url"         VARCHAR(500),
    "role"        VARCHAR(50),
    "isPrimary"   BOOLEAN,
    "sortOrder"   INT,
    "altText"     VARCHAR(200)
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        ma."MediaAssetId",
        ma."PublicUrl"::VARCHAR(500),
        ei."RoleCode"::VARCHAR(50),
        ei."IsPrimary",
        ei."SortOrder",
        ma."AltText"::VARCHAR(200)
    FROM cfg."EntityImage" ei
    INNER JOIN cfg."MediaAsset" ma ON ma."MediaAssetId" = ei."MediaAssetId"
    INNER JOIN master."Product" p ON p."ProductId" = ei."EntityId" AND p."CompanyId" = ei."CompanyId"
    WHERE ei."CompanyId"   = p_company_id
      AND ei."BranchId"    = p_branch_id
      AND ei."EntityType"  = 'MASTER_PRODUCT'
      AND p."ProductCode"  = p_code
      AND ei."IsDeleted"   = FALSE
      AND ei."IsActive"    = TRUE
      AND ma."IsDeleted"   = FALSE
      AND ma."IsActive"    = TRUE
    ORDER BY CASE WHEN ei."IsPrimary" = TRUE THEN 0 ELSE 1 END, ei."SortOrder";
END;
$$;

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- 2c. Highlights del producto
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
DROP FUNCTION IF EXISTS usp_Store_Product_GetHighlights(INT, VARCHAR(80)) CASCADE;
CREATE OR REPLACE FUNCTION usp_Store_Product_GetHighlights(
    p_company_id  INT           DEFAULT 1,
    p_code        VARCHAR(80)   DEFAULT NULL
)
RETURNS TABLE("text" VARCHAR(500))
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT h."HighlightText"::VARCHAR(500)
    FROM store."ProductHighlight" h
    WHERE h."CompanyId"   = p_company_id
      AND h."ProductCode" = p_code
      AND h."IsActive"    = TRUE
    ORDER BY h."SortOrder", h."HighlightId";
END;
$$;

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- 2d. Especificaciones tecnicas del producto
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
DROP FUNCTION IF EXISTS usp_Store_Product_GetSpecs(INT, VARCHAR(80)) CASCADE;
CREATE OR REPLACE FUNCTION usp_Store_Product_GetSpecs(
    p_company_id  INT           DEFAULT 1,
    p_code        VARCHAR(80)   DEFAULT NULL
)
RETURNS TABLE(
    "group" VARCHAR(100),
    "key"   VARCHAR(100),
    "value" VARCHAR(500)
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT s."SpecGroup"::VARCHAR(100),
           s."SpecKey"::VARCHAR(100),
           s."SpecValue"::VARCHAR(500)
    FROM store."ProductSpec" s
    WHERE s."CompanyId"   = p_company_id
      AND s."ProductCode" = p_code
      AND s."IsActive"    = TRUE
    ORDER BY s."SpecGroup", s."SortOrder", s."SpecId";
END;
$$;

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- 3. Categorias con conteo de productos
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
DROP FUNCTION IF EXISTS usp_Store_Category_List(INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_Store_Category_List(
    p_company_id INT DEFAULT 1
)
RETURNS TABLE(
    "code"         VARCHAR(100),
    "name"         VARCHAR(200),
    "productCount" BIGINT
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        c."CategoryCode"::VARCHAR(100),
        c."CategoryName"::VARCHAR(200),
        COUNT(p."ProductId")
    FROM master."Category" c
    LEFT JOIN master."Product" p
        ON p."CategoryCode" = c."CategoryCode"
        AND p."CompanyId" = c."CompanyId"
        AND p."IsDeleted" = FALSE
        AND p."IsActive" = TRUE
        AND (p."StockQty" > 0 OR p."IsService" = TRUE)
    WHERE c."CompanyId" = p_company_id
      AND c."IsDeleted" = FALSE
      AND c."IsActive" = TRUE
    GROUP BY c."CategoryCode", c."CategoryName"
    HAVING COUNT(p."ProductId") > 0
    ORDER BY c."CategoryName";
END;
$$;

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- 4. Marcas
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
DROP FUNCTION IF EXISTS usp_Store_Brand_List(INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_Store_Brand_List(
    p_company_id INT DEFAULT 1
)
RETURNS TABLE(
    "code"         VARCHAR(20),
    "name"         VARCHAR(200),
    "productCount" INT
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        b."BrandCode"::VARCHAR(20),
        b."BrandName"::VARCHAR(200),
        0::INT
    FROM master."Brand" b
    WHERE b."CompanyId" = p_company_id
      AND b."IsDeleted" = FALSE
      AND b."IsActive"  = TRUE
    ORDER BY b."BrandName";
END;
$$;

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- 5. Buscar o crear cliente por email
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
DROP FUNCTION IF EXISTS usp_Store_Customer_FindOrCreate(INT, VARCHAR(150), VARCHAR(200), VARCHAR(40), VARCHAR(250), VARCHAR(30)) CASCADE;
CREATE OR REPLACE FUNCTION usp_Store_Customer_FindOrCreate(
    p_company_id    INT            DEFAULT 1,
    p_email         VARCHAR(150)   DEFAULT NULL,
    p_name          VARCHAR(200)   DEFAULT NULL,
    p_phone         VARCHAR(40)    DEFAULT NULL,
    p_address       VARCHAR(250)   DEFAULT NULL,
    p_fiscal_id     VARCHAR(30)    DEFAULT NULL
)
RETURNS TABLE(
    "CustomerCode" VARCHAR(24),
    "Resultado"    INT,
    "Mensaje"      VARCHAR(500)
)
LANGUAGE plpgsql AS $$
DECLARE
    v_code VARCHAR(24);
    v_seq  INT;
BEGIN
    SELECT c."CustomerCode" INTO v_code
    FROM master."Customer" c
    WHERE c."CompanyId" = p_company_id AND c."Email" = p_email AND c."IsDeleted" = FALSE
    LIMIT 1;

    IF v_code IS NOT NULL THEN
        RETURN QUERY SELECT v_code, 1, 'Cliente encontrado'::VARCHAR(500);
        RETURN;
    END IF;

    SELECT COALESCE(MAX(REPLACE(c."CustomerCode", 'ECOM-',''::VARCHAR)::INT), 0) + 1
    INTO v_seq
    FROM master."Customer" c
    WHERE c."CompanyId" = p_company_id AND c."CustomerCode" LIKE 'ECOM-%';

    v_code := 'ECOM-' || LPAD(v_seq::TEXT, 6, '0');

    INSERT INTO master."Customer" (
        "CompanyId", "CustomerCode", "CustomerName", "Email", "Phone", "AddressLine", "FiscalId",
        "IsActive", "IsDeleted", "CreatedAt", "UpdatedAt"
    ) VALUES (
        p_company_id, v_code, p_name, p_email, p_phone, p_address,
        COALESCE(p_fiscal_id,''::VARCHAR),
        TRUE, FALSE, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'
    );

    RETURN QUERY SELECT v_code, 1, 'Cliente creado'::VARCHAR(500);
END;
$$;

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- 6. Registro de cuenta de cliente
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
DROP FUNCTION IF EXISTS usp_Store_Customer_Register(INT, VARCHAR(150), VARCHAR(200), VARCHAR(500), VARCHAR(40), VARCHAR(250), VARCHAR(30)) CASCADE;
CREATE OR REPLACE FUNCTION usp_Store_Customer_Register(
    p_company_id    INT            DEFAULT 1,
    p_email         VARCHAR(150)   DEFAULT NULL,
    p_name          VARCHAR(200)   DEFAULT NULL,
    p_password_hash VARCHAR(500)   DEFAULT NULL,
    p_phone         VARCHAR(40)    DEFAULT NULL,
    p_address       VARCHAR(250)   DEFAULT NULL,
    p_fiscal_id     VARCHAR(30)    DEFAULT NULL
)
RETURNS TABLE(
    "Resultado" INT,
    "Mensaje"   VARCHAR(500)
)
LANGUAGE plpgsql AS $$
DECLARE
    v_customer_code VARCHAR(24);
    v_user_code VARCHAR(40);
BEGIN
    IF EXISTS (SELECT 1 FROM sec."User" WHERE "Email" = p_email AND "IsDeleted" = FALSE) THEN
        RETURN QUERY SELECT -1, 'Ya existe una cuenta con este email'::VARCHAR(500);
        RETURN;
    END IF;

    -- Buscar o crear cliente
    SELECT r."CustomerCode" INTO v_customer_code
    FROM usp_Store_Customer_FindOrCreate(p_company_id, p_email, p_name, p_phone, p_address, p_fiscal_id) r;

    -- Generate UserCode from email prefix
    v_user_code := UPPER(LEFT(SPLIT_PART(p_email, '@', 1), 40));
    IF EXISTS (SELECT 1 FROM sec."User" WHERE "UserCode" = v_user_code) THEN
        v_user_code := LEFT(v_user_code, 34) || '_' || LPAD(FLOOR(RANDOM()*99999)::TEXT, 5, '0');
    END IF;

    INSERT INTO sec."User" (
        "UserCode", "CompanyId", "UserName", "Email", "PasswordHash", "DisplayName",
        "IsAdmin", "IsActive", "IsDeleted", "Role", "CreatedAt",
        "CanUpdate", "CanCreate", "CanDelete", "IsCreator", "CanChangePwd", "CanChangePrice", "CanGiveCredit"
    ) VALUES (
        v_user_code, p_company_id, p_email, p_email, p_password_hash, p_name,
        FALSE, TRUE, FALSE, 'customer', NOW() AT TIME ZONE 'UTC',
        FALSE, FALSE, FALSE, FALSE, TRUE, FALSE, FALSE
    );

    RETURN QUERY SELECT 1, 'Cuenta creada exitosamente'::VARCHAR(500);
END;
$$;

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- 7. Login de cliente
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
DROP FUNCTION IF EXISTS usp_Store_Customer_Login(VARCHAR(150)) CASCADE;
CREATE OR REPLACE FUNCTION usp_Store_Customer_Login(
    p_email VARCHAR(150)
)
RETURNS TABLE(
    "UserId"       INT,
    "Email"        VARCHAR(150),
    "displayName"  VARCHAR(200),
    "passwordHash" VARCHAR(500),
    "isActive"     BOOLEAN,
    "customerCode" VARCHAR(24),
    "customerName" VARCHAR(200),
    "phone"        VARCHAR(40),
    "address"      VARCHAR(250),
    "fiscalId"     VARCHAR(30)
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        u."UserId",
        u."Email"::VARCHAR(150),
        u."DisplayName"::VARCHAR(200),
        u."PasswordHash"::VARCHAR(500),
        u."IsActive",
        c."CustomerCode"::VARCHAR(24),
        c."CustomerName"::VARCHAR(200),
        c."Phone"::VARCHAR(40),
        c."AddressLine"::VARCHAR(250),
        c."FiscalId"::VARCHAR(30)
    FROM sec."User" u
    LEFT JOIN master."Customer" c ON c."Email" = u."Email" AND c."CompanyId" = u."CompanyId" AND c."IsDeleted" = FALSE
    WHERE u."Email" = p_email AND u."IsDeleted" = FALSE AND u."Role" = 'customer'
    LIMIT 1;
END;
$$;

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- 8. Crear pedido ecommerce (JSONB en lugar de XML)
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
DROP FUNCTION IF EXISTS usp_Store_Order_Create(INT, INT, VARCHAR(24), VARCHAR(200), VARCHAR(150), VARCHAR(30), VARCHAR(40), VARCHAR(250), VARCHAR(500), JSONB, INT, INT, VARCHAR(30), INT, VARCHAR(500), VARCHAR(500)) CASCADE;
DROP FUNCTION IF EXISTS usp_Store_Order_Create(INT, INT, VARCHAR(24), VARCHAR(200), VARCHAR(150), VARCHAR(30), VARCHAR(40), VARCHAR(250), VARCHAR(500), JSONB, INT, INT, VARCHAR(30)) CASCADE;
CREATE OR REPLACE FUNCTION usp_Store_Order_Create(
    p_company_id            INT             DEFAULT 1,
    p_branch_id             INT             DEFAULT 1,
    p_customer_code         VARCHAR(24)     DEFAULT NULL,
    p_customer_name         VARCHAR(200)    DEFAULT NULL,
    p_customer_email        VARCHAR(150)    DEFAULT NULL,
    p_fiscal_id             VARCHAR(30)     DEFAULT NULL,
    p_phone                 VARCHAR(40)     DEFAULT NULL,
    p_address               VARCHAR(250)    DEFAULT NULL,
    p_notes                 VARCHAR(500)    DEFAULT NULL,
    p_items_json            JSONB           DEFAULT NULL,
    p_address_id            INT             DEFAULT NULL,
    p_payment_method_id     INT             DEFAULT NULL,
    p_payment_method_type   VARCHAR(30)     DEFAULT NULL,
    p_billing_address_id    INT             DEFAULT NULL,
    p_shipping_address_text VARCHAR(500)    DEFAULT NULL,
    p_billing_address_text  VARCHAR(500)    DEFAULT NULL
)
RETURNS TABLE(
    "OrderNumber" VARCHAR(60),
    "OrderToken"  VARCHAR(100),
    "Resultado"   INT,
    "Mensaje"     VARCHAR(500)
)
LANGUAGE plpgsql AS $$
DECLARE
    v_order_number VARCHAR(60);
    v_order_token  VARCHAR(100);
    v_today        VARCHAR(8);
    v_seq          INT;
    v_total_sub    NUMERIC(18,2);
    v_total_tax    NUMERIC(18,2);
BEGIN
    v_today := TO_CHAR(NOW(), 'YYYYMMDD');

    SELECT COALESCE(MAX(
        CASE WHEN RIGHT("DocumentNumber", 4) ~ '^\d+$'
             THEN RIGHT("DocumentNumber", 4)::INT ELSE 0 END
    ), 0) + 1
    INTO v_seq
    FROM doc."SalesDocument"
    WHERE "OperationType" = 'PEDIDO' AND "DocumentNumber" LIKE 'ECOM-' || v_today || '-%';

    v_order_number := 'ECOM-' || v_today || '-' || LPAD(v_seq::TEXT, 4, '0');
    v_order_token  := LOWER(REPLACE(gen_random_uuid()::TEXT, '-',''::VARCHAR));

    -- Calcular totales desde JSON
    SELECT COALESCE(SUM((item->>'st')::NUMERIC(18,2)), 0),
           COALESCE(SUM((item->>'ta')::NUMERIC(18,2)), 0)
    INTO v_total_sub, v_total_tax
    FROM jsonb_array_elements(p_items_json) AS item;

    -- Insertar cabecera
    INSERT INTO doc."SalesDocument" (
        "DocumentNumber", "SerialType", "OperationType",
        "CustomerCode", "CustomerName", "FiscalId",
        "IssueDate", "DocumentTime",
        "Subtotal", "TaxableAmount", "ExemptAmount", "TaxAmount", "TotalAmount", "DiscountAmount",
        "IsVoided", "IsCanceled", "IsInvoiced", "IsDelivered",
        "Notes", "CurrencyCode", "ExchangeRate",
        "ShippingAddressId", "BillingAddressId", "ShippingAddress", "BillingAddress",
        "CreatedAt", "UpdatedAt", "IsDeleted"
    ) VALUES (
        v_order_number, 'ECOM', 'PEDIDO',
        p_customer_code, p_customer_name, COALESCE(p_fiscal_id,''::VARCHAR),
        CURRENT_DATE, TO_CHAR(NOW(), 'HH24:MI:SS'),
        v_total_sub, v_total_sub, 0, v_total_tax, v_total_sub + v_total_tax, 0,
        FALSE, 'N', 'N', 'N',
        COALESCE(p_notes,''::VARCHAR) || ' | token=' || v_order_token,
        'USD', 1.0,
        p_address_id, COALESCE(p_billing_address_id, p_address_id),
        COALESCE(p_shipping_address_text, p_address),
        COALESCE(p_billing_address_text, p_shipping_address_text, p_address),
        NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC', FALSE
    );

    -- Insertar lineas de detalle desde JSON
    INSERT INTO doc."SalesDocumentLine" (
        "DocumentNumber", "SerialType", "DocumentType", "LineNumber",
        "ProductCode", "Description", "Quantity", "UnitPrice", "DiscountUnitPrice", "UnitCost",
        "Subtotal", "DiscountAmount", "LineTotal", "TaxRate", "TaxAmount", "IsVoided",
        "CreatedAt", "UpdatedAt", "IsDeleted"
    )
    SELECT
        v_order_number, 'ECOM', 'PEDIDO', ROW_NUMBER() OVER ()::INT,
        (item->>'pc')::VARCHAR(80),
        (item->>'pn')::VARCHAR(250),
        (item->>'qty')::NUMERIC(18,3),
        (item->>'up')::NUMERIC(18,2),
        (item->>'up')::NUMERIC(18,2),
        0,
        (item->>'st')::NUMERIC(18,2),
        0,
        (item->>'st')::NUMERIC(18,2) + (item->>'ta')::NUMERIC(18,2),
        (item->>'tr')::NUMERIC(9,4),
        (item->>'ta')::NUMERIC(18,2),
        FALSE,
        NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC', FALSE
    FROM jsonb_array_elements(p_items_json) AS item;

    -- Descontar stock
    UPDATE master."Product" pr
    SET "StockQty" = pr."StockQty" - d.qty
    FROM (
        SELECT (item->>'pc')::VARCHAR(80) AS pc, SUM((item->>'qty')::NUMERIC) AS qty
        FROM jsonb_array_elements(p_items_json) AS item
        GROUP BY (item->>'pc')
    ) d
    WHERE d.pc = pr."ProductCode" AND pr."CompanyId" = p_company_id;

    -- Registrar movimiento en inventario avanzado (inv.StockMovement)
    -- Solo si la tabla existe (compatibilidad con instalaciones sin inv.*)
    BEGIN
        INSERT INTO inv."StockMovement" (
            "CompanyId", "BranchId", "ProductId",
            "MovementType", "Quantity", "UnitCost", "TotalCost",
            "SourceDocumentType", "SourceDocumentNumber",
            "Notes", "MovementDate", "CreatedAt"
        )
        SELECT
            p_company_id,
            p_branch_id,
            pr."ProductId",
            'SALE_OUT',
            (item->>'qty')::NUMERIC(18,4),
            COALESCE(pr."CostPrice", pr."SalesPrice", 0),
            (item->>'qty')::NUMERIC(18,4) * COALESCE(pr."CostPrice", pr."SalesPrice", 0),
            'ECOM_PEDIDO',
            v_order_number,
            'Pedido ecommerce',
            NOW() AT TIME ZONE 'UTC',
            NOW() AT TIME ZONE 'UTC'
        FROM jsonb_array_elements(p_items_json) AS item
        INNER JOIN master."Product" pr
            ON pr."ProductCode" = (item->>'pc')
            AND pr."CompanyId" = p_company_id;
    EXCEPTION WHEN undefined_table THEN
        -- inv.StockMovement no existe en esta instalaciÃ³n, ignorar
        NULL;
    END;

    RETURN QUERY SELECT v_order_number, v_order_token, 1, 'Pedido creado exitosamente'::VARCHAR(500);

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT NULL::VARCHAR(60), NULL::VARCHAR(100), -99, SQLERRM::VARCHAR(500);
END;
$$;

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- 9. Historial de pedidos
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
DROP FUNCTION IF EXISTS usp_Store_Order_List(INT, VARCHAR(24), INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_Store_Order_List(
    p_company_id    INT DEFAULT 1,
    p_customer_code VARCHAR(24) DEFAULT NULL,
    p_page          INT DEFAULT 1,
    p_limit         INT DEFAULT 20
)
RETURNS TABLE(
    "TotalCount"    BIGINT,
    "orderNumber"   VARCHAR(60),
    "orderDate"     DATE,
    "customerName"  VARCHAR(200),
    "subtotal"      NUMERIC(18,2),
    "taxAmount"     NUMERIC(18,2),
    "totalAmount"   NUMERIC(18,2),
    "isInvoiced"    VARCHAR(1),
    "isDelivered"   VARCHAR(1),
    "notes"         TEXT
)
LANGUAGE plpgsql AS $$
DECLARE
    v_offset INT := (GREATEST(p_page, 1) - 1) * p_limit;
    v_total  BIGINT;
BEGIN
    SELECT COUNT(*) INTO v_total FROM doc."SalesDocument"
    WHERE "OperationType" = 'PEDIDO' AND "SerialType" = 'ECOM'
      AND "CustomerCode" = p_customer_code AND "IsVoided" = FALSE;

    RETURN QUERY
    SELECT v_total,
        d."DocumentNumber"::VARCHAR(60), d."IssueDate", d."CustomerName"::VARCHAR(200),
        d."Subtotal", d."TaxAmount", d."TotalAmount",
        d."IsInvoiced"::VARCHAR(1), d."IsDelivered"::VARCHAR(1), d."Notes"::TEXT
    FROM doc."SalesDocument" d
    WHERE d."OperationType" = 'PEDIDO' AND d."SerialType" = 'ECOM'
      AND d."CustomerCode" = p_customer_code AND d."IsVoided" = FALSE
    ORDER BY d."IssueDate" DESC, d."DocumentNumber" DESC
    LIMIT p_limit OFFSET v_offset;
END;
$$;

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- 10. Detalle de pedido por numero (cabecera)
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
DROP FUNCTION IF EXISTS usp_Store_Order_GetByNumber(INT, VARCHAR(60)) CASCADE;
CREATE OR REPLACE FUNCTION usp_Store_Order_GetByNumber(
    p_company_id   INT DEFAULT 1,
    p_order_number VARCHAR(60) DEFAULT NULL
)
RETURNS TABLE(
    "orderNumber"    VARCHAR(60),
    "orderDate"      DATE,
    "customerCode"   VARCHAR(24),
    "customerName"   VARCHAR(200),
    "fiscalId"       VARCHAR(30),
    "subtotal"       NUMERIC(18,2),
    "taxAmount"      NUMERIC(18,2),
    "totalAmount"    NUMERIC(18,2),
    "discountAmount" NUMERIC(18,2),
    "isInvoiced"     VARCHAR(1),
    "isDelivered"    VARCHAR(1),
    "notes"          TEXT,
    "createdAt"      TIMESTAMP
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT d."DocumentNumber"::VARCHAR(60), d."IssueDate",
        d."CustomerCode"::VARCHAR(24), d."CustomerName"::VARCHAR(200), d."FiscalId"::VARCHAR(30),
        d."Subtotal", d."TaxAmount", d."TotalAmount",
        d."DiscountAmount", d."IsInvoiced"::VARCHAR(1),
        d."IsDelivered"::VARCHAR(1), d."Notes"::TEXT, d."CreatedAt"
    FROM doc."SalesDocument" d
    WHERE d."OperationType" = 'PEDIDO' AND d."DocumentNumber" = p_order_number
    LIMIT 1;
END;
$$;

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- 10b. Detalle de pedido por numero (lineas)
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
DROP FUNCTION IF EXISTS usp_Store_Order_GetByNumber_Lines(VARCHAR(60)) CASCADE;
CREATE OR REPLACE FUNCTION usp_Store_Order_GetByNumber_Lines(
    p_order_number VARCHAR(60) DEFAULT NULL
)
RETURNS TABLE(
    "lineNumber"   INT,
    "productCode"  VARCHAR(80),
    "productName"  VARCHAR(250),
    "quantity"     NUMERIC(18,3),
    "unitPrice"    NUMERIC(18,2),
    "subtotal"     NUMERIC(18,2),
    "taxRate"      NUMERIC(9,4),
    "taxAmount"    NUMERIC(18,2),
    "lineTotal"    NUMERIC(18,2)
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT l."LineNumber", l."ProductCode"::VARCHAR(80), l."Description"::VARCHAR(250),
        l."Quantity", l."UnitPrice", l."Subtotal",
        l."TaxRate", l."TaxAmount", l."LineTotal"
    FROM doc."SalesDocumentLine" l
    WHERE l."DocumentNumber" = p_order_number AND l."SerialType" = 'ECOM' AND l."IsVoided" = FALSE
    ORDER BY l."LineNumber";
END;
$$;

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- 11. Obtener pedido por token
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
DROP FUNCTION IF EXISTS usp_Store_Order_GetByToken(INT, VARCHAR(100)) CASCADE;
CREATE OR REPLACE FUNCTION usp_Store_Order_GetByToken(
    p_company_id INT DEFAULT 1,
    p_token      VARCHAR(100) DEFAULT NULL
)
RETURNS TABLE(
    "orderNumber"    VARCHAR(60),
    "orderDate"      DATE,
    "customerCode"   VARCHAR(24),
    "customerName"   VARCHAR(200),
    "fiscalId"       VARCHAR(30),
    "subtotal"       NUMERIC(18,2),
    "taxAmount"      NUMERIC(18,2),
    "totalAmount"    NUMERIC(18,2),
    "discountAmount" NUMERIC(18,2),
    "isInvoiced"     VARCHAR(1),
    "isDelivered"    VARCHAR(1),
    "notes"          TEXT,
    "createdAt"      TIMESTAMP
)
LANGUAGE plpgsql AS $$
DECLARE
    v_order_number VARCHAR(60);
BEGIN
    SELECT d."DocumentNumber" INTO v_order_number
    FROM doc."SalesDocument" d
    WHERE d."OperationType" = 'PEDIDO' AND d."SerialType" = 'ECOM'
      AND d."Notes" LIKE '%token=' || p_token || '%'
    LIMIT 1;

    IF v_order_number IS NOT NULL THEN
        RETURN QUERY SELECT * FROM usp_Store_Order_GetByNumber(p_company_id, v_order_number);
    END IF;
END;
$$;

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- 12. Listar resenas de un producto (resumen + lista)
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
DROP FUNCTION IF EXISTS usp_Store_Review_List_Summary(INT, VARCHAR(80)) CASCADE;
CREATE OR REPLACE FUNCTION usp_Store_Review_List_Summary(
    p_company_id   INT DEFAULT 1,
    p_product_code VARCHAR(80) DEFAULT NULL
)
RETURNS TABLE(
    "avgRating"  DOUBLE PRECISION,
    "totalCount" BIGINT,
    "star1"      BIGINT,
    "star2"      BIGINT,
    "star3"      BIGINT,
    "star4"      BIGINT,
    "star5"      BIGINT
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT COALESCE(AVG(r."Rating"::DOUBLE PRECISION), 0), COUNT(*),
        SUM(CASE WHEN r."Rating" = 1 THEN 1 ELSE 0 END),
        SUM(CASE WHEN r."Rating" = 2 THEN 1 ELSE 0 END),
        SUM(CASE WHEN r."Rating" = 3 THEN 1 ELSE 0 END),
        SUM(CASE WHEN r."Rating" = 4 THEN 1 ELSE 0 END),
        SUM(CASE WHEN r."Rating" = 5 THEN 1 ELSE 0 END)
    FROM store."ProductReview" r
    WHERE r."CompanyId" = p_company_id AND r."ProductCode" = p_product_code
      AND r."IsDeleted" = FALSE AND r."IsApproved" = TRUE;
END;
$$;

DROP FUNCTION IF EXISTS usp_Store_Review_List_Items(INT, VARCHAR(80), INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_Store_Review_List_Items(
    p_company_id   INT DEFAULT 1,
    p_product_code VARCHAR(80) DEFAULT NULL,
    p_page         INT DEFAULT 1,
    p_limit        INT DEFAULT 20
)
RETURNS TABLE(
    "id"           INT,
    "rating"       INT,
    "title"        VARCHAR(200),
    "comment"      VARCHAR(2000),
    "reviewerName" VARCHAR(200),
    "isVerified"   BOOLEAN,
    "createdAt"    TIMESTAMP
)
LANGUAGE plpgsql AS $$
DECLARE
    v_offset INT := (GREATEST(p_page, 1) - 1) * p_limit;
BEGIN
    RETURN QUERY
    SELECT r."ReviewId", r."Rating", r."Title"::VARCHAR(200), r."Comment"::VARCHAR(2000),
        r."ReviewerName"::VARCHAR(200), r."IsVerified", r."CreatedAt"
    FROM store."ProductReview" r
    WHERE r."CompanyId" = p_company_id AND r."ProductCode" = p_product_code
      AND r."IsDeleted" = FALSE AND r."IsApproved" = TRUE
    ORDER BY r."CreatedAt" DESC
    LIMIT p_limit OFFSET v_offset;
END;
$$;

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- 13. Crear resena
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
DROP FUNCTION IF EXISTS usp_Store_Review_Create(INT, VARCHAR(80), INT, VARCHAR(200), VARCHAR(2000), VARCHAR(200), VARCHAR(150)) CASCADE;
CREATE OR REPLACE FUNCTION usp_Store_Review_Create(
    p_company_id    INT DEFAULT 1,
    p_product_code  VARCHAR(80)  DEFAULT NULL,
    p_rating        INT          DEFAULT NULL,
    p_title         VARCHAR(200) DEFAULT NULL,
    p_comment       VARCHAR(2000) DEFAULT NULL,
    p_reviewer_name VARCHAR(200) DEFAULT 'Cliente',
    p_reviewer_email VARCHAR(150) DEFAULT NULL
)
RETURNS TABLE(
    "Resultado" INT,
    "Mensaje"   VARCHAR(500)
)
LANGUAGE plpgsql AS $$
BEGIN
    IF p_rating < 1 OR p_rating > 5 THEN
        RETURN QUERY SELECT -1, 'La calificacion debe ser entre 1 y 5'::VARCHAR(500);
        RETURN;
    END IF;

    INSERT INTO store."ProductReview" (
        "CompanyId", "ProductCode", "Rating", "Title", "Comment",
        "ReviewerName", "ReviewerEmail", "IsVerified", "IsApproved", "IsDeleted", "CreatedAt"
    ) VALUES (
        p_company_id, p_product_code, p_rating, p_title, p_comment,
        p_reviewer_name, p_reviewer_email, FALSE, TRUE, FALSE, NOW() AT TIME ZONE 'UTC'
    );

    RETURN QUERY SELECT 1, 'Resena creada exitosamente'::VARCHAR(500);
END;
$$;

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- 16. Listar direcciones del cliente
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
DROP FUNCTION IF EXISTS usp_Store_Address_List(INT, VARCHAR(24)) CASCADE;
CREATE OR REPLACE FUNCTION usp_Store_Address_List(
    p_company_id    INT          DEFAULT 1,
    p_customer_code VARCHAR(24)  DEFAULT NULL
)
RETURNS TABLE(
    "AddressId"     INT,
    "Label"         VARCHAR(50),
    "RecipientName" VARCHAR(200),
    "Phone"         VARCHAR(40),
    "AddressLine"   VARCHAR(300),
    "City"          VARCHAR(100),
    "State"         VARCHAR(100),
    "ZipCode"       VARCHAR(20),
    "Country"       VARCHAR(50),
    "Instructions"  VARCHAR(300),
    "IsDefault"     BOOLEAN
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT a."AddressId", a."Label"::VARCHAR(50), a."RecipientName"::VARCHAR(200),
           a."Phone"::VARCHAR(40), a."AddressLine"::VARCHAR(300),
           a."City"::VARCHAR(100), a."State"::VARCHAR(100), a."ZipCode"::VARCHAR(20),
           a."Country"::VARCHAR(50), a."Instructions"::VARCHAR(300), a."IsDefault"
    FROM master."CustomerAddress" a
    WHERE a."CompanyId" = p_company_id AND a."CustomerCode" = p_customer_code AND a."IsDeleted" = FALSE
    ORDER BY a."IsDefault" DESC, a."UpdatedAt" DESC;
END;
$$;

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- 17. Upsert direccion del cliente
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
DROP FUNCTION IF EXISTS usp_Store_Address_Upsert(INT, INT, VARCHAR(24), VARCHAR(50), VARCHAR(200), VARCHAR(40), VARCHAR(300), VARCHAR(100), VARCHAR(100), VARCHAR(20), VARCHAR(50), VARCHAR(300), BOOLEAN) CASCADE;
CREATE OR REPLACE FUNCTION usp_Store_Address_Upsert(
    p_address_id     INT           DEFAULT NULL,
    p_company_id     INT           DEFAULT 1,
    p_customer_code  VARCHAR(24)   DEFAULT NULL,
    p_label          VARCHAR(50)   DEFAULT NULL,
    p_recipient_name VARCHAR(200)  DEFAULT NULL,
    p_phone          VARCHAR(40)   DEFAULT NULL,
    p_address_line   VARCHAR(300)  DEFAULT NULL,
    p_city           VARCHAR(100)  DEFAULT NULL,
    p_state          VARCHAR(100)  DEFAULT NULL,
    p_zip_code       VARCHAR(20)   DEFAULT NULL,
    p_country        VARCHAR(50)   DEFAULT 'Venezuela',
    p_instructions   VARCHAR(300)  DEFAULT NULL,
    p_is_default     BOOLEAN       DEFAULT FALSE
)
RETURNS TABLE(
    "Resultado" INT,
    "Mensaje"   VARCHAR(500),
    "NewId"     INT
)
LANGUAGE plpgsql AS $$
DECLARE
    v_new_id INT := 0;
BEGIN
    -- Si es default, quitar default de las demas
    IF p_is_default THEN
        UPDATE master."CustomerAddress"
        SET "IsDefault" = FALSE, "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
        WHERE "CompanyId" = p_company_id AND "CustomerCode" = p_customer_code AND "IsDeleted" = FALSE;
    END IF;

    IF p_address_id IS NULL THEN
        INSERT INTO master."CustomerAddress"
            ("CompanyId", "CustomerCode", "Label", "RecipientName", "Phone", "AddressLine",
             "City", "State", "ZipCode", "Country", "Instructions", "IsDefault")
        VALUES
            (p_company_id, p_customer_code, p_label, p_recipient_name, p_phone, p_address_line,
             p_city, p_state, p_zip_code, COALESCE(p_country, 'Venezuela'), p_instructions, p_is_default)
        RETURNING "AddressId" INTO v_new_id;

        -- Si es la primera, hacerla default
        IF NOT EXISTS (SELECT 1 FROM master."CustomerAddress"
                      WHERE "CompanyId" = p_company_id AND "CustomerCode" = p_customer_code
                        AND "IsDeleted" = FALSE AND "IsDefault" = TRUE) THEN
            UPDATE master."CustomerAddress" SET "IsDefault" = TRUE WHERE "AddressId" = v_new_id;
        END IF;
    ELSE
        IF NOT EXISTS (SELECT 1 FROM master."CustomerAddress"
                      WHERE "AddressId" = p_address_id AND "CustomerCode" = p_customer_code AND "IsDeleted" = FALSE) THEN
            RETURN QUERY SELECT -1, 'Direccion no encontrada'::VARCHAR(500), 0;
            RETURN;
        END IF;

        UPDATE master."CustomerAddress" SET
            "Label" = p_label, "RecipientName" = p_recipient_name, "Phone" = p_phone,
            "AddressLine" = p_address_line, "City" = p_city, "State" = p_state,
            "ZipCode" = p_zip_code, "Country" = COALESCE(p_country, 'Venezuela'),
            "Instructions" = p_instructions, "IsDefault" = p_is_default,
            "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
        WHERE "AddressId" = p_address_id AND "CustomerCode" = p_customer_code;
        v_new_id := p_address_id;
    END IF;

    RETURN QUERY SELECT 1, 'OK'::VARCHAR(500), v_new_id;

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500), 0;
END;
$$;

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- 18. Eliminar direccion (soft delete)
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
DROP FUNCTION IF EXISTS usp_Store_Address_Delete(INT, VARCHAR(24)) CASCADE;
CREATE OR REPLACE FUNCTION usp_Store_Address_Delete(
    p_address_id    INT          DEFAULT NULL,
    p_customer_code VARCHAR(24)  DEFAULT NULL
)
RETURNS TABLE("Resultado" INT, "Mensaje" VARCHAR(500))
LANGUAGE plpgsql AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM master."CustomerAddress"
                  WHERE "AddressId" = p_address_id AND "CustomerCode" = p_customer_code AND "IsDeleted" = FALSE) THEN
        RETURN QUERY SELECT -1, 'Direccion no encontrada'::VARCHAR(500);
        RETURN;
    END IF;

    UPDATE master."CustomerAddress"
    SET "IsDeleted" = TRUE, "IsDefault" = FALSE, "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
    WHERE "AddressId" = p_address_id AND "CustomerCode" = p_customer_code;

    RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);
END;
$$;

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- 19. Listar metodos de pago del cliente
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
DROP FUNCTION IF EXISTS usp_Store_PaymentMethod_List(INT, VARCHAR(24)) CASCADE;
CREATE OR REPLACE FUNCTION usp_Store_PaymentMethod_List(
    p_company_id    INT          DEFAULT 1,
    p_customer_code VARCHAR(24)  DEFAULT NULL
)
RETURNS TABLE(
    "PaymentMethodId" INT,
    "MethodType"      VARCHAR(30),
    "Label"           VARCHAR(50),
    "BankName"        VARCHAR(100),
    "AccountPhone"    VARCHAR(40),
    "AccountNumber"   VARCHAR(40),
    "AccountEmail"    VARCHAR(150),
    "HolderName"      VARCHAR(200),
    "HolderFiscalId"  VARCHAR(30),
    "CardType"        VARCHAR(20),
    "CardLast4"       VARCHAR(4),
    "CardExpiry"      VARCHAR(7),
    "IsDefault"       BOOLEAN
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT m."PaymentMethodId", m."MethodType"::VARCHAR(30), m."Label"::VARCHAR(50),
           m."BankName"::VARCHAR(100), m."AccountPhone"::VARCHAR(40),
           m."AccountNumber"::VARCHAR(40), m."AccountEmail"::VARCHAR(150),
           m."HolderName"::VARCHAR(200), m."HolderFiscalId"::VARCHAR(30),
           m."CardType"::VARCHAR(20), m."CardLast4"::VARCHAR(4),
           m."CardExpiry"::VARCHAR(7), m."IsDefault"
    FROM master."CustomerPaymentMethod" m
    WHERE m."CompanyId" = p_company_id AND m."CustomerCode" = p_customer_code AND m."IsDeleted" = FALSE
    ORDER BY m."IsDefault" DESC, m."UpdatedAt" DESC;
END;
$$;

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- 20. Upsert metodo de pago del cliente
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
DROP FUNCTION IF EXISTS usp_Store_PaymentMethod_Upsert(INT, INT, VARCHAR(24), VARCHAR(30), VARCHAR(50), VARCHAR(100), VARCHAR(40), VARCHAR(40), VARCHAR(150), VARCHAR(200), VARCHAR(30), VARCHAR(20), VARCHAR(4), VARCHAR(7), BOOLEAN) CASCADE;
CREATE OR REPLACE FUNCTION usp_Store_PaymentMethod_Upsert(
    p_payment_method_id INT           DEFAULT NULL,
    p_company_id        INT           DEFAULT 1,
    p_customer_code     VARCHAR(24)   DEFAULT NULL,
    p_method_type       VARCHAR(30)   DEFAULT NULL,
    p_label             VARCHAR(50)   DEFAULT NULL,
    p_bank_name         VARCHAR(100)  DEFAULT NULL,
    p_account_phone     VARCHAR(40)   DEFAULT NULL,
    p_account_number    VARCHAR(40)   DEFAULT NULL,
    p_account_email     VARCHAR(150)  DEFAULT NULL,
    p_holder_name       VARCHAR(200)  DEFAULT NULL,
    p_holder_fiscal_id  VARCHAR(30)   DEFAULT NULL,
    p_card_type         VARCHAR(20)   DEFAULT NULL,
    p_card_last4        VARCHAR(4)    DEFAULT NULL,
    p_card_expiry       VARCHAR(7)    DEFAULT NULL,
    p_is_default        BOOLEAN       DEFAULT FALSE
)
RETURNS TABLE("Resultado" INT, "Mensaje" VARCHAR(500), "NewId" INT)
LANGUAGE plpgsql AS $$
DECLARE
    v_new_id INT := 0;
BEGIN
    IF p_method_type NOT IN ('PAGO_MOVIL', 'TRANSFERENCIA', 'ZELLE', 'EFECTIVO', 'TARJETA') THEN
        RETURN QUERY SELECT -1, 'Tipo de metodo de pago invalido'::VARCHAR(500), 0;
        RETURN;
    END IF;

    IF p_is_default THEN
        UPDATE master."CustomerPaymentMethod"
        SET "IsDefault" = FALSE, "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
        WHERE "CompanyId" = p_company_id AND "CustomerCode" = p_customer_code AND "IsDeleted" = FALSE;
    END IF;

    IF p_payment_method_id IS NULL THEN
        INSERT INTO master."CustomerPaymentMethod"
            ("CompanyId", "CustomerCode", "MethodType", "Label", "BankName", "AccountPhone",
             "AccountNumber", "AccountEmail", "HolderName", "HolderFiscalId",
             "CardType", "CardLast4", "CardExpiry", "IsDefault")
        VALUES
            (p_company_id, p_customer_code, p_method_type, p_label, p_bank_name, p_account_phone,
             p_account_number, p_account_email, p_holder_name, p_holder_fiscal_id,
             p_card_type, p_card_last4, p_card_expiry, p_is_default)
        RETURNING "PaymentMethodId" INTO v_new_id;

        IF NOT EXISTS (SELECT 1 FROM master."CustomerPaymentMethod"
                      WHERE "CompanyId" = p_company_id AND "CustomerCode" = p_customer_code
                        AND "IsDeleted" = FALSE AND "IsDefault" = TRUE) THEN
            UPDATE master."CustomerPaymentMethod" SET "IsDefault" = TRUE WHERE "PaymentMethodId" = v_new_id;
        END IF;
    ELSE
        IF NOT EXISTS (SELECT 1 FROM master."CustomerPaymentMethod"
                      WHERE "PaymentMethodId" = p_payment_method_id AND "CustomerCode" = p_customer_code AND "IsDeleted" = FALSE) THEN
            RETURN QUERY SELECT -1, 'Metodo de pago no encontrado'::VARCHAR(500), 0;
            RETURN;
        END IF;

        UPDATE master."CustomerPaymentMethod" SET
            "MethodType" = p_method_type, "Label" = p_label, "BankName" = p_bank_name,
            "AccountPhone" = p_account_phone, "AccountNumber" = p_account_number,
            "AccountEmail" = p_account_email, "HolderName" = p_holder_name,
            "HolderFiscalId" = p_holder_fiscal_id, "CardType" = p_card_type,
            "CardLast4" = p_card_last4, "CardExpiry" = p_card_expiry,
            "IsDefault" = p_is_default, "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
        WHERE "PaymentMethodId" = p_payment_method_id AND "CustomerCode" = p_customer_code;
        v_new_id := p_payment_method_id;
    END IF;

    RETURN QUERY SELECT 1, 'OK'::VARCHAR(500), v_new_id;

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500), 0;
END;
$$;

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- 21. Eliminar metodo de pago (soft delete)
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
DROP FUNCTION IF EXISTS usp_Store_PaymentMethod_Delete(INT, VARCHAR(24)) CASCADE;
CREATE OR REPLACE FUNCTION usp_Store_PaymentMethod_Delete(
    p_payment_method_id INT          DEFAULT NULL,
    p_customer_code     VARCHAR(24)  DEFAULT NULL
)
RETURNS TABLE("Resultado" INT, "Mensaje" VARCHAR(500))
LANGUAGE plpgsql AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM master."CustomerPaymentMethod"
                  WHERE "PaymentMethodId" = p_payment_method_id AND "CustomerCode" = p_customer_code AND "IsDeleted" = FALSE) THEN
        RETURN QUERY SELECT -1, 'Metodo de pago no encontrado'::VARCHAR(500);
        RETURN;
    END IF;

    UPDATE master."CustomerPaymentMethod"
    SET "IsDeleted" = TRUE, "IsDefault" = FALSE, "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
    WHERE "PaymentMethodId" = p_payment_method_id AND "CustomerCode" = p_customer_code;

    RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);
END;
$$;
