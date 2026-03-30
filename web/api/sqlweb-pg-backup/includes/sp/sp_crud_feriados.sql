-- ============================================================
-- DatqBoxWeb PostgreSQL - sp_crud_feriados.sql
-- CRUD de Feriados (PK: Fecha date)
-- ============================================================

-- ---------- 1. List (paginado con filtros) ----------
CREATE OR REPLACE FUNCTION usp_feriados_list(
    p_search  VARCHAR(100) DEFAULT NULL,
    p_anio    INT          DEFAULT NULL,
    p_page    INT          DEFAULT 1,
    p_limit   INT          DEFAULT 50
)
RETURNS TABLE(
    "TotalCount"   INT,
    "Fecha"        DATE,
    "Descripcion"  VARCHAR(100)
)
LANGUAGE plpgsql AS $$
DECLARE
    v_offset  INT;
    v_limit   INT;
    v_search  VARCHAR(100);
    v_total   INT;
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

    -- Contar total
    SELECT COUNT(1) INTO v_total
    FROM public."Feriados" f
    WHERE (v_search IS NULL OR f."Descripcion" LIKE v_search)
      AND (p_anio IS NULL OR EXTRACT(YEAR FROM f."Fecha") = p_anio);

    -- Devolver filas
    RETURN QUERY
    SELECT
        v_total,
        f."Fecha"::DATE,
        f."Descripcion"
    FROM public."Feriados" f
    WHERE (v_search IS NULL OR f."Descripcion" LIKE v_search)
      AND (p_anio IS NULL OR EXTRACT(YEAR FROM f."Fecha") = p_anio)
    ORDER BY f."Fecha"
    LIMIT v_limit OFFSET v_offset;
END;
$$;

-- ---------- 2. Get by Fecha ----------
CREATE OR REPLACE FUNCTION usp_feriados_getbyfecha(
    p_fecha DATE
)
RETURNS TABLE(
    "Fecha"        DATE,
    "Descripcion"  VARCHAR(100)
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        f."Fecha"::DATE,
        f."Descripcion"
    FROM public."Feriados" f
    WHERE f."Fecha"::DATE = p_fecha;
END;
$$;

-- ---------- 3. Insert ----------
CREATE OR REPLACE FUNCTION usp_feriados_insert(
    p_row_json JSONB
)
RETURNS TABLE(
    "Resultado" INT,
    "Mensaje"   VARCHAR(500)
)
LANGUAGE plpgsql AS $$
DECLARE
    v_fecha DATE;
BEGIN
    v_fecha := (p_row_json->>'Fecha')::DATE;

    IF EXISTS (
        SELECT 1 FROM public."Feriados"
        WHERE "Fecha"::DATE = v_fecha
    ) THEN
        RETURN QUERY SELECT -1, 'Feriado ya existe para esta fecha'::VARCHAR(500);
        RETURN;
    END IF;

    INSERT INTO public."Feriados" ("Fecha", "Descripcion")
    VALUES (
        v_fecha,
        NULLIF(p_row_json->>'Descripcion', ''::VARCHAR)
    );

    RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
END;
$$;

-- ---------- 4. Update ----------
CREATE OR REPLACE FUNCTION usp_feriados_update(
    p_fecha    DATE,
    p_row_json JSONB
)
RETURNS TABLE(
    "Resultado" INT,
    "Mensaje"   VARCHAR(500)
)
LANGUAGE plpgsql AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public."Feriados" WHERE "Fecha"::DATE = p_fecha) THEN
        RETURN QUERY SELECT -1, 'Feriado no encontrado'::VARCHAR(500);
        RETURN;
    END IF;

    UPDATE public."Feriados" SET
        "Descripcion" = COALESCE(NULLIF(p_row_json->>'Descripcion', ''::VARCHAR), "Descripcion")
    WHERE "Fecha"::DATE = p_fecha;

    RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
END;
$$;

-- ---------- 5. Delete ----------
CREATE OR REPLACE FUNCTION usp_feriados_delete(
    p_fecha DATE
)
RETURNS TABLE(
    "Resultado" INT,
    "Mensaje"   VARCHAR(500)
)
LANGUAGE plpgsql AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public."Feriados" WHERE "Fecha"::DATE = p_fecha) THEN
        RETURN QUERY SELECT -1, 'Feriado no encontrado'::VARCHAR(500);
        RETURN;
    END IF;

    DELETE FROM public."Feriados" WHERE "Fecha"::DATE = p_fecha;

    RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
END;
$$;
