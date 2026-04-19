-- +goose Up
-- SPs CRM Company — List / Detail / Upsert / Delete / Search (ADR-CRM-001).
-- Convención:
--   * Primer parámetro siempre p_company_id (tenant).
--   * Lists retornan TotalCount BIGINT.
--   * Writes retornan ok BOOLEAN + mensaje VARCHAR + id BIGINT.

-- ─────────────────────────────────────────────────────────────────────────────
-- usp_crm_company_list
-- ─────────────────────────────────────────────────────────────────────────────

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_crm_company_list(
    p_company_id INTEGER,
    p_search     VARCHAR DEFAULT NULL,
    p_industry   VARCHAR DEFAULT NULL,
    p_is_active  BOOLEAN DEFAULT NULL,
    p_page       INTEGER DEFAULT 1,
    p_limit      INTEGER DEFAULT 50
) RETURNS TABLE(
    "CrmCompanyId" BIGINT,
    "Name"         VARCHAR,
    "LegalName"    VARCHAR,
    "TaxId"        VARCHAR,
    "Industry"     VARCHAR,
    "Size"         VARCHAR,
    "Website"      VARCHAR,
    "Phone"        VARCHAR,
    "Email"        VARCHAR,
    "IsActive"     BOOLEAN,
    "CreatedAt"    TIMESTAMP,
    "UpdatedAt"    TIMESTAMP,
    "TotalCount"   BIGINT
)
LANGUAGE plpgsql AS $$
DECLARE
    v_offset INTEGER := GREATEST(0, (COALESCE(p_page,1) - 1) * COALESCE(p_limit,50));
    v_total  BIGINT  := 0;
BEGIN
    SELECT COUNT(*) INTO v_total
      FROM crm."Company" c
     WHERE c."CompanyId" = p_company_id
       AND c."IsDeleted" = FALSE
       AND (p_search IS NULL OR p_search = ''
            OR c."Name" ILIKE '%' || p_search || '%'
            OR COALESCE(c."LegalName",'')::VARCHAR ILIKE '%' || p_search || '%'
            OR COALESCE(c."TaxId",'')::VARCHAR     ILIKE '%' || p_search || '%'
            OR COALESCE(c."Email",'')::VARCHAR     ILIKE '%' || p_search || '%')
       AND (p_industry  IS NULL OR c."Industry" = p_industry)
       AND (p_is_active IS NULL OR c."IsActive" = p_is_active);

    RETURN QUERY
    SELECT c."CrmCompanyId",
           c."Name"::VARCHAR,
           c."LegalName"::VARCHAR,
           c."TaxId"::VARCHAR,
           c."Industry"::VARCHAR,
           c."Size"::VARCHAR,
           c."Website"::VARCHAR,
           c."Phone"::VARCHAR,
           c."Email"::VARCHAR,
           c."IsActive",
           c."CreatedAt",
           c."UpdatedAt",
           v_total
      FROM crm."Company" c
     WHERE c."CompanyId" = p_company_id
       AND c."IsDeleted" = FALSE
       AND (p_search IS NULL OR p_search = ''
            OR c."Name" ILIKE '%' || p_search || '%'
            OR COALESCE(c."LegalName",'')::VARCHAR ILIKE '%' || p_search || '%'
            OR COALESCE(c."TaxId",'')::VARCHAR     ILIKE '%' || p_search || '%'
            OR COALESCE(c."Email",'')::VARCHAR     ILIKE '%' || p_search || '%')
       AND (p_industry  IS NULL OR c."Industry" = p_industry)
       AND (p_is_active IS NULL OR c."IsActive" = p_is_active)
     ORDER BY c."Name" ASC
     LIMIT  COALESCE(p_limit,50)
     OFFSET v_offset;
END;
$$;
-- +goose StatementEnd

