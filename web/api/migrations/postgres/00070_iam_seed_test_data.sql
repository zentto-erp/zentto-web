-- +goose Up
-- Migration: iam_seed_test_data
-- Seeds roles, permissions, users with roles, module access, and role-permissions
-- for testing the full IAM flow. Idempotent (uses ON CONFLICT).
-- Password for all test users: Zentto2026!

-- =============================================================================
-- 1. SEED: Permission catalog (15 modules × 8 actions = 120 permissions)
-- =============================================================================

-- Call the existing permission seed SP
SELECT * FROM usp_sec_permission_seed();

-- =============================================================================
-- 2. SEED: System Roles (4 base roles)
-- =============================================================================
INSERT INTO sec."Role" ("RoleCode", "RoleName", "IsSystem", "IsActive")
VALUES
    ('SUPERADMIN', 'Super Administrador', TRUE, TRUE),
    ('ADMIN',      'Administrador',       TRUE, TRUE),
    ('MANAGER',    'Gerente',             TRUE, TRUE),
    ('CASHIER',    'Cajero',              FALSE, TRUE),
    ('ACCOUNTANT', 'Contador',            FALSE, TRUE),
    ('WAREHOUSE',  'Almacenista',         FALSE, TRUE),
    ('SALESPERSON','Vendedor',            FALSE, TRUE),
    ('VIEWER',     'Solo Lectura',        FALSE, TRUE)
ON CONFLICT ("RoleCode") DO UPDATE SET
    "RoleName" = EXCLUDED."RoleName",
    "IsSystem" = EXCLUDED."IsSystem",
    "IsActive" = EXCLUDED."IsActive",
    "UpdatedAt" = NOW() AT TIME ZONE 'UTC';

-- =============================================================================
-- 3. SEED: Test Users (7 users covering all levels)
-- =============================================================================
-- Password: Zentto2026! (bcrypt hash below)

INSERT INTO sec."User" ("UserCode", "UserName", "PasswordHash", "Email", "IsAdmin", "UserType", "IsActive", "CompanyId", "DisplayName", "Role", "CanCreate", "CanUpdate", "CanDelete")
VALUES
    -- SUP: Superusuario Zentto (acceso total)
    ('sup.zentto',   'Zentto Support',      '$2b$10$.Inu8RN2dH.Z7ZqAtK.9jOIVX5CwZasiq3ZNaf8aJR5sFclRDJNVS', 'soporte@zentto.net',    TRUE,  'SUP',   TRUE, 1, 'Zentto Support',   'superadmin', TRUE, TRUE, TRUE),
    -- ADMIN: Administrador de empresa
    ('admin.demo',   'Admin Demo',          '$2b$10$.Inu8RN2dH.Z7ZqAtK.9jOIVX5CwZasiq3ZNaf8aJR5sFclRDJNVS', 'admin@demo.zentto.net', TRUE,  'ADMIN', TRUE, 1, 'Admin Demo',       'admin',      TRUE, TRUE, TRUE),
    -- MANAGER: Gerente con acceso amplio pero sin admin
    ('gerente.demo', 'Maria Gonzalez',      '$2b$10$.Inu8RN2dH.Z7ZqAtK.9jOIVX5CwZasiq3ZNaf8aJR5sFclRDJNVS', 'maria@demo.zentto.net', FALSE, 'USER',  TRUE, 1, 'Maria Gonzalez',   'manager',    TRUE, TRUE, FALSE),
    -- ACCOUNTANT: Contador con acceso a contabilidad + bancos
    ('contador.demo','Carlos Mendez',       '$2b$10$.Inu8RN2dH.Z7ZqAtK.9jOIVX5CwZasiq3ZNaf8aJR5sFclRDJNVS', 'carlos@demo.zentto.net',FALSE, 'USER',  TRUE, 1, 'Carlos Mendez',    'user',       TRUE, TRUE, FALSE),
    -- SALESPERSON: Vendedor con acceso a ventas/clientes
    ('vendedor.demo','Ana Torres',          '$2b$10$.Inu8RN2dH.Z7ZqAtK.9jOIVX5CwZasiq3ZNaf8aJR5sFclRDJNVS', 'ana@demo.zentto.net',   FALSE, 'USER',  TRUE, 1, 'Ana Torres',       'user',       TRUE, TRUE, FALSE),
    -- CASHIER: Cajero POS con acceso limitado
    ('cajero.demo',  'Pedro Ramirez',       '$2b$10$.Inu8RN2dH.Z7ZqAtK.9jOIVX5CwZasiq3ZNaf8aJR5sFclRDJNVS', 'pedro@demo.zentto.net', FALSE, 'USER',  TRUE, 1, 'Pedro Ramirez',    'user',       FALSE, FALSE, FALSE),
    -- VIEWER: Solo lectura (para auditorias externas)
    ('auditor.demo', 'Laura Fernandez',     '$2b$10$.Inu8RN2dH.Z7ZqAtK.9jOIVX5CwZasiq3ZNaf8aJR5sFclRDJNVS', 'laura@demo.zentto.net', FALSE, 'USER',  TRUE, 1, 'Laura Fernandez',  'user',       FALSE, FALSE, FALSE)
