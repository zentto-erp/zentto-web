-- +goose Up
-- CMS Foundation: blog + páginas institucionales (ADR-CMS-001).
-- Crea schema cms con tablas Post + Page y 10 SPs (list/get públicos + CRUD privado + publish).

-- ── Schema ─────────────────────────────────────────────────────────────────────
CREATE SCHEMA IF NOT EXISTS cms;

-- ── Tabla Post ────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS cms."Post" (
    "PostId"         SERIAL        PRIMARY KEY,
    "CompanyId"      INTEGER       NOT NULL DEFAULT 1,
    "Slug"           VARCHAR(200)  NOT NULL,
    "Vertical"       VARCHAR(50)   NOT NULL,
    "Category"       VARCHAR(50)   NOT NULL,
    "Locale"         VARCHAR(10)   NOT NULL DEFAULT 'es',
    "Title"          VARCHAR(300)  NOT NULL,
    "Excerpt"        VARCHAR(500)  NOT NULL DEFAULT ''::VARCHAR,
    "Body"           TEXT          NOT NULL,
    "CoverUrl"       VARCHAR(500)  NOT NULL DEFAULT ''::VARCHAR,
    "AuthorName"     VARCHAR(200)  NOT NULL DEFAULT ''::VARCHAR,
    "AuthorSlug"     VARCHAR(100)  NOT NULL DEFAULT ''::VARCHAR,
    "AuthorAvatar"   VARCHAR(500)  NOT NULL DEFAULT ''::VARCHAR,
    "Tags"           VARCHAR(500)  NOT NULL DEFAULT ''::VARCHAR,
    "ReadingMin"     INTEGER       NOT NULL DEFAULT 5,
    "SeoTitle"       VARCHAR(300)  NOT NULL DEFAULT ''::VARCHAR,
    "SeoDescription" VARCHAR(500)  NOT NULL DEFAULT ''::VARCHAR,
    "SeoImageUrl"    VARCHAR(500)  NOT NULL DEFAULT ''::VARCHAR,
    "Status"         VARCHAR(20)   NOT NULL DEFAULT 'draft'::VARCHAR,
    "PublishedAt"    TIMESTAMPTZ,
    "CreatedAt"      TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    "UpdatedAt"      TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_cms_post_slug_locale UNIQUE ("Slug", "Locale"),
    CONSTRAINT chk_cms_post_status CHECK ("Status" IN ('draft','published','archived'))
);

CREATE INDEX IF NOT EXISTS idx_cms_post_vertical        ON cms."Post" ("Vertical");
CREATE INDEX IF NOT EXISTS idx_cms_post_category        ON cms."Post" ("Category");
CREATE INDEX IF NOT EXISTS idx_cms_post_status          ON cms."Post" ("Status");
CREATE INDEX IF NOT EXISTS idx_cms_post_published_at    ON cms."Post" ("PublishedAt" DESC);
CREATE INDEX IF NOT EXISTS idx_cms_post_company         ON cms."Post" ("CompanyId");

-- ── Tabla Page ────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS cms."Page" (
    "PageId"         SERIAL        PRIMARY KEY,
    "CompanyId"      INTEGER       NOT NULL DEFAULT 1,
    "Slug"           VARCHAR(100)  NOT NULL,
    "Vertical"       VARCHAR(50)   NOT NULL DEFAULT 'corporate'::VARCHAR,
    "Locale"         VARCHAR(10)   NOT NULL DEFAULT 'es',
    "Title"          VARCHAR(300)  NOT NULL,
    "Body"           TEXT          NOT NULL,
    "Meta"           JSONB         NOT NULL DEFAULT '{}'::JSONB,
    "SeoTitle"       VARCHAR(300)  NOT NULL DEFAULT ''::VARCHAR,
    "SeoDescription" VARCHAR(500)  NOT NULL DEFAULT ''::VARCHAR,
    "Status"         VARCHAR(20)   NOT NULL DEFAULT 'draft'::VARCHAR,
    "PublishedAt"    TIMESTAMPTZ,
    "CreatedAt"      TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    "UpdatedAt"      TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_cms_page_slug_vertical_locale UNIQUE ("Slug", "Vertical", "Locale"),
    CONSTRAINT chk_cms_page_status CHECK ("Status" IN ('draft','published','archived'))
);

CREATE INDEX IF NOT EXISTS idx_cms_page_vertical ON cms."Page" ("Vertical");
CREATE INDEX IF NOT EXISTS idx_cms_page_status   ON cms."Page" ("Status");

