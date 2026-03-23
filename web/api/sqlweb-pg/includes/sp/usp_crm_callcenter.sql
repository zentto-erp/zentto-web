-- ============================================================
-- DatqBoxWeb PostgreSQL - usp_crm_callcenter.sql
-- Funciones del modulo CRM - Call Center
-- (Colas, Agentes, Llamadas, Scripts, Campanas, Dashboard)
-- Fecha: 2026-03-22
-- ============================================================

-- ═══════════════════════════════════════════════════════════════════════════════
--  TABLAS
-- ═══════════════════════════════════════════════════════════════════════════════

-- ── 1. crm.CallQueue ────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS crm."CallQueue" (
    "QueueId"           BIGINT         GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    "CompanyId"         INT            NOT NULL REFERENCES cfg."Company"("CompanyId"),
    "QueueCode"         VARCHAR(20)    NOT NULL,
    "QueueName"         VARCHAR(100)   NOT NULL,
    "QueueType"         VARCHAR(20)    NOT NULL DEFAULT 'GENERAL',
    "Description"       VARCHAR(500),
    "IsActive"          BOOLEAN        NOT NULL DEFAULT TRUE,
    "CreatedAt"         TIMESTAMP      NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "UpdatedAt"         TIMESTAMP      NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "CreatedByUserId"   INT,
    "UpdatedByUserId"   INT,
    "IsDeleted"         BOOLEAN        NOT NULL DEFAULT FALSE,
    "DeletedAt"         TIMESTAMP,
    "DeletedByUserId"   INT,
    CONSTRAINT "UQ_CallQueue_Code" UNIQUE ("CompanyId", "QueueCode"),
    CONSTRAINT "CK_CallQueue_Type" CHECK ("QueueType" IN ('SALES','SUPPORT','COLLECTIONS','GENERAL'))
);

-- ── 2. crm.Agent ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS crm."Agent" (
    "AgentId"              BIGINT         GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    "CompanyId"            INT            NOT NULL REFERENCES cfg."Company"("CompanyId"),
    "UserId"               INT            NOT NULL REFERENCES sec."User"("UserId"),
    "QueueId"              BIGINT         REFERENCES crm."CallQueue"("QueueId"),
    "AgentCode"            VARCHAR(20)    NOT NULL,
    "AgentName"            VARCHAR(200)   NOT NULL,
    "Extension"            VARCHAR(20),
    "Status"               VARCHAR(20)    NOT NULL DEFAULT 'OFFLINE',
    "MaxConcurrentCalls"   INT            NOT NULL DEFAULT 1,
    "IsActive"             BOOLEAN        NOT NULL DEFAULT TRUE,
    "CreatedAt"            TIMESTAMP      NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "UpdatedAt"            TIMESTAMP      NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "CreatedByUserId"      INT,
    "UpdatedByUserId"      INT,
    "IsDeleted"            BOOLEAN        NOT NULL DEFAULT FALSE,
    "DeletedAt"            TIMESTAMP,
    "DeletedByUserId"      INT,
    CONSTRAINT "UQ_Agent_Code" UNIQUE ("CompanyId", "AgentCode"),
    CONSTRAINT "CK_Agent_Status" CHECK ("Status" IN ('AVAILABLE','BUSY','ON_CALL','BREAK','OFFLINE'))
);

-- ── 3. crm.CallLog ──────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS crm."CallLog" (
    "CallLogId"              BIGINT         GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    "CompanyId"              INT            NOT NULL REFERENCES cfg."Company"("CompanyId"),
    "BranchId"               INT            NOT NULL REFERENCES cfg."Branch"("BranchId"),
    "AgentId"                BIGINT         REFERENCES crm."Agent"("AgentId"),
    "QueueId"                BIGINT         REFERENCES crm."CallQueue"("QueueId"),
    "CallDirection"          VARCHAR(10)    NOT NULL,
    "CallerNumber"           VARCHAR(30)    NOT NULL,
    "CalledNumber"           VARCHAR(30)    NOT NULL,
    "CustomerCode"           VARCHAR(24),
    "CustomerId"             BIGINT         REFERENCES master."Customer"("CustomerId"),
    "LeadId"                 BIGINT         REFERENCES crm."Lead"("LeadId"),
    "ContactName"            VARCHAR(200),
    "CallStartTime"          TIMESTAMP      NOT NULL,
    "CallEndTime"            TIMESTAMP,
    "DurationSeconds"        INT,
    "WaitSeconds"            INT,
    "Result"                 VARCHAR(20)    NOT NULL,
    "Disposition"            VARCHAR(30),
    "Notes"                  TEXT,
    "RecordingUrl"           VARCHAR(500),
    "CallbackScheduled"      TIMESTAMP,
    "RelatedDocumentType"    VARCHAR(30),
    "RelatedDocumentNumber"  VARCHAR(60),
    "Tags"                   VARCHAR(500),
    "SatisfactionScore"      INT,
    "CreatedAt"              TIMESTAMP      NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "UpdatedAt"              TIMESTAMP      NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "CreatedByUserId"        INT,
    "UpdatedByUserId"        INT,
    "IsDeleted"              BOOLEAN        NOT NULL DEFAULT FALSE,
    "DeletedAt"              TIMESTAMP,
    "DeletedByUserId"        INT,
    CONSTRAINT "CK_CallLog_Direction" CHECK ("CallDirection" IN ('INBOUND','OUTBOUND')),
    CONSTRAINT "CK_CallLog_Result" CHECK ("Result" IN ('ANSWERED','NO_ANSWER','BUSY','VOICEMAIL','CALLBACK','TRANSFERRED','DROPPED')),
    CONSTRAINT "CK_CallLog_Score" CHECK ("SatisfactionScore" IS NULL OR ("SatisfactionScore" >= 1 AND "SatisfactionScore" <= 5))
);

CREATE INDEX IF NOT EXISTS "IX_CallLog_CompanyDate" ON crm."CallLog" ("CompanyId", "CallStartTime" DESC);
CREATE INDEX IF NOT EXISTS "IX_CallLog_CustomerCode" ON crm."CallLog" ("CompanyId", "CustomerCode");
CREATE INDEX IF NOT EXISTS "IX_CallLog_Agent" ON crm."CallLog" ("AgentId", "CallStartTime" DESC);

