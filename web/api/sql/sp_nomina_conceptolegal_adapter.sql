-- =============================================
-- ADAPTADOR PARA NOMINACONCEPTOLEGAL
-- Integra el sistema con la tabla existente del usuario
-- Compatible con: SQL Server 2012+
-- =============================================

PRINT '============================================================';
PRINT 'ADAPTADOR NOMINACONCEPTOLEGAL';
PRINT '============================================================';
GO

-- =============================================
-- 1. VERIFICAR ESTRUCTURA DE TABLA EXISTENTE
-- =============================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'NominaConceptoLegal')
BEGIN
    RAISERROR('ERROR: La tabla NominaConceptoLegal no existe. Abortando.', 16, 1);
    RETURN;
END

PRINT 'Tabla NominaConceptoLegal encontrada.';

-- Verificar columnas clave
DECLARE @Cols TABLE (ColName NVARCHAR(100));
INSERT INTO @Cols SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'NominaConceptoLegal';

DECLARE @MissingCols NVARCHAR(MAX) = '';
IF NOT EXISTS (SELECT 1 FROM @Cols WHERE ColName = 'Convencion') SET @MissingCols = @MissingCols + 'Convencion, ';
IF NOT EXISTS (SELECT 1 FROM @Cols WHERE ColName = 'TipoCalculo') SET @MissingCols = @MissingCols + 'TipoCalculo, ';
IF NOT EXISTS (SELECT 1 FROM @Cols WHERE ColName = 'CO_CONCEPT') SET @MissingCols = @MissingCols + 'CO_CONCEPT, ';
IF NOT EXISTS (SELECT 1 FROM @Cols WHERE ColName = 'NB_CONCEPTO') SET @MissingCols = @MissingCols + 'NB_CONCEPTO, ';
IF NOT EXISTS (SELECT 1 FROM @Cols WHERE ColName = 'FORMULA') SET @MissingCols = @MissingCols + 'FORMULA, ';
IF NOT EXISTS (SELECT 1 FROM @Cols WHERE ColName = 'SOBRE') SET @MissingCols = @MissingCols + 'SOBRE, ';
IF NOT EXISTS (SELECT 1 FROM @Cols WHERE ColName = 'TIPO') SET @MissingCols = @MissingCols + 'TIPO, ';
IF NOT EXISTS (SELECT 1 FROM @Cols WHERE ColName = 'BONIFICABLE') SET @MissingCols = @MissingCols + 'BONIFICABLE, ';
IF NOT EXISTS (SELECT 1 FROM @Cols WHERE ColName = 'Orden') SET @MissingCols = @MissingCols + 'Orden, ';
IF NOT EXISTS (SELECT 1 FROM @Cols WHERE ColName = 'Activo') SET @MissingCols = @MissingCols + 'Activo, ';

IF LEN(@MissingCols) > 0
BEGIN
    RAISERROR('ERROR: Faltan columnas: %s', 16, 1, @MissingCols);
    RETURN;
END

PRINT 'Estructura de tabla verificada correctamente.';
GO

-- =============================================
-- 2. VISTA: Conceptos por Régimen (Compatibilidad)
-- =============================================
IF EXISTS (SELECT * FROM sys.views WHERE name = 'vw_ConceptosPorRegimen')
    DROP VIEW vw_ConceptosPorRegimen;
GO

CREATE VIEW vw_ConceptosPorRegimen AS
SELECT 
    Id,
    Convencion AS Regimen,
    TipoCalculo,
    CO_CONCEPT AS CoConcepto,
    NB_CONCEPTO AS NbConcepto,
    FORMULA AS Formula,
    SOBRE AS Sobre,
    TIPO AS Tipo,
    BONIFICABLE AS Bonificable,
    LOTTT_Articulo AS ArticuloLey,
    CCP_Clausula AS ClausulaConvenio,
    Orden AS OrdenCalculo,
    Activo AS Aplica,
    CASE 
        WHEN Convencion = 'LOT' THEN 'Ley Organica del Trabajo'
        WHEN Convencion LIKE '%PETRO%' THEN 'Contrato Colectivo Petrolero'
        WHEN Convencion LIKE '%CONSTRUCCION%' OR Convencion LIKE '%CONST%' THEN 'Construccion'
        ELSE Convencion 
    END AS NombreRegimen
FROM NominaConceptoLegal
WHERE Activo = 1;
GO

PRINT 'Vista vw_ConceptosPorRegimen creada.';
GO

