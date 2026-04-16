-- +goose Up

-- Extiende cfg.Country con los campos de localización fiscal/monetaria
-- necesarios para auto-configurar tenants por país (multi-país, multi-moneda).
-- Fuente de verdad única: cfg.Country. Sin hardcode en código.

-- +goose StatementBegin
DO $$
BEGIN
  -- ReferenceCurrency: código ISO de moneda de referencia (USD, EUR, etc.)
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'cfg' AND table_name = 'Country' AND column_name = 'ReferenceCurrency'
  ) THEN
    ALTER TABLE cfg."Country" ADD COLUMN "ReferenceCurrency" VARCHAR(3) NOT NULL DEFAULT 'USD';
  END IF;

  -- ReferenceCurrencySymbol: símbolo de moneda de referencia ($, €)
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'cfg' AND table_name = 'Country' AND column_name = 'ReferenceCurrencySymbol'
  ) THEN
    ALTER TABLE cfg."Country" ADD COLUMN "ReferenceCurrencySymbol" VARCHAR(8) NOT NULL DEFAULT '$';
  END IF;

  -- DefaultExchangeRate: tasa inicial local→referencia al provisionar tenant
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'cfg' AND table_name = 'Country' AND column_name = 'DefaultExchangeRate'
  ) THEN
    ALTER TABLE cfg."Country" ADD COLUMN "DefaultExchangeRate" NUMERIC(18,8) NOT NULL DEFAULT 1.0;
  END IF;

  -- PricesIncludeTax: régimen fiscal — si los precios mostrados incluyen IVA
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'cfg' AND table_name = 'Country' AND column_name = 'PricesIncludeTax'
  ) THEN
    ALTER TABLE cfg."Country" ADD COLUMN "PricesIncludeTax" BOOLEAN NOT NULL DEFAULT FALSE;
  END IF;

  -- SpecialTaxRate: tasa de impuesto especial del país (IGTF en VE, etc.)
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'cfg' AND table_name = 'Country' AND column_name = 'SpecialTaxRate'
  ) THEN
    ALTER TABLE cfg."Country" ADD COLUMN "SpecialTaxRate" NUMERIC(10,4) NOT NULL DEFAULT 0;
  END IF;

  -- SpecialTaxEnabled: si el impuesto especial aplica por defecto
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'cfg' AND table_name = 'Country' AND column_name = 'SpecialTaxEnabled'
  ) THEN
    ALTER TABLE cfg."Country" ADD COLUMN "SpecialTaxEnabled" BOOLEAN NOT NULL DEFAULT FALSE;
  END IF;
END $$;
-- +goose StatementEnd

-- Seed/update de países soportados — fuente de verdad de configuración fiscal
-- +goose StatementBegin
INSERT INTO cfg."Country" (
  "CountryCode", "CountryName", "Iso3", "CurrencyCode", "CurrencySymbol",
  "ReferenceCurrency", "ReferenceCurrencySymbol", "DefaultExchangeRate",
  "PricesIncludeTax", "SpecialTaxRate", "SpecialTaxEnabled",
  "TaxAuthorityCode", "FiscalIdName", "TimeZoneIana", "PhonePrefix", "FlagEmoji",
  "SortOrder", "IsActive"
) VALUES
  ('VE', 'Venezuela',      'VEN', 'VES', 'Bs', 'USD', '$', 45.0,  TRUE,  3,    TRUE,  'SENIAT', 'RIF', 'America/Caracas',   '+58', '🇻🇪', 10, TRUE),
  ('CO', 'Colombia',       'COL', 'COP', '$',  'USD', '$', 4000,  FALSE, 0,    FALSE, 'DIAN',   'NIT', 'America/Bogota',    '+57', '🇨🇴', 20, TRUE),
  ('MX', 'Mexico',         'MEX', 'MXN', '$',  'USD', '$', 18.0,  FALSE, 0,    FALSE, 'SAT',    'RFC', 'America/Mexico_City','+52', '🇲🇽', 30, TRUE),
  ('ES', 'Espana',         'ESP', 'EUR', '€',  'USD', '$', 1.0,   TRUE,  0,    FALSE, 'AEAT',   'NIF', 'Europe/Madrid',     '+34', '🇪🇸', 40, TRUE),
  ('US', 'Estados Unidos', 'USA', 'USD', '$',  'EUR', '€', 1.0,   FALSE, 0,    FALSE, 'IRS',    'EIN', 'America/New_York',  '+1',  '🇺🇸', 50, TRUE)
