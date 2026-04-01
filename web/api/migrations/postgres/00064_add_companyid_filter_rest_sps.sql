-- +goose Up
-- Migración: Agregar filtro p_company_id a funciones del módulo restaurante (rest.*)
-- y funciones legacy (public."Restaurante*") para aislamiento multi-tenant.

-- =============================================================================
-- 1. usp_acct_rest_getheader — OrderTicket tiene CompanyId
-- =============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_acct_rest_getheader(
    p_company_id INTEGER,
    p_order_ticket_id bigint
) RETURNS TABLE(id bigint, total numeric, "fechaCierre" timestamp without time zone, "codUsuario" character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT
        o."OrderTicketId"  AS "id",
        o."TotalAmount"    AS "total",
        o."ClosedAt"       AS "fechaCierre",
        COALESCE(uclose."UserCode", uopen."UserCode")::VARCHAR AS "codUsuario"
    FROM rest."OrderTicket" o
    LEFT JOIN sec."User" uopen  ON uopen."UserId"  = o."OpenedByUserId"
    LEFT JOIN sec."User" uclose ON uclose."UserId" = o."ClosedByUserId"
    WHERE o."OrderTicketId" = p_order_ticket_id
      AND o."CompanyId" = p_company_id
    LIMIT 1;
END;
$$;
-- +goose StatementEnd

-- =============================================================================
-- 2. usp_acct_rest_gettaxsummary — OrderTicketLine (child), JOIN via OrderTicket
-- =============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_acct_rest_gettaxsummary(
    p_company_id INTEGER,
    p_order_ticket_id bigint
) RETURNS TABLE("taxRate" numeric, "baseAmount" numeric, "taxAmount" numeric, "totalAmount" numeric)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT
        otl."TaxRate"          AS "taxRate",
        SUM(otl."NetAmount")   AS "baseAmount",
        SUM(otl."TaxAmount")   AS "taxAmount",
        SUM(otl."TotalAmount") AS "totalAmount"
    FROM rest."OrderTicketLine" otl
    INNER JOIN rest."OrderTicket" ot ON ot."OrderTicketId" = otl."OrderTicketId"
    WHERE otl."OrderTicketId" = p_order_ticket_id
      AND ot."CompanyId" = p_company_id
    GROUP BY otl."TaxRate";
END;
$$;
-- +goose StatementEnd

-- =============================================================================
-- 3. usp_rest_admin_adjuststock — master."Product" tiene CompanyId
-- =============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_rest_admin_adjuststock(
    p_company_id INTEGER,
    p_product_id bigint,
    p_delta_qty numeric
) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF p_product_id IS NULL OR p_delta_qty = 0 THEN
        RETURN;
    END IF;

    UPDATE master."Product"
    SET "StockQty" = COALESCE("StockQty", 0) + p_delta_qty,
        "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
    WHERE "ProductId" = p_product_id
      AND "CompanyId" = p_company_id;
END;
$$;
-- +goose StatementEnd

-- =============================================================================
-- 4. usp_rest_admin_componente_upsert — MenuComponent (child of MenuProduct)
-- =============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_rest_admin_componente_upsert(
    p_company_id INTEGER,
    p_id integer DEFAULT 0,
    p_producto_id integer DEFAULT NULL::integer,
    p_nombre character varying DEFAULT NULL::character varying,
    p_obligatorio boolean DEFAULT false,
    p_orden integer DEFAULT 0
) RETURNS TABLE(id integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_id INT;
BEGIN
    IF p_id > 0 AND EXISTS (
        SELECT 1 FROM rest."MenuComponent" mc
        INNER JOIN rest."MenuProduct" mp ON mp."MenuProductId" = mc."MenuProductId"
        WHERE mc."MenuComponentId" = p_id
          AND mp."CompanyId" = p_company_id
    ) THEN
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
-- +goose StatementEnd

-- =============================================================================
-- 5. usp_rest_admin_compra_getdetalle_header — Purchase tiene CompanyId
-- =============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_rest_admin_compra_getdetalle_header(
    p_company_id INTEGER,
    p_compra_id bigint
) RETURNS TABLE(id bigint, "numCompra" character varying, "proveedorId" character varying, "proveedorNombre" character varying, "fechaCompra" timestamp without time zone, estado character varying, subtotal numeric, iva numeric, total numeric, observaciones character varying, "codUsuario" character varying)
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
      AND p."CompanyId" = p_company_id
    LIMIT 1;
END;
$$;
-- +goose StatementEnd

-- =============================================================================
-- 6. usp_rest_admin_compra_getdetalle_lines — PurchaseLine (child), JOIN Purchase
-- =============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_rest_admin_compra_getdetalle_lines(
    p_company_id INTEGER,
    p_compra_id bigint
) RETURNS TABLE(id bigint, "compraId" bigint, "inventarioId" character varying, descripcion character varying, cantidad numeric, "precioUnit" numeric, subtotal numeric, iva numeric)
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
    INNER JOIN rest."Purchase" pu ON pu."PurchaseId" = pl."PurchaseId"
    LEFT JOIN master."Product" pr ON pr."ProductId" = pl."IngredientProductId"
    WHERE pl."PurchaseId" = p_compra_id
      AND pu."CompanyId" = p_company_id
    ORDER BY pl."PurchaseLineId";
END;
$$;
-- +goose StatementEnd

-- =============================================================================
-- 7. usp_rest_admin_compra_recalctotals — PurchaseLine/Purchase
-- =============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_rest_admin_compra_recalctotals(
    p_company_id INTEGER,
    p_purchase_id integer
) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_subtotal NUMERIC(18,2);
    v_tax      NUMERIC(18,2);
    v_total    NUMERIC(18,2);
BEGIN
    SELECT
        COALESCE(SUM(pl."SubtotalAmount"), 0),
        COALESCE(SUM(pl."SubtotalAmount" * pl."TaxRatePercent" / 100.0), 0),
        COALESCE(SUM(pl."SubtotalAmount" + (pl."SubtotalAmount" * pl."TaxRatePercent" / 100.0)), 0)
    INTO v_subtotal, v_tax, v_total
    FROM rest."PurchaseLine" pl
    INNER JOIN rest."Purchase" pu ON pu."PurchaseId" = pl."PurchaseId"
    WHERE pl."PurchaseId" = p_purchase_id
      AND pu."CompanyId" = p_company_id;

    UPDATE rest."Purchase"
    SET "SubtotalAmount" = v_subtotal,
        "TaxAmount"      = v_tax,
        "TotalAmount"    = v_total,
        "UpdatedAt"      = NOW() AT TIME ZONE 'UTC'
    WHERE "PurchaseId" = p_purchase_id
      AND "CompanyId" = p_company_id;
END;
$$;
-- +goose StatementEnd

-- =============================================================================
-- 8. usp_rest_admin_compra_update — Purchase tiene CompanyId
-- =============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_rest_admin_compra_update(
    p_company_id INTEGER,
    p_compra_id integer,
    p_supplier_id bigint DEFAULT NULL::bigint,
    p_status character varying DEFAULT NULL::character varying,
    p_notes character varying DEFAULT NULL::character varying
) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE rest."Purchase"
    SET "SupplierId" = COALESCE(p_supplier_id, "SupplierId"),
        "Status"     = COALESCE(p_status, "Status"),
        "Notes"      = COALESCE(p_notes, "Notes"),
        "UpdatedAt"  = NOW() AT TIME ZONE 'UTC'
    WHERE "PurchaseId" = p_compra_id
      AND "CompanyId" = p_company_id;
END;
$$;
-- +goose StatementEnd

-- =============================================================================
-- 9. usp_rest_admin_compralinea_delete — PurchaseLine (child), JOIN Purchase
-- =============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_rest_admin_compralinea_delete(
    p_company_id INTEGER,
    p_compra_id integer,
    p_detalle_id integer
) RETURNS TABLE("ingredientProductId" bigint, quantity numeric)
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Validar que la compra pertenece a la empresa
    IF NOT EXISTS (
        SELECT 1 FROM rest."Purchase" WHERE "PurchaseId" = p_compra_id AND "CompanyId" = p_company_id
    ) THEN
        RETURN;
    END IF;

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
-- +goose StatementEnd

-- =============================================================================
-- 10. usp_rest_admin_compralinea_getprev — PurchaseLine (child), JOIN Purchase
-- =============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_rest_admin_compralinea_getprev(
    p_company_id INTEGER,
    p_id integer,
    p_compra_id integer
) RETURNS TABLE("ingredientProductId" bigint, quantity numeric)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT pl."IngredientProductId", pl."Quantity"
    FROM rest."PurchaseLine" pl
    INNER JOIN rest."Purchase" pu ON pu."PurchaseId" = pl."PurchaseId"
    WHERE pl."PurchaseLineId" = p_id
      AND pl."PurchaseId" = p_compra_id
      AND pu."CompanyId" = p_company_id
    LIMIT 1;
END;
$$;
-- +goose StatementEnd

-- =============================================================================
-- 11. usp_rest_admin_compralinea_upsert — PurchaseLine (child), JOIN Purchase
-- =============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_rest_admin_compralinea_upsert(
    p_company_id INTEGER,
    p_id integer DEFAULT 0,
    p_compra_id integer DEFAULT NULL::integer,
    p_ingredient_product_id bigint DEFAULT NULL::bigint,
    p_descripcion character varying DEFAULT NULL::character varying,
    p_quantity numeric DEFAULT NULL::numeric,
    p_unit_price numeric DEFAULT NULL::numeric,
    p_tax_rate_percent numeric DEFAULT 16,
    p_subtotal numeric DEFAULT NULL::numeric
) RETURNS TABLE(id integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_id INT;
BEGIN
    -- Validar que la compra pertenece a la empresa
    IF NOT EXISTS (
        SELECT 1 FROM rest."Purchase" WHERE "PurchaseId" = p_compra_id AND "CompanyId" = p_company_id
    ) THEN
        RETURN;
    END IF;

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
-- +goose StatementEnd

-- =============================================================================
-- 12. usp_rest_admin_opcion_upsert — MenuOption (child of MenuComponent)
-- =============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_rest_admin_opcion_upsert(
    p_company_id INTEGER,
    p_id integer DEFAULT 0,
    p_componente_id integer DEFAULT NULL::integer,
    p_nombre character varying DEFAULT NULL::character varying,
    p_precio_extra numeric DEFAULT 0,
    p_orden integer DEFAULT 0
) RETURNS TABLE(id integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_id INT;
BEGIN
    IF p_id > 0 AND EXISTS (
        SELECT 1 FROM rest."MenuOption" mo
        INNER JOIN rest."MenuComponent" mc ON mc."MenuComponentId" = mo."MenuComponentId"
        INNER JOIN rest."MenuProduct" mp ON mp."MenuProductId" = mc."MenuProductId"
        WHERE mo."MenuOptionId" = p_id
          AND mp."CompanyId" = p_company_id
    ) THEN
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
-- +goose StatementEnd

-- =============================================================================
-- 13. usp_rest_admin_producto_delete — MenuProduct tiene CompanyId
-- =============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_rest_admin_producto_delete(
    p_company_id INTEGER,
    p_id integer
) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE rest."MenuProduct"
    SET "IsActive" = FALSE,
        "IsAvailable" = FALSE,
        "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
    WHERE "MenuProductId" = p_id
      AND "CompanyId" = p_company_id;
END;
$$;
-- +goose StatementEnd

-- =============================================================================
-- 14. usp_rest_admin_producto_get — add p_company_id (already has p_branch_id)
-- =============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_rest_admin_producto_get(
    p_company_id INTEGER,
    p_id bigint,
    p_branch_id integer
) RETURNS TABLE(id bigint, codigo character varying, nombre character varying, descripcion character varying, "categoriaId" bigint, precio numeric, "costoEstimado" numeric, iva numeric, "esCompuesto" boolean, "tiempoPreparacion" integer, imagen character varying, "esSugerenciaDelDia" boolean, disponible boolean, "articuloInventarioId" character varying)
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
      AND mp."CompanyId" = p_company_id
      AND mp."IsActive" = TRUE
    LIMIT 1;
END;
$$;
-- +goose StatementEnd

-- =============================================================================
-- 15. usp_rest_admin_producto_get_componentes — MenuComponent (child)
-- =============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_rest_admin_producto_get_componentes(
    p_company_id INTEGER,
    p_id bigint
) RETURNS TABLE(id bigint, nombre character varying, obligatorio boolean, orden integer, "opcionId" bigint, "opcionNombre" character varying, "precioExtra" numeric, "opcionOrden" integer)
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
    INNER JOIN rest."MenuProduct" mp ON mp."MenuProductId" = c."MenuProductId"
    LEFT JOIN rest."MenuOption" o
      ON o."MenuComponentId" = c."MenuComponentId"
     AND o."IsActive" = TRUE
    WHERE c."MenuProductId" = p_id
      AND c."IsActive" = TRUE
      AND mp."CompanyId" = p_company_id
    ORDER BY c."SortOrder", c."MenuComponentId", o."SortOrder", o."MenuOptionId";
END;
$$;
-- +goose StatementEnd

-- =============================================================================
-- 16. usp_rest_admin_producto_get_receta — MenuRecipe (child), add p_company_id
-- =============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_rest_admin_producto_get_receta(
    p_company_id INTEGER,
    p_id bigint,
    p_branch_id integer
) RETURNS TABLE(id bigint, "productoId" bigint, "inventarioId" character varying, descripcion character varying, imagen character varying, cantidad numeric, unidad character varying, comentario character varying)
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
    INNER JOIN rest."MenuProduct" mp ON mp."MenuProductId" = r."MenuProductId"
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
      AND mp."CompanyId" = p_company_id
    ORDER BY r."MenuRecipeId";
END;
$$;
-- +goose StatementEnd

-- =============================================================================
-- 17. usp_rest_admin_receta_delete — MenuRecipe (child)
-- =============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_rest_admin_receta_delete(
    p_company_id INTEGER,
    p_id integer
) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE rest."MenuRecipe" mr
    SET "IsActive" = FALSE,
        "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
    FROM rest."MenuProduct" mp
    WHERE mr."MenuProductId" = mp."MenuProductId"
      AND mr."MenuRecipeId" = p_id
      AND mp."CompanyId" = p_company_id;
END;
$$;
-- +goose StatementEnd

-- =============================================================================
-- 18. usp_rest_admin_receta_upsert — MenuRecipe (child)
-- =============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_rest_admin_receta_upsert(
    p_company_id INTEGER,
    p_id integer DEFAULT 0,
    p_producto_id integer DEFAULT NULL::integer,
    p_ingredient_product_id bigint DEFAULT NULL::bigint,
    p_quantity numeric DEFAULT NULL::numeric,
    p_unit_code character varying DEFAULT NULL::character varying,
    p_notes character varying DEFAULT NULL::character varying
) RETURNS TABLE(id integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_id INT;
BEGIN
    IF p_id > 0 AND EXISTS (
        SELECT 1 FROM rest."MenuRecipe" mr
        INNER JOIN rest."MenuProduct" mp ON mp."MenuProductId" = mr."MenuProductId"
        WHERE mr."MenuRecipeId" = p_id
          AND mp."CompanyId" = p_company_id
    ) THEN
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
-- +goose StatementEnd

-- =============================================================================
-- 19. usp_rest_admin_resolvemenucategory — MenuCategory tiene CompanyId
-- =============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_rest_admin_resolvemenucategory(
    p_company_id INTEGER,
    p_menu_category_id integer
) RETURNS TABLE(id integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT mc."MenuCategoryId"
    FROM rest."MenuCategory" mc
    WHERE mc."MenuCategoryId" = p_menu_category_id
      AND mc."CompanyId" = p_company_id
    LIMIT 1;
END;
$$;
-- +goose StatementEnd

-- =============================================================================
-- 20. usp_rest_orderticket_checkpriorvoid — sec.SupervisorOverride (no CompanyId directo)
-- =============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_rest_orderticket_checkpriorvoid(
    p_company_id INTEGER,
    p_pedido_id bigint,
    p_item_id bigint
) RETURNS TABLE("alreadyVoided" integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT 1 FROM sec."SupervisorOverride" so
    INNER JOIN rest."OrderTicket" ot ON ot."OrderTicketId" = so."SourceDocumentId"
    WHERE so."ModuleCode" = 'RESTAURANTE'
      AND so."ActionCode" = 'ORDER_LINE_VOID'
      AND so."Status" = 'CONSUMED'
      AND so."SourceDocumentId" = p_pedido_id
      AND so."SourceLineId" = p_item_id
      AND ot."CompanyId" = p_company_id
    LIMIT 1;
END;
$$;
-- +goose StatementEnd

-- =============================================================================
-- 21. usp_rest_orderticket_close — OrderTicket tiene CompanyId
-- =============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_rest_orderticket_close(
    p_company_id INTEGER,
    p_pedido_id bigint,
    p_closed_by_user_id integer DEFAULT NULL::integer
) RETURNS TABLE("Resultado" integer, "Mensaje" character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE rest."OrderTicket"
    SET "Status" = 'CLOSED',
        "ClosedByUserId" = p_closed_by_user_id,
        "ClosedAt" = NOW() AT TIME ZONE 'UTC',
        "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
    WHERE "OrderTicketId" = p_pedido_id
      AND "CompanyId" = p_company_id;
    RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);
END;
$$;
-- +goose StatementEnd

-- =============================================================================
-- 22. usp_rest_orderticket_getbyid — OrderTicket tiene CompanyId
-- =============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_rest_orderticket_getbyid(
    p_company_id INTEGER,
    p_pedido_id bigint
) RETURNS TABLE("orderId" bigint, "companyId" integer, "branchId" integer, "countryCode" character varying, status character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT ot."OrderTicketId", ot."CompanyId", ot."BranchId",
        ot."CountryCode"::VARCHAR, ot."Status"::VARCHAR
    FROM rest."OrderTicket" ot
    WHERE ot."OrderTicketId" = p_pedido_id
      AND ot."CompanyId" = p_company_id
    LIMIT 1;
END;
$$;
-- +goose StatementEnd

-- =============================================================================
-- 23. usp_rest_orderticket_getheaderforclose — OrderTicket tiene CompanyId
-- =============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_rest_orderticket_getheaderforclose(
    p_company_id INTEGER,
    p_pedido_id bigint
) RETURNS TABLE(id bigint, "empresaId" integer, "sucursalId" integer, "countryCode" character varying, "mesaId" bigint, "clienteNombre" character varying, "clienteRif" character varying, estado character varying, total numeric, "fechaCierre" timestamp without time zone, "codUsuario" character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT o."OrderTicketId", o."CompanyId", o."BranchId",
        o."CountryCode"::VARCHAR, dt."DiningTableId",
        o."CustomerName"::VARCHAR, o."CustomerFiscalId"::VARCHAR,
        o."Status"::VARCHAR, o."TotalAmount", o."ClosedAt",
        COALESCE(uc."UserCode", uo."UserCode")::VARCHAR
    FROM rest."OrderTicket" o
    LEFT JOIN rest."DiningTable" dt ON dt."CompanyId" = o."CompanyId" AND dt."BranchId" = o."BranchId" AND dt."TableNumber" = o."TableNumber"
    LEFT JOIN sec."User" uo ON uo."UserId" = o."OpenedByUserId"
    LEFT JOIN sec."User" uc ON uc."UserId" = o."ClosedByUserId"
    WHERE o."OrderTicketId" = p_pedido_id
      AND o."CompanyId" = p_company_id
    LIMIT 1;
END;
$$;
-- +goose StatementEnd

-- =============================================================================
-- 24. usp_rest_orderticket_recalctotals — OrderTicketLine/OrderTicket
-- =============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_rest_orderticket_recalctotals(
    p_company_id INTEGER,
    p_order_id bigint
) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE v_net NUMERIC(18,2); v_tax NUMERIC(18,2); v_total NUMERIC(18,2);
BEGIN
    SELECT COALESCE(SUM("NetAmount"),0), COALESCE(SUM("TaxAmount"),0), COALESCE(SUM("TotalAmount"),0)
    INTO v_net, v_tax, v_total
    FROM rest."OrderTicketLine"
    WHERE "OrderTicketId" = p_order_id;

    UPDATE rest."OrderTicket"
    SET "NetAmount" = v_net, "TaxAmount" = v_tax, "TotalAmount" = v_total,
        "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
    WHERE "OrderTicketId" = p_order_id
      AND "CompanyId" = p_company_id;
END;
$$;
-- +goose StatementEnd

-- =============================================================================
-- 25. usp_rest_orderticket_sendtokitchen — OrderTicket tiene CompanyId
-- =============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_rest_orderticket_sendtokitchen(
    p_company_id INTEGER,
    p_pedido_id bigint
) RETURNS TABLE("Resultado" integer, "Mensaje" character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE rest."OrderTicket"
    SET "Status" = CASE WHEN "Status" = 'OPEN' THEN 'SENT' ELSE "Status" END,
        "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
    WHERE "OrderTicketId" = p_pedido_id
      AND "CompanyId" = p_company_id;
    RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);
END;
$$;
-- +goose StatementEnd

-- =============================================================================
-- 26. usp_rest_orderticket_updatetimestamp — OrderTicket tiene CompanyId
-- =============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_rest_orderticket_updatetimestamp(
    p_company_id INTEGER,
    p_pedido_id bigint
) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE rest."OrderTicket"
    SET "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
    WHERE "OrderTicketId" = p_pedido_id
      AND "CompanyId" = p_company_id;
END;
$$;
-- +goose StatementEnd

-- =============================================================================
-- 27. usp_rest_orderticketline_getbyid — OrderTicketLine (child), JOIN OrderTicket
-- =============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_rest_orderticketline_getbyid(
    p_company_id INTEGER,
    p_pedido_id bigint,
    p_item_id bigint
) RETURNS TABLE("itemId" bigint, "lineNumber" integer, "countryCode" character varying, "productId" bigint, "productCode" character varying, nombre character varying, cantidad numeric, "unitPrice" numeric, "taxCode" character varying, "taxRate" numeric, "netAmount" numeric, "taxAmount" numeric, "totalAmount" numeric)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT ol."OrderTicketLineId", ol."LineNumber", ol."CountryCode"::VARCHAR,
        ol."ProductId", ol."ProductCode"::VARCHAR, ol."ProductName"::VARCHAR,
        ol."Quantity", ol."UnitPrice", ol."TaxCode"::VARCHAR, ol."TaxRate",
        ol."NetAmount", ol."TaxAmount", ol."TotalAmount"
    FROM rest."OrderTicketLine" ol
    INNER JOIN rest."OrderTicket" ot ON ot."OrderTicketId" = ol."OrderTicketId"
    WHERE ol."OrderTicketId" = p_pedido_id
      AND ol."OrderTicketLineId" = p_item_id
      AND ot."CompanyId" = p_company_id
    LIMIT 1;
END;
$$;
-- +goose StatementEnd

-- =============================================================================
-- 28. usp_rest_orderticketline_getbypedido — OrderTicketLine (child), JOIN OrderTicket
-- =============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_rest_orderticketline_getbypedido(
    p_company_id INTEGER,
    p_pedido_id bigint
) RETURNS TABLE(id bigint, "productoId" character varying, nombre character varying, cantidad numeric, "precioUnitario" numeric, subtotal numeric, iva numeric, "taxCode" character varying, impuesto numeric, total numeric)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT ol."OrderTicketLineId",
        ol."ProductCode"::VARCHAR, ol."ProductName"::VARCHAR,
        ol."Quantity", ol."UnitPrice", ol."NetAmount",
        CASE WHEN ol."TaxRate" > 1 THEN ol."TaxRate" ELSE ol."TaxRate" * 100 END,
        ol."TaxCode"::VARCHAR, ol."TaxAmount", ol."TotalAmount"
    FROM rest."OrderTicketLine" ol
    INNER JOIN rest."OrderTicket" ot ON ot."OrderTicketId" = ol."OrderTicketId"
    WHERE ol."OrderTicketId" = p_pedido_id
      AND ot."CompanyId" = p_company_id
    ORDER BY ol."LineNumber";
END;
$$;
-- +goose StatementEnd

-- =============================================================================
-- 29. usp_rest_orderticketline_getfiscalbreakdown — OrderTicketLine (child)
-- =============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_rest_orderticketline_getfiscalbreakdown(
    p_company_id INTEGER,
    p_pedido_id bigint
) RETURNS TABLE("itemId" bigint, "productoId" character varying, nombre character varying, quantity numeric, "unitPrice" numeric, "baseAmount" numeric, "taxCode" character varying, "taxRate" numeric, "taxAmount" numeric, "totalAmount" numeric)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT ol."OrderTicketLineId",
        ol."ProductCode"::VARCHAR, ol."ProductName"::VARCHAR,
        ol."Quantity", ol."UnitPrice", ol."NetAmount",
        ol."TaxCode"::VARCHAR, ol."TaxRate", ol."TaxAmount", ol."TotalAmount"
    FROM rest."OrderTicketLine" ol
    INNER JOIN rest."OrderTicket" ot ON ot."OrderTicketId" = ol."OrderTicketId"
    WHERE ol."OrderTicketId" = p_pedido_id
      AND ot."CompanyId" = p_company_id
    ORDER BY ol."LineNumber";
END;
$$;
-- +goose StatementEnd

-- =============================================================================
-- 30. usp_rest_orderticketline_insert — OrderTicketLine insert, validate via OrderTicket
-- =============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_rest_orderticketline_insert(
    p_company_id INTEGER,
    p_order_id bigint,
    p_line_number integer,
    p_country_code character varying,
    p_product_id bigint DEFAULT NULL::bigint,
    p_product_code character varying DEFAULT NULL::character varying,
    p_product_name character varying DEFAULT NULL::character varying,
    p_quantity numeric DEFAULT NULL::numeric,
    p_unit_price numeric DEFAULT NULL::numeric,
    p_tax_code character varying DEFAULT NULL::character varying,
    p_tax_rate numeric DEFAULT NULL::numeric,
    p_net_amount numeric DEFAULT NULL::numeric,
    p_tax_amount numeric DEFAULT NULL::numeric,
    p_total_amount numeric DEFAULT NULL::numeric,
    p_notes character varying DEFAULT NULL::character varying,
    p_supervisor_approval_id integer DEFAULT NULL::integer
) RETURNS TABLE("Resultado" bigint, "Mensaje" character varying)
    LANGUAGE plpgsql
    AS $$
DECLARE v_id BIGINT;
BEGIN
    -- Validar que el ticket pertenece a la empresa
    IF NOT EXISTS (
        SELECT 1 FROM rest."OrderTicket" WHERE "OrderTicketId" = p_order_id AND "CompanyId" = p_company_id
    ) THEN
        RETURN QUERY SELECT 0::BIGINT, 'OrderTicket no pertenece a la empresa'::VARCHAR(500);
        RETURN;
    END IF;

    INSERT INTO rest."OrderTicketLine" ("OrderTicketId","LineNumber","CountryCode",
        "ProductId","ProductCode","ProductName","Quantity","UnitPrice","TaxCode","TaxRate",
        "NetAmount","TaxAmount","TotalAmount","Notes","SupervisorApprovalId","CreatedAt","UpdatedAt")
    VALUES (p_order_id, p_line_number, p_country_code, p_product_id, p_product_code, p_product_name,
        p_quantity, p_unit_price, p_tax_code, p_tax_rate, p_net_amount, p_tax_amount, p_total_amount,
        p_notes, p_supervisor_approval_id, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC')
    RETURNING "OrderTicketLineId" INTO v_id;
    RETURN QUERY SELECT v_id, 'OK'::VARCHAR(500);
END;
$$;
-- +goose StatementEnd

-- =============================================================================
-- 31. usp_rest_orderticketline_nextlinenumber — OrderTicketLine (child)
-- =============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_rest_orderticketline_nextlinenumber(
    p_company_id INTEGER,
    p_order_id bigint
) RETURNS TABLE("nextLine" integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT COALESCE(MAX(ol."LineNumber"), 0) + 1
    FROM rest."OrderTicketLine" ol
    INNER JOIN rest."OrderTicket" ot ON ot."OrderTicketId" = ol."OrderTicketId"
    WHERE ol."OrderTicketId" = p_order_id
      AND ot."CompanyId" = p_company_id;
END;
$$;
-- +goose StatementEnd

-- =============================================================================
-- LEGACY FUNCTIONS (public."Restaurante*" tables)
-- Pattern: (CompanyId = p_company_id OR CompanyId IS NULL) for backward compat
-- =============================================================================

-- =============================================================================
-- 32. usp_rest_ambiente_upsert — RestauranteAmbientes (legacy)
-- =============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_rest_ambiente_upsert(
    p_company_id INTEGER,
    p_id integer DEFAULT 0,
    p_nombre character varying DEFAULT ''::character varying,
    p_color character varying DEFAULT '#4CAF50'::character varying,
    p_orden integer DEFAULT 0
) RETURNS TABLE("ResultId" integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_result_id INT;
BEGIN
    IF p_id > 0 AND EXISTS (
        SELECT 1 FROM "RestauranteAmbientes"
        WHERE "Id" = p_id AND ("CompanyId" = p_company_id OR "CompanyId" IS NULL)
    ) THEN
        UPDATE "RestauranteAmbientes"
        SET "Nombre" = p_nombre, "Color" = p_color, "Orden" = p_orden
        WHERE "Id" = p_id AND ("CompanyId" = p_company_id OR "CompanyId" IS NULL);
        v_result_id := p_id;
    ELSE
        INSERT INTO "RestauranteAmbientes" ("Nombre", "Color", "Orden")
        VALUES (p_nombre, p_color, p_orden)
        RETURNING "Id" INTO v_result_id;
    END IF;

    RETURN QUERY SELECT v_result_id;
END;
$$;
-- +goose StatementEnd

-- =============================================================================
-- 33. usp_rest_ambientes_list — RestauranteAmbientes (legacy)
-- =============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_rest_ambientes_list(
    p_company_id INTEGER
) RETURNS TABLE(id integer, nombre character varying, color character varying, orden integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT "Id", "Nombre", "Color", "Orden"
    FROM "RestauranteAmbientes"
    WHERE "Activo" = TRUE
      AND ("CompanyId" = p_company_id OR "CompanyId" IS NULL)
    ORDER BY "Orden";
END;
$$;
-- +goose StatementEnd

-- =============================================================================
-- 34. usp_rest_categoria_upsert — RestauranteCategorias (legacy)
-- =============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_rest_categoria_upsert(
    p_company_id INTEGER,
    p_id integer DEFAULT 0,
    p_nombre character varying DEFAULT ''::character varying,
    p_descripcion character varying DEFAULT NULL::character varying,
    p_color character varying DEFAULT NULL::character varying,
    p_orden integer DEFAULT 0
) RETURNS TABLE("ResultId" integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_result_id INT;
BEGIN
    IF p_id > 0 AND EXISTS (
        SELECT 1 FROM "RestauranteCategorias"
        WHERE "Id" = p_id AND ("CompanyId" = p_company_id OR "CompanyId" IS NULL)
    ) THEN
        UPDATE "RestauranteCategorias"
        SET "Nombre" = p_nombre, "Descripcion" = p_descripcion, "Color" = p_color, "Orden" = p_orden
        WHERE "Id" = p_id AND ("CompanyId" = p_company_id OR "CompanyId" IS NULL);
        v_result_id := p_id;
    ELSE
        INSERT INTO "RestauranteCategorias" ("Nombre", "Descripcion", "Color", "Orden")
        VALUES (p_nombre, p_descripcion, p_color, p_orden)
        RETURNING "Id" INTO v_result_id;
    END IF;

    RETURN QUERY SELECT v_result_id;
END;
$$;
-- +goose StatementEnd

-- =============================================================================
-- 35. usp_rest_categorias_list — RestauranteCategorias (legacy)
-- =============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_rest_categorias_list(
    p_company_id INTEGER
) RETURNS TABLE(id integer, nombre character varying, descripcion character varying, color character varying, orden integer, "productCount" bigint)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT c."Id", c."Nombre", c."Descripcion", c."Color", c."Orden",
        (SELECT COUNT(1) FROM "RestauranteProductos" p
         WHERE p."CategoriaId" = c."Id" AND p."Activo" = TRUE
           AND ("CompanyId" = p_company_id OR "CompanyId" IS NULL))
    FROM "RestauranteCategorias" c
    WHERE c."Activa" = TRUE
      AND (c."CompanyId" = p_company_id OR c."CompanyId" IS NULL)
    ORDER BY c."Orden";
END;
$$;
-- +goose StatementEnd

-- =============================================================================
-- 36. usp_rest_comanda_enviar — RestaurantePedidoItems/Pedidos (legacy)
-- =============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_rest_comanda_enviar(
    p_company_id INTEGER,
    p_pedido_id integer
) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE "RestaurantePedidoItems"
    SET "EnviadoACocina" = TRUE,
        "HoraEnvio" = NOW() AT TIME ZONE 'UTC',
        "Estado" = 'en_preparacion'
    WHERE "PedidoId" = p_pedido_id
      AND "EnviadoACocina" = FALSE;

    UPDATE "RestaurantePedidos"
    SET "Estado" = 'en_preparacion'
    WHERE "Id" = p_pedido_id AND "Estado" = 'abierto'
      AND ("CompanyId" = p_company_id OR "CompanyId" IS NULL);
END;
$$;
-- +goose StatementEnd

-- =============================================================================
-- 37. usp_rest_componente_upsert — RestauranteProductoComponentes (legacy)
-- =============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_rest_componente_upsert(
    p_company_id INTEGER,
    p_id integer DEFAULT 0,
    p_producto_id integer DEFAULT 0,
    p_nombre character varying DEFAULT ''::character varying,
    p_obligatorio boolean DEFAULT false,
    p_orden integer DEFAULT 0
) RETURNS TABLE("ResultId" integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_result_id INT;
BEGIN
    IF p_id > 0 AND EXISTS (SELECT 1 FROM "RestauranteProductoComponentes" WHERE "Id" = p_id) THEN
        UPDATE "RestauranteProductoComponentes"
        SET "Nombre" = p_nombre, "Obligatorio" = p_obligatorio, "Orden" = p_orden
        WHERE "Id" = p_id;
        v_result_id := p_id;
    ELSE
        INSERT INTO "RestauranteProductoComponentes" ("ProductoId", "Nombre", "Obligatorio", "Orden")
        VALUES (p_producto_id, p_nombre, p_obligatorio, p_orden)
        RETURNING "Id" INTO v_result_id;
    END IF;

    RETURN QUERY SELECT v_result_id;
END;
$$;
-- +goose StatementEnd

-- =============================================================================
-- 38. usp_rest_compra_crear — RestauranteCompras (legacy)
-- =============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_rest_compra_crear(
    p_company_id INTEGER,
    p_proveedor_id character varying DEFAULT NULL::character varying,
    p_observaciones character varying DEFAULT NULL::character varying,
    p_cod_usuario character varying DEFAULT NULL::character varying,
    p_detalle_json jsonb DEFAULT '[]'::jsonb
) RETURNS TABLE("CompraId" integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_compra_id  INT;
    v_num_compra VARCHAR(20);
    v_seq        INT;
BEGIN
    SELECT COALESCE(MAX("Id"), 0) + 1 INTO v_seq FROM "RestauranteCompras";
    v_num_compra := 'RC-' || REPLACE(TO_CHAR(NOW() AT TIME ZONE 'UTC', 'YYYY-MM'), '-',''::VARCHAR) || '-' || LPAD(v_seq::TEXT, 4, '0');

    INSERT INTO "RestauranteCompras" ("NumCompra", "ProveedorId", "Estado", "Observaciones", "CodUsuario")
    VALUES (v_num_compra, p_proveedor_id, 'pendiente', p_observaciones, p_cod_usuario)
    RETURNING "Id" INTO v_compra_id;

    INSERT INTO "RestauranteComprasDetalle" ("CompraId", "InventarioId", "Descripcion", "Cantidad", "PrecioUnit", "Subtotal", "IVA")
    SELECT
        v_compra_id,
        (item->>'invId')::VARCHAR(15),
        (item->>'desc')::VARCHAR(200),
        (item->>'cant')::NUMERIC(10,3),
        (item->>'precio')::NUMERIC(18,2),
        (item->>'cant')::NUMERIC(10,3) * (item->>'precio')::NUMERIC(18,2),
        COALESCE((item->>'iva')::NUMERIC(5,2), 16)
    FROM jsonb_array_elements(p_detalle_json) AS item;

    UPDATE "RestauranteCompras" SET
        "Subtotal" = (SELECT COALESCE(SUM("Subtotal"), 0) FROM "RestauranteComprasDetalle" WHERE "CompraId" = v_compra_id),
        "IVA" = (SELECT COALESCE(SUM("Subtotal" * "IVA" / 100), 0) FROM "RestauranteComprasDetalle" WHERE "CompraId" = v_compra_id),
        "Total" = (SELECT COALESCE(SUM("Subtotal" + "Subtotal" * "IVA" / 100), 0) FROM "RestauranteComprasDetalle" WHERE "CompraId" = v_compra_id)
    WHERE "Id" = v_compra_id;

    RETURN QUERY SELECT v_compra_id;

EXCEPTION WHEN OTHERS THEN
    RAISE EXCEPTION '%', SQLERRM;
END;
$$;
-- +goose StatementEnd

-- =============================================================================
-- 39. usp_rest_compras_list — RestauranteCompras (legacy)
-- =============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_rest_compras_list(
    p_company_id INTEGER,
    p_estado character varying DEFAULT NULL::character varying,
    p_from timestamp without time zone DEFAULT NULL::timestamp without time zone,
    p_to timestamp without time zone DEFAULT NULL::timestamp without time zone
) RETURNS TABLE(id integer, "numCompra" character varying, "proveedorId" character varying, "proveedorNombre" character varying, "fechaCompra" timestamp without time zone, "fechaRecepcion" timestamp without time zone, estado character varying, subtotal numeric, iva numeric, total numeric, observaciones character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT
        c."Id", c."NumCompra",
        c."ProveedorId",
        p."SupplierName",
        c."FechaCompra", c."FechaRecepcion",
        c."Estado", c."Subtotal", c."IVA", c."Total",
        c."Observaciones"
    FROM "RestauranteCompras" c
    LEFT JOIN master."Supplier" p ON p."SupplierCode" = c."ProveedorId"
    WHERE (COALESCE(p."IsDeleted", FALSE) = FALSE OR p."SupplierCode" IS NULL)
      AND (c."CompanyId" = p_company_id OR c."CompanyId" IS NULL)
      AND (p_estado IS NULL OR c."Estado" = p_estado)
      AND (p_from IS NULL OR c."FechaCompra" >= p_from)
      AND (p_to IS NULL OR c."FechaCompra" <= p_to)
    ORDER BY c."FechaCompra" DESC;
END;
$$;
-- +goose StatementEnd

-- =============================================================================
-- 40. usp_rest_mesas_list — RestauranteMesas (legacy)
-- =============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_rest_mesas_list(
    p_company_id INTEGER,
    p_ambiente_id character varying DEFAULT NULL::character varying
) RETURNS TABLE(id integer, numero integer, nombre character varying, capacidad integer, "ambienteId" character varying, ambiente character varying, "posicionX" integer, "posicionY" integer, estado character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT
        m."Id",
        m."Numero",
        m."Nombre",
        m."Capacidad",
        m."AmbienteId",
        m."Ambiente",
        m."PosicionX",
        m."PosicionY",
        m."Estado"
    FROM "RestauranteMesas" m
    WHERE m."Activa" = TRUE
      AND (m."CompanyId" = p_company_id OR m."CompanyId" IS NULL)
      AND (p_ambiente_id IS NULL OR m."AmbienteId" = p_ambiente_id)
    ORDER BY m."AmbienteId", m."Numero";
END;
$$;
-- +goose StatementEnd

-- =============================================================================
-- 41. usp_rest_opcion_upsert — RestauranteComponenteOpciones (legacy)
-- =============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_rest_opcion_upsert(
    p_company_id INTEGER,
    p_id integer DEFAULT 0,
    p_componente_id integer DEFAULT 0,
    p_nombre character varying DEFAULT ''::character varying,
    p_precio_extra numeric DEFAULT 0,
    p_orden integer DEFAULT 0
) RETURNS TABLE("ResultId" integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_result_id INT;
BEGIN
    IF p_id > 0 AND EXISTS (SELECT 1 FROM "RestauranteComponenteOpciones" WHERE "Id" = p_id) THEN
        UPDATE "RestauranteComponenteOpciones"
        SET "Nombre" = p_nombre, "PrecioExtra" = p_precio_extra, "Orden" = p_orden
        WHERE "Id" = p_id;
        v_result_id := p_id;
    ELSE
        INSERT INTO "RestauranteComponenteOpciones" ("ComponenteId", "Nombre", "PrecioExtra", "Orden")
        VALUES (p_componente_id, p_nombre, p_precio_extra, p_orden)
        RETURNING "Id" INTO v_result_id;
    END IF;

    RETURN QUERY SELECT v_result_id;
END;
$$;
-- +goose StatementEnd

-- =============================================================================
-- 42. usp_rest_pedido_abrir — RestaurantePedidos (legacy)
-- =============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_rest_pedido_abrir(
    p_company_id INTEGER,
    p_mesa_id integer,
    p_cliente_nombre character varying DEFAULT NULL::character varying,
    p_cliente_rif character varying DEFAULT NULL::character varying,
    p_cod_usuario character varying DEFAULT NULL::character varying
) RETURNS TABLE("PedidoId" integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_pedido_id INT;
BEGIN
    INSERT INTO "RestaurantePedidos" ("MesaId", "ClienteNombre", "ClienteRif", "Estado", "CodUsuario")
    VALUES (p_mesa_id, p_cliente_nombre, p_cliente_rif, 'abierto', p_cod_usuario)
    RETURNING "Id" INTO v_pedido_id;

    UPDATE "RestauranteMesas"
    SET "Estado" = 'ocupada'
    WHERE "Id" = p_mesa_id
      AND ("CompanyId" = p_company_id OR "CompanyId" IS NULL);

    RETURN QUERY SELECT v_pedido_id AS "PedidoId";

EXCEPTION WHEN OTHERS THEN
    RAISE EXCEPTION '%', SQLERRM;
END;
$$;
-- +goose StatementEnd

-- =============================================================================
-- 43. usp_rest_pedido_cerrar — RestaurantePedidos (legacy)
-- =============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_rest_pedido_cerrar(
    p_company_id INTEGER,
    p_pedido_id integer
) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_mesa_id INT;
BEGIN
    SELECT "MesaId" INTO v_mesa_id
    FROM "RestaurantePedidos"
    WHERE "Id" = p_pedido_id
      AND ("CompanyId" = p_company_id OR "CompanyId" IS NULL);

    UPDATE "RestaurantePedidos"
    SET "Estado" = 'cerrado', "FechaCierre" = NOW() AT TIME ZONE 'UTC'
    WHERE "Id" = p_pedido_id
      AND ("CompanyId" = p_company_id OR "CompanyId" IS NULL);

    UPDATE "RestauranteMesas" SET "Estado" = 'libre'
    WHERE "Id" = v_mesa_id
      AND ("CompanyId" = p_company_id OR "CompanyId" IS NULL);

EXCEPTION WHEN OTHERS THEN
    RAISE EXCEPTION '%', SQLERRM;
END;
$$;
-- +goose StatementEnd

-- =============================================================================
-- 44. usp_rest_pedido_get_by_mesa_header — RestaurantePedidos (legacy)
-- =============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_rest_pedido_get_by_mesa_header(
    p_company_id INTEGER,
    p_mesa_id integer
) RETURNS TABLE(id integer, "mesaId" integer, "clienteNombre" character varying, "clienteRif" character varying, estado character varying, total numeric, comentarios character varying, "fechaApertura" timestamp without time zone)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT
        p."Id",
        p."MesaId",
        p."ClienteNombre",
        p."ClienteRif",
        p."Estado",
        p."Total",
        p."Comentarios",
        p."FechaApertura"
    FROM "RestaurantePedidos" p
    WHERE p."MesaId" = p_mesa_id AND p."Estado" <> 'cerrado'
      AND (p."CompanyId" = p_company_id OR p."CompanyId" IS NULL)
    ORDER BY p."FechaApertura" DESC
    LIMIT 1;
END;
$$;
-- +goose StatementEnd

-- =============================================================================
-- 45. usp_rest_pedido_get_by_mesa_items — RestaurantePedidoItems (legacy)
-- =============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_rest_pedido_get_by_mesa_items(
    p_company_id INTEGER,
    p_mesa_id integer
) RETURNS TABLE(id integer, "pedidoId" integer, "productoId" character varying, nombre character varying, cantidad numeric, "precioUnitario" numeric, subtotal numeric, iva numeric, estado character varying, "esCompuesto" boolean, componentes text, comentarios character varying, "enviadoACocina" boolean, "horaEnvio" timestamp without time zone)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT
        i."Id",
        i."PedidoId",
        i."ProductoId",
        i."Nombre",
        i."Cantidad",
        i."PrecioUnitario",
        i."Subtotal",
        i."IvaPct",
        i."Estado",
        i."EsCompuesto",
        i."Componentes",
        i."Comentarios",
        i."EnviadoACocina",
        i."HoraEnvio"
    FROM "RestaurantePedidoItems" i
    INNER JOIN "RestaurantePedidos" p ON i."PedidoId" = p."Id"
    WHERE p."MesaId" = p_mesa_id AND p."Estado" <> 'cerrado'
      AND (p."CompanyId" = p_company_id OR p."CompanyId" IS NULL)
    ORDER BY i."Id";
END;
$$;
-- +goose StatementEnd

-- =============================================================================
-- 46. usp_rest_pedido_item_agregar — RestaurantePedidoItems (legacy)
-- =============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_rest_pedido_item_agregar(
    p_company_id INTEGER,
    p_pedido_id integer,
    p_producto_id character varying,
    p_nombre character varying,
    p_cantidad numeric,
    p_precio_unitario numeric,
    p_iva numeric DEFAULT NULL::numeric,
    p_es_compuesto boolean DEFAULT false,
    p_componentes text DEFAULT NULL::text,
    p_comentarios character varying DEFAULT NULL::character varying
) RETURNS TABLE("ItemId" integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_subtotal NUMERIC(18,2) := p_cantidad * p_precio_unitario;
    v_iva_pct  NUMERIC(9,4) := p_iva;
    v_item_id  INT;
BEGIN
    IF v_iva_pct IS NULL THEN
        SELECT
            CASE
                WHEN COALESCE(inv."PORCENTAJE", 0) > 1 THEN (inv."PORCENTAJE" / 100.0)::NUMERIC(9,4)
                ELSE COALESCE(inv."PORCENTAJE", 0)::NUMERIC(9,4)
            END
        INTO v_iva_pct
        FROM master."Product" inv
        WHERE COALESCE(inv."IsDeleted", FALSE) = FALSE
          AND TRIM(inv."ProductCode") = TRIM(p_producto_id)
          AND inv."CompanyId" = p_company_id
        LIMIT 1;
    END IF;

    IF v_iva_pct IS NULL THEN
        v_iva_pct := 0;
    END IF;

    INSERT INTO "RestaurantePedidoItems" ("PedidoId", "ProductoId", "Nombre", "Cantidad", "PrecioUnitario", "Subtotal", "IvaPct", "EsCompuesto", "Componentes", "Comentarios")
    VALUES (p_pedido_id, p_producto_id, p_nombre, p_cantidad, p_precio_unitario, v_subtotal, v_iva_pct, p_es_compuesto, p_componentes, p_comentarios)
    RETURNING "Id" INTO v_item_id;

    -- Recalcular total del pedido
    UPDATE "RestaurantePedidos"
    SET "Total" = (SELECT COALESCE(SUM("Subtotal"), 0) FROM "RestaurantePedidoItems" WHERE "PedidoId" = p_pedido_id)
    WHERE "Id" = p_pedido_id
      AND ("CompanyId" = p_company_id OR "CompanyId" IS NULL);

    RETURN QUERY SELECT v_item_id AS "ItemId";
END;
$$;
-- +goose StatementEnd

-- =============================================================================
-- 47. usp_rest_producto_delete — RestauranteProductos (legacy)
-- =============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_rest_producto_delete(
    p_company_id INTEGER,
    p_id integer
) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE "RestauranteProductos"
    SET "Activo" = FALSE
    WHERE "Id" = p_id
      AND ("CompanyId" = p_company_id OR "CompanyId" IS NULL);
END;
$$;
-- +goose StatementEnd

-- =============================================================================
-- 48. usp_rest_producto_get — RestauranteProductos (legacy)
-- =============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_rest_producto_get(
    p_company_id INTEGER,
    p_id integer
) RETURNS TABLE(id integer, codigo character varying, nombre character varying, descripcion character varying, precio numeric, "categoriaId" integer, categoria character varying, "esCompuesto" boolean, "tiempoPreparacion" integer, imagen character varying, "esSugerenciaDelDia" boolean, disponible boolean, iva numeric, "costoEstimado" numeric, "articuloInventarioId" character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT
        p."Id", p."Codigo", p."Nombre", p."Descripcion",
        p."Precio", p."CategoriaId", c."Nombre",
        p."EsCompuesto", p."TiempoPreparacion",
        p."Imagen", p."EsSugerenciaDelDia",
        p."Disponible", p."IVA", p."CostoEstimado",
        p."ArticuloInventarioId"
    FROM "RestauranteProductos" p
    LEFT JOIN "RestauranteCategorias" c ON c."Id" = p."CategoriaId"
    WHERE p."Id" = p_id
      AND (p."CompanyId" = p_company_id OR p."CompanyId" IS NULL);
END;
$$;
-- +goose StatementEnd

-- =============================================================================
-- 49. usp_rest_producto_get_componentes — RestauranteProductoComponentes (legacy)
-- =============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_rest_producto_get_componentes(
    p_company_id INTEGER,
    p_id integer
) RETURNS TABLE(id integer, nombre character varying, obligatorio boolean, orden integer, "opcionId" integer, "opcionNombre" character varying, "precioExtra" numeric, "opcionOrden" integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT
        comp."Id", comp."Nombre", comp."Obligatorio", comp."Orden",
        opc."Id", opc."Nombre", opc."PrecioExtra", opc."Orden"
    FROM "RestauranteProductoComponentes" comp
    LEFT JOIN "RestauranteComponenteOpciones" opc ON opc."ComponenteId" = comp."Id"
    INNER JOIN "RestauranteProductos" pr ON pr."Id" = comp."ProductoId"
    WHERE comp."ProductoId" = p_id
      AND (pr."CompanyId" = p_company_id OR pr."CompanyId" IS NULL)
    ORDER BY comp."Orden", opc."Orden";
END;
$$;
-- +goose StatementEnd

-- =============================================================================
-- 50. usp_rest_producto_get_receta — RestauranteRecetas (legacy)
-- =============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_rest_producto_get_receta(
    p_company_id INTEGER,
    p_id integer
) RETURNS TABLE(id integer, "inventarioId" character varying, "inventarioNombre" character varying, cantidad numeric, unidad character varying, comentario character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT
        r."Id", r."InventarioId",
        i."ProductName",
        r."Cantidad", r."Unidad", r."Comentario"
    FROM "RestauranteRecetas" r
    LEFT JOIN master."Product" i ON i."ProductCode" = r."InventarioId"
    INNER JOIN "RestauranteProductos" pr ON pr."Id" = r."ProductoId"
    WHERE r."ProductoId" = p_id
      AND (pr."CompanyId" = p_company_id OR pr."CompanyId" IS NULL);
END;
$$;
-- +goose StatementEnd

-- =============================================================================
-- 51. usp_rest_producto_upsert — RestauranteProductos (legacy)
-- =============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_rest_producto_upsert(
    p_company_id INTEGER,
    p_id integer DEFAULT 0,
    p_codigo character varying DEFAULT ''::character varying,
    p_nombre character varying DEFAULT ''::character varying,
    p_descripcion character varying DEFAULT NULL::character varying,
    p_categoria_id integer DEFAULT NULL::integer,
    p_precio numeric DEFAULT 0,
    p_costo_estimado numeric DEFAULT 0,
    p_iva numeric DEFAULT 16,
    p_es_compuesto boolean DEFAULT false,
    p_tiempo_preparacion integer DEFAULT 0,
    p_imagen character varying DEFAULT NULL::character varying,
    p_es_sugerencia_del_dia boolean DEFAULT false,
    p_disponible boolean DEFAULT true,
    p_articulo_inventario_id character varying DEFAULT NULL::character varying
) RETURNS TABLE("ResultId" integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_result_id INT;
BEGIN
    IF p_id > 0 AND EXISTS (
        SELECT 1 FROM "RestauranteProductos"
        WHERE "Id" = p_id AND ("CompanyId" = p_company_id OR "CompanyId" IS NULL)
    ) THEN
        UPDATE "RestauranteProductos" SET
            "Codigo" = p_codigo, "Nombre" = p_nombre, "Descripcion" = p_descripcion,
            "CategoriaId" = p_categoria_id, "Precio" = p_precio, "CostoEstimado" = p_costo_estimado,
            "IVA" = p_iva, "EsCompuesto" = p_es_compuesto, "TiempoPreparacion" = p_tiempo_preparacion,
            "Imagen" = p_imagen, "EsSugerenciaDelDia" = p_es_sugerencia_del_dia,
            "Disponible" = p_disponible, "ArticuloInventarioId" = p_articulo_inventario_id,
            "FechaModificacion" = NOW() AT TIME ZONE 'UTC'
        WHERE "Id" = p_id AND ("CompanyId" = p_company_id OR "CompanyId" IS NULL);
        v_result_id := p_id;
    ELSE
        INSERT INTO "RestauranteProductos" ("Codigo", "Nombre", "Descripcion", "CategoriaId", "Precio", "CostoEstimado", "IVA", "EsCompuesto", "TiempoPreparacion", "Imagen", "EsSugerenciaDelDia", "Disponible", "ArticuloInventarioId")
        VALUES (p_codigo, p_nombre, p_descripcion, p_categoria_id, p_precio, p_costo_estimado, p_iva, p_es_compuesto, p_tiempo_preparacion, p_imagen, p_es_sugerencia_del_dia, p_disponible, p_articulo_inventario_id)
        RETURNING "Id" INTO v_result_id;
    END IF;

    RETURN QUERY SELECT v_result_id;
END;
$$;
-- +goose StatementEnd

-- =============================================================================
-- 52. usp_rest_productos_list — RestauranteProductos (legacy)
-- =============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_rest_productos_list(
    p_company_id INTEGER,
    p_categoria_id integer DEFAULT NULL::integer,
    p_search character varying DEFAULT NULL::character varying,
    p_solo_disponibles boolean DEFAULT true
) RETURNS TABLE(id integer, codigo character varying, nombre character varying, descripcion character varying, precio numeric, "categoriaId" integer, categoria character varying, "esCompuesto" boolean, "tiempoPreparacion" integer, imagen character varying, "esSugerenciaDelDia" boolean, disponible boolean, iva numeric, "costoEstimado" numeric)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT
        p."Id",
        p."Codigo",
        p."Nombre",
        p."Descripcion",
        p."Precio",
        p."CategoriaId",
        c."Nombre",
        p."EsCompuesto",
        p."TiempoPreparacion",
        p."Imagen",
        p."EsSugerenciaDelDia",
        p."Disponible",
        p."IVA",
        p."CostoEstimado"
    FROM "RestauranteProductos" p
    LEFT JOIN "RestauranteCategorias" c ON c."Id" = p."CategoriaId"
    WHERE p."Activo" = TRUE
      AND (p."CompanyId" = p_company_id OR p."CompanyId" IS NULL)
      AND (p_solo_disponibles = FALSE OR p."Disponible" = TRUE)
      AND (p_categoria_id IS NULL OR p."CategoriaId" = p_categoria_id)
      AND (p_search IS NULL OR p."Nombre" ILIKE '%' || p_search || '%' OR p."Codigo" ILIKE '%' || p_search || '%')
    ORDER BY c."Orden", p."Nombre";
END;
$$;
-- +goose StatementEnd

-- =============================================================================
-- 53. usp_rest_receta_upsert — RestauranteRecetas (legacy)
-- =============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_rest_receta_upsert(
    p_company_id INTEGER,
    p_id integer DEFAULT 0,
    p_producto_id integer DEFAULT 0,
    p_inventario_id character varying DEFAULT ''::character varying,
    p_cantidad numeric DEFAULT 0,
    p_unidad character varying DEFAULT NULL::character varying,
    p_comentario character varying DEFAULT NULL::character varying
) RETURNS TABLE("ResultId" integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_result_id INT;
BEGIN
    IF p_id > 0 AND EXISTS (SELECT 1 FROM "RestauranteRecetas" WHERE "Id" = p_id) THEN
        UPDATE "RestauranteRecetas"
        SET "InventarioId" = p_inventario_id, "Cantidad" = p_cantidad, "Unidad" = p_unidad, "Comentario" = p_comentario
        WHERE "Id" = p_id;
        v_result_id := p_id;
    ELSE
        INSERT INTO "RestauranteRecetas" ("ProductoId", "InventarioId", "Cantidad", "Unidad", "Comentario")
        VALUES (p_producto_id, p_inventario_id, p_cantidad, p_unidad, p_comentario)
        RETURNING "Id" INTO v_result_id;
    END IF;

    RETURN QUERY SELECT v_result_id;
END;
$$;
-- +goose StatementEnd

-- =============================================================================
-- 54. usp_rest_recipe_getingredients — RestauranteRecetas/Productos (legacy)
-- =============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_rest_recipe_getingredients(
    p_company_id INTEGER,
    p_product_code character varying
) RETURNS TABLE("InventarioId" character varying, "Cantidad" numeric)
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'RestauranteRecetas') THEN
        RETURN QUERY
        SELECT
            r."InventarioId",
            r."Cantidad"
        FROM "RestauranteRecetas" r
        INNER JOIN "RestauranteProductos" p ON p."Id" = r."ProductoId"
        WHERE p."Codigo" = p_product_code
          AND (p."CompanyId" = p_company_id OR p."CompanyId" IS NULL);
    END IF;
END;
$$;
-- +goose StatementEnd


-- +goose Down
-- Revertir al estado original sin p_company_id

-- 1. usp_acct_rest_getheader
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_acct_rest_getheader(p_order_ticket_id bigint) RETURNS TABLE(id bigint, total numeric, "fechaCierre" timestamp without time zone, "codUsuario" character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT o."OrderTicketId" AS "id", o."TotalAmount" AS "total", o."ClosedAt" AS "fechaCierre",
        COALESCE(uclose."UserCode", uopen."UserCode")::VARCHAR AS "codUsuario"
    FROM rest."OrderTicket" o
    LEFT JOIN sec."User" uopen ON uopen."UserId" = o."OpenedByUserId"
    LEFT JOIN sec."User" uclose ON uclose."UserId" = o."ClosedByUserId"
    WHERE o."OrderTicketId" = p_order_ticket_id LIMIT 1;
END; $$;
-- +goose StatementEnd

-- 2. usp_acct_rest_gettaxsummary
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_acct_rest_gettaxsummary(p_order_ticket_id bigint) RETURNS TABLE("taxRate" numeric, "baseAmount" numeric, "taxAmount" numeric, "totalAmount" numeric)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT otl."TaxRate", SUM(otl."NetAmount"), SUM(otl."TaxAmount"), SUM(otl."TotalAmount")
    FROM rest."OrderTicketLine" otl WHERE otl."OrderTicketId" = p_order_ticket_id GROUP BY otl."TaxRate";
END; $$;
-- +goose StatementEnd

-- 3. usp_rest_admin_adjuststock
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_rest_admin_adjuststock(p_product_id bigint, p_delta_qty numeric) RETURNS void
    LANGUAGE plpgsql AS $$
BEGIN
    IF p_product_id IS NULL OR p_delta_qty = 0 THEN RETURN; END IF;
    UPDATE master."Product" SET "StockQty" = COALESCE("StockQty", 0) + p_delta_qty, "UpdatedAt" = NOW() AT TIME ZONE 'UTC' WHERE "ProductId" = p_product_id;
END; $$;
-- +goose StatementEnd

-- 4. usp_rest_admin_componente_upsert
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_rest_admin_componente_upsert(p_id integer DEFAULT 0, p_producto_id integer DEFAULT NULL, p_nombre character varying DEFAULT NULL, p_obligatorio boolean DEFAULT false, p_orden integer DEFAULT 0) RETURNS TABLE(id integer)
    LANGUAGE plpgsql AS $$
DECLARE v_id INT;
BEGIN
    IF p_id > 0 AND EXISTS (SELECT 1 FROM rest."MenuComponent" WHERE "MenuComponentId" = p_id) THEN
        UPDATE rest."MenuComponent" SET "ComponentName"=p_nombre,"IsRequired"=p_obligatorio,"SortOrder"=p_orden,"UpdatedAt"=NOW() AT TIME ZONE 'UTC' WHERE "MenuComponentId"=p_id;
        RETURN QUERY SELECT p_id;
    ELSE
        INSERT INTO rest."MenuComponent" ("MenuProductId","ComponentName","IsRequired","SortOrder","IsActive") VALUES (p_producto_id,p_nombre,p_obligatorio,p_orden,TRUE) RETURNING "MenuComponentId" INTO v_id;
        RETURN QUERY SELECT v_id;
    END IF;
END; $$;
-- +goose StatementEnd

-- 5. usp_rest_admin_compra_getdetalle_header
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_rest_admin_compra_getdetalle_header(p_compra_id bigint) RETURNS TABLE(id bigint, "numCompra" character varying, "proveedorId" character varying, "proveedorNombre" character varying, "fechaCompra" timestamp without time zone, estado character varying, subtotal numeric, iva numeric, total numeric, observaciones character varying, "codUsuario" character varying)
    LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY SELECT p."PurchaseId",p."PurchaseNumber",s."SupplierCode",s."SupplierName",p."PurchaseDate",p."Status",p."SubtotalAmount",p."TaxAmount",p."TotalAmount",p."Notes",u."UserCode"
    FROM rest."Purchase" p LEFT JOIN master."Supplier" s ON s."SupplierId"=p."SupplierId" LEFT JOIN sec."User" u ON u."UserId"=p."CreatedByUserId" WHERE p."PurchaseId"=p_compra_id LIMIT 1;
END; $$;
-- +goose StatementEnd

-- 6. usp_rest_admin_compra_getdetalle_lines
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_rest_admin_compra_getdetalle_lines(p_compra_id bigint) RETURNS TABLE(id bigint, "compraId" bigint, "inventarioId" character varying, descripcion character varying, cantidad numeric, "precioUnit" numeric, subtotal numeric, iva numeric)
    LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY SELECT pl."PurchaseLineId",pl."PurchaseId",pr."ProductCode",pl."DescriptionText",pl."Quantity",pl."UnitPrice",pl."SubtotalAmount",pl."TaxRatePercent"
    FROM rest."PurchaseLine" pl LEFT JOIN master."Product" pr ON pr."ProductId"=pl."IngredientProductId" WHERE pl."PurchaseId"=p_compra_id ORDER BY pl."PurchaseLineId";
END; $$;
-- +goose StatementEnd

-- 7. usp_rest_admin_compra_recalctotals
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_rest_admin_compra_recalctotals(p_purchase_id integer) RETURNS void
    LANGUAGE plpgsql AS $$
DECLARE v_subtotal NUMERIC(18,2); v_tax NUMERIC(18,2); v_total NUMERIC(18,2);
BEGIN
    SELECT COALESCE(SUM("SubtotalAmount"),0),COALESCE(SUM("SubtotalAmount"*"TaxRatePercent"/100.0),0),COALESCE(SUM("SubtotalAmount"+("SubtotalAmount"*"TaxRatePercent"/100.0)),0) INTO v_subtotal,v_tax,v_total FROM rest."PurchaseLine" WHERE "PurchaseId"=p_purchase_id;
    UPDATE rest."Purchase" SET "SubtotalAmount"=v_subtotal,"TaxAmount"=v_tax,"TotalAmount"=v_total,"UpdatedAt"=NOW() AT TIME ZONE 'UTC' WHERE "PurchaseId"=p_purchase_id;
END; $$;
-- +goose StatementEnd

-- 8. usp_rest_admin_compra_update
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_rest_admin_compra_update(p_compra_id integer, p_supplier_id bigint DEFAULT NULL, p_status character varying DEFAULT NULL, p_notes character varying DEFAULT NULL) RETURNS void
    LANGUAGE plpgsql AS $$
BEGIN
    UPDATE rest."Purchase" SET "SupplierId"=COALESCE(p_supplier_id,"SupplierId"),"Status"=COALESCE(p_status,"Status"),"Notes"=COALESCE(p_notes,"Notes"),"UpdatedAt"=NOW() AT TIME ZONE 'UTC' WHERE "PurchaseId"=p_compra_id;
END; $$;
-- +goose StatementEnd

-- 9. usp_rest_admin_compralinea_delete
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_rest_admin_compralinea_delete(p_compra_id integer, p_detalle_id integer) RETURNS TABLE("ingredientProductId" bigint, quantity numeric)
    LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY SELECT pl."IngredientProductId",pl."Quantity" FROM rest."PurchaseLine" pl WHERE pl."PurchaseLineId"=p_detalle_id AND pl."PurchaseId"=p_compra_id LIMIT 1;
    DELETE FROM rest."PurchaseLine" WHERE "PurchaseLineId"=p_detalle_id AND "PurchaseId"=p_compra_id;
END; $$;
-- +goose StatementEnd

-- 10. usp_rest_admin_compralinea_getprev
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_rest_admin_compralinea_getprev(p_id integer, p_compra_id integer) RETURNS TABLE("ingredientProductId" bigint, quantity numeric)
    LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY SELECT pl."IngredientProductId",pl."Quantity" FROM rest."PurchaseLine" pl WHERE pl."PurchaseLineId"=p_id AND pl."PurchaseId"=p_compra_id LIMIT 1;
END; $$;
-- +goose StatementEnd

-- 11. usp_rest_admin_compralinea_upsert
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_rest_admin_compralinea_upsert(p_id integer DEFAULT 0, p_compra_id integer DEFAULT NULL, p_ingredient_product_id bigint DEFAULT NULL, p_descripcion character varying DEFAULT NULL, p_quantity numeric DEFAULT NULL, p_unit_price numeric DEFAULT NULL, p_tax_rate_percent numeric DEFAULT 16, p_subtotal numeric DEFAULT NULL) RETURNS TABLE(id integer)
    LANGUAGE plpgsql AS $$
DECLARE v_id INT;
BEGIN
    IF p_id > 0 THEN
        UPDATE rest."PurchaseLine" SET "IngredientProductId"=p_ingredient_product_id,"DescriptionText"=p_descripcion,"Quantity"=p_quantity,"UnitPrice"=p_unit_price,"TaxRatePercent"=p_tax_rate_percent,"SubtotalAmount"=p_subtotal,"UpdatedAt"=NOW() AT TIME ZONE 'UTC' WHERE "PurchaseLineId"=p_id AND "PurchaseId"=p_compra_id;
        RETURN QUERY SELECT p_id;
    ELSE
        INSERT INTO rest."PurchaseLine" ("PurchaseId","IngredientProductId","DescriptionText","Quantity","UnitPrice","TaxRatePercent","SubtotalAmount") VALUES (p_compra_id,p_ingredient_product_id,p_descripcion,p_quantity,p_unit_price,p_tax_rate_percent,p_subtotal) RETURNING "PurchaseLineId" INTO v_id;
        RETURN QUERY SELECT v_id;
    END IF;
END; $$;
-- +goose StatementEnd

-- 12. usp_rest_admin_opcion_upsert
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_rest_admin_opcion_upsert(p_id integer DEFAULT 0, p_componente_id integer DEFAULT NULL, p_nombre character varying DEFAULT NULL, p_precio_extra numeric DEFAULT 0, p_orden integer DEFAULT 0) RETURNS TABLE(id integer)
    LANGUAGE plpgsql AS $$
DECLARE v_id INT;
BEGIN
    IF p_id > 0 AND EXISTS (SELECT 1 FROM rest."MenuOption" WHERE "MenuOptionId"=p_id) THEN
        UPDATE rest."MenuOption" SET "OptionName"=p_nombre,"ExtraPrice"=p_precio_extra,"SortOrder"=p_orden,"UpdatedAt"=NOW() AT TIME ZONE 'UTC' WHERE "MenuOptionId"=p_id;
        RETURN QUERY SELECT p_id;
    ELSE
        INSERT INTO rest."MenuOption" ("MenuComponentId","OptionName","ExtraPrice","SortOrder","IsActive") VALUES (p_componente_id,p_nombre,p_precio_extra,p_orden,TRUE) RETURNING "MenuOptionId" INTO v_id;
        RETURN QUERY SELECT v_id;
    END IF;
END; $$;
-- +goose StatementEnd

-- 13. usp_rest_admin_producto_delete
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_rest_admin_producto_delete(p_id integer) RETURNS void
    LANGUAGE plpgsql AS $$
BEGIN
    UPDATE rest."MenuProduct" SET "IsActive"=FALSE,"IsAvailable"=FALSE,"UpdatedAt"=NOW() AT TIME ZONE 'UTC' WHERE "MenuProductId"=p_id;
END; $$;
-- +goose StatementEnd

-- 14. usp_rest_admin_producto_get
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_rest_admin_producto_get(p_id bigint, p_branch_id integer) RETURNS TABLE(id bigint, codigo character varying, nombre character varying, descripcion character varying, "categoriaId" bigint, precio numeric, "costoEstimado" numeric, iva numeric, "esCompuesto" boolean, "tiempoPreparacion" integer, imagen character varying, "esSugerenciaDelDia" boolean, disponible boolean, "articuloInventarioId" character varying)
    LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT mp."MenuProductId",mp."ProductCode",mp."ProductName",mp."DescriptionText",mp."MenuCategoryId",mp."PriceAmount",mp."EstimatedCost",mp."TaxRatePercent",mp."IsComposite",mp."PrepMinutes",COALESCE(img."PublicUrl",mp."ImageUrl"),mp."IsDailySuggestion",mp."IsAvailable",inv."ProductCode"
    FROM rest."MenuProduct" mp LEFT JOIN master."Product" inv ON inv."ProductId"=mp."InventoryProductId"
    LEFT JOIN LATERAL (SELECT ma."PublicUrl" FROM cfg."EntityImage" ei INNER JOIN cfg."MediaAsset" ma ON ma."MediaAssetId"=ei."MediaAssetId" WHERE ei."CompanyId"=mp."CompanyId" AND ei."BranchId"=mp."BranchId" AND ei."EntityType"='REST_MENU_PRODUCT' AND ei."EntityId"=mp."MenuProductId" AND ei."IsDeleted"=FALSE AND ei."IsActive"=TRUE AND ma."IsDeleted"=FALSE AND ma."IsActive"=TRUE ORDER BY CASE WHEN ei."IsPrimary"=TRUE THEN 0 ELSE 1 END,ei."SortOrder",ei."EntityImageId" LIMIT 1) img ON TRUE
    WHERE mp."MenuProductId"=p_id AND mp."IsActive"=TRUE LIMIT 1;
END; $$;
-- +goose StatementEnd

-- 15. usp_rest_admin_producto_get_componentes
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_rest_admin_producto_get_componentes(p_id bigint) RETURNS TABLE(id bigint, nombre character varying, obligatorio boolean, orden integer, "opcionId" bigint, "opcionNombre" character varying, "precioExtra" numeric, "opcionOrden" integer)
    LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY SELECT c."MenuComponentId",c."ComponentName",c."IsRequired",c."SortOrder",o."MenuOptionId",o."OptionName",o."ExtraPrice",o."SortOrder"
    FROM rest."MenuComponent" c LEFT JOIN rest."MenuOption" o ON o."MenuComponentId"=c."MenuComponentId" AND o."IsActive"=TRUE
    WHERE c."MenuProductId"=p_id AND c."IsActive"=TRUE ORDER BY c."SortOrder",c."MenuComponentId",o."SortOrder",o."MenuOptionId";
END; $$;
-- +goose StatementEnd

-- 16. usp_rest_admin_producto_get_receta
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_rest_admin_producto_get_receta(p_id bigint, p_branch_id integer) RETURNS TABLE(id bigint, "productoId" bigint, "inventarioId" character varying, descripcion character varying, imagen character varying, cantidad numeric, unidad character varying, comentario character varying)
    LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT r."MenuRecipeId",r."MenuProductId",p."ProductCode",p."ProductName",img."PublicUrl",r."Quantity",r."UnitCode",r."Notes"
    FROM rest."MenuRecipe" r INNER JOIN master."Product" p ON p."ProductId"=r."IngredientProductId"
    LEFT JOIN LATERAL (SELECT ma."PublicUrl" FROM cfg."EntityImage" ei INNER JOIN cfg."MediaAsset" ma ON ma."MediaAssetId"=ei."MediaAssetId" WHERE ei."CompanyId"=p."CompanyId" AND ei."BranchId"=p_branch_id AND ei."EntityType"='MASTER_PRODUCT' AND ei."EntityId"=p."ProductId" AND ei."IsDeleted"=FALSE AND ei."IsActive"=TRUE AND ma."IsDeleted"=FALSE AND ma."IsActive"=TRUE ORDER BY CASE WHEN ei."IsPrimary"=TRUE THEN 0 ELSE 1 END,ei."SortOrder",ei."EntityImageId" LIMIT 1) img ON TRUE
    WHERE r."MenuProductId"=p_id AND r."IsActive"=TRUE ORDER BY r."MenuRecipeId";
END; $$;
-- +goose StatementEnd

-- 17. usp_rest_admin_receta_delete
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_rest_admin_receta_delete(p_id integer) RETURNS void
    LANGUAGE plpgsql AS $$
BEGIN UPDATE rest."MenuRecipe" SET "IsActive"=FALSE,"UpdatedAt"=NOW() AT TIME ZONE 'UTC' WHERE "MenuRecipeId"=p_id; END; $$;
-- +goose StatementEnd

-- 18. usp_rest_admin_receta_upsert
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_rest_admin_receta_upsert(p_id integer DEFAULT 0, p_producto_id integer DEFAULT NULL, p_ingredient_product_id bigint DEFAULT NULL, p_quantity numeric DEFAULT NULL, p_unit_code character varying DEFAULT NULL, p_notes character varying DEFAULT NULL) RETURNS TABLE(id integer)
    LANGUAGE plpgsql AS $$
DECLARE v_id INT;
BEGIN
    IF p_id > 0 AND EXISTS (SELECT 1 FROM rest."MenuRecipe" WHERE "MenuRecipeId"=p_id) THEN
        UPDATE rest."MenuRecipe" SET "IngredientProductId"=p_ingredient_product_id,"Quantity"=p_quantity,"UnitCode"=p_unit_code,"Notes"=p_notes,"IsActive"=TRUE,"UpdatedAt"=NOW() AT TIME ZONE 'UTC' WHERE "MenuRecipeId"=p_id;
        RETURN QUERY SELECT p_id;
    ELSE
        INSERT INTO rest."MenuRecipe" ("MenuProductId","IngredientProductId","Quantity","UnitCode","Notes","IsActive") VALUES (p_producto_id,p_ingredient_product_id,p_quantity,p_unit_code,p_notes,TRUE) RETURNING "MenuRecipeId" INTO v_id;
        RETURN QUERY SELECT v_id;
    END IF;
END; $$;
-- +goose StatementEnd

-- 19. usp_rest_admin_resolvemenucategory
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_rest_admin_resolvemenucategory(p_menu_category_id integer) RETURNS TABLE(id integer)
    LANGUAGE plpgsql AS $$
BEGIN RETURN QUERY SELECT mc."MenuCategoryId" FROM rest."MenuCategory" mc WHERE mc."MenuCategoryId"=p_menu_category_id LIMIT 1; END; $$;
-- +goose StatementEnd

-- 20. usp_rest_orderticket_checkpriorvoid
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_rest_orderticket_checkpriorvoid(p_pedido_id bigint, p_item_id bigint) RETURNS TABLE("alreadyVoided" integer)
    LANGUAGE plpgsql AS $$ BEGIN
    RETURN QUERY SELECT 1 FROM sec."SupervisorOverride" WHERE "ModuleCode"='RESTAURANTE' AND "ActionCode"='ORDER_LINE_VOID' AND "Status"='CONSUMED' AND "SourceDocumentId"=p_pedido_id AND "SourceLineId"=p_item_id LIMIT 1;
END; $$;
-- +goose StatementEnd

-- 21. usp_rest_orderticket_close
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_rest_orderticket_close(p_pedido_id bigint, p_closed_by_user_id integer DEFAULT NULL) RETURNS TABLE("Resultado" integer, "Mensaje" character varying)
    LANGUAGE plpgsql AS $$ BEGIN
    UPDATE rest."OrderTicket" SET "Status"='CLOSED',"ClosedByUserId"=p_closed_by_user_id,"ClosedAt"=NOW() AT TIME ZONE 'UTC',"UpdatedAt"=NOW() AT TIME ZONE 'UTC' WHERE "OrderTicketId"=p_pedido_id;
    RETURN QUERY SELECT 1,'OK'::VARCHAR(500);
END; $$;
-- +goose StatementEnd

-- 22. usp_rest_orderticket_getbyid
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_rest_orderticket_getbyid(p_pedido_id bigint) RETURNS TABLE("orderId" bigint, "companyId" integer, "branchId" integer, "countryCode" character varying, status character varying)
    LANGUAGE plpgsql AS $$ BEGIN
    RETURN QUERY SELECT ot."OrderTicketId",ot."CompanyId",ot."BranchId",ot."CountryCode"::VARCHAR,ot."Status"::VARCHAR FROM rest."OrderTicket" ot WHERE ot."OrderTicketId"=p_pedido_id LIMIT 1;
END; $$;
-- +goose StatementEnd

-- 23. usp_rest_orderticket_getheaderforclose
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_rest_orderticket_getheaderforclose(p_pedido_id bigint) RETURNS TABLE(id bigint, "empresaId" integer, "sucursalId" integer, "countryCode" character varying, "mesaId" bigint, "clienteNombre" character varying, "clienteRif" character varying, estado character varying, total numeric, "fechaCierre" timestamp without time zone, "codUsuario" character varying)
    LANGUAGE plpgsql AS $$ BEGIN
    RETURN QUERY SELECT o."OrderTicketId",o."CompanyId",o."BranchId",o."CountryCode"::VARCHAR,dt."DiningTableId",o."CustomerName"::VARCHAR,o."CustomerFiscalId"::VARCHAR,o."Status"::VARCHAR,o."TotalAmount",o."ClosedAt",COALESCE(uc."UserCode",uo."UserCode")::VARCHAR
    FROM rest."OrderTicket" o LEFT JOIN rest."DiningTable" dt ON dt."CompanyId"=o."CompanyId" AND dt."BranchId"=o."BranchId" AND dt."TableNumber"=o."TableNumber" LEFT JOIN sec."User" uo ON uo."UserId"=o."OpenedByUserId" LEFT JOIN sec."User" uc ON uc."UserId"=o."ClosedByUserId" WHERE o."OrderTicketId"=p_pedido_id LIMIT 1;
END; $$;
-- +goose StatementEnd

-- 24. usp_rest_orderticket_recalctotals
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_rest_orderticket_recalctotals(p_order_id bigint) RETURNS void
    LANGUAGE plpgsql AS $$
DECLARE v_net NUMERIC(18,2); v_tax NUMERIC(18,2); v_total NUMERIC(18,2);
BEGIN
    SELECT COALESCE(SUM("NetAmount"),0),COALESCE(SUM("TaxAmount"),0),COALESCE(SUM("TotalAmount"),0) INTO v_net,v_tax,v_total FROM rest."OrderTicketLine" WHERE "OrderTicketId"=p_order_id;
    UPDATE rest."OrderTicket" SET "NetAmount"=v_net,"TaxAmount"=v_tax,"TotalAmount"=v_total,"UpdatedAt"=NOW() AT TIME ZONE 'UTC' WHERE "OrderTicketId"=p_order_id;
END; $$;
-- +goose StatementEnd

-- 25. usp_rest_orderticket_sendtokitchen
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_rest_orderticket_sendtokitchen(p_pedido_id bigint) RETURNS TABLE("Resultado" integer, "Mensaje" character varying)
    LANGUAGE plpgsql AS $$ BEGIN
    UPDATE rest."OrderTicket" SET "Status"=CASE WHEN "Status"='OPEN' THEN 'SENT' ELSE "Status" END,"UpdatedAt"=NOW() AT TIME ZONE 'UTC' WHERE "OrderTicketId"=p_pedido_id;
    RETURN QUERY SELECT 1,'OK'::VARCHAR(500);
END; $$;
-- +goose StatementEnd

-- 26. usp_rest_orderticket_updatetimestamp
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_rest_orderticket_updatetimestamp(p_pedido_id bigint) RETURNS void
    LANGUAGE plpgsql AS $$ BEGIN
    UPDATE rest."OrderTicket" SET "UpdatedAt"=NOW() AT TIME ZONE 'UTC' WHERE "OrderTicketId"=p_pedido_id;
END; $$;
-- +goose StatementEnd

-- 27. usp_rest_orderticketline_getbyid
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_rest_orderticketline_getbyid(p_pedido_id bigint, p_item_id bigint) RETURNS TABLE("itemId" bigint, "lineNumber" integer, "countryCode" character varying, "productId" bigint, "productCode" character varying, nombre character varying, cantidad numeric, "unitPrice" numeric, "taxCode" character varying, "taxRate" numeric, "netAmount" numeric, "taxAmount" numeric, "totalAmount" numeric)
    LANGUAGE plpgsql AS $$ BEGIN
    RETURN QUERY SELECT ol."OrderTicketLineId",ol."LineNumber",ol."CountryCode"::VARCHAR,ol."ProductId",ol."ProductCode"::VARCHAR,ol."ProductName"::VARCHAR,ol."Quantity",ol."UnitPrice",ol."TaxCode"::VARCHAR,ol."TaxRate",ol."NetAmount",ol."TaxAmount",ol."TotalAmount"
    FROM rest."OrderTicketLine" ol WHERE ol."OrderTicketId"=p_pedido_id AND ol."OrderTicketLineId"=p_item_id LIMIT 1;
END; $$;
-- +goose StatementEnd

-- 28. usp_rest_orderticketline_getbypedido
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_rest_orderticketline_getbypedido(p_pedido_id bigint) RETURNS TABLE(id bigint, "productoId" character varying, nombre character varying, cantidad numeric, "precioUnitario" numeric, subtotal numeric, iva numeric, "taxCode" character varying, impuesto numeric, total numeric)
    LANGUAGE plpgsql AS $$ BEGIN
    RETURN QUERY SELECT ol."OrderTicketLineId",ol."ProductCode"::VARCHAR,ol."ProductName"::VARCHAR,ol."Quantity",ol."UnitPrice",ol."NetAmount",CASE WHEN ol."TaxRate">1 THEN ol."TaxRate" ELSE ol."TaxRate"*100 END,ol."TaxCode"::VARCHAR,ol."TaxAmount",ol."TotalAmount"
    FROM rest."OrderTicketLine" ol WHERE ol."OrderTicketId"=p_pedido_id ORDER BY ol."LineNumber";
END; $$;
-- +goose StatementEnd

-- 29. usp_rest_orderticketline_getfiscalbreakdown
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_rest_orderticketline_getfiscalbreakdown(p_pedido_id bigint) RETURNS TABLE("itemId" bigint, "productoId" character varying, nombre character varying, quantity numeric, "unitPrice" numeric, "baseAmount" numeric, "taxCode" character varying, "taxRate" numeric, "taxAmount" numeric, "totalAmount" numeric)
    LANGUAGE plpgsql AS $$ BEGIN
    RETURN QUERY SELECT ol."OrderTicketLineId",ol."ProductCode"::VARCHAR,ol."ProductName"::VARCHAR,ol."Quantity",ol."UnitPrice",ol."NetAmount",ol."TaxCode"::VARCHAR,ol."TaxRate",ol."TaxAmount",ol."TotalAmount"
    FROM rest."OrderTicketLine" ol WHERE ol."OrderTicketId"=p_pedido_id ORDER BY ol."LineNumber";
END; $$;
-- +goose StatementEnd

-- 30. usp_rest_orderticketline_insert
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_rest_orderticketline_insert(p_order_id bigint, p_line_number integer, p_country_code character varying, p_product_id bigint DEFAULT NULL, p_product_code character varying DEFAULT NULL, p_product_name character varying DEFAULT NULL, p_quantity numeric DEFAULT NULL, p_unit_price numeric DEFAULT NULL, p_tax_code character varying DEFAULT NULL, p_tax_rate numeric DEFAULT NULL, p_net_amount numeric DEFAULT NULL, p_tax_amount numeric DEFAULT NULL, p_total_amount numeric DEFAULT NULL, p_notes character varying DEFAULT NULL, p_supervisor_approval_id integer DEFAULT NULL) RETURNS TABLE("Resultado" bigint, "Mensaje" character varying)
    LANGUAGE plpgsql AS $$
DECLARE v_id BIGINT;
BEGIN
    INSERT INTO rest."OrderTicketLine" ("OrderTicketId","LineNumber","CountryCode","ProductId","ProductCode","ProductName","Quantity","UnitPrice","TaxCode","TaxRate","NetAmount","TaxAmount","TotalAmount","Notes","SupervisorApprovalId","CreatedAt","UpdatedAt")
    VALUES (p_order_id,p_line_number,p_country_code,p_product_id,p_product_code,p_product_name,p_quantity,p_unit_price,p_tax_code,p_tax_rate,p_net_amount,p_tax_amount,p_total_amount,p_notes,p_supervisor_approval_id,NOW() AT TIME ZONE 'UTC',NOW() AT TIME ZONE 'UTC')
    RETURNING "OrderTicketLineId" INTO v_id;
    RETURN QUERY SELECT v_id,'OK'::VARCHAR(500);
END; $$;
-- +goose StatementEnd

-- 31. usp_rest_orderticketline_nextlinenumber
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_rest_orderticketline_nextlinenumber(p_order_id bigint) RETURNS TABLE("nextLine" integer)
    LANGUAGE plpgsql AS $$ BEGIN
    RETURN QUERY SELECT COALESCE(MAX("LineNumber"),0)+1 FROM rest."OrderTicketLine" WHERE "OrderTicketId"=p_order_id;
END; $$;
-- +goose StatementEnd

-- 32-54: Legacy functions revert
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_rest_ambiente_upsert(p_id integer DEFAULT 0, p_nombre character varying DEFAULT ''::character varying, p_color character varying DEFAULT '#4CAF50'::character varying, p_orden integer DEFAULT 0) RETURNS TABLE("ResultId" integer)
    LANGUAGE plpgsql AS $$
DECLARE v_result_id INT;
BEGIN
    IF p_id > 0 AND EXISTS (SELECT 1 FROM "RestauranteAmbientes" WHERE "Id"=p_id) THEN
        UPDATE "RestauranteAmbientes" SET "Nombre"=p_nombre,"Color"=p_color,"Orden"=p_orden WHERE "Id"=p_id; v_result_id:=p_id;
    ELSE INSERT INTO "RestauranteAmbientes" ("Nombre","Color","Orden") VALUES (p_nombre,p_color,p_orden) RETURNING "Id" INTO v_result_id; END IF;
    RETURN QUERY SELECT v_result_id;
END; $$;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_rest_ambientes_list() RETURNS TABLE(id integer, nombre character varying, color character varying, orden integer)
    LANGUAGE plpgsql AS $$
BEGIN RETURN QUERY SELECT "Id","Nombre","Color","Orden" FROM "RestauranteAmbientes" WHERE "Activo"=TRUE ORDER BY "Orden"; END; $$;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_rest_categoria_upsert(p_id integer DEFAULT 0, p_nombre character varying DEFAULT ''::character varying, p_descripcion character varying DEFAULT NULL, p_color character varying DEFAULT NULL, p_orden integer DEFAULT 0) RETURNS TABLE("ResultId" integer)
    LANGUAGE plpgsql AS $$
DECLARE v_result_id INT;
BEGIN
    IF p_id > 0 AND EXISTS (SELECT 1 FROM "RestauranteCategorias" WHERE "Id"=p_id) THEN
        UPDATE "RestauranteCategorias" SET "Nombre"=p_nombre,"Descripcion"=p_descripcion,"Color"=p_color,"Orden"=p_orden WHERE "Id"=p_id; v_result_id:=p_id;
    ELSE INSERT INTO "RestauranteCategorias" ("Nombre","Descripcion","Color","Orden") VALUES (p_nombre,p_descripcion,p_color,p_orden) RETURNING "Id" INTO v_result_id; END IF;
    RETURN QUERY SELECT v_result_id;
END; $$;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_rest_categorias_list() RETURNS TABLE(id integer, nombre character varying, descripcion character varying, color character varying, orden integer, "productCount" bigint)
    LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY SELECT c."Id",c."Nombre",c."Descripcion",c."Color",c."Orden",(SELECT COUNT(1) FROM "RestauranteProductos" p WHERE p."CategoriaId"=c."Id" AND p."Activo"=TRUE) FROM "RestauranteCategorias" c WHERE c."Activa"=TRUE ORDER BY c."Orden";
END; $$;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_rest_comanda_enviar(p_pedido_id integer) RETURNS void
    LANGUAGE plpgsql AS $$
BEGIN
    UPDATE "RestaurantePedidoItems" SET "EnviadoACocina"=TRUE,"HoraEnvio"=NOW() AT TIME ZONE 'UTC',"Estado"='en_preparacion' WHERE "PedidoId"=p_pedido_id AND "EnviadoACocina"=FALSE;
    UPDATE "RestaurantePedidos" SET "Estado"='en_preparacion' WHERE "Id"=p_pedido_id AND "Estado"='abierto';
END; $$;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_rest_componente_upsert(p_id integer DEFAULT 0, p_producto_id integer DEFAULT 0, p_nombre character varying DEFAULT ''::character varying, p_obligatorio boolean DEFAULT false, p_orden integer DEFAULT 0) RETURNS TABLE("ResultId" integer)
    LANGUAGE plpgsql AS $$
DECLARE v_result_id INT;
BEGIN
    IF p_id > 0 AND EXISTS (SELECT 1 FROM "RestauranteProductoComponentes" WHERE "Id"=p_id) THEN
        UPDATE "RestauranteProductoComponentes" SET "Nombre"=p_nombre,"Obligatorio"=p_obligatorio,"Orden"=p_orden WHERE "Id"=p_id; v_result_id:=p_id;
    ELSE INSERT INTO "RestauranteProductoComponentes" ("ProductoId","Nombre","Obligatorio","Orden") VALUES (p_producto_id,p_nombre,p_obligatorio,p_orden) RETURNING "Id" INTO v_result_id; END IF;
    RETURN QUERY SELECT v_result_id;
END; $$;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_rest_compra_crear(p_proveedor_id character varying DEFAULT NULL, p_observaciones character varying DEFAULT NULL, p_cod_usuario character varying DEFAULT NULL, p_detalle_json jsonb DEFAULT '[]'::jsonb) RETURNS TABLE("CompraId" integer)
    LANGUAGE plpgsql AS $$
DECLARE v_compra_id INT; v_num_compra VARCHAR(20); v_seq INT;
BEGIN
    SELECT COALESCE(MAX("Id"),0)+1 INTO v_seq FROM "RestauranteCompras";
    v_num_compra:='RC-'||REPLACE(TO_CHAR(NOW() AT TIME ZONE 'UTC','YYYY-MM'),'-',''::VARCHAR)||'-'||LPAD(v_seq::TEXT,4,'0');
    INSERT INTO "RestauranteCompras" ("NumCompra","ProveedorId","Estado","Observaciones","CodUsuario") VALUES (v_num_compra,p_proveedor_id,'pendiente',p_observaciones,p_cod_usuario) RETURNING "Id" INTO v_compra_id;
    INSERT INTO "RestauranteComprasDetalle" ("CompraId","InventarioId","Descripcion","Cantidad","PrecioUnit","Subtotal","IVA") SELECT v_compra_id,(item->>'invId')::VARCHAR(15),(item->>'desc')::VARCHAR(200),(item->>'cant')::NUMERIC(10,3),(item->>'precio')::NUMERIC(18,2),(item->>'cant')::NUMERIC(10,3)*(item->>'precio')::NUMERIC(18,2),COALESCE((item->>'iva')::NUMERIC(5,2),16) FROM jsonb_array_elements(p_detalle_json) AS item;
    UPDATE "RestauranteCompras" SET "Subtotal"=(SELECT COALESCE(SUM("Subtotal"),0) FROM "RestauranteComprasDetalle" WHERE "CompraId"=v_compra_id),"IVA"=(SELECT COALESCE(SUM("Subtotal"*"IVA"/100),0) FROM "RestauranteComprasDetalle" WHERE "CompraId"=v_compra_id),"Total"=(SELECT COALESCE(SUM("Subtotal"+"Subtotal"*"IVA"/100),0) FROM "RestauranteComprasDetalle" WHERE "CompraId"=v_compra_id) WHERE "Id"=v_compra_id;
    RETURN QUERY SELECT v_compra_id;
EXCEPTION WHEN OTHERS THEN RAISE EXCEPTION '%',SQLERRM;
END; $$;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_rest_compras_list(p_estado character varying DEFAULT NULL, p_from timestamp without time zone DEFAULT NULL, p_to timestamp without time zone DEFAULT NULL) RETURNS TABLE(id integer, "numCompra" character varying, "proveedorId" character varying, "proveedorNombre" character varying, "fechaCompra" timestamp without time zone, "fechaRecepcion" timestamp without time zone, estado character varying, subtotal numeric, iva numeric, total numeric, observaciones character varying)
    LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY SELECT c."Id",c."NumCompra",c."ProveedorId",p."SupplierName",c."FechaCompra",c."FechaRecepcion",c."Estado",c."Subtotal",c."IVA",c."Total",c."Observaciones"
    FROM "RestauranteCompras" c LEFT JOIN master."Supplier" p ON p."SupplierCode"=c."ProveedorId"
    WHERE (COALESCE(p."IsDeleted",FALSE)=FALSE OR p."SupplierCode" IS NULL) AND (p_estado IS NULL OR c."Estado"=p_estado) AND (p_from IS NULL OR c."FechaCompra">=p_from) AND (p_to IS NULL OR c."FechaCompra"<=p_to) ORDER BY c."FechaCompra" DESC;
END; $$;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_rest_mesas_list(p_ambiente_id character varying DEFAULT NULL) RETURNS TABLE(id integer, numero integer, nombre character varying, capacidad integer, "ambienteId" character varying, ambiente character varying, "posicionX" integer, "posicionY" integer, estado character varying)
    LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY SELECT m."Id",m."Numero",m."Nombre",m."Capacidad",m."AmbienteId",m."Ambiente",m."PosicionX",m."PosicionY",m."Estado" FROM "RestauranteMesas" m WHERE m."Activa"=TRUE AND (p_ambiente_id IS NULL OR m."AmbienteId"=p_ambiente_id) ORDER BY m."AmbienteId",m."Numero";
END; $$;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_rest_opcion_upsert(p_id integer DEFAULT 0, p_componente_id integer DEFAULT 0, p_nombre character varying DEFAULT ''::character varying, p_precio_extra numeric DEFAULT 0, p_orden integer DEFAULT 0) RETURNS TABLE("ResultId" integer)
    LANGUAGE plpgsql AS $$
DECLARE v_result_id INT;
BEGIN
    IF p_id > 0 AND EXISTS (SELECT 1 FROM "RestauranteComponenteOpciones" WHERE "Id"=p_id) THEN
        UPDATE "RestauranteComponenteOpciones" SET "Nombre"=p_nombre,"PrecioExtra"=p_precio_extra,"Orden"=p_orden WHERE "Id"=p_id; v_result_id:=p_id;
    ELSE INSERT INTO "RestauranteComponenteOpciones" ("ComponenteId","Nombre","PrecioExtra","Orden") VALUES (p_componente_id,p_nombre,p_precio_extra,p_orden) RETURNING "Id" INTO v_result_id; END IF;
    RETURN QUERY SELECT v_result_id;
END; $$;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_rest_pedido_abrir(p_mesa_id integer, p_cliente_nombre character varying DEFAULT NULL, p_cliente_rif character varying DEFAULT NULL, p_cod_usuario character varying DEFAULT NULL) RETURNS TABLE("PedidoId" integer)
    LANGUAGE plpgsql AS $$
DECLARE v_pedido_id INT;
BEGIN
    INSERT INTO "RestaurantePedidos" ("MesaId","ClienteNombre","ClienteRif","Estado","CodUsuario") VALUES (p_mesa_id,p_cliente_nombre,p_cliente_rif,'abierto',p_cod_usuario) RETURNING "Id" INTO v_pedido_id;
    UPDATE "RestauranteMesas" SET "Estado"='ocupada' WHERE "Id"=p_mesa_id;
    RETURN QUERY SELECT v_pedido_id AS "PedidoId";
EXCEPTION WHEN OTHERS THEN RAISE EXCEPTION '%',SQLERRM;
END; $$;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_rest_pedido_cerrar(p_pedido_id integer) RETURNS void
    LANGUAGE plpgsql AS $$
DECLARE v_mesa_id INT;
BEGIN
    SELECT "MesaId" INTO v_mesa_id FROM "RestaurantePedidos" WHERE "Id"=p_pedido_id;
    UPDATE "RestaurantePedidos" SET "Estado"='cerrado',"FechaCierre"=NOW() AT TIME ZONE 'UTC' WHERE "Id"=p_pedido_id;
    UPDATE "RestauranteMesas" SET "Estado"='libre' WHERE "Id"=v_mesa_id;
EXCEPTION WHEN OTHERS THEN RAISE EXCEPTION '%',SQLERRM;
END; $$;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_rest_pedido_get_by_mesa_header(p_mesa_id integer) RETURNS TABLE(id integer, "mesaId" integer, "clienteNombre" character varying, "clienteRif" character varying, estado character varying, total numeric, comentarios character varying, "fechaApertura" timestamp without time zone)
    LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY SELECT p."Id",p."MesaId",p."ClienteNombre",p."ClienteRif",p."Estado",p."Total",p."Comentarios",p."FechaApertura" FROM "RestaurantePedidos" p WHERE p."MesaId"=p_mesa_id AND p."Estado"<>'cerrado' ORDER BY p."FechaApertura" DESC LIMIT 1;
END; $$;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_rest_pedido_get_by_mesa_items(p_mesa_id integer) RETURNS TABLE(id integer, "pedidoId" integer, "productoId" character varying, nombre character varying, cantidad numeric, "precioUnitario" numeric, subtotal numeric, iva numeric, estado character varying, "esCompuesto" boolean, componentes text, comentarios character varying, "enviadoACocina" boolean, "horaEnvio" timestamp without time zone)
    LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY SELECT i."Id",i."PedidoId",i."ProductoId",i."Nombre",i."Cantidad",i."PrecioUnitario",i."Subtotal",i."IvaPct",i."Estado",i."EsCompuesto",i."Componentes",i."Comentarios",i."EnviadoACocina",i."HoraEnvio"
    FROM "RestaurantePedidoItems" i INNER JOIN "RestaurantePedidos" p ON i."PedidoId"=p."Id" WHERE p."MesaId"=p_mesa_id AND p."Estado"<>'cerrado' ORDER BY i."Id";
END; $$;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_rest_pedido_item_agregar(p_pedido_id integer, p_producto_id character varying, p_nombre character varying, p_cantidad numeric, p_precio_unitario numeric, p_iva numeric DEFAULT NULL, p_es_compuesto boolean DEFAULT false, p_componentes text DEFAULT NULL, p_comentarios character varying DEFAULT NULL) RETURNS TABLE("ItemId" integer)
    LANGUAGE plpgsql AS $$
DECLARE v_subtotal NUMERIC(18,2):=p_cantidad*p_precio_unitario; v_iva_pct NUMERIC(9,4):=p_iva; v_item_id INT;
BEGIN
    IF v_iva_pct IS NULL THEN
        SELECT CASE WHEN COALESCE(inv."PORCENTAJE",0)>1 THEN (inv."PORCENTAJE"/100.0)::NUMERIC(9,4) ELSE COALESCE(inv."PORCENTAJE",0)::NUMERIC(9,4) END INTO v_iva_pct FROM master."Product" inv WHERE COALESCE(inv."IsDeleted",FALSE)=FALSE AND TRIM(inv."ProductCode")=TRIM(p_producto_id) LIMIT 1;
    END IF;
    IF v_iva_pct IS NULL THEN v_iva_pct:=0; END IF;
    INSERT INTO "RestaurantePedidoItems" ("PedidoId","ProductoId","Nombre","Cantidad","PrecioUnitario","Subtotal","IvaPct","EsCompuesto","Componentes","Comentarios") VALUES (p_pedido_id,p_producto_id,p_nombre,p_cantidad,p_precio_unitario,v_subtotal,v_iva_pct,p_es_compuesto,p_componentes,p_comentarios) RETURNING "Id" INTO v_item_id;
    UPDATE "RestaurantePedidos" SET "Total"=(SELECT COALESCE(SUM("Subtotal"),0) FROM "RestaurantePedidoItems" WHERE "PedidoId"=p_pedido_id) WHERE "Id"=p_pedido_id;
    RETURN QUERY SELECT v_item_id AS "ItemId";
END; $$;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_rest_producto_delete(p_id integer) RETURNS void
    LANGUAGE plpgsql AS $$
BEGIN UPDATE "RestauranteProductos" SET "Activo"=FALSE WHERE "Id"=p_id; END; $$;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_rest_producto_get(p_id integer) RETURNS TABLE(id integer, codigo character varying, nombre character varying, descripcion character varying, precio numeric, "categoriaId" integer, categoria character varying, "esCompuesto" boolean, "tiempoPreparacion" integer, imagen character varying, "esSugerenciaDelDia" boolean, disponible boolean, iva numeric, "costoEstimado" numeric, "articuloInventarioId" character varying)
    LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY SELECT p."Id",p."Codigo",p."Nombre",p."Descripcion",p."Precio",p."CategoriaId",c."Nombre",p."EsCompuesto",p."TiempoPreparacion",p."Imagen",p."EsSugerenciaDelDia",p."Disponible",p."IVA",p."CostoEstimado",p."ArticuloInventarioId"
    FROM "RestauranteProductos" p LEFT JOIN "RestauranteCategorias" c ON c."Id"=p."CategoriaId" WHERE p."Id"=p_id;
END; $$;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_rest_producto_get_componentes(p_id integer) RETURNS TABLE(id integer, nombre character varying, obligatorio boolean, orden integer, "opcionId" integer, "opcionNombre" character varying, "precioExtra" numeric, "opcionOrden" integer)
    LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY SELECT comp."Id",comp."Nombre",comp."Obligatorio",comp."Orden",opc."Id",opc."Nombre",opc."PrecioExtra",opc."Orden"
    FROM "RestauranteProductoComponentes" comp LEFT JOIN "RestauranteComponenteOpciones" opc ON opc."ComponenteId"=comp."Id" WHERE comp."ProductoId"=p_id ORDER BY comp."Orden",opc."Orden";
END; $$;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_rest_producto_get_receta(p_id integer) RETURNS TABLE(id integer, "inventarioId" character varying, "inventarioNombre" character varying, cantidad numeric, unidad character varying, comentario character varying)
    LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY SELECT r."Id",r."InventarioId",i."ProductName",r."Cantidad",r."Unidad",r."Comentario" FROM "RestauranteRecetas" r LEFT JOIN master."Product" i ON i."ProductCode"=r."InventarioId" WHERE r."ProductoId"=p_id;
END; $$;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_rest_producto_upsert(p_id integer DEFAULT 0, p_codigo character varying DEFAULT ''::character varying, p_nombre character varying DEFAULT ''::character varying, p_descripcion character varying DEFAULT NULL, p_categoria_id integer DEFAULT NULL, p_precio numeric DEFAULT 0, p_costo_estimado numeric DEFAULT 0, p_iva numeric DEFAULT 16, p_es_compuesto boolean DEFAULT false, p_tiempo_preparacion integer DEFAULT 0, p_imagen character varying DEFAULT NULL, p_es_sugerencia_del_dia boolean DEFAULT false, p_disponible boolean DEFAULT true, p_articulo_inventario_id character varying DEFAULT NULL) RETURNS TABLE("ResultId" integer)
    LANGUAGE plpgsql AS $$
DECLARE v_result_id INT;
BEGIN
    IF p_id > 0 AND EXISTS (SELECT 1 FROM "RestauranteProductos" WHERE "Id"=p_id) THEN
        UPDATE "RestauranteProductos" SET "Codigo"=p_codigo,"Nombre"=p_nombre,"Descripcion"=p_descripcion,"CategoriaId"=p_categoria_id,"Precio"=p_precio,"CostoEstimado"=p_costo_estimado,"IVA"=p_iva,"EsCompuesto"=p_es_compuesto,"TiempoPreparacion"=p_tiempo_preparacion,"Imagen"=p_imagen,"EsSugerenciaDelDia"=p_es_sugerencia_del_dia,"Disponible"=p_disponible,"ArticuloInventarioId"=p_articulo_inventario_id,"FechaModificacion"=NOW() AT TIME ZONE 'UTC' WHERE "Id"=p_id; v_result_id:=p_id;
    ELSE INSERT INTO "RestauranteProductos" ("Codigo","Nombre","Descripcion","CategoriaId","Precio","CostoEstimado","IVA","EsCompuesto","TiempoPreparacion","Imagen","EsSugerenciaDelDia","Disponible","ArticuloInventarioId") VALUES (p_codigo,p_nombre,p_descripcion,p_categoria_id,p_precio,p_costo_estimado,p_iva,p_es_compuesto,p_tiempo_preparacion,p_imagen,p_es_sugerencia_del_dia,p_disponible,p_articulo_inventario_id) RETURNING "Id" INTO v_result_id; END IF;
    RETURN QUERY SELECT v_result_id;
END; $$;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_rest_productos_list(p_categoria_id integer DEFAULT NULL, p_search character varying DEFAULT NULL, p_solo_disponibles boolean DEFAULT true) RETURNS TABLE(id integer, codigo character varying, nombre character varying, descripcion character varying, precio numeric, "categoriaId" integer, categoria character varying, "esCompuesto" boolean, "tiempoPreparacion" integer, imagen character varying, "esSugerenciaDelDia" boolean, disponible boolean, iva numeric, "costoEstimado" numeric)
    LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY SELECT p."Id",p."Codigo",p."Nombre",p."Descripcion",p."Precio",p."CategoriaId",c."Nombre",p."EsCompuesto",p."TiempoPreparacion",p."Imagen",p."EsSugerenciaDelDia",p."Disponible",p."IVA",p."CostoEstimado"
    FROM "RestauranteProductos" p LEFT JOIN "RestauranteCategorias" c ON c."Id"=p."CategoriaId"
    WHERE p."Activo"=TRUE AND (p_solo_disponibles=FALSE OR p."Disponible"=TRUE) AND (p_categoria_id IS NULL OR p."CategoriaId"=p_categoria_id) AND (p_search IS NULL OR p."Nombre" ILIKE '%'||p_search||'%' OR p."Codigo" ILIKE '%'||p_search||'%') ORDER BY c."Orden",p."Nombre";
END; $$;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_rest_receta_upsert(p_id integer DEFAULT 0, p_producto_id integer DEFAULT 0, p_inventario_id character varying DEFAULT ''::character varying, p_cantidad numeric DEFAULT 0, p_unidad character varying DEFAULT NULL, p_comentario character varying DEFAULT NULL) RETURNS TABLE("ResultId" integer)
    LANGUAGE plpgsql AS $$
DECLARE v_result_id INT;
BEGIN
    IF p_id > 0 AND EXISTS (SELECT 1 FROM "RestauranteRecetas" WHERE "Id"=p_id) THEN
        UPDATE "RestauranteRecetas" SET "InventarioId"=p_inventario_id,"Cantidad"=p_cantidad,"Unidad"=p_unidad,"Comentario"=p_comentario WHERE "Id"=p_id; v_result_id:=p_id;
    ELSE INSERT INTO "RestauranteRecetas" ("ProductoId","InventarioId","Cantidad","Unidad","Comentario") VALUES (p_producto_id,p_inventario_id,p_cantidad,p_unidad,p_comentario) RETURNING "Id" INTO v_result_id; END IF;
    RETURN QUERY SELECT v_result_id;
END; $$;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_rest_recipe_getingredients(p_product_code character varying) RETURNS TABLE("InventarioId" character varying, "Cantidad" numeric)
    LANGUAGE plpgsql AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name='RestauranteRecetas') THEN
        RETURN QUERY SELECT r."InventarioId",r."Cantidad" FROM "RestauranteRecetas" r INNER JOIN "RestauranteProductos" p ON p."Id"=r."ProductoId" WHERE p."Codigo"=p_product_code;
    END IF;
END; $$;
-- +goose StatementEnd
