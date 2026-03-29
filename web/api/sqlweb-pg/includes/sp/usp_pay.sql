/* ============================================================================
 *  usp_pay.sql  (PostgreSQL)
 *  ---------------------------------------------------------------------------
 *  Funciones para gestion de configuracion de medios de pago,
 *  proveedores, capacidades, configuracion por empresa y dispositivos lectores.
 *
 *  Traducido de SQL Server -> PostgreSQL.
 *  Patron: DROP FUNCTION IF EXISTS (idempotente)
 * ============================================================================ */

-- =============================================================================
--  1: usp_pay_method_list
-- =============================================================================
DROP FUNCTION IF EXISTS usp_pay_method_list(CHAR(2)) CASCADE;
CREATE OR REPLACE FUNCTION usp_pay_method_list(
    p_country_code CHAR(2) DEFAULT NULL
)
RETURNS TABLE(
    "Id" INT, "Code" VARCHAR, "Name" VARCHAR, "Category" VARCHAR,
    "CountryCode" VARCHAR, "IconName" VARCHAR, "RequiresGateway" BOOLEAN,
    "IsActive" BOOLEAN, "SortOrder" INT
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT pm."Id", pm."Code", pm."Name", pm."Category",
           pm."CountryCode"::VARCHAR, pm."IconName", pm."RequiresGateway",
           pm."IsActive", pm."SortOrder"
    FROM pay."PaymentMethods" pm
    WHERE pm."IsActive" = TRUE
      AND (p_country_code IS NULL
            OR pm."CountryCode" = p_country_code
            OR pm."CountryCode" IS NULL)
    ORDER BY pm."SortOrder", pm."Name";
END;
$$;

-- =============================================================================
--  2: usp_pay_method_upsert
-- =============================================================================
DROP FUNCTION IF EXISTS usp_pay_method_upsert(VARCHAR(30), VARCHAR(100), CHAR(2), VARCHAR(30), BOOLEAN) CASCADE;
CREATE OR REPLACE FUNCTION usp_pay_method_upsert(
    p_method_code  VARCHAR(30),
    p_method_name  VARCHAR(100),
    p_country_code CHAR(2)      DEFAULT NULL,
    p_method_type  VARCHAR(30)  DEFAULT NULL,
    p_is_active    BOOLEAN      DEFAULT TRUE
)
RETURNS VOID
LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO pay."PaymentMethods" ("Code", "Name", "Category", "CountryCode", "IsActive")
    VALUES (p_method_code, p_method_name, p_method_type, p_country_code, p_is_active)
    ON CONFLICT ("Code", COALESCE("CountryCode", '__'))
    DO UPDATE SET
        "Name"     = EXCLUDED."Name",
        "Category" = COALESCE(EXCLUDED."Category", pay."PaymentMethods"."Category"),
        "IsActive" = EXCLUDED."IsActive";
END;
$$;

-- =============================================================================
--  3: usp_pay_provider_list
-- =============================================================================
DROP FUNCTION IF EXISTS usp_pay_provider_list() CASCADE;
CREATE OR REPLACE FUNCTION usp_pay_provider_list()
RETURNS TABLE(
    "Id" INT, "Code" VARCHAR, "Name" VARCHAR, "CountryCode" VARCHAR,
    "ProviderType" VARCHAR, "BaseUrlSandbox" VARCHAR, "BaseUrlProd" VARCHAR,
    "AuthType" VARCHAR, "DocsUrl" VARCHAR, "LogoUrl" VARCHAR, "IsActive" BOOLEAN
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT pp."Id", pp."Code", pp."Name", pp."CountryCode"::VARCHAR,
           pp."ProviderType", pp."BaseUrlSandbox", pp."BaseUrlProd",
           pp."AuthType", pp."DocsUrl", pp."LogoUrl", pp."IsActive"
    FROM pay."PaymentProviders" pp
    WHERE pp."IsActive" = TRUE
    ORDER BY pp."Name";
END;
$$;

-- =============================================================================
--  4: usp_pay_provider_get
-- =============================================================================
DROP FUNCTION IF EXISTS usp_pay_provider_get(VARCHAR(30)) CASCADE;
CREATE OR REPLACE FUNCTION usp_pay_provider_get(
    p_provider_code VARCHAR(30)
)
RETURNS TABLE(
    "Id" INT, "Code" VARCHAR, "Name" VARCHAR, "CountryCode" VARCHAR,
    "ProviderType" VARCHAR, "BaseUrlSandbox" VARCHAR, "BaseUrlProd" VARCHAR,
    "AuthType" VARCHAR, "DocsUrl" VARCHAR, "LogoUrl" VARCHAR,
    "IsActive" BOOLEAN, "CreatedAt" TIMESTAMP
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT pp."Id", pp."Code", pp."Name", pp."CountryCode"::VARCHAR,
           pp."ProviderType", pp."BaseUrlSandbox", pp."BaseUrlProd",
           pp."AuthType", pp."DocsUrl", pp."LogoUrl",
           pp."IsActive", pp."CreatedAt"
    FROM pay."PaymentProviders" pp
    WHERE pp."Code" = p_provider_code
    LIMIT 1;
END;
$$;

-- =============================================================================
--  5: usp_pay_provider_getcapabilities
-- =============================================================================
DROP FUNCTION IF EXISTS usp_pay_provider_getcapabilities(VARCHAR(30)) CASCADE;
CREATE OR REPLACE FUNCTION usp_pay_provider_getcapabilities(
    p_provider_code VARCHAR(30)
)
RETURNS TABLE(
    "ProviderCode" VARCHAR, "ProviderName" VARCHAR, "ProviderType" VARCHAR,
    "CapabilityId" INT, "Capability" VARCHAR, "PaymentMethod" VARCHAR,
    "EndpointPath" VARCHAR, "HttpMethod" VARCHAR, "IsActive" BOOLEAN
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT p."Code", p."Name", p."ProviderType",
           c."Id", c."Capability", c."PaymentMethod",
           c."EndpointPath", c."HttpMethod", c."IsActive"
    FROM pay."ProviderCapabilities" c
    INNER JOIN pay."PaymentProviders" p ON p."Id" = c."ProviderId"
    WHERE p."Code" = p_provider_code
      AND c."IsActive" = TRUE
    ORDER BY c."Capability", c."PaymentMethod";
END;
$$;

-- =============================================================================
--  6: usp_pay_companyconfig_list
-- =============================================================================
DROP FUNCTION IF EXISTS usp_pay_companyconfig_list(INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_pay_companyconfig_list(
    p_company_id INT DEFAULT NULL
)
RETURNS TABLE(
    "Id" INT, "EmpresaId" INT, "SucursalId" INT, "CountryCode" VARCHAR,
    "ProviderId" INT, "ProviderCode" VARCHAR, "ProviderName" VARCHAR,
    "ProviderType" VARCHAR, "Environment" VARCHAR,
    "AutoCapture" BOOLEAN, "AllowRefunds" BOOLEAN, "MaxRefundDays" INT,
    "IsActive" BOOLEAN, "CreatedAt" TIMESTAMP, "UpdatedAt" TIMESTAMP
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT cc."Id", cc."EmpresaId", cc."SucursalId", cc."CountryCode",
           cc."ProviderId", p."Code", p."Name", p."ProviderType",
           cc."Environment", cc."AutoCapture", cc."AllowRefunds", cc."MaxRefundDays",
           cc."IsActive", cc."CreatedAt", cc."UpdatedAt"
    FROM pay."CompanyPaymentConfig" cc
    INNER JOIN pay."PaymentProviders" p ON p."Id" = cc."ProviderId"
    WHERE (p_company_id IS NULL OR cc."EmpresaId" = p_company_id)
    ORDER BY cc."EmpresaId", p."Code";
END;
$$;

-- =============================================================================
--  6b: usp_pay_companyconfig_listbycompany
-- =============================================================================
DROP FUNCTION IF EXISTS usp_pay_companyconfig_listbycompany(INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_pay_companyconfig_listbycompany(
    p_company_id INT,
    p_branch_id  INT DEFAULT NULL
)
RETURNS TABLE(
    "Id" INT, "EmpresaId" INT, "SucursalId" INT, "CountryCode" VARCHAR,
    "ProviderId" INT, "ProviderCode" VARCHAR, "ProviderName" VARCHAR,
    "ProviderType" VARCHAR, "Environment" VARCHAR,
    "ClientId" VARCHAR, "ClientSecret" VARCHAR,
    "MerchantId" VARCHAR, "TerminalId" VARCHAR, "IntegratorId" VARCHAR,
    "CertificatePath" VARCHAR, "ExtraConfig" TEXT,
    "AutoCapture" BOOLEAN, "AllowRefunds" BOOLEAN, "MaxRefundDays" INT,
    "IsActive" BOOLEAN, "CreatedAt" TIMESTAMP, "UpdatedAt" TIMESTAMP
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT cc."Id", cc."EmpresaId", cc."SucursalId", cc."CountryCode",
           cc."ProviderId", p."Code", p."Name", p."ProviderType",
           cc."Environment", cc."ClientId", cc."ClientSecret",
           cc."MerchantId", cc."TerminalId", cc."IntegratorId",
           cc."CertificatePath", cc."ExtraConfig",
           cc."AutoCapture", cc."AllowRefunds", cc."MaxRefundDays",
           cc."IsActive", cc."CreatedAt", cc."UpdatedAt"
    FROM pay."CompanyPaymentConfig" cc
    INNER JOIN pay."PaymentProviders" p ON p."Id" = cc."ProviderId"
    WHERE cc."EmpresaId" = p_company_id
      AND (p_branch_id IS NULL OR cc."SucursalId" = p_branch_id)
    ORDER BY p."Name";
END;
$$;

-- =============================================================================
--  7: usp_pay_companyconfig_upsert (legacy simple)
-- =============================================================================
DROP FUNCTION IF EXISTS usp_pay_companyconfig_upsert(INT, VARCHAR(30), BOOLEAN, TEXT) CASCADE;
CREATE OR REPLACE FUNCTION usp_pay_companyconfig_upsert(
    p_company_id    INT,
    p_provider_code VARCHAR(30),
    p_is_active     BOOLEAN DEFAULT TRUE,
    p_config_json   TEXT    DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql AS $$
DECLARE
    v_provider_id INT;
BEGIN
    SELECT "Id" INTO v_provider_id
    FROM pay."PaymentProviders"
    WHERE "Code" = p_provider_code;

    IF v_provider_id IS NULL THEN
        RAISE EXCEPTION 'Proveedor con codigo ''%'' no encontrado.', p_provider_code;
    END IF;

    INSERT INTO pay."CompanyPaymentConfig" (
        "EmpresaId", "SucursalId", "CountryCode", "ProviderId", "IsActive", "ExtraConfig", "CreatedAt", "UpdatedAt"
    )
    VALUES (
        p_company_id, 0,
        COALESCE((SELECT "CountryCode" FROM pay."PaymentProviders" WHERE "Id" = v_provider_id LIMIT 1), 'XX'),
        v_provider_id, p_is_active, p_config_json,
        NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'
    )
    ON CONFLICT ("EmpresaId", "ProviderId")
    DO UPDATE SET
        "IsActive"    = EXCLUDED."IsActive",
        "ExtraConfig" = COALESCE(EXCLUDED."ExtraConfig", pay."CompanyPaymentConfig"."ExtraConfig"),
        "UpdatedAt"   = NOW() AT TIME ZONE 'UTC';
END;
$$;

-- =============================================================================
--  7b: usp_pay_companyconfig_upsertfull
-- =============================================================================
DROP FUNCTION IF EXISTS usp_pay_companyconfig_upsertfull(INT, INT, CHAR(2), VARCHAR(30), VARCHAR(10), VARCHAR(500), VARCHAR(500), VARCHAR(100), VARCHAR(100), VARCHAR(50), VARCHAR(500), TEXT, BOOLEAN, BOOLEAN, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_pay_companyconfig_upsertfull(
    p_company_id       INT,
    p_branch_id        INT            DEFAULT 0,
    p_country_code     CHAR(2)        DEFAULT NULL,
    p_provider_code    VARCHAR(30)    DEFAULT NULL,
    p_environment      VARCHAR(10)    DEFAULT 'sandbox',
    p_client_id        VARCHAR(500)   DEFAULT NULL,
    p_client_secret    VARCHAR(500)   DEFAULT NULL,
    p_merchant_id      VARCHAR(100)   DEFAULT NULL,
    p_terminal_id      VARCHAR(100)   DEFAULT NULL,
    p_integrator_id    VARCHAR(50)    DEFAULT NULL,
    p_certificate_path VARCHAR(500)   DEFAULT NULL,
    p_extra_config     TEXT           DEFAULT NULL,
    p_auto_capture     BOOLEAN        DEFAULT TRUE,
    p_allow_refunds    BOOLEAN        DEFAULT TRUE,
    p_max_refund_days  INT            DEFAULT 30
)
RETURNS VOID
LANGUAGE plpgsql AS $$
DECLARE
    v_provider_id INT;
BEGIN
    SELECT "Id" INTO v_provider_id
    FROM pay."PaymentProviders"
    WHERE "Code" = p_provider_code;

    IF v_provider_id IS NULL THEN
        RAISE EXCEPTION 'Proveedor con codigo ''%'' no encontrado.', p_provider_code;
    END IF;

    INSERT INTO pay."CompanyPaymentConfig" (
        "EmpresaId", "SucursalId", "CountryCode", "ProviderId", "Environment",
        "ClientId", "ClientSecret", "MerchantId", "TerminalId", "IntegratorId",
        "CertificatePath", "ExtraConfig", "AutoCapture", "AllowRefunds", "MaxRefundDays",
        "IsActive", "CreatedAt", "UpdatedAt"
    )
    VALUES (
        p_company_id, p_branch_id, p_country_code, v_provider_id, p_environment,
        p_client_id, p_client_secret, p_merchant_id, p_terminal_id, p_integrator_id,
        p_certificate_path, p_extra_config, p_auto_capture, p_allow_refunds, p_max_refund_days,
        TRUE, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'
    )
    ON CONFLICT ("EmpresaId", "SucursalId", "ProviderId")
    DO UPDATE SET
        "CountryCode"    = EXCLUDED."CountryCode",
        "Environment"    = EXCLUDED."Environment",
        "ClientId"       = COALESCE(EXCLUDED."ClientId",       pay."CompanyPaymentConfig"."ClientId"),
        "ClientSecret"   = COALESCE(EXCLUDED."ClientSecret",   pay."CompanyPaymentConfig"."ClientSecret"),
        "MerchantId"     = COALESCE(EXCLUDED."MerchantId",     pay."CompanyPaymentConfig"."MerchantId"),
        "TerminalId"     = COALESCE(EXCLUDED."TerminalId",     pay."CompanyPaymentConfig"."TerminalId"),
        "IntegratorId"   = COALESCE(EXCLUDED."IntegratorId",   pay."CompanyPaymentConfig"."IntegratorId"),
        "CertificatePath"= COALESCE(EXCLUDED."CertificatePath",pay."CompanyPaymentConfig"."CertificatePath"),
        "ExtraConfig"    = COALESCE(EXCLUDED."ExtraConfig",    pay."CompanyPaymentConfig"."ExtraConfig"),
        "AutoCapture"    = EXCLUDED."AutoCapture",
        "AllowRefunds"   = EXCLUDED."AllowRefunds",
        "MaxRefundDays"  = EXCLUDED."MaxRefundDays",
        "IsActive"       = TRUE,
        "UpdatedAt"      = NOW() AT TIME ZONE 'UTC';
END;
$$;

-- =============================================================================
--  8: usp_pay_companyconfig_deactivate
-- =============================================================================
DROP FUNCTION IF EXISTS usp_pay_companyconfig_deactivate(INT, VARCHAR(30)) CASCADE;
CREATE OR REPLACE FUNCTION usp_pay_companyconfig_deactivate(
    p_company_id    INT,
    p_provider_code VARCHAR(30)
)
RETURNS VOID
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE pay."CompanyPaymentConfig" cc
    SET "IsActive"  = FALSE,
        "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
    FROM pay."PaymentProviders" p
    WHERE p."Id" = cc."ProviderId"
      AND cc."EmpresaId" = p_company_id
      AND p."Code" = p_provider_code;
END;
$$;

-- =============================================================================
--  8b: usp_pay_companyconfig_deactivatebyid
-- =============================================================================
DROP FUNCTION IF EXISTS usp_pay_companyconfig_deactivatebyid(INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_pay_companyconfig_deactivatebyid(p_id INT)
RETURNS VOID
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE pay."CompanyPaymentConfig"
    SET "IsActive"  = FALSE,
        "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
    WHERE "Id" = p_id;
END;
$$;

-- =============================================================================
--  9: usp_pay_acceptedmethod_list
-- =============================================================================
DROP FUNCTION IF EXISTS usp_pay_acceptedmethod_list(INT, INT, BOOLEAN, BOOLEAN, BOOLEAN) CASCADE;
CREATE OR REPLACE FUNCTION usp_pay_acceptedmethod_list(
    p_company_id           INT,
    p_sucursal_id          INT     DEFAULT NULL,
    p_applies_to_pos       BOOLEAN DEFAULT NULL,
    p_applies_to_web       BOOLEAN DEFAULT NULL,
    p_applies_to_restaurant BOOLEAN DEFAULT NULL
)
RETURNS TABLE(
    "Id" INT, "EmpresaId" INT, "SucursalId" INT,
    "PaymentMethodId" INT, "MethodCode" VARCHAR, "MethodName" VARCHAR,
    "MethodCategory" VARCHAR, "IconName" VARCHAR,
    "ProviderId" INT, "ProviderCode" VARCHAR, "ProviderName" VARCHAR,
    "AppliesToPOS" BOOLEAN, "AppliesToWeb" BOOLEAN, "AppliesToRestaurant" BOOLEAN,
    "MinAmount" NUMERIC, "MaxAmount" NUMERIC,
    "CommissionPct" NUMERIC, "CommissionFixed" NUMERIC,
    "SortOrder" INT, "IsActive" BOOLEAN
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT am."Id", am."EmpresaId", am."SucursalId",
           am."PaymentMethodId", m."Code", m."Name", m."Category", m."IconName",
           am."ProviderId", p."Code", p."Name",
           am."AppliesToPOS", am."AppliesToWeb", am."AppliesToRestaurant",
           am."MinAmount", am."MaxAmount", am."CommissionPct", am."CommissionFixed",
           am."SortOrder", am."IsActive"
    FROM pay."AcceptedPaymentMethods" am
    INNER JOIN pay."PaymentMethods" m ON m."Id" = am."PaymentMethodId"
    LEFT  JOIN pay."PaymentProviders" p ON p."Id" = am."ProviderId"
    WHERE am."EmpresaId" = p_company_id
      AND am."IsActive" = TRUE
      AND (p_sucursal_id IS NULL          OR am."SucursalId" = p_sucursal_id)
      AND (p_applies_to_pos IS NULL       OR am."AppliesToPOS" = p_applies_to_pos)
      AND (p_applies_to_web IS NULL       OR am."AppliesToWeb" = p_applies_to_web)
      AND (p_applies_to_restaurant IS NULL OR am."AppliesToRestaurant" = p_applies_to_restaurant)
    ORDER BY am."SortOrder", m."Name";
END;
$$;

-- =============================================================================
--  10: usp_pay_acceptedmethod_upsert
-- =============================================================================
DROP FUNCTION IF EXISTS usp_pay_acceptedmethod_upsert(INT, INT, INT, INT, BOOLEAN, BOOLEAN, BOOLEAN, NUMERIC(18,2), NUMERIC(18,2), NUMERIC(5,4), NUMERIC(18,2), INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_pay_acceptedmethod_upsert(
    p_company_id           INT,
    p_branch_id            INT,
    p_payment_method_id    INT,
    p_provider_id          INT            DEFAULT NULL,
    p_applies_to_pos       BOOLEAN        DEFAULT TRUE,
    p_applies_to_web       BOOLEAN        DEFAULT TRUE,
    p_applies_to_restaurant BOOLEAN       DEFAULT TRUE,
    p_min_amount           NUMERIC(18,2)  DEFAULT NULL,
    p_max_amount           NUMERIC(18,2)  DEFAULT NULL,
    p_commission_pct       NUMERIC(5,4)   DEFAULT NULL,
    p_commission_fixed     NUMERIC(18,2)  DEFAULT NULL,
    p_sort_order           INT            DEFAULT 0
)
RETURNS VOID
LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO pay."AcceptedPaymentMethods" (
        "EmpresaId", "SucursalId", "PaymentMethodId", "ProviderId",
        "AppliesToPOS", "AppliesToWeb", "AppliesToRestaurant",
        "MinAmount", "MaxAmount", "CommissionPct", "CommissionFixed", "SortOrder"
    )
    VALUES (
        p_company_id, p_branch_id, p_payment_method_id, p_provider_id,
        p_applies_to_pos, p_applies_to_web, p_applies_to_restaurant,
        p_min_amount, p_max_amount, p_commission_pct, p_commission_fixed, p_sort_order
    )
    ON CONFLICT ("EmpresaId", "SucursalId", "PaymentMethodId", COALESCE("ProviderId", 0))
    DO UPDATE SET
        "AppliesToPOS"        = EXCLUDED."AppliesToPOS",
        "AppliesToWeb"        = EXCLUDED."AppliesToWeb",
        "AppliesToRestaurant" = EXCLUDED."AppliesToRestaurant",
        "MinAmount"           = EXCLUDED."MinAmount",
        "MaxAmount"           = EXCLUDED."MaxAmount",
        "CommissionPct"       = EXCLUDED."CommissionPct",
        "CommissionFixed"     = EXCLUDED."CommissionFixed",
        "SortOrder"           = EXCLUDED."SortOrder",
        "IsActive"            = TRUE;
END;
$$;

-- =============================================================================
--  10b: usp_pay_acceptedmethod_deactivate
-- =============================================================================
DROP FUNCTION IF EXISTS usp_pay_acceptedmethod_deactivate(INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_pay_acceptedmethod_deactivate(p_id INT)
RETURNS VOID
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE pay."AcceptedPaymentMethods"
    SET "IsActive" = FALSE
    WHERE "Id" = p_id;
END;
$$;

-- =============================================================================
--  11: usp_pay_cardreader_list
-- =============================================================================
DROP FUNCTION IF EXISTS usp_pay_cardreader_list(INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_pay_cardreader_list(
    p_company_id INT DEFAULT NULL
)
RETURNS TABLE(
    "Id" INT, "EmpresaId" INT, "SucursalId" INT, "StationId" VARCHAR,
    "DeviceName" VARCHAR, "DeviceType" VARCHAR, "ConnectionType" VARCHAR,
    "ConnectionConfig" VARCHAR, "ProviderId" INT, "IsActive" BOOLEAN,
    "LastSeenAt" TIMESTAMP, "CreatedAt" TIMESTAMP
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT cr."Id", cr."EmpresaId", cr."SucursalId", cr."StationId",
           cr."DeviceName", cr."DeviceType", cr."ConnectionType",
           cr."ConnectionConfig", cr."ProviderId", cr."IsActive",
           cr."LastSeenAt", cr."CreatedAt"
    FROM pay."CardReaderDevices" cr
    WHERE (p_company_id IS NULL OR cr."EmpresaId" = p_company_id)
    ORDER BY cr."EmpresaId", cr."StationId", cr."DeviceName";
END;
$$;

-- =============================================================================
--  11b: usp_pay_cardreader_listbycompany
-- =============================================================================
DROP FUNCTION IF EXISTS usp_pay_cardreader_listbycompany(INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_pay_cardreader_listbycompany(
    p_company_id INT,
    p_branch_id  INT DEFAULT NULL
)
RETURNS TABLE(
    "Id" INT, "EmpresaId" INT, "SucursalId" INT, "StationId" VARCHAR,
    "DeviceName" VARCHAR, "DeviceType" VARCHAR, "ConnectionType" VARCHAR,
    "ConnectionConfig" VARCHAR, "ProviderId" INT, "IsActive" BOOLEAN,
    "LastSeenAt" TIMESTAMP, "CreatedAt" TIMESTAMP
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT cr."Id", cr."EmpresaId", cr."SucursalId", cr."StationId",
           cr."DeviceName", cr."DeviceType", cr."ConnectionType",
           cr."ConnectionConfig", cr."ProviderId", cr."IsActive",
           cr."LastSeenAt", cr."CreatedAt"
    FROM pay."CardReaderDevices" cr
    WHERE cr."EmpresaId" = p_company_id
      AND cr."IsActive" = TRUE
      AND (p_branch_id IS NULL OR cr."SucursalId" = p_branch_id)
    ORDER BY cr."StationId", cr."DeviceName";
END;
$$;

-- =============================================================================
--  12: usp_pay_cardreader_upsert
-- =============================================================================
DROP FUNCTION IF EXISTS usp_pay_cardreader_upsert(INT, INT, INT, VARCHAR(50), VARCHAR(100), VARCHAR(30), VARCHAR(30), VARCHAR(500), INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_pay_cardreader_upsert(
    p_device_id         INT           DEFAULT NULL,
    p_company_id        INT           DEFAULT NULL,
    p_branch_id         INT           DEFAULT 0,
    p_station_id        VARCHAR(50)   DEFAULT 'DEFAULT',
    p_device_name       VARCHAR(100)  DEFAULT NULL,
    p_device_type       VARCHAR(30)   DEFAULT NULL,
    p_connection_type   VARCHAR(30)   DEFAULT 'USB',
    p_connection_config VARCHAR(500)  DEFAULT NULL,
    p_provider_id       INT           DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql AS $$
BEGIN
    IF p_device_id IS NOT NULL THEN
        UPDATE pay."CardReaderDevices"
        SET "DeviceName"       = p_device_name,
            "DeviceType"       = p_device_type,
            "ConnectionType"   = p_connection_type,
            "ConnectionConfig" = COALESCE(p_connection_config, "ConnectionConfig"),
            "ProviderId"       = p_provider_id,
            "StationId"        = p_station_id
        WHERE "Id" = p_device_id;
    ELSE
        INSERT INTO pay."CardReaderDevices" (
            "EmpresaId", "SucursalId", "StationId", "DeviceName",
            "DeviceType", "ConnectionType", "ConnectionConfig",
            "ProviderId", "IsActive", "CreatedAt"
        )
        VALUES (
            p_company_id, p_branch_id, p_station_id, p_device_name,
            p_device_type, p_connection_type, p_connection_config,
            p_provider_id, TRUE, NOW() AT TIME ZONE 'UTC'
        );
    END IF;
END;
$$;
