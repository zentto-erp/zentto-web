SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

USE DatqBoxWeb;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

/*
  Contabilidad general: tablas nucleares, SPs y bridge POS-restaurante.
*/

:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\includes\sp\create_contabilidad_general.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\includes\sp\sp_contabilidad_general.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\includes\sp\alter_pos_restaurante_contabilidad_bridge.sql
GO
