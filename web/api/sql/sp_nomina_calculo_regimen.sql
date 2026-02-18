-- =============================================
-- MOTOR DE CÁLCULO CON RÉGIMEN LABORAL VENEZOLANO
-- Evaluación dinámica según tipo de contrato
-- Compatible con: SQL Server 2012+
-- =============================================

-- =============================================
-- SP: Cargar constantes por régimen
-- =============================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_Nomina_CargarConstantesRegimen')
    DROP PROCEDURE sp_Nomina_CargarConstantesRegimen
GO

CREATE PROCEDURE sp_Nomina_CargarConstantesRegimen
    @SessionID NVARCHAR(50),
    @Regimen NVARCHAR(10) = 'LOT',
    @TipoNomina NVARCHAR(15) = 'MENSUAL'
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Primero cargar constantes LOT (base) que no existan en el régimen específico
    INSERT INTO VariablesCalculadas (SessionID, Variable, Valor, Descripcion)
    SELECT @SessionID, c.Codigo + '_LOT', 
           CASE c.TipoDato 
               WHEN 'NUMERO' THEN CAST(c.Valor AS DECIMAL(18,4))
               WHEN 'PORCENTAJE' THEN CAST(c.Valor AS DECIMAL(18,4))
               ELSE 0 
           END,
           c.Nombre + ' (LOT)'
    FROM ConstantesNominaExtendida c
    WHERE c.Regimen = 'LOT'
      AND c.AplicaPorDefecto = 1
      AND NOT EXISTS (
          SELECT 1 FROM ConstantesNominaExtendida c2 
          WHERE c2.Codigo = c.Codigo AND c2.Regimen = @Regimen
      );
    
    -- Luego cargar/sobrescribir con constantes del régimen específico
    INSERT INTO VariablesCalculadas (SessionID, Variable, Valor, Descripcion)
    SELECT @SessionID, c.Codigo + '_' + @Regimen, 
           CASE c.TipoDato 
               WHEN 'NUMERO' THEN CAST(c.Valor AS DECIMAL(18,4))
               WHEN 'PORCENTAJE' THEN CAST(c.Valor AS DECIMAL(18,4))
               ELSE 0 
           END,
           c.Nombre + ' (' + @Regimen + ')'
    FROM ConstantesNominaExtendida c
    WHERE c.Regimen = @Regimen
      AND c.AplicaPorDefecto = 1;
    
    -- Cargar constantes del tipo de nómina (SEMANAL, QUINCENAL, MENSUAL)
    INSERT INTO VariablesCalculadas (SessionID, Variable, Valor, Descripcion)
    SELECT @SessionID, c.Codigo + '_' + @TipoNomina, 
           CASE c.TipoDato 
               WHEN 'NUMERO' THEN CAST(c.Valor AS DECIMAL(18,4))
               WHEN 'PORCENTAJE' THEN CAST(c.Valor AS DECIMAL(18,4))
               ELSE 0 
           END,
           c.Nombre + ' (' + @TipoNomina + ')'
    FROM ConstantesNominaExtendida c
    WHERE c.Regimen = @TipoNomina;
    
    -- Crear variables alias simplificadas (sin sufijo) para las más comunes
    -- usando el valor del régimen específico si existe, sino LOT
    DECLARE @VarName NVARCHAR(50), @VarValue DECIMAL(18,4), @VarDesc NVARCHAR(100);
    DECLARE @BaseName NVARCHAR(50);
    
    DECLARE const_cursor CURSOR FOR
        SELECT DISTINCT SUBSTRING(c.Codigo, 1, 50), c.Nombre
        FROM ConstantesNominaExtendida c
        WHERE c.Regimen IN (@Regimen, 'LOT', @TipoNomina)
          AND c.AplicaPorDefecto = 1;
    
    OPEN const_cursor
    FETCH NEXT FROM const_cursor INTO @BaseName, @VarDesc
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Buscar valor en orden: Régimen específico → LOT → Tipo Nómina
        SELECT TOP 1 @VarValue = CASE c.TipoDato 
                                    WHEN 'NUMERO' THEN CAST(c.Valor AS DECIMAL(18,4))
                                    WHEN 'PORCENTAJE' THEN CAST(c.Valor AS DECIMAL(18,4))
                                    ELSE 0 
                                 END,
                     @VarDesc = c.Nombre
        FROM ConstantesNominaExtendida c
        WHERE c.Codigo = @BaseName 
          AND c.Regimen IN (@Regimen, 'LOT', @TipoNomina)
        ORDER BY CASE c.Regimen 
                     WHEN @Regimen THEN 1 
                     WHEN @TipoNomina THEN 2 
                     ELSE 3 
                 END;
        
        IF @VarValue IS NOT NULL
            EXEC sp_Nomina_SetVariable @SessionID, @BaseName, @VarValue, @VarDesc;
        
        FETCH NEXT FROM const_cursor INTO @BaseName, @VarDesc
    END
    
    CLOSE const_cursor
    DEALLOCATE const_cursor
