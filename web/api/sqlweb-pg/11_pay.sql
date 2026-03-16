-- usp_pay_acceptedmethod_deactivate
CREATE OR REPLACE FUNCTION public.usp_pay_acceptedmethod_deactivate(p_id integer)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
    UPDATE pay."AcceptedPaymentMethods"
    SET "IsActive" = FALSE
    WHERE "Id" = p_id;
END;
$function$
;

-- usp_pay_acceptedmethod_list
CREATE OR REPLACE FUNCTION public.usp_pay_acceptedmethod_list(p_company_id integer, p_sucursal_id integer DEFAULT NULL::integer, p_applies_to_pos boolean DEFAULT NULL::boolean, p_applies_to_web boolean DEFAULT NULL::boolean, p_applies_to_restaurant boolean DEFAULT NULL::boolean)
 RETURNS TABLE("Id" integer, "EmpresaId" integer, "SucursalId" integer, "PaymentMethodId" integer, "MethodCode" character varying, "MethodName" character varying, "MethodCategory" character varying, "IconName" character varying, "ProviderId" integer, "ProviderCode" character varying, "ProviderName" character varying, "AppliesToPOS" boolean, "AppliesToWeb" boolean, "AppliesToRestaurant" boolean, "MinAmount" numeric, "MaxAmount" numeric, "CommissionPct" numeric, "CommissionFixed" numeric, "SortOrder" integer, "IsActive" boolean)
 LANGUAGE plpgsql
AS $function$
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
$function$
;

-- usp_pay_acceptedmethod_upsert
CREATE OR REPLACE FUNCTION public.usp_pay_acceptedmethod_upsert(p_company_id integer, p_branch_id integer, p_payment_method_id integer, p_provider_id integer DEFAULT NULL::integer, p_applies_to_pos boolean DEFAULT true, p_applies_to_web boolean DEFAULT true, p_applies_to_restaurant boolean DEFAULT true, p_min_amount numeric DEFAULT NULL::numeric, p_max_amount numeric DEFAULT NULL::numeric, p_commission_pct numeric DEFAULT NULL::numeric, p_commission_fixed numeric DEFAULT NULL::numeric, p_sort_order integer DEFAULT 0)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
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
$function$
;

-- usp_pay_cardreader_list
CREATE OR REPLACE FUNCTION public.usp_pay_cardreader_list(p_company_id integer DEFAULT NULL::integer)
 RETURNS TABLE("Id" integer, "EmpresaId" integer, "SucursalId" integer, "StationId" character varying, "DeviceName" character varying, "DeviceType" character varying, "ConnectionType" character varying, "ConnectionConfig" character varying, "ProviderId" integer, "IsActive" boolean, "LastSeenAt" timestamp with time zone, "CreatedAt" timestamp with time zone)
 LANGUAGE plpgsql
AS $function$
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
$function$
;

-- usp_pay_cardreader_listbycompany
CREATE OR REPLACE FUNCTION public.usp_pay_cardreader_listbycompany(p_company_id integer, p_branch_id integer DEFAULT NULL::integer)
 RETURNS TABLE("Id" integer, "EmpresaId" integer, "SucursalId" integer, "StationId" character varying, "DeviceName" character varying, "DeviceType" character varying, "ConnectionType" character varying, "ConnectionConfig" character varying, "ProviderId" integer, "IsActive" boolean, "LastSeenAt" timestamp with time zone, "CreatedAt" timestamp with time zone)
 LANGUAGE plpgsql
AS $function$
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
$function$
;

-- usp_pay_cardreader_upsert
CREATE OR REPLACE FUNCTION public.usp_pay_cardreader_upsert(p_device_id integer DEFAULT NULL::integer, p_company_id integer DEFAULT NULL::integer, p_branch_id integer DEFAULT 0, p_station_id character varying DEFAULT 'DEFAULT'::character varying, p_device_name character varying DEFAULT NULL::character varying, p_device_type character varying DEFAULT NULL::character varying, p_connection_type character varying DEFAULT 'USB'::character varying, p_connection_config character varying DEFAULT NULL::character varying, p_provider_id integer DEFAULT NULL::integer)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
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
$function$
;

