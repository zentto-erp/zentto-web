/*
 * seed_demo_rbac.sql (PostgreSQL)
 *
 * Seed demo alineado al esquema canónico RBAC de PostgreSQL.
 */

DO $$
DECLARE
  v_role_admin       INT;
  v_role_gerente     INT;
  v_role_vendedor    INT;
  v_role_almacenista INT;
  v_role_contador    INT;
  v_module           VARCHAR(50);
  v_module_label     VARCHAR(100);
  v_action           VARCHAR(20);
  v_action_label     VARCHAR(50);
  v_modules          VARCHAR(50)[] := ARRAY['ventas','compras','inventario','bancos','contabilidad','nomina','rrhh','pos','restaurante','auditoria','crm','manufactura','flota','logistica','permisos'];
  v_module_labels    VARCHAR(100)[] := ARRAY['Ventas','Compras','Inventario','Bancos','Contabilidad','Nomina','Recursos Humanos','Punto de Venta','Restaurante','Auditoria','CRM','Manufactura','Flota Vehicular','Logistica','Permisos'];
  v_actions          VARCHAR(20)[] := ARRAY['VIEW','CREATE','EDIT','DELETE','VOID','APPROVE','EXPORT','PRINT'];
  v_action_labels    VARCHAR(50)[] := ARRAY['Ver','Crear','Editar','Eliminar','Anular','Aprobar','Exportar','Imprimir'];
  i INT;
  j INT;
