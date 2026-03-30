-- ============================================================
-- DatqBoxWeb PostgreSQL - 00_governance_baseline.sql
-- Baseline de gobernanza de datos (no destructivo).
-- Catalogo de decisiones, snapshots de calidad de esquema,
-- vistas de cobertura de auditoria y riesgo de duplicidad.
-- ============================================================

DO $body$
BEGIN

    -- SchemaGovernanceDecision
    CREATE TABLE IF NOT EXISTS public."SchemaGovernanceDecision" (
        "Id"             BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
        "DecisionGroup"  VARCHAR(60) NOT NULL,
        "ObjectType"     VARCHAR(20) NOT NULL,
        "ObjectName"     VARCHAR(256) NOT NULL,
        "DecisionStatus" VARCHAR(20) NOT NULL DEFAULT 'PENDING',
        "RiskLevel"      VARCHAR(20) NOT NULL DEFAULT 'MEDIUM',
        "ProposedAction" VARCHAR(500) NULL,
        "Notes"          TEXT NULL,
        "Owner"          VARCHAR(80) NULL,
        "CreatedAt"      TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
        "UpdatedAt"      TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
        "CreatedBy"      VARCHAR(40) NULL,
        "UpdatedBy"      VARCHAR(40) NULL
    );

    -- SchemaGovernanceSnapshot
    CREATE TABLE IF NOT EXISTS public."SchemaGovernanceSnapshot" (
        "Id"                         BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
        "SnapshotAt"                 TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
        "TotalTables"                INT NOT NULL,
        "TablesWithoutPK"            INT NOT NULL,
        "TablesWithoutCreatedAt"     INT NOT NULL,
        "TablesWithoutUpdatedAt"     INT NOT NULL,
        "TablesWithoutCreatedBy"     INT NOT NULL,
        "TablesWithoutDateColumns"   INT NOT NULL,
        "DuplicateNameCandidatePairs" INT NOT NULL,
        "SimilarityCandidatePairs"   INT NOT NULL,
        "Notes"                      VARCHAR(500) NULL
    );

EXCEPTION WHEN OTHERS THEN
    RAISE EXCEPTION 'Error 00_governance_baseline.sql: %', SQLERRM;
END;
$body$;

-- Vista: Cobertura de auditoria
CREATE OR REPLACE VIEW public."vw_Governance_AuditCoverage" AS
WITH t AS (
    SELECT n.nspname AS schema_name, c.relname AS table_name, c.oid AS object_id
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE c.relkind = 'r'
      AND c.relname <> 'sysdiagrams'
      AND c.relname NOT LIKE '%SchemaGovernance%'
      AND n.nspname NOT IN ('pg_catalog', 'information_schema')
),
pk AS (
    SELECT DISTINCT con.conrelid AS object_id
    FROM pg_constraint con
    WHERE con.contype = 'p'
),
aud AS (
    SELECT
        a.attrelid AS object_id,
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
        a.attrelid AS object_id,
        SUM(CASE WHEN tp.typname IN ('timestamp','timestamptz','date') THEN 1 ELSE 0 END) AS date_column_count
    FROM pg_attribute a
    JOIN pg_type tp ON a.atttypid = tp.oid
    WHERE a.attnum > 0 AND NOT a.attisdropped
    GROUP BY a.attrelid
)
SELECT
    t.schema_name,
    t.table_name,
    CASE WHEN pk.object_id IS NULL THEN FALSE ELSE TRUE END AS has_pk,
    COALESCE(aud.has_created_at, 0)::BOOLEAN AS has_created_at,
    COALESCE(aud.has_updated_at, 0)::BOOLEAN AS has_updated_at,
    COALESCE(aud.has_created_by, 0)::BOOLEAN AS has_created_by,
    COALESCE(aud.has_updated_by, 0)::BOOLEAN AS has_updated_by,
    COALESCE(aud.has_is_deleted, 0)::BOOLEAN AS has_is_deleted,
    COALESCE(dt.date_column_count, 0) AS date_column_count
FROM t
LEFT JOIN pk ON pk.object_id = t.object_id
LEFT JOIN aud ON aud.object_id = t.object_id
LEFT JOIN dt ON dt.object_id = t.object_id;