-- usp_pay_companyconfig_deactivate
CREATE OR REPLACE FUNCTION public.usp_pay_companyconfig_deactivate(p_company_id integer, p_provider_code character varying)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
    UPDATE pay."CompanyPaymentConfig" cc
    SET "IsActive"  = FALSE,
        "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
    FROM pay."PaymentProviders" p
    WHERE p."Id" = cc."ProviderId"
      AND cc."EmpresaId" = p_company_id
      AND p."Code" = p_provider_code;
END;
$function$
;

-- usp_pay_companyconfig_deactivatebyid
CREATE OR REPLACE FUNCTION public.usp_pay_companyconfig_deactivatebyid(p_id integer)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
    UPDATE pay."CompanyPaymentConfig"
    SET "IsActive"  = FALSE,
        "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
    WHERE "Id" = p_id;
END;
$function$
;

-- usp_pay_companyconfig_list
CREATE OR REPLACE FUNCTION public.usp_pay_companyconfig_list(p_company_id integer DEFAULT NULL::integer)
 RETURNS TABLE("Id" integer, "EmpresaId" integer, "SucursalId" integer, "CountryCode" character varying, "ProviderId" integer, "ProviderCode" character varying, "ProviderName" character varying, "ProviderType" character varying, "Environment" character varying, "AutoCapture" boolean, "AllowRefunds" boolean, "MaxRefundDays" integer, "IsActive" boolean, "CreatedAt" timestamp with time zone, "UpdatedAt" timestamp with time zone)
 LANGUAGE plpgsql
AS $function$
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
$function$
;

-- usp_pay_companyconfig_listbycompany
CREATE OR REPLACE FUNCTION public.usp_pay_companyconfig_listbycompany(p_company_id integer, p_branch_id integer DEFAULT NULL::integer)
 RETURNS TABLE("Id" integer, "EmpresaId" integer, "SucursalId" integer, "CountryCode" character varying, "ProviderId" integer, "ProviderCode" character varying, "ProviderName" character varying, "ProviderType" character varying, "Environment" character varying, "ClientId" character varying, "ClientSecret" character varying, "MerchantId" character varying, "TerminalId" character varying, "IntegratorId" character varying, "CertificatePath" character varying, "ExtraConfig" character varying, "AutoCapture" boolean, "AllowRefunds" boolean, "MaxRefundDays" integer, "IsActive" boolean, "CreatedAt" timestamp with time zone, "UpdatedAt" timestamp with time zone)
 LANGUAGE plpgsql
AS $function$
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
$function$
;

-- usp_pay_companyconfig_upsert
CREATE OR REPLACE FUNCTION public.usp_pay_companyconfig_upsert(p_company_id integer, p_provider_code character varying, p_is_active boolean DEFAULT true, p_config_json text DEFAULT NULL::text)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
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
$function$
;

-- usp_pay_companyconfig_upsertfull
CREATE OR REPLACE FUNCTION public.usp_pay_companyconfig_upsertfull(p_company_id integer, p_branch_id integer DEFAULT 0, p_country_code character DEFAULT NULL::bpchar, p_provider_code character varying DEFAULT NULL::character varying, p_environment character varying DEFAULT 'sandbox'::character varying, p_client_id character varying DEFAULT NULL::character varying, p_client_secret character varying DEFAULT NULL::character varying, p_merchant_id character varying DEFAULT NULL::character varying, p_terminal_id character varying DEFAULT NULL::character varying, p_integrator_id character varying DEFAULT NULL::character varying, p_certificate_path character varying DEFAULT NULL::character varying, p_extra_config text DEFAULT NULL::text, p_auto_capture boolean DEFAULT true, p_allow_refunds boolean DEFAULT true, p_max_refund_days integer DEFAULT 30)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
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
$function$
;

