-- =============================================
-- CÁLCULO POR RÉGIMEN (CANÓNICO)
-- =============================================
SET NOCOUNT ON;
GO

IF OBJECT_ID('dbo.sp_Nomina_CargarConstantesRegimen','P') IS NOT NULL DROP PROCEDURE dbo.sp_Nomina_CargarConstantesRegimen;
GO
CREATE PROCEDURE dbo.sp_Nomina_CargarConstantesRegimen
  @SessionID NVARCHAR(80),
  @Regimen NVARCHAR(10) = N'LOT',
  @TipoNomina NVARCHAR(15) = N'MENSUAL'
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @CompanyId INT;
  DECLARE @BranchId INT;
  DECLARE @Prefix NVARCHAR(20) = UPPER(ISNULL(@Regimen, N'LOT')) + N'_';

  EXEC dbo.sp_Nomina_GetScope @CompanyId OUTPUT, @BranchId OUTPUT;

  EXEC dbo.sp_Nomina_CargarConstantes @SessionID;

  INSERT INTO hr.PayrollCalcVariable (SessionID, Variable, Valor, Descripcion)
  SELECT
    @SessionID,
    REPLACE(pc.ConstantCode, @Prefix, N''),
    pc.ConstantValue,
    (pc.ConstantName + N' [' + @Regimen + N']')
  FROM hr.PayrollConstant pc
  WHERE pc.CompanyId = @CompanyId
    AND pc.IsActive = 1
    AND pc.ConstantCode LIKE @Prefix + N'%'
    AND NOT EXISTS (
      SELECT 1
      FROM hr.PayrollCalcVariable v
      WHERE v.SessionID = @SessionID
        AND v.Variable = REPLACE(pc.ConstantCode, @Prefix, N'')
    );

  EXEC dbo.sp_Nomina_SetVariable @SessionID, N'REGIMEN_ID', 0, @Regimen;

  IF UPPER(@TipoNomina) = N'SEMANAL'
    EXEC dbo.sp_Nomina_SetVariable @SessionID, N'DIAS_PERIODO', 7, N'Días período semanal';
  ELSE IF UPPER(@TipoNomina) = N'QUINCENAL'
    EXEC dbo.sp_Nomina_SetVariable @SessionID, N'DIAS_PERIODO', 15, N'Días período quincenal';
END
GO

IF OBJECT_ID('dbo.sp_Nomina_CalcularVacacionesRegimen','P') IS NOT NULL DROP PROCEDURE dbo.sp_Nomina_CalcularVacacionesRegimen;
GO
CREATE PROCEDURE dbo.sp_Nomina_CalcularVacacionesRegimen
  @SessionID NVARCHAR(80),
  @Regimen NVARCHAR(10),
  @AniosServicio INT,
  @MesesPeriodo INT = 12,
  @DiasVacaciones DECIMAL(18,6) OUTPUT,
  @DiasBonoVacacional DECIMAL(18,6) OUTPUT,
  @DiasBonoPostVacacional DECIMAL(18,6) OUTPUT
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @VacBase DECIMAL(18,6) = dbo.fn_Nomina_GetVariable(@SessionID, N'DIAS_VACACIONES_BASE');
  DECLARE @BonoBase DECIMAL(18,6) = dbo.fn_Nomina_GetVariable(@SessionID, N'DIAS_BONO_VAC_BASE');

  IF @VacBase <= 0 SET @VacBase = 15;
  IF @BonoBase <= 0 SET @BonoBase = 15;

  SET @DiasVacaciones = @VacBase + CASE WHEN @AniosServicio > 0 THEN (@AniosServicio - 1) ELSE 0 END;
  SET @DiasBonoVacacional = @BonoBase + CASE WHEN @AniosServicio > 0 THEN (@AniosServicio - 1) ELSE 0 END;
  SET @DiasBonoPostVacacional = 0;

  EXEC dbo.sp_Nomina_SetVariable @SessionID, N'DIAS_VACACIONES', @DiasVacaciones, N'Días vacaciones (régimen)';
  EXEC dbo.sp_Nomina_SetVariable @SessionID, N'DIAS_BONO_VAC', @DiasBonoVacacional, N'Días bono vacacional (régimen)';
  EXEC dbo.sp_Nomina_SetVariable @SessionID, N'DIAS_BONO_POST_VAC', @DiasBonoPostVacacional, N'Bono post vacacional';
END
GO

IF OBJECT_ID('dbo.sp_Nomina_CalcularUtilidadesRegimen','P') IS NOT NULL DROP PROCEDURE dbo.sp_Nomina_CalcularUtilidadesRegimen;
GO
CREATE PROCEDURE dbo.sp_Nomina_CalcularUtilidadesRegimen
  @SessionID NVARCHAR(80),
  @Regimen NVARCHAR(10),
  @DiasTrabajadosAno INT,
  @SalarioNormal DECIMAL(18,6),
  @Utilidades DECIMAL(18,6) OUTPUT
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @DiasMin DECIMAL(18,6) = dbo.fn_Nomina_GetVariable(@SessionID, N'DIAS_UTILIDADES_MIN');
  DECLARE @DiasMax DECIMAL(18,6) = dbo.fn_Nomina_GetVariable(@SessionID, N'DIAS_UTILIDADES_MAX');
  DECLARE @DiasUtil DECIMAL(18,6);

  IF @DiasMin <= 0 SET @DiasMin = 30;
  IF @DiasMax <= 0 SET @DiasMax = 120;

  SET @DiasUtil = CASE
    WHEN @DiasTrabajadosAno >= 365 THEN @DiasMax
    WHEN @DiasTrabajadosAno <= 0 THEN 0
    ELSE (@DiasMax * @DiasTrabajadosAno) / 365.0
  END;

  IF @DiasUtil < @DiasMin AND @DiasTrabajadosAno > 0 SET @DiasUtil = @DiasMin;

  SET @Utilidades = (@SalarioNormal * @DiasUtil);
  EXEC dbo.sp_Nomina_SetVariable @SessionID, N'DIAS_UTILIDADES', @DiasUtil, N'Días utilidades';
  EXEC dbo.sp_Nomina_SetVariable @SessionID, N'MONTO_UTILIDADES', @Utilidades, N'Monto utilidades';
