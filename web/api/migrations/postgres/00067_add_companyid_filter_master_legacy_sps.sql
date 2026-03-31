-- +goose Up
-- Migration: Add p_company_id filter to master/legacy functions that query
-- business data in master schema tables (Warehouse, Category, Brand, Seller,
-- Employee, Customer, Supplier) without CompanyId filtering.
--
-- Functions already having p_company_id are skipped:
--   usp_clientes_list, usp_clientes_getbycodigo,
--   usp_proveedores_list, usp_proveedores_getbycodigo,
--   usp_inventario_* (most).
--
-- Pure legacy tables (dbo."Bancos", public."Cuentas", public."Clases",
-- public."Grupos", public."Lineas", public."Compras", public."Cotizacion",
-- public."Pedidos") do NOT have CompanyId column — skipped.

-- ============================================================
-- 1) usp_almacen_list  (master."Warehouse")
-- ============================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_almacen_list(
    p_company_id INTEGER,
    p_search     CHARACTER VARYING DEFAULT NULL::CHARACTER VARYING,
    p_tipo       CHARACTER VARYING DEFAULT NULL::CHARACTER VARYING,
    p_page       INTEGER DEFAULT 1,
    p_limit      INTEGER DEFAULT 50
) RETURNS TABLE(
    "Codigo"        CHARACTER VARYING,
    "Descripcion"   CHARACTER VARYING,
    "Tipo"          CHARACTER VARYING,
    "IsActive"      BOOLEAN,
    "IsDeleted"     BOOLEAN,
    "CompanyId"     INTEGER,
    "WarehouseCode" CHARACTER VARYING,
    "Description"   CHARACTER VARYING,
    "WarehouseType" CHARACTER VARYING,
    "TotalCount"    INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_offset INT;
    v_limit  INT;
    v_search VARCHAR(100);
    v_total  INT;
BEGIN
    v_limit  := COALESCE(NULLIF(p_limit, 0), 50);
    IF v_limit < 1  THEN v_limit := 50;  END IF;
    IF v_limit > 500 THEN v_limit := 500; END IF;

    v_offset := (COALESCE(NULLIF(p_page, 0), 1) - 1) * v_limit;
    IF v_offset < 0 THEN v_offset := 0; END IF;

    v_search := NULL;
    IF p_search IS NOT NULL AND TRIM(p_search) <> '' THEN
        v_search := '%' || p_search || '%';
    END IF;

    SELECT COUNT(1) INTO v_total
    FROM master."Warehouse" w
    WHERE COALESCE(w."IsDeleted", FALSE) = FALSE
      AND w."CompanyId" = p_company_id
      AND (v_search IS NULL OR (w."WarehouseCode" ILIKE v_search OR w."Description" ILIKE v_search))
      AND (p_tipo IS NULL OR TRIM(p_tipo) = '' OR w."WarehouseType" = p_tipo);

    RETURN QUERY
    SELECT
        w."WarehouseCode"  AS "Codigo",
        w."Description"    AS "Descripcion",
        w."WarehouseType"  AS "Tipo",
        w."IsActive",
        w."IsDeleted",
        w."CompanyId",
        w."WarehouseCode",
        w."Description",
        w."WarehouseType",
        v_total            AS "TotalCount"
    FROM master."Warehouse" w
    WHERE COALESCE(w."IsDeleted", FALSE) = FALSE
      AND w."CompanyId" = p_company_id
      AND (v_search IS NULL OR (w."WarehouseCode" ILIKE v_search OR w."Description" ILIKE v_search))
      AND (p_tipo IS NULL OR TRIM(p_tipo) = '' OR w."WarehouseType" = p_tipo)
    ORDER BY w."WarehouseCode"
    LIMIT v_limit OFFSET v_offset;
END;
$$;
-- +goose StatementEnd

-- ============================================================
-- 2) usp_almacen_getbycodigo  (master."Warehouse")
-- ============================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_almacen_getbycodigo(
    p_company_id INTEGER,
    p_codigo     CHARACTER VARYING
) RETURNS TABLE(
    "Codigo"        CHARACTER VARYING,
    "Descripcion"   CHARACTER VARYING,
    "Tipo"          CHARACTER VARYING,
    "IsActive"      BOOLEAN,
    "IsDeleted"     BOOLEAN,
    "CompanyId"     INTEGER,
    "WarehouseCode" CHARACTER VARYING,
    "Description"   CHARACTER VARYING,
    "WarehouseType" CHARACTER VARYING
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        w."WarehouseCode"  AS "Codigo",
        w."Description"    AS "Descripcion",
        w."WarehouseType"  AS "Tipo",
        w."IsActive",
        w."IsDeleted",
        w."CompanyId",
        w."WarehouseCode",
        w."Description",
        w."WarehouseType"
    FROM master."Warehouse" w
    WHERE w."WarehouseCode" = p_codigo
      AND w."CompanyId" = p_company_id
      AND COALESCE(w."IsDeleted", FALSE) = FALSE;
END;
$$;
-- +goose StatementEnd

-- ============================================================
-- 3) usp_almacen_delete  (master."Warehouse")
-- ============================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_almacen_delete(
    p_company_id INTEGER,
    p_codigo     CHARACTER VARYING
) RETURNS TABLE("Resultado" INTEGER, "Mensaje" CHARACTER VARYING)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM master."Warehouse"
        WHERE "WarehouseCode" = p_codigo
          AND "CompanyId" = p_company_id
          AND COALESCE("IsDeleted", FALSE) = FALSE
    ) THEN
        RETURN QUERY SELECT -1, 'Almacen no encontrado'::VARCHAR(500);
        RETURN;
    END IF;

    UPDATE master."Warehouse"
    SET "IsDeleted" = TRUE, "IsActive" = FALSE
    WHERE "WarehouseCode" = p_codigo
      AND "CompanyId" = p_company_id;

    RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
END;
$$;
-- +goose StatementEnd

-- ============================================================
-- 4) usp_almacen_insert  (master."Warehouse")
-- ============================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_almacen_insert(
    p_company_id INTEGER,
    p_row_json   JSONB
) RETURNS TABLE("Resultado" INTEGER, "Mensaje" CHARACTER VARYING)
LANGUAGE plpgsql
AS $$
DECLARE
    v_company_id INT;
    v_codigo     VARCHAR(10);
    v_desc       VARCHAR(100);
    v_tipo       VARCHAR(50);
BEGIN
    v_company_id := COALESCE(p_company_id, 1);

    v_codigo := NULLIF(p_row_json->>'Codigo', ''::VARCHAR);
    v_desc   := NULLIF(p_row_json->>'Descripcion', ''::VARCHAR);
    v_tipo   := NULLIF(p_row_json->>'Tipo', ''::VARCHAR);

    IF EXISTS (
        SELECT 1 FROM master."Warehouse"
        WHERE "WarehouseCode" = v_codigo AND "CompanyId" = v_company_id
    ) THEN
        RETURN QUERY SELECT -1, 'Almacen ya existe'::VARCHAR(500);
        RETURN;
    END IF;

    INSERT INTO master."Warehouse" (
        "WarehouseCode", "Description", "WarehouseType",
        "IsActive", "IsDeleted", "CompanyId"
    )
    VALUES (v_codigo, v_desc, v_tipo, TRUE, FALSE, v_company_id);

    RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
END;
$$;
-- +goose StatementEnd

-- ============================================================
-- 5) usp_almacen_update  (master."Warehouse")
-- ============================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_almacen_update(
    p_company_id INTEGER,
    p_codigo     CHARACTER VARYING,
    p_row_json   JSONB
) RETURNS TABLE("Resultado" INTEGER, "Mensaje" CHARACTER VARYING)
LANGUAGE plpgsql
AS $$
DECLARE
    v_desc VARCHAR(100);
    v_tipo VARCHAR(50);
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM master."Warehouse"
        WHERE "WarehouseCode" = p_codigo
          AND "CompanyId" = p_company_id
          AND COALESCE("IsDeleted", FALSE) = FALSE
    ) THEN
        RETURN QUERY SELECT -1, 'Almacen no encontrado'::VARCHAR(500);
        RETURN;
    END IF;

    v_desc := NULLIF(p_row_json->>'Descripcion', ''::VARCHAR);
    v_tipo := NULLIF(p_row_json->>'Tipo', ''::VARCHAR);

    UPDATE master."Warehouse" SET
        "Description"   = COALESCE(v_desc, "Description"),
        "WarehouseType" = COALESCE(v_tipo, "WarehouseType")
    WHERE "WarehouseCode" = p_codigo
      AND "CompanyId" = p_company_id
      AND COALESCE("IsDeleted", FALSE) = FALSE;

    RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
