-- +goose Up
-- White-label brand config per tenant (F4)

-- ── Tabla ──────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS cfg."BrandConfig" (
    "BrandConfigId"   SERIAL        PRIMARY KEY,
    "CompanyId"       INTEGER       NOT NULL,
    "LogoUrl"         VARCHAR(500)  DEFAULT ''::VARCHAR,
    "FaviconUrl"      VARCHAR(500)  DEFAULT ''::VARCHAR,
    "PrimaryColor"    VARCHAR(20)   DEFAULT '#FFB547'::VARCHAR,
    "SecondaryColor"  VARCHAR(20)   DEFAULT '#232f3e'::VARCHAR,
    "AccentColor"     VARCHAR(20)   DEFAULT '#FFB547'::VARCHAR,
    "AppName"         VARCHAR(120)  DEFAULT ''::VARCHAR,
    "SupportEmail"    VARCHAR(200)  DEFAULT ''::VARCHAR,
    "SupportPhone"    VARCHAR(50)   DEFAULT ''::VARCHAR,
    "CustomDomain"    VARCHAR(200)  DEFAULT ''::VARCHAR,
    "CustomCss"       TEXT          DEFAULT '',
    "FooterText"      VARCHAR(500)  DEFAULT ''::VARCHAR,
    "LoginBgUrl"      VARCHAR(500)  DEFAULT ''::VARCHAR,
    "IsActive"        BOOLEAN       NOT NULL DEFAULT TRUE,
    "CreatedAt"       TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    "UpdatedAt"       TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_brand_config_company UNIQUE ("CompanyId")
);

CREATE INDEX IF NOT EXISTS idx_brand_config_company ON cfg."BrandConfig" ("CompanyId");

-- ── SP: usp_cfg_brand_config_get ───────────────────────────────────────────────
CREATE OR REPLACE FUNCTION usp_cfg_brand_config_get(
    p_company_id INTEGER
)
RETURNS TABLE(
    "BrandConfigId"  INTEGER,
    "CompanyId"      INTEGER,
    "LogoUrl"        VARCHAR,
    "FaviconUrl"     VARCHAR,
    "PrimaryColor"   VARCHAR,
    "SecondaryColor" VARCHAR,
    "AccentColor"    VARCHAR,
    "AppName"        VARCHAR,
    "SupportEmail"   VARCHAR,
    "SupportPhone"   VARCHAR,
    "CustomDomain"   VARCHAR,
    "CustomCss"      TEXT,
    "FooterText"     VARCHAR,
    "LoginBgUrl"     VARCHAR,
    "IsActive"       BOOLEAN,
    "CreatedAt"      TIMESTAMPTZ,
    "UpdatedAt"      TIMESTAMPTZ
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        bc."BrandConfigId",
        bc."CompanyId",
        bc."LogoUrl",
        bc."FaviconUrl",
        bc."PrimaryColor",
        bc."SecondaryColor",
        bc."AccentColor",
        bc."AppName",
        bc."SupportEmail",
        bc."SupportPhone",
        bc."CustomDomain",
        bc."CustomCss",
        bc."FooterText",
        bc."LoginBgUrl",
        bc."IsActive",
        bc."CreatedAt",
        bc."UpdatedAt"
    FROM cfg."BrandConfig" bc
    WHERE bc."CompanyId" = p_company_id
      AND bc."IsActive" = TRUE;
END;
$$;

-- ── SP: usp_cfg_brand_config_upsert ────────────────────────────────────────────
CREATE OR REPLACE FUNCTION usp_cfg_brand_config_upsert(
    p_company_id      INTEGER,
    p_logo_url        VARCHAR DEFAULT ''::VARCHAR,
    p_favicon_url     VARCHAR DEFAULT ''::VARCHAR,
    p_primary_color   VARCHAR DEFAULT '#FFB547'::VARCHAR,
    p_secondary_color VARCHAR DEFAULT '#232f3e'::VARCHAR,
    p_accent_color    VARCHAR DEFAULT '#FFB547'::VARCHAR,
    p_app_name        VARCHAR DEFAULT ''::VARCHAR,
    p_support_email   VARCHAR DEFAULT ''::VARCHAR,
    p_support_phone   VARCHAR DEFAULT ''::VARCHAR,
    p_custom_domain   VARCHAR DEFAULT ''::VARCHAR,
    p_custom_css      TEXT    DEFAULT '',
    p_footer_text     VARCHAR DEFAULT ''::VARCHAR,
    p_login_bg_url    VARCHAR DEFAULT ''::VARCHAR,
    p_is_active       BOOLEAN DEFAULT TRUE
)
RETURNS TABLE("ok" BOOLEAN, "mensaje" VARCHAR)
LANGUAGE plpgsql AS $$
DECLARE
    v_exists BOOLEAN;
BEGIN
    SELECT EXISTS(
        SELECT 1 FROM cfg."BrandConfig" WHERE "CompanyId" = p_company_id
    ) INTO v_exists;

    IF v_exists THEN
        UPDATE cfg."BrandConfig" SET
            "LogoUrl"        = COALESCE(p_logo_url, "LogoUrl"),
            "FaviconUrl"     = COALESCE(p_favicon_url, "FaviconUrl"),
            "PrimaryColor"   = COALESCE(p_primary_color, "PrimaryColor"),
            "SecondaryColor" = COALESCE(p_secondary_color, "SecondaryColor"),
            "AccentColor"    = COALESCE(p_accent_color, "AccentColor"),
            "AppName"        = COALESCE(p_app_name, "AppName"),
            "SupportEmail"   = COALESCE(p_support_email, "SupportEmail"),
            "SupportPhone"   = COALESCE(p_support_phone, "SupportPhone"),
            "CustomDomain"   = COALESCE(p_custom_domain, "CustomDomain"),
            "CustomCss"      = COALESCE(p_custom_css, "CustomCss"),
            "FooterText"     = COALESCE(p_footer_text, "FooterText"),
            "LoginBgUrl"     = COALESCE(p_login_bg_url, "LoginBgUrl"),
            "IsActive"       = COALESCE(p_is_active, "IsActive"),
            "UpdatedAt"      = NOW()
        WHERE "CompanyId" = p_company_id;

        RETURN QUERY SELECT TRUE, 'brand_config_updated'::VARCHAR;
    ELSE
        INSERT INTO cfg."BrandConfig" (
            "CompanyId", "LogoUrl", "FaviconUrl",
            "PrimaryColor", "SecondaryColor", "AccentColor",
            "AppName", "SupportEmail", "SupportPhone",
            "CustomDomain", "CustomCss", "FooterText",
            "LoginBgUrl", "IsActive"
        ) VALUES (
            p_company_id, p_logo_url, p_favicon_url,
            p_primary_color, p_secondary_color, p_accent_color,
            p_app_name, p_support_email, p_support_phone,
            p_custom_domain, p_custom_css, p_footer_text,
            p_login_bg_url, p_is_active
        );

        RETURN QUERY SELECT TRUE, 'brand_config_created'::VARCHAR;
    END IF;
END;
$$;

-- +goose Down
DROP FUNCTION IF EXISTS usp_cfg_brand_config_upsert;
DROP FUNCTION IF EXISTS usp_cfg_brand_config_get;
DROP TABLE IF EXISTS cfg."BrandConfig";
