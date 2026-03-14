-- =============================================
-- STORED PROCEDURE: dbo.sp_CxC_Documentos_List
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

CREATE PROCEDURE dbo.sp_CxC_Documentos_List
  @CodCliente NVARCHAR(20) = NULL,
  @TipoDoc NVARCHAR(10) = NULL,
  @Estado NVARCHAR(15) = NULL,
  @FechaDesde DATE = NULL,
  @FechaHasta DATE = NULL,
  @Page INT = 1,
  @Limit INT = 50
AS
BEGIN
  SET NOCOUNT ON;
  IF @Page IS NULL OR @Page < 1 SET @Page = 1;
  IF @Limit IS NULL OR @Limit < 1 SET @Limit = 50;
  IF @Limit > 500 SET @Limit = 500;

  DECLARE @Offset INT = (@Page - 1) * @Limit;

  ;WITH Base AS (
    SELECT
      c.CustomerCode AS codCliente,
      d.DocumentType AS tipoDoc,
      d.DocumentNumber AS numDoc,
      d.IssueDate AS fecha,
      d.TotalAmount AS total,
      d.PendingAmount AS pendiente,
      d.Status AS estado,
      d.Notes AS observacion,
      u.UserCode AS codUsuario,
      ROW_NUMBER() OVER (ORDER BY d.IssueDate DESC, d.DocumentNumber DESC, d.ReceivableDocumentId DESC) AS rn
    FROM ar.ReceivableDocument d
    INNER JOIN [master].Customer c ON c.CustomerId = d.CustomerId
    LEFT JOIN sec.[User] u ON u.UserId = d.CreatedByUserId
    WHERE (@CodCliente IS NULL OR c.CustomerCode = @CodCliente)
      AND (@TipoDoc IS NULL OR d.DocumentType = @TipoDoc)
      AND (@FechaDesde IS NULL OR d.IssueDate >= @FechaDesde)
      AND (@FechaHasta IS NULL OR d.IssueDate <= @FechaHasta)
  )
  SELECT codCliente, tipoDoc, numDoc, fecha, total, pendiente, estado, observacion, codUsuario
  FROM Base
  WHERE (@Estado IS NULL OR @Estado = '' OR estado = @Estado)
    AND rn BETWEEN (@Offset + 1) AND (@Offset + @Limit)
  ORDER BY rn;
END;

GO
 
 
-- =============================================
-- STORED PROCEDURE: dbo.sp_CxP_Documentos_List
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

CREATE PROCEDURE dbo.sp_CxP_Documentos_List
  @CodProveedor NVARCHAR(20) = NULL,
  @TipoDoc NVARCHAR(10) = NULL,
  @Estado NVARCHAR(15) = NULL,
  @FechaDesde DATE = NULL,
  @FechaHasta DATE = NULL,
  @Page INT = 1,
  @Limit INT = 50
AS
BEGIN
  SET NOCOUNT ON;
  IF @Page IS NULL OR @Page < 1 SET @Page = 1;
  IF @Limit IS NULL OR @Limit < 1 SET @Limit = 50;
  IF @Limit > 500 SET @Limit = 500;

  DECLARE @Offset INT = (@Page - 1) * @Limit;

  ;WITH Base AS (
    SELECT
      s.SupplierCode AS codProveedor,
      d.DocumentType AS tipoDoc,
      d.DocumentNumber AS numDoc,
      d.IssueDate AS fecha,
      d.TotalAmount AS total,
      d.PendingAmount AS pendiente,
      d.Status AS estado,
      d.Notes AS observacion,
      u.UserCode AS codUsuario,
      ROW_NUMBER() OVER (ORDER BY d.IssueDate DESC, d.DocumentNumber DESC, d.PayableDocumentId DESC) AS rn
    FROM ap.PayableDocument d
    INNER JOIN [master].Supplier s ON s.SupplierId = d.SupplierId
    LEFT JOIN sec.[User] u ON u.UserId = d.CreatedByUserId
    WHERE (@CodProveedor IS NULL OR s.SupplierCode = @CodProveedor)
      AND (@TipoDoc IS NULL OR d.DocumentType = @TipoDoc)
      AND (@FechaDesde IS NULL OR d.IssueDate >= @FechaDesde)
      AND (@FechaHasta IS NULL OR d.IssueDate <= @FechaHasta)
  )
  SELECT codProveedor, tipoDoc, numDoc, fecha, total, pendiente, estado, observacion, codUsuario
  FROM Base
  WHERE (@Estado IS NULL OR @Estado = '' OR estado = @Estado)
    AND rn BETWEEN (@Offset + 1) AND (@Offset + @Limit)
  ORDER BY rn;
END;

GO
 
 
-- =============================================
-- STORED PROCEDURE: dbo.sp_Nomina_CalcularAntiguedad
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE dbo.sp_Nomina_CalcularAntiguedad
  @SessionID NVARCHAR(80),
  @Cedula NVARCHAR(32),
  @FechaCalculo DATE = NULL
AS
BEGIN
  SET NOCOUNT ON;

  IF @FechaCalculo IS NULL SET @FechaCalculo = CAST(GETDATE() AS DATE);

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

  EXEC dbo.sp_Nomina_SetVariable @SessionID, 'ANTI_ANIOS', @Anios, 'A§os de antigÅedad';
  EXEC dbo.sp_Nomina_SetVariable @SessionID, 'ANTI_MESES', @Meses, 'Meses de antigÅedad';
  EXEC dbo.sp_Nomina_SetVariable @SessionID, 'ANTI_DIAS', @Dias, 'D°as de antigÅedad';
  EXEC dbo.sp_Nomina_SetVariable @SessionID, 'ANTI_TOTAL_MESES', @TotalMeses, 'Total meses de antigÅedad';
END

GO
 
 
-- =============================================
-- STORED PROCEDURE: dbo.sp_Nomina_CalcularConcepto
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE dbo.sp_Nomina_CalcularConcepto
  @SessionID NVARCHAR(80),
  @Cedula NVARCHAR(32),
  @CoConcepto NVARCHAR(20),
  @CoNomina NVARCHAR(20),
  @Cantidad DECIMAL(18,6) = NULL,
  @Monto DECIMAL(18,6) OUTPUT,
  @Total DECIMAL(18,6) OUTPUT,
  @Descripcion NVARCHAR(200) OUTPUT
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @CompanyId INT;
  DECLARE @BranchId INT;
  DECLARE @Formula NVARCHAR(MAX);
  DECLARE @DefaultValue DECIMAL(18,6);

  EXEC dbo.sp_Nomina_GetScope @CompanyId OUTPUT, @BranchId OUTPUT;

  SELECT TOP 1
    @Formula = pc.Formula,
    @DefaultValue = pc.DefaultValue,
    @Descripcion = pc.ConceptName
  FROM hr.PayrollConcept pc
  WHERE pc.CompanyId = @CompanyId
    AND pc.PayrollCode = @CoNomina
    AND pc.ConceptCode = @CoConcepto
    AND pc.IsActive = 1;

  IF @Cantidad IS NULL OR @Cantidad <= 0 SET @Cantidad = 1;

  IF @Formula IS NOT NULL AND LTRIM(RTRIM(@Formula)) <> N''
    EXEC dbo.sp_Nomina_EvaluarFormula @SessionID, @Formula, @Monto OUTPUT, @FormulaResuelta = @Formula OUTPUT;
  ELSE
    SET @Monto = ISNULL(@DefaultValue, 0);

  SET @Monto = ISNULL(@Monto, 0);
  SET @Total = @Monto * @Cantidad;
END

GO
 
 
-- =============================================
-- STORED PROCEDURE: dbo.sp_Nomina_CalcularDiasVacaciones
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
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

  EXEC dbo.sp_Nomina_SetVariable @SessionID, N'DIAS_VACACIONES', @DiasVacaciones, N'D°as vacaciones calculados';
  EXEC dbo.sp_Nomina_SetVariable @SessionID, N'DIAS_BONO_VAC', @DiasBonoVacacional, N'D°as bono vacacional calculados';
END

GO
 
 
-- =============================================
-- STORED PROCEDURE: dbo.sp_Nomina_CalcularLiquidacion
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
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
    SET @Mensaje = N'Liquidaci¢n calculada. Total=' + CONVERT(NVARCHAR(40), @Total);
  END TRY
  BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK;
    EXEC dbo.sp_Nomina_LimpiarVariables @SessionID;
    SET @Resultado = 0;
    SET @Mensaje = ERROR_MESSAGE();
  END CATCH
END

GO
 
 
-- =============================================
-- STORED PROCEDURE: dbo.sp_Nomina_CalcularPrestacionesRegimen
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
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

  EXEC dbo.sp_Nomina_SetVariable @SessionID, N'DIAS_PRESTACIONES', @DiasTotales, N'D°as prestaciones';
  EXEC dbo.sp_Nomina_SetVariable @SessionID, N'MONTO_PRESTACIONES', @Prestaciones, N'Monto prestaciones';
  EXEC dbo.sp_Nomina_SetVariable @SessionID, N'INTERESES_PRESTACIONES', @Intereses, N'Intereses prestaciones';
END

GO
 
 
-- =============================================
-- STORED PROCEDURE: dbo.sp_Nomina_CalcularSalariosPromedio
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
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
  EXEC dbo.sp_Nomina_SetVariable @SessionID, N'DIAS_CALCULO', @Dias, N'D°as del c†lculo';
END

GO
 
 
-- =============================================
-- STORED PROCEDURE: dbo.sp_Nomina_CalcularUtilidadesRegimen
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
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
  EXEC dbo.sp_Nomina_SetVariable @SessionID, N'DIAS_UTILIDADES', @DiasUtil, N'D°as utilidades';
  EXEC dbo.sp_Nomina_SetVariable @SessionID, N'MONTO_UTILIDADES', @Utilidades, N'Monto utilidades';
END

GO
 
 
-- =============================================
-- STORED PROCEDURE: dbo.sp_Nomina_CalcularVacacionesRegimen
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
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

  EXEC dbo.sp_Nomina_SetVariable @SessionID, N'DIAS_VACACIONES', @DiasVacaciones, N'D°as vacaciones (rÇgimen)';
  EXEC dbo.sp_Nomina_SetVariable @SessionID, N'DIAS_BONO_VAC', @DiasBonoVacacional, N'D°as bono vacacional (rÇgimen)';
  EXEC dbo.sp_Nomina_SetVariable @SessionID, N'DIAS_BONO_POST_VAC', @DiasBonoPostVacacional, N'Bono post vacacional';
END

GO
 
 
-- =============================================
-- STORED PROCEDURE: dbo.sp_Nomina_CargarConstantes
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
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
 
 
-- =============================================
-- STORED PROCEDURE: dbo.sp_Nomina_CargarConstantesDesdeConceptoLegal
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE dbo.sp_Nomina_CargarConstantesDesdeConceptoLegal
  @SessionID NVARCHAR(80),
  @Convencion NVARCHAR(50) = N'LOT',
  @TipoCalculo NVARCHAR(50) = N'MENSUAL'
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @Regimen NVARCHAR(10) = UPPER(LEFT(ISNULL(@Convencion, N'LOT'), 10));
  DECLARE @TipoNomina NVARCHAR(15) = UPPER(CASE WHEN @TipoCalculo IN (N'SEMANAL', N'QUINCENAL') THEN @TipoCalculo ELSE N'MENSUAL' END);

  EXEC dbo.sp_Nomina_CargarConstantesRegimen @SessionID, @Regimen, @TipoNomina;
END

GO
 
 
-- =============================================
-- STORED PROCEDURE: dbo.sp_Nomina_CargarConstantesRegimen
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
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
    EXEC dbo.sp_Nomina_SetVariable @SessionID, N'DIAS_PERIODO', 7, N'D°as per°odo semanal';
  ELSE IF UPPER(@TipoNomina) = N'QUINCENAL'
    EXEC dbo.sp_Nomina_SetVariable @SessionID, N'DIAS_PERIODO', 15, N'D°as per°odo quincenal';
END

GO
 
 
-- =============================================
-- STORED PROCEDURE: dbo.sp_Nomina_Cerrar
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE dbo.sp_Nomina_Cerrar
  @Nomina NVARCHAR(20),
  @Cedula NVARCHAR(32) = NULL,
  @CoUsuario NVARCHAR(50) = N'API',
  @Resultado INT OUTPUT,
  @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @CompanyId INT;
  DECLARE @BranchId INT;
  DECLARE @UserId INT = NULL;

  SET @Resultado = 0;
  SET @Mensaje = N'';

  EXEC dbo.sp_Nomina_GetScope @CompanyId OUTPUT, @BranchId OUTPUT;

  SELECT TOP 1 @UserId = u.UserId
  FROM sec.[User] u
  WHERE u.UserCode = @CoUsuario
    AND u.IsDeleted = 0;

  UPDATE hr.PayrollRun
  SET IsClosed = 1,
      ClosedAt = SYSUTCDATETIME(),
      ClosedByUserId = @UserId,
      UpdatedAt = SYSUTCDATETIME(),
      UpdatedByUserId = @UserId
  WHERE CompanyId = @CompanyId
    AND BranchId = @BranchId
    AND PayrollCode = @Nomina
    AND (@Cedula IS NULL OR EmployeeCode = @Cedula)
    AND IsClosed = 0;

  SET @Resultado = 1;
  SET @Mensaje = N'Registros cerrados: ' + CONVERT(NVARCHAR(20), @@ROWCOUNT);
END

GO
 
 
-- =============================================
-- STORED PROCEDURE: dbo.sp_Nomina_Concepto_Save
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE dbo.sp_Nomina_Concepto_Save
  @CoConcept NVARCHAR(20),
  @CoNomina NVARCHAR(20),
  @NbConcepto NVARCHAR(120),
  @Formula NVARCHAR(MAX) = NULL,
  @Sobre NVARCHAR(255) = NULL,
  @Clase NVARCHAR(20) = NULL,
  @Tipo NVARCHAR(20) = NULL,
  @Uso NVARCHAR(20) = NULL,
  @Bonificable NVARCHAR(1) = NULL,
  @Antiguedad NVARCHAR(1) = NULL,
  @Contable NVARCHAR(50) = NULL,
  @Aplica NVARCHAR(1) = N'S',
  @Defecto FLOAT = NULL,
  @Resultado INT OUTPUT,
  @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @CompanyId INT;
  DECLARE @BranchId INT;

  SET @Resultado = 0;
  SET @Mensaje = N'';

  EXEC dbo.sp_Nomina_GetScope @CompanyId OUTPUT, @BranchId OUTPUT;

  IF EXISTS (
    SELECT 1
    FROM hr.PayrollConcept
    WHERE CompanyId = @CompanyId
      AND PayrollCode = @CoNomina
      AND ConceptCode = @CoConcept
      AND ISNULL(ConventionCode,N'') = N''
      AND ISNULL(CalculationType,N'') = N''
  )
  BEGIN
    UPDATE hr.PayrollConcept
    SET
      ConceptName = @NbConcepto,
      Formula = @Formula,
      BaseExpression = @Sobre,
      ConceptClass = @Clase,
      ConceptType = ISNULL(@Tipo, N'ASIGNACION'),
      UsageType = @Uso,
      IsBonifiable = CASE WHEN UPPER(ISNULL(@Bonificable,N'S')) IN (N'S',N'1') THEN 1 ELSE 0 END,
      IsSeniority = CASE WHEN UPPER(ISNULL(@Antiguedad,N'N')) IN (N'S',N'1') THEN 1 ELSE 0 END,
      AccountingAccountCode = @Contable,
      AppliesFlag = CASE WHEN UPPER(ISNULL(@Aplica,N'S')) IN (N'S',N'1') THEN 1 ELSE 0 END,
      DefaultValue = ISNULL(CONVERT(DECIMAL(18,6), @Defecto), 0),
      UpdatedAt = SYSUTCDATETIME(),
      IsActive = 1
    WHERE CompanyId = @CompanyId
      AND PayrollCode = @CoNomina
      AND ConceptCode = @CoConcept
      AND ISNULL(ConventionCode,N'') = N''
      AND ISNULL(CalculationType,N'') = N'';

    SET @Resultado = 1;
    SET @Mensaje = N'Concepto actualizado';
  END
  ELSE
  BEGIN
    INSERT INTO hr.PayrollConcept (
      CompanyId, PayrollCode, ConceptCode, ConceptName,
      Formula, BaseExpression, ConceptClass, ConceptType,
      UsageType, IsBonifiable, IsSeniority,
      AccountingAccountCode, AppliesFlag, DefaultValue,
      ConventionCode, CalculationType, LotttArticle, CcpClause,
      SortOrder, IsActive, CreatedAt, UpdatedAt
    )
    VALUES (
      @CompanyId, @CoNomina, @CoConcept, @NbConcepto,
      @Formula, @Sobre, @Clase, ISNULL(@Tipo, N'ASIGNACION'),
      @Uso, CASE WHEN UPPER(ISNULL(@Bonificable,N'S')) IN (N'S',N'1') THEN 1 ELSE 0 END,
      CASE WHEN UPPER(ISNULL(@Antiguedad,N'N')) IN (N'S',N'1') THEN 1 ELSE 0 END,
      @Contable, CASE WHEN UPPER(ISNULL(@Aplica,N'S')) IN (N'S',N'1') THEN 1 ELSE 0 END,
      ISNULL(CONVERT(DECIMAL(18,6), @Defecto), 0),
      NULL, NULL, NULL, NULL,
      0, 1, SYSUTCDATETIME(), SYSUTCDATETIME()
    );

    SET @Resultado = 1;
    SET @Mensaje = N'Concepto creado';
  END
END

