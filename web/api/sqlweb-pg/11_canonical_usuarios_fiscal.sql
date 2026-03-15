-- ============================================================
-- DatqBoxWeb PostgreSQL - 11_canonical_usuarios_fiscal.sql
-- Migracion dbo.Usuarios -> sec."User", columnas legacy,
-- vistas de compatibilidad, limpieza dbo.Fiscal*
-- Fuente: 22_canonical_usuarios_fiscal.sql
-- ============================================================

BEGIN;

-- ============================================================
-- SECCION 1: AMPLIAR sec."User" CON COLUMNAS LEGACY
-- ============================================================
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'sec' AND table_name = 'User' AND column_name = 'UserType') THEN
    ALTER TABLE sec."User" ADD COLUMN "UserType" VARCHAR(10) NULL;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'sec' AND table_name = 'User' AND column_name = 'CanUpdate') THEN
    ALTER TABLE sec."User" ADD COLUMN "CanUpdate" BOOLEAN NOT NULL DEFAULT TRUE;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'sec' AND table_name = 'User' AND column_name = 'CanCreate') THEN
    ALTER TABLE sec."User" ADD COLUMN "CanCreate" BOOLEAN NOT NULL DEFAULT TRUE;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'sec' AND table_name = 'User' AND column_name = 'CanDelete') THEN
    ALTER TABLE sec."User" ADD COLUMN "CanDelete" BOOLEAN NOT NULL DEFAULT FALSE;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'sec' AND table_name = 'User' AND column_name = 'IsCreator') THEN
    ALTER TABLE sec."User" ADD COLUMN "IsCreator" BOOLEAN NOT NULL DEFAULT FALSE;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'sec' AND table_name = 'User' AND column_name = 'CanChangePwd') THEN
    ALTER TABLE sec."User" ADD COLUMN "CanChangePwd" BOOLEAN NOT NULL DEFAULT TRUE;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'sec' AND table_name = 'User' AND column_name = 'CanChangePrice') THEN
    ALTER TABLE sec."User" ADD COLUMN "CanChangePrice" BOOLEAN NOT NULL DEFAULT FALSE;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'sec' AND table_name = 'User' AND column_name = 'CanGiveCredit') THEN
    ALTER TABLE sec."User" ADD COLUMN "CanGiveCredit" BOOLEAN NOT NULL DEFAULT FALSE;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'sec' AND table_name = 'User' AND column_name = 'Avatar') THEN
    ALTER TABLE sec."User" ADD COLUMN "Avatar" TEXT NULL;
  END IF;
END $$;

-- ============================================================
-- SECCION 2: MIGRAR DATOS public."Usuarios" -> sec."User"
-- Convertir MERGE -> INSERT ... ON CONFLICT DO UPDATE
-- ============================================================
DO $$
BEGIN
  -- Solo migrar si existe la tabla Usuarios como tabla base
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public'
      AND table_name = 'Usuarios'
      AND table_type = 'BASE TABLE'
  ) THEN
    INSERT INTO sec."User" (
      "UserCode", "PasswordHash", "UserName", "IsAdmin", "IsActive",
      "UserType", "CanUpdate", "CanCreate", "CanDelete", "IsCreator",
      "CanChangePwd", "CanChangePrice", "CanGiveCredit", "Avatar",
      "CreatedAt", "UpdatedAt", "IsDeleted"
    )
    SELECT
      "Cod_Usuario",
      "Password",
      "Nombre",
      CASE WHEN "Tipo" IN ('ADMIN','SUP') THEN TRUE ELSE FALSE END,
      TRUE,
      CASE WHEN "Tipo" = 'ADMIN' THEN 'ADMIN'
           WHEN "Tipo" = 'SUP'   THEN 'SUP'
           ELSE 'USER' END,
      COALESCE("Updates", TRUE),
      COALESCE("Addnews", TRUE),
      COALESCE("Deletes", FALSE),
      COALESCE("Creador", FALSE),
      COALESCE("Cambiar", TRUE),
      COALESCE("PrecioMinimo", FALSE),
      COALESCE("Credito", FALSE),
      "Avatar",
      (NOW() AT TIME ZONE 'UTC'),
      (NOW() AT TIME ZONE 'UTC'),
      FALSE
    FROM public."Usuarios"
    ON CONFLICT ("UserCode") DO UPDATE SET
      "PasswordHash"   = EXCLUDED."PasswordHash",
      "UserName"       = EXCLUDED."UserName",
      "IsAdmin"        = EXCLUDED."IsAdmin",
      "UserType"       = EXCLUDED."UserType",
      "CanUpdate"      = EXCLUDED."CanUpdate",
      "CanCreate"      = EXCLUDED."CanCreate",
      "CanDelete"      = EXCLUDED."CanDelete",
      "IsCreator"      = EXCLUDED."IsCreator",
      "CanChangePwd"   = EXCLUDED."CanChangePwd",
      "CanChangePrice" = EXCLUDED."CanChangePrice",
      "CanGiveCredit"  = EXCLUDED."CanGiveCredit",
      "Avatar"         = EXCLUDED."Avatar",
      "IsActive"       = TRUE,
      "UpdatedAt"      = (NOW() AT TIME ZONE 'UTC');

    -- Eliminar tabla legacy
    DROP TABLE public."Usuarios";
  END IF;
END $$;

