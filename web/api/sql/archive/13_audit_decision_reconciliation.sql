SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/*
  Reconciliacion de decisiones AUDIT rechazadas por conflicto de timestamp/rowversion
  Si la tabla ya cumple auditoria base, se marca DONE.
*/

IF OBJECT_ID('dbo.SchemaGovernanceDecision', 'U') IS NULL OR OBJECT_ID('dbo.vw_Governance_AuditCoverage', 'V') IS NULL
BEGIN
  RAISERROR('Faltan objetos de gobernanza (SchemaGovernanceDecision/vw_Governance_AuditCoverage).', 16, 1);
  RETURN;
END

UPDATE d
SET
  d.DecisionStatus = 'DONE',
  d.RiskLevel = 'LOW',
  d.ProposedAction = 'Auditoria aplicada; rowversion existente (upsize_ts/timestamp legacy).',
  d.Notes = CONCAT(ISNULL(d.Notes, ''), ' | reconciled=', CONVERT(NVARCHAR(19), SYSUTCDATETIME(), 120)),
  d.UpdatedAt = SYSUTCDATETIME(),
  d.UpdatedBy = 'SYSTEM'
FROM dbo.SchemaGovernanceDecision d
INNER JOIN dbo.vw_Governance_AuditCoverage a
  ON a.table_name = d.ObjectName
WHERE d.DecisionGroup = 'AUDIT'
  AND d.DecisionStatus = 'REJECTED'
  AND d.Notes LIKE N'%timestamp%'
  AND a.has_created_at = 1
  AND a.has_updated_at = 1
  AND a.has_created_by = 1
  AND a.has_is_deleted = 1;
GO

