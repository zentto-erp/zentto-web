-- =============================================
-- Seed: constantes de nomina (ConstanteNomina) y conceptos legales (NominaConceptoLegal)
-- Basado en LOTTT, CCT Petrolero, CCT Construccion y documentos tipo informe vacaciones / prestaciones.
-- Las formulas usan variables ya definidas en el sistema: SUELDO, SALARIO_DIARIO, SALARIO_INTEGRAL,
-- DIAS_VACACIONES, DIAS_BONO_VAC, VAC_INDUS, BONO_VAC, NORMAL, ANTI_TOTAL_MESES, TOTAL_ASIGNACIONES, etc.
-- =============================================

SET NOCOUNT ON;

-- Asegurar tabla ConstanteNomina (si no existe, crearla)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'ConstanteNomina')
BEGIN
    CREATE TABLE dbo.ConstanteNomina (
        Codigo  NVARCHAR(50) NOT NULL PRIMARY KEY,
        Nombre  NVARCHAR(150) NULL,
        Valor   FLOAT NULL,
        Origen  NVARCHAR(100) NULL
    );
    PRINT N'Tabla ConstanteNomina creada.';
END

-- Constantes comunes (LOTTT y deducciones)
MERGE dbo.ConstanteNomina AS t
USING (VALUES
    ('BaseUtil', N'Base utilidad % para salario integral', 0, N'LOTTT'),
    ('TECHOSSO', N'Techo SSO (salarios minimos)', 5, N'LOTTT'),
    ('PCT_SSO', N'Porcentaje SSO trabajador', 0.04, N'LOTTT'),
    ('PCT_FAOV', N'Porcentaje FAOV trabajador', 0.01, N'LOTTT'),
    ('PCT_LRPE', N'Porcentaje LRPE paro forzoso', 0.005, N'LOTTT'),
    ('PCT_INCE_UTIL', N'Porcentaje INCE sobre utilidades', 0.005, N'LOTTT'),
    ('DIAS_PRESTACION_ANIO', N'Dias prestaciones por ano', 30, N'LOTTT 142'),
    ('DIAS_PRESTACION_TRIM', N'Dias deposito trimestral', 15, N'LOTTT 142'),
    ('DIAS_VACACIONES_LOT', N'Dias vacaciones base (ley)', 15, N'LOTTT 189-203'),
    ('DIAS_BONO_VAC_LOT', N'Dias bono vacacional base (ley)', 15, N'LOTTT'),
    ('DIAS_VACACIONES_PETROLERO', N'Dias vacaciones CCT Petrolero', 34, N'CCP'),
    ('DIAS_BONO_VAC_PETROLERO', N'Dias bono vacacional CCT Petrolero', 55, N'CCP'),
    ('DIAS_BONO_POST_PETROLERO', N'Dias bono post-vacacional Petrolero', 15, N'CCP'),
    ('DIAS_UTILIDADES_PETROLERO', N'Dias utilidades base CCT Petrolero', 120, N'CCP'),
    ('DIAS_VACACIONES_CONSTRUCCION', N'Dias vacaciones CCT Construccion', 15, N'CCT Const'),
    ('DIAS_BONO_VAC_CONSTRUCCION', N'Dias bono vacacional CCT Construccion', 15, N'CCT Const')
) AS s(Codigo, Nombre, Valor, Origen)
ON t.Codigo = s.Codigo
WHEN NOT MATCHED THEN INSERT (Codigo, Nombre, Valor, Origen) VALUES (s.Codigo, s.Nombre, s.Valor, s.Origen)
WHEN MATCHED AND (t.Valor <> s.Valor OR t.Nombre <> s.Nombre) THEN UPDATE SET t.Nombre = s.Nombre, t.Valor = s.Valor, t.Origen = s.Origen;

PRINT N'ConstanteNomina: constantes legales actualizadas.';

-- Requiere NominaConceptoLegal (ejecutar antes create_nomina_convencion_conocimiento.sql)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'NominaConceptoLegal')
BEGIN
    PRINT N'Ejecutar antes create_nomina_convencion_conocimiento.sql';
    RETURN;
END

-- Limpiar seed previo de conceptos legales (opcional: comentar si quiere acumular)
-- DELETE FROM dbo.NominaConceptoLegal WHERE Convencion IN ('LOT','CCT_PETROLERO','CCT_CONSTRUCCION');

