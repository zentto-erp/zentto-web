-- +goose Up
-- Migration: license_enforcement_rbac
-- Adds license enforcement columns, plan definition tables, and RBAC SPs.

-- =============================================================================
-- 1. Add columns to sys."License" (if not exist)
-- =============================================================================
ALTER TABLE sys."License"
    ADD COLUMN IF NOT EXISTS "MaxCompanies" INTEGER DEFAULT NULL,
    ADD COLUMN IF NOT EXISTS "MultiCompanyEnabled" BOOLEAN DEFAULT TRUE;

-- MaxBranches already exists — no action needed.

-- =============================================================================
-- 2. Create cfg."PlanDefinition"
-- =============================================================================
CREATE TABLE IF NOT EXISTS cfg."PlanDefinition" (
    "PlanCode"          VARCHAR(30)    NOT NULL PRIMARY KEY,
    "PlanName"          VARCHAR(100)   NOT NULL,
    "MaxUsers"          INTEGER,
    "MaxCompanies"      INTEGER,
    "MaxBranches"       INTEGER,
    "MultiCompanyEnabled" BOOLEAN      DEFAULT FALSE,
    "MonthlyPriceUsd"   NUMERIC(10,2),
    "AnnualPriceUsd"    NUMERIC(10,2),
    "IsActive"          BOOLEAN        DEFAULT TRUE,
    "SortOrder"         INTEGER        DEFAULT 0,
    "CreatedAt"         TIMESTAMP      DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "UpdatedAt"         TIMESTAMP      DEFAULT (NOW() AT TIME ZONE 'UTC')
);

-- =============================================================================
-- 3. Create cfg."PlanModule"
-- =============================================================================
CREATE TABLE IF NOT EXISTS cfg."PlanModule" (
    "PlanModuleId" SERIAL PRIMARY KEY,
    "PlanCode"     VARCHAR(30)  NOT NULL REFERENCES cfg."PlanDefinition"("PlanCode"),
    "ModuleCode"   VARCHAR(60)  NOT NULL,
    "IsIncluded"   BOOLEAN      DEFAULT TRUE,
    UNIQUE("PlanCode", "ModuleCode")
);

-- =============================================================================
-- 4. Seed PlanDefinition
-- =============================================================================
INSERT INTO cfg."PlanDefinition" ("PlanCode","PlanName","MaxUsers","MaxCompanies","MaxBranches","MultiCompanyEnabled","MonthlyPriceUsd","AnnualPriceUsd","IsActive","SortOrder")
VALUES
    ('FREE',       'Gratuito',      2,    1,    1,    FALSE, 0,      0,       TRUE, 1),
    ('STARTER',    'Iniciador',     5,    1,    2,    FALSE, 29.99,  299.99,  TRUE, 2),
    ('PRO',        'Profesional',  15,    3,    5,    TRUE,  79.99,  799.99,  TRUE, 3),
    ('ENTERPRISE', 'Empresarial', NULL, NULL, NULL,   TRUE,  199.99, 1999.99, TRUE, 4)
ON CONFLICT ("PlanCode") DO UPDATE SET
    "PlanName"             = EXCLUDED."PlanName",
    "MaxUsers"             = EXCLUDED."MaxUsers",
    "MaxCompanies"         = EXCLUDED."MaxCompanies",
    "MaxBranches"          = EXCLUDED."MaxBranches",
    "MultiCompanyEnabled"  = EXCLUDED."MultiCompanyEnabled",
    "MonthlyPriceUsd"      = EXCLUDED."MonthlyPriceUsd",
    "AnnualPriceUsd"       = EXCLUDED."AnnualPriceUsd",
    "IsActive"             = EXCLUDED."IsActive",
    "SortOrder"            = EXCLUDED."SortOrder",
    "UpdatedAt"            = (NOW() AT TIME ZONE 'UTC');