-- usp_pay_method_list
CREATE OR REPLACE FUNCTION public.usp_pay_method_list(p_country_code character DEFAULT NULL::bpchar)
 RETURNS TABLE("Id" integer, "Code" character varying, "Name" character varying, "Category" character varying, "CountryCode" character varying, "IconName" character varying, "RequiresGateway" boolean, "IsActive" boolean, "SortOrder" integer)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT pm."Id", pm."Code", pm."Name", pm."Category",
           pm."CountryCode", pm."IconName", pm."RequiresGateway",
           pm."IsActive", pm."SortOrder"
    FROM pay."PaymentMethods" pm
    WHERE pm."IsActive" = TRUE
      AND (p_country_code IS NULL
            OR pm."CountryCode" = p_country_code
            OR pm."CountryCode" IS NULL)
    ORDER BY pm."SortOrder", pm."Name";
END;
$function$
;

-- usp_pay_method_upsert
CREATE OR REPLACE FUNCTION public.usp_pay_method_upsert(p_method_code character varying, p_method_name character varying, p_country_code character DEFAULT NULL::bpchar, p_method_type character varying DEFAULT NULL::character varying, p_is_active boolean DEFAULT true)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
    INSERT INTO pay."PaymentMethods" ("Code", "Name", "Category", "CountryCode", "IsActive")
    VALUES (p_method_code, p_method_name, p_method_type, p_country_code, p_is_active)
    ON CONFLICT ("Code", COALESCE("CountryCode", '__'))
    DO UPDATE SET
        "Name"     = EXCLUDED."Name",
        "Category" = COALESCE(EXCLUDED."Category", pay."PaymentMethods"."Category"),
        "IsActive" = EXCLUDED."IsActive";
END;
$function$
;

-- usp_pay_provider_get
CREATE OR REPLACE FUNCTION public.usp_pay_provider_get(p_provider_code character varying)
 RETURNS TABLE("Id" integer, "Code" character varying, "Name" character varying, "CountryCode" character varying, "ProviderType" character varying, "BaseUrlSandbox" character varying, "BaseUrlProd" character varying, "AuthType" character varying, "DocsUrl" character varying, "LogoUrl" character varying, "IsActive" boolean, "CreatedAt" timestamp with time zone)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT pp."Id", pp."Code", pp."Name", pp."CountryCode",
           pp."ProviderType", pp."BaseUrlSandbox", pp."BaseUrlProd",
           pp."AuthType", pp."DocsUrl", pp."LogoUrl",
           pp."IsActive", pp."CreatedAt"
    FROM pay."PaymentProviders" pp
    WHERE pp."Code" = p_provider_code
    LIMIT 1;
END;
$function$
;

-- usp_pay_provider_getcapabilities
CREATE OR REPLACE FUNCTION public.usp_pay_provider_getcapabilities(p_provider_code character varying)
 RETURNS TABLE("ProviderCode" character varying, "ProviderName" character varying, "ProviderType" character varying, "CapabilityId" integer, "Capability" character varying, "PaymentMethod" character varying, "EndpointPath" character varying, "HttpMethod" character varying, "IsActive" boolean)
 LANGUAGE plpgsql
AS $function$
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
$function$
;

-- usp_pay_provider_list
CREATE OR REPLACE FUNCTION public.usp_pay_provider_list()
 RETURNS TABLE("Id" integer, "Code" character varying, "Name" character varying, "CountryCode" character varying, "ProviderType" character varying, "BaseUrlSandbox" character varying, "BaseUrlProd" character varying, "AuthType" character varying, "DocsUrl" character varying, "LogoUrl" character varying, "IsActive" boolean)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT pp."Id", pp."Code", pp."Name", pp."CountryCode",
           pp."ProviderType", pp."BaseUrlSandbox", pp."BaseUrlProd",
           pp."AuthType", pp."DocsUrl", pp."LogoUrl", pp."IsActive"
    FROM pay."PaymentProviders" pp
    WHERE pp."IsActive" = TRUE
    ORDER BY pp."Name";
