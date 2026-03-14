-- =============================================
-- VACACIONES Y LIQUIDACIÓN (CANÓNICO)
-- =============================================
SET NOCOUNT ON;
GO

IF OBJECT_ID('dbo.sp_Nomina_CalcularSalariosPromedio','P') IS NOT NULL DROP PROCEDURE dbo.sp_Nomina_CalcularSalariosPromedio;
GO
CREATE PROCEDURE dbo.sp_Nomina_CalcularSalariosPromedio
  @SessionID NVARCHAR(80),
  @Cedula NVARCHAR(32),
  @FechaDesde DATE,
  @FechaHasta DATE
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @SalarioDiario DECIMAL(18,6) = dbo.fn_Nomina_GetVariable(@SessionID, N'SALARIO_DIARIO');
  DECLARE @BaseUtil DECIMAL(18,6) = dbo.fn_Nomina_GetVariable(@SessionID, N'DIAS_UTILIDADES_MIN');
  DECLARE @SalarioNormal DECIMAL(18,6);
  DECLARE @SalarioIntegral DECIMAL(18,6);
  DECLARE @Dias INT = DATEDIFF(DAY, @FechaDesde, @FechaHasta) + 1;

  IF @SalarioDiario <= 0 SET @SalarioDiario = 0;
  IF @BaseUtil <= 0 SET @BaseUtil = 30;

  SET @SalarioNormal = @SalarioDiario;
  SET @SalarioIntegral = @SalarioDiario + (@SalarioDiario * (@BaseUtil / 360.0));

  EXEC dbo.sp_Nomina_SetVariable @SessionID, N'SALARIO_NORMAL', @SalarioNormal, N'Salario promedio diario';
  EXEC dbo.sp_Nomina_SetVariable @SessionID, N'SALARIO_INTEGRAL', @SalarioIntegral, N'Salario integral diario';
  EXEC dbo.sp_Nomina_SetVariable @SessionID, N'BASE_UTIL', @BaseUtil, N'Base de utilidad';
  EXEC dbo.sp_Nomina_SetVariable @SessionID, N'DIAS_CALCULO', @Dias, N'Días del cálculo';
END
GO

IF OBJECT_ID('dbo.sp_Nomina_CalcularDiasVacaciones','P') IS NOT NULL DROP PROCEDURE dbo.sp_Nomina_CalcularDiasVacaciones;
GO
CREATE PROCEDURE dbo.sp_Nomina_CalcularDiasVacaciones
  @SessionID NVARCHAR(80),
  @Cedula NVARCHAR(32),
  @FechaRetiro DATE = NULL,
  @DiasVacaciones DECIMAL(18,6) OUTPUT,
  @DiasBonoVacacional DECIMAL(18,6) OUTPUT
AS
BEGIN
  SET NOCOUNT ON;

  IF @FechaRetiro IS NULL SET @FechaRetiro = CAST(GETDATE() AS DATE);

  DECLARE @CompanyId INT;
  DECLARE @BranchId INT;
  DECLARE @HireDate DATE;
  DECLARE @Years INT = 0;
  DECLARE @BaseVac DECIMAL(18,6) = dbo.fn_Nomina_GetVariable(@SessionID, N'DIAS_VACACIONES_BASE');
  DECLARE @BaseBono DECIMAL(18,6) = dbo.fn_Nomina_GetVariable(@SessionID, N'DIAS_BONO_VAC_BASE');

  EXEC dbo.sp_Nomina_GetScope @CompanyId OUTPUT, @BranchId OUTPUT;

  SELECT TOP 1 @HireDate = e.HireDate
  FROM [master].Employee e
  WHERE e.CompanyId = @CompanyId
    AND e.EmployeeCode = @Cedula
    AND e.IsDeleted = 0;

  IF @BaseVac <= 0 SET @BaseVac = 15;
  IF @BaseBono <= 0 SET @BaseBono = 15;

  IF @HireDate IS NOT NULL
    SET @Years = DATEDIFF(YEAR, @HireDate, @FechaRetiro);

  IF @Years < 0 SET @Years = 0;

  SET @DiasVacaciones = @BaseVac + CASE WHEN @Years > 0 THEN (@Years - 1) ELSE 0 END;
  SET @DiasBonoVacacional = @BaseBono + CASE WHEN @Years > 0 THEN (@Years - 1) ELSE 0 END;

  EXEC dbo.sp_Nomina_SetVariable @SessionID, N'DIAS_VACACIONES', @DiasVacaciones, N'Días vacaciones calculados';
  EXEC dbo.sp_Nomina_SetVariable @SessionID, N'DIAS_BONO_VAC', @DiasBonoVacacional, N'Días bono vacacional calculados';
END
GO