-- ── 4. crm.CallScript ──────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS crm."CallScript" (
    "ScriptId"          BIGINT         GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    "CompanyId"         INT            NOT NULL REFERENCES cfg."Company"("CompanyId"),
    "ScriptCode"        VARCHAR(20)    NOT NULL,
    "ScriptName"        VARCHAR(200)   NOT NULL,
    "QueueType"         VARCHAR(20)    NOT NULL,
    "Content"           TEXT           NOT NULL,
    "Version"           INT            NOT NULL DEFAULT 1,
    "IsActive"          BOOLEAN        NOT NULL DEFAULT TRUE,
    "CreatedAt"         TIMESTAMP      NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "UpdatedAt"         TIMESTAMP      NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "CreatedByUserId"   INT,
    "UpdatedByUserId"   INT,
    "IsDeleted"         BOOLEAN        NOT NULL DEFAULT FALSE,
    "DeletedAt"         TIMESTAMP,
    "DeletedByUserId"   INT,
    CONSTRAINT "UQ_CallScript_Code" UNIQUE ("CompanyId", "ScriptCode")
);

-- ── 5. crm.Campaign ────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS crm."Campaign" (
    "CampaignId"        BIGINT         GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    "CompanyId"         INT            NOT NULL REFERENCES cfg."Company"("CompanyId"),
    "CampaignCode"      VARCHAR(20)    NOT NULL,
    "CampaignName"      VARCHAR(200)   NOT NULL,
    "CampaignType"      VARCHAR(30)    NOT NULL,
    "QueueId"           BIGINT         REFERENCES crm."CallQueue"("QueueId"),
    "ScriptId"          BIGINT         REFERENCES crm."CallScript"("ScriptId"),
    "StartDate"         DATE           NOT NULL,
    "EndDate"           DATE,
    "TotalContacts"     INT            NOT NULL DEFAULT 0,
    "ContactedCount"    INT            NOT NULL DEFAULT 0,
    "SuccessCount"      INT            NOT NULL DEFAULT 0,
    "Status"            VARCHAR(20)    NOT NULL DEFAULT 'DRAFT',
    "Notes"             TEXT,
    "AssignedToUserId"  INT            REFERENCES sec."User"("UserId"),
    "CreatedAt"         TIMESTAMP      NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "UpdatedAt"         TIMESTAMP      NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "CreatedByUserId"   INT,
    "UpdatedByUserId"   INT,
    "IsDeleted"         BOOLEAN        NOT NULL DEFAULT FALSE,
    "DeletedAt"         TIMESTAMP,
    "DeletedByUserId"   INT,
    CONSTRAINT "UQ_Campaign_Code" UNIQUE ("CompanyId", "CampaignCode"),
    CONSTRAINT "CK_Campaign_Type" CHECK ("CampaignType" IN ('OUTBOUND_SALES','OUTBOUND_COLLECTION','OUTBOUND_SURVEY','OUTBOUND_FOLLOWUP')),
    CONSTRAINT "CK_Campaign_Status" CHECK ("Status" IN ('DRAFT','ACTIVE','PAUSED','COMPLETED','CANCELLED'))
);

-- ── 6. crm.CampaignContact ─────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS crm."CampaignContact" (
    "CampaignContactId"  BIGINT         GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    "CampaignId"         BIGINT         NOT NULL REFERENCES crm."Campaign"("CampaignId"),
    "CustomerId"         BIGINT         REFERENCES master."Customer"("CustomerId"),
    "LeadId"             BIGINT         REFERENCES crm."Lead"("LeadId"),
    "ContactName"        VARCHAR(200)   NOT NULL,
    "Phone"              VARCHAR(30)    NOT NULL,
    "Email"              VARCHAR(150),
    "Status"             VARCHAR(20)    NOT NULL DEFAULT 'PENDING',
    "Attempts"           INT            NOT NULL DEFAULT 0,
    "LastAttempt"        TIMESTAMP,
    "LastResult"         VARCHAR(30),
    "CallbackDate"       TIMESTAMP,
    "AssignedAgentId"    BIGINT         REFERENCES crm."Agent"("AgentId"),
    "Notes"              TEXT,
    "Priority"           VARCHAR(10)    NOT NULL DEFAULT 'MEDIUM',
    "CreatedAt"          TIMESTAMP      NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "UpdatedAt"          TIMESTAMP      NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "CreatedByUserId"    INT,
    "UpdatedByUserId"    INT,
    "IsDeleted"          BOOLEAN        NOT NULL DEFAULT FALSE,
    "DeletedAt"          TIMESTAMP,
    "DeletedByUserId"    INT,
    CONSTRAINT "CK_CampaignContact_Status" CHECK ("Status" IN ('PENDING','CALLED','CALLBACK','COMPLETED','SKIPPED','DO_NOT_CALL')),
    CONSTRAINT "CK_CampaignContact_Priority" CHECK ("Priority" IN ('LOW','MEDIUM','HIGH'))
);

CREATE INDEX IF NOT EXISTS "IX_CampaignContact_Status" ON crm."CampaignContact" ("CampaignId", "Status", "Priority");


-- ═══════════════════════════════════════════════════════════════════════════════
--  FUNCIONES (equivalentes a SPs de SQL Server)
-- ═══════════════════════════════════════════════════════════════════════════════

