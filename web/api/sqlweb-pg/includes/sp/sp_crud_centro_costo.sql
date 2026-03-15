-- ============================================================
-- DatqBoxWeb PostgreSQL - sp_crud_centro_costo.sql
-- CRUD de Centro de Costo (public."Centro_Costo")
-- ============================================================

-- ---------- 1. List (paginado con filtros) ----------
CREATE OR REPLACE FUNCTION usp_centrocosto_list(
    p_search VARCHAR(100) DEFAULT NULL,
    p_page   INT          DEFAULT 1,
    p_limit  INT          DEFAULT 50
)
RETURNS TABLE(
    "Codigo"        VARCHAR(50),
    "Descripcion"   VARCHAR(100),
    "Presupuestado" VARCHAR(50),
    "Saldo_Real"    VARCHAR(50),
    "TotalCount"    INT
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
    FROM public."Centro_Costo" cc
    WHERE v_search IS NULL
       OR (cc."Codigo" ILIKE v_search OR cc."Descripcion" ILIKE v_search);

    -- Resultados paginados
    RETURN QUERY
    SELECT
        cc."Codigo",
        cc."Descripcion",
        cc."Presupuestado",
        cc."Saldo_Real",
        v_total AS "TotalCount"
    FROM public."Centro_Costo" cc
    WHERE v_search IS NULL
       OR (cc."Codigo" ILIKE v_search OR cc."Descripcion" ILIKE v_search)
    ORDER BY cc."Codigo"
    LIMIT v_limit OFFSET v_offset;
END;
$$;

-- ---------- 2. Get by Codigo ----------
CREATE OR REPLACE FUNCTION usp_centrocosto_getbycodigo(
    p_codigo VARCHAR(50)
)
RETURNS TABLE(
    "Codigo"        VARCHAR(50),
    "Descripcion"   VARCHAR(100),
    "Presupuestado" VARCHAR(50),
    "Saldo_Real"    VARCHAR(50)
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        cc."Codigo",
        cc."Descripcion",
        cc."Presupuestado",
        cc."Saldo_Real"
    FROM public."Centro_Costo" cc
    WHERE cc."Codigo" = p_codigo;
END;
$$;

-- ---------- 3. Insert ----------
CREATE OR REPLACE FUNCTION usp_centrocosto_insert(
    p_row_json JSONB
)
RETURNS TABLE(
    "Resultado" INT,
    "Mensaje"   VARCHAR(500)
)
LANGUAGE plpgsql AS $$
DECLARE
    v_codigo        VARCHAR(50);
    v_descripcion   VARCHAR(100);
    v_presupuestado VARCHAR(50);
    v_saldo_real    VARCHAR(50);
BEGIN
    v_codigo        := NULLIF(p_row_json->>'Codigo', '');
    v_descripcion   := NULLIF(p_row_json->>'Descripcion', '');
    v_presupuestado := NULLIF(p_row_json->>'Presupuestado', '');
    v_saldo_real    := NULLIF(p_row_json->>'Saldo_Real', '');

    -- Verificar duplicado
    IF EXISTS (SELECT 1 FROM public."Centro_Costo" WHERE "Codigo" = v_codigo) THEN
        RETURN QUERY SELECT -1, 'Centro de costo ya existe'::VARCHAR(500);
        RETURN;
    END IF;

    INSERT INTO public."Centro_Costo" (
        "Codigo", "Descripcion", "Presupuestado", "Saldo_Real"
    )
    VALUES (v_codigo, v_descripcion, v_presupuestado, v_saldo_real);

    RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
END;
$$;

-- ---------- 4. Update ----------
CREATE OR REPLACE FUNCTION usp_centrocosto_update(
    p_codigo   VARCHAR(50),
    p_row_json JSONB
)
RETURNS TABLE(
    "Resultado" INT,
    "Mensaje"   VARCHAR(500)
)
LANGUAGE plpgsql AS $$
DECLARE
    v_descripcion   VARCHAR(100);
    v_presupuestado VARCHAR(50);
    v_saldo_real    VARCHAR(50);
BEGIN
    -- Verificar existencia
    IF NOT EXISTS (SELECT 1 FROM public."Centro_Costo" WHERE "Codigo" = p_codigo) THEN
        RETURN QUERY SELECT -1, 'Centro de costo no encontrado'::VARCHAR(500);
        RETURN;
    END IF;

    v_descripcion   := NULLIF(p_row_json->>'Descripcion', '');
    v_presupuestado := NULLIF(p_row_json->>'Presupuestado', '');
    v_saldo_real    := NULLIF(p_row_json->>'Saldo_Real', '');

    UPDATE public."Centro_Costo" SET
        "Descripcion"   = COALESCE(v_descripcion, "Descripcion"),
        "Presupuestado" = COALESCE(v_presupuestado, "Presupuestado"),
        "Saldo_Real"    = COALESCE(v_saldo_real, "Saldo_Real")
    WHERE "Codigo" = p_codigo;

    RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
END;
$$;

-- ---------- 5. Delete ----------
CREATE OR REPLACE FUNCTION usp_centrocosto_delete(
    p_codigo VARCHAR(50)
)
RETURNS TABLE(
    "Resultado" INT,
    "Mensaje"   VARCHAR(500)
)
LANGUAGE plpgsql AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public."Centro_Costo" WHERE "Codigo" = p_codigo) THEN
        RETURN QUERY SELECT -1, 'Centro de costo no encontrado'::VARCHAR(500);
        RETURN;
    END IF;

    DELETE FROM public."Centro_Costo" WHERE "Codigo" = p_codigo;

    RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
END;
$$;
