-- +goose Up
-- Migration: fix_iam_seed_company_access
-- Adds UserCompanyAccess entries for IAM seed users.
-- Multi-company: SUP/ADMIN have access to all companies, others to specific ones.

-- SUP: Access to ALL companies (4)
INSERT INTO sec."UserCompanyAccess" ("CodUsuario", "CompanyId", "BranchId", "IsActive", "IsDefault")
VALUES
    ('sup.zentto', 1, 1, TRUE, TRUE),
    ('sup.zentto', 1, 3, TRUE, FALSE),
    ('sup.zentto', 2, 2, TRUE, FALSE),
    ('sup.zentto', 3, 4, TRUE, FALSE)
ON CONFLICT DO NOTHING;

-- ADMIN: Access to 3 companies (DEFAULT + Spain + Zentto main)
INSERT INTO sec."UserCompanyAccess" ("CodUsuario", "CompanyId", "BranchId", "IsActive", "IsDefault")
VALUES
    ('admin.demo', 1, 1, TRUE, TRUE),
    ('admin.demo', 1, 3, TRUE, FALSE),
    ('admin.demo', 2, 2, TRUE, FALSE)
ON CONFLICT DO NOTHING;

-- MANAGER: 2 companies (DEFAULT principal + sucursal España)
INSERT INTO sec."UserCompanyAccess" ("CodUsuario", "CompanyId", "BranchId", "IsActive", "IsDefault")
VALUES
    ('gerente.demo', 1, 1, TRUE, TRUE),
    ('gerente.demo', 1, 3, TRUE, FALSE)
ON CONFLICT DO NOTHING;

-- ACCOUNTANT: 2 companies (DEFAULT + Spain para contabilidad multi-pais)
INSERT INTO sec."UserCompanyAccess" ("CodUsuario", "CompanyId", "BranchId", "IsActive", "IsDefault")
VALUES
    ('contador.demo', 1, 1, TRUE, TRUE),
    ('contador.demo', 2, 2, TRUE, FALSE)
ON CONFLICT DO NOTHING;

-- SALESPERSON: Solo empresa principal
INSERT INTO sec."UserCompanyAccess" ("CodUsuario", "CompanyId", "BranchId", "IsActive", "IsDefault")
VALUES
    ('vendedor.demo', 1, 1, TRUE, TRUE)
ON CONFLICT DO NOTHING;

-- CASHIER: Solo empresa principal
INSERT INTO sec."UserCompanyAccess" ("CodUsuario", "CompanyId", "BranchId", "IsActive", "IsDefault")
VALUES
    ('cajero.demo', 1, 1, TRUE, TRUE)
ON CONFLICT DO NOTHING;

-- VIEWER: Solo empresa principal (auditor externo)
INSERT INTO sec."UserCompanyAccess" ("CodUsuario", "CompanyId", "BranchId", "IsActive", "IsDefault")
VALUES
    ('auditor.demo', 1, 1, TRUE, TRUE)
ON CONFLICT DO NOTHING;


-- +goose Down
DELETE FROM sec."UserCompanyAccess"
 WHERE "CodUsuario" IN ('sup.zentto','admin.demo','gerente.demo','contador.demo','vendedor.demo','cajero.demo','auditor.demo');
