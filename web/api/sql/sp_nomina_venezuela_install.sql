-- =============================================
-- INSTALACIÓN COMPLETA SISTEMA NÓMINA VENEZUELA
-- Compatible con: SQL Server 2012+
-- =============================================

PRINT '============================================================';
PRINT 'INSTALACIÓN SISTEMA DE NÓMINA VENEZUELA - DATQBOX';
PRINT '============================================================';
PRINT 'Iniciando: ' + CONVERT(NVARCHAR, GETDATE(), 120);
PRINT '';
GO

-- =============================================
-- 1. VERIFICAR Y CREAR TABLAS EXISTENTES
-- =============================================

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'VariablesCalculadas')
BEGIN
    PRINT 'Creando tabla VariablesCalculadas...';
    CREATE TABLE VariablesCalculadas (
        ID INT IDENTITY(1,1) PRIMARY KEY,
        SessionID NVARCHAR(50) NOT NULL,
        Variable NVARCHAR(50) NOT NULL,
        Valor DECIMAL(18,4) NULL,
        Descripcion NVARCHAR(100) NULL,
        FechaReg DATETIME DEFAULT GETDATE()
    );
    CREATE INDEX IX_Variables_Session ON VariablesCalculadas(SessionID, Variable);
END
ELSE
    PRINT 'Tabla VariablesCalculadas ya existe.';
GO

-- =============================================
-- 2. CREAR NUEVAS TABLAS DE RÉGIMEN
-- =============================================

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'RegimenLaboral')
BEGIN
    PRINT 'Creando tabla RegimenLaboral...';
    CREATE TABLE RegimenLaboral (
        Codigo NVARCHAR(10) PRIMARY KEY,
        Nombre NVARCHAR(100) NOT NULL,
        Descripcion NVARCHAR(255),
        VigenciaDesde DATE,
        VigenciaHasta DATE,
        BaseLegal NVARCHAR(200),
        Activo BIT DEFAULT 1
    );
END
ELSE
    PRINT 'Tabla RegimenLaboral ya existe.';
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'ConstantesNominaExtendida')
BEGIN
    PRINT 'Creando tabla ConstantesNominaExtendida...';
    CREATE TABLE ConstantesNominaExtendida (
        ID INT IDENTITY(1,1) PRIMARY KEY,
        Codigo NVARCHAR(50) NOT NULL,
        Regimen NVARCHAR(10) NOT NULL DEFAULT 'LOT',
        Nombre NVARCHAR(100),
        Valor NVARCHAR(255),
        TipoDato NVARCHAR(20) DEFAULT 'NUMERO',
        Unidad NVARCHAR(20),
        Categoria NVARCHAR(50),
        ArticuloLey NVARCHAR(100),
        Descripcion NVARCHAR(500),
        AplicaPorDefecto BIT DEFAULT 1,
        OrdenCalculo INT DEFAULT 0,
        CONSTRAINT UK_ConstNomExt UNIQUE (Codigo, Regimen)
    );
    CREATE INDEX IX_ConstRegimen ON ConstantesNominaExtendida(Regimen, Categoria);