ON CONFLICT ("UserCode") DO UPDATE SET
    "UserName"     = EXCLUDED."UserName",
    "PasswordHash" = EXCLUDED."PasswordHash",
    "Email"        = EXCLUDED."Email",
    "IsAdmin"      = EXCLUDED."IsAdmin",
    "UserType"     = EXCLUDED."UserType",
    "DisplayName"  = EXCLUDED."DisplayName",
    "Role"         = EXCLUDED."Role",
    "CanCreate"    = EXCLUDED."CanCreate",
    "CanUpdate"    = EXCLUDED."CanUpdate",
    "CanDelete"    = EXCLUDED."CanDelete",
    "UpdatedAt"    = NOW() AT TIME ZONE 'UTC';

-- =============================================================================
-- 4. SEED: User → Role assignments
-- =============================================================================
INSERT INTO sec."UserRole" ("UserId", "RoleId")
SELECT u."UserId", r."RoleId"
  FROM (VALUES
    ('sup.zentto',   'SUPERADMIN'),
    ('admin.demo',   'ADMIN'),
    ('gerente.demo', 'MANAGER'),
    ('contador.demo','ACCOUNTANT'),
    ('vendedor.demo','SALESPERSON'),
    ('cajero.demo',  'CASHIER'),
    ('auditor.demo', 'VIEWER')
  ) AS mapping(user_code, role_code)
  JOIN sec."User" u ON u."UserCode" = mapping.user_code
  JOIN sec."Role" r ON r."RoleCode" = mapping.role_code
ON CONFLICT DO NOTHING;

-- =============================================================================
-- 5. SEED: Module access per user
-- =============================================================================
-- Delete existing test user module access to avoid duplicates
DELETE FROM sec."UserModuleAccess"
 WHERE "UserCode" IN ('sup.zentto','admin.demo','gerente.demo','contador.demo','vendedor.demo','cajero.demo','auditor.demo');

-- SUP + ADMIN: All modules (29)
INSERT INTO sec."UserModuleAccess" ("UserCode", "ModuleCode", "IsAllowed")
SELECT u.user_code, m.module_code, TRUE
  FROM (VALUES ('sup.zentto'), ('admin.demo')) AS u(user_code)
 CROSS JOIN (VALUES
    ('dashboard'),('facturas'),('compras'),('clientes'),('proveedores'),
    ('inventario'),('articulos'),('pagos'),('abonos'),('cuentas-por-pagar'),
    ('cxc'),('cxp'),('bancos'),('contabilidad'),('nomina'),
    ('configuracion'),('reportes'),('usuarios'),
    ('pos'),('restaurante'),('ecommerce'),('auditoria'),
    ('logistica'),('crm'),('manufactura'),('flota'),('shipping'),
    ('report-studio'),('addons')
  ) AS m(module_code);

-- MANAGER: 20 modules (todo excepto admin/backoffice/shipping/manufactura/flota)
INSERT INTO sec."UserModuleAccess" ("UserCode", "ModuleCode", "IsAllowed")
SELECT 'gerente.demo', m.module_code, TRUE
  FROM (VALUES
    ('dashboard'),('facturas'),('compras'),('clientes'),('proveedores'),
    ('inventario'),('articulos'),('pagos'),('abonos'),('cuentas-por-pagar'),
    ('cxc'),('cxp'),('bancos'),('contabilidad'),('nomina'),
    ('reportes'),('pos'),('restaurante'),('crm'),('auditoria')
  ) AS m(module_code);

-- ACCOUNTANT: 10 modules (contabilidad, bancos, reportes, cxc/cxp)
INSERT INTO sec."UserModuleAccess" ("UserCode", "ModuleCode", "IsAllowed")
SELECT 'contador.demo', m.module_code, TRUE
  FROM (VALUES
    ('dashboard'),('contabilidad'),('bancos'),('reportes'),
    ('cxc'),('cxp'),('pagos'),('abonos'),('cuentas-por-pagar'),('nomina')
  ) AS m(module_code);

