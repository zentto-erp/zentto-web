/*
 * ============================================================================
 *  Archivo : usp_rest_admin.sql  (PostgreSQL)
 *  Esquema : rest (subsistema restaurante - tablas canonicas)
 *
 *  Descripcion:
 *    Funciones para el modulo administrativo del restaurante
 *    usando tablas canonicas (rest."MenuEnvironment", rest."MenuCategory",
 *    rest."MenuProduct", rest."MenuComponent", rest."MenuOption",
 *    rest."MenuRecipe", rest."Purchase", rest."PurchaseLine",
 *    master."Supplier", master."Product").
 * ============================================================================
 */

-- ============================================================================
-- HELPERS INTERNOS
-- ============================================================================

-- ============================================================================
-- usp_Rest_Admin_ResolveSupplier
-- ============================================================================
DROP FUNCTION IF EXISTS usp_rest_admin_resolvesupplier(INT, VARCHAR(30)) CASCADE;
CREATE OR REPLACE FUNCTION usp_rest_admin_resolvesupplier(
    p_company_id INT,
    p_key        VARCHAR(30)
)
RETURNS TABLE("supplierId" BIGINT)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT s."SupplierId"
    FROM master."Supplier" s
    WHERE s."CompanyId" = p_company_id
      AND s."IsDeleted" = FALSE
      AND s."IsActive" = TRUE
      AND (
          s."SupplierCode" = p_key
          OR s."SupplierId"::TEXT = p_key
      )
    ORDER BY s."SupplierId"
    LIMIT 1;
END;
$$;

-- ============================================================================
-- usp_Rest_Admin_ResolveProduct
-- ============================================================================
DROP FUNCTION IF EXISTS usp_rest_admin_resolveproduct(INT, VARCHAR(60)) CASCADE;
CREATE OR REPLACE FUNCTION usp_rest_admin_resolveproduct(
    p_company_id INT,
    p_key        VARCHAR(60)
)
RETURNS TABLE("productId" BIGINT)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT p."ProductId"
    FROM master."Product" p
    WHERE p."CompanyId" = p_company_id
      AND p."IsDeleted" = FALSE
      AND p."IsActive" = TRUE
      AND (
          p."ProductCode" = p_key
          OR p."ProductId"::TEXT = p_key
      )
    ORDER BY p."ProductId"
    LIMIT 1;
END;
$$;

