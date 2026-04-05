-- +goose Up
-- Fix inventario functions: rewrite to use canonical column names on master."Product"
-- Old functions referenced legacy columns (Referencia, Categoria, Marca, Tipo, etc.)
-- that no longer exist after clean baseline rebuild.

-- ============================================================================
-- 1) usp_inventario_list  (called by inventario-sp.service.ts → listInventarioSP)
--    API sends: CompanyId, Search, Categoria, Marca, Page, Limit
--    Must return TotalCount + legacy-shaped columns for frontend compat
-- ============================================================================
-- +goose StatementBegin
DROP FUNCTION IF EXISTS public.usp_inventario_list(
    character varying, character varying, character varying,
    character varying, character varying, character varying,
    integer, integer);

CREATE OR REPLACE FUNCTION public.usp_inventario_list(
    p_search    VARCHAR DEFAULT NULL,
    p_categoria VARCHAR DEFAULT NULL,
    p_marca     VARCHAR DEFAULT NULL,
    p_linea     VARCHAR DEFAULT NULL,
    p_tipo      VARCHAR DEFAULT NULL,
    p_clase     VARCHAR DEFAULT NULL,
    p_page      INT     DEFAULT 1,
    p_limit     INT     DEFAULT 50
)
RETURNS TABLE(
    "TotalCount"          BIGINT,
    "ProductId"           BIGINT,
    "ProductCode"         VARCHAR,
    "Referencia"          VARCHAR,
    "Categoria"           VARCHAR,
    "Marca"               VARCHAR,
    "Tipo"                VARCHAR,
    "Unidad"              VARCHAR,
    "Clase"               VARCHAR,
    "ProductName"         VARCHAR,
    "StockQty"            DOUBLE PRECISION,
    "VENTA"               DOUBLE PRECISION,
    "MINIMO"              DOUBLE PRECISION,
    "MAXIMO"              DOUBLE PRECISION,
    "CostPrice"           DOUBLE PRECISION,
    "SalesPrice"          DOUBLE PRECISION,
    "PORCENTAJE"          DOUBLE PRECISION,
    "UBICACION"           VARCHAR,
    "Co_Usuario"          VARCHAR,
    "Linea"               VARCHAR,
    "N_PARTE"             VARCHAR,
    "Barra"               VARCHAR,
    "IsService"           BOOLEAN,
    "IsActive"            BOOLEAN,
    "CompanyId"           INT,
    "CODIGO"              VARCHAR,
    "DESCRIPCION"         VARCHAR,
    "EXISTENCIA"          DOUBLE PRECISION,
    "PRECIO"              DOUBLE PRECISION,
    "COSTO"               DOUBLE PRECISION,
    "Servicio"            BOOLEAN,
    "DescripcionCompleta" TEXT,
    "PRECIO_VENTA1"       DOUBLE PRECISION,
    "PRECIO_VENTA2"       DOUBLE PRECISION,
    "PRECIO_VENTA3"       DOUBLE PRECISION,
    "COSTO_PROMEDIO"      DOUBLE PRECISION,
    "Alicuota"            DOUBLE PRECISION,
    "PLU"                 INT,
    "UbicaFisica"         VARCHAR,
    "Garantia"            VARCHAR,
    "Descripcion"         TEXT
)
LANGUAGE plpgsql AS $fn$
DECLARE
    v_offset  INT;
    v_limit   INT;
    v_total   BIGINT;
    v_search  VARCHAR(200);