GO
 
 
-- =============================================
-- STORED PROCEDURE: dbo.sp_Nomina_Conceptos_List
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE dbo.sp_Nomina_Conceptos_List
  @CoNomina NVARCHAR(20) = NULL,
  @Tipo NVARCHAR(20) = NULL,
  @Search NVARCHAR(120) = NULL,
  @Page INT = 1,
  @Limit INT = 50,
  @TotalCount INT OUTPUT
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @CompanyId INT;
  DECLARE @BranchId INT;
  DECLARE @Offset INT = (@Page - 1) * @Limit;

  EXEC dbo.sp_Nomina_GetScope @CompanyId OUTPUT, @BranchId OUTPUT;

  SELECT @TotalCount = COUNT(1)
  FROM hr.PayrollConcept pc
  WHERE pc.CompanyId = @CompanyId
    AND (@CoNomina IS NULL OR pc.PayrollCode = @CoNomina)
    AND (@Tipo IS NULL OR pc.ConceptType = @Tipo)
    AND (
      @Search IS NULL
      OR pc.ConceptName LIKE N'%' + @Search + N'%'
      OR pc.ConceptCode LIKE N'%' + @Search + N'%'
    );

  SELECT
    pc.ConceptCode AS Codigo,
    pc.PayrollCode AS CodigoNomina,
    pc.ConceptName AS Nombre,
    pc.Formula,
    pc.BaseExpression AS Sobre,
    pc.ConceptClass AS Clase,
    pc.ConceptType AS Tipo,
    pc.UsageType AS Uso,
    CASE WHEN pc.IsBonifiable = 1 THEN N'S' ELSE N'N' END AS Bonificable,
    CASE WHEN pc.IsSeniority = 1 THEN N'S' ELSE N'N' END AS Antiguedad,
    pc.AccountingAccountCode AS Contable,
    CASE WHEN pc.AppliesFlag = 1 THEN N'S' ELSE N'N' END AS Aplica,
    pc.DefaultValue AS Defecto,
    pc.ConventionCode AS Convencion,
    pc.CalculationType AS TipoCalculo,
    pc.SortOrder AS Orden,
    pc.IsActive AS Activo
  FROM hr.PayrollConcept pc
  WHERE pc.CompanyId = @CompanyId
    AND (@CoNomina IS NULL OR pc.PayrollCode = @CoNomina)
    AND (@Tipo IS NULL OR pc.ConceptType = @Tipo)
    AND (
      @Search IS NULL
      OR pc.ConceptName LIKE N'%' + @Search + N'%'
      OR pc.ConceptCode LIKE N'%' + @Search + N'%'
    )
  ORDER BY pc.PayrollCode, pc.SortOrder, pc.ConceptCode
  OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;
END

GO
 
 
-- =============================================
-- STORED PROCEDURE: dbo.sp_Nomina_ConceptosLegales_List
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE dbo.sp_Nomina_ConceptosLegales_List
  @Convencion NVARCHAR(50) = NULL,
  @TipoCalculo NVARCHAR(50) = NULL,
  @Tipo NVARCHAR(15) = NULL,
  @Activo BIT = 1
AS
BEGIN
  SET NOCOUNT ON;

  SELECT
    PayrollConceptId AS Id,
    ConventionCode AS Convencion,
    CalculationType AS TipoCalculo,
    ConceptCode AS CO_CONCEPT,
    ConceptName AS NB_CONCEPTO,
    Formula,
    BaseExpression AS SOBRE,
    ConceptType AS TIPO,
    CASE WHEN IsBonifiable = 1 THEN 'S' ELSE 'N' END AS BONIFICABLE,
    LotttArticle AS LOTTT_Articulo,
    CcpClause AS CCP_Clausula,
    SortOrder AS Orden,
    IsActive AS Activo,
    PayrollCode AS CO_NOMINA
  FROM hr.PayrollConcept
  WHERE ConventionCode IS NOT NULL
    AND (@Convencion IS NULL OR ConventionCode = @Convencion)
    AND (@TipoCalculo IS NULL OR CalculationType = @TipoCalculo)
    AND (@Tipo IS NULL OR ConceptType = @Tipo)
    AND (@Activo IS NULL OR IsActive = @Activo)
  ORDER BY ConventionCode, CalculationType, SortOrder, ConceptCode;
END

GO
 
 
-- =============================================
-- STORED PROCEDURE: dbo.sp_Nomina_Constante_Save
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE dbo.sp_Nomina_Constante_Save
  @Codigo NVARCHAR(50),
  @Nombre NVARCHAR(120) = NULL,
  @Valor FLOAT = NULL,
  @Origen NVARCHAR(80) = NULL,
  @Resultado INT OUTPUT,
  @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @CompanyId INT;
  DECLARE @BranchId INT;

  SET @Resultado = 0;
  SET @Mensaje = N'';

  EXEC dbo.sp_Nomina_GetScope @CompanyId OUTPUT, @BranchId OUTPUT;

  IF EXISTS (
    SELECT 1 FROM hr.PayrollConstant
    WHERE CompanyId = @CompanyId
      AND ConstantCode = @Codigo
  )
  BEGIN
    UPDATE hr.PayrollConstant
    SET ConstantName = ISNULL(@Nombre, ConstantName),
        ConstantValue = ISNULL(CONVERT(DECIMAL(18,6), @Valor), ConstantValue),
        SourceName = ISNULL(@Origen, SourceName),
        IsActive = 1,
        UpdatedAt = SYSUTCDATETIME()
    WHERE CompanyId = @CompanyId
      AND ConstantCode = @Codigo;

    SET @Resultado = 1;
    SET @Mensaje = N'Constante actualizada';
  END
  ELSE
  BEGIN
    INSERT INTO hr.PayrollConstant (
      CompanyId, ConstantCode, ConstantName, ConstantValue, SourceName,
      IsActive, CreatedAt, UpdatedAt
    )
    VALUES (
      @CompanyId,
      @Codigo,
      ISNULL(@Nombre, @Codigo),
      ISNULL(CONVERT(DECIMAL(18,6), @Valor), 0),
      @Origen,
      1,
      SYSUTCDATETIME(),
      SYSUTCDATETIME()
    );

    SET @Resultado = 1;
    SET @Mensaje = N'Constante creada';
  END
END

GO
 
 
-- =============================================
-- STORED PROCEDURE: dbo.sp_Nomina_Constantes_List
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE dbo.sp_Nomina_Constantes_List
  @Page INT = 1,
  @Limit INT = 50,
  @TotalCount INT OUTPUT
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @CompanyId INT;
  DECLARE @BranchId INT;
  DECLARE @Offset INT = (@Page - 1) * @Limit;

  EXEC dbo.sp_Nomina_GetScope @CompanyId OUTPUT, @BranchId OUTPUT;

  SELECT @TotalCount = COUNT(1)
  FROM hr.PayrollConstant pc
  WHERE pc.CompanyId = @CompanyId;

  SELECT
    pc.ConstantCode AS Codigo,
    pc.ConstantName AS Nombre,
    pc.ConstantValue AS Valor,
    pc.SourceName AS Origen,
    pc.IsActive
  FROM hr.PayrollConstant pc
  WHERE pc.CompanyId = @CompanyId
  ORDER BY pc.ConstantCode
  OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;
END

GO
 
 
-- =============================================
-- STORED PROCEDURE: dbo.sp_Nomina_CopiarConceptosDesdeLegal
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

CREATE PROCEDURE dbo.sp_Nomina_CopiarConceptosDesdeLegal
  @CoNomina     NVARCHAR(30),   -- C«¸digo n«¸mina destino (PayrollCode)
  @Convencion   NVARCHAR(30),   -- Convenci«¸n origen (ConventionCode)
  @TipoCalculo  NVARCHAR(30),   -- Tipo c«≠lculo origen (CalculationType)
  @Sobrescribir BIT = 0,        -- 1 = actualiza conceptos existentes
  @Resultado    INT OUTPUT,
  @Mensaje      NVARCHAR(500) OUTPUT
AS
BEGIN
  SET NOCOUNT ON;
  SET XACT_ABORT ON;

  SET @Resultado = 0;
  SET @Mensaje = N'';

  DECLARE @CompanyId INT = NULL;
  DECLARE @BranchId INT = NULL;
  EXEC dbo.sp_Nomina_GetScope @CompanyId OUTPUT, @BranchId OUTPUT;

  IF @CompanyId IS NULL
  BEGIN
    SET @Resultado = -2;
    SET @Mensaje = N'No se pudo resolver CompanyId en cfg.Company';
    RETURN;
  END;

  IF NOT EXISTS (
    SELECT 1
    FROM hr.PayrollConcept pc
    WHERE pc.CompanyId = @CompanyId
      AND pc.ConventionCode = @Convencion
      AND pc.CalculationType = @TipoCalculo
      AND pc.IsActive = 1
  )
  BEGIN
    SET @Resultado = -1;
    SET @Mensaje = N'No hay conceptos legales en hr.PayrollConcept para Convencion=' + @Convencion + N' y TipoCalculo=' + @TipoCalculo;
    RETURN;
  END;

  BEGIN TRY
    DECLARE @Changes TABLE (ActionName NVARCHAR(10));

    ;WITH SourceRows AS (
      SELECT
        pc.CompanyId,
        @CoNomina AS PayrollCode,
        pc.ConceptCode,
        pc.ConceptName,
        pc.Formula,
        pc.BaseExpression,
        pc.ConceptClass,
        pc.ConceptType,
        pc.UsageType,
        pc.IsBonifiable,
        pc.IsSeniority,
        pc.AccountingAccountCode,
        pc.AppliesFlag,
        pc.DefaultValue,
        pc.ConventionCode,
        pc.CalculationType,
        pc.LotttArticle,
        pc.CcpClause,
        pc.SortOrder,
        pc.IsActive
      FROM hr.PayrollConcept pc
      WHERE pc.CompanyId = @CompanyId
        AND pc.ConventionCode = @Convencion
        AND pc.CalculationType = @TipoCalculo
        AND pc.IsActive = 1
    )
    MERGE hr.PayrollConcept AS target
    USING SourceRows AS src
    ON target.CompanyId = src.CompanyId
       AND target.PayrollCode = src.PayrollCode
       AND target.ConceptCode = src.ConceptCode
       AND ISNULL(target.ConventionCode, N'') = ISNULL(src.ConventionCode, N'')
       AND ISNULL(target.CalculationType, N'') = ISNULL(src.CalculationType, N'')
    WHEN MATCHED AND @Sobrescribir = 1 THEN
      UPDATE SET
        ConceptName = src.ConceptName,
        Formula = src.Formula,
        BaseExpression = src.BaseExpression,
        ConceptClass = src.ConceptClass,
        ConceptType = src.ConceptType,
        UsageType = src.UsageType,
        IsBonifiable = src.IsBonifiable,
        IsSeniority = src.IsSeniority,
        AccountingAccountCode = src.AccountingAccountCode,
        AppliesFlag = src.AppliesFlag,
        DefaultValue = src.DefaultValue,
        LotttArticle = src.LotttArticle,
        CcpClause = src.CcpClause,
        SortOrder = src.SortOrder,
        IsActive = src.IsActive,
        UpdatedAt = SYSUTCDATETIME()
    WHEN NOT MATCHED THEN
      INSERT (
        CompanyId, PayrollCode, ConceptCode, ConceptName, Formula, BaseExpression,
        ConceptClass, ConceptType, UsageType, IsBonifiable, IsSeniority,
        AccountingAccountCode, AppliesFlag, DefaultValue, ConventionCode,
        CalculationType, LotttArticle, CcpClause, SortOrder, IsActive,
        CreatedAt, UpdatedAt
      )
      VALUES (
        src.CompanyId, src.PayrollCode, src.ConceptCode, src.ConceptName, src.Formula, src.BaseExpression,
        src.ConceptClass, src.ConceptType, src.UsageType, src.IsBonifiable, src.IsSeniority,
        src.AccountingAccountCode, src.AppliesFlag, src.DefaultValue, src.ConventionCode,
        src.CalculationType, src.LotttArticle, src.CcpClause, src.SortOrder, src.IsActive,
        SYSUTCDATETIME(), SYSUTCDATETIME()
      )
    OUTPUT $action INTO @Changes(ActionName);

    SELECT @Resultado = COUNT(1) FROM @Changes;

    SET @Mensaje = CAST(@Resultado AS NVARCHAR(20)) + N' concepto(s) sincronizados en hr.PayrollConcept para PayrollCode=' + @CoNomina;
  END TRY
  BEGIN CATCH
    SET @Resultado = -99;
    SET @Mensaje = ERROR_MESSAGE();
  END CATCH
END

GO
 
 
-- =============================================
-- STORED PROCEDURE: dbo.sp_Nomina_EvaluarFormula
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE dbo.sp_Nomina_EvaluarFormula
  @SessionID NVARCHAR(80),
  @Formula NVARCHAR(MAX),
  @Resultado DECIMAL(18,6) OUTPUT,
  @FormulaResuelta NVARCHAR(MAX) OUTPUT
AS
BEGIN
  SET NOCOUNT ON;
  SET @Resultado = 0;
  SET @FormulaResuelta = N'';

  IF @Formula IS NULL OR LTRIM(RTRIM(@Formula)) = N'' RETURN;

  EXEC dbo.sp_Nomina_ReemplazarVariables @SessionID, @Formula, @FormulaResuelta OUTPUT;

  -- Solo caracteres matem†ticos permitidos.
  IF PATINDEX('%[^0-9\.+\-\*/\(\) ]%', @FormulaResuelta) > 0
  BEGIN
    SET @Resultado = 0;
    RETURN;
  END

  DECLARE @SQL NVARCHAR(MAX) = N'SELECT @Out = TRY_CONVERT(DECIMAL(18,6), (' + @FormulaResuelta + N'));';

  BEGIN TRY
    EXEC sp_executesql @SQL, N'@Out DECIMAL(18,6) OUTPUT', @Out = @Resultado OUTPUT;
    SET @Resultado = ISNULL(@Resultado, 0);
  END TRY
  BEGIN CATCH
    SET @Resultado = 0;
  END CATCH
END

GO
 
 
-- =============================================
-- STORED PROCEDURE: dbo.sp_Nomina_Get
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE dbo.sp_Nomina_Get
  @Nomina NVARCHAR(20),
  @Cedula NVARCHAR(32)
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @CompanyId INT;
  DECLARE @BranchId INT;

  EXEC dbo.sp_Nomina_GetScope @CompanyId OUTPUT, @BranchId OUTPUT;

  SELECT TOP 1
    pr.PayrollRunId,
    pr.PayrollCode AS NOMINA,
    pr.EmployeeCode AS CEDULA,
    pr.EmployeeName AS NombreEmpleado,
    pr.ProcessDate AS FECHA,
    pr.DateFrom AS INICIO,
    pr.DateTo AS HASTA,
    pr.TotalAssignments AS ASIGNACION,
    pr.TotalDeductions AS DEDUCCION,
    pr.NetTotal AS TOTAL,
    pr.IsClosed AS CERRADA,
    pr.PayrollTypeName AS TipoNomina
  FROM hr.PayrollRun pr
  WHERE pr.CompanyId = @CompanyId
    AND pr.BranchId = @BranchId
    AND pr.PayrollCode = @Nomina
    AND pr.EmployeeCode = @Cedula
  ORDER BY pr.ProcessDate DESC, pr.PayrollRunId DESC;

  DECLARE @RunId BIGINT;
  SELECT TOP 1 @RunId = pr.PayrollRunId
  FROM hr.PayrollRun pr
  WHERE pr.CompanyId = @CompanyId
    AND pr.BranchId = @BranchId
    AND pr.PayrollCode = @Nomina
    AND pr.EmployeeCode = @Cedula
  ORDER BY pr.ProcessDate DESC, pr.PayrollRunId DESC;

  SELECT
    rl.PayrollRunLineId,
    rl.ConceptCode AS CO_CONCEPTO,
    rl.ConceptName AS NombreConcepto,
    rl.ConceptType AS TIPO,
    rl.Quantity AS CANTIDAD,
    rl.Amount AS MONTO,
    rl.Total
  FROM hr.PayrollRunLine rl
  WHERE rl.PayrollRunId = @RunId
  ORDER BY rl.PayrollRunLineId;
END

GO
 
 
-- =============================================
-- STORED PROCEDURE: dbo.sp_Nomina_GetLiquidacion
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
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
 
 
-- =============================================
-- STORED PROCEDURE: dbo.sp_Nomina_GetScope
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
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
    THROW 50001, 'No existe cfg.Company activa para n¢mina', 1;

  SELECT TOP 1 @BranchId = b.BranchId
  FROM cfg.Branch b
  WHERE b.CompanyId = @CompanyId
    AND b.IsDeleted = 0
  ORDER BY CASE WHEN b.BranchCode = 'MAIN' THEN 0 ELSE 1 END, b.BranchId;

  IF @BranchId IS NULL
    THROW 50002, 'No existe cfg.Branch activa para n¢mina', 1;
END

GO
 
 
-- =============================================
-- STORED PROCEDURE: dbo.sp_Nomina_LimpiarVariables
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE dbo.sp_Nomina_LimpiarVariables
  @SessionID NVARCHAR(80)
AS
BEGIN
  SET NOCOUNT ON;
  DELETE FROM hr.PayrollCalcVariable WHERE SessionID = @SessionID;
END

GO
 
 
-- =============================================
-- STORED PROCEDURE: dbo.sp_Nomina_Liquidaciones_List
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE dbo.sp_Nomina_Liquidaciones_List
  @Cedula NVARCHAR(32) = NULL,
  @Page INT = 1,
  @Limit INT = 50,
  @TotalCount INT OUTPUT
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @CompanyId INT;
  DECLARE @BranchId INT;
  DECLARE @Offset INT = (@Page - 1) * @Limit;

  EXEC dbo.sp_Nomina_GetScope @CompanyId OUTPUT, @BranchId OUTPUT;

  SELECT @TotalCount = COUNT(1)
  FROM hr.SettlementProcess sp
  WHERE sp.CompanyId = @CompanyId
    AND sp.BranchId = @BranchId
    AND (@Cedula IS NULL OR sp.EmployeeCode = @Cedula);

  SELECT
    sp.SettlementProcessId,
    sp.SettlementCode AS Liquidacion,
    sp.EmployeeCode AS Cedula,
    sp.EmployeeName AS NombreEmpleado,
    sp.RetirementDate AS FechaRetiro,
    sp.RetirementCause AS CausaRetiro,
    sp.TotalAmount AS TotalLiquidacion,
    sp.CreatedAt AS FechaCalculo
  FROM hr.SettlementProcess sp
  WHERE sp.CompanyId = @CompanyId
    AND sp.BranchId = @BranchId
    AND (@Cedula IS NULL OR sp.EmployeeCode = @Cedula)
  ORDER BY sp.CreatedAt DESC, sp.SettlementProcessId DESC
  OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;
