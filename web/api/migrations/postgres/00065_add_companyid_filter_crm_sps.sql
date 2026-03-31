-- +goose Up
-- Migracion: Agregar filtro p_company_id a funciones CRM que no lo tenian
-- Tablas con CompanyId directo: Lead, Pipeline, Campaign, Activity, Agent, AutomationRule, CallLog, CallQueue, CallScript
-- Tablas hijas (sin CompanyId): PipelineStage, CampaignContact, LeadHistory, LeadScore, AutomationLog
--   -> se validan via INNER JOIN al padre

-- =============================================
-- 1) usp_crm_activity_complete
-- =============================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_crm_activity_complete(
    p_company_id  INTEGER,
    p_activity_id INTEGER,
    p_user_id     INTEGER DEFAULT NULL::INTEGER
) RETURNS TABLE(ok INTEGER, mensaje CHARACTER VARYING)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE crm."Activity"
    SET    "IsCompleted"     = TRUE,
           "CompletedAt"     = NOW() AT TIME ZONE 'UTC',
           "UpdatedByUserId" = p_user_id,
           "UpdatedAt"       = NOW() AT TIME ZONE 'UTC'
    WHERE  "ActivityId" = p_activity_id
      AND  "CompanyId"  = p_company_id;

    IF NOT FOUND THEN
        RETURN QUERY SELECT 0, 'Actividad no encontrada'::VARCHAR;
        RETURN;
    END IF;

    RETURN QUERY SELECT 1, 'OK'::VARCHAR;

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT 0, SQLERRM::VARCHAR;
END;
$$;
-- +goose StatementEnd

-- =============================================
-- 2) usp_crm_activity_update
-- =============================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_crm_activity_update(
    p_company_id  INTEGER,
    p_activity_id INTEGER,
    p_subject     CHARACTER VARYING DEFAULT NULL::CHARACTER VARYING,
    p_description TEXT              DEFAULT NULL::TEXT,
    p_due_date    TIMESTAMP WITHOUT TIME ZONE DEFAULT NULL::TIMESTAMP WITHOUT TIME ZONE,
    p_priority    CHARACTER VARYING DEFAULT NULL::CHARACTER VARYING,
    p_user_id     INTEGER           DEFAULT NULL::INTEGER
) RETURNS TABLE(ok INTEGER, mensaje CHARACTER VARYING)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE crm."Activity"
    SET    "Subject"         = COALESCE(p_subject,     "Subject"),
           "Description"     = COALESCE(p_description, "Description"),
           "DueDate"         = COALESCE(p_due_date,    "DueDate"),
           "Priority"        = COALESCE(p_priority,    "Priority"),
           "UpdatedByUserId" = p_user_id,
           "UpdatedAt"       = NOW() AT TIME ZONE 'UTC'
    WHERE  "ActivityId" = p_activity_id
      AND  "CompanyId"  = p_company_id;

    IF NOT FOUND THEN
        RETURN QUERY SELECT 0, 'Actividad no encontrada'::VARCHAR;
        RETURN;
    END IF;

    RETURN QUERY SELECT 1, 'OK'::VARCHAR;

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT 0, SQLERRM::VARCHAR;
END;
$$;
-- +goose StatementEnd

-- =============================================
-- 3) usp_crm_agent_updatestatus
-- =============================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_crm_agent_updatestatus(
    p_company_id INTEGER,
    p_agent_id   BIGINT,
    p_status     CHARACTER VARYING
) RETURNS TABLE(ok INTEGER, mensaje CHARACTER VARYING)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM crm."Agent"
        WHERE "AgentId" = p_agent_id
          AND "CompanyId" = p_company_id
          AND "IsDeleted" = FALSE
    ) THEN
        RETURN QUERY SELECT 0, 'Agente no encontrado'::VARCHAR;
        RETURN;
    END IF;

    UPDATE crm."Agent"
    SET    "Status"    = p_status,
           "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
    WHERE  "AgentId"   = p_agent_id
      AND  "CompanyId" = p_company_id
      AND  "IsDeleted" = FALSE;

    RETURN QUERY SELECT 1, 'OK'::VARCHAR;

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT 0, SQLERRM::VARCHAR;
END;
$$;
-- +goose StatementEnd

-- =============================================
-- 4) usp_crm_automation_delete
-- =============================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_crm_automation_delete(
    p_company_id INTEGER,
    p_rule_id    BIGINT,
    p_user_id    INTEGER DEFAULT NULL::INTEGER
) RETURNS TABLE(ok INTEGER, mensaje CHARACTER VARYING)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE crm."AutomationRule"
    SET    "IsDeleted" = TRUE,
           "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
    WHERE  "RuleId"    = p_rule_id
      AND  "CompanyId" = p_company_id
      AND  "IsDeleted" = FALSE;

    IF NOT FOUND THEN
        RETURN QUERY SELECT 0, 'Regla no encontrada'::VARCHAR;
        RETURN;
    END IF;

    RETURN QUERY SELECT 1, 'Regla eliminada correctamente'::VARCHAR;
END;
$$;
-- +goose StatementEnd

-- =============================================
-- 5) usp_crm_automation_getlogs
--    AutomationLog es tabla hija -> JOIN a AutomationRule (tiene CompanyId)
-- =============================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_crm_automation_getlogs(
    p_company_id INTEGER,
    p_rule_id    BIGINT  DEFAULT NULL::BIGINT,
    p_lead_id    BIGINT  DEFAULT NULL::BIGINT,
    p_limit      INTEGER DEFAULT 50
) RETURNS TABLE(
    "LogId"        BIGINT,
    "RuleId"       BIGINT,
    "RuleName"     CHARACTER VARYING,
    "LeadId"       BIGINT,
    "LeadCode"     CHARACTER VARYING,
    "ActionTaken"  CHARACTER VARYING,
    "ActionResult" TEXT,
    "ExecutedAt"   TIMESTAMP WITHOUT TIME ZONE
)
LANGUAGE plpgsql
AS $$
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
    INNER JOIN crm."AutomationRule" r ON r."RuleId" = al."RuleId"
        AND r."CompanyId" = p_company_id
    LEFT JOIN crm."Lead" l ON l."LeadId" = al."LeadId"
    WHERE  (p_rule_id IS NULL OR al."RuleId" = p_rule_id)
      AND  (p_lead_id IS NULL OR al."LeadId" = p_lead_id)
    ORDER BY al."ExecutedAt" DESC
    LIMIT p_limit;
END;
$$;
-- +goose StatementEnd

-- =============================================
-- 6) usp_crm_automation_logaction
--    AutomationLog es tabla hija -> validar que la regla pertenezca a la company
-- =============================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_crm_automation_logaction(
    p_company_id    INTEGER,
    p_rule_id       BIGINT,
    p_lead_id       BIGINT,
    p_action_taken  CHARACTER VARYING,
    p_action_result TEXT DEFAULT NULL::TEXT
) RETURNS TABLE(ok INTEGER, mensaje CHARACTER VARYING)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Validar que la regla pertenezca a la empresa
    IF NOT EXISTS (
        SELECT 1 FROM crm."AutomationRule"
        WHERE "RuleId" = p_rule_id AND "CompanyId" = p_company_id
    ) THEN
        RETURN QUERY SELECT 0, 'Regla no pertenece a la empresa'::VARCHAR;
        RETURN;
    END IF;

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
-- +goose StatementEnd