BEGIN
    v_limit  := COALESCE(NULLIF(p_limit, 0), 50);
    IF v_limit < 1   THEN v_limit := 50;  END IF;
    IF v_limit > 500  THEN v_limit := 500; END IF;
    v_offset := (COALESCE(NULLIF(p_page, 0), 1) - 1) * v_limit;
    IF v_offset < 0 THEN v_offset := 0; END IF;

    v_search := NULL;
    IF p_search IS NOT NULL AND TRIM(p_search) <> '' THEN
        v_search := '%' || LOWER(p_search) || '%';
    END IF;

    -- Count
    SELECT COUNT(1) INTO v_total
    FROM master."Product" pr
    WHERE COALESCE(pr."IsDeleted", FALSE) = FALSE
      AND (v_search IS NULL
           OR LOWER(pr."ProductCode") LIKE v_search
           OR LOWER(pr."ProductName") LIKE v_search
           OR LOWER(COALESCE(pr."CategoryCode",'')) LIKE v_search
           OR LOWER(COALESCE(pr."BrandCode",'')) LIKE v_search
           OR LOWER(COALESCE(pr."ShortDescription",'')) LIKE v_search
           OR LOWER(COALESCE(pr."BarCode",'')) LIKE v_search)
      AND (p_categoria IS NULL OR TRIM(p_categoria) = '' OR pr."CategoryCode" = p_categoria)
      AND (p_marca     IS NULL OR TRIM(p_marca)     = '' OR pr."BrandCode"    = p_marca)
      AND (p_linea     IS NULL OR TRIM(p_linea)     = '' OR FALSE)
      AND (p_tipo      IS NULL OR TRIM(p_tipo)      = '' OR
           CASE WHEN pr."IsService" THEN 'SERVICIO' ELSE 'PRODUCTO' END = UPPER(p_tipo))
      AND (p_clase     IS NULL OR TRIM(p_clase)     = '' OR FALSE);

    RETURN QUERY
    SELECT
        v_total                                         AS "TotalCount",
        p."ProductId",
        p."ProductCode",
        COALESCE(p."ShortDescription", '')::VARCHAR     AS "Referencia",
        COALESCE(p."CategoryCode", '')::VARCHAR         AS "Categoria",
        COALESCE(p."BrandCode", '')::VARCHAR            AS "Marca",
        (CASE WHEN p."IsService" THEN 'SERVICIO' ELSE 'PRODUCTO' END)::VARCHAR AS "Tipo",
        COALESCE(p."UnitCode", '')::VARCHAR             AS "Unidad",
        ''::VARCHAR                                     AS "Clase",
        p."ProductName",
        COALESCE(p."StockQty", 0)::DOUBLE PRECISION     AS "StockQty",
        COALESCE(p."SalesPrice", 0)::DOUBLE PRECISION   AS "VENTA",
        0::DOUBLE PRECISION                              AS "MINIMO",
        0::DOUBLE PRECISION                              AS "MAXIMO",
        COALESCE(p."CostPrice", 0)::DOUBLE PRECISION    AS "CostPrice",
        COALESCE(p."SalesPrice", 0)::DOUBLE PRECISION   AS "SalesPrice",
        0::DOUBLE PRECISION                              AS "PORCENTAJE",
        ''::VARCHAR                                      AS "UBICACION",
        ''::VARCHAR                                      AS "Co_Usuario",
        ''::VARCHAR                                      AS "Linea",
        ''::VARCHAR                                      AS "N_PARTE",
        COALESCE(p."BarCode", '')::VARCHAR               AS "Barra",
        p."IsService",
        p."IsActive",
        p."CompanyId",
        p."ProductCode"                                  AS "CODIGO",
        p."ProductName"                                  AS "DESCRIPCION",
        COALESCE(p."StockQty", 0)::DOUBLE PRECISION      AS "EXISTENCIA",
        COALESCE(p."SalesPrice", 0)::DOUBLE PRECISION    AS "PRECIO",
        COALESCE(p."CostPrice", 0)::DOUBLE PRECISION     AS "COSTO",
        p."IsService"                                     AS "Servicio",
        TRIM(BOTH FROM
            COALESCE(p."CategoryCode",'') ||
            CASE WHEN COALESCE(p."ProductName",'') <> '' THEN ' ' || p."ProductName" ELSE '' END ||
            CASE WHEN COALESCE(p."BrandCode",'') <> '' THEN ' ' || p."BrandCode" ELSE '' END
        )                                                 AS "DescripcionCompleta",
        COALESCE(p."SalesPrice", 0)::DOUBLE PRECISION     AS "PRECIO_VENTA1",
        COALESCE(p."CompareAtPrice", 0)::DOUBLE PRECISION AS "PRECIO_VENTA2",
        0::DOUBLE PRECISION                                AS "PRECIO_VENTA3",
        COALESCE(p."CostPrice", 0)::DOUBLE PRECISION      AS "COSTO_PROMEDIO",
        COALESCE(p."DefaultTaxRate", 0)::DOUBLE PRECISION  AS "Alicuota",
        0                                                  AS "PLU",
        ''::VARCHAR                                        AS "UbicaFisica",
        COALESCE(p."WarrantyMonths"::TEXT, '')::VARCHAR     AS "Garantia",
        COALESCE(p."LongDescription", '')::TEXT             AS "Descripcion"
    FROM master."Product" p
    WHERE COALESCE(p."IsDeleted", FALSE) = FALSE
      AND (v_search IS NULL
           OR LOWER(p."ProductCode") LIKE v_search
           OR LOWER(p."ProductName") LIKE v_search
           OR LOWER(COALESCE(p."CategoryCode",'')) LIKE v_search
           OR LOWER(COALESCE(p."BrandCode",'')) LIKE v_search
           OR LOWER(COALESCE(p."ShortDescription",'')) LIKE v_search
           OR LOWER(COALESCE(p."BarCode",'')) LIKE v_search)
      AND (p_categoria IS NULL OR TRIM(p_categoria) = '' OR p."CategoryCode" = p_categoria)
      AND (p_marca     IS NULL OR TRIM(p_marca)     = '' OR p."BrandCode"    = p_marca)
      AND (p_linea     IS NULL OR TRIM(p_linea)     = '' OR FALSE)
      AND (p_tipo      IS NULL OR TRIM(p_tipo)      = '' OR
           CASE WHEN p."IsService" THEN 'SERVICIO' ELSE 'PRODUCTO' END = UPPER(p_tipo))
      AND (p_clase     IS NULL OR TRIM(p_clase)     = '' OR FALSE)
    ORDER BY p."ProductCode"
    LIMIT v_limit OFFSET v_offset;
END;
$fn$;
-- +goose StatementEnd

-- ============================================================================
-- 2) usp_inventario_getbycodigo  (called by inventario-sp.service.ts → old route)
--    API sends: Codigo (no CompanyId in this signature)
-- ============================================================================
-- +goose StatementBegin
DROP FUNCTION IF EXISTS public.usp_inventario_getbycodigo(character varying);