END;
$$;
-- +goose StatementEnd

-- ============================================================
-- 6) usp_categorias_list  (master."Category")
-- ============================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_categorias_list(
    p_company_id INTEGER,
    p_search     CHARACTER VARYING DEFAULT NULL::CHARACTER VARYING,
    p_page       INTEGER DEFAULT 1,
    p_limit      INTEGER DEFAULT 50
) RETURNS TABLE(
    "Codigo"     INTEGER,
    "Nombre"     CHARACTER VARYING,
    "Co_Usuario" CHARACTER VARYING,
    "TotalCount" BIGINT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_offset INT;
    v_limit  INT;
    v_total  BIGINT;
    v_search VARCHAR(100);
BEGIN
    v_limit  := COALESCE(NULLIF(p_limit, 0), 50);
    IF v_limit < 1 THEN v_limit := 50; END IF;
    IF v_limit > 500 THEN v_limit := 500; END IF;

    v_offset := (COALESCE(NULLIF(p_page, 0), 1) - 1) * v_limit;
    IF v_offset < 0 THEN v_offset := 0; END IF;

    v_search := NULL;
    IF p_search IS NOT NULL AND TRIM(p_search) <> '' THEN
        v_search := '%' || TRIM(p_search) || '%';
    END IF;

    SELECT COUNT(1) INTO v_total
    FROM master."Category" c
    WHERE COALESCE(c."IsDeleted", FALSE) = FALSE
      AND c."CompanyId" = p_company_id
      AND (
        v_search IS NULL
        OR c."CategoryName"::TEXT ILIKE v_search
        OR COALESCE(c."UserCode", ''::VARCHAR)::TEXT ILIKE v_search
        OR COALESCE(c."CategoryCode", ''::VARCHAR)::TEXT ILIKE v_search
      );

    RETURN QUERY
    SELECT
        c."CategoryId"::INT                          AS "Codigo",
        c."CategoryName"::VARCHAR                    AS "Nombre",
        COALESCE(c."UserCode", ''::VARCHAR)::VARCHAR AS "Co_Usuario",
        v_total                                      AS "TotalCount"
    FROM master."Category" c
    WHERE COALESCE(c."IsDeleted", FALSE) = FALSE
      AND c."CompanyId" = p_company_id
      AND (
        v_search IS NULL
        OR c."CategoryName"::TEXT ILIKE v_search
        OR COALESCE(c."UserCode", ''::VARCHAR)::TEXT ILIKE v_search
        OR COALESCE(c."CategoryCode", ''::VARCHAR)::TEXT ILIKE v_search
      )
    ORDER BY c."CategoryId"
    LIMIT v_limit OFFSET v_offset;
END;
$$;
-- +goose StatementEnd

-- ============================================================
-- 7) usp_categorias_getbycodigo  (master."Category")
-- ============================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_categorias_getbycodigo(
    p_company_id INTEGER,
    p_codigo     INTEGER
) RETURNS TABLE(
    "Codigo"     INTEGER,
    "Nombre"     CHARACTER VARYING,
    "Co_Usuario" CHARACTER VARYING
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        c."CategoryId"::INT                          AS "Codigo",
        c."CategoryName"::VARCHAR                    AS "Nombre",
        COALESCE(c."UserCode", ''::VARCHAR)::VARCHAR AS "Co_Usuario"
    FROM master."Category" c
    WHERE c."CategoryId" = p_codigo
      AND c."CompanyId" = p_company_id
      AND COALESCE(c."IsDeleted", FALSE) = FALSE;
END;
$$;
-- +goose StatementEnd

-- ============================================================
-- 8) usp_categorias_delete  (master."Category")
-- ============================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_categorias_delete(
    p_company_id INTEGER,
    p_codigo     INTEGER
) RETURNS TABLE("Resultado" INTEGER, "Mensaje" CHARACTER VARYING)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM master."Category"
        WHERE "CategoryId" = p_codigo
          AND "CompanyId" = p_company_id
          AND COALESCE("IsDeleted", FALSE) = FALSE
    ) THEN
        RETURN QUERY SELECT -1, 'Categoria no encontrada'::VARCHAR(500);
        RETURN;
    END IF;

    UPDATE master."Category"
    SET "IsDeleted" = TRUE, "IsActive" = FALSE
    WHERE "CategoryId" = p_codigo
      AND "CompanyId" = p_company_id;

    RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);
EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
END;
$$;
-- +goose StatementEnd

-- ============================================================
-- 9) usp_categorias_insert  (master."Category")
-- ============================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_categorias_insert(
    p_company_id INTEGER,
    p_row_json   JSONB
) RETURNS TABLE("Resultado" INTEGER, "Mensaje" CHARACTER VARYING, "NuevoCodigo" INTEGER)
LANGUAGE plpgsql
AS $$
DECLARE
    v_nuevo_codigo INT;
    v_company_id   INT;
    v_nombre       VARCHAR(100);
    v_user_code    VARCHAR(60);
BEGIN
    v_company_id := COALESCE(p_company_id, 1);

    v_nombre    := NULLIF(TRIM(COALESCE(p_row_json->>'Nombre', p_row_json->>'CategoryName', ''::VARCHAR)), ''::VARCHAR);
    v_user_code := NULLIF(TRIM(COALESCE(p_row_json->>'Co_Usuario', p_row_json->>'UserCode', ''::VARCHAR)), ''::VARCHAR);

    IF v_nombre IS NULL THEN
        RETURN QUERY SELECT -1, 'Nombre requerido'::VARCHAR(500), 0;
        RETURN;
    END IF;

    IF EXISTS (
        SELECT 1 FROM master."Category"
        WHERE "CompanyId" = v_company_id
          AND COALESCE("IsDeleted", FALSE) = FALSE
          AND UPPER("CategoryName") = UPPER(v_nombre)
    ) THEN
        RETURN QUERY SELECT -1, 'Categoria ya existe'::VARCHAR(500), 0;
        RETURN;
    END IF;

    INSERT INTO master."Category" (
        "CategoryName", "UserCode", "Description",
        "CompanyId", "IsActive", "IsDeleted"
    )
    VALUES (v_nombre, v_user_code, v_nombre, v_company_id, TRUE, FALSE)
    RETURNING "CategoryId" INTO v_nuevo_codigo;

    RETURN QUERY SELECT 1, 'OK'::VARCHAR(500), v_nuevo_codigo;
EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500), 0;
END;
$$;
-- +goose StatementEnd

-- ============================================================
-- 10) usp_categorias_update  (master."Category")
-- ============================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_categorias_update(
    p_company_id INTEGER,
    p_codigo     INTEGER,
    p_row_json   JSONB
) RETURNS TABLE("Resultado" INTEGER, "Mensaje" CHARACTER VARYING)
LANGUAGE plpgsql
AS $$
DECLARE
    v_nombre VARCHAR(100);
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM master."Category"
        WHERE "CategoryId" = p_codigo
          AND "CompanyId" = p_company_id
          AND COALESCE("IsDeleted", FALSE) = FALSE
    ) THEN
        RETURN QUERY SELECT -1, 'Categoria no encontrada'::VARCHAR(500);
        RETURN;
    END IF;

    v_nombre := NULLIF(TRIM(COALESCE(p_row_json->>'Nombre', p_row_json->>'CategoryName', ''::VARCHAR)), ''::VARCHAR);

    IF v_nombre IS NOT NULL AND EXISTS (
        SELECT 1 FROM master."Category"
        WHERE "CategoryId" <> p_codigo
          AND "CompanyId" = p_company_id
          AND COALESCE("IsDeleted", FALSE) = FALSE
          AND UPPER("CategoryName") = UPPER(v_nombre)
    ) THEN
        RETURN QUERY SELECT -1, ('Categoria duplicada: ' || v_nombre)::VARCHAR(500);
        RETURN;
    END IF;

    UPDATE master."Category" SET
        "CategoryName" = COALESCE(v_nombre, "CategoryName"),
        "UserCode"     = COALESCE(
            NULLIF(TRIM(COALESCE(p_row_json->>'Co_Usuario', p_row_json->>'UserCode', ''::VARCHAR)), ''::VARCHAR),
            "UserCode"
        )
    WHERE "CategoryId" = p_codigo
      AND "CompanyId" = p_company_id;

    RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);
EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
END;
$$;
-- +goose StatementEnd

-- ============================================================
-- 11) usp_marcas_list  (master."Brand")
-- ============================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_marcas_list(
    p_company_id INTEGER,
    p_search     CHARACTER VARYING DEFAULT NULL::CHARACTER VARYING,
    p_page       INTEGER DEFAULT 1,
    p_limit      INTEGER DEFAULT 50
) RETURNS TABLE(
    "Codigo"     INTEGER,
    "Descripcion" CHARACTER VARYING,
    "TotalCount" BIGINT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_offset INT;
    v_limit  INT;
    v_total  BIGINT;
    v_search VARCHAR(100);
BEGIN
    v_limit  := COALESCE(NULLIF(p_limit, 0), 50);
    IF v_limit < 1  THEN v_limit := 50;  END IF;
    IF v_limit > 500 THEN v_limit := 500; END IF;

    v_offset := (COALESCE(NULLIF(p_page, 0), 1) - 1) * v_limit;
    IF v_offset < 0 THEN v_offset := 0; END IF;

    v_search := NULL;
    IF p_search IS NOT NULL AND TRIM(p_search) <> '' THEN
        v_search := '%' || p_search || '%';
    END IF;

    SELECT COUNT(1) INTO v_total
    FROM master."Brand" b
    WHERE COALESCE(b."IsDeleted", FALSE) = FALSE
      AND b."CompanyId" = p_company_id
      AND (v_search IS NULL OR b."BrandName"::TEXT ILIKE v_search);

    RETURN QUERY
    SELECT
        b."BrandId"::INT       AS "Codigo",
        b."BrandName"::VARCHAR AS "Descripcion",
        v_total                AS "TotalCount"
    FROM master."Brand" b
    WHERE COALESCE(b."IsDeleted", FALSE) = FALSE
      AND b."CompanyId" = p_company_id
      AND (v_search IS NULL OR b."BrandName"::TEXT ILIKE v_search)
    ORDER BY b."BrandId"
    LIMIT v_limit OFFSET v_offset;
END;
$$;
-- +goose StatementEnd

-- ============================================================
-- 12) usp_marcas_getbycodigo  (master."Brand")
-- ============================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_marcas_getbycodigo(
    p_company_id INTEGER,
    p_codigo     INTEGER
) RETURNS TABLE("Codigo" INTEGER, "Descripcion" CHARACTER VARYING)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT b."BrandId"::INT, b."BrandName"::VARCHAR
    FROM master."Brand" b
    WHERE b."BrandId" = p_codigo
      AND b."CompanyId" = p_company_id
      AND COALESCE(b."IsDeleted", FALSE) = FALSE;
END;
$$;
-- +goose StatementEnd

-- ============================================================
-- 13) usp_marcas_delete  (master."Brand")
-- ============================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_marcas_delete(
    p_company_id INTEGER,
    p_codigo     INTEGER
) RETURNS TABLE("Resultado" INTEGER, "Mensaje" CHARACTER VARYING)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM master."Brand"
        WHERE "BrandId" = p_codigo
          AND "CompanyId" = p_company_id
          AND COALESCE("IsDeleted", FALSE) = FALSE
    ) THEN
        RETURN QUERY SELECT -1, 'Marca no encontrada'::VARCHAR(500);
        RETURN;
    END IF;

    UPDATE master."Brand"
    SET "IsDeleted" = TRUE, "IsActive" = FALSE
    WHERE "BrandId" = p_codigo
      AND "CompanyId" = p_company_id;

    RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);
EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
END;
$$;
-- +goose StatementEnd

-- ============================================================
-- 14) usp_marcas_insert  (master."Brand")
-- ============================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_marcas_insert(
    p_company_id INTEGER,
    p_row_json   JSONB
) RETURNS TABLE("Resultado" INTEGER, "Mensaje" CHARACTER VARYING, "NuevoCodigo" INTEGER)
LANGUAGE plpgsql
AS $$
DECLARE
    v_nuevo_codigo INT;
    v_company_id   INT;
BEGIN
    v_company_id := COALESCE(p_company_id, 1);

    INSERT INTO master."Brand" ("BrandName", "CompanyId", "IsActive", "IsDeleted")
    VALUES (
        NULLIF(COALESCE(p_row_json->>'Descripcion', p_row_json->>'BrandName'), ''::VARCHAR),
        v_company_id, TRUE, FALSE
    )
    RETURNING "BrandId" INTO v_nuevo_codigo;

    RETURN QUERY SELECT 1, 'OK'::VARCHAR(500), v_nuevo_codigo;
EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500), 0;
END;
$$;
-- +goose StatementEnd

-- ============================================================
-- 15) usp_marcas_update  (master."Brand")
-- ============================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_marcas_update(
    p_company_id INTEGER,
    p_codigo     INTEGER,
    p_row_json   JSONB
) RETURNS TABLE("Resultado" INTEGER, "Mensaje" CHARACTER VARYING)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM master."Brand"
        WHERE "BrandId" = p_codigo
          AND "CompanyId" = p_company_id
          AND COALESCE("IsDeleted", FALSE) = FALSE
    ) THEN
        RETURN QUERY SELECT -1, 'Marca no encontrada'::VARCHAR(500);
        RETURN;
    END IF;

    UPDATE master."Brand" SET
        "BrandName" = COALESCE(
            NULLIF(COALESCE(p_row_json->>'Descripcion', p_row_json->>'BrandName'), ''::VARCHAR),
            "BrandName"
        )
    WHERE "BrandId" = p_codigo
      AND "CompanyId" = p_company_id;

    RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);
EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
END;
$$;
-- +goose StatementEnd