-- =============================================
-- 7) usp_crm_calllog_get
-- =============================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_crm_calllog_get(
    p_company_id  INTEGER,
    p_call_log_id BIGINT
) RETURNS TABLE(
    "CallLogId"             BIGINT,
    "CompanyId"             INTEGER,
    "BranchId"              INTEGER,
    "AgentId"               BIGINT,
    "QueueId"               BIGINT,
    "CallDirection"         CHARACTER VARYING,
    "CallerNumber"          CHARACTER VARYING,
    "CalledNumber"          CHARACTER VARYING,
    "CustomerCode"          CHARACTER VARYING,
    "CustomerId"            BIGINT,
    "LeadId"                BIGINT,
    "ContactName"           CHARACTER VARYING,
    "CallStartTime"         TIMESTAMP WITHOUT TIME ZONE,
    "CallEndTime"           TIMESTAMP WITHOUT TIME ZONE,
    "DurationSeconds"       INTEGER,
    "WaitSeconds"           INTEGER,
    "Result"                CHARACTER VARYING,
    "Disposition"           CHARACTER VARYING,
    "Notes"                 TEXT,
    "RecordingUrl"          CHARACTER VARYING,
    "CallbackScheduled"     TIMESTAMP WITHOUT TIME ZONE,
    "RelatedDocumentType"   CHARACTER VARYING,
    "RelatedDocumentNumber" CHARACTER VARYING,
    "Tags"                  CHARACTER VARYING,
    "SatisfactionScore"     INTEGER,
    "CreatedAt"             TIMESTAMP WITHOUT TIME ZONE,
    "AgentName"             CHARACTER VARYING,
    "QueueName"             CHARACTER VARYING
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        c."CallLogId", c."CompanyId", c."BranchId", c."AgentId", c."QueueId",
        c."CallDirection", c."CallerNumber", c."CalledNumber",
        c."CustomerCode", c."CustomerId", c."LeadId", c."ContactName",
        c."CallStartTime", c."CallEndTime", c."DurationSeconds", c."WaitSeconds",
        c."Result", c."Disposition", c."Notes"::TEXT, c."RecordingUrl",
        c."CallbackScheduled", c."RelatedDocumentType", c."RelatedDocumentNumber",
        c."Tags", c."SatisfactionScore", c."CreatedAt",
        a."AgentName",
        q."QueueName"
    FROM crm."CallLog" c
    LEFT JOIN crm."Agent" a ON a."AgentId" = c."AgentId"
    LEFT JOIN crm."CallQueue" q ON q."QueueId" = c."QueueId"
    WHERE c."CallLogId" = p_call_log_id
      AND c."CompanyId" = p_company_id
      AND c."IsDeleted" = FALSE;
END;
$$;
-- +goose StatementEnd

-- =============================================
-- 8) usp_crm_campaign_get
-- =============================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_crm_campaign_get(
    p_company_id  INTEGER,
    p_campaign_id BIGINT
) RETURNS TABLE(
    "CampaignId"      BIGINT,
    "CompanyId"        INTEGER,
    "CampaignCode"     CHARACTER VARYING,
    "CampaignName"     CHARACTER VARYING,
    "CampaignType"     CHARACTER VARYING,
    "QueueId"          BIGINT,
    "ScriptId"         BIGINT,
    "StartDate"        DATE,
    "EndDate"          DATE,
    "TotalContacts"    INTEGER,
    "ContactedCount"   INTEGER,
    "SuccessCount"     INTEGER,
    "Status"           CHARACTER VARYING,
    "Notes"            TEXT,
    "AssignedToUserId" INTEGER,
    "CreatedAt"        TIMESTAMP WITHOUT TIME ZONE,
    "UpdatedAt"        TIMESTAMP WITHOUT TIME ZONE,
    "QueueName"        CHARACTER VARYING,
    "ScriptName"       CHARACTER VARYING,
    "PendingCount"     BIGINT,
    "CallbackCount"    BIGINT
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        c."CampaignId", c."CompanyId", c."CampaignCode", c."CampaignName",
        c."CampaignType", c."QueueId", c."ScriptId",
        c."StartDate", c."EndDate",
        c."TotalContacts", c."ContactedCount", c."SuccessCount",
        c."Status", c."Notes"::TEXT, c."AssignedToUserId",
        c."CreatedAt", c."UpdatedAt",
        q."QueueName",
        s."ScriptName",
        (SELECT COUNT(*) FROM crm."CampaignContact" cc WHERE cc."CampaignId" = c."CampaignId" AND cc."Status" = 'PENDING' AND cc."IsDeleted" = FALSE),
        (SELECT COUNT(*) FROM crm."CampaignContact" cc WHERE cc."CampaignId" = c."CampaignId" AND cc."Status" = 'CALLBACK' AND cc."IsDeleted" = FALSE)
    FROM crm."Campaign" c
    LEFT JOIN crm."CallQueue" q ON q."QueueId" = c."QueueId"
    LEFT JOIN crm."CallScript" s ON s."ScriptId" = c."ScriptId"
    WHERE c."CampaignId" = p_campaign_id
      AND c."CompanyId"  = p_company_id
      AND c."IsDeleted"  = FALSE;
END;
$$;
-- +goose StatementEnd

-- =============================================
-- 9) usp_crm_campaign_getnextcontact
--    CampaignContact es tabla hija -> JOIN a Campaign (tiene CompanyId)
-- =============================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_crm_campaign_getnextcontact(
    p_company_id  INTEGER,
    p_campaign_id BIGINT,
    p_agent_id    BIGINT
) RETURNS TABLE(
    "CampaignContactId" BIGINT,
    "CampaignId"        BIGINT,
    "CustomerId"        BIGINT,
    "LeadId"            BIGINT,
    "ContactName"       CHARACTER VARYING,
    "Phone"             CHARACTER VARYING,
    "Email"             CHARACTER VARYING,
    "Status"            CHARACTER VARYING,
    "Attempts"          INTEGER,
    "LastAttempt"       TIMESTAMP WITHOUT TIME ZONE,
    "LastResult"        CHARACTER VARYING,
    "CallbackDate"      TIMESTAMP WITHOUT TIME ZONE,
    "AssignedAgentId"   BIGINT,
    "Notes"             TEXT,
    "Priority"          CHARACTER VARYING
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        cc."CampaignContactId", cc."CampaignId", cc."CustomerId", cc."LeadId",
        cc."ContactName", cc."Phone", cc."Email", cc."Status",
        cc."Attempts", cc."LastAttempt", cc."LastResult",
        cc."CallbackDate", cc."AssignedAgentId", cc."Notes"::TEXT, cc."Priority"
    FROM crm."CampaignContact" cc
    INNER JOIN crm."Campaign" camp ON camp."CampaignId" = cc."CampaignId"
        AND camp."CompanyId" = p_company_id
        AND camp."IsDeleted" = FALSE
    WHERE cc."CampaignId" = p_campaign_id
      AND cc."IsDeleted" = FALSE
      AND (cc."AssignedAgentId" IS NULL OR cc."AssignedAgentId" = p_agent_id)
      AND cc."Status" IN ('PENDING', 'CALLBACK')
      AND (
           (cc."Status" = 'CALLBACK' AND cc."CallbackDate" <= NOW() AT TIME ZONE 'UTC')
           OR cc."Status" = 'PENDING'
      )
    ORDER BY
        CASE cc."Status" WHEN 'CALLBACK' THEN 0 ELSE 1 END,
        CASE cc."Priority" WHEN 'HIGH' THEN 0 WHEN 'MEDIUM' THEN 1 ELSE 2 END,
        cc."CallbackDate" NULLS LAST,
        cc."CampaignContactId"
    LIMIT 1;
END;
$$;
-- +goose StatementEnd

-- =============================================
-- 10) usp_crm_campaign_logattempt
--     CampaignContact es tabla hija -> validar via JOIN a Campaign
-- =============================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_crm_campaign_logattempt(
    p_company_id          INTEGER,
    p_campaign_contact_id BIGINT,
    p_result              CHARACTER VARYING,
    p_callback_date       TIMESTAMP WITHOUT TIME ZONE DEFAULT NULL::TIMESTAMP WITHOUT TIME ZONE,
    p_notes               TEXT DEFAULT NULL::TEXT,
    p_user_id             INTEGER DEFAULT NULL::INTEGER
) RETURNS TABLE(ok INTEGER, mensaje CHARACTER VARYING)
LANGUAGE plpgsql
AS $$
DECLARE
    v_new_status VARCHAR;
    v_camp_id    BIGINT;
BEGIN
    -- Validar que el contacto pertenezca a una campana de la empresa
    IF NOT EXISTS (
        SELECT 1
        FROM crm."CampaignContact" cc
        INNER JOIN crm."Campaign" camp ON camp."CampaignId" = cc."CampaignId"
            AND camp."CompanyId" = p_company_id
        WHERE cc."CampaignContactId" = p_campaign_contact_id
          AND cc."IsDeleted" = FALSE
    ) THEN
        RETURN QUERY SELECT 0, 'Contacto de campana no encontrado'::VARCHAR;
        RETURN;
    END IF;

    v_new_status := CASE
        WHEN p_callback_date IS NOT NULL THEN 'CALLBACK'
        WHEN p_result IN ('ANSWERED', 'SALE', 'APPOINTMENT', 'COLLECTION_PROMISE') THEN 'COMPLETED'
        WHEN p_result IN ('DO_NOT_CALL', 'WRONG_NUMBER') THEN 'DO_NOT_CALL'
        ELSE 'CALLED'
    END;

    UPDATE crm."CampaignContact"
    SET    "Attempts"        = "Attempts" + 1,
           "LastAttempt"     = NOW() AT TIME ZONE 'UTC',
           "LastResult"      = p_result,
           "Status"          = v_new_status,
           "CallbackDate"    = p_callback_date,
           "Notes"           = COALESCE(p_notes, "Notes"),
           "UpdatedByUserId" = p_user_id,
           "UpdatedAt"       = NOW() AT TIME ZONE 'UTC'
    WHERE  "CampaignContactId" = p_campaign_contact_id AND "IsDeleted" = FALSE;

    -- Actualizar contadores de campana
    SELECT "CampaignId" INTO v_camp_id FROM crm."CampaignContact" WHERE "CampaignContactId" = p_campaign_contact_id;

    UPDATE crm."Campaign"
    SET    "ContactedCount" = (SELECT COUNT(*) FROM crm."CampaignContact" WHERE "CampaignId" = v_camp_id AND "Status" NOT IN ('PENDING') AND "IsDeleted" = FALSE),
           "SuccessCount"   = (SELECT COUNT(*) FROM crm."CampaignContact" WHERE "CampaignId" = v_camp_id AND "Status" = 'COMPLETED' AND "IsDeleted" = FALSE),
           "UpdatedAt"      = NOW() AT TIME ZONE 'UTC'
    WHERE  "CampaignId" = v_camp_id;

    RETURN QUERY SELECT 1, 'OK'::VARCHAR;

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT 0, SQLERRM::VARCHAR;
END;
$$;
-- +goose StatementEnd

-- =============================================
-- 11) usp_crm_campaign_updatestatus
-- =============================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_crm_campaign_updatestatus(
    p_company_id  INTEGER,
    p_campaign_id BIGINT,
    p_status      CHARACTER VARYING,
    p_user_id     INTEGER
) RETURNS TABLE(ok INTEGER, mensaje CHARACTER VARYING)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM crm."Campaign"
        WHERE "CampaignId" = p_campaign_id
          AND "CompanyId"  = p_company_id
          AND "IsDeleted"  = FALSE
    ) THEN
        RETURN QUERY SELECT 0, 'Campana no encontrada'::VARCHAR;
        RETURN;
    END IF;

    UPDATE crm."Campaign"
    SET    "Status"          = p_status,
           "UpdatedByUserId" = p_user_id,
           "UpdatedAt"       = NOW() AT TIME ZONE 'UTC'
    WHERE  "CampaignId" = p_campaign_id
      AND  "CompanyId"  = p_company_id
      AND  "IsDeleted"  = FALSE;

    RETURN QUERY SELECT 1, 'OK'::VARCHAR;

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT 0, SQLERRM::VARCHAR;
END;
$$;
-- +goose StatementEnd

-- =============================================
-- 12) usp_crm_lead_changestage
-- =============================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_crm_lead_changestage(
    p_company_id   INTEGER,
    p_lead_id      INTEGER,
    p_new_stage_id INTEGER,
    p_notes        CHARACTER VARYING DEFAULT NULL::CHARACTER VARYING,
    p_user_id      INTEGER           DEFAULT NULL::INTEGER
) RETURNS TABLE(ok INTEGER, mensaje CHARACTER VARYING)
LANGUAGE plpgsql
AS $$
DECLARE
    v_old_stage_id INT;
