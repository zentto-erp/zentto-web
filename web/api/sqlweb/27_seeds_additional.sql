SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

USE DatqBoxWeb;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

/*
  Seeds adicionales: plan de cuentas, contabilidad,
  restaurante, nomina legal.
*/

:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\includes\sp\seed_account_plan.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\includes\sp\seed_contabilidad.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\includes\sp\seed_restaurante_componentes_recetas.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\includes\sp\seed_restaurante_menu_extra.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\includes\sp\seed_constantes_y_conceptos_legal.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\includes\sp\seed_gananciales_y_deducciones_completo.sql
GO
