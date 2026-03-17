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
--
-- NOTA: cfg."Country" solo tiene las columnas definidas en 01_core_foundation.sql:
--   CountryCode, CountryName, CurrencyCode, TaxAuthorityCode, FiscalIdName,
--   IsActive, CreatedAt, UpdatedAt
-- =============================================================================

-- =============================================================================
-- Drop existing functions to allow return type changes
-- =============================================================================
DROP FUNCTION IF EXISTS public.usp_CFG_Country_List(BOOLEAN);
DROP FUNCTION IF EXISTS public.usp_CFG_Country_Get(CHAR);

-- =============================================================================
-- 1. usp_CFG_Country_List
-- =============================================================================
CREATE OR REPLACE FUNCTION public.usp_CFG_Country_List(
    p_active_only BOOLEAN DEFAULT TRUE
)
RETURNS TABLE (
    "CountryCode"       CHAR(2),
    "CountryName"       VARCHAR(80),
    "CurrencyCode"      CHAR(3),
    "TaxAuthorityCode"  VARCHAR(20),
    "FiscalIdName"      VARCHAR(20),
    "IsActive"          BOOLEAN,
    "CreatedAt"         TIMESTAMP,
    "UpdatedAt"         TIMESTAMP
)
LANGUAGE plpgsql
AS $$
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
$$;

-- =============================================================================
-- 2. usp_CFG_Country_Save
-- Full-parameter version: API sends TimeZoneIana -> p_time_zone_iana (with underscore)
-- Drop ALL overloads before recreating
-- =============================================================================
DO $$
DECLARE r record;
BEGIN
    FOR r IN SELECT oid, pg_get_function_identity_arguments(oid) as args
             FROM pg_proc WHERE proname = 'usp_cfg_country_save'
    LOOP
        EXECUTE 'DROP FUNCTION IF EXISTS public.usp_cfg_country_save(' || r.args || ') CASCADE';
    END LOOP;
END;
$$;

CREATE OR REPLACE FUNCTION public.usp_CFG_Country_Save(
    p_country_code              VARCHAR(3),
    p_country_name              VARCHAR(80),
    p_currency_code             VARCHAR(5),
    p_currency_symbol           VARCHAR(10) DEFAULT '$',
    p_reference_currency        VARCHAR(5) DEFAULT 'USD',
    p_reference_currency_symbol VARCHAR(10) DEFAULT '$',
    p_default_exchange_rate     NUMERIC(18,6) DEFAULT 1.0,
    p_prices_include_tax        BOOLEAN DEFAULT FALSE,
    p_special_tax_rate          NUMERIC(10,4) DEFAULT 0,
    p_special_tax_enabled       BOOLEAN DEFAULT FALSE,
    p_tax_authority_code        VARCHAR(20) DEFAULT NULL,
    p_fiscal_id_name            VARCHAR(20) DEFAULT NULL,
    p_time_zone_iana            VARCHAR(60) DEFAULT NULL,
    p_phone_prefix              VARCHAR(10) DEFAULT NULL,
    p_sort_order                INT DEFAULT 100,
    p_is_active                 BOOLEAN DEFAULT TRUE,
    OUT p_resultado             INTEGER,
    OUT p_mensaje               VARCHAR(500)
)
LANGUAGE plpgsql AS $$
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
            p_mensaje   := 'Pais actualizado correctamente.';
        ELSE
            INSERT INTO cfg."Country" (
                "CountryCode", "CountryName", "CurrencyCode",
                "TaxAuthorityCode", "FiscalIdName",
                "IsActive", "CreatedAt", "UpdatedAt"
            ) VALUES (
                p_country_code, p_country_name, p_currency_code,
                p_tax_authority_code, p_fiscal_id_name,
                p_is_active,
                (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
            );

            p_resultado := 0;
            p_mensaje   := 'Pais creado correctamente.';
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
DROP FUNCTION IF EXISTS public.usp_CFG_Country_Get(CHAR(2)) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_CFG_Country_Get(
    p_country_code CHAR(2)
)
RETURNS TABLE (
    "CountryCode"       CHAR(2),
    "CountryName"       VARCHAR(80),
    "CurrencyCode"      CHAR(3),
    "TaxAuthorityCode"  VARCHAR(20),
    "FiscalIdName"      VARCHAR(20),
    "IsActive"          BOOLEAN,
    "CreatedAt"         TIMESTAMP,
    "UpdatedAt"         TIMESTAMP
)
LANGUAGE plpgsql
AS $$
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
$$;

-- =============================================================================
-- Seed data
-- =============================================================================

-- Venezuela
INSERT INTO cfg."Country" (
    "CountryCode", "CountryName", "CurrencyCode",
    "TaxAuthorityCode", "FiscalIdName",
    "IsActive", "CreatedAt", "UpdatedAt"
)
VALUES (
    'VE', 'Venezuela', 'VEF',
    'SENIAT', 'RIF',
    TRUE, (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
)
ON CONFLICT ("CountryCode") DO UPDATE
SET "CountryName"       = 'Venezuela',
    "CurrencyCode"      = 'VEF',
    "TaxAuthorityCode"  = 'SENIAT',
    "FiscalIdName"      = 'RIF',
    "IsActive"          = TRUE,
    "UpdatedAt"         = (NOW() AT TIME ZONE 'UTC');

-- España
INSERT INTO cfg."Country" (
    "CountryCode", "CountryName", "CurrencyCode",
    "TaxAuthorityCode", "FiscalIdName",
    "IsActive", "CreatedAt", "UpdatedAt"
)
VALUES (
    'ES', 'España', 'EUR',
    'AEAT', 'NIF',
    TRUE, (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
)
ON CONFLICT ("CountryCode") DO UPDATE
SET "CountryName"       = 'España',
    "CurrencyCode"      = 'EUR',
    "TaxAuthorityCode"  = 'AEAT',
    "FiscalIdName"      = 'NIF',
    "IsActive"          = TRUE,
    "UpdatedAt"         = (NOW() AT TIME ZONE 'UTC');

-- Colombia
INSERT INTO cfg."Country" (
    "CountryCode", "CountryName", "CurrencyCode",
    "TaxAuthorityCode", "FiscalIdName",
    "IsActive", "CreatedAt", "UpdatedAt"
)
VALUES (
    'CO', 'Colombia', 'COP',
    'DIAN', 'NIT',
    TRUE, (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
)
ON CONFLICT ("CountryCode") DO NOTHING;

-- México
INSERT INTO cfg."Country" (
    "CountryCode", "CountryName", "CurrencyCode",
    "TaxAuthorityCode", "FiscalIdName",
    "IsActive", "CreatedAt", "UpdatedAt"
)
VALUES (
    'MX', 'México', 'MXN',
    'SAT', 'RFC',
    TRUE, (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
)
ON CONFLICT ("CountryCode") DO NOTHING;

-- Estados Unidos
INSERT INTO cfg."Country" (
    "CountryCode", "CountryName", "CurrencyCode",
    "TaxAuthorityCode", "FiscalIdName",
    "IsActive", "CreatedAt", "UpdatedAt"
)
VALUES (
    'US', 'Estados Unidos', 'USD',
    'IRS', 'EIN',
    TRUE, (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
)
ON CONFLICT ("CountryCode") DO NOTHING;
