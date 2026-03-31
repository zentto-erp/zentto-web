-- +goose Up
-- Migration: fix_iam_seed_passwords
-- Updates PasswordHash for IAM test users (00070 didn't update passwords on conflict).
-- Password: Zentto2026!
-- bcrypt hash: $2b$10$.Inu8RN2dH.Z7ZqAtK.9jOIVX5CwZasiq3ZNaf8aJR5sFclRDJNVS

UPDATE sec."User"
   SET "PasswordHash" = '$2b$10$.Inu8RN2dH.Z7ZqAtK.9jOIVX5CwZasiq3ZNaf8aJR5sFclRDJNVS',
       "UpdatedAt"    = NOW() AT TIME ZONE 'UTC'
 WHERE "UserCode" IN (
    'sup.zentto', 'admin.demo', 'gerente.demo', 'contador.demo',
    'vendedor.demo', 'cajero.demo', 'auditor.demo'
 );

-- +goose Down
-- No rollback needed — passwords were already set in 00070 seed