END

GO
 
 
-- =============================================
-- STORED PROCEDURE: dbo.sp_Nomina_List
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE dbo.sp_Nomina_List
  @Nomina NVARCHAR(20) = NULL,
  @Cedula NVARCHAR(32) = NULL,
  @FechaDesde DATE = NULL,
  @FechaHasta DATE = NULL,
  @SoloAbiertas BIT = 0,
  @Page INT = 1,
  @Limit INT = 50,
  @TotalCount INT OUTPUT
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @CompanyId INT;
  DECLARE @BranchId INT;
  DECLARE @Offset INT = (@Page - 1) * @Limit;

  EXEC dbo.sp_Nomina_GetScope @CompanyId OUTPUT, @BranchId OUTPUT;

  SELECT @TotalCount = COUNT(1)
  FROM hr.PayrollRun pr
  WHERE pr.CompanyId = @CompanyId
    AND pr.BranchId = @BranchId
    AND (@Nomina IS NULL OR pr.PayrollCode = @Nomina)
    AND (@Cedula IS NULL OR pr.EmployeeCode = @Cedula)
    AND (@FechaDesde IS NULL OR pr.DateFrom >= @FechaDesde)
    AND (@FechaHasta IS NULL OR pr.DateTo <= @FechaHasta)
    AND (@SoloAbiertas = 0 OR pr.IsClosed = 0);

  SELECT
    pr.PayrollRunId,
    pr.PayrollCode AS NOMINA,
    pr.EmployeeCode AS CEDULA,
    pr.EmployeeName AS NOMBRE,
    pr.ProcessDate AS FECHA,
    pr.DateFrom AS INICIO,
    pr.DateTo AS HASTA,
    pr.TotalAssignments AS ASIGNACION,
    pr.TotalDeductions AS DEDUCCION,
    pr.NetTotal AS TOTAL,
    pr.IsClosed AS CERRADA,
    pr.PayrollTypeName AS TipoNomina
  FROM hr.PayrollRun pr
  WHERE pr.CompanyId = @CompanyId
    AND pr.BranchId = @BranchId
    AND (@Nomina IS NULL OR pr.PayrollCode = @Nomina)
    AND (@Cedula IS NULL OR pr.EmployeeCode = @Cedula)
    AND (@FechaDesde IS NULL OR pr.DateFrom >= @FechaDesde)
    AND (@FechaHasta IS NULL OR pr.DateTo <= @FechaHasta)
    AND (@SoloAbiertas = 0 OR pr.IsClosed = 0)
  ORDER BY pr.ProcessDate DESC, pr.PayrollRunId DESC
  OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;
END

GO
 
 
-- =============================================
-- STORED PROCEDURE: dbo.sp_Nomina_PrepararVariablesBase
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
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
  EXEC dbo.sp_Nomina_SetVariable @SessionID, 'DIAS_PERIODO', @DiasPeriodo, 'D°as del per°odo';
  EXEC dbo.sp_Nomina_SetVariable @SessionID, 'FERIADOS', @Feriados, 'Feriados del per°odo';
  EXEC dbo.sp_Nomina_SetVariable @SessionID, 'DOMINGOS', @Domingos, 'Domingos del per°odo';
  EXEC dbo.sp_Nomina_SetVariable @SessionID, 'SUELDO', @Sueldo, 'Sueldo mensual referencial';
  EXEC dbo.sp_Nomina_SetVariable @SessionID, 'SALARIO_DIARIO', @SalarioDiario, 'Salario diario referencial';
  EXEC dbo.sp_Nomina_SetVariable @SessionID, 'SALARIO_HORA', @SalarioHora, 'Salario hora referencial';
  EXEC dbo.sp_Nomina_SetVariable @SessionID, 'HORAS_MES', 240, 'Horas laborales referenciales';

  EXEC dbo.sp_Nomina_CalcularAntiguedad @SessionID, @Cedula, @FechaHasta;
END

GO
 
 
-- =============================================
-- STORED PROCEDURE: dbo.sp_Nomina_PrepararVariablesRegimen
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
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
 
 
-- =============================================
-- STORED PROCEDURE: dbo.sp_Nomina_ProcesarEmpleado
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE dbo.sp_Nomina_ProcesarEmpleado
  @Nomina NVARCHAR(20),
  @Cedula NVARCHAR(32),
  @FechaInicio DATE,
  @FechaHasta DATE,
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
  DECLARE @RunId BIGINT;
  DECLARE @SessionID NVARCHAR(80);

  DECLARE @Asig DECIMAL(18,6) = 0;
  DECLARE @Ded DECIMAL(18,6) = 0;
  DECLARE @Neto DECIMAL(18,6) = 0;

  SET @Resultado = 0;
  SET @Mensaje = N'';
  SET @SessionID = (@Nomina + N'_' + @Cedula + N'_' + CONVERT(NVARCHAR(8), GETDATE(), 112));

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
      SET @Resultado = 0;
      SET @Mensaje = N'Empleado no encontrado o inactivo en master.Employee';
      RETURN;
    END

    EXEC dbo.sp_Nomina_PrepararVariablesBase @SessionID, @Cedula, @Nomina, @FechaInicio, @FechaHasta;

    BEGIN TRAN;

    SELECT TOP 1 @RunId = pr.PayrollRunId
    FROM hr.PayrollRun pr
    WHERE pr.CompanyId = @CompanyId
      AND pr.BranchId = @BranchId
      AND pr.PayrollCode = @Nomina
      AND pr.EmployeeCode = @Cedula
      AND pr.DateFrom = @FechaInicio
      AND pr.DateTo = @FechaHasta
      AND pr.RunSource = N'SP_LEGACY_COMPAT'
    ORDER BY pr.PayrollRunId DESC;

    IF @RunId IS NULL
    BEGIN
      INSERT INTO hr.PayrollRun (
        CompanyId, BranchId, PayrollCode, EmployeeId, EmployeeCode, EmployeeName,
        ProcessDate, DateFrom, DateTo, TotalAssignments, TotalDeductions, NetTotal,
        IsClosed, PayrollTypeName, RunSource, CreatedAt, UpdatedAt, CreatedByUserId, UpdatedByUserId
      )
      VALUES (
        @CompanyId, @BranchId, @Nomina, @EmployeeId, @Cedula, @EmployeeName,
        CAST(GETDATE() AS DATE), @FechaInicio, @FechaHasta, 0, 0, 0,
        0, N'COMPAT', N'SP_LEGACY_COMPAT', SYSUTCDATETIME(), SYSUTCDATETIME(), @UserId, @UserId
      );

      SET @RunId = SCOPE_IDENTITY();
    END
    ELSE
    BEGIN
      UPDATE hr.PayrollRun
      SET UpdatedAt = SYSUTCDATETIME(),
          UpdatedByUserId = @UserId,
          ProcessDate = CAST(GETDATE() AS DATE)
      WHERE PayrollRunId = @RunId;

      DELETE FROM hr.PayrollRunLine WHERE PayrollRunId = @RunId;
    END

    DECLARE @ConceptCode NVARCHAR(20);
    DECLARE @ConceptName NVARCHAR(120);
    DECLARE @ConceptType NVARCHAR(20);
    DECLARE @AccountCode NVARCHAR(50);
    DECLARE @Monto DECIMAL(18,6);
    DECLARE @Total DECIMAL(18,6);
    DECLARE @Desc NVARCHAR(200);
    DECLARE @VarCode NVARCHAR(120);
    DECLARE @VarDesc NVARCHAR(255);
    DECLARE @VarTotal DECIMAL(18,6);

    DECLARE concept_cursor CURSOR LOCAL FAST_FORWARD FOR
      SELECT ConceptCode, ConceptName, ConceptType, AccountingAccountCode
      FROM hr.PayrollConcept
      WHERE CompanyId = @CompanyId
        AND PayrollCode = @Nomina
        AND IsActive = 1
      ORDER BY SortOrder, ConceptCode;

    OPEN concept_cursor;
    FETCH NEXT FROM concept_cursor INTO @ConceptCode, @ConceptName, @ConceptType, @AccountCode;
    WHILE @@FETCH_STATUS = 0
    BEGIN
      EXEC dbo.sp_Nomina_CalcularConcepto
        @SessionID = @SessionID,
        @Cedula = @Cedula,
        @CoConcepto = @ConceptCode,
        @CoNomina = @Nomina,
        @Cantidad = 1,
        @Monto = @Monto OUTPUT,
        @Total = @Total OUTPUT,
        @Descripcion = @Desc OUTPUT;


      INSERT INTO hr.PayrollRunLine (
        PayrollRunId, ConceptCode, ConceptName, ConceptType,
        Quantity, Amount, Total, DescriptionText, AccountingAccountCode, CreatedAt
      )
      VALUES (
        @RunId, @ConceptCode, ISNULL(@ConceptName, @Desc), ISNULL(@ConceptType, N'ASIGNACION'),
        1, ISNULL(@Monto,0), ISNULL(@Total,0), @Desc, @AccountCode, SYSUTCDATETIME()
      );

      IF UPPER(ISNULL(@ConceptType, N'')) = N'DEDUCCION'
        SET @Ded = @Ded + ISNULL(@Total,0);
      ELSE
        SET @Asig = @Asig + ISNULL(@Total,0);

      SET @VarCode = N'C' + @ConceptCode;
      SET @VarTotal = ISNULL(@Total, 0);
      SET @VarDesc = ISNULL(@ConceptName, @Desc);
      EXEC dbo.sp_Nomina_SetVariable @SessionID, @VarCode, @VarTotal, @VarDesc;

      FETCH NEXT FROM concept_cursor INTO @ConceptCode, @ConceptName, @ConceptType, @AccountCode;
    END
    CLOSE concept_cursor;
    DEALLOCATE concept_cursor;

    SET @Neto = @Asig - @Ded;

    UPDATE hr.PayrollRun
    SET TotalAssignments = @Asig,
        TotalDeductions = @Ded,
        NetTotal = @Neto,
        UpdatedAt = SYSUTCDATETIME(),
        UpdatedByUserId = @UserId
    WHERE PayrollRunId = @RunId;

    COMMIT;

    EXEC dbo.sp_Nomina_LimpiarVariables @SessionID;

    SET @Resultado = 1;
    SET @Mensaje = N'Procesado can¢nico. Asig=' + CONVERT(NVARCHAR(40), @Asig) + N' Ded=' + CONVERT(NVARCHAR(40), @Ded) + N' Neto=' + CONVERT(NVARCHAR(40), @Neto);
  END TRY
  BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK;
    EXEC dbo.sp_Nomina_LimpiarVariables @SessionID;
    SET @Resultado = 0;
    SET @Mensaje = ERROR_MESSAGE();
  END CATCH
END

GO
 
 
-- =============================================
-- STORED PROCEDURE: dbo.sp_Nomina_ProcesarEmpleadoConceptoLegal
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE dbo.sp_Nomina_ProcesarEmpleadoConceptoLegal
  @Nomina NVARCHAR(20),
  @Cedula NVARCHAR(32),
  @FechaInicio DATE,
  @FechaHasta DATE,
  @Convencion NVARCHAR(50) = NULL,
  @TipoCalculo NVARCHAR(50) = N'MENSUAL',
  @CoUsuario NVARCHAR(50) = N'API',
  @Resultado INT OUTPUT,
  @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @Regimen NVARCHAR(10) = UPPER(ISNULL(@Convencion, @Nomina));

  EXEC dbo.sp_Nomina_ProcesarEmpleadoRegimen
    @Nomina = @Nomina,
    @Cedula = @Cedula,
    @FechaInicio = @FechaInicio,
    @FechaHasta = @FechaHasta,
    @Regimen = @Regimen,
    @CoUsuario = @CoUsuario,
    @Resultado = @Resultado OUTPUT,
    @Mensaje = @Mensaje OUTPUT;
END

GO
 
 
-- =============================================
-- STORED PROCEDURE: dbo.sp_Nomina_ProcesarEmpleadoRegimen
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
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
  DECLARE @SessionID NVARCHAR(80) = (@Nomina + N'_' + @Cedula + N'_' + CONVERT(NVARCHAR(8), GETDATE(), 112));
  DECLARE @NominaProceso NVARCHAR(20);

  IF UPPER(@Nomina) LIKE N'%VAC%' SET @TipoCalculo = N'VACACIONES';
  IF UPPER(@Nomina) LIKE N'%LIQ%' SET @TipoCalculo = N'LIQUIDACION';

  -- Reusar procesamiento base can¢nico
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
 
 
-- =============================================
-- STORED PROCEDURE: dbo.sp_Nomina_ProcesarNomina
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE dbo.sp_Nomina_ProcesarNomina
  @Nomina NVARCHAR(20),
  @FechaInicio DATE,
  @FechaHasta DATE,
  @CoUsuario NVARCHAR(50) = N'API',
  @SoloActivos BIT = 1,
  @Procesados INT OUTPUT,
  @Errores INT OUTPUT,
  @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @CompanyId INT;
  DECLARE @BranchId INT;
  DECLARE @Cedula NVARCHAR(32);
  DECLARE @Res INT;
  DECLARE @Msg NVARCHAR(500);

  SET @Procesados = 0;
  SET @Errores = 0;
  SET @Mensaje = N'';

  EXEC dbo.sp_Nomina_GetScope @CompanyId OUTPUT, @BranchId OUTPUT;

  DECLARE emp_cursor CURSOR LOCAL FAST_FORWARD FOR
    SELECT e.EmployeeCode
    FROM [master].Employee e
    WHERE e.CompanyId = @CompanyId
      AND e.IsDeleted = 0
      AND (@SoloActivos = 0 OR e.IsActive = 1)
    ORDER BY e.EmployeeCode;

  OPEN emp_cursor;
  FETCH NEXT FROM emp_cursor INTO @Cedula;
  WHILE @@FETCH_STATUS = 0
  BEGIN
    EXEC dbo.sp_Nomina_ProcesarEmpleado
      @Nomina = @Nomina,
      @Cedula = @Cedula,
      @FechaInicio = @FechaInicio,
      @FechaHasta = @FechaHasta,
      @CoUsuario = @CoUsuario,
      @Resultado = @Res OUTPUT,
      @Mensaje = @Msg OUTPUT;

    IF @Res = 1 SET @Procesados = @Procesados + 1;
    ELSE SET @Errores = @Errores + 1;

    FETCH NEXT FROM emp_cursor INTO @Cedula;
  END
  CLOSE emp_cursor;
  DEALLOCATE emp_cursor;

  SET @Mensaje = N'Proceso completado. Procesados=' + CONVERT(NVARCHAR(20), @Procesados) + N' Errores=' + CONVERT(NVARCHAR(20), @Errores);
END

GO
 
 
-- =============================================
-- STORED PROCEDURE: dbo.sp_Nomina_ProcesarVacaciones
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
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
 
 
-- =============================================
-- STORED PROCEDURE: dbo.sp_Nomina_ReemplazarVariables
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE dbo.sp_Nomina_ReemplazarVariables
  @SessionID NVARCHAR(80),
  @Formula NVARCHAR(MAX),
  @FormulaOut NVARCHAR(MAX) OUTPUT
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @Result NVARCHAR(MAX) = ISNULL(@Formula, N'');
  DECLARE @VarName NVARCHAR(120);
  DECLARE @VarValue NVARCHAR(80);

  DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
    SELECT Variable, CONVERT(NVARCHAR(80), Valor)
    FROM hr.PayrollCalcVariable
    WHERE SessionID = @SessionID
    ORDER BY LEN(Variable) DESC;

  OPEN cur;
  FETCH NEXT FROM cur INTO @VarName, @VarValue;
  WHILE @@FETCH_STATUS = 0
  BEGIN
    SET @Result = REPLACE(@Result, @VarName, @VarValue);
    FETCH NEXT FROM cur INTO @VarName, @VarValue;
  END
  CLOSE cur;
  DEALLOCATE cur;

  SET @FormulaOut = @Result;
END

GO
 
 
-- =============================================
-- STORED PROCEDURE: dbo.sp_Nomina_SetVariable
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
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
 
 
-- =============================================
-- STORED PROCEDURE: dbo.sp_Nomina_Vacaciones_Get
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE dbo.sp_Nomina_Vacaciones_Get
  @VacacionID NVARCHAR(50)
AS
BEGIN
  SET NOCOUNT ON;

  SELECT TOP 1
    vp.*
  FROM hr.VacationProcess vp
  WHERE vp.VacationCode = @VacacionID;

  SELECT
    vl.*
  FROM hr.VacationProcessLine vl
  INNER JOIN hr.VacationProcess vp ON vp.VacationProcessId = vl.VacationProcessId
  WHERE vp.VacationCode = @VacacionID
  ORDER BY vl.VacationProcessLineId;
END

GO
 
 
-- =============================================
-- STORED PROCEDURE: dbo.sp_Nomina_Vacaciones_List
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE dbo.sp_Nomina_Vacaciones_List
  @Cedula NVARCHAR(32) = NULL,
  @Page INT = 1,
  @Limit INT = 50,
  @TotalCount INT OUTPUT
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @CompanyId INT;
  DECLARE @BranchId INT;
  DECLARE @Offset INT = (@Page - 1) * @Limit;

  EXEC dbo.sp_Nomina_GetScope @CompanyId OUTPUT, @BranchId OUTPUT;

  SELECT @TotalCount = COUNT(1)
  FROM hr.VacationProcess vp
  WHERE vp.CompanyId = @CompanyId
    AND vp.BranchId = @BranchId
    AND (@Cedula IS NULL OR vp.EmployeeCode = @Cedula);

  SELECT
    vp.VacationProcessId,
    vp.VacationCode AS Vacacion,
    vp.EmployeeCode AS Cedula,
    vp.EmployeeName AS NombreEmpleado,
    vp.StartDate AS Inicio,
    vp.EndDate AS Hasta,
    vp.ReintegrationDate AS Reintegro,
    vp.ProcessDate AS Fecha_Calculo,
    vp.TotalAmount AS Total,
    vp.CalculatedAmount AS TotalCalculado
  FROM hr.VacationProcess vp
  WHERE vp.CompanyId = @CompanyId
    AND vp.BranchId = @BranchId
    AND (@Cedula IS NULL OR vp.EmployeeCode = @Cedula)
  ORDER BY vp.ProcessDate DESC, vp.VacationProcessId DESC
  OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;
