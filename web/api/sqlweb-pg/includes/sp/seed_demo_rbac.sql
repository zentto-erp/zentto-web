/*
 * seed_demo_rbac.sql (PostgreSQL)
 * ────────────────────────────────
 * Seed de datos demo para RBAC (Role-Based Access Control) en esquema sec.
 * Idempotente: ON CONFLICT DO NOTHING / WHERE NOT EXISTS.
 *
 * Tablas afectadas:
 *   sec."Permission", sec."Role", sec."RolePermission",
 *   sec."PriceRestriction", sec."ApprovalRule"
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

  -- ============================================================================
  -- SECCION 1: sec."Permission"  (15 modulos x 8 acciones = 120 permisos)
  -- ============================================================================
  RAISE NOTICE '>> 1. Catalogo de permisos (120 registros)...';

  FOR i IN 1..array_length(v_modules, 1) LOOP
    v_module := v_modules[i];
    v_module_label := v_module_labels[i];
    FOR j IN 1..array_length(v_actions, 1) LOOP
      v_action := v_actions[j];
      v_action_label := v_action_labels[j];

      INSERT INTO sec."Permission" ("CompanyId", "PermissionCode", "PermissionName", "Module", "Action", "Description", "IsActive", "CreatedByUserId", "CreatedAt")
      VALUES (1,
        v_module || '.' || v_action,
        v_module_label || ' - ' || v_action_label,
        v_module,
        v_action,
        'Permiso para ' || LOWER(v_action_label) || ' en modulo ' || v_module_label,
        TRUE, 1, NOW() AT TIME ZONE 'UTC')
      ON CONFLICT ("CompanyId", "PermissionCode") DO NOTHING;
    END LOOP;
  END LOOP;

  -- ============================================================================
  -- SECCION 2: sec."Role"  (5 roles)
  -- ============================================================================
  RAISE NOTICE '>> 2. Roles...';

  INSERT INTO sec."Role" ("CompanyId", "RoleCode", "RoleName", "Description", "IsSystem", "IsActive", "CreatedByUserId", "CreatedAt")
  VALUES (1, 'ADMIN', 'Administrador', 'Acceso total al sistema - todos los permisos', TRUE, TRUE, 1, NOW() AT TIME ZONE 'UTC')
  ON CONFLICT ("CompanyId", "RoleCode") DO NOTHING;

  INSERT INTO sec."Role" ("CompanyId", "RoleCode", "RoleName", "Description", "IsSystem", "IsActive", "CreatedByUserId", "CreatedAt")
  VALUES (1, 'GERENTE', 'Gerente', 'Acceso de supervision y aprobacion con permisos amplios', FALSE, TRUE, 1, NOW() AT TIME ZONE 'UTC')
  ON CONFLICT ("CompanyId", "RoleCode") DO NOTHING;

  INSERT INTO sec."Role" ("CompanyId", "RoleCode", "RoleName", "Description", "IsSystem", "IsActive", "CreatedByUserId", "CreatedAt")
  VALUES (1, 'VENDEDOR', 'Vendedor', 'Acceso a ventas y CRM con permisos limitados', FALSE, TRUE, 1, NOW() AT TIME ZONE 'UTC')
  ON CONFLICT ("CompanyId", "RoleCode") DO NOTHING;

  INSERT INTO sec."Role" ("CompanyId", "RoleCode", "RoleName", "Description", "IsSystem", "IsActive", "CreatedByUserId", "CreatedAt")
  VALUES (1, 'ALMACENISTA', 'Almacenista', 'Acceso completo a inventario y logistica', FALSE, TRUE, 1, NOW() AT TIME ZONE 'UTC')
  ON CONFLICT ("CompanyId", "RoleCode") DO NOTHING;

  INSERT INTO sec."Role" ("CompanyId", "RoleCode", "RoleName", "Description", "IsSystem", "IsActive", "CreatedByUserId", "CreatedAt")
  VALUES (1, 'CONTADOR', 'Contador', 'Acceso completo a contabilidad y bancos', FALSE, TRUE, 1, NOW() AT TIME ZONE 'UTC')
  ON CONFLICT ("CompanyId", "RoleCode") DO NOTHING;

  -- Obtener IDs de roles
  SELECT "RoleId" INTO v_role_admin FROM sec."Role" WHERE "CompanyId" = 1 AND "RoleCode" = 'ADMIN' LIMIT 1;
  SELECT "RoleId" INTO v_role_gerente FROM sec."Role" WHERE "CompanyId" = 1 AND "RoleCode" = 'GERENTE' LIMIT 1;
  SELECT "RoleId" INTO v_role_vendedor FROM sec."Role" WHERE "CompanyId" = 1 AND "RoleCode" = 'VENDEDOR' LIMIT 1;
  SELECT "RoleId" INTO v_role_almacenista FROM sec."Role" WHERE "CompanyId" = 1 AND "RoleCode" = 'ALMACENISTA' LIMIT 1;
  SELECT "RoleId" INTO v_role_contador FROM sec."Role" WHERE "CompanyId" = 1 AND "RoleCode" = 'CONTADOR' LIMIT 1;

  -- ============================================================================
  -- SECCION 3: sec."RolePermission"  (asignacion de permisos a roles)
  -- ============================================================================
  RAISE NOTICE '>> 3. Permisos por rol...';

  -- 3a. ADMIN: TODOS los permisos (120)
  IF v_role_admin IS NOT NULL THEN
    INSERT INTO sec."RolePermission" ("RoleId", "PermissionId", "IsGranted", "CreatedByUserId", "CreatedAt")
    SELECT v_role_admin, p."PermissionId", TRUE, 1, NOW() AT TIME ZONE 'UTC'
    FROM sec."Permission" p
    WHERE p."CompanyId" = 1
      AND NOT EXISTS (SELECT 1 FROM sec."RolePermission" rp WHERE rp."RoleId" = v_role_admin AND rp."PermissionId" = p."PermissionId");
  END IF;

  -- 3b. GERENTE: VIEW+EXPORT+PRINT para todos + CREATE+EDIT para ventas,compras,inventario,crm
  IF v_role_gerente IS NOT NULL THEN
    -- VIEW, EXPORT, PRINT para todos
    INSERT INTO sec."RolePermission" ("RoleId", "PermissionId", "IsGranted", "CreatedByUserId", "CreatedAt")
    SELECT v_role_gerente, p."PermissionId", TRUE, 1, NOW() AT TIME ZONE 'UTC'
    FROM sec."Permission" p
    WHERE p."CompanyId" = 1
      AND p."Action" IN ('VIEW', 'EXPORT', 'PRINT')
      AND NOT EXISTS (SELECT 1 FROM sec."RolePermission" rp WHERE rp."RoleId" = v_role_gerente AND rp."PermissionId" = p."PermissionId");

    -- CREATE, EDIT para ventas, compras, inventario, crm
    INSERT INTO sec."RolePermission" ("RoleId", "PermissionId", "IsGranted", "CreatedByUserId", "CreatedAt")
    SELECT v_role_gerente, p."PermissionId", TRUE, 1, NOW() AT TIME ZONE 'UTC'
    FROM sec."Permission" p
    WHERE p."CompanyId" = 1
      AND p."Module" IN ('ventas', 'compras', 'inventario', 'crm')
      AND p."Action" IN ('CREATE', 'EDIT')
      AND NOT EXISTS (SELECT 1 FROM sec."RolePermission" rp WHERE rp."RoleId" = v_role_gerente AND rp."PermissionId" = p."PermissionId");
  END IF;

  -- 3c. VENDEDOR: VIEW para todos + CREATE+EDIT para ventas,crm + PRINT para ventas
  IF v_role_vendedor IS NOT NULL THEN
    -- VIEW para todos
    INSERT INTO sec."RolePermission" ("RoleId", "PermissionId", "IsGranted", "CreatedByUserId", "CreatedAt")
    SELECT v_role_vendedor, p."PermissionId", TRUE, 1, NOW() AT TIME ZONE 'UTC'
    FROM sec."Permission" p
    WHERE p."CompanyId" = 1
      AND p."Action" = 'VIEW'
      AND NOT EXISTS (SELECT 1 FROM sec."RolePermission" rp WHERE rp."RoleId" = v_role_vendedor AND rp."PermissionId" = p."PermissionId");

    -- CREATE, EDIT para ventas, crm
    INSERT INTO sec."RolePermission" ("RoleId", "PermissionId", "IsGranted", "CreatedByUserId", "CreatedAt")
    SELECT v_role_vendedor, p."PermissionId", TRUE, 1, NOW() AT TIME ZONE 'UTC'
    FROM sec."Permission" p
    WHERE p."CompanyId" = 1
      AND p."Module" IN ('ventas', 'crm')
      AND p."Action" IN ('CREATE', 'EDIT')
      AND NOT EXISTS (SELECT 1 FROM sec."RolePermission" rp WHERE rp."RoleId" = v_role_vendedor AND rp."PermissionId" = p."PermissionId");

    -- PRINT para ventas
    INSERT INTO sec."RolePermission" ("RoleId", "PermissionId", "IsGranted", "CreatedByUserId", "CreatedAt")
    SELECT v_role_vendedor, p."PermissionId", TRUE, 1, NOW() AT TIME ZONE 'UTC'
    FROM sec."Permission" p
    WHERE p."CompanyId" = 1
      AND p."Module" = 'ventas'
      AND p."Action" = 'PRINT'
      AND NOT EXISTS (SELECT 1 FROM sec."RolePermission" rp WHERE rp."RoleId" = v_role_vendedor AND rp."PermissionId" = p."PermissionId");
  END IF;

  -- 3d. ALMACENISTA: todos permisos para inventario,logistica + VIEW para compras,ventas
  IF v_role_almacenista IS NOT NULL THEN
    -- Todos para inventario y logistica
    INSERT INTO sec."RolePermission" ("RoleId", "PermissionId", "IsGranted", "CreatedByUserId", "CreatedAt")
    SELECT v_role_almacenista, p."PermissionId", TRUE, 1, NOW() AT TIME ZONE 'UTC'
    FROM sec."Permission" p
    WHERE p."CompanyId" = 1
      AND p."Module" IN ('inventario', 'logistica')
      AND NOT EXISTS (SELECT 1 FROM sec."RolePermission" rp WHERE rp."RoleId" = v_role_almacenista AND rp."PermissionId" = p."PermissionId");

    -- VIEW para compras y ventas
    INSERT INTO sec."RolePermission" ("RoleId", "PermissionId", "IsGranted", "CreatedByUserId", "CreatedAt")
    SELECT v_role_almacenista, p."PermissionId", TRUE, 1, NOW() AT TIME ZONE 'UTC'
    FROM sec."Permission" p
    WHERE p."CompanyId" = 1
      AND p."Module" IN ('compras', 'ventas')
      AND p."Action" = 'VIEW'
      AND NOT EXISTS (SELECT 1 FROM sec."RolePermission" rp WHERE rp."RoleId" = v_role_almacenista AND rp."PermissionId" = p."PermissionId");
  END IF;

  -- 3e. CONTADOR: todos permisos para contabilidad,bancos + VIEW+EXPORT para el resto
  IF v_role_contador IS NOT NULL THEN
    -- Todos para contabilidad y bancos
    INSERT INTO sec."RolePermission" ("RoleId", "PermissionId", "IsGranted", "CreatedByUserId", "CreatedAt")
    SELECT v_role_contador, p."PermissionId", TRUE, 1, NOW() AT TIME ZONE 'UTC'
    FROM sec."Permission" p
    WHERE p."CompanyId" = 1
      AND p."Module" IN ('contabilidad', 'bancos')
      AND NOT EXISTS (SELECT 1 FROM sec."RolePermission" rp WHERE rp."RoleId" = v_role_contador AND rp."PermissionId" = p."PermissionId");

    -- VIEW + EXPORT para todo lo demas
    INSERT INTO sec."RolePermission" ("RoleId", "PermissionId", "IsGranted", "CreatedByUserId", "CreatedAt")
    SELECT v_role_contador, p."PermissionId", TRUE, 1, NOW() AT TIME ZONE 'UTC'
    FROM sec."Permission" p
    WHERE p."CompanyId" = 1
      AND p."Module" NOT IN ('contabilidad', 'bancos')
      AND p."Action" IN ('VIEW', 'EXPORT')
      AND NOT EXISTS (SELECT 1 FROM sec."RolePermission" rp WHERE rp."RoleId" = v_role_contador AND rp."PermissionId" = p."PermissionId");
  END IF;

  -- ============================================================================
  -- SECCION 4: sec."PriceRestriction"  (2 restricciones de precio)
  -- ============================================================================
  RAISE NOTICE '>> 4. Restricciones de precio por rol...';

  -- VENDEDOR: MaxDiscount 15%, MinPrice 80%, RequiresApprovalAbove $5000
  IF v_role_vendedor IS NOT NULL AND NOT EXISTS (SELECT 1 FROM sec."PriceRestriction" WHERE "CompanyId" = 1 AND "RoleId" = v_role_vendedor) THEN
    INSERT INTO sec."PriceRestriction" ("CompanyId", "RoleId", "MaxDiscountPercent", "MinPricePercent", "RequiresApprovalAbove", "Notes", "IsActive", "CreatedByUserId", "CreatedAt")
    VALUES (1, v_role_vendedor, 15.00, 80.00, 5000.00, 'Vendedor: descuento max 15%, precio min 80% del lista, aprobacion requerida sobre $5000', TRUE, 1, NOW() AT TIME ZONE 'UTC');
  END IF;

  -- GERENTE: MaxDiscount 30%, MinPrice 50%
  IF v_role_gerente IS NOT NULL AND NOT EXISTS (SELECT 1 FROM sec."PriceRestriction" WHERE "CompanyId" = 1 AND "RoleId" = v_role_gerente) THEN
    INSERT INTO sec."PriceRestriction" ("CompanyId", "RoleId", "MaxDiscountPercent", "MinPricePercent", "RequiresApprovalAbove", "Notes", "IsActive", "CreatedByUserId", "CreatedAt")
    VALUES (1, v_role_gerente, 30.00, 50.00, NULL, 'Gerente: descuento max 30%, precio min 50% del lista, sin limite de aprobacion', TRUE, 1, NOW() AT TIME ZONE 'UTC');
  END IF;

  -- ============================================================================
  -- SECCION 5: sec."ApprovalRule"  (2 reglas de aprobacion)
  -- ============================================================================
  RAISE NOTICE '>> 5. Reglas de aprobacion...';

  -- ventas.FACTURA: montos > $5000 requieren aprobacion de GERENTE
  IF NOT EXISTS (SELECT 1 FROM sec."ApprovalRule" WHERE "CompanyId" = 1 AND "RuleCode" = 'APR-VENTAS-5K') THEN
    INSERT INTO sec."ApprovalRule" ("CompanyId", "RuleCode", "RuleName", "Module", "DocumentType", "ThresholdAmount", "ApproverRoleId", "ApprovalLevels", "Notes", "IsActive", "CreatedByUserId", "CreatedAt")
    VALUES (1, 'APR-VENTAS-5K', 'Aprobacion facturas > $5,000', 'ventas', 'FACTURA', 5000.00, v_role_gerente, 1, 'Facturas de venta superiores a $5,000 requieren aprobacion del Gerente', TRUE, 1, NOW() AT TIME ZONE 'UTC');
  END IF;

  -- compras.COMPRA: montos > $10000 requieren aprobacion de GERENTE
  IF NOT EXISTS (SELECT 1 FROM sec."ApprovalRule" WHERE "CompanyId" = 1 AND "RuleCode" = 'APR-COMPRAS-10K') THEN
    INSERT INTO sec."ApprovalRule" ("CompanyId", "RuleCode", "RuleName", "Module", "DocumentType", "ThresholdAmount", "ApproverRoleId", "ApprovalLevels", "Notes", "IsActive", "CreatedByUserId", "CreatedAt")
    VALUES (1, 'APR-COMPRAS-10K', 'Aprobacion compras > $10,000', 'compras', 'COMPRA', 10000.00, v_role_gerente, 1, 'Ordenes de compra superiores a $10,000 requieren aprobacion del Gerente', TRUE, 1, NOW() AT TIME ZONE 'UTC');
  END IF;

  RAISE NOTICE '=== Seed RBAC completado ===';
END $$;
