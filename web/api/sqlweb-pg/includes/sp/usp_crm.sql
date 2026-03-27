-- ============================================================
-- DatqBoxWeb PostgreSQL - usp_crm.sql
-- Funciones del modulo CRM (pipelines, leads, actividades)
-- Fecha: 2026-03-22
-- ============================================================

-- =============================================================================
--  usp_CRM_Pipeline_List
-- =============================================================================
DROP FUNCTION IF EXISTS usp_crm_pipeline_list(INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_crm_pipeline_list(
    p_company_id INT
)
RETURNS TABLE(
    "PipelineId" BIGINT,
    "PipelineCode" VARCHAR,
    "PipelineName" VARCHAR,
    "IsDefault"    BOOLEAN,
    "IsActive"     BOOLEAN,
    "CreatedAt"    TIMESTAMP,
    "UpdatedAt"    TIMESTAMP,
    "StageCount"   BIGINT
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        p."PipelineId", p."PipelineCode", p."PipelineName",
        p."IsDefault", p."IsActive", p."CreatedAt", p."UpdatedAt",
        (SELECT COUNT(*) FROM crm."PipelineStage" s WHERE s."PipelineId" = p."PipelineId" AND s."IsActive" = TRUE)
    FROM crm."Pipeline" p
    WHERE p."CompanyId" = p_company_id AND p."IsDeleted" = FALSE
    ORDER BY p."IsDefault" DESC, p."PipelineName";
END;
$$;

-- =============================================================================
--  usp_CRM_Pipeline_Upsert
-- =============================================================================
DROP FUNCTION IF EXISTS usp_crm_pipeline_upsert(INT, INT, VARCHAR, VARCHAR, BOOLEAN, BOOLEAN, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_crm_pipeline_upsert(
    p_company_id    INT,
    p_pipeline_id   INT DEFAULT NULL,
    p_pipeline_code VARCHAR(30) DEFAULT NULL,
    p_pipeline_name VARCHAR(120) DEFAULT NULL,
    p_is_default    BOOLEAN DEFAULT FALSE,
    p_is_active     BOOLEAN DEFAULT TRUE,
    p_user_id       INT DEFAULT NULL
)
RETURNS TABLE("ok" INT, "mensaje" VARCHAR)
LANGUAGE plpgsql AS $$
DECLARE
    v_id BIGINT;
BEGIN
    -- Si se marca como default, quitar default a los demas
    IF p_is_default THEN
        UPDATE crm."Pipeline" SET "IsDefault" = FALSE
        WHERE  "CompanyId" = p_company_id AND (p_pipeline_id IS NULL OR "PipelineId" <> p_pipeline_id);
    END IF;

    IF p_pipeline_id IS NULL THEN
        -- Verificar duplicado
        IF EXISTS (SELECT 1 FROM crm."Pipeline" WHERE "CompanyId" = p_company_id AND "PipelineCode" = p_pipeline_code) THEN
            RETURN QUERY SELECT 0, ('Ya existe un pipeline con el codigo ' || p_pipeline_code)::VARCHAR;
            RETURN;
        END IF;

        INSERT INTO crm."Pipeline" ("CompanyId", "PipelineCode", "PipelineName", "IsDefault", "IsActive", "CreatedByUserId", "UpdatedByUserId", "CreatedAt", "UpdatedAt")
        VALUES (p_company_id, p_pipeline_code, p_pipeline_name, p_is_default, p_is_active, p_user_id, p_user_id, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC');
    ELSE
        UPDATE crm."Pipeline"
        SET    "PipelineCode"    = p_pipeline_code,
               "PipelineName"    = p_pipeline_name,
               "IsDefault"       = p_is_default,
               "IsActive"        = p_is_active,
               "UpdatedByUserId" = p_user_id,
               "UpdatedAt"       = NOW() AT TIME ZONE 'UTC'
        WHERE  "PipelineId" = p_pipeline_id AND "CompanyId" = p_company_id;
    END IF;

    RETURN QUERY SELECT 1, 'OK'::VARCHAR;

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT 0, SQLERRM::VARCHAR;
END;
$$;

-- =============================================================================
--  usp_CRM_Pipeline_GetStages
-- =============================================================================
DROP FUNCTION IF EXISTS usp_crm_pipeline_getstages(INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_crm_pipeline_getstages(
    p_pipeline_id INT
)
RETURNS TABLE(
    "StageId" BIGINT,
    "PipelineId" BIGINT,
    "StageCode"    VARCHAR,
    "StageName"    VARCHAR,
    "StageOrder"   INT,
    "Probability"  NUMERIC,
    "DaysExpected" INT,
    "Color"        VARCHAR,
    "IsClosed"     BOOLEAN,
    "IsWon"        BOOLEAN,
    "IsActive"     BOOLEAN
)
LANGUAGE plpgsql AS $$
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

-- =============================================================================
--  usp_CRM_Stage_Upsert
-- =============================================================================
DROP FUNCTION IF EXISTS usp_crm_stage_upsert(INT, INT, VARCHAR, VARCHAR, INT, NUMERIC, INT, VARCHAR, BOOLEAN, BOOLEAN, BOOLEAN, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_crm_stage_upsert(
    p_pipeline_id   INT,
    p_stage_id      INT DEFAULT NULL,
    p_stage_code    VARCHAR(30) DEFAULT NULL,
    p_stage_name    VARCHAR(120) DEFAULT NULL,
    p_stage_order   INT DEFAULT 0,
    p_probability   NUMERIC(5,2) DEFAULT 0,
    p_days_expected INT DEFAULT 0,
    p_color         VARCHAR(20) DEFAULT NULL,
    p_is_closed     BOOLEAN DEFAULT FALSE,
    p_is_won        BOOLEAN DEFAULT FALSE,
    p_is_active     BOOLEAN DEFAULT TRUE,
    p_user_id       INT DEFAULT NULL
)
RETURNS TABLE("ok" INT, "mensaje" VARCHAR)
LANGUAGE plpgsql AS $$
BEGIN
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

-- =============================================================================
--  usp_CRM_Lead_List
-- =============================================================================
DROP FUNCTION IF EXISTS usp_crm_lead_list(INT, INT, INT, VARCHAR, INT, VARCHAR, VARCHAR, VARCHAR, INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_crm_lead_list(
    p_company_id         INT,
    p_pipeline_id        INT DEFAULT NULL,
    p_stage_id           INT DEFAULT NULL,
    p_status             VARCHAR(20) DEFAULT NULL,
    p_assigned_to_user_id INT DEFAULT NULL,
    p_source             VARCHAR(50) DEFAULT NULL,
    p_priority           VARCHAR(20) DEFAULT NULL,
    p_search             VARCHAR(200) DEFAULT NULL,
    p_page               INT DEFAULT 1,
    p_limit              INT DEFAULT 50
)
RETURNS TABLE(
    "LeadId" BIGINT,
    "LeadCode"         VARCHAR,
    "PipelineId" BIGINT,
    "StageId" BIGINT,
    "StageName"        VARCHAR,
    "StageColor"       VARCHAR,
    "ContactName"      VARCHAR,
    "CompanyName"      VARCHAR,
    "Email"            VARCHAR,
    "Phone"            VARCHAR,
    "Source"           VARCHAR,
    "Status"           VARCHAR,
    "AssignedToUserId" INT,
    "EstimatedValue"   NUMERIC,
    "CurrencyCode" CHAR(3),
    "ExpectedCloseDate" DATE,
    "Priority"         VARCHAR,
    "Tags"             VARCHAR,
    "CreatedAt"        TIMESTAMP,
    "UpdatedAt"        TIMESTAMP,
    "TotalCount"       BIGINT
)
LANGUAGE plpgsql AS $$
DECLARE
    v_total BIGINT;
BEGIN
    SELECT COUNT(*) INTO v_total
    FROM   crm."Lead" l
    WHERE  l."CompanyId" = p_company_id
      AND  l."IsDeleted" = FALSE
      AND  (p_pipeline_id        IS NULL OR l."PipelineId"       = p_pipeline_id)
      AND  (p_stage_id           IS NULL OR l."StageId"          = p_stage_id)
      AND  (p_status             IS NULL OR l."Status"           = p_status)
      AND  (p_assigned_to_user_id IS NULL OR l."AssignedToUserId" = p_assigned_to_user_id)
      AND  (p_source             IS NULL OR l."Source"            = p_source)
      AND  (p_priority           IS NULL OR l."Priority"         = p_priority)
      AND  (p_search             IS NULL OR l."ContactName" ILIKE '%' || p_search || '%'
                                         OR l."CompanyName" ILIKE '%' || p_search || '%'
                                         OR l."LeadCode"    ILIKE '%' || p_search || '%'
                                         OR l."Email"       ILIKE '%' || p_search || '%');

    RETURN QUERY
    SELECT
        l."LeadId", l."LeadCode", l."PipelineId", l."StageId",
        s."StageName", s."Color",
        l."ContactName", l."CompanyName", l."Email", l."Phone",
        l."Source", l."Status", l."AssignedToUserId",
        l."EstimatedValue", l."CurrencyCode", l."ExpectedCloseDate",
        l."Priority", l."Tags", l."CreatedAt", l."UpdatedAt",
        v_total
    FROM   crm."Lead" l
    LEFT JOIN crm."PipelineStage" s ON s."StageId" = l."StageId"
    WHERE  l."CompanyId" = p_company_id
      AND  l."IsDeleted" = FALSE
      AND  (p_pipeline_id        IS NULL OR l."PipelineId"       = p_pipeline_id)
      AND  (p_stage_id           IS NULL OR l."StageId"          = p_stage_id)
      AND  (p_status             IS NULL OR l."Status"           = p_status)
      AND  (p_assigned_to_user_id IS NULL OR l."AssignedToUserId" = p_assigned_to_user_id)
      AND  (p_source             IS NULL OR l."Source"            = p_source)
      AND  (p_priority           IS NULL OR l."Priority"         = p_priority)
      AND  (p_search             IS NULL OR l."ContactName" ILIKE '%' || p_search || '%'
                                         OR l."CompanyName" ILIKE '%' || p_search || '%'
                                         OR l."LeadCode"    ILIKE '%' || p_search || '%'
                                         OR l."Email"       ILIKE '%' || p_search || '%')
    ORDER BY l."CreatedAt" DESC
    LIMIT p_limit OFFSET (p_page - 1) * p_limit;
END;
$$;

-- =============================================================================
--  usp_CRM_Lead_Get
-- =============================================================================
DROP FUNCTION IF EXISTS usp_crm_lead_get(INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_crm_lead_get(
    p_lead_id INT
)
RETURNS TABLE(
    "LeadId" BIGINT,
    "LeadCode"         VARCHAR,
    "CompanyId"        INT,
    "BranchId"         INT,
    "PipelineId" BIGINT,
    "PipelineName"     VARCHAR,
    "StageId" BIGINT,
    "StageName"        VARCHAR,
    "StageColor"       VARCHAR,
    "ContactName"      VARCHAR,
    "CompanyName"      VARCHAR,
    "Email"            VARCHAR,
    "Phone"            VARCHAR,
    "Source"           VARCHAR,
    "Status"           VARCHAR,
    "AssignedToUserId" INT,
    "EstimatedValue"   NUMERIC,
    "CurrencyCode" CHAR(3),
    "ExpectedCloseDate" DATE,
    "Notes"            TEXT,
    "Tags"             VARCHAR,
    "Priority"         VARCHAR,
    "LostReason"       VARCHAR,
    "CustomerId" BIGINT,
    "CreatedAt"        TIMESTAMP,
    "UpdatedAt"        TIMESTAMP,
    "_section"         VARCHAR
)
LANGUAGE plpgsql AS $$
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
    WHERE  l."LeadId" = p_lead_id;
END;
$$;

-- =============================================================================
--  usp_CRM_Lead_Create
-- =============================================================================
DROP FUNCTION IF EXISTS usp_crm_lead_create(INT, INT, INT, INT, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, INT, NUMERIC, VARCHAR, TIMESTAMP, TEXT, VARCHAR, VARCHAR, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_crm_lead_create(
    p_company_id         INT,
    p_branch_id          INT,
    p_pipeline_id        INT,
    p_stage_id           INT,
    p_contact_name VARCHAR(200) DEFAULT NULL,
    p_company_name       VARCHAR(200) DEFAULT NULL,
    p_email              VARCHAR(200) DEFAULT NULL,
    p_phone              VARCHAR(60)  DEFAULT NULL,
    p_source             VARCHAR(50)  DEFAULT NULL,
    p_assigned_to_user_id INT DEFAULT NULL,
    p_estimated_value    NUMERIC(18,2) DEFAULT 0,
    p_currency_code      VARCHAR(5)   DEFAULT 'USD',
    p_expected_close_date TIMESTAMP   DEFAULT NULL,
    p_notes              TEXT         DEFAULT NULL,
    p_tags               VARCHAR(500) DEFAULT NULL,
    p_priority           VARCHAR(20)  DEFAULT 'MEDIUM',
    p_user_id            INT          DEFAULT NULL
)
RETURNS TABLE("ok" INT, "mensaje" VARCHAR, "LeadId" BIGINT, "LeadCode" VARCHAR)
LANGUAGE plpgsql AS $$
DECLARE
    v_id BIGINT;
    v_seq  INT;
    v_code VARCHAR(30);
BEGIN
    SELECT COALESCE(MAX("LeadId"), 0) + 1 INTO v_seq FROM crm."Lead" WHERE "CompanyId" = p_company_id;
    v_code := 'LEAD-' || LPAD(v_seq::TEXT, 6, '0');

    INSERT INTO crm."Lead" (
        "CompanyId", "BranchId", "LeadCode", "PipelineId", "StageId",
        "ContactName", "CompanyName", "Email", "Phone", "Source",
        "AssignedToUserId", "EstimatedValue", "CurrencyCode",
        "ExpectedCloseDate", "Notes", "Tags", "Priority", "Status",
        "CreatedByUserId", "UpdatedByUserId", "CreatedAt", "UpdatedAt"
    ) VALUES (
        p_company_id, p_branch_id, v_code, p_pipeline_id, p_stage_id,
        p_contact_name, p_company_name, p_email, p_phone, p_source,
        p_assigned_to_user_id, p_estimated_value, p_currency_code,
        p_expected_close_date, p_notes, p_tags, p_priority, 'OPEN',
        p_user_id, p_user_id, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'
    ) RETURNING "LeadId" INTO v_id;

    INSERT INTO crm."LeadHistory" ("LeadId", "ChangeType", "ToStageId", "Notes", "ChangedByUserId", "CreatedAt")
    VALUES (v_id, 'STATUS', p_stage_id, 'Lead creado', p_user_id, NOW() AT TIME ZONE 'UTC');

    RETURN QUERY SELECT 1, 'OK'::VARCHAR, v_id, v_code;

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT 0, SQLERRM::VARCHAR, 0::BIGINT, ''::VARCHAR;
END;
$$;

-- =============================================================================
--  usp_CRM_Lead_Update
-- =============================================================================
DROP FUNCTION IF EXISTS usp_crm_lead_update(INT, INT, VARCHAR, VARCHAR, VARCHAR, VARCHAR, INT, NUMERIC, TIMESTAMP, TEXT, VARCHAR, VARCHAR, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_crm_lead_update(
    p_lead_id            INT,
    p_stage_id           INT DEFAULT NULL,
    p_contact_name       VARCHAR(200) DEFAULT NULL,
    p_company_name       VARCHAR(200) DEFAULT NULL,
    p_email              VARCHAR(200) DEFAULT NULL,
    p_phone              VARCHAR(60)  DEFAULT NULL,
    p_assigned_to_user_id INT DEFAULT NULL,
    p_estimated_value    NUMERIC(18,2) DEFAULT NULL,
    p_expected_close_date TIMESTAMP DEFAULT NULL,
    p_notes              TEXT DEFAULT NULL,
    p_tags               VARCHAR(500) DEFAULT NULL,
    p_priority           VARCHAR(20)  DEFAULT NULL,
    p_user_id            INT DEFAULT NULL
)
RETURNS TABLE("ok" INT, "mensaje" VARCHAR)
LANGUAGE plpgsql AS $$
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
    WHERE  "LeadId" = p_lead_id;

    RETURN QUERY SELECT 1, 'OK'::VARCHAR;

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT 0, SQLERRM::VARCHAR;
END;
$$;

-- =============================================================================
--  usp_CRM_Lead_ChangeStage
-- =============================================================================
DROP FUNCTION IF EXISTS usp_crm_lead_changestage(INT, INT, VARCHAR, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_crm_lead_changestage(
    p_lead_id      INT,
    p_new_stage_id INT,
    p_notes        VARCHAR(500) DEFAULT NULL,
    p_user_id      INT DEFAULT NULL
)
RETURNS TABLE("ok" INT, "mensaje" VARCHAR)
LANGUAGE plpgsql AS $$
DECLARE
    v_old_stage_id INT;
BEGIN
    SELECT "StageId" INTO v_old_stage_id FROM crm."Lead" WHERE "LeadId" = p_lead_id;

    IF v_old_stage_id IS NULL THEN
        RETURN QUERY SELECT 0, 'Lead no encontrado'::VARCHAR;
        RETURN;
    END IF;

    UPDATE crm."Lead"
    SET    "StageId" = p_new_stage_id, "UpdatedByUserId" = p_user_id, "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
    WHERE  "LeadId" = p_lead_id;

    INSERT INTO crm."LeadHistory" ("LeadId", "ChangeType", "FromStageId", "ToStageId", "Notes", "ChangedByUserId", "CreatedAt")
    VALUES (p_lead_id, 'STAGE_CHANGE', v_old_stage_id, p_new_stage_id, p_notes, p_user_id, NOW() AT TIME ZONE 'UTC');

    RETURN QUERY SELECT 1, 'OK'::VARCHAR;

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT 0, SQLERRM::VARCHAR;
END;
$$;

-- =============================================================================
--  usp_CRM_Lead_Close
-- =============================================================================
DROP FUNCTION IF EXISTS usp_crm_lead_close(INT, BOOLEAN, VARCHAR, INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_crm_lead_close(
    p_lead_id     INT,
    p_is_won      BOOLEAN,
    p_lost_reason VARCHAR(500) DEFAULT NULL,
    p_customer_id BIGINT DEFAULT NULL,
    p_user_id     INT DEFAULT NULL
)
RETURNS TABLE("ok" INT, "mensaje" VARCHAR)
LANGUAGE plpgsql AS $$
DECLARE
    v_old_stage_id    INT;
    v_closed_stage_id INT;
    v_new_status      VARCHAR(20);
BEGIN
    v_new_status := CASE WHEN p_is_won THEN 'WON' ELSE 'LOST' END;

    SELECT "StageId" INTO v_old_stage_id FROM crm."Lead" WHERE "LeadId" = p_lead_id;

    IF v_old_stage_id IS NULL THEN
        RETURN QUERY SELECT 0, 'Lead no encontrado'::VARCHAR;
        RETURN;
    END IF;

    SELECT s."StageId" INTO v_closed_stage_id
    FROM   crm."PipelineStage" s
    JOIN   crm."Lead" l ON l."PipelineId" = s."PipelineId"
    WHERE  l."LeadId" = p_lead_id AND s."IsClosed" = TRUE AND s."IsWon" = p_is_won
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
    WHERE  "LeadId" = p_lead_id;

    INSERT INTO crm."LeadHistory" ("LeadId", "ChangeType", "FromStageId", "ToStageId", "Notes", "ChangedByUserId", "CreatedAt")
    VALUES (p_lead_id, 'STATUS', v_old_stage_id, COALESCE(v_closed_stage_id, v_old_stage_id),
            COALESCE(p_lost_reason, 'Cerrado como ' || v_new_status), p_user_id, NOW() AT TIME ZONE 'UTC');

    RETURN QUERY SELECT 1, 'OK'::VARCHAR;

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT 0, SQLERRM::VARCHAR;
END;
$$;

-- =============================================================================
--  usp_CRM_Activity_List
-- =============================================================================
DROP FUNCTION IF EXISTS usp_crm_activity_list(INT, INT, INT, BOOLEAN, TIMESTAMP, INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_crm_activity_list(
    p_company_id   INT,
    p_lead_id      INT DEFAULT NULL,
    p_customer_id  BIGINT DEFAULT NULL,
    p_is_completed BOOLEAN DEFAULT NULL,
    p_due_before   TIMESTAMP DEFAULT NULL,
    p_page         INT DEFAULT 1,
    p_limit        INT DEFAULT 50
)
RETURNS TABLE(
    "ActivityId" BIGINT,
    "LeadId" BIGINT,
    "CustomerId" BIGINT,
    "ActivityType"     VARCHAR,
    "Subject"          VARCHAR,
    "Description"      TEXT,
    "DueDate"          TIMESTAMP,
    "CompletedAt"      TIMESTAMP,
    "IsCompleted"      BOOLEAN,
    "Priority"         VARCHAR,
    "AssignedToUserId" INT,
    "CreatedAt"        TIMESTAMP,
    "UpdatedAt"        TIMESTAMP,
    "TotalCount"       BIGINT
)
LANGUAGE plpgsql AS $$
DECLARE
    v_total BIGINT;
BEGIN
    SELECT COUNT(*) INTO v_total
    FROM   crm."Activity" a
    WHERE  a."CompanyId" = p_company_id
      AND  a."IsDeleted" = FALSE
      AND  (p_lead_id      IS NULL OR a."LeadId"      = p_lead_id)
      AND  (p_customer_id  IS NULL OR a."CustomerId"   = p_customer_id)
      AND  (p_is_completed IS NULL OR a."IsCompleted"  = p_is_completed)
      AND  (p_due_before   IS NULL OR a."DueDate"     <= p_due_before);

    RETURN QUERY
    SELECT
        a."ActivityId", a."LeadId", a."CustomerId",
        a."ActivityType", a."Subject", a."Description"::TEXT,
        a."DueDate", a."CompletedAt", a."IsCompleted",
        a."Priority", a."AssignedToUserId",
        a."CreatedAt", a."UpdatedAt",
        v_total
    FROM   crm."Activity" a
    WHERE  a."CompanyId" = p_company_id
      AND  a."IsDeleted" = FALSE
      AND  (p_lead_id      IS NULL OR a."LeadId"      = p_lead_id)
      AND  (p_customer_id  IS NULL OR a."CustomerId"   = p_customer_id)
      AND  (p_is_completed IS NULL OR a."IsCompleted"  = p_is_completed)
      AND  (p_due_before   IS NULL OR a."DueDate"     <= p_due_before)
    ORDER BY a."DueDate" ASC
    LIMIT p_limit OFFSET (p_page - 1) * p_limit;
END;
$$;

-- =============================================================================
--  usp_CRM_Activity_Create
-- =============================================================================
DROP FUNCTION IF EXISTS usp_crm_activity_create(INT, INT, INT, VARCHAR, VARCHAR, TEXT, TIMESTAMP, INT, VARCHAR, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_crm_activity_create(
    p_company_id         INT,
    p_lead_id            INT DEFAULT NULL,
    p_customer_id        BIGINT DEFAULT NULL,
    p_activity_type      VARCHAR(30) DEFAULT NULL,
    p_subject            VARCHAR(200) DEFAULT NULL,
    p_description        TEXT DEFAULT NULL,
    p_due_date           TIMESTAMP DEFAULT NULL,
    p_assigned_to_user_id INT DEFAULT NULL,
    p_priority           VARCHAR(20) DEFAULT 'MEDIUM',
    p_user_id            INT DEFAULT NULL
)
RETURNS TABLE("ok" INT, "mensaje" VARCHAR, "ActivityId" BIGINT)
LANGUAGE plpgsql AS $$
DECLARE
    v_id BIGINT;
BEGIN
    INSERT INTO crm."Activity" (
        "CompanyId", "LeadId", "CustomerId", "ActivityType",
        "Subject", "Description", "DueDate", "IsCompleted",
        "AssignedToUserId", "Priority",
        "CreatedByUserId", "UpdatedByUserId", "CreatedAt", "UpdatedAt"
    ) VALUES (
        p_company_id, p_lead_id, p_customer_id, p_activity_type,
        p_subject, p_description, p_due_date, FALSE,
        p_assigned_to_user_id, p_priority,
        p_user_id, p_user_id, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'
    ) RETURNING "ActivityId" INTO v_id;

    RETURN QUERY SELECT 1, 'OK'::VARCHAR, v_id;

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT 0, SQLERRM::VARCHAR, 0::BIGINT;
END;
$$;

-- =============================================================================
--  usp_CRM_Activity_Complete
-- =============================================================================
DROP FUNCTION IF EXISTS usp_crm_activity_complete(INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_crm_activity_complete(
    p_activity_id INT,
    p_user_id     INT DEFAULT NULL
)
RETURNS TABLE("ok" INT, "mensaje" VARCHAR)
LANGUAGE plpgsql AS $$
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

-- =============================================================================
--  usp_CRM_Activity_Update
-- =============================================================================
DROP FUNCTION IF EXISTS usp_crm_activity_update(INT, VARCHAR, TEXT, TIMESTAMP, VARCHAR, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_crm_activity_update(
    p_activity_id INT,
    p_subject     VARCHAR(200) DEFAULT NULL,
    p_description TEXT DEFAULT NULL,
    p_due_date    TIMESTAMP DEFAULT NULL,
    p_priority    VARCHAR(20) DEFAULT NULL,
    p_user_id     INT DEFAULT NULL
)
RETURNS TABLE("ok" INT, "mensaje" VARCHAR)
LANGUAGE plpgsql AS $$
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

-- =============================================================================
--  usp_CRM_Dashboard
-- =============================================================================
DROP FUNCTION IF EXISTS usp_crm_dashboard(INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_crm_dashboard(
    p_company_id  INT,
    p_pipeline_id INT DEFAULT NULL
)
RETURNS TABLE(
    "StageId" BIGINT,
    "StageName"      VARCHAR,
    "StageOrder"     INT,
    "Color"          VARCHAR,
    "LeadCount"      BIGINT,
    "TotalValue"     NUMERIC,
    "TotalLeads"     BIGINT,
    "WonLeads"       BIGINT,
    "LostLeads"      BIGINT,
    "ConversionRate" NUMERIC,
    "AvgDealValue"   NUMERIC,
    "WonThisMonth"   BIGINT,
    "LostThisMonth"  BIGINT
)
LANGUAGE plpgsql AS $$
DECLARE
    v_pipeline_id   INT;
    v_total         BIGINT;
    v_won           BIGINT;
    v_lost          BIGINT;
    v_avg           NUMERIC;
    v_month_start   TIMESTAMP;
    v_won_month     BIGINT;
    v_lost_month    BIGINT;
BEGIN
    v_pipeline_id := p_pipeline_id;
    IF v_pipeline_id IS NULL THEN
        SELECT p."PipelineId" INTO v_pipeline_id
        FROM   crm."Pipeline" p
        WHERE  p."CompanyId" = p_company_id AND p."IsDefault" = TRUE AND p."IsActive" = TRUE
        LIMIT 1;
    END IF;

    SELECT COUNT(*) INTO v_total  FROM crm."Lead" WHERE "CompanyId" = p_company_id AND "PipelineId" = v_pipeline_id;
    SELECT COUNT(*) INTO v_won    FROM crm."Lead" WHERE "CompanyId" = p_company_id AND "PipelineId" = v_pipeline_id AND "Status" = 'WON';
    SELECT COUNT(*) INTO v_lost   FROM crm."Lead" WHERE "CompanyId" = p_company_id AND "PipelineId" = v_pipeline_id AND "Status" = 'LOST';
    SELECT COALESCE(AVG("EstimatedValue"), 0) INTO v_avg FROM crm."Lead" WHERE "CompanyId" = p_company_id AND "PipelineId" = v_pipeline_id AND "Status" = 'WON';

    v_month_start := DATE_TRUNC('month', NOW() AT TIME ZONE 'UTC');
    SELECT COUNT(*) INTO v_won_month  FROM crm."Lead" WHERE "CompanyId" = p_company_id AND "PipelineId" = v_pipeline_id AND "Status" = 'WON'  AND "UpdatedAt" >= v_month_start;
    SELECT COUNT(*) INTO v_lost_month FROM crm."Lead" WHERE "CompanyId" = p_company_id AND "PipelineId" = v_pipeline_id AND "Status" = 'LOST' AND "UpdatedAt" >= v_month_start;

    RETURN QUERY
    SELECT
        s."StageId", s."StageName", s."StageOrder", s."Color",
        COUNT(l."LeadId"),
        COALESCE(SUM(l."EstimatedValue"), 0),
        v_total, v_won, v_lost,
        CASE WHEN v_total > 0 THEN ROUND(v_won * 100.0 / v_total, 2) ELSE 0 END,
        v_avg, v_won_month, v_lost_month
    FROM   crm."PipelineStage" s
    LEFT JOIN crm."Lead" l ON l."StageId" = s."StageId" AND l."Status" = 'OPEN'
    WHERE  s."PipelineId" = v_pipeline_id
    GROUP BY s."StageId", s."StageName", s."StageOrder", s."Color"
    ORDER BY s."StageOrder";
END;
$$;