-- =============================================================================
-- 5. Seed PlanModule
-- =============================================================================
INSERT INTO cfg."PlanModule" ("PlanCode", "ModuleCode") VALUES
    -- FREE
    ('FREE', 'dashboard'),
    ('FREE', 'facturas'),
    ('FREE', 'clientes'),
    ('FREE', 'inventario'),
    ('FREE', 'articulos'),
    ('FREE', 'reportes'),
    -- STARTER (includes FREE modules + more)
    ('STARTER', 'dashboard'),
    ('STARTER', 'facturas'),
    ('STARTER', 'clientes'),
    ('STARTER', 'inventario'),
    ('STARTER', 'articulos'),
    ('STARTER', 'reportes'),
    ('STARTER', 'abonos'),
    ('STARTER', 'cxc'),
    ('STARTER', 'compras'),
    ('STARTER', 'cxp'),
    ('STARTER', 'cuentas-por-pagar'),
    ('STARTER', 'proveedores'),
    ('STARTER', 'pagos'),
    ('STARTER', 'bancos'),
    ('STARTER', 'configuracion'),
    ('STARTER', 'usuarios'),
    -- PRO (includes STARTER modules + more)
    ('PRO', 'dashboard'),
    ('PRO', 'facturas'),
    ('PRO', 'clientes'),
    ('PRO', 'inventario'),
    ('PRO', 'articulos'),
    ('PRO', 'reportes'),
    ('PRO', 'abonos'),
    ('PRO', 'cxc'),
    ('PRO', 'compras'),
    ('PRO', 'cxp'),
    ('PRO', 'cuentas-por-pagar'),
    ('PRO', 'proveedores'),
    ('PRO', 'pagos'),
    ('PRO', 'bancos'),
    ('PRO', 'configuracion'),
    ('PRO', 'usuarios'),
    ('PRO', 'contabilidad'),
    ('PRO', 'nomina'),
    ('PRO', 'pos'),
    ('PRO', 'restaurante'),
    ('PRO', 'ecommerce'),
    ('PRO', 'auditoria'),
    ('PRO', 'logistica'),
    ('PRO', 'crm'),
    ('PRO', 'shipping'),
    -- ENTERPRISE (includes PRO modules + more)
    ('ENTERPRISE', 'dashboard'),
    ('ENTERPRISE', 'facturas'),
    ('ENTERPRISE', 'clientes'),
    ('ENTERPRISE', 'inventario'),
    ('ENTERPRISE', 'articulos'),
    ('ENTERPRISE', 'reportes'),
    ('ENTERPRISE', 'abonos'),
    ('ENTERPRISE', 'cxc'),
    ('ENTERPRISE', 'compras'),
    ('ENTERPRISE', 'cxp'),
    ('ENTERPRISE', 'cuentas-por-pagar'),
    ('ENTERPRISE', 'proveedores'),
    ('ENTERPRISE', 'pagos'),
    ('ENTERPRISE', 'bancos'),
    ('ENTERPRISE', 'configuracion'),
    ('ENTERPRISE', 'usuarios'),
    ('ENTERPRISE', 'contabilidad'),
    ('ENTERPRISE', 'nomina'),
    ('ENTERPRISE', 'pos'),
    ('ENTERPRISE', 'restaurante'),
    ('ENTERPRISE', 'ecommerce'),
    ('ENTERPRISE', 'auditoria'),
    ('ENTERPRISE', 'logistica'),
    ('ENTERPRISE', 'crm'),
    ('ENTERPRISE', 'shipping'),
    ('ENTERPRISE', 'manufactura'),
    ('ENTERPRISE', 'flota')
ON CONFLICT ("PlanCode", "ModuleCode") DO NOTHING;

-- =============================================================================
-- 6. SP: usp_Sys_License_CheckUserLimit
-- =============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_sys_license_checkuserlimit(
    p_company_id INTEGER
)
RETURNS TABLE(
    "allowed"      BOOLEAN,
    "currentUsers" INTEGER,
    "maxUsers"     INTEGER,
    "plan"         VARCHAR
)
LANGUAGE plpgsql AS $$
DECLARE
    v_current_users INTEGER;
    v_max_users     INTEGER;
    v_plan          VARCHAR;
