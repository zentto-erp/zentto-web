-- ============================================================
-- DatqBoxWeb PostgreSQL - sp_crud_tipos.sql
-- CRUD de Tipos (usa master."ProductType")
-- ============================================================

-- LIST
CREATE OR REPLACE FUNCTION usp_tipos_list(
    p_company_id INT          DEFAULT 1,
    p_search     VARCHAR(100) DEFAULT NULL,
    p_categoria  VARCHAR(50)  DEFAULT NULL,
    p_page       INT          DEFAULT 1,
    p_limit      INT          DEFAULT 50
)
RETURNS TABLE(
    "Codigo"     INT,
    "Nombre"     VARCHAR(100),
    "Categoria"  VARCHAR(50),
    "Co_Usuario" VARCHAR(10),
    "TotalCount" BIGINT
)
LANGUAGE plpgsql AS $$
DECLARE
    v_offset INT;
    v_total  BIGINT;
BEGIN
    v_offset := (COALESCE(NULLIF(p_page, 0), 1) - 1) * COALESCE(NULLIF(p_limit, 0), 50);
    IF v_offset < 0  THEN v_offset := 0;   END IF;
    IF p_limit  < 1  THEN p_limit  := 50;  END IF;
    IF p_limit  > 500 THEN p_limit := 500; END IF;

    SELECT COUNT(1) INTO v_total
    FROM master."ProductType" tc
    WHERE tc."IsDeleted" = FALSE
      AND tc."CompanyId" = p_company_id
      AND (p_search IS NULL
           OR CAST(tc."TypeId" AS VARCHAR(20)) LIKE '%' || p_search || '%'
           OR tc."TypeName" ILIKE '%' || p_search || '%'
           OR tc."TypeCode" ILIKE '%' || p_search || '%')
      AND (p_categoria IS NULL OR tc."CategoryCode" = p_categoria);

    RETURN QUERY
    SELECT
        t."TypeId",
        t."TypeName",
        t."CategoryCode"::VARCHAR(50),
        NULL::VARCHAR(10)  AS "Co_Usuario",
        v_total            AS "TotalCount"
    FROM master."ProductType" t
    WHERE t."IsDeleted" = FALSE
      AND t."CompanyId" = p_company_id
      AND (p_search IS NULL
           OR CAST(t."TypeId" AS VARCHAR(20)) LIKE '%' || p_search || '%'
           OR t."TypeName" ILIKE '%' || p_search || '%'
           OR t."TypeCode" ILIKE '%' || p_search || '%')
      AND (p_categoria IS NULL OR t."CategoryCode" = p_categoria)
    ORDER BY t."TypeId"
    LIMIT p_limit OFFSET v_offset;
END;
$$;

-- GET BY CODIGO
DROP FUNCTION IF EXISTS usp_tipos_getbycodigo(INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_tipos_getbycodigo(
    p_codigo INT
)
RETURNS TABLE(
    "Codigo"     INT,
    "Nombre"     VARCHAR(100),
    "Categoria"  VARCHAR(50),
    "Co_Usuario" VARCHAR(10)
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT t."TypeId", t."TypeName", t."CategoryCode"::VARCHAR(50), NULL::VARCHAR(10)
    FROM master."ProductType" t
    WHERE t."TypeId" = p_codigo AND t."IsDeleted" = FALSE;
END;
$$;

-- INSERT
CREATE OR REPLACE FUNCTION usp_tipos_insert(
    p_row_json JSONB
)
RETURNS TABLE(
    "Resultado"  INT,
    "Mensaje"    VARCHAR(500),
    "NuevoCodigo" INT
)
LANGUAGE plpgsql AS $$
DECLARE
    v_nombre     VARCHAR(100);
    v_categoria  VARCHAR(50);
    v_company_id INT;
    v_nuevo_codigo INT;
BEGIN
    v_nombre     := NULLIF(p_row_json->>'Nombre', '');
    v_categoria  := NULLIF(p_row_json->>'Categoria', '');
    v_company_id := COALESCE((p_row_json->>'CompanyId')::INT, 1);

    BEGIN
        INSERT INTO master."ProductType" ("CompanyId", "TypeCode", "TypeName", "CategoryCode")
        VALUES (
            v_company_id,
            COALESCE(LEFT(UPPER(REPLACE(v_nombre, ' ', '-')), 20), 'TIP-NEW'),
            v_nombre,
            v_categoria
        )
        RETURNING "TypeId" INTO v_nuevo_codigo;

        RETURN QUERY SELECT 1, 'Tipo creado exitosamente'::VARCHAR(500), v_nuevo_codigo;
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT 0, SQLERRM::VARCHAR(500), NULL::INT;
    END;
END;
$$;

-- UPDATE
CREATE OR REPLACE FUNCTION usp_tipos_update(
    p_codigo   INT,
    p_row_json JSONB
)
RETURNS TABLE(
    "Resultado" INT,
    "Mensaje"   VARCHAR(500)
)
LANGUAGE plpgsql AS $$
DECLARE
    v_nombre    VARCHAR(100);
    v_categoria VARCHAR(50);
BEGIN
    IF NOT EXISTS (SELECT 1 FROM master."ProductType" WHERE "TypeId" = p_codigo AND "IsDeleted" = FALSE) THEN
        RETURN QUERY SELECT 0, 'Tipo no encontrado'::VARCHAR(500);
        RETURN;
    END IF;

    v_nombre    := NULLIF(p_row_json->>'Nombre', '');
    v_categoria := NULLIF(p_row_json->>'Categoria', '');

    BEGIN
        UPDATE master."ProductType"
        SET "TypeName"     = COALESCE(v_nombre, "TypeName"),
            "CategoryCode" = v_categoria,
            "UpdatedAt"    = NOW() AT TIME ZONE 'UTC'
        WHERE "TypeId" = p_codigo;

        RETURN QUERY SELECT 1, 'Tipo actualizado exitosamente'::VARCHAR(500);
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT 0, SQLERRM::VARCHAR(500);
    END;
END;
$$;

-- DELETE (soft delete)
CREATE OR REPLACE FUNCTION usp_tipos_delete(
    p_codigo INT
)
RETURNS TABLE(
    "Resultado" INT,
    "Mensaje"   VARCHAR(500)
)
LANGUAGE plpgsql AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM master."ProductType" WHERE "TypeId" = p_codigo AND "IsDeleted" = FALSE) THEN
        RETURN QUERY SELECT 0, 'Tipo no encontrado'::VARCHAR(500);
        RETURN;
    END IF;

    BEGIN
        UPDATE master."ProductType"
        SET "IsDeleted" = TRUE,
            "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
        WHERE "TypeId" = p_codigo;

        RETURN QUERY SELECT 1, 'Tipo eliminado exitosamente'::VARCHAR(500);
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT 0, SQLERRM::VARCHAR(500);
    END;
END;
$$;
