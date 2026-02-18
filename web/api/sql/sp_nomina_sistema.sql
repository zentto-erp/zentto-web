-- =============================================
-- SISTEMA DE NÓMINA CON FÓRMULAS DINÁMICAS
-- Compatible con: SQL Server 2012+
-- =============================================

-- =============================================
-- 1. TABLA: VariablesCalculadas (para almacenar valores intermedios)
-- =============================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'VariablesCalculadas')
BEGIN
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
GO

-- =============================================
-- 2. FN: Evaluar expresión matemática simple
-- =============================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'FN' AND name = 'fn_EvaluarExpr')
    DROP FUNCTION fn_EvaluarExpr
GO

CREATE FUNCTION fn_EvaluarExpr(@Expr NVARCHAR(MAX))
RETURNS DECIMAL(18,4)
AS
BEGIN
    DECLARE @Result DECIMAL(18,4)
    DECLARE @SQL NVARCHAR(MAX)
    DECLARE @Err INT
    
    -- Limpiar expresión
    SET @Expr = LTRIM(RTRIM(@Expr))
    
    IF @Expr IS NULL OR LEN(@Expr) = 0
        RETURN 0
    
    -- Verificar que solo contiene caracteres permitidos
    IF @Expr LIKE '%[^0-9.()\+\-\*/ ]%'
    BEGIN
        -- Intentar limpiar caracteres no deseados
        SET @Expr = REPLACE(@Expr, CHAR(13), '')
        SET @Expr = REPLACE(@Expr, CHAR(10), '')
        SET @Expr = REPLACE(@Expr, CHAR(9), ' ')
    END
    
    -- Construir SQL dinámico seguro
    SET @SQL = 'SELECT @ResultOut = CAST(' + @Expr + ' AS DECIMAL(18,4))'
    
    BEGIN TRY
        EXEC sp_executesql @SQL, N'@ResultOut DECIMAL(18,4) OUTPUT', @ResultOut = @Result OUTPUT
    END TRY
    BEGIN CATCH
        SET @Result = 0
    END CATCH
    
    RETURN ISNULL(@Result, 0)
END
GO

-- =============================================
-- 3. SP: Limpiar variables de sesión
-- =============================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_Nomina_LimpiarVariables')
    DROP PROCEDURE sp_Nomina_LimpiarVariables
GO

CREATE PROCEDURE sp_Nomina_LimpiarVariables
    @SessionID NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM VariablesCalculadas WHERE SessionID = @SessionID;
END
GO

-- =============================================
-- 4. SP: Guardar variable calculada
-- =============================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_Nomina_SetVariable')
    DROP PROCEDURE sp_Nomina_SetVariable
GO

CREATE PROCEDURE sp_Nomina_SetVariable
    @SessionID NVARCHAR(50),
    @Variable NVARCHAR(50),
    @Valor DECIMAL(18,4),
    @Descripcion NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Eliminar si existe
    DELETE FROM VariablesCalculadas 
    WHERE SessionID = @SessionID AND Variable = @Variable;
    
    -- Insertar nuevo valor
    INSERT INTO VariablesCalculadas (SessionID, Variable, Valor, Descripcion)
    VALUES (@SessionID, @Variable, @Valor, @Descripcion);
END
GO

-- =============================================
-- 5. FN: Obtener variable calculada
-- =============================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'FN' AND name = 'fn_Nomina_GetVariable')
    DROP FUNCTION fn_Nomina_GetVariable
GO

CREATE FUNCTION fn_Nomina_GetVariable(@SessionID NVARCHAR(50), @Variable NVARCHAR(50))
RETURNS DECIMAL(18,4)
AS
BEGIN
    DECLARE @Valor DECIMAL(18,4)
    
    SELECT @Valor = Valor 
    FROM VariablesCalculadas 
    WHERE SessionID = @SessionID AND Variable = @Variable
    
    RETURN ISNULL(@Valor, 0)
END
GO

-- =============================================
-- 6. SP: Cargar constantes de nómina
-- =============================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_Nomina_CargarConstantes')
    DROP PROCEDURE sp_Nomina_CargarConstantes
GO

CREATE PROCEDURE sp_Nomina_CargarConstantes
    @SessionID NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    
    INSERT INTO VariablesCalculadas (SessionID, Variable, Valor, Descripcion)
    SELECT @SessionID, Codigo, Valor, Nombre
    FROM ConstanteNomina
    WHERE Valor IS NOT NULL;
END
GO

-- =============================================
-- 7. SP: Calcular días de antigüedad
-- =============================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_Nomina_CalcularAntiguedad')
    DROP PROCEDURE sp_Nomina_CalcularAntiguedad
GO

