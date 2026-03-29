-- ============================================================
-- DatqBoxWeb PostgreSQL - sp_crud_categorias.sql
-- CRUD de Categorias (master."Category")
-- Canonical schema: CategoryId, CategoryCode, CategoryName, UserCode,
--   Description, IsActive, IsDeleted, CompanyId
-- ============================================================

-- LIST
DROP FUNCTION IF EXISTS usp_categorias_list(VARCHAR, INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_categorias_list(
    p_search VARCHAR(100) DEFAULT NULL,
    p_page   INT          DEFAULT 1,
    p_limit  INT          DEFAULT 50
)
RETURNS TABLE(
    "Codigo"      INT,
    "Nombre"      VARCHAR,
    "Co_Usuario"  VARCHAR,
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
      AND (
        v_search IS NULL
        OR c."CategoryName"::TEXT ILIKE v_search
        OR COALESCE(c."UserCode", ''::VARCHAR)::TEXT ILIKE v_search
        OR COALESCE(c."CategoryCode", ''::VARCHAR)::TEXT ILIKE v_search
      );

    RETURN QUERY
    SELECT
        c."CategoryId"::INT                         AS "Codigo",
        c."CategoryName"::VARCHAR                   AS "Nombre",
        COALESCE(c."UserCode", ''::VARCHAR)::VARCHAR AS "Co_Usuario",
        v_total                                     AS "TotalCount"
    FROM master."Category" c
    WHERE COALESCE(c."IsDeleted", FALSE) = FALSE
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

-- GET BY CODIGO
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
        c."CategoryId"::INT                          AS "Codigo",
        c."CategoryName"::VARCHAR                    AS "Nombre",
        COALESCE(c."UserCode", ''::VARCHAR)::VARCHAR AS "Co_Usuario"
    FROM master."Category" c
    WHERE c."CategoryId" = p_codigo
      AND COALESCE(c."IsDeleted", FALSE) = FALSE;
END;
$$;

-- INSERT
DROP FUNCTION IF EXISTS usp_categorias_insert(JSONB) CASCADE;
CREATE OR REPLACE FUNCTION usp_categorias_insert(
    p_row_json JSONB
)
RETURNS TABLE(
    "Resultado"   INT,
    "Mensaje"     VARCHAR(500),
    "NuevoCodigo" INT
)
LANGUAGE plpgsql AS $$
DECLARE
    v_nuevo_codigo INT;
    v_company_id   INT;
    v_nombre       VARCHAR(100);
    v_user_code    VARCHAR(60);
BEGIN
    SELECT co."CompanyId" INTO v_company_id
    FROM cfg."Company" co
    WHERE COALESCE(co."IsDeleted", FALSE) = FALSE
    ORDER BY co."CompanyId"
    LIMIT 1;

    IF v_company_id IS NULL THEN
        v_company_id := 1;
    END IF;

    v_nombre := NULLIF(TRIM(COALESCE(p_row_json->>'Nombre', p_row_json->>'CategoryName', ''::VARCHAR)), ''::VARCHAR);
    v_user_code := NULLIF(TRIM(COALESCE(p_row_json->>'Co_Usuario', p_row_json->>'UserCode', ''::VARCHAR)), ''::VARCHAR);

    IF v_nombre IS NULL THEN
        RETURN QUERY SELECT -1, 'Nombre requerido'::VARCHAR(500), 0;
        RETURN;
    END IF;

    IF EXISTS (
        SELECT 1
        FROM master."Category"
        WHERE "CompanyId" = v_company_id
          AND COALESCE("IsDeleted", FALSE) = FALSE
          AND UPPER("CategoryName") = UPPER(v_nombre)
    ) THEN
        RETURN QUERY SELECT -1, 'Categoria ya existe'::VARCHAR(500), 0;
        RETURN;
    END IF;

    INSERT INTO master."Category" (
        "CategoryName",
        "UserCode",
        "Description",
        "CompanyId",
        "IsActive",
        "IsDeleted"
    )
    VALUES (
        v_nombre,
        v_user_code,
        v_nombre,
        v_company_id,
        TRUE,
        FALSE
    )
    RETURNING "CategoryId" INTO v_nuevo_codigo;

    RETURN QUERY SELECT 1, 'OK'::VARCHAR(500), v_nuevo_codigo;
EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500), 0;
END;
$$;

-- UPDATE
DROP FUNCTION IF EXISTS usp_categorias_update(INT, JSONB) CASCADE;
CREATE OR REPLACE FUNCTION usp_categorias_update(
    p_codigo   INT,
    p_row_json JSONB
)
RETURNS TABLE(
    "Resultado" INT,
    "Mensaje"   VARCHAR(500)
)
LANGUAGE plpgsql AS $$
DECLARE
    v_nombre VARCHAR(100);
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM master."Category"
        WHERE "CategoryId" = p_codigo
          AND COALESCE("IsDeleted", FALSE) = FALSE
    ) THEN
        RETURN QUERY SELECT -1, 'Categoria no encontrada'::VARCHAR(500);
        RETURN;
    END IF;

    v_nombre := NULLIF(TRIM(COALESCE(p_row_json->>'Nombre', p_row_json->>'CategoryName', ''::VARCHAR)), ''::VARCHAR);

    IF v_nombre IS NOT NULL AND EXISTS (
        SELECT 1
        FROM master."Category"
        WHERE "CategoryId" <> p_codigo
          AND COALESCE("IsDeleted", FALSE) = FALSE
          AND UPPER("CategoryName") = UPPER(v_nombre)
    ) THEN
        RETURN QUERY SELECT -1, 'Categoria ya existe'::VARCHAR(500);
        RETURN;
    END IF;

    UPDATE master."Category"
    SET
        "CategoryName" = COALESCE(v_nombre, "CategoryName"),
        "UserCode" = COALESCE(
            NULLIF(TRIM(COALESCE(p_row_json->>'Co_Usuario', p_row_json->>'UserCode', ''::VARCHAR)), ''::VARCHAR),
            "UserCode"
        ),
        "Description" = COALESCE(v_nombre, "Description"),
        "IsActive" = CASE
            WHEN p_row_json ? 'IsActive' THEN COALESCE((p_row_json->>'IsActive')::BOOLEAN, "IsActive")
            WHEN p_row_json ? 'Activo' THEN COALESCE((p_row_json->>'Activo')::BOOLEAN, "IsActive")
            ELSE "IsActive"
        END
    WHERE "CategoryId" = p_codigo
      AND COALESCE("IsDeleted", FALSE) = FALSE;

    RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);
EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
END;
$$;

-- DELETE
DROP FUNCTION IF EXISTS usp_categorias_delete(INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_categorias_delete(
    p_codigo INT
)
RETURNS TABLE(
    "Resultado" INT,
    "Mensaje"   VARCHAR(500)
)
LANGUAGE plpgsql AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM master."Category"
        WHERE "CategoryId" = p_codigo
          AND COALESCE("IsDeleted", FALSE) = FALSE
    ) THEN
        RETURN QUERY SELECT -1, 'Categoria no encontrada'::VARCHAR(500);
        RETURN;
    END IF;

    UPDATE master."Category"
    SET
        "IsDeleted" = TRUE,
        "IsActive" = FALSE
    WHERE "CategoryId" = p_codigo;

    RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);
EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
END;
$$;
