SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/*
  Fase 2B - Consolidacion automatica de duplicados vacios
  Regla:
    - similarity_ratio = 1.0
    - una tabla con 0 filas y la otra con >0
    - se reemplaza la vacia por vista de compatibilidad hacia la canónica
*/

IF OBJECT_ID('dbo.vw_Governance_TableSimilarityCandidates', 'V') IS NULL
BEGIN
  RAISERROR('Falta vw_Governance_TableSimilarityCandidates. Ejecuta 00_governance_baseline.sql primero.', 16, 1);
  RETURN;
END

DECLARE @Pairs TABLE (
  SourceTable SYSNAME NOT NULL,
  TargetTable SYSNAME NOT NULL
);

;WITH rc AS (
  SELECT
    t.name AS table_name,
    SUM(p.rows) AS row_count
  FROM sys.tables t
  INNER JOIN sys.partitions p
    ON p.object_id = t.object_id
   AND p.index_id IN (0,1)
  GROUP BY t.name
),
cand AS (
  SELECT
    s.table_a,
    s.table_b,
    ra.row_count AS rows_a,
    rb.row_count AS rows_b,
    s.similarity_ratio
  FROM dbo.vw_Governance_TableSimilarityCandidates s
  INNER JOIN rc ra ON ra.table_name = s.table_a
  INNER JOIN rc rb ON rb.table_name = s.table_b
  WHERE s.similarity_ratio = 1.0000
)
INSERT INTO @Pairs (SourceTable, TargetTable)
SELECT
  CASE WHEN rows_a = 0 AND rows_b > 0 THEN table_a ELSE table_b END AS SourceTable,
  CASE WHEN rows_a = 0 AND rows_b > 0 THEN table_b ELSE table_a END AS TargetTable
FROM cand
WHERE (rows_a = 0 AND rows_b > 0) OR (rows_b = 0 AND rows_a > 0);

DELETE p
FROM @Pairs p
WHERE p.SourceTable IN (
  'Categoria', 'Cliente', 'Inventarios', 'Monedas', -- ya tratados manualmente en fase 2
  'sysdiagrams'
);

DECLARE @Source SYSNAME;
DECLARE @Target SYSNAME;
DECLARE @ColList NVARCHAR(MAX);
DECLARE @Sql NVARCHAR(MAX);
DECLARE @Compatible INT;

DECLARE c CURSOR LOCAL FAST_FORWARD FOR
  SELECT SourceTable, TargetTable
  FROM @Pairs
  ORDER BY SourceTable, TargetTable;

