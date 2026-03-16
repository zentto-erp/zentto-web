-- =============================================
-- SISTEMA BASE DE NÓMINA (CANÓNICO)
-- Modelo objetivo: hr.* + master.Employee
-- =============================================
SET NOCOUNT ON;
GO

IF SCHEMA_ID('hr') IS NULL EXEC('CREATE SCHEMA hr AUTHORIZATION dbo');
GO

IF OBJECT_ID('hr.PayrollCalcVariable','U') IS NULL
BEGIN
  CREATE TABLE hr.PayrollCalcVariable (
    SessionID NVARCHAR(80) NOT NULL,
    Variable NVARCHAR(120) NOT NULL,
    Valor DECIMAL(18,6) NOT NULL CONSTRAINT DF_PayrollCalcVariable_Valor DEFAULT (0),
    Descripcion NVARCHAR(255) NULL,
    CreatedAt DATETIME2(3) NOT NULL CONSTRAINT DF_PayrollCalcVariable_CreatedAt DEFAULT SYSUTCDATETIME(),
    UpdatedAt DATETIME2(3) NOT NULL CONSTRAINT DF_PayrollCalcVariable_UpdatedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_PayrollCalcVariable PRIMARY KEY (SessionID, Variable)
  );
END
GO

IF OBJECT_ID('dbo.fn_EvaluarExpr','FN') IS NOT NULL DROP FUNCTION dbo.fn_EvaluarExpr;
GO
CREATE FUNCTION dbo.fn_EvaluarExpr (@Expr NVARCHAR(MAX))
RETURNS DECIMAL(18,6)
AS
BEGIN
  RETURN TRY_CONVERT(DECIMAL(18,6), @Expr);
END
GO

IF OBJECT_ID('dbo.fn_Nomina_GetVariable','FN') IS NOT NULL DROP FUNCTION dbo.fn_Nomina_GetVariable;
GO
CREATE FUNCTION dbo.fn_Nomina_GetVariable (
  @SessionID NVARCHAR(80),
  @Variable NVARCHAR(120)
)
RETURNS DECIMAL(18,6)
AS
BEGIN
  DECLARE @Valor DECIMAL(18,6) = 0;
  SELECT TOP 1 @Valor = Valor
  FROM hr.PayrollCalcVariable
  WHERE SessionID = @SessionID AND Variable = @Variable;

  RETURN ISNULL(@Valor, 0);
END
GO

IF OBJECT_ID('dbo.fn_Nomina_ContarFeriados','FN') IS NOT NULL DROP FUNCTION dbo.fn_Nomina_ContarFeriados;
GO
CREATE FUNCTION dbo.fn_Nomina_ContarFeriados(
  @FechaDesde DATE,
  @FechaHasta DATE
)
RETURNS INT
AS
BEGIN
  -- En DatqBoxWeb canónico no se depende de dbo.Feriados legacy.
  -- Se deja en 0 y puede ser reemplazado por catálogo canónico si se incorpora.
  RETURN 0;
END
GO

IF OBJECT_ID('dbo.fn_Nomina_ContarDomingos','FN') IS NOT NULL DROP FUNCTION dbo.fn_Nomina_ContarDomingos;
GO
CREATE FUNCTION dbo.fn_Nomina_ContarDomingos(
  @FechaDesde DATE,
  @FechaHasta DATE
)
RETURNS INT
AS
BEGIN
  DECLARE @Actual DATE = @FechaDesde;
  DECLARE @Domingos INT = 0;

  WHILE (@Actual <= @FechaHasta)
  BEGIN
    IF DATEPART(WEEKDAY, @Actual) = 1 SET @Domingos = @Domingos + 1;
    SET @Actual = DATEADD(DAY, 1, @Actual);
  END

  RETURN @Domingos;
END
GO