-- SALESPERSON: 8 modules (ventas, clientes, inventario)
INSERT INTO sec."UserModuleAccess" ("UserCode", "ModuleCode", "IsAllowed")
SELECT 'vendedor.demo', m.module_code, TRUE
  FROM (VALUES
    ('dashboard'),('facturas'),('clientes'),('articulos'),
    ('inventario'),('reportes'),('cxc'),('abonos')
  ) AS m(module_code);

-- CASHIER: 4 modules (POS, facturas)
INSERT INTO sec."UserModuleAccess" ("UserCode", "ModuleCode", "IsAllowed")
SELECT 'cajero.demo', m.module_code, TRUE
  FROM (VALUES
    ('dashboard'),('pos'),('facturas'),('clientes')
  ) AS m(module_code);

-- VIEWER: 5 modules (solo lectura, reportes + dashboards)
INSERT INTO sec."UserModuleAccess" ("UserCode", "ModuleCode", "IsAllowed")
SELECT 'auditor.demo', m.module_code, TRUE
  FROM (VALUES
    ('dashboard'),('reportes'),('auditoria'),('contabilidad'),('bancos')
  ) AS m(module_code);

-- =============================================================================
-- 6. SEED: Role → Permission matrix (granular CRUD per role)
-- =============================================================================

-- Helper: Insert role-permissions for all permissions of a module
-- SUPERADMIN: Full access to everything
INSERT INTO sec."RolePermission" ("RoleId", "PermissionId", "CanCreate", "CanRead", "CanUpdate", "CanDelete", "CanExport", "CanApprove")
SELECT r."RoleId", p."PermissionId", TRUE, TRUE, TRUE, TRUE, TRUE, TRUE
  FROM sec."Role" r, sec."Permission" p
 WHERE r."RoleCode" = 'SUPERADMIN'
   AND p."IsActive" = TRUE
ON CONFLICT DO NOTHING;

-- ADMIN: Full CRUD + Export + Approve on everything
INSERT INTO sec."RolePermission" ("RoleId", "PermissionId", "CanCreate", "CanRead", "CanUpdate", "CanDelete", "CanExport", "CanApprove")
SELECT r."RoleId", p."PermissionId", TRUE, TRUE, TRUE, TRUE, TRUE, TRUE
  FROM sec."Role" r, sec."Permission" p
 WHERE r."RoleCode" = 'ADMIN'
   AND p."IsActive" = TRUE
ON CONFLICT DO NOTHING;

-- MANAGER: CRUD + Export, NO Approve, NO Delete on some
INSERT INTO sec."RolePermission" ("RoleId", "PermissionId", "CanCreate", "CanRead", "CanUpdate", "CanDelete", "CanExport", "CanApprove")
SELECT r."RoleId", p."PermissionId",
       TRUE,  -- CanCreate
       TRUE,  -- CanRead
       TRUE,  -- CanUpdate
       CASE WHEN p."Module" IN ('contabilidad', 'nomina', 'auditoria') THEN FALSE ELSE TRUE END,  -- CanDelete
       TRUE,  -- CanExport
       FALSE  -- CanApprove
  FROM sec."Role" r, sec."Permission" p
 WHERE r."RoleCode" = 'MANAGER'
   AND p."IsActive" = TRUE
ON CONFLICT DO NOTHING;

-- ACCOUNTANT: CRUD on contabilidad/bancos/nomina, Read-only on rest
INSERT INTO sec."RolePermission" ("RoleId", "PermissionId", "CanCreate", "CanRead", "CanUpdate", "CanDelete", "CanExport", "CanApprove")
SELECT r."RoleId", p."PermissionId",
       CASE WHEN p."Module" IN ('contabilidad', 'bancos', 'nomina') THEN TRUE ELSE FALSE END,
       TRUE,
       CASE WHEN p."Module" IN ('contabilidad', 'bancos', 'nomina') THEN TRUE ELSE FALSE END,
       FALSE,
       TRUE,
       CASE WHEN p."Module" = 'contabilidad' THEN TRUE ELSE FALSE END
  FROM sec."Role" r, sec."Permission" p
 WHERE r."RoleCode" = 'ACCOUNTANT'
   AND p."IsActive" = TRUE
   AND p."Module" IN ('contabilidad', 'bancos', 'nomina', 'ventas', 'compras', 'auditoria')
ON CONFLICT DO NOTHING;

-- SALESPERSON: CRUD on ventas/inventario, Read on others
INSERT INTO sec."RolePermission" ("RoleId", "PermissionId", "CanCreate", "CanRead", "CanUpdate", "CanDelete", "CanExport", "CanApprove")
SELECT r."RoleId", p."PermissionId",
       CASE WHEN p."Module" IN ('ventas', 'inventario') THEN TRUE ELSE FALSE END,
       TRUE,
       CASE WHEN p."Module" IN ('ventas', 'inventario') THEN TRUE ELSE FALSE END,
       FALSE,
       CASE WHEN p."Module" = 'ventas' THEN TRUE ELSE FALSE END,
       FALSE
  FROM sec."Role" r, sec."Permission" p
 WHERE r."RoleCode" = 'SALESPERSON'
   AND p."IsActive" = TRUE
   AND p."Module" IN ('ventas', 'inventario', 'compras')
