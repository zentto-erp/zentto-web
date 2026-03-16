SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET NOCOUNT ON;

BEGIN TRY
  BEGIN TRAN;

  IF COL_LENGTH('cfg.Branch', 'CountryCode') IS NULL
  BEGIN
    EXEC(N'ALTER TABLE cfg.Branch ADD CountryCode CHAR(2) NULL;');
  END;

  IF COL_LENGTH('cfg.Branch', 'CountryCode') IS NOT NULL
  BEGIN
    EXEC(N'
      UPDATE b
      SET b.CountryCode = c.FiscalCountryCode
      FROM cfg.Branch b
      INNER JOIN cfg.Company c
        ON c.CompanyId = b.CompanyId
      WHERE (b.CountryCode IS NULL OR LTRIM(RTRIM(b.CountryCode)) = '''')
        AND c.FiscalCountryCode IS NOT NULL;
    ');
  END;

  IF COL_LENGTH('cfg.Branch', 'CountryCode') IS NOT NULL
     AND NOT EXISTS (
      SELECT 1
      FROM sys.foreign_keys
      WHERE name = 'FK_cfg_Branch_Country'
    )
  BEGIN
    EXEC(N'
      ALTER TABLE cfg.Branch WITH CHECK
        ADD CONSTRAINT FK_cfg_Branch_Country
        FOREIGN KEY (CountryCode) REFERENCES cfg.Country(CountryCode);
    ');
  END;

  IF COL_LENGTH('cfg.Branch', 'CountryCode') IS NOT NULL
     AND NOT EXISTS (
      SELECT 1
      FROM sys.indexes
      WHERE name = 'IX_cfg_Branch_CountryCode'
        AND object_id = OBJECT_ID('cfg.Branch')
    )
  BEGIN
    EXEC(N'CREATE INDEX IX_cfg_Branch_CountryCode ON cfg.Branch (CountryCode);');
  END;

  COMMIT TRAN;
END TRY
BEGIN CATCH
  IF @@TRANCOUNT > 0
    ROLLBACK TRAN;
  THROW;
END CATCH;
