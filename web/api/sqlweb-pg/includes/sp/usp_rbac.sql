/*
 * ============================================================================
 *  Archivo : usp_rbac.sql  (PostgreSQL)
 *  Esquemas: sec (tablas)
 *
 *  Descripcion:
 *    Funciones para el modulo RBAC (Role-Based Access Control).
 *    Permisos granulares, restricciones de precio, reglas de aprobacion.
 *
 *  Convenciones:
 *    - Nombrado: usp_sec_[entity]_[action]
 *    - Patron: CREATE OR REPLACE FUNCTION ... LANGUAGE plpgsql
 * ============================================================================
 */

-- =============================================================================
--  SECCION 1: PERMISOS (Permission Catalog)
-- =============================================================================

-- usp_Sec_Permission_List
DROP FUNCTION IF EXISTS usp_sec_permission_list(VARCHAR) CASCADE;
CREATE OR REPLACE FUNCTION usp_sec_permission_list(
    p_module_code VARCHAR(50) DEFAULT NULL
)
RETURNS TABLE(
    "PermissionId"   INT,
    "ModuleCode"     VARCHAR,
    "PermissionCode" VARCHAR,
    "PermissionName" VARCHAR,
    "Description"    VARCHAR,
    "SortOrder"      INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        p."PermissionId",
        p."ModuleCode"::VARCHAR,
        p."PermissionCode"::VARCHAR,
        p."PermissionName"::VARCHAR,
        p."Description"::VARCHAR,
        p."SortOrder"
    FROM sec."Permission" p
    WHERE (p_module_code IS NULL OR p."ModuleCode" = p_module_code)
    ORDER BY p."ModuleCode", p."SortOrder", p."PermissionCode";
END;
$$;

-- usp_Sec_Permission_Seed
DROP FUNCTION IF EXISTS usp_sec_permission_seed() CASCADE;
CREATE OR REPLACE FUNCTION usp_sec_permission_seed()
RETURNS TABLE("InsertedCount" INT)
LANGUAGE plpgsql
AS $$
DECLARE
    v_count INT := 0;
BEGIN
    -- Crear tabla temporal con permisos
    CREATE TEMP TABLE IF NOT EXISTS _perms (
        module_code     VARCHAR(50),
        permission_code VARCHAR(100),
        permission_name VARCHAR(200),
        sort_order      INT
    ) ON COMMIT DROP;

    TRUNCATE _perms;

    INSERT INTO _perms (module_code, permission_code, permission_name, sort_order)
    SELECT m.code, m.code || '.' || a.action, m.nombre || ' - ' || a.action_name, a.sort
    FROM (VALUES
        ('ventas',       'Ventas'),
        ('compras',      'Compras'),
        ('inventario',   'Inventario'),
        ('bancos',       'Bancos'),
        ('contabilidad', 'Contabilidad'),
        ('nomina',       'Nomina'),
        ('rrhh',         'Recursos Humanos'),
        ('pos',          'Punto de Venta'),
        ('restaurante',  'Restaurante'),
        ('auditoria',    'Auditoria'),
        ('crm',          'CRM'),
        ('manufactura',  'Manufactura'),
        ('flota',        'Flota')
    ) AS m(code, nombre)
    CROSS JOIN (VALUES
        ('VIEW',   'Ver',      1),
        ('CREATE', 'Crear',    2),
        ('EDIT',   'Editar',   3),
        ('DELETE', 'Eliminar', 4),
        ('VOID',   'Anular',   5)
    ) AS a(action, action_name, sort);

    -- Insertar solo los que no existen
    INSERT INTO sec."Permission" ("ModuleCode", "PermissionCode", "PermissionName", "SortOrder", "CreatedAt")
    SELECT p.module_code, p.permission_code, p.permission_name, p.sort_order, NOW() AT TIME ZONE 'UTC'
    FROM _perms p
    WHERE NOT EXISTS (
        SELECT 1 FROM sec."Permission" ep WHERE ep."PermissionCode" = p.permission_code
    );

    GET DIAGNOSTICS v_count = ROW_COUNT;

    RETURN QUERY SELECT v_count;
END;
$$;

-- =============================================================================
--  SECCION 2: PERMISOS POR ROL (Role Permissions)
-- =============================================================================

-- usp_Sec_RolePermission_List
DROP FUNCTION IF EXISTS usp_sec_rolepermission_list(INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_sec_rolepermission_list(
    p_role_id INT
)
RETURNS TABLE(
    "PermissionId"   INT,
    "ModuleCode"     VARCHAR,
    "PermissionCode" VARCHAR,
    "PermissionName" VARCHAR,
    "IsGranted"      BOOLEAN,
    "BranchId"       INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        p."PermissionId",
        p."ModuleCode"::VARCHAR,
        p."PermissionCode"::VARCHAR,
        p."PermissionName"::VARCHAR,
        CASE WHEN rp."RolePermissionId" IS NOT NULL THEN TRUE ELSE FALSE END,
        rp."BranchId"
    FROM sec."Permission" p
    LEFT JOIN sec."RolePermission" rp ON rp."PermissionId" = p."PermissionId"
        AND rp."RoleId" = p_role_id
        AND rp."IsGranted" = TRUE
    ORDER BY p."ModuleCode", p."SortOrder";
END;
$$;

-- usp_Sec_RolePermission_Set
DROP FUNCTION IF EXISTS usp_sec_rolepermission_set(INT, INT, INT, BOOLEAN, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_sec_rolepermission_set(
    p_role_id       INT,
    p_permission_id INT,
    p_branch_id     INT DEFAULT NULL,
    p_is_granted    BOOLEAN DEFAULT TRUE,
    p_user_id       INT DEFAULT NULL
)
RETURNS TABLE("ok" INT, "mensaje" VARCHAR)
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_is_granted THEN
        IF NOT EXISTS (
            SELECT 1 FROM sec."RolePermission"
            WHERE "RoleId" = p_role_id AND "PermissionId" = p_permission_id
              AND COALESCE("BranchId", 0) = COALESCE(p_branch_id, 0)
        ) THEN
            INSERT INTO sec."RolePermission" ("RoleId", "PermissionId", "BranchId", "IsGranted", "CreatedAt", "CreatedBy")
            VALUES (p_role_id, p_permission_id, p_branch_id, TRUE, NOW() AT TIME ZONE 'UTC', p_user_id);
        ELSE
            UPDATE sec."RolePermission" SET "IsGranted" = TRUE, "UpdatedAt" = NOW() AT TIME ZONE 'UTC', "UpdatedBy" = p_user_id
            WHERE "RoleId" = p_role_id AND "PermissionId" = p_permission_id
              AND COALESCE("BranchId", 0) = COALESCE(p_branch_id, 0);
        END IF;
    ELSE
        DELETE FROM sec."RolePermission"
        WHERE "RoleId" = p_role_id AND "PermissionId" = p_permission_id
          AND COALESCE("BranchId", 0) = COALESCE(p_branch_id, 0);
    END IF;

    RETURN QUERY SELECT 1, 'Permiso actualizado'::VARCHAR;

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -1, SQLERRM::VARCHAR;
END;
$$;

-- usp_Sec_RolePermission_BulkSet
DROP FUNCTION IF EXISTS usp_sec_rolepermission_bulkset(INT, VARCHAR, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_sec_rolepermission_bulkset(
    p_role_id          INT,
    p_permissions_json VARCHAR,
    p_user_id          INT DEFAULT NULL
)
RETURNS TABLE("ok" INT, "mensaje" VARCHAR)
LANGUAGE plpgsql
AS $$
DECLARE
    v_count INT;
BEGIN
    -- Eliminar permisos actuales del rol
    DELETE FROM sec."RolePermission" WHERE "RoleId" = p_role_id;

    -- Insertar los nuevos
    INSERT INTO sec."RolePermission" ("RoleId", "PermissionId", "BranchId", "IsGranted", "CreatedAt", "CreatedBy")
    SELECT
        p_role_id,
        (j->>'permissionId')::INT,
        (j->>'branchId')::INT,
        TRUE,
        NOW() AT TIME ZONE 'UTC',
        p_user_id
    FROM jsonb_array_elements(p_permissions_json::JSONB) AS j
    WHERE (j->>'isGranted')::BOOLEAN = TRUE;

    GET DIAGNOSTICS v_count = ROW_COUNT;

    RETURN QUERY SELECT 1, (v_count::TEXT || ' permisos asignados')::VARCHAR;

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -1, SQLERRM::VARCHAR;
END;
$$;

-- =============================================================================
--  SECCION 3: PERMISOS DE USUARIO (User Permission Overrides)
-- =============================================================================

-- usp_Sec_UserPermission_List
DROP FUNCTION IF EXISTS usp_sec_userpermission_list(INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_sec_userpermission_list(
    p_user_id INT
)
RETURNS TABLE(
    "PermissionId"   INT,
    "ModuleCode"     VARCHAR,
    "PermissionCode" VARCHAR,
    "PermissionName" VARCHAR,
    "IsGranted"      BOOLEAN,
    "Source"         VARCHAR
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_role_id INT;
BEGIN
    SELECT "RoleId" INTO v_role_id FROM sec."User" WHERE "UserId" = p_user_id;

    RETURN QUERY
    SELECT
        p."PermissionId",
        p."ModuleCode"::VARCHAR,
        p."PermissionCode"::VARCHAR,
        p."PermissionName"::VARCHAR,
        CASE
            WHEN upo."OverrideId" IS NOT NULL THEN upo."IsGranted"
            WHEN rp."RolePermissionId" IS NOT NULL THEN rp."IsGranted"
            ELSE FALSE
        END,
        CASE
            WHEN upo."OverrideId" IS NOT NULL THEN 'OVERRIDE'::VARCHAR
            WHEN rp."RolePermissionId" IS NOT NULL THEN 'ROLE'::VARCHAR
            ELSE 'DEFAULT'::VARCHAR
        END
    FROM sec."Permission" p
    LEFT JOIN sec."RolePermission" rp ON rp."PermissionId" = p."PermissionId" AND rp."RoleId" = v_role_id
    LEFT JOIN sec."UserPermissionOverride" upo ON upo."PermissionId" = p."PermissionId" AND upo."UserId" = p_user_id
    ORDER BY p."ModuleCode", p."SortOrder";
END;
$$;

-- usp_Sec_UserPermission_Override
DROP FUNCTION IF EXISTS usp_sec_userpermission_override(INT, INT, INT, BOOLEAN, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_sec_userpermission_override(
    p_user_id       INT,
    p_permission_id INT,
    p_branch_id     INT DEFAULT NULL,
    p_is_granted    BOOLEAN DEFAULT TRUE,
    p_admin_user_id INT DEFAULT NULL
)
RETURNS TABLE("ok" INT, "mensaje" VARCHAR)
LANGUAGE plpgsql
AS $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM sec."UserPermissionOverride"
        WHERE "UserId" = p_user_id AND "PermissionId" = p_permission_id
          AND COALESCE("BranchId", 0) = COALESCE(p_branch_id, 0)
    ) THEN
        UPDATE sec."UserPermissionOverride" SET
            "IsGranted" = p_is_granted,
            "UpdatedAt" = NOW() AT TIME ZONE 'UTC',
            "UpdatedBy" = p_admin_user_id
        WHERE "UserId" = p_user_id AND "PermissionId" = p_permission_id
          AND COALESCE("BranchId", 0) = COALESCE(p_branch_id, 0);
    ELSE
        INSERT INTO sec."UserPermissionOverride" ("UserId", "PermissionId", "BranchId", "IsGranted", "CreatedAt", "CreatedBy")
        VALUES (p_user_id, p_permission_id, p_branch_id, p_is_granted, NOW() AT TIME ZONE 'UTC', p_admin_user_id);
    END IF;

    RETURN QUERY SELECT 1, 'Override aplicado'::VARCHAR;

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -1, SQLERRM::VARCHAR;
END;
$$;

-- usp_Sec_UserPermission_Check
DROP FUNCTION IF EXISTS usp_sec_userpermission_check(INT, VARCHAR) CASCADE;
CREATE OR REPLACE FUNCTION usp_sec_userpermission_check(
    p_user_id        INT,
    p_permission_code VARCHAR(100)
)
RETURNS TABLE("HasPermission" BOOLEAN)
LANGUAGE plpgsql
AS $$
DECLARE
    v_role_id       INT;
    v_permission_id INT;
    v_override      BOOLEAN;
BEGIN
    SELECT "RoleId" INTO v_role_id FROM sec."User" WHERE "UserId" = p_user_id;
    SELECT "PermissionId" INTO v_permission_id FROM sec."Permission" WHERE "PermissionCode" = p_permission_code;

    IF v_permission_id IS NULL THEN
        RETURN QUERY SELECT FALSE;
        RETURN;
    END IF;

    -- 1. Check user override
    SELECT upo."IsGranted" INTO v_override
    FROM sec."UserPermissionOverride" upo
    WHERE upo."UserId" = p_user_id AND upo."PermissionId" = v_permission_id
    LIMIT 1;

    IF v_override IS NOT NULL THEN
        RETURN QUERY SELECT v_override;
        RETURN;
    END IF;

    -- 2. Check role permission
    IF EXISTS (
        SELECT 1 FROM sec."RolePermission"
        WHERE "RoleId" = v_role_id AND "PermissionId" = v_permission_id AND "IsGranted" = TRUE
    ) THEN
        RETURN QUERY SELECT TRUE;
        RETURN;
    END IF;

    -- 3. Default deny
    RETURN QUERY SELECT FALSE;
END;
$$;

-- =============================================================================
--  SECCION 4: RESTRICCIONES DE PRECIO
-- =============================================================================

-- usp_Sec_PriceRestriction_List
DROP FUNCTION IF EXISTS usp_sec_pricerestriction_list(INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_sec_pricerestriction_list(
    p_company_id INT
)
RETURNS TABLE(
    "RestrictionId"        INT,
    "RoleId"               INT,
    "RoleName"             VARCHAR,
    "UserId_Target"        INT,
    "MaxDiscountPercent"   NUMERIC,
    "MinPricePercent"      NUMERIC,
    "MaxCreditLimit"       NUMERIC,
    "RequiresApprovalAbove" NUMERIC,
    "CreatedAt"            TIMESTAMP
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        pr."RestrictionId",
        pr."RoleId",
        r."RoleName"::VARCHAR,
        pr."UserId_Target",
        pr."MaxDiscountPercent",
        pr."MinPricePercent",
        pr."MaxCreditLimit",
        pr."RequiresApprovalAbove",
        pr."CreatedAt"
    FROM sec."PriceRestriction" pr
    LEFT JOIN sec."Role" r ON r."RoleId" = pr."RoleId"
    WHERE pr."CompanyId" = p_company_id
    ORDER BY pr."RoleId", pr."UserId_Target";
END;
$$;

-- usp_Sec_PriceRestriction_Upsert
DROP FUNCTION IF EXISTS usp_sec_pricerestriction_upsert(INT, INT, INT, INT, NUMERIC, NUMERIC, NUMERIC, NUMERIC, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_sec_pricerestriction_upsert(
    p_company_id              INT,
    p_restriction_id          INT DEFAULT NULL,
    p_role_id                 INT DEFAULT NULL,
    p_user_id_target          INT DEFAULT NULL,
    p_max_discount_percent    NUMERIC(5,2) DEFAULT 0,
    p_min_price_percent       NUMERIC(5,2) DEFAULT 0,
    p_max_credit_limit        NUMERIC(18,2) DEFAULT NULL,
    p_requires_approval_above NUMERIC(18,2) DEFAULT NULL,
    p_admin_user_id           INT DEFAULT NULL
)
RETURNS TABLE("ok" INT, "mensaje" VARCHAR)
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_restriction_id IS NOT NULL AND EXISTS (SELECT 1 FROM sec."PriceRestriction" WHERE "RestrictionId" = p_restriction_id) THEN
        UPDATE sec."PriceRestriction" SET
            "RoleId"                 = p_role_id,
            "UserId_Target"          = p_user_id_target,
            "MaxDiscountPercent"     = p_max_discount_percent,
            "MinPricePercent"        = p_min_price_percent,
            "MaxCreditLimit"         = p_max_credit_limit,
            "RequiresApprovalAbove"  = p_requires_approval_above,
            "UpdatedAt"              = NOW() AT TIME ZONE 'UTC',
            "UpdatedBy"              = p_admin_user_id
        WHERE "RestrictionId" = p_restriction_id;

        RETURN QUERY SELECT 1, 'Restriccion actualizada'::VARCHAR;
    ELSE
        INSERT INTO sec."PriceRestriction" (
            "CompanyId", "RoleId", "UserId_Target", "MaxDiscountPercent", "MinPricePercent",
            "MaxCreditLimit", "RequiresApprovalAbove", "CreatedAt", "CreatedBy"
        ) VALUES (
            p_company_id, p_role_id, p_user_id_target, p_max_discount_percent, p_min_price_percent,
            p_max_credit_limit, p_requires_approval_above, NOW() AT TIME ZONE 'UTC', p_admin_user_id
        );

        RETURN QUERY SELECT 1, 'Restriccion creada'::VARCHAR;
    END IF;

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -1, SQLERRM::VARCHAR;
END;
$$;

-- usp_Sec_PriceRestriction_Check
DROP FUNCTION IF EXISTS usp_sec_pricerestriction_check(INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_sec_pricerestriction_check(
    p_user_id    INT,
    p_company_id INT
)
RETURNS TABLE(
    "RestrictionId"        INT,
    "MaxDiscountPercent"   NUMERIC,
    "MinPricePercent"      NUMERIC,
    "MaxCreditLimit"       NUMERIC,
    "RequiresApprovalAbove" NUMERIC
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_role_id INT;
BEGIN
    SELECT "RoleId" INTO v_role_id FROM sec."User" WHERE "UserId" = p_user_id;

    RETURN QUERY
    SELECT
        pr."RestrictionId",
        pr."MaxDiscountPercent",
        pr."MinPricePercent",
        pr."MaxCreditLimit",
        pr."RequiresApprovalAbove"
    FROM sec."PriceRestriction" pr
    WHERE pr."CompanyId" = p_company_id
      AND (pr."UserId_Target" = p_user_id OR pr."RoleId" = v_role_id)
    ORDER BY
        CASE WHEN pr."UserId_Target" = p_user_id THEN 0 ELSE 1 END
    LIMIT 1;
END;
$$;

-- =============================================================================
--  SECCION 5: REGLAS DE APROBACION
-- =============================================================================

-- usp_Sec_ApprovalRule_List
DROP FUNCTION IF EXISTS usp_sec_approvalrule_list(INT, VARCHAR) CASCADE;
CREATE OR REPLACE FUNCTION usp_sec_approvalrule_list(
    p_company_id  INT,
    p_module_code VARCHAR(50) DEFAULT NULL
)
RETURNS TABLE(
    "ApprovalRuleId"   INT,
    "ModuleCode"       VARCHAR,
    "DocumentType"     VARCHAR,
    "MinAmount"        NUMERIC,
    "MaxAmount"        NUMERIC,
    "RequiredRoleId"   INT,
    "RequiredRoleName" VARCHAR,
    "ApprovalLevels"   INT,
    "IsActive"         BOOLEAN,
    "CreatedAt"        TIMESTAMP
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        ar."ApprovalRuleId",
        ar."ModuleCode"::VARCHAR,
        ar."DocumentType"::VARCHAR,
        ar."MinAmount",
        ar."MaxAmount",
        ar."RequiredRoleId",
        r."RoleName"::VARCHAR,
        ar."ApprovalLevels",
        ar."IsActive",
        ar."CreatedAt"
    FROM sec."ApprovalRule" ar
    LEFT JOIN sec."Role" r ON r."RoleId" = ar."RequiredRoleId"
    WHERE ar."CompanyId" = p_company_id
      AND (p_module_code IS NULL OR ar."ModuleCode" = p_module_code)
    ORDER BY ar."ModuleCode", ar."MinAmount";
END;
$$;

-- usp_Sec_ApprovalRule_Upsert
DROP FUNCTION IF EXISTS usp_sec_approvalrule_upsert(INT, INT, VARCHAR, VARCHAR, NUMERIC, NUMERIC, INT, INT, BOOLEAN, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_sec_approvalrule_upsert(
    p_company_id      INT,
    p_approval_rule_id INT DEFAULT NULL,
    p_module_code     VARCHAR(50) DEFAULT NULL,
    p_document_type   VARCHAR(50) DEFAULT NULL,
    p_min_amount      NUMERIC(18,2) DEFAULT 0,
    p_max_amount      NUMERIC(18,2) DEFAULT NULL,
    p_required_role_id INT DEFAULT NULL,
    p_approval_levels INT DEFAULT 1,
    p_is_active       BOOLEAN DEFAULT TRUE,
    p_user_id         INT DEFAULT NULL
)
RETURNS TABLE("ok" INT, "mensaje" VARCHAR)
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_approval_rule_id IS NOT NULL AND EXISTS (SELECT 1 FROM sec."ApprovalRule" WHERE "ApprovalRuleId" = p_approval_rule_id) THEN
        UPDATE sec."ApprovalRule" SET
            "ModuleCode"     = p_module_code,
            "DocumentType"   = p_document_type,
            "MinAmount"      = p_min_amount,
            "MaxAmount"      = p_max_amount,
            "RequiredRoleId" = p_required_role_id,
            "ApprovalLevels" = p_approval_levels,
            "IsActive"       = p_is_active,
            "UpdatedAt"      = NOW() AT TIME ZONE 'UTC',
            "UpdatedBy"      = p_user_id
        WHERE "ApprovalRuleId" = p_approval_rule_id;

        RETURN QUERY SELECT 1, 'Regla actualizada'::VARCHAR;
    ELSE
        INSERT INTO sec."ApprovalRule" (
            "CompanyId", "ModuleCode", "DocumentType", "MinAmount", "MaxAmount",
            "RequiredRoleId", "ApprovalLevels", "IsActive", "CreatedAt", "CreatedBy"
        ) VALUES (
            p_company_id, p_module_code, p_document_type, p_min_amount, p_max_amount,
            p_required_role_id, p_approval_levels, p_is_active, NOW() AT TIME ZONE 'UTC', p_user_id
        );

        RETURN QUERY SELECT 1, 'Regla creada'::VARCHAR;
    END IF;

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -1, SQLERRM::VARCHAR;
END;
$$;

-- =============================================================================
--  SECCION 6: SOLICITUDES DE APROBACION
-- =============================================================================

-- usp_Sec_ApprovalRequest_List
DROP FUNCTION IF EXISTS usp_sec_approvalrequest_list(INT, VARCHAR, VARCHAR, INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_sec_approvalrequest_list(
    p_company_id  INT,
    p_status      VARCHAR(20) DEFAULT NULL,
    p_module_code VARCHAR(50) DEFAULT NULL,
    p_page        INT DEFAULT 1,
    p_limit       INT DEFAULT 50
)
RETURNS TABLE(
    "ApprovalRequestId"  INT,
    "DocumentModule"     VARCHAR,
    "DocumentType"       VARCHAR,
    "DocumentNumber"     VARCHAR,
    "DocumentAmount"     NUMERIC,
    "Status"             VARCHAR,
    "CurrentLevel"       INT,
    "RequiredLevels"     INT,
    "RequestedByUserId"  INT,
    "BranchId"           INT,
    "CreatedAt"          TIMESTAMP,
    "UpdatedAt"          TIMESTAMP,
    "TotalCount"         INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_offset INT := (p_page - 1) * p_limit;
    v_total  INT;
BEGIN
    SELECT COUNT(*) INTO v_total
    FROM sec."ApprovalRequest"
    WHERE "CompanyId" = p_company_id
      AND (p_status IS NULL OR "Status" = p_status)
      AND (p_module_code IS NULL OR "DocumentModule" = p_module_code);

    RETURN QUERY
    SELECT
        ar."ApprovalRequestId",
        ar."DocumentModule"::VARCHAR,
        ar."DocumentType"::VARCHAR,
        ar."DocumentNumber"::VARCHAR,
        ar."DocumentAmount",
        ar."Status"::VARCHAR,
        ar."CurrentLevel",
        ar."RequiredLevels",
        ar."RequestedByUserId",
        ar."BranchId",
        ar."CreatedAt",
        ar."UpdatedAt",
        v_total
    FROM sec."ApprovalRequest" ar
    WHERE ar."CompanyId" = p_company_id
      AND (p_status IS NULL OR ar."Status" = p_status)
      AND (p_module_code IS NULL OR ar."DocumentModule" = p_module_code)
    ORDER BY ar."CreatedAt" DESC
    OFFSET v_offset LIMIT p_limit;
END;
$$;

-- usp_Sec_ApprovalRequest_Create
DROP FUNCTION IF EXISTS usp_sec_approvalrequest_create(INT, INT, VARCHAR, VARCHAR, VARCHAR, NUMERIC, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_sec_approvalrequest_create(
    p_company_id          INT,
    p_branch_id           INT,
    p_document_module     VARCHAR(50),
    p_document_type       VARCHAR(50),
    p_document_number     VARCHAR(50),
    p_document_amount     NUMERIC(18,2),
    p_requested_by_user_id INT
)
RETURNS TABLE("ok" INT, "ApprovalRequestId" INT)
LANGUAGE plpgsql
AS $$
DECLARE
    v_id             INT;
    v_required_levels INT := 1;
BEGIN
    -- Buscar regla aplicable
    SELECT ar."ApprovalLevels" INTO v_required_levels
    FROM sec."ApprovalRule" ar
    WHERE ar."CompanyId" = p_company_id
      AND ar."ModuleCode" = p_document_module
      AND ar."DocumentType" = p_document_type
      AND p_document_amount >= ar."MinAmount"
      AND (p_document_amount <= ar."MaxAmount" OR ar."MaxAmount" IS NULL)
      AND ar."IsActive" = TRUE
    ORDER BY ar."MinAmount" DESC
    LIMIT 1;

    IF v_required_levels IS NULL THEN
        v_required_levels := 1;
    END IF;

    INSERT INTO sec."ApprovalRequest" (
        "CompanyId", "BranchId", "DocumentModule", "DocumentType", "DocumentNumber",
        "DocumentAmount", "RequestedByUserId", "Status", "CurrentLevel", "RequiredLevels",
        "CreatedAt"
    ) VALUES (
        p_company_id, p_branch_id, p_document_module, p_document_type, p_document_number,
        p_document_amount, p_requested_by_user_id, 'PENDING', 0, v_required_levels,
        NOW() AT TIME ZONE 'UTC'
    ) RETURNING "ApprovalRequestId" INTO v_id;

    RETURN QUERY SELECT 1, v_id;

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -1, 0;
END;
$$;

-- usp_Sec_ApprovalRequest_Act
DROP FUNCTION IF EXISTS usp_sec_approvalrequest_act(INT, INT, VARCHAR, VARCHAR) CASCADE;
CREATE OR REPLACE FUNCTION usp_sec_approvalrequest_act(
    p_approval_request_id INT,
    p_action_by_user_id   INT,
    p_action              VARCHAR(10),  -- APPROVE / REJECT
    p_comments            VARCHAR(500) DEFAULT NULL
)
RETURNS TABLE("ok" INT, "NewStatus" VARCHAR)
LANGUAGE plpgsql
AS $$
DECLARE
    v_current_level   INT;
    v_required_levels INT;
    v_current_status  VARCHAR(20);
    v_new_status      VARCHAR(20);
BEGIN
    SELECT "CurrentLevel", "RequiredLevels", "Status"
    INTO v_current_level, v_required_levels, v_current_status
    FROM sec."ApprovalRequest"
    WHERE "ApprovalRequestId" = p_approval_request_id;

    IF v_current_status <> 'PENDING' THEN
        RETURN QUERY SELECT -1, v_current_status::VARCHAR;
        RETURN;
    END IF;

    -- Registrar accion
    INSERT INTO sec."ApprovalAction" (
        "ApprovalRequestId", "ActionByUserId", "Action", "ActionLevel", "Comments", "CreatedAt"
    ) VALUES (
        p_approval_request_id, p_action_by_user_id, p_action, v_current_level + 1, p_comments, NOW() AT TIME ZONE 'UTC'
    );

    IF p_action = 'REJECT' THEN
        v_new_status := 'REJECTED';
        UPDATE sec."ApprovalRequest" SET "Status" = v_new_status, "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
        WHERE "ApprovalRequestId" = p_approval_request_id;
    ELSIF p_action = 'APPROVE' THEN
        v_current_level := v_current_level + 1;

        IF v_current_level >= v_required_levels THEN
            v_new_status := 'APPROVED';
        ELSE
            v_new_status := 'PENDING';
        END IF;

        UPDATE sec."ApprovalRequest" SET
            "Status" = v_new_status,
            "CurrentLevel" = v_current_level,
            "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
        WHERE "ApprovalRequestId" = p_approval_request_id;
    END IF;

    RETURN QUERY SELECT 1, v_new_status;

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -1, 'ERROR'::VARCHAR;
END;
$$;

-- usp_Sec_ApprovalRequest_Get
DROP FUNCTION IF EXISTS usp_sec_approvalrequest_get(INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_sec_approvalrequest_get(
    p_approval_request_id INT
)
RETURNS TABLE(
    "ApprovalRequestId"  INT,
    "CompanyId"          INT,
    "BranchId"           INT,
    "DocumentModule"     VARCHAR,
    "DocumentType"       VARCHAR,
    "DocumentNumber"     VARCHAR,
    "DocumentAmount"     NUMERIC,
    "RequestedByUserId"  INT,
    "Status"             VARCHAR,
    "CurrentLevel"       INT,
    "RequiredLevels"     INT,
    "CreatedAt"          TIMESTAMP,
    "UpdatedAt"          TIMESTAMP
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        ar."ApprovalRequestId",
        ar."CompanyId",
        ar."BranchId",
        ar."DocumentModule"::VARCHAR,
        ar."DocumentType"::VARCHAR,
        ar."DocumentNumber"::VARCHAR,
        ar."DocumentAmount",
        ar."RequestedByUserId",
        ar."Status"::VARCHAR,
        ar."CurrentLevel",
        ar."RequiredLevels",
        ar."CreatedAt",
        ar."UpdatedAt"
    FROM sec."ApprovalRequest" ar
    WHERE ar."ApprovalRequestId" = p_approval_request_id;
END;
$$;
