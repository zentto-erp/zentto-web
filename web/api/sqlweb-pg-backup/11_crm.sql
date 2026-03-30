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

DO $$ BEGIN RAISE NOTICE '>>> 11_crm.sql ejecutado correctamente <<<'; END $$;
