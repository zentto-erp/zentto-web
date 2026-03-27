-- =============================================
-- Funciones CRUD: Inventario (Productos)
-- Compatible con: PostgreSQL 14+
-- Tabla canonica: master."Product" (antes dbo."Inventario")
-- PK: "ProductCode" VARCHAR(15) unico por "CompanyId"
-- Filtros: Search, Categoria, Marca, Linea, Tipo, Clase
--
-- La descripcion completa de un articulo se compone de:
--   Categoria + Tipo + ProductName + Marca + Clase
-- El campo Linea actua como departamento (ej: REPUESTOS)
-- =============================================

-- ---------- 1. List (paginado con filtros y descripcion compuesta) ----------
DROP FUNCTION IF EXISTS usp_inventario_list(VARCHAR(100), VARCHAR(50), VARCHAR(50), VARCHAR(30), VARCHAR(50), VARCHAR(25), INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_inventario_list(
    p_search     VARCHAR(100) DEFAULT NULL,
    p_categoria  VARCHAR(50)  DEFAULT NULL,
    p_marca      VARCHAR(50)  DEFAULT NULL,
    p_linea      VARCHAR(30)  DEFAULT NULL,
    p_tipo       VARCHAR(50)  DEFAULT NULL,
    p_clase      VARCHAR(25)  DEFAULT NULL,
    p_page       INT DEFAULT 1,
    p_limit      INT DEFAULT 50
)
RETURNS TABLE (
    "TotalCount"          BIGINT,
    "ProductId"           INT,
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
) LANGUAGE plpgsql AS $$
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
    FROM master."Product" pr
    WHERE COALESCE(pr."IsDeleted", FALSE) = FALSE
      AND (v_search IS NULL OR
           pr."ProductCode" LIKE v_search OR pr."Referencia" LIKE v_search OR
           pr."ProductName" LIKE v_search OR pr."Categoria" LIKE v_search OR
           pr."Tipo" LIKE v_search OR pr."Marca" LIKE v_search OR
           pr."Clase" LIKE v_search OR pr."Linea" LIKE v_search)
      AND (p_categoria IS NULL OR TRIM(p_categoria) = '' OR pr."Categoria" = p_categoria)
      AND (p_marca IS NULL OR TRIM(p_marca) = '' OR pr."Marca" = p_marca)
      AND (p_linea IS NULL OR TRIM(p_linea) = '' OR pr."Linea" = p_linea)
      AND (p_tipo IS NULL OR TRIM(p_tipo) = '' OR pr."Tipo" = p_tipo)
      AND (p_clase IS NULL OR TRIM(p_clase) = '' OR pr."Clase" = p_clase);

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
            COALESCE(RTRIM(p."Categoria"),''::VARCHAR) ||
            CASE WHEN RTRIM(COALESCE(p."Tipo",''::VARCHAR)) <> '' THEN ' ' || RTRIM(p."Tipo") ELSE '' END ||
            CASE WHEN RTRIM(COALESCE(p."ProductName",''::VARCHAR)) <> '' THEN ' ' || RTRIM(p."ProductName") ELSE '' END ||
            CASE WHEN RTRIM(COALESCE(p."Marca",''::VARCHAR)) <> '' THEN ' ' || RTRIM(p."Marca") ELSE '' END ||
            CASE WHEN RTRIM(COALESCE(p."Clase",''::VARCHAR)) <> '' THEN ' ' || RTRIM(p."Clase") ELSE '' END
        )                           AS "DescripcionCompleta",
        p."PRECIO_VENTA1",
        p."PRECIO_VENTA2",
        p."PRECIO_VENTA3",
        p."COSTO_PROMEDIO",
        p."Alicuota",
        p."PLU",
        p."UbicaFisica",
        p."Garantia",
        p."Descripcion"
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
$$;