ON CONFLICT ("CountryCode") DO UPDATE SET
  "CountryName" = EXCLUDED."CountryName",
  "CurrencyCode" = EXCLUDED."CurrencyCode",
  "CurrencySymbol" = EXCLUDED."CurrencySymbol",
  "ReferenceCurrency" = EXCLUDED."ReferenceCurrency",
  "ReferenceCurrencySymbol" = EXCLUDED."ReferenceCurrencySymbol",
  "DefaultExchangeRate" = EXCLUDED."DefaultExchangeRate",
  "PricesIncludeTax" = EXCLUDED."PricesIncludeTax",
  "SpecialTaxRate" = EXCLUDED."SpecialTaxRate",
  "SpecialTaxEnabled" = EXCLUDED."SpecialTaxEnabled",
  "TaxAuthorityCode" = EXCLUDED."TaxAuthorityCode",
  "FiscalIdName" = EXCLUDED."FiscalIdName",
  "TimeZoneIana" = EXCLUDED."TimeZoneIana",
  "PhonePrefix" = EXCLUDED."PhonePrefix",
  "FlagEmoji" = EXCLUDED."FlagEmoji",
  "UpdatedAt" = NOW();
-- +goose StatementEnd

-- Auto-seed de settings de localización al provisionar tenant.
-- Lee 100% desde cfg.Country — sin hardcode.
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.fn_seed_localizacion_settings(p_company_id INT)
RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
  v_country_code   VARCHAR(3);
  v_country        cfg."Country"%ROWTYPE;
  v_module         TEXT;
  v_modules        TEXT[] := ARRAY['pos', 'restaurante'];
BEGIN
  -- Obtener país fiscal de la empresa
  SELECT UPPER(c."FiscalCountryCode") INTO v_country_code
  FROM cfg."Company" c
  WHERE c."CompanyId" = p_company_id;

  IF v_country_code IS NULL OR TRIM(v_country_code) = '' THEN
    v_country_code := 'VE';
  END IF;

  -- Obtener config fiscal del país (fuente de verdad)
  SELECT * INTO v_country
  FROM cfg."Country"
  WHERE "CountryCode" = v_country_code
  LIMIT 1;

  -- Si el país no existe en cfg.Country, saltar seed
  IF v_country."CountryCode" IS NULL THEN
    RETURN;
  END IF;

  -- Insertar settings por cada módulo (pos + restaurante)
  FOREACH v_module IN ARRAY v_modules LOOP
    INSERT INTO cfg."AppSetting" ("CompanyId", "Module", "SettingKey", "SettingValue", "ValueType", "UpdatedAt")
    VALUES
      (p_company_id, v_module, 'localizacion.pais',               v_country."CountryCode",                   'string',  NOW()),
      (p_company_id, v_module, 'localizacion.monedaPrincipal',    v_country."CurrencySymbol",                'string',  NOW()),
      (p_company_id, v_module, 'localizacion.monedaReferencia',   v_country."ReferenceCurrencySymbol",       'string',  NOW()),
      (p_company_id, v_module, 'localizacion.tasaCambio',         v_country."DefaultExchangeRate"::TEXT,     'number',  NOW()),
      (p_company_id, v_module, 'localizacion.preciosIncluyenIva', v_country."PricesIncludeTax"::TEXT,        'boolean', NOW()),
      (p_company_id, v_module, 'localizacion.aplicarIgtf',        v_country."SpecialTaxEnabled"::TEXT,       'boolean', NOW()),
      (p_company_id, v_module, 'localizacion.tasaIgtf',           v_country."SpecialTaxRate"::TEXT,          'number',  NOW())
    ON CONFLICT ("CompanyId", "Module", "SettingKey") DO NOTHING;
  END LOOP;