-- ============================================================================
-- usp_Rest_Admin_ResolveMenuCategory
-- ============================================================================
DROP FUNCTION IF EXISTS usp_rest_admin_resolvemenucategory(INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_rest_admin_resolvemenucategory(
    p_menu_category_id INT
)
RETURNS TABLE("id" INT)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT mc."MenuCategoryId"
    FROM rest."MenuCategory" mc
    WHERE mc."MenuCategoryId" = p_menu_category_id
    LIMIT 1;
END;
$$;

-- ============================================================================
-- AMBIENTES
-- ============================================================================

DROP FUNCTION IF EXISTS usp_rest_admin_ambiente_list(INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_rest_admin_ambiente_list(
    p_company_id INT,
    p_branch_id  INT
)
RETURNS TABLE(
    "id"     INT,
    "nombre" VARCHAR,
    "color"  VARCHAR,
    "orden"  INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        me."MenuEnvironmentId",
        me."EnvironmentName",
        me."ColorHex",
        me."SortOrder"
    FROM rest."MenuEnvironment" me
    WHERE me."CompanyId" = p_company_id
      AND me."BranchId"  = p_branch_id
      AND me."IsActive"  = TRUE
    ORDER BY me."SortOrder", me."EnvironmentName";
END;
$$;

DROP FUNCTION IF EXISTS usp_rest_admin_ambiente_upsert(INT, INT, INT, VARCHAR(30), VARCHAR(100), VARCHAR(10), INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_rest_admin_ambiente_upsert(
    p_id         INT DEFAULT 0,
    p_company_id INT DEFAULT NULL,
    p_branch_id  INT DEFAULT NULL,
    p_code       VARCHAR(30) DEFAULT NULL,
    p_nombre     VARCHAR(100) DEFAULT NULL,
    p_color      VARCHAR(10) DEFAULT NULL,
    p_orden      INT DEFAULT 0,
    p_user_id    INT DEFAULT NULL
)
RETURNS TABLE("id" INT)
LANGUAGE plpgsql
AS $$
DECLARE
    v_id INT;
BEGIN
    IF p_id > 0 AND EXISTS (SELECT 1 FROM rest."MenuEnvironment" WHERE "MenuEnvironmentId" = p_id) THEN
        UPDATE rest."MenuEnvironment"
        SET "EnvironmentName" = p_nombre,
            "ColorHex" = p_color,
            "SortOrder" = p_orden,
            "UpdatedAt" = NOW() AT TIME ZONE 'UTC',
            "UpdatedByUserId" = p_user_id
        WHERE "MenuEnvironmentId" = p_id;

        RETURN QUERY SELECT p_id;
    ELSE
        INSERT INTO rest."MenuEnvironment" (
            "CompanyId", "BranchId", "EnvironmentCode", "EnvironmentName",
            "ColorHex", "SortOrder", "IsActive", "CreatedByUserId", "UpdatedByUserId"
        )
        VALUES (
            p_company_id, p_branch_id, p_code, p_nombre,
            p_color, p_orden, TRUE, p_user_id, p_user_id
        )
        RETURNING "MenuEnvironmentId" INTO v_id;

        RETURN QUERY SELECT v_id;
    END IF;
END;
$$;

-- ============================================================================
-- CATEGORIAS MENU
-- ============================================================================

DROP FUNCTION IF EXISTS usp_rest_admin_categoria_list(INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_rest_admin_categoria_list(
    p_company_id INT,
    p_branch_id  INT
)
RETURNS TABLE(
    "id"          INT,
    "nombre"      VARCHAR,
    "descripcion" VARCHAR,
    "color"       VARCHAR,
    "orden"       INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        mc."MenuCategoryId",
        mc."CategoryName",
        mc."DescriptionText",
        mc."ColorHex",
        mc."SortOrder"
    FROM rest."MenuCategory" mc
    WHERE mc."CompanyId" = p_company_id
      AND mc."BranchId"  = p_branch_id
      AND mc."IsActive"  = TRUE
    ORDER BY mc."SortOrder", mc."CategoryName";
END;
$$;

DROP FUNCTION IF EXISTS usp_rest_admin_categoria_upsert(INT, INT, INT, VARCHAR(30), VARCHAR(100), VARCHAR(500), VARCHAR(10), INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_rest_admin_categoria_upsert(
    p_id          INT DEFAULT 0,
    p_company_id  INT DEFAULT NULL,
    p_branch_id   INT DEFAULT NULL,
    p_code        VARCHAR(30) DEFAULT NULL,
    p_nombre      VARCHAR(100) DEFAULT NULL,
    p_descripcion VARCHAR(500) DEFAULT NULL,
    p_color       VARCHAR(10) DEFAULT NULL,
    p_orden       INT DEFAULT 0,
    p_user_id     INT DEFAULT NULL
)
RETURNS TABLE("id" INT)
LANGUAGE plpgsql
AS $$
DECLARE
    v_id INT;
BEGIN
    IF p_id > 0 AND EXISTS (SELECT 1 FROM rest."MenuCategory" WHERE "MenuCategoryId" = p_id) THEN
        UPDATE rest."MenuCategory"
        SET "CategoryName" = p_nombre,
            "DescriptionText" = p_descripcion,
            "ColorHex" = p_color,
            "SortOrder" = p_orden,
            "UpdatedAt" = NOW() AT TIME ZONE 'UTC',
            "UpdatedByUserId" = p_user_id
        WHERE "MenuCategoryId" = p_id;

        RETURN QUERY SELECT p_id;
    ELSE
        INSERT INTO rest."MenuCategory" (
            "CompanyId", "BranchId", "CategoryCode", "CategoryName",
            "DescriptionText", "ColorHex", "SortOrder", "IsActive",
            "CreatedByUserId", "UpdatedByUserId"
        )
        VALUES (
            p_company_id, p_branch_id, p_code, p_nombre,
            p_descripcion, p_color, p_orden, TRUE,
            p_user_id, p_user_id
        )
        RETURNING "MenuCategoryId" INTO v_id;

        RETURN QUERY SELECT v_id;
    END IF;
END;
$$;

-- ============================================================================
-- PRODUCTOS MENU
-- ============================================================================

DROP FUNCTION IF EXISTS usp_rest_admin_producto_list(INT, INT, INT, VARCHAR(100), BOOLEAN) CASCADE;
CREATE OR REPLACE FUNCTION usp_rest_admin_producto_list(
    p_company_id       INT,
    p_branch_id        INT,
    p_menu_category_id INT DEFAULT NULL,
    p_search           VARCHAR(100) DEFAULT NULL,
    p_solo_disponibles BOOLEAN DEFAULT TRUE
)
RETURNS TABLE(
    "id"                   INT,
    "codigo"               VARCHAR,
    "nombre"               VARCHAR,
    "descripcion"          VARCHAR,
    "categoriaId"          INT,
    "categoriaNombre"      VARCHAR,
    "precio"               NUMERIC,
    "costoEstimado"        NUMERIC,
    "iva"                  NUMERIC,
    "esCompuesto"          BOOLEAN,
    "tiempoPreparacion"    INT,
    "imagen"               VARCHAR,
    "esSugerenciaDelDia"   BOOLEAN,
    "disponible"           BOOLEAN,
    "articuloInventarioId" VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        mp."MenuProductId",
        mp."ProductCode",
        mp."ProductName",
        mp."DescriptionText",
        mp."MenuCategoryId",
        mc."CategoryName",
        mp."PriceAmount",
        mp."EstimatedCost",
        mp."TaxRatePercent",
        mp."IsComposite",
        mp."PrepMinutes",
        COALESCE(img."PublicUrl", mp."ImageUrl"),
        mp."IsDailySuggestion",
        mp."IsAvailable",
        inv."ProductCode"
    FROM rest."MenuProduct" mp
    LEFT JOIN rest."MenuCategory" mc ON mc."MenuCategoryId" = mp."MenuCategoryId"
    LEFT JOIN master."Product" inv ON inv."ProductId" = mp."InventoryProductId"
    LEFT JOIN LATERAL (
        SELECT ma."PublicUrl"
        FROM cfg."EntityImage" ei
        INNER JOIN cfg."MediaAsset" ma ON ma."MediaAssetId" = ei."MediaAssetId"
        WHERE ei."CompanyId" = mp."CompanyId"
          AND ei."BranchId" = mp."BranchId"
          AND ei."EntityType" = 'REST_MENU_PRODUCT'
          AND ei."EntityId" = mp."MenuProductId"
          AND ei."IsDeleted" = FALSE AND ei."IsActive" = TRUE
          AND ma."IsDeleted" = FALSE AND ma."IsActive" = TRUE
        ORDER BY CASE WHEN ei."IsPrimary" = TRUE THEN 0 ELSE 1 END, ei."SortOrder", ei."EntityImageId"
        LIMIT 1
    ) img ON TRUE
    WHERE mp."CompanyId" = p_company_id
      AND mp."BranchId"  = p_branch_id
      AND mp."IsActive" = TRUE
      AND (p_solo_disponibles = FALSE OR mp."IsAvailable" = TRUE)
      AND (p_menu_category_id IS NULL OR mp."MenuCategoryId" = p_menu_category_id)
      AND (p_search IS NULL OR mp."ProductCode" LIKE p_search OR mp."ProductName" LIKE p_search)
    ORDER BY mp."ProductName";
END;
$$;

DROP FUNCTION IF EXISTS usp_rest_admin_producto_get(INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_rest_admin_producto_get(
    p_id        INT,
    p_branch_id INT
)
RETURNS TABLE(
    "id"                   INT,
    "codigo"               VARCHAR,
    "nombre"               VARCHAR,
    "descripcion"          VARCHAR,
    "categoriaId"          INT,
    "precio"               NUMERIC,
    "costoEstimado"        NUMERIC,
    "iva"                  NUMERIC,
    "esCompuesto"          BOOLEAN,
    "tiempoPreparacion"    INT,
    "imagen"               VARCHAR,
    "esSugerenciaDelDia"   BOOLEAN,
    "disponible"           BOOLEAN,
    "articuloInventarioId" VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Resultset 1: producto
    RETURN QUERY
    SELECT
        mp."MenuProductId",
        mp."ProductCode",
        mp."ProductName",
        mp."DescriptionText",
        mp."MenuCategoryId",
        mp."PriceAmount",
        mp."EstimatedCost",
        mp."TaxRatePercent",
        mp."IsComposite",
        mp."PrepMinutes",
        COALESCE(img."PublicUrl", mp."ImageUrl"),
        mp."IsDailySuggestion",
        mp."IsAvailable",
        inv."ProductCode"
    FROM rest."MenuProduct" mp
    LEFT JOIN master."Product" inv ON inv."ProductId" = mp."InventoryProductId"
    LEFT JOIN LATERAL (
        SELECT ma."PublicUrl"
        FROM cfg."EntityImage" ei
        INNER JOIN cfg."MediaAsset" ma ON ma."MediaAssetId" = ei."MediaAssetId"
        WHERE ei."CompanyId" = mp."CompanyId"
          AND ei."BranchId" = mp."BranchId"
          AND ei."EntityType" = 'REST_MENU_PRODUCT'
          AND ei."EntityId" = mp."MenuProductId"
          AND ei."IsDeleted" = FALSE AND ei."IsActive" = TRUE
          AND ma."IsDeleted" = FALSE AND ma."IsActive" = TRUE
        ORDER BY CASE WHEN ei."IsPrimary" = TRUE THEN 0 ELSE 1 END, ei."SortOrder", ei."EntityImageId"
        LIMIT 1
    ) img ON TRUE
    WHERE mp."MenuProductId" = p_id
      AND mp."IsActive" = TRUE
    LIMIT 1;
END;
$$;

-- Nota: los resultsets 2 y 3 del GET original se separan en funciones individuales
DROP FUNCTION IF EXISTS usp_rest_admin_producto_get_componentes(INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_rest_admin_producto_get_componentes(
    p_id INT
)
RETURNS TABLE(
    "id"           INT,
    "nombre"       VARCHAR,
    "obligatorio"  BOOLEAN,
    "orden"        INT,
    "opcionId"     INT,
    "opcionNombre" VARCHAR,
    "precioExtra"  NUMERIC,
    "opcionOrden"  INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        c."MenuComponentId",
        c."ComponentName",
        c."IsRequired",
        c."SortOrder",
        o."MenuOptionId",
        o."OptionName",
        o."ExtraPrice",
        o."SortOrder"
    FROM rest."MenuComponent" c
    LEFT JOIN rest."MenuOption" o
      ON o."MenuComponentId" = c."MenuComponentId"
     AND o."IsActive" = TRUE
    WHERE c."MenuProductId" = p_id
      AND c."IsActive" = TRUE
    ORDER BY c."SortOrder", c."MenuComponentId", o."SortOrder", o."MenuOptionId";
END;
$$;

DROP FUNCTION IF EXISTS usp_rest_admin_producto_get_receta(INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_rest_admin_producto_get_receta(
    p_id        INT,
    p_branch_id INT
)
RETURNS TABLE(
    "id"          INT,
    "productoId"  INT,
    "inventarioId" VARCHAR,
    "descripcion" VARCHAR,
    "imagen"      VARCHAR,
    "cantidad"    NUMERIC,
    "unidad"      VARCHAR,
    "comentario"  VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        r."MenuRecipeId",
        r."MenuProductId",
        p."ProductCode",
        p."ProductName",
        img."PublicUrl",
        r."Quantity",
        r."UnitCode",
        r."Notes"
    FROM rest."MenuRecipe" r
    INNER JOIN master."Product" p ON p."ProductId" = r."IngredientProductId"
    LEFT JOIN LATERAL (
        SELECT ma."PublicUrl"
        FROM cfg."EntityImage" ei
        INNER JOIN cfg."MediaAsset" ma ON ma."MediaAssetId" = ei."MediaAssetId"
        WHERE ei."CompanyId" = p."CompanyId"
          AND ei."BranchId" = p_branch_id
          AND ei."EntityType" = 'MASTER_PRODUCT'
          AND ei."EntityId" = p."ProductId"
          AND ei."IsDeleted" = FALSE AND ei."IsActive" = TRUE
          AND ma."IsDeleted" = FALSE AND ma."IsActive" = TRUE
        ORDER BY CASE WHEN ei."IsPrimary" = TRUE THEN 0 ELSE 1 END, ei."SortOrder", ei."EntityImageId"
        LIMIT 1
    ) img ON TRUE
    WHERE r."MenuProductId" = p_id
      AND r."IsActive" = TRUE
    ORDER BY r."MenuRecipeId";
END;
$$;

DROP FUNCTION IF EXISTS usp_rest_admin_producto_upsert(INT, INT, INT, VARCHAR(20), VARCHAR(200), VARCHAR(500), INT, NUMERIC(18,2), NUMERIC(18,2), NUMERIC(5,2), BOOLEAN, INT, VARCHAR(500), BOOLEAN, BOOLEAN, INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_rest_admin_producto_upsert(
    p_id                   INT DEFAULT 0,
    p_company_id           INT DEFAULT NULL,
    p_branch_id            INT DEFAULT NULL,
    p_code                 VARCHAR(20) DEFAULT NULL,
    p_name                 VARCHAR(200) DEFAULT NULL,
    p_description          VARCHAR(500) DEFAULT NULL,
    p_menu_category_id     INT DEFAULT NULL,
    p_price                NUMERIC(18,2) DEFAULT 0,
    p_estimated_cost       NUMERIC(18,2) DEFAULT 0,
    p_tax_rate_percent     NUMERIC(5,2) DEFAULT 16,
    p_is_composite         BOOLEAN DEFAULT FALSE,
    p_prep_minutes         INT DEFAULT 0,
    p_image_url            VARCHAR(500) DEFAULT NULL,
    p_is_daily_suggestion  BOOLEAN DEFAULT FALSE,
    p_is_available         BOOLEAN DEFAULT TRUE,
    p_inventory_product_id INT DEFAULT NULL,
    p_user_id              INT DEFAULT NULL
)
RETURNS TABLE("id" INT)
LANGUAGE plpgsql
AS $$
DECLARE
    v_id INT;
BEGIN
    IF p_id > 0 AND EXISTS (SELECT 1 FROM rest."MenuProduct" WHERE "MenuProductId" = p_id) THEN
        UPDATE rest."MenuProduct"
        SET "ProductCode" = p_code,
            "ProductName" = p_name,
            "DescriptionText" = p_description,
            "MenuCategoryId" = p_menu_category_id,
            "PriceAmount" = p_price,
            "EstimatedCost" = p_estimated_cost,
            "TaxRatePercent" = p_tax_rate_percent,
            "IsComposite" = p_is_composite,
            "PrepMinutes" = p_prep_minutes,
            "ImageUrl" = p_image_url,
            "IsDailySuggestion" = p_is_daily_suggestion,
            "IsAvailable" = p_is_available,
            "InventoryProductId" = p_inventory_product_id,
            "UpdatedAt" = NOW() AT TIME ZONE 'UTC',
            "UpdatedByUserId" = p_user_id
        WHERE "MenuProductId" = p_id;

        RETURN QUERY SELECT p_id;
    ELSE
        INSERT INTO rest."MenuProduct" (
            "CompanyId", "BranchId", "ProductCode", "ProductName", "DescriptionText",
            "MenuCategoryId", "PriceAmount", "EstimatedCost", "TaxRatePercent",
            "IsComposite", "PrepMinutes", "ImageUrl", "IsDailySuggestion",
            "IsAvailable", "InventoryProductId", "IsActive",
            "CreatedByUserId", "UpdatedByUserId"
        )
        VALUES (
            p_company_id, p_branch_id, p_code, p_name, p_description,
            p_menu_category_id, p_price, p_estimated_cost, p_tax_rate_percent,
            p_is_composite, p_prep_minutes, p_image_url, p_is_daily_suggestion,
            p_is_available, p_inventory_product_id, TRUE,
            p_user_id, p_user_id
        )
        RETURNING "MenuProductId" INTO v_id;

        RETURN QUERY SELECT v_id;
    END IF;
END;
$$;

DROP FUNCTION IF EXISTS usp_rest_admin_producto_delete(INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_rest_admin_producto_delete(
    p_id INT
)
RETURNS VOID
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE rest."MenuProduct"
    SET "IsActive" = FALSE,
        "IsAvailable" = FALSE,
        "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
    WHERE "MenuProductId" = p_id;
END;
$$;

-- ============================================================================
-- COMPONENTES / OPCIONES
-- ============================================================================

DROP FUNCTION IF EXISTS usp_rest_admin_componente_upsert(INT, INT, VARCHAR(100), BOOLEAN, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_rest_admin_componente_upsert(
    p_id           INT DEFAULT 0,
    p_producto_id  INT DEFAULT NULL,
    p_nombre       VARCHAR(100) DEFAULT NULL,
    p_obligatorio  BOOLEAN DEFAULT FALSE,
    p_orden        INT DEFAULT 0
)
RETURNS TABLE("id" INT)
LANGUAGE plpgsql
AS $$
DECLARE
    v_id INT;
BEGIN
    IF p_id > 0 AND EXISTS (SELECT 1 FROM rest."MenuComponent" WHERE "MenuComponentId" = p_id) THEN
        UPDATE rest."MenuComponent"
        SET "ComponentName" = p_nombre,
            "IsRequired" = p_obligatorio,
            "SortOrder" = p_orden,
            "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
        WHERE "MenuComponentId" = p_id;

        RETURN QUERY SELECT p_id;
    ELSE
        INSERT INTO rest."MenuComponent" (
            "MenuProductId", "ComponentName", "IsRequired", "SortOrder", "IsActive"
        )
        VALUES (p_producto_id, p_nombre, p_obligatorio, p_orden, TRUE)
        RETURNING "MenuComponentId" INTO v_id;

        RETURN QUERY SELECT v_id;
    END IF;
END;
$$;

DROP FUNCTION IF EXISTS usp_rest_admin_opcion_upsert(INT, INT, VARCHAR(100), NUMERIC(18,2), INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_rest_admin_opcion_upsert(
    p_id            INT DEFAULT 0,
    p_componente_id INT DEFAULT NULL,
    p_nombre        VARCHAR(100) DEFAULT NULL,
    p_precio_extra  NUMERIC(18,2) DEFAULT 0,
    p_orden         INT DEFAULT 0
)
RETURNS TABLE("id" INT)
LANGUAGE plpgsql
AS $$
DECLARE
    v_id INT;
BEGIN
    IF p_id > 0 AND EXISTS (SELECT 1 FROM rest."MenuOption" WHERE "MenuOptionId" = p_id) THEN
        UPDATE rest."MenuOption"
        SET "OptionName" = p_nombre,
            "ExtraPrice" = p_precio_extra,
            "SortOrder" = p_orden,
            "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
        WHERE "MenuOptionId" = p_id;

        RETURN QUERY SELECT p_id;
    ELSE
        INSERT INTO rest."MenuOption" (
            "MenuComponentId", "OptionName", "ExtraPrice", "SortOrder", "IsActive"
        )
        VALUES (p_componente_id, p_nombre, p_precio_extra, p_orden, TRUE)
        RETURNING "MenuOptionId" INTO v_id;

        RETURN QUERY SELECT v_id;
    END IF;
END;
$$;

-- ============================================================================
-- RECETAS
-- ============================================================================

DROP FUNCTION IF EXISTS usp_rest_admin_receta_upsert(INT, INT, INT, NUMERIC(10,3), VARCHAR(20), VARCHAR(200)) CASCADE;
CREATE OR REPLACE FUNCTION usp_rest_admin_receta_upsert(
    p_id                    INT DEFAULT 0,
    p_producto_id           INT DEFAULT NULL,
    p_ingredient_product_id INT DEFAULT NULL,
    p_quantity              NUMERIC(10,3) DEFAULT NULL,
    p_unit_code             VARCHAR(20) DEFAULT NULL,
    p_notes                 VARCHAR(200) DEFAULT NULL
)
RETURNS TABLE("id" INT)
LANGUAGE plpgsql
AS $$
DECLARE
    v_id INT;
BEGIN
    IF p_id > 0 AND EXISTS (SELECT 1 FROM rest."MenuRecipe" WHERE "MenuRecipeId" = p_id) THEN
        UPDATE rest."MenuRecipe"
        SET "IngredientProductId" = p_ingredient_product_id,
            "Quantity" = p_quantity,
            "UnitCode" = p_unit_code,
            "Notes" = p_notes,
            "IsActive" = TRUE,
            "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
        WHERE "MenuRecipeId" = p_id;

        RETURN QUERY SELECT p_id;
    ELSE
        INSERT INTO rest."MenuRecipe" (
            "MenuProductId", "IngredientProductId", "Quantity", "UnitCode", "Notes", "IsActive"
        )
        VALUES (p_producto_id, p_ingredient_product_id, p_quantity, p_unit_code, p_notes, TRUE)
        RETURNING "MenuRecipeId" INTO v_id;

        RETURN QUERY SELECT v_id;
    END IF;
END;
$$;

DROP FUNCTION IF EXISTS usp_rest_admin_receta_delete(INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_rest_admin_receta_delete(
    p_id INT
)
RETURNS VOID
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE rest."MenuRecipe"
    SET "IsActive" = FALSE,
        "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
    WHERE "MenuRecipeId" = p_id;
END;
$$;

-- ============================================================================
-- COMPRAS
-- ============================================================================

DROP FUNCTION IF EXISTS usp_rest_admin_compra_list(INT, INT, VARCHAR, TIMESTAMP, TIMESTAMP) CASCADE;
CREATE OR REPLACE FUNCTION usp_rest_admin_compra_list(
    p_company_id INT,
    p_branch_id  INT,
    p_status     VARCHAR(20) DEFAULT NULL,
    p_from_date  TIMESTAMP DEFAULT NULL,
    p_to_date    TIMESTAMP DEFAULT NULL
)
RETURNS TABLE(
    "id"                INT,
    "numCompra"         VARCHAR,
    "proveedorId"       VARCHAR,
    "proveedorNombre"   VARCHAR,
    "fechaCompra"       TIMESTAMP,
    "estado"            VARCHAR,
    "subtotal"          NUMERIC,
    "iva"               NUMERIC,
    "total"             NUMERIC,
    "observaciones"     VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        p."PurchaseId",
        p."PurchaseNumber",
        s."SupplierCode",
        s."SupplierName",
        p."PurchaseDate",
        p."Status",
        p."SubtotalAmount",
        p."TaxAmount",
        p."TotalAmount",
        p."Notes"
    FROM rest."Purchase" p
    LEFT JOIN master."Supplier" s ON s."SupplierId" = p."SupplierId"
    WHERE p."CompanyId" = p_company_id
      AND p."BranchId"  = p_branch_id
      AND (p_status IS NULL OR p."Status" = p_status)
      AND (p_from_date IS NULL OR p."PurchaseDate" >= p_from_date)
      AND (p_to_date IS NULL OR p."PurchaseDate" <= p_to_date)
    ORDER BY p."PurchaseDate" DESC, p."PurchaseId" DESC;
END;
$$;

DROP FUNCTION IF EXISTS usp_rest_admin_compra_getdetalle_header(INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_rest_admin_compra_getdetalle_header(
    p_compra_id INT
)
RETURNS TABLE(
    "id"                INT,
    "numCompra"         VARCHAR,
    "proveedorId"       VARCHAR,
    "proveedorNombre"   VARCHAR,
    "fechaCompra"       TIMESTAMP,
    "estado"            VARCHAR,
    "subtotal"          NUMERIC,
    "iva"               NUMERIC,
    "total"             NUMERIC,
    "observaciones"     VARCHAR,
    "codUsuario"        VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        p."PurchaseId",
        p."PurchaseNumber",
        s."SupplierCode",
        s."SupplierName",
        p."PurchaseDate",
        p."Status",
        p."SubtotalAmount",
        p."TaxAmount",
        p."TotalAmount",
        p."Notes",
        u."UserCode"
    FROM rest."Purchase" p
    LEFT JOIN master."Supplier" s ON s."SupplierId" = p."SupplierId"
    LEFT JOIN sec."User" u ON u."UserId" = p."CreatedByUserId"
    WHERE p."PurchaseId" = p_compra_id
    LIMIT 1;
END;
$$;

DROP FUNCTION IF EXISTS usp_rest_admin_compra_getdetalle_lines(INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_rest_admin_compra_getdetalle_lines(
    p_compra_id INT
)
RETURNS TABLE(
    "id"           INT,
    "compraId"     INT,
    "inventarioId" VARCHAR,
    "descripcion"  VARCHAR,
    "cantidad"     NUMERIC,
    "precioUnit"   NUMERIC,
    "subtotal"     NUMERIC,
    "iva"          NUMERIC
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        pl."PurchaseLineId",
        pl."PurchaseId",
        pr."ProductCode",
        pl."DescriptionText",
        pl."Quantity",
        pl."UnitPrice",
        pl."SubtotalAmount",
        pl."TaxRatePercent"
    FROM rest."PurchaseLine" pl
    LEFT JOIN master."Product" pr ON pr."ProductId" = pl."IngredientProductId"
    WHERE pl."PurchaseId" = p_compra_id
    ORDER BY pl."PurchaseLineId";
END;
$$;

DROP FUNCTION IF EXISTS usp_rest_admin_compra_getnextseq(INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_rest_admin_compra_getnextseq(
    p_company_id INT,
    p_branch_id  INT
)
RETURNS TABLE("seq" BIGINT)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT COALESCE(MAX(p."PurchaseId"), 0) + 1
    FROM rest."Purchase" p
    WHERE p."CompanyId" = p_company_id
      AND p."BranchId"  = p_branch_id;
END;
$$;

DROP FUNCTION IF EXISTS usp_rest_admin_compra_insert(INT, INT, VARCHAR(20), INT, VARCHAR(500), INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_rest_admin_compra_insert(
    p_company_id      INT,
    p_branch_id       INT,
    p_purchase_number VARCHAR(20),
    p_supplier_id     INT DEFAULT NULL,
    p_notes           VARCHAR(500) DEFAULT NULL,
    p_user_id         INT DEFAULT NULL
)
RETURNS TABLE("id" INT)
LANGUAGE plpgsql
AS $$
DECLARE
    v_id INT;
BEGIN
    INSERT INTO rest."Purchase" (
        "CompanyId", "BranchId", "PurchaseNumber", "SupplierId",
        "PurchaseDate", "Status", "Notes", "CreatedByUserId", "UpdatedByUserId"
    )
    VALUES (
        p_company_id, p_branch_id, p_purchase_number, p_supplier_id,
        NOW() AT TIME ZONE 'UTC', 'PENDIENTE', p_notes, p_user_id, p_user_id
    )
    RETURNING "PurchaseId" INTO v_id;

    RETURN QUERY SELECT v_id;
END;
$$;

DROP FUNCTION IF EXISTS usp_rest_admin_compra_update(INT, INT, VARCHAR(20), VARCHAR(500)) CASCADE;
CREATE OR REPLACE FUNCTION usp_rest_admin_compra_update(
    p_compra_id   INT,
    p_supplier_id INT DEFAULT NULL,
    p_status      VARCHAR(20) DEFAULT NULL,
    p_notes       VARCHAR(500) DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE rest."Purchase"
    SET "SupplierId" = COALESCE(p_supplier_id, "SupplierId"),
        "Status"     = COALESCE(p_status, "Status"),
        "Notes"      = COALESCE(p_notes, "Notes"),
        "UpdatedAt"  = NOW() AT TIME ZONE 'UTC'
    WHERE "PurchaseId" = p_compra_id;
END;
$$;

DROP FUNCTION IF EXISTS usp_rest_admin_compralinea_getprev(INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_rest_admin_compralinea_getprev(
    p_id        INT,
    p_compra_id INT
)
RETURNS TABLE("ingredientProductId" INT, "quantity" NUMERIC)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT pl."IngredientProductId", pl."Quantity"
    FROM rest."PurchaseLine" pl
    WHERE pl."PurchaseLineId" = p_id
      AND pl."PurchaseId" = p_compra_id
    LIMIT 1;
END;
$$;

DROP FUNCTION IF EXISTS usp_rest_admin_compralinea_upsert(INT, INT, INT, VARCHAR(200), NUMERIC(10,3), NUMERIC(18,2), NUMERIC(5,2), NUMERIC(18,2)) CASCADE;
CREATE OR REPLACE FUNCTION usp_rest_admin_compralinea_upsert(
    p_id                    INT DEFAULT 0,
    p_compra_id             INT DEFAULT NULL,
    p_ingredient_product_id INT DEFAULT NULL,
    p_descripcion           VARCHAR(200) DEFAULT NULL,
    p_quantity              NUMERIC(10,3) DEFAULT NULL,
    p_unit_price            NUMERIC(18,2) DEFAULT NULL,
    p_tax_rate_percent      NUMERIC(5,2) DEFAULT 16,
    p_subtotal              NUMERIC(18,2) DEFAULT NULL
)
RETURNS TABLE("id" INT)
LANGUAGE plpgsql
AS $$
DECLARE
    v_id INT;
BEGIN
    IF p_id > 0 THEN
        UPDATE rest."PurchaseLine"
        SET "IngredientProductId" = p_ingredient_product_id,
            "DescriptionText" = p_descripcion,
            "Quantity" = p_quantity,
            "UnitPrice" = p_unit_price,
            "TaxRatePercent" = p_tax_rate_percent,
            "SubtotalAmount" = p_subtotal,
            "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
        WHERE "PurchaseLineId" = p_id
          AND "PurchaseId" = p_compra_id;

        RETURN QUERY SELECT p_id;
    ELSE
        INSERT INTO rest."PurchaseLine" (
            "PurchaseId", "IngredientProductId", "DescriptionText",
            "Quantity", "UnitPrice", "TaxRatePercent", "SubtotalAmount"
        )
        VALUES (
            p_compra_id, p_ingredient_product_id, p_descripcion,
            p_quantity, p_unit_price, p_tax_rate_percent, p_subtotal
        )
        RETURNING "PurchaseLineId" INTO v_id;

        RETURN QUERY SELECT v_id;
    END IF;
END;
$$;

DROP FUNCTION IF EXISTS usp_rest_admin_compralinea_delete(INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_rest_admin_compralinea_delete(
    p_compra_id  INT,
    p_detalle_id INT
)
RETURNS TABLE("ingredientProductId" INT, "quantity" NUMERIC)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Devolver datos previos antes de borrar
    RETURN QUERY
    SELECT pl."IngredientProductId", pl."Quantity"
    FROM rest."PurchaseLine" pl
    WHERE pl."PurchaseLineId" = p_detalle_id
      AND pl."PurchaseId" = p_compra_id
    LIMIT 1;

    DELETE FROM rest."PurchaseLine"
    WHERE "PurchaseLineId" = p_detalle_id
      AND "PurchaseId" = p_compra_id;
END;
$$;

DROP FUNCTION IF EXISTS usp_rest_admin_compra_recalctotals(INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_rest_admin_compra_recalctotals(
    p_purchase_id INT
)
RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
    v_subtotal NUMERIC(18,2);
    v_tax      NUMERIC(18,2);
    v_total    NUMERIC(18,2);
BEGIN
    SELECT
        COALESCE(SUM("SubtotalAmount"), 0),
        COALESCE(SUM("SubtotalAmount" * "TaxRatePercent" / 100.0), 0),
        COALESCE(SUM("SubtotalAmount" + ("SubtotalAmount" * "TaxRatePercent" / 100.0)), 0)
    INTO v_subtotal, v_tax, v_total
    FROM rest."PurchaseLine"
    WHERE "PurchaseId" = p_purchase_id;

    UPDATE rest."Purchase"
    SET "SubtotalAmount" = v_subtotal,
        "TaxAmount"      = v_tax,
        "TotalAmount"    = v_total,
        "UpdatedAt"      = NOW() AT TIME ZONE 'UTC'
    WHERE "PurchaseId" = p_purchase_id;
END;
$$;

DROP FUNCTION IF EXISTS usp_rest_admin_adjuststock(INT, NUMERIC(18,4)) CASCADE;
CREATE OR REPLACE FUNCTION usp_rest_admin_adjuststock(
    p_product_id INT,
    p_delta_qty  NUMERIC(18,4)
)
RETURNS VOID
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_product_id IS NULL OR p_delta_qty = 0 THEN
        RETURN;
    END IF;

    UPDATE master."Product"
    SET "StockQty" = COALESCE("StockQty", 0) + p_delta_qty,
        "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
    WHERE "ProductId" = p_product_id;
END;
$$;

-- ============================================================================
-- SYNC IMAGE LINK
-- ============================================================================

DROP FUNCTION IF EXISTS usp_rest_admin_syncmenuproductimage(INT, INT, INT, VARCHAR(500), INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_rest_admin_syncmenuproductimage(
    p_company_id      INT,
    p_branch_id       INT,
    p_menu_product_id INT,
    p_storage_key     VARCHAR(500),
    p_user_id         INT DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
    v_media_asset_id INT;
BEGIN
    IF p_storage_key IS NULL OR LENGTH(p_storage_key) = 0 THEN
        RETURN;
    END IF;

    SELECT "MediaAssetId" INTO v_media_asset_id
    FROM cfg."MediaAsset"
    WHERE "CompanyId" = p_company_id
      AND "BranchId"  = p_branch_id
      AND "StorageKey" = p_storage_key
      AND "IsDeleted" = FALSE
      AND "IsActive" = TRUE
    ORDER BY "MediaAssetId" DESC
    LIMIT 1;

    IF v_media_asset_id IS NULL THEN
        RETURN;
    END IF;

    -- Quitar primary de todos
    UPDATE cfg."EntityImage"
    SET "IsPrimary" = FALSE,
        "UpdatedAt" = NOW() AT TIME ZONE 'UTC',
        "UpdatedByUserId" = p_user_id
    WHERE "CompanyId" = p_company_id
      AND "BranchId"  = p_branch_id
      AND "EntityType" = 'REST_MENU_PRODUCT'
      AND "EntityId"   = p_menu_product_id
      AND "IsDeleted"  = FALSE
      AND "IsActive"   = TRUE;

    IF EXISTS (
        SELECT 1 FROM cfg."EntityImage"
        WHERE "CompanyId" = p_company_id
          AND "BranchId"  = p_branch_id
          AND "EntityType" = 'REST_MENU_PRODUCT'
          AND "EntityId"   = p_menu_product_id
          AND "MediaAssetId" = v_media_asset_id
    ) THEN
        UPDATE cfg."EntityImage"
        SET "IsPrimary" = TRUE,
            "SortOrder" = 0,
            "IsActive"  = TRUE,
            "IsDeleted" = FALSE,
            "UpdatedAt" = NOW() AT TIME ZONE 'UTC',
            "UpdatedByUserId" = p_user_id
        WHERE "CompanyId" = p_company_id
          AND "BranchId"  = p_branch_id
          AND "EntityType" = 'REST_MENU_PRODUCT'
          AND "EntityId"   = p_menu_product_id
          AND "MediaAssetId" = v_media_asset_id;
    ELSE
        INSERT INTO cfg."EntityImage" (
            "CompanyId", "BranchId", "EntityType", "EntityId", "MediaAssetId",
            "SortOrder", "IsPrimary", "CreatedByUserId", "UpdatedByUserId"
        )
        VALUES (
            p_company_id, p_branch_id, 'REST_MENU_PRODUCT', p_menu_product_id, v_media_asset_id,
            0, TRUE, p_user_id, p_user_id
        );
    END IF;
END;
$$;

-- ============================================================================
-- BUSQUEDA DE PROVEEDORES
-- ============================================================================

DROP FUNCTION IF EXISTS usp_rest_admin_proveedor_search(INT, VARCHAR(100), INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_rest_admin_proveedor_search(
    p_company_id INT,
    p_search     VARCHAR(100) DEFAULT NULL,
    p_limit      INT DEFAULT 20
)
RETURNS TABLE(
    "id"        BIGINT,
    "codigo"    VARCHAR,
    "nombre"    VARCHAR,
    "rif"       VARCHAR,
    "telefono"  VARCHAR,
    "direccion" VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        s."SupplierId",
        s."SupplierCode",
        s."SupplierName",
        s."FiscalId",
        s."Phone",
        s."AddressLine"
    FROM master."Supplier" s
    WHERE s."CompanyId" = p_company_id
      AND s."IsDeleted" = FALSE
      AND s."IsActive" = TRUE
      AND (
          p_search IS NULL
          OR s."SupplierCode" LIKE p_search
          OR s."SupplierName" LIKE p_search
          OR s."FiscalId" LIKE p_search
      )
    ORDER BY s."SupplierName"
    LIMIT p_limit;
END;
$$;

-- ============================================================================
-- BUSQUEDA DE INSUMOS
-- ============================================================================

DROP FUNCTION IF EXISTS usp_rest_admin_insumo_search(INT, INT, VARCHAR(100), INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_rest_admin_insumo_search(
    p_company_id INT,
    p_branch_id  INT,
    p_search     VARCHAR(100) DEFAULT NULL,
    p_limit      INT DEFAULT 30
)
RETURNS TABLE(
    "codigo"     VARCHAR,
    "descripcion" VARCHAR,
    "imagen"     VARCHAR,
    "unidad"     VARCHAR,
    "existencia" NUMERIC
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        p."ProductCode",
        p."ProductName",
        img."PublicUrl",
        p."UnitCode",
        p."StockQty"
    FROM master."Product" p
    LEFT JOIN LATERAL (
        SELECT ma."PublicUrl"
        FROM cfg."EntityImage" ei
        INNER JOIN cfg."MediaAsset" ma ON ma."MediaAssetId" = ei."MediaAssetId"
        WHERE ei."CompanyId" = p."CompanyId"
          AND ei."BranchId" = p_branch_id
          AND ei."EntityType" = 'MASTER_PRODUCT'
          AND ei."EntityId" = p."ProductId"
          AND ei."IsDeleted" = FALSE AND ei."IsActive" = TRUE
          AND ma."IsDeleted" = FALSE AND ma."IsActive" = TRUE
        ORDER BY CASE WHEN ei."IsPrimary" = TRUE THEN 0 ELSE 1 END, ei."SortOrder", ei."EntityImageId"
        LIMIT 1
    ) img ON TRUE
    WHERE p."CompanyId" = p_company_id
      AND p."IsDeleted" = FALSE
      AND p."IsActive" = TRUE
      AND (
          p_search IS NULL
          OR p."ProductCode" LIKE p_search
          OR p."ProductName" LIKE p_search
      )
    ORDER BY p."ProductCode"
    LIMIT p_limit;
END;
$$;

-- Verificacion
DO $$ BEGIN RAISE NOTICE 'SPs administrativos restaurante (tablas canonicas) creados exitosamente.'; END $$;