-- =============================================
-- 3. SP: Cargar Constantes desde ConceptoLegal
-- Extrae valores constantes de las fórmulas
-- =============================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_Nomina_CargarConstantesDesdeConceptoLegal')
    DROP PROCEDURE sp_Nomina_CargarConstantesDesdeConceptoLegal;
GO

CREATE PROCEDURE sp_Nomina_CargarConstantesDesdeConceptoLegal
    @SessionID NVARCHAR(50),
    @Convencion NVARCHAR(50) = 'LOT',
    @TipoCalculo NVARCHAR(50) = 'MENSUAL'
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Cargar variables base del sistema
    DECLARE @DiasPeriodo INT = 30;
    IF @TipoCalculo = 'SEMANAL' SET @DiasPeriodo = 7;
    IF @TipoCalculo = 'QUINCENAL' SET @DiasPeriodo = 15;
    
    EXEC sp_Nomina_SetVariable @SessionID, 'DIAS_PERIODO', @DiasPeriodo, 'Dias del periodo';
    EXEC sp_Nomina_SetVariable @SessionID, 'HORAS_MES', @DiasPeriodo * 8, 'Horas del periodo';
    
    -- Extraer constantes de las fórmulas (valores numéricos comunes)
    -- Estos son valores que aparecen en las fórmulas de NominaConceptoLegal
    DECLARE @PctSSO DECIMAL(18,4) = 0.04;      -- 4% SSO
    DECLARE @PctFAOV DECIMAL(18,4) = 0.01;     -- 1% FAOV
    DECLARE @PctLRPE DECIMAL(18,4) = 0.005;    -- 0.5% LRPE
    DECLARE @RecargoHE DECIMAL(18,4) = 0.50;   -- 50% horas extras
    DECLARE @RecargoNoct DECIMAL(18,4) = 0.30; -- 30% nocturno
    DECLARE @RecargoDF DECIMAL(18,4) = 0.50;   -- 50% día feriado
    
    -- Verificar si en ConceptoLegal hay porcentajes específicos
    SELECT TOP 1 @PctSSO = CASE 
        WHEN FORMULA LIKE '%0.04%' THEN 0.04
        WHEN FORMULA LIKE '%4%' THEN 0.04
        WHEN FORMULA LIKE '%PCT_SSO%' THEN 0.04
        ELSE @PctSSO 
    END
    FROM NominaConceptoLegal 
    WHERE CO_CONCEPT = 'SSO' AND Convencion = @Convencion;
    
    -- Guardar constantes estándar
    EXEC sp_Nomina_SetVariable @SessionID, 'PCT_SSO', @PctSSO, 'Porcentaje SSO';
    EXEC sp_Nomina_SetVariable @SessionID, 'PCT_FAOV', @PctFAOV, 'Porcentaje FAOV';
    EXEC sp_Nomina_SetVariable @SessionID, 'PCT_LRPE', @PctLRPE, 'Porcentaje LRPE';
    EXEC sp_Nomina_SetVariable @SessionID, 'RECARGO_HE', @RecargoHE, 'Recargo horas extras';
    EXEC sp_Nomina_SetVariable @SessionID, 'RECARGO_NOCTURNO', @RecargoNoct, 'Recargo nocturno';
    EXEC sp_Nomina_SetVariable @SessionID, 'RECARGO_DESCANSO', @RecargoDF, 'Recargo descanso trabajado';
    EXEC sp_Nomina_SetVariable @SessionID, 'RECARGO_FERIADO', @RecargoDF, 'Recargo feriado trabajado';
    
    -- Cargar constantes específicas del convenio desde Antiguedad o ConstanteNomina
    IF EXISTS (SELECT 1 FROM ConstanteNomina WHERE Codigo = 'DIAS_VACACIONES')
    BEGIN
        DECLARE @DiasVac DECIMAL(18,4), @DiasBonoVac DECIMAL(18,4);
        SELECT @DiasVac = Valor FROM ConstanteNomina WHERE Codigo = 'DIAS_VACACIONES';
        SELECT @DiasBonoVac = Valor FROM ConstanteNomina WHERE Codigo = 'DIAS_BONO_VAC';
        
        IF @DiasVac IS NOT NULL 
            EXEC sp_Nomina_SetVariable @SessionID, 'DIAS_VACACIONES', @DiasVac, 'Dias vacaciones anuales';
        IF @DiasBonoVac IS NOT NULL 
            EXEC sp_Nomina_SetVariable @SessionID, 'DIAS_BONO_VAC', @DiasBonoVac, 'Dias bono vacacional';
    END
    ELSE
    BEGIN
        -- Valores por defecto según LOT
        EXEC sp_Nomina_SetVariable @SessionID, 'DIAS_VACACIONES', 15, 'Dias vacaciones base';
        EXEC sp_Nomina_SetVariable @SessionID, 'DIAS_BONO_VAC', 15, 'Dias bono vacacional base';
    END
    
    -- Si es petrolero, usar valores específicos
    IF @Convencion LIKE '%PETRO%'
    BEGIN
        EXEC sp_Nomina_SetVariable @SessionID, 'DIAS_VACACIONES', 34, 'Dias vacaciones petrolero';
        EXEC sp_Nomina_SetVariable @SessionID, 'DIAS_BONO_VAC', 55, 'Dias bono vacacional petrolero';
        EXEC sp_Nomina_SetVariable @SessionID, 'DIAS_UTILIDADES', 120, 'Dias utilidades petrolero';
    END
    
    PRINT 'Constantes cargadas para convencion: ' + @Convencion;