-- ---------- 2. Get by Codigo (incluye DescripcionCompleta) ----------
DROP FUNCTION IF EXISTS usp_inventario_getbycodigo(VARCHAR(15)) CASCADE;
CREATE OR REPLACE FUNCTION usp_inventario_getbycodigo(
    p_codigo VARCHAR(15)
)
RETURNS TABLE (
    "ProductId"           INT,
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
) LANGUAGE plpgsql AS $$
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
            COALESCE(RTRIM(p."Categoria"),''::VARCHAR) ||
            CASE WHEN RTRIM(COALESCE(p."Tipo",''::VARCHAR)) <> '' THEN ' ' || RTRIM(p."Tipo") ELSE '' END ||
            CASE WHEN RTRIM(COALESCE(p."ProductName",''::VARCHAR)) <> '' THEN ' ' || RTRIM(p."ProductName") ELSE '' END ||
            CASE WHEN RTRIM(COALESCE(p."Marca",''::VARCHAR)) <> '' THEN ' ' || RTRIM(p."Marca") ELSE '' END ||
            CASE WHEN RTRIM(COALESCE(p."Clase",''::VARCHAR)) <> '' THEN ' ' || RTRIM(p."Clase") ELSE '' END
        )                      AS "DescripcionCompleta",
        p."PRECIO_VENTA1",
        p."PRECIO_VENTA2",
        p."PRECIO_VENTA3",
        p."COSTO_PROMEDIO",
        p."Alicuota",
        p."PLU",
        p."UbicaFisica",
        p."Garantia",
        p."Descripcion"
    FROM master."Product" p
    WHERE p."ProductCode" = p_codigo
      AND COALESCE(p."IsDeleted", FALSE) = FALSE;
END;
$$;

-- ---------- 3. Insert (columnas principales segun schema canonico) ----------
DROP FUNCTION IF EXISTS usp_inventario_insert(INT, JSONB) CASCADE;
CREATE OR REPLACE FUNCTION usp_inventario_insert(
    p_company_id INT DEFAULT NULL,
    p_row_json JSONB DEFAULT '{}'::JSONB
)
RETURNS TABLE (
    "Resultado" INT,
    "Mensaje"   VARCHAR
) LANGUAGE plpgsql AS $$
DECLARE
    v_company_id INT;
    v_codigo     VARCHAR(15);
BEGIN
    -- Usar CompanyId del parámetro, o buscar el primero activo
    v_company_id := p_company_id;
    IF v_company_id IS NULL THEN
        SELECT "CompanyId" INTO v_company_id
        FROM cfg."Company"
        WHERE COALESCE("IsDeleted", FALSE) = FALSE
        ORDER BY "CompanyId" LIMIT 1;
    END IF;
    IF v_company_id IS NULL THEN v_company_id := 1; END IF;

    v_codigo := NULLIF(p_row_json->>'CODIGO', ''::VARCHAR);

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
            "Servicio", "IsService", "IsActive", "IsDeleted", "CompanyId", "Descripcion"
        ) VALUES (
            v_codigo,
            NULLIF(p_row_json->>'Referencia', ''::VARCHAR),
            NULLIF(p_row_json->>'Categoria', ''::VARCHAR),
            NULLIF(p_row_json->>'Marca', ''::VARCHAR),
            NULLIF(p_row_json->>'Tipo', ''::VARCHAR),
            NULLIF(p_row_json->>'Unidad', ''::VARCHAR),
            NULLIF(p_row_json->>'Clase', ''::VARCHAR),
            NULLIF(p_row_json->>'DESCRIPCION', ''::VARCHAR),
            CASE WHEN NULLIF(p_row_json->>'EXISTENCIA', ''::VARCHAR) IS NULL THEN NULL ELSE (p_row_json->>'EXISTENCIA')::DOUBLE PRECISION END,
            CASE WHEN NULLIF(p_row_json->>'VENTA', ''::VARCHAR) IS NULL THEN NULL ELSE (p_row_json->>'VENTA')::DOUBLE PRECISION END,
            CASE WHEN NULLIF(p_row_json->>'MINIMO', ''::VARCHAR) IS NULL THEN NULL ELSE (p_row_json->>'MINIMO')::DOUBLE PRECISION END,
            CASE WHEN NULLIF(p_row_json->>'MAXIMO', ''::VARCHAR) IS NULL THEN NULL ELSE (p_row_json->>'MAXIMO')::DOUBLE PRECISION END,
            CASE WHEN NULLIF(p_row_json->>'PRECIO_COMPRA', ''::VARCHAR) IS NULL THEN NULL ELSE (p_row_json->>'PRECIO_COMPRA')::DOUBLE PRECISION END,
            CASE WHEN NULLIF(p_row_json->>'PRECIO_VENTA', ''::VARCHAR) IS NULL THEN NULL ELSE (p_row_json->>'PRECIO_VENTA')::DOUBLE PRECISION END,
            CASE WHEN NULLIF(p_row_json->>'PORCENTAJE', ''::VARCHAR) IS NULL THEN NULL ELSE (p_row_json->>'PORCENTAJE')::DOUBLE PRECISION END,
            NULLIF(p_row_json->>'UBICACION', ''::VARCHAR),
            NULLIF(p_row_json->>'Co_Usuario', ''::VARCHAR),
            NULLIF(p_row_json->>'Linea', ''::VARCHAR),
            NULLIF(p_row_json->>'N_PARTE', ''::VARCHAR),
            NULLIF(p_row_json->>'Barra', ''::VARCHAR),
            COALESCE((NULLIF(p_row_json->>'Servicio', ''::VARCHAR))::BOOLEAN, FALSE),
            COALESCE((NULLIF(p_row_json->>'Servicio', ''::VARCHAR))::BOOLEAN, FALSE),
            TRUE,
            FALSE,
            v_company_id,
            NULLIF(p_row_json->>'Descripcion', ''::VARCHAR)
        );

        RETURN QUERY SELECT 1, 'OK'::VARCHAR;
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT -99, SQLERRM::VARCHAR;
    END;
