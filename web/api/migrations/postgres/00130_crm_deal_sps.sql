-- +goose Up
-- SPs CRM Deal (ADR-CRM-001): List/Detail/Upsert/MoveStage/CloseWon/CloseLost/
-- Delete/Search/Timeline + Lead_Convert.

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_crm_deal_list(
    p_company_id     INTEGER,
    p_pipeline_id    BIGINT  DEFAULT NULL,
    p_stage_id       BIGINT  DEFAULT NULL,
    p_status         VARCHAR DEFAULT NULL,
    p_owner_agent_id BIGINT  DEFAULT NULL,
    p_contact_id     BIGINT  DEFAULT NULL,
    p_crm_company_id BIGINT  DEFAULT NULL,
    p_search         VARCHAR DEFAULT NULL,
    p_page           INTEGER DEFAULT 1,
    p_limit          INTEGER DEFAULT 50
) RETURNS TABLE(
    "DealId"            BIGINT,
    "Name"              VARCHAR,
    "Value"             NUMERIC,
    "Currency"          VARCHAR,
    "Probability"       NUMERIC,
    "ExpectedCloseDate" DATE,
    "Status"            VARCHAR,
    "Priority"          VARCHAR,
    "StageId"           BIGINT,
    "StageName"         VARCHAR,
    "PipelineId"        BIGINT,
    "ContactId"         BIGINT,
    "ContactName"       VARCHAR,
    "CrmCompanyId"      BIGINT,
    "CompanyName"       VARCHAR,
    "OwnerAgentId"      BIGINT,
    "OwnerName"         VARCHAR,
    "CreatedAt"         TIMESTAMP,
    "UpdatedAt"         TIMESTAMP,
    "TotalCount"        BIGINT
)
LANGUAGE plpgsql AS $$
DECLARE
    v_offset INTEGER := GREATEST(0, (COALESCE(p_page,1) - 1) * COALESCE(p_limit,50));
    v_total  BIGINT  := 0;
BEGIN
    SELECT COUNT(*) INTO v_total
      FROM crm."Deal" d
     WHERE d."CompanyId" = p_company_id
       AND d."IsDeleted" = FALSE
       AND (p_pipeline_id    IS NULL OR d."PipelineId"    = p_pipeline_id)
       AND (p_stage_id       IS NULL OR d."StageId"       = p_stage_id)
       AND (p_status         IS NULL OR d."Status"        = p_status)
       AND (p_owner_agent_id IS NULL OR d."OwnerAgentId"  = p_owner_agent_id)
       AND (p_contact_id     IS NULL OR d."ContactId"     = p_contact_id)
       AND (p_crm_company_id IS NULL OR d."CrmCompanyId"  = p_crm_company_id)
       AND (p_search IS NULL OR p_search = '' OR d."Name" ILIKE '%' || p_search || '%');

    RETURN QUERY
    SELECT d."DealId",
           d."Name"::VARCHAR,
           d."Value",
           d."Currency"::VARCHAR,
           d."Probability",
           d."ExpectedCloseDate",
           d."Status"::VARCHAR,
           d."Priority"::VARCHAR,
           d."StageId",
           s."StageName"::VARCHAR,
           d."PipelineId",
           d."ContactId",
           CASE WHEN c."ContactId" IS NOT NULL
                THEN TRIM(c."FirstName" || ' ' || COALESCE(c."LastName",''))::VARCHAR
                ELSE NULL::VARCHAR END,
           d."CrmCompanyId",
           cc."Name"::VARCHAR,
           d."OwnerAgentId",
           a."AgentName"::VARCHAR,
           d."CreatedAt",
           d."UpdatedAt",
           v_total
      FROM crm."Deal" d
      LEFT JOIN crm."PipelineStage" s ON s."StageId"      = d."StageId"
      LEFT JOIN crm."Contact"       c ON c."ContactId"    = d."ContactId"
      LEFT JOIN crm."Company"      cc ON cc."CrmCompanyId"= d."CrmCompanyId"
      LEFT JOIN crm."Agent"         a ON a."AgentId"      = d."OwnerAgentId"
     WHERE d."CompanyId" = p_company_id
       AND d."IsDeleted" = FALSE
       AND (p_pipeline_id    IS NULL OR d."PipelineId"    = p_pipeline_id)
       AND (p_stage_id       IS NULL OR d."StageId"       = p_stage_id)
       AND (p_status         IS NULL OR d."Status"        = p_status)
       AND (p_owner_agent_id IS NULL OR d."OwnerAgentId"  = p_owner_agent_id)
       AND (p_contact_id     IS NULL OR d."ContactId"     = p_contact_id)
       AND (p_crm_company_id IS NULL OR d."CrmCompanyId"  = p_crm_company_id)
       AND (p_search IS NULL OR p_search = '' OR d."Name" ILIKE '%' || p_search || '%')
     ORDER BY d."UpdatedAt" DESC
     LIMIT  COALESCE(p_limit, 50)
     OFFSET v_offset;
