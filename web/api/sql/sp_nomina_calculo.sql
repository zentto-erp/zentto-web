-- =============================================
-- MOTOR DE CÁLCULO DE NÓMINA CON FÓRMULAS
-- Compatible con: SQL Server 2012+
-- =============================================

-- =============================================
-- 1. SP: Reemplazar variables en fórmula
-- =============================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_Nomina_ReemplazarVariables')
    DROP PROCEDURE sp_Nomina_ReemplazarVariables
GO

CREATE PROCEDURE sp_Nomina_ReemplazarVariables
    @SessionID NVARCHAR(50),
    @Formula NVARCHAR(MAX),
    @FormulaOut NVARCHAR(MAX) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @Result NVARCHAR(MAX) = @Formula
    DECLARE @VarName NVARCHAR(50)
    DECLARE @VarValue DECIMAL(18,4)
    DECLARE @VarStr NVARCHAR(50)
    
    -- Cursor para reemplazar todas las variables
    DECLARE var_cursor CURSOR FOR
        SELECT Variable, CAST(Valor AS NVARCHAR(50))
        FROM VariablesCalculadas
        WHERE SessionID = @SessionID
        ORDER BY LEN(Variable) DESC; -- Reemplazar las más largas primero
    
    OPEN var_cursor
    FETCH NEXT FROM var_cursor INTO @VarName, @VarStr
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @Result = REPLACE(@Result, @VarName, @VarStr)
        FETCH NEXT FROM var_cursor INTO @VarName, @VarStr
    END
    
    CLOSE var_cursor
    DEALLOCATE var_cursor
    
    SET @FormulaOut = @Result
END
GO

-- =============================================
-- 2. SP: Evaluar fórmula completa
-- =============================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_Nomina_EvaluarFormula')
    DROP PROCEDURE sp_Nomina_EvaluarFormula
GO

CREATE PROCEDURE sp_Nomina_EvaluarFormula
    @SessionID NVARCHAR(50),
    @Formula NVARCHAR(MAX),
    @Resultado DECIMAL(18,4) OUTPUT,
    @FormulaResuelta NVARCHAR(MAX) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Resultado = 0;
    SET @FormulaResuelta = '';
    
    IF @Formula IS NULL OR LTRIM(RTRIM(@Formula)) = ''
        RETURN;
    
    DECLARE @FormulaLimpia NVARCHAR(MAX)
    SET @FormulaLimpia = LTRIM(RTRIM(@Formula))
    
    -- Reemplazar variables
    EXEC sp_Nomina_ReemplazarVariables @SessionID, @FormulaLimpia, @FormulaResuelta OUTPUT;
    
    -- Limpiar caracteres no permitidos (mantener solo matemáticos)
    SET @FormulaResuelta = REPLACE(@FormulaResuelta, CHAR(13), '');
    SET @FormulaResuelta = REPLACE(@FormulaResuelta, CHAR(10), '');
    SET @FormulaResuelta = REPLACE(@FormulaResuelta, CHAR(9), ' ');
    
    -- Evaluar usando función
    SET @Resultado = dbo.fn_EvaluarExpr(@FormulaResuelta);
END
GO

-- =============================================
-- 3. SP: Calcular concepto de nómina
-- =============================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_Nomina_CalcularConcepto')
    DROP PROCEDURE sp_Nomina_CalcularConcepto
GO

