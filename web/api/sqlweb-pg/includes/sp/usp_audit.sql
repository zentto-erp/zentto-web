-- ============================================================
-- DatqBoxWeb PostgreSQL - usp_audit.sql
-- Funciones de auditoria: insercion de logs, consultas paginadas,
-- detalle individual, dashboard de resumen y listado de registros fiscales.
-- Traducido de SQL Server stored procedures a PL/pgSQL.
-- ============================================================

-- ============================================================================
--  Schema: audit
-- ============================================================================
CREATE SCHEMA IF NOT EXISTS audit;

-- ============================================================================
--  Tabla: audit."AuditLog"
-- ============================================================================
CREATE TABLE IF NOT EXISTS audit."AuditLog" (
    "AuditLogId"    BIGSERIAL PRIMARY KEY,
    "CompanyId"     INT NOT NULL,
    "BranchId"      INT NOT NULL,
    "UserId"        INT NULL,
    "UserName"      VARCHAR(100) NULL,
    "ModuleName"    VARCHAR(50) NOT NULL,
    "EntityName"    VARCHAR(100) NOT NULL,
    "EntityId"      VARCHAR(50) NULL,
    "ActionType"    VARCHAR(10) NOT NULL,       -- CREATE, UPDATE, DELETE, VOID, LOGIN
    "Summary"       VARCHAR(500) NULL,
    "OldValues"     TEXT NULL,
    "NewValues"     TEXT NULL,
    "IpAddress"     VARCHAR(50) NULL,
    "CreatedAt"     TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC')
);

CREATE INDEX IF NOT EXISTS "IX_AuditLog_Company_Date"
    ON audit."AuditLog"("CompanyId", "BranchId", "CreatedAt" DESC);

CREATE INDEX IF NOT EXISTS "IX_AuditLog_Module"
    ON audit."AuditLog"("ModuleName", "CreatedAt" DESC);

CREATE INDEX IF NOT EXISTS "IX_AuditLog_User"
    ON audit."AuditLog"("UserName", "CreatedAt" DESC);

-- =============================================================================
--  SP 1: usp_Audit_Log_Insert
--  Inserta un registro en audit."AuditLog" y retorna el "AuditLogId" generado.
-- =============================================================================
DROP FUNCTION IF EXISTS usp_Audit_Log_Insert(INT, INT, INT, VARCHAR(100), VARCHAR(50), VARCHAR(100), VARCHAR(50), VARCHAR(10), VARCHAR(500), TEXT, TEXT, VARCHAR(50)) CASCADE;
CREATE OR REPLACE FUNCTION usp_Audit_Log_Insert(
    p_company_id    INT,
    p_branch_id     INT,
    p_user_id       INT            DEFAULT NULL,
    p_user_name     VARCHAR(100)   DEFAULT NULL,
    p_module_name   VARCHAR(50)    DEFAULT NULL,
    p_entity_name   VARCHAR(100)   DEFAULT NULL,
    p_entity_id     VARCHAR(50)    DEFAULT NULL,
    p_action_type   VARCHAR(10)    DEFAULT NULL,
    p_summary       VARCHAR(500)   DEFAULT NULL,
    p_old_values    TEXT           DEFAULT NULL,
    p_new_values    TEXT           DEFAULT NULL,
    p_ip_address    VARCHAR(50)    DEFAULT NULL
)
RETURNS TABLE("AuditLogId" BIGINT)
LANGUAGE plpgsql AS $$
DECLARE
    v_id BIGINT;
BEGIN
    INSERT INTO audit."AuditLog" (
        "CompanyId", "BranchId", "UserId", "UserName",
        "ModuleName", "EntityName", "EntityId", "ActionType",
        "Summary", "OldValues", "NewValues", "IpAddress"
    )
    VALUES (
        p_company_id, p_branch_id, p_user_id, p_user_name,
        p_module_name, p_entity_name, p_entity_id, p_action_type,
        p_summary, p_old_values, p_new_values, p_ip_address
    )
    RETURNING audit."AuditLog"."AuditLogId" INTO v_id;

    RETURN QUERY SELECT v_id;
END;
$$;