IF OBJECT_ID('dbo.sp_Nomina_ProcesarVacaciones','P') IS NOT NULL DROP PROCEDURE dbo.sp_Nomina_ProcesarVacaciones;
GO
CREATE PROCEDURE dbo.sp_Nomina_ProcesarVacaciones
  @VacacionID NVARCHAR(50),
  @Cedula NVARCHAR(32),
  @FechaInicio DATE,
  @FechaHasta DATE,
  @FechaReintegro DATE = NULL,
  @CoUsuario NVARCHAR(50) = N'API',
  @Resultado INT OUTPUT,
  @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
  SET NOCOUNT ON;
  SET XACT_ABORT ON;

  DECLARE @CompanyId INT;
  DECLARE @BranchId INT;
  DECLARE @UserId INT = NULL;
  DECLARE @EmployeeId BIGINT;
  DECLARE @EmployeeName NVARCHAR(120);
  DECLARE @SessionID NVARCHAR(80) = (N'VAC_' + @VacacionID);
  DECLARE @DiasVac DECIMAL(18,6);
  DECLARE @DiasBono DECIMAL(18,6);
  DECLARE @SalarioIntegral DECIMAL(18,6);
  DECLARE @MontoVac DECIMAL(18,6);
  DECLARE @MontoBono DECIMAL(18,6);
  DECLARE @Total DECIMAL(18,6);
  DECLARE @VacationProcessId BIGINT;
  DECLARE @FechaDesdeSalarios DATE;

  SET @Resultado = 0;
  SET @Mensaje = N'';

  BEGIN TRY
    EXEC dbo.sp_Nomina_GetScope @CompanyId OUTPUT, @BranchId OUTPUT;

    SELECT TOP 1 @UserId = u.UserId
    FROM sec.[User] u
    WHERE u.UserCode = @CoUsuario AND u.IsDeleted = 0;

    SELECT TOP 1
      @EmployeeId = e.EmployeeId,
      @EmployeeName = e.EmployeeName
    FROM [master].Employee e
    WHERE e.CompanyId = @CompanyId
      AND e.EmployeeCode = @Cedula
      AND e.IsDeleted = 0
      AND e.IsActive = 1;

    IF @EmployeeId IS NULL
    BEGIN
      SET @Mensaje = N'Empleado no encontrado o inactivo';
      RETURN;
    END

    SET @FechaDesdeSalarios = DATEADD(MONTH, -3, @FechaInicio);

    EXEC dbo.sp_Nomina_PrepararVariablesBase @SessionID, @Cedula, N'VACACIONES', @FechaInicio, @FechaHasta;
    EXEC dbo.sp_Nomina_CalcularSalariosPromedio @SessionID, @Cedula, @FechaDesdeSalarios, @FechaInicio;
    EXEC dbo.sp_Nomina_CalcularDiasVacaciones @SessionID, @Cedula, NULL, @DiasVac OUTPUT, @DiasBono OUTPUT;

    SET @SalarioIntegral = dbo.fn_Nomina_GetVariable(@SessionID, N'SALARIO_INTEGRAL');
    IF @SalarioIntegral <= 0 SET @SalarioIntegral = dbo.fn_Nomina_GetVariable(@SessionID, N'SALARIO_DIARIO');

    SET @MontoVac = @SalarioIntegral * ISNULL(@DiasVac,0);
    SET @MontoBono = @SalarioIntegral * ISNULL(@DiasBono,0);
    SET @Total = @MontoVac + @MontoBono;

    BEGIN TRAN;

    SELECT TOP 1 @VacationProcessId = vp.VacationProcessId
    FROM hr.VacationProcess vp
    WHERE vp.CompanyId = @CompanyId
      AND vp.BranchId = @BranchId
      AND vp.VacationCode = @VacacionID
    ORDER BY vp.VacationProcessId DESC;

    IF @VacationProcessId IS NULL
    BEGIN
      INSERT INTO hr.VacationProcess (
        CompanyId, BranchId, VacationCode, EmployeeId, EmployeeCode, EmployeeName,
        StartDate, EndDate, ReintegrationDate, ProcessDate,
        TotalAmount, CalculatedAmount,
        CreatedAt, UpdatedAt, CreatedByUserId, UpdatedByUserId
      )
      VALUES (
        @CompanyId, @BranchId, @VacacionID, @EmployeeId, @Cedula, @EmployeeName,
        @FechaInicio, @FechaHasta, @FechaReintegro, CAST(GETDATE() AS DATE),
        @Total, @Total,
        SYSUTCDATETIME(), SYSUTCDATETIME(), @UserId, @UserId
      );

      SET @VacationProcessId = SCOPE_IDENTITY();
    END
    ELSE
    BEGIN
      UPDATE hr.VacationProcess
      SET EmployeeId = @EmployeeId,
          EmployeeCode = @Cedula,
          EmployeeName = @EmployeeName,
          StartDate = @FechaInicio,
          EndDate = @FechaHasta,
          ReintegrationDate = @FechaReintegro,
          ProcessDate = CAST(GETDATE() AS DATE),
          TotalAmount = @Total,
          CalculatedAmount = @Total,
          UpdatedAt = SYSUTCDATETIME(),
          UpdatedByUserId = @UserId
      WHERE VacationProcessId = @VacationProcessId;

      DELETE FROM hr.VacationProcessLine WHERE VacationProcessId = @VacationProcessId;
    END

    INSERT INTO hr.VacationProcessLine (VacationProcessId, ConceptCode, ConceptName, Amount, CreatedAt)
    VALUES
      (@VacationProcessId, N'VAC_PAGO', N'Pago vacaciones', @MontoVac, SYSUTCDATETIME()),
      (@VacationProcessId, N'VAC_BONO', N'Bono vacacional', @MontoBono, SYSUTCDATETIME());

    COMMIT;

    EXEC dbo.sp_Nomina_LimpiarVariables @SessionID;

    SET @Resultado = 1;
    SET @Mensaje = N'Vacaciones procesadas. Total=' + CONVERT(NVARCHAR(40), @Total);
  END TRY
  BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK;
    EXEC dbo.sp_Nomina_LimpiarVariables @SessionID;
    SET @Resultado = 0;
    SET @Mensaje = ERROR_MESSAGE();
  END CATCH