CREATE PROCEDURE sp_Nomina_CalcularAntiguedad
    @SessionID NVARCHAR(50),
    @Cedula NVARCHAR(12),
    @FechaCalculo DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    IF @FechaCalculo IS NULL
        SET @FechaCalculo = GETDATE();
    
    DECLARE @FechaIngreso DATE
    DECLARE @Dias INT, @Meses INT, @Anios INT
    
    SELECT @FechaIngreso = INGRESO 
    FROM Empleados 
    WHERE CEDULA = @Cedula;
    
    IF @FechaIngreso IS NULL
    BEGIN
        -- Valores por defecto
        EXEC sp_Nomina_SetVariable @SessionID, 'ANTI_ANIOS', 0, 'Años de antigüedad';
        EXEC sp_Nomina_SetVariable @SessionID, 'ANTI_MESES', 0, 'Meses de antigüedad';
        EXEC sp_Nomina_SetVariable @SessionID, 'ANTI_DIAS', 0, 'Días de antigüedad';
        EXEC sp_Nomina_SetVariable @SessionID, 'ANTI_TOTAL_MESES', 0, 'Total meses de antigüedad';
        RETURN;
    END
    
    -- Calcular diferencia
    SET @Dias = DATEDIFF(DAY, @FechaIngreso, @FechaCalculo);
    SET @Anios = @Dias / 365;
    SET @Meses = (@Dias % 365) / 30;
    SET @Dias = (@Dias % 365) % 30;
    
    DECLARE @TotalMeses INT = DATEDIFF(MONTH, @FechaIngreso, @FechaCalculo);
    
    -- Guardar en variables
    EXEC sp_Nomina_SetVariable @SessionID, 'ANTI_ANIOS', @Anios, 'Años de antigüedad';
    EXEC sp_Nomina_SetVariable @SessionID, 'ANTI_MESES', @Meses, 'Meses de antigüedad';
    EXEC sp_Nomina_SetVariable @SessionID, 'ANTI_DIAS', @Dias, 'Días de antigüedad';
    EXEC sp_Nomina_SetVariable @SessionID, 'ANTI_TOTAL_MESES', @TotalMeses, 'Total meses de antigüedad';
    
    -- Cargar valores de tabla Antiguedad
    DECLARE @MesesAntiguedad INT
    SELECT @MesesAntiguedad = MESES FROM Antiguedad WHERE MESES <= @TotalMeses
    ORDER BY MESES DESC;
    
    IF @MesesAntiguedad IS NOT NULL
    BEGIN
        DECLARE @Preaviso INT, @Legal FLOAT, @VacIndus FLOAT, @Contrato FLOAT
        DECLARE @Adicional FLOAT, @BonoVac FLOAT, @Normal FLOAT
        
        SELECT 
            @Preaviso = PREAVISO,
            @Legal = LEGAL,
            @VacIndus = VAC_INDUS,
            @Contrato = CONTRATO,
            @Adicional = ADICIONAL,
            @BonoVac = BONO_VAC,
            @Normal = NORMAL
        FROM Antiguedad 
        WHERE MESES = @MesesAntiguedad;
        
        EXEC sp_Nomina_SetVariable @SessionID, 'PREAVISO', @Preaviso, 'Días de preaviso';
        EXEC sp_Nomina_SetVariable @SessionID, 'LEGAL', @Legal, 'Días legal';
        EXEC sp_Nomina_SetVariable @SessionID, 'VAC_INDUS', @VacIndus, 'Días vacaciones industriales';
        EXEC sp_Nomina_SetVariable @SessionID, 'CONTRATO', @Contrato, 'Días contrato';
        EXEC sp_Nomina_SetVariable @SessionID, 'ADICIONAL', @Adicional, 'Días adicionales';
        EXEC sp_Nomina_SetVariable @SessionID, 'BONO_VAC', @BonoVac, 'Bono vacacional';
        EXEC sp_Nomina_SetVariable @SessionID, 'NORMAL', @Normal, 'Normal';
    END
END
GO

-- =============================================
-- 8. FN: Contar feriados en período
-- =============================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'FN' AND name = 'fn_Nomina_ContarFeriados')
    DROP FUNCTION fn_Nomina_ContarFeriados
GO

CREATE FUNCTION fn_Nomina_ContarFeriados(@FechaDesde DATE, @FechaHasta DATE)
RETURNS INT
AS
BEGIN
    DECLARE @Count INT
    SELECT @Count = COUNT(*) 
    FROM Feriados 
    WHERE Fecha >= @FechaDesde AND Fecha <= @FechaHasta
    RETURN ISNULL(@Count, 0)
END
GO

-- =============================================
-- 9. FN: Contar domingos en período
-- =============================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'FN' AND name = 'fn_Nomina_ContarDomingos')
    DROP FUNCTION fn_Nomina_ContarDomingos
GO

