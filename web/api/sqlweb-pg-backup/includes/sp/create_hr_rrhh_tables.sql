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
