-- +goose Up
-- Fix: Columnas que el baseline no pudo crear por error de ownership.
-- Todas usan IF NOT EXISTS / ADD COLUMN IF NOT EXISTS para ser idempotentes.

-- +goose StatementBegin
DO $$
BEGIN
  -- cfg.Branch.CountryCode (añadido en 003_branch_country_support.sql)
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'cfg' AND table_name = 'Branch' AND column_name = 'CountryCode'
  ) THEN
    ALTER TABLE cfg."Branch" ADD COLUMN "CountryCode" CHAR(2) NULL;
  END IF;

  -- cfg.Country columnas extendidas (añadidas en sp_cfg_country.sql)
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'cfg' AND table_name = 'Country' AND column_name = 'CurrencySymbol'
  ) THEN
    ALTER TABLE cfg."Country" ADD COLUMN "CurrencySymbol" VARCHAR(5) NOT NULL DEFAULT '$';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'cfg' AND table_name = 'Country' AND column_name = 'ReferenceCurrency'
  ) THEN
    ALTER TABLE cfg."Country" ADD COLUMN "ReferenceCurrency" CHAR(3) NOT NULL DEFAULT 'USD';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'cfg' AND table_name = 'Country' AND column_name = 'ReferenceCurrencySymbol'
  ) THEN
    ALTER TABLE cfg."Country" ADD COLUMN "ReferenceCurrencySymbol" VARCHAR(5) NOT NULL DEFAULT '$';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'cfg' AND table_name = 'Country' AND column_name = 'DefaultExchangeRate'
  ) THEN
    ALTER TABLE cfg."Country" ADD COLUMN "DefaultExchangeRate" DECIMAL(18,4) NOT NULL DEFAULT 1.0;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'cfg' AND table_name = 'Country' AND column_name = 'PricesIncludeTax'
  ) THEN
    ALTER TABLE cfg."Country" ADD COLUMN "PricesIncludeTax" BOOLEAN NOT NULL DEFAULT FALSE;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'cfg' AND table_name = 'Country' AND column_name = 'SpecialTaxRate'
  ) THEN
    ALTER TABLE cfg."Country" ADD COLUMN "SpecialTaxRate" DECIMAL(5,2) NOT NULL DEFAULT 0;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'cfg' AND table_name = 'Country' AND column_name = 'SpecialTaxEnabled'
  ) THEN
    ALTER TABLE cfg."Country" ADD COLUMN "SpecialTaxEnabled" BOOLEAN NOT NULL DEFAULT FALSE;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'cfg' AND table_name = 'Country' AND column_name = 'PhonePrefix'
  ) THEN
    ALTER TABLE cfg."Country" ADD COLUMN "PhonePrefix" VARCHAR(5) NULL;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'cfg' AND table_name = 'Country' AND column_name = 'SortOrder'
  ) THEN
    ALTER TABLE cfg."Country" ADD COLUMN "SortOrder" INT NOT NULL DEFAULT 100;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'cfg' AND table_name = 'Country' AND column_name = 'TimeZoneIana'
  ) THEN
    ALTER TABLE cfg."Country" ADD COLUMN "TimeZoneIana" VARCHAR(64) NULL;
  END IF;

  -- cfg.Company columnas tenant (añadidas en alter_cfg_company_tenant.sql)
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'cfg' AND table_name = 'Company' AND column_name = 'Plan'
  ) THEN
    ALTER TABLE cfg."Company" ADD COLUMN "Plan" VARCHAR(30) NOT NULL DEFAULT 'FREE';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'cfg' AND table_name = 'Company' AND column_name = 'TenantStatus'
  ) THEN
    ALTER TABLE cfg."Company" ADD COLUMN "TenantStatus" VARCHAR(20) NOT NULL DEFAULT 'ACTIVE';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'cfg' AND table_name = 'Company' AND column_name = 'OwnerEmail'
  ) THEN
    ALTER TABLE cfg."Company" ADD COLUMN "OwnerEmail" VARCHAR(150) NULL;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'cfg' AND table_name = 'Company' AND column_name = 'TenantSubdomain'
  ) THEN
    ALTER TABLE cfg."Company" ADD COLUMN "TenantSubdomain" VARCHAR(63) NULL;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'cfg' AND table_name = 'Company' AND column_name = 'PaddleSubscriptionId'
  ) THEN
    ALTER TABLE cfg."Company" ADD COLUMN "PaddleSubscriptionId" VARCHAR(100) NULL;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'cfg' AND table_name = 'Company' AND column_name = 'ProvisionedAt'
  ) THEN
    ALTER TABLE cfg."Company" ADD COLUMN "ProvisionedAt" TIMESTAMP NULL;
  END IF;

  -- cfg.Company.TradeName (usado por el SP de accesos)
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'cfg' AND table_name = 'Company' AND column_name = 'TradeName'
  ) THEN
    ALTER TABLE cfg."Company" ADD COLUMN "TradeName" VARCHAR(200) NULL;
  END IF;

  -- master.Product.SearchVector (para fulltext search)
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'master' AND table_name = 'Product' AND column_name = 'SearchVector'
  ) THEN
    ALTER TABLE master."Product" ADD COLUMN "SearchVector" TSVECTOR NULL;
  END IF;

  RAISE NOTICE 'Fix missing columns: completado';
END $$;
-- +goose StatementEnd

-- +goose Down
-- No rollback — las columnas se mantienen
SELECT 1;
