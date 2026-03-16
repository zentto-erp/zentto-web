SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET NOCOUNT ON;

BEGIN TRY
  BEGIN TRAN;

  IF COL_LENGTH('cfg.Country', 'TimeZoneIana') IS NULL
  BEGIN
    ALTER TABLE cfg.Country
      ADD TimeZoneIana NVARCHAR(64) NULL;
  END;

  IF COL_LENGTH('cfg.Country', 'TimeZoneIana') IS NOT NULL
  BEGIN
    EXEC(N'
      UPDATE cfg.Country
      SET TimeZoneIana = CASE UPPER(CountryCode)
        WHEN ''VE'' THEN N''America/Caracas''
        WHEN ''ES'' THEN N''Europe/Madrid''
        ELSE N''UTC''
      END
      WHERE TimeZoneIana IS NULL
         OR LTRIM(RTRIM(TimeZoneIana)) = N'''';
    ');
  END;

  COMMIT TRAN;
END TRY
BEGIN CATCH
  IF @@TRANCOUNT > 0
    ROLLBACK TRAN;
  THROW;
END CATCH;
