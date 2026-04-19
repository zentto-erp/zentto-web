-- +goose Up
-- Fix: usp_crm_saved_view_list y usp_crm_saved_view_detail usaban TIMESTAMPTZ
-- en el RETURNS TABLE. El contrato del proyecto requiere TIMESTAMP (sin zona).
-- La tabla interna sigue usando TIMESTAMPTZ; las funciones castean al retornar.

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_crm_saved_view_list(
    p_company_id INTEGER,
    p_user_id    INTEGER,
    p_entity     VARCHAR DEFAULT NULL
)
RETURNS TABLE(
    "ViewId"      BIGINT,
    "CompanyId"   INTEGER,
    "UserId"      INTEGER,
    "Entity"      VARCHAR,
    "Name"        VARCHAR,
    "FilterJson"  JSONB,
    "ColumnsJson" JSONB,
    "SortJson"    JSONB,
    "IsShared"    BOOLEAN,
    "IsDefault"   BOOLEAN,
    "IsOwner"     BOOLEAN,
    "CreatedAt"   TIMESTAMP,
    "UpdatedAt"   TIMESTAMP
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        sv."ViewId",
        sv."CompanyId",
        sv."UserId",
        sv."Entity"::VARCHAR,
        sv."Name"::VARCHAR,
        sv."FilterJson",
        sv."ColumnsJson",
        sv."SortJson",
        sv."IsShared",
        sv."IsDefault",
        (sv."UserId" = p_user_id) AS "IsOwner",
        sv."CreatedAt"::TIMESTAMP,
        sv."UpdatedAt"::TIMESTAMP
    FROM   crm."SavedView" sv
    WHERE  sv."CompanyId" = p_company_id
      AND  (p_entity IS NULL OR sv."Entity" = p_entity)
      AND  (sv."UserId" = p_user_id OR sv."IsShared" = TRUE)
    ORDER BY sv."Entity", sv."IsDefault" DESC, sv."Name";
END;
$$;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_crm_saved_view_detail(
    p_company_id INTEGER,
    p_user_id    INTEGER,
    p_view_id    BIGINT
)
RETURNS TABLE(
    "ViewId"      BIGINT,
    "CompanyId"   INTEGER,
    "UserId"      INTEGER,
    "Entity"      VARCHAR,
    "Name"        VARCHAR,
    "FilterJson"  JSONB,
    "ColumnsJson" JSONB,
    "SortJson"    JSONB,
    "IsShared"    BOOLEAN,
    "IsDefault"   BOOLEAN,
    "IsOwner"     BOOLEAN,
    "CreatedAt"   TIMESTAMP,
    "UpdatedAt"   TIMESTAMP
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        sv."ViewId",
        sv."CompanyId",
        sv."UserId",
        sv."Entity"::VARCHAR,
        sv."Name"::VARCHAR,
        sv."FilterJson",
        sv."ColumnsJson",
        sv."SortJson",
        sv."IsShared",
        sv."IsDefault",
        (sv."UserId" = p_user_id) AS "IsOwner",
        sv."CreatedAt"::TIMESTAMP,
        sv."UpdatedAt"::TIMESTAMP
    FROM   crm."SavedView" sv
    WHERE  sv."ViewId"    = p_view_id
      AND  sv."CompanyId" = p_company_id
      AND  (sv."UserId" = p_user_id OR sv."IsShared" = TRUE);
END;
$$;
-- +goose StatementEnd


-- +goose Down
-- Revertir a TIMESTAMPTZ (estado previo de migration 00126_crm_saved_view)
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_crm_saved_view_list(
    p_company_id INTEGER,
    p_user_id    INTEGER,
    p_entity     VARCHAR DEFAULT NULL
)
RETURNS TABLE(
    "ViewId"      BIGINT,
    "CompanyId"   INTEGER,
    "UserId"      INTEGER,
    "Entity"      VARCHAR,
    "Name"        VARCHAR,
    "FilterJson"  JSONB,
    "ColumnsJson" JSONB,
    "SortJson"    JSONB,
    "IsShared"    BOOLEAN,
    "IsDefault"   BOOLEAN,
    "IsOwner"     BOOLEAN,
    "CreatedAt"   TIMESTAMPTZ,
    "UpdatedAt"   TIMESTAMPTZ
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT sv."ViewId", sv."CompanyId", sv."UserId",
           sv."Entity"::VARCHAR, sv."Name"::VARCHAR,
           sv."FilterJson", sv."ColumnsJson", sv."SortJson",
           sv."IsShared", sv."IsDefault",
           (sv."UserId" = p_user_id) AS "IsOwner",
           sv."CreatedAt", sv."UpdatedAt"
    FROM   crm."SavedView" sv
    WHERE  sv."CompanyId" = p_company_id
      AND  (p_entity IS NULL OR sv."Entity" = p_entity)
      AND  (sv."UserId" = p_user_id OR sv."IsShared" = TRUE)
    ORDER BY sv."Entity", sv."IsDefault" DESC, sv."Name";
END;
$$;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_crm_saved_view_detail(
    p_company_id INTEGER,
    p_user_id    INTEGER,
    p_view_id    BIGINT
)
RETURNS TABLE(
    "ViewId"      BIGINT,
    "CompanyId"   INTEGER,
    "UserId"      INTEGER,
    "Entity"      VARCHAR,
    "Name"        VARCHAR,
    "FilterJson"  JSONB,
    "ColumnsJson" JSONB,
    "SortJson"    JSONB,
    "IsShared"    BOOLEAN,
    "IsDefault"   BOOLEAN,
    "IsOwner"     BOOLEAN,
    "CreatedAt"   TIMESTAMPTZ,
    "UpdatedAt"   TIMESTAMPTZ
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT sv."ViewId", sv."CompanyId", sv."UserId",
           sv."Entity"::VARCHAR, sv."Name"::VARCHAR,
           sv."FilterJson", sv."ColumnsJson", sv."SortJson",
           sv."IsShared", sv."IsDefault",
           (sv."UserId" = p_user_id) AS "IsOwner",
           sv."CreatedAt", sv."UpdatedAt"
    FROM   crm."SavedView" sv
    WHERE  sv."ViewId"    = p_view_id
      AND  sv."CompanyId" = p_company_id
      AND  (sv."UserId" = p_user_id OR sv."IsShared" = TRUE);
END;
$$;
-- +goose StatementEnd
