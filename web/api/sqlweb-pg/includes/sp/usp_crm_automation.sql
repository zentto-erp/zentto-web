-- ============================================================
-- DatqBoxWeb PostgreSQL - usp_crm_automation.sql
-- Funciones de automatizacion del modulo CRM
-- Fecha: 2026-03-23
-- ============================================================

-- ============================================================
-- Tabla crm."AutomationRule" (reglas de automatizacion)
-- ============================================================
CREATE TABLE IF NOT EXISTS crm."AutomationRule" (
    "RuleId" BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    "CompanyId" INT NOT NULL,
    "RuleName" VARCHAR(200) NOT NULL,
    "TriggerEvent" VARCHAR(50) NOT NULL, -- LEAD_STALE, STAGE_CHANGE, NO_ACTIVITY, SCORE_BELOW, LEAD_CREATED
    "ConditionJson" JSONB DEFAULT '{}', -- {"days_stale": 7, "score_threshold": 30, "stage_id": null}
    "ActionType" VARCHAR(50) NOT NULL, -- NOTIFY, ASSIGN, MOVE_STAGE, CREATE_ACTIVITY, SEND_EMAIL
    "ActionConfig" JSONB DEFAULT '{}', -- {"notify_user_id": 5, "message": "Lead estancado", "template": "stale_lead"}
    "IsActive" BOOLEAN NOT NULL DEFAULT TRUE,
    "SortOrder" INT NOT NULL DEFAULT 0,
    "CreatedAt" TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "UpdatedAt" TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "CreatedByUserId" INT NULL,
    "IsDeleted" BOOLEAN NOT NULL DEFAULT FALSE
);
CREATE INDEX IF NOT EXISTS "IX_crm_AutomationRule_Company" ON crm."AutomationRule"("CompanyId", "IsActive") WHERE "IsDeleted" = FALSE;

-- ============================================================
-- Tabla crm."AutomationLog" (log de ejecuciones)
-- ============================================================
CREATE TABLE IF NOT EXISTS crm."AutomationLog" (
    "LogId" BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    "RuleId" BIGINT NOT NULL REFERENCES crm."AutomationRule"("RuleId"),
    "LeadId" BIGINT REFERENCES crm."Lead"("LeadId"),
    "ActionTaken" VARCHAR(50) NOT NULL,
    "ActionResult" TEXT,
    "ExecutedAt" TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC')
);
CREATE INDEX IF NOT EXISTS "IX_crm_AutomationLog_Rule" ON crm."AutomationLog"("RuleId", "ExecutedAt" DESC);

