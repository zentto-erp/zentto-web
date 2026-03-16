-- =============================================
-- CONSULTAS NÓMINA (CANÓNICO)
-- =============================================
SET NOCOUNT ON;
GO

IF OBJECT_ID('dbo.sp_Nomina_Conceptos_List','P') IS NOT NULL DROP PROCEDURE dbo.sp_Nomina_Conceptos_List;
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

IF OBJECT_ID('dbo.sp_Nomina_Concepto_Save','P') IS NOT NULL DROP PROCEDURE dbo.sp_Nomina_Concepto_Save;
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

IF OBJECT_ID('dbo.sp_Nomina_List','P') IS NOT NULL DROP PROCEDURE dbo.sp_Nomina_List;
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

IF OBJECT_ID('dbo.sp_Nomina_Get','P') IS NOT NULL DROP PROCEDURE dbo.sp_Nomina_Get;
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

IF OBJECT_ID('dbo.sp_Nomina_Cerrar','P') IS NOT NULL DROP PROCEDURE dbo.sp_Nomina_Cerrar;
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

IF OBJECT_ID('dbo.sp_Nomina_Vacaciones_List','P') IS NOT NULL DROP PROCEDURE dbo.sp_Nomina_Vacaciones_List;
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

IF OBJECT_ID('dbo.sp_Nomina_Vacaciones_Get','P') IS NOT NULL DROP PROCEDURE dbo.sp_Nomina_Vacaciones_Get;
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

IF OBJECT_ID('dbo.sp_Nomina_Liquidaciones_List','P') IS NOT NULL DROP PROCEDURE dbo.sp_Nomina_Liquidaciones_List;
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

IF OBJECT_ID('dbo.sp_Nomina_Constantes_List','P') IS NOT NULL DROP PROCEDURE dbo.sp_Nomina_Constantes_List;
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

IF OBJECT_ID('dbo.sp_Nomina_Constante_Save','P') IS NOT NULL DROP PROCEDURE dbo.sp_Nomina_Constante_Save;
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