-- ── SP: usp_cms_post_list ─────────────────────────────────────────────────────
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION usp_cms_post_list(
    p_vertical   VARCHAR DEFAULT NULL,
    p_category   VARCHAR DEFAULT NULL,
    p_locale     VARCHAR DEFAULT 'es',
    p_status     VARCHAR DEFAULT 'published',
    p_limit      INTEGER DEFAULT 20,
    p_offset     INTEGER DEFAULT 0
)
RETURNS TABLE(
    "PostId"         INTEGER,
    "CompanyId"      INTEGER,
    "Slug"           VARCHAR,
    "Vertical"       VARCHAR,
    "Category"       VARCHAR,
    "Locale"         VARCHAR,
    "Title"          VARCHAR,
    "Excerpt"        VARCHAR,
    "CoverUrl"       VARCHAR,
    "AuthorName"     VARCHAR,
    "AuthorSlug"     VARCHAR,
    "AuthorAvatar"   VARCHAR,
    "Tags"           VARCHAR,
    "ReadingMin"     INTEGER,
    "Status"         VARCHAR,
    "PublishedAt"    TIMESTAMPTZ,
    "TotalCount"     BIGINT
)
LANGUAGE plpgsql AS $$
DECLARE
    v_total BIGINT;
BEGIN
    SELECT COUNT(*) INTO v_total
    FROM cms."Post" p
    WHERE (p_vertical IS NULL OR p."Vertical" = p_vertical)
      AND (p_category IS NULL OR p."Category" = p_category)
      AND p."Locale" = p_locale
      AND (p_status IS NULL OR p."Status" = p_status);

    RETURN QUERY
    SELECT
        p."PostId", p."CompanyId", p."Slug", p."Vertical", p."Category", p."Locale",
        p."Title", p."Excerpt", p."CoverUrl",
        p."AuthorName", p."AuthorSlug", p."AuthorAvatar",
        p."Tags", p."ReadingMin", p."Status", p."PublishedAt",
        v_total AS "TotalCount"
    FROM cms."Post" p
    WHERE (p_vertical IS NULL OR p."Vertical" = p_vertical)
      AND (p_category IS NULL OR p."Category" = p_category)
      AND p."Locale" = p_locale
      AND (p_status IS NULL OR p."Status" = p_status)
    ORDER BY COALESCE(p."PublishedAt", p."CreatedAt") DESC, p."PostId" DESC
    LIMIT p_limit OFFSET p_offset;
END;
$$;
-- +goose StatementEnd

