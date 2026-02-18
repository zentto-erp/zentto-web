-- =============================================
-- CÁLCULO DE VACACIONES Y LIQUIDACIÓN
-- Compatible con: SQL Server 2012+
-- =============================================

-- =============================================
-- 1. SP: Calcular salarios promedio para utilidades/vacaciones
-- =============================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_Nomina_CalcularSalariosPromedio')
    DROP PROCEDURE sp_Nomina_CalcularSalariosPromedio
GO

CREATE PROCEDURE sp_Nomina_CalcularSalariosPromedio
    @SessionID NVARCHAR(50),
    @Cedula NVARCHAR(12),
    @FechaDesde DATE,
    @FechaHasta DATE
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @Dias INT = DATEDIFF(DAY, @FechaDesde, @FechaHasta) + 1;
    DECLARE @AcumuladoAsignaciones DECIMAL(18,4) = 0;
    DECLARE @SalarioNormal DECIMAL(18,4) = 0;
    DECLARE @SalarioIntegral DECIMAL(18,4) = 0;
    DECLARE @BaseUtil DECIMAL(18,4) = 0;
    
    -- Obtener base de utilidad de constantes
    SELECT @BaseUtil = Valor FROM ConstanteNomina WHERE Codigo = 'BaseUtil';
    IF @BaseUtil IS NULL SET @BaseUtil = 0;
    
    -- Calcular acumulado de asignaciones bonificables en el período
    SELECT @AcumuladoAsignaciones = ISNULL(SUM(d.TOTAL), 0)
    FROM DtllNom d
    INNER JOIN ConcNom c ON d.CO_CONCEPTO = c.CO_CONCEPT AND c.CO_NOMINA = (SELECT NOMINA FROM Empleados WHERE CEDULA = @Cedula)
    WHERE d.CEDULA = @Cedula
      AND d.INICIO >= @FechaDesde
      AND d.HASTA <= @FechaHasta
      AND c.BONIFICABLE = 'S'
      AND c.TIPO = 'ASIGNACION';
    
    -- Si no hay datos de DtllNom, usar sueldo base
    IF @AcumuladoAsignaciones = 0
    BEGIN
        SELECT @AcumuladoAsignaciones = ISNULL(SUELDO, 0) * (@Dias / 30.0)
        FROM Empleados
        WHERE CEDULA = @Cedula;
    END
    
    -- Calcular salarios
    IF @Dias > 0
    BEGIN
        SET @SalarioNormal = @AcumuladoAsignaciones / @Dias;
        SET @SalarioIntegral = @SalarioNormal + (@SalarioNormal * @BaseUtil / 100);
    END
    
    -- Guardar variables
    EXEC sp_Nomina_SetVariable @SessionID, 'SALARIO_NORMAL', @SalarioNormal, 'Salario promedio diario';
    EXEC sp_Nomina_SetVariable @SessionID, 'SALARIO_INTEGRAL', @SalarioIntegral, 'Salario integral diario';
    EXEC sp_Nomina_SetVariable @SessionID, 'BASE_UTIL', @BaseUtil, 'Base utilidad %';
    EXEC sp_Nomina_SetVariable @SessionID, 'ACUMULADO_ASIG', @AcumuladoAsignaciones, 'Acumulado asignaciones';
    EXEC sp_Nomina_SetVariable @SessionID, 'DIAS_CALCULO', @Dias, 'Días de cálculo';
END
GO

-- =============================================
-- 2. SP: Calcular días de vacaciones según antigüedad
-- =============================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_Nomina_CalcularDiasVacaciones')
    DROP PROCEDURE sp_Nomina_CalcularDiasVacaciones
GO

