-- +goose Up

-- VENEZUELA — Columnas de seguimiento SENIAT Digital en fiscal.Record
-- Opt-in por tenant via cfg.AppSetting("seniat.digitalEnabled" = "true").
-- Si el micro zentto-imprenta-seniat esta offline, estas columnas quedan NULL y el ERP sigue operando normal.

-- +goose StatementBegin
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'fiscal' AND table_name = 'Record') THEN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='fiscal' AND table_name='Record' AND column_name='SeniatDigitalStatus') THEN
      ALTER TABLE fiscal."Record" ADD COLUMN "SeniatDigitalStatus" VARCHAR(20);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='fiscal' AND table_name='Record' AND column_name='SeniatNCFD') THEN
      ALTER TABLE fiscal."Record" ADD COLUMN "SeniatNCFD" VARCHAR(40);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='fiscal' AND table_name='Record' AND column_name='SeniatDispatchedAt') THEN
      ALTER TABLE fiscal."Record" ADD COLUMN "SeniatDispatchedAt" TIMESTAMP;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='fiscal' AND table_name='Record' AND column_name='SeniatLastError') THEN
      ALTER TABLE fiscal."Record" ADD COLUMN "SeniatLastError" TEXT;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='fiscal' AND table_name='Record' AND column_name='SeniatImprentaInvoiceId') THEN
      ALTER TABLE fiscal."Record" ADD COLUMN "SeniatImprentaInvoiceId" BIGINT;
    END IF;
  END IF;
END $$;
-- +goose StatementEnd

-- Cola de pendientes por si el micro esta offline
-- +goose StatementBegin
CREATE TABLE IF NOT EXISTS fiscal."PendingSeniatReceipt" (
  "PendingId"      BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  "CompanyId"      INTEGER NOT NULL,
  "DocumentId"     BIGINT,
  "PayloadJson"    JSONB NOT NULL,
  "Attempts"       INTEGER NOT NULL DEFAULT 0,
  "NextAttemptAt"  TIMESTAMP NOT NULL DEFAULT NOW(),
  "LastError"      TEXT,
  "Status"         VARCHAR(20) NOT NULL DEFAULT 'PENDING',
  "CreatedAt"      TIMESTAMP NOT NULL DEFAULT NOW(),
  "UpdatedAt"      TIMESTAMP NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS "IX_PendingSeniat_Next" ON fiscal."PendingSeniatReceipt"("Status","NextAttemptAt");
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
DROP TABLE IF EXISTS fiscal."PendingSeniatReceipt";
-- +goose StatementEnd
