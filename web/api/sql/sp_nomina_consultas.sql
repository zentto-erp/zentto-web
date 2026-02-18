-- =============================================
-- CONSULTAS Y LISTADOS DE NÓMINA
-- Compatible con: SQL Server 2012+
-- =============================================

-- =============================================
-- 1. SP: Listar conceptos de nómina
-- =============================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_Nomina_Conceptos_List')
    DROP PROCEDURE sp_Nomina_Conceptos_List
GO

CREATE PROCEDURE sp_Nomina_Conceptos_List
    @CoNomina NVARCHAR(15) = NULL,
    @Tipo NVARCHAR(15) = NULL,
    @Search NVARCHAR(100) = NULL,
    @Page INT = 1,
    @Limit INT = 50,
    @TotalCount INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Offset INT = (@Page - 1) * @Limit;
    
    SELECT @TotalCount = COUNT(*) 
    FROM ConcNom
    WHERE (@CoNomina IS NULL OR CO_NOMINA = @CoNomina)
      AND (@Tipo IS NULL OR TIPO = @Tipo)
      AND (@Search IS NULL OR NB_CONCEPTO LIKE '%' + @Search + '%' OR CO_CONCEPT LIKE '%' + @Search + '%');
    
    SELECT 
        CO_CONCEPT as Codigo,
        CO_NOMINA as CodigoNomina,
        NB_CONCEPTO as Nombre,
        FORMULA as Formula,
        SOBRE as Sobre,
        CLASE as Clase,
        TIPO as Tipo,
        USO as Uso,
        BONIFICABLE as Bonificable,
        Antiguedad as EsAntiguedad,
        Contable as CuentaContable,
        Aplica as Aplica,
        Defecto as ValorDefecto
    FROM ConcNom
    WHERE (@CoNomina IS NULL OR CO_NOMINA = @CoNomina)
      AND (@Tipo IS NULL OR TIPO = @Tipo)
      AND (@Search IS NULL OR NB_CONCEPTO LIKE '%' + @Search + '%' OR CO_CONCEPT LIKE '%' + @Search + '%')
    ORDER BY CO_NOMINA, TIPO, CO_CONCEPT
    OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;
END
GO

-- =============================================
-- 2. SP: Guardar/Actualizar concepto
-- =============================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_Nomina_Concepto_Save')
    DROP PROCEDURE sp_Nomina_Concepto_Save
GO

CREATE PROCEDURE sp_Nomina_Concepto_Save
    @CoConcept NVARCHAR(10),
    @CoNomina NVARCHAR(15),
    @NbConcepto NVARCHAR(100),
    @Formula NVARCHAR(255) = NULL,
    @Sobre NVARCHAR(255) = NULL,
    @Clase NVARCHAR(15) = NULL,
    @Tipo NVARCHAR(15) = NULL,
    @Uso NVARCHAR(15) = NULL,
    @Bonificable NVARCHAR(1) = NULL,
    @Antiguedad NVARCHAR(1) = NULL,
    @Contable NVARCHAR(50) = NULL,
    @Aplica NVARCHAR(1) = 'S',
    @Defecto FLOAT = NULL,
    @Resultado INT OUTPUT,
    @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Resultado = 0;
    SET @Mensaje = '';
    
    BEGIN TRY
        IF EXISTS (SELECT 1 FROM ConcNom WHERE CO_CONCEPT = @CoConcept AND CO_NOMINA = @CoNomina)
        BEGIN
            -- Actualizar
            UPDATE ConcNom SET
                NB_CONCEPTO = @NbConcepto,
                FORMULA = @Formula,
                SOBRE = @Sobre,
                CLASE = @Clase,
                TIPO = @Tipo,
                USO = @Uso,
                BONIFICABLE = @Bonificable,
                Antiguedad = @Antiguedad,
                Contable = @Contable,
                Aplica = @Aplica,
                Defecto = @Defecto
            WHERE CO_CONCEPT = @CoConcept AND CO_NOMINA = @CoNomina;
            
            SET @Resultado = 1;
            SET @Mensaje = 'Concepto actualizado exitosamente';
        END
        ELSE
        BEGIN
            -- Insertar
            INSERT INTO ConcNom (CO_CONCEPT, CO_NOMINA, NB_CONCEPTO, FORMULA, SOBRE, CLASE, TIPO, USO,
                                 BONIFICABLE, Antiguedad, Contable, Aplica, Defecto)
            VALUES (@CoConcept, @CoNomina, @NbConcepto, @Formula, @Sobre, @Clase, @Tipo, @Uso,
                    @Bonificable, @Antiguedad, @Contable, @Aplica, @Defecto);
            
            SET @Resultado = 1;
            SET @Mensaje = 'Concepto creado exitosamente';
        END
    END TRY
    BEGIN CATCH
        SET @Resultado = -99;
        SET @Mensaje = ERROR_MESSAGE();
    END CATCH
END
GO

-- =============================================
-- 3. SP: Listar nóminas procesadas
-- =============================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_Nomina_List')
    DROP PROCEDURE sp_Nomina_List
