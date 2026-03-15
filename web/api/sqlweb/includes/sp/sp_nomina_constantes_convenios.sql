-- =============================================
-- SEMILLA DE CONCEPTOS POR CONVENIO (CANÓNICO)
-- Tabla objetivo: hr.PayrollConcept
-- =============================================
SET NOCOUNT ON;
GO

DECLARE @CompanyId INT;
SELECT TOP 1 @CompanyId = CompanyId
FROM cfg.Company
WHERE IsDeleted = 0
ORDER BY CASE WHEN CompanyCode = 'DEFAULT' THEN 0 ELSE 1 END, CompanyId;

IF @CompanyId IS NULL
  THROW 50012, 'No existe cfg.Company activa para sembrar conceptos nómina', 1;

;WITH TypeSeed AS (
  SELECT N'LOT' AS PayrollCode, N'Nómina LOTTT' AS PayrollName
  UNION ALL SELECT N'PETRO', N'Nómina CCT Petrolero'
  UNION ALL SELECT N'CONST', N'Nómina Construcción'
)
MERGE hr.PayrollType AS target
USING TypeSeed AS src
ON target.CompanyId = @CompanyId
   AND target.PayrollCode = src.PayrollCode
WHEN MATCHED THEN
  UPDATE SET
    PayrollName = src.PayrollName,
    IsActive = 1,
    UpdatedAt = SYSUTCDATETIME()
WHEN NOT MATCHED THEN
  INSERT (CompanyId, PayrollCode, PayrollName, IsActive, CreatedAt, UpdatedAt)
  VALUES (@CompanyId, src.PayrollCode, src.PayrollName, 1, SYSUTCDATETIME(), SYSUTCDATETIME());

;WITH SourceRows AS (
  -- LOTTT mensual
  SELECT N'LOT' AS PayrollCode, N'LOT' AS ConventionCode, N'MENSUAL' AS CalculationType,
         N'ASIG_BASE' AS ConceptCode, N'Salario base mensual' AS ConceptName, N'ASIGNACION' AS ConceptType,
         CAST(0.00 AS DECIMAL(18,6)) AS DefaultValue, N'SUELDO' AS Formula, N'SALARIO' AS ConceptClass, 10 AS SortOrder
  UNION ALL SELECT N'LOT', N'LOT', N'MENSUAL', N'DED_SSO', N'Deducción SSO', N'DEDUCCION', 0.00, N'SUELDO * PCT_SSO', N'LEGAL', 90
  UNION ALL SELECT N'LOT', N'LOT', N'MENSUAL', N'DED_FAOV', N'Deducción FAOV', N'DEDUCCION', 0.00, N'TOTAL_ASIGNACIONES * PCT_FAOV', N'LEGAL', 91
  UNION ALL SELECT N'LOT', N'LOT', N'MENSUAL', N'DED_LRPE', N'Deducción LRPE', N'DEDUCCION', 0.00, N'SUELDO * PCT_LRPE', N'LEGAL', 92

  -- LOTTT vacaciones
  UNION ALL SELECT N'LOT', N'LOT', N'VACACIONES', N'VAC_PAGO', N'Pago vacaciones', N'ASIGNACION', 0.00, N'SALARIO_DIARIO * DIAS_VACACIONES', N'VACACIONES', 10
  UNION ALL SELECT N'LOT', N'LOT', N'VACACIONES', N'VAC_BONO', N'Bono vacacional', N'ASIGNACION', 0.00, N'SALARIO_DIARIO * DIAS_BONO_VAC', N'VACACIONES', 20

  -- LOTTT liquidación
  UNION ALL SELECT N'LOT', N'LOT', N'LIQUIDACION', N'LIQ_PREST', N'Prestaciones', N'ASIGNACION', 0.00, N'SALARIO_DIARIO * PREST_DIAS_ANIO', N'LIQUIDACION', 10
  UNION ALL SELECT N'LOT', N'LOT', N'LIQUIDACION', N'LIQ_VAC', N'Vacaciones pendientes', N'ASIGNACION', 0.00, N'SALARIO_DIARIO * DIAS_VACACIONES_BASE', N'LIQUIDACION', 20

  -- Petrolero mensual
  UNION ALL SELECT N'PETRO', N'PETRO', N'MENSUAL', N'ASIG_BASE', N'Salario base mensual petrolero', N'ASIGNACION', 0.00, N'SUELDO', N'SALARIO', 10
  UNION ALL SELECT N'PETRO', N'PETRO', N'MENSUAL', N'BONO_PETRO', N'Bono petrolero', N'ASIGNACION', 0.00, N'SALARIO_DIARIO * 10', N'BONO', 20
  UNION ALL SELECT N'PETRO', N'PETRO', N'MENSUAL', N'DED_SSO', N'Deducción SSO', N'DEDUCCION', 0.00, N'SUELDO * PCT_SSO', N'LEGAL', 90

  -- Construcción mensual
  UNION ALL SELECT N'CONST', N'CONST', N'MENSUAL', N'ASIG_BASE', N'Salario base construcción', N'ASIGNACION', 0.00, N'SUELDO', N'SALARIO', 10
  UNION ALL SELECT N'CONST', N'CONST', N'MENSUAL', N'BONO_CONST', N'Bono construcción', N'ASIGNACION', 0.00, N'SALARIO_DIARIO * 5', N'BONO', 20
  UNION ALL SELECT N'CONST', N'CONST', N'MENSUAL', N'DED_SSO', N'Deducción SSO', N'DEDUCCION', 0.00, N'SUELDO * PCT_SSO', N'LEGAL', 90
)
MERGE hr.PayrollConcept AS target
USING SourceRows AS src
ON target.CompanyId = @CompanyId
   AND target.PayrollCode = src.PayrollCode
   AND target.ConceptCode = src.ConceptCode
   AND ISNULL(target.ConventionCode,N'') = ISNULL(src.ConventionCode,N'')
   AND ISNULL(target.CalculationType,N'') = ISNULL(src.CalculationType,N'')
WHEN MATCHED THEN
  UPDATE SET
    ConceptName = src.ConceptName,
    Formula = src.Formula,
    BaseExpression = NULL,
    ConceptClass = src.ConceptClass,
    ConceptType = src.ConceptType,
    UsageType = N'T',
    IsBonifiable = CASE WHEN src.ConceptType = N'ASIGNACION' THEN 1 ELSE 0 END,
    IsSeniority = 0,
    AccountingAccountCode = NULL,
    AppliesFlag = 1,
    DefaultValue = src.DefaultValue,
    SortOrder = src.SortOrder,
    IsActive = 1,
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
    @CompanyId, src.PayrollCode, src.ConceptCode, src.ConceptName, src.Formula, NULL,
    src.ConceptClass, src.ConceptType, N'T', CASE WHEN src.ConceptType = N'ASIGNACION' THEN 1 ELSE 0 END, 0,
    NULL, 1, src.DefaultValue, src.ConventionCode,
    src.CalculationType, NULL, NULL, src.SortOrder, 1,
    SYSUTCDATETIME(), SYSUTCDATETIME()
  );

PRINT 'Conceptos por convenio sembrados/actualizados en hr.PayrollConcept';
GO
