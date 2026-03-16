-- ============================================================
-- DatqBoxWeb PostgreSQL - sp_crud_empleados.sql
-- CRUD de Empleados (PK: CEDULA varchar)
-- ============================================================

-- ---------- 1. List (paginado con filtros) ----------
CREATE OR REPLACE FUNCTION usp_empleados_list(
    p_search  VARCHAR(100) DEFAULT NULL,
    p_grupo   VARCHAR(50)  DEFAULT NULL,
    p_status  VARCHAR(50)  DEFAULT NULL,
    p_page    INT          DEFAULT 1,
    p_limit   INT          DEFAULT 50
)
RETURNS TABLE(
    "TotalCount"    INT,
    "CEDULA"        VARCHAR(20),
    "GRUPO"         VARCHAR(50),
    "NOMBRE"        VARCHAR(100),
    "DIRECCION"     VARCHAR(255),
    "TELEFONO"      VARCHAR(60),
    "NACIMIENTO"    TIMESTAMP,
    "CARGO"         VARCHAR(50),
    "NOMINA"        VARCHAR(50),
    "SUELDO"        DOUBLE PRECISION,
    "INGRESO"       TIMESTAMP,
    "RETIRO"        TIMESTAMP,
    "STATUS"        VARCHAR(50),
    "COMISION"      DOUBLE PRECISION,
    "UTILIDAD"      DOUBLE PRECISION,
    "CO_Usuario"    VARCHAR(10),
    "SEXO"          VARCHAR(10),
    "NACIONALIDAD"  VARCHAR(50),
    "Autoriza"      BOOLEAN,
    "Apodo"         VARCHAR(50)
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
    FROM public."Empleados" e
    WHERE (v_search IS NULL OR e."CEDULA" LIKE v_search OR e."NOMBRE" LIKE v_search OR e."CARGO" LIKE v_search)
      AND (p_grupo IS NULL OR TRIM(p_grupo) = '' OR e."GRUPO" = p_grupo)
      AND (p_status IS NULL OR TRIM(p_status) = '' OR e."STATUS" = p_status);

    -- Devolver filas
    RETURN QUERY
    SELECT
        v_total,
        e."CEDULA",
        e."GRUPO",
        e."NOMBRE",
        e."DIRECCION",
        e."TELEFONO",
        e."NACIMIENTO",
        e."CARGO",
        e."NOMINA",
        e."SUELDO",
        e."INGRESO",
        e."RETIRO",
        e."STATUS",
        e."COMISION",
        e."UTILIDAD",
        e."CO_Usuario",
        e."SEXO",
        e."NACIONALIDAD",
        e."Autoriza",
        e."Apodo"
    FROM public."Empleados" e
    WHERE (v_search IS NULL OR e."CEDULA" LIKE v_search OR e."NOMBRE" LIKE v_search OR e."CARGO" LIKE v_search)
      AND (p_grupo IS NULL OR TRIM(p_grupo) = '' OR e."GRUPO" = p_grupo)
      AND (p_status IS NULL OR TRIM(p_status) = '' OR e."STATUS" = p_status)
    ORDER BY e."NOMBRE"
    LIMIT v_limit OFFSET v_offset;
END;
$$;

-- ---------- 2. Get by Cedula ----------
CREATE OR REPLACE FUNCTION usp_empleados_getbycedula(
    p_cedula VARCHAR(20)
)
RETURNS TABLE(
    "CEDULA"        VARCHAR(20),
    "GRUPO"         VARCHAR(50),
    "NOMBRE"        VARCHAR(100),
    "DIRECCION"     VARCHAR(255),
    "TELEFONO"      VARCHAR(60),
    "NACIMIENTO"    TIMESTAMP,
    "CARGO"         VARCHAR(50),
    "NOMINA"        VARCHAR(50),
    "SUELDO"        DOUBLE PRECISION,
    "INGRESO"       TIMESTAMP,
    "RETIRO"        TIMESTAMP,
    "STATUS"        VARCHAR(50),
    "COMISION"      DOUBLE PRECISION,
    "UTILIDAD"      DOUBLE PRECISION,
    "CO_Usuario"    VARCHAR(10),
    "SEXO"          VARCHAR(10),
    "NACIONALIDAD"  VARCHAR(50),
    "Autoriza"      BOOLEAN,
    "Apodo"         VARCHAR(50)
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        e."CEDULA",
        e."GRUPO",
        e."NOMBRE",
        e."DIRECCION",
        e."TELEFONO",
        e."NACIMIENTO",
        e."CARGO",
        e."NOMINA",
        e."SUELDO",
        e."INGRESO",
        e."RETIRO",
        e."STATUS",
        e."COMISION",
        e."UTILIDAD",
        e."CO_Usuario",
        e."SEXO",
        e."NACIONALIDAD",
        e."Autoriza",
        e."Apodo"
    FROM public."Empleados" e
    WHERE e."CEDULA" = p_cedula;
END;
$$;

-- ---------- 3. Insert ----------
CREATE OR REPLACE FUNCTION usp_empleados_insert(
    p_row_json JSONB
)
RETURNS TABLE(
    "Resultado" INT,
    "Mensaje"   VARCHAR(500)
)
LANGUAGE plpgsql AS $$
BEGIN
    -- Verificar duplicado
    IF EXISTS (
        SELECT 1 FROM public."Empleados"
        WHERE "CEDULA" = (p_row_json->>'CEDULA')
    ) THEN
        RETURN QUERY SELECT -1, 'Empleado ya existe'::VARCHAR(500);
        RETURN;
    END IF;

    INSERT INTO public."Empleados" (
        "CEDULA", "GRUPO", "NOMBRE", "DIRECCION", "TELEFONO", "NACIMIENTO",
        "CARGO", "NOMINA", "SUELDO", "INGRESO", "RETIRO", "STATUS",
        "COMISION", "UTILIDAD", "CO_Usuario", "SEXO", "NACIONALIDAD",
        "Autoriza", "Apodo"
    ) VALUES (
        NULLIF(p_row_json->>'CEDULA', ''),
        NULLIF(p_row_json->>'GRUPO', ''),
        NULLIF(p_row_json->>'NOMBRE', ''),
        NULLIF(p_row_json->>'DIRECCION', ''),
        NULLIF(p_row_json->>'TELEFONO', ''),
        CASE WHEN COALESCE(p_row_json->>'NACIMIENTO', '') = '' THEN NULL
             ELSE (p_row_json->>'NACIMIENTO')::TIMESTAMP END,
        NULLIF(p_row_json->>'CARGO', ''),
        NULLIF(p_row_json->>'NOMINA', ''),
        CASE WHEN COALESCE(p_row_json->>'SUELDO', '') = '' THEN NULL
             ELSE (p_row_json->>'SUELDO')::DOUBLE PRECISION END,
        CASE WHEN COALESCE(p_row_json->>'INGRESO', '') = '' THEN NULL
             ELSE (p_row_json->>'INGRESO')::TIMESTAMP END,
        CASE WHEN COALESCE(p_row_json->>'RETIRO', '') = '' THEN NULL
             ELSE (p_row_json->>'RETIRO')::TIMESTAMP END,
        NULLIF(p_row_json->>'STATUS', ''),
        CASE WHEN COALESCE(p_row_json->>'COMISION', '') = '' THEN NULL
             ELSE (p_row_json->>'COMISION')::DOUBLE PRECISION END,
        CASE WHEN COALESCE(p_row_json->>'UTILIDAD', '') = '' THEN NULL
             ELSE (p_row_json->>'UTILIDAD')::DOUBLE PRECISION END,
        NULLIF(p_row_json->>'CO_Usuario', ''),
        NULLIF(p_row_json->>'SEXO', ''),
        NULLIF(p_row_json->>'NACIONALIDAD', ''),
        COALESCE((p_row_json->>'Autoriza')::BOOLEAN, FALSE),
        NULLIF(p_row_json->>'Apodo', '')
    );

    RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
END;
$$;

-- ---------- 4. Update ----------
CREATE OR REPLACE FUNCTION usp_empleados_update(
    p_cedula   VARCHAR(20),
    p_row_json JSONB
)
RETURNS TABLE(
    "Resultado" INT,
    "Mensaje"   VARCHAR(500)
)
LANGUAGE plpgsql AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public."Empleados" WHERE "CEDULA" = p_cedula) THEN
        RETURN QUERY SELECT -1, 'Empleado no encontrado'::VARCHAR(500);
        RETURN;
    END IF;

    UPDATE public."Empleados" SET
        "GRUPO"        = COALESCE(NULLIF(p_row_json->>'GRUPO', ''), "GRUPO"),
        "NOMBRE"       = COALESCE(NULLIF(p_row_json->>'NOMBRE', ''), "NOMBRE"),
        "DIRECCION"    = COALESCE(NULLIF(p_row_json->>'DIRECCION', ''), "DIRECCION"),
        "TELEFONO"     = COALESCE(NULLIF(p_row_json->>'TELEFONO', ''), "TELEFONO"),
        "CARGO"        = COALESCE(NULLIF(p_row_json->>'CARGO', ''), "CARGO"),
        "NOMINA"       = COALESCE(NULLIF(p_row_json->>'NOMINA', ''), "NOMINA"),
        "SUELDO"       = CASE WHEN COALESCE(p_row_json->>'SUELDO', '') = '' THEN "SUELDO"
                              ELSE (p_row_json->>'SUELDO')::DOUBLE PRECISION END,
        "STATUS"       = COALESCE(NULLIF(p_row_json->>'STATUS', ''), "STATUS"),
        "COMISION"     = CASE WHEN COALESCE(p_row_json->>'COMISION', '') = '' THEN "COMISION"
                              ELSE (p_row_json->>'COMISION')::DOUBLE PRECISION END,
        "SEXO"         = COALESCE(NULLIF(p_row_json->>'SEXO', ''), "SEXO"),
        "NACIONALIDAD" = COALESCE(NULLIF(p_row_json->>'NACIONALIDAD', ''), "NACIONALIDAD"),
        "Autoriza"     = COALESCE((p_row_json->>'Autoriza')::BOOLEAN, "Autoriza")
    WHERE "CEDULA" = p_cedula;

    RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
END;
$$;

-- ---------- 5. Delete ----------
CREATE OR REPLACE FUNCTION usp_empleados_delete(
    p_cedula VARCHAR(20)
)
RETURNS TABLE(
    "Resultado" INT,
    "Mensaje"   VARCHAR(500)
)
LANGUAGE plpgsql AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public."Empleados" WHERE "CEDULA" = p_cedula) THEN
        RETURN QUERY SELECT -1, 'Empleado no encontrado'::VARCHAR(500);
        RETURN;
    END IF;

    DELETE FROM public."Empleados" WHERE "CEDULA" = p_cedula;

    RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
END;
$$;