END
GO

PRINT 'SP sp_Nomina_CargarConstantesDesdeConceptoLegal creado.';
GO

-- =============================================
-- 4. SP: Procesar Nómina usando NominaConceptoLegal
-- =============================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_Nomina_ProcesarEmpleadoConceptoLegal')
    DROP PROCEDURE sp_Nomina_ProcesarEmpleadoConceptoLegal;
GO

CREATE PROCEDURE sp_Nomina_ProcesarEmpleadoConceptoLegal
    @Nomina NVARCHAR(10),
    @Cedula NVARCHAR(12),
    @FechaInicio DATE,
    @FechaHasta DATE,
    @Convencion NVARCHAR(50) = NULL, -- LOT, CCT_PETROLERO, etc.
    @TipoCalculo NVARCHAR(50) = 'MENSUAL', -- MENSUAL, SEMANAL, VACACIONES, LIQUIDACION
    @CoUsuario NVARCHAR(20) = 'API',
    @Resultado INT OUTPUT,
    @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    
    SET @Resultado = 0;
    SET @Mensaje = '';
    
    DECLARE @SessionID NVARCHAR(50) = @Nomina + '_' + @Cedula + '_' + CONVERT(NVARCHAR, GETDATE(), 112);
    
    -- Detectar convención si no se proporcionó
    IF @Convencion IS NULL
    BEGIN
        DECLARE @NominaEmp NVARCHAR(15);
        SELECT @NominaEmp = NOMINA FROM Empleados WHERE CEDULA = @Cedula;
        
        IF @NominaEmp LIKE '%PETRO%' OR @NominaEmp LIKE '%PDV%'
            SET @Convencion = 'CCT_PETROLERO';
        ELSE IF @NominaEmp LIKE '%CONST%'
            SET @Convencion = 'CONSTRUCCION';
        ELSE
            SET @Convencion = 'LOT';
    END
    
    -- Verificar que exista la convención en ConceptoLegal
    IF NOT EXISTS (SELECT 1 FROM NominaConceptoLegal WHERE Convencion = @Convencion AND Activo = 1)
    BEGIN
        SET @Resultado = -1;
        SET @Mensaje = 'Convencion no encontrada en NominaConceptoLegal: ' + @Convencion;
        RETURN;
    END
    
    -- Verificar empleado
    IF NOT EXISTS (SELECT 1 FROM Empleados WHERE CEDULA = @Cedula AND STATUS = 'A')
    BEGIN
        SET @Resultado = -2;
        SET @Mensaje = 'Empleado no encontrado o inactivo';
        RETURN;
    END
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Eliminar cálculo anterior
        DELETE FROM DtllNom WHERE NOMINA = @Nomina AND CEDULA = @Cedula;
        DELETE FROM Nomina WHERE NOMINA = @Nomina AND CEDULA = @Cedula;
        
        -- Preparar variables base
        EXEC sp_Nomina_LimpiarVariables @SessionID;
        EXEC sp_Nomina_CargarConstantesDesdeConceptoLegal @SessionID, @Convencion, @TipoCalculo;
        
        -- Cargar datos del empleado
        DECLARE @Sueldo FLOAT, @FechaIngreso DATE;
        SELECT @Sueldo = ISNULL(SUELDO, 0), @FechaIngreso = INGRESO 
        FROM Empleados WHERE CEDULA = @Cedula;
        
        EXEC sp_Nomina_SetVariable @SessionID, 'SUELDO', @Sueldo, 'Sueldo base';
        EXEC sp_Nomina_SetVariable @SessionID, 'SALARIO_DIARIO', @Sueldo / 30, 'Salario diario';
        EXEC sp_Nomina_SetVariable @SessionID, 'SALARIO_HORA', @Sueldo / 240, 'Salario por hora';
        
        -- Calcular antigüedad
        EXEC sp_Nomina_CalcularAntiguedad @SessionID, @Cedula, @FechaHasta;
        
        -- Variables de período
        DECLARE @DiasPeriodo INT = DATEDIFF(DAY, @FechaInicio, @FechaHasta) + 1;
        DECLARE @Feriados INT = dbo.fn_Nomina_ContarFeriados(@FechaInicio, @FechaHasta);
        DECLARE @Domingos INT = dbo.fn_Nomina_ContarDomingos(@FechaInicio, @FechaHasta);
        
        EXEC sp_Nomina_SetVariable @SessionID, 'DIAS_PERIODO', @DiasPeriodo, 'Dias del periodo';
        EXEC sp_Nomina_SetVariable @SessionID, 'FERIADOS', @Feriados, 'Feriados';
        EXEC sp_Nomina_SetVariable @SessionID, 'DOMINGOS', @Domingos, 'Domingos';
        
        -- Acumulados
        DECLARE @TotalAsignaciones DECIMAL(18,4) = 0;
        DECLARE @TotalDeducciones DECIMAL(18,4) = 0;
        
        -- CURSOR: Procesar conceptos de NominaConceptoLegal
        DECLARE @CoConcept NVARCHAR(10), @NbConcepto NVARCHAR(100), @Formula NVARCHAR(500);
        DECLARE @Sobre NVARCHAR(255), @Tipo NVARCHAR(15), @Bonificable NVARCHAR(1);
        DECLARE @Monto DECIMAL(18,4), @Total DECIMAL(18,4), @FormulaResuelta NVARCHAR(MAX);
        
        DECLARE concept_cursor CURSOR FOR
            SELECT CO_CONCEPT, NB_CONCEPTO, FORMULA, SOBRE, TIPO, BONIFICABLE
            FROM NominaConceptoLegal
            WHERE Convencion = @Convencion 
              AND TipoCalculo = @TipoCalculo
              AND Activo = 1
            ORDER BY Orden, Id;
        
        OPEN concept_cursor;
        FETCH NEXT FROM concept_cursor INTO @CoConcept, @NbConcepto, @Formula, @Sobre, @Tipo, @Bonificable;
        
        WHILE @@FETCH_STATUS = 0
        BEGIN
            SET @Monto = 0;
            SET @Total = 0;
            
            -- Evaluar fórmula si existe
            IF @Formula IS NOT NULL AND LTRIM(RTRIM(@Formula)) != ''
            BEGIN
                BEGIN TRY
                    EXEC sp_Nomina_EvaluarFormula @SessionID, @Formula, @Monto OUTPUT, @FormulaResuelta OUTPUT;
                    SET @Total = @Monto;
                END TRY
                BEGIN CATCH
                    -- Si hay error en fórmula, usar 0 pero no fallar todo
                    SET @Monto = 0;
                    SET @Total = 0;
                    PRINT 'Error en formula ' + @CoConcept + ': ' + ERROR_MESSAGE();
                END CATCH
            END
            
            -- Insertar solo si tiene valor o es un concepto fijo
            IF @Total != 0 OR @CoConcept IN ('SUELDO', 'SALARIO_BASE')
            BEGIN
                INSERT INTO DtllNom (NOMINA, CO_CONCEPTO, CEDULA, INICIO, HASTA, CANTIDAD, MONTO, TOTAL, 
                                     Co_Usuario, Descripcion, Tipo)
                VALUES (@Nomina, @CoConcept, @Cedula, @FechaInicio, @FechaHasta, 
                        1, @Monto, @Total, @CoUsuario, @NbConcepto, @Tipo);
                
                -- Acumular
                IF @Tipo = 'ASIGNACION' OR @Tipo = 'BONO'
                    SET @TotalAsignaciones = @TotalAsignaciones + @Total;
                ELSE IF @Tipo = 'DEDUCCION'
                    SET @TotalDeducciones = @TotalDeducciones + @Total;
                
                -- Guardar para referencias posteriores
                EXEC sp_Nomina_SetVariable @SessionID, 'C' + @CoConcept, @Total, @NbConcepto;
                
                -- Si es sueldo base, guardar también como variable base
                IF @CoConcept = 'SUELDO' OR @CoConcept = 'SALARIO_BASE'
                    EXEC sp_Nomina_SetVariable @SessionID, 'TOTAL_ASIGNACIONES_BASE', @TotalAsignaciones, 'Asignaciones base';
            END
            
            FETCH NEXT FROM concept_cursor INTO @CoConcept, @NbConcepto, @Formula, @Sobre, @Tipo, @Bonificable;
        END
        
        CLOSE concept_cursor;
        DEALLOCATE concept_cursor;
        
        -- Guardar totales
        EXEC sp_Nomina_SetVariable @SessionID, 'TOTAL_ASIGNACIONES', @TotalAsignaciones, 'Total asignaciones';
        EXEC sp_Nomina_SetVariable @SessionID, 'TOTAL_DEDUCCIONES', @TotalDeducciones, 'Total deducciones';
        
        -- Insertar cabecera
        INSERT INTO Nomina (NOMINA, CEDULA, FECHA, INICIO, HASTA, ASIGNACION, DEDUCCION, TOTAL, CERRADA)
        VALUES (@Nomina, @Cedula, GETDATE(), @FechaInicio, @FechaHasta, 
                @TotalAsignaciones, @TotalDeducciones, @TotalAsignaciones - @TotalDeducciones, 0);
        
        -- Limpiar
        EXEC sp_Nomina_LimpiarVariables @SessionID;
        
        COMMIT TRANSACTION;
        
        SET @Resultado = 1;
        SET @Mensaje = 'NOMINA PROCESADA OK. Convencion: ' + @Convencion + 
                       ', Tipo: ' + @TipoCalculo + 
                       ', Asignaciones: ' + CONVERT(NVARCHAR, @TotalAsignaciones) + 
                       ', Deducciones: ' + CONVERT(NVARCHAR, @TotalDeducciones);
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SET @Resultado = -99;
        SET @Mensaje = ERROR_MESSAGE();
        EXEC sp_Nomina_LimpiarVariables @SessionID;
    END CATCH
