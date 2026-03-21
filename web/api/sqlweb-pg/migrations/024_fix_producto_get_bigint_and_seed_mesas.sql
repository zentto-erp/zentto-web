-- =============================================================================
--  Migración 024: Fix BIGINT en GET funciones de producto + Seed mesas/ambientes
--  1. usp_rest_admin_producto_get: "id" INT → BIGINT, "categoriaId" INT → BIGINT
--  2. usp_rest_admin_producto_get_componentes: "id" INT → BIGINT, "opcionId" INT → BIGINT
--  3. usp_rest_admin_producto_get_receta: "id" INT → BIGINT, "productoId" INT → BIGINT
--  4. Seed idempotente de ambientes y mesas para DEFAULT/MAIN
-- =============================================================================

\echo '  [024] Fix BIGINT en usp_rest_admin_producto_get...'

DROP FUNCTION IF EXISTS usp_rest_admin_producto_get(INT, INT) CASCADE;
DROP FUNCTION IF EXISTS usp_rest_admin_producto_get(BIGINT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_rest_admin_producto_get(
    p_id        BIGINT,
    p_branch_id INT
)
RETURNS TABLE(
    "id"                   BIGINT,
    "codigo"               VARCHAR,
    "nombre"               VARCHAR,
    "descripcion"          VARCHAR,
    "categoriaId"          BIGINT,
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

GRANT EXECUTE ON FUNCTION usp_rest_admin_producto_get(BIGINT, INT) TO zentto_app;

\echo '  [024] Fix BIGINT en usp_rest_admin_producto_get_componentes...'

DROP FUNCTION IF EXISTS usp_rest_admin_producto_get_componentes(INT) CASCADE;
DROP FUNCTION IF EXISTS usp_rest_admin_producto_get_componentes(BIGINT) CASCADE;
CREATE OR REPLACE FUNCTION usp_rest_admin_producto_get_componentes(
    p_id BIGINT
)
RETURNS TABLE(
    "id"           BIGINT,
    "nombre"       VARCHAR,
    "obligatorio"  BOOLEAN,
    "orden"        INT,
    "opcionId"     BIGINT,
    "opcionNombre" VARCHAR,
    "precioExtra"  NUMERIC,
    "opcionOrden"  INT
)
LANGUAGE plpgsql AS $$
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

GRANT EXECUTE ON FUNCTION usp_rest_admin_producto_get_componentes(BIGINT) TO zentto_app;

\echo '  [024] Fix BIGINT en usp_rest_admin_producto_get_receta...'

DROP FUNCTION IF EXISTS usp_rest_admin_producto_get_receta(INT, INT) CASCADE;
DROP FUNCTION IF EXISTS usp_rest_admin_producto_get_receta(BIGINT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_rest_admin_producto_get_receta(
    p_id        BIGINT,
    p_branch_id INT
)
RETURNS TABLE(
    "id"           BIGINT,
    "productoId"   BIGINT,
    "inventarioId" VARCHAR,
    "descripcion"  VARCHAR,
    "imagen"       VARCHAR,
    "cantidad"     NUMERIC,
    "unidad"       VARCHAR,
    "comentario"   VARCHAR
)
LANGUAGE plpgsql AS $$
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

GRANT EXECUTE ON FUNCTION usp_rest_admin_producto_get_receta(BIGINT, INT) TO zentto_app;

\echo '  [024] Seed idempotente de ambientes y mesas (DEFAULT/MAIN)...'

DO $$
DECLARE
    v_company_id   INT;
    v_branch_id    INT;
    v_user_id      INT;
BEGIN
    SELECT "CompanyId" INTO v_company_id
    FROM cfg."Company"
    WHERE "IsDeleted" = FALSE
    ORDER BY CASE WHEN "CompanyCode" = 'DEFAULT' THEN 0 ELSE 1 END, "CompanyId"
    LIMIT 1;

    SELECT "BranchId" INTO v_branch_id
    FROM cfg."Branch"
    WHERE "CompanyId" = v_company_id AND "IsDeleted" = FALSE
    ORDER BY CASE WHEN "BranchCode" = 'MAIN' THEN 0 ELSE 1 END, "BranchId"
    LIMIT 1;

    SELECT "UserId" INTO v_user_id
    FROM sec."User"
    WHERE "UserCode" = 'SYSTEM' AND "IsDeleted" = FALSE
    LIMIT 1;

    IF v_company_id IS NULL OR v_branch_id IS NULL THEN
        RAISE NOTICE 'No se encontró empresa/sucursal DEFAULT/MAIN — seed omitido';
        RETURN;
    END IF;

    -- Ambiente: Salón Principal
    INSERT INTO rest."MenuEnvironment" (
        "CompanyId", "BranchId", "EnvironmentCode", "EnvironmentName",
        "ColorHex", "SortOrder", "IsActive", "CreatedByUserId", "UpdatedByUserId"
    ) VALUES (
        v_company_id, v_branch_id, 'SALON', 'Salón Principal',
        '#4CAF50', 1, TRUE, v_user_id, v_user_id
    )
    ON CONFLICT ("CompanyId", "BranchId", "EnvironmentCode") DO UPDATE
        SET "EnvironmentName" = EXCLUDED."EnvironmentName",
            "IsActive" = TRUE,
            "UpdatedByUserId" = v_user_id;

    -- Ambiente: Terraza
    INSERT INTO rest."MenuEnvironment" (
        "CompanyId", "BranchId", "EnvironmentCode", "EnvironmentName",
        "ColorHex", "SortOrder", "IsActive", "CreatedByUserId", "UpdatedByUserId"
    ) VALUES (
        v_company_id, v_branch_id, 'TERRAZA', 'Terraza',
        '#FF9800', 2, TRUE, v_user_id, v_user_id
    )
    ON CONFLICT ("CompanyId", "BranchId", "EnvironmentCode") DO NOTHING;

    -- Mesas: 10 en SALON si no hay ninguna
    IF NOT EXISTS (
        SELECT 1 FROM rest."DiningTable"
        WHERE "CompanyId" = v_company_id AND "BranchId" = v_branch_id
    ) THEN
        WITH RECURSIVE n_series AS (
            SELECT 1 AS n
            UNION ALL
            SELECT n + 1 FROM n_series WHERE n < 10
        )
        INSERT INTO rest."DiningTable" (
            "CompanyId", "BranchId", "TableNumber", "TableName",
            "Capacity", "EnvironmentCode", "EnvironmentName",
            "PositionX", "PositionY", "IsActive",
            "CreatedByUserId", "UpdatedByUserId"
        )
        SELECT
            v_company_id,
            v_branch_id,
            n::TEXT,
            'Mesa ' || n::TEXT,
            4,
            'SALON',
            'Salón Principal',
            ((n - 1) % 5) * 150,
            ((n - 1) / 5) * 150,
            TRUE,
            v_user_id,
            v_user_id
        FROM n_series
        ON CONFLICT ("CompanyId", "BranchId", "TableNumber") DO NOTHING;

        RAISE NOTICE 'Seed: 10 mesas creadas para empresa % sucursal %', v_company_id, v_branch_id;
    ELSE
        RAISE NOTICE 'Seed: mesas ya existen, omitido';
    END IF;

END $$;

\echo '  [024] Registrando migración...'
INSERT INTO public._migrations (name, applied_at)
VALUES ('024_fix_producto_get_bigint_and_seed_mesas', NOW() AT TIME ZONE 'UTC')
ON CONFLICT (name) DO NOTHING;

\echo '  [024] COMPLETO — BIGINT GET producto + seed mesas/ambientes'
