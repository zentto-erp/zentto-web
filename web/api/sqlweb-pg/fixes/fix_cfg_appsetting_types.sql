-- Fix: usp_cfg_appsetting_* functions
-- cfg."AppSetting"."SettingId" is INT (not BIGINT)
-- cfg."AppSetting"."SettingValue" is TEXT (not VARCHAR)
-- The 02_cfg.sql FASE-6 version declares them wrong â†’ 500 on /v1/settings

DROP FUNCTION IF EXISTS public.usp_cfg_appsetting_list(integer) CASCADE;
DROP FUNCTION IF EXISTS public.usp_cfg_appsetting_list(p_company_id integer)
RETURNS TABLE(
    "SettingId"    INT,
    "Module"       CHARACTER VARYING,
    "SettingKey"   CHARACTER VARYING,
    "SettingValue" TEXT,
    "ValueType"    CHARACTER VARYING,
    "Description"  CHARACTER VARYING,
    "UpdatedAt"    TIMESTAMP WITHOUT TIME ZONE
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT s."SettingId", s."Module", s."SettingKey",
           s."SettingValue"::TEXT, s."ValueType", s."Description",
           s."UpdatedAt"
    FROM   cfg."AppSetting" s
    WHERE  s."CompanyId" = p_company_id
    ORDER BY s."Module", s."SettingKey";
END;
$$;

DROP FUNCTION IF EXISTS public.usp_cfg_appsetting_listbymodule(integer, character varying) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_cfg_appsetting_listbymodule(
    p_company_id integer,
    p_module     character varying
)
RETURNS TABLE(
    "SettingId"    INT,
    "Module"       CHARACTER VARYING,
    "SettingKey"   CHARACTER VARYING,
    "SettingValue" TEXT,
    "ValueType"    CHARACTER VARYING,
    "Description"  CHARACTER VARYING,
    "UpdatedAt"    TIMESTAMP WITHOUT TIME ZONE
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT s."SettingId", s."Module", s."SettingKey",
           s."SettingValue"::TEXT, s."ValueType", s."Description",
           s."UpdatedAt"
    FROM   cfg."AppSetting" s
    WHERE  s."CompanyId" = p_company_id
      AND  s."Module"    = p_module
    ORDER BY s."SettingKey";
END;
$$;

DROP FUNCTION IF EXISTS public.usp_cfg_appsetting_listwithmeta(integer, character varying) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_cfg_appsetting_listwithmeta(
    p_company_id integer,
    p_module     character varying DEFAULT NULL::character varying
)
RETURNS TABLE(
    "SettingId"    INT,
    "Module"       CHARACTER VARYING,
    "SettingKey"   CHARACTER VARYING,
    "SettingValue" TEXT,
    "ValueType"    CHARACTER VARYING,
    "Description"  CHARACTER VARYING,
    "IsReadOnly"   BOOLEAN,
    "UpdatedAt"    TIMESTAMP WITHOUT TIME ZONE
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT s."SettingId", s."Module", s."SettingKey",
           s."SettingValue"::TEXT, s."ValueType", s."Description",
           s."IsReadOnly", s."UpdatedAt"
    FROM   cfg."AppSetting" s
    WHERE  s."CompanyId" = p_company_id
      AND  (p_module IS NULL OR s."Module" = p_module)
    ORDER BY s."Module", s."SettingKey";
END;
$$;
