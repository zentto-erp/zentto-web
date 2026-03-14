SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

USE DatqBoxWeb;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

/*
  Tablas adicionales: cierre inventario, supervisor, pasarela pagos,
  settings, indices de optimizacion.
*/

:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\includes\sp\create_cierre_mensual_inventario.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\includes\sp\create_supervisor_biometric_credentials.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\includes\sp\create_supervisor_override_controls.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\includes\sp\payment_gateway_tables.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\includes\sp\settings_table.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\includes\sp\add_indexes_inventario_cierre.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\includes\sp\fulltext_index_inventario.sql
GO
