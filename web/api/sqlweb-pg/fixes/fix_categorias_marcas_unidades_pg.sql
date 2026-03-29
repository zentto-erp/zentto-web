-- ============================================================
-- FIX: Categorias, Marcas, Unidades - Adapted for production schema
-- ============================================================

-- ============= CATEGORIAS =============
-- master."Category": CategoryId, CategoryName, UserCode, IsActive, IsDeleted, CompanyId

DROP FUNCTION IF EXISTS usp_categorias_list(VARCHAR, INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_categorias_list(
    p_search VARCHAR(100) DEFAULT NULL,
    p_page   INT          DEFAULT 1,
    p_limit  INT          DEFAULT 50
)
RETURNS TABLE(
    "TotalCount" BIGINT,
    "Codigo"     INT,
    "Nombre"     VARCHAR,
    "Co_Usuario" VARCHAR
)
LANGUAGE plpgsql AS $$
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
    FROM master."Category" c
    WHERE COALESCE(c."IsDeleted", FALSE) = FALSE
      AND (v_search IS NULL OR c."CategoryName"::TEXT ILIKE v_search);

    RETURN QUERY
    SELECT
        v_total,
        c."CategoryId"::INT        AS "Codigo",
        c."CategoryName"::VARCHAR  AS "Nombre",
        COALESCE(c."UserCode",'')::VARCHAR AS "Co_Usuario"
    FROM master."Category" c
    WHERE COALESCE(c."IsDeleted", FALSE) = FALSE
      AND (v_search IS NULL OR c."CategoryName"::TEXT ILIKE v_search)
    ORDER BY c."CategoryId"
    LIMIT v_limit OFFSET v_offset;
END;
$$;

DROP FUNCTION IF EXISTS usp_categorias_getbycodigo(INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_categorias_getbycodigo(
    p_codigo INT
)
RETURNS TABLE(
    "Codigo"     INT,
    "Nombre"     VARCHAR,
    "Co_Usuario" VARCHAR
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        c."CategoryId"::INT        AS "Codigo",
        c."CategoryName"::VARCHAR  AS "Nombre",
        COALESCE(c."UserCode",'')::VARCHAR AS "Co_Usuario"
    FROM master."Category" c
    WHERE c."CategoryId" = p_codigo
      AND COALESCE(c."IsDeleted", FALSE) = FALSE;
END;
$$;

DROP FUNCTION IF EXISTS usp_categorias_insert(JSONB) CASCADE;
CREATE OR REPLACE FUNCTION usp_categorias_insert(
    p_row_json JSONB
)
RETURNS TABLE(
    "Resultado"   INT,
    "Mensaje"     VARCHAR,
    "NuevoCodigo" INT
)
LANGUAGE plpgsql AS $$
DECLARE
    v_nuevo_codigo INT;
    v_company_id   INT;
BEGIN
    SELECT "CompanyId" INTO v_company_id FROM cfg."Company"
    WHERE COALESCE("IsDeleted", FALSE) = FALSE ORDER BY "CompanyId" LIMIT 1;
    IF v_company_id IS NULL THEN v_company_id := 1; END IF;

    INSERT INTO master."Category" ("CategoryName", "UserCode", "CompanyId", "IsActive", "IsDeleted")
    VALUES (
        NULLIF(COALESCE(p_row_json->>'Nombre', p_row_json->>'CategoryName'), ''),
        NULLIF(p_row_json->>'Co_Usuario', ''),
        v_company_id, TRUE, FALSE
    )
    RETURNING "CategoryId" INTO v_nuevo_codigo;

    RETURN QUERY SELECT 1, 'OK'::VARCHAR, v_nuevo_codigo;
EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, SQLERRM::VARCHAR, 0;
END;
$$;

DROP FUNCTION IF EXISTS usp_categorias_update(INT, JSONB) CASCADE;
CREATE OR REPLACE FUNCTION usp_categorias_update(
    p_codigo   INT,
    p_row_json JSONB
)
RETURNS TABLE("Resultado" INT, "Mensaje" VARCHAR)
LANGUAGE plpgsql AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM master."Category" WHERE "CategoryId" = p_codigo AND COALESCE("IsDeleted",FALSE)=FALSE) THEN
        RETURN QUERY SELECT -1, 'Categoria no encontrada'::VARCHAR; RETURN;
    END IF;
    UPDATE master."Category" SET
        "CategoryName" = COALESCE(NULLIF(COALESCE(p_row_json->>'Nombre', p_row_json->>'CategoryName'),''), "CategoryName"),
        "UserCode"     = COALESCE(NULLIF(p_row_json->>'Co_Usuario',''), "UserCode")
    WHERE "CategoryId" = p_codigo;
    RETURN QUERY SELECT 1, 'OK'::VARCHAR;
EXCEPTION WHEN OTHERS THEN RETURN QUERY SELECT -99, SQLERRM::VARCHAR;
END;
$$;

DROP FUNCTION IF EXISTS usp_categorias_delete(INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_categorias_delete(p_codigo INT)
RETURNS TABLE("Resultado" INT, "Mensaje" VARCHAR)
LANGUAGE plpgsql AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM master."Category" WHERE "CategoryId" = p_codigo AND COALESCE("IsDeleted",FALSE)=FALSE) THEN
        RETURN QUERY SELECT -1, 'Categoria no encontrada'::VARCHAR; RETURN;
    END IF;
    UPDATE master."Category" SET "IsDeleted" = TRUE, "IsActive" = FALSE WHERE "CategoryId" = p_codigo;
    RETURN QUERY SELECT 1, 'OK'::VARCHAR;
EXCEPTION WHEN OTHERS THEN RETURN QUERY SELECT -99, SQLERRM::VARCHAR;
END;
$$;

-- ============= MARCAS =============
-- master."Brand": BrandId, BrandName, UserCode, IsActive, IsDeleted, CompanyId

DROP FUNCTION IF EXISTS usp_marcas_list(VARCHAR, INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_marcas_list(
    p_search VARCHAR(100) DEFAULT NULL,
    p_page   INT          DEFAULT 1,
    p_limit  INT          DEFAULT 50
)
RETURNS TABLE(
    "Codigo"      INT,
    "Descripcion" VARCHAR,
    "TotalCount"  BIGINT
)
LANGUAGE plpgsql AS $$
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
      AND (v_search IS NULL OR b."BrandName"::TEXT ILIKE v_search);

    RETURN QUERY
    SELECT
        b."BrandId"::INT       AS "Codigo",
        b."BrandName"::VARCHAR AS "Descripcion",
        v_total                AS "TotalCount"
    FROM master."Brand" b
    WHERE COALESCE(b."IsDeleted", FALSE) = FALSE
      AND (v_search IS NULL OR b."BrandName"::TEXT ILIKE v_search)
    ORDER BY b."BrandId"
    LIMIT v_limit OFFSET v_offset;
END;
$$;

DROP FUNCTION IF EXISTS usp_marcas_getbycodigo(INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_marcas_getbycodigo(p_codigo INT)
RETURNS TABLE("Codigo" INT, "Descripcion" VARCHAR)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT b."BrandId"::INT, b."BrandName"::VARCHAR
    FROM master."Brand" b
    WHERE b."BrandId" = p_codigo AND COALESCE(b."IsDeleted", FALSE) = FALSE;
END;
$$;

DROP FUNCTION IF EXISTS usp_marcas_insert(JSONB) CASCADE;
CREATE OR REPLACE FUNCTION usp_marcas_insert(p_row_json JSONB)
RETURNS TABLE("Resultado" INT, "Mensaje" VARCHAR(500), "NuevoCodigo" INT)
LANGUAGE plpgsql AS $$
DECLARE
    v_nuevo_codigo INT;
    v_company_id   INT;
BEGIN
    SELECT "CompanyId" INTO v_company_id FROM cfg."Company"
    WHERE COALESCE("IsDeleted", FALSE) = FALSE ORDER BY "CompanyId" LIMIT 1;
    IF v_company_id IS NULL THEN v_company_id := 1; END IF;

    INSERT INTO master."Brand" ("BrandName", "CompanyId", "IsActive", "IsDeleted")
    VALUES (
        NULLIF(COALESCE(p_row_json->>'Descripcion', p_row_json->>'BrandName'), ''),
        v_company_id, TRUE, FALSE
    )
    RETURNING "BrandId" INTO v_nuevo_codigo;
    RETURN QUERY SELECT 1, 'OK'::VARCHAR(500), v_nuevo_codigo;
EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500), 0;
END;
$$;

DROP FUNCTION IF EXISTS usp_marcas_update(INT, JSONB) CASCADE;
CREATE OR REPLACE FUNCTION usp_marcas_update(p_codigo INT, p_row_json JSONB)
RETURNS TABLE("Resultado" INT, "Mensaje" VARCHAR(500))
LANGUAGE plpgsql AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM master."Brand" WHERE "BrandId" = p_codigo AND COALESCE("IsDeleted",FALSE)=FALSE) THEN
        RETURN QUERY SELECT -1, 'Marca no encontrada'::VARCHAR(500); RETURN;
    END IF;
    UPDATE master."Brand" SET
        "BrandName" = COALESCE(NULLIF(COALESCE(p_row_json->>'Descripcion', p_row_json->>'BrandName'),''), "BrandName")
    WHERE "BrandId" = p_codigo;
    RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);
EXCEPTION WHEN OTHERS THEN RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
END;
$$;

DROP FUNCTION IF EXISTS usp_marcas_delete(INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_marcas_delete(p_codigo INT)
RETURNS TABLE("Resultado" INT, "Mensaje" VARCHAR(500))
LANGUAGE plpgsql AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM master."Brand" WHERE "BrandId" = p_codigo AND COALESCE("IsDeleted",FALSE)=FALSE) THEN
        RETURN QUERY SELECT -1, 'Marca no encontrada'::VARCHAR(500); RETURN;
    END IF;
    UPDATE master."Brand" SET "IsDeleted" = TRUE, "IsActive" = FALSE WHERE "BrandId" = p_codigo;
    RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);
