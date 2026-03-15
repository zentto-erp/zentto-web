-- ============================================================
-- DatqBoxWeb PostgreSQL - sp_crud_unidades.sql
-- CRUD de Unidades (PK: Id INT IDENTITY)
-- ============================================================

-- LIST
CREATE OR REPLACE FUNCTION usp_unidades_list(
    p_search VARCHAR(100) DEFAULT NULL,
    p_page INT DEFAULT 1,
    p_limit INT DEFAULT 50
)
RETURNS TABLE(
    "Id" INT,
    "Unidad" VARCHAR(50),
    "Cantidad" DOUBLE PRECISION,
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
    FROM public."Unidades" u
    WHERE (v_search_param IS NULL OR u."Unidad" LIKE v_search_param);

    RETURN QUERY
    SELECT
        u."Id",
        u."Unidad",
        u."Cantidad",
        v_total AS "TotalCount"
    FROM public."Unidades" u
    WHERE (v_search_param IS NULL OR u."Unidad" LIKE v_search_param)
    ORDER BY u."Id"
    LIMIT p_limit OFFSET v_offset;
END;
$$;

-- GET BY ID
CREATE OR REPLACE FUNCTION usp_unidades_getbyid(
    p_id INT
)
RETURNS TABLE(
    "Id" INT,
    "Unidad" VARCHAR(50),
    "Cantidad" DOUBLE PRECISION
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT u."Id", u."Unidad", u."Cantidad"
    FROM public."Unidades" u
    WHERE u."Id" = p_id;
END;
$$;

-- INSERT
CREATE OR REPLACE FUNCTION usp_unidades_insert(
    p_row_json JSONB
)
RETURNS TABLE(
    "Resultado" INT,
    "Mensaje" VARCHAR(500),
    "NuevoId" INT
)
LANGUAGE plpgsql AS $$
DECLARE
    v_nuevo_id INT;
BEGIN
    BEGIN
        INSERT INTO public."Unidades" ("Unidad", "Cantidad")
        VALUES (
            NULLIF(p_row_json->>'Unidad', ''),
            CASE WHEN p_row_json->>'Cantidad' IS NULL OR p_row_json->>'Cantidad' = '' THEN NULL
                 ELSE (p_row_json->>'Cantidad')::DOUBLE PRECISION END
        )
        RETURNING "Id" INTO v_nuevo_id;

        RETURN QUERY SELECT 1, 'OK'::VARCHAR(500), v_nuevo_id;
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500), 0;
    END;
END;
$$;

-- UPDATE
CREATE OR REPLACE FUNCTION usp_unidades_update(
    p_id INT,
    p_row_json JSONB
)
RETURNS TABLE(
    "Resultado" INT,
    "Mensaje" VARCHAR(500)
)
LANGUAGE plpgsql AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public."Unidades" WHERE "Id" = p_id) THEN
        RETURN QUERY SELECT -1, 'Unidad no encontrada'::VARCHAR(500);
        RETURN;
    END IF;

    BEGIN
        UPDATE public."Unidades"
        SET
            "Unidad"   = COALESCE(NULLIF(p_row_json->>'Unidad', ''), "Unidad"),
            "Cantidad" = CASE WHEN p_row_json->>'Cantidad' IS NULL OR p_row_json->>'Cantidad' = ''
                              THEN "Cantidad"
                              ELSE (p_row_json->>'Cantidad')::DOUBLE PRECISION END
        WHERE "Id" = p_id;

        RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
    END;
END;
$$;

-- DELETE
CREATE OR REPLACE FUNCTION usp_unidades_delete(
    p_id INT
)
RETURNS TABLE(
    "Resultado" INT,
    "Mensaje" VARCHAR(500)
)
LANGUAGE plpgsql AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public."Unidades" WHERE "Id" = p_id) THEN
        RETURN QUERY SELECT -1, 'Unidad no encontrada'::VARCHAR(500);
        RETURN;
    END IF;

    BEGIN
        DELETE FROM public."Unidades" WHERE "Id" = p_id;

        RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
    END;
END;
$$;
