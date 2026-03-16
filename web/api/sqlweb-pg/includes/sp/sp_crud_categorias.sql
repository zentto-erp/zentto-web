-- =============================================
-- Funciones CRUD: Categorias
-- Compatible con: PostgreSQL 14+
-- PK: "Codigo" INT (GENERATED ALWAYS AS IDENTITY)
-- =============================================

-- ---------- 1. List (paginado con filtros) ----------
CREATE OR REPLACE FUNCTION usp_categorias_list(
    p_search     VARCHAR(100) DEFAULT NULL,
    p_page       INT DEFAULT 1,
    p_limit      INT DEFAULT 50
)
RETURNS TABLE (
    "TotalCount" BIGINT,
    "Codigo"     INT,
    "Nombre"     VARCHAR,
    "Co_Usuario" VARCHAR
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

    v_search := NULL;
    IF p_search IS NOT NULL AND TRIM(p_search) <> '' THEN
        v_search := '%' || p_search || '%';
    END IF;

    SELECT COUNT(1) INTO v_total
    FROM public."Categoria"
    WHERE (v_search IS NULL OR
           "Nombre"::TEXT LIKE v_search OR "Codigo"::TEXT LIKE v_search);

    RETURN QUERY
    SELECT
        v_total,
        c."Codigo",
        c."Nombre",
        c."Co_Usuario"
    FROM public."Categoria" c
    WHERE (v_search IS NULL OR
           c."Nombre"::TEXT LIKE v_search OR c."Codigo"::TEXT LIKE v_search)
    ORDER BY c."Codigo"
    LIMIT v_limit OFFSET v_offset;
END;
$$;

-- ---------- 2. Get by Codigo ----------
CREATE OR REPLACE FUNCTION usp_categorias_getbycodigo(
    p_codigo INT
)
RETURNS TABLE (
    "Codigo"     INT,
    "Nombre"     VARCHAR,
    "Co_Usuario" VARCHAR
) LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT c."Codigo", c."Nombre", c."Co_Usuario"
    FROM public."Categoria" c
    WHERE c."Codigo" = p_codigo;
END;
$$;

-- ---------- 3. Insert ----------
CREATE OR REPLACE FUNCTION usp_categorias_insert(
    p_row_json JSONB
)
RETURNS TABLE (
    "Resultado"   INT,
    "Mensaje"     VARCHAR,
    "NuevoCodigo" INT
) LANGUAGE plpgsql AS $$
DECLARE
    v_nuevo_codigo INT;
BEGIN
    BEGIN
        INSERT INTO public."Categoria" ("Nombre", "Co_Usuario")
        VALUES (
            NULLIF(p_row_json->>'Nombre', ''),
            NULLIF(p_row_json->>'Co_Usuario', '')
        )
        RETURNING "Codigo" INTO v_nuevo_codigo;

        RETURN QUERY SELECT 1, 'OK'::VARCHAR, v_nuevo_codigo;
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT -99, SQLERRM::VARCHAR, 0;
    END;
END;
$$;

-- ---------- 4. Update ----------
CREATE OR REPLACE FUNCTION usp_categorias_update(
    p_codigo   INT,
    p_row_json JSONB
)
RETURNS TABLE (
    "Resultado" INT,
    "Mensaje"   VARCHAR
) LANGUAGE plpgsql AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public."Categoria" WHERE "Codigo" = p_codigo) THEN
        RETURN QUERY SELECT -1, 'Categoria no encontrada'::VARCHAR;
        RETURN;
    END IF;

    BEGIN
        UPDATE public."Categoria" SET
            "Nombre"     = COALESCE(NULLIF(p_row_json->>'Nombre', ''), "Nombre"),
            "Co_Usuario" = COALESCE(NULLIF(p_row_json->>'Co_Usuario', ''), "Co_Usuario")
        WHERE "Codigo" = p_codigo;

        RETURN QUERY SELECT 1, 'OK'::VARCHAR;
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT -99, SQLERRM::VARCHAR;
    END;
END;
$$;

-- ---------- 5. Delete ----------
CREATE OR REPLACE FUNCTION usp_categorias_delete(
    p_codigo INT
)
RETURNS TABLE (
    "Resultado" INT,
    "Mensaje"   VARCHAR
) LANGUAGE plpgsql AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public."Categoria" WHERE "Codigo" = p_codigo) THEN
        RETURN QUERY SELECT -1, 'Categoria no encontrada'::VARCHAR;
        RETURN;
    END IF;

    BEGIN
        DELETE FROM public."Categoria" WHERE "Codigo" = p_codigo;
        RETURN QUERY SELECT 1, 'OK'::VARCHAR;
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT -99, SQLERRM::VARCHAR;
    END;
END;
$$;