EXCEPTION WHEN OTHERS THEN RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
END;
$$;

-- ============= UNIDADES =============
-- master."UnitOfMeasure": UnitId, UnitCode, Description, Symbol, IsActive, IsDeleted, CompanyId
-- Service expects: Id (INT), Unidad, Cantidad

DROP FUNCTION IF EXISTS usp_unidades_list(VARCHAR, INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_unidades_list(
    p_search VARCHAR(100) DEFAULT NULL,
    p_page   INT          DEFAULT 1,
    p_limit  INT          DEFAULT 50
)
RETURNS TABLE(
    "Id"         INT,
    "Unidad"     VARCHAR,
    "Cantidad"   DOUBLE PRECISION,
    "TotalCount" BIGINT
)
LANGUAGE plpgsql AS $$
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
    FROM master."UnitOfMeasure" u
    WHERE COALESCE(u."IsDeleted", FALSE) = FALSE
      AND (v_search IS NULL OR u."UnitCode"::TEXT ILIKE v_search OR u."Description"::TEXT ILIKE v_search);

    RETURN QUERY
    SELECT
        u."UnitId"::INT         AS "Id",
        u."UnitCode"::VARCHAR   AS "Unidad",
        1.0::DOUBLE PRECISION   AS "Cantidad",
        v_total                 AS "TotalCount"
    FROM master."UnitOfMeasure" u
    WHERE COALESCE(u."IsDeleted", FALSE) = FALSE
      AND (v_search IS NULL OR u."UnitCode"::TEXT ILIKE v_search OR u."Description"::TEXT ILIKE v_search)
    ORDER BY u."UnitId"
    LIMIT v_limit OFFSET v_offset;
END;
$$;

DROP FUNCTION IF EXISTS usp_unidades_getbyid(INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_unidades_getbyid(p_id INT)
RETURNS TABLE("Id" INT, "Unidad" VARCHAR, "Cantidad" DOUBLE PRECISION)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT u."UnitId"::INT, u."UnitCode"::VARCHAR, 1.0::DOUBLE PRECISION
    FROM master."UnitOfMeasure" u
    WHERE u."UnitId" = p_id AND COALESCE(u."IsDeleted", FALSE) = FALSE;
END;
$$;

DROP FUNCTION IF EXISTS usp_unidades_insert(JSONB) CASCADE;
CREATE OR REPLACE FUNCTION usp_unidades_insert(p_row_json JSONB)
RETURNS TABLE("Resultado" INT, "Mensaje" VARCHAR(500), "NuevoId" INT)
LANGUAGE plpgsql AS $$
DECLARE
    v_nuevo_id   INT;
    v_company_id INT;
BEGIN
    SELECT "CompanyId" INTO v_company_id FROM cfg."Company"
    WHERE COALESCE("IsDeleted", FALSE) = FALSE ORDER BY "CompanyId" LIMIT 1;
    IF v_company_id IS NULL THEN v_company_id := 1; END IF;

    INSERT INTO master."UnitOfMeasure" ("UnitCode", "Description", "CompanyId", "IsActive", "IsDeleted")
    VALUES (
        NULLIF(COALESCE(p_row_json->>'Unidad', p_row_json->>'UnitCode'), ''),
        COALESCE(NULLIF(p_row_json->>'Descripcion',''), NULLIF(COALESCE(p_row_json->>'Unidad', p_row_json->>'UnitCode'),''), 'SIN DESCRIPCION'),
        v_company_id, TRUE, FALSE
    )
    RETURNING "UnitId" INTO v_nuevo_id;
    RETURN QUERY SELECT 1, 'OK'::VARCHAR(500), v_nuevo_id;
EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500), 0;
END;
$$;

DROP FUNCTION IF EXISTS usp_unidades_update(INT, JSONB) CASCADE;
CREATE OR REPLACE FUNCTION usp_unidades_update(p_id INT, p_row_json JSONB)
RETURNS TABLE("Resultado" INT, "Mensaje" VARCHAR(500))
LANGUAGE plpgsql AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM master."UnitOfMeasure" WHERE "UnitId" = p_id AND COALESCE("IsDeleted",FALSE)=FALSE) THEN
        RETURN QUERY SELECT -1, 'Unidad no encontrada'::VARCHAR(500); RETURN;
    END IF;
    UPDATE master."UnitOfMeasure" SET
        "UnitCode"    = COALESCE(NULLIF(COALESCE(p_row_json->>'Unidad',p_row_json->>'UnitCode'),''), "UnitCode"),
        "Description" = COALESCE(NULLIF(p_row_json->>'Descripcion',''), "Description")
    WHERE "UnitId" = p_id;
    RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);
EXCEPTION WHEN OTHERS THEN RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
END;
$$;

DROP FUNCTION IF EXISTS usp_unidades_delete(INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_unidades_delete(p_id INT)
RETURNS TABLE("Resultado" INT, "Mensaje" VARCHAR(500))
LANGUAGE plpgsql AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM master."UnitOfMeasure" WHERE "UnitId" = p_id AND COALESCE("IsDeleted",FALSE)=FALSE) THEN
        RETURN QUERY SELECT -1, 'Unidad no encontrada'::VARCHAR(500); RETURN;
    END IF;
    UPDATE master."UnitOfMeasure" SET "IsDeleted" = TRUE, "IsActive" = FALSE WHERE "UnitId" = p_id;
    RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);
EXCEPTION WHEN OTHERS THEN RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
END;
$$;
