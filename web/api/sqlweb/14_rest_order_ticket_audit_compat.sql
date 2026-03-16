SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

USE DatqBoxWeb;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

BEGIN TRY
  BEGIN TRAN;

  IF OBJECT_ID(N'rest.OrderTicket', N'U') IS NOT NULL
  BEGIN
    IF COL_LENGTH(N'rest.OrderTicket', N'CreatedAt') IS NULL
    BEGIN
      ALTER TABLE rest.OrderTicket
      ADD CreatedAt DATETIME2(0) NOT NULL
      CONSTRAINT DF_rest_OrderTicket_CreatedAt DEFAULT SYSUTCDATETIME();
    END;

    IF COL_LENGTH(N'rest.OrderTicket', N'UpdatedAt') IS NULL
    BEGIN
      ALTER TABLE rest.OrderTicket
      ADD UpdatedAt DATETIME2(0) NOT NULL
      CONSTRAINT DF_rest_OrderTicket_UpdatedAt DEFAULT SYSUTCDATETIME();
    END;
  END;

  IF OBJECT_ID(N'rest.OrderTicketLine', N'U') IS NOT NULL
  BEGIN
    IF COL_LENGTH(N'rest.OrderTicketLine', N'CreatedAt') IS NULL
    BEGIN
      ALTER TABLE rest.OrderTicketLine
      ADD CreatedAt DATETIME2(0) NOT NULL
      CONSTRAINT DF_rest_OrderTicketLine_CreatedAt DEFAULT SYSUTCDATETIME();
    END;

    IF COL_LENGTH(N'rest.OrderTicketLine', N'UpdatedAt') IS NULL
    BEGIN
      ALTER TABLE rest.OrderTicketLine
      ADD UpdatedAt DATETIME2(0) NOT NULL
      CONSTRAINT DF_rest_OrderTicketLine_UpdatedAt DEFAULT SYSUTCDATETIME();
    END;
  END;

  COMMIT TRAN;
END TRY
BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRAN;
  THROW;
END CATCH;
GO