END

GO
 
 
-- =============================================
-- STORED PROCEDURE: dbo.sp_Nomina_ValidarFormulasConceptoLegal
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE dbo.sp_Nomina_ValidarFormulasConceptoLegal
  @Convencion NVARCHAR(50) = NULL,
  @TipoCalculo NVARCHAR(50) = NULL
AS
BEGIN
  SET NOCOUNT ON;

  CREATE TABLE #Resultados (
    Id BIGINT,
    CO_CONCEPT NVARCHAR(20),
    NB_CONCEPTO NVARCHAR(120),
    FORMULA NVARCHAR(MAX),
    Error NVARCHAR(500),
    EsValida BIT
  );

  DECLARE @Id BIGINT;
  DECLARE @CoConcept NVARCHAR(20);
  DECLARE @NbConcepto NVARCHAR(120);
  DECLARE @Formula NVARCHAR(MAX);
  DECLARE @Result DECIMAL(18,6);
  DECLARE @FormulaResuelta NVARCHAR(MAX);
  DECLARE @SessionTest NVARCHAR(80) = (N'TEST_' + CONVERT(NVARCHAR(8), GETDATE(), 112));

  EXEC dbo.sp_Nomina_LimpiarVariables @SessionTest;
  EXEC dbo.sp_Nomina_SetVariable @SessionTest, N'SUELDO', 30000, N'Test';
  EXEC dbo.sp_Nomina_SetVariable @SessionTest, N'SALARIO_DIARIO', 1000, N'Test';
  EXEC dbo.sp_Nomina_SetVariable @SessionTest, N'DIAS_PERIODO', 30, N'Test';
  EXEC dbo.sp_Nomina_SetVariable @SessionTest, N'PCT_SSO', 0.04, N'Test';

  DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
    SELECT PayrollConceptId, ConceptCode, ConceptName, Formula
    FROM hr.PayrollConcept
    WHERE ConventionCode IS NOT NULL
      AND (@Convencion IS NULL OR ConventionCode = @Convencion)
      AND (@TipoCalculo IS NULL OR CalculationType = @TipoCalculo)
      AND IsActive = 1
    ORDER BY ConventionCode, CalculationType, SortOrder, ConceptCode;

  OPEN cur;
  FETCH NEXT FROM cur INTO @Id, @CoConcept, @NbConcepto, @Formula;
  WHILE @@FETCH_STATUS = 0
  BEGIN
    IF @Formula IS NULL OR LTRIM(RTRIM(@Formula)) = N''
    BEGIN
      INSERT INTO #Resultados VALUES (@Id, @CoConcept, @NbConcepto, @Formula, N'Sin f¢rmula (usa valor por defecto)', 1);
    END
    ELSE IF PATINDEX('%[^A-Za-z0-9_\.+\-\*/\(\) ]%', @Formula) > 0
    BEGIN
      INSERT INTO #Resultados VALUES (@Id, @CoConcept, @NbConcepto, @Formula, N'Contiene caracteres no permitidos', 0);
    END
    ELSE
    BEGIN
      BEGIN TRY
        EXEC dbo.sp_Nomina_EvaluarFormula @SessionTest, @Formula, @Result OUTPUT, @FormulaResuelta OUTPUT;
        INSERT INTO #Resultados VALUES (@Id, @CoConcept, @NbConcepto, @Formula, NULL, 1);
      END TRY
      BEGIN CATCH
        INSERT INTO #Resultados VALUES (@Id, @CoConcept, @NbConcepto, @Formula, ERROR_MESSAGE(), 0);
      END CATCH
    END

    FETCH NEXT FROM cur INTO @Id, @CoConcept, @NbConcepto, @Formula;
  END
  CLOSE cur;
  DEALLOCATE cur;

  EXEC dbo.sp_Nomina_LimpiarVariables @SessionTest;

  SELECT * FROM #Resultados ORDER BY EsValida ASC, CO_CONCEPT;
END

GO
 
 
-- =============================================
-- STORED PROCEDURE: dbo.usp_Almacen_Delete
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE usp_Almacen_Delete
    @Codigo NVARCHAR(10), @Resultado INT OUTPUT, @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON; SET @Resultado = 0; SET @Mensaje = N'';
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM master.Warehouse WHERE WarehouseCode = @Codigo AND IsDeleted = 0)
        BEGIN SET @Resultado = -1; SET @Mensaje = N'Almac«∏n no encontrado'; RETURN; END
        UPDATE master.Warehouse SET IsDeleted = 1, UpdatedAt = SYSUTCDATETIME() WHERE WarehouseCode = @Codigo;
        SET @Resultado = 1; SET @Mensaje = N'OK';
    END TRY BEGIN CATCH SET @Resultado = -99; SET @Mensaje = ERROR_MESSAGE(); END CATCH
END

GO
 
 
-- =============================================
-- STORED PROCEDURE: dbo.usp_Almacen_GetByCodigo
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE usp_Almacen_GetByCodigo @Codigo NVARCHAR(10)
AS BEGIN SET NOCOUNT ON;
    SELECT WarehouseCode AS Codigo, Description AS Descripcion, WarehouseType AS Tipo
    FROM master.Warehouse WHERE WarehouseCode = @Codigo AND IsDeleted = 0;
END

GO
 
 
-- =============================================
-- STORED PROCEDURE: dbo.usp_Almacen_Insert
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE usp_Almacen_Insert
    @RowXml NVARCHAR(MAX), @Resultado INT OUTPUT, @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON; SET @Resultado = 0; SET @Mensaje = N'';
    DECLARE @x XML = CAST(@RowXml AS XML);
    DECLARE @Codigo     NVARCHAR(20) = NULLIF(@x.value('(/row/@Codigo)[1]',     'NVARCHAR(20)'), N'');
    DECLARE @Desc       NVARCHAR(200)= NULLIF(@x.value('(/row/@Descripcion)[1]','NVARCHAR(200)'),N'');
    DECLARE @Tipo       NVARCHAR(20) = NULLIF(@x.value('(/row/@Tipo)[1]',       'NVARCHAR(20)'), N'');
    BEGIN TRY
        IF @Codigo IS NULL BEGIN SET @Resultado = -1; SET @Mensaje = N'Codigo requerido'; RETURN; END
        IF EXISTS (SELECT 1 FROM master.Warehouse WHERE WarehouseCode = @Codigo AND IsDeleted = 0)
        BEGIN SET @Resultado = -1; SET @Mensaje = N'Almac«∏n ya existe'; RETURN; END
        INSERT INTO master.Warehouse (WarehouseCode, Description, WarehouseType)
        VALUES (@Codigo, COALESCE(@Desc, @Codigo), COALESCE(@Tipo, N'PRINCIPAL'));
        SET @Resultado = 1; SET @Mensaje = N'OK';
    END TRY BEGIN CATCH SET @Resultado = -99; SET @Mensaje = ERROR_MESSAGE(); END CATCH
END

GO
 
 
-- =============================================
-- STORED PROCEDURE: dbo.usp_Almacen_List
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE usp_Almacen_List
    @Search     NVARCHAR(100) = NULL,
    @Tipo       NVARCHAR(50)  = NULL,
    @Page       INT = 1,
    @Limit      INT = 50,
    @TotalCount INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Offset INT = (ISNULL(NULLIF(@Page,0),1) - 1) * ISNULL(NULLIF(@Limit,0),50);
    IF @Offset < 0 SET @Offset = 0; IF @Limit < 1 SET @Limit = 50; IF @Limit > 500 SET @Limit = 500;
    DECLARE @S NVARCHAR(100) = CASE WHEN @Search IS NOT NULL AND LTRIM(RTRIM(@Search)) <> N'' THEN N'%' + @Search + N'%' ELSE NULL END;
    SELECT @TotalCount = COUNT(1) FROM master.Warehouse
    WHERE IsDeleted = 0
      AND (@S IS NULL OR WarehouseCode LIKE @S OR Description LIKE @S)
      AND (@Tipo IS NULL OR WarehouseType = @Tipo);
    SELECT WarehouseCode AS Codigo, Description AS Descripcion, WarehouseType AS Tipo
    FROM master.Warehouse
    WHERE IsDeleted = 0
      AND (@S IS NULL OR WarehouseCode LIKE @S OR Description LIKE @S)
      AND (@Tipo IS NULL OR WarehouseType = @Tipo)
    ORDER BY WarehouseCode OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;
END

GO
 
 
-- =============================================
-- STORED PROCEDURE: dbo.usp_Almacen_Update
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE usp_Almacen_Update
    @Codigo NVARCHAR(10), @RowXml NVARCHAR(MAX), @Resultado INT OUTPUT, @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON; SET @Resultado = 0; SET @Mensaje = N'';
    DECLARE @x XML = CAST(@RowXml AS XML);
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM master.Warehouse WHERE WarehouseCode = @Codigo AND IsDeleted = 0)
        BEGIN SET @Resultado = -1; SET @Mensaje = N'Almac«∏n no encontrado'; RETURN; END
        UPDATE master.Warehouse SET
            Description   = COALESCE(NULLIF(@x.value('(/row/@Descripcion)[1]','NVARCHAR(200)'),N''), Description),
            WarehouseType = COALESCE(NULLIF(@x.value('(/row/@Tipo)[1]',       'NVARCHAR(20)'), N''), WarehouseType),
            UpdatedAt     = SYSUTCDATETIME()
        WHERE WarehouseCode = @Codigo;
        SET @Resultado = 1; SET @Mensaje = N'OK';
    END TRY BEGIN CATCH SET @Resultado = -99; SET @Mensaje = ERROR_MESSAGE(); END CATCH
END

GO
 
 
-- =============================================
-- STORED PROCEDURE: dbo.usp_Categorias_Delete
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE usp_Categorias_Delete
    @Codigo    INT,
    @Resultado INT OUTPUT,
    @Mensaje   NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON; SET @Resultado = 0; SET @Mensaje = N'';
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM master.Category WHERE CategoryId = @Codigo AND IsDeleted = 0)
        BEGIN SET @Resultado = -1; SET @Mensaje = N'Categor«a no encontrada'; RETURN; END
        UPDATE master.Category SET IsDeleted = 1, UpdatedAt = SYSUTCDATETIME() WHERE CategoryId = @Codigo;
        SET @Resultado = 1; SET @Mensaje = N'OK';
    END TRY BEGIN CATCH SET @Resultado = -99; SET @Mensaje = ERROR_MESSAGE(); END CATCH
END

GO
 
 
-- =============================================
-- STORED PROCEDURE: dbo.usp_Categorias_GetByCodigo
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE usp_Categorias_GetByCodigo @Codigo INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CategoryId AS Codigo, CategoryName AS Nombre, UserCode AS Co_Usuario
    FROM master.Category WHERE CategoryId = @Codigo AND IsDeleted = 0;
END

GO
 
 
-- =============================================
-- STORED PROCEDURE: dbo.usp_Categorias_Insert
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE usp_Categorias_Insert
    @RowXml      NVARCHAR(MAX),
    @Resultado   INT OUTPUT,
    @Mensaje     NVARCHAR(500) OUTPUT,
    @NuevoCodigo INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    SET @Resultado = 0; SET @Mensaje = N''; SET @NuevoCodigo = 0;
    DECLARE @x XML = CAST(@RowXml AS XML);
    DECLARE @Nombre    NVARCHAR(100) = NULLIF(@x.value('(/row/@Nombre)[1]',    'NVARCHAR(100)'), N'');
    DECLARE @CoUsuario NVARCHAR(20)  = NULLIF(@x.value('(/row/@Co_Usuario)[1]','NVARCHAR(20)'),  N'');
    BEGIN TRY
        IF @Nombre IS NULL BEGIN SET @Resultado = -1; SET @Mensaje = N'Nombre requerido'; RETURN; END
        INSERT INTO master.Category (CategoryName, UserCode) VALUES (@Nombre, @CoUsuario);
        SET @NuevoCodigo = CAST(SCOPE_IDENTITY() AS INT);
        SET @Resultado = 1; SET @Mensaje = N'OK';
    END TRY BEGIN CATCH SET @Resultado = -99; SET @Mensaje = ERROR_MESSAGE(); END CATCH
END

GO
 
 
-- =============================================
-- STORED PROCEDURE: dbo.usp_Categorias_List
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE usp_Categorias_List
    @Search     NVARCHAR(100) = NULL,
    @Page       INT = 1,
    @Limit      INT = 50,
    @TotalCount INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Offset INT = (ISNULL(NULLIF(@Page,0),1) - 1) * ISNULL(NULLIF(@Limit,0),50);
    IF @Offset < 0 SET @Offset = 0;
    IF @Limit < 1 SET @Limit = 50;
    IF @Limit > 500 SET @Limit = 500;
    DECLARE @S NVARCHAR(100) = CASE WHEN @Search IS NOT NULL AND LTRIM(RTRIM(@Search)) <> N'' THEN N'%' + @Search + N'%' ELSE NULL END;
    SELECT @TotalCount = COUNT(1) FROM master.Category
    WHERE IsDeleted = 0 AND (@S IS NULL OR CategoryName LIKE @S OR CAST(CategoryId AS NVARCHAR(20)) LIKE @S);
    SELECT CategoryId AS Codigo, CategoryName AS Nombre, UserCode AS Co_Usuario
    FROM master.Category
    WHERE IsDeleted = 0 AND (@S IS NULL OR CategoryName LIKE @S OR CAST(CategoryId AS NVARCHAR(20)) LIKE @S)
    ORDER BY CategoryId OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;
END

GO
 
 
-- =============================================
-- STORED PROCEDURE: dbo.usp_Categorias_Update
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE usp_Categorias_Update
    @Codigo    INT,
    @RowXml    NVARCHAR(MAX),
    @Resultado INT OUTPUT,
    @Mensaje   NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON; SET @Resultado = 0; SET @Mensaje = N'';
    DECLARE @x XML = CAST(@RowXml AS XML);
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM master.Category WHERE CategoryId = @Codigo AND IsDeleted = 0)
        BEGIN SET @Resultado = -1; SET @Mensaje = N'Categor«a no encontrada'; RETURN; END
        UPDATE master.Category SET
            CategoryName = COALESCE(NULLIF(@x.value('(/row/@Nombre)[1]',    'NVARCHAR(100)'), N''), CategoryName),
            UserCode     = COALESCE(NULLIF(@x.value('(/row/@Co_Usuario)[1]','NVARCHAR(20)'),  N''), UserCode),
            UpdatedAt    = SYSUTCDATETIME()
        WHERE CategoryId = @Codigo;
        SET @Resultado = 1; SET @Mensaje = N'OK';
    END TRY BEGIN CATCH SET @Resultado = -99; SET @Mensaje = ERROR_MESSAGE(); END CATCH
END

GO
 
 
-- =============================================
-- STORED PROCEDURE: dbo.usp_CentroCosto_Delete
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE usp_CentroCosto_Delete
    @Codigo NVARCHAR(50), @Resultado INT OUTPUT, @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON; SET @Resultado = 0; SET @Mensaje = N'';
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM master.CostCenter WHERE CostCenterCode = @Codigo AND IsDeleted = 0)
        BEGIN SET @Resultado = -1; SET @Mensaje = N'Centro de costo no encontrado'; RETURN; END
        UPDATE master.CostCenter SET IsDeleted = 1, UpdatedAt = SYSUTCDATETIME() WHERE CostCenterCode = @Codigo;
        SET @Resultado = 1; SET @Mensaje = N'OK';
    END TRY BEGIN CATCH SET @Resultado = -99; SET @Mensaje = ERROR_MESSAGE(); END CATCH
END

GO
 
 
-- =============================================
-- STORED PROCEDURE: dbo.usp_CentroCosto_GetByCodigo
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE usp_CentroCosto_GetByCodigo @Codigo NVARCHAR(50)
AS BEGIN SET NOCOUNT ON;
    SELECT CostCenterCode AS Codigo, CostCenterName AS Descripcion,
           CAST(NULL AS NVARCHAR(50)) AS Presupuestado,
           CAST(NULL AS NVARCHAR(50)) AS Saldo_Real
    FROM master.CostCenter WHERE CostCenterCode = @Codigo AND IsDeleted = 0;
END

GO
 
 
-- =============================================
-- STORED PROCEDURE: dbo.usp_CentroCosto_Insert
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE usp_CentroCosto_Insert
    @RowXml NVARCHAR(MAX), @Resultado INT OUTPUT, @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON; SET @Resultado = 0; SET @Mensaje = N'';
    DECLARE @x XML = CAST(@RowXml AS XML);
    DECLARE @Codigo NVARCHAR(20) = NULLIF(@x.value('(/row/@Codigo)[1]',     'NVARCHAR(20)'),N'');
    DECLARE @Desc   NVARCHAR(100)= NULLIF(@x.value('(/row/@Descripcion)[1]','NVARCHAR(100)'),N'');
    BEGIN TRY
        IF @Codigo IS NULL BEGIN SET @Resultado = -1; SET @Mensaje = N'Codigo requerido'; RETURN; END
        IF EXISTS (SELECT 1 FROM master.CostCenter WHERE CostCenterCode = @Codigo AND IsDeleted = 0)
        BEGIN SET @Resultado = -1; SET @Mensaje = N'Centro de costo ya existe'; RETURN; END
        INSERT INTO master.CostCenter (CostCenterCode, CostCenterName)
        VALUES (@Codigo, COALESCE(@Desc, @Codigo));
        SET @Resultado = 1; SET @Mensaje = N'OK';
    END TRY BEGIN CATCH SET @Resultado = -99; SET @Mensaje = ERROR_MESSAGE(); END CATCH
