-- usp_cfg_appsetting_list
DROP FUNCTION IF EXISTS public.usp_cfg_appsetting_list(integer) CASCADE;
DROP FUNCTION IF EXISTS public.usp_cfg_appsetting_list(p_company_id integer)
 RETURNS TABLE("SettingId" bigint, "Module" character varying, "SettingKey" character varying, "SettingValue" character varying, "ValueType" character varying, "Description" character varying, "UpdatedAt" timestamp without time zone)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT s."SettingId", s."Module", s."SettingKey",
           s."SettingValue", s."ValueType", s."Description",
           s."UpdatedAt"
    FROM   cfg."AppSetting" s
    WHERE  s."CompanyId" = p_company_id
    ORDER BY s."Module", s."SettingKey";
END;
$function$
;

-- usp_cfg_appsetting_listbymodule
DROP FUNCTION IF EXISTS public.usp_cfg_appsetting_listbymodule(integer, character varying) CASCADE;
DROP FUNCTION IF EXISTS public.usp_cfg_appsetting_listbymodule(p_company_id integer, p_module character varying)
 RETURNS TABLE("SettingId" bigint, "Module" character varying, "SettingKey" character varying, "SettingValue" character varying, "ValueType" character varying, "Description" character varying, "UpdatedAt" timestamp without time zone)
 LANGUAGE plpgsql
AS $function$
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
$function$
;