END
GO

-- =============================================
-- SP: Calcular vacaciones según régimen
-- =============================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_Nomina_CalcularVacacionesRegimen')
    DROP PROCEDURE sp_Nomina_CalcularVacacionesRegimen
GO

CREATE PROCEDURE sp_Nomina_CalcularVacacionesRegimen
    @SessionID NVARCHAR(50),
    @Regimen NVARCHAR(10),
    @AniosServicio INT,
    @MesesPeriodo INT = 12,
    @DiasVacaciones DECIMAL(18,4) OUTPUT,
    @DiasBonoVacacional DECIMAL(18,4) OUTPUT,
    @DiasBonoPostVacacional DECIMAL(18,4) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @VacBase DECIMAL(18,4), @VacAdicAnio DECIMAL(18,4), @VacMax DECIMAL(18,4);
    DECLARE @BonoBase DECIMAL(18,4), @BonoAdicAnio DECIMAL(18,4), @BonoMax DECIMAL(18,4);
    DECLARE @BonoPost DECIMAL(18,4) = 0;
    
    -- Obtener parámetros según régimen (o LOT por defecto)
    SELECT @VacBase = ISNULL(CAST(Valor AS DECIMAL(18,4)), 15),
           @VacAdicAnio = 1,
           @VacMax = 30
    FROM ConstantesNominaExtendida 
    WHERE Codigo = 'VAC_DIAS_BASE' AND Regimen = @Regimen;
    
    IF @VacBase IS NULL
        SELECT @VacBase = ISNULL(CAST(Valor AS DECIMAL(18,4)), 15)
        FROM ConstantesNominaExtendida 
        WHERE Codigo = 'VAC_DIAS_BASE' AND Regimen = 'LOT';
    
    SELECT @VacAdicAnio = ISNULL(CAST(Valor AS DECIMAL(18,4)), 1)
    FROM ConstantesNominaExtendida 
    WHERE Codigo = 'VAC_DIAS_ADIC_ANIO' AND Regimen = @Regimen;
    IF @VacAdicAnio IS NULL
        SELECT @VacAdicAnio = ISNULL(CAST(Valor AS DECIMAL(18,4)), 1)
        FROM ConstantesNominaExtendida WHERE Codigo = 'VAC_DIAS_ADIC_ANIO' AND Regimen = 'LOT';
    
    SELECT @VacMax = ISNULL(CAST(Valor AS DECIMAL(18,4)), 30)
    FROM ConstantesNominaExtendida 
    WHERE Codigo = 'VAC_DIAS_MAX' AND Regimen = @Regimen;
    IF @VacMax IS NULL
        SELECT @VacMax = ISNULL(CAST(Valor AS DECIMAL(18,4)), 30)
        FROM ConstantesNominaExtendida WHERE Codigo = 'VAC_DIAS_MAX' AND Regimen = 'LOT';
    
    -- Bono vacacional
    SELECT @BonoBase = ISNULL(CAST(Valor AS DECIMAL(18,4)), 15)
    FROM ConstantesNominaExtendida 
    WHERE Codigo = 'BONO_VAC_DIAS' AND Regimen = @Regimen;
    IF @BonoBase IS NULL
        SELECT @BonoBase = ISNULL(CAST(Valor AS DECIMAL(18,4)), 15)
        FROM ConstantesNominaExtendida WHERE Codigo = 'BONO_VAC_DIAS' AND Regimen = 'LOT';
    
    SELECT @BonoAdicAnio = ISNULL(CAST(Valor AS DECIMAL(18,4)), 1)
    FROM ConstantesNominaExtendida 
    WHERE Codigo = 'BONO_VAC_ADIC_ANIO' AND Regimen = @Regimen;
    IF @BonoAdicAnio IS NULL SET @BonoAdicAnio = 1;
    
    SELECT @BonoMax = ISNULL(CAST(Valor AS DECIMAL(18,4)), 30)
    FROM ConstantesNominaExtendida 
    WHERE Codigo = 'BONO_VAC_MAX' AND Regimen = @Regimen;
    IF @BonoMax IS NULL SET @BonoMax = 30;
    
    -- Bono post vacacional (específico petrolero)
    SELECT @BonoPost = ISNULL(CAST(Valor AS DECIMAL(18,4)), 0)
    FROM ConstantesNominaExtendida 
    WHERE Codigo = 'BONO_VAC_POST_DIAS' AND Regimen = @Regimen;
    
    -- Calcular vacaciones
    SET @DiasVacaciones = @VacBase + (@AniosServicio * @VacAdicAnio);
    IF @DiasVacaciones > @VacMax SET @DiasVacaciones = @VacMax;
    
    -- Calcular bono vacacional
    SET @DiasBonoVacacional = @BonoBase + (@AniosServicio * @BonoAdicAnio);
    IF @DiasBonoVacacional > @BonoMax SET @DiasBonoVacacional = @BonoMax;
    
    -- Bono post vacacional
    SET @DiasBonoPostVacacional = @BonoPost;
    
    -- Si es fraccionado (no año completo)
    IF @MesesPeriodo < 12
    BEGIN
        DECLARE @FraccMes DECIMAL(18,4);
        SELECT @FraccMes = ISNULL(CAST(Valor AS DECIMAL(18,4)), @VacBase/12.0)
        FROM ConstantesNominaExtendida 
        WHERE Codigo = 'VAC_FRACC_MES' AND Regimen = @Regimen;
        IF @FraccMes IS NULL SET @FraccMes = @VacBase / 12.0;
        
        SET @DiasVacaciones = @FraccMes * @MesesPeriodo;
        SET @DiasBonoVacacional = (@BonoBase / 12.0) * @MesesPeriodo;
    END
    
    -- Guardar en variables
    EXEC sp_Nomina_SetVariable @SessionID, 'DIAS_VACACIONES', @DiasVacaciones, 'Días de vacaciones calculados';
    EXEC sp_Nomina_SetVariable @SessionID, 'DIAS_BONO_VAC', @DiasBonoVacacional, 'Días bono vacacional';
    EXEC sp_Nomina_SetVariable @SessionID, 'DIAS_BONO_POST_VAC', @DiasBonoPostVacacional, 'Días bono post vacacional';
