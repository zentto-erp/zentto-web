SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/*
  Fase 3 Auditoria - Batch Movimientos/Restantes
  - Aplica auditoria al resto de tablas de usuario que aun no tienen estandar
  - Requiere helper dbo.usp_Governance_ApplyAuditColumns
*/

IF OBJECT_ID('dbo.usp_Governance_ApplyAuditColumns', 'P') IS NULL
BEGIN
  RAISERROR('Falta helper dbo.usp_Governance_ApplyAuditColumns. Ejecuta 11_audit_columns_phase2_maestros.sql primero.', 16, 1);
  RETURN;
END

IF OBJECT_ID('dbo.vw_Governance_AuditCoverage', 'V') IS NULL
BEGIN
  RAISERROR('Falta vw_Governance_AuditCoverage. Ejecuta 00_governance_baseline.sql primero.', 16, 1);
  RETURN;
END

DECLARE @TableName SYSNAME;

DECLARE c CURSOR LOCAL FAST_FORWARD FOR
SELECT table_name
FROM dbo.vw_Governance_AuditCoverage
WHERE schema_name = 'dbo'
  AND table_name NOT IN (
    'sysdiagrams',
    'SchemaGovernanceDecision',
    'SchemaGovernanceSnapshot',
    'EndpointDependency'
  )
  AND (has_created_at = 0 OR has_updated_at = 0 OR has_created_by = 0 OR has_is_deleted = 0)
ORDER BY table_name;

OPEN c;
FETCH NEXT FROM c INTO @TableName;
WHILE @@FETCH_STATUS = 0
BEGIN
  BEGIN TRY
    EXEC dbo.usp_Governance_ApplyAuditColumns @SchemaName='dbo', @TableName=@TableName;

    MERGE dbo.SchemaGovernanceDecision AS tgt
    USING (SELECT @TableName AS ObjectName) AS src
    ON tgt.DecisionGroup='AUDIT' AND tgt.ObjectType='TABLE' AND tgt.ObjectName=src.ObjectName
    WHEN MATCHED THEN
      UPDATE SET DecisionStatus='DONE', RiskLevel='LOW', ProposedAction='Auditoria aplicada (batch movimientos/restantes)', UpdatedAt=SYSUTCDATETIME(), UpdatedBy='SYSTEM'
    WHEN NOT MATCHED THEN
      INSERT (DecisionGroup, ObjectType, ObjectName, DecisionStatus, RiskLevel, ProposedAction, Notes, Owner, CreatedBy, UpdatedBy)
      VALUES ('AUDIT','TABLE',src.ObjectName,'DONE','LOW','Auditoria aplicada (batch movimientos/restantes)','Phase3 movimientos/restantes','DBA','SYSTEM','SYSTEM');
  END TRY
  BEGIN CATCH
    MERGE dbo.SchemaGovernanceDecision AS tgt
    USING (SELECT @TableName AS ObjectName) AS src
    ON tgt.DecisionGroup='AUDIT' AND tgt.ObjectType='TABLE' AND tgt.ObjectName=src.ObjectName
    WHEN MATCHED THEN
      UPDATE SET DecisionStatus='REJECTED', RiskLevel='HIGH', ProposedAction='Error aplicando auditoria (batch movimientos/restantes)', Notes=ERROR_MESSAGE(), UpdatedAt=SYSUTCDATETIME(), UpdatedBy='SYSTEM'
    WHEN NOT MATCHED THEN
      INSERT (DecisionGroup, ObjectType, ObjectName, DecisionStatus, RiskLevel, ProposedAction, Notes, Owner, CreatedBy, UpdatedBy)
      VALUES ('AUDIT','TABLE',src.ObjectName,'REJECTED','HIGH','Error aplicando auditoria (batch movimientos/restantes)',ERROR_MESSAGE(),'DBA','SYSTEM','SYSTEM');
  END CATCH;

  FETCH NEXT FROM c INTO @TableName;
END
CLOSE c;
DEALLOCATE c;
GO

