-- ============================================
-- Baseline de gobernanza de datos (no destructivo) - PostgreSQL
-- Catalogo de decisiones y snapshots de calidad de esquema
-- Vistas de cobertura de auditoria y riesgo de duplicidad
-- Traducido de SQL Server a PostgreSQL
-- ============================================

DO $$
BEGIN
    -- SchemaGovernanceDecision
    CREATE TABLE IF NOT EXISTS "SchemaGovernanceDecision" (
        "Id"              BIGSERIAL PRIMARY KEY,
        "DecisionGroup"   VARCHAR(60) NOT NULL,
        "ObjectType"      VARCHAR(20) NOT NULL,
        "ObjectName"      VARCHAR(256) NOT NULL,
        "DecisionStatus"  VARCHAR(20) NOT NULL DEFAULT 'PENDING',
        "RiskLevel"       VARCHAR(20) NOT NULL DEFAULT 'MEDIUM',
        "ProposedAction"  VARCHAR(500),
        "Notes"           TEXT,
        "Owner"           VARCHAR(80),
        "CreatedAt"       TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
        "UpdatedAt"       TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
        "CreatedBy"       VARCHAR(40),
        "UpdatedBy"       VARCHAR(40)
    );

    -- SchemaGovernanceSnapshot
    CREATE TABLE IF NOT EXISTS "SchemaGovernanceSnapshot" (
        "Id"                          BIGSERIAL PRIMARY KEY,
        "SnapshotAt"                  TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
        "TotalTables"                 INT NOT NULL,
        "TablesWithoutPK"             INT NOT NULL,
        "TablesWithoutCreatedAt"      INT NOT NULL,
        "TablesWithoutUpdatedAt"      INT NOT NULL,
        "TablesWithoutCreatedBy"      INT NOT NULL,
        "TablesWithoutDateColumns"    INT NOT NULL,
        "DuplicateNameCandidatePairs" INT NOT NULL,
        "SimilarityCandidatePairs"    INT NOT NULL,
        "Notes"                       VARCHAR(500)
    );

EXCEPTION WHEN OTHERS THEN
    RAISE EXCEPTION 'Error 00_governance_baseline.sql: %', SQLERRM;
END;
$$;

-- ============================================
-- Vista: vw_Governance_AuditCoverage
-- ============================================
CREATE OR REPLACE VIEW vw_Governance_AuditCoverage AS
WITH t AS (
    SELECT
        n.nspname AS schema_name,
        c.relname AS table_name,
        c.oid AS table_oid
    FROM pg_class c
    INNER JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE c.relkind = 'r'
      AND n.nspname NOT IN ('pg_catalog', 'information_schema')
      AND c.relname <> 'SchemaGovernanceDecision'
      AND c.relname <> 'SchemaGovernanceSnapshot'
),
pk AS (
    SELECT DISTINCT conrelid AS table_oid
    FROM pg_constraint
    WHERE contype = 'p'
),
aud AS (
    SELECT
        a.attrelid AS table_oid,
        MAX(CASE WHEN a.attname IN ('CreatedAt','FechaCreacion','Fecha_Creacion','created_at') THEN 1 ELSE 0 END) AS has_created_at,
        MAX(CASE WHEN a.attname IN ('UpdatedAt','FechaModificacion','Fecha_Modificacion','updated_at') THEN 1 ELSE 0 END) AS has_updated_at,
        MAX(CASE WHEN a.attname IN ('CreatedBy','CodUsuario','Cod_Usuario','UsuarioCreacion','created_by') THEN 1 ELSE 0 END) AS has_created_by,
        MAX(CASE WHEN a.attname IN ('UpdatedBy','UsuarioModificacion','updated_by') THEN 1 ELSE 0 END) AS has_updated_by,
        MAX(CASE WHEN a.attname IN ('IsDeleted','is_deleted') THEN 1 ELSE 0 END) AS has_is_deleted
    FROM pg_attribute a
    WHERE a.attnum > 0 AND NOT a.attisdropped
    GROUP BY a.attrelid
),
dt AS (
    SELECT
        a.attrelid AS table_oid,
        COUNT(*) FILTER (WHERE ty.typname IN ('timestamp','timestamptz','date')) AS date_column_count
    FROM pg_attribute a
    INNER JOIN pg_type ty ON a.atttypid = ty.oid
    WHERE a.attnum > 0 AND NOT a.attisdropped
    GROUP BY a.attrelid
)
SELECT
    t.schema_name,
    t.table_name,
    CASE WHEN pk.table_oid IS NULL THEN FALSE ELSE TRUE END AS has_pk,
    COALESCE(aud.has_created_at, 0)::BOOLEAN AS has_created_at,
    COALESCE(aud.has_updated_at, 0)::BOOLEAN AS has_updated_at,
    COALESCE(aud.has_created_by, 0)::BOOLEAN AS has_created_by,
    COALESCE(aud.has_updated_by, 0)::BOOLEAN AS has_updated_by,
    COALESCE(aud.has_is_deleted, 0)::BOOLEAN AS has_is_deleted,
    COALESCE(dt.date_column_count, 0) AS date_column_count
