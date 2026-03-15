-- =============================================
-- Funciones CRUD: Vehiculos
-- Compatible con: PostgreSQL 14+
-- PK: "Placa" VARCHAR
-- =============================================

-- ---------- 1. List ----------
CREATE OR REPLACE FUNCTION usp_vehiculos_list(
    p_search  VARCHAR(100) DEFAULT NULL,
    p_cedula  VARCHAR(20)  DEFAULT NULL,
    p_page    INT DEFAULT 1,
    p_limit   INT DEFAULT 50
)
RETURNS TABLE (
    "TotalCount" BIGINT,
    "Placa"      VARCHAR,
    "Cedula"     VARCHAR,
    "Marca"      VARCHAR,
    "Anio"       VARCHAR,
    "Cauchos"    VARCHAR
) LANGUAGE plpgsql AS $$
DECLARE
    v_offset  INT;
    v_limit   INT;
    v_total   BIGINT;
    v_search  VARCHAR(100);
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

    SELECT COUNT(1) INTO v_total
    FROM public."Vehiculos"
    WHERE (v_search IS NULL OR "Placa" LIKE v_search OR "Marca" LIKE v_search)
      AND (p_cedula IS NULL OR TRIM(p_cedula) = '' OR "Cedula" = p_cedula);

    RETURN QUERY
    SELECT
        v_total,
        v."Placa",
        v."Cedula",
        v."Marca",
        v."Anio",
        v."Cauchos"
    FROM public."Vehiculos" v
    WHERE (v_search IS NULL OR v."Placa" LIKE v_search OR v."Marca" LIKE v_search)
      AND (p_cedula IS NULL OR TRIM(p_cedula) = '' OR v."Cedula" = p_cedula)
    ORDER BY v."Placa"
    LIMIT v_limit OFFSET v_offset;
END;
$$;

-- ---------- 2. Get by Placa ----------
CREATE OR REPLACE FUNCTION usp_vehiculos_getbyplaca(
    p_placa VARCHAR(20)
)
RETURNS TABLE (
    "Placa"   VARCHAR,
    "Cedula"  VARCHAR,
    "Marca"   VARCHAR,
    "Anio"    VARCHAR,
    "Cauchos" VARCHAR
) LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT v."Placa", v."Cedula", v."Marca", v."Anio", v."Cauchos"
    FROM public."Vehiculos" v
    WHERE v."Placa" = p_placa;
END;
$$;

-- ---------- 3. Insert ----------
CREATE OR REPLACE FUNCTION usp_vehiculos_insert(
    p_row_json JSONB
)
RETURNS TABLE (
    "Resultado" INT,
    "Mensaje"   VARCHAR
) LANGUAGE plpgsql AS $$
DECLARE
    v_placa VARCHAR(20);
BEGIN
    v_placa := NULLIF(p_row_json->>'Placa', '');

    IF EXISTS (SELECT 1 FROM public."Vehiculos" WHERE "Placa" = v_placa) THEN
        RETURN QUERY SELECT -1, 'Vehiculo ya existe'::VARCHAR;
        RETURN;
    END IF;

    BEGIN
        INSERT INTO public."Vehiculos" ("Placa", "Cedula", "Marca", "Anio", "Cauchos")
        VALUES (
            v_placa,
            NULLIF(p_row_json->>'Cedula', ''),
            NULLIF(p_row_json->>'Marca', ''),
            NULLIF(p_row_json->>'Anio', ''),
            NULLIF(p_row_json->>'Cauchos', '')
        );

        RETURN QUERY SELECT 1, 'OK'::VARCHAR;
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT -99, SQLERRM::VARCHAR;
    END;
END;
$$;

-- ---------- 4. Update ----------
CREATE OR REPLACE FUNCTION usp_vehiculos_update(
    p_placa    VARCHAR(20),
    p_row_json JSONB
)
RETURNS TABLE (
    "Resultado" INT,
    "Mensaje"   VARCHAR
) LANGUAGE plpgsql AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public."Vehiculos" WHERE "Placa" = p_placa) THEN
        RETURN QUERY SELECT -1, 'Vehiculo no encontrado'::VARCHAR;
        RETURN;
    END IF;

    BEGIN
        UPDATE public."Vehiculos" SET
            "Cedula"  = COALESCE(NULLIF(p_row_json->>'Cedula', ''), "Cedula"),
            "Marca"   = COALESCE(NULLIF(p_row_json->>'Marca', ''), "Marca"),
            "Anio"    = COALESCE(NULLIF(p_row_json->>'Anio', ''), "Anio"),
            "Cauchos" = COALESCE(NULLIF(p_row_json->>'Cauchos', ''), "Cauchos")
        WHERE "Placa" = p_placa;

        RETURN QUERY SELECT 1, 'OK'::VARCHAR;
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT -99, SQLERRM::VARCHAR;
    END;
END;
$$;

-- ---------- 5. Delete ----------
CREATE OR REPLACE FUNCTION usp_vehiculos_delete(
    p_placa VARCHAR(20)
)
RETURNS TABLE (
    "Resultado" INT,
    "Mensaje"   VARCHAR
) LANGUAGE plpgsql AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public."Vehiculos" WHERE "Placa" = p_placa) THEN
        RETURN QUERY SELECT -1, 'Vehiculo no encontrado'::VARCHAR;
        RETURN;
    END IF;

    BEGIN
        DELETE FROM public."Vehiculos" WHERE "Placa" = p_placa;
        RETURN QUERY SELECT 1, 'OK'::VARCHAR;
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT -99, SQLERRM::VARCHAR;
    END;
END;
$$;