CREATE OR REPLACE FUNCTION public.usp_inventario_getbycodigo(
    p_codigo VARCHAR
)
RETURNS TABLE(
    "ProductId"           BIGINT,
    "ProductCode"         VARCHAR,
    "Referencia"          VARCHAR,
    "Categoria"           VARCHAR,
    "Marca"               VARCHAR,
    "Tipo"                VARCHAR,
    "Unidad"              VARCHAR,
    "Clase"               VARCHAR,
    "ProductName"         VARCHAR,
    "StockQty"            DOUBLE PRECISION,
    "VENTA"               DOUBLE PRECISION,
    "MINIMO"              DOUBLE PRECISION,
    "MAXIMO"              DOUBLE PRECISION,
    "CostPrice"           DOUBLE PRECISION,
    "SalesPrice"          DOUBLE PRECISION,
    "PORCENTAJE"          DOUBLE PRECISION,
    "UBICACION"           VARCHAR,
    "Co_Usuario"          VARCHAR,
    "Linea"               VARCHAR,
    "N_PARTE"             VARCHAR,
    "Barra"               VARCHAR,
    "IsService"           BOOLEAN,
    "IsActive"            BOOLEAN,
    "CompanyId"           INT,
    "CODIGO"              VARCHAR,
    "DESCRIPCION"         VARCHAR,
    "EXISTENCIA"          DOUBLE PRECISION,
    "PRECIO"              DOUBLE PRECISION,
    "COSTO"               DOUBLE PRECISION,
    "Servicio"            BOOLEAN,
    "DescripcionCompleta" TEXT,
    "PRECIO_VENTA1"       DOUBLE PRECISION,
    "PRECIO_VENTA2"       DOUBLE PRECISION,
    "PRECIO_VENTA3"       DOUBLE PRECISION,
    "COSTO_PROMEDIO"      DOUBLE PRECISION,
    "Alicuota"            DOUBLE PRECISION,
    "PLU"                 INT,
    "UbicaFisica"         VARCHAR,
    "Garantia"            VARCHAR,
    "Descripcion"         TEXT
)
LANGUAGE plpgsql AS $fn$
BEGIN
    RETURN QUERY
    SELECT
        p."ProductId",
        p."ProductCode",
        COALESCE(p."ShortDescription", '')::VARCHAR     AS "Referencia",
        COALESCE(p."CategoryCode", '')::VARCHAR         AS "Categoria",
        COALESCE(p."BrandCode", '')::VARCHAR            AS "Marca",
        (CASE WHEN p."IsService" THEN 'SERVICIO' ELSE 'PRODUCTO' END)::VARCHAR AS "Tipo",
        COALESCE(p."UnitCode", '')::VARCHAR             AS "Unidad",
        ''::VARCHAR                                     AS "Clase",
        p."ProductName",
        COALESCE(p."StockQty", 0)::DOUBLE PRECISION     AS "StockQty",
        COALESCE(p."SalesPrice", 0)::DOUBLE PRECISION   AS "VENTA",
        0::DOUBLE PRECISION                              AS "MINIMO",
        0::DOUBLE PRECISION                              AS "MAXIMO",
        COALESCE(p."CostPrice", 0)::DOUBLE PRECISION    AS "CostPrice",
        COALESCE(p."SalesPrice", 0)::DOUBLE PRECISION   AS "SalesPrice",
        0::DOUBLE PRECISION                              AS "PORCENTAJE",
        ''::VARCHAR                                      AS "UBICACION",
        ''::VARCHAR                                      AS "Co_Usuario",
        ''::VARCHAR                                      AS "Linea",
        ''::VARCHAR                                      AS "N_PARTE",
        COALESCE(p."BarCode", '')::VARCHAR               AS "Barra",
        p."IsService",
        p."IsActive",
        p."CompanyId",
        p."ProductCode"                                  AS "CODIGO",
        p."ProductName"                                  AS "DESCRIPCION",
        COALESCE(p."StockQty", 0)::DOUBLE PRECISION      AS "EXISTENCIA",
        COALESCE(p."SalesPrice", 0)::DOUBLE PRECISION    AS "PRECIO",
        COALESCE(p."CostPrice", 0)::DOUBLE PRECISION     AS "COSTO",
        p."IsService"                                     AS "Servicio",
        TRIM(BOTH FROM
            COALESCE(p."CategoryCode",'') ||
            CASE WHEN COALESCE(p."ProductName",'') <> '' THEN ' ' || p."ProductName" ELSE '' END ||
            CASE WHEN COALESCE(p."BrandCode",'') <> '' THEN ' ' || p."BrandCode" ELSE '' END
        )                                                 AS "DescripcionCompleta",
        COALESCE(p."SalesPrice", 0)::DOUBLE PRECISION     AS "PRECIO_VENTA1",
        COALESCE(p."CompareAtPrice", 0)::DOUBLE PRECISION AS "PRECIO_VENTA2",
        0::DOUBLE PRECISION                                AS "PRECIO_VENTA3",
        COALESCE(p."CostPrice", 0)::DOUBLE PRECISION      AS "COSTO_PROMEDIO",
        COALESCE(p."DefaultTaxRate", 0)::DOUBLE PRECISION  AS "Alicuota",
        0                                                  AS "PLU",
        ''::VARCHAR                                        AS "UbicaFisica",
        COALESCE(p."WarrantyMonths"::TEXT, '')::VARCHAR     AS "Garantia",
        COALESCE(p."LongDescription", '')::TEXT             AS "Descripcion"
    FROM master."Product" p
    WHERE p."ProductCode" = p_codigo
      AND COALESCE(p."IsDeleted", FALSE) = FALSE;