-- Conceptos: LOT - Nómina mensual (asignaciones y deducciones)
INSERT INTO dbo.NominaConceptoLegal (Convencion, TipoCalculo, CO_CONCEPT, NB_CONCEPTO, FORMULA, SOBRE, TIPO, BONIFICABLE, LOTTT_Articulo, Orden)
SELECT * FROM (VALUES
    ('LOT', 'MENSUAL', 'SUELDO', N'Sueldo base', 'SUELDO', NULL, 'ASIGNACION', 'S', NULL, 10),
    ('LOT', 'MENSUAL', 'SSO', N'Seguro Social Obligatorio', 'SUELDO * PCT_SSO', NULL, 'DEDUCCION', 'N', N'LOTTT', 100),
    ('LOT', 'MENSUAL', 'FAOV', N'FAOV 1%', 'SUELDO * PCT_FAOV', NULL, 'DEDUCCION', 'N', N'LOTTT', 101),
    ('LOT', 'MENSUAL', 'LRPE', N'LRPE Paro forzoso', 'SUELDO * PCT_LRPE', NULL, 'DEDUCCION', 'N', N'LOTTT', 102)
) AS v(Convencion, TipoCalculo, CO_CONCEPT, NB_CONCEPTO, FORMULA, SOBRE, TIPO, BONIFICABLE, LOTTT_Articulo, Orden)
WHERE NOT EXISTS (SELECT 1 FROM dbo.NominaConceptoLegal n WHERE n.Convencion = v.Convencion AND n.TipoCalculo = v.TipoCalculo AND n.CO_CONCEPT = v.CO_CONCEPT);

-- Conceptos: LOT - Vacaciones
INSERT INTO dbo.NominaConceptoLegal (Convencion, TipoCalculo, CO_CONCEPT, NB_CONCEPTO, FORMULA, SOBRE, TIPO, BONIFICABLE, LOTTT_Articulo, Orden)
SELECT * FROM (VALUES
    ('LOT', 'VACACIONES', 'VAC', N'Vacaciones', 'SALARIO_INTEGRAL', 'DIAS_VACACIONES', 'ASIGNACION', 'S', N'LOTTT 121', 10),
    ('LOT', 'VACACIONES', 'BONOVAC', N'Bono vacacional', 'SALARIO_INTEGRAL', 'DIAS_BONO_VAC', 'ASIGNACION', 'S', N'LOTTT', 11)
) AS v(Convencion, TipoCalculo, CO_CONCEPT, NB_CONCEPTO, FORMULA, SOBRE, TIPO, BONIFICABLE, LOTTT_Articulo, Orden)
WHERE NOT EXISTS (SELECT 1 FROM dbo.NominaConceptoLegal n WHERE n.Convencion = v.Convencion AND n.TipoCalculo = v.TipoCalculo AND n.CO_CONCEPT = v.CO_CONCEPT);

-- Conceptos: LOT - Liquidación (prestaciones, vacaciones no gozadas, utilidades)
INSERT INTO dbo.NominaConceptoLegal (Convencion, TipoCalculo, CO_CONCEPT, NB_CONCEPTO, FORMULA, SOBRE, TIPO, BONIFICABLE, LOTTT_Articulo, Orden)
SELECT * FROM (VALUES
    ('LOT', 'LIQUIDACION', 'PREST', N'Prestaciones sociales', 'SALARIO_INTEGRAL', '(ANTI_TOTAL_MESES / 12) * DIAS_PRESTACION_ANIO', 'ASIGNACION', 'N', N'LOTTT 142', 10),
    ('LOT', 'LIQUIDACION', 'VACLIQ', N'Vacaciones no gozadas', 'SALARIO_INTEGRAL', 'DIAS_VACACIONES', 'ASIGNACION', 'N', N'LOTTT 192', 11),
    ('LOT', 'LIQUIDACION', 'BONOVACLIQ', N'Bono vacacional liquidacion', 'SALARIO_INTEGRAL', 'DIAS_BONO_VAC', 'ASIGNACION', 'N', N'LOTTT', 12),
    ('LOT', 'LIQUIDACION', 'SSOLIQ', N'SSO liquidacion', 'TOTAL_ASIGNACIONES * PCT_SSO', NULL, 'DEDUCCION', 'N', N'LOTTT', 100),
    ('LOT', 'LIQUIDACION', 'FAOVLIQ', N'FAOV liquidacion', 'TOTAL_ASIGNACIONES * PCT_FAOV', NULL, 'DEDUCCION', 'N', N'LOTTT', 101)
) AS v(Convencion, TipoCalculo, CO_CONCEPT, NB_CONCEPTO, FORMULA, SOBRE, TIPO, BONIFICABLE, LOTTT_Articulo, Orden)
WHERE NOT EXISTS (SELECT 1 FROM dbo.NominaConceptoLegal n WHERE n.Convencion = v.Convencion AND n.TipoCalculo = v.TipoCalculo AND n.CO_CONCEPT = v.CO_CONCEPT);