END
GO

-- =============================================
-- SP: Calcular utilidades según régimen
-- =============================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_Nomina_CalcularUtilidadesRegimen')
    DROP PROCEDURE sp_Nomina_CalcularUtilidadesRegimen
GO

CREATE PROCEDURE sp_Nomina_CalcularUtilidadesRegimen
    @SessionID NVARCHAR(50),
    @Regimen NVARCHAR(10),
    @DiasTrabajadosAno INT,
    @SalarioNormal DECIMAL(18,4),
    @Utilidades DECIMAL(18,4) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @DiasMin DECIMAL(18,4), @DiasMax DECIMAL(18,4), @DiasUtil DECIMAL(18,4);
    
    -- Obtener parámetros
    SELECT @DiasMin = ISNULL(CAST(Valor AS DECIMAL(18,4)), 30),
           @DiasMax = ISNULL(CAST(Valor AS DECIMAL(18,4)), 120)
    FROM ConstantesNominaExtendida 
    WHERE Codigo = 'UTIL_DIAS_MIN' AND Regimen = @Regimen;
    
    IF @DiasMin IS NULL SET @DiasMin = 30;
    IF @DiasMax IS NULL SET @DiasMax = 120;
    
    -- Para petrolero, usar semanas base
    IF @Regimen = 'PETRO'
    BEGIN
        DECLARE @SemanasBase INT;
        SELECT @SemanasBase = ISNULL(CAST(Valor AS INT), 6)
        FROM ConstantesNominaExtendida 
        WHERE Codigo = 'UTIL_CALCULO_SEMANAS' AND Regimen = 'PETRO';
        
        -- El cálculo es diferente, se basa en promedio de semanas
        -- Esta es una simplificación, el cálculo real usa DtllNom
        SET @DiasUtil = @DiasMin; -- Base mínima petrolero
    END
    ELSE
    BEGIN
        -- LOT: Entre 30 y 120 días según rentabilidad
        -- Simplificación: usamos el mínimo si no hay datos de empresa
        SET @DiasUtil = @DiasMin;
    END
    
    -- Calcular utilidades proporcionales
    SET @Utilidades = (@SalarioNormal * @DiasUtil / 360) * @DiasTrabajadosAno;
    
    EXEC sp_Nomina_SetVariable @SessionID, 'DIAS_UTILIDADES', @DiasUtil, 'Días de utilidades';
    EXEC sp_Nomina_SetVariable @SessionID, 'MONTO_UTILIDADES', @Utilidades, 'Monto utilidades calculado';