END;
$fn$;
-- +goose StatementEnd

-- ============================================================================
-- 3) usp_inventario_insert  (called by inventario-sp.service.ts)
--    API sends: CompanyId, RowXml (but PG version uses p_row_json JSONB)
--    Maps legacy JSON keys → canonical columns
-- ============================================================================
-- +goose StatementBegin
DROP FUNCTION IF EXISTS public.usp_inventario_insert(integer, jsonb);

CREATE OR REPLACE FUNCTION public.usp_inventario_insert(
    p_company_id INT     DEFAULT NULL,
    p_row_json   JSONB   DEFAULT '{}'::JSONB
)
RETURNS TABLE("Resultado" INT, "Mensaje" VARCHAR)
LANGUAGE plpgsql AS $fn$
DECLARE
    v_company_id INT;
    v_codigo     VARCHAR(50);
BEGIN
    v_company_id := p_company_id;
    IF v_company_id IS NULL THEN
        SELECT "CompanyId" INTO v_company_id
        FROM cfg."Company"
        WHERE COALESCE("IsDeleted", FALSE) = FALSE
        ORDER BY "CompanyId" LIMIT 1;
    END IF;
    IF v_company_id IS NULL THEN v_company_id := 1; END IF;

    v_codigo := NULLIF(TRIM(p_row_json->>'CODIGO'), '');
    IF v_codigo IS NULL THEN
        v_codigo := NULLIF(TRIM(p_row_json->>'ProductCode'), '');
    END IF;

    IF v_codigo IS NULL OR v_codigo = '' THEN
        RETURN QUERY SELECT -1, 'Codigo requerido'::VARCHAR;
        RETURN;
    END IF;

    -- Check duplicate
    IF EXISTS (
        SELECT 1 FROM master."Product"
        WHERE "ProductCode" = v_codigo AND "CompanyId" = v_company_id
    ) THEN
        RETURN QUERY SELECT -1, 'Articulo ya existe'::VARCHAR;
        RETURN;
    END IF;

    BEGIN
        INSERT INTO master."Product" (
            "ProductCode", "ProductName", "ShortDescription",
            "CategoryCode", "BrandCode", "UnitCode", "BarCode",
            "StockQty", "CostPrice", "SalesPrice", "CompareAtPrice",
            "DefaultTaxRate", "LongDescription", "WarrantyMonths",
            "IsService", "IsActive", "IsDeleted", "CompanyId",
            "CreatedAt", "UpdatedAt"
        ) VALUES (
            v_codigo,
            NULLIF(COALESCE(p_row_json->>'DESCRIPCION', p_row_json->>'ProductName'), ''),
            NULLIF(p_row_json->>'Referencia', ''),
            NULLIF(COALESCE(p_row_json->>'Categoria', p_row_json->>'CategoryCode'), ''),
            NULLIF(COALESCE(p_row_json->>'Marca', p_row_json->>'BrandCode'), ''),
            NULLIF(COALESCE(p_row_json->>'Unidad', p_row_json->>'UnitCode'), ''),
            NULLIF(COALESCE(p_row_json->>'Barra', p_row_json->>'BarCode'), ''),
            CASE WHEN NULLIF(p_row_json->>'EXISTENCIA','') IS NOT NULL
                 THEN (p_row_json->>'EXISTENCIA')::NUMERIC ELSE 0 END,
            CASE WHEN NULLIF(p_row_json->>'PRECIO_COMPRA','') IS NOT NULL
                 THEN (p_row_json->>'PRECIO_COMPRA')::NUMERIC
                 WHEN NULLIF(p_row_json->>'CostPrice','') IS NOT NULL
                 THEN (p_row_json->>'CostPrice')::NUMERIC ELSE 0 END,
            CASE WHEN NULLIF(p_row_json->>'PRECIO_VENTA','') IS NOT NULL
                 THEN (p_row_json->>'PRECIO_VENTA')::NUMERIC
                 WHEN NULLIF(p_row_json->>'SalesPrice','') IS NOT NULL
                 THEN (p_row_json->>'SalesPrice')::NUMERIC ELSE 0 END,
            CASE WHEN NULLIF(p_row_json->>'PRECIO_VENTA2','') IS NOT NULL
                 THEN (p_row_json->>'PRECIO_VENTA2')::NUMERIC ELSE 0 END,
            CASE WHEN NULLIF(p_row_json->>'Alicuota','') IS NOT NULL
                 THEN (p_row_json->>'Alicuota')::NUMERIC
                 WHEN NULLIF(p_row_json->>'DefaultTaxRate','') IS NOT NULL
                 THEN (p_row_json->>'DefaultTaxRate')::NUMERIC ELSE 0 END,
            NULLIF(COALESCE(p_row_json->>'Descripcion', p_row_json->>'LongDescription'), ''),
            CASE WHEN NULLIF(p_row_json->>'Garantia','') IS NOT NULL
                 THEN NULLIF(REGEXP_REPLACE(p_row_json->>'Garantia', '[^0-9]', '', 'g'), '')::INT
                 ELSE NULL END,
            COALESCE((NULLIF(p_row_json->>'Servicio', ''))::BOOLEAN,
                     (NULLIF(p_row_json->>'IsService', ''))::BOOLEAN, FALSE),
            TRUE,
            FALSE,
            v_company_id,
            NOW() AT TIME ZONE 'UTC',
            NOW() AT TIME ZONE 'UTC'
        );

        RETURN QUERY SELECT 1, 'OK'::VARCHAR;
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT -99, SQLERRM::VARCHAR;
    END;
