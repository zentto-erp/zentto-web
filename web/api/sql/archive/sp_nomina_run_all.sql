-- =============================================
-- INSTALACIÓN COMPLETA NÓMINA (CANÓNICO)
-- Ejecutar con sqlcmd desde carpeta web/api/sql
-- =============================================

PRINT 'Iniciando instalación canónica de nómina...';
GO

:r sp_nomina_sistema.sql
GO
:r sp_nomina_constantes_venezuela.sql
GO
:r sp_nomina_constantes_convenios.sql
GO
:r sp_nomina_calculo.sql
GO
:r sp_nomina_calculo_regimen.sql
GO
:r sp_nomina_conceptolegal_adapter.sql
GO
:r sp_nomina_vacaciones_liquidacion.sql
GO
:r sp_nomina_consultas.sql
GO
:r sp_nomina_venezuela_install.sql
GO

PRINT 'Instalación canónica completada.';
GO

SELECT 'SP Nomina' AS Objeto, COUNT(1) AS Total
FROM sys.procedures
WHERE name LIKE 'sp_Nomina%'
UNION ALL
SELECT 'FN Nomina', COUNT(1)
FROM sys.objects
WHERE type = 'FN' AND name LIKE 'fn_Nomina%'
UNION ALL
SELECT 'Tablas hr nomina', COUNT(1)
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
WHERE s.name = 'hr' AND t.name IN (
  'PayrollType','PayrollConstant','PayrollConcept','PayrollRun','PayrollRunLine',
  'VacationProcess','VacationProcessLine','SettlementProcess','SettlementProcessLine','PayrollCalcVariable'
);
GO
