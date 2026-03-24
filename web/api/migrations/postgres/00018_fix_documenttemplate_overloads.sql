-- +goose Up
-- Fix: Eliminar TODAS las sobrecargas de funciones DocumentTemplate
-- que causan "function is not unique" en cada deploy.
--
-- Causa raíz: sp_nomina_documentos.sql creaba funciones con firma
-- (INTEGER, CHAR(2), VARCHAR(40)) mientras las migraciones 00008/00009
-- las creaban con (INT, VARCHAR, VARCHAR). Ambas coexistían como
-- sobrecargas separadas, y callSp no podía resolver cuál usar.

DO $do$
DECLARE _oid OID;
BEGIN
  FOR _oid IN
    SELECT p.oid FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public' AND p.proname IN (
      'usp_hr_documenttemplate_list',
      'usp_hr_documenttemplate_get',
      'usp_hr_documenttemplate_save',
      'usp_hr_documenttemplate_delete'
    )
  LOOP
    EXECUTE format('DROP FUNCTION IF EXISTS %s CASCADE', _oid::regprocedure);
  END LOOP;
END $do$;

-- Recrear con firma canónica: VARCHAR sin tamaño, BIGINT para IDs, TIMESTAMP sin precisión
CREATE OR REPLACE FUNCTION public.usp_hr_documenttemplate_list(
    p_company_id INT, p_country_code VARCHAR DEFAULT NULL, p_template_type VARCHAR DEFAULT NULL
)
RETURNS TABLE(
    "TemplateId" BIGINT, "TemplateCode" VARCHAR, "TemplateName" VARCHAR,
    "TemplateType" VARCHAR, "CountryCode" VARCHAR, "PayrollCode" VARCHAR,
    "IsDefault" BOOLEAN, "IsSystem" BOOLEAN, "IsActive" BOOLEAN, "UpdatedAt" TIMESTAMP
)
LANGUAGE plpgsql AS $fn$
BEGIN
    RETURN QUERY
    SELECT t."TemplateId"::BIGINT, t."TemplateCode"::VARCHAR, t."TemplateName"::VARCHAR,
           t."TemplateType"::VARCHAR, t."CountryCode"::VARCHAR, t."PayrollCode"::VARCHAR,
           t."IsDefault", t."IsSystem", t."IsActive", t."UpdatedAt"::TIMESTAMP
    FROM hr."DocumentTemplate" t
    WHERE t."CompanyId" = p_company_id AND t."IsActive" = TRUE
      AND (p_country_code IS NULL OR t."CountryCode" = p_country_code)
      AND (p_template_type IS NULL OR t."TemplateType" = p_template_type)
    ORDER BY t."CountryCode", t."TemplateType", t."TemplateName";
END;
$fn$;

CREATE OR REPLACE FUNCTION public.usp_hr_documenttemplate_get(
    p_company_id INT, p_template_code VARCHAR
)
RETURNS TABLE(
    "TemplateId" BIGINT, "TemplateCode" VARCHAR, "TemplateName" VARCHAR,
    "TemplateType" VARCHAR, "CountryCode" VARCHAR, "PayrollCode" VARCHAR,
    "ContentMD" TEXT, "IsDefault" BOOLEAN, "IsSystem" BOOLEAN, "IsActive" BOOLEAN,
    "CreatedAt" TIMESTAMP, "UpdatedAt" TIMESTAMP
)
LANGUAGE plpgsql AS $fn$
BEGIN
    RETURN QUERY
    SELECT t."TemplateId"::BIGINT, t."TemplateCode"::VARCHAR, t."TemplateName"::VARCHAR,
           t."TemplateType"::VARCHAR, t."CountryCode"::VARCHAR, t."PayrollCode"::VARCHAR,
           t."ContentMD", t."IsDefault", t."IsSystem", t."IsActive",
           t."CreatedAt"::TIMESTAMP, t."UpdatedAt"::TIMESTAMP
    FROM hr."DocumentTemplate" t
    WHERE t."CompanyId" = p_company_id AND t."TemplateCode" = p_template_code;
END;
$fn$;

CREATE OR REPLACE FUNCTION public.usp_hr_documenttemplate_save(
    p_company_id INT, p_template_code VARCHAR, p_template_name VARCHAR,
    p_template_type VARCHAR, p_country_code VARCHAR, p_content_md TEXT,
    p_payroll_code VARCHAR DEFAULT NULL, p_is_default BOOLEAN DEFAULT FALSE,
    OUT p_resultado INT, OUT p_mensaje TEXT
)
LANGUAGE plpgsql AS $fn$
BEGIN
    p_resultado := 0; p_mensaje := ''::VARCHAR;
    IF EXISTS (SELECT 1 FROM hr."DocumentTemplate"
        WHERE "CompanyId" = p_company_id AND "TemplateCode" = p_template_code AND "IsSystem" = TRUE
    ) THEN
        p_resultado := -1; p_mensaje := 'No se puede modificar una plantilla del sistema.'::VARCHAR; RETURN;
    END IF;
    INSERT INTO hr."DocumentTemplate"(
        "CompanyId","TemplateCode","TemplateName","TemplateType","CountryCode","PayrollCode",
        "ContentMD","IsDefault","IsSystem","IsActive","CreatedAt","UpdatedAt"
    ) VALUES (
        p_company_id, p_template_code, p_template_name, p_template_type,
        p_country_code, p_payroll_code, p_content_md, COALESCE(p_is_default,FALSE),
        FALSE, TRUE, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'
    )
    ON CONFLICT ("CompanyId","TemplateCode") DO UPDATE
    SET "TemplateName"=EXCLUDED."TemplateName", "TemplateType"=EXCLUDED."TemplateType",
        "CountryCode"=EXCLUDED."CountryCode", "PayrollCode"=EXCLUDED."PayrollCode",
        "ContentMD"=EXCLUDED."ContentMD", "IsDefault"=EXCLUDED."IsDefault",
        "IsSystem"=FALSE, "UpdatedAt"=NOW() AT TIME ZONE 'UTC';
    p_resultado := 1; p_mensaje := 'Plantilla guardada correctamente.'::VARCHAR;
END;
$fn$;

CREATE OR REPLACE FUNCTION public.usp_hr_documenttemplate_delete(
    p_company_id INT, p_template_code VARCHAR,
    OUT p_resultado INT, OUT p_mensaje TEXT
)
LANGUAGE plpgsql AS $fn$
BEGIN
    p_resultado := 0; p_mensaje := ''::VARCHAR;
    IF EXISTS (SELECT 1 FROM hr."DocumentTemplate"
        WHERE "CompanyId" = p_company_id AND "TemplateCode" = p_template_code AND "IsSystem" = TRUE
    ) THEN
        p_resultado := -1; p_mensaje := 'No se puede eliminar una plantilla del sistema.'::VARCHAR; RETURN;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM hr."DocumentTemplate"
        WHERE "CompanyId" = p_company_id AND "TemplateCode" = p_template_code
    ) THEN
        p_resultado := -2; p_mensaje := 'Plantilla no encontrada.'::VARCHAR; RETURN;
    END IF;
    DELETE FROM hr."DocumentTemplate"
    WHERE "CompanyId" = p_company_id AND "TemplateCode" = p_template_code;
    p_resultado := 1; p_mensaje := 'Plantilla eliminada correctamente.'::VARCHAR;
END;
$fn$;

-- +goose Down
-- No rollback needed