-- ============================================================
-- 16) usp_vendedores_list  (master."Seller")
-- ============================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_vendedores_list(
    p_company_id INTEGER,
    p_search     CHARACTER VARYING DEFAULT NULL::CHARACTER VARYING,
    p_status     BOOLEAN DEFAULT NULL::BOOLEAN,
    p_tipo       CHARACTER VARYING DEFAULT NULL::CHARACTER VARYING,
    p_page       INTEGER DEFAULT 1,
    p_limit      INTEGER DEFAULT 50
) RETURNS TABLE(
    "Codigo"               CHARACTER VARYING,
    "Nombre"               CHARACTER VARYING,
    "Comision"             NUMERIC,
    "Status"               BOOLEAN,
    "IsActive"             BOOLEAN,
    "IsDeleted"            BOOLEAN,
    "CompanyId"            INTEGER,
    "SellerCode"           CHARACTER VARYING,
    "SellerName"           CHARACTER VARYING,
    "Commission"           NUMERIC,
    "Direccion"            CHARACTER VARYING,
    "Telefonos"            CHARACTER VARYING,
    "Email"                CHARACTER VARYING,
    "Tipo"                 CHARACTER VARYING,
    "Clave"                CHARACTER VARYING,
    "RangoVentasUno"       NUMERIC,
    "ComisionVentasUno"    NUMERIC,
    "RangoVentasDos"       NUMERIC,
    "ComisionVentasDos"    NUMERIC,
    "RangoVentasTres"      NUMERIC,
    "ComisionVentasTres"   NUMERIC,
    "RangoVentasCuatro"    NUMERIC,
    "ComisionVentasCuatro" NUMERIC,
    "TotalCount"           BIGINT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_offset       INT;
    v_total        BIGINT;
    v_search_param VARCHAR(100);
BEGIN
    v_offset := (COALESCE(NULLIF(p_page, 0), 1) - 1) * COALESCE(NULLIF(p_limit, 0), 50);
    IF v_offset < 0  THEN v_offset := 0;   END IF;
    IF p_limit < 1   THEN p_limit := 50;   END IF;
    IF p_limit > 500 THEN p_limit := 500;  END IF;

    v_search_param := NULL;
    IF p_search IS NOT NULL AND TRIM(p_search) <> '' THEN
        v_search_param := '%' || p_search || '%';
    END IF;

    SELECT COUNT(1) INTO v_total
    FROM master."Seller" s
    WHERE COALESCE(s."IsDeleted", FALSE) = FALSE
      AND s."CompanyId" = p_company_id
      AND (v_search_param IS NULL OR s."SellerCode" LIKE v_search_param OR s."SellerName" LIKE v_search_param OR s."Email" LIKE v_search_param)
      AND (p_status IS NULL OR s."IsActive" = p_status)
      AND (p_tipo IS NULL OR TRIM(p_tipo) = '' OR s."SellerType" = p_tipo);

    RETURN QUERY
    SELECT s."SellerCode"::VARCHAR,
           s."SellerName"::VARCHAR,
           s."Commission",
           s."IsActive",
           s."IsActive",
           s."IsDeleted",
           s."CompanyId",
           s."SellerCode"::VARCHAR,
           s."SellerName"::VARCHAR,
           s."Commission",
           s."Address"::VARCHAR,
           s."Phone"::VARCHAR,
           s."Email"::VARCHAR,
           s."SellerType"::VARCHAR,
           NULL::VARCHAR,
           NULL::NUMERIC,
           NULL::NUMERIC,
           NULL::NUMERIC,
           NULL::NUMERIC,
           NULL::NUMERIC,
           NULL::NUMERIC,
           NULL::NUMERIC,
           NULL::NUMERIC,
           v_total
    FROM master."Seller" s
    WHERE COALESCE(s."IsDeleted", FALSE) = FALSE
      AND s."CompanyId" = p_company_id
      AND (v_search_param IS NULL OR s."SellerCode" LIKE v_search_param OR s."SellerName" LIKE v_search_param OR s."Email" LIKE v_search_param)
      AND (p_status IS NULL OR s."IsActive" = p_status)
      AND (p_tipo IS NULL OR TRIM(p_tipo) = '' OR s."SellerType" = p_tipo)
    ORDER BY s."SellerCode"
    LIMIT p_limit OFFSET v_offset;
END;
$$;
-- +goose StatementEnd

-- ============================================================
-- 17) usp_vendedores_getbycodigo  (master."Seller")
-- ============================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_vendedores_getbycodigo(
    p_company_id INTEGER,
    p_codigo     CHARACTER VARYING
) RETURNS TABLE(
    "Codigo"               CHARACTER VARYING,
    "Nombre"               CHARACTER VARYING,
    "Comision"             DOUBLE PRECISION,
    "Status"               BOOLEAN,
    "IsActive"             BOOLEAN,
    "IsDeleted"            BOOLEAN,
    "CompanyId"            INTEGER,
    "SellerCode"           CHARACTER VARYING,
    "SellerName"           CHARACTER VARYING,
    "Commission"           DOUBLE PRECISION,
    "Direccion"            CHARACTER VARYING,
    "Telefonos"            CHARACTER VARYING,
    "Email"                CHARACTER VARYING,
    "Tipo"                 CHARACTER VARYING,
    "Clave"                CHARACTER VARYING,
    "RangoVentasUno"       DOUBLE PRECISION,
    "ComisionVentasUno"    DOUBLE PRECISION,
    "RangoVentasDos"       DOUBLE PRECISION,
    "ComisionVentasDos"    DOUBLE PRECISION,
    "RangoVentasTres"      DOUBLE PRECISION,
    "ComisionVentasTres"   DOUBLE PRECISION,
    "RangoVentasCuatro"    DOUBLE PRECISION,
    "ComisionVentasCuatro" DOUBLE PRECISION
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        s."SellerCode"  AS "Codigo",
        s."SellerName"  AS "Nombre",
        s."Commission"  AS "Comision",
        s."IsActive"    AS "Status",
        s."IsActive",
        s."IsDeleted",
        s."CompanyId",
        s."SellerCode",
        s."SellerName",
        s."Commission",
        s."Direccion",
        s."Telefonos",
        s."Email",
        s."Tipo",
        s."Clave",
        s."RangoVentasUno",
        s."ComisionVentasUno",
        s."RangoVentasDos",
        s."ComisionVentasDos",
        s."RangoVentasTres",
        s."ComisionVentasTres",
        s."RangoVentasCuatro",
        s."ComisionVentasCuatro"
    FROM master."Seller" s
    WHERE s."SellerCode" = p_codigo
      AND s."CompanyId" = p_company_id
      AND COALESCE(s."IsDeleted", FALSE) = FALSE;
END;
$$;
-- +goose StatementEnd

-- ============================================================
-- 18) usp_vendedores_delete  (master."Seller")
-- ============================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_vendedores_delete(
    p_company_id INTEGER,
    p_codigo     CHARACTER VARYING
) RETURNS TABLE("Resultado" INTEGER, "Mensaje" CHARACTER VARYING)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM master."Seller"
        WHERE "SellerCode" = p_codigo
          AND "CompanyId" = p_company_id
          AND COALESCE("IsDeleted", FALSE) = FALSE
    ) THEN
        RETURN QUERY SELECT -1, 'Vendedor no encontrado'::VARCHAR(500);
        RETURN;
    END IF;

    UPDATE master."Seller"
    SET "IsDeleted" = TRUE, "IsActive" = FALSE
    WHERE "SellerCode" = p_codigo
      AND "CompanyId" = p_company_id;

    RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);
EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
END;
$$;
-- +goose StatementEnd

-- ============================================================
-- 19) usp_vendedores_insert  (master."Seller")
-- ============================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_vendedores_insert(
    p_company_id INTEGER,
    p_row_json   JSONB
) RETURNS TABLE("Resultado" INTEGER, "Mensaje" CHARACTER VARYING)
LANGUAGE plpgsql
AS $$
DECLARE
    v_company_id INT;
    v_codigo     VARCHAR(10);
