-- =============================================================================
-- ALTER: Agregar JournalEntryId a fin.BankMovement (SQL Server)
-- Permite vincular movimientos bancarios con asientos contables autogenerados.
-- =============================================================================

IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID('fin.BankMovement')
      AND name = 'JournalEntryId'
)
BEGIN
    ALTER TABLE fin.BankMovement
        ADD JournalEntryId BIGINT NULL;

    ALTER TABLE fin.BankMovement
        ADD CONSTRAINT FK_fin_BankMovement_JournalEntry
        FOREIGN KEY (JournalEntryId)
        REFERENCES acct.JournalEntry(JournalEntryId);

    CREATE NONCLUSTERED INDEX IX_fin_BankMovement_JournalEntry
        ON fin.BankMovement (JournalEntryId)
        WHERE JournalEntryId IS NOT NULL;
END;
GO
