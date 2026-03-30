-- ============================================================
-- usp_zsys_studio.sql — Studio Addons CRUD
-- Schema: zsys | Naming: usp_zsys_StudioAddon_*
-- ============================================================

-- List: addons de una empresa, opcionalmente filtrados por módulo
DROP FUNCTION IF EXISTS usp_zsys_StudioAddon_List(INT, VARCHAR, INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_zsys_StudioAddon_List(
    p_company_id    INT,
    p_module_id     VARCHAR(50)  DEFAULT NULL,
    p_page          INT          DEFAULT 1,
    p_page_size     INT          DEFAULT 50
)
RETURNS TABLE(
    "AddonId"       VARCHAR(50),
    "Title"         VARCHAR(200),
    "Description"   VARCHAR(500),
    "Icon"          VARCHAR(10),
    "Modules"       TEXT,
    "CreatedBy"     INT,
    "CreatedAt"     TIMESTAMP,
    "UpdatedAt"     TIMESTAMP,
    "TotalCount"    INT
)
LANGUAGE plpgsql AS $$
DECLARE
    v_total INT;
    v_offset INT := (GREATEST(p_page, 1) - 1) * p_page_size;
BEGIN
    SELECT COUNT(DISTINCT a."AddonId") INTO v_total
    FROM zsys."StudioAddon" a
    LEFT JOIN zsys."StudioAddonModule" m ON m."AddonId" = a."AddonId"
    WHERE a."CompanyId" = p_company_id
      AND a."IsActive" = TRUE
      AND (p_module_id IS NULL OR m."ModuleId" = p_module_id);

    RETURN QUERY
    SELECT
        a."AddonId",
        a."Title",
        a."Description",
        a."Icon",
        (SELECT STRING_AGG(sm."ModuleId", ',') FROM zsys."StudioAddonModule" sm WHERE sm."AddonId" = a."AddonId")::TEXT AS "Modules",
        a."CreatedBy",
        a."CreatedAt",
        a."UpdatedAt",
        v_total
    FROM zsys."StudioAddon" a
    LEFT JOIN zsys."StudioAddonModule" m ON m."AddonId" = a."AddonId"
    WHERE a."CompanyId" = p_company_id
      AND a."IsActive" = TRUE
      AND (p_module_id IS NULL OR m."ModuleId" = p_module_id)
    GROUP BY a."AddonId", a."Title", a."Description", a."Icon", a."CreatedBy", a."CreatedAt", a."UpdatedAt"
    ORDER BY a."UpdatedAt" DESC
    LIMIT p_page_size OFFSET v_offset;
END;
$$;

-- Get: obtener un addon por AddonId (incluye Config)
DROP FUNCTION IF EXISTS usp_zsys_StudioAddon_Get(INT, VARCHAR) CASCADE;
CREATE OR REPLACE FUNCTION usp_zsys_StudioAddon_Get(
    p_company_id    INT,
    p_addon_id      VARCHAR(50)
)
RETURNS TABLE(
    "AddonId"       VARCHAR(50),
    "Title"         VARCHAR(200),
    "Description"   VARCHAR(500),
    "Icon"          VARCHAR(10),
    "Config"        TEXT,
    "Modules"       TEXT,
    "CreatedBy"     INT,
    "CreatedAt"     TIMESTAMP,
    "UpdatedAt"     TIMESTAMP
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        a."AddonId",
        a."Title",
        a."Description",
        a."Icon",
        a."Config",
        (SELECT STRING_AGG(sm."ModuleId", ',') FROM zsys."StudioAddonModule" sm WHERE sm."AddonId" = a."AddonId")::TEXT AS "Modules",
        a."CreatedBy",
        a."CreatedAt",
        a."UpdatedAt"
    FROM zsys."StudioAddon" a
    WHERE a."CompanyId" = p_company_id
      AND a."AddonId" = p_addon_id
      AND a."IsActive" = TRUE;
END;
$$;

-- Save: inserta o actualiza addon + sus módulos
DROP FUNCTION IF EXISTS usp_zsys_StudioAddon_Save(INT, VARCHAR, VARCHAR, VARCHAR, VARCHAR, TEXT, INT, TEXT) CASCADE;
CREATE OR REPLACE FUNCTION usp_zsys_StudioAddon_Save(
    p_company_id    INT,
    p_addon_id      VARCHAR(50),
    p_title         VARCHAR(200),
    p_description   VARCHAR(500) DEFAULT NULL,
    p_icon          VARCHAR(10)  DEFAULT NULL,
    p_config        TEXT         DEFAULT '{}',
    p_created_by    INT          DEFAULT 0,
    p_modules       TEXT         DEFAULT NULL
)
RETURNS TABLE("ok" BOOLEAN, "mensaje" VARCHAR, "AddonId" VARCHAR)
LANGUAGE plpgsql AS $$
DECLARE
    v_is_new BOOLEAN := FALSE;
    v_module TEXT;
BEGIN
    IF EXISTS (SELECT 1 FROM zsys."StudioAddon" WHERE "AddonId" = p_addon_id AND "CompanyId" = p_company_id) THEN
        UPDATE zsys."StudioAddon" SET
            "Title" = p_title,
            "Description" = p_description,
            "Icon" = p_icon,
            "Config" = p_config,
            "UpdatedAt" = NOW() AT TIME ZONE 'UTC',
            "IsActive" = TRUE
        WHERE "AddonId" = p_addon_id AND "CompanyId" = p_company_id;
    ELSE
        v_is_new := TRUE;
        INSERT INTO zsys."StudioAddon" ("AddonId", "CompanyId", "Title", "Description", "Icon", "Config", "CreatedBy")
        VALUES (p_addon_id, p_company_id, p_title, p_description, p_icon, p_config, p_created_by);
    END IF;

    DELETE FROM zsys."StudioAddonModule" WHERE "AddonId" = p_addon_id;
    IF p_modules IS NOT NULL AND p_modules <> '' THEN
        FOREACH v_module IN ARRAY STRING_TO_ARRAY(p_modules, ',')
        LOOP
            INSERT INTO zsys."StudioAddonModule" ("AddonId", "ModuleId")
            VALUES (p_addon_id, TRIM(v_module));
        END LOOP;
    END IF;

    RETURN QUERY SELECT TRUE, (CASE WHEN v_is_new THEN 'Addon creado' ELSE 'Addon actualizado' END)::VARCHAR, p_addon_id;
END;
$$;

-- Delete: soft delete
DROP FUNCTION IF EXISTS usp_zsys_StudioAddon_Delete(INT, VARCHAR) CASCADE;
CREATE OR REPLACE FUNCTION usp_zsys_StudioAddon_Delete(
    p_company_id    INT,
    p_addon_id      VARCHAR(50)
)
RETURNS TABLE("ok" BOOLEAN, "mensaje" VARCHAR)
LANGUAGE plpgsql AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM zsys."StudioAddon" WHERE "AddonId" = p_addon_id AND "CompanyId" = p_company_id AND "IsActive" = TRUE) THEN
        RETURN QUERY SELECT FALSE, 'Addon no encontrado'::VARCHAR;
        RETURN;
    END IF;

    UPDATE zsys."StudioAddon" SET "IsActive" = FALSE, "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
    WHERE "AddonId" = p_addon_id AND "CompanyId" = p_company_id;

    DELETE FROM zsys."StudioAddonModule" WHERE "AddonId" = p_addon_id;

    RETURN QUERY SELECT TRUE, 'Addon eliminado'::VARCHAR;
END;
$$;
