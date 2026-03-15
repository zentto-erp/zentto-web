-- ============================================================
-- DatqBoxWeb PostgreSQL - sp_crud_cuentas.sql
-- CRUD de Cuentas contables (PK: COD_CUENTA varchar)
-- ============================================================

-- ---------- 1. List (paginado con filtros) ----------
CREATE OR REPLACE FUNCTION usp_cuentas_list(
    p_search   VARCHAR(100) DEFAULT NULL,
    p_tipo     VARCHAR(50)  DEFAULT NULL,
    p_grupo    VARCHAR(50)  DEFAULT NULL,
    p_page     INT          DEFAULT 1,
    p_limit    INT          DEFAULT 50
)
RETURNS TABLE(
    "TotalCount"   INT,
    "COD_CUENTA"   VARCHAR(50),
    "DESCRIPCION"  VARCHAR(100),
    "TIPO"         VARCHAR(50),
    "PRESUPUESTO"  INT,
    "SALDO"        INT,
    "COD_USUARIO"  VARCHAR(10),
    "grupo"        VARCHAR(50),
    "LINEA"        VARCHAR(50),
    "USO"          VARCHAR(50),
    "Nivel"        INT,
    "Porcentaje"   DOUBLE PRECISION
)
LANGUAGE plpgsql AS $$
DECLARE
    v_offset   INT;
    v_limit    INT;
    v_search   VARCHAR(100);
    v_total    INT;
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
    FROM public."Cuentas" c
    WHERE (v_search IS NULL OR c."COD_CUENTA" LIKE v_search OR c."DESCRIPCION" LIKE v_search)
      AND (p_tipo IS NULL OR TRIM(p_tipo) = '' OR c."TIPO" = p_tipo)
      AND (p_grupo IS NULL OR TRIM(p_grupo) = '' OR c."grupo" = p_grupo);

    -- Devolver filas
    RETURN QUERY
    SELECT
        v_total,
        c."COD_CUENTA",
        c."DESCRIPCION",
        c."TIPO",
        c."PRESUPUESTO",
        c."SALDO",
        c."COD_USUARIO",
        c."grupo",
        c."LINEA",
        c."USO",
        c."Nivel",
        c."Porcentaje"
    FROM public."Cuentas" c
    WHERE (v_search IS NULL OR c."COD_CUENTA" LIKE v_search OR c."DESCRIPCION" LIKE v_search)
      AND (p_tipo IS NULL OR TRIM(p_tipo) = '' OR c."TIPO" = p_tipo)
      AND (p_grupo IS NULL OR TRIM(p_grupo) = '' OR c."grupo" = p_grupo)
    ORDER BY c."COD_CUENTA"
    LIMIT v_limit OFFSET v_offset;
END;
$$;

