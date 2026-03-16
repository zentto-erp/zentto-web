-- =============================================
-- ADAPTADOR CONCEPTO LEGAL -> MODELO CANÓNICO
-- Base: hr.PayrollConcept (ConventionCode/CalculationType)
-- =============================================
SET NOCOUNT ON;
GO

IF OBJECT_ID('dbo.vw_ConceptosPorRegimen','V') IS NOT NULL DROP VIEW dbo.vw_ConceptosPorRegimen;
GO
CREATE VIEW dbo.vw_ConceptosPorRegimen
AS
SELECT
  pc.PayrollConceptId AS Id,
  pc.ConventionCode AS Convencion,
  pc.CalculationType AS TipoCalculo,
  pc.ConceptCode AS CO_CONCEPT,
  pc.ConceptName AS NB_CONCEPTO,
  pc.Formula AS FORMULA,
  pc.BaseExpression AS SOBRE,
  pc.ConceptType AS TIPO,
  CASE WHEN pc.IsBonifiable = 1 THEN 'S' ELSE 'N' END AS BONIFICABLE,
  pc.LotttArticle AS LOTTT_Articulo,
  pc.CcpClause AS CCP_Clausula,
  pc.SortOrder AS Orden,
  pc.IsActive AS Activo,
  pc.PayrollCode AS CO_NOMINA,
  pc.CompanyId
FROM hr.PayrollConcept pc
WHERE pc.ConventionCode IS NOT NULL;
GO

IF OBJECT_ID('dbo.sp_Nomina_CargarConstantesDesdeConceptoLegal','P') IS NOT NULL DROP PROCEDURE dbo.sp_Nomina_CargarConstantesDesdeConceptoLegal;
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

IF OBJECT_ID('dbo.sp_Nomina_ProcesarEmpleadoConceptoLegal','P') IS NOT NULL DROP PROCEDURE dbo.sp_Nomina_ProcesarEmpleadoConceptoLegal;
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

IF OBJECT_ID('dbo.sp_Nomina_ConceptosLegales_List','P') IS NOT NULL DROP PROCEDURE dbo.sp_Nomina_ConceptosLegales_List;
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

IF OBJECT_ID('dbo.sp_Nomina_ValidarFormulasConceptoLegal','P') IS NOT NULL DROP PROCEDURE dbo.sp_Nomina_ValidarFormulasConceptoLegal;
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
  DECLARE @SessionTest NVARCHAR(80) = (N'TEST_' + CONVERT(NVARCHAR(8), SYSUTCDATETIME(), 112));

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
      INSERT INTO #Resultados VALUES (@Id, @CoConcept, @NbConcepto, @Formula, N'Sin fórmula (usa valor por defecto)', 1);
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
