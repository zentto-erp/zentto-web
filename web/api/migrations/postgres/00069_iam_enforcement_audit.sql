-- +goose Up
-- Migration: iam_enforcement_audit
-- Adds missing SPs for IAM enforcement and audit change log table.

-- =============================================================================
-- 1. SP: usp_Sys_License_GetLimits — unified limits query for UI
-- =============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_sys_license_getlimits(
    p_company_id INTEGER
)
RETURNS TABLE(
    "maxUsers"            INTEGER,
    "currentUsers"        INTEGER,
    "maxCompanies"        INTEGER,
    "currentCompanies"    INTEGER,
    "maxBranches"         INTEGER,
    "currentBranches"     INTEGER,
    "multiCompanyEnabled" BOOLEAN,
    "plan"                VARCHAR
)
LANGUAGE plpgsql AS $$
DECLARE
    v_max_users       INTEGER;
    v_max_companies   INTEGER;
    v_max_branches    INTEGER;
    v_multi_enabled   BOOLEAN;
    v_plan            VARCHAR;
    v_current_users   INTEGER;
    v_current_companies INTEGER;
    v_current_branches  INTEGER;
BEGIN
    -- Get limits from active license + plan definition
    SELECT COALESCE(l."MaxUsers", pd."MaxUsers"),
           COALESCE(l."MaxCompanies", pd."MaxCompanies"),
           COALESCE(l."MaxBranches", pd."MaxBranches"),
           COALESCE(l."MultiCompanyEnabled", pd."MultiCompanyEnabled", FALSE),
           COALESCE(l."Plan", 'FREE')::VARCHAR
      INTO v_max_users, v_max_companies, v_max_branches, v_multi_enabled, v_plan
      FROM sys."License" l
      LEFT JOIN cfg."PlanDefinition" pd ON pd."PlanCode" = l."Plan"
     WHERE l."CompanyId" = p_company_id
       AND l."Status" = 'ACTIVE'
     ORDER BY l."ExpiresAt" DESC NULLS FIRST
     LIMIT 1;

    -- Fallback to FREE plan
    IF v_plan IS NULL THEN
        SELECT pd."MaxUsers", pd."MaxCompanies", pd."MaxBranches",
               pd."MultiCompanyEnabled", pd."PlanCode"::VARCHAR
          INTO v_max_users, v_max_companies, v_max_branches, v_multi_enabled, v_plan
          FROM cfg."PlanDefinition" pd
         WHERE pd."PlanCode" = 'FREE';
    END IF;

    -- Count current resources
    SELECT COUNT(*)::INTEGER INTO v_current_users
      FROM sec."User"
     WHERE "CompanyId" = p_company_id
       AND "IsActive" = TRUE AND "IsDeleted" = FALSE;

    SELECT COUNT(*)::INTEGER INTO v_current_companies
      FROM cfg."Company"
     WHERE "IsActive" = TRUE AND "IsDeleted" = FALSE;

    SELECT COUNT(*)::INTEGER INTO v_current_branches
      FROM cfg."Branch"
     WHERE "CompanyId" = p_company_id
       AND "IsActive" = TRUE AND "IsDeleted" = FALSE;

    RETURN QUERY SELECT
        v_max_users,       v_current_users,
        v_max_companies,   v_current_companies,
        v_max_branches,    v_current_branches,
        v_multi_enabled,   v_plan;
END;
$$;
-- +goose StatementEnd

-- =============================================================================
-- 2. SP: usp_sys_Subscription_GetCompanyByPaddleId
--    (wrapper that resolves CompanyId from PaddleSubscriptionId via License)
-- =============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_sys_subscription_getcompanybypaddleid(
    p_paddle_subscription_id VARCHAR
)
RETURNS TABLE("CompanyId" INTEGER)
LANGUAGE plpgsql AS $$
BEGIN
    -- First try sys."Subscription" table
    RETURN QUERY
    SELECT s."CompanyId"
      FROM sys."Subscription" s
     WHERE s."PaddleSubscriptionId" = p_paddle_subscription_id
     LIMIT 1;

    IF FOUND THEN RETURN; END IF;

    -- Fallback: try sys."License".PaddleSubId
    RETURN QUERY
    SELECT l."CompanyId"
      FROM sys."License" l
     WHERE l."PaddleSubId" = p_paddle_subscription_id
       AND l."Status" = 'ACTIVE'
     LIMIT 1;
END;
$$;
-- +goose StatementEnd

-- =============================================================================
-- 3. Table: audit."IamChangeLog"
-- =============================================================================
CREATE TABLE IF NOT EXISTS audit."IamChangeLog" (
    "IamChangeId"   BIGSERIAL   PRIMARY KEY,
    "CompanyId"     INTEGER     NOT NULL,
    "ChangeType"    VARCHAR(50) NOT NULL,
    "EntityType"    VARCHAR(50) NOT NULL,
    "EntityId"      VARCHAR(50),
    "OldValue"      TEXT,
    "NewValue"      TEXT,
    "ChangedByUserId" INTEGER  NOT NULL,
    "ChangedAt"     TIMESTAMP   DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "IpAddress"     VARCHAR(50),
    "UserAgent"     VARCHAR(500)
);

