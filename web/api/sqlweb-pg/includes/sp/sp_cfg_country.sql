-- =============================================================================
-- sp_cfg_country.sql  (PostgreSQL / PL/pgSQL)
-- Convertido desde T-SQL: web/api/sqlweb/includes/sp/sp_cfg_country.sql
-- Fecha conversión: 2026-03-16
--
-- Funciones:
--   1. usp_CFG_Country_List  - Lista países activos ordenados por SortOrder, CountryName
--   2. usp_CFG_Country_Save  - Insert o Update país (OUT params)
--   3. usp_CFG_Country_Get   - Obtener un país por código
--
-- Seed data: VE, ES, CO, MX, US
-- =============================================================================

-- =============================================================================
-- 1. usp_CFG_Country_List
-- =============================================================================
CREATE OR REPLACE FUNCTION public.usp_CFG_Country_List(
    p_active_only BOOLEAN DEFAULT TRUE
)
RETURNS TABLE (
    "CountryCode"               CHAR(2),
    "CountryName"               VARCHAR(80),
    "CurrencyCode"              CHAR(3),
    "CurrencySymbol"            VARCHAR(5),
    "ReferenceCurrency"         CHAR(3),
    "ReferenceCurrencySymbol"   VARCHAR(5),
    "DefaultExchangeRate"       NUMERIC(18,4),
    "PricesIncludeTax"          BOOLEAN,
    "SpecialTaxRate"            NUMERIC(5,2),
    "SpecialTaxEnabled"         BOOLEAN,
    "TaxAuthorityCode"          VARCHAR(20),
    "FiscalIdName"              VARCHAR(20),
    "TimeZoneIana"              VARCHAR(64),
    "PhonePrefix"               VARCHAR(5),
    "SortOrder"                 INTEGER,
    "IsActive"                  BOOLEAN,
    "CreatedAt"                 TIMESTAMP,
    "UpdatedAt"                 TIMESTAMP
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        c."CountryCode",
        c."CountryName",
        c."CurrencyCode",
        c."CurrencySymbol",
        c."ReferenceCurrency",
        c."ReferenceCurrencySymbol",
        c."DefaultExchangeRate",
        c."PricesIncludeTax",
        c."SpecialTaxRate",
        c."SpecialTaxEnabled",
        c."TaxAuthorityCode",
        c."FiscalIdName",
        c."TimeZoneIana",
        c."PhonePrefix",
        c."SortOrder",
        c."IsActive",
        c."CreatedAt",
        c."UpdatedAt"
    FROM cfg."Country" c
    WHERE (NOT p_active_only OR c."IsActive" = TRUE)
    ORDER BY c."SortOrder", c."CountryName";
END;
$$;

-- =============================================================================
-- 2. usp_CFG_Country_Save
-- =============================================================================
CREATE OR REPLACE FUNCTION public.usp_CFG_Country_Save(
    p_country_code              CHAR(2),
    p_country_name              VARCHAR(80),
    p_currency_code             CHAR(3),
    p_currency_symbol           VARCHAR(5),
    p_reference_currency        CHAR(3),
    p_reference_currency_symbol VARCHAR(5),
    p_default_exchange_rate     NUMERIC(18,4),
    p_prices_include_tax        BOOLEAN,
    p_special_tax_rate          NUMERIC(5,2),
    p_special_tax_enabled       BOOLEAN,
    p_tax_authority_code        VARCHAR(20),
    p_fiscal_id_name            VARCHAR(20),
    p_timezone_iana             VARCHAR(64),
    p_phone_prefix              VARCHAR(5),
    p_sort_order                INTEGER,
    p_is_active                 BOOLEAN,
    OUT p_resultado             INTEGER,
    OUT p_mensaje               VARCHAR(500)
)
LANGUAGE plpgsql
AS $$
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
            p_mensaje   := 'País actualizado correctamente.';
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
            p_mensaje   := 'País creado correctamente.';
        END IF;

    EXCEPTION WHEN OTHERS THEN
        p_resultado := -1;
        p_mensaje   := SQLERRM;
    END;
END;
$$;

-- =============================================================================
-- 3. usp_CFG_Country_Get
-- =============================================================================
CREATE OR REPLACE FUNCTION public.usp_CFG_Country_Get(
    p_country_code CHAR(2)
)
RETURNS TABLE (
    "CountryCode"               CHAR(2),
    "CountryName"               VARCHAR(80),
    "CurrencyCode"              CHAR(3),
    "CurrencySymbol"            VARCHAR(5),
    "ReferenceCurrency"         CHAR(3),
    "ReferenceCurrencySymbol"   VARCHAR(5),
    "DefaultExchangeRate"       NUMERIC(18,4),
    "PricesIncludeTax"          BOOLEAN,
    "SpecialTaxRate"            NUMERIC(5,2),
    "SpecialTaxEnabled"         BOOLEAN,
    "TaxAuthorityCode"          VARCHAR(20),
    "FiscalIdName"              VARCHAR(20),
    "TimeZoneIana"              VARCHAR(64),
    "PhonePrefix"               VARCHAR(5),
    "SortOrder"                 INTEGER,
    "IsActive"                  BOOLEAN,
    "CreatedAt"                 TIMESTAMP,
    "UpdatedAt"                 TIMESTAMP
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        c."CountryCode",
        c."CountryName",
        c."CurrencyCode",
        c."CurrencySymbol",
        c."ReferenceCurrency",
        c."ReferenceCurrencySymbol",
        c."DefaultExchangeRate",
        c."PricesIncludeTax",
        c."SpecialTaxRate",
        c."SpecialTaxEnabled",
        c."TaxAuthorityCode",
        c."FiscalIdName",
        c."TimeZoneIana",
        c."PhonePrefix",
        c."SortOrder",
        c."IsActive",
        c."CreatedAt",
        c."UpdatedAt"
    FROM cfg."Country" c
    WHERE c."CountryCode" = p_country_code;
END;
$$;

-- =============================================================================
-- Seed data
-- =============================================================================

-- Venezuela
INSERT INTO cfg."Country" (
    "CountryCode", "CountryName", "CurrencyCode", "CurrencySymbol",
    "ReferenceCurrency", "ReferenceCurrencySymbol", "DefaultExchangeRate",
    "PricesIncludeTax", "SpecialTaxRate", "SpecialTaxEnabled",
    "TaxAuthorityCode", "FiscalIdName", "TimeZoneIana", "PhonePrefix",
    "SortOrder", "IsActive", "CreatedAt", "UpdatedAt"
)
VALUES (
    'VE', 'Venezuela', 'VEF', 'Bs',
    'USD', '$', 45.0,
    TRUE, 3, TRUE,
    'SENIAT', 'RIF', 'America/Caracas', '+58',
    1, TRUE, (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
)
ON CONFLICT ("CountryCode") DO UPDATE
SET "CurrencySymbol"            = 'Bs',
    "ReferenceCurrency"         = 'USD',
    "ReferenceCurrencySymbol"   = '$',
    "DefaultExchangeRate"       = 45.0,
    "PricesIncludeTax"          = TRUE,
    "SpecialTaxRate"            = 3,
    "SpecialTaxEnabled"         = TRUE,
    "PhonePrefix"               = '+58',
    "SortOrder"                 = 1,
    "UpdatedAt"                 = (NOW() AT TIME ZONE 'UTC');

-- España
INSERT INTO cfg."Country" (
    "CountryCode", "CountryName", "CurrencyCode", "CurrencySymbol",
    "ReferenceCurrency", "ReferenceCurrencySymbol", "DefaultExchangeRate",
    "PricesIncludeTax", "SpecialTaxRate", "SpecialTaxEnabled",
    "TaxAuthorityCode", "FiscalIdName", "TimeZoneIana", "PhonePrefix",
    "SortOrder", "IsActive", "CreatedAt", "UpdatedAt"
)
VALUES (
    'ES', 'España', 'EUR', '€',
    'USD', '$', 1.0,
    TRUE, 0, FALSE,
    'AEAT', 'NIF', 'Europe/Madrid', '+34',
    2, TRUE, (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
)
ON CONFLICT ("CountryCode") DO UPDATE
SET "CurrencySymbol"            = '€',
    "ReferenceCurrency"         = 'USD',
    "ReferenceCurrencySymbol"   = '$',
    "DefaultExchangeRate"       = 1.0,
    "PricesIncludeTax"          = TRUE,
    "SpecialTaxRate"            = 0,
    "SpecialTaxEnabled"         = FALSE,
    "PhonePrefix"               = '+34',
    "SortOrder"                 = 2,
    "UpdatedAt"                 = (NOW() AT TIME ZONE 'UTC');

-- Colombia
INSERT INTO cfg."Country" (
    "CountryCode", "CountryName", "CurrencyCode", "CurrencySymbol",
    "ReferenceCurrency", "ReferenceCurrencySymbol", "DefaultExchangeRate",
    "PricesIncludeTax", "SpecialTaxRate", "SpecialTaxEnabled",
    "TaxAuthorityCode", "FiscalIdName", "TimeZoneIana", "PhonePrefix",
    "SortOrder", "IsActive", "CreatedAt", "UpdatedAt"
)
VALUES (
    'CO', 'Colombia', 'COP', '$',
    'USD', '$', 4000,
    FALSE, 0, FALSE,
    'DIAN', 'NIT', 'America/Bogota', '+57',
    3, TRUE, (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
)
ON CONFLICT ("CountryCode") DO NOTHING;

-- México
INSERT INTO cfg."Country" (
    "CountryCode", "CountryName", "CurrencyCode", "CurrencySymbol",
    "ReferenceCurrency", "ReferenceCurrencySymbol", "DefaultExchangeRate",
    "PricesIncludeTax", "SpecialTaxRate", "SpecialTaxEnabled",
    "TaxAuthorityCode", "FiscalIdName", "TimeZoneIana", "PhonePrefix",
    "SortOrder", "IsActive", "CreatedAt", "UpdatedAt"
)
VALUES (
    'MX', 'México', 'MXN', '$',
    'USD', '$', 18.0,
    FALSE, 0, FALSE,
    'SAT', 'RFC', 'America/Mexico_City', '+52',
    4, TRUE, (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
)
ON CONFLICT ("CountryCode") DO NOTHING;

-- Estados Unidos
INSERT INTO cfg."Country" (
    "CountryCode", "CountryName", "CurrencyCode", "CurrencySymbol",
    "ReferenceCurrency", "ReferenceCurrencySymbol", "DefaultExchangeRate",
    "PricesIncludeTax", "SpecialTaxRate", "SpecialTaxEnabled",
    "TaxAuthorityCode", "FiscalIdName", "TimeZoneIana", "PhonePrefix",
    "SortOrder", "IsActive", "CreatedAt", "UpdatedAt"
)
VALUES (
    'US', 'Estados Unidos', 'USD', '$',
    'EUR', '€', 1.0,
    FALSE, 0, FALSE,
    'IRS', 'EIN', 'America/New_York', '+1',
    5, TRUE, (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
)
ON CONFLICT ("CountryCode") DO NOTHING;