BEGIN
    v_company_id := COALESCE(p_company_id, 1);
    v_codigo     := NULLIF(p_row_json->>'Codigo', ''::VARCHAR);

    IF EXISTS (
        SELECT 1 FROM master."Seller"
        WHERE "SellerCode" = v_codigo AND "CompanyId" = v_company_id
    ) THEN
        RETURN QUERY SELECT -1, 'Vendedor ya existe'::VARCHAR(500);
        RETURN;
    END IF;

    BEGIN
        INSERT INTO master."Seller" (
            "SellerCode", "SellerName", "Commission",
            "Direccion", "Telefonos", "Email",
            "RangoVentasUno", "ComisionVentasUno",
            "RangoVentasDos", "ComisionVentasDos",
            "RangoVentasTres", "ComisionVentasTres",
            "RangoVentasCuatro", "ComisionVentasCuatro",
            "IsActive", "Tipo", "Clave", "IsDeleted", "CompanyId"
        )
        VALUES (
            v_codigo,
            NULLIF(p_row_json->>'Nombre', ''::VARCHAR),
            CASE WHEN p_row_json->>'Comision' IS NULL OR p_row_json->>'Comision' = '' THEN NULL
                 ELSE (p_row_json->>'Comision')::DOUBLE PRECISION END,
            NULLIF(p_row_json->>'Direccion', ''::VARCHAR),
            NULLIF(p_row_json->>'Telefonos', ''::VARCHAR),
            NULLIF(p_row_json->>'Email', ''::VARCHAR),
            CASE WHEN p_row_json->>'Rango_ventas_Uno' IS NULL OR p_row_json->>'Rango_ventas_Uno' = '' THEN NULL
                 ELSE (p_row_json->>'Rango_ventas_Uno')::DOUBLE PRECISION END,
            CASE WHEN p_row_json->>'Comision_ventas_Uno' IS NULL OR p_row_json->>'Comision_ventas_Uno' = '' THEN NULL
                 ELSE (p_row_json->>'Comision_ventas_Uno')::DOUBLE PRECISION END,
            CASE WHEN p_row_json->>'Rango_ventas_dos' IS NULL OR p_row_json->>'Rango_ventas_dos' = '' THEN NULL
                 ELSE (p_row_json->>'Rango_ventas_dos')::DOUBLE PRECISION END,
            CASE WHEN p_row_json->>'Comision_ventas_dos' IS NULL OR p_row_json->>'Comision_ventas_dos' = '' THEN NULL
                 ELSE (p_row_json->>'Comision_ventas_dos')::DOUBLE PRECISION END,
            CASE WHEN p_row_json->>'Rango_ventas_tres' IS NULL OR p_row_json->>'Rango_ventas_tres' = '' THEN NULL
                 ELSE (p_row_json->>'Rango_ventas_tres')::DOUBLE PRECISION END,
            CASE WHEN p_row_json->>'Comision_ventas_tres' IS NULL OR p_row_json->>'Comision_ventas_tres' = '' THEN NULL
                 ELSE (p_row_json->>'Comision_ventas_tres')::DOUBLE PRECISION END,
            CASE WHEN p_row_json->>'Rango_ventas_Cuatro' IS NULL OR p_row_json->>'Rango_ventas_Cuatro' = '' THEN NULL
                 ELSE (p_row_json->>'Rango_ventas_Cuatro')::DOUBLE PRECISION END,
            CASE WHEN p_row_json->>'Comision_ventas_Cuatro' IS NULL OR p_row_json->>'Comision_ventas_Cuatro' = '' THEN NULL
                 ELSE (p_row_json->>'Comision_ventas_Cuatro')::DOUBLE PRECISION END,
            COALESCE((p_row_json->>'Status')::BOOLEAN, TRUE),
            NULLIF(p_row_json->>'Tipo', ''::VARCHAR),
            NULLIF(p_row_json->>'clave', ''::VARCHAR),
            FALSE,
            v_company_id
        );

        RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
    END;
END;
$$;
-- +goose StatementEnd

-- ============================================================
-- 20) usp_vendedores_update  (master."Seller")
-- ============================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_vendedores_update(
    p_company_id INTEGER,
    p_codigo     CHARACTER VARYING,
    p_row_json   JSONB
) RETURNS TABLE("Resultado" INTEGER, "Mensaje" CHARACTER VARYING)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM master."Seller"
        WHERE "SellerCode" = p_codigo
          AND "CompanyId" = p_company_id
          AND COALESCE("IsDeleted", FALSE) = FALSE
    ) THEN
        RETURN QUERY SELECT -1, 'Vendedor no encontrado'::VARCHAR(500);
        RETURN;
    END IF;

    BEGIN
        UPDATE master."Seller"
        SET
            "SellerName" = COALESCE(NULLIF(p_row_json->>'Nombre', ''::VARCHAR), "SellerName"),
            "Commission" = CASE WHEN p_row_json->>'Comision' IS NULL OR p_row_json->>'Comision' = ''
                                THEN "Commission"
                                ELSE (p_row_json->>'Comision')::DOUBLE PRECISION END,
            "Direccion"  = COALESCE(NULLIF(p_row_json->>'Direccion', ''::VARCHAR), "Direccion"),
            "Telefonos"  = COALESCE(NULLIF(p_row_json->>'Telefonos', ''::VARCHAR), "Telefonos"),
            "Email"      = COALESCE(NULLIF(p_row_json->>'Email', ''::VARCHAR), "Email"),
            "IsActive"   = COALESCE((p_row_json->>'Status')::BOOLEAN, "IsActive"),
            "Tipo"       = COALESCE(NULLIF(p_row_json->>'Tipo', ''::VARCHAR), "Tipo"),
            "Clave"      = COALESCE(NULLIF(p_row_json->>'clave', ''::VARCHAR), "Clave")
        WHERE "SellerCode" = p_codigo
          AND "CompanyId" = p_company_id;

        RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
    END;
END;
$$;
-- +goose StatementEnd

