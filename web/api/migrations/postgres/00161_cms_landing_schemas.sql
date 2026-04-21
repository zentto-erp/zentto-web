-- +goose Up
-- CMS Landing Schemas — persistencia de schemas JSON de landings verticales.
-- Primer PR del plan "landing schemas en CMS" (Opción 3: studio schema + landing-kit renderer).
-- Precedente: web/modular-frontend/packages/module-ecommerce/src/components/StudioPageRenderer.tsx:29-33.
--
-- Objetivos:
--   • Editor CMS en zentto.net/cms/landings/:vertical guarda/publica LandingConfig.
--   • Multi-tenant: CompanyId scoping en todas las lecturas/escrituras.
--   • Draft vs published: estado editable (DraftSchema) + estado servido (PublishedSchema).
--   • Versioning: historial inmutable para rollback.
--   • Preview cross-subdomain: token UUID público (cookie zentto.net no llega a hotel.zentto.net).
--   • Opcional: ThemeTokens override + SeoMeta separados del schema.

-- ── Schema (crea si no existe, idempotente con 00147) ─────────────────────────
CREATE SCHEMA IF NOT EXISTS cms;

-- ── Tabla cms.LandingSchema ───────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS cms."LandingSchema" (
    "LandingSchemaId"  SERIAL        PRIMARY KEY,
    "CompanyId"        INTEGER       NOT NULL,
    "Vertical"         VARCHAR(50)   NOT NULL,
    "Slug"             VARCHAR(100)  NOT NULL DEFAULT 'default',
    "Locale"           VARCHAR(10)   NOT NULL DEFAULT 'es',
    "DraftSchema"      JSONB         NOT NULL,
    "PublishedSchema"  JSONB,
    "ThemeTokens"      JSONB,
    "SeoMeta"          JSONB,
    "Version"          INTEGER       NOT NULL DEFAULT 1,
    "Status"           VARCHAR(20)   NOT NULL DEFAULT 'draft',
    "PreviewToken"     VARCHAR(64),
    "PublishedAt"      TIMESTAMPTZ,
    "PublishedBy"      INTEGER,
    "CreatedAt"        TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    "CreatedBy"        INTEGER,
    "UpdatedAt"        TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    "UpdatedBy"        INTEGER,
    CONSTRAINT uq_cms_landing_company_vertical_slug_locale
        UNIQUE ("CompanyId", "Vertical", "Slug", "Locale"),
    CONSTRAINT chk_cms_landing_status
        CHECK ("Status" IN ('draft','published','archived'))
);

CREATE INDEX IF NOT EXISTS idx_cms_landing_company_vertical
    ON cms."LandingSchema" ("CompanyId", "Vertical", "Status");
CREATE INDEX IF NOT EXISTS idx_cms_landing_preview_token
    ON cms."LandingSchema" ("PreviewToken")
    WHERE "PreviewToken" IS NOT NULL;

-- ── Tabla cms.LandingSchemaHistory ────────────────────────────────────────────
-- Snapshot inmutable de cada publish para rollback.
CREATE TABLE IF NOT EXISTS cms."LandingSchemaHistory" (
    "LandingSchemaHistoryId" SERIAL       PRIMARY KEY,
    "LandingSchemaId"        INTEGER      NOT NULL
        REFERENCES cms."LandingSchema"("LandingSchemaId") ON DELETE CASCADE,
    "Version"                INTEGER      NOT NULL,
    "Schema"                 JSONB        NOT NULL,
    "ThemeTokens"            JSONB,
    "SeoMeta"                JSONB,
    "PublishedAt"            TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    "PublishedBy"            INTEGER
);

CREATE INDEX IF NOT EXISTS idx_cms_landing_history_schema_version
    ON cms."LandingSchemaHistory" ("LandingSchemaId", "Version" DESC);