-- =============================================================================
--  SP 2: usp_Audit_Log_List
--  Retorna lista paginada de registros de auditoria con filtros opcionales.
--  Nota: En PG retornamos una sola tabla; el TotalCount se incluye como columna.
-- =============================================================================
DROP FUNCTION IF EXISTS usp_Audit_Log_List(INT, INT, DATE, DATE, VARCHAR(50), VARCHAR(100), VARCHAR(10), VARCHAR(100), VARCHAR(200), INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_Audit_Log_List(
    p_company_id    INT,
    p_branch_id     INT,
    p_fecha_desde   DATE           DEFAULT NULL,
    p_fecha_hasta   DATE           DEFAULT NULL,
    p_module_name   VARCHAR(50)    DEFAULT NULL,
    p_user_name     VARCHAR(100)   DEFAULT NULL,
    p_action_type   VARCHAR(10)    DEFAULT NULL,
    p_entity_name   VARCHAR(100)   DEFAULT NULL,
    p_search        VARCHAR(200)   DEFAULT NULL,
    p_page          INT            DEFAULT 1,
    p_limit         INT            DEFAULT 50
)
RETURNS TABLE(
    "TotalCount"  BIGINT,
    "AuditLogId"  BIGINT,
    "CompanyId"   INT,
    "BranchId"    INT,
    "UserId"      INT,
    "UserName"    VARCHAR(100),
    "ModuleName"  VARCHAR(50),
    "EntityName"  VARCHAR(100),
    "EntityId"    VARCHAR(50),
    "ActionType"  VARCHAR(10),
    "Summary"     VARCHAR(500),
    "IpAddress"   VARCHAR(50),
    "CreatedAt"   TIMESTAMP
)
LANGUAGE plpgsql AS $$
DECLARE
    v_page   INT := GREATEST(p_page, 1);
    v_limit  INT := GREATEST(LEAST(p_limit, 500), 1);
    v_offset INT := (v_page - 1) * v_limit;
    v_total  BIGINT;
BEGIN
    -- Calcular total
    SELECT COUNT(*)
    INTO   v_total
    FROM   audit."AuditLog" a
    WHERE  a."CompanyId" = p_company_id
      AND  a."BranchId"  = p_branch_id
      AND  (p_fecha_desde IS NULL OR a."CreatedAt"::DATE >= p_fecha_desde)
      AND  (p_fecha_hasta IS NULL OR a."CreatedAt"::DATE <= p_fecha_hasta)
      AND  (p_module_name IS NULL OR a."ModuleName" = p_module_name)
      AND  (p_user_name   IS NULL OR a."UserName"   = p_user_name)
      AND  (p_action_type IS NULL OR a."ActionType" = p_action_type)
      AND  (p_entity_name IS NULL OR a."EntityName" = p_entity_name)
      AND  (p_search      IS NULL OR a."Summary" LIKE '%' || p_search || '%');

    RETURN QUERY
    SELECT v_total,
           a."AuditLogId",
           a."CompanyId",
           a."BranchId",
           a."UserId",
           a."UserName",
           a."ModuleName",
           a."EntityName",
           a."EntityId",
           a."ActionType",
           a."Summary",
           a."IpAddress",
           a."CreatedAt"
    FROM   audit."AuditLog" a
    WHERE  a."CompanyId" = p_company_id
      AND  a."BranchId"  = p_branch_id
      AND  (p_fecha_desde IS NULL OR a."CreatedAt"::DATE >= p_fecha_desde)
      AND  (p_fecha_hasta IS NULL OR a."CreatedAt"::DATE <= p_fecha_hasta)
      AND  (p_module_name IS NULL OR a."ModuleName" = p_module_name)
      AND  (p_user_name   IS NULL OR a."UserName"   = p_user_name)
      AND  (p_action_type IS NULL OR a."ActionType" = p_action_type)
      AND  (p_entity_name IS NULL OR a."EntityName" = p_entity_name)
      AND  (p_search      IS NULL OR a."Summary" LIKE '%' || p_search || '%')
    ORDER BY a."CreatedAt" DESC
    LIMIT v_limit OFFSET v_offset;
END;
$$;

-- =============================================================================
--  SP 3: usp_Audit_Log_GetById
--  Retorna el registro completo de auditoria incluyendo OldValues y NewValues.
-- =============================================================================
DROP FUNCTION IF EXISTS usp_Audit_Log_GetById(BIGINT) CASCADE;
CREATE OR REPLACE FUNCTION usp_Audit_Log_GetById(
    p_audit_log_id  BIGINT
)
RETURNS TABLE(
    "AuditLogId"  BIGINT,
    "CompanyId"   INT,
    "BranchId"    INT,
    "UserId"      INT,
    "UserName"    VARCHAR(100),
    "ModuleName"  VARCHAR(50),
    "EntityName"  VARCHAR(100),
    "EntityId"    VARCHAR(50),
    "ActionType"  VARCHAR(10),
    "Summary"     VARCHAR(500),
    "OldValues"   TEXT,
    "NewValues"   TEXT,
    "IpAddress"   VARCHAR(50),
    "CreatedAt"   TIMESTAMP
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT a."AuditLogId",
           a."CompanyId",
           a."BranchId",
           a."UserId",
           a."UserName",
           a."ModuleName",
           a."EntityName",
           a."EntityId",
           a."ActionType",
           a."Summary",
           a."OldValues",
           a."NewValues",
           a."IpAddress",
           a."CreatedAt"
    FROM   audit."AuditLog" a
    WHERE  a."AuditLogId" = p_audit_log_id;
END;
$$;

-- =============================================================================
--  SP 4: usp_Audit_Dashboard_Resumen
--  Dashboard de auditoria. Retorna totales generales, top modulos y ultimos logs.
--  Nota: En PG retornamos 3 funciones separadas para los 3 recordsets.
-- =============================================================================

-- 4a. Totales generales
DROP FUNCTION IF EXISTS usp_Audit_Dashboard_Totales(INT, INT, DATE, DATE) CASCADE;
CREATE OR REPLACE FUNCTION usp_Audit_Dashboard_Totales(
    p_company_id    INT,
    p_branch_id     INT,
    p_fecha_desde   DATE,
    p_fecha_hasta   DATE
)
RETURNS TABLE(
    "totalLogs"       BIGINT,
    "totalCreates"    BIGINT,
    "totalUpdates"    BIGINT,
    "totalDeletes"    BIGINT,
    "totalVoids"      BIGINT,
    "totalLogins"     BIGINT,
    "logsUltimas24h"  BIGINT
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        COUNT(*)                                                           AS "totalLogs",
        SUM(CASE WHEN a."ActionType" = 'CREATE' THEN 1 ELSE 0 END)::BIGINT AS "totalCreates",
        SUM(CASE WHEN a."ActionType" = 'UPDATE' THEN 1 ELSE 0 END)::BIGINT AS "totalUpdates",
        SUM(CASE WHEN a."ActionType" = 'DELETE' THEN 1 ELSE 0 END)::BIGINT AS "totalDeletes",
        SUM(CASE WHEN a."ActionType" = 'VOID'   THEN 1 ELSE 0 END)::BIGINT AS "totalVoids",
        SUM(CASE WHEN a."ActionType" = 'LOGIN'  THEN 1 ELSE 0 END)::BIGINT AS "totalLogins",
        SUM(CASE WHEN a."CreatedAt" >= (NOW() AT TIME ZONE 'UTC') - INTERVAL '24 hours'
                 THEN 1 ELSE 0 END)::BIGINT                                AS "logsUltimas24h"
    FROM   audit."AuditLog" a
    WHERE  a."CompanyId" = p_company_id
      AND  a."BranchId"  = p_branch_id
      AND  a."CreatedAt"::DATE >= p_fecha_desde
      AND  a."CreatedAt"::DATE <= p_fecha_hasta;
END;
$$;

-- 4b. Top 10 modulos con mayor actividad
DROP FUNCTION IF EXISTS usp_Audit_Dashboard_TopModulos(INT, INT, DATE, DATE) CASCADE;
CREATE OR REPLACE FUNCTION usp_Audit_Dashboard_TopModulos(
    p_company_id    INT,
    p_branch_id     INT,
    p_fecha_desde   DATE,
    p_fecha_hasta   DATE
)
RETURNS TABLE(
    "ModuleName"  VARCHAR(50),
    "Total"       BIGINT
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT a."ModuleName",
           COUNT(*) AS "Total"
    FROM   audit."AuditLog" a
    WHERE  a."CompanyId" = p_company_id
      AND  a."BranchId"  = p_branch_id
      AND  a."CreatedAt"::DATE >= p_fecha_desde
      AND  a."CreatedAt"::DATE <= p_fecha_hasta
    GROUP BY a."ModuleName"
    ORDER BY "Total" DESC
    LIMIT 10;
END;
$$;

-- 4c. Ultimos 10 registros de auditoria
DROP FUNCTION IF EXISTS usp_Audit_Dashboard_UltimosLogs(INT, INT, DATE, DATE) CASCADE;
CREATE OR REPLACE FUNCTION usp_Audit_Dashboard_UltimosLogs(
    p_company_id    INT,
    p_branch_id     INT,
    p_fecha_desde   DATE,
    p_fecha_hasta   DATE
)
RETURNS TABLE(
    "AuditLogId"  BIGINT,
    "CreatedAt"   TIMESTAMP,
    "UserName"    VARCHAR(100),
    "ModuleName"  VARCHAR(50),
    "ActionType"  VARCHAR(10),
    "EntityName"  VARCHAR(100),
    "Summary"     VARCHAR(500)
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT a."AuditLogId",
           a."CreatedAt",
           a."UserName",
           a."ModuleName",
           a."ActionType",
           a."EntityName",
           a."Summary"
    FROM   audit."AuditLog" a
    WHERE  a."CompanyId" = p_company_id
      AND  a."BranchId"  = p_branch_id
      AND  a."CreatedAt"::DATE >= p_fecha_desde
      AND  a."CreatedAt"::DATE <= p_fecha_hasta
    ORDER BY a."CreatedAt" DESC
    LIMIT 10;
END;
$$;

-- =============================================================================
--  SP 5: usp_Audit_FiscalRecord_List
--  Lista paginada de registros fiscales desde fiscal."Record".
--  Si la tabla no existe, retorna conjunto vacio.
-- =============================================================================
DROP FUNCTION IF EXISTS usp_Audit_FiscalRecord_List(INT, INT, DATE, DATE, INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_Audit_FiscalRecord_List(
    p_company_id    INT,
    p_branch_id     INT,
    p_fecha_desde   DATE           DEFAULT NULL,
    p_fecha_hasta   DATE           DEFAULT NULL,
    p_page          INT            DEFAULT 1,
    p_limit         INT            DEFAULT 50
)
RETURNS TABLE(
    "TotalCount"       BIGINT,
    "FiscalRecordId"   INT,
    "InvoiceId"        INT,
    "InvoiceNumber"    VARCHAR(50),
    "InvoiceDate"      DATE,
    "InvoiceType"      VARCHAR(20),
    "RecordHash"       VARCHAR(64),
    "SentToAuthority"  BOOLEAN,
    "AuthorityStatus"  VARCHAR(50),
    "CountryCode"      VARCHAR(3),
    "CreatedAt"        TIMESTAMP
)
LANGUAGE plpgsql AS $$
DECLARE
    v_page   INT := GREATEST(p_page, 1);
    v_limit  INT := GREATEST(LEAST(p_limit, 500), 1);
    v_offset INT := (v_page - 1) * v_limit;
    v_total  BIGINT;
    v_table_exists BOOLEAN;
BEGIN
    -- Verificar si existe la tabla fiscal."Record"
    SELECT EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = 'fiscal' AND table_name = 'Record'
    ) INTO v_table_exists;

    IF NOT v_table_exists THEN
        -- Retornar conjunto vacio
        RETURN;
    END IF;

    -- Calcular total
    EXECUTE format(
        'SELECT COUNT(*) FROM fiscal."Record" WHERE "CompanyId" = $1 AND "BranchId" = $2'
        || CASE WHEN p_fecha_desde IS NOT NULL THEN ' AND "CreatedAt"::DATE >= $3' ELSE '' END
        || CASE WHEN p_fecha_hasta IS NOT NULL THEN ' AND "CreatedAt"::DATE <= $4' ELSE '' END
    )
    INTO v_total
    USING p_company_id, p_branch_id, p_fecha_desde, p_fecha_hasta;

    -- Retornar registros paginados
    RETURN QUERY EXECUTE format(
        'SELECT $5::BIGINT AS "TotalCount",'
        || ' "FiscalRecordId", "InvoiceId", "InvoiceNumber"::VARCHAR(50),'
        || ' "InvoiceDate"::DATE, "InvoiceType"::VARCHAR(20),'
        || ' "RecordHash"::VARCHAR(64), "SentToAuthority"::BOOLEAN,'
        || ' "AuthorityStatus"::VARCHAR(50), "CountryCode"::VARCHAR(3), "CreatedAt"'
        || ' FROM fiscal."Record"'
        || ' WHERE "CompanyId" = $1 AND "BranchId" = $2'
        || CASE WHEN p_fecha_desde IS NOT NULL THEN ' AND "CreatedAt"::DATE >= $3' ELSE '' END
        || CASE WHEN p_fecha_hasta IS NOT NULL THEN ' AND "CreatedAt"::DATE <= $4' ELSE '' END
        || ' ORDER BY "CreatedAt" DESC'
        || ' LIMIT $6 OFFSET $7'
    )
    USING p_company_id, p_branch_id, p_fecha_desde, p_fecha_hasta, v_total, v_limit, v_offset;
END;
$$;
