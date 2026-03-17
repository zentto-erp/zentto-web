-- =============================================
-- Funciones CRUD: Bancos  (PostgreSQL)
-- PK: Nombre varchar
-- =============================================

-- ---------- 1. List (paginado con filtros) ----------
DROP FUNCTION IF EXISTS usp_bancos_list(VARCHAR(100), INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_bancos_list(
    p_search      VARCHAR(100) DEFAULT NULL,
    p_page        INT DEFAULT 1,
    p_limit       INT DEFAULT 50
)
RETURNS TABLE(
    "Nombre"      VARCHAR(50),
    "Contacto"    VARCHAR(50),
    "Direccion"   VARCHAR(255),
    "Telefonos"   VARCHAR(60),
    "Co_Usuario"  VARCHAR(10),
    "TotalCount"  BIGINT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_offset   INT;
    v_limit    INT;
    v_search   VARCHAR(100);
    v_total    BIGINT;
BEGIN
    v_limit  := COALESCE(NULLIF(p_limit, 0), 50);
    IF v_limit < 1 THEN v_limit := 50; END IF;
    IF v_limit > 500 THEN v_limit := 500; END IF;

    v_offset := (COALESCE(NULLIF(p_page, 0), 1) - 1) * v_limit;
    IF v_offset < 0 THEN v_offset := 0; END IF;

    IF p_search IS NOT NULL AND TRIM(p_search) <> '' THEN
        v_search := '%' || p_search || '%';
    ELSE
        v_search := NULL;
    END IF;

    SELECT COUNT(1) INTO v_total
    FROM dbo."Bancos" b
    WHERE (v_search IS NULL OR b."Nombre" LIKE v_search OR b."Contacto" LIKE v_search);

    RETURN QUERY
    SELECT
        b."Nombre",
        b."Contacto",
        b."Direccion",
        b."Telefonos",
        b."Co_Usuario",
        v_total
    FROM dbo."Bancos" b
    WHERE (v_search IS NULL OR b."Nombre" LIKE v_search OR b."Contacto" LIKE v_search)
    ORDER BY b."Nombre"
    LIMIT v_limit OFFSET v_offset;
END;
$$;

-- ---------- 2. Get by Nombre ----------
DROP FUNCTION IF EXISTS usp_bancos_getbynombre(VARCHAR(50)) CASCADE;
CREATE OR REPLACE FUNCTION usp_bancos_getbynombre(
    p_nombre VARCHAR(50)
)
RETURNS TABLE(
    "Nombre"      VARCHAR(50),
    "Contacto"    VARCHAR(50),
    "Direccion"   VARCHAR(255),
    "Telefonos"   VARCHAR(60),
    "Co_Usuario"  VARCHAR(10)
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT b."Nombre", b."Contacto", b."Direccion", b."Telefonos", b."Co_Usuario"
    FROM dbo."Bancos" b
    WHERE b."Nombre" = p_nombre;
END;
$$;

-- ---------- 3. Insert ----------
DROP FUNCTION IF EXISTS usp_bancos_insert(JSONB) CASCADE;
CREATE OR REPLACE FUNCTION usp_bancos_insert(
    p_row_json JSONB
)
RETURNS TABLE("Resultado" INT, "Mensaje" VARCHAR(500))
LANGUAGE plpgsql
AS $$
DECLARE
    v_nombre VARCHAR(50);
BEGIN
    v_nombre := NULLIF(p_row_json->>'Nombre', '');

    IF EXISTS (SELECT 1 FROM dbo."Bancos" WHERE "Nombre" = v_nombre) THEN
        RETURN QUERY SELECT -1, 'Banco ya existe'::VARCHAR(500);
        RETURN;
    END IF;

    BEGIN
        INSERT INTO dbo."Bancos" ("Nombre", "Contacto", "Direccion", "Telefonos", "Co_Usuario")
        VALUES (
            v_nombre,
            NULLIF(p_row_json->>'Contacto', ''),
            NULLIF(p_row_json->>'Direccion', ''),
            NULLIF(p_row_json->>'Telefonos', ''),
            NULLIF(p_row_json->>'Co_Usuario', '')
        );

        RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
    END;
END;
$$;

-- ---------- 4. Update ----------
DROP FUNCTION IF EXISTS usp_bancos_update(VARCHAR(50), JSONB) CASCADE;
CREATE OR REPLACE FUNCTION usp_bancos_update(
    p_nombre  VARCHAR(50),
    p_row_json JSONB
)
RETURNS TABLE("Resultado" INT, "Mensaje" VARCHAR(500))
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM dbo."Bancos" WHERE "Nombre" = p_nombre) THEN
        RETURN QUERY SELECT -1, 'Banco no encontrado'::VARCHAR(500);
        RETURN;
    END IF;

    BEGIN
        UPDATE dbo."Bancos"
        SET "Contacto"   = COALESCE(NULLIF(p_row_json->>'Contacto', ''), "Contacto"),
            "Direccion"  = COALESCE(NULLIF(p_row_json->>'Direccion', ''), "Direccion"),
            "Telefonos"  = COALESCE(NULLIF(p_row_json->>'Telefonos', ''), "Telefonos"),
            "Co_Usuario" = COALESCE(NULLIF(p_row_json->>'Co_Usuario', ''), "Co_Usuario")
        WHERE "Nombre" = p_nombre;

        RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
    END;
END;
$$;

-- ---------- 5. Delete ----------
DROP FUNCTION IF EXISTS usp_bancos_delete(VARCHAR(50)) CASCADE;
CREATE OR REPLACE FUNCTION usp_bancos_delete(
    p_nombre VARCHAR(50)
)
RETURNS TABLE("Resultado" INT, "Mensaje" VARCHAR(500))
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM dbo."Bancos" WHERE "Nombre" = p_nombre) THEN
        RETURN QUERY SELECT -1, 'Banco no encontrado'::VARCHAR(500);
        RETURN;
    END IF;

    BEGIN
        DELETE FROM dbo."Bancos" WHERE "Nombre" = p_nombre;

        RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
    END;
END;
$$;