CREATE PROCEDURE sp_Nomina_CalcularConcepto
    @SessionID NVARCHAR(50),
    @Cedula NVARCHAR(12),
    @CoConcepto NVARCHAR(10),
    @CoNomina NVARCHAR(15),
    @Cantidad DECIMAL(18,4) = NULL,
    @Monto DECIMAL(18,4) OUTPUT,
    @Total DECIMAL(18,4) OUTPUT,
    @Descripcion NVARCHAR(100) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    SET @Monto = 0;
    SET @Total = 0;
    SET @Descripcion = '';
    
    -- Obtener datos del concepto
    DECLARE @Formula NVARCHAR(255)
    DECLARE @Sobre NVARCHAR(255)
    DECLARE @Tipo NVARCHAR(15)
    DECLARE @Uso NVARCHAR(15)
    DECLARE @Defecto FLOAT
    DECLARE @NombreConcepto NVARCHAR(100)
    
    SELECT 
        @Formula = FORMULA,
        @Sobre = SOBRE,
        @Tipo = TIPO,
        @Uso = USO,
        @Defecto = Defecto,
        @NombreConcepto = NB_CONCEPTO
    FROM ConcNom
    WHERE CO_CONCEPT = @CoConcepto AND CO_NOMINA = @CoNomina;
    
    IF @NombreConcepto IS NULL
    BEGIN
        SET @Descripcion = 'Concepto no encontrado';
        RETURN;
    END
    
    SET @Descripcion = @NombreConcepto;
    
    -- Si hay valor por defecto y no hay fórmula, usar defecto
    IF (@Formula IS NULL OR LTRIM(RTRIM(@Formula)) = '') AND @Defecto IS NOT NULL
    BEGIN
        SET @Monto = @Defecto;
        SET @Total = @Monto * ISNULL(@Cantidad, 1);
        
        -- Guardar valor para referencias
        EXEC sp_Nomina_SetVariable @SessionID, 'C' + @CoConcepto, @Total, @NombreConcepto;
        RETURN;
    END
    
    -- Si hay fórmula, evaluarla
    IF @Formula IS NOT NULL AND LTRIM(RTRIM(@Formula)) != ''
    BEGIN
        DECLARE @FormulaResuelta NVARCHAR(MAX)
        EXEC sp_Nomina_EvaluarFormula @SessionID, @Formula, @Monto OUTPUT, @FormulaResuelta OUTPUT;
    END
    
    -- Si hay base de cálculo (SOBRE), calcular sobre esa base
    IF @Sobre IS NOT NULL AND LTRIM(RTRIM(@Sobre)) != ''
    BEGIN
        DECLARE @BaseCalculo DECIMAL(18,4)
        DECLARE @FormulaSobre NVARCHAR(MAX)
        EXEC sp_Nomina_EvaluarFormula @SessionID, @Sobre, @BaseCalculo OUTPUT, @FormulaSobre OUTPUT;
        
        SET @Total = @Monto * @BaseCalculo;
    END
    ELSE
    BEGIN
        SET @Total = @Monto * ISNULL(@Cantidad, 1);
    END
    
    -- Guardar valor total para posibles referencias
    EXEC sp_Nomina_SetVariable @SessionID, 'C' + @CoConcepto, @Total, @NombreConcepto;
END
GO

-- =============================================
-- 4. SP: Procesar nómina completa de empleado
-- =============================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_Nomina_ProcesarEmpleado')
    DROP PROCEDURE sp_Nomina_ProcesarEmpleado
GO