END;
$fn$;
-- +goose StatementEnd

-- ============================================================================
-- 4) usp_inventario_update  (called by inventario-sp.service.ts)
--    API sends: CompanyId, Codigo, RowXml (PG: p_row_json)
-- ============================================================================
-- +goose StatementBegin
DROP FUNCTION IF EXISTS public.usp_inventario_update(integer, character varying, jsonb);

CREATE OR REPLACE FUNCTION public.usp_inventario_update(
    p_company_id INT     DEFAULT NULL,
    p_codigo     VARCHAR DEFAULT NULL,
    p_row_json   JSONB   DEFAULT '{}'::JSONB
)
RETURNS TABLE("Resultado" INT, "Mensaje" VARCHAR)
LANGUAGE plpgsql AS $fn$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM master."Product"
        WHERE "ProductCode" = p_codigo AND COALESCE("IsDeleted", FALSE) = FALSE
    ) THEN
        RETURN QUERY SELECT -1, 'Articulo no encontrado'::VARCHAR;
        RETURN;
    END IF;

    BEGIN
        UPDATE master."Product" SET
            "ProductName"      = COALESCE(NULLIF(COALESCE(p_row_json->>'DESCRIPCION', p_row_json->>'ProductName'), ''), "ProductName"),
            "ShortDescription" = COALESCE(NULLIF(p_row_json->>'Referencia', ''), "ShortDescription"),
            "CategoryCode"     = COALESCE(NULLIF(COALESCE(p_row_json->>'Categoria', p_row_json->>'CategoryCode'), ''), "CategoryCode"),
            "BrandCode"        = COALESCE(NULLIF(COALESCE(p_row_json->>'Marca', p_row_json->>'BrandCode'), ''), "BrandCode"),
            "UnitCode"         = COALESCE(NULLIF(COALESCE(p_row_json->>'Unidad', p_row_json->>'UnitCode'), ''), "UnitCode"),
            "BarCode"          = COALESCE(NULLIF(COALESCE(p_row_json->>'Barra', p_row_json->>'BarCode'), ''), "BarCode"),
            "StockQty"         = CASE WHEN NULLIF(p_row_json->>'EXISTENCIA','') IS NOT NULL
                                      THEN (p_row_json->>'EXISTENCIA')::NUMERIC ELSE "StockQty" END,
            "CostPrice"        = CASE WHEN NULLIF(p_row_json->>'PRECIO_COMPRA','') IS NOT NULL
                                      THEN (p_row_json->>'PRECIO_COMPRA')::NUMERIC
                                      WHEN NULLIF(p_row_json->>'CostPrice','') IS NOT NULL
                                      THEN (p_row_json->>'CostPrice')::NUMERIC ELSE "CostPrice" END,
            "SalesPrice"       = CASE WHEN NULLIF(p_row_json->>'PRECIO_VENTA','') IS NOT NULL
                                      THEN (p_row_json->>'PRECIO_VENTA')::NUMERIC
                                      WHEN NULLIF(p_row_json->>'SalesPrice','') IS NOT NULL
                                      THEN (p_row_json->>'SalesPrice')::NUMERIC ELSE "SalesPrice" END,
            "DefaultTaxRate"   = CASE WHEN NULLIF(p_row_json->>'Alicuota','') IS NOT NULL
                                      THEN (p_row_json->>'Alicuota')::NUMERIC
                                      WHEN NULLIF(p_row_json->>'DefaultTaxRate','') IS NOT NULL
                                      THEN (p_row_json->>'DefaultTaxRate')::NUMERIC ELSE "DefaultTaxRate" END,
            "LongDescription"  = COALESCE(NULLIF(COALESCE(p_row_json->>'Descripcion', p_row_json->>'LongDescription'), ''), "LongDescription"),
            "IsService"        = COALESCE((NULLIF(p_row_json->>'Servicio', ''))::BOOLEAN,
                                          (NULLIF(p_row_json->>'IsService', ''))::BOOLEAN, "IsService"),
            "UpdatedAt"        = NOW() AT TIME ZONE 'UTC'
        WHERE "ProductCode" = p_codigo AND COALESCE("IsDeleted", FALSE) = FALSE;

        RETURN QUERY SELECT 1, 'OK'::VARCHAR;
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT -99, SQLERRM::VARCHAR;
    END;
END;
$fn$;
-- +goose StatementEnd

