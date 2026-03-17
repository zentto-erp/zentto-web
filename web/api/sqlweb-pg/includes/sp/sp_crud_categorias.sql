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
