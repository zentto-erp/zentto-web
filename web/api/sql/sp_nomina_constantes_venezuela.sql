-- =============================================
-- SEMILLA DE CONSTANTES NÓMINA VENEZUELA (CANÓNICO)
-- =============================================
SET NOCOUNT ON;
GO

DECLARE @CompanyId INT;
SELECT TOP 1 @CompanyId = CompanyId
FROM cfg.Company
WHERE IsDeleted = 0
ORDER BY CASE WHEN CompanyCode = 'DEFAULT' THEN 0 ELSE 1 END, CompanyId;

IF @CompanyId IS NULL
  THROW 50011, 'No existe cfg.Company activa para sembrar constantes nómina', 1;

;WITH SourceRows AS (
  SELECT N'SALARIO_DIARIO' AS ConstantCode, N'Salario diario base' AS ConstantName, CAST(0.00 AS DECIMAL(18,6)) AS ConstantValue, N'VE_BASE' AS SourceName
  UNION ALL SELECT N'HORAS_MES', N'Horas laborales mensuales', 240.00, N'VE_BASE'
  UNION ALL SELECT N'PCT_SSO', N'Porcentaje SSO empleado', 0.040000, N'VE_BASE'
  UNION ALL SELECT N'PCT_FAOV', N'Porcentaje FAOV empleado', 0.010000, N'VE_BASE'
  UNION ALL SELECT N'PCT_LRPE', N'Porcentaje LRPE empleado', 0.005000, N'VE_BASE'
  UNION ALL SELECT N'RECARGO_HE', N'Recargo hora extra', 1.500000, N'VE_BASE'
  UNION ALL SELECT N'RECARGO_NOCTURNO', N'Recargo nocturno', 1.300000, N'VE_BASE'
  UNION ALL SELECT N'RECARGO_DESCANSO', N'Recargo descanso trabajado', 1.500000, N'VE_BASE'
  UNION ALL SELECT N'RECARGO_FERIADO', N'Recargo feriado trabajado', 2.000000, N'VE_BASE'
  UNION ALL SELECT N'DIAS_VACACIONES_BASE', N'Días vacaciones base', 15.000000, N'VE_BASE'
  UNION ALL SELECT N'DIAS_BONO_VAC_BASE', N'Días bono vacacional base', 15.000000, N'VE_BASE'
  UNION ALL SELECT N'DIAS_UTILIDADES_MIN', N'Días utilidades mínimo', 30.000000, N'VE_BASE'
  UNION ALL SELECT N'DIAS_UTILIDADES_MAX', N'Días utilidades máximo', 120.000000, N'VE_BASE'
  UNION ALL SELECT N'PREST_DIAS_ANIO', N'Días prestaciones por año', 30.000000, N'VE_BASE'
  UNION ALL SELECT N'PREST_INTERES_ANUAL', N'Interés anual prestaciones', 0.150000, N'VE_BASE'

  UNION ALL SELECT N'LOT_DIAS_VACACIONES_BASE', N'LOTTT: días vacaciones base', 15.000000, N'REGIMEN:LOT'
  UNION ALL SELECT N'LOT_DIAS_BONO_VAC_BASE', N'LOTTT: días bono vacacional base', 15.000000, N'REGIMEN:LOT'
  UNION ALL SELECT N'LOT_DIAS_UTILIDADES', N'LOTTT: días utilidades referencia', 30.000000, N'REGIMEN:LOT'

  UNION ALL SELECT N'PETRO_DIAS_VACACIONES_BASE', N'Petrolero: días vacaciones base', 34.000000, N'REGIMEN:PETRO'
  UNION ALL SELECT N'PETRO_DIAS_BONO_VAC_BASE', N'Petrolero: bono vacacional base', 55.000000, N'REGIMEN:PETRO'
  UNION ALL SELECT N'PETRO_DIAS_UTILIDADES', N'Petrolero: días utilidades', 120.000000, N'REGIMEN:PETRO'

  UNION ALL SELECT N'CONST_DIAS_VACACIONES_BASE', N'Construcción: días vacaciones base', 20.000000, N'REGIMEN:CONST'
  UNION ALL SELECT N'CONST_DIAS_BONO_VAC_BASE', N'Construcción: bono vacacional base', 30.000000, N'REGIMEN:CONST'
  UNION ALL SELECT N'CONST_DIAS_UTILIDADES', N'Construcción: días utilidades', 60.000000, N'REGIMEN:CONST'
)
MERGE hr.PayrollConstant AS target
USING SourceRows AS src
ON target.CompanyId = @CompanyId
   AND target.ConstantCode = src.ConstantCode
WHEN MATCHED THEN
  UPDATE SET
    ConstantName = src.ConstantName,
    ConstantValue = src.ConstantValue,
    SourceName = src.SourceName,
    IsActive = 1,
    UpdatedAt = SYSUTCDATETIME()
WHEN NOT MATCHED THEN
  INSERT (CompanyId, ConstantCode, ConstantName, ConstantValue, SourceName, IsActive, CreatedAt, UpdatedAt)
  VALUES (@CompanyId, src.ConstantCode, src.ConstantName, src.ConstantValue, src.SourceName, 1, SYSUTCDATETIME(), SYSUTCDATETIME());

PRINT 'Constantes de nómina Venezuela sembradas/actualizadas en hr.PayrollConstant';
GO