END;
$$;

-- ---------- 4. Update ----------
DROP FUNCTION IF EXISTS usp_inventario_update(INT, VARCHAR(15), JSONB) CASCADE;
CREATE OR REPLACE FUNCTION usp_inventario_update(
    p_company_id INT DEFAULT NULL,
    p_codigo   VARCHAR(15) DEFAULT NULL,
    p_row_json JSONB DEFAULT '{}'::JSONB
)
RETURNS TABLE (
    "Resultado" INT,
    "Mensaje"   VARCHAR
) LANGUAGE plpgsql AS $$
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
            "Referencia" = COALESCE(NULLIF(p_row_json->>'Referencia', ''::VARCHAR), "Referencia"),
            "Categoria"  = COALESCE(NULLIF(p_row_json->>'Categoria', ''::VARCHAR), "Categoria"),
            "Marca"      = COALESCE(NULLIF(p_row_json->>'Marca', ''::VARCHAR), "Marca"),
            "Tipo"       = COALESCE(NULLIF(p_row_json->>'Tipo', ''::VARCHAR), "Tipo"),
            "Unidad"     = COALESCE(NULLIF(p_row_json->>'Unidad', ''::VARCHAR), "Unidad"),
            "Clase"      = COALESCE(NULLIF(p_row_json->>'Clase', ''::VARCHAR), "Clase"),
            "ProductName"= COALESCE(NULLIF(p_row_json->>'DESCRIPCION', ''::VARCHAR), "ProductName"),
            "StockQty"   = CASE WHEN NULLIF(p_row_json->>'EXISTENCIA', ''::VARCHAR) IS NULL THEN "StockQty" ELSE (p_row_json->>'EXISTENCIA')::DOUBLE PRECISION END,
            "VENTA"      = CASE WHEN NULLIF(p_row_json->>'VENTA', ''::VARCHAR) IS NULL THEN "VENTA" ELSE (p_row_json->>'VENTA')::DOUBLE PRECISION END,
            "MINIMO"     = CASE WHEN NULLIF(p_row_json->>'MINIMO', ''::VARCHAR) IS NULL THEN "MINIMO" ELSE (p_row_json->>'MINIMO')::DOUBLE PRECISION END,
            "MAXIMO"     = CASE WHEN NULLIF(p_row_json->>'MAXIMO', ''::VARCHAR) IS NULL THEN "MAXIMO" ELSE (p_row_json->>'MAXIMO')::DOUBLE PRECISION END,
            "CostPrice"  = CASE WHEN NULLIF(p_row_json->>'PRECIO_COMPRA', ''::VARCHAR) IS NULL THEN "CostPrice" ELSE (p_row_json->>'PRECIO_COMPRA')::DOUBLE PRECISION END,
            "SalesPrice" = CASE WHEN NULLIF(p_row_json->>'PRECIO_VENTA', ''::VARCHAR) IS NULL THEN "SalesPrice" ELSE (p_row_json->>'PRECIO_VENTA')::DOUBLE PRECISION END,
            "PORCENTAJE" = CASE WHEN NULLIF(p_row_json->>'PORCENTAJE', ''::VARCHAR) IS NULL THEN "PORCENTAJE" ELSE (p_row_json->>'PORCENTAJE')::DOUBLE PRECISION END,
            "UBICACION"  = COALESCE(NULLIF(p_row_json->>'UBICACION', ''::VARCHAR), "UBICACION"),
            "Co_Usuario" = COALESCE(NULLIF(p_row_json->>'Co_Usuario', ''::VARCHAR), "Co_Usuario"),
            "Linea"      = COALESCE(NULLIF(p_row_json->>'Linea', ''::VARCHAR), "Linea"),
            "N_PARTE"    = COALESCE(NULLIF(p_row_json->>'N_PARTE', ''::VARCHAR), "N_PARTE"),
            "Barra"      = COALESCE(NULLIF(p_row_json->>'Barra', ''::VARCHAR), "Barra"),
            "Descripcion" = COALESCE(NULLIF(p_row_json->>'Descripcion', ''::VARCHAR), "Descripcion")
        WHERE "ProductCode" = p_codigo AND COALESCE("IsDeleted", FALSE) = FALSE;

        RETURN QUERY SELECT 1, 'OK'::VARCHAR;
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT -99, SQLERRM::VARCHAR;
    END;
