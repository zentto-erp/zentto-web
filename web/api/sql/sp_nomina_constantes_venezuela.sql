-- =============================================
-- SISTEMA DE CONSTANTES Y CONCEPTOS POR RÉGIMEN LABORAL VENEZOLANO
-- Compatible con: SQL Server 2012+
-- Basado en: LOTTT, Contrato Petrolero, Construcción
-- =============================================

-- =============================================
-- 1. TABLA: RegimenLaboral (Tipos de convenios)
-- =============================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'RegimenLaboral')
BEGIN
    CREATE TABLE RegimenLaboral (
        Codigo NVARCHAR(10) PRIMARY KEY,
        Nombre NVARCHAR(100) NOT NULL,
        Descripcion NVARCHAR(255),
        VigenciaDesde DATE,
        VigenciaHasta DATE,
        BaseLegal NVARCHAR(200), -- Artículos de ley o convenio
        Activo BIT DEFAULT 1
    );
    
    INSERT INTO RegimenLaboral (Codigo, Nombre, Descripcion, BaseLegal) VALUES
    ('LOT', 'Ley Orgánica del Trabajo', 'Régimen general LOTTT 2012', 'LOTTT Gaceta Extraordinaria N° 6.015 de 2012'),
    ('PETRO', 'Contrato Colectivo Petrolero', 'Sector petrolero PDVSA', 'CCT Petrolero 2019-2021'),
    ('CONST', 'Construcción', 'Sector construcción y obras', 'CCO Construcción Venezuela'),
    ('COMERC', 'Comercio', 'Sector comercial', 'Convenio Comercio Venezuela'),
    ('SALUD', 'Salud', 'Sector salud', 'Convenio Sector Salud'),
    ('INDUS', 'Industria General', 'Sector industrial', 'Convenio Industrial');
END
GO

-- =============================================
-- 2. TABLA: ConstantesNominaExtendida
-- Constantes por régimen con fórmulas y referencias legales
-- =============================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'ConstantesNominaExtendida')
BEGIN
    CREATE TABLE ConstantesNominaExtendida (
        ID INT IDENTITY(1,1) PRIMARY KEY,
        Codigo NVARCHAR(50) NOT NULL,
        Regimen NVARCHAR(10) NOT NULL DEFAULT 'LOT',
        Nombre NVARCHAR(100),
        Valor NVARCHAR(255), -- Puede ser número o fórmula
        TipoDato NVARCHAR(20) DEFAULT 'NUMERO', -- NUMERO, FORMULA, TEXTO
        Unidad NVARCHAR(20), -- DIAS, MESES, PORCENTAJE, MONTO
        Categoria NVARCHAR(50), -- VACACIONES, UTILIDADES, PRESTACIONES, DEDUCCIONES
        ArticuloLey NVARCHAR(100), -- Referencia legal
        Descripcion NVARCHAR(500),
        AplicaPorDefecto BIT DEFAULT 1,
        OrdenCalculo INT DEFAULT 0,
        CONSTRAINT UK_ConstNomExt UNIQUE (Codigo, Regimen)
    );
    
    CREATE INDEX IX_ConstRegimen ON ConstantesNominaExtendida(Regimen, Categoria);
    CREATE INDEX IX_ConstCodigo ON ConstantesNominaExtendida(Codigo);
END
GO

-- =============================================
-- 3. TABLA: ConceptosNominaRegimen
-- Conceptos por régimen con fórmulas específicas
-- =============================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'ConceptosNominaRegimen')
BEGIN
    CREATE TABLE ConceptosNominaRegimen (
        ID INT IDENTITY(1,1) PRIMARY KEY,
        CoConcepto NVARCHAR(10) NOT NULL,
        Regimen NVARCHAR(10) NOT NULL DEFAULT 'LOT',
        CoNomina NVARCHAR(15) NOT NULL DEFAULT 'MENSUAL',
        NbConcepto NVARCHAR(100),
        Formula NVARCHAR(500),
        Sobre NVARCHAR(255),
        Tipo NVARCHAR(15), -- ASIGNACION, DEDUCCION, BONO
        Clase NVARCHAR(15), -- FIJO, VARIABLE, FORMULA
        Categoria NVARCHAR(50),
        Bonificable BIT DEFAULT 0,
        ArticuloLey NVARCHAR(100),
        Descripcion NVARCHAR(500),
        Aplica BIT DEFAULT 1,
        OrdenCalculo INT DEFAULT 0,
        CONSTRAINT UK_ConcNomReg UNIQUE (CoConcepto, Regimen, CoNomina)
    );
    
    CREATE INDEX IX_ConcRegimen ON ConceptosNominaRegimen(Regimen, CoNomina, Tipo);
END
GO

-- =============================================
-- 4. INSERTAR CONSTANTES LOTTT (BASE LEGAL)
-- =============================================