END;
$$;
-- +goose StatementEnd

-- Reparar tenants existentes — seed para todas las companies activas
-- +goose StatementBegin
DO $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN
    SELECT "CompanyId" FROM cfg."Company"
    WHERE "IsDeleted" = FALSE AND "IsActive" = TRUE
  LOOP
    PERFORM fn_seed_localizacion_settings(r."CompanyId");
  END LOOP;
END;
$$;
-- +goose StatementEnd

-- Actualizar usp_CFG_Country_List para exponer todos los campos fiscales
-- +goose StatementBegin
DROP FUNCTION IF EXISTS public.usp_cfg_country_list(integer);
DROP FUNCTION IF EXISTS public.usp_cfg_country_list(boolean);
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_cfg_country_list(p_active_only integer DEFAULT 1)
RETURNS TABLE(
  "CountryCode" character,
  "CountryName" character varying,
  "Iso3" character varying,
  "CurrencyCode" character,
  "CurrencySymbol" character varying,
  "ReferenceCurrency" character varying,
  "ReferenceCurrencySymbol" character varying,
  "DefaultExchangeRate" numeric,
  "PricesIncludeTax" boolean,
  "SpecialTaxRate" numeric,
  "SpecialTaxEnabled" boolean,
  "TaxAuthorityCode" character varying,
  "FiscalIdName" character varying,
  "TimeZoneIana" character varying,
  "PhonePrefix" character varying,
  "FlagEmoji" character varying,
  "SortOrder" integer,
  "IsActive" boolean
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT
    c."CountryCode", c."CountryName", c."Iso3",
    c."CurrencyCode", c."CurrencySymbol",
    c."ReferenceCurrency", c."ReferenceCurrencySymbol",
    c."DefaultExchangeRate",
    c."PricesIncludeTax", c."SpecialTaxRate", c."SpecialTaxEnabled",
    c."TaxAuthorityCode", c."FiscalIdName", c."TimeZoneIana",
    c."PhonePrefix", c."FlagEmoji", c."SortOrder", c."IsActive"
  FROM cfg."Country" c
  WHERE (p_active_only = 0 OR c."IsActive" = TRUE)
  ORDER BY c."SortOrder", c."CountryName";
END;
$$;
-- +goose StatementEnd

-- Reemplazar usp_cfg_tenant_provision para llamar al seed después del provision
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_cfg_tenant_provision(
  p_company_code character varying,
  p_legal_name character varying,
  p_owner_email character varying,
  p_country_code character,
  p_base_currency character,
  p_admin_user_code character varying,
  p_admin_password_hash character varying,
  p_plan character varying DEFAULT 'STARTER'::character varying,
  p_paddle_subscription_id character varying DEFAULT NULL::character varying
)
RETURNS TABLE(ok boolean, mensaje character varying, "NewCompanyId" integer, "NewUserId" integer)
LANGUAGE plpgsql
AS $$
DECLARE
  v_company_id   INT;
  v_branch_id    INT;
  v_user_id      INT;
  v_system_id    INT := 1;
BEGIN
  SELECT u."UserId" INTO v_system_id
  FROM sec."User" u WHERE u."UserCode" = 'SYSTEM' LIMIT 1;

  IF EXISTS (
    SELECT 1 FROM cfg."Company" cc
    WHERE LOWER(cc."OwnerEmail") = LOWER(p_owner_email) AND cc."IsDeleted" = FALSE
  ) THEN
    RETURN QUERY SELECT FALSE, 'EMAIL_ALREADY_EXISTS'::VARCHAR, 0, 0;
    RETURN;
  END IF;

  IF EXISTS (
    SELECT 1 FROM cfg."Company" cc
    WHERE UPPER(cc."CompanyCode") = UPPER(p_company_code) AND cc."IsDeleted" = FALSE
  ) THEN
    RETURN QUERY SELECT FALSE, 'COMPANY_CODE_ALREADY_EXISTS'::VARCHAR, 0, 0;
    RETURN;
  END IF;

  INSERT INTO cfg."Company" (
    "CompanyCode", "LegalName", "FiscalCountryCode", "BaseCurrency",
    "IsActive", "Plan", "TenantStatus", "OwnerEmail", "ProvisionedAt",
    "PaddleSubscriptionId", "CreatedByUserId", "UpdatedByUserId"
  ) VALUES (
    UPPER(p_company_code), p_legal_name, UPPER(p_country_code), UPPER(p_base_currency),
    TRUE, UPPER(p_plan), 'ACTIVE', LOWER(p_owner_email),
    NOW() AT TIME ZONE 'UTC', p_paddle_subscription_id, v_system_id, v_system_id
  ) RETURNING "CompanyId" INTO v_company_id;

  INSERT INTO cfg."Branch" (
    "CompanyId", "BranchCode", "BranchName",
    "IsActive", "CreatedByUserId", "UpdatedByUserId"
  ) VALUES (
    v_company_id, 'MAIN', 'Principal',
    TRUE, v_system_id, v_system_id
  ) RETURNING "BranchId" INTO v_branch_id;

  INSERT INTO sec."User" (
    "UserCode", "UserName", "PasswordHash", "Email",
    "IsAdmin", "IsActive", "UserType", "Role",
    "CanUpdate", "CanCreate", "CanDelete", "IsCreator",
    "CanChangePwd", "CanChangePrice", "CanGiveCredit",
    "CompanyId", "DisplayName",
    "CreatedByUserId", "UpdatedByUserId"
  ) VALUES (
    UPPER(p_admin_user_code), p_legal_name,
    p_admin_password_hash, LOWER(p_owner_email),
    TRUE, TRUE, 'ADMIN', 'admin',
    TRUE, TRUE, TRUE, TRUE,
    TRUE, FALSE, FALSE,
    v_company_id, 'Administrador',
    v_system_id, v_system_id
  ) RETURNING "UserId" INTO v_user_id;

  INSERT INTO sec."UserCompanyAccess"
    ("CodUsuario", "CompanyId", "BranchId", "IsActive", "IsDefault")
  VALUES
    (UPPER(p_admin_user_code), v_company_id, v_branch_id, TRUE, TRUE)
  ON CONFLICT ("CodUsuario", "CompanyId", "BranchId")
  DO UPDATE SET
    "IsActive"  = TRUE,
    "IsDefault" = TRUE,
    "UpdatedAt" = NOW() AT TIME ZONE 'UTC';

  INSERT INTO cfg."ExchangeRateDaily"
    ("CurrencyCode", "RateToBase", "RateDate", "SourceName", "CreatedByUserId")
  VALUES
    (UPPER(p_base_currency), 1.000000, CURRENT_DATE, 'PROVISION_SEED', v_system_id)
  ON CONFLICT DO NOTHING;

  UPDATE cfg."Company" c_upd
  SET "TenantSubdomain" = LOWER(REPLACE(p_company_code, '_', '-'))
  WHERE c_upd."CompanyId" = v_company_id
    AND c_upd."TenantSubdomain" IS NULL;

  -- Seed localización settings desde cfg.Country (multi-país, multi-moneda)
  PERFORM fn_seed_localizacion_settings(v_company_id);

  RETURN QUERY SELECT TRUE, 'TENANT_PROVISIONED'::VARCHAR, v_company_id, v_user_id;

EXCEPTION WHEN OTHERS THEN
  RETURN QUERY SELECT FALSE, SQLERRM::VARCHAR, 0, 0;
END;
$$;
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
DROP FUNCTION IF EXISTS public.fn_seed_localizacion_settings(INT);
-- +goose StatementEnd