-- =============================================================================
--  usp_CRM_CallQueue_List
-- =============================================================================
DROP FUNCTION IF EXISTS usp_crm_callqueue_list(INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_crm_callqueue_list(
    p_company_id INT
)
RETURNS TABLE(
    "QueueId"     BIGINT,
    "CompanyId"   INT,
    "QueueCode"   VARCHAR,
    "QueueName"   VARCHAR,
    "QueueType"   VARCHAR,
    "Description" VARCHAR,
    "IsActive"    BOOLEAN,
    "CreatedAt"   TIMESTAMP,
    "UpdatedAt"   TIMESTAMP,
    "AgentCount"  BIGINT
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        q."QueueId", q."CompanyId", q."QueueCode", q."QueueName",
        q."QueueType", q."Description", q."IsActive", q."CreatedAt", q."UpdatedAt",
        (SELECT COUNT(*) FROM crm."Agent" a WHERE a."QueueId" = q."QueueId" AND a."IsActive" = TRUE AND a."IsDeleted" = FALSE)
    FROM crm."CallQueue" q
    WHERE q."CompanyId" = p_company_id
      AND q."IsDeleted" = FALSE
    ORDER BY q."QueueName";
END;
$$;

-- =============================================================================
--  usp_CRM_CallQueue_Upsert
-- =============================================================================
DROP FUNCTION IF EXISTS usp_crm_callqueue_upsert(INT, BIGINT, VARCHAR, VARCHAR, VARCHAR, VARCHAR, BOOLEAN, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_crm_callqueue_upsert(
    p_company_id   INT,
    p_queue_id     BIGINT   DEFAULT NULL,
    p_queue_code   VARCHAR  DEFAULT NULL,
    p_queue_name   VARCHAR  DEFAULT NULL,
    p_queue_type   VARCHAR  DEFAULT 'GENERAL',
    p_description  VARCHAR  DEFAULT NULL,
    p_is_active    BOOLEAN  DEFAULT TRUE,
    p_user_id      INT      DEFAULT NULL
)
RETURNS TABLE("ok" INT, "mensaje" VARCHAR)
LANGUAGE plpgsql AS $$
BEGIN
    IF p_queue_id IS NULL THEN
        IF EXISTS (SELECT 1 FROM crm."CallQueue" WHERE "CompanyId" = p_company_id AND "QueueCode" = p_queue_code AND "IsDeleted" = FALSE) THEN
            RETURN QUERY SELECT 0, ('Ya existe una cola con el codigo ' || p_queue_code)::VARCHAR;
            RETURN;
        END IF;

        INSERT INTO crm."CallQueue" ("CompanyId", "QueueCode", "QueueName", "QueueType", "Description", "IsActive", "CreatedByUserId", "UpdatedByUserId", "CreatedAt", "UpdatedAt")
        VALUES (p_company_id, p_queue_code, p_queue_name, p_queue_type, p_description, p_is_active, p_user_id, p_user_id, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC');
    ELSE
        UPDATE crm."CallQueue"
        SET    "QueueCode"       = p_queue_code,
               "QueueName"       = p_queue_name,
               "QueueType"       = p_queue_type,
               "Description"     = p_description,
               "IsActive"        = p_is_active,
               "UpdatedByUserId" = p_user_id,
               "UpdatedAt"       = NOW() AT TIME ZONE 'UTC'
        WHERE  "QueueId" = p_queue_id AND "CompanyId" = p_company_id AND "IsDeleted" = FALSE;
    END IF;

    RETURN QUERY SELECT 1, 'OK'::VARCHAR;

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT 0, SQLERRM::VARCHAR;
END;
$$;

-- =============================================================================
--  usp_CRM_Agent_List
-- =============================================================================
DROP FUNCTION IF EXISTS usp_crm_agent_list(INT, BIGINT, VARCHAR, INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_crm_agent_list(
    p_company_id INT,
    p_queue_id   BIGINT   DEFAULT NULL,
    p_status     VARCHAR  DEFAULT NULL,
    p_page       INT      DEFAULT 1,
    p_limit      INT      DEFAULT 50
)
RETURNS TABLE(
    "AgentId"            BIGINT,
    "CompanyId"          INT,
    "UserId"             INT,
    "QueueId"            BIGINT,
    "AgentCode"          VARCHAR,
    "AgentName"          VARCHAR,
    "Extension"          VARCHAR,
    "Status"             VARCHAR,
    "MaxConcurrentCalls" INT,
    "IsActive"           BOOLEAN,
    "CreatedAt"          TIMESTAMP,
    "UpdatedAt"          TIMESTAMP,
    "QueueName"          VARCHAR,
    "TotalCount"         BIGINT
)
LANGUAGE plpgsql AS $$
DECLARE
    v_total BIGINT;
    v_offset INT;
BEGIN
    SELECT COUNT(*) INTO v_total
    FROM crm."Agent" a
    WHERE a."CompanyId" = p_company_id
      AND a."IsDeleted" = FALSE
      AND (p_queue_id IS NULL OR a."QueueId" = p_queue_id)
      AND (p_status IS NULL OR a."Status" = p_status);

    v_offset := (p_page - 1) * p_limit;

    RETURN QUERY
    SELECT
        a."AgentId", a."CompanyId", a."UserId", a."QueueId",
        a."AgentCode", a."AgentName", a."Extension", a."Status",
        a."MaxConcurrentCalls", a."IsActive", a."CreatedAt", a."UpdatedAt",
        q."QueueName",
        v_total
    FROM crm."Agent" a
    LEFT JOIN crm."CallQueue" q ON q."QueueId" = a."QueueId"
    WHERE a."CompanyId" = p_company_id
      AND a."IsDeleted" = FALSE
      AND (p_queue_id IS NULL OR a."QueueId" = p_queue_id)
      AND (p_status IS NULL OR a."Status" = p_status)
    ORDER BY a."AgentName"
    OFFSET v_offset LIMIT p_limit;
END;
$$;

-- =============================================================================
--  usp_CRM_Agent_Upsert
-- =============================================================================
DROP FUNCTION IF EXISTS usp_crm_agent_upsert(INT, BIGINT, INT, BIGINT, VARCHAR, VARCHAR, VARCHAR, INT, BOOLEAN, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_crm_agent_upsert(
    p_company_id          INT,
    p_agent_id            BIGINT   DEFAULT NULL,
    p_user_id_agent       INT      DEFAULT NULL,
    p_queue_id            BIGINT   DEFAULT NULL,
    p_agent_code          VARCHAR  DEFAULT NULL,
    p_agent_name          VARCHAR  DEFAULT NULL,
    p_extension           VARCHAR  DEFAULT NULL,
    p_max_concurrent_calls INT     DEFAULT 1,
    p_is_active           BOOLEAN  DEFAULT TRUE,
    p_admin_user_id       INT      DEFAULT NULL
)
RETURNS TABLE("ok" INT, "mensaje" VARCHAR)
LANGUAGE plpgsql AS $$
BEGIN
    IF p_agent_id IS NULL THEN
        IF EXISTS (SELECT 1 FROM crm."Agent" WHERE "CompanyId" = p_company_id AND "AgentCode" = p_agent_code AND "IsDeleted" = FALSE) THEN
            RETURN QUERY SELECT 0, ('Ya existe un agente con el codigo ' || p_agent_code)::VARCHAR;
            RETURN;
        END IF;

        INSERT INTO crm."Agent" ("CompanyId", "UserId", "QueueId", "AgentCode", "AgentName", "Extension", "MaxConcurrentCalls", "IsActive", "CreatedByUserId", "UpdatedByUserId", "CreatedAt", "UpdatedAt")
        VALUES (p_company_id, p_user_id_agent, p_queue_id, p_agent_code, p_agent_name, p_extension, p_max_concurrent_calls, p_is_active, p_admin_user_id, p_admin_user_id, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC');
    ELSE
        UPDATE crm."Agent"
        SET    "UserId"               = p_user_id_agent,
               "QueueId"              = p_queue_id,
               "AgentCode"            = p_agent_code,
               "AgentName"            = p_agent_name,
               "Extension"            = p_extension,
               "MaxConcurrentCalls"   = p_max_concurrent_calls,
               "IsActive"             = p_is_active,
               "UpdatedByUserId"      = p_admin_user_id,
               "UpdatedAt"            = NOW() AT TIME ZONE 'UTC'
        WHERE  "AgentId" = p_agent_id AND "CompanyId" = p_company_id AND "IsDeleted" = FALSE;
    END IF;

    RETURN QUERY SELECT 1, 'OK'::VARCHAR;

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT 0, SQLERRM::VARCHAR;
END;
$$;

-- =============================================================================
--  usp_CRM_Agent_UpdateStatus
-- =============================================================================
DROP FUNCTION IF EXISTS usp_crm_agent_updatestatus(BIGINT, VARCHAR) CASCADE;
CREATE OR REPLACE FUNCTION usp_crm_agent_updatestatus(
    p_agent_id BIGINT,
    p_status   VARCHAR
)
RETURNS TABLE("ok" INT, "mensaje" VARCHAR)
LANGUAGE plpgsql AS $$
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

-- =============================================================================
--  usp_CRM_CallLog_List
-- =============================================================================
DROP FUNCTION IF EXISTS usp_crm_calllog_list(INT, BIGINT, BIGINT, VARCHAR, VARCHAR, VARCHAR, TIMESTAMP, TIMESTAMP, INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_crm_calllog_list(
    p_company_id    INT,
    p_agent_id      BIGINT    DEFAULT NULL,
    p_queue_id      BIGINT    DEFAULT NULL,
    p_direction     VARCHAR   DEFAULT NULL,
    p_result        VARCHAR   DEFAULT NULL,
    p_customer_code VARCHAR   DEFAULT NULL,
    p_fecha_desde   TIMESTAMP DEFAULT NULL,
    p_fecha_hasta   TIMESTAMP DEFAULT NULL,
    p_page          INT       DEFAULT 1,
    p_limit         INT       DEFAULT 50
)
RETURNS TABLE(
    "CallLogId"         BIGINT,
    "CompanyId"         INT,
    "BranchId"          INT,
    "AgentId"           BIGINT,
    "QueueId"           BIGINT,
    "CallDirection"     VARCHAR,
    "CallerNumber"      VARCHAR,
    "CalledNumber"      VARCHAR,
    "CustomerCode"      VARCHAR,
    "CustomerId"        BIGINT,
    "LeadId"            BIGINT,
    "ContactName"       VARCHAR,
    "CallStartTime"     TIMESTAMP,
    "CallEndTime"       TIMESTAMP,
    "DurationSeconds"   INT,
    "WaitSeconds"       INT,
    "Result"            VARCHAR,
    "Disposition"       VARCHAR,
    "Notes"             TEXT,
    "RecordingUrl"      VARCHAR,
    "CallbackScheduled" TIMESTAMP,
    "Tags"              VARCHAR,
    "SatisfactionScore" INT,
    "AgentName"         VARCHAR,
    "QueueName"         VARCHAR,
    "TotalCount"        BIGINT
)
LANGUAGE plpgsql AS $$
DECLARE
    v_total BIGINT;
    v_offset INT;
BEGIN
    SELECT COUNT(*) INTO v_total
    FROM crm."CallLog" c
    WHERE c."CompanyId" = p_company_id
      AND c."IsDeleted" = FALSE
      AND c."CallStartTime" >= p_fecha_desde
      AND c."CallStartTime" <= p_fecha_hasta
      AND (p_agent_id IS NULL OR c."AgentId" = p_agent_id)
      AND (p_queue_id IS NULL OR c."QueueId" = p_queue_id)
      AND (p_direction IS NULL OR c."CallDirection" = p_direction)
      AND (p_result IS NULL OR c."Result" = p_result)
      AND (p_customer_code IS NULL OR c."CustomerCode" = p_customer_code);

    v_offset := (p_page - 1) * p_limit;

    RETURN QUERY
    SELECT
        c."CallLogId", c."CompanyId", c."BranchId", c."AgentId", c."QueueId",
        c."CallDirection", c."CallerNumber", c."CalledNumber",
        c."CustomerCode", c."CustomerId", c."LeadId", c."ContactName",
        c."CallStartTime", c."CallEndTime", c."DurationSeconds", c."WaitSeconds",
        c."Result", c."Disposition", c."Notes"::TEXT, c."RecordingUrl",
        c."CallbackScheduled", c."Tags", c."SatisfactionScore",
        a."AgentName",
        q."QueueName",
        v_total
    FROM crm."CallLog" c
    LEFT JOIN crm."Agent" a ON a."AgentId" = c."AgentId"
    LEFT JOIN crm."CallQueue" q ON q."QueueId" = c."QueueId"
    WHERE c."CompanyId" = p_company_id
      AND c."IsDeleted" = FALSE
      AND c."CallStartTime" >= p_fecha_desde
      AND c."CallStartTime" <= p_fecha_hasta
      AND (p_agent_id IS NULL OR c."AgentId" = p_agent_id)
      AND (p_queue_id IS NULL OR c."QueueId" = p_queue_id)
      AND (p_direction IS NULL OR c."CallDirection" = p_direction)
      AND (p_result IS NULL OR c."Result" = p_result)
      AND (p_customer_code IS NULL OR c."CustomerCode" = p_customer_code)
    ORDER BY c."CallStartTime" DESC
    OFFSET v_offset LIMIT p_limit;
END;
$$;

-- =============================================================================
--  usp_CRM_CallLog_Get
-- =============================================================================
DROP FUNCTION IF EXISTS usp_crm_calllog_get(BIGINT) CASCADE;
CREATE OR REPLACE FUNCTION usp_crm_calllog_get(
    p_call_log_id BIGINT
)
RETURNS TABLE(
    "CallLogId"             BIGINT,
    "CompanyId"             INT,
    "BranchId"              INT,
    "AgentId"               BIGINT,
    "QueueId"               BIGINT,
    "CallDirection"         VARCHAR,
    "CallerNumber"          VARCHAR,
    "CalledNumber"          VARCHAR,
    "CustomerCode"          VARCHAR,
    "CustomerId"            BIGINT,
    "LeadId"                BIGINT,
    "ContactName"           VARCHAR,
    "CallStartTime"         TIMESTAMP,
    "CallEndTime"           TIMESTAMP,
    "DurationSeconds"       INT,
    "WaitSeconds"           INT,
    "Result"                VARCHAR,
    "Disposition"           VARCHAR,
    "Notes"                 TEXT,
    "RecordingUrl"          VARCHAR,
    "CallbackScheduled"     TIMESTAMP,
    "RelatedDocumentType"   VARCHAR,
    "RelatedDocumentNumber" VARCHAR,
    "Tags"                  VARCHAR,
    "SatisfactionScore"     INT,
    "CreatedAt"             TIMESTAMP,
    "AgentName"             VARCHAR,
    "QueueName"             VARCHAR
)
LANGUAGE plpgsql AS $$
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
      AND c."IsDeleted" = FALSE;
END;
$$;

-- =============================================================================
--  usp_CRM_CallLog_Create
--  Crea registro de llamada. Auto-crea Lead si no hay LeadId/CustomerCode.
--  Crea Activity de tipo CALL.
-- =============================================================================
DROP FUNCTION IF EXISTS usp_crm_calllog_create(INT, INT, BIGINT, BIGINT, VARCHAR, VARCHAR, VARCHAR, VARCHAR, BIGINT, BIGINT, VARCHAR, TIMESTAMP, TIMESTAMP, INT, INT, VARCHAR, VARCHAR, TEXT, VARCHAR, TIMESTAMP, VARCHAR, VARCHAR, VARCHAR, INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_crm_calllog_create(
    p_company_id              INT,
    p_branch_id               INT,
    p_agent_id                BIGINT    DEFAULT NULL,
    p_queue_id                BIGINT    DEFAULT NULL,
    p_call_direction          VARCHAR   DEFAULT NULL,
    p_caller_number           VARCHAR   DEFAULT '',
    p_called_number           VARCHAR   DEFAULT '',
    p_customer_code           VARCHAR   DEFAULT NULL,
    p_customer_id             BIGINT    DEFAULT NULL,
    p_lead_id                 BIGINT    DEFAULT NULL,
    p_contact_name            VARCHAR   DEFAULT NULL,
    p_call_start_time         TIMESTAMP DEFAULT NULL,
    p_call_end_time           TIMESTAMP DEFAULT NULL,
    p_duration_seconds        INT       DEFAULT NULL,
    p_wait_seconds            INT       DEFAULT NULL,
    p_result                  VARCHAR   DEFAULT NULL,
    p_disposition             VARCHAR   DEFAULT NULL,
    p_notes                   TEXT      DEFAULT NULL,
    p_recording_url           VARCHAR   DEFAULT NULL,
    p_callback_scheduled      TIMESTAMP DEFAULT NULL,
    p_related_document_type   VARCHAR   DEFAULT NULL,
    p_related_document_number VARCHAR   DEFAULT NULL,
    p_tags                    VARCHAR   DEFAULT NULL,
    p_satisfaction_score      INT       DEFAULT NULL,
    p_user_id                 INT       DEFAULT NULL
)
RETURNS TABLE("ok" INT, "mensaje" VARCHAR, "CallLogId" BIGINT)
LANGUAGE plpgsql AS $$
DECLARE
    v_new_lead_id    BIGINT := p_lead_id;
    v_call_log_id    BIGINT;
    v_default_pipe   INT;
    v_default_stage  INT;
    v_lead_seq       INT;
    v_lead_code      VARCHAR;
    v_activity_subj  VARCHAR;
BEGIN
    -- Auto-crear Lead si no hay LeadId ni CustomerCode y hay CallerNumber
    IF v_new_lead_id IS NULL AND (p_customer_code IS NULL OR p_customer_code = '') AND p_caller_number <> '' THEN
        SELECT p."PipelineId" INTO v_default_pipe
        FROM crm."Pipeline" p
        WHERE p."CompanyId" = p_company_id AND p."IsDefault" = TRUE AND p."IsActive" = TRUE
        LIMIT 1;

        IF v_default_pipe IS NOT NULL THEN
            SELECT s."StageId" INTO v_default_stage
            FROM crm."PipelineStage" s
            WHERE s."PipelineId" = v_default_pipe AND s."IsActive" = TRUE
            ORDER BY s."StageOrder"
            LIMIT 1;

            IF v_default_stage IS NOT NULL THEN
                SELECT COALESCE(MAX(CAST(REPLACE("LeadCode", 'LEAD-',''::VARCHAR) AS INT)), 0) + 1
                INTO v_lead_seq
                FROM crm."Lead"
                WHERE "CompanyId" = p_company_id AND "LeadCode" LIKE 'LEAD-%';

                v_lead_code := 'LEAD-' || LPAD(v_lead_seq::VARCHAR, 6, '0');

                INSERT INTO crm."Lead" ("CompanyId", "BranchId", "PipelineId", "StageId", "LeadCode", "ContactName", "Phone", "Source", "Status", "Priority", "EstimatedValue", "CurrencyCode", "CreatedByUserId", "UpdatedByUserId", "CreatedAt", "UpdatedAt")
                VALUES (p_company_id, p_branch_id, v_default_pipe, v_default_stage, v_lead_code,
                        COALESCE(p_contact_name, 'Llamada ' || p_caller_number),
                        p_caller_number, 'CALL_CENTER', 'NEW', 'MEDIUM', 0, 'USD',
                        p_user_id, p_user_id, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC')
                RETURNING "LeadId" INTO v_new_lead_id;
            END IF;
        END IF;
    END IF;

    -- Insertar CallLog
    INSERT INTO crm."CallLog" (
        "CompanyId", "BranchId", "AgentId", "QueueId", "CallDirection",
        "CallerNumber", "CalledNumber", "CustomerCode", "CustomerId", "LeadId", "ContactName",
        "CallStartTime", "CallEndTime", "DurationSeconds", "WaitSeconds",
        "Result", "Disposition", "Notes", "RecordingUrl", "CallbackScheduled",
        "RelatedDocumentType", "RelatedDocumentNumber", "Tags", "SatisfactionScore",
        "CreatedByUserId", "UpdatedByUserId", "CreatedAt", "UpdatedAt"
    )
    VALUES (
        p_company_id, p_branch_id, p_agent_id, p_queue_id, p_call_direction,
        p_caller_number, p_called_number, p_customer_code, p_customer_id, v_new_lead_id, p_contact_name,
        p_call_start_time, p_call_end_time, p_duration_seconds, p_wait_seconds,
        p_result, p_disposition, p_notes, p_recording_url, p_callback_scheduled,
        p_related_document_type, p_related_document_number, p_tags, p_satisfaction_score,
        p_user_id, p_user_id, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'
    )
    RETURNING "CallLogId" INTO v_call_log_id;

    -- Crear Activity de tipo CALL
    v_activity_subj := p_call_direction || ' - ' || COALESCE(p_contact_name, p_caller_number) || ' (' || p_result || ')';

    INSERT INTO crm."Activity" (
        "CompanyId", "LeadId", "CustomerId", "ActivityType", "Subject",
        "Description", "IsCompleted", "CompletedAt",
        "AssignedToUserId", "Priority",
        "CreatedByUserId", "UpdatedByUserId", "CreatedAt", "UpdatedAt"
    )
    VALUES (
        p_company_id, v_new_lead_id, p_customer_id, 'CALL', v_activity_subj,
        p_notes, TRUE, NOW() AT TIME ZONE 'UTC',
        p_user_id, 'MEDIUM',
        p_user_id, p_user_id, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'
    );

    RETURN QUERY SELECT 1, 'OK'::VARCHAR, v_call_log_id;

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT 0, SQLERRM::VARCHAR, 0::BIGINT;
END;
$$;

-- =============================================================================
--  usp_CRM_CallScript_List
-- =============================================================================
DROP FUNCTION IF EXISTS usp_crm_callscript_list(INT, VARCHAR) CASCADE;
CREATE OR REPLACE FUNCTION usp_crm_callscript_list(
    p_company_id INT,
    p_queue_type VARCHAR DEFAULT NULL
)
RETURNS TABLE(
    "ScriptId"   BIGINT,
    "CompanyId"  INT,
    "ScriptCode" VARCHAR,
    "ScriptName" VARCHAR,
    "QueueType"  VARCHAR,
    "Content"    TEXT,
    "Version"    INT,
    "IsActive"   BOOLEAN,
    "CreatedAt"  TIMESTAMP,
    "UpdatedAt"  TIMESTAMP
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        s."ScriptId", s."CompanyId", s."ScriptCode", s."ScriptName",
        s."QueueType", s."Content"::TEXT, s."Version", s."IsActive",
        s."CreatedAt", s."UpdatedAt"
    FROM crm."CallScript" s
    WHERE s."CompanyId" = p_company_id
      AND s."IsDeleted" = FALSE
      AND (p_queue_type IS NULL OR s."QueueType" = p_queue_type)
    ORDER BY s."ScriptName";
END;
$$;

-- =============================================================================
--  usp_CRM_CallScript_Upsert
-- =============================================================================
DROP FUNCTION IF EXISTS usp_crm_callscript_upsert(INT, BIGINT, VARCHAR, VARCHAR, VARCHAR, TEXT, BOOLEAN, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_crm_callscript_upsert(
    p_company_id   INT,
    p_script_id    BIGINT   DEFAULT NULL,
    p_script_code  VARCHAR  DEFAULT NULL,
    p_script_name  VARCHAR  DEFAULT NULL,
    p_queue_type   VARCHAR  DEFAULT NULL,
    p_content      TEXT     DEFAULT NULL,
    p_is_active    BOOLEAN  DEFAULT TRUE,
    p_user_id      INT      DEFAULT NULL
)
RETURNS TABLE("ok" INT, "mensaje" VARCHAR)
LANGUAGE plpgsql AS $$
BEGIN
    IF p_script_id IS NULL THEN
        IF EXISTS (SELECT 1 FROM crm."CallScript" WHERE "CompanyId" = p_company_id AND "ScriptCode" = p_script_code AND "IsDeleted" = FALSE) THEN
            RETURN QUERY SELECT 0, ('Ya existe un script con el codigo ' || p_script_code)::VARCHAR;
            RETURN;
        END IF;

        INSERT INTO crm."CallScript" ("CompanyId", "ScriptCode", "ScriptName", "QueueType", "Content", "IsActive", "CreatedByUserId", "UpdatedByUserId", "CreatedAt", "UpdatedAt")
        VALUES (p_company_id, p_script_code, p_script_name, p_queue_type, p_content, p_is_active, p_user_id, p_user_id, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC');
    ELSE
        UPDATE crm."CallScript"
        SET    "ScriptCode"      = p_script_code,
               "ScriptName"      = p_script_name,
               "QueueType"       = p_queue_type,
               "Content"         = p_content,
               "Version"         = "Version" + 1,
               "IsActive"        = p_is_active,
               "UpdatedByUserId" = p_user_id,
               "UpdatedAt"       = NOW() AT TIME ZONE 'UTC'
        WHERE  "ScriptId" = p_script_id AND "CompanyId" = p_company_id AND "IsDeleted" = FALSE;
    END IF;

    RETURN QUERY SELECT 1, 'OK'::VARCHAR;

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT 0, SQLERRM::VARCHAR;
END;
$$;

-- =============================================================================
--  usp_CRM_Campaign_List
-- =============================================================================
DROP FUNCTION IF EXISTS usp_crm_campaign_list(INT, VARCHAR, INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_crm_campaign_list(
    p_company_id INT,
    p_status     VARCHAR DEFAULT NULL,
    p_page       INT     DEFAULT 1,
    p_limit      INT     DEFAULT 50
)
RETURNS TABLE(
    "CampaignId"       BIGINT,
    "CompanyId"        INT,
    "CampaignCode"     VARCHAR,
    "CampaignName"     VARCHAR,
    "CampaignType"     VARCHAR,
    "QueueId"          BIGINT,
    "ScriptId"         BIGINT,
    "StartDate"        DATE,
    "EndDate"          DATE,
    "TotalContacts"    INT,
    "ContactedCount"   INT,
    "SuccessCount"     INT,
    "Status"           VARCHAR,
    "Notes"            TEXT,
    "AssignedToUserId" INT,
    "CreatedAt"        TIMESTAMP,
    "UpdatedAt"        TIMESTAMP,
    "QueueName"        VARCHAR,
    "TotalCount"       BIGINT
)
LANGUAGE plpgsql AS $$
DECLARE
    v_total BIGINT;
    v_offset INT;
BEGIN
    SELECT COUNT(*) INTO v_total
    FROM crm."Campaign" c
    WHERE c."CompanyId" = p_company_id
      AND c."IsDeleted" = FALSE
      AND (p_status IS NULL OR c."Status" = p_status);

    v_offset := (p_page - 1) * p_limit;

    RETURN QUERY
    SELECT
        c."CampaignId", c."CompanyId", c."CampaignCode", c."CampaignName",
        c."CampaignType", c."QueueId", c."ScriptId",
        c."StartDate", c."EndDate",
        c."TotalContacts", c."ContactedCount", c."SuccessCount",
        c."Status", c."Notes"::TEXT, c."AssignedToUserId",
        c."CreatedAt", c."UpdatedAt",
        q."QueueName",
        v_total
    FROM crm."Campaign" c
    LEFT JOIN crm."CallQueue" q ON q."QueueId" = c."QueueId"
    WHERE c."CompanyId" = p_company_id
      AND c."IsDeleted" = FALSE
      AND (p_status IS NULL OR c."Status" = p_status)
    ORDER BY c."CreatedAt" DESC
    OFFSET v_offset LIMIT p_limit;
END;
$$;

-- =============================================================================
--  usp_CRM_Campaign_Get
-- =============================================================================
DROP FUNCTION IF EXISTS usp_crm_campaign_get(BIGINT) CASCADE;
CREATE OR REPLACE FUNCTION usp_crm_campaign_get(
    p_campaign_id BIGINT
)
RETURNS TABLE(
    "CampaignId"       BIGINT,
    "CompanyId"        INT,
    "CampaignCode"     VARCHAR,
    "CampaignName"     VARCHAR,
    "CampaignType"     VARCHAR,
    "QueueId"          BIGINT,
    "ScriptId"         BIGINT,
    "StartDate"        DATE,
    "EndDate"          DATE,
    "TotalContacts"    INT,
    "ContactedCount"   INT,
    "SuccessCount"     INT,
    "Status"           VARCHAR,
    "Notes"            TEXT,
    "AssignedToUserId" INT,
    "CreatedAt"        TIMESTAMP,
    "UpdatedAt"        TIMESTAMP,
    "QueueName"        VARCHAR,
    "ScriptName"       VARCHAR,
    "PendingCount"     BIGINT,
    "CallbackCount"    BIGINT
)
LANGUAGE plpgsql AS $$
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
      AND c."IsDeleted" = FALSE;
END;
$$;

-- =============================================================================
--  usp_CRM_Campaign_Create
--  ContactsJson: [{"customerId":1,"leadId":null,"contactName":"...","phone":"...","email":"...","priority":"HIGH"},...]
-- =============================================================================
DROP FUNCTION IF EXISTS usp_crm_campaign_create(INT, VARCHAR, VARCHAR, VARCHAR, BIGINT, BIGINT, DATE, DATE, INT, TEXT, TEXT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_crm_campaign_create(
    p_company_id         INT,
    p_campaign_code      VARCHAR  DEFAULT NULL,
    p_campaign_name      VARCHAR  DEFAULT NULL,
    p_campaign_type      VARCHAR  DEFAULT NULL,
    p_queue_id           BIGINT   DEFAULT NULL,
    p_script_id          BIGINT   DEFAULT NULL,
    p_start_date         DATE     DEFAULT NULL,
    p_end_date           DATE     DEFAULT NULL,
    p_assigned_to_user_id INT     DEFAULT NULL,
    p_notes              TEXT     DEFAULT NULL,
    p_contacts_json      TEXT     DEFAULT NULL,
    p_user_id            INT      DEFAULT NULL
)
RETURNS TABLE("ok" INT, "mensaje" VARCHAR, "CampaignId" BIGINT)
LANGUAGE plpgsql AS $$
DECLARE
    v_campaign_id  BIGINT;
    v_contact_count INT := 0;
    v_contact JSONB;
BEGIN
    IF EXISTS (SELECT 1 FROM crm."Campaign" WHERE "CompanyId" = p_company_id AND "CampaignCode" = p_campaign_code AND "IsDeleted" = FALSE) THEN
        RETURN QUERY SELECT 0, ('Ya existe una campana con el codigo ' || p_campaign_code)::VARCHAR, 0::BIGINT;
        RETURN;
    END IF;

    IF p_contacts_json IS NOT NULL AND p_contacts_json <> '' THEN
        SELECT COUNT(*) INTO v_contact_count FROM jsonb_array_elements(p_contacts_json::JSONB);
    END IF;

    INSERT INTO crm."Campaign" (
        "CompanyId", "CampaignCode", "CampaignName", "CampaignType",
        "QueueId", "ScriptId", "StartDate", "EndDate",
        "TotalContacts", "Status", "Notes", "AssignedToUserId",
        "CreatedByUserId", "UpdatedByUserId", "CreatedAt", "UpdatedAt"
    )
    VALUES (
        p_company_id, p_campaign_code, p_campaign_name, p_campaign_type,
        p_queue_id, p_script_id, p_start_date, p_end_date,
        v_contact_count, 'DRAFT', p_notes, p_assigned_to_user_id,
        p_user_id, p_user_id, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'
    )
    RETURNING "CampaignId" INTO v_campaign_id;

    -- Insertar contactos
    IF p_contacts_json IS NOT NULL AND p_contacts_json <> '' THEN
        FOR v_contact IN SELECT * FROM jsonb_array_elements(p_contacts_json::JSONB)
        LOOP
            INSERT INTO crm."CampaignContact" ("CampaignId", "CustomerId", "LeadId", "ContactName", "Phone", "Email", "Priority", "CreatedByUserId", "UpdatedByUserId", "CreatedAt", "UpdatedAt")
            VALUES (
                v_campaign_id,
                (v_contact->>'customerId')::BIGINT,
                (v_contact->>'leadId')::BIGINT,
                v_contact->>'contactName',
                v_contact->>'phone',
                v_contact->>'email',
                COALESCE(v_contact->>'priority', 'MEDIUM'),
                p_user_id, p_user_id, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'
            );
        END LOOP;
    END IF;

    RETURN QUERY SELECT 1, 'OK'::VARCHAR, v_campaign_id;

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT 0, SQLERRM::VARCHAR, 0::BIGINT;
END;
$$;

-- =============================================================================
--  usp_CRM_Campaign_UpdateStatus
-- =============================================================================
DROP FUNCTION IF EXISTS usp_crm_campaign_updatestatus(BIGINT, VARCHAR, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_crm_campaign_updatestatus(
    p_campaign_id BIGINT,
    p_status      VARCHAR,
    p_user_id     INT
)
RETURNS TABLE("ok" INT, "mensaje" VARCHAR)
LANGUAGE plpgsql AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM crm."Campaign" WHERE "CampaignId" = p_campaign_id AND "IsDeleted" = FALSE) THEN
        RETURN QUERY SELECT 0, 'Campana no encontrada'::VARCHAR;
        RETURN;
    END IF;

    UPDATE crm."Campaign"
    SET    "Status"          = p_status,
           "UpdatedByUserId" = p_user_id,
           "UpdatedAt"       = NOW() AT TIME ZONE 'UTC'
    WHERE  "CampaignId" = p_campaign_id AND "IsDeleted" = FALSE;

    RETURN QUERY SELECT 1, 'OK'::VARCHAR;

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT 0, SQLERRM::VARCHAR;
END;
$$;

-- =============================================================================
--  usp_CRM_Campaign_GetNextContact
-- =============================================================================
DROP FUNCTION IF EXISTS usp_crm_campaign_getnextcontact(BIGINT, BIGINT) CASCADE;
CREATE OR REPLACE FUNCTION usp_crm_campaign_getnextcontact(
    p_campaign_id BIGINT,
    p_agent_id    BIGINT
)
RETURNS TABLE(
    "CampaignContactId" BIGINT,
    "CampaignId"        BIGINT,
    "CustomerId"        BIGINT,
    "LeadId"            BIGINT,
    "ContactName"       VARCHAR,
    "Phone"             VARCHAR,
    "Email"             VARCHAR,
    "Status"            VARCHAR,
    "Attempts"          INT,
    "LastAttempt"        TIMESTAMP,
    "LastResult"        VARCHAR,
    "CallbackDate"      TIMESTAMP,
    "AssignedAgentId"   BIGINT,
    "Notes"             TEXT,
    "Priority"          VARCHAR
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        cc."CampaignContactId", cc."CampaignId", cc."CustomerId", cc."LeadId",
        cc."ContactName", cc."Phone", cc."Email", cc."Status",
        cc."Attempts", cc."LastAttempt", cc."LastResult",
        cc."CallbackDate", cc."AssignedAgentId", cc."Notes"::TEXT, cc."Priority"
    FROM crm."CampaignContact" cc
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

-- =============================================================================
--  usp_CRM_Campaign_LogAttempt
-- =============================================================================
DROP FUNCTION IF EXISTS usp_crm_campaign_logattempt(BIGINT, VARCHAR, TIMESTAMP, TEXT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_crm_campaign_logattempt(
    p_campaign_contact_id BIGINT,
    p_result              VARCHAR,
    p_callback_date       TIMESTAMP DEFAULT NULL,
    p_notes               TEXT      DEFAULT NULL,
    p_user_id             INT       DEFAULT NULL
)
RETURNS TABLE("ok" INT, "mensaje" VARCHAR)
LANGUAGE plpgsql AS $$
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

-- =============================================================================
--  usp_CRM_CallCenter_Dashboard
--  KPIs del call center. Retorna multiples resultsets como columnas JSON.
-- =============================================================================
DROP FUNCTION IF EXISTS usp_crm_callcenter_dashboard(INT, TIMESTAMP, TIMESTAMP) CASCADE;
CREATE OR REPLACE FUNCTION usp_crm_callcenter_dashboard(
    p_company_id  INT,
    p_fecha_desde TIMESTAMP,
    p_fecha_hasta TIMESTAMP
)
RETURNS TABLE(
    "TotalCalls"          BIGINT,
    "AnsweredCalls"       BIGINT,
    "AvgDurationSeconds"  INT,
    "AvgWaitSeconds"      INT,
    "CallsByResult"       JSONB,
    "CallsByAgent"        JSONB,
    "ActiveCampaigns"     BIGINT,
    "CallbacksPending"    BIGINT
)
LANGUAGE plpgsql AS $$
DECLARE
    v_total       BIGINT;
    v_answered    BIGINT;
    v_avg_dur     INT;
    v_avg_wait    INT;
    v_by_result   JSONB;
    v_by_agent    JSONB;
    v_campaigns   BIGINT;
    v_callbacks   BIGINT;
BEGIN
    -- Metricas generales
    SELECT
        COUNT(*),
        SUM(CASE WHEN "Result" = 'ANSWERED' THEN 1 ELSE 0 END),
        AVG("DurationSeconds")::INT,
        AVG("WaitSeconds")::INT
    INTO v_total, v_answered, v_avg_dur, v_avg_wait
    FROM crm."CallLog"
    WHERE "CompanyId" = p_company_id
      AND "IsDeleted" = FALSE
      AND "CallStartTime" >= p_fecha_desde
      AND "CallStartTime" <= p_fecha_hasta;

    -- Llamadas por resultado
    SELECT COALESCE(jsonb_agg(jsonb_build_object('Result', r."Result", 'CallCount', r.cnt)), '[]'::JSONB)
    INTO v_by_result
    FROM (
        SELECT "Result", COUNT(*) AS cnt
        FROM crm."CallLog"
        WHERE "CompanyId" = p_company_id AND "IsDeleted" = FALSE
          AND "CallStartTime" >= p_fecha_desde AND "CallStartTime" <= p_fecha_hasta
        GROUP BY "Result"
        ORDER BY cnt DESC
    ) r;

    -- Top agentes
    SELECT COALESCE(jsonb_agg(jsonb_build_object(
        'AgentId', ag."AgentId", 'AgentName', ag."AgentName",
        'TotalCalls', ag.total, 'AnsweredCalls', ag.answered, 'AvgDuration', ag.avg_dur
    )), '[]'::JSONB)
    INTO v_by_agent
    FROM (
        SELECT
            a."AgentId", a."AgentName",
            COUNT(*) AS total,
            SUM(CASE WHEN c."Result" = 'ANSWERED' THEN 1 ELSE 0 END) AS answered,
            AVG(c."DurationSeconds")::INT AS avg_dur
        FROM crm."CallLog" c
        INNER JOIN crm."Agent" a ON a."AgentId" = c."AgentId"
        WHERE c."CompanyId" = p_company_id AND c."IsDeleted" = FALSE
          AND c."CallStartTime" >= p_fecha_desde AND c."CallStartTime" <= p_fecha_hasta
        GROUP BY a."AgentId", a."AgentName"
        ORDER BY total DESC
        LIMIT 10
    ) ag;

    -- Campanas activas
    SELECT COUNT(*) INTO v_campaigns
    FROM crm."Campaign"
    WHERE "CompanyId" = p_company_id AND "IsDeleted" = FALSE AND "Status" = 'ACTIVE';

    -- Callbacks pendientes
    SELECT COUNT(*) INTO v_callbacks
    FROM crm."CallLog"
    WHERE "CompanyId" = p_company_id AND "IsDeleted" = FALSE
      AND "CallbackScheduled" IS NOT NULL
      AND "CallbackScheduled" >= NOW() AT TIME ZONE 'UTC'
      AND "Result" = 'CALLBACK';

    RETURN QUERY SELECT v_total, v_answered, COALESCE(v_avg_dur, 0), COALESCE(v_avg_wait, 0),
                        v_by_result, v_by_agent, v_campaigns, v_callbacks;
END;
$$;
