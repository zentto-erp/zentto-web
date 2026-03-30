-- =============================================
-- usp_sys_Lead_Upsert
-- Registra o actualiza un lead desde la landing page
-- =============================================
DROP FUNCTION IF EXISTS public.usp_sys_lead_upsert;

CREATE OR REPLACE FUNCTION public.usp_sys_lead_upsert(
    p_email      VARCHAR(255),
    p_fullname   VARCHAR(255),
    p_company    VARCHAR(255) DEFAULT NULL,
    p_country    VARCHAR(10)  DEFAULT NULL,
    p_source     VARCHAR(100) DEFAULT 'zentto-landing'
)
RETURNS TABLE("ok" INT, "mensaje" VARCHAR(500))
LANGUAGE plpgsql
AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM public."Lead" WHERE "Email" = p_email) THEN
        UPDATE public."Lead"
        SET "FullName"  = p_fullname,
            "Company"   = COALESCE(p_company, "Company"),
            "Country"   = COALESCE(p_country, "Country"),
            "Source"    = p_source,
            "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
        WHERE "Email" = p_email;

        RETURN QUERY SELECT 1, 'Lead actualizado'::VARCHAR(500);
    ELSE
        INSERT INTO public."Lead" ("Email", "FullName", "Company", "Country", "Source", "CreatedAt", "UpdatedAt")
        VALUES (p_email, p_fullname, p_company, p_country, p_source, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC');

        RETURN QUERY SELECT 1, 'Lead registrado'::VARCHAR(500);
    END IF;

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT 0, SQLERRM::VARCHAR(500);
END;
$$;