-- ---------- 2. Get by Codigo ----------
CREATE OR REPLACE FUNCTION usp_cuentas_getbycodigo(
    p_cod_cuenta VARCHAR(50)
)
RETURNS TABLE(
    "COD_CUENTA"   VARCHAR(50),
    "DESCRIPCION"  VARCHAR(100),
    "TIPO"         VARCHAR(50),
    "PRESUPUESTO"  INT,
    "SALDO"        INT,
    "COD_USUARIO"  VARCHAR(10),
    "grupo"        VARCHAR(50),
    "LINEA"        VARCHAR(50),
    "USO"          VARCHAR(50),
    "Nivel"        INT,
    "Porcentaje"   DOUBLE PRECISION
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        c."COD_CUENTA",
        c."DESCRIPCION",
        c."TIPO",
        c."PRESUPUESTO",
        c."SALDO",
        c."COD_USUARIO",
        c."grupo",
        c."LINEA",
        c."USO",
        c."Nivel",
        c."Porcentaje"
    FROM public."Cuentas" c
    WHERE c."COD_CUENTA" = p_cod_cuenta;
END;
$$;

-- ---------- 3. Insert ----------
CREATE OR REPLACE FUNCTION usp_cuentas_insert(
    p_row_json JSONB
)
RETURNS TABLE(
    "Resultado" INT,
    "Mensaje"   VARCHAR(500)
)
LANGUAGE plpgsql AS $$
DECLARE
    v_resultado INT := 0;
    v_mensaje   VARCHAR(500) := '';
BEGIN
    -- Verificar duplicado
    IF EXISTS (
        SELECT 1 FROM public."Cuentas"
        WHERE "COD_CUENTA" = (p_row_json->>'COD_CUENTA')
    ) THEN
        RETURN QUERY SELECT -1, 'Cuenta ya existe'::VARCHAR(500);
        RETURN;
    END IF;

    INSERT INTO public."Cuentas" (
        "COD_CUENTA", "DESCRIPCION", "TIPO", "PRESUPUESTO", "SALDO",
        "COD_USUARIO", "grupo", "LINEA", "USO", "Nivel", "Porcentaje"
    ) VALUES (
        NULLIF(p_row_json->>'COD_CUENTA', ''),
        NULLIF(p_row_json->>'DESCRIPCION', ''),
        NULLIF(p_row_json->>'TIPO', ''),
        CASE WHEN COALESCE(p_row_json->>'PRESUPUESTO', '') = '' THEN NULL
             ELSE (p_row_json->>'PRESUPUESTO')::INT END,
        CASE WHEN COALESCE(p_row_json->>'SALDO', '') = '' THEN NULL
             ELSE (p_row_json->>'SALDO')::INT END,
        NULLIF(p_row_json->>'COD_USUARIO', ''),
        NULLIF(p_row_json->>'grupo', ''),
        NULLIF(p_row_json->>'LINEA', ''),
        NULLIF(p_row_json->>'USO', ''),
        CASE WHEN COALESCE(p_row_json->>'Nivel', '') = '' THEN NULL
             ELSE (p_row_json->>'Nivel')::INT END,
        CASE WHEN COALESCE(p_row_json->>'Porcentaje', '') = '' THEN NULL
             ELSE (p_row_json->>'Porcentaje')::DOUBLE PRECISION END
    );

    RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
END;
$$;

-- ---------- 4. Update ----------
CREATE OR REPLACE FUNCTION usp_cuentas_update(
    p_cod_cuenta VARCHAR(50),
    p_row_json   JSONB
)
RETURNS TABLE(
    "Resultado" INT,
    "Mensaje"   VARCHAR(500)
)
LANGUAGE plpgsql AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public."Cuentas" WHERE "COD_CUENTA" = p_cod_cuenta) THEN
        RETURN QUERY SELECT -1, 'Cuenta no encontrada'::VARCHAR(500);
        RETURN;
    END IF;

    UPDATE public."Cuentas" SET
        "DESCRIPCION" = COALESCE(NULLIF(p_row_json->>'DESCRIPCION', ''), "DESCRIPCION"),
        "TIPO"        = COALESCE(NULLIF(p_row_json->>'TIPO', ''), "TIPO"),
        "grupo"       = COALESCE(NULLIF(p_row_json->>'grupo', ''), "grupo"),
        "LINEA"       = COALESCE(NULLIF(p_row_json->>'LINEA', ''), "LINEA"),
        "USO"         = COALESCE(NULLIF(p_row_json->>'USO', ''), "USO"),
        "Nivel"       = CASE WHEN COALESCE(p_row_json->>'Nivel', '') = '' THEN "Nivel"
                             ELSE (p_row_json->>'Nivel')::INT END,
        "Porcentaje"  = CASE WHEN COALESCE(p_row_json->>'Porcentaje', '') = '' THEN "Porcentaje"
                             ELSE (p_row_json->>'Porcentaje')::DOUBLE PRECISION END
    WHERE "COD_CUENTA" = p_cod_cuenta;

    RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
END;
$$;

-- ---------- 5. Delete ----------
CREATE OR REPLACE FUNCTION usp_cuentas_delete(
    p_cod_cuenta VARCHAR(50)
)
RETURNS TABLE(
    "Resultado" INT,
    "Mensaje"   VARCHAR(500)
)
LANGUAGE plpgsql AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public."Cuentas" WHERE "COD_CUENTA" = p_cod_cuenta) THEN
        RETURN QUERY SELECT -1, 'Cuenta no encontrada'::VARCHAR(500);
        RETURN;
    END IF;

    DELETE FROM public."Cuentas" WHERE "COD_CUENTA" = p_cod_cuenta;

    RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
END;
$$;