GO

CREATE PROCEDURE sp_Nomina_List
    @Nomina NVARCHAR(10) = NULL,
    @Cedula NVARCHAR(12) = NULL,
    @FechaDesde DATE = NULL,
    @FechaHasta DATE = NULL,
    @SoloAbiertas BIT = 0,
    @Page INT = 1,
    @Limit INT = 50,
    @TotalCount INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Offset INT = (@Page - 1) * @Limit;
    
    SELECT @TotalCount = COUNT(*) 
    FROM Nomina n
    WHERE (@Nomina IS NULL OR n.NOMINA = @Nomina)
      AND (@Cedula IS NULL OR n.CEDULA = @Cedula)
      AND (@FechaDesde IS NULL OR n.INICIO >= @FechaDesde)
      AND (@FechaHasta IS NULL OR n.HASTA <= @FechaHasta)
      AND (@SoloAbiertas = 0 OR n.CERRADA = 0);
    
    SELECT 
        n.NOMINA as Nomina,
        n.CEDULA as Cedula,
        e.NOMBRE as NombreEmpleado,
        n.FECHA as FechaProceso,
        n.INICIO as FechaInicio,
        n.HASTA as FechaHasta,
        n.ASIGNACION as TotalAsignaciones,
        n.DEDUCCION as TotalDeducciones,
        n.TOTAL as TotalNeto,
        n.CERRADA as Cerrada,
        e.NOMINA as TipoNomina
    FROM Nomina n
    INNER JOIN Empleados e ON n.CEDULA = e.CEDULA
    WHERE (@Nomina IS NULL OR n.NOMINA = @Nomina)
      AND (@Cedula IS NULL OR n.CEDULA = @Cedula)
      AND (@FechaDesde IS NULL OR n.INICIO >= @FechaDesde)
      AND (@FechaHasta IS NULL OR n.HASTA <= @FechaHasta)
      AND (@SoloAbiertas = 0 OR n.CERRADA = 0)
    ORDER BY n.NOMINA DESC, n.FECHA DESC
    OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;
END
GO

-- =============================================
-- 4. SP: Obtener detalle de nómina
-- =============================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_Nomina_Get')
    DROP PROCEDURE sp_Nomina_Get
GO

CREATE PROCEDURE sp_Nomina_Get
    @Nomina NVARCHAR(10),
    @Cedula NVARCHAR(12)
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Cabecera
    SELECT 
        n.*,
        e.NOMBRE as NombreEmpleado,
        e.CARGO,
        e.NOMINA as TipoNomina
    FROM Nomina n
    INNER JOIN Empleados e ON n.CEDULA = e.CEDULA
    WHERE n.NOMINA = @Nomina AND n.CEDULA = @Cedula;
    
    -- Detalle
    SELECT 
        d.*,
        c.NB_CONCEPTO as NombreConcepto,
        c.TIPO as TipoConcepto,
        c.CONTABLE as CuentaContable
    FROM DtllNom d
    LEFT JOIN ConcNom c ON d.CO_CONCEPTO = c.CO_CONCEPT AND c.CO_NOMINA = (SELECT NOMINA FROM Empleados WHERE CEDULA = @Cedula)
    WHERE d.NOMINA = @Nomina AND d.CEDULA = @Cedula
    ORDER BY c.TIPO, d.CO_CONCEPTO;
END
GO

-- =============================================
-- 5. SP: Cerrar nómina
-- =============================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_Nomina_Cerrar')
    DROP PROCEDURE sp_Nomina_Cerrar
GO

CREATE PROCEDURE sp_Nomina_Cerrar
    @Nomina NVARCHAR(10),
    @Cedula NVARCHAR(12) = NULL, -- NULL = cerrar todos
    @CoUsuario NVARCHAR(20) = 'API',
    @Resultado INT OUTPUT,
    @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Resultado = 0;
    SET @Mensaje = '';
    
    BEGIN TRY
        IF @Cedula IS NOT NULL
        BEGIN
            UPDATE Nomina SET CERRADA = 1 WHERE NOMINA = @Nomina AND CEDULA = @Cedula;
            SET @Resultado = 1;
            SET @Mensaje = 'Nómina cerrada para el empleado';
        END
        ELSE
        BEGIN
            UPDATE Nomina SET CERRADA = 1 WHERE NOMINA = @Nomina;
            SET @Resultado = @@ROWCOUNT;
            SET @Mensaje = 'Nómina cerrada para ' + CONVERT(NVARCHAR, @Resultado) + ' empleados';
        END
    END TRY
    BEGIN CATCH
        SET @Resultado = -99;
        SET @Mensaje = ERROR_MESSAGE();
    END CATCH
END
GO

-- =============================================
-- 6. SP: Listar vacaciones
-- =============================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_Nomina_Vacaciones_List')
    DROP PROCEDURE sp_Nomina_Vacaciones_List
GO