-- ============================================================
-- 21) usp_empleados_list  (master."Employee")
-- ============================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_empleados_list(
    p_company_id INTEGER,
    p_search     CHARACTER VARYING DEFAULT NULL::CHARACTER VARYING,
    p_grupo      CHARACTER VARYING DEFAULT NULL::CHARACTER VARYING,
    p_status     CHARACTER VARYING DEFAULT NULL::CHARACTER VARYING,
    p_page       INTEGER DEFAULT 1,
    p_limit      INTEGER DEFAULT 50
) RETURNS TABLE(
    "CEDULA"       CHARACTER VARYING,
    "GRUPO"        CHARACTER VARYING,
    "NOMBRE"       CHARACTER VARYING,
    "DIRECCION"    CHARACTER VARYING,
    "TELEFONO"     CHARACTER VARYING,
    "NACIMIENTO"   DATE,
    "CARGO"        CHARACTER VARYING,
    "NOMINA"       CHARACTER VARYING,
    "SUELDO"       DOUBLE PRECISION,
    "INGRESO"      DATE,
    "RETIRO"       DATE,
    "STATUS"       CHARACTER VARYING,
    "COMISION"     DOUBLE PRECISION,
    "UTILIDAD"     DOUBLE PRECISION,
    "CO_Usuario"   CHARACTER VARYING,
    "SEXO"         CHARACTER VARYING,
    "NACIONALIDAD" CHARACTER VARYING,
    "Autoriza"     BOOLEAN,
    "Apodo"        CHARACTER VARYING,
    "IsActive"     BOOLEAN,
    "IsDeleted"    BOOLEAN,
    "CompanyId"    INTEGER,
    "EmployeeCode" CHARACTER VARYING,
    "EmployeeName" CHARACTER VARYING,
    "TotalCount"   INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_offset INT;
    v_limit  INT;
    v_search VARCHAR(100);
    v_total  INT;
BEGIN
    v_limit  := COALESCE(NULLIF(p_limit, 0), 50);
    IF v_limit < 1  THEN v_limit := 50;  END IF;
    IF v_limit > 500 THEN v_limit := 500; END IF;

    v_offset := (COALESCE(NULLIF(p_page, 0), 1) - 1) * v_limit;
    IF v_offset < 0 THEN v_offset := 0; END IF;

    v_search := NULL;
    IF p_search IS NOT NULL AND TRIM(p_search) <> '' THEN
        v_search := '%' || p_search || '%';
    END IF;

    SELECT COUNT(1) INTO v_total
    FROM master."Employee" e
    WHERE COALESCE(e."IsDeleted", FALSE) = FALSE
      AND e."CompanyId" = p_company_id
      AND (v_search IS NULL OR (e."EmployeeCode" ILIKE v_search OR e."EmployeeName" ILIKE v_search))
      AND (p_grupo IS NULL OR TRIM(p_grupo) = '' OR COALESCE(e."DepartmentName",'') ILIKE '%' || p_grupo || '%')
      AND (p_status IS NULL OR TRIM(p_status) = '' OR
           CASE WHEN p_status = 'A' THEN e."IsActive" = TRUE
                WHEN p_status = 'I' THEN e."IsActive" = FALSE
                ELSE TRUE END);

    RETURN QUERY
    SELECT
        e."EmployeeCode"::VARCHAR                AS "CEDULA",
        COALESCE(e."DepartmentName",'')::VARCHAR AS "GRUPO",
        e."EmployeeName"::VARCHAR                AS "NOMBRE",
        NULL::VARCHAR                            AS "DIRECCION",
        NULL::VARCHAR                            AS "TELEFONO",
        NULL::DATE                               AS "NACIMIENTO",
        COALESCE(e."PositionName",'')::VARCHAR   AS "CARGO",
        NULL::VARCHAR                            AS "NOMINA",
        COALESCE(e."Salary",0)::DOUBLE PRECISION AS "SUELDO",
        e."HireDate"                             AS "INGRESO",
        e."TerminationDate"                      AS "RETIRO",
        CASE WHEN e."IsActive" THEN 'A' ELSE 'I' END::VARCHAR AS "STATUS",
        NULL::DOUBLE PRECISION                   AS "COMISION",
        NULL::DOUBLE PRECISION                   AS "UTILIDAD",
        NULL::VARCHAR                            AS "CO_Usuario",
        NULL::VARCHAR                            AS "SEXO",
        NULL::VARCHAR                            AS "NACIONALIDAD",
        FALSE                                    AS "Autoriza",
        NULL::VARCHAR                            AS "Apodo",
        e."IsActive",
        e."IsDeleted",
        e."CompanyId",
        e."EmployeeCode"::VARCHAR,
        e."EmployeeName"::VARCHAR,
        v_total                                  AS "TotalCount"
    FROM master."Employee" e
    WHERE COALESCE(e."IsDeleted", FALSE) = FALSE
      AND e."CompanyId" = p_company_id
      AND (v_search IS NULL OR (e."EmployeeCode" ILIKE v_search OR e."EmployeeName" ILIKE v_search))
      AND (p_grupo IS NULL OR TRIM(p_grupo) = '' OR COALESCE(e."DepartmentName",'') ILIKE '%' || p_grupo || '%')
      AND (p_status IS NULL OR TRIM(p_status) = '' OR
           CASE WHEN p_status = 'A' THEN e."IsActive" = TRUE
                WHEN p_status = 'I' THEN e."IsActive" = FALSE
                ELSE TRUE END)
    ORDER BY e."EmployeeCode"
    LIMIT v_limit OFFSET v_offset;
END;
$$;
-- +goose StatementEnd

-- ============================================================
-- 22) usp_empleados_getbycedula  (master."Employee")
-- ============================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_empleados_getbycedula(
    p_company_id INTEGER,
    p_cedula     CHARACTER VARYING
) RETURNS TABLE(
    "CEDULA"       CHARACTER VARYING,
    "GRUPO"        CHARACTER VARYING,
    "NOMBRE"       CHARACTER VARYING,
    "DIRECCION"    CHARACTER VARYING,
    "TELEFONO"     CHARACTER VARYING,
    "NACIMIENTO"   DATE,
    "CARGO"        CHARACTER VARYING,
    "NOMINA"       CHARACTER VARYING,
    "SUELDO"       DOUBLE PRECISION,
    "INGRESO"      DATE,
    "RETIRO"       DATE,
    "STATUS"       CHARACTER VARYING,
    "COMISION"     DOUBLE PRECISION,
    "UTILIDAD"     DOUBLE PRECISION,
    "CO_Usuario"   CHARACTER VARYING,
    "SEXO"         CHARACTER VARYING,
    "NACIONALIDAD" CHARACTER VARYING,
    "Autoriza"     BOOLEAN,
    "Apodo"        CHARACTER VARYING,
    "IsActive"     BOOLEAN,
    "IsDeleted"    BOOLEAN,
    "CompanyId"    INTEGER,
    "EmployeeCode" CHARACTER VARYING,
    "EmployeeName" CHARACTER VARYING
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        e."EmployeeCode"::VARCHAR                AS "CEDULA",
        COALESCE(e."DepartmentName",'')::VARCHAR AS "GRUPO",
        e."EmployeeName"::VARCHAR                AS "NOMBRE",
        NULL::VARCHAR                            AS "DIRECCION",
        NULL::VARCHAR                            AS "TELEFONO",
        NULL::DATE                               AS "NACIMIENTO",
        COALESCE(e."PositionName",'')::VARCHAR   AS "CARGO",
        NULL::VARCHAR                            AS "NOMINA",
        COALESCE(e."Salary",0)::DOUBLE PRECISION AS "SUELDO",
        e."HireDate"                             AS "INGRESO",
        e."TerminationDate"                      AS "RETIRO",
        CASE WHEN e."IsActive" THEN 'A' ELSE 'I' END::VARCHAR AS "STATUS",
        NULL::DOUBLE PRECISION                   AS "COMISION",
        NULL::DOUBLE PRECISION                   AS "UTILIDAD",
        NULL::VARCHAR                            AS "CO_Usuario",
        NULL::VARCHAR                            AS "SEXO",
        NULL::VARCHAR                            AS "NACIONALIDAD",
        FALSE                                    AS "Autoriza",
        NULL::VARCHAR                            AS "Apodo",
        e."IsActive",
        e."IsDeleted",
        e."CompanyId",
        e."EmployeeCode"::VARCHAR,
        e."EmployeeName"::VARCHAR
    FROM master."Employee" e
    WHERE e."EmployeeCode" = p_cedula
      AND e."CompanyId" = p_company_id
      AND COALESCE(e."IsDeleted", FALSE) = FALSE;
END;
$$;
-- +goose StatementEnd

-- ============================================================
-- 23) usp_empleados_delete  (master."Employee")
-- ============================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_empleados_delete(
    p_company_id INTEGER,
    p_cedula     CHARACTER VARYING
) RETURNS TABLE("Resultado" INTEGER, "Mensaje" CHARACTER VARYING)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM master."Employee"
        WHERE "EmployeeCode" = p_cedula
          AND "CompanyId" = p_company_id
          AND COALESCE("IsDeleted", FALSE) = FALSE
    ) THEN
        RETURN QUERY SELECT -1, 'Empleado no encontrado'::VARCHAR(500);
        RETURN;
    END IF;

    UPDATE master."Employee"
    SET "IsDeleted" = TRUE, "IsActive" = FALSE
    WHERE "EmployeeCode" = p_cedula
      AND "CompanyId" = p_company_id;

    RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
END;
$$;
-- +goose StatementEnd

-- ============================================================
-- 24) usp_empleados_insert  (master."Employee")
-- ============================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_empleados_insert(
    p_company_id INTEGER,
    p_row_json   JSONB
) RETURNS TABLE("Resultado" INTEGER, "Mensaje" CHARACTER VARYING)
LANGUAGE plpgsql
AS $$
DECLARE
    v_company_id INT;
    v_cedula     VARCHAR(24);
    v_nombre     VARCHAR(200);
BEGIN
    v_company_id := COALESCE(p_company_id, 1);

    v_cedula := NULLIF(TRIM(COALESCE(p_row_json->>'CEDULA', ''::VARCHAR)),''::VARCHAR);
    v_nombre := NULLIF(TRIM(COALESCE(p_row_json->>'NOMBRE', ''::VARCHAR)),''::VARCHAR);

    IF v_cedula IS NULL THEN
        RETURN QUERY SELECT -1, 'CEDULA requerida'::VARCHAR(500);
        RETURN;
    END IF;

    IF v_nombre IS NULL THEN
        RETURN QUERY SELECT -1, 'NOMBRE requerido'::VARCHAR(500);
        RETURN;
    END IF;

    IF EXISTS (
        SELECT 1 FROM master."Employee"
        WHERE "EmployeeCode" = v_cedula AND "CompanyId" = v_company_id
    ) THEN
        RETURN QUERY SELECT -1, 'Empleado ya existe'::VARCHAR(500);
        RETURN;
    END IF;

    INSERT INTO master."Employee" (
        "EmployeeCode", "EmployeeName", "FiscalId",
        "PositionName", "DepartmentName", "Salary",
        "HireDate", "IsActive", "IsDeleted", "CompanyId"
    )
    VALUES (
        v_cedula,
        v_nombre,
        NULLIF(p_row_json->>'CEDULA', ''::VARCHAR),
        NULLIF(p_row_json->>'CARGO', ''::VARCHAR),
        NULLIF(p_row_json->>'GRUPO', ''::VARCHAR),
        CASE WHEN COALESCE(p_row_json->>'SUELDO','') = '' THEN NULL
             ELSE (p_row_json->>'SUELDO')::NUMERIC END,
        CASE WHEN COALESCE(p_row_json->>'INGRESO','') = '' THEN NULL
             ELSE (p_row_json->>'INGRESO')::DATE END,
        TRUE,
        FALSE,
        v_company_id
    );

    RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
END;
$$;
-- +goose StatementEnd

