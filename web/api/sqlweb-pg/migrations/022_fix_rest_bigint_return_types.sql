-- =============================================================================
--  Migración 022: Corregir tipos BIGINT en funciones restaurante
--  Motivo: Las tablas rest.* usan BIGINT GENERATED ALWAYS AS IDENTITY para
--          sus PKs (DiningTableId, MenuEnvironmentId, MenuCategoryId,
--          MenuProductId, PurchaseId, PurchaseLineId) pero las funciones
--          declaraban RETURNS TABLE("id" INT), causando error runtime:
--          "returned type bigint does not match expected type integer".
--          Esto impedía que listMesas, listAmbientes, listCategorias,
--          listProductos y listCompras funcionaran después de que
--          usp_cfg_scope_getdefault fue añadido (migración 020).
-- =============================================================================

\echo '  [022] Fix BIGINT en usp_rest_diningtable_list...'

DROP FUNCTION IF EXISTS usp_rest_diningtable_list(INT, INT, VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS usp_rest_diningtable_list(INT, INT, VARCHAR(50)) CASCADE;
CREATE OR REPLACE FUNCTION usp_rest_diningtable_list(
    p_company_id  INT,
    p_branch_id   INT,
    p_ambiente_id VARCHAR DEFAULT NULL
)
RETURNS TABLE(
    "id" BIGINT, "numero" VARCHAR, "nombre" VARCHAR, "capacidad" INT,
    "ambienteId" VARCHAR, "ambiente" VARCHAR,
    "posicionX" NUMERIC, "posicionY" NUMERIC, "estado" VARCHAR
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        dt."DiningTableId",
        dt."TableNumber",
        COALESCE(NULLIF(dt."TableName", ''), 'Mesa ' || dt."TableNumber")::VARCHAR,
        dt."Capacity",
        dt."EnvironmentCode",
        dt."EnvironmentName",
        dt."PositionX",
        dt."PositionY",
        CASE
            WHEN EXISTS (
                SELECT 1 FROM rest."OrderTicket" o
                WHERE o."CompanyId" = dt."CompanyId" AND o."BranchId" = dt."BranchId"
                  AND o."TableNumber" = dt."TableNumber" AND o."Status" IN ('OPEN', 'SENT')
            ) THEN 'ocupada'::VARCHAR
            ELSE 'libre'::VARCHAR
        END
    FROM rest."DiningTable" dt
    WHERE dt."CompanyId" = p_company_id AND dt."BranchId" = p_branch_id AND dt."IsActive" = TRUE
      AND (p_ambiente_id IS NULL OR dt."EnvironmentCode" = p_ambiente_id)
    ORDER BY dt."EnvironmentCode", dt."TableNumber"::INT, dt."TableNumber";
END;
$$;

GRANT EXECUTE ON FUNCTION usp_rest_diningtable_list(INT, INT, VARCHAR) TO zentto_app;

\echo '  [022] Fix BIGINT en usp_rest_diningtable_getbyid...'

DROP FUNCTION IF EXISTS usp_rest_diningtable_getbyid(INT, INT, INT) CASCADE;
DROP FUNCTION IF EXISTS usp_rest_diningtable_getbyid(INT, INT, BIGINT) CASCADE;
CREATE OR REPLACE FUNCTION usp_rest_diningtable_getbyid(
    p_company_id INT,
    p_branch_id  INT,
    p_mesa_id    BIGINT
)
RETURNS TABLE(
    "id" BIGINT, "tableNumber" VARCHAR, "tableName" VARCHAR, "capacity" INT,
    "ambienteId" VARCHAR, "ambiente" VARCHAR, "posicionX" NUMERIC, "posicionY" NUMERIC
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT dt."DiningTableId", dt."TableNumber", dt."TableName", dt."Capacity",
           dt."EnvironmentCode", dt."EnvironmentName", dt."PositionX", dt."PositionY"
    FROM rest."DiningTable" dt
    WHERE dt."CompanyId" = p_company_id AND dt."BranchId" = p_branch_id
      AND dt."DiningTableId" = p_mesa_id AND dt."IsActive" = TRUE
    LIMIT 1;
END;
$$;

GRANT EXECUTE ON FUNCTION usp_rest_diningtable_getbyid(INT, INT, BIGINT) TO zentto_app;

\echo '  [022] Fix BIGINT en usp_rest_admin_ambiente_list...'

DROP FUNCTION IF EXISTS usp_rest_admin_ambiente_list(INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_rest_admin_ambiente_list(
    p_company_id INT,
    p_branch_id  INT
)
RETURNS TABLE(
    "id"     BIGINT,
    "nombre" VARCHAR,
    "color"  VARCHAR,
    "orden"  INT
)
LANGUAGE plpgsql AS $$
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

GRANT EXECUTE ON FUNCTION usp_rest_admin_ambiente_list(INT, INT) TO zentto_app;

\echo '  [022] Fix BIGINT en usp_rest_admin_categoria_list...'

DROP FUNCTION IF EXISTS usp_rest_admin_categoria_list(INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_rest_admin_categoria_list(
    p_company_id INT,
    p_branch_id  INT
)
RETURNS TABLE(
    "id"          BIGINT,
    "nombre"      VARCHAR,
    "descripcion" VARCHAR,
    "color"       VARCHAR,
    "orden"       INT
)
LANGUAGE plpgsql AS $$
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

GRANT EXECUTE ON FUNCTION usp_rest_admin_categoria_list(INT, INT) TO zentto_app;

\echo '  [022] Fix BIGINT en usp_rest_admin_producto_list...'

DROP FUNCTION IF EXISTS usp_rest_admin_producto_list(INT, INT, INT, VARCHAR(100), BOOLEAN) CASCADE;
CREATE OR REPLACE FUNCTION usp_rest_admin_producto_list(
    p_company_id       INT,
    p_branch_id        INT,
    p_menu_category_id BIGINT DEFAULT NULL,
    p_search           VARCHAR(100) DEFAULT NULL,
    p_solo_disponibles BOOLEAN DEFAULT TRUE
)
RETURNS TABLE(
    "id"                   BIGINT,
    "codigo"               VARCHAR,
    "nombre"               VARCHAR,
    "descripcion"          VARCHAR,
    "categoriaId"          BIGINT,
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
LANGUAGE plpgsql AS $$
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

GRANT EXECUTE ON FUNCTION usp_rest_admin_producto_list(INT, INT, BIGINT, VARCHAR(100), BOOLEAN) TO zentto_app;

\echo '  [022] Fix BIGINT en usp_rest_admin_compra_list...'

DROP FUNCTION IF EXISTS usp_rest_admin_compra_list(INT, INT, VARCHAR, TIMESTAMP, TIMESTAMP) CASCADE;
DROP FUNCTION IF EXISTS usp_rest_admin_compra_list(INT, INT, VARCHAR(20), TIMESTAMP, TIMESTAMP) CASCADE;
CREATE OR REPLACE FUNCTION usp_rest_admin_compra_list(
    p_company_id INT,
    p_branch_id  INT,
    p_status     VARCHAR(20) DEFAULT NULL,
    p_from_date  TIMESTAMP DEFAULT NULL,
    p_to_date    TIMESTAMP DEFAULT NULL
)
RETURNS TABLE(
    "id"                BIGINT,
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
LANGUAGE plpgsql AS $$
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

GRANT EXECUTE ON FUNCTION usp_rest_admin_compra_list(INT, INT, VARCHAR(20), TIMESTAMP, TIMESTAMP) TO zentto_app;

\echo '  [022] Fix BIGINT en usp_rest_admin_compra_getdetalle_header...'

DROP FUNCTION IF EXISTS usp_rest_admin_compra_getdetalle_header(INT) CASCADE;
DROP FUNCTION IF EXISTS usp_rest_admin_compra_getdetalle_header(BIGINT) CASCADE;
CREATE OR REPLACE FUNCTION usp_rest_admin_compra_getdetalle_header(
    p_compra_id BIGINT
)
RETURNS TABLE(
    "id"                BIGINT,
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
LANGUAGE plpgsql AS $$
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

GRANT EXECUTE ON FUNCTION usp_rest_admin_compra_getdetalle_header(BIGINT) TO zentto_app;

\echo '  [022] Fix BIGINT en usp_rest_admin_compra_getdetalle_lines...'

DROP FUNCTION IF EXISTS usp_rest_admin_compra_getdetalle_lines(INT) CASCADE;
DROP FUNCTION IF EXISTS usp_rest_admin_compra_getdetalle_lines(BIGINT) CASCADE;
CREATE OR REPLACE FUNCTION usp_rest_admin_compra_getdetalle_lines(
    p_compra_id BIGINT
)
RETURNS TABLE(
    "id"           BIGINT,
    "compraId"     BIGINT,
    "inventarioId" VARCHAR,
    "descripcion"  VARCHAR,
    "cantidad"     NUMERIC,
    "precioUnit"   NUMERIC,
    "subtotal"     NUMERIC,
    "iva"          NUMERIC
)
LANGUAGE plpgsql AS $$
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

GRANT EXECUTE ON FUNCTION usp_rest_admin_compra_getdetalle_lines(BIGINT) TO zentto_app;

\echo '  [022] Registrando migración...'
INSERT INTO public._migrations (name, applied_at)
VALUES ('022_fix_rest_bigint_return_types', NOW() AT TIME ZONE 'UTC')
ON CONFLICT (name) DO NOTHING;

\echo '  [022] COMPLETO — tipos BIGINT corregidos en 7 funciones restaurante'
