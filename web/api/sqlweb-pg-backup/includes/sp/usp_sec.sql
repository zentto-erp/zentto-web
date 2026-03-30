-- ============================================================
-- DatqBoxWeb PostgreSQL - usp_sec.sql
-- Funciones de seguridad (autenticaciÃƒÂ³n, permisos, usuarios)
-- ============================================================

-- sec."UserCompanyAccess" table: user-company-branch access control
-- Required by usp_Sec_User_EnsureDefaultCompanyAccess and usp_Sec_User_GetCompanyAccesses
-- Must be created by a superuser or schema owner (zentto_app needs GRANT ALL ON SCHEMA sec)
CREATE TABLE IF NOT EXISTS sec."UserCompanyAccess" (
    "AccessId"   SERIAL PRIMARY KEY,
    "CodUsuario" VARCHAR(50) NOT NULL,
    "CompanyId"  INT NOT NULL,
    "BranchId"   INT NOT NULL,
    "IsActive"   BOOLEAN NOT NULL DEFAULT TRUE,
    "IsDefault"  BOOLEAN NOT NULL DEFAULT FALSE,
    "CreatedAt"  TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "UpdatedAt"  TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    CONSTRAINT "UQ_sec_UserCompanyAccess" UNIQUE ("CodUsuario", "CompanyId", "BranchId")
);

