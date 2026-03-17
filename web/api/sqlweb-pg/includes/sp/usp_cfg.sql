-- ============================================================
-- DatqBoxWeb PostgreSQL - usp_cfg.sql
-- Funciones de configuración (cfg.AppSetting, contexto)
-- ============================================================

-- usp_Cfg_ResolveContext: resuelve contexto empresa/sucursal/usuario
DROP FUNCTION IF EXISTS usp_Cfg_ResolveContext(VARCHAR(60)) CASCADE;
CREATE OR REPLACE FUNCTION usp_Cfg_ResolveContext(
    p_user_code VARCHAR(60) DEFAULT NULL
)
RETURNS TABLE("CompanyId" INT, "BranchId" INT, "UserId" INT)
LANGUAGE plpgsql AS $$
DECLARE
    v_company_id INT;
    v_branch_id  INT;
    v_user_id    INT := NULL;
BEGIN
    SELECT c."CompanyId" INTO v_company_id
    FROM   cfg."Company" c
    WHERE  c."IsDeleted" = FALSE
    ORDER BY CASE WHEN c."CompanyCode" = 'DEFAULT' THEN 0 ELSE 1 END, c."CompanyId"
    LIMIT 1;

    SELECT b."BranchId" INTO v_branch_id
    FROM   cfg."Branch" b
    WHERE  b."CompanyId" = v_company_id
      AND  b."IsDeleted" = FALSE
    ORDER BY CASE WHEN b."BranchCode" = 'MAIN' THEN 0 ELSE 1 END, b."BranchId"
    LIMIT 1;

    IF p_user_code IS NOT NULL THEN
        SELECT u."UserId" INTO v_user_id
        FROM   sec."User" u
        WHERE  u."UserCode"  = p_user_code
          AND  u."IsDeleted" = FALSE
        LIMIT 1;
    END IF;

    RETURN QUERY SELECT v_company_id, v_branch_id, v_user_id;
END;
$$;

-- usp_Cfg_AppSetting_List: lista configuraciones por empresa
DROP FUNCTION IF EXISTS usp_Cfg_AppSetting_List(INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_Cfg_AppSetting_List(
    p_company_id INT
)
RETURNS TABLE(
    "SettingId" BIGINT, "Module" VARCHAR, "SettingKey" VARCHAR,
    "SettingValue" TEXT, "ValueType" VARCHAR, "Description" VARCHAR,
    "UpdatedAt" TIMESTAMP
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT s."SettingId", s."Module", s."SettingKey",
           s."SettingValue", s."ValueType", s."Description",
           s."UpdatedAt"
    FROM   cfg."AppSetting" s
    WHERE  s."CompanyId" = p_company_id
    ORDER BY s."Module", s."SettingKey";
END;
$$;

-- usp_Cfg_AppSetting_ListByModule: lista configuraciones por módulo
DROP FUNCTION IF EXISTS usp_Cfg_AppSetting_ListByModule(INT, VARCHAR(60)) CASCADE;
CREATE OR REPLACE FUNCTION usp_Cfg_AppSetting_ListByModule(
    p_company_id INT,
    p_module     VARCHAR(60)
)
RETURNS TABLE(
    "SettingId" BIGINT, "Module" VARCHAR, "SettingKey" VARCHAR,
    "SettingValue" TEXT, "ValueType" VARCHAR, "Description" VARCHAR,
    "UpdatedAt" TIMESTAMP
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT s."SettingId", s."Module", s."SettingKey",
           s."SettingValue", s."ValueType", s."Description",
           s."UpdatedAt"
    FROM   cfg."AppSetting" s
    WHERE  s."CompanyId" = p_company_id
      AND  s."Module"    = p_module
    ORDER BY s."SettingKey";
END;
$$;

-- usp_Cfg_AppSetting_ListWithMeta: con metadatos completos
DROP FUNCTION IF EXISTS usp_Cfg_AppSetting_ListWithMeta(INT, VARCHAR(60)) CASCADE;
CREATE OR REPLACE FUNCTION usp_Cfg_AppSetting_ListWithMeta(
    p_company_id INT,
    p_module     VARCHAR(60) DEFAULT NULL
)
RETURNS TABLE(
    "SettingId" BIGINT, "Module" VARCHAR, "SettingKey" VARCHAR,
    "SettingValue" TEXT, "ValueType" VARCHAR, "Description" VARCHAR,
    "IsReadOnly" BOOLEAN, "UpdatedAt" TIMESTAMP
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT s."SettingId", s."Module", s."SettingKey",
           s."SettingValue", s."ValueType", s."Description",
           s."IsReadOnly", s."UpdatedAt"
    FROM   cfg."AppSetting" s
    WHERE  s."CompanyId" = p_company_id
      AND  (p_module IS NULL OR s."Module" = p_module)
    ORDER BY s."Module", s."SettingKey";
END;
$$;

-- usp_Cfg_AppSetting_Upsert: insertar o actualizar configuración
DROP FUNCTION IF EXISTS usp_Cfg_AppSetting_Upsert(INT, VARCHAR(60), VARCHAR(128), TEXT, VARCHAR(30), VARCHAR(500), INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_Cfg_AppSetting_Upsert(
    p_company_id    INT,
    p_module        VARCHAR(60),
    p_setting_key   VARCHAR(128),
    p_setting_value TEXT,
    p_value_type    VARCHAR(30) DEFAULT NULL,
    p_description   VARCHAR(500) DEFAULT NULL,
    p_user_id       INT DEFAULT NULL
)
RETURNS TABLE("Resultado" INT, "Mensaje" TEXT)
LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO cfg."AppSetting"
        ("CompanyId", "Module", "SettingKey", "SettingValue", "ValueType",
         "Description", "UpdatedAt", "UpdatedByUserId")
    VALUES
        (p_company_id, p_module, p_setting_key, p_setting_value, p_value_type,
         p_description, NOW() AT TIME ZONE 'UTC', p_user_id)
    ON CONFLICT ("CompanyId", "Module", "SettingKey")
    DO UPDATE SET
        "SettingValue"     = EXCLUDED."SettingValue",
        "ValueType"        = COALESCE(EXCLUDED."ValueType", cfg."AppSetting"."ValueType"),
        "Description"      = COALESCE(EXCLUDED."Description", cfg."AppSetting"."Description"),
        "UpdatedAt"        = NOW() AT TIME ZONE 'UTC',
        "UpdatedByUserId"  = EXCLUDED."UpdatedByUserId";

    RETURN QUERY SELECT 0, 'Configuracion guardada correctamente.'::TEXT;

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -1, SQLERRM::TEXT;
END;
$$;

-- usp_Cfg_AppSetting_ListModules: lista módulos distintos
DROP FUNCTION IF EXISTS usp_Cfg_AppSetting_ListModules(INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_Cfg_AppSetting_ListModules(
    p_company_id INT
)
RETURNS TABLE("Module" VARCHAR)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT DISTINCT s."Module"
    FROM   cfg."AppSetting" s
    WHERE  s."CompanyId" = p_company_id
    ORDER BY s."Module";
END;
$$;

-- usp_Cfg_AppSetting_ListValueTypes: lista tipos de valor
DROP FUNCTION IF EXISTS usp_Cfg_AppSetting_ListValueTypes() CASCADE;
CREATE OR REPLACE FUNCTION usp_Cfg_AppSetting_ListValueTypes()
RETURNS TABLE("ValueType" VARCHAR)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT DISTINCT s."ValueType"
    FROM   cfg."AppSetting" s
    WHERE  s."ValueType" IS NOT NULL
    ORDER BY s."ValueType";
END;
$$;
