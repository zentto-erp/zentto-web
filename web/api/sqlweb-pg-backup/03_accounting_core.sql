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