-- usp_Sec_User_Authenticate: datos del usuario para autenticaciÃƒÂ³n
-- La verificaciÃƒÂ³n bcrypt se hace en Node.js
DROP FUNCTION IF EXISTS usp_Sec_User_Authenticate(VARCHAR(60)) CASCADE;
CREATE OR REPLACE FUNCTION usp_Sec_User_Authenticate(
    p_cod_usuario VARCHAR(60)
)
RETURNS TABLE(
    "Cod_Usuario" VARCHAR, "Password" VARCHAR, "Nombre" VARCHAR,
    "Tipo" VARCHAR, "Updates" BOOLEAN, "Addnews" BOOLEAN,
    "Deletes" BOOLEAN, "Creador" VARCHAR, "Cambiar" BOOLEAN,
    "PrecioMinimo" BOOLEAN, "Credito" BOOLEAN
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT u."UserCode",
           u."PasswordHash",
           u."UserName",
           u."UserType",
           COALESCE(u."CanUpdate", TRUE),
           COALESCE(u."CanCreate", TRUE),
           COALESCE(u."CanDelete", TRUE),
           u."CreatedByUserId"::VARCHAR,
           COALESCE(u."CanChangePwd", TRUE),
           COALESCE(u."CanChangePrice", TRUE),
           COALESCE(u."CanGiveCredit", TRUE)
    FROM   sec."User" u
    WHERE  u."UserCode"  = p_cod_usuario
      AND  u."IsDeleted" = FALSE
    LIMIT 1;
END;
$$;

-- usp_Sec_User_GetType: tipo/rol del usuario
DROP FUNCTION IF EXISTS usp_Sec_User_GetType(VARCHAR(60)) CASCADE;
CREATE OR REPLACE FUNCTION usp_Sec_User_GetType(
    p_cod_usuario VARCHAR(60)
)
RETURNS TABLE("Cod_Usuario" VARCHAR, "Tipo" VARCHAR)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT u."UserCode", u."UserType"
    FROM   sec."User" u
    WHERE  u."UserCode"  = p_cod_usuario
      AND  u."IsDeleted" = FALSE
    LIMIT 1;
END;
$$;

-- usp_Sec_User_GetModuleAccess: permisos de mÃƒÂ³dulos
DROP FUNCTION IF EXISTS usp_Sec_User_GetModuleAccess(VARCHAR(60)) CASCADE;
CREATE OR REPLACE FUNCTION usp_Sec_User_GetModuleAccess(
    p_cod_usuario VARCHAR(60)
)
RETURNS TABLE("Cod_Usuario" VARCHAR, "Modulo" VARCHAR, "Permitido" BOOLEAN)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT a."UserCode", a."ModuleCode", a."IsAllowed"
    FROM   sec."UserModuleAccess" a
    WHERE  a."UserCode" = p_cod_usuario;
END;
$$;

-- usp_Sec_User_ListCompanyAccesses_Default: empresas/sucursales activas (admin)
DROP FUNCTION IF EXISTS usp_Sec_User_ListCompanyAccesses_Default() CASCADE;
CREATE OR REPLACE FUNCTION usp_Sec_User_ListCompanyAccesses_Default()
RETURNS TABLE(
    "companyId" INT, "companyCode" VARCHAR, "companyName" VARCHAR,
    "branchId" INT, "branchCode" VARCHAR, "branchName" VARCHAR,
    "countryCode" VARCHAR, "timeZone" VARCHAR, "isDefault" BOOLEAN
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        c."CompanyId",
        c."CompanyCode",
        COALESCE(NULLIF(c."TradeName", ''::VARCHAR), c."LegalName"),
        b."BranchId",
        b."BranchCode",
        b."BranchName",
        UPPER(COALESCE(NULLIF(b."CountryCode", ''::VARCHAR), c."FiscalCountryCode")),
        COALESCE(
            NULLIF(ct."TimeZoneIana", ''::VARCHAR),
            CASE UPPER(COALESCE(NULLIF(b."CountryCode", ''::VARCHAR), c."FiscalCountryCode"))
                WHEN 'ES' THEN 'Europe/Madrid'
                WHEN 'VE' THEN 'America/Caracas'
                ELSE 'UTC'
            END
        ),
        (c."CompanyCode" = 'DEFAULT' AND b."BranchCode" = 'MAIN')
    FROM cfg."Company" c
    INNER JOIN cfg."Branch" b
        ON b."CompanyId" = c."CompanyId"
    LEFT JOIN cfg."Country" ct
        ON ct."CountryCode" = UPPER(COALESCE(NULLIF(b."CountryCode", ''::VARCHAR), c."FiscalCountryCode"))
       AND ct."IsActive" = TRUE
    WHERE c."IsActive"  = TRUE
      AND c."IsDeleted" = FALSE
      AND b."IsActive"  = TRUE
      AND b."IsDeleted" = FALSE
    ORDER BY
        CASE WHEN c."CompanyCode" = 'DEFAULT' AND b."BranchCode" = 'MAIN'
             THEN 0 ELSE 1 END,
        c."CompanyId", b."BranchId";
END;
$$;

-- usp_Sec_User_GetCompanyAccesses: accesos empresa/sucursal de un usuario
DROP FUNCTION IF EXISTS usp_Sec_User_GetCompanyAccesses(VARCHAR(60)) CASCADE;
CREATE OR REPLACE FUNCTION usp_Sec_User_GetCompanyAccesses(
    p_cod_usuario VARCHAR(60)
)
RETURNS TABLE(
    "companyId" INT, "companyCode" VARCHAR, "companyName" VARCHAR,
    "branchId" INT, "branchCode" VARCHAR, "branchName" VARCHAR,
    "countryCode" VARCHAR, "timeZone" VARCHAR, "isDefault" BOOLEAN
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        a."CompanyId",
        c."CompanyCode",
        COALESCE(NULLIF(c."TradeName", ''::VARCHAR), c."LegalName"),
        a."BranchId",
        b."BranchCode",
        b."BranchName",
        UPPER(COALESCE(NULLIF(b."CountryCode", ''::VARCHAR), c."FiscalCountryCode")),
        COALESCE(
            NULLIF(ct."TimeZoneIana", ''::VARCHAR),
            CASE UPPER(COALESCE(NULLIF(b."CountryCode", ''::VARCHAR), c."FiscalCountryCode"))
                WHEN 'ES' THEN 'Europe/Madrid'
                WHEN 'VE' THEN 'America/Caracas'
                ELSE 'UTC'
            END
        ),
        a."IsDefault"
    FROM sec."UserCompanyAccess" a
    INNER JOIN cfg."Company" c
        ON c."CompanyId" = a."CompanyId"
       AND c."IsActive"  = TRUE
       AND c."IsDeleted" = FALSE
    INNER JOIN cfg."Branch" b
        ON b."BranchId"  = a."BranchId"
       AND b."CompanyId" = a."CompanyId"
       AND b."IsActive"  = TRUE
       AND b."IsDeleted" = FALSE
    LEFT JOIN cfg."Country" ct
        ON ct."CountryCode" = UPPER(COALESCE(NULLIF(b."CountryCode", ''::VARCHAR), c."FiscalCountryCode"))
       AND ct."IsActive" = TRUE
    WHERE UPPER(a."CodUsuario") = UPPER(p_cod_usuario)
      AND a."IsActive" = TRUE
    ORDER BY
        CASE WHEN a."IsDefault" = TRUE THEN 0 ELSE 1 END,
        a."CompanyId", a."BranchId";

EXCEPTION WHEN OTHERS THEN
    -- Si la tabla no existe, retornar vacÃƒÂ­o
    RETURN;
END;
$$;

-- usp_Sec_User_EnsureDefaultCompanyAccess: garantiza acceso a empresa DEFAULT
DROP FUNCTION IF EXISTS usp_Sec_User_EnsureDefaultCompanyAccess(VARCHAR(60)) CASCADE;
CREATE OR REPLACE FUNCTION usp_Sec_User_EnsureDefaultCompanyAccess(
    p_cod_usuario VARCHAR(60)
)
RETURNS VOID
LANGUAGE plpgsql AS $$
DECLARE
    v_company_id INT;
    v_branch_id  INT;
BEGIN
    -- Buscar empresa DEFAULT y sucursal MAIN
    SELECT c."CompanyId", b."BranchId"
    INTO   v_company_id, v_branch_id
    FROM   cfg."Company" c
    INNER JOIN cfg."Branch" b
        ON b."CompanyId"  = c."CompanyId"
       AND b."BranchCode" = 'MAIN'
       AND b."IsActive"   = TRUE
       AND b."IsDeleted"  = FALSE
    WHERE  c."CompanyCode" = 'DEFAULT'
      AND  c."IsActive"    = TRUE
      AND  c."IsDeleted"   = FALSE
    LIMIT 1;

    IF v_company_id IS NULL OR v_branch_id IS NULL THEN
        RETURN;
    END IF;

    -- UPSERT: insertar si no existe
    INSERT INTO sec."UserCompanyAccess"
        ("CodUsuario", "CompanyId", "BranchId", "IsActive", "IsDefault")
    VALUES
        (p_cod_usuario, v_company_id, v_branch_id, TRUE, TRUE)
    ON CONFLICT ("CodUsuario", "CompanyId", "BranchId")
    DO UPDATE SET "IsActive" = TRUE, "IsDefault" = TRUE,
                  "UpdatedAt" = NOW() AT TIME ZONE 'UTC';
END;
$$;

-- usp_Sec_User_SetModuleAccess: establece permisos desde JSON
DROP FUNCTION IF EXISTS usp_Sec_User_SetModuleAccess(VARCHAR(60), JSONB) CASCADE;
CREATE OR REPLACE FUNCTION usp_Sec_User_SetModuleAccess(
    p_cod_usuario  VARCHAR(60),
    p_modules_json JSONB
)
RETURNS VOID
LANGUAGE plpgsql AS $$
BEGIN
    -- Eliminar permisos actuales
    DELETE FROM sec."UserModuleAccess"
    WHERE  "UserCode" = p_cod_usuario;

    -- Insertar nuevos permisos desde JSONB array
    INSERT INTO sec."UserModuleAccess" ("UserCode", "ModuleCode", "IsAllowed")
    SELECT p_cod_usuario,
           elem->>'modulo',
           COALESCE((elem->>'permitido')::BOOLEAN, FALSE)
    FROM   jsonb_array_elements(p_modules_json) elem;
END;
$$;

-- usp_Sec_User_UpdatePassword: actualiza hash de contraseÃƒÂ±a
DROP FUNCTION IF EXISTS usp_Sec_User_UpdatePassword(VARCHAR(60), VARCHAR(255)) CASCADE;
CREATE OR REPLACE FUNCTION usp_Sec_User_UpdatePassword(
    p_cod_usuario  VARCHAR(60),
    p_password_hash VARCHAR(255)
)
RETURNS VOID
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE sec."User"
    SET    "PasswordHash" = p_password_hash,
           "UpdatedAt"    = NOW() AT TIME ZONE 'UTC'
    WHERE  "UserCode"  = p_cod_usuario
      AND  "IsDeleted" = FALSE;
END;
$$;

-- usp_Sec_User_GetAvatar: obtiene avatar del usuario
DROP FUNCTION IF EXISTS usp_Sec_User_GetAvatar(VARCHAR(60)) CASCADE;
CREATE OR REPLACE FUNCTION usp_Sec_User_GetAvatar(
    p_cod_usuario VARCHAR(60)
)
RETURNS TABLE("Avatar" TEXT)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT u."Avatar"
    FROM   sec."User" u
    WHERE  u."UserCode" = p_cod_usuario
    LIMIT 1;
END;
$$;

-- usp_Sec_User_SetAvatar: establece o elimina avatar
DROP FUNCTION IF EXISTS usp_Sec_User_SetAvatar(VARCHAR(60), TEXT) CASCADE;
CREATE OR REPLACE FUNCTION usp_Sec_User_SetAvatar(
    p_cod_usuario VARCHAR(60),
    p_avatar      TEXT DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE sec."User"
    SET    "Avatar"    = p_avatar,
           "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
    WHERE  "UserCode" = p_cod_usuario;
END;
$$;

-- usp_Sec_User_CheckExists: verifica si usuario existe
DROP FUNCTION IF EXISTS usp_Sec_User_CheckExists(VARCHAR(60)) CASCADE;
CREATE OR REPLACE FUNCTION usp_Sec_User_CheckExists(
    p_cod_usuario VARCHAR(60)
)
RETURNS TABLE("Cod_Usuario" VARCHAR)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT u."UserCode"
    FROM   sec."User" u
    WHERE  u."UserCode" = p_cod_usuario
    LIMIT 1;
END;
$$;
