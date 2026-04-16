-- +goose Up
-- Fix: UQ_sec_User_UserCode era UNIQUE(UserCode) global, impidiendo que dos
-- tenants tengan UserCode='ADMIN'. Ahora es UNIQUE(UserCode, CompanyId).
--
-- Las FKs en AuthIdentity, AuthToken y SupervisorBiometricCredential
-- referenciaban UserCode solo. Se agregan CompanyId a esas tablas y se
-- recrean las FKs como composite (UserCode, CompanyId).

-- 1. Drop FKs dependientes
ALTER TABLE sec."AuthIdentity"
  DROP CONSTRAINT IF EXISTS "FK_sec_AuthIdentity_User";
ALTER TABLE sec."AuthToken"
  DROP CONSTRAINT IF EXISTS "FK_sec_AuthToken_User";
ALTER TABLE sec."SupervisorBiometricCredential"
  DROP CONSTRAINT IF EXISTS "FK_SupervisorBiometricCredential_SupervisorUser";

-- 2. Agregar CompanyId a las tablas dependientes (nullable temporalmente)
ALTER TABLE sec."AuthIdentity"
  ADD COLUMN IF NOT EXISTS "CompanyId" INT;
ALTER TABLE sec."AuthToken"
  ADD COLUMN IF NOT EXISTS "CompanyId" INT;
ALTER TABLE sec."SupervisorBiometricCredential"
  ADD COLUMN IF NOT EXISTS "CompanyId" INT;

-- 3. Backfill CompanyId desde sec.User
UPDATE sec."AuthIdentity" ai
SET "CompanyId" = u."CompanyId"
FROM sec."User" u
WHERE u."UserCode" = ai."UserCode"
  AND ai."CompanyId" IS NULL;

UPDATE sec."AuthToken" at2
SET "CompanyId" = u."CompanyId"
FROM sec."User" u
WHERE u."UserCode" = at2."UserCode"
  AND at2."CompanyId" IS NULL;

UPDATE sec."SupervisorBiometricCredential" sbc
SET "CompanyId" = u."CompanyId"
FROM sec."User" u
WHERE u."UserCode" = sbc."SupervisorUserCode"
  AND sbc."CompanyId" IS NULL;

-- 4. Cambiar constraint de sec.User
ALTER TABLE sec."User"
  DROP CONSTRAINT IF EXISTS "UQ_sec_User_UserCode";
ALTER TABLE sec."User"
  ADD CONSTRAINT "UQ_sec_User_UserCode" UNIQUE ("UserCode", "CompanyId");

-- 5. Recrear FKs como composite
ALTER TABLE sec."AuthIdentity"
  ADD CONSTRAINT "FK_sec_AuthIdentity_User"
  FOREIGN KEY ("UserCode", "CompanyId")
  REFERENCES sec."User"("UserCode", "CompanyId");

ALTER TABLE sec."AuthToken"
  ADD CONSTRAINT "FK_sec_AuthToken_User"
  FOREIGN KEY ("UserCode", "CompanyId")
  REFERENCES sec."User"("UserCode", "CompanyId");

ALTER TABLE sec."SupervisorBiometricCredential"
  ADD CONSTRAINT "FK_SupervisorBiometricCredential_SupervisorUser"
  FOREIGN KEY ("SupervisorUserCode", "CompanyId")
  REFERENCES sec."User"("UserCode", "CompanyId");


-- +goose Down
-- Revertir: quitar CompanyId de FKs, volver a UNIQUE(UserCode)

ALTER TABLE sec."AuthIdentity"
  DROP CONSTRAINT IF EXISTS "FK_sec_AuthIdentity_User";
ALTER TABLE sec."AuthToken"
  DROP CONSTRAINT IF EXISTS "FK_sec_AuthToken_User";
ALTER TABLE sec."SupervisorBiometricCredential"
  DROP CONSTRAINT IF EXISTS "FK_SupervisorBiometricCredential_SupervisorUser";

ALTER TABLE sec."User"
  DROP CONSTRAINT IF EXISTS "UQ_sec_User_UserCode";
ALTER TABLE sec."User"
  ADD CONSTRAINT "UQ_sec_User_UserCode" UNIQUE ("UserCode");

ALTER TABLE sec."AuthIdentity"
  ADD CONSTRAINT "FK_sec_AuthIdentity_User"
  FOREIGN KEY ("UserCode") REFERENCES sec."User"("UserCode");
ALTER TABLE sec."AuthToken"
  ADD CONSTRAINT "FK_sec_AuthToken_User"
  FOREIGN KEY ("UserCode") REFERENCES sec."User"("UserCode");
ALTER TABLE sec."SupervisorBiometricCredential"
  ADD CONSTRAINT "FK_SupervisorBiometricCredential_SupervisorUser"
  FOREIGN KEY ("SupervisorUserCode") REFERENCES sec."User"("UserCode");

ALTER TABLE sec."AuthIdentity" DROP COLUMN IF EXISTS "CompanyId";
ALTER TABLE sec."AuthToken" DROP COLUMN IF EXISTS "CompanyId";
ALTER TABLE sec."SupervisorBiometricCredential" DROP COLUMN IF EXISTS "CompanyId";
