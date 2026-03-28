/*
 * usp_rbac.sql
 *
 * Funciones RBAC alineadas al esquema canÃƒÂ³nico PostgreSQL.
 */

-- =============================================================================
-- PERMISOS
-- =============================================================================

DROP FUNCTION IF EXISTS usp_sec_permission_list(VARCHAR) CASCADE;
CREATE OR REPLACE FUNCTION usp_sec_permission_list(
  p_module_code VARCHAR(50) DEFAULT NULL
)
RETURNS TABLE(
  "PermissionId" INT,
  "ModuleCode" VARCHAR,
  "PermissionCode" VARCHAR,
  "PermissionName" VARCHAR,
  "Description" VARCHAR,
  "SortOrder" INT
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT
    p."PermissionId"::INT,
    p."Module"::VARCHAR,
    p."PermissionCode"::VARCHAR,
    p."PermissionName"::VARCHAR,
    COALESCE(p."Description", '')::VARCHAR,
    CASE split_part(p."PermissionCode", '.', 2)
      WHEN 'VIEW' THEN 1
      WHEN 'CREATE' THEN 2
      WHEN 'EDIT' THEN 3
      WHEN 'DELETE' THEN 4
      WHEN 'VOID' THEN 5
      WHEN 'APPROVE' THEN 6
      WHEN 'EXPORT' THEN 7
      WHEN 'PRINT' THEN 8
      ELSE 99
    END AS "SortOrder"
  FROM sec."Permission" p
  WHERE p."IsDeleted" = FALSE
    AND (p_module_code IS NULL OR p."Module" = p_module_code)
  ORDER BY p."Module", "SortOrder", p."PermissionCode";
END;
$$;

DROP FUNCTION IF EXISTS usp_sec_permission_seed() CASCADE;
CREATE OR REPLACE FUNCTION usp_sec_permission_seed()
RETURNS TABLE("InsertedCount" INT)
LANGUAGE plpgsql
AS $$
DECLARE
  v_count INT := 0;
BEGIN
  WITH modules AS (
    SELECT *
    FROM (VALUES
      ('ventas', 'Ventas'),
      ('compras', 'Compras'),
      ('inventario', 'Inventario'),
      ('bancos', 'Bancos'),
      ('contabilidad', 'Contabilidad'),
      ('nomina', 'Nomina'),
      ('rrhh', 'Recursos Humanos'),
      ('pos', 'Punto de Venta'),
      ('restaurante', 'Restaurante'),
      ('auditoria', 'Auditoria'),
      ('crm', 'CRM'),
      ('manufactura', 'Manufactura'),
      ('flota', 'Flota Vehicular'),
      ('logistica', 'Logistica'),
      ('permisos', 'Permisos')
    ) AS m(module_code, module_name)
  ),
  actions AS (
    SELECT *
    FROM (VALUES
      ('VIEW', 'Ver'),
      ('CREATE', 'Crear'),
      ('EDIT', 'Editar'),
      ('DELETE', 'Eliminar'),
      ('VOID', 'Anular'),
      ('APPROVE', 'Aprobar'),
      ('EXPORT', 'Exportar'),
      ('PRINT', 'Imprimir')
    ) AS a(action_code, action_name)
  ),
  inserted AS (
    INSERT INTO sec."Permission" (
      "PermissionCode",
      "PermissionName",
      "Module",
      "Category",
      "Description",
      "IsSystem",
      "IsActive",
      "CreatedByUserId",
      "UpdatedByUserId"
    )
    SELECT
      m.module_code || '.' || a.action_code,
      m.module_name || ' - ' || a.action_name,
      m.module_code,
      a.action_code,
      'Permiso para ' || LOWER(a.action_name) || ' en modulo ' || m.module_name,
      FALSE,
      TRUE,
      1,
      1
    FROM modules m
    CROSS JOIN actions a
    ON CONFLICT ("PermissionCode") DO NOTHING
    RETURNING 1
  )
  SELECT COUNT(*) INTO v_count FROM inserted;

  RETURN QUERY SELECT v_count;
END;
$$;

-- =============================================================================
-- PERMISOS POR ROL
-- =============================================================================

DROP FUNCTION IF EXISTS usp_sec_rolepermission_list(INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_sec_rolepermission_list(
  p_role_id INT
)
RETURNS TABLE(
  "PermissionId" INT,
  "ModuleCode" VARCHAR,
  "PermissionCode" VARCHAR,
  "PermissionName" VARCHAR,
  "IsGranted" BOOLEAN,
  "BranchId" INT
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT
    p."PermissionId"::INT,
    p."Module"::VARCHAR,
    p."PermissionCode"::VARCHAR,
    p."PermissionName"::VARCHAR,
    (rp."RolePermissionId" IS NOT NULL) AS "IsGranted",
    NULL::INT AS "BranchId"
  FROM sec."Permission" p
  LEFT JOIN sec."RolePermission" rp
    ON rp."PermissionId" = p."PermissionId"
   AND rp."RoleId" = p_role_id
  WHERE p."IsDeleted" = FALSE
  ORDER BY p."Module",
    CASE split_part(p."PermissionCode", '.', 2)
      WHEN 'VIEW' THEN 1
      WHEN 'CREATE' THEN 2
      WHEN 'EDIT' THEN 3
      WHEN 'DELETE' THEN 4
      WHEN 'VOID' THEN 5
      WHEN 'APPROVE' THEN 6
      WHEN 'EXPORT' THEN 7
      WHEN 'PRINT' THEN 8
      ELSE 99
    END,
    p."PermissionCode";
END;
$$;

DROP FUNCTION IF EXISTS usp_sec_rolepermission_set(INT, INT, INT, BOOLEAN, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_sec_rolepermission_set(
  p_role_id INT,
  p_permission_id INT,
  p_branch_id INT DEFAULT NULL,
  p_is_granted BOOLEAN DEFAULT TRUE,
  p_user_id INT DEFAULT NULL
)
RETURNS TABLE("Resultado" INT, "Mensaje" VARCHAR)
LANGUAGE plpgsql
AS $$
DECLARE
  v_action VARCHAR(20);
BEGIN
  SELECT split_part("PermissionCode", '.', 2)
    INTO v_action
  FROM sec."Permission"
  WHERE "PermissionId" = p_permission_id
    AND "IsDeleted" = FALSE;

  IF v_action IS NULL THEN
    RETURN QUERY SELECT -1, 'Permiso no encontrado'::VARCHAR;
    RETURN;
  END IF;

  IF p_is_granted THEN
    INSERT INTO sec."RolePermission" (
      "RoleId", "PermissionId", "CanCreate", "CanRead", "CanUpdate", "CanDelete", "CanExport", "CanApprove",
      "CreatedByUserId", "UpdatedByUserId"
    )
    VALUES (
      p_role_id,
      p_permission_id,
      v_action = 'CREATE',
      v_action IN ('VIEW', 'PRINT', 'VOID'),
      v_action = 'EDIT',
      v_action = 'DELETE',
      v_action = 'EXPORT',
      v_action = 'APPROVE',
      p_user_id,
      p_user_id
    )
    ON CONFLICT ("RoleId", "PermissionId") DO UPDATE
    SET
      "CanCreate" = EXCLUDED."CanCreate",
      "CanRead" = EXCLUDED."CanRead",
      "CanUpdate" = EXCLUDED."CanUpdate",
      "CanDelete" = EXCLUDED."CanDelete",
      "CanExport" = EXCLUDED."CanExport",
      "CanApprove" = EXCLUDED."CanApprove",
      "UpdatedAt" = NOW() AT TIME ZONE 'UTC',
      "UpdatedByUserId" = EXCLUDED."UpdatedByUserId";
  ELSE
    DELETE FROM sec."RolePermission"
    WHERE "RoleId" = p_role_id
      AND "PermissionId" = p_permission_id;
  END IF;

  RETURN QUERY SELECT 1, 'Permiso actualizado'::VARCHAR;
END;
$$;

DROP FUNCTION IF EXISTS usp_sec_rolepermission_bulkset(INT, VARCHAR, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_sec_rolepermission_bulkset(
  p_role_id INT,
  p_permissions_json VARCHAR,
  p_user_id INT DEFAULT NULL
)
RETURNS TABLE("Resultado" INT, "Mensaje" VARCHAR)
LANGUAGE plpgsql
AS $$
DECLARE
  v_count INT := 0;
BEGIN
  DELETE FROM sec."RolePermission"
  WHERE "RoleId" = p_role_id;

  INSERT INTO sec."RolePermission" (
    "RoleId", "PermissionId", "CanCreate", "CanRead", "CanUpdate", "CanDelete", "CanExport", "CanApprove",
    "CreatedByUserId", "UpdatedByUserId"
  )
  SELECT
    p_role_id,
    perm."PermissionId",
    split_part(perm."PermissionCode", '.', 2) = 'CREATE',
    split_part(perm."PermissionCode", '.', 2) IN ('VIEW', 'PRINT', 'VOID'),
    split_part(perm."PermissionCode", '.', 2) = 'EDIT',
    split_part(perm."PermissionCode", '.', 2) = 'DELETE',
    split_part(perm."PermissionCode", '.', 2) = 'EXPORT',
    split_part(perm."PermissionCode", '.', 2) = 'APPROVE',
    p_user_id,
    p_user_id
  FROM jsonb_array_elements(COALESCE(p_permissions_json, '[]')::JSONB) AS j
  JOIN sec."Permission" perm
    ON perm."PermissionId" = (j->>'permissionId')::INT
  WHERE COALESCE((j->>'isGranted')::BOOLEAN, FALSE) = TRUE;

  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN QUERY SELECT 1, (v_count::TEXT || ' permisos asignados')::VARCHAR;
END;
$$;

-- =============================================================================
-- PERMISOS DE USUARIO
-- =============================================================================

DROP FUNCTION IF EXISTS usp_sec_userpermission_list(INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_sec_userpermission_list(
  p_user_id INT
)
RETURNS TABLE(
  "PermissionId" INT,
  "ModuleCode" VARCHAR,
  "PermissionCode" VARCHAR,
  "PermissionName" VARCHAR,
  "IsGranted" BOOLEAN,
  "Source" VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT
    p."PermissionId"::INT,
    p."Module"::VARCHAR,
    p."PermissionCode"::VARCHAR,
    p."PermissionName"::VARCHAR,
    CASE
      WHEN upo."UserPermissionOverrideId" IS NOT NULL THEN upo."OverrideType" = 'GRANT'
      WHEN EXISTS (
        SELECT 1
        FROM sec."UserRole" ur
        JOIN sec."RolePermission" rp ON rp."RoleId" = ur."RoleId"
        WHERE ur."UserId" = p_user_id
          AND rp."PermissionId" = p."PermissionId"
      ) THEN TRUE
      ELSE FALSE
    END AS "IsGranted",
    CASE
      WHEN upo."UserPermissionOverrideId" IS NOT NULL THEN 'OVERRIDE'::VARCHAR
      WHEN EXISTS (
        SELECT 1
        FROM sec."UserRole" ur
        JOIN sec."RolePermission" rp ON rp."RoleId" = ur."RoleId"
        WHERE ur."UserId" = p_user_id
          AND rp."PermissionId" = p."PermissionId"
      ) THEN 'ROLE'::VARCHAR
      ELSE 'DEFAULT'::VARCHAR
    END AS "Source"
  FROM sec."Permission" p
  LEFT JOIN sec."UserPermissionOverride" upo
    ON upo."UserId" = p_user_id
   AND upo."PermissionId" = p."PermissionId"
   AND upo."IsDeleted" = FALSE
  WHERE p."IsDeleted" = FALSE
  ORDER BY p."Module",
    CASE split_part(p."PermissionCode", '.', 2)
      WHEN 'VIEW' THEN 1
      WHEN 'CREATE' THEN 2
      WHEN 'EDIT' THEN 3
      WHEN 'DELETE' THEN 4
      WHEN 'VOID' THEN 5
      WHEN 'APPROVE' THEN 6
      WHEN 'EXPORT' THEN 7
      WHEN 'PRINT' THEN 8
      ELSE 99
    END,
    p."PermissionCode";
END;
$$;

DROP FUNCTION IF EXISTS usp_sec_userpermission_override(INT, INT, INT, BOOLEAN, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_sec_userpermission_override(
  p_user_id INT,
  p_permission_id INT,
  p_branch_id INT DEFAULT NULL,
  p_is_granted BOOLEAN DEFAULT TRUE,
  p_admin_user_id INT DEFAULT NULL
)
RETURNS TABLE("Resultado" INT, "Mensaje" VARCHAR)
LANGUAGE plpgsql
AS $$
DECLARE
  v_action VARCHAR(20);
BEGIN
  SELECT split_part("PermissionCode", '.', 2)
    INTO v_action
  FROM sec."Permission"
  WHERE "PermissionId" = p_permission_id
    AND "IsDeleted" = FALSE;

  IF v_action IS NULL THEN
    RETURN QUERY SELECT -1, 'Permiso no encontrado'::VARCHAR;
    RETURN;
  END IF;

  INSERT INTO sec."UserPermissionOverride" (
    "UserId", "PermissionId", "OverrideType", "CanCreate", "CanRead", "CanUpdate", "CanDelete", "CanExport", "CanApprove",
    "CreatedByUserId", "UpdatedByUserId", "IsDeleted", "DeletedAt", "DeletedByUserId"
  )
  VALUES (
    p_user_id,
    p_permission_id,
    CASE WHEN p_is_granted THEN 'GRANT' ELSE 'DENY' END,
    CASE WHEN v_action = 'CREATE' THEN p_is_granted ELSE NULL END,
    CASE WHEN v_action IN ('VIEW', 'PRINT', 'VOID') THEN p_is_granted ELSE NULL END,
    CASE WHEN v_action = 'EDIT' THEN p_is_granted ELSE NULL END,
    CASE WHEN v_action = 'DELETE' THEN p_is_granted ELSE NULL END,
    CASE WHEN v_action = 'EXPORT' THEN p_is_granted ELSE NULL END,
    CASE WHEN v_action = 'APPROVE' THEN p_is_granted ELSE NULL END,
    p_admin_user_id,
    p_admin_user_id,
    FALSE,
    NULL,
    NULL
  )
  ON CONFLICT ("UserId", "PermissionId") DO UPDATE
  SET
    "OverrideType" = EXCLUDED."OverrideType",
    "CanCreate" = EXCLUDED."CanCreate",
    "CanRead" = EXCLUDED."CanRead",
    "CanUpdate" = EXCLUDED."CanUpdate",
    "CanDelete" = EXCLUDED."CanDelete",
    "CanExport" = EXCLUDED."CanExport",
    "CanApprove" = EXCLUDED."CanApprove",
    "UpdatedAt" = NOW() AT TIME ZONE 'UTC',
    "UpdatedByUserId" = EXCLUDED."UpdatedByUserId",
    "IsDeleted" = FALSE,
    "DeletedAt" = NULL,
    "DeletedByUserId" = NULL;

  RETURN QUERY SELECT 1, 'Override aplicado'::VARCHAR;
END;
$$;

DROP FUNCTION IF EXISTS usp_sec_userpermission_check(INT, VARCHAR) CASCADE;
CREATE OR REPLACE FUNCTION usp_sec_userpermission_check(
  p_user_id INT,
  p_permission_code VARCHAR(100)
)
RETURNS TABLE("HasPermission" BOOLEAN)
LANGUAGE plpgsql
AS $$
DECLARE
  v_permission_id INT;
  v_is_admin BOOLEAN := FALSE;
  v_override VARCHAR(10);
BEGIN
  SELECT COALESCE("IsAdmin", FALSE)
    INTO v_is_admin
  FROM sec."User"
  WHERE "UserId" = p_user_id
    AND "IsDeleted" = FALSE
  LIMIT 1;

  IF v_is_admin THEN
    RETURN QUERY SELECT TRUE;
    RETURN;
  END IF;

  SELECT "PermissionId"::INT
    INTO v_permission_id
  FROM sec."Permission"
  WHERE "PermissionCode" = p_permission_code
    AND "IsDeleted" = FALSE
  LIMIT 1;

  IF v_permission_id IS NULL THEN
    RETURN QUERY SELECT FALSE;
    RETURN;
  END IF;

  SELECT "OverrideType"
    INTO v_override
  FROM sec."UserPermissionOverride"
  WHERE "UserId" = p_user_id
    AND "PermissionId" = v_permission_id
    AND "IsDeleted" = FALSE
  LIMIT 1;

  IF v_override IS NOT NULL THEN
    RETURN QUERY SELECT (v_override = 'GRANT');
    RETURN;
  END IF;

  RETURN QUERY
  SELECT EXISTS (
    SELECT 1
    FROM sec."UserRole" ur
    JOIN sec."RolePermission" rp ON rp."RoleId" = ur."RoleId"
    WHERE ur."UserId" = p_user_id
      AND rp."PermissionId" = v_permission_id
  );
END;
$$;

-- =============================================================================
-- RESTRICCIONES DE PRECIO
-- =============================================================================

DROP FUNCTION IF EXISTS usp_sec_pricerestriction_list(INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_sec_pricerestriction_list(
  p_company_id INT
)
RETURNS TABLE(
  "RestrictionId" INT,
  "RoleId" INT,
  "RoleName" VARCHAR,
  "UserId_Target" INT,
  "MaxDiscountPercent" NUMERIC,
  "MinPricePercent" NUMERIC,
  "MaxCreditLimit" NUMERIC,
  "RequiresApprovalAbove" NUMERIC,
  "CreatedAt" TIMESTAMP
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT
    pr."PriceRestrictionId"::INT,
    pr."RoleId",
    COALESCE(r."RoleName", '')::VARCHAR,
    pr."UserId",
    pr."MaxDiscountPercent",
    pr."MinMarginPercent",
    pr."MaxCreditAmount",
    pr."RequiresApprovalAbove",
    pr."CreatedAt"
  FROM sec."PriceRestriction" pr
  LEFT JOIN sec."Role" r ON r."RoleId" = pr."RoleId"
  WHERE pr."CompanyId" = p_company_id
    AND pr."IsDeleted" = FALSE
  ORDER BY pr."RoleId", pr."UserId", pr."PriceRestrictionId";
END;
$$;

DROP FUNCTION IF EXISTS usp_sec_pricerestriction_upsert(INT, INT, INT, INT, NUMERIC, NUMERIC, NUMERIC, NUMERIC, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_sec_pricerestriction_upsert(
  p_company_id INT,
  p_restriction_id INT DEFAULT NULL,
  p_role_id INT DEFAULT NULL,
  p_user_id_target INT DEFAULT NULL,
  p_max_discount_percent NUMERIC(5,2) DEFAULT 0,
  p_min_price_percent NUMERIC(5,2) DEFAULT 0,
  p_max_credit_limit NUMERIC(18,2) DEFAULT NULL,
  p_requires_approval_above NUMERIC(18,2) DEFAULT NULL,
  p_admin_user_id INT DEFAULT NULL
)
RETURNS TABLE("Resultado" INT, "Mensaje" VARCHAR)
LANGUAGE plpgsql
AS $$
BEGIN
  IF p_restriction_id IS NOT NULL AND EXISTS (
    SELECT 1 FROM sec."PriceRestriction" WHERE "PriceRestrictionId" = p_restriction_id
  ) THEN
    UPDATE sec."PriceRestriction"
    SET
      "RoleId" = p_role_id,
      "UserId" = p_user_id_target,
      "MaxDiscountPercent" = p_max_discount_percent,
      "MinMarginPercent" = p_min_price_percent,
      "MaxCreditAmount" = p_max_credit_limit,
      "RequiresApprovalAbove" = p_requires_approval_above,
      "UpdatedAt" = NOW() AT TIME ZONE 'UTC',
      "UpdatedByUserId" = p_admin_user_id,
      "IsDeleted" = FALSE,
      "DeletedAt" = NULL,
      "DeletedByUserId" = NULL
    WHERE "PriceRestrictionId" = p_restriction_id;

    RETURN QUERY SELECT 1, 'Restriccion actualizada'::VARCHAR;
  ELSE
    INSERT INTO sec."PriceRestriction" (
      "CompanyId", "RoleId", "UserId", "MaxDiscountPercent", "MinMarginPercent", "MaxCreditAmount",
      "RequiresApprovalAbove", "IsActive", "CreatedByUserId", "UpdatedByUserId"
    )
    VALUES (
      p_company_id, p_role_id, p_user_id_target, p_max_discount_percent, p_min_price_percent, p_max_credit_limit,
      p_requires_approval_above, TRUE, p_admin_user_id, p_admin_user_id
    );

    RETURN QUERY SELECT 1, 'Restriccion creada'::VARCHAR;
  END IF;
END;
$$;

DROP FUNCTION IF EXISTS usp_sec_pricerestriction_check(INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_sec_pricerestriction_check(
  p_user_id INT,
  p_company_id INT
)
RETURNS TABLE(
  "RestrictionId" INT,
  "MaxDiscountPercent" NUMERIC,
  "MinPricePercent" NUMERIC,
  "MaxCreditLimit" NUMERIC,
  "RequiresApprovalAbove" NUMERIC
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT
    pr."PriceRestrictionId"::INT,
    pr."MaxDiscountPercent",
    pr."MinMarginPercent",
    pr."MaxCreditAmount",
    pr."RequiresApprovalAbove"
  FROM sec."PriceRestriction" pr
  WHERE pr."CompanyId" = p_company_id
    AND pr."IsDeleted" = FALSE
    AND (
      pr."UserId" = p_user_id
      OR EXISTS (
        SELECT 1
        FROM sec."UserRole" ur
        WHERE ur."UserId" = p_user_id
          AND ur."RoleId" = pr."RoleId"
      )
    )
  ORDER BY CASE WHEN pr."UserId" = p_user_id THEN 0 ELSE 1 END, pr."PriceRestrictionId"
  LIMIT 1;
END;
$$;

-- =============================================================================
-- REGLAS DE APROBACION
-- =============================================================================

DROP FUNCTION IF EXISTS usp_sec_approvalrule_list(INT, VARCHAR) CASCADE;
CREATE OR REPLACE FUNCTION usp_sec_approvalrule_list(
  p_company_id INT,
  p_module_code VARCHAR(50) DEFAULT NULL
)
RETURNS TABLE(
  "ApprovalRuleId" INT,
  "ModuleCode" VARCHAR,
  "DocumentType" VARCHAR,
  "MinAmount" NUMERIC,
  "MaxAmount" NUMERIC,
  "RequiredRoleId" INT,
  "RequiredRoleName" VARCHAR,
  "ApprovalLevels" INT,
  "IsActive" BOOLEAN,
  "CreatedAt" TIMESTAMP
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT
    ar."ApprovalRuleId"::INT,
    COALESCE(
      NULLIF(lower(split_part(ar."RuleCode", ':', 1)), ''),
      NULLIF(lower(split_part(ar."RuleCode", '-', 2)), '')
    )::VARCHAR AS "ModuleCode",
    ar."DocumentType"::VARCHAR,
    ar."ThresholdAmount" AS "MinAmount",
    NULL::NUMERIC AS "MaxAmount",
    ar."ApproverRoleId" AS "RequiredRoleId",
    COALESCE(r."RoleName", '')::VARCHAR AS "RequiredRoleName",
    ar."RequiredApprovals" AS "ApprovalLevels",
    ar."IsActive",
    ar."CreatedAt"
  FROM sec."ApprovalRule" ar
  LEFT JOIN sec."Role" r ON r."RoleId" = ar."ApproverRoleId"
  WHERE ar."CompanyId" = p_company_id
    AND ar."IsDeleted" = FALSE
    AND (
      p_module_code IS NULL
      OR lower(split_part(ar."RuleCode", ':', 1)) = lower(p_module_code)
      OR lower(split_part(ar."RuleCode", '-', 2)) = lower(p_module_code)
    )
  ORDER BY "ModuleCode", ar."ThresholdAmount", ar."ApprovalRuleId";
END;
$$;

DROP FUNCTION IF EXISTS usp_sec_approvalrule_upsert(INT, INT, VARCHAR, VARCHAR, NUMERIC, NUMERIC, INT, INT, BOOLEAN, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_sec_approvalrule_upsert(
  p_company_id INT,
  p_approval_rule_id INT DEFAULT NULL,
  p_module_code VARCHAR(50) DEFAULT NULL,
  p_document_type VARCHAR(50) DEFAULT NULL,
  p_min_amount NUMERIC(18,2) DEFAULT 0,
  p_max_amount NUMERIC(18,2) DEFAULT NULL,
  p_required_role_id INT DEFAULT NULL,
  p_approval_levels INT DEFAULT 1,
  p_is_active BOOLEAN DEFAULT TRUE,
  p_user_id INT DEFAULT NULL
)
RETURNS TABLE("Resultado" INT, "Mensaje" VARCHAR)
LANGUAGE plpgsql
AS $$
DECLARE
  v_rule_code VARCHAR(100);
BEGIN
  v_rule_code := lower(COALESCE(p_module_code, 'general')) || ':' ||
                 upper(COALESCE(p_document_type, 'DOC')) || ':' ||
                 replace(COALESCE(p_min_amount, 0)::TEXT, '.', '_');

  IF p_approval_rule_id IS NOT NULL AND EXISTS (
    SELECT 1 FROM sec."ApprovalRule" WHERE "ApprovalRuleId" = p_approval_rule_id
  ) THEN
    UPDATE sec."ApprovalRule"
    SET
      "RuleCode" = v_rule_code,
      "RuleName" = COALESCE(p_module_code, 'General') || ' - ' || COALESCE(p_document_type, 'Documento'),
      "DocumentType" = COALESCE(p_document_type, 'DOC'),
      "Condition" = 'AMOUNT_ABOVE',
      "ThresholdAmount" = p_min_amount,
      "ApproverRoleId" = p_required_role_id,
      "RequiredApprovals" = p_approval_levels,
      "IsActive" = COALESCE(p_is_active, TRUE),
      "UpdatedAt" = NOW() AT TIME ZONE 'UTC',
      "UpdatedByUserId" = p_user_id,
      "IsDeleted" = FALSE,
      "DeletedAt" = NULL,
      "DeletedByUserId" = NULL
    WHERE "ApprovalRuleId" = p_approval_rule_id;

    RETURN QUERY SELECT 1, 'Regla actualizada'::VARCHAR;
  ELSE
    INSERT INTO sec."ApprovalRule" (
      "CompanyId", "RuleCode", "RuleName", "DocumentType", "Condition", "ThresholdAmount",
      "ApproverRoleId", "RequiredApprovals", "IsActive", "CreatedByUserId", "UpdatedByUserId"
    )
    VALUES (
      p_company_id,
      v_rule_code,
      COALESCE(p_module_code, 'General') || ' - ' || COALESCE(p_document_type, 'Documento'),
      COALESCE(p_document_type, 'DOC'),
      'AMOUNT_ABOVE',
      p_min_amount,
      p_required_role_id,
      p_approval_levels,
      COALESCE(p_is_active, TRUE),
      p_user_id,
      p_user_id
    )
    ON CONFLICT ("CompanyId", "RuleCode") DO UPDATE
    SET
      "RuleName" = EXCLUDED."RuleName",
      "DocumentType" = EXCLUDED."DocumentType",
      "Condition" = EXCLUDED."Condition",
      "ThresholdAmount" = EXCLUDED."ThresholdAmount",
      "ApproverRoleId" = EXCLUDED."ApproverRoleId",
      "RequiredApprovals" = EXCLUDED."RequiredApprovals",
      "IsActive" = EXCLUDED."IsActive",
      "UpdatedAt" = NOW() AT TIME ZONE 'UTC',
      "UpdatedByUserId" = EXCLUDED."UpdatedByUserId",
      "IsDeleted" = FALSE,
      "DeletedAt" = NULL,
      "DeletedByUserId" = NULL;

    RETURN QUERY SELECT 1, 'Regla creada'::VARCHAR;
  END IF;
END;
$$;

-- =============================================================================
-- SOLICITUDES DE APROBACION
-- =============================================================================

DROP FUNCTION IF EXISTS usp_sec_approvalrequest_list(INT, VARCHAR, VARCHAR, INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_sec_approvalrequest_list(
  p_company_id INT,
  p_status VARCHAR(20) DEFAULT NULL,
  p_module_code VARCHAR(50) DEFAULT NULL,
  p_page INT DEFAULT 1,
  p_limit INT DEFAULT 50
)
RETURNS TABLE(
  "ApprovalRequestId" INT,
  "DocumentModule" VARCHAR,
  "DocumentType" VARCHAR,
  "DocumentNumber" VARCHAR,
  "DocumentAmount" NUMERIC,
  "Status" VARCHAR,
  "CurrentLevel" INT,
  "RequiredLevels" INT,
  "RequestedByUserId" INT,
  "BranchId" INT,
  "CreatedAt" TIMESTAMP,
  "UpdatedAt" TIMESTAMP,
  "TotalCount" INT
)
LANGUAGE plpgsql
AS $$
DECLARE
  v_offset INT := GREATEST(COALESCE(p_page, 1), 1) - 1;
  v_total INT := 0;
BEGIN
  v_offset := v_offset * GREATEST(COALESCE(p_limit, 50), 1);

  SELECT COUNT(*)
    INTO v_total
  FROM sec."ApprovalRequest" ar
  JOIN sec."ApprovalRule" rule ON rule."ApprovalRuleId" = ar."ApprovalRuleId"
  WHERE ar."CompanyId" = p_company_id
    AND (p_status IS NULL OR ar."Status" = p_status)
    AND (
      p_module_code IS NULL
      OR ar."Notes" = 'MODULE:' || p_module_code
      OR lower(split_part(rule."RuleCode", ':', 1)) = lower(p_module_code)
      OR lower(split_part(rule."RuleCode", '-', 2)) = lower(p_module_code)
    );

  RETURN QUERY
  SELECT
    ar."ApprovalRequestId"::INT,
    COALESCE(
      NULLIF(replace(ar."Notes", 'MODULE:', ''), ''),
      NULLIF(lower(split_part(rule."RuleCode", ':', 1)), ''),
      NULLIF(lower(split_part(rule."RuleCode", '-', 2)), ''),
      'general'
    )::VARCHAR AS "DocumentModule",
    ar."DocumentType"::VARCHAR,
    COALESCE(ar."DocumentNumber", '')::VARCHAR,
    ar."RequestedAmount" AS "DocumentAmount",
    ar."Status"::VARCHAR,
    COALESCE((
      SELECT COUNT(*)::INT
      FROM sec."ApprovalAction" aa
      WHERE aa."ApprovalRequestId" = ar."ApprovalRequestId"
        AND aa."ActionType" = 'APPROVE'
    ), 0) AS "CurrentLevel",
    rule."RequiredApprovals" AS "RequiredLevels",
    ar."RequestedByUserId",
    NULL::INT AS "BranchId",
    ar."CreatedAt",
    ar."UpdatedAt",
    v_total AS "TotalCount"
  FROM sec."ApprovalRequest" ar
  JOIN sec."ApprovalRule" rule ON rule."ApprovalRuleId" = ar."ApprovalRuleId"
  WHERE ar."CompanyId" = p_company_id
    AND (p_status IS NULL OR ar."Status" = p_status)
    AND (
      p_module_code IS NULL
      OR ar."Notes" = 'MODULE:' || p_module_code
      OR lower(split_part(rule."RuleCode", ':', 1)) = lower(p_module_code)
      OR lower(split_part(rule."RuleCode", '-', 2)) = lower(p_module_code)
    )
  ORDER BY ar."CreatedAt" DESC
  OFFSET v_offset
  LIMIT GREATEST(COALESCE(p_limit, 50), 1);
END;
$$;

DROP FUNCTION IF EXISTS usp_sec_approvalrequest_create(INT, INT, VARCHAR, VARCHAR, VARCHAR, NUMERIC, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_sec_approvalrequest_create(
  p_company_id INT,
  p_branch_id INT,
  p_document_module VARCHAR(50),
  p_document_type VARCHAR(50),
  p_document_number VARCHAR(50),
  p_document_amount NUMERIC(18,2),
  p_requested_by_user_id INT
)
RETURNS TABLE("Resultado" INT, "ApprovalRequestId" INT)
LANGUAGE plpgsql
AS $$
DECLARE
  v_rule_id BIGINT;
  v_request_id BIGINT;
BEGIN
  SELECT ar."ApprovalRuleId"
    INTO v_rule_id
  FROM sec."ApprovalRule" ar
  WHERE ar."CompanyId" = p_company_id
    AND ar."IsDeleted" = FALSE
    AND ar."IsActive" = TRUE
    AND ar."DocumentType" = p_document_type
    AND (
      lower(split_part(ar."RuleCode", ':', 1)) = lower(p_document_module)
      OR lower(split_part(ar."RuleCode", '-', 2)) = lower(p_document_module)
    )
    AND COALESCE(ar."ThresholdAmount", 0) <= COALESCE(p_document_amount, 0)
  ORDER BY ar."ThresholdAmount" DESC NULLS LAST, ar."ApprovalRuleId" DESC
  LIMIT 1;

  IF v_rule_id IS NULL THEN
    RETURN QUERY SELECT -1, 0;
    RETURN;
  END IF;

  INSERT INTO sec."ApprovalRequest" (
    "CompanyId", "ApprovalRuleId", "DocumentType", "DocumentId", "DocumentNumber",
    "RequestedAmount", "Status", "RequestedByUserId", "Notes"
  )
  VALUES (
    p_company_id, v_rule_id, p_document_type, 0, p_document_number,
    p_document_amount, 'PENDING', p_requested_by_user_id, 'MODULE:' || lower(p_document_module)
  )
  RETURNING "ApprovalRequestId" INTO v_request_id;

  RETURN QUERY SELECT 1, COALESCE(v_request_id, 0)::INT;
END;
$$;

DROP FUNCTION IF EXISTS usp_sec_approvalrequest_act(INT, INT, VARCHAR, VARCHAR) CASCADE;
CREATE OR REPLACE FUNCTION usp_sec_approvalrequest_act(
  p_approval_request_id INT,
  p_action_by_user_id INT,
  p_action VARCHAR(10),
  p_comments VARCHAR(500) DEFAULT NULL
)
RETURNS TABLE("Resultado" INT, "NewStatus" VARCHAR)
LANGUAGE plpgsql
AS $$
DECLARE
  v_status VARCHAR(20);
  v_required_levels INT := 1;
  v_current_level INT := 0;
  v_new_status VARCHAR(20);
BEGIN
  SELECT ar."Status", rule."RequiredApprovals"
    INTO v_status, v_required_levels
  FROM sec."ApprovalRequest" ar
  JOIN sec."ApprovalRule" rule ON rule."ApprovalRuleId" = ar."ApprovalRuleId"
  WHERE ar."ApprovalRequestId" = p_approval_request_id;

  IF v_status IS NULL THEN
    RETURN QUERY SELECT -1, 'NOT_FOUND'::VARCHAR;
    RETURN;
  END IF;

  IF v_status <> 'PENDING' THEN
    RETURN QUERY SELECT -1, v_status::VARCHAR;
    RETURN;
  END IF;

  INSERT INTO sec."ApprovalAction" (
    "ApprovalRequestId", "ActionType", "ActionByUserId", "Comments"
  )
  VALUES (
    p_approval_request_id, UPPER(p_action), p_action_by_user_id, p_comments
  );

  IF UPPER(p_action) = 'REJECT' THEN
    v_new_status := 'REJECTED';
  ELSE
    SELECT COUNT(*)::INT
      INTO v_current_level
    FROM sec."ApprovalAction"
    WHERE "ApprovalRequestId" = p_approval_request_id
      AND "ActionType" = 'APPROVE';

    IF v_current_level >= COALESCE(v_required_levels, 1) THEN
      v_new_status := 'APPROVED';
    ELSE
      v_new_status := 'PENDING';
    END IF;
  END IF;

  UPDATE sec."ApprovalRequest"
  SET
    "Status" = v_new_status,
    "ResolvedAt" = CASE WHEN v_new_status IN ('APPROVED', 'REJECTED') THEN NOW() AT TIME ZONE 'UTC' ELSE NULL END,
    "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
  WHERE "ApprovalRequestId" = p_approval_request_id;

  RETURN QUERY SELECT 1, v_new_status::VARCHAR;
END;
$$;

DROP FUNCTION IF EXISTS usp_sec_approvalrequest_get(INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_sec_approvalrequest_get(
  p_approval_request_id INT
)
RETURNS TABLE(
  "ApprovalRequestId" INT,
  "CompanyId" INT,
  "BranchId" INT,
  "DocumentModule" VARCHAR,
  "DocumentType" VARCHAR,
  "DocumentNumber" VARCHAR,
  "DocumentAmount" NUMERIC,
  "RequestedByUserId" INT,
  "Status" VARCHAR,
  "CurrentLevel" INT,
  "RequiredLevels" INT,
  "CreatedAt" TIMESTAMP,
  "UpdatedAt" TIMESTAMP
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT
    ar."ApprovalRequestId"::INT,
    ar."CompanyId",
    NULL::INT AS "BranchId",
    COALESCE(
      NULLIF(replace(ar."Notes", 'MODULE:', ''), ''),
      NULLIF(lower(split_part(rule."RuleCode", ':', 1)), ''),
      NULLIF(lower(split_part(rule."RuleCode", '-', 2)), ''),
      'general'
    )::VARCHAR AS "DocumentModule",
    ar."DocumentType"::VARCHAR,
    COALESCE(ar."DocumentNumber", '')::VARCHAR,
    ar."RequestedAmount" AS "DocumentAmount",
    ar."RequestedByUserId",
    ar."Status"::VARCHAR,
    COALESCE((
      SELECT COUNT(*)::INT
      FROM sec."ApprovalAction" aa
      WHERE aa."ApprovalRequestId" = ar."ApprovalRequestId"
        AND aa."ActionType" = 'APPROVE'
    ), 0) AS "CurrentLevel",
    rule."RequiredApprovals" AS "RequiredLevels",
    ar."CreatedAt",
    ar."UpdatedAt"
  FROM sec."ApprovalRequest" ar
  JOIN sec."ApprovalRule" rule ON rule."ApprovalRuleId" = ar."ApprovalRuleId"
  WHERE ar."ApprovalRequestId" = p_approval_request_id;
END;
$$;