OPEN c;
FETCH NEXT FROM c INTO @Source, @Target;
WHILE @@FETCH_STATUS = 0
BEGIN
  BEGIN TRY
    IF OBJECT_ID('dbo.' + @Source, 'U') IS NULL
    BEGIN
      FETCH NEXT FROM c INTO @Source, @Target;
      CONTINUE;
    END

    IF OBJECT_ID('dbo.' + @Target, 'U') IS NULL
    BEGIN
      FETCH NEXT FROM c INTO @Source, @Target;
      CONTINUE;
    END

    SELECT @Compatible =
      CASE WHEN EXISTS (
        SELECT 1
        FROM sys.columns s
        LEFT JOIN sys.columns t
          ON t.object_id = OBJECT_ID('dbo.' + @Target)
         AND t.name = s.name
        WHERE s.object_id = OBJECT_ID('dbo.' + @Source)
          AND t.name IS NULL
      ) THEN 0 ELSE 1 END;

    IF ISNULL(@Compatible, 0) = 0
    BEGIN
      MERGE dbo.SchemaGovernanceDecision AS tgt
      USING (
        SELECT CONCAT(@Source, '<->', @Target) AS ObjectName
      ) AS src
      ON tgt.DecisionGroup='DUPLICATE_TABLE' AND tgt.ObjectType='TABLE' AND tgt.ObjectName=src.ObjectName
      WHEN MATCHED THEN
        UPDATE SET DecisionStatus='REJECTED', RiskLevel='HIGH', ProposedAction='Compatibilidad de columnas insuficiente para consolidacion automatica', UpdatedAt=SYSUTCDATETIME(), UpdatedBy='SYSTEM'
      WHEN NOT MATCHED THEN
        INSERT (DecisionGroup, ObjectType, ObjectName, DecisionStatus, RiskLevel, ProposedAction, Notes, Owner, CreatedBy, UpdatedBy)
        VALUES ('DUPLICATE_TABLE','TABLE',src.ObjectName,'REJECTED','HIGH','Compatibilidad de columnas insuficiente para consolidacion automatica','Requiere migracion manual','DBA','SYSTEM','SYSTEM');

      FETCH NEXT FROM c INTO @Source, @Target;
      CONTINUE;
    END

    IF OBJECT_ID('dbo.' + @Source + '__legacy_backup_phase2', 'U') IS NULL
    BEGIN
      SET @Sql = N'SELECT * INTO dbo.' + QUOTENAME(@Source + '__legacy_backup_phase2') + N' FROM dbo.' + QUOTENAME(@Source) + N';';
      EXEC(@Sql);
    END

    SET @Sql = N'DROP TABLE dbo.' + QUOTENAME(@Source) + N';';
    EXEC(@Sql);

    IF OBJECT_ID('dbo.' + @Source, 'V') IS NOT NULL
    BEGIN
      SET @Sql = N'DROP VIEW dbo.' + QUOTENAME(@Source) + N';';
      EXEC(@Sql);
    END

    SELECT @ColList =
      STUFF((
        SELECT ', ' + QUOTENAME(c.name)
        FROM sys.columns c
        WHERE c.object_id = OBJECT_ID('dbo.' + @Source + '__legacy_backup_phase2')
        ORDER BY c.column_id
        FOR XML PATH(''), TYPE
      ).value('.', 'nvarchar(max)'), 1, 2, '');

    SET @Sql = N'CREATE VIEW dbo.' + QUOTENAME(@Source) + N' AS SELECT ' + @ColList + N' FROM dbo.' + QUOTENAME(@Target) + N';';
    EXEC(@Sql);

    MERGE dbo.SchemaGovernanceDecision AS tgt
    USING (
      SELECT CONCAT(@Source, '<->', @Target) AS ObjectName
    ) AS src
    ON tgt.DecisionGroup='DUPLICATE_TABLE' AND tgt.ObjectType='TABLE' AND tgt.ObjectName=src.ObjectName
    WHEN MATCHED THEN
      UPDATE SET DecisionStatus='DONE', RiskLevel='MEDIUM', ProposedAction='Tabla vacia consolidada automaticamente y reemplazada por vista', UpdatedAt=SYSUTCDATETIME(), UpdatedBy='SYSTEM'
    WHEN NOT MATCHED THEN
      INSERT (DecisionGroup, ObjectType, ObjectName, DecisionStatus, RiskLevel, ProposedAction, Notes, Owner, CreatedBy, UpdatedBy)
      VALUES ('DUPLICATE_TABLE','TABLE',src.ObjectName,'DONE','MEDIUM','Tabla vacia consolidada automaticamente y reemplazada por vista','Consolidacion automatica phase2b','DBA','SYSTEM','SYSTEM');
  END TRY
  BEGIN CATCH
    MERGE dbo.SchemaGovernanceDecision AS tgt
    USING (
      SELECT CONCAT(@Source, '<->', @Target) AS ObjectName
    ) AS src
    ON tgt.DecisionGroup='DUPLICATE_TABLE' AND tgt.ObjectType='TABLE' AND tgt.ObjectName=src.ObjectName
    WHEN MATCHED THEN
      UPDATE SET DecisionStatus='REJECTED', RiskLevel='HIGH', ProposedAction='Error en consolidacion automatica', Notes=ERROR_MESSAGE(), UpdatedAt=SYSUTCDATETIME(), UpdatedBy='SYSTEM'
    WHEN NOT MATCHED THEN
      INSERT (DecisionGroup, ObjectType, ObjectName, DecisionStatus, RiskLevel, ProposedAction, Notes, Owner, CreatedBy, UpdatedBy)
      VALUES ('DUPLICATE_TABLE','TABLE',src.ObjectName,'REJECTED','HIGH','Error en consolidacion automatica',ERROR_MESSAGE(),'DBA','SYSTEM','SYSTEM');
  END CATCH;

  FETCH NEXT FROM c INTO @Source, @Target;
END
CLOSE c;
DEALLOCATE c;
GO

