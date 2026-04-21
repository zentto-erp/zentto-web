-- +goose Up
-- +goose StatementBegin
-- =============================================================================
-- Fix ambiguous column references en usp_cms_landingschema_*
-- =============================================================================
-- Bug: RETURNS TABLE con columna "LandingSchemaId" colisiona con la misma
-- columna de cms."LandingSchema" en SELECT/UPDATE. Postgres lanza
-- "column reference LandingSchemaId is ambiguous".
--
-- Fix: agregar `#variable_conflict use_column` + alias de tabla en todos los
-- SPs que acceden a cms."LandingSchema" con columnas coincidentes con el
-- RETURNS TABLE.
-- =============================================================================

-- ─── 1. upsert_draft ─────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION usp_cms_landingschema_upsert_draft(
    p_landing_schema_id INTEGER DEFAULT NULL,
    p_company_id        INTEGER DEFAULT 1,
    p_vertical          VARCHAR DEFAULT '',
    p_slug              VARCHAR DEFAULT 'default',
    p_locale            VARCHAR DEFAULT 'es',
    p_draft_schema      JSONB   DEFAULT '{}',
    p_theme_tokens      JSONB   DEFAULT NULL,
    p_seo_meta          JSONB   DEFAULT NULL,
    p_user_id           INTEGER DEFAULT NULL
)
RETURNS TABLE(ok BOOLEAN, mensaje VARCHAR, "LandingSchemaId" INTEGER)
LANGUAGE plpgsql
AS $$
#variable_conflict use_column
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

    IF p_landing_schema_id IS NULL OR p_landing_schema_id = 0 THEN
        SELECT ls."LandingSchemaId" INTO v_id
        FROM cms."LandingSchema" ls
        WHERE ls."CompanyId" = p_company_id
          AND ls."Vertical"  = p_vertical
          AND ls."Slug"      = p_slug
          AND ls."Locale"    = p_locale
        LIMIT 1;

        IF v_id IS NOT NULL THEN
            UPDATE cms."LandingSchema" ls SET
                "DraftSchema" = p_draft_schema,
                "ThemeTokens" = COALESCE(p_theme_tokens, ls."ThemeTokens"),
                "SeoMeta"     = COALESCE(p_seo_meta, ls."SeoMeta"),
                "UpdatedAt"   = NOW(),
                "UpdatedBy"   = p_user_id
            WHERE ls."LandingSchemaId" = v_id;
            RETURN QUERY SELECT TRUE, 'landing_draft_updated'::VARCHAR, v_id;
            RETURN;
        END IF;

        INSERT INTO cms."LandingSchema" (
            "CompanyId", "Vertical", "Slug", "Locale",
            "DraftSchema", "ThemeTokens", "SeoMeta",
            "Status", "CreatedBy", "UpdatedBy"
        ) VALUES (
            p_company_id, p_vertical, p_slug, p_locale,
            p_draft_schema, p_theme_tokens, p_seo_meta,
            'draft', p_user_id, p_user_id
        )
        RETURNING cms."LandingSchema"."LandingSchemaId" INTO v_id;
        RETURN QUERY SELECT TRUE, 'landing_draft_created'::VARCHAR, v_id;
    ELSE
        UPDATE cms."LandingSchema" ls SET
            "DraftSchema" = p_draft_schema,
            "ThemeTokens" = COALESCE(p_theme_tokens, ls."ThemeTokens"),
            "SeoMeta"     = COALESCE(p_seo_meta, ls."SeoMeta"),
            "UpdatedAt"   = NOW(),
            "UpdatedBy"   = p_user_id
        WHERE ls."LandingSchemaId" = p_landing_schema_id
          AND ls."CompanyId"      = p_company_id
        RETURNING ls."LandingSchemaId" INTO v_id;

        IF v_id IS NULL THEN
            RETURN QUERY SELECT FALSE, 'landing_not_found'::VARCHAR, 0;
        ELSE
            RETURN QUERY SELECT TRUE, 'landing_draft_updated'::VARCHAR, v_id;
        END IF;
    END IF;
END;
$$;

-- ─── 2. publish — mismo patrón de ambigüedad ────────────────────────────────
CREATE OR REPLACE FUNCTION usp_cms_landingschema_publish(
    p_landing_schema_id INTEGER,
    p_company_id        INTEGER,
    p_user_id           INTEGER DEFAULT NULL
)
RETURNS TABLE(ok BOOLEAN, mensaje VARCHAR, "Version" INTEGER)
LANGUAGE plpgsql
AS $$
#variable_conflict use_column
DECLARE
    v_draft       JSONB;
    v_theme       JSONB;
    v_seo         JSONB;
    v_new_version INTEGER;
BEGIN
    SELECT ls."DraftSchema", ls."ThemeTokens", ls."SeoMeta", (ls."Version" + 1)
      INTO v_draft, v_theme, v_seo, v_new_version
    FROM cms."LandingSchema" ls
    WHERE ls."LandingSchemaId" = p_landing_schema_id
      AND ls."CompanyId"       = p_company_id
    LIMIT 1;

    IF v_draft IS NULL THEN
        RETURN QUERY SELECT FALSE, 'landing_not_found'::VARCHAR, 0;
        RETURN;
    END IF;

    UPDATE cms."LandingSchema" ls SET
        "PublishedSchema" = v_draft,
        "Version"         = v_new_version,
        "Status"          = 'published',
        "PublishedAt"     = NOW(),
        "PublishedBy"     = p_user_id,
        "UpdatedAt"       = NOW(),
        "UpdatedBy"       = p_user_id
    WHERE ls."LandingSchemaId" = p_landing_schema_id
      AND ls."CompanyId"       = p_company_id;

    -- Snapshot en history
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

-- ─── 3. set_preview_token — usa "PreviewToken" col ──────────────────────────
CREATE OR REPLACE FUNCTION usp_cms_landingschema_set_preview_token(
    p_landing_schema_id INTEGER,
    p_company_id        INTEGER,
    p_token             VARCHAR DEFAULT NULL
)
RETURNS TABLE(ok BOOLEAN, mensaje VARCHAR, "PreviewToken" VARCHAR)
LANGUAGE plpgsql
AS $$
#variable_conflict use_column
DECLARE
    v_token VARCHAR;
BEGIN
    UPDATE cms."LandingSchema" ls SET
        "PreviewToken" = p_token,
        "UpdatedAt"    = NOW()
    WHERE ls."LandingSchemaId" = p_landing_schema_id
      AND ls."CompanyId"       = p_company_id
    RETURNING ls."PreviewToken" INTO v_token;

    IF NOT FOUND THEN
        RETURN QUERY SELECT FALSE, 'landing_not_found'::VARCHAR, NULL::VARCHAR;
        RETURN;
    END IF;

    RETURN QUERY SELECT TRUE, 'preview_token_set'::VARCHAR, v_token;
END;
$$;

-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
-- Revertir a la versión de 00161 (con el bug conocido) no tiene sentido.
-- El rollback real es dropear las funciones, que 00161.down ya maneja.
-- Dejamos un stub vacío para que goose down sobre 00162 no falle.
SELECT 1;
-- +goose StatementEnd