END

GO
 
 
-- =============================================
-- STORED PROCEDURE: dbo.usp_CentroCosto_List
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE usp_CentroCosto_List
    @Search     NVARCHAR(100) = NULL,
    @Page       INT = 1,
    @Limit      INT = 50,
    @TotalCount INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Offset INT = (ISNULL(NULLIF(@Page,0),1) - 1) * ISNULL(NULLIF(@Limit,0),50);
    IF @Offset < 0 SET @Offset = 0; IF @Limit < 1 SET @Limit = 50; IF @Limit > 500 SET @Limit = 500;
    DECLARE @S NVARCHAR(100) = CASE WHEN @Search IS NOT NULL AND LTRIM(RTRIM(@Search)) <> N'' THEN N'%' + @Search + N'%' ELSE NULL END;
    SELECT @TotalCount = COUNT(1) FROM master.CostCenter
    WHERE IsDeleted = 0 AND (@S IS NULL OR CostCenterCode LIKE @S OR CostCenterName LIKE @S);
    SELECT CostCenterCode AS Codigo, CostCenterName AS Descripcion,
           CAST(NULL AS NVARCHAR(50)) AS Presupuestado,
           CAST(NULL AS NVARCHAR(50)) AS Saldo_Real
    FROM master.CostCenter
    WHERE IsDeleted = 0 AND (@S IS NULL OR CostCenterCode LIKE @S OR CostCenterName LIKE @S)
    ORDER BY CostCenterCode OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;
END

GO
 
 
-- =============================================
-- STORED PROCEDURE: dbo.usp_CentroCosto_Update
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE usp_CentroCosto_Update
    @Codigo NVARCHAR(50), @RowXml NVARCHAR(MAX), @Resultado INT OUTPUT, @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON; SET @Resultado = 0; SET @Mensaje = N'';
    DECLARE @x XML = CAST(@RowXml AS XML);
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM master.CostCenter WHERE CostCenterCode = @Codigo AND IsDeleted = 0)
        BEGIN SET @Resultado = -1; SET @Mensaje = N'Centro de costo no encontrado'; RETURN; END
        UPDATE master.CostCenter SET
            CostCenterName = COALESCE(NULLIF(@x.value('(/row/@Descripcion)[1]','NVARCHAR(100)'),N''), CostCenterName),
            UpdatedAt      = SYSUTCDATETIME()
        WHERE CostCenterCode = @Codigo;
        SET @Resultado = 1; SET @Mensaje = N'OK';
    END TRY BEGIN CATCH SET @Resultado = -99; SET @Mensaje = ERROR_MESSAGE(); END CATCH
END

GO
 
 
-- =============================================
-- STORED PROCEDURE: dbo.usp_Clases_Delete
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE usp_Clases_Delete
    @Codigo INT, @Resultado INT OUTPUT, @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON; SET @Resultado = 0; SET @Mensaje = N'';
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM master.ProductClass WHERE ClassId = @Codigo AND IsDeleted = 0)
        BEGIN SET @Resultado = -1; SET @Mensaje = N'Clase no encontrada'; RETURN; END
        UPDATE master.ProductClass SET IsDeleted = 1, UpdatedAt = SYSUTCDATETIME() WHERE ClassId = @Codigo;
        SET @Resultado = 1; SET @Mensaje = N'OK';
    END TRY BEGIN CATCH SET @Resultado = -99; SET @Mensaje = ERROR_MESSAGE(); END CATCH
END

GO
 
 
-- =============================================
-- STORED PROCEDURE: dbo.usp_Clases_GetByCodigo
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE usp_Clases_GetByCodigo @Codigo INT
AS BEGIN SET NOCOUNT ON;
    SELECT ClassId AS Codigo, ClassName AS Descripcion FROM master.ProductClass WHERE ClassId = @Codigo AND IsDeleted = 0;
END

GO
 
 
-- =============================================
-- STORED PROCEDURE: dbo.usp_Clases_Insert
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE usp_Clases_Insert
    @RowXml NVARCHAR(MAX), @Resultado INT OUTPUT, @Mensaje NVARCHAR(500) OUTPUT, @NuevoCodigo INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON; SET @Resultado = 0; SET @Mensaje = N''; SET @NuevoCodigo = 0;
    DECLARE @x XML = CAST(@RowXml AS XML);
    DECLARE @Desc NVARCHAR(100) = NULLIF(@x.value('(/row/@Descripcion)[1]','NVARCHAR(100)'),N'');
    BEGIN TRY
        IF @Desc IS NULL BEGIN SET @Resultado = -1; SET @Mensaje = N'Descripcion requerida'; RETURN; END
        DECLARE @CCode NVARCHAR(20) = N'C' + FORMAT((SELECT ISNULL(MAX(ClassId),0)+1 FROM master.ProductClass), N'000');
        INSERT INTO master.ProductClass (ClassCode, ClassName) VALUES (@CCode, @Desc);
        SET @NuevoCodigo = CAST(SCOPE_IDENTITY() AS INT);
        SET @Resultado = 1; SET @Mensaje = N'OK';
    END TRY BEGIN CATCH SET @Resultado = -99; SET @Mensaje = ERROR_MESSAGE(); END CATCH
END

GO
 
 
-- =============================================
-- STORED PROCEDURE: dbo.usp_Clases_List
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE usp_Clases_List
    @Search     NVARCHAR(100) = NULL,
    @Page       INT = 1,
    @Limit      INT = 50,
    @TotalCount INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Offset INT = (ISNULL(NULLIF(@Page,0),1) - 1) * ISNULL(NULLIF(@Limit,0),50);
    IF @Offset < 0 SET @Offset = 0; IF @Limit < 1 SET @Limit = 50; IF @Limit > 500 SET @Limit = 500;
    DECLARE @S NVARCHAR(100) = CASE WHEN @Search IS NOT NULL AND LTRIM(RTRIM(@Search)) <> N'' THEN N'%' + @Search + N'%' ELSE NULL END;
    SELECT @TotalCount = COUNT(1) FROM master.ProductClass
    WHERE IsDeleted = 0 AND (@S IS NULL OR ClassName LIKE @S OR CAST(ClassId AS NVARCHAR(20)) LIKE @S);
    SELECT ClassId AS Codigo, ClassName AS Descripcion
    FROM master.ProductClass
    WHERE IsDeleted = 0 AND (@S IS NULL OR ClassName LIKE @S OR CAST(ClassId AS NVARCHAR(20)) LIKE @S)
    ORDER BY ClassId OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;
END

GO
 
 
-- =============================================
-- STORED PROCEDURE: dbo.usp_Clases_Update
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE usp_Clases_Update
    @Codigo INT, @RowXml NVARCHAR(MAX), @Resultado INT OUTPUT, @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON; SET @Resultado = 0; SET @Mensaje = N'';
    DECLARE @x XML = CAST(@RowXml AS XML);
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM master.ProductClass WHERE ClassId = @Codigo AND IsDeleted = 0)
        BEGIN SET @Resultado = -1; SET @Mensaje = N'Clase no encontrada'; RETURN; END
        UPDATE master.ProductClass SET
            ClassName = COALESCE(NULLIF(@x.value('(/row/@Descripcion)[1]','NVARCHAR(100)'),N''), ClassName),
            UpdatedAt = SYSUTCDATETIME()
        WHERE ClassId = @Codigo;
        SET @Resultado = 1; SET @Mensaje = N'OK';
    END TRY BEGIN CATCH SET @Resultado = -99; SET @Mensaje = ERROR_MESSAGE(); END CATCH
END

GO
 
 
-- =============================================
-- STORED PROCEDURE: dbo.usp_CxC_AplicarCobro
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

CREATE PROCEDURE dbo.usp_CxC_AplicarCobro
    @RequestId       NVARCHAR(100),
    @CodCliente      NVARCHAR(24),
    @Fecha           NVARCHAR(10),
    @MontoTotal      DECIMAL(18,2),
    @CodUsuario      NVARCHAR(40),
    @Observaciones   NVARCHAR(500) = N'',
    @DocumentosXml   NVARCHAR(MAX),
    @FormasPagoXml   NVARCHAR(MAX) = NULL,
    @NumRecibo       NVARCHAR(50) OUTPUT,
    @Resultado       INT OUTPUT,
    @Mensaje         NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @Resultado = 0;
    SET @Mensaje = N'';
    SET @NumRecibo = N'';

    DECLARE @FechaDate DATE = TRY_CONVERT(DATE, @Fecha);
    IF @FechaDate IS NULL
    BEGIN
        SET @Resultado = -91;
        SET @Mensaje = N'Fecha inv«≠lida: ' + ISNULL(@Fecha, N'NULL');
        RETURN;
    END

    DECLARE @CustomerId BIGINT;
    SELECT TOP 1 @CustomerId = c.CustomerId
    FROM [master].Customer c
    WHERE c.CustomerCode = @CodCliente
      AND c.IsDeleted = 0;

    IF @CustomerId IS NULL
    BEGIN
        SET @Resultado = -1;
        SET @Mensaje = N'Cliente no encontrado: ' + @CodCliente;
        RETURN;
    END

    DECLARE @DocsXml XML = TRY_CAST(@DocumentosXml AS XML);
    IF @DocsXml IS NULL
    BEGIN
        SET @Resultado = -2;
        SET @Mensaje = N'DocumentosXml inv«≠lido';
        RETURN;
    END

    DECLARE @Docs TABLE (
        RowNum INT IDENTITY(1,1) PRIMARY KEY,
        TipoDoc NVARCHAR(20) NOT NULL,
        NumDoc NVARCHAR(120) NOT NULL,
        MontoAplicar DECIMAL(18,2) NOT NULL
    );

    INSERT INTO @Docs (TipoDoc, NumDoc, MontoAplicar)
    SELECT
        UPPER(ISNULL(NULLIF(T.X.value('@tipoDoc', 'NVARCHAR(20)'), N''), N'FACT')),
        ISNULL(NULLIF(T.X.value('@numDoc', 'NVARCHAR(120)'), N''), N''),
        ISNULL(TRY_CONVERT(DECIMAL(18,2), NULLIF(T.X.value('@montoAplicar', 'NVARCHAR(40)'), N'')), 0)
    FROM @DocsXml.nodes('/documentos/row') T(X)
    WHERE ISNULL(NULLIF(T.X.value('@numDoc', 'NVARCHAR(120)'), N''), N'') <> N'';

    IF NOT EXISTS (SELECT 1 FROM @Docs)
    BEGIN
        SET @Resultado = -3;
        SET @Mensaje = N'No se recibieron documentos v«≠lidos para aplicar';
        RETURN;
    END

    SET @NumRecibo = N'RCB-' + REPLACE(REPLACE(REPLACE(CONVERT(NVARCHAR(19), SYSUTCDATETIME(), 120), N'-', N''), N' ', N''), N':', N'');

    BEGIN TRY
        BEGIN TRAN;

        IF EXISTS (
            SELECT 1
            FROM ar.ReceivableApplication ra
            INNER JOIN ar.ReceivableDocument rd ON rd.ReceivableDocumentId = ra.ReceivableDocumentId
            WHERE rd.CustomerId = @CustomerId
              AND ra.PaymentReference LIKE @RequestId + N':%'
        )
        BEGIN
            SELECT TOP 1 @NumRecibo = SUBSTRING(ra.PaymentReference, CHARINDEX(N':', ra.PaymentReference) + 1, 50)
            FROM ar.ReceivableApplication ra
            INNER JOIN ar.ReceivableDocument rd ON rd.ReceivableDocumentId = ra.ReceivableDocumentId
            WHERE rd.CustomerId = @CustomerId
              AND ra.PaymentReference LIKE @RequestId + N':%'
            ORDER BY ra.ReceivableApplicationId DESC;

            SET @Resultado = 1;
            SET @Mensaje = N'Duplicado idempotente. Recibo: ' + ISNULL(@NumRecibo, N'');
            COMMIT TRAN;
            RETURN;
        END

        DECLARE @Row INT = 1;
        DECLARE @TipoDoc NVARCHAR(20);
        DECLARE @NumDoc NVARCHAR(120);
        DECLARE @MontoAplicar DECIMAL(18,2);
        DECLARE @ReceivableId BIGINT;
        DECLARE @Pending DECIMAL(18,2);
        DECLARE @Total DECIMAL(18,2);
        DECLARE @Apply DECIMAL(18,2);
        DECLARE @AppliedTotal DECIMAL(18,2) = 0;

        WHILE EXISTS (SELECT 1 FROM @Docs WHERE RowNum = @Row)
        BEGIN
            SELECT
                @TipoDoc = TipoDoc,
                @NumDoc = NumDoc,
                @MontoAplicar = MontoAplicar
            FROM @Docs
            WHERE RowNum = @Row;

            SELECT TOP 1
                @ReceivableId = rd.ReceivableDocumentId,

                @Pending = rd.PendingAmount,
                @Total = rd.TotalAmount
            FROM ar.ReceivableDocument rd WITH (UPDLOCK, ROWLOCK)
            WHERE rd.CustomerId = @CustomerId
              AND rd.DocumentType = @TipoDoc
              AND rd.DocumentNumber = @NumDoc
              AND rd.Status <> N'VOIDED'
            ORDER BY rd.ReceivableDocumentId DESC;

            IF @ReceivableId IS NOT NULL AND @Pending > 0 AND @MontoAplicar > 0
            BEGIN
                SET @Apply = CASE WHEN @MontoAplicar > @Pending THEN @Pending ELSE @MontoAplicar END;

                INSERT INTO ar.ReceivableApplication (
                    ReceivableDocumentId,
                    ApplyDate,
                    AppliedAmount,
                    PaymentReference
                )
                VALUES (
                    @ReceivableId,
                    @FechaDate,
                    @Apply,
                    @RequestId + N':' + @NumRecibo
                );

                UPDATE ar.ReceivableDocument
                SET PendingAmount = CASE WHEN PendingAmount - @Apply < 0 THEN 0 ELSE PendingAmount - @Apply END,
                    PaidFlag = CASE WHEN PendingAmount - @Apply <= 0 THEN 1 ELSE 0 END,
                    Status = CASE
                        WHEN PendingAmount - @Apply <= 0 THEN N'PAID'
                        WHEN PendingAmount - @Apply < @Total THEN N'PARTIAL'
                        ELSE N'PENDING'
                    END,
                    UpdatedAt = SYSUTCDATETIME()
                WHERE ReceivableDocumentId = @ReceivableId;

                SET @AppliedTotal = @AppliedTotal + @Apply;
            END

            SET @ReceivableId = NULL;
            SET @Pending = NULL;
            SET @Total = NULL;
            SET @Apply = NULL;
            SET @Row += 1;
        END

        IF @AppliedTotal <= 0
        BEGIN
            ROLLBACK TRAN;
            SET @Resultado = -4;
            SET @Mensaje = N'No se aplic«¸ ning«ßn monto';
            RETURN;
        END

        UPDATE [master].Customer
        SET TotalBalance = (
                SELECT ISNULL(SUM(PendingAmount), 0)
                FROM ar.ReceivableDocument
                WHERE CustomerId = @CustomerId
                  AND Status <> N'VOIDED'
            ),
            UpdatedAt = SYSUTCDATETIME()
        WHERE CustomerId = @CustomerId;

        COMMIT TRAN;

        SET @Resultado = 1;
        SET @Mensaje = N'Cobro aplicado exitosamente. Recibo: ' + @NumRecibo;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRAN;
        SET @Resultado = -99;
        SET @Mensaje = ERROR_MESSAGE();
    END CATCH
END

GO
 
 
-- =============================================
-- STORED PROCEDURE: dbo.usp_CxP_AplicarPago
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