END;
$$;

-- ---------- 5. Delete (soft delete via IsDeleted) ----------
DROP FUNCTION IF EXISTS usp_inventario_delete(VARCHAR(15)) CASCADE;
CREATE OR REPLACE FUNCTION usp_inventario_delete(
    p_codigo VARCHAR(15)
)
RETURNS TABLE (
    "Resultado" INT,
    "Mensaje"   VARCHAR
) LANGUAGE plpgsql AS $$
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
$$;

-- ---------- 6. Movimiento Insert (ENTRADA/SALIDA/AJUSTE/TRASLADO) ----------
DROP FUNCTION IF EXISTS usp_inventario_movimiento_insert(INT, VARCHAR(80), VARCHAR(20), NUMERIC, NUMERIC, VARCHAR(60), VARCHAR(20), VARCHAR(20), VARCHAR(300), INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_inventario_movimiento_insert(
    p_company_id      INT DEFAULT 1,
    p_product_code    VARCHAR(80) DEFAULT NULL,
    p_movement_type   VARCHAR(20) DEFAULT NULL,
    p_quantity        NUMERIC(18,4) DEFAULT 0,
    p_unit_cost       NUMERIC(18,4) DEFAULT 0,
    p_document_ref    VARCHAR(60) DEFAULT NULL,
    p_warehouse_from  VARCHAR(20) DEFAULT NULL,
    p_warehouse_to    VARCHAR(20) DEFAULT NULL,
    p_notes           VARCHAR(300) DEFAULT NULL,
    p_user_id         INT DEFAULT NULL
)
RETURNS TABLE (
    "Resultado" INT,
    "Mensaje"   VARCHAR
) LANGUAGE plpgsql AS $$
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
                LEFT(REPLACE(gen_random_uuid()::TEXT, '-',''::VARCHAR), 6));

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
$$;

