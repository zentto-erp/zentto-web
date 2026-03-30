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
