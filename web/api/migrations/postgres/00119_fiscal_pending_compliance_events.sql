-- +goose Up

-- VENEZUELA - Cola local de eventos de compliance SENIAT pendientes de enviar.
-- Usada por venezuela-compliance.adapter.ts cuando el microservicio
-- zentto-seniat-compliance esta offline o hay error de red.
-- Un worker async del ERP la procesa y reintenta con backoff.

-- +goose StatementBegin
CREATE TABLE IF NOT EXISTS fiscal."PendingComplianceEvent" (
  "PendingId"      BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  "CompanyId"      INTEGER NOT NULL,
  "RifEmisor"      VARCHAR(15) NOT NULL,
  "EventType"      VARCHAR(40) NOT NULL,
  "ReferenceType"  VARCHAR(30),
  "ReferenceId"    VARCHAR(100),
  "PayloadJson"    JSONB NOT NULL,
  "OccurredAt"     TIMESTAMP NOT NULL,
  "Attempts"       INTEGER NOT NULL DEFAULT 0,
  "NextAttemptAt"  TIMESTAMP NOT NULL DEFAULT NOW(),
  "LastError"      TEXT,
  "Status"         VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    -- PENDING | SENT | ABANDONED
  "SentAt"         TIMESTAMP,
  "CreatedAt"      TIMESTAMP NOT NULL DEFAULT NOW(),
  "UpdatedAt"      TIMESTAMP NOT NULL DEFAULT NOW()
);
-- +goose StatementEnd

-- +goose StatementBegin
CREATE INDEX IF NOT EXISTS "IX_PendingCompliance_Next"
  ON fiscal."PendingComplianceEvent"("Status", "NextAttemptAt")
  WHERE "Status" = 'PENDING';
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
DROP TABLE IF EXISTS fiscal."PendingComplianceEvent";
-- +goose StatementEnd