CREATE INDEX IF NOT EXISTS idx_iam_changelog_company
    ON audit."IamChangeLog" ("CompanyId", "ChangedAt" DESC);

CREATE INDEX IF NOT EXISTS idx_iam_changelog_type
    ON audit."IamChangeLog" ("ChangeType", "ChangedAt" DESC);

-- =============================================================================
-- 4. SP: usp_Audit_IamChange_Insert
-- =============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_audit_iamchange_insert(
    p_company_id        INTEGER,
    p_change_type       VARCHAR,
    p_entity_type       VARCHAR,
    p_entity_id         VARCHAR DEFAULT NULL,
    p_old_value         TEXT    DEFAULT NULL,
    p_new_value         TEXT    DEFAULT NULL,
    p_changed_by_user_id INTEGER DEFAULT 0,
    p_ip_address        VARCHAR DEFAULT NULL,
    p_user_agent        VARCHAR DEFAULT NULL
)
RETURNS TABLE("ok" BOOLEAN, "mensaje" VARCHAR)
LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO audit."IamChangeLog" (
        "CompanyId", "ChangeType", "EntityType", "EntityId",
        "OldValue", "NewValue", "ChangedByUserId",
        "IpAddress", "UserAgent"
    ) VALUES (
        p_company_id, p_change_type, p_entity_type, p_entity_id,
        p_old_value, p_new_value, p_changed_by_user_id,
        p_ip_address, p_user_agent
    );

    RETURN QUERY SELECT TRUE::BOOLEAN, 'Cambio IAM registrado'::VARCHAR;
END;
$$;
-- +goose StatementEnd

-- =============================================================================
-- 5. SP: usp_Audit_IamChange_List
-- =============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_audit_iamchange_list(
    p_company_id   INTEGER,
    p_change_type  VARCHAR DEFAULT NULL,
    p_entity_type  VARCHAR DEFAULT NULL,
    p_page         INTEGER DEFAULT 1,
    p_limit        INTEGER DEFAULT 50
)
RETURNS TABLE(
    "IamChangeId"     BIGINT,
    "ChangeType"      VARCHAR,
    "EntityType"      VARCHAR,
    "EntityId"        VARCHAR,
    "OldValue"        TEXT,
    "NewValue"        TEXT,
    "ChangedByUserId" INTEGER,
    "ChangedByName"   VARCHAR,
    "ChangedAt"       TIMESTAMP,
    "TotalCount"      BIGINT
)
LANGUAGE plpgsql AS $$
DECLARE
    v_offset INTEGER := (GREATEST(p_page, 1) - 1) * LEAST(GREATEST(p_limit, 1), 500);
    v_limit  INTEGER := LEAST(GREATEST(p_limit, 1), 500);
    v_total  BIGINT;
BEGIN
    SELECT COUNT(*) INTO v_total
      FROM audit."IamChangeLog" c
     WHERE c."CompanyId" = p_company_id
       AND (p_change_type IS NULL OR c."ChangeType" = p_change_type)
       AND (p_entity_type IS NULL OR c."EntityType" = p_entity_type);

    RETURN QUERY
    SELECT c."IamChangeId",
           c."ChangeType"::VARCHAR,
           c."EntityType"::VARCHAR,
           c."EntityId"::VARCHAR,
           c."OldValue",
           c."NewValue",
           c."ChangedByUserId",
           COALESCE(u."FullName", u."UserName", 'Sistema')::VARCHAR AS "ChangedByName",
           c."ChangedAt",
           v_total AS "TotalCount"
      FROM audit."IamChangeLog" c
      LEFT JOIN sec."User" u ON u."UserId" = c."ChangedByUserId"
     WHERE c."CompanyId" = p_company_id
       AND (p_change_type IS NULL OR c."ChangeType" = p_change_type)
       AND (p_entity_type IS NULL OR c."EntityType" = p_entity_type)
     ORDER BY c."ChangedAt" DESC
    OFFSET v_offset LIMIT v_limit;
END;
$$;
-- +goose StatementEnd


-- +goose Down

DROP FUNCTION IF EXISTS public.usp_audit_iamchange_list(INTEGER, VARCHAR, VARCHAR, INTEGER, INTEGER);
DROP FUNCTION IF EXISTS public.usp_audit_iamchange_insert(INTEGER, VARCHAR, VARCHAR, VARCHAR, TEXT, TEXT, INTEGER, VARCHAR, VARCHAR);
DROP TABLE IF EXISTS audit."IamChangeLog";
DROP FUNCTION IF EXISTS public.usp_sys_subscription_getcompanybypaddleid(VARCHAR);
DROP FUNCTION IF EXISTS public.usp_sys_license_getlimits(INTEGER);