BEGIN
    SELECT "StageId" INTO v_old_stage_id
    FROM crm."Lead"
    WHERE "LeadId" = p_lead_id
      AND "CompanyId" = p_company_id;

    IF v_old_stage_id IS NULL THEN
        RETURN QUERY SELECT 0, 'Lead no encontrado'::VARCHAR;
        RETURN;
    END IF;

    UPDATE crm."Lead"
    SET    "StageId" = p_new_stage_id,
           "UpdatedByUserId" = p_user_id,
           "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
    WHERE  "LeadId"    = p_lead_id
      AND  "CompanyId" = p_company_id;

    INSERT INTO crm."LeadHistory" ("LeadId", "ChangeType", "FromStageId", "ToStageId", "Notes", "ChangedByUserId", "CreatedAt")
    VALUES (p_lead_id, 'STAGE_CHANGE', v_old_stage_id, p_new_stage_id, p_notes, p_user_id, NOW() AT TIME ZONE 'UTC');

    RETURN QUERY SELECT 1, 'OK'::VARCHAR;

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT 0, SQLERRM::VARCHAR;
END;
$$;
-- +goose StatementEnd

-- =============================================
-- 13) usp_crm_lead_close
-- =============================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_crm_lead_close(
    p_company_id  INTEGER,
    p_lead_id     INTEGER,
    p_is_won      BOOLEAN,
    p_lost_reason CHARACTER VARYING DEFAULT NULL::CHARACTER VARYING,
    p_customer_id BIGINT            DEFAULT NULL::BIGINT,
    p_user_id     INTEGER           DEFAULT NULL::INTEGER
) RETURNS TABLE(ok INTEGER, mensaje CHARACTER VARYING)
LANGUAGE plpgsql
AS $$
DECLARE
    v_old_stage_id    INT;
    v_closed_stage_id INT;
    v_new_status      VARCHAR(20);
BEGIN
    v_new_status := CASE WHEN p_is_won THEN 'WON' ELSE 'LOST' END;

    SELECT "StageId" INTO v_old_stage_id
    FROM crm."Lead"
    WHERE "LeadId" = p_lead_id
      AND "CompanyId" = p_company_id;

    IF v_old_stage_id IS NULL THEN
        RETURN QUERY SELECT 0, 'Lead no encontrado'::VARCHAR;
        RETURN;
    END IF;

    SELECT s."StageId" INTO v_closed_stage_id
    FROM   crm."PipelineStage" s
    JOIN   crm."Lead" l ON l."PipelineId" = s."PipelineId"
    WHERE  l."LeadId" = p_lead_id
      AND  l."CompanyId" = p_company_id
      AND  s."IsClosed" = TRUE
      AND  s."IsWon" = p_is_won
    LIMIT 1;

    UPDATE crm."Lead"
    SET    "Status"          = v_new_status,
           "StageId"         = COALESCE(v_closed_stage_id, "StageId"),
           "LostReason"      = p_lost_reason,
           "CustomerId"      = p_customer_id,
           "WonAt"           = CASE WHEN p_is_won THEN NOW() AT TIME ZONE 'UTC' ELSE NULL END,
           "LostAt"          = CASE WHEN NOT p_is_won THEN NOW() AT TIME ZONE 'UTC' ELSE NULL END,
           "UpdatedByUserId" = p_user_id,
           "UpdatedAt"       = NOW() AT TIME ZONE 'UTC'
    WHERE  "LeadId"    = p_lead_id
      AND  "CompanyId" = p_company_id;

    INSERT INTO crm."LeadHistory" ("LeadId", "ChangeType", "FromStageId", "ToStageId", "Notes", "ChangedByUserId", "CreatedAt")
    VALUES (p_lead_id, 'STATUS', v_old_stage_id, COALESCE(v_closed_stage_id, v_old_stage_id),
            COALESCE(p_lost_reason, 'Cerrado como ' || v_new_status), p_user_id, NOW() AT TIME ZONE 'UTC');

    RETURN QUERY SELECT 1, 'OK'::VARCHAR;

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT 0, SQLERRM::VARCHAR;
END;
$$;
-- +goose StatementEnd

