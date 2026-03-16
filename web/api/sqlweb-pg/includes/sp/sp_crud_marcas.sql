-- ============================================================
-- DatqBoxWeb PostgreSQL - sp_crud_marcas.sql
-- CRUD de Marcas (PK: Codigo INT IDENTITY)
-- ============================================================

-- LIST
CREATE OR REPLACE FUNCTION usp_marcas_list(
    p_search VARCHAR(100) DEFAULT NULL,
    p_page INT DEFAULT 1,
    p_limit INT DEFAULT 50
)
RETURNS TABLE(
    "Codigo" INT,
    "Descripcion" VARCHAR(100),
    "TotalCount" BIGINT
)
LANGUAGE plpgsql AS $$
DECLARE
    v_offset INT;
    v_total BIGINT;
    v_search_param VARCHAR(100);
BEGIN
    v_offset := (COALESCE(NULLIF(p_page, 0), 1) - 1) * COALESCE(NULLIF(p_limit, 0), 50);
    IF v_offset < 0 THEN v_offset := 0; END IF;
    IF p_limit < 1 THEN p_limit := 50; END IF;
    IF p_limit > 500 THEN p_limit := 500; END IF;

    v_search_param := NULL;
    IF p_search IS NOT NULL AND TRIM(p_search) <> '' THEN
        v_search_param := '%' || p_search || '%';
    END IF;

    SELECT COUNT(1) INTO v_total
    FROM public."Marcas" m
    WHERE (v_search_param IS NULL OR m."Descripcion" LIKE v_search_param);

    RETURN QUERY
    SELECT
        m."Codigo",
        m."Descripcion",
        v_total AS "TotalCount"
    FROM public."Marcas" m
    WHERE (v_search_param IS NULL OR m."Descripcion" LIKE v_search_param)
    ORDER BY m."Codigo"
    LIMIT p_limit OFFSET v_offset;
END;
$$;

-- GET BY CODIGO
CREATE OR REPLACE FUNCTION usp_marcas_getbycodigo(
    p_codigo INT
)
RETURNS TABLE(
    "Codigo" INT,
    "Descripcion" VARCHAR(100)
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT m."Codigo", m."Descripcion"
    FROM public."Marcas" m
    WHERE m."Codigo" = p_codigo;
END;
$$;

-- INSERT
CREATE OR REPLACE FUNCTION usp_marcas_insert(
    p_row_json JSONB
)
RETURNS TABLE(
    "Resultado" INT,
    "Mensaje" VARCHAR(500),
    "NuevoCodigo" INT
)
LANGUAGE plpgsql AS $$
DECLARE
    v_nuevo_codigo INT;
BEGIN
    BEGIN
        INSERT INTO public."Marcas" ("Descripcion")
        VALUES (NULLIF(p_row_json->>'Descripcion', ''))
        RETURNING "Codigo" INTO v_nuevo_codigo;

        RETURN QUERY SELECT 1, 'OK'::VARCHAR(500), v_nuevo_codigo;
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500), 0;
    END;
END;
$$;

-- UPDATE
CREATE OR REPLACE FUNCTION usp_marcas_update(
    p_codigo INT,
    p_row_json JSONB
)
RETURNS TABLE(
    "Resultado" INT,
    "Mensaje" VARCHAR(500)
)
LANGUAGE plpgsql AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public."Marcas" WHERE "Codigo" = p_codigo) THEN
        RETURN QUERY SELECT -1, 'Marca no encontrada'::VARCHAR(500);
        RETURN;
    END IF;

    BEGIN
        UPDATE public."Marcas"
        SET "Descripcion" = COALESCE(NULLIF(p_row_json->>'Descripcion', ''), "Descripcion")
        WHERE "Codigo" = p_codigo;

        RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
    END;
END;
$$;

-- DELETE
CREATE OR REPLACE FUNCTION usp_marcas_delete(
    p_codigo INT
)
RETURNS TABLE(
    "Resultado" INT,
    "Mensaje" VARCHAR(500)
)
LANGUAGE plpgsql AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public."Marcas" WHERE "Codigo" = p_codigo) THEN
        RETURN QUERY SELECT -1, 'Marca no encontrada'::VARCHAR(500);
        RETURN;
    END IF;

    BEGIN
        DELETE FROM public."Marcas" WHERE "Codigo" = p_codigo;

        RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
    END;
END;
$$;