END
GO

PRINT 'SP sp_Nomina_ProcesarEmpleadoConceptoLegal creado.';
GO

-- =============================================
-- 5. SP: Consultar Conceptos Disponibles
-- =============================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_Nomina_ConceptosLegales_List')
    DROP PROCEDURE sp_Nomina_ConceptosLegales_List;
GO

CREATE PROCEDURE sp_Nomina_ConceptosLegales_List
    @Convencion NVARCHAR(50) = NULL,
    @TipoCalculo NVARCHAR(50) = NULL,
    @Tipo NVARCHAR(15) = NULL,
    @Activo BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        Id,
        Convencion,
        TipoCalculo,
        CO_CONCEPT,
        NB_CONCEPTO,
        FORMULA,
        SOBRE,
        TIPO,
        BONIFICABLE,
        LOTTT_Articulo,
        CCP_Clausula,
        Orden,
        Activo
    FROM NominaConceptoLegal
    WHERE (@Convencion IS NULL OR Convencion = @Convencion)
      AND (@TipoCalculo IS NULL OR TipoCalculo = @TipoCalculo)
      AND (@Tipo IS NULL OR TIPO = @Tipo)
      AND (@Activo IS NULL OR Activo = @Activo)
    ORDER BY Convencion, TipoCalculo, Orden, CO_CONCEPT;
