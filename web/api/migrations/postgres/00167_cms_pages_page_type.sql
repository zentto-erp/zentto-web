-- +goose Up
-- CMS Pages · extender cms."Page" con columna "PageType" para distinguir
-- páginas corporativas por propósito: about / contact / press / legal-terms
-- / legal-privacy / case-study / custom.
--
-- Contexto: Dogfooding del CMS Zentto en las 8 verticales. Cada vertical
-- necesita "Acerca", "Contacto", "Prensa" etc. editables desde /cms sin que
-- un cliente nuevo tenga que contratar desarrollo. El schema multi-tenant ya
-- soporta page per tenant (00159) — solo falta tipar el propósito.
--
-- Enum suave (VARCHAR) para tolerar extensiones futuras sin migración. La
-- constraint CHECK enumera los tipos canónicos actuales.

-- ── Columna PageType ──────────────────────────────────────────────────────────
ALTER TABLE cms."Page"
    ADD COLUMN IF NOT EXISTS "PageType" VARCHAR(30) NOT NULL DEFAULT 'custom';

ALTER TABLE cms."Page"
    DROP CONSTRAINT IF EXISTS ck_cms_page_page_type;
ALTER TABLE cms."Page"
    ADD CONSTRAINT ck_cms_page_page_type
    CHECK ("PageType" IN (
        'about',
        'contact',
        'press',
        'legal-terms',
        'legal-privacy',
        'case-study',
        'custom'
    ));

-- ── Índice para lookups por vertical + tipo (list corporate pages del hotel, etc.) ──
CREATE INDEX IF NOT EXISTS ix_cms_page_company_vertical_type
    ON cms."Page" ("CompanyId", "Vertical", "PageType");