BEGIN
    -- Get current active user count for this company
    SELECT COUNT(*)::INTEGER
      INTO v_current_users
      FROM sec."User"
     WHERE "CompanyId" = p_company_id
       AND "IsActive" = TRUE
       AND "IsDeleted" = FALSE;

    -- Get limit from sys."License" joined with cfg."PlanDefinition"
    SELECT COALESCE(l."MaxUsers", pd."MaxUsers"),
           COALESCE(l."Plan", 'FREE'::VARCHAR)
      INTO v_max_users, v_plan
      FROM sys."License" l
      LEFT JOIN cfg."PlanDefinition" pd ON pd."PlanCode" = l."Plan"
     WHERE l."CompanyId" = p_company_id
       AND l."Status" = 'ACTIVE'
     ORDER BY l."ExpiresAt" DESC NULLS FIRST
     LIMIT 1;

    -- If no license found, try PlanDefinition FREE defaults
    IF v_plan IS NULL THEN
        SELECT pd."MaxUsers", pd."PlanCode"::VARCHAR
          INTO v_max_users, v_plan
          FROM cfg."PlanDefinition" pd
         WHERE pd."PlanCode" = 'FREE';
    END IF;

    RETURN QUERY
    SELECT
        CASE WHEN v_max_users IS NULL THEN TRUE
             WHEN v_current_users < v_max_users THEN TRUE
             ELSE FALSE
        END AS "allowed",
        v_current_users AS "currentUsers",
        v_max_users     AS "maxUsers",
        v_plan          AS "plan";
END;
$$;
-- +goose StatementEnd

-- =============================================================================
-- 7. SP: usp_Sys_License_CheckCompanyLimit
-- =============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_sys_license_checkcompanylimit(
    p_company_id INTEGER
)
RETURNS TABLE(
    "allowed"              BOOLEAN,
    "currentCompanies"     INTEGER,
    "maxCompanies"         INTEGER,
    "multiCompanyEnabled"  BOOLEAN,
    "plan"                 VARCHAR
)
LANGUAGE plpgsql AS $$
DECLARE
    v_current_companies    INTEGER;
    v_max_companies        INTEGER;
    v_multi_enabled        BOOLEAN;
    v_plan                 VARCHAR;
BEGIN
    -- Count active companies
    SELECT COUNT(*)::INTEGER
      INTO v_current_companies
      FROM cfg."Company"
     WHERE "IsActive" = TRUE
       AND "IsDeleted" = FALSE;

    -- Get limits from license + plan definition
    SELECT COALESCE(l."MaxCompanies", pd."MaxCompanies"),
           COALESCE(l."MultiCompanyEnabled", pd."MultiCompanyEnabled", FALSE),
           COALESCE(l."Plan", 'FREE'::VARCHAR)
      INTO v_max_companies, v_multi_enabled, v_plan
      FROM sys."License" l
      LEFT JOIN cfg."PlanDefinition" pd ON pd."PlanCode" = l."Plan"
     WHERE l."CompanyId" = p_company_id
       AND l."Status" = 'ACTIVE'
     ORDER BY l."ExpiresAt" DESC NULLS FIRST
     LIMIT 1;

    -- Fallback to FREE plan
    IF v_plan IS NULL THEN
        SELECT pd."MaxCompanies", pd."MultiCompanyEnabled", pd."PlanCode"::VARCHAR
          INTO v_max_companies, v_multi_enabled, v_plan
          FROM cfg."PlanDefinition" pd
         WHERE pd."PlanCode" = 'FREE';
    END IF;

    RETURN QUERY
    SELECT
        CASE
            WHEN v_multi_enabled = FALSE AND v_current_companies >= 1 THEN FALSE
            WHEN v_max_companies IS NULL THEN TRUE
            WHEN v_current_companies < v_max_companies THEN TRUE
            ELSE FALSE
        END AS "allowed",
        v_current_companies AS "currentCompanies",
        v_max_companies     AS "maxCompanies",
        v_multi_enabled     AS "multiCompanyEnabled",
        v_plan              AS "plan";
