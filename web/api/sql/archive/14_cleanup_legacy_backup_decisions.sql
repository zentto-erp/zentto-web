SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/*
  Limpieza de decisiones para tablas backup legacy
  Estas tablas no forman parte del esquema operativo.
*/

IF OBJECT_ID('dbo.SchemaGovernanceDecision', 'U') IS NULL
BEGIN
  RAISERROR('SchemaGovernanceDecision no existe.', 16, 1);
  RETURN;
END

UPDATE d
SET
  d.DecisionStatus = 'DONE',
  d.RiskLevel = 'LOW',
  d.ProposedAction = 'Tabla backup legacy excluida de auditoria operativa.',
  d.UpdatedAt = SYSUTCDATETIME(),
  d.UpdatedBy = 'SYSTEM'
FROM dbo.SchemaGovernanceDecision d
WHERE d.ObjectName LIKE '%__legacy_backup_phase2'
  AND d.DecisionGroup = 'AUDIT'
  AND d.DecisionStatus = 'REJECTED';
GO

