-- usp_almacen_delete
DROP FUNCTION IF EXISTS public.usp_almacen_delete(character varying) CASCADE;
DROP FUNCTION IF EXISTS public.usp_almacen_delete(p_codigo character varying)
 RETURNS TABLE("Resultado" integer, "Mensaje" character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM master."Warehouse"
        WHERE "WarehouseCode" = p_codigo AND COALESCE("IsDeleted", FALSE) = FALSE
    ) THEN
        RETURN QUERY SELECT -1, 'Almacen no encontrado'::VARCHAR(500);
        RETURN;
    END IF;

    UPDATE master."Warehouse"
    SET "IsDeleted" = TRUE, "IsActive" = FALSE
    WHERE "WarehouseCode" = p_codigo;

    RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
END;
$function$
;

-- usp_almacen_getbycodigo
DROP FUNCTION IF EXISTS public.usp_almacen_getbycodigo(character varying) CASCADE;
DROP FUNCTION IF EXISTS public.usp_almacen_getbycodigo(p_codigo character varying)
 RETURNS TABLE("Codigo" character varying, "Descripcion" character varying, "Tipo" character varying, "IsActive" boolean, "IsDeleted" boolean, "CompanyId" integer, "WarehouseCode" character varying, "Description" character varying, "WarehouseType" character varying)
 LANGUAGE plpgsql
AS $function$
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
      AND COALESCE(w."IsDeleted", FALSE) = FALSE;
END;
$function$
;

-- usp_almacen_insert
DROP FUNCTION IF EXISTS public.usp_almacen_insert(jsonb) CASCADE;
DROP FUNCTION IF EXISTS public.usp_almacen_insert(p_row_json jsonb)
 RETURNS TABLE("Resultado" integer, "Mensaje" character varying)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_company_id INT;
    v_codigo     VARCHAR(10);
    v_desc       VARCHAR(100);
    v_tipo       VARCHAR(50);
BEGIN
    -- Obtener CompanyId por defecto
    SELECT c."CompanyId" INTO v_company_id
    FROM cfg."Company" c
    WHERE COALESCE(c."IsDeleted", FALSE) = FALSE
    ORDER BY c."CompanyId"
    LIMIT 1;

    IF v_company_id IS NULL THEN v_company_id := 1; END IF;

    v_codigo := NULLIF(p_row_json->>'Codigo', ''::character varying);
    v_desc   := NULLIF(p_row_json->>'Descripcion', ''::character varying);
    v_tipo   := NULLIF(p_row_json->>'Tipo', ''::character varying);

    -- Verificar duplicado
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
$function$
;

-- usp_almacen_list
DROP FUNCTION IF EXISTS public.usp_almacen_list(character varying, character varying, integer, integer) CASCADE;
DROP FUNCTION IF EXISTS public.usp_almacen_list(p_search character varying DEFAULT NULL::character varying, p_tipo character varying DEFAULT NULL::character varying, p_page integer DEFAULT 1, p_limit integer DEFAULT 50)
 RETURNS TABLE("Codigo" character varying, "Descripcion" character varying, "Tipo" character varying, "IsActive" boolean, "IsDeleted" boolean, "CompanyId" integer, "WarehouseCode" character varying, "Description" character varying, "WarehouseType" character varying, "TotalCount" integer)
 LANGUAGE plpgsql
AS $function$
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

    -- Conteo total
    SELECT COUNT(1) INTO v_total
    FROM master."Warehouse" w
    WHERE COALESCE(w."IsDeleted", FALSE) = FALSE
      AND (v_search IS NULL OR (w."WarehouseCode" ILIKE v_search OR w."Description" ILIKE v_search))
      AND (p_tipo IS NULL OR TRIM(p_tipo) = '' OR w."WarehouseType" = p_tipo);

    -- Resultados paginados
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
      AND (v_search IS NULL OR (w."WarehouseCode" ILIKE v_search OR w."Description" ILIKE v_search))
      AND (p_tipo IS NULL OR TRIM(p_tipo) = '' OR w."WarehouseType" = p_tipo)
    ORDER BY w."WarehouseCode"
    LIMIT v_limit OFFSET v_offset;
END;
$function$
;

-- usp_almacen_update
DROP FUNCTION IF EXISTS public.usp_almacen_update(character varying, jsonb) CASCADE;
DROP FUNCTION IF EXISTS public.usp_almacen_update(p_codigo character varying, p_row_json jsonb)
 RETURNS TABLE("Resultado" integer, "Mensaje" character varying)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_desc VARCHAR(100);
    v_tipo VARCHAR(50);
BEGIN
    -- Verificar existencia
    IF NOT EXISTS (
        SELECT 1 FROM master."Warehouse"
        WHERE "WarehouseCode" = p_codigo AND COALESCE("IsDeleted", FALSE) = FALSE
    ) THEN
        RETURN QUERY SELECT -1, 'Almacen no encontrado'::VARCHAR(500);
        RETURN;
    END IF;

    v_desc := NULLIF(p_row_json->>'Descripcion', ''::character varying);
    v_tipo := NULLIF(p_row_json->>'Tipo', ''::character varying);

    UPDATE master."Warehouse" SET
        "Description"   = COALESCE(v_desc, "Description"),
        "WarehouseType" = COALESCE(v_tipo, "WarehouseType")
    WHERE "WarehouseCode" = p_codigo
      AND COALESCE("IsDeleted", FALSE) = FALSE;

    RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