FROM t
LEFT JOIN pk ON pk.table_oid = t.table_oid
LEFT JOIN aud ON aud.table_oid = t.table_oid
LEFT JOIN dt ON dt.table_oid = t.table_oid;

-- ============================================
-- Vista: vw_Governance_DuplicateNameCandidates
-- ============================================
CREATE OR REPLACE VIEW vw_Governance_DuplicateNameCandidates AS
WITH base AS (
    SELECT c.relname AS table_name, LOWER(c.relname) AS name_lower
    FROM pg_class c
    INNER JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE c.relkind = 'r'
      AND n.nspname NOT IN ('pg_catalog', 'information_schema')
      AND c.relname <> 'SchemaGovernanceDecision'
      AND c.relname <> 'SchemaGovernanceSnapshot'
),
norm AS (
    SELECT table_name,
        CASE
            WHEN RIGHT(name_lower, 1) = 's' AND RIGHT(name_lower, 2) <> 'ss'
            THEN LEFT(name_lower, LENGTH(name_lower) - 1)
            ELSE name_lower
        END AS stem
    FROM base
)
SELECT
    a.table_name AS table_a,
    b.table_name AS table_b,
    a.stem AS normalized_name
FROM norm a
INNER JOIN norm b ON a.stem = b.stem AND a.table_name < b.table_name;

-- ============================================
-- Funcion: usp_Governance_CaptureSnapshot
-- ============================================
DROP FUNCTION IF EXISTS usp_Governance_CaptureSnapshot(VARCHAR);

CREATE OR REPLACE FUNCTION usp_Governance_CaptureSnapshot(
    p_notes VARCHAR(500) DEFAULT NULL
)
RETURNS TABLE (
    "Id"                          BIGINT,
    "SnapshotAt"                  TIMESTAMP,
    "TotalTables"                 INT,
    "TablesWithoutPK"             INT,
    "TablesWithoutCreatedAt"      INT,
    "TablesWithoutUpdatedAt"      INT,
    "TablesWithoutCreatedBy"      INT,
    "TablesWithoutDateColumns"    INT,
    "DuplicateNameCandidatePairs" INT,
    "SimilarityCandidatePairs"    INT,
    "Notes"                       VARCHAR(500)
)
LANGUAGE plpgsql AS $$
DECLARE
    v_total_tables INT := 0;
    v_without_pk INT := 0;
    v_without_created_at INT := 0;
    v_without_updated_at INT := 0;
    v_without_created_by INT := 0;
    v_without_date_cols INT := 0;
    v_dup_pairs INT := 0;
    v_sim_pairs INT := 0;
    v_id BIGINT;
BEGIN
    SELECT
        COUNT(1),
        COUNT(1) FILTER (WHERE has_pk = FALSE),
        COUNT(1) FILTER (WHERE has_created_at = FALSE),
        COUNT(1) FILTER (WHERE has_updated_at = FALSE),
        COUNT(1) FILTER (WHERE has_created_by = FALSE),
        COUNT(1) FILTER (WHERE date_column_count = 0)
    INTO v_total_tables, v_without_pk, v_without_created_at, v_without_updated_at, v_without_created_by, v_without_date_cols
    FROM vw_Governance_AuditCoverage;

    SELECT COUNT(1) INTO v_dup_pairs FROM vw_Governance_DuplicateNameCandidates;

    INSERT INTO "SchemaGovernanceSnapshot" (
        "TotalTables", "TablesWithoutPK", "TablesWithoutCreatedAt",
        "TablesWithoutUpdatedAt", "TablesWithoutCreatedBy",
        "TablesWithoutDateColumns", "DuplicateNameCandidatePairs",
        "SimilarityCandidatePairs", "Notes"
    )
    VALUES (
        v_total_tables, v_without_pk, v_without_created_at,
        v_without_updated_at, v_without_created_by,
        v_without_date_cols, v_dup_pairs,
        v_sim_pairs, p_notes
    )
    RETURNING "SchemaGovernanceSnapshot"."Id" INTO v_id;

    RETURN QUERY SELECT *
    FROM "SchemaGovernanceSnapshot" s
    WHERE s."Id" = v_id;
END;
$$;