END
GO

-- =============================================
-- SP: Calcular prestaciones según régimen
-- =============================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_Nomina_CalcularPrestacionesRegimen')
    DROP PROCEDURE sp_Nomina_CalcularPrestacionesRegimen
GO

CREATE PROCEDURE sp_Nomina_CalcularPrestacionesRegimen
    @SessionID NVARCHAR(50),
    @Regimen NVARCHAR(10),
    @AniosServicio INT,
    @MesesAdicionales INT,
    @SalarioIntegral DECIMAL(18,4),
    @Prestaciones DECIMAL(18,4) OUTPUT,
    @Intereses DECIMAL(18,4) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @DiasAnio DECIMAL(18,4), @InteresAnual DECIMAL(18,4), @TopeMeses DECIMAL(18,4);
    DECLARE @ComplementoAntig DECIMAL(18,4) = 0;
    
    -- Parámetros según régimen
    SELECT @DiasAnio = ISNULL(CAST(Valor AS DECIMAL(18,4)), 30),
           @InteresAnual = ISNULL(CAST(Valor AS DECIMAL(18,4)), 0.04),
           @TopeMeses = ISNULL(CAST(Valor AS DECIMAL(18,4)), 10)
    FROM ConstantesNominaExtendida 
    WHERE Codigo IN ('PREST_DIAS_ANTIGUEDAD', 'PREST_INTERES_ANUAL', 'PREST_TOPE_SALARIO')
      AND Regimen = @Regimen;
    
    IF @DiasAnio IS NULL SET @DiasAnio = 30;
    IF @InteresAnual IS NULL SET @InteresAnual = 0.04;
    IF @TopeMeses IS NULL SET @TopeMeses = 10;
    
    -- Complemento antigüedad (petrolero)
    SELECT @ComplementoAntig = ISNULL(CAST(Valor AS DECIMAL(18,4)), 0)
    FROM ConstantesNominaExtendida 
    WHERE Codigo = 'PREST_COMPLEMENTO_ANTIG' AND Regimen = @Regimen;
    
    -- Calcular días totales
    DECLARE @DiasTotales DECIMAL(18,4) = (@AniosServicio * @DiasAnio) + 
                                          (@MesesAdicionales * @DiasAnio / 12.0) +
                                          (@AniosServicio * ISNULL(@ComplementoAntig, 0));
    
    -- Calcular prestaciones
    SET @Prestaciones = @SalarioIntegral * @DiasTotales / 30;
    
    -- Verificar tope
    DECLARE @TopeMonto DECIMAL(18,4) = @SalarioIntegral * @TopeMeses;
    IF @Prestaciones > @TopeMonto SET @Prestaciones = @TopeMonto;
    
    -- Intereses sobre prestaciones (días de interés proporcionales)
    SET @Intereses = @Prestaciones * @InteresAnual * (@AniosServicio + (@MesesAdicionales / 12.0));
    
    EXEC sp_Nomina_SetVariable @SessionID, 'DIAS_PRESTACIONES', @DiasTotales, 'Días prestaciones sociales';
    EXEC sp_Nomina_SetVariable @SessionID, 'MONTO_PRESTACIONES', @Prestaciones, 'Monto prestaciones';
    EXEC sp_Nomina_SetVariable @SessionID, 'INTERESES_PRESTACIONES', @Intereses, 'Intereses prestaciones';
