-- +goose Up
-- Fix: "column reference 'LeadId' is ambiguous" en usp_public_lead_upsert.
-- La función tiene RETURNS TABLE(..."LeadId" INTEGER) y el RETURNING del INSERT
-- usaba "LeadId" sin calificar — ambiguo con el out-param del RETURNS TABLE.
-- Solución: calificar con public."Lead"."LeadId" en el RETURNING.

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_public_lead_upsert(
    p_email               VARCHAR,
    p_full_name           VARCHAR,
    p_company             VARCHAR,
    p_country             VARCHAR,
    p_source              VARCHAR,
    p_vertical_interest   VARCHAR,
    p_plan_slug           VARCHAR,
    p_addon_slugs         JSONB,
    p_intended_subdomain  VARCHAR,
    p_utm_source          VARCHAR,
    p_utm_medium          VARCHAR,
    p_utm_campaign        VARCHAR
)
RETURNS TABLE("ok" BOOLEAN, "mensaje" VARCHAR, "LeadId" INTEGER)
LANGUAGE plpgsql AS $$
DECLARE
    v_lead_id INTEGER;
BEGIN
    INSERT INTO public."Lead" (
        "Email", "FullName", "Company", "Country", "Source",
        "VerticalInterest", "PlanSlug", "AddonSlugs", "IntendedSubdomain",
        "UtmSource", "UtmMedium", "UtmCampaign",
        "Status", "CreatedAt", "UpdatedAt"
    ) VALUES (
        LOWER(p_email), COALESCE(p_full_name,''), COALESCE(p_company,''),
        COALESCE(p_country,''), COALESCE(p_source,'registro'),
        COALESCE(p_vertical_interest,''), COALESCE(p_plan_slug,''),
        COALESCE(p_addon_slugs,'[]'::JSONB), COALESCE(p_intended_subdomain,''),
        COALESCE(p_utm_source,''), COALESCE(p_utm_medium,''), COALESCE(p_utm_campaign,''),
        'new', NOW(), NOW()
    )
    ON CONFLICT ("Email") DO UPDATE SET
        "FullName"          = COALESCE(NULLIF(EXCLUDED."FullName",''),          public."Lead"."FullName"),
        "Company"           = COALESCE(NULLIF(EXCLUDED."Company",''),           public."Lead"."Company"),
        "Country"           = COALESCE(NULLIF(EXCLUDED."Country",''),           public."Lead"."Country"),
        "Source"            = COALESCE(NULLIF(EXCLUDED."Source",''),            public."Lead"."Source"),
        "VerticalInterest"  = COALESCE(NULLIF(EXCLUDED."VerticalInterest",''),  public."Lead"."VerticalInterest"),
        "PlanSlug"          = COALESCE(NULLIF(EXCLUDED."PlanSlug",''),          public."Lead"."PlanSlug"),
        "AddonSlugs"        = EXCLUDED."AddonSlugs",
        "IntendedSubdomain" = COALESCE(NULLIF(EXCLUDED."IntendedSubdomain",''), public."Lead"."IntendedSubdomain"),
        "UtmSource"         = COALESCE(NULLIF(EXCLUDED."UtmSource",''),         public."Lead"."UtmSource"),
        "UtmMedium"         = COALESCE(NULLIF(EXCLUDED."UtmMedium",''),         public."Lead"."UtmMedium"),
        "UtmCampaign"       = COALESCE(NULLIF(EXCLUDED."UtmCampaign",''),       public."Lead"."UtmCampaign"),
        "UpdatedAt"         = NOW()
    RETURNING public."Lead"."LeadId" INTO v_lead_id;

    RETURN QUERY SELECT TRUE, 'Lead registrado'::VARCHAR, v_lead_id;
END;
$$;
-- +goose StatementEnd

-- +goose Down
-- No-op: la versión anterior tenía el bug, no vale la pena restaurarla.
SELECT 1;
