SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/*
  Baseline de gobernanza de datos (no destructivo)
  - Catálogo de decisiones y snapshots de calidad de esquema
  - Vistas de cobertura de auditoría y riesgo de duplicidad
*/

BEGIN TRY
  BEGIN TRAN;

  IF OBJECT_ID('dbo.SchemaGovernanceDecision', 'U') IS NULL
  BEGIN
    CREATE TABLE dbo.SchemaGovernanceDecision (
      Id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      DecisionGroup NVARCHAR(60) NOT NULL,    -- DUPLICATE_TABLE / DEPRECATION / NORMALIZATION / AUDIT
      ObjectType NVARCHAR(20) NOT NULL,       -- TABLE / VIEW / PROC / COLUMN
      ObjectName NVARCHAR(256) NOT NULL,
      DecisionStatus NVARCHAR(20) NOT NULL DEFAULT('PENDING'), -- PENDING/APPROVED/DONE/REJECTED
      RiskLevel NVARCHAR(20) NOT NULL DEFAULT('MEDIUM'),       -- LOW/MEDIUM/HIGH
      ProposedAction NVARCHAR(500) NULL,
      Notes NVARCHAR(MAX) NULL,
      Owner NVARCHAR(80) NULL,
      CreatedAt DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
      UpdatedAt DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
      CreatedBy NVARCHAR(40) NULL,
      UpdatedBy NVARCHAR(40) NULL
    );
  END

  IF OBJECT_ID('dbo.SchemaGovernanceSnapshot', 'U') IS NULL
  BEGIN
    CREATE TABLE dbo.SchemaGovernanceSnapshot (
      Id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      SnapshotAt DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
      TotalTables INT NOT NULL,
      TablesWithoutPK INT NOT NULL,
      TablesWithoutCreatedAt INT NOT NULL,
      TablesWithoutUpdatedAt INT NOT NULL,
      TablesWithoutCreatedBy INT NOT NULL,
      TablesWithoutDateColumns INT NOT NULL,
      DuplicateNameCandidatePairs INT NOT NULL,
      SimilarityCandidatePairs INT NOT NULL,
      Notes NVARCHAR(500) NULL
    );
  END

  IF OBJECT_ID('dbo.vw_Governance_AuditCoverage', 'V') IS NOT NULL
    DROP VIEW dbo.vw_Governance_AuditCoverage;

  EXEC('
  CREATE VIEW dbo.vw_Governance_AuditCoverage
  AS
  WITH t AS (
    SELECT s.name AS schema_name, tb.name AS table_name, tb.object_id
    FROM sys.tables tb
    INNER JOIN sys.schemas s ON s.schema_id = tb.schema_id
    WHERE tb.name <> ''sysdiagrams''
      AND tb.name <> ''EndpointDependency''
      AND tb.name NOT LIKE ''%__legacy_backup_phase2%''
      AND tb.name NOT LIKE ''%__legacy_backup_phase1%''
      AND tb.name NOT LIKE ''SchemaGovernance%''
  ),
  pk AS (
    SELECT DISTINCT parent_object_id AS object_id
    FROM sys.key_constraints
    WHERE type = ''PK''
  ),
  aud AS (
    SELECT
      c.object_id,
      MAX(CASE WHEN c.name IN (''CreatedAt'',''FechaCreacion'',''Fecha_Creacion'',''FECHA_CREACION'',''created_at'') THEN 1 ELSE 0 END) AS has_created_at,
      MAX(CASE WHEN c.name IN (''UpdatedAt'',''FechaModificacion'',''Fecha_Modificacion'',''FECHA_MODIFICACION'',''updated_at'') THEN 1 ELSE 0 END) AS has_updated_at,
      MAX(CASE WHEN c.name IN (''CreatedBy'',''CodUsuario'',''Cod_Usuario'',''UsuarioCreacion'',''USUARIO_CREACION'',''created_by'') THEN 1 ELSE 0 END) AS has_created_by,
      MAX(CASE WHEN c.name IN (''UpdatedBy'',''UsuarioModificacion'',''USUARIO_MODIFICACION'',''updated_by'') THEN 1 ELSE 0 END) AS has_updated_by,
      MAX(CASE WHEN c.name IN (''IsDeleted'',''is_deleted'') THEN 1 ELSE 0 END) AS has_is_deleted
    FROM sys.columns c
    GROUP BY c.object_id
  ),
  dt AS (
    SELECT
      c.object_id,
      SUM(CASE WHEN ty.name IN (''datetime'',''datetime2'',''date'',''smalldatetime'') THEN 1 ELSE 0 END) AS date_column_count
    FROM sys.columns c
    INNER JOIN sys.types ty ON c.user_type_id = ty.user_type_id
    GROUP BY c.object_id
  )
  SELECT
    t.schema_name,
    t.table_name,
    CASE WHEN pk.object_id IS NULL THEN CAST(0 AS BIT) ELSE CAST(1 AS BIT) END AS has_pk,
    CAST(ISNULL(aud.has_created_at, 0) AS BIT) AS has_created_at,
    CAST(ISNULL(aud.has_updated_at, 0) AS BIT) AS has_updated_at,
    CAST(ISNULL(aud.has_created_by, 0) AS BIT) AS has_created_by,
    CAST(ISNULL(aud.has_updated_by, 0) AS BIT) AS has_updated_by,
    CAST(ISNULL(aud.has_is_deleted, 0) AS BIT) AS has_is_deleted,
    ISNULL(dt.date_column_count, 0) AS date_column_count
  FROM t
  LEFT JOIN pk ON pk.object_id = t.object_id
  LEFT JOIN aud ON aud.object_id = t.object_id
  LEFT JOIN dt ON dt.object_id = t.object_id;
  ');

  IF OBJECT_ID('dbo.vw_Governance_DuplicateNameCandidates', 'V') IS NOT NULL
    DROP VIEW dbo.vw_Governance_DuplicateNameCandidates;

  EXEC('
  CREATE VIEW dbo.vw_Governance_DuplicateNameCandidates
  AS
  WITH base AS (
    SELECT
      tb.name AS table_name,
      LOWER(tb.name) AS name_lower
    FROM sys.tables tb
    WHERE tb.name <> ''sysdiagrams''
      AND tb.name <> ''EndpointDependency''
      AND tb.name NOT LIKE ''%__legacy_backup_phase2%''
      AND tb.name NOT LIKE ''%__legacy_backup_phase1%''
      AND tb.name NOT LIKE ''SchemaGovernance%''
  ),
  norm AS (
    SELECT
      table_name,
      CASE
        WHEN RIGHT(name_lower, 1) = ''s'' AND RIGHT(name_lower, 2) <> ''ss''
          THEN LEFT(name_lower, LEN(name_lower) - 1)
        ELSE name_lower
      END AS stem
    FROM base
  )
  SELECT
    a.table_name AS table_a,
    b.table_name AS table_b,
    a.stem AS normalized_name
  FROM norm a
  INNER JOIN norm b
    ON a.stem = b.stem
   AND a.table_name < b.table_name;
  ');

  IF OBJECT_ID('dbo.vw_Governance_TableSimilarityCandidates', 'V') IS NOT NULL
    DROP VIEW dbo.vw_Governance_TableSimilarityCandidates;

  EXEC('
  CREATE VIEW dbo.vw_Governance_TableSimilarityCandidates
  AS
  WITH cols AS (
    SELECT c.object_id, LOWER(c.name) AS column_name
    FROM sys.columns c
    INNER JOIN sys.tables t ON t.object_id = c.object_id
    WHERE t.name <> ''sysdiagrams''
      AND t.name <> ''EndpointDependency''
      AND t.name NOT LIKE ''%__legacy_backup_phase2%''
      AND t.name NOT LIKE ''%__legacy_backup_phase1%''
      AND t.name NOT LIKE ''SchemaGovernance%''
  ),
  tcols AS (
    SELECT object_id, COUNT(1) AS column_count
    FROM cols
    GROUP BY object_id
  ),
  common_cols AS (
    SELECT
      a.object_id AS object_id_a,
      b.object_id AS object_id_b,
      COUNT(1) AS common_count
    FROM cols a
    INNER JOIN cols b
      ON a.column_name = b.column_name
     AND a.object_id < b.object_id
    GROUP BY a.object_id, b.object_id
  )
  SELECT
    ta.name AS table_a,
    tb.name AS table_b,
    cc.common_count,
    ca.column_count AS columns_a,
    cb.column_count AS columns_b,
    CAST(
      CASE
        WHEN (ca.column_count + cb.column_count - cc.common_count) = 0 THEN 0
        ELSE (cc.common_count * 1.0) / (ca.column_count + cb.column_count - cc.common_count)
      END
      AS DECIMAL(9,4)
    ) AS similarity_ratio
  FROM common_cols cc
  INNER JOIN tcols ca ON ca.object_id = cc.object_id_a
  INNER JOIN tcols cb ON cb.object_id = cc.object_id_b
  INNER JOIN sys.tables ta ON ta.object_id = cc.object_id_a
  INNER JOIN sys.tables tb ON tb.object_id = cc.object_id_b
  WHERE cc.common_count >= 5;
  ');

  IF OBJECT_ID('dbo.usp_Governance_CaptureSnapshot', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_Governance_CaptureSnapshot;
  EXEC('
  CREATE PROCEDURE dbo.usp_Governance_CaptureSnapshot
    @Notes NVARCHAR(500) = NULL
  AS
  BEGIN
    SET NOCOUNT ON;

    DECLARE
      @TotalTables INT = 0,
      @TablesWithoutPK INT = 0,
      @TablesWithoutCreatedAt INT = 0,
      @TablesWithoutUpdatedAt INT = 0,
      @TablesWithoutCreatedBy INT = 0,
      @TablesWithoutDateColumns INT = 0,
      @DuplicateNamePairs INT = 0,
      @SimilarityPairs INT = 0;

    SELECT
      @TotalTables = COUNT(1),
      @TablesWithoutPK = SUM(CASE WHEN has_pk = 0 THEN 1 ELSE 0 END),
      @TablesWithoutCreatedAt = SUM(CASE WHEN has_created_at = 0 THEN 1 ELSE 0 END),
      @TablesWithoutUpdatedAt = SUM(CASE WHEN has_updated_at = 0 THEN 1 ELSE 0 END),
      @TablesWithoutCreatedBy = SUM(CASE WHEN has_created_by = 0 THEN 1 ELSE 0 END),
      @TablesWithoutDateColumns = SUM(CASE WHEN date_column_count = 0 THEN 1 ELSE 0 END)
    FROM dbo.vw_Governance_AuditCoverage;

    SELECT @DuplicateNamePairs = COUNT(1) FROM dbo.vw_Governance_DuplicateNameCandidates;
    SELECT @SimilarityPairs = COUNT(1)
    FROM dbo.vw_Governance_TableSimilarityCandidates
    WHERE similarity_ratio >= 0.7000;

    INSERT INTO dbo.SchemaGovernanceSnapshot (
      TotalTables,
      TablesWithoutPK,
      TablesWithoutCreatedAt,
      TablesWithoutUpdatedAt,
      TablesWithoutCreatedBy,
      TablesWithoutDateColumns,
      DuplicateNameCandidatePairs,
      SimilarityCandidatePairs,
      Notes
    )
    VALUES (
      @TotalTables,
      @TablesWithoutPK,
      @TablesWithoutCreatedAt,
      @TablesWithoutUpdatedAt,
      @TablesWithoutCreatedBy,
      @TablesWithoutDateColumns,
      @DuplicateNamePairs,
      @SimilarityPairs,
      @Notes
    );

    SELECT TOP 1 *
    FROM dbo.SchemaGovernanceSnapshot
    ORDER BY Id DESC;
  END
  ');

  COMMIT TRAN;
END TRY
BEGIN CATCH
  IF @@TRANCOUNT > 0 ROLLBACK TRAN;
  DECLARE @Err NVARCHAR(4000) = ERROR_MESSAGE();
  RAISERROR('Error 00_governance_baseline.sql: %s', 16, 1, @Err);
END CATCH;
GO