-- ── usp_cms_page_list · filtro opcional por page_type ────────────────────────
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION usp_cms_page_list(
    p_company_id INTEGER DEFAULT 1,
    p_vertical   VARCHAR DEFAULT NULL,
    p_locale     VARCHAR DEFAULT 'es',
    p_status     VARCHAR DEFAULT 'published',
    p_page_type  VARCHAR DEFAULT NULL
)
RETURNS TABLE(
    "PageId"         INTEGER,
    "CompanyId"      INTEGER,
    "Slug"           VARCHAR,
    "Vertical"       VARCHAR,
    "PageType"       VARCHAR,
    "Locale"         VARCHAR,
    "Title"          VARCHAR,
    "Status"         VARCHAR,
    "PublishedAt"    TIMESTAMPTZ,
    "UpdatedAt"      TIMESTAMPTZ
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        p."PageId", p."CompanyId", p."Slug", p."Vertical", p."PageType", p."Locale",
        p."Title", p."Status", p."PublishedAt", p."UpdatedAt"
    FROM cms."Page" p
    WHERE p."CompanyId" = p_company_id
      AND (p_vertical IS NULL OR p."Vertical" = p_vertical)
      AND p."Locale" = p_locale
      AND (p_status IS NULL OR p."Status" = p_status)
      AND (p_page_type IS NULL OR p."PageType" = p_page_type)
    ORDER BY p."PageType", p."Slug";
END;
$$;
-- +goose StatementEnd

-- ── usp_cms_page_get · retorna PageType en el detalle ────────────────────────
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION usp_cms_page_get(
    p_slug       VARCHAR,
    p_vertical   VARCHAR DEFAULT 'corporate',
    p_locale     VARCHAR DEFAULT 'es',
    p_company_id INTEGER DEFAULT 1
)
RETURNS TABLE(
    "PageId"         INTEGER,
    "CompanyId"      INTEGER,
    "Slug"           VARCHAR,
    "Vertical"       VARCHAR,
    "PageType"       VARCHAR,
    "Locale"         VARCHAR,
    "Title"          VARCHAR,
    "Body"           TEXT,
    "Meta"           JSONB,
    "SeoTitle"       VARCHAR,
    "SeoDescription" VARCHAR,
    "Status"         VARCHAR,
    "PublishedAt"    TIMESTAMPTZ,
    "CreatedAt"      TIMESTAMPTZ,
    "UpdatedAt"      TIMESTAMPTZ
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        p."PageId", p."CompanyId", p."Slug", p."Vertical", p."PageType", p."Locale",
        p."Title", p."Body", p."Meta",
        p."SeoTitle", p."SeoDescription",
        p."Status", p."PublishedAt", p."CreatedAt", p."UpdatedAt"
    FROM cms."Page" p
    WHERE p."Slug" = p_slug
      AND p."Vertical" = p_vertical
      AND p."Locale" = p_locale
      AND p."CompanyId" = p_company_id
    LIMIT 1;
END;
$$;
-- +goose StatementEnd

-- ── usp_cms_page_upsert · acepta p_page_type ─────────────────────────────────
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION usp_cms_page_upsert(
    p_page_id         INTEGER DEFAULT NULL,
    p_company_id      INTEGER DEFAULT 1,
    p_slug            VARCHAR DEFAULT '',
    p_vertical        VARCHAR DEFAULT 'corporate',
    p_locale          VARCHAR DEFAULT 'es',
    p_title           VARCHAR DEFAULT '',
    p_body            TEXT    DEFAULT '',
    p_meta            JSONB   DEFAULT '{}'::JSONB,
    p_seo_title       VARCHAR DEFAULT '',
    p_seo_description VARCHAR DEFAULT '',
    p_page_type       VARCHAR DEFAULT 'custom'
)
RETURNS TABLE("ok" BOOLEAN, "mensaje" VARCHAR, "page_id" INTEGER)
LANGUAGE plpgsql AS $$
DECLARE
    v_id INTEGER;
BEGIN
    IF p_slug IS NULL OR p_slug = '' THEN
        RETURN QUERY SELECT FALSE, 'slug_required'::VARCHAR, 0;
        RETURN;
    END IF;
    IF p_title IS NULL OR p_title = '' THEN
        RETURN QUERY SELECT FALSE, 'title_required'::VARCHAR, 0;
        RETURN;
    END IF;
    IF p_page_type IS NULL OR p_page_type NOT IN (
        'about','contact','press','legal-terms','legal-privacy','case-study','custom'
    ) THEN
        RETURN QUERY SELECT FALSE, 'invalid_page_type'::VARCHAR, 0;
        RETURN;
    END IF;

    IF p_page_id IS NULL OR p_page_id = 0 THEN
        INSERT INTO cms."Page" (
            "CompanyId", "Slug", "Vertical", "Locale",
            "Title", "Body", "Meta",
            "SeoTitle", "SeoDescription",
            "PageType"
        ) VALUES (
            p_company_id, p_slug, p_vertical, p_locale,
            p_title, p_body, p_meta,
            p_seo_title, p_seo_description,
            p_page_type
        )
        RETURNING "PageId" INTO v_id;
        RETURN QUERY SELECT TRUE, 'page_created'::VARCHAR, v_id;
    ELSE
        UPDATE cms."Page" SET
            "Slug"           = p_slug,
            "Vertical"       = p_vertical,
            "Locale"         = p_locale,
            "Title"          = p_title,
            "Body"           = p_body,
            "Meta"           = p_meta,
            "SeoTitle"       = p_seo_title,
            "SeoDescription" = p_seo_description,
            "PageType"       = p_page_type,
            "UpdatedAt"      = NOW()
        WHERE "PageId" = p_page_id
          AND "CompanyId" = p_company_id
        RETURNING "PageId" INTO v_id;

        IF v_id IS NULL THEN
            RETURN QUERY SELECT FALSE, 'page_not_found'::VARCHAR, 0;
        ELSE
            RETURN QUERY SELECT TRUE, 'page_updated'::VARCHAR, v_id;
        END IF;
    END IF;
END;
$$;
-- +goose StatementEnd

-- ── Seeds opcionales desactivados ─────────────────────────────────────────────
-- Los seeds de pages por vertical (acerca/contacto/prensa) los inserta la UI
-- del CMS al editar (o un seed-script del deploy team), NO desde esta migración:
-- eso deja el CompanyId correcto del tenant inicial (tenant 1 = Zentto) sin
-- forzar contenido específico en sistemas que ya tengan rows.

-- +goose Down
-- Rollback: restaurar signatures previas sin p_page_type y drop columna.
-- El orden importa: primero recrear SPs (que dejarían de referenciar PageType),
-- luego quitar la columna.

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION usp_cms_page_list(
    p_company_id INTEGER DEFAULT 1,
    p_vertical   VARCHAR DEFAULT NULL,
    p_locale     VARCHAR DEFAULT 'es',
    p_status     VARCHAR DEFAULT 'published'
)
RETURNS TABLE(
    "PageId"         INTEGER,
    "CompanyId"      INTEGER,
    "Slug"           VARCHAR,
    "Vertical"       VARCHAR,
    "Locale"         VARCHAR,
    "Title"          VARCHAR,
    "Status"         VARCHAR,
    "PublishedAt"    TIMESTAMPTZ,
    "UpdatedAt"      TIMESTAMPTZ
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        p."PageId", p."CompanyId", p."Slug", p."Vertical", p."Locale",
        p."Title", p."Status", p."PublishedAt", p."UpdatedAt"
    FROM cms."Page" p
    WHERE p."CompanyId" = p_company_id
      AND (p_vertical IS NULL OR p."Vertical" = p_vertical)
      AND p."Locale" = p_locale
      AND (p_status IS NULL OR p."Status" = p_status)
    ORDER BY p."Slug";
END;
$$;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION usp_cms_page_get(
    p_slug       VARCHAR,
    p_vertical   VARCHAR DEFAULT 'corporate',
    p_locale     VARCHAR DEFAULT 'es',
    p_company_id INTEGER DEFAULT 1
)
RETURNS TABLE(
    "PageId"         INTEGER,
    "CompanyId"      INTEGER,
    "Slug"           VARCHAR,
    "Vertical"       VARCHAR,
    "Locale"         VARCHAR,
    "Title"          VARCHAR,
    "Body"           TEXT,
    "Meta"           JSONB,
    "SeoTitle"       VARCHAR,
    "SeoDescription" VARCHAR,
    "Status"         VARCHAR,
    "PublishedAt"    TIMESTAMPTZ,
    "CreatedAt"      TIMESTAMPTZ,
    "UpdatedAt"      TIMESTAMPTZ
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        p."PageId", p."CompanyId", p."Slug", p."Vertical", p."Locale",
        p."Title", p."Body", p."Meta",
        p."SeoTitle", p."SeoDescription",
        p."Status", p."PublishedAt", p."CreatedAt", p."UpdatedAt"
    FROM cms."Page" p
    WHERE p."Slug" = p_slug
      AND p."Vertical" = p_vertical
      AND p."Locale" = p_locale
      AND p."CompanyId" = p_company_id
    LIMIT 1;
END;
$$;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION usp_cms_page_upsert(
    p_page_id         INTEGER DEFAULT NULL,
    p_company_id      INTEGER DEFAULT 1,
    p_slug            VARCHAR DEFAULT '',
    p_vertical        VARCHAR DEFAULT 'corporate',
    p_locale          VARCHAR DEFAULT 'es',
    p_title           VARCHAR DEFAULT '',
    p_body            TEXT    DEFAULT '',
    p_meta            JSONB   DEFAULT '{}'::JSONB,
    p_seo_title       VARCHAR DEFAULT '',
    p_seo_description VARCHAR DEFAULT ''
)
RETURNS TABLE("ok" BOOLEAN, "mensaje" VARCHAR, "page_id" INTEGER)
LANGUAGE plpgsql AS $$
DECLARE
    v_id INTEGER;
BEGIN
    IF p_slug IS NULL OR p_slug = '' THEN
        RETURN QUERY SELECT FALSE, 'slug_required'::VARCHAR, 0;
        RETURN;
    END IF;
    IF p_title IS NULL OR p_title = '' THEN
        RETURN QUERY SELECT FALSE, 'title_required'::VARCHAR, 0;
        RETURN;
    END IF;

    IF p_page_id IS NULL OR p_page_id = 0 THEN
        INSERT INTO cms."Page" (
            "CompanyId", "Slug", "Vertical", "Locale",
            "Title", "Body", "Meta",
            "SeoTitle", "SeoDescription"
        ) VALUES (
            p_company_id, p_slug, p_vertical, p_locale,
            p_title, p_body, p_meta,
            p_seo_title, p_seo_description
        )
        RETURNING "PageId" INTO v_id;
        RETURN QUERY SELECT TRUE, 'page_created'::VARCHAR, v_id;
    ELSE
        UPDATE cms."Page" SET
            "Slug"           = p_slug,
            "Vertical"       = p_vertical,
            "Locale"         = p_locale,
            "Title"          = p_title,
            "Body"           = p_body,
            "Meta"           = p_meta,
            "SeoTitle"       = p_seo_title,
            "SeoDescription" = p_seo_description,
            "UpdatedAt"      = NOW()
        WHERE "PageId" = p_page_id
          AND "CompanyId" = p_company_id
        RETURNING "PageId" INTO v_id;

        IF v_id IS NULL THEN
            RETURN QUERY SELECT FALSE, 'page_not_found'::VARCHAR, 0;
        ELSE
            RETURN QUERY SELECT TRUE, 'page_updated'::VARCHAR, v_id;
        END IF;
    END IF;
END;
$$;
-- +goose StatementEnd

DROP INDEX IF EXISTS ix_cms_page_company_vertical_type;
ALTER TABLE cms."Page" DROP CONSTRAINT IF EXISTS ck_cms_page_page_type;
ALTER TABLE cms."Page" DROP COLUMN IF EXISTS "PageType";
