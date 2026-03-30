-- ============================================================
-- DatqBoxWeb PostgreSQL - sp_crud_almacen.sql
-- CRUD de Almacenes (master."Warehouse")
-- ============================================================

-- ---------- 1. List (paginado con filtros) ----------
DROP FUNCTION IF EXISTS usp_almacen_list(VARCHAR(100), VARCHAR(50), INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_almacen_list(
    p_search   VARCHAR(100) DEFAULT NULL,
    p_tipo     VARCHAR(50)  DEFAULT NULL,
    p_page     INT          DEFAULT 1,
    p_limit    INT          DEFAULT 50
)
RETURNS TABLE(
    "Codigo"        VARCHAR(10),
    "Descripcion"   VARCHAR(100),
    "Tipo"          VARCHAR(50),
    "IsActive"      BOOLEAN,
    "IsDeleted"     BOOLEAN,
    "CompanyId"     INT,
    "WarehouseCode" VARCHAR(10),
    "Description"   VARCHAR(100),
    "WarehouseType" VARCHAR(50),
    "TotalCount"    INT
)
LANGUAGE plpgsql AS $$
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
$$;

-- ---------- 2. Get by Codigo ----------
DROP FUNCTION IF EXISTS usp_almacen_getbycodigo(VARCHAR(10)) CASCADE;
CREATE OR REPLACE FUNCTION usp_almacen_getbycodigo(
    p_codigo VARCHAR(10)
)
RETURNS TABLE(
    "Codigo"        VARCHAR(10),
    "Descripcion"   VARCHAR(100),
    "Tipo"          VARCHAR(50),
    "IsActive"      BOOLEAN,
    "IsDeleted"     BOOLEAN,
    "CompanyId"     INT,
    "WarehouseCode" VARCHAR(10),
    "Description"   VARCHAR(100),
    "WarehouseType" VARCHAR(50)
)
LANGUAGE plpgsql AS $$
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
$$;

-- ---------- 3. Insert ----------
DROP FUNCTION IF EXISTS usp_almacen_insert(JSONB) CASCADE;
CREATE OR REPLACE FUNCTION usp_almacen_insert(
    p_row_json JSONB
)
RETURNS TABLE(
    "Resultado" INT,
    "Mensaje"   VARCHAR(500)
)
LANGUAGE plpgsql AS $$
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

    v_codigo := NULLIF(p_row_json->>'Codigo', ''::VARCHAR);
    v_desc   := NULLIF(p_row_json->>'Descripcion', ''::VARCHAR);
    v_tipo   := NULLIF(p_row_json->>'Tipo', ''::VARCHAR);

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
$$;

-- ---------- 4. Update ----------
DROP FUNCTION IF EXISTS usp_almacen_update(VARCHAR(10), JSONB) CASCADE;
CREATE OR REPLACE FUNCTION usp_almacen_update(
    p_codigo   VARCHAR(10),
    p_row_json JSONB
)
RETURNS TABLE(
    "Resultado" INT,
    "Mensaje"   VARCHAR(500)
)
LANGUAGE plpgsql AS $$
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

    v_desc := NULLIF(p_row_json->>'Descripcion', ''::VARCHAR);
    v_tipo := NULLIF(p_row_json->>'Tipo', ''::VARCHAR);

    UPDATE master."Warehouse" SET
        "Description"   = COALESCE(v_desc, "Description"),
        "WarehouseType" = COALESCE(v_tipo, "WarehouseType")
    WHERE "WarehouseCode" = p_codigo
      AND COALESCE("IsDeleted", FALSE) = FALSE;

    RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
END;
$$;

-- ---------- 5. Delete (soft delete via IsDeleted) ----------
DROP FUNCTION IF EXISTS usp_almacen_delete(VARCHAR(10)) CASCADE;
CREATE OR REPLACE FUNCTION usp_almacen_delete(
    p_codigo VARCHAR(10)
)
RETURNS TABLE(
    "Resultado" INT,
    "Mensaje"   VARCHAR(500)
)
LANGUAGE plpgsql AS $$
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
$$;