CREATE FUNCTION fn_Nomina_ContarDomingos(@FechaDesde DATE, @FechaHasta DATE)
RETURNS INT
AS
BEGIN
    DECLARE @Count INT = 0
    DECLARE @Current DATE = @FechaDesde
    
    WHILE @Current <= @FechaHasta
    BEGIN
        IF DATEPART(WEEKDAY, @Current) = 1 -- Domingo
            SET @Count = @Count + 1
        SET @Current = DATEADD(DAY, 1, @Current)
    END
    
    RETURN @Count
END
GO

-- =============================================
-- 10. SP: Preparar variables base para cálculo
-- =============================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_Nomina_PrepararVariablesBase')
    DROP PROCEDURE sp_Nomina_PrepararVariablesBase
GO

CREATE PROCEDURE sp_Nomina_PrepararVariablesBase
    @SessionID NVARCHAR(50),
    @Cedula NVARCHAR(12),
    @Nomina NVARCHAR(10),
    @FechaInicio DATE,
    @FechaHasta DATE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Limpiar variables anteriores
    EXEC sp_Nomina_LimpiarVariables @SessionID;
    
    -- Cargar constantes
    EXEC sp_Nomina_CargarConstantes @SessionID;
    
    -- Fechas del período
    DECLARE @DiasPeriodo INT = DATEDIFF(DAY, @FechaInicio, @FechaHasta) + 1;
    DECLARE @Feriados INT = dbo.fn_Nomina_ContarFeriados(@FechaInicio, @FechaHasta);
    DECLARE @Domingos INT = dbo.fn_Nomina_ContarDomingos(@FechaInicio, @FechaHasta);
    
    EXEC sp_Nomina_SetVariable @SessionID, 'FECHA_INICIO', 0, CONVERT(NVARCHAR, @FechaInicio, 103);
    EXEC sp_Nomina_SetVariable @SessionID, 'FECHA_HASTA', 0, CONVERT(NVARCHAR, @FechaHasta, 103);
    EXEC sp_Nomina_SetVariable @SessionID, 'DIAS_PERIODO', @DiasPeriodo, 'Días del período';
    EXEC sp_Nomina_SetVariable @SessionID, 'FERIADOS', @Feriados, 'Feriados en período';
    EXEC sp_Nomina_SetVariable @SessionID, 'DOMINGOS', @Domingos, 'Domingos en período';
    
    -- Datos del empleado
    DECLARE @Sueldo FLOAT, @NominaTipo NVARCHAR(15), @Ingreso DATE
    DECLARE @Utilidad FLOAT, @Comision FLOAT
    
    SELECT 
        @Sueldo = ISNULL(SUELDO, 0),
        @NominaTipo = NOMINA,
        @Ingreso = INGRESO,
        @Utilidad = ISNULL(UTILIDAD, 0),
        @Comision = ISNULL(COMISION, 0)
    FROM Empleados 
    WHERE CEDULA = @Cedula;
    
    EXEC sp_Nomina_SetVariable @SessionID, 'SUELDO', @Sueldo, 'Sueldo base';
    EXEC sp_Nomina_SetVariable @SessionID, 'UTILIDAD_PCT', @Utilidad, 'Porcentaje utilidad';
    EXEC sp_Nomina_SetVariable @SessionID, 'COMISION_PCT', @Comision, 'Porcentaje comisión';
    
    -- Calcular antigüedad
    EXEC sp_Nomina_CalcularAntiguedad @SessionID, @Cedula, @FechaHasta;
    
    -- Variables de cálculo salarial
    DECLARE @SalarioDiario DECIMAL(18,4) = CASE WHEN @DiasPeriodo > 0 THEN @Sueldo / @DiasPeriodo ELSE 0 END;
    DECLARE @SalarioHora DECIMAL(18,4) = CASE WHEN @DiasPeriodo > 0 THEN @Sueldo / (@DiasPeriodo * 8) ELSE 0 END;
    
    EXEC sp_Nomina_SetVariable @SessionID, 'SALARIO_DIARIO', @SalarioDiario, 'Salario diario';
    EXEC sp_Nomina_SetVariable @SessionID, 'SALARIO_HORA', @SalarioHora, 'Salario por hora';
    EXEC sp_Nomina_SetVariable @SessionID, 'HORAS_MES', 240, 'Horas laborales mes (30 días x 8h)';
    
    -- Cargar valores de sueldos específicos si existen
    SELECT 
        @Sueldo = ISNULL(Sueldo, @Sueldo)
    FROM EmpleadoSueldo 
    WHERE Cedula = @Cedula AND Nomina = @Nomina;
    
    IF @Sueldo IS NOT NULL
        EXEC sp_Nomina_SetVariable @SessionID, 'SUELDO_ASIGNADO', @Sueldo, 'Sueldo asignado en ficha';
END
GO

PRINT 'Funciones base de nómina creadas exitosamente';
GO