END
GO

PRINT 'SP sp_Nomina_ConceptosLegales_List creado.';
GO

-- =============================================
-- 6. SP: Validar Fórmulas de Conceptos
-- =============================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_Nomina_ValidarFormulasConceptoLegal')
    DROP PROCEDURE sp_Nomina_ValidarFormulasConceptoLegal;
GO

CREATE PROCEDURE sp_Nomina_ValidarFormulasConceptoLegal
    @Convencion NVARCHAR(50) = NULL,
    @TipoCalculo NVARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    CREATE TABLE #Resultados (
        Id INT,
        CO_CONCEPT NVARCHAR(10),
        NB_CONCEPTO NVARCHAR(100),
        FORMULA NVARCHAR(500),
        Error NVARCHAR(500),
        EsValida BIT
    );
    
    DECLARE @Id INT, @CoConcept NVARCHAR(10), @NbConcepto NVARCHAR(100), @Formula NVARCHAR(500);
    DECLARE @TestResult DECIMAL(18,4), @TestFormula NVARCHAR(MAX);
    DECLARE @SessionTest NVARCHAR(50) = 'TEST_' + CONVERT(NVARCHAR, GETDATE(), 112);
    
    -- Preparar variables de prueba
    EXEC sp_Nomina_LimpiarVariables @SessionTest;
    EXEC sp_Nomina_SetVariable @SessionTest, 'SUELDO', 50000, 'Test';
    EXEC sp_Nomina_SetVariable @SessionTest, 'SALARIO_DIARIO', 1666.67, 'Test';
    EXEC sp_Nomina_SetVariable @SessionTest, 'SALARIO_HORA', 208.33, 'Test';
    EXEC sp_Nomina_SetVariable @SessionTest, 'DIAS_PERIODO', 30, 'Test';
    EXEC sp_Nomina_SetVariable @SessionTest, 'TOTAL_ASIGNACIONES', 50000, 'Test';
    
    DECLARE test_cursor CURSOR FOR
        SELECT Id, CO_CONCEPT, NB_CONCEPTO, FORMULA
        FROM NominaConceptoLegal
        WHERE (@Convencion IS NULL OR Convencion = @Convencion)
          AND (@TipoCalculo IS NULL OR TipoCalculo = @TipoCalculo)
          AND Activo = 1
          AND FORMULA IS NOT NULL AND LTRIM(RTRIM(FORMULA)) != '';
    
    OPEN test_cursor;
    FETCH NEXT FROM test_cursor INTO @Id, @CoConcept, @NbConcepto, @Formula;
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        BEGIN TRY
            EXEC sp_Nomina_EvaluarFormula @SessionTest, @Formula, @TestResult OUTPUT, @TestFormula OUTPUT;
            INSERT INTO #Resultados (Id, CO_CONCEPT, NB_CONCEPTO, FORMULA, Error, EsValida)
            VALUES (@Id, @CoConcept, @NbConcepto, @Formula, NULL, 1);
        END TRY
        BEGIN CATCH
            INSERT INTO #Resultados (Id, CO_CONCEPT, NB_CONCEPTO, FORMULA, Error, EsValida)
            VALUES (@Id, @CoConcept, @NbConcepto, @Formula, ERROR_MESSAGE(), 0);
        END CATCH
        
        FETCH NEXT FROM test_cursor INTO @Id, @CoConcept, @NbConcepto, @Formula;
    END
    
    CLOSE test_cursor;
    DEALLOCATE test_cursor;
    
    EXEC sp_Nomina_LimpiarVariables @SessionTest;
    
    -- Resultados
    SELECT 
        Convencion = @Convencion,
        TotalConceptos = COUNT(*),
        FormulasValidas = SUM(CASE WHEN EsValida = 1 THEN 1 ELSE 0 END),
        FormulasConError = SUM(CASE WHEN EsValida = 0 THEN 1 ELSE 0 END)
    FROM #Resultados;
    
    SELECT * FROM #Resultados WHERE EsValida = 0 ORDER BY CO_CONCEPT;
    
    DROP TABLE #Resultados;