-- ============================================================
-- SECCION 3: VISTA public."Usuarios" -> sec."User"
-- (mismos nombres de columna legacy)
-- ============================================================
CREATE OR REPLACE VIEW public."Usuarios" AS
SELECT
  "UserCode"       AS "Cod_Usuario",
  "PasswordHash"   AS "Password",
  "UserName"       AS "Nombre",
  "UserType"       AS "Tipo",
  "CanUpdate"      AS "Updates",
  "CanCreate"      AS "Addnews",
  "CanDelete"      AS "Deletes",
  "IsCreator"      AS "Creador",
  "CanChangePwd"   AS "Cambiar",
  "CanChangePrice" AS "PrecioMinimo",
  "CanGiveCredit"  AS "Credito",
  "IsAdmin",
  "Avatar"
FROM sec."User"
WHERE "IsDeleted" = FALSE;

-- ============================================================
-- SECCION 4: REGLAS INSTEAD OF para la vista public."Usuarios"
-- PG usa reglas (RULES) en lugar de INSTEAD OF triggers en vistas
-- ============================================================

-- Regla INSERT
CREATE OR REPLACE RULE "rule_Usuarios_Insert" AS
ON INSERT TO public."Usuarios"
DO INSTEAD
INSERT INTO sec."User" (
  "UserCode", "PasswordHash", "UserName", "IsAdmin", "IsActive",
  "UserType", "CanUpdate", "CanCreate", "CanDelete", "IsCreator",
  "CanChangePwd", "CanChangePrice", "CanGiveCredit", "Avatar",
  "CreatedAt", "UpdatedAt", "IsDeleted"
)
VALUES (
  NEW."Cod_Usuario",
  NEW."Password",
  NEW."Nombre",
  COALESCE(NEW."IsAdmin", FALSE),
  TRUE,
  COALESCE(NEW."Tipo", 'USER'),
  COALESCE(NEW."Updates", TRUE),
  COALESCE(NEW."Addnews", TRUE),
  COALESCE(NEW."Deletes", FALSE),
  COALESCE(NEW."Creador", FALSE),
  COALESCE(NEW."Cambiar", TRUE),
  COALESCE(NEW."PrecioMinimo", FALSE),
  COALESCE(NEW."Credito", FALSE),
  NEW."Avatar",
  (NOW() AT TIME ZONE 'UTC'),
  (NOW() AT TIME ZONE 'UTC'),
  FALSE
);

-- Regla UPDATE
CREATE OR REPLACE RULE "rule_Usuarios_Update" AS
ON UPDATE TO public."Usuarios"
DO INSTEAD
UPDATE sec."User"
SET
  "PasswordHash"   = NEW."Password",
  "UserName"       = NEW."Nombre",
  "UserType"       = NEW."Tipo",
  "IsAdmin"        = NEW."IsAdmin",
  "CanUpdate"      = NEW."Updates",
  "CanCreate"      = NEW."Addnews",
  "CanDelete"      = NEW."Deletes",
  "IsCreator"      = NEW."Creador",
  "CanChangePwd"   = NEW."Cambiar",
  "CanChangePrice" = NEW."PrecioMinimo",
  "CanGiveCredit"  = NEW."Credito",
  "Avatar"         = NEW."Avatar",
  "UpdatedAt"      = (NOW() AT TIME ZONE 'UTC')
WHERE UPPER("UserCode") = UPPER(OLD."Cod_Usuario")
  AND "IsDeleted" = FALSE;

-- Regla DELETE (soft-delete en sec."User")
CREATE OR REPLACE RULE "rule_Usuarios_Delete" AS
ON DELETE TO public."Usuarios"
DO INSTEAD
UPDATE sec."User"
SET
  "IsDeleted" = TRUE,
  "IsActive"  = FALSE,
  "DeletedAt" = (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt" = (NOW() AT TIME ZONE 'UTC')
WHERE UPPER("UserCode") = UPPER(OLD."Cod_Usuario")
  AND "IsDeleted" = FALSE;

-- ============================================================
-- SECCION 5: LIMPIAR public."Fiscal*" (duplicados de fiscal.*)
-- ============================================================
DO $$
DECLARE
  v_has_fk BOOLEAN;
BEGIN
  -- Verificar que no haya FKs dependientes (excepto las propias)
  SELECT EXISTS (
    SELECT 1 FROM information_schema.table_constraints tc
    JOIN information_schema.constraint_column_usage ccu
      ON tc.constraint_name = ccu.constraint_name
    WHERE tc.constraint_type = 'FOREIGN KEY'
      AND ccu.table_schema = 'public'
      AND ccu.table_name IN ('FiscalCountryConfig', 'FiscalTaxRates', 'FiscalInvoiceTypes', 'FiscalRecords')
      AND tc.table_schema = 'public'
      AND tc.table_name NOT IN ('FiscalCountryConfig', 'FiscalTaxRates', 'FiscalInvoiceTypes', 'FiscalRecords')
  ) INTO v_has_fk;

  IF NOT v_has_fk THEN
    -- Las tablas public.Fiscal* se mantienen porque se crearon en 05
    -- y son usadas por la API. No se eliminan aqui.
    -- Si en el futuro se migra a fiscal.*, se pueden eliminar.
    RAISE NOTICE '[11] Tablas public.Fiscal* mantenidas (usadas por API compat bridge).';
  ELSE
    RAISE NOTICE '[11] AVISO: public.Fiscal* tiene dependencias FK externas.';
  END IF;
END $$;

COMMIT;