END;
$$;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_crm_deal_detail(
    p_company_id INTEGER,
    p_deal_id    BIGINT
) RETURNS TABLE(
    "DealId"            BIGINT,
    "Name"              VARCHAR,
    "Value"             NUMERIC,
    "Currency"          VARCHAR,
    "Probability"       NUMERIC,
    "ExpectedCloseDate" DATE,
    "ActualCloseDate"   DATE,
    "Status"            VARCHAR,
    "WonLostReason"     VARCHAR,
    "Priority"          VARCHAR,
    "Source"            VARCHAR,
    "Notes"             TEXT,
    "Tags"              VARCHAR,
    "PipelineId"        BIGINT,
    "StageId"           BIGINT,
    "StageName"         VARCHAR,
    "ContactId"         BIGINT,
    "ContactName"       VARCHAR,
    "CrmCompanyId"      BIGINT,
    "CompanyName"       VARCHAR,
    "OwnerAgentId"      BIGINT,
    "OwnerName"         VARCHAR,
    "SourceLeadId"      BIGINT,
    "CreatedAt"         TIMESTAMP,
    "UpdatedAt"         TIMESTAMP,
    "ClosedAt"          TIMESTAMP
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT d."DealId",
           d."Name"::VARCHAR,
           d."Value",
           d."Currency"::VARCHAR,
           d."Probability",
           d."ExpectedCloseDate",
           d."ActualCloseDate",
           d."Status"::VARCHAR,
           d."WonLostReason"::VARCHAR,
           d."Priority"::VARCHAR,
           d."Source"::VARCHAR,
           d."Notes",
           d."Tags"::VARCHAR,
           d."PipelineId",
           d."StageId",
           s."StageName"::VARCHAR,
           d."ContactId",
           CASE WHEN c."ContactId" IS NOT NULL
                THEN TRIM(c."FirstName" || ' ' || COALESCE(c."LastName",''))::VARCHAR
                ELSE NULL::VARCHAR END,
           d."CrmCompanyId",
           cc."Name"::VARCHAR,
           d."OwnerAgentId",
           a."AgentName"::VARCHAR,
           d."SourceLeadId",
           d."CreatedAt",
           d."UpdatedAt",
           d."ClosedAt"
      FROM crm."Deal" d
      LEFT JOIN crm."PipelineStage" s ON s."StageId"      = d."StageId"
      LEFT JOIN crm."Contact"       c ON c."ContactId"    = d."ContactId"
      LEFT JOIN crm."Company"      cc ON cc."CrmCompanyId"= d."CrmCompanyId"
      LEFT JOIN crm."Agent"         a ON a."AgentId"      = d."OwnerAgentId"
     WHERE d."CompanyId" = p_company_id
       AND d."DealId"    = p_deal_id
       AND d."IsDeleted" = FALSE;
END;
$$;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_crm_deal_upsert(
    p_company_id         INTEGER,
    p_deal_id            BIGINT   DEFAULT NULL,
    p_name               VARCHAR  DEFAULT NULL,
    p_pipeline_id        BIGINT   DEFAULT NULL,
    p_stage_id           BIGINT   DEFAULT NULL,
    p_contact_id         BIGINT   DEFAULT NULL,
    p_crm_company_id     BIGINT   DEFAULT NULL,
    p_owner_agent_id     BIGINT   DEFAULT NULL,
    p_value              NUMERIC  DEFAULT 0,
    p_currency           VARCHAR  DEFAULT 'USD',
    p_probability        NUMERIC  DEFAULT NULL,
    p_expected_close     DATE     DEFAULT NULL,
    p_priority           VARCHAR  DEFAULT 'MEDIUM',
    p_source             VARCHAR  DEFAULT NULL,
    p_notes              TEXT     DEFAULT NULL,
    p_tags               VARCHAR  DEFAULT NULL,
    p_branch_id          INTEGER  DEFAULT 1,
    p_user_id            INTEGER  DEFAULT NULL
) RETURNS TABLE("ok" BOOLEAN, "mensaje" VARCHAR, "id" BIGINT)
LANGUAGE plpgsql AS $$
DECLARE
    v_id BIGINT := p_deal_id;
BEGIN
    IF COALESCE(p_name,'')::VARCHAR = '' THEN
        RETURN QUERY SELECT FALSE, 'Nombre del deal requerido'::VARCHAR, NULL::BIGINT;
        RETURN;
    END IF;
    IF v_id IS NULL AND (p_pipeline_id IS NULL OR p_stage_id IS NULL) THEN
        RETURN QUERY SELECT FALSE, 'PipelineId y StageId son requeridos al crear'::VARCHAR, NULL::BIGINT;
        RETURN;
    END IF;

    IF v_id IS NULL THEN
        INSERT INTO crm."Deal" (
            "CompanyId","BranchId","Name","PipelineId","StageId","ContactId","CrmCompanyId",
            "OwnerAgentId","Value","Currency","Probability","ExpectedCloseDate",
            "Priority","Source","Notes","Tags","CreatedByUserId","UpdatedByUserId"
        ) VALUES (
            p_company_id, COALESCE(p_branch_id,1), p_name, p_pipeline_id, p_stage_id,
            p_contact_id, p_crm_company_id, p_owner_agent_id,
            COALESCE(p_value,0), COALESCE(p_currency,'USD'), p_probability, p_expected_close,
            COALESCE(p_priority,'MEDIUM'), p_source, p_notes, p_tags, p_user_id, p_user_id
        )
        RETURNING "DealId" INTO v_id;

        INSERT INTO crm."DealHistory" ("DealId","ChangeType","NewValue","UserId")
        VALUES (v_id, 'CREATED',
                jsonb_build_object('name',p_name,'pipelineId',p_pipeline_id,'stageId',p_stage_id,'value',p_value),
                p_user_id);
    ELSE
        UPDATE crm."Deal" SET
            "Name"              = COALESCE(p_name,           "Name"),
            "PipelineId"        = COALESCE(p_pipeline_id,    "PipelineId"),
            "StageId"           = COALESCE(p_stage_id,       "StageId"),
            "ContactId"         = COALESCE(p_contact_id,     "ContactId"),
            "CrmCompanyId"      = COALESCE(p_crm_company_id, "CrmCompanyId"),
            "OwnerAgentId"      = COALESCE(p_owner_agent_id, "OwnerAgentId"),
            "Value"             = COALESCE(p_value,          "Value"),
            "Currency"          = COALESCE(p_currency,       "Currency"),
            "Probability"       = COALESCE(p_probability,    "Probability"),
            "ExpectedCloseDate" = COALESCE(p_expected_close, "ExpectedCloseDate"),
            "Priority"          = COALESCE(p_priority,       "Priority"),
            "Source"            = COALESCE(p_source,         "Source"),
            "Notes"             = COALESCE(p_notes,          "Notes"),
            "Tags"              = COALESCE(p_tags,           "Tags"),
            "UpdatedByUserId"   = p_user_id,
            "UpdatedAt"         = (now() AT TIME ZONE 'UTC'),
            "RowVer"            = "RowVer" + 1
          WHERE "DealId"    = v_id
            AND "CompanyId" = p_company_id
            AND "IsDeleted" = FALSE;

        IF NOT FOUND THEN
            RETURN QUERY SELECT FALSE, 'Deal no encontrado'::VARCHAR, NULL::BIGINT;
            RETURN;
        END IF;

        INSERT INTO crm."DealHistory" ("DealId","ChangeType","NewValue","UserId")
        VALUES (v_id, 'VALUE_CHANGE',
                jsonb_build_object('value',p_value,'stageId',p_stage_id),
                p_user_id);
    END IF;

    RETURN QUERY SELECT TRUE, 'OK'::VARCHAR, v_id;
END;
$$;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_crm_deal_move_stage(
    p_company_id  INTEGER,
    p_deal_id     BIGINT,
    p_new_stage_id BIGINT,
    p_notes       TEXT    DEFAULT NULL,
    p_user_id     INTEGER DEFAULT NULL
) RETURNS TABLE("ok" BOOLEAN, "mensaje" VARCHAR, "id" BIGINT)
LANGUAGE plpgsql AS $$
DECLARE
    v_old_stage BIGINT;
BEGIN
    SELECT "StageId" INTO v_old_stage
      FROM crm."Deal"
     WHERE "DealId"    = p_deal_id
       AND "CompanyId" = p_company_id
       AND "IsDeleted" = FALSE;

    IF v_old_stage IS NULL THEN
        RETURN QUERY SELECT FALSE, 'Deal no encontrado'::VARCHAR, NULL::BIGINT;
        RETURN;
    END IF;

    UPDATE crm."Deal"
       SET "StageId"         = p_new_stage_id,
           "UpdatedAt"       = (now() AT TIME ZONE 'UTC'),
           "UpdatedByUserId" = p_user_id
     WHERE "DealId"    = p_deal_id
       AND "CompanyId" = p_company_id;

    INSERT INTO crm."DealHistory" ("DealId","ChangeType","OldValue","NewValue","Notes","UserId")
    VALUES (p_deal_id,'STAGE_CHANGE',
            jsonb_build_object('stageId',v_old_stage),
            jsonb_build_object('stageId',p_new_stage_id),
            p_notes, p_user_id);

    RETURN QUERY SELECT TRUE, 'OK'::VARCHAR, p_deal_id;
END;
$$;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_crm_deal_close_won(
    p_company_id INTEGER,
    p_deal_id    BIGINT,
    p_reason     VARCHAR DEFAULT NULL,
    p_user_id    INTEGER DEFAULT NULL
) RETURNS TABLE("ok" BOOLEAN, "mensaje" VARCHAR, "id" BIGINT)
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE crm."Deal" SET
        "Status"          = 'WON',
        "WonLostReason"   = p_reason,
        "ActualCloseDate" = (now() AT TIME ZONE 'UTC')::DATE,
        "ClosedAt"        = (now() AT TIME ZONE 'UTC'),
        "UpdatedAt"       = (now() AT TIME ZONE 'UTC'),
        "UpdatedByUserId" = p_user_id
      WHERE "DealId"    = p_deal_id
        AND "CompanyId" = p_company_id
        AND "IsDeleted" = FALSE
        AND "Status"    = 'OPEN';

    IF NOT FOUND THEN
        RETURN QUERY SELECT FALSE, 'Deal no encontrado o ya cerrado'::VARCHAR, NULL::BIGINT;
        RETURN;
    END IF;

    INSERT INTO crm."DealHistory" ("DealId","ChangeType","NewValue","Notes","UserId")
    VALUES (p_deal_id,'WON', jsonb_build_object('status','WON'), p_reason, p_user_id);

    RETURN QUERY SELECT TRUE, 'OK'::VARCHAR, p_deal_id;
END;
$$;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_crm_deal_close_lost(
    p_company_id INTEGER,
    p_deal_id    BIGINT,
    p_reason     VARCHAR DEFAULT NULL,
    p_user_id    INTEGER DEFAULT NULL
) RETURNS TABLE("ok" BOOLEAN, "mensaje" VARCHAR, "id" BIGINT)
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE crm."Deal" SET
        "Status"          = 'LOST',
        "WonLostReason"   = p_reason,
        "ActualCloseDate" = (now() AT TIME ZONE 'UTC')::DATE,
        "ClosedAt"        = (now() AT TIME ZONE 'UTC'),
        "UpdatedAt"       = (now() AT TIME ZONE 'UTC'),
        "UpdatedByUserId" = p_user_id
      WHERE "DealId"    = p_deal_id
        AND "CompanyId" = p_company_id
        AND "IsDeleted" = FALSE
        AND "Status"    = 'OPEN';

    IF NOT FOUND THEN
        RETURN QUERY SELECT FALSE, 'Deal no encontrado o ya cerrado'::VARCHAR, NULL::BIGINT;
        RETURN;
    END IF;

    INSERT INTO crm."DealHistory" ("DealId","ChangeType","NewValue","Notes","UserId")
    VALUES (p_deal_id,'LOST', jsonb_build_object('status','LOST'), p_reason, p_user_id);

    RETURN QUERY SELECT TRUE, 'OK'::VARCHAR, p_deal_id;
END;
$$;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_crm_deal_delete(
    p_company_id INTEGER,
    p_deal_id    BIGINT,
    p_user_id    INTEGER DEFAULT NULL
) RETURNS TABLE("ok" BOOLEAN, "mensaje" VARCHAR, "id" BIGINT)
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE crm."Deal" SET
        "IsDeleted"       = TRUE,
        "DeletedAt"       = (now() AT TIME ZONE 'UTC'),
        "DeletedByUserId" = p_user_id,
        "UpdatedByUserId" = p_user_id,
        "UpdatedAt"       = (now() AT TIME ZONE 'UTC')
      WHERE "DealId"    = p_deal_id
        AND "CompanyId" = p_company_id
        AND "IsDeleted" = FALSE;

    IF NOT FOUND THEN
        RETURN QUERY SELECT FALSE, 'Deal no encontrado'::VARCHAR, NULL::BIGINT;
        RETURN;
    END IF;

    RETURN QUERY SELECT TRUE, 'OK'::VARCHAR, p_deal_id;
END;
$$;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_crm_deal_search(
    p_company_id INTEGER,
    p_term       VARCHAR,
    p_limit      INTEGER DEFAULT 20
) RETURNS TABLE(
    "DealId"   BIGINT,
    "Name"     VARCHAR,
    "Value"    NUMERIC,
    "Currency" VARCHAR,
    "Status"   VARCHAR
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT d."DealId",
           d."Name"::VARCHAR,
           d."Value",
           d."Currency"::VARCHAR,
           d."Status"::VARCHAR
      FROM crm."Deal" d
     WHERE d."CompanyId" = p_company_id
       AND d."IsDeleted" = FALSE
       AND (p_term IS NULL OR p_term = ''
            OR d."Name" ILIKE '%' || p_term || '%')
     ORDER BY d."UpdatedAt" DESC
     LIMIT COALESCE(p_limit, 20);
END;
$$;
-- +goose StatementEnd

-- ─────────────────────────────────────────────────────────────────────────────
-- Timeline: une DealHistory + Activity + CallLog
-- ─────────────────────────────────────────────────────────────────────────────

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_crm_deal_timeline(
    p_company_id INTEGER,
    p_deal_id    BIGINT,
    p_limit      INTEGER DEFAULT 100
) RETURNS TABLE(
    "EventAt"     TIMESTAMP,
    "Kind"        VARCHAR,
    "Title"       VARCHAR,
    "Description" TEXT,
    "UserId"      INTEGER,
    "Metadata"    JSONB
)
LANGUAGE plpgsql AS $$
DECLARE
    v_contact_id BIGINT;
    v_lead_id    BIGINT;
BEGIN
    SELECT "ContactId","SourceLeadId" INTO v_contact_id, v_lead_id
      FROM crm."Deal"
     WHERE "DealId" = p_deal_id AND "CompanyId" = p_company_id;

    RETURN QUERY
    SELECT h."ChangedAt"         AS "EventAt",
           ('HISTORY:' || h."ChangeType")::VARCHAR AS "Kind",
           h."ChangeType"::VARCHAR AS "Title",
           h."Notes"              AS "Description",
           h."UserId"             AS "UserId",
           jsonb_build_object('oldValue',h."OldValue",'newValue',h."NewValue") AS "Metadata"
      FROM crm."DealHistory" h
     WHERE h."DealId" = p_deal_id
    UNION ALL
    SELECT a."CreatedAt"          AS "EventAt",
           ('ACTIVITY:' || a."ActivityType")::VARCHAR AS "Kind",
           a."Subject"::VARCHAR   AS "Title",
           a."Description"        AS "Description",
           a."CreatedByUserId"    AS "UserId",
           jsonb_build_object('isCompleted',a."IsCompleted",'priority',a."Priority") AS "Metadata"
      FROM crm."Activity" a
     WHERE a."CompanyId" = p_company_id
       AND (a."LeadId" = v_lead_id
            OR (v_contact_id IS NOT NULL AND a."CustomerId" = (
                    SELECT "PromotedCustomerId"
                      FROM crm."Contact"
                     WHERE "ContactId" = v_contact_id)))
    UNION ALL
    SELECT cl."CallStartTime"     AS "EventAt",
           ('CALL:' || cl."CallDirection")::VARCHAR AS "Kind",
           cl."ContactName"::VARCHAR AS "Title",
           cl."Notes"               AS "Description",
           cl."CreatedByUserId"     AS "UserId",
           jsonb_build_object('result',cl."Result",'duration',cl."DurationSeconds") AS "Metadata"
      FROM crm."CallLog" cl
     WHERE cl."CompanyId" = p_company_id
       AND cl."LeadId"    = v_lead_id
     ORDER BY "EventAt" DESC
     LIMIT COALESCE(p_limit, 100);
END;
$$;
-- +goose StatementEnd

-- ─────────────────────────────────────────────────────────────────────────────
-- Lead_Convert: crea Deal a partir de Lead y marca Lead como CONVERTED.
-- ─────────────────────────────────────────────────────────────────────────────

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_crm_lead_convert(
    p_company_id      INTEGER,
    p_lead_id         BIGINT,
    p_deal_name       VARCHAR DEFAULT NULL,
    p_pipeline_id     BIGINT  DEFAULT NULL,
    p_stage_id        BIGINT  DEFAULT NULL,
    p_crm_company_id  BIGINT  DEFAULT NULL,
    p_user_id         INTEGER DEFAULT NULL
) RETURNS TABLE("ok" BOOLEAN, "mensaje" VARCHAR, "id" BIGINT)
LANGUAGE plpgsql AS $$
DECLARE
    v_lead        crm."Lead"%ROWTYPE;
    v_deal_id     BIGINT;
    v_contact_id  BIGINT;
    v_pipeline    BIGINT;
    v_stage       BIGINT;
BEGIN
    SELECT * INTO v_lead
      FROM crm."Lead"
     WHERE "LeadId"    = p_lead_id
       AND "CompanyId" = p_company_id
       AND "IsDeleted" = FALSE;

    IF NOT FOUND THEN
        RETURN QUERY SELECT FALSE, 'Lead no encontrado'::VARCHAR, NULL::BIGINT;
        RETURN;
    END IF;

    IF v_lead."ConvertedToDealId" IS NOT NULL THEN
        RETURN QUERY SELECT TRUE, 'Lead ya convertido'::VARCHAR, v_lead."ConvertedToDealId";
        RETURN;
    END IF;

    v_pipeline := COALESCE(p_pipeline_id, v_lead."PipelineId");
    v_stage    := COALESCE(p_stage_id,    v_lead."StageId");

    -- Contact derivado del Lead (FirstName obligatorio)
    IF COALESCE(v_lead."ContactName",'')::VARCHAR <> '' THEN
        INSERT INTO crm."Contact" (
            "CompanyId","CrmCompanyId","FirstName","Email","Phone",
            "CreatedByUserId","UpdatedByUserId"
        ) VALUES (
            p_company_id, p_crm_company_id, v_lead."ContactName",
            v_lead."Email", v_lead."Phone", p_user_id, p_user_id
        )
        RETURNING "ContactId" INTO v_contact_id;
    END IF;

    INSERT INTO crm."Deal" (
        "CompanyId","BranchId","Name","PipelineId","StageId","ContactId","CrmCompanyId",
        "Value","Currency","ExpectedCloseDate","SourceLeadId","Priority","Source",
        "CreatedByUserId","UpdatedByUserId"
    ) VALUES (
        p_company_id, v_lead."BranchId",
        COALESCE(p_deal_name, v_lead."ContactName", 'Deal-' || v_lead."LeadId"::VARCHAR),
        v_pipeline, v_stage, v_contact_id, p_crm_company_id,
        COALESCE(v_lead."EstimatedValue",0),
        COALESCE(v_lead."CurrencyCode",'USD'),
        v_lead."ExpectedCloseDate",
        v_lead."LeadId",
        COALESCE(v_lead."Priority",'MEDIUM'),
        v_lead."Source",
        p_user_id, p_user_id
    )
    RETURNING "DealId" INTO v_deal_id;

    UPDATE crm."Lead"
       SET "Status"            = 'CONVERTED',
           "ConvertedToDealId" = v_deal_id,
           "UpdatedAt"         = (now() AT TIME ZONE 'UTC'),
           "UpdatedByUserId"   = p_user_id
     WHERE "LeadId"    = p_lead_id
       AND "CompanyId" = p_company_id;

    INSERT INTO crm."DealHistory" ("DealId","ChangeType","NewValue","UserId")
    VALUES (v_deal_id, 'CREATED',
            jsonb_build_object('sourceLeadId',p_lead_id,'convertedAt',(now() AT TIME ZONE 'UTC')),
            p_user_id);

    RETURN QUERY SELECT TRUE, 'OK'::VARCHAR, v_deal_id;
END;
$$;
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
DROP FUNCTION IF EXISTS public.usp_crm_lead_convert(INTEGER, BIGINT, VARCHAR, BIGINT, BIGINT, BIGINT, INTEGER);
DROP FUNCTION IF EXISTS public.usp_crm_deal_timeline(INTEGER, BIGINT, INTEGER);
DROP FUNCTION IF EXISTS public.usp_crm_deal_search(INTEGER, VARCHAR, INTEGER);
DROP FUNCTION IF EXISTS public.usp_crm_deal_delete(INTEGER, BIGINT, INTEGER);
DROP FUNCTION IF EXISTS public.usp_crm_deal_close_lost(INTEGER, BIGINT, VARCHAR, INTEGER);
DROP FUNCTION IF EXISTS public.usp_crm_deal_close_won(INTEGER, BIGINT, VARCHAR, INTEGER);
DROP FUNCTION IF EXISTS public.usp_crm_deal_move_stage(INTEGER, BIGINT, BIGINT, TEXT, INTEGER);
DROP FUNCTION IF EXISTS public.usp_crm_deal_upsert(
    INTEGER, BIGINT, VARCHAR, BIGINT, BIGINT, BIGINT, BIGINT, BIGINT, NUMERIC, VARCHAR,
    NUMERIC, DATE, VARCHAR, VARCHAR, TEXT, VARCHAR, INTEGER, INTEGER);
DROP FUNCTION IF EXISTS public.usp_crm_deal_detail(INTEGER, BIGINT);
DROP FUNCTION IF EXISTS public.usp_crm_deal_list(INTEGER, BIGINT, BIGINT, VARCHAR, BIGINT, BIGINT, BIGINT, VARCHAR, INTEGER, INTEGER);
-- +goose StatementEnd