-- Conceptos: CCT Petrolero - Vacaciones (dias mayores + bono post + TEA/vivienda)
INSERT INTO dbo.NominaConceptoLegal (Convencion, TipoCalculo, CO_CONCEPT, NB_CONCEPTO, FORMULA, SOBRE, TIPO, BONIFICABLE, LOTTT_Articulo, CCP_Clausula, Orden)
SELECT * FROM (VALUES
    ('CCT_PETROLERO', 'VACACIONES', 'VAC', N'Vacaciones', 'SALARIO_INTEGRAL', 'DIAS_VACACIONES', 'ASIGNACION', 'S', N'LOTTT 121', N'CCP', 10),
    ('CCT_PETROLERO', 'VACACIONES', 'VACAyu', N'Vacaciones ayuda', 'SALARIO_DIARIO', 'DIAS_VACACIONES * 1.62', 'ASIGNACION', 'S', N'LOTTT 157', N'CCP', 11),
    ('CCT_PETROLERO', 'VACACIONES', 'BONOVAC', N'Bono vacacional', 'SALARIO_INTEGRAL', 'DIAS_BONO_VAC', 'ASIGNACION', 'S', N'LOTTT', N'CCP', 12),
    ('CCT_PETROLERO', 'VACACIONES', 'BONOPOST', N'Bono post-vacacional', 'SALARIO_DIARIO', 'DIAS_BONO_POST_PETROLERO', 'ASIGNACION', 'S', N'LOTTT 157', N'CCP', 13)
) AS v(Convencion, TipoCalculo, CO_CONCEPT, NB_CONCEPTO, FORMULA, SOBRE, TIPO, BONIFICABLE, LOTTT_Articulo, CCP_Clausula, Orden)
WHERE NOT EXISTS (SELECT 1 FROM dbo.NominaConceptoLegal n WHERE n.Convencion = v.Convencion AND n.TipoCalculo = v.TipoCalculo AND n.CO_CONCEPT = v.CO_CONCEPT);

-- Conceptos: CCT Petrolero - Nómina mensual (deducciones igual que LOT; asignaciones pueden incluir TEA)
INSERT INTO dbo.NominaConceptoLegal (Convencion, TipoCalculo, CO_CONCEPT, NB_CONCEPTO, FORMULA, SOBRE, TIPO, BONIFICABLE, LOTTT_Articulo, CCP_Clausula, Orden)
SELECT * FROM (VALUES
    ('CCT_PETROLERO', 'MENSUAL', 'SUELDO', N'Sueldo base', 'SUELDO', NULL, 'ASIGNACION', 'S', NULL, NULL, 10),
    ('CCT_PETROLERO', 'MENSUAL', 'SSO', N'SSO 4%', 'SUELDO * PCT_SSO', NULL, 'DEDUCCION', 'N', N'LOTTT', NULL, 100),
    ('CCT_PETROLERO', 'MENSUAL', 'FAOV', N'FAOV 1%', 'SUELDO * PCT_FAOV', NULL, 'DEDUCCION', 'N', N'LOTTT', NULL, 101),
    ('CCT_PETROLERO', 'MENSUAL', 'LRPE', N'LRPE', 'SUELDO * PCT_LRPE', NULL, 'DEDUCCION', 'N', N'LOTTT', NULL, 102)
) AS v(Convencion, TipoCalculo, CO_CONCEPT, NB_CONCEPTO, FORMULA, SOBRE, TIPO, BONIFICABLE, LOTTT_Articulo, CCP_Clausula, Orden)
WHERE NOT EXISTS (SELECT 1 FROM dbo.NominaConceptoLegal n WHERE n.Convencion = v.Convencion AND n.TipoCalculo = v.TipoCalculo AND n.CO_CONCEPT = v.CO_CONCEPT);

-- Conceptos: CCT Construcción - alineado a LOT con posibles mejoras por cláusula
INSERT INTO dbo.NominaConceptoLegal (Convencion, TipoCalculo, CO_CONCEPT, NB_CONCEPTO, FORMULA, SOBRE, TIPO, BONIFICABLE, LOTTT_Articulo, CCP_Clausula, Orden)
SELECT * FROM (VALUES
    ('CCT_CONSTRUCCION', 'MENSUAL', 'SUELDO', N'Sueldo base', 'SUELDO', NULL, 'ASIGNACION', 'S', NULL, N'Cl 44', 10),
    ('CCT_CONSTRUCCION', 'MENSUAL', 'SSO', N'SSO', 'SUELDO * PCT_SSO', NULL, 'DEDUCCION', 'N', N'LOTTT', NULL, 100),
    ('CCT_CONSTRUCCION', 'MENSUAL', 'FAOV', N'FAOV', 'SUELDO * PCT_FAOV', NULL, 'DEDUCCION', 'N', N'LOTTT', NULL, 101),
    ('CCT_CONSTRUCCION', 'VACACIONES', 'VAC', N'Vacaciones', 'SALARIO_INTEGRAL', 'DIAS_VACACIONES', 'ASIGNACION', 'S', N'LOTTT 189-203', N'Cl 44', 10),
    ('CCT_CONSTRUCCION', 'VACACIONES', 'BONOVAC', N'Bono vacacional', 'SALARIO_INTEGRAL', 'DIAS_BONO_VAC', 'ASIGNACION', 'S', N'LOTTT', N'Cl 44', 11)
) AS v(Convencion, TipoCalculo, CO_CONCEPT, NB_CONCEPTO, FORMULA, SOBRE, TIPO, BONIFICABLE, LOTTT_Articulo, CCP_Clausula, Orden)
WHERE NOT EXISTS (SELECT 1 FROM dbo.NominaConceptoLegal n WHERE n.Convencion = v.Convencion AND n.TipoCalculo = v.TipoCalculo AND n.CO_CONCEPT = v.CO_CONCEPT);

PRINT N'NominaConceptoLegal: conceptos legales insertados.';
PRINT N'Fin seed_constantes_y_conceptos_legal.sql';
GO
