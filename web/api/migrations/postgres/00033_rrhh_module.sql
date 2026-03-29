-- +goose Up

-- +goose StatementBegin
-- ===========================================================================
-- 00033_rrhh_module.sql
-- Migracion: modulo RRHH completo (tablas + funciones + seeds)
-- Corrige errores 500 en /v1/rrhh/* endpoints
-- ===========================================================================

-- Helper: usp_HR_Payroll_ResolveScope
DROP FUNCTION IF EXISTS public.usp_HR_Payroll_ResolveScope() CASCADE;
CREATE OR REPLACE FUNCTION public.usp_HR_Payroll_ResolveScope()
RETURNS TABLE(
    "companyId"     INTEGER,
    "branchId"      INTEGER,
    "systemUserId"  INTEGER
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        c."CompanyId"   AS "companyId",
        b."BranchId"    AS "branchId",
        su."UserId"     AS "systemUserId"
    FROM cfg."Company" c
    INNER JOIN cfg."Branch" b
        ON b."CompanyId" = c."CompanyId"
       AND b."BranchCode" = 'MAIN'
    LEFT JOIN sec."User" su
        ON su."UserCode" = 'SYSTEM'
    WHERE c."CompanyCode" = 'DEFAULT'
    ORDER BY c."CompanyId", b."BranchId"
    LIMIT 1;
END;
$$;

-- Helper: usp_HR_Payroll_ResolveUser
DROP FUNCTION IF EXISTS public.usp_HR_Payroll_ResolveUser(VARCHAR) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_HR_Payroll_ResolveUser(
    p_user_code  VARCHAR DEFAULT NULL
)
RETURNS TABLE("userId" INTEGER)
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_user_code IS NOT NULL AND TRIM(p_user_code) <> '' THEN
        RETURN QUERY
        SELECT u."UserId" AS "userId"
        FROM sec."User" u
        WHERE u."UserCode" = TRIM(p_user_code)
           OR u."Username" = TRIM(p_user_code)
        LIMIT 1;
    ELSE
        RETURN QUERY
        SELECT u."UserId" AS "userId"
        FROM sec."User" u
        WHERE u."UserCode" = 'SYSTEM'
        LIMIT 1;
    END IF;
END;
$$;


-- RRHH Tables

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

-- ----------------------------------------------------------------------------
-- Seed: hr."SavingsFund" — Caja de Ahorro
-- ----------------------------------------------------------------------------
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

-- ----------------------------------------------------------------------------
-- Seed: hr."SavingsFundTransaction"
-- ----------------------------------------------------------------------------
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

-- ----------------------------------------------------------------------------
-- Seed: hr."SavingsLoan"
-- ----------------------------------------------------------------------------
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

-- ----------------------------------------------------------------------------
-- Seed: hr."SocialBenefitsTrust" — Fideicomiso Prestaciones Sociales
-- ----------------------------------------------------------------------------
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

-- ----------------------------------------------------------------------------
-- Seed: hr."ProfitSharing" + hr."ProfitSharingLine" — Utilidades 2025
-- ----------------------------------------------------------------------------
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

-- ----------------------------------------------------------------------------
-- Seed: hr."OccupationalHealth"
-- ----------------------------------------------------------------------------
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

-- ----------------------------------------------------------------------------
-- Seed: hr."MedicalExam"
-- ----------------------------------------------------------------------------
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

-- ----------------------------------------------------------------------------
-- Seed: hr."MedicalOrder"
-- ----------------------------------------------------------------------------
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

-- ----------------------------------------------------------------------------
-- Seed: hr."TrainingRecord"
-- ----------------------------------------------------------------------------
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

-- ----------------------------------------------------------------------------
-- Seed: hr."SafetyCommittee" + hr."SafetyCommitteeMember" + hr."SafetyCommitteeMeeting"
-- ----------------------------------------------------------------------------
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


-- RRHH Functions: Beneficios

-- =============================================================================
-- sp_rrhh_beneficios.sql  (PostgreSQL / PL/pgSQL)
-- Convertido desde T-SQL: web/api/sqlweb/includes/sp/sp_rrhh_beneficios.sql
-- Fecha conversiÃ³n: 2026-03-16
--
-- Beneficios Laborales (LOTTT Venezuela):
--   1. Utilidades (Profit Sharing) - Art. 131-140
--   2. Fideicomiso / Prestaciones Sociales (Social Benefits Trust) - Art. 141-143
--   3. Caja de Ahorro (Savings Fund)
--
-- Funciones (16 en total):
--   1.  usp_HR_ProfitSharing_Generate        - Generar cÃ¡lculo de utilidades
--   2.  usp_HR_ProfitSharing_GetSummary      - Resumen cabecera + detalle
--   3.  usp_HR_ProfitSharing_Approve         - Aprobar utilidades
--   4.  usp_HR_ProfitSharing_List            - Listado paginado de utilidades
--   5.  usp_HR_Trust_CalculateQuarter        - Calcular fideicomiso trimestral
--   6.  usp_HR_Trust_GetEmployeeBalance      - Saldo y historial por empleado
--   7.  usp_HR_Trust_GetSummary              - Resumen trimestral
--   8.  usp_HR_Trust_List                    - Listado paginado
--   9.  usp_HR_Savings_Enroll                - Inscribir empleado
--   10. usp_HR_Savings_ProcessMonthly        - Procesar aportes mensuales
--   11. usp_HR_Savings_GetBalance            - Saldo y transacciones
--   12. usp_HR_Savings_RequestLoan           - Solicitar prÃ©stamo
--   13. usp_HR_Savings_ApproveLoan           - Aprobar/rechazar prÃ©stamo
--   14. usp_HR_Savings_ProcessLoanPayment    - Registrar pago de prÃ©stamo
--   15. usp_HR_Savings_List                  - Listado paginado de afiliados
--   16. usp_HR_Savings_LoanList              - Listado paginado de prÃ©stamos
-- =============================================================================

-- =============================================================================
-- 1. usp_HR_ProfitSharing_Generate
-- =============================================================================
DROP FUNCTION IF EXISTS public.usp_HR_ProfitSharing_Generate(INTEGER, INTEGER, INTEGER, INTEGER, NUMERIC(18,2), INTEGER, INTEGER, VARCHAR(500)) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_HR_ProfitSharing_Generate(
    p_company_id            INTEGER,
    p_branch_id             INTEGER,
    p_fiscal_year           INTEGER,
    p_days_granted          INTEGER,
    p_total_company_profits NUMERIC(18,2)   DEFAULT NULL,
    p_created_by            INTEGER         DEFAULT NULL,
    OUT p_resultado         INTEGER,
    OUT p_mensaje           VARCHAR(500)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_old_id            INTEGER;
    v_ps_id             INTEGER;
    v_year_start        DATE;
    v_year_end          DATE;
    v_total_days        INTEGER;
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    IF p_days_granted < 30 OR p_days_granted > 120 THEN
        p_resultado := -1;
        p_mensaje   := 'Los dÃ­as otorgados deben estar entre 30 y 120 (LOTTT Art. 131).';
        RETURN;
    END IF;

    IF EXISTS (
        SELECT 1 FROM hr."ProfitSharing"
        WHERE "CompanyId" = p_company_id AND "BranchId" = p_branch_id AND "FiscalYear" = p_fiscal_year
          AND "Status" IN ('CALCULADA','PROCESADA','CERRADA')
    ) THEN
        p_resultado := -2;
        p_mensaje   := 'Ya existe un cÃ¡lculo de utilidades procesado para este aÃ±o fiscal.';
        RETURN;
    END IF;

    BEGIN
        v_year_start     := MAKE_DATE(p_fiscal_year, 1, 1);
        v_year_end       := MAKE_DATE(p_fiscal_year, 12, 31);
        v_total_days     := (v_year_end - v_year_start) + 1;

        -- Eliminar borrador previo si existe
        SELECT "ProfitSharingId" INTO v_old_id
        FROM hr."ProfitSharing"
        WHERE "CompanyId" = p_company_id AND "BranchId" = p_branch_id
          AND "FiscalYear" = p_fiscal_year AND "Status" = 'BORRADOR';

        IF v_old_id IS NOT NULL THEN
            DELETE FROM hr."ProfitSharingLine" WHERE "ProfitSharingId" = v_old_id;
            DELETE FROM hr."ProfitSharing"     WHERE "ProfitSharingId" = v_old_id;
        END IF;

        INSERT INTO hr."ProfitSharing" (
            "CompanyId", "BranchId", "FiscalYear", "DaysGranted",
            "TotalCompanyProfits", "Status", "CreatedBy", "CreatedAt", "UpdatedAt"
        )
        VALUES (
            p_company_id, p_branch_id, p_fiscal_year, p_days_granted,
            p_total_company_profits, 'CALCULADA', p_created_by,
            (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
        )
        RETURNING "ProfitSharingId" INTO v_ps_id;

        INSERT INTO hr."ProfitSharingLine" (
            "ProfitSharingId", "EmployeeId", "EmployeeCode", "EmployeeName",
            "MonthlySalary", "DailySalary", "DaysWorked", "DaysEntitled",
            "GrossAmount", "InceDeduction", "NetAmount"
        )
        SELECT
            v_ps_id,
            e."EmployeeId",
            e."EmployeeCode",
            e."EmployeeName",
            COALESCE((
                SELECT prl."Amount"
                FROM hr."PayrollRun" pr
                INNER JOIN hr."PayrollRunLine" prl ON prl."PayrollRunId" = pr."PayrollRunId"
                WHERE pr."EmployeeId" = e."EmployeeId" AND prl."ConceptCode" = 'SALARIO_BASE'
                ORDER BY pr."CreatedAt" DESC LIMIT 1
            ), 0) AS "MonthlySalary",
            ROUND(COALESCE((
                SELECT prl."Amount"
                FROM hr."PayrollRun" pr
                INNER JOIN hr."PayrollRunLine" prl ON prl."PayrollRunId" = pr."PayrollRunId"
                WHERE pr."EmployeeId" = e."EmployeeId" AND prl."ConceptCode" = 'SALARIO_BASE'
                ORDER BY pr."CreatedAt" DESC LIMIT 1
            ), 0) / 30.0, 2) AS "DailySalary",
            -- DaysWorked: desde mayor(HireDate, YearStart) hasta menor(hoy, YearEnd)
            (LEAST(COALESCE(e."TerminationDate", v_year_end), v_year_end)
             - GREATEST(e."HireDate", v_year_start) + 1)::INTEGER AS "DaysWorked",
            -- DaysEntitled = (DaysWorked / TotalDays) * DaysGranted
            ROUND(
                (LEAST(COALESCE(e."TerminationDate", v_year_end), v_year_end)
                 - GREATEST(e."HireDate", v_year_start) + 1)::NUMERIC
                / v_total_days::NUMERIC * p_days_granted,
            2) AS "DaysEntitled",
            -- GrossAmount = DailySalary * DaysEntitled
            ROUND(
                (COALESCE((
                    SELECT prl."Amount"
                    FROM hr."PayrollRun" pr
                    INNER JOIN hr."PayrollRunLine" prl ON prl."PayrollRunId" = pr."PayrollRunId"
                    WHERE pr."EmployeeId" = e."EmployeeId" AND prl."ConceptCode" = 'SALARIO_BASE'
                    ORDER BY pr."CreatedAt" DESC LIMIT 1
                ), 0) / 30.0)
                * ROUND(
                    (LEAST(COALESCE(e."TerminationDate", v_year_end), v_year_end)
                     - GREATEST(e."HireDate", v_year_start) + 1)::NUMERIC
                    / v_total_days::NUMERIC * p_days_granted,
                2),
            2) AS "GrossAmount",
            -- InceDeduction = GrossAmount * 0.5%
            ROUND(
                (COALESCE((
                    SELECT prl."Amount"
                    FROM hr."PayrollRun" pr
                    INNER JOIN hr."PayrollRunLine" prl ON prl."PayrollRunId" = pr."PayrollRunId"
                    WHERE pr."EmployeeId" = e."EmployeeId" AND prl."ConceptCode" = 'SALARIO_BASE'
                    ORDER BY pr."CreatedAt" DESC LIMIT 1
                ), 0) / 30.0)
                * ROUND(
                    (LEAST(COALESCE(e."TerminationDate", v_year_end), v_year_end)
                     - GREATEST(e."HireDate", v_year_start) + 1)::NUMERIC
                    / v_total_days::NUMERIC * p_days_granted,
                2) * 0.005,
            2) AS "InceDeduction",
            -- NetAmount = GrossAmount - InceDeduction
            ROUND(
                (COALESCE((
                    SELECT prl."Amount"
                    FROM hr."PayrollRun" pr
                    INNER JOIN hr."PayrollRunLine" prl ON prl."PayrollRunId" = pr."PayrollRunId"
                    WHERE pr."EmployeeId" = e."EmployeeId" AND prl."ConceptCode" = 'SALARIO_BASE'
                    ORDER BY pr."CreatedAt" DESC LIMIT 1
                ), 0) / 30.0)
                * ROUND(
                    (LEAST(COALESCE(e."TerminationDate", v_year_end), v_year_end)
                     - GREATEST(e."HireDate", v_year_start) + 1)::NUMERIC
                    / v_total_days::NUMERIC * p_days_granted,
                2)
                -
                ROUND(
                    (COALESCE((
                        SELECT prl."Amount"
                        FROM hr."PayrollRun" pr
                        INNER JOIN hr."PayrollRunLine" prl ON prl."PayrollRunId" = pr."PayrollRunId"
                        WHERE pr."EmployeeId" = e."EmployeeId" AND prl."ConceptCode" = 'SALARIO_BASE'
                        ORDER BY pr."CreatedAt" DESC LIMIT 1
                    ), 0) / 30.0)
                    * ROUND(
                        (LEAST(COALESCE(e."TerminationDate", v_year_end), v_year_end)
                         - GREATEST(e."HireDate", v_year_start) + 1)::NUMERIC
                        / v_total_days::NUMERIC * p_days_granted,
                    2) * 0.005,
                2),
            2) AS "NetAmount"
        FROM master."Employee" e
        WHERE e."CompanyId" = p_company_id
          AND e."IsActive" = TRUE
          AND e."HireDate" <= v_year_end
          AND (e."TerminationDate" IS NULL OR e."TerminationDate" >= v_year_start);

        p_resultado := v_ps_id;
        p_mensaje   := 'Utilidades generadas exitosamente.';

    EXCEPTION WHEN OTHERS THEN
        p_resultado := -99;
        p_mensaje   := SQLERRM;
    END;
END;
$$;

-- =============================================================================
-- 2. usp_HR_ProfitSharing_GetSummary
-- =============================================================================
DROP FUNCTION IF EXISTS public.usp_HR_ProfitSharing_GetSummary(INTEGER) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_HR_ProfitSharing_GetSummary(
    p_profit_sharing_id INTEGER
)
RETURNS TABLE (
    result_type TEXT,
    row_data    JSONB
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Cabecera
    RETURN QUERY
    SELECT
        'HEADER'::TEXT,
        jsonb_build_object(
            'ProfitSharingId',      ps."ProfitSharingId",
            'CompanyId',            ps."CompanyId",
            'BranchId',             ps."BranchId",
            'FiscalYear',           ps."FiscalYear",
            'DaysGranted',          ps."DaysGranted",
            'TotalCompanyProfits',  ps."TotalCompanyProfits",
            'Status',               ps."Status",
            'CreatedBy',            ps."CreatedBy",
            'CreatedAt',            ps."CreatedAt",
            'ApprovedBy',           ps."ApprovedBy",
            'ApprovedAt',           ps."ApprovedAt",
            'UpdatedAt',            ps."UpdatedAt",
            'TotalEmployees',       (SELECT COUNT(*) FROM hr."ProfitSharingLine" WHERE "ProfitSharingId" = ps."ProfitSharingId"),
            'TotalGross',           COALESCE((SELECT SUM("GrossAmount") FROM hr."ProfitSharingLine" WHERE "ProfitSharingId" = ps."ProfitSharingId"), 0),
            'TotalInce',            COALESCE((SELECT SUM("InceDeduction") FROM hr."ProfitSharingLine" WHERE "ProfitSharingId" = ps."ProfitSharingId"), 0),
            'TotalNet',             COALESCE((SELECT SUM("NetAmount") FROM hr."ProfitSharingLine" WHERE "ProfitSharingId" = ps."ProfitSharingId"), 0)
        )
    FROM hr."ProfitSharing" ps
    WHERE ps."ProfitSharingId" = p_profit_sharing_id;

    -- Detalle
    RETURN QUERY
    SELECT
        'DETAIL'::TEXT,
        jsonb_build_object(
            'LineId',           l."LineId",
            'EmployeeId',       l."EmployeeId",
            'EmployeeCode',     l."EmployeeCode",
            'EmployeeName',     l."EmployeeName",
            'MonthlySalary',    l."MonthlySalary",
            'DailySalary',      l."DailySalary",
            'DaysWorked',       l."DaysWorked",
            'DaysEntitled',     l."DaysEntitled",
            'GrossAmount',      l."GrossAmount",
            'InceDeduction',    l."InceDeduction",
            'NetAmount',        l."NetAmount",
            'IsPaid',           l."IsPaid",
            'PaidAt',           l."PaidAt"
        )
    FROM hr."ProfitSharingLine" l
    WHERE l."ProfitSharingId" = p_profit_sharing_id
    ORDER BY l."EmployeeName";
END;
$$;

-- =============================================================================
-- 3. usp_HR_ProfitSharing_Approve
-- =============================================================================
DROP FUNCTION IF EXISTS public.usp_HR_ProfitSharing_Approve(INTEGER, INTEGER, INTEGER, VARCHAR(500)) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_HR_ProfitSharing_Approve(
    p_profit_sharing_id INTEGER,
    p_approved_by       INTEGER,
    OUT p_resultado     INTEGER,
    OUT p_mensaje       VARCHAR(500)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_current_status VARCHAR(20);
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    SELECT "Status" INTO v_current_status
    FROM hr."ProfitSharing"
    WHERE "ProfitSharingId" = p_profit_sharing_id;

    IF v_current_status IS NULL THEN
        p_resultado := -1;
        p_mensaje   := 'Registro de utilidades no encontrado.';
        RETURN;
    END IF;

    IF v_current_status <> 'CALCULADA' THEN
        p_resultado := -2;
        p_mensaje   := 'Solo se pueden aprobar utilidades en estado CALCULADA. Estado actual: ' || v_current_status;
        RETURN;
    END IF;

    UPDATE hr."ProfitSharing"
    SET "Status"     = 'PROCESADA',
        "ApprovedBy" = p_approved_by,
        "ApprovedAt" = (NOW() AT TIME ZONE 'UTC'),
        "UpdatedAt"  = (NOW() AT TIME ZONE 'UTC')
    WHERE "ProfitSharingId" = p_profit_sharing_id;

    p_resultado := p_profit_sharing_id;
    p_mensaje   := 'Utilidades aprobadas exitosamente.';
END;
$$;

-- =============================================================================
-- 4. usp_HR_ProfitSharing_List
-- =============================================================================
DROP FUNCTION IF EXISTS public.usp_HR_ProfitSharing_List(INTEGER, INTEGER, INTEGER, VARCHAR(20), INTEGER, INTEGER) CASCADE;
DROP FUNCTION IF EXISTS public.usp_HR_ProfitSharing_List(INTEGER, INTEGER, VARCHAR(20), INTEGER, INTEGER) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_HR_ProfitSharing_List(
    p_company_id    INTEGER,
    p_year          INTEGER         DEFAULT NULL,
    p_status        VARCHAR(20)     DEFAULT NULL,
    p_offset        INTEGER         DEFAULT 0,
    p_limit         INTEGER         DEFAULT 50
)
RETURNS TABLE(
    p_total_count       BIGINT,
    "ProfitSharingId"   INTEGER,
    "CompanyId"         INTEGER,
    "FiscalYear"        INTEGER,
    "DaysGranted"       INTEGER,
    "TotalCompanyProfits" NUMERIC(18,2),
    "Status"            VARCHAR(20),
    "CreatedAt"         TIMESTAMP,
    "UpdatedAt"         TIMESTAMP,
    "TotalEmployees"    BIGINT,
    "TotalNet"          NUMERIC
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        COUNT(*) OVER()                                                                                           AS p_total_count,
        ps."ProfitSharingId",
        ps."CompanyId",
        ps."FiscalYear",
        ps."DaysGranted",
        ps."TotalCompanyProfits",
        ps."Status",
        ps."CreatedAt",
        ps."UpdatedAt",
        (SELECT COUNT(*) FROM hr."ProfitSharingLine" psl WHERE psl."ProfitSharingId" = ps."ProfitSharingId")::BIGINT     AS "TotalEmployees",
        COALESCE((SELECT SUM(psl2."NetAmount") FROM hr."ProfitSharingLine" psl2 WHERE psl2."ProfitSharingId" = ps."ProfitSharingId"), 0) AS "TotalNet"
    FROM hr."ProfitSharing" ps
    WHERE ps."CompanyId" = p_company_id
      AND (p_year     IS NULL OR ps."FiscalYear"  = p_year)
      AND (p_status   IS NULL OR ps."Status"      = p_status)
    ORDER BY ps."FiscalYear" DESC, ps."CreatedAt" DESC
    LIMIT p_limit OFFSET p_offset;
END;
$$;

-- =============================================================================
-- 5. usp_HR_Trust_CalculateQuarter
-- =============================================================================
DROP FUNCTION IF EXISTS public.usp_HR_Trust_CalculateQuarter(INTEGER, INTEGER, SMALLINT, NUMERIC(8,5), INTEGER, VARCHAR(500)) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_HR_Trust_CalculateQuarter(
    p_company_id    INTEGER,
    p_fiscal_year   INTEGER,
    p_quarter       SMALLINT,
    p_interest_rate NUMERIC(8,5)    DEFAULT 0,
    OUT p_resultado INTEGER,
    OUT p_mensaje   VARCHAR(500)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_inserted      INTEGER;
    v_year_end_str  TEXT;
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    IF p_quarter < 1 OR p_quarter > 4 THEN
        p_resultado := -1;
        p_mensaje   := 'El trimestre debe estar entre 1 y 4.';
        RETURN;
    END IF;

    IF EXISTS (
        SELECT 1 FROM hr."SocialBenefitsTrust"
        WHERE "CompanyId" = p_company_id AND "FiscalYear" = p_fiscal_year AND "Quarter" = p_quarter
    ) THEN
        p_resultado := -2;
        p_mensaje   := 'Ya existe un cÃ¡lculo para el trimestre ' || p_quarter::TEXT || ' del aÃ±o ' || p_fiscal_year::TEXT || '.';
        RETURN;
    END IF;

    v_year_end_str := p_fiscal_year::TEXT || '-12-31';

    BEGIN
        INSERT INTO hr."SocialBenefitsTrust" (
            "CompanyId", "EmployeeId", "EmployeeCode", "EmployeeName",
            "FiscalYear", "Quarter", "DailySalary",
            "DaysDeposited", "BonusDays", "DepositAmount",
            "InterestRate", "InterestAmount", "AccumulatedBalance", "Status",
            "CreatedAt", "UpdatedAt"
        )
        SELECT
            p_company_id,
            e."EmployeeId",
            e."EmployeeCode",
            e."EmployeeName",
            p_fiscal_year,
            p_quarter,
            ROUND(COALESCE((
                SELECT prl."Amount"
                FROM hr."PayrollRun" pr
                INNER JOIN hr."PayrollRunLine" prl ON prl."PayrollRunId" = pr."PayrollRunId"
                WHERE pr."EmployeeId" = e."EmployeeId" AND prl."ConceptCode" = 'SALARIO_BASE'
                ORDER BY pr."CreatedAt" DESC LIMIT 1
            ), 0) / 30.0, 2) AS "DailySalary",
            15 AS "DaysDeposited",
            -- BonusDays: 2 dÃ­as por cada aÃ±o despuÃ©s del primero, max 30, solo en Q4
            CASE
                WHEN p_quarter = 4
                 AND DATE_PART('year', v_year_end_str::DATE) - DATE_PART('year', e."HireDate") > 1
                THEN LEAST(
                    (DATE_PART('year', v_year_end_str::DATE) - DATE_PART('year', e."HireDate") - 1)::INTEGER * 2,
                    30
                )
                ELSE 0
            END AS "BonusDays",
            -- DepositAmount = DailySalary * (15 + BonusDays)
            ROUND(
                COALESCE((
                    SELECT prl."Amount"
                    FROM hr."PayrollRun" pr
                    INNER JOIN hr."PayrollRunLine" prl ON prl."PayrollRunId" = pr."PayrollRunId"
                    WHERE pr."EmployeeId" = e."EmployeeId" AND prl."ConceptCode" = 'SALARIO_BASE'
                    ORDER BY pr."CreatedAt" DESC LIMIT 1
                ), 0) / 30.0
                * (15 + CASE
                    WHEN p_quarter = 4
                     AND DATE_PART('year', v_year_end_str::DATE) - DATE_PART('year', e."HireDate") > 1
                    THEN LEAST(
                        (DATE_PART('year', v_year_end_str::DATE) - DATE_PART('year', e."HireDate") - 1)::INTEGER * 2,
                        30
                    )
                    ELSE 0
                   END),
            2) AS "DepositAmount",
            p_interest_rate,
            -- InterestAmount = saldo acumulado anterior * tasa / 4
            ROUND(
                COALESCE((
                    SELECT t."AccumulatedBalance"
                    FROM hr."SocialBenefitsTrust" t
                    WHERE t."CompanyId" = p_company_id
                      AND t."EmployeeCode" = e."EmployeeCode"
                      AND (t."FiscalYear" < p_fiscal_year
                           OR (t."FiscalYear" = p_fiscal_year AND t."Quarter" < p_quarter))
                    ORDER BY t."FiscalYear" DESC, t."Quarter" DESC
                    LIMIT 1
                ), 0) * (p_interest_rate / 100.0) / 4.0,
            2) AS "InterestAmount",
            -- AccumulatedBalance = saldo anterior + deposito + interes
            COALESCE((
                SELECT t."AccumulatedBalance"
                FROM hr."SocialBenefitsTrust" t
                WHERE t."CompanyId" = p_company_id
                  AND t."EmployeeCode" = e."EmployeeCode"
                  AND (t."FiscalYear" < p_fiscal_year
                       OR (t."FiscalYear" = p_fiscal_year AND t."Quarter" < p_quarter))
                ORDER BY t."FiscalYear" DESC, t."Quarter" DESC
                LIMIT 1
            ), 0)
            +
            ROUND(
                COALESCE((
                    SELECT prl."Amount"
                    FROM hr."PayrollRun" pr
                    INNER JOIN hr."PayrollRunLine" prl ON prl."PayrollRunId" = pr."PayrollRunId"
                    WHERE pr."EmployeeId" = e."EmployeeId" AND prl."ConceptCode" = 'SALARIO_BASE'
                    ORDER BY pr."CreatedAt" DESC LIMIT 1
                ), 0) / 30.0
                * (15 + CASE
                    WHEN p_quarter = 4
                     AND DATE_PART('year', v_year_end_str::DATE) - DATE_PART('year', e."HireDate") > 1
                    THEN LEAST(
                        (DATE_PART('year', v_year_end_str::DATE) - DATE_PART('year', e."HireDate") - 1)::INTEGER * 2,
                        30
                    )
                    ELSE 0
                   END),
            2)
            +
            ROUND(
                COALESCE((
                    SELECT t."AccumulatedBalance"
                    FROM hr."SocialBenefitsTrust" t
                    WHERE t."CompanyId" = p_company_id
                      AND t."EmployeeCode" = e."EmployeeCode"
                      AND (t."FiscalYear" < p_fiscal_year
                           OR (t."FiscalYear" = p_fiscal_year AND t."Quarter" < p_quarter))
                    ORDER BY t."FiscalYear" DESC, t."Quarter" DESC
                    LIMIT 1
                ), 0) * (p_interest_rate / 100.0) / 4.0,
            2) AS "AccumulatedBalance",
            'PENDIENTE',
            (NOW() AT TIME ZONE 'UTC'),
            (NOW() AT TIME ZONE 'UTC')
        FROM master."Employee" e
        WHERE e."CompanyId" = p_company_id
          AND e."IsActive" = TRUE
          AND e."HireDate" <= MAKE_DATE(p_fiscal_year, p_quarter * 3, 28);

        GET DIAGNOSTICS v_inserted = ROW_COUNT;

        p_resultado := v_inserted;
        p_mensaje   := 'Fideicomiso calculado para ' || v_inserted::TEXT || ' empleados.';

    EXCEPTION WHEN OTHERS THEN
        p_resultado := -99;
        p_mensaje   := SQLERRM;
    END;
END;
$$;

-- =============================================================================
-- 6. usp_HR_Trust_GetEmployeeBalance
-- =============================================================================
DROP FUNCTION IF EXISTS public.usp_HR_Trust_GetEmployeeBalance(INTEGER, VARCHAR(24)) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_HR_Trust_GetEmployeeBalance(
    p_company_id    INTEGER,
    p_employee_code VARCHAR(24)
)
RETURNS TABLE (
    result_type TEXT,
    row_data    JSONB
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Saldo actual (1 fila)
    RETURN QUERY
    SELECT
        'BALANCE'::TEXT,
        jsonb_build_object(
            'EmployeeCode',     t."EmployeeCode",
            'EmployeeName',     t."EmployeeName",
            'CurrentBalance',   t."AccumulatedBalance",
            'LastFiscalYear',   t."FiscalYear",
            'LastQuarter',      t."Quarter"
        )
    FROM hr."SocialBenefitsTrust" t
    WHERE t."CompanyId" = p_company_id AND t."EmployeeCode" = p_employee_code
    ORDER BY t."FiscalYear" DESC, t."Quarter" DESC
    LIMIT 1;

    -- Historial
    RETURN QUERY
    SELECT
        'HISTORY'::TEXT,
        jsonb_build_object(
            'TrustId',              t."TrustId",
            'FiscalYear',           t."FiscalYear",
            'Quarter',              t."Quarter",
            'DailySalary',          t."DailySalary",
            'DaysDeposited',        t."DaysDeposited",
            'BonusDays',            t."BonusDays",
            'DepositAmount',        t."DepositAmount",
            'InterestRate',         t."InterestRate",
            'InterestAmount',       t."InterestAmount",
            'AccumulatedBalance',   t."AccumulatedBalance",
            'Status',               t."Status",
            'CreatedAt',            t."CreatedAt"
        )
    FROM hr."SocialBenefitsTrust" t
    WHERE t."CompanyId" = p_company_id AND t."EmployeeCode" = p_employee_code
    ORDER BY t."FiscalYear", t."Quarter";
END;
$$;

-- =============================================================================
-- 7. usp_HR_Trust_GetSummary
-- =============================================================================
DROP FUNCTION IF EXISTS public.usp_HR_Trust_GetSummary(INTEGER, INTEGER, INTEGER) CASCADE;
DROP FUNCTION IF EXISTS public.usp_HR_Trust_GetSummary(INTEGER, INTEGER, SMALLINT) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_HR_Trust_GetSummary(
    p_company_id    INTEGER,
    p_fiscal_year   INTEGER,
    p_quarter       SMALLINT
)
RETURNS TABLE (
    result_type TEXT,
    row_data    JSONB
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Resumen por estado
    RETURN QUERY
    SELECT
        'SUMMARY'::TEXT,
        jsonb_build_object(
            'TotalEmployees',           COUNT(*),
            'TotalDeposits',            SUM(t."DepositAmount"),
            'TotalInterest',            SUM(t."InterestAmount"),
            'TotalBonusDays',           SUM(t."BonusDays"),
            'TotalAccumulatedBalance',  SUM(t."AccumulatedBalance"),
            'Status',                   t."Status"
        )
    FROM hr."SocialBenefitsTrust" t
    WHERE t."CompanyId" = p_company_id AND t."FiscalYear" = p_fiscal_year AND t."Quarter" = p_quarter
    GROUP BY t."Status";

    -- Detalle por empleado
    RETURN QUERY
    SELECT
        'DETAIL'::TEXT,
        jsonb_build_object(
            'TrustId',              t."TrustId",
            'EmployeeCode',         t."EmployeeCode",
            'EmployeeName',         t."EmployeeName",
            'DailySalary',          t."DailySalary",
            'DaysDeposited',        t."DaysDeposited",
            'BonusDays',            t."BonusDays",
            'DepositAmount',        t."DepositAmount",
            'InterestRate',         t."InterestRate",
            'InterestAmount',       t."InterestAmount",
            'AccumulatedBalance',   t."AccumulatedBalance",
            'Status',               t."Status"
        )
    FROM hr."SocialBenefitsTrust" t
    WHERE t."CompanyId" = p_company_id AND t."FiscalYear" = p_fiscal_year AND t."Quarter" = p_quarter
    ORDER BY t."EmployeeName";
END;
$$;

-- =============================================================================
-- 8. usp_HR_Trust_List
-- =============================================================================
DROP FUNCTION IF EXISTS public.usp_HR_Trust_List(INTEGER, INTEGER, SMALLINT, VARCHAR(24), VARCHAR(20), INTEGER, INTEGER) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_HR_Trust_List(
    p_company_id    INTEGER,
    p_fiscal_year   INTEGER         DEFAULT NULL,
    p_quarter       SMALLINT        DEFAULT NULL,
    p_employee_code VARCHAR(24)     DEFAULT NULL,
    p_status        VARCHAR(20)     DEFAULT NULL,
    p_offset        INTEGER         DEFAULT 0,
    p_limit         INTEGER         DEFAULT 50
)
RETURNS TABLE(
    p_total_count           BIGINT,
    "TrustId"               INTEGER,
    "EmployeeId"            BIGINT,
    "EmployeeCode"          VARCHAR(24),
    "EmployeeName"          VARCHAR(200),
    "FiscalYear"            INTEGER,
    "Quarter"               SMALLINT,
    "DailySalary"           NUMERIC(18,2),
    "DaysDeposited"         INTEGER,
    "BonusDays"             INTEGER,
    "DepositAmount"         NUMERIC(18,2),
    "InterestRate"          NUMERIC(8,5),
    "InterestAmount"        NUMERIC(18,2),
    "AccumulatedBalance"    NUMERIC(18,2),
    "Status"                VARCHAR(20),
    "CreatedAt"             TIMESTAMP
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        COUNT(*) OVER()         AS p_total_count,
        t."TrustId",
        t."EmployeeId",
        t."EmployeeCode",
        t."EmployeeName",
        t."FiscalYear",
        t."Quarter",
        t."DailySalary",
        t."DaysDeposited",
        t."BonusDays",
        t."DepositAmount",
        t."InterestRate",
        t."InterestAmount",
        t."AccumulatedBalance",
        t."Status",
        t."CreatedAt"
    FROM hr."SocialBenefitsTrust" t
    WHERE t."CompanyId" = p_company_id
      AND (p_fiscal_year   IS NULL OR t."FiscalYear"    = p_fiscal_year)
      AND (p_quarter       IS NULL OR t."Quarter"        = p_quarter)
      AND (p_employee_code IS NULL OR t."EmployeeCode"   = p_employee_code)
      AND (p_status        IS NULL OR t."Status"         = p_status)
    ORDER BY t."FiscalYear" DESC, t."Quarter" DESC, t."EmployeeName"
    LIMIT p_limit OFFSET p_offset;
END;
$$;

-- =============================================================================
-- 9. usp_HR_Savings_Enroll
-- =============================================================================
DROP FUNCTION IF EXISTS public.usp_HR_Savings_Enroll(INTEGER, BIGINT, VARCHAR(24), VARCHAR(200), NUMERIC(8,4), NUMERIC(8,4), DATE, INTEGER, VARCHAR(500)) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_HR_Savings_Enroll(
    p_company_id                INTEGER,
    p_employee_id               BIGINT          DEFAULT NULL,
    p_employee_code             VARCHAR(24)     DEFAULT NULL,
    p_employee_name             VARCHAR(200)    DEFAULT NULL,
    p_employee_contribution     NUMERIC(8,4)    DEFAULT NULL,
    p_employer_match            NUMERIC(8,4)    DEFAULT NULL,
    p_enrollment_date           DATE            DEFAULT NULL,
    OUT p_resultado             INTEGER,
    OUT p_mensaje               VARCHAR(500)
)
LANGUAGE plpgsql
AS $$
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    IF EXISTS (
        SELECT 1 FROM hr."SavingsFund"
        WHERE "CompanyId" = p_company_id AND "EmployeeCode" = p_employee_code AND "Status" = 'ACTIVO'
    ) THEN
        p_resultado := -1;
        p_mensaje   := 'El empleado ya estÃ¡ inscrito en la caja de ahorro.';
        RETURN;
    END IF;

    IF p_employee_contribution <= 0 OR p_employer_match < 0 THEN
        p_resultado := -2;
        p_mensaje   := 'El porcentaje de aporte del empleado debe ser mayor a cero.';
        RETURN;
    END IF;

    BEGIN
        INSERT INTO hr."SavingsFund" (
            "CompanyId", "EmployeeId", "EmployeeCode", "EmployeeName",
            "EmployeeContribution", "EmployerMatch", "EnrollmentDate", "Status", "CreatedAt"
        )
        VALUES (
            p_company_id, p_employee_id, p_employee_code, p_employee_name,
            p_employee_contribution, p_employer_match, p_enrollment_date, 'ACTIVO',
            (NOW() AT TIME ZONE 'UTC')
        )
        RETURNING "SavingsFundId" INTO p_resultado;

        p_mensaje := 'Empleado inscrito en caja de ahorro exitosamente.';

    EXCEPTION WHEN OTHERS THEN
        p_resultado := -99;
        p_mensaje   := SQLERRM;
    END;
END;
$$;

-- =============================================================================
-- 10. usp_HR_Savings_ProcessMonthly
-- =============================================================================
DROP FUNCTION IF EXISTS public.usp_HR_Savings_ProcessMonthly(INTEGER, DATE, INTEGER, INTEGER, VARCHAR(500)) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_HR_Savings_ProcessMonthly(
    p_company_id        INTEGER,
    p_process_date      DATE,
    p_payroll_batch_id  INTEGER         DEFAULT NULL,
    OUT p_resultado     INTEGER,
    OUT p_mensaje       VARCHAR(500)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_fund_id       INTEGER;
    v_emp_code      VARCHAR(24);
    v_emp_contrib   NUMERIC(8,4);
    v_match_pct     NUMERIC(8,4);
    v_salary        NUMERIC(18,2);
    v_emp_amount    NUMERIC(18,2);
    v_match_amount  NUMERIC(18,2);
    v_cur_balance   NUMERIC(18,2);
    v_processed     INTEGER := 0;
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    BEGIN
        FOR v_fund_id, v_emp_code, v_emp_contrib, v_match_pct IN
            SELECT sf."SavingsFundId", sf."EmployeeCode", sf."EmployeeContribution", sf."EmployerMatch"
            FROM hr."SavingsFund" sf
            WHERE sf."CompanyId" = p_company_id AND sf."Status" = 'ACTIVO'
        LOOP
            SELECT COALESCE((
                SELECT prl."Amount"
                FROM hr."PayrollRun" pr
                INNER JOIN hr."PayrollRunLine" prl ON prl."PayrollRunId" = pr."PayrollRunId"
                WHERE pr."EmployeeId" = e."EmployeeId" AND prl."ConceptCode" = 'SALARIO_BASE'
                ORDER BY pr."CreatedAt" DESC LIMIT 1
            ), 0)
            INTO v_salary
            FROM master."Employee" e
            WHERE e."CompanyId" = p_company_id AND e."EmployeeCode" = v_emp_code AND e."IsActive" = TRUE;

            IF v_salary IS NOT NULL AND v_salary > 0 THEN
                v_emp_amount   := ROUND(v_salary * v_emp_contrib / 100.0, 2);
                v_match_amount := ROUND(v_salary * v_match_pct  / 100.0, 2);

                SELECT COALESCE((
                    SELECT "Balance" FROM hr."SavingsFundTransaction"
                    WHERE "SavingsFundId" = v_fund_id
                    ORDER BY "TransactionId" DESC LIMIT 1
                ), 0)
                INTO v_cur_balance;

                v_cur_balance := v_cur_balance + v_emp_amount;
                INSERT INTO hr."SavingsFundTransaction" (
                    "SavingsFundId", "TransactionDate", "TransactionType",
                    "Amount", "Balance", "Reference", "PayrollBatchId", "CreatedAt"
                )
                VALUES (
                    v_fund_id, p_process_date, 'APORTE_EMPLEADO',
                    v_emp_amount, v_cur_balance,
                    'Aporte mensual ' || TO_CHAR(p_process_date, 'YYYY-MM'),
                    p_payroll_batch_id,
                    (NOW() AT TIME ZONE 'UTC')
                );

                v_cur_balance := v_cur_balance + v_match_amount;
                INSERT INTO hr."SavingsFundTransaction" (
                    "SavingsFundId", "TransactionDate", "TransactionType",
                    "Amount", "Balance", "Reference", "PayrollBatchId", "CreatedAt"
                )
                VALUES (
                    v_fund_id, p_process_date, 'APORTE_PATRONAL',
                    v_match_amount, v_cur_balance,
                    'Aporte patronal ' || TO_CHAR(p_process_date, 'YYYY-MM'),
                    p_payroll_batch_id,
                    (NOW() AT TIME ZONE 'UTC')
                );

                v_processed := v_processed + 1;
            END IF;
        END LOOP;

        p_resultado := v_processed;
        p_mensaje   := 'Aportes procesados para ' || v_processed::TEXT || ' miembros.';

    EXCEPTION WHEN OTHERS THEN
        p_resultado := -99;
        p_mensaje   := SQLERRM;
    END;
END;
$$;

-- =============================================================================
-- 11. usp_HR_Savings_GetBalance
-- =============================================================================
DROP FUNCTION IF EXISTS public.usp_HR_Savings_GetBalance(INTEGER, VARCHAR(24)) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_HR_Savings_GetBalance(
    p_company_id    INTEGER,
    p_employee_code VARCHAR(24)
)
RETURNS TABLE (
    result_type TEXT,
    row_data    JSONB
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Datos del fondo
    RETURN QUERY
    SELECT
        'FUND'::TEXT,
        jsonb_build_object(
            'SavingsFundId',        sf."SavingsFundId",
            'EmployeeCode',         sf."EmployeeCode",
            'EmployeeName',         sf."EmployeeName",
            'EmployeeContribution', sf."EmployeeContribution",
            'EmployerMatch',        sf."EmployerMatch",
            'EnrollmentDate',       sf."EnrollmentDate",
            'Status',               sf."Status",
            'CurrentBalance',       COALESCE((
                                        SELECT "Balance" FROM hr."SavingsFundTransaction"
                                        WHERE "SavingsFundId" = sf."SavingsFundId"
                                        ORDER BY "TransactionId" DESC LIMIT 1
                                    ), 0)
        )
    FROM hr."SavingsFund" sf
    WHERE sf."CompanyId" = p_company_id AND sf."EmployeeCode" = p_employee_code;

    -- Historial de transacciones
    RETURN QUERY
    SELECT
        'TRANSACTION'::TEXT,
        jsonb_build_object(
            'TransactionId',    tx."TransactionId",
            'TransactionDate',  tx."TransactionDate",
            'TransactionType',  tx."TransactionType",
            'Amount',           tx."Amount",
            'Balance',          tx."Balance",
            'Reference',        tx."Reference",
            'PayrollBatchId',   tx."PayrollBatchId",
            'Notes',            tx."Notes",
            'CreatedAt',        tx."CreatedAt"
        )
    FROM hr."SavingsFundTransaction" tx
    INNER JOIN hr."SavingsFund" sf ON sf."SavingsFundId" = tx."SavingsFundId"
    WHERE sf."CompanyId" = p_company_id AND sf."EmployeeCode" = p_employee_code
    ORDER BY tx."TransactionDate" DESC, tx."TransactionId" DESC;
END;
$$;

-- =============================================================================
-- 12. usp_HR_Savings_RequestLoan
-- =============================================================================
DROP FUNCTION IF EXISTS public.usp_HR_Savings_RequestLoan(INTEGER, VARCHAR(24), NUMERIC(18,2), NUMERIC(8,5), INTEGER, VARCHAR(500), INTEGER, VARCHAR(500)) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_HR_Savings_RequestLoan(
    p_company_id        INTEGER,
    p_employee_code     VARCHAR(24),
    p_loan_amount       NUMERIC(18,2),
    p_interest_rate     NUMERIC(8,5)    DEFAULT 0,
    p_installments_total INTEGER        DEFAULT NULL,
    p_notes             VARCHAR(500)    DEFAULT NULL,
    OUT p_resultado     INTEGER,
    OUT p_mensaje       VARCHAR(500)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_fund_id       INTEGER;
    v_total_payable NUMERIC(18,2);
    v_monthly_pmt   NUMERIC(18,2);
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    SELECT "SavingsFundId" INTO v_fund_id
    FROM hr."SavingsFund"
    WHERE "CompanyId" = p_company_id AND "EmployeeCode" = p_employee_code AND "Status" = 'ACTIVO';

    IF v_fund_id IS NULL THEN
        p_resultado := -1;
        p_mensaje   := 'El empleado no tiene una cuenta activa en caja de ahorro.';
        RETURN;
    END IF;

    IF EXISTS (
        SELECT 1 FROM hr."SavingsLoan"
        WHERE "SavingsFundId" = v_fund_id AND "Status" IN ('SOLICITADO','APROBADO','ACTIVO')
    ) THEN
        p_resultado := -2;
        p_mensaje   := 'El empleado ya tiene un prÃ©stamo activo o pendiente.';
        RETURN;
    END IF;

    IF p_loan_amount <= 0 THEN
        p_resultado := -3;
        p_mensaje   := 'El monto del prÃ©stamo debe ser mayor a cero.';
        RETURN;
    END IF;

    IF p_installments_total <= 0 THEN
        p_resultado := -4;
        p_mensaje   := 'El nÃºmero de cuotas debe ser mayor a cero.';
        RETURN;
    END IF;

    v_total_payable := ROUND(p_loan_amount * (1 + p_interest_rate / 100.0), 2);
    v_monthly_pmt   := ROUND(v_total_payable / p_installments_total, 2);

    BEGIN
        INSERT INTO hr."SavingsLoan" (
            "SavingsFundId", "EmployeeCode", "RequestDate",
            "LoanAmount", "InterestRate", "TotalPayable", "MonthlyPayment",
            "InstallmentsTotal", "InstallmentsPaid", "OutstandingBalance",
            "Status", "Notes", "CreatedAt", "UpdatedAt"
        )
        VALUES (
            v_fund_id, p_employee_code, CAST((NOW() AT TIME ZONE 'UTC') AS DATE),
            p_loan_amount, p_interest_rate, v_total_payable, v_monthly_pmt,
            p_installments_total, 0, v_total_payable,
            'SOLICITADO', p_notes,
            (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
        )
        RETURNING "LoanId" INTO p_resultado;

        p_mensaje := 'Solicitud de prÃ©stamo registrada exitosamente.';

    EXCEPTION WHEN OTHERS THEN
        p_resultado := -99;
        p_mensaje   := SQLERRM;
    END;
END;
$$;

-- =============================================================================
-- 13. usp_HR_Savings_ApproveLoan
-- =============================================================================
DROP FUNCTION IF EXISTS public.usp_HR_Savings_ApproveLoan(INTEGER, BOOLEAN, INTEGER, VARCHAR(500), INTEGER, VARCHAR(500)) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_HR_Savings_ApproveLoan(
    p_loan_id       INTEGER,
    p_approved      BOOLEAN,
    p_approved_by   INTEGER,
    p_notes         VARCHAR(500)    DEFAULT NULL,
    OUT p_resultado INTEGER,
    OUT p_mensaje   VARCHAR(500)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_current_status    VARCHAR(15);
    v_fund_id           INTEGER;
    v_loan_amount       NUMERIC(18,2);
    v_cur_balance       NUMERIC(18,2);
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    SELECT "Status", "SavingsFundId", "LoanAmount"
    INTO v_current_status, v_fund_id, v_loan_amount
    FROM hr."SavingsLoan"
    WHERE "LoanId" = p_loan_id;

    IF v_current_status IS NULL THEN
        p_resultado := -1;
        p_mensaje   := 'PrÃ©stamo no encontrado.';
        RETURN;
    END IF;

    IF v_current_status <> 'SOLICITADO' THEN
        p_resultado := -2;
        p_mensaje   := 'Solo se pueden aprobar/rechazar prÃ©stamos en estado SOLICITADO. Estado actual: ' || v_current_status;
        RETURN;
    END IF;

    BEGIN
        IF p_approved THEN
            UPDATE hr."SavingsLoan"
            SET "Status"        = 'ACTIVO',
                "ApprovedDate"  = CAST((NOW() AT TIME ZONE 'UTC') AS DATE),
                "ApprovedBy"    = p_approved_by,
                "Notes"         = COALESCE(p_notes, "Notes"),
                "UpdatedAt"     = (NOW() AT TIME ZONE 'UTC')
            WHERE "LoanId" = p_loan_id;

            SELECT COALESCE((
                SELECT "Balance" FROM hr."SavingsFundTransaction"
                WHERE "SavingsFundId" = v_fund_id
                ORDER BY "TransactionId" DESC LIMIT 1
            ), 0)
            INTO v_cur_balance;

            v_cur_balance := v_cur_balance - v_loan_amount;

            INSERT INTO hr."SavingsFundTransaction" (
                "SavingsFundId", "TransactionDate", "TransactionType",
                "Amount", "Balance", "Reference", "Notes", "CreatedAt"
            )
            VALUES (
                v_fund_id,
                CAST((NOW() AT TIME ZONE 'UTC') AS DATE),
                'PRESTAMO',
                v_loan_amount,
                v_cur_balance,
                'Desembolso prÃ©stamo #' || p_loan_id::TEXT,
                'Aprobado por usuario ' || p_approved_by::TEXT,
                (NOW() AT TIME ZONE 'UTC')
            );

            p_mensaje := 'PrÃ©stamo aprobado y desembolsado exitosamente.';
        ELSE
            UPDATE hr."SavingsLoan"
            SET "Status"    = 'RECHAZADO',
                "ApprovedBy" = p_approved_by,
                "Notes"      = COALESCE(p_notes, "Notes"),
                "UpdatedAt"  = (NOW() AT TIME ZONE 'UTC')
            WHERE "LoanId" = p_loan_id;

            p_mensaje := 'PrÃ©stamo rechazado.';
        END IF;

        p_resultado := p_loan_id;

    EXCEPTION WHEN OTHERS THEN
        p_resultado := -99;
        p_mensaje   := SQLERRM;
    END;
END;
$$;

-- =============================================================================
-- 14. usp_HR_Savings_ProcessLoanPayment
-- =============================================================================
DROP FUNCTION IF EXISTS public.usp_HR_Savings_ProcessLoanPayment(INTEGER, NUMERIC(18,2), DATE, INTEGER, INTEGER, VARCHAR(500)) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_HR_Savings_ProcessLoanPayment(
    p_loan_id           INTEGER,
    p_payment_amount    NUMERIC(18,2)   DEFAULT NULL,
    p_payment_date      DATE            DEFAULT NULL,
    p_payroll_batch_id  INTEGER         DEFAULT NULL,
    OUT p_resultado     INTEGER,
    OUT p_mensaje       VARCHAR(500)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_fund_id           INTEGER;
    v_monthly_payment   NUMERIC(18,2);
    v_outstanding       NUMERIC(18,2);
    v_inst_paid         INTEGER;
    v_inst_total        INTEGER;
    v_current_status    VARCHAR(15);
    v_cur_balance       NUMERIC(18,2);
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    SELECT "SavingsFundId", "MonthlyPayment", "OutstandingBalance",
           "InstallmentsPaid", "InstallmentsTotal", "Status"
    INTO v_fund_id, v_monthly_payment, v_outstanding,
         v_inst_paid, v_inst_total, v_current_status
    FROM hr."SavingsLoan"
    WHERE "LoanId" = p_loan_id;

    IF v_current_status IS NULL THEN
        p_resultado := -1;
        p_mensaje   := 'PrÃ©stamo no encontrado.';
        RETURN;
    END IF;

    IF v_current_status <> 'ACTIVO' THEN
        p_resultado := -2;
        p_mensaje   := 'Solo se pueden registrar pagos en prÃ©stamos ACTIVOS. Estado actual: ' || v_current_status;
        RETURN;
    END IF;

    IF p_payment_amount IS NULL THEN p_payment_amount := v_monthly_payment; END IF;
    IF p_payment_date   IS NULL THEN p_payment_date   := CAST((NOW() AT TIME ZONE 'UTC') AS DATE); END IF;

    IF p_payment_amount > v_outstanding THEN
        p_payment_amount := v_outstanding;
    END IF;

    BEGIN
        v_outstanding := v_outstanding - p_payment_amount;
        v_inst_paid   := v_inst_paid + 1;

        UPDATE hr."SavingsLoan"
        SET "OutstandingBalance"  = v_outstanding,
            "InstallmentsPaid"    = v_inst_paid,
            "Status"              = CASE WHEN v_outstanding <= 0 THEN 'PAGADO' ELSE 'ACTIVO' END,
            "UpdatedAt"           = (NOW() AT TIME ZONE 'UTC')
        WHERE "LoanId" = p_loan_id;

        SELECT COALESCE((
            SELECT "Balance" FROM hr."SavingsFundTransaction"
            WHERE "SavingsFundId" = v_fund_id
            ORDER BY "TransactionId" DESC LIMIT 1
        ), 0)
        INTO v_cur_balance;

        v_cur_balance := v_cur_balance + p_payment_amount;

        INSERT INTO hr."SavingsFundTransaction" (
            "SavingsFundId", "TransactionDate", "TransactionType",
            "Amount", "Balance", "Reference", "PayrollBatchId", "Notes", "CreatedAt"
        )
        VALUES (
            v_fund_id,
            p_payment_date,
            'PAGO_PRESTAMO',
            p_payment_amount,
            v_cur_balance,
            'Pago cuota ' || v_inst_paid::TEXT || '/' || v_inst_total::TEXT || ' prÃ©stamo #' || p_loan_id::TEXT,
            p_payroll_batch_id,
            CASE WHEN v_outstanding <= 0 THEN 'PrÃ©stamo liquidado' ELSE NULL END,
            (NOW() AT TIME ZONE 'UTC')
        );

        p_resultado := p_loan_id;
        IF v_outstanding <= 0 THEN
            p_mensaje := 'PrÃ©stamo liquidado exitosamente.';
        ELSE
            p_mensaje := 'Pago registrado. Saldo pendiente: ' || v_outstanding::TEXT;
        END IF;

    EXCEPTION WHEN OTHERS THEN
        p_resultado := -99;
        p_mensaje   := SQLERRM;
    END;
END;
$$;

-- =============================================================================
-- 15. usp_HR_Savings_List
-- =============================================================================
DROP FUNCTION IF EXISTS public.usp_HR_Savings_List(INTEGER, VARCHAR(15), VARCHAR(24), INTEGER, INTEGER) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_HR_Savings_List(
    p_company_id    INTEGER,
    p_status        VARCHAR(15)     DEFAULT NULL,
    p_employee_code VARCHAR(24)     DEFAULT NULL,
    p_offset        INTEGER         DEFAULT 0,
    p_limit         INTEGER         DEFAULT 50
)
RETURNS TABLE(
    p_total_count           BIGINT,
    "SavingsFundId"         INTEGER,
    "EmployeeId"            BIGINT,
    "EmployeeCode"          VARCHAR(24),
    "EmployeeName"          VARCHAR(200),
    "EmployeeContribution"  NUMERIC(8,4),
    "EmployerMatch"         NUMERIC(8,4),
    "EnrollmentDate"        DATE,
    "Status"                VARCHAR(15),
    "CreatedAt"             TIMESTAMP,
    "CurrentBalance"        NUMERIC
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        COUNT(*) OVER()         AS p_total_count,
        sf."SavingsFundId",
        sf."EmployeeId",
        sf."EmployeeCode",
        sf."EmployeeName",
        sf."EmployeeContribution",
        sf."EmployerMatch",
        sf."EnrollmentDate",
        sf."Status",
        sf."CreatedAt",
        COALESCE((
            SELECT "Balance" FROM hr."SavingsFundTransaction"
            WHERE "SavingsFundId" = sf."SavingsFundId"
            ORDER BY "TransactionId" DESC LIMIT 1
        ), 0::NUMERIC) AS "CurrentBalance"
    FROM hr."SavingsFund" sf
    WHERE sf."CompanyId" = p_company_id
      AND (p_status        IS NULL OR sf."Status"       = p_status)
      AND (p_employee_code IS NULL OR sf."EmployeeCode" = p_employee_code)
    ORDER BY sf."EmployeeName"
    LIMIT p_limit OFFSET p_offset;
END;
$$;

-- =============================================================================
-- 16. usp_HR_Savings_LoanList
-- =============================================================================
DROP FUNCTION IF EXISTS public.usp_HR_Savings_LoanList(INTEGER, VARCHAR(15), VARCHAR(24), INTEGER, INTEGER) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_HR_Savings_LoanList(
    p_company_id    INTEGER,
    p_status        VARCHAR(15)     DEFAULT NULL,
    p_employee_code VARCHAR(24)     DEFAULT NULL,
    p_offset        INTEGER         DEFAULT 0,
    p_limit         INTEGER         DEFAULT 50
)
RETURNS TABLE(
    p_total_count           BIGINT,
    "LoanId"                INTEGER,
    "SavingsFundId"         INTEGER,
    "EmployeeCode"          VARCHAR(24),
    "EmployeeName"          VARCHAR(200),
    "RequestDate"           DATE,
    "ApprovedDate"          DATE,
    "LoanAmount"            NUMERIC(18,2),
    "InterestRate"          NUMERIC(8,4),
    "TotalPayable"          NUMERIC(18,2),
    "MonthlyPayment"        NUMERIC(18,2),
    "InstallmentsTotal"     INTEGER,
    "InstallmentsPaid"      INTEGER,
    "OutstandingBalance"    NUMERIC(18,2),
    "Status"                VARCHAR(15),
    "ApprovedBy"            INTEGER,
    "Notes"                 VARCHAR(500),
    "CreatedAt"             TIMESTAMP
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        COUNT(*) OVER()         AS p_total_count,
        sl."LoanId",
        sl."SavingsFundId",
        sl."EmployeeCode",
        sf."EmployeeName",
        sl."RequestDate",
        sl."ApprovedDate",
        sl."LoanAmount",
        sl."InterestRate",
        sl."TotalPayable",
        sl."MonthlyPayment",
        sl."InstallmentsTotal",
        sl."InstallmentsPaid",
        sl."OutstandingBalance",
        sl."Status",
        sl."ApprovedBy",
        sl."Notes",
        sl."CreatedAt"
    FROM hr."SavingsLoan" sl
    INNER JOIN hr."SavingsFund" sf ON sf."SavingsFundId" = sl."SavingsFundId"
    WHERE sf."CompanyId" = p_company_id
      AND (p_status        IS NULL OR sl."Status"       = p_status)
      AND (p_employee_code IS NULL OR sl."EmployeeCode" = p_employee_code)
    ORDER BY sl."RequestDate" DESC, sl."LoanId" DESC
    LIMIT p_limit OFFSET p_offset;
END;
$$;


-- RRHH Functions: Obligaciones Legales

-- =============================================================================
-- sp_rrhh_obligaciones_legales.sql  (PostgreSQL / PL/pgSQL)
-- Convertido desde T-SQL: web/api/sqlweb/includes/sp/sp_rrhh_obligaciones_legales.sql
-- Fecha conversiÃ³n: 2026-03-16
--
-- Obligaciones Legales de RRHH (SSO, FAOV, INCE, TGSS, IMSS, EPS, FICA, etc.)
-- Modelo genÃ©rico, agnÃ³stico de paÃ­s, orientado a configuraciÃ³n.
--
-- Tablas:
--   hr.LegalObligation, hr.ObligationRiskLevel,
--   hr.EmployeeObligation, hr.ObligationFiling, hr.ObligationFilingDetail
--
-- Funciones:
--   1.  usp_HR_Obligation_List            - Listado paginado de obligaciones
--   2.  usp_HR_Obligation_Save            - Insertar/actualizar obligaciÃ³n
--   3.  usp_HR_Obligation_GetByCountry    - Obligaciones activas por paÃ­s
--   4.  usp_HR_EmployeeObligation_Enroll  - Inscribir empleado en obligaciÃ³n
--   5.  usp_HR_EmployeeObligation_Disenroll - Desinscribir empleado
--   6.  usp_HR_EmployeeObligation_GetByEmployee - Obligaciones de un empleado
--   7.  usp_HR_Filing_Generate            - Generar declaraciÃ³n para un perÃ­odo
--   8.  usp_HR_Filing_GetSummary          - Cabecera + detalle de declaraciÃ³n
--   9.  usp_HR_Filing_MarkFiled           - Marcar como presentada
--   10. usp_HR_Filing_List                - Listado paginado de declaraciones
-- =============================================================================

-- =============================================================================
-- DDL: Tablas requeridas por este mÃ³dulo
-- =============================================================================

CREATE SCHEMA IF NOT EXISTS hr;

-- hr."LegalObligation" - CatÃ¡logo maestro de obligaciones legales
CREATE TABLE IF NOT EXISTS hr."LegalObligation" (
    "LegalObligationId"  SERIAL          NOT NULL CONSTRAINT "PK_LegalObligation" PRIMARY KEY,
    "CountryCode"        CHAR(2)         NOT NULL,
    "Code"               VARCHAR(30)     NOT NULL,
    "Name"               VARCHAR(200)    NOT NULL,
    "InstitutionName"    VARCHAR(200)    NULL,
    "ObligationType"     VARCHAR(20)     NOT NULL, -- CONTRIBUTION, TAX_WITHHOLDING, REPORTING, REGISTRATION
    "CalculationBasis"   VARCHAR(30)     NOT NULL, -- NORMAL_SALARY, INTEGRAL_SALARY, GROSS_PAYROLL, TAXABLE_INCOME, FIXED_AMOUNT
    "SalaryCap"          NUMERIC(18,2)   NULL,
    "SalaryCapUnit"      VARCHAR(20)     NULL,     -- CURRENCY, MIN_WAGES, UMA, SMMLV
    "EmployerRate"       NUMERIC(8,5)    NOT NULL DEFAULT 0,
    "EmployeeRate"       NUMERIC(8,5)    NOT NULL DEFAULT 0,
    "RateVariableByRisk" BOOLEAN         NOT NULL DEFAULT FALSE,
    "FilingFrequency"    VARCHAR(15)     NOT NULL, -- MONTHLY, QUARTERLY, ANNUAL, REALTIME
    "FilingDeadlineRule" VARCHAR(200)    NULL,
    "EffectiveFrom"      DATE            NOT NULL,
    "EffectiveTo"        DATE            NULL,
    "IsActive"           BOOLEAN         NOT NULL DEFAULT TRUE,
    "Notes"              VARCHAR(500)    NULL,
    "CreatedAt"          TIMESTAMP(0)    NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "UpdatedAt"          TIMESTAMP(0)    NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    CONSTRAINT "UQ_LegalObligation_Country_Code_From" UNIQUE ("CountryCode", "Code", "EffectiveFrom")
);

-- hr."ObligationRiskLevel" - Tasas variables por nivel de riesgo
CREATE TABLE IF NOT EXISTS hr."ObligationRiskLevel" (
    "ObligationRiskLevelId" SERIAL          NOT NULL CONSTRAINT "PK_ObligationRiskLevel" PRIMARY KEY,
    "LegalObligationId"     INTEGER         NOT NULL,
    "RiskLevel"             SMALLINT        NOT NULL,
    "RiskDescription"       VARCHAR(100)    NULL,
    "EmployerRate"          NUMERIC(8,5)    NOT NULL DEFAULT 0,
    "EmployeeRate"          NUMERIC(8,5)    NOT NULL DEFAULT 0,
    CONSTRAINT "FK_ObligationRiskLevel_Obligation" FOREIGN KEY ("LegalObligationId")
        REFERENCES hr."LegalObligation" ("LegalObligationId"),
    CONSTRAINT "UQ_ObligationRiskLevel" UNIQUE ("LegalObligationId", "RiskLevel")
);

-- hr."EmployeeObligation" - InscripciÃ³n por empleado
CREATE TABLE IF NOT EXISTS hr."EmployeeObligation" (
    "EmployeeObligationId" SERIAL          NOT NULL CONSTRAINT "PK_EmployeeObligation" PRIMARY KEY,
    "EmployeeId"           BIGINT          NOT NULL,
    "LegalObligationId"    INTEGER         NOT NULL,
    "AffiliationNumber"    VARCHAR(50)     NULL,
    "InstitutionCode"      VARCHAR(50)     NULL,
    "RiskLevelId"          INTEGER         NULL,
    "EnrollmentDate"       DATE            NOT NULL,
    "DisenrollmentDate"    DATE            NULL,
    "Status"               VARCHAR(15)     NOT NULL DEFAULT 'ACTIVE', -- ACTIVE, SUSPENDED, TERMINATED
    "CustomRate"           NUMERIC(8,5)    NULL,
    "CreatedAt"            TIMESTAMP(0)    NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "UpdatedAt"            TIMESTAMP(0)    NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    CONSTRAINT "FK_EmployeeObligation_Obligation" FOREIGN KEY ("LegalObligationId")
        REFERENCES hr."LegalObligation" ("LegalObligationId"),
    CONSTRAINT "FK_EmployeeObligation_RiskLevel" FOREIGN KEY ("RiskLevelId")
        REFERENCES hr."ObligationRiskLevel" ("ObligationRiskLevelId")
);

-- hr."ObligationFiling" - Declaraciones por perÃ­odo
CREATE TABLE IF NOT EXISTS hr."ObligationFiling" (
    "ObligationFilingId"   SERIAL          NOT NULL CONSTRAINT "PK_ObligationFiling" PRIMARY KEY,
    "CompanyId"            INTEGER         NOT NULL,
    "LegalObligationId"    INTEGER         NOT NULL,
    "FilingPeriodStart"    DATE            NOT NULL,
    "FilingPeriodEnd"      DATE            NOT NULL,
    "DueDate"              DATE            NOT NULL,
    "FiledDate"            DATE            NULL,
    "ConfirmationNumber"   VARCHAR(100)    NULL,
    "TotalEmployerAmount"  NUMERIC(18,2)   NULL,
    "TotalEmployeeAmount"  NUMERIC(18,2)   NULL,
    "TotalAmount"          NUMERIC(18,2)   NULL,
    "EmployeeCount"        INTEGER         NULL,
    "Status"               VARCHAR(15)     NOT NULL DEFAULT 'PENDING', -- PENDING, LATE, FILED, PAID, REJECTED
    "FiledByUserId"        INTEGER         NULL,
    "DocumentUrl"          VARCHAR(500)    NULL,
    "Notes"                VARCHAR(500)    NULL,
    "CreatedAt"            TIMESTAMP(0)    NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "UpdatedAt"            TIMESTAMP(0)    NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    CONSTRAINT "FK_ObligationFiling_Obligation" FOREIGN KEY ("LegalObligationId")
        REFERENCES hr."LegalObligation" ("LegalObligationId")
);

-- hr."ObligationFilingDetail" - Detalle por empleado en cada declaraciÃ³n
CREATE TABLE IF NOT EXISTS hr."ObligationFilingDetail" (
    "DetailId"             SERIAL          NOT NULL CONSTRAINT "PK_ObligationFilingDetail" PRIMARY KEY,
    "ObligationFilingId"   INTEGER         NOT NULL,
    "EmployeeId"           BIGINT          NOT NULL,
    "BaseSalary"           NUMERIC(18,2)   NOT NULL DEFAULT 0,
    "EmployerAmount"       NUMERIC(18,2)   NOT NULL DEFAULT 0,
    "EmployeeAmount"       NUMERIC(18,2)   NOT NULL DEFAULT 0,
    "DaysWorked"           INTEGER         NOT NULL DEFAULT 30,
    "NoveltyType"          VARCHAR(20)     NOT NULL DEFAULT 'NONE', -- NONE, ENROLLMENT, WITHDRAWAL, SUSPENSION
    CONSTRAINT "FK_ObligationFilingDetail_Filing" FOREIGN KEY ("ObligationFilingId")
        REFERENCES hr."ObligationFiling" ("ObligationFilingId")
);

-- =============================================================================
-- 1. usp_HR_Obligation_List
-- =============================================================================
DROP FUNCTION IF EXISTS public.usp_HR_Obligation_List(CHAR(2), VARCHAR(20), BOOLEAN, VARCHAR(100), INTEGER, INTEGER) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_HR_Obligation_List(
    p_country_code      CHAR(2)         DEFAULT NULL,
    p_obligation_type   VARCHAR(20)     DEFAULT NULL,
    p_is_active         BOOLEAN         DEFAULT NULL,
    p_search            VARCHAR(100)    DEFAULT NULL,
    p_page              INTEGER         DEFAULT 1,
    p_limit             INTEGER         DEFAULT 50
)
RETURNS TABLE(
    p_total_count           BIGINT,
    "LegalObligationId"     INTEGER,
    "CountryCode"           CHAR(2),
    "Code"                  VARCHAR(30),
    "Name"                  VARCHAR(200),
    "InstitutionName"       VARCHAR(200),
    "ObligationType"        VARCHAR(20),
    "CalculationBasis"      VARCHAR(30),
    "SalaryCap"             NUMERIC(18,2),
    "SalaryCapUnit"         VARCHAR(20),
    "EmployerRate"          NUMERIC(8,5),
    "EmployeeRate"          NUMERIC(8,5),
    "RateVariableByRisk"    BOOLEAN,
    "FilingFrequency"       VARCHAR(15),
    "FilingDeadlineRule"    VARCHAR(200),
    "EffectiveFrom"         DATE,
    "EffectiveTo"           DATE,
    "IsActive"              BOOLEAN,
    "Notes"                 VARCHAR(500)
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_page  < 1   THEN p_page  := 1;   END IF;
    IF p_limit < 1   THEN p_limit := 50;  END IF;
    IF p_limit > 500 THEN p_limit := 500; END IF;

    RETURN QUERY
    SELECT
        COUNT(*) OVER()         AS p_total_count,
        "LegalObligationId",
        "CountryCode",
        "Code",
        "Name",
        "InstitutionName",
        "ObligationType",
        "CalculationBasis",
        "SalaryCap",
        "SalaryCapUnit",
        "EmployerRate",
        "EmployeeRate",
        "RateVariableByRisk",
        "FilingFrequency",
        "FilingDeadlineRule",
        "EffectiveFrom",
        "EffectiveTo",
        "IsActive",
        "Notes"
    FROM hr."LegalObligation"
    WHERE (p_country_code    IS NULL OR "CountryCode"    = p_country_code)
      AND (p_obligation_type IS NULL OR "ObligationType" = p_obligation_type)
      AND (p_is_active       IS NULL OR "IsActive"       = p_is_active)
      AND (p_search          IS NULL OR "Name" ILIKE '%' || p_search || '%'
                                     OR "Code" ILIKE '%' || p_search || '%')
    ORDER BY "CountryCode", "Code"
    LIMIT p_limit OFFSET (p_page - 1) * p_limit;
END;
$$;

-- =============================================================================
-- 2. usp_HR_Obligation_Save
-- =============================================================================
DROP FUNCTION IF EXISTS public.usp_HR_Obligation_Save(INTEGER, CHAR(2), VARCHAR(30), VARCHAR(200), VARCHAR(200), VARCHAR(20), VARCHAR(30), NUMERIC(18,2), VARCHAR(20), NUMERIC(8,5), NUMERIC(8,5), BOOLEAN, VARCHAR(15), VARCHAR(200), DATE, DATE, BOOLEAN, VARCHAR(500), INTEGER, VARCHAR(500)) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_HR_Obligation_Save(
    p_legal_obligation_id   INTEGER         DEFAULT NULL,
    p_country_code          CHAR(2)         DEFAULT NULL,
    p_code                  VARCHAR(30)     DEFAULT NULL,
    p_name                  VARCHAR(200)    DEFAULT NULL,
    p_institution_name      VARCHAR(200)    DEFAULT NULL,
    p_obligation_type       VARCHAR(20)     DEFAULT NULL,
    p_calculation_basis     VARCHAR(30)     DEFAULT NULL,
    p_salary_cap            NUMERIC(18,2)   DEFAULT NULL,
    p_salary_cap_unit       VARCHAR(20)     DEFAULT NULL,
    p_employer_rate         NUMERIC(8,5)    DEFAULT 0,
    p_employee_rate         NUMERIC(8,5)    DEFAULT 0,
    p_rate_variable_by_risk BOOLEAN         DEFAULT FALSE,
    p_filing_frequency      VARCHAR(15)     DEFAULT NULL,
    p_filing_deadline_rule  VARCHAR(200)    DEFAULT NULL,
    p_effective_from        DATE            DEFAULT NULL,
    p_effective_to          DATE            DEFAULT NULL,
    p_is_active             BOOLEAN         DEFAULT TRUE,
    p_notes                 VARCHAR(500)    DEFAULT NULL,
    OUT p_resultado         INTEGER,
    OUT p_mensaje           VARCHAR(500)
)
LANGUAGE plpgsql
AS $$
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    -- Validaciones
    IF p_country_code IS NULL OR LENGTH(TRIM(p_country_code)) = 0 THEN
        p_resultado := -1;
        p_mensaje   := 'El cÃ³digo de paÃ­s es obligatorio.';
        RETURN;
    END IF;

    IF p_code IS NULL OR LENGTH(TRIM(p_code)) = 0 THEN
        p_resultado := -1;
        p_mensaje   := 'El cÃ³digo de obligaciÃ³n es obligatorio.';
        RETURN;
    END IF;

    IF p_obligation_type NOT IN ('CONTRIBUTION','TAX_WITHHOLDING','REPORTING','REGISTRATION') THEN
        p_resultado := -1;
        p_mensaje   := 'Tipo de obligaciÃ³n no vÃ¡lido. Use: CONTRIBUTION, TAX_WITHHOLDING, REPORTING, REGISTRATION.';
        RETURN;
    END IF;

    IF p_calculation_basis NOT IN ('NORMAL_SALARY','INTEGRAL_SALARY','GROSS_PAYROLL','TAXABLE_INCOME','FIXED_AMOUNT') THEN
        p_resultado := -1;
        p_mensaje   := 'Base de cÃ¡lculo no vÃ¡lida.';
        RETURN;
    END IF;

    IF p_filing_frequency NOT IN ('MONTHLY','QUARTERLY','ANNUAL','REALTIME') THEN
        p_resultado := -1;
        p_mensaje   := 'Frecuencia de presentaciÃ³n no vÃ¡lida.';
        RETURN;
    END IF;

    BEGIN
        IF p_legal_obligation_id IS NULL OR p_legal_obligation_id = 0 THEN
            -- Verificar duplicado
            IF EXISTS (
                SELECT 1 FROM hr."LegalObligation"
                WHERE "CountryCode" = p_country_code
                  AND "Code" = p_code
                  AND "EffectiveFrom" = p_effective_from
            ) THEN
                p_resultado := -2;
                p_mensaje   := 'Ya existe una obligaciÃ³n con ese cÃ³digo y fecha de vigencia para el paÃ­s indicado.';
                RETURN;
            END IF;

            INSERT INTO hr."LegalObligation" (
                "CountryCode", "Code", "Name", "InstitutionName", "ObligationType",
                "CalculationBasis", "SalaryCap", "SalaryCapUnit", "EmployerRate", "EmployeeRate",
                "RateVariableByRisk", "FilingFrequency", "FilingDeadlineRule",
                "EffectiveFrom", "EffectiveTo", "IsActive", "Notes",
                "CreatedAt", "UpdatedAt"
            )
            VALUES (
                p_country_code, p_code, p_name, p_institution_name, p_obligation_type,
                p_calculation_basis, p_salary_cap, p_salary_cap_unit, p_employer_rate, p_employee_rate,
                p_rate_variable_by_risk, p_filing_frequency, p_filing_deadline_rule,
                p_effective_from, p_effective_to, p_is_active, p_notes,
                (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
            )
            RETURNING "LegalObligationId" INTO p_resultado;

            p_mensaje := 'ObligaciÃ³n legal creada exitosamente.';

        ELSE
            IF NOT EXISTS (SELECT 1 FROM hr."LegalObligation" WHERE "LegalObligationId" = p_legal_obligation_id) THEN
                p_resultado := -3;
                p_mensaje   := 'No se encontrÃ³ la obligaciÃ³n legal con el ID indicado.';
                RETURN;
            END IF;

            -- Verificar duplicado excluyendo el registro actual
            IF EXISTS (
                SELECT 1 FROM hr."LegalObligation"
                WHERE "CountryCode" = p_country_code
                  AND "Code" = p_code
                  AND "EffectiveFrom" = p_effective_from
                  AND "LegalObligationId" <> p_legal_obligation_id
            ) THEN
                p_resultado := -2;
                p_mensaje   := 'Ya existe otra obligaciÃ³n con ese cÃ³digo y fecha de vigencia para el paÃ­s indicado.';
                RETURN;
            END IF;

            UPDATE hr."LegalObligation" SET
                "CountryCode"           = p_country_code,
                "Code"                  = p_code,
                "Name"                  = p_name,
                "InstitutionName"       = p_institution_name,
                "ObligationType"        = p_obligation_type,
                "CalculationBasis"      = p_calculation_basis,
                "SalaryCap"             = p_salary_cap,
                "SalaryCapUnit"         = p_salary_cap_unit,
                "EmployerRate"          = p_employer_rate,
                "EmployeeRate"          = p_employee_rate,
                "RateVariableByRisk"    = p_rate_variable_by_risk,
                "FilingFrequency"       = p_filing_frequency,
                "FilingDeadlineRule"    = p_filing_deadline_rule,
                "EffectiveFrom"         = p_effective_from,
                "EffectiveTo"           = p_effective_to,
                "IsActive"              = p_is_active,
                "Notes"                 = p_notes,
                "UpdatedAt"             = (NOW() AT TIME ZONE 'UTC')
            WHERE "LegalObligationId" = p_legal_obligation_id;

            p_resultado := p_legal_obligation_id;
            p_mensaje   := 'ObligaciÃ³n legal actualizada exitosamente.';
        END IF;

    EXCEPTION WHEN OTHERS THEN
        p_resultado := -99;
        p_mensaje   := SQLERRM;
    END;
END;
$$;

-- =============================================================================
-- 3. usp_HR_Obligation_GetByCountry
-- =============================================================================
DROP FUNCTION IF EXISTS public.usp_HR_Obligation_GetByCountry(CHAR(2), DATE) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_HR_Obligation_GetByCountry(
    p_country_code  CHAR(2),
    p_as_of_date    DATE DEFAULT NULL
)
RETURNS TABLE (
    "LegalObligationId"     INTEGER,
    "CountryCode"           CHAR(2),
    "Code"                  VARCHAR(30),
    "Name"                  VARCHAR(200),
    "InstitutionName"       VARCHAR(200),
    "ObligationType"        VARCHAR(20),
    "CalculationBasis"      VARCHAR(30),
    "SalaryCap"             NUMERIC(18,2),
    "SalaryCapUnit"         VARCHAR(20),
    "EmployerRate"          NUMERIC(8,5),
    "EmployeeRate"          NUMERIC(8,5),
    "RateVariableByRisk"    BOOLEAN,
    "FilingFrequency"       VARCHAR(15),
    "FilingDeadlineRule"    VARCHAR(200),
    "EffectiveFrom"         DATE,
    "EffectiveTo"           DATE,
    "Notes"                 VARCHAR(500)
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_as_of_date IS NULL THEN
        p_as_of_date := CAST((NOW() AT TIME ZONE 'UTC') AS DATE);
    END IF;

    RETURN QUERY
    SELECT
        o."LegalObligationId",
        o."CountryCode",
        o."Code",
        o."Name",
        o."InstitutionName",
        o."ObligationType",
        o."CalculationBasis",
        o."SalaryCap",
        o."SalaryCapUnit",
        o."EmployerRate",
        o."EmployeeRate",
        o."RateVariableByRisk",
        o."FilingFrequency",
        o."FilingDeadlineRule",
        o."EffectiveFrom",
        o."EffectiveTo",
        o."Notes"
    FROM hr."LegalObligation" o
    WHERE o."CountryCode" = p_country_code
      AND o."IsActive" = TRUE
      AND o."EffectiveFrom" <= p_as_of_date
      AND (o."EffectiveTo" IS NULL OR o."EffectiveTo" >= p_as_of_date)
    ORDER BY o."Code";
END;
$$;

-- =============================================================================
-- 4. usp_HR_EmployeeObligation_Enroll
-- =============================================================================
DROP FUNCTION IF EXISTS public.usp_HR_EmployeeObligation_Enroll(BIGINT, INTEGER, VARCHAR(50), VARCHAR(50), INTEGER, DATE, NUMERIC(8,5), INTEGER, VARCHAR(500)) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_HR_EmployeeObligation_Enroll(
    p_employee_id           BIGINT,
    p_legal_obligation_id   INTEGER,
    p_affiliation_number    VARCHAR(50)     DEFAULT NULL,
    p_institution_code      VARCHAR(50)     DEFAULT NULL,
    p_risk_level_id         INTEGER         DEFAULT NULL,
    p_enrollment_date       DATE            DEFAULT NULL,
    p_custom_rate           NUMERIC(8,5)    DEFAULT NULL,
    OUT p_resultado         INTEGER,
    OUT p_mensaje           VARCHAR(500)
)
LANGUAGE plpgsql
AS $$
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    IF NOT EXISTS (
        SELECT 1 FROM hr."LegalObligation"
        WHERE "LegalObligationId" = p_legal_obligation_id AND "IsActive" = TRUE
    ) THEN
        p_resultado := -1;
        p_mensaje   := 'La obligaciÃ³n legal no existe o no estÃ¡ activa.';
        RETURN;
    END IF;

    IF EXISTS (
        SELECT 1 FROM hr."EmployeeObligation"
        WHERE "EmployeeId"          = p_employee_id
          AND "LegalObligationId"   = p_legal_obligation_id
          AND "Status"              = 'ACTIVE'
    ) THEN
        p_resultado := -2;
        p_mensaje   := 'El empleado ya tiene una inscripciÃ³n activa en esta obligaciÃ³n.';
        RETURN;
    END IF;

    IF p_risk_level_id IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM hr."ObligationRiskLevel"
        WHERE "ObligationRiskLevelId" = p_risk_level_id
          AND "LegalObligationId"     = p_legal_obligation_id
    ) THEN
        p_resultado := -3;
        p_mensaje   := 'El nivel de riesgo indicado no corresponde a esta obligaciÃ³n.';
        RETURN;
    END IF;

    BEGIN
        INSERT INTO hr."EmployeeObligation" (
            "EmployeeId", "LegalObligationId", "AffiliationNumber", "InstitutionCode",
            "RiskLevelId", "EnrollmentDate", "Status", "CustomRate", "CreatedAt", "UpdatedAt"
        )
        VALUES (
            p_employee_id, p_legal_obligation_id, p_affiliation_number, p_institution_code,
            p_risk_level_id, p_enrollment_date, 'ACTIVE', p_custom_rate,
            (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
        )
        RETURNING "EmployeeObligationId" INTO p_resultado;

        p_mensaje := 'Empleado inscrito exitosamente en la obligaciÃ³n.';

    EXCEPTION WHEN OTHERS THEN
        p_resultado := -99;
        p_mensaje   := SQLERRM;
    END;
END;
$$;

-- =============================================================================
-- 5. usp_HR_EmployeeObligation_Disenroll
-- =============================================================================
DROP FUNCTION IF EXISTS public.usp_HR_EmployeeObligation_Disenroll(INTEGER, DATE, INTEGER, VARCHAR(500)) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_HR_EmployeeObligation_Disenroll(
    p_employee_obligation_id    INTEGER,
    p_disenrollment_date        DATE,
    OUT p_resultado             INTEGER,
    OUT p_mensaje               VARCHAR(500)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_current_status    VARCHAR(15);
    v_enroll_date       DATE;
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    SELECT "Status", "EnrollmentDate"
    INTO v_current_status, v_enroll_date
    FROM hr."EmployeeObligation"
    WHERE "EmployeeObligationId" = p_employee_obligation_id;

    IF v_current_status IS NULL THEN
        p_resultado := -1;
        p_mensaje   := 'No se encontrÃ³ la inscripciÃ³n indicada.';
        RETURN;
    END IF;

    IF v_current_status <> 'ACTIVE' THEN
        p_resultado := -2;
        p_mensaje   := 'La inscripciÃ³n no estÃ¡ activa. Estado actual: ' || v_current_status;
        RETURN;
    END IF;

    IF p_disenrollment_date < v_enroll_date THEN
        p_resultado := -3;
        p_mensaje   := 'La fecha de retiro no puede ser anterior a la fecha de inscripciÃ³n.';
        RETURN;
    END IF;

    BEGIN
        UPDATE hr."EmployeeObligation" SET
            "DisenrollmentDate" = p_disenrollment_date,
            "Status"            = 'TERMINATED',
            "UpdatedAt"         = (NOW() AT TIME ZONE 'UTC')
        WHERE "EmployeeObligationId" = p_employee_obligation_id;

        p_resultado := p_employee_obligation_id;
        p_mensaje   := 'Empleado desinscrito exitosamente.';

    EXCEPTION WHEN OTHERS THEN
        p_resultado := -99;
        p_mensaje   := SQLERRM;
    END;
END;
$$;

-- =============================================================================
-- 6. usp_HR_EmployeeObligation_GetByEmployee
-- =============================================================================
DROP FUNCTION IF EXISTS public.usp_HR_EmployeeObligation_GetByEmployee(BIGINT, VARCHAR(15)) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_HR_EmployeeObligation_GetByEmployee(
    p_employee_id       BIGINT,
    p_status_filter     VARCHAR(15)     DEFAULT NULL
)
RETURNS TABLE(
    p_total_count               BIGINT,
    "EmployeeObligationId"      INTEGER,
    "EmployeeId"                BIGINT,
    "LegalObligationId"         INTEGER,
    "CountryCode"               CHAR(2),
    "Code"                      VARCHAR(30),
    "ObligationName"            VARCHAR(200),
    "InstitutionName"           VARCHAR(200),
    "ObligationType"            VARCHAR(20),
    "CalculationBasis"          VARCHAR(30),
    "AffiliationNumber"         VARCHAR(50),
    "InstitutionCode"           VARCHAR(50),
    "RiskLevelId"               INTEGER,
    "RiskLevel"                 SMALLINT,
    "RiskDescription"           VARCHAR(100),
    "EnrollmentDate"            DATE,
    "DisenrollmentDate"         DATE,
    "Status"                    VARCHAR(15),
    "CustomRate"                NUMERIC(8,5),
    "EffectiveEmployerRate"     NUMERIC(8,5),
    "EffectiveEmployeeRate"     NUMERIC(8,5)
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        COUNT(*) OVER()                                                         AS p_total_count,
        eo."EmployeeObligationId",
        eo."EmployeeId",
        eo."LegalObligationId",
        lo."CountryCode",
        lo."Code",
        lo."Name"                               AS "ObligationName",
        lo."InstitutionName",
        lo."ObligationType",
        lo."CalculationBasis",
        eo."AffiliationNumber",
        eo."InstitutionCode",
        eo."RiskLevelId",
        rl."RiskLevel",
        rl."RiskDescription",
        eo."EnrollmentDate",
        eo."DisenrollmentDate",
        eo."Status",
        eo."CustomRate",
        COALESCE(eo."CustomRate", rl."EmployerRate", lo."EmployerRate")         AS "EffectiveEmployerRate",
        COALESCE(
            CASE WHEN eo."CustomRate" IS NOT NULL THEN lo."EmployeeRate" ELSE NULL END,
            rl."EmployeeRate",
            lo."EmployeeRate"
        )                                                                       AS "EffectiveEmployeeRate"
    FROM hr."EmployeeObligation" eo
    INNER JOIN hr."LegalObligation" lo ON lo."LegalObligationId" = eo."LegalObligationId"
    LEFT JOIN  hr."ObligationRiskLevel" rl ON rl."ObligationRiskLevelId" = eo."RiskLevelId"
    WHERE eo."EmployeeId" = p_employee_id
      AND (p_status_filter IS NULL OR eo."Status" = p_status_filter)
    ORDER BY lo."CountryCode", lo."Code";
END;
$$;

-- =============================================================================
-- 7. usp_HR_Filing_Generate
-- =============================================================================
DROP FUNCTION IF EXISTS public.usp_HR_Filing_Generate(INTEGER, INTEGER, DATE, DATE, DATE, INTEGER, VARCHAR(500)) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_HR_Filing_Generate(
    p_company_id            INTEGER,
    p_legal_obligation_id   INTEGER,
    p_filing_period_start   DATE,
    p_filing_period_end     DATE,
    p_due_date              DATE,
    OUT p_resultado         INTEGER,
    OUT p_mensaje           VARCHAR(500)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_base_employer_rate    NUMERIC(8,5);
    v_base_employee_rate    NUMERIC(8,5);
    v_cap                   NUMERIC(18,2);
    v_filing_id             INTEGER;
    v_tot_employer          NUMERIC(18,2);
    v_tot_employee          NUMERIC(18,2);
    v_emp_count             INTEGER;
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    IF NOT EXISTS (
        SELECT 1 FROM hr."LegalObligation"
        WHERE "LegalObligationId" = p_legal_obligation_id AND "IsActive" = TRUE
    ) THEN
        p_resultado := -1;
        p_mensaje   := 'La obligaciÃ³n legal no existe o no estÃ¡ activa.';
        RETURN;
    END IF;

    IF EXISTS (
        SELECT 1 FROM hr."ObligationFiling"
        WHERE "CompanyId"           = p_company_id
          AND "LegalObligationId"   = p_legal_obligation_id
          AND "FilingPeriodStart"   = p_filing_period_start
          AND "FilingPeriodEnd"     = p_filing_period_end
          AND "Status"             <> 'REJECTED'
    ) THEN
        p_resultado := -2;
        p_mensaje   := 'Ya existe una declaraciÃ³n para este perÃ­odo y obligaciÃ³n.';
        RETURN;
    END IF;

    IF p_filing_period_end < p_filing_period_start THEN
        p_resultado := -3;
        p_mensaje   := 'La fecha fin del perÃ­odo no puede ser anterior a la fecha inicio.';
        RETURN;
    END IF;

    BEGIN
        SELECT "EmployerRate", "EmployeeRate", "SalaryCap"
        INTO v_base_employer_rate, v_base_employee_rate, v_cap
        FROM hr."LegalObligation"
        WHERE "LegalObligationId" = p_legal_obligation_id;

        INSERT INTO hr."ObligationFiling" (
            "CompanyId", "LegalObligationId",
            "FilingPeriodStart", "FilingPeriodEnd",
            "DueDate", "Status", "CreatedAt", "UpdatedAt"
        )
        VALUES (
            p_company_id, p_legal_obligation_id,
            p_filing_period_start, p_filing_period_end,
            p_due_date, 'PENDING',
            (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
        )
        RETURNING "ObligationFilingId" INTO v_filing_id;

        INSERT INTO hr."ObligationFilingDetail" (
            "ObligationFilingId", "EmployeeId", "BaseSalary",
            "EmployerAmount", "EmployeeAmount", "DaysWorked", "NoveltyType"
        )
        SELECT
            v_filing_id,
            eo."EmployeeId",
            COALESCE((
                SELECT prl."Amount"
                FROM hr."PayrollRun" pr
                INNER JOIN hr."PayrollRunLine" prl ON prl."PayrollRunId" = pr."PayrollRunId"
                WHERE pr."EmployeeId" = e."EmployeeId" AND prl."ConceptCode" = 'SALARIO_BASE'
                ORDER BY pr."CreatedAt" DESC
                LIMIT 1
            ), 0) AS "BaseSalary",
            ROUND(
                CASE
                    WHEN v_cap IS NOT NULL
                     AND COALESCE((
                            SELECT prl."Amount"
                            FROM hr."PayrollRun" pr
                            INNER JOIN hr."PayrollRunLine" prl ON prl."PayrollRunId" = pr."PayrollRunId"
                            WHERE pr."EmployeeId" = e."EmployeeId" AND prl."ConceptCode" = 'SALARIO_BASE'
                            ORDER BY pr."CreatedAt" DESC LIMIT 1
                         ), 0) > v_cap
                    THEN v_cap
                    ELSE COALESCE((
                            SELECT prl."Amount"
                            FROM hr."PayrollRun" pr
                            INNER JOIN hr."PayrollRunLine" prl ON prl."PayrollRunId" = pr."PayrollRunId"
                            WHERE pr."EmployeeId" = e."EmployeeId" AND prl."ConceptCode" = 'SALARIO_BASE'
                            ORDER BY pr."CreatedAt" DESC LIMIT 1
                         ), 0)
                END
                * COALESCE(eo."CustomRate", rl."EmployerRate", v_base_employer_rate) / 100.0,
            2) AS "EmployerAmount",
            ROUND(
                CASE
                    WHEN v_cap IS NOT NULL
                     AND COALESCE((
                            SELECT prl."Amount"
                            FROM hr."PayrollRun" pr
                            INNER JOIN hr."PayrollRunLine" prl ON prl."PayrollRunId" = pr."PayrollRunId"
                            WHERE pr."EmployeeId" = e."EmployeeId" AND prl."ConceptCode" = 'SALARIO_BASE'
                            ORDER BY pr."CreatedAt" DESC LIMIT 1
                         ), 0) > v_cap
                    THEN v_cap
                    ELSE COALESCE((
                            SELECT prl."Amount"
                            FROM hr."PayrollRun" pr
                            INNER JOIN hr."PayrollRunLine" prl ON prl."PayrollRunId" = pr."PayrollRunId"
                            WHERE pr."EmployeeId" = e."EmployeeId" AND prl."ConceptCode" = 'SALARIO_BASE'
                            ORDER BY pr."CreatedAt" DESC LIMIT 1
                         ), 0)
                END
                * COALESCE(rl."EmployeeRate", v_base_employee_rate) / 100.0,
            2) AS "EmployeeAmount",
            30 AS "DaysWorked",
            CASE
                WHEN eo."EnrollmentDate"     BETWEEN p_filing_period_start AND p_filing_period_end THEN 'ENROLLMENT'
                WHEN eo."DisenrollmentDate"  BETWEEN p_filing_period_start AND p_filing_period_end THEN 'WITHDRAWAL'
                ELSE 'NONE'
            END AS "NoveltyType"
        FROM hr."EmployeeObligation" eo
        INNER JOIN master."Employee" e ON e."EmployeeId" = eo."EmployeeId"
        LEFT JOIN  hr."ObligationRiskLevel" rl ON rl."ObligationRiskLevelId" = eo."RiskLevelId"
        WHERE eo."LegalObligationId" = p_legal_obligation_id
          AND eo."Status" IN ('ACTIVE','SUSPENDED')
          AND eo."EnrollmentDate" <= p_filing_period_end
          AND (eo."DisenrollmentDate" IS NULL OR eo."DisenrollmentDate" >= p_filing_period_start);

        SELECT
            COALESCE(SUM("EmployerAmount"), 0),
            COALESCE(SUM("EmployeeAmount"), 0),
            COUNT(*)
        INTO v_tot_employer, v_tot_employee, v_emp_count
        FROM hr."ObligationFilingDetail"
        WHERE "ObligationFilingId" = v_filing_id;

        UPDATE hr."ObligationFiling" SET
            "TotalEmployerAmount"   = v_tot_employer,
            "TotalEmployeeAmount"   = v_tot_employee,
            "TotalAmount"           = v_tot_employer + v_tot_employee,
            "EmployeeCount"         = v_emp_count,
            "UpdatedAt"             = (NOW() AT TIME ZONE 'UTC')
        WHERE "ObligationFilingId" = v_filing_id;

        p_resultado := v_filing_id;
        p_mensaje   := 'DeclaraciÃ³n generada exitosamente con ' || v_emp_count::TEXT || ' empleado(s).';

    EXCEPTION WHEN OTHERS THEN
        p_resultado := -99;
        p_mensaje   := SQLERRM;
    END;
END;
$$;

-- =============================================================================
-- 8. usp_HR_Filing_GetSummary
-- =============================================================================
DROP FUNCTION IF EXISTS public.usp_HR_Filing_GetSummary(INTEGER) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_HR_Filing_GetSummary(
    p_filing_id INTEGER
)
RETURNS TABLE (
    result_type     TEXT,
    row_data        JSONB
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Cabecera
    RETURN QUERY
    SELECT
        'HEADER'::TEXT,
        jsonb_build_object(
            'ObligationFilingId',   f."ObligationFilingId",
            'CompanyId',            f."CompanyId",
            'LegalObligationId',    f."LegalObligationId",
            'CountryCode',          lo."CountryCode",
            'ObligationCode',       lo."Code",
            'ObligationName',       lo."Name",
            'InstitutionName',      lo."InstitutionName",
            'ObligationType',       lo."ObligationType",
            'CalculationBasis',     lo."CalculationBasis",
            'BaseEmployerRate',     lo."EmployerRate",
            'BaseEmployeeRate',     lo."EmployeeRate",
            'FilingPeriodStart',    f."FilingPeriodStart",
            'FilingPeriodEnd',      f."FilingPeriodEnd",
            'DueDate',              f."DueDate",
            'FiledDate',            f."FiledDate",
            'ConfirmationNumber',   f."ConfirmationNumber",
            'TotalEmployerAmount',  f."TotalEmployerAmount",
            'TotalEmployeeAmount',  f."TotalEmployeeAmount",
            'TotalAmount',          f."TotalAmount",
            'EmployeeCount',        f."EmployeeCount",
            'Status',               f."Status",
            'FiledByUserId',        f."FiledByUserId",
            'DocumentUrl',          f."DocumentUrl",
            'Notes',                f."Notes",
            'CreatedAt',            f."CreatedAt",
            'UpdatedAt',            f."UpdatedAt"
        )
    FROM hr."ObligationFiling" f
    INNER JOIN hr."LegalObligation" lo ON lo."LegalObligationId" = f."LegalObligationId"
    WHERE f."ObligationFilingId" = p_filing_id;

    -- Detalle
    RETURN QUERY
    SELECT
        'DETAIL'::TEXT,
        jsonb_build_object(
            'DetailId',             d."DetailId",
            'ObligationFilingId',   d."ObligationFilingId",
            'EmployeeId',           d."EmployeeId",
            'EmployeeCode',         e."EmployeeCode",
            'EmployeeName',         e."EmployeeName",
            'BaseSalary',           d."BaseSalary",
            'EmployerAmount',       d."EmployerAmount",
            'EmployeeAmount',       d."EmployeeAmount",
            'TotalAmount',          d."EmployerAmount" + d."EmployeeAmount",
            'DaysWorked',           d."DaysWorked",
            'NoveltyType',          d."NoveltyType"
        )
    FROM hr."ObligationFilingDetail" d
    INNER JOIN master."Employee" e ON e."EmployeeId" = d."EmployeeId"
    WHERE d."ObligationFilingId" = p_filing_id
    ORDER BY e."EmployeeName";
END;
$$;

-- =============================================================================
-- 9. usp_HR_Filing_MarkFiled
-- =============================================================================
DROP FUNCTION IF EXISTS public.usp_HR_Filing_MarkFiled(INTEGER, DATE, VARCHAR(100), INTEGER, VARCHAR(500), VARCHAR(500), INTEGER, VARCHAR(500)) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_HR_Filing_MarkFiled(
    p_obligation_filing_id  INTEGER,
    p_filed_date            DATE            DEFAULT NULL,
    p_confirmation_number   VARCHAR(100)    DEFAULT NULL,
    p_filed_by_user_id      INTEGER         DEFAULT NULL,
    p_document_url          VARCHAR(500)    DEFAULT NULL,
    p_notes                 VARCHAR(500)    DEFAULT NULL,
    OUT p_resultado         INTEGER,
    OUT p_mensaje           VARCHAR(500)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_current_status VARCHAR(15);
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    SELECT "Status"
    INTO v_current_status
    FROM hr."ObligationFiling"
    WHERE "ObligationFilingId" = p_obligation_filing_id;

    IF v_current_status IS NULL THEN
        p_resultado := -1;
        p_mensaje   := 'No se encontrÃ³ la declaraciÃ³n indicada.';
        RETURN;
    END IF;

    IF v_current_status NOT IN ('PENDING','LATE','REJECTED') THEN
        p_resultado := -2;
        p_mensaje   := 'Solo se pueden marcar como presentadas las declaraciones en estado PENDING, LATE o REJECTED. Estado actual: ' || v_current_status;
        RETURN;
    END IF;

    IF p_filed_date IS NULL THEN
        p_filed_date := CAST((NOW() AT TIME ZONE 'UTC') AS DATE);
    END IF;

    BEGIN
        UPDATE hr."ObligationFiling" SET
            "Status"                = 'FILED',
            "FiledDate"             = p_filed_date,
            "ConfirmationNumber"    = p_confirmation_number,
            "FiledByUserId"         = p_filed_by_user_id,
            "DocumentUrl"           = p_document_url,
            "Notes"                 = COALESCE(p_notes, "Notes"),
            "UpdatedAt"             = (NOW() AT TIME ZONE 'UTC')
        WHERE "ObligationFilingId" = p_obligation_filing_id;

        p_resultado := p_obligation_filing_id;
        p_mensaje   := 'DeclaraciÃ³n marcada como presentada exitosamente.';

    EXCEPTION WHEN OTHERS THEN
        p_resultado := -99;
        p_mensaje   := SQLERRM;
    END;
END;
$$;

-- =============================================================================
-- 10. usp_HR_Filing_List
-- =============================================================================
-- usp_HR_Filing_List: service sends (p_company_id, p_obligation_id, p_status, p_offset, p_limit)
-- Function accepts those exact param names and inlines the query.
DROP FUNCTION IF EXISTS public.usp_HR_Filing_List(INTEGER, INTEGER, CHAR, VARCHAR, DATE, DATE, INTEGER, INTEGER) CASCADE;
DROP FUNCTION IF EXISTS public.usp_HR_Filing_List(INTEGER, INTEGER, VARCHAR, INTEGER, INTEGER) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_HR_Filing_List(
    p_company_id    INTEGER,
    p_obligation_id INTEGER     DEFAULT NULL,
    p_status        VARCHAR     DEFAULT NULL,
    p_offset        INTEGER     DEFAULT 0,
    p_limit         INTEGER     DEFAULT 50
)
RETURNS TABLE(
    p_total_count           BIGINT,
    "ObligationFilingId"    INTEGER,
    "CompanyId"             INTEGER,
    "LegalObligationId"     INTEGER,
    "CountryCode"           CHAR(2),
    "ObligationCode"        VARCHAR(30),
    "ObligationName"        VARCHAR(200),
    "InstitutionName"       VARCHAR(200),
    "FilingPeriodStart"     DATE,
    "FilingPeriodEnd"       DATE,
    "DueDate"               DATE,
    "FiledDate"             DATE,
    "ConfirmationNumber"    VARCHAR(100),
    "TotalEmployerAmount"   NUMERIC(18,2),
    "TotalEmployeeAmount"   NUMERIC(18,2),
    "TotalAmount"           NUMERIC(18,2),
    "EmployeeCount"         INTEGER,
    "Status"                VARCHAR(15),
    "CreatedAt"             TIMESTAMP
)
LANGUAGE plpgsql AS $$
BEGIN
    IF p_limit < 1   THEN p_limit := 50;  END IF;
    IF p_limit > 500 THEN p_limit := 500; END IF;

    RETURN QUERY
    SELECT
        COUNT(*) OVER()         AS p_total_count,
        f."ObligationFilingId",
        f."CompanyId",
        f."LegalObligationId",
        lo."CountryCode",
        lo."Code"               AS "ObligationCode",
        lo."Name"               AS "ObligationName",
        lo."InstitutionName",
        f."FilingPeriodStart",
        f."FilingPeriodEnd",
        f."DueDate",
        f."FiledDate",
        f."ConfirmationNumber",
        f."TotalEmployerAmount",
        f."TotalEmployeeAmount",
        f."TotalAmount",
        f."EmployeeCount",
        f."Status",
        f."CreatedAt"
    FROM hr."ObligationFiling" f
    INNER JOIN hr."LegalObligation" lo ON lo."LegalObligationId" = f."LegalObligationId"
    WHERE (p_company_id    IS NULL OR f."CompanyId"         = p_company_id)
      AND (p_obligation_id IS NULL OR f."LegalObligationId" = p_obligation_id)
      AND (p_status        IS NULL OR f."Status"            = p_status)
    ORDER BY f."FilingPeriodStart" DESC, lo."Code"
    LIMIT p_limit OFFSET p_offset;
END;
$$;

-- =============================================================================
-- Seed data - Obligaciones legales Venezuela (VE)
-- =============================================================================

-- VE_SSO: Seguro Social Obligatorio / IVSS
INSERT INTO hr."LegalObligation" (
    "CountryCode", "Code", "Name", "InstitutionName", "ObligationType",
    "CalculationBasis", "SalaryCap", "SalaryCapUnit", "EmployerRate", "EmployeeRate",
    "RateVariableByRisk", "FilingFrequency", "FilingDeadlineRule",
    "EffectiveFrom", "IsActive", "Notes", "CreatedAt", "UpdatedAt"
)
SELECT
    'VE', 'VE_SSO', 'Seguro Social Obligatorio', 'IVSS', 'CONTRIBUTION',
    'NORMAL_SALARY', 5, 'MIN_WAGES', 9.00000, 4.00000,
    TRUE, 'MONTHLY', 'Primeros 5 dÃ­as hÃ¡biles del mes siguiente',
    '2000-01-01', TRUE, 'Tasa base clase I. Consultar tabla de riesgo para clases II-IV.',
    (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
WHERE NOT EXISTS (SELECT 1 FROM hr."LegalObligation" WHERE "CountryCode" = 'VE' AND "Code" = 'VE_SSO');

-- VE_FAOV: Fondo de Ahorro Obligatorio para la Vivienda / BANAVIH
INSERT INTO hr."LegalObligation" (
    "CountryCode", "Code", "Name", "InstitutionName", "ObligationType",
    "CalculationBasis", "EmployerRate", "EmployeeRate",
    "RateVariableByRisk", "FilingFrequency", "FilingDeadlineRule",
    "EffectiveFrom", "IsActive", "Notes", "CreatedAt", "UpdatedAt"
)
SELECT
    'VE', 'VE_FAOV', 'Fondo de Ahorro Obligatorio para la Vivienda', 'BANAVIH', 'CONTRIBUTION',
    'INTEGRAL_SALARY', 2.00000, 1.00000,
    FALSE, 'MONTHLY', 'Primeros 5 dÃ­as hÃ¡biles del mes siguiente',
    '2000-01-01', TRUE, 'Base: salario integral (salario + alÃ­cuota utilidades + alÃ­cuota vacaciones).',
    (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
WHERE NOT EXISTS (SELECT 1 FROM hr."LegalObligation" WHERE "CountryCode" = 'VE' AND "Code" = 'VE_FAOV');

-- VE_LRPE: RÃ©gimen Prestacional de Empleo (Paro Forzoso)
INSERT INTO hr."LegalObligation" (
    "CountryCode", "Code", "Name", "InstitutionName", "ObligationType",
    "CalculationBasis", "EmployerRate", "EmployeeRate",
    "RateVariableByRisk", "FilingFrequency", "FilingDeadlineRule",
    "EffectiveFrom", "IsActive", "Notes", "CreatedAt", "UpdatedAt"
)
SELECT
    'VE', 'VE_LRPE', 'Regimen Prestacional de Empleo (Paro Forzoso)', 'IVSS', 'CONTRIBUTION',
    'NORMAL_SALARY', 2.00000, 0.50000,
    FALSE, 'MONTHLY', 'Primeros 5 dÃ­as hÃ¡biles del mes siguiente',
    '2000-01-01', TRUE, 'Paro forzoso - Ley del RÃ©gimen Prestacional de Empleo.',
    (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
WHERE NOT EXISTS (SELECT 1 FROM hr."LegalObligation" WHERE "CountryCode" = 'VE' AND "Code" = 'VE_LRPE');

-- VE_INCE: Instituto Nacional de CapacitaciÃ³n y EducaciÃ³n Socialista
INSERT INTO hr."LegalObligation" (
    "CountryCode", "Code", "Name", "InstitutionName", "ObligationType",
    "CalculationBasis", "EmployerRate", "EmployeeRate",
    "RateVariableByRisk", "FilingFrequency", "FilingDeadlineRule",
    "EffectiveFrom", "IsActive", "Notes", "CreatedAt", "UpdatedAt"
)
SELECT
    'VE', 'VE_INCE', 'INCE - Aporte Patronal', 'INCE', 'CONTRIBUTION',
    'GROSS_PAYROLL', 2.00000, 0.00000,
    FALSE, 'QUARTERLY', 'Dentro de los 5 dÃ­as hÃ¡biles despuÃ©s del cierre del trimestre',
    '2000-01-01', TRUE, 'Empleado aporta 0.5% sobre utilidades (manejado por separado en nÃ³mina).',
    (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
WHERE NOT EXISTS (SELECT 1 FROM hr."LegalObligation" WHERE "CountryCode" = 'VE' AND "Code" = 'VE_INCE');

-- VE_SSO niveles de riesgo (clases I a IV)
DO $$
DECLARE
    v_sso_id INTEGER;
BEGIN
    SELECT "LegalObligationId" INTO v_sso_id
    FROM hr."LegalObligation"
    WHERE "CountryCode" = 'VE' AND "Code" = 'VE_SSO';

    IF v_sso_id IS NOT NULL THEN
        INSERT INTO hr."ObligationRiskLevel" ("LegalObligationId", "RiskLevel", "RiskDescription", "EmployerRate", "EmployeeRate")
        SELECT v_sso_id, 1, 'Riesgo mÃ­nimo',  9.00000, 4.00000
        WHERE NOT EXISTS (SELECT 1 FROM hr."ObligationRiskLevel" WHERE "LegalObligationId" = v_sso_id AND "RiskLevel" = 1);

        INSERT INTO hr."ObligationRiskLevel" ("LegalObligationId", "RiskLevel", "RiskDescription", "EmployerRate", "EmployeeRate")
        SELECT v_sso_id, 2, 'Riesgo medio',  10.00000, 4.00000
        WHERE NOT EXISTS (SELECT 1 FROM hr."ObligationRiskLevel" WHERE "LegalObligationId" = v_sso_id AND "RiskLevel" = 2);

        INSERT INTO hr."ObligationRiskLevel" ("LegalObligationId", "RiskLevel", "RiskDescription", "EmployerRate", "EmployeeRate")
        SELECT v_sso_id, 3, 'Riesgo alto',   11.00000, 4.00000
        WHERE NOT EXISTS (SELECT 1 FROM hr."ObligationRiskLevel" WHERE "LegalObligationId" = v_sso_id AND "RiskLevel" = 3);

        INSERT INTO hr."ObligationRiskLevel" ("LegalObligationId", "RiskLevel", "RiskDescription", "EmployerRate", "EmployeeRate")
        SELECT v_sso_id, 4, 'Riesgo mÃ¡ximo', 12.00000, 4.00000
        WHERE NOT EXISTS (SELECT 1 FROM hr."ObligationRiskLevel" WHERE "LegalObligationId" = v_sso_id AND "RiskLevel" = 4);
    END IF;
END;
$$;


-- RRHH Functions: Salud Ocupacional

-- =============================================================================
-- sp_rrhh_salud_ocupacional.sql  (PostgreSQL / PL/pgSQL)
-- Convertido desde T-SQL: web/api/sqlweb/includes/sp/sp_rrhh_salud_ocupacional.sql
-- Fecha conversiÃ³n: 2026-03-16
--
-- Salud Ocupacional / Occupational Health
-- Cubre: INPSASEL (VE), OSHA (US), PRL (ES), SG-SST (CO)
-- Tablas: hr.OccupationalHealth, hr.MedicalExam, hr.MedicalOrder,
--         hr.TrainingRecord, hr.SafetyCommittee, hr.SafetyCommitteeMember,
--         hr.SafetyCommitteeMeeting
--
-- Funciones (19 en total):
--   1.  usp_HR_OccHealth_Create                   - Crear registro de salud ocupacional
--   2.  usp_HR_OccHealth_Update                   - Actualizar registro
--   3.  usp_HR_OccHealth_List                     - Listado paginado
--   4.  usp_HR_OccHealth_Get                      - Obtener por ID
--   5.  usp_HR_MedExam_Save                       - Crear/actualizar examen mÃ©dico
--   6.  usp_HR_MedExam_List                       - Listado paginado
--   7.  usp_HR_MedExam_GetPending                 - ExÃ¡menes vencidos/por vencer
--   8.  usp_HR_MedOrder_Create                    - Crear orden mÃ©dica
--   9.  usp_HR_MedOrder_Approve                   - Aprobar/rechazar orden
--   10. usp_HR_MedOrder_List                      - Listado paginado
--   11. usp_HR_Training_Save                      - Crear/actualizar capacitaciÃ³n
--   12. usp_HR_Training_List                      - Listado paginado
--   13. usp_HR_Training_GetEmployeeCertifications - Certificaciones de empleado
--   14. usp_HR_Committee_Save                     - Crear/actualizar comitÃ©
--   15. usp_HR_Committee_AddMember                - Agregar miembro
--   16. usp_HR_Committee_RemoveMember             - Remover miembro
--   17. usp_HR_Committee_RecordMeeting            - Registrar reuniÃ³n
--   18. usp_HR_Committee_List                     - Listado paginado de comitÃ©s
--   19. usp_HR_Committee_GetMeetings              - Reuniones paginadas de un comitÃ©
-- =============================================================================

-- =============================================================================
-- 1. usp_HR_OccHealth_Create
-- =============================================================================
DROP FUNCTION IF EXISTS public.usp_HR_OccHealth_Create(INTEGER, CHAR(2), VARCHAR(25), BIGINT, VARCHAR(24), VARCHAR(200), TIMESTAMP, TIMESTAMP, TIMESTAMP, VARCHAR(15), VARCHAR(100), INTEGER, VARCHAR(200), TEXT, VARCHAR(500), VARCHAR(500), DATE, VARCHAR(100), VARCHAR(500), VARCHAR(500), INTEGER, INTEGER, VARCHAR(500)) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_HR_OccHealth_Create(
    p_company_id                INTEGER,
    p_country_code              CHAR(2),
    p_record_type               VARCHAR(25),
    p_employee_id               BIGINT          DEFAULT NULL,
    p_employee_code             VARCHAR(24)     DEFAULT NULL,
    p_employee_name             VARCHAR(200)    DEFAULT NULL,
    p_occurrence_date           TIMESTAMP       DEFAULT NULL,
    p_report_deadline           TIMESTAMP       DEFAULT NULL,
    p_reported_date             TIMESTAMP       DEFAULT NULL,
    p_severity                  VARCHAR(15)     DEFAULT NULL,
    p_body_part_affected        VARCHAR(100)    DEFAULT NULL,
    p_days_lost                 INTEGER         DEFAULT NULL,
    p_location                  VARCHAR(200)    DEFAULT NULL,
    p_description               TEXT            DEFAULT NULL,
    p_root_cause                VARCHAR(500)    DEFAULT NULL,
    p_corrective_action         VARCHAR(500)    DEFAULT NULL,
    p_investigation_due_date    DATE            DEFAULT NULL,
    p_institution_reference     VARCHAR(100)    DEFAULT NULL,
    p_document_url              VARCHAR(500)    DEFAULT NULL,
    p_notes                     VARCHAR(500)    DEFAULT NULL,
    p_created_by                INTEGER         DEFAULT NULL,
    OUT p_resultado             INTEGER,
    OUT p_mensaje               VARCHAR(500)
)
LANGUAGE plpgsql
AS $$
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    IF p_record_type NOT IN ('ACCIDENT','DISEASE','NEAR_MISS','INSPECTION','RISK_NOTIFICATION') THEN
        p_resultado := -1;
        p_mensaje   := 'Tipo de registro no vÃ¡lido.';
        RETURN;
    END IF;

    IF p_severity IS NOT NULL AND p_severity NOT IN ('MINOR','MODERATE','SEVERE','FATAL') THEN
        p_resultado := -1;
        p_mensaje   := 'Severidad no vÃ¡lida.';
        RETURN;
    END IF;

    BEGIN
        INSERT INTO hr."OccupationalHealth" (
            "CompanyId", "CountryCode", "RecordType",
            "EmployeeId", "EmployeeCode", "EmployeeName",
            "OccurrenceDate", "ReportDeadline", "ReportedDate",
            "Severity", "BodyPartAffected", "DaysLost",
            "Location", "Description", "RootCause", "CorrectiveAction",
            "InvestigationDueDate", "InstitutionReference",
            "Status", "DocumentUrl", "Notes", "CreatedBy",
            "CreatedAt", "UpdatedAt"
        )
        VALUES (
            p_company_id, p_country_code, p_record_type,
            p_employee_id, p_employee_code, p_employee_name,
            p_occurrence_date, p_report_deadline, p_reported_date,
            p_severity, p_body_part_affected, p_days_lost,
            p_location, p_description, p_root_cause, p_corrective_action,
            p_investigation_due_date, p_institution_reference,
            'OPEN', p_document_url, p_notes, p_created_by,
            (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
        )
        RETURNING "OccupationalHealthId" INTO p_resultado;

        p_mensaje := 'Registro de salud ocupacional creado exitosamente.';

    EXCEPTION WHEN OTHERS THEN
        p_resultado := -1;
        p_mensaje   := SQLERRM;
    END;
END;
$$;

-- =============================================================================
-- 2. usp_HR_OccHealth_Update
-- =============================================================================
DROP FUNCTION IF EXISTS public.usp_HR_OccHealth_Update(INTEGER, INTEGER, TIMESTAMP, VARCHAR(15), VARCHAR(100), INTEGER, VARCHAR(200), TEXT, VARCHAR(500), VARCHAR(500), DATE, DATE, VARCHAR(100), VARCHAR(15), VARCHAR(500), VARCHAR(500), INTEGER, VARCHAR(500)) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_HR_OccHealth_Update(
    p_occupational_health_id        INTEGER,
    p_company_id                    INTEGER,
    p_reported_date                 TIMESTAMP       DEFAULT NULL,
    p_severity                      VARCHAR(15)     DEFAULT NULL,
    p_body_part_affected            VARCHAR(100)    DEFAULT NULL,
    p_days_lost                     INTEGER         DEFAULT NULL,
    p_location                      VARCHAR(200)    DEFAULT NULL,
    p_description                   TEXT            DEFAULT NULL,
    p_root_cause                    VARCHAR(500)    DEFAULT NULL,
    p_corrective_action             VARCHAR(500)    DEFAULT NULL,
    p_investigation_due_date        DATE            DEFAULT NULL,
    p_investigation_completed_date  DATE            DEFAULT NULL,
    p_institution_reference         VARCHAR(100)    DEFAULT NULL,
    p_status                        VARCHAR(15)     DEFAULT NULL,
    p_document_url                  VARCHAR(500)    DEFAULT NULL,
    p_notes                         VARCHAR(500)    DEFAULT NULL,
    OUT p_resultado                 INTEGER,
    OUT p_mensaje                   VARCHAR(500)
)
LANGUAGE plpgsql
AS $$
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    IF NOT EXISTS (
        SELECT 1 FROM hr."OccupationalHealth"
        WHERE "OccupationalHealthId" = p_occupational_health_id AND "CompanyId" = p_company_id
    ) THEN
        p_resultado := -1;
        p_mensaje   := 'Registro no encontrado.';
        RETURN;
    END IF;

    IF p_status IS NOT NULL AND p_status NOT IN ('OPEN','REPORTED','INVESTIGATING','CLOSED') THEN
        p_resultado := -1;
        p_mensaje   := 'Estado no vÃ¡lido.';
        RETURN;
    END IF;

    IF p_severity IS NOT NULL AND p_severity NOT IN ('MINOR','MODERATE','SEVERE','FATAL') THEN
        p_resultado := -1;
        p_mensaje   := 'Severidad no vÃ¡lida.';
        RETURN;
    END IF;

    BEGIN
        UPDATE hr."OccupationalHealth"
        SET
            "ReportedDate"               = COALESCE(p_reported_date,              "ReportedDate"),
            "Severity"                   = COALESCE(p_severity,                   "Severity"),
            "BodyPartAffected"           = COALESCE(p_body_part_affected,         "BodyPartAffected"),
            "DaysLost"                   = COALESCE(p_days_lost,                  "DaysLost"),
            "Location"                   = COALESCE(p_location,                   "Location"),
            "Description"                = COALESCE(p_description,                "Description"),
            "RootCause"                  = COALESCE(p_root_cause,                 "RootCause"),
            "CorrectiveAction"           = COALESCE(p_corrective_action,          "CorrectiveAction"),
            "InvestigationDueDate"       = COALESCE(p_investigation_due_date,     "InvestigationDueDate"),
            "InvestigationCompletedDate" = COALESCE(p_investigation_completed_date, "InvestigationCompletedDate"),
            "InstitutionReference"       = COALESCE(p_institution_reference,      "InstitutionReference"),
            "Status"                     = COALESCE(p_status,                     "Status"),
            "DocumentUrl"                = COALESCE(p_document_url,               "DocumentUrl"),
            "Notes"                      = COALESCE(p_notes,                      "Notes"),
            "UpdatedAt"                  = (NOW() AT TIME ZONE 'UTC')
        WHERE "OccupationalHealthId" = p_occupational_health_id
          AND "CompanyId" = p_company_id;

        p_resultado := p_occupational_health_id;
        p_mensaje   := 'Registro actualizado exitosamente.';

    EXCEPTION WHEN OTHERS THEN
        p_resultado := -1;
        p_mensaje   := SQLERRM;
    END;
END;
$$;

-- =============================================================================
-- 3. usp_HR_OccHealth_List
-- =============================================================================
DROP FUNCTION IF EXISTS public.usp_HR_OccHealth_List(INTEGER, VARCHAR(25), VARCHAR(15), VARCHAR(24), CHAR(2), DATE, DATE, INTEGER, INTEGER) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_HR_OccHealth_List(
    p_company_id    INTEGER,
    p_record_type   VARCHAR(25)     DEFAULT NULL,
    p_status        VARCHAR(15)     DEFAULT NULL,
    p_employee_code VARCHAR(24)     DEFAULT NULL,
    p_country_code  CHAR(2)         DEFAULT NULL,
    p_from_date     DATE            DEFAULT NULL,
    p_to_date       DATE            DEFAULT NULL,
    p_page          INTEGER         DEFAULT 1,
    p_limit         INTEGER         DEFAULT 50
)
RETURNS TABLE(
    p_total_count                   BIGINT,
    "OccupationalHealthId"          INTEGER,
    "CompanyId"                     INTEGER,
    "CountryCode"                   CHAR(2),
    "RecordType"                    VARCHAR(25),
    "EmployeeId"                    BIGINT,
    "EmployeeCode"                  VARCHAR(24),
    "EmployeeName"                  VARCHAR(200),
    "OccurrenceDate"                TIMESTAMP,
    "ReportDeadline"                TIMESTAMP,
    "ReportedDate"                  TIMESTAMP,
    "Severity"                      VARCHAR(15),
    "BodyPartAffected"              VARCHAR(100),
    "DaysLost"                      INTEGER,
    "Location"                      VARCHAR(200),
    "Description"                   TEXT,
    "RootCause"                     VARCHAR(500),
    "CorrectiveAction"              VARCHAR(500),
    "InvestigationDueDate"          DATE,
    "InvestigationCompletedDate"    DATE,
    "InstitutionReference"          VARCHAR(100),
    "Status"                        VARCHAR(15),
    "DocumentUrl"                   VARCHAR(500),
    "Notes"                         VARCHAR(500),
    "CreatedBy"                     INTEGER,
    "CreatedAt"                     TIMESTAMP,
    "UpdatedAt"                     TIMESTAMP
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_page  < 1   THEN p_page  := 1;   END IF;
    IF p_limit < 1   THEN p_limit := 50;  END IF;
    IF p_limit > 500 THEN p_limit := 500; END IF;

    RETURN QUERY
    SELECT
        COUNT(*) OVER()         AS p_total_count,
        "OccupationalHealthId",
        "CompanyId",
        "CountryCode",
        "RecordType",
        "EmployeeId",
        "EmployeeCode",
        "EmployeeName",
        "OccurrenceDate",
        "ReportDeadline",
        "ReportedDate",
        "Severity",
        "BodyPartAffected",
        "DaysLost",
        "Location",
        "Description",
        "RootCause",
        "CorrectiveAction",
        "InvestigationDueDate",
        "InvestigationCompletedDate",
        "InstitutionReference",
        "Status",
        "DocumentUrl",
        "Notes",
        "CreatedBy",
        "CreatedAt",
        "UpdatedAt"
    FROM hr."OccupationalHealth"
    WHERE "CompanyId" = p_company_id
      AND (p_record_type   IS NULL OR "RecordType"   = p_record_type)
      AND (p_status        IS NULL OR "Status"        = p_status)
      AND (p_employee_code IS NULL OR "EmployeeCode"  = p_employee_code)
      AND (p_country_code  IS NULL OR "CountryCode"   = p_country_code)
      AND (p_from_date     IS NULL OR "OccurrenceDate" >= p_from_date)
      AND (p_to_date       IS NULL OR "OccurrenceDate" <= p_to_date)
    ORDER BY "OccurrenceDate" DESC, "OccupationalHealthId" DESC
    LIMIT p_limit OFFSET (p_page - 1) * p_limit;
END;
$$;

-- =============================================================================
-- 4. usp_HR_OccHealth_Get
-- =============================================================================
DROP FUNCTION IF EXISTS public.usp_HR_OccHealth_Get(INTEGER, INTEGER) CASCADE;
DROP FUNCTION IF EXISTS public.usp_HR_OccHealth_Get(INTEGER) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_HR_OccHealth_Get(
    p_record_id                 INTEGER,
    p_company_id                INTEGER  DEFAULT NULL
)
RETURNS TABLE (
    "OccupationalHealthId"          INTEGER,
    "CompanyId"                     INTEGER,
    "CountryCode"                   VARCHAR,
    "RecordType"                    VARCHAR,
    "EmployeeId"                    BIGINT,
    "EmployeeCode"                  VARCHAR(24),
    "EmployeeName"                  VARCHAR(200),
    "OccurrenceDate"                TIMESTAMP,
    "ReportDeadline"                TIMESTAMP,
    "ReportedDate"                  TIMESTAMP,
    "Severity"                      VARCHAR(15),
    "BodyPartAffected"              VARCHAR(100),
    "DaysLost"                      INTEGER,
    "Location"                      VARCHAR(200),
    "Description"                   TEXT,
    "RootCause"                     VARCHAR(500),
    "CorrectiveAction"              VARCHAR(500),
    "InvestigationDueDate"          DATE,
    "InvestigationCompletedDate"    DATE,
    "InstitutionReference"          VARCHAR(100),
    "Status"                        VARCHAR(15),
    "DocumentUrl"                   VARCHAR(500),
    "Notes"                         VARCHAR(500),
    "CreatedBy"                     INTEGER,
    "CreatedAt"                     TIMESTAMP,
    "UpdatedAt"                     TIMESTAMP
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        o."OccupationalHealthId",
        o."CompanyId",
        o."CountryCode"::VARCHAR,
        o."RecordType"::VARCHAR,
        o."EmployeeId",
        o."EmployeeCode",
        o."EmployeeName",
        o."OccurrenceDate",
        o."ReportDeadline",
        o."ReportedDate",
        o."Severity",
        o."BodyPartAffected",
        o."DaysLost",
        o."Location",
        o."Description",
        o."RootCause",
        o."CorrectiveAction",
        o."InvestigationDueDate",
        o."InvestigationCompletedDate",
        o."InstitutionReference",
        o."Status",
        o."DocumentUrl",
        o."Notes",
        o."CreatedBy",
        o."CreatedAt",
        o."UpdatedAt"
    FROM hr."OccupationalHealth" o
    WHERE o."OccupationalHealthId" = p_record_id
      AND (p_company_id IS NULL OR o."CompanyId" = p_company_id);
END;
$$;

-- =============================================================================
-- 5. usp_HR_MedExam_Save
-- =============================================================================
DROP FUNCTION IF EXISTS public.usp_HR_MedExam_Save(INTEGER, INTEGER, BIGINT, VARCHAR(24), VARCHAR(200), VARCHAR(20), DATE, DATE, VARCHAR(20), VARCHAR(500), VARCHAR(200), VARCHAR(200), VARCHAR(500), VARCHAR(500), INTEGER, VARCHAR(500)) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_HR_MedExam_Save(
    p_medical_exam_id   INTEGER         DEFAULT NULL,
    p_company_id        INTEGER         DEFAULT NULL,
    p_employee_id       BIGINT          DEFAULT NULL,
    p_employee_code     VARCHAR(24)     DEFAULT NULL,
    p_employee_name     VARCHAR(200)    DEFAULT NULL,
    p_exam_type         VARCHAR(20)     DEFAULT NULL,
    p_exam_date         DATE            DEFAULT NULL,
    p_next_due_date     DATE            DEFAULT NULL,
    p_result            VARCHAR(20)     DEFAULT 'PENDING',
    p_restrictions      VARCHAR(500)    DEFAULT NULL,
    p_physician_name    VARCHAR(200)    DEFAULT NULL,
    p_clinic_name       VARCHAR(200)    DEFAULT NULL,
    p_document_url      VARCHAR(500)    DEFAULT NULL,
    p_notes             VARCHAR(500)    DEFAULT NULL,
    OUT p_resultado     INTEGER,
    OUT p_mensaje       VARCHAR(500)
)
LANGUAGE plpgsql
AS $$
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    IF p_exam_type NOT IN ('PRE_EMPLOYMENT','PERIODIC','POST_VACATION','EXIT','SPECIAL') THEN
        p_resultado := -1;
        p_mensaje   := 'Tipo de examen no vÃ¡lido.';
        RETURN;
    END IF;

    IF p_result NOT IN ('FIT','FIT_WITH_RESTRICTIONS','UNFIT','PENDING') THEN
        p_resultado := -1;
        p_mensaje   := 'Resultado de examen no vÃ¡lido.';
        RETURN;
    END IF;

    BEGIN
        IF p_medical_exam_id IS NULL THEN
            INSERT INTO hr."MedicalExam" (
                "CompanyId", "EmployeeId", "EmployeeCode", "EmployeeName",
                "ExamType", "ExamDate", "NextDueDate", "Result",
                "Restrictions", "PhysicianName", "ClinicName",
                "DocumentUrl", "Notes", "CreatedAt", "UpdatedAt"
            )
            VALUES (
                p_company_id, p_employee_id, p_employee_code, p_employee_name,
                p_exam_type, p_exam_date, p_next_due_date, p_result,
                p_restrictions, p_physician_name, p_clinic_name,
                p_document_url, p_notes,
                (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
            )
            RETURNING "MedicalExamId" INTO p_resultado;

            p_mensaje := 'Examen mÃ©dico creado exitosamente.';
        ELSE
            IF NOT EXISTS (
                SELECT 1 FROM hr."MedicalExam"
                WHERE "MedicalExamId" = p_medical_exam_id AND "CompanyId" = p_company_id
            ) THEN
                p_resultado := -1;
                p_mensaje   := 'Examen mÃ©dico no encontrado.';
                RETURN;
            END IF;

            UPDATE hr."MedicalExam"
            SET
                "EmployeeId"    = COALESCE(p_employee_id, "EmployeeId"),
                "EmployeeCode"  = p_employee_code,
                "EmployeeName"  = p_employee_name,
                "ExamType"      = p_exam_type,
                "ExamDate"      = p_exam_date,
                "NextDueDate"   = p_next_due_date,
                "Result"        = p_result,
                "Restrictions"  = p_restrictions,
                "PhysicianName" = p_physician_name,
                "ClinicName"    = p_clinic_name,
                "DocumentUrl"   = p_document_url,
                "Notes"         = p_notes,
                "UpdatedAt"     = (NOW() AT TIME ZONE 'UTC')
            WHERE "MedicalExamId" = p_medical_exam_id
              AND "CompanyId" = p_company_id;

            p_resultado := p_medical_exam_id;
            p_mensaje   := 'Examen mÃ©dico actualizado exitosamente.';
        END IF;

    EXCEPTION WHEN OTHERS THEN
        p_resultado := -1;
        p_mensaje   := SQLERRM;
    END;
END;
$$;

-- =============================================================================
-- 6. usp_HR_MedExam_List
-- =============================================================================
DROP FUNCTION IF EXISTS public.usp_HR_MedExam_List(INTEGER, VARCHAR(20), VARCHAR(20), VARCHAR(24), DATE, DATE, INTEGER, INTEGER) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_HR_MedExam_List(
    p_company_id    INTEGER,
    p_exam_type     VARCHAR(20)     DEFAULT NULL,
    p_result        VARCHAR(20)     DEFAULT NULL,
    p_employee_code VARCHAR(24)     DEFAULT NULL,
    p_from_date     DATE            DEFAULT NULL,
    p_to_date       DATE            DEFAULT NULL,
    p_page          INTEGER         DEFAULT 1,
    p_limit         INTEGER         DEFAULT 50
)
RETURNS TABLE(
    p_total_count       BIGINT,
    "MedicalExamId"     INTEGER,
    "CompanyId"         INTEGER,
    "EmployeeId"        BIGINT,
    "EmployeeCode"      VARCHAR(24),
    "EmployeeName"      VARCHAR(200),
    "ExamType"          VARCHAR(20),
    "ExamDate"          DATE,
    "NextDueDate"       DATE,
    "Result"            VARCHAR(20),
    "Restrictions"      VARCHAR(500),
    "PhysicianName"     VARCHAR(200),
    "ClinicName"        VARCHAR(200),
    "DocumentUrl"       VARCHAR(500),
    "Notes"             VARCHAR(500),
    "CreatedAt"         TIMESTAMP,
    "UpdatedAt"         TIMESTAMP
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_page  < 1   THEN p_page  := 1;   END IF;
    IF p_limit < 1   THEN p_limit := 50;  END IF;
    IF p_limit > 500 THEN p_limit := 500; END IF;

    RETURN QUERY
    SELECT
        COUNT(*) OVER()         AS p_total_count,
        "MedicalExamId",
        "CompanyId",
        "EmployeeId",
        "EmployeeCode",
        "EmployeeName",
        "ExamType",
        "ExamDate",
        "NextDueDate",
        "Result",
        "Restrictions",
        "PhysicianName",
        "ClinicName",
        "DocumentUrl",
        "Notes",
        "CreatedAt",
        "UpdatedAt"
    FROM hr."MedicalExam"
    WHERE "CompanyId" = p_company_id
      AND (p_exam_type     IS NULL OR "ExamType"     = p_exam_type)
      AND (p_result        IS NULL OR "Result"        = p_result)
      AND (p_employee_code IS NULL OR "EmployeeCode"  = p_employee_code)
      AND (p_from_date     IS NULL OR "ExamDate"     >= p_from_date)
      AND (p_to_date       IS NULL OR "ExamDate"     <= p_to_date)
    ORDER BY "ExamDate" DESC, "MedicalExamId" DESC
    LIMIT p_limit OFFSET (p_page - 1) * p_limit;
END;
$$;

-- =============================================================================
-- 7. usp_HR_MedExam_GetPending
-- =============================================================================
DROP FUNCTION IF EXISTS public.usp_HR_MedExam_GetPending(INTEGER, DATE, INTEGER, INTEGER, INTEGER) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_HR_MedExam_GetPending(
    p_company_id    INTEGER,
    p_as_of_date    DATE        DEFAULT NULL,
    p_days_ahead    INTEGER     DEFAULT 30,
    p_page          INTEGER     DEFAULT 1,
    p_limit         INTEGER     DEFAULT 50
)
RETURNS TABLE(
    p_total_count       BIGINT,
    "MedicalExamId"     INTEGER,
    "CompanyId"         INTEGER,
    "EmployeeId"        BIGINT,
    "EmployeeCode"      VARCHAR(24),
    "EmployeeName"      VARCHAR(200),
    "ExamType"          VARCHAR(20),
    "ExamDate"          DATE,
    "NextDueDate"       DATE,
    "Result"            VARCHAR(20),
    "Restrictions"      VARCHAR(500),
    "PhysicianName"     VARCHAR(200),
    "ClinicName"        VARCHAR(200),
    "IsOverdue"         BOOLEAN,
    "DaysUntilDue"      INTEGER
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_as_of_date IS NULL THEN p_as_of_date := CAST((NOW() AT TIME ZONE 'UTC') AS DATE); END IF;
    IF p_page  < 1   THEN p_page  := 1;   END IF;
    IF p_limit < 1   THEN p_limit := 50;  END IF;
    IF p_limit > 500 THEN p_limit := 500; END IF;

    RETURN QUERY
    WITH "LatestExam" AS (
        SELECT me."MedicalExamId", me."CompanyId", me."EmployeeId",
               me."EmployeeCode", me."EmployeeName", me."ExamType",
               me."ExamDate", me."NextDueDate", me."Result",
               me."Restrictions", me."PhysicianName", me."ClinicName",
               ROW_NUMBER() OVER (PARTITION BY me."EmployeeCode" ORDER BY me."ExamDate" DESC) AS rn
        FROM hr."MedicalExam" me
        WHERE me."CompanyId"  = p_company_id
          AND me."ExamType"   = 'PERIODIC'
          AND me."NextDueDate" IS NOT NULL
          AND me."NextDueDate" <= p_as_of_date + p_days_ahead
    )
    SELECT
        COUNT(*) OVER()                                     AS p_total_count,
        le."MedicalExamId",
        le."CompanyId",
        le."EmployeeId",
        le."EmployeeCode",
        le."EmployeeName",
        le."ExamType",
        le."ExamDate",
        le."NextDueDate",
        le."Result",
        le."Restrictions",
        le."PhysicianName",
        le."ClinicName",
        (le."NextDueDate" < p_as_of_date)                  AS "IsOverdue",
        (le."NextDueDate" - p_as_of_date)::INTEGER         AS "DaysUntilDue"
    FROM "LatestExam" le
    WHERE le.rn = 1
    ORDER BY le."NextDueDate" ASC
    LIMIT p_limit OFFSET (p_page - 1) * p_limit;
END;
$$;

-- =============================================================================
-- 8. usp_HR_MedOrder_Create
-- =============================================================================
DROP FUNCTION IF EXISTS public.usp_HR_MedOrder_Create(INTEGER, BIGINT, VARCHAR(24), VARCHAR(200), VARCHAR(20), DATE, VARCHAR(500), VARCHAR(200), TEXT, NUMERIC(18,2), VARCHAR(500), VARCHAR(500), INTEGER, VARCHAR(500)) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_HR_MedOrder_Create(
    p_company_id    INTEGER,
    p_employee_id   BIGINT          DEFAULT NULL,
    p_employee_code VARCHAR(24)     DEFAULT NULL,
    p_employee_name VARCHAR(200)    DEFAULT NULL,
    p_order_type    VARCHAR(20)     DEFAULT NULL,
    p_order_date    DATE            DEFAULT NULL,
    p_diagnosis     VARCHAR(500)    DEFAULT NULL,
    p_physician_name VARCHAR(200)   DEFAULT NULL,
    p_prescriptions TEXT            DEFAULT NULL,
    p_estimated_cost NUMERIC(18,2)  DEFAULT NULL,
    p_document_url  VARCHAR(500)    DEFAULT NULL,
    p_notes         VARCHAR(500)    DEFAULT NULL,
    OUT p_resultado INTEGER,
    OUT p_mensaje   VARCHAR(500)
)
LANGUAGE plpgsql
AS $$
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    IF p_order_type NOT IN ('MEDICAL','PHARMACY','LAB','REFERRAL') THEN
        p_resultado := -1;
        p_mensaje   := 'Tipo de orden no vÃ¡lido.';
        RETURN;
    END IF;

    BEGIN
        INSERT INTO hr."MedicalOrder" (
            "CompanyId", "EmployeeId", "EmployeeCode", "EmployeeName",
            "OrderType", "OrderDate", "Diagnosis", "PhysicianName",
            "Prescriptions", "EstimatedCost", "Status",
            "DocumentUrl", "Notes", "CreatedAt", "UpdatedAt"
        )
        VALUES (
            p_company_id, p_employee_id, p_employee_code, p_employee_name,
            p_order_type, p_order_date, p_diagnosis, p_physician_name,
            p_prescriptions, p_estimated_cost, 'PENDIENTE',
            p_document_url, p_notes,
            (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
        )
        RETURNING "MedicalOrderId" INTO p_resultado;

        p_mensaje := 'Orden mÃ©dica creada exitosamente.';

    EXCEPTION WHEN OTHERS THEN
        p_resultado := -1;
        p_mensaje   := SQLERRM;
    END;
END;
$$;

-- =============================================================================
-- 9. usp_HR_MedOrder_Approve
-- =============================================================================
DROP FUNCTION IF EXISTS public.usp_HR_MedOrder_Approve(INTEGER, INTEGER, VARCHAR(15), NUMERIC(18,2), INTEGER, VARCHAR(500), INTEGER, VARCHAR(500)) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_HR_MedOrder_Approve(
    p_medical_order_id  INTEGER,
    p_company_id        INTEGER,
    p_action            VARCHAR(15),
    p_approved_amount   NUMERIC(18,2)   DEFAULT NULL,
    p_approved_by       INTEGER         DEFAULT NULL,
    p_notes             VARCHAR(500)    DEFAULT NULL,
    OUT p_resultado     INTEGER,
    OUT p_mensaje       VARCHAR(500)
)
LANGUAGE plpgsql
AS $$
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    IF p_action NOT IN ('APROBADA','RECHAZADA') THEN
        p_resultado := -1;
        p_mensaje   := 'AcciÃ³n no vÃ¡lida. Use APROBADA o RECHAZADA.';
        RETURN;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM hr."MedicalOrder"
        WHERE "MedicalOrderId" = p_medical_order_id AND "CompanyId" = p_company_id
    ) THEN
        p_resultado := -1;
        p_mensaje   := 'Orden mÃ©dica no encontrada.';
        RETURN;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM hr."MedicalOrder"
        WHERE "MedicalOrderId" = p_medical_order_id AND "CompanyId" = p_company_id
          AND "Status" = 'PENDIENTE'
    ) THEN
        p_resultado := -1;
        p_mensaje   := 'La orden no estÃ¡ en estado PENDIENTE.';
        RETURN;
    END IF;

    BEGIN
        UPDATE hr."MedicalOrder"
        SET
            "Status"         = p_action,
            "ApprovedAmount" = CASE WHEN p_action = 'APROBADA'
                                    THEN COALESCE(p_approved_amount, "EstimatedCost")
                                    ELSE NULL END,
            "ApprovedBy"     = p_approved_by,
            "ApprovedAt"     = (NOW() AT TIME ZONE 'UTC'),
            "Notes"          = COALESCE(p_notes, "Notes"),
            "UpdatedAt"      = (NOW() AT TIME ZONE 'UTC')
        WHERE "MedicalOrderId" = p_medical_order_id
          AND "CompanyId" = p_company_id;

        p_resultado := p_medical_order_id;
        p_mensaje   := CASE WHEN p_action = 'APROBADA'
                            THEN 'Orden mÃ©dica aprobada exitosamente.'
                            ELSE 'Orden mÃ©dica rechazada.' END;

    EXCEPTION WHEN OTHERS THEN
        p_resultado := -1;
        p_mensaje   := SQLERRM;
    END;
END;
$$;

-- =============================================================================
-- 10. usp_HR_MedOrder_List
-- =============================================================================
DROP FUNCTION IF EXISTS public.usp_HR_MedOrder_List(INTEGER, VARCHAR(20), VARCHAR(15), VARCHAR(24), DATE, DATE, INTEGER, INTEGER) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_HR_MedOrder_List(
    p_company_id    INTEGER,
    p_order_type    VARCHAR(20)     DEFAULT NULL,
    p_status        VARCHAR(15)     DEFAULT NULL,
    p_employee_code VARCHAR(24)     DEFAULT NULL,
    p_from_date     DATE            DEFAULT NULL,
    p_to_date       DATE            DEFAULT NULL,
    p_page          INTEGER         DEFAULT 1,
    p_limit         INTEGER         DEFAULT 50
)
RETURNS TABLE(
    p_total_count       BIGINT,
    "MedicalOrderId"    INTEGER,
    "CompanyId"         INTEGER,
    "EmployeeId"        BIGINT,
    "EmployeeCode"      VARCHAR(24),
    "EmployeeName"      VARCHAR(200),
    "OrderType"         VARCHAR(20),
    "OrderDate"         DATE,
    "Diagnosis"         VARCHAR(500),
    "PhysicianName"     VARCHAR(200),
    "Prescriptions"     TEXT,
    "EstimatedCost"     NUMERIC(18,2),
    "ApprovedAmount"    NUMERIC(18,2),
    "Status"            VARCHAR(15),
    "ApprovedBy"        INTEGER,
    "ApprovedAt"        TIMESTAMP,
    "DocumentUrl"       VARCHAR(500),
    "Notes"             VARCHAR(500),
    "CreatedAt"         TIMESTAMP,
    "UpdatedAt"         TIMESTAMP
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_page  < 1   THEN p_page  := 1;   END IF;
    IF p_limit < 1   THEN p_limit := 50;  END IF;
    IF p_limit > 500 THEN p_limit := 500; END IF;

    RETURN QUERY
    SELECT
        COUNT(*) OVER()         AS p_total_count,
        "MedicalOrderId",
        "CompanyId",
        "EmployeeId",
        "EmployeeCode",
        "EmployeeName",
        "OrderType",
        "OrderDate",
        "Diagnosis",
        "PhysicianName",
        "Prescriptions",
        "EstimatedCost",
        "ApprovedAmount",
        "Status",
        "ApprovedBy",
        "ApprovedAt",
        "DocumentUrl",
        "Notes",
        "CreatedAt",
        "UpdatedAt"
    FROM hr."MedicalOrder"
    WHERE "CompanyId" = p_company_id
      AND (p_order_type    IS NULL OR "OrderType"    = p_order_type)
      AND (p_status        IS NULL OR "Status"        = p_status)
      AND (p_employee_code IS NULL OR "EmployeeCode"  = p_employee_code)
      AND (p_from_date     IS NULL OR "OrderDate"    >= p_from_date)
      AND (p_to_date       IS NULL OR "OrderDate"    <= p_to_date)
    ORDER BY "OrderDate" DESC, "MedicalOrderId" DESC
    LIMIT p_limit OFFSET (p_page - 1) * p_limit;
END;
$$;

-- =============================================================================
-- 11. usp_HR_Training_Save
-- =============================================================================
DROP FUNCTION IF EXISTS public.usp_HR_Training_Save(INTEGER, INTEGER, CHAR(2), VARCHAR(25), VARCHAR(200), VARCHAR(200), DATE, DATE, NUMERIC(6,2), BIGINT, VARCHAR(24), VARCHAR(200), VARCHAR(100), VARCHAR(500), VARCHAR(15), BOOLEAN, VARCHAR(500), INTEGER, VARCHAR(500)) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_HR_Training_Save(
    p_training_record_id    INTEGER         DEFAULT NULL,
    p_company_id            INTEGER         DEFAULT NULL,
    p_country_code          CHAR(2)         DEFAULT NULL,
    p_training_type         VARCHAR(25)     DEFAULT NULL,
    p_title                 VARCHAR(200)    DEFAULT NULL,
    p_provider              VARCHAR(200)    DEFAULT NULL,
    p_start_date            DATE            DEFAULT NULL,
    p_end_date              DATE            DEFAULT NULL,
    p_duration_hours        NUMERIC(6,2)    DEFAULT NULL,
    p_employee_id           BIGINT          DEFAULT NULL,
    p_employee_code         VARCHAR(24)     DEFAULT NULL,
    p_employee_name         VARCHAR(200)    DEFAULT NULL,
    p_certificate_number    VARCHAR(100)    DEFAULT NULL,
    p_certificate_url       VARCHAR(500)    DEFAULT NULL,
    p_result                VARCHAR(15)     DEFAULT NULL,
    p_is_regulatory         BOOLEAN         DEFAULT FALSE,
    p_notes                 VARCHAR(500)    DEFAULT NULL,
    OUT p_resultado         INTEGER,
    OUT p_mensaje           VARCHAR(500)
)
LANGUAGE plpgsql
AS $$
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    IF p_training_type NOT IN ('SAFETY','REGULATORY','TECHNICAL','APPRENTICESHIP','INDUCTION') THEN
        p_resultado := -1;
        p_mensaje   := 'Tipo de capacitaciÃ³n no vÃ¡lido.';
        RETURN;
    END IF;

    IF p_result IS NOT NULL AND p_result NOT IN ('PASSED','FAILED','IN_PROGRESS','ATTENDED') THEN
        p_resultado := -1;
        p_mensaje   := 'Resultado no vÃ¡lido.';
        RETURN;
    END IF;

    IF p_duration_hours <= 0 THEN
        p_resultado := -1;
        p_mensaje   := 'La duraciÃ³n en horas debe ser mayor a cero.';
        RETURN;
    END IF;

    BEGIN
        IF p_training_record_id IS NULL THEN
            INSERT INTO hr."TrainingRecord" (
                "CompanyId", "CountryCode", "TrainingType", "Title", "Provider",
                "StartDate", "EndDate", "DurationHours",
                "EmployeeId", "EmployeeCode", "EmployeeName",
                "CertificateNumber", "CertificateUrl", "Result",
                "IsRegulatory", "Notes", "CreatedAt", "UpdatedAt"
            )
            VALUES (
                p_company_id, p_country_code, p_training_type, p_title, p_provider,
                p_start_date, p_end_date, p_duration_hours,
                p_employee_id, p_employee_code, p_employee_name,
                p_certificate_number, p_certificate_url, p_result,
                p_is_regulatory, p_notes,
                (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
            )
            RETURNING "TrainingRecordId" INTO p_resultado;

            p_mensaje := 'Registro de capacitaciÃ³n creado exitosamente.';
        ELSE
            IF NOT EXISTS (
                SELECT 1 FROM hr."TrainingRecord"
                WHERE "TrainingRecordId" = p_training_record_id AND "CompanyId" = p_company_id
            ) THEN
                p_resultado := -1;
                p_mensaje   := 'Registro de capacitaciÃ³n no encontrado.';
                RETURN;
            END IF;

            UPDATE hr."TrainingRecord"
            SET
                "CountryCode"       = p_country_code,
                "TrainingType"      = p_training_type,
                "Title"             = p_title,
                "Provider"          = p_provider,
                "StartDate"         = p_start_date,
                "EndDate"           = p_end_date,
                "DurationHours"     = p_duration_hours,
                "EmployeeId"        = COALESCE(p_employee_id, "EmployeeId"),
                "EmployeeCode"      = p_employee_code,
                "EmployeeName"      = p_employee_name,
                "CertificateNumber" = p_certificate_number,
                "CertificateUrl"    = p_certificate_url,
                "Result"            = p_result,
                "IsRegulatory"      = p_is_regulatory,
                "Notes"             = p_notes,
                "UpdatedAt"         = (NOW() AT TIME ZONE 'UTC')
            WHERE "TrainingRecordId" = p_training_record_id
              AND "CompanyId" = p_company_id;

            p_resultado := p_training_record_id;
            p_mensaje   := 'Registro de capacitaciÃ³n actualizado exitosamente.';
        END IF;

    EXCEPTION WHEN OTHERS THEN
        p_resultado := -1;
        p_mensaje   := SQLERRM;
    END;
END;
$$;

-- =============================================================================
-- 12. usp_HR_Training_List
-- =============================================================================
DROP FUNCTION IF EXISTS public.usp_HR_Training_List(INTEGER, VARCHAR(25), VARCHAR(24), CHAR(2), BOOLEAN, VARCHAR(15), DATE, DATE, INTEGER, INTEGER) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_HR_Training_List(
    p_company_id    INTEGER,
    p_training_type VARCHAR(25)     DEFAULT NULL,
    p_employee_code VARCHAR(24)     DEFAULT NULL,
    p_country_code  CHAR(2)         DEFAULT NULL,
    p_is_regulatory BOOLEAN         DEFAULT NULL,
    p_result        VARCHAR(15)     DEFAULT NULL,
    p_from_date     DATE            DEFAULT NULL,
    p_to_date       DATE            DEFAULT NULL,
    p_page          INTEGER         DEFAULT 1,
    p_limit         INTEGER         DEFAULT 50
)
RETURNS TABLE(
    p_total_count           BIGINT,
    "TrainingRecordId"      INTEGER,
    "CompanyId"             INTEGER,
    "CountryCode"           CHAR(2),
    "TrainingType"          VARCHAR(25),
    "Title"                 VARCHAR(200),
    "Provider"              VARCHAR(200),
    "StartDate"             DATE,
    "EndDate"               DATE,
    "DurationHours"         NUMERIC(6,2),
    "EmployeeId"            BIGINT,
    "EmployeeCode"          VARCHAR(24),
    "EmployeeName"          VARCHAR(200),
    "CertificateNumber"     VARCHAR(100),
    "CertificateUrl"        VARCHAR(500),
    "Result"                VARCHAR(15),
    "IsRegulatory"          BOOLEAN,
    "Notes"                 VARCHAR(500),
    "CreatedAt"             TIMESTAMP,
    "UpdatedAt"             TIMESTAMP
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_page  < 1   THEN p_page  := 1;   END IF;
    IF p_limit < 1   THEN p_limit := 50;  END IF;
    IF p_limit > 500 THEN p_limit := 500; END IF;

    RETURN QUERY
    SELECT
        COUNT(*) OVER()         AS p_total_count,
        "TrainingRecordId",
        "CompanyId",
        "CountryCode",
        "TrainingType",
        "Title",
        "Provider",
        "StartDate",
        "EndDate",
        "DurationHours",
        "EmployeeId",
        "EmployeeCode",
        "EmployeeName",
        "CertificateNumber",
        "CertificateUrl",
        "Result",
        "IsRegulatory",
        "Notes",
        "CreatedAt",
        "UpdatedAt"
    FROM hr."TrainingRecord"
    WHERE "CompanyId" = p_company_id
      AND (p_training_type IS NULL OR "TrainingType" = p_training_type)
      AND (p_employee_code IS NULL OR "EmployeeCode" = p_employee_code)
      AND (p_country_code  IS NULL OR "CountryCode"  = p_country_code)
      AND (p_is_regulatory IS NULL OR "IsRegulatory" = p_is_regulatory)
      AND (p_result        IS NULL OR "Result"        = p_result)
      AND (p_from_date     IS NULL OR "StartDate"    >= p_from_date)
      AND (p_to_date       IS NULL OR "StartDate"    <= p_to_date)
    ORDER BY "StartDate" DESC, "TrainingRecordId" DESC
    LIMIT p_limit OFFSET (p_page - 1) * p_limit;
END;
$$;

-- =============================================================================
-- 13. usp_HR_Training_GetEmployeeCertifications
-- =============================================================================
DROP FUNCTION IF EXISTS public.usp_HR_Training_GetEmployeeCertifications(INTEGER, VARCHAR(24)) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_HR_Training_GetEmployeeCertifications(
    p_company_id    INTEGER,
    p_employee_code VARCHAR(24)
)
RETURNS TABLE (
    "TrainingRecordId"  INTEGER,
    "CompanyId"         INTEGER,
    "CountryCode"       CHAR(2),
    "TrainingType"      VARCHAR(25),
    "Title"             VARCHAR(200),
    "Provider"          VARCHAR(200),
    "StartDate"         DATE,
    "EndDate"           DATE,
    "DurationHours"     NUMERIC(6,2),
    "EmployeeId"        BIGINT,
    "EmployeeCode"      VARCHAR(24),
    "EmployeeName"      VARCHAR(200),
    "CertificateNumber" VARCHAR(100),
    "CertificateUrl"    VARCHAR(500),
    "Result"            VARCHAR(15),
    "IsRegulatory"      BOOLEAN,
    "Notes"             VARCHAR(500),
    "CreatedAt"         TIMESTAMP,
    "UpdatedAt"         TIMESTAMP
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        t."TrainingRecordId",
        t."CompanyId",
        t."CountryCode",
        t."TrainingType",
        t."Title",
        t."Provider",
        t."StartDate",
        t."EndDate",
        t."DurationHours",
        t."EmployeeId",
        t."EmployeeCode",
        t."EmployeeName",
        t."CertificateNumber",
        t."CertificateUrl",
        t."Result",
        t."IsRegulatory",
        t."Notes",
        t."CreatedAt",
        t."UpdatedAt"
    FROM hr."TrainingRecord" t
    WHERE t."CompanyId"         = p_company_id
      AND t."EmployeeCode"      = p_employee_code
      AND t."Result"            = 'PASSED'
      AND t."CertificateNumber" IS NOT NULL
    ORDER BY t."StartDate" DESC;
END;
$$;

-- =============================================================================
-- 14. usp_HR_Committee_Save
-- =============================================================================
DROP FUNCTION IF EXISTS public.usp_HR_Committee_Save(INTEGER, INTEGER, CHAR(2), VARCHAR(200), DATE, VARCHAR(15), BOOLEAN, INTEGER, VARCHAR(500)) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_HR_Committee_Save(
    p_safety_committee_id   INTEGER         DEFAULT NULL,
    p_company_id            INTEGER         DEFAULT NULL,
    p_country_code          CHAR(2)         DEFAULT NULL,
    p_committee_name        VARCHAR(200)    DEFAULT NULL,
    p_formation_date        DATE            DEFAULT NULL,
    p_meeting_frequency     VARCHAR(15)     DEFAULT 'MONTHLY',
    p_is_active             BOOLEAN         DEFAULT TRUE,
    OUT p_resultado         INTEGER,
    OUT p_mensaje           VARCHAR(500)
)
LANGUAGE plpgsql
AS $$
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    BEGIN
        IF p_safety_committee_id IS NULL THEN
            INSERT INTO hr."SafetyCommittee" (
                "CompanyId", "CountryCode", "CommitteeName",
                "FormationDate", "MeetingFrequency", "IsActive", "CreatedAt"
            )
            VALUES (
                p_company_id, p_country_code, p_committee_name,
                p_formation_date, p_meeting_frequency, p_is_active,
                (NOW() AT TIME ZONE 'UTC')
            )
            RETURNING "SafetyCommitteeId" INTO p_resultado;

            p_mensaje := 'ComitÃ© de seguridad creado exitosamente.';
        ELSE
            IF NOT EXISTS (
                SELECT 1 FROM hr."SafetyCommittee"
                WHERE "SafetyCommitteeId" = p_safety_committee_id AND "CompanyId" = p_company_id
            ) THEN
                p_resultado := -1;
                p_mensaje   := 'ComitÃ© no encontrado.';
                RETURN;
            END IF;

            UPDATE hr."SafetyCommittee"
            SET
                "CountryCode"      = p_country_code,
                "CommitteeName"    = p_committee_name,
                "FormationDate"    = p_formation_date,
                "MeetingFrequency" = p_meeting_frequency,
                "IsActive"         = p_is_active
            WHERE "SafetyCommitteeId" = p_safety_committee_id
              AND "CompanyId" = p_company_id;

            p_resultado := p_safety_committee_id;
            p_mensaje   := 'ComitÃ© de seguridad actualizado exitosamente.';
        END IF;

    EXCEPTION WHEN OTHERS THEN
        p_resultado := -1;
        p_mensaje   := SQLERRM;
    END;
END;
$$;

-- =============================================================================
-- 15. usp_HR_Committee_AddMember
-- =============================================================================
DROP FUNCTION IF EXISTS public.usp_HR_Committee_AddMember(INTEGER, INTEGER, BIGINT, VARCHAR(24), VARCHAR(200), VARCHAR(25), DATE, DATE, INTEGER, VARCHAR(500)) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_HR_Committee_AddMember(
    p_safety_committee_id   INTEGER,
    p_company_id            INTEGER,
    p_employee_id           BIGINT          DEFAULT NULL,
    p_employee_code         VARCHAR(24)     DEFAULT NULL,
    p_employee_name         VARCHAR(200)    DEFAULT NULL,
    p_role                  VARCHAR(25)     DEFAULT NULL,
    p_start_date            DATE            DEFAULT NULL,
    p_end_date              DATE            DEFAULT NULL,
    OUT p_resultado         INTEGER,
    OUT p_mensaje           VARCHAR(500)
)
LANGUAGE plpgsql
AS $$
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    IF p_role NOT IN ('PRESIDENT','SECRETARY','DELEGATE','EMPLOYER_REP') THEN
        p_resultado := -1;
        p_mensaje   := 'Rol no vÃ¡lido.';
        RETURN;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM hr."SafetyCommittee"
        WHERE "SafetyCommitteeId" = p_safety_committee_id AND "CompanyId" = p_company_id
    ) THEN
        p_resultado := -1;
        p_mensaje   := 'ComitÃ© no encontrado.';
        RETURN;
    END IF;

    IF EXISTS (
        SELECT 1 FROM hr."SafetyCommitteeMember"
        WHERE "SafetyCommitteeId" = p_safety_committee_id
          AND "EmployeeCode" = p_employee_code
          AND ("EndDate" IS NULL OR "EndDate" >= p_start_date)
    ) THEN
        p_resultado := -1;
        p_mensaje   := 'El empleado ya es miembro activo de este comitÃ©.';
        RETURN;
    END IF;

    BEGIN
        INSERT INTO hr."SafetyCommitteeMember" (
            "SafetyCommitteeId", "EmployeeId", "EmployeeCode", "EmployeeName",
            "Role", "StartDate", "EndDate"
        )
        VALUES (
            p_safety_committee_id, p_employee_id, p_employee_code, p_employee_name,
            p_role, p_start_date, p_end_date
        )
        RETURNING "MemberId" INTO p_resultado;

        p_mensaje := 'Miembro agregado exitosamente al comitÃ©.';

    EXCEPTION WHEN OTHERS THEN
        p_resultado := -1;
        p_mensaje   := SQLERRM;
    END;
END;
$$;

-- =============================================================================
-- 16. usp_HR_Committee_RemoveMember
-- =============================================================================
DROP FUNCTION IF EXISTS public.usp_HR_Committee_RemoveMember(INTEGER, INTEGER, INTEGER, DATE, INTEGER, VARCHAR(500)) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_HR_Committee_RemoveMember(
    p_member_id             INTEGER,
    p_safety_committee_id   INTEGER,
    p_company_id            INTEGER,
    p_end_date              DATE            DEFAULT NULL,
    OUT p_resultado         INTEGER,
    OUT p_mensaje           VARCHAR(500)
)
LANGUAGE plpgsql
AS $$
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    IF p_end_date IS NULL THEN
        p_end_date := CAST((NOW() AT TIME ZONE 'UTC') AS DATE);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM hr."SafetyCommittee"
        WHERE "SafetyCommitteeId" = p_safety_committee_id AND "CompanyId" = p_company_id
    ) THEN
        p_resultado := -1;
        p_mensaje   := 'ComitÃ© no encontrado.';
        RETURN;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM hr."SafetyCommitteeMember"
        WHERE "MemberId" = p_member_id AND "SafetyCommitteeId" = p_safety_committee_id
    ) THEN
        p_resultado := -1;
        p_mensaje   := 'Miembro no encontrado en este comitÃ©.';
        RETURN;
    END IF;

    BEGIN
        UPDATE hr."SafetyCommitteeMember"
        SET "EndDate" = p_end_date
        WHERE "MemberId" = p_member_id
          AND "SafetyCommitteeId" = p_safety_committee_id;

        p_resultado := p_member_id;
        p_mensaje   := 'Miembro removido del comitÃ© exitosamente.';

    EXCEPTION WHEN OTHERS THEN
        p_resultado := -1;
        p_mensaje   := SQLERRM;
    END;
END;
$$;

-- =============================================================================
-- 17. usp_HR_Committee_RecordMeeting
-- =============================================================================
DROP FUNCTION IF EXISTS public.usp_HR_Committee_RecordMeeting(INTEGER, INTEGER, TIMESTAMP, VARCHAR(500), TEXT, TEXT, INTEGER, VARCHAR(500)) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_HR_Committee_RecordMeeting(
    p_safety_committee_id   INTEGER,
    p_company_id            INTEGER,
    p_meeting_date          TIMESTAMP,
    p_minutes_url           VARCHAR(500)    DEFAULT NULL,
    p_topics_summary        TEXT            DEFAULT NULL,
    p_action_items          TEXT            DEFAULT NULL,
    OUT p_resultado         INTEGER,
    OUT p_mensaje           VARCHAR(500)
)
LANGUAGE plpgsql
AS $$
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    IF NOT EXISTS (
        SELECT 1 FROM hr."SafetyCommittee"
        WHERE "SafetyCommitteeId" = p_safety_committee_id AND "CompanyId" = p_company_id
    ) THEN
        p_resultado := -1;
        p_mensaje   := 'ComitÃ© no encontrado.';
        RETURN;
    END IF;

    BEGIN
        INSERT INTO hr."SafetyCommitteeMeeting" (
            "SafetyCommitteeId", "MeetingDate", "MinutesUrl",
            "TopicsSummary", "ActionItems", "CreatedAt"
        )
        VALUES (
            p_safety_committee_id, p_meeting_date, p_minutes_url,
            p_topics_summary, p_action_items,
            (NOW() AT TIME ZONE 'UTC')
        )
        RETURNING "MeetingId" INTO p_resultado;

        p_mensaje := 'ReuniÃ³n registrada exitosamente.';

    EXCEPTION WHEN OTHERS THEN
        p_resultado := -1;
        p_mensaje   := SQLERRM;
    END;
END;
$$;

-- =============================================================================
-- 18. usp_HR_Committee_List
-- =============================================================================
DROP FUNCTION IF EXISTS public.usp_HR_Committee_List(INTEGER, CHAR(2), BOOLEAN, INTEGER, INTEGER) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_HR_Committee_List(
    p_company_id    INTEGER,
    p_country_code  CHAR(2)     DEFAULT NULL,
    p_is_active     BOOLEAN     DEFAULT NULL,
    p_page          INTEGER     DEFAULT 1,
    p_limit         INTEGER     DEFAULT 50
)
RETURNS TABLE(
    p_total_count           BIGINT,
    "SafetyCommitteeId"     INTEGER,
    "CompanyId"             INTEGER,
    "CountryCode"           CHAR(2),
    "CommitteeName"         VARCHAR(200),
    "FormationDate"         DATE,
    "MeetingFrequency"      VARCHAR(15),
    "IsActive"              BOOLEAN,
    "CreatedAt"             TIMESTAMP,
    "ActiveMemberCount"     BIGINT,
    "TotalMeetings"         BIGINT
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_page  < 1   THEN p_page  := 1;   END IF;
    IF p_limit < 1   THEN p_limit := 50;  END IF;
    IF p_limit > 500 THEN p_limit := 500; END IF;

    RETURN QUERY
    SELECT
        COUNT(*) OVER()         AS p_total_count,
        sc."SafetyCommitteeId",
        sc."CompanyId",
        sc."CountryCode",
        sc."CommitteeName",
        sc."FormationDate",
        sc."MeetingFrequency",
        sc."IsActive",
        sc."CreatedAt",
        (
            SELECT COUNT(*) FROM hr."SafetyCommitteeMember" m
            WHERE m."SafetyCommitteeId" = sc."SafetyCommitteeId"
              AND (m."EndDate" IS NULL OR m."EndDate" >= CAST((NOW() AT TIME ZONE 'UTC') AS DATE))
        )::BIGINT AS "ActiveMemberCount",
        (
            SELECT COUNT(*) FROM hr."SafetyCommitteeMeeting" mt
            WHERE mt."SafetyCommitteeId" = sc."SafetyCommitteeId"
        )::BIGINT AS "TotalMeetings"
    FROM hr."SafetyCommittee" sc
    WHERE sc."CompanyId" = p_company_id
      AND (p_country_code IS NULL OR sc."CountryCode" = p_country_code)
      AND (p_is_active    IS NULL OR sc."IsActive"    = p_is_active)
    ORDER BY sc."IsActive" DESC, sc."FormationDate" DESC
    LIMIT p_limit OFFSET (p_page - 1) * p_limit;
END;
$$;

-- =============================================================================
-- 19. usp_HR_Committee_GetMeetings
-- =============================================================================
DROP FUNCTION IF EXISTS public.usp_HR_Committee_GetMeetings(INTEGER, INTEGER, DATE, DATE, INTEGER, INTEGER) CASCADE;
DROP FUNCTION IF EXISTS public.usp_HR_Committee_GetMeetings(INTEGER) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_HR_Committee_GetMeetings(
    p_committee_id          INTEGER,
    p_company_id            INTEGER     DEFAULT NULL,
    p_from_date             DATE        DEFAULT NULL,
    p_to_date               DATE        DEFAULT NULL,
    p_page                  INTEGER     DEFAULT 1,
    p_limit                 INTEGER     DEFAULT 50
)
RETURNS TABLE(
    p_total_count           BIGINT,
    "MeetingId"             INTEGER,
    "SafetyCommitteeId"     INTEGER,
    "MeetingDate"           TIMESTAMP,
    "MinutesUrl"            VARCHAR(500),
    "TopicsSummary"         TEXT,
    "ActionItems"           TEXT,
    "CreatedAt"             TIMESTAMP,
    "CommitteeName"         VARCHAR(200)
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_page  < 1   THEN p_page  := 1;   END IF;
    IF p_limit < 1   THEN p_limit := 50;  END IF;
    IF p_limit > 500 THEN p_limit := 500; END IF;

    -- Verificar que el comitÃ© pertenece a la empresa
    IF p_company_id IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM hr."SafetyCommittee" c2
        WHERE c2."SafetyCommitteeId" = p_committee_id AND c2."CompanyId" = p_company_id
    ) THEN
        RETURN;
    END IF;

    RETURN QUERY
    SELECT
        COUNT(*) OVER()::BIGINT,
        m."MeetingId",
        m."SafetyCommitteeId",
        m."MeetingDate",
        m."MinutesUrl"::VARCHAR(500),
        m."TopicsSummary",
        m."ActionItems",
        m."CreatedAt"::TIMESTAMP,
        sc."CommitteeName"::VARCHAR(200)
    FROM hr."SafetyCommitteeMeeting" m
    INNER JOIN hr."SafetyCommittee" sc ON sc."SafetyCommitteeId" = m."SafetyCommitteeId"
    WHERE m."SafetyCommitteeId" = p_committee_id
      AND (p_from_date IS NULL OR m."MeetingDate" >= p_from_date)
      AND (p_to_date   IS NULL OR m."MeetingDate" <= p_to_date)
    ORDER BY m."MeetingDate" DESC
    LIMIT p_limit OFFSET (p_page - 1) * p_limit;
END;
$$;


-- =============================================================================
-- SERVICE BRIDGE WRAPPERS
-- These wrappers bridge the gap between the service parameter names
-- (converted via toSnakeParam) and the underlying function signatures.
-- =============================================================================

-- Internal alias for usp_HR_OccHealth_Create (avoids overload ambiguity)
CREATE OR REPLACE FUNCTION public.usp_hr_occhealth_create_internal(
    p_company_id                INTEGER,
    p_country_code              CHAR(2),
    p_record_type               VARCHAR(25),
    p_employee_id               BIGINT          DEFAULT NULL,
    p_employee_code             VARCHAR(24)     DEFAULT NULL,
    p_employee_name             VARCHAR(200)    DEFAULT NULL,
    p_occurrence_date           TIMESTAMP       DEFAULT NULL,
    p_report_deadline           TIMESTAMP       DEFAULT NULL,
    p_reported_date             TIMESTAMP       DEFAULT NULL,
    p_severity                  VARCHAR(15)     DEFAULT NULL,
    p_body_part_affected        VARCHAR(100)    DEFAULT NULL,
    p_days_lost                 INTEGER         DEFAULT NULL,
    p_location                  VARCHAR(200)    DEFAULT NULL,
    p_description               TEXT            DEFAULT NULL,
    p_root_cause                VARCHAR(500)    DEFAULT NULL,
    p_corrective_action         VARCHAR(500)    DEFAULT NULL,
    p_investigation_due_date    DATE            DEFAULT NULL,
    p_institution_reference     VARCHAR(100)    DEFAULT NULL,
    p_document_url              VARCHAR(500)    DEFAULT NULL,
    p_notes                     VARCHAR(500)    DEFAULT NULL,
    p_created_by                INTEGER         DEFAULT NULL,
    OUT p_resultado             INTEGER,
    OUT p_mensaje               VARCHAR(500)
)
LANGUAGE plpgsql AS $$
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    IF p_record_type NOT IN ('ACCIDENT','DISEASE','NEAR_MISS','INSPECTION','RISK_NOTIFICATION') THEN
        p_resultado := -1;
        p_mensaje   := 'Tipo de registro no vÃ¡lido.';
        RETURN;
    END IF;

    IF p_severity IS NOT NULL AND p_severity NOT IN ('MINOR','MODERATE','SEVERE','FATAL') THEN
        p_resultado := -1;
        p_mensaje   := 'Severidad no vÃ¡lida.';
        RETURN;
    END IF;

    BEGIN
        INSERT INTO hr."OccupationalHealth" (
            "CompanyId", "CountryCode", "RecordType",
            "EmployeeId", "EmployeeCode", "EmployeeName",
            "OccurrenceDate", "ReportDeadline", "ReportedDate",
            "Severity", "BodyPartAffected", "DaysLost",
            "Location", "Description", "RootCause", "CorrectiveAction",
            "InvestigationDueDate", "InstitutionReference",
            "Status", "DocumentUrl", "Notes", "CreatedBy",
            "CreatedAt", "UpdatedAt"
        )
        VALUES (
            p_company_id, p_country_code, p_record_type,
            p_employee_id, p_employee_code, p_employee_name,
            p_occurrence_date, p_report_deadline, p_reported_date,
            p_severity, p_body_part_affected, p_days_lost,
            p_location, p_description, p_root_cause, p_corrective_action,
            p_investigation_due_date, p_institution_reference,
            'OPEN', p_document_url, p_notes, p_created_by,
            (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
        )
        RETURNING "OccupationalHealthId" INTO p_resultado;

        p_mensaje := 'Registro de salud ocupacional creado exitosamente.';
    EXCEPTION WHEN OTHERS THEN
        p_resultado := -1;
        p_mensaje   := SQLERRM;
    END;
END;
$$;

-- Service wrapper: usp_HR_OccHealth_Create
-- Service sends: p_company_id, p_branch_id, p_employee_code, p_record_type,
--                p_incident_date (DATE), p_description, p_severity, p_user_id
DROP FUNCTION IF EXISTS public.usp_hr_occhealth_create(INTEGER, CHAR, VARCHAR, BIGINT, VARCHAR, VARCHAR, TIMESTAMP, TIMESTAMP, TIMESTAMP, VARCHAR, VARCHAR, INTEGER, VARCHAR, TEXT, VARCHAR, VARCHAR, DATE, VARCHAR, VARCHAR, VARCHAR, INTEGER) CASCADE;
DROP FUNCTION IF EXISTS public.usp_hr_occhealth_create(INTEGER, INTEGER, VARCHAR, VARCHAR, TIMESTAMP, TEXT, VARCHAR, INTEGER) CASCADE;
DROP FUNCTION IF EXISTS public.usp_hr_occhealth_create(INTEGER, INTEGER, VARCHAR, VARCHAR, DATE, TEXT, VARCHAR, INTEGER) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_hr_occhealth_create(
    p_company_id    INTEGER,
    p_branch_id     INTEGER     DEFAULT NULL,
    p_employee_code VARCHAR     DEFAULT NULL,
    p_record_type   VARCHAR     DEFAULT NULL,
    p_incident_date DATE        DEFAULT NULL,
    p_description   TEXT        DEFAULT NULL,
    p_severity      VARCHAR     DEFAULT NULL,
    p_user_id       INTEGER     DEFAULT NULL
)
RETURNS TABLE("Resultado" INT, "Mensaje" VARCHAR)
LANGUAGE plpgsql AS $$
DECLARE
    v_country_code CHAR(2);
    v_resultado    INTEGER;
    v_mensaje      VARCHAR(500);
BEGIN
    SELECT COALESCE(c."FiscalCountryCode", 'VE')
    INTO v_country_code
    FROM cfg."Company" c
    WHERE c."CompanyId" = p_company_id
    LIMIT 1;

    IF v_country_code IS NULL THEN v_country_code := 'VE'; END IF;

    SELECT r.p_resultado, r.p_mensaje
    INTO v_resultado, v_mensaje
    FROM public.usp_hr_occhealth_create_internal(
        p_company_id      := p_company_id,
        p_country_code    := v_country_code,
        p_record_type     := UPPER(COALESCE(p_record_type, 'ACCIDENT')),
        p_employee_code   := p_employee_code,
        p_occurrence_date := p_incident_date::TIMESTAMP,
        p_description     := p_description,
        p_severity        := UPPER(p_severity),
        p_created_by      := p_user_id
    ) r;

    RETURN QUERY SELECT v_resultado, v_mensaje;
EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -1::INT, SQLERRM::VARCHAR;
END;
$$;


-- Service wrapper: usp_HR_MedExam_Save
-- Service sends: p_company_id, p_branch_id, p_exam_id, p_employee_code,
--                p_exam_type, p_exam_date, p_result, p_notes, p_next_due_date, p_user_id
DROP FUNCTION IF EXISTS public.usp_HR_MedExam_Save(INTEGER, INTEGER, BIGINT, VARCHAR(24), VARCHAR(200), VARCHAR(20), DATE, DATE, VARCHAR(20), VARCHAR(500), VARCHAR(200), VARCHAR(200), VARCHAR(500), VARCHAR(500)) CASCADE;
DROP FUNCTION IF EXISTS public.usp_hr_medexam_save(INTEGER, INTEGER, INTEGER, VARCHAR, VARCHAR, DATE, VARCHAR, VARCHAR, DATE, INTEGER) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_hr_medexam_save(
    p_company_id    INTEGER,
    p_branch_id     INTEGER     DEFAULT NULL,
    p_exam_id       INTEGER     DEFAULT NULL,
    p_employee_code VARCHAR     DEFAULT NULL,
    p_exam_type     VARCHAR     DEFAULT NULL,
    p_exam_date     DATE        DEFAULT NULL,
    p_result        VARCHAR     DEFAULT NULL,
    p_notes         VARCHAR     DEFAULT NULL,
    p_next_due_date DATE        DEFAULT NULL,
    p_user_id       INTEGER     DEFAULT NULL
)
RETURNS TABLE("Resultado" INT, "Mensaje" VARCHAR)
LANGUAGE plpgsql AS $$
DECLARE
    v_resultado    INTEGER;
    v_mensaje      VARCHAR(500);
    v_employee_id  BIGINT;
    v_employee_name VARCHAR(200);
BEGIN
    SELECT e."EmployeeId", e."EmployeeName"
    INTO v_employee_id, v_employee_name
    FROM master."Employee" e
    WHERE e."EmployeeCode" = p_employee_code
      AND e."CompanyId" = p_company_id
    LIMIT 1;

    IF v_employee_name IS NULL THEN
        v_employee_name := p_employee_code;
    END IF;

    SELECT r.p_resultado, r.p_mensaje
    INTO v_resultado, v_mensaje
    FROM public.usp_hr_medexam_save(
        p_medical_exam_id := p_exam_id,
        p_company_id      := p_company_id,
        p_employee_id     := v_employee_id,
        p_employee_code   := p_employee_code,
        p_employee_name   := v_employee_name,
        p_exam_type       := UPPER(COALESCE(p_exam_type, 'PERIODIC')),
        p_exam_date       := p_exam_date,
        p_result          := UPPER(COALESCE(p_result, 'PENDING')),
        p_notes           := p_notes,
        p_next_due_date   := p_next_due_date
    ) r;

    RETURN QUERY SELECT v_resultado, v_mensaje;
EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -1::INT, SQLERRM::VARCHAR;
END;
$$;


-- Service wrapper: usp_HR_Training_Save
-- Service sends: p_company_id, p_branch_id, p_training_id, p_name, p_description,
--                p_start_date, p_end_date, p_instructor, p_hours, p_participants, p_user_id
DROP FUNCTION IF EXISTS public.usp_HR_Training_Save(INTEGER, INTEGER, CHAR(2), VARCHAR(25), VARCHAR(200), VARCHAR(200), DATE, DATE, NUMERIC(6,2), BIGINT, VARCHAR(24), VARCHAR(200), VARCHAR(100), VARCHAR(500), VARCHAR(15), BOOLEAN, VARCHAR(500)) CASCADE;
DROP FUNCTION IF EXISTS public.usp_hr_training_save(INTEGER, INTEGER, INTEGER, VARCHAR, VARCHAR, DATE, DATE, VARCHAR, NUMERIC, VARCHAR, INTEGER) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_hr_training_save(
    p_company_id    INTEGER,
    p_branch_id     INTEGER     DEFAULT NULL,
    p_training_id   INTEGER     DEFAULT NULL,
    p_name          VARCHAR     DEFAULT NULL,
    p_description   VARCHAR     DEFAULT NULL,
    p_start_date    DATE        DEFAULT NULL,
    p_end_date      DATE        DEFAULT NULL,
    p_instructor    VARCHAR     DEFAULT NULL,
    p_hours         NUMERIC     DEFAULT NULL,
    p_participants  VARCHAR     DEFAULT NULL,
    p_user_id       INTEGER     DEFAULT NULL
)
RETURNS TABLE("Resultado" INT, "Mensaje" VARCHAR)
LANGUAGE plpgsql AS $$
DECLARE
    v_country_code CHAR(2);
    v_resultado    INTEGER;
    v_mensaje      VARCHAR(500);
BEGIN
    SELECT COALESCE(c."FiscalCountryCode", 'VE')
    INTO v_country_code
    FROM cfg."Company" c
    WHERE c."CompanyId" = p_company_id
    LIMIT 1;

    IF v_country_code IS NULL THEN v_country_code := 'VE'; END IF;

    SELECT r.p_resultado, r.p_mensaje
    INTO v_resultado, v_mensaje
    FROM public.usp_hr_training_save(
        p_training_record_id := p_training_id,
        p_company_id         := p_company_id,
        p_country_code       := v_country_code,
        p_training_type      := 'TECHNICAL',
        p_title              := p_name,
        p_provider           := p_instructor,
        p_start_date         := p_start_date,
        p_end_date           := p_end_date,
        p_duration_hours     := COALESCE(p_hours, 1),
        p_employee_code      := COALESCE(p_participants, 'GENERAL'),
        p_employee_name      := COALESCE(p_participants, p_name, 'GENERAL'),
        p_notes              := p_description
    ) r;

    RETURN QUERY SELECT v_resultado, v_mensaje;
EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -1::INT, SQLERRM::VARCHAR;
END;
$$;


-- Service wrapper: usp_HR_Committee_Save
-- Service sends: p_company_id, p_branch_id, p_committee_id, p_name,
--                p_committee_type, p_start_date, p_end_date, p_user_id
DROP FUNCTION IF EXISTS public.usp_HR_Committee_Save(INTEGER, INTEGER, CHAR(2), VARCHAR(200), DATE, VARCHAR(15), BOOLEAN) CASCADE;
DROP FUNCTION IF EXISTS public.usp_hr_committee_save(INTEGER, INTEGER, INTEGER, VARCHAR, VARCHAR, DATE, DATE, INTEGER) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_hr_committee_save(
    p_company_id     INTEGER,
    p_branch_id      INTEGER     DEFAULT NULL,
    p_committee_id   INTEGER     DEFAULT NULL,
    p_name           VARCHAR     DEFAULT NULL,
    p_committee_type VARCHAR     DEFAULT NULL,
    p_start_date     DATE        DEFAULT NULL,
    p_end_date       DATE        DEFAULT NULL,
    p_user_id        INTEGER     DEFAULT NULL
)
RETURNS TABLE("Resultado" INT, "Mensaje" VARCHAR)
LANGUAGE plpgsql AS $$
DECLARE
    v_country_code CHAR(2);
    v_resultado    INTEGER;
    v_mensaje      VARCHAR(500);
    v_meeting_freq VARCHAR(15);
BEGIN
    SELECT COALESCE(c."FiscalCountryCode", 'VE')
    INTO v_country_code
    FROM cfg."Company" c
    WHERE c."CompanyId" = p_company_id
    LIMIT 1;

    IF v_country_code IS NULL THEN v_country_code := 'VE'; END IF;

    v_meeting_freq := CASE UPPER(COALESCE(p_committee_type,''::VARCHAR))
        WHEN 'MONTHLY'   THEN 'MONTHLY'
        WHEN 'QUARTERLY' THEN 'QUARTERLY'
        WHEN 'BIMONTHLY' THEN 'BIMONTHLY'
        WHEN 'WEEKLY'    THEN 'WEEKLY'
        ELSE 'MONTHLY'
    END;

    SELECT r.p_resultado, r.p_mensaje
    INTO v_resultado, v_mensaje
    FROM public.usp_hr_committee_save(
        p_safety_committee_id := p_committee_id,
        p_company_id          := p_company_id,
        p_country_code        := v_country_code,
        p_committee_name      := p_name,
        p_formation_date      := p_start_date,
        p_meeting_frequency   := v_meeting_freq,
        p_is_active           := TRUE
    ) r;

    RETURN QUERY SELECT v_resultado, v_mensaje;
EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -1::INT, SQLERRM::VARCHAR;
END;
$$;


-- RRHH Seed Data

-- ============================================================================
-- SEED RRHH COMPLETO (PostgreSQL) — Datos realistas para Venezuela
-- Idempotente: usa IF NOT EXISTS en cada INSERT
-- Convertido desde SQL Server
-- Fecha: 2026-03-15
-- ============================================================================

DO $$
BEGIN
  RAISE NOTICE '=== SEED RRHH COMPLETO — Inicio ===';

  -- ============================================================================
  -- 1. UTILIDADES 2025 (ProfitSharing + ProfitSharingLine)
  -- Empleado 1: Salario mensual 3500, diario = 116.6667
  -- Empleado 2: Salario mensual 2800, diario = 93.3333
  -- DaysWorked=365, DaysEntitled=30
  -- GrossAmount = DailySalary * DaysEntitled
  -- InceDeduction = GrossAmount * 0.005
  -- ============================================================================
  RAISE NOTICE '>> 1. Utilidades 2025';

  IF NOT EXISTS (SELECT 1 FROM hr."ProfitSharing" WHERE "CompanyId" = 1 AND "FiscalYear" = 2025) THEN
    INSERT INTO hr."ProfitSharing" (
      "ProfitSharingId", "CompanyId", "BranchId", "FiscalYear", "DaysGranted",
      "TotalCompanyProfits", "Status", "CreatedBy", "CreatedAt", "UpdatedAt"
    ) OVERRIDING SYSTEM VALUE
    VALUES (
      1, 1, 1, 2025, 30,
      500000.00, 'CALCULADA', 1, (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
    );
    RAISE NOTICE '   ProfitSharing 2025 insertado.';
  END IF;

  -- Linea empleado V-25678901
  IF NOT EXISTS (SELECT 1 FROM hr."ProfitSharingLine" WHERE "ProfitSharingId" = 1 AND "EmployeeCode" = 'V-25678901') THEN
    INSERT INTO hr."ProfitSharingLine" (
      "LineId", "ProfitSharingId", "EmployeeId", "EmployeeCode", "EmployeeName",
      "MonthlySalary", "DailySalary", "DaysWorked", "DaysEntitled",
      "GrossAmount", "InceDeduction", "NetAmount", "IsPaid", "PaidAt"
    ) OVERRIDING SYSTEM VALUE
    SELECT 1, 1, e."EmployeeId", 'V-25678901', 'Empleado V-25678901',
      3500.00, 116.6667, 365, 30,
      3500.00, 17.50, 3482.50, false, NULL
    FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-25678901';
    RAISE NOTICE '   ProfitSharingLine empleado V-25678901 insertado.';
  END IF;

  -- Linea empleado V-18901234
  IF NOT EXISTS (SELECT 1 FROM hr."ProfitSharingLine" WHERE "ProfitSharingId" = 1 AND "EmployeeCode" = 'V-18901234') THEN
    INSERT INTO hr."ProfitSharingLine" (
      "LineId", "ProfitSharingId", "EmployeeId", "EmployeeCode", "EmployeeName",
      "MonthlySalary", "DailySalary", "DaysWorked", "DaysEntitled",
      "GrossAmount", "InceDeduction", "NetAmount", "IsPaid", "PaidAt"
    ) OVERRIDING SYSTEM VALUE
    SELECT 2, 1, e."EmployeeId", 'V-18901234', 'Empleado V-18901234',
      2800.00, 93.3333, 365, 30,
      2800.00, 14.00, 2786.00, false, NULL
    FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-18901234';
    RAISE NOTICE '   ProfitSharingLine empleado V-18901234 insertado.';
  END IF;

  -- ============================================================================
  -- 2. FIDEICOMISO (SocialBenefitsTrust) — 4 trimestres 2025, ambos empleados
  -- Empleado 1: DailySalary=116.6667, 15 dias/trimestre, InterestRate=15.3%
  -- Empleado 2: DailySalary=93.3333, 15 dias/trimestre
  -- ============================================================================
  RAISE NOTICE '>> 2. Fideicomiso de Prestaciones Sociales 2025';

  -- Empleado V-25678901: Q1
  IF NOT EXISTS (SELECT 1 FROM hr."SocialBenefitsTrust" WHERE "TrustId" = 1) THEN
    INSERT INTO hr."SocialBenefitsTrust" (
      "TrustId", "CompanyId", "EmployeeId", "EmployeeCode", "EmployeeName",
      "FiscalYear", "Quarter", "DailySalary", "DaysDeposited", "BonusDays",
      "DepositAmount", "InterestRate", "InterestAmount", "AccumulatedBalance",
      "Status", "CreatedAt", "UpdatedAt"
    ) OVERRIDING SYSTEM VALUE
    SELECT 1, 1, e."EmployeeId", 'V-25678901', 'Empleado V-25678901', 2025, 1, 116.6667, 15, 0, 1750.00, 15.30, 0.00, 1750.00, 'DEPOSITADO', (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
    FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-25678901';
  END IF;

  -- Empleado V-25678901: Q2
  IF NOT EXISTS (SELECT 1 FROM hr."SocialBenefitsTrust" WHERE "TrustId" = 2) THEN
    INSERT INTO hr."SocialBenefitsTrust" (
      "TrustId", "CompanyId", "EmployeeId", "EmployeeCode", "EmployeeName",
      "FiscalYear", "Quarter", "DailySalary", "DaysDeposited", "BonusDays",
      "DepositAmount", "InterestRate", "InterestAmount", "AccumulatedBalance",
      "Status", "CreatedAt", "UpdatedAt"
    ) OVERRIDING SYSTEM VALUE
    SELECT 2, 1, e."EmployeeId", 'V-25678901', 'Empleado V-25678901', 2025, 2, 116.6667, 15, 0, 1750.00, 15.30, 66.94, 3566.94, 'DEPOSITADO', (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
    FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-25678901';
  END IF;

  -- Empleado V-25678901: Q3
  IF NOT EXISTS (SELECT 1 FROM hr."SocialBenefitsTrust" WHERE "TrustId" = 3) THEN
    INSERT INTO hr."SocialBenefitsTrust" (
      "TrustId", "CompanyId", "EmployeeId", "EmployeeCode", "EmployeeName",
      "FiscalYear", "Quarter", "DailySalary", "DaysDeposited", "BonusDays",
      "DepositAmount", "InterestRate", "InterestAmount", "AccumulatedBalance",
      "Status", "CreatedAt", "UpdatedAt"
    ) OVERRIDING SYSTEM VALUE
    SELECT 3, 1, e."EmployeeId", 'V-25678901', 'Empleado V-25678901', 2025, 3, 116.6667, 15, 0, 1750.00, 15.30, 136.44, 5453.38, 'DEPOSITADO', (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
    FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-25678901';
  END IF;

  -- Empleado V-25678901: Q4
  IF NOT EXISTS (SELECT 1 FROM hr."SocialBenefitsTrust" WHERE "TrustId" = 4) THEN
    INSERT INTO hr."SocialBenefitsTrust" (
      "TrustId", "CompanyId", "EmployeeId", "EmployeeCode", "EmployeeName",
      "FiscalYear", "Quarter", "DailySalary", "DaysDeposited", "BonusDays",
      "DepositAmount", "InterestRate", "InterestAmount", "AccumulatedBalance",
      "Status", "CreatedAt", "UpdatedAt"
    ) OVERRIDING SYSTEM VALUE
    SELECT 4, 1, e."EmployeeId", 'V-25678901', 'Empleado V-25678901', 2025, 4, 116.6667, 15, 0, 1750.00, 15.30, 208.59, 7411.97, 'DEPOSITADO', (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
    FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-25678901';
  END IF;

  -- Empleado V-18901234: Q1
  IF NOT EXISTS (SELECT 1 FROM hr."SocialBenefitsTrust" WHERE "TrustId" = 5) THEN
    INSERT INTO hr."SocialBenefitsTrust" (
      "TrustId", "CompanyId", "EmployeeId", "EmployeeCode", "EmployeeName",
      "FiscalYear", "Quarter", "DailySalary", "DaysDeposited", "BonusDays",
      "DepositAmount", "InterestRate", "InterestAmount", "AccumulatedBalance",
      "Status", "CreatedAt", "UpdatedAt"
    ) OVERRIDING SYSTEM VALUE
    SELECT 5, 1, e."EmployeeId", 'V-18901234', 'Empleado V-18901234', 2025, 1, 93.3333, 15, 0, 1400.00, 15.30, 0.00, 1400.00, 'DEPOSITADO', (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
    FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-18901234';
  END IF;

  -- Empleado V-18901234: Q2
  IF NOT EXISTS (SELECT 1 FROM hr."SocialBenefitsTrust" WHERE "TrustId" = 6) THEN
    INSERT INTO hr."SocialBenefitsTrust" (
      "TrustId", "CompanyId", "EmployeeId", "EmployeeCode", "EmployeeName",
      "FiscalYear", "Quarter", "DailySalary", "DaysDeposited", "BonusDays",
      "DepositAmount", "InterestRate", "InterestAmount", "AccumulatedBalance",
      "Status", "CreatedAt", "UpdatedAt"
    ) OVERRIDING SYSTEM VALUE
    SELECT 6, 1, e."EmployeeId", 'V-18901234', 'Empleado V-18901234', 2025, 2, 93.3333, 15, 0, 1400.00, 15.30, 53.55, 2853.55, 'DEPOSITADO', (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
    FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-18901234';
  END IF;

  -- Empleado V-18901234: Q3
  IF NOT EXISTS (SELECT 1 FROM hr."SocialBenefitsTrust" WHERE "TrustId" = 7) THEN
    INSERT INTO hr."SocialBenefitsTrust" (
      "TrustId", "CompanyId", "EmployeeId", "EmployeeCode", "EmployeeName",
      "FiscalYear", "Quarter", "DailySalary", "DaysDeposited", "BonusDays",
      "DepositAmount", "InterestRate", "InterestAmount", "AccumulatedBalance",
      "Status", "CreatedAt", "UpdatedAt"
    ) OVERRIDING SYSTEM VALUE
    SELECT 7, 1, e."EmployeeId", 'V-18901234', 'Empleado V-18901234', 2025, 3, 93.3333, 15, 0, 1400.00, 15.30, 109.15, 4362.70, 'DEPOSITADO', (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
    FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-18901234';
  END IF;

  -- Empleado V-18901234: Q4
  IF NOT EXISTS (SELECT 1 FROM hr."SocialBenefitsTrust" WHERE "TrustId" = 8) THEN
    INSERT INTO hr."SocialBenefitsTrust" (
      "TrustId", "CompanyId", "EmployeeId", "EmployeeCode", "EmployeeName",
      "FiscalYear", "Quarter", "DailySalary", "DaysDeposited", "BonusDays",
      "DepositAmount", "InterestRate", "InterestAmount", "AccumulatedBalance",
      "Status", "CreatedAt", "UpdatedAt"
    ) OVERRIDING SYSTEM VALUE
    SELECT 8, 1, e."EmployeeId", 'V-18901234', 'Empleado V-18901234', 2025, 4, 93.3333, 15, 0, 1400.00, 15.30, 166.87, 5929.57, 'DEPOSITADO', (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
    FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-18901234';
  END IF;

  RAISE NOTICE '   8 registros de fideicomiso insertados.';

  -- ============================================================================
  -- 3. CAJA DE AHORRO (SavingsFund + SavingsFundTransaction + SavingsLoan)
  -- Empleado 1: 5% de 3500 = 175.00 por tipo por mes
  -- Empleado 2: 5% de 2800 = 140.00 por tipo por mes
  -- ============================================================================
  RAISE NOTICE '>> 3. Caja de Ahorro';

  IF NOT EXISTS (SELECT 1 FROM hr."SavingsFund" WHERE "SavingsFundId" = 1) THEN
    INSERT INTO hr."SavingsFund" (
      "SavingsFundId", "CompanyId", "EmployeeId", "EmployeeCode", "EmployeeName",
      "EmployeeContribution", "EmployerMatch", "EnrollmentDate", "Status", "CreatedAt"
    ) OVERRIDING SYSTEM VALUE
    SELECT 1, 1, e."EmployeeId", 'V-25678901', 'Empleado V-25678901', 5.00, 5.00, '2025-01-15', 'ACTIVO', (NOW() AT TIME ZONE 'UTC')
    FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-25678901';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM hr."SavingsFund" WHERE "SavingsFundId" = 2) THEN
    INSERT INTO hr."SavingsFund" (
      "SavingsFundId", "CompanyId", "EmployeeId", "EmployeeCode", "EmployeeName",
      "EmployeeContribution", "EmployerMatch", "EnrollmentDate", "Status", "CreatedAt"
    ) OVERRIDING SYSTEM VALUE
    SELECT 2, 1, e."EmployeeId", 'V-18901234', 'Empleado V-18901234', 5.00, 5.00, '2025-01-15', 'ACTIVO', (NOW() AT TIME ZONE 'UTC')
    FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-18901234';
  END IF;

  RAISE NOTICE '   2 inscripciones de caja de ahorro insertadas.';

  -- Transacciones: 3 meses x 2 tipos x 2 empleados = 12 transacciones
  INSERT INTO hr."SavingsFundTransaction" (
    "TransactionId", "SavingsFundId", "TransactionDate", "TransactionType",
    "Amount", "Balance", "Reference", "PayrollBatchId", "Notes", "CreatedAt"
  ) OVERRIDING SYSTEM VALUE
  SELECT txn_id, fund_id, txn_date::date, txn_type, amount, balance, ref, NULL, notes, (NOW() AT TIME ZONE 'UTC')
  FROM (VALUES
    (1,  1, '2025-01-31', 'APORTE_EMPLEADO', 175.00, 175.00,  'NOM-2025-01', 'Aporte enero 2025'),
    (2,  1, '2025-01-31', 'APORTE_PATRONAL', 175.00, 350.00,  'NOM-2025-01', 'Aporte patronal enero 2025'),
    (3,  1, '2025-02-28', 'APORTE_EMPLEADO', 175.00, 525.00,  'NOM-2025-02', 'Aporte febrero 2025'),
    (4,  1, '2025-02-28', 'APORTE_PATRONAL', 175.00, 700.00,  'NOM-2025-02', 'Aporte patronal febrero 2025'),
    (5,  1, '2025-03-31', 'APORTE_EMPLEADO', 175.00, 875.00,  'NOM-2025-03', 'Aporte marzo 2025'),
    (6,  1, '2025-03-31', 'APORTE_PATRONAL', 175.00, 1050.00, 'NOM-2025-03', 'Aporte patronal marzo 2025'),
    (7,  2, '2025-01-31', 'APORTE_EMPLEADO', 140.00, 140.00,  'NOM-2025-01', 'Aporte enero 2025'),
    (8,  2, '2025-01-31', 'APORTE_PATRONAL', 140.00, 280.00,  'NOM-2025-01', 'Aporte patronal enero 2025'),
    (9,  2, '2025-02-28', 'APORTE_EMPLEADO', 140.00, 420.00,  'NOM-2025-02', 'Aporte febrero 2025'),
    (10, 2, '2025-02-28', 'APORTE_PATRONAL', 140.00, 560.00,  'NOM-2025-02', 'Aporte patronal febrero 2025'),
    (11, 2, '2025-03-31', 'APORTE_EMPLEADO', 140.00, 700.00,  'NOM-2025-03', 'Aporte marzo 2025'),
    (12, 2, '2025-03-31', 'APORTE_PATRONAL', 140.00, 840.00,  'NOM-2025-03', 'Aporte patronal marzo 2025')
  ) AS t(txn_id, fund_id, txn_date, txn_type, amount, balance, ref, notes)
  WHERE NOT EXISTS (SELECT 1 FROM hr."SavingsFundTransaction" WHERE "TransactionId" = t.txn_id);

  RAISE NOTICE '   12 transacciones de caja de ahorro insertadas.';

  -- Prestamo para empleado 1
  IF NOT EXISTS (SELECT 1 FROM hr."SavingsLoan" WHERE "LoanId" = 1) THEN
    INSERT INTO hr."SavingsLoan" (
      "LoanId", "SavingsFundId", "EmployeeCode", "RequestDate", "ApprovedDate",
      "LoanAmount", "InterestRate", "TotalPayable", "MonthlyPayment",
      "InstallmentsTotal", "InstallmentsPaid", "OutstandingBalance",
      "Status", "ApprovedBy", "Notes", "CreatedAt", "UpdatedAt"
    ) OVERRIDING SYSTEM VALUE VALUES (
      1, 1, 'V-25678901', '2025-04-01', '2025-04-05',
      5000.00, 6.00, 5300.00, 441.67,
      12, 3, 3975.01,
      'APROBADO', 1, 'Prestamo ordinario caja de ahorro', (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
    );
  END IF;

  RAISE NOTICE '   1 prestamo de caja de ahorro insertado.';

  -- ============================================================================
  -- 4. OBLIGACIONES LEGALES — Inscripcion empleados 1 y 2 + Filing SSO enero 2026
  -- ============================================================================
  RAISE NOTICE '>> 4. Obligaciones Legales';

  -- Inscribir empleado 1 en SSO
  INSERT INTO hr."EmployeeObligation" (
    "EmployeeId", "LegalObligationId", "AffiliationNumber", "InstitutionCode",
    "RiskLevelId", "EnrollmentDate", "DisenrollmentDate", "Status", "CustomRate",
    "CreatedAt", "UpdatedAt"
  )
  SELECT 1, lo."LegalObligationId", 'SSO-0125678901', 'IVSS',
    NULL, '2024-03-01', NULL, 'ACTIVO', NULL,
    (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
  FROM hr."LegalObligation" lo WHERE lo."Code" = 'VE_SSO'
  AND NOT EXISTS (
    SELECT 1 FROM hr."EmployeeObligation" eo
    INNER JOIN hr."LegalObligation" lo2 ON eo."LegalObligationId" = lo2."LegalObligationId"
    WHERE eo."EmployeeId" = 1 AND lo2."Code" = 'VE_SSO'
  );

  -- Inscribir empleado 1 en FAOV
  INSERT INTO hr."EmployeeObligation" (
    "EmployeeId", "LegalObligationId", "AffiliationNumber", "InstitutionCode",
    "RiskLevelId", "EnrollmentDate", "DisenrollmentDate", "Status", "CustomRate",
    "CreatedAt", "UpdatedAt"
  )
  SELECT 1, lo."LegalObligationId", 'FAOV-0125678901', 'BANAVIH',
    NULL, '2024-03-01', NULL, 'ACTIVO', NULL,
    (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
  FROM hr."LegalObligation" lo WHERE lo."Code" = 'VE_FAOV'
  AND NOT EXISTS (
    SELECT 1 FROM hr."EmployeeObligation" eo
    INNER JOIN hr."LegalObligation" lo2 ON eo."LegalObligationId" = lo2."LegalObligationId"
    WHERE eo."EmployeeId" = 1 AND lo2."Code" = 'VE_FAOV'
  );

  -- Inscribir empleado 1 en INCE
  INSERT INTO hr."EmployeeObligation" (
    "EmployeeId", "LegalObligationId", "AffiliationNumber", "InstitutionCode",
    "RiskLevelId", "EnrollmentDate", "DisenrollmentDate", "Status", "CustomRate",
    "CreatedAt", "UpdatedAt"
  )
  SELECT 1, lo."LegalObligationId", 'INCE-0125678901', 'INCE',
    NULL, '2024-03-01', NULL, 'ACTIVO', NULL,
    (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
  FROM hr."LegalObligation" lo WHERE lo."Code" = 'VE_INCE'
  AND NOT EXISTS (
    SELECT 1 FROM hr."EmployeeObligation" eo
    INNER JOIN hr."LegalObligation" lo2 ON eo."LegalObligationId" = lo2."LegalObligationId"
    WHERE eo."EmployeeId" = 1 AND lo2."Code" = 'VE_INCE'
  );

  -- Inscribir empleado 2 en SSO
  INSERT INTO hr."EmployeeObligation" (
    "EmployeeId", "LegalObligationId", "AffiliationNumber", "InstitutionCode",
    "RiskLevelId", "EnrollmentDate", "DisenrollmentDate", "Status", "CustomRate",
    "CreatedAt", "UpdatedAt"
  )
  SELECT 2, lo."LegalObligationId", 'SSO-0218901234', 'IVSS',
    NULL, '2024-06-01', NULL, 'ACTIVO', NULL,
    (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
  FROM hr."LegalObligation" lo WHERE lo."Code" = 'VE_SSO'
  AND NOT EXISTS (
    SELECT 1 FROM hr."EmployeeObligation" eo
    INNER JOIN hr."LegalObligation" lo2 ON eo."LegalObligationId" = lo2."LegalObligationId"
    WHERE eo."EmployeeId" = 2 AND lo2."Code" = 'VE_SSO'
  );

  -- Inscribir empleado 2 en FAOV
  INSERT INTO hr."EmployeeObligation" (
    "EmployeeId", "LegalObligationId", "AffiliationNumber", "InstitutionCode",
    "RiskLevelId", "EnrollmentDate", "DisenrollmentDate", "Status", "CustomRate",
    "CreatedAt", "UpdatedAt"
  )
  SELECT 2, lo."LegalObligationId", 'FAOV-0218901234', 'BANAVIH',
    NULL, '2024-06-01', NULL, 'ACTIVO', NULL,
    (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
  FROM hr."LegalObligation" lo WHERE lo."Code" = 'VE_FAOV'
  AND NOT EXISTS (
    SELECT 1 FROM hr."EmployeeObligation" eo
    INNER JOIN hr."LegalObligation" lo2 ON eo."LegalObligationId" = lo2."LegalObligationId"
    WHERE eo."EmployeeId" = 2 AND lo2."Code" = 'VE_FAOV'
  );

  -- Inscribir empleado 2 en INCE
  INSERT INTO hr."EmployeeObligation" (
    "EmployeeId", "LegalObligationId", "AffiliationNumber", "InstitutionCode",
    "RiskLevelId", "EnrollmentDate", "DisenrollmentDate", "Status", "CustomRate",
    "CreatedAt", "UpdatedAt"
  )
  SELECT 2, lo."LegalObligationId", 'INCE-0218901234', 'INCE',
    NULL, '2024-06-01', NULL, 'ACTIVO', NULL,
    (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
  FROM hr."LegalObligation" lo WHERE lo."Code" = 'VE_INCE'
  AND NOT EXISTS (
    SELECT 1 FROM hr."EmployeeObligation" eo
    INNER JOIN hr."LegalObligation" lo2 ON eo."LegalObligationId" = lo2."LegalObligationId"
    WHERE eo."EmployeeId" = 2 AND lo2."Code" = 'VE_INCE'
  );

  -- Filing SSO enero 2026 (FilingId 1)
  IF NOT EXISTS (SELECT 1 FROM hr."ObligationFiling" WHERE "ObligationFilingId" = 1) THEN
    INSERT INTO hr."ObligationFiling" (
      "ObligationFilingId", "CompanyId", "LegalObligationId",
      "FilingPeriodStart", "FilingPeriodEnd", "DueDate", "FiledDate",
      "ConfirmationNumber", "TotalEmployerAmount", "TotalEmployeeAmount", "TotalAmount",
      "EmployeeCount", "Status", "FiledByUserId", "DocumentUrl", "Notes",
      "CreatedAt", "UpdatedAt"
    ) OVERRIDING SYSTEM VALUE
    SELECT 1, 1, lo."LegalObligationId",
      '2026-01-01', '2026-01-31', '2026-02-15', '2026-02-10',
      'IVSS-2026-01-00458', 693.00, 252.00, 945.00,
      2, 'FILED', 1, NULL, 'Declaracion SSO enero 2026',
      (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
    FROM hr."LegalObligation" lo WHERE lo."Code" = 'VE_SSO';
  END IF;

  -- Filing Detail: empleado V-25678901
  INSERT INTO hr."ObligationFilingDetail" ("ObligationFilingId", "EmployeeId", "BaseSalary", "EmployerAmount", "EmployeeAmount", "DaysWorked", "NoveltyType")
  SELECT 1, e."EmployeeId", 3500.00, 385.00, 140.00, 31, 'NONE'
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-25678901'
  AND NOT EXISTS (SELECT 1 FROM hr."ObligationFilingDetail" WHERE "ObligationFilingId" = 1 AND "EmployeeId" = e."EmployeeId");

  -- Filing Detail: empleado V-18901234
  INSERT INTO hr."ObligationFilingDetail" ("ObligationFilingId", "EmployeeId", "BaseSalary", "EmployerAmount", "EmployeeAmount", "DaysWorked", "NoveltyType")
  SELECT 1, e."EmployeeId", 2800.00, 308.00, 112.00, 31, 'NONE'
  FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-18901234'
  AND NOT EXISTS (SELECT 1 FROM hr."ObligationFilingDetail" WHERE "ObligationFilingId" = 1 AND "EmployeeId" = e."EmployeeId");

  RAISE NOTICE '   Filing SSO enero 2026 + 2 detalles insertados.';

  -- ============================================================================
  -- 5. SALUD OCUPACIONAL (OccupationalHealth)
  -- ============================================================================
  RAISE NOTICE '>> 5. Salud Ocupacional';

  -- Accidente leve emp V-25678901
  IF NOT EXISTS (SELECT 1 FROM hr."OccupationalHealth" WHERE "OccupationalHealthId" = 1) THEN
    INSERT INTO hr."OccupationalHealth" (
      "OccupationalHealthId", "CompanyId", "CountryCode", "RecordType",
      "EmployeeId", "EmployeeCode", "EmployeeName",
      "OccurrenceDate", "ReportDeadline", "ReportedDate",
      "Severity", "BodyPartAffected", "DaysLost", "Location",
      "Description", "RootCause", "CorrectiveAction",
      "InvestigationDueDate", "InvestigationCompletedDate",
      "InstitutionReference", "Status", "DocumentUrl", "Notes",
      "CreatedBy", "CreatedAt", "UpdatedAt"
    ) OVERRIDING SYSTEM VALUE
    SELECT
      1, 1, 'VE', 'ACCIDENTE',
      e."EmployeeId", 'V-25678901', 'Empleado V-25678901',
      '2025-09-15', '2025-09-19', '2025-09-16',
      'LEVE', 'Mano derecha', 2, 'Almacen principal',
      'Corte superficial en mano derecha al manipular cajas de inventario.',
      'Ausencia de guantes de proteccion durante manipulacion de cajas.',
      'Dotacion inmediata de guantes de seguridad. Charla de refuerzo sobre EPP.',
      '2025-09-22', '2025-09-20',
      'INPSASEL-2025-09-004571', 'CLOSED', NULL,
      'Caso cerrado. Empleado reincorporado el 2025-09-17.',
      1, (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
    FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-25678901';
  END IF;

  -- Incidente sin dias perdidos emp V-18901234
  IF NOT EXISTS (SELECT 1 FROM hr."OccupationalHealth" WHERE "OccupationalHealthId" = 2) THEN
    INSERT INTO hr."OccupationalHealth" (
      "OccupationalHealthId", "CompanyId", "CountryCode", "RecordType",
      "EmployeeId", "EmployeeCode", "EmployeeName",
      "OccurrenceDate", "ReportDeadline", "ReportedDate",
      "Severity", "BodyPartAffected", "DaysLost", "Location",
      "Description", "RootCause", "CorrectiveAction",
      "InvestigationDueDate", "InvestigationCompletedDate",
      "InstitutionReference", "Status", "DocumentUrl", "Notes",
      "CreatedBy", "CreatedAt", "UpdatedAt"
    ) OVERRIDING SYSTEM VALUE
    SELECT
      2, 1, 'VE', 'INCIDENTE',
      e."EmployeeId", 'V-18901234', 'Empleado V-18901234',
      '2025-11-03', '2025-11-07', '2025-11-04',
      'LEVE', NULL, 0, 'Oficina administrativa',
      'Derrame de liquido en pasillo causo resbalo sin caida ni lesion.',
      'Falta de senalizacion de piso mojado.',
      'Instalacion de porta avisos de piso humedo en cada area. Protocolo de limpieza actualizado.',
      '2025-11-10', NULL,
      NULL, 'REPORTED', NULL,
      'Incidente reportado. Sin lesion. Pendiente cierre de investigacion.',
      1, (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
    FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-18901234';
  END IF;

  RAISE NOTICE '   2 registros de salud ocupacional insertados.';

  -- ============================================================================
  -- 6. EXAMENES MEDICOS (MedicalExam)
  -- ============================================================================
  RAISE NOTICE '>> 6. Examenes Medicos';

  -- Preempleo empleado V-25678901
  IF NOT EXISTS (SELECT 1 FROM hr."MedicalExam" WHERE "MedicalExamId" = 1) THEN
    INSERT INTO hr."MedicalExam" (
      "MedicalExamId", "CompanyId", "EmployeeId", "EmployeeCode", "EmployeeName",
      "ExamType", "ExamDate", "NextDueDate", "Result", "Restrictions",
      "PhysicianName", "ClinicName", "DocumentUrl", "Notes", "CreatedAt", "UpdatedAt"
    ) OVERRIDING SYSTEM VALUE
    SELECT 1, 1, e."EmployeeId", 'V-25678901', 'Empleado V-25678901',
      'PREEMPLEO', '2024-02-20', NULL, 'APTO', NULL,
      'Dra. Maria Gonzalez', 'Centro Medico La Trinidad',
      NULL, 'Examen preempleo sin observaciones.', (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
    FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-25678901';
  END IF;

  -- Preempleo empleado V-18901234
  IF NOT EXISTS (SELECT 1 FROM hr."MedicalExam" WHERE "MedicalExamId" = 2) THEN
    INSERT INTO hr."MedicalExam" (
      "MedicalExamId", "CompanyId", "EmployeeId", "EmployeeCode", "EmployeeName",
      "ExamType", "ExamDate", "NextDueDate", "Result", "Restrictions",
      "PhysicianName", "ClinicName", "DocumentUrl", "Notes", "CreatedAt", "UpdatedAt"
    ) OVERRIDING SYSTEM VALUE
    SELECT 2, 1, e."EmployeeId", 'V-18901234', 'Empleado V-18901234',
      'PREEMPLEO', '2024-05-10', NULL, 'APTO', NULL,
      'Dr. Carlos Ramirez', 'Clinica Santa Sofia',
      NULL, 'Examen preempleo sin restricciones.', (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
    FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-18901234';
  END IF;

  -- Periodico empleado V-25678901
  IF NOT EXISTS (SELECT 1 FROM hr."MedicalExam" WHERE "MedicalExamId" = 3) THEN
    INSERT INTO hr."MedicalExam" (
      "MedicalExamId", "CompanyId", "EmployeeId", "EmployeeCode", "EmployeeName",
      "ExamType", "ExamDate", "NextDueDate", "Result", "Restrictions",
      "PhysicianName", "ClinicName", "DocumentUrl", "Notes", "CreatedAt", "UpdatedAt"
    ) OVERRIDING SYSTEM VALUE
    SELECT 3, 1, e."EmployeeId", 'V-25678901', 'Empleado V-25678901',
      'PERIODICO', '2025-02-18', '2026-02-18', 'APTO', NULL,
      'Dra. Maria Gonzalez', 'Centro Medico La Trinidad',
      NULL, 'Control anual. Sin hallazgos relevantes.', (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
    FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-25678901';
  END IF;

  -- Periodico empleado V-18901234 — NextDueDate VENCIDA para generar alerta
  IF NOT EXISTS (SELECT 1 FROM hr."MedicalExam" WHERE "MedicalExamId" = 4) THEN
    INSERT INTO hr."MedicalExam" (
      "MedicalExamId", "CompanyId", "EmployeeId", "EmployeeCode", "EmployeeName",
      "ExamType", "ExamDate", "NextDueDate", "Result", "Restrictions",
      "PhysicianName", "ClinicName", "DocumentUrl", "Notes", "CreatedAt", "UpdatedAt"
    ) OVERRIDING SYSTEM VALUE
    SELECT 4, 1, e."EmployeeId", 'V-18901234', 'Empleado V-18901234',
      'PERIODICO', '2025-01-10', '2026-01-10', 'APTO',
      'Uso de lentes correctivos obligatorio',
      'Dr. Carlos Ramirez', 'Clinica Santa Sofia',
      NULL, 'Control anual. Requiere lentes correctivos. VENCIDO — proximo examen pendiente.',
      (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
    FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-18901234';
  END IF;

  RAISE NOTICE '   4 examenes medicos insertados.';

  -- ============================================================================
  -- 7. ORDENES MEDICAS (MedicalOrder)
  -- ============================================================================
  RAISE NOTICE '>> 7. Ordenes Medicas';

  -- Consulta aprobada emp V-25678901
  IF NOT EXISTS (SELECT 1 FROM hr."MedicalOrder" WHERE "MedicalOrderId" = 1) THEN
    INSERT INTO hr."MedicalOrder" (
      "MedicalOrderId", "CompanyId", "EmployeeId", "EmployeeCode", "EmployeeName",
      "OrderType", "OrderDate", "Diagnosis", "PhysicianName", "Prescriptions",
      "EstimatedCost", "ApprovedAmount", "Status", "ApprovedBy", "ApprovedAt",
      "DocumentUrl", "Notes", "CreatedAt", "UpdatedAt"
    ) OVERRIDING SYSTEM VALUE
    SELECT 1, 1, e."EmployeeId", 'V-25678901', 'Empleado V-25678901',
      'CONSULTA', '2025-10-05', 'Lumbalgia mecanica',
      'Dr. Pedro Martinez', 'Ibuprofeno 400mg c/8h x 5 dias. Reposo relativo.',
      150.00, 150.00, 'APROBADA', 1, '2025-10-06',
      NULL, 'Consulta traumatologia por dolor lumbar.', (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
    FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-25678901';
  END IF;

  -- Farmacia pendiente emp V-18901234
  IF NOT EXISTS (SELECT 1 FROM hr."MedicalOrder" WHERE "MedicalOrderId" = 2) THEN
    INSERT INTO hr."MedicalOrder" (
      "MedicalOrderId", "CompanyId", "EmployeeId", "EmployeeCode", "EmployeeName",
      "OrderType", "OrderDate", "Diagnosis", "PhysicianName", "Prescriptions",
      "EstimatedCost", "ApprovedAmount", "Status", "ApprovedBy", "ApprovedAt",
      "DocumentUrl", "Notes", "CreatedAt", "UpdatedAt"
    ) OVERRIDING SYSTEM VALUE
    SELECT 2, 1, e."EmployeeId", 'V-18901234', 'Empleado V-18901234',
      'FARMACIA', '2026-01-15', 'Infeccion respiratoria aguda',
      'Dra. Ana Suarez', 'Amoxicilina 500mg c/8h x 7 dias. Reposo 2 dias.',
      80.00, 80.00, 'PENDIENTE', NULL, NULL,
      NULL, 'Pendiente aprobacion farmacia.', (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
    FROM master."Employee" e WHERE e."CompanyId" = 1 AND e."EmployeeCode" = 'V-18901234';
  END IF;

  RAISE NOTICE '   2 ordenes medicas insertadas.';
  RAISE NOTICE '=== SEED RRHH COMPLETO — Completado ===';

EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE 'Error en seed_rrhh_completo.sql: %', SQLERRM;
END $$;


-- +goose StatementEnd

-- +goose Down
DROP FUNCTION IF EXISTS public.usp_HR_ProfitSharing_Generate CASCADE;
DROP FUNCTION IF EXISTS public.usp_HR_ProfitSharing_GetSummary CASCADE;
DROP FUNCTION IF EXISTS public.usp_HR_ProfitSharing_Approve CASCADE;
DROP FUNCTION IF EXISTS public.usp_HR_ProfitSharing_List CASCADE;
DROP FUNCTION IF EXISTS public.usp_HR_Trust_CalculateQuarter CASCADE;
DROP FUNCTION IF EXISTS public.usp_HR_Trust_GetEmployeeBalance CASCADE;
DROP FUNCTION IF EXISTS public.usp_HR_Trust_GetSummary CASCADE;
DROP FUNCTION IF EXISTS public.usp_HR_Trust_List CASCADE;
DROP FUNCTION IF EXISTS public.usp_HR_Savings_Enroll CASCADE;
DROP FUNCTION IF EXISTS public.usp_HR_Savings_ProcessMonthly CASCADE;
DROP FUNCTION IF EXISTS public.usp_HR_Savings_GetBalance CASCADE;
DROP FUNCTION IF EXISTS public.usp_HR_Savings_RequestLoan CASCADE;
DROP FUNCTION IF EXISTS public.usp_HR_Savings_ApproveLoan CASCADE;
DROP FUNCTION IF EXISTS public.usp_HR_Savings_ProcessLoanPayment CASCADE;
DROP FUNCTION IF EXISTS public.usp_HR_Savings_List CASCADE;
DROP FUNCTION IF EXISTS public.usp_HR_Savings_LoanList CASCADE;
DROP FUNCTION IF EXISTS public.usp_HR_Obligation_List CASCADE;
DROP FUNCTION IF EXISTS public.usp_HR_Obligation_Save CASCADE;
DROP FUNCTION IF EXISTS public.usp_HR_Obligation_GetByCountry CASCADE;
DROP FUNCTION IF EXISTS public.usp_HR_EmployeeObligation_Enroll CASCADE;
DROP FUNCTION IF EXISTS public.usp_HR_EmployeeObligation_Disenroll CASCADE;
DROP FUNCTION IF EXISTS public.usp_HR_EmployeeObligation_GetByEmployee CASCADE;
DROP FUNCTION IF EXISTS public.usp_HR_Filing_Generate CASCADE;
DROP FUNCTION IF EXISTS public.usp_HR_Filing_GetSummary CASCADE;
DROP FUNCTION IF EXISTS public.usp_HR_Filing_MarkFiled CASCADE;
DROP FUNCTION IF EXISTS public.usp_HR_Filing_List CASCADE;
DROP FUNCTION IF EXISTS public.usp_HR_OccHealth_Create CASCADE;
DROP FUNCTION IF EXISTS public.usp_HR_OccHealth_Update CASCADE;
DROP FUNCTION IF EXISTS public.usp_HR_OccHealth_List CASCADE;
DROP FUNCTION IF EXISTS public.usp_HR_OccHealth_Get CASCADE;
DROP FUNCTION IF EXISTS public.usp_HR_MedExam_Save CASCADE;
DROP FUNCTION IF EXISTS public.usp_HR_MedExam_List CASCADE;
DROP FUNCTION IF EXISTS public.usp_HR_MedExam_GetPending CASCADE;
DROP FUNCTION IF EXISTS public.usp_HR_MedOrder_Create CASCADE;
DROP FUNCTION IF EXISTS public.usp_HR_MedOrder_Approve CASCADE;
DROP FUNCTION IF EXISTS public.usp_HR_MedOrder_List CASCADE;
DROP FUNCTION IF EXISTS public.usp_HR_Training_Save CASCADE;
DROP FUNCTION IF EXISTS public.usp_HR_Training_List CASCADE;
DROP FUNCTION IF EXISTS public.usp_HR_Training_GetEmployeeCertifications CASCADE;
DROP FUNCTION IF EXISTS public.usp_HR_Committee_Save CASCADE;
DROP FUNCTION IF EXISTS public.usp_HR_Committee_AddMember CASCADE;
DROP FUNCTION IF EXISTS public.usp_HR_Committee_RemoveMember CASCADE;
DROP FUNCTION IF EXISTS public.usp_HR_Committee_RecordMeeting CASCADE;
DROP FUNCTION IF EXISTS public.usp_HR_Committee_List CASCADE;
DROP FUNCTION IF EXISTS public.usp_HR_Committee_GetMeetings CASCADE;
DROP FUNCTION IF EXISTS public.usp_HR_Payroll_ResolveScope CASCADE;
DROP FUNCTION IF EXISTS public.usp_HR_Payroll_ResolveUser CASCADE;
DROP TABLE IF EXISTS hr."ObligationFilingDetail" CASCADE;
DROP TABLE IF EXISTS hr."ObligationFiling" CASCADE;
DROP TABLE IF EXISTS hr."EmployeeObligation" CASCADE;
DROP TABLE IF EXISTS hr."ObligationRiskLevel" CASCADE;
DROP TABLE IF EXISTS hr."LegalObligation" CASCADE;
DROP TABLE IF EXISTS hr."SafetyCommitteeMeeting" CASCADE;
DROP TABLE IF EXISTS hr."SafetyCommitteeMember" CASCADE;
DROP TABLE IF EXISTS hr."SafetyCommittee" CASCADE;
DROP TABLE IF EXISTS hr."TrainingRecord" CASCADE;
DROP TABLE IF EXISTS hr."MedicalOrder" CASCADE;
DROP TABLE IF EXISTS hr."MedicalExam" CASCADE;
DROP TABLE IF EXISTS hr."OccupationalHealth" CASCADE;
DROP TABLE IF EXISTS hr."SavingsLoan" CASCADE;
DROP TABLE IF EXISTS hr."SavingsFundTransaction" CASCADE;
DROP TABLE IF EXISTS hr."SavingsFund" CASCADE;
DROP TABLE IF EXISTS hr."SocialBenefitsTrust" CASCADE;
DROP TABLE IF EXISTS hr."ProfitSharingLine" CASCADE;
DROP TABLE IF EXISTS hr."ProfitSharing" CASCADE;