-- ============================================================================
-- 5) usp_inventario_dashboard  (already uses canonical columns — re-create
--    to fix potential "CategoryCode" vs "Categoria" issue depending on version)
-- ============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_inventario_dashboard(
    p_company_id INT DEFAULT 1
)
RETURNS TABLE(
    "TotalArticulos"  BIGINT,
    "BajoStock"       BIGINT,
    "TotalCategorias" BIGINT,
    "ValorInventario" NUMERIC,
    "MovimientosMes"  BIGINT
)
LANGUAGE plpgsql AS $fn$
BEGIN
    RETURN QUERY
    SELECT
        (SELECT COUNT(1) FROM master."Product"
         WHERE "CompanyId" = p_company_id AND COALESCE("IsDeleted", FALSE) = FALSE
        ),
        (SELECT COUNT(1) FROM master."Product"
         WHERE "CompanyId" = p_company_id AND COALESCE("IsDeleted", FALSE) = FALSE
           AND COALESCE("StockQty", 0) <= 0
        ),
        (SELECT COUNT(DISTINCT "CategoryCode") FROM master."Product"
         WHERE "CompanyId" = p_company_id AND COALESCE("IsDeleted", FALSE) = FALSE
           AND "CategoryCode" IS NOT NULL AND "CategoryCode" <> ''
        ),
        (SELECT COALESCE(SUM(COALESCE("StockQty", 0) * COALESCE("CostPrice", 0)), 0)
         FROM master."Product"
         WHERE "CompanyId" = p_company_id AND COALESCE("IsDeleted", FALSE) = FALSE
        ),
        (SELECT COUNT(1) FROM master."InventoryMovement"
         WHERE "CompanyId" = p_company_id AND COALESCE("IsDeleted", FALSE) = FALSE
           AND "MovementDate" >= DATE_TRUNC('month', (NOW() AT TIME ZONE 'UTC')::DATE)
        );
END;
$fn$;
-- +goose StatementEnd

-- ============================================================================
-- 6) usp_inventario_movimiento_insert  (re-create to ensure canonical columns)
-- ============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_inventario_movimiento_insert(
    p_company_id    INT     DEFAULT 1,
    p_product_code  VARCHAR DEFAULT NULL,
    p_movement_type VARCHAR DEFAULT 'ENTRADA',
    p_quantity      NUMERIC DEFAULT 0,
    p_unit_cost     NUMERIC DEFAULT 0,
    p_document_ref  VARCHAR DEFAULT NULL,
    p_warehouse_from VARCHAR DEFAULT NULL,
    p_warehouse_to   VARCHAR DEFAULT NULL,
    p_notes         VARCHAR DEFAULT NULL,
    p_user_id       INT     DEFAULT NULL
)
RETURNS TABLE("Resultado" INT, "Mensaje" VARCHAR)
LANGUAGE plpgsql AS $fn$
DECLARE
    v_product_name VARCHAR(250);
BEGIN
    IF p_product_code IS NULL OR TRIM(p_product_code) = '' THEN
        RETURN QUERY SELECT -1, 'ProductCode requerido'::VARCHAR;
        RETURN;
    END IF;

    SELECT "ProductName" INTO v_product_name
    FROM master."Product"
    WHERE "ProductCode" = p_product_code AND "CompanyId" = p_company_id
    LIMIT 1;

    INSERT INTO master."InventoryMovement" (
        "CompanyId", "ProductCode", "ProductName",
        "MovementType", "Quantity", "UnitCost", "TotalCost",
        "DocumentRef", "Notes", "CreatedByUserId",
        "CreatedAt", "UpdatedAt"
    )
    VALUES (
        p_company_id,
        p_product_code,
        COALESCE(v_product_name, p_product_code),
        COALESCE(NULLIF(p_movement_type,''), 'ENTRADA'),
        COALESCE(p_quantity, 0),
        COALESCE(p_unit_cost, 0),
        COALESCE(p_quantity, 0) * COALESCE(p_unit_cost, 0),
        NULLIF(p_document_ref,''),
        NULLIF(p_notes,''),
        p_user_id,
        NOW() AT TIME ZONE 'UTC',
        NOW() AT TIME ZONE 'UTC'
    );

    -- Update stock qty
    IF p_movement_type IN ('ENTRADA', 'AJUSTE_POSITIVO') THEN
        UPDATE master."Product" SET "StockQty" = COALESCE("StockQty",0) + p_quantity,
               "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
        WHERE "ProductCode" = p_product_code AND "CompanyId" = p_company_id;
    ELSIF p_movement_type IN ('SALIDA', 'AJUSTE_NEGATIVO') THEN
        UPDATE master."Product" SET "StockQty" = GREATEST(COALESCE("StockQty",0) - p_quantity, 0),
               "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
        WHERE "ProductCode" = p_product_code AND "CompanyId" = p_company_id;
    END IF;

    RETURN QUERY SELECT 1, 'OK'::VARCHAR;

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, SQLERRM::VARCHAR;
END;
$fn$;
-- +goose StatementEnd

-- ============================================================================
-- 7) usp_inventario_movimiento_list  (re-create to ensure canonical columns)
-- ============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_inventario_movimiento_list(
    p_company_id    INT     DEFAULT 1,
    p_search        VARCHAR DEFAULT NULL,
    p_product_code  VARCHAR DEFAULT NULL,
    p_movement_type VARCHAR DEFAULT NULL,
    p_warehouse_code VARCHAR DEFAULT NULL,
    p_fecha_desde   DATE    DEFAULT NULL,
    p_fecha_hasta   DATE    DEFAULT NULL,
    p_page          INT     DEFAULT 1,
    p_limit         INT     DEFAULT 50
)
RETURNS TABLE(
    "TotalCount"      BIGINT,
    "MovementId"      BIGINT,
    "ProductCode"     VARCHAR,
    "ProductName"     VARCHAR,
    "MovementType"    VARCHAR,
    "MovementDate"    DATE,
    "Quantity"        NUMERIC,
    "UnitCost"        NUMERIC,
    "TotalCost"       NUMERIC,
    "DocumentRef"     VARCHAR,
    "WarehouseFrom"   VARCHAR,
    "WarehouseTo"     VARCHAR,
    "Notes"           VARCHAR,
    "CreatedAt"       TIMESTAMP,
    "CreatedByUserId" INT
)
LANGUAGE plpgsql AS $fn$
DECLARE
    v_offset INT;
    v_limit  INT;
    v_total  BIGINT;
