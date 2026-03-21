-- ============================================================
-- DatqBoxWeb PostgreSQL - usp_sys.sql
-- Funciones de sistema (diagnóstico y utilidades)
-- ============================================================

-- usp_Sys_HealthCheck: verificación rápida de salud
DROP FUNCTION IF EXISTS usp_Sys_HealthCheck() CASCADE;
CREATE OR REPLACE FUNCTION usp_Sys_HealthCheck()
RETURNS TABLE("ok" INT, "serverTime" TIMESTAMP, "dbName" TEXT)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT 1, NOW() AT TIME ZONE 'UTC', current_database()::TEXT;
END;
$$;

-- usp_Sys_GetTableColumns: lista columnas de una tabla
DROP FUNCTION IF EXISTS usp_Sys_GetTableColumns(VARCHAR(20), VARCHAR(128)) CASCADE;
CREATE OR REPLACE FUNCTION usp_Sys_GetTableColumns(
    p_schema_name VARCHAR(20),
    p_table_name  VARCHAR(128)
)
RETURNS TABLE("COLUMN_NAME" VARCHAR)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT c.column_name::VARCHAR
    FROM   information_schema.columns c
    WHERE  c.table_schema = p_schema_name
      AND  c.table_name   = p_table_name
    ORDER BY c.ordinal_position;
END;
$$;

-- usp_Sys_Metadata_Tables: lista de tablas en schemas de aplicacion
DROP FUNCTION IF EXISTS usp_Sys_Metadata_Tables() CASCADE;
CREATE OR REPLACE FUNCTION usp_Sys_Metadata_Tables()
RETURNS TABLE(
    "TABLE_SCHEMA" VARCHAR,
    "TABLE_NAME"   VARCHAR
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        t.table_schema::VARCHAR,
        t.table_name::VARCHAR
    FROM information_schema.tables t
    WHERE t.table_schema IN (
        'public', 'cfg', 'sec', 'master', 'doc', 'ar', 'ap',
        'acct', 'pay', 'pos', 'rest', 'hr', 'fin', 'store'
    )
      AND t.table_type = 'BASE TABLE'
    ORDER BY t.table_schema, t.table_name;
END;
$$;

-- usp_Sys_Metadata_Columns: lista de columnas con metadata de identidad y generacion
DROP FUNCTION IF EXISTS usp_Sys_Metadata_Columns() CASCADE;
CREATE OR REPLACE FUNCTION usp_Sys_Metadata_Columns()
RETURNS TABLE(
    "TABLE_SCHEMA" VARCHAR,
    "TABLE_NAME"   VARCHAR,
    "COLUMN_NAME"  VARCHAR,
    "DATA_TYPE"    VARCHAR,
    "IS_NULLABLE"  VARCHAR,
    "is_identity"  INT,
    "is_computed"  INT
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        c.table_schema::VARCHAR,
        c.table_name::VARCHAR,
        c.column_name::VARCHAR,
        c.data_type::VARCHAR,
        c.is_nullable::VARCHAR,
        CASE WHEN c.identity_generation IS NOT NULL THEN 1 ELSE 0 END::INT,
        CASE WHEN c.is_generated = 'ALWAYS' AND c.identity_generation IS NULL THEN 1 ELSE 0 END::INT
    FROM information_schema.columns c
    WHERE c.table_schema IN (
        'public', 'cfg', 'sec', 'master', 'doc', 'ar', 'ap',
        'acct', 'pay', 'pos', 'rest', 'hr', 'fin', 'store'
    )
    ORDER BY c.table_schema, c.table_name, c.ordinal_position;
END;
$$;

-- usp_Sys_Metadata_PrimaryKeys: claves primarias de tablas en schemas de aplicacion
DROP FUNCTION IF EXISTS usp_Sys_Metadata_PrimaryKeys() CASCADE;
CREATE OR REPLACE FUNCTION usp_Sys_Metadata_PrimaryKeys()
RETURNS TABLE(
    "TABLE_SCHEMA"     VARCHAR,
    "TABLE_NAME"       VARCHAR,
    "COLUMN_NAME"      VARCHAR,
    "ORDINAL_POSITION" INT
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        tc.table_schema::VARCHAR,
        tc.table_name::VARCHAR,
        kcu.column_name::VARCHAR,
        kcu.ordinal_position::INT
    FROM information_schema.table_constraints tc
    INNER JOIN information_schema.key_column_usage kcu
        ON kcu.constraint_name = tc.constraint_name
       AND kcu.table_schema    = tc.table_schema
       AND kcu.table_name      = tc.table_name
    WHERE tc.constraint_type = 'PRIMARY KEY'
      AND tc.table_schema IN (
        'public', 'cfg', 'sec', 'master', 'doc', 'ar', 'ap',
        'acct', 'pay', 'pos', 'rest', 'hr', 'fin', 'store'
      )
    ORDER BY tc.table_schema, tc.table_name, kcu.ordinal_position;
END;
$$;
