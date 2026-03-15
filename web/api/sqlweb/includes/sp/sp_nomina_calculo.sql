-- =============================================
-- MOTOR DE CÁLCULO DE NÓMINA (CANÓNICO)
-- Requiere: sp_nomina_sistema.sql
-- =============================================
SET NOCOUNT ON;
GO

IF OBJECT_ID('dbo.sp_Nomina_ReemplazarVariables','P') IS NOT NULL DROP PROCEDURE dbo.sp_Nomina_ReemplazarVariables;
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

IF OBJECT_ID('dbo.sp_Nomina_EvaluarFormula','P') IS NOT NULL DROP PROCEDURE dbo.sp_Nomina_EvaluarFormula;
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

  -- Solo caracteres matemáticos permitidos.
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

IF OBJECT_ID('dbo.sp_Nomina_CalcularConcepto','P') IS NOT NULL DROP PROCEDURE dbo.sp_Nomina_CalcularConcepto;
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

IF OBJECT_ID('dbo.sp_Nomina_ProcesarEmpleado','P') IS NOT NULL DROP PROCEDURE dbo.sp_Nomina_ProcesarEmpleado;
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
  SET @SessionID = (@Nomina + N'_' + @Cedula + N'_' + CONVERT(NVARCHAR(8), SYSUTCDATETIME(), 112));

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
        CAST(SYSUTCDATETIME() AS DATE), @FechaInicio, @FechaHasta, 0, 0, 0,
        0, N'COMPAT', N'SP_LEGACY_COMPAT', SYSUTCDATETIME(), SYSUTCDATETIME(), @UserId, @UserId
      );

      SET @RunId = SCOPE_IDENTITY();
    END
    ELSE
    BEGIN
      UPDATE hr.PayrollRun
      SET UpdatedAt = SYSUTCDATETIME(),
          UpdatedByUserId = @UserId,
          ProcessDate = CAST(SYSUTCDATETIME() AS DATE)
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
      BEGIN
        SET @Asig = @Asig + ISNULL(@Total,0);
        -- Actualizar TOTAL_ASIGNACIONES para que deducciones legales
        -- (ej. FAOV) puedan calcular sobre gananciales (LOTTT Art. 172)
        EXEC dbo.sp_Nomina_SetVariable @SessionID, N'TOTAL_ASIGNACIONES', @Asig, N'Total asignaciones acumuladas';
      END

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
    SET @Mensaje = N'Procesado canónico. Asig=' + CONVERT(NVARCHAR(40), @Asig) + N' Ded=' + CONVERT(NVARCHAR(40), @Ded) + N' Neto=' + CONVERT(NVARCHAR(40), @Neto);
  END TRY
  BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK;
    EXEC dbo.sp_Nomina_LimpiarVariables @SessionID;
    SET @Resultado = 0;
    SET @Mensaje = ERROR_MESSAGE();
  END CATCH
END
GO

IF OBJECT_ID('dbo.sp_Nomina_ProcesarNomina','P') IS NOT NULL DROP PROCEDURE dbo.sp_Nomina_ProcesarNomina;
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
