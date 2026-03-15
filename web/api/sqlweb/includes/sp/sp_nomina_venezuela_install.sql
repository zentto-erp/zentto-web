-- =============================================
-- INSTALADOR NÓMINA VENEZUELA (CANÓNICO)
-- Compatibilidad de nombres sp_Nomina_* sin tablas legacy
-- =============================================
SET NOCOUNT ON;
GO

PRINT 'Instalando base canónica de nómina...';
GO

IF SCHEMA_ID('hr') IS NULL EXEC('CREATE SCHEMA hr AUTHORIZATION dbo');
GO

IF OBJECT_ID('hr.PayrollCalcVariable','U') IS NULL
BEGIN
  CREATE TABLE hr.PayrollCalcVariable (
    SessionID NVARCHAR(80) NOT NULL,
    Variable NVARCHAR(120) NOT NULL,
    Valor DECIMAL(18,6) NOT NULL CONSTRAINT DF_PCV_Valor DEFAULT(0),
    Descripcion NVARCHAR(255) NULL,
    CreatedAt DATETIME2(3) NOT NULL CONSTRAINT DF_PCV_CreatedAt DEFAULT SYSUTCDATETIME(),
    UpdatedAt DATETIME2(3) NOT NULL CONSTRAINT DF_PCV_UpdatedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_PCV PRIMARY KEY (SessionID, Variable)
  );
END
GO

-- Wrappers de compatibilidad por si aún no se ejecutó sp_nomina_sistema.sql
IF OBJECT_ID('dbo.sp_Nomina_LimpiarVariables','P') IS NULL
BEGIN
  EXEC('CREATE PROCEDURE dbo.sp_Nomina_LimpiarVariables @SessionID NVARCHAR(80) AS BEGIN DELETE FROM hr.PayrollCalcVariable WHERE SessionID=@SessionID; END');
END
GO

IF OBJECT_ID('dbo.sp_Nomina_SetVariable','P') IS NULL
BEGIN
  EXEC('CREATE PROCEDURE dbo.sp_Nomina_SetVariable @SessionID NVARCHAR(80), @Variable NVARCHAR(120), @Valor DECIMAL(18,6), @Descripcion NVARCHAR(255)=NULL AS BEGIN MERGE hr.PayrollCalcVariable t USING (SELECT @SessionID SessionID,@Variable Variable) s ON t.SessionID=s.SessionID AND t.Variable=s.Variable WHEN MATCHED THEN UPDATE SET Valor=@Valor,Descripcion=@Descripcion,UpdatedAt=SYSUTCDATETIME() WHEN NOT MATCHED THEN INSERT(SessionID,Variable,Valor,Descripcion) VALUES(@SessionID,@Variable,@Valor,@Descripcion); END');
END
GO

IF OBJECT_ID('dbo.sp_Nomina_CalcularAntiguedad','P') IS NULL
BEGIN
  EXEC('CREATE PROCEDURE dbo.sp_Nomina_CalcularAntiguedad @SessionID NVARCHAR(80), @Cedula NVARCHAR(32), @FechaCalculo DATE=NULL AS BEGIN IF @FechaCalculo IS NULL SET @FechaCalculo=CAST(SYSUTCDATETIME() AS DATE); EXEC dbo.sp_Nomina_SetVariable @SessionID, N''ANTI_ANIOS'', 0, N''Años''; EXEC dbo.sp_Nomina_SetVariable @SessionID, N''ANTI_MESES'', 0, N''Meses''; EXEC dbo.sp_Nomina_SetVariable @SessionID, N''ANTI_TOTAL_MESES'', 0, N''Total meses''; END');
END
GO

-- Semilla de constantes base para Venezuela (idempotente)
DECLARE @CompanyId INT;
SELECT TOP 1 @CompanyId = CompanyId
FROM cfg.Company
WHERE IsDeleted = 0
ORDER BY CASE WHEN CompanyCode = 'DEFAULT' THEN 0 ELSE 1 END, CompanyId;

IF @CompanyId IS NULL
  THROW 50031, 'No existe cfg.Company activa', 1;

;WITH Seed AS (
  SELECT N'SALARIO_DIARIO' ConstantCode, N'Salario diario base' ConstantName, CAST(0.00 AS DECIMAL(18,6)) ConstantValue, N'VE_INSTALL' SourceName
  UNION ALL SELECT N'HORAS_MES', N'Horas laborales mensuales', 240.00, N'VE_INSTALL'
  UNION ALL SELECT N'PCT_SSO', N'Porcentaje SSO empleado', 0.040000, N'VE_INSTALL'
  UNION ALL SELECT N'PCT_FAOV', N'Porcentaje FAOV empleado', 0.010000, N'VE_INSTALL'
  UNION ALL SELECT N'PCT_LRPE', N'Porcentaje LRPE empleado', 0.005000, N'VE_INSTALL'
  UNION ALL SELECT N'DIAS_VACACIONES_BASE', N'Días vacaciones base', 15.000000, N'VE_INSTALL'
  UNION ALL SELECT N'DIAS_BONO_VAC_BASE', N'Días bono vacacional base', 15.000000, N'VE_INSTALL'
  UNION ALL SELECT N'DIAS_UTILIDADES_MIN', N'Días utilidades mínimo', 30.000000, N'VE_INSTALL'
  UNION ALL SELECT N'DIAS_UTILIDADES_MAX', N'Días utilidades máximo', 120.000000, N'VE_INSTALL'
)
MERGE hr.PayrollConstant AS t
USING Seed AS s
ON t.CompanyId = @CompanyId AND t.ConstantCode = s.ConstantCode
WHEN MATCHED THEN
  UPDATE SET ConstantName = s.ConstantName, ConstantValue = s.ConstantValue, SourceName = s.SourceName, IsActive = 1, UpdatedAt = SYSUTCDATETIME()
WHEN NOT MATCHED THEN
  INSERT (CompanyId, ConstantCode, ConstantName, ConstantValue, SourceName, IsActive, CreatedAt, UpdatedAt)
  VALUES (@CompanyId, s.ConstantCode, s.ConstantName, s.ConstantValue, s.SourceName, 1, SYSUTCDATETIME(), SYSUTCDATETIME());
GO

PRINT 'Instalación canónica de nómina completada.';
GO

SELECT 'PayrollType' AS Objeto, COUNT(1) AS Total FROM hr.PayrollType
UNION ALL SELECT 'PayrollConstant', COUNT(1) FROM hr.PayrollConstant
UNION ALL SELECT 'PayrollConcept', COUNT(1) FROM hr.PayrollConcept
UNION ALL SELECT 'PayrollRun', COUNT(1) FROM hr.PayrollRun
UNION ALL SELECT 'PayrollCalcVariable', COUNT(1) FROM hr.PayrollCalcVariable;
GO
