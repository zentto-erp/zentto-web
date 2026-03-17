-- ============================================================
-- DatqBoxWeb PostgreSQL - 01_core_foundation.sql
-- Schemas + tablas core (sec, cfg)
-- ============================================================

BEGIN;

-- Schemas
CREATE SCHEMA IF NOT EXISTS sec;
CREATE SCHEMA IF NOT EXISTS cfg;
CREATE SCHEMA IF NOT EXISTS master;
CREATE SCHEMA IF NOT EXISTS acct;
CREATE SCHEMA IF NOT EXISTS ar;
CREATE SCHEMA IF NOT EXISTS ap;
CREATE SCHEMA IF NOT EXISTS pos;
CREATE SCHEMA IF NOT EXISTS rest;
CREATE SCHEMA IF NOT EXISTS fiscal;
CREATE SCHEMA IF NOT EXISTS doc;
CREATE SCHEMA IF NOT EXISTS fin;
CREATE SCHEMA IF NOT EXISTS hr;
CREATE SCHEMA IF NOT EXISTS pay;
CREATE SCHEMA IF NOT EXISTS audit;
CREATE SCHEMA IF NOT EXISTS store;

-- ============================================================
-- sec."User" (user es palabra reservada en PG)
-- ============================================================
CREATE TABLE IF NOT EXISTS sec."User"(
  "UserId"            INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "UserCode"          VARCHAR(40) NOT NULL,
  "UserName"          VARCHAR(150) NOT NULL,
  "PasswordHash"      VARCHAR(255),
  "Email"             VARCHAR(150),
  "IsAdmin"           BOOLEAN NOT NULL DEFAULT FALSE,
  "IsActive"          BOOLEAN NOT NULL DEFAULT TRUE,
  "LastLoginAt"       TIMESTAMP,
  "CreatedAt"         TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"         TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId"   INT,
  "UpdatedByUserId"   INT,
  "IsDeleted"         BOOLEAN NOT NULL DEFAULT FALSE,
  "DeletedAt"         TIMESTAMP,
  "DeletedByUserId"   INT,
  "RowVer"            INT NOT NULL DEFAULT 1,
  CONSTRAINT "UQ_sec_User_UserCode" UNIQUE ("UserCode")
);

-- ============================================================
-- sec."Role"
-- ============================================================
CREATE TABLE IF NOT EXISTS sec."Role"(
  "RoleId"            INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "RoleCode"          VARCHAR(40) NOT NULL,
  "RoleName"          VARCHAR(120) NOT NULL,
  "IsSystem"          BOOLEAN NOT NULL DEFAULT FALSE,
  "IsActive"          BOOLEAN NOT NULL DEFAULT TRUE,
  "CreatedAt"         TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"         TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  CONSTRAINT "UQ_sec_Role_RoleCode" UNIQUE ("RoleCode")
);

-- ============================================================
-- sec."UserRole"
-- ============================================================
CREATE TABLE IF NOT EXISTS sec."UserRole"(
  "UserRoleId"        BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "UserId"            INT NOT NULL,
  "RoleId"            INT NOT NULL,
  "CreatedAt"         TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  CONSTRAINT "UQ_sec_UserRole" UNIQUE ("UserId", "RoleId"),
  CONSTRAINT "FK_sec_UserRole_User" FOREIGN KEY ("UserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_sec_UserRole_Role" FOREIGN KEY ("RoleId") REFERENCES sec."Role"("RoleId")
);

-- ============================================================
-- cfg."Country"
-- ============================================================
CREATE TABLE IF NOT EXISTS cfg."Country"(
  "CountryCode"       CHAR(2) NOT NULL PRIMARY KEY,
  "CountryName"       VARCHAR(80) NOT NULL,
  "CurrencyCode"      CHAR(3) NOT NULL,
  "TaxAuthorityCode"  VARCHAR(20) NOT NULL,
  "FiscalIdName"      VARCHAR(20) NOT NULL,
  "TimeZoneIana"      VARCHAR(50) NULL,
  "CurrencySymbol"    VARCHAR(10) NULL,
  "DecimalSeparator"  CHAR(1) DEFAULT '.',
  "ThousandsSeparator" CHAR(1) DEFAULT ',',
  "IsActive"          BOOLEAN NOT NULL DEFAULT TRUE,
  "CreatedAt"         TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"         TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC')
);

-- ============================================================
-- cfg."Company"
-- ============================================================
CREATE TABLE IF NOT EXISTS cfg."Company"(
  "CompanyId"         INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyCode"       VARCHAR(20) NOT NULL,
  "LegalName"         VARCHAR(200) NOT NULL,
  "TradeName"         VARCHAR(200),
  "FiscalCountryCode" CHAR(2) NOT NULL,
  "FiscalId"          VARCHAR(30),
  "BaseCurrency"      CHAR(3) NOT NULL,
  "Address"           VARCHAR(500) NULL,
  "LegalRep"          VARCHAR(200) NULL,
  "Phone"             VARCHAR(50) NULL,
  "IsActive"          BOOLEAN NOT NULL DEFAULT TRUE,
  "CreatedAt"         TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"         TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId"   INT,
  "UpdatedByUserId"   INT,
  "IsDeleted"         BOOLEAN NOT NULL DEFAULT FALSE,
  "DeletedAt"         TIMESTAMP,
  "DeletedByUserId"   INT,
  "RowVer"            INT NOT NULL DEFAULT 1,
  CONSTRAINT "UQ_cfg_Company_CompanyCode" UNIQUE ("CompanyCode"),
  CONSTRAINT "FK_cfg_Company_Country" FOREIGN KEY ("FiscalCountryCode") REFERENCES cfg."Country"("CountryCode"),
  CONSTRAINT "FK_cfg_Company_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_cfg_Company_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId")
);