BEGIN
    v_limit  := COALESCE(NULLIF(p_limit, 0), 50);
    IF v_limit < 1   THEN v_limit := 50;  END IF;
    IF v_limit > 500  THEN v_limit := 500; END IF;
    v_offset := (COALESCE(NULLIF(p_page, 0), 1) - 1) * v_limit;
    IF v_offset < 0 THEN v_offset := 0; END IF;

    SELECT COUNT(1) INTO v_total
    FROM master."InventoryMovement" m
    WHERE m."CompanyId" = p_company_id
      AND COALESCE(m."IsDeleted", FALSE) = FALSE
      AND (p_search IS NULL
           OR m."ProductCode" ILIKE '%' || p_search || '%'
           OR COALESCE(m."ProductName",'') ILIKE '%' || p_search || '%'
           OR COALESCE(m."DocumentRef",'') ILIKE '%' || p_search || '%')
      AND (p_product_code  IS NULL OR m."ProductCode"  = p_product_code)
      AND (p_movement_type IS NULL OR m."MovementType" = p_movement_type)
      AND (p_fecha_desde   IS NULL OR m."MovementDate" >= p_fecha_desde)
      AND (p_fecha_hasta   IS NULL OR m."MovementDate" <= p_fecha_hasta);

    RETURN QUERY
    SELECT
        v_total,
        m."MovementId",
        m."ProductCode"::VARCHAR,
        COALESCE(m."ProductName",'')::VARCHAR,
        m."MovementType"::VARCHAR,
        m."MovementDate",
        m."Quantity",
        m."UnitCost",
        m."TotalCost",
        COALESCE(m."DocumentRef",'')::VARCHAR,
        NULL::VARCHAR  AS "WarehouseFrom",
        NULL::VARCHAR  AS "WarehouseTo",
        COALESCE(m."Notes",'')::VARCHAR,
        m."CreatedAt",
        m."CreatedByUserId"
    FROM master."InventoryMovement" m
    WHERE m."CompanyId" = p_company_id
      AND COALESCE(m."IsDeleted", FALSE) = FALSE
      AND (p_search IS NULL
           OR m."ProductCode" ILIKE '%' || p_search || '%'
           OR COALESCE(m."ProductName",'') ILIKE '%' || p_search || '%'
           OR COALESCE(m."DocumentRef",'') ILIKE '%' || p_search || '%')
      AND (p_product_code  IS NULL OR m."ProductCode"  = p_product_code)
      AND (p_movement_type IS NULL OR m."MovementType" = p_movement_type)
      AND (p_fecha_desde   IS NULL OR m."MovementDate" >= p_fecha_desde)
      AND (p_fecha_hasta   IS NULL OR m."MovementDate" <= p_fecha_hasta)
    ORDER BY m."CreatedAt" DESC
    LIMIT v_limit OFFSET v_offset;
END;
$fn$;
-- +goose StatementEnd

-- ============================================================================
-- 8) usp_inventario_libroinventario  (re-create to ensure canonical columns)
-- ============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_inventario_libroinventario(
    p_company_id   INT     DEFAULT 1,
    p_fecha_desde  DATE    DEFAULT NULL,
    p_fecha_hasta  DATE    DEFAULT NULL,
    p_product_code VARCHAR DEFAULT NULL
)
RETURNS TABLE(
    "CODIGO"              VARCHAR,
    "DESCRIPCION"         VARCHAR,
    "DescripcionCompleta" TEXT,
    "StockInicial"        NUMERIC,
    "Entradas"            NUMERIC,
    "Salidas"             NUMERIC,
    "StockFinal"          NUMERIC,
    "CostoUnitario"       NUMERIC,
    "Unidad"              VARCHAR
)
LANGUAGE plpgsql AS $fn$
BEGIN
    RETURN QUERY
    WITH movs AS (
        SELECT
            im."ProductCode",
            SUM(CASE WHEN im."MovementType" IN ('ENTRADA','AJUSTE','AJUSTE_POSITIVO') THEN im."Quantity" ELSE 0 END) AS entradas_total,
            SUM(CASE WHEN im."MovementType" IN ('SALIDA','AJUSTE_NEGATIVO') THEN im."Quantity" ELSE 0 END)           AS salidas_total,
            SUM(CASE WHEN im."MovementType" IN ('ENTRADA','AJUSTE','AJUSTE_POSITIVO') AND im."MovementDate" <= p_fecha_hasta THEN im."Quantity" ELSE 0 END) AS entradas_rango,
            SUM(CASE WHEN im."MovementType" IN ('SALIDA','AJUSTE_NEGATIVO') AND im."MovementDate" <= p_fecha_hasta THEN im."Quantity" ELSE 0 END)           AS salidas_rango
        FROM master."InventoryMovement" im
        WHERE im."CompanyId" = p_company_id
          AND COALESCE(im."IsDeleted", FALSE) = FALSE
          AND im."MovementDate" >= p_fecha_desde
        GROUP BY im."ProductCode"
    )
    SELECT
        p."ProductCode"   AS "CODIGO",
        p."ProductName"   AS "DESCRIPCION",
        TRIM(BOTH FROM
            COALESCE(p."CategoryCode",'') ||
            CASE WHEN COALESCE(p."ProductName",'') <> '' THEN ' ' || p."ProductName" ELSE '' END
        )                 AS "DescripcionCompleta",
        COALESCE(p."StockQty",0) - COALESCE(m.entradas_total,0) + COALESCE(m.salidas_total,0) AS "StockInicial",
        COALESCE(m.entradas_rango, 0) AS "Entradas",
        COALESCE(m.salidas_rango, 0)  AS "Salidas",
        (COALESCE(p."StockQty",0) - COALESCE(m.entradas_total,0) + COALESCE(m.salidas_total,0))
            + COALESCE(m.entradas_rango,0) - COALESCE(m.salidas_rango,0) AS "StockFinal",
        COALESCE(p."CostPrice", 0) AS "CostoUnitario",
        COALESCE(p."UnitCode",'')  AS "Unidad"
    FROM master."Product" p
    LEFT JOIN movs m ON m."ProductCode" = p."ProductCode"
    WHERE p."CompanyId" = p_company_id
      AND COALESCE(p."IsDeleted", FALSE) = FALSE
      AND (p_product_code IS NULL OR p."ProductCode" = p_product_code)
    ORDER BY p."ProductCode";
