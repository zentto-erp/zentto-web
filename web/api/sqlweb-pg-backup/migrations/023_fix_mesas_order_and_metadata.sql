-- =============================================================================
--  MigraciÃƒÂ³n 023: Fix mesas ORDER BY seguro + metadata functions para CRUD
--  1. usp_rest_diningtable_list: ORDER BY seguro (TableNumber no siempre numÃƒÂ©rico)
--  2. usp_Sys_Metadata_Tables/Columns/PrimaryKeys: necesarios para CRUD admin PG
-- =============================================================================

\echo '  [023] Fix ORDER BY seguro en usp_rest_diningtable_list...'

DROP FUNCTION IF EXISTS usp_rest_diningtable_list(INT, INT, VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS usp_rest_diningtable_list(INT, INT, VARCHAR(50)) CASCADE;
CREATE OR REPLACE FUNCTION usp_rest_diningtable_list(
    p_company_id  INT,
    p_branch_id   INT,
    p_ambiente_id VARCHAR DEFAULT NULL
)
RETURNS TABLE(
    "id" BIGINT, "numero" VARCHAR, "nombre" VARCHAR, "capacidad" INT,
    "ambienteId" VARCHAR, "ambiente" VARCHAR,
    "posicionX" NUMERIC, "posicionY" NUMERIC, "estado" VARCHAR
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        dt."DiningTableId",
        dt."TableNumber",
        COALESCE(NULLIF(dt."TableName", ''), 'Mesa ' || dt."TableNumber")::VARCHAR,
        dt."Capacity",
        dt."EnvironmentCode",
        dt."EnvironmentName",
        dt."PositionX"::NUMERIC,
        dt."PositionY"::NUMERIC,
        CASE
            WHEN EXISTS (
                SELECT 1 FROM rest."OrderTicket" o
                WHERE o."CompanyId" = dt."CompanyId" AND o."BranchId" = dt."BranchId"
                  AND o."TableNumber" = dt."TableNumber" AND o."Status" IN ('OPEN', 'SENT')
            ) THEN 'ocupada'::VARCHAR
            ELSE 'libre'::VARCHAR
        END
    FROM rest."DiningTable" dt
    WHERE dt."CompanyId" = p_company_id AND dt."BranchId" = p_branch_id AND dt."IsActive" = TRUE
      AND (p_ambiente_id IS NULL OR dt."EnvironmentCode" = p_ambiente_id)
    ORDER BY
        dt."EnvironmentCode" NULLS LAST,
        CASE WHEN dt."TableNumber" ~ '^[0-9]+$' THEN dt."TableNumber"::INT ELSE 9999 END,
        dt."TableNumber";
END;
$$;

GRANT EXECUTE ON FUNCTION usp_rest_diningtable_list(INT, INT, VARCHAR) TO zentto_app;

\echo '  [023] Agregando usp_Sys_Metadata_Tables para CRUD admin...'

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

GRANT EXECUTE ON FUNCTION usp_Sys_Metadata_Tables() TO zentto_app;

\echo '  [023] Agregando usp_Sys_Metadata_Columns...'

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

GRANT EXECUTE ON FUNCTION usp_Sys_Metadata_Columns() TO zentto_app;

\echo '  [023] Agregando usp_Sys_Metadata_PrimaryKeys...'

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

GRANT EXECUTE ON FUNCTION usp_Sys_Metadata_PrimaryKeys() TO zentto_app;

\echo '  [023] Registrando migraciÃƒÂ³n...'
INSERT INTO public._migrations (name, applied_at)
VALUES ('023_fix_mesas_order_and_metadata', NOW() AT TIME ZONE 'UTC')
ON CONFLICT (name) DO NOTHING;

\echo '  [023] COMPLETO Ã¢â‚¬â€ ORDER BY mesas seguro + metadata functions PG'