END;
$$;
-- +goose StatementEnd

-- =============================================================================
-- 8. SP: usp_Sec_Role_List
-- =============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_sec_role_list(
    p_company_id INTEGER
)
RETURNS TABLE(
    "RoleId"    INTEGER,
    "RoleCode"  VARCHAR,
    "RoleName"  VARCHAR,
    "IsSystem"  BOOLEAN,
    "IsActive"  BOOLEAN,
    "UserCount" BIGINT
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT r."RoleId",
           r."RoleCode"::VARCHAR,
           r."RoleName"::VARCHAR,
           r."IsSystem",
           r."IsActive",
           COALESCE(uc.cnt, 0) AS "UserCount"
      FROM sec."Role" r
      LEFT JOIN (
          SELECT ur."RoleId", COUNT(*)::BIGINT AS cnt
            FROM sec."UserRole" ur
            JOIN sec."User" u ON u."UserId" = ur."UserId"
           WHERE u."CompanyId" = p_company_id
             AND u."IsActive" = TRUE
             AND u."IsDeleted" = FALSE
           GROUP BY ur."RoleId"
      ) uc ON uc."RoleId" = r."RoleId"
     WHERE r."IsActive" = TRUE
     ORDER BY r."RoleId";
END;
$$;
-- +goose StatementEnd

-- =============================================================================
-- 9. SP: usp_Sec_Role_Upsert
-- =============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_sec_role_upsert(
    p_role_id   INTEGER,
    p_role_code VARCHAR,
    p_role_name VARCHAR,
    p_is_system BOOLEAN DEFAULT FALSE,
    p_is_active BOOLEAN DEFAULT TRUE
)
RETURNS TABLE("ok" BOOLEAN, "mensaje" VARCHAR)
LANGUAGE plpgsql AS $$
DECLARE
    v_id INTEGER;
BEGIN
    IF p_role_id IS NOT NULL AND p_role_id > 0 THEN
        -- UPDATE
        UPDATE sec."Role"
           SET "RoleCode"  = COALESCE(p_role_code, "RoleCode"),
               "RoleName"  = COALESCE(p_role_name, "RoleName"),
               "IsSystem"  = COALESCE(p_is_system, "IsSystem"),
               "IsActive"  = COALESCE(p_is_active, "IsActive"),
               "UpdatedAt" = (NOW() AT TIME ZONE 'UTC')
         WHERE "RoleId" = p_role_id;

        IF NOT FOUND THEN
            RETURN QUERY SELECT FALSE::BOOLEAN, 'Rol no encontrado'::VARCHAR;
            RETURN;
        END IF;

        RETURN QUERY SELECT TRUE::BOOLEAN, 'Rol actualizado'::VARCHAR;
    ELSE
        -- INSERT
        INSERT INTO sec."Role" ("RoleCode", "RoleName", "IsSystem", "IsActive")
        VALUES (p_role_code, p_role_name, COALESCE(p_is_system, FALSE), COALESCE(p_is_active, TRUE))
        RETURNING "RoleId" INTO v_id;

        RETURN QUERY SELECT TRUE::BOOLEAN, ('Rol creado con Id ' || v_id)::VARCHAR;
    END IF;
END;
$$;
-- +goose StatementEnd

-- =============================================================================
-- 10. SP: usp_Sec_Role_Delete
-- =============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_sec_role_delete(
    p_role_id INTEGER
)
RETURNS TABLE("ok" BOOLEAN, "mensaje" VARCHAR)
LANGUAGE plpgsql AS $$
DECLARE
    v_is_system BOOLEAN;
BEGIN
    SELECT "IsSystem" INTO v_is_system
      FROM sec."Role"
     WHERE "RoleId" = p_role_id;

    IF NOT FOUND THEN
        RETURN QUERY SELECT FALSE::BOOLEAN, 'Rol no encontrado'::VARCHAR;
        RETURN;
    END IF;

    IF v_is_system = TRUE THEN
        RETURN QUERY SELECT FALSE::BOOLEAN, 'No se puede eliminar un rol de sistema'::VARCHAR;
        RETURN;
    END IF;

    -- Soft delete: mark as inactive
    UPDATE sec."Role"
       SET "IsActive"  = FALSE,
           "UpdatedAt" = (NOW() AT TIME ZONE 'UTC')
     WHERE "RoleId" = p_role_id;

    RETURN QUERY SELECT TRUE::BOOLEAN, 'Rol desactivado'::VARCHAR;
END;
$$;
-- +goose StatementEnd

-- =============================================================================
-- 11. SP: usp_Sec_UserRole_Set
-- =============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_sec_userrole_set(
    p_user_id  INTEGER,
    p_role_ids INTEGER[]
)
RETURNS TABLE("ok" BOOLEAN, "mensaje" VARCHAR)
LANGUAGE plpgsql AS $$
BEGIN
    -- Remove existing roles for user
    DELETE FROM sec."UserRole"
     WHERE "UserId" = p_user_id;

    -- Insert new roles
    INSERT INTO sec."UserRole" ("UserId", "RoleId")
    SELECT p_user_id, unnest(p_role_ids);

    RETURN QUERY SELECT TRUE::BOOLEAN,
        ('Asignados ' || array_length(p_role_ids, 1) || ' roles al usuario ' || p_user_id)::VARCHAR;
END;
$$;
-- +goose StatementEnd

-- =============================================================================
-- 12. SP: usp_Sec_UserRole_List
-- =============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_sec_userrole_list(
    p_user_id INTEGER
)
RETURNS TABLE(
    "UserRoleId" BIGINT,
    "RoleId"     INTEGER,
    "RoleCode"   VARCHAR,
    "RoleName"   VARCHAR,
    "IsSystem"   BOOLEAN,
    "AssignedAt" TIMESTAMP
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT ur."UserRoleId",
           r."RoleId",
           r."RoleCode"::VARCHAR,
           r."RoleName"::VARCHAR,
           r."IsSystem",
           ur."CreatedAt" AS "AssignedAt"
      FROM sec."UserRole" ur
      JOIN sec."Role" r ON r."RoleId" = ur."RoleId"
     WHERE ur."UserId" = p_user_id
       AND r."IsActive" = TRUE
     ORDER BY r."RoleId";
END;
$$;
-- +goose StatementEnd


-- +goose Down

-- Drop functions in reverse order
DROP FUNCTION IF EXISTS public.usp_sec_userrole_list(INTEGER);
DROP FUNCTION IF EXISTS public.usp_sec_userrole_set(INTEGER, INTEGER[]);
DROP FUNCTION IF EXISTS public.usp_sec_role_delete(INTEGER);
DROP FUNCTION IF EXISTS public.usp_sec_role_upsert(INTEGER, VARCHAR, VARCHAR, BOOLEAN, BOOLEAN);
DROP FUNCTION IF EXISTS public.usp_sec_role_list(INTEGER);
DROP FUNCTION IF EXISTS public.usp_sys_license_checkcompanylimit(INTEGER);
DROP FUNCTION IF EXISTS public.usp_sys_license_checkuserlimit(INTEGER);

-- Drop tables
DROP TABLE IF EXISTS cfg."PlanModule";
DROP TABLE IF EXISTS cfg."PlanDefinition";

-- Remove added columns from sys."License"
ALTER TABLE sys."License"
    DROP COLUMN IF EXISTS "MaxCompanies",
    DROP COLUMN IF EXISTS "MultiCompanyEnabled";
