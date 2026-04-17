-- +goose Up
-- Fix: seed_demo_users usa ON CONFLICT("UserCode") pero el constraint es
-- ahora UNIQUE(UserCode, CompanyId). Actualizar los seeds para usar la key
-- composite. Migración idempotente.

-- +goose StatementBegin
DO $$
DECLARE
  v_company_id INT := 1;
  v_hash TEXT := '$2b$10$GNSTNDBLLzIK6IhRJRQuMeu2ER2x5q.mO5hJXCB2bL0EurZcC8owO'; -- Admin123!
BEGIN
  -- Admin principal
  INSERT INTO sec."User" (
    "UserCode", "CompanyId", "PasswordHash", "UserName", "UserType",
    "Email", "IsAdmin", "IsActive"
  ) VALUES (
    'ADMIN', v_company_id, v_hash, 'Administrador', 'ADMIN',
    'admin@zentto.net', TRUE, TRUE
  ) ON CONFLICT ("UserCode", "CompanyId") DO UPDATE
    SET "PasswordHash" = v_hash,
        "IsAdmin"      = TRUE,
        "IsActive"     = TRUE;

  -- Usuario gerente
  INSERT INTO sec."User" (
    "UserCode", "CompanyId", "PasswordHash", "UserName", "UserType",
    "Email", "IsAdmin", "IsActive"
  ) VALUES (
    'GERENTE', v_company_id, v_hash, 'Gerente Demo', 'USER',
    'gerente@zentto.net', FALSE, TRUE
  ) ON CONFLICT ("UserCode", "CompanyId") DO UPDATE
    SET "PasswordHash" = v_hash, "IsActive" = TRUE;

  -- Usuario cajero
  INSERT INTO sec."User" (
    "UserCode", "CompanyId", "PasswordHash", "UserName", "UserType",
    "Email", "IsAdmin", "IsActive"
  ) VALUES (
    'CAJERO', v_company_id, v_hash, 'Cajero Demo', 'USER',
    'cajero@zentto.net', FALSE, TRUE
  ) ON CONFLICT ("UserCode", "CompanyId") DO UPDATE
    SET "PasswordHash" = v_hash, "IsActive" = TRUE;

  -- Asignar rol ADMIN al admin (en la company principal)
  INSERT INTO sec."UserRole" ("UserId", "RoleId")
  SELECT u."UserId", r."RoleId"
  FROM sec."User" u, sec."Role" r
  WHERE u."UserCode" = 'ADMIN' AND u."CompanyId" = v_company_id AND r."RoleCode" = 'ADMIN'
  ON CONFLICT ("UserId", "RoleId") DO NOTHING;

  RAISE NOTICE '✓ Usuarios demo creados/actualizados con composite key';
END $$;
-- +goose StatementEnd

-- +goose Down
-- No-op: los usuarios demo permanecen. La migración es idempotente.
SELECT 1;
