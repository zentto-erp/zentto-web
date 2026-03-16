/*
  Activos Fijos - Tablas canonicas (PostgreSQL)
  Esquema: acct
  ---------------------------------------------------
  Crea la estructura completa para gestion de activos fijos:
    1. acct."FixedAssetCategory"      - Categorias de activos con vida util por pais
    2. acct."FixedAsset"              - Registro maestro de activos fijos
    3. acct."FixedAssetDepreciation"  - Lineas de depreciacion mensual
    4. acct."FixedAssetImprovement"   - Mejoras / adiciones capitalizables
    5. acct."FixedAssetRevaluation"   - Revaluaciones por indice (inflacion)
  Seed data: categorias para VE y ES
*/

DO $$
DECLARE
  v_seed_company_id INT;
BEGIN

  -- ============================================================
  -- 0. Asegurar que el esquema acct existe
  -- ============================================================
  CREATE SCHEMA IF NOT EXISTS acct;
  RAISE NOTICE '>> Esquema acct verificado.';

  -- ============================================================
  -- 1. acct."FixedAssetCategory"
  --    Categorias maestras de activos fijos.
  --    Cada pais puede tener vida util distinta (VE vs ES).
  -- ============================================================
  CREATE TABLE IF NOT EXISTS acct."FixedAssetCategory" (
    "CategoryId"                INTEGER GENERATED ALWAYS AS IDENTITY NOT NULL PRIMARY KEY,
    "CompanyId"                 INTEGER NOT NULL,
    "CategoryCode"              VARCHAR(20) NOT NULL,
    "CategoryName"              VARCHAR(200) NOT NULL,
    "DefaultUsefulLifeMonths"   INTEGER NOT NULL,
    "DefaultDepreciationMethod" VARCHAR(20) NOT NULL DEFAULT 'STRAIGHT_LINE',
      -- Valores: STRAIGHT_LINE, DOUBLE_DECLINING, UNITS_PRODUCED, NONE
    "DefaultResidualPercent"    NUMERIC(5,2) DEFAULT 0,
    "DefaultAssetAccountCode"   VARCHAR(20) NULL,
    "DefaultDeprecAccountCode"  VARCHAR(20) NULL,
    "DefaultExpenseAccountCode" VARCHAR(20) NULL,
    "CountryCode"               VARCHAR(2) NULL,
    "IsActive"                  BOOLEAN DEFAULT TRUE,
    "IsDeleted"                 BOOLEAN DEFAULT FALSE,
    "CreatedAt"                 TIMESTAMP DEFAULT (NOW() AT TIME ZONE 'UTC'),
    CONSTRAINT "UQ_FixedAssetCategory" UNIQUE ("CompanyId", "CategoryCode", "CountryCode")
  );
  RAISE NOTICE '>> Tabla acct."FixedAssetCategory" verificada.';

  -- ============================================================
  -- 2. acct."FixedAsset"
  --    Registro maestro de cada activo fijo.
  --    Referencia cuentas contables y centro de costo.
  -- ============================================================
  CREATE TABLE IF NOT EXISTS acct."FixedAsset" (
    "AssetId"            BIGINT GENERATED ALWAYS AS IDENTITY NOT NULL PRIMARY KEY,
    "CompanyId"          INTEGER NOT NULL,
    "BranchId"           INTEGER NOT NULL DEFAULT 0,
    "AssetCode"          VARCHAR(40) NOT NULL,
    "Description"        VARCHAR(250) NOT NULL,
    "CategoryId"         INTEGER NULL
      CONSTRAINT "FK_FA_Category" REFERENCES acct."FixedAssetCategory"("CategoryId"),
    "AcquisitionDate"    DATE NOT NULL,
    "AcquisitionCost"    NUMERIC(18,2) NOT NULL,
    "ResidualValue"      NUMERIC(18,2) DEFAULT 0,
    "UsefulLifeMonths"   INTEGER NOT NULL,
    "DepreciationMethod" VARCHAR(20) NOT NULL DEFAULT 'STRAIGHT_LINE',
    "AssetAccountCode"   VARCHAR(20) NOT NULL,   -- ej: 1.2.01
    "DeprecAccountCode"  VARCHAR(20) NOT NULL,   -- ej: 1.2.02
    "ExpenseAccountCode" VARCHAR(20) NOT NULL,   -- ej: 6.1.xx
    "CostCenterCode"     VARCHAR(20) NULL,
    "Location"           VARCHAR(200) NULL,
    "SerialNumber"       VARCHAR(100) NULL,
    "Status"             VARCHAR(20) DEFAULT 'ACTIVE',
      -- Valores: ACTIVE, DISPOSED, FULLY_DEPRECIATED, IMPAIRED
    "DisposalDate"       DATE NULL,
    "DisposalAmount"     NUMERIC(18,2) NULL,
    "DisposalReason"     VARCHAR(500) NULL,
    "DisposalEntryId"    BIGINT NULL,
    "AcquisitionEntryId" BIGINT NULL,
    "UnitsCapacity"      INTEGER NULL,
    "CurrencyCode"       VARCHAR(3) DEFAULT 'VES',
    "IsDeleted"          BOOLEAN DEFAULT FALSE,
    "CreatedAt"          TIMESTAMP DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "UpdatedAt"          TIMESTAMP NULL,
    "CreatedBy"          VARCHAR(40) NULL,
    "UpdatedBy"          VARCHAR(40) NULL,
    CONSTRAINT "UQ_FixedAsset_Code" UNIQUE ("CompanyId", "AssetCode")
  );
  RAISE NOTICE '>> Tabla acct."FixedAsset" verificada.';

  -- ============================================================
  -- 3. acct."FixedAssetDepreciation"
  --    Lineas de depreciacion mensual por activo.
  --    Cada registro corresponde a un periodo YYYY-MM.
  -- ============================================================
  CREATE TABLE IF NOT EXISTS acct."FixedAssetDepreciation" (
    "DepreciationId"           BIGINT GENERATED ALWAYS AS IDENTITY NOT NULL PRIMARY KEY,
    "AssetId"                  BIGINT NOT NULL
      CONSTRAINT "FK_FAD_Asset" REFERENCES acct."FixedAsset"("AssetId"),
    "PeriodCode"               VARCHAR(7) NOT NULL,   -- YYYY-MM
    "DepreciationDate"         DATE NOT NULL,
    "Amount"                   NUMERIC(18,2) NOT NULL,
    "AccumulatedDepreciation"  NUMERIC(18,2) NOT NULL,
    "BookValue"                NUMERIC(18,2) NOT NULL,
    "JournalEntryId"           BIGINT NULL,
    "Status"                   VARCHAR(20) DEFAULT 'GENERATED',
      -- Valores: GENERATED, POSTED, REVERSED
    "CreatedAt"                TIMESTAMP DEFAULT (NOW() AT TIME ZONE 'UTC'),
    CONSTRAINT "UQ_AssetDeprec" UNIQUE ("AssetId", "PeriodCode")
  );
  RAISE NOTICE '>> Tabla acct."FixedAssetDepreciation" verificada.';

  -- ============================================================
  -- 4. acct."FixedAssetImprovement"
  --    Mejoras capitalizables que incrementan costo y/o vida util.
  -- ============================================================
  CREATE TABLE IF NOT EXISTS acct."FixedAssetImprovement" (
    "ImprovementId"        BIGINT GENERATED ALWAYS AS IDENTITY NOT NULL PRIMARY KEY,
    "AssetId"              BIGINT NOT NULL
      CONSTRAINT "FK_FAI_Asset" REFERENCES acct."FixedAsset"("AssetId"),
    "ImprovementDate"      DATE NOT NULL,
    "Description"          VARCHAR(500) NOT NULL,
    "Amount"               NUMERIC(18,2) NOT NULL,
    "AdditionalLifeMonths" INTEGER DEFAULT 0,
    "JournalEntryId"       BIGINT NULL,
    "CreatedBy"            VARCHAR(40) NULL,
    "CreatedAt"            TIMESTAMP DEFAULT (NOW() AT TIME ZONE 'UTC')
  );
  RAISE NOTICE '>> Tabla acct."FixedAssetImprovement" verificada.';

  -- ============================================================
  -- 5. acct."FixedAssetRevaluation"
  --    Revaluaciones por indice de precios (inflacion).
  --    Aplica principalmente en paises con alta inflacion (VE).
  -- ============================================================
  CREATE TABLE IF NOT EXISTS acct."FixedAssetRevaluation" (
    "RevaluationId"        BIGINT GENERATED ALWAYS AS IDENTITY NOT NULL PRIMARY KEY,
    "AssetId"              BIGINT NOT NULL
      CONSTRAINT "FK_FAR_Asset" REFERENCES acct."FixedAsset"("AssetId"),
    "RevaluationDate"      DATE NOT NULL,
    "PreviousCost"         NUMERIC(18,2) NOT NULL,
    "NewCost"              NUMERIC(18,2) NOT NULL,
    "PreviousAccumDeprec"  NUMERIC(18,2) NOT NULL,
    "NewAccumDeprec"       NUMERIC(18,2) NOT NULL,
    "IndexFactor"          NUMERIC(12,6) NOT NULL,
    "JournalEntryId"       BIGINT NULL,
    "CountryCode"          VARCHAR(2) NOT NULL,
    "CreatedBy"            VARCHAR(40) NULL,
    "CreatedAt"            TIMESTAMP DEFAULT (NOW() AT TIME ZONE 'UTC')
  );
  RAISE NOTICE '>> Tabla acct."FixedAssetRevaluation" verificada.';

  -- ============================================================
  -- 6. Seed data: Categorias de activos fijos (VE y ES)
  -- ============================================================
  RAISE NOTICE '>> Insertando categorias seed para VE y ES...';

  SELECT "CompanyId" INTO v_seed_company_id FROM acct."Account" LIMIT 1;
  IF v_seed_company_id IS NULL THEN
    v_seed_company_id := 1;
  END IF;

  -- Venezuela (VE)
  INSERT INTO acct."FixedAssetCategory" ("CompanyId", "CategoryCode", "CategoryName", "DefaultUsefulLifeMonths", "DefaultDepreciationMethod", "DefaultResidualPercent", "DefaultAssetAccountCode", "DefaultDeprecAccountCode", "DefaultExpenseAccountCode", "CountryCode")
  VALUES (v_seed_company_id, 'MOB', 'Mobiliario y Enseres', 120, 'STRAIGHT_LINE', 0, '1.2.01', '1.2.02', '6.1.06', 'VE')
  ON CONFLICT ("CompanyId", "CategoryCode", "CountryCode") DO NOTHING;

  INSERT INTO acct."FixedAssetCategory" ("CompanyId", "CategoryCode", "CategoryName", "DefaultUsefulLifeMonths", "DefaultDepreciationMethod", "DefaultResidualPercent", "DefaultAssetAccountCode", "DefaultDeprecAccountCode", "DefaultExpenseAccountCode", "CountryCode")
  VALUES (v_seed_company_id, 'VEH', 'Vehículos', 60, 'STRAIGHT_LINE', 0, '1.2.01', '1.2.02', '6.1.06', 'VE')
  ON CONFLICT ("CompanyId", "CategoryCode", "CountryCode") DO NOTHING;

  INSERT INTO acct."FixedAssetCategory" ("CompanyId", "CategoryCode", "CategoryName", "DefaultUsefulLifeMonths", "DefaultDepreciationMethod", "DefaultResidualPercent", "DefaultAssetAccountCode", "DefaultDeprecAccountCode", "DefaultExpenseAccountCode", "CountryCode")
  VALUES (v_seed_company_id, 'MAQ', 'Maquinaria y Equipos', 120, 'STRAIGHT_LINE', 0, '1.2.01', '1.2.02', '6.1.06', 'VE')
  ON CONFLICT ("CompanyId", "CategoryCode", "CountryCode") DO NOTHING;

  INSERT INTO acct."FixedAssetCategory" ("CompanyId", "CategoryCode", "CategoryName", "DefaultUsefulLifeMonths", "DefaultDepreciationMethod", "DefaultResidualPercent", "DefaultAssetAccountCode", "DefaultDeprecAccountCode", "DefaultExpenseAccountCode", "CountryCode")
  VALUES (v_seed_company_id, 'EDI', 'Edificios y Construcciones', 240, 'STRAIGHT_LINE', 0, '1.2.01', '1.2.02', '6.1.06', 'VE')
  ON CONFLICT ("CompanyId", "CategoryCode", "CountryCode") DO NOTHING;

  INSERT INTO acct."FixedAssetCategory" ("CompanyId", "CategoryCode", "CategoryName", "DefaultUsefulLifeMonths", "DefaultDepreciationMethod", "DefaultResidualPercent", "DefaultAssetAccountCode", "DefaultDeprecAccountCode", "DefaultExpenseAccountCode", "CountryCode")
  VALUES (v_seed_company_id, 'TER', 'Terrenos', 0, 'NONE', 0, '1.2.01', NULL, NULL, 'VE')
  ON CONFLICT ("CompanyId", "CategoryCode", "CountryCode") DO NOTHING;

  INSERT INTO acct."FixedAssetCategory" ("CompanyId", "CategoryCode", "CategoryName", "DefaultUsefulLifeMonths", "DefaultDepreciationMethod", "DefaultResidualPercent", "DefaultAssetAccountCode", "DefaultDeprecAccountCode", "DefaultExpenseAccountCode", "CountryCode")
  VALUES (v_seed_company_id, 'EQU', 'Equipos Informáticos', 36, 'STRAIGHT_LINE', 0, '1.2.01', '1.2.02', '6.1.06', 'VE')
  ON CONFLICT ("CompanyId", "CategoryCode", "CountryCode") DO NOTHING;

  INSERT INTO acct."FixedAssetCategory" ("CompanyId", "CategoryCode", "CategoryName", "DefaultUsefulLifeMonths", "DefaultDepreciationMethod", "DefaultResidualPercent", "DefaultAssetAccountCode", "DefaultDeprecAccountCode", "DefaultExpenseAccountCode", "CountryCode")
  VALUES (v_seed_company_id, 'INT', 'Intangibles y Software', 60, 'STRAIGHT_LINE', 0, '1.2.03', '1.2.03', '6.1.06', 'VE')
  ON CONFLICT ("CompanyId", "CategoryCode", "CountryCode") DO NOTHING;

  INSERT INTO acct."FixedAssetCategory" ("CompanyId", "CategoryCode", "CategoryName", "DefaultUsefulLifeMonths", "DefaultDepreciationMethod", "DefaultResidualPercent", "DefaultAssetAccountCode", "DefaultDeprecAccountCode", "DefaultExpenseAccountCode", "CountryCode")
  VALUES (v_seed_company_id, 'HER', 'Herramientas', 60, 'STRAIGHT_LINE', 0, '1.2.01', '1.2.02', '6.1.06', 'VE')
  ON CONFLICT ("CompanyId", "CategoryCode", "CountryCode") DO NOTHING;

  RAISE NOTICE '   VE: 8 categorias verificadas/insertadas.';

  -- España (ES)
  INSERT INTO acct."FixedAssetCategory" ("CompanyId", "CategoryCode", "CategoryName", "DefaultUsefulLifeMonths", "DefaultDepreciationMethod", "DefaultResidualPercent", "DefaultAssetAccountCode", "DefaultDeprecAccountCode", "DefaultExpenseAccountCode", "CountryCode")
  VALUES (v_seed_company_id, 'MOB', 'Mobiliario y Enseres', 120, 'STRAIGHT_LINE', 0, '1.2.01', '1.2.02', '6.1.06', 'ES')
  ON CONFLICT ("CompanyId", "CategoryCode", "CountryCode") DO NOTHING;

  INSERT INTO acct."FixedAssetCategory" ("CompanyId", "CategoryCode", "CategoryName", "DefaultUsefulLifeMonths", "DefaultDepreciationMethod", "DefaultResidualPercent", "DefaultAssetAccountCode", "DefaultDeprecAccountCode", "DefaultExpenseAccountCode", "CountryCode")
  VALUES (v_seed_company_id, 'VEH', 'Vehículos', 72, 'STRAIGHT_LINE', 0, '1.2.01', '1.2.02', '6.1.06', 'ES')
  ON CONFLICT ("CompanyId", "CategoryCode", "CountryCode") DO NOTHING;

  INSERT INTO acct."FixedAssetCategory" ("CompanyId", "CategoryCode", "CategoryName", "DefaultUsefulLifeMonths", "DefaultDepreciationMethod", "DefaultResidualPercent", "DefaultAssetAccountCode", "DefaultDeprecAccountCode", "DefaultExpenseAccountCode", "CountryCode")
  VALUES (v_seed_company_id, 'MAQ', 'Maquinaria y Equipos', 144, 'STRAIGHT_LINE', 0, '1.2.01', '1.2.02', '6.1.06', 'ES')
  ON CONFLICT ("CompanyId", "CategoryCode", "CountryCode") DO NOTHING;

  INSERT INTO acct."FixedAssetCategory" ("CompanyId", "CategoryCode", "CategoryName", "DefaultUsefulLifeMonths", "DefaultDepreciationMethod", "DefaultResidualPercent", "DefaultAssetAccountCode", "DefaultDeprecAccountCode", "DefaultExpenseAccountCode", "CountryCode")
  VALUES (v_seed_company_id, 'EDI', 'Edificios y Construcciones', 396, 'STRAIGHT_LINE', 0, '1.2.01', '1.2.02', '6.1.06', 'ES')
  ON CONFLICT ("CompanyId", "CategoryCode", "CountryCode") DO NOTHING;

  INSERT INTO acct."FixedAssetCategory" ("CompanyId", "CategoryCode", "CategoryName", "DefaultUsefulLifeMonths", "DefaultDepreciationMethod", "DefaultResidualPercent", "DefaultAssetAccountCode", "DefaultDeprecAccountCode", "DefaultExpenseAccountCode", "CountryCode")
  VALUES (v_seed_company_id, 'TER', 'Terrenos', 0, 'NONE', 0, '1.2.01', NULL, NULL, 'ES')
  ON CONFLICT ("CompanyId", "CategoryCode", "CountryCode") DO NOTHING;

  INSERT INTO acct."FixedAssetCategory" ("CompanyId", "CategoryCode", "CategoryName", "DefaultUsefulLifeMonths", "DefaultDepreciationMethod", "DefaultResidualPercent", "DefaultAssetAccountCode", "DefaultDeprecAccountCode", "DefaultExpenseAccountCode", "CountryCode")
  VALUES (v_seed_company_id, 'EQU', 'Equipos Informáticos', 48, 'STRAIGHT_LINE', 0, '1.2.01', '1.2.02', '6.1.06', 'ES')
  ON CONFLICT ("CompanyId", "CategoryCode", "CountryCode") DO NOTHING;

  INSERT INTO acct."FixedAssetCategory" ("CompanyId", "CategoryCode", "CategoryName", "DefaultUsefulLifeMonths", "DefaultDepreciationMethod", "DefaultResidualPercent", "DefaultAssetAccountCode", "DefaultDeprecAccountCode", "DefaultExpenseAccountCode", "CountryCode")
  VALUES (v_seed_company_id, 'INT', 'Intangibles y Software', 60, 'STRAIGHT_LINE', 0, '1.2.03', '1.2.03', '6.1.06', 'ES')
  ON CONFLICT ("CompanyId", "CategoryCode", "CountryCode") DO NOTHING;

  INSERT INTO acct."FixedAssetCategory" ("CompanyId", "CategoryCode", "CategoryName", "DefaultUsefulLifeMonths", "DefaultDepreciationMethod", "DefaultResidualPercent", "DefaultAssetAccountCode", "DefaultDeprecAccountCode", "DefaultExpenseAccountCode", "CountryCode")
  VALUES (v_seed_company_id, 'HER', 'Herramientas', 96, 'STRAIGHT_LINE', 0, '1.2.01', '1.2.02', '6.1.06', 'ES')
  ON CONFLICT ("CompanyId", "CategoryCode", "CountryCode") DO NOTHING;

  RAISE NOTICE '   ES: 8 categorias verificadas/insertadas.';

  -- ============================================================
  -- INDICES
  -- ============================================================
  CREATE INDEX IF NOT EXISTS "IX_FixedAsset_CompanyCode"
    ON acct."FixedAsset" ("CompanyId", "AssetCode");

  CREATE INDEX IF NOT EXISTS "IX_FixedAsset_CategoryId"
    ON acct."FixedAsset" ("CategoryId");

  CREATE INDEX IF NOT EXISTS "IX_FixedAssetDepreciation_AssetPeriod"
    ON acct."FixedAssetDepreciation" ("AssetId", "PeriodCode");

  RAISE NOTICE '>> Activos fijos: script completado exitosamente.';

EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE 'ERROR en create_activos_fijos.sql: %', SQLERRM;
  RAISE;
END $$;