END;
$function$
;

-- usp_inv_movement_getbyid
DROP FUNCTION IF EXISTS public.usp_inv_movement_getbyid(integer) CASCADE;
DROP FUNCTION IF EXISTS public.usp_inv_movement_getbyid(p_id integer)
 RETURNS TABLE("MovementId" integer, "Codigo" character varying, "Product" character varying, "Documento" character varying, "Tipo" character varying, "Fecha" timestamp with time zone, "Quantity" numeric, "UnitCost" numeric, "TotalCost" numeric, "Notes" character varying)
 LANGUAGE plpgsql
AS $function$ BEGIN
    RETURN QUERY SELECT m."MovementId",m."ProductCode",m."ProductName",m."DocumentRef",
        m."MovementType",m."MovementDate",m."Quantity",m."UnitCost",m."TotalCost",m."Notes"
    FROM master."InventoryMovement" m WHERE m."MovementId"=p_id AND m."IsDeleted"=FALSE;
END; $function$
;

-- usp_inv_movement_list
DROP FUNCTION IF EXISTS public.usp_inv_movement_list(character varying, character varying, integer, integer) CASCADE;
DROP FUNCTION IF EXISTS public.usp_inv_movement_list(p_search character varying DEFAULT NULL::character varying, p_tipo character varying DEFAULT NULL::character varying, p_offset integer DEFAULT 0, p_limit integer DEFAULT 50)
 RETURNS TABLE("MovementId" integer, "Codigo" character varying, "Product" character varying, "Documento" character varying, "Tipo" character varying, "Fecha" timestamp with time zone, "Quantity" numeric, "UnitCost" numeric, "TotalCost" numeric, "Notes" character varying, "TotalCount" bigint)
 LANGUAGE plpgsql
AS $function$
DECLARE v_total BIGINT;
BEGIN
    SELECT COUNT(1) INTO v_total FROM master."InventoryMovement"
    WHERE "IsDeleted"=FALSE
      AND (p_search IS NULL OR "ProductCode" LIKE p_search OR "ProductName" LIKE p_search OR "DocumentRef" LIKE p_search)
      AND (p_tipo IS NULL OR "MovementType"=p_tipo);

    RETURN QUERY SELECT m."MovementId",m."ProductCode",m."ProductName",m."DocumentRef",
        m."MovementType",m."MovementDate",m."Quantity",m."UnitCost",m."TotalCost",m."Notes",v_total
    FROM master."InventoryMovement" m
    WHERE m."IsDeleted"=FALSE
      AND (p_search IS NULL OR m."ProductCode" LIKE p_search OR m."ProductName" LIKE p_search OR m."DocumentRef" LIKE p_search)
      AND (p_tipo IS NULL OR m."MovementType"=p_tipo)
    ORDER BY m."MovementDate" DESC, m."MovementId" DESC
    LIMIT p_limit OFFSET p_offset;
END;
$function$
;

-- usp_inv_movement_listperiodsummary
DROP FUNCTION IF EXISTS public.usp_inv_movement_listperiodsummary(character varying, character varying, integer, integer) CASCADE;
DROP FUNCTION IF EXISTS public.usp_inv_movement_listperiodsummary(p_periodo character varying DEFAULT NULL::character varying, p_codigo character varying DEFAULT NULL::character varying, p_offset integer DEFAULT 0, p_limit integer DEFAULT 50)
 RETURNS TABLE("SummaryId" integer, "Periodo" character varying, "Codigo" character varying, "OpeningQty" numeric, "InboundQty" numeric, "OutboundQty" numeric, "ClosingQty" numeric, fecha timestamp with time zone, "IsClosed" boolean, "TotalCount" bigint)
 LANGUAGE plpgsql
AS $function$
DECLARE v_total BIGINT;
BEGIN
    SELECT COUNT(1) INTO v_total FROM master."InventoryPeriodSummary"
    WHERE (p_periodo IS NULL OR "Period"=p_periodo) AND (p_codigo IS NULL OR "ProductCode"=p_codigo);

    RETURN QUERY SELECT s."SummaryId",s."Period",s."ProductCode",s."OpeningQty",
        s."InboundQty",s."OutboundQty",s."ClosingQty",s."SummaryDate",s."IsClosed",v_total
    FROM master."InventoryPeriodSummary" s
    WHERE (p_periodo IS NULL OR s."Period"=p_periodo) AND (p_codigo IS NULL OR s."ProductCode"=p_codigo)
    ORDER BY s."Period" DESC, s."ProductCode"
    LIMIT p_limit OFFSET p_offset;
END; $function$
;

-- usp_inventario_cacheload
DROP FUNCTION IF EXISTS public.usp_inventario_cacheload(integer) CASCADE;
DROP FUNCTION IF EXISTS public.usp_inventario_cacheload(p_company_id integer)
 RETURNS TABLE("ProductId" bigint, "ProductCode" character varying, "ProductName" character varying, "CategoryCode" character varying, "UnitCode" character varying, "SalesPrice" numeric, "CostPrice" numeric, "DefaultTaxRate" numeric, "StockQty" numeric, "IsService" boolean, "IsDeleted" boolean, "UpdatedAt" timestamp without time zone)
 LANGUAGE plpgsql
AS $function$
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
$function$
;

