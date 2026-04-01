-- +goose Up
-- Migration: fix_iam_seed_company_access
-- Adds UserCompanyAccess entries for IAM seed users.
-- Without this, the login flow can't resolve Company/Branch for these users.

INSERT INTO sec."UserCompanyAccess" ("CodUsuario", "CompanyId", "BranchId", "IsActive", "IsDefault")
VALUES
    ('sup.zentto',    1, 1, TRUE, TRUE),
    ('admin.demo',    1, 1, TRUE, TRUE),
    ('gerente.demo',  1, 1, TRUE, TRUE),
    ('contador.demo', 1, 1, TRUE, TRUE),
    ('vendedor.demo', 1, 1, TRUE, TRUE),
    ('cajero.demo',   1, 1, TRUE, TRUE),
    ('auditor.demo',  1, 1, TRUE, TRUE)
ON CONFLICT DO NOTHING;

-- +goose Down
DELETE FROM sec."UserCompanyAccess"
 WHERE "CodUsuario" IN ('sup.zentto','admin.demo','gerente.demo','contador.demo','vendedor.demo','cajero.demo','auditor.demo');
