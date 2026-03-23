-- ============================================================
-- DatqBoxWeb PostgreSQL - sp_crud_clases.sql
-- CRUD de Clases (public."Clases") - PK: Codigo INT identity
-- ============================================================

-- ---------- 1. List (paginado con filtros) ----------
CREATE OR REPLACE FUNCTION usp_clases_list(
    p_search VARCHAR(100) DEFAULT NULL,
    p_page   INT          DEFAULT 1,
    p_limit  INT          DEFAULT 50
)
RETURNS TABLE(
    "Codigo"      INT,
    "Descripcion" VARCHAR(25),
    "TotalCount"  INT
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
    FROM public."Clases" cl
    WHERE v_search IS NULL
       OR (cl."Codigo"::VARCHAR ILIKE v_search OR cl."Descripcion" ILIKE v_search);

    -- Resultados paginados
    RETURN QUERY
    SELECT
        cl."Codigo",
        cl."Descripcion",
        v_total AS "TotalCount"
    FROM public."Clases" cl
    WHERE v_search IS NULL
       OR (cl."Codigo"::VARCHAR ILIKE v_search OR cl."Descripcion" ILIKE v_search)
    ORDER BY cl."Codigo"
    LIMIT v_limit OFFSET v_offset;
END;
$$;

-- ---------- 2. Get by Codigo ----------
CREATE OR REPLACE FUNCTION usp_clases_getbycodigo(
    p_codigo INT
)
RETURNS TABLE(
    "Codigo"      INT,
    "Descripcion" VARCHAR(25)
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        cl."Codigo",
        cl."Descripcion"
    FROM public."Clases" cl
    WHERE cl."Codigo" = p_codigo;
END;
$$;

-- ---------- 3. Insert ----------
CREATE OR REPLACE FUNCTION usp_clases_insert(
    p_row_json JSONB
)
RETURNS TABLE(
    "Resultado"   INT,
    "Mensaje"     VARCHAR(500),
    "NuevoCodigo" INT
)
LANGUAGE plpgsql AS $$
DECLARE
    v_descripcion VARCHAR(25);
    v_new_id      INT;
BEGIN
    v_descripcion := NULLIF(p_row_json->>'Descripcion', ''::VARCHAR);

    INSERT INTO public."Clases" ("Descripcion")
    VALUES (v_descripcion)
    RETURNING "Codigo" INTO v_new_id;

    RETURN QUERY SELECT 1, 'Clase creada exitosamente'::VARCHAR(500), v_new_id;

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT 0, SQLERRM::VARCHAR(500), NULL::INT;
END;
$$;

-- ---------- 4. Update ----------
CREATE OR REPLACE FUNCTION usp_clases_update(
    p_codigo   INT,
    p_row_json JSONB
)
RETURNS TABLE(
    "Resultado" INT,
    "Mensaje"   VARCHAR(500)
)
LANGUAGE plpgsql AS $$
DECLARE
    v_descripcion VARCHAR(25);
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public."Clases" WHERE "Codigo" = p_codigo) THEN
        RETURN QUERY SELECT 0, 'Clase no encontrada'::VARCHAR(500);
        RETURN;
    END IF;

    v_descripcion := NULLIF(p_row_json->>'Descripcion', ''::VARCHAR);

    UPDATE public."Clases"
    SET "Descripcion" = v_descripcion
    WHERE "Codigo" = p_codigo;

    RETURN QUERY SELECT 1, 'Clase actualizada exitosamente'::VARCHAR(500);

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT 0, SQLERRM::VARCHAR(500);
END;
$$;

-- ---------- 5. Delete ----------
CREATE OR REPLACE FUNCTION usp_clases_delete(
    p_codigo INT
)
RETURNS TABLE(
    "Resultado" INT,
    "Mensaje"   VARCHAR(500)
)
LANGUAGE plpgsql AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public."Clases" WHERE "Codigo" = p_codigo) THEN
        RETURN QUERY SELECT 0, 'Clase no encontrada'::VARCHAR(500);
        RETURN;
    END IF;

    DELETE FROM public."Clases" WHERE "Codigo" = p_codigo;

    RETURN QUERY SELECT 1, 'Clase eliminada exitosamente'::VARCHAR(500);

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT 0, SQLERRM::VARCHAR(500);
END;
$$;