END
GO

IF OBJECT_ID('dbo.sp_Nomina_CalcularPrestacionesRegimen','P') IS NOT NULL DROP PROCEDURE dbo.sp_Nomina_CalcularPrestacionesRegimen;
GO
CREATE PROCEDURE dbo.sp_Nomina_CalcularPrestacionesRegimen
  @SessionID NVARCHAR(80),
  @Regimen NVARCHAR(10),
  @AniosServicio INT,
  @MesesAdicionales INT,
  @SalarioIntegral DECIMAL(18,6),
  @Prestaciones DECIMAL(18,6) OUTPUT,
  @Intereses DECIMAL(18,6) OUTPUT
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @DiasAnio DECIMAL(18,6) = dbo.fn_Nomina_GetVariable(@SessionID, N'PREST_DIAS_ANIO');
  DECLARE @InteresAnual DECIMAL(18,6) = dbo.fn_Nomina_GetVariable(@SessionID, N'PREST_INTERES_ANUAL');
  DECLARE @DiasTotales DECIMAL(18,6);

  IF @DiasAnio <= 0 SET @DiasAnio = 30;
  IF @InteresAnual <= 0 SET @InteresAnual = 0.15;

  SET @DiasTotales = (@AniosServicio * @DiasAnio) + (@MesesAdicionales * (@DiasAnio / 12.0));
  SET @Prestaciones = (@SalarioIntegral * @DiasTotales);
  SET @Intereses = @Prestaciones * @InteresAnual;

  EXEC dbo.sp_Nomina_SetVariable @SessionID, N'DIAS_PRESTACIONES', @DiasTotales, N'Días prestaciones';
  EXEC dbo.sp_Nomina_SetVariable @SessionID, N'MONTO_PRESTACIONES', @Prestaciones, N'Monto prestaciones';
  EXEC dbo.sp_Nomina_SetVariable @SessionID, N'INTERESES_PRESTACIONES', @Intereses, N'Intereses prestaciones';
END
GO

IF OBJECT_ID('dbo.sp_Nomina_PrepararVariablesRegimen','P') IS NOT NULL DROP PROCEDURE dbo.sp_Nomina_PrepararVariablesRegimen;
GO
CREATE PROCEDURE dbo.sp_Nomina_PrepararVariablesRegimen
  @SessionID NVARCHAR(80),
  @Cedula NVARCHAR(32),
  @Nomina NVARCHAR(20),
  @TipoNomina NVARCHAR(15),
  @Regimen NVARCHAR(10) = NULL,
  @FechaInicio DATE,
  @FechaHasta DATE
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @Reg NVARCHAR(10) = UPPER(ISNULL(@Regimen, @Nomina));
  IF @Reg = N'' SET @Reg = N'LOT';

  EXEC dbo.sp_Nomina_PrepararVariablesBase @SessionID, @Cedula, @Nomina, @FechaInicio, @FechaHasta;
  EXEC dbo.sp_Nomina_CargarConstantesRegimen @SessionID, @Reg, @TipoNomina;
END
GO

IF OBJECT_ID('dbo.sp_Nomina_ProcesarEmpleadoRegimen','P') IS NOT NULL DROP PROCEDURE dbo.sp_Nomina_ProcesarEmpleadoRegimen;
GO
CREATE PROCEDURE dbo.sp_Nomina_ProcesarEmpleadoRegimen
  @Nomina NVARCHAR(20),
  @Cedula NVARCHAR(32),
  @FechaInicio DATE,
  @FechaHasta DATE,
  @Regimen NVARCHAR(10) = NULL,
  @CoUsuario NVARCHAR(50) = N'API',
  @Resultado INT OUTPUT,
  @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
  SET NOCOUNT ON;
  SET XACT_ABORT ON;

  DECLARE @Reg NVARCHAR(10) = UPPER(ISNULL(@Regimen, @Nomina));
  DECLARE @TipoCalculo NVARCHAR(20) = N'MENSUAL';
  DECLARE @SessionID NVARCHAR(80) = (@Nomina + N'_' + @Cedula + N'_' + CONVERT(NVARCHAR(8), SYSUTCDATETIME(), 112));
  DECLARE @NominaProceso NVARCHAR(20);

  IF UPPER(@Nomina) LIKE N'%VAC%' SET @TipoCalculo = N'VACACIONES';
  IF UPPER(@Nomina) LIKE N'%LIQ%' SET @TipoCalculo = N'LIQUIDACION';

  -- Reusar procesamiento base canónico
  SET @NominaProceso = CASE WHEN @Reg IS NULL OR @Reg = N'' THEN @Nomina ELSE @Reg END;

  EXEC dbo.sp_Nomina_ProcesarEmpleado
    @Nomina = @NominaProceso,
    @Cedula = @Cedula,
    @FechaInicio = @FechaInicio,
    @FechaHasta = @FechaHasta,
    @CoUsuario = @CoUsuario,
    @Resultado = @Resultado OUTPUT,
    @Mensaje = @Mensaje OUTPUT;

  IF @Resultado = 1
  BEGIN
    EXEC dbo.sp_Nomina_SetVariable @SessionID, N'TIPO_CALCULO_ID', 0, @TipoCalculo;
  END
END
GO
