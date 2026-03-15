-- ============================================================
-- DatqBoxWeb PostgreSQL - usp_sys.sql
-- Funciones de sistema (diagnóstico y utilidades)
-- ============================================================

-- usp_Sys_HealthCheck: verificación rápida de salud
CREATE OR REPLACE FUNCTION usp_Sys_HealthCheck()
RETURNS TABLE("ok" INT, "serverTime" TIMESTAMP, "dbName" TEXT)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT 1, NOW() AT TIME ZONE 'UTC', current_database()::TEXT;
END;
$$;

-- usp_Sys_GetTableColumns: lista columnas de una tabla
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
