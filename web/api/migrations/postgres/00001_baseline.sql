-- +goose Up
-- Baseline migration: estado completo de la base de datos
-- Generado automaticamente desde run_all.sql el 2026-03-28

-- Source: run_all.sql
-- ============================================================
-- DatqBoxWeb PostgreSQL - run_all.sql
-- Script maestro de despliegue
-- Ejecutar: psql -U postgres -d datqboxweb -f run_all.sql
-- ============================================================


-- Bootstrap: crear tabla _migrations antes que cualquier otra cosa
-- (requerida por los scripts de migrations/ y por SP contract tests)
CREATE TABLE IF NOT EXISTS public._migrations (
  id         SERIAL PRIMARY KEY,
  name       VARCHAR(255) NOT NULL UNIQUE,
  applied_at TIMESTAMP DEFAULT NOW()
);
INSERT INTO public._migrations (name) VALUES ('run_all.sql')
  ON CONFLICT (name) DO NOTHING;

-- ====================================================================
-- FASE 1: Base de datos (ejecutar manualmente la primera vez)
-- psql -U postgres -f 00_create_database.sql
-- ====================================================================

-- ====================================================================
-- FASE 2: DDL - Tablas y schemas
-- ====================================================================

-- Source: 01_core_foundation.sql
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
  "UserType"          VARCHAR(10) DEFAULT 'USER',
  "CanUpdate"         BOOLEAN NOT NULL DEFAULT TRUE,
  "CanCreate"         BOOLEAN NOT NULL DEFAULT TRUE,
  "CanDelete"         BOOLEAN NOT NULL DEFAULT FALSE,
  "IsCreator"         BOOLEAN NOT NULL DEFAULT FALSE,
  "CanChangePwd"      BOOLEAN NOT NULL DEFAULT TRUE,
  "CanChangePrice"    BOOLEAN NOT NULL DEFAULT FALSE,
  "CanGiveCredit"     BOOLEAN NOT NULL DEFAULT FALSE,
  "Avatar"            TEXT,
  "CompanyId"         INT DEFAULT 1,
  "DisplayName"       VARCHAR(200),
  "Role"              VARCHAR(30) DEFAULT 'admin',
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

-- +goose StatementBegin
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
-- +goose StatementEnd

COMMIT;

-- Source: 02_master_data.sql
-- ============================================================
-- DatqBoxWeb PostgreSQL - 02_master_data.sql
-- Tablas maestras: Customer, Supplier, Employee, Product
-- ============================================================

BEGIN;

-- ---------------------------------------------------------
-- master."Customer"
-- ---------------------------------------------------------
CREATE TABLE IF NOT EXISTS master."Customer" (
  "CustomerId"           BIGINT GENERATED ALWAYS AS IDENTITY NOT NULL PRIMARY KEY,
  "CompanyId"            INT NOT NULL,
  "CustomerCode"         VARCHAR(24) NOT NULL,
  "CustomerName"         VARCHAR(200) NOT NULL,
  "FiscalId"             VARCHAR(30) NULL,
  "Email"                VARCHAR(150) NULL,
  "Phone"                VARCHAR(40) NULL,
  "AddressLine"          VARCHAR(250) NULL,
  "CreditLimit"          NUMERIC(18,2) NOT NULL CONSTRAINT "DF_master_Customer_CreditLimit" DEFAULT 0,
  "TotalBalance"         NUMERIC(18,2) NOT NULL CONSTRAINT "DF_master_Customer_TotalBalance" DEFAULT 0,
  "IsActive"             BOOLEAN NOT NULL CONSTRAINT "DF_master_Customer_IsActive" DEFAULT TRUE,
  "CreatedAt"            TIMESTAMP NOT NULL CONSTRAINT "DF_master_Customer_CreatedAt" DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"            TIMESTAMP NOT NULL CONSTRAINT "DF_master_Customer_UpdatedAt" DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId"      INT NULL,
  "UpdatedByUserId"      INT NULL,
  "IsDeleted"            BOOLEAN NOT NULL CONSTRAINT "DF_master_Customer_IsDeleted" DEFAULT FALSE,
  "DeletedAt"            TIMESTAMP NULL,
  "DeletedByUserId"      INT NULL,
  "RowVer"               INT NOT NULL DEFAULT 1,
  CONSTRAINT "UQ_master_Customer" UNIQUE ("CompanyId", "CustomerCode"),
  CONSTRAINT "FK_master_Customer_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId"),
  CONSTRAINT "FK_master_Customer_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_master_Customer_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId")
);

-- ---------------------------------------------------------
-- master."Supplier"
-- ---------------------------------------------------------
CREATE TABLE IF NOT EXISTS master."Supplier" (
  "SupplierId"           BIGINT GENERATED ALWAYS AS IDENTITY NOT NULL PRIMARY KEY,
  "CompanyId"            INT NOT NULL,
  "SupplierCode"         VARCHAR(24) NOT NULL,
  "SupplierName"         VARCHAR(200) NOT NULL,
  "FiscalId"             VARCHAR(30) NULL,
  "Email"                VARCHAR(150) NULL,
  "Phone"                VARCHAR(40) NULL,
  "AddressLine"          VARCHAR(250) NULL,
  "CreditLimit"          NUMERIC(18,2) NOT NULL CONSTRAINT "DF_master_Supplier_CreditLimit" DEFAULT 0,
  "TotalBalance"         NUMERIC(18,2) NOT NULL CONSTRAINT "DF_master_Supplier_TotalBalance" DEFAULT 0,
  "IsActive"             BOOLEAN NOT NULL CONSTRAINT "DF_master_Supplier_IsActive" DEFAULT TRUE,
  "CreatedAt"            TIMESTAMP NOT NULL CONSTRAINT "DF_master_Supplier_CreatedAt" DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"            TIMESTAMP NOT NULL CONSTRAINT "DF_master_Supplier_UpdatedAt" DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId"      INT NULL,
  "UpdatedByUserId"      INT NULL,
  "IsDeleted"            BOOLEAN NOT NULL CONSTRAINT "DF_master_Supplier_IsDeleted" DEFAULT FALSE,
  "DeletedAt"            TIMESTAMP NULL,
  "DeletedByUserId"      INT NULL,
  "RowVer"               INT NOT NULL DEFAULT 1,
  CONSTRAINT "UQ_master_Supplier" UNIQUE ("CompanyId", "SupplierCode"),
  CONSTRAINT "FK_master_Supplier_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId"),
  CONSTRAINT "FK_master_Supplier_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_master_Supplier_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId")
);

-- ---------------------------------------------------------
-- master."Employee"
-- ---------------------------------------------------------
CREATE TABLE IF NOT EXISTS master."Employee" (
  "EmployeeId"           BIGINT GENERATED ALWAYS AS IDENTITY NOT NULL PRIMARY KEY,
  "CompanyId"            INT NOT NULL,
  "EmployeeCode"         VARCHAR(24) NOT NULL,
  "EmployeeName"         VARCHAR(200) NOT NULL,
  "FiscalId"             VARCHAR(30) NULL,
  "HireDate"             DATE NULL,
  "TerminationDate"      DATE NULL,
  "PositionName"         VARCHAR(150) NULL,
  "DepartmentName"       VARCHAR(150) NULL,
  "Salary"               DECIMAL(18,2) NULL,
  "IsActive"             BOOLEAN NOT NULL CONSTRAINT "DF_master_Employee_IsActive" DEFAULT TRUE,
  "CreatedAt"            TIMESTAMP NOT NULL CONSTRAINT "DF_master_Employee_CreatedAt" DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"            TIMESTAMP NOT NULL CONSTRAINT "DF_master_Employee_UpdatedAt" DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId"      INT NULL,
  "UpdatedByUserId"      INT NULL,
  "IsDeleted"            BOOLEAN NOT NULL CONSTRAINT "DF_master_Employee_IsDeleted" DEFAULT FALSE,
  "DeletedAt"            TIMESTAMP NULL,
  "DeletedByUserId"      INT NULL,
  "RowVer"               INT NOT NULL DEFAULT 1,
  CONSTRAINT "UQ_master_Employee" UNIQUE ("CompanyId", "EmployeeCode"),
  CONSTRAINT "FK_master_Employee_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId"),
  CONSTRAINT "FK_master_Employee_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_master_Employee_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId")
);

-- ---------------------------------------------------------
-- master."Product"
-- ---------------------------------------------------------
CREATE TABLE IF NOT EXISTS master."Product" (
  "ProductId"            BIGINT GENERATED ALWAYS AS IDENTITY NOT NULL PRIMARY KEY,
  "CompanyId"            INT NOT NULL,
  "ProductCode"          VARCHAR(80) NOT NULL,
  "ProductName"          VARCHAR(250) NOT NULL,
  "CategoryCode"         VARCHAR(50) NULL,
  "UnitCode"             VARCHAR(20) NULL,
  "SalesPrice"           NUMERIC(18,2) NOT NULL CONSTRAINT "DF_master_Product_SalesPrice" DEFAULT 0,
  "CostPrice"            NUMERIC(18,2) NOT NULL CONSTRAINT "DF_master_Product_CostPrice" DEFAULT 0,
  "DefaultTaxCode"       VARCHAR(30) NULL,
  "DefaultTaxRate"       NUMERIC(9,4) NOT NULL CONSTRAINT "DF_master_Product_DefaultTaxRate" DEFAULT 0,
  "StockQty"             NUMERIC(18,3) NOT NULL CONSTRAINT "DF_master_Product_StockQty" DEFAULT 0,
  "IsService"            BOOLEAN NOT NULL CONSTRAINT "DF_master_Product_IsService" DEFAULT FALSE,
  "IsActive"             BOOLEAN NOT NULL CONSTRAINT "DF_master_Product_IsActive" DEFAULT TRUE,
  "CreatedAt"            TIMESTAMP NOT NULL CONSTRAINT "DF_master_Product_CreatedAt" DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"            TIMESTAMP NOT NULL CONSTRAINT "DF_master_Product_UpdatedAt" DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId"      INT NULL,
  "UpdatedByUserId"      INT NULL,
  "IsDeleted"            BOOLEAN NOT NULL CONSTRAINT "DF_master_Product_IsDeleted" DEFAULT FALSE,
  "DeletedAt"            TIMESTAMP NULL,
  "DeletedByUserId"      INT NULL,
  "RowVer"               INT NOT NULL DEFAULT 1,
  -- Columnas ecommerce
  "ShortDescription"     VARCHAR(500) NULL,
  "LongDescription"      TEXT NULL,
  "CompareAtPrice"       NUMERIC(18,4) NULL,
  "BrandCode"            VARCHAR(20) NULL,
  "BarCode"              VARCHAR(50) NULL,
  "Slug"                 VARCHAR(200) NULL,
  "WeightKg"             NUMERIC(10,3) NULL,
  "WidthCm"              NUMERIC(10,2) NULL,
  "HeightCm"             NUMERIC(10,2) NULL,
  "DepthCm"              NUMERIC(10,2) NULL,
  "WarrantyMonths"       INT NULL,
  "IsVariantParent"      BOOLEAN NOT NULL DEFAULT FALSE,
  "ParentProductCode"    VARCHAR(80) NULL,
  "IndustryTemplateCode" VARCHAR(30) NULL,
  CONSTRAINT "UQ_master_Product" UNIQUE ("CompanyId", "ProductCode"),
  CONSTRAINT "FK_master_Product_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId"),
  CONSTRAINT "FK_master_Product_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_master_Product_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId")
);

CREATE INDEX IF NOT EXISTS "IX_master_Product_Company_IsActive"
  ON master."Product" ("CompanyId", "IsActive", "ProductCode");

COMMIT;

-- Source: 03_accounting_core.sql
-- ============================================================
-- DatqBoxWeb PostgreSQL - 03_accounting_core.sql
-- Tablas contables: Account, JournalEntry, JournalEntryLine,
--                   DocumentLink, AccountingPolicy
-- ============================================================

BEGIN;

-- ---------------------------------------------------------
-- acct."Account"
-- ---------------------------------------------------------
CREATE TABLE IF NOT EXISTS acct."Account" (
  "AccountId"             BIGINT GENERATED ALWAYS AS IDENTITY NOT NULL PRIMARY KEY,
  "CompanyId"             INT NOT NULL,
  "AccountCode"           VARCHAR(40) NOT NULL,
  "AccountName"           VARCHAR(200) NOT NULL,
  "AccountType"           CHAR(1) NOT NULL, -- A,P,C,I,G
  "AccountLevel"          INT NOT NULL CONSTRAINT "DF_acct_Account_Level" DEFAULT 1,
  "ParentAccountId"       BIGINT NULL,
  "AllowsPosting"         BOOLEAN NOT NULL CONSTRAINT "DF_acct_Account_AllowsPosting" DEFAULT TRUE,
  "RequiresAuxiliary"     BOOLEAN NOT NULL CONSTRAINT "DF_acct_Account_RequiresAux" DEFAULT FALSE,
  "IsActive"              BOOLEAN NOT NULL CONSTRAINT "DF_acct_Account_IsActive" DEFAULT TRUE,
  "CreatedAt"             TIMESTAMP NOT NULL CONSTRAINT "DF_acct_Account_CreatedAt" DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"             TIMESTAMP NOT NULL CONSTRAINT "DF_acct_Account_UpdatedAt" DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId"       INT NULL,
  "UpdatedByUserId"       INT NULL,
  "IsDeleted"             BOOLEAN NOT NULL CONSTRAINT "DF_acct_Account_IsDeleted" DEFAULT FALSE,
  "DeletedAt"             TIMESTAMP NULL,
  "DeletedByUserId"       INT NULL,
  "RowVer"                INT NOT NULL DEFAULT 1,
  CONSTRAINT "CK_acct_Account_AccountType" CHECK ("AccountType" IN ('A', 'P', 'C', 'I', 'G')),
  CONSTRAINT "UQ_acct_Account" UNIQUE ("CompanyId", "AccountCode"),
  CONSTRAINT "FK_acct_Account_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId"),
  CONSTRAINT "FK_acct_Account_Parent" FOREIGN KEY ("ParentAccountId") REFERENCES acct."Account"("AccountId"),
  CONSTRAINT "FK_acct_Account_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_acct_Account_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId")
);

CREATE INDEX IF NOT EXISTS "IX_acct_Account_Company_Parent"
  ON acct."Account" ("CompanyId", "ParentAccountId", "AccountCode");

-- ---------------------------------------------------------
-- acct."JournalEntry"
-- ---------------------------------------------------------
CREATE TABLE IF NOT EXISTS acct."JournalEntry" (
  "JournalEntryId"        BIGINT GENERATED ALWAYS AS IDENTITY NOT NULL PRIMARY KEY,
  "CompanyId"             INT NOT NULL,
  "BranchId"              INT NOT NULL,
  "EntryNumber"           VARCHAR(40) NOT NULL,
  "EntryDate"             DATE NOT NULL,
  "PeriodCode"            VARCHAR(7) NOT NULL,
  "EntryType"             VARCHAR(20) NOT NULL,
  "ReferenceNumber"       VARCHAR(120) NULL,
  "Concept"               VARCHAR(400) NOT NULL,
  "CurrencyCode"          CHAR(3) NOT NULL,
  "ExchangeRate"          NUMERIC(18,6) NOT NULL CONSTRAINT "DF_acct_JE_ExRate" DEFAULT 1,
  "TotalDebit"            NUMERIC(18,2) NOT NULL CONSTRAINT "DF_acct_JE_Debit" DEFAULT 0,
  "TotalCredit"           NUMERIC(18,2) NOT NULL CONSTRAINT "DF_acct_JE_Credit" DEFAULT 0,
  "Status"                VARCHAR(20) NOT NULL CONSTRAINT "DF_acct_JE_Status" DEFAULT 'APPROVED',
  "SourceModule"          VARCHAR(40) NULL,
  "SourceDocumentType"    VARCHAR(40) NULL,
  "SourceDocumentNo"      VARCHAR(120) NULL,
  "CreatedAt"             TIMESTAMP NOT NULL CONSTRAINT "DF_acct_JE_CreatedAt" DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"             TIMESTAMP NOT NULL CONSTRAINT "DF_acct_JE_UpdatedAt" DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId"       INT NULL,
  "UpdatedByUserId"       INT NULL,
  "IsDeleted"             BOOLEAN NOT NULL CONSTRAINT "DF_acct_JE_IsDeleted" DEFAULT FALSE,
  "DeletedAt"             TIMESTAMP NULL,
  "DeletedByUserId"       INT NULL,
  "RowVer"                INT NOT NULL DEFAULT 1,
  CONSTRAINT "CK_acct_JE_Status" CHECK ("Status" IN ('DRAFT','APPROVED','VOIDED')),
  CONSTRAINT "UQ_acct_JE" UNIQUE ("CompanyId", "BranchId", "EntryNumber"),
  CONSTRAINT "FK_acct_JE_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId"),
  CONSTRAINT "FK_acct_JE_Branch" FOREIGN KEY ("BranchId") REFERENCES cfg."Branch"("BranchId"),
  CONSTRAINT "FK_acct_JE_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_acct_JE_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId")
);

CREATE INDEX IF NOT EXISTS "IX_acct_JE_Date"
  ON acct."JournalEntry" ("CompanyId", "BranchId", "EntryDate", "JournalEntryId");

-- ---------------------------------------------------------
-- acct."JournalEntryLine"
-- ---------------------------------------------------------
CREATE TABLE IF NOT EXISTS acct."JournalEntryLine" (
  "JournalEntryLineId"    BIGINT GENERATED ALWAYS AS IDENTITY NOT NULL PRIMARY KEY,
  "JournalEntryId"        BIGINT NOT NULL,
  "LineNumber"            INT NOT NULL,
  "AccountId"             BIGINT NOT NULL,
  "AccountCodeSnapshot"   VARCHAR(40) NOT NULL,
  "Description"           VARCHAR(400) NULL,
  "DebitAmount"           NUMERIC(18,2) NOT NULL CONSTRAINT "DF_acct_JEL_Debit" DEFAULT 0,
  "CreditAmount"          NUMERIC(18,2) NOT NULL CONSTRAINT "DF_acct_JEL_Credit" DEFAULT 0,
  "AuxiliaryType"         VARCHAR(20) NULL,
  "AuxiliaryCode"         VARCHAR(80) NULL,
  "CostCenterCode"        VARCHAR(20) NULL,
  "SourceDocumentNo"      VARCHAR(120) NULL,
  "CreatedAt"             TIMESTAMP NOT NULL CONSTRAINT "DF_acct_JEL_CreatedAt" DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"             TIMESTAMP NOT NULL CONSTRAINT "DF_acct_JEL_UpdatedAt" DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "RowVer"                INT NOT NULL DEFAULT 1,
  CONSTRAINT "UQ_acct_JEL" UNIQUE ("JournalEntryId", "LineNumber"),
  CONSTRAINT "CK_acct_JEL_DebitCredit" CHECK (
    ("DebitAmount" >= 0 AND "CreditAmount" >= 0)
    AND NOT ("DebitAmount" > 0 AND "CreditAmount" > 0)
  ),
  CONSTRAINT "FK_acct_JEL_JE" FOREIGN KEY ("JournalEntryId") REFERENCES acct."JournalEntry"("JournalEntryId"),
  CONSTRAINT "FK_acct_JEL_Account" FOREIGN KEY ("AccountId") REFERENCES acct."Account"("AccountId")
);

CREATE INDEX IF NOT EXISTS "IX_acct_JEL_Account"
  ON acct."JournalEntryLine" ("AccountId", "JournalEntryId");

-- ---------------------------------------------------------
-- acct."DocumentLink"
-- ---------------------------------------------------------
CREATE TABLE IF NOT EXISTS acct."DocumentLink" (
  "DocumentLinkId"        BIGINT GENERATED ALWAYS AS IDENTITY NOT NULL PRIMARY KEY,
  "CompanyId"             INT NOT NULL,
  "BranchId"              INT NOT NULL,
  "ModuleCode"            VARCHAR(20) NOT NULL,
  "DocumentType"          VARCHAR(20) NOT NULL,
  "DocumentNumber"        VARCHAR(120) NOT NULL,
  "NativeDocumentId"      BIGINT NULL,
  "JournalEntryId"        BIGINT NOT NULL,
  "CreatedAt"             TIMESTAMP NOT NULL CONSTRAINT "DF_acct_DocLink_CreatedAt" DEFAULT (NOW() AT TIME ZONE 'UTC'),
  CONSTRAINT "UQ_acct_DocLink" UNIQUE ("CompanyId", "BranchId", "ModuleCode", "DocumentType", "DocumentNumber"),
  CONSTRAINT "FK_acct_DocLink_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId"),
  CONSTRAINT "FK_acct_DocLink_Branch" FOREIGN KEY ("BranchId") REFERENCES cfg."Branch"("BranchId"),
  CONSTRAINT "FK_acct_DocLink_JE" FOREIGN KEY ("JournalEntryId") REFERENCES acct."JournalEntry"("JournalEntryId")
);

-- ---------------------------------------------------------
-- acct."AccountingPolicy"
-- ---------------------------------------------------------
CREATE TABLE IF NOT EXISTS acct."AccountingPolicy" (
  "AccountingPolicyId"    BIGINT GENERATED ALWAYS AS IDENTITY NOT NULL PRIMARY KEY,
  "CompanyId"             INT NOT NULL,
  "ModuleCode"            VARCHAR(20) NOT NULL,
  "ProcessCode"           VARCHAR(40) NOT NULL,
  "Nature"                VARCHAR(10) NOT NULL,
  "AccountId"             BIGINT NOT NULL,
  "PriorityOrder"         INT NOT NULL CONSTRAINT "DF_acct_Policy_Priority" DEFAULT 1,
  "IsActive"              BOOLEAN NOT NULL CONSTRAINT "DF_acct_Policy_IsActive" DEFAULT TRUE,
  "CreatedAt"             TIMESTAMP NOT NULL CONSTRAINT "DF_acct_Policy_CreatedAt" DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"             TIMESTAMP NOT NULL CONSTRAINT "DF_acct_Policy_UpdatedAt" DEFAULT (NOW() AT TIME ZONE 'UTC'),
  CONSTRAINT "CK_acct_Policy_Nature" CHECK ("Nature" IN ('DEBIT','CREDIT')),
  CONSTRAINT "UQ_acct_Policy" UNIQUE ("CompanyId", "ModuleCode", "ProcessCode", "Nature", "AccountId"),
  CONSTRAINT "FK_acct_Policy_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId"),
  CONSTRAINT "FK_acct_Policy_Account" FOREIGN KEY ("AccountId") REFERENCES acct."Account"("AccountId")
);

COMMIT;

-- Source: 04_operations_core.sql
-- ============================================================
-- DatqBoxWeb PostgreSQL - 04_operations_core.sql
-- Tablas operativas: AR (cuentas por cobrar), AP (cuentas por
-- pagar), Fiscal, POS, Restaurante
-- ============================================================

BEGIN;

-- =========================================================
-- SCHEMA ar  (Accounts Receivable)
-- =========================================================

-- ---------------------------------------------------------
-- ar."ReceivableDocument"
-- ---------------------------------------------------------
CREATE TABLE IF NOT EXISTS ar."ReceivableDocument" (
  "ReceivableDocumentId"   BIGINT GENERATED ALWAYS AS IDENTITY NOT NULL PRIMARY KEY,
  "CompanyId"              INT NOT NULL,
  "BranchId"               INT NOT NULL,
  "CustomerId"             BIGINT NOT NULL,
  "DocumentType"           VARCHAR(20) NOT NULL,
  "DocumentNumber"         VARCHAR(120) NOT NULL,
  "IssueDate"              DATE NOT NULL,
  "DueDate"                DATE NULL,
  "CurrencyCode"           CHAR(3) NOT NULL,
  "TotalAmount"            NUMERIC(18,2) NOT NULL,
  "PendingAmount"          NUMERIC(18,2) NOT NULL,
  "PaidFlag"               BOOLEAN NOT NULL CONSTRAINT "DF_ar_RecDoc_PaidFlag" DEFAULT FALSE,
  "Status"                 VARCHAR(20) NOT NULL CONSTRAINT "DF_ar_RecDoc_Status" DEFAULT 'PENDING',
  "Notes"                  VARCHAR(500) NULL,
  "CreatedAt"              TIMESTAMP NOT NULL CONSTRAINT "DF_ar_RecDoc_CreatedAt" DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"              TIMESTAMP NOT NULL CONSTRAINT "DF_ar_RecDoc_UpdatedAt" DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId"        INT NULL,
  "UpdatedByUserId"        INT NULL,
  "RowVer"                 INT NOT NULL DEFAULT 1,
  CONSTRAINT "CK_ar_RecDoc_Status" CHECK ("Status" IN ('PENDING','PARTIAL','PAID','VOIDED')),
  CONSTRAINT "UQ_ar_RecDoc" UNIQUE ("CompanyId", "BranchId", "DocumentType", "DocumentNumber"),
  CONSTRAINT "FK_ar_RecDoc_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId"),
  CONSTRAINT "FK_ar_RecDoc_Branch" FOREIGN KEY ("BranchId") REFERENCES cfg."Branch"("BranchId"),
  CONSTRAINT "FK_ar_RecDoc_Customer" FOREIGN KEY ("CustomerId") REFERENCES master."Customer"("CustomerId"),
  CONSTRAINT "FK_ar_RecDoc_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_ar_RecDoc_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId")
);

-- ---------------------------------------------------------
-- ar."ReceivableApplication"
-- ---------------------------------------------------------
CREATE TABLE IF NOT EXISTS ar."ReceivableApplication" (
  "ReceivableApplicationId" BIGINT GENERATED ALWAYS AS IDENTITY NOT NULL PRIMARY KEY,
  "ReceivableDocumentId"    BIGINT NOT NULL,
  "ApplyDate"               DATE NOT NULL,
  "AppliedAmount"           NUMERIC(18,2) NOT NULL,
  "PaymentReference"        VARCHAR(120) NULL,
  "CreatedAt"               TIMESTAMP NOT NULL CONSTRAINT "DF_ar_RecApp_CreatedAt" DEFAULT (NOW() AT TIME ZONE 'UTC'),
  CONSTRAINT "FK_ar_RecApp_Doc" FOREIGN KEY ("ReceivableDocumentId") REFERENCES ar."ReceivableDocument"("ReceivableDocumentId")
);

-- =========================================================
-- SCHEMA ap  (Accounts Payable)
-- =========================================================

-- ---------------------------------------------------------
-- ap."PayableDocument"
-- ---------------------------------------------------------
CREATE TABLE IF NOT EXISTS ap."PayableDocument" (
  "PayableDocumentId"      BIGINT GENERATED ALWAYS AS IDENTITY NOT NULL PRIMARY KEY,
  "CompanyId"              INT NOT NULL,
  "BranchId"               INT NOT NULL,
  "SupplierId"             BIGINT NOT NULL,
  "DocumentType"           VARCHAR(20) NOT NULL,
  "DocumentNumber"         VARCHAR(120) NOT NULL,
  "IssueDate"              DATE NOT NULL,
  "DueDate"                DATE NULL,
  "CurrencyCode"           CHAR(3) NOT NULL,
  "TotalAmount"            NUMERIC(18,2) NOT NULL,
  "PendingAmount"          NUMERIC(18,2) NOT NULL,
  "PaidFlag"               BOOLEAN NOT NULL CONSTRAINT "DF_ap_PayDoc_PaidFlag" DEFAULT FALSE,
  "Status"                 VARCHAR(20) NOT NULL CONSTRAINT "DF_ap_PayDoc_Status" DEFAULT 'PENDING',
  "Notes"                  VARCHAR(500) NULL,
  "CreatedAt"              TIMESTAMP NOT NULL CONSTRAINT "DF_ap_PayDoc_CreatedAt" DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"              TIMESTAMP NOT NULL CONSTRAINT "DF_ap_PayDoc_UpdatedAt" DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId"        INT NULL,
  "UpdatedByUserId"        INT NULL,
  "RowVer"                 INT NOT NULL DEFAULT 1,
  CONSTRAINT "CK_ap_PayDoc_Status" CHECK ("Status" IN ('PENDING','PARTIAL','PAID','VOIDED')),
  CONSTRAINT "UQ_ap_PayDoc" UNIQUE ("CompanyId", "BranchId", "DocumentType", "DocumentNumber"),
  CONSTRAINT "FK_ap_PayDoc_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId"),
  CONSTRAINT "FK_ap_PayDoc_Branch" FOREIGN KEY ("BranchId") REFERENCES cfg."Branch"("BranchId"),
  CONSTRAINT "FK_ap_PayDoc_Supplier" FOREIGN KEY ("SupplierId") REFERENCES master."Supplier"("SupplierId"),
  CONSTRAINT "FK_ap_PayDoc_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_ap_PayDoc_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId")
);

-- ---------------------------------------------------------
-- ap."PayableApplication"
-- ---------------------------------------------------------
CREATE TABLE IF NOT EXISTS ap."PayableApplication" (
  "PayableApplicationId"   BIGINT GENERATED ALWAYS AS IDENTITY NOT NULL PRIMARY KEY,
  "PayableDocumentId"      BIGINT NOT NULL,
  "ApplyDate"              DATE NOT NULL,
  "AppliedAmount"          NUMERIC(18,2) NOT NULL,
  "PaymentReference"       VARCHAR(120) NULL,
  "CreatedAt"              TIMESTAMP NOT NULL CONSTRAINT "DF_ap_PayApp_CreatedAt" DEFAULT (NOW() AT TIME ZONE 'UTC'),
  CONSTRAINT "FK_ap_PayApp_Doc" FOREIGN KEY ("PayableDocumentId") REFERENCES ap."PayableDocument"("PayableDocumentId")
);

-- =========================================================
-- SCHEMA fiscal
-- =========================================================

-- ---------------------------------------------------------
-- fiscal."CountryConfig"
-- ---------------------------------------------------------
CREATE TABLE IF NOT EXISTS fiscal."CountryConfig" (
  "CountryConfigId"         BIGINT GENERATED ALWAYS AS IDENTITY NOT NULL PRIMARY KEY,
  "CompanyId"               INT NOT NULL,
  "BranchId"                INT NOT NULL,
  "CountryCode"             CHAR(2) NOT NULL,
  "Currency"                CHAR(3) NOT NULL,
  "TaxRegime"               VARCHAR(50) NULL,
  "DefaultTaxCode"          VARCHAR(30) NULL,
  "DefaultTaxRate"          NUMERIC(9,4) NOT NULL,
  "FiscalPrinterEnabled"    BOOLEAN NOT NULL CONSTRAINT "DF_fiscal_CountryCfg_Printer" DEFAULT FALSE,
  "PrinterBrand"            VARCHAR(30) NULL,
  "PrinterPort"             VARCHAR(20) NULL,
  "VerifactuEnabled"        BOOLEAN NOT NULL CONSTRAINT "DF_fiscal_CountryCfg_Verifactu" DEFAULT FALSE,
  "VerifactuMode"           VARCHAR(10) NULL,
  "CertificatePath"         VARCHAR(500) NULL,
  "CertificatePassword"     VARCHAR(255) NULL,
  "AEATEndpoint"            VARCHAR(500) NULL,
  "SenderNIF"               VARCHAR(20) NULL,
  "SenderRIF"               VARCHAR(20) NULL,
  "SoftwareId"              VARCHAR(100) NULL,
  "SoftwareName"            VARCHAR(200) NULL,
  "SoftwareVersion"         VARCHAR(20) NULL,
  "PosEnabled"              BOOLEAN NOT NULL CONSTRAINT "DF_fiscal_CountryCfg_PosEnabled" DEFAULT TRUE,
  "RestaurantEnabled"       BOOLEAN NOT NULL CONSTRAINT "DF_fiscal_CountryCfg_RestEnabled" DEFAULT TRUE,
  "IsActive"                BOOLEAN NOT NULL CONSTRAINT "DF_fiscal_CountryCfg_IsActive" DEFAULT TRUE,
  "CreatedAt"               TIMESTAMP NOT NULL CONSTRAINT "DF_fiscal_CountryCfg_CreatedAt" DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"               TIMESTAMP NOT NULL CONSTRAINT "DF_fiscal_CountryCfg_UpdatedAt" DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId"         INT NULL,
  "UpdatedByUserId"         INT NULL,
  "RowVer"                  INT NOT NULL DEFAULT 1,
  CONSTRAINT "CK_fiscal_CountryCfg_VerifactuMode" CHECK ("VerifactuMode" IN ('auto','manual') OR "VerifactuMode" IS NULL),
  CONSTRAINT "UQ_fiscal_CountryCfg" UNIQUE ("CompanyId", "BranchId", "CountryCode"),
  CONSTRAINT "FK_fiscal_CountryCfg_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId"),
  CONSTRAINT "FK_fiscal_CountryCfg_Branch" FOREIGN KEY ("BranchId") REFERENCES cfg."Branch"("BranchId"),
  CONSTRAINT "FK_fiscal_CountryCfg_Country" FOREIGN KEY ("CountryCode") REFERENCES cfg."Country"("CountryCode"),
  CONSTRAINT "FK_fiscal_CountryCfg_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_fiscal_CountryCfg_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId")
);

-- ---------------------------------------------------------
-- fiscal."TaxRate"
-- ---------------------------------------------------------
CREATE TABLE IF NOT EXISTS fiscal."TaxRate" (
  "TaxRateId"               BIGINT GENERATED ALWAYS AS IDENTITY NOT NULL PRIMARY KEY,
  "CountryCode"             CHAR(2) NOT NULL,
  "TaxCode"                 VARCHAR(30) NOT NULL,
  "TaxName"                 VARCHAR(120) NOT NULL,
  "Rate"                    NUMERIC(9,4) NOT NULL,
  "SurchargeRate"           NUMERIC(9,4) NULL,
  "AppliesToPOS"            BOOLEAN NOT NULL CONSTRAINT "DF_fiscal_TaxRate_AppliesToPOS" DEFAULT TRUE,
  "AppliesToRestaurant"     BOOLEAN NOT NULL CONSTRAINT "DF_fiscal_TaxRate_AppliesToRest" DEFAULT TRUE,
  "IsDefault"               BOOLEAN NOT NULL CONSTRAINT "DF_fiscal_TaxRate_IsDefault" DEFAULT FALSE,
  "IsActive"                BOOLEAN NOT NULL CONSTRAINT "DF_fiscal_TaxRate_IsActive" DEFAULT TRUE,
  "SortOrder"               INT NOT NULL CONSTRAINT "DF_fiscal_TaxRate_Sort" DEFAULT 0,
  "CreatedAt"               TIMESTAMP NOT NULL CONSTRAINT "DF_fiscal_TaxRate_CreatedAt" DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"               TIMESTAMP NOT NULL CONSTRAINT "DF_fiscal_TaxRate_UpdatedAt" DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId"         INT NULL,
  "UpdatedByUserId"         INT NULL,
  "RowVer"                  INT NOT NULL DEFAULT 1,
  CONSTRAINT "CK_fiscal_TaxRate_Rate" CHECK ("Rate" >= 0 AND "Rate" <= 1),
  CONSTRAINT "CK_fiscal_TaxRate_Surcharge" CHECK ("SurchargeRate" IS NULL OR ("SurchargeRate" >= 0 AND "SurchargeRate" <= 1)),
  CONSTRAINT "UQ_fiscal_TaxRate" UNIQUE ("CountryCode", "TaxCode"),
  CONSTRAINT "FK_fiscal_TaxRate_Country" FOREIGN KEY ("CountryCode") REFERENCES cfg."Country"("CountryCode"),
  CONSTRAINT "FK_fiscal_TaxRate_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_fiscal_TaxRate_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId")
);

-- ---------------------------------------------------------
-- fiscal."InvoiceType"
-- ---------------------------------------------------------
CREATE TABLE IF NOT EXISTS fiscal."InvoiceType" (
  "InvoiceTypeId"           BIGINT GENERATED ALWAYS AS IDENTITY NOT NULL PRIMARY KEY,
  "CountryCode"             CHAR(2) NOT NULL,
  "InvoiceTypeCode"         VARCHAR(20) NOT NULL,
  "InvoiceTypeName"         VARCHAR(120) NOT NULL,
  "IsRectificative"         BOOLEAN NOT NULL CONSTRAINT "DF_fiscal_InvType_Rect" DEFAULT FALSE,
  "RequiresRecipientId"     BOOLEAN NOT NULL CONSTRAINT "DF_fiscal_InvType_ReqRcpt" DEFAULT FALSE,
  "MaxAmount"               NUMERIC(18,2) NULL,
  "RequiresFiscalPrinter"   BOOLEAN NOT NULL CONSTRAINT "DF_fiscal_InvType_ReqPrinter" DEFAULT FALSE,
  "IsActive"                BOOLEAN NOT NULL CONSTRAINT "DF_fiscal_InvType_IsActive" DEFAULT TRUE,
  "SortOrder"               INT NOT NULL CONSTRAINT "DF_fiscal_InvType_Sort" DEFAULT 0,
  "CreatedAt"               TIMESTAMP NOT NULL CONSTRAINT "DF_fiscal_InvType_CreatedAt" DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"               TIMESTAMP NOT NULL CONSTRAINT "DF_fiscal_InvType_UpdatedAt" DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId"         INT NULL,
  "UpdatedByUserId"         INT NULL,
  "RowVer"                  INT NOT NULL DEFAULT 1,
  CONSTRAINT "UQ_fiscal_InvType" UNIQUE ("CountryCode", "InvoiceTypeCode"),
  CONSTRAINT "FK_fiscal_InvType_Country" FOREIGN KEY ("CountryCode") REFERENCES cfg."Country"("CountryCode"),
  CONSTRAINT "FK_fiscal_InvType_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_fiscal_InvType_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId")
);

-- ---------------------------------------------------------
-- fiscal."Record"
-- ---------------------------------------------------------
CREATE TABLE IF NOT EXISTS fiscal."Record" (
  "FiscalRecordId"          BIGINT GENERATED ALWAYS AS IDENTITY NOT NULL PRIMARY KEY,
  "CompanyId"               INT NOT NULL,
  "BranchId"                INT NOT NULL,
  "CountryCode"             CHAR(2) NOT NULL,
  "InvoiceId"               INT NOT NULL,
  "InvoiceType"             VARCHAR(20) NOT NULL,
  "InvoiceNumber"           VARCHAR(50) NOT NULL,
  "InvoiceDate"             DATE NOT NULL,
  "RecipientId"             VARCHAR(20) NULL,
  "TotalAmount"             NUMERIC(18,2) NOT NULL,
  "RecordHash"              VARCHAR(64) NOT NULL,
  "PreviousRecordHash"      VARCHAR(64) NULL,
  "XmlContent"              TEXT NULL,
  "DigitalSignature"        TEXT NULL,
  "QRCodeData"              VARCHAR(800) NULL,
  "SentToAuthority"         BOOLEAN NOT NULL CONSTRAINT "DF_fiscal_Record_Sent" DEFAULT FALSE,
  "SentAt"                  TIMESTAMP NULL,
  "AuthorityResponse"       TEXT NULL,
  "AuthorityStatus"         VARCHAR(20) NULL,
  "FiscalPrinterSerial"     VARCHAR(30) NULL,
  "FiscalControlNumber"     VARCHAR(30) NULL,
  "ZReportNumber"           INT NULL,
  "CreatedAt"               TIMESTAMP NOT NULL CONSTRAINT "DF_fiscal_Record_CreatedAt" DEFAULT (NOW() AT TIME ZONE 'UTC'),
  CONSTRAINT "UQ_fiscal_Record_Hash" UNIQUE ("RecordHash"),
  CONSTRAINT "FK_fiscal_Record_CountryCfg" FOREIGN KEY ("CompanyId", "BranchId", "CountryCode") REFERENCES fiscal."CountryConfig"("CompanyId", "BranchId", "CountryCode"),
  CONSTRAINT "FK_fiscal_Record_PrevHash" FOREIGN KEY ("PreviousRecordHash") REFERENCES fiscal."Record"("RecordHash")
);

CREATE INDEX IF NOT EXISTS "IX_fiscal_Record_Search"
  ON fiscal."Record" ("CompanyId", "BranchId", "CountryCode", "FiscalRecordId" DESC);

-- =========================================================
-- SCHEMA pos  (Point of Sale)
-- =========================================================

-- ---------------------------------------------------------
-- pos."WaitTicket"
-- ---------------------------------------------------------
CREATE TABLE IF NOT EXISTS pos."WaitTicket" (
  "WaitTicketId"            BIGINT GENERATED ALWAYS AS IDENTITY NOT NULL PRIMARY KEY,
  "CompanyId"               INT NOT NULL,
  "BranchId"                INT NOT NULL,
  "CountryCode"             CHAR(2) NOT NULL,
  "CashRegisterCode"        VARCHAR(10) NOT NULL,
  "StationName"             VARCHAR(50) NULL,
  "CreatedByUserId"         INT NULL,
  "CustomerId"              BIGINT NULL,
  "CustomerCode"            VARCHAR(24) NULL,
  "CustomerName"            VARCHAR(200) NULL,
  "CustomerFiscalId"        VARCHAR(30) NULL,
  "PriceTier"               VARCHAR(20) NOT NULL CONSTRAINT "DF_pos_WaitTicket_PriceTier" DEFAULT 'DETAIL',
  "Reason"                  VARCHAR(200) NULL,
  "NetAmount"               NUMERIC(18,2) NOT NULL CONSTRAINT "DF_pos_WaitTicket_Net" DEFAULT 0,
  "DiscountAmount"          NUMERIC(18,2) NOT NULL CONSTRAINT "DF_pos_WaitTicket_Discount" DEFAULT 0,
  "TaxAmount"               NUMERIC(18,2) NOT NULL CONSTRAINT "DF_pos_WaitTicket_Tax" DEFAULT 0,
  "TotalAmount"             NUMERIC(18,2) NOT NULL CONSTRAINT "DF_pos_WaitTicket_Total" DEFAULT 0,
  "Status"                  VARCHAR(20) NOT NULL CONSTRAINT "DF_pos_WaitTicket_Status" DEFAULT 'WAITING',
  "RecoveredByUserId"       INT NULL,
  "RecoveredAtRegister"     VARCHAR(10) NULL,
  "RecoveredAt"             TIMESTAMP NULL,
  "CreatedAt"               TIMESTAMP NOT NULL CONSTRAINT "DF_pos_WaitTicket_CreatedAt" DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"               TIMESTAMP NOT NULL CONSTRAINT "DF_pos_WaitTicket_UpdatedAt" DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "RowVer"                  INT NOT NULL DEFAULT 1,
  CONSTRAINT "CK_pos_WaitTicket_Status" CHECK ("Status" IN ('WAITING','RECOVERED','VOIDED')),
  CONSTRAINT "FK_pos_WaitTicket_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId"),
  CONSTRAINT "FK_pos_WaitTicket_Branch" FOREIGN KEY ("BranchId") REFERENCES cfg."Branch"("BranchId"),
  CONSTRAINT "FK_pos_WaitTicket_Country" FOREIGN KEY ("CountryCode") REFERENCES cfg."Country"("CountryCode"),
  CONSTRAINT "FK_pos_WaitTicket_Customer" FOREIGN KEY ("CustomerId") REFERENCES master."Customer"("CustomerId"),
  CONSTRAINT "FK_pos_WaitTicket_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_pos_WaitTicket_RecoveredBy" FOREIGN KEY ("RecoveredByUserId") REFERENCES sec."User"("UserId")
);

-- ---------------------------------------------------------
-- pos."WaitTicketLine"
-- ---------------------------------------------------------
CREATE TABLE IF NOT EXISTS pos."WaitTicketLine" (
  "WaitTicketLineId"        BIGINT GENERATED ALWAYS AS IDENTITY NOT NULL PRIMARY KEY,
  "WaitTicketId"            BIGINT NOT NULL,
  "LineNumber"              INT NOT NULL,
  "CountryCode"             CHAR(2) NOT NULL,
  "ProductId"               BIGINT NULL,
  "ProductCode"             VARCHAR(80) NOT NULL,
  "ProductName"             VARCHAR(250) NOT NULL,
  "Quantity"                NUMERIC(10,3) NOT NULL,
  "UnitPrice"               NUMERIC(18,2) NOT NULL,
  "DiscountAmount"          NUMERIC(18,2) NOT NULL CONSTRAINT "DF_pos_WaitTicketLine_Discount" DEFAULT 0,
  "TaxCode"                 VARCHAR(30) NOT NULL,
  "TaxRate"                 NUMERIC(9,4) NOT NULL,
  "NetAmount"               NUMERIC(18,2) NOT NULL,
  "TaxAmount"               NUMERIC(18,2) NOT NULL,
  "TotalAmount"             NUMERIC(18,2) NOT NULL,
  "CreatedAt"               TIMESTAMP NOT NULL CONSTRAINT "DF_pos_WaitTicketLine_CreatedAt" DEFAULT (NOW() AT TIME ZONE 'UTC'),
  CONSTRAINT "UQ_pos_WaitTicketLine" UNIQUE ("WaitTicketId", "LineNumber"),
  CONSTRAINT "FK_pos_WaitTicketLine_WaitTicket" FOREIGN KEY ("WaitTicketId") REFERENCES pos."WaitTicket"("WaitTicketId") ON DELETE CASCADE,
  CONSTRAINT "FK_pos_WaitTicketLine_Product" FOREIGN KEY ("ProductId") REFERENCES master."Product"("ProductId"),
  CONSTRAINT "FK_pos_WaitTicketLine_Tax" FOREIGN KEY ("CountryCode", "TaxCode") REFERENCES fiscal."TaxRate"("CountryCode", "TaxCode")
);

-- ---------------------------------------------------------
-- pos."SaleTicket"
-- ---------------------------------------------------------
CREATE TABLE IF NOT EXISTS pos."SaleTicket" (
  "SaleTicketId"            BIGINT GENERATED ALWAYS AS IDENTITY NOT NULL PRIMARY KEY,
  "CompanyId"               INT NOT NULL,
  "BranchId"                INT NOT NULL,
  "CountryCode"             CHAR(2) NOT NULL,
  "InvoiceNumber"           VARCHAR(20) NOT NULL,
  "CashRegisterCode"        VARCHAR(10) NOT NULL,
  "SoldByUserId"            INT NULL,
  "CustomerId"              BIGINT NULL,
  "CustomerCode"            VARCHAR(24) NULL,
  "CustomerName"            VARCHAR(200) NULL,
  "CustomerFiscalId"        VARCHAR(30) NULL,
  "PriceTier"               VARCHAR(20) NOT NULL CONSTRAINT "DF_pos_SaleTicket_PriceTier" DEFAULT 'DETAIL',
  "PaymentMethod"           VARCHAR(50) NULL,
  "FiscalPayload"           TEXT NULL,
  "WaitTicketId"            BIGINT NULL,
  "NetAmount"               NUMERIC(18,2) NOT NULL CONSTRAINT "DF_pos_SaleTicket_Net" DEFAULT 0,
  "DiscountAmount"          NUMERIC(18,2) NOT NULL CONSTRAINT "DF_pos_SaleTicket_Discount" DEFAULT 0,
  "TaxAmount"               NUMERIC(18,2) NOT NULL CONSTRAINT "DF_pos_SaleTicket_Tax" DEFAULT 0,
  "TotalAmount"             NUMERIC(18,2) NOT NULL CONSTRAINT "DF_pos_SaleTicket_Total" DEFAULT 0,
  "SoldAt"                  TIMESTAMP NOT NULL CONSTRAINT "DF_pos_SaleTicket_SoldAt" DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "RowVer"                  INT NOT NULL DEFAULT 1,
  CONSTRAINT "UQ_pos_SaleTicket" UNIQUE ("CompanyId", "BranchId", "InvoiceNumber"),
  CONSTRAINT "FK_pos_SaleTicket_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId"),
  CONSTRAINT "FK_pos_SaleTicket_Branch" FOREIGN KEY ("BranchId") REFERENCES cfg."Branch"("BranchId"),
  CONSTRAINT "FK_pos_SaleTicket_Country" FOREIGN KEY ("CountryCode") REFERENCES cfg."Country"("CountryCode"),
  CONSTRAINT "FK_pos_SaleTicket_Customer" FOREIGN KEY ("CustomerId") REFERENCES master."Customer"("CustomerId"),
  CONSTRAINT "FK_pos_SaleTicket_WaitTicket" FOREIGN KEY ("WaitTicketId") REFERENCES pos."WaitTicket"("WaitTicketId"),
  CONSTRAINT "FK_pos_SaleTicket_SoldBy" FOREIGN KEY ("SoldByUserId") REFERENCES sec."User"("UserId")
);

-- ---------------------------------------------------------
-- pos."SaleTicketLine"
-- ---------------------------------------------------------
CREATE TABLE IF NOT EXISTS pos."SaleTicketLine" (
  "SaleTicketLineId"        BIGINT GENERATED ALWAYS AS IDENTITY NOT NULL PRIMARY KEY,
  "SaleTicketId"            BIGINT NOT NULL,
  "LineNumber"              INT NOT NULL,
  "CountryCode"             CHAR(2) NOT NULL,
  "ProductId"               BIGINT NULL,
  "ProductCode"             VARCHAR(80) NOT NULL,
  "ProductName"             VARCHAR(250) NOT NULL,
  "Quantity"                NUMERIC(10,3) NOT NULL,
  "UnitPrice"               NUMERIC(18,2) NOT NULL,
  "DiscountAmount"          NUMERIC(18,2) NOT NULL CONSTRAINT "DF_pos_SaleTicketLine_Discount" DEFAULT 0,
  "TaxCode"                 VARCHAR(30) NOT NULL,
  "TaxRate"                 NUMERIC(9,4) NOT NULL,
  "NetAmount"               NUMERIC(18,2) NOT NULL,
  "TaxAmount"               NUMERIC(18,2) NOT NULL,
  "TotalAmount"             NUMERIC(18,2) NOT NULL,
  CONSTRAINT "UQ_pos_SaleTicketLine" UNIQUE ("SaleTicketId", "LineNumber"),
  CONSTRAINT "FK_pos_SaleTicketLine_SaleTicket" FOREIGN KEY ("SaleTicketId") REFERENCES pos."SaleTicket"("SaleTicketId") ON DELETE CASCADE,
  CONSTRAINT "FK_pos_SaleTicketLine_Product" FOREIGN KEY ("ProductId") REFERENCES master."Product"("ProductId"),
  CONSTRAINT "FK_pos_SaleTicketLine_Tax" FOREIGN KEY ("CountryCode", "TaxCode") REFERENCES fiscal."TaxRate"("CountryCode", "TaxCode")
);

-- =========================================================
-- SCHEMA rest  (Restaurant)
-- =========================================================

-- ---------------------------------------------------------
-- rest."OrderTicket"
-- ---------------------------------------------------------
CREATE TABLE IF NOT EXISTS rest."OrderTicket" (
  "OrderTicketId"           BIGINT GENERATED ALWAYS AS IDENTITY NOT NULL PRIMARY KEY,
  "CompanyId"               INT NOT NULL,
  "BranchId"                INT NOT NULL,
  "CountryCode"             CHAR(2) NOT NULL,
  "TableNumber"             VARCHAR(20) NULL,
  "OpenedByUserId"          INT NULL,
  "ClosedByUserId"          INT NULL,
  "CustomerName"            VARCHAR(200) NULL,
  "CustomerFiscalId"        VARCHAR(30) NULL,
  "Status"                  VARCHAR(20) NOT NULL CONSTRAINT "DF_rest_OrderTicket_Status" DEFAULT 'OPEN',
  "NetAmount"               NUMERIC(18,2) NOT NULL CONSTRAINT "DF_rest_OrderTicket_Net" DEFAULT 0,
  "TaxAmount"               NUMERIC(18,2) NOT NULL CONSTRAINT "DF_rest_OrderTicket_Tax" DEFAULT 0,
  "TotalAmount"             NUMERIC(18,2) NOT NULL CONSTRAINT "DF_rest_OrderTicket_Total" DEFAULT 0,
  "OpenedAt"                TIMESTAMP NOT NULL CONSTRAINT "DF_rest_OrderTicket_OpenedAt" DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "ClosedAt"                TIMESTAMP NULL,
  "UpdatedAt"               TIMESTAMP NOT NULL CONSTRAINT "DF_rest_OrderTicket_UpdatedAt" DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "RowVer"                  INT NOT NULL DEFAULT 1,
  CONSTRAINT "CK_rest_OrderTicket_Status" CHECK ("Status" IN ('OPEN','SENT','CLOSED','VOIDED')),
  CONSTRAINT "FK_rest_OrderTicket_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId"),
  CONSTRAINT "FK_rest_OrderTicket_Branch" FOREIGN KEY ("BranchId") REFERENCES cfg."Branch"("BranchId"),
  CONSTRAINT "FK_rest_OrderTicket_Country" FOREIGN KEY ("CountryCode") REFERENCES cfg."Country"("CountryCode"),
  CONSTRAINT "FK_rest_OrderTicket_OpenedBy" FOREIGN KEY ("OpenedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_rest_OrderTicket_ClosedBy" FOREIGN KEY ("ClosedByUserId") REFERENCES sec."User"("UserId")
);

-- ---------------------------------------------------------
-- rest."OrderTicketLine"
-- ---------------------------------------------------------
CREATE TABLE IF NOT EXISTS rest."OrderTicketLine" (
  "OrderTicketLineId"       BIGINT GENERATED ALWAYS AS IDENTITY NOT NULL PRIMARY KEY,
  "OrderTicketId"           BIGINT NOT NULL,
  "LineNumber"              INT NOT NULL,
  "CountryCode"             CHAR(2) NOT NULL,
  "ProductId"               BIGINT NULL,
  "ProductCode"             VARCHAR(80) NOT NULL,
  "ProductName"             VARCHAR(250) NOT NULL,
  "Quantity"                NUMERIC(10,3) NOT NULL,
  "UnitPrice"               NUMERIC(18,2) NOT NULL,
  "TaxCode"                 VARCHAR(30) NOT NULL,
  "TaxRate"                 NUMERIC(9,4) NOT NULL,
  "NetAmount"               NUMERIC(18,2) NOT NULL,
  "TaxAmount"               NUMERIC(18,2) NOT NULL,
  "TotalAmount"             NUMERIC(18,2) NOT NULL,
  "Notes"                   VARCHAR(300) NULL,
  "CreatedAt"               TIMESTAMP NOT NULL CONSTRAINT "DF_rest_OrderTicketLine_CreatedAt" DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"               TIMESTAMP NOT NULL CONSTRAINT "DF_rest_OrderTicketLine_UpdatedAt" DEFAULT (NOW() AT TIME ZONE 'UTC'),
  CONSTRAINT "UQ_rest_OrderTicketLine" UNIQUE ("OrderTicketId", "LineNumber"),
  CONSTRAINT "FK_rest_OrderTicketLine_Order" FOREIGN KEY ("OrderTicketId") REFERENCES rest."OrderTicket"("OrderTicketId") ON DELETE CASCADE,
  CONSTRAINT "FK_rest_OrderTicketLine_Product" FOREIGN KEY ("ProductId") REFERENCES master."Product"("ProductId"),
  CONSTRAINT "FK_rest_OrderTicketLine_Tax" FOREIGN KEY ("CountryCode", "TaxCode") REFERENCES fiscal."TaxRate"("CountryCode", "TaxCode")
);

COMMIT;

-- Source: 005_auth_security_hardening.sql
-- ============================================================================
-- 005_auth_security_hardening.sql — PostgreSQL
-- Tablas: sec.AuthIdentity, sec.AuthToken
-- Equivalente a sqlweb/includes/005_auth_security_hardening.sql (SQL Server)
-- ============================================================================

-- sec.AuthIdentity
CREATE TABLE IF NOT EXISTS sec."AuthIdentity" (
  "UserCode"              VARCHAR(10)   NOT NULL,
  "Email"                 VARCHAR(254)  NULL,
  "EmailNormalized"       VARCHAR(254)  NULL,
  "EmailVerifiedAtUtc"    TIMESTAMP     NULL,
  "IsRegistrationPending" BOOLEAN       NOT NULL DEFAULT FALSE,
  "FailedLoginCount"      INT           NOT NULL DEFAULT 0,
  "LastFailedLoginAtUtc"  TIMESTAMP     NULL,
  "LastFailedLoginIp"     VARCHAR(64)   NULL,
  "LockoutUntilUtc"       TIMESTAMP     NULL,
  "LastLoginAtUtc"        TIMESTAMP     NULL,
  "PasswordChangedAtUtc"  TIMESTAMP     NULL,
  "CreatedAtUtc"          TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAtUtc"          TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  CONSTRAINT "PK_sec_AuthIdentity" PRIMARY KEY ("UserCode"),
  CONSTRAINT "FK_sec_AuthIdentity_User"
    FOREIGN KEY ("UserCode") REFERENCES sec."User"("UserCode")
);

CREATE UNIQUE INDEX IF NOT EXISTS "UX_sec_AuthIdentity_EmailNormalized"
  ON sec."AuthIdentity" ("EmailNormalized")
  WHERE "EmailNormalized" IS NOT NULL;

-- sec.AuthToken
CREATE TABLE IF NOT EXISTS sec."AuthToken" (
  "TokenId"           BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "UserCode"          VARCHAR(10)   NOT NULL,
  "TokenType"         VARCHAR(32)   NOT NULL,
  "TokenHash"         CHAR(64)      NOT NULL,
  "EmailNormalized"   VARCHAR(254)  NULL,
  "ExpiresAtUtc"      TIMESTAMP     NOT NULL,
  "ConsumedAtUtc"     TIMESTAMP     NULL,
  "MetaIp"            VARCHAR(64)   NULL,
  "MetaUserAgent"     VARCHAR(256)  NULL,
  "CreatedAtUtc"      TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  CONSTRAINT "FK_sec_AuthToken_User"
    FOREIGN KEY ("UserCode") REFERENCES sec."User"("UserCode"),
  CONSTRAINT "CK_sec_AuthToken_Type"
    CHECK ("TokenType" IN ('VERIFY_EMAIL', 'RESET_PASSWORD'))
);

CREATE UNIQUE INDEX IF NOT EXISTS "UX_sec_AuthToken_TokenHash"
  ON sec."AuthToken" ("TokenHash");

CREATE INDEX IF NOT EXISTS "IX_sec_AuthToken_UserCode_Type_Expires"
  ON sec."AuthToken" ("UserCode", "TokenType", "ExpiresAtUtc", "ConsumedAtUtc");

-- Seed: migrar usuarios existentes a AuthIdentity
INSERT INTO sec."AuthIdentity" (
  "UserCode", "EmailVerifiedAtUtc", "IsRegistrationPending",
  "FailedLoginCount", "CreatedAtUtc", "UpdatedAtUtc"
)
SELECT
  u."UserCode",
  NOW() AT TIME ZONE 'UTC',
  FALSE,
  0,
  NOW() AT TIME ZONE 'UTC',
  NOW() AT TIME ZONE 'UTC'
FROM sec."User" u
LEFT JOIN sec."AuthIdentity" ai ON ai."UserCode" = u."UserCode"
WHERE ai."UserCode" IS NULL AND u."IsDeleted" = FALSE
ON CONFLICT DO NOTHING;

-- Source: 05_api_compat_bridge.sql
-- ============================================================
-- DatqBoxWeb PostgreSQL - 05_api_compat_bridge.sql
-- Tablas legacy de compatibilidad (dbo.* -> public.*),
-- vistas de compatibilidad, y stored procedures contables
-- ============================================================

BEGIN;

-- ============================================================
-- Obtener IDs por defecto
-- ============================================================
-- +goose StatementBegin
DO $$
DECLARE
  v_DefaultCompanyId INT;
  v_DefaultBranchId  INT;
  v_SystemUserId     INT;
BEGIN
  SELECT "CompanyId" INTO v_DefaultCompanyId
    FROM cfg."Company" WHERE "CompanyCode" = 'DEFAULT' LIMIT 1;
  SELECT "BranchId" INTO v_DefaultBranchId
    FROM cfg."Branch" WHERE "CompanyId" = v_DefaultCompanyId AND "BranchCode" = 'MAIN' LIMIT 1;

  IF v_DefaultCompanyId IS NULL OR v_DefaultBranchId IS NULL THEN
    RAISE EXCEPTION 'Missing DEFAULT company/MAIN branch. Run 01_core_foundation.sql first.';
  END IF;
END $$;
-- +goose StatementEnd

-- ============================================================
-- NOTA: Tablas legacy public.* eliminadas (2026-03-16).
-- Usar esquemas canonicos: acct.*, fiscal.*, cfg.*, etc.
-- Tablas eliminadas: Cuentas, Asientos, Asientos_Detalle,
--   TasasDiarias, FiscalCountryConfig, FiscalTaxRates,
--   FiscalInvoiceTypes, FiscalRecords, vista DtllAsiento.
-- ============================================================

-- ============================================================
-- FUNCIONES de compatibilidad contable (equivalentes a SPs)
-- ============================================================

-- sp_CxC_Documentos_List
DROP FUNCTION IF EXISTS public."sp_CxC_Documentos_List"(VARCHAR, VARCHAR, VARCHAR, DATE, DATE, INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION public."sp_CxC_Documentos_List"(
  p_CodCliente  VARCHAR DEFAULT NULL,
  p_TipoDoc     VARCHAR DEFAULT NULL,
  p_Estado      VARCHAR DEFAULT NULL,
  p_FechaDesde  DATE    DEFAULT NULL,
  p_FechaHasta  DATE    DEFAULT NULL,
  p_Page        INT     DEFAULT 1,
  p_Limit       INT     DEFAULT 50
)
RETURNS TABLE (
  "codCliente"   VARCHAR,
  "tipoDoc"      VARCHAR,
  "numDoc"       VARCHAR,
  "fecha"        DATE,
  "total"        NUMERIC,
  "pendiente"    NUMERIC,
  "estado"       VARCHAR,
  "observacion"  VARCHAR,
  "codUsuario"   VARCHAR
)
-- +goose StatementBegin
LANGUAGE plpgsql AS $$
DECLARE
  v_Page  INT := GREATEST(COALESCE(p_Page, 1), 1);
  v_Limit INT := LEAST(GREATEST(COALESCE(p_Limit, 50), 1), 500);
  v_Offset INT := (v_Page - 1) * v_Limit;
BEGIN
  RETURN QUERY
  SELECT
    c."CustomerCode"::VARCHAR      AS "codCliente",
    d."DocumentType"::VARCHAR      AS "tipoDoc",
    d."DocumentNumber"::VARCHAR    AS "numDoc",
    d."IssueDate"                  AS "fecha",
    d."TotalAmount"                AS "total",
    d."PendingAmount"              AS "pendiente",
    d."Status"::VARCHAR            AS "estado",
    d."Notes"::VARCHAR             AS "observacion",
    u."UserCode"::VARCHAR          AS "codUsuario"
  FROM ar."ReceivableDocument" d
  INNER JOIN master."Customer" c ON c."CustomerId" = d."CustomerId"
  LEFT JOIN sec."User" u ON u."UserId" = d."CreatedByUserId"
  WHERE (p_CodCliente IS NULL OR c."CustomerCode" = p_CodCliente)
    AND (p_TipoDoc IS NULL OR d."DocumentType" = p_TipoDoc)
    AND (p_FechaDesde IS NULL OR d."IssueDate" >= p_FechaDesde)
    AND (p_FechaHasta IS NULL OR d."IssueDate" <= p_FechaHasta)
    AND (p_Estado IS NULL OR p_Estado = '' OR d."Status" = p_Estado)
  ORDER BY d."IssueDate" DESC, d."DocumentNumber" DESC, d."ReceivableDocumentId" DESC
  LIMIT v_Limit OFFSET v_Offset;
END;
$$;
-- +goose StatementEnd

-- sp_CxP_Documentos_List
DROP FUNCTION IF EXISTS public."sp_CxP_Documentos_List"(VARCHAR, VARCHAR, VARCHAR, DATE, DATE, INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION public."sp_CxP_Documentos_List"(
  p_CodProveedor VARCHAR DEFAULT NULL,
  p_TipoDoc      VARCHAR DEFAULT NULL,
  p_Estado       VARCHAR DEFAULT NULL,
  p_FechaDesde   DATE    DEFAULT NULL,
  p_FechaHasta   DATE    DEFAULT NULL,
  p_Page         INT     DEFAULT 1,
  p_Limit        INT     DEFAULT 50
)
RETURNS TABLE (
  "codProveedor" VARCHAR,
  "tipoDoc"      VARCHAR,
  "numDoc"       VARCHAR,
  "fecha"        DATE,
  "total"        NUMERIC,
  "pendiente"    NUMERIC,
  "estado"       VARCHAR,
  "observacion"  VARCHAR,
  "codUsuario"   VARCHAR
)
-- +goose StatementBegin
LANGUAGE plpgsql AS $$
DECLARE
  v_Page  INT := GREATEST(COALESCE(p_Page, 1), 1);
  v_Limit INT := LEAST(GREATEST(COALESCE(p_Limit, 50), 1), 500);
  v_Offset INT := (v_Page - 1) * v_Limit;
BEGIN
  RETURN QUERY
  SELECT
    s."SupplierCode"::VARCHAR      AS "codProveedor",
    d."DocumentType"::VARCHAR      AS "tipoDoc",
    d."DocumentNumber"::VARCHAR    AS "numDoc",
    d."IssueDate"                  AS "fecha",
    d."TotalAmount"                AS "total",
    d."PendingAmount"              AS "pendiente",
    d."Status"::VARCHAR            AS "estado",
    d."Notes"::VARCHAR             AS "observacion",
    u."UserCode"::VARCHAR          AS "codUsuario"
  FROM ap."PayableDocument" d
  INNER JOIN master."Supplier" s ON s."SupplierId" = d."SupplierId"
  LEFT JOIN sec."User" u ON u."UserId" = d."CreatedByUserId"
  WHERE (p_CodProveedor IS NULL OR s."SupplierCode" = p_CodProveedor)
    AND (p_TipoDoc IS NULL OR d."DocumentType" = p_TipoDoc)
    AND (p_FechaDesde IS NULL OR d."IssueDate" >= p_FechaDesde)
    AND (p_FechaHasta IS NULL OR d."IssueDate" <= p_FechaHasta)
    AND (p_Estado IS NULL OR p_Estado = '' OR d."Status" = p_Estado)
  ORDER BY d."IssueDate" DESC, d."DocumentNumber" DESC, d."PayableDocumentId" DESC
  LIMIT v_Limit OFFSET v_Offset;
END;
$$;
-- +goose StatementEnd

-- ============================================================
-- Funciones contables: usp_Contabilidad_Asientos_List
-- ============================================================
DROP FUNCTION IF EXISTS public."usp_Contabilidad_Asientos_List"(DATE, DATE, VARCHAR, VARCHAR, VARCHAR, VARCHAR, INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION public."usp_Contabilidad_Asientos_List"(
  p_FechaDesde      DATE    DEFAULT NULL,
  p_FechaHasta      DATE    DEFAULT NULL,
  p_TipoAsiento     VARCHAR DEFAULT NULL,
  p_Estado          VARCHAR DEFAULT NULL,
  p_OrigenModulo    VARCHAR DEFAULT NULL,
  p_OrigenDocumento VARCHAR DEFAULT NULL,
  p_Page            INT     DEFAULT 1,
  p_Limit           INT     DEFAULT 50
)
RETURNS TABLE(
  "AsientoId"      BIGINT,
  "NumeroAsiento"  VARCHAR,
  "Fecha"          DATE,
  "TipoAsiento"    VARCHAR,
  "Referencia"     VARCHAR,
  "Concepto"       VARCHAR,
  "Moneda"         VARCHAR,
  "Tasa"           NUMERIC,
  "TotalDebe"      NUMERIC,
  "TotalHaber"     NUMERIC,
  "Estado"         VARCHAR,
  "OrigenModulo"   VARCHAR,
  "CodUsuario"     VARCHAR,
  "TotalCount"     INT
)
-- +goose StatementBegin
LANGUAGE plpgsql AS $$
DECLARE
  v_Page  INT := GREATEST(COALESCE(p_Page, 1), 1);
  v_Limit INT := LEAST(GREATEST(COALESCE(p_Limit, 50), 1), 500);
  v_Offset INT := (v_Page - 1) * v_Limit;
  v_TotalCount INT;
BEGIN
  SELECT COUNT(1) INTO v_TotalCount
  FROM public."Asientos" a
  WHERE (p_FechaDesde IS NULL OR a."Fecha" >= p_FechaDesde)
    AND (p_FechaHasta IS NULL OR a."Fecha" <= p_FechaHasta)
    AND (p_TipoAsiento IS NULL OR a."Tipo_Asiento" = p_TipoAsiento)
    AND (p_Estado IS NULL OR a."Estado" = p_Estado)
    AND (p_OrigenModulo IS NULL OR a."Origen_Modulo" = p_OrigenModulo)
    AND (p_OrigenDocumento IS NULL OR a."Referencia" = p_OrigenDocumento);

  RETURN QUERY
  SELECT
    a."Id"::BIGINT                                                                  AS "AsientoId",
    ('LEG-' || LPAD(a."Id"::TEXT, 10, '0'))::VARCHAR                                AS "NumeroAsiento",
    a."Fecha",
    a."Tipo_Asiento"::VARCHAR                                                       AS "TipoAsiento",
    a."Referencia"::VARCHAR,
    a."Concepto"::VARCHAR,
    'VES'::VARCHAR                                                                  AS "Moneda",
    1::NUMERIC(18,6)                                                                AS "Tasa",
    a."Total_Debe"                                                                  AS "TotalDebe",
    a."Total_Haber"                                                                 AS "TotalHaber",
    a."Estado"::VARCHAR,
    a."Origen_Modulo"::VARCHAR                                                      AS "OrigenModulo",
    a."Cod_Usuario"::VARCHAR                                                        AS "CodUsuario",
    v_TotalCount
  FROM public."Asientos" a
  WHERE (p_FechaDesde IS NULL OR a."Fecha" >= p_FechaDesde)
    AND (p_FechaHasta IS NULL OR a."Fecha" <= p_FechaHasta)
    AND (p_TipoAsiento IS NULL OR a."Tipo_Asiento" = p_TipoAsiento)
    AND (p_Estado IS NULL OR a."Estado" = p_Estado)
    AND (p_OrigenModulo IS NULL OR a."Origen_Modulo" = p_OrigenModulo)
    AND (p_OrigenDocumento IS NULL OR a."Referencia" = p_OrigenDocumento)
  ORDER BY a."Fecha" DESC, a."Id" DESC
  LIMIT v_Limit OFFSET v_Offset;
END;
$$;
-- +goose StatementEnd

-- ============================================================
-- usp_Contabilidad_Asiento_Get
-- ============================================================
DROP FUNCTION IF EXISTS public."usp_Contabilidad_Asiento_Get"(BIGINT) CASCADE;
CREATE OR REPLACE FUNCTION public."usp_Contabilidad_Asiento_Get"(
  p_AsientoId BIGINT
)
RETURNS TABLE (
  "AsientoId"      BIGINT,
  "NumeroAsiento"  VARCHAR,
  "Fecha"          DATE,
  "TipoAsiento"    VARCHAR,
  "Referencia"     VARCHAR,
  "Concepto"       VARCHAR,
  "Moneda"         VARCHAR,
  "Tasa"           NUMERIC,
  "TotalDebe"      NUMERIC,
  "TotalHaber"     NUMERIC,
  "Estado"         VARCHAR,
  "OrigenModulo"   VARCHAR,
  "CodUsuario"     VARCHAR
)
-- +goose StatementBegin
LANGUAGE plpgsql AS $$
BEGIN
  RETURN QUERY
  SELECT
    a."Id"::BIGINT,
    ('LEG-' || LPAD(a."Id"::TEXT, 10, '0'))::VARCHAR,
    a."Fecha",
    a."Tipo_Asiento"::VARCHAR,
    a."Referencia"::VARCHAR,
    a."Concepto"::VARCHAR,
    'VES'::VARCHAR,
    1::NUMERIC(18,6),
    a."Total_Debe",
    a."Total_Haber",
    a."Estado"::VARCHAR,
    a."Origen_Modulo"::VARCHAR,
    a."Cod_Usuario"::VARCHAR
  FROM public."Asientos" a
  WHERE a."Id" = p_AsientoId
  LIMIT 1;
END;
$$;
-- +goose StatementEnd

-- ============================================================
-- usp_Contabilidad_Asiento_Crear
-- Usa JSON en lugar de XML para el detalle
-- ============================================================
DROP FUNCTION IF EXISTS public."usp_Contabilidad_Asiento_Crear"(DATE, VARCHAR, VARCHAR, VARCHAR, VARCHAR, NUMERIC, VARCHAR, VARCHAR, VARCHAR, JSONB, BIGINT, VARCHAR, INT, VARCHAR) CASCADE;
CREATE OR REPLACE FUNCTION public."usp_Contabilidad_Asiento_Crear"(
  p_Fecha          DATE,
  p_TipoAsiento    VARCHAR,
  p_Referencia     VARCHAR DEFAULT NULL,
  p_Concepto       VARCHAR DEFAULT '',
  p_Moneda         VARCHAR DEFAULT 'VES',
  p_Tasa           NUMERIC DEFAULT 1,
  p_OrigenModulo   VARCHAR DEFAULT NULL,
  p_OrigenDocumento VARCHAR DEFAULT NULL,
  p_CodUsuario     VARCHAR DEFAULT NULL,
  p_DetalleJson    JSONB   DEFAULT '[]'::JSONB,
  OUT p_AsientoId      BIGINT,
  OUT p_NumeroAsiento  VARCHAR,
  OUT p_Resultado      INT,
  OUT p_Mensaje        VARCHAR
)
-- +goose StatementBegin
LANGUAGE plpgsql AS $$
DECLARE
  v_TotalDebe  NUMERIC(18,2);
  v_TotalHaber NUMERIC(18,2);
BEGIN
  -- Validar detalle
  IF jsonb_array_length(p_DetalleJson) = 0 THEN
    p_Resultado := 0;
    p_Mensaje := 'Detalle contable vacio.';
    RETURN;
  END IF;

  SELECT
    COALESCE(SUM((r->>'debe')::NUMERIC), 0),
    COALESCE(SUM((r->>'haber')::NUMERIC), 0)
  INTO v_TotalDebe, v_TotalHaber
  FROM jsonb_array_elements(p_DetalleJson) r;

  IF v_TotalDebe <> v_TotalHaber THEN
    p_Resultado := 0;
    p_Mensaje := 'Asiento no balanceado.';
    RETURN;
  END IF;

  INSERT INTO public."Asientos" (
    "Fecha", "Tipo_Asiento", "Concepto", "Referencia", "Estado",
    "Total_Debe", "Total_Haber", "Origen_Modulo", "Cod_Usuario"
  )
  VALUES (
    p_Fecha, p_TipoAsiento, p_Concepto,
    COALESCE(p_OrigenDocumento, p_Referencia),
    'APROBADO', v_TotalDebe, v_TotalHaber,
    p_OrigenModulo, COALESCE(p_CodUsuario, 'API')
  )
  RETURNING "Id" INTO p_AsientoId;

  INSERT INTO public."Asientos_Detalle" (
    "Id_Asiento", "Cod_Cuenta", "Descripcion", "CentroCosto",
    "AuxiliarTipo", "AuxiliarCodigo", "Documento", "Debe", "Haber"
  )
  SELECT
    p_AsientoId,
    r->>'codCuenta',
    NULLIF(r->>'descripcion', ''),
    NULLIF(r->>'centroCosto', ''),
    NULLIF(r->>'auxiliarTipo', ''),
    NULLIF(r->>'auxiliarCodigo', ''),
    NULLIF(r->>'documento', ''),
    COALESCE((r->>'debe')::NUMERIC, 0),
    COALESCE((r->>'haber')::NUMERIC, 0)
  FROM jsonb_array_elements(p_DetalleJson) r;

  p_NumeroAsiento := 'LEG-' || LPAD(p_AsientoId::TEXT, 10, '0');
  p_Resultado := 1;
  p_Mensaje := 'Asiento creado correctamente.';
END;
$$;
-- +goose StatementEnd

-- ============================================================
-- usp_Contabilidad_Asiento_Anular
-- ============================================================
DROP FUNCTION IF EXISTS public."usp_Contabilidad_Asiento_Anular"(BIGINT, VARCHAR, VARCHAR, INT, VARCHAR) CASCADE;
CREATE OR REPLACE FUNCTION public."usp_Contabilidad_Asiento_Anular"(
  p_AsientoId  BIGINT,
  p_Motivo     VARCHAR,
  p_CodUsuario VARCHAR DEFAULT NULL,
  OUT p_Resultado INT,
  OUT p_Mensaje   VARCHAR
)
-- +goose StatementBegin
LANGUAGE plpgsql AS $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public."Asientos" WHERE "Id" = p_AsientoId) THEN
    p_Resultado := 0;
    p_Mensaje := 'Asiento no encontrado.';
    RETURN;
  END IF;

  UPDATE public."Asientos"
  SET "Estado" = 'ANULADO',
      "Concepto" = LEFT("Concepto" || ' | ANULADO: ' || COALESCE(p_Motivo, ''), 400),
      "FechaActualizacion" = (NOW() AT TIME ZONE 'UTC')
  WHERE "Id" = p_AsientoId;

  p_Resultado := 1;
  p_Mensaje := 'Asiento anulado.';
END;
$$;
-- +goose StatementEnd

-- ============================================================
-- usp_Contabilidad_Ajuste_Crear
-- ============================================================
DROP FUNCTION IF EXISTS public."usp_Contabilidad_Ajuste_Crear"(DATE, VARCHAR, VARCHAR, VARCHAR, VARCHAR, JSONB, BIGINT, INT, VARCHAR) CASCADE;
CREATE OR REPLACE FUNCTION public."usp_Contabilidad_Ajuste_Crear"(
  p_Fecha       DATE,
  p_TipoAjuste  VARCHAR,
  p_Referencia   VARCHAR DEFAULT NULL,
  p_Motivo       VARCHAR DEFAULT '',
  p_CodUsuario   VARCHAR DEFAULT NULL,
  p_DetalleJson  JSONB   DEFAULT '[]'::JSONB,
  OUT p_AsientoId  BIGINT,
  OUT p_Resultado  INT,
  OUT p_Mensaje    VARCHAR
)
-- +goose StatementBegin
LANGUAGE plpgsql AS $$
DECLARE
  v_NumeroAsiento VARCHAR;
BEGIN
  SELECT * INTO p_AsientoId, v_NumeroAsiento, p_Resultado, p_Mensaje
  FROM public."usp_Contabilidad_Asiento_Crear"(
    p_Fecha,
    p_TipoAjuste,
    p_Referencia,
    p_Motivo,
    'VES',
    1,
    'AJUSTE',
    p_Referencia,
    p_CodUsuario,
    p_DetalleJson
  );
END;
$$;
-- +goose StatementEnd

-- ============================================================
-- usp_Contabilidad_Depreciacion_Generar (stub)
-- ============================================================
DROP FUNCTION IF EXISTS public."usp_Contabilidad_Depreciacion_Generar"(VARCHAR, VARCHAR, VARCHAR, INT, VARCHAR) CASCADE;
CREATE OR REPLACE FUNCTION public."usp_Contabilidad_Depreciacion_Generar"(
  p_Periodo     VARCHAR,
  p_CodUsuario  VARCHAR DEFAULT NULL,
  p_CentroCosto VARCHAR DEFAULT NULL,
  OUT p_Resultado INT,
  OUT p_Mensaje   VARCHAR
)
-- +goose StatementBegin
LANGUAGE plpgsql AS $$
BEGIN
  p_Resultado := 1;
  p_Mensaje := 'Proceso de depreciacion preparado (sin reglas cargadas).';
END;
$$;
-- +goose StatementEnd

-- ============================================================
-- usp_Contabilidad_Libro_Mayor
-- ============================================================
DROP FUNCTION IF EXISTS public."usp_Contabilidad_Libro_Mayor"(DATE, DATE) CASCADE;
CREATE OR REPLACE FUNCTION public."usp_Contabilidad_Libro_Mayor"(
  p_FechaDesde DATE,
  p_FechaHasta DATE
)
RETURNS TABLE (
  "CodCuenta"   VARCHAR,
  "Descripcion" VARCHAR,
  "Debe"        NUMERIC,
  "Haber"       NUMERIC,
  "Saldo"       NUMERIC
)
-- +goose StatementBegin
LANGUAGE plpgsql AS $$
BEGIN
  RETURN QUERY
  SELECT
    d."Cod_Cuenta"::VARCHAR,
    c."Desc_Cta"::VARCHAR,
    SUM(d."Debe"),
    SUM(d."Haber"),
    SUM(d."Debe" - d."Haber")
  FROM public."Asientos_Detalle" d
  INNER JOIN public."Asientos" a ON a."Id" = d."Id_Asiento"
  LEFT JOIN public."Cuentas" c ON c."Cod_Cuenta" = d."Cod_Cuenta"
  WHERE a."Fecha" BETWEEN p_FechaDesde AND p_FechaHasta
    AND a."Estado" <> 'ANULADO'
  GROUP BY d."Cod_Cuenta", c."Desc_Cta"
  ORDER BY d."Cod_Cuenta";
END;
$$;
-- +goose StatementEnd

-- ============================================================
-- usp_Contabilidad_Mayor_Analitico
-- ============================================================
DROP FUNCTION IF EXISTS public."usp_Contabilidad_Mayor_Analitico"(VARCHAR, DATE, DATE) CASCADE;
CREATE OR REPLACE FUNCTION public."usp_Contabilidad_Mayor_Analitico"(
  p_CodCuenta  VARCHAR,
  p_FechaDesde DATE,
  p_FechaHasta DATE
)
RETURNS TABLE (
  "AsientoId"      INT,
  "Fecha"          DATE,
  "Referencia"     VARCHAR,
  "Concepto"       VARCHAR,
  "Descripcion"    VARCHAR,
  "Debe"           NUMERIC,
  "Haber"          NUMERIC,
  "SaldoAcumulado" NUMERIC
)
-- +goose StatementBegin
LANGUAGE plpgsql AS $$
BEGIN
  RETURN QUERY
  SELECT
    a."Id",
    a."Fecha",
    a."Referencia"::VARCHAR,
    a."Concepto"::VARCHAR,
    d."Descripcion"::VARCHAR,
    d."Debe",
    d."Haber",
    SUM(d."Debe" - d."Haber") OVER (ORDER BY a."Fecha", a."Id", d."Id" ROWS UNBOUNDED PRECEDING)
  FROM public."Asientos_Detalle" d
  INNER JOIN public."Asientos" a ON a."Id" = d."Id_Asiento"
  WHERE d."Cod_Cuenta" = p_CodCuenta
    AND a."Fecha" BETWEEN p_FechaDesde AND p_FechaHasta
    AND a."Estado" <> 'ANULADO'
  ORDER BY a."Fecha", a."Id", d."Id";
END;
$$;
-- +goose StatementEnd

-- ============================================================
-- usp_Contabilidad_Balance_Comprobacion
-- ============================================================
DROP FUNCTION IF EXISTS public."usp_Contabilidad_Balance_Comprobacion"(DATE, DATE) CASCADE;
CREATE OR REPLACE FUNCTION public."usp_Contabilidad_Balance_Comprobacion"(
  p_FechaDesde DATE,
  p_FechaHasta DATE
)
RETURNS TABLE (
  "CodCuenta"   VARCHAR,
  "Descripcion" VARCHAR,
  "Debe"        NUMERIC,
  "Haber"       NUMERIC,
  "Saldo"       NUMERIC
)
-- +goose StatementBegin
LANGUAGE plpgsql AS $$
BEGIN
  RETURN QUERY
  SELECT
    d."Cod_Cuenta"::VARCHAR,
    c."Desc_Cta"::VARCHAR,
    SUM(d."Debe"),
    SUM(d."Haber"),
    SUM(d."Debe" - d."Haber")
  FROM public."Asientos_Detalle" d
  INNER JOIN public."Asientos" a ON a."Id" = d."Id_Asiento"
  LEFT JOIN public."Cuentas" c ON c."Cod_Cuenta" = d."Cod_Cuenta"
  WHERE a."Fecha" BETWEEN p_FechaDesde AND p_FechaHasta
    AND a."Estado" <> 'ANULADO'
  GROUP BY d."Cod_Cuenta", c."Desc_Cta"
  ORDER BY d."Cod_Cuenta";
END;
$$;
-- +goose StatementEnd

-- ============================================================
-- usp_Contabilidad_Estado_Resultados
-- ============================================================
DROP FUNCTION IF EXISTS public."usp_Contabilidad_Estado_Resultados"(DATE, DATE) CASCADE;
CREATE OR REPLACE FUNCTION public."usp_Contabilidad_Estado_Resultados"(
  p_FechaDesde DATE,
  p_FechaHasta DATE
)
RETURNS TABLE (
  "Tipo"            CHAR(1),
  "CodCuenta"       VARCHAR,
  "Descripcion"     VARCHAR,
  "Debe"            NUMERIC,
  "Haber"           NUMERIC,
  "SaldoResultado"  NUMERIC
)
-- +goose StatementBegin
LANGUAGE plpgsql AS $$
BEGIN
  RETURN QUERY
  SELECT
    c."Tipo",
    d."Cod_Cuenta"::VARCHAR,
    c."Desc_Cta"::VARCHAR,
    SUM(d."Debe"),
    SUM(d."Haber"),
    SUM(d."Haber" - d."Debe")
  FROM public."Asientos_Detalle" d
  INNER JOIN public."Asientos" a ON a."Id" = d."Id_Asiento"
  INNER JOIN public."Cuentas" c ON c."Cod_Cuenta" = d."Cod_Cuenta"
  WHERE a."Fecha" BETWEEN p_FechaDesde AND p_FechaHasta
    AND a."Estado" <> 'ANULADO'
    AND c."Tipo" IN ('I','G')
  GROUP BY c."Tipo", d."Cod_Cuenta", c."Desc_Cta"
  ORDER BY d."Cod_Cuenta";
END;
$$;
-- +goose StatementEnd

-- ============================================================
-- usp_Contabilidad_Balance_General
-- ============================================================
DROP FUNCTION IF EXISTS public."usp_Contabilidad_Balance_General"(DATE) CASCADE;
CREATE OR REPLACE FUNCTION public."usp_Contabilidad_Balance_General"(
  p_FechaCorte DATE
)
RETURNS TABLE (
  "Tipo"        CHAR(1),
  "CodCuenta"   VARCHAR,
  "Descripcion" VARCHAR,
  "Debe"        NUMERIC,
  "Haber"       NUMERIC,
  "Saldo"       NUMERIC
)
-- +goose StatementBegin
LANGUAGE plpgsql AS $$
BEGIN
  RETURN QUERY
  SELECT
    c."Tipo",
    d."Cod_Cuenta"::VARCHAR,
    c."Desc_Cta"::VARCHAR,
    SUM(d."Debe"),
    SUM(d."Haber"),
    CASE WHEN c."Tipo" = 'A' THEN SUM(d."Debe" - d."Haber")
         ELSE -SUM(d."Debe" - d."Haber") END
  FROM public."Asientos_Detalle" d
  INNER JOIN public."Asientos" a ON a."Id" = d."Id_Asiento"
  INNER JOIN public."Cuentas" c ON c."Cod_Cuenta" = d."Cod_Cuenta"
  WHERE a."Fecha" <= p_FechaCorte
    AND a."Estado" <> 'ANULADO'
    AND c."Tipo" IN ('A','P','C')
  GROUP BY c."Tipo", d."Cod_Cuenta", c."Desc_Cta"
  ORDER BY d."Cod_Cuenta";
END;
$$;
-- +goose StatementEnd

-- ============================================================
-- NOTA: Los triggers de sincronizacion bidireccional
-- (TR_Asientos_AI_SyncJournalEntry, TR_Cuentas_AIUD_SyncAccount,
--  TR_FiscalCountryConfig_AIUD_SyncCanonical, etc.) se implementan
-- como trigger functions en PG en un script separado de SPs.
-- Aqui solo se crean las tablas y funciones de consulta.
-- ============================================================

COMMIT;

-- Source: 07_pos_rest_extensions.sql
-- ============================================================
-- DatqBoxWeb PostgreSQL - 07_pos_rest_extensions.sql
-- Tablas: pos."FiscalCorrelative", rest."DiningTable" + seeds
-- ============================================================

BEGIN;

-- ============================================================
-- pos.FiscalCorrelative
-- ============================================================
CREATE TABLE IF NOT EXISTS pos."FiscalCorrelative" (
  "FiscalCorrelativeId"  BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"            INT         NOT NULL,
  "BranchId"             INT         NOT NULL,
  "CorrelativeType"      VARCHAR(20) NOT NULL DEFAULT 'FACTURA',
  "CashRegisterCode"     VARCHAR(10) NOT NULL DEFAULT 'GLOBAL',
  "SerialFiscal"         VARCHAR(40) NOT NULL,
  "CurrentNumber"        INT         NOT NULL DEFAULT 0,
  "Description"          VARCHAR(200) NULL,
  "IsActive"             BOOLEAN     NOT NULL DEFAULT TRUE,
  "CreatedAt"            TIMESTAMP   NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"            TIMESTAMP   NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId"      INT         NULL,
  "UpdatedByUserId"      INT         NULL,
  "RowVer"               INT         NOT NULL DEFAULT 1,
  CONSTRAINT "UQ_pos_FiscalCorrelative" UNIQUE ("CompanyId", "BranchId", "CorrelativeType", "CashRegisterCode"),
  CONSTRAINT "FK_pos_FiscalCorrelative_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId"),
  CONSTRAINT "FK_pos_FiscalCorrelative_Branch" FOREIGN KEY ("BranchId") REFERENCES cfg."Branch"("BranchId"),
  CONSTRAINT "FK_pos_FiscalCorrelative_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_pos_FiscalCorrelative_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId")
);

CREATE INDEX IF NOT EXISTS "IX_pos_FiscalCorrelative_Search"
  ON pos."FiscalCorrelative" ("CompanyId", "BranchId", "CorrelativeType", "CashRegisterCode", "IsActive");

-- ============================================================
-- rest.DiningTable
-- ============================================================
CREATE TABLE IF NOT EXISTS rest."DiningTable" (
  "DiningTableId"    BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"        INT          NOT NULL,
  "BranchId"         INT          NOT NULL,
  "TableNumber"      VARCHAR(20)  NOT NULL,
  "TableName"        VARCHAR(100) NULL,
  "Capacity"         INT          NOT NULL DEFAULT 4,
  "EnvironmentCode"  VARCHAR(20)  NULL,
  "EnvironmentName"  VARCHAR(80)  NULL,
  "PositionX"        INT          NULL,
  "PositionY"        INT          NULL,
  "IsActive"         BOOLEAN      NOT NULL DEFAULT TRUE,
  "CreatedAt"        TIMESTAMP    NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"        TIMESTAMP    NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId"  INT          NULL,
  "UpdatedByUserId"  INT          NULL,
  "RowVer"           INT          NOT NULL DEFAULT 1,
  CONSTRAINT "UQ_rest_DiningTable" UNIQUE ("CompanyId", "BranchId", "TableNumber"),
  CONSTRAINT "FK_rest_DiningTable_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId"),
  CONSTRAINT "FK_rest_DiningTable_Branch" FOREIGN KEY ("BranchId") REFERENCES cfg."Branch"("BranchId"),
  CONSTRAINT "FK_rest_DiningTable_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_rest_DiningTable_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId")
);

CREATE INDEX IF NOT EXISTS "IX_rest_DiningTable_Search"
  ON rest."DiningTable" ("CompanyId", "BranchId", "IsActive", "EnvironmentCode", "TableNumber");

-- ============================================================
-- SEEDS
-- ============================================================
-- +goose StatementBegin
DO $$
DECLARE
  v_DefaultCompanyId INT;
  v_DefaultBranchId  INT;
  v_SystemUserId     INT;
  v_n                INT;
BEGIN
  SELECT "CompanyId" INTO v_DefaultCompanyId
    FROM cfg."Company" WHERE "CompanyCode" = 'DEFAULT' LIMIT 1;
  SELECT "BranchId" INTO v_DefaultBranchId
    FROM cfg."Branch"
    WHERE "CompanyId" = v_DefaultCompanyId AND "BranchCode" = 'MAIN' LIMIT 1;
  SELECT "UserId" INTO v_SystemUserId
    FROM sec."User" WHERE "UserCode" = 'SYSTEM' LIMIT 1;

  IF v_DefaultCompanyId IS NOT NULL AND v_DefaultBranchId IS NOT NULL THEN

    -- Seed: FiscalCorrelative
    INSERT INTO pos."FiscalCorrelative" (
      "CompanyId", "BranchId", "CorrelativeType", "CashRegisterCode",
      "SerialFiscal", "CurrentNumber", "Description", "IsActive",
      "CreatedByUserId", "UpdatedByUserId"
    )
    VALUES (
      v_DefaultCompanyId, v_DefaultBranchId, 'FACTURA', 'GLOBAL',
      'SERIAL-DEMO', 0, 'Correlativo fiscal global por defecto', TRUE,
      v_SystemUserId, v_SystemUserId
    )
    ON CONFLICT ("CompanyId", "BranchId", "CorrelativeType", "CashRegisterCode") DO NOTHING;

    -- Seed: 20 mesas de restaurante (recursive CTE)
    IF NOT EXISTS (
      SELECT 1 FROM rest."DiningTable"
      WHERE "CompanyId" = v_DefaultCompanyId AND "BranchId" = v_DefaultBranchId
    ) THEN
      WITH RECURSIVE n_series AS (
        SELECT 1 AS n
        UNION ALL
        SELECT n + 1 FROM n_series WHERE n < 20
      )
      INSERT INTO rest."DiningTable" (
        "CompanyId", "BranchId", "TableNumber", "TableName",
        "Capacity", "EnvironmentCode", "EnvironmentName",
        "PositionX", "PositionY", "IsActive",
        "CreatedByUserId", "UpdatedByUserId"
      )
      SELECT
        v_DefaultCompanyId,
        v_DefaultBranchId,
        n::TEXT,
        'Mesa ' || n::TEXT,
        4,
        'SALON',
        'Salon Principal',
        ((n - 1) % 5) * 120,
        ((n - 1) / 5) * 120,
        TRUE,
        v_SystemUserId,
        v_SystemUserId
      FROM n_series;
    END IF;

  END IF;
END $$;
-- +goose StatementEnd

COMMIT;

-- Source: 08_fin_hr_extensions.sql
-- ============================================================
-- DatqBoxWeb PostgreSQL - 08_fin_hr_extensions.sql
-- Tablas de finanzas (fin.*), recursos humanos (hr.*),
-- extensiones restaurante (rest.*) y seeds
-- ============================================================

BEGIN;

-- Crear schemas si no existen
CREATE SCHEMA IF NOT EXISTS fin;
CREATE SCHEMA IF NOT EXISTS hr;

-- ============================================================
-- fin.Bank
-- ============================================================
CREATE TABLE IF NOT EXISTS fin."Bank" (
  "BankId"           BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"        INT          NOT NULL,
  "BankCode"         VARCHAR(30)  NOT NULL,
  "BankName"         VARCHAR(120) NOT NULL,
  "ContactName"      VARCHAR(120) NULL,
  "AddressLine"      VARCHAR(250) NULL,
  "Phones"           VARCHAR(120) NULL,
  "IsActive"         BOOLEAN      NOT NULL DEFAULT TRUE,
  "CreatedAt"        TIMESTAMP    NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"        TIMESTAMP    NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId"  INT          NULL,
  "UpdatedByUserId"  INT          NULL,
  "RowVer"           INT          NOT NULL DEFAULT 1,
  CONSTRAINT "UQ_fin_Bank_Code" UNIQUE ("CompanyId", "BankCode"),
  CONSTRAINT "UQ_fin_Bank_Name" UNIQUE ("CompanyId", "BankName"),
  CONSTRAINT "FK_fin_Bank_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId"),
  CONSTRAINT "FK_fin_Bank_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_fin_Bank_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId")
);

-- ============================================================
-- fin.BankAccount
-- ============================================================
CREATE TABLE IF NOT EXISTS fin."BankAccount" (
  "BankAccountId"    BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"        INT            NOT NULL,
  "BranchId"         INT            NOT NULL,
  "BankId"           BIGINT         NOT NULL,
  "AccountNumber"    VARCHAR(40)    NOT NULL,
  "AccountName"      VARCHAR(150)   NULL,
  "CurrencyCode"     CHAR(3)        NOT NULL,
  "Balance"          NUMERIC(18,2)  NOT NULL DEFAULT 0,
  "AvailableBalance" NUMERIC(18,2)  NOT NULL DEFAULT 0,
  "IsActive"         BOOLEAN        NOT NULL DEFAULT TRUE,
  "CreatedAt"        TIMESTAMP      NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"        TIMESTAMP      NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId"  INT            NULL,
  "UpdatedByUserId"  INT            NULL,
  "RowVer"           INT            NOT NULL DEFAULT 1,
  CONSTRAINT "UQ_fin_BankAccount" UNIQUE ("CompanyId", "AccountNumber"),
  CONSTRAINT "FK_fin_BankAccount_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId"),
  CONSTRAINT "FK_fin_BankAccount_Branch" FOREIGN KEY ("BranchId") REFERENCES cfg."Branch"("BranchId"),
  CONSTRAINT "FK_fin_BankAccount_Bank" FOREIGN KEY ("BankId") REFERENCES fin."Bank"("BankId"),
  CONSTRAINT "FK_fin_BankAccount_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_fin_BankAccount_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId")
);

CREATE INDEX IF NOT EXISTS "IX_fin_BankAccount_Search"
  ON fin."BankAccount" ("CompanyId", "BranchId", "IsActive", "AccountNumber");

-- ============================================================
-- fin.BankReconciliation
-- ============================================================
CREATE TABLE IF NOT EXISTS fin."BankReconciliation" (
  "BankReconciliationId" BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"            INT            NOT NULL,
  "BranchId"             INT            NOT NULL,
  "BankAccountId"        BIGINT         NOT NULL,
  "DateFrom"             DATE           NOT NULL,
  "DateTo"               DATE           NOT NULL,
  "OpeningSystemBalance" NUMERIC(18,2)  NOT NULL,
  "ClosingSystemBalance" NUMERIC(18,2)  NOT NULL,
  "OpeningBankBalance"   NUMERIC(18,2)  NOT NULL,
  "ClosingBankBalance"   NUMERIC(18,2)  NULL,
  "DifferenceAmount"     NUMERIC(18,2)  NULL,
  "Status"               VARCHAR(20)    NOT NULL DEFAULT 'OPEN',
  "Notes"                VARCHAR(500)   NULL,
  "ClosedAt"             TIMESTAMP      NULL,
  "CreatedAt"            TIMESTAMP      NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"            TIMESTAMP      NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId"      INT            NULL,
  "ClosedByUserId"       INT            NULL,
  "RowVer"               INT            NOT NULL DEFAULT 1,
  CONSTRAINT "CK_fin_BankRec_Status" CHECK ("Status" IN ('OPEN','CLOSED','CLOSED_WITH_DIFF')),
  CONSTRAINT "FK_fin_BankRec_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId"),
  CONSTRAINT "FK_fin_BankRec_Branch" FOREIGN KEY ("BranchId") REFERENCES cfg."Branch"("BranchId"),
  CONSTRAINT "FK_fin_BankRec_Account" FOREIGN KEY ("BankAccountId") REFERENCES fin."BankAccount"("BankAccountId"),
  CONSTRAINT "FK_fin_BankRec_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_fin_BankRec_ClosedBy" FOREIGN KEY ("ClosedByUserId") REFERENCES sec."User"("UserId")
);

CREATE INDEX IF NOT EXISTS "IX_fin_BankRec_Search"
  ON fin."BankReconciliation" ("BankAccountId", "Status", "DateFrom", "DateTo");

-- ============================================================
-- fin.BankMovement
-- ============================================================
CREATE TABLE IF NOT EXISTS fin."BankMovement" (
  "BankMovementId"    BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "BankAccountId"     BIGINT         NOT NULL,
  "ReconciliationId"  BIGINT         NULL,
  "MovementDate"      TIMESTAMP      NOT NULL,
  "MovementType"      VARCHAR(12)    NOT NULL,
  "MovementSign"      SMALLINT       NOT NULL,
  "Amount"            NUMERIC(18,2)  NOT NULL,
  "NetAmount"         NUMERIC(18,2)  NOT NULL,
  "ReferenceNo"       VARCHAR(50)    NULL,
  "Beneficiary"       VARCHAR(255)   NULL,
  "Concept"           VARCHAR(255)   NULL,
  "CategoryCode"      VARCHAR(50)    NULL,
  "RelatedDocumentNo"   VARCHAR(60)  NULL,
  "RelatedDocumentType" VARCHAR(20)  NULL,
  "BalanceAfter"      NUMERIC(18,2)  NULL,
  "IsReconciled"      BOOLEAN        NOT NULL DEFAULT FALSE,
  "ReconciledAt"      TIMESTAMP      NULL,
  "CreatedAt"         TIMESTAMP      NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId"   INT            NULL,
  "RowVer"            INT            NOT NULL DEFAULT 1,
  CONSTRAINT "CK_fin_BankMovement_Sign" CHECK ("MovementSign" IN (-1, 1)),
  CONSTRAINT "CK_fin_BankMovement_Amount" CHECK ("Amount" >= 0),
  CONSTRAINT "FK_fin_BankMovement_Account" FOREIGN KEY ("BankAccountId") REFERENCES fin."BankAccount"("BankAccountId"),
  CONSTRAINT "FK_fin_BankMovement_Reconciliation" FOREIGN KEY ("ReconciliationId") REFERENCES fin."BankReconciliation"("BankReconciliationId"),
  CONSTRAINT "FK_fin_BankMovement_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId")
);

CREATE INDEX IF NOT EXISTS "IX_fin_BankMovement_Search"
  ON fin."BankMovement" ("BankAccountId", "MovementDate" DESC, "BankMovementId" DESC);

-- ============================================================
-- fin.BankStatementLine
-- ============================================================
CREATE TABLE IF NOT EXISTS fin."BankStatementLine" (
  "StatementLineId"  BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "ReconciliationId" BIGINT         NOT NULL,
  "StatementDate"    TIMESTAMP      NOT NULL,
  "DescriptionText"  VARCHAR(255)   NULL,
  "ReferenceNo"      VARCHAR(50)    NULL,
  "EntryType"        VARCHAR(12)    NOT NULL,
  "Amount"           NUMERIC(18,2)  NOT NULL,
  "Balance"          NUMERIC(18,2)  NULL,
  "IsMatched"        BOOLEAN        NOT NULL DEFAULT FALSE,
  "MatchedAt"        TIMESTAMP      NULL,
  "CreatedAt"        TIMESTAMP      NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId"  INT            NULL,
  "RowVer"           INT            NOT NULL DEFAULT 1,
  CONSTRAINT "CK_fin_BankStatementLine_EntryType" CHECK ("EntryType" IN ('DEBITO', 'CREDITO')),
  CONSTRAINT "CK_fin_BankStatementLine_Amount" CHECK ("Amount" >= 0),
  CONSTRAINT "FK_fin_BankStatementLine_Reconciliation" FOREIGN KEY ("ReconciliationId") REFERENCES fin."BankReconciliation"("BankReconciliationId"),
  CONSTRAINT "FK_fin_BankStatementLine_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId")
);

CREATE INDEX IF NOT EXISTS "IX_fin_BankStatementLine_Search"
  ON fin."BankStatementLine" ("ReconciliationId", "IsMatched", "StatementDate");

-- ============================================================
-- fin.BankReconciliationMatch
-- ============================================================
CREATE TABLE IF NOT EXISTS fin."BankReconciliationMatch" (
  "BankReconciliationMatchId" BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "ReconciliationId"          BIGINT    NOT NULL,
  "BankMovementId"            BIGINT    NOT NULL,
  "StatementLineId"           BIGINT    NULL,
  "MatchedAt"                 TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "MatchedByUserId"           INT       NULL,
  CONSTRAINT "UQ_fin_BankRecMatch_Movement" UNIQUE ("ReconciliationId", "BankMovementId"),
  CONSTRAINT "UQ_fin_BankRecMatch_Statement" UNIQUE ("ReconciliationId", "StatementLineId"),
  CONSTRAINT "FK_fin_BankRecMatch_Reconciliation" FOREIGN KEY ("ReconciliationId") REFERENCES fin."BankReconciliation"("BankReconciliationId"),
  CONSTRAINT "FK_fin_BankRecMatch_Movement" FOREIGN KEY ("BankMovementId") REFERENCES fin."BankMovement"("BankMovementId"),
  CONSTRAINT "FK_fin_BankRecMatch_Statement" FOREIGN KEY ("StatementLineId") REFERENCES fin."BankStatementLine"("StatementLineId"),
  CONSTRAINT "FK_fin_BankRecMatch_User" FOREIGN KEY ("MatchedByUserId") REFERENCES sec."User"("UserId")
);

-- ============================================================
-- hr.PayrollType
-- ============================================================
CREATE TABLE IF NOT EXISTS hr."PayrollType" (
  "PayrollTypeId"    BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"        INT          NOT NULL,
  "PayrollCode"      VARCHAR(15)  NOT NULL,
  "PayrollName"      VARCHAR(120) NOT NULL,
  "IsActive"         BOOLEAN      NOT NULL DEFAULT TRUE,
  "CreatedAt"        TIMESTAMP    NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"        TIMESTAMP    NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId"  INT          NULL,
  "UpdatedByUserId"  INT          NULL,
  "RowVer"           INT          NOT NULL DEFAULT 1,
  CONSTRAINT "UQ_hr_PayrollType" UNIQUE ("CompanyId", "PayrollCode"),
  CONSTRAINT "FK_hr_PayrollType_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId"),
  CONSTRAINT "FK_hr_PayrollType_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_hr_PayrollType_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId")
);

-- ============================================================
-- hr.PayrollConcept
-- ============================================================
CREATE TABLE IF NOT EXISTS hr."PayrollConcept" (
  "PayrollConceptId"      BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"             INT            NOT NULL,
  "PayrollCode"           VARCHAR(15)    NOT NULL,
  "ConceptCode"           VARCHAR(20)    NOT NULL,
  "ConceptName"           VARCHAR(120)   NOT NULL,
  "Formula"               VARCHAR(500)   NULL,
  "BaseExpression"        VARCHAR(255)   NULL,
  "ConceptClass"          VARCHAR(20)    NULL,
  "ConceptType"           VARCHAR(15)    NOT NULL DEFAULT 'ASIGNACION',
  "UsageType"             VARCHAR(20)    NULL,
  "IsBonifiable"          BOOLEAN        NOT NULL DEFAULT FALSE,
  "IsSeniority"           BOOLEAN        NOT NULL DEFAULT FALSE,
  "AccountingAccountCode" VARCHAR(50)    NULL,
  "AppliesFlag"           BOOLEAN        NOT NULL DEFAULT TRUE,
  "DefaultValue"          NUMERIC(18,4)  NOT NULL DEFAULT 0,
  "ConventionCode"        VARCHAR(50)    NULL,
  "CalculationType"       VARCHAR(50)    NULL,
  "LotttArticle"          VARCHAR(50)    NULL,
  "CcpClause"             VARCHAR(50)    NULL,
  "SortOrder"             INT            NOT NULL DEFAULT 0,
  "IsActive"              BOOLEAN        NOT NULL DEFAULT TRUE,
  "CreatedAt"             TIMESTAMP      NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"             TIMESTAMP      NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId"       INT            NULL,
  "UpdatedByUserId"       INT            NULL,
  "RowVer"                INT            NOT NULL DEFAULT 1,
  CONSTRAINT "CK_hr_PayrollConcept_Type" CHECK ("ConceptType" IN ('ASIGNACION', 'DEDUCCION', 'BONO')),
  CONSTRAINT "UQ_hr_PayrollConcept" UNIQUE ("CompanyId", "PayrollCode", "ConceptCode", "ConventionCode", "CalculationType"),
  CONSTRAINT "FK_hr_PayrollConcept_PayrollType" FOREIGN KEY ("CompanyId", "PayrollCode") REFERENCES hr."PayrollType"("CompanyId", "PayrollCode"),
  CONSTRAINT "FK_hr_PayrollConcept_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_hr_PayrollConcept_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId")
);

CREATE INDEX IF NOT EXISTS "IX_hr_PayrollConcept_Search"
  ON hr."PayrollConcept" ("CompanyId", "PayrollCode", "IsActive", "ConceptType", "SortOrder", "ConceptCode");

-- ============================================================
-- hr.PayrollRun
-- ============================================================
CREATE TABLE IF NOT EXISTS hr."PayrollRun" (
  "PayrollRunId"     BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"        INT            NOT NULL,
  "BranchId"         INT            NOT NULL,
  "PayrollCode"      VARCHAR(15)    NOT NULL,
  "EmployeeId"       BIGINT         NULL,
  "EmployeeCode"     VARCHAR(24)    NOT NULL,
  "EmployeeName"     VARCHAR(200)   NOT NULL,
  "PositionName"     VARCHAR(120)   NULL,
  "ProcessDate"      DATE           NOT NULL,
  "DateFrom"         DATE           NOT NULL,
  "DateTo"           DATE           NOT NULL,
  "TotalAssignments" NUMERIC(18,2)  NOT NULL DEFAULT 0,
  "TotalDeductions"  NUMERIC(18,2)  NOT NULL DEFAULT 0,
  "NetTotal"         NUMERIC(18,2)  NOT NULL DEFAULT 0,
  "IsClosed"         BOOLEAN        NOT NULL DEFAULT FALSE,
  "PayrollTypeName"  VARCHAR(50)    NULL,
  "RunSource"        VARCHAR(20)    NOT NULL DEFAULT 'MANUAL',
  "ClosedAt"         TIMESTAMP      NULL,
  "ClosedByUserId"   INT            NULL,
  "CreatedAt"        TIMESTAMP      NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"        TIMESTAMP      NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId"  INT            NULL,
  "UpdatedByUserId"  INT            NULL,
  "RowVer"           INT            NOT NULL DEFAULT 1,
  CONSTRAINT "UQ_hr_PayrollRun" UNIQUE ("CompanyId", "BranchId", "PayrollCode", "EmployeeCode", "DateFrom", "DateTo", "RunSource"),
  CONSTRAINT "FK_hr_PayrollRun_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId"),
  CONSTRAINT "FK_hr_PayrollRun_Branch" FOREIGN KEY ("BranchId") REFERENCES cfg."Branch"("BranchId"),
  CONSTRAINT "FK_hr_PayrollRun_Employee" FOREIGN KEY ("EmployeeId") REFERENCES master."Employee"("EmployeeId"),
  CONSTRAINT "FK_hr_PayrollRun_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_hr_PayrollRun_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_hr_PayrollRun_ClosedBy" FOREIGN KEY ("ClosedByUserId") REFERENCES sec."User"("UserId")
);

CREATE INDEX IF NOT EXISTS "IX_hr_PayrollRun_Search"
  ON hr."PayrollRun" ("CompanyId", "PayrollCode", "EmployeeCode", "ProcessDate" DESC, "IsClosed");

-- ============================================================
-- hr.PayrollRunLine
-- ============================================================
CREATE TABLE IF NOT EXISTS hr."PayrollRunLine" (
  "PayrollRunLineId"      BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "PayrollRunId"          BIGINT         NOT NULL,
  "ConceptCode"           VARCHAR(20)    NOT NULL,
  "ConceptName"           VARCHAR(120)   NOT NULL,
  "ConceptType"           VARCHAR(15)    NOT NULL,
  "Quantity"              NUMERIC(18,4)  NOT NULL DEFAULT 1,
  "Amount"                NUMERIC(18,4)  NOT NULL DEFAULT 0,
  "Total"                 NUMERIC(18,2)  NOT NULL DEFAULT 0,
  "DescriptionText"       VARCHAR(255)   NULL,
  "AccountingAccountCode" VARCHAR(50)    NULL,
  "CreatedAt"             TIMESTAMP      NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  CONSTRAINT "FK_hr_PayrollRunLine_Run" FOREIGN KEY ("PayrollRunId") REFERENCES hr."PayrollRun"("PayrollRunId") ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS "IX_hr_PayrollRunLine_Run"
  ON hr."PayrollRunLine" ("PayrollRunId", "ConceptType", "ConceptCode");

-- ============================================================
-- hr.VacationProcess
-- ============================================================
CREATE TABLE IF NOT EXISTS hr."VacationProcess" (
  "VacationProcessId" BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"          INT            NOT NULL,
  "BranchId"           INT            NOT NULL,
  "VacationCode"       VARCHAR(50)    NOT NULL,
  "EmployeeId"         BIGINT         NULL,
  "EmployeeCode"       VARCHAR(24)    NOT NULL,
  "EmployeeName"       VARCHAR(200)   NOT NULL,
  "StartDate"          DATE           NOT NULL,
  "EndDate"            DATE           NOT NULL,
  "ReintegrationDate"  DATE           NULL,
  "ProcessDate"        DATE           NOT NULL,
  "TotalAmount"        NUMERIC(18,2)  NOT NULL DEFAULT 0,
  "CalculatedAmount"   NUMERIC(18,2)  NOT NULL DEFAULT 0,
  "CreatedAt"          TIMESTAMP      NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"          TIMESTAMP      NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId"    INT            NULL,
  "UpdatedByUserId"    INT            NULL,
  "RowVer"             INT            NOT NULL DEFAULT 1,
  CONSTRAINT "UQ_hr_VacationProcess" UNIQUE ("CompanyId", "VacationCode"),
  CONSTRAINT "FK_hr_VacationProcess_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId"),
  CONSTRAINT "FK_hr_VacationProcess_Branch" FOREIGN KEY ("BranchId") REFERENCES cfg."Branch"("BranchId"),
  CONSTRAINT "FK_hr_VacationProcess_Employee" FOREIGN KEY ("EmployeeId") REFERENCES master."Employee"("EmployeeId"),
  CONSTRAINT "FK_hr_VacationProcess_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_hr_VacationProcess_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId")
);

-- ============================================================
-- hr.VacationProcessLine
-- ============================================================
CREATE TABLE IF NOT EXISTS hr."VacationProcessLine" (
  "VacationProcessLineId" BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "VacationProcessId"     BIGINT        NOT NULL,
  "ConceptCode"           VARCHAR(20)   NOT NULL,
  "ConceptName"           VARCHAR(120)  NOT NULL,
  "Amount"                NUMERIC(18,2) NOT NULL,
  "CreatedAt"             TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  CONSTRAINT "FK_hr_VacationProcessLine_Process" FOREIGN KEY ("VacationProcessId") REFERENCES hr."VacationProcess"("VacationProcessId") ON DELETE CASCADE
);

-- ============================================================
-- hr.SettlementProcess
-- ============================================================
CREATE TABLE IF NOT EXISTS hr."SettlementProcess" (
  "SettlementProcessId" BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"           INT            NOT NULL,
  "BranchId"            INT            NOT NULL,
  "SettlementCode"      VARCHAR(50)    NOT NULL,
  "EmployeeId"          BIGINT         NULL,
  "EmployeeCode"        VARCHAR(24)    NOT NULL,
  "EmployeeName"        VARCHAR(200)   NOT NULL,
  "RetirementDate"      DATE           NOT NULL,
  "RetirementCause"     VARCHAR(40)    NULL,
  "TotalAmount"         NUMERIC(18,2)  NOT NULL DEFAULT 0,
  "CreatedAt"           TIMESTAMP      NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"           TIMESTAMP      NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId"     INT            NULL,
  "UpdatedByUserId"     INT            NULL,
  "RowVer"              INT            NOT NULL DEFAULT 1,
  CONSTRAINT "UQ_hr_SettlementProcess" UNIQUE ("CompanyId", "SettlementCode"),
  CONSTRAINT "FK_hr_SettlementProcess_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId"),
  CONSTRAINT "FK_hr_SettlementProcess_Branch" FOREIGN KEY ("BranchId") REFERENCES cfg."Branch"("BranchId"),
  CONSTRAINT "FK_hr_SettlementProcess_Employee" FOREIGN KEY ("EmployeeId") REFERENCES master."Employee"("EmployeeId"),
  CONSTRAINT "FK_hr_SettlementProcess_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_hr_SettlementProcess_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId")
);

-- ============================================================
-- hr.SettlementProcessLine
-- ============================================================
CREATE TABLE IF NOT EXISTS hr."SettlementProcessLine" (
  "SettlementProcessLineId" BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "SettlementProcessId"     BIGINT        NOT NULL,
  "ConceptCode"             VARCHAR(20)   NOT NULL,
  "ConceptName"             VARCHAR(120)  NOT NULL,
  "Amount"                  NUMERIC(18,2) NOT NULL,
  "CreatedAt"               TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  CONSTRAINT "FK_hr_SettlementProcessLine_Process" FOREIGN KEY ("SettlementProcessId") REFERENCES hr."SettlementProcess"("SettlementProcessId") ON DELETE CASCADE
);

-- ============================================================
-- hr.PayrollConstant
-- ============================================================
CREATE TABLE IF NOT EXISTS hr."PayrollConstant" (
  "PayrollConstantId" BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"         INT            NOT NULL,
  "ConstantCode"      VARCHAR(50)    NOT NULL,
  "ConstantName"      VARCHAR(120)   NOT NULL,
  "ConstantValue"     NUMERIC(18,4)  NOT NULL,
  "SourceName"        VARCHAR(60)    NULL,
  "IsActive"          BOOLEAN        NOT NULL DEFAULT TRUE,
  "CreatedAt"         TIMESTAMP      NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"         TIMESTAMP      NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId"   INT            NULL,
  "UpdatedByUserId"   INT            NULL,
  "RowVer"            INT            NOT NULL DEFAULT 1,
  CONSTRAINT "UQ_hr_PayrollConstant" UNIQUE ("CompanyId", "ConstantCode"),
  CONSTRAINT "FK_hr_PayrollConstant_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId"),
  CONSTRAINT "FK_hr_PayrollConstant_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_hr_PayrollConstant_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId")
);

-- ============================================================
-- rest.MenuEnvironment
-- ============================================================
CREATE TABLE IF NOT EXISTS rest."MenuEnvironment" (
  "MenuEnvironmentId" BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"          INT          NOT NULL,
  "BranchId"           INT          NOT NULL,
  "EnvironmentCode"    VARCHAR(30)  NOT NULL,
  "EnvironmentName"    VARCHAR(120) NOT NULL,
  "ColorHex"           VARCHAR(10)  NULL,
  "SortOrder"          INT          NOT NULL DEFAULT 0,
  "IsActive"           BOOLEAN      NOT NULL DEFAULT TRUE,
  "CreatedAt"          TIMESTAMP    NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"          TIMESTAMP    NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId"    INT          NULL,
  "UpdatedByUserId"    INT          NULL,
  "RowVer"             INT          NOT NULL DEFAULT 1,
  CONSTRAINT "UQ_rest_MenuEnvironment" UNIQUE ("CompanyId", "BranchId", "EnvironmentCode"),
  CONSTRAINT "FK_rest_MenuEnvironment_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId"),
  CONSTRAINT "FK_rest_MenuEnvironment_Branch" FOREIGN KEY ("BranchId") REFERENCES cfg."Branch"("BranchId"),
  CONSTRAINT "FK_rest_MenuEnvironment_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_rest_MenuEnvironment_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId")
);

-- ============================================================
-- rest.MenuCategory
-- ============================================================
CREATE TABLE IF NOT EXISTS rest."MenuCategory" (
  "MenuCategoryId"   BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"        INT          NOT NULL,
  "BranchId"         INT          NOT NULL,
  "CategoryCode"     VARCHAR(30)  NOT NULL,
  "CategoryName"     VARCHAR(120) NOT NULL,
  "DescriptionText"  VARCHAR(250) NULL,
  "ColorHex"         VARCHAR(10)  NULL,
  "SortOrder"        INT          NOT NULL DEFAULT 0,
  "IsActive"         BOOLEAN      NOT NULL DEFAULT TRUE,
  "CreatedAt"        TIMESTAMP    NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"        TIMESTAMP    NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId"  INT          NULL,
  "UpdatedByUserId"  INT          NULL,
  "RowVer"           INT          NOT NULL DEFAULT 1,
  CONSTRAINT "UQ_rest_MenuCategory" UNIQUE ("CompanyId", "BranchId", "CategoryCode"),
  CONSTRAINT "FK_rest_MenuCategory_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId"),
  CONSTRAINT "FK_rest_MenuCategory_Branch" FOREIGN KEY ("BranchId") REFERENCES cfg."Branch"("BranchId"),
  CONSTRAINT "FK_rest_MenuCategory_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_rest_MenuCategory_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId")
);

-- ============================================================
-- rest.MenuProduct
-- ============================================================
CREATE TABLE IF NOT EXISTS rest."MenuProduct" (
  "MenuProductId"      BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"          INT            NOT NULL,
  "BranchId"           INT            NOT NULL,
  "ProductCode"        VARCHAR(40)    NOT NULL,
  "ProductName"        VARCHAR(200)   NOT NULL,
  "DescriptionText"    VARCHAR(500)   NULL,
  "MenuCategoryId"     BIGINT         NULL,
  "PriceAmount"        NUMERIC(18,2)  NOT NULL DEFAULT 0,
  "EstimatedCost"      NUMERIC(18,2)  NOT NULL DEFAULT 0,
  "TaxRatePercent"     NUMERIC(9,4)   NOT NULL DEFAULT 16,
  "IsComposite"        BOOLEAN        NOT NULL DEFAULT FALSE,
  "PrepMinutes"        INT            NOT NULL DEFAULT 0,
  "ImageUrl"           VARCHAR(500)   NULL,
  "IsDailySuggestion"  BOOLEAN        NOT NULL DEFAULT FALSE,
  "IsAvailable"        BOOLEAN        NOT NULL DEFAULT TRUE,
  "InventoryProductId" BIGINT         NULL,
  "IsActive"           BOOLEAN        NOT NULL DEFAULT TRUE,
  "CreatedAt"          TIMESTAMP      NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"          TIMESTAMP      NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId"    INT            NULL,
  "UpdatedByUserId"    INT            NULL,
  "RowVer"             INT            NOT NULL DEFAULT 1,
  CONSTRAINT "UQ_rest_MenuProduct" UNIQUE ("CompanyId", "BranchId", "ProductCode"),
  CONSTRAINT "FK_rest_MenuProduct_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId"),
  CONSTRAINT "FK_rest_MenuProduct_Branch" FOREIGN KEY ("BranchId") REFERENCES cfg."Branch"("BranchId"),
  CONSTRAINT "FK_rest_MenuProduct_Category" FOREIGN KEY ("MenuCategoryId") REFERENCES rest."MenuCategory"("MenuCategoryId"),
  CONSTRAINT "FK_rest_MenuProduct_InventoryProduct" FOREIGN KEY ("InventoryProductId") REFERENCES master."Product"("ProductId"),
  CONSTRAINT "FK_rest_MenuProduct_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_rest_MenuProduct_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId")
);

CREATE INDEX IF NOT EXISTS "IX_rest_MenuProduct_Search"
  ON rest."MenuProduct" ("CompanyId", "BranchId", "IsActive", "IsAvailable", "ProductCode", "ProductName");

-- ============================================================
-- rest.MenuComponent
-- ============================================================
CREATE TABLE IF NOT EXISTS rest."MenuComponent" (
  "MenuComponentId"  BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "MenuProductId"    BIGINT       NOT NULL,
  "ComponentName"    VARCHAR(120) NOT NULL,
  "IsRequired"       BOOLEAN      NOT NULL DEFAULT FALSE,
  "SortOrder"        INT          NOT NULL DEFAULT 0,
  "IsActive"         BOOLEAN      NOT NULL DEFAULT TRUE,
  "CreatedAt"        TIMESTAMP    NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"        TIMESTAMP    NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  CONSTRAINT "FK_rest_MenuComponent_Product" FOREIGN KEY ("MenuProductId") REFERENCES rest."MenuProduct"("MenuProductId") ON DELETE CASCADE
);

-- ============================================================
-- rest.MenuOption
-- ============================================================
CREATE TABLE IF NOT EXISTS rest."MenuOption" (
  "MenuOptionId"     BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "MenuComponentId"  BIGINT         NOT NULL,
  "OptionName"       VARCHAR(120)   NOT NULL,
  "ExtraPrice"       NUMERIC(18,2)  NOT NULL DEFAULT 0,
  "SortOrder"        INT            NOT NULL DEFAULT 0,
  "IsActive"         BOOLEAN        NOT NULL DEFAULT TRUE,
  "CreatedAt"        TIMESTAMP      NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"        TIMESTAMP      NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  CONSTRAINT "FK_rest_MenuOption_Component" FOREIGN KEY ("MenuComponentId") REFERENCES rest."MenuComponent"("MenuComponentId") ON DELETE CASCADE
);

-- ============================================================
-- rest.MenuRecipe
-- ============================================================
CREATE TABLE IF NOT EXISTS rest."MenuRecipe" (
  "MenuRecipeId"        BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "MenuProductId"       BIGINT         NOT NULL,
  "IngredientProductId" BIGINT         NOT NULL,
  "Quantity"            NUMERIC(18,4)  NOT NULL,
  "UnitCode"            VARCHAR(20)    NULL,
  "Notes"               VARCHAR(200)   NULL,
  "IsActive"            BOOLEAN        NOT NULL DEFAULT TRUE,
  "CreatedAt"           TIMESTAMP      NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"           TIMESTAMP      NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  CONSTRAINT "FK_rest_MenuRecipe_MenuProduct" FOREIGN KEY ("MenuProductId") REFERENCES rest."MenuProduct"("MenuProductId") ON DELETE CASCADE,
  CONSTRAINT "FK_rest_MenuRecipe_Ingredient" FOREIGN KEY ("IngredientProductId") REFERENCES master."Product"("ProductId")
);

-- ============================================================
-- rest.Purchase
-- ============================================================
CREATE TABLE IF NOT EXISTS rest."Purchase" (
  "PurchaseId"       BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"        INT            NOT NULL,
  "BranchId"         INT            NOT NULL,
  "PurchaseNumber"   VARCHAR(30)    NOT NULL,
  "SupplierId"       BIGINT         NULL,
  "PurchaseDate"     TIMESTAMP      NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "Status"           VARCHAR(20)    NOT NULL DEFAULT 'PENDIENTE',
  "SubtotalAmount"   NUMERIC(18,2)  NOT NULL DEFAULT 0,
  "TaxAmount"        NUMERIC(18,2)  NOT NULL DEFAULT 0,
  "TotalAmount"      NUMERIC(18,2)  NOT NULL DEFAULT 0,
  "Notes"            VARCHAR(500)   NULL,
  "CreatedAt"        TIMESTAMP      NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"        TIMESTAMP      NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId"  INT            NULL,
  "UpdatedByUserId"  INT            NULL,
  "RowVer"           INT            NOT NULL DEFAULT 1,
  CONSTRAINT "UQ_rest_Purchase" UNIQUE ("CompanyId", "BranchId", "PurchaseNumber"),
  CONSTRAINT "FK_rest_Purchase_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId"),
  CONSTRAINT "FK_rest_Purchase_Branch" FOREIGN KEY ("BranchId") REFERENCES cfg."Branch"("BranchId"),
  CONSTRAINT "FK_rest_Purchase_Supplier" FOREIGN KEY ("SupplierId") REFERENCES master."Supplier"("SupplierId"),
  CONSTRAINT "FK_rest_Purchase_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_rest_Purchase_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId")
);

CREATE INDEX IF NOT EXISTS "IX_rest_Purchase_Search"
  ON rest."Purchase" ("CompanyId", "BranchId", "PurchaseDate" DESC, "Status");

-- ============================================================
-- rest.PurchaseLine
-- ============================================================
CREATE TABLE IF NOT EXISTS rest."PurchaseLine" (
  "PurchaseLineId"      BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "PurchaseId"          BIGINT         NOT NULL,
  "IngredientProductId" BIGINT         NULL,
  "DescriptionText"     VARCHAR(200)   NOT NULL,
  "Quantity"            NUMERIC(18,4)  NOT NULL,
  "UnitPrice"           NUMERIC(18,2)  NOT NULL,
  "TaxRatePercent"      NUMERIC(9,4)   NOT NULL,
  "SubtotalAmount"      NUMERIC(18,2)  NOT NULL,
  "CreatedAt"           TIMESTAMP      NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"           TIMESTAMP      NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  CONSTRAINT "FK_rest_PurchaseLine_Purchase" FOREIGN KEY ("PurchaseId") REFERENCES rest."Purchase"("PurchaseId") ON DELETE CASCADE,
  CONSTRAINT "FK_rest_PurchaseLine_Ingredient" FOREIGN KEY ("IngredientProductId") REFERENCES master."Product"("ProductId")
);

-- ============================================================
-- hr."PayrollBatch"
-- ============================================================
CREATE TABLE IF NOT EXISTS hr."PayrollBatch" (
  "BatchId"         BIGINT GENERATED ALWAYS AS IDENTITY NOT NULL PRIMARY KEY,
  "CompanyId"       INT NOT NULL,
  "PayrollCode"     VARCHAR(20) NOT NULL,
  "FromDate"        DATE NOT NULL,
  "ToDate"          DATE NOT NULL,
  "Status"          VARCHAR(20) NOT NULL DEFAULT 'DRAFT',
  "Notes"           VARCHAR(500) NULL,
  "CreatedAt"       TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"       TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId" INT NULL,
  "UpdatedByUserId" INT NULL,
  "IsDeleted"       BOOLEAN NOT NULL DEFAULT FALSE,
  "DeletedAt"       TIMESTAMP NULL,
  "DeletedByUserId" INT NULL,
  "RowVer"          INT NOT NULL DEFAULT 1,
  CONSTRAINT "FK_hr_PayrollBatch_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId")
);

-- ============================================================
-- hr."PayrollBatchLine"
-- ============================================================
CREATE TABLE IF NOT EXISTS hr."PayrollBatchLine" (
  "LineId"          BIGINT GENERATED ALWAYS AS IDENTITY NOT NULL PRIMARY KEY,
  "BatchId"         BIGINT NOT NULL,
  "EmployeeId"      BIGINT NULL,
  "EmployeeCode"    VARCHAR(24) NOT NULL,
  "EmployeeName"    VARCHAR(200) NOT NULL,
  "ConceptCode"     VARCHAR(20) NOT NULL,
  "ConceptName"     VARCHAR(100) NOT NULL,
  "ConceptType"     VARCHAR(20) NOT NULL,
  "Quantity"        DECIMAL(18,4) NOT NULL DEFAULT 1,
  "Amount"          DECIMAL(18,2) NOT NULL DEFAULT 0,
  "Total"           DECIMAL(18,2) NOT NULL DEFAULT 0,
  "IsModified"      BOOLEAN NOT NULL DEFAULT FALSE,
  "Notes"           VARCHAR(500) NULL,
  "UpdatedAt"       TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  CONSTRAINT "FK_hr_PayrollBatchLine_Batch" FOREIGN KEY ("BatchId") REFERENCES hr."PayrollBatch"("BatchId") ON DELETE CASCADE
);

-- ============================================================
-- hr."DocumentTemplate"
-- ============================================================
CREATE TABLE IF NOT EXISTS hr."DocumentTemplate" (
  "TemplateId"      BIGINT GENERATED ALWAYS AS IDENTITY NOT NULL PRIMARY KEY,
  "CompanyId"       INT NOT NULL,
  "TemplateCode"    VARCHAR(50) NOT NULL,
  "TemplateName"    VARCHAR(200) NOT NULL,
  "TemplateType"    VARCHAR(30) NOT NULL DEFAULT 'PAYROLL',
  "CountryCode"     CHAR(2) NOT NULL DEFAULT 'VE',
  "PayrollCode"     VARCHAR(20) NULL,
  "ContentMD"       TEXT NOT NULL DEFAULT '',
  "IsDefault"       BOOLEAN NOT NULL DEFAULT FALSE,
  "IsActive"        BOOLEAN NOT NULL DEFAULT TRUE,
  "CreatedAt"       TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"       TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId" INT NULL,
  "UpdatedByUserId" INT NULL,
  "IsDeleted"       BOOLEAN NOT NULL DEFAULT FALSE,
  "DeletedAt"       TIMESTAMP NULL,
  "DeletedByUserId" INT NULL,
  "RowVer"          INT NOT NULL DEFAULT 1,
  CONSTRAINT "UQ_hr_DocumentTemplate" UNIQUE ("CompanyId", "TemplateCode"),
  CONSTRAINT "FK_hr_DocumentTemplate_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId")
);

-- ============================================================
-- SEED DATA
-- ============================================================
-- +goose StatementBegin
DO $$
DECLARE
  v_DefaultCompanyId INT;
  v_DefaultBranchId  INT;
  v_SystemUserId     INT;
  v_BaseCurrency     CHAR(3);
  v_DefaultBankId    BIGINT;
BEGIN
  SELECT "CompanyId" INTO v_DefaultCompanyId
    FROM cfg."Company" WHERE "CompanyCode" = 'DEFAULT' LIMIT 1;
  SELECT "BranchId" INTO v_DefaultBranchId
    FROM cfg."Branch"
    WHERE "CompanyId" = v_DefaultCompanyId AND "BranchCode" = 'MAIN' LIMIT 1;
  SELECT "UserId" INTO v_SystemUserId
    FROM sec."User" WHERE "UserCode" = 'SYSTEM' LIMIT 1;
  SELECT "BaseCurrency" INTO v_BaseCurrency
    FROM cfg."Company" WHERE "CompanyId" = v_DefaultCompanyId LIMIT 1;

  IF v_DefaultCompanyId IS NOT NULL THEN

    -- PayrollType seed
    INSERT INTO hr."PayrollType" ("CompanyId", "PayrollCode", "PayrollName", "IsActive", "CreatedByUserId", "UpdatedByUserId")
    VALUES (v_DefaultCompanyId, 'GENERAL', 'Nomina General', TRUE, v_SystemUserId, v_SystemUserId)
    ON CONFLICT ("CompanyId", "PayrollCode") DO NOTHING;

    -- PayrollConstant seeds
    INSERT INTO hr."PayrollConstant" ("CompanyId", "ConstantCode", "ConstantName", "ConstantValue", "SourceName", "IsActive", "CreatedByUserId", "UpdatedByUserId")
    VALUES (v_DefaultCompanyId, 'SALARIO_MINIMO', 'Salario minimo de referencia', 100, 'DEFAULT', TRUE, v_SystemUserId, v_SystemUserId)
    ON CONFLICT ("CompanyId", "ConstantCode") DO NOTHING;

    INSERT INTO hr."PayrollConstant" ("CompanyId", "ConstantCode", "ConstantName", "ConstantValue", "SourceName", "IsActive", "CreatedByUserId", "UpdatedByUserId")
    VALUES (v_DefaultCompanyId, 'SALARIO_DIARIO', 'Salario diario de referencia', 3.3333, 'DEFAULT', TRUE, v_SystemUserId, v_SystemUserId)
    ON CONFLICT ("CompanyId", "ConstantCode") DO NOTHING;

    -- Bank seed
    INSERT INTO fin."Bank" ("CompanyId", "BankCode", "BankName", "ContactName", "IsActive", "CreatedByUserId", "UpdatedByUserId")
    VALUES (v_DefaultCompanyId, 'BANCO_DEFAULT', 'Banco Default', 'Sistema', TRUE, v_SystemUserId, v_SystemUserId)
    ON CONFLICT ("CompanyId", "BankCode") DO NOTHING;

    SELECT "BankId" INTO v_DefaultBankId
      FROM fin."Bank"
      WHERE "CompanyId" = v_DefaultCompanyId AND "BankCode" = 'BANCO_DEFAULT' LIMIT 1;

    -- BankAccount seed
    IF v_DefaultBankId IS NOT NULL AND v_DefaultBranchId IS NOT NULL THEN
      INSERT INTO fin."BankAccount" (
        "CompanyId", "BranchId", "BankId", "AccountNumber", "AccountName",
        "CurrencyCode", "Balance", "AvailableBalance", "IsActive",
        "CreatedByUserId", "UpdatedByUserId"
      )
      VALUES (
        v_DefaultCompanyId, v_DefaultBranchId, v_DefaultBankId,
        '0000000000', 'Cuenta Principal',
        COALESCE(v_BaseCurrency, 'VES'), 0, 0, TRUE,
        v_SystemUserId, v_SystemUserId
      )
      ON CONFLICT ("CompanyId", "AccountNumber") DO NOTHING;
    END IF;

    -- MenuEnvironment seed
    IF v_DefaultBranchId IS NOT NULL THEN
      INSERT INTO rest."MenuEnvironment" (
        "CompanyId", "BranchId", "EnvironmentCode", "EnvironmentName",
        "ColorHex", "SortOrder", "IsActive", "CreatedByUserId", "UpdatedByUserId"
      )
      VALUES (
        v_DefaultCompanyId, v_DefaultBranchId, 'SALON', 'Salon Principal',
        '#4CAF50', 1, TRUE, v_SystemUserId, v_SystemUserId
      )
      ON CONFLICT ("CompanyId", "BranchId", "EnvironmentCode") DO NOTHING;

      -- MenuCategory seed
      INSERT INTO rest."MenuCategory" (
        "CompanyId", "BranchId", "CategoryCode", "CategoryName",
        "DescriptionText", "ColorHex", "SortOrder", "IsActive",
        "CreatedByUserId", "UpdatedByUserId"
      )
      VALUES (
        v_DefaultCompanyId, v_DefaultBranchId, 'GENERAL', 'General',
        'Categoria general de menu', '#607D8B', 1, TRUE,
        v_SystemUserId, v_SystemUserId
      )
      ON CONFLICT ("CompanyId", "BranchId", "CategoryCode") DO NOTHING;
    END IF;

  END IF;
END $$;
-- +goose StatementEnd

COMMIT;

-- Source: 09_canonical_maestros.sql
-- ============================================================
-- DatqBoxWeb PostgreSQL - 09_canonical_maestros.sql
-- Tablas maestras canonicas: master.*, cfg.* y seed data
-- Fuente: 19_canonical_maestros_and_missing.sql
-- ============================================================

BEGIN;

-- ============================================================
-- SECCION 1: TABLAS CANONICAS EN SCHEMA master
-- ============================================================

-- master.Category (Categorias de productos)
CREATE TABLE IF NOT EXISTS master."Category" (
  "CategoryId"      INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"       INT           NOT NULL DEFAULT 1,
  "CategoryCode"    VARCHAR(20)   NULL,
  "CategoryName"    VARCHAR(100)  NOT NULL,
  "Description"     VARCHAR(500)  NULL,
  "UserCode"        VARCHAR(20)   NULL,
  "IsActive"        BOOLEAN       NOT NULL DEFAULT TRUE,
  "IsDeleted"       BOOLEAN       NOT NULL DEFAULT FALSE,
  "CreatedAt"       TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"       TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId" INT           NULL,
  "UpdatedByUserId" INT           NULL
);

CREATE UNIQUE INDEX IF NOT EXISTS "UQ_Category_CompanyName"
  ON master."Category" ("CompanyId", "CategoryName") WHERE "IsDeleted" = FALSE;

-- master.Brand (Marcas de productos)
CREATE TABLE IF NOT EXISTS master."Brand" (
  "BrandId"         INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"       INT           NOT NULL DEFAULT 1,
  "BrandCode"       VARCHAR(20)   NULL,
  "BrandName"       VARCHAR(100)  NOT NULL,
  "Description"     VARCHAR(500)  NULL,
  "UserCode"        VARCHAR(20)   NULL,
  "IsActive"        BOOLEAN       NOT NULL DEFAULT TRUE,
  "IsDeleted"       BOOLEAN       NOT NULL DEFAULT FALSE,
  "CreatedAt"       TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"       TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId" INT           NULL,
  "UpdatedByUserId" INT           NULL
);

CREATE UNIQUE INDEX IF NOT EXISTS "UQ_Brand_CompanyName"
  ON master."Brand" ("CompanyId", "BrandName") WHERE "IsDeleted" = FALSE;

-- master.Warehouse (Almacenes)
CREATE TABLE IF NOT EXISTS master."Warehouse" (
  "WarehouseId"     INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"       INT           NOT NULL DEFAULT 1,
  "BranchId"        INT           NULL,
  "WarehouseCode"   VARCHAR(20)   NOT NULL,
  "Description"     VARCHAR(200)  NOT NULL,
  "WarehouseType"   VARCHAR(20)   NOT NULL DEFAULT 'PRINCIPAL',
  "AddressLine"     VARCHAR(250)  NULL,
  "IsActive"        BOOLEAN       NOT NULL DEFAULT TRUE,
  "IsDeleted"       BOOLEAN       NOT NULL DEFAULT FALSE,
  "CreatedAt"       TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"       TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId" INT           NULL,
  "UpdatedByUserId" INT           NULL
);

CREATE UNIQUE INDEX IF NOT EXISTS "UQ_Warehouse_CompanyCode"
  ON master."Warehouse" ("CompanyId", "WarehouseCode") WHERE "IsDeleted" = FALSE;

-- master.ProductLine (Lineas de productos)
CREATE TABLE IF NOT EXISTS master."ProductLine" (
  "LineId"          INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"       INT           NOT NULL DEFAULT 1,
  "LineCode"        VARCHAR(20)   NOT NULL,
  "LineName"        VARCHAR(100)  NOT NULL,
  "Description"     VARCHAR(500)  NULL,
  "IsActive"        BOOLEAN       NOT NULL DEFAULT TRUE,
  "IsDeleted"       BOOLEAN       NOT NULL DEFAULT FALSE,
  "CreatedAt"       TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"       TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId" INT           NULL,
  "UpdatedByUserId" INT           NULL
);

-- master.ProductClass (Clases de productos)
CREATE TABLE IF NOT EXISTS master."ProductClass" (
  "ClassId"         INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"       INT           NOT NULL DEFAULT 1,
  "ClassCode"       VARCHAR(20)   NOT NULL,
  "ClassName"       VARCHAR(100)  NOT NULL,
  "Description"     VARCHAR(500)  NULL,
  "IsActive"        BOOLEAN       NOT NULL DEFAULT TRUE,
  "IsDeleted"       BOOLEAN       NOT NULL DEFAULT FALSE,
  "CreatedAt"       TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"       TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId" INT           NULL,
  "UpdatedByUserId" INT           NULL
);

-- master.ProductGroup (Grupos de productos)
CREATE TABLE IF NOT EXISTS master."ProductGroup" (
  "GroupId"         INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"       INT           NOT NULL DEFAULT 1,
  "GroupCode"       VARCHAR(20)   NOT NULL,
  "GroupName"       VARCHAR(100)  NOT NULL,
  "Description"     VARCHAR(500)  NULL,
  "IsActive"        BOOLEAN       NOT NULL DEFAULT TRUE,
  "IsDeleted"       BOOLEAN       NOT NULL DEFAULT FALSE,
  "CreatedAt"       TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"       TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId" INT           NULL,
  "UpdatedByUserId" INT           NULL
);

-- master.ProductType (Tipos de productos)
CREATE TABLE IF NOT EXISTS master."ProductType" (
  "TypeId"          INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"       INT           NOT NULL DEFAULT 1,
  "TypeCode"        VARCHAR(20)   NOT NULL,
  "TypeName"        VARCHAR(100)  NOT NULL,
  "CategoryCode"    VARCHAR(50)   NULL,
  "Description"     VARCHAR(500)  NULL,
  "IsActive"        BOOLEAN       NOT NULL DEFAULT TRUE,
  "IsDeleted"       BOOLEAN       NOT NULL DEFAULT FALSE,
  "CreatedAt"       TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"       TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId" INT           NULL,
  "UpdatedByUserId" INT           NULL
);

-- master.UnitOfMeasure (Unidades de medida)
CREATE TABLE IF NOT EXISTS master."UnitOfMeasure" (
  "UnitId"          INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"       INT           NOT NULL DEFAULT 1,
  "UnitCode"        VARCHAR(20)   NOT NULL,
  "Description"     VARCHAR(100)  NOT NULL,
  "Symbol"          VARCHAR(10)   NULL,
  "IsActive"        BOOLEAN       NOT NULL DEFAULT TRUE,
  "IsDeleted"       BOOLEAN       NOT NULL DEFAULT FALSE,
  "CreatedAt"       TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"       TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId" INT           NULL,
  "UpdatedByUserId" INT           NULL
);

CREATE UNIQUE INDEX IF NOT EXISTS "UQ_UnitOfMeasure_CompanyCode"
  ON master."UnitOfMeasure" ("CompanyId", "UnitCode") WHERE "IsDeleted" = FALSE;

-- master.Seller (Vendedores / Agentes)
CREATE TABLE IF NOT EXISTS master."Seller" (
  "SellerId"        INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"       INT           NOT NULL DEFAULT 1,
  "SellerCode"      VARCHAR(10)   NOT NULL,
  "SellerName"      VARCHAR(120)  NOT NULL,
  "Commission"      NUMERIC(5,2)  NOT NULL DEFAULT 0,
  "Address"         VARCHAR(250)  NULL,
  "Phone"           VARCHAR(60)   NULL,
  "Email"           VARCHAR(150)  NULL,
  "SellerType"      VARCHAR(20)   NOT NULL DEFAULT 'INTERNO',
  "IsActive"        BOOLEAN       NOT NULL DEFAULT TRUE,
  "IsDeleted"       BOOLEAN       NOT NULL DEFAULT FALSE,
  "CreatedAt"       TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"       TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId" INT           NULL,
  "UpdatedByUserId" INT           NULL
);

CREATE UNIQUE INDEX IF NOT EXISTS "UQ_Seller_CompanyCode"
  ON master."Seller" ("CompanyId", "SellerCode") WHERE "IsDeleted" = FALSE;

-- master.CostCenter (Centros de costo)
CREATE TABLE IF NOT EXISTS master."CostCenter" (
  "CostCenterId"    INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"       INT           NOT NULL DEFAULT 1,
  "CostCenterCode"  VARCHAR(20)   NOT NULL,
  "CostCenterName"  VARCHAR(100)  NOT NULL,
  "Description"     VARCHAR(500)  NULL,
  "IsActive"        BOOLEAN       NOT NULL DEFAULT TRUE,
  "IsDeleted"       BOOLEAN       NOT NULL DEFAULT FALSE,
  "CreatedAt"       TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"       TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId" INT           NULL,
  "UpdatedByUserId" INT           NULL
);

-- master.TaxRetention (Retenciones fiscales)
CREATE TABLE IF NOT EXISTS master."TaxRetention" (
  "RetentionId"     INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"       INT           NOT NULL DEFAULT 1,
  "RetentionCode"   VARCHAR(20)   NOT NULL,
  "Description"     VARCHAR(200)  NOT NULL,
  "RetentionType"   VARCHAR(20)   NOT NULL DEFAULT 'ISLR',
  "RetentionRate"   NUMERIC(8,4)  NOT NULL DEFAULT 0,
  "CountryCode"     CHAR(2)       NOT NULL DEFAULT 'VE',
  "IsActive"        BOOLEAN       NOT NULL DEFAULT TRUE,
  "IsDeleted"       BOOLEAN       NOT NULL DEFAULT FALSE,
  "CreatedAt"       TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"       TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId" INT           NULL,
  "UpdatedByUserId" INT           NULL
);

CREATE UNIQUE INDEX IF NOT EXISTS "UQ_TaxRetention_CompanyCode"
  ON master."TaxRetention" ("CompanyId", "RetentionCode") WHERE "IsDeleted" = FALSE;

-- master.InventoryMovement (Movimientos de inventario)
CREATE TABLE IF NOT EXISTS master."InventoryMovement" (
  "MovementId"      BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"       INT            NOT NULL DEFAULT 1,
  "BranchId"        INT            NULL,
  "ProductCode"     VARCHAR(80)    NOT NULL,
  "ProductName"     VARCHAR(250)   NULL,
  "DocumentRef"     VARCHAR(60)    NULL,
  "MovementType"    VARCHAR(20)    NOT NULL DEFAULT 'ENTRADA',
  "MovementDate"    DATE           NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC')::DATE,
  "Quantity"        NUMERIC(18,4)  NOT NULL DEFAULT 0,
  "UnitCost"        NUMERIC(18,4)  NOT NULL DEFAULT 0,
  "TotalCost"       NUMERIC(18,4)  NOT NULL DEFAULT 0,
  "Notes"           VARCHAR(300)   NULL,
  "IsDeleted"       BOOLEAN        NOT NULL DEFAULT FALSE,
  "CreatedAt"       TIMESTAMP      NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"       TIMESTAMP      NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId" INT            NULL,
  "UpdatedByUserId" INT            NULL
);

CREATE INDEX IF NOT EXISTS "IX_InventoryMovement_ProductDate"
  ON master."InventoryMovement" ("ProductCode", "MovementDate" DESC) WHERE "IsDeleted" = FALSE;

-- master.InventoryPeriodSummary (Cierre mensual inventario)
CREATE TABLE IF NOT EXISTS master."InventoryPeriodSummary" (
  "SummaryId"   BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"   INT            NOT NULL DEFAULT 1,
  "Period"      CHAR(6)        NOT NULL,  -- YYYYMM
  "ProductCode" VARCHAR(80)    NOT NULL,
  "OpeningQty"  NUMERIC(18,4)  NOT NULL DEFAULT 0,
  "InboundQty"  NUMERIC(18,4)  NOT NULL DEFAULT 0,
  "OutboundQty" NUMERIC(18,4)  NOT NULL DEFAULT 0,
  "ClosingQty"  NUMERIC(18,4)  NOT NULL DEFAULT 0,
  "SummaryDate" DATE           NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC')::DATE,
  "IsClosed"    BOOLEAN        NOT NULL DEFAULT FALSE,
  "CreatedAt"   TIMESTAMP      NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"   TIMESTAMP      NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC')
);

CREATE UNIQUE INDEX IF NOT EXISTS "UQ_InventoryPeriodSummary_Key"
  ON master."InventoryPeriodSummary" ("CompanyId", "Period", "ProductCode");

-- master.SupplierLine (Lineas de proveedores)
CREATE TABLE IF NOT EXISTS master."SupplierLine" (
  "SupplierLineId" INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"       INT           NOT NULL DEFAULT 1,
  "LineCode"        VARCHAR(20)   NOT NULL,
  "LineName"        VARCHAR(100)  NOT NULL,
  "Description"     VARCHAR(500)  NULL,
  "IsActive"        BOOLEAN       NOT NULL DEFAULT TRUE,
  "IsDeleted"       BOOLEAN       NOT NULL DEFAULT FALSE,
  "CreatedAt"       TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"       TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC')
);

-- ============================================================
-- SECCION 2: TABLAS EN SCHEMA cfg
-- ============================================================

-- cfg.Holiday (Dias feriados)
CREATE TABLE IF NOT EXISTS cfg."Holiday" (
  "HolidayId"    INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CountryCode"  CHAR(2)      NOT NULL DEFAULT 'VE',
  "HolidayDate"  DATE         NOT NULL,
  "HolidayName"  VARCHAR(100) NOT NULL,
  "IsRecurring"  BOOLEAN      NOT NULL DEFAULT FALSE,
  "IsActive"     BOOLEAN      NOT NULL DEFAULT TRUE,
  "CreatedAt"    TIMESTAMP    NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC')
);

-- cfg.DocumentSequence (Correlativos / Secuencias de documentos)
CREATE TABLE IF NOT EXISTS cfg."DocumentSequence" (
  "SequenceId"    INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"     INT          NOT NULL DEFAULT 1,
  "BranchId"      INT          NULL,
  "DocumentType"  VARCHAR(20)  NOT NULL,
  "Prefix"        VARCHAR(10)  NULL,
  "Suffix"        VARCHAR(10)  NULL,
  "CurrentNumber" BIGINT       NOT NULL DEFAULT 1,
  "PaddingLength" INT          NOT NULL DEFAULT 8,
  "IsActive"      BOOLEAN      NOT NULL DEFAULT TRUE,
  "CreatedAt"     TIMESTAMP    NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"     TIMESTAMP    NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC')
);

CREATE UNIQUE INDEX IF NOT EXISTS "UQ_DocumentSequence_NoBranch"
  ON cfg."DocumentSequence" ("CompanyId", "DocumentType")
  WHERE "BranchId" IS NULL;
CREATE UNIQUE INDEX IF NOT EXISTS "UQ_DocumentSequence_Branch"
  ON cfg."DocumentSequence" ("CompanyId", "BranchId", "DocumentType")
  WHERE "BranchId" IS NOT NULL;

-- cfg.Currency (Catalogo de monedas)
CREATE TABLE IF NOT EXISTS cfg."Currency" (
  "CurrencyId"   INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CurrencyCode" CHAR(3)      NOT NULL,
  "CurrencyName" VARCHAR(60)  NOT NULL,
  "Symbol"       VARCHAR(10)  NULL,
  "IsActive"     BOOLEAN      NOT NULL DEFAULT TRUE,
  "CreatedAt"    TIMESTAMP    NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  CONSTRAINT "UQ_Currency_Code" UNIQUE ("CurrencyCode")
);

-- cfg.ReportTemplate (Plantillas de reportes)
CREATE TABLE IF NOT EXISTS cfg."ReportTemplate" (
  "ReportId"    INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"   INT           NOT NULL DEFAULT 1,
  "ReportCode"  VARCHAR(50)   NOT NULL,
  "ReportName"  VARCHAR(150)  NOT NULL,
  "ReportType"  VARCHAR(20)   NOT NULL DEFAULT 'REPORT',
  "QueryText"   TEXT          NULL,
  "Parameters"  TEXT          NULL,
  "IsActive"    BOOLEAN       NOT NULL DEFAULT TRUE,
  "IsDeleted"   BOOLEAN       NOT NULL DEFAULT FALSE,
  "CreatedAt"   TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"   TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC')
);

-- cfg.CompanyProfile (Perfil extendido de empresa)
CREATE TABLE IF NOT EXISTS cfg."CompanyProfile" (
  "ProfileId"   INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"   INT           NOT NULL,
  "Phone"       VARCHAR(60)   NULL,
  "AddressLine" VARCHAR(250)  NULL,
  "NitCode"     VARCHAR(50)   NULL,
  "AltFiscalId" VARCHAR(50)   NULL,
  "WebSite"     VARCHAR(150)  NULL,
  "LogoBase64"  TEXT          NULL,
  "Notes"       VARCHAR(500)  NULL,
  "UpdatedAt"   TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  CONSTRAINT "FK_CompanyProfile_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId")
);

CREATE UNIQUE INDEX IF NOT EXISTS "UQ_CompanyProfile_CompanyId"
  ON cfg."CompanyProfile" ("CompanyId");

-- ============================================================
-- NOTA: public."AccesoUsuarios" eliminada (2026-03-16).
-- Los permisos de modulo deben residir en sec.* o cfg.*.
-- ============================================================
-- Inicializar perfil DEFAULT de empresa
-- ============================================================
INSERT INTO cfg."CompanyProfile" ("CompanyId", "Phone", "AddressLine")
SELECT c."CompanyId", '+58 212 555-0000', 'Direccion Principal'
FROM cfg."Company" c
WHERE c."CompanyCode" = 'DEFAULT'
  AND NOT EXISTS (
    SELECT 1 FROM cfg."CompanyProfile" cp WHERE cp."CompanyId" = c."CompanyId"
  )
LIMIT 1;

-- ============================================================
-- SECCION 4: SEED DATA (datos de referencia)
-- ============================================================
-- +goose StatementBegin
DO $$
DECLARE
  v_CompanyId INT;
  v_BranchId  INT;
BEGIN
  SELECT "CompanyId" INTO v_CompanyId
    FROM cfg."Company" WHERE "CompanyCode" = 'DEFAULT' LIMIT 1;

  IF v_CompanyId IS NULL THEN RETURN; END IF;

  SELECT "BranchId" INTO v_BranchId
    FROM cfg."Branch" WHERE "CompanyId" = v_CompanyId AND "BranchCode" = 'MAIN' LIMIT 1;

  -- Categorias de productos
  IF NOT EXISTS (SELECT 1 FROM master."Category" WHERE "CompanyId" = v_CompanyId) THEN
    INSERT INTO master."Category" ("CompanyId", "CategoryCode", "CategoryName", "Description") VALUES
      (v_CompanyId, 'PROD',    'Productos',         'Articulos de venta general'),
      (v_CompanyId, 'SERV',    'Servicios',          'Servicios y honorarios'),
      (v_CompanyId, 'INSUMOS', 'Insumos',            'Materiales de produccion e insumos'),
      (v_CompanyId, 'REPUEST', 'Repuestos',          'Repuestos y piezas de mantenimiento'),
      (v_CompanyId, 'MATERI',  'Materia Prima',      'Materias primas industriales'),
      (v_CompanyId, 'COMIDA',  'Alimentos',          'Productos alimenticios'),
      (v_CompanyId, 'BEBIDA',  'Bebidas',            'Bebidas y refrescos'),
      (v_CompanyId, 'TECNOL',  'Tecnologia',         'Equipos y perifericos tecnologicos'),
      (v_CompanyId, 'OFICI',   'Oficina',            'Articulos de oficina y papeleria'),
      (v_CompanyId, 'LIMPI',   'Limpieza',           'Productos de limpieza e higiene');
  END IF;

  -- Marcas
  IF NOT EXISTS (SELECT 1 FROM master."Brand" WHERE "CompanyId" = v_CompanyId) THEN
    INSERT INTO master."Brand" ("CompanyId", "BrandCode", "BrandName", "Description") VALUES
      (v_CompanyId, 'GEN',    'Generico',       'Marca generica sin especificar'),
      (v_CompanyId, 'PROPI',  'Marca Propia',   'Productos con marca de la empresa'),
      (v_CompanyId, 'IMPORT', 'Importado',      'Productos importados');
  END IF;

  -- Almacenes
  IF NOT EXISTS (SELECT 1 FROM master."Warehouse" WHERE "CompanyId" = v_CompanyId) THEN
    INSERT INTO master."Warehouse" ("CompanyId", "BranchId", "WarehouseCode", "Description", "WarehouseType") VALUES
      (v_CompanyId, v_BranchId, 'PRINCIPAL', 'Almacen Principal',              'PRINCIPAL'),
      (v_CompanyId, v_BranchId, 'SERVICIO',  'Almacen Servicio',               'SERVICIO'),
      (v_CompanyId, v_BranchId, 'PLANTA',    'Almacen Planta',                 'PLANTA'),
      (v_CompanyId, v_BranchId, 'CONSIG',    'Almacen Consignacion',           'CONSIGNACION'),
      (v_CompanyId, v_BranchId, 'AVERIA',    'Almacen Averias/Devoluciones',   'AVERIA');
  END IF;

  -- Lineas de productos
  IF NOT EXISTS (SELECT 1 FROM master."ProductLine" WHERE "CompanyId" = v_CompanyId) THEN
    INSERT INTO master."ProductLine" ("CompanyId", "LineCode", "LineName") VALUES
      (v_CompanyId, 'LIN-A', 'Linea A - Premium'),
      (v_CompanyId, 'LIN-B', 'Linea B - Estandar'),
      (v_CompanyId, 'LIN-C', 'Linea C - Economica'),
      (v_CompanyId, 'LIN-S', 'Linea Servicios'),
      (v_CompanyId, 'LIN-I', 'Linea Importados');
  END IF;

  -- Clases de productos
  IF NOT EXISTS (SELECT 1 FROM master."ProductClass" WHERE "CompanyId" = v_CompanyId) THEN
    INSERT INTO master."ProductClass" ("CompanyId", "ClassCode", "ClassName") VALUES
      (v_CompanyId, 'CL-CONS', 'Consumible'),
      (v_CompanyId, 'CL-DURA', 'Durable'),
      (v_CompanyId, 'CL-SERV', 'Servicio Tecnico'),
      (v_CompanyId, 'CL-PROM', 'Promocional'),
      (v_CompanyId, 'CL-ACTF', 'Activo Fijo');
  END IF;

  -- Grupos de productos
  IF NOT EXISTS (SELECT 1 FROM master."ProductGroup" WHERE "CompanyId" = v_CompanyId) THEN
    INSERT INTO master."ProductGroup" ("CompanyId", "GroupCode", "GroupName") VALUES
      (v_CompanyId, 'GR-01', 'Grupo Ventas Directas'),
      (v_CompanyId, 'GR-02', 'Grupo Distribucion'),
      (v_CompanyId, 'GR-03', 'Grupo Exportacion'),
      (v_CompanyId, 'GR-04', 'Grupo Uso Interno');
  END IF;

  -- Tipos de productos
  IF NOT EXISTS (SELECT 1 FROM master."ProductType" WHERE "CompanyId" = v_CompanyId) THEN
    INSERT INTO master."ProductType" ("CompanyId", "TypeCode", "TypeName", "CategoryCode") VALUES
      (v_CompanyId, 'TIP-FIN', 'Producto Terminado',   NULL),
      (v_CompanyId, 'TIP-SEM', 'Semielaborado',        NULL),
      (v_CompanyId, 'TIP-INS', 'Insumo/Materia Prima', 'INSUMOS'),
      (v_CompanyId, 'TIP-SER', 'Servicio',             'SERV'),
      (v_CompanyId, 'TIP-REP', 'Repuesto',             'REPUEST');
  END IF;

  -- Unidades de medida
  IF NOT EXISTS (SELECT 1 FROM master."UnitOfMeasure" WHERE "CompanyId" = v_CompanyId) THEN
    INSERT INTO master."UnitOfMeasure" ("CompanyId", "UnitCode", "Description", "Symbol") VALUES
      (v_CompanyId, 'UND',  'Unidad',            'und'),
      (v_CompanyId, 'KG',   'Kilogramo',         'kg'),
      (v_CompanyId, 'GR',   'Gramo',             'gr'),
      (v_CompanyId, 'LT',   'Litro',             'lt'),
      (v_CompanyId, 'ML',   'Mililitro',         'ml'),
      (v_CompanyId, 'MT',   'Metro',             'm'),
      (v_CompanyId, 'CM',   'Centimetro',        'cm'),
      (v_CompanyId, 'PAQ',  'Paquete',           'paq'),
      (v_CompanyId, 'CAJA', 'Caja',              'caja'),
      (v_CompanyId, 'DOC',  'Docena',            'doc'),
      (v_CompanyId, 'HRS',  'Horas',             'hrs'),
      (v_CompanyId, 'DIA',  'Dia',               'dia'),
      (v_CompanyId, 'SER',  'Servicio (global)', 'srv');
  END IF;

  -- Vendedores
  IF NOT EXISTS (SELECT 1 FROM master."Seller" WHERE "CompanyId" = v_CompanyId) THEN
    INSERT INTO master."Seller" ("CompanyId", "SellerCode", "SellerName", "Commission", "SellerType", "IsActive") VALUES
      (v_CompanyId, 'V001', 'Vendedor General',     2.00, 'INTERNO', TRUE),
      (v_CompanyId, 'V002', 'Ventas Corporativas',  3.50, 'INTERNO', TRUE),
      (v_CompanyId, 'V003', 'Canal Distribucion',   5.00, 'EXTERNO', TRUE),
      (v_CompanyId, 'SHOW', 'Tienda / Mostrador',   0.00, 'MOSTRADOR', TRUE);
  END IF;

  -- Centros de costo
  IF NOT EXISTS (SELECT 1 FROM master."CostCenter" WHERE "CompanyId" = v_CompanyId) THEN
    INSERT INTO master."CostCenter" ("CompanyId", "CostCenterCode", "CostCenterName") VALUES
      (v_CompanyId, 'CC-ADM', 'Administracion'),
      (v_CompanyId, 'CC-VEN', 'Ventas y Comercial'),
      (v_CompanyId, 'CC-OPE', 'Operaciones'),
      (v_CompanyId, 'CC-FIN', 'Finanzas'),
      (v_CompanyId, 'CC-LOG', 'Logistica y Almacen'),
      (v_CompanyId, 'CC-TIC', 'Tecnologia e Informatica'),
      (v_CompanyId, 'CC-RRH', 'Recursos Humanos');
  END IF;

  -- Retenciones fiscales
  IF NOT EXISTS (SELECT 1 FROM master."TaxRetention" WHERE "CompanyId" = v_CompanyId) THEN
    INSERT INTO master."TaxRetention" ("CompanyId", "RetentionCode", "Description", "RetentionType", "RetentionRate", "CountryCode") VALUES
      (v_CompanyId, 'ISLR-1',   'ISLR Servicios Profesionales 3%',   'ISLR',      3.0000, 'VE'),
      (v_CompanyId, 'ISLR-2',   'ISLR Honorarios Profesionales 5%',  'ISLR',      5.0000, 'VE'),
      (v_CompanyId, 'ISLR-3',   'ISLR Actividades Comerciales 2%',   'ISLR',      2.0000, 'VE'),
      (v_CompanyId, 'IVA-75',   'Retencion IVA 75%',                 'IVA',      75.0000, 'VE'),
      (v_CompanyId, 'IVA-100',  'Retencion IVA 100%',                'IVA',     100.0000, 'VE'),
      (v_CompanyId, 'MUN-1',    'Impuesto Municipal Actividad 1%',   'MUNICIPAL',  1.0000, 'VE'),
      (v_CompanyId, 'MUN-2',    'Impuesto Municipal Actividad 2%',   'MUNICIPAL',  2.0000, 'VE');
  END IF;

  -- Monedas
  IF NOT EXISTS (SELECT 1 FROM cfg."Currency") THEN
    INSERT INTO cfg."Currency" ("CurrencyCode", "CurrencyName", "Symbol") VALUES
      ('VES', 'Bolivar Soberano',      'Bs.S'),
      ('USD', 'Dolar Estadounidense',  '$'),
      ('EUR', 'Euro',                  'E'),
      ('COP', 'Peso Colombiano',       '$'),
      ('PEN', 'Sol Peruano',           'S/.');
  END IF;

  -- Correlativos de documentos
  IF NOT EXISTS (SELECT 1 FROM cfg."DocumentSequence" WHERE "CompanyId" = v_CompanyId) THEN
    INSERT INTO cfg."DocumentSequence" ("CompanyId", "BranchId", "DocumentType", "Prefix", "CurrentNumber", "PaddingLength") VALUES
      (v_CompanyId, v_BranchId, 'FACT',     'FAC', 1, 8),
      (v_CompanyId, v_BranchId, 'PEDIDO',   'PED', 1, 8),
      (v_CompanyId, v_BranchId, 'COTIZ',    'COT', 1, 8),
      (v_CompanyId, v_BranchId, 'PRESUP',   'PRE', 1, 8),
      (v_CompanyId, v_BranchId, 'NOTACRED', 'NCA', 1, 8),
      (v_CompanyId, v_BranchId, 'NOTADEB',  'NDE', 1, 8),
      (v_CompanyId, v_BranchId, 'NOTA_ENT', 'NEN', 1, 8),
      (v_CompanyId, v_BranchId, 'COMPRA',   'COM', 1, 8),
      (v_CompanyId, v_BranchId, 'ORDEN',    'ORC', 1, 8);
  END IF;

  -- Feriados Venezuela 2026
  IF NOT EXISTS (SELECT 1 FROM cfg."Holiday" WHERE "CountryCode" = 'VE') THEN
    INSERT INTO cfg."Holiday" ("CountryCode", "HolidayDate", "HolidayName", "IsRecurring") VALUES
      ('VE', '2026-01-01', 'Anio Nuevo',                        TRUE),
      ('VE', '2026-02-16', 'Lunes de Carnaval',                 FALSE),
      ('VE', '2026-02-17', 'Martes de Carnaval',                FALSE),
      ('VE', '2026-04-02', 'Jueves Santo',                      FALSE),
      ('VE', '2026-04-03', 'Viernes Santo',                     FALSE),
      ('VE', '2026-04-19', 'Declaracion de Independencia',      TRUE),
      ('VE', '2026-05-01', 'Dia del Trabajador',                TRUE),
      ('VE', '2026-06-24', 'Batalla de Carabobo',               TRUE),
      ('VE', '2026-07-05', 'Dia de la Independencia',           TRUE),
      ('VE', '2026-07-24', 'Natalicio de Simon Bolivar',        TRUE),
      ('VE', '2026-10-12', 'Dia de la Resistencia Indigena',    TRUE),
      ('VE', '2026-12-24', 'Nochebuena',                        TRUE),
      ('VE', '2026-12-25', 'Navidad',                           TRUE),
      ('VE', '2026-12-31', 'Fin de Anio',                       TRUE);
  END IF;

  -- NOTA: Seed de AccesoUsuarios eliminado (2026-03-16).
  -- La tabla public."AccesoUsuarios" fue removida. Los permisos
  -- de modulo deben gestionarse en sec.* o cfg.*.

END $$;
-- +goose StatementEnd

COMMIT;

-- Source: 10_canonical_documents.sql
-- ============================================================
-- DatqBoxWeb PostgreSQL - 10_canonical_documents.sql
-- Limpieza de tablas legacy dbo.Documentos*,
-- creacion de sec."UserModuleAccess" y vista de compatibilidad
-- Fuente: 21_canonical_document_tables.sql
-- ============================================================

BEGIN;

-- ============================================================
-- SECCION 1: LIMPIEZA DE TABLAS public."Documentos*" LEGACY
-- En PG, si existen como tablas fisicas, se eliminan
-- (reemplazadas por doc.*)
-- ============================================================

-- Solo eliminar si existen como tablas (no vistas)
-- Usa DO block para ignorar si el objeto existe como vista en lugar de tabla
-- +goose StatementBegin
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = 'public' AND table_name = 'DocumentosVentaDetalle' AND table_type = 'BASE TABLE'
    ) THEN
        DROP TABLE public."DocumentosVentaDetalle" CASCADE;
    END IF;
    IF EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = 'public' AND table_name = 'DocumentosVentaPago' AND table_type = 'BASE TABLE'
    ) THEN
        DROP TABLE public."DocumentosVentaPago" CASCADE;
    END IF;
    IF EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = 'public' AND table_name = 'DocumentosVenta' AND table_type = 'BASE TABLE'
    ) THEN
        DROP TABLE public."DocumentosVenta" CASCADE;
    END IF;
    IF EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = 'public' AND table_name = 'DocumentosCompraDetalle' AND table_type = 'BASE TABLE'
    ) THEN
        DROP TABLE public."DocumentosCompraDetalle" CASCADE;
    END IF;
    IF EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = 'public' AND table_name = 'DocumentosCompraPago' AND table_type = 'BASE TABLE'
    ) THEN
        DROP TABLE public."DocumentosCompraPago" CASCADE;
    END IF;
    IF EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = 'public' AND table_name = 'DocumentosCompra' AND table_type = 'BASE TABLE'
    ) THEN
        DROP TABLE public."DocumentosCompra" CASCADE;
    END IF;
END $$;
-- +goose StatementEnd

-- ============================================================
-- SECCION 2: sec."UserModuleAccess" (permisos de modulos)
-- ============================================================

CREATE TABLE IF NOT EXISTS sec."UserModuleAccess" (
  "AccessId"    INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "UserCode"    VARCHAR(20)  NOT NULL,
  "ModuleCode"  VARCHAR(60)  NOT NULL,
  "IsAllowed"   BOOLEAN      NOT NULL DEFAULT TRUE,
  "CreatedAt"   TIMESTAMP    NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"   TIMESTAMP    NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  CONSTRAINT "UQ_UserModuleAccess" UNIQUE ("UserCode", "ModuleCode")
);

-- ============================================================
-- Migrar datos de public."AccesoUsuarios" (tabla) -> sec."UserModuleAccess"
-- Solo si public."AccesoUsuarios" existe como tabla
-- ============================================================
-- +goose StatementBegin
DO $$
BEGIN
  -- Verificar si "AccesoUsuarios" existe como tabla (no vista)
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public'
      AND table_name = 'AccesoUsuarios'
      AND table_type = 'BASE TABLE'
  ) THEN
    INSERT INTO sec."UserModuleAccess" ("UserCode", "ModuleCode", "IsAllowed", "CreatedAt", "UpdatedAt")
    SELECT "Cod_Usuario", "Modulo", "Permitido", (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
    FROM public."AccesoUsuarios" a
    WHERE NOT EXISTS (
      SELECT 1 FROM sec."UserModuleAccess" m
      WHERE m."UserCode" = a."Cod_Usuario" AND m."ModuleCode" = a."Modulo"
    );

    DROP TABLE public."AccesoUsuarios";
  END IF;
END $$;
-- +goose StatementEnd

-- ============================================================
-- Vista de compatibilidad: public."AccesoUsuarios" -> sec."UserModuleAccess"
-- ============================================================
CREATE OR REPLACE VIEW public."AccesoUsuarios" AS
  SELECT
    "UserCode"   AS "Cod_Usuario",
    "ModuleCode" AS "Modulo",
    "IsAllowed"  AS "Permitido",
    "CreatedAt",
    "UpdatedAt"
  FROM sec."UserModuleAccess";

COMMIT;

-- Source: 11_canonical_usuarios_fiscal.sql
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
-- +goose StatementBegin
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
-- +goose StatementEnd

-- ============================================================
-- SECCION 2: MIGRAR DATOS public."Usuarios" -> sec."User"
-- Convertir MERGE -> INSERT ... ON CONFLICT DO UPDATE
-- ============================================================
-- +goose StatementBegin
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
-- +goose StatementEnd

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
-- +goose StatementBegin
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
-- +goose StatementEnd

COMMIT;

-- Source: 12_payment_ecommerce.sql
-- ============================================================
-- DatqBoxWeb PostgreSQL - 12_payment_ecommerce.sql
-- Payment gateway + E-commerce tables
-- ============================================================

BEGIN;

-- Crear schemas si no existen
CREATE SCHEMA IF NOT EXISTS pay;
CREATE SCHEMA IF NOT EXISTS store;

-- ============================================================
-- PAYMENT GATEWAY TABLES (pay.*)
-- ============================================================

-- ============================================================
-- 1. pay."PaymentMethods" (catalogo global de formas de pago)
-- ============================================================
CREATE TABLE IF NOT EXISTS pay."PaymentMethods" (
  "Id"              INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "Code"            VARCHAR(30)  NOT NULL,
  "Name"            VARCHAR(100) NOT NULL,
  "Category"        VARCHAR(30)  NOT NULL,
  "CountryCode"     CHAR(2)      NULL,
  "IconName"        VARCHAR(50)  NULL,
  "RequiresGateway" BOOLEAN      DEFAULT FALSE,
  "IsActive"        BOOLEAN      DEFAULT TRUE,
  "SortOrder"       INT          DEFAULT 0,
  "CreatedAt"       TIMESTAMP    DEFAULT (NOW() AT TIME ZONE 'UTC'),
  CONSTRAINT "UQ_PayMethod" UNIQUE ("Code", "CountryCode")
);

-- ============================================================
-- 2. pay."PaymentProviders" (Mercantil, Stripe, Binance, etc.)
-- ============================================================
CREATE TABLE IF NOT EXISTS pay."PaymentProviders" (
  "Id"              INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "Code"            VARCHAR(30)  NOT NULL UNIQUE,
  "Name"            VARCHAR(150) NOT NULL,
  "CountryCode"     CHAR(2)      NULL,
  "ProviderType"    VARCHAR(30)  NOT NULL,
  "BaseUrlSandbox"  VARCHAR(500) NULL,
  "BaseUrlProd"     VARCHAR(500) NULL,
  "AuthType"        VARCHAR(30)  NULL,
  "DocsUrl"         VARCHAR(500) NULL,
  "LogoUrl"         VARCHAR(500) NULL,
  "IsActive"        BOOLEAN      DEFAULT TRUE,
  "CreatedAt"       TIMESTAMP    DEFAULT (NOW() AT TIME ZONE 'UTC')
);

-- ============================================================
-- 3. pay."ProviderCapabilities"
-- ============================================================
CREATE TABLE IF NOT EXISTS pay."ProviderCapabilities" (
  "Id"              INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "ProviderId"      INT          NOT NULL REFERENCES pay."PaymentProviders"("Id"),
  "Capability"      VARCHAR(50)  NOT NULL,
  "PaymentMethod"   VARCHAR(30)  NULL,
  "EndpointPath"    VARCHAR(200) NULL,
  "HttpMethod"      VARCHAR(10)  DEFAULT 'POST',
  "IsActive"        BOOLEAN      DEFAULT TRUE,
  CONSTRAINT "UQ_ProvCap" UNIQUE ("ProviderId", "Capability", "PaymentMethod")
);

-- ============================================================
-- 4. pay."CompanyPaymentConfig"
-- ============================================================
CREATE TABLE IF NOT EXISTS pay."CompanyPaymentConfig" (
  "Id"              INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "EmpresaId"       INT          NOT NULL,
  "SucursalId"      INT          NOT NULL DEFAULT 0,
  "CountryCode"     CHAR(2)      NOT NULL,
  "ProviderId"      INT          NOT NULL REFERENCES pay."PaymentProviders"("Id"),
  "Environment"     VARCHAR(10)  DEFAULT 'sandbox',
  "ClientId"        VARCHAR(500) NULL,
  "ClientSecret"    VARCHAR(500) NULL,
  "MerchantId"      VARCHAR(100) NULL,
  "TerminalId"      VARCHAR(100) NULL,
  "IntegratorId"    VARCHAR(50)  NULL,
  "CertificatePath" VARCHAR(500) NULL,
  "ExtraConfig"     TEXT         NULL,
  "AutoCapture"     BOOLEAN      DEFAULT TRUE,
  "AllowRefunds"    BOOLEAN      DEFAULT TRUE,
  "MaxRefundDays"   INT          DEFAULT 30,
  "IsActive"        BOOLEAN      DEFAULT TRUE,
  "CreatedAt"       TIMESTAMP    DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"       TIMESTAMP    DEFAULT (NOW() AT TIME ZONE 'UTC'),
  CONSTRAINT "UQ_CompanyPayConfig" UNIQUE ("EmpresaId", "SucursalId", "ProviderId")
);

-- ============================================================
-- 5. pay."AcceptedPaymentMethods"
-- ============================================================
CREATE TABLE IF NOT EXISTS pay."AcceptedPaymentMethods" (
  "Id"                  INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "EmpresaId"           INT            NOT NULL,
  "SucursalId"          INT            NOT NULL DEFAULT 0,
  "PaymentMethodId"     INT            NOT NULL REFERENCES pay."PaymentMethods"("Id"),
  "ProviderId"          INT            NULL REFERENCES pay."PaymentProviders"("Id"),
  "AppliesToPOS"        BOOLEAN        DEFAULT TRUE,
  "AppliesToWeb"        BOOLEAN        DEFAULT TRUE,
  "AppliesToRestaurant" BOOLEAN        DEFAULT TRUE,
  "MinAmount"           NUMERIC(18,2)  NULL,
  "MaxAmount"           NUMERIC(18,2)  NULL,
  "CommissionPct"       NUMERIC(5,4)   NULL,
  "CommissionFixed"     NUMERIC(18,2)  NULL,
  "IsActive"            BOOLEAN        DEFAULT TRUE,
  "SortOrder"           INT            DEFAULT 0,
  CONSTRAINT "UQ_AcceptedPM" UNIQUE ("EmpresaId", "SucursalId", "PaymentMethodId", "ProviderId")
);

-- ============================================================
-- 6. pay."Transactions" (log de transacciones)
-- ============================================================
CREATE TABLE IF NOT EXISTS pay."Transactions" (
  "Id"                BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "TransactionUUID"   VARCHAR(36)    NOT NULL UNIQUE,
  "EmpresaId"         INT            NOT NULL,
  "SucursalId"        INT            NOT NULL DEFAULT 0,
  "SourceType"        VARCHAR(30)    NOT NULL,
  "SourceId"          INT            NULL,
  "SourceNumber"      VARCHAR(50)    NULL,
  "PaymentMethodCode" VARCHAR(30)    NOT NULL,
  "ProviderId"        INT            NULL REFERENCES pay."PaymentProviders"("Id"),
  "Currency"          VARCHAR(3)     NOT NULL,
  "Amount"            NUMERIC(18,2)  NOT NULL,
  "CommissionAmount"  NUMERIC(18,2)  NULL,
  "NetAmount"         NUMERIC(18,2)  NULL,
  "ExchangeRate"      NUMERIC(18,6)  NULL,
  "AmountInBase"      NUMERIC(18,2)  NULL,
  "TrxType"           VARCHAR(20)    NOT NULL,
  "Status"            VARCHAR(20)    NOT NULL DEFAULT 'PENDING',
  "GatewayTrxId"      VARCHAR(100)   NULL,
  "GatewayAuthCode"   VARCHAR(50)    NULL,
  "GatewayResponse"   TEXT           NULL,
  "GatewayMessage"    VARCHAR(500)   NULL,
  "CardLastFour"      VARCHAR(4)     NULL,
  "CardBrand"         VARCHAR(20)    NULL,
  "MobileNumber"      VARCHAR(20)    NULL,
  "BankCode"          VARCHAR(10)    NULL,
  "PaymentRef"        VARCHAR(50)    NULL,
  "IsReconciled"      BOOLEAN        DEFAULT FALSE,
  "ReconciledAt"      TIMESTAMP      NULL,
  "ReconciliationId"  BIGINT         NULL,
  "StationId"         VARCHAR(50)    NULL,
  "CashierId"         VARCHAR(20)    NULL,
  "IpAddress"         VARCHAR(45)    NULL,
  "UserAgent"         VARCHAR(500)   NULL,
  "Notes"             VARCHAR(500)   NULL,
  "CreatedAt"         TIMESTAMP      DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"         TIMESTAMP      DEFAULT (NOW() AT TIME ZONE 'UTC')
);

CREATE INDEX IF NOT EXISTS "IX_PayTrx_Source"
  ON pay."Transactions" ("SourceType", "SourceId");
CREATE INDEX IF NOT EXISTS "IX_PayTrx_Status"
  ON pay."Transactions" ("Status", "CreatedAt");
CREATE INDEX IF NOT EXISTS "IX_PayTrx_Recon"
  ON pay."Transactions" ("IsReconciled", "ProviderId");

-- ============================================================
-- 7. pay."ReconciliationBatches"
-- ============================================================
CREATE TABLE IF NOT EXISTS pay."ReconciliationBatches" (
  "Id"                BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "EmpresaId"         INT            NOT NULL,
  "ProviderId"        INT            NOT NULL REFERENCES pay."PaymentProviders"("Id"),
  "DateFrom"          DATE           NOT NULL,
  "DateTo"            DATE           NOT NULL,
  "TotalTransactions" INT            DEFAULT 0,
  "TotalAmount"       NUMERIC(18,2)  DEFAULT 0,
  "MatchedCount"      INT            DEFAULT 0,
  "UnmatchedCount"    INT            DEFAULT 0,
  "Status"            VARCHAR(20)    DEFAULT 'PENDING',
  "ResultJson"        TEXT           NULL,
  "CreatedAt"         TIMESTAMP      DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CompletedAt"       TIMESTAMP      NULL,
  "UserId"            VARCHAR(20)    NULL
);

-- ============================================================
-- 8. pay."CardReaderDevices"
-- ============================================================
CREATE TABLE IF NOT EXISTS pay."CardReaderDevices" (
  "Id"               INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "EmpresaId"        INT          NOT NULL,
  "SucursalId"       INT          NOT NULL DEFAULT 0,
  "StationId"        VARCHAR(50)  NOT NULL,
  "DeviceName"       VARCHAR(100) NOT NULL,
  "DeviceType"       VARCHAR(30)  NOT NULL,
  "ConnectionType"   VARCHAR(30)  NOT NULL,
  "ConnectionConfig" VARCHAR(500) NULL,
  "ProviderId"       INT          NULL REFERENCES pay."PaymentProviders"("Id"),
  "IsActive"         BOOLEAN      DEFAULT TRUE,
  "LastSeenAt"       TIMESTAMP    NULL,
  "CreatedAt"        TIMESTAMP    DEFAULT (NOW() AT TIME ZONE 'UTC')
);

-- ============================================================
-- E-COMMERCE TABLES (store.*)
-- ============================================================

-- ============================================================
-- 9. store."ProductReview" (resenas de productos)
-- ============================================================
CREATE TABLE IF NOT EXISTS store."ProductReview" (
  "ReviewId"      INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"     INT          NOT NULL DEFAULT 1,
  "ProductCode"   VARCHAR(80)  NOT NULL,
  "Rating"        INT          NOT NULL CHECK ("Rating" BETWEEN 1 AND 5),
  "Title"         VARCHAR(200) NULL,
  "Comment"       VARCHAR(2000) NOT NULL,
  "ReviewerName"  VARCHAR(200) NOT NULL DEFAULT 'Cliente',
  "ReviewerEmail" VARCHAR(150) NULL,
  "IsVerified"    BOOLEAN      NOT NULL DEFAULT FALSE,
  "IsApproved"    BOOLEAN      NOT NULL DEFAULT TRUE,
  "IsDeleted"     BOOLEAN      NOT NULL DEFAULT FALSE,
  "CreatedAt"     TIMESTAMP    NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC')
);

CREATE INDEX IF NOT EXISTS "IX_ProductReview_Product"
  ON store."ProductReview" ("CompanyId", "ProductCode", "IsDeleted", "IsApproved");

-- ============================================================
-- 10. store."ProductHighlight" (bullets "Acerca de este articulo")
-- ============================================================
CREATE TABLE IF NOT EXISTS store."ProductHighlight" (
  "HighlightId"   INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"     INT          NOT NULL DEFAULT 1,
  "ProductCode"   VARCHAR(80)  NOT NULL,
  "SortOrder"     INT          NOT NULL DEFAULT 0,
  "HighlightText" VARCHAR(500) NOT NULL,
  "IsActive"      BOOLEAN      NOT NULL DEFAULT TRUE,
  "CreatedAt"     TIMESTAMP    NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC')
);

CREATE INDEX IF NOT EXISTS "IX_ProductHighlight_Product"
  ON store."ProductHighlight" ("CompanyId", "ProductCode", "IsActive");

-- ============================================================
-- 11. store."ProductSpec" (especificaciones tecnicas key-value)
-- ============================================================
CREATE TABLE IF NOT EXISTS store."ProductSpec" (
  "SpecId"       INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"    INT          NOT NULL DEFAULT 1,
  "ProductCode"  VARCHAR(80)  NOT NULL,
  "SpecGroup"    VARCHAR(100) NOT NULL DEFAULT 'General',
  "SpecKey"      VARCHAR(100) NOT NULL,
  "SpecValue"    VARCHAR(500) NOT NULL,
  "SortOrder"    INT          NOT NULL DEFAULT 0,
  "IsActive"     BOOLEAN      NOT NULL DEFAULT TRUE,
  "CreatedAt"    TIMESTAMP    NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC')
);

CREATE INDEX IF NOT EXISTS "IX_ProductSpec_Product"
  ON store."ProductSpec" ("CompanyId", "ProductCode", "IsActive");

-- ============================================================
-- SEED: Metodos de pago globales
-- ============================================================
INSERT INTO pay."PaymentMethods" ("Code", "Name", "Category", "CountryCode", "IconName", "RequiresGateway", "IsActive", "SortOrder") VALUES
  ('EFECTIVO',    'Efectivo',                     'CASH',          NULL, 'Payments',           FALSE, TRUE, 1),
  ('TDC',         'Tarjeta de Credito',           'CARD',          NULL, 'CreditCard',         TRUE,  TRUE, 2),
  ('TDD',         'Tarjeta de Debito',            'CARD',          NULL, 'CreditCard',         TRUE,  TRUE, 3),
  ('C2P',         'Pago Movil (C2P)',             'MOBILE',        'VE', 'PhoneIphone',        TRUE,  TRUE, 4),
  ('TRANSFER',    'Transferencia Bancaria',       'TRANSFER',      NULL, 'AccountBalance',     FALSE, TRUE, 5),
  ('ZELLE',       'Zelle',                        'TRANSFER',      'US', 'SwapHoriz',          FALSE, TRUE, 6),
  ('BIZUM',       'Bizum',                        'MOBILE',        'ES', 'PhoneIphone',        TRUE,  TRUE, 7),
  ('CRYPTO_USDT', 'USDT (Tether)',                'CRYPTO',        NULL, 'CurrencyBitcoin',    TRUE,  TRUE, 8),
  ('CRYPTO_BTC',  'Bitcoin',                      'CRYPTO',        NULL, 'CurrencyBitcoin',    TRUE,  TRUE, 9),
  ('BINANCE_PAY', 'Binance Pay',                  'DIGITAL_WALLET',NULL, 'AccountBalanceWallet',TRUE, TRUE, 10),
  ('PAYPAL',      'PayPal',                       'DIGITAL_WALLET',NULL, 'AccountBalanceWallet',TRUE, TRUE, 11),
  ('QR_PAY',      'Pago por QR',                  'QR',            NULL, 'QrCode2',            TRUE,  TRUE, 12),
  ('CHEQUE',      'Cheque',                       'OTHER',         NULL, 'Receipt',            FALSE, TRUE, 13),
  ('CREDITO',     'Credito / Fiado',              'OTHER',         NULL, 'CreditScore',        FALSE, TRUE, 14),
  ('BOTON_WEB',   'Boton de Pagos Web',           'DIGITAL_WALLET','VE', 'Language',           TRUE,  TRUE, 15),
  ('SDI',         'Solicitud Debito Inmediato',   'TRANSFER',      'VE', 'AccountBalance',     TRUE,  TRUE, 16),
  ('REDSYS',      'Redsys (TPV Virtual)',         'CARD',          'ES', 'CreditCard',         TRUE,  TRUE, 17),
  ('VUELTO_C2P',  'Vuelto Pago Movil',           'MOBILE',        'VE', 'PhoneIphone',        TRUE,  TRUE, 18)
ON CONFLICT ("Code", "CountryCode") DO NOTHING;

-- ============================================================
-- SEED: Proveedores de pago
-- ============================================================
INSERT INTO pay."PaymentProviders" ("Code", "Name", "CountryCode", "ProviderType", "BaseUrlSandbox", "BaseUrlProd", "AuthType", "DocsUrl", "LogoUrl") VALUES
  ('MERCANTIL',    'Banco Mercantil - API Payment',          'VE', 'BANK_API',
   'https://apimbu.mercantilbanco.com/mercantil-banco/sandbox/v1',
   'https://apimbu.mercantilbanco.com/mercantil-banco/produccion/v1',
   'API_KEY',
   'https://apiportal.mercantilbanco.com/mercantil-banco/produccion/product', NULL),
  ('BINANCE',      'Binance Pay',                            NULL, 'CRYPTO_EXCHANGE',
   'https://bpay.binanceapi.com', 'https://bpay.binanceapi.com',
   'HMAC', 'https://developers.binance.com/docs/binance-pay', NULL),
  ('STRIPE',       'Stripe',                                 NULL, 'PAYMENT_GATEWAY',
   'https://api.stripe.com', 'https://api.stripe.com',
   'API_KEY', 'https://docs.stripe.com/', NULL),
  ('REDSYS',       'Redsys (Espana)',                        'ES', 'CARD_PROCESSOR',
   'https://sis-t.redsys.es:25443/sis/realizarPago',
   'https://sis.redsys.es/sis/realizarPago',
   'HMAC', 'https://pagosonline.redsys.es/desarrolladores.html', NULL),
  ('BANESCO',      'Banco Banesco - Pago Movil',             'VE', 'BANK_API',
   NULL, NULL, 'API_KEY', NULL, NULL),
  ('PROVINCIAL',   'BBVA Provincial',                        'VE', 'BANK_API',
   NULL, NULL, 'API_KEY', NULL, NULL),
  ('BDV',          'Banco de Venezuela',                     'VE', 'BANK_API',
   NULL, NULL, 'API_KEY', 'https://www.bancodevenezuela.com/', NULL),
  ('BANCA_AMIGA',  'Banca Amiga',                            'VE', 'BANK_API',
   NULL, NULL, 'API_KEY', 'https://www.bancaamiga.com/', NULL),
  ('CAIXABANK',    'CaixaBank (via Redsys)',                 'ES', 'CARD_PROCESSOR',
   'https://sis-t.redsys.es:25443/sis/rest/trataPeticionREST',
   'https://sis.redsys.es/sis/rest/trataPeticionREST',
   'HMAC', 'https://www.caixabank.es/empresa/tpv-virtual.html', NULL),
  ('BBVA_ES',      'BBVA Espana (via Redsys)',               'ES', 'CARD_PROCESSOR',
   'https://sis-t.redsys.es:25443/sis/rest/trataPeticionREST',
   'https://sis.redsys.es/sis/rest/trataPeticionREST',
   'HMAC', 'https://www.bbva.es/empresas/productos/cobros/tpv-virtual.html', NULL),
  ('SANTANDER_ES', 'Banco Santander Espana (via Redsys)',    'ES', 'CARD_PROCESSOR',
   'https://sis-t.redsys.es:25443/sis/rest/trataPeticionREST',
   'https://sis.redsys.es/sis/rest/trataPeticionREST',
   'HMAC', 'https://www.bancosantander.es/empresas/cobros-pagos/tpv', NULL),
  ('SABADELL',     'Banco Sabadell (via Redsys)',            'ES', 'CARD_PROCESSOR',
   'https://sis-t.redsys.es:25443/sis/rest/trataPeticionREST',
   'https://sis.redsys.es/sis/rest/trataPeticionREST',
   'HMAC', 'https://www.bancsabadell.com/cs/Satellite/SabAtl/TPV-virtual/6000002059', NULL),
  ('BANKINTER',    'Bankinter (via Redsys)',                 'ES', 'CARD_PROCESSOR',
   'https://sis-t.redsys.es:25443/sis/rest/trataPeticionREST',
   'https://sis.redsys.es/sis/rest/trataPeticionREST',
   'HMAC', 'https://www.bankinter.com/banca/nav/empresas', NULL)
ON CONFLICT ("Code") DO NOTHING;

-- ============================================================
-- SEED: Capabilities para proveedores
-- ============================================================
-- +goose StatementBegin
DO $$
DECLARE
  v_redsysId    INT;
  v_binanceId   INT;
  v_mercantilId INT;
  v_bankId      INT;
  v_bankCode    VARCHAR(30);
  v_bankCodes   VARCHAR(30)[] := ARRAY['CAIXABANK','BBVA_ES','SANTANDER_ES','SABADELL','BANKINTER'];
BEGIN
  SELECT "Id" INTO v_redsysId FROM pay."PaymentProviders" WHERE "Code" = 'REDSYS';
  SELECT "Id" INTO v_binanceId FROM pay."PaymentProviders" WHERE "Code" = 'BINANCE';
  SELECT "Id" INTO v_mercantilId FROM pay."PaymentProviders" WHERE "Code" = 'MERCANTIL';

  -- Redsys capabilities
  IF v_redsysId IS NOT NULL THEN
    INSERT INTO pay."ProviderCapabilities" ("ProviderId", "Capability", "PaymentMethod", "EndpointPath", "HttpMethod") VALUES
      (v_redsysId, 'SALE',    'TDC',   '/sis/rest/trataPeticionREST', 'POST'),
      (v_redsysId, 'SALE',    'TDD',   '/sis/rest/trataPeticionREST', 'POST'),
      (v_redsysId, 'AUTH',    'TDC',   '/sis/rest/trataPeticionREST', 'POST'),
      (v_redsysId, 'CAPTURE', 'TDC',   '/sis/rest/trataPeticionREST', 'POST'),
      (v_redsysId, 'REFUND',  'TDC',   '/sis/rest/trataPeticionREST', 'POST'),
      (v_redsysId, 'REFUND',  'TDD',   '/sis/rest/trataPeticionREST', 'POST'),
      (v_redsysId, 'VOID',    NULL,    '/sis/rest/trataPeticionREST', 'POST'),
      (v_redsysId, 'SALE',    'BIZUM', '/sis/rest/trataPeticionREST', 'POST')
    ON CONFLICT ("ProviderId", "Capability", "PaymentMethod") DO NOTHING;
  END IF;

  -- Clonar capabilities para cada banco espanol
  FOREACH v_bankCode IN ARRAY v_bankCodes LOOP
    SELECT "Id" INTO v_bankId FROM pay."PaymentProviders" WHERE "Code" = v_bankCode;
    IF v_bankId IS NOT NULL THEN
      INSERT INTO pay."ProviderCapabilities" ("ProviderId", "Capability", "PaymentMethod", "EndpointPath", "HttpMethod") VALUES
        (v_bankId, 'SALE',    'TDC',   '/sis/rest/trataPeticionREST', 'POST'),
        (v_bankId, 'SALE',    'TDD',   '/sis/rest/trataPeticionREST', 'POST'),
        (v_bankId, 'AUTH',    'TDC',   '/sis/rest/trataPeticionREST', 'POST'),
        (v_bankId, 'CAPTURE', 'TDC',   '/sis/rest/trataPeticionREST', 'POST'),
        (v_bankId, 'REFUND',  'TDC',   '/sis/rest/trataPeticionREST', 'POST'),
        (v_bankId, 'REFUND',  'TDD',   '/sis/rest/trataPeticionREST', 'POST'),
        (v_bankId, 'VOID',    NULL,    '/sis/rest/trataPeticionREST', 'POST'),
        (v_bankId, 'SALE',    'BIZUM', '/sis/rest/trataPeticionREST', 'POST')
      ON CONFLICT ("ProviderId", "Capability", "PaymentMethod") DO NOTHING;
    END IF;
  END LOOP;

  -- Binance Pay capabilities
  IF v_binanceId IS NOT NULL THEN
    INSERT INTO pay."ProviderCapabilities" ("ProviderId", "Capability", "PaymentMethod", "EndpointPath", "HttpMethod") VALUES
      (v_binanceId, 'SALE',   'CRYPTO_USDT', '/binancepay/openapi/v2/order',        'POST'),
      (v_binanceId, 'SALE',   'CRYPTO_BTC',  '/binancepay/openapi/v2/order',        'POST'),
      (v_binanceId, 'SALE',   'BINANCE_PAY', '/binancepay/openapi/v2/order',        'POST'),
      (v_binanceId, 'SEARCH', NULL,          '/binancepay/openapi/v2/order/query',  'POST'),
      (v_binanceId, 'VOID',   NULL,          '/binancepay/openapi/v2/order/close',  'POST'),
      (v_binanceId, 'REFUND', NULL,          '/binancepay/openapi/v3/order/refund', 'POST')
    ON CONFLICT ("ProviderId", "Capability", "PaymentMethod") DO NOTHING;
  END IF;

  -- Mercantil capabilities
  IF v_mercantilId IS NOT NULL THEN
    INSERT INTO pay."ProviderCapabilities" ("ProviderId", "Capability", "PaymentMethod", "EndpointPath", "HttpMethod") VALUES
      (v_mercantilId, 'SALE',       'C2P',      '/payment/c2p',             'POST'),
      (v_mercantilId, 'REFUND',     'C2P',      '/payment/c2p',             'POST'),
      (v_mercantilId, 'VOID',       'C2P',      '/payment/c2p',             'POST'),
      (v_mercantilId, 'SCP',        'C2P',      '/mobile-payment/scp',      'POST'),
      (v_mercantilId, 'SEARCH',     'C2P',      '/mobile-payment/search',   'POST'),
      (v_mercantilId, 'AUTH',       'TDD',      '/payment/getauth',         'POST'),
      (v_mercantilId, 'SALE',       'TDC',      '/payment/pay',             'POST'),
      (v_mercantilId, 'SALE',       'TDD',      '/payment/pay',             'POST'),
      (v_mercantilId, 'SEARCH',     'TDC',      '/payment/search',          'POST'),
      (v_mercantilId, 'SEARCH',     'TDD',      '/payment/search',          'POST'),
      (v_mercantilId, 'SEARCH',     'TRANSFER', '/payment/transfer-search', 'POST'),
      (v_mercantilId, 'RECONCILE',  NULL,       '/payment/search',          'POST')
    ON CONFLICT ("ProviderId", "Capability", "PaymentMethod") DO NOTHING;
  END IF;
END $$;
-- +goose StatementEnd

COMMIT;

-- Source: 09_inventory_advanced.sql
-- ============================================================
-- Zentto PostgreSQL - 09_inventory_advanced.sql
-- Schema: inv (Inventario Avanzado)
-- Tablas: Warehouse, WarehouseZone, WarehouseBin, ProductLot,
--         ProductSerial, ProductBinStock, InventoryValuationMethod,
--         InventoryValuationLayer, StockMovement
-- Traducido de SQL Server -> PostgreSQL
-- ============================================================

BEGIN;

CREATE SCHEMA IF NOT EXISTS inv;

-- ============================================================
-- 1. inv."Warehouse"  (Almacenes)
-- ============================================================
CREATE TABLE IF NOT EXISTS inv."Warehouse"(
  "WarehouseId"           BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"             INT          NOT NULL,
  "BranchId"              INT          NOT NULL,
  "WarehouseCode"         VARCHAR(30)  NOT NULL,
  "WarehouseName"         VARCHAR(150) NOT NULL,
  "AddressLine"           VARCHAR(250) NULL,
  "ContactName"           VARCHAR(120) NULL,
  "Phone"                 VARCHAR(40)  NULL,
  "IsActive"              BOOLEAN      NOT NULL DEFAULT TRUE,
  "IsDeleted"             BOOLEAN      NOT NULL DEFAULT FALSE,
  "DeletedAt"             TIMESTAMP    NULL,
  "DeletedByUserId"       INT          NULL,
  "CreatedAt"             TIMESTAMP    NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"             TIMESTAMP    NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId"       INT          NULL,
  "UpdatedByUserId"       INT          NULL,
  "RowVer"                INT          NOT NULL DEFAULT 1,
  CONSTRAINT "FK_inv_Warehouse_Company"   FOREIGN KEY ("CompanyId")       REFERENCES cfg."Company"("CompanyId"),
  CONSTRAINT "FK_inv_Warehouse_Branch"    FOREIGN KEY ("BranchId")        REFERENCES cfg."Branch"("BranchId"),
  CONSTRAINT "FK_inv_Warehouse_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_inv_Warehouse_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_inv_Warehouse_DeletedBy" FOREIGN KEY ("DeletedByUserId") REFERENCES sec."User"("UserId")
);

CREATE UNIQUE INDEX IF NOT EXISTS "UQ_inv_Warehouse_Code"
  ON inv."Warehouse" ("CompanyId", "WarehouseCode")
  WHERE "IsDeleted" = FALSE;

CREATE INDEX IF NOT EXISTS "IX_inv_Warehouse_Company"
  ON inv."Warehouse" ("CompanyId", "IsDeleted", "IsActive");

-- ============================================================
-- 2. inv."WarehouseZone"  (Zonas dentro del almacen)
-- ============================================================
CREATE TABLE IF NOT EXISTS inv."WarehouseZone"(
  "ZoneId"                BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "WarehouseId"           BIGINT       NOT NULL,
  "ZoneCode"              VARCHAR(30)  NOT NULL,
  "ZoneName"              VARCHAR(150) NOT NULL,
  "ZoneType"              VARCHAR(20)  NOT NULL DEFAULT 'STORAGE',
  "Temperature"           VARCHAR(20)  NOT NULL DEFAULT 'AMBIENT',
  "IsActive"              BOOLEAN      NOT NULL DEFAULT TRUE,
  "IsDeleted"             BOOLEAN      NOT NULL DEFAULT FALSE,
  "DeletedAt"             TIMESTAMP    NULL,
  "DeletedByUserId"       INT          NULL,
  "CreatedAt"             TIMESTAMP    NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"             TIMESTAMP    NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId"       INT          NULL,
  "UpdatedByUserId"       INT          NULL,
  "RowVer"                INT          NOT NULL DEFAULT 1,
  CONSTRAINT "CK_inv_WarehouseZone_Type" CHECK ("ZoneType" IN ('RECEIVING', 'STORAGE', 'PICKING', 'SHIPPING', 'QUARANTINE')),
  CONSTRAINT "CK_inv_WarehouseZone_Temp" CHECK ("Temperature" IN ('AMBIENT', 'COLD', 'FROZEN')),
  CONSTRAINT "FK_inv_WarehouseZone_Warehouse" FOREIGN KEY ("WarehouseId")     REFERENCES inv."Warehouse"("WarehouseId"),
  CONSTRAINT "FK_inv_WarehouseZone_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_inv_WarehouseZone_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_inv_WarehouseZone_DeletedBy" FOREIGN KEY ("DeletedByUserId") REFERENCES sec."User"("UserId")
);

CREATE INDEX IF NOT EXISTS "IX_inv_WarehouseZone_Warehouse"
  ON inv."WarehouseZone" ("WarehouseId", "IsDeleted", "IsActive");

-- ============================================================
-- 3. inv."WarehouseBin"  (Ubicaciones â€” estantes, racks)
-- ============================================================
CREATE TABLE IF NOT EXISTS inv."WarehouseBin"(
  "BinId"                 BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "ZoneId"                BIGINT        NOT NULL,
  "BinCode"               VARCHAR(30)   NOT NULL,
  "BinName"               VARCHAR(100)  NULL,
  "MaxWeight"             DECIMAL(18,2) NULL,
  "MaxVolume"             DECIMAL(18,4) NULL,
  "IsActive"              BOOLEAN       NOT NULL DEFAULT TRUE,
  "IsDeleted"             BOOLEAN       NOT NULL DEFAULT FALSE,
  "DeletedAt"             TIMESTAMP     NULL,
  "DeletedByUserId"       INT           NULL,
  "CreatedAt"             TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"             TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId"       INT           NULL,
  "UpdatedByUserId"       INT           NULL,
  "RowVer"                INT           NOT NULL DEFAULT 1,
  CONSTRAINT "FK_inv_WarehouseBin_Zone"      FOREIGN KEY ("ZoneId")          REFERENCES inv."WarehouseZone"("ZoneId"),
  CONSTRAINT "FK_inv_WarehouseBin_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_inv_WarehouseBin_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_inv_WarehouseBin_DeletedBy" FOREIGN KEY ("DeletedByUserId") REFERENCES sec."User"("UserId")
);

CREATE INDEX IF NOT EXISTS "IX_inv_WarehouseBin_Zone"
  ON inv."WarehouseBin" ("ZoneId", "IsDeleted", "IsActive");

-- ============================================================
-- 4. inv."ProductLot"  (Lotes de productos)
-- ============================================================
CREATE TABLE IF NOT EXISTS inv."ProductLot"(
  "LotId"                  BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"              INT           NOT NULL,
  "ProductId"              BIGINT        NOT NULL,
  "LotNumber"              VARCHAR(60)   NOT NULL,
  "ManufactureDate"        DATE          NULL,
  "ExpiryDate"             DATE          NULL,
  "SupplierCode"           VARCHAR(24)   NULL,
  "PurchaseDocumentNumber" VARCHAR(60)   NULL,
  "InitialQuantity"        DECIMAL(18,4) NOT NULL DEFAULT 0,
  "CurrentQuantity"        DECIMAL(18,4) NOT NULL DEFAULT 0,
  "UnitCost"               DECIMAL(18,4) NOT NULL DEFAULT 0,
  "Status"                 VARCHAR(20)   NOT NULL DEFAULT 'ACTIVE',
  "Notes"                  VARCHAR(500)  NULL,
  "IsDeleted"              BOOLEAN       NOT NULL DEFAULT FALSE,
  "DeletedAt"              TIMESTAMP     NULL,
  "DeletedByUserId"        INT           NULL,
  "CreatedAt"              TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"              TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId"        INT           NULL,
  "UpdatedByUserId"        INT           NULL,
  "RowVer"                 INT           NOT NULL DEFAULT 1,
  CONSTRAINT "CK_inv_ProductLot_Status" CHECK ("Status" IN ('ACTIVE', 'DEPLETED', 'EXPIRED', 'QUARANTINE', 'BLOCKED')),
  CONSTRAINT "FK_inv_ProductLot_Company"   FOREIGN KEY ("CompanyId")       REFERENCES cfg."Company"("CompanyId"),
  CONSTRAINT "FK_inv_ProductLot_Product"   FOREIGN KEY ("ProductId")       REFERENCES master."Product"("ProductId"),
  CONSTRAINT "FK_inv_ProductLot_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_inv_ProductLot_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_inv_ProductLot_DeletedBy" FOREIGN KEY ("DeletedByUserId") REFERENCES sec."User"("UserId")
);

CREATE UNIQUE INDEX IF NOT EXISTS "UQ_inv_ProductLot"
  ON inv."ProductLot" ("CompanyId", "ProductId", "LotNumber")
  WHERE "IsDeleted" = FALSE;

CREATE INDEX IF NOT EXISTS "IX_inv_ProductLot_Product"
  ON inv."ProductLot" ("CompanyId", "ProductId", "Status");

CREATE INDEX IF NOT EXISTS "IX_inv_ProductLot_Expiry"
  ON inv."ProductLot" ("CompanyId", "ExpiryDate")
  WHERE "ExpiryDate" IS NOT NULL AND "IsDeleted" = FALSE AND "Status" = 'ACTIVE';

-- ============================================================
-- 5. inv."ProductSerial"  (Seriales individuales)
-- ============================================================
CREATE TABLE IF NOT EXISTS inv."ProductSerial"(
  "SerialId"               BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"              INT          NOT NULL,
  "ProductId"              BIGINT       NOT NULL,
  "LotId"                  BIGINT       NULL,
  "SerialNumber"           VARCHAR(100) NOT NULL,
  "WarehouseId"            BIGINT       NULL,
  "BinId"                  BIGINT       NULL,
  "Status"                 VARCHAR(20)  NOT NULL DEFAULT 'AVAILABLE',
  "PurchaseDocumentNumber" VARCHAR(60)  NULL,
  "SalesDocumentNumber"    VARCHAR(60)  NULL,
  "CustomerId"             BIGINT       NULL,
  "SoldAt"                 TIMESTAMP    NULL,
  "WarrantyExpiry"         DATE         NULL,
  "Notes"                  VARCHAR(500) NULL,
  "IsDeleted"              BOOLEAN      NOT NULL DEFAULT FALSE,
  "DeletedAt"              TIMESTAMP    NULL,
  "DeletedByUserId"        INT          NULL,
  "CreatedAt"              TIMESTAMP    NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"              TIMESTAMP    NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId"        INT          NULL,
  "UpdatedByUserId"        INT          NULL,
  "RowVer"                 INT          NOT NULL DEFAULT 1,
  CONSTRAINT "CK_inv_ProductSerial_Status" CHECK ("Status" IN ('AVAILABLE', 'RESERVED', 'SOLD', 'RETURNED', 'DEFECTIVE', 'SCRAPPED')),
  CONSTRAINT "FK_inv_ProductSerial_Company"   FOREIGN KEY ("CompanyId")       REFERENCES cfg."Company"("CompanyId"),
  CONSTRAINT "FK_inv_ProductSerial_Product"   FOREIGN KEY ("ProductId")       REFERENCES master."Product"("ProductId"),
  CONSTRAINT "FK_inv_ProductSerial_Lot"       FOREIGN KEY ("LotId")           REFERENCES inv."ProductLot"("LotId"),
  CONSTRAINT "FK_inv_ProductSerial_Warehouse" FOREIGN KEY ("WarehouseId")     REFERENCES inv."Warehouse"("WarehouseId"),
  CONSTRAINT "FK_inv_ProductSerial_Bin"       FOREIGN KEY ("BinId")           REFERENCES inv."WarehouseBin"("BinId"),
  CONSTRAINT "FK_inv_ProductSerial_Customer"  FOREIGN KEY ("CustomerId")      REFERENCES master."Customer"("CustomerId"),
  CONSTRAINT "FK_inv_ProductSerial_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_inv_ProductSerial_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_inv_ProductSerial_DeletedBy" FOREIGN KEY ("DeletedByUserId") REFERENCES sec."User"("UserId")
);

CREATE UNIQUE INDEX IF NOT EXISTS "UQ_inv_ProductSerial"
  ON inv."ProductSerial" ("CompanyId", "ProductId", "SerialNumber")
  WHERE "IsDeleted" = FALSE;

CREATE INDEX IF NOT EXISTS "IX_inv_ProductSerial_Product"
  ON inv."ProductSerial" ("CompanyId", "ProductId", "Status");

CREATE INDEX IF NOT EXISTS "IX_inv_ProductSerial_Warehouse"
  ON inv."ProductSerial" ("WarehouseId", "Status")
  WHERE "IsDeleted" = FALSE AND "Status" = 'AVAILABLE';

-- ============================================================
-- 6. inv."ProductBinStock"  (Stock por ubicacion)
-- Nota: QuantityAvailable es columna normal (no computed/generated).
-- Debe ser mantenida por triggers o stored procedures.
-- ============================================================
CREATE TABLE IF NOT EXISTS inv."ProductBinStock"(
  "ProductBinStockId"     BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"             INT           NOT NULL,
  "ProductId"             BIGINT        NOT NULL,
  "WarehouseId"           BIGINT        NOT NULL,
  "BinId"                 BIGINT        NULL,
  "LotId"                 BIGINT        NULL,
  "QuantityOnHand"        DECIMAL(18,4) NOT NULL DEFAULT 0,
  "QuantityReserved"      DECIMAL(18,4) NOT NULL DEFAULT 0,
  "QuantityAvailable"     DECIMAL(18,4) NOT NULL DEFAULT 0,
  "LastCountDate"         DATE          NULL,
  "IsDeleted"             BOOLEAN       NOT NULL DEFAULT FALSE,
  "DeletedAt"             TIMESTAMP     NULL,
  "DeletedByUserId"       INT           NULL,
  "CreatedAt"             TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"             TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId"       INT           NULL,
  "UpdatedByUserId"       INT           NULL,
  "RowVer"                INT           NOT NULL DEFAULT 1,
  CONSTRAINT "FK_inv_ProductBinStock_Company"   FOREIGN KEY ("CompanyId")       REFERENCES cfg."Company"("CompanyId"),
  CONSTRAINT "FK_inv_ProductBinStock_Product"   FOREIGN KEY ("ProductId")       REFERENCES master."Product"("ProductId"),
  CONSTRAINT "FK_inv_ProductBinStock_Warehouse" FOREIGN KEY ("WarehouseId")     REFERENCES inv."Warehouse"("WarehouseId"),
  CONSTRAINT "FK_inv_ProductBinStock_Bin"       FOREIGN KEY ("BinId")           REFERENCES inv."WarehouseBin"("BinId"),
  CONSTRAINT "FK_inv_ProductBinStock_Lot"       FOREIGN KEY ("LotId")           REFERENCES inv."ProductLot"("LotId"),
  CONSTRAINT "FK_inv_ProductBinStock_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_inv_ProductBinStock_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_inv_ProductBinStock_DeletedBy" FOREIGN KEY ("DeletedByUserId") REFERENCES sec."User"("UserId")
);

CREATE UNIQUE INDEX IF NOT EXISTS "UX_inv_ProductBinStock_Location"
  ON inv."ProductBinStock" ("CompanyId", "ProductId", "WarehouseId", COALESCE("BinId", 0), COALESCE("LotId", 0));

CREATE INDEX IF NOT EXISTS "IX_inv_ProductBinStock_Warehouse"
  ON inv."ProductBinStock" ("WarehouseId", "ProductId")
  WHERE "IsDeleted" = FALSE;

-- Trigger para mantener QuantityAvailable sincronizado
CREATE OR REPLACE FUNCTION inv.trg_product_bin_stock_available()
-- +goose StatementBegin
RETURNS TRIGGER AS $$
BEGIN
  NEW."QuantityAvailable" := NEW."QuantityOnHand" - NEW."QuantityReserved";
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS "TR_inv_ProductBinStock_Available" ON inv."ProductBinStock";
CREATE TRIGGER "TR_inv_ProductBinStock_Available"
  BEFORE INSERT OR UPDATE OF "QuantityOnHand", "QuantityReserved"
  ON inv."ProductBinStock"
  FOR EACH ROW
  EXECUTE FUNCTION inv.trg_product_bin_stock_available();

-- ============================================================
-- 7. inv."InventoryValuationMethod"  (Metodo de valoracion)
-- ============================================================
CREATE TABLE IF NOT EXISTS inv."InventoryValuationMethod"(
  "ValuationMethodId"     BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"             INT           NOT NULL,
  "ProductId"             BIGINT        NOT NULL,
  "Method"                VARCHAR(20)   NOT NULL DEFAULT 'WEIGHTED_AVG',
  "StandardCost"          DECIMAL(18,4) NULL,
  "IsDeleted"             BOOLEAN       NOT NULL DEFAULT FALSE,
  "DeletedAt"             TIMESTAMP     NULL,
  "DeletedByUserId"       INT           NULL,
  "CreatedAt"             TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"             TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId"       INT           NULL,
  "UpdatedByUserId"       INT           NULL,
  "RowVer"                INT           NOT NULL DEFAULT 1,
  CONSTRAINT "CK_inv_ValMethod_Method" CHECK ("Method" IN ('FIFO', 'LIFO', 'WEIGHTED_AVG', 'LAST_COST', 'STANDARD')),
  CONSTRAINT "FK_inv_ValMethod_Company"   FOREIGN KEY ("CompanyId")       REFERENCES cfg."Company"("CompanyId"),
  CONSTRAINT "FK_inv_ValMethod_Product"   FOREIGN KEY ("ProductId")       REFERENCES master."Product"("ProductId"),
  CONSTRAINT "FK_inv_ValMethod_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_inv_ValMethod_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_inv_ValMethod_DeletedBy" FOREIGN KEY ("DeletedByUserId") REFERENCES sec."User"("UserId")
);

CREATE UNIQUE INDEX IF NOT EXISTS "UQ_inv_ValMethod_Product"
  ON inv."InventoryValuationMethod" ("CompanyId", "ProductId")
  WHERE "IsDeleted" = FALSE;

-- ============================================================
-- 8. inv."InventoryValuationLayer"  (Capas de costo FIFO/LIFO)
-- ============================================================
CREATE TABLE IF NOT EXISTS inv."InventoryValuationLayer"(
  "LayerId"               BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"             INT           NOT NULL,
  "ProductId"             BIGINT        NOT NULL,
  "LotId"                 BIGINT        NULL,
  "LayerDate"             DATE          NOT NULL,
  "RemainingQuantity"     DECIMAL(18,4) NOT NULL DEFAULT 0,
  "UnitCost"              DECIMAL(18,4) NOT NULL DEFAULT 0,
  "SourceDocumentType"    VARCHAR(30)   NULL,
  "SourceDocumentNumber"  VARCHAR(60)   NULL,
  "CreatedAt"             TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  CONSTRAINT "FK_inv_ValLayer_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId"),
  CONSTRAINT "FK_inv_ValLayer_Product" FOREIGN KEY ("ProductId") REFERENCES master."Product"("ProductId"),
  CONSTRAINT "FK_inv_ValLayer_Lot"     FOREIGN KEY ("LotId")     REFERENCES inv."ProductLot"("LotId")
);

CREATE INDEX IF NOT EXISTS "IX_inv_ValLayer_Product"
  ON inv."InventoryValuationLayer" ("CompanyId", "ProductId", "LayerDate");

CREATE INDEX IF NOT EXISTS "IX_inv_ValLayer_Remaining"
  ON inv."InventoryValuationLayer" ("CompanyId", "ProductId")
  WHERE "RemainingQuantity" > 0;

-- ============================================================
-- 9. inv."StockMovement"  (Movimientos de stock detallados)
-- ============================================================
CREATE TABLE IF NOT EXISTS inv."StockMovement"(
  "MovementId"            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"             INT           NOT NULL,
  "BranchId"              INT           NOT NULL,
  "ProductId"             BIGINT        NOT NULL,
  "LotId"                 BIGINT        NULL,
  "SerialId"              BIGINT        NULL,
  "FromWarehouseId"       BIGINT        NULL,
  "ToWarehouseId"         BIGINT        NULL,
  "FromBinId"             BIGINT        NULL,
  "ToBinId"               BIGINT        NULL,
  "MovementType"          VARCHAR(20)   NOT NULL,
  "Quantity"              DECIMAL(18,4) NOT NULL,
  "UnitCost"              DECIMAL(18,4) NOT NULL DEFAULT 0,
  "TotalCost"             DECIMAL(18,2) NOT NULL DEFAULT 0,
  "SourceDocumentType"    VARCHAR(30)   NULL,
  "SourceDocumentNumber"  VARCHAR(60)   NULL,
  "Notes"                 VARCHAR(500)  NULL,
  "MovementDate"          TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId"       INT           NULL,
  "CreatedAt"             TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  CONSTRAINT "CK_inv_StockMovement_Type" CHECK ("MovementType" IN (
    'PURCHASE_IN', 'SALE_OUT', 'TRANSFER', 'ADJUSTMENT',
    'RETURN_IN', 'RETURN_OUT', 'PRODUCTION_IN', 'PRODUCTION_OUT', 'SCRAP'
  )),
  CONSTRAINT "FK_inv_StockMovement_Company"   FOREIGN KEY ("CompanyId")       REFERENCES cfg."Company"("CompanyId"),
  CONSTRAINT "FK_inv_StockMovement_Branch"    FOREIGN KEY ("BranchId")        REFERENCES cfg."Branch"("BranchId"),
  CONSTRAINT "FK_inv_StockMovement_Product"   FOREIGN KEY ("ProductId")       REFERENCES master."Product"("ProductId"),
  CONSTRAINT "FK_inv_StockMovement_Lot"       FOREIGN KEY ("LotId")           REFERENCES inv."ProductLot"("LotId"),
  CONSTRAINT "FK_inv_StockMovement_Serial"    FOREIGN KEY ("SerialId")        REFERENCES inv."ProductSerial"("SerialId"),
  CONSTRAINT "FK_inv_StockMovement_FromWH"    FOREIGN KEY ("FromWarehouseId") REFERENCES inv."Warehouse"("WarehouseId"),
  CONSTRAINT "FK_inv_StockMovement_ToWH"      FOREIGN KEY ("ToWarehouseId")   REFERENCES inv."Warehouse"("WarehouseId"),
  CONSTRAINT "FK_inv_StockMovement_FromBin"   FOREIGN KEY ("FromBinId")       REFERENCES inv."WarehouseBin"("BinId"),
  CONSTRAINT "FK_inv_StockMovement_ToBin"     FOREIGN KEY ("ToBinId")         REFERENCES inv."WarehouseBin"("BinId"),
  CONSTRAINT "FK_inv_StockMovement_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId")
);

CREATE INDEX IF NOT EXISTS "IX_inv_StockMovement_Product"
  ON inv."StockMovement" ("CompanyId", "ProductId", "MovementDate" DESC);

CREATE INDEX IF NOT EXISTS "IX_inv_StockMovement_Date"
  ON inv."StockMovement" ("CompanyId", "MovementDate" DESC);

CREATE INDEX IF NOT EXISTS "IX_inv_StockMovement_Type"
  ON inv."StockMovement" ("CompanyId", "MovementType", "MovementDate" DESC);

COMMIT;

DO $$ BEGIN RAISE NOTICE '>>> 09_inventory_advanced.sql ejecutado correctamente <<<'; END $$;
-- +goose StatementEnd

-- Source: 10_logistics.sql
-- ============================================================
-- Zentto PostgreSQL - 10_logistics.sql
-- Schema: logistics (Logistica)
-- Tablas: Carrier, Driver, GoodsReceipt, GoodsReceiptLine,
--         GoodsReceiptSerial, GoodsReturn, GoodsReturnLine,
--         DeliveryNote, DeliveryNoteLine, DeliveryNoteSerial
-- ============================================================

BEGIN;

CREATE SCHEMA IF NOT EXISTS logistics;

-- ============================================================
-- 1. logistics.Carrier (Transportistas)
-- ============================================================
CREATE TABLE IF NOT EXISTS logistics."Carrier" (
  "CarrierId"       BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"       INT           NOT NULL,
  "CarrierCode"     VARCHAR(30)   NOT NULL,
  "CarrierName"     VARCHAR(150)  NOT NULL,
  "FiscalId"        VARCHAR(30)   NULL,
  "ContactName"     VARCHAR(120)  NULL,
  "Phone"           VARCHAR(40)   NULL,
  "Email"           VARCHAR(150)  NULL,
  "AddressLine"     VARCHAR(250)  NULL,
  "IsActive"        BOOLEAN       NOT NULL DEFAULT TRUE,
  "IsDeleted"       BOOLEAN       NOT NULL DEFAULT FALSE,
  "CreatedAt"       TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"       TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId" INT           NULL,
  "UpdatedByUserId" INT           NULL,
  "RowVer"          INT           NOT NULL DEFAULT 1
);

CREATE UNIQUE INDEX IF NOT EXISTS "UQ_Carrier_CompanyCode"
  ON logistics."Carrier" ("CompanyId", "CarrierCode") WHERE "IsDeleted" = FALSE;

CREATE INDEX IF NOT EXISTS "IX_Carrier_CompanyActive"
  ON logistics."Carrier" ("CompanyId", "IsDeleted", "IsActive");

-- ============================================================
-- 2. logistics.Driver (Conductores)
-- ============================================================
CREATE TABLE IF NOT EXISTS logistics."Driver" (
  "DriverId"        BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"       INT           NOT NULL,
  "CarrierId"       BIGINT        NULL REFERENCES logistics."Carrier" ("CarrierId"),
  "DriverCode"      VARCHAR(30)   NOT NULL,
  "DriverName"      VARCHAR(150)  NOT NULL,
  "FiscalId"        VARCHAR(30)   NULL,
  "LicenseNumber"   VARCHAR(40)   NULL,
  "LicenseExpiry"   DATE          NULL,
  "Phone"           VARCHAR(40)   NULL,
  "IsActive"        BOOLEAN       NOT NULL DEFAULT TRUE,
  "IsDeleted"       BOOLEAN       NOT NULL DEFAULT FALSE,
  "CreatedAt"       TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"       TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId" INT           NULL,
  "UpdatedByUserId" INT           NULL,
  "RowVer"          INT           NOT NULL DEFAULT 1
);

CREATE UNIQUE INDEX IF NOT EXISTS "UQ_Driver_CompanyCode"
  ON logistics."Driver" ("CompanyId", "DriverCode") WHERE "IsDeleted" = FALSE;

CREATE INDEX IF NOT EXISTS "IX_Driver_CompanyActive"
  ON logistics."Driver" ("CompanyId", "IsDeleted", "IsActive");

CREATE INDEX IF NOT EXISTS "IX_Driver_Carrier"
  ON logistics."Driver" ("CarrierId") WHERE "IsDeleted" = FALSE;

-- ============================================================
-- 3. logistics.GoodsReceipt (Recepcion de mercancia)
-- ============================================================
CREATE TABLE IF NOT EXISTS logistics."GoodsReceipt" (
  "GoodsReceiptId"         BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"              INT           NOT NULL,
  "BranchId"               INT           NOT NULL,
  "ReceiptNumber"          VARCHAR(40)   NOT NULL,
  "PurchaseDocumentNumber" VARCHAR(60)   NULL,
  "SupplierId"             BIGINT        NOT NULL,
  "WarehouseId"            BIGINT        NOT NULL,
  "ReceiptDate"            DATE          NOT NULL,
  "Status"                 VARCHAR(20)   NOT NULL DEFAULT 'DRAFT'
                           CHECK ("Status" IN ('DRAFT','PARTIAL','COMPLETE','VOIDED')),
  "Notes"                  VARCHAR(500)  NULL,
  "CarrierId"              BIGINT        NULL,
  "DriverName"             VARCHAR(150)  NULL,
  "VehiclePlate"           VARCHAR(20)   NULL,
  "ReceivedByUserId"       INT           NULL,
  "IsDeleted"              BOOLEAN       NOT NULL DEFAULT FALSE,
  "CreatedAt"              TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"              TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId"        INT           NULL,
  "UpdatedByUserId"        INT           NULL,
  "RowVer"                 INT           NOT NULL DEFAULT 1
);

CREATE UNIQUE INDEX IF NOT EXISTS "UQ_GoodsReceipt_Number"
  ON logistics."GoodsReceipt" ("CompanyId", "BranchId", "ReceiptNumber") WHERE "IsDeleted" = FALSE;

CREATE INDEX IF NOT EXISTS "IX_GoodsReceipt_Date"
  ON logistics."GoodsReceipt" ("CompanyId", "ReceiptDate" DESC);

CREATE INDEX IF NOT EXISTS "IX_GoodsReceipt_Status"
  ON logistics."GoodsReceipt" ("CompanyId", "Status") WHERE "IsDeleted" = FALSE AND "Status" <> 'VOIDED';

-- ============================================================
-- 4. logistics.GoodsReceiptLine (Lineas de recepcion)
-- ============================================================
CREATE TABLE IF NOT EXISTS logistics."GoodsReceiptLine" (
  "GoodsReceiptLineId" BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "GoodsReceiptId"     BIGINT        NOT NULL REFERENCES logistics."GoodsReceipt" ("GoodsReceiptId"),
  "LineNumber"         INT           NOT NULL,
  "ProductId"          BIGINT        NOT NULL,
  "ProductCode"        VARCHAR(40)   NOT NULL,
  "Description"        VARCHAR(250)  NULL,
  "OrderedQuantity"    DECIMAL(18,4) NOT NULL,
  "ReceivedQuantity"   DECIMAL(18,4) NOT NULL,
  "RejectedQuantity"   DECIMAL(18,4) NOT NULL DEFAULT 0,
  "UnitCost"           DECIMAL(18,4) NOT NULL,
  "TotalCost"          DECIMAL(18,2) NOT NULL,
  "LotNumber"          VARCHAR(60)   NULL,
  "ExpiryDate"         DATE          NULL,
  "WarehouseId"        BIGINT        NULL,
  "BinId"              BIGINT        NULL,
  "InspectionStatus"   VARCHAR(20)   NOT NULL DEFAULT 'PENDING'
                       CHECK ("InspectionStatus" IN ('PENDING','APPROVED','REJECTED')),
  "Notes"              VARCHAR(500)  NULL,
  "IsDeleted"          BOOLEAN       NOT NULL DEFAULT FALSE,
  "CreatedAt"          TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"          TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId"    INT           NULL,
  "UpdatedByUserId"    INT           NULL,
  "RowVer"             INT           NOT NULL DEFAULT 1
);

CREATE INDEX IF NOT EXISTS "IX_GoodsReceiptLine_Receipt"
  ON logistics."GoodsReceiptLine" ("GoodsReceiptId", "LineNumber");

-- ============================================================
-- 5. logistics.GoodsReceiptSerial (Seriales recibidos)
-- ============================================================
CREATE TABLE IF NOT EXISTS logistics."GoodsReceiptSerial" (
  "GoodsReceiptSerialId" BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "GoodsReceiptLineId"   BIGINT        NOT NULL REFERENCES logistics."GoodsReceiptLine" ("GoodsReceiptLineId"),
  "SerialNumber"         VARCHAR(100)  NOT NULL,
  "Status"               VARCHAR(20)   NOT NULL DEFAULT 'RECEIVED'
                         CHECK ("Status" IN ('RECEIVED','REJECTED')),
  "Notes"                VARCHAR(250)  NULL
);

-- ============================================================
-- 6. logistics.GoodsReturn (Devolucion de mercancia)
-- ============================================================
CREATE TABLE IF NOT EXISTS logistics."GoodsReturn" (
  "GoodsReturnId"   BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"       INT           NOT NULL,
  "BranchId"        INT           NOT NULL,
  "ReturnNumber"    VARCHAR(40)   NOT NULL,
  "GoodsReceiptId"  BIGINT        NULL REFERENCES logistics."GoodsReceipt" ("GoodsReceiptId"),
  "SupplierId"      BIGINT        NOT NULL,
  "WarehouseId"     BIGINT        NOT NULL,
  "ReturnDate"      DATE          NOT NULL,
  "Reason"          VARCHAR(500)  NULL,
  "Status"          VARCHAR(20)   NOT NULL DEFAULT 'DRAFT'
                    CHECK ("Status" IN ('DRAFT','APPROVED','SHIPPED','VOIDED')),
  "Notes"           VARCHAR(500)  NULL,
  "IsDeleted"       BOOLEAN       NOT NULL DEFAULT FALSE,
  "CreatedAt"       TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"       TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId" INT           NULL,
  "UpdatedByUserId" INT           NULL,
  "RowVer"          INT           NOT NULL DEFAULT 1
);

CREATE UNIQUE INDEX IF NOT EXISTS "UQ_GoodsReturn_Number"
  ON logistics."GoodsReturn" ("CompanyId", "BranchId", "ReturnNumber") WHERE "IsDeleted" = FALSE;

CREATE INDEX IF NOT EXISTS "IX_GoodsReturn_Date"
  ON logistics."GoodsReturn" ("CompanyId", "ReturnDate" DESC);

-- ============================================================
-- 7. logistics.GoodsReturnLine (Lineas de devolucion)
-- ============================================================
CREATE TABLE IF NOT EXISTS logistics."GoodsReturnLine" (
  "GoodsReturnLineId" BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "GoodsReturnId"     BIGINT        NOT NULL REFERENCES logistics."GoodsReturn" ("GoodsReturnId"),
  "LineNumber"        INT           NOT NULL,
  "ProductId"         BIGINT        NOT NULL,
  "ProductCode"       VARCHAR(40)   NOT NULL,
  "Quantity"          DECIMAL(18,4) NOT NULL,
  "UnitCost"          DECIMAL(18,4) NOT NULL,
  "LotNumber"         VARCHAR(60)   NULL,
  "SerialNumber"      VARCHAR(100)  NULL,
  "Reason"            VARCHAR(250)  NULL,
  "IsDeleted"         BOOLEAN       NOT NULL DEFAULT FALSE,
  "CreatedAt"         TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"         TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId"   INT           NULL,
  "UpdatedByUserId"   INT           NULL,
  "RowVer"            INT           NOT NULL DEFAULT 1
);

CREATE INDEX IF NOT EXISTS "IX_GoodsReturnLine_Return"
  ON logistics."GoodsReturnLine" ("GoodsReturnId", "LineNumber");

-- ============================================================
-- 8. logistics.DeliveryNote (Notas de entrega / guias de despacho)
-- ============================================================
CREATE TABLE IF NOT EXISTS logistics."DeliveryNote" (
  "DeliveryNoteId"       BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"            INT           NOT NULL,
  "BranchId"             INT           NOT NULL,
  "DeliveryNumber"       VARCHAR(40)   NOT NULL,
  "SalesDocumentNumber"  VARCHAR(60)   NULL,
  "CustomerId"           BIGINT        NOT NULL,
  "WarehouseId"          BIGINT        NOT NULL,
  "DeliveryDate"         DATE          NOT NULL,
  "Status"               VARCHAR(20)   NOT NULL DEFAULT 'DRAFT'
                         CHECK ("Status" IN ('DRAFT','PICKING','PACKED','DISPATCHED','IN_TRANSIT','DELIVERED','VOIDED')),
  "CarrierId"            BIGINT        NULL REFERENCES logistics."Carrier" ("CarrierId"),
  "DriverId"             BIGINT        NULL REFERENCES logistics."Driver" ("DriverId"),
  "VehiclePlate"         VARCHAR(20)   NULL,
  "ShipToAddress"        VARCHAR(500)  NULL,
  "ShipToContact"        VARCHAR(150)  NULL,
  "EstimatedDelivery"    DATE          NULL,
  "ActualDelivery"       DATE          NULL,
  "DeliveredToName"      VARCHAR(150)  NULL,
  "DeliverySignature"    VARCHAR(500)  NULL,
  "Notes"                VARCHAR(500)  NULL,
  "DispatchedByUserId"   INT           NULL,
  "IsDeleted"            BOOLEAN       NOT NULL DEFAULT FALSE,
  "CreatedAt"            TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"            TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId"      INT           NULL,
  "UpdatedByUserId"      INT           NULL,
  "RowVer"               INT           NOT NULL DEFAULT 1
);

CREATE UNIQUE INDEX IF NOT EXISTS "UQ_DeliveryNote_Number"
  ON logistics."DeliveryNote" ("CompanyId", "BranchId", "DeliveryNumber") WHERE "IsDeleted" = FALSE;

CREATE INDEX IF NOT EXISTS "IX_DeliveryNote_Date"
  ON logistics."DeliveryNote" ("CompanyId", "DeliveryDate" DESC);

CREATE INDEX IF NOT EXISTS "IX_DeliveryNote_ActiveStatus"
  ON logistics."DeliveryNote" ("CompanyId", "Status")
  WHERE "IsDeleted" = FALSE AND "Status" NOT IN ('DELIVERED','VOIDED');

CREATE INDEX IF NOT EXISTS "IX_DeliveryNote_Customer"
  ON logistics."DeliveryNote" ("CustomerId") WHERE "IsDeleted" = FALSE;

-- ============================================================
-- 9. logistics.DeliveryNoteLine (Lineas de nota de entrega)
-- ============================================================
CREATE TABLE IF NOT EXISTS logistics."DeliveryNoteLine" (
  "DeliveryNoteLineId" BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "DeliveryNoteId"     BIGINT        NOT NULL REFERENCES logistics."DeliveryNote" ("DeliveryNoteId"),
  "LineNumber"         INT           NOT NULL,
  "ProductId"          BIGINT        NOT NULL,
  "ProductCode"        VARCHAR(40)   NOT NULL,
  "Description"        VARCHAR(250)  NULL,
  "Quantity"           DECIMAL(18,4) NOT NULL,
  "LotNumber"          VARCHAR(60)   NULL,
  "WarehouseId"        BIGINT        NULL,
  "BinId"              BIGINT        NULL,
  "PickedQuantity"     DECIMAL(18,4) NOT NULL DEFAULT 0,
  "PackedQuantity"     DECIMAL(18,4) NOT NULL DEFAULT 0,
  "Notes"              VARCHAR(500)  NULL,
  "IsDeleted"          BOOLEAN       NOT NULL DEFAULT FALSE,
  "CreatedAt"          TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"          TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId"    INT           NULL,
  "UpdatedByUserId"    INT           NULL,
  "RowVer"             INT           NOT NULL DEFAULT 1
);

CREATE INDEX IF NOT EXISTS "IX_DeliveryNoteLine_Note"
  ON logistics."DeliveryNoteLine" ("DeliveryNoteId", "LineNumber");

-- ============================================================
-- 10. logistics.DeliveryNoteSerial (Seriales despachados)
-- ============================================================
CREATE TABLE IF NOT EXISTS logistics."DeliveryNoteSerial" (
  "DeliveryNoteSerialId" BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "DeliveryNoteLineId"   BIGINT        NOT NULL REFERENCES logistics."DeliveryNoteLine" ("DeliveryNoteLineId"),
  "SerialId"             BIGINT        NULL,
  "SerialNumber"         VARCHAR(100)  NOT NULL,
  "Status"               VARCHAR(20)   NOT NULL DEFAULT 'DISPATCHED'
                         CHECK ("Status" IN ('DISPATCHED','DELIVERED','RETURNED'))
);

COMMIT;

-- +goose StatementBegin
DO $$ BEGIN RAISE NOTICE '>>> 10_logistics.sql ejecutado correctamente <<<'; END $$;
-- +goose StatementEnd

-- Source: 11_crm.sql
-- ============================================================
-- Zentto PostgreSQL - 11_crm.sql
-- Schema: crm (Gestion de Relaciones con Clientes)
-- Tablas: Pipeline, PipelineStage, Lead, Activity, LeadHistory
-- ============================================================

BEGIN;

CREATE SCHEMA IF NOT EXISTS crm;

-- ============================================================
-- 1. crm."Pipeline"  (Embudos de ventas)
-- ============================================================
CREATE TABLE IF NOT EXISTS crm."Pipeline"(
  "PipelineId"            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"             INT NOT NULL,
  "PipelineCode"          VARCHAR(30) NOT NULL,
  "PipelineName"          VARCHAR(150) NOT NULL,
  "IsDefault"             BOOLEAN NOT NULL DEFAULT FALSE,
  "IsActive"              BOOLEAN NOT NULL DEFAULT TRUE,
  "IsDeleted"             BOOLEAN NOT NULL DEFAULT FALSE,
  "CreatedAt"             TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"             TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "DeletedAt"             TIMESTAMP NULL,
  "CreatedByUserId"       INT NULL,
  "UpdatedByUserId"       INT NULL,
  "DeletedByUserId"       INT NULL,
  "RowVer"                INT NOT NULL DEFAULT 1,
  CONSTRAINT "FK_crm_Pipeline_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId"),
  CONSTRAINT "FK_crm_Pipeline_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_crm_Pipeline_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_crm_Pipeline_DeletedBy" FOREIGN KEY ("DeletedByUserId") REFERENCES sec."User"("UserId")
);

CREATE UNIQUE INDEX IF NOT EXISTS "UQ_crm_Pipeline_Code"
  ON crm."Pipeline" ("CompanyId", "PipelineCode")
  WHERE "IsDeleted" = FALSE;

-- ============================================================
-- 2. crm."PipelineStage"  (Etapas del embudo)
-- ============================================================
CREATE TABLE IF NOT EXISTS crm."PipelineStage"(
  "StageId"               BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "PipelineId"            BIGINT NOT NULL,
  "StageCode"             VARCHAR(30) NOT NULL,
  "StageName"             VARCHAR(100) NOT NULL,
  "StageOrder"            INT NOT NULL DEFAULT 0,
  "Probability"           DECIMAL(5,2) NOT NULL DEFAULT 0,
  "DaysExpected"          INT NOT NULL DEFAULT 7,
  "Color"                 VARCHAR(7) NULL,
  "IsClosed"              BOOLEAN NOT NULL DEFAULT FALSE,
  "IsWon"                 BOOLEAN NOT NULL DEFAULT FALSE,
  "IsActive"              BOOLEAN NOT NULL DEFAULT TRUE,
  "IsDeleted"             BOOLEAN NOT NULL DEFAULT FALSE,
  "CreatedAt"             TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"             TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "DeletedAt"             TIMESTAMP NULL,
  "CreatedByUserId"       INT NULL,
  "UpdatedByUserId"       INT NULL,
  "DeletedByUserId"       INT NULL,
  "RowVer"                INT NOT NULL DEFAULT 1,
  CONSTRAINT "FK_crm_PipelineStage_Pipeline" FOREIGN KEY ("PipelineId") REFERENCES crm."Pipeline"("PipelineId"),
  CONSTRAINT "FK_crm_PipelineStage_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_crm_PipelineStage_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_crm_PipelineStage_DeletedBy" FOREIGN KEY ("DeletedByUserId") REFERENCES sec."User"("UserId")
);

CREATE UNIQUE INDEX IF NOT EXISTS "UQ_crm_PipelineStage_Code"
  ON crm."PipelineStage" ("PipelineId", "StageCode")
  WHERE "IsDeleted" = FALSE;

-- ============================================================
-- 3. crm."Lead"  (Oportunidades / Prospectos)
-- ============================================================
CREATE TABLE IF NOT EXISTS crm."Lead"(
  "LeadId"                BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"             INT NOT NULL,
  "BranchId"              INT NOT NULL,
  "PipelineId"            BIGINT NOT NULL,
  "StageId"               BIGINT NOT NULL,
  "LeadCode"              VARCHAR(40) NOT NULL,
  "ContactName"           VARCHAR(200) NULL,
  "CompanyName"           VARCHAR(200) NULL,
  "Email"                 VARCHAR(150) NULL,
  "Phone"                 VARCHAR(40) NULL,
  "Source"                 VARCHAR(20) NOT NULL DEFAULT 'OTHER',
  "AssignedToUserId"      INT NULL,
  "CustomerId"            BIGINT NULL,
  "EstimatedValue"        DECIMAL(18,2) NULL,
  "CurrencyCode"          CHAR(3) NOT NULL DEFAULT 'USD',
  "ExpectedCloseDate"     DATE NULL,
  "LostReason"            VARCHAR(500) NULL,
  "Notes"                 TEXT NULL,
  "Tags"                  VARCHAR(500) NULL,
  "Priority"              VARCHAR(10) NOT NULL DEFAULT 'MEDIUM',
  "Status"                VARCHAR(10) NOT NULL DEFAULT 'OPEN',
  "WonAt"                 TIMESTAMP NULL,
  "LostAt"                TIMESTAMP NULL,
  "IsDeleted"             BOOLEAN NOT NULL DEFAULT FALSE,
  "CreatedAt"             TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"             TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "DeletedAt"             TIMESTAMP NULL,
  "CreatedByUserId"       INT NULL,
  "UpdatedByUserId"       INT NULL,
  "DeletedByUserId"       INT NULL,
  "RowVer"                INT NOT NULL DEFAULT 1,
  CONSTRAINT "CK_crm_Lead_Source" CHECK ("Source" IN ('WEB', 'REFERRAL', 'COLD_CALL', 'EVENT', 'SOCIAL', 'OTHER')),
  CONSTRAINT "CK_crm_Lead_Priority" CHECK ("Priority" IN ('LOW', 'MEDIUM', 'HIGH', 'URGENT')),
  CONSTRAINT "CK_crm_Lead_Status" CHECK ("Status" IN ('OPEN', 'WON', 'LOST', 'ARCHIVED')),
  CONSTRAINT "FK_crm_Lead_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId"),
  CONSTRAINT "FK_crm_Lead_Pipeline" FOREIGN KEY ("PipelineId") REFERENCES crm."Pipeline"("PipelineId"),
  CONSTRAINT "FK_crm_Lead_Stage" FOREIGN KEY ("StageId") REFERENCES crm."PipelineStage"("StageId"),
  CONSTRAINT "FK_crm_Lead_Customer" FOREIGN KEY ("CustomerId") REFERENCES master."Customer"("CustomerId"),
  CONSTRAINT "FK_crm_Lead_AssignedTo" FOREIGN KEY ("AssignedToUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_crm_Lead_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_crm_Lead_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_crm_Lead_DeletedBy" FOREIGN KEY ("DeletedByUserId") REFERENCES sec."User"("UserId")
);

CREATE UNIQUE INDEX IF NOT EXISTS "UQ_crm_Lead_Code"
  ON crm."Lead" ("CompanyId", "LeadCode")
  WHERE "IsDeleted" = FALSE;

CREATE INDEX IF NOT EXISTS "IX_crm_Lead_Status_Stage"
  ON crm."Lead" ("CompanyId", "Status", "StageId")
  WHERE "IsDeleted" = FALSE;

-- ============================================================
-- 4. crm."Activity"  (Actividades — llamadas, emails, tareas)
-- ============================================================
CREATE TABLE IF NOT EXISTS crm."Activity"(
  "ActivityId"            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"             INT NOT NULL,
  "LeadId"                BIGINT NULL,
  "CustomerId"            BIGINT NULL,
  "ActivityType"          VARCHAR(20) NOT NULL DEFAULT 'NOTE',
  "Subject"               VARCHAR(200) NOT NULL,
  "Description"           TEXT NULL,
  "DueDate"               TIMESTAMP NULL,
  "CompletedAt"           TIMESTAMP NULL,
  "AssignedToUserId"      INT NULL,
  "IsCompleted"           BOOLEAN NOT NULL DEFAULT FALSE,
  "Priority"              VARCHAR(10) NOT NULL DEFAULT 'MEDIUM',
  "IsDeleted"             BOOLEAN NOT NULL DEFAULT FALSE,
  "CreatedAt"             TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"             TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "DeletedAt"             TIMESTAMP NULL,
  "CreatedByUserId"       INT NULL,
  "UpdatedByUserId"       INT NULL,
  "DeletedByUserId"       INT NULL,
  "RowVer"                INT NOT NULL DEFAULT 1,
  CONSTRAINT "CK_crm_Activity_Type" CHECK ("ActivityType" IN ('CALL', 'EMAIL', 'MEETING', 'NOTE', 'TASK', 'FOLLOWUP')),
  CONSTRAINT "CK_crm_Activity_Priority" CHECK ("Priority" IN ('LOW', 'MEDIUM', 'HIGH', 'URGENT')),
  CONSTRAINT "FK_crm_Activity_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId"),
  CONSTRAINT "FK_crm_Activity_Lead" FOREIGN KEY ("LeadId") REFERENCES crm."Lead"("LeadId"),
  CONSTRAINT "FK_crm_Activity_Customer" FOREIGN KEY ("CustomerId") REFERENCES master."Customer"("CustomerId"),
  CONSTRAINT "FK_crm_Activity_AssignedTo" FOREIGN KEY ("AssignedToUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_crm_Activity_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_crm_Activity_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_crm_Activity_DeletedBy" FOREIGN KEY ("DeletedByUserId") REFERENCES sec."User"("UserId")
);

CREATE INDEX IF NOT EXISTS "IX_crm_Activity_Pending"
  ON crm."Activity" ("CompanyId", "IsCompleted", "DueDate")
  WHERE "IsDeleted" = FALSE AND "IsCompleted" = FALSE;

-- ============================================================
-- 5. crm."LeadHistory"  (Historial de cambios del lead)
-- ============================================================
CREATE TABLE IF NOT EXISTS crm."LeadHistory"(
  "HistoryId"             BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "LeadId"                BIGINT NOT NULL,
  "FromStageId"           BIGINT NULL,
  "ToStageId"             BIGINT NULL,
  "ChangedByUserId"       INT NULL,
  "ChangeType"            VARCHAR(20) NOT NULL DEFAULT 'NOTE',
  "Notes"                 VARCHAR(500) NULL,
  "CreatedAt"             TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  CONSTRAINT "CK_crm_LeadHistory_ChangeType" CHECK ("ChangeType" IN ('STAGE_CHANGE', 'ASSIGN', 'NOTE', 'STATUS')),
  CONSTRAINT "FK_crm_LeadHistory_Lead" FOREIGN KEY ("LeadId") REFERENCES crm."Lead"("LeadId"),
  CONSTRAINT "FK_crm_LeadHistory_FromStage" FOREIGN KEY ("FromStageId") REFERENCES crm."PipelineStage"("StageId"),
  CONSTRAINT "FK_crm_LeadHistory_ToStage" FOREIGN KEY ("ToStageId") REFERENCES crm."PipelineStage"("StageId"),
  CONSTRAINT "FK_crm_LeadHistory_ChangedBy" FOREIGN KEY ("ChangedByUserId") REFERENCES sec."User"("UserId")
);

CREATE INDEX IF NOT EXISTS "IX_crm_LeadHistory_Lead"
  ON crm."LeadHistory" ("LeadId", "CreatedAt" DESC);

COMMIT;

-- +goose StatementBegin
DO $$ BEGIN RAISE NOTICE '>>> 11_crm.sql ejecutado correctamente <<<'; END $$;
-- +goose StatementEnd

-- Source: 12_manufacturing.sql
-- ============================================================
-- Zentto PostgreSQL - 12_manufacturing.sql
-- Schema: mfg (Manufactura)
-- Tablas: BillOfMaterials, BOMLine, WorkCenter, Routing,
--         WorkOrder, WorkOrderMaterial, WorkOrderOutput
-- ============================================================

BEGIN;

CREATE SCHEMA IF NOT EXISTS mfg;

-- ============================================================
-- 1. mfg."BillOfMaterials"  (Lista de materiales — cabecera)
-- ============================================================
CREATE TABLE IF NOT EXISTS mfg."BillOfMaterials"(
  "BOMId"                 BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"             INT NOT NULL,
  "BOMCode"               VARCHAR(30) NOT NULL,
  "BOMName"               VARCHAR(200) NOT NULL,
  "ProductId"             BIGINT NOT NULL,
  "OutputQuantity"        DECIMAL(18,3) NOT NULL DEFAULT 1,
  "UnitOfMeasure"         VARCHAR(20) NULL,
  "Version"               INT NOT NULL DEFAULT 1,
  "Status"                VARCHAR(20) NOT NULL DEFAULT 'DRAFT',
  "EffectiveFrom"         DATE NULL,
  "EffectiveTo"           DATE NULL,
  "Notes"                 VARCHAR(500) NULL,
  "IsActive"              BOOLEAN NOT NULL DEFAULT TRUE,
  "CreatedAt"             TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"             TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId"       INT NULL,
  "UpdatedByUserId"       INT NULL,
  "IsDeleted"             BOOLEAN NOT NULL DEFAULT FALSE,
  "DeletedAt"             TIMESTAMP NULL,
  "DeletedByUserId"       INT NULL,
  CONSTRAINT "CK_mfg_BOM_Status" CHECK ("Status" IN ('DRAFT', 'ACTIVE', 'OBSOLETE')),
  CONSTRAINT "UQ_mfg_BOM_Code" UNIQUE ("CompanyId", "BOMCode"),
  CONSTRAINT "FK_mfg_BOM_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId"),
  CONSTRAINT "FK_mfg_BOM_Product" FOREIGN KEY ("ProductId") REFERENCES master."Product"("ProductId"),
  CONSTRAINT "FK_mfg_BOM_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_mfg_BOM_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_mfg_BOM_DeletedBy" FOREIGN KEY ("DeletedByUserId") REFERENCES sec."User"("UserId")
);

CREATE INDEX IF NOT EXISTS "IX_mfg_BOM_Company"
  ON mfg."BillOfMaterials" ("CompanyId", "IsDeleted", "IsActive");

CREATE INDEX IF NOT EXISTS "IX_mfg_BOM_Product"
  ON mfg."BillOfMaterials" ("ProductId")
  WHERE "IsDeleted" = FALSE;

-- ============================================================
-- 2. mfg."BOMLine"  (Componentes de la lista de materiales)
-- ============================================================
CREATE TABLE IF NOT EXISTS mfg."BOMLine"(
  "BOMLineId"             BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "BOMId"                 BIGINT NOT NULL,
  "LineNumber"            INT NOT NULL,
  "ComponentProductId"    BIGINT NOT NULL,
  "Quantity"              DECIMAL(18,3) NOT NULL,
  "UnitOfMeasure"         VARCHAR(20) NULL,
  "WastePercent"          DECIMAL(5,2) NOT NULL DEFAULT 0,
  "IsOptional"            BOOLEAN NOT NULL DEFAULT FALSE,
  "Notes"                 VARCHAR(500) NULL,
  "CreatedAt"             TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"             TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  CONSTRAINT "UQ_mfg_BOMLine" UNIQUE ("BOMId", "LineNumber"),
  CONSTRAINT "FK_mfg_BOMLine_BOM" FOREIGN KEY ("BOMId") REFERENCES mfg."BillOfMaterials"("BOMId"),
  CONSTRAINT "FK_mfg_BOMLine_Component" FOREIGN KEY ("ComponentProductId") REFERENCES master."Product"("ProductId")
);

CREATE INDEX IF NOT EXISTS "IX_mfg_BOMLine_BOM"
  ON mfg."BOMLine" ("BOMId");

CREATE INDEX IF NOT EXISTS "IX_mfg_BOMLine_Component"
  ON mfg."BOMLine" ("ComponentProductId");

-- ============================================================
-- 3. mfg."WorkCenter"  (Centros de trabajo)
-- ============================================================
CREATE TABLE IF NOT EXISTS mfg."WorkCenter"(
  "WorkCenterId"          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"             INT NOT NULL,
  "WorkCenterCode"        VARCHAR(20) NOT NULL,
  "WorkCenterName"        VARCHAR(200) NOT NULL,
  "WarehouseId"           BIGINT NULL,
  "CostPerHour"           DECIMAL(18,4) NOT NULL DEFAULT 0,
  "Capacity"              DECIMAL(18,2) NOT NULL DEFAULT 1,
  "CapacityUom"           VARCHAR(20) NOT NULL DEFAULT 'UNITS_PER_HOUR',
  "IsActive"              BOOLEAN NOT NULL DEFAULT TRUE,
  "CreatedAt"             TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"             TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId"       INT NULL,
  "UpdatedByUserId"       INT NULL,
  "IsDeleted"             BOOLEAN NOT NULL DEFAULT FALSE,
  "DeletedAt"             TIMESTAMP NULL,
  "DeletedByUserId"       INT NULL,
  CONSTRAINT "UQ_mfg_WorkCenter_Code" UNIQUE ("CompanyId", "WorkCenterCode"),
  CONSTRAINT "FK_mfg_WorkCenter_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId"),
  CONSTRAINT "FK_mfg_WorkCenter_Warehouse" FOREIGN KEY ("WarehouseId") REFERENCES inv."Warehouse"("WarehouseId"),
  CONSTRAINT "FK_mfg_WorkCenter_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_mfg_WorkCenter_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_mfg_WorkCenter_DeletedBy" FOREIGN KEY ("DeletedByUserId") REFERENCES sec."User"("UserId")
);

CREATE INDEX IF NOT EXISTS "IX_mfg_WorkCenter_Company"
  ON mfg."WorkCenter" ("CompanyId", "IsDeleted", "IsActive");

-- ============================================================
-- 4. mfg."Routing"  (Rutas de produccion — operaciones)
-- ============================================================
CREATE TABLE IF NOT EXISTS mfg."Routing"(
  "RoutingId"             BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "BOMId"                 BIGINT NOT NULL,
  "OperationNumber"       INT NOT NULL,
  "OperationName"         VARCHAR(200) NOT NULL,
  "WorkCenterId"          BIGINT NOT NULL,
  "SetupTimeMinutes"      DECIMAL(10,2) NOT NULL DEFAULT 0,
  "RunTimeMinutes"        DECIMAL(10,2) NOT NULL DEFAULT 0,
  "Notes"                 VARCHAR(500) NULL,
  "CreatedAt"             TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"             TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  CONSTRAINT "UQ_mfg_Routing_Operation" UNIQUE ("BOMId", "OperationNumber"),
  CONSTRAINT "FK_mfg_Routing_BOM" FOREIGN KEY ("BOMId") REFERENCES mfg."BillOfMaterials"("BOMId"),
  CONSTRAINT "FK_mfg_Routing_WorkCenter" FOREIGN KEY ("WorkCenterId") REFERENCES mfg."WorkCenter"("WorkCenterId")
);

CREATE INDEX IF NOT EXISTS "IX_mfg_Routing_BOM"
  ON mfg."Routing" ("BOMId", "OperationNumber");

-- ============================================================
-- 5. mfg."WorkOrder"  (Ordenes de trabajo / produccion)
-- ============================================================
CREATE TABLE IF NOT EXISTS mfg."WorkOrder"(
  "WorkOrderId"           BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"             INT NOT NULL,
  "BranchId"              INT NOT NULL,
  "WorkOrderNumber"       VARCHAR(30) NOT NULL,
  "BOMId"                 BIGINT NOT NULL,
  "ProductId"             BIGINT NOT NULL,
  "PlannedQuantity"       DECIMAL(18,3) NOT NULL,
  "ProducedQuantity"      DECIMAL(18,3) NOT NULL DEFAULT 0,
  "ScrapQuantity"         DECIMAL(18,3) NOT NULL DEFAULT 0,
  "UnitOfMeasure"         VARCHAR(20) NULL,
  "WarehouseId"           BIGINT NOT NULL,
  "Status"                VARCHAR(20) NOT NULL DEFAULT 'DRAFT',
  "Priority"              VARCHAR(10) NOT NULL DEFAULT 'MEDIUM',
  "PlannedStartDate"      TIMESTAMP NULL,
  "PlannedEndDate"        TIMESTAMP NULL,
  "ActualStartDate"       TIMESTAMP NULL,
  "ActualEndDate"         TIMESTAMP NULL,
  "Notes"                 VARCHAR(500) NULL,
  "CreatedAt"             TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"             TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId"       INT NULL,
  "UpdatedByUserId"       INT NULL,
  "IsDeleted"             BOOLEAN NOT NULL DEFAULT FALSE,
  "DeletedAt"             TIMESTAMP NULL,
  "DeletedByUserId"       INT NULL,
  CONSTRAINT "CK_mfg_WorkOrder_Status" CHECK ("Status" IN ('DRAFT', 'CONFIRMED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED')),
  CONSTRAINT "CK_mfg_WorkOrder_Priority" CHECK ("Priority" IN ('LOW', 'MEDIUM', 'HIGH', 'URGENT')),
  CONSTRAINT "UQ_mfg_WorkOrder_Number" UNIQUE ("CompanyId", "WorkOrderNumber"),
  CONSTRAINT "FK_mfg_WorkOrder_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId"),
  CONSTRAINT "FK_mfg_WorkOrder_Branch" FOREIGN KEY ("BranchId") REFERENCES cfg."Branch"("BranchId"),
  CONSTRAINT "FK_mfg_WorkOrder_BOM" FOREIGN KEY ("BOMId") REFERENCES mfg."BillOfMaterials"("BOMId"),
  CONSTRAINT "FK_mfg_WorkOrder_Product" FOREIGN KEY ("ProductId") REFERENCES master."Product"("ProductId"),
  CONSTRAINT "FK_mfg_WorkOrder_Warehouse" FOREIGN KEY ("WarehouseId") REFERENCES inv."Warehouse"("WarehouseId"),
  CONSTRAINT "FK_mfg_WorkOrder_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_mfg_WorkOrder_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_mfg_WorkOrder_DeletedBy" FOREIGN KEY ("DeletedByUserId") REFERENCES sec."User"("UserId")
);

CREATE INDEX IF NOT EXISTS "IX_mfg_WorkOrder_Company"
  ON mfg."WorkOrder" ("CompanyId", "BranchId", "Status")
  WHERE "IsDeleted" = FALSE;

CREATE INDEX IF NOT EXISTS "IX_mfg_WorkOrder_BOM"
  ON mfg."WorkOrder" ("BOMId")
  WHERE "IsDeleted" = FALSE;

CREATE INDEX IF NOT EXISTS "IX_mfg_WorkOrder_Planned"
  ON mfg."WorkOrder" ("CompanyId", "PlannedStartDate")
  WHERE "Status" IN ('DRAFT', 'CONFIRMED') AND "IsDeleted" = FALSE;

-- ============================================================
-- 6. mfg."WorkOrderMaterial"  (Materiales consumidos)
-- ============================================================
CREATE TABLE IF NOT EXISTS mfg."WorkOrderMaterial"(
  "WorkOrderMaterialId"   BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "WorkOrderId"           BIGINT NOT NULL,
  "LineNumber"            INT NOT NULL,
  "ProductId"             BIGINT NOT NULL,
  "PlannedQuantity"       DECIMAL(18,3) NOT NULL,
  "ConsumedQuantity"      DECIMAL(18,3) NOT NULL DEFAULT 0,
  "UnitOfMeasure"         VARCHAR(20) NULL,
  "LotId"                 BIGINT NULL,
  "BinId"                 BIGINT NULL,
  "UnitCost"              DECIMAL(18,4) NOT NULL DEFAULT 0,
  "Notes"                 VARCHAR(500) NULL,
  "CreatedAt"             TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"             TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  CONSTRAINT "UQ_mfg_WOMaterial" UNIQUE ("WorkOrderId", "LineNumber"),
  CONSTRAINT "FK_mfg_WOMaterial_WorkOrder" FOREIGN KEY ("WorkOrderId") REFERENCES mfg."WorkOrder"("WorkOrderId"),
  CONSTRAINT "FK_mfg_WOMaterial_Product" FOREIGN KEY ("ProductId") REFERENCES master."Product"("ProductId"),
  CONSTRAINT "FK_mfg_WOMaterial_Lot" FOREIGN KEY ("LotId") REFERENCES inv."ProductLot"("LotId"),
  CONSTRAINT "FK_mfg_WOMaterial_Bin" FOREIGN KEY ("BinId") REFERENCES inv."WarehouseBin"("BinId")
);

CREATE INDEX IF NOT EXISTS "IX_mfg_WOMaterial_WorkOrder"
  ON mfg."WorkOrderMaterial" ("WorkOrderId");

-- ============================================================
-- 7. mfg."WorkOrderOutput"  (Productos terminados / salida)
-- ============================================================
CREATE TABLE IF NOT EXISTS mfg."WorkOrderOutput"(
  "WorkOrderOutputId"     BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "WorkOrderId"           BIGINT NOT NULL,
  "ProductId"             BIGINT NOT NULL,
  "Quantity"              DECIMAL(18,3) NOT NULL,
  "UnitOfMeasure"         VARCHAR(20) NULL,
  "LotNumber"             VARCHAR(60) NULL,
  "WarehouseId"           BIGINT NOT NULL,
  "BinId"                 BIGINT NULL,
  "UnitCost"              DECIMAL(18,4) NOT NULL DEFAULT 0,
  "IsScrap"               BOOLEAN NOT NULL DEFAULT FALSE,
  "Notes"                 VARCHAR(500) NULL,
  "ProducedAt"            TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId"       INT NULL,
  "CreatedAt"             TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  CONSTRAINT "FK_mfg_WOOutput_WorkOrder" FOREIGN KEY ("WorkOrderId") REFERENCES mfg."WorkOrder"("WorkOrderId"),
  CONSTRAINT "FK_mfg_WOOutput_Product" FOREIGN KEY ("ProductId") REFERENCES master."Product"("ProductId"),
  CONSTRAINT "FK_mfg_WOOutput_Warehouse" FOREIGN KEY ("WarehouseId") REFERENCES inv."Warehouse"("WarehouseId"),
  CONSTRAINT "FK_mfg_WOOutput_Bin" FOREIGN KEY ("BinId") REFERENCES inv."WarehouseBin"("BinId"),
  CONSTRAINT "FK_mfg_WOOutput_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId")
);

CREATE INDEX IF NOT EXISTS "IX_mfg_WOOutput_WorkOrder"
  ON mfg."WorkOrderOutput" ("WorkOrderId");

COMMIT;

-- Source: 13_fleet.sql
-- ============================================================
-- Zentto PostgreSQL - 13_fleet.sql
-- Schema: fleet (Flota vehicular)
-- Tablas: Vehicle, FuelLog, MaintenanceType, MaintenanceOrder,
--         MaintenanceOrderLine, Trip, VehicleDocument
-- ============================================================

BEGIN;

CREATE SCHEMA IF NOT EXISTS fleet;

-- ============================================================
-- 1. fleet."Vehicle"  (Vehiculos)
-- ============================================================
CREATE TABLE IF NOT EXISTS fleet."Vehicle"(
  "VehicleId"             BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"             INT NOT NULL,
  "VehicleCode"           VARCHAR(20) NOT NULL,
  "LicensePlate"          VARCHAR(20) NOT NULL,
  "VehicleType"           VARCHAR(30) NOT NULL DEFAULT 'CAR',
  "Brand"                 VARCHAR(60) NULL,
  "Model"                 VARCHAR(60) NULL,
  "Year"                  INT NULL,
  "Color"                 VARCHAR(30) NULL,
  "VinNumber"             VARCHAR(30) NULL,
  "EngineNumber"          VARCHAR(30) NULL,
  "FuelType"              VARCHAR(20) NOT NULL DEFAULT 'GASOLINE',
  "TankCapacity"          DECIMAL(10,2) NULL,
  "CurrentOdometer"       DECIMAL(12,2) NOT NULL DEFAULT 0,
  "OdometerUnit"          VARCHAR(5) NOT NULL DEFAULT 'KM',
  "DefaultDriverId"       BIGINT NULL,
  "WarehouseId"           BIGINT NULL,
  "PurchaseDate"          DATE NULL,
  "PurchaseCost"          DECIMAL(18,2) NULL,
  "InsurancePolicy"       VARCHAR(60) NULL,
  "InsuranceExpiry"       DATE NULL,
  "Status"                VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
  "Notes"                 VARCHAR(500) NULL,
  "IsActive"              BOOLEAN NOT NULL DEFAULT TRUE,
  "CreatedAt"             TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"             TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId"       INT NULL,
  "UpdatedByUserId"       INT NULL,
  "IsDeleted"             BOOLEAN NOT NULL DEFAULT FALSE,
  "DeletedAt"             TIMESTAMP NULL,
  "DeletedByUserId"       INT NULL,
  CONSTRAINT "CK_fleet_Vehicle_Type" CHECK ("VehicleType" IN ('CAR', 'TRUCK', 'VAN', 'MOTORCYCLE', 'BUS', 'TRAILER', 'FORKLIFT', 'OTHER')),
  CONSTRAINT "CK_fleet_Vehicle_Fuel" CHECK ("FuelType" IN ('GASOLINE', 'DIESEL', 'GAS', 'ELECTRIC', 'HYBRID', 'OTHER')),
  CONSTRAINT "CK_fleet_Vehicle_OdoUnit" CHECK ("OdometerUnit" IN ('KM', 'MI')),
  CONSTRAINT "CK_fleet_Vehicle_Status" CHECK ("Status" IN ('ACTIVE', 'IN_MAINTENANCE', 'OUT_OF_SERVICE', 'SOLD', 'SCRAPPED')),
  CONSTRAINT "UQ_fleet_Vehicle_Code" UNIQUE ("CompanyId", "VehicleCode"),
  CONSTRAINT "UQ_fleet_Vehicle_Plate" UNIQUE ("CompanyId", "LicensePlate"),
  CONSTRAINT "FK_fleet_Vehicle_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId"),
  CONSTRAINT "FK_fleet_Vehicle_Driver" FOREIGN KEY ("DefaultDriverId") REFERENCES logistics."Driver"("DriverId"),
  CONSTRAINT "FK_fleet_Vehicle_Warehouse" FOREIGN KEY ("WarehouseId") REFERENCES inv."Warehouse"("WarehouseId"),
  CONSTRAINT "FK_fleet_Vehicle_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_fleet_Vehicle_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_fleet_Vehicle_DeletedBy" FOREIGN KEY ("DeletedByUserId") REFERENCES sec."User"("UserId")
);

CREATE INDEX IF NOT EXISTS "IX_fleet_Vehicle_Company"
  ON fleet."Vehicle" ("CompanyId", "IsDeleted", "IsActive");

CREATE INDEX IF NOT EXISTS "IX_fleet_Vehicle_Status"
  ON fleet."Vehicle" ("CompanyId", "Status")
  WHERE "IsDeleted" = FALSE;

-- ============================================================
-- 2. fleet."FuelLog"  (Registro de combustible)
-- ============================================================
CREATE TABLE IF NOT EXISTS fleet."FuelLog"(
  "FuelLogId"             BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"             INT NOT NULL,
  "VehicleId"             BIGINT NOT NULL,
  "DriverId"              BIGINT NULL,
  "FuelDate"              TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "FuelType"              VARCHAR(20) NOT NULL,
  "Quantity"              DECIMAL(10,3) NOT NULL,
  "UnitPrice"             DECIMAL(18,4) NOT NULL,
  "TotalCost"             DECIMAL(18,2) NOT NULL,
  "CurrencyCode"          CHAR(3) NOT NULL DEFAULT 'USD',
  "OdometerReading"       DECIMAL(12,2) NULL,
  "IsFullTank"            BOOLEAN NOT NULL DEFAULT TRUE,
  "StationName"           VARCHAR(200) NULL,
  "InvoiceNumber"         VARCHAR(60) NULL,
  "Notes"                 VARCHAR(500) NULL,
  "CreatedAt"             TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"             TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId"       INT NULL,
  "UpdatedByUserId"       INT NULL,
  "IsDeleted"             BOOLEAN NOT NULL DEFAULT FALSE,
  "DeletedAt"             TIMESTAMP NULL,
  "DeletedByUserId"       INT NULL,
  CONSTRAINT "FK_fleet_FuelLog_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId"),
  CONSTRAINT "FK_fleet_FuelLog_Vehicle" FOREIGN KEY ("VehicleId") REFERENCES fleet."Vehicle"("VehicleId"),
  CONSTRAINT "FK_fleet_FuelLog_Driver" FOREIGN KEY ("DriverId") REFERENCES logistics."Driver"("DriverId"),
  CONSTRAINT "FK_fleet_FuelLog_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_fleet_FuelLog_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_fleet_FuelLog_DeletedBy" FOREIGN KEY ("DeletedByUserId") REFERENCES sec."User"("UserId")
);

CREATE INDEX IF NOT EXISTS "IX_fleet_FuelLog_Vehicle"
  ON fleet."FuelLog" ("VehicleId", "FuelDate" DESC);

CREATE INDEX IF NOT EXISTS "IX_fleet_FuelLog_Company"
  ON fleet."FuelLog" ("CompanyId", "FuelDate" DESC)
  WHERE "IsDeleted" = FALSE;

-- ============================================================
-- 3. fleet."MaintenanceType"  (Tipos de mantenimiento)
-- ============================================================
CREATE TABLE IF NOT EXISTS fleet."MaintenanceType"(
  "MaintenanceTypeId"     BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"             INT NOT NULL,
  "TypeCode"              VARCHAR(20) NOT NULL,
  "TypeName"              VARCHAR(200) NOT NULL,
  "Category"              VARCHAR(20) NOT NULL DEFAULT 'PREVENTIVE',
  "DefaultIntervalKm"     DECIMAL(12,2) NULL,
  "DefaultIntervalDays"   INT NULL,
  "IsActive"              BOOLEAN NOT NULL DEFAULT TRUE,
  "CreatedAt"             TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"             TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId"       INT NULL,
  "UpdatedByUserId"       INT NULL,
  "IsDeleted"             BOOLEAN NOT NULL DEFAULT FALSE,
  "DeletedAt"             TIMESTAMP NULL,
  "DeletedByUserId"       INT NULL,
  CONSTRAINT "CK_fleet_MaintType_Category" CHECK ("Category" IN ('PREVENTIVE', 'CORRECTIVE', 'PREDICTIVE', 'INSPECTION')),
  CONSTRAINT "UQ_fleet_MaintType_Code" UNIQUE ("CompanyId", "TypeCode"),
  CONSTRAINT "FK_fleet_MaintType_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId"),
  CONSTRAINT "FK_fleet_MaintType_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_fleet_MaintType_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_fleet_MaintType_DeletedBy" FOREIGN KEY ("DeletedByUserId") REFERENCES sec."User"("UserId")
);

CREATE INDEX IF NOT EXISTS "IX_fleet_MaintType_Company"
  ON fleet."MaintenanceType" ("CompanyId", "IsDeleted", "IsActive");

-- ============================================================
-- 4. fleet."MaintenanceOrder"  (Ordenes de mantenimiento)
-- ============================================================
CREATE TABLE IF NOT EXISTS fleet."MaintenanceOrder"(
  "MaintenanceOrderId"    BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"             INT NOT NULL,
  "VehicleId"             BIGINT NOT NULL,
  "MaintenanceTypeId"     BIGINT NOT NULL,
  "OrderNumber"           VARCHAR(30) NOT NULL,
  "OrderDate"             TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "OdometerAtService"     DECIMAL(12,2) NULL,
  "Status"                VARCHAR(20) NOT NULL DEFAULT 'DRAFT',
  "Priority"              VARCHAR(10) NOT NULL DEFAULT 'MEDIUM',
  "ScheduledDate"         TIMESTAMP NULL,
  "StartedAt"             TIMESTAMP NULL,
  "CompletedAt"           TIMESTAMP NULL,
  "WorkshopName"          VARCHAR(200) NULL,
  "TechnicianName"        VARCHAR(200) NULL,
  "TotalLaborCost"        DECIMAL(18,2) NOT NULL DEFAULT 0,
  "TotalPartsCost"        DECIMAL(18,2) NOT NULL DEFAULT 0,
  "TotalCost"             DECIMAL(18,2) NOT NULL DEFAULT 0,
  "CurrencyCode"          CHAR(3) NOT NULL DEFAULT 'USD',
  "Notes"                 VARCHAR(500) NULL,
  "CreatedAt"             TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"             TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId"       INT NULL,
  "UpdatedByUserId"       INT NULL,
  "IsDeleted"             BOOLEAN NOT NULL DEFAULT FALSE,
  "DeletedAt"             TIMESTAMP NULL,
  "DeletedByUserId"       INT NULL,
  CONSTRAINT "CK_fleet_MaintOrder_Status" CHECK ("Status" IN ('DRAFT', 'SCHEDULED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED')),
  CONSTRAINT "CK_fleet_MaintOrder_Priority" CHECK ("Priority" IN ('LOW', 'MEDIUM', 'HIGH', 'URGENT')),
  CONSTRAINT "UQ_fleet_MaintOrder_Number" UNIQUE ("CompanyId", "OrderNumber"),
  CONSTRAINT "FK_fleet_MaintOrder_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId"),
  CONSTRAINT "FK_fleet_MaintOrder_Vehicle" FOREIGN KEY ("VehicleId") REFERENCES fleet."Vehicle"("VehicleId"),
  CONSTRAINT "FK_fleet_MaintOrder_Type" FOREIGN KEY ("MaintenanceTypeId") REFERENCES fleet."MaintenanceType"("MaintenanceTypeId"),
  CONSTRAINT "FK_fleet_MaintOrder_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_fleet_MaintOrder_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_fleet_MaintOrder_DeletedBy" FOREIGN KEY ("DeletedByUserId") REFERENCES sec."User"("UserId")
);

CREATE INDEX IF NOT EXISTS "IX_fleet_MaintOrder_Vehicle"
  ON fleet."MaintenanceOrder" ("VehicleId", "OrderDate" DESC);

CREATE INDEX IF NOT EXISTS "IX_fleet_MaintOrder_Status"
  ON fleet."MaintenanceOrder" ("CompanyId", "Status")
  WHERE "IsDeleted" = FALSE;

-- ============================================================
-- 5. fleet."MaintenanceOrderLine"  (Lineas de la orden)
-- ============================================================
CREATE TABLE IF NOT EXISTS fleet."MaintenanceOrderLine"(
  "MaintenanceOrderLineId" BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "MaintenanceOrderId"    BIGINT NOT NULL,
  "LineNumber"            INT NOT NULL,
  "LineType"              VARCHAR(10) NOT NULL DEFAULT 'PART',
  "ProductId"             BIGINT NULL,
  "Description"           VARCHAR(300) NOT NULL,
  "Quantity"              DECIMAL(18,3) NOT NULL DEFAULT 1,
  "UnitCost"              DECIMAL(18,4) NOT NULL DEFAULT 0,
  "TotalCost"             DECIMAL(18,2) NOT NULL DEFAULT 0,
  "Notes"                 VARCHAR(500) NULL,
  "CreatedAt"             TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"             TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  CONSTRAINT "CK_fleet_MOLine_Type" CHECK ("LineType" IN ('PART', 'LABOR', 'SERVICE', 'OTHER')),
  CONSTRAINT "UQ_fleet_MOLine" UNIQUE ("MaintenanceOrderId", "LineNumber"),
  CONSTRAINT "FK_fleet_MOLine_Order" FOREIGN KEY ("MaintenanceOrderId") REFERENCES fleet."MaintenanceOrder"("MaintenanceOrderId"),
  CONSTRAINT "FK_fleet_MOLine_Product" FOREIGN KEY ("ProductId") REFERENCES master."Product"("ProductId")
);

CREATE INDEX IF NOT EXISTS "IX_fleet_MOLine_Order"
  ON fleet."MaintenanceOrderLine" ("MaintenanceOrderId");

-- ============================================================
-- 6. fleet."Trip"  (Viajes)
-- ============================================================
CREATE TABLE IF NOT EXISTS fleet."Trip"(
  "TripId"                BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"             INT NOT NULL,
  "VehicleId"             BIGINT NOT NULL,
  "DriverId"              BIGINT NULL,
  "DeliveryNoteId"        BIGINT NULL,
  "TripNumber"            VARCHAR(30) NOT NULL,
  "TripDate"              TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "Origin"                VARCHAR(300) NULL,
  "Destination"           VARCHAR(300) NULL,
  "DistanceKm"            DECIMAL(10,2) NULL,
  "OdometerStart"         DECIMAL(12,2) NULL,
  "OdometerEnd"           DECIMAL(12,2) NULL,
  "DepartedAt"            TIMESTAMP NULL,
  "ArrivedAt"             TIMESTAMP NULL,
  "Status"                VARCHAR(20) NOT NULL DEFAULT 'PLANNED',
  "Notes"                 VARCHAR(500) NULL,
  "CreatedAt"             TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"             TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId"       INT NULL,
  "UpdatedByUserId"       INT NULL,
  "IsDeleted"             BOOLEAN NOT NULL DEFAULT FALSE,
  "DeletedAt"             TIMESTAMP NULL,
  "DeletedByUserId"       INT NULL,
  CONSTRAINT "CK_fleet_Trip_Status" CHECK ("Status" IN ('PLANNED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED')),
  CONSTRAINT "UQ_fleet_Trip_Number" UNIQUE ("CompanyId", "TripNumber"),
  CONSTRAINT "FK_fleet_Trip_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId"),
  CONSTRAINT "FK_fleet_Trip_Vehicle" FOREIGN KEY ("VehicleId") REFERENCES fleet."Vehicle"("VehicleId"),
  CONSTRAINT "FK_fleet_Trip_Driver" FOREIGN KEY ("DriverId") REFERENCES logistics."Driver"("DriverId"),
  CONSTRAINT "FK_fleet_Trip_DeliveryNote" FOREIGN KEY ("DeliveryNoteId") REFERENCES logistics."DeliveryNote"("DeliveryNoteId"),
  CONSTRAINT "FK_fleet_Trip_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_fleet_Trip_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_fleet_Trip_DeletedBy" FOREIGN KEY ("DeletedByUserId") REFERENCES sec."User"("UserId")
);

CREATE INDEX IF NOT EXISTS "IX_fleet_Trip_Vehicle"
  ON fleet."Trip" ("VehicleId", "TripDate" DESC);

CREATE INDEX IF NOT EXISTS "IX_fleet_Trip_Company"
  ON fleet."Trip" ("CompanyId", "TripDate" DESC)
  WHERE "IsDeleted" = FALSE;

CREATE INDEX IF NOT EXISTS "IX_fleet_Trip_DeliveryNote"
  ON fleet."Trip" ("DeliveryNoteId")
  WHERE "DeliveryNoteId" IS NOT NULL;

-- ============================================================
-- 7. fleet."VehicleDocument"  (Documentos del vehiculo)
-- ============================================================
CREATE TABLE IF NOT EXISTS fleet."VehicleDocument"(
  "VehicleDocumentId"     BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "VehicleId"             BIGINT NOT NULL,
  "DocumentType"          VARCHAR(30) NOT NULL,
  "DocumentNumber"        VARCHAR(60) NULL,
  "Description"           VARCHAR(300) NULL,
  "IssuedAt"              DATE NULL,
  "ExpiresAt"             DATE NULL,
  "FileUrl"               VARCHAR(500) NULL,
  "Notes"                 VARCHAR(500) NULL,
  "CreatedAt"             TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"             TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId"       INT NULL,
  "UpdatedByUserId"       INT NULL,
  "IsDeleted"             BOOLEAN NOT NULL DEFAULT FALSE,
  "DeletedAt"             TIMESTAMP NULL,
  "DeletedByUserId"       INT NULL,
  CONSTRAINT "CK_fleet_VehicleDoc_Type" CHECK ("DocumentType" IN ('REGISTRATION', 'INSURANCE', 'INSPECTION', 'PERMIT', 'WARRANTY', 'TITLE', 'OTHER')),
  CONSTRAINT "FK_fleet_VehicleDoc_Vehicle" FOREIGN KEY ("VehicleId") REFERENCES fleet."Vehicle"("VehicleId"),
  CONSTRAINT "FK_fleet_VehicleDoc_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_fleet_VehicleDoc_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_fleet_VehicleDoc_DeletedBy" FOREIGN KEY ("DeletedByUserId") REFERENCES sec."User"("UserId")
);

CREATE INDEX IF NOT EXISTS "IX_fleet_VehicleDoc_Vehicle"
  ON fleet."VehicleDocument" ("VehicleId")
  WHERE "IsDeleted" = FALSE;

CREATE INDEX IF NOT EXISTS "IX_fleet_VehicleDoc_Expiry"
  ON fleet."VehicleDocument" ("ExpiresAt")
  WHERE "ExpiresAt" IS NOT NULL AND "IsDeleted" = FALSE;

COMMIT;

-- Source: 14_rbac.sql
-- ============================================================
-- Zentto PostgreSQL - 14_rbac.sql
-- Schema: sec (extension — Control de Acceso Basado en Roles)
-- Tablas: Permission, RolePermission, UserPermissionOverride,
--         PriceRestriction, ApprovalRule, ApprovalRequest,
--         ApprovalAction
-- ============================================================

BEGIN;

-- sec schema already exists from 01_core_foundation.sql

-- ============================================================
-- 1. sec."Permission"  (Permisos del sistema)
-- ============================================================
CREATE TABLE IF NOT EXISTS sec."Permission"(
  "PermissionId"          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "PermissionCode"        VARCHAR(80) NOT NULL,
  "PermissionName"        VARCHAR(200) NOT NULL,
  "Module"                VARCHAR(40) NOT NULL,
  "Category"              VARCHAR(40) NULL,
  "Description"           VARCHAR(500) NULL,
  "IsSystem"              BOOLEAN NOT NULL DEFAULT FALSE,
  "IsActive"              BOOLEAN NOT NULL DEFAULT TRUE,
  "CreatedAt"             TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"             TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId"       INT NULL,
  "UpdatedByUserId"       INT NULL,
  "IsDeleted"             BOOLEAN NOT NULL DEFAULT FALSE,
  "DeletedAt"             TIMESTAMP NULL,
  "DeletedByUserId"       INT NULL,
  CONSTRAINT "UQ_sec_Permission_Code" UNIQUE ("PermissionCode"),
  CONSTRAINT "FK_sec_Permission_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_sec_Permission_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_sec_Permission_DeletedBy" FOREIGN KEY ("DeletedByUserId") REFERENCES sec."User"("UserId")
);

CREATE INDEX IF NOT EXISTS "IX_sec_Permission_Module"
  ON sec."Permission" ("Module", "IsDeleted", "IsActive");

-- ============================================================
-- 2. sec."RolePermission"  (Permisos por rol)
-- ============================================================
CREATE TABLE IF NOT EXISTS sec."RolePermission"(
  "RolePermissionId"      BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "RoleId"                INT NOT NULL,
  "PermissionId"          BIGINT NOT NULL,
  "CanCreate"             BOOLEAN NOT NULL DEFAULT FALSE,
  "CanRead"               BOOLEAN NOT NULL DEFAULT TRUE,
  "CanUpdate"             BOOLEAN NOT NULL DEFAULT FALSE,
  "CanDelete"             BOOLEAN NOT NULL DEFAULT FALSE,
  "CanExport"             BOOLEAN NOT NULL DEFAULT FALSE,
  "CanApprove"            BOOLEAN NOT NULL DEFAULT FALSE,
  "CreatedAt"             TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"             TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId"       INT NULL,
  "UpdatedByUserId"       INT NULL,
  CONSTRAINT "UQ_sec_RolePermission" UNIQUE ("RoleId", "PermissionId"),
  CONSTRAINT "FK_sec_RolePermission_Role" FOREIGN KEY ("RoleId") REFERENCES sec."Role"("RoleId"),
  CONSTRAINT "FK_sec_RolePermission_Permission" FOREIGN KEY ("PermissionId") REFERENCES sec."Permission"("PermissionId"),
  CONSTRAINT "FK_sec_RolePermission_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_sec_RolePermission_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId")
);

CREATE INDEX IF NOT EXISTS "IX_sec_RolePermission_Role"
  ON sec."RolePermission" ("RoleId");

CREATE INDEX IF NOT EXISTS "IX_sec_RolePermission_Permission"
  ON sec."RolePermission" ("PermissionId");

-- ============================================================
-- 3. sec."UserPermissionOverride"  (Sobreescritura de permisos por usuario)
-- ============================================================
CREATE TABLE IF NOT EXISTS sec."UserPermissionOverride"(
  "UserPermissionOverrideId" BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "UserId"                INT NOT NULL,
  "PermissionId"          BIGINT NOT NULL,
  "OverrideType"          VARCHAR(10) NOT NULL DEFAULT 'GRANT',
  "CanCreate"             BOOLEAN NULL,
  "CanRead"               BOOLEAN NULL,
  "CanUpdate"             BOOLEAN NULL,
  "CanDelete"             BOOLEAN NULL,
  "CanExport"             BOOLEAN NULL,
  "CanApprove"            BOOLEAN NULL,
  "ExpiresAt"             TIMESTAMP NULL,
  "Reason"                VARCHAR(500) NULL,
  "CreatedAt"             TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"             TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId"       INT NULL,
  "UpdatedByUserId"       INT NULL,
  "IsDeleted"             BOOLEAN NOT NULL DEFAULT FALSE,
  "DeletedAt"             TIMESTAMP NULL,
  "DeletedByUserId"       INT NULL,
  CONSTRAINT "CK_sec_UPOverride_Type" CHECK ("OverrideType" IN ('GRANT', 'DENY')),
  CONSTRAINT "UQ_sec_UserPermOverride" UNIQUE ("UserId", "PermissionId"),
  CONSTRAINT "FK_sec_UPOverride_User" FOREIGN KEY ("UserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_sec_UPOverride_Permission" FOREIGN KEY ("PermissionId") REFERENCES sec."Permission"("PermissionId"),
  CONSTRAINT "FK_sec_UPOverride_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_sec_UPOverride_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_sec_UPOverride_DeletedBy" FOREIGN KEY ("DeletedByUserId") REFERENCES sec."User"("UserId")
);

CREATE INDEX IF NOT EXISTS "IX_sec_UPOverride_User"
  ON sec."UserPermissionOverride" ("UserId")
  WHERE "IsDeleted" = FALSE;

-- ============================================================
-- 4. sec."PriceRestriction"  (Restricciones de precios por rol/usuario)
-- ============================================================
CREATE TABLE IF NOT EXISTS sec."PriceRestriction"(
  "PriceRestrictionId"    BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"             INT NOT NULL,
  "RoleId"                INT NULL,
  "UserId"                INT NULL,
  "MaxDiscountPercent"    DECIMAL(5,2) NOT NULL DEFAULT 0,
  "MinMarginPercent"      DECIMAL(5,2) NULL,
  "MaxCreditAmount"       DECIMAL(18,2) NULL,
  "CurrencyCode"          CHAR(3) NULL,
  "CanOverridePrice"      BOOLEAN NOT NULL DEFAULT FALSE,
  "CanGiveFreeItems"      BOOLEAN NOT NULL DEFAULT FALSE,
  "RequiresApprovalAbove" DECIMAL(18,2) NULL,
  "IsActive"              BOOLEAN NOT NULL DEFAULT TRUE,
  "CreatedAt"             TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"             TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId"       INT NULL,
  "UpdatedByUserId"       INT NULL,
  "IsDeleted"             BOOLEAN NOT NULL DEFAULT FALSE,
  "DeletedAt"             TIMESTAMP NULL,
  "DeletedByUserId"       INT NULL,
  CONSTRAINT "FK_sec_PriceRestr_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId"),
  CONSTRAINT "FK_sec_PriceRestr_Role" FOREIGN KEY ("RoleId") REFERENCES sec."Role"("RoleId"),
  CONSTRAINT "FK_sec_PriceRestr_User" FOREIGN KEY ("UserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_sec_PriceRestr_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_sec_PriceRestr_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_sec_PriceRestr_DeletedBy" FOREIGN KEY ("DeletedByUserId") REFERENCES sec."User"("UserId")
);

CREATE INDEX IF NOT EXISTS "IX_sec_PriceRestr_Role"
  ON sec."PriceRestriction" ("RoleId")
  WHERE "RoleId" IS NOT NULL AND "IsDeleted" = FALSE;

CREATE INDEX IF NOT EXISTS "IX_sec_PriceRestr_User"
  ON sec."PriceRestriction" ("UserId")
  WHERE "UserId" IS NOT NULL AND "IsDeleted" = FALSE;

-- ============================================================
-- 5. sec."ApprovalRule"  (Reglas de aprobacion)
-- ============================================================
CREATE TABLE IF NOT EXISTS sec."ApprovalRule"(
  "ApprovalRuleId"        BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"             INT NOT NULL,
  "RuleCode"              VARCHAR(30) NOT NULL,
  "RuleName"              VARCHAR(200) NOT NULL,
  "DocumentType"          VARCHAR(30) NOT NULL,
  "Condition"             VARCHAR(30) NOT NULL DEFAULT 'AMOUNT_ABOVE',
  "ThresholdAmount"       DECIMAL(18,2) NULL,
  "CurrencyCode"          CHAR(3) NULL,
  "ApproverRoleId"        INT NULL,
  "ApproverUserId"        INT NULL,
  "RequiredApprovals"     INT NOT NULL DEFAULT 1,
  "AutoApproveBelow"      DECIMAL(18,2) NULL,
  "EscalateAfterHours"    INT NULL,
  "EscalateToUserId"      INT NULL,
  "IsActive"              BOOLEAN NOT NULL DEFAULT TRUE,
  "CreatedAt"             TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"             TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId"       INT NULL,
  "UpdatedByUserId"       INT NULL,
  "IsDeleted"             BOOLEAN NOT NULL DEFAULT FALSE,
  "DeletedAt"             TIMESTAMP NULL,
  "DeletedByUserId"       INT NULL,
  CONSTRAINT "CK_sec_ApprovalRule_Condition" CHECK ("Condition" IN ('AMOUNT_ABOVE', 'DISCOUNT_ABOVE', 'CREDIT_LIMIT', 'ALWAYS', 'CUSTOM')),
  CONSTRAINT "UQ_sec_ApprovalRule_Code" UNIQUE ("CompanyId", "RuleCode"),
  CONSTRAINT "FK_sec_ApprovalRule_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId"),
  CONSTRAINT "FK_sec_ApprovalRule_ApproverRole" FOREIGN KEY ("ApproverRoleId") REFERENCES sec."Role"("RoleId"),
  CONSTRAINT "FK_sec_ApprovalRule_ApproverUser" FOREIGN KEY ("ApproverUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_sec_ApprovalRule_EscalateTo" FOREIGN KEY ("EscalateToUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_sec_ApprovalRule_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_sec_ApprovalRule_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_sec_ApprovalRule_DeletedBy" FOREIGN KEY ("DeletedByUserId") REFERENCES sec."User"("UserId")
);

CREATE INDEX IF NOT EXISTS "IX_sec_ApprovalRule_Company"
  ON sec."ApprovalRule" ("CompanyId", "DocumentType", "IsActive")
  WHERE "IsDeleted" = FALSE;

-- ============================================================
-- 6. sec."ApprovalRequest"  (Solicitudes de aprobacion)
-- ============================================================
CREATE TABLE IF NOT EXISTS sec."ApprovalRequest"(
  "ApprovalRequestId"     BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"             INT NOT NULL,
  "ApprovalRuleId"        BIGINT NOT NULL,
  "DocumentType"          VARCHAR(30) NOT NULL,
  "DocumentId"            BIGINT NOT NULL,
  "DocumentNumber"        VARCHAR(60) NULL,
  "RequestedAmount"       DECIMAL(18,2) NULL,
  "CurrencyCode"          CHAR(3) NULL,
  "Status"                VARCHAR(20) NOT NULL DEFAULT 'PENDING',
  "RequestedByUserId"     INT NOT NULL,
  "RequestedAt"           TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "ResolvedAt"            TIMESTAMP NULL,
  "Notes"                 VARCHAR(500) NULL,
  "CreatedAt"             TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"             TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  CONSTRAINT "CK_sec_ApprovalRequest_Status" CHECK ("Status" IN ('PENDING', 'APPROVED', 'REJECTED', 'ESCALATED', 'CANCELLED', 'EXPIRED')),
  CONSTRAINT "FK_sec_ApprovalReq_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId"),
  CONSTRAINT "FK_sec_ApprovalReq_Rule" FOREIGN KEY ("ApprovalRuleId") REFERENCES sec."ApprovalRule"("ApprovalRuleId"),
  CONSTRAINT "FK_sec_ApprovalReq_RequestedBy" FOREIGN KEY ("RequestedByUserId") REFERENCES sec."User"("UserId")
);

CREATE INDEX IF NOT EXISTS "IX_sec_ApprovalReq_Status"
  ON sec."ApprovalRequest" ("CompanyId", "Status")
  WHERE "Status" = 'PENDING';

CREATE INDEX IF NOT EXISTS "IX_sec_ApprovalReq_Document"
  ON sec."ApprovalRequest" ("DocumentType", "DocumentId");

CREATE INDEX IF NOT EXISTS "IX_sec_ApprovalReq_RequestedBy"
  ON sec."ApprovalRequest" ("RequestedByUserId", "Status");

-- ============================================================
-- 7. sec."ApprovalAction"  (Acciones de aprobacion/rechazo)
-- ============================================================
CREATE TABLE IF NOT EXISTS sec."ApprovalAction"(
  "ApprovalActionId"      BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "ApprovalRequestId"     BIGINT NOT NULL,
  "ActionType"            VARCHAR(20) NOT NULL,
  "ActionByUserId"        INT NOT NULL,
  "ActionAt"              TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "Comments"              VARCHAR(500) NULL,
  CONSTRAINT "CK_sec_ApprovalAction_Type" CHECK ("ActionType" IN ('APPROVE', 'REJECT', 'ESCALATE', 'COMMENT', 'CANCEL')),
  CONSTRAINT "FK_sec_ApprovalAction_Request" FOREIGN KEY ("ApprovalRequestId") REFERENCES sec."ApprovalRequest"("ApprovalRequestId"),
  CONSTRAINT "FK_sec_ApprovalAction_ActionBy" FOREIGN KEY ("ActionByUserId") REFERENCES sec."User"("UserId")
);

CREATE INDEX IF NOT EXISTS "IX_sec_ApprovalAction_Request"
  ON sec."ApprovalAction" ("ApprovalRequestId", "ActionAt");

CREATE INDEX IF NOT EXISTS "IX_sec_ApprovalAction_User"
  ON sec."ApprovalAction" ("ActionByUserId", "ActionAt" DESC);

COMMIT;

-- Source: 13_triggers.sql
-- ============================================================
-- DatqBoxWeb PostgreSQL - 13_triggers.sql
-- Triggers: row_ver (ROWVERSION), updated_at automatico
-- ============================================================

-- Funcion reutilizable para incrementar RowVer en UPDATE
CREATE OR REPLACE FUNCTION trg_increment_row_ver()
-- +goose StatementBegin
RETURNS TRIGGER AS $$
BEGIN
    NEW."RowVer" := COALESCE(OLD."RowVer", 0) + 1;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Funcion reutilizable para auto-actualizar UpdatedAt
CREATE OR REPLACE FUNCTION trg_set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW."UpdatedAt" := NOW() AT TIME ZONE 'UTC';
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- sec."User"
-- ============================================================
DROP TRIGGER IF EXISTS "trg_sec_User_row_ver" ON sec."User";
CREATE TRIGGER "trg_sec_User_row_ver"
    BEFORE UPDATE ON sec."User"
    FOR EACH ROW EXECUTE FUNCTION trg_increment_row_ver();

DROP TRIGGER IF EXISTS "trg_sec_User_updated_at" ON sec."User";
CREATE TRIGGER "trg_sec_User_updated_at"
    BEFORE UPDATE ON sec."User"
    FOR EACH ROW EXECUTE FUNCTION trg_set_updated_at();

-- ============================================================
-- cfg."Company"
-- ============================================================
DROP TRIGGER IF EXISTS "trg_cfg_Company_row_ver" ON cfg."Company";
CREATE TRIGGER "trg_cfg_Company_row_ver"
    BEFORE UPDATE ON cfg."Company"
    FOR EACH ROW EXECUTE FUNCTION trg_increment_row_ver();

DROP TRIGGER IF EXISTS "trg_cfg_Company_updated_at" ON cfg."Company";
CREATE TRIGGER "trg_cfg_Company_updated_at"
    BEFORE UPDATE ON cfg."Company"
    FOR EACH ROW EXECUTE FUNCTION trg_set_updated_at();

-- ============================================================
-- cfg."Branch"
-- ============================================================
DROP TRIGGER IF EXISTS "trg_cfg_Branch_row_ver" ON cfg."Branch";
CREATE TRIGGER "trg_cfg_Branch_row_ver"
    BEFORE UPDATE ON cfg."Branch"
    FOR EACH ROW EXECUTE FUNCTION trg_increment_row_ver();

DROP TRIGGER IF EXISTS "trg_cfg_Branch_updated_at" ON cfg."Branch";
CREATE TRIGGER "trg_cfg_Branch_updated_at"
    BEFORE UPDATE ON cfg."Branch"
    FOR EACH ROW EXECUTE FUNCTION trg_set_updated_at();

-- ============================================================
-- master."Customer"
-- ============================================================
DROP TRIGGER IF EXISTS "trg_master_Customer_row_ver" ON master."Customer";
CREATE TRIGGER "trg_master_Customer_row_ver"
    BEFORE UPDATE ON master."Customer"
    FOR EACH ROW EXECUTE FUNCTION trg_increment_row_ver();

DROP TRIGGER IF EXISTS "trg_master_Customer_updated_at" ON master."Customer";
CREATE TRIGGER "trg_master_Customer_updated_at"
    BEFORE UPDATE ON master."Customer"
    FOR EACH ROW EXECUTE FUNCTION trg_set_updated_at();

-- ============================================================
-- master."Supplier"
-- ============================================================
DROP TRIGGER IF EXISTS "trg_master_Supplier_row_ver" ON master."Supplier";
CREATE TRIGGER "trg_master_Supplier_row_ver"
    BEFORE UPDATE ON master."Supplier"
    FOR EACH ROW EXECUTE FUNCTION trg_increment_row_ver();

DROP TRIGGER IF EXISTS "trg_master_Supplier_updated_at" ON master."Supplier";
CREATE TRIGGER "trg_master_Supplier_updated_at"
    BEFORE UPDATE ON master."Supplier"
    FOR EACH ROW EXECUTE FUNCTION trg_set_updated_at();

-- ============================================================
-- master."Employee"
-- ============================================================
DROP TRIGGER IF EXISTS "trg_master_Employee_row_ver" ON master."Employee";
CREATE TRIGGER "trg_master_Employee_row_ver"
    BEFORE UPDATE ON master."Employee"
    FOR EACH ROW EXECUTE FUNCTION trg_increment_row_ver();

DROP TRIGGER IF EXISTS "trg_master_Employee_updated_at" ON master."Employee";
CREATE TRIGGER "trg_master_Employee_updated_at"
    BEFORE UPDATE ON master."Employee"
    FOR EACH ROW EXECUTE FUNCTION trg_set_updated_at();

-- ============================================================
-- master."Product"
-- ============================================================
DROP TRIGGER IF EXISTS "trg_master_Product_row_ver" ON master."Product";
CREATE TRIGGER "trg_master_Product_row_ver"
    BEFORE UPDATE ON master."Product"
    FOR EACH ROW EXECUTE FUNCTION trg_increment_row_ver();

DROP TRIGGER IF EXISTS "trg_master_Product_updated_at" ON master."Product";
CREATE TRIGGER "trg_master_Product_updated_at"
    BEFORE UPDATE ON master."Product"
    FOR EACH ROW EXECUTE FUNCTION trg_set_updated_at();

-- ============================================================
-- acct."Account"
-- ============================================================
DROP TRIGGER IF EXISTS "trg_acct_Account_row_ver" ON acct."Account";
CREATE TRIGGER "trg_acct_Account_row_ver"
    BEFORE UPDATE ON acct."Account"
    FOR EACH ROW EXECUTE FUNCTION trg_increment_row_ver();

DROP TRIGGER IF EXISTS "trg_acct_Account_updated_at" ON acct."Account";
CREATE TRIGGER "trg_acct_Account_updated_at"
    BEFORE UPDATE ON acct."Account"
    FOR EACH ROW EXECUTE FUNCTION trg_set_updated_at();

-- ============================================================
-- acct."JournalEntry"
-- ============================================================
DROP TRIGGER IF EXISTS "trg_acct_JournalEntry_row_ver" ON acct."JournalEntry";
CREATE TRIGGER "trg_acct_JournalEntry_row_ver"
    BEFORE UPDATE ON acct."JournalEntry"
    FOR EACH ROW EXECUTE FUNCTION trg_increment_row_ver();

DROP TRIGGER IF EXISTS "trg_acct_JournalEntry_updated_at" ON acct."JournalEntry";
CREATE TRIGGER "trg_acct_JournalEntry_updated_at"
    BEFORE UPDATE ON acct."JournalEntry"
    FOR EACH ROW EXECUTE FUNCTION trg_set_updated_at();

-- ============================================================
-- acct."JournalEntryLine"
-- ============================================================
DROP TRIGGER IF EXISTS "trg_acct_JournalEntryLine_row_ver" ON acct."JournalEntryLine";
CREATE TRIGGER "trg_acct_JournalEntryLine_row_ver"
    BEFORE UPDATE ON acct."JournalEntryLine"
    FOR EACH ROW EXECUTE FUNCTION trg_increment_row_ver();

DROP TRIGGER IF EXISTS "trg_acct_JournalEntryLine_updated_at" ON acct."JournalEntryLine";
CREATE TRIGGER "trg_acct_JournalEntryLine_updated_at"
    BEFORE UPDATE ON acct."JournalEntryLine"
    FOR EACH ROW EXECUTE FUNCTION trg_set_updated_at();

-- ============================================================
-- ar."ReceivableDocument"
-- ============================================================
DROP TRIGGER IF EXISTS "trg_ar_ReceivableDocument_row_ver" ON ar."ReceivableDocument";
CREATE TRIGGER "trg_ar_ReceivableDocument_row_ver"
    BEFORE UPDATE ON ar."ReceivableDocument"
    FOR EACH ROW EXECUTE FUNCTION trg_increment_row_ver();

DROP TRIGGER IF EXISTS "trg_ar_ReceivableDocument_updated_at" ON ar."ReceivableDocument";
CREATE TRIGGER "trg_ar_ReceivableDocument_updated_at"
    BEFORE UPDATE ON ar."ReceivableDocument"
    FOR EACH ROW EXECUTE FUNCTION trg_set_updated_at();

-- ============================================================
-- ap."PayableDocument"
-- ============================================================
DROP TRIGGER IF EXISTS "trg_ap_PayableDocument_row_ver" ON ap."PayableDocument";
CREATE TRIGGER "trg_ap_PayableDocument_row_ver"
    BEFORE UPDATE ON ap."PayableDocument"
    FOR EACH ROW EXECUTE FUNCTION trg_increment_row_ver();

DROP TRIGGER IF EXISTS "trg_ap_PayableDocument_updated_at" ON ap."PayableDocument";
CREATE TRIGGER "trg_ap_PayableDocument_updated_at"
    BEFORE UPDATE ON ap."PayableDocument"
    FOR EACH ROW EXECUTE FUNCTION trg_set_updated_at();

-- ============================================================
-- fiscal."CountryConfig"
-- ============================================================
DROP TRIGGER IF EXISTS "trg_fiscal_CountryConfig_row_ver" ON fiscal."CountryConfig";
CREATE TRIGGER "trg_fiscal_CountryConfig_row_ver"
    BEFORE UPDATE ON fiscal."CountryConfig"
    FOR EACH ROW EXECUTE FUNCTION trg_increment_row_ver();

DROP TRIGGER IF EXISTS "trg_fiscal_CountryConfig_updated_at" ON fiscal."CountryConfig";
CREATE TRIGGER "trg_fiscal_CountryConfig_updated_at"
    BEFORE UPDATE ON fiscal."CountryConfig"
    FOR EACH ROW EXECUTE FUNCTION trg_set_updated_at();

-- ============================================================
-- fiscal."TaxRate"
-- ============================================================
DROP TRIGGER IF EXISTS "trg_fiscal_TaxRate_row_ver" ON fiscal."TaxRate";
CREATE TRIGGER "trg_fiscal_TaxRate_row_ver"
    BEFORE UPDATE ON fiscal."TaxRate"
    FOR EACH ROW EXECUTE FUNCTION trg_increment_row_ver();

DROP TRIGGER IF EXISTS "trg_fiscal_TaxRate_updated_at" ON fiscal."TaxRate";
CREATE TRIGGER "trg_fiscal_TaxRate_updated_at"
    BEFORE UPDATE ON fiscal."TaxRate"
    FOR EACH ROW EXECUTE FUNCTION trg_set_updated_at();

-- ============================================================
-- fiscal."InvoiceType"
-- ============================================================
DROP TRIGGER IF EXISTS "trg_fiscal_InvoiceType_row_ver" ON fiscal."InvoiceType";
CREATE TRIGGER "trg_fiscal_InvoiceType_row_ver"
    BEFORE UPDATE ON fiscal."InvoiceType"
    FOR EACH ROW EXECUTE FUNCTION trg_increment_row_ver();

DROP TRIGGER IF EXISTS "trg_fiscal_InvoiceType_updated_at" ON fiscal."InvoiceType";
CREATE TRIGGER "trg_fiscal_InvoiceType_updated_at"
    BEFORE UPDATE ON fiscal."InvoiceType"
    FOR EACH ROW EXECUTE FUNCTION trg_set_updated_at();

-- ============================================================
-- pos."WaitTicket"
-- ============================================================
DROP TRIGGER IF EXISTS "trg_pos_WaitTicket_row_ver" ON pos."WaitTicket";
CREATE TRIGGER "trg_pos_WaitTicket_row_ver"
    BEFORE UPDATE ON pos."WaitTicket"
    FOR EACH ROW EXECUTE FUNCTION trg_increment_row_ver();

DROP TRIGGER IF EXISTS "trg_pos_WaitTicket_updated_at" ON pos."WaitTicket";
CREATE TRIGGER "trg_pos_WaitTicket_updated_at"
    BEFORE UPDATE ON pos."WaitTicket"
    FOR EACH ROW EXECUTE FUNCTION trg_set_updated_at();

-- ============================================================
-- pos."SaleTicket"
-- ============================================================
DROP TRIGGER IF EXISTS "trg_pos_SaleTicket_row_ver" ON pos."SaleTicket";
CREATE TRIGGER "trg_pos_SaleTicket_row_ver"
    BEFORE UPDATE ON pos."SaleTicket"
    FOR EACH ROW EXECUTE FUNCTION trg_increment_row_ver();

DROP TRIGGER IF EXISTS "trg_pos_SaleTicket_updated_at" ON pos."SaleTicket";
CREATE TRIGGER "trg_pos_SaleTicket_updated_at"
    BEFORE UPDATE ON pos."SaleTicket"
    FOR EACH ROW EXECUTE FUNCTION trg_set_updated_at();

-- ============================================================
-- pos."FiscalCorrelative"
-- ============================================================
DROP TRIGGER IF EXISTS "trg_pos_FiscalCorrelative_row_ver" ON pos."FiscalCorrelative";
CREATE TRIGGER "trg_pos_FiscalCorrelative_row_ver"
    BEFORE UPDATE ON pos."FiscalCorrelative"
    FOR EACH ROW EXECUTE FUNCTION trg_increment_row_ver();

DROP TRIGGER IF EXISTS "trg_pos_FiscalCorrelative_updated_at" ON pos."FiscalCorrelative";
CREATE TRIGGER "trg_pos_FiscalCorrelative_updated_at"
    BEFORE UPDATE ON pos."FiscalCorrelative"
    FOR EACH ROW EXECUTE FUNCTION trg_set_updated_at();

-- ============================================================
-- rest."OrderTicket"
-- ============================================================
DROP TRIGGER IF EXISTS "trg_rest_OrderTicket_row_ver" ON rest."OrderTicket";
CREATE TRIGGER "trg_rest_OrderTicket_row_ver"
    BEFORE UPDATE ON rest."OrderTicket"
    FOR EACH ROW EXECUTE FUNCTION trg_increment_row_ver();

DROP TRIGGER IF EXISTS "trg_rest_OrderTicket_updated_at" ON rest."OrderTicket";
CREATE TRIGGER "trg_rest_OrderTicket_updated_at"
    BEFORE UPDATE ON rest."OrderTicket"
    FOR EACH ROW EXECUTE FUNCTION trg_set_updated_at();

-- ============================================================
-- rest."DiningTable"
-- ============================================================
DROP TRIGGER IF EXISTS "trg_rest_DiningTable_row_ver" ON rest."DiningTable";
CREATE TRIGGER "trg_rest_DiningTable_row_ver"
    BEFORE UPDATE ON rest."DiningTable"
    FOR EACH ROW EXECUTE FUNCTION trg_increment_row_ver();

DROP TRIGGER IF EXISTS "trg_rest_DiningTable_updated_at" ON rest."DiningTable";
CREATE TRIGGER "trg_rest_DiningTable_updated_at"
    BEFORE UPDATE ON rest."DiningTable"
    FOR EACH ROW EXECUTE FUNCTION trg_set_updated_at();

-- Source: 14_fulltext_search.sql
-- ============================================================
-- DatqBoxWeb PostgreSQL - 14_fulltext_search.sql
-- Fulltext search con tsvector + indice GIN
-- ============================================================

-- Columna de busqueda en master."Product"
ALTER TABLE master."Product" ADD COLUMN IF NOT EXISTS "SearchVector" TSVECTOR;

-- Trigger para actualizar SearchVector automaticamente
CREATE OR REPLACE FUNCTION trg_product_search_vector()
RETURNS TRIGGER AS $$
BEGIN
    NEW."SearchVector" :=
        setweight(to_tsvector('spanish', COALESCE(NEW."ProductCode", '')), 'A') ||
        setweight(to_tsvector('spanish', COALESCE(NEW."ProductName", '')), 'A') ||
        setweight(to_tsvector('spanish', COALESCE(NEW."CategoryCode", '')), 'B') ||
        setweight(to_tsvector('spanish', COALESCE(NEW."UnitCode", '')), 'C');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS "trg_master_Product_search" ON master."Product";
CREATE TRIGGER "trg_master_Product_search"
    BEFORE INSERT OR UPDATE ON master."Product"
    FOR EACH ROW EXECUTE FUNCTION trg_product_search_vector();

-- Indice GIN para busqueda rapida
CREATE INDEX IF NOT EXISTS "IX_master_Product_fulltext"
    ON master."Product" USING GIN ("SearchVector");

-- Indice trigram para busqueda fuzzy por codigo
CREATE INDEX IF NOT EXISTS "IX_master_Product_code_trgm"
    ON master."Product" USING GIN ("ProductCode" gin_trgm_ops);

-- Source: includes/sp/create_documentos_unificado.sql
-- ============================================================
-- DatqBoxWeb PostgreSQL - create_documentos_unificado.sql
-- Creacion de tablas y vistas de documentos unificados.
-- Tablas reales: ar.SalesDocument*, ap.PurchaseDocument*
-- Vistas legacy: public.DocumentosVenta*, public.DocumentosCompra*
-- Vistas alias:  doc.SalesDocument*, doc.PurchaseDocument*
-- ============================================================

CREATE SCHEMA IF NOT EXISTS ar;
CREATE SCHEMA IF NOT EXISTS ap;
CREATE SCHEMA IF NOT EXISTS doc;
CREATE SCHEMA IF NOT EXISTS acct;
CREATE SCHEMA IF NOT EXISTS master;

-- =============================================================================
-- SECCION 1: TABLAS ar.* (Documentos de Venta)
-- =============================================================================

-- 1.1 ar.SalesDocument
CREATE TABLE IF NOT EXISTS ar."SalesDocument" (
    "DocumentId"          INT GENERATED ALWAYS AS IDENTITY NOT NULL,
    "DocumentNumber"      VARCHAR(60)   NOT NULL,
    "SerialType"          VARCHAR(60)   NOT NULL DEFAULT '',
    "FiscalMemoryNumber"  VARCHAR(80)   NULL DEFAULT '',
    "OperationType"       VARCHAR(20)   NOT NULL,
    "CustomerCode"        VARCHAR(60)   NULL,
    "CustomerName"        VARCHAR(255)  NULL,
    "FiscalId"            VARCHAR(20)   NULL,
    "DocumentDate"        TIMESTAMP     NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "DueDate"             TIMESTAMP     NULL,
    "DocumentTime"        VARCHAR(20)   NULL DEFAULT TO_CHAR(NOW() AT TIME ZONE 'UTC', 'HH24:MI:SS'),
    "SubTotal"            NUMERIC(18,4) NULL DEFAULT 0,
    "TaxableAmount"       NUMERIC(18,4) NULL DEFAULT 0,
    "ExemptAmount"        NUMERIC(18,4) NULL DEFAULT 0,
    "TaxAmount"           NUMERIC(18,4) NULL DEFAULT 0,
    "TaxRate"             NUMERIC(8,4)  NULL DEFAULT 0,
    "TotalAmount"         NUMERIC(18,4) NULL DEFAULT 0,
    "DiscountAmount"      NUMERIC(18,4) NULL DEFAULT 0,
    "IsVoided"            BOOLEAN       NULL DEFAULT FALSE,
    "IsPaid"              VARCHAR(1)    NULL DEFAULT 'N',
    "IsInvoiced"          VARCHAR(1)    NULL DEFAULT 'N',
    "IsDelivered"         VARCHAR(1)    NULL DEFAULT 'N',
    "OriginDocumentNumber" VARCHAR(60)  NULL,
    "OriginDocumentType"  VARCHAR(20)   NULL,
    "ControlNumber"       VARCHAR(60)   NULL,
    "IsLegal"             BOOLEAN       NULL DEFAULT FALSE,
    "IsPrinted"           BOOLEAN       NULL DEFAULT FALSE,
    "Notes"               VARCHAR(500)  NULL,
    "Concept"             VARCHAR(255)  NULL,
    "PaymentTerms"        VARCHAR(255)  NULL,
    "ShipToAddress"       VARCHAR(255)  NULL,
    "SellerCode"          VARCHAR(60)   NULL,
    "DepartmentCode"      VARCHAR(50)   NULL,
    "LocationCode"        VARCHAR(100)  NULL,
    "CurrencyCode"        VARCHAR(20)   NULL DEFAULT 'BS',
    "ExchangeRate"        NUMERIC(18,6) NULL DEFAULT 1,
    "UserCode"            VARCHAR(60)   NULL DEFAULT 'API',
    "ReportDate"          TIMESTAMP     NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "HostName"            VARCHAR(255)  NULL,
    "VehiclePlate"        VARCHAR(20)   NULL,
    "Mileage"             INT           NULL,
    "TollAmount"          NUMERIC(18,4) NULL DEFAULT 0,
    "CreatedAt"           TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "UpdatedAt"           TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "CreatedByUserId"     INT           NULL,
    "UpdatedByUserId"     INT           NULL,
    "IsDeleted"           BOOLEAN       NOT NULL DEFAULT FALSE,
    "DeletedAt"           TIMESTAMP     NULL,
    "DeletedByUserId"     INT           NULL,
    CONSTRAINT "PK_SalesDocument" PRIMARY KEY ("DocumentId"),
    CONSTRAINT "UQ_SalesDocument_NumDocOp" UNIQUE ("DocumentNumber", "OperationType")
);

CREATE INDEX IF NOT EXISTS "IX_SalesDocument_Customer" ON ar."SalesDocument" ("CustomerCode");
CREATE INDEX IF NOT EXISTS "IX_SalesDocument_OpDate" ON ar."SalesDocument" ("OperationType", "DocumentDate" DESC) WHERE "IsDeleted" = FALSE;

-- 1.2 ar.SalesDocumentLine
CREATE TABLE IF NOT EXISTS ar."SalesDocumentLine" (
    "LineId"              INT GENERATED ALWAYS AS IDENTITY NOT NULL,
    "DocumentNumber"      VARCHAR(60)   NOT NULL,
    "SerialType"          VARCHAR(60)   NOT NULL DEFAULT '',
    "FiscalMemoryNumber"  VARCHAR(80)   NULL DEFAULT '',
    "OperationType"       VARCHAR(20)   NOT NULL,
    "LineNumber"          INT           NULL DEFAULT 0,
    "ProductCode"         VARCHAR(60)   NULL,
    "Description"         VARCHAR(255)  NULL,
    "AlternateCode"       VARCHAR(60)   NULL,
    "Quantity"            NUMERIC(18,4) NULL DEFAULT 0,
    "UnitPrice"           NUMERIC(18,4) NULL DEFAULT 0,
    "DiscountedPrice"     NUMERIC(18,4) NULL DEFAULT 0,
    "UnitCost"            NUMERIC(18,4) NULL DEFAULT 0,
    "SubTotal"            NUMERIC(18,4) NULL DEFAULT 0,
    "DiscountAmount"      NUMERIC(18,4) NULL DEFAULT 0,
    "TotalAmount"         NUMERIC(18,4) NULL DEFAULT 0,
    "TaxRate"             NUMERIC(8,4)  NULL DEFAULT 0,
    "TaxAmount"           NUMERIC(18,4) NULL DEFAULT 0,
    "IsVoided"            BOOLEAN       NULL DEFAULT FALSE,
    "RelatedRef"          VARCHAR(10)   NULL DEFAULT '0',
    "UserCode"            VARCHAR(60)   NULL DEFAULT 'API',
    "LineDate"            TIMESTAMP     NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "CreatedAt"           TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "UpdatedAt"           TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "CreatedByUserId"     INT           NULL,
    "UpdatedByUserId"     INT           NULL,
    "IsDeleted"           BOOLEAN       NOT NULL DEFAULT FALSE,
    "DeletedAt"           TIMESTAMP     NULL,
    "DeletedByUserId"     INT           NULL,
    CONSTRAINT "PK_SalesDocumentLine" PRIMARY KEY ("LineId")
);

CREATE INDEX IF NOT EXISTS "IX_SalesDocLine_DocKey" ON ar."SalesDocumentLine" ("DocumentNumber", "OperationType") WHERE "IsDeleted" = FALSE;
CREATE INDEX IF NOT EXISTS "IX_SalesDocLine_Product" ON ar."SalesDocumentLine" ("ProductCode");

-- 1.3 ar.SalesDocumentPayment
CREATE TABLE IF NOT EXISTS ar."SalesDocumentPayment" (
    "PaymentId"           INT GENERATED ALWAYS AS IDENTITY NOT NULL,
    "DocumentNumber"      VARCHAR(60)   NOT NULL,
    "SerialType"          VARCHAR(60)   NOT NULL DEFAULT '',
    "FiscalMemoryNumber"  VARCHAR(80)   NULL DEFAULT '',
    "OperationType"       VARCHAR(20)   NOT NULL DEFAULT 'FACT',
    "PaymentMethod"       VARCHAR(30)   NULL,
    "BankCode"            VARCHAR(60)   NULL,
    "PaymentNumber"       VARCHAR(60)   NULL,
    "Amount"              NUMERIC(18,4) NULL DEFAULT 0,
    "AmountBs"            NUMERIC(18,4) NULL DEFAULT 0,
    "ExchangeRate"        NUMERIC(18,6) NULL DEFAULT 1,
    "PaymentDate"         TIMESTAMP     NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "DueDate"             TIMESTAMP     NULL,
    "ReferenceNumber"     VARCHAR(100)  NULL,
    "UserCode"            VARCHAR(60)   NULL DEFAULT 'API',
    "CreatedAt"           TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "UpdatedAt"           TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "CreatedByUserId"     INT           NULL,
    "UpdatedByUserId"     INT           NULL,
    "IsDeleted"           BOOLEAN       NOT NULL DEFAULT FALSE,
    "DeletedAt"           TIMESTAMP     NULL,
    "DeletedByUserId"     INT           NULL,
    CONSTRAINT "PK_SalesDocumentPayment" PRIMARY KEY ("PaymentId")
);

CREATE INDEX IF NOT EXISTS "IX_SalesDocPay_DocKey" ON ar."SalesDocumentPayment" ("DocumentNumber", "OperationType") WHERE "IsDeleted" = FALSE;

-- =============================================================================
-- SECCION 2: TABLAS ap.* (Documentos de Compra)
-- =============================================================================

-- 2.1 ap.PurchaseDocument
CREATE TABLE IF NOT EXISTS ap."PurchaseDocument" (
    "DocumentId"          INT GENERATED ALWAYS AS IDENTITY NOT NULL,
    "DocumentNumber"      VARCHAR(60)   NOT NULL,
    "SerialType"          VARCHAR(60)   NOT NULL DEFAULT '',
    "FiscalMemoryNumber"  VARCHAR(80)   NULL DEFAULT '',
    "OperationType"       VARCHAR(20)   NOT NULL DEFAULT 'COMPRA',
    "SupplierCode"        VARCHAR(60)   NULL,
    "SupplierName"        VARCHAR(255)  NULL,
    "FiscalId"            VARCHAR(15)   NULL,
    "DocumentDate"        TIMESTAMP     NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "DueDate"             TIMESTAMP     NULL,
    "ReceiptDate"         TIMESTAMP     NULL,
    "PaymentDate"         TIMESTAMP     NULL,
    "DocumentTime"        VARCHAR(20)   NULL DEFAULT TO_CHAR(NOW() AT TIME ZONE 'UTC', 'HH24:MI:SS'),
    "SubTotal"            NUMERIC(18,4) NULL DEFAULT 0,
    "TaxableAmount"       NUMERIC(18,4) NULL DEFAULT 0,
    "ExemptAmount"        NUMERIC(18,4) NULL DEFAULT 0,
    "TaxAmount"           NUMERIC(18,4) NULL DEFAULT 0,
    "TaxRate"             NUMERIC(8,4)  NULL DEFAULT 0,
    "TotalAmount"         NUMERIC(18,4) NULL DEFAULT 0,
    "ExemptTotalAmount"   NUMERIC(18,4) NULL DEFAULT 0,
    "DiscountAmount"      NUMERIC(18,4) NULL DEFAULT 0,
    "IsVoided"            BOOLEAN       NULL DEFAULT FALSE,
    "IsPaid"              VARCHAR(1)    NULL DEFAULT 'N',
    "IsReceived"          VARCHAR(1)    NULL DEFAULT 'N',
    "IsLegal"             BOOLEAN       NULL DEFAULT FALSE,
    "OriginDocumentNumber" VARCHAR(60)  NULL,
    "ControlNumber"       VARCHAR(60)   NULL,
    "VoucherNumber"       VARCHAR(50)   NULL,
    "VoucherDate"         TIMESTAMP     NULL,
    "RetainedTax"         NUMERIC(18,4) NULL DEFAULT 0,
    "IsrCode"             VARCHAR(50)   NULL,
    "IsrAmount"           NUMERIC(18,4) NULL DEFAULT 0,
    "IsrSubjectAmount"    NUMERIC(18,4) NULL DEFAULT 0,
    "RetentionRate"       NUMERIC(8,4)  NULL DEFAULT 0,
    "ImportAmount"        NUMERIC(18,4) NULL DEFAULT 0,
    "ImportTax"           NUMERIC(18,4) NULL DEFAULT 0,
    "ImportBase"          NUMERIC(18,4) NULL DEFAULT 0,
    "FreightAmount"       NUMERIC(18,4) NULL DEFAULT 0,
    "Concept"             VARCHAR(255)  NULL,
    "Notes"               VARCHAR(500)  NULL,
    "OrderNumber"         VARCHAR(20)   NULL,
    "ReceivedBy"          VARCHAR(20)   NULL,
    "WarehouseCode"       VARCHAR(50)   NULL,
    "CurrencyCode"        VARCHAR(20)   NULL DEFAULT 'BS',
    "ExchangeRate"        NUMERIC(18,6) NULL DEFAULT 1,
    "UsdAmount"           NUMERIC(18,4) NULL DEFAULT 0,
    "UserCode"            VARCHAR(60)   NULL DEFAULT 'API',
    "ShortUserCode"       VARCHAR(10)   NULL,
    "ReportDate"          TIMESTAMP     NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "HostName"            VARCHAR(255)  NULL,
    "CreatedAt"           TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "UpdatedAt"           TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "CreatedByUserId"     INT           NULL,
    "UpdatedByUserId"     INT           NULL,
    "IsDeleted"           BOOLEAN       NOT NULL DEFAULT FALSE,
    "DeletedAt"           TIMESTAMP     NULL,
    "DeletedByUserId"     INT           NULL,
    CONSTRAINT "PK_PurchaseDocument" PRIMARY KEY ("DocumentId"),
    CONSTRAINT "UQ_PurchaseDocument_NumDocOp" UNIQUE ("DocumentNumber", "OperationType")
);

CREATE INDEX IF NOT EXISTS "IX_PurchaseDocument_Supplier" ON ap."PurchaseDocument" ("SupplierCode");
CREATE INDEX IF NOT EXISTS "IX_PurchaseDocument_OpDate" ON ap."PurchaseDocument" ("OperationType", "DocumentDate") WHERE "IsDeleted" = FALSE;

-- 2.2 ap.PurchaseDocumentLine
CREATE TABLE IF NOT EXISTS ap."PurchaseDocumentLine" (
    "LineId"              INT GENERATED ALWAYS AS IDENTITY NOT NULL,
    "DocumentNumber"      VARCHAR(60)   NOT NULL,
    "SerialType"          VARCHAR(60)   NOT NULL DEFAULT '',
    "FiscalMemoryNumber"  VARCHAR(80)   NULL DEFAULT '',
    "OperationType"       VARCHAR(20)   NOT NULL DEFAULT 'COMPRA',
    "LineNumber"          INT           NULL DEFAULT 0,
    "ProductCode"         VARCHAR(60)   NULL,
    "Description"         VARCHAR(255)  NULL,
    "Quantity"            NUMERIC(18,4) NULL DEFAULT 0,
    "UnitPrice"           NUMERIC(18,4) NULL DEFAULT 0,
    "UnitCost"            NUMERIC(18,4) NULL DEFAULT 0,
    "SubTotal"            NUMERIC(18,4) NULL DEFAULT 0,
    "DiscountAmount"      NUMERIC(18,4) NULL DEFAULT 0,
    "TotalAmount"         NUMERIC(18,4) NULL DEFAULT 0,
    "TaxRate"             NUMERIC(8,4)  NULL DEFAULT 0,
    "TaxAmount"           NUMERIC(18,4) NULL DEFAULT 0,
    "IsVoided"            BOOLEAN       NULL DEFAULT FALSE,
    "UserCode"            VARCHAR(60)   NULL DEFAULT 'API',
    "LineDate"            TIMESTAMP     NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "CreatedAt"           TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "UpdatedAt"           TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "CreatedByUserId"     INT           NULL,
    "UpdatedByUserId"     INT           NULL,
    "IsDeleted"           BOOLEAN       NOT NULL DEFAULT FALSE,
    "DeletedAt"           TIMESTAMP     NULL,
    "DeletedByUserId"     INT           NULL,
    CONSTRAINT "PK_PurchaseDocumentLine" PRIMARY KEY ("LineId")
);

CREATE INDEX IF NOT EXISTS "IX_PurchDocLine_DocKey" ON ap."PurchaseDocumentLine" ("DocumentNumber", "OperationType") WHERE "IsDeleted" = FALSE;
CREATE INDEX IF NOT EXISTS "IX_PurchDocLine_Product" ON ap."PurchaseDocumentLine" ("ProductCode");

-- 2.3 ap.PurchaseDocumentPayment
CREATE TABLE IF NOT EXISTS ap."PurchaseDocumentPayment" (
    "PaymentId"           INT GENERATED ALWAYS AS IDENTITY NOT NULL,
    "DocumentNumber"      VARCHAR(60)   NOT NULL,
    "SerialType"          VARCHAR(60)   NOT NULL DEFAULT '',
    "FiscalMemoryNumber"  VARCHAR(80)   NULL DEFAULT '',
    "OperationType"       VARCHAR(20)   NOT NULL DEFAULT 'COMPRA',
    "PaymentMethod"       VARCHAR(30)   NULL,
    "BankCode"            VARCHAR(60)   NULL,
    "PaymentNumber"       VARCHAR(60)   NULL,
    "Amount"              NUMERIC(18,4) NULL DEFAULT 0,
    "PaymentDate"         TIMESTAMP     NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "DueDate"             TIMESTAMP     NULL,
    "ReferenceNumber"     VARCHAR(100)  NULL,
    "UserCode"            VARCHAR(60)   NULL DEFAULT 'API',
    "CreatedAt"           TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "UpdatedAt"           TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "CreatedByUserId"     INT           NULL,
    "UpdatedByUserId"     INT           NULL,
    "IsDeleted"           BOOLEAN       NOT NULL DEFAULT FALSE,
    "DeletedAt"           TIMESTAMP     NULL,
    "DeletedByUserId"     INT           NULL,
    CONSTRAINT "PK_PurchaseDocumentPayment" PRIMARY KEY ("PaymentId")
);

CREATE INDEX IF NOT EXISTS "IX_PurchDocPay_DocKey" ON ap."PurchaseDocumentPayment" ("DocumentNumber", "OperationType") WHERE "IsDeleted" = FALSE;

-- =============================================================================
-- SECCION 3: VISTAS public.Documentos* (compatibilidad legacy)
-- =============================================================================

CREATE OR REPLACE VIEW public."DocumentosVenta" AS
SELECT
    "DocumentId" AS "ID", "DocumentNumber" AS "NUM_DOC", "SerialType" AS "SERIALTIPO",
    "FiscalMemoryNumber" AS "MEMORIA", "OperationType" AS "TIPO_OPERACION",
    "CustomerCode" AS "CODIGO", "CustomerName" AS "NOMBRE", "FiscalId" AS "RIF",
    "DocumentDate" AS "FECHA", "DueDate" AS "FECHA_VENCE", "DocumentTime" AS "HORA",
    "SubTotal"::DOUBLE PRECISION AS "SUBTOTAL", "TaxableAmount"::DOUBLE PRECISION AS "MONTO_GRA",
    "ExemptAmount"::DOUBLE PRECISION AS "MONTO_EXE", "TaxAmount"::DOUBLE PRECISION AS "IVA",
    "TaxRate"::DOUBLE PRECISION AS "ALICUOTA", "TotalAmount"::DOUBLE PRECISION AS "TOTAL",
    "DiscountAmount"::DOUBLE PRECISION AS "DESCUENTO",
    "IsVoided" AS "ANULADA", "IsPaid" AS "CANCELADA", "IsInvoiced" AS "FACTURADA",
    "IsDelivered" AS "ENTREGADA", "OriginDocumentNumber" AS "DOC_ORIGEN",
    "OriginDocumentType" AS "TIPO_DOC_ORIGEN", "ControlNumber" AS "NUM_CONTROL",
    "IsLegal" AS "LEGAL", "IsPrinted" AS "IMPRESA", "Notes" AS "OBSERV",
    "Concept" AS "CONCEPTO", "PaymentTerms" AS "TERMINOS", "ShipToAddress" AS "DESPACHAR",
    "SellerCode" AS "VENDEDOR", "DepartmentCode" AS "DEPARTAMENTO",
    "LocationCode" AS "LOCACION", "CurrencyCode" AS "MONEDA",
    "ExchangeRate"::DOUBLE PRECISION AS "TASA_CAMBIO",
    "UserCode" AS "COD_USUARIO", "ReportDate" AS "FECHA_REPORTE", "HostName" AS "COMPUTER",
    "VehiclePlate" AS "PLACAS", "Mileage" AS "KILOMETROS",
    "TollAmount"::DOUBLE PRECISION AS "PEAJE",
    "CreatedAt", "UpdatedAt", "CreatedByUserId", "UpdatedByUserId",
    "IsDeleted", "DeletedAt", "DeletedByUserId"
FROM ar."SalesDocument";

CREATE OR REPLACE VIEW public."DocumentosVentaDetalle" AS
SELECT
    "LineId" AS "ID", "DocumentNumber" AS "NUM_DOC", "SerialType" AS "SERIALTIPO",
    "FiscalMemoryNumber" AS "MEMORIA", "OperationType" AS "TIPO_OPERACION",
    "LineNumber" AS "RENGLON", "ProductCode" AS "COD_SERV", "Description" AS "DESCRIPCION",
    "AlternateCode" AS "COD_ALTERNO",
    "Quantity"::DOUBLE PRECISION AS "CANTIDAD", "UnitPrice"::DOUBLE PRECISION AS "PRECIO",
    "DiscountedPrice"::DOUBLE PRECISION AS "PRECIO_DESCUENTO",
    "UnitCost"::DOUBLE PRECISION AS "COSTO", "SubTotal"::DOUBLE PRECISION AS "SUBTOTAL",
    "DiscountAmount"::DOUBLE PRECISION AS "DESCUENTO",
    "TotalAmount"::DOUBLE PRECISION AS "TOTAL", "TaxRate"::DOUBLE PRECISION AS "ALICUOTA",
    "TaxAmount"::DOUBLE PRECISION AS "MONTO_IVA",
    "IsVoided" AS "ANULADA", "RelatedRef" AS "RELACIONADA",
    "UserCode" AS "CO_USUARIO", "LineDate" AS "FECHA",
    "CreatedAt", "UpdatedAt", "CreatedByUserId", "UpdatedByUserId",
    "IsDeleted", "DeletedAt", "DeletedByUserId"
FROM ar."SalesDocumentLine";

CREATE OR REPLACE VIEW public."DocumentosVentaPago" AS
SELECT
    "PaymentId" AS "ID", "DocumentNumber" AS "NUM_DOC", "SerialType" AS "SERIALTIPO",
    "FiscalMemoryNumber" AS "MEMORIA", "OperationType" AS "TIPO_OPERACION",
    "PaymentMethod" AS "TIPO_PAGO", "BankCode" AS "BANCO", "PaymentNumber" AS "NUMERO",
    "Amount"::DOUBLE PRECISION AS "MONTO", "AmountBs"::DOUBLE PRECISION AS "MONTO_BS",
    "ExchangeRate"::DOUBLE PRECISION AS "TASA_CAMBIO",
    "PaymentDate" AS "FECHA", "DueDate" AS "FECHA_VENCE",
    "ReferenceNumber" AS "REFERENCIA", "UserCode" AS "CO_USUARIO",
    "CreatedAt", "UpdatedAt", "CreatedByUserId", "UpdatedByUserId",
    "IsDeleted", "DeletedAt", "DeletedByUserId"
FROM ar."SalesDocumentPayment";

CREATE OR REPLACE VIEW public."DocumentosCompra" AS
SELECT
    "DocumentId" AS "ID", "DocumentNumber" AS "NUM_DOC", "SerialType" AS "SERIALTIPO",
    "FiscalMemoryNumber" AS "MEMORIA", "OperationType" AS "TIPO_OPERACION",
    "SupplierCode" AS "COD_PROVEEDOR", "SupplierName" AS "NOMBRE", "FiscalId" AS "RIF",
    "DocumentDate" AS "FECHA", "DueDate" AS "FECHA_VENCE",
    "ReceiptDate" AS "FECHA_RECIBO", "PaymentDate" AS "FECHA_PAGO",
    "DocumentTime" AS "HORA",
    "SubTotal"::DOUBLE PRECISION AS "SUBTOTAL", "TaxableAmount"::DOUBLE PRECISION AS "MONTO_GRA",
    "ExemptAmount"::DOUBLE PRECISION AS "MONTO_EXE", "TaxAmount"::DOUBLE PRECISION AS "IVA",
    "TaxRate"::DOUBLE PRECISION AS "ALICUOTA", "TotalAmount"::DOUBLE PRECISION AS "TOTAL",
    "ExemptTotalAmount"::DOUBLE PRECISION AS "EXENTO",
    "DiscountAmount"::DOUBLE PRECISION AS "DESCUENTO",
    "IsVoided" AS "ANULADA", "IsPaid" AS "CANCELADA", "IsReceived" AS "RECIBIDA",
    "IsLegal" AS "LEGAL", "OriginDocumentNumber" AS "DOC_ORIGEN",
    "ControlNumber" AS "NUM_CONTROL", "VoucherNumber" AS "NRO_COMPROBANTE",
    "VoucherDate" AS "FECHA_COMPROBANTE",
    "RetainedTax"::DOUBLE PRECISION AS "IVA_RETENIDO",
    "IsrCode" AS "ISLR", "IsrAmount"::DOUBLE PRECISION AS "MONTO_ISLR",
    "IsrCode" AS "CODIGO_ISLR", "IsrSubjectAmount"::DOUBLE PRECISION AS "SUJETO_ISLR",
    "RetentionRate"::DOUBLE PRECISION AS "TASA_RETENCION",
    "ImportAmount"::DOUBLE PRECISION AS "IMPORTACION",
    "ImportTax"::DOUBLE PRECISION AS "IVA_IMPORT",
    "ImportBase"::DOUBLE PRECISION AS "BASE_IMPORT",
    "FreightAmount"::DOUBLE PRECISION AS "FLETE",
    "Concept" AS "CONCEPTO", "Notes" AS "OBSERV", "OrderNumber" AS "PEDIDO",
    "ReceivedBy" AS "RECIBIDO", "WarehouseCode" AS "ALMACEN",
    "CurrencyCode" AS "MONEDA", "ExchangeRate"::DOUBLE PRECISION AS "TASA_CAMBIO",
    "UsdAmount"::DOUBLE PRECISION AS "PRECIO_DOLLAR",
    "UserCode" AS "COD_USUARIO", "ShortUserCode" AS "CO_USUARIO",
    "ReportDate" AS "FECHA_REPORTE", "HostName" AS "COMPUTER",
    "CreatedAt", "UpdatedAt", "CreatedByUserId", "UpdatedByUserId",
    "IsDeleted", "DeletedAt", "DeletedByUserId"
FROM ap."PurchaseDocument";

CREATE OR REPLACE VIEW public."DocumentosCompraDetalle" AS
SELECT
    "LineId" AS "ID", "DocumentNumber" AS "NUM_DOC", "SerialType" AS "SERIALTIPO",
    "FiscalMemoryNumber" AS "MEMORIA", "OperationType" AS "TIPO_OPERACION",
    "LineNumber" AS "RENGLON", "ProductCode" AS "COD_SERV", "Description" AS "DESCRIPCION",
    "Quantity"::DOUBLE PRECISION AS "CANTIDAD", "UnitPrice"::DOUBLE PRECISION AS "PRECIO",
    "UnitCost"::DOUBLE PRECISION AS "COSTO", "SubTotal"::DOUBLE PRECISION AS "SUBTOTAL",
    "DiscountAmount"::DOUBLE PRECISION AS "DESCUENTO",
    "TotalAmount"::DOUBLE PRECISION AS "TOTAL", "TaxRate"::DOUBLE PRECISION AS "ALICUOTA",
    "TaxAmount"::DOUBLE PRECISION AS "MONTO_IVA",
    "IsVoided" AS "ANULADA", "UserCode" AS "CO_USUARIO", "LineDate" AS "FECHA",
    "CreatedAt", "UpdatedAt", "CreatedByUserId", "UpdatedByUserId",
    "IsDeleted", "DeletedAt", "DeletedByUserId"
FROM ap."PurchaseDocumentLine";

CREATE OR REPLACE VIEW public."DocumentosCompraPago" AS
SELECT
    "PaymentId" AS "ID", "DocumentNumber" AS "NUM_DOC", "SerialType" AS "SERIALTIPO",
    "FiscalMemoryNumber" AS "MEMORIA", "OperationType" AS "TIPO_OPERACION",
    "PaymentMethod" AS "TIPO_PAGO", "BankCode" AS "BANCO", "PaymentNumber" AS "NUMERO",
    "Amount"::DOUBLE PRECISION AS "MONTO",
    "PaymentDate" AS "FECHA", "DueDate" AS "FECHA_VENCE",
    "ReferenceNumber" AS "REFERENCIA", "UserCode" AS "CO_USUARIO",
    "CreatedAt", "UpdatedAt", "CreatedByUserId", "UpdatedByUserId",
    "IsDeleted", "DeletedAt", "DeletedByUserId"
FROM ap."PurchaseDocumentPayment";

-- =============================================================================
-- SECCION 4: VISTAS doc.* (alias ingles)
-- =============================================================================

CREATE OR REPLACE VIEW doc."SalesDocument" AS
SELECT
    "ID" AS "DocumentId", "NUM_DOC" AS "DocumentNumber", "SERIALTIPO" AS "SerialType",
    "MEMORIA" AS "FiscalMemoryNumber", "TIPO_OPERACION" AS "OperationType",
    "CODIGO" AS "CustomerCode", "NOMBRE" AS "CustomerName", "RIF" AS "FiscalId",
    "FECHA" AS "IssueDate", "FECHA_VENCE" AS "DueDate", "HORA" AS "DocumentTime",
    "SUBTOTAL" AS "Subtotal", "MONTO_GRA" AS "TaxableAmount", "MONTO_EXE" AS "ExemptAmount",
    "IVA" AS "TaxAmount", "ALICUOTA" AS "TaxRate", "TOTAL" AS "TotalAmount",
    "DESCUENTO" AS "DiscountAmount", "ANULADA" AS "IsVoided", "CANCELADA" AS "IsCanceled",
    "FACTURADA" AS "IsInvoiced", "ENTREGADA" AS "IsDelivered",
    "DOC_ORIGEN" AS "SourceDocumentNumber", "TIPO_DOC_ORIGEN" AS "SourceDocumentType",
    "NUM_CONTROL" AS "ControlNumber", "OBSERV" AS "Notes", "CONCEPTO" AS "Concept",
    "MONEDA" AS "CurrencyCode", "TASA_CAMBIO" AS "ExchangeRate",
    "COD_USUARIO" AS "LegacyUserCode",
    "CreatedAt", "UpdatedAt", "CreatedByUserId", "UpdatedByUserId",
    "IsDeleted", "DeletedAt", "DeletedByUserId"
FROM public."DocumentosVenta";

CREATE OR REPLACE VIEW doc."SalesDocumentLine" AS
SELECT
    "ID" AS "LineId", "NUM_DOC" AS "DocumentNumber", "SERIALTIPO" AS "SerialType",
    "MEMORIA" AS "FiscalMemoryNumber", "TIPO_OPERACION" AS "DocumentType",
    "RENGLON" AS "LineNumber", "COD_SERV" AS "ProductCode", "DESCRIPCION" AS "Description",
    "COD_ALTERNO" AS "AlternateCode", "CANTIDAD" AS "Quantity", "PRECIO" AS "UnitPrice",
    "PRECIO_DESCUENTO" AS "DiscountUnitPrice", "COSTO" AS "UnitCost",
    "SUBTOTAL" AS "Subtotal", "DESCUENTO" AS "DiscountAmount", "TOTAL" AS "LineTotal",
    "ALICUOTA" AS "TaxRate", "MONTO_IVA" AS "TaxAmount", "ANULADA" AS "IsVoided",
    "CreatedAt", "UpdatedAt", "CreatedByUserId", "UpdatedByUserId",
    "IsDeleted", "DeletedAt", "DeletedByUserId"
FROM public."DocumentosVentaDetalle";

CREATE OR REPLACE VIEW doc."SalesDocumentPayment" AS
SELECT
    "ID" AS "PaymentId", "NUM_DOC" AS "DocumentNumber", "SERIALTIPO" AS "SerialType",
    "MEMORIA" AS "FiscalMemoryNumber", "TIPO_OPERACION" AS "DocumentType",
    "TIPO_PAGO" AS "PaymentType", "BANCO" AS "BankCode", "NUMERO" AS "ReferenceNumber",
    "MONTO" AS "Amount", "MONTO_BS" AS "AmountLocal", "TASA_CAMBIO" AS "ExchangeRate",
    "FECHA" AS "ApplyDate", "FECHA_VENCE" AS "DueDate", "REFERENCIA" AS "PaymentReference",
    "CreatedAt", "UpdatedAt", "CreatedByUserId", "UpdatedByUserId",
    "IsDeleted", "DeletedAt", "DeletedByUserId"
FROM public."DocumentosVentaPago";

CREATE OR REPLACE VIEW doc."PurchaseDocument" AS
SELECT
    "ID" AS "DocumentId", "NUM_DOC" AS "DocumentNumber", "SERIALTIPO" AS "SerialType",
    "MEMORIA" AS "FiscalMemoryNumber", "TIPO_OPERACION" AS "DocumentType",
    "COD_PROVEEDOR" AS "SupplierCode", "NOMBRE" AS "SupplierName", "RIF" AS "FiscalId",
    "FECHA" AS "IssueDate", "FECHA_VENCE" AS "DueDate",
    "SUBTOTAL" AS "Subtotal", "MONTO_GRA" AS "TaxableAmount", "MONTO_EXE" AS "ExemptAmount",
    "IVA" AS "TaxAmount", "ALICUOTA" AS "TaxRate", "TOTAL" AS "TotalAmount",
    "DESCUENTO" AS "DiscountAmount", "ANULADA" AS "IsVoided", "CANCELADA" AS "IsCanceled",
    "OBSERV" AS "Notes", "CONCEPTO" AS "Concept",
    "MONEDA" AS "CurrencyCode", "TASA_CAMBIO" AS "ExchangeRate",
    "COD_USUARIO" AS "LegacyUserCode",
    "CreatedAt", "UpdatedAt", "CreatedByUserId", "UpdatedByUserId",
    "IsDeleted", "DeletedAt", "DeletedByUserId"
FROM public."DocumentosCompra";

CREATE OR REPLACE VIEW doc."PurchaseDocumentLine" AS
SELECT
    "ID" AS "LineId", "NUM_DOC" AS "DocumentNumber", "SERIALTIPO" AS "SerialType",
    "MEMORIA" AS "FiscalMemoryNumber", "TIPO_OPERACION" AS "DocumentType",
    "RENGLON" AS "LineNumber", "COD_SERV" AS "ProductCode", "DESCRIPCION" AS "Description",
    "CANTIDAD" AS "Quantity", "PRECIO" AS "UnitPrice", "COSTO" AS "UnitCost",
    "SUBTOTAL" AS "Subtotal", "DESCUENTO" AS "DiscountAmount", "TOTAL" AS "LineTotal",
    "ALICUOTA" AS "TaxRate", "MONTO_IVA" AS "TaxAmount", "ANULADA" AS "IsVoided",
    "CreatedAt", "UpdatedAt", "CreatedByUserId", "UpdatedByUserId",
    "IsDeleted", "DeletedAt", "DeletedByUserId"
FROM public."DocumentosCompraDetalle";

CREATE OR REPLACE VIEW doc."PurchaseDocumentPayment" AS
SELECT
    "ID" AS "PaymentId", "NUM_DOC" AS "DocumentNumber", "SERIALTIPO" AS "SerialType",
    "MEMORIA" AS "FiscalMemoryNumber", "TIPO_OPERACION" AS "DocumentType",
    "TIPO_PAGO" AS "PaymentType", "BANCO" AS "BankCode", "NUMERO" AS "ReferenceNumber",
    "MONTO" AS "Amount", "FECHA" AS "ApplyDate", "FECHA_VENCE" AS "DueDate",
    "REFERENCIA" AS "PaymentReference",
    "CreatedAt", "UpdatedAt", "CreatedByUserId", "UpdatedByUserId",
    "IsDeleted", "DeletedAt", "DeletedByUserId"
FROM public."DocumentosCompraPago";

-- =============================================================================
-- SECCION 5: TABLAS AUXILIARES
-- =============================================================================

-- 5.1 acct.BankDeposit
CREATE TABLE IF NOT EXISTS acct."BankDeposit" (
    "BankDepositId"   INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    "Amount"          NUMERIC(18,4) NOT NULL DEFAULT 0,
    "CheckNumber"     VARCHAR(80)   NULL,
    "BankAccount"     VARCHAR(120)  NULL,
    "CustomerCode"    VARCHAR(60)   NULL,
    "IsRelated"       BOOLEAN       NOT NULL DEFAULT FALSE,
    "BankName"        VARCHAR(120)  NULL,
    "DocumentRef"     VARCHAR(60)   NULL,
    "OperationType"   VARCHAR(20)   NULL,
    "CreatedAt"       TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "UpdatedAt"       TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "CreatedByUserId" INT           NULL,
    "IsDeleted"       BOOLEAN       NOT NULL DEFAULT FALSE
);

CREATE INDEX IF NOT EXISTS "IX_BankDeposit_Customer" ON acct."BankDeposit" ("CustomerCode") WHERE "IsDeleted" = FALSE;

-- 5.2 master.AlternateStock
CREATE TABLE IF NOT EXISTS master."AlternateStock" (
    "AlternateStockId" INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    "ProductCode"      VARCHAR(80)   NOT NULL,
    "StockQty"         NUMERIC(18,4) NOT NULL DEFAULT 0,
    "CreatedAt"        TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "UpdatedAt"        TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "IsDeleted"        BOOLEAN       NOT NULL DEFAULT FALSE,
    CONSTRAINT "UQ_AlternateStock_ProductCode" UNIQUE ("ProductCode")
);

-- Source: includes/sp/create_activos_fijos.sql
/*
  Activos Fijos - Tablas canonicas (PostgreSQL)
  Esquema: acct
  ---------------------------------------------------
  Crea la estructura completa para gestion de activos fijos:
    1. acct."FixedAssetCategory"      - Categorias de activos con vida util por pais
    2. acct."FixedAsset"              - Registro maestro de activos fijos
    3. acct."FixedAssetDepreciation"  - Lineas de depreciacion mensual
    4. acct."FixedAssetImprovement"   - Mejoras / adiciones capitalizables
    5. acct."FixedAssetRevaluation"   - Revaluaciones por indice (inflacion)
  Seed data: categorias para VE y ES
*/

DO $$
DECLARE
  v_seed_company_id INT;
BEGIN

  -- ============================================================
  -- 0. Asegurar que el esquema acct existe
  -- ============================================================
  CREATE SCHEMA IF NOT EXISTS acct;
  RAISE NOTICE '>> Esquema acct verificado.';

  -- ============================================================
  -- 1. acct."FixedAssetCategory"
  --    Categorias maestras de activos fijos.
  --    Cada pais puede tener vida util distinta (VE vs ES).
  -- ============================================================
  CREATE TABLE IF NOT EXISTS acct."FixedAssetCategory" (
    "CategoryId"                INTEGER GENERATED ALWAYS AS IDENTITY NOT NULL PRIMARY KEY,
    "CompanyId"                 INTEGER NOT NULL,
    "CategoryCode"              VARCHAR(20) NOT NULL,
    "CategoryName"              VARCHAR(200) NOT NULL,
    "DefaultUsefulLifeMonths"   INTEGER NOT NULL,
    "DefaultDepreciationMethod" VARCHAR(20) NOT NULL DEFAULT 'STRAIGHT_LINE',
      -- Valores: STRAIGHT_LINE, DOUBLE_DECLINING, UNITS_PRODUCED, NONE
    "DefaultResidualPercent"    NUMERIC(5,2) DEFAULT 0,
    "DefaultAssetAccountCode"   VARCHAR(20) NULL,
    "DefaultDeprecAccountCode"  VARCHAR(20) NULL,
    "DefaultExpenseAccountCode" VARCHAR(20) NULL,
    "CountryCode"               VARCHAR(2) NULL,
    "IsActive"                  BOOLEAN DEFAULT TRUE,
    "IsDeleted"                 BOOLEAN DEFAULT FALSE,
    "CreatedAt"                 TIMESTAMP DEFAULT (NOW() AT TIME ZONE 'UTC'),
    CONSTRAINT "UQ_FixedAssetCategory" UNIQUE ("CompanyId", "CategoryCode", "CountryCode")
  );
  RAISE NOTICE '>> Tabla acct."FixedAssetCategory" verificada.';

  -- ============================================================
  -- 2. acct."FixedAsset"
  --    Registro maestro de cada activo fijo.
  --    Referencia cuentas contables y centro de costo.
  -- ============================================================
  CREATE TABLE IF NOT EXISTS acct."FixedAsset" (
    "AssetId"            BIGINT GENERATED ALWAYS AS IDENTITY NOT NULL PRIMARY KEY,
    "CompanyId"          INTEGER NOT NULL,
    "BranchId"           INTEGER NOT NULL DEFAULT 0,
    "AssetCode"          VARCHAR(40) NOT NULL,
    "Description"        VARCHAR(250) NOT NULL,
    "CategoryId"         INTEGER NULL
      CONSTRAINT "FK_FA_Category" REFERENCES acct."FixedAssetCategory"("CategoryId"),
    "AcquisitionDate"    DATE NOT NULL,
    "AcquisitionCost"    NUMERIC(18,2) NOT NULL,
    "ResidualValue"      NUMERIC(18,2) DEFAULT 0,
    "UsefulLifeMonths"   INTEGER NOT NULL,
    "DepreciationMethod" VARCHAR(20) NOT NULL DEFAULT 'STRAIGHT_LINE',
    "AssetAccountCode"   VARCHAR(20) NOT NULL,   -- ej: 1.2.01
    "DeprecAccountCode"  VARCHAR(20) NOT NULL,   -- ej: 1.2.02
    "ExpenseAccountCode" VARCHAR(20) NOT NULL,   -- ej: 6.1.xx
    "CostCenterCode"     VARCHAR(20) NULL,
    "Location"           VARCHAR(200) NULL,
    "SerialNumber"       VARCHAR(100) NULL,
    "Status"             VARCHAR(20) DEFAULT 'ACTIVE',
      -- Valores: ACTIVE, DISPOSED, FULLY_DEPRECIATED, IMPAIRED
    "DisposalDate"       DATE NULL,
    "DisposalAmount"     NUMERIC(18,2) NULL,
    "DisposalReason"     VARCHAR(500) NULL,
    "DisposalEntryId"    BIGINT NULL,
    "AcquisitionEntryId" BIGINT NULL,
    "UnitsCapacity"      INTEGER NULL,
    "CurrencyCode"       VARCHAR(3) DEFAULT 'VES',
    "IsDeleted"          BOOLEAN DEFAULT FALSE,
    "CreatedAt"          TIMESTAMP DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "UpdatedAt"          TIMESTAMP NULL,
    "CreatedBy"          VARCHAR(40) NULL,
    "UpdatedBy"          VARCHAR(40) NULL,
    CONSTRAINT "UQ_FixedAsset_Code" UNIQUE ("CompanyId", "AssetCode")
  );
  RAISE NOTICE '>> Tabla acct."FixedAsset" verificada.';

  -- ============================================================
  -- 3. acct."FixedAssetDepreciation"
  --    Lineas de depreciacion mensual por activo.
  --    Cada registro corresponde a un periodo YYYY-MM.
  -- ============================================================
  CREATE TABLE IF NOT EXISTS acct."FixedAssetDepreciation" (
    "DepreciationId"           BIGINT GENERATED ALWAYS AS IDENTITY NOT NULL PRIMARY KEY,
    "AssetId"                  BIGINT NOT NULL
      CONSTRAINT "FK_FAD_Asset" REFERENCES acct."FixedAsset"("AssetId"),
    "PeriodCode"               VARCHAR(7) NOT NULL,   -- YYYY-MM
    "DepreciationDate"         DATE NOT NULL,
    "Amount"                   NUMERIC(18,2) NOT NULL,
    "AccumulatedDepreciation"  NUMERIC(18,2) NOT NULL,
    "BookValue"                NUMERIC(18,2) NOT NULL,
    "JournalEntryId"           BIGINT NULL,
    "Status"                   VARCHAR(20) DEFAULT 'GENERATED',
      -- Valores: GENERATED, POSTED, REVERSED
    "CreatedAt"                TIMESTAMP DEFAULT (NOW() AT TIME ZONE 'UTC'),
    CONSTRAINT "UQ_AssetDeprec" UNIQUE ("AssetId", "PeriodCode")
  );
  RAISE NOTICE '>> Tabla acct."FixedAssetDepreciation" verificada.';

  -- ============================================================
  -- 4. acct."FixedAssetImprovement"
  --    Mejoras capitalizables que incrementan costo y/o vida util.
  -- ============================================================
  CREATE TABLE IF NOT EXISTS acct."FixedAssetImprovement" (
    "ImprovementId"        BIGINT GENERATED ALWAYS AS IDENTITY NOT NULL PRIMARY KEY,
    "AssetId"              BIGINT NOT NULL
      CONSTRAINT "FK_FAI_Asset" REFERENCES acct."FixedAsset"("AssetId"),
    "ImprovementDate"      DATE NOT NULL,
    "Description"          VARCHAR(500) NOT NULL,
    "Amount"               NUMERIC(18,2) NOT NULL,
    "AdditionalLifeMonths" INTEGER DEFAULT 0,
    "JournalEntryId"       BIGINT NULL,
    "CreatedBy"            VARCHAR(40) NULL,
    "CreatedAt"            TIMESTAMP DEFAULT (NOW() AT TIME ZONE 'UTC')
  );
  RAISE NOTICE '>> Tabla acct."FixedAssetImprovement" verificada.';

  -- ============================================================
  -- 5. acct."FixedAssetRevaluation"
  --    Revaluaciones por indice de precios (inflacion).
  --    Aplica principalmente en paises con alta inflacion (VE).
  -- ============================================================
  CREATE TABLE IF NOT EXISTS acct."FixedAssetRevaluation" (
    "RevaluationId"        BIGINT GENERATED ALWAYS AS IDENTITY NOT NULL PRIMARY KEY,
    "AssetId"              BIGINT NOT NULL
      CONSTRAINT "FK_FAR_Asset" REFERENCES acct."FixedAsset"("AssetId"),
    "RevaluationDate"      DATE NOT NULL,
    "PreviousCost"         NUMERIC(18,2) NOT NULL,
    "NewCost"              NUMERIC(18,2) NOT NULL,
    "PreviousAccumDeprec"  NUMERIC(18,2) NOT NULL,
    "NewAccumDeprec"       NUMERIC(18,2) NOT NULL,
    "IndexFactor"          NUMERIC(12,6) NOT NULL,
    "JournalEntryId"       BIGINT NULL,
    "CountryCode"          VARCHAR(2) NOT NULL,
    "CreatedBy"            VARCHAR(40) NULL,
    "CreatedAt"            TIMESTAMP DEFAULT (NOW() AT TIME ZONE 'UTC')
  );
  RAISE NOTICE '>> Tabla acct."FixedAssetRevaluation" verificada.';

  -- ============================================================
  -- 6. Seed data: Categorias de activos fijos (VE y ES)
  -- ============================================================
  RAISE NOTICE '>> Insertando categorias seed para VE y ES...';

  SELECT "CompanyId" INTO v_seed_company_id FROM acct."Account" LIMIT 1;
  IF v_seed_company_id IS NULL THEN
    v_seed_company_id := 1;
  END IF;

  -- Venezuela (VE)
  INSERT INTO acct."FixedAssetCategory" ("CompanyId", "CategoryCode", "CategoryName", "DefaultUsefulLifeMonths", "DefaultDepreciationMethod", "DefaultResidualPercent", "DefaultAssetAccountCode", "DefaultDeprecAccountCode", "DefaultExpenseAccountCode", "CountryCode")
  VALUES (v_seed_company_id, 'MOB', 'Mobiliario y Enseres', 120, 'STRAIGHT_LINE', 0, '1.2.01', '1.2.02', '6.1.06', 'VE')
  ON CONFLICT ("CompanyId", "CategoryCode", "CountryCode") DO NOTHING;

  INSERT INTO acct."FixedAssetCategory" ("CompanyId", "CategoryCode", "CategoryName", "DefaultUsefulLifeMonths", "DefaultDepreciationMethod", "DefaultResidualPercent", "DefaultAssetAccountCode", "DefaultDeprecAccountCode", "DefaultExpenseAccountCode", "CountryCode")
  VALUES (v_seed_company_id, 'VEH', 'Vehículos', 60, 'STRAIGHT_LINE', 0, '1.2.01', '1.2.02', '6.1.06', 'VE')
  ON CONFLICT ("CompanyId", "CategoryCode", "CountryCode") DO NOTHING;

  INSERT INTO acct."FixedAssetCategory" ("CompanyId", "CategoryCode", "CategoryName", "DefaultUsefulLifeMonths", "DefaultDepreciationMethod", "DefaultResidualPercent", "DefaultAssetAccountCode", "DefaultDeprecAccountCode", "DefaultExpenseAccountCode", "CountryCode")
  VALUES (v_seed_company_id, 'MAQ', 'Maquinaria y Equipos', 120, 'STRAIGHT_LINE', 0, '1.2.01', '1.2.02', '6.1.06', 'VE')
  ON CONFLICT ("CompanyId", "CategoryCode", "CountryCode") DO NOTHING;

  INSERT INTO acct."FixedAssetCategory" ("CompanyId", "CategoryCode", "CategoryName", "DefaultUsefulLifeMonths", "DefaultDepreciationMethod", "DefaultResidualPercent", "DefaultAssetAccountCode", "DefaultDeprecAccountCode", "DefaultExpenseAccountCode", "CountryCode")
  VALUES (v_seed_company_id, 'EDI', 'Edificios y Construcciones', 240, 'STRAIGHT_LINE', 0, '1.2.01', '1.2.02', '6.1.06', 'VE')
  ON CONFLICT ("CompanyId", "CategoryCode", "CountryCode") DO NOTHING;

  INSERT INTO acct."FixedAssetCategory" ("CompanyId", "CategoryCode", "CategoryName", "DefaultUsefulLifeMonths", "DefaultDepreciationMethod", "DefaultResidualPercent", "DefaultAssetAccountCode", "DefaultDeprecAccountCode", "DefaultExpenseAccountCode", "CountryCode")
  VALUES (v_seed_company_id, 'TER', 'Terrenos', 0, 'NONE', 0, '1.2.01', NULL, NULL, 'VE')
  ON CONFLICT ("CompanyId", "CategoryCode", "CountryCode") DO NOTHING;

  INSERT INTO acct."FixedAssetCategory" ("CompanyId", "CategoryCode", "CategoryName", "DefaultUsefulLifeMonths", "DefaultDepreciationMethod", "DefaultResidualPercent", "DefaultAssetAccountCode", "DefaultDeprecAccountCode", "DefaultExpenseAccountCode", "CountryCode")
  VALUES (v_seed_company_id, 'EQU', 'Equipos Informáticos', 36, 'STRAIGHT_LINE', 0, '1.2.01', '1.2.02', '6.1.06', 'VE')
  ON CONFLICT ("CompanyId", "CategoryCode", "CountryCode") DO NOTHING;

  INSERT INTO acct."FixedAssetCategory" ("CompanyId", "CategoryCode", "CategoryName", "DefaultUsefulLifeMonths", "DefaultDepreciationMethod", "DefaultResidualPercent", "DefaultAssetAccountCode", "DefaultDeprecAccountCode", "DefaultExpenseAccountCode", "CountryCode")
  VALUES (v_seed_company_id, 'INT', 'Intangibles y Software', 60, 'STRAIGHT_LINE', 0, '1.2.03', '1.2.03', '6.1.06', 'VE')
  ON CONFLICT ("CompanyId", "CategoryCode", "CountryCode") DO NOTHING;

  INSERT INTO acct."FixedAssetCategory" ("CompanyId", "CategoryCode", "CategoryName", "DefaultUsefulLifeMonths", "DefaultDepreciationMethod", "DefaultResidualPercent", "DefaultAssetAccountCode", "DefaultDeprecAccountCode", "DefaultExpenseAccountCode", "CountryCode")
  VALUES (v_seed_company_id, 'HER', 'Herramientas', 60, 'STRAIGHT_LINE', 0, '1.2.01', '1.2.02', '6.1.06', 'VE')
  ON CONFLICT ("CompanyId", "CategoryCode", "CountryCode") DO NOTHING;

  RAISE NOTICE '   VE: 8 categorias verificadas/insertadas.';

  -- España (ES)
  INSERT INTO acct."FixedAssetCategory" ("CompanyId", "CategoryCode", "CategoryName", "DefaultUsefulLifeMonths", "DefaultDepreciationMethod", "DefaultResidualPercent", "DefaultAssetAccountCode", "DefaultDeprecAccountCode", "DefaultExpenseAccountCode", "CountryCode")
  VALUES (v_seed_company_id, 'MOB', 'Mobiliario y Enseres', 120, 'STRAIGHT_LINE', 0, '1.2.01', '1.2.02', '6.1.06', 'ES')
  ON CONFLICT ("CompanyId", "CategoryCode", "CountryCode") DO NOTHING;

  INSERT INTO acct."FixedAssetCategory" ("CompanyId", "CategoryCode", "CategoryName", "DefaultUsefulLifeMonths", "DefaultDepreciationMethod", "DefaultResidualPercent", "DefaultAssetAccountCode", "DefaultDeprecAccountCode", "DefaultExpenseAccountCode", "CountryCode")
  VALUES (v_seed_company_id, 'VEH', 'Vehículos', 72, 'STRAIGHT_LINE', 0, '1.2.01', '1.2.02', '6.1.06', 'ES')
  ON CONFLICT ("CompanyId", "CategoryCode", "CountryCode") DO NOTHING;

  INSERT INTO acct."FixedAssetCategory" ("CompanyId", "CategoryCode", "CategoryName", "DefaultUsefulLifeMonths", "DefaultDepreciationMethod", "DefaultResidualPercent", "DefaultAssetAccountCode", "DefaultDeprecAccountCode", "DefaultExpenseAccountCode", "CountryCode")
  VALUES (v_seed_company_id, 'MAQ', 'Maquinaria y Equipos', 144, 'STRAIGHT_LINE', 0, '1.2.01', '1.2.02', '6.1.06', 'ES')
  ON CONFLICT ("CompanyId", "CategoryCode", "CountryCode") DO NOTHING;

  INSERT INTO acct."FixedAssetCategory" ("CompanyId", "CategoryCode", "CategoryName", "DefaultUsefulLifeMonths", "DefaultDepreciationMethod", "DefaultResidualPercent", "DefaultAssetAccountCode", "DefaultDeprecAccountCode", "DefaultExpenseAccountCode", "CountryCode")
  VALUES (v_seed_company_id, 'EDI', 'Edificios y Construcciones', 396, 'STRAIGHT_LINE', 0, '1.2.01', '1.2.02', '6.1.06', 'ES')
  ON CONFLICT ("CompanyId", "CategoryCode", "CountryCode") DO NOTHING;

  INSERT INTO acct."FixedAssetCategory" ("CompanyId", "CategoryCode", "CategoryName", "DefaultUsefulLifeMonths", "DefaultDepreciationMethod", "DefaultResidualPercent", "DefaultAssetAccountCode", "DefaultDeprecAccountCode", "DefaultExpenseAccountCode", "CountryCode")
  VALUES (v_seed_company_id, 'TER', 'Terrenos', 0, 'NONE', 0, '1.2.01', NULL, NULL, 'ES')
  ON CONFLICT ("CompanyId", "CategoryCode", "CountryCode") DO NOTHING;

  INSERT INTO acct."FixedAssetCategory" ("CompanyId", "CategoryCode", "CategoryName", "DefaultUsefulLifeMonths", "DefaultDepreciationMethod", "DefaultResidualPercent", "DefaultAssetAccountCode", "DefaultDeprecAccountCode", "DefaultExpenseAccountCode", "CountryCode")
  VALUES (v_seed_company_id, 'EQU', 'Equipos Informáticos', 48, 'STRAIGHT_LINE', 0, '1.2.01', '1.2.02', '6.1.06', 'ES')
  ON CONFLICT ("CompanyId", "CategoryCode", "CountryCode") DO NOTHING;

  INSERT INTO acct."FixedAssetCategory" ("CompanyId", "CategoryCode", "CategoryName", "DefaultUsefulLifeMonths", "DefaultDepreciationMethod", "DefaultResidualPercent", "DefaultAssetAccountCode", "DefaultDeprecAccountCode", "DefaultExpenseAccountCode", "CountryCode")
  VALUES (v_seed_company_id, 'INT', 'Intangibles y Software', 60, 'STRAIGHT_LINE', 0, '1.2.03', '1.2.03', '6.1.06', 'ES')
  ON CONFLICT ("CompanyId", "CategoryCode", "CountryCode") DO NOTHING;

  INSERT INTO acct."FixedAssetCategory" ("CompanyId", "CategoryCode", "CategoryName", "DefaultUsefulLifeMonths", "DefaultDepreciationMethod", "DefaultResidualPercent", "DefaultAssetAccountCode", "DefaultDeprecAccountCode", "DefaultExpenseAccountCode", "CountryCode")
  VALUES (v_seed_company_id, 'HER', 'Herramientas', 96, 'STRAIGHT_LINE', 0, '1.2.01', '1.2.02', '6.1.06', 'ES')
  ON CONFLICT ("CompanyId", "CategoryCode", "CountryCode") DO NOTHING;

  RAISE NOTICE '   ES: 8 categorias verificadas/insertadas.';

  -- ============================================================
  -- INDICES
  -- ============================================================
  CREATE INDEX IF NOT EXISTS "IX_FixedAsset_CompanyCode"
    ON acct."FixedAsset" ("CompanyId", "AssetCode");

  CREATE INDEX IF NOT EXISTS "IX_FixedAsset_CategoryId"
    ON acct."FixedAsset" ("CategoryId");

  CREATE INDEX IF NOT EXISTS "IX_FixedAssetDepreciation_AssetPeriod"
    ON acct."FixedAssetDepreciation" ("AssetId", "PeriodCode");

  RAISE NOTICE '>> Activos fijos: script completado exitosamente.';

EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE 'ERROR en create_activos_fijos.sql: %', SQLERRM;
  RAISE;
END $$;
-- +goose StatementEnd

-- Source: includes/sp/alter_bank_movement_journal.sql
-- =============================================================================
-- ALTER: Agregar JournalEntryId a fin.BankMovement (PostgreSQL)
-- Permite vincular movimientos bancarios con asientos contables autogenerados.
-- =============================================================================

-- +goose StatementBegin
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'fin'
          AND table_name   = 'BankMovement'
          AND column_name  = 'JournalEntryId'
    ) THEN
        ALTER TABLE fin."BankMovement"
            ADD COLUMN "JournalEntryId" BIGINT NULL;

        ALTER TABLE fin."BankMovement"
            ADD CONSTRAINT "FK_fin_BankMovement_JournalEntry"
            FOREIGN KEY ("JournalEntryId")
            REFERENCES acct."JournalEntry"("JournalEntryId");

        CREATE INDEX "IX_fin_BankMovement_JournalEntry"
            ON fin."BankMovement" ("JournalEntryId")
            WHERE "JournalEntryId" IS NOT NULL;
    END IF;
END $$;
-- +goose StatementEnd

-- Source: includes/sp/create_hr_rrhh_tables.sql
-- ============================================================================
-- create_hr_rrhh_tables.sql
-- Tablas HR: RRHH Salud, Beneficios, Comites de Seguridad, Caja de Ahorro
-- Convertido de T-SQL a PostgreSQL
-- Fecha: 2026-03-16
-- ============================================================================

-- ============================================================
-- hr."MedicalExam"
-- ============================================================
CREATE TABLE IF NOT EXISTS hr."MedicalExam" (
  "MedicalExamId"  INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"      INT              NOT NULL,
  "EmployeeId"     BIGINT           NULL,
  "EmployeeCode"   VARCHAR(24)      NOT NULL,
  "EmployeeName"   VARCHAR(200)     NOT NULL,
  "ExamType"       VARCHAR(20)      NOT NULL,
  "ExamDate"       DATE             NOT NULL,
  "NextDueDate"    DATE             NULL,
  "Result"         VARCHAR(20)      NOT NULL DEFAULT 'PENDING',
  "Restrictions"   VARCHAR(500)     NULL,
  "PhysicianName"  VARCHAR(200)     NULL,
  "ClinicName"     VARCHAR(200)     NULL,
  "DocumentUrl"    VARCHAR(500)     NULL,
  "Notes"          VARCHAR(500)     NULL,
  "CreatedAt"      TIMESTAMP        NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"      TIMESTAMP        NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  CONSTRAINT "FK_hr_MedicalExam_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId"),
  CONSTRAINT "FK_hr_MedicalExam_Employee" FOREIGN KEY ("EmployeeId") REFERENCES master."Employee"("EmployeeId")
);

CREATE INDEX IF NOT EXISTS "IX_MedExam_Company_Type"
  ON hr."MedicalExam" ("CompanyId", "ExamType", "ExamDate" DESC);

CREATE INDEX IF NOT EXISTS "IX_MedExam_NextDue"
  ON hr."MedicalExam" ("CompanyId", "NextDueDate")
  WHERE "NextDueDate" IS NOT NULL;

CREATE INDEX IF NOT EXISTS "IX_MedExam_Employee"
  ON hr."MedicalExam" ("EmployeeCode", "CompanyId");

-- ============================================================
-- hr."MedicalOrder"
-- ============================================================
CREATE TABLE IF NOT EXISTS hr."MedicalOrder" (
  "MedicalOrderId"  INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"       INT              NOT NULL,
  "EmployeeId"      BIGINT           NULL,
  "EmployeeCode"    VARCHAR(24)      NOT NULL,
  "EmployeeName"    VARCHAR(200)     NOT NULL,
  "OrderType"       VARCHAR(20)      NOT NULL,
  "OrderDate"       DATE             NOT NULL,
  "Diagnosis"       VARCHAR(500)     NULL,
  "PhysicianName"   VARCHAR(200)     NULL,
  "Prescriptions"   TEXT             NULL,
  "EstimatedCost"   NUMERIC(18,2)    NULL,
  "ApprovedAmount"  NUMERIC(18,2)    NULL,
  "Status"          VARCHAR(15)      NOT NULL DEFAULT 'PENDIENTE',
  "ApprovedBy"      INT              NULL,
  "ApprovedAt"      TIMESTAMP        NULL,
  "DocumentUrl"     VARCHAR(500)     NULL,
  "Notes"           VARCHAR(500)     NULL,
  "CreatedAt"       TIMESTAMP        NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"       TIMESTAMP        NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  CONSTRAINT "FK_hr_MedicalOrder_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId"),
  CONSTRAINT "FK_hr_MedicalOrder_Employee" FOREIGN KEY ("EmployeeId") REFERENCES master."Employee"("EmployeeId")
);

CREATE INDEX IF NOT EXISTS "IX_MedOrder_Company_Status"
  ON hr."MedicalOrder" ("CompanyId", "Status", "OrderDate" DESC);

CREATE INDEX IF NOT EXISTS "IX_MedOrder_Employee"
  ON hr."MedicalOrder" ("EmployeeCode", "CompanyId");

-- ============================================================
-- hr."OccupationalHealth"
-- ============================================================
CREATE TABLE IF NOT EXISTS hr."OccupationalHealth" (
  "OccupationalHealthId"       INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"                  INT              NOT NULL,
  "CountryCode"                CHAR(2)          NOT NULL,
  "RecordType"                 VARCHAR(25)      NOT NULL,
  "EmployeeId"                 BIGINT           NULL,
  "EmployeeCode"               VARCHAR(24)      NULL,
  "EmployeeName"               VARCHAR(200)     NULL,
  "OccurrenceDate"             TIMESTAMP        NOT NULL,
  "ReportDeadline"             TIMESTAMP        NULL,
  "ReportedDate"               TIMESTAMP        NULL,
  "Severity"                   VARCHAR(15)      NULL,
  "BodyPartAffected"           VARCHAR(100)     NULL,
  "DaysLost"                   INT              NULL,
  "Location"                   VARCHAR(200)     NULL,
  "Description"                TEXT             NULL,
  "RootCause"                  VARCHAR(500)     NULL,
  "CorrectiveAction"           VARCHAR(500)     NULL,
  "InvestigationDueDate"       DATE             NULL,
  "InvestigationCompletedDate" DATE             NULL,
  "InstitutionReference"       VARCHAR(100)     NULL,
  "Status"                     VARCHAR(15)      NOT NULL DEFAULT 'OPEN',
  "DocumentUrl"                VARCHAR(500)     NULL,
  "Notes"                      VARCHAR(500)     NULL,
  "CreatedBy"                  INT              NULL,
  "CreatedAt"                  TIMESTAMP        NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"                  TIMESTAMP        NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  CONSTRAINT "FK_hr_OccHealth_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId"),
  CONSTRAINT "FK_hr_OccHealth_Employee" FOREIGN KEY ("EmployeeId") REFERENCES master."Employee"("EmployeeId")
);

CREATE INDEX IF NOT EXISTS "IX_OccHealth_Company_Status"
  ON hr."OccupationalHealth" ("CompanyId", "Status");

CREATE INDEX IF NOT EXISTS "IX_OccHealth_Company_RecordType"
  ON hr."OccupationalHealth" ("CompanyId", "RecordType", "OccurrenceDate" DESC);

CREATE INDEX IF NOT EXISTS "IX_OccHealth_Employee"
  ON hr."OccupationalHealth" ("EmployeeId")
  WHERE "EmployeeId" IS NOT NULL;

-- ============================================================
-- hr."ProfitSharing"
-- ============================================================
CREATE TABLE IF NOT EXISTS hr."ProfitSharing" (
  "ProfitSharingId"      INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"            INT              NOT NULL,
  "BranchId"             INT              NOT NULL,
  "FiscalYear"           INT              NOT NULL,
  "DaysGranted"          INT              NOT NULL,
  "TotalCompanyProfits"  NUMERIC(18,2)    NULL,
  "Status"               VARCHAR(20)      NOT NULL DEFAULT 'BORRADOR',
  "CreatedBy"            INT              NULL,
  "CreatedAt"            TIMESTAMP        NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "ApprovedBy"           INT              NULL,
  "ApprovedAt"           TIMESTAMP        NULL,
  "UpdatedAt"            TIMESTAMP        NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  CONSTRAINT "CK_ProfitSharing_Days"   CHECK ("DaysGranted" >= 30 AND "DaysGranted" <= 120),
  CONSTRAINT "CK_ProfitSharing_Status" CHECK ("Status" IN ('CERRADA','PROCESADA','CALCULADA','BORRADOR')),
  CONSTRAINT "FK_hr_ProfitSharing_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId"),
  CONSTRAINT "FK_hr_ProfitSharing_Branch"  FOREIGN KEY ("BranchId")  REFERENCES cfg."Branch"("BranchId")
);

-- ============================================================
-- hr."ProfitSharingLine"
-- ============================================================
CREATE TABLE IF NOT EXISTS hr."ProfitSharingLine" (
  "LineId"           INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "ProfitSharingId"  INT              NOT NULL,
  "EmployeeId"       BIGINT           NULL,
  "EmployeeCode"     VARCHAR(24)      NOT NULL,
  "EmployeeName"     VARCHAR(200)     NOT NULL,
  "MonthlySalary"    NUMERIC(18,2)    NOT NULL,
  "DailySalary"      NUMERIC(18,2)    NOT NULL,
  "DaysWorked"       INT              NOT NULL,
  "DaysEntitled"     INT              NOT NULL,
  "GrossAmount"      NUMERIC(18,2)    NOT NULL,
  "InceDeduction"    NUMERIC(18,2)    NOT NULL DEFAULT 0,
  "NetAmount"        NUMERIC(18,2)    NOT NULL,
  "IsPaid"           BOOLEAN          NOT NULL DEFAULT FALSE,
  "PaidAt"           TIMESTAMP        NULL,
  CONSTRAINT "FK_ProfitSharingLine_Header"   FOREIGN KEY ("ProfitSharingId") REFERENCES hr."ProfitSharing"("ProfitSharingId"),
  CONSTRAINT "FK_ProfitSharingLine_Employee" FOREIGN KEY ("EmployeeId") REFERENCES master."Employee"("EmployeeId")
);

CREATE INDEX IF NOT EXISTS "IX_ProfitSharingLine_Header"
  ON hr."ProfitSharingLine" ("ProfitSharingId");

CREATE INDEX IF NOT EXISTS "IX_ProfitSharingLine_Employee"
  ON hr."ProfitSharingLine" ("EmployeeCode");

-- ============================================================
-- hr."SafetyCommittee"
-- ============================================================
CREATE TABLE IF NOT EXISTS hr."SafetyCommittee" (
  "SafetyCommitteeId"  INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"          INT              NOT NULL,
  "CountryCode"        CHAR(2)          NOT NULL,
  "CommitteeName"      VARCHAR(200)     NOT NULL,
  "FormationDate"      DATE             NOT NULL,
  "MeetingFrequency"   VARCHAR(15)      NOT NULL DEFAULT 'MONTHLY',
  "IsActive"           BOOLEAN          NOT NULL DEFAULT TRUE,
  "CreatedAt"          TIMESTAMP        NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  CONSTRAINT "FK_hr_SafetyCommittee_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId")
);

CREATE INDEX IF NOT EXISTS "IX_Committee_Company"
  ON hr."SafetyCommittee" ("CompanyId", "IsActive");

-- ============================================================
-- hr."SafetyCommitteeMeeting"
-- ============================================================
CREATE TABLE IF NOT EXISTS hr."SafetyCommitteeMeeting" (
  "MeetingId"          INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "SafetyCommitteeId"  INT              NOT NULL,
  "MeetingDate"        TIMESTAMP        NOT NULL,
  "MinutesUrl"         VARCHAR(500)     NULL,
  "TopicsSummary"      TEXT             NULL,
  "ActionItems"        TEXT             NULL,
  "CreatedAt"          TIMESTAMP        NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  CONSTRAINT "FK_CommitteeMeeting_Committee" FOREIGN KEY ("SafetyCommitteeId") REFERENCES hr."SafetyCommittee"("SafetyCommitteeId")
);

CREATE INDEX IF NOT EXISTS "IX_CommitteeMeeting_Committee"
  ON hr."SafetyCommitteeMeeting" ("SafetyCommitteeId", "MeetingDate" DESC);

-- ============================================================
-- hr."SafetyCommitteeMember"
-- ============================================================
CREATE TABLE IF NOT EXISTS hr."SafetyCommitteeMember" (
  "MemberId"           INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "SafetyCommitteeId"  INT              NOT NULL,
  "EmployeeId"         BIGINT           NULL,
  "EmployeeCode"       VARCHAR(24)      NOT NULL,
  "EmployeeName"       VARCHAR(200)     NOT NULL,
  "Role"               VARCHAR(25)      NOT NULL,
  "StartDate"          DATE             NOT NULL,
  "EndDate"            DATE             NULL,
  CONSTRAINT "FK_CommitteeMember_Committee" FOREIGN KEY ("SafetyCommitteeId") REFERENCES hr."SafetyCommittee"("SafetyCommitteeId"),
  CONSTRAINT "FK_CommitteeMember_Employee"  FOREIGN KEY ("EmployeeId") REFERENCES master."Employee"("EmployeeId")
);

CREATE INDEX IF NOT EXISTS "IX_CommitteeMember_Committee"
  ON hr."SafetyCommitteeMember" ("SafetyCommitteeId");

-- ============================================================
-- hr."SavingsFund"
-- ============================================================
CREATE TABLE IF NOT EXISTS hr."SavingsFund" (
  "SavingsFundId"          INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"              INT              NOT NULL,
  "EmployeeId"             BIGINT           NULL,
  "EmployeeCode"           VARCHAR(24)      NOT NULL,
  "EmployeeName"           VARCHAR(200)     NOT NULL,
  "EmployeeContribution"   NUMERIC(8,4)     NOT NULL,
  "EmployerMatch"          NUMERIC(8,4)     NOT NULL,
  "EnrollmentDate"         DATE             NOT NULL,
  "Status"                 VARCHAR(15)      NOT NULL DEFAULT 'ACTIVO',
  "CreatedAt"              TIMESTAMP        NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  CONSTRAINT "CK_SavingsFund_Status" CHECK ("Status" IN ('ACTIVO','SUSPENDIDO','RETIRADO')),
  CONSTRAINT "UX_SavingsFund_Employee" UNIQUE ("CompanyId", "EmployeeCode"),
  CONSTRAINT "FK_hr_SavingsFund_Company"  FOREIGN KEY ("CompanyId")  REFERENCES cfg."Company"("CompanyId"),
  CONSTRAINT "FK_hr_SavingsFund_Employee" FOREIGN KEY ("EmployeeId") REFERENCES master."Employee"("EmployeeId")
);

CREATE INDEX IF NOT EXISTS "IX_SavingsFund_Status"
  ON hr."SavingsFund" ("CompanyId", "Status");

-- ============================================================
-- hr."SavingsFundTransaction"
-- ============================================================
CREATE TABLE IF NOT EXISTS hr."SavingsFundTransaction" (
  "TransactionId"    INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "SavingsFundId"    INT              NOT NULL,
  "TransactionDate"  DATE             NOT NULL,
  "TransactionType"  VARCHAR(20)      NOT NULL,
  "Amount"           NUMERIC(18,2)    NOT NULL,
  "Balance"          NUMERIC(18,2)    NOT NULL,
  "Reference"        VARCHAR(100)     NULL,
  "PayrollBatchId"   INT              NULL,
  "Notes"            VARCHAR(500)     NULL,
  "CreatedAt"        TIMESTAMP        NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  CONSTRAINT "CK_SavingsTx_Type" CHECK ("TransactionType" IN (
    'APORTE_EMPLEADO','APORTE_PATRONAL','RETIRO','PRESTAMO','PAGO_PRESTAMO','INTERES'
  )),
  CONSTRAINT "FK_SavingsTx_Fund" FOREIGN KEY ("SavingsFundId") REFERENCES hr."SavingsFund"("SavingsFundId")
);

CREATE INDEX IF NOT EXISTS "IX_SavingsTx_Fund"
  ON hr."SavingsFundTransaction" ("SavingsFundId", "TransactionDate");

CREATE INDEX IF NOT EXISTS "IX_SavingsTx_Type"
  ON hr."SavingsFundTransaction" ("TransactionType");

-- ============================================================
-- hr."SavingsLoan"
-- ============================================================
CREATE TABLE IF NOT EXISTS hr."SavingsLoan" (
  "LoanId"              INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "SavingsFundId"       INT              NOT NULL,
  "EmployeeCode"        VARCHAR(24)      NOT NULL,
  "RequestDate"         DATE             NOT NULL,
  "ApprovedDate"        DATE             NULL,
  "LoanAmount"          NUMERIC(18,2)    NOT NULL,
  "InterestRate"        NUMERIC(8,5)     NOT NULL DEFAULT 0,
  "TotalPayable"        NUMERIC(18,2)    NOT NULL,
  "MonthlyPayment"      NUMERIC(18,2)    NOT NULL,
  "InstallmentsTotal"   INT              NOT NULL,
  "InstallmentsPaid"    INT              NOT NULL DEFAULT 0,
  "OutstandingBalance"  NUMERIC(18,2)    NOT NULL,
  "Status"              VARCHAR(15)      NOT NULL DEFAULT 'SOLICITADO',
  "ApprovedBy"          INT              NULL,
  "Notes"               VARCHAR(500)     NULL,
  "CreatedAt"           TIMESTAMP        NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"           TIMESTAMP        NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  CONSTRAINT "CK_SavingsLoan_Status" CHECK ("Status" IN ('SOLICITADO','APROBADO','ACTIVO','PAGADO','RECHAZADO')),
  CONSTRAINT "FK_SavingsLoan_Fund" FOREIGN KEY ("SavingsFundId") REFERENCES hr."SavingsFund"("SavingsFundId")
);

CREATE INDEX IF NOT EXISTS "IX_SavingsLoan_Fund"
  ON hr."SavingsLoan" ("SavingsFundId");

CREATE INDEX IF NOT EXISTS "IX_SavingsLoan_Employee"
  ON hr."SavingsLoan" ("EmployeeCode");

CREATE INDEX IF NOT EXISTS "IX_SavingsLoan_Status"
  ON hr."SavingsLoan" ("Status");

-- ============================================================
-- hr."SocialBenefitsTrust"
-- ============================================================
CREATE TABLE IF NOT EXISTS hr."SocialBenefitsTrust" (
  "TrustId"             INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"           INT              NOT NULL,
  "EmployeeId"          BIGINT           NULL,
  "EmployeeCode"        VARCHAR(24)      NOT NULL,
  "EmployeeName"        VARCHAR(200)     NOT NULL,
  "FiscalYear"          INT              NOT NULL,
  "Quarter"             SMALLINT         NOT NULL,
  "DailySalary"         NUMERIC(18,2)    NOT NULL,
  "DaysDeposited"       INT              NOT NULL DEFAULT 15,
  "BonusDays"           INT              NOT NULL DEFAULT 0,
  "DepositAmount"       NUMERIC(18,2)    NOT NULL,
  "InterestRate"        NUMERIC(8,5)     NOT NULL DEFAULT 0,
  "InterestAmount"      NUMERIC(18,2)    NOT NULL DEFAULT 0,
  "AccumulatedBalance"  NUMERIC(18,2)    NOT NULL,
  "Status"              VARCHAR(20)      NOT NULL DEFAULT 'PENDIENTE',
  "CreatedAt"           TIMESTAMP        NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"           TIMESTAMP        NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  CONSTRAINT "CK_Trust_Quarter" CHECK ("Quarter" >= 1 AND "Quarter" <= 4),
  CONSTRAINT "CK_Trust_Status"  CHECK ("Status" IN ('PENDIENTE','DEPOSITADO','PAGADO')),
  CONSTRAINT "UX_Trust_Employee_Quarter" UNIQUE ("CompanyId", "EmployeeCode", "FiscalYear", "Quarter"),
  CONSTRAINT "FK_hr_Trust_Company"  FOREIGN KEY ("CompanyId")  REFERENCES cfg."Company"("CompanyId"),
  CONSTRAINT "FK_hr_Trust_Employee" FOREIGN KEY ("EmployeeId") REFERENCES master."Employee"("EmployeeId")
);

CREATE INDEX IF NOT EXISTS "IX_Trust_Company_Year"
  ON hr."SocialBenefitsTrust" ("CompanyId", "FiscalYear", "Quarter");

CREATE INDEX IF NOT EXISTS "IX_Trust_Employee"
  ON hr."SocialBenefitsTrust" ("EmployeeCode", "FiscalYear");

-- ============================================================
-- hr."TrainingRecord"
-- ============================================================
CREATE TABLE IF NOT EXISTS hr."TrainingRecord" (
  "TrainingRecordId"   INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"          INT              NOT NULL,
  "CountryCode"        CHAR(2)          NOT NULL,
  "TrainingType"       VARCHAR(25)      NOT NULL,
  "Title"              VARCHAR(200)     NOT NULL,
  "Provider"           VARCHAR(200)     NULL,
  "StartDate"          DATE             NOT NULL,
  "EndDate"            DATE             NULL,
  "DurationHours"      NUMERIC(6,2)     NOT NULL,
  "EmployeeId"         BIGINT           NULL,
  "EmployeeCode"       VARCHAR(24)      NOT NULL,
  "EmployeeName"       VARCHAR(200)     NOT NULL,
  "CertificateNumber"  VARCHAR(100)     NULL,
  "CertificateUrl"     VARCHAR(500)     NULL,
  "Result"             VARCHAR(15)      NULL,
  "IsRegulatory"       BOOLEAN          NOT NULL DEFAULT FALSE,
  "Notes"              VARCHAR(500)     NULL,
  "CreatedAt"          TIMESTAMP        NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"          TIMESTAMP        NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  CONSTRAINT "FK_hr_TrainingRecord_Company"  FOREIGN KEY ("CompanyId")  REFERENCES cfg."Company"("CompanyId"),
  CONSTRAINT "FK_hr_TrainingRecord_Employee" FOREIGN KEY ("EmployeeId") REFERENCES master."Employee"("EmployeeId")
);

CREATE INDEX IF NOT EXISTS "IX_Training_Company_Type"
  ON hr."TrainingRecord" ("CompanyId", "TrainingType", "StartDate" DESC);

CREATE INDEX IF NOT EXISTS "IX_Training_Employee"
  ON hr."TrainingRecord" ("EmployeeCode", "CompanyId");

CREATE INDEX IF NOT EXISTS "IX_Training_Regulatory"
  ON hr."TrainingRecord" ("CompanyId", "IsRegulatory")
  WHERE "IsRegulatory" = TRUE;

-- ============================================================================
-- SEED DATA — Datos de demostración Venezuela
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Seed: master."Employee" (si no hay empleados)
-- ----------------------------------------------------------------------------
-- +goose StatementBegin
DO $$
BEGIN
  RAISE NOTICE '>> Seed: Empleados base (si no existen)';

  INSERT INTO master."Employee" ("CompanyId","EmployeeCode","EmployeeName","FiscalId","HireDate","TerminationDate","IsActive")
  SELECT 1,'V-12345678','Maria Elena Gonzalez Perez','V-12345678','2020-01-15',NULL,true
  WHERE NOT EXISTS (SELECT 1 FROM master."Employee" WHERE "CompanyId"=1 AND "EmployeeCode"='V-12345678');

  INSERT INTO master."Employee" ("CompanyId","EmployeeCode","EmployeeName","FiscalId","HireDate","TerminationDate","IsActive")
  SELECT 1,'V-14567890','Carlos Alberto Rodriguez Silva','V-14567890','2019-06-01',NULL,true
  WHERE NOT EXISTS (SELECT 1 FROM master."Employee" WHERE "CompanyId"=1 AND "EmployeeCode"='V-14567890');

  INSERT INTO master."Employee" ("CompanyId","EmployeeCode","EmployeeName","FiscalId","HireDate","TerminationDate","IsActive")
  SELECT 1,'V-16789012','Ana Isabel Martinez Lopez','V-16789012','2021-03-10',NULL,true
  WHERE NOT EXISTS (SELECT 1 FROM master."Employee" WHERE "CompanyId"=1 AND "EmployeeCode"='V-16789012');

  INSERT INTO master."Employee" ("CompanyId","EmployeeCode","EmployeeName","FiscalId","HireDate","TerminationDate","IsActive")
  SELECT 1,'V-18234567','Jose Manuel Fernandez Torres','V-18234567','2022-08-20',NULL,true
  WHERE NOT EXISTS (SELECT 1 FROM master."Employee" WHERE "CompanyId"=1 AND "EmployeeCode"='V-18234567');

  INSERT INTO master."Employee" ("CompanyId","EmployeeCode","EmployeeName","FiscalId","HireDate","TerminationDate","IsActive")
  SELECT 1,'V-18901234','Luis Eduardo Perez Mendoza','V-18901234','2024-06-01',NULL,true
  WHERE NOT EXISTS (SELECT 1 FROM master."Employee" WHERE "CompanyId"=1 AND "EmployeeCode"='V-18901234');

  INSERT INTO master."Employee" ("CompanyId","EmployeeCode","EmployeeName","FiscalId","HireDate","TerminationDate","IsActive")
  SELECT 1,'V-20456789','Carmen Rosa Salazar Vega','V-20456789','2023-02-14',NULL,true
  WHERE NOT EXISTS (SELECT 1 FROM master."Employee" WHERE "CompanyId"=1 AND "EmployeeCode"='V-20456789');

  INSERT INTO master."Employee" ("CompanyId","EmployeeCode","EmployeeName","FiscalId","HireDate","TerminationDate","IsActive")
  SELECT 1,'V-22678901','Miguel Angel Castillo Reyes','V-22678901','2021-11-05',NULL,true
  WHERE NOT EXISTS (SELECT 1 FROM master."Employee" WHERE "CompanyId"=1 AND "EmployeeCode"='V-22678901');

  INSERT INTO master."Employee" ("CompanyId","EmployeeCode","EmployeeName","FiscalId","HireDate","TerminationDate","IsActive")
  SELECT 1,'V-24890123','Laura Patricia Mora Jimenez','V-24890123','2022-04-18',NULL,true
  WHERE NOT EXISTS (SELECT 1 FROM master."Employee" WHERE "CompanyId"=1 AND "EmployeeCode"='V-24890123');

  INSERT INTO master."Employee" ("CompanyId","EmployeeCode","EmployeeName","FiscalId","HireDate","TerminationDate","IsActive")
  SELECT 1,'V-25678901','Roberto Jose Herrera Blanco','V-25678901','2024-03-01',NULL,true
  WHERE NOT EXISTS (SELECT 1 FROM master."Employee" WHERE "CompanyId"=1 AND "EmployeeCode"='V-25678901');

  INSERT INTO master."Employee" ("CompanyId","EmployeeCode","EmployeeName","FiscalId","HireDate","TerminationDate","IsActive")
  SELECT 1,'V-26012345','Gabriela Sofia Diaz Rojas','V-26012345','2023-09-01',NULL,true
  WHERE NOT EXISTS (SELECT 1 FROM master."Employee" WHERE "CompanyId"=1 AND "EmployeeCode"='V-26012345');

  RAISE NOTICE '   Empleados base procesados.';
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE 'Error en seed empleados: %', SQLERRM;
END $$;
-- +goose StatementEnd

-- ----------------------------------------------------------------------------
-- Seed: hr."SavingsFund" — Caja de Ahorro
-- ----------------------------------------------------------------------------
-- +goose StatementBegin
DO $$
BEGIN
  RAISE NOTICE '>> Seed: SavingsFund';

  INSERT INTO hr."SavingsFund" (
    "CompanyId","EmployeeId","EmployeeCode","EmployeeName",
    "EmployeeContribution","EmployerMatch","EnrollmentDate","Status","CreatedAt"
  )
  SELECT 1,e."EmployeeId",'V-25678901','Roberto Jose Herrera Blanco',10.00,10.00,'2025-01-15','ACTIVO',(NOW() AT TIME ZONE 'UTC')
  FROM master."Employee" e WHERE e."EmployeeCode"='V-25678901' AND e."CompanyId"=1
  ON CONFLICT ("CompanyId","EmployeeCode") DO NOTHING;

  INSERT INTO hr."SavingsFund" (
    "CompanyId","EmployeeId","EmployeeCode","EmployeeName",
    "EmployeeContribution","EmployerMatch","EnrollmentDate","Status","CreatedAt"
  )
  SELECT 1,e."EmployeeId",'V-18901234','Luis Eduardo Perez Mendoza',10.00,10.00,'2025-01-15','ACTIVO',(NOW() AT TIME ZONE 'UTC')
  FROM master."Employee" e WHERE e."EmployeeCode"='V-18901234' AND e."CompanyId"=1
  ON CONFLICT ("CompanyId","EmployeeCode") DO NOTHING;

  INSERT INTO hr."SavingsFund" (
    "CompanyId","EmployeeId","EmployeeCode","EmployeeName",
    "EmployeeContribution","EmployerMatch","EnrollmentDate","Status","CreatedAt"
  )
  SELECT 1,e."EmployeeId",'V-12345678','Maria Elena Gonzalez Perez',12.00,12.00,'2024-03-01','ACTIVO',(NOW() AT TIME ZONE 'UTC')
  FROM master."Employee" e WHERE e."EmployeeCode"='V-12345678' AND e."CompanyId"=1
  ON CONFLICT ("CompanyId","EmployeeCode") DO NOTHING;

  INSERT INTO hr."SavingsFund" (
    "CompanyId","EmployeeId","EmployeeCode","EmployeeName",
    "EmployeeContribution","EmployerMatch","EnrollmentDate","Status","CreatedAt"
  )
  SELECT 1,e."EmployeeId",'V-14567890','Carlos Alberto Rodriguez Silva',10.00,10.00,'2023-06-01','ACTIVO',(NOW() AT TIME ZONE 'UTC')
  FROM master."Employee" e WHERE e."EmployeeCode"='V-14567890' AND e."CompanyId"=1
  ON CONFLICT ("CompanyId","EmployeeCode") DO NOTHING;

  INSERT INTO hr."SavingsFund" (
    "CompanyId","EmployeeId","EmployeeCode","EmployeeName",
    "EmployeeContribution","EmployerMatch","EnrollmentDate","Status","CreatedAt"
  )
  SELECT 1,e."EmployeeId",'V-22678901','Miguel Angel Castillo Reyes',15.00,15.00,'2024-01-10','ACTIVO',(NOW() AT TIME ZONE 'UTC')
  FROM master."Employee" e WHERE e."EmployeeCode"='V-22678901' AND e."CompanyId"=1
  ON CONFLICT ("CompanyId","EmployeeCode") DO NOTHING;

  INSERT INTO hr."SavingsFund" (
    "CompanyId","EmployeeId","EmployeeCode","EmployeeName",
    "EmployeeContribution","EmployerMatch","EnrollmentDate","Status","CreatedAt"
  )
  SELECT 1,e."EmployeeId",'V-20456789','Carmen Rosa Salazar Vega',10.00,10.00,'2023-08-01','ACTIVO',(NOW() AT TIME ZONE 'UTC')
  FROM master."Employee" e WHERE e."EmployeeCode"='V-20456789' AND e."CompanyId"=1
  ON CONFLICT ("CompanyId","EmployeeCode") DO NOTHING;

  INSERT INTO hr."SavingsFund" (
    "CompanyId","EmployeeId","EmployeeCode","EmployeeName",
    "EmployeeContribution","EmployerMatch","EnrollmentDate","Status","CreatedAt"
  )
  SELECT 1,e."EmployeeId",'V-16789012','Ana Isabel Martinez Lopez',10.00,10.00,'2024-06-01','ACTIVO',(NOW() AT TIME ZONE 'UTC')
  FROM master."Employee" e WHERE e."EmployeeCode"='V-16789012' AND e."CompanyId"=1
  ON CONFLICT ("CompanyId","EmployeeCode") DO NOTHING;

  RAISE NOTICE '   SavingsFund procesado.';
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE 'Error en seed SavingsFund: %', SQLERRM;
END $$;
-- +goose StatementEnd

-- ----------------------------------------------------------------------------
-- Seed: hr."SavingsFundTransaction"
-- ----------------------------------------------------------------------------
-- +goose StatementBegin
DO $$
DECLARE v_fund1 INT; v_fund2 INT;
BEGIN
  RAISE NOTICE '>> Seed: SavingsFundTransaction';

  SELECT "SavingsFundId" INTO v_fund1 FROM hr."SavingsFund" WHERE "CompanyId"=1 AND "EmployeeCode"='V-25678901';
  SELECT "SavingsFundId" INTO v_fund2 FROM hr."SavingsFund" WHERE "CompanyId"=1 AND "EmployeeCode"='V-18901234';

  IF v_fund1 IS NOT NULL THEN
    INSERT INTO hr."SavingsFundTransaction" ("SavingsFundId","TransactionDate","TransactionType","Amount","Balance","Reference","Notes","CreatedAt")
    SELECT v_fund1,'2025-01-31','APORTE_EMPLEADO',350.00,350.00,'NOM-2025-01','Aporte empleado enero 2025',(NOW() AT TIME ZONE 'UTC')
    WHERE NOT EXISTS (SELECT 1 FROM hr."SavingsFundTransaction" WHERE "SavingsFundId"=v_fund1 AND "TransactionDate"='2025-01-31' AND "TransactionType"='APORTE_EMPLEADO');

    INSERT INTO hr."SavingsFundTransaction" ("SavingsFundId","TransactionDate","TransactionType","Amount","Balance","Reference","Notes","CreatedAt")
    SELECT v_fund1,'2025-01-31','APORTE_PATRONAL',350.00,700.00,'NOM-2025-01','Aporte patronal enero 2025',(NOW() AT TIME ZONE 'UTC')
    WHERE NOT EXISTS (SELECT 1 FROM hr."SavingsFundTransaction" WHERE "SavingsFundId"=v_fund1 AND "TransactionDate"='2025-01-31' AND "TransactionType"='APORTE_PATRONAL');

    INSERT INTO hr."SavingsFundTransaction" ("SavingsFundId","TransactionDate","TransactionType","Amount","Balance","Reference","Notes","CreatedAt")
    SELECT v_fund1,'2025-02-28','APORTE_EMPLEADO',350.00,1050.00,'NOM-2025-02','Aporte empleado febrero 2025',(NOW() AT TIME ZONE 'UTC')
    WHERE NOT EXISTS (SELECT 1 FROM hr."SavingsFundTransaction" WHERE "SavingsFundId"=v_fund1 AND "TransactionDate"='2025-02-28' AND "TransactionType"='APORTE_EMPLEADO');

    INSERT INTO hr."SavingsFundTransaction" ("SavingsFundId","TransactionDate","TransactionType","Amount","Balance","Reference","Notes","CreatedAt")
    SELECT v_fund1,'2025-02-28','APORTE_PATRONAL',350.00,1400.00,'NOM-2025-02','Aporte patronal febrero 2025',(NOW() AT TIME ZONE 'UTC')
    WHERE NOT EXISTS (SELECT 1 FROM hr."SavingsFundTransaction" WHERE "SavingsFundId"=v_fund1 AND "TransactionDate"='2025-02-28' AND "TransactionType"='APORTE_PATRONAL');

    INSERT INTO hr."SavingsFundTransaction" ("SavingsFundId","TransactionDate","TransactionType","Amount","Balance","Reference","Notes","CreatedAt")
    SELECT v_fund1,'2025-03-31','APORTE_EMPLEADO',350.00,1750.00,'NOM-2025-03','Aporte empleado marzo 2025',(NOW() AT TIME ZONE 'UTC')
    WHERE NOT EXISTS (SELECT 1 FROM hr."SavingsFundTransaction" WHERE "SavingsFundId"=v_fund1 AND "TransactionDate"='2025-03-31' AND "TransactionType"='APORTE_EMPLEADO');

    INSERT INTO hr."SavingsFundTransaction" ("SavingsFundId","TransactionDate","TransactionType","Amount","Balance","Reference","Notes","CreatedAt")
    SELECT v_fund1,'2025-03-31','APORTE_PATRONAL',350.00,2100.00,'NOM-2025-03','Aporte patronal marzo 2025',(NOW() AT TIME ZONE 'UTC')
    WHERE NOT EXISTS (SELECT 1 FROM hr."SavingsFundTransaction" WHERE "SavingsFundId"=v_fund1 AND "TransactionDate"='2025-03-31' AND "TransactionType"='APORTE_PATRONAL');
  END IF;

  IF v_fund2 IS NOT NULL THEN
    INSERT INTO hr."SavingsFundTransaction" ("SavingsFundId","TransactionDate","TransactionType","Amount","Balance","Reference","Notes","CreatedAt")
    SELECT v_fund2,'2025-01-31','APORTE_EMPLEADO',280.00,280.00,'NOM-2025-01','Aporte empleado enero 2025',(NOW() AT TIME ZONE 'UTC')
    WHERE NOT EXISTS (SELECT 1 FROM hr."SavingsFundTransaction" WHERE "SavingsFundId"=v_fund2 AND "TransactionDate"='2025-01-31' AND "TransactionType"='APORTE_EMPLEADO');

    INSERT INTO hr."SavingsFundTransaction" ("SavingsFundId","TransactionDate","TransactionType","Amount","Balance","Reference","Notes","CreatedAt")
    SELECT v_fund2,'2025-01-31','APORTE_PATRONAL',280.00,560.00,'NOM-2025-01','Aporte patronal enero 2025',(NOW() AT TIME ZONE 'UTC')
    WHERE NOT EXISTS (SELECT 1 FROM hr."SavingsFundTransaction" WHERE "SavingsFundId"=v_fund2 AND "TransactionDate"='2025-01-31' AND "TransactionType"='APORTE_PATRONAL');

    INSERT INTO hr."SavingsFundTransaction" ("SavingsFundId","TransactionDate","TransactionType","Amount","Balance","Reference","Notes","CreatedAt")
    SELECT v_fund2,'2025-02-28','APORTE_EMPLEADO',280.00,840.00,'NOM-2025-02','Aporte empleado febrero 2025',(NOW() AT TIME ZONE 'UTC')
    WHERE NOT EXISTS (SELECT 1 FROM hr."SavingsFundTransaction" WHERE "SavingsFundId"=v_fund2 AND "TransactionDate"='2025-02-28' AND "TransactionType"='APORTE_EMPLEADO');

    INSERT INTO hr."SavingsFundTransaction" ("SavingsFundId","TransactionDate","TransactionType","Amount","Balance","Reference","Notes","CreatedAt")
    SELECT v_fund2,'2025-02-28','APORTE_PATRONAL',280.00,1120.00,'NOM-2025-02','Aporte patronal febrero 2025',(NOW() AT TIME ZONE 'UTC')
    WHERE NOT EXISTS (SELECT 1 FROM hr."SavingsFundTransaction" WHERE "SavingsFundId"=v_fund2 AND "TransactionDate"='2025-02-28' AND "TransactionType"='APORTE_PATRONAL');

    INSERT INTO hr."SavingsFundTransaction" ("SavingsFundId","TransactionDate","TransactionType","Amount","Balance","Reference","Notes","CreatedAt")
    SELECT v_fund2,'2025-03-31','APORTE_EMPLEADO',280.00,1400.00,'NOM-2025-03','Aporte empleado marzo 2025',(NOW() AT TIME ZONE 'UTC')
    WHERE NOT EXISTS (SELECT 1 FROM hr."SavingsFundTransaction" WHERE "SavingsFundId"=v_fund2 AND "TransactionDate"='2025-03-31' AND "TransactionType"='APORTE_EMPLEADO');

    INSERT INTO hr."SavingsFundTransaction" ("SavingsFundId","TransactionDate","TransactionType","Amount","Balance","Reference","Notes","CreatedAt")
    SELECT v_fund2,'2025-03-31','APORTE_PATRONAL',280.00,1680.00,'NOM-2025-03','Aporte patronal marzo 2025',(NOW() AT TIME ZONE 'UTC')
    WHERE NOT EXISTS (SELECT 1 FROM hr."SavingsFundTransaction" WHERE "SavingsFundId"=v_fund2 AND "TransactionDate"='2025-03-31' AND "TransactionType"='APORTE_PATRONAL');
  END IF;

  RAISE NOTICE '   SavingsFundTransaction procesado.';
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE 'Error en seed SavingsFundTransaction: %', SQLERRM;
END $$;
-- +goose StatementEnd

-- ----------------------------------------------------------------------------
-- Seed: hr."SavingsLoan"
-- ----------------------------------------------------------------------------
-- +goose StatementBegin
DO $$
DECLARE v_fund1 INT;
BEGIN
  RAISE NOTICE '>> Seed: SavingsLoan';

  SELECT "SavingsFundId" INTO v_fund1 FROM hr."SavingsFund" WHERE "CompanyId"=1 AND "EmployeeCode"='V-25678901';

  IF v_fund1 IS NOT NULL THEN
    INSERT INTO hr."SavingsLoan" (
      "SavingsFundId","EmployeeCode","RequestDate","ApprovedDate",
      "LoanAmount","InterestRate","TotalPayable","MonthlyPayment",
      "InstallmentsTotal","InstallmentsPaid","OutstandingBalance",
      "Status","ApprovedBy","Notes","CreatedAt","UpdatedAt"
    )
    SELECT
      v_fund1,'V-25678901','2025-04-01','2025-04-05',
      5000.00,6.00000,5300.00,441.67,
      12,3,3975.01,
      'APROBADO',1,'Prestamo ordinario caja de ahorro',(NOW() AT TIME ZONE 'UTC'),(NOW() AT TIME ZONE 'UTC')
    WHERE NOT EXISTS (SELECT 1 FROM hr."SavingsLoan" WHERE "SavingsFundId"=v_fund1 AND "RequestDate"='2025-04-01');
  END IF;

  RAISE NOTICE '   SavingsLoan procesado.';
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE 'Error en seed SavingsLoan: %', SQLERRM;
END $$;
-- +goose StatementEnd

-- ----------------------------------------------------------------------------
-- Seed: hr."SocialBenefitsTrust" — Fideicomiso Prestaciones Sociales
-- ----------------------------------------------------------------------------
-- +goose StatementBegin
DO $$
BEGIN
  RAISE NOTICE '>> Seed: SocialBenefitsTrust';

  -- Empleado V-25678901: 4 trimestres 2025
  INSERT INTO hr."SocialBenefitsTrust" (
    "CompanyId","EmployeeId","EmployeeCode","EmployeeName",
    "FiscalYear","Quarter","DailySalary","DaysDeposited","BonusDays",
    "DepositAmount","InterestRate","InterestAmount","AccumulatedBalance",
    "Status","CreatedAt","UpdatedAt"
  )
  SELECT 1,e."EmployeeId",'V-25678901','Roberto Jose Herrera Blanco',
    2025,1,116.6667,15,0,1750.00,15.30000,0.00,1750.00,
    'DEPOSITADO',(NOW() AT TIME ZONE 'UTC'),(NOW() AT TIME ZONE 'UTC')
  FROM master."Employee" e WHERE e."EmployeeCode"='V-25678901' AND e."CompanyId"=1
  ON CONFLICT ("CompanyId","EmployeeCode","FiscalYear","Quarter") DO NOTHING;

  INSERT INTO hr."SocialBenefitsTrust" (
    "CompanyId","EmployeeId","EmployeeCode","EmployeeName",
    "FiscalYear","Quarter","DailySalary","DaysDeposited","BonusDays",
    "DepositAmount","InterestRate","InterestAmount","AccumulatedBalance",
    "Status","CreatedAt","UpdatedAt"
  )
  SELECT 1,e."EmployeeId",'V-25678901','Roberto Jose Herrera Blanco',
    2025,2,116.6667,15,0,1750.00,15.30000,66.94,3566.94,
    'DEPOSITADO',(NOW() AT TIME ZONE 'UTC'),(NOW() AT TIME ZONE 'UTC')
  FROM master."Employee" e WHERE e."EmployeeCode"='V-25678901' AND e."CompanyId"=1
  ON CONFLICT ("CompanyId","EmployeeCode","FiscalYear","Quarter") DO NOTHING;

  INSERT INTO hr."SocialBenefitsTrust" (
    "CompanyId","EmployeeId","EmployeeCode","EmployeeName",
    "FiscalYear","Quarter","DailySalary","DaysDeposited","BonusDays",
    "DepositAmount","InterestRate","InterestAmount","AccumulatedBalance",
    "Status","CreatedAt","UpdatedAt"
  )
  SELECT 1,e."EmployeeId",'V-25678901','Roberto Jose Herrera Blanco',
    2025,3,116.6667,15,0,1750.00,15.30000,136.44,5453.38,
    'DEPOSITADO',(NOW() AT TIME ZONE 'UTC'),(NOW() AT TIME ZONE 'UTC')
  FROM master."Employee" e WHERE e."EmployeeCode"='V-25678901' AND e."CompanyId"=1
  ON CONFLICT ("CompanyId","EmployeeCode","FiscalYear","Quarter") DO NOTHING;

  INSERT INTO hr."SocialBenefitsTrust" (
    "CompanyId","EmployeeId","EmployeeCode","EmployeeName",
    "FiscalYear","Quarter","DailySalary","DaysDeposited","BonusDays",
    "DepositAmount","InterestRate","InterestAmount","AccumulatedBalance",
    "Status","CreatedAt","UpdatedAt"
  )
  SELECT 1,e."EmployeeId",'V-25678901','Roberto Jose Herrera Blanco',
    2025,4,116.6667,15,0,1750.00,15.30000,208.59,7411.97,
    'DEPOSITADO',(NOW() AT TIME ZONE 'UTC'),(NOW() AT TIME ZONE 'UTC')
  FROM master."Employee" e WHERE e."EmployeeCode"='V-25678901' AND e."CompanyId"=1
  ON CONFLICT ("CompanyId","EmployeeCode","FiscalYear","Quarter") DO NOTHING;

  -- Empleado V-18901234: 4 trimestres 2025
  INSERT INTO hr."SocialBenefitsTrust" (
    "CompanyId","EmployeeId","EmployeeCode","EmployeeName",
    "FiscalYear","Quarter","DailySalary","DaysDeposited","BonusDays",
    "DepositAmount","InterestRate","InterestAmount","AccumulatedBalance",
    "Status","CreatedAt","UpdatedAt"
  )
  SELECT 1,e."EmployeeId",'V-18901234','Luis Eduardo Perez Mendoza',
    2025,1,93.3333,15,0,1400.00,15.30000,0.00,1400.00,
    'DEPOSITADO',(NOW() AT TIME ZONE 'UTC'),(NOW() AT TIME ZONE 'UTC')
  FROM master."Employee" e WHERE e."EmployeeCode"='V-18901234' AND e."CompanyId"=1
  ON CONFLICT ("CompanyId","EmployeeCode","FiscalYear","Quarter") DO NOTHING;

  INSERT INTO hr."SocialBenefitsTrust" (
    "CompanyId","EmployeeId","EmployeeCode","EmployeeName",
    "FiscalYear","Quarter","DailySalary","DaysDeposited","BonusDays",
    "DepositAmount","InterestRate","InterestAmount","AccumulatedBalance",
    "Status","CreatedAt","UpdatedAt"
  )
  SELECT 1,e."EmployeeId",'V-18901234','Luis Eduardo Perez Mendoza',
    2025,2,93.3333,15,0,1400.00,15.30000,53.55,2853.55,
    'DEPOSITADO',(NOW() AT TIME ZONE 'UTC'),(NOW() AT TIME ZONE 'UTC')
  FROM master."Employee" e WHERE e."EmployeeCode"='V-18901234' AND e."CompanyId"=1
  ON CONFLICT ("CompanyId","EmployeeCode","FiscalYear","Quarter") DO NOTHING;

  INSERT INTO hr."SocialBenefitsTrust" (
    "CompanyId","EmployeeId","EmployeeCode","EmployeeName",
    "FiscalYear","Quarter","DailySalary","DaysDeposited","BonusDays",
    "DepositAmount","InterestRate","InterestAmount","AccumulatedBalance",
    "Status","CreatedAt","UpdatedAt"
  )
  SELECT 1,e."EmployeeId",'V-18901234','Luis Eduardo Perez Mendoza',
    2025,3,93.3333,15,0,1400.00,15.30000,109.15,4362.70,
    'DEPOSITADO',(NOW() AT TIME ZONE 'UTC'),(NOW() AT TIME ZONE 'UTC')
  FROM master."Employee" e WHERE e."EmployeeCode"='V-18901234' AND e."CompanyId"=1
  ON CONFLICT ("CompanyId","EmployeeCode","FiscalYear","Quarter") DO NOTHING;

  INSERT INTO hr."SocialBenefitsTrust" (
    "CompanyId","EmployeeId","EmployeeCode","EmployeeName",
    "FiscalYear","Quarter","DailySalary","DaysDeposited","BonusDays",
    "DepositAmount","InterestRate","InterestAmount","AccumulatedBalance",
    "Status","CreatedAt","UpdatedAt"
  )
  SELECT 1,e."EmployeeId",'V-18901234','Luis Eduardo Perez Mendoza',
    2025,4,93.3333,15,0,1400.00,15.30000,166.87,5929.57,
    'DEPOSITADO',(NOW() AT TIME ZONE 'UTC'),(NOW() AT TIME ZONE 'UTC')
  FROM master."Employee" e WHERE e."EmployeeCode"='V-18901234' AND e."CompanyId"=1
  ON CONFLICT ("CompanyId","EmployeeCode","FiscalYear","Quarter") DO NOTHING;

  -- Empleado V-12345678: 2 trimestres 2025
  INSERT INTO hr."SocialBenefitsTrust" (
    "CompanyId","EmployeeId","EmployeeCode","EmployeeName",
    "FiscalYear","Quarter","DailySalary","DaysDeposited","BonusDays",
    "DepositAmount","InterestRate","InterestAmount","AccumulatedBalance",
    "Status","CreatedAt","UpdatedAt"
  )
  SELECT 1,e."EmployeeId",'V-12345678','Maria Elena Gonzalez Perez',
    2025,1,133.3333,15,0,2000.00,15.30000,0.00,2000.00,
    'DEPOSITADO',(NOW() AT TIME ZONE 'UTC'),(NOW() AT TIME ZONE 'UTC')
  FROM master."Employee" e WHERE e."EmployeeCode"='V-12345678' AND e."CompanyId"=1
  ON CONFLICT ("CompanyId","EmployeeCode","FiscalYear","Quarter") DO NOTHING;

  INSERT INTO hr."SocialBenefitsTrust" (
    "CompanyId","EmployeeId","EmployeeCode","EmployeeName",
    "FiscalYear","Quarter","DailySalary","DaysDeposited","BonusDays",
    "DepositAmount","InterestRate","InterestAmount","AccumulatedBalance",
    "Status","CreatedAt","UpdatedAt"
  )
  SELECT 1,e."EmployeeId",'V-12345678','Maria Elena Gonzalez Perez',
    2025,2,133.3333,15,0,2000.00,15.30000,76.50,4076.50,
    'DEPOSITADO',(NOW() AT TIME ZONE 'UTC'),(NOW() AT TIME ZONE 'UTC')
  FROM master."Employee" e WHERE e."EmployeeCode"='V-12345678' AND e."CompanyId"=1
  ON CONFLICT ("CompanyId","EmployeeCode","FiscalYear","Quarter") DO NOTHING;

  RAISE NOTICE '   SocialBenefitsTrust procesado.';
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE 'Error en seed SocialBenefitsTrust: %', SQLERRM;
END $$;
-- +goose StatementEnd

-- ----------------------------------------------------------------------------
-- Seed: hr."ProfitSharing" + hr."ProfitSharingLine" — Utilidades 2025
-- ----------------------------------------------------------------------------
-- +goose StatementBegin
DO $$
DECLARE v_ps_id INT;
BEGIN
  RAISE NOTICE '>> Seed: ProfitSharing 2025';

  INSERT INTO hr."ProfitSharing" (
    "CompanyId","BranchId","FiscalYear","DaysGranted",
    "TotalCompanyProfits","Status","CreatedBy","CreatedAt","UpdatedAt"
  )
  SELECT 1,1,2025,30,500000.00,'CALCULADA',1,(NOW() AT TIME ZONE 'UTC'),(NOW() AT TIME ZONE 'UTC')
  WHERE NOT EXISTS (SELECT 1 FROM hr."ProfitSharing" WHERE "CompanyId"=1 AND "FiscalYear"=2025);

  SELECT "ProfitSharingId" INTO v_ps_id FROM hr."ProfitSharing" WHERE "CompanyId"=1 AND "FiscalYear"=2025;

  IF v_ps_id IS NOT NULL THEN
    INSERT INTO hr."ProfitSharingLine" (
      "ProfitSharingId","EmployeeId","EmployeeCode","EmployeeName",
      "MonthlySalary","DailySalary","DaysWorked","DaysEntitled",
      "GrossAmount","InceDeduction","NetAmount","IsPaid","PaidAt"
    )
    SELECT v_ps_id,e."EmployeeId",'V-25678901','Roberto Jose Herrera Blanco',
      3500.00,116.6667,365,30,3500.00,17.50,3482.50,false,NULL
    FROM master."Employee" e WHERE e."EmployeeCode"='V-25678901' AND e."CompanyId"=1
    ON CONFLICT DO NOTHING;

    INSERT INTO hr."ProfitSharingLine" (
      "ProfitSharingId","EmployeeId","EmployeeCode","EmployeeName",
      "MonthlySalary","DailySalary","DaysWorked","DaysEntitled",
      "GrossAmount","InceDeduction","NetAmount","IsPaid","PaidAt"
    )
    SELECT v_ps_id,e."EmployeeId",'V-18901234','Luis Eduardo Perez Mendoza',
      2800.00,93.3333,365,30,2800.00,14.00,2786.00,false,NULL
    FROM master."Employee" e WHERE e."EmployeeCode"='V-18901234' AND e."CompanyId"=1
    ON CONFLICT DO NOTHING;

    INSERT INTO hr."ProfitSharingLine" (
      "ProfitSharingId","EmployeeId","EmployeeCode","EmployeeName",
      "MonthlySalary","DailySalary","DaysWorked","DaysEntitled",
      "GrossAmount","InceDeduction","NetAmount","IsPaid","PaidAt"
    )
    SELECT v_ps_id,e."EmployeeId",'V-12345678','Maria Elena Gonzalez Perez',
      4000.00,133.3333,365,30,4000.00,20.00,3980.00,false,NULL
    FROM master."Employee" e WHERE e."EmployeeCode"='V-12345678' AND e."CompanyId"=1
    ON CONFLICT DO NOTHING;

    INSERT INTO hr."ProfitSharingLine" (
      "ProfitSharingId","EmployeeId","EmployeeCode","EmployeeName",
      "MonthlySalary","DailySalary","DaysWorked","DaysEntitled",
      "GrossAmount","InceDeduction","NetAmount","IsPaid","PaidAt"
    )
    SELECT v_ps_id,e."EmployeeId",'V-14567890','Carlos Alberto Rodriguez Silva',
      3200.00,106.6667,365,30,3200.00,16.00,3184.00,false,NULL
    FROM master."Employee" e WHERE e."EmployeeCode"='V-14567890' AND e."CompanyId"=1
    ON CONFLICT DO NOTHING;

    INSERT INTO hr."ProfitSharingLine" (
      "ProfitSharingId","EmployeeId","EmployeeCode","EmployeeName",
      "MonthlySalary","DailySalary","DaysWorked","DaysEntitled",
      "GrossAmount","InceDeduction","NetAmount","IsPaid","PaidAt"
    )
    SELECT v_ps_id,e."EmployeeId",'V-22678901','Miguel Angel Castillo Reyes',
      2600.00,86.6667,310,26,2253.33,11.27,2242.06,false,NULL
    FROM master."Employee" e WHERE e."EmployeeCode"='V-22678901' AND e."CompanyId"=1
    ON CONFLICT DO NOTHING;

    INSERT INTO hr."ProfitSharingLine" (
      "ProfitSharingId","EmployeeId","EmployeeCode","EmployeeName",
      "MonthlySalary","DailySalary","DaysWorked","DaysEntitled",
      "GrossAmount","InceDeduction","NetAmount","IsPaid","PaidAt"
    )
    SELECT v_ps_id,e."EmployeeId",'V-20456789','Carmen Rosa Salazar Vega',
      2500.00,83.3333,365,30,2500.00,12.50,2487.50,false,NULL
    FROM master."Employee" e WHERE e."EmployeeCode"='V-20456789' AND e."CompanyId"=1
    ON CONFLICT DO NOTHING;

    INSERT INTO hr."ProfitSharingLine" (
      "ProfitSharingId","EmployeeId","EmployeeCode","EmployeeName",
      "MonthlySalary","DailySalary","DaysWorked","DaysEntitled",
      "GrossAmount","InceDeduction","NetAmount","IsPaid","PaidAt"
    )
    SELECT v_ps_id,e."EmployeeId",'V-24890123','Laura Patricia Mora Jimenez',
      2200.00,73.3333,275,23,1686.67,8.43,1678.24,false,NULL
    FROM master."Employee" e WHERE e."EmployeeCode"='V-24890123' AND e."CompanyId"=1
    ON CONFLICT DO NOTHING;

    INSERT INTO hr."ProfitSharingLine" (
      "ProfitSharingId","EmployeeId","EmployeeCode","EmployeeName",
      "MonthlySalary","DailySalary","DaysWorked","DaysEntitled",
      "GrossAmount","InceDeduction","NetAmount","IsPaid","PaidAt"
    )
    SELECT v_ps_id,e."EmployeeId",'V-16789012','Ana Isabel Martinez Lopez',
      2900.00,96.6667,365,30,2900.00,14.50,2885.50,false,NULL
    FROM master."Employee" e WHERE e."EmployeeCode"='V-16789012' AND e."CompanyId"=1
    ON CONFLICT DO NOTHING;

    INSERT INTO hr."ProfitSharingLine" (
      "ProfitSharingId","EmployeeId","EmployeeCode","EmployeeName",
      "MonthlySalary","DailySalary","DaysWorked","DaysEntitled",
      "GrossAmount","InceDeduction","NetAmount","IsPaid","PaidAt"
    )
    SELECT v_ps_id,e."EmployeeId",'V-26012345','Gabriela Sofia Diaz Rojas',
      2100.00,70.0000,180,15,1050.00,5.25,1044.75,false,NULL
    FROM master."Employee" e WHERE e."EmployeeCode"='V-26012345' AND e."CompanyId"=1
    ON CONFLICT DO NOTHING;
  END IF;

  RAISE NOTICE '   ProfitSharing + ProfitSharingLine procesado.';
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE 'Error en seed ProfitSharing: %', SQLERRM;
END $$;
-- +goose StatementEnd

-- ----------------------------------------------------------------------------
-- Seed: hr."OccupationalHealth"
-- ----------------------------------------------------------------------------
-- +goose StatementBegin
DO $$
BEGIN
  RAISE NOTICE '>> Seed: OccupationalHealth';

  INSERT INTO hr."OccupationalHealth" (
    "CompanyId","CountryCode","RecordType",
    "EmployeeId","EmployeeCode","EmployeeName",
    "OccurrenceDate","ReportDeadline","ReportedDate",
    "Severity","BodyPartAffected","DaysLost","Location",
    "Description","RootCause","CorrectiveAction",
    "InvestigationDueDate","InvestigationCompletedDate",
    "InstitutionReference","Status","Notes",
    "CreatedBy","CreatedAt","UpdatedAt"
  )
  SELECT 1,'VE','ACCIDENTE',
    e."EmployeeId",'V-25678901','Roberto Jose Herrera Blanco',
    '2025-09-15','2025-09-19','2025-09-16',
    'LEVE','Mano derecha',2,'Almacen principal',
    'Corte superficial en mano derecha al manipular cajas de inventario.',
    'Ausencia de guantes de proteccion durante manipulacion de cajas.',
    'Dotacion inmediata de guantes de seguridad. Charla de refuerzo sobre EPP.',
    '2025-09-22','2025-09-20',
    'INPSASEL-2025-09-004571','CLOSED','Caso cerrado. Empleado reincorporado el 2025-09-17.',
    1,(NOW() AT TIME ZONE 'UTC'),(NOW() AT TIME ZONE 'UTC')
  FROM master."Employee" e WHERE e."EmployeeCode"='V-25678901' AND e."CompanyId"=1
  AND NOT EXISTS (
    SELECT 1 FROM hr."OccupationalHealth"
    WHERE "CompanyId"=1 AND "EmployeeCode"='V-25678901' AND "OccurrenceDate"='2025-09-15'
  );

  INSERT INTO hr."OccupationalHealth" (
    "CompanyId","CountryCode","RecordType",
    "EmployeeId","EmployeeCode","EmployeeName",
    "OccurrenceDate","ReportDeadline","ReportedDate",
    "Severity","BodyPartAffected","DaysLost","Location",
    "Description","RootCause","CorrectiveAction",
    "InvestigationDueDate","InvestigationCompletedDate",
    "InstitutionReference","Status","Notes",
    "CreatedBy","CreatedAt","UpdatedAt"
  )
  SELECT 1,'VE','INCIDENTE',
    e."EmployeeId",'V-18901234','Luis Eduardo Perez Mendoza',
    '2025-11-03','2025-11-07','2025-11-04',
    'LEVE',NULL,0,'Oficina administrativa',
    'Derrame de liquido en pasillo causo resbalo sin caida ni lesion.',
    'Falta de senalizacion de piso mojado.',
    'Instalacion de porta avisos de piso humedo en cada area. Protocolo de limpieza actualizado.',
    '2025-11-10',NULL,
    NULL,'REPORTED','Incidente reportado. Sin lesion. Pendiente cierre de investigacion.',
    1,(NOW() AT TIME ZONE 'UTC'),(NOW() AT TIME ZONE 'UTC')
  FROM master."Employee" e WHERE e."EmployeeCode"='V-18901234' AND e."CompanyId"=1
  AND NOT EXISTS (
    SELECT 1 FROM hr."OccupationalHealth"
    WHERE "CompanyId"=1 AND "EmployeeCode"='V-18901234' AND "OccurrenceDate"='2025-11-03'
  );

  INSERT INTO hr."OccupationalHealth" (
    "CompanyId","CountryCode","RecordType",
    "EmployeeId","EmployeeCode","EmployeeName",
    "OccurrenceDate","ReportDeadline","ReportedDate",
    "Severity","BodyPartAffected","DaysLost","Location",
    "Description","RootCause","CorrectiveAction",
    "InvestigationDueDate","InvestigationCompletedDate",
    "InstitutionReference","Status","Notes",
    "CreatedBy","CreatedAt","UpdatedAt"
  )
  SELECT 1,'VE','ENFERMEDAD_OCUPACIONAL',
    e."EmployeeId",'V-12345678','Maria Elena Gonzalez Perez',
    '2025-07-10','2025-07-14','2025-07-11',
    'MODERADA','Columna lumbar',15,'Oficina contabilidad',
    'Lumbalgia cronica por postura inadecuada en estacion de trabajo.',
    'Escritorio y silla sin ergonomia adecuada. Largas horas sentada.',
    'Adquisicion de silla ergonomica. Pausas activas cada 2 horas.',
    '2025-07-17','2025-07-16',
    'INPSASEL-2025-07-001234','CLOSED','Empleada en tratamiento fisioterapeutico. Reincorporada con restricciones.',
    1,(NOW() AT TIME ZONE 'UTC'),(NOW() AT TIME ZONE 'UTC')
  FROM master."Employee" e WHERE e."EmployeeCode"='V-12345678' AND e."CompanyId"=1
  AND NOT EXISTS (
    SELECT 1 FROM hr."OccupationalHealth"
    WHERE "CompanyId"=1 AND "EmployeeCode"='V-12345678' AND "OccurrenceDate"='2025-07-10'
  );

  INSERT INTO hr."OccupationalHealth" (
    "CompanyId","CountryCode","RecordType",
    "EmployeeId","EmployeeCode","EmployeeName",
    "OccurrenceDate","ReportDeadline","ReportedDate",
    "Severity","BodyPartAffected","DaysLost","Location",
    "Description","RootCause","CorrectiveAction",
    "InvestigationDueDate","InvestigationCompletedDate",
    "InstitutionReference","Status","Notes",
    "CreatedBy","CreatedAt","UpdatedAt"
  )
  SELECT 1,'VE','ACCIDENTE',
    e."EmployeeId",'V-22678901','Miguel Angel Castillo Reyes',
    '2025-12-05','2025-12-09','2025-12-06',
    'GRAVE','Pie izquierdo',30,'Deposito de materiales',
    'Fractura de metatarso por caida de pallet en deposito.',
    'Pallet mal apilado. Ausencia de calzado de seguridad.',
    'Dotacion obligatoria de calzado de seguridad. Revision de procedimiento de almacenaje.',
    '2025-12-12',NULL,
    'INPSASEL-2025-12-009876','INVESTIGATING','En investigacion. Empleado con reposo medico.',
    1,(NOW() AT TIME ZONE 'UTC'),(NOW() AT TIME ZONE 'UTC')
  FROM master."Employee" e WHERE e."EmployeeCode"='V-22678901' AND e."CompanyId"=1
  AND NOT EXISTS (
    SELECT 1 FROM hr."OccupationalHealth"
    WHERE "CompanyId"=1 AND "EmployeeCode"='V-22678901' AND "OccurrenceDate"='2025-12-05'
  );

  INSERT INTO hr."OccupationalHealth" (
    "CompanyId","CountryCode","RecordType",
    "EmployeeId","EmployeeCode","EmployeeName",
    "OccurrenceDate","ReportDeadline","ReportedDate",
    "Severity","BodyPartAffected","DaysLost","Location",
    "Description","RootCause","CorrectiveAction",
    "InvestigationDueDate","InvestigationCompletedDate",
    "InstitutionReference","Status","Notes",
    "CreatedBy","CreatedAt","UpdatedAt"
  )
  SELECT 1,'VE','INCIDENTE',
    e."EmployeeId",'V-14567890','Carlos Alberto Rodriguez Silva',
    '2026-01-20','2026-01-24','2026-01-21',
    'LEVE','Sin lesion',0,'Estacionamiento empresa',
    'Conato de incendio en vehiculo propio estacionado. Sin victimas.',
    'Cortocircuito electrico en vehiculo. No relacionado con operaciones empresa.',
    'Revision del protocolo de emergencias. Actualizacion del plan de evacuacion.',
    '2026-01-27',NULL,
    NULL,'REPORTED','Reporte preventivo. Bomberos atendieron. Sin lesionados.',
    1,(NOW() AT TIME ZONE 'UTC'),(NOW() AT TIME ZONE 'UTC')
  FROM master."Employee" e WHERE e."EmployeeCode"='V-14567890' AND e."CompanyId"=1
  AND NOT EXISTS (
    SELECT 1 FROM hr."OccupationalHealth"
    WHERE "CompanyId"=1 AND "EmployeeCode"='V-14567890' AND "OccurrenceDate"='2026-01-20'
  );

  RAISE NOTICE '   OccupationalHealth procesado.';
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE 'Error en seed OccupationalHealth: %', SQLERRM;
END $$;
-- +goose StatementEnd

-- ----------------------------------------------------------------------------
-- Seed: hr."MedicalExam"
-- ----------------------------------------------------------------------------
-- +goose StatementBegin
DO $$
BEGIN
  RAISE NOTICE '>> Seed: MedicalExam';

  INSERT INTO hr."MedicalExam" (
    "CompanyId","EmployeeId","EmployeeCode","EmployeeName",
    "ExamType","ExamDate","NextDueDate","Result","Restrictions",
    "PhysicianName","ClinicName","Notes","CreatedAt","UpdatedAt"
  )
  SELECT 1,e."EmployeeId",'V-25678901','Roberto Jose Herrera Blanco',
    'PREEMPLEO','2024-02-20',NULL,'APTO',NULL,
    'Dra. Maria Gonzalez','Centro Medico La Trinidad',
    'Examen preempleo sin observaciones.',(NOW() AT TIME ZONE 'UTC'),(NOW() AT TIME ZONE 'UTC')
  FROM master."Employee" e WHERE e."EmployeeCode"='V-25678901' AND e."CompanyId"=1
  AND NOT EXISTS (SELECT 1 FROM hr."MedicalExam" WHERE "CompanyId"=1 AND "EmployeeCode"='V-25678901' AND "ExamType"='PREEMPLEO');

  INSERT INTO hr."MedicalExam" (
    "CompanyId","EmployeeId","EmployeeCode","EmployeeName",
    "ExamType","ExamDate","NextDueDate","Result","Restrictions",
    "PhysicianName","ClinicName","Notes","CreatedAt","UpdatedAt"
  )
  SELECT 1,e."EmployeeId",'V-18901234','Luis Eduardo Perez Mendoza',
    'PREEMPLEO','2024-05-10',NULL,'APTO',NULL,
    'Dr. Carlos Ramirez','Clinica Santa Sofia',
    'Examen preempleo sin restricciones.',(NOW() AT TIME ZONE 'UTC'),(NOW() AT TIME ZONE 'UTC')
  FROM master."Employee" e WHERE e."EmployeeCode"='V-18901234' AND e."CompanyId"=1
  AND NOT EXISTS (SELECT 1 FROM hr."MedicalExam" WHERE "CompanyId"=1 AND "EmployeeCode"='V-18901234' AND "ExamType"='PREEMPLEO');

  INSERT INTO hr."MedicalExam" (
    "CompanyId","EmployeeId","EmployeeCode","EmployeeName",
    "ExamType","ExamDate","NextDueDate","Result","Restrictions",
    "PhysicianName","ClinicName","Notes","CreatedAt","UpdatedAt"
  )
  SELECT 1,e."EmployeeId",'V-25678901','Roberto Jose Herrera Blanco',
    'PERIODICO','2025-02-18','2026-02-18','APTO',NULL,
    'Dra. Maria Gonzalez','Centro Medico La Trinidad',
    'Control anual. Sin hallazgos relevantes.',(NOW() AT TIME ZONE 'UTC'),(NOW() AT TIME ZONE 'UTC')
  FROM master."Employee" e WHERE e."EmployeeCode"='V-25678901' AND e."CompanyId"=1
  AND NOT EXISTS (SELECT 1 FROM hr."MedicalExam" WHERE "CompanyId"=1 AND "EmployeeCode"='V-25678901' AND "ExamType"='PERIODICO');

  INSERT INTO hr."MedicalExam" (
    "CompanyId","EmployeeId","EmployeeCode","EmployeeName",
    "ExamType","ExamDate","NextDueDate","Result","Restrictions",
    "PhysicianName","ClinicName","Notes","CreatedAt","UpdatedAt"
  )
  SELECT 1,e."EmployeeId",'V-18901234','Luis Eduardo Perez Mendoza',
    'PERIODICO','2025-01-10','2026-01-10','APTO','Uso de lentes correctivos obligatorio',
    'Dr. Carlos Ramirez','Clinica Santa Sofia',
    'Control anual. Requiere lentes correctivos. VENCIDO — proximo examen pendiente.',(NOW() AT TIME ZONE 'UTC'),(NOW() AT TIME ZONE 'UTC')
  FROM master."Employee" e WHERE e."EmployeeCode"='V-18901234' AND e."CompanyId"=1
  AND NOT EXISTS (SELECT 1 FROM hr."MedicalExam" WHERE "CompanyId"=1 AND "EmployeeCode"='V-18901234' AND "ExamType"='PERIODICO');

  INSERT INTO hr."MedicalExam" (
    "CompanyId","EmployeeId","EmployeeCode","EmployeeName",
    "ExamType","ExamDate","NextDueDate","Result","Restrictions",
    "PhysicianName","ClinicName","Notes","CreatedAt","UpdatedAt"
  )
  SELECT 1,e."EmployeeId",'V-12345678','Maria Elena Gonzalez Perez',
    'PREEMPLEO','2020-01-05',NULL,'APTO',NULL,
    'Dr. Jose Villanueva','Clinica El Avila',
    'Examen preempleo sin observaciones.',(NOW() AT TIME ZONE 'UTC'),(NOW() AT TIME ZONE 'UTC')
  FROM master."Employee" e WHERE e."EmployeeCode"='V-12345678' AND e."CompanyId"=1
  AND NOT EXISTS (SELECT 1 FROM hr."MedicalExam" WHERE "CompanyId"=1 AND "EmployeeCode"='V-12345678' AND "ExamType"='PREEMPLEO');

  INSERT INTO hr."MedicalExam" (
    "CompanyId","EmployeeId","EmployeeCode","EmployeeName",
    "ExamType","ExamDate","NextDueDate","Result","Restrictions",
    "PhysicianName","ClinicName","Notes","CreatedAt","UpdatedAt"
  )
  SELECT 1,e."EmployeeId",'V-12345678','Maria Elena Gonzalez Perez',
    'POST_ACCIDENTE','2025-07-25','2026-01-25','APTO_CONDICIONADO','Restriccion de levantamiento de peso > 5kg por 3 meses',
    'Dra. Maria Gonzalez','Centro Medico La Trinidad',
    'Evaluacion post accidente laboral. Apta con restricciones temporales.',(NOW() AT TIME ZONE 'UTC'),(NOW() AT TIME ZONE 'UTC')
  FROM master."Employee" e WHERE e."EmployeeCode"='V-12345678' AND e."CompanyId"=1
  AND NOT EXISTS (SELECT 1 FROM hr."MedicalExam" WHERE "CompanyId"=1 AND "EmployeeCode"='V-12345678' AND "ExamType"='POST_ACCIDENTE');

  INSERT INTO hr."MedicalExam" (
    "CompanyId","EmployeeId","EmployeeCode","EmployeeName",
    "ExamType","ExamDate","NextDueDate","Result","Restrictions",
    "PhysicianName","ClinicName","Notes","CreatedAt","UpdatedAt"
  )
  SELECT 1,e."EmployeeId",'V-22678901','Miguel Angel Castillo Reyes',
    'PREEMPLEO','2021-10-25',NULL,'APTO',NULL,
    'Dr. Roberto Soto','Clinica Las Mercedes',
    'Examen preempleo sin observaciones.',(NOW() AT TIME ZONE 'UTC'),(NOW() AT TIME ZONE 'UTC')
  FROM master."Employee" e WHERE e."EmployeeCode"='V-22678901' AND e."CompanyId"=1
  AND NOT EXISTS (SELECT 1 FROM hr."MedicalExam" WHERE "CompanyId"=1 AND "EmployeeCode"='V-22678901' AND "ExamType"='PREEMPLEO');

  INSERT INTO hr."MedicalExam" (
    "CompanyId","EmployeeId","EmployeeCode","EmployeeName",
    "ExamType","ExamDate","NextDueDate","Result","Restrictions",
    "PhysicianName","ClinicName","Notes","CreatedAt","UpdatedAt"
  )
  SELECT 1,e."EmployeeId",'V-14567890','Carlos Alberto Rodriguez Silva',
    'PERIODICO','2025-06-15','2026-06-15','APTO',NULL,
    'Dr. Jose Villanueva','Clinica El Avila',
    'Control anual. Sin hallazgos relevantes.',(NOW() AT TIME ZONE 'UTC'),(NOW() AT TIME ZONE 'UTC')
  FROM master."Employee" e WHERE e."EmployeeCode"='V-14567890' AND e."CompanyId"=1
  AND NOT EXISTS (SELECT 1 FROM hr."MedicalExam" WHERE "CompanyId"=1 AND "EmployeeCode"='V-14567890' AND "ExamType"='PERIODICO');

  RAISE NOTICE '   MedicalExam procesado.';
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE 'Error en seed MedicalExam: %', SQLERRM;
END $$;
-- +goose StatementEnd

-- ----------------------------------------------------------------------------
-- Seed: hr."MedicalOrder"
-- ----------------------------------------------------------------------------
-- +goose StatementBegin
DO $$
BEGIN
  RAISE NOTICE '>> Seed: MedicalOrder';

  INSERT INTO hr."MedicalOrder" (
    "CompanyId","EmployeeId","EmployeeCode","EmployeeName",
    "OrderType","OrderDate","Diagnosis","PhysicianName","Prescriptions",
    "EstimatedCost","ApprovedAmount","Status","ApprovedBy","ApprovedAt",
    "Notes","CreatedAt","UpdatedAt"
  )
  SELECT 1,e."EmployeeId",'V-25678901','Roberto Jose Herrera Blanco',
    'CONSULTA','2025-10-05','Lumbalgia mecanica',
    'Dr. Pedro Martinez','Ibuprofeno 400mg c/8h x 5 dias. Reposo relativo.',
    150.00,150.00,'APROBADA',1,'2025-10-06',
    'Consulta traumatologia por dolor lumbar.',(NOW() AT TIME ZONE 'UTC'),(NOW() AT TIME ZONE 'UTC')
  FROM master."Employee" e WHERE e."EmployeeCode"='V-25678901' AND e."CompanyId"=1
  AND NOT EXISTS (SELECT 1 FROM hr."MedicalOrder" WHERE "CompanyId"=1 AND "EmployeeCode"='V-25678901' AND "OrderDate"='2025-10-05');

  INSERT INTO hr."MedicalOrder" (
    "CompanyId","EmployeeId","EmployeeCode","EmployeeName",
    "OrderType","OrderDate","Diagnosis","PhysicianName","Prescriptions",
    "EstimatedCost","ApprovedAmount","Status","ApprovedBy","ApprovedAt",
    "Notes","CreatedAt","UpdatedAt"
  )
  SELECT 1,e."EmployeeId",'V-18901234','Luis Eduardo Perez Mendoza',
    'FARMACIA','2026-01-15','Infeccion respiratoria aguda',
    'Dra. Ana Suarez','Amoxicilina 500mg c/8h x 7 dias. Reposo 2 dias.',
    80.00,80.00,'PENDIENTE',NULL,NULL,
    'Pendiente aprobacion farmacia.',(NOW() AT TIME ZONE 'UTC'),(NOW() AT TIME ZONE 'UTC')
  FROM master."Employee" e WHERE e."EmployeeCode"='V-18901234' AND e."CompanyId"=1
  AND NOT EXISTS (SELECT 1 FROM hr."MedicalOrder" WHERE "CompanyId"=1 AND "EmployeeCode"='V-18901234' AND "OrderDate"='2026-01-15');

  INSERT INTO hr."MedicalOrder" (
    "CompanyId","EmployeeId","EmployeeCode","EmployeeName",
    "OrderType","OrderDate","Diagnosis","PhysicianName","Prescriptions",
    "EstimatedCost","ApprovedAmount","Status","ApprovedBy","ApprovedAt",
    "Notes","CreatedAt","UpdatedAt"
  )
  SELECT 1,e."EmployeeId",'V-12345678','Maria Elena Gonzalez Perez',
    'ESPECIALISTA','2025-07-28','Lumbalgia cronica - interconsulta fisiatria',
    'Dra. Maria Gonzalez','Sesiones de fisioterapia x 12 sesiones.',
    800.00,800.00,'APROBADA',1,'2025-07-29',
    'Tratamiento rehabilitacion lumbar post accidente laboral.',(NOW() AT TIME ZONE 'UTC'),(NOW() AT TIME ZONE 'UTC')
  FROM master."Employee" e WHERE e."EmployeeCode"='V-12345678' AND e."CompanyId"=1
  AND NOT EXISTS (SELECT 1 FROM hr."MedicalOrder" WHERE "CompanyId"=1 AND "EmployeeCode"='V-12345678' AND "OrderDate"='2025-07-28');

  INSERT INTO hr."MedicalOrder" (
    "CompanyId","EmployeeId","EmployeeCode","EmployeeName",
    "OrderType","OrderDate","Diagnosis","PhysicianName","Prescriptions",
    "EstimatedCost","ApprovedAmount","Status","ApprovedBy","ApprovedAt",
    "Notes","CreatedAt","UpdatedAt"
  )
  SELECT 1,e."EmployeeId",'V-22678901','Miguel Angel Castillo Reyes',
    'EMERGENCIA','2025-12-05','Fractura metatarso pie izquierdo',
    'Dr. Ortopedista Ugarte','Inmovilizacion. Antibiotico. Analgesicos. Reposo 30 dias.',
    2500.00,2500.00,'APROBADA',1,'2025-12-05',
    'Atencion de emergencia por accidente laboral.',(NOW() AT TIME ZONE 'UTC'),(NOW() AT TIME ZONE 'UTC')
  FROM master."Employee" e WHERE e."EmployeeCode"='V-22678901' AND e."CompanyId"=1
  AND NOT EXISTS (SELECT 1 FROM hr."MedicalOrder" WHERE "CompanyId"=1 AND "EmployeeCode"='V-22678901' AND "OrderDate"='2025-12-05');

  INSERT INTO hr."MedicalOrder" (
    "CompanyId","EmployeeId","EmployeeCode","EmployeeName",
    "OrderType","OrderDate","Diagnosis","PhysicianName","Prescriptions",
    "EstimatedCost","ApprovedAmount","Status","ApprovedBy","ApprovedAt",
    "Notes","CreatedAt","UpdatedAt"
  )
  SELECT 1,e."EmployeeId",'V-20456789','Carmen Rosa Salazar Vega',
    'CONSULTA','2025-11-20','Tension arterial elevada',
    'Dr. Cardiologo Figuera','Losartan 50mg. Control mensual.',
    200.00,200.00,'APROBADA',1,'2025-11-21',
    'Control hipertension arterial.',(NOW() AT TIME ZONE 'UTC'),(NOW() AT TIME ZONE 'UTC')
  FROM master."Employee" e WHERE e."EmployeeCode"='V-20456789' AND e."CompanyId"=1
  AND NOT EXISTS (SELECT 1 FROM hr."MedicalOrder" WHERE "CompanyId"=1 AND "EmployeeCode"='V-20456789' AND "OrderDate"='2025-11-20');

  RAISE NOTICE '   MedicalOrder procesado.';
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE 'Error en seed MedicalOrder: %', SQLERRM;
END $$;
-- +goose StatementEnd

-- ----------------------------------------------------------------------------
-- Seed: hr."TrainingRecord"
-- ----------------------------------------------------------------------------
-- +goose StatementBegin
DO $$
BEGIN
  RAISE NOTICE '>> Seed: TrainingRecord';

  INSERT INTO hr."TrainingRecord" (
    "CompanyId","CountryCode","TrainingType","Title","Provider",
    "StartDate","EndDate","DurationHours",
    "EmployeeId","EmployeeCode","EmployeeName",
    "CertificateNumber","Result","IsRegulatory","Notes","CreatedAt","UpdatedAt"
  )
  SELECT 1,'VE','SEGURIDAD_SALUD','Induccion en Seguridad y Salud en el Trabajo (SST)','INPSASEL',
    '2024-03-05','2024-03-05',8,
    e."EmployeeId",'V-25678901','Roberto Jose Herrera Blanco',
    'SST-2024-001','APROBADO',true,'Induccion obligatoria LOPCYMAT art. 53.',(NOW() AT TIME ZONE 'UTC'),(NOW() AT TIME ZONE 'UTC')
  FROM master."Employee" e WHERE e."EmployeeCode"='V-25678901' AND e."CompanyId"=1
  AND NOT EXISTS (SELECT 1 FROM hr."TrainingRecord" WHERE "CompanyId"=1 AND "EmployeeCode"='V-25678901' AND "Title"='Induccion en Seguridad y Salud en el Trabajo (SST)');

  INSERT INTO hr."TrainingRecord" (
    "CompanyId","CountryCode","TrainingType","Title","Provider",
    "StartDate","EndDate","DurationHours",
    "EmployeeId","EmployeeCode","EmployeeName",
    "CertificateNumber","Result","IsRegulatory","Notes","CreatedAt","UpdatedAt"
  )
  SELECT 1,'VE','TECNICO','Manejo de Inventarios y WMS','Soluciones Logisticas VE',
    '2025-01-20','2025-01-24',40,
    e."EmployeeId",'V-25678901','Roberto Jose Herrera Blanco',
    'LOG-2025-042','APROBADO',false,'Certificacion manejo de sistema WMS.',(NOW() AT TIME ZONE 'UTC'),(NOW() AT TIME ZONE 'UTC')
  FROM master."Employee" e WHERE e."EmployeeCode"='V-25678901' AND e."CompanyId"=1
  AND NOT EXISTS (SELECT 1 FROM hr."TrainingRecord" WHERE "CompanyId"=1 AND "EmployeeCode"='V-25678901' AND "Title"='Manejo de Inventarios y WMS');

  INSERT INTO hr."TrainingRecord" (
    "CompanyId","CountryCode","TrainingType","Title","Provider",
    "StartDate","EndDate","DurationHours",
    "EmployeeId","EmployeeCode","EmployeeName",
    "CertificateNumber","Result","IsRegulatory","Notes","CreatedAt","UpdatedAt"
  )
  SELECT 1,'VE','SEGURIDAD_SALUD','Primeros Auxilios Basicos','Cruz Roja Venezolana',
    '2024-06-10','2024-06-11',16,
    e."EmployeeId",'V-18901234','Luis Eduardo Perez Mendoza',
    'CRV-2024-PA-0118','APROBADO',true,'Certificacion vigente 2 anos.',(NOW() AT TIME ZONE 'UTC'),(NOW() AT TIME ZONE 'UTC')
  FROM master."Employee" e WHERE e."EmployeeCode"='V-18901234' AND e."CompanyId"=1
  AND NOT EXISTS (SELECT 1 FROM hr."TrainingRecord" WHERE "CompanyId"=1 AND "EmployeeCode"='V-18901234' AND "Title"='Primeros Auxilios Basicos');

  INSERT INTO hr."TrainingRecord" (
    "CompanyId","CountryCode","TrainingType","Title","Provider",
    "StartDate","EndDate","DurationHours",
    "EmployeeId","EmployeeCode","EmployeeName",
    "CertificateNumber","Result","IsRegulatory","Notes","CreatedAt","UpdatedAt"
  )
  SELECT 1,'VE','TECNICO','Contabilidad General y NIIF para PYMES','Instituto Venezolano de Contadores',
    '2024-09-02','2024-11-29',120,
    e."EmployeeId",'V-12345678','Maria Elena Gonzalez Perez',
    'IVC-2024-CG-00234','APROBADO',false,'Diplomado contabilidad. Credito universitario.',(NOW() AT TIME ZONE 'UTC'),(NOW() AT TIME ZONE 'UTC')
  FROM master."Employee" e WHERE e."EmployeeCode"='V-12345678' AND e."CompanyId"=1
  AND NOT EXISTS (SELECT 1 FROM hr."TrainingRecord" WHERE "CompanyId"=1 AND "EmployeeCode"='V-12345678' AND "Title"='Contabilidad General y NIIF para PYMES');

  INSERT INTO hr."TrainingRecord" (
    "CompanyId","CountryCode","TrainingType","Title","Provider",
    "StartDate","EndDate","DurationHours",
    "EmployeeId","EmployeeCode","EmployeeName",
    "CertificateNumber","Result","IsRegulatory","Notes","CreatedAt","UpdatedAt"
  )
  SELECT 1,'VE','LIDERAZGO','Liderazgo y Gestion de Equipos','Escuela de Negocios IESA',
    '2025-03-03','2025-03-07',40,
    e."EmployeeId",'V-14567890','Carlos Alberto Rodriguez Silva',
    'IESA-2025-LG-0089','APROBADO',false,'Programa ejecutivo liderazgo.',(NOW() AT TIME ZONE 'UTC'),(NOW() AT TIME ZONE 'UTC')
  FROM master."Employee" e WHERE e."EmployeeCode"='V-14567890' AND e."CompanyId"=1
  AND NOT EXISTS (SELECT 1 FROM hr."TrainingRecord" WHERE "CompanyId"=1 AND "EmployeeCode"='V-14567890' AND "Title"='Liderazgo y Gestion de Equipos');

  INSERT INTO hr."TrainingRecord" (
    "CompanyId","CountryCode","TrainingType","Title","Provider",
    "StartDate","EndDate","DurationHours",
    "EmployeeId","EmployeeCode","EmployeeName",
    "CertificateNumber","Result","IsRegulatory","Notes","CreatedAt","UpdatedAt"
  )
  SELECT 1,'VE','SEGURIDAD_SALUD','Uso y Mantenimiento de Equipos de Proteccion Personal','Proveedor EPP Nacional',
    '2025-02-10','2025-02-10',4,
    e."EmployeeId",'V-22678901','Miguel Angel Castillo Reyes',
    NULL,'APROBADO',true,'Charla obligatoria post accidente. Registro INPSASEL.',(NOW() AT TIME ZONE 'UTC'),(NOW() AT TIME ZONE 'UTC')
  FROM master."Employee" e WHERE e."EmployeeCode"='V-22678901' AND e."CompanyId"=1
  AND NOT EXISTS (SELECT 1 FROM hr."TrainingRecord" WHERE "CompanyId"=1 AND "EmployeeCode"='V-22678901' AND "Title"='Uso y Mantenimiento de Equipos de Proteccion Personal');

  INSERT INTO hr."TrainingRecord" (
    "CompanyId","CountryCode","TrainingType","Title","Provider",
    "StartDate","EndDate","DurationHours",
    "EmployeeId","EmployeeCode","EmployeeName",
    "CertificateNumber","Result","IsRegulatory","Notes","CreatedAt","UpdatedAt"
  )
  SELECT 1,'VE','TECNICO','Excel Avanzado para Administracion','Centro de Capacitacion CAVECOM-E',
    '2025-01-13','2025-01-17',30,
    e."EmployeeId",'V-20456789','Carmen Rosa Salazar Vega',
    'CAVECOM-2025-EA-0015','APROBADO',false,'Excel para reportes administrativos y nomina.',(NOW() AT TIME ZONE 'UTC'),(NOW() AT TIME ZONE 'UTC')
  FROM master."Employee" e WHERE e."EmployeeCode"='V-20456789' AND e."CompanyId"=1
  AND NOT EXISTS (SELECT 1 FROM hr."TrainingRecord" WHERE "CompanyId"=1 AND "EmployeeCode"='V-20456789' AND "Title"='Excel Avanzado para Administracion');

  INSERT INTO hr."TrainingRecord" (
    "CompanyId","CountryCode","TrainingType","Title","Provider",
    "StartDate","EndDate","DurationHours",
    "EmployeeId","EmployeeCode","EmployeeName",
    "CertificateNumber","Result","IsRegulatory","Notes","CreatedAt","UpdatedAt"
  )
  SELECT 1,'VE','SEGURIDAD_SALUD','Combate Contra Incendios Nivel I','Cuerpo de Bomberos Caracas',
    '2024-11-18','2024-11-18',8,
    e."EmployeeId",'V-24890123','Laura Patricia Mora Jimenez',
    'BOMB-2024-CI-0344','APROBADO',true,'Brigada contra incendios. Certificacion vigente 1 ano.',(NOW() AT TIME ZONE 'UTC'),(NOW() AT TIME ZONE 'UTC')
  FROM master."Employee" e WHERE e."EmployeeCode"='V-24890123' AND e."CompanyId"=1
  AND NOT EXISTS (SELECT 1 FROM hr."TrainingRecord" WHERE "CompanyId"=1 AND "EmployeeCode"='V-24890123' AND "Title"='Combate Contra Incendios Nivel I');

  INSERT INTO hr."TrainingRecord" (
    "CompanyId","CountryCode","TrainingType","Title","Provider",
    "StartDate","EndDate","DurationHours",
    "EmployeeId","EmployeeCode","EmployeeName",
    "CertificateNumber","Result","IsRegulatory","Notes","CreatedAt","UpdatedAt"
  )
  SELECT 1,'VE','TECNICO','Atencion al Cliente y Servicio de Calidad','Instituto Venezolano de Calidad',
    '2025-02-24','2025-02-28',40,
    e."EmployeeId",'V-16789012','Ana Isabel Martinez Lopez',
    'IVC-2025-AC-0078','APROBADO',false,'Certificacion servicio al cliente.',(NOW() AT TIME ZONE 'UTC'),(NOW() AT TIME ZONE 'UTC')
  FROM master."Employee" e WHERE e."EmployeeCode"='V-16789012' AND e."CompanyId"=1
  AND NOT EXISTS (SELECT 1 FROM hr."TrainingRecord" WHERE "CompanyId"=1 AND "EmployeeCode"='V-16789012' AND "Title"='Atencion al Cliente y Servicio de Calidad');

  INSERT INTO hr."TrainingRecord" (
    "CompanyId","CountryCode","TrainingType","Title","Provider",
    "StartDate","EndDate","DurationHours",
    "EmployeeId","EmployeeCode","EmployeeName",
    "CertificateNumber","Result","IsRegulatory","Notes","CreatedAt","UpdatedAt"
  )
  SELECT 1,'VE','SEGURIDAD_SALUD','Induccion SST y Plan de Emergencias','Departamento SSOT Interno',
    '2023-09-05','2023-09-05',4,
    e."EmployeeId",'V-26012345','Gabriela Sofia Diaz Rojas',
    NULL,'APROBADO',true,'Induccion inicial obligatoria nueva empleada.',(NOW() AT TIME ZONE 'UTC'),(NOW() AT TIME ZONE 'UTC')
  FROM master."Employee" e WHERE e."EmployeeCode"='V-26012345' AND e."CompanyId"=1
  AND NOT EXISTS (SELECT 1 FROM hr."TrainingRecord" WHERE "CompanyId"=1 AND "EmployeeCode"='V-26012345' AND "Title"='Induccion SST y Plan de Emergencias');

  RAISE NOTICE '   TrainingRecord procesado.';
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE 'Error en seed TrainingRecord: %', SQLERRM;
END $$;
-- +goose StatementEnd

-- ----------------------------------------------------------------------------
-- Seed: hr."SafetyCommittee" + hr."SafetyCommitteeMember" + hr."SafetyCommitteeMeeting"
-- ----------------------------------------------------------------------------
-- +goose StatementBegin
DO $$
DECLARE v_comm1 INT; v_comm2 INT;
BEGIN
  RAISE NOTICE '>> Seed: SafetyCommittee';

  INSERT INTO hr."SafetyCommittee" (
    "CompanyId","CountryCode","CommitteeName","FormationDate","MeetingFrequency","IsActive","CreatedAt"
  )
  SELECT 1,'VE','Comite de Seguridad y Salud Laboral — Sede Principal','2024-01-15','MONTHLY',true,(NOW() AT TIME ZONE 'UTC')
  WHERE NOT EXISTS (
    SELECT 1 FROM hr."SafetyCommittee" WHERE "CompanyId"=1 AND "CommitteeName"='Comite de Seguridad y Salud Laboral — Sede Principal'
  );

  INSERT INTO hr."SafetyCommittee" (
    "CompanyId","CountryCode","CommitteeName","FormationDate","MeetingFrequency","IsActive","CreatedAt"
  )
  SELECT 1,'VE','Comite de Seguridad y Salud Laboral — Deposito y Operaciones','2024-03-01','MONTHLY',true,(NOW() AT TIME ZONE 'UTC')
  WHERE NOT EXISTS (
    SELECT 1 FROM hr."SafetyCommittee" WHERE "CompanyId"=1 AND "CommitteeName"='Comite de Seguridad y Salud Laboral — Deposito y Operaciones'
  );

  SELECT "SafetyCommitteeId" INTO v_comm1 FROM hr."SafetyCommittee" WHERE "CompanyId"=1 AND "CommitteeName"='Comite de Seguridad y Salud Laboral — Sede Principal';
  SELECT "SafetyCommitteeId" INTO v_comm2 FROM hr."SafetyCommittee" WHERE "CompanyId"=1 AND "CommitteeName"='Comite de Seguridad y Salud Laboral — Deposito y Operaciones';

  RAISE NOTICE '   SafetyCommittee procesado. IDs: %, %', v_comm1, v_comm2;

  -- Miembros Comite 1
  IF v_comm1 IS NOT NULL THEN
    INSERT INTO hr."SafetyCommitteeMember" ("SafetyCommitteeId","EmployeeId","EmployeeCode","EmployeeName","Role","StartDate","EndDate")
    SELECT v_comm1,e."EmployeeId",'V-12345678','Maria Elena Gonzalez Perez','PRESIDENTE','2024-01-15',NULL
    FROM master."Employee" e WHERE e."EmployeeCode"='V-12345678' AND e."CompanyId"=1
    AND NOT EXISTS (SELECT 1 FROM hr."SafetyCommitteeMember" WHERE "SafetyCommitteeId"=v_comm1 AND "EmployeeCode"='V-12345678');

    INSERT INTO hr."SafetyCommitteeMember" ("SafetyCommitteeId","EmployeeId","EmployeeCode","EmployeeName","Role","StartDate","EndDate")
    SELECT v_comm1,e."EmployeeId",'V-14567890','Carlos Alberto Rodriguez Silva','SECRETARIO','2024-01-15',NULL
    FROM master."Employee" e WHERE e."EmployeeCode"='V-14567890' AND e."CompanyId"=1
    AND NOT EXISTS (SELECT 1 FROM hr."SafetyCommitteeMember" WHERE "SafetyCommitteeId"=v_comm1 AND "EmployeeCode"='V-14567890');

    INSERT INTO hr."SafetyCommitteeMember" ("SafetyCommitteeId","EmployeeId","EmployeeCode","EmployeeName","Role","StartDate","EndDate")
    SELECT v_comm1,e."EmployeeId",'V-20456789','Carmen Rosa Salazar Vega','VOCAL','2024-01-15',NULL
    FROM master."Employee" e WHERE e."EmployeeCode"='V-20456789' AND e."CompanyId"=1
    AND NOT EXISTS (SELECT 1 FROM hr."SafetyCommitteeMember" WHERE "SafetyCommitteeId"=v_comm1 AND "EmployeeCode"='V-20456789');

    -- Reuniones Comite 1
    INSERT INTO hr."SafetyCommitteeMeeting" ("SafetyCommitteeId","MeetingDate","TopicsSummary","ActionItems","CreatedAt")
    SELECT v_comm1,'2025-09-10 09:00:00',
      'Revision de indices de accidentalidad Q3 2025. Plan de accion para EPP. Actualizacion mapa de riesgos.',
      '1. Adquirir 50 pares de guantes de seguridad. 2. Actualizar mapa de riesgos antes del 30/09. 3. Programar charla EPP para operaciones.',
      (NOW() AT TIME ZONE 'UTC')
    WHERE NOT EXISTS (SELECT 1 FROM hr."SafetyCommitteeMeeting" WHERE "SafetyCommitteeId"=v_comm1 AND "MeetingDate"='2025-09-10 09:00:00');

    INSERT INTO hr."SafetyCommitteeMeeting" ("SafetyCommitteeId","MeetingDate","TopicsSummary","ActionItems","CreatedAt")
    SELECT v_comm1,'2025-10-15 09:00:00',
      'Seguimiento accidente V-25678901. Revision dotacion EPP. Evaluacion programa pausas activas.',
      '1. Verificar dotacion EPP completada. 2. Implementar programa pausas activas. 3. Notificar INPSASEL cierre investigacion.',
      (NOW() AT TIME ZONE 'UTC')
    WHERE NOT EXISTS (SELECT 1 FROM hr."SafetyCommitteeMeeting" WHERE "SafetyCommitteeId"=v_comm1 AND "MeetingDate"='2025-10-15 09:00:00');

    INSERT INTO hr."SafetyCommitteeMeeting" ("SafetyCommitteeId","MeetingDate","TopicsSummary","ActionItems","CreatedAt")
    SELECT v_comm1,'2025-12-10 09:00:00',
      'Balance anual SST 2025. Planificacion plan SST 2026. Renovacion certificaciones brigadas.',
      '1. Preparar informe anual INPSASEL. 2. Elaborar plan SST 2026 para enero. 3. Renovar certificaciones brigadas Q1 2026.',
      (NOW() AT TIME ZONE 'UTC')
    WHERE NOT EXISTS (SELECT 1 FROM hr."SafetyCommitteeMeeting" WHERE "SafetyCommitteeId"=v_comm1 AND "MeetingDate"='2025-12-10 09:00:00');
  END IF;

  -- Miembros Comite 2
  IF v_comm2 IS NOT NULL THEN
    INSERT INTO hr."SafetyCommitteeMember" ("SafetyCommitteeId","EmployeeId","EmployeeCode","EmployeeName","Role","StartDate","EndDate")
    SELECT v_comm2,e."EmployeeId",'V-22678901','Miguel Angel Castillo Reyes','PRESIDENTE','2024-03-01',NULL
    FROM master."Employee" e WHERE e."EmployeeCode"='V-22678901' AND e."CompanyId"=1
    AND NOT EXISTS (SELECT 1 FROM hr."SafetyCommitteeMember" WHERE "SafetyCommitteeId"=v_comm2 AND "EmployeeCode"='V-22678901');

    INSERT INTO hr."SafetyCommitteeMember" ("SafetyCommitteeId","EmployeeId","EmployeeCode","EmployeeName","Role","StartDate","EndDate")
    SELECT v_comm2,e."EmployeeId",'V-24890123','Laura Patricia Mora Jimenez','SECRETARIO','2024-03-01',NULL
    FROM master."Employee" e WHERE e."EmployeeCode"='V-24890123' AND e."CompanyId"=1
    AND NOT EXISTS (SELECT 1 FROM hr."SafetyCommitteeMember" WHERE "SafetyCommitteeId"=v_comm2 AND "EmployeeCode"='V-24890123');

    -- Reunion Comite 2
    INSERT INTO hr."SafetyCommitteeMeeting" ("SafetyCommitteeId","MeetingDate","TopicsSummary","ActionItems","CreatedAt")
    SELECT v_comm2,'2025-12-08 10:00:00',
      'Revision accidente grave V-22678901. Analisis causalidad. Plan correctivo deposito.',
      '1. Implementar sistema anti-caida pallets. 2. Verificar calzado seguridad 100% operaciones. 3. Simulacro evacuacion Q1 2026.',
      (NOW() AT TIME ZONE 'UTC')
    WHERE NOT EXISTS (SELECT 1 FROM hr."SafetyCommitteeMeeting" WHERE "SafetyCommitteeId"=v_comm2 AND "MeetingDate"='2025-12-08 10:00:00');

    INSERT INTO hr."SafetyCommitteeMeeting" ("SafetyCommitteeId","MeetingDate","TopicsSummary","ActionItems","CreatedAt")
    SELECT v_comm2,'2026-01-12 10:00:00',
      'Seguimiento plan correctivo deposito. Estado de reposo V-22678901. Preparacion informe INPSASEL.',
      '1. Documentar implementacion mejoras. 2. Informe INPSASEL antes del 15/02. 3. Planificar induccion nuevos operadores.',
      (NOW() AT TIME ZONE 'UTC')
    WHERE NOT EXISTS (SELECT 1 FROM hr."SafetyCommitteeMeeting" WHERE "SafetyCommitteeId"=v_comm2 AND "MeetingDate"='2026-01-12 10:00:00');
  END IF;

  RAISE NOTICE '   SafetyCommitteeMember y SafetyCommitteeMeeting procesados.';
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE 'Error en seed SafetyCommittee: %', SQLERRM;
END $$;
-- +goose StatementEnd

-- Source: includes/sp/create_contabilidad_general.sql
-- ============================================================
-- DatqBoxWeb PostgreSQL - create_contabilidad_general.sql
-- Contabilidad general base: estructura contable nuclear,
-- enlaces contables a tablas auxiliares, plan de cuentas base
-- y centros de costo iniciales.
-- ============================================================

DO $body$
BEGIN

    -- NOTA: Tablas legacy public.* eliminadas (2026-03-16).
    -- Usar acct.JournalEntry, acct.Account, acct.JournalEntryLine, etc.
    -- Tablas eliminadas: PeriodoContable, AsientoContable, AsientoContableDetalle,
    --   AsientoOrigenAuxiliar, ConfiguracionContableAuxiliar, AjusteContable,
    --   ActivoFijoContable, DepreciacionContable (y sus indices asociados).

    -- Enlaces contables a auxiliares existentes (ADD COLUMN IF NOT EXISTS)
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'DocumentosVenta' AND table_schema = 'public' AND table_type = 'BASE TABLE') THEN
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'DocumentosVenta' AND column_name = 'Asiento_Id') THEN
            ALTER TABLE public."DocumentosVenta" ADD COLUMN "Asiento_Id" BIGINT NULL;
        END IF;
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'DocumentosVenta' AND column_name = 'Centro_Costo') THEN
            ALTER TABLE public."DocumentosVenta" ADD COLUMN "Centro_Costo" VARCHAR(20) NULL;
        END IF;
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'DocumentosVentaDetalle' AND table_schema = 'public' AND table_type = 'BASE TABLE') THEN
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'DocumentosVentaDetalle' AND column_name = 'Cod_Cuenta') THEN
            ALTER TABLE public."DocumentosVentaDetalle" ADD COLUMN "Cod_Cuenta" VARCHAR(40) NULL;
        END IF;
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'DocumentosVentaDetalle' AND column_name = 'Centro_Costo') THEN
            ALTER TABLE public."DocumentosVentaDetalle" ADD COLUMN "Centro_Costo" VARCHAR(20) NULL;
        END IF;
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'DocumentosCompra' AND table_schema = 'public' AND table_type = 'BASE TABLE') THEN
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'DocumentosCompra' AND column_name = 'Asiento_Id') THEN
            ALTER TABLE public."DocumentosCompra" ADD COLUMN "Asiento_Id" BIGINT NULL;
        END IF;
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'DocumentosCompra' AND column_name = 'Centro_Costo') THEN
            ALTER TABLE public."DocumentosCompra" ADD COLUMN "Centro_Costo" VARCHAR(20) NULL;
        END IF;
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'DocumentosCompraDetalle' AND table_schema = 'public' AND table_type = 'BASE TABLE') THEN
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'DocumentosCompraDetalle' AND column_name = 'Cod_Cuenta') THEN
            ALTER TABLE public."DocumentosCompraDetalle" ADD COLUMN "Cod_Cuenta" VARCHAR(40) NULL;
        END IF;
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'DocumentosCompraDetalle' AND column_name = 'Centro_Costo') THEN
            ALTER TABLE public."DocumentosCompraDetalle" ADD COLUMN "Centro_Costo" VARCHAR(20) NULL;
        END IF;
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'p_cobrar' AND table_schema = 'public') THEN
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'p_cobrar' AND column_name = 'Cod_Cuenta') THEN
            ALTER TABLE public."p_cobrar" ADD COLUMN "Cod_Cuenta" VARCHAR(40) NULL;
        END IF;
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'p_cobrar' AND column_name = 'Centro_Costo') THEN
            ALTER TABLE public."p_cobrar" ADD COLUMN "Centro_Costo" VARCHAR(20) NULL;
        END IF;
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'p_cobrar' AND column_name = 'Asiento_Id') THEN
            ALTER TABLE public."p_cobrar" ADD COLUMN "Asiento_Id" BIGINT NULL;
        END IF;
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'P_Pagar' AND table_schema = 'public') THEN
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'P_Pagar' AND column_name = 'Cod_Cuenta') THEN
            ALTER TABLE public."P_Pagar" ADD COLUMN "Cod_Cuenta" VARCHAR(40) NULL;
        END IF;
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'P_Pagar' AND column_name = 'Centro_Costo') THEN
            ALTER TABLE public."P_Pagar" ADD COLUMN "Centro_Costo" VARCHAR(20) NULL;
        END IF;
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'P_Pagar' AND column_name = 'Asiento_Id') THEN
            ALTER TABLE public."P_Pagar" ADD COLUMN "Asiento_Id" BIGINT NULL;
        END IF;
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'MovInvent' AND table_schema = 'public') THEN
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'MovInvent' AND column_name = 'Cod_Cuenta') THEN
            ALTER TABLE public."MovInvent" ADD COLUMN "Cod_Cuenta" VARCHAR(40) NULL;
        END IF;
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'MovInvent' AND column_name = 'Centro_Costo') THEN
            ALTER TABLE public."MovInvent" ADD COLUMN "Centro_Costo" VARCHAR(20) NULL;
        END IF;
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'MovInvent' AND column_name = 'Asiento_Id') THEN
            ALTER TABLE public."MovInvent" ADD COLUMN "Asiento_Id" BIGINT NULL;
        END IF;
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'Abonos' AND table_schema = 'public') THEN
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'Abonos' AND column_name = 'Cod_Cuenta') THEN
            ALTER TABLE public."Abonos" ADD COLUMN "Cod_Cuenta" VARCHAR(40) NULL;
        END IF;
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'Abonos' AND column_name = 'Centro_Costo') THEN
            ALTER TABLE public."Abonos" ADD COLUMN "Centro_Costo" VARCHAR(20) NULL;
        END IF;
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'Abonos' AND column_name = 'Asiento_Id') THEN
            ALTER TABLE public."Abonos" ADD COLUMN "Asiento_Id" BIGINT NULL;
        END IF;
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'pagos' AND table_schema = 'public') THEN
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'pagos' AND column_name = 'Cod_Cuenta') THEN
            ALTER TABLE public."pagos" ADD COLUMN "Cod_Cuenta" VARCHAR(40) NULL;
        END IF;
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'pagos' AND column_name = 'Centro_Costo') THEN
            ALTER TABLE public."pagos" ADD COLUMN "Centro_Costo" VARCHAR(20) NULL;
        END IF;
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'pagos' AND column_name = 'Asiento_Id') THEN
            ALTER TABLE public."pagos" ADD COLUMN "Asiento_Id" BIGINT NULL;
        END IF;
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'Pagosc' AND table_schema = 'public') THEN
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'Pagosc' AND column_name = 'Cod_Cuenta') THEN
            ALTER TABLE public."Pagosc" ADD COLUMN "Cod_Cuenta" VARCHAR(40) NULL;
        END IF;
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'Pagosc' AND column_name = 'Centro_Costo') THEN
            ALTER TABLE public."Pagosc" ADD COLUMN "Centro_Costo" VARCHAR(20) NULL;
        END IF;
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'Pagosc' AND column_name = 'Asiento_Id') THEN
            ALTER TABLE public."Pagosc" ADD COLUMN "Asiento_Id" BIGINT NULL;
        END IF;
    END IF;

    -- Seed: Centros de Costo base
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'Centro_Costo' AND table_schema = 'public') THEN
        INSERT INTO public."Centro_Costo" ("Codigo", "Descripcion", "Presupuestado", "Saldo_Real")
        SELECT v.* FROM (VALUES
            ('ADM', 'Administracion',     '0', '0'),
            ('VEN', 'Ventas',             '0', '0'),
            ('COM', 'Compras',            '0', '0'),
            ('ALM', 'Almacen',            '0', '0'),
            ('BAN', 'Bancos y Tesoreria', '0', '0')
        ) AS v("Codigo", "Descripcion", "Presupuestado", "Saldo_Real")
        WHERE NOT EXISTS (SELECT 1 FROM public."Centro_Costo" cc WHERE cc."Codigo" = v."Codigo");
    END IF;

    -- Seed: Plan de Cuentas base
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'Cuentas' AND table_schema = 'public' AND table_type = 'BASE TABLE') THEN
        INSERT INTO public."Cuentas" ("Cod_Cuenta", "Desc_Cta", "Tipo", "Nivel", "Cod_CtaPadre", "Activo", "Accepta_Detalle")
        SELECT s."COD_CUENTA", s."DESCRIPCION",
               (CASE s."grupo" WHEN '1' THEN 'A' WHEN '2' THEN 'P' WHEN '3' THEN 'C' WHEN '4' THEN 'I' WHEN '5' THEN 'G' WHEN '6' THEN 'G' WHEN '7' THEN 'C' ELSE 'A' END)::CHAR(1),
               s."Nivel",
               CASE WHEN s."Nivel" = 1 THEN NULL
                    ELSE REGEXP_REPLACE(s."COD_CUENTA", '\.[^.]+$',''::VARCHAR)
               END,
               TRUE,
               CASE WHEN s."USO" = 'MOV' THEN TRUE ELSE FALSE END
        FROM (VALUES
            ('1',      'ACTIVOS',                          'D', '1', 'GENERAL',       'HEADER', 1),
            ('1.1',    'ACTIVO CORRIENTE',                 'D', '1', 'GENERAL',       'HEADER', 2),
            ('1.1.01', 'CAJA',                             'D', '1', 'TESORERIA',     'MOV',    3),
            ('1.1.02', 'BANCOS',                           'D', '1', 'TESORERIA',     'MOV',    3),
            ('1.1.03', 'CUENTAS POR COBRAR COMERCIALES',   'D', '1', 'CXC',           'MOV',    3),
            ('1.1.04', 'RETENCIONES POR RECUPERAR',        'D', '1', 'IMPUESTOS',     'MOV',    3),
            ('1.1.05', 'INVENTARIOS MERCANCIA',            'D', '1', 'INVENTARIO',    'MOV',    3),
            ('1.1.06', 'GASTOS PAGADOS POR ANTICIPADO',    'D', '1', 'GENERAL',       'MOV',    3),
            ('1.2',    'ACTIVO NO CORRIENTE',              'D', '1', 'GENERAL',       'HEADER', 2),
            ('1.2.01', 'PROPIEDAD, PLANTA Y EQUIPO',       'D', '1', 'ACTIVOS_FIJOS', 'MOV',    3),
            ('1.2.02', 'DEPRECIACION ACUMULADA PPE',       'A', '1', 'ACTIVOS_FIJOS', 'MOV',    3),
            ('1.2.03', 'ACTIVOS INTANGIBLES',              'D', '1', 'ACTIVOS_FIJOS', 'MOV',    3),
            ('2',      'PASIVOS',                          'A', '2', 'GENERAL',       'HEADER', 1),
            ('2.1',    'PASIVO CORRIENTE',                 'A', '2', 'GENERAL',       'HEADER', 2),
            ('2.1.01', 'CUENTAS POR PAGAR PROVEEDORES',    'A', '2', 'CXP',           'MOV',    3),
            ('2.1.02', 'RETENCIONES POR PAGAR',            'A', '2', 'IMPUESTOS',     'MOV',    3),
            ('2.1.03', 'IMPUESTOS POR PAGAR',              'A', '2', 'IMPUESTOS',     'MOV',    3),
            ('2.1.04', 'OBLIGACIONES LABORALES POR PAGAR', 'A', '2', 'NOMINA',        'MOV',    3),
            ('2.1.05', 'ANTICIPOS DE CLIENTES',            'A', '2', 'CXC',           'MOV',    3),
            ('2.2',    'PASIVO NO CORRIENTE',              'A', '2', 'GENERAL',       'HEADER', 2),
            ('2.2.01', 'PRESTAMOS LARGO PLAZO',            'A', '2', 'FINANCIERO',    'MOV',    3),
            ('3',      'PATRIMONIO',                       'A', '3', 'GENERAL',       'HEADER', 1),
            ('3.1',    'CAPITAL SOCIAL',                   'A', '3', 'GENERAL',       'MOV',    2),
            ('3.2',    'RESERVAS',                         'A', '3', 'GENERAL',       'MOV',    2),
            ('3.3',    'RESULTADOS ACUMULADOS',            'A', '3', 'GENERAL',       'MOV',    2),
            ('3.4',    'UTILIDAD O PERDIDA DEL EJERCICIO', 'A', '3', 'GENERAL',       'MOV',    2),
            ('4',      'INGRESOS',                         'A', '4', 'GENERAL',       'HEADER', 1),
            ('4.1',    'INGRESOS OPERACIONALES',           'A', '4', 'VENTAS',        'HEADER', 2),
            ('4.1.01', 'VENTAS GRAVADAS',                  'A', '4', 'VENTAS',        'MOV',    3),
            ('4.1.02', 'VENTAS EXENTAS',                   'A', '4', 'VENTAS',        'MOV',    3),
            ('4.1.03', 'SERVICIOS PRESTADOS',              'A', '4', 'VENTAS',        'MOV',    3),
            ('4.2',    'INGRESOS NO OPERACIONALES',        'A', '4', 'GENERAL',       'HEADER', 2),
            ('4.2.01', 'OTROS INGRESOS',                   'A', '4', 'GENERAL',       'MOV',    3),
            ('5',      'COSTOS',                           'D', '5', 'GENERAL',       'HEADER', 1),
            ('5.1',    'COSTO DE VENTAS',                  'D', '5', 'INVENTARIO',    'MOV',    2),
            ('5.2',    'COSTO DE SERVICIOS',               'D', '5', 'SERVICIOS',     'MOV',    2),
            ('6',      'GASTOS OPERACIONALES',             'D', '6', 'GENERAL',       'HEADER', 1),
            ('6.1',    'GASTOS DE ADMINISTRACION',         'D', '6', 'ADMIN',         'HEADER', 2),
            ('6.1.01', 'SUELDOS Y SALARIOS ADMIN',         'D', '6', 'NOMINA',        'MOV',    3),
            ('6.1.02', 'ALQUILERES',                       'D', '6', 'ADMIN',         'MOV',    3),
            ('6.1.03', 'SERVICIOS BASICOS',                'D', '6', 'ADMIN',         'MOV',    3),
            ('6.1.04', 'DEPRECIACION DEL EJERCICIO',       'D', '6', 'ACTIVOS_FIJOS', 'MOV',    3),
            ('6.2',    'GASTOS DE VENTAS',                 'D', '6', 'VENTAS',        'HEADER', 2),
            ('6.2.01', 'COMISIONES DE VENTAS',             'D', '6', 'VENTAS',        'MOV',    3),
            ('6.2.02', 'PUBLICIDAD Y MERCADEO',            'D', '6', 'VENTAS',        'MOV',    3),
            ('7',      'RESULTADO INTEGRAL Y CIERRE',      'A', '7', 'CIERRE',        'HEADER', 1),
            ('7.1',    'RESUMEN DE INGRESOS',              'A', '7', 'CIERRE',        'MOV',    2),
            ('7.2',    'RESUMEN DE COSTOS Y GASTOS',       'D', '7', 'CIERRE',        'MOV',    2)
        ) AS s("COD_CUENTA", "DESCRIPCION", "TIPO", "grupo", "LINEA", "USO", "Nivel")
        WHERE NOT EXISTS (SELECT 1 FROM public."Cuentas" c WHERE c."Cod_Cuenta" = s."COD_CUENTA");
    END IF;

EXCEPTION WHEN OTHERS THEN
    RAISE EXCEPTION 'Error create_contabilidad_general.sql: %', SQLERRM;
END;
$body$;

-- Source: includes/sp/create_fiscal_tributaria.sql
/*
================================================================================
  MÓDULO FISCAL / TRIBUTARIA (PostgreSQL)
  Gestión de declaraciones, libros fiscales, retenciones y plantillas
  Multi-país: VE, ES, CO, MX, US

  Tablas:
    fiscal."TaxDeclaration"      - Declaraciones tributarias (IVA, ISLR, IRPF, etc.)
    fiscal."TaxBookEntry"        - Líneas del libro de compras/ventas
    fiscal."WithholdingVoucher"  - Comprobantes de retención
    fiscal."DeclarationTemplate" - Plantillas de declaración por país
    fiscal."ISLRTariff"          - Tabla progresiva ISLR Venezuela

  Seed data:
    - Plantillas de declaración (VE, ES)
    - Tarifa ISLR Venezuela 2026
    - Complemento master."TaxRetention" (VE, ES)
================================================================================
*/

-- +goose StatementBegin
DO $$
BEGIN

  -- ============================================================
  -- ESQUEMA fiscal
  -- ============================================================
  CREATE SCHEMA IF NOT EXISTS fiscal;
  RAISE NOTICE '>> Esquema fiscal verificado.';

  -- ============================================================
  -- 1. fiscal."TaxDeclaration" - Declaraciones tributarias
  -- ============================================================
  CREATE TABLE IF NOT EXISTS fiscal."TaxDeclaration" (
    "DeclarationId"       BIGINT GENERATED ALWAYS AS IDENTITY NOT NULL,
    "CompanyId"           INTEGER NOT NULL,
    "BranchId"            INTEGER NOT NULL DEFAULT 0,
    "CountryCode"         VARCHAR(2) NOT NULL,
    "DeclarationType"     VARCHAR(30) NOT NULL,       -- IVA, ISLR, IRPF, MODELO_303, MODELO_390, MODELO_349
    "PeriodCode"          VARCHAR(7) NOT NULL,         -- YYYY-MM
    "PeriodStart"         DATE NOT NULL,
    "PeriodEnd"           DATE NOT NULL,
    -- Totales ventas/compras
    "SalesBase"           NUMERIC(18,2) DEFAULT 0,
    "SalesTax"            NUMERIC(18,2) DEFAULT 0,
    "PurchasesBase"       NUMERIC(18,2) DEFAULT 0,
    "PurchasesTax"        NUMERIC(18,2) DEFAULT 0,
    -- Cálculo
    "TaxableBase"         NUMERIC(18,2) DEFAULT 0,
    "TaxAmount"           NUMERIC(18,2) DEFAULT 0,
    "WithholdingsCredit"  NUMERIC(18,2) DEFAULT 0,
    "PreviousBalance"     NUMERIC(18,2) DEFAULT 0,
    "NetPayable"          NUMERIC(18,2) DEFAULT 0,
    -- Flujo de estado
    "Status"              VARCHAR(20) DEFAULT 'DRAFT', -- DRAFT, CALCULATED, SUBMITTED, PAID, AMENDED
    "SubmittedAt"         TIMESTAMP NULL,
    "SubmittedFile"       VARCHAR(500) NULL,
    "AuthorityResponse"   TEXT NULL,
    "PaidAt"              TIMESTAMP NULL,
    "PaymentReference"    VARCHAR(100) NULL,
    -- Contabilidad
    "JournalEntryId"      BIGINT NULL,
    "Notes"               VARCHAR(1000) NULL,
    "CreatedBy"           VARCHAR(40) NULL,
    "UpdatedBy"           VARCHAR(40) NULL,
    "CreatedAt"           TIMESTAMP DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "UpdatedAt"           TIMESTAMP NULL,
    CONSTRAINT "PK_TaxDeclaration" PRIMARY KEY ("DeclarationId"),
    CONSTRAINT "UQ_TaxDeclaration" UNIQUE ("CompanyId", "DeclarationType", "PeriodCode")
  );
  RAISE NOTICE '>> Tabla fiscal."TaxDeclaration" verificada.';

  -- ============================================================
  -- 2. fiscal."TaxBookEntry" - Líneas del libro de compras/ventas
  -- ============================================================
  CREATE TABLE IF NOT EXISTS fiscal."TaxBookEntry" (
    "EntryId"             BIGINT GENERATED ALWAYS AS IDENTITY NOT NULL,
    "CompanyId"           INTEGER NOT NULL,
    "BookType"            VARCHAR(10) NOT NULL,         -- PURCHASE, SALES
    "PeriodCode"          VARCHAR(7) NOT NULL,
    "EntryDate"           DATE NOT NULL,
    "DocumentNumber"      VARCHAR(60) NOT NULL,
    "DocumentType"        VARCHAR(30) NULL,             -- FACTURA, NOTA_CREDITO, NOTA_DEBITO
    "ControlNumber"       VARCHAR(40) NULL,             -- Número de control (VE)
    "ThirdPartyId"        VARCHAR(40) NULL,             -- RIF/NIF del tercero
    "ThirdPartyName"      VARCHAR(200) NULL,
    "TaxableBase"         NUMERIC(18,2) NOT NULL DEFAULT 0,
    "ExemptAmount"        NUMERIC(18,2) DEFAULT 0,
    "TaxRate"             NUMERIC(5,2) NOT NULL DEFAULT 0,
    "TaxAmount"           NUMERIC(18,2) NOT NULL DEFAULT 0,
    "WithholdingRate"     NUMERIC(5,2) DEFAULT 0,
    "WithholdingAmount"   NUMERIC(18,2) DEFAULT 0,
    "TotalAmount"         NUMERIC(18,2) NOT NULL DEFAULT 0,
    "SourceDocumentId"    BIGINT NULL,
    "SourceModule"        VARCHAR(20) NULL,             -- AR, AP, POS
    "CountryCode"         VARCHAR(2) NOT NULL,
    "DeclarationId"       BIGINT NULL,
    "CreatedAt"           TIMESTAMP DEFAULT (NOW() AT TIME ZONE 'UTC'),
    CONSTRAINT "PK_TaxBookEntry" PRIMARY KEY ("EntryId"),
    CONSTRAINT "FK_TaxBookEntry_Declaration" FOREIGN KEY ("DeclarationId")
      REFERENCES fiscal."TaxDeclaration" ("DeclarationId")
  );
  RAISE NOTICE '>> Tabla fiscal."TaxBookEntry" verificada.';

  -- ============================================================
  -- 3. fiscal."WithholdingVoucher" - Comprobantes de retención
  -- ============================================================
  CREATE TABLE IF NOT EXISTS fiscal."WithholdingVoucher" (
    "VoucherId"           BIGINT GENERATED ALWAYS AS IDENTITY NOT NULL,
    "CompanyId"           INTEGER NOT NULL,
    "VoucherNumber"       VARCHAR(40) NOT NULL,
    "VoucherDate"         DATE NOT NULL,
    "WithholdingType"     VARCHAR(20) NOT NULL,         -- IVA, ISLR, IRPF, ICA
    "ThirdPartyId"        VARCHAR(40) NOT NULL,
    "ThirdPartyName"      VARCHAR(200) NULL,
    "DocumentNumber"      VARCHAR(60) NOT NULL,
    "DocumentDate"        DATE NULL,
    "TaxableBase"         NUMERIC(18,2) NOT NULL,
    "WithholdingRate"     NUMERIC(5,2) NOT NULL,
    "WithholdingAmount"   NUMERIC(18,2) NOT NULL,
    "PeriodCode"          VARCHAR(7) NOT NULL,
    "Status"              VARCHAR(20) DEFAULT 'ACTIVE', -- ACTIVE, VOIDED
    "CountryCode"         VARCHAR(2) NOT NULL,
    "JournalEntryId"      BIGINT NULL,
    "CreatedBy"           VARCHAR(40) NULL,
    "CreatedAt"           TIMESTAMP DEFAULT (NOW() AT TIME ZONE 'UTC'),
    CONSTRAINT "PK_WithholdingVoucher" PRIMARY KEY ("VoucherId"),
    CONSTRAINT "UQ_WithholdingVoucher" UNIQUE ("CompanyId", "VoucherNumber")
  );
  RAISE NOTICE '>> Tabla fiscal."WithholdingVoucher" verificada.';

  -- ============================================================
  -- 4. fiscal."DeclarationTemplate" - Plantillas por país
  -- ============================================================
  CREATE TABLE IF NOT EXISTS fiscal."DeclarationTemplate" (
    "TemplateId"          INTEGER GENERATED ALWAYS AS IDENTITY NOT NULL,
    "CountryCode"         VARCHAR(2) NOT NULL,
    "DeclarationType"     VARCHAR(30) NOT NULL,
    "TemplateName"        VARCHAR(200) NOT NULL,
    "FileFormat"          VARCHAR(10) NOT NULL,         -- XML, TXT, JSON
    "FormatVersion"       VARCHAR(20) NULL,
    "AuthorityName"       VARCHAR(100) NULL,
    "AuthorityUrl"        VARCHAR(500) NULL,
    "IsActive"            BOOLEAN DEFAULT TRUE,
    "CreatedAt"           TIMESTAMP DEFAULT (NOW() AT TIME ZONE 'UTC'),
    CONSTRAINT "PK_DeclarationTemplate" PRIMARY KEY ("TemplateId"),
    CONSTRAINT "UQ_DeclTemplate" UNIQUE ("CountryCode", "DeclarationType")
  );
  RAISE NOTICE '>> Tabla fiscal."DeclarationTemplate" verificada.';

  -- ============================================================
  -- 5. fiscal."ISLRTariff" - Tabla progresiva ISLR Venezuela
  -- ============================================================
  CREATE TABLE IF NOT EXISTS fiscal."ISLRTariff" (
    "TariffId"            INTEGER GENERATED ALWAYS AS IDENTITY NOT NULL,
    "CountryCode"         VARCHAR(2) NOT NULL DEFAULT 'VE',
    "TaxYear"             INTEGER NOT NULL,
    "BracketFrom"         NUMERIC(18,2) NOT NULL,        -- En UT (Unidades Tributarias)
    "BracketTo"           NUMERIC(18,2) NULL,
    "Rate"                NUMERIC(5,2) NOT NULL,
    "Subtrahend"          NUMERIC(18,2) DEFAULT 0,
    "IsActive"            BOOLEAN DEFAULT TRUE,
    CONSTRAINT "PK_ISLRTariff" PRIMARY KEY ("TariffId")
  );
  RAISE NOTICE '>> Tabla fiscal."ISLRTariff" verificada.';

  -- ============================================================
  -- ÍNDICES
  -- ============================================================
  CREATE INDEX IF NOT EXISTS "IX_TaxDeclaration_Country_Period"
    ON fiscal."TaxDeclaration" ("CountryCode", "PeriodCode", "Status");

  CREATE INDEX IF NOT EXISTS "IX_TaxBookEntry_Period_Book"
    ON fiscal."TaxBookEntry" ("CompanyId", "BookType", "PeriodCode");

  CREATE INDEX IF NOT EXISTS "IX_TaxBookEntry_Declaration"
    ON fiscal."TaxBookEntry" ("DeclarationId")
    WHERE "DeclarationId" IS NOT NULL;

  CREATE INDEX IF NOT EXISTS "IX_WithholdingVoucher_Period"
    ON fiscal."WithholdingVoucher" ("CompanyId", "PeriodCode", "WithholdingType");

  CREATE INDEX IF NOT EXISTS "IX_ISLRTariff_Year"
    ON fiscal."ISLRTariff" ("CountryCode", "TaxYear", "IsActive");

  RAISE NOTICE '>> Índices verificados.';

  -- ============================================================
  -- SEED DATA: Plantillas de declaración
  -- ============================================================
  RAISE NOTICE '>> Insertando plantillas de declaración...';

  -- Venezuela
  INSERT INTO fiscal."DeclarationTemplate" ("CountryCode", "DeclarationType", "TemplateName", "FileFormat", "AuthorityName")
  VALUES ('VE', 'IVA', 'Declaración IVA SENIAT', 'TXT', 'SENIAT')
  ON CONFLICT ("CountryCode", "DeclarationType") DO NOTHING;

  INSERT INTO fiscal."DeclarationTemplate" ("CountryCode", "DeclarationType", "TemplateName", "FileFormat", "AuthorityName")
  VALUES ('VE', 'ISLR', 'Declaración ISLR SENIAT', 'XML', 'SENIAT')
  ON CONFLICT ("CountryCode", "DeclarationType") DO NOTHING;

  INSERT INTO fiscal."DeclarationTemplate" ("CountryCode", "DeclarationType", "TemplateName", "FileFormat", "AuthorityName")
  VALUES ('VE', 'RET_IVA', 'Retenciones IVA SENIAT', 'XML', 'SENIAT')
  ON CONFLICT ("CountryCode", "DeclarationType") DO NOTHING;

  INSERT INTO fiscal."DeclarationTemplate" ("CountryCode", "DeclarationType", "TemplateName", "FileFormat", "AuthorityName")
  VALUES ('VE', 'RET_ISLR', 'Retenciones ISLR SENIAT', 'XML', 'SENIAT')
  ON CONFLICT ("CountryCode", "DeclarationType") DO NOTHING;

  -- España
  INSERT INTO fiscal."DeclarationTemplate" ("CountryCode", "DeclarationType", "TemplateName", "FileFormat", "AuthorityName")
  VALUES ('ES', 'MODELO_303', 'Modelo 303 - IVA Trimestral', 'XML', 'AEAT')
  ON CONFLICT ("CountryCode", "DeclarationType") DO NOTHING;

  INSERT INTO fiscal."DeclarationTemplate" ("CountryCode", "DeclarationType", "TemplateName", "FileFormat", "AuthorityName")
  VALUES ('ES', 'MODELO_390', 'Modelo 390 - Resumen Anual IVA', 'XML', 'AEAT')
  ON CONFLICT ("CountryCode", "DeclarationType") DO NOTHING;

  INSERT INTO fiscal."DeclarationTemplate" ("CountryCode", "DeclarationType", "TemplateName", "FileFormat", "AuthorityName")
  VALUES ('ES', 'MODELO_349', 'Modelo 349 - Operaciones Intracomunitarias', 'XML', 'AEAT')
  ON CONFLICT ("CountryCode", "DeclarationType") DO NOTHING;

  INSERT INTO fiscal."DeclarationTemplate" ("CountryCode", "DeclarationType", "TemplateName", "FileFormat", "AuthorityName")
  VALUES ('ES', 'MODELO_111', 'Modelo 111 - Retenciones IRPF', 'XML', 'AEAT')
  ON CONFLICT ("CountryCode", "DeclarationType") DO NOTHING;

  INSERT INTO fiscal."DeclarationTemplate" ("CountryCode", "DeclarationType", "TemplateName", "FileFormat", "AuthorityName")
  VALUES ('ES', 'MODELO_190', 'Modelo 190 - Resumen Anual Retenciones', 'XML', 'AEAT')
  ON CONFLICT ("CountryCode", "DeclarationType") DO NOTHING;

  RAISE NOTICE '>> Plantillas de declaración insertadas.';

  -- ============================================================
  -- SEED DATA: Tarifa ISLR Venezuela 2026
  -- ============================================================
  RAISE NOTICE '>> Insertando tarifa ISLR Venezuela 2026...';

  IF NOT EXISTS (SELECT 1 FROM fiscal."ISLRTariff" WHERE "CountryCode" = 'VE' AND "TaxYear" = 2026) THEN
    INSERT INTO fiscal."ISLRTariff" ("CountryCode", "TaxYear", "BracketFrom", "BracketTo", "Rate", "Subtrahend")
    VALUES
      ('VE', 2026,     0.00, 1000.00,  6.00,   0.00),
      ('VE', 2026, 1000.00, 1500.00,  9.00,  30.00),
      ('VE', 2026, 1500.00, 2000.00, 12.00,  75.00),
      ('VE', 2026, 2000.00, 2500.00, 16.00, 155.00),
      ('VE', 2026, 2500.00, 3000.00, 20.00, 255.00),
      ('VE', 2026, 3000.00, 4000.00, 24.00, 375.00),
      ('VE', 2026, 4000.00, 6000.00, 29.00, 575.00),
      ('VE', 2026, 6000.00,    NULL, 34.00, 875.00);
    RAISE NOTICE '>> Tarifa ISLR 2026 insertada (8 tramos).';
  ELSE
    RAISE NOTICE '>> Tarifa ISLR 2026 ya existe, omitida.';
  END IF;

  -- ============================================================
  -- SEED DATA: Complemento master."TaxRetention"
  -- ============================================================
  RAISE NOTICE '>> Verificando retenciones en master."TaxRetention"...';

  -- Venezuela - IVA
  INSERT INTO master."TaxRetention" ("RetentionCode", "RetentionType", "RetentionRate", "CountryCode", "Description")
  SELECT 'RET_IVA_75', 'IVA', 75.00, 'VE', 'Retención IVA 75% Contribuyente Ordinario'
  WHERE NOT EXISTS (SELECT 1 FROM master."TaxRetention" WHERE "RetentionCode" = 'RET_IVA_75');

  INSERT INTO master."TaxRetention" ("RetentionCode", "RetentionType", "RetentionRate", "CountryCode", "Description")
  SELECT 'RET_IVA_100', 'IVA', 100.00, 'VE', 'Retención IVA 100% Contribuyente Especial'
  WHERE NOT EXISTS (SELECT 1 FROM master."TaxRetention" WHERE "RetentionCode" = 'RET_IVA_100');

  -- Venezuela - ISLR
  INSERT INTO master."TaxRetention" ("RetentionCode", "RetentionType", "RetentionRate", "CountryCode", "Description")
  SELECT 'RET_ISLR_1', 'ISLR', 1.00, 'VE', 'Retención ISLR 1% Servicios Profesionales'
  WHERE NOT EXISTS (SELECT 1 FROM master."TaxRetention" WHERE "RetentionCode" = 'RET_ISLR_1');

  INSERT INTO master."TaxRetention" ("RetentionCode", "RetentionType", "RetentionRate", "CountryCode", "Description")
  SELECT 'RET_ISLR_2', 'ISLR', 2.00, 'VE', 'Retención ISLR 2% Servicios'
  WHERE NOT EXISTS (SELECT 1 FROM master."TaxRetention" WHERE "RetentionCode" = 'RET_ISLR_2');

  INSERT INTO master."TaxRetention" ("RetentionCode", "RetentionType", "RetentionRate", "CountryCode", "Description")
  SELECT 'RET_ISLR_3', 'ISLR', 3.00, 'VE', 'Retención ISLR 3% Comisiones'
  WHERE NOT EXISTS (SELECT 1 FROM master."TaxRetention" WHERE "RetentionCode" = 'RET_ISLR_3');

  INSERT INTO master."TaxRetention" ("RetentionCode", "RetentionType", "RetentionRate", "CountryCode", "Description")
  SELECT 'RET_ISLR_5', 'ISLR', 5.00, 'VE', 'Retención ISLR 5% Honorarios'
  WHERE NOT EXISTS (SELECT 1 FROM master."TaxRetention" WHERE "RetentionCode" = 'RET_ISLR_5');

  -- España - IRPF
  INSERT INTO master."TaxRetention" ("RetentionCode", "RetentionType", "RetentionRate", "CountryCode", "Description")
  SELECT 'RET_IRPF_15', 'IRPF', 15.00, 'ES', 'Retención IRPF 15% Profesionales'
  WHERE NOT EXISTS (SELECT 1 FROM master."TaxRetention" WHERE "RetentionCode" = 'RET_IRPF_15');

  INSERT INTO master."TaxRetention" ("RetentionCode", "RetentionType", "RetentionRate", "CountryCode", "Description")
  SELECT 'RET_IRPF_19', 'IRPF', 19.00, 'ES', 'Retención IRPF 19% Rendimientos Capital'
  WHERE NOT EXISTS (SELECT 1 FROM master."TaxRetention" WHERE "RetentionCode" = 'RET_IRPF_19');

  INSERT INTO master."TaxRetention" ("RetentionCode", "RetentionType", "RetentionRate", "CountryCode", "Description")
  SELECT 'RET_IRPF_7', 'IRPF', 7.00, 'ES', 'Retención IRPF 7% Nuevos Profesionales'
  WHERE NOT EXISTS (SELECT 1 FROM master."TaxRetention" WHERE "RetentionCode" = 'RET_IRPF_7');

  RAISE NOTICE '>> Retenciones en master."TaxRetention" verificadas.';

  RAISE NOTICE '========================================================';
  RAISE NOTICE '>> Módulo fiscal/tributaria desplegado exitosamente.';
  RAISE NOTICE '========================================================';

EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE 'ERROR en módulo fiscal/tributaria: %', SQLERRM;
  RAISE;
END $$;
-- +goose StatementEnd

-- Source: 18_fiscal_retenciones_schema.sql
-- =============================================================================
-- 18_fiscal_retenciones_schema.sql (PostgreSQL)
-- Tablas y ALTER para módulo de retenciones fiscales automáticas.
-- Soporta multi-país: VE (ISLR), ES (IRPF), CO (ReteFuente), MX (ISR).
-- =============================================================================

-- =============================================================================
-- 1. cfg.TaxUnit — Unidad Tributaria configurable por país y año
-- =============================================================================
CREATE TABLE IF NOT EXISTS cfg."TaxUnit" (
    "TaxUnitId"     INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    "CountryCode"   CHAR(2)        NOT NULL,
    "TaxYear"       INT            NOT NULL,
    "UnitValue"     NUMERIC(18,4)  NOT NULL,
    "Currency"      CHAR(3)        NOT NULL DEFAULT 'VES',
    "EffectiveDate" DATE           NOT NULL,
    "IsActive"      BOOLEAN        NOT NULL DEFAULT TRUE,
    "CreatedAt"     TIMESTAMP      NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "UpdatedAt"     TIMESTAMP      NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    CONSTRAINT "UQ_cfg_TaxUnit" UNIQUE ("CountryCode", "TaxYear", "EffectiveDate")
);

-- =============================================================================
-- 2. fiscal.WithholdingConcept — Conceptos de retención parametrizables
--    Mapea tipo persona + actividad → porcentaje de retención
-- =============================================================================
CREATE TABLE IF NOT EXISTS fiscal."WithholdingConcept" (
    "ConceptId"       INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    "CompanyId"       INT            NOT NULL DEFAULT 1,
    "CountryCode"     CHAR(2)        NOT NULL,
    "ConceptCode"     VARCHAR(20)    NOT NULL,
    "Description"     VARCHAR(200)   NOT NULL,
    "SupplierType"    VARCHAR(20)    NOT NULL DEFAULT 'AMBOS',
    "ActivityCode"    VARCHAR(30)    NULL,
    "RetentionType"   VARCHAR(20)    NOT NULL DEFAULT 'ISLR',
    "Rate"            NUMERIC(8,4)   NOT NULL,
    "SubtrahendUT"    NUMERIC(8,4)   NOT NULL DEFAULT 0,
    "MinBaseUT"       NUMERIC(8,4)   NOT NULL DEFAULT 0,
    "SeniatCode"      VARCHAR(10)    NULL,
    "IsActive"        BOOLEAN        NOT NULL DEFAULT TRUE,
    "IsDeleted"       BOOLEAN        NOT NULL DEFAULT FALSE,
    "CreatedAt"       TIMESTAMP      NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "UpdatedAt"       TIMESTAMP      NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    CONSTRAINT "UQ_fiscal_WHConcept" UNIQUE ("CompanyId", "CountryCode", "ConceptCode"),
    CONSTRAINT "CK_fiscal_WHConcept_Type" CHECK ("SupplierType" IN ('NATURAL','JURIDICA','AMBOS')),
    CONSTRAINT "CK_fiscal_WHConcept_RetType" CHECK ("RetentionType" IN ('ISLR','IVA','IRPF','ISR','RETEFUENTE','MUNICIPAL'))
);

-- =============================================================================
-- 3. ALTER master.Supplier — Campos de clasificación fiscal
-- =============================================================================
-- +goose StatementBegin
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='master' AND table_name='Supplier' AND column_name='SupplierType') THEN
        ALTER TABLE master."Supplier" ADD COLUMN "SupplierType" VARCHAR(20) NOT NULL DEFAULT 'JURIDICA';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='master' AND table_name='Supplier' AND column_name='BusinessActivity') THEN
        ALTER TABLE master."Supplier" ADD COLUMN "BusinessActivity" VARCHAR(30) NULL;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='master' AND table_name='Supplier' AND column_name='DefaultRetentionCode') THEN
        ALTER TABLE master."Supplier" ADD COLUMN "DefaultRetentionCode" VARCHAR(20) NULL;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='master' AND table_name='Supplier' AND column_name='CountryCode') THEN
        ALTER TABLE master."Supplier" ADD COLUMN "CountryCode" CHAR(2) NOT NULL DEFAULT 'VE';
    END IF;
END $$;
-- +goose StatementEnd

-- =============================================================================
-- 4. ALTER ap.PayableApplication — Campos de retención en pagos
-- =============================================================================
-- +goose StatementBegin
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='ap' AND table_name='PayableApplication' AND column_name='RetentionType') THEN
        ALTER TABLE ap."PayableApplication" ADD COLUMN "RetentionType" VARCHAR(20) NULL;
        ALTER TABLE ap."PayableApplication" ADD COLUMN "RetentionRate" NUMERIC(8,4) NULL;
        ALTER TABLE ap."PayableApplication" ADD COLUMN "RetentionAmount" NUMERIC(18,2) NOT NULL DEFAULT 0;
        ALTER TABLE ap."PayableApplication" ADD COLUMN "NetAmount" NUMERIC(18,2) NULL;
        ALTER TABLE ap."PayableApplication" ADD COLUMN "WithholdingVoucherId" BIGINT NULL;
    END IF;
END $$;
-- +goose StatementEnd

-- =============================================================================
-- 5. hr.EmployeeTaxProfile — Perfil fiscal del empleado (ARI)
-- =============================================================================
CREATE SCHEMA IF NOT EXISTS hr;

CREATE TABLE IF NOT EXISTS hr."EmployeeTaxProfile" (
    "ProfileId"                INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    "EmployeeId"               BIGINT         NOT NULL,
    "TaxYear"                  INT            NOT NULL,
    "EstimatedAnnualIncome"    NUMERIC(18,2)  NOT NULL DEFAULT 0,
    "DeductionType"            VARCHAR(20)    NOT NULL DEFAULT 'UNICO',
    "UniqueDeductionUT"        NUMERIC(8,2)   NOT NULL DEFAULT 774,
    "DetailedDeductions"       NUMERIC(18,2)  NOT NULL DEFAULT 0,
    "DependentCount"           INT            NOT NULL DEFAULT 0,
    "PersonalRebateUT"         NUMERIC(8,2)   NOT NULL DEFAULT 10,
    "DependentRebateUT"        NUMERIC(8,2)   NOT NULL DEFAULT 10,
    "MonthsRemaining"          INT            NOT NULL DEFAULT 12,
    "CalculatedAnnualISLR"     NUMERIC(18,2)  NOT NULL DEFAULT 0,
    "MonthlyWithholding"       NUMERIC(18,2)  NOT NULL DEFAULT 0,
    "CountryCode"              CHAR(2)        NOT NULL DEFAULT 'VE',
    "Status"                   VARCHAR(20)    NOT NULL DEFAULT 'ACTIVE',
    "CreatedAt"                TIMESTAMP      NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "UpdatedAt"                TIMESTAMP      NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    CONSTRAINT "UQ_hr_EmpTaxProfile" UNIQUE ("EmployeeId", "TaxYear"),
    CONSTRAINT "CK_hr_EmpTaxProfile_Ded" CHECK ("DeductionType" IN ('UNICO','DETALLADO')),
    CONSTRAINT "CK_hr_EmpTaxProfile_Status" CHECK ("Status" IN ('ACTIVE','INACTIVE'))
);

-- =============================================================================
-- 6. SEED DATA: Unidad Tributaria Venezuela 2026
-- =============================================================================
INSERT INTO cfg."TaxUnit" ("CountryCode", "TaxYear", "UnitValue", "Currency", "EffectiveDate")
SELECT 'VE', 2026, 9.00, 'VES', '2026-01-01'
WHERE NOT EXISTS (
    SELECT 1 FROM cfg."TaxUnit" WHERE "CountryCode"='VE' AND "TaxYear"=2026
);

-- =============================================================================
-- 7. SEED DATA: Conceptos ISLR Venezuela (Decreto 1.808)
-- =============================================================================
INSERT INTO fiscal."WithholdingConcept"
    ("CountryCode", "ConceptCode", "Description", "SupplierType", "ActivityCode", "RetentionType", "Rate", "SubtrahendUT", "MinBaseUT", "SeniatCode")
SELECT v.*
FROM (VALUES
    ('VE', 'ISLR_HON_PN',   'Honorarios profesionales (PN)',          'NATURAL',  'HONORARIOS',    'ISLR', 3.0000, 1.0000, 25.0000, '002'),
    ('VE', 'ISLR_HON_PJ',   'Honorarios profesionales (PJ)',          'JURIDICA', 'HONORARIOS',    'ISLR', 5.0000, 0.0000,  0.0000, '002'),
    ('VE', 'ISLR_COM_PN',   'Comisiones y corretaje (PN)',            'NATURAL',  'COMISIONES',    'ISLR', 3.0000, 1.0000, 25.0000, '003'),
    ('VE', 'ISLR_COM_PJ',   'Comisiones y corretaje (PJ)',            'JURIDICA', 'COMISIONES',    'ISLR', 5.0000, 0.0000,  0.0000, '003'),
    ('VE', 'ISLR_SRV_PN',   'Servicios en general (PN)',              'NATURAL',  'SERVICIOS',     'ISLR', 1.0000, 1.0000, 25.0000, '004'),
    ('VE', 'ISLR_SRV_PJ',   'Servicios en general (PJ)',              'JURIDICA', 'SERVICIOS',     'ISLR', 2.0000, 0.0000,  0.0000, '004'),
    ('VE', 'ISLR_FLE_PN',   'Fletes y transporte (PN)',               'NATURAL',  'FLETES',        'ISLR', 3.0000, 1.0000, 25.0000, '005'),
    ('VE', 'ISLR_FLE_PJ',   'Fletes y transporte (PJ)',               'JURIDICA', 'FLETES',        'ISLR', 1.0000, 0.0000,  0.0000, '005'),
    ('VE', 'ISLR_ALQ_PN',   'Alquiler bienes inmuebles (PN)',         'NATURAL',  'ALQUILER_INM',  'ISLR', 3.0000, 0.0000,  0.0000, '006'),
    ('VE', 'ISLR_ALQ_PJ',   'Alquiler bienes inmuebles (PJ)',         'JURIDICA', 'ALQUILER_INM',  'ISLR', 5.0000, 0.0000,  0.0000, '006'),
    ('VE', 'ISLR_PUB_PN',   'Publicidad y propaganda (PN)',           'NATURAL',  'PUBLICIDAD',    'ISLR', 1.0000, 1.0000, 25.0000, '007'),
    ('VE', 'ISLR_PUB_PJ',   'Publicidad y propaganda (PJ)',           'JURIDICA', 'PUBLICIDAD',    'ISLR', 2.0000, 0.0000,  0.0000, '007')
) AS v("CountryCode", "ConceptCode", "Description", "SupplierType", "ActivityCode", "RetentionType", "Rate", "SubtrahendUT", "MinBaseUT", "SeniatCode")
WHERE NOT EXISTS (
    SELECT 1 FROM fiscal."WithholdingConcept" WHERE "ConceptCode" = v."ConceptCode" AND "CountryCode" = 'VE'
);

-- España IRPF
INSERT INTO fiscal."WithholdingConcept"
    ("CountryCode", "ConceptCode", "Description", "SupplierType", "ActivityCode", "RetentionType", "Rate", "SubtrahendUT", "MinBaseUT")
SELECT v.*
FROM (VALUES
    ('ES', 'IRPF_PROF',    'Profesionales/autónomos',     'AMBOS',   'PROFESIONAL', 'IRPF', 15.0000, 0, 0),
    ('ES', 'IRPF_NUEVO',   'Nuevos profesionales (3 años)', 'AMBOS', 'PROFESIONAL', 'IRPF',  7.0000, 0, 0),
    ('ES', 'IRPF_ALQ',     'Arrendamientos inmuebles',    'AMBOS',   'ALQUILER_INM','IRPF', 19.0000, 0, 0),
    ('ES', 'IRPF_CAP',     'Rendimientos de capital',     'AMBOS',   'CAPITAL',     'IRPF', 19.0000, 0, 0)
) AS v("CountryCode", "ConceptCode", "Description", "SupplierType", "ActivityCode", "RetentionType", "Rate", "SubtrahendUT", "MinBaseUT")
WHERE NOT EXISTS (
    SELECT 1 FROM fiscal."WithholdingConcept" WHERE "ConceptCode" = v."ConceptCode" AND "CountryCode" = 'ES'
);

-- +goose StatementBegin
DO $$ BEGIN RAISE NOTICE '>>> 18_fiscal_retenciones_schema.sql ejecutado correctamente <<<'; END $$;
-- +goose StatementEnd

-- Source: includes/sp/create_vacation_request.sql
-- ============================================================
-- DatqBoxWeb PostgreSQL - create_vacation_request.sql
-- Tables: hr.VacationRequest, hr.VacationRequestDay
-- Workflow: PENDIENTE -> APROBADA -> PROCESADA (or RECHAZADA/CANCELADA)
-- ============================================================

BEGIN;

-- hr.VacationRequest
CREATE TABLE IF NOT EXISTS hr."VacationRequest" (
    "RequestId"       BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    "CompanyId"       INT NOT NULL DEFAULT 1,
    "BranchId"        INT NOT NULL DEFAULT 1,
    "EmployeeCode"    VARCHAR(60) NOT NULL,
    "RequestDate"     DATE NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC')::DATE,
    "StartDate"       DATE NOT NULL,
    "EndDate"         DATE NOT NULL,
    "TotalDays"       INT NOT NULL,
    "IsPartial"       BOOLEAN NOT NULL DEFAULT FALSE,
    "Status"          VARCHAR(20) NOT NULL DEFAULT 'PENDIENTE',
    "Notes"           VARCHAR(500),
    "ApprovedBy"      VARCHAR(60),
    "ApprovalDate"    TIMESTAMP,
    "RejectionReason" VARCHAR(500),
    "VacationId"      BIGINT,
    "CreatedAt"       TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "UpdatedAt"       TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),

    CONSTRAINT "CK_VacationRequest_Status" CHECK ("Status" IN ('PENDIENTE','APROBADA','RECHAZADA','CANCELADA','PROCESADA')),
    CONSTRAINT "CK_VacationRequest_Dates"  CHECK ("EndDate" >= "StartDate"),
    CONSTRAINT "CK_VacationRequest_Days"   CHECK ("TotalDays" > 0)
);

CREATE INDEX IF NOT EXISTS "IX_VacationRequest_Employee"
    ON hr."VacationRequest" ("CompanyId", "EmployeeCode", "Status");

CREATE INDEX IF NOT EXISTS "IX_VacationRequest_Status"
    ON hr."VacationRequest" ("Status", "RequestDate");

-- hr.VacationRequestDay
CREATE TABLE IF NOT EXISTS hr."VacationRequestDay" (
    "DayId"        BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    "RequestId"    BIGINT NOT NULL REFERENCES hr."VacationRequest"("RequestId"),
    "SelectedDate" DATE NOT NULL,
    "DayType"      VARCHAR(20) NOT NULL DEFAULT 'COMPLETO',

    CONSTRAINT "CK_VacationRequestDay_Type" CHECK ("DayType" IN ('COMPLETO','MEDIO_DIA'))
);

CREATE INDEX IF NOT EXISTS "IX_VacationRequestDay_Request"
    ON hr."VacationRequestDay" ("RequestId");

COMMIT;

-- Source: includes/sp/create_supervisor_biometric_credentials.sql
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

-- Source: includes/sp/create_supervisor_override_controls.sql
-- ============================================================
-- DatqBoxWeb PostgreSQL - create_supervisor_override_controls.sql
-- Tabla de overrides de supervisor y columnas adicionales en
-- lineas de ticket POS / Restaurante
-- ============================================================

CREATE SCHEMA IF NOT EXISTS sec;

CREATE TABLE IF NOT EXISTS sec."SupervisorOverride" (
  "OverrideId"            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "ModuleCode"            VARCHAR(32) NOT NULL,
  "ActionCode"            VARCHAR(64) NOT NULL,
  "Status"                VARCHAR(20) NOT NULL DEFAULT 'APPROVED',
  "CompanyId"             INT NULL,
  "BranchId"              INT NULL,
  "RequestedByUserCode"   VARCHAR(50) NULL,
  "SupervisorUserCode"    VARCHAR(50) NOT NULL,
  "Reason"                VARCHAR(300) NOT NULL,
  "PayloadJson"           TEXT NULL,
  "SourceDocumentId"      BIGINT NULL,
  "SourceLineId"          BIGINT NULL,
  "ReversalLineId"        BIGINT NULL,
  "ApprovedAtUtc"         TIMESTAMP(3) NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "ConsumedAtUtc"         TIMESTAMP(3) NULL,
  "ConsumedByUserCode"    VARCHAR(50) NULL,
  "CreatedAt"             TIMESTAMP(3) NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"             TIMESTAMP(3) NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC')
);

CREATE INDEX IF NOT EXISTS "IX_SupervisorOverride_Status"
  ON sec."SupervisorOverride"("Status", "ModuleCode", "ActionCode", "ApprovedAtUtc" DESC);

CREATE INDEX IF NOT EXISTS "IX_SupervisorOverride_Source"
  ON sec."SupervisorOverride"("ModuleCode", "ActionCode", "SourceDocumentId", "SourceLineId");

-- ── Columnas adicionales en tablas POS ──

-- +goose StatementBegin
DO $$
BEGIN
  -- pos.WaitTicketLine
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'pos' AND table_name = 'WaitTicketLine'
      AND column_name = 'SupervisorApprovalId'
  ) THEN
    ALTER TABLE pos."WaitTicketLine"
      ADD COLUMN "SupervisorApprovalId" BIGINT NULL;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'pos' AND table_name = 'WaitTicketLine'
      AND column_name = 'LineMetaJson'
  ) THEN
    ALTER TABLE pos."WaitTicketLine"
      ADD COLUMN "LineMetaJson" VARCHAR(1000) NULL;
  END IF;

  -- pos.SaleTicketLine
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'pos' AND table_name = 'SaleTicketLine'
      AND column_name = 'SupervisorApprovalId'
  ) THEN
    ALTER TABLE pos."SaleTicketLine"
      ADD COLUMN "SupervisorApprovalId" BIGINT NULL;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'pos' AND table_name = 'SaleTicketLine'
      AND column_name = 'LineMetaJson'
  ) THEN
    ALTER TABLE pos."SaleTicketLine"
      ADD COLUMN "LineMetaJson" VARCHAR(1000) NULL;
  END IF;

  -- rest.OrderTicketLine
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'rest' AND table_name = 'OrderTicketLine'
      AND column_name = 'SupervisorApprovalId'
  ) THEN
    ALTER TABLE rest."OrderTicketLine"
      ADD COLUMN "SupervisorApprovalId" BIGINT NULL;
  END IF;
END $$;
-- +goose StatementEnd

-- Source: includes/sp/alter_employee_position_company_address.sql
-- ============================================================
-- Migración: Campos complementarios en master.Employee y cfg.Company
-- Fecha: 2026-03-16
-- PostgreSQL version
-- ============================================================

-- ── cfg."Company": Address, LegalRep, Phone ──────────────────
ALTER TABLE cfg."Company"
  ADD COLUMN IF NOT EXISTS "Address" VARCHAR(500) NULL,
  ADD COLUMN IF NOT EXISTS "LegalRep" VARCHAR(200) NULL,
  ADD COLUMN IF NOT EXISTS "Phone"   VARCHAR(50)  NULL;

-- ── master."Employee": PositionName, DepartmentName, Salary ──
ALTER TABLE master."Employee"
  ADD COLUMN IF NOT EXISTS "PositionName"   VARCHAR(150) NULL,
  ADD COLUMN IF NOT EXISTS "DepartmentName" VARCHAR(150) NULL,
  ADD COLUMN IF NOT EXISTS "Salary"         DECIMAL(18,2) NULL;

-- Source: run_all.sql
-- Drop overloads INTEGER de POS que duplican las versiones BIGINT de usp_ops.sql
DROP FUNCTION IF EXISTS public.usp_pos_saleticket_create(integer, integer, character varying, character varying, character varying, integer, integer, character varying, character varying, character varying, character varying, character varying, text, integer, numeric, numeric, numeric, numeric) CASCADE;
DROP FUNCTION IF EXISTS public.usp_pos_saleticketline_insert(integer, integer, character varying, integer, character varying, character varying, numeric, numeric, numeric, character varying, numeric, numeric, numeric, numeric, integer, text) CASCADE;
DROP FUNCTION IF EXISTS public.usp_pos_waitticket_create(integer, integer, character varying, character varying, character varying, integer, integer, character varying, character varying, character varying, character varying, character varying, numeric, numeric, numeric, numeric) CASCADE;
DROP FUNCTION IF EXISTS public.usp_pos_waitticketline_insert(integer, integer, character varying, integer, character varying, character varying, numeric, numeric, numeric, character varying, numeric, numeric, numeric, numeric, integer, text) CASCADE;

-- Source: 19_sys_tenant_mgmt.sql
-- 19_sys_tenant_mgmt.sql
-- Schema sys + tablas de gestión de tenants
-- Refleja migraciones 00002, 00027, 00028, 00029, 00030

CREATE SCHEMA IF NOT EXISTS sys;

-- ─── sys."TenantDatabase" (migración 00002) ───────────────────────────────────
CREATE TABLE IF NOT EXISTS sys."TenantDatabase" (
  "TenantDbId"    INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"     INT NOT NULL,
  "CompanyCode"   VARCHAR(20) NOT NULL,
  "DbName"        VARCHAR(63) NOT NULL,
  "DbHost"        VARCHAR(255) DEFAULT NULL,
  "DbPort"        INT DEFAULT NULL,
  "DbUser"        VARCHAR(63) DEFAULT NULL,
  "DbPassword"    VARCHAR(255) DEFAULT NULL,
  "PoolMin"       INT NOT NULL DEFAULT 0,
  "PoolMax"       INT NOT NULL DEFAULT 5,
  "IsActive"      BOOLEAN NOT NULL DEFAULT TRUE,
  "IsDemo"        BOOLEAN NOT NULL DEFAULT FALSE,
  "ProvisionedAt" TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "LastMigration" VARCHAR(100) NULL,
  "CreatedAt"     TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  CONSTRAINT "UQ_sys_TenantDatabase_CompanyId" UNIQUE ("CompanyId"),
  CONSTRAINT "UQ_sys_TenantDatabase_DbName" UNIQUE ("DbName")
);

-- ─── sys."License" (migración 00027) ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS sys."License" (
  "LicenseId"         BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"         BIGINT NOT NULL,
  "LicenseType"       VARCHAR(20) NOT NULL DEFAULT 'SUBSCRIPTION',
  "Plan"              VARCHAR(30) NOT NULL DEFAULT 'STARTER',
  "LicenseKey"        VARCHAR(64) NOT NULL UNIQUE,
  "Status"            VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
  "StartsAt"          TIMESTAMP NOT NULL DEFAULT NOW(),
  "ExpiresAt"         TIMESTAMP,
  "PaddleSubId"       VARCHAR(100),
  "ContractRef"       VARCHAR(100),
  "MaxUsers"          INT,
  "MaxBranches"       INT,
  "Notes"             TEXT,
  "ConvertedFromTrial" BOOLEAN DEFAULT FALSE,
  "CreatedAt"         TIMESTAMP NOT NULL DEFAULT NOW(),
  "UpdatedAt"         TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_license_company ON sys."License" ("CompanyId");
CREATE INDEX IF NOT EXISTS idx_license_key     ON sys."License" ("LicenseKey");

-- ─── sys."TenantResourceLog" (migración 00028) ───────────────────────────────
CREATE TABLE IF NOT EXISTS sys."TenantResourceLog" (
  "LogId"       BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"   BIGINT NOT NULL,
  "DbName"      VARCHAR(100),
  "DbSizeBytes" BIGINT,
  "DbSizeMB"    NUMERIC(10,2),
  "TableCount"  INT,
  "LastLoginAt" TIMESTAMP,
  "UserCount"   INT,
  "RecordedAt"  TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_resource_log_company  ON sys."TenantResourceLog" ("CompanyId");
CREATE INDEX IF NOT EXISTS idx_resource_log_recorded ON sys."TenantResourceLog" ("RecordedAt" DESC);

-- ─── sys."CleanupQueue" (migración 00028) ────────────────────────────────────
CREATE TABLE IF NOT EXISTS sys."CleanupQueue" (
  "QueueId"       BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"     BIGINT NOT NULL UNIQUE,
  "Reason"        VARCHAR(50) NOT NULL,
  "FlaggedAt"     TIMESTAMP NOT NULL DEFAULT NOW(),
  "FlaggedBy"     VARCHAR(100) DEFAULT 'auto',
  "Status"        VARCHAR(20) NOT NULL DEFAULT 'PENDING',
  "NotifiedAt"    TIMESTAMP,
  "ArchivedAt"    TIMESTAMP,
  "DeletedAt"     TIMESTAMP,
  "Notes"         TEXT
);

CREATE INDEX IF NOT EXISTS idx_cleanup_status ON sys."CleanupQueue" ("Status") WHERE "Status" = 'PENDING';

-- ─── sys."TenantBackup" (migraciones 00029/00030) ────────────────────────────
CREATE TABLE IF NOT EXISTS sys."TenantBackup" (
  "BackupId"      BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"     BIGINT NOT NULL,
  "DbName"        VARCHAR(100) NOT NULL,
  "FilePath"      VARCHAR(500),
  "FileName"      VARCHAR(200),
  "FileSizeBytes" BIGINT,
  "FileSizeMB"    NUMERIC(10,2),
  "Status"        VARCHAR(20) NOT NULL DEFAULT 'PENDING',
  "StartedAt"     TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CompletedAt"   TIMESTAMP,
  "ErrorMessage"  TEXT,
  "CreatedBy"     VARCHAR(100) DEFAULT 'backoffice',
  "Notes"         TEXT,
  "StorageKey"    VARCHAR(500),
  "StorageUrl"    VARCHAR(1000),
  "StorageStatus" VARCHAR(20) DEFAULT 'LOCAL_ONLY'
);

CREATE INDEX IF NOT EXISTS idx_backup_company ON sys."TenantBackup" ("CompanyId");
CREATE INDEX IF NOT EXISTS idx_backup_status  ON sys."TenantBackup" ("Status");

-- ─── SEED: cfg.Company agregar columna LicenseKey si no existe ────────────────
ALTER TABLE cfg."Company" ADD COLUMN IF NOT EXISTS "LicenseKey"      VARCHAR(64);
ALTER TABLE cfg."Company" ADD COLUMN IF NOT EXISTS "Plan"            VARCHAR(30);
ALTER TABLE cfg."Company" ADD COLUMN IF NOT EXISTS "TenantStatus"    VARCHAR(20);
ALTER TABLE cfg."Company" ADD COLUMN IF NOT EXISTS "OwnerEmail"      VARCHAR(255);
ALTER TABLE cfg."Company" ADD COLUMN IF NOT EXISTS "TenantSubdomain" VARCHAR(100);

-- ─── SEED: Zentto como primer tenant (interno) ────────────────────────────────
-- Inserta la empresa Zentto si no existe (primer tenant del sistema)
INSERT INTO cfg."Company" (
  "CompanyCode", "LegalName", "TradeName",
  "FiscalCountryCode", "BaseCurrency",
  "Plan", "TenantStatus", "IsActive",
  "OwnerEmail", "TenantSubdomain", "CreatedAt"
)
SELECT
  'ZENTTO', 'Zentto ERP S.A.', 'Zentto',
  'VE', 'USD',
  'ENTERPRISE', 'ACTIVE', TRUE,
  'admin@zentto.net', 'app', NOW()
WHERE NOT EXISTS (SELECT 1 FROM cfg."Company" WHERE "CompanyCode" = 'ZENTTO')
ON CONFLICT ("CompanyCode") DO NOTHING;

-- ─── SEED: TenantDatabase — BD demo apunta a la BD actual ────────────────────
INSERT INTO sys."TenantDatabase" ("CompanyId", "CompanyCode", "DbName", "IsDemo")
VALUES (0, 'DEMO', current_database() || '_demo', TRUE)
ON CONFLICT ("CompanyId") DO UPDATE
SET "CompanyCode" = EXCLUDED."CompanyCode",
    "DbName" = EXCLUDED."DbName",
    "IsDemo" = EXCLUDED."IsDemo";

-- TenantDatabase para la empresa DEFAULT (primer tenant real)
INSERT INTO sys."TenantDatabase" ("CompanyId", "CompanyCode", "DbName", "IsDemo")
SELECT c."CompanyId", c."CompanyCode", current_database(), FALSE
FROM cfg."Company" c
WHERE c."CompanyCode" = 'DEFAULT'
ON CONFLICT ("CompanyId") DO UPDATE
SET "CompanyCode" = EXCLUDED."CompanyCode",
    "DbName" = EXCLUDED."DbName",
    "IsDemo" = EXCLUDED."IsDemo";

-- TenantDatabase para Zentto (tenant interno)
INSERT INTO sys."TenantDatabase" ("CompanyId", "CompanyCode", "DbName", "IsDemo")
SELECT c."CompanyId", c."CompanyCode", current_database() || '_zentto', FALSE
FROM cfg."Company" c
WHERE c."CompanyCode" = 'ZENTTO'
ON CONFLICT ("CompanyId") DO UPDATE
SET "CompanyCode" = EXCLUDED."CompanyCode",
    "DbName" = EXCLUDED."DbName",
    "IsDemo" = EXCLUDED."IsDemo";

-- ─── SEED: sys.License — licencia INTERNAL LIFETIME para Zentto ──────────────
INSERT INTO sys."License" (
  "CompanyId", "LicenseType", "Plan", "LicenseKey", "Status",
  "StartsAt", "ExpiresAt", "Notes"
)
SELECT
  c."CompanyId",
  'INTERNAL', 'ENTERPRISE',
  md5('zentto-internal-license-forever'),
  'ACTIVE', NOW(), NULL,
  'Licencia interna Zentto — nunca expira'
FROM cfg."Company" c
WHERE c."CompanyCode" = 'ZENTTO'
  AND NOT EXISTS (
    SELECT 1 FROM sys."License" l
    WHERE l."CompanyId" = c."CompanyId"
      AND l."LicenseType" = 'INTERNAL'
  )
ON CONFLICT DO NOTHING;

-- Actualizar LicenseKey en cfg.Company para Zentto
UPDATE cfg."Company"
SET "LicenseKey" = md5('zentto-internal-license-forever')
WHERE "CompanyCode" = 'ZENTTO'
  AND "LicenseKey" IS NULL;

-- Source: includes/sp/alter_cfg_company_tenant.sql
-- ============================================================
-- Multi-tenant: agregar columnas de suscripción a cfg.Company
-- Idempotente: usa ADD COLUMN IF NOT EXISTS
-- ============================================================
ALTER TABLE cfg."Company"
  ADD COLUMN IF NOT EXISTS "Plan"                   VARCHAR(30)  NOT NULL DEFAULT 'FREE',
  ADD COLUMN IF NOT EXISTS "TenantStatus"           VARCHAR(20)  NOT NULL DEFAULT 'ACTIVE',
  ADD COLUMN IF NOT EXISTS "OwnerEmail"             VARCHAR(150) NULL,
  ADD COLUMN IF NOT EXISTS "ProvisionedAt"          TIMESTAMP    NULL,
  ADD COLUMN IF NOT EXISTS "PaddleSubscriptionId"   VARCHAR(100) NULL,
  ADD COLUMN IF NOT EXISTS "TenantSubdomain"       VARCHAR(63)  NULL;

CREATE INDEX IF NOT EXISTS "IX_cfg_Company_OwnerEmail"
  ON cfg."Company"("OwnerEmail") WHERE "OwnerEmail" IS NOT NULL;

CREATE INDEX IF NOT EXISTS "IX_cfg_Company_TenantStatus"
  ON cfg."Company"("TenantStatus");

-- Source: run_all.sql
-- ====================================================================
-- FASE 7: Permisos de aplicacion
-- ====================================================================
GRANT USAGE ON SCHEMA acct, ap, ar, audit, cfg, doc, fin, fiscal, hr, master, pay, pos, public, rest, sec, store TO zentto_app;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA acct, ap, ar, audit, cfg, doc, fin, fiscal, hr, master, pay, pos, public, rest, sec, store TO zentto_app;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA acct, ap, ar, audit, cfg, doc, fin, fiscal, hr, master, pay, pos, public, rest, sec, store TO zentto_app;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA acct, ap, ar, audit, cfg, doc, fin, fiscal, hr, master, pay, pos, public, rest, sec, store TO zentto_app;
ALTER DEFAULT PRIVILEGES IN SCHEMA acct, ap, ar, audit, cfg, doc, fin, fiscal, hr, master, pay, pos, public, rest, sec, store GRANT ALL ON TABLES TO zentto_app;
ALTER DEFAULT PRIVILEGES IN SCHEMA acct, ap, ar, audit, cfg, doc, fin, fiscal, hr, master, pay, pos, public, rest, sec, store GRANT ALL ON SEQUENCES TO zentto_app;
ALTER DEFAULT PRIVILEGES IN SCHEMA acct, ap, ar, audit, cfg, doc, fin, fiscal, hr, master, pay, pos, public, rest, sec, store GRANT EXECUTE ON FUNCTIONS TO zentto_app;

-- ====================================================================
-- FASE 7.5: Landing / Leads
-- ====================================================================

-- Source: run_all.sql
-- ====================================================================
-- FASE 8b: Nuclear cleanup — eliminar sobrecargas duplicadas
-- Igual que run-functions.sql: borra todos los overloads de usp_* que
-- tengan >1 version, para que el estado final sea limpio.
-- ====================================================================
DO $cleanup$
DECLARE
  _func_name TEXT;
  _oid OID;
  _dropped INT := 0;
BEGIN
  FOR _func_name IN
    SELECT p.proname
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public'
      AND p.proname LIKE 'usp_%'
    GROUP BY p.proname
    HAVING COUNT(*) > 1
  LOOP
    FOR _oid IN
      SELECT p.oid
      FROM pg_proc p
      JOIN pg_namespace n ON n.oid = p.pronamespace
      WHERE n.nspname = 'public' AND p.proname = _func_name
    LOOP
      EXECUTE format('DROP FUNCTION IF EXISTS %s CASCADE', _oid::regprocedure);
      _dropped := _dropped + 1;
    END LOOP;
    RAISE NOTICE 'Dropped all overloads of: %', _func_name;
  END LOOP;
  IF _dropped > 0 THEN
    RAISE NOTICE 'Nuclear cleanup: % functions dropped', _dropped;
  ELSE
    RAISE NOTICE 'No duplicate overloads found';
  END IF;
END $cleanup$;

-- Re-cargar funciones con tipos correctos (después de limpiar overloads)

-- +goose Down
-- No rollback para baseline
