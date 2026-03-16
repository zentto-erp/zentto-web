-- =============================================================================
--  Archivo : usp_acct_templates.sql  (PostgreSQL)
--  Auto-convertido desde T-SQL (SQL Server) a PL/pgSQL
--  Fecha de conversion: 2026-03-16
--  Fuente original: web/api/sqlweb/includes/sp/usp_acct_templates.sql
--
--  Esquema : acct (plantillas de reportes legales)
--  Funciones (5):
--    usp_Acct_ReportTemplate_List, usp_Acct_ReportTemplate_Get,
--    usp_Acct_ReportTemplate_Upsert, usp_Acct_ReportTemplate_Delete,
--    usp_Acct_ReportTemplate_Render
-- =============================================================================

-- =============================================================================
--  SP 1: usp_Acct_ReportTemplate_List
-- =============================================================================
CREATE OR REPLACE FUNCTION usp_Acct_ReportTemplate_List(
    p_company_id   INTEGER,
    p_country_code CHAR(2)       DEFAULT NULL,
    p_report_code  VARCHAR(50)   DEFAULT NULL,
    OUT p_total_count INTEGER
)
RETURNS SETOF RECORD
LANGUAGE plpgsql
AS $$
BEGIN
    SELECT COUNT(*)
    INTO p_total_count
    FROM acct."ReportTemplate"
    WHERE "CompanyId" = p_company_id
      AND "IsActive"  = TRUE
      AND (p_country_code IS NULL OR "CountryCode" = p_country_code)
      AND (p_report_code  IS NULL OR "ReportCode"  = p_report_code);

    RETURN QUERY
    SELECT "ReportTemplateId",
           "CountryCode",
           "ReportCode",
           "ReportName",
           "LegalFramework",
           "LegalReference",
           "IsDefault",
           "Version",
           "CreatedAt",
           "UpdatedAt"
    FROM acct."ReportTemplate"
    WHERE "CompanyId" = p_company_id
      AND "IsActive"  = TRUE
      AND (p_country_code IS NULL OR "CountryCode" = p_country_code)
      AND (p_report_code  IS NULL OR "ReportCode"  = p_report_code)
    ORDER BY "CountryCode", "ReportCode";
END;
$$;

-- =============================================================================
--  SP 2: usp_Acct_ReportTemplate_Get
-- =============================================================================
CREATE OR REPLACE FUNCTION usp_Acct_ReportTemplate_Get(
    p_company_id        INTEGER,
    p_report_template_id INTEGER
)
RETURNS SETOF RECORD
LANGUAGE plpgsql
AS $$
BEGIN
    -- Recordset 1: cabecera
    RETURN QUERY
    SELECT "ReportTemplateId", "CountryCode", "ReportCode", "ReportName",
           "LegalFramework", "LegalReference", "TemplateContent",
           "HeaderJson", "FooterJson", "IsDefault", "Version",
           "CreatedAt", "UpdatedAt"
    FROM acct."ReportTemplate"
    WHERE "ReportTemplateId" = p_report_template_id
      AND "CompanyId"        = p_company_id;
END;
$$;