CREATE PROCEDURE dbo.usp_CxP_AplicarPago
    @RequestId       NVARCHAR(100),
    @CodProveedor    NVARCHAR(24),
    @Fecha           NVARCHAR(10),
    @MontoTotal      DECIMAL(18,2),
    @CodUsuario      NVARCHAR(40),
    @Observaciones   NVARCHAR(500) = N'',
    @DocumentosXml   NVARCHAR(MAX),
    @FormasPagoXml   NVARCHAR(MAX) = NULL,
    @NumPago         NVARCHAR(50) OUTPUT,
    @Resultado       INT OUTPUT,
    @Mensaje         NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @Resultado = 0;
    SET @Mensaje = N'';
    SET @NumPago = N'';

    DECLARE @FechaDate DATE = TRY_CONVERT(DATE, @Fecha);
    IF @FechaDate IS NULL
    BEGIN
        SET @Resultado = -91;
        SET @Mensaje = N'Fecha inv«≠lida: ' + ISNULL(@Fecha, N'NULL');
        RETURN;
    END

    DECLARE @SupplierId BIGINT;
    SELECT TOP 1 @SupplierId = s.SupplierId
    FROM [master].Supplier s
    WHERE s.SupplierCode = @CodProveedor
      AND s.IsDeleted = 0;

    IF @SupplierId IS NULL
    BEGIN
        SET @Resultado = -1;
        SET @Mensaje = N'Proveedor no encontrado: ' + @CodProveedor;
        RETURN;
    END

    DECLARE @DocsXml XML = TRY_CAST(@DocumentosXml AS XML);
    IF @DocsXml IS NULL
    BEGIN
        SET @Resultado = -2;
        SET @Mensaje = N'DocumentosXml inv«≠lido';
        RETURN;
    END

    DECLARE @Docs TABLE (
        RowNum INT IDENTITY(1,1) PRIMARY KEY,
        TipoDoc NVARCHAR(20) NOT NULL,
        NumDoc NVARCHAR(120) NOT NULL,
        MontoAplicar DECIMAL(18,2) NOT NULL
    );

    INSERT INTO @Docs (TipoDoc, NumDoc, MontoAplicar)
    SELECT
        UPPER(ISNULL(NULLIF(T.X.value('@tipoDoc', 'NVARCHAR(20)'), N''), N'COMPRA')),
        ISNULL(NULLIF(T.X.value('@numDoc', 'NVARCHAR(120)'), N''), N''),
        ISNULL(TRY_CONVERT(DECIMAL(18,2), NULLIF(T.X.value('@montoAplicar', 'NVARCHAR(40)'), N'')), 0)
    FROM @DocsXml.nodes('/documentos/row') T(X)
    WHERE ISNULL(NULLIF(T.X.value('@numDoc', 'NVARCHAR(120)'), N''), N'') <> N'';

    IF NOT EXISTS (SELECT 1 FROM @Docs)
    BEGIN
        SET @Resultado = -3;
        SET @Mensaje = N'No se recibieron documentos v«≠lidos para aplicar';
        RETURN;
    END

    SET @NumPago = N'PAG-' + REPLACE(REPLACE(REPLACE(CONVERT(NVARCHAR(19), SYSUTCDATETIME(), 120), N'-', N''), N' ', N''), N':', N'');

    BEGIN TRY
        BEGIN TRAN;

        IF EXISTS (
            SELECT 1
            FROM ap.PayableApplication pa
            INNER JOIN ap.PayableDocument pd ON pd.PayableDocumentId = pa.PayableDocumentId
            WHERE pd.SupplierId = @SupplierId
              AND pa.PaymentReference LIKE @RequestId + N':%'
        )
        BEGIN
            SELECT TOP 1 @NumPago = SUBSTRING(pa.PaymentReference, CHARINDEX(N':', pa.PaymentReference) + 1, 50)
            FROM ap.PayableApplication pa
            INNER JOIN ap.PayableDocument pd ON pd.PayableDocumentId = pa.PayableDocumentId
            WHERE pd.SupplierId = @SupplierId
              AND pa.PaymentReference LIKE @RequestId + N':%'
            ORDER BY pa.PayableApplicationId DESC;

            SET @Resultado = 1;
            SET @Mensaje = N'Duplicado idempotente. Pago: ' + ISNULL(@NumPago, N'');
            COMMIT TRAN;
            RETURN;
        END

        DECLARE @Row INT = 1;
        DECLARE @TipoDoc NVARCHAR(20);
        DECLARE @NumDoc NVARCHAR(120);
        DECLARE @MontoAplicar DECIMAL(18,2);
        DECLARE @PayableId BIGINT;
        DECLARE @Pending DECIMAL(18,2);
        DECLARE @Total DECIMAL(18,2);
        DECLARE @Apply DECIMAL(18,2);
        DECLARE @AppliedTotal DECIMAL(18,2) = 0;

        WHILE EXISTS (SELECT 1 FROM @Docs WHERE RowNum = @Row)
        BEGIN
            SELECT
                @TipoDoc = TipoDoc,
                @NumDoc = NumDoc,
                @MontoAplicar = MontoAplicar
            FROM @Docs
            WHERE RowNum = @Row;

            SELECT TOP 1
                @PayableId = pd.PayableDocumentId,
                @Pending = pd.PendingAmount,

                @Total = pd.TotalAmount
            FROM ap.PayableDocument pd WITH (UPDLOCK, ROWLOCK)
            WHERE pd.SupplierId = @SupplierId
              AND pd.DocumentType = @TipoDoc
              AND pd.DocumentNumber = @NumDoc
              AND pd.Status <> N'VOIDED'
            ORDER BY pd.PayableDocumentId DESC;

            IF @PayableId IS NOT NULL AND @Pending > 0 AND @MontoAplicar > 0
            BEGIN
                SET @Apply = CASE WHEN @MontoAplicar > @Pending THEN @Pending ELSE @MontoAplicar END;

                INSERT INTO ap.PayableApplication (
                    PayableDocumentId,
                    ApplyDate,
                    AppliedAmount,
                    PaymentReference
                )
                VALUES (
                    @PayableId,
                    @FechaDate,
                    @Apply,
                    @RequestId + N':' + @NumPago
                );

                UPDATE ap.PayableDocument
                SET PendingAmount = CASE WHEN PendingAmount - @Apply < 0 THEN 0 ELSE PendingAmount - @Apply END,
                    PaidFlag = CASE WHEN PendingAmount - @Apply <= 0 THEN 1 ELSE 0 END,
                    Status = CASE
                        WHEN PendingAmount - @Apply <= 0 THEN N'PAID'
                        WHEN PendingAmount - @Apply < @Total THEN N'PARTIAL'
                        ELSE N'PENDING'
                    END,
                    UpdatedAt = SYSUTCDATETIME()
                WHERE PayableDocumentId = @PayableId;

                SET @AppliedTotal = @AppliedTotal + @Apply;
            END

            SET @PayableId = NULL;
            SET @Pending = NULL;
            SET @Total = NULL;
            SET @Apply = NULL;
            SET @Row += 1;
        END

        IF @AppliedTotal <= 0
        BEGIN
            ROLLBACK TRAN;
            SET @Resultado = -4;
            SET @Mensaje = N'No se aplic«¸ ning«ßn monto';
            RETURN;
        END

        UPDATE [master].Supplier
        SET TotalBalance = (
                SELECT ISNULL(SUM(PendingAmount), 0)
                FROM ap.PayableDocument
                WHERE SupplierId = @SupplierId
                  AND Status <> N'VOIDED'
            ),
            UpdatedAt = SYSUTCDATETIME()
        WHERE SupplierId = @SupplierId;

        COMMIT TRAN;

        SET @Resultado = 1;
        SET @Mensaje = N'Pago aplicado exitosamente. Pago: ' + @NumPago;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRAN;
        SET @Resultado = -99;
        SET @Mensaje = ERROR_MESSAGE();
    END CATCH
END

GO
 
 
-- =============================================
-- STORED PROCEDURE: dbo.usp_Empresa_Get
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE usp_Empresa_Get
AS
BEGIN
    SET NOCOUNT ON;
    SELECT TOP 1
        c.LegalName    AS Empresa,
        c.FiscalId     AS RIF,
        cp.NitCode     AS Nit,
        cp.Phone       AS Telefono,
        cp.AddressLine AS Direccion,
        cp.AltFiscalId AS Rifs
    FROM cfg.Company c
    LEFT JOIN cfg.CompanyProfile cp ON cp.CompanyId = c.CompanyId
    WHERE c.IsDeleted = 0
    ORDER BY c.CompanyId;
END

GO
 
 
-- =============================================
-- STORED PROCEDURE: dbo.usp_Empresa_Update
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE usp_Empresa_Update
    @RowXml    NVARCHAR(MAX),
    @Resultado INT OUTPUT,
    @Mensaje   NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON; SET @Resultado = 0; SET @Mensaje = N'';
    DECLARE @x XML = CAST(@RowXml AS XML);
    BEGIN TRY
        DECLARE @CompanyId INT;
        SELECT TOP 1 @CompanyId = CompanyId FROM cfg.Company WHERE IsDeleted = 0 ORDER BY CompanyId;
        IF @CompanyId IS NULL BEGIN SET @Resultado = -1; SET @Mensaje = N'Empresa no encontrada'; RETURN; END

        -- Actualizar cfg.Company
        UPDATE cfg.Company SET
            LegalName  = COALESCE(NULLIF(@x.value('(/row/@Empresa)[1]','NVARCHAR(200)'),N''), LegalName),
            FiscalId   = COALESCE(NULLIF(@x.value('(/row/@RIF)[1]',    'NVARCHAR(30)'), N''), FiscalId),
            UpdatedAt  = SYSUTCDATETIME()
        WHERE CompanyId = @CompanyId;

        -- Actualizar o crear cfg.CompanyProfile
        IF EXISTS (SELECT 1 FROM cfg.CompanyProfile WHERE CompanyId = @CompanyId)
        BEGIN
            UPDATE cfg.CompanyProfile SET
                NitCode    = COALESCE(NULLIF(@x.value('(/row/@Nit)[1]',      'NVARCHAR(50)'), N''), NitCode),
                Phone      = COALESCE(NULLIF(@x.value('(/row/@Telefono)[1]', 'NVARCHAR(60)'), N''), Phone),
                AddressLine= COALESCE(NULLIF(@x.value('(/row/@Direccion)[1]','NVARCHAR(250)'),N''), AddressLine),
                AltFiscalId= COALESCE(NULLIF(@x.value('(/row/@Rifs)[1]',    'NVARCHAR(50)'), N''), AltFiscalId),
                UpdatedAt  = SYSUTCDATETIME()
            WHERE CompanyId = @CompanyId;
        END
        ELSE
        BEGIN
            INSERT INTO cfg.CompanyProfile (CompanyId, NitCode, Phone, AddressLine, AltFiscalId)
            VALUES (
                @CompanyId,
                NULLIF(@x.value('(/row/@Nit)[1]',      'NVARCHAR(50)'), N''),
                NULLIF(@x.value('(/row/@Telefono)[1]', 'NVARCHAR(60)'), N''),
                NULLIF(@x.value('(/row/@Direccion)[1]','NVARCHAR(250)'),N''),
                NULLIF(@x.value('(/row/@Rifs)[1]',     'NVARCHAR(50)'), N'')
            );
        END

        SET @Resultado = 1; SET @Mensaje = N'OK';
    END TRY BEGIN CATCH SET @Resultado = -99; SET @Mensaje = ERROR_MESSAGE(); END CATCH
END

GO
 
 
-- =============================================
-- STORED PROCEDURE: dbo.usp_Governance_CaptureSnapshot
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

  CREATE PROCEDURE dbo.usp_Governance_CaptureSnapshot
    @Notes NVARCHAR(500) = NULL
  AS
  BEGIN
    SET NOCOUNT ON;

    DECLARE
      @TotalTables INT = 0,
      @TablesWithoutPK INT = 0,
      @TablesWithoutCreatedAt INT = 0,
      @TablesWithoutUpdatedAt INT = 0,
      @TablesWithoutCreatedBy INT = 0,
      @TablesWithoutDateColumns INT = 0,
      @DuplicateNamePairs INT = 0,
      @SimilarityPairs INT = 0;

    SELECT
      @TotalTables = COUNT(1),
      @TablesWithoutPK = SUM(CASE WHEN has_pk = 0 THEN 1 ELSE 0 END),
      @TablesWithoutCreatedAt = SUM(CASE WHEN has_created_at = 0 THEN 1 ELSE 0 END),
      @TablesWithoutUpdatedAt = SUM(CASE WHEN has_updated_at = 0 THEN 1 ELSE 0 END),
      @TablesWithoutCreatedBy = SUM(CASE WHEN has_created_by = 0 THEN 1 ELSE 0 END),
      @TablesWithoutDateColumns = SUM(CASE WHEN date_column_count = 0 THEN 1 ELSE 0 END)
    FROM dbo.vw_Governance_AuditCoverage;

    SELECT @DuplicateNamePairs = COUNT(1) FROM dbo.vw_Governance_DuplicateNameCandidates;
    SELECT @SimilarityPairs = COUNT(1)
    FROM dbo.vw_Governance_TableSimilarityCandidates
    WHERE similarity_ratio >= 0.7000;

    INSERT INTO dbo.SchemaGovernanceSnapshot (
      TotalTables,
      TablesWithoutPK,
      TablesWithoutCreatedAt,
      TablesWithoutUpdatedAt,
      TablesWithoutCreatedBy,
      TablesWithoutDateColumns,
      DuplicateNameCandidatePairs,
      SimilarityCandidatePairs,
      Notes
    )
    VALUES (
      @TotalTables,
      @TablesWithoutPK,
      @TablesWithoutCreatedAt,
      @TablesWithoutUpdatedAt,
      @TablesWithoutCreatedBy,
      @TablesWithoutDateColumns,
      @DuplicateNamePairs,
      @SimilarityPairs,
      @Notes
    );

    SELECT TOP 1 *
    FROM dbo.SchemaGovernanceSnapshot
    ORDER BY Id DESC;
  END
  
GO
 
 
-- =============================================
-- STORED PROCEDURE: dbo.usp_Grupos_Delete
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE usp_Grupos_Delete
    @Codigo INT, @Resultado INT OUTPUT, @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON; SET @Resultado = 0; SET @Mensaje = N'';
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM master.ProductGroup WHERE GroupId = @Codigo AND IsDeleted = 0)
        BEGIN SET @Resultado = -1; SET @Mensaje = N'Grupo no encontrado'; RETURN; END
        UPDATE master.ProductGroup SET IsDeleted = 1, UpdatedAt = SYSUTCDATETIME() WHERE GroupId = @Codigo;
        SET @Resultado = 1; SET @Mensaje = N'OK';
    END TRY BEGIN CATCH SET @Resultado = -99; SET @Mensaje = ERROR_MESSAGE(); END CATCH
END

GO
 
 
-- =============================================
-- STORED PROCEDURE: dbo.usp_Grupos_GetByCodigo
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE usp_Grupos_GetByCodigo @Codigo INT
AS BEGIN SET NOCOUNT ON;
    SELECT GroupId AS Codigo, GroupName AS Descripcion,
           CAST(NULL AS NVARCHAR(10)) AS Co_Usuario,
           CAST(0.0 AS FLOAT) AS Porcentaje
    FROM master.ProductGroup WHERE GroupId = @Codigo AND IsDeleted = 0;
END

GO
 
 
-- =============================================
-- STORED PROCEDURE: dbo.usp_Grupos_Insert
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE usp_Grupos_Insert
    @RowXml NVARCHAR(MAX), @Resultado INT OUTPUT, @Mensaje NVARCHAR(500) OUTPUT, @NuevoCodigo INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON; SET @Resultado = 0; SET @Mensaje = N''; SET @NuevoCodigo = 0;
    DECLARE @x XML = CAST(@RowXml AS XML);
    DECLARE @Desc NVARCHAR(100) = NULLIF(@x.value('(/row/@Descripcion)[1]','NVARCHAR(100)'),N'');
    BEGIN TRY
        IF @Desc IS NULL BEGIN SET @Resultado = -1; SET @Mensaje = N'Descripcion requerida'; RETURN; END
        DECLARE @GCode NVARCHAR(20) = N'G' + FORMAT((SELECT ISNULL(MAX(GroupId),0)+1 FROM master.ProductGroup), N'000');
        INSERT INTO master.ProductGroup (GroupCode, GroupName) VALUES (@GCode, @Desc);
        SET @NuevoCodigo = CAST(SCOPE_IDENTITY() AS INT);
        SET @Resultado = 1; SET @Mensaje = N'OK';
    END TRY BEGIN CATCH SET @Resultado = -99; SET @Mensaje = ERROR_MESSAGE(); END CATCH
END

GO
 
 
-- =============================================
-- STORED PROCEDURE: dbo.usp_Grupos_List
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE usp_Grupos_List
    @Search     NVARCHAR(100) = NULL,
    @Page       INT = 1,
    @Limit      INT = 50,
    @TotalCount INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Offset INT = (ISNULL(NULLIF(@Page,0),1) - 1) * ISNULL(NULLIF(@Limit,0),50);
    IF @Offset < 0 SET @Offset = 0; IF @Limit < 1 SET @Limit = 50; IF @Limit > 500 SET @Limit = 500;
    DECLARE @S NVARCHAR(100) = CASE WHEN @Search IS NOT NULL AND LTRIM(RTRIM(@Search)) <> N'' THEN N'%' + @Search + N'%' ELSE NULL END;
    SELECT @TotalCount = COUNT(1) FROM master.ProductGroup
    WHERE IsDeleted = 0 AND (@S IS NULL OR GroupName LIKE @S OR CAST(GroupId AS NVARCHAR(20)) LIKE @S);
    SELECT GroupId AS Codigo, GroupName AS Descripcion,
           CAST(NULL AS NVARCHAR(10)) AS Co_Usuario,
           CAST(0.0 AS FLOAT) AS Porcentaje
    FROM master.ProductGroup
    WHERE IsDeleted = 0 AND (@S IS NULL OR GroupName LIKE @S OR CAST(GroupId AS NVARCHAR(20)) LIKE @S)
    ORDER BY GroupId OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;
END

GO
 
 
-- =============================================
-- STORED PROCEDURE: dbo.usp_Grupos_Update
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE usp_Grupos_Update
    @Codigo INT, @RowXml NVARCHAR(MAX), @Resultado INT OUTPUT, @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON; SET @Resultado = 0; SET @Mensaje = N'';
    DECLARE @x XML = CAST(@RowXml AS XML);
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM master.ProductGroup WHERE GroupId = @Codigo AND IsDeleted = 0)
        BEGIN SET @Resultado = -1; SET @Mensaje = N'Grupo no encontrado'; RETURN; END
        UPDATE master.ProductGroup SET
            GroupName = COALESCE(NULLIF(@x.value('(/row/@Descripcion)[1]','NVARCHAR(100)'),N''), GroupName),
            UpdatedAt = SYSUTCDATETIME()
        WHERE GroupId = @Codigo;
        SET @Resultado = 1; SET @Mensaje = N'OK';
    END TRY BEGIN CATCH SET @Resultado = -99; SET @Mensaje = ERROR_MESSAGE(); END CATCH
END

GO
 
 
-- =============================================
-- STORED PROCEDURE: dbo.usp_Lineas_Delete
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE usp_Lineas_Delete
    @Codigo INT, @Resultado INT OUTPUT, @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON; SET @Resultado = 0; SET @Mensaje = N'';
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM master.ProductLine WHERE LineId = @Codigo AND IsDeleted = 0)
        BEGIN SET @Resultado = -1; SET @Mensaje = N'Linea no encontrada'; RETURN; END
        UPDATE master.ProductLine SET IsDeleted = 1, UpdatedAt = SYSUTCDATETIME() WHERE LineId = @Codigo;
        SET @Resultado = 1; SET @Mensaje = N'OK';
    END TRY BEGIN CATCH SET @Resultado = -99; SET @Mensaje = ERROR_MESSAGE(); END CATCH
END