END
GO

-- =============================================
-- SP: Preparar variables con régimen laboral
-- =============================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_Nomina_PrepararVariablesRegimen')
    DROP PROCEDURE sp_Nomina_PrepararVariablesRegimen
GO

CREATE PROCEDURE sp_Nomina_PrepararVariablesRegimen
    @SessionID NVARCHAR(50),
    @Cedula NVARCHAR(12),
    @Nomina NVARCHAR(10),
    @TipoNomina NVARCHAR(15),
    @Regimen NVARCHAR(10) = NULL, -- Si NULL, se detecta del empleado
    @FechaInicio DATE,
    @FechaHasta DATE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Detectar régimen si no se proporcionó
    IF @Regimen IS NULL
    BEGIN
        SELECT @Regimen = ISNULL(NOMINA, 'LOT') 
        FROM Empleados 
        WHERE CEDULA = @Cedula;
        
        -- Mapear tipos de nómina a regímenes
        IF @Regimen LIKE '%PETRO%' OR @Regimen LIKE '%PDV%' SET @Regimen = 'PETRO';
        ELSE IF @Regimen LIKE '%CONST%' OR @Regimen LIKE '%OBRA%' SET @Regimen = 'CONST';
        ELSE IF @Regimen LIKE '%COMERC%' SET @Regimen = 'COMERC';
        ELSE IF @Regimen LIKE '%SALUD%' SET @Regimen = 'SALUD';
        ELSE SET @Regimen = 'LOT';
    END
    
    -- Limpiar variables anteriores
    EXEC sp_Nomina_LimpiarVariables @SessionID;
    
    -- Cargar constantes del régimen
    EXEC sp_Nomina_CargarConstantesRegimen @SessionID, @Regimen, @TipoNomina;
    
    -- Cargar variables base del empleado
    DECLARE @Sueldo FLOAT, @Ingreso DATE, @Utilidad FLOAT;
    SELECT @Sueldo = ISNULL(SUELDO, 0), @Ingreso = INGRESO, @Utilidad = ISNULL(UTILIDAD, 0)
    FROM Empleados WHERE CEDULA = @Cedula;
    
    EXEC sp_Nomina_SetVariable @SessionID, 'SUELDO', @Sueldo, 'Sueldo base mensual';
    EXEC sp_Nomina_SetVariable @SessionID, 'UTILIDAD_PCT', @Utilidad, 'Porcentaje utilidad empresa';
    
    -- Fechas y período
    DECLARE @DiasPeriodo INT = DATEDIFF(DAY, @FechaInicio, @FechaHasta) + 1;
    DECLARE @Feriados INT = dbo.fn_Nomina_ContarFeriados(@FechaInicio, @FechaHasta);
    DECLARE @Domingos INT = dbo.fn_Nomina_ContarDomingos(@FechaInicio, @FechaHasta);
    
    EXEC sp_Nomina_SetVariable @SessionID, 'FECHA_INICIO', 0, CONVERT(NVARCHAR, @FechaInicio, 103);
    EXEC sp_Nomina_SetVariable @SessionID, 'FECHA_HASTA', 0, CONVERT(NVARCHAR, @FechaHasta, 103);
    EXEC sp_Nomina_SetVariable @SessionID, 'DIAS_PERIODO', @DiasPeriodo, 'Días del período';
    EXEC sp_Nomina_SetVariable @SessionID, 'FERIADOS', @Feriados, 'Feriados en período';
    EXEC sp_Nomina_SetVariable @SessionID, 'DOMINGOS', @Domingos, 'Domingos en período';
    
    -- Calcular antigüedad
    EXEC sp_Nomina_CalcularAntiguedad @SessionID, @Cedula, @FechaHasta;
    
    -- Calcular salarios
    DECLARE @DiasUtilAno INT = 360; -- Base 360 para Venezuela
    DECLARE @SalarioDiario DECIMAL(18,4) = @Sueldo / @DiasUtilAno * 12;
    DECLARE @SalarioHora DECIMAL(18,4) = @SalarioDiario / 8;
    
    EXEC sp_Nomina_SetVariable @SessionID, 'SALARIO_DIARIO', @SalarioDiario, 'Salario diario';
    EXEC sp_Nomina_SetVariable @SessionID, 'SALARIO_HORA', @SalarioHora, 'Salario por hora';
    EXEC sp_Nomina_SetVariable @SessionID, 'HORAS_MES', 240, 'Horas laborables mes';
    
    -- Guardar régimen para referencias
    EXEC sp_Nomina_SetVariable @SessionID, 'REGIMEN_LABORAL', 0, @Regimen;
    EXEC sp_Nomina_SetVariable @SessionID, 'TIPO_NOMINA', 0, @TipoNomina;
