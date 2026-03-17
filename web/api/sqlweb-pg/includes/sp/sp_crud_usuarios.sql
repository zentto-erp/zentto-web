-- =============================================
-- Funciones CRUD: Usuarios
-- Compatible con: PostgreSQL 14+
-- Tabla canonica: sec."User"
-- PK: "UserCode" VARCHAR (legacy: Cod_Usuario)
-- =============================================

-- ---------- 1. List ----------
-- NOTE: Avatar column is TEXT in sec."User", must match return type
DROP FUNCTION IF EXISTS usp_usuarios_list(character varying, character varying, integer, integer) CASCADE;
CREATE OR REPLACE FUNCTION usp_usuarios_list(
    p_search VARCHAR(100) DEFAULT NULL,
    p_tipo   VARCHAR(50)  DEFAULT NULL,
    p_page   INT DEFAULT 1,
    p_limit  INT DEFAULT 50
)
RETURNS TABLE (
    "TotalCount"    BIGINT,
    "Cod_Usuario"   VARCHAR,
    "Password"      VARCHAR,
    "Nombre"        VARCHAR,
    "Tipo"          VARCHAR,
    "Updates"       BOOLEAN,
    "Addnews"       BOOLEAN,
    "Deletes"       BOOLEAN,
    "Creador"       BOOLEAN,
    "Cambiar"       BOOLEAN,
    "PrecioMinimo"  BOOLEAN,
    "Credito"       BOOLEAN,
    "IsAdmin"       BOOLEAN,
    "Avatar"        TEXT
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
    FROM sec."User"
    WHERE "IsDeleted" = FALSE
      AND (v_search IS NULL OR "UserCode" LIKE v_search OR "UserName" LIKE v_search)
      AND (p_tipo IS NULL OR TRIM(p_tipo) = '' OR "UserType" = p_tipo);

    RETURN QUERY
    SELECT
        v_total,
        u."UserCode"::VARCHAR        AS "Cod_Usuario",
        u."PasswordHash"::VARCHAR    AS "Password",
        u."UserName"::VARCHAR        AS "Nombre",
        u."UserType"::VARCHAR        AS "Tipo",
        u."CanUpdate"       AS "Updates",
        u."CanCreate"       AS "Addnews",
        u."CanDelete"       AS "Deletes",
        u."IsCreator"       AS "Creador",
        u."CanChangePwd"    AS "Cambiar",
        u."CanChangePrice"  AS "PrecioMinimo",
        u."CanGiveCredit"   AS "Credito",
        u."IsAdmin",
        u."Avatar"
    FROM sec."User" u
    WHERE u."IsDeleted" = FALSE
      AND (v_search IS NULL OR u."UserCode" LIKE v_search OR u."UserName" LIKE v_search)
      AND (p_tipo IS NULL OR TRIM(p_tipo) = '' OR u."UserType" = p_tipo)
    ORDER BY u."UserCode"
    LIMIT v_limit OFFSET v_offset;
END;
$$;

-- ---------- 2. Get by Codigo ----------
-- NOTE: Avatar column is TEXT in sec."User", must match return type
DROP FUNCTION IF EXISTS usp_usuarios_getbycodigo(character varying) CASCADE;
CREATE OR REPLACE FUNCTION usp_usuarios_getbycodigo(
    p_cod_usuario VARCHAR(50)
)
RETURNS TABLE (
    "Cod_Usuario"   VARCHAR,
    "Password"      VARCHAR,
    "Nombre"        VARCHAR,
    "Tipo"          VARCHAR,
    "Updates"       BOOLEAN,
    "Addnews"       BOOLEAN,
    "Deletes"       BOOLEAN,
    "Creador"       BOOLEAN,
    "Cambiar"       BOOLEAN,
    "PrecioMinimo"  BOOLEAN,
    "Credito"       BOOLEAN,
    "IsAdmin"       BOOLEAN,
    "Avatar"        TEXT
) LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        u."UserCode"::VARCHAR       AS "Cod_Usuario",
        u."PasswordHash"::VARCHAR   AS "Password",
        u."UserName"::VARCHAR       AS "Nombre",
        u."UserType"::VARCHAR       AS "Tipo",
        u."CanUpdate"      AS "Updates",
        u."CanCreate"      AS "Addnews",
        u."CanDelete"      AS "Deletes",
        u."IsCreator"      AS "Creador",
        u."CanChangePwd"   AS "Cambiar",
        u."CanChangePrice" AS "PrecioMinimo",
        u."CanGiveCredit"  AS "Credito",
        u."IsAdmin",
        u."Avatar"
    FROM sec."User" u
    WHERE u."UserCode" = p_cod_usuario AND u."IsDeleted" = FALSE;
END;
$$;

-- ---------- 3. Insert ----------
-- NOTE: Handles upsert for soft-deleted users to avoid unique constraint violation
DROP FUNCTION IF EXISTS usp_usuarios_insert(jsonb) CASCADE;
CREATE OR REPLACE FUNCTION usp_usuarios_insert(
    p_row_json JSONB
)
RETURNS TABLE (
    "Resultado" INT,
    "Mensaje"   VARCHAR
) LANGUAGE plpgsql AS $$
DECLARE
    v_cod_usuario VARCHAR(50);
BEGIN
    v_cod_usuario := NULLIF(p_row_json->>'Cod_Usuario', '');

    -- Check if active user already exists
    IF EXISTS (SELECT 1 FROM sec."User" WHERE "UserCode" = v_cod_usuario AND "IsDeleted" = FALSE) THEN
        RETURN QUERY SELECT -1, 'Usuario ya existe'::VARCHAR;
        RETURN;
    END IF;

    BEGIN
        -- If soft-deleted record exists, restore it with new data
        IF EXISTS (SELECT 1 FROM sec."User" WHERE "UserCode" = v_cod_usuario AND "IsDeleted" = TRUE) THEN
            UPDATE sec."User" SET
                "PasswordHash"   = NULLIF(p_row_json->>'Password', ''),
                "UserName"       = NULLIF(p_row_json->>'Nombre', ''),
                "UserType"       = COALESCE(NULLIF(p_row_json->>'Tipo', ''), 'USER'),
                "CanUpdate"      = COALESCE((p_row_json->>'Updates')::BOOLEAN, TRUE),
                "CanCreate"      = COALESCE((p_row_json->>'Addnews')::BOOLEAN, TRUE),
                "CanDelete"      = COALESCE((p_row_json->>'Deletes')::BOOLEAN, FALSE),
                "IsCreator"      = COALESCE((p_row_json->>'Creador')::BOOLEAN, FALSE),
                "CanChangePwd"   = COALESCE((p_row_json->>'Cambiar')::BOOLEAN, TRUE),
                "CanChangePrice" = COALESCE((p_row_json->>'PrecioMinimo')::BOOLEAN, FALSE),
                "CanGiveCredit"  = COALESCE((p_row_json->>'Credito')::BOOLEAN, FALSE),
                "IsAdmin"        = COALESCE((p_row_json->>'IsAdmin')::BOOLEAN, FALSE),
                "IsActive"       = TRUE,
                "IsDeleted"      = FALSE,
                "DeletedAt"      = NULL,
                "DeletedByUserId" = NULL,
                "UpdatedAt"      = NOW() AT TIME ZONE 'UTC'
            WHERE "UserCode" = v_cod_usuario;
        ELSE
            INSERT INTO sec."User" (
                "UserCode", "PasswordHash", "UserName", "UserType",
                "CanUpdate", "CanCreate", "CanDelete", "IsCreator",
                "CanChangePwd", "CanChangePrice", "CanGiveCredit",
                "IsAdmin", "IsActive", "CreatedAt", "UpdatedAt", "IsDeleted"
            ) VALUES (
                v_cod_usuario,
                NULLIF(p_row_json->>'Password', ''),
                NULLIF(p_row_json->>'Nombre', ''),
                COALESCE(NULLIF(p_row_json->>'Tipo', ''), 'USER'),
                COALESCE((p_row_json->>'Updates')::BOOLEAN, TRUE),
                COALESCE((p_row_json->>'Addnews')::BOOLEAN, TRUE),
                COALESCE((p_row_json->>'Deletes')::BOOLEAN, FALSE),
                COALESCE((p_row_json->>'Creador')::BOOLEAN, FALSE),
                COALESCE((p_row_json->>'Cambiar')::BOOLEAN, TRUE),
                COALESCE((p_row_json->>'PrecioMinimo')::BOOLEAN, FALSE),
                COALESCE((p_row_json->>'Credito')::BOOLEAN, FALSE),
                COALESCE((p_row_json->>'IsAdmin')::BOOLEAN, FALSE),
                TRUE,
                NOW() AT TIME ZONE 'UTC',
                NOW() AT TIME ZONE 'UTC',
                FALSE
            );
        END IF;

        RETURN QUERY SELECT 1, 'OK'::VARCHAR;
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT -99, SQLERRM::VARCHAR;
    END;
END;
$$;

-- ---------- 4. Update ----------
CREATE OR REPLACE FUNCTION usp_usuarios_update(
    p_cod_usuario VARCHAR(50),
    p_row_json    JSONB
)
RETURNS TABLE (
    "Resultado" INT,
    "Mensaje"   VARCHAR
) LANGUAGE plpgsql AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sec."User" WHERE "UserCode" = p_cod_usuario AND "IsDeleted" = FALSE) THEN
        RETURN QUERY SELECT -1, 'Usuario no encontrado'::VARCHAR;
        RETURN;
    END IF;

    BEGIN
        UPDATE sec."User" SET
            "PasswordHash"   = COALESCE(NULLIF(p_row_json->>'Password', ''), "PasswordHash"),
            "UserName"       = COALESCE(NULLIF(p_row_json->>'Nombre', ''), "UserName"),
            "UserType"       = COALESCE(NULLIF(p_row_json->>'Tipo', ''), "UserType"),
            "IsAdmin"        = COALESCE((p_row_json->>'IsAdmin')::BOOLEAN, "IsAdmin"),
            "CanUpdate"      = COALESCE((p_row_json->>'Updates')::BOOLEAN, "CanUpdate"),
            "CanCreate"      = COALESCE((p_row_json->>'Addnews')::BOOLEAN, "CanCreate"),
            "CanDelete"      = COALESCE((p_row_json->>'Deletes')::BOOLEAN, "CanDelete"),
            "IsCreator"      = COALESCE((p_row_json->>'Creador')::BOOLEAN, "IsCreator"),
            "CanChangePwd"   = COALESCE((p_row_json->>'Cambiar')::BOOLEAN, "CanChangePwd"),
            "CanChangePrice" = COALESCE((p_row_json->>'PrecioMinimo')::BOOLEAN, "CanChangePrice"),
            "CanGiveCredit"  = COALESCE((p_row_json->>'Credito')::BOOLEAN, "CanGiveCredit"),
            "UpdatedAt"      = NOW() AT TIME ZONE 'UTC'
        WHERE "UserCode" = p_cod_usuario AND "IsDeleted" = FALSE;

        RETURN QUERY SELECT 1, 'OK'::VARCHAR;
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT -99, SQLERRM::VARCHAR;
    END;
END;
$$;

-- ---------- 5. Delete (soft delete) ----------
CREATE OR REPLACE FUNCTION usp_usuarios_delete(
    p_cod_usuario VARCHAR(50)
)
RETURNS TABLE (
    "Resultado" INT,
    "Mensaje"   VARCHAR
) LANGUAGE plpgsql AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sec."User" WHERE "UserCode" = p_cod_usuario AND "IsDeleted" = FALSE) THEN
        RETURN QUERY SELECT -1, 'Usuario no encontrado'::VARCHAR;
        RETURN;
    END IF;

    BEGIN
        UPDATE sec."User"
        SET "IsDeleted" = TRUE,
            "IsActive"  = FALSE,
            "DeletedAt" = NOW() AT TIME ZONE 'UTC',
            "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
        WHERE "UserCode" = p_cod_usuario AND "IsDeleted" = FALSE;

        RETURN QUERY SELECT 1, 'OK'::VARCHAR;
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT -99, SQLERRM::VARCHAR;
    END;
END;
$$;
