-- ============================================================
-- DatqBoxWeb PostgreSQL - sp_crud_tipos.sql
-- CRUD de Tipos (Codigo es INT IDENTITY)
-- ============================================================

-- LIST
CREATE OR REPLACE FUNCTION usp_tipos_list(
    p_search VARCHAR(100) DEFAULT NULL,
    p_page INT DEFAULT 1,
    p_limit INT DEFAULT 50
)
RETURNS TABLE(
    "Codigo" INT,
    "Nombre" VARCHAR(50),
    "Categoria" VARCHAR(50),
    "Co_Usuario" VARCHAR(10),
    "TotalCount" BIGINT
)
LANGUAGE plpgsql AS $$
DECLARE
    v_offset INT;
    v_total BIGINT;
BEGIN
    v_offset := (COALESCE(NULLIF(p_page, 0), 1) - 1) * COALESCE(NULLIF(p_limit, 0), 50);
    IF v_offset < 0 THEN v_offset := 0; END IF;
    IF p_limit < 1 THEN p_limit := 50; END IF;
    IF p_limit > 500 THEN p_limit := 500; END IF;

    SELECT COUNT(1) INTO v_total
    FROM public."Tipos"
    WHERE (p_search IS NULL
           OR CAST("Codigo" AS VARCHAR(20)) LIKE '%' || p_search || '%'
           OR "Nombre" LIKE '%' || p_search || '%'
           OR "Categoria" LIKE '%' || p_search || '%');

    RETURN QUERY
    SELECT
        t."Codigo",
        t."Nombre",
        t."Categoria",
        t."Co_Usuario",
        v_total AS "TotalCount"
    FROM public."Tipos" t
    WHERE (p_search IS NULL
           OR CAST(t."Codigo" AS VARCHAR(20)) LIKE '%' || p_search || '%'
           OR t."Nombre" LIKE '%' || p_search || '%'
           OR t."Categoria" LIKE '%' || p_search || '%')
    ORDER BY t."Codigo"
    LIMIT p_limit OFFSET v_offset;
END;
$$;

-- GET BY CODIGO
CREATE OR REPLACE FUNCTION usp_tipos_getbycodigo(
    p_codigo INT
)
RETURNS TABLE(
    "Codigo" INT,
    "Nombre" VARCHAR(50),
    "Categoria" VARCHAR(50),
    "Co_Usuario" VARCHAR(10)
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT t."Codigo", t."Nombre", t."Categoria", t."Co_Usuario"
    FROM public."Tipos" t
    WHERE t."Codigo" = p_codigo;
END;
$$;

-- INSERT
CREATE OR REPLACE FUNCTION usp_tipos_insert(
    p_row_json JSONB
)
RETURNS TABLE(
    "Resultado" INT,
    "Mensaje" VARCHAR(500),
    "NuevoCodigo" INT
)
LANGUAGE plpgsql AS $$
DECLARE
    v_nombre VARCHAR(50);
    v_categoria VARCHAR(50);
    v_co_usuario VARCHAR(10);
    v_nuevo_codigo INT;
BEGIN
    v_nombre     := NULLIF(p_row_json->>'Nombre', ''::VARCHAR);
    v_categoria  := NULLIF(p_row_json->>'Categoria', ''::VARCHAR);
    v_co_usuario := NULLIF(p_row_json->>'Co_Usuario', ''::VARCHAR);

    BEGIN
        INSERT INTO public."Tipos" ("Nombre", "Categoria", "Co_Usuario")
        VALUES (v_nombre, v_categoria, v_co_usuario)
        RETURNING "Codigo" INTO v_nuevo_codigo;

        RETURN QUERY SELECT 1, 'Tipo creado exitosamente'::VARCHAR(500), v_nuevo_codigo;
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT 0, SQLERRM::VARCHAR(500), NULL::INT;
    END;
END;
$$;

-- UPDATE
CREATE OR REPLACE FUNCTION usp_tipos_update(
    p_codigo INT,
    p_row_json JSONB
)
RETURNS TABLE(
    "Resultado" INT,
    "Mensaje" VARCHAR(500)
)
LANGUAGE plpgsql AS $$
DECLARE
    v_nombre VARCHAR(50);
    v_categoria VARCHAR(50);
    v_co_usuario VARCHAR(10);
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public."Tipos" WHERE "Codigo" = p_codigo) THEN
        RETURN QUERY SELECT 0, 'Tipo no encontrado'::VARCHAR(500);
        RETURN;
    END IF;

    v_nombre     := NULLIF(p_row_json->>'Nombre', ''::VARCHAR);
    v_categoria  := NULLIF(p_row_json->>'Categoria', ''::VARCHAR);
    v_co_usuario := NULLIF(p_row_json->>'Co_Usuario', ''::VARCHAR);

    BEGIN
        UPDATE public."Tipos"
        SET "Nombre" = v_nombre,
            "Categoria" = v_categoria,
            "Co_Usuario" = v_co_usuario
        WHERE "Codigo" = p_codigo;

        RETURN QUERY SELECT 1, 'Tipo actualizado exitosamente'::VARCHAR(500);
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT 0, SQLERRM::VARCHAR(500);
    END;
END;
$$;

-- DELETE
CREATE OR REPLACE FUNCTION usp_tipos_delete(
    p_codigo INT
)
RETURNS TABLE(
    "Resultado" INT,
    "Mensaje" VARCHAR(500)
)
LANGUAGE plpgsql AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public."Tipos" WHERE "Codigo" = p_codigo) THEN
        RETURN QUERY SELECT 0, 'Tipo no encontrado'::VARCHAR(500);
        RETURN;
    END IF;

    BEGIN
        DELETE FROM public."Tipos" WHERE "Codigo" = p_codigo;

        RETURN QUERY SELECT 1, 'Tipo eliminado exitosamente'::VARCHAR(500);
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT 0, SQLERRM::VARCHAR(500);
    END;
END;
$$;