CREATE PROCEDURE sp_Nomina_CalcularDiasVacaciones
    @SessionID NVARCHAR(50),
    @Cedula NVARCHAR(12),
    @FechaRetiro DATE = NULL,
    @DiasVacaciones DECIMAL(18,4) OUTPUT,
    @DiasBonoVacacional DECIMAL(18,4) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @FechaIngreso DATE
    DECLARE @TotalMeses INT
    DECLARE @TipoVacacion NVARCHAR(20)
    
    SELECT @FechaIngreso = INGRESO FROM Empleados WHERE CEDULA = @Cedula;
    
    IF @FechaRetiro IS NULL
        SET @FechaRetiro = GETDATE();
    
    IF @FechaIngreso IS NULL
    BEGIN
        SET @DiasVacaciones = 0;
        SET @DiasBonoVacacional = 0;
        RETURN;
    END
    
    SET @TotalMeses = DATEDIFF(MONTH, @FechaIngreso, @FechaRetiro);
    
    -- Buscar en tabla de antigüedad
    DECLARE @VacIndus FLOAT, @BonoVac FLOAT, @Normal FLOAT
    
    SELECT TOP 1 
        @VacIndus = VAC_INDUS,
        @BonoVac = BONO_VAC,
        @Normal = NORMAL
    FROM Antiguedad
    WHERE MESES <= @TotalMeses
    ORDER BY MESES DESC;
    
    -- Determinar tipo de vacaciones según sector
    SELECT @TipoVacacion = ISNULL(NOMINA, 'NORMAL') FROM Empleados WHERE CEDULA = @Cedula;
    
    IF @TipoVacacion LIKE '%INDUS%' OR @TipoVacacion LIKE '%PETRO%'
    BEGIN
        SET @DiasVacaciones = ISNULL(@VacIndus, 15);
    END
    ELSE
    BEGIN
        SET @DiasVacaciones = ISNULL(@Normal, 15);
    END
    
    SET @DiasBonoVacacional = ISNULL(@BonoVac, 0);
    
    -- Si es fraccionado (menos de un año), calcular proporcional
    DECLARE @MesesPeriodo INT = @TotalMeses % 12;
    IF @MesesPeriodo > 0 AND @MesesPeriodo < 12
    BEGIN
        SET @DiasVacaciones = (@DiasVacaciones / 12.0) * @MesesPeriodo;
        SET @DiasBonoVacacional = (@DiasBonoVacacional / 12.0) * @MesesPeriodo;
    END
    
    -- Guardar variables
    EXEC sp_Nomina_SetVariable @SessionID, 'DIAS_VACACIONES', @DiasVacaciones, 'Días de vacaciones';
    EXEC sp_Nomina_SetVariable @SessionID, 'DIAS_BONO_VAC', @DiasBonoVacacional, 'Días bono vacacional';
END
GO

-- =============================================
-- 3. SP: Procesar vacaciones
-- =============================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_Nomina_ProcesarVacaciones')
    DROP PROCEDURE sp_Nomina_ProcesarVacaciones
GO