-- usp_inventario_dashboard
DROP FUNCTION IF EXISTS public.usp_inventario_dashboard(integer) CASCADE;
DROP FUNCTION IF EXISTS public.usp_inventario_dashboard(p_company_id integer DEFAULT 1)
 RETURNS TABLE("TotalArticulos" bigint, "BajoStock" bigint, "TotalCategorias" bigint, "ValorInventario" numeric, "MovimientosMes" bigint)
 LANGUAGE plpgsql
AS $function$
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
$function$
;

-- usp_inventario_delete
DROP FUNCTION IF EXISTS public.usp_inventario_delete(character varying) CASCADE;
DROP FUNCTION IF EXISTS public.usp_inventario_delete(p_codigo character varying)
 RETURNS TABLE("Resultado" integer, "Mensaje" character varying)
 LANGUAGE plpgsql
AS $function$
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
        SET "IsDeleted" = TRUE, "IsActive" = FALSE
        WHERE "ProductCode" = p_codigo;

        RETURN QUERY SELECT 1, 'OK'::VARCHAR;
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT -99, SQLERRM::VARCHAR;
    END;
END;
$function$
;

-- usp_inventario_getbycode
DROP FUNCTION IF EXISTS public.usp_inventario_getbycode(integer, character varying) CASCADE;
DROP FUNCTION IF EXISTS public.usp_inventario_getbycode(p_company_id integer, p_codigo character varying)
 RETURNS TABLE("ProductId" bigint, "ProductCode" character varying, "ProductName" character varying, "CategoryCode" character varying, "UnitCode" character varying, "SalesPrice" numeric, "CostPrice" numeric, "DefaultTaxRate" numeric, "StockQty" numeric, "IsService" boolean, "IsDeleted" boolean, "UpdatedAt" timestamp without time zone)
 LANGUAGE plpgsql
AS $function$
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
$function$
;