END
GO

IF OBJECT_ID('dbo.sp_Nomina_CalcularLiquidacion','P') IS NOT NULL DROP PROCEDURE dbo.sp_Nomina_CalcularLiquidacion;
GO
CREATE PROCEDURE dbo.sp_Nomina_CalcularLiquidacion
  @LiquidacionID NVARCHAR(50),
  @Cedula NVARCHAR(32),
  @FechaRetiro DATE,
  @CausaRetiro NVARCHAR(50) = N'RENUNCIA',
  @CoUsuario NVARCHAR(50) = N'API',
  @Resultado INT OUTPUT,
  @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
  SET NOCOUNT ON;
  SET XACT_ABORT ON;

  DECLARE @CompanyId INT;
  DECLARE @BranchId INT;
  DECLARE @UserId INT = NULL;
  DECLARE @EmployeeId BIGINT;
  DECLARE @EmployeeName NVARCHAR(120);
  DECLARE @HireDate DATE;
  DECLARE @SessionID NVARCHAR(80) = (N'LIQ_' + @LiquidacionID);
  DECLARE @ServiceYears INT = 0;
  DECLARE @SalarioDiario DECIMAL(18,6);
  DECLARE @Prestaciones DECIMAL(18,6);
  DECLARE @VacPendientes DECIMAL(18,6);
  DECLARE @BonoSalida DECIMAL(18,6);
  DECLARE @Total DECIMAL(18,6);
  DECLARE @SettlementProcessId BIGINT;
  DECLARE @FechaDesdeBase DATE;

  SET @Resultado = 0;
  SET @Mensaje = N'';

  BEGIN TRY
    EXEC dbo.sp_Nomina_GetScope @CompanyId OUTPUT, @BranchId OUTPUT;

    SELECT TOP 1 @UserId = u.UserId
    FROM sec.[User] u
    WHERE u.UserCode = @CoUsuario AND u.IsDeleted = 0;

    SELECT TOP 1
      @EmployeeId = e.EmployeeId,
      @EmployeeName = e.EmployeeName,
      @HireDate = e.HireDate
    FROM [master].Employee e
    WHERE e.CompanyId = @CompanyId
      AND e.EmployeeCode = @Cedula
      AND e.IsDeleted = 0;

    IF @EmployeeId IS NULL
    BEGIN
      SET @Mensaje = N'Empleado no encontrado';
      RETURN;
    END

    SET @FechaDesdeBase = DATEADD(MONTH, -1, @FechaRetiro);
    EXEC dbo.sp_Nomina_PrepararVariablesBase @SessionID, @Cedula, N'LIQUIDACION', @FechaDesdeBase, @FechaRetiro;
    SET @SalarioDiario = dbo.fn_Nomina_GetVariable(@SessionID, N'SALARIO_DIARIO');

    IF @HireDate IS NOT NULL
      SET @ServiceYears = DATEDIFF(YEAR, @HireDate, @FechaRetiro);

    IF @ServiceYears < 0 SET @ServiceYears = 0;
    IF @SalarioDiario < 0 SET @SalarioDiario = 0;

    SET @Prestaciones = (@ServiceYears * @SalarioDiario * 30);
    SET @VacPendientes = (@SalarioDiario * 15);
    SET @BonoSalida = CASE WHEN UPPER(@CausaRetiro) = N'DESPIDO' THEN (@SalarioDiario * 15) ELSE (@SalarioDiario * 10) END;
    SET @Total = @Prestaciones + @VacPendientes + @BonoSalida;

    BEGIN TRAN;

    SELECT TOP 1 @SettlementProcessId = sp.SettlementProcessId
    FROM hr.SettlementProcess sp
    WHERE sp.CompanyId = @CompanyId
      AND sp.BranchId = @BranchId
      AND sp.SettlementCode = @LiquidacionID
    ORDER BY sp.SettlementProcessId DESC;

    IF @SettlementProcessId IS NULL
    BEGIN
      INSERT INTO hr.SettlementProcess (
        CompanyId, BranchId, SettlementCode, EmployeeId, EmployeeCode, EmployeeName,
        RetirementDate, RetirementCause, TotalAmount,
        CreatedAt, UpdatedAt, CreatedByUserId, UpdatedByUserId
      )
      VALUES (
        @CompanyId, @BranchId, @LiquidacionID, @EmployeeId, @Cedula, @EmployeeName,
        @FechaRetiro, @CausaRetiro, @Total,
        SYSUTCDATETIME(), SYSUTCDATETIME(), @UserId, @UserId
      );

      SET @SettlementProcessId = SCOPE_IDENTITY();
    END
    ELSE
    BEGIN
      UPDATE hr.SettlementProcess
      SET EmployeeId = @EmployeeId,
          EmployeeCode = @Cedula,
          EmployeeName = @EmployeeName,
          RetirementDate = @FechaRetiro,
          RetirementCause = @CausaRetiro,
          TotalAmount = @Total,
          UpdatedAt = SYSUTCDATETIME(),
          UpdatedByUserId = @UserId
      WHERE SettlementProcessId = @SettlementProcessId;

      DELETE FROM hr.SettlementProcessLine WHERE SettlementProcessId = @SettlementProcessId;
    END

    INSERT INTO hr.SettlementProcessLine (SettlementProcessId, ConceptCode, ConceptName, Amount, CreatedAt)
    VALUES
      (@SettlementProcessId, N'LIQ_PREST', N'Prestaciones', @Prestaciones, SYSUTCDATETIME()),
      (@SettlementProcessId, N'LIQ_VAC', N'Vacaciones pendientes', @VacPendientes, SYSUTCDATETIME()),
      (@SettlementProcessId, N'LIQ_BONO', N'Bono de salida', @BonoSalida, SYSUTCDATETIME());

    COMMIT;

    EXEC dbo.sp_Nomina_LimpiarVariables @SessionID;

    SET @Resultado = 1;
    SET @Mensaje = N'Liquidación calculada. Total=' + CONVERT(NVARCHAR(40), @Total);
  END TRY
  BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK;
    EXEC dbo.sp_Nomina_LimpiarVariables @SessionID;
    SET @Resultado = 0;
    SET @Mensaje = ERROR_MESSAGE();
  END CATCH