-- ─────────────────────────────────────────────────────────────────────────────
-- usp_crm_company_detail
-- ─────────────────────────────────────────────────────────────────────────────

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_crm_company_detail(
    p_company_id     INTEGER,
    p_crm_company_id BIGINT
) RETURNS TABLE(
    "CrmCompanyId"    BIGINT,
    "Name"            VARCHAR,
    "LegalName"       VARCHAR,
    "TaxId"           VARCHAR,
    "Industry"        VARCHAR,
    "Size"            VARCHAR,
    "Website"         VARCHAR,
    "Phone"           VARCHAR,
    "Email"           VARCHAR,
    "BillingAddress"  JSONB,
    "ShippingAddress" JSONB,
    "Notes"           TEXT,
    "IsActive"        BOOLEAN,
    "CreatedAt"       TIMESTAMP,
    "UpdatedAt"       TIMESTAMP
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT c."CrmCompanyId",
           c."Name"::VARCHAR,
           c."LegalName"::VARCHAR,
           c."TaxId"::VARCHAR,
           c."Industry"::VARCHAR,
           c."Size"::VARCHAR,
           c."Website"::VARCHAR,
           c."Phone"::VARCHAR,
           c."Email"::VARCHAR,
           c."BillingAddress",
           c."ShippingAddress",
           c."Notes",
           c."IsActive",
           c."CreatedAt",
           c."UpdatedAt"
      FROM crm."Company" c
     WHERE c."CompanyId"    = p_company_id
       AND c."CrmCompanyId" = p_crm_company_id
       AND c."IsDeleted"    = FALSE;
END;
$$;
-- +goose StatementEnd

-- ─────────────────────────────────────────────────────────────────────────────
-- usp_crm_company_upsert
-- ─────────────────────────────────────────────────────────────────────────────

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_crm_company_upsert(
    p_company_id       INTEGER,
    p_crm_company_id   BIGINT   DEFAULT NULL,
    p_name             VARCHAR  DEFAULT NULL,
    p_legal_name       VARCHAR  DEFAULT NULL,
    p_tax_id           VARCHAR  DEFAULT NULL,
    p_industry         VARCHAR  DEFAULT NULL,
    p_size             VARCHAR  DEFAULT NULL,
    p_website          VARCHAR  DEFAULT NULL,
    p_phone            VARCHAR  DEFAULT NULL,
    p_email            VARCHAR  DEFAULT NULL,
    p_billing_address  JSONB    DEFAULT NULL,
    p_shipping_address JSONB    DEFAULT NULL,
    p_notes            TEXT     DEFAULT NULL,
    p_is_active        BOOLEAN  DEFAULT TRUE,
    p_user_id          INTEGER  DEFAULT NULL
) RETURNS TABLE(
    "ok"       BOOLEAN,
    "mensaje"  VARCHAR,
    "id"       BIGINT
)
LANGUAGE plpgsql AS $$
DECLARE
    v_id BIGINT := p_crm_company_id;
BEGIN
    IF COALESCE(p_name,'')::VARCHAR = '' THEN
        RETURN QUERY SELECT FALSE, 'Nombre requerido'::VARCHAR, NULL::BIGINT;
        RETURN;
    END IF;

    IF v_id IS NULL THEN
        INSERT INTO crm."Company" (
            "CompanyId","Name","LegalName","TaxId","Industry","Size","Website",
            "Phone","Email","BillingAddress","ShippingAddress","Notes",
            "IsActive","CreatedByUserId","UpdatedByUserId"
        ) VALUES (
            p_company_id, p_name, p_legal_name, p_tax_id, p_industry, p_size, p_website,
            p_phone, p_email, p_billing_address, p_shipping_address, p_notes,
            COALESCE(p_is_active, TRUE), p_user_id, p_user_id
        )
        RETURNING "CrmCompanyId" INTO v_id;
    ELSE
        UPDATE crm."Company" SET
            "Name"            = COALESCE(p_name,            "Name"),
            "LegalName"       = COALESCE(p_legal_name,      "LegalName"),
            "TaxId"           = COALESCE(p_tax_id,          "TaxId"),
            "Industry"        = COALESCE(p_industry,        "Industry"),
            "Size"            = COALESCE(p_size,            "Size"),
            "Website"         = COALESCE(p_website,         "Website"),
            "Phone"           = COALESCE(p_phone,           "Phone"),
            "Email"           = COALESCE(p_email,           "Email"),
            "BillingAddress"  = COALESCE(p_billing_address, "BillingAddress"),
            "ShippingAddress" = COALESCE(p_shipping_address,"ShippingAddress"),
            "Notes"           = COALESCE(p_notes,           "Notes"),
            "IsActive"        = COALESCE(p_is_active,       "IsActive"),
            "UpdatedByUserId" = p_user_id,
            "UpdatedAt"       = (now() AT TIME ZONE 'UTC'),
            "RowVer"          = "RowVer" + 1
          WHERE "CrmCompanyId" = v_id
            AND "CompanyId"    = p_company_id
            AND "IsDeleted"    = FALSE;

        IF NOT FOUND THEN
            RETURN QUERY SELECT FALSE, 'Empresa no encontrada'::VARCHAR, NULL::BIGINT;
            RETURN;
        END IF;
    END IF;

    RETURN QUERY SELECT TRUE, 'OK'::VARCHAR, v_id;
END;
$$;
-- +goose StatementEnd

-- ─────────────────────────────────────────────────────────────────────────────
-- usp_crm_company_delete (soft delete)
-- ─────────────────────────────────────────────────────────────────────────────

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_crm_company_delete(
    p_company_id     INTEGER,
    p_crm_company_id BIGINT,
    p_user_id        INTEGER DEFAULT NULL
) RETURNS TABLE("ok" BOOLEAN, "mensaje" VARCHAR, "id" BIGINT)
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE crm."Company" SET
        "IsDeleted"       = TRUE,
        "DeletedAt"       = (now() AT TIME ZONE 'UTC'),
        "DeletedByUserId" = p_user_id,
        "UpdatedByUserId" = p_user_id,
        "UpdatedAt"       = (now() AT TIME ZONE 'UTC')
      WHERE "CrmCompanyId" = p_crm_company_id
        AND "CompanyId"    = p_company_id
        AND "IsDeleted"    = FALSE;

    IF NOT FOUND THEN
        RETURN QUERY SELECT FALSE, 'Empresa no encontrada'::VARCHAR, NULL::BIGINT;
        RETURN;
    END IF;

    RETURN QUERY SELECT TRUE, 'OK'::VARCHAR, p_crm_company_id;
END;
$$;
-- +goose StatementEnd

-- ─────────────────────────────────────────────────────────────────────────────
-- usp_crm_company_search (lookup compacto)
-- ─────────────────────────────────────────────────────────────────────────────

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_crm_company_search(
    p_company_id INTEGER,
    p_term       VARCHAR,
    p_limit      INTEGER DEFAULT 20
) RETURNS TABLE(
    "CrmCompanyId" BIGINT,
    "Name"         VARCHAR,
    "TaxId"        VARCHAR,
    "Industry"     VARCHAR
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT c."CrmCompanyId",
           c."Name"::VARCHAR,
           c."TaxId"::VARCHAR,
           c."Industry"::VARCHAR
      FROM crm."Company" c
     WHERE c."CompanyId" = p_company_id
       AND c."IsDeleted" = FALSE
       AND c."IsActive"  = TRUE
       AND (p_term IS NULL OR p_term = ''
            OR c."Name" ILIKE '%' || p_term || '%'
            OR COALESCE(c."TaxId",'')::VARCHAR ILIKE '%' || p_term || '%')
     ORDER BY c."Name"
     LIMIT COALESCE(p_limit, 20);
END;
$$;
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
DROP FUNCTION IF EXISTS public.usp_crm_company_search(INTEGER, VARCHAR, INTEGER);
DROP FUNCTION IF EXISTS public.usp_crm_company_delete(INTEGER, BIGINT, INTEGER);
DROP FUNCTION IF EXISTS public.usp_crm_company_upsert(
    INTEGER, BIGINT, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR,
    VARCHAR, VARCHAR, JSONB, JSONB, TEXT, BOOLEAN, INTEGER);
DROP FUNCTION IF EXISTS public.usp_crm_company_detail(INTEGER, BIGINT);
DROP FUNCTION IF EXISTS public.usp_crm_company_list(INTEGER, VARCHAR, VARCHAR, BOOLEAN, INTEGER, INTEGER);
-- +goose StatementEnd
