-- ============================================================
-- DatqBoxWeb PostgreSQL - sp_crud_centro_costo.sql
-- CRUD de Centro de Costo (acct."CostCenter")
-- Tabla canonica: acct."CostCenter" (CostCenterId, CostCenterCode, CostCenterName)
-- Columnas legacy (Presupuestado, Saldo_Real) retornan NULL para compatibilidad
-- ============================================================

-- ---------- 1. List (paginado con filtros) ----------
DROP FUNCTION IF EXISTS usp_centrocosto_list(VARCHAR, INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_centrocosto_list(
    p_search VARCHAR DEFAULT NULL,
    p_page   INT     DEFAULT 1,
    p_limit  INT     DEFAULT 50
)
RETURNS TABLE(
    "Codigo"        character varying,
    "Descripcion"   character varying,
    "Presupuestado" character varying,
    "Saldo_Real"    character varying,
    "TotalCount"    integer
)
LANGUAGE plpgsql AS $func$
DECLARE
    v_offset INT;
    v_limit  INT;
    v_total  INT;
    v_search VARCHAR(100);
BEGIN
    v_limit  := COALESCE(NULLIF(p_limit, 0), 50);
    IF v_limit < 1   THEN v_limit := 50;  END IF;
    IF v_limit > 500 THEN v_limit := 500; END IF;
    v_offset := (COALESCE(NULLIF(p_page, 0), 1) - 1) * v_limit;
    IF v_offset < 0 THEN v_offset := 0; END IF;

    v_search := NULL;
    IF p_search IS NOT NULL AND TRIM(p_search) <> '' THEN
        v_search := '%' || p_search || '%';
    END IF;

    -- Conteo total
    SELECT COUNT(1) INTO v_total
    FROM acct."CostCenter" cc
    WHERE COALESCE(cc."IsDeleted", FALSE) = FALSE
      AND (v_search IS NULL OR cc."CostCenterCode" ILIKE v_search OR cc."CostCenterName" ILIKE v_search);

    -- Resultados paginados
    RETURN QUERY
    SELECT
        cc."CostCenterCode"::VARCHAR,
        cc."CostCenterName"::VARCHAR,
        NULL::VARCHAR,
        NULL::VARCHAR,
        v_total::INT
    FROM acct."CostCenter" cc
    WHERE COALESCE(cc."IsDeleted", FALSE) = FALSE
      AND (v_search IS NULL OR cc."CostCenterCode" ILIKE v_search OR cc."CostCenterName" ILIKE v_search)
    ORDER BY cc."CostCenterCode"
    LIMIT v_limit OFFSET v_offset;
END;
$func$;

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
    v_codigo        := NULLIF(p_row_json->>'Codigo', ''::VARCHAR);
    v_descripcion   := NULLIF(p_row_json->>'Descripcion', ''::VARCHAR);
    v_presupuestado := NULLIF(p_row_json->>'Presupuestado', ''::VARCHAR);
    v_saldo_real    := NULLIF(p_row_json->>'Saldo_Real', ''::VARCHAR);

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

    v_descripcion   := NULLIF(p_row_json->>'Descripcion', ''::VARCHAR);
    v_presupuestado := NULLIF(p_row_json->>'Presupuestado', ''::VARCHAR);
    v_saldo_real    := NULLIF(p_row_json->>'Saldo_Real', ''::VARCHAR);

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