ON CONFLICT DO NOTHING;

-- CASHIER: Create/Read on pos/ventas only, no delete/export/approve
INSERT INTO sec."RolePermission" ("RoleId", "PermissionId", "CanCreate", "CanRead", "CanUpdate", "CanDelete", "CanExport", "CanApprove")
SELECT r."RoleId", p."PermissionId",
       CASE WHEN p."Module" = 'pos' THEN TRUE ELSE FALSE END,
       TRUE,
       FALSE,
       FALSE,
       FALSE,
       FALSE
  FROM sec."Role" r, sec."Permission" p
 WHERE r."RoleCode" = 'CASHIER'
   AND p."IsActive" = TRUE
   AND p."Module" IN ('pos', 'ventas')
ON CONFLICT DO NOTHING;

-- VIEWER: Read-only + Export on everything, nothing else
INSERT INTO sec."RolePermission" ("RoleId", "PermissionId", "CanCreate", "CanRead", "CanUpdate", "CanDelete", "CanExport", "CanApprove")
SELECT r."RoleId", p."PermissionId",
       FALSE,  -- CanCreate
       TRUE,   -- CanRead
       FALSE,  -- CanUpdate
       FALSE,  -- CanDelete
       TRUE,   -- CanExport
       FALSE   -- CanApprove
  FROM sec."Role" r, sec."Permission" p
 WHERE r."RoleCode" = 'VIEWER'
   AND p."IsActive" = TRUE
ON CONFLICT DO NOTHING;

-- =============================================================================
-- 7. SEED: License for CompanyId=1 (PRO plan for testing)
-- =============================================================================
-- Upsert license: update if exists, insert if not (CompanyId is not UNIQUE)
UPDATE sys."License"
   SET "Plan"                = 'PRO',
       "Status"              = 'ACTIVE',
       "MaxUsers"            = 15,
       "MaxBranches"         = 5,
       "MaxCompanies"        = 3,
       "MultiCompanyEnabled" = TRUE,
       "ExpiresAt"           = (NOW() AT TIME ZONE 'UTC') + INTERVAL '365 days',
       "UpdatedAt"           = NOW() AT TIME ZONE 'UTC'
 WHERE "CompanyId" = 1;

INSERT INTO sys."License" ("CompanyId", "LicenseKey", "LicenseType", "Plan", "Status", "MaxUsers", "MaxBranches", "MaxCompanies", "MultiCompanyEnabled", "StartsAt", "ExpiresAt")
SELECT 1, 'ZENTTO-DEMO-PRO-' || md5(random()::text), 'SUBSCRIPTION', 'PRO', 'ACTIVE', 15, 5, 3, TRUE, NOW() AT TIME ZONE 'UTC', (NOW() AT TIME ZONE 'UTC') + INTERVAL '365 days'
 WHERE NOT EXISTS (SELECT 1 FROM sys."License" WHERE "CompanyId" = 1);


-- +goose Down

-- Remove seed data in reverse order
DELETE FROM sec."RolePermission"
 WHERE "RoleId" IN (SELECT "RoleId" FROM sec."Role" WHERE "RoleCode" IN ('SUPERADMIN','ADMIN','MANAGER','CASHIER','ACCOUNTANT','WAREHOUSE','SALESPERSON','VIEWER'));

DELETE FROM sec."UserModuleAccess"
 WHERE "UserCode" IN ('sup.zentto','admin.demo','gerente.demo','contador.demo','vendedor.demo','cajero.demo','auditor.demo');

DELETE FROM sec."UserRole"
 WHERE "UserId" IN (SELECT "UserId" FROM sec."User" WHERE "UserCode" IN ('sup.zentto','admin.demo','gerente.demo','contador.demo','vendedor.demo','cajero.demo','auditor.demo'));

DELETE FROM sec."User"
 WHERE "UserCode" IN ('sup.zentto','admin.demo','gerente.demo','contador.demo','vendedor.demo','cajero.demo','auditor.demo');

DELETE FROM sec."Role"
 WHERE "RoleCode" IN ('SUPERADMIN','ADMIN','MANAGER','CASHIER','ACCOUNTANT','WAREHOUSE','SALESPERSON','VIEWER');

DELETE FROM sys."License" WHERE "CompanyId" = 1;
