-- =============================================
-- Wrapper canonico: conocimiento nomina
-- Orquesta seeds canonicos en hr.PayrollConstant/hr.PayrollConcept
-- =============================================
SET NOCOUNT ON;
GO

:r ..\sp_nomina_constantes_venezuela.sql
:r ..\sp_nomina_constantes_convenios.sql

PRINT 'Nomina canonica: conocimiento base sembrado en hr.Payroll*';
GO
