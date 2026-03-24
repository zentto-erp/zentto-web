-- +goose Up

-- ─── cfg."PlanModule" ─────────────────────────────────────────────────────────
-- Define qué módulos incluye cada plan. Seed incluido.
CREATE TABLE IF NOT EXISTS cfg."PlanModule" (
  "PlanModuleId" INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "PlanCode"     VARCHAR(30) NOT NULL,
  "ModuleCode"   VARCHAR(60) NOT NULL,
  "IsEnabled"    BOOLEAN NOT NULL DEFAULT TRUE,
  "SortOrder"    SMALLINT NOT NULL DEFAULT 0,
  "CreatedAt"    TIMESTAMP NOT NULL DEFAULT NOW(),
  CONSTRAINT "UQ_PlanModule" UNIQUE ("PlanCode", "ModuleCode")
);

-- ─── sys."License" ───────────────────────────────────────────────────────────
-- Tabla central de licencias — desvinculada de Paddle
-- Soporta: SUBSCRIPTION | LIFETIME | CORPORATE | INTERNAL | TRIAL
CREATE TABLE IF NOT EXISTS sys."License" (
  "LicenseId"       BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"       BIGINT NOT NULL,
  "LicenseType"     VARCHAR(20) NOT NULL DEFAULT 'SUBSCRIPTION',
                    -- SUBSCRIPTION | LIFETIME | CORPORATE | INTERNAL | TRIAL
  "Plan"            VARCHAR(30) NOT NULL DEFAULT 'STARTER',
                    -- FREE | STARTER | PRO | ENTERPRISE
  "LicenseKey"      VARCHAR(64) NOT NULL UNIQUE,
                    -- UUID random para validación de BYOC sin autenticación
  "Status"          VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
                    -- ACTIVE | EXPIRED | SUSPENDED | CANCELLED
  "StartsAt"        TIMESTAMP NOT NULL DEFAULT NOW(),
  "ExpiresAt"       TIMESTAMP,
                    -- NULL = nunca expira (LIFETIME, INTERNAL)
  "PaddleSubId"     VARCHAR(100),
                    -- Solo para LicenseType=SUBSCRIPTION
  "ContractRef"     VARCHAR(100),
                    -- Solo para LicenseType=CORPORATE
  "MaxUsers"        INT,
                    -- NULL = ilimitado
  "MaxBranches"     INT,
                    -- NULL = ilimitado
  "Notes"           TEXT,
  "CreatedAt"       TIMESTAMP NOT NULL DEFAULT NOW(),
  "UpdatedAt"       TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_license_company ON sys."License" ("CompanyId");
CREATE INDEX IF NOT EXISTS idx_license_key ON sys."License" ("LicenseKey");
CREATE INDEX IF NOT EXISTS idx_license_status ON sys."License" ("Status") WHERE "Status" = 'ACTIVE';

-- ─── cfg."Company": agregar LicenseKey ───────────────────────────────────────
-- Campo conveniente para acceso rápido (mismo que sys.License.LicenseKey del registro activo)
ALTER TABLE cfg."Company" ADD COLUMN IF NOT EXISTS "LicenseKey" VARCHAR(64);

-- ─── SEED: plan → módulos ─────────────────────────────────────────────────────
INSERT INTO cfg."PlanModule" ("PlanCode", "ModuleCode", "SortOrder") VALUES
-- FREE
('FREE', 'dashboard', 1),
('FREE', 'facturas', 2),
('FREE', 'clientes', 3),
('FREE', 'inventario', 4),
('FREE', 'articulos', 5),
('FREE', 'reportes', 6),
-- STARTER
('STARTER', 'dashboard', 1),
('STARTER', 'facturas', 2),
('STARTER', 'abonos', 3),
('STARTER', 'cxc', 4),
('STARTER', 'clientes', 5),
('STARTER', 'compras', 6),
('STARTER', 'cxp', 7),
('STARTER', 'cuentas-por-pagar', 8),
('STARTER', 'proveedores', 9),
('STARTER', 'inventario', 10),
('STARTER', 'articulos', 11),
('STARTER', 'pagos', 12),
('STARTER', 'bancos', 13),
('STARTER', 'reportes', 14),
('STARTER', 'configuracion', 15),
('STARTER', 'usuarios', 16),
-- PRO (todo STARTER +)
('PRO', 'dashboard', 1), ('PRO', 'facturas', 2), ('PRO', 'abonos', 3),
('PRO', 'cxc', 4), ('PRO', 'clientes', 5), ('PRO', 'compras', 6),
('PRO', 'cxp', 7), ('PRO', 'cuentas-por-pagar', 8), ('PRO', 'proveedores', 9),
('PRO', 'inventario', 10), ('PRO', 'articulos', 11), ('PRO', 'pagos', 12),
('PRO', 'bancos', 13), ('PRO', 'reportes', 14), ('PRO', 'configuracion', 15),
('PRO', 'usuarios', 16), ('PRO', 'contabilidad', 17), ('PRO', 'nomina', 18),
('PRO', 'pos', 19), ('PRO', 'restaurante', 20), ('PRO', 'ecommerce', 21),
('PRO', 'auditoria', 22), ('PRO', 'logistica', 23), ('PRO', 'crm', 24),
('PRO', 'shipping', 25),
-- ENTERPRISE (todos)
('ENTERPRISE', 'dashboard', 1), ('ENTERPRISE', 'facturas', 2), ('ENTERPRISE', 'abonos', 3),
('ENTERPRISE', 'cxc', 4), ('ENTERPRISE', 'clientes', 5), ('ENTERPRISE', 'compras', 6),
('ENTERPRISE', 'cxp', 7), ('ENTERPRISE', 'cuentas-por-pagar', 8), ('ENTERPRISE', 'proveedores', 9),
('ENTERPRISE', 'inventario', 10), ('ENTERPRISE', 'articulos', 11), ('ENTERPRISE', 'pagos', 12),
('ENTERPRISE', 'bancos', 13), ('ENTERPRISE', 'reportes', 14), ('ENTERPRISE', 'configuracion', 15),
('ENTERPRISE', 'usuarios', 16), ('ENTERPRISE', 'contabilidad', 17), ('ENTERPRISE', 'nomina', 18),
('ENTERPRISE', 'pos', 19), ('ENTERPRISE', 'restaurante', 20), ('ENTERPRISE', 'ecommerce', 21),
('ENTERPRISE', 'auditoria', 22), ('ENTERPRISE', 'logistica', 23), ('ENTERPRISE', 'crm', 24),
('ENTERPRISE', 'shipping', 25), ('ENTERPRISE', 'manufactura', 26), ('ENTERPRISE', 'flota', 27)
ON CONFLICT ("PlanCode", "ModuleCode") DO NOTHING;

-- +goose Down
ALTER TABLE cfg."Company" DROP COLUMN IF EXISTS "LicenseKey";
DROP TABLE IF EXISTS sys."License";
DROP TABLE IF EXISTS cfg."PlanModule";