-- ============================================================
-- 25) usp_empleados_update  (master."Employee")
-- ============================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_empleados_update(
    p_company_id INTEGER,
    p_cedula     CHARACTER VARYING,
    p_row_json   JSONB
) RETURNS TABLE("Resultado" INTEGER, "Mensaje" CHARACTER VARYING)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM master."Employee"
        WHERE "EmployeeCode" = p_cedula
          AND "CompanyId" = p_company_id
          AND COALESCE("IsDeleted", FALSE) = FALSE
    ) THEN
        RETURN QUERY SELECT -1, 'Empleado no encontrado'::VARCHAR(500);
        RETURN;
    END IF;

    UPDATE master."Employee" SET
        "EmployeeName"   = COALESCE(NULLIF(p_row_json->>'NOMBRE', ''::VARCHAR), "EmployeeName"),
        "PositionName"   = COALESCE(NULLIF(p_row_json->>'CARGO', ''::VARCHAR), "PositionName"),
        "DepartmentName" = COALESCE(NULLIF(p_row_json->>'GRUPO', ''::VARCHAR), "DepartmentName"),
        "Salary"         = CASE WHEN COALESCE(p_row_json->>'SUELDO','') = '' THEN "Salary"
                                ELSE (p_row_json->>'SUELDO')::NUMERIC END,
        "IsActive"       = CASE WHEN p_row_json->>'STATUS' = 'A' THEN TRUE
                                WHEN p_row_json->>'STATUS' = 'I' THEN FALSE
                                ELSE "IsActive" END
    WHERE "EmployeeCode" = p_cedula
      AND "CompanyId" = p_company_id;

    RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
END;
$$;
-- +goose StatementEnd

-- ============================================================
-- 26) usp_clientes_delete  (master."Customer")
-- ============================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_clientes_delete(
    p_company_id INTEGER,
    p_codigo     CHARACTER VARYING
) RETURNS TABLE("Resultado" INTEGER, "Mensaje" CHARACTER VARYING)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM master."Customer"
        WHERE "CustomerCode" = p_codigo
          AND "CompanyId" = p_company_id
          AND COALESCE("IsDeleted", FALSE) = FALSE
    ) THEN
        RETURN QUERY SELECT -1, 'Cliente no encontrado'::VARCHAR(500);
        RETURN;
    END IF;

    UPDATE master."Customer"
    SET "IsDeleted" = TRUE, "IsActive" = FALSE
    WHERE "CustomerCode" = p_codigo
      AND "CompanyId" = p_company_id;

    RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
END;
$$;
-- +goose StatementEnd

-- ============================================================
-- 27) usp_clientes_insert  (master."Customer")
-- ============================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_clientes_insert(
    p_company_id INTEGER,
    p_row_json   JSONB
) RETURNS TABLE("Resultado" INTEGER, "Mensaje" CHARACTER VARYING)
LANGUAGE plpgsql
AS $$
DECLARE
    v_company_id INT;
    v_codigo     VARCHAR(24);
BEGIN
    v_company_id := COALESCE(p_company_id, 1);

    v_codigo := NULLIF(TRIM(COALESCE(p_row_json->>'CODIGO', p_row_json->>'CodCliente',''::VARCHAR)),''::VARCHAR);

    IF v_codigo IS NULL THEN
        RETURN QUERY SELECT -1, 'CODIGO requerido'::VARCHAR(500);
        RETURN;
    END IF;

    IF EXISTS (
        SELECT 1 FROM master."Customer"
        WHERE "CustomerCode" = v_codigo AND "CompanyId" = v_company_id
    ) THEN
        RETURN QUERY SELECT -1, 'Cliente ya existe'::VARCHAR(500);
        RETURN;
    END IF;

    INSERT INTO master."Customer" (
        "CustomerCode", "CustomerName", "FiscalId",
        "Email", "Phone", "AddressLine",
        "CreditLimit", "IsActive", "IsDeleted", "CompanyId"
    )
    VALUES (
        v_codigo,
        COALESCE(NULLIF(COALESCE(p_row_json->>'NOMBRE', p_row_json->>'Nombre'),''::VARCHAR), v_codigo),
        NULLIF(p_row_json->>'RIF', ''::VARCHAR),
        NULLIF(COALESCE(p_row_json->>'EMAIL', p_row_json->>'Email'),''::VARCHAR),
        NULLIF(COALESCE(p_row_json->>'TELEFONO', p_row_json->>'Telefono'),''::VARCHAR),
        NULLIF(COALESCE(p_row_json->>'DIRECCION', p_row_json->>'Direccion'),''::VARCHAR),
        CASE WHEN COALESCE(p_row_json->>'LIMITE','') = '' THEN 0
             ELSE (p_row_json->>'LIMITE')::NUMERIC END,
        TRUE,
        FALSE,
        v_company_id
    );

    RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
END;
$$;
-- +goose StatementEnd

-- ============================================================
-- 28) usp_clientes_update  (master."Customer")
-- ============================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_clientes_update(
    p_company_id INTEGER,
    p_codigo     CHARACTER VARYING,
    p_row_json   JSONB
) RETURNS TABLE("Resultado" INTEGER, "Mensaje" CHARACTER VARYING)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM master."Customer"
        WHERE "CustomerCode" = p_codigo
          AND "CompanyId" = p_company_id
          AND COALESCE("IsDeleted", FALSE) = FALSE
    ) THEN
        RETURN QUERY SELECT -1, 'Cliente no encontrado'::VARCHAR(500);
        RETURN;
    END IF;

    UPDATE master."Customer" SET
        "CustomerName" = COALESCE(NULLIF(COALESCE(p_row_json->>'NOMBRE', p_row_json->>'Nombre'),''::VARCHAR), "CustomerName"),
        "FiscalId"     = COALESCE(NULLIF(p_row_json->>'RIF', ''::VARCHAR), "FiscalId"),
        "Email"        = COALESCE(NULLIF(COALESCE(p_row_json->>'EMAIL', p_row_json->>'Email'),''::VARCHAR), "Email"),
        "Phone"        = COALESCE(NULLIF(COALESCE(p_row_json->>'TELEFONO', p_row_json->>'Telefono'),''::VARCHAR), "Phone"),
        "AddressLine"  = COALESCE(NULLIF(COALESCE(p_row_json->>'DIRECCION', p_row_json->>'Direccion'),''::VARCHAR), "AddressLine"),
        "CreditLimit"  = CASE WHEN COALESCE(p_row_json->>'LIMITE','') = '' THEN "CreditLimit"
                              ELSE (p_row_json->>'LIMITE')::NUMERIC END,
        "IsActive"     = CASE WHEN p_row_json->>'Activo' = 'true' OR p_row_json->>'ESTADO' = 'A' THEN TRUE
                              WHEN p_row_json->>'Activo' = 'false' OR p_row_json->>'ESTADO' = 'I' THEN FALSE
                              ELSE "IsActive" END
    WHERE "CustomerCode" = p_codigo
      AND "CompanyId" = p_company_id;

    RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
END;
$$;
-- +goose StatementEnd

-- ============================================================
-- 29) usp_proveedores_delete  (master."Supplier")
-- ============================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_proveedores_delete(
    p_company_id INTEGER,
    p_codigo     CHARACTER VARYING
) RETURNS TABLE("Resultado" INTEGER, "Mensaje" CHARACTER VARYING)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM master."Supplier"
        WHERE "SupplierCode" = p_codigo
          AND "CompanyId" = p_company_id
          AND COALESCE("IsDeleted", FALSE) = FALSE
    ) THEN
        RETURN QUERY SELECT -1, 'Proveedor no encontrado'::VARCHAR(500);
        RETURN;
    END IF;

    UPDATE master."Supplier"
    SET "IsDeleted" = TRUE, "IsActive" = FALSE
    WHERE "SupplierCode" = p_codigo
      AND "CompanyId" = p_company_id;

    RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
END;
$$;
-- +goose StatementEnd