END;
$fn$;
-- +goose StatementEnd

-- ============================================================================
-- 9) usp_inventario_cacheload  (re-create for safety — already canonical)
-- ============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_inventario_cacheload(
    p_company_id INT
)
RETURNS TABLE(
    "ProductId"      BIGINT,
    "ProductCode"    VARCHAR,
    "ProductName"    VARCHAR,
    "CategoryCode"   VARCHAR,
    "UnitCode"       VARCHAR,
    "SalesPrice"     NUMERIC,
    "CostPrice"      NUMERIC,
    "DefaultTaxRate" NUMERIC,
    "StockQty"       NUMERIC,
    "IsService"      BOOLEAN,
    "IsDeleted"      BOOLEAN,
    "UpdatedAt"      TIMESTAMP
)
LANGUAGE plpgsql AS $fn$
BEGIN
    RETURN QUERY
    SELECT p."ProductId", p."ProductCode", p."ProductName",
           p."CategoryCode", p."UnitCode",
           p."SalesPrice", p."CostPrice", p."DefaultTaxRate",
           p."StockQty", p."IsService", p."IsDeleted", p."UpdatedAt"
    FROM master."Product" p
    WHERE p."CompanyId" = p_company_id
    ORDER BY p."ProductCode";
END;
$fn$;
-- +goose StatementEnd

-- ============================================================================
-- 10) usp_inventario_getbycode  (re-create for safety — already canonical)
-- ============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_inventario_getbycode(
    p_company_id INT,
    p_codigo     VARCHAR
)
RETURNS TABLE(
    "ProductId"      BIGINT,
    "ProductCode"    VARCHAR,
    "ProductName"    VARCHAR,
    "CategoryCode"   VARCHAR,
    "UnitCode"       VARCHAR,
    "SalesPrice"     NUMERIC,
    "CostPrice"      NUMERIC,
    "DefaultTaxRate" NUMERIC,
    "StockQty"       NUMERIC,
    "IsService"      BOOLEAN,
    "IsDeleted"      BOOLEAN,
    "UpdatedAt"      TIMESTAMP
)
LANGUAGE plpgsql AS $fn$
BEGIN
    RETURN QUERY
    SELECT p."ProductId", p."ProductCode", p."ProductName",
           p."CategoryCode", p."UnitCode",
           p."SalesPrice", p."CostPrice", p."DefaultTaxRate",
           p."StockQty", p."IsService", p."IsDeleted", p."UpdatedAt"
    FROM master."Product" p
    WHERE p."CompanyId" = p_company_id AND p."ProductCode" = p_codigo
    LIMIT 1;
END;
$fn$;
-- +goose StatementEnd

-- ============================================================================
-- 11) usp_inventario_delete  (re-create for safety — add CompanyId param)
-- ============================================================================
-- +goose StatementBegin
DROP FUNCTION IF EXISTS public.usp_inventario_delete(character varying);

CREATE OR REPLACE FUNCTION public.usp_inventario_delete(
    p_company_id INT DEFAULT NULL,
    p_codigo     VARCHAR DEFAULT NULL
)
RETURNS TABLE("Resultado" INT, "Mensaje" VARCHAR)
LANGUAGE plpgsql AS $fn$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM master."Product"
        WHERE "ProductCode" = p_codigo AND COALESCE("IsDeleted", FALSE) = FALSE
    ) THEN
        RETURN QUERY SELECT -1, 'Articulo no encontrado'::VARCHAR;
        RETURN;
    END IF;

    BEGIN
        UPDATE master."Product"
        SET "IsDeleted" = TRUE,
            "IsActive"  = FALSE,
            "DeletedAt" = NOW() AT TIME ZONE 'UTC',
            "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
        WHERE "ProductCode" = p_codigo
          AND COALESCE("IsDeleted", FALSE) = FALSE;

        RETURN QUERY SELECT 1, 'OK'::VARCHAR;
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT -99, SQLERRM::VARCHAR;
    END;
END;
$fn$;
-- +goose StatementEnd

-- +goose Down
-- Rollback: would need to restore old functions with legacy column refs.
-- Not practical since legacy columns don't exist in canonical schema.
SELECT 1;
