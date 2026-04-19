-- +goose Up
-- SPs CRM Contact (ADR-CRM-001): List/Detail/Upsert/Delete/Search/PromoteToCustomer.

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_crm_contact_list(
    p_company_id     INTEGER,
    p_crm_company_id BIGINT  DEFAULT NULL,
    p_search         VARCHAR DEFAULT NULL,
    p_is_active      BOOLEAN DEFAULT NULL,
    p_page           INTEGER DEFAULT 1,
    p_limit          INTEGER DEFAULT 50
) RETURNS TABLE(
    "ContactId"          BIGINT,
    "CrmCompanyId"       BIGINT,
    "CompanyName"        VARCHAR,
    "FirstName"          VARCHAR,
    "LastName"           VARCHAR,
    "Email"              VARCHAR,
    "Phone"              VARCHAR,
    "Mobile"             VARCHAR,
    "Title"              VARCHAR,
    "Department"         VARCHAR,
    "PromotedCustomerId" BIGINT,
    "IsActive"           BOOLEAN,
    "CreatedAt"          TIMESTAMP,
    "UpdatedAt"          TIMESTAMP,
    "TotalCount"         BIGINT
)
LANGUAGE plpgsql AS $$
DECLARE
    v_offset INTEGER := GREATEST(0, (COALESCE(p_page,1) - 1) * COALESCE(p_limit,50));
    v_total  BIGINT  := 0;
BEGIN
    SELECT COUNT(*) INTO v_total
      FROM crm."Contact" c
     WHERE c."CompanyId" = p_company_id
       AND c."IsDeleted" = FALSE
       AND (p_crm_company_id IS NULL OR c."CrmCompanyId" = p_crm_company_id)
       AND (p_is_active      IS NULL OR c."IsActive"     = p_is_active)
       AND (p_search IS NULL OR p_search = ''
            OR c."FirstName" ILIKE '%' || p_search || '%'
            OR COALESCE(c."LastName",'')::VARCHAR ILIKE '%' || p_search || '%'
            OR COALESCE(c."Email",'')::VARCHAR    ILIKE '%' || p_search || '%'
            OR COALESCE(c."Phone",'')::VARCHAR    ILIKE '%' || p_search || '%');

    RETURN QUERY
    SELECT c."ContactId",
           c."CrmCompanyId",
           cc."Name"::VARCHAR,
           c."FirstName"::VARCHAR,
           c."LastName"::VARCHAR,
           c."Email"::VARCHAR,
           c."Phone"::VARCHAR,
           c."Mobile"::VARCHAR,
           c."Title"::VARCHAR,
           c."Department"::VARCHAR,
           c."PromotedCustomerId",
           c."IsActive",
           c."CreatedAt",
           c."UpdatedAt",
           v_total
      FROM crm."Contact" c
      LEFT JOIN crm."Company" cc ON cc."CrmCompanyId" = c."CrmCompanyId"
     WHERE c."CompanyId" = p_company_id
       AND c."IsDeleted" = FALSE
       AND (p_crm_company_id IS NULL OR c."CrmCompanyId" = p_crm_company_id)
       AND (p_is_active      IS NULL OR c."IsActive"     = p_is_active)
       AND (p_search IS NULL OR p_search = ''
            OR c."FirstName" ILIKE '%' || p_search || '%'
            OR COALESCE(c."LastName",'')::VARCHAR ILIKE '%' || p_search || '%'
            OR COALESCE(c."Email",'')::VARCHAR    ILIKE '%' || p_search || '%'
            OR COALESCE(c."Phone",'')::VARCHAR    ILIKE '%' || p_search || '%')
     ORDER BY c."FirstName", c."LastName"
     LIMIT  COALESCE(p_limit, 50)
     OFFSET v_offset;