END
GO

-- =============================================
-- SP: Procesar nómina con régimen
-- =============================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_Nomina_ProcesarEmpleadoRegimen')
    DROP PROCEDURE sp_Nomina_ProcesarEmpleadoRegimen
GO

CREATE PROCEDURE sp_Nomina_ProcesarEmpleadoRegimen
    @Nomina NVARCHAR(10),
    @Cedula NVARCHAR(12),
    @FechaInicio DATE,
    @FechaHasta DATE,
    @Regimen NVARCHAR(10) = NULL,
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
    DECLARE @TipoNomina NVARCHAR(15) = 'MENSUAL';
    
    -- Detectar tipo de nómina
    IF @Nomina LIKE '%SEM%' SET @TipoNomina = 'SEMANAL';
    ELSE IF @Nomina LIKE '%QUIN%' SET @TipoNomina = 'QUINCENAL';
    
    -- Verificar empleado
    IF NOT EXISTS (SELECT 1 FROM Empleados WHERE CEDULA = @Cedula AND STATUS = 'A')
    BEGIN
        SET @Resultado = -1;
        SET @Mensaje = 'Empleado no encontrado o inactivo';
        RETURN;
    END
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Eliminar cálculo anterior
        DELETE FROM DtllNom WHERE NOMINA = @Nomina AND CEDULA = @Cedula;
        DELETE FROM Nomina WHERE NOMINA = @Nomina AND CEDULA = @Cedula;
        
        -- Preparar variables con régimen
        EXEC sp_Nomina_PrepararVariablesRegimen @SessionID, @Cedula, @Nomina, @TipoNomina, @Regimen, @FechaInicio, @FechaHasta;
        
        -- Obtener régimen usado
        SELECT @Regimen = Descripcion 
        FROM VariablesCalculadas 
        WHERE SessionID = @SessionID AND Variable = 'REGIMEN_LABORAL';
        IF @Regimen IS NULL SET @Regimen = 'LOT';
        
        -- Variables para acumulados
        DECLARE @TotalAsignaciones DECIMAL(18,4) = 0;
        DECLARE @TotalDeducciones DECIMAL(18,4) = 0;
        
        -- Procesar conceptos del régimen
        DECLARE @CoConcepto NVARCHAR(10), @Monto DECIMAL(18,4), @Total DECIMAL(18,4), @Descripcion NVARCHAR(100);
        DECLARE @Tipo NVARCHAR(15), @Formula NVARCHAR(500), @FormulaResuelta NVARCHAR(MAX);
        
        -- Cursor para ASIGNACIONES del régimen
        DECLARE concept_cursor CURSOR FOR
            SELECT CoConcepto, NbConcepto, Formula, Tipo
            FROM ConceptosNominaRegimen
            WHERE Regimen = @Regimen 
              AND (CoNomina = @TipoNomina OR CoNomina = 'MENSUAL')
              AND Tipo IN ('ASIGNACION', 'BONO')
              AND Aplica = 1
            ORDER BY OrdenCalculo;
        
        OPEN concept_cursor
        FETCH NEXT FROM concept_cursor INTO @CoConcepto, @Descripcion, @Formula, @Tipo
        
        WHILE @@FETCH_STATUS = 0
        BEGIN
            IF @Formula IS NOT NULL AND LTRIM(RTRIM(@Formula)) != ''
            BEGIN
                EXEC sp_Nomina_EvaluarFormula @SessionID, @Formula, @Monto OUTPUT, @FormulaResuelta OUTPUT;
                SET @Total = @Monto;
            END
            ELSE
                SET @Total = 0;
            
            IF @Total != 0
            BEGIN
                INSERT INTO DtllNom (NOMINA, CO_CONCEPTO, CEDULA, INICIO, HASTA, CANTIDAD, MONTO, TOTAL, 
                                     Co_Usuario, Descripcion, Tipo)
                VALUES (@Nomina, @CoConcepto, @Cedula, @FechaInicio, @FechaHasta, 1, @Monto, @Total,
                        @CoUsuario, @Descripcion, @Tipo);
                
                SET @TotalAsignaciones = @TotalAsignaciones + @Total;
                EXEC sp_Nomina_SetVariable @SessionID, 'C' + @CoConcepto, @Total, @Descripcion;
            END
            
            FETCH NEXT FROM concept_cursor INTO @CoConcepto, @Descripcion, @Formula, @Tipo
        END
        
        CLOSE concept_cursor
        DEALLOCATE concept_cursor
        
        -- Guardar total asignaciones
        EXEC sp_Nomina_SetVariable @SessionID, 'TOTAL_ASIGNACIONES', @TotalAsignaciones, 'Total asignaciones';
        
        -- Cursor para DEDUCCIONES
        DECLARE concept_cursor CURSOR FOR
            SELECT CoConcepto, NbConcepto, Formula, Tipo
            FROM ConceptosNominaRegimen
            WHERE Regimen = @Regimen 
              AND (CoNomina = @TipoNomina OR CoNomina = 'MENSUAL')
              AND Tipo = 'DEDUCCION'
              AND Aplica = 1
            ORDER BY OrdenCalculo;
        
        OPEN concept_cursor
        FETCH NEXT FROM concept_cursor INTO @CoConcepto, @Descripcion, @Formula, @Tipo
        
        WHILE @@FETCH_STATUS = 0
        BEGIN
            IF @Formula IS NOT NULL AND LTRIM(RTRIM(@Formula)) != ''
            BEGIN
                EXEC sp_Nomina_EvaluarFormula @SessionID, @Formula, @Monto OUTPUT, @FormulaResuelta OUTPUT;
                SET @Total = @Monto;
            END
            ELSE
                SET @Total = 0;
            
            IF @Total != 0
            BEGIN
                INSERT INTO DtllNom (NOMINA, CO_CONCEPTO, CEDULA, INICIO, HASTA, CANTIDAD, MONTO, TOTAL, 
                                     Co_Usuario, Descripcion, Tipo)
                VALUES (@Nomina, @CoConcepto, @Cedula, @FechaInicio, @FechaHasta, 1, @Monto, @Total,
                        @CoUsuario, @Descripcion, @Tipo);
                
                SET @TotalDeducciones = @TotalDeducciones + @Total;
            END
            
            FETCH NEXT FROM concept_cursor INTO @CoConcepto, @Descripcion, @Formula, @Tipo
        END
        
        CLOSE concept_cursor
        DEALLOCATE concept_cursor
        
        -- Insertar cabecera
        INSERT INTO Nomina (NOMINA, CEDULA, FECHA, INICIO, HASTA, ASIGNACION, DEDUCCION, TOTAL, CERRADA)
        VALUES (@Nomina, @Cedula, GETDATE(), @FechaInicio, @FechaHasta, 
                @TotalAsignaciones, @TotalDeducciones, @TotalAsignaciones - @TotalDeducciones, 0);
        
        -- Limpiar variables
        EXEC sp_Nomina_LimpiarVariables @SessionID;
        
        COMMIT TRANSACTION;
        
        SET @Resultado = 1;
        SET @Mensaje = 'Nómina procesada exitosamente (' + @Regimen + '). Asignaciones: ' + 
                       CONVERT(NVARCHAR, @TotalAsignaciones) + ', Deducciones: ' + CONVERT(NVARCHAR, @TotalDeducciones);
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SET @Resultado = -99;
        SET @Mensaje = ERROR_MESSAGE();
        EXEC sp_Nomina_LimpiarVariables @SessionID;
    END CATCH
END
GO

PRINT 'Motor de cálculo con régimen laboral creado exitosamente';
GO