END;
$function$
;

-- usp_pay_transaction_insert
CREATE OR REPLACE FUNCTION public.usp_pay_transaction_insert(p_transaction_uuid character varying, p_empresa_id integer, p_sucursal_id integer, p_source_type character varying, p_source_id integer DEFAULT NULL::integer, p_source_number character varying DEFAULT NULL::character varying, p_payment_method_code character varying DEFAULT NULL::character varying, p_provider_id integer DEFAULT NULL::integer, p_currency character varying DEFAULT NULL::character varying, p_amount numeric DEFAULT 0, p_trx_type character varying DEFAULT NULL::character varying, p_status character varying DEFAULT NULL::character varying, p_gateway_trx_id character varying DEFAULT NULL::character varying, p_gateway_auth_code character varying DEFAULT NULL::character varying, p_gateway_response text DEFAULT NULL::text, p_gateway_message character varying DEFAULT NULL::character varying, p_card_last_four character varying DEFAULT NULL::character varying, p_card_brand character varying DEFAULT NULL::character varying, p_mobile_number character varying DEFAULT NULL::character varying, p_bank_code character varying DEFAULT NULL::character varying, p_payment_ref character varying DEFAULT NULL::character varying, p_station_id character varying DEFAULT NULL::character varying, p_cashier_id character varying DEFAULT NULL::character varying, p_ip_address character varying DEFAULT NULL::character varying)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
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
$function$
;

-- usp_pay_transaction_resolveconfig
CREATE OR REPLACE FUNCTION public.usp_pay_transaction_resolveconfig(p_empresa_id integer, p_sucursal_id integer, p_provider_code character varying)
 RETURNS SETOF pay."CompanyPaymentConfig"
 LANGUAGE plpgsql
AS $function$
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
$function$
;

-- usp_pay_transaction_search
CREATE OR REPLACE FUNCTION public.usp_pay_transaction_search(p_empresa_id integer, p_sucursal_id integer DEFAULT NULL::integer, p_provider_code character varying DEFAULT NULL::character varying, p_source_type character varying DEFAULT NULL::character varying, p_source_number character varying DEFAULT NULL::character varying, p_status character varying DEFAULT NULL::character varying, p_date_from timestamp without time zone DEFAULT NULL::timestamp without time zone, p_date_to timestamp without time zone DEFAULT NULL::timestamp without time zone, p_offset integer DEFAULT 0, p_limit integer DEFAULT 50)
 RETURNS SETOF pay."Transactions"
 LANGUAGE plpgsql
AS $function$
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
$function$
;

-- usp_pay_transaction_searchcount
CREATE OR REPLACE FUNCTION public.usp_pay_transaction_searchcount(p_empresa_id integer, p_sucursal_id integer DEFAULT NULL::integer, p_provider_code character varying DEFAULT NULL::character varying, p_source_type character varying DEFAULT NULL::character varying, p_source_number character varying DEFAULT NULL::character varying, p_status character varying DEFAULT NULL::character varying, p_date_from timestamp without time zone DEFAULT NULL::timestamp without time zone, p_date_to timestamp without time zone DEFAULT NULL::timestamp without time zone)
 RETURNS TABLE(total bigint)
 LANGUAGE plpgsql
AS $function$
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
$function$
;

-- usp_pay_transaction_updatestatus
CREATE OR REPLACE FUNCTION public.usp_pay_transaction_updatestatus(p_transaction_uuid character varying, p_status character varying, p_gateway_trx_id character varying DEFAULT NULL::character varying, p_gateway_auth_code character varying DEFAULT NULL::character varying, p_gateway_response text DEFAULT NULL::text, p_gateway_message character varying DEFAULT NULL::character varying)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
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
$function$
;