-- ============================================================
-- 30) usp_proveedores_insert  (master."Supplier")
-- ============================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_proveedores_insert(
    p_company_id INTEGER,
    p_row_json   JSONB
) RETURNS TABLE("Resultado" INTEGER, "Mensaje" CHARACTER VARYING)
LANGUAGE plpgsql
AS $$
DECLARE
    v_company_id INT;
    v_codigo     VARCHAR(24);
BEGIN
    v_company_id := COALESCE(p_company_id, 1);

    v_codigo := NULLIF(TRIM(COALESCE(p_row_json->>'CODIGO', ''::VARCHAR)),''::VARCHAR);

    IF v_codigo IS NULL THEN
        RETURN QUERY SELECT -1, 'CODIGO requerido'::VARCHAR(500);
        RETURN;
    END IF;

    IF EXISTS (
        SELECT 1 FROM master."Supplier"
        WHERE "SupplierCode" = v_codigo AND "CompanyId" = v_company_id
    ) THEN
        RETURN QUERY SELECT -1, 'Proveedor ya existe'::VARCHAR(500);
        RETURN;
    END IF;

    INSERT INTO master."Supplier" (
        "SupplierCode", "SupplierName", "FiscalId",
        "Email", "Phone", "AddressLine",
        "CreditLimit", "IsActive", "IsDeleted", "CompanyId"
    )
    VALUES (
        v_codigo,
        COALESCE(NULLIF(p_row_json->>'NOMBRE',''::VARCHAR), v_codigo),
        NULLIF(p_row_json->>'RIF', ''::VARCHAR),
        NULLIF(p_row_json->>'EMAIL', ''::VARCHAR),
        NULLIF(p_row_json->>'TELEFONO', ''::VARCHAR),
        NULLIF(p_row_json->>'DIRECCION', ''::VARCHAR),
        CASE WHEN COALESCE(p_row_json->>'LIMITE',''::VARCHAR) = '' THEN 0
             ELSE (p_row_json->>'LIMITE')::NUMERIC END,
        TRUE,
        FALSE,
        v_company_id
    );

    RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
END;
$$;
-- +goose StatementEnd

-- ============================================================
-- 31) usp_proveedores_update  (master."Supplier")
-- ============================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_proveedores_update(
    p_company_id INTEGER,
    p_codigo     CHARACTER VARYING,
    p_row_json   JSONB
) RETURNS TABLE("Resultado" INTEGER, "Mensaje" CHARACTER VARYING)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM master."Supplier"
        WHERE "SupplierCode" = p_codigo
          AND "CompanyId" = p_company_id
          AND COALESCE("IsDeleted", FALSE) = FALSE
    ) THEN
        RETURN QUERY SELECT -1, 'Proveedor no encontrado'::VARCHAR(500);
        RETURN;
    END IF;

    UPDATE master."Supplier" SET
        "SupplierName" = COALESCE(NULLIF(p_row_json->>'NOMBRE',''::VARCHAR), "SupplierName"),
        "FiscalId"     = COALESCE(NULLIF(p_row_json->>'RIF', ''::VARCHAR), "FiscalId"),
        "Email"        = COALESCE(NULLIF(p_row_json->>'EMAIL', ''::VARCHAR), "Email"),
        "Phone"        = COALESCE(NULLIF(p_row_json->>'TELEFONO', ''::VARCHAR), "Phone"),
        "AddressLine"  = COALESCE(NULLIF(p_row_json->>'DIRECCION', ''::VARCHAR), "AddressLine"),
        "CreditLimit"  = CASE WHEN COALESCE(p_row_json->>'LIMITE','') = '' THEN "CreditLimit"
                              ELSE (p_row_json->>'LIMITE')::NUMERIC END,
        "IsActive"     = CASE WHEN p_row_json->>'ESTADO' = 'A' THEN TRUE
                              WHEN p_row_json->>'ESTADO' = 'I' THEN FALSE
                              ELSE "IsActive" END
    WHERE "SupplierCode" = p_codigo
      AND "CompanyId" = p_company_id;

    RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
END;
$$;
-- +goose StatementEnd


-- +goose Down
-- Revert to original signatures without p_company_id.
-- NOTE: Rolling back requires re-deploying the original functions
-- from baseline/005_functions.sql. The down migration drops the
-- new overloaded signatures so the originals can be restored.

-- Since CREATE OR REPLACE changes the existing function in-place
-- (same name, different args = overload), the down migration must
-- drop the new signatures and recreate the originals.
-- For safety, we only drop the new-signature overloads here.

DROP FUNCTION IF EXISTS public.usp_almacen_list(INTEGER, CHARACTER VARYING, CHARACTER VARYING, INTEGER, INTEGER);
DROP FUNCTION IF EXISTS public.usp_almacen_getbycodigo(INTEGER, CHARACTER VARYING);
DROP FUNCTION IF EXISTS public.usp_almacen_delete(INTEGER, CHARACTER VARYING);
DROP FUNCTION IF EXISTS public.usp_almacen_insert(INTEGER, JSONB);
DROP FUNCTION IF EXISTS public.usp_almacen_update(INTEGER, CHARACTER VARYING, JSONB);

DROP FUNCTION IF EXISTS public.usp_categorias_list(INTEGER, CHARACTER VARYING, INTEGER, INTEGER);
DROP FUNCTION IF EXISTS public.usp_categorias_getbycodigo(INTEGER, INTEGER);
DROP FUNCTION IF EXISTS public.usp_categorias_delete(INTEGER, INTEGER);
DROP FUNCTION IF EXISTS public.usp_categorias_insert(INTEGER, JSONB);
DROP FUNCTION IF EXISTS public.usp_categorias_update(INTEGER, INTEGER, JSONB);

DROP FUNCTION IF EXISTS public.usp_marcas_list(INTEGER, CHARACTER VARYING, INTEGER, INTEGER);
DROP FUNCTION IF EXISTS public.usp_marcas_getbycodigo(INTEGER, INTEGER);
DROP FUNCTION IF EXISTS public.usp_marcas_delete(INTEGER, INTEGER);
DROP FUNCTION IF EXISTS public.usp_marcas_insert(INTEGER, JSONB);
DROP FUNCTION IF EXISTS public.usp_marcas_update(INTEGER, INTEGER, JSONB);

DROP FUNCTION IF EXISTS public.usp_vendedores_list(INTEGER, CHARACTER VARYING, BOOLEAN, CHARACTER VARYING, INTEGER, INTEGER);
DROP FUNCTION IF EXISTS public.usp_vendedores_getbycodigo(INTEGER, CHARACTER VARYING);
DROP FUNCTION IF EXISTS public.usp_vendedores_delete(INTEGER, CHARACTER VARYING);
DROP FUNCTION IF EXISTS public.usp_vendedores_insert(INTEGER, JSONB);
DROP FUNCTION IF EXISTS public.usp_vendedores_update(INTEGER, CHARACTER VARYING, JSONB);

DROP FUNCTION IF EXISTS public.usp_empleados_list(INTEGER, CHARACTER VARYING, CHARACTER VARYING, CHARACTER VARYING, INTEGER, INTEGER);
DROP FUNCTION IF EXISTS public.usp_empleados_getbycedula(INTEGER, CHARACTER VARYING);
DROP FUNCTION IF EXISTS public.usp_empleados_delete(INTEGER, CHARACTER VARYING);
DROP FUNCTION IF EXISTS public.usp_empleados_insert(INTEGER, JSONB);
DROP FUNCTION IF EXISTS public.usp_empleados_update(INTEGER, CHARACTER VARYING, JSONB);

DROP FUNCTION IF EXISTS public.usp_clientes_delete(INTEGER, CHARACTER VARYING);
DROP FUNCTION IF EXISTS public.usp_clientes_insert(INTEGER, JSONB);
DROP FUNCTION IF EXISTS public.usp_clientes_update(INTEGER, CHARACTER VARYING, JSONB);

DROP FUNCTION IF EXISTS public.usp_proveedores_delete(INTEGER, CHARACTER VARYING);
DROP FUNCTION IF EXISTS public.usp_proveedores_insert(INTEGER, JSONB);
DROP FUNCTION IF EXISTS public.usp_proveedores_update(INTEGER, CHARACTER VARYING, JSONB);
