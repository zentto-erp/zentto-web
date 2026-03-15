/* ============================================================================
 *  usp_util.sql  (PostgreSQL)
 *  ---------------------------------------------------------------------------
 *  Funciones utilitarias: Config, Fiscal, Sistema, Maestros, Retenciones,
 *  Empleados, Supervisor Biometric, Supervisor Override, Payment Engine,
 *  CRUD Generico, Inventario Cache, Metadata, Scope, Auth-Security, Bancos, Media.
 *
 *  Traducido de SQL Server -> PostgreSQL.
 *  Patron: CREATE OR REPLACE FUNCTION (idempotente)
 * ============================================================================ */

-- ============================================================================
-- 1. CONFIG: usp_cfg_exchangerate_upsert
-- ============================================================================
CREATE OR REPLACE FUNCTION usp_cfg_exchangerate_upsert(
    p_rate_date    DATE,
    p_tasa_usd     NUMERIC(18,6),
    p_tasa_eur     NUMERIC(18,6),
    p_source_name  VARCHAR(120)
)
RETURNS VOID
LANGUAGE plpgsql AS $$
BEGIN
    -- USD
    INSERT INTO cfg."ExchangeRateDaily" ("CurrencyCode", "RateToBase", "RateDate", "SourceName")
    VALUES ('USD', p_tasa_usd, p_rate_date, p_source_name)
    ON CONFLICT ("CurrencyCode", "RateDate")
    DO UPDATE SET "RateToBase" = EXCLUDED."RateToBase", "SourceName" = EXCLUDED."SourceName";

    -- EUR
    INSERT INTO cfg."ExchangeRateDaily" ("CurrencyCode", "RateToBase", "RateDate", "SourceName")
    VALUES ('EUR', p_tasa_eur, p_rate_date, p_source_name)
    ON CONFLICT ("CurrencyCode", "RateDate")
    DO UPDATE SET "RateToBase" = EXCLUDED."RateToBase", "SourceName" = EXCLUDED."SourceName";
END;
$$;

-- ============================================================================
-- 2. FISCAL: usp_cfg_fiscal_hastable
-- ============================================================================
CREATE OR REPLACE FUNCTION usp_cfg_fiscal_hastable()
RETURNS TABLE("hasTable" INT)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT CASE WHEN EXISTS(
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = 'fiscal' AND table_name = 'CountryConfig'
    ) THEN 1 ELSE 0 END;
END;
$$;

-- ============================================================================
-- 2b. FISCAL: usp_cfg_fiscal_hasrecordstable
-- ============================================================================
CREATE OR REPLACE FUNCTION usp_cfg_fiscal_hasrecordstable()
RETURNS TABLE("hasTable" INT)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT CASE WHEN EXISTS(
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = 'fiscal' AND table_name = 'Record'
    ) THEN 1 ELSE 0 END;
END;
$$;

-- ============================================================================
-- 2c. FISCAL: usp_cfg_fiscal_getlatestrecord
-- ============================================================================
CREATE OR REPLACE FUNCTION usp_cfg_fiscal_getlatestrecord(
    p_empresa_id   INT,
    p_sucursal_id  INT,
    p_country_code VARCHAR(10)
)
RETURNS TABLE(
    "Id" BIGINT, "InvoiceId" INT, "CountryCode" VARCHAR,
    "InvoiceType" VARCHAR, "XmlContent" TEXT,
    "RecordHash" VARCHAR, "PreviousRecordHash" VARCHAR,
    "DigitalSignature" TEXT, "QRCodeData" TEXT,
    "SentToAuthority" BOOLEAN, "AuthorityResponse" TEXT,
    "CreatedAt" TIMESTAMP
)
LANGUAGE plpgsql AS $$
BEGIN
    -- Verificar existencia de tabla dinamicamente no es posible de forma simple en PG
    -- Se asume que la tabla existe (el caller verifica con usp_cfg_fiscal_hasrecordstable)
    RETURN QUERY
    SELECT
        fr."FiscalRecordId", fr."InvoiceId", fr."CountryCode",
        fr."InvoiceType", fr."XmlContent",
        fr."RecordHash", fr."PreviousRecordHash",
        fr."DigitalSignature", fr."QRCodeData",
        fr."SentToAuthority", fr."AuthorityResponse",
        fr."CreatedAt"
    FROM fiscal."Record" fr
    WHERE fr."CompanyId"   = p_empresa_id
      AND fr."BranchId"    = p_sucursal_id
      AND fr."CountryCode" = p_country_code
    ORDER BY fr."FiscalRecordId" DESC
    LIMIT 1;
END;
$$;

-- ============================================================================
-- 2d. FISCAL: usp_cfg_fiscal_infercountry
-- ============================================================================
CREATE OR REPLACE FUNCTION usp_cfg_fiscal_infercountry(
    p_empresa_id  INT,
    p_sucursal_id INT
)
RETURNS TABLE("CountryCode" VARCHAR)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT fc."CountryCode"
    FROM fiscal."CountryConfig" fc
    WHERE fc."CompanyId" = p_empresa_id
      AND fc."BranchId"  = p_sucursal_id
      AND fc."IsActive"  = TRUE
    ORDER BY fc."UpdatedAt" DESC, fc."CountryConfigId" DESC
    LIMIT 1;
END;
$$;