-- =============================================
-- 14) usp_crm_lead_get
-- =============================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_crm_lead_get(
    p_company_id INTEGER,
    p_lead_id    INTEGER
) RETURNS TABLE(
    "LeadId"            BIGINT,
    "LeadCode"          CHARACTER VARYING,
    "CompanyId"         INTEGER,
    "BranchId"          INTEGER,
    "PipelineId"        BIGINT,
    "PipelineName"      CHARACTER VARYING,
    "StageId"           BIGINT,
    "StageName"         CHARACTER VARYING,
    "StageColor"        CHARACTER VARYING,
    "ContactName"       CHARACTER VARYING,
    "CompanyName"       CHARACTER VARYING,
    "Email"             CHARACTER VARYING,
    "Phone"             CHARACTER VARYING,
    "Source"            CHARACTER VARYING,
    "Status"            CHARACTER VARYING,
    "AssignedToUserId"  INTEGER,
    "EstimatedValue"    NUMERIC,
    "CurrencyCode"      CHARACTER,
    "ExpectedCloseDate" DATE,
    "Notes"             TEXT,
    "Tags"              CHARACTER VARYING,
    "Priority"          CHARACTER VARYING,
    "LostReason"        CHARACTER VARYING,
    "CustomerId"        BIGINT,
    "CreatedAt"         TIMESTAMP WITHOUT TIME ZONE,
    "UpdatedAt"         TIMESTAMP WITHOUT TIME ZONE,
    _section            CHARACTER VARYING
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Section: header
    RETURN QUERY
    SELECT
        l."LeadId", l."LeadCode", l."CompanyId", l."BranchId",
        l."PipelineId", p."PipelineName",
        l."StageId", s."StageName", s."Color",
        l."ContactName", l."CompanyName", l."Email", l."Phone",
        l."Source", l."Status", l."AssignedToUserId",
        l."EstimatedValue", l."CurrencyCode",
        l."ExpectedCloseDate", l."Notes"::TEXT, l."Tags", l."Priority",
        l."LostReason", l."CustomerId",
        l."CreatedAt", l."UpdatedAt",
        'header'::VARCHAR
    FROM   crm."Lead" l
    LEFT JOIN crm."Pipeline"      p ON p."PipelineId" = l."PipelineId"
    LEFT JOIN crm."PipelineStage" s ON s."StageId"    = l."StageId"
    WHERE  l."LeadId"    = p_lead_id
      AND  l."CompanyId" = p_company_id;
END;
$$;
-- +goose StatementEnd

-- =============================================
-- 15) usp_crm_lead_getdetail
-- =============================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_crm_lead_getdetail(
    p_company_id INTEGER,
    p_lead_id    BIGINT
) RETURNS TABLE(
    "LeadId"                BIGINT,
    "CompanyId"             INTEGER,
    "BranchId"              INTEGER,
    "PipelineId"            BIGINT,
    "StageId"               BIGINT,
    "LeadCode"              CHARACTER VARYING,
    "ContactName"           CHARACTER VARYING,
    "CompanyName"           CHARACTER VARYING,
    "Email"                 CHARACTER VARYING,
    "Phone"                 CHARACTER VARYING,
    "Source"                CHARACTER VARYING,
    "AssignedToUserId"      INTEGER,
    "CustomerId"            BIGINT,
    "EstimatedValue"        NUMERIC,
    "CurrencyCode"          CHARACTER VARYING,
    "ExpectedCloseDate"     DATE,
    "LostReason"            CHARACTER VARYING,
    "Notes"                 TEXT,
    "Tags"                  CHARACTER VARYING,
    "Priority"              CHARACTER VARYING,
    "Status"                CHARACTER VARYING,
    "WonAt"                 TIMESTAMP WITHOUT TIME ZONE,
    "LostAt"                TIMESTAMP WITHOUT TIME ZONE,
    "CreatedAt"             TIMESTAMP WITHOUT TIME ZONE,
    "UpdatedAt"             TIMESTAMP WITHOUT TIME ZONE,
    "CreatedByUserId"       INTEGER,
    "UpdatedByUserId"       INTEGER,
    "RowVer"                INTEGER,
    "StageName"             CHARACTER VARYING,
    "StageColor"            CHARACTER VARYING,
    "StageProbability"      INTEGER,
    "PipelineName"          CHARACTER VARYING,
    "AssignedToName"        CHARACTER VARYING,
    "CurrentScore"          INTEGER,
    "DaysInCurrentStage"    INTEGER,
    "TotalActivities"       INTEGER,
    "PendingActivities"     INTEGER,
    "DaysSinceLastActivity" INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_now TIMESTAMP := NOW() AT TIME ZONE 'UTC';
BEGIN
    RETURN QUERY
    SELECT
        l."LeadId",
        l."CompanyId",
        l."BranchId",
        l."PipelineId",
        l."StageId",
        l."LeadCode"::VARCHAR,
        l."ContactName"::VARCHAR,
        l."CompanyName"::VARCHAR,
        l."Email"::VARCHAR,
        l."Phone"::VARCHAR,
        l."Source"::VARCHAR,
        l."AssignedToUserId",
        l."CustomerId",
        l."EstimatedValue"::NUMERIC,
        l."CurrencyCode"::VARCHAR,
        l."ExpectedCloseDate",
        l."LostReason"::VARCHAR,
        l."Notes",
        l."Tags"::VARCHAR,
        l."Priority"::VARCHAR,
        l."Status"::VARCHAR,
        l."WonAt",
        l."LostAt",
        l."CreatedAt",
        l."UpdatedAt",
        l."CreatedByUserId",
        l."UpdatedByUserId",
        l."RowVer",
        s."StageName"::VARCHAR,
        s."Color"::VARCHAR                     AS "StageColor",
        s."Probability"::INT                   AS "StageProbability",
        p."PipelineName"::VARCHAR,
        u."FullName"::VARCHAR                  AS "AssignedToName",
        -- Score mas reciente (LeadScore es hija, acceso via LeadId ya validado)
        COALESCE((
            SELECT ls."Score"
            FROM   crm."LeadScore" ls
            WHERE  ls."LeadId" = l."LeadId"
            ORDER BY ls."ScoreDate" DESC
            LIMIT 1
        ), 0)::INT                             AS "CurrentScore",
        -- Dias en etapa actual (LeadHistory es hija)
        COALESCE((
            SELECT EXTRACT(EPOCH FROM (v_now - h."CreatedAt"))::INT / 86400
            FROM   crm."LeadHistory" h
            WHERE  h."LeadId" = l."LeadId"
              AND  h."ChangeType" = 'STAGE_CHANGE'
            ORDER BY h."CreatedAt" DESC
            LIMIT 1
        ), EXTRACT(EPOCH FROM (v_now - l."CreatedAt"))::INT / 86400)::INT AS "DaysInCurrentStage",
        -- Total actividades
        (SELECT COUNT(*)::INT FROM crm."Activity" a
         WHERE a."LeadId" = l."LeadId" AND a."IsDeleted" = FALSE) AS "TotalActivities",
        -- Actividades pendientes
        (SELECT COUNT(*)::INT FROM crm."Activity" a
         WHERE a."LeadId" = l."LeadId" AND a."IsDeleted" = FALSE AND a."IsCompleted" = FALSE) AS "PendingActivities",
        -- Dias desde ultima actividad
        COALESCE((
            SELECT EXTRACT(EPOCH FROM (v_now - MAX(a."CreatedAt")))::INT / 86400
            FROM   crm."Activity" a
            WHERE  a."LeadId" = l."LeadId" AND a."IsDeleted" = FALSE
        ), -1)::INT                            AS "DaysSinceLastActivity"
    FROM   crm."Lead" l
    JOIN   crm."PipelineStage" s ON s."StageId" = l."StageId"
    JOIN   crm."Pipeline" p      ON p."PipelineId" = l."PipelineId"
    LEFT JOIN sec."User" u       ON u."UserId" = l."AssignedToUserId"
    WHERE  l."LeadId"    = p_lead_id
      AND  l."CompanyId" = p_company_id
      AND  l."IsDeleted" = FALSE;
END;
$$;
-- +goose StatementEnd

-- =============================================
-- 16) usp_crm_lead_gethistory
--     LeadHistory es tabla hija -> JOIN a Lead (tiene CompanyId)
-- =============================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_crm_lead_gethistory(
    p_company_id INTEGER,
    p_lead_id    BIGINT
) RETURNS TABLE(
    "HistoryId"     BIGINT,
    "ChangeType"    CHARACTER VARYING,
    "FromStageName" CHARACTER VARYING,
    "ToStageName"   CHARACTER VARYING,
    "ChangedByName" CHARACTER VARYING,
    "Notes"         CHARACTER VARYING,
    "CreatedAt"     TIMESTAMP WITHOUT TIME ZONE
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        h."HistoryId",
        h."ChangeType"::VARCHAR,
        sf."StageName"::VARCHAR                AS "FromStageName",
        st."StageName"::VARCHAR                AS "ToStageName",
        u."FullName"::VARCHAR                  AS "ChangedByName",
        h."Notes"::VARCHAR,
        h."CreatedAt"
    FROM   crm."LeadHistory" h
    INNER JOIN crm."Lead" ld ON ld."LeadId" = h."LeadId"
        AND ld."CompanyId" = p_company_id
    LEFT JOIN crm."PipelineStage" sf ON sf."StageId" = h."FromStageId"
    LEFT JOIN crm."PipelineStage" st ON st."StageId" = h."ToStageId"
    LEFT JOIN sec."User" u           ON u."UserId" = h."ChangedByUserId"
    WHERE  h."LeadId" = p_lead_id
    ORDER BY h."CreatedAt" DESC;
END;
$$;
-- +goose StatementEnd

-- =============================================
-- 17) usp_crm_lead_update
-- =============================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_crm_lead_update(
    p_company_id          INTEGER,
    p_lead_id             INTEGER,
    p_stage_id            INTEGER           DEFAULT NULL::INTEGER,
    p_contact_name        CHARACTER VARYING DEFAULT NULL::CHARACTER VARYING,
    p_company_name        CHARACTER VARYING DEFAULT NULL::CHARACTER VARYING,
    p_email               CHARACTER VARYING DEFAULT NULL::CHARACTER VARYING,
    p_phone               CHARACTER VARYING DEFAULT NULL::CHARACTER VARYING,
    p_assigned_to_user_id INTEGER           DEFAULT NULL::INTEGER,
    p_estimated_value     NUMERIC           DEFAULT NULL::NUMERIC,
    p_expected_close_date TIMESTAMP WITHOUT TIME ZONE DEFAULT NULL::TIMESTAMP WITHOUT TIME ZONE,
    p_notes               TEXT              DEFAULT NULL::TEXT,
    p_tags                CHARACTER VARYING DEFAULT NULL::CHARACTER VARYING,
    p_priority            CHARACTER VARYING DEFAULT NULL::CHARACTER VARYING,
    p_user_id             INTEGER           DEFAULT NULL::INTEGER
) RETURNS TABLE(ok INTEGER, mensaje CHARACTER VARYING)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE crm."Lead"
    SET    "StageId"          = COALESCE(p_stage_id,           "StageId"),
           "ContactName"      = COALESCE(p_contact_name,       "ContactName"),
           "CompanyName"      = COALESCE(p_company_name,       "CompanyName"),
           "Email"            = COALESCE(p_email,              "Email"),
           "Phone"            = COALESCE(p_phone,              "Phone"),
           "AssignedToUserId" = COALESCE(p_assigned_to_user_id,"AssignedToUserId"),
           "EstimatedValue"   = COALESCE(p_estimated_value,    "EstimatedValue"),
           "ExpectedCloseDate"= COALESCE(p_expected_close_date,"ExpectedCloseDate"),
           "Notes"            = COALESCE(p_notes,              "Notes"),
           "Tags"             = COALESCE(p_tags,               "Tags"),
           "Priority"         = COALESCE(p_priority,           "Priority"),
           "UpdatedByUserId"  = p_user_id,
           "UpdatedAt"        = NOW() AT TIME ZONE 'UTC'
    WHERE  "LeadId"    = p_lead_id
      AND  "CompanyId" = p_company_id;

    IF NOT FOUND THEN
        RETURN QUERY SELECT 0, 'Lead no encontrado'::VARCHAR;
        RETURN;
    END IF;

    RETURN QUERY SELECT 1, 'OK'::VARCHAR;

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT 0, SQLERRM::VARCHAR;
END;
$$;
-- +goose StatementEnd

-- =============================================
-- 18) usp_crm_leadscore_calculate
-- =============================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_crm_leadscore_calculate(
    p_company_id INTEGER,
    p_lead_id    BIGINT,
    p_user_id    INTEGER DEFAULT NULL::INTEGER
) RETURNS TABLE(ok INTEGER, mensaje CHARACTER VARYING, "Score" INTEGER)
LANGUAGE plpgsql
AS $$
DECLARE
    v_score        INT := 0;
    v_factors      JSONB := '{}';
    v_now          TIMESTAMP := NOW() AT TIME ZONE 'UTC';
    v_7d_ago       TIMESTAMP := (NOW() AT TIME ZONE 'UTC') - INTERVAL '7 days';
    v_30d_ago      TIMESTAMP := (NOW() AT TIME ZONE 'UTC') - INTERVAL '30 days';
    v_lead         RECORD;
    v_act_7d       INT := 0;
    v_act_30d      INT := 0;
    v_act_total    INT := 0;
    v_last_act     TIMESTAMP;
BEGIN
    -- Obtener datos del lead
    SELECT l."LeadId", l."Email", l."Phone", l."CompanyName",
           l."EstimatedValue", l."ExpectedCloseDate", l."Priority",
           l."Status", l."Notes"
    INTO   v_lead
    FROM   crm."Lead" l
    WHERE  l."LeadId"    = p_lead_id
      AND  l."CompanyId" = p_company_id
      AND  l."IsDeleted" = FALSE;

    IF v_lead."LeadId" IS NULL THEN
        RETURN QUERY SELECT 0, 'Lead no encontrado'::VARCHAR, 0;
        RETURN;
    END IF;

    -- Factor: Tiene email (+10)
    IF v_lead."Email" IS NOT NULL AND v_lead."Email" <> '' THEN
        v_score := v_score + 10;
        v_factors := v_factors || '{"email": 10}';
    END IF;

    -- Factor: Tiene telefono (+8)
    IF v_lead."Phone" IS NOT NULL AND v_lead."Phone" <> '' THEN
        v_score := v_score + 8;
        v_factors := v_factors || '{"phone": 8}';
    END IF;

    -- Factor: Tiene empresa (+5)
    IF v_lead."CompanyName" IS NOT NULL AND v_lead."CompanyName" <> '' THEN
        v_score := v_score + 5;
        v_factors := v_factors || '{"companyName": 5}';
    END IF;

    -- Factor: Valor estimado > 0 (+15)
    IF COALESCE(v_lead."EstimatedValue", 0) > 0 THEN
        v_score := v_score + 15;
        v_factors := v_factors || '{"estimatedValue": 15}';
    END IF;

    -- Factor: Valor estimado > 10000 (+10 extra)
    IF COALESCE(v_lead."EstimatedValue", 0) > 10000 THEN
        v_score := v_score + 10;
        v_factors := v_factors || '{"highValue": 10}';
    END IF;

    -- Factor: Tiene fecha cierre esperada (+5)
    IF v_lead."ExpectedCloseDate" IS NOT NULL THEN
        v_score := v_score + 5;
        v_factors := v_factors || '{"expectedCloseDate": 5}';
    END IF;

    -- Factor: Prioridad HIGH/URGENT (+10)
    IF v_lead."Priority" IN ('HIGH', 'URGENT') THEN
        v_score := v_score + 10;
        v_factors := v_factors || '{"highPriority": 10}';
    END IF;

    -- Factor: Status OPEN (+5)
    IF v_lead."Status" = 'OPEN' THEN
        v_score := v_score + 5;
        v_factors := v_factors || '{"statusOpen": 5}';
    END IF;

    -- Factor: Notas no vacias (+5)
    IF v_lead."Notes" IS NOT NULL AND v_lead."Notes" <> '' THEN
        v_score := v_score + 5;
        v_factors := v_factors || '{"hasNotes": 5}';
    END IF;

    -- Contar actividades
    SELECT COUNT(*) FILTER (WHERE a."CreatedAt" >= v_7d_ago),
           COUNT(*) FILTER (WHERE a."CreatedAt" >= v_30d_ago AND a."CreatedAt" < v_7d_ago),
           COUNT(*),
           MAX(a."CreatedAt")
    INTO   v_act_7d, v_act_30d, v_act_total, v_last_act
    FROM   crm."Activity" a
    WHERE  a."LeadId" = p_lead_id
      AND  a."IsDeleted" = FALSE;

    -- Factor: Actividades en ultimos 7 dias (+15)
    IF v_act_7d > 0 THEN
        v_score := v_score + 15;
        v_factors := v_factors || '{"recentActivity7d": 15}';
    -- Factor: Actividades en ultimos 30 dias pero no en 7 (+7)
    ELSIF v_act_30d > 0 THEN
        v_score := v_score + 7;
        v_factors := v_factors || '{"recentActivity30d": 7}';
    -- Factor: Sin actividades > 30 dias (-10)
    ELSIF v_act_total > 0 AND v_last_act < v_30d_ago THEN
        v_score := v_score - 10;
        v_factors := v_factors || '{"staleActivity": -10}';
    END IF;

    -- Factor: Total actividades > 5 (+5)
    IF v_act_total > 5 THEN
        v_score := v_score + 5;
        v_factors := v_factors || '{"manyActivities": 5}';
    END IF;

    -- Clamp entre 0 y 100
    v_score := GREATEST(0, LEAST(100, v_score));

    -- Insertar en LeadScore
    INSERT INTO crm."LeadScore" ("LeadId", "Score", "ScoreDate", "Factors", "CalculatedByUserId")
    VALUES (p_lead_id, v_score, v_now, v_factors, p_user_id);

    RETURN QUERY SELECT 1, 'Score calculado correctamente'::VARCHAR, v_score;