GO
 
 
-- =============================================
-- STORED PROCEDURE: dbo.usp_Lineas_GetByCodigo
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE usp_Lineas_GetByCodigo @Codigo INT
AS BEGIN SET NOCOUNT ON;
    SELECT LineId AS CODIGO, LineName AS DESCRIPCION FROM master.ProductLine WHERE LineId = @Codigo AND IsDeleted = 0;
END

GO
 
 
-- =============================================
-- STORED PROCEDURE: dbo.usp_Lineas_Insert
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE usp_Lineas_Insert
    @RowXml NVARCHAR(MAX), @Resultado INT OUTPUT, @Mensaje NVARCHAR(500) OUTPUT, @NuevoCodigo INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON; SET @Resultado = 0; SET @Mensaje = N''; SET @NuevoCodigo = 0;
    DECLARE @x XML = CAST(@RowXml AS XML);
    DECLARE @Desc NVARCHAR(100) = NULLIF(@x.value('(/row/@DESCRIPCION)[1]','NVARCHAR(100)'),N'');
    BEGIN TRY
        IF @Desc IS NULL BEGIN SET @Resultado = -1; SET @Mensaje = N'DESCRIPCION requerida'; RETURN; END
        -- LineCode autogenerado como secuencial formateado
        DECLARE @NextCode NVARCHAR(20) = N'L' + FORMAT((SELECT ISNULL(MAX(LineId),0)+1 FROM master.ProductLine), N'000');
        INSERT INTO master.ProductLine (LineCode, LineName) VALUES (@NextCode, @Desc);
        SET @NuevoCodigo = CAST(SCOPE_IDENTITY() AS INT);
        SET @Resultado = 1; SET @Mensaje = N'OK';
    END TRY BEGIN CATCH SET @Resultado = -99; SET @Mensaje = ERROR_MESSAGE(); END CATCH
END

GO
 
 
-- =============================================
-- STORED PROCEDURE: dbo.usp_Lineas_List
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE usp_Lineas_List
    @Search     NVARCHAR(100) = NULL,
    @Page       INT = 1,
    @Limit      INT = 50,
    @TotalCount INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Offset INT = (ISNULL(NULLIF(@Page,0),1) - 1) * ISNULL(NULLIF(@Limit,0),50);
    IF @Offset < 0 SET @Offset = 0; IF @Limit < 1 SET @Limit = 50; IF @Limit > 500 SET @Limit = 500;
    DECLARE @S NVARCHAR(100) = CASE WHEN @Search IS NOT NULL AND LTRIM(RTRIM(@Search)) <> N'' THEN N'%' + @Search + N'%' ELSE NULL END;
    SELECT @TotalCount = COUNT(1) FROM master.ProductLine
    WHERE IsDeleted = 0 AND (@S IS NULL OR LineName LIKE @S OR CAST(LineId AS NVARCHAR(20)) LIKE @S);
    SELECT LineId AS CODIGO, LineName AS DESCRIPCION
    FROM master.ProductLine
    WHERE IsDeleted = 0 AND (@S IS NULL OR LineName LIKE @S OR CAST(LineId AS NVARCHAR(20)) LIKE @S)
    ORDER BY LineId OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;
END

GO
 
 
-- =============================================
-- STORED PROCEDURE: dbo.usp_Lineas_Update
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE usp_Lineas_Update
    @Codigo INT, @RowXml NVARCHAR(MAX), @Resultado INT OUTPUT, @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON; SET @Resultado = 0; SET @Mensaje = N'';
    DECLARE @x XML = CAST(@RowXml AS XML);
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM master.ProductLine WHERE LineId = @Codigo AND IsDeleted = 0)
        BEGIN SET @Resultado = -1; SET @Mensaje = N'Linea no encontrada'; RETURN; END
        UPDATE master.ProductLine SET
            LineName  = COALESCE(NULLIF(@x.value('(/row/@DESCRIPCION)[1]','NVARCHAR(100)'),N''), LineName),
            UpdatedAt = SYSUTCDATETIME()
        WHERE LineId = @Codigo;
        SET @Resultado = 1; SET @Mensaje = N'OK';
    END TRY BEGIN CATCH SET @Resultado = -99; SET @Mensaje = ERROR_MESSAGE(); END CATCH
END

GO
 
 
-- =============================================
-- STORED PROCEDURE: dbo.usp_Marcas_Delete
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE usp_Marcas_Delete
    @Codigo INT, @Resultado INT OUTPUT, @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON; SET @Resultado = 0; SET @Mensaje = N'';
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM master.Brand WHERE BrandId = @Codigo AND IsDeleted = 0)
        BEGIN SET @Resultado = -1; SET @Mensaje = N'Marca no encontrada'; RETURN; END
        UPDATE master.Brand SET IsDeleted = 1, UpdatedAt = SYSUTCDATETIME() WHERE BrandId = @Codigo;
        SET @Resultado = 1; SET @Mensaje = N'OK';
    END TRY BEGIN CATCH SET @Resultado = -99; SET @Mensaje = ERROR_MESSAGE(); END CATCH
END

GO
 
 
-- =============================================
-- STORED PROCEDURE: dbo.usp_Marcas_GetByCodigo
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE usp_Marcas_GetByCodigo @Codigo INT
AS BEGIN SET NOCOUNT ON;
    SELECT BrandId AS Codigo, BrandName AS Descripcion FROM master.Brand WHERE BrandId = @Codigo AND IsDeleted = 0;
END

GO
 
 
-- =============================================
-- STORED PROCEDURE: dbo.usp_Marcas_Insert
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE usp_Marcas_Insert
    @RowXml      NVARCHAR(MAX),
    @Resultado   INT OUTPUT,
    @Mensaje     NVARCHAR(500) OUTPUT,
    @NuevoCodigo INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    SET @Resultado = 0; SET @Mensaje = N''; SET @NuevoCodigo = 0;
    DECLARE @x XML = CAST(@RowXml AS XML);
    DECLARE @Desc NVARCHAR(100) = NULLIF(@x.value('(/row/@Descripcion)[1]','NVARCHAR(100)'),N'');
    BEGIN TRY
        IF @Desc IS NULL BEGIN SET @Resultado = -1; SET @Mensaje = N'Descripcion requerida'; RETURN; END
        INSERT INTO master.Brand (BrandName) VALUES (@Desc);
        SET @NuevoCodigo = CAST(SCOPE_IDENTITY() AS INT);
        SET @Resultado = 1; SET @Mensaje = N'OK';
    END TRY BEGIN CATCH SET @Resultado = -99; SET @Mensaje = ERROR_MESSAGE(); END CATCH
END

GO
 
 
-- =============================================
-- STORED PROCEDURE: dbo.usp_Marcas_List
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE usp_Marcas_List
    @Search     NVARCHAR(100) = NULL,
    @Page       INT = 1,
    @Limit      INT = 50,
    @TotalCount INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Offset INT = (ISNULL(NULLIF(@Page,0),1) - 1) * ISNULL(NULLIF(@Limit,0),50);
    IF @Offset < 0 SET @Offset = 0; IF @Limit < 1 SET @Limit = 50; IF @Limit > 500 SET @Limit = 500;
    DECLARE @S NVARCHAR(100) = CASE WHEN @Search IS NOT NULL AND LTRIM(RTRIM(@Search)) <> N'' THEN N'%' + @Search + N'%' ELSE NULL END;
    SELECT @TotalCount = COUNT(1) FROM master.Brand
    WHERE IsDeleted = 0 AND (@S IS NULL OR BrandName LIKE @S);
    SELECT BrandId AS Codigo, BrandName AS Descripcion
    FROM master.Brand
    WHERE IsDeleted = 0 AND (@S IS NULL OR BrandName LIKE @S)
    ORDER BY BrandId OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;
END

GO
 
 
-- =============================================
-- STORED PROCEDURE: dbo.usp_Marcas_Update
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE usp_Marcas_Update
    @Codigo INT, @RowXml NVARCHAR(MAX), @Resultado INT OUTPUT, @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON; SET @Resultado = 0; SET @Mensaje = N'';
    DECLARE @x XML = CAST(@RowXml AS XML);
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM master.Brand WHERE BrandId = @Codigo AND IsDeleted = 0)
        BEGIN SET @Resultado = -1; SET @Mensaje = N'Marca no encontrada'; RETURN; END
        UPDATE master.Brand SET
            BrandName = COALESCE(NULLIF(@x.value('(/row/@Descripcion)[1]','NVARCHAR(100)'),N''), BrandName),
            UpdatedAt = SYSUTCDATETIME()
        WHERE BrandId = @Codigo;
        SET @Resultado = 1; SET @Mensaje = N'OK';
    END TRY BEGIN CATCH SET @Resultado = -99; SET @Mensaje = ERROR_MESSAGE(); END CATCH
END

GO
 
 
-- =============================================
-- STORED PROCEDURE: dbo.usp_Tipos_Delete
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE usp_Tipos_Delete
    @Codigo INT, @Resultado INT OUTPUT, @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON; SET @Resultado = 0; SET @Mensaje = N'';
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM master.ProductType WHERE TypeId = @Codigo AND IsDeleted = 0)
        BEGIN SET @Resultado = -1; SET @Mensaje = N'Tipo no encontrado'; RETURN; END
        UPDATE master.ProductType SET IsDeleted = 1, UpdatedAt = SYSUTCDATETIME() WHERE TypeId = @Codigo;
        SET @Resultado = 1; SET @Mensaje = N'OK';
    END TRY BEGIN CATCH SET @Resultado = -99; SET @Mensaje = ERROR_MESSAGE(); END CATCH
END

GO
 
 
-- =============================================
-- STORED PROCEDURE: dbo.usp_Tipos_GetByCodigo
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE usp_Tipos_GetByCodigo @Codigo INT
AS BEGIN SET NOCOUNT ON;
    SELECT TypeId AS Codigo, TypeName AS Nombre, CategoryCode AS Categoria,
           CAST(NULL AS NVARCHAR(10)) AS Co_Usuario
    FROM master.ProductType WHERE TypeId = @Codigo AND IsDeleted = 0;
END

GO
 
 
-- =============================================
-- STORED PROCEDURE: dbo.usp_Tipos_Insert
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE usp_Tipos_Insert
    @RowXml NVARCHAR(MAX), @Resultado INT OUTPUT, @Mensaje NVARCHAR(500) OUTPUT, @NuevoCodigo INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON; SET @Resultado = 0; SET @Mensaje = N''; SET @NuevoCodigo = 0;
    DECLARE @x XML = CAST(@RowXml AS XML);
    DECLARE @Nombre   NVARCHAR(100) = NULLIF(@x.value('(/row/@Nombre)[1]',   'NVARCHAR(100)'),N'');
    DECLARE @Categoria NVARCHAR(50) = NULLIF(@x.value('(/row/@Categoria)[1]','NVARCHAR(50)'), N'');
    BEGIN TRY
        IF @Nombre IS NULL BEGIN SET @Resultado = -1; SET @Mensaje = N'Nombre requerido'; RETURN; END
        DECLARE @TCode NVARCHAR(20) = N'T' + FORMAT((SELECT ISNULL(MAX(TypeId),0)+1 FROM master.ProductType), N'000');
        INSERT INTO master.ProductType (TypeCode, TypeName, CategoryCode) VALUES (@TCode, @Nombre, @Categoria);
        SET @NuevoCodigo = CAST(SCOPE_IDENTITY() AS INT);
        SET @Resultado = 1; SET @Mensaje = N'OK';
    END TRY BEGIN CATCH SET @Resultado = -99; SET @Mensaje = ERROR_MESSAGE(); END CATCH
END

GO
 
 
-- =============================================
-- STORED PROCEDURE: dbo.usp_Tipos_List
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE usp_Tipos_List
    @Search     NVARCHAR(100) = NULL,
    @Page       INT = 1,
    @Limit      INT = 50,
    @TotalCount INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Offset INT = (ISNULL(NULLIF(@Page,0),1) - 1) * ISNULL(NULLIF(@Limit,0),50);
    IF @Offset < 0 SET @Offset = 0; IF @Limit < 1 SET @Limit = 50; IF @Limit > 500 SET @Limit = 500;
    DECLARE @S NVARCHAR(100) = CASE WHEN @Search IS NOT NULL AND LTRIM(RTRIM(@Search)) <> N'' THEN N'%' + @Search + N'%' ELSE NULL END;
    SELECT @TotalCount = COUNT(1) FROM master.ProductType
    WHERE IsDeleted = 0 AND (@S IS NULL OR TypeName LIKE @S OR CategoryCode LIKE @S OR CAST(TypeId AS NVARCHAR(20)) LIKE @S);
    SELECT TypeId AS Codigo, TypeName AS Nombre, CategoryCode AS Categoria,
           CAST(NULL AS NVARCHAR(10)) AS Co_Usuario
    FROM master.ProductType
    WHERE IsDeleted = 0 AND (@S IS NULL OR TypeName LIKE @S OR CategoryCode LIKE @S OR CAST(TypeId AS NVARCHAR(20)) LIKE @S)
    ORDER BY TypeId OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;
END

GO
 
 
-- =============================================
-- STORED PROCEDURE: dbo.usp_Tipos_Update
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE usp_Tipos_Update
    @Codigo INT, @RowXml NVARCHAR(MAX), @Resultado INT OUTPUT, @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON; SET @Resultado = 0; SET @Mensaje = N'';
    DECLARE @x XML = CAST(@RowXml AS XML);
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM master.ProductType WHERE TypeId = @Codigo AND IsDeleted = 0)
        BEGIN SET @Resultado = -1; SET @Mensaje = N'Tipo no encontrado'; RETURN; END
        UPDATE master.ProductType SET
            TypeName     = COALESCE(NULLIF(@x.value('(/row/@Nombre)[1]',   'NVARCHAR(100)'),N''), TypeName),
            CategoryCode = COALESCE(NULLIF(@x.value('(/row/@Categoria)[1]','NVARCHAR(50)'), N''), CategoryCode),
            UpdatedAt    = SYSUTCDATETIME()
        WHERE TypeId = @Codigo;
        SET @Resultado = 1; SET @Mensaje = N'OK';
    END TRY BEGIN CATCH SET @Resultado = -99; SET @Mensaje = ERROR_MESSAGE(); END CATCH
END

GO
 
 
-- =============================================
-- STORED PROCEDURE: dbo.usp_Unidades_Delete
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE usp_Unidades_Delete
    @Id INT, @Resultado INT OUTPUT, @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON; SET @Resultado = 0; SET @Mensaje = N'';
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM master.UnitOfMeasure WHERE UnitId = @Id AND IsDeleted = 0)
        BEGIN SET @Resultado = -1; SET @Mensaje = N'Unidad no encontrada'; RETURN; END
        UPDATE master.UnitOfMeasure SET IsDeleted = 1, UpdatedAt = SYSUTCDATETIME() WHERE UnitId = @Id;
        SET @Resultado = 1; SET @Mensaje = N'OK';
    END TRY BEGIN CATCH SET @Resultado = -99; SET @Mensaje = ERROR_MESSAGE(); END CATCH
END

GO
 
 
-- =============================================
-- STORED PROCEDURE: dbo.usp_Unidades_GetById
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE usp_Unidades_GetById @Id INT
AS BEGIN SET NOCOUNT ON;
    SELECT UnitId AS Id, UnitCode AS Unidad, ConversionFactor AS Cantidad
    FROM master.UnitOfMeasure WHERE UnitId = @Id AND IsDeleted = 0;
END

GO
 
 
-- =============================================
-- STORED PROCEDURE: dbo.usp_Unidades_Insert
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE usp_Unidades_Insert
    @RowXml NVARCHAR(MAX), @Resultado INT OUTPUT, @Mensaje NVARCHAR(500) OUTPUT, @NuevoId INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON; SET @Resultado = 0; SET @Mensaje = N''; SET @NuevoId = 0;
    DECLARE @x XML = CAST(@RowXml AS XML);
    DECLARE @Unidad   NVARCHAR(20) = NULLIF(@x.value('(/row/@Unidad)[1]',  'NVARCHAR(20)'),N'');
    DECLARE @CantStr  NVARCHAR(50) = NULLIF(@x.value('(/row/@Cantidad)[1]','NVARCHAR(50)'),N'');
    DECLARE @Cantidad DECIMAL(18,4) = CASE WHEN ISNUMERIC(@CantStr) = 1 THEN CAST(@CantStr AS DECIMAL(18,4)) ELSE NULL END;
    BEGIN TRY
        IF @Unidad IS NULL BEGIN SET @Resultado = -1; SET @Mensaje = N'Unidad requerida'; RETURN; END
        INSERT INTO master.UnitOfMeasure (UnitCode, Description, ConversionFactor)
        VALUES (@Unidad, @Unidad, @Cantidad);
        SET @NuevoId = CAST(SCOPE_IDENTITY() AS INT);
        SET @Resultado = 1; SET @Mensaje = N'OK';
    END TRY BEGIN CATCH SET @Resultado = -99; SET @Mensaje = ERROR_MESSAGE(); END CATCH
END

GO
 
 
-- =============================================
-- STORED PROCEDURE: dbo.usp_Unidades_List
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE usp_Unidades_List
    @Search     NVARCHAR(100) = NULL,
    @Page       INT = 1,
    @Limit      INT = 50,
    @TotalCount INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Offset INT = (ISNULL(NULLIF(@Page,0),1) - 1) * ISNULL(NULLIF(@Limit,0),50);
    IF @Offset < 0 SET @Offset = 0; IF @Limit < 1 SET @Limit = 50; IF @Limit > 500 SET @Limit = 500;
    DECLARE @S NVARCHAR(100) = CASE WHEN @Search IS NOT NULL AND LTRIM(RTRIM(@Search)) <> N'' THEN N'%' + @Search + N'%' ELSE NULL END;
    SELECT @TotalCount = COUNT(1) FROM master.UnitOfMeasure
    WHERE IsDeleted = 0 AND (@S IS NULL OR UnitCode LIKE @S OR Description LIKE @S);
    SELECT UnitId AS Id, UnitCode AS Unidad, ConversionFactor AS Cantidad
    FROM master.UnitOfMeasure
    WHERE IsDeleted = 0 AND (@S IS NULL OR UnitCode LIKE @S OR Description LIKE @S)
    ORDER BY UnitId OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;