BEGIN
  RAISE NOTICE '=== Seed demo: RBAC (sec) ===';

  RAISE NOTICE '>> 1. Catalogo de permisos (120 registros)...';
  FOR i IN 1..array_length(v_modules, 1) LOOP
    v_module := v_modules[i];
    v_module_label := v_module_labels[i];
    FOR j IN 1..array_length(v_actions, 1) LOOP
      v_action := v_actions[j];
      v_action_label := v_action_labels[j];

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
      VALUES (
        v_module || '.' || v_action,
        v_module_label || ' - ' || v_action_label,
        v_module,
        v_action,
        'Permiso para ' || LOWER(v_action_label) || ' en modulo ' || v_module_label,
        FALSE,
        TRUE,
        1,
        1
      )
      ON CONFLICT ("PermissionCode") DO UPDATE
      SET
        "PermissionName" = EXCLUDED."PermissionName",
        "Module" = EXCLUDED."Module",
        "Category" = EXCLUDED."Category",
        "Description" = EXCLUDED."Description",
        "IsActive" = TRUE,
        "UpdatedAt" = NOW() AT TIME ZONE 'UTC',
        "UpdatedByUserId" = 1,
        "IsDeleted" = FALSE,
        "DeletedAt" = NULL,
        "DeletedByUserId" = NULL;
    END LOOP;
  END LOOP;

  RAISE NOTICE '>> 2. Roles...';
  INSERT INTO sec."Role" ("RoleCode", "RoleName", "IsSystem", "IsActive")
  VALUES ('ADMIN', 'Administrador', TRUE, TRUE)
  ON CONFLICT ("RoleCode") DO UPDATE SET "RoleName" = EXCLUDED."RoleName", "IsActive" = TRUE;

  INSERT INTO sec."Role" ("RoleCode", "RoleName", "IsSystem", "IsActive")
  VALUES ('GERENTE', 'Gerente', FALSE, TRUE)
  ON CONFLICT ("RoleCode") DO UPDATE SET "RoleName" = EXCLUDED."RoleName", "IsActive" = TRUE;

  INSERT INTO sec."Role" ("RoleCode", "RoleName", "IsSystem", "IsActive")
  VALUES ('VENDEDOR', 'Vendedor', FALSE, TRUE)
  ON CONFLICT ("RoleCode") DO UPDATE SET "RoleName" = EXCLUDED."RoleName", "IsActive" = TRUE;

  INSERT INTO sec."Role" ("RoleCode", "RoleName", "IsSystem", "IsActive")
  VALUES ('ALMACENISTA', 'Almacenista', FALSE, TRUE)
  ON CONFLICT ("RoleCode") DO UPDATE SET "RoleName" = EXCLUDED."RoleName", "IsActive" = TRUE;

  INSERT INTO sec."Role" ("RoleCode", "RoleName", "IsSystem", "IsActive")
  VALUES ('CONTADOR', 'Contador', FALSE, TRUE)
  ON CONFLICT ("RoleCode") DO UPDATE SET "RoleName" = EXCLUDED."RoleName", "IsActive" = TRUE;

  SELECT "RoleId" INTO v_role_admin FROM sec."Role" WHERE "RoleCode" = 'ADMIN' LIMIT 1;
  SELECT "RoleId" INTO v_role_gerente FROM sec."Role" WHERE "RoleCode" = 'GERENTE' LIMIT 1;
  SELECT "RoleId" INTO v_role_vendedor FROM sec."Role" WHERE "RoleCode" = 'VENDEDOR' LIMIT 1;
  SELECT "RoleId" INTO v_role_almacenista FROM sec."Role" WHERE "RoleCode" = 'ALMACENISTA' LIMIT 1;
  SELECT "RoleId" INTO v_role_contador FROM sec."Role" WHERE "RoleCode" = 'CONTADOR' LIMIT 1;

  RAISE NOTICE '>> 3. Permisos por rol...';
  IF v_role_admin IS NOT NULL THEN
    INSERT INTO sec."RolePermission" (
      "RoleId", "PermissionId", "CanCreate", "CanRead", "CanUpdate", "CanDelete", "CanExport", "CanApprove",
      "CreatedByUserId", "UpdatedByUserId"
    )
    SELECT
      v_role_admin,
      p."PermissionId",
      split_part(p."PermissionCode", '.', 2) = 'CREATE',
      split_part(p."PermissionCode", '.', 2) IN ('VIEW', 'PRINT', 'VOID'),
      split_part(p."PermissionCode", '.', 2) = 'EDIT',
      split_part(p."PermissionCode", '.', 2) = 'DELETE',
      split_part(p."PermissionCode", '.', 2) = 'EXPORT',
      split_part(p."PermissionCode", '.', 2) = 'APPROVE',
      1,
      1
    FROM sec."Permission" p
    ON CONFLICT ("RoleId", "PermissionId") DO NOTHING;
  END IF;

  IF v_role_gerente IS NOT NULL THEN
    INSERT INTO sec."RolePermission" (
      "RoleId", "PermissionId", "CanCreate", "CanRead", "CanUpdate", "CanDelete", "CanExport", "CanApprove",
      "CreatedByUserId", "UpdatedByUserId"
    )
    SELECT
      v_role_gerente,
      p."PermissionId",
      split_part(p."PermissionCode", '.', 2) = 'CREATE',
      split_part(p."PermissionCode", '.', 2) IN ('VIEW', 'PRINT'),
      split_part(p."PermissionCode", '.', 2) = 'EDIT',
      FALSE,
      split_part(p."PermissionCode", '.', 2) = 'EXPORT',
      split_part(p."PermissionCode", '.', 2) = 'APPROVE',
      1,
      1
    FROM sec."Permission" p
    WHERE split_part(p."PermissionCode", '.', 2) IN ('VIEW', 'EXPORT', 'PRINT', 'APPROVE')
       OR (p."Module" IN ('ventas', 'compras', 'inventario', 'crm') AND split_part(p."PermissionCode", '.', 2) IN ('CREATE', 'EDIT'))
    ON CONFLICT ("RoleId", "PermissionId") DO NOTHING;
  END IF;

  IF v_role_vendedor IS NOT NULL THEN
    INSERT INTO sec."RolePermission" (
      "RoleId", "PermissionId", "CanCreate", "CanRead", "CanUpdate", "CanDelete", "CanExport", "CanApprove",
      "CreatedByUserId", "UpdatedByUserId"
    )
    SELECT
      v_role_vendedor,
      p."PermissionId",
      split_part(p."PermissionCode", '.', 2) = 'CREATE',
      split_part(p."PermissionCode", '.', 2) IN ('VIEW', 'PRINT'),
      split_part(p."PermissionCode", '.', 2) = 'EDIT',
      FALSE,
      FALSE,
      FALSE,
      1,
      1
    FROM sec."Permission" p
    WHERE split_part(p."PermissionCode", '.', 2) = 'VIEW'
       OR (p."Module" IN ('ventas', 'crm') AND split_part(p."PermissionCode", '.', 2) IN ('CREATE', 'EDIT'))
       OR (p."Module" = 'ventas' AND split_part(p."PermissionCode", '.', 2) = 'PRINT')
    ON CONFLICT ("RoleId", "PermissionId") DO NOTHING;
  END IF;

  IF v_role_almacenista IS NOT NULL THEN
    INSERT INTO sec."RolePermission" (
      "RoleId", "PermissionId", "CanCreate", "CanRead", "CanUpdate", "CanDelete", "CanExport", "CanApprove",
      "CreatedByUserId", "UpdatedByUserId"
    )
    SELECT
      v_role_almacenista,
      p."PermissionId",
      split_part(p."PermissionCode", '.', 2) = 'CREATE',
      split_part(p."PermissionCode", '.', 2) IN ('VIEW', 'PRINT', 'VOID'),
      split_part(p."PermissionCode", '.', 2) = 'EDIT',
      split_part(p."PermissionCode", '.', 2) = 'DELETE',
      split_part(p."PermissionCode", '.', 2) = 'EXPORT',
      split_part(p."PermissionCode", '.', 2) = 'APPROVE',
      1,
      1
    FROM sec."Permission" p
    WHERE p."Module" IN ('inventario', 'logistica')
       OR (p."Module" IN ('compras', 'ventas') AND split_part(p."PermissionCode", '.', 2) = 'VIEW')
    ON CONFLICT ("RoleId", "PermissionId") DO NOTHING;
  END IF;

  IF v_role_contador IS NOT NULL THEN
    INSERT INTO sec."RolePermission" (
      "RoleId", "PermissionId", "CanCreate", "CanRead", "CanUpdate", "CanDelete", "CanExport", "CanApprove",
      "CreatedByUserId", "UpdatedByUserId"
    )
    SELECT
      v_role_contador,
      p."PermissionId",
      split_part(p."PermissionCode", '.', 2) = 'CREATE',
      split_part(p."PermissionCode", '.', 2) IN ('VIEW', 'PRINT', 'VOID'),
      split_part(p."PermissionCode", '.', 2) = 'EDIT',
      split_part(p."PermissionCode", '.', 2) = 'DELETE',
      split_part(p."PermissionCode", '.', 2) = 'EXPORT',
      split_part(p."PermissionCode", '.', 2) = 'APPROVE',
      1,
      1
    FROM sec."Permission" p
    WHERE p."Module" IN ('contabilidad', 'bancos')
       OR (p."Module" NOT IN ('contabilidad', 'bancos') AND split_part(p."PermissionCode", '.', 2) IN ('VIEW', 'EXPORT'))
    ON CONFLICT ("RoleId", "PermissionId") DO NOTHING;
  END IF;

  RAISE NOTICE '>> 4. Restricciones de precio por rol...';
  IF v_role_vendedor IS NOT NULL AND NOT EXISTS (
    SELECT 1 FROM sec."PriceRestriction" WHERE "CompanyId" = 1 AND "RoleId" = v_role_vendedor AND "IsDeleted" = FALSE
  ) THEN
    INSERT INTO sec."PriceRestriction" (
      "CompanyId", "RoleId", "MaxDiscountPercent", "MinMarginPercent", "RequiresApprovalAbove",
      "IsActive", "CreatedByUserId", "UpdatedByUserId"
    )
    VALUES (1, v_role_vendedor, 15.00, 80.00, 5000.00, TRUE, 1, 1);
  END IF;

  IF v_role_gerente IS NOT NULL AND NOT EXISTS (
    SELECT 1 FROM sec."PriceRestriction" WHERE "CompanyId" = 1 AND "RoleId" = v_role_gerente AND "IsDeleted" = FALSE
  ) THEN
    INSERT INTO sec."PriceRestriction" (
      "CompanyId", "RoleId", "MaxDiscountPercent", "MinMarginPercent", "RequiresApprovalAbove",
      "IsActive", "CreatedByUserId", "UpdatedByUserId"
    )
    VALUES (1, v_role_gerente, 30.00, 50.00, NULL, TRUE, 1, 1);
  END IF;

  RAISE NOTICE '>> 5. Reglas de aprobacion...';
  IF NOT EXISTS (
    SELECT 1 FROM sec."ApprovalRule" WHERE "CompanyId" = 1 AND "RuleCode" = 'ventas:FACTURA:5000' AND "IsDeleted" = FALSE
  ) THEN
    INSERT INTO sec."ApprovalRule" (
      "CompanyId", "RuleCode", "RuleName", "DocumentType", "Condition", "ThresholdAmount",
      "ApproverRoleId", "RequiredApprovals", "IsActive", "CreatedByUserId", "UpdatedByUserId"
    )
    VALUES (
      1, 'ventas:FACTURA:5000', 'Aprobacion facturas > 5000', 'FACTURA', 'AMOUNT_ABOVE', 5000.00,
      v_role_gerente, 1, TRUE, 1, 1
    );
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM sec."ApprovalRule" WHERE "CompanyId" = 1 AND "RuleCode" = 'compras:COMPRA:10000' AND "IsDeleted" = FALSE
  ) THEN
    INSERT INTO sec."ApprovalRule" (
      "CompanyId", "RuleCode", "RuleName", "DocumentType", "Condition", "ThresholdAmount",
      "ApproverRoleId", "RequiredApprovals", "IsActive", "CreatedByUserId", "UpdatedByUserId"
    )
    VALUES (
      1, 'compras:COMPRA:10000', 'Aprobacion compras > 10000', 'COMPRA', 'AMOUNT_ABOVE', 10000.00,
      v_role_gerente, 1, TRUE, 1, 1
    );
  END IF;

  RAISE NOTICE '=== Seed RBAC completado ===';
END $$;