-- Function for variables sub-query (second recordset)
CREATE OR REPLACE FUNCTION usp_Acct_ReportTemplate_Get_Variables(
    p_report_template_id INTEGER
)
RETURNS TABLE(
    "VariableId"        INTEGER,
    "VariableName"      VARCHAR(100),
    "VariableType"      VARCHAR(20),
    "DataSource"        VARCHAR(200),
    "DefaultValue"      VARCHAR(500),
    "Description"       VARCHAR(300),
    "SortOrder"         INTEGER
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT "VariableId", "VariableName", "VariableType", "DataSource",
           "DefaultValue", "Description", "SortOrder"
    FROM acct."ReportTemplateVariable"
    WHERE "ReportTemplateId" = p_report_template_id
    ORDER BY "SortOrder";
END;
$$;

-- =============================================================================
--  SP 3: usp_Acct_ReportTemplate_Upsert
-- =============================================================================
CREATE OR REPLACE FUNCTION usp_Acct_ReportTemplate_Upsert(
    p_company_id        INTEGER,
    p_report_template_id INTEGER       DEFAULT NULL,
    p_country_code      CHAR(2)        DEFAULT NULL,
    p_report_code       VARCHAR(50)    DEFAULT NULL,
    p_report_name       VARCHAR(200)   DEFAULT NULL,
    p_legal_framework   VARCHAR(50)    DEFAULT NULL,
    p_legal_reference   VARCHAR(300)   DEFAULT NULL,
    p_template_content  TEXT           DEFAULT NULL,
    p_header_json       TEXT           DEFAULT NULL,
    p_footer_json       TEXT           DEFAULT NULL,
    p_user_id           INTEGER        DEFAULT NULL,
    OUT p_resultado      INTEGER,
    OUT p_mensaje        TEXT
)
RETURNS RECORD
LANGUAGE plpgsql
AS $$
DECLARE
    v_new_id INTEGER;
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    IF p_report_template_id IS NOT NULL AND EXISTS (
        SELECT 1 FROM acct."ReportTemplate"
        WHERE "ReportTemplateId" = p_report_template_id
          AND "CompanyId"        = p_company_id
    ) THEN
        UPDATE acct."ReportTemplate"
        SET "ReportName"      = COALESCE(p_report_name,      "ReportName"),
            "LegalFramework"  = COALESCE(p_legal_framework,  "LegalFramework"),
            "LegalReference"  = COALESCE(p_legal_reference,  "LegalReference"),
            "TemplateContent" = COALESCE(p_template_content, "TemplateContent"),
            "HeaderJson"      = COALESCE(p_header_json,      "HeaderJson"),
            "FooterJson"      = COALESCE(p_footer_json,      "FooterJson"),
            "Version"         = "Version" + 1,
            "UpdatedAt"       = (NOW() AT TIME ZONE 'UTC')
        WHERE "ReportTemplateId" = p_report_template_id;

        p_resultado := 1;
        p_mensaje   := 'Plantilla actualizada correctamente.';
    ELSE
        IF p_country_code IS NULL OR p_report_code IS NULL OR p_report_name IS NULL OR p_template_content IS NULL THEN
            p_mensaje := 'CountryCode, ReportCode, ReportName y TemplateContent son obligatorios para crear.';
            RETURN;
        END IF;

        INSERT INTO acct."ReportTemplate" (
            "CompanyId", "CountryCode", "ReportCode", "ReportName",
            "LegalFramework", "LegalReference", "TemplateContent",
            "HeaderJson", "FooterJson", "CreatedByUserId"
        )
        VALUES (
            p_company_id, p_country_code, p_report_code, p_report_name,
            COALESCE(p_legal_framework, 'VEN-NIF'), p_legal_reference, p_template_content,
            p_header_json, p_footer_json, p_user_id
        )
        RETURNING "ReportTemplateId" INTO v_new_id;

        p_resultado := 1;
        p_mensaje   := 'Plantilla creada. ID: ' || v_new_id::TEXT;
    END IF;
END;
$$;

-- =============================================================================
--  SP 4: usp_Acct_ReportTemplate_Delete
-- =============================================================================
CREATE OR REPLACE FUNCTION usp_Acct_ReportTemplate_Delete(
    p_company_id        INTEGER,
    p_report_template_id INTEGER,
    OUT p_resultado      INTEGER,
    OUT p_mensaje        TEXT
)
RETURNS RECORD
LANGUAGE plpgsql
AS $$
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    IF NOT EXISTS (
        SELECT 1 FROM acct."ReportTemplate"
        WHERE "ReportTemplateId" = p_report_template_id
          AND "CompanyId"        = p_company_id
    ) THEN
        p_mensaje := 'Plantilla no encontrada.';
        RETURN;
    END IF;

    UPDATE acct."ReportTemplate"
    SET "IsActive"  = FALSE,
        "UpdatedAt" = (NOW() AT TIME ZONE 'UTC')
    WHERE "ReportTemplateId" = p_report_template_id;

    p_resultado := 1;
    p_mensaje   := 'Plantilla eliminada correctamente.';
END;
$$;

-- =============================================================================
--  SP 5: usp_Acct_ReportTemplate_Render
--  Descripcion : Retorna los datos para renderizar una plantilla.
--    Retorna cabecera de plantilla + datos de empresa para variables comunes.
--  Nota PG: retorna solo la plantilla. Para datos de empresa y variables
--           usar usp_Acct_ReportTemplate_Render_Company y
--           usp_Acct_ReportTemplate_Get_Variables.
-- =============================================================================
CREATE OR REPLACE FUNCTION usp_Acct_ReportTemplate_Render(
    p_company_id        INTEGER,
    p_report_template_id INTEGER,
    p_fecha_desde       DATE DEFAULT NULL,
    p_fecha_hasta       DATE DEFAULT NULL,
    p_fecha_corte       DATE DEFAULT NULL
)
RETURNS TABLE(
    "ReportTemplateId"  INTEGER,
    "CountryCode"       CHAR(2),
    "ReportCode"        VARCHAR(50),
    "ReportName"        VARCHAR(200),
    "LegalFramework"    VARCHAR(50),
    "LegalReference"    VARCHAR(300),
    "TemplateContent"   TEXT,
    "HeaderJson"        TEXT,
    "FooterJson"        TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Recordset 1: plantilla
    RETURN QUERY
    SELECT "ReportTemplateId", "CountryCode", "ReportCode", "ReportName",
           "LegalFramework", "LegalReference", "TemplateContent",
           "HeaderJson", "FooterJson"
    FROM acct."ReportTemplate"
    WHERE "ReportTemplateId" = p_report_template_id
      AND "CompanyId"        = p_company_id;
END;
$$;

-- Datos de empresa para render (segundo recordset)
CREATE OR REPLACE FUNCTION usp_Acct_ReportTemplate_Render_Company(
    p_company_id        INTEGER,
    p_fecha_desde       DATE DEFAULT NULL,
    p_fecha_hasta       DATE DEFAULT NULL,
    p_fecha_corte       DATE DEFAULT NULL
)
RETURNS TABLE(
    "CompanyId"      INTEGER,
    "CompanyCode"    VARCHAR(20),
    "companyName"    VARCHAR(200),
    "companyRIF"     VARCHAR(50),
    "companyNIF"     VARCHAR(50),
    "companyAddress" TEXT,
    "companyCountry" CHAR(2),
    "reportDate"     DATE,
    "fechaDesde"     DATE,
    "fechaHasta"     DATE,
    "currency"       VARCHAR(3)
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT c."CompanyId",
           c."CompanyCode",
           c."LegalName"    AS "companyName",
           c."FiscalId"     AS "companyRIF",
           c."FiscalId"     AS "companyNIF",
           b."AddressLine"  AS "companyAddress",
           c."FiscalCountryCode" AS "companyCountry",
           COALESCE(p_fecha_corte, p_fecha_hasta) AS "reportDate",
           p_fecha_desde    AS "fechaDesde",
           p_fecha_hasta    AS "fechaHasta",
           c."BaseCurrency" AS "currency"
    FROM cfg."Company" c
    LEFT JOIN cfg."Branch" b ON b."CompanyId" = c."CompanyId" AND b."IsActive" = TRUE
    WHERE c."CompanyId" = p_company_id;
END;
$$;