END
ELSE
    PRINT 'Tabla ConstantesNominaExtendida ya existe.';
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'ConceptosNominaRegimen')
BEGIN
    PRINT 'Creando tabla ConceptosNominaRegimen...';
    CREATE TABLE ConceptosNominaRegimen (
        ID INT IDENTITY(1,1) PRIMARY KEY,
        CoConcepto NVARCHAR(10) NOT NULL,
        Regimen NVARCHAR(10) NOT NULL DEFAULT 'LOT',
        CoNomina NVARCHAR(15) NOT NULL DEFAULT 'MENSUAL',
        NbConcepto NVARCHAR(100),
        Formula NVARCHAR(500),
        Sobre NVARCHAR(255),
        Tipo NVARCHAR(15),
        Clase NVARCHAR(15),
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
ELSE
    PRINT 'Tabla ConceptosNominaRegimen ya existe.';
GO

-- =============================================
-- 3. INSERTAR RÉGIMENES LABORALES
-- =============================================

PRINT '';
PRINT 'Insertando regímenes laborales...';

MERGE INTO RegimenLaboral AS target
USING (VALUES
    ('LOT', 'Ley Orgánica del Trabajo', 'Régimen general LOTTT 2012', 'LOTTT Gaceta Extraordinaria N° 6.015 de 2012', NULL, NULL, 1),
    ('PETRO', 'Contrato Colectivo Petrolero', 'Sector petrolero PDVSA', 'CCT Petrolero 2019-2021', '2019-01-01', '2021-12-31', 1),
    ('CONST', 'Construcción', 'Sector construcción y obras', 'CCO Construcción Venezuela', NULL, NULL, 1),
    ('COMERC', 'Comercio', 'Sector comercial', 'Convenio Comercio Venezuela', NULL, NULL, 1),
    ('SALUD', 'Salud', 'Sector salud', 'Convenio Sector Salud', NULL, NULL, 1),
    ('INDUS', 'Industria General', 'Sector industrial', 'Convenio Industrial', NULL, NULL, 1)
) AS source (Codigo, Nombre, Descripcion, BaseLegal, VigenciaDesde, VigenciaHasta, Activo)
ON target.Codigo = source.Codigo
WHEN MATCHED THEN
    UPDATE SET Nombre = source.Nombre, Descripcion = source.Descripcion, BaseLegal = source.BaseLegal
WHEN NOT MATCHED THEN
    INSERT (Codigo, Nombre, Descripcion, BaseLegal, VigenciaDesde, VigenciaHasta, Activo)
    VALUES (source.Codigo, source.Nombre, source.Descripcion, source.BaseLegal, source.VigenciaDesde, source.VigenciaHasta, source.Activo);

PRINT 'Regímenes insertados/actualizados.';
GO

-- =============================================
-- 4. FUNCIONES Y SPs AUXILIARES (SIMPLIFICADOS)
-- =============================================

-- Función para contar feriados
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'FN' AND name = 'fn_Nomina_ContarFeriados')
    DROP FUNCTION fn_Nomina_ContarFeriados
GO

CREATE FUNCTION fn_Nomina_ContarFeriados(@FechaDesde DATE, @FechaHasta DATE)
RETURNS INT
AS
BEGIN
    DECLARE @Count INT
    SELECT @Count = COUNT(*) FROM Feriados WHERE Fecha >= @FechaDesde AND Fecha <= @FechaHasta
    RETURN ISNULL(@Count, 0)
END
GO

-- Función para contar domingos
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'FN' AND name = 'fn_Nomina_ContarDomingos')
    DROP FUNCTION fn_Nomina_ContarDomingos
GO

CREATE FUNCTION fn_Nomina_ContarDomingos(@FechaDesde DATE, @FechaHasta DATE)
RETURNS INT
AS
BEGIN
    DECLARE @Count INT = 0, @Current DATE = @FechaDesde
    WHILE @Current <= @FechaHasta
    BEGIN
        IF DATEPART(WEEKDAY, @Current) = 1 SET @Count = @Count + 1
        SET @Current = DATEADD(DAY, 1, @Current)
    END
    RETURN @Count
END
GO

-- SP para limpiar variables
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_Nomina_LimpiarVariables')
    DROP PROCEDURE sp_Nomina_LimpiarVariables
GO

CREATE PROCEDURE sp_Nomina_LimpiarVariables @SessionID NVARCHAR(50)
AS DELETE FROM VariablesCalculadas WHERE SessionID = @SessionID;
GO

-- SP para guardar variable
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_Nomina_SetVariable')
    DROP PROCEDURE sp_Nomina_SetVariable
GO

CREATE PROCEDURE sp_Nomina_SetVariable 
    @SessionID NVARCHAR(50), @Variable NVARCHAR(50), @Valor DECIMAL(18,4), @Descripcion NVARCHAR(100) = NULL
AS
BEGIN
    DELETE FROM VariablesCalculadas WHERE SessionID = @SessionID AND Variable = @Variable;
    INSERT INTO VariablesCalculadas (SessionID, Variable, Valor, Descripcion) VALUES (@SessionID, @Variable, @Valor, @Descripcion);
END
GO

-- SP para calcular antigüedad
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_Nomina_CalcularAntiguedad')
    DROP PROCEDURE sp_Nomina_CalcularAntiguedad
GO

CREATE PROCEDURE sp_Nomina_CalcularAntiguedad
    @SessionID NVARCHAR(50), @Cedula NVARCHAR(12), @FechaCalculo DATE = NULL
