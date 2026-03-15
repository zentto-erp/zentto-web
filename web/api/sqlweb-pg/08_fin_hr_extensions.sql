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
-- SEED DATA
-- ============================================================
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

COMMIT;