-- =============================================
-- fn_Nomina_ContarLunes
-- Cuenta lunes en el rango [@FechaDesde, @FechaHasta].
-- Referencia fija: 2000-01-03 fue lunes (no depende de DATEFIRST).
-- =============================================
IF OBJECT_ID('dbo.fn_Nomina_ContarLunes','FN') IS NOT NULL DROP FUNCTION dbo.fn_Nomina_ContarLunes;
GO
CREATE FUNCTION dbo.fn_Nomina_ContarLunes(
  @FechaDesde DATE,
  @FechaHasta DATE
)
RETURNS INT
AS
BEGIN
  DECLARE @Actual DATE = @FechaDesde;
  DECLARE @Lunes INT = 0;

  WHILE (@Actual <= @FechaHasta)
  BEGIN
    -- (DATEDIFF(DAY, '2000-01-03', @Actual) % 7) = 0 identifica lunes
    -- independientemente del valor de DATEFIRST.
    IF (DATEDIFF(DAY, '2000-01-03', @Actual) % 7) = 0
      SET @Lunes = @Lunes + 1;
    SET @Actual = DATEADD(DAY, 1, @Actual);
  END

  RETURN @Lunes;
END
GO

IF OBJECT_ID('dbo.sp_Nomina_GetScope','P') IS NOT NULL DROP PROCEDURE dbo.sp_Nomina_GetScope;
GO
CREATE PROCEDURE dbo.sp_Nomina_GetScope
  @CompanyId INT OUTPUT,
  @BranchId INT OUTPUT
AS
BEGIN
  SET NOCOUNT ON;

  SELECT TOP 1 @CompanyId = c.CompanyId
  FROM cfg.Company c
  WHERE c.IsDeleted = 0
  ORDER BY CASE WHEN c.CompanyCode = 'DEFAULT' THEN 0 ELSE 1 END, c.CompanyId;

  IF @CompanyId IS NULL
    THROW 50001, 'No existe cfg.Company activa para nómina', 1;

  SELECT TOP 1 @BranchId = b.BranchId
  FROM cfg.Branch b
  WHERE b.CompanyId = @CompanyId
    AND b.IsDeleted = 0
  ORDER BY CASE WHEN b.BranchCode = 'MAIN' THEN 0 ELSE 1 END, b.BranchId;

  IF @BranchId IS NULL
    THROW 50002, 'No existe cfg.Branch activa para nómina', 1;
END
GO

IF OBJECT_ID('dbo.sp_Nomina_LimpiarVariables','P') IS NOT NULL DROP PROCEDURE dbo.sp_Nomina_LimpiarVariables;
GO
CREATE PROCEDURE dbo.sp_Nomina_LimpiarVariables
  @SessionID NVARCHAR(80)
AS
BEGIN
  SET NOCOUNT ON;
  DELETE FROM hr.PayrollCalcVariable WHERE SessionID = @SessionID;
END
GO

IF OBJECT_ID('dbo.sp_Nomina_SetVariable','P') IS NOT NULL DROP PROCEDURE dbo.sp_Nomina_SetVariable;
GO
CREATE PROCEDURE dbo.sp_Nomina_SetVariable
  @SessionID NVARCHAR(80),
  @Variable NVARCHAR(120),
  @Valor DECIMAL(18,6),
  @Descripcion NVARCHAR(255) = NULL
AS
BEGIN
  SET NOCOUNT ON;

  MERGE hr.PayrollCalcVariable AS target
  USING (SELECT @SessionID AS SessionID, @Variable AS Variable) AS src
  ON target.SessionID = src.SessionID AND target.Variable = src.Variable
  WHEN MATCHED THEN
    UPDATE SET
      Valor = @Valor,
      Descripcion = @Descripcion,
      UpdatedAt = SYSUTCDATETIME()
  WHEN NOT MATCHED THEN
    INSERT (SessionID, Variable, Valor, Descripcion)
    VALUES (@SessionID, @Variable, @Valor, @Descripcion);
END
GO

