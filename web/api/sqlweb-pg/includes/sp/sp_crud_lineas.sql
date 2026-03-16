-- ============================================================
-- DatqBoxWeb PostgreSQL - sp_crud_lineas.sql
-- CRUD de Lineas (CODIGO es INT IDENTITY)
-- ============================================================

-- LIST
CREATE OR REPLACE FUNCTION usp_lineas_list(
    p_search VARCHAR(100) DEFAULT NULL,
    p_page INT DEFAULT 1,
    p_limit INT DEFAULT 50
)
RETURNS TABLE(
    "CODIGO" INT,
    "DESCRIPCION" VARCHAR(50),
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
    FROM public."Lineas"
    WHERE (p_search IS NULL
           OR CAST("CODIGO" AS VARCHAR(20)) LIKE '%' || p_search || '%'
           OR "DESCRIPCION" LIKE '%' || p_search || '%');

    RETURN QUERY
    SELECT
        l."CODIGO",
        l."DESCRIPCION",
        v_total AS "TotalCount"
    FROM public."Lineas" l
    WHERE (p_search IS NULL
           OR CAST(l."CODIGO" AS VARCHAR(20)) LIKE '%' || p_search || '%'
           OR l."DESCRIPCION" LIKE '%' || p_search || '%')
    ORDER BY l."CODIGO"
    LIMIT p_limit OFFSET v_offset;
END;
$$;

-- GET BY CODIGO
CREATE OR REPLACE FUNCTION usp_lineas_getbycodigo(
    p_codigo INT
)
RETURNS TABLE(
    "CODIGO" INT,
    "DESCRIPCION" VARCHAR(50)
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT l."CODIGO", l."DESCRIPCION"
    FROM public."Lineas" l
    WHERE l."CODIGO" = p_codigo;
END;
$$;

-- INSERT
CREATE OR REPLACE FUNCTION usp_lineas_insert(
    p_row_json JSONB
)
RETURNS TABLE(
    "Resultado" INT,
    "Mensaje" VARCHAR(500),
    "NuevoCodigo" INT
)
LANGUAGE plpgsql AS $$
DECLARE
    v_descripcion VARCHAR(50);
    v_nuevo_codigo INT;
BEGIN
    v_descripcion := NULLIF(p_row_json->>'DESCRIPCION', '');

    BEGIN
        INSERT INTO public."Lineas" ("DESCRIPCION")
        VALUES (v_descripcion)
        RETURNING "CODIGO" INTO v_nuevo_codigo;

        RETURN QUERY SELECT 1, 'Linea creada exitosamente'::VARCHAR(500), v_nuevo_codigo;
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT 0, SQLERRM::VARCHAR(500), NULL::INT;
    END;
END;
$$;

-- UPDATE
CREATE OR REPLACE FUNCTION usp_lineas_update(
    p_codigo INT,
    p_row_json JSONB
)
RETURNS TABLE(
    "Resultado" INT,
    "Mensaje" VARCHAR(500)
)
LANGUAGE plpgsql AS $$
DECLARE
    v_descripcion VARCHAR(50);
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public."Lineas" WHERE "CODIGO" = p_codigo) THEN
        RETURN QUERY SELECT 0, 'Linea no encontrada'::VARCHAR(500);
        RETURN;
    END IF;

    v_descripcion := NULLIF(p_row_json->>'DESCRIPCION', '');

    BEGIN
        UPDATE public."Lineas"
        SET "DESCRIPCION" = v_descripcion
        WHERE "CODIGO" = p_codigo;

        RETURN QUERY SELECT 1, 'Linea actualizada exitosamente'::VARCHAR(500);
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT 0, SQLERRM::VARCHAR(500);
    END;
END;
$$;

-- DELETE
CREATE OR REPLACE FUNCTION usp_lineas_delete(
    p_codigo INT
)
RETURNS TABLE(
    "Resultado" INT,
    "Mensaje" VARCHAR(500)
)
LANGUAGE plpgsql AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public."Lineas" WHERE "CODIGO" = p_codigo) THEN
        RETURN QUERY SELECT 0, 'Linea no encontrada'::VARCHAR(500);
        RETURN;
    END IF;

    BEGIN
        DELETE FROM public."Lineas" WHERE "CODIGO" = p_codigo;

        RETURN QUERY SELECT 1, 'Linea eliminada exitosamente'::VARCHAR(500);
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT 0, SQLERRM::VARCHAR(500);
    END;
END;
$$;
