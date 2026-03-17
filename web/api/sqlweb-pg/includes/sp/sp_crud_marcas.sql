-- ============================================================
-- DatqBoxWeb PostgreSQL - sp_crud_marcas.sql
-- CRUD de Marcas (master."Brand")
-- Production schema: BrandId (PK), BrandName, UserCode, IsActive, IsDeleted, CompanyId
-- Service expects: Codigo (INT), Descripcion
-- ============================================================

-- LIST
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

-- GET BY CODIGO
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

-- INSERT
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

-- UPDATE
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

-- DELETE
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