-- usp_cfg_appsetting_listmodules
DROP FUNCTION IF EXISTS public.usp_cfg_appsetting_listmodules(integer) CASCADE;
DROP FUNCTION IF EXISTS public.usp_cfg_appsetting_listmodules(p_company_id integer)
 RETURNS TABLE("Module" character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT DISTINCT s."Module"
    FROM   cfg."AppSetting" s
    WHERE  s."CompanyId" = p_company_id
    ORDER BY s."Module";
END;
$function$
;

-- usp_cfg_appsetting_listvaluetypes
DROP FUNCTION IF EXISTS public.usp_cfg_appsetting_listvaluetypes() CASCADE;
CREATE OR REPLACE FUNCTION public.usp_cfg_appsetting_listvaluetypes()
 RETURNS TABLE("ValueType" character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT DISTINCT s."ValueType"
    FROM   cfg."AppSetting" s
    WHERE  s."ValueType" IS NOT NULL
    ORDER BY s."ValueType";
END;
$function$
;

-- usp_cfg_appsetting_listwithmeta
DROP FUNCTION IF EXISTS public.usp_cfg_appsetting_listwithmeta(integer, character varying) CASCADE;
DROP FUNCTION IF EXISTS public.usp_cfg_appsetting_listwithmeta(p_company_id integer, p_module character varying DEFAULT NULL::character varying)
 RETURNS TABLE("SettingId" bigint, "Module" character varying, "SettingKey" character varying, "SettingValue" character varying, "ValueType" character varying, "Description" character varying, "IsReadOnly" boolean, "UpdatedAt" timestamp without time zone)
 LANGUAGE plpgsql
AS $function$
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
$function$
;

-- usp_cfg_appsetting_upsert
DROP FUNCTION IF EXISTS public.usp_cfg_appsetting_upsert(integer, character varying, character varying, text, character varying, character varying, integer) CASCADE;
DROP FUNCTION IF EXISTS public.usp_cfg_appsetting_upsert(p_company_id integer, p_module character varying, p_setting_key character varying, p_setting_value text, p_value_type character varying DEFAULT NULL::character varying, p_description character varying DEFAULT NULL::character varying, p_user_id integer DEFAULT NULL::integer)
 RETURNS TABLE("Resultado" integer, "Mensaje" character varying)
 LANGUAGE plpgsql
AS $function$
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
$function$
;

-- usp_cfg_country_get
DROP FUNCTION IF EXISTS public.usp_cfg_country_get(character) CASCADE;
DROP FUNCTION IF EXISTS public.usp_cfg_country_get(p_country_code character)
 RETURNS TABLE("CountryCode" character, "CountryName" character varying, "CurrencyCode" character, "TaxAuthorityCode" character varying, "FiscalIdName" character varying, "IsActive" boolean, "CreatedAt" timestamp without time zone, "UpdatedAt" timestamp without time zone)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        c."CountryCode",
        c."CountryName",
        c."CurrencyCode",
        c."TaxAuthorityCode",
        c."FiscalIdName",
        c."IsActive",
        c."CreatedAt",
        c."UpdatedAt"
    FROM cfg."Country" c
    WHERE c."CountryCode" = p_country_code;
END;
$function$
;

-- usp_cfg_country_list
DROP FUNCTION IF EXISTS public.usp_cfg_country_list(boolean) CASCADE;
DROP FUNCTION IF EXISTS public.usp_cfg_country_list(p_active_only boolean DEFAULT true)
 RETURNS TABLE("CountryCode" character, "CountryName" character varying, "CurrencyCode" character, "TaxAuthorityCode" character varying, "FiscalIdName" character varying, "IsActive" boolean, "CreatedAt" timestamp without time zone, "UpdatedAt" timestamp without time zone)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        c."CountryCode",
        c."CountryName",
        c."CurrencyCode",
        c."TaxAuthorityCode",
        c."FiscalIdName",
        c."IsActive",
        c."CreatedAt",
        c."UpdatedAt"
    FROM cfg."Country" c
    WHERE (NOT p_active_only OR c."IsActive" = TRUE)
    ORDER BY c."CountryName";
END;
$function$
;

-- usp_cfg_country_save
DROP FUNCTION IF EXISTS public.usp_cfg_country_save(character, character varying, character, character varying, character varying, boolean, integer, character varying) CASCADE;
DROP FUNCTION IF EXISTS public.usp_cfg_country_save(p_country_code character, p_country_name character varying, p_currency_code character, p_tax_authority_code character varying, p_fiscal_id_name character varying, p_is_active boolean, OUT p_resultado integer, OUT p_mensaje character varying)
 RETURNS record
 LANGUAGE plpgsql
AS $function$
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    BEGIN
        IF EXISTS (SELECT 1 FROM cfg."Country" WHERE "CountryCode" = p_country_code) THEN
            UPDATE cfg."Country"
            SET "CountryName"       = p_country_name,
                "CurrencyCode"      = p_currency_code,
                "TaxAuthorityCode"  = p_tax_authority_code,
                "FiscalIdName"      = p_fiscal_id_name,
                "IsActive"          = p_is_active,
                "UpdatedAt"         = (NOW() AT TIME ZONE 'UTC')
            WHERE "CountryCode" = p_country_code;

            p_resultado := 0;
            p_mensaje   := 'PaÃ­s actualizado correctamente.';
        ELSE
            INSERT INTO cfg."Country" (
                "CountryCode", "CountryName", "CurrencyCode",
                "TaxAuthorityCode", "FiscalIdName",
                "IsActive", "CreatedAt", "UpdatedAt"
            )
            VALUES (
                p_country_code, p_country_name, p_currency_code,
                p_tax_authority_code, p_fiscal_id_name,
                p_is_active,
                (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
            );

            p_resultado := 0;
            p_mensaje   := 'PaÃ­s creado correctamente.';
        END IF;

    EXCEPTION WHEN OTHERS THEN
        p_resultado := -1;
        p_mensaje   := SQLERRM;
    END;
END;
$function$
;

-- usp_cfg_country_save
DROP FUNCTION IF EXISTS public.usp_cfg_country_save(character, character varying, character, character varying, character, character varying, numeric, boolean, numeric, boolean, character varying, character varying, character varying, character varying, integer, boolean, integer, character varying) CASCADE;
DROP FUNCTION IF EXISTS public.usp_cfg_country_save(p_country_code character, p_country_name character varying, p_currency_code character, p_currency_symbol character varying, p_reference_currency character, p_reference_currency_symbol character varying, p_default_exchange_rate numeric, p_prices_include_tax boolean, p_special_tax_rate numeric, p_special_tax_enabled boolean, p_tax_authority_code character varying, p_fiscal_id_name character varying, p_timezone_iana character varying, p_phone_prefix character varying, p_sort_order integer, p_is_active boolean, OUT p_resultado integer, OUT p_mensaje character varying)
 RETURNS record
 LANGUAGE plpgsql
AS $function$
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    BEGIN
        IF EXISTS (SELECT 1 FROM cfg."Country" WHERE "CountryCode" = p_country_code) THEN
            UPDATE cfg."Country"
            SET "CountryName"               = p_country_name,
                "CurrencyCode"              = p_currency_code,
                "CurrencySymbol"            = p_currency_symbol,
                "ReferenceCurrency"         = p_reference_currency,
                "ReferenceCurrencySymbol"   = p_reference_currency_symbol,
                "DefaultExchangeRate"       = p_default_exchange_rate,
                "PricesIncludeTax"          = p_prices_include_tax,
                "SpecialTaxRate"            = p_special_tax_rate,
                "SpecialTaxEnabled"         = p_special_tax_enabled,
                "TaxAuthorityCode"          = p_tax_authority_code,
                "FiscalIdName"              = p_fiscal_id_name,
                "TimeZoneIana"              = p_timezone_iana,
                "PhonePrefix"              = p_phone_prefix,
                "SortOrder"                 = p_sort_order,
                "IsActive"                  = p_is_active,
                "UpdatedAt"                 = (NOW() AT TIME ZONE 'UTC')
            WHERE "CountryCode" = p_country_code;

            p_resultado := 0;
            p_mensaje   := 'PaÃ­s actualizado correctamente.';
        ELSE
            INSERT INTO cfg."Country" (
                "CountryCode", "CountryName", "CurrencyCode", "CurrencySymbol",
                "ReferenceCurrency", "ReferenceCurrencySymbol", "DefaultExchangeRate",
                "PricesIncludeTax", "SpecialTaxRate", "SpecialTaxEnabled",
                "TaxAuthorityCode", "FiscalIdName", "TimeZoneIana", "PhonePrefix",
                "SortOrder", "IsActive", "CreatedAt", "UpdatedAt"
            )
            VALUES (
                p_country_code, p_country_name, p_currency_code, p_currency_symbol,
                p_reference_currency, p_reference_currency_symbol, p_default_exchange_rate,
                p_prices_include_tax, p_special_tax_rate, p_special_tax_enabled,
                p_tax_authority_code, p_fiscal_id_name, p_timezone_iana, p_phone_prefix,
                p_sort_order, p_is_active,
                (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
            );

            p_resultado := 0;
            p_mensaje   := 'PaÃ­s creado correctamente.';
        END IF;

    EXCEPTION WHEN OTHERS THEN
        p_resultado := -1;
        p_mensaje   := SQLERRM;
    END;
END;
$function$
;

-- usp_cfg_entityimage_link
DROP FUNCTION IF EXISTS public.usp_cfg_entityimage_link(integer, integer, character varying, integer, integer, character varying, integer, boolean, integer) CASCADE;
DROP FUNCTION IF EXISTS public.usp_cfg_entityimage_link(p_company_id integer, p_branch_id integer, p_entity_type character varying, p_entity_id integer, p_media_asset_id integer, p_role_code character varying DEFAULT NULL::character varying, p_sort_order integer DEFAULT 0, p_is_primary boolean DEFAULT false, p_actor_user_id integer DEFAULT NULL::integer)
 RETURNS TABLE("entityImageId" integer, "entityType" character varying, "entityId" integer, "mediaAssetId" integer, "roleCode" character varying, "sortOrder" integer, "isPrimary" boolean, "publicUrl" character varying, "mimeType" character varying)
 LANGUAGE plpgsql
AS $function$
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
$function$
;

-- usp_cfg_entityimage_list
DROP FUNCTION IF EXISTS public.usp_cfg_entityimage_list(integer, integer, character varying, integer) CASCADE;
DROP FUNCTION IF EXISTS public.usp_cfg_entityimage_list(p_company_id integer, p_branch_id integer, p_entity_type character varying, p_entity_id integer)
 RETURNS TABLE("entityImageId" integer, "entityType" character varying, "entityId" integer, "mediaAssetId" integer, "roleCode" character varying, "sortOrder" integer, "isPrimary" boolean, "publicUrl" character varying, "originalFileName" character varying, "mimeType" character varying, "fileSizeBytes" bigint, "altText" character varying, "createdAt" timestamp without time zone)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT ei."EntityImageId", ei."EntityType", ei."EntityId", ei."MediaAssetId", ei."RoleCode", ei."SortOrder", ei."IsPrimary", ma."PublicUrl", ma."OriginalFileName", ma."MimeType", ma."FileSizeBytes", ma."AltText", ma."CreatedAt"
    FROM cfg."EntityImage" ei
    INNER JOIN cfg."MediaAsset" ma ON ma."MediaAssetId" = ei."MediaAssetId"
    WHERE ei."CompanyId" = p_company_id AND ei."BranchId" = p_branch_id AND ei."EntityType" = p_entity_type AND ei."EntityId" = p_entity_id AND ei."IsDeleted" = FALSE AND ei."IsActive" = TRUE AND ma."IsDeleted" = FALSE AND ma."IsActive" = TRUE
    ORDER BY CASE WHEN ei."IsPrimary" THEN 0 ELSE 1 END, ei."SortOrder", ei."EntityImageId";
END;
$function$
;

-- usp_cfg_entityimage_setprimary
DROP FUNCTION IF EXISTS public.usp_cfg_entityimage_setprimary(integer, integer, character varying, integer, integer, integer) CASCADE;
DROP FUNCTION IF EXISTS public.usp_cfg_entityimage_setprimary(p_company_id integer, p_branch_id integer, p_entity_type character varying, p_entity_id integer, p_entity_image_id integer, p_actor_user_id integer DEFAULT NULL::integer)
 RETURNS TABLE(affected integer)
 LANGUAGE plpgsql
AS $function$
DECLARE v_affected INT;
BEGIN
    UPDATE cfg."EntityImage" SET "IsPrimary" = FALSE, "UpdatedAt" = NOW() AT TIME ZONE 'UTC', "UpdatedByUserId" = p_actor_user_id
    WHERE "CompanyId" = p_company_id AND "BranchId" = p_branch_id AND "EntityType" = p_entity_type AND "EntityId" = p_entity_id AND "IsDeleted" = FALSE AND "IsActive" = TRUE;

    UPDATE cfg."EntityImage" SET "IsPrimary" = TRUE, "UpdatedAt" = NOW() AT TIME ZONE 'UTC', "UpdatedByUserId" = p_actor_user_id
    WHERE "CompanyId" = p_company_id AND "BranchId" = p_branch_id AND "EntityType" = p_entity_type AND "EntityId" = p_entity_id AND "EntityImageId" = p_entity_image_id AND "IsDeleted" = FALSE AND "IsActive" = TRUE;

    GET DIAGNOSTICS v_affected = ROW_COUNT;
    RETURN QUERY SELECT v_affected;
END;
$function$
;

-- usp_cfg_entityimage_unlink
DROP FUNCTION IF EXISTS public.usp_cfg_entityimage_unlink(integer, integer, character varying, integer, integer, integer) CASCADE;
DROP FUNCTION IF EXISTS public.usp_cfg_entityimage_unlink(p_company_id integer, p_branch_id integer, p_entity_type character varying, p_entity_id integer, p_entity_image_id integer, p_actor_user_id integer DEFAULT NULL::integer)
 RETURNS TABLE(ok integer)
 LANGUAGE plpgsql
AS $function$
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
$function$
;

-- usp_cfg_exchangerate_upsert
DROP FUNCTION IF EXISTS public.usp_cfg_exchangerate_upsert(date, numeric, numeric, character varying) CASCADE;
DROP FUNCTION IF EXISTS public.usp_cfg_exchangerate_upsert(p_rate_date date, p_tasa_usd numeric, p_tasa_eur numeric, p_source_name character varying)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
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
$function$
;

-- usp_cfg_fiscal_getconfig
DROP FUNCTION IF EXISTS public.usp_cfg_fiscal_getconfig(integer, integer, character varying) CASCADE;
DROP FUNCTION IF EXISTS public.usp_cfg_fiscal_getconfig(p_empresa_id integer, p_sucursal_id integer, p_country_code character varying)
 RETURNS TABLE("EmpresaId" integer, "SucursalId" integer, "CountryCode" character varying, "Currency" character varying, "TaxRegime" character varying, "DefaultTaxCode" character varying, "DefaultTaxRate" numeric, "FiscalPrinterEnabled" boolean, "PrinterBrand" character varying, "PrinterPort" character varying, "VerifactuEnabled" boolean, "VerifactuMode" character varying, "CertificatePath" character varying, "CertificatePassword" character varying, "AEATEndpoint" character varying, "SenderNIF" character varying, "SenderRIF" character varying, "SoftwareId" character varying, "SoftwareName" character varying, "SoftwareVersion" character varying, "PosEnabled" boolean, "RestaurantEnabled" boolean)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        fc."CompanyId", fc."BranchId", fc."CountryCode"::VARCHAR,
        fc."Currency"::VARCHAR, fc."TaxRegime", fc."DefaultTaxCode",
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
$function$
;

-- usp_cfg_fiscal_getlatestrecord
DROP FUNCTION IF EXISTS public.usp_cfg_fiscal_getlatestrecord(integer, integer, character varying) CASCADE;
DROP FUNCTION IF EXISTS public.usp_cfg_fiscal_getlatestrecord(p_empresa_id integer, p_sucursal_id integer, p_country_code character varying)
 RETURNS TABLE("Id" bigint, "InvoiceId" integer, "CountryCode" character varying, "InvoiceType" character varying, "XmlContent" character varying, "RecordHash" character varying, "PreviousRecordHash" character varying, "DigitalSignature" character varying, "QRCodeData" character varying, "SentToAuthority" boolean, "AuthorityResponse" character varying, "CreatedAt" timestamp without time zone)
 LANGUAGE plpgsql
AS $function$
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
$function$
;

-- usp_cfg_fiscal_hasrecordstable
DROP FUNCTION IF EXISTS public.usp_cfg_fiscal_hasrecordstable() CASCADE;
CREATE OR REPLACE FUNCTION public.usp_cfg_fiscal_hasrecordstable()
 RETURNS TABLE("hasTable" integer)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT CASE WHEN EXISTS(
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = 'fiscal' AND table_name = 'Record'
    ) THEN 1 ELSE 0 END;
END;
$function$
;

-- usp_cfg_fiscal_hastable
DROP FUNCTION IF EXISTS public.usp_cfg_fiscal_hastable() CASCADE;
CREATE OR REPLACE FUNCTION public.usp_cfg_fiscal_hastable()
 RETURNS TABLE("hasTable" integer)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT CASE WHEN EXISTS(
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = 'fiscal' AND table_name = 'CountryConfig'
    ) THEN 1 ELSE 0 END;
END;
$function$
;

-- usp_cfg_fiscal_infercountry
DROP FUNCTION IF EXISTS public.usp_cfg_fiscal_infercountry(integer, integer) CASCADE;
DROP FUNCTION IF EXISTS public.usp_cfg_fiscal_infercountry(p_empresa_id integer, p_sucursal_id integer)
 RETURNS TABLE("CountryCode" character varying)
 LANGUAGE plpgsql
AS $function$
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
$function$
;

-- usp_cfg_fiscal_insertrecord
DROP FUNCTION IF EXISTS public.usp_cfg_fiscal_insertrecord(integer, integer, character varying, integer, character varying, character varying, timestamp without time zone, character varying, numeric, character varying, character varying, text, text, text, boolean, timestamp without time zone, text, character varying, character varying, character varying, integer) CASCADE;
DROP FUNCTION IF EXISTS public.usp_cfg_fiscal_insertrecord(p_empresa_id integer, p_sucursal_id integer, p_country_code character varying, p_invoice_id integer, p_invoice_type character varying, p_invoice_number character varying, p_invoice_date timestamp without time zone, p_recipient_id character varying DEFAULT NULL::character varying, p_total_amount numeric DEFAULT 0, p_record_hash character varying DEFAULT NULL::character varying, p_previous_record_hash character varying DEFAULT NULL::character varying, p_xml_content text DEFAULT NULL::text, p_digital_signature text DEFAULT NULL::text, p_qr_code_data text DEFAULT NULL::text, p_sent_to_authority boolean DEFAULT false, p_sent_at timestamp without time zone DEFAULT NULL::timestamp without time zone, p_authority_response text DEFAULT NULL::text, p_authority_status character varying DEFAULT NULL::character varying, p_fiscal_printer_serial character varying DEFAULT NULL::character varying, p_fiscal_control_number character varying DEFAULT NULL::character varying, p_z_report_number integer DEFAULT NULL::integer)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
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
$function$
;

-- usp_cfg_fiscal_upsertconfig
DROP FUNCTION IF EXISTS public.usp_cfg_fiscal_upsertconfig(integer, integer, character varying, character varying, character varying, character varying, numeric, boolean, character varying, character varying, boolean, character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying, boolean, boolean) CASCADE;
DROP FUNCTION IF EXISTS public.usp_cfg_fiscal_upsertconfig(p_empresa_id integer, p_sucursal_id integer, p_country_code character varying, p_currency character varying, p_tax_regime character varying, p_default_tax_code character varying, p_default_tax_rate numeric, p_fiscal_printer_enabled boolean, p_printer_brand character varying DEFAULT NULL::character varying, p_printer_port character varying DEFAULT NULL::character varying, p_verifactu_enabled boolean DEFAULT false, p_verifactu_mode character varying DEFAULT NULL::character varying, p_certificate_path character varying DEFAULT NULL::character varying, p_certificate_password character varying DEFAULT NULL::character varying, p_aeat_endpoint character varying DEFAULT NULL::character varying, p_sender_nif character varying DEFAULT NULL::character varying, p_sender_rif character varying DEFAULT NULL::character varying, p_software_id character varying DEFAULT NULL::character varying, p_software_name character varying DEFAULT NULL::character varying, p_software_version character varying DEFAULT NULL::character varying, p_pos_enabled boolean DEFAULT false, p_restaurant_enabled boolean DEFAULT false)
 RETURNS TABLE("Affected" integer)
 LANGUAGE plpgsql
AS $function$
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
$function$
;

-- usp_cfg_mediaasset_getbyid
DROP FUNCTION IF EXISTS public.usp_cfg_mediaasset_getbyid(integer, integer, integer) CASCADE;
DROP FUNCTION IF EXISTS public.usp_cfg_mediaasset_getbyid(p_company_id integer, p_branch_id integer, p_media_asset_id integer)
 RETURNS TABLE("mediaAssetId" integer, "storageKey" character varying, "publicUrl" character varying, "mimeType" character varying, "originalFileName" character varying, "fileSizeBytes" bigint, "isActive" boolean, "isDeleted" boolean)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT ma."MediaAssetId", ma."StorageKey", ma."PublicUrl", ma."MimeType", ma."OriginalFileName", ma."FileSizeBytes", ma."IsActive", ma."IsDeleted"
    FROM cfg."MediaAsset" ma
    WHERE ma."CompanyId" = p_company_id AND ma."BranchId" = p_branch_id AND ma."MediaAssetId" = p_media_asset_id
    LIMIT 1;
END;
$function$
;

-- usp_cfg_mediaasset_getbystoragekey
DROP FUNCTION IF EXISTS public.usp_cfg_mediaasset_getbystoragekey(integer, integer, character varying) CASCADE;
DROP FUNCTION IF EXISTS public.usp_cfg_mediaasset_getbystoragekey(p_company_id integer, p_branch_id integer, p_storage_key character varying)
 RETURNS TABLE("mediaAssetId" integer)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT ma."MediaAssetId"
    FROM cfg."MediaAsset" ma
    WHERE ma."CompanyId" = p_company_id AND ma."BranchId" = p_branch_id AND ma."StorageKey" = p_storage_key AND ma."IsDeleted" = FALSE AND ma."IsActive" = TRUE
    ORDER BY ma."MediaAssetId" DESC LIMIT 1;
END;
$function$
;

-- usp_cfg_mediaasset_insert
DROP FUNCTION IF EXISTS public.usp_cfg_mediaasset_insert(integer, integer, character varying, character varying, character varying, character varying, character varying, bigint, character varying, character varying, integer) CASCADE;
DROP FUNCTION IF EXISTS public.usp_cfg_mediaasset_insert(p_company_id integer, p_branch_id integer, p_storage_key character varying, p_public_url character varying, p_original_file_name character varying DEFAULT NULL::character varying, p_mime_type character varying DEFAULT NULL::character varying, p_file_extension character varying DEFAULT NULL::character varying, p_file_size_bytes bigint DEFAULT 0, p_checksum_sha256 character varying DEFAULT NULL::character varying, p_alt_text character varying DEFAULT NULL::character varying, p_actor_user_id integer DEFAULT NULL::integer)
 RETURNS TABLE("mediaAssetId" integer)
 LANGUAGE plpgsql
AS $function$
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
$function$
;

-- usp_cfg_resolvecontext
DROP FUNCTION IF EXISTS public.usp_cfg_resolvecontext(character varying) CASCADE;
DROP FUNCTION IF EXISTS public.usp_cfg_resolvecontext(p_user_code character varying DEFAULT NULL::character varying)
 RETURNS TABLE("CompanyId" integer, "BranchId" integer, "UserId" integer)
 LANGUAGE plpgsql
AS $function$
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
$function$
;

-- usp_cfg_scope_getdefault
DROP FUNCTION IF EXISTS public.usp_cfg_scope_getdefault() CASCADE;
CREATE OR REPLACE FUNCTION public.usp_cfg_scope_getdefault()
 RETURNS TABLE("companyId" integer, "branchId" integer, "systemUserId" integer)
 LANGUAGE plpgsql
AS $function$
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
$function$
;

-- usp_cfg_scope_getdefaultcompanyuser
DROP FUNCTION IF EXISTS public.usp_cfg_scope_getdefaultcompanyuser() CASCADE;
CREATE OR REPLACE FUNCTION public.usp_cfg_scope_getdefaultcompanyuser()
 RETURNS TABLE("companyId" integer, "systemUserId" integer)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT c."CompanyId", su."UserId"
    FROM cfg."Company" c
    LEFT JOIN sec."User" su ON su."UserCode" = 'SYSTEM'
    WHERE c."CompanyCode" = 'DEFAULT'
    ORDER BY c."CompanyId"
    LIMIT 1;
END;
$function$
;

-- usp_empresa_get
DROP FUNCTION IF EXISTS public.usp_empresa_get() CASCADE;
CREATE OR REPLACE FUNCTION public.usp_empresa_get()
 RETURNS TABLE("Empresa" character varying, "RIF" character varying, "Nit" character varying, "Telefono" character varying, "Direccion" character varying, "Rifs" character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        e."Empresa",
        e."RIF",
        e."Nit",
        e."Telefono",
        e."Direccion",
        e."Rifs"
    FROM public."Empresa" e
    LIMIT 1;
END;
$function$
;

-- usp_empresa_update
DROP FUNCTION IF EXISTS public.usp_empresa_update(jsonb) CASCADE;
DROP FUNCTION IF EXISTS public.usp_empresa_update(p_row_json jsonb)
 RETURNS TABLE("Resultado" integer, "Mensaje" character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public."Empresa") THEN
        RETURN QUERY SELECT -1, 'Empresa no encontrada'::VARCHAR(500);
        RETURN;
    END IF;

    UPDATE public."Empresa" SET
        "Empresa"   = COALESCE(NULLIF(p_row_json->>'Empresa', ''::character varying), "Empresa")::character varying,
        "RIF"       = COALESCE(NULLIF(p_row_json->>'RIF', ''::character varying), "RIF")::character varying,
        "Nit"       = COALESCE(NULLIF(p_row_json->>'Nit', ''::character varying), "Nit")::character varying,
        "Telefono"  = COALESCE(NULLIF(p_row_json->>'Telefono', ''::character varying), "Telefono")::character varying,
        "Direccion" = COALESCE(NULLIF(p_row_json->>'Direccion', ''::character varying), "Direccion")::character varying,
        "Rifs"      = COALESCE(NULLIF(p_row_json->>'Rifs', ''::character varying), "Rifs")::character varying;

    RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
END;
$function$
;

-- usp_feriados_delete
DROP FUNCTION IF EXISTS public.usp_feriados_delete(date) CASCADE;
DROP FUNCTION IF EXISTS public.usp_feriados_delete(p_fecha date)
 RETURNS TABLE("Resultado" integer, "Mensaje" character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public."Feriados" WHERE "Fecha"::DATE = p_fecha) THEN
        RETURN QUERY SELECT -1, 'Feriado no encontrado'::VARCHAR(500);
        RETURN;
    END IF;

    DELETE FROM public."Feriados" WHERE "Fecha"::DATE = p_fecha;

    RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
END;
$function$
;

-- usp_feriados_getbyfecha
DROP FUNCTION IF EXISTS public.usp_feriados_getbyfecha(date) CASCADE;
DROP FUNCTION IF EXISTS public.usp_feriados_getbyfecha(p_fecha date)
 RETURNS TABLE("Fecha" date, "Descripcion" character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        f."Fecha"::DATE,
        f."Descripcion"
    FROM public."Feriados" f
    WHERE f."Fecha"::DATE = p_fecha;
END;
$function$
;

-- usp_feriados_insert
DROP FUNCTION IF EXISTS public.usp_feriados_insert(jsonb) CASCADE;
DROP FUNCTION IF EXISTS public.usp_feriados_insert(p_row_json jsonb)
 RETURNS TABLE("Resultado" integer, "Mensaje" character varying)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_fecha DATE;
BEGIN
    v_fecha := (p_row_json->>'Fecha')::DATE;

    IF EXISTS (
        SELECT 1 FROM public."Feriados"
        WHERE "Fecha"::DATE = v_fecha
    ) THEN
        RETURN QUERY SELECT -1, 'Feriado ya existe para esta fecha'::VARCHAR(500);
        RETURN;
    END IF;

    INSERT INTO public."Feriados" ("Fecha", "Descripcion")
    VALUES (
        v_fecha,
        NULLIF(p_row_json->>'Descripcion', ''::character varying)
    );

    RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
END;
$function$
;

-- usp_feriados_list
DROP FUNCTION IF EXISTS public.usp_feriados_list(character varying, integer, integer, integer) CASCADE;
DROP FUNCTION IF EXISTS public.usp_feriados_list(p_search character varying DEFAULT NULL::character varying, p_anio integer DEFAULT NULL::integer, p_page integer DEFAULT 1, p_limit integer DEFAULT 50)
 RETURNS TABLE("TotalCount" integer, "Fecha" date, "Descripcion" character varying)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_offset  INT;
    v_limit   INT;
    v_search  VARCHAR(100);
    v_total   INT;
BEGIN
    v_limit  := COALESCE(NULLIF(p_limit, 0), 50);
    IF v_limit < 1 THEN v_limit := 50; END IF;
    IF v_limit > 500 THEN v_limit := 500; END IF;
    v_offset := (COALESCE(NULLIF(p_page, 0), 1) - 1) * v_limit;
    IF v_offset < 0 THEN v_offset := 0; END IF;

    v_search := NULL;
    IF p_search IS NOT NULL AND TRIM(p_search) <> '' THEN
        v_search := '%' || p_search || '%';
    END IF;

    -- Contar total
    SELECT COUNT(1) INTO v_total
    FROM public."Feriados" f
    WHERE (v_search IS NULL OR f."Descripcion" LIKE v_search)
      AND (p_anio IS NULL OR EXTRACT(YEAR FROM f."Fecha") = p_anio);

    -- Devolver filas
    RETURN QUERY
    SELECT
        v_total,
        f."Fecha"::DATE,
        f."Descripcion"
    FROM public."Feriados" f
    WHERE (v_search IS NULL OR f."Descripcion" LIKE v_search)
      AND (p_anio IS NULL OR EXTRACT(YEAR FROM f."Fecha") = p_anio)
    ORDER BY f."Fecha"
    LIMIT v_limit OFFSET v_offset;
END;
$function$
;

-- usp_feriados_update
DROP FUNCTION IF EXISTS public.usp_feriados_update(date, jsonb) CASCADE;
DROP FUNCTION IF EXISTS public.usp_feriados_update(p_fecha date, p_row_json jsonb)
 RETURNS TABLE("Resultado" integer, "Mensaje" character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public."Feriados" WHERE "Fecha"::DATE = p_fecha) THEN
        RETURN QUERY SELECT -1, 'Feriado no encontrado'::VARCHAR(500);
        RETURN;
    END IF;

    UPDATE public."Feriados" SET
        "Descripcion" = COALESCE(NULLIF(p_row_json->>'Descripcion', ''::character varying), "Descripcion")::character varying
    WHERE "Fecha"::DATE = p_fecha;

    RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
END;
$function$
;

-- usp_moneda_delete
DROP FUNCTION IF EXISTS public.usp_moneda_delete(character varying) CASCADE;
DROP FUNCTION IF EXISTS public.usp_moneda_delete(p_nombre character varying)
 RETURNS TABLE("Resultado" integer, "Mensaje" character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public."Moneda" WHERE "Nombre" = p_nombre) THEN
        RETURN QUERY SELECT -1, 'Moneda no encontrada'::VARCHAR(500);
        RETURN;
    END IF;

    BEGIN
        DELETE FROM public."Moneda" WHERE "Nombre" = p_nombre;

        RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
    END;
END;
$function$
;

-- usp_moneda_getbynombre
DROP FUNCTION IF EXISTS public.usp_moneda_getbynombre(character varying) CASCADE;
DROP FUNCTION IF EXISTS public.usp_moneda_getbynombre(p_nombre character varying)
 RETURNS TABLE("Nombre" character varying, "Simbolo" character varying, "Tasa_Local" double precision, "Local_Tasa" double precision, "Local" character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT m."Nombre", m."Simbolo", m."Tasa_Local", m."Local_Tasa", m."Local"
    FROM public."Moneda" m
    WHERE m."Nombre" = p_nombre;
END;
$function$
;

-- usp_moneda_insert
DROP FUNCTION IF EXISTS public.usp_moneda_insert(jsonb) CASCADE;
DROP FUNCTION IF EXISTS public.usp_moneda_insert(p_row_json jsonb)
 RETURNS TABLE("Resultado" integer, "Mensaje" character varying)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_nombre VARCHAR(50);
BEGIN
    v_nombre := NULLIF(p_row_json->>'Nombre', ''::character varying);

    IF EXISTS (SELECT 1 FROM public."Moneda" WHERE "Nombre" = v_nombre) THEN
        RETURN QUERY SELECT -1, 'Moneda ya existe'::VARCHAR(500);
        RETURN;
    END IF;

    BEGIN
        INSERT INTO public."Moneda" ("Nombre", "Simbolo", "Tasa_Local", "Local_Tasa", "Local")
        VALUES (
            v_nombre,
            NULLIF(p_row_json->>'Simbolo', ''::character varying),
            CASE WHEN p_row_json->>'Tasa_Local' IS NULL OR p_row_json->>'Tasa_Local' = '' THEN NULL
                 ELSE (p_row_json->>'Tasa_Local')::DOUBLE PRECISION END,
            CASE WHEN p_row_json->>'Local_Tasa' IS NULL OR p_row_json->>'Local_Tasa' = '' THEN NULL
                 ELSE (p_row_json->>'Local_Tasa')::DOUBLE PRECISION END,
            NULLIF(p_row_json->>'Local', ''::character varying)
        );

        RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
    END;
END;
$function$
;

-- usp_moneda_list
DROP FUNCTION IF EXISTS public.usp_moneda_list(character varying, integer, integer) CASCADE;
DROP FUNCTION IF EXISTS public.usp_moneda_list(p_search character varying DEFAULT NULL::character varying, p_page integer DEFAULT 1, p_limit integer DEFAULT 50)
 RETURNS TABLE("Nombre" character varying, "Simbolo" character varying, "Tasa_Local" double precision, "Local_Tasa" double precision, "Local" character varying, "TotalCount" bigint)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_offset INT;
    v_total BIGINT;
    v_search_param VARCHAR(100);
BEGIN
    v_offset := (COALESCE(NULLIF(p_page, 0), 1) - 1) * COALESCE(NULLIF(p_limit, 0), 50);
    IF v_offset < 0 THEN v_offset := 0; END IF;
    IF p_limit < 1 THEN p_limit := 50; END IF;
    IF p_limit > 500 THEN p_limit := 500; END IF;

    v_search_param := NULL;
    IF p_search IS NOT NULL AND TRIM(p_search) <> '' THEN
        v_search_param := '%' || p_search || '%';
    END IF;

    SELECT COUNT(1) INTO v_total
    FROM public."Moneda" m
    WHERE (v_search_param IS NULL
           OR m."Nombre" LIKE v_search_param
           OR m."Simbolo" LIKE v_search_param);

    RETURN QUERY
    SELECT
        m."Nombre",
        m."Simbolo",
        m."Tasa_Local",
        m."Local_Tasa",
        m."Local",
        v_total AS "TotalCount"
    FROM public."Moneda" m
    WHERE (v_search_param IS NULL
           OR m."Nombre" LIKE v_search_param
           OR m."Simbolo" LIKE v_search_param)
    ORDER BY m."Nombre"
    LIMIT p_limit OFFSET v_offset;
END;
$function$
;

-- usp_moneda_update
DROP FUNCTION IF EXISTS public.usp_moneda_update(character varying, jsonb) CASCADE;
DROP FUNCTION IF EXISTS public.usp_moneda_update(p_nombre character varying, p_row_json jsonb)
 RETURNS TABLE("Resultado" integer, "Mensaje" character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public."Moneda" WHERE "Nombre" = p_nombre) THEN
        RETURN QUERY SELECT -1, 'Moneda no encontrada'::VARCHAR(500);
        RETURN;
    END IF;

    BEGIN
        UPDATE public."Moneda"
        SET
            "Simbolo"    = COALESCE(NULLIF(p_row_json->>'Simbolo', ''::character varying), "Simbolo")::character varying,
            "Tasa_Local" = CASE WHEN p_row_json->>'Tasa_Local' IS NULL OR p_row_json->>'Tasa_Local' = ''
                                THEN "Tasa_Local"
                                ELSE (p_row_json->>'Tasa_Local')::DOUBLE PRECISION END,
            "Local_Tasa" = CASE WHEN p_row_json->>'Local_Tasa' IS NULL OR p_row_json->>'Local_Tasa' = ''
                                THEN "Local_Tasa"
                                ELSE (p_row_json->>'Local_Tasa')::DOUBLE PRECISION END,
            "Local"      = COALESCE(NULLIF(p_row_json->>'Local', ''::character varying), "Local")::character varying
        WHERE "Nombre" = p_nombre;

        RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
    END;
END;
$function$
;

