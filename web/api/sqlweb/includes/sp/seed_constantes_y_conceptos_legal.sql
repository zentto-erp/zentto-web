-- =============================================
-- Wrapper canonico: constantes + conceptos legales
-- =============================================
SET NOCOUNT ON;
GO

:r ..\sp_nomina_constantes_venezuela.sql
:r ..\sp_nomina_constantes_convenios.sql

PRINT 'Seed canonico aplicado: hr.PayrollConstant + hr.PayrollConcept';
GO