-- ============================================================================
-- 2e. FISCAL: usp_cfg_fiscal_getconfig
-- ============================================================================
CREATE OR REPLACE FUNCTION usp_cfg_fiscal_getconfig(
    p_empresa_id   INT,
    p_sucursal_id  INT,
    p_country_code VARCHAR(10)
)
RETURNS TABLE(
    "EmpresaId" INT, "SucursalId" INT, "CountryCode" VARCHAR,
    "Currency" VARCHAR, "TaxRegime" VARCHAR, "DefaultTaxCode" VARCHAR,
    "DefaultTaxRate" NUMERIC, "FiscalPrinterEnabled" BOOLEAN,
    "PrinterBrand" VARCHAR, "PrinterPort" VARCHAR,
    "VerifactuEnabled" BOOLEAN, "VerifactuMode" VARCHAR,
    "CertificatePath" VARCHAR, "CertificatePassword" VARCHAR,
    "AEATEndpoint" VARCHAR, "SenderNIF" VARCHAR, "SenderRIF" VARCHAR,
    "SoftwareId" VARCHAR, "SoftwareName" VARCHAR, "SoftwareVersion" VARCHAR,
    "PosEnabled" BOOLEAN, "RestaurantEnabled" BOOLEAN
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        fc."CompanyId", fc."BranchId", fc."CountryCode",
        fc."Currency", fc."TaxRegime", fc."DefaultTaxCode",
        fc."DefaultTaxRate", fc."FiscalPrinterEnabled",
        fc."PrinterBrand", fc."PrinterPort",
        fc."VerifactuEnabled", fc."VerifactuMode",
        fc."CertificatePath", fc."CertificatePassword",
        fc."AEATEndpoint", fc."SenderNIF", fc."SenderRIF",
        fc."SoftwareId", fc."SoftwareName", fc."SoftwareVersion",
        fc."PosEnabled", fc."RestaurantEnabled"
    FROM fiscal."CountryConfig" fc
    WHERE fc."CompanyId"   = p_empresa_id
      AND fc."BranchId"    = p_sucursal_id
      AND fc."CountryCode" = p_country_code
    LIMIT 1;
END;
$$;

-- ============================================================================
-- 2f. FISCAL: usp_cfg_fiscal_upsertconfig
-- ============================================================================
CREATE OR REPLACE FUNCTION usp_cfg_fiscal_upsertconfig(
    p_empresa_id             INT,
    p_sucursal_id            INT,
    p_country_code           VARCHAR(10),
    p_currency               VARCHAR(10),
    p_tax_regime             VARCHAR(60),
    p_default_tax_code       VARCHAR(30),
    p_default_tax_rate       NUMERIC(18,6),
    p_fiscal_printer_enabled BOOLEAN,
    p_printer_brand          VARCHAR(60)   DEFAULT NULL,
    p_printer_port           VARCHAR(60)   DEFAULT NULL,
    p_verifactu_enabled      BOOLEAN       DEFAULT FALSE,
    p_verifactu_mode         VARCHAR(20)   DEFAULT NULL,
    p_certificate_path       VARCHAR(500)  DEFAULT NULL,
    p_certificate_password   VARCHAR(500)  DEFAULT NULL,
    p_aeat_endpoint          VARCHAR(500)  DEFAULT NULL,
    p_sender_nif             VARCHAR(30)   DEFAULT NULL,
    p_sender_rif             VARCHAR(30)   DEFAULT NULL,
    p_software_id            VARCHAR(60)   DEFAULT NULL,
    p_software_name          VARCHAR(120)  DEFAULT NULL,
    p_software_version       VARCHAR(30)   DEFAULT NULL,
    p_pos_enabled            BOOLEAN       DEFAULT FALSE,
    p_restaurant_enabled     BOOLEAN       DEFAULT FALSE
)
RETURNS TABLE("Affected" INT)
LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO fiscal."CountryConfig" (
        "CompanyId", "BranchId", "CountryCode", "Currency", "TaxRegime",
        "DefaultTaxCode", "DefaultTaxRate", "FiscalPrinterEnabled",
        "PrinterBrand", "PrinterPort", "VerifactuEnabled", "VerifactuMode",
        "CertificatePath", "CertificatePassword", "AEATEndpoint",
        "SenderNIF", "SenderRIF", "SoftwareId", "SoftwareName", "SoftwareVersion",
        "PosEnabled", "RestaurantEnabled", "CreatedAt", "UpdatedAt"
    )
    VALUES (
        p_empresa_id, p_sucursal_id, p_country_code, p_currency, p_tax_regime,
        p_default_tax_code, p_default_tax_rate, p_fiscal_printer_enabled,
        p_printer_brand, p_printer_port, p_verifactu_enabled, p_verifactu_mode,
        p_certificate_path, p_certificate_password, p_aeat_endpoint,
        p_sender_nif, p_sender_rif, p_software_id, p_software_name, p_software_version,
        p_pos_enabled, p_restaurant_enabled, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'
    )
    ON CONFLICT ("CompanyId", "BranchId", "CountryCode")
    DO UPDATE SET
        "Currency"            = EXCLUDED."Currency",
        "TaxRegime"           = EXCLUDED."TaxRegime",
        "DefaultTaxCode"      = EXCLUDED."DefaultTaxCode",
        "DefaultTaxRate"      = EXCLUDED."DefaultTaxRate",
        "FiscalPrinterEnabled"= EXCLUDED."FiscalPrinterEnabled",
        "PrinterBrand"        = EXCLUDED."PrinterBrand",
        "PrinterPort"         = EXCLUDED."PrinterPort",
        "VerifactuEnabled"    = EXCLUDED."VerifactuEnabled",
        "VerifactuMode"       = EXCLUDED."VerifactuMode",
        "CertificatePath"     = EXCLUDED."CertificatePath",
        "CertificatePassword" = EXCLUDED."CertificatePassword",
        "AEATEndpoint"        = EXCLUDED."AEATEndpoint",
        "SenderNIF"           = EXCLUDED."SenderNIF",
        "SenderRIF"           = EXCLUDED."SenderRIF",
        "SoftwareId"          = EXCLUDED."SoftwareId",
        "SoftwareName"        = EXCLUDED."SoftwareName",
        "SoftwareVersion"     = EXCLUDED."SoftwareVersion",
        "PosEnabled"          = EXCLUDED."PosEnabled",
        "RestaurantEnabled"   = EXCLUDED."RestaurantEnabled",
        "UpdatedAt"           = NOW() AT TIME ZONE 'UTC';

    RETURN QUERY SELECT 1;
END;
$$;

-- ============================================================================
-- 2g. FISCAL: usp_cfg_fiscal_insertrecord
-- ============================================================================
CREATE OR REPLACE FUNCTION usp_cfg_fiscal_insertrecord(
    p_empresa_id           INT,
    p_sucursal_id          INT,
    p_country_code         VARCHAR(10),
    p_invoice_id           INT,
    p_invoice_type         VARCHAR(30),
    p_invoice_number       VARCHAR(60),
    p_invoice_date         TIMESTAMP,
    p_recipient_id         VARCHAR(60)   DEFAULT NULL,
    p_total_amount         NUMERIC(18,2) DEFAULT 0,
    p_record_hash          VARCHAR(200)  DEFAULT NULL,
    p_previous_record_hash VARCHAR(200)  DEFAULT NULL,
    p_xml_content          TEXT          DEFAULT NULL,
    p_digital_signature    TEXT          DEFAULT NULL,
    p_qr_code_data         TEXT          DEFAULT NULL,
    p_sent_to_authority    BOOLEAN       DEFAULT FALSE,
    p_sent_at              TIMESTAMP     DEFAULT NULL,
    p_authority_response   TEXT          DEFAULT NULL,
    p_authority_status     VARCHAR(30)   DEFAULT NULL,
    p_fiscal_printer_serial VARCHAR(60)  DEFAULT NULL,
    p_fiscal_control_number VARCHAR(60)  DEFAULT NULL,
    p_z_report_number      INT           DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO fiscal."Record" (
        "CompanyId", "BranchId", "CountryCode",
        "InvoiceId", "InvoiceType", "InvoiceNumber", "InvoiceDate",
        "RecipientId", "TotalAmount", "RecordHash", "PreviousRecordHash",
        "XmlContent", "DigitalSignature", "QRCodeData",
        "SentToAuthority", "SentAt", "AuthorityResponse", "AuthorityStatus",
        "FiscalPrinterSerial", "FiscalControlNumber", "ZReportNumber",
        "CreatedAt"
    ) VALUES (
        p_empresa_id, p_sucursal_id, p_country_code,
        p_invoice_id, p_invoice_type, p_invoice_number, p_invoice_date,
        p_recipient_id, p_total_amount, p_record_hash, p_previous_record_hash,
        p_xml_content, p_digital_signature, p_qr_code_data,
        p_sent_to_authority, p_sent_at, p_authority_response, p_authority_status,
        p_fiscal_printer_serial, p_fiscal_control_number, p_z_report_number,
        NOW() AT TIME ZONE 'UTC'
    );
END;
$$;

-- ============================================================================
-- 3. SISTEMA: usp_sys_notificacion_list
-- ============================================================================
CREATE OR REPLACE FUNCTION usp_sys_notificacion_list(
    p_usuario_id VARCHAR(60) DEFAULT NULL
)
RETURNS TABLE(
    "Id" INT, "Tipo" VARCHAR, "Titulo" VARCHAR, "Mensaje" TEXT,
    "Leido" BOOLEAN, "FechaCreacion" TIMESTAMP, "RutaNavegacion" VARCHAR
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT n."Id", n."Tipo", n."Titulo", n."Mensaje",
           n."Leido", n."FechaCreacion", n."RutaNavegacion"
    FROM "Sys_Notificaciones" n
    WHERE n."UsuarioId" IS NULL OR n."UsuarioId" = p_usuario_id
    ORDER BY n."FechaCreacion" DESC
    LIMIT 50;
END;
$$;

-- ============================================================================
-- 3b. SISTEMA: usp_sys_notificacion_markread
-- ============================================================================
CREATE OR REPLACE FUNCTION usp_sys_notificacion_markread(
    p_ids_csv TEXT
)
RETURNS TABLE("AffectedCount" INT)
LANGUAGE plpgsql AS $$
DECLARE
    v_affected INT;
BEGIN
    UPDATE "Sys_Notificaciones" n
    SET "Leido" = TRUE
    FROM unnest(string_to_array(p_ids_csv, ',')) AS s(val)
    WHERE n."Id" = s.val::INT;

    GET DIAGNOSTICS v_affected = ROW_COUNT;
    RETURN QUERY SELECT v_affected;
END;
$$;

-- ============================================================================
-- 3c. SISTEMA: usp_sys_tarea_list
-- ============================================================================
CREATE OR REPLACE FUNCTION usp_sys_tarea_list(
    p_asignado_a VARCHAR(60) DEFAULT NULL
)
RETURNS TABLE(
    "Id" INT, "Titulo" VARCHAR, "Descripcion" TEXT, "Progreso" INT,
    "Color" VARCHAR, "AsignadoA" VARCHAR, "FechaVencimiento" DATE,
    "Completado" BOOLEAN, "FechaCreacion" TIMESTAMP
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT t."Id", t."Titulo", t."Descripcion", t."Progreso",
           t."Color", t."AsignadoA", t."FechaVencimiento",
           t."Completado", t."FechaCreacion"
    FROM "Sys_Tareas" t
    WHERE (t."AsignadoA" IS NULL OR t."AsignadoA" = p_asignado_a)
      AND t."Completado" = FALSE
    ORDER BY t."FechaCreacion" DESC
    LIMIT 50;
END;
$$;

-- ============================================================================
-- 3d. SISTEMA: usp_sys_tarea_toggle
-- ============================================================================
CREATE OR REPLACE FUNCTION usp_sys_tarea_toggle(
    p_id         INT,
    p_completado BOOLEAN,
    p_progress   INT
)
RETURNS VOID
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE "Sys_Tareas"
    SET "Completado" = p_completado,
        "Progreso"   = p_progress
    WHERE "Id" = p_id;
END;
$$;

-- ============================================================================
-- 3e. SISTEMA: usp_sys_mensaje_list
-- ============================================================================
CREATE OR REPLACE FUNCTION usp_sys_mensaje_list(
    p_destinatario_id VARCHAR(60)
)
RETURNS TABLE(
    "Id" INT, "RemitenteId" VARCHAR, "RemitenteNombre" VARCHAR,
    "Asunto" VARCHAR, "Cuerpo" TEXT, "Leido" BOOLEAN, "FechaEnvio" TIMESTAMP
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT m."Id", m."RemitenteId", m."RemitenteNombre",
           m."Asunto", m."Cuerpo", m."Leido", m."FechaEnvio"
    FROM "Sys_Mensajes" m
    WHERE m."DestinatarioId" = p_destinatario_id
    ORDER BY m."FechaEnvio" DESC
    LIMIT 50;
END;
$$;

-- ============================================================================
-- 3f. SISTEMA: usp_sys_mensaje_markread
-- ============================================================================
CREATE OR REPLACE FUNCTION usp_sys_mensaje_markread(p_id INT)
RETURNS VOID
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE "Sys_Mensajes" SET "Leido" = TRUE WHERE "Id" = p_id;
END;
$$;

-- ============================================================================
-- 5. RETENCIONES: usp_tax_retention_list
-- ============================================================================
CREATE OR REPLACE FUNCTION usp_tax_retention_list(
    p_search VARCHAR(200) DEFAULT NULL,
    p_tipo   VARCHAR(60)  DEFAULT NULL,
    p_offset INT          DEFAULT 0,
    p_limit  INT          DEFAULT 50
)
RETURNS TABLE(
    "RetentionId" INT, "Codigo" VARCHAR, "Descripcion" VARCHAR,
    "Tipo" VARCHAR, "Porcentaje" NUMERIC, "Pais" VARCHAR, "IsActive" BOOLEAN
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        tr."RetentionId", tr."RetentionCode", tr."Description",
        tr."RetentionType", tr."RetentionRate", tr."CountryCode", tr."IsActive"
    FROM master."TaxRetention" tr
    WHERE tr."IsDeleted" = FALSE
      AND (p_search IS NULL OR (tr."RetentionCode" ILIKE '%' || p_search || '%' OR tr."Description" ILIKE '%' || p_search || '%'))
      AND (p_tipo IS NULL OR tr."RetentionType" = p_tipo)
    ORDER BY tr."RetentionCode"
    LIMIT p_limit OFFSET p_offset;
END;
$$;

-- ============================================================================
-- 5b. RETENCIONES: usp_tax_retention_count
-- ============================================================================
CREATE OR REPLACE FUNCTION usp_tax_retention_count(
    p_search VARCHAR(200) DEFAULT NULL,
    p_tipo   VARCHAR(60)  DEFAULT NULL
)
RETURNS TABLE("total" BIGINT)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT COUNT(1)
    FROM master."TaxRetention"
    WHERE "IsDeleted" = FALSE
      AND (p_search IS NULL OR ("RetentionCode" ILIKE '%' || p_search || '%' OR "Description" ILIKE '%' || p_search || '%'))
      AND (p_tipo IS NULL OR "RetentionType" = p_tipo);
END;
$$;

-- ============================================================================
-- 5c. RETENCIONES: usp_tax_retention_getbycode
-- ============================================================================
CREATE OR REPLACE FUNCTION usp_tax_retention_getbycode(p_codigo VARCHAR(60))
RETURNS TABLE(
    "RetentionId" INT, "Codigo" VARCHAR, "Descripcion" VARCHAR,
    "Tipo" VARCHAR, "Porcentaje" NUMERIC, "Pais" VARCHAR, "IsActive" BOOLEAN
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT tr."RetentionId", tr."RetentionCode", tr."Description",
           tr."RetentionType", tr."RetentionRate", tr."CountryCode", tr."IsActive"
    FROM master."TaxRetention" tr
    WHERE tr."RetentionCode" = p_codigo AND tr."IsDeleted" = FALSE
    LIMIT 1;
END;
$$;

-- ============================================================================
-- 6. EMPLEADOS: usp_hr_employee_getdefaultcompany
-- ============================================================================
CREATE OR REPLACE FUNCTION usp_hr_employee_getdefaultcompany()
RETURNS TABLE("CompanyId" INT)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT c."CompanyId"
    FROM cfg."Company" c
    WHERE c."IsDeleted" = FALSE
    ORDER BY CASE WHEN c."CompanyCode" = 'DEFAULT' THEN 0 ELSE 1 END, c."CompanyId"
    LIMIT 1;
END;
$$;

-- ============================================================================
-- 6b. EMPLEADOS: usp_hr_employee_list
-- ============================================================================
CREATE OR REPLACE FUNCTION usp_hr_employee_list(
    p_company_id INT,
    p_search     VARCHAR(200) DEFAULT NULL,
    p_status     VARCHAR(20)  DEFAULT NULL,
    p_offset     INT          DEFAULT 0,
    p_limit      INT          DEFAULT 50
)
RETURNS TABLE(
    "EmployeeCode" VARCHAR, "EmployeeName" VARCHAR, "FiscalId" VARCHAR,
    "HireDate" DATE, "TerminationDate" DATE, "IsActive" BOOLEAN
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT e."EmployeeCode", e."EmployeeName", e."FiscalId",
           e."HireDate", e."TerminationDate", e."IsActive"
    FROM master."Employee" e
    WHERE e."CompanyId" = p_company_id
      AND COALESCE(e."IsDeleted", FALSE) = FALSE
      AND (p_search IS NULL OR (e."EmployeeCode" ILIKE '%' || p_search || '%' OR e."EmployeeName" ILIKE '%' || p_search || '%' OR e."FiscalId" ILIKE '%' || p_search || '%'))
      AND (p_status IS NULL
           OR (p_status = 'ACTIVO' AND e."IsActive" = TRUE)
           OR (p_status = 'INACTIVO' AND e."IsActive" = FALSE))
    ORDER BY e."EmployeeCode"
    LIMIT p_limit OFFSET p_offset;
END;
$$;

-- ============================================================================
-- 6c. EMPLEADOS: usp_hr_employee_count
-- ============================================================================
CREATE OR REPLACE FUNCTION usp_hr_employee_count(
    p_company_id INT,
    p_search     VARCHAR(200) DEFAULT NULL,
    p_status     VARCHAR(20)  DEFAULT NULL
)
RETURNS TABLE("total" BIGINT)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT COUNT(1)
    FROM master."Employee"
    WHERE "CompanyId" = p_company_id
      AND COALESCE("IsDeleted", FALSE) = FALSE
      AND (p_search IS NULL OR ("EmployeeCode" ILIKE '%' || p_search || '%' OR "EmployeeName" ILIKE '%' || p_search || '%' OR "FiscalId" ILIKE '%' || p_search || '%'))
      AND (p_status IS NULL
           OR (p_status = 'ACTIVO' AND "IsActive" = TRUE)
           OR (p_status = 'INACTIVO' AND "IsActive" = FALSE));
END;
$$;

-- ============================================================================
-- 6d. EMPLEADOS: usp_hr_employee_getbycode
-- ============================================================================
CREATE OR REPLACE FUNCTION usp_hr_employee_getbycode(p_company_id INT, p_cedula VARCHAR(60))
RETURNS TABLE("EmployeeCode" VARCHAR, "EmployeeName" VARCHAR, "FiscalId" VARCHAR, "HireDate" DATE, "TerminationDate" DATE, "IsActive" BOOLEAN)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT e."EmployeeCode", e."EmployeeName", e."FiscalId", e."HireDate", e."TerminationDate", e."IsActive"
    FROM master."Employee" e
    WHERE e."CompanyId" = p_company_id AND e."EmployeeCode" = p_cedula AND COALESCE(e."IsDeleted", FALSE) = FALSE
    LIMIT 1;
END;
$$;

-- ============================================================================
-- 6e. EMPLEADOS: usp_hr_employee_existsbycode
-- ============================================================================
CREATE OR REPLACE FUNCTION usp_hr_employee_existsbycode(p_company_id INT, p_code VARCHAR(60))
RETURNS TABLE("EmployeeId" BIGINT)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT e."EmployeeId"
    FROM master."Employee" e
    WHERE e."CompanyId" = p_company_id AND e."EmployeeCode" = p_code AND COALESCE(e."IsDeleted", FALSE) = FALSE
    LIMIT 1;
END;
$$;

-- ============================================================================
-- 6f. EMPLEADOS: usp_hr_employee_insert
-- ============================================================================
CREATE OR REPLACE FUNCTION usp_hr_employee_insert(
    p_company_id       INT,
    p_code             VARCHAR(60),
    p_name             VARCHAR(200),
    p_fiscal_id        VARCHAR(60)  DEFAULT NULL,
    p_hire_date        DATE         DEFAULT NULL,
    p_termination_date DATE         DEFAULT NULL,
    p_is_active        BOOLEAN      DEFAULT TRUE
)
RETURNS VOID
LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO master."Employee"
        ("CompanyId", "EmployeeCode", "EmployeeName", "FiscalId", "HireDate", "TerminationDate", "IsActive", "CreatedAt", "UpdatedAt", "IsDeleted")
    VALUES
        (p_company_id, p_code, p_name, p_fiscal_id, COALESCE(p_hire_date, (NOW() AT TIME ZONE 'UTC')::DATE), p_termination_date, p_is_active, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC', FALSE);
END;
$$;

-- ============================================================================
-- 6g. EMPLEADOS: usp_hr_employee_update
-- ============================================================================
CREATE OR REPLACE FUNCTION usp_hr_employee_update(
    p_company_id       INT,
    p_cedula           VARCHAR(60),
    p_name             VARCHAR(200) DEFAULT NULL,
    p_fiscal_id        VARCHAR(60)  DEFAULT NULL,
    p_hire_date        DATE         DEFAULT NULL,
    p_termination_date DATE         DEFAULT NULL,
    p_is_active        BOOLEAN      DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE master."Employee"
    SET "EmployeeName"   = COALESCE(p_name, "EmployeeName"),
        "FiscalId"       = COALESCE(p_fiscal_id, "FiscalId"),
        "HireDate"       = COALESCE(p_hire_date, "HireDate"),
        "TerminationDate"= COALESCE(p_termination_date, "TerminationDate"),
        "IsActive"       = COALESCE(p_is_active, "IsActive"),
        "UpdatedAt"      = NOW() AT TIME ZONE 'UTC'
    WHERE "CompanyId"    = p_company_id
      AND "EmployeeCode" = p_cedula
      AND COALESCE("IsDeleted", FALSE) = FALSE;
END;
$$;

-- ============================================================================
-- 6h. EMPLEADOS: usp_hr_employee_delete
-- ============================================================================
CREATE OR REPLACE FUNCTION usp_hr_employee_delete(p_company_id INT, p_cedula VARCHAR(60))
RETURNS VOID
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE master."Employee"
    SET "IsDeleted" = TRUE, "IsActive" = FALSE,
        "DeletedAt" = NOW() AT TIME ZONE 'UTC', "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
    WHERE "CompanyId" = p_company_id AND "EmployeeCode" = p_cedula AND COALESCE("IsDeleted", FALSE) = FALSE;
END;
$$;

-- ============================================================================
-- 7. SUPERVISOR BIOMETRIC: usp_sec_supervisor_biometric_hasactive
-- ============================================================================
CREATE OR REPLACE FUNCTION usp_sec_supervisor_biometric_hasactive(
    p_supervisor_user VARCHAR(60),
    p_credential_hash VARCHAR(128)
)
RETURNS TABLE("biometricCredentialId" BIGINT)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT bc."BiometricCredentialId"
    FROM sec."SupervisorBiometricCredential" bc
    WHERE bc."SupervisorUserCode" = p_supervisor_user
      AND bc."CredentialHash"     = p_credential_hash
      AND bc."IsActive" = TRUE
    LIMIT 1;
END;
$$;

-- ============================================================================
-- 7b. SUPERVISOR BIOMETRIC: usp_sec_supervisor_biometric_touch
-- ============================================================================
CREATE OR REPLACE FUNCTION usp_sec_supervisor_biometric_touch(
    p_supervisor_user VARCHAR(60),
    p_credential_hash VARCHAR(128)
)
RETURNS VOID
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE sec."SupervisorBiometricCredential"
    SET "LastValidatedAtUtc" = NOW() AT TIME ZONE 'UTC',
        "UpdatedAtUtc"       = NOW() AT TIME ZONE 'UTC'
    WHERE "SupervisorUserCode" = p_supervisor_user
      AND "CredentialHash"     = p_credential_hash
      AND "IsActive" = TRUE;
END;
$$;

-- ============================================================================
-- 7c. SUPERVISOR BIOMETRIC: usp_sec_supervisor_biometric_enroll
-- ============================================================================
CREATE OR REPLACE FUNCTION usp_sec_supervisor_biometric_enroll(
    p_supervisor_user  VARCHAR(60),
    p_credential_hash  VARCHAR(128),
    p_credential_id    VARCHAR(500),
    p_credential_label VARCHAR(120) DEFAULT NULL,
    p_device_info      VARCHAR(300) DEFAULT NULL,
    p_actor_user       VARCHAR(60)  DEFAULT NULL
)
RETURNS TABLE("biometricCredentialId" BIGINT)
LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO sec."SupervisorBiometricCredential" (
        "SupervisorUserCode", "CredentialHash", "CredentialId",
        "CredentialLabel", "DeviceInfo", "IsActive",
        "LastValidatedAtUtc", "CreatedAtUtc", "UpdatedAtUtc",
        "CreatedByUserCode", "UpdatedByUserCode"
    )
    VALUES (
        p_supervisor_user, p_credential_hash, p_credential_id,
        p_credential_label, p_device_info, TRUE,
        NULL, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC',
        p_actor_user, p_actor_user
    )
    ON CONFLICT ("SupervisorUserCode", "CredentialHash")
    DO UPDATE SET
        "CredentialId"       = EXCLUDED."CredentialId",
        "CredentialLabel"    = EXCLUDED."CredentialLabel",
        "DeviceInfo"         = EXCLUDED."DeviceInfo",
        "IsActive"           = TRUE,
        "UpdatedAtUtc"       = NOW() AT TIME ZONE 'UTC',
        "UpdatedByUserCode"  = p_actor_user;

    RETURN QUERY
    SELECT bc."BiometricCredentialId"
    FROM sec."SupervisorBiometricCredential" bc
    WHERE bc."SupervisorUserCode" = p_supervisor_user
      AND bc."CredentialHash"     = p_credential_hash
    LIMIT 1;
END;
$$;

-- ============================================================================
-- 7d. SUPERVISOR BIOMETRIC: usp_sec_supervisor_biometric_list
-- ============================================================================
CREATE OR REPLACE FUNCTION usp_sec_supervisor_biometric_list(
    p_supervisor_user VARCHAR(60) DEFAULT ''
)
RETURNS TABLE(
    "biometricCredentialId" BIGINT, "supervisorUserCode" VARCHAR,
    "credentialId" VARCHAR, "credentialLabel" VARCHAR,
    "deviceInfo" VARCHAR, "isActive" BOOLEAN, "lastValidatedAtUtc" TEXT
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        bc."BiometricCredentialId", bc."SupervisorUserCode",
        bc."CredentialId", bc."CredentialLabel",
        bc."DeviceInfo", bc."IsActive",
        TO_CHAR(bc."LastValidatedAtUtc", 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"')
    FROM sec."SupervisorBiometricCredential" bc
    WHERE bc."IsActive" = TRUE
      AND (p_supervisor_user = '' OR bc."SupervisorUserCode" = p_supervisor_user)
    ORDER BY bc."BiometricCredentialId" DESC;
END;
$$;

-- ============================================================================
-- 7e. SUPERVISOR BIOMETRIC: usp_sec_supervisor_biometric_deactivate
-- ============================================================================
CREATE OR REPLACE FUNCTION usp_sec_supervisor_biometric_deactivate(
    p_supervisor_user VARCHAR(60),
    p_credential_hash VARCHAR(128),
    p_actor_user      VARCHAR(60)
)
RETURNS TABLE("biometricCredentialId" BIGINT)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    UPDATE sec."SupervisorBiometricCredential"
    SET "IsActive"          = FALSE,
        "UpdatedAtUtc"      = NOW() AT TIME ZONE 'UTC',
        "UpdatedByUserCode" = p_actor_user
    WHERE "SupervisorUserCode" = p_supervisor_user
      AND "CredentialHash"     = p_credential_hash
      AND "IsActive" = TRUE
    RETURNING "BiometricCredentialId";
END;
$$;

-- ============================================================================
-- 8. SUPERVISOR OVERRIDE: usp_sec_supervisor_getrecord
-- ============================================================================
CREATE OR REPLACE FUNCTION usp_sec_supervisor_getrecord(p_supervisor_user VARCHAR(60))
RETURNS TABLE("codUsuario" VARCHAR, "nombre" VARCHAR, "tipo" VARCHAR, "isAdmin" BOOLEAN, "canDelete" BOOLEAN, "passwordHash" VARCHAR)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT u."Cod_Usuario", u."Nombre", u."Tipo", u."IsAdmin", u."Deletes", u."Password"
    FROM "Usuarios" u
    WHERE UPPER(u."Cod_Usuario") = p_supervisor_user
    LIMIT 1;
END;
$$;

-- ============================================================================
-- 8b. SUPERVISOR OVERRIDE: usp_sec_supervisor_override_create
-- ============================================================================
CREATE OR REPLACE FUNCTION usp_sec_supervisor_override_create(
    p_module_code          VARCHAR(60),
    p_action_code          VARCHAR(60),
    p_status               VARCHAR(20),
    p_company_id           INT          DEFAULT NULL,
    p_branch_id            INT          DEFAULT NULL,
    p_requested_by_user    VARCHAR(60)  DEFAULT NULL,
    p_supervisor_user_code VARCHAR(60)  DEFAULT NULL,
    p_reason               VARCHAR(300) DEFAULT NULL,
    p_payload_json         TEXT         DEFAULT NULL
)
RETURNS TABLE("overrideId" INT)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    INSERT INTO sec."SupervisorOverride" (
        "ModuleCode", "ActionCode", "Status",
        "CompanyId", "BranchId",
        "RequestedByUserCode", "SupervisorUserCode",
        "Reason", "PayloadJson", "ApprovedAtUtc"
    )
    VALUES (
        p_module_code, p_action_code, p_status,
        p_company_id, p_branch_id,
        p_requested_by_user, p_supervisor_user_code,
        p_reason, p_payload_json, NOW() AT TIME ZONE 'UTC'
    )
    RETURNING "OverrideId";
END;
$$;

-- ============================================================================
-- 8c. SUPERVISOR OVERRIDE: usp_sec_supervisor_override_consume
-- ============================================================================
CREATE OR REPLACE FUNCTION usp_sec_supervisor_override_consume(
    p_override_id        INT,
    p_module_code        VARCHAR(60),
    p_action_code        VARCHAR(60),
    p_consumed_by_user   VARCHAR(60) DEFAULT NULL,
    p_source_document_id INT         DEFAULT NULL,
    p_source_line_id     INT         DEFAULT NULL,
    p_reversal_line_id   INT         DEFAULT NULL
)
RETURNS TABLE("overrideId" INT)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    UPDATE sec."SupervisorOverride"
    SET "Status"             = 'CONSUMED',
        "ConsumedAtUtc"      = NOW() AT TIME ZONE 'UTC',
        "ConsumedByUserCode" = p_consumed_by_user,
        "SourceDocumentId"   = p_source_document_id,
        "SourceLineId"       = p_source_line_id,
        "ReversalLineId"     = p_reversal_line_id
    WHERE "OverrideId" = p_override_id
      AND "Status" = 'APPROVED'
      AND UPPER("ModuleCode") = p_module_code
      AND UPPER("ActionCode") = p_action_code
    RETURNING "OverrideId";
END;
$$;

-- ============================================================================
-- 9. PAYMENT ENGINE: usp_pay_transaction_resolveconfig
-- ============================================================================
CREATE OR REPLACE FUNCTION usp_pay_transaction_resolveconfig(
    p_empresa_id    INT,
    p_sucursal_id   INT,
    p_provider_code VARCHAR(30)
)
RETURNS SETOF pay."CompanyPaymentConfig"
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT c.*
    FROM pay."CompanyPaymentConfig" c
    JOIN pay."PaymentProviders" p ON p."Id" = c."ProviderId"
    WHERE c."EmpresaId"  = p_empresa_id
      AND c."SucursalId" = p_sucursal_id
      AND p."Code"       = p_provider_code
      AND c."IsActive"   = TRUE;
END;
$$;

-- ============================================================================
-- 9b. PAYMENT ENGINE: usp_pay_transaction_insert
-- ============================================================================
CREATE OR REPLACE FUNCTION usp_pay_transaction_insert(
    p_transaction_uuid    VARCHAR(36),
    p_empresa_id          INT,
    p_sucursal_id         INT,
    p_source_type         VARCHAR(30),
    p_source_id           INT           DEFAULT NULL,
    p_source_number       VARCHAR(50)   DEFAULT NULL,
    p_payment_method_code VARCHAR(30)   DEFAULT NULL,
    p_provider_id         INT           DEFAULT NULL,
    p_currency            VARCHAR(3)    DEFAULT NULL,
    p_amount              NUMERIC(18,2) DEFAULT 0,
    p_trx_type            VARCHAR(20)   DEFAULT NULL,
    p_status              VARCHAR(20)   DEFAULT NULL,
    p_gateway_trx_id      VARCHAR(100)  DEFAULT NULL,
    p_gateway_auth_code   VARCHAR(50)   DEFAULT NULL,
    p_gateway_response    TEXT          DEFAULT NULL,
    p_gateway_message     VARCHAR(500)  DEFAULT NULL,
    p_card_last_four      VARCHAR(4)    DEFAULT NULL,
    p_card_brand          VARCHAR(20)   DEFAULT NULL,
    p_mobile_number       VARCHAR(20)   DEFAULT NULL,
    p_bank_code           VARCHAR(10)   DEFAULT NULL,
    p_payment_ref         VARCHAR(50)   DEFAULT NULL,
    p_station_id          VARCHAR(50)   DEFAULT NULL,
    p_cashier_id          VARCHAR(20)   DEFAULT NULL,
    p_ip_address          VARCHAR(45)   DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO pay."Transactions" (
        "TransactionUUID", "EmpresaId", "SucursalId",
        "SourceType", "SourceId", "SourceNumber",
        "PaymentMethodCode", "ProviderId",
        "Currency", "Amount", "TrxType", "Status",
        "GatewayTrxId", "GatewayAuthCode", "GatewayResponse", "GatewayMessage",
        "CardLastFour", "CardBrand",
        "MobileNumber", "BankCode", "PaymentRef",
        "StationId", "CashierId", "IpAddress"
    ) VALUES (
        p_transaction_uuid, p_empresa_id, p_sucursal_id,
        p_source_type, p_source_id, p_source_number,
        p_payment_method_code, p_provider_id,
        p_currency, p_amount, p_trx_type, p_status,
        p_gateway_trx_id, p_gateway_auth_code, p_gateway_response, p_gateway_message,
        p_card_last_four, p_card_brand,
        p_mobile_number, p_bank_code, p_payment_ref,
        p_station_id, p_cashier_id, p_ip_address
    );
END;
$$;

-- ============================================================================
-- 9c. PAYMENT ENGINE: usp_pay_transaction_updatestatus
-- ============================================================================
CREATE OR REPLACE FUNCTION usp_pay_transaction_updatestatus(
    p_transaction_uuid VARCHAR(36),
    p_status           VARCHAR(20),
    p_gateway_trx_id   VARCHAR(100) DEFAULT NULL,
    p_gateway_auth_code VARCHAR(50) DEFAULT NULL,
    p_gateway_response TEXT         DEFAULT NULL,
    p_gateway_message  VARCHAR(500) DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE pay."Transactions"
    SET "Status"          = p_status,
        "GatewayTrxId"    = COALESCE(p_gateway_trx_id, "GatewayTrxId"),
        "GatewayAuthCode" = COALESCE(p_gateway_auth_code, "GatewayAuthCode"),
        "GatewayResponse" = COALESCE(p_gateway_response, "GatewayResponse"),
        "GatewayMessage"  = COALESCE(p_gateway_message, "GatewayMessage"),
        "UpdatedAt"       = NOW() AT TIME ZONE 'UTC'
    WHERE "TransactionUUID" = p_transaction_uuid;
END;
$$;

-- ============================================================================
-- 9d. PAYMENT ENGINE: usp_pay_transaction_search
-- ============================================================================
CREATE OR REPLACE FUNCTION usp_pay_transaction_search(
    p_empresa_id    INT,
    p_sucursal_id   INT          DEFAULT NULL,
    p_provider_code VARCHAR(30)  DEFAULT NULL,
    p_source_type   VARCHAR(30)  DEFAULT NULL,
    p_source_number VARCHAR(50)  DEFAULT NULL,
    p_status        VARCHAR(20)  DEFAULT NULL,
    p_date_from     TIMESTAMP    DEFAULT NULL,
    p_date_to       TIMESTAMP    DEFAULT NULL,
    p_offset        INT          DEFAULT 0,
    p_limit         INT          DEFAULT 50
)
RETURNS SETOF pay."Transactions"
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT t.*
    FROM pay."Transactions" t
    LEFT JOIN pay."PaymentProviders" p ON p."Id" = t."ProviderId"
    WHERE t."EmpresaId"  = p_empresa_id
      AND (p_sucursal_id   IS NULL OR t."SucursalId"   = p_sucursal_id)
      AND (p_provider_code IS NULL OR p."Code"         = p_provider_code)
      AND (p_source_type   IS NULL OR t."SourceType"   = p_source_type)
      AND (p_source_number IS NULL OR t."SourceNumber" = p_source_number)
      AND (p_status        IS NULL OR t."Status"       = p_status)
      AND (p_date_from     IS NULL OR t."CreatedAt"   >= p_date_from)
      AND (p_date_to       IS NULL OR t."CreatedAt"   <= p_date_to)
    ORDER BY t."CreatedAt" DESC
    LIMIT p_limit OFFSET p_offset;
END;
$$;

-- ============================================================================
-- 9e. PAYMENT ENGINE: usp_pay_transaction_searchcount
-- ============================================================================
CREATE OR REPLACE FUNCTION usp_pay_transaction_searchcount(
    p_empresa_id    INT,
    p_sucursal_id   INT          DEFAULT NULL,
    p_provider_code VARCHAR(30)  DEFAULT NULL,
    p_source_type   VARCHAR(30)  DEFAULT NULL,
    p_source_number VARCHAR(50)  DEFAULT NULL,
    p_status        VARCHAR(20)  DEFAULT NULL,
    p_date_from     TIMESTAMP    DEFAULT NULL,
    p_date_to       TIMESTAMP    DEFAULT NULL
)
RETURNS TABLE("total" BIGINT)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT COUNT(1)
    FROM pay."Transactions" t
    LEFT JOIN pay."PaymentProviders" p ON p."Id" = t."ProviderId"
    WHERE t."EmpresaId"  = p_empresa_id
      AND (p_sucursal_id   IS NULL OR t."SucursalId"   = p_sucursal_id)
      AND (p_provider_code IS NULL OR p."Code"         = p_provider_code)
      AND (p_source_type   IS NULL OR t."SourceType"   = p_source_type)
      AND (p_source_number IS NULL OR t."SourceNumber" = p_source_number)
      AND (p_status        IS NULL OR t."Status"       = p_status)
      AND (p_date_from     IS NULL OR t."CreatedAt"   >= p_date_from)
      AND (p_date_to       IS NULL OR t."CreatedAt"   <= p_date_to);
END;
$$;

-- ============================================================================
-- 11. INVENTARIO CACHE: usp_inventario_cacheload
-- ============================================================================
CREATE OR REPLACE FUNCTION usp_inventario_cacheload(p_company_id INT)
RETURNS TABLE(
    "ProductId" BIGINT, "ProductCode" VARCHAR, "ProductName" VARCHAR,
    "CategoryCode" VARCHAR, "UnitCode" VARCHAR,
    "SalesPrice" NUMERIC, "CostPrice" NUMERIC, "DefaultTaxRate" NUMERIC,
    "StockQty" NUMERIC, "IsService" BOOLEAN, "IsDeleted" BOOLEAN, "UpdatedAt" TIMESTAMP
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT p."ProductId", p."ProductCode", p."ProductName",
           p."CategoryCode", p."UnitCode",
           p."SalesPrice", p."CostPrice", p."DefaultTaxRate",
           p."StockQty", p."IsService", p."IsDeleted", p."UpdatedAt"
    FROM master."Product" p
    WHERE p."CompanyId" = p_company_id
    ORDER BY p."ProductCode";
END;
$$;

-- ============================================================================
-- 11b. INVENTARIO CACHE: usp_inventario_getbycode
-- ============================================================================
CREATE OR REPLACE FUNCTION usp_inventario_getbycode(p_company_id INT, p_codigo VARCHAR(60))
RETURNS TABLE(
    "ProductId" BIGINT, "ProductCode" VARCHAR, "ProductName" VARCHAR,
    "CategoryCode" VARCHAR, "UnitCode" VARCHAR,
    "SalesPrice" NUMERIC, "CostPrice" NUMERIC, "DefaultTaxRate" NUMERIC,
    "StockQty" NUMERIC, "IsService" BOOLEAN, "IsDeleted" BOOLEAN, "UpdatedAt" TIMESTAMP
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT p."ProductId", p."ProductCode", p."ProductName",
           p."CategoryCode", p."UnitCode",
           p."SalesPrice", p."CostPrice", p."DefaultTaxRate",
           p."StockQty", p."IsService", p."IsDeleted", p."UpdatedAt"
    FROM master."Product" p
    WHERE p."CompanyId" = p_company_id AND p."ProductCode" = p_codigo
    LIMIT 1;
END;
$$;

-- ============================================================================
-- 13. METADATA: usp_sys_metadata_tables
-- ============================================================================
CREATE OR REPLACE FUNCTION usp_sys_metadata_tables()
RETURNS TABLE("TABLE_SCHEMA" VARCHAR, "TABLE_NAME" VARCHAR)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT t.table_schema::VARCHAR, t.table_name::VARCHAR
    FROM information_schema.tables t
    WHERE t.table_type = 'BASE TABLE'
      AND t.table_schema NOT IN ('pg_catalog', 'information_schema')
    ORDER BY t.table_schema, t.table_name;
END;
$$;

-- ============================================================================
-- 13b. METADATA: usp_sys_metadata_columns
-- ============================================================================
CREATE OR REPLACE FUNCTION usp_sys_metadata_columns()
RETURNS TABLE(
    "TABLE_SCHEMA" VARCHAR, "TABLE_NAME" VARCHAR, "COLUMN_NAME" VARCHAR,
    "DATA_TYPE" VARCHAR, "IS_NULLABLE" VARCHAR,
    "is_identity" INT, "is_computed" INT
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        c.table_schema::VARCHAR, c.table_name::VARCHAR, c.column_name::VARCHAR,
        c.data_type::VARCHAR, c.is_nullable::VARCHAR,
        CASE WHEN c.column_default LIKE 'nextval%' THEN 1 ELSE 0 END,
        CASE WHEN c.is_generated = 'ALWAYS' THEN 1 ELSE 0 END
    FROM information_schema.columns c
    WHERE c.table_schema NOT IN ('pg_catalog', 'information_schema')
    ORDER BY c.table_schema, c.table_name, c.ordinal_position;
END;
$$;

-- ============================================================================
-- 13c. METADATA: usp_sys_metadata_primarykeys
-- ============================================================================
CREATE OR REPLACE FUNCTION usp_sys_metadata_primarykeys()
RETURNS TABLE("TABLE_SCHEMA" VARCHAR, "TABLE_NAME" VARCHAR, "COLUMN_NAME" VARCHAR, "ORDINAL_POSITION" INT)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        ku.table_schema::VARCHAR, ku.table_name::VARCHAR,
        ku.column_name::VARCHAR, ku.ordinal_position::INT
    FROM information_schema.table_constraints tc
    JOIN information_schema.key_column_usage ku
      ON tc.constraint_name = ku.constraint_name
      AND tc.table_schema = ku.table_schema
      AND tc.table_name = ku.table_name
    WHERE tc.constraint_type = 'PRIMARY KEY'
    ORDER BY ku.table_schema, ku.table_name, ku.ordinal_position;
END;
$$;

-- ============================================================================
-- 15. SCOPE: usp_cfg_scope_getdefault
-- ============================================================================
CREATE OR REPLACE FUNCTION usp_cfg_scope_getdefault()
RETURNS TABLE("companyId" INT, "branchId" INT, "systemUserId" INT)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT c."CompanyId", b."BranchId", su."UserId"
    FROM cfg."Company" c
    INNER JOIN cfg."Branch" b ON b."CompanyId" = c."CompanyId" AND b."BranchCode" = 'MAIN'
    LEFT JOIN sec."User" su ON su."UserCode" = 'SYSTEM'
    WHERE c."CompanyCode" = 'DEFAULT'
    ORDER BY c."CompanyId", b."BranchId"
    LIMIT 1;
END;
$$;

-- ============================================================================
-- 15b. SCOPE: usp_cfg_scope_getdefaultcompanyuser
-- ============================================================================
CREATE OR REPLACE FUNCTION usp_cfg_scope_getdefaultcompanyuser()
RETURNS TABLE("companyId" INT, "systemUserId" INT)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT c."CompanyId", su."UserId"
    FROM cfg."Company" c
    LEFT JOIN sec."User" su ON su."UserCode" = 'SYSTEM'
    WHERE c."CompanyCode" = 'DEFAULT'
    ORDER BY c."CompanyId"
    LIMIT 1;
END;
$$;

-- ============================================================================
-- 15c. USER: usp_sec_user_resolvebycode
-- ============================================================================
CREATE OR REPLACE FUNCTION usp_sec_user_resolvebycode(p_code VARCHAR(60))
RETURNS TABLE("userId" INT)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT u."UserId" FROM sec."User" u WHERE UPPER(u."UserCode") = UPPER(p_code) ORDER BY u."UserId" LIMIT 1;
END;
$$;

-- ============================================================================
-- 15d. USER: usp_sec_user_resolvebycodeactive
-- ============================================================================
CREATE OR REPLACE FUNCTION usp_sec_user_resolvebycodeactive(p_code VARCHAR(60))
RETURNS TABLE("userId" INT)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT u."UserId" FROM sec."User" u
    WHERE UPPER(u."UserCode") = UPPER(p_code) AND u."IsDeleted" = FALSE AND u."IsActive" = TRUE
    ORDER BY u."UserId" LIMIT 1;
END;
$$;

-- ============================================================================
-- 16. BANCOS: usp_fin_bank_list
-- ============================================================================
CREATE OR REPLACE FUNCTION usp_fin_bank_list(
    p_company_id INT,
    p_search     VARCHAR(100) DEFAULT NULL,
    p_offset     INT DEFAULT 0,
    p_limit      INT DEFAULT 50
)
RETURNS TABLE("TotalCount" BIGINT, "Nombre" VARCHAR, "Contacto" VARCHAR, "Direccion" VARCHAR, "Telefonos" VARCHAR)
LANGUAGE plpgsql AS $$
DECLARE v_total BIGINT;
BEGIN
    SELECT COUNT(1) INTO v_total FROM fin."Bank"
    WHERE "CompanyId" = p_company_id AND "IsActive" = TRUE
      AND (p_search IS NULL OR "BankName" ILIKE p_search OR "ContactName" ILIKE p_search);

    RETURN QUERY
    SELECT v_total, b."BankName", b."ContactName", b."AddressLine", b."Phones"
    FROM fin."Bank" b
    WHERE b."CompanyId" = p_company_id AND b."IsActive" = TRUE
      AND (p_search IS NULL OR b."BankName" ILIKE p_search OR b."ContactName" ILIKE p_search)
    ORDER BY b."BankName"
    LIMIT p_limit OFFSET p_offset;
END;
$$;

-- ============================================================================
-- 16b. BANCOS: usp_fin_bank_getbyname
-- ============================================================================
CREATE OR REPLACE FUNCTION usp_fin_bank_getbyname(p_company_id INT, p_bank_name VARCHAR(100))
RETURNS TABLE("Nombre" VARCHAR, "Contacto" VARCHAR, "Direccion" VARCHAR, "Telefonos" VARCHAR)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT b."BankName", b."ContactName", b."AddressLine", b."Phones"
    FROM fin."Bank" b
    WHERE b."CompanyId" = p_company_id AND b."IsActive" = TRUE AND b."BankName" = p_bank_name
    ORDER BY b."BankId" DESC LIMIT 1;
END;
$$;

-- ============================================================================
-- 16c. BANCOS: usp_fin_bank_insert
-- ============================================================================
CREATE OR REPLACE FUNCTION usp_fin_bank_insert(
    p_company_id  INT, p_bank_code VARCHAR(30), p_bank_name VARCHAR(100),
    p_contact_name VARCHAR(100) DEFAULT NULL, p_address_line VARCHAR(255) DEFAULT NULL,
    p_phones VARCHAR(100) DEFAULT NULL, p_user_id INT DEFAULT NULL
)
RETURNS TABLE("Success" BOOLEAN, "Message" TEXT)
LANGUAGE plpgsql AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM fin."Bank" WHERE "CompanyId" = p_company_id AND "BankName" = p_bank_name) THEN
        RETURN QUERY SELECT FALSE, 'Banco ya existe'::TEXT;
        RETURN;
    END IF;

    INSERT INTO fin."Bank" ("CompanyId", "BankCode", "BankName", "ContactName", "AddressLine", "Phones", "IsActive", "CreatedByUserId", "UpdatedByUserId")
    VALUES (p_company_id, p_bank_code, p_bank_name, p_contact_name, p_address_line, p_phones, TRUE, p_user_id, p_user_id);

    RETURN QUERY SELECT TRUE, 'Banco creado'::TEXT;
END;
$$;

-- ============================================================================
-- 16d. BANCOS: usp_fin_bank_update
-- ============================================================================
CREATE OR REPLACE FUNCTION usp_fin_bank_update(
    p_company_id INT, p_bank_name VARCHAR(100),
    p_contact_name VARCHAR(100) DEFAULT NULL, p_address_line VARCHAR(255) DEFAULT NULL,
    p_phones VARCHAR(100) DEFAULT NULL, p_user_id INT DEFAULT NULL
)
RETURNS TABLE("Success" BOOLEAN, "Message" TEXT)
LANGUAGE plpgsql AS $$
DECLARE v_affected INT;
BEGIN
    UPDATE fin."Bank"
    SET "ContactName" = COALESCE(p_contact_name, "ContactName"),
        "AddressLine" = COALESCE(p_address_line, "AddressLine"),
        "Phones"      = COALESCE(p_phones, "Phones"),
        "UpdatedAt"   = NOW() AT TIME ZONE 'UTC',
        "UpdatedByUserId" = p_user_id
    WHERE "CompanyId" = p_company_id AND "BankName" = p_bank_name AND "IsActive" = TRUE;

    GET DIAGNOSTICS v_affected = ROW_COUNT;
    IF v_affected <= 0 THEN
        RETURN QUERY SELECT FALSE, 'Banco no encontrado'::TEXT;
    ELSE
        RETURN QUERY SELECT TRUE, 'Banco actualizado'::TEXT;
    END IF;
END;
$$;

-- ============================================================================
-- 16e. BANCOS: usp_fin_bank_delete
-- ============================================================================
CREATE OR REPLACE FUNCTION usp_fin_bank_delete(p_company_id INT, p_bank_name VARCHAR(100), p_user_id INT DEFAULT NULL)
RETURNS TABLE("Success" BOOLEAN, "Message" TEXT)
LANGUAGE plpgsql AS $$
DECLARE v_affected INT;
BEGIN
    UPDATE fin."Bank"
    SET "IsActive" = FALSE, "UpdatedAt" = NOW() AT TIME ZONE 'UTC', "UpdatedByUserId" = p_user_id
    WHERE "CompanyId" = p_company_id AND "BankName" = p_bank_name AND "IsActive" = TRUE;

    GET DIAGNOSTICS v_affected = ROW_COUNT;
    IF v_affected <= 0 THEN
        RETURN QUERY SELECT FALSE, 'Banco no encontrado'::TEXT;
    ELSE
        RETURN QUERY SELECT TRUE, 'Banco eliminado'::TEXT;
    END IF;
END;
$$;

-- ============================================================================
-- 17. MEDIA: usp_cfg_mediaasset_insert
-- ============================================================================
CREATE OR REPLACE FUNCTION usp_cfg_mediaasset_insert(
    p_company_id INT, p_branch_id INT,
    p_storage_key VARCHAR(500), p_public_url VARCHAR(1000),
    p_original_file_name VARCHAR(255) DEFAULT NULL, p_mime_type VARCHAR(100) DEFAULT NULL,
    p_file_extension VARCHAR(20) DEFAULT NULL, p_file_size_bytes BIGINT DEFAULT 0,
    p_checksum_sha256 VARCHAR(64) DEFAULT NULL, p_alt_text VARCHAR(500) DEFAULT NULL,
    p_actor_user_id INT DEFAULT NULL
)
RETURNS TABLE("mediaAssetId" INT)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    INSERT INTO cfg."MediaAsset" (
        "CompanyId", "BranchId", "StorageProvider", "StorageKey", "PublicUrl",
        "OriginalFileName", "MimeType", "FileExtension", "FileSizeBytes",
        "ChecksumSha256", "AltText", "CreatedByUserId", "UpdatedByUserId"
    )
    VALUES (
        p_company_id, p_branch_id, 'LOCAL', p_storage_key, p_public_url,
        p_original_file_name, p_mime_type, p_file_extension, p_file_size_bytes,
        p_checksum_sha256, p_alt_text, p_actor_user_id, p_actor_user_id
    )
    RETURNING "MediaAssetId";
END;
$$;

-- ============================================================================
-- 17b. MEDIA: usp_cfg_mediaasset_getbyid
-- ============================================================================
CREATE OR REPLACE FUNCTION usp_cfg_mediaasset_getbyid(p_company_id INT, p_branch_id INT, p_media_asset_id INT)
RETURNS TABLE("mediaAssetId" INT, "storageKey" VARCHAR, "publicUrl" VARCHAR, "mimeType" VARCHAR, "originalFileName" VARCHAR, "fileSizeBytes" BIGINT, "isActive" BOOLEAN, "isDeleted" BOOLEAN)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT ma."MediaAssetId", ma."StorageKey", ma."PublicUrl", ma."MimeType", ma."OriginalFileName", ma."FileSizeBytes", ma."IsActive", ma."IsDeleted"
    FROM cfg."MediaAsset" ma
    WHERE ma."CompanyId" = p_company_id AND ma."BranchId" = p_branch_id AND ma."MediaAssetId" = p_media_asset_id
    LIMIT 1;
END;
$$;

-- ============================================================================
-- 17c. MEDIA: usp_cfg_mediaasset_getbystoragekey
-- ============================================================================
CREATE OR REPLACE FUNCTION usp_cfg_mediaasset_getbystoragekey(p_company_id INT, p_branch_id INT, p_storage_key VARCHAR(500))
RETURNS TABLE("mediaAssetId" INT)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT ma."MediaAssetId"
    FROM cfg."MediaAsset" ma
    WHERE ma."CompanyId" = p_company_id AND ma."BranchId" = p_branch_id AND ma."StorageKey" = p_storage_key AND ma."IsDeleted" = FALSE AND ma."IsActive" = TRUE
    ORDER BY ma."MediaAssetId" DESC LIMIT 1;
END;
$$;

-- ============================================================================
-- 17d. MEDIA: usp_cfg_entityimage_link
-- ============================================================================
CREATE OR REPLACE FUNCTION usp_cfg_entityimage_link(
    p_company_id INT, p_branch_id INT, p_entity_type VARCHAR(50), p_entity_id INT,
    p_media_asset_id INT, p_role_code VARCHAR(30) DEFAULT NULL,
    p_sort_order INT DEFAULT 0, p_is_primary BOOLEAN DEFAULT FALSE, p_actor_user_id INT DEFAULT NULL
)
RETURNS TABLE("entityImageId" INT, "entityType" VARCHAR, "entityId" INT, "mediaAssetId" INT, "roleCode" VARCHAR, "sortOrder" INT, "isPrimary" BOOLEAN, "publicUrl" VARCHAR, "mimeType" VARCHAR)
LANGUAGE plpgsql AS $$
BEGIN
    IF p_is_primary THEN
        UPDATE cfg."EntityImage"
        SET "IsPrimary" = FALSE, "UpdatedAt" = NOW() AT TIME ZONE 'UTC', "UpdatedByUserId" = p_actor_user_id
        WHERE "CompanyId" = p_company_id AND "BranchId" = p_branch_id AND "EntityType" = p_entity_type AND "EntityId" = p_entity_id AND "IsDeleted" = FALSE AND "IsActive" = TRUE;
    END IF;

    INSERT INTO cfg."EntityImage" ("CompanyId", "BranchId", "EntityType", "EntityId", "MediaAssetId", "RoleCode", "SortOrder", "IsPrimary", "CreatedByUserId", "UpdatedByUserId")
    VALUES (p_company_id, p_branch_id, p_entity_type, p_entity_id, p_media_asset_id, p_role_code, p_sort_order, p_is_primary, p_actor_user_id, p_actor_user_id)
    ON CONFLICT ("CompanyId", "BranchId", "EntityType", "EntityId", "MediaAssetId")
    DO UPDATE SET
        "RoleCode"  = EXCLUDED."RoleCode",
        "SortOrder" = EXCLUDED."SortOrder",
        "IsPrimary" = CASE WHEN p_is_primary THEN TRUE ELSE cfg."EntityImage"."IsPrimary" END,
        "IsActive"  = TRUE,
        "IsDeleted" = FALSE,
        "UpdatedAt" = NOW() AT TIME ZONE 'UTC',
        "UpdatedByUserId" = p_actor_user_id;

    RETURN QUERY
    SELECT ei."EntityImageId", ei."EntityType", ei."EntityId", ei."MediaAssetId", ei."RoleCode", ei."SortOrder", ei."IsPrimary", ma."PublicUrl", ma."MimeType"
    FROM cfg."EntityImage" ei
    INNER JOIN cfg."MediaAsset" ma ON ma."MediaAssetId" = ei."MediaAssetId"
    WHERE ei."CompanyId" = p_company_id AND ei."BranchId" = p_branch_id AND ei."EntityType" = p_entity_type AND ei."EntityId" = p_entity_id AND ei."MediaAssetId" = p_media_asset_id AND ei."IsDeleted" = FALSE AND ei."IsActive" = TRUE AND ma."IsDeleted" = FALSE AND ma."IsActive" = TRUE
    ORDER BY ei."EntityImageId" DESC LIMIT 1;
END;
$$;

-- ============================================================================
-- 17e. MEDIA: usp_cfg_entityimage_list
-- ============================================================================
CREATE OR REPLACE FUNCTION usp_cfg_entityimage_list(p_company_id INT, p_branch_id INT, p_entity_type VARCHAR(50), p_entity_id INT)
RETURNS TABLE("entityImageId" INT, "entityType" VARCHAR, "entityId" INT, "mediaAssetId" INT, "roleCode" VARCHAR, "sortOrder" INT, "isPrimary" BOOLEAN, "publicUrl" VARCHAR, "originalFileName" VARCHAR, "mimeType" VARCHAR, "fileSizeBytes" BIGINT, "altText" VARCHAR, "createdAt" TIMESTAMP)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT ei."EntityImageId", ei."EntityType", ei."EntityId", ei."MediaAssetId", ei."RoleCode", ei."SortOrder", ei."IsPrimary", ma."PublicUrl", ma."OriginalFileName", ma."MimeType", ma."FileSizeBytes", ma."AltText", ma."CreatedAt"
    FROM cfg."EntityImage" ei
    INNER JOIN cfg."MediaAsset" ma ON ma."MediaAssetId" = ei."MediaAssetId"
    WHERE ei."CompanyId" = p_company_id AND ei."BranchId" = p_branch_id AND ei."EntityType" = p_entity_type AND ei."EntityId" = p_entity_id AND ei."IsDeleted" = FALSE AND ei."IsActive" = TRUE AND ma."IsDeleted" = FALSE AND ma."IsActive" = TRUE
    ORDER BY CASE WHEN ei."IsPrimary" THEN 0 ELSE 1 END, ei."SortOrder", ei."EntityImageId";
END;
$$;

-- ============================================================================
-- 17f. MEDIA: usp_cfg_entityimage_setprimary
-- ============================================================================
CREATE OR REPLACE FUNCTION usp_cfg_entityimage_setprimary(p_company_id INT, p_branch_id INT, p_entity_type VARCHAR(50), p_entity_id INT, p_entity_image_id INT, p_actor_user_id INT DEFAULT NULL)
RETURNS TABLE("affected" INT)
LANGUAGE plpgsql AS $$
DECLARE v_affected INT;
BEGIN
    UPDATE cfg."EntityImage" SET "IsPrimary" = FALSE, "UpdatedAt" = NOW() AT TIME ZONE 'UTC', "UpdatedByUserId" = p_actor_user_id
    WHERE "CompanyId" = p_company_id AND "BranchId" = p_branch_id AND "EntityType" = p_entity_type AND "EntityId" = p_entity_id AND "IsDeleted" = FALSE AND "IsActive" = TRUE;

    UPDATE cfg."EntityImage" SET "IsPrimary" = TRUE, "UpdatedAt" = NOW() AT TIME ZONE 'UTC', "UpdatedByUserId" = p_actor_user_id
    WHERE "CompanyId" = p_company_id AND "BranchId" = p_branch_id AND "EntityType" = p_entity_type AND "EntityId" = p_entity_id AND "EntityImageId" = p_entity_image_id AND "IsDeleted" = FALSE AND "IsActive" = TRUE;

    GET DIAGNOSTICS v_affected = ROW_COUNT;
    RETURN QUERY SELECT v_affected;
END;
$$;

-- ============================================================================
-- 17g. MEDIA: usp_cfg_entityimage_unlink
-- ============================================================================
CREATE OR REPLACE FUNCTION usp_cfg_entityimage_unlink(p_company_id INT, p_branch_id INT, p_entity_type VARCHAR(50), p_entity_id INT, p_entity_image_id INT, p_actor_user_id INT DEFAULT NULL)
RETURNS TABLE("ok" INT)
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE cfg."EntityImage"
    SET "IsActive" = FALSE, "IsDeleted" = TRUE, "IsPrimary" = FALSE, "UpdatedAt" = NOW() AT TIME ZONE 'UTC', "UpdatedByUserId" = p_actor_user_id
    WHERE "CompanyId" = p_company_id AND "BranchId" = p_branch_id AND "EntityType" = p_entity_type AND "EntityId" = p_entity_id AND "EntityImageId" = p_entity_image_id AND "IsDeleted" = FALSE;

    -- Auto-promote si no queda ninguno primary
    IF NOT EXISTS (
        SELECT 1 FROM cfg."EntityImage"
        WHERE "CompanyId" = p_company_id AND "BranchId" = p_branch_id AND "EntityType" = p_entity_type AND "EntityId" = p_entity_id AND "IsDeleted" = FALSE AND "IsActive" = TRUE AND "IsPrimary" = TRUE
    ) THEN
        UPDATE cfg."EntityImage"
        SET "IsPrimary" = TRUE, "UpdatedAt" = NOW() AT TIME ZONE 'UTC', "UpdatedByUserId" = p_actor_user_id
        WHERE "EntityImageId" = (
            SELECT ei."EntityImageId" FROM cfg."EntityImage" ei
            WHERE ei."CompanyId" = p_company_id AND ei."BranchId" = p_branch_id AND ei."EntityType" = p_entity_type AND ei."EntityId" = p_entity_id AND ei."IsDeleted" = FALSE AND ei."IsActive" = TRUE
            ORDER BY ei."SortOrder", ei."EntityImageId" LIMIT 1
        );
    END IF;

    RETURN QUERY SELECT 1;
END;
$$;

-- ============================================================================
-- 18. AUTH-SECURITY: usp_sec_authstore_check
-- ============================================================================
CREATE OR REPLACE FUNCTION usp_sec_authstore_check()
RETURNS TABLE("hasStore" INT)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT CASE
      WHEN EXISTS(SELECT 1 FROM information_schema.tables WHERE table_schema = 'sec' AND table_name = 'AuthIdentity')
       AND EXISTS(SELECT 1 FROM information_schema.tables WHERE table_schema = 'sec' AND table_name = 'AuthToken')
      THEN 1 ELSE 0 END;
END;
$$;

-- ============================================================================
-- 18b. AUTH-SECURITY: usp_sec_auth_userexistslegacy
-- ============================================================================
CREATE OR REPLACE FUNCTION usp_sec_auth_userexistslegacy(p_user_code VARCHAR(60))
RETURNS TABLE("existsFlag" INT)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT CASE WHEN EXISTS (SELECT 1 FROM "Usuarios" WHERE UPPER("Cod_Usuario") = UPPER(p_user_code)) THEN 1 ELSE 0 END;
END;
$$;

-- ============================================================================
-- 18c. AUTH-SECURITY: usp_sec_auth_emailexists
-- ============================================================================
CREATE OR REPLACE FUNCTION usp_sec_auth_emailexists(p_email_normalized VARCHAR(200))
RETURNS TABLE("existsFlag" INT)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT CASE WHEN EXISTS (SELECT 1 FROM sec."AuthIdentity" WHERE "EmailNormalized" = p_email_normalized) THEN 1 ELSE 0 END;
END;
$$;

-- ============================================================================
-- 18d. AUTH-SECURITY: usp_sec_authidentity_upsert
-- ============================================================================
CREATE OR REPLACE FUNCTION usp_sec_authidentity_upsert(
    p_user_code VARCHAR(60), p_email VARCHAR(200), p_email_normalized VARCHAR(200), p_pending BOOLEAN
)
RETURNS VOID
LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO sec."AuthIdentity" (
        "UserCode", "Email", "EmailNormalized", "EmailVerifiedAtUtc",
        "IsRegistrationPending", "FailedLoginCount", "CreatedAtUtc", "UpdatedAtUtc"
    )
    VALUES (
        p_user_code, p_email, p_email_normalized,
        CASE WHEN p_pending THEN NULL ELSE NOW() AT TIME ZONE 'UTC' END,
        p_pending, 0, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'
    )
    ON CONFLICT ("UserCode")
    DO UPDATE SET
        "Email" = EXCLUDED."Email",
        "EmailNormalized" = EXCLUDED."EmailNormalized",
        "IsRegistrationPending" = p_pending,
        "EmailVerifiedAtUtc" = CASE WHEN p_pending THEN NULL ELSE COALESCE(sec."AuthIdentity"."EmailVerifiedAtUtc", NOW() AT TIME ZONE 'UTC') END,
        "UpdatedAtUtc" = NOW() AT TIME ZONE 'UTC';
END;
$$;

-- ============================================================================
-- 18e. AUTH-SECURITY: usp_sec_authtoken_issue
-- ============================================================================
CREATE OR REPLACE FUNCTION usp_sec_authtoken_issue(
    p_user_code VARCHAR(60), p_token_type VARCHAR(30), p_token_hash VARCHAR(64),
    p_email_normalized VARCHAR(200), p_ttl_minutes INT,
    p_ip VARCHAR(50) DEFAULT NULL, p_user_agent VARCHAR(500) DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO sec."AuthToken" ("UserCode", "TokenType", "TokenHash", "EmailNormalized", "ExpiresAtUtc", "MetaIp", "MetaUserAgent")
    VALUES (p_user_code, p_token_type, p_token_hash, p_email_normalized, (NOW() AT TIME ZONE 'UTC') + (p_ttl_minutes || ' minutes')::INTERVAL, p_ip, p_user_agent);
END;
$$;

-- ============================================================================
-- 18f. AUTH-SECURITY: usp_sec_auth_getloginsecuritystate
-- ============================================================================
CREATE OR REPLACE FUNCTION usp_sec_auth_getloginsecuritystate(p_user_code VARCHAR(60))
RETURNS TABLE("IsRegistrationPending" BOOLEAN, "EmailVerifiedAtUtc" TIMESTAMP, "LockoutUntilUtc" TIMESTAMP)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT ai."IsRegistrationPending", ai."EmailVerifiedAtUtc", ai."LockoutUntilUtc"
    FROM sec."AuthIdentity" ai WHERE UPPER(ai."UserCode") = UPPER(p_user_code) LIMIT 1;
END;
$$;

-- ============================================================================
-- 18g. AUTH-SECURITY: usp_sec_auth_registerloginfailure
-- ============================================================================
CREATE OR REPLACE FUNCTION usp_sec_auth_registerloginfailure(
    p_user_code VARCHAR(60), p_ip VARCHAR(50) DEFAULT NULL, p_max_attempts INT DEFAULT 5, p_lockout_minutes INT DEFAULT 15
)
RETURNS VOID
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE sec."AuthIdentity"
    SET "FailedLoginCount" = COALESCE("FailedLoginCount", 0) + 1,
        "LastFailedLoginAtUtc" = NOW() AT TIME ZONE 'UTC',
        "LastFailedLoginIp" = p_ip,
        "LockoutUntilUtc" = CASE
            WHEN COALESCE("FailedLoginCount", 0) + 1 >= p_max_attempts
              THEN (NOW() AT TIME ZONE 'UTC') + (p_lockout_minutes || ' minutes')::INTERVAL
            ELSE "LockoutUntilUtc"
        END,
        "UpdatedAtUtc" = NOW() AT TIME ZONE 'UTC'
    WHERE UPPER("UserCode") = UPPER(p_user_code);
END;
$$;

-- ============================================================================
-- 18h. AUTH-SECURITY: usp_sec_auth_registerloginsuccess
-- ============================================================================
CREATE OR REPLACE FUNCTION usp_sec_auth_registerloginsuccess(p_user_code VARCHAR(60))
RETURNS VOID
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE sec."AuthIdentity"
    SET "FailedLoginCount" = 0, "LastLoginAtUtc" = NOW() AT TIME ZONE 'UTC', "LockoutUntilUtc" = NULL, "UpdatedAtUtc" = NOW() AT TIME ZONE 'UTC'
    WHERE UPPER("UserCode") = UPPER(p_user_code);
END;
$$;

-- ============================================================================
-- 18i. AUTH-SECURITY: usp_sec_auth_consumetoken
-- ============================================================================
CREATE OR REPLACE FUNCTION usp_sec_auth_consumetoken(p_token_hash VARCHAR(64), p_token_type VARCHAR(30))
RETURNS TABLE("UserCode" VARCHAR, "EmailNormalized" VARCHAR)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    UPDATE sec."AuthToken"
    SET "ConsumedAtUtc" = NOW() AT TIME ZONE 'UTC'
    WHERE "TokenId" = (
        SELECT "TokenId" FROM sec."AuthToken"
        WHERE "TokenHash" = p_token_hash AND "TokenType" = p_token_type
          AND "ConsumedAtUtc" IS NULL AND "ExpiresAtUtc" >= NOW() AT TIME ZONE 'UTC'
        ORDER BY "TokenId" DESC LIMIT 1
    )
    RETURNING sec."AuthToken"."UserCode", sec."AuthToken"."EmailNormalized";
END;
$$;

-- ============================================================================
-- 18j. AUTH-SECURITY: usp_sec_auth_verifyemail
-- ============================================================================
CREATE OR REPLACE FUNCTION usp_sec_auth_verifyemail(p_user_code VARCHAR(60))
RETURNS VOID
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE sec."AuthIdentity"
    SET "IsRegistrationPending" = FALSE, "EmailVerifiedAtUtc" = NOW() AT TIME ZONE 'UTC',
        "FailedLoginCount" = 0, "LockoutUntilUtc" = NULL, "UpdatedAtUtc" = NOW() AT TIME ZONE 'UTC'
    WHERE UPPER("UserCode") = UPPER(p_user_code);
END;
$$;

-- ============================================================================
-- 18k. AUTH-SECURITY: usp_sec_auth_resolvebyidentifier
-- ============================================================================
CREATE OR REPLACE FUNCTION usp_sec_auth_resolvebyidentifier(p_user_code VARCHAR(60), p_email_normalized VARCHAR(200), p_is_email BOOLEAN)
RETURNS TABLE("UserCode" VARCHAR, "Email" VARCHAR, "EmailNormalized" VARCHAR, "IsRegistrationPending" BOOLEAN, "EmailVerifiedAtUtc" TIMESTAMP)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT ai."UserCode", ai."Email", ai."EmailNormalized", ai."IsRegistrationPending", ai."EmailVerifiedAtUtc"
    FROM sec."AuthIdentity" ai
    WHERE CASE WHEN p_is_email THEN ai."EmailNormalized" = p_email_normalized
               ELSE UPPER(ai."UserCode") = UPPER(p_user_code) END
    LIMIT 1;
END;
$$;

-- ============================================================================
-- 18l. AUTH-SECURITY: usp_sec_auth_invalidatetokens
-- ============================================================================
CREATE OR REPLACE FUNCTION usp_sec_auth_invalidatetokens(p_user_code VARCHAR(60), p_token_type VARCHAR(30))
RETURNS VOID
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE sec."AuthToken"
    SET "ConsumedAtUtc" = COALESCE("ConsumedAtUtc", NOW() AT TIME ZONE 'UTC')
    WHERE UPPER("UserCode") = UPPER(p_user_code) AND "TokenType" = p_token_type AND "ConsumedAtUtc" IS NULL;
END;
$$;

-- ============================================================================
-- 18m. AUTH-SECURITY: usp_sec_auth_registeruser
-- ============================================================================
CREATE OR REPLACE FUNCTION usp_sec_auth_registeruser(p_user_code VARCHAR(60), p_password_hash VARCHAR(200), p_nombre VARCHAR(100))
RETURNS VOID
LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO "Usuarios" ("Cod_Usuario", "Password", "Nombre", "Tipo", "Updates", "Addnews", "Deletes", "Creador", "Cambiar", "PrecioMinimo", "Credito", "IsAdmin")
    VALUES (p_user_code, p_password_hash, p_nombre, 'USER', TRUE, TRUE, FALSE, FALSE, TRUE, FALSE, FALSE, FALSE);
END;
$$;

-- ============================================================================
-- 18n. AUTH-SECURITY: usp_sec_auth_updatepassword
-- ============================================================================
CREATE OR REPLACE FUNCTION usp_sec_auth_updatepassword(p_user_code VARCHAR(60), p_password_hash VARCHAR(200))
RETURNS VOID
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE "Usuarios" SET "Password" = p_password_hash WHERE UPPER("Cod_Usuario") = UPPER(p_user_code);
END;
$$;