-- VACACIONES LOTTT
INSERT INTO ConstantesNominaExtendida (Codigo, Regimen, Nombre, Valor, TipoDato, Unidad, Categoria, ArticuloLey, Descripcion, OrdenCalculo) VALUES
('VAC_DIAS_BASE', 'LOT', 'Días Vacaciones Base', '15', 'NUMERO', 'DIAS', 'VACACIONES', 'Art. 190 LOTTT', 'Vacaciones mínimas anuales', 10),
('VAC_DIAS_ADIC_ANIO', 'LOT', 'Días Adicional por Año', '1', 'NUMERO', 'DIAS', 'VACACIONES', 'Art. 190 LOTTT', 'Día adicional por cada año de servicio', 11),
('VAC_DIAS_MAX', 'LOT', 'Días Vacaciones Máximo', '30', 'NUMERO', 'DIAS', 'VACACIONES', 'Art. 190 LOTTT', 'Tope máximo de vacaciones', 12),
('BONO_VAC_DIAS', 'LOT', 'Días Bono Vacacional', '15', 'NUMERO', 'DIAS', 'VACACIONES', 'Art. 192 LOTTT', 'Bono vacacional mínimo', 20),
('BONO_VAC_ADIC_ANIO', 'LOT', 'Días Bono Vacacional Adicional', '1', 'NUMERO', 'DIAS', 'VACACIONES', 'Art. 192 LOTTT', 'Día adicional bono por año', 21),
('BONO_VAC_MAX', 'LOT', 'Días Bono Vacacional Máximo', '30', 'NUMERO', 'DIAS', 'VACACIONES', 'Art. 192 LOTTT', 'Tope bono vacacional', 22),
('VAC_FRACC_MES', 'LOT', 'Vacaciones Fracción por Mes', '1.25', 'NUMERO', 'DIAS', 'VACACIONES', 'Art. 190 LOTTT', 'Días de vacación por mes trabajado', 15),
('BONO_VAC_FRACC_MES', 'LOT', 'Bono Vacacional Fracción Mes', '1.25', 'NUMERO', 'DIAS', 'VACACIONES', 'Art. 192 LOTTT', 'Días bono vacacional por mes', 25);

-- UTILIDADES LOTTT
INSERT INTO ConstantesNominaExtendida (Codigo, Regimen, Nombre, Valor, TipoDato, Unidad, Categoria, ArticuloLey, Descripcion, OrdenCalculo) VALUES
('UTIL_DIAS_MIN', 'LOT', 'Días Utilidades Mínimo', '30', 'NUMERO', 'DIAS', 'UTILIDADES', 'Art. 131 LOTTT', 'Mínimo 30 días de utilidades', 30),
('UTIL_DIAS_MAX', 'LOT', 'Días Utilidades Máximo', '120', 'NUMERO', 'DIAS', 'UTILIDADES', 'Art. 131 LOTTT', 'Máximo 120 días de utilidades', 31),
('UTIL_BASE_SALARIO', 'LOT', 'Base Cálculo Utilidades', 'SALARIO_NORMAL', 'FORMULA', 'MONTO', 'UTILIDADES', 'Art. 131 LOTTT', 'Salario normal diario', 32);

-- PRESTACIONES LOTTT
INSERT INTO ConstantesNominaExtendida (Codigo, Regimen, Nombre, Valor, TipoDato, Unidad, Categoria, ArticuloLey, Descripcion, OrdenCalculo) VALUES
('PREST_DIAS_ANTIGUEDAD', 'LOT', 'Días Prestaciones por Año', '30', 'NUMERO', 'DIAS', 'PRESTACIONES', 'Art. 142 LOTTT', 'Días de salario por año de antigüedad', 40),
('PREST_TOPE_SALARIO', 'LOT', 'Tope Salario Integral', '10', 'NUMERO', 'MESES', 'PRESTACIONES', 'Art. 142 LOTTT', 'Tope de 10 meses de salario', 41),
('PREST_INTERES_ANUAL', 'LOT', 'Interés Anual Prestaciones', '0.04', 'NUMERO', 'PORCENTAJE', 'PRESTACIONES', 'Art. 142 LOTTT', '4% anual sobre prestaciones', 42),
('PREST_ANTICIPO_PORC', 'LOT', 'Porcentaje Anticipo', '0.75', 'NUMERO', 'PORCENTAJE', 'PRESTACIONES', 'Art. 144 LOTTT', '75% de anticipo de prestaciones', 43);

-- INDEMNIZACIÓN LOTTT
INSERT INTO ConstantesNominaExtendida (Codigo, Regimen, Nombre, Valor, TipoDato, Unidad, Categoria, ArticuloLey, Descripcion, OrdenCalculo) VALUES
('INDEMN_DIAS_ANIO_1', 'LOT', 'Indemnización Primer Año', '30', 'NUMERO', 'DIAS', 'PRESTACIONES', 'Art. 125 LOTTT', '30 días primer año antigüedad', 50),
('INDEMN_DIAS_ANIO_2', 'LOT', 'Indemnización Segundo Año', '20', 'NUMERO', 'DIAS', 'PRESTACIONES', 'Art. 125 LOTTT', '20 días segundo año antigüedad', 51),
('INDEMN_DIAS_ANIO_3', 'LOT', 'Indemnización Tercer Año', '15', 'NUMERO', 'DIAS', 'PRESTACIONES', 'Art. 125 LOTTT', '15 días tercer año antigüedad', 52),
('INDEMN_TOPE', 'LOT', 'Tope Indemnización', '5', 'NUMERO', 'MESES', 'PRESTACIONES', 'Art. 125 LOTTT', 'Máximo 5 meses de salario', 53);