END;
$$;
-- +goose StatementEnd

-- =============================================
-- 19) usp_crm_leadscore_get
--     LeadScore es tabla hija -> JOIN a Lead (tiene CompanyId)
-- =============================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_crm_leadscore_get(
    p_company_id INTEGER,
    p_lead_id    BIGINT
) RETURNS TABLE("Score" INTEGER, "ScoreDate" TIMESTAMP WITHOUT TIME ZONE, "Factors" JSONB)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT ls."Score", ls."ScoreDate", ls."Factors"
    FROM   crm."LeadScore" ls
    INNER JOIN crm."Lead" l ON l."LeadId" = ls."LeadId"
        AND l."CompanyId" = p_company_id
    WHERE  ls."LeadId" = p_lead_id
    ORDER BY ls."ScoreDate" DESC
    LIMIT 1;
END;
$$;
-- +goose StatementEnd

-- =============================================
-- 20) usp_crm_pipeline_getstages
--     PipelineStage es tabla hija -> JOIN a Pipeline (tiene CompanyId)
-- =============================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_crm_pipeline_getstages(
    p_company_id  INTEGER,
    p_pipeline_id INTEGER
) RETURNS TABLE(
    "StageId"      BIGINT,
    "PipelineId"   BIGINT,
    "StageCode"    CHARACTER VARYING,
    "StageName"    CHARACTER VARYING,
    "StageOrder"   INTEGER,
    "Probability"  NUMERIC,
    "DaysExpected" INTEGER,
    "Color"        CHARACTER VARYING,
    "IsClosed"     BOOLEAN,
    "IsWon"        BOOLEAN,
    "IsActive"     BOOLEAN
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT s."StageId", s."PipelineId", s."StageCode", s."StageName",
           s."StageOrder", s."Probability", s."DaysExpected", s."Color",
           s."IsClosed", s."IsWon", s."IsActive"
    FROM crm."PipelineStage" s
    INNER JOIN crm."Pipeline" p ON p."PipelineId" = s."PipelineId"
        AND p."CompanyId" = p_company_id
    WHERE s."PipelineId" = p_pipeline_id
      AND s."IsDeleted" = FALSE
    ORDER BY s."StageOrder";
END;
$$;
-- +goose StatementEnd

-- =============================================
-- 21) usp_crm_stage_upsert
--     PipelineStage es tabla hija -> validar Pipeline pertenece a company
-- =============================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_crm_stage_upsert(
    p_company_id   INTEGER,
    p_pipeline_id  INTEGER,
    p_stage_id     INTEGER           DEFAULT NULL::INTEGER,
    p_stage_code   CHARACTER VARYING DEFAULT NULL::CHARACTER VARYING,
    p_stage_name   CHARACTER VARYING DEFAULT NULL::CHARACTER VARYING,
    p_stage_order  INTEGER           DEFAULT 0,
    p_probability  NUMERIC           DEFAULT 0,
    p_days_expected INTEGER          DEFAULT 0,
    p_color        CHARACTER VARYING DEFAULT NULL::CHARACTER VARYING,
    p_is_closed    BOOLEAN           DEFAULT FALSE,
    p_is_won       BOOLEAN           DEFAULT FALSE,
    p_is_active    BOOLEAN           DEFAULT TRUE,
    p_user_id      INTEGER           DEFAULT NULL::INTEGER
) RETURNS TABLE(ok INTEGER, mensaje CHARACTER VARYING)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Validar que el pipeline pertenezca a la empresa
    IF NOT EXISTS (
        SELECT 1 FROM crm."Pipeline"
        WHERE "PipelineId" = p_pipeline_id AND "CompanyId" = p_company_id
    ) THEN
        RETURN QUERY SELECT 0, 'Pipeline no pertenece a la empresa'::VARCHAR;
        RETURN;
    END IF;

    IF p_stage_id IS NULL THEN
        INSERT INTO crm."PipelineStage" ("PipelineId", "StageCode", "StageName", "StageOrder", "Probability", "DaysExpected", "Color", "IsClosed", "IsWon", "IsActive", "CreatedByUserId", "UpdatedByUserId", "CreatedAt", "UpdatedAt")
        VALUES (p_pipeline_id, p_stage_code, p_stage_name, p_stage_order, p_probability, p_days_expected, p_color, p_is_closed, p_is_won, p_is_active, p_user_id, p_user_id, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC');
    ELSE
        UPDATE crm."PipelineStage"
        SET    "StageCode"       = p_stage_code,
               "StageName"       = p_stage_name,
               "StageOrder"      = p_stage_order,
               "Probability"     = p_probability,
               "DaysExpected"    = p_days_expected,
               "Color"           = p_color,
               "IsClosed"        = p_is_closed,
               "IsWon"           = p_is_won,
               "IsActive"        = p_is_active,
               "UpdatedByUserId" = p_user_id,
               "UpdatedAt"       = NOW() AT TIME ZONE 'UTC'
        WHERE  "StageId" = p_stage_id AND "PipelineId" = p_pipeline_id;
    END IF;

    RETURN QUERY SELECT 1, 'OK'::VARCHAR;

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT 0, SQLERRM::VARCHAR;
END;
$$;
-- +goose StatementEnd


-- +goose Down
-- Revertir: restaurar funciones originales sin p_company_id

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_crm_activity_complete(p_activity_id integer, p_user_id integer DEFAULT NULL::integer) RETURNS TABLE(ok integer, mensaje character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE crm."Activity"
    SET    "IsCompleted"     = TRUE,
           "CompletedAt"     = NOW() AT TIME ZONE 'UTC',
           "UpdatedByUserId" = p_user_id,
           "UpdatedAt"       = NOW() AT TIME ZONE 'UTC'
    WHERE  "ActivityId" = p_activity_id;
    RETURN QUERY SELECT 1, 'OK'::VARCHAR;
EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT 0, SQLERRM::VARCHAR;
END;
$$;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_crm_activity_update(p_activity_id integer, p_subject character varying DEFAULT NULL::character varying, p_description text DEFAULT NULL::text, p_due_date timestamp without time zone DEFAULT NULL::timestamp without time zone, p_priority character varying DEFAULT NULL::character varying, p_user_id integer DEFAULT NULL::integer) RETURNS TABLE(ok integer, mensaje character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE crm."Activity"
    SET    "Subject"         = COALESCE(p_subject,     "Subject"),
           "Description"     = COALESCE(p_description, "Description"),
           "DueDate"         = COALESCE(p_due_date,    "DueDate"),
           "Priority"        = COALESCE(p_priority,    "Priority"),
           "UpdatedByUserId" = p_user_id,
           "UpdatedAt"       = NOW() AT TIME ZONE 'UTC'
    WHERE  "ActivityId" = p_activity_id;
    RETURN QUERY SELECT 1, 'OK'::VARCHAR;
EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT 0, SQLERRM::VARCHAR;
END;
$$;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_crm_agent_updatestatus(p_agent_id bigint, p_status character varying) RETURNS TABLE(ok integer, mensaje character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM crm."Agent" WHERE "AgentId" = p_agent_id AND "IsDeleted" = FALSE) THEN
        RETURN QUERY SELECT 0, 'Agente no encontrado'::VARCHAR;
        RETURN;
    END IF;
    UPDATE crm."Agent"
    SET    "Status"    = p_status,
           "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
    WHERE  "AgentId" = p_agent_id AND "IsDeleted" = FALSE;
    RETURN QUERY SELECT 1, 'OK'::VARCHAR;
EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT 0, SQLERRM::VARCHAR;
END;
$$;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_crm_automation_delete(p_rule_id bigint, p_user_id integer DEFAULT NULL::integer) RETURNS TABLE(ok integer, mensaje character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE crm."AutomationRule"
    SET    "IsDeleted" = TRUE, "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
    WHERE  "RuleId" = p_rule_id AND "IsDeleted" = FALSE;
    IF NOT FOUND THEN
        RETURN QUERY SELECT 0, 'Regla no encontrada'::VARCHAR;
        RETURN;
    END IF;
    RETURN QUERY SELECT 1, 'Regla eliminada correctamente'::VARCHAR;
END;
$$;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_crm_automation_getlogs(p_rule_id bigint DEFAULT NULL::bigint, p_lead_id bigint DEFAULT NULL::bigint, p_limit integer DEFAULT 50) RETURNS TABLE("LogId" bigint, "RuleId" bigint, "RuleName" character varying, "LeadId" bigint, "LeadCode" character varying, "ActionTaken" character varying, "ActionResult" text, "ExecutedAt" timestamp without time zone)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT al."LogId", al."RuleId", r."RuleName"::VARCHAR, al."LeadId",
           COALESCE(l."LeadCode", ''::VARCHAR)::VARCHAR, al."ActionTaken"::VARCHAR,
           al."ActionResult", al."ExecutedAt"
    FROM   crm."AutomationLog" al
    JOIN   crm."AutomationRule" r ON r."RuleId" = al."RuleId"
    LEFT JOIN crm."Lead" l        ON l."LeadId" = al."LeadId"
    WHERE  (p_rule_id IS NULL OR al."RuleId" = p_rule_id)
      AND  (p_lead_id IS NULL OR al."LeadId" = p_lead_id)
    ORDER BY al."ExecutedAt" DESC
    LIMIT p_limit;
END;
$$;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_crm_automation_logaction(p_rule_id bigint, p_lead_id bigint, p_action_taken character varying, p_action_result text DEFAULT NULL::text) RETURNS TABLE(ok integer, mensaje character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
    INSERT INTO crm."AutomationLog" ("RuleId", "LeadId", "ActionTaken", "ActionResult", "ExecutedAt")
    VALUES (p_rule_id, p_lead_id, p_action_taken, p_action_result, NOW() AT TIME ZONE 'UTC');
    RETURN QUERY SELECT 1, 'Accion registrada correctamente'::VARCHAR;
EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT 0, ('Error: ' || SQLERRM)::VARCHAR;
END;
$$;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_crm_calllog_get(p_call_log_id bigint) RETURNS TABLE("CallLogId" bigint, "CompanyId" integer, "BranchId" integer, "AgentId" bigint, "QueueId" bigint, "CallDirection" character varying, "CallerNumber" character varying, "CalledNumber" character varying, "CustomerCode" character varying, "CustomerId" bigint, "LeadId" bigint, "ContactName" character varying, "CallStartTime" timestamp without time zone, "CallEndTime" timestamp without time zone, "DurationSeconds" integer, "WaitSeconds" integer, "Result" character varying, "Disposition" character varying, "Notes" text, "RecordingUrl" character varying, "CallbackScheduled" timestamp without time zone, "RelatedDocumentType" character varying, "RelatedDocumentNumber" character varying, "Tags" character varying, "SatisfactionScore" integer, "CreatedAt" timestamp without time zone, "AgentName" character varying, "QueueName" character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT c."CallLogId", c."CompanyId", c."BranchId", c."AgentId", c."QueueId",
           c."CallDirection", c."CallerNumber", c."CalledNumber",
           c."CustomerCode", c."CustomerId", c."LeadId", c."ContactName",
           c."CallStartTime", c."CallEndTime", c."DurationSeconds", c."WaitSeconds",
           c."Result", c."Disposition", c."Notes"::TEXT, c."RecordingUrl",
           c."CallbackScheduled", c."RelatedDocumentType", c."RelatedDocumentNumber",
           c."Tags", c."SatisfactionScore", c."CreatedAt",
           a."AgentName", q."QueueName"
    FROM crm."CallLog" c
    LEFT JOIN crm."Agent" a ON a."AgentId" = c."AgentId"
    LEFT JOIN crm."CallQueue" q ON q."QueueId" = c."QueueId"
    WHERE c."CallLogId" = p_call_log_id AND c."IsDeleted" = FALSE;
END;
$$;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_crm_campaign_get(p_campaign_id bigint) RETURNS TABLE("CampaignId" bigint, "CompanyId" integer, "CampaignCode" character varying, "CampaignName" character varying, "CampaignType" character varying, "QueueId" bigint, "ScriptId" bigint, "StartDate" date, "EndDate" date, "TotalContacts" integer, "ContactedCount" integer, "SuccessCount" integer, "Status" character varying, "Notes" text, "AssignedToUserId" integer, "CreatedAt" timestamp without time zone, "UpdatedAt" timestamp without time zone, "QueueName" character varying, "ScriptName" character varying, "PendingCount" bigint, "CallbackCount" bigint)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT c."CampaignId", c."CompanyId", c."CampaignCode", c."CampaignName",
           c."CampaignType", c."QueueId", c."ScriptId", c."StartDate", c."EndDate",
           c."TotalContacts", c."ContactedCount", c."SuccessCount",
           c."Status", c."Notes"::TEXT, c."AssignedToUserId", c."CreatedAt", c."UpdatedAt",
           q."QueueName", s."ScriptName",
           (SELECT COUNT(*) FROM crm."CampaignContact" cc WHERE cc."CampaignId" = c."CampaignId" AND cc."Status" = 'PENDING' AND cc."IsDeleted" = FALSE),
           (SELECT COUNT(*) FROM crm."CampaignContact" cc WHERE cc."CampaignId" = c."CampaignId" AND cc."Status" = 'CALLBACK' AND cc."IsDeleted" = FALSE)
    FROM crm."Campaign" c
    LEFT JOIN crm."CallQueue" q ON q."QueueId" = c."QueueId"
    LEFT JOIN crm."CallScript" s ON s."ScriptId" = c."ScriptId"
    WHERE c."CampaignId" = p_campaign_id AND c."IsDeleted" = FALSE;
END;
$$;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_crm_campaign_getnextcontact(p_campaign_id bigint, p_agent_id bigint) RETURNS TABLE("CampaignContactId" bigint, "CampaignId" bigint, "CustomerId" bigint, "LeadId" bigint, "ContactName" character varying, "Phone" character varying, "Email" character varying, "Status" character varying, "Attempts" integer, "LastAttempt" timestamp without time zone, "LastResult" character varying, "CallbackDate" timestamp without time zone, "AssignedAgentId" bigint, "Notes" text, "Priority" character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT cc."CampaignContactId", cc."CampaignId", cc."CustomerId", cc."LeadId",
           cc."ContactName", cc."Phone", cc."Email", cc."Status",
           cc."Attempts", cc."LastAttempt", cc."LastResult",
           cc."CallbackDate", cc."AssignedAgentId", cc."Notes"::TEXT, cc."Priority"
    FROM crm."CampaignContact" cc
    WHERE cc."CampaignId" = p_campaign_id AND cc."IsDeleted" = FALSE
      AND (cc."AssignedAgentId" IS NULL OR cc."AssignedAgentId" = p_agent_id)
      AND cc."Status" IN ('PENDING', 'CALLBACK')
      AND ((cc."Status" = 'CALLBACK' AND cc."CallbackDate" <= NOW() AT TIME ZONE 'UTC') OR cc."Status" = 'PENDING')
    ORDER BY CASE cc."Status" WHEN 'CALLBACK' THEN 0 ELSE 1 END,
             CASE cc."Priority" WHEN 'HIGH' THEN 0 WHEN 'MEDIUM' THEN 1 ELSE 2 END,
             cc."CallbackDate" NULLS LAST, cc."CampaignContactId"
    LIMIT 1;
END;
$$;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_crm_campaign_logattempt(p_campaign_contact_id bigint, p_result character varying, p_callback_date timestamp without time zone DEFAULT NULL::timestamp without time zone, p_notes text DEFAULT NULL::text, p_user_id integer DEFAULT NULL::integer) RETURNS TABLE(ok integer, mensaje character varying)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_new_status VARCHAR;
    v_camp_id    BIGINT;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM crm."CampaignContact" WHERE "CampaignContactId" = p_campaign_contact_id AND "IsDeleted" = FALSE) THEN
        RETURN QUERY SELECT 0, 'Contacto de campana no encontrado'::VARCHAR;
        RETURN;
    END IF;
    v_new_status := CASE
        WHEN p_callback_date IS NOT NULL THEN 'CALLBACK'
        WHEN p_result IN ('ANSWERED', 'SALE', 'APPOINTMENT', 'COLLECTION_PROMISE') THEN 'COMPLETED'
        WHEN p_result IN ('DO_NOT_CALL', 'WRONG_NUMBER') THEN 'DO_NOT_CALL'
        ELSE 'CALLED'
    END;
    UPDATE crm."CampaignContact"
    SET    "Attempts" = "Attempts" + 1, "LastAttempt" = NOW() AT TIME ZONE 'UTC',
           "LastResult" = p_result, "Status" = v_new_status, "CallbackDate" = p_callback_date,
           "Notes" = COALESCE(p_notes, "Notes"), "UpdatedByUserId" = p_user_id,
           "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
    WHERE  "CampaignContactId" = p_campaign_contact_id AND "IsDeleted" = FALSE;
    SELECT "CampaignId" INTO v_camp_id FROM crm."CampaignContact" WHERE "CampaignContactId" = p_campaign_contact_id;
    UPDATE crm."Campaign"
    SET    "ContactedCount" = (SELECT COUNT(*) FROM crm."CampaignContact" WHERE "CampaignId" = v_camp_id AND "Status" NOT IN ('PENDING') AND "IsDeleted" = FALSE),
           "SuccessCount"   = (SELECT COUNT(*) FROM crm."CampaignContact" WHERE "CampaignId" = v_camp_id AND "Status" = 'COMPLETED' AND "IsDeleted" = FALSE),
           "UpdatedAt"      = NOW() AT TIME ZONE 'UTC'
    WHERE  "CampaignId" = v_camp_id;
    RETURN QUERY SELECT 1, 'OK'::VARCHAR;
EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT 0, SQLERRM::VARCHAR;
END;
$$;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_crm_campaign_updatestatus(p_campaign_id bigint, p_status character varying, p_user_id integer) RETURNS TABLE(ok integer, mensaje character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM crm."Campaign" WHERE "CampaignId" = p_campaign_id AND "IsDeleted" = FALSE) THEN
        RETURN QUERY SELECT 0, 'Campana no encontrada'::VARCHAR;
        RETURN;
    END IF;
    UPDATE crm."Campaign"
    SET    "Status" = p_status, "UpdatedByUserId" = p_user_id, "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
    WHERE  "CampaignId" = p_campaign_id AND "IsDeleted" = FALSE;
    RETURN QUERY SELECT 1, 'OK'::VARCHAR;
EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT 0, SQLERRM::VARCHAR;
END;
$$;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_crm_lead_changestage(p_lead_id integer, p_new_stage_id integer, p_notes character varying DEFAULT NULL::character varying, p_user_id integer DEFAULT NULL::integer) RETURNS TABLE(ok integer, mensaje character varying)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_old_stage_id INT;
BEGIN
    SELECT "StageId" INTO v_old_stage_id FROM crm."Lead" WHERE "LeadId" = p_lead_id;
    IF v_old_stage_id IS NULL THEN
        RETURN QUERY SELECT 0, 'Lead no encontrado'::VARCHAR;
        RETURN;
    END IF;
    UPDATE crm."Lead" SET "StageId" = p_new_stage_id, "UpdatedByUserId" = p_user_id, "UpdatedAt" = NOW() AT TIME ZONE 'UTC' WHERE "LeadId" = p_lead_id;
    INSERT INTO crm."LeadHistory" ("LeadId", "ChangeType", "FromStageId", "ToStageId", "Notes", "ChangedByUserId", "CreatedAt")
    VALUES (p_lead_id, 'STAGE_CHANGE', v_old_stage_id, p_new_stage_id, p_notes, p_user_id, NOW() AT TIME ZONE 'UTC');
    RETURN QUERY SELECT 1, 'OK'::VARCHAR;
EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT 0, SQLERRM::VARCHAR;
END;
$$;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_crm_lead_close(p_lead_id integer, p_is_won boolean, p_lost_reason character varying DEFAULT NULL::character varying, p_customer_id bigint DEFAULT NULL::bigint, p_user_id integer DEFAULT NULL::integer) RETURNS TABLE(ok integer, mensaje character varying)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_old_stage_id INT;
    v_closed_stage_id INT;
    v_new_status VARCHAR(20);
BEGIN
    v_new_status := CASE WHEN p_is_won THEN 'WON' ELSE 'LOST' END;
    SELECT "StageId" INTO v_old_stage_id FROM crm."Lead" WHERE "LeadId" = p_lead_id;
    IF v_old_stage_id IS NULL THEN
        RETURN QUERY SELECT 0, 'Lead no encontrado'::VARCHAR;
        RETURN;
    END IF;
    SELECT s."StageId" INTO v_closed_stage_id
    FROM crm."PipelineStage" s JOIN crm."Lead" l ON l."PipelineId" = s."PipelineId"
    WHERE l."LeadId" = p_lead_id AND s."IsClosed" = TRUE AND s."IsWon" = p_is_won LIMIT 1;
    UPDATE crm."Lead"
    SET "Status" = v_new_status, "StageId" = COALESCE(v_closed_stage_id, "StageId"),
        "LostReason" = p_lost_reason, "CustomerId" = p_customer_id,
        "WonAt" = CASE WHEN p_is_won THEN NOW() AT TIME ZONE 'UTC' ELSE NULL END,
        "LostAt" = CASE WHEN NOT p_is_won THEN NOW() AT TIME ZONE 'UTC' ELSE NULL END,
        "UpdatedByUserId" = p_user_id, "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
    WHERE "LeadId" = p_lead_id;
    INSERT INTO crm."LeadHistory" ("LeadId", "ChangeType", "FromStageId", "ToStageId", "Notes", "ChangedByUserId", "CreatedAt")
    VALUES (p_lead_id, 'STATUS', v_old_stage_id, COALESCE(v_closed_stage_id, v_old_stage_id),
            COALESCE(p_lost_reason, 'Cerrado como ' || v_new_status), p_user_id, NOW() AT TIME ZONE 'UTC');
    RETURN QUERY SELECT 1, 'OK'::VARCHAR;
EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT 0, SQLERRM::VARCHAR;
END;
$$;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_crm_lead_get(p_lead_id integer) RETURNS TABLE("LeadId" bigint, "LeadCode" character varying, "CompanyId" integer, "BranchId" integer, "PipelineId" bigint, "PipelineName" character varying, "StageId" bigint, "StageName" character varying, "StageColor" character varying, "ContactName" character varying, "CompanyName" character varying, "Email" character varying, "Phone" character varying, "Source" character varying, "Status" character varying, "AssignedToUserId" integer, "EstimatedValue" numeric, "CurrencyCode" character, "ExpectedCloseDate" date, "Notes" text, "Tags" character varying, "Priority" character varying, "LostReason" character varying, "CustomerId" bigint, "CreatedAt" timestamp without time zone, "UpdatedAt" timestamp without time zone, _section character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT l."LeadId", l."LeadCode", l."CompanyId", l."BranchId",
           l."PipelineId", p."PipelineName", l."StageId", s."StageName", s."Color",
           l."ContactName", l."CompanyName", l."Email", l."Phone",
           l."Source", l."Status", l."AssignedToUserId",
           l."EstimatedValue", l."CurrencyCode", l."ExpectedCloseDate",
           l."Notes"::TEXT, l."Tags", l."Priority", l."LostReason", l."CustomerId",
           l."CreatedAt", l."UpdatedAt", 'header'::VARCHAR
    FROM crm."Lead" l
    LEFT JOIN crm."Pipeline" p ON p."PipelineId" = l."PipelineId"
    LEFT JOIN crm."PipelineStage" s ON s."StageId" = l."StageId"
    WHERE l."LeadId" = p_lead_id;
END;
$$;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_crm_lead_getdetail(p_lead_id bigint) RETURNS TABLE("LeadId" bigint, "CompanyId" integer, "BranchId" integer, "PipelineId" bigint, "StageId" bigint, "LeadCode" character varying, "ContactName" character varying, "CompanyName" character varying, "Email" character varying, "Phone" character varying, "Source" character varying, "AssignedToUserId" integer, "CustomerId" bigint, "EstimatedValue" numeric, "CurrencyCode" character varying, "ExpectedCloseDate" date, "LostReason" character varying, "Notes" text, "Tags" character varying, "Priority" character varying, "Status" character varying, "WonAt" timestamp without time zone, "LostAt" timestamp without time zone, "CreatedAt" timestamp without time zone, "UpdatedAt" timestamp without time zone, "CreatedByUserId" integer, "UpdatedByUserId" integer, "RowVer" integer, "StageName" character varying, "StageColor" character varying, "StageProbability" integer, "PipelineName" character varying, "AssignedToName" character varying, "CurrentScore" integer, "DaysInCurrentStage" integer, "TotalActivities" integer, "PendingActivities" integer, "DaysSinceLastActivity" integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_now TIMESTAMP := NOW() AT TIME ZONE 'UTC';
BEGIN
    RETURN QUERY
    SELECT l."LeadId", l."CompanyId", l."BranchId", l."PipelineId", l."StageId",
           l."LeadCode"::VARCHAR, l."ContactName"::VARCHAR, l."CompanyName"::VARCHAR,
           l."Email"::VARCHAR, l."Phone"::VARCHAR, l."Source"::VARCHAR,
           l."AssignedToUserId", l."CustomerId", l."EstimatedValue"::NUMERIC,
           l."CurrencyCode"::VARCHAR, l."ExpectedCloseDate", l."LostReason"::VARCHAR,
           l."Notes", l."Tags"::VARCHAR, l."Priority"::VARCHAR, l."Status"::VARCHAR,
           l."WonAt", l."LostAt", l."CreatedAt", l."UpdatedAt",
           l."CreatedByUserId", l."UpdatedByUserId", l."RowVer",
           s."StageName"::VARCHAR, s."Color"::VARCHAR, s."Probability"::INT,
           p."PipelineName"::VARCHAR, u."FullName"::VARCHAR,
           COALESCE((SELECT ls."Score" FROM crm."LeadScore" ls WHERE ls."LeadId" = l."LeadId" ORDER BY ls."ScoreDate" DESC LIMIT 1), 0)::INT,
           COALESCE((SELECT EXTRACT(EPOCH FROM (v_now - h."CreatedAt"))::INT / 86400 FROM crm."LeadHistory" h WHERE h."LeadId" = l."LeadId" AND h."ChangeType" = 'STAGE_CHANGE' ORDER BY h."CreatedAt" DESC LIMIT 1), EXTRACT(EPOCH FROM (v_now - l."CreatedAt"))::INT / 86400)::INT,
           (SELECT COUNT(*)::INT FROM crm."Activity" a WHERE a."LeadId" = l."LeadId" AND a."IsDeleted" = FALSE),
           (SELECT COUNT(*)::INT FROM crm."Activity" a WHERE a."LeadId" = l."LeadId" AND a."IsDeleted" = FALSE AND a."IsCompleted" = FALSE),
           COALESCE((SELECT EXTRACT(EPOCH FROM (v_now - MAX(a."CreatedAt")))::INT / 86400 FROM crm."Activity" a WHERE a."LeadId" = l."LeadId" AND a."IsDeleted" = FALSE), -1)::INT
    FROM crm."Lead" l
    JOIN crm."PipelineStage" s ON s."StageId" = l."StageId"
    JOIN crm."Pipeline" p ON p."PipelineId" = l."PipelineId"
    LEFT JOIN sec."User" u ON u."UserId" = l."AssignedToUserId"
    WHERE l."LeadId" = p_lead_id AND l."IsDeleted" = FALSE;
END;
$$;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_crm_lead_gethistory(p_lead_id bigint) RETURNS TABLE("HistoryId" bigint, "ChangeType" character varying, "FromStageName" character varying, "ToStageName" character varying, "ChangedByName" character varying, "Notes" character varying, "CreatedAt" timestamp without time zone)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT h."HistoryId", h."ChangeType"::VARCHAR,
           sf."StageName"::VARCHAR, st."StageName"::VARCHAR,
           u."FullName"::VARCHAR, h."Notes"::VARCHAR, h."CreatedAt"
    FROM crm."LeadHistory" h
    LEFT JOIN crm."PipelineStage" sf ON sf."StageId" = h."FromStageId"
    LEFT JOIN crm."PipelineStage" st ON st."StageId" = h."ToStageId"
    LEFT JOIN sec."User" u ON u."UserId" = h."ChangedByUserId"
    WHERE h."LeadId" = p_lead_id
    ORDER BY h."CreatedAt" DESC;
END;
$$;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_crm_lead_update(p_lead_id integer, p_stage_id integer DEFAULT NULL::integer, p_contact_name character varying DEFAULT NULL::character varying, p_company_name character varying DEFAULT NULL::character varying, p_email character varying DEFAULT NULL::character varying, p_phone character varying DEFAULT NULL::character varying, p_assigned_to_user_id integer DEFAULT NULL::integer, p_estimated_value numeric DEFAULT NULL::numeric, p_expected_close_date timestamp without time zone DEFAULT NULL::timestamp without time zone, p_notes text DEFAULT NULL::text, p_tags character varying DEFAULT NULL::character varying, p_priority character varying DEFAULT NULL::character varying, p_user_id integer DEFAULT NULL::integer) RETURNS TABLE(ok integer, mensaje character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE crm."Lead"
    SET "StageId" = COALESCE(p_stage_id, "StageId"), "ContactName" = COALESCE(p_contact_name, "ContactName"),
        "CompanyName" = COALESCE(p_company_name, "CompanyName"), "Email" = COALESCE(p_email, "Email"),
        "Phone" = COALESCE(p_phone, "Phone"), "AssignedToUserId" = COALESCE(p_assigned_to_user_id, "AssignedToUserId"),
        "EstimatedValue" = COALESCE(p_estimated_value, "EstimatedValue"),
        "ExpectedCloseDate" = COALESCE(p_expected_close_date, "ExpectedCloseDate"),
        "Notes" = COALESCE(p_notes, "Notes"), "Tags" = COALESCE(p_tags, "Tags"),
        "Priority" = COALESCE(p_priority, "Priority"),
        "UpdatedByUserId" = p_user_id, "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
    WHERE "LeadId" = p_lead_id;
    RETURN QUERY SELECT 1, 'OK'::VARCHAR;
EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT 0, SQLERRM::VARCHAR;
END;
$$;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_crm_leadscore_calculate(p_lead_id bigint, p_user_id integer DEFAULT NULL::integer) RETURNS TABLE(ok integer, mensaje character varying, "Score" integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_score INT := 0; v_factors JSONB := '{}';
    v_now TIMESTAMP := NOW() AT TIME ZONE 'UTC';
    v_7d_ago TIMESTAMP := (NOW() AT TIME ZONE 'UTC') - INTERVAL '7 days';
    v_30d_ago TIMESTAMP := (NOW() AT TIME ZONE 'UTC') - INTERVAL '30 days';
    v_lead RECORD; v_act_7d INT := 0; v_act_30d INT := 0; v_act_total INT := 0; v_last_act TIMESTAMP;
BEGIN
    SELECT l."LeadId", l."Email", l."Phone", l."CompanyName", l."EstimatedValue",
           l."ExpectedCloseDate", l."Priority", l."Status", l."Notes"
    INTO v_lead FROM crm."Lead" l WHERE l."LeadId" = p_lead_id AND l."IsDeleted" = FALSE;
    IF v_lead."LeadId" IS NULL THEN RETURN QUERY SELECT 0, 'Lead no encontrado'::VARCHAR, 0; RETURN; END IF;
    IF v_lead."Email" IS NOT NULL AND v_lead."Email" <> '' THEN v_score := v_score + 10; v_factors := v_factors || '{"email": 10}'; END IF;
    IF v_lead."Phone" IS NOT NULL AND v_lead."Phone" <> '' THEN v_score := v_score + 8; v_factors := v_factors || '{"phone": 8}'; END IF;
    IF v_lead."CompanyName" IS NOT NULL AND v_lead."CompanyName" <> '' THEN v_score := v_score + 5; v_factors := v_factors || '{"companyName": 5}'; END IF;
    IF COALESCE(v_lead."EstimatedValue", 0) > 0 THEN v_score := v_score + 15; v_factors := v_factors || '{"estimatedValue": 15}'; END IF;
    IF COALESCE(v_lead."EstimatedValue", 0) > 10000 THEN v_score := v_score + 10; v_factors := v_factors || '{"highValue": 10}'; END IF;
    IF v_lead."ExpectedCloseDate" IS NOT NULL THEN v_score := v_score + 5; v_factors := v_factors || '{"expectedCloseDate": 5}'; END IF;
    IF v_lead."Priority" IN ('HIGH', 'URGENT') THEN v_score := v_score + 10; v_factors := v_factors || '{"highPriority": 10}'; END IF;
    IF v_lead."Status" = 'OPEN' THEN v_score := v_score + 5; v_factors := v_factors || '{"statusOpen": 5}'; END IF;
    IF v_lead."Notes" IS NOT NULL AND v_lead."Notes" <> '' THEN v_score := v_score + 5; v_factors := v_factors || '{"hasNotes": 5}'; END IF;
    SELECT COUNT(*) FILTER (WHERE a."CreatedAt" >= v_7d_ago),
           COUNT(*) FILTER (WHERE a."CreatedAt" >= v_30d_ago AND a."CreatedAt" < v_7d_ago),
           COUNT(*), MAX(a."CreatedAt")
    INTO v_act_7d, v_act_30d, v_act_total, v_last_act
    FROM crm."Activity" a WHERE a."LeadId" = p_lead_id AND a."IsDeleted" = FALSE;
    IF v_act_7d > 0 THEN v_score := v_score + 15; v_factors := v_factors || '{"recentActivity7d": 15}';
    ELSIF v_act_30d > 0 THEN v_score := v_score + 7; v_factors := v_factors || '{"recentActivity30d": 7}';
    ELSIF v_act_total > 0 AND v_last_act < v_30d_ago THEN v_score := v_score - 10; v_factors := v_factors || '{"staleActivity": -10}'; END IF;
    IF v_act_total > 5 THEN v_score := v_score + 5; v_factors := v_factors || '{"manyActivities": 5}'; END IF;
    v_score := GREATEST(0, LEAST(100, v_score));
    INSERT INTO crm."LeadScore" ("LeadId", "Score", "ScoreDate", "Factors", "CalculatedByUserId")
    VALUES (p_lead_id, v_score, v_now, v_factors, p_user_id);
    RETURN QUERY SELECT 1, 'Score calculado correctamente'::VARCHAR, v_score;
END;
$$;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_crm_leadscore_get(p_lead_id bigint) RETURNS TABLE("Score" integer, "ScoreDate" timestamp without time zone, "Factors" jsonb)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT ls."Score", ls."ScoreDate", ls."Factors"
    FROM crm."LeadScore" ls WHERE ls."LeadId" = p_lead_id
    ORDER BY ls."ScoreDate" DESC LIMIT 1;
END;
$$;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_crm_pipeline_getstages(p_pipeline_id integer) RETURNS TABLE("StageId" bigint, "PipelineId" bigint, "StageCode" character varying, "StageName" character varying, "StageOrder" integer, "Probability" numeric, "DaysExpected" integer, "Color" character varying, "IsClosed" boolean, "IsWon" boolean, "IsActive" boolean)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT s."StageId", s."PipelineId", s."StageCode", s."StageName",
           s."StageOrder", s."Probability", s."DaysExpected", s."Color",
           s."IsClosed", s."IsWon", s."IsActive"
    FROM crm."PipelineStage" s
    WHERE s."PipelineId" = p_pipeline_id AND s."IsDeleted" = FALSE
    ORDER BY s."StageOrder";
END;
$$;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_crm_stage_upsert(p_pipeline_id integer, p_stage_id integer DEFAULT NULL::integer, p_stage_code character varying DEFAULT NULL::character varying, p_stage_name character varying DEFAULT NULL::character varying, p_stage_order integer DEFAULT 0, p_probability numeric DEFAULT 0, p_days_expected integer DEFAULT 0, p_color character varying DEFAULT NULL::character varying, p_is_closed boolean DEFAULT false, p_is_won boolean DEFAULT false, p_is_active boolean DEFAULT true, p_user_id integer DEFAULT NULL::integer) RETURNS TABLE(ok integer, mensaje character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF p_stage_id IS NULL THEN
        INSERT INTO crm."PipelineStage" ("PipelineId", "StageCode", "StageName", "StageOrder", "Probability", "DaysExpected", "Color", "IsClosed", "IsWon", "IsActive", "CreatedByUserId", "UpdatedByUserId", "CreatedAt", "UpdatedAt")
        VALUES (p_pipeline_id, p_stage_code, p_stage_name, p_stage_order, p_probability, p_days_expected, p_color, p_is_closed, p_is_won, p_is_active, p_user_id, p_user_id, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC');
    ELSE
        UPDATE crm."PipelineStage"
        SET "StageCode" = p_stage_code, "StageName" = p_stage_name, "StageOrder" = p_stage_order,
            "Probability" = p_probability, "DaysExpected" = p_days_expected, "Color" = p_color,
            "IsClosed" = p_is_closed, "IsWon" = p_is_won, "IsActive" = p_is_active,
            "UpdatedByUserId" = p_user_id, "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
        WHERE "StageId" = p_stage_id AND "PipelineId" = p_pipeline_id;
    END IF;
    RETURN QUERY SELECT 1, 'OK'::VARCHAR;
EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT 0, SQLERRM::VARCHAR;
END;
$$;
-- +goose StatementEnd