END

GO
 
 
-- =============================================
-- STORED PROCEDURE: dbo.usp_Unidades_Update
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE usp_Unidades_Update
    @Id INT, @RowXml NVARCHAR(MAX), @Resultado INT OUTPUT, @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON; SET @Resultado = 0; SET @Mensaje = N'';
    DECLARE @x XML = CAST(@RowXml AS XML);
    DECLARE @CantStr  NVARCHAR(50) = NULLIF(@x.value('(/row/@Cantidad)[1]','NVARCHAR(50)'),N'');
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM master.UnitOfMeasure WHERE UnitId = @Id AND IsDeleted = 0)
        BEGIN SET @Resultado = -1; SET @Mensaje = N'Unidad no encontrada'; RETURN; END
        UPDATE master.UnitOfMeasure SET
            UnitCode         = COALESCE(NULLIF(@x.value('(/row/@Unidad)[1]','NVARCHAR(20)'),N''), UnitCode),
            Description      = COALESCE(NULLIF(@x.value('(/row/@Unidad)[1]','NVARCHAR(20)'),N''), Description),
            ConversionFactor = CASE WHEN @CantStr IS NULL THEN ConversionFactor
                                    WHEN ISNUMERIC(@CantStr) = 1 THEN CAST(@CantStr AS DECIMAL(18,4))
                                    ELSE ConversionFactor END,
            UpdatedAt        = SYSUTCDATETIME()
        WHERE UnitId = @Id;
        SET @Resultado = 1; SET @Mensaje = N'OK';
    END TRY BEGIN CATCH SET @Resultado = -99; SET @Mensaje = ERROR_MESSAGE(); END CATCH
END

GO
 
 
-- =============================================
-- STORED PROCEDURE: dbo.usp_Usuarios_Delete
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE usp_Usuarios_Delete @CodUsuario NVARCHAR(10), @Resultado INT OUTPUT, @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON; SET @Resultado = 0; SET @Mensaje = N'';
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM [dbo].[Usuarios] WHERE Cod_Usuario = @CodUsuario) BEGIN SET @Resultado = -1; SET @Mensaje = N'Usuario no encontrado'; RETURN; END
        DELETE FROM [dbo].[Usuarios] WHERE Cod_Usuario = @CodUsuario; SET @Resultado = 1; SET @Mensaje = N'OK';
    END TRY BEGIN CATCH SET @Resultado = -99; SET @Mensaje = ERROR_MESSAGE(); END CATCH
END

GO
 
 
-- =============================================
-- STORED PROCEDURE: dbo.usp_Usuarios_GetByCodigo
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE usp_Usuarios_GetByCodigo @CodUsuario NVARCHAR(10) AS
BEGIN SET NOCOUNT ON; SELECT * FROM [dbo].[Usuarios] WHERE Cod_Usuario = @CodUsuario; END

GO
 
 
-- =============================================
-- STORED PROCEDURE: dbo.usp_Usuarios_Insert
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE usp_Usuarios_Insert @RowXml NVARCHAR(MAX), @Resultado INT OUTPUT, @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON; SET @Resultado = 0; SET @Mensaje = N'';
    DECLARE @xml XML = CAST(@RowXml AS XML);
    BEGIN TRY
        IF EXISTS (SELECT 1 FROM [dbo].[Usuarios] WHERE Cod_Usuario = @xml.value('(/row/@Cod_Usuario)[1]', 'NVARCHAR(10)'))
        BEGIN SET @Resultado = -1; SET @Mensaje = N'Usuario ya existe'; RETURN; END
        INSERT INTO [dbo].[Usuarios] (Cod_Usuario, Password, Nombre, Tipo, Updates, Addnews, Deletes, Creador, Cambiar, PrecioMinimo, Credito)
        SELECT NULLIF(r.value('@Cod_Usuario', 'NVARCHAR(10)'), N''),
               NULLIF(r.value('@Password', 'NVARCHAR(50)'), N''),
               NULLIF(r.value('@Nombre', 'NVARCHAR(100)'), N''),
               NULLIF(r.value('@Tipo', 'NVARCHAR(50)'), N''),
               ISNULL(r.value('@Updates', 'BIT'), 0),
               ISNULL(r.value('@Addnews', 'BIT'), 0),
               ISNULL(r.value('@Deletes', 'BIT'), 0),
               ISNULL(r.value('@Creador', 'BIT'), 0),
               ISNULL(r.value('@Cambiar', 'BIT'), 0),
               ISNULL(r.value('@PrecioMinimo', 'BIT'), 0),
               ISNULL(r.value('@Credito', 'BIT'), 0)
        FROM @xml.nodes('/row') T(r);
        SET @Resultado = 1; SET @Mensaje = N'OK';
    END TRY BEGIN CATCH SET @Resultado = -99; SET @Mensaje = ERROR_MESSAGE(); END CATCH
END

GO
 
 
-- =============================================
-- STORED PROCEDURE: dbo.usp_Usuarios_List
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE usp_Usuarios_List
    @Search NVARCHAR(100) = NULL,
    @Tipo NVARCHAR(50) = NULL,
    @Page INT = 1,
    @Limit INT = 50,
    @TotalCount INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Offset INT = (ISNULL(NULLIF(@Page, 0), 1) - 1) * ISNULL(NULLIF(@Limit, 0), 50);
    IF @Offset < 0 SET @Offset = 0; IF @Limit < 1 SET @Limit = 50; IF @Limit > 500 SET @Limit = 500;
    DECLARE @Where NVARCHAR(MAX) = N''; DECLARE @Sql NVARCHAR(MAX);
    DECLARE @Params NVARCHAR(600) = N'@Search NVARCHAR(100), @Tipo NVARCHAR(50), @Offset INT, @Limit INT, @TotalCount INT OUTPUT';
    IF @Search IS NOT NULL AND LTRIM(RTRIM(@Search)) <> N''
        SET @Where = @Where + N' AND (Cod_Usuario LIKE @Search OR Nombre LIKE @Search)';
    IF @Tipo IS NOT NULL AND LTRIM(RTRIM(@Tipo)) <> N''
        SET @Where = @Where + N' AND Tipo = @Tipo';
    IF LEN(@Where) > 0 SET @Where = N' WHERE ' + STUFF(@Where, 1, 5, N'');
    DECLARE @SearchParam NVARCHAR(100) = NULL;
    IF @Search IS NOT NULL AND LTRIM(RTRIM(@Search)) <> N''
        SET @SearchParam = N'%' + @Search + N'%';
    SET @Sql = N'SELECT @TotalCount = COUNT(1) FROM [dbo].[Usuarios]' + @Where + N';
    SELECT * FROM [dbo].[Usuarios]' + @Where + N' ORDER BY Cod_Usuario OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;';
    EXEC sp_executesql @Sql, @Params, @Search = @SearchParam, @Tipo = @Tipo, @Offset = @Offset, @Limit = @Limit, @TotalCount = @TotalCount OUTPUT;
END

GO
 
 
-- =============================================
-- STORED PROCEDURE: dbo.usp_Usuarios_Update
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE usp_Usuarios_Update @CodUsuario NVARCHAR(10), @RowXml NVARCHAR(MAX), @Resultado INT OUTPUT, @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON; SET @Resultado = 0; SET @Mensaje = N'';
    DECLARE @xml XML = CAST(@RowXml AS XML);
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM [dbo].[Usuarios] WHERE Cod_Usuario = @CodUsuario) BEGIN SET @Resultado = -1; SET @Mensaje = N'Usuario no encontrado'; RETURN; END
        UPDATE u SET Password = COALESCE(NULLIF(r.value('@Password', 'NVARCHAR(255)'), N''), u.Password),
                     Nombre = COALESCE(NULLIF(r.value('@Nombre', 'NVARCHAR(50)'), N''), u.Nombre),
                     Tipo = COALESCE(NULLIF(r.value('@Tipo', 'NVARCHAR(10)'), N''), u.Tipo),
                     IsAdmin = ISNULL(r.value('@IsAdmin', 'BIT'), u.IsAdmin),
                     Updates = ISNULL(r.value('@Updates', 'BIT'), u.Updates),
                     Addnews = ISNULL(r.value('@Addnews', 'BIT'), u.Addnews),
                     Deletes = ISNULL(r.value('@Deletes', 'BIT'), u.Deletes),
                     Creador = ISNULL(r.value('@Creador', 'BIT'), u.Creador),
                     Cambiar = ISNULL(r.value('@Cambiar', 'BIT'), u.Cambiar),
                     PrecioMinimo = ISNULL(r.value('@PrecioMinimo', 'BIT'), u.PrecioMinimo),
                     Credito = ISNULL(r.value('@Credito', 'BIT'), u.Credito)
        FROM [dbo].[Usuarios] u CROSS JOIN @xml.nodes('/row') T(r) WHERE u.Cod_Usuario = @CodUsuario;
        SET @Resultado = 1; SET @Mensaje = N'OK';
    END TRY BEGIN CATCH SET @Resultado = -99; SET @Mensaje = ERROR_MESSAGE(); END CATCH
END

GO
 
 
-- =============================================
-- STORED PROCEDURE: dbo.usp_Vendedores_Delete
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE usp_Vendedores_Delete
    @Codigo NVARCHAR(10), @Resultado INT OUTPUT, @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON; SET @Resultado = 0; SET @Mensaje = N'';
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM master.Seller WHERE SellerCode = @Codigo AND IsDeleted = 0)
        BEGIN SET @Resultado = -1; SET @Mensaje = N'Vendedor no encontrado'; RETURN; END
        UPDATE master.Seller SET IsDeleted = 1, UpdatedAt = SYSUTCDATETIME() WHERE SellerCode = @Codigo;
        SET @Resultado = 1; SET @Mensaje = N'OK';
    END TRY BEGIN CATCH SET @Resultado = -99; SET @Mensaje = ERROR_MESSAGE(); END CATCH
END

GO
 
 
-- =============================================
-- STORED PROCEDURE: dbo.usp_Vendedores_GetByCodigo
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE usp_Vendedores_GetByCodigo @Codigo NVARCHAR(10)
AS BEGIN SET NOCOUNT ON;
    SELECT SellerCode AS Codigo, SellerName AS Nombre, CAST(Commission AS FLOAT) AS Comision,
           Address AS Direccion, Phone AS Telefonos, Email, IsActive AS Status, SellerType AS Tipo,
           CAST(NULL AS NVARCHAR(50)) AS clave
    FROM master.Seller WHERE SellerCode = @Codigo AND IsDeleted = 0;
END

GO
 
 
-- =============================================
-- STORED PROCEDURE: dbo.usp_Vendedores_Insert
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE usp_Vendedores_Insert
    @RowXml NVARCHAR(MAX), @Resultado INT OUTPUT, @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON; SET @Resultado = 0; SET @Mensaje = N'';
    DECLARE @x XML = CAST(@RowXml AS XML);
    DECLARE @Codigo   NVARCHAR(10) = NULLIF(@x.value('(/row/@Codigo)[1]',   'NVARCHAR(10)'), N'');
    DECLARE @Nombre   NVARCHAR(120)= NULLIF(@x.value('(/row/@Nombre)[1]',   'NVARCHAR(120)'),N'');
    DECLARE @ComStr   NVARCHAR(50) = NULLIF(@x.value('(/row/@Comision)[1]', 'NVARCHAR(50)'), N'');
    DECLARE @Direccion NVARCHAR(250)= NULLIF(@x.value('(/row/@Direccion)[1]','NVARCHAR(250)'),N'');
    DECLARE @Telef    NVARCHAR(60) = NULLIF(@x.value('(/row/@Telefonos)[1]','NVARCHAR(60)'), N'');
    DECLARE @Email    NVARCHAR(150)= NULLIF(@x.value('(/row/@Email)[1]',    'NVARCHAR(150)'),N'');
    DECLARE @Status   BIT          = ISNULL(@x.value('(/row/@Status)[1]',   'BIT'),           1);
    DECLARE @Tipo     NVARCHAR(20) = ISNULL(NULLIF(@x.value('(/row/@Tipo)[1]','NVARCHAR(20)'),N''), N'INTERNO');
    DECLARE @Comision DECIMAL(5,2) = CASE WHEN ISNUMERIC(@ComStr) = 1 THEN CAST(@ComStr AS DECIMAL(5,2)) ELSE 0 END;
    BEGIN TRY
        IF @Codigo IS NULL BEGIN SET @Resultado = -1; SET @Mensaje = N'Codigo requerido'; RETURN; END
        IF EXISTS (SELECT 1 FROM master.Seller WHERE SellerCode = @Codigo AND IsDeleted = 0)
        BEGIN SET @Resultado = -1; SET @Mensaje = N'Vendedor ya existe'; RETURN; END
        INSERT INTO master.Seller (SellerCode, SellerName, Commission, Address, Phone, Email, IsActive, SellerType)
        VALUES (@Codigo, COALESCE(@Nombre, @Codigo), @Comision, @Direccion, @Telef, @Email, @Status, @Tipo);
        SET @Resultado = 1; SET @Mensaje = N'OK';
    END TRY BEGIN CATCH SET @Resultado = -99; SET @Mensaje = ERROR_MESSAGE(); END CATCH
END

GO
 
 
-- =============================================
-- STORED PROCEDURE: dbo.usp_Vendedores_List
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE usp_Vendedores_List
    @Search     NVARCHAR(100) = NULL,
    @Status     BIT  = NULL,
    @Tipo       NVARCHAR(50) = NULL,
    @Page       INT = 1,
    @Limit      INT = 50,
    @TotalCount INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Offset INT = (ISNULL(NULLIF(@Page,0),1) - 1) * ISNULL(NULLIF(@Limit,0),50);
    IF @Offset < 0 SET @Offset = 0; IF @Limit < 1 SET @Limit = 50; IF @Limit > 500 SET @Limit = 500;
    DECLARE @S NVARCHAR(100) = CASE WHEN @Search IS NOT NULL AND LTRIM(RTRIM(@Search)) <> N'' THEN N'%' + @Search + N'%' ELSE NULL END;
    SELECT @TotalCount = COUNT(1) FROM master.Seller
    WHERE IsDeleted = 0
      AND (@S IS NULL OR SellerCode LIKE @S OR SellerName LIKE @S OR Email LIKE @S)
      AND (@Status IS NULL OR IsActive = @Status)
      AND (@Tipo IS NULL OR SellerType = @Tipo);
    SELECT
        SellerCode AS Codigo,
        SellerName AS Nombre,
        CAST(Commission AS FLOAT) AS Comision,
        Address AS Direccion,
        Phone AS Telefonos,
        Email,
        IsActive AS Status,
        SellerType AS Tipo,
        CAST(NULL AS NVARCHAR(50)) AS clave,
        CAST(NULL AS FLOAT) AS Rango_ventas_Uno,
        CAST(NULL AS FLOAT) AS [Comision_ ventas_Uno],
        CAST(NULL AS FLOAT) AS Rango_ventas_dos,
        CAST(NULL AS FLOAT) AS [Comision_ ventas_dos],
        CAST(NULL AS FLOAT) AS Rango_ventas_tres,
        CAST(NULL AS FLOAT) AS [Comision_ ventas_tres],
        CAST(NULL AS FLOAT) AS Rango_ventas_Cuatro,
        CAST(NULL AS FLOAT) AS [Comision_ ventas_Cuatro]
    FROM master.Seller
    WHERE IsDeleted = 0
      AND (@S IS NULL OR SellerCode LIKE @S OR SellerName LIKE @S OR Email LIKE @S)
      AND (@Status IS NULL OR IsActive = @Status)
      AND (@Tipo IS NULL OR SellerType = @Tipo)
    ORDER BY SellerCode OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;
END

GO
 
 
-- =============================================
-- STORED PROCEDURE: dbo.usp_Vendedores_Update
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE usp_Vendedores_Update
    @Codigo NVARCHAR(10), @RowXml NVARCHAR(MAX), @Resultado INT OUTPUT, @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON; SET @Resultado = 0; SET @Mensaje = N'';
    DECLARE @x XML = CAST(@RowXml AS XML);
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM master.Seller WHERE SellerCode = @Codigo AND IsDeleted = 0)
        BEGIN SET @Resultado = -1; SET @Mensaje = N'Vendedor no encontrado'; RETURN; END
        DECLARE @ComStr NVARCHAR(50) = NULLIF(@x.value('(/row/@Comision)[1]','NVARCHAR(50)'),N'');
        UPDATE master.Seller SET
            SellerName = COALESCE(NULLIF(@x.value('(/row/@Nombre)[1]',    'NVARCHAR(120)'),N''), SellerName),
            Commission = CASE WHEN @ComStr IS NULL THEN Commission
                              WHEN ISNUMERIC(@ComStr) = 1 THEN CAST(@ComStr AS DECIMAL(5,2))
                              ELSE Commission END,
            Address    = COALESCE(NULLIF(@x.value('(/row/@Direccion)[1]', 'NVARCHAR(250)'),N''), Address),
            Phone      = COALESCE(NULLIF(@x.value('(/row/@Telefonos)[1]','NVARCHAR(60)'), N''), Phone),
            Email      = COALESCE(NULLIF(@x.value('(/row/@Email)[1]',    'NVARCHAR(150)'),N''), Email),
            IsActive   = ISNULL(@x.value('(/row/@Status)[1]','BIT'), IsActive),
            SellerType = COALESCE(NULLIF(@x.value('(/row/@Tipo)[1]',     'NVARCHAR(20)'), N''), SellerType),
            UpdatedAt  = SYSUTCDATETIME()
        WHERE SellerCode = @Codigo;
        SET @Resultado = 1; SET @Mensaje = N'OK';
    END TRY BEGIN CATCH SET @Resultado = -99; SET @Mensaje = ERROR_MESSAGE(); END CATCH
END

GO
 
 