CREATE PROCEDURE sp_Nomina_Vacaciones_List
    @Cedula NVARCHAR(12) = NULL,
    @Page INT = 1,
    @Limit INT = 50,
    @TotalCount INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Offset INT = (@Page - 1) * @Limit;
    
    SELECT @TotalCount = COUNT(*) FROM Vacacion WHERE (@Cedula IS NULL OR Cedula = @Cedula);
    
    SELECT 
        v.*,
        e.NOMBRE as NombreEmpleado,
        e.CARGO,
        (SELECT SUM(Total) FROM DtllVacacion WHERE Vacacion = v.Vacacion AND Cedula = v.Cedula) as TotalCalculado
    FROM Vacacion v
    INNER JOIN Empleados e ON v.Cedula = e.CEDULA
    WHERE (@Cedula IS NULL OR v.Cedula = @Cedula)
    ORDER BY v.Fecha_Calculo DESC
    OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;
END
GO

-- =============================================
-- 7. SP: Obtener detalle de vacaciones
-- =============================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_Nomina_Vacaciones_Get')
    DROP PROCEDURE sp_Nomina_Vacaciones_Get
GO

CREATE PROCEDURE sp_Nomina_Vacaciones_Get
    @VacacionID NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Cabecera
    SELECT v.*, e.NOMBRE as NombreEmpleado, e.CARGO
    FROM Vacacion v
    INNER JOIN Empleados e ON v.Cedula = e.CEDULA
    WHERE v.Vacacion = @VacacionID;
    
    -- Detalle
    SELECT * FROM DtllVacacion WHERE Vacacion = @VacacionID ORDER BY Co_Concepto;
END
GO

-- =============================================
-- 8. SP: Listar liquidaciones
-- =============================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_Nomina_Liquidaciones_List')
    DROP PROCEDURE sp_Nomina_Liquidaciones_List
GO

CREATE PROCEDURE sp_Nomina_Liquidaciones_List
    @Cedula NVARCHAR(12) = NULL,
    @Page INT = 1,
    @Limit INT = 50,
    @TotalCount INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Offset INT = (@Page - 1) * @Limit;
    
    SELECT @TotalCount = COUNT(DISTINCT Liquidacion) FROM DtllLiquidacion WHERE (@Cedula IS NULL OR Cedula = @Cedula);
    
    SELECT 
        l.Liquidacion,
        l.Cedula,
        e.NOMBRE as NombreEmpleado,
        e.CARGO,
        e.INGRESO as FechaIngreso,
        MAX(l.Calculado) as FechaCalculo,
        SUM(l.Total) as TotalLiquidacion
    FROM DtllLiquidacion l
    INNER JOIN Empleados e ON l.Cedula = e.CEDULA
    WHERE (@Cedula IS NULL OR l.Cedula = @Cedula)
    GROUP BY l.Liquidacion, l.Cedula, e.NOMBRE, e.CARGO, e.INGRESO
    ORDER BY MAX(l.Calculado) DESC
    OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;
END
GO

-- =============================================
-- 9. SP: Constantes de nómina
-- =============================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_Nomina_Constantes_List')
    DROP PROCEDURE sp_Nomina_Constantes_List
GO

CREATE PROCEDURE sp_Nomina_Constantes_List
    @Page INT = 1,
    @Limit INT = 50,
    @TotalCount INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Offset INT = (@Page - 1) * @Limit;
    
    SELECT @TotalCount = COUNT(*) FROM ConstanteNomina;
    
    SELECT Codigo, Nombre, Valor, Origen
    FROM ConstanteNomina
    ORDER BY Codigo
    OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;
END
GO

-- =============================================
-- 10. SP: Guardar constante
-- =============================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_Nomina_Constante_Save')
    DROP PROCEDURE sp_Nomina_Constante_Save
GO

CREATE PROCEDURE sp_Nomina_Constante_Save
    @Codigo NVARCHAR(50),
    @Nombre NVARCHAR(100) = NULL,
    @Valor FLOAT = NULL,
    @Origen NVARCHAR(50) = NULL,
    @Resultado INT OUTPUT,
    @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Resultado = 0;
    SET @Mensaje = '';
    
    BEGIN TRY
        IF EXISTS (SELECT 1 FROM ConstanteNomina WHERE Codigo = @Codigo)
        BEGIN
            UPDATE ConstanteNomina SET Nombre = @Nombre, Valor = @Valor, Origen = @Origen WHERE Codigo = @Codigo;
            SET @Resultado = 1;
            SET @Mensaje = 'Constante actualizada';
        END
        ELSE
        BEGIN
            INSERT INTO ConstanteNomina (Codigo, Nombre, Valor, Origen) VALUES (@Codigo, @Nombre, @Valor, @Origen);
            SET @Resultado = 1;
            SET @Mensaje = 'Constante creada';
        END
    END TRY
    BEGIN CATCH
        SET @Resultado = -99;
        SET @Mensaje = ERROR_MESSAGE();
    END CATCH
END
GO

PRINT 'SPs de consultas de nómina creados exitosamente';
GO