CREATE PROCEDURE sp_Nomina_ProcesarEmpleado
    @Nomina NVARCHAR(10),
    @Cedula NVARCHAR(12),
    @FechaInicio DATE,
    @FechaHasta DATE,
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
    DECLARE @TipoNomina NVARCHAR(15);
    
    -- Verificar empleado
    IF NOT EXISTS (SELECT 1 FROM Empleados WHERE CEDULA = @Cedula AND STATUS = 'A')
    BEGIN
        SET @Resultado = -1;
        SET @Mensaje = 'Empleado no encontrado o inactivo';
        RETURN;
    END
    
    -- Obtener tipo de nómina del empleado
    SELECT @TipoNomina = NOMINA FROM Empleados WHERE CEDULA = @Cedula;
    
    IF @TipoNomina IS NULL
    BEGIN
        SET @Resultado = -2;
        SET @Mensaje = 'Empleado no tiene tipo de nómina asignado';
        RETURN;
    END
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Eliminar cálculo anterior si existe
        DELETE FROM DtllNom WHERE NOMINA = @Nomina AND CEDULA = @Cedula;
        DELETE FROM Nomina WHERE NOMINA = @Nomina AND CEDULA = @Cedula;
        
        -- Preparar variables base
        EXEC sp_Nomina_PrepararVariablesBase @SessionID, @Cedula, @Nomina, @FechaInicio, @FechaHasta;
        
        -- Variables para acumulados
        DECLARE @TotalAsignaciones DECIMAL(18,4) = 0;
        DECLARE @TotalDeducciones DECIMAL(18,4) = 0;
        
        -- Procesar conceptos en orden (ASIGNACIONES primero)
        DECLARE @CoConcepto NVARCHAR(10)
        DECLARE @Monto DECIMAL(18,4)
        DECLARE @Total DECIMAL(18,4)
        DECLARE @Descripcion NVARCHAR(100)
        DECLARE @Tipo NVARCHAR(15)
        
        -- Cursor para ASIGNACIONES
        DECLARE concept_cursor CURSOR FOR
            SELECT CO_CONCEPT, TIPO
            FROM ConcNom
            WHERE CO_NOMINA = @TipoNomina
              AND (TIPO = 'ASIGNACION' OR TIPO = 'BONO')
              AND (Aplica IS NULL OR Aplica = 'S')
            ORDER BY CO_CONCEPT;
        
        OPEN concept_cursor
        FETCH NEXT FROM concept_cursor INTO @CoConcepto, @Tipo
        
        WHILE @@FETCH_STATUS = 0
        BEGIN
            EXEC sp_Nomina_CalcularConcepto 
                @SessionID, @Cedula, @CoConcepto, @TipoNomina, 
                1, @Monto OUTPUT, @Total OUTPUT, @Descripcion OUTPUT;
            
            IF @Total != 0
            BEGIN
                INSERT INTO DtllNom (NOMINA, CO_CONCEPTO, CEDULA, INICIO, HASTA, CANTIDAD, MONTO, TOTAL, 
                                     Co_Usuario, Descripcion, Tipo)
                VALUES (@Nomina, @CoConcepto, @Cedula, @FechaInicio, @FechaHasta, 1, @Monto, @Total,
                        @CoUsuario, @Descripcion, @Tipo);
                
                SET @TotalAsignaciones = @TotalAsignaciones + @Total;
            END
            
            FETCH NEXT FROM concept_cursor INTO @CoConcepto, @Tipo
        END
        
        CLOSE concept_cursor
        DEALLOCATE concept_cursor
        
        -- Guardar total asignaciones para usar en deducciones
        EXEC sp_Nomina_SetVariable @SessionID, 'TOTAL_ASIGNACIONES', @TotalAsignaciones, 'Total asignaciones';
        
        -- Cursor para DEDUCCIONES
        DECLARE concept_cursor CURSOR FOR
            SELECT CO_CONCEPT, TIPO
            FROM ConcNom
            WHERE CO_NOMINA = @TipoNomina
              AND TIPO = 'DEDUCCION'
              AND (Aplica IS NULL OR Aplica = 'S')
            ORDER BY CO_CONCEPT;
        
        OPEN concept_cursor
        FETCH NEXT FROM concept_cursor INTO @CoConcepto, @Tipo
        
        WHILE @@FETCH_STATUS = 0
        BEGIN
            EXEC sp_Nomina_CalcularConcepto 
                @SessionID, @Cedula, @CoConcepto, @TipoNomina, 
                1, @Monto OUTPUT, @Total OUTPUT, @Descripcion OUTPUT;
            
            IF @Total != 0
            BEGIN
                INSERT INTO DtllNom (NOMINA, CO_CONCEPTO, CEDULA, INICIO, HASTA, CANTIDAD, MONTO, TOTAL, 
                                     Co_Usuario, Descripcion, Tipo)
                VALUES (@Nomina, @CoConcepto, @Cedula, @FechaInicio, @FechaHasta, 1, @Monto, @Total,
                        @CoUsuario, @Descripcion, @Tipo);
                
                SET @TotalDeducciones = @TotalDeducciones + @Total;
            END
            
            FETCH NEXT FROM concept_cursor INTO @CoConcepto, @Tipo
        END
        
        CLOSE concept_cursor
        DEALLOCATE concept_cursor
        
        -- Insertar/Actualizar cabecera de nómina
        INSERT INTO Nomina (NOMINA, CEDULA, FECHA, INICIO, HASTA, ASIGNACION, DEDUCCION, TOTAL, CERRADA)
        VALUES (@Nomina, @Cedula, GETDATE(), @FechaInicio, @FechaHasta, 
                @TotalAsignaciones, @TotalDeducciones, @TotalAsignaciones - @TotalDeducciones, 0);
        
        -- Limpiar variables temporales
        EXEC sp_Nomina_LimpiarVariables @SessionID;
        
        COMMIT TRANSACTION;
        
        SET @Resultado = 1;
        SET @Mensaje = 'Nómina procesada exitosamente. Asignaciones: ' + 
                       CONVERT(NVARCHAR, @TotalAsignaciones) + 
                       ', Deducciones: ' + CONVERT(NVARCHAR, @TotalDeducciones);
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        SET @Resultado = -99;
        SET @Mensaje = ERROR_MESSAGE();
        
        -- Limpiar variables en caso de error
        EXEC sp_Nomina_LimpiarVariables @SessionID;
    END CATCH
