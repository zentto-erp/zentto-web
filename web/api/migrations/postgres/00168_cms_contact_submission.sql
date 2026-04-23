-- +goose Up
-- CMS Contact Submissions · persiste mensajes enviados desde el
-- ContactFormAdapter del `@zentto/landing-kit` en las páginas `/contacto` de
-- las 8 verticales.
--
-- Scope multi-tenant vía CompanyId. Cada submission es leída solo por el
-- tenant dueño (ej. Zentto ve los submissions enviados a hola@zentto.net,
-- futuros clientes verán los suyos cuando adopten el CMS).

-- ── Tabla ────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS cms."ContactSubmission" (
    "ContactSubmissionId" SERIAL PRIMARY KEY,
    "CompanyId"           INTEGER      NOT NULL,
    "Vertical"            VARCHAR(50)  NOT NULL,
    "Slug"                VARCHAR(100) NOT NULL DEFAULT 'contacto',
    "Name"                VARCHAR(200) NOT NULL,
    "Email"               VARCHAR(200) NOT NULL,
    "Subject"             VARCHAR(200) NOT NULL DEFAULT '',
    "Message"             TEXT         NOT NULL,
    "IpAddress"           VARCHAR(45)  NULL,
    "UserAgent"           TEXT         NULL,
    "Status"              VARCHAR(20)  NOT NULL DEFAULT 'pending',
    "CreatedAt"           TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS ix_cms_contactsubmission_company_created
    ON cms."ContactSubmission" ("CompanyId", "CreatedAt" DESC);

CREATE INDEX IF NOT EXISTS ix_cms_contactsubmission_vertical_status
    ON cms."ContactSubmission" ("Vertical", "Status");

-- ── usp_cms_contact_submit · INSERT desde endpoint público ───────────────────
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION usp_cms_contact_submit(
    p_company_id  INTEGER DEFAULT 1,
    p_vertical    VARCHAR DEFAULT 'corporate',
    p_slug        VARCHAR DEFAULT 'contacto',
    p_name        VARCHAR DEFAULT '',
    p_email       VARCHAR DEFAULT '',
    p_subject     VARCHAR DEFAULT '',
    p_message     TEXT    DEFAULT '',
    p_ip_address  VARCHAR DEFAULT NULL,
    p_user_agent  TEXT    DEFAULT NULL
)
RETURNS TABLE("ok" BOOLEAN, "mensaje" VARCHAR, "submission_id" INTEGER)
LANGUAGE plpgsql AS $$
DECLARE
    v_id INTEGER;
BEGIN
    -- Validaciones mínimas (el router ya valida con Zod pero defendemos el SP)
    IF p_name IS NULL OR LENGTH(TRIM(p_name)) = 0 THEN
        RETURN QUERY SELECT FALSE, 'name_required'::VARCHAR, 0;
        RETURN;
    END IF;
    IF p_email IS NULL OR LENGTH(TRIM(p_email)) = 0 OR POSITION('@' IN p_email) = 0 THEN
        RETURN QUERY SELECT FALSE, 'email_invalid'::VARCHAR, 0;
        RETURN;
    END IF;
    IF p_message IS NULL OR LENGTH(TRIM(p_message)) = 0 THEN
        RETURN QUERY SELECT FALSE, 'message_required'::VARCHAR, 0;
        RETURN;
    END IF;

    INSERT INTO cms."ContactSubmission" (
        "CompanyId", "Vertical", "Slug",
        "Name", "Email", "Subject", "Message",
        "IpAddress", "UserAgent"
    ) VALUES (
        p_company_id, p_vertical, p_slug,
        TRIM(p_name), LOWER(TRIM(p_email)), COALESCE(p_subject, ''), p_message,
        p_ip_address, p_user_agent
    )
    RETURNING "ContactSubmissionId" INTO v_id;

    RETURN QUERY SELECT TRUE, 'submission_created'::VARCHAR, v_id;
END;
$$;
-- +goose StatementEnd

-- ── usp_cms_contact_list · admin, con filtros ────────────────────────────────
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION usp_cms_contact_list(
    p_company_id INTEGER DEFAULT 1,
    p_vertical   VARCHAR DEFAULT NULL,
    p_status     VARCHAR DEFAULT NULL,
    p_limit      INTEGER DEFAULT 50,
    p_offset     INTEGER DEFAULT 0
)
RETURNS TABLE(
    "ContactSubmissionId" INTEGER,
    "CompanyId"           INTEGER,
    "Vertical"            VARCHAR,
    "Slug"                VARCHAR,
    "Name"                VARCHAR,
    "Email"               VARCHAR,
    "Subject"             VARCHAR,
    "Message"             TEXT,
    "Status"              VARCHAR,
    "CreatedAt"           TIMESTAMPTZ,
    "TotalCount"          BIGINT
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    WITH filtered AS (
        SELECT s.*
        FROM cms."ContactSubmission" s
        WHERE s."CompanyId" = p_company_id
          AND (p_vertical IS NULL OR s."Vertical" = p_vertical)
          AND (p_status IS NULL OR s."Status" = p_status)
    ),
    total AS (SELECT COUNT(*) AS c FROM filtered)
    SELECT
        f."ContactSubmissionId", f."CompanyId", f."Vertical", f."Slug",
        f."Name", f."Email", f."Subject", f."Message",
        f."Status", f."CreatedAt",
        t.c
    FROM filtered f CROSS JOIN total t
    ORDER BY f."CreatedAt" DESC
    LIMIT p_limit OFFSET p_offset;
END;
$$;
-- +goose StatementEnd

-- +goose Down
DROP FUNCTION IF EXISTS usp_cms_contact_list(INTEGER, VARCHAR, VARCHAR, INTEGER, INTEGER);
DROP FUNCTION IF EXISTS usp_cms_contact_submit(INTEGER, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, TEXT, VARCHAR, TEXT);
DROP INDEX IF EXISTS ix_cms_contactsubmission_vertical_status;
DROP INDEX IF EXISTS ix_cms_contactsubmission_company_created;
DROP TABLE IF EXISTS cms."ContactSubmission";