CREATE PROCEDURE sp_Nomina_ProcesarVacaciones
    @VacacionID NVARCHAR(50),
    @Cedula NVARCHAR(12),
    @FechaInicio DATE,
    @FechaHasta DATE,
    @FechaReintegro DATE = NULL,
    @CoUsuario NVARCHAR(20) = 'API',
    @Resultado INT OUTPUT,
    @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    
    SET @Resultado = 0;
    SET @Mensaje = '';
    
    DECLARE @SessionID NVARCHAR(50) = 'VAC_' + @VacacionID;
    DECLARE @TipoNomina NVARCHAR(15);
    DECLARE @DiasVacaciones DECIMAL(18,4);
    DECLARE @DiasBonoVacacional DECIMAL(18,4);
    
    -- Verificar empleado
    IF NOT EXISTS (SELECT 1 FROM Empleados WHERE CEDULA = @Cedula AND STATUS = 'A')
    BEGIN
        SET @Resultado = -1;
        SET @Mensaje = 'Empleado no encontrado o inactivo';
        RETURN;
    END
    
    SELECT @TipoNomina = NOMINA FROM Empleados WHERE CEDULA = @Cedula;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Limpiar previos
        DELETE FROM DtllVacacion WHERE Vacacion = @VacacionID AND Cedula = @Cedula;
        DELETE FROM Vacacion WHERE Vacacion = @VacacionID AND Cedula = @Cedula;
        
        -- Preparar variables base
        EXEC sp_Nomina_PrepararVariablesBase @SessionID, @Cedula, @TipoNomina, @FechaInicio, @FechaHasta;
        
        -- Calcular salarios promedio (últimos 3 meses o lo que haya)
        DECLARE @FechaDesdeSalarios DATE = DATEADD(MONTH, -3, @FechaInicio);
        EXEC sp_Nomina_CalcularSalariosPromedio @SessionID, @Cedula, @FechaDesdeSalarios, @FechaInicio;
        
        -- Calcular días de vacaciones
        EXEC sp_Nomina_CalcularDiasVacaciones @SessionID, @Cedula, NULL, @DiasVacaciones OUTPUT, @DiasBonoVacacional OUTPUT;
        
        -- Obtener salario integral
        DECLARE @SalarioIntegral DECIMAL(18,4)
        SELECT @SalarioIntegral = Valor FROM VariablesCalculadas WHERE SessionID = @SessionID AND Variable = 'SALARIO_INTEGRAL';
        IF @SalarioIntegral IS NULL SET @SalarioIntegral = 0;
        
        -- Insertar vacaciones pagadas
        IF @DiasVacaciones > 0 AND @SalarioIntegral > 0
        BEGIN
            INSERT INTO DtllVacacion (Vacacion, Cedula, Co_Concepto, Cantidad, Monto, Total, Co_Usuario, NB_CONCEPTO)
            VALUES (@VacacionID, @Cedula, 'VAC_PAG', @DiasVacaciones, @SalarioIntegral, 
                    @DiasVacaciones * @SalarioIntegral, @CoUsuario, 'Vacaciones Pagadas');
        END
        
        -- Insertar bono vacacional
        IF @DiasBonoVacacional > 0 AND @SalarioIntegral > 0
        BEGIN
            INSERT INTO DtllVacacion (Vacacion, Cedula, Co_Concepto, Cantidad, Monto, Total, Co_Usuario, NB_CONCEPTO)
            VALUES (@VacacionID, @Cedula, 'BONO_VAC', @DiasBonoVacacional, @SalarioIntegral, 
                    @DiasBonoVacacional * @SalarioIntegral, @CoUsuario, 'Bono Vacacional');
        END
        
        -- Insertar cabecera
        DECLARE @TotalVacaciones DECIMAL(18,4) = (@DiasVacaciones + @DiasBonoVacacional) * @SalarioIntegral;
        
        INSERT INTO Vacacion (Vacacion, Cedula, Inicio, Hasta, Reintegro, Fecha_Calculo, Total, Co_Usuario)
        VALUES (@VacacionID, @Cedula, @FechaInicio, @FechaHasta, @FechaReintegro, GETDATE(), @TotalVacaciones, @CoUsuario);
        
        -- Limpiar
        EXEC sp_Nomina_LimpiarVariables @SessionID;
        
        COMMIT TRANSACTION;
        
        SET @Resultado = 1;
        SET @Mensaje = 'Vacaciones procesadas. Días: ' + CONVERT(NVARCHAR, @DiasVacaciones) + 
                       ', Bono: ' + CONVERT(NVARCHAR, @DiasBonoVacacional) + 
                       ', Total: ' + CONVERT(NVARCHAR, @TotalVacaciones);
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        SET @Resultado = -99;
        SET @Mensaje = ERROR_MESSAGE();
        EXEC sp_Nomina_LimpiarVariables @SessionID;
    END CATCH
END
GO

-- =============================================
-- 4. SP: Calcular liquidación (prestaciones)
-- =============================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_Nomina_CalcularLiquidacion')
    DROP PROCEDURE sp_Nomina_CalcularLiquidacion
GO