-- =============================================================================
--  usp_CRM_Automation_List
--  Lista reglas de automatizacion activas de una empresa
-- =============================================================================
DROP FUNCTION IF EXISTS usp_crm_automation_list(INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_crm_automation_list(
    p_company_id  INT
)
RETURNS TABLE(
    "RuleId"        BIGINT,
    "RuleName"      VARCHAR,
    "TriggerEvent"  VARCHAR,
    "ConditionJson" JSONB,
    "ActionType"    VARCHAR,
    "ActionConfig"  JSONB,
    "IsActive"      BOOLEAN,
    "SortOrder"     INT,
    "CreatedAt"     TIMESTAMP
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        r."RuleId",
        r."RuleName"::VARCHAR,
        r."TriggerEvent"::VARCHAR,
        r."ConditionJson",
        r."ActionType"::VARCHAR,
        r."ActionConfig",
        r."IsActive",
        r."SortOrder",
        r."CreatedAt"
    FROM   crm."AutomationRule" r
    WHERE  r."CompanyId" = p_company_id
      AND  r."IsDeleted" = FALSE
    ORDER BY r."SortOrder";
END;
$$;

-- =============================================================================
--  usp_CRM_Automation_Upsert
--  Crea o actualiza una regla de automatizacion
-- =============================================================================
DROP FUNCTION IF EXISTS usp_crm_automation_upsert(INT, INT, VARCHAR, VARCHAR, JSONB, VARCHAR, JSONB, BOOLEAN, INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_crm_automation_upsert(
    p_company_id     INT,
    p_rule_id        INT DEFAULT NULL,
    p_rule_name      VARCHAR DEFAULT ''::VARCHAR,
    p_trigger_event  VARCHAR DEFAULT ''::VARCHAR,
    p_condition_json JSONB DEFAULT '{}'::JSONB,
    p_action_type    VARCHAR DEFAULT ''::VARCHAR,
    p_action_config  JSONB DEFAULT '{}'::JSONB,
    p_is_active      BOOLEAN DEFAULT TRUE,
    p_sort_order     INT DEFAULT 0,
    p_user_id        INT DEFAULT NULL
)
RETURNS TABLE(
    "ok"      INT,
    "mensaje" VARCHAR,
    "RuleId"  BIGINT
)
LANGUAGE plpgsql AS $$
DECLARE
    v_now     TIMESTAMP := NOW() AT TIME ZONE 'UTC';
    v_rule_id BIGINT;
BEGIN
    IF p_rule_id IS NOT NULL AND p_rule_id > 0 THEN
        -- UPDATE
        UPDATE crm."AutomationRule"
        SET    "RuleName"      = p_rule_name,
               "TriggerEvent"  = p_trigger_event,
               "ConditionJson" = p_condition_json,
               "ActionType"    = p_action_type,
               "ActionConfig"  = p_action_config,
               "IsActive"      = p_is_active,
               "SortOrder"     = p_sort_order,
               "UpdatedAt"     = v_now
        WHERE  "RuleId" = p_rule_id
          AND  "CompanyId" = p_company_id
          AND  "IsDeleted" = FALSE;

        IF NOT FOUND THEN
            RETURN QUERY SELECT 0, 'Regla no encontrada'::VARCHAR, 0::BIGINT;
            RETURN;
        END IF;

        v_rule_id := p_rule_id::BIGINT;
        RETURN QUERY SELECT 1, 'Regla actualizada correctamente'::VARCHAR, v_rule_id;
    ELSE
        -- INSERT
        INSERT INTO crm."AutomationRule" (
            "CompanyId", "RuleName", "TriggerEvent", "ConditionJson",
            "ActionType", "ActionConfig", "IsActive", "SortOrder",
            "CreatedAt", "UpdatedAt", "CreatedByUserId"
        )
        VALUES (
            p_company_id, p_rule_name, p_trigger_event, p_condition_json,
            p_action_type, p_action_config, p_is_active, p_sort_order,
            v_now, v_now, p_user_id
        )
        RETURNING crm."AutomationRule"."RuleId" INTO v_rule_id;

        RETURN QUERY SELECT 1, 'Regla creada correctamente'::VARCHAR, v_rule_id;
    END IF;
EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT 0, ('Error: ' || SQLERRM)::VARCHAR, 0::BIGINT;
END;
$$;

-- =============================================================================
--  usp_CRM_Automation_Delete
--  Soft delete de una regla de automatizacion
-- =============================================================================
DROP FUNCTION IF EXISTS usp_crm_automation_delete(BIGINT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_crm_automation_delete(
    p_rule_id  BIGINT,
    p_user_id  INT DEFAULT NULL
)
RETURNS TABLE(
    "ok"      INT,
    "mensaje" VARCHAR
)
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE crm."AutomationRule"
    SET    "IsDeleted" = TRUE,
           "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
    WHERE  "RuleId" = p_rule_id
      AND  "IsDeleted" = FALSE;

    IF NOT FOUND THEN
        RETURN QUERY SELECT 0, 'Regla no encontrada'::VARCHAR;
        RETURN;
    END IF;

    RETURN QUERY SELECT 1, 'Regla eliminada correctamente'::VARCHAR;
END;
$$;

-- =============================================================================
--  usp_CRM_Lead_FindStale
--  Encuentra leads OPEN cuya ultima actividad (o cambio de etapa)
--  fue hace mas de p_days dias
-- =============================================================================
DROP FUNCTION IF EXISTS usp_crm_lead_findstale(INT, INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_crm_lead_findstale(
    p_company_id   INT,
    p_days         INT DEFAULT 7,
    p_pipeline_id  INT DEFAULT NULL
)
RETURNS TABLE(
    "LeadId"                BIGINT,
    "LeadCode"              VARCHAR,
    "ContactName"           VARCHAR,
    "CompanyName"           VARCHAR,
    "StageName"             VARCHAR,
    "EstimatedValue"        NUMERIC,
    "DaysSinceLastActivity" INT,
    "AssignedToName"        VARCHAR
)
LANGUAGE plpgsql AS $$
DECLARE
    v_now TIMESTAMP := NOW() AT TIME ZONE 'UTC';
BEGIN
    RETURN QUERY
    WITH last_touch AS (
        -- Ultima actividad o cambio de etapa por lead (lo mas reciente)
        SELECT
            l."LeadId",
            GREATEST(
                COALESCE((
                    SELECT MAX(a."CreatedAt")
                    FROM   crm."Activity" a
                    WHERE  a."LeadId" = l."LeadId" AND a."IsDeleted" = FALSE
                ), l."CreatedAt"),
                COALESCE((
                    SELECT MAX(h."CreatedAt")
                    FROM   crm."LeadHistory" h
                    WHERE  h."LeadId" = l."LeadId" AND h."ChangeType" = 'STAGE_CHANGE'
                ), l."CreatedAt")
            ) AS last_touch_at
        FROM crm."Lead" l
        WHERE l."CompanyId" = p_company_id
          AND l."IsDeleted" = FALSE
          AND l."Status" = 'OPEN'
          AND (p_pipeline_id IS NULL OR l."PipelineId" = p_pipeline_id)
    )
    SELECT
        l."LeadId",
        l."LeadCode"::VARCHAR,
        l."ContactName"::VARCHAR,
        l."CompanyName"::VARCHAR,
        s."StageName"::VARCHAR,
        l."EstimatedValue"::NUMERIC,
        (EXTRACT(EPOCH FROM (v_now - lt.last_touch_at)) / 86400)::INT AS "DaysSinceLastActivity",
        COALESCE(u."FullName", 'Sin asignar')::VARCHAR                AS "AssignedToName"
    FROM   crm."Lead" l
    JOIN   last_touch lt          ON lt."LeadId" = l."LeadId"
    JOIN   crm."PipelineStage" s  ON s."StageId" = l."StageId"
    LEFT JOIN sec."User" u        ON u."UserId" = l."AssignedToUserId"
    WHERE  l."CompanyId" = p_company_id
      AND  l."IsDeleted" = FALSE
      AND  l."Status" = 'OPEN'
      AND  (p_pipeline_id IS NULL OR l."PipelineId" = p_pipeline_id)
      AND  (EXTRACT(EPOCH FROM (v_now - lt.last_touch_at)) / 86400)::INT >= p_days
    ORDER BY (EXTRACT(EPOCH FROM (v_now - lt.last_touch_at)) / 86400)::INT DESC;
END;
$$;

-- =============================================================================
--  usp_CRM_Automation_LogAction
--  Registra la ejecucion de una accion de automatizacion
-- =============================================================================
DROP FUNCTION IF EXISTS usp_crm_automation_logaction(BIGINT, BIGINT, VARCHAR, TEXT) CASCADE;
CREATE OR REPLACE FUNCTION usp_crm_automation_logaction(
    p_rule_id       BIGINT,
    p_lead_id       BIGINT,
    p_action_taken  VARCHAR,
    p_action_result TEXT DEFAULT NULL
)
RETURNS TABLE(
    "ok"      INT,
    "mensaje" VARCHAR
)
LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO crm."AutomationLog" (
        "RuleId", "LeadId", "ActionTaken", "ActionResult", "ExecutedAt"
    )
    VALUES (
        p_rule_id, p_lead_id, p_action_taken, p_action_result, NOW() AT TIME ZONE 'UTC'
    );

    RETURN QUERY SELECT 1, 'Accion registrada correctamente'::VARCHAR;
EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT 0, ('Error: ' || SQLERRM)::VARCHAR;
END;
$$;

-- =============================================================================
--  usp_CRM_Automation_GetLogs
--  Consulta el log de ejecuciones de automatizaciones
-- =============================================================================
DROP FUNCTION IF EXISTS usp_crm_automation_getlogs(BIGINT, BIGINT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_crm_automation_getlogs(
    p_rule_id  BIGINT DEFAULT NULL,
    p_lead_id  BIGINT DEFAULT NULL,
    p_limit    INT DEFAULT 50
)
RETURNS TABLE(
    "LogId"        BIGINT,
    "RuleId"       BIGINT,
    "RuleName"     VARCHAR,
    "LeadId"       BIGINT,
    "LeadCode"     VARCHAR,
    "ActionTaken"  VARCHAR,
    "ActionResult" TEXT,
    "ExecutedAt"   TIMESTAMP
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        al."LogId",
        al."RuleId",
        r."RuleName"::VARCHAR,
        al."LeadId",
        COALESCE(l."LeadCode", ''::VARCHAR)::VARCHAR AS "LeadCode",
        al."ActionTaken"::VARCHAR,
        al."ActionResult",
        al."ExecutedAt"
    FROM   crm."AutomationLog" al
    JOIN   crm."AutomationRule" r ON r."RuleId" = al."RuleId"
    LEFT JOIN crm."Lead" l        ON l."LeadId" = al."LeadId"
    WHERE  (p_rule_id IS NULL OR al."RuleId" = p_rule_id)
      AND  (p_lead_id IS NULL OR al."LeadId" = p_lead_id)
    ORDER BY al."ExecutedAt" DESC
    LIMIT p_limit;
END;
$$;