-- ── SP: usp_cms_post_get ──────────────────────────────────────────────────────
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION usp_cms_post_get(
    p_slug   VARCHAR,
    p_locale VARCHAR DEFAULT 'es'
)
RETURNS TABLE(
    "PostId"         INTEGER,
    "CompanyId"      INTEGER,
    "Slug"           VARCHAR,
    "Vertical"       VARCHAR,
    "Category"       VARCHAR,
    "Locale"         VARCHAR,
    "Title"          VARCHAR,
    "Excerpt"        VARCHAR,
    "Body"           TEXT,
    "CoverUrl"       VARCHAR,
    "AuthorName"     VARCHAR,
    "AuthorSlug"     VARCHAR,
    "AuthorAvatar"   VARCHAR,
    "Tags"           VARCHAR,
    "ReadingMin"     INTEGER,
    "SeoTitle"       VARCHAR,
    "SeoDescription" VARCHAR,
    "SeoImageUrl"    VARCHAR,
    "Status"         VARCHAR,
    "PublishedAt"    TIMESTAMPTZ,
    "CreatedAt"      TIMESTAMPTZ,
    "UpdatedAt"      TIMESTAMPTZ
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        p."PostId", p."CompanyId", p."Slug", p."Vertical", p."Category", p."Locale",
        p."Title", p."Excerpt", p."Body", p."CoverUrl",
        p."AuthorName", p."AuthorSlug", p."AuthorAvatar",
        p."Tags", p."ReadingMin",
        p."SeoTitle", p."SeoDescription", p."SeoImageUrl",
        p."Status", p."PublishedAt", p."CreatedAt", p."UpdatedAt"
    FROM cms."Post" p
    WHERE p."Slug" = p_slug
      AND p."Locale" = p_locale
    LIMIT 1;
END;
$$;
-- +goose StatementEnd

-- ── SP: usp_cms_post_upsert ───────────────────────────────────────────────────
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION usp_cms_post_upsert(
    p_post_id         INTEGER DEFAULT NULL,
    p_company_id      INTEGER DEFAULT 1,
    p_slug            VARCHAR DEFAULT '',
    p_vertical        VARCHAR DEFAULT 'corporate',
    p_category        VARCHAR DEFAULT 'producto',
    p_locale          VARCHAR DEFAULT 'es',
    p_title           VARCHAR DEFAULT '',
    p_excerpt         VARCHAR DEFAULT '',
    p_body            TEXT    DEFAULT '',
    p_cover_url       VARCHAR DEFAULT '',
    p_author_name     VARCHAR DEFAULT '',
    p_author_slug     VARCHAR DEFAULT '',
    p_author_avatar   VARCHAR DEFAULT '',
    p_tags            VARCHAR DEFAULT '',
    p_reading_min     INTEGER DEFAULT 5,
    p_seo_title       VARCHAR DEFAULT '',
    p_seo_description VARCHAR DEFAULT '',
    p_seo_image_url   VARCHAR DEFAULT ''
)
RETURNS TABLE("ok" BOOLEAN, "mensaje" VARCHAR, "post_id" INTEGER)
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

    IF p_post_id IS NULL OR p_post_id = 0 THEN
        INSERT INTO cms."Post" (
            "CompanyId", "Slug", "Vertical", "Category", "Locale",
            "Title", "Excerpt", "Body", "CoverUrl",
            "AuthorName", "AuthorSlug", "AuthorAvatar",
            "Tags", "ReadingMin",
            "SeoTitle", "SeoDescription", "SeoImageUrl"
        ) VALUES (
            p_company_id, p_slug, p_vertical, p_category, p_locale,
            p_title, p_excerpt, p_body, p_cover_url,
            p_author_name, p_author_slug, p_author_avatar,
            p_tags, p_reading_min,
            p_seo_title, p_seo_description, p_seo_image_url
        )
        RETURNING "PostId" INTO v_id;
        RETURN QUERY SELECT TRUE, 'post_created'::VARCHAR, v_id;
    ELSE
        UPDATE cms."Post" SET
            "Slug"           = p_slug,
            "Vertical"       = p_vertical,
            "Category"       = p_category,
            "Locale"         = p_locale,
            "Title"          = p_title,
            "Excerpt"        = p_excerpt,
            "Body"           = p_body,
            "CoverUrl"       = p_cover_url,
            "AuthorName"     = p_author_name,
            "AuthorSlug"     = p_author_slug,
            "AuthorAvatar"   = p_author_avatar,
            "Tags"           = p_tags,
            "ReadingMin"     = p_reading_min,
            "SeoTitle"       = p_seo_title,
            "SeoDescription" = p_seo_description,
            "SeoImageUrl"    = p_seo_image_url,
            "UpdatedAt"      = NOW()
        WHERE "PostId" = p_post_id
        RETURNING "PostId" INTO v_id;

        IF v_id IS NULL THEN
            RETURN QUERY SELECT FALSE, 'post_not_found'::VARCHAR, 0;
        ELSE
            RETURN QUERY SELECT TRUE, 'post_updated'::VARCHAR, v_id;
        END IF;
    END IF;
END;
$$;
-- +goose StatementEnd

-- ── SP: usp_cms_post_publish ──────────────────────────────────────────────────
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION usp_cms_post_publish(
    p_post_id INTEGER,
    p_publish BOOLEAN DEFAULT TRUE
)
RETURNS TABLE("ok" BOOLEAN, "mensaje" VARCHAR)
LANGUAGE plpgsql AS $$
DECLARE
    v_rows INTEGER;
BEGIN
    UPDATE cms."Post" SET
        "Status"      = CASE WHEN p_publish THEN 'published' ELSE 'draft' END,
        "PublishedAt" = CASE WHEN p_publish AND "PublishedAt" IS NULL THEN NOW() ELSE "PublishedAt" END,
        "UpdatedAt"   = NOW()
    WHERE "PostId" = p_post_id;

    GET DIAGNOSTICS v_rows = ROW_COUNT;
    IF v_rows = 0 THEN
        RETURN QUERY SELECT FALSE, 'post_not_found'::VARCHAR;
    ELSE
        RETURN QUERY SELECT TRUE,
            CASE WHEN p_publish THEN 'post_published'::VARCHAR ELSE 'post_unpublished'::VARCHAR END;
    END IF;
END;
$$;
-- +goose StatementEnd

-- ── SP: usp_cms_post_delete ───────────────────────────────────────────────────
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION usp_cms_post_delete(
    p_post_id INTEGER
)
RETURNS TABLE("ok" BOOLEAN, "mensaje" VARCHAR)
LANGUAGE plpgsql AS $$
DECLARE
    v_rows INTEGER;
BEGIN
    DELETE FROM cms."Post" WHERE "PostId" = p_post_id;
    GET DIAGNOSTICS v_rows = ROW_COUNT;
    IF v_rows = 0 THEN
        RETURN QUERY SELECT FALSE, 'post_not_found'::VARCHAR;
    ELSE
        RETURN QUERY SELECT TRUE, 'post_deleted'::VARCHAR;
    END IF;
END;
$$;
-- +goose StatementEnd

-- ── SP: usp_cms_page_list ─────────────────────────────────────────────────────
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION usp_cms_page_list(
    p_vertical VARCHAR DEFAULT NULL,
    p_locale   VARCHAR DEFAULT 'es',
    p_status   VARCHAR DEFAULT 'published'
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
    WHERE (p_vertical IS NULL OR p."Vertical" = p_vertical)
      AND p."Locale" = p_locale
      AND (p_status IS NULL OR p."Status" = p_status)
    ORDER BY p."Slug";
END;
$$;
-- +goose StatementEnd

-- ── SP: usp_cms_page_get ──────────────────────────────────────────────────────
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION usp_cms_page_get(
    p_slug     VARCHAR,
    p_vertical VARCHAR DEFAULT 'corporate',
    p_locale   VARCHAR DEFAULT 'es'
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
    LIMIT 1;
END;
$$;
-- +goose StatementEnd

-- ── SP: usp_cms_page_upsert ───────────────────────────────────────────────────
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

-- ── SP: usp_cms_page_publish ──────────────────────────────────────────────────
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION usp_cms_page_publish(
    p_page_id INTEGER,
    p_publish BOOLEAN DEFAULT TRUE
)
RETURNS TABLE("ok" BOOLEAN, "mensaje" VARCHAR)
LANGUAGE plpgsql AS $$
DECLARE
    v_rows INTEGER;
BEGIN
    UPDATE cms."Page" SET
        "Status"      = CASE WHEN p_publish THEN 'published' ELSE 'draft' END,
        "PublishedAt" = CASE WHEN p_publish AND "PublishedAt" IS NULL THEN NOW() ELSE "PublishedAt" END,
        "UpdatedAt"   = NOW()
    WHERE "PageId" = p_page_id;

    GET DIAGNOSTICS v_rows = ROW_COUNT;
    IF v_rows = 0 THEN
        RETURN QUERY SELECT FALSE, 'page_not_found'::VARCHAR;
    ELSE
        RETURN QUERY SELECT TRUE,
            CASE WHEN p_publish THEN 'page_published'::VARCHAR ELSE 'page_unpublished'::VARCHAR END;
    END IF;
END;
$$;
-- +goose StatementEnd

-- ── SP: usp_cms_page_delete ───────────────────────────────────────────────────
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION usp_cms_page_delete(
    p_page_id INTEGER
)
RETURNS TABLE("ok" BOOLEAN, "mensaje" VARCHAR)
LANGUAGE plpgsql AS $$
DECLARE
    v_rows INTEGER;
BEGIN
    DELETE FROM cms."Page" WHERE "PageId" = p_page_id;
    GET DIAGNOSTICS v_rows = ROW_COUNT;
    IF v_rows = 0 THEN
        RETURN QUERY SELECT FALSE, 'page_not_found'::VARCHAR;
    ELSE
        RETURN QUERY SELECT TRUE, 'page_deleted'::VARCHAR;
    END IF;
END;
$$;
-- +goose StatementEnd

-- +goose Down
DROP FUNCTION IF EXISTS usp_cms_page_delete;
DROP FUNCTION IF EXISTS usp_cms_page_publish;
DROP FUNCTION IF EXISTS usp_cms_page_upsert;
DROP FUNCTION IF EXISTS usp_cms_page_get;
DROP FUNCTION IF EXISTS usp_cms_page_list;
DROP FUNCTION IF EXISTS usp_cms_post_delete;
DROP FUNCTION IF EXISTS usp_cms_post_publish;
DROP FUNCTION IF EXISTS usp_cms_post_upsert;
DROP FUNCTION IF EXISTS usp_cms_post_get;
DROP FUNCTION IF EXISTS usp_cms_post_list;
DROP TABLE IF EXISTS cms."Page";
DROP TABLE IF EXISTS cms."Post";
DROP SCHEMA IF EXISTS cms;