-- ── SP: usp_cms_landingschema_get_published ───────────────────────────────────
-- Lectura pública para SSG/SSR de landings verticales. Sólo devuelve Published.
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION usp_cms_landingschema_get_published(
    p_company_id INTEGER,
    p_vertical   VARCHAR,
    p_slug       VARCHAR DEFAULT 'default',
    p_locale     VARCHAR DEFAULT 'es'
)
RETURNS TABLE(
    "LandingSchemaId" INTEGER,
    "CompanyId"       INTEGER,
    "Vertical"        VARCHAR,
    "Slug"            VARCHAR,
    "Locale"          VARCHAR,
    "Schema"          JSONB,
    "ThemeTokens"     JSONB,
    "SeoMeta"         JSONB,
    "Version"         INTEGER,
    "Status"          VARCHAR,
    "PublishedAt"     TIMESTAMPTZ,
    "UpdatedAt"       TIMESTAMPTZ
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        l."LandingSchemaId", l."CompanyId", l."Vertical", l."Slug", l."Locale",
        l."PublishedSchema" AS "Schema",
        l."ThemeTokens", l."SeoMeta",
        l."Version", l."Status", l."PublishedAt", l."UpdatedAt"
    FROM cms."LandingSchema" l
    WHERE l."CompanyId" = p_company_id
      AND l."Vertical"  = p_vertical
      AND l."Slug"      = p_slug
      AND l."Locale"    = p_locale
      AND l."Status"    = 'published'
      AND l."PublishedSchema" IS NOT NULL
    LIMIT 1;
END;
$$;
-- +goose StatementEnd

-- ── SP: usp_cms_landingschema_upsert_draft ────────────────────────────────────
-- Editor admin: crea o actualiza DraftSchema (no publica).
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION usp_cms_landingschema_upsert_draft(
    p_landing_schema_id INTEGER  DEFAULT NULL,
    p_company_id        INTEGER  DEFAULT 1,
    p_vertical          VARCHAR  DEFAULT '',
    p_slug              VARCHAR  DEFAULT 'default',
    p_locale            VARCHAR  DEFAULT 'es',
    p_draft_schema      JSONB    DEFAULT '{}'::JSONB,
    p_theme_tokens      JSONB    DEFAULT NULL,
    p_seo_meta          JSONB    DEFAULT NULL,
    p_user_id           INTEGER  DEFAULT NULL
)
RETURNS TABLE("ok" BOOLEAN, "mensaje" VARCHAR, "LandingSchemaId" INTEGER)
LANGUAGE plpgsql AS $$
DECLARE
    v_id INTEGER;
BEGIN
    IF p_vertical IS NULL OR p_vertical = '' THEN
        RETURN QUERY SELECT FALSE, 'vertical_required'::VARCHAR, 0;
        RETURN;
    END IF;
    IF p_draft_schema IS NULL THEN
        RETURN QUERY SELECT FALSE, 'draft_schema_required'::VARCHAR, 0;
        RETURN;
    END IF;

    -- INSERT si no hay id o id = 0
    IF p_landing_schema_id IS NULL OR p_landing_schema_id = 0 THEN
        -- Buscar existente por (CompanyId, Vertical, Slug, Locale) para evitar UNIQUE violation
        SELECT "LandingSchemaId" INTO v_id
        FROM cms."LandingSchema"
        WHERE "CompanyId" = p_company_id
          AND "Vertical"  = p_vertical
          AND "Slug"      = p_slug
          AND "Locale"    = p_locale
        LIMIT 1;

        IF v_id IS NOT NULL THEN
            -- Actualizar draft del existente (idempotente para el editor)
            UPDATE cms."LandingSchema" SET
                "DraftSchema"  = p_draft_schema,
                "ThemeTokens"  = COALESCE(p_theme_tokens, "ThemeTokens"),
                "SeoMeta"      = COALESCE(p_seo_meta, "SeoMeta"),
                "UpdatedAt"    = NOW(),
                "UpdatedBy"    = p_user_id
            WHERE "LandingSchemaId" = v_id;
            RETURN QUERY SELECT TRUE, 'landing_draft_updated'::VARCHAR, v_id;
            RETURN;
        END IF;

        -- Nuevo registro
        INSERT INTO cms."LandingSchema" (
            "CompanyId", "Vertical", "Slug", "Locale",
            "DraftSchema", "ThemeTokens", "SeoMeta",
            "Status", "CreatedBy", "UpdatedBy"
        ) VALUES (
            p_company_id, p_vertical, p_slug, p_locale,
            p_draft_schema, p_theme_tokens, p_seo_meta,
            'draft', p_user_id, p_user_id
        )
        RETURNING "LandingSchemaId" INTO v_id;
        RETURN QUERY SELECT TRUE, 'landing_draft_created'::VARCHAR, v_id;
    ELSE
        UPDATE cms."LandingSchema" SET
            "DraftSchema"  = p_draft_schema,
            "ThemeTokens"  = COALESCE(p_theme_tokens, "ThemeTokens"),
            "SeoMeta"      = COALESCE(p_seo_meta, "SeoMeta"),
            "UpdatedAt"    = NOW(),
            "UpdatedBy"    = p_user_id
        WHERE "LandingSchemaId" = p_landing_schema_id
          AND "CompanyId" = p_company_id
        RETURNING "LandingSchemaId" INTO v_id;

        IF v_id IS NULL THEN
            RETURN QUERY SELECT FALSE, 'landing_not_found'::VARCHAR, 0;
        ELSE
            RETURN QUERY SELECT TRUE, 'landing_draft_updated'::VARCHAR, v_id;
        END IF;
    END IF;
END;
$$;
-- +goose StatementEnd

-- ── SP: usp_cms_landingschema_publish ─────────────────────────────────────────
-- Copia DraftSchema → PublishedSchema + incrementa Version + inserta History snapshot.
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION usp_cms_landingschema_publish(
    p_landing_schema_id INTEGER,
    p_company_id        INTEGER,
    p_user_id           INTEGER DEFAULT NULL
)
RETURNS TABLE("ok" BOOLEAN, "mensaje" VARCHAR, "Version" INTEGER)
LANGUAGE plpgsql AS $$
DECLARE
    v_draft       JSONB;
    v_theme       JSONB;
    v_seo         JSONB;
    v_new_version INTEGER;
BEGIN
    SELECT "DraftSchema", "ThemeTokens", "SeoMeta", "Version" + 1
      INTO v_draft, v_theme, v_seo, v_new_version
    FROM cms."LandingSchema"
    WHERE "LandingSchemaId" = p_landing_schema_id
      AND "CompanyId" = p_company_id;

    IF v_draft IS NULL THEN
        RETURN QUERY SELECT FALSE, 'landing_not_found'::VARCHAR, 0;
        RETURN;
    END IF;

    UPDATE cms."LandingSchema" SET
        "PublishedSchema" = v_draft,
        "Version"         = v_new_version,
        "Status"          = 'published',
        "PublishedAt"     = NOW(),
        "PublishedBy"     = p_user_id,
        "UpdatedAt"       = NOW(),
        "UpdatedBy"       = p_user_id
    WHERE "LandingSchemaId" = p_landing_schema_id
      AND "CompanyId" = p_company_id;

    INSERT INTO cms."LandingSchemaHistory" (
        "LandingSchemaId", "Version", "Schema", "ThemeTokens", "SeoMeta",
        "PublishedAt", "PublishedBy"
    ) VALUES (
        p_landing_schema_id, v_new_version, v_draft, v_theme, v_seo,
        NOW(), p_user_id
    );

    RETURN QUERY SELECT TRUE, 'landing_published'::VARCHAR, v_new_version;
END;
$$;
-- +goose StatementEnd

-- ── SP: usp_cms_landingschema_list_versions ───────────────────────────────────
-- Historial de versiones (admin) para rollback.
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION usp_cms_landingschema_list_versions(
    p_landing_schema_id INTEGER,
    p_company_id        INTEGER,
    p_limit             INTEGER DEFAULT 20,
    p_offset            INTEGER DEFAULT 0
)
RETURNS TABLE(
    "LandingSchemaHistoryId" INTEGER,
    "LandingSchemaId"        INTEGER,
    "Version"                INTEGER,
    "PublishedAt"            TIMESTAMPTZ,
    "PublishedBy"            INTEGER,
    "TotalCount"             BIGINT
)
LANGUAGE plpgsql AS $$
DECLARE
    v_total BIGINT;
BEGIN
    -- Verificar ownership (tenant scope) con un subquery simple
    IF NOT EXISTS (
        SELECT 1 FROM cms."LandingSchema"
        WHERE "LandingSchemaId" = p_landing_schema_id
          AND "CompanyId" = p_company_id
    ) THEN
        RETURN;
    END IF;

    SELECT COUNT(*) INTO v_total
    FROM cms."LandingSchemaHistory"
    WHERE "LandingSchemaId" = p_landing_schema_id;

    RETURN QUERY
    SELECT
        h."LandingSchemaHistoryId",
        h."LandingSchemaId",
        h."Version",
        h."PublishedAt",
        h."PublishedBy",
        v_total AS "TotalCount"
    FROM cms."LandingSchemaHistory" h
    WHERE h."LandingSchemaId" = p_landing_schema_id
    ORDER BY h."Version" DESC, h."LandingSchemaHistoryId" DESC
    LIMIT p_limit OFFSET p_offset;
END;
$$;
-- +goose StatementEnd

-- ── SP: usp_cms_landingschema_get_by_preview_token ────────────────────────────
-- Público sin auth: devuelve DraftSchema si el token coincide.
-- Útil para preview cross-subdomain (hotel.zentto.net) sin cookie httpOnly.
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION usp_cms_landingschema_get_by_preview_token(
    p_preview_token VARCHAR
)
RETURNS TABLE(
    "LandingSchemaId" INTEGER,
    "CompanyId"       INTEGER,
    "Vertical"        VARCHAR,
    "Slug"            VARCHAR,
    "Locale"          VARCHAR,
    "Schema"          JSONB,
    "ThemeTokens"     JSONB,
    "SeoMeta"         JSONB,
    "Version"         INTEGER,
    "Status"          VARCHAR,
    "UpdatedAt"       TIMESTAMPTZ
)
LANGUAGE plpgsql AS $$
BEGIN
    IF p_preview_token IS NULL OR p_preview_token = '' THEN
        RETURN;
    END IF;

    RETURN QUERY
    SELECT
        l."LandingSchemaId", l."CompanyId", l."Vertical", l."Slug", l."Locale",
        l."DraftSchema" AS "Schema",
        l."ThemeTokens", l."SeoMeta",
        l."Version", l."Status", l."UpdatedAt"
    FROM cms."LandingSchema" l
    WHERE l."PreviewToken" = p_preview_token
    LIMIT 1;
END;
$$;
-- +goose StatementEnd

-- ── SP: usp_cms_landingschema_list ────────────────────────────────────────────
-- Admin: lista landings del tenant con filtros.
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION usp_cms_landingschema_list(
    p_company_id INTEGER DEFAULT 1,
    p_vertical   VARCHAR DEFAULT NULL,
    p_status     VARCHAR DEFAULT NULL,
    p_limit      INTEGER DEFAULT 50,
    p_offset     INTEGER DEFAULT 0
)
RETURNS TABLE(
    "LandingSchemaId" INTEGER,
    "CompanyId"       INTEGER,
    "Vertical"        VARCHAR,
    "Slug"            VARCHAR,
    "Locale"          VARCHAR,
    "Version"         INTEGER,
    "Status"          VARCHAR,
    "PublishedAt"     TIMESTAMPTZ,
    "UpdatedAt"       TIMESTAMPTZ,
    "TotalCount"      BIGINT
)
LANGUAGE plpgsql AS $$
DECLARE
    v_total BIGINT;
BEGIN
    SELECT COUNT(*) INTO v_total
    FROM cms."LandingSchema" l
    WHERE l."CompanyId" = p_company_id
      AND (p_vertical IS NULL OR l."Vertical" = p_vertical)
      AND (p_status   IS NULL OR l."Status"   = p_status);

    RETURN QUERY
    SELECT
        l."LandingSchemaId", l."CompanyId", l."Vertical", l."Slug", l."Locale",
        l."Version", l."Status", l."PublishedAt", l."UpdatedAt",
        v_total AS "TotalCount"
    FROM cms."LandingSchema" l
    WHERE l."CompanyId" = p_company_id
      AND (p_vertical IS NULL OR l."Vertical" = p_vertical)
      AND (p_status   IS NULL OR l."Status"   = p_status)
    ORDER BY l."UpdatedAt" DESC, l."LandingSchemaId" DESC
    LIMIT p_limit OFFSET p_offset;
END;
$$;
-- +goose StatementEnd

-- ── SP: usp_cms_landingschema_get_by_id ───────────────────────────────────────
-- Admin: detalle completo (Draft + Published + metadata). Scope al CompanyId.
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION usp_cms_landingschema_get_by_id(
    p_landing_schema_id INTEGER,
    p_company_id        INTEGER
)
RETURNS TABLE(
    "LandingSchemaId" INTEGER,
    "CompanyId"       INTEGER,
    "Vertical"        VARCHAR,
    "Slug"            VARCHAR,
    "Locale"          VARCHAR,
    "DraftSchema"     JSONB,
    "PublishedSchema" JSONB,
    "ThemeTokens"     JSONB,
    "SeoMeta"         JSONB,
    "Version"         INTEGER,
    "Status"          VARCHAR,
    "PreviewToken"    VARCHAR,
    "PublishedAt"     TIMESTAMPTZ,
    "PublishedBy"     INTEGER,
    "CreatedAt"       TIMESTAMPTZ,
    "CreatedBy"       INTEGER,
    "UpdatedAt"       TIMESTAMPTZ,
    "UpdatedBy"       INTEGER
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        l."LandingSchemaId", l."CompanyId", l."Vertical", l."Slug", l."Locale",
        l."DraftSchema", l."PublishedSchema", l."ThemeTokens", l."SeoMeta",
        l."Version", l."Status", l."PreviewToken",
        l."PublishedAt", l."PublishedBy",
        l."CreatedAt", l."CreatedBy",
        l."UpdatedAt", l."UpdatedBy"
    FROM cms."LandingSchema" l
    WHERE l."LandingSchemaId" = p_landing_schema_id
      AND l."CompanyId" = p_company_id
    LIMIT 1;
END;
$$;
-- +goose StatementEnd

-- ── SP: usp_cms_landingschema_set_preview_token ───────────────────────────────
-- Rota (genera/reemplaza) el PreviewToken del landing. Pasa NULL para limpiar.
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION usp_cms_landingschema_set_preview_token(
    p_landing_schema_id INTEGER,
    p_company_id        INTEGER,
    p_token             VARCHAR DEFAULT NULL
)
RETURNS TABLE("ok" BOOLEAN, "mensaje" VARCHAR, "PreviewToken" VARCHAR)
LANGUAGE plpgsql AS $$
DECLARE
    v_token VARCHAR;
    v_rows  INTEGER;
BEGIN
    v_token := COALESCE(p_token, '');

    UPDATE cms."LandingSchema"
       SET "PreviewToken" = NULLIF(v_token, ''),
           "UpdatedAt"    = NOW()
     WHERE "LandingSchemaId" = p_landing_schema_id
       AND "CompanyId" = p_company_id;

    GET DIAGNOSTICS v_rows = ROW_COUNT;
    IF v_rows = 0 THEN
        RETURN QUERY SELECT FALSE, 'landing_not_found'::VARCHAR, NULL::VARCHAR;
    ELSE
        RETURN QUERY SELECT TRUE, 'preview_token_set'::VARCHAR, NULLIF(v_token, '');
    END IF;
END;
$$;
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
DROP FUNCTION IF EXISTS usp_cms_landingschema_set_preview_token(INTEGER, INTEGER, VARCHAR);
DROP FUNCTION IF EXISTS usp_cms_landingschema_get_by_id(INTEGER, INTEGER);
DROP FUNCTION IF EXISTS usp_cms_landingschema_list(INTEGER, VARCHAR, VARCHAR, INTEGER, INTEGER);
DROP FUNCTION IF EXISTS usp_cms_landingschema_get_by_preview_token(VARCHAR);
DROP FUNCTION IF EXISTS usp_cms_landingschema_list_versions(INTEGER, INTEGER, INTEGER, INTEGER);
DROP FUNCTION IF EXISTS usp_cms_landingschema_publish(INTEGER, INTEGER, INTEGER);
DROP FUNCTION IF EXISTS usp_cms_landingschema_upsert_draft(INTEGER, INTEGER, VARCHAR, VARCHAR, VARCHAR, JSONB, JSONB, JSONB, INTEGER);
DROP FUNCTION IF EXISTS usp_cms_landingschema_get_published(INTEGER, VARCHAR, VARCHAR, VARCHAR);
DROP INDEX  IF EXISTS cms.idx_cms_landing_history_schema_version;
DROP TABLE  IF EXISTS cms."LandingSchemaHistory";
DROP INDEX  IF EXISTS cms.idx_cms_landing_preview_token;
DROP INDEX  IF EXISTS cms.idx_cms_landing_company_vertical;
DROP TABLE  IF EXISTS cms."LandingSchema";
-- +goose StatementEnd