-- PREAVISO LOTTT
INSERT INTO ConstantesNominaExtendida (Codigo, Regimen, Nombre, Valor, TipoDato, Unidad, Categoria, ArticuloLey, Descripcion, OrdenCalculo) VALUES
('PREAVISO_MENOS_6M', 'LOT', 'Preaviso Menos 6 Meses', '7', 'NUMERO', 'DIAS', 'PRESTACIONES', 'Art. 162 LOTTT', '7 días de preaviso', 60),
('PREAVISO_6M_A_1A', 'LOT', 'Preaviso 6 Meses a 1 Año', '15', 'NUMERO', 'DIAS', 'PRESTACIONES', 'Art. 162 LOTTT', '15 días de preaviso', 61),
('PREAVISO_MAS_1A', 'LOT', 'Preaviso Más 1 Año', '30', 'NUMERO', 'DIAS', 'PRESTACIONES', 'Art. 162 LOTTT', '30 días de preaviso', 62);

-- DEDUCCIONES LOTTT
INSERT INTO ConstantesNominaExtendida (Codigo, Regimen, Nombre, Valor, TipoDato, Unidad, Categoria, ArticuloLey, Descripcion, OrdenCalculo) VALUES
('SSO_PORC_EMPLEADO', 'LOT', 'SSO % Empleado', '0.04', 'NUMERO', 'PORCENTAJE', 'DEDUCCIONES', 'Art. 203 LOTTT', '4% SSO a cargo del trabajador', 70),
('SSO_TOPE_SALARIO', 'LOT', 'SSO Tope Salario', '5', 'NUMERO', 'SUELDO_MIN', 'DEDUCCIONES', 'Art. 203 LOTTT', 'Tope de 5 sueldos mínimos', 71),
('FAOV_PORC_EMPLEADO', 'LOT', 'FAOV % Empleado', '0.01', 'NUMERO', 'PORCENTAJE', 'DEDUCCIONES', 'Art. 203 LOTTT', '1% FAOV a cargo del trabajador', 72),
('LRPE_PORC_EMPLEADO', 'LOT', 'LRPE % Empleado', '0.005', 'NUMERO', 'PORCENTAJE', 'DEDUCCIONES', 'Art. 203 LOTTT', '0.5% LRPE paro forzoso', 73),
('INCE_PORC_EMPLEADO', 'LOT', 'INCE % Empleado', '0.005', 'NUMERO', 'PORCENTAJE', 'DEDUCCIONES', 'Art. 203 LOTTT', '0.5% INCE', 74);

-- JORNADA LOTTT
INSERT INTO ConstantesNominaExtendida (Codigo, Regimen, Nombre, Valor, TipoDato, Unidad, Categoria, ArticuloLey, Descripcion, OrdenCalculo) VALUES
('JOR_SEMANAL_HORAS', 'LOT', 'Jornada Semanal Horas', '40', 'NUMERO', 'HORAS', 'JORNADA', 'Art. 174 LOTTT', '40 horas semanales', 80),
('JOR_DIARIA_HORAS', 'LOT', 'Jornada Diaria Horas', '8', 'NUMERO', 'HORAS', 'JORNADA', 'Art. 174 LOTTT', '8 horas diarias', 81),
('JOR_MENSUAL_HORAS', 'LOT', 'Jornada Mensual Horas', '240', 'NUMERO', 'HORAS', 'JORNADA', 'Art. 174 LOTTT', '240 horas mensuales', 82),
('RECARGO_NOCTURNO', 'LOT', 'Recargo Nocturno %', '0.30', 'NUMERO', 'PORCENTAJE', 'JORNADA', 'Art. 118 LOTTT', '30% recargo hora nocturna', 83),
('RECARGO_DF', 'LOT', 'Recargo Descanso Feriado %', '0.50', 'NUMERO', 'PORCENTAJE', 'JORNADA', 'Art. 119 LOTTT', '50% recargo día feriado', 84),
('RECARGO_EXTRAS_DIURNAS', 'LOT', 'Recargo H.E. Diurnas %', '0.50', 'NUMERO', 'PORCENTAJE', 'JORNADA', 'Art. 118 LOTTT', '50% horas extras diurnas', 85),
('RECARGO_EXTRAS_NOCTURNAS', 'LOT', 'Recargo H.E. Nocturnas %', '1.00', 'NUMERO', 'PORCENTAJE', 'JORNADA', 'Art. 118 LOTTT', '100% horas extras nocturnas', 86);

GO

PRINT 'Constantes LOTTT insertadas';
GO