-- ============================================================
-- cfg."Branch"
-- ============================================================
CREATE TABLE IF NOT EXISTS cfg."Branch"(
  "BranchId"          INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"         INT NOT NULL,
  "BranchCode"        VARCHAR(20) NOT NULL,
  "BranchName"        VARCHAR(150) NOT NULL,
  "AddressLine"       VARCHAR(250),
  "Phone"             VARCHAR(40),
  "CountryCode"       VARCHAR(5) NULL,
  "CurrencyCode"      VARCHAR(5) NULL,
  "IsActive"          BOOLEAN NOT NULL DEFAULT TRUE,
  "CreatedAt"         TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"         TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId"   INT,
  "UpdatedByUserId"   INT,
  "IsDeleted"         BOOLEAN NOT NULL DEFAULT FALSE,
  "DeletedAt"         TIMESTAMP,
  "DeletedByUserId"   INT,
  "RowVer"            INT NOT NULL DEFAULT 1,
  CONSTRAINT "UQ_cfg_Branch" UNIQUE ("CompanyId", "BranchCode"),
  CONSTRAINT "FK_cfg_Branch_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId"),
  CONSTRAINT "FK_cfg_Branch_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_cfg_Branch_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId")
);

-- ============================================================
-- cfg."ExchangeRateDaily"
-- ============================================================
CREATE TABLE IF NOT EXISTS cfg."ExchangeRateDaily"(
  "ExchangeRateDailyId" BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CurrencyCode"        CHAR(3) NOT NULL,
  "RateToBase"          NUMERIC(18,6) NOT NULL,
  "RateDate"            DATE NOT NULL,
  "SourceName"          VARCHAR(120),
  "CreatedAt"           TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId"     INT,
  CONSTRAINT "UQ_cfg_ExchangeRateDaily" UNIQUE ("CurrencyCode", "RateDate"),
  CONSTRAINT "FK_cfg_ExchangeRateDaily_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId")
);

-- ============================================================
-- Seed data inicial
-- ============================================================
INSERT INTO cfg."Country" ("CountryCode", "CountryName", "CurrencyCode", "TaxAuthorityCode", "FiscalIdName")
VALUES ('VE', 'Venezuela', 'VES', 'SENIAT', 'RIF')
ON CONFLICT ("CountryCode") DO NOTHING;

INSERT INTO cfg."Country" ("CountryCode", "CountryName", "CurrencyCode", "TaxAuthorityCode", "FiscalIdName")
VALUES ('ES', 'Espana', 'EUR', 'AEAT', 'NIF')
ON CONFLICT ("CountryCode") DO NOTHING;

INSERT INTO sec."User" ("UserCode", "UserName", "IsAdmin", "IsActive")
VALUES ('SYSTEM', 'System User', TRUE, TRUE)
ON CONFLICT ("UserCode") DO NOTHING;

INSERT INTO sec."Role" ("RoleCode", "RoleName", "IsSystem", "IsActive")
VALUES ('ADMIN', 'Administrators', TRUE, TRUE)
ON CONFLICT ("RoleCode") DO NOTHING;

DO $$
DECLARE
  v_system_user_id INT;
  v_admin_role_id INT;
  v_default_company_id INT;
BEGIN
  SELECT "UserId" INTO v_system_user_id FROM sec."User" WHERE "UserCode" = 'SYSTEM' LIMIT 1;
  SELECT "RoleId" INTO v_admin_role_id FROM sec."Role" WHERE "RoleCode" = 'ADMIN' LIMIT 1;

  IF v_system_user_id IS NOT NULL AND v_admin_role_id IS NOT NULL THEN
    INSERT INTO sec."UserRole" ("UserId", "RoleId")
    VALUES (v_system_user_id, v_admin_role_id)
    ON CONFLICT ("UserId", "RoleId") DO NOTHING;
  END IF;

  INSERT INTO cfg."Company" ("CompanyCode", "LegalName", "TradeName", "FiscalCountryCode", "FiscalId", "BaseCurrency", "CreatedByUserId", "UpdatedByUserId")
  VALUES ('DEFAULT', 'DatqBox Default Company', 'DatqBox', 'VE', 'J-00000000-0', 'VES', v_system_user_id, v_system_user_id)
  ON CONFLICT ("CompanyCode") DO NOTHING;

  SELECT "CompanyId" INTO v_default_company_id FROM cfg."Company" WHERE "CompanyCode" = 'DEFAULT' LIMIT 1;

  IF v_default_company_id IS NOT NULL THEN
    INSERT INTO cfg."Branch" ("CompanyId", "BranchCode", "BranchName", "CreatedByUserId", "UpdatedByUserId")
    VALUES (v_default_company_id, 'MAIN', 'Principal', v_system_user_id, v_system_user_id)
    ON CONFLICT ("CompanyId", "BranchCode") DO NOTHING;
  END IF;
END $$;

COMMIT;
