-- =============================================================================
-- ALTER: Agregar JournalEntryId a fin.BankMovement (PostgreSQL)
-- Permite vincular movimientos bancarios con asientos contables autogenerados.
-- =============================================================================

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
