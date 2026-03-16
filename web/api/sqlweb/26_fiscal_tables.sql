SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

USE DatqBoxWeb;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

/*
  Base fiscal multi-pais (Venezuela + Espana/Verifactu).
*/

:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\includes\sp\001_fiscal_multipais_base.sql
GO