-- ---------- 7. Movimientos List (paginado con filtros) ----------
DROP FUNCTION IF EXISTS usp_inventario_movimiento_list(INT, VARCHAR(100), VARCHAR(80), VARCHAR(20), VARCHAR(20), DATE, DATE, INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_inventario_movimiento_list(
    p_company_id      INT DEFAULT 1,
    p_search          VARCHAR(100) DEFAULT NULL,
    p_product_code    VARCHAR(80) DEFAULT NULL,
    p_movement_type   VARCHAR(20) DEFAULT NULL,
    p_warehouse_code  VARCHAR(20) DEFAULT NULL,
    p_fecha_desde     DATE DEFAULT NULL,
    p_fecha_hasta     DATE DEFAULT NULL,
    p_page            INT DEFAULT 1,
    p_limit           INT DEFAULT 50
)
RETURNS TABLE (
    "TotalCount"       BIGINT,
    "MovementId"       INT,
    "ProductCode"      VARCHAR,
    "ProductName"      VARCHAR,
    "MovementType"     VARCHAR,
    "MovementDate"     DATE,
    "Quantity"         NUMERIC,
    "UnitCost"         NUMERIC,
    "TotalCost"        NUMERIC,
    "DocumentRef"      VARCHAR,
    "WarehouseFrom"    VARCHAR,
    "WarehouseTo"      VARCHAR,
    "Notes"            VARCHAR,
    "CreatedAt"        TIMESTAMP,
    "CreatedByUserId"  INT
) LANGUAGE plpgsql AS $$
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
$$;

-- ---------- 8. Dashboard Inventario (metricas) ----------
DROP FUNCTION IF EXISTS usp_inventario_dashboard(INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_inventario_dashboard(
    p_company_id INT DEFAULT 1
)
RETURNS TABLE (
    "TotalArticulos"   BIGINT,
    "BajoStock"        BIGINT,
    "TotalCategorias"  BIGINT,
    "ValorInventario"  NUMERIC,
    "MovimientosMes"   BIGINT
) LANGUAGE plpgsql AS $$
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
$$;

-- ---------- 9. Libro de Inventario (reporte por rango de fechas) ----------
DROP FUNCTION IF EXISTS usp_inventario_libroinventario(INT, DATE, DATE, VARCHAR(80)) CASCADE;
CREATE OR REPLACE FUNCTION usp_inventario_libroinventario(
    p_company_id   INT DEFAULT 1,
    p_fecha_desde  DATE DEFAULT NULL,
    p_fecha_hasta  DATE DEFAULT NULL,
    p_product_code VARCHAR(80) DEFAULT NULL
)
RETURNS TABLE (
    "CODIGO"              VARCHAR,
    "DESCRIPCION"         VARCHAR,
    "DescripcionCompleta" TEXT,
    "StockInicial"        NUMERIC,
    "Entradas"            NUMERIC,
    "Salidas"             NUMERIC,
    "StockFinal"          NUMERIC,
    "CostoUnitario"       NUMERIC,
    "Unidad"              VARCHAR
) LANGUAGE plpgsql AS $$
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
            COALESCE(RTRIM(p."CategoryCode"),''::VARCHAR) ||
            CASE WHEN RTRIM(COALESCE(p."ProductName",''::VARCHAR)) <> '' THEN ' ' || RTRIM(p."ProductName") ELSE '' END
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
$$;
-- ============================================================
-- FIX: inventario movimientos functions
-- master."InventoryMovement" columns:
--   MovementId, CompanyId, BranchId, ProductCode, ProductName,
--   DocumentRef, MovementType, MovementDate, Quantity, UnitCost,
--   TotalCost, Notes, IsDeleted, CreatedAt, UpdatedAt,
--   CreatedByUserId, UpdatedByUserId
-- Note: NO WarehouseFrom, WarehouseTo columns
-- ============================================================

-- ---------- usp_inventario_movimiento_list ----------
DROP FUNCTION IF EXISTS usp_inventario_movimiento_list(INT, VARCHAR, VARCHAR, VARCHAR, VARCHAR, DATE, DATE, INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_inventario_movimiento_list(
    p_company_id    INT          DEFAULT 1,
    p_search        VARCHAR(100) DEFAULT NULL,
    p_product_code  VARCHAR(80)  DEFAULT NULL,
    p_movement_type VARCHAR(20)  DEFAULT NULL,
    p_warehouse_code VARCHAR(20) DEFAULT NULL,
    p_fecha_desde   DATE         DEFAULT NULL,
    p_fecha_hasta   DATE         DEFAULT NULL,
    p_page          INT          DEFAULT 1,
    p_limit         INT          DEFAULT 50
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
LANGUAGE plpgsql AS $$
DECLARE
    v_offset INT;
    v_limit  INT;
    v_total  BIGINT;
BEGIN
    v_limit  := COALESCE(NULLIF(p_limit, 0), 50);
    IF v_limit < 1  THEN v_limit := 50;  END IF;
    IF v_limit > 500 THEN v_limit := 500; END IF;

    v_offset := (COALESCE(NULLIF(p_page, 0), 1) - 1) * v_limit;
    IF v_offset < 0 THEN v_offset := 0; END IF;

    SELECT COUNT(1) INTO v_total
    FROM master."InventoryMovement" m
    WHERE m."CompanyId" = p_company_id
      AND COALESCE(m."IsDeleted", FALSE) = FALSE
      AND (p_search IS NULL OR m."ProductCode" ILIKE '%' || p_search || '%'
           OR COALESCE(m."ProductName",''::VARCHAR) ILIKE '%' || p_search || '%'
           OR COALESCE(m."DocumentRef",''::VARCHAR) ILIKE '%' || p_search || '%')
      AND (p_product_code IS NULL OR m."ProductCode" = p_product_code)
      AND (p_movement_type IS NULL OR m."MovementType" = p_movement_type)
      AND (p_fecha_desde IS NULL OR m."MovementDate" >= p_fecha_desde)
      AND (p_fecha_hasta IS NULL OR m."MovementDate" <= p_fecha_hasta);

    RETURN QUERY
    SELECT
        v_total,
        m."MovementId",
        m."ProductCode"::VARCHAR,
        COALESCE(m."ProductName",''::VARCHAR)::VARCHAR,
        m."MovementType"::VARCHAR,
        m."MovementDate",
        m."Quantity",
        m."UnitCost",
        m."TotalCost",
        COALESCE(m."DocumentRef",''::VARCHAR)::VARCHAR AS "DocumentRef",
        NULL::VARCHAR                         AS "WarehouseFrom",
        NULL::VARCHAR                         AS "WarehouseTo",
        COALESCE(m."Notes",''::VARCHAR)::VARCHAR       AS "Notes",
        m."CreatedAt",
        m."CreatedByUserId"
    FROM master."InventoryMovement" m
    WHERE m."CompanyId" = p_company_id
      AND COALESCE(m."IsDeleted", FALSE) = FALSE
      AND (p_search IS NULL OR m."ProductCode" ILIKE '%' || p_search || '%'
           OR COALESCE(m."ProductName",''::VARCHAR) ILIKE '%' || p_search || '%'
           OR COALESCE(m."DocumentRef",''::VARCHAR) ILIKE '%' || p_search || '%')
      AND (p_product_code IS NULL OR m."ProductCode" = p_product_code)
      AND (p_movement_type IS NULL OR m."MovementType" = p_movement_type)
      AND (p_fecha_desde IS NULL OR m."MovementDate" >= p_fecha_desde)
      AND (p_fecha_hasta IS NULL OR m."MovementDate" <= p_fecha_hasta)
    ORDER BY m."CreatedAt" DESC
    LIMIT v_limit OFFSET v_offset;
END;
$$;

-- ---------- usp_inventario_movimiento_insert ----------
DROP FUNCTION IF EXISTS usp_inventario_movimiento_insert(INT, VARCHAR, VARCHAR, NUMERIC, NUMERIC, VARCHAR, VARCHAR, VARCHAR, VARCHAR, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_inventario_movimiento_insert(
    p_company_id    INT          DEFAULT 1,
    p_product_code  VARCHAR(80)  DEFAULT NULL,
    p_movement_type VARCHAR(20)  DEFAULT 'ENTRADA',
    p_quantity      NUMERIC      DEFAULT 0,
    p_unit_cost     NUMERIC      DEFAULT 0,
    p_document_ref  VARCHAR(60)  DEFAULT NULL,
    p_warehouse_from VARCHAR(20) DEFAULT NULL,
    p_warehouse_to  VARCHAR(20)  DEFAULT NULL,
    p_notes         VARCHAR(300) DEFAULT NULL,
    p_user_id       INT          DEFAULT NULL
)
RETURNS TABLE(
    "Resultado" INT,
    "Mensaje"   VARCHAR(500)
)
LANGUAGE plpgsql AS $$
DECLARE
    v_product_name VARCHAR(250);
BEGIN
    IF p_product_code IS NULL OR TRIM(p_product_code) = '' THEN
        RETURN QUERY SELECT -1, 'ProductCode requerido'::VARCHAR(500);
        RETURN;
    END IF;

    -- Get product name for denormalization
    SELECT "ProductName" INTO v_product_name
    FROM master."Product"
    WHERE "ProductCode" = p_product_code AND "CompanyId" = p_company_id
    LIMIT 1;

    INSERT INTO master."InventoryMovement" (
        "CompanyId", "ProductCode", "ProductName",
        "MovementType", "Quantity", "UnitCost", "TotalCost",
        "DocumentRef", "Notes", "CreatedByUserId"
    )
    VALUES (
        p_company_id,
        p_product_code,
        COALESCE(v_product_name, p_product_code),
        COALESCE(NULLIF(p_movement_type,''::VARCHAR), 'ENTRADA'),
        COALESCE(p_quantity, 0),
        COALESCE(p_unit_cost, 0),
        COALESCE(p_quantity, 0) * COALESCE(p_unit_cost, 0),
        NULLIF(p_document_ref,''::VARCHAR),
        NULLIF(p_notes,''::VARCHAR),
        p_user_id
    );

    -- Update stock
    IF p_movement_type IN ('ENTRADA', 'AJUSTE_POSITIVO') THEN
        UPDATE master."Product" SET "StockQty" = "StockQty" + p_quantity
        WHERE "ProductCode" = p_product_code AND "CompanyId" = p_company_id;
    ELSIF p_movement_type IN ('SALIDA', 'AJUSTE_NEGATIVO') THEN
        UPDATE master."Product" SET "StockQty" = GREATEST("StockQty" - p_quantity, 0)
        WHERE "ProductCode" = p_product_code AND "CompanyId" = p_company_id;
    END IF;

    RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
END;
$$;
