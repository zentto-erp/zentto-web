-- ============================================================
-- DatqBoxWeb PostgreSQL - create_supervisor_biometric_credentials.sql
-- Tabla de credenciales biometricas de supervisores
-- ============================================================

CREATE SCHEMA IF NOT EXISTS sec;

CREATE TABLE IF NOT EXISTS sec."SupervisorBiometricCredential" (
  "BiometricCredentialId"  BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "SupervisorUserCode"     VARCHAR(10) NOT NULL,
  "CredentialHash"         CHAR(64) NOT NULL,
  "CredentialId"           VARCHAR(512) NOT NULL,
  "CredentialLabel"        VARCHAR(120) NULL,
  "DeviceInfo"             VARCHAR(300) NULL,
  "IsActive"               BOOLEAN NOT NULL DEFAULT TRUE,
  "LastValidatedAtUtc"     TIMESTAMP(3) NULL,
  "CreatedAtUtc"           TIMESTAMP(3) NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAtUtc"           TIMESTAMP(3) NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserCode"      VARCHAR(10) NULL,
  "UpdatedByUserCode"      VARCHAR(10) NULL,

  CONSTRAINT "FK_SupervisorBiometricCredential_SupervisorUser"
    FOREIGN KEY ("SupervisorUserCode") REFERENCES sec."User"("UserCode")
);

CREATE UNIQUE INDEX IF NOT EXISTS "UX_SupervisorBiometricCredential_UserHash"
  ON sec."SupervisorBiometricCredential" ("SupervisorUserCode", "CredentialHash");

CREATE INDEX IF NOT EXISTS "IX_SupervisorBiometricCredential_Active"
  ON sec."SupervisorBiometricCredential" ("SupervisorUserCode", "IsActive", "LastValidatedAtUtc" DESC);