CREATE PROCEDURE sp_Nomina_CalcularLiquidacion
    @LiquidacionID NVARCHAR(50),
    @Cedula NVARCHAR(12),
    @FechaRetiro DATE,
    @CausaRetiro NVARCHAR(50) = 'RENUNCIA', -- RENUNCIA, DESPIDO, DESPIDO_JUSTIFICADO
    @CoUsuario NVARCHAR(20) = 'API',
    @Resultado INT OUTPUT,
    @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    
    SET @Resultado = 0;
    SET @Mensaje = '';
    
    DECLARE @SessionID NVARCHAR(50) = 'LIQ_' + @LiquidacionID;
    DECLARE @TipoNomina NVARCHAR(15);
    DECLARE @FechaIngreso DATE;
    DECLARE @SalarioMensual FLOAT;
    
    -- Verificar empleado
    IF NOT EXISTS (SELECT 1 FROM Empleados WHERE CEDULA = @Cedula)
    BEGIN
        SET @Resultado = -1;
        SET @Mensaje = 'Empleado no encontrado';
        RETURN;
    END
    
    SELECT 
        @TipoNomina = NOMINA, 
        @FechaIngreso = INGRESO,
        @SalarioMensual = ISNULL(SUELDO, 0)
    FROM Empleados 
    WHERE CEDULA = @Cedula;
    
    IF @FechaIngreso IS NULL
    BEGIN
        SET @Resultado = -2;
        SET @Mensaje = 'Empleado no tiene fecha de ingreso';
        RETURN;
    END
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Limpiar previos
        DELETE FROM DtllLiquidacion WHERE Liquidacion = @LiquidacionID AND Cedula = @Cedula;
        
        -- Preparar variables base (usar último mes)
        DECLARE @FechaDesde DATE = DATEADD(MONTH, -1, @FechaRetiro);
        EXEC sp_Nomina_PrepararVariablesBase @SessionID, @Cedula, @TipoNomina, @FechaDesde, @FechaRetiro;
        
        -- Calcular salarios promedio (últimos 3 meses)
        EXEC sp_Nomina_CalcularSalariosPromedio @SessionID, @Cedula, DATEADD(MONTH, -3, @FechaRetiro), @FechaRetiro;
        
        DECLARE @SalarioIntegral DECIMAL(18,4), @SalarioNormal DECIMAL(18,4);
        SELECT @SalarioIntegral = Valor FROM VariablesCalculadas WHERE SessionID = @SessionID AND Variable = 'SALARIO_INTEGRAL';
        SELECT @SalarioNormal = Valor FROM VariablesCalculadas WHERE SessionID = @SessionID AND Variable = 'SALARIO_NORMAL';
        
        IF @SalarioIntegral IS NULL SET @SalarioIntegral = @SalarioMensual / 30;
        IF @SalarioNormal IS NULL SET @SalarioNormal = @SalarioMensual / 30;
        
        -- Calcular antigüedad completa
        DECLARE @Anios INT, @Meses INT, @Dias INT;
        DECLARE @DiasTotales INT = DATEDIFF(DAY, @FechaIngreso, @FechaRetiro);
        SET @Anios = @DiasTotales / 365;
        SET @Meses = (@DiasTotales % 365) / 30;
        SET @Dias = (@DiasTotales % 365) % 30;
        
        -- Días de prestaciones según antigüedad
        DECLARE @PreavisoDias INT = 0;
        DECLARE @VacacionesPendientes DECIMAL(18,4) = 0;
        DECLARE @BonoVacacionalPendiente DECIMAL(18,4) = 0;
        
        -- Obtener valores de antigüedad
        DECLARE @TotalMeses INT = DATEDIFF(MONTH, @FechaIngreso, @FechaRetiro);
        DECLARE @Legal FLOAT, @VacIndus FLOAT, @BonoVac FLOAT, @Adicional FLOAT;
        
        SELECT TOP 1 
            @Legal = LEGAL,
            @VacIndus = VAC_INDUS,
            @BonoVac = BONO_VAC,
            @Adicional = ADICIONAL
        FROM Antiguedad
        WHERE MESES <= @TotalMeses
        ORDER BY MESES DESC;
        
        -- Preaviso según antigüedad (solo si es despido sin justificación)
        IF @CausaRetiro = 'DESPIDO'
        BEGIN
            IF @TotalMeses >= 3 AND @TotalMeses < 6 SET @PreavisoDias = 7;
            ELSE IF @TotalMeses >= 6 AND @TotalMeses < 12 SET @PreavisoDias = 15;
            ELSE IF @TotalMeses >= 12 SET @PreavisoDias = ISNULL(@Legal, 30);
        END
        
        -- Vacaciones proporcionales (año en curso)
        DECLARE @MesesAnio INT = @TotalMeses % 12;
        SET @VacacionesPendientes = (ISNULL(@VacIndus, 15) / 12.0) * @MesesAnio;
        SET @BonoVacacionalPendiente = (ISNULL(@BonoVac, 15) / 12.0) * @MesesAnio;
        
        -- Insertar detalles de liquidación
        
        -- 1. Preaviso (si aplica)
        IF @PreavisoDias > 0
        BEGIN
            INSERT INTO DtllLiquidacion (Liquidacion, Cedula, Co_Concepto, Cantidad, Monto, Total, Co_Usuario, NB_CONCEPTO)
            VALUES (@LiquidacionID, @Cedula, 'PREAVISO', @PreavisoDias, @SalarioIntegral, 
                    @PreavisoDias * @SalarioIntegral, @CoUsuario, 'Preaviso');
        END
        
        -- 2. Vacaciones proporcionales
        IF @VacacionesPendientes > 0
        BEGIN
            INSERT INTO DtllLiquidacion (Liquidacion, Cedula, Co_Concepto, Cantidad, Monto, Total, Co_Usuario, NB_CONCEPTO)
            VALUES (@LiquidacionID, @Cedula, 'VAC_PROP', @VacacionesPendientes, @SalarioIntegral, 
                    @VacacionesPendientes * @SalarioIntegral, @CoUsuario, 'Vacaciones Proporcionales');
        END
        
        -- 3. Bono vacacional proporcional
        IF @BonoVacacionalPendiente > 0
        BEGIN
            INSERT INTO DtllLiquidacion (Liquidacion, Cedula, Co_Concepto, Cantidad, Monto, Total, Co_Usuario, NB_CONCEPTO)
            VALUES (@LiquidacionID, @Cedula, 'BONO_VAC_PROP', @BonoVacacionalPendiente, @SalarioIntegral, 
                    @BonoVacacionalPendiente * @SalarioIntegral, @CoUsuario, 'Bono Vacacional Proporcional');
        END
        
        -- 4. Utilidades proporcionales (días del año trabajados)
        DECLARE @DiasAnio INT = DATEDIFF(DAY, DATEADD(YEAR, DATEDIFF(YEAR, @FechaIngreso, @FechaRetiro), @FechaIngreso), @FechaRetiro);
        IF @DiasAnio < 0 SET @DiasAnio = @DiasTotales; -- Primer año
        
        DECLARE @Utilidades DECIMAL(18,4) = 0;
        SELECT @Utilidades = Utilidad FROM Empleados WHERE CEDULA = @Cedula;
        IF @Utilidades IS NULL SET @Utilidades = 0;
        
        IF @Utilidades > 0 AND @DiasAnio > 0
        BEGIN
            DECLARE @MontoUtilidades DECIMAL(18,4) = (@Utilidades / 360) * @DiasAnio;
            INSERT INTO DtllLiquidacion (Liquidacion, Cedula, Co_Concepto, Cantidad, Monto, Total, Co_Usuario, NB_CONCEPTO)
            VALUES (@LiquidacionID, @Cedula, 'UTIL_PROP', @DiasAnio, @MontoUtilidades / @DiasAnio, 
                    @MontoUtilidades, @CoUsuario, 'Utilidades Proporcionales');
        END
        
        -- 5. Indemnización (si aplica - solo despido sin justificación)
        IF @CausaRetiro = 'DESPIDO' AND @TotalMeses >= 3
        BEGIN
            DECLARE @Indemnizacion DECIMAL(18,4) = @SalarioIntegral * @Anios;
            IF @Meses >= 6 SET @Indemnizacion = @Indemnizacion + @SalarioIntegral;
            
            IF @Indemnizacion > 0
            BEGIN
                INSERT INTO DtllLiquidacion (Liquidacion, Cedula, Co_Concepto, Cantidad, Monto, Total, Co_Usuario, NB_CONCEPTO)
                VALUES (@LiquidacionID, @Cedula, 'INDEMNIZ', @Anios + CASE WHEN @Meses >= 6 THEN 1 ELSE 0 END, 
                        @SalarioIntegral, @Indemnizacion, @CoUsuario, 'Indemnización por Antigüedad');
            END
        END
        
        -- Calcular total
        DECLARE @TotalLiquidacion DECIMAL(18,4);
        SELECT @TotalLiquidacion = ISNULL(SUM(Total), 0) FROM DtllLiquidacion WHERE Liquidacion = @LiquidacionID AND Cedula = @Cedula;
        
        -- Limpiar
        EXEC sp_Nomina_LimpiarVariables @SessionID;
        
        COMMIT TRANSACTION;
        
        SET @Resultado = 1;
        SET @Mensaje = 'Liquidación calculada exitosamente. Total: ' + CONVERT(NVARCHAR, @TotalLiquidacion);
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        SET @Resultado = -99;
        SET @Mensaje = ERROR_MESSAGE();
        EXEC sp_Nomina_LimpiarVariables @SessionID;
    END CATCH
END
GO

-- =============================================
-- 5. SP: Consultar detalle de liquidación
-- =============================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_Nomina_GetLiquidacion')
    DROP PROCEDURE sp_Nomina_GetLiquidacion
GO

CREATE PROCEDURE sp_Nomina_GetLiquidacion
    @LiquidacionID NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Cabecera
    SELECT 
        l.*,
        e.NOMBRE as NombreEmpleado,
        e.CARGO,
        e.INGRESO as FechaIngreso
    FROM DtllLiquidacion l
    INNER JOIN Empleados e ON l.Cedula = e.CEDULA
    WHERE l.Liquidacion = @LiquidacionID
    ORDER BY l.Co_Concepto;
    
    -- Totales
    SELECT 
        SUM(CASE WHEN l.Total > 0 THEN l.Total ELSE 0 END) as TotalAsignaciones,
        SUM(CASE WHEN l.Total < 0 THEN l.Total ELSE 0 END) as TotalDeducciones,
        SUM(l.Total) as TotalNeto
    FROM DtllLiquidacion l
    WHERE l.Liquidacion = @LiquidacionID;
END
GO

PRINT 'SPs de vacaciones y liquidación creados exitosamente';
GO