-- Vista: Candidatos a duplicacion de nombre
CREATE OR REPLACE VIEW public."vw_Governance_DuplicateNameCandidates" AS
WITH base AS (
    SELECT c.relname AS table_name, LOWER(c.relname) AS name_lower
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE c.relkind = 'r'
      AND c.relname <> 'sysdiagrams'
      AND c.relname NOT LIKE '%SchemaGovernance%'
      AND n.nspname NOT IN ('pg_catalog', 'information_schema')
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
JOIN norm b ON a.stem = b.stem AND a.table_name < b.table_name;

-- Vista: Similitud de tablas por columnas comunes
CREATE OR REPLACE VIEW public."vw_Governance_TableSimilarityCandidates" AS
WITH cols AS (
    SELECT a.attrelid AS object_id, LOWER(a.attname) AS column_name
    FROM pg_attribute a
    JOIN pg_class c ON c.oid = a.attrelid
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE c.relkind = 'r'
      AND a.attnum > 0
      AND NOT a.attisdropped
      AND c.relname <> 'sysdiagrams'
      AND c.relname NOT LIKE '%SchemaGovernance%'
      AND n.nspname NOT IN ('pg_catalog', 'information_schema')
),
tcols AS (
    SELECT object_id, COUNT(1) AS column_count FROM cols GROUP BY object_id
),
common_cols AS (
    SELECT
        a.object_id AS object_id_a,
        b.object_id AS object_id_b,
        COUNT(1) AS common_count
    FROM cols a
    JOIN cols b ON a.column_name = b.column_name AND a.object_id < b.object_id
    GROUP BY a.object_id, b.object_id
)
SELECT
    ta.relname AS table_a,
    tb.relname AS table_b,
    cc.common_count,
    ca.column_count AS columns_a,
    cb.column_count AS columns_b,
    CAST(
        CASE
            WHEN (ca.column_count + cb.column_count - cc.common_count) = 0 THEN 0
            ELSE (cc.common_count * 1.0) / (ca.column_count + cb.column_count - cc.common_count)
        END
        AS NUMERIC(9,4)
    ) AS similarity_ratio
FROM common_cols cc
JOIN tcols ca ON ca.object_id = cc.object_id_a
JOIN tcols cb ON cb.object_id = cc.object_id_b
JOIN pg_class ta ON ta.oid = cc.object_id_a
JOIN pg_class tb ON tb.oid = cc.object_id_b
WHERE cc.common_count >= 5;

-- Funcion: Capturar snapshot de gobernanza
CREATE OR REPLACE FUNCTION public.usp_governance_capturesnapshot(
    p_notes VARCHAR(500) DEFAULT NULL
)
RETURNS TABLE (
    "Id" BIGINT, "SnapshotAt" TIMESTAMP, "TotalTables" INT, "TablesWithoutPK" INT,
    "TablesWithoutCreatedAt" INT, "TablesWithoutUpdatedAt" INT, "TablesWithoutCreatedBy" INT,
    "TablesWithoutDateColumns" INT, "DuplicateNameCandidatePairs" INT,
    "SimilarityCandidatePairs" INT, "Notes" VARCHAR(500)
)
LANGUAGE plpgsql
AS $fn$
DECLARE
    v_total INT := 0;
    v_no_pk INT := 0;
    v_no_cat INT := 0;
    v_no_uat INT := 0;
    v_no_cby INT := 0;
    v_no_dt INT := 0;
    v_dup INT := 0;
    v_sim INT := 0;
BEGIN
    SELECT
        COUNT(1),
        SUM(CASE WHEN NOT has_pk THEN 1 ELSE 0 END),
        SUM(CASE WHEN NOT has_created_at THEN 1 ELSE 0 END),
        SUM(CASE WHEN NOT has_updated_at THEN 1 ELSE 0 END),
        SUM(CASE WHEN NOT has_created_by THEN 1 ELSE 0 END),
        SUM(CASE WHEN date_column_count = 0 THEN 1 ELSE 0 END)
    INTO v_total, v_no_pk, v_no_cat, v_no_uat, v_no_cby, v_no_dt
    FROM public."vw_Governance_AuditCoverage";

    SELECT COUNT(1) INTO v_dup FROM public."vw_Governance_DuplicateNameCandidates";
    SELECT COUNT(1) INTO v_sim FROM public."vw_Governance_TableSimilarityCandidates" WHERE similarity_ratio >= 0.7000;

    INSERT INTO public."SchemaGovernanceSnapshot" (
        "TotalTables", "TablesWithoutPK", "TablesWithoutCreatedAt", "TablesWithoutUpdatedAt",
        "TablesWithoutCreatedBy", "TablesWithoutDateColumns", "DuplicateNameCandidatePairs",
        "SimilarityCandidatePairs", "Notes"
    ) VALUES (v_total, v_no_pk, v_no_cat, v_no_uat, v_no_cby, v_no_dt, v_dup, v_sim, p_notes);

    RETURN QUERY
    SELECT s.* FROM public."SchemaGovernanceSnapshot" s ORDER BY s."Id" DESC LIMIT 1;
END;
$fn$;