END;
$$;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_crm_contact_detail(
    p_company_id INTEGER,
    p_contact_id BIGINT
) RETURNS TABLE(
    "ContactId"          BIGINT,
    "CrmCompanyId"       BIGINT,
    "CompanyName"        VARCHAR,
    "FirstName"          VARCHAR,
    "LastName"           VARCHAR,
    "Email"              VARCHAR,
    "Phone"              VARCHAR,
    "Mobile"             VARCHAR,
    "Title"              VARCHAR,
    "Department"         VARCHAR,
    "LinkedIn"           VARCHAR,
    "Notes"              TEXT,
    "PromotedCustomerId" BIGINT,
    "IsActive"           BOOLEAN,
    "CreatedAt"          TIMESTAMP,
    "UpdatedAt"          TIMESTAMP
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT c."ContactId",
           c."CrmCompanyId",
           cc."Name"::VARCHAR,
           c."FirstName"::VARCHAR,
           c."LastName"::VARCHAR,
           c."Email"::VARCHAR,
           c."Phone"::VARCHAR,
           c."Mobile"::VARCHAR,
           c."Title"::VARCHAR,
           c."Department"::VARCHAR,
           c."LinkedIn"::VARCHAR,
           c."Notes",
           c."PromotedCustomerId",
           c."IsActive",
           c."CreatedAt",
           c."UpdatedAt"
      FROM crm."Contact" c
      LEFT JOIN crm."Company" cc ON cc."CrmCompanyId" = c."CrmCompanyId"
     WHERE c."CompanyId" = p_company_id
       AND c."ContactId" = p_contact_id
       AND c."IsDeleted" = FALSE;
END;
$$;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_crm_contact_upsert(
    p_company_id     INTEGER,
    p_contact_id     BIGINT  DEFAULT NULL,
    p_crm_company_id BIGINT  DEFAULT NULL,
    p_first_name     VARCHAR DEFAULT NULL,
    p_last_name      VARCHAR DEFAULT NULL,
    p_email          VARCHAR DEFAULT NULL,
    p_phone          VARCHAR DEFAULT NULL,
    p_mobile         VARCHAR DEFAULT NULL,
    p_title          VARCHAR DEFAULT NULL,
    p_department     VARCHAR DEFAULT NULL,
    p_linkedin       VARCHAR DEFAULT NULL,
    p_notes          TEXT    DEFAULT NULL,
    p_is_active      BOOLEAN DEFAULT TRUE,
    p_user_id        INTEGER DEFAULT NULL
) RETURNS TABLE("ok" BOOLEAN, "mensaje" VARCHAR, "id" BIGINT)
LANGUAGE plpgsql AS $$
DECLARE
    v_id BIGINT := p_contact_id;
BEGIN
    IF COALESCE(p_first_name,'')::VARCHAR = '' THEN
        RETURN QUERY SELECT FALSE, 'Nombre requerido'::VARCHAR, NULL::BIGINT;
        RETURN;
    END IF;

    IF p_crm_company_id IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM crm."Company"
         WHERE "CrmCompanyId" = p_crm_company_id
           AND "CompanyId"    = p_company_id
           AND "IsDeleted"    = FALSE
    ) THEN
        RETURN QUERY SELECT FALSE, 'CrmCompanyId invalido'::VARCHAR, NULL::BIGINT;
        RETURN;
    END IF;

    IF v_id IS NULL THEN
        INSERT INTO crm."Contact" (
            "CompanyId","CrmCompanyId","FirstName","LastName","Email","Phone","Mobile",
            "Title","Department","LinkedIn","Notes","IsActive",
            "CreatedByUserId","UpdatedByUserId"
        ) VALUES (
            p_company_id, p_crm_company_id, p_first_name, p_last_name, p_email, p_phone, p_mobile,
            p_title, p_department, p_linkedin, p_notes, COALESCE(p_is_active, TRUE),
            p_user_id, p_user_id
        )
        RETURNING "ContactId" INTO v_id;
    ELSE
        UPDATE crm."Contact" SET
            "CrmCompanyId"    = COALESCE(p_crm_company_id,"CrmCompanyId"),
            "FirstName"       = COALESCE(p_first_name,    "FirstName"),
            "LastName"        = COALESCE(p_last_name,     "LastName"),
            "Email"           = COALESCE(p_email,         "Email"),
            "Phone"           = COALESCE(p_phone,         "Phone"),
            "Mobile"          = COALESCE(p_mobile,        "Mobile"),
            "Title"           = COALESCE(p_title,         "Title"),
            "Department"      = COALESCE(p_department,    "Department"),
            "LinkedIn"        = COALESCE(p_linkedin,      "LinkedIn"),
            "Notes"           = COALESCE(p_notes,         "Notes"),
            "IsActive"        = COALESCE(p_is_active,     "IsActive"),
            "UpdatedByUserId" = p_user_id,
            "UpdatedAt"       = (now() AT TIME ZONE 'UTC'),
            "RowVer"          = "RowVer" + 1
          WHERE "ContactId"   = v_id
            AND "CompanyId"   = p_company_id
            AND "IsDeleted"   = FALSE;

        IF NOT FOUND THEN
            RETURN QUERY SELECT FALSE, 'Contacto no encontrado'::VARCHAR, NULL::BIGINT;
            RETURN;
        END IF;
    END IF;

    RETURN QUERY SELECT TRUE, 'OK'::VARCHAR, v_id;