IF OBJECT_ID('dbo.sp_Nomina_CargarConstantes','P') IS NOT NULL DROP PROCEDURE dbo.sp_Nomina_CargarConstantes;
GO
CREATE PROCEDURE dbo.sp_Nomina_CargarConstantes
  @SessionID NVARCHAR(80)
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @CompanyId INT;
  DECLARE @BranchId INT;
  EXEC dbo.sp_Nomina_GetScope @CompanyId OUTPUT, @BranchId OUTPUT;

  INSERT INTO hr.PayrollCalcVariable (SessionID, Variable, Valor, Descripcion)
  SELECT
    @SessionID,
    pc.ConstantCode,
    pc.ConstantValue,
    pc.ConstantName
  FROM hr.PayrollConstant pc
  WHERE pc.CompanyId = @CompanyId
    AND pc.IsActive = 1
    AND NOT EXISTS (
      SELECT 1
      FROM hr.PayrollCalcVariable v
      WHERE v.SessionID = @SessionID
        AND v.Variable = pc.ConstantCode
    );
END
GO

IF OBJECT_ID('dbo.sp_Nomina_CalcularAntiguedad','P') IS NOT NULL DROP PROCEDURE dbo.sp_Nomina_CalcularAntiguedad;
GO
CREATE PROCEDURE dbo.sp_Nomina_CalcularAntiguedad
  @SessionID NVARCHAR(80),
  @Cedula NVARCHAR(32),
  @FechaCalculo DATE = NULL
AS
BEGIN
  SET NOCOUNT ON;

  IF @FechaCalculo IS NULL SET @FechaCalculo = CAST(SYSUTCDATETIME() AS DATE);

  DECLARE @CompanyId INT;
  DECLARE @BranchId INT;
  DECLARE @FechaIngreso DATE;
  DECLARE @Dias INT = 0;
  DECLARE @Anios INT = 0;
  DECLARE @Meses INT = 0;
  DECLARE @TotalMeses INT = 0;

  EXEC dbo.sp_Nomina_GetScope @CompanyId OUTPUT, @BranchId OUTPUT;

  SELECT TOP 1 @FechaIngreso = e.HireDate
  FROM [master].Employee e
  WHERE e.CompanyId = @CompanyId
    AND e.EmployeeCode = @Cedula
    AND e.IsDeleted = 0;

  IF @FechaIngreso IS NOT NULL
  BEGIN
    SET @Dias = DATEDIFF(DAY, @FechaIngreso, @FechaCalculo);
    SET @Anios = @Dias / 365;
    SET @Meses = (@Dias % 365) / 30;
    SET @TotalMeses = DATEDIFF(MONTH, @FechaIngreso, @FechaCalculo);
  END

  EXEC dbo.sp_Nomina_SetVariable @SessionID, 'ANTI_ANIOS', @Anios, 'Años de antigüedad';
  EXEC dbo.sp_Nomina_SetVariable @SessionID, 'ANTI_MESES', @Meses, 'Meses de antigüedad';
  EXEC dbo.sp_Nomina_SetVariable @SessionID, 'ANTI_DIAS', @Dias, 'Días de antigüedad';
  EXEC dbo.sp_Nomina_SetVariable @SessionID, 'ANTI_TOTAL_MESES', @TotalMeses, 'Total meses de antigüedad';
END
GO

