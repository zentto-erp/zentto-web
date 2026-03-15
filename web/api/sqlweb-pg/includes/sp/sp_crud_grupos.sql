-- ============================================================
-- DatqBoxWeb PostgreSQL - sp_crud_grupos.sql
-- CRUD de Grupos (PK: Codigo INT identity)
-- ============================================================

-- ---------- 1. List (paginado con filtros) ----------
CREATE OR REPLACE FUNCTION usp_grupos_list(
    p_search  VARCHAR(100) DEFAULT NULL,
    p_page    INT          DEFAULT 1,
    p_limit   INT          DEFAULT 50
)
RETURNS TABLE(
    "TotalCount"    INT,
    "Codigo"        INT,
    "Descripcion"   VARCHAR(50),
    "Co_Usuario"    VARCHAR(10),
    "Porcentaje"    DOUBLE PRECISION
)
LANGUAGE plpgsql AS $$
DECLARE
    v_offset  INT;
    v_total   INT;
BEGIN
    v_offset := (p_page - 1) * p_limit;

    -- Contar total
    SELECT COUNT(1) INTO v_total
    FROM public."Grupos" g
    WHERE (p_search IS NULL
           OR g."Codigo"::VARCHAR(20) LIKE '%' || p_search || '%'
           OR g."Descripcion" LIKE '%' || p_search || '%');

    -- Devolver filas
    RETURN QUERY
    SELECT
        v_total,
        g."Codigo",
        g."Descripcion",
        g."Co_Usuario",
        g."Porcentaje"
    FROM public."Grupos" g
    WHERE (p_search IS NULL
           OR g."Codigo"::VARCHAR(20) LIKE '%' || p_search || '%'
           OR g."Descripcion" LIKE '%' || p_search || '%')
    ORDER BY g."Codigo"
    LIMIT p_limit OFFSET v_offset;
END;
$$;

-- ---------- 2. Get by Codigo ----------
CREATE OR REPLACE FUNCTION usp_grupos_getbycodigo(
    p_codigo INT
)
RETURNS TABLE(
    "Codigo"        INT,
    "Descripcion"   VARCHAR(50),
    "Co_Usuario"    VARCHAR(10),
    "Porcentaje"    DOUBLE PRECISION
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        g."Codigo",
        g."Descripcion",
        g."Co_Usuario",
        g."Porcentaje"
    FROM public."Grupos" g
    WHERE g."Codigo" = p_codigo;
END;
$$;

-- ---------- 3. Insert ----------
CREATE OR REPLACE FUNCTION usp_grupos_insert(
    p_row_json JSONB
)
RETURNS TABLE(
    "Resultado"   INT,
    "Mensaje"     VARCHAR(500),
    "NuevoCodigo" INT
)
LANGUAGE plpgsql AS $$
DECLARE
    v_descripcion  VARCHAR(50);
    v_co_usuario   VARCHAR(10);
    v_porcentaje_str VARCHAR(50);
    v_porcentaje   DOUBLE PRECISION;
    v_nuevo_codigo INT;
BEGIN
    v_descripcion    := NULLIF(p_row_json->>'Descripcion', '');
    v_co_usuario     := NULLIF(p_row_json->>'Co_Usuario', '');
    v_porcentaje_str := NULLIF(p_row_json->>'Porcentaje', '');
    v_porcentaje     := CASE
                            WHEN v_porcentaje_str IS NOT NULL AND v_porcentaje_str ~ '^\d+(\.\d+)?$'
                            THEN v_porcentaje_str::DOUBLE PRECISION
                            ELSE 0
                        END;

    INSERT INTO public."Grupos" ("Descripcion", "Co_Usuario", "Porcentaje")
    VALUES (v_descripcion, v_co_usuario, v_porcentaje)
    RETURNING "Codigo" INTO v_nuevo_codigo;

    RETURN QUERY SELECT 1, 'Grupo creado exitosamente'::VARCHAR(500), v_nuevo_codigo;

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT 0, SQLERRM::VARCHAR(500), NULL::INT;
END;
$$;

-- ---------- 4. Update ----------
CREATE OR REPLACE FUNCTION usp_grupos_update(
    p_codigo   INT,
    p_row_json JSONB
)
RETURNS TABLE(
    "Resultado" INT,
    "Mensaje"   VARCHAR(500)
)
LANGUAGE plpgsql AS $$
DECLARE
    v_descripcion  VARCHAR(50);
    v_co_usuario   VARCHAR(10);
    v_porcentaje_str VARCHAR(50);
    v_porcentaje   DOUBLE PRECISION;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public."Grupos" WHERE "Codigo" = p_codigo) THEN
        RETURN QUERY SELECT 0, 'Grupo no encontrado'::VARCHAR(500);
        RETURN;
    END IF;

    v_descripcion    := NULLIF(p_row_json->>'Descripcion', '');
    v_co_usuario     := NULLIF(p_row_json->>'Co_Usuario', '');
    v_porcentaje_str := NULLIF(p_row_json->>'Porcentaje', '');
    v_porcentaje     := CASE
                            WHEN v_porcentaje_str IS NOT NULL AND v_porcentaje_str ~ '^\d+(\.\d+)?$'
                            THEN v_porcentaje_str::DOUBLE PRECISION
                            ELSE 0
                        END;

    UPDATE public."Grupos" SET
        "Descripcion" = v_descripcion,
        "Co_Usuario"  = v_co_usuario,
        "Porcentaje"  = v_porcentaje
    WHERE "Codigo" = p_codigo;

    RETURN QUERY SELECT 1, 'Grupo actualizado exitosamente'::VARCHAR(500);

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT 0, SQLERRM::VARCHAR(500);
END;
$$;

-- ---------- 5. Delete ----------
CREATE OR REPLACE FUNCTION usp_grupos_delete(
    p_codigo INT
)
RETURNS TABLE(
    "Resultado" INT,
    "Mensaje"   VARCHAR(500)
)
LANGUAGE plpgsql AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public."Grupos" WHERE "Codigo" = p_codigo) THEN
        RETURN QUERY SELECT 0, 'Grupo no encontrado'::VARCHAR(500);
        RETURN;
    END IF;

    DELETE FROM public."Grupos" WHERE "Codigo" = p_codigo;

    RETURN QUERY SELECT 1, 'Grupo eliminado exitosamente'::VARCHAR(500);

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT 0, SQLERRM::VARCHAR(500);
END;
$$;