-- usp_inventario_getbycodigo
DROP FUNCTION IF EXISTS public.usp_inventario_getbycodigo(character varying) CASCADE;
DROP FUNCTION IF EXISTS public.usp_inventario_getbycodigo(p_codigo character varying)
 RETURNS TABLE("ProductId" integer, "ProductCode" character varying, "Referencia" character varying, "Categoria" character varying, "Marca" character varying, "Tipo" character varying, "Unidad" character varying, "Clase" character varying, "ProductName" character varying, "StockQty" double precision, "VENTA" double precision, "MINIMO" double precision, "MAXIMO" double precision, "CostPrice" double precision, "SalesPrice" double precision, "PORCENTAJE" double precision, "UBICACION" character varying, "Co_Usuario" character varying, "Linea" character varying, "N_PARTE" character varying, "Barra" character varying, "IsService" boolean, "IsActive" boolean, "CompanyId" integer, "CODIGO" character varying, "DESCRIPCION" character varying, "EXISTENCIA" double precision, "PRECIO" double precision, "COSTO" double precision, "Servicio" boolean, "DescripcionCompleta" character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        p."ProductId",
        p."ProductCode",
        p."Referencia",
        p."Categoria",
        p."Marca",
        p."Tipo",
        p."Unidad",
        p."Clase",
        p."ProductName",
        p."StockQty",
        p."VENTA",
        p."MINIMO",
        p."MAXIMO",
        p."CostPrice",
        p."SalesPrice",
        p."PORCENTAJE",
        p."UBICACION",
        p."Co_Usuario",
        p."Linea",
        p."N_PARTE",
        p."Barra",
        p."IsService",
        p."IsActive",
        p."CompanyId",
        p."ProductCode"        AS "CODIGO",
        p."ProductName"        AS "DESCRIPCION",
        p."StockQty"           AS "EXISTENCIA",
        p."SalesPrice"         AS "PRECIO",
        p."CostPrice"          AS "COSTO",
        p."IsService"          AS "Servicio",
        TRIM(BOTH FROM
            COALESCE(RTRIM(p."Categoria"), '') ||
            CASE WHEN RTRIM(COALESCE(p."Tipo", '')) <> '' THEN ' ' || RTRIM(p."Tipo") ELSE '' END ||
            CASE WHEN RTRIM(COALESCE(p."ProductName", '')) <> '' THEN ' ' || RTRIM(p."ProductName") ELSE '' END ||
            CASE WHEN RTRIM(COALESCE(p."Marca", '')) <> '' THEN ' ' || RTRIM(p."Marca") ELSE '' END ||
            CASE WHEN RTRIM(COALESCE(p."Clase", '')) <> '' THEN ' ' || RTRIM(p."Clase") ELSE '' END
        )                      AS "DescripcionCompleta"
    FROM master."Product" p
    WHERE p."ProductCode" = p_codigo
      AND COALESCE(p."IsDeleted", FALSE) = FALSE;
END;
$function$
;

-- usp_inventario_insert
DROP FUNCTION IF EXISTS public.usp_inventario_insert(jsonb) CASCADE;
DROP FUNCTION IF EXISTS public.usp_inventario_insert(p_row_json jsonb)
 RETURNS TABLE("Resultado" integer, "Mensaje" character varying)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_company_id INT;
    v_codigo     VARCHAR(15);
BEGIN
    -- Obtener CompanyId
    SELECT "CompanyId" INTO v_company_id
    FROM cfg."Company"
    WHERE COALESCE("IsDeleted", FALSE) = FALSE
    ORDER BY "CompanyId" LIMIT 1;
    IF v_company_id IS NULL THEN v_company_id := 1; END IF;

    v_codigo := NULLIF(p_row_json->>'CODIGO', ''::character varying);

    -- Verificar duplicado
    IF EXISTS (
        SELECT 1 FROM master."Product"
        WHERE "ProductCode" = v_codigo AND "CompanyId" = v_company_id
    ) THEN
        RETURN QUERY SELECT -1, 'Articulo ya existe'::VARCHAR;
        RETURN;
    END IF;

    BEGIN
        INSERT INTO master."Product" (
            "ProductCode", "Referencia", "Categoria", "Marca", "Tipo", "Unidad", "Clase", "ProductName",
            "StockQty", "VENTA", "MINIMO", "MAXIMO", "CostPrice", "SalesPrice", "PORCENTAJE",
            "UBICACION", "Co_Usuario", "Linea", "N_PARTE", "Barra",
            "IsService", "IsActive", "IsDeleted", "CompanyId"
        ) VALUES (
            v_codigo,
            NULLIF(p_row_json->>'Referencia', ''::character varying),
            NULLIF(p_row_json->>'Categoria', ''::character varying),
            NULLIF(p_row_json->>'Marca', ''::character varying),
            NULLIF(p_row_json->>'Tipo', ''::character varying),
            NULLIF(p_row_json->>'Unidad', ''::character varying),
            NULLIF(p_row_json->>'Clase', ''::character varying),
            NULLIF(p_row_json->>'DESCRIPCION', ''::character varying),
            CASE WHEN NULLIF(p_row_json->>'EXISTENCIA', ''::character varying) IS NULL THEN NULL ELSE (p_row_json->>'EXISTENCIA')::DOUBLE PRECISION END,
            CASE WHEN NULLIF(p_row_json->>'VENTA', ''::character varying) IS NULL THEN NULL ELSE (p_row_json->>'VENTA')::DOUBLE PRECISION END,
            CASE WHEN NULLIF(p_row_json->>'MINIMO', ''::character varying) IS NULL THEN NULL ELSE (p_row_json->>'MINIMO')::DOUBLE PRECISION END,
            CASE WHEN NULLIF(p_row_json->>'MAXIMO', ''::character varying) IS NULL THEN NULL ELSE (p_row_json->>'MAXIMO')::DOUBLE PRECISION END,
            CASE WHEN NULLIF(p_row_json->>'PRECIO_COMPRA', ''::character varying) IS NULL THEN NULL ELSE (p_row_json->>'PRECIO_COMPRA')::DOUBLE PRECISION END,
            CASE WHEN NULLIF(p_row_json->>'PRECIO_VENTA', ''::character varying) IS NULL THEN NULL ELSE (p_row_json->>'PRECIO_VENTA')::DOUBLE PRECISION END,
            CASE WHEN NULLIF(p_row_json->>'PORCENTAJE', ''::character varying) IS NULL THEN NULL ELSE (p_row_json->>'PORCENTAJE')::DOUBLE PRECISION END,
            NULLIF(p_row_json->>'UBICACION', ''::character varying),
            NULLIF(p_row_json->>'Co_Usuario', ''::character varying),
            NULLIF(p_row_json->>'Linea', ''::character varying),
            NULLIF(p_row_json->>'N_PARTE', ''::character varying),
            NULLIF(p_row_json->>'Barra', ''::character varying),
            COALESCE((NULLIF(p_row_json->>'Servicio', ''::character varying))::BOOLEAN, FALSE)::character varying,
            TRUE,
            FALSE,
            v_company_id
        );

        RETURN QUERY SELECT 1, 'OK'::VARCHAR;
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT -99, SQLERRM::VARCHAR;
    END;
END;
$function$
;

-- usp_inventario_libroinventario
DROP FUNCTION IF EXISTS public.usp_inventario_libroinventario(integer, date, date, character varying) CASCADE;
DROP FUNCTION IF EXISTS public.usp_inventario_libroinventario(p_company_id integer DEFAULT 1, p_fecha_desde date DEFAULT NULL::date, p_fecha_hasta date DEFAULT NULL::date, p_product_code character varying DEFAULT NULL::character varying)
 RETURNS TABLE("CODIGO" character varying, "DESCRIPCION" character varying, "DescripcionCompleta" character varying, "StockInicial" numeric, "Entradas" numeric, "Salidas" numeric, "StockFinal" numeric, "CostoUnitario" numeric, "Unidad" character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    WITH "MovsByProduct" AS (
        SELECT
            im."ProductCode",
            SUM(CASE WHEN im."MovementType" IN ('ENTRADA', 'AJUSTE') THEN im."Quantity" ELSE 0 END) AS "EntradasDesde",
            SUM(CASE WHEN im."MovementType" = 'SALIDA' THEN im."Quantity" ELSE 0 END) AS "SalidasDesde",
            SUM(CASE WHEN im."MovementType" IN ('ENTRADA', 'AJUSTE') AND im."MovementDate" <= p_fecha_hasta THEN im."Quantity" ELSE 0 END) AS "EntradasR",
            SUM(CASE WHEN im."MovementType" = 'SALIDA' AND im."MovementDate" <= p_fecha_hasta THEN im."Quantity" ELSE 0 END) AS "SalidasR"
        FROM master."InventoryMovement" im
        WHERE im."CompanyId" = p_company_id
          AND COALESCE(im."IsDeleted", FALSE) = FALSE
          AND im."MovementDate" >= p_fecha_desde
        GROUP BY im."ProductCode"
    )
    SELECT
        p."ProductCode"       AS "CODIGO",
        p."ProductName"       AS "DESCRIPCION",
        TRIM(BOTH FROM
            COALESCE(RTRIM(p."CategoryCode"), '') ||
            CASE WHEN RTRIM(COALESCE(p."ProductName", '')) <> '' THEN ' ' || RTRIM(p."ProductName") ELSE '' END
        )                     AS "DescripcionCompleta",
        COALESCE(p."StockQty", 0) - COALESCE(m."EntradasDesde", 0) + COALESCE(m."SalidasDesde", 0) AS "StockInicial",
        COALESCE(m."EntradasR", 0)  AS "Entradas",
        COALESCE(m."SalidasR", 0)   AS "Salidas",
        (COALESCE(p."StockQty", 0) - COALESCE(m."EntradasDesde", 0) + COALESCE(m."SalidasDesde", 0))
            + COALESCE(m."EntradasR", 0) - COALESCE(m."SalidasR", 0) AS "StockFinal",
        COALESCE(p."CostPrice", 0)  AS "CostoUnitario",
        p."UnitCode"                AS "Unidad"
    FROM master."Product" p
    LEFT JOIN "MovsByProduct" m ON m."ProductCode" = p."ProductCode"
    WHERE p."CompanyId" = p_company_id
      AND COALESCE(p."IsDeleted", FALSE) = FALSE
      AND (p_product_code IS NULL OR p."ProductCode" = p_product_code)
    ORDER BY p."ProductCode";
END;
$function$
;

-- usp_inventario_list
DROP FUNCTION IF EXISTS public.usp_inventario_list(character varying, character varying, character varying, character varying, character varying, character varying, integer, integer) CASCADE;
DROP FUNCTION IF EXISTS public.usp_inventario_list(p_search character varying DEFAULT NULL::character varying, p_categoria character varying DEFAULT NULL::character varying, p_marca character varying DEFAULT NULL::character varying, p_linea character varying DEFAULT NULL::character varying, p_tipo character varying DEFAULT NULL::character varying, p_clase character varying DEFAULT NULL::character varying, p_page integer DEFAULT 1, p_limit integer DEFAULT 50)
 RETURNS TABLE("TotalCount" bigint, "ProductId" integer, "ProductCode" character varying, "Referencia" character varying, "Categoria" character varying, "Marca" character varying, "Tipo" character varying, "Unidad" character varying, "Clase" character varying, "ProductName" character varying, "StockQty" double precision, "VENTA" double precision, "MINIMO" double precision, "MAXIMO" double precision, "CostPrice" double precision, "SalesPrice" double precision, "PORCENTAJE" double precision, "UBICACION" character varying, "Co_Usuario" character varying, "Linea" character varying, "N_PARTE" character varying, "Barra" character varying, "IsService" boolean, "IsActive" boolean, "CompanyId" integer, "CODIGO" character varying, "DESCRIPCION" character varying, "EXISTENCIA" double precision, "PRECIO" double precision, "COSTO" double precision, "Servicio" boolean, "DescripcionCompleta" character varying)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_offset  INT;
    v_limit   INT;
    v_total   BIGINT;
    v_search  VARCHAR(100);
BEGIN
    v_limit  := COALESCE(NULLIF(p_limit, 0), 50);
    IF v_limit < 1 THEN v_limit := 50; END IF;
    IF v_limit > 500 THEN v_limit := 500; END IF;
    v_offset := (COALESCE(NULLIF(p_page, 0), 1) - 1) * v_limit;
    IF v_offset < 0 THEN v_offset := 0; END IF;

    -- Preparar busqueda con comodines
    v_search := NULL;
    IF p_search IS NOT NULL AND TRIM(p_search) <> '' THEN
        v_search := '%' || p_search || '%';
    END IF;

    -- Contar total
    SELECT COUNT(1) INTO v_total
    FROM master."Product"
    WHERE COALESCE("IsDeleted", FALSE) = FALSE
      AND (v_search IS NULL OR
           "ProductCode" LIKE v_search OR "Referencia" LIKE v_search OR
           "ProductName" LIKE v_search OR "Categoria" LIKE v_search OR
           "Tipo" LIKE v_search OR "Marca" LIKE v_search OR
           "Clase" LIKE v_search OR "Linea" LIKE v_search)
      AND (p_categoria IS NULL OR TRIM(p_categoria) = '' OR "Categoria" = p_categoria)
      AND (p_marca IS NULL OR TRIM(p_marca) = '' OR "Marca" = p_marca)
      AND (p_linea IS NULL OR TRIM(p_linea) = '' OR "Linea" = p_linea)
      AND (p_tipo IS NULL OR TRIM(p_tipo) = '' OR "Tipo" = p_tipo)
      AND (p_clase IS NULL OR TRIM(p_clase) = '' OR "Clase" = p_clase);

    RETURN QUERY
    SELECT
        v_total                     AS "TotalCount",
        p."ProductId",
        p."ProductCode",
        p."Referencia",
        p."Categoria",
        p."Marca",
        p."Tipo",
        p."Unidad",
        p."Clase",
        p."ProductName",
        p."StockQty",
        p."VENTA",
        p."MINIMO",
        p."MAXIMO",
        p."CostPrice",
        p."SalesPrice",
        p."PORCENTAJE",
        p."UBICACION",
        p."Co_Usuario",
        p."Linea",
        p."N_PARTE",
        p."Barra",
        p."IsService",
        p."IsActive",
        p."CompanyId",
        p."ProductCode"             AS "CODIGO",
        p."ProductName"             AS "DESCRIPCION",
        p."StockQty"                AS "EXISTENCIA",
        p."SalesPrice"              AS "PRECIO",
        p."CostPrice"               AS "COSTO",
        p."IsService"               AS "Servicio",
        TRIM(BOTH FROM
            COALESCE(RTRIM(p."Categoria"), '') ||
            CASE WHEN RTRIM(COALESCE(p."Tipo", '')) <> '' THEN ' ' || RTRIM(p."Tipo") ELSE '' END ||
            CASE WHEN RTRIM(COALESCE(p."ProductName", '')) <> '' THEN ' ' || RTRIM(p."ProductName") ELSE '' END ||
            CASE WHEN RTRIM(COALESCE(p."Marca", '')) <> '' THEN ' ' || RTRIM(p."Marca") ELSE '' END ||
            CASE WHEN RTRIM(COALESCE(p."Clase", '')) <> '' THEN ' ' || RTRIM(p."Clase") ELSE '' END
        )                           AS "DescripcionCompleta"
    FROM master."Product" p
    WHERE COALESCE(p."IsDeleted", FALSE) = FALSE
      AND (v_search IS NULL OR
           p."ProductCode" LIKE v_search OR p."Referencia" LIKE v_search OR
           p."ProductName" LIKE v_search OR p."Categoria" LIKE v_search OR
           p."Tipo" LIKE v_search OR p."Marca" LIKE v_search OR
           p."Clase" LIKE v_search OR p."Linea" LIKE v_search)
      AND (p_categoria IS NULL OR TRIM(p_categoria) = '' OR p."Categoria" = p_categoria)
      AND (p_marca IS NULL OR TRIM(p_marca) = '' OR p."Marca" = p_marca)
      AND (p_linea IS NULL OR TRIM(p_linea) = '' OR p."Linea" = p_linea)
      AND (p_tipo IS NULL OR TRIM(p_tipo) = '' OR p."Tipo" = p_tipo)
      AND (p_clase IS NULL OR TRIM(p_clase) = '' OR p."Clase" = p_clase)
    ORDER BY p."ProductCode"
    LIMIT v_limit OFFSET v_offset;
END;
$function$
;

-- usp_inventario_movimiento_insert
DROP FUNCTION IF EXISTS public.usp_inventario_movimiento_insert(integer, character varying, character varying, numeric, numeric, character varying, character varying, character varying, character varying, integer) CASCADE;
DROP FUNCTION IF EXISTS public.usp_inventario_movimiento_insert(p_company_id integer DEFAULT 1, p_product_code character varying DEFAULT NULL::character varying, p_movement_type character varying DEFAULT NULL::character varying, p_quantity numeric DEFAULT 0, p_unit_cost numeric DEFAULT 0, p_document_ref character varying DEFAULT NULL::character varying, p_warehouse_from character varying DEFAULT NULL::character varying, p_warehouse_to character varying DEFAULT NULL::character varying, p_notes character varying DEFAULT NULL::character varying, p_user_id integer DEFAULT NULL::integer)
 RETURNS TABLE("Resultado" integer, "Mensaje" character varying)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_product_name  VARCHAR(250);
    v_current_stock NUMERIC(18,4);
    v_cost_price    NUMERIC(18,4);
    v_qty           NUMERIC(18,4);
    v_doc_ref       VARCHAR(60);
BEGIN
    SELECT "ProductName", COALESCE("StockQty", 0), COALESCE("CostPrice", 0)
    INTO v_product_name, v_current_stock, v_cost_price
    FROM master."Product"
    WHERE "ProductCode" = p_product_code
      AND "CompanyId" = p_company_id
      AND COALESCE("IsDeleted", FALSE) = FALSE;

    IF v_product_name IS NULL THEN
        RETURN QUERY SELECT -1, ('Producto no encontrado: ' || p_product_code)::VARCHAR;
        RETURN;
    END IF;

    IF p_unit_cost = 0 THEN p_unit_cost := v_cost_price; END IF;
    v_qty := ABS(p_quantity);

    BEGIN
        IF p_movement_type = 'TRASLADO' THEN
            IF p_warehouse_from IS NULL OR p_warehouse_to IS NULL THEN
                RETURN QUERY SELECT -2, 'Traslado requiere almacen origen y destino'::VARCHAR;
                RETURN;
            END IF;

            IF v_current_stock < v_qty THEN
                RETURN QUERY SELECT -3, ('Stock insuficiente. Disponible: ' || v_current_stock::TEXT)::VARCHAR;
                RETURN;
            END IF;

            v_doc_ref := COALESCE(p_document_ref,
                'TRASL-' || TO_CHAR(NOW() AT TIME ZONE 'UTC', 'YYYYMMDD') || '-' ||
                LEFT(REPLACE(gen_random_uuid()::TEXT, '-', ''), 6));

            -- Movimiento SALIDA del almacen origen
            INSERT INTO master."InventoryMovement"
                ("CompanyId", "ProductCode", "ProductName", "MovementType", "MovementDate",
                 "Quantity", "UnitCost", "TotalCost", "DocumentRef", "WarehouseFrom", "WarehouseTo",
                 "Notes", "CreatedByUserId")
            VALUES
                (p_company_id, p_product_code, v_product_name, 'SALIDA', (NOW() AT TIME ZONE 'UTC')::DATE,
                 v_qty, p_unit_cost, v_qty * p_unit_cost, v_doc_ref, p_warehouse_from, NULL,
                 'Traslado a ' || p_warehouse_to || CASE WHEN p_notes IS NOT NULL THEN '. ' || p_notes ELSE '' END,
                 p_user_id);

            -- Movimiento ENTRADA al almacen destino
            INSERT INTO master."InventoryMovement"
                ("CompanyId", "ProductCode", "ProductName", "MovementType", "MovementDate",
                 "Quantity", "UnitCost", "TotalCost", "DocumentRef", "WarehouseFrom", "WarehouseTo",
                 "Notes", "CreatedByUserId")
            VALUES
                (p_company_id, p_product_code, v_product_name, 'ENTRADA', (NOW() AT TIME ZONE 'UTC')::DATE,
                 v_qty, p_unit_cost, v_qty * p_unit_cost, v_doc_ref, NULL, p_warehouse_to,
                 'Traslado desde ' || p_warehouse_from || CASE WHEN p_notes IS NOT NULL THEN '. ' || p_notes ELSE '' END,
                 p_user_id);

            -- Stock neto no cambia (traslado es movimiento interno)
        ELSE
            -- Movimiento normal: ENTRADA, SALIDA, AJUSTE
            IF p_movement_type = 'SALIDA' AND v_current_stock < v_qty THEN
                RETURN QUERY SELECT -3, ('Stock insuficiente. Disponible: ' || v_current_stock::TEXT)::VARCHAR;
                RETURN;
            END IF;

            INSERT INTO master."InventoryMovement"
                ("CompanyId", "ProductCode", "ProductName", "MovementType", "MovementDate",
                 "Quantity", "UnitCost", "TotalCost", "DocumentRef", "WarehouseFrom", "WarehouseTo",
                 "Notes", "CreatedByUserId")
            VALUES
                (p_company_id, p_product_code, v_product_name, p_movement_type, (NOW() AT TIME ZONE 'UTC')::DATE,
                 v_qty, p_unit_cost, v_qty * p_unit_cost, p_document_ref, p_warehouse_from, p_warehouse_to,
                 p_notes, p_user_id);

            -- Actualizar stock en master."Product"
            IF p_movement_type IN ('ENTRADA', 'AJUSTE') THEN
                UPDATE master."Product"
                SET "StockQty" = COALESCE("StockQty", 0) + v_qty
                WHERE "ProductCode" = p_product_code AND "CompanyId" = p_company_id;
            ELSIF p_movement_type = 'SALIDA' THEN
                UPDATE master."Product"
                SET "StockQty" = COALESCE("StockQty", 0) - v_qty
                WHERE "ProductCode" = p_product_code AND "CompanyId" = p_company_id;
            END IF;
        END IF;

        RETURN QUERY SELECT 1, 'OK'::VARCHAR;
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT -99, SQLERRM::VARCHAR;
    END;
END;
$function$
;

-- usp_inventario_movimiento_list
DROP FUNCTION IF EXISTS public.usp_inventario_movimiento_list(integer, character varying, character varying, character varying, character varying, date, date, integer, integer) CASCADE;
DROP FUNCTION IF EXISTS public.usp_inventario_movimiento_list(p_company_id integer DEFAULT 1, p_search character varying DEFAULT NULL::character varying, p_product_code character varying DEFAULT NULL::character varying, p_movement_type character varying DEFAULT NULL::character varying, p_warehouse_code character varying DEFAULT NULL::character varying, p_fecha_desde date DEFAULT NULL::date, p_fecha_hasta date DEFAULT NULL::date, p_page integer DEFAULT 1, p_limit integer DEFAULT 50)
 RETURNS TABLE("TotalCount" bigint, "MovementId" integer, "ProductCode" character varying, "ProductName" character varying, "MovementType" character varying, "MovementDate" date, "Quantity" numeric, "UnitCost" numeric, "TotalCost" numeric, "DocumentRef" character varying, "WarehouseFrom" character varying, "WarehouseTo" character varying, "Notes" character varying, "CreatedAt" timestamp without time zone, "CreatedByUserId" integer)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_offset INT;
    v_limit  INT;
    v_total  BIGINT;
BEGIN
    v_limit  := COALESCE(NULLIF(p_limit, 0), 50);
    IF v_limit < 1 THEN v_limit := 50; END IF;
    IF v_limit > 500 THEN v_limit := 500; END IF;
    v_offset := (COALESCE(NULLIF(p_page, 0), 1) - 1) * v_limit;
    IF v_offset < 0 THEN v_offset := 0; END IF;

    SELECT COUNT(1) INTO v_total
    FROM master."InventoryMovement"
    WHERE "CompanyId" = p_company_id
      AND COALESCE("IsDeleted", FALSE) = FALSE
      AND (p_search IS NULL OR "ProductCode" LIKE '%' || p_search || '%'
           OR "ProductName" LIKE '%' || p_search || '%'
           OR "DocumentRef" LIKE '%' || p_search || '%')
      AND (p_product_code IS NULL OR "ProductCode" = p_product_code)
      AND (p_movement_type IS NULL OR "MovementType" = p_movement_type)
      AND (p_warehouse_code IS NULL OR "WarehouseFrom" = p_warehouse_code OR "WarehouseTo" = p_warehouse_code)
      AND (p_fecha_desde IS NULL OR "MovementDate" >= p_fecha_desde)
      AND (p_fecha_hasta IS NULL OR "MovementDate" <= p_fecha_hasta);

    RETURN QUERY
    SELECT
        v_total,
        m."MovementId", m."ProductCode", m."ProductName", m."MovementType", m."MovementDate",
        m."Quantity", m."UnitCost", m."TotalCost", m."DocumentRef",
        m."WarehouseFrom", m."WarehouseTo", m."Notes", m."CreatedAt", m."CreatedByUserId"
    FROM master."InventoryMovement" m
    WHERE m."CompanyId" = p_company_id
      AND COALESCE(m."IsDeleted", FALSE) = FALSE
      AND (p_search IS NULL OR m."ProductCode" LIKE '%' || p_search || '%'
           OR m."ProductName" LIKE '%' || p_search || '%'
           OR m."DocumentRef" LIKE '%' || p_search || '%')
      AND (p_product_code IS NULL OR m."ProductCode" = p_product_code)
      AND (p_movement_type IS NULL OR m."MovementType" = p_movement_type)
      AND (p_warehouse_code IS NULL OR m."WarehouseFrom" = p_warehouse_code OR m."WarehouseTo" = p_warehouse_code)
      AND (p_fecha_desde IS NULL OR m."MovementDate" >= p_fecha_desde)
      AND (p_fecha_hasta IS NULL OR m."MovementDate" <= p_fecha_hasta)
    ORDER BY m."CreatedAt" DESC
    LIMIT v_limit OFFSET v_offset;
END;
$function$
;

-- usp_inventario_update
DROP FUNCTION IF EXISTS public.usp_inventario_update(character varying, jsonb) CASCADE;
DROP FUNCTION IF EXISTS public.usp_inventario_update(p_codigo character varying, p_row_json jsonb)
 RETURNS TABLE("Resultado" integer, "Mensaje" character varying)
 LANGUAGE plpgsql
AS $function$
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
            "Referencia" = COALESCE(NULLIF(p_row_json->>'Referencia', ''::character varying), "Referencia")::character varying,
            "Categoria"  = COALESCE(NULLIF(p_row_json->>'Categoria', ''::character varying), "Categoria")::character varying,
            "Marca"      = COALESCE(NULLIF(p_row_json->>'Marca', ''::character varying), "Marca")::character varying,
            "Tipo"       = COALESCE(NULLIF(p_row_json->>'Tipo', ''::character varying), "Tipo")::character varying,
            "Unidad"     = COALESCE(NULLIF(p_row_json->>'Unidad', ''::character varying), "Unidad")::character varying,
            "Clase"      = COALESCE(NULLIF(p_row_json->>'Clase', ''::character varying), "Clase")::character varying,
            "ProductName"= COALESCE(NULLIF(p_row_json->>'DESCRIPCION', ''::character varying), "ProductName")::character varying,
            "StockQty"   = CASE WHEN NULLIF(p_row_json->>'EXISTENCIA', ''::character varying) IS NULL THEN "StockQty" ELSE (p_row_json->>'EXISTENCIA')::DOUBLE PRECISION END,
            "VENTA"      = CASE WHEN NULLIF(p_row_json->>'VENTA', ''::character varying) IS NULL THEN "VENTA" ELSE (p_row_json->>'VENTA')::DOUBLE PRECISION END,
            "MINIMO"     = CASE WHEN NULLIF(p_row_json->>'MINIMO', ''::character varying) IS NULL THEN "MINIMO" ELSE (p_row_json->>'MINIMO')::DOUBLE PRECISION END,
            "MAXIMO"     = CASE WHEN NULLIF(p_row_json->>'MAXIMO', ''::character varying) IS NULL THEN "MAXIMO" ELSE (p_row_json->>'MAXIMO')::DOUBLE PRECISION END,
            "CostPrice"  = CASE WHEN NULLIF(p_row_json->>'PRECIO_COMPRA', ''::character varying) IS NULL THEN "CostPrice" ELSE (p_row_json->>'PRECIO_COMPRA')::DOUBLE PRECISION END,
            "SalesPrice" = CASE WHEN NULLIF(p_row_json->>'PRECIO_VENTA', ''::character varying) IS NULL THEN "SalesPrice" ELSE (p_row_json->>'PRECIO_VENTA')::DOUBLE PRECISION END,
            "PORCENTAJE" = CASE WHEN NULLIF(p_row_json->>'PORCENTAJE', ''::character varying) IS NULL THEN "PORCENTAJE" ELSE (p_row_json->>'PORCENTAJE')::DOUBLE PRECISION END,
            "UBICACION"  = COALESCE(NULLIF(p_row_json->>'UBICACION', ''::character varying), "UBICACION")::character varying,
            "Co_Usuario" = COALESCE(NULLIF(p_row_json->>'Co_Usuario', ''::character varying), "Co_Usuario")::character varying,
            "Linea"      = COALESCE(NULLIF(p_row_json->>'Linea', ''::character varying), "Linea")::character varying,
            "N_PARTE"    = COALESCE(NULLIF(p_row_json->>'N_PARTE', ''::character varying), "N_PARTE")::character varying,
            "Barra"      = COALESCE(NULLIF(p_row_json->>'Barra', ''::character varying), "Barra")::character varying
        WHERE "ProductCode" = p_codigo AND COALESCE("IsDeleted", FALSE) = FALSE;

        RETURN QUERY SELECT 1, 'OK'::VARCHAR;
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT -99, SQLERRM::VARCHAR;
    END;
END;
$function$
;

