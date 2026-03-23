-- ============================================================
-- DatqBoxWeb PostgreSQL - sp_crud_moneda.sql
-- CRUD de Moneda (PK: Nombre VARCHAR)
-- ============================================================

-- LIST
CREATE OR REPLACE FUNCTION usp_moneda_list(
    p_search VARCHAR(100) DEFAULT NULL,
    p_page INT DEFAULT 1,
    p_limit INT DEFAULT 50
)
RETURNS TABLE(
    "Nombre" VARCHAR(50),
    "Simbolo" VARCHAR(10),
    "Tasa_Local" DOUBLE PRECISION,
    "Local_Tasa" DOUBLE PRECISION,
    "Local" VARCHAR(10),
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
    FROM public."Moneda" m
    WHERE (v_search_param IS NULL
           OR m."Nombre" LIKE v_search_param
           OR m."Simbolo" LIKE v_search_param);

    RETURN QUERY
    SELECT
        m."Nombre",
        m."Simbolo",
        m."Tasa_Local",
        m."Local_Tasa",
        m."Local",
        v_total AS "TotalCount"
    FROM public."Moneda" m
    WHERE (v_search_param IS NULL
           OR m."Nombre" LIKE v_search_param
           OR m."Simbolo" LIKE v_search_param)
    ORDER BY m."Nombre"
    LIMIT p_limit OFFSET v_offset;
END;
$$;

-- GET BY NOMBRE
CREATE OR REPLACE FUNCTION usp_moneda_getbynombre(
    p_nombre VARCHAR(50)
)
RETURNS TABLE(
    "Nombre" VARCHAR(50),
    "Simbolo" VARCHAR(10),
    "Tasa_Local" DOUBLE PRECISION,
    "Local_Tasa" DOUBLE PRECISION,
    "Local" VARCHAR(10)
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT m."Nombre", m."Simbolo", m."Tasa_Local", m."Local_Tasa", m."Local"
    FROM public."Moneda" m
    WHERE m."Nombre" = p_nombre;
END;
$$;

-- INSERT
CREATE OR REPLACE FUNCTION usp_moneda_insert(
    p_row_json JSONB
)
RETURNS TABLE(
    "Resultado" INT,
    "Mensaje" VARCHAR(500)
)
LANGUAGE plpgsql AS $$
DECLARE
    v_nombre VARCHAR(50);
BEGIN
    v_nombre := NULLIF(p_row_json->>'Nombre', ''::VARCHAR);

    IF EXISTS (SELECT 1 FROM public."Moneda" WHERE "Nombre" = v_nombre) THEN
        RETURN QUERY SELECT -1, 'Moneda ya existe'::VARCHAR(500);
        RETURN;
    END IF;

    BEGIN
        INSERT INTO public."Moneda" ("Nombre", "Simbolo", "Tasa_Local", "Local_Tasa", "Local")
        VALUES (
            v_nombre,
            NULLIF(p_row_json->>'Simbolo', ''::VARCHAR),
            CASE WHEN p_row_json->>'Tasa_Local' IS NULL OR p_row_json->>'Tasa_Local' = '' THEN NULL
                 ELSE (p_row_json->>'Tasa_Local')::DOUBLE PRECISION END,
            CASE WHEN p_row_json->>'Local_Tasa' IS NULL OR p_row_json->>'Local_Tasa' = '' THEN NULL
                 ELSE (p_row_json->>'Local_Tasa')::DOUBLE PRECISION END,
            NULLIF(p_row_json->>'Local', ''::VARCHAR)
        );

        RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
    END;
END;
$$;

-- UPDATE
CREATE OR REPLACE FUNCTION usp_moneda_update(
    p_nombre VARCHAR(50),
    p_row_json JSONB
)
RETURNS TABLE(
    "Resultado" INT,
    "Mensaje" VARCHAR(500)
)
LANGUAGE plpgsql AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public."Moneda" WHERE "Nombre" = p_nombre) THEN
        RETURN QUERY SELECT -1, 'Moneda no encontrada'::VARCHAR(500);
        RETURN;
    END IF;

    BEGIN
        UPDATE public."Moneda"
        SET
            "Simbolo"    = COALESCE(NULLIF(p_row_json->>'Simbolo', ''::VARCHAR), "Simbolo"),
            "Tasa_Local" = CASE WHEN p_row_json->>'Tasa_Local' IS NULL OR p_row_json->>'Tasa_Local' = ''
                                THEN "Tasa_Local"
                                ELSE (p_row_json->>'Tasa_Local')::DOUBLE PRECISION END,
            "Local_Tasa" = CASE WHEN p_row_json->>'Local_Tasa' IS NULL OR p_row_json->>'Local_Tasa' = ''
                                THEN "Local_Tasa"
                                ELSE (p_row_json->>'Local_Tasa')::DOUBLE PRECISION END,
            "Local"      = COALESCE(NULLIF(p_row_json->>'Local', ''::VARCHAR), "Local")
        WHERE "Nombre" = p_nombre;

        RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
    END;
END;
$$;

-- DELETE
CREATE OR REPLACE FUNCTION usp_moneda_delete(
    p_nombre VARCHAR(50)
)
RETURNS TABLE(
    "Resultado" INT,
    "Mensaje" VARCHAR(500)
)
LANGUAGE plpgsql AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public."Moneda" WHERE "Nombre" = p_nombre) THEN
        RETURN QUERY SELECT -1, 'Moneda no encontrada'::VARCHAR(500);
        RETURN;
    END IF;

    BEGIN
        DELETE FROM public."Moneda" WHERE "Nombre" = p_nombre;

        RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
    END;
END;
$$;