END
GO

IF OBJECT_ID('dbo.sp_Nomina_GetLiquidacion','P') IS NOT NULL DROP PROCEDURE dbo.sp_Nomina_GetLiquidacion;
GO
CREATE PROCEDURE dbo.sp_Nomina_GetLiquidacion
  @LiquidacionID NVARCHAR(50)
AS
BEGIN
  SET NOCOUNT ON;

  SELECT TOP 1
    sp.SettlementProcessId,
    sp.SettlementCode,
    sp.EmployeeCode AS Cedula,
    sp.EmployeeName AS NombreEmpleado,
    sp.RetirementDate,
    sp.RetirementCause,
    sp.TotalAmount,
    sp.CreatedAt,
    sp.UpdatedAt
  FROM hr.SettlementProcess sp
  WHERE sp.SettlementCode = @LiquidacionID
  ORDER BY sp.SettlementProcessId DESC;

  SELECT
    sl.SettlementProcessLineId,
    sl.ConceptCode,
    sl.ConceptName,
    sl.Amount,
    sl.CreatedAt
  FROM hr.SettlementProcessLine sl
  INNER JOIN hr.SettlementProcess sp ON sp.SettlementProcessId = sl.SettlementProcessId
  WHERE sp.SettlementCode = @LiquidacionID
  ORDER BY sl.SettlementProcessLineId;

  SELECT
    SUM(CASE WHEN sl.Amount > 0 THEN sl.Amount ELSE 0 END) AS TotalAsignaciones,
    SUM(CASE WHEN sl.Amount < 0 THEN sl.Amount ELSE 0 END) AS TotalDeducciones,
    SUM(sl.Amount) AS TotalNeto
  FROM hr.SettlementProcessLine sl
  INNER JOIN hr.SettlementProcess sp ON sp.SettlementProcessId = sl.SettlementProcessId
  WHERE sp.SettlementCode = @LiquidacionID;
END
GO
