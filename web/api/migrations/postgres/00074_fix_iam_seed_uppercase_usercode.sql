-- +goose Up
-- Migration: fix_iam_seed_uppercase_usercode
-- The login normalizes UserCode to UPPERCASE before calling the SP.
-- But the SP does case-sensitive WHERE. The seed users were created
-- with lowercase UserCode. Fix: update UserCode to UPPERCASE and
-- cascade the change to UserCompanyAccess and UserModuleAccess.

-- 1. Update UserCode to UPPERCASE in sec.User
UPDATE sec."User" SET "UserCode" = UPPER("UserCode"), "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
 WHERE "UserCode" IN ('sup.zentto','admin.demo','gerente.demo','contador.demo','vendedor.demo','cajero.demo','auditor.demo');

-- 2. Update CodUsuario in sec.UserCompanyAccess
UPDATE sec."UserCompanyAccess" SET "CodUsuario" = UPPER("CodUsuario")
 WHERE "CodUsuario" IN ('sup.zentto','admin.demo','gerente.demo','contador.demo','vendedor.demo','cajero.demo','auditor.demo');

-- 3. Update UserCode in sec.UserModuleAccess
UPDATE sec."UserModuleAccess" SET "UserCode" = UPPER("UserCode"), "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
 WHERE "UserCode" IN ('sup.zentto','admin.demo','gerente.demo','contador.demo','vendedor.demo','cajero.demo','auditor.demo');


-- +goose Down
-- Revert to lowercase
UPDATE sec."User" SET "UserCode" = LOWER("UserCode")
 WHERE "UserCode" IN ('SUP.ZENTTO','ADMIN.DEMO','GERENTE.DEMO','CONTADOR.DEMO','VENDEDOR.DEMO','CAJERO.DEMO','AUDITOR.DEMO');

UPDATE sec."UserCompanyAccess" SET "CodUsuario" = LOWER("CodUsuario")
 WHERE "CodUsuario" IN ('SUP.ZENTTO','ADMIN.DEMO','GERENTE.DEMO','CONTADOR.DEMO','VENDEDOR.DEMO','CAJERO.DEMO','AUDITOR.DEMO');

UPDATE sec."UserModuleAccess" SET "UserCode" = LOWER("UserCode")
 WHERE "UserCode" IN ('SUP.ZENTTO','ADMIN.DEMO','GERENTE.DEMO','CONTADOR.DEMO','VENDEDOR.DEMO','CAJERO.DEMO','AUDITOR.DEMO');
