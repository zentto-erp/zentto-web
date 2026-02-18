-- =============================================
-- INSTALACIÓN COMPLETA DEL SISTEMA DE NÓMINA
-- Ejecutar en orden para crear todo el sistema
-- =============================================

PRINT 'Iniciando instalación del sistema de nómina...';
GO

-- 1. Funciones base y variables
:r sp_nomina_sistema.sql
GO

-- 2. Motor de cálculo
:r sp_nomina_calculo.sql
GO

-- 3. Vacaciones y liquidación
:r sp_nomina_vacaciones_liquidacion.sql
GO

-- 4. Consultas y listados
:r sp_nomina_consultas.sql
GO

PRINT 'Instalación completada exitosamente!';
GO

-- Verificar objetos creados
SELECT 'Funciones creadas:' as Verificacion, COUNT(*) as Total
FROM sys.objects 
WHERE type = 'FN' AND name LIKE 'fn_Nomina%';

SELECT 'Stored Procedures creados:' as Verificacion, COUNT(*) as Total  
FROM sys.objects 
WHERE type = 'P' AND name LIKE 'sp_Nomina%';

SELECT 'Tablas creadas:' as Verificacion, COUNT(*) as Total
FROM sys.tables 
WHERE name IN ('VariablesCalculadas');
GO