END;
$$;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_crm_contact_delete(
    p_company_id INTEGER,
    p_contact_id BIGINT,
    p_user_id    INTEGER DEFAULT NULL
) RETURNS TABLE("ok" BOOLEAN, "mensaje" VARCHAR, "id" BIGINT)
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE crm."Contact" SET
        "IsDeleted"       = TRUE,
        "DeletedAt"       = (now() AT TIME ZONE 'UTC'),
        "DeletedByUserId" = p_user_id,
        "UpdatedByUserId" = p_user_id,
        "UpdatedAt"       = (now() AT TIME ZONE 'UTC')
      WHERE "ContactId" = p_contact_id
        AND "CompanyId" = p_company_id
        AND "IsDeleted" = FALSE;

    IF NOT FOUND THEN
        RETURN QUERY SELECT FALSE, 'Contacto no encontrado'::VARCHAR, NULL::BIGINT;
        RETURN;
    END IF;

    RETURN QUERY SELECT TRUE, 'OK'::VARCHAR, p_contact_id;
END;
$$;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_crm_contact_search(
    p_company_id INTEGER,
    p_term       VARCHAR,
    p_limit      INTEGER DEFAULT 20
) RETURNS TABLE(
    "ContactId"   BIGINT,
    "FirstName"   VARCHAR,
    "LastName"    VARCHAR,
    "Email"       VARCHAR,
    "Phone"       VARCHAR,
    "CompanyName" VARCHAR
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT c."ContactId",
           c."FirstName"::VARCHAR,
           c."LastName"::VARCHAR,
           c."Email"::VARCHAR,
           c."Phone"::VARCHAR,
           cc."Name"::VARCHAR
      FROM crm."Contact" c
      LEFT JOIN crm."Company" cc ON cc."CrmCompanyId" = c."CrmCompanyId"
     WHERE c."CompanyId" = p_company_id
       AND c."IsDeleted" = FALSE
       AND c."IsActive"  = TRUE
       AND (p_term IS NULL OR p_term = ''
            OR c."FirstName" ILIKE '%' || p_term || '%'
            OR COALESCE(c."LastName",'')::VARCHAR ILIKE '%' || p_term || '%'
            OR COALESCE(c."Email",'')::VARCHAR    ILIKE '%' || p_term || '%')
     ORDER BY c."FirstName", c."LastName"
     LIMIT COALESCE(p_limit, 20);
END;
$$;
-- +goose StatementEnd

-- ─────────────────────────────────────────────────────────────────────────────
-- usp_crm_contact_promote_to_customer
-- Crea (o reusa) master."Customer" a partir de un crm.Contact y lo marca como promovido.
-- ─────────────────────────────────────────────────────────────────────────────

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_crm_contact_promote_to_customer(
    p_company_id   INTEGER,
    p_contact_id   BIGINT,
    p_customer_code VARCHAR DEFAULT NULL,
    p_user_id      INTEGER DEFAULT NULL
) RETURNS TABLE("ok" BOOLEAN, "mensaje" VARCHAR, "id" BIGINT)
LANGUAGE plpgsql AS $$
DECLARE
    v_customer_id BIGINT;
    v_row         crm."Contact"%ROWTYPE;
    v_full_name   VARCHAR(200);
    v_code        VARCHAR(24);
BEGIN
    SELECT * INTO v_row
      FROM crm."Contact"
     WHERE "ContactId" = p_contact_id
       AND "CompanyId" = p_company_id
       AND "IsDeleted" = FALSE;

    IF NOT FOUND THEN
        RETURN QUERY SELECT FALSE, 'Contacto no encontrado'::VARCHAR, NULL::BIGINT;
        RETURN;
    END IF;

    IF v_row."PromotedCustomerId" IS NOT NULL THEN
        RETURN QUERY SELECT TRUE, 'Contacto ya promovido'::VARCHAR, v_row."PromotedCustomerId";
        RETURN;
    END IF;

    v_full_name := TRIM(v_row."FirstName" || ' ' || COALESCE(v_row."LastName",''));
    v_code      := COALESCE(p_customer_code, 'CRM-' || v_row."ContactId"::VARCHAR);

    -- Reusa customer existente si ya hay email/phone match por tenant
    SELECT "CustomerId" INTO v_customer_id
      FROM master."Customer"
     WHERE "CompanyId" = p_company_id
       AND "IsDeleted" = FALSE
       AND (
            (v_row."Email" IS NOT NULL AND "Email" = v_row."Email")
         OR (v_row."Phone" IS NOT NULL AND "Phone" = v_row."Phone")
       )
     LIMIT 1;

    IF v_customer_id IS NULL THEN
        INSERT INTO master."Customer" (
            "CustomerId","CompanyId","CustomerCode","CustomerName",
            "Email","Phone","CreatedByUserId","UpdatedByUserId"
        ) VALUES (
            COALESCE((SELECT MAX("CustomerId") + 1 FROM master."Customer"), 1),
            p_company_id, v_code, v_full_name,
            v_row."Email", v_row."Phone", p_user_id, p_user_id
        )
        RETURNING "CustomerId" INTO v_customer_id;
    END IF;

    UPDATE crm."Contact"
       SET "PromotedCustomerId" = v_customer_id,
           "UpdatedByUserId"    = p_user_id,
           "UpdatedAt"          = (now() AT TIME ZONE 'UTC')
     WHERE "ContactId"   = p_contact_id
       AND "CompanyId"   = p_company_id;

    RETURN QUERY SELECT TRUE, 'OK'::VARCHAR, v_customer_id;
END;
$$;
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
DROP FUNCTION IF EXISTS public.usp_crm_contact_promote_to_customer(INTEGER, BIGINT, VARCHAR, INTEGER);
DROP FUNCTION IF EXISTS public.usp_crm_contact_search(INTEGER, VARCHAR, INTEGER);
DROP FUNCTION IF EXISTS public.usp_crm_contact_delete(INTEGER, BIGINT, INTEGER);
DROP FUNCTION IF EXISTS public.usp_crm_contact_upsert(
    INTEGER, BIGINT, BIGINT, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR,
    VARCHAR, VARCHAR, TEXT, BOOLEAN, INTEGER);
DROP FUNCTION IF EXISTS public.usp_crm_contact_detail(INTEGER, BIGINT);
DROP FUNCTION IF EXISTS public.usp_crm_contact_list(INTEGER, BIGINT, VARCHAR, BOOLEAN, INTEGER, INTEGER);
-- +goose StatementEnd