END
GO

PRINT 'SP sp_Nomina_ValidarFormulasConceptoLegal creado.';
GO

PRINT '';
PRINT '============================================================';
PRINT 'ADAPTADOR INSTALADO CORRECTAMENTE';
PRINT '============================================================';
PRINT '';
PRINT 'Nuevos objetos:';
PRINT '  - vw_ConceptosPorRegimen (Vista)';
PRINT '  - sp_Nomina_CargarConstantesDesdeConceptoLegal';
PRINT '  - sp_Nomina_ProcesarEmpleadoConceptoLegal (PRINCIPAL)';
PRINT '  - sp_Nomina_ConceptosLegales_List';
PRINT '  - sp_Nomina_ValidarFormulasConceptoLegal';
PRINT '';
PRINT 'Uso:';
PRINT '  EXEC sp_Nomina_ProcesarEmpleadoConceptoLegal';
PRINT '       @Nomina = ''NOM20240201'',';
PRINT '       @Cedula = ''V12345678'',';
PRINT '       @FechaInicio = ''2024-02-01'',';
PRINT '       @FechaHasta = ''2024-02-15'',';
PRINT '       @Convencion = ''LOT'',  -- o ''CCT_PETROLERO''';
PRINT '       @TipoCalculo = ''MENSUAL'';  -- o ''VACACIONES'', ''LIQUIDACION''';
GO
