-- +goose Up
-- Migration: fix_iam_seed_force_all
-- Force-updates passwords, roles, and user-role assignments for IAM seed users.
-- This runs AFTER baseline bootstrap, so it always works.

-- Password: Zentto2026!
-- Hash generated fresh on 2026-03-31

-- 1. Force update PasswordHash for all seed users
UPDATE sec."User"
   SET "PasswordHash" = '$2b$10$.Inu8RN2dH.Z7ZqAtK.9jOIVX5CwZasiq3ZNaf8aJR5sFclRDJNVS',
       "UpdatedAt"    = NOW() AT TIME ZONE 'UTC'
 WHERE "UserCode" IN (
    'sup.zentto', 'admin.demo', 'gerente.demo', 'contador.demo',
    'vendedor.demo', 'cajero.demo', 'auditor.demo'
 )
   AND "PasswordHash" IS DISTINCT FROM '$2b$10$.Inu8RN2dH.Z7ZqAtK.9jOIVX5CwZasiq3ZNaf8aJR5sFclRDJNVS';

-- 2. Force user-role assignments (delete + re-insert)
DELETE FROM sec."UserRole"
 WHERE "UserId" IN (SELECT "UserId" FROM sec."User" WHERE "UserCode" IN (
    'sup.zentto', 'admin.demo', 'gerente.demo', 'contador.demo',
    'vendedor.demo', 'cajero.demo', 'auditor.demo'
 ));

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
  JOIN sec."Role" r ON r."RoleCode" = mapping.role_code;

-- 3. Force module access (delete + re-insert)
DELETE FROM sec."UserModuleAccess"
 WHERE "UserCode" IN ('sup.zentto','admin.demo','gerente.demo','contador.demo','vendedor.demo','cajero.demo','auditor.demo');

-- SUP + ADMIN: All 29 modules
INSERT INTO sec."UserModuleAccess" ("UserCode", "ModuleCode", "IsAllowed")
SELECT u.uc, m.mc, TRUE
  FROM (VALUES ('sup.zentto'), ('admin.demo')) AS u(uc)
 CROSS JOIN (VALUES
    ('dashboard'),('facturas'),('compras'),('clientes'),('proveedores'),
    ('inventario'),('articulos'),('pagos'),('abonos'),('cuentas-por-pagar'),
    ('cxc'),('cxp'),('bancos'),('contabilidad'),('nomina'),
    ('configuracion'),('reportes'),('usuarios'),
    ('pos'),('restaurante'),('ecommerce'),('auditoria'),
    ('logistica'),('crm'),('manufactura'),('flota'),('shipping'),
    ('report-studio'),('addons')
  ) AS m(mc)
ON CONFLICT ("UserCode", "ModuleCode") DO NOTHING;

-- MANAGER: 20 modules
INSERT INTO sec."UserModuleAccess" ("UserCode", "ModuleCode", "IsAllowed")
SELECT 'gerente.demo', m.mc, TRUE
  FROM (VALUES
    ('dashboard'),('facturas'),('compras'),('clientes'),('proveedores'),
    ('inventario'),('articulos'),('pagos'),('abonos'),('cuentas-por-pagar'),
    ('cxc'),('cxp'),('bancos'),('contabilidad'),('nomina'),
    ('reportes'),('pos'),('restaurante'),('crm'),('auditoria')
  ) AS m(mc)
ON CONFLICT ("UserCode", "ModuleCode") DO NOTHING;

-- ACCOUNTANT: 10 modules
INSERT INTO sec."UserModuleAccess" ("UserCode", "ModuleCode", "IsAllowed")
SELECT 'contador.demo', m.mc, TRUE
  FROM (VALUES
    ('dashboard'),('contabilidad'),('bancos'),('reportes'),
    ('cxc'),('cxp'),('pagos'),('abonos'),('cuentas-por-pagar'),('nomina')
  ) AS m(mc)
ON CONFLICT ("UserCode", "ModuleCode") DO NOTHING;

-- SALESPERSON: 8 modules
INSERT INTO sec."UserModuleAccess" ("UserCode", "ModuleCode", "IsAllowed")
SELECT 'vendedor.demo', m.mc, TRUE
  FROM (VALUES
    ('dashboard'),('facturas'),('clientes'),('articulos'),
    ('inventario'),('reportes'),('cxc'),('abonos')
  ) AS m(mc)
ON CONFLICT ("UserCode", "ModuleCode") DO NOTHING;

-- CASHIER: 4 modules
INSERT INTO sec."UserModuleAccess" ("UserCode", "ModuleCode", "IsAllowed")
SELECT 'cajero.demo', m.mc, TRUE
  FROM (VALUES ('dashboard'),('pos'),('facturas'),('clientes')) AS m(mc)
ON CONFLICT ("UserCode", "ModuleCode") DO NOTHING;

-- VIEWER: 5 modules
INSERT INTO sec."UserModuleAccess" ("UserCode", "ModuleCode", "IsAllowed")
SELECT 'auditor.demo', m.mc, TRUE
  FROM (VALUES ('dashboard'),('reportes'),('auditoria'),('contabilidad'),('bancos')) AS m(mc)
ON CONFLICT ("UserCode", "ModuleCode") DO NOTHING;


-- +goose Down
-- No rollback needed