AS
BEGIN
    IF @FechaCalculo IS NULL SET @FechaCalculo = GETDATE();
    DECLARE @FechaIngreso DATE, @Dias INT, @Anios INT, @Meses INT, @TotalMeses INT;
    SELECT @FechaIngreso = INGRESO FROM Empleados WHERE CEDULA = @Cedula;
    
    IF @FechaIngreso IS NULL
    BEGIN
        EXEC sp_Nomina_SetVariable @SessionID, 'ANTI_ANIOS', 0, 'Años';
        EXEC sp_Nomina_SetVariable @SessionID, 'ANTI_MESES', 0, 'Meses';
        EXEC sp_Nomina_SetVariable @SessionID, 'ANTI_TOTAL_MESES', 0, 'Total meses';
        RETURN;
    END
    
    SET @Dias = DATEDIFF(DAY, @FechaIngreso, @FechaCalculo);
    SET @Anios = @Dias / 365;
    SET @Meses = (@Dias % 365) / 30;
    SET @TotalMeses = DATEDIFF(MONTH, @FechaIngreso, @FechaCalculo);
    
    EXEC sp_Nomina_SetVariable @SessionID, 'ANTI_ANIOS', @Anios, 'Años antigüedad';
    EXEC sp_Nomina_SetVariable @SessionID, 'ANTI_MESES', @Meses, 'Meses antigüedad';
    EXEC sp_Nomina_SetVariable @SessionID, 'ANTI_TOTAL_MESES', @TotalMeses, 'Total meses';
    
    -- Cargar valores de tabla Antiguedad si existen
    DECLARE @MesesAntiguedad INT;
    SELECT TOP 1 @MesesAntiguedad = MESES FROM Antiguedad WHERE MESES <= @TotalMeses ORDER BY MESES DESC;
    
    IF @MesesAntiguedad IS NOT NULL
    BEGIN
        DECLARE @Preaviso INT, @Legal FLOAT, @VacIndus FLOAT, @BonoVac FLOAT, @Normal FLOAT;
        SELECT @Preaviso = PREAVISO, @Legal = LEGAL, @VacIndus = VAC_INDUS, @BonoVac = BONO_VAC, @Normal = NORMAL
        FROM Antiguedad WHERE MESES = @MesesAntiguedad;
        
        EXEC sp_Nomina_SetVariable @SessionID, 'PREAVISO', @Preaviso, 'Días preaviso';
        EXEC sp_Nomina_SetVariable @SessionID, 'LEGAL', @Legal, 'Días legal';
        EXEC sp_Nomina_SetVariable @SessionID, 'VAC_INDUS', @VacIndus, 'Vacaciones industriales';
        EXEC sp_Nomina_SetVariable @SessionID, 'BONO_VAC', @BonoVac, 'Bono vacacional';
        EXEC sp_Nomina_SetVariable @SessionID, 'NORMAL', @Normal, 'Vacaciones normales';
    END
END
GO

PRINT 'Funciones auxiliares creadas.';
GO

-- =============================================
-- 5. CONTINUAR CON SCRIPTS ESPECÍFICOS
-- =============================================

PRINT '';
PRINT '============================================================';
PRINT 'Para completar la instalación, ejecutar los siguientes scripts:';
PRINT '============================================================';
PRINT '1. sp_nomina_constantes_venezuela.sql - Constantes LOTTT base';
PRINT '2. sp_nomina_constantes_convenios.sql - Constantes CCT Petrolero y Construcción';
PRINT '3. sp_nomina_calculo_regimen.sql - Motor de cálculo con régimen';
PRINT '4. sp_nomina_calculo.sql - Procesamiento de nómina';
PRINT '5. sp_nomina_vacaciones_liquidacion.sql - Vacaciones y liquidación';
PRINT '';
PRINT 'O ejecutar todo con:';
PRINT '  :r sp_nomina_constantes_venezuela.sql';
PRINT '  :r sp_nomina_constantes_convenios.sql';
PRINT '  :r sp_nomina_calculo_regimen.sql';
PRINT '============================================================';
GO

-- Resumen de verificación
SELECT 'Regímenes configurados' as Item, COUNT(*) as Total FROM RegimenLaboral WHERE Activo = 1
UNION ALL
SELECT 'Constantes LOT', COUNT(*) FROM ConstantesNominaExtendida WHERE Regimen = 'LOT'
UNION ALL
SELECT 'Constantes Petrolero', COUNT(*) FROM ConstantesNominaExtendida WHERE Regimen = 'PETRO'
UNION ALL
SELECT 'Constantes Construcción', COUNT(*) FROM ConstantesNominaExtendida WHERE Regimen = 'CONST'
UNION ALL
SELECT 'Conceptos configurados', COUNT(*) FROM ConceptosNominaRegimen;
GO

PRINT '';
PRINT 'Instalación base completada: ' + CONVERT(NVARCHAR, GETDATE(), 120);
GO
