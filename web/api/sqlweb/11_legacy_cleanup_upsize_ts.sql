SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

USE DatqBoxWeb;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

/* Remueve upsize_ts en cualquier tabla creada por compat legacy. */
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\includes\46_remove_upsize_ts_all_tables.sql
GO