IF OBJECT_ID('dbo.sp_Nomina_PrepararVariablesBase','P') IS NOT NULL DROP PROCEDURE dbo.sp_Nomina_PrepararVariablesBase;
GO
CREATE PROCEDURE dbo.sp_Nomina_PrepararVariablesBase
  @SessionID NVARCHAR(80),
  @Cedula NVARCHAR(32),
  @Nomina NVARCHAR(20),
  @FechaInicio DATE,
  @FechaHasta DATE
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @CompanyId INT;
  DECLARE @BranchId INT;
  DECLARE @DiasPeriodo INT;
  DECLARE @Feriados INT;
  DECLARE @Domingos INT;
  DECLARE @SalarioDiario DECIMAL(18,6);
  DECLARE @Sueldo DECIMAL(18,6);
  DECLARE @SalarioHora DECIMAL(18,6);
  DECLARE @FechaInicioNum INT;
  DECLARE @FechaHastaNum INT;

  EXEC dbo.sp_Nomina_GetScope @CompanyId OUTPUT, @BranchId OUTPUT;

  EXEC dbo.sp_Nomina_LimpiarVariables @SessionID;
  EXEC dbo.sp_Nomina_CargarConstantes @SessionID;

  SET @DiasPeriodo = DATEDIFF(DAY, @FechaInicio, @FechaHasta) + 1;
  SET @Feriados = dbo.fn_Nomina_ContarFeriados(@FechaInicio, @FechaHasta);
  SET @Domingos = dbo.fn_Nomina_ContarDomingos(@FechaInicio, @FechaHasta);

  SELECT @SalarioDiario = pc.ConstantValue
  FROM hr.PayrollConstant pc
  WHERE pc.CompanyId = @CompanyId
    AND pc.ConstantCode = 'SALARIO_DIARIO'
    AND pc.IsActive = 1;

  IF @SalarioDiario IS NULL SET @SalarioDiario = 0;
  SET @Sueldo = @SalarioDiario * 30;
  SET @SalarioHora = @SalarioDiario / 8.0;
  SET @FechaInicioNum = CONVERT(INT, CONVERT(CHAR(8), @FechaInicio, 112));
  SET @FechaHastaNum = CONVERT(INT, CONVERT(CHAR(8), @FechaHasta, 112));

  EXEC dbo.sp_Nomina_SetVariable @SessionID, 'FECHA_INICIO_NUM', @FechaInicioNum, 'Fecha inicio (yyyymmdd)';
  EXEC dbo.sp_Nomina_SetVariable @SessionID, 'FECHA_HASTA_NUM', @FechaHastaNum, 'Fecha hasta (yyyymmdd)';
  EXEC dbo.sp_Nomina_SetVariable @SessionID, 'DIAS_PERIODO', @DiasPeriodo, 'Días del período';
  EXEC dbo.sp_Nomina_SetVariable @SessionID, 'FERIADOS', @Feriados, 'Feriados del período';
  EXEC dbo.sp_Nomina_SetVariable @SessionID, 'DOMINGOS', @Domingos, 'Domingos del período';
  EXEC dbo.sp_Nomina_SetVariable @SessionID, 'SUELDO', @Sueldo, 'Sueldo mensual referencial';
  EXEC dbo.sp_Nomina_SetVariable @SessionID, 'SALARIO_DIARIO', @SalarioDiario, 'Salario diario referencial';
  EXEC dbo.sp_Nomina_SetVariable @SessionID, 'SALARIO_HORA', @SalarioHora, 'Salario hora referencial';
  EXEC dbo.sp_Nomina_SetVariable @SessionID, 'HORAS_MES', 240, 'Horas laborales referenciales';

  EXEC dbo.sp_Nomina_CalcularAntiguedad @SessionID, @Cedula, @FechaHasta;

  -- -------------------------------------------------------
  -- Variables adicionales: semanas, SSO, RPE
  -- -------------------------------------------------------
  DECLARE @SueldoMin DECIMAL(18,6) = 0;
  DECLARE @TopeSSO DECIMAL(18,6) = 5;
  DECLARE @TopeRPE DECIMAL(18,6) = 10;
  DECLARE @LunesMes INT;
  DECLARE @SueldoSemanal DECIMAL(18,6);
  DECLARE @SemanasPeriodo DECIMAL(18,6);
  DECLARE @SueldoMinSem DECIMAL(18,6);
  DECLARE @TopeSsoSem DECIMAL(18,6);
  DECLARE @TopeRpeSem DECIMAL(18,6);
  DECLARE @PrimerDiaMes DATE;

  -- Leer SUELDO_MIN de hr.PayrollConstant
  SELECT @SueldoMin = pc.ConstantValue
  FROM hr.PayrollConstant pc
  WHERE pc.CompanyId = @CompanyId
    AND pc.ConstantCode = 'SUELDO_MIN'
    AND pc.IsActive = 1;

  IF @SueldoMin IS NULL SET @SueldoMin = 0;

  -- Leer TOPE_SSO (por defecto 5 salarios mínimos)
  SELECT @TopeSSO = pc.ConstantValue
  FROM hr.PayrollConstant pc
  WHERE pc.CompanyId = @CompanyId
    AND pc.ConstantCode = 'TOPE_SSO'
    AND pc.IsActive = 1;

  IF @TopeSSO IS NULL SET @TopeSSO = 5;

  -- Leer TOPE_RPE (por defecto 10 salarios mínimos)
  SELECT @TopeRPE = pc.ConstantValue
  FROM hr.PayrollConstant pc
  WHERE pc.CompanyId = @CompanyId
    AND pc.ConstantCode = 'TOPE_RPE'
    AND pc.IsActive = 1;

  IF @TopeRPE IS NULL SET @TopeRPE = 10;

  -- Primer día del mes de @FechaInicio
  SET @PrimerDiaMes = DATEFROMPARTS(YEAR(@FechaInicio), MONTH(@FechaInicio), 1);

  -- Lunes del mes completo
  SET @LunesMes = dbo.fn_Nomina_ContarLunes(@PrimerDiaMes, EOMONTH(@FechaInicio));

  -- Sueldo semanal = sueldo mensual × 12 / 52
  SET @SueldoSemanal = @Sueldo * 12.0 / 52.0;

  -- Semanas del período según duración
  IF @DiasPeriodo <= 7
    SET @SemanasPeriodo = 1.0;
  ELSE IF @DiasPeriodo <= 16
    SET @SemanasPeriodo = CAST(@LunesMes AS DECIMAL(18,6)) / 2.0;
  ELSE
    SET @SemanasPeriodo = CAST(@LunesMes AS DECIMAL(18,6));

  -- Sueldo mínimo semanal
  SET @SueldoMinSem = @SueldoMin * 12.0 / 52.0;

  -- Topes semanales SSO y RPE
  IF @SueldoMin > 0
  BEGIN
    -- TOPE_SSO_SEM = MIN(sueldo_semanal, TopeSSO × sueldo_min_semanal)
    IF @SueldoSemanal < (@TopeSSO * @SueldoMinSem)
      SET @TopeSsoSem = @SueldoSemanal;
    ELSE
      SET @TopeSsoSem = @TopeSSO * @SueldoMinSem;

    -- TOPE_RPE_SEM = MIN(sueldo_semanal, TopeRPE × sueldo_min_semanal)
    IF @SueldoSemanal < (@TopeRPE * @SueldoMinSem)
      SET @TopeRpeSem = @SueldoSemanal;
    ELSE
      SET @TopeRpeSem = @TopeRPE * @SueldoMinSem;
  END
  ELSE
  BEGIN
    -- Sin salario mínimo configurado: sin tope aplicado
    SET @TopeSsoSem = @SueldoSemanal;
    SET @TopeRpeSem = @SueldoSemanal;
  END

  EXEC dbo.sp_Nomina_SetVariable @SessionID, 'LUNES_MES', @LunesMes, 'Lunes del mes (para cálculo SSO)';
  EXEC dbo.sp_Nomina_SetVariable @SessionID, 'SUELDO_SEMANAL', @SueldoSemanal, 'Sueldo semanal (sueldo × 12/52)';
  EXEC dbo.sp_Nomina_SetVariable @SessionID, 'SEMANAS_PERIODO', @SemanasPeriodo, 'Semanas en el período de nómina';
  EXEC dbo.sp_Nomina_SetVariable @SessionID, 'TOPE_SSO_SEM', @TopeSsoSem, 'Base semanal SSO con tope (min(sal_sem, 5×salMin_sem))';
  EXEC dbo.sp_Nomina_SetVariable @SessionID, 'TOPE_RPE_SEM', @TopeRpeSem, 'Base semanal RPE con tope (min(sal_sem, 10×salMin_sem))';
END
GO