END
GO

-- =============================================
-- 5. SP: Procesar nómina completa (todos los empleados)
-- =============================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_Nomina_ProcesarNomina')
    DROP PROCEDURE sp_Nomina_ProcesarNomina
GO

CREATE PROCEDURE sp_Nomina_ProcesarNomina
    @Nomina NVARCHAR(10),
    @FechaInicio DATE,
    @FechaHasta DATE,
    @CoUsuario NVARCHAR(20) = 'API',
    @SoloActivos BIT = 1,
    @Procesados INT OUTPUT,
    @Errores INT OUTPUT,
    @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    SET @Procesados = 0;
    SET @Errores = 0;
    SET @Mensaje = '';
    
    DECLARE @Cedula NVARCHAR(12)
    DECLARE @Nombre NVARCHAR(50)
    DECLARE @Resultado INT
    DECLARE @Msg NVARCHAR(500)
    
    -- Cursor de empleados
    DECLARE emp_cursor CURSOR FOR
        SELECT CEDULA, NOMBRE
        FROM Empleados
        WHERE (@SoloActivos = 0 OR STATUS = 'A')
          AND (NOMINA IS NOT NULL)
        ORDER BY CEDULA;
    
    OPEN emp_cursor
    FETCH NEXT FROM emp_cursor INTO @Cedula, @Nombre
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        EXEC sp_Nomina_ProcesarEmpleado 
            @Nomina, @Cedula, @FechaInicio, @FechaHasta, @CoUsuario,
            @Resultado OUTPUT, @Msg OUTPUT;
        
        IF @Resultado > 0
            SET @Procesados = @Procesados + 1;
        ELSE
        BEGIN
            SET @Errores = @Errores + 1;
            SET @Mensaje = @Mensaje + @Nombre + ': ' + @Msg + '; ';
        END
        
        FETCH NEXT FROM emp_cursor INTO @Cedula, @Nombre
    END
    
    CLOSE emp_cursor
    DEALLOCATE emp_cursor
    
    IF @Errores = 0
        SET @Mensaje = 'Nómina procesada exitosamente. Empleados procesados: ' + CONVERT(NVARCHAR, @Procesados);
    ELSE
        SET @Mensaje = 'Nómina procesada con ' + CONVERT(NVARCHAR, @Errores) + ' errores. Procesados: ' + 
                       CONVERT(NVARCHAR, @Procesados);
END
GO

PRINT 'Motor de cálculo de nómina creado exitosamente';
GO
