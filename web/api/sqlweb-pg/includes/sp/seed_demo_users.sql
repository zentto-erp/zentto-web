-- ============================================================
-- Seed: Usuarios demo con contraseña para acceso inicial
-- Contraseña para todos: Admin123!
-- ============================================================

DO $$
DECLARE
  v_company_id INT := 1;
  v_hash TEXT := '$2b$10$GNSTNDBLLzIK6IhRJRQuMeu2ER2x5q.mO5hJXCB2bL0EurZcC8owO'; -- Admin123!
BEGIN

  -- Admin principal
  INSERT INTO sec."User" (
    "UserCode", "PasswordHash", "UserName", "UserType",
    "Email", "IsAdmin", "IsActive"
  ) VALUES (
    'ADMIN', v_hash, 'Administrador', 'ADMIN',
    'admin@zentto.net', TRUE, TRUE
  ) ON CONFLICT ("UserCode") DO UPDATE
    SET "PasswordHash" = v_hash,
        "IsAdmin"      = TRUE,
        "IsActive"     = TRUE;

  -- Usuario gerente
  INSERT INTO sec."User" (
    "UserCode", "PasswordHash", "UserName", "UserType",
    "Email", "IsAdmin", "IsActive"
  ) VALUES (
    'GERENTE', v_hash, 'Gerente Demo', 'USER',
    'gerente@zentto.net', FALSE, TRUE
  ) ON CONFLICT ("UserCode") DO UPDATE
    SET "PasswordHash" = v_hash, "IsActive" = TRUE;

  -- Usuario cajero
  INSERT INTO sec."User" (
    "UserCode", "PasswordHash", "UserName", "UserType",
    "Email", "IsAdmin", "IsActive"
  ) VALUES (
    'CAJERO', v_hash, 'Cajero Demo', 'USER',
    'cajero@zentto.net', FALSE, TRUE
  ) ON CONFLICT ("UserCode") DO UPDATE
    SET "PasswordHash" = v_hash, "IsActive" = TRUE;

  -- Asignar rol ADMIN al admin
  INSERT INTO sec."UserRole" ("UserId", "RoleId")
  SELECT u."UserId", r."RoleId"
  FROM sec."User" u, sec."Role" r
  WHERE u."UserCode" = 'ADMIN' AND r."RoleCode" = 'ADMIN'
  ON CONFLICT ("UserId", "RoleId") DO NOTHING;

  -- Uniformar clave a todos los usuarios importados del live data
  UPDATE sec."User"
  SET "PasswordHash" = v_hash
  WHERE "PasswordHash" IS NOT NULL
    AND "PasswordHash" <> v_hash;

  RAISE NOTICE '✓ Usuarios demo creados y claves uniformadas — pass: Admin123!';
END $$;
