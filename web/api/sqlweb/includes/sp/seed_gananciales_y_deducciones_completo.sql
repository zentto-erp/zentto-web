-- =============================================
-- Wrapper canonico: gananciales/deducciones
-- Este flujo ahora se centraliza en el seed canonico de convenios.
-- =============================================
SET NOCOUNT ON;
GO

:r ..\sp_nomina_constantes_venezuela.sql
:r ..\sp_nomina_constantes_convenios.sql

PRINT 'Gananciales/deducciones canonicos actualizados en hr.PayrollConcept';
GO
