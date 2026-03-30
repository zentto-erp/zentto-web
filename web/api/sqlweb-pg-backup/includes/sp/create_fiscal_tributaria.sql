/*
================================================================================
  MÓDULO FISCAL / TRIBUTARIA (PostgreSQL)
  Gestión de declaraciones, libros fiscales, retenciones y plantillas
  Multi-país: VE, ES, CO, MX, US

  Tablas:
    fiscal."TaxDeclaration"      - Declaraciones tributarias (IVA, ISLR, IRPF, etc.)
    fiscal."TaxBookEntry"        - Líneas del libro de compras/ventas
    fiscal."WithholdingVoucher"  - Comprobantes de retención
    fiscal."DeclarationTemplate" - Plantillas de declaración por país
    fiscal."ISLRTariff"          - Tabla progresiva ISLR Venezuela

  Seed data:
    - Plantillas de declaración (VE, ES)
    - Tarifa ISLR Venezuela 2026
    - Complemento master."TaxRetention" (VE, ES)
================================================================================
*/

DO $$
BEGIN

  -- ============================================================
  -- ESQUEMA fiscal
  -- ============================================================
  CREATE SCHEMA IF NOT EXISTS fiscal;
  RAISE NOTICE '>> Esquema fiscal verificado.';

  -- ============================================================
  -- 1. fiscal."TaxDeclaration" - Declaraciones tributarias
  -- ============================================================
  CREATE TABLE IF NOT EXISTS fiscal."TaxDeclaration" (
    "DeclarationId"       BIGINT GENERATED ALWAYS AS IDENTITY NOT NULL,
    "CompanyId"           INTEGER NOT NULL,
    "BranchId"            INTEGER NOT NULL DEFAULT 0,
    "CountryCode"         VARCHAR(2) NOT NULL,
    "DeclarationType"     VARCHAR(30) NOT NULL,       -- IVA, ISLR, IRPF, MODELO_303, MODELO_390, MODELO_349
    "PeriodCode"          VARCHAR(7) NOT NULL,         -- YYYY-MM
    "PeriodStart"         DATE NOT NULL,
    "PeriodEnd"           DATE NOT NULL,
    -- Totales ventas/compras
    "SalesBase"           NUMERIC(18,2) DEFAULT 0,
    "SalesTax"            NUMERIC(18,2) DEFAULT 0,
    "PurchasesBase"       NUMERIC(18,2) DEFAULT 0,
    "PurchasesTax"        NUMERIC(18,2) DEFAULT 0,
    -- Cálculo
    "TaxableBase"         NUMERIC(18,2) DEFAULT 0,
    "TaxAmount"           NUMERIC(18,2) DEFAULT 0,
    "WithholdingsCredit"  NUMERIC(18,2) DEFAULT 0,
    "PreviousBalance"     NUMERIC(18,2) DEFAULT 0,
    "NetPayable"          NUMERIC(18,2) DEFAULT 0,
    -- Flujo de estado
    "Status"              VARCHAR(20) DEFAULT 'DRAFT', -- DRAFT, CALCULATED, SUBMITTED, PAID, AMENDED
    "SubmittedAt"         TIMESTAMP NULL,
    "SubmittedFile"       VARCHAR(500) NULL,
    "AuthorityResponse"   TEXT NULL,
    "PaidAt"              TIMESTAMP NULL,
    "PaymentReference"    VARCHAR(100) NULL,
    -- Contabilidad
    "JournalEntryId"      BIGINT NULL,
    "Notes"               VARCHAR(1000) NULL,
    "CreatedBy"           VARCHAR(40) NULL,
    "UpdatedBy"           VARCHAR(40) NULL,
    "CreatedAt"           TIMESTAMP DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "UpdatedAt"           TIMESTAMP NULL,
    CONSTRAINT "PK_TaxDeclaration" PRIMARY KEY ("DeclarationId"),
    CONSTRAINT "UQ_TaxDeclaration" UNIQUE ("CompanyId", "DeclarationType", "PeriodCode")
  );
  RAISE NOTICE '>> Tabla fiscal."TaxDeclaration" verificada.';

  -- ============================================================
  -- 2. fiscal."TaxBookEntry" - Líneas del libro de compras/ventas
  -- ============================================================
  CREATE TABLE IF NOT EXISTS fiscal."TaxBookEntry" (
    "EntryId"             BIGINT GENERATED ALWAYS AS IDENTITY NOT NULL,
    "CompanyId"           INTEGER NOT NULL,
    "BookType"            VARCHAR(10) NOT NULL,         -- PURCHASE, SALES
    "PeriodCode"          VARCHAR(7) NOT NULL,
    "EntryDate"           DATE NOT NULL,
    "DocumentNumber"      VARCHAR(60) NOT NULL,
    "DocumentType"        VARCHAR(30) NULL,             -- FACTURA, NOTA_CREDITO, NOTA_DEBITO
    "ControlNumber"       VARCHAR(40) NULL,             -- Número de control (VE)
    "ThirdPartyId"        VARCHAR(40) NULL,             -- RIF/NIF del tercero
    "ThirdPartyName"      VARCHAR(200) NULL,
    "TaxableBase"         NUMERIC(18,2) NOT NULL DEFAULT 0,
    "ExemptAmount"        NUMERIC(18,2) DEFAULT 0,
    "TaxRate"             NUMERIC(5,2) NOT NULL DEFAULT 0,
    "TaxAmount"           NUMERIC(18,2) NOT NULL DEFAULT 0,
    "WithholdingRate"     NUMERIC(5,2) DEFAULT 0,
    "WithholdingAmount"   NUMERIC(18,2) DEFAULT 0,
    "TotalAmount"         NUMERIC(18,2) NOT NULL DEFAULT 0,
    "SourceDocumentId"    BIGINT NULL,
    "SourceModule"        VARCHAR(20) NULL,             -- AR, AP, POS
    "CountryCode"         VARCHAR(2) NOT NULL,
    "DeclarationId"       BIGINT NULL,
    "CreatedAt"           TIMESTAMP DEFAULT (NOW() AT TIME ZONE 'UTC'),
    CONSTRAINT "PK_TaxBookEntry" PRIMARY KEY ("EntryId"),
    CONSTRAINT "FK_TaxBookEntry_Declaration" FOREIGN KEY ("DeclarationId")
      REFERENCES fiscal."TaxDeclaration" ("DeclarationId")
  );
  RAISE NOTICE '>> Tabla fiscal."TaxBookEntry" verificada.';

  -- ============================================================
  -- 3. fiscal."WithholdingVoucher" - Comprobantes de retención
  -- ============================================================
  CREATE TABLE IF NOT EXISTS fiscal."WithholdingVoucher" (
    "VoucherId"           BIGINT GENERATED ALWAYS AS IDENTITY NOT NULL,
    "CompanyId"           INTEGER NOT NULL,
    "VoucherNumber"       VARCHAR(40) NOT NULL,
    "VoucherDate"         DATE NOT NULL,
    "WithholdingType"     VARCHAR(20) NOT NULL,         -- IVA, ISLR, IRPF, ICA
    "ThirdPartyId"        VARCHAR(40) NOT NULL,
    "ThirdPartyName"      VARCHAR(200) NULL,
    "DocumentNumber"      VARCHAR(60) NOT NULL,
    "DocumentDate"        DATE NULL,
    "TaxableBase"         NUMERIC(18,2) NOT NULL,
    "WithholdingRate"     NUMERIC(5,2) NOT NULL,
    "WithholdingAmount"   NUMERIC(18,2) NOT NULL,
    "PeriodCode"          VARCHAR(7) NOT NULL,
    "Status"              VARCHAR(20) DEFAULT 'ACTIVE', -- ACTIVE, VOIDED
    "CountryCode"         VARCHAR(2) NOT NULL,
    "JournalEntryId"      BIGINT NULL,
    "CreatedBy"           VARCHAR(40) NULL,
    "CreatedAt"           TIMESTAMP DEFAULT (NOW() AT TIME ZONE 'UTC'),
    CONSTRAINT "PK_WithholdingVoucher" PRIMARY KEY ("VoucherId"),
    CONSTRAINT "UQ_WithholdingVoucher" UNIQUE ("CompanyId", "VoucherNumber")
  );
  RAISE NOTICE '>> Tabla fiscal."WithholdingVoucher" verificada.';

  -- ============================================================
  -- 4. fiscal."DeclarationTemplate" - Plantillas por país
  -- ============================================================
  CREATE TABLE IF NOT EXISTS fiscal."DeclarationTemplate" (
    "TemplateId"          INTEGER GENERATED ALWAYS AS IDENTITY NOT NULL,
    "CountryCode"         VARCHAR(2) NOT NULL,
    "DeclarationType"     VARCHAR(30) NOT NULL,
    "TemplateName"        VARCHAR(200) NOT NULL,
    "FileFormat"          VARCHAR(10) NOT NULL,         -- XML, TXT, JSON
    "FormatVersion"       VARCHAR(20) NULL,
    "AuthorityName"       VARCHAR(100) NULL,
    "AuthorityUrl"        VARCHAR(500) NULL,
    "IsActive"            BOOLEAN DEFAULT TRUE,
    "CreatedAt"           TIMESTAMP DEFAULT (NOW() AT TIME ZONE 'UTC'),
    CONSTRAINT "PK_DeclarationTemplate" PRIMARY KEY ("TemplateId"),
    CONSTRAINT "UQ_DeclTemplate" UNIQUE ("CountryCode", "DeclarationType")
  );
  RAISE NOTICE '>> Tabla fiscal."DeclarationTemplate" verificada.';

  -- ============================================================
  -- 5. fiscal."ISLRTariff" - Tabla progresiva ISLR Venezuela
  -- ============================================================
  CREATE TABLE IF NOT EXISTS fiscal."ISLRTariff" (
    "TariffId"            INTEGER GENERATED ALWAYS AS IDENTITY NOT NULL,
    "CountryCode"         VARCHAR(2) NOT NULL DEFAULT 'VE',
    "TaxYear"             INTEGER NOT NULL,
    "BracketFrom"         NUMERIC(18,2) NOT NULL,        -- En UT (Unidades Tributarias)
    "BracketTo"           NUMERIC(18,2) NULL,
    "Rate"                NUMERIC(5,2) NOT NULL,
    "Subtrahend"          NUMERIC(18,2) DEFAULT 0,
    "IsActive"            BOOLEAN DEFAULT TRUE,
    CONSTRAINT "PK_ISLRTariff" PRIMARY KEY ("TariffId")
  );
  RAISE NOTICE '>> Tabla fiscal."ISLRTariff" verificada.';

  -- ============================================================
  -- ÍNDICES
  -- ============================================================
  CREATE INDEX IF NOT EXISTS "IX_TaxDeclaration_Country_Period"
    ON fiscal."TaxDeclaration" ("CountryCode", "PeriodCode", "Status");

  CREATE INDEX IF NOT EXISTS "IX_TaxBookEntry_Period_Book"
    ON fiscal."TaxBookEntry" ("CompanyId", "BookType", "PeriodCode");

  CREATE INDEX IF NOT EXISTS "IX_TaxBookEntry_Declaration"
    ON fiscal."TaxBookEntry" ("DeclarationId")
    WHERE "DeclarationId" IS NOT NULL;

  CREATE INDEX IF NOT EXISTS "IX_WithholdingVoucher_Period"
    ON fiscal."WithholdingVoucher" ("CompanyId", "PeriodCode", "WithholdingType");

  CREATE INDEX IF NOT EXISTS "IX_ISLRTariff_Year"
    ON fiscal."ISLRTariff" ("CountryCode", "TaxYear", "IsActive");

  RAISE NOTICE '>> Índices verificados.';

  -- ============================================================
  -- SEED DATA: Plantillas de declaración
  -- ============================================================
  RAISE NOTICE '>> Insertando plantillas de declaración...';

  -- Venezuela
  INSERT INTO fiscal."DeclarationTemplate" ("CountryCode", "DeclarationType", "TemplateName", "FileFormat", "AuthorityName")
  VALUES ('VE', 'IVA', 'Declaración IVA SENIAT', 'TXT', 'SENIAT')
  ON CONFLICT ("CountryCode", "DeclarationType") DO NOTHING;

  INSERT INTO fiscal."DeclarationTemplate" ("CountryCode", "DeclarationType", "TemplateName", "FileFormat", "AuthorityName")
  VALUES ('VE', 'ISLR', 'Declaración ISLR SENIAT', 'XML', 'SENIAT')
  ON CONFLICT ("CountryCode", "DeclarationType") DO NOTHING;

  INSERT INTO fiscal."DeclarationTemplate" ("CountryCode", "DeclarationType", "TemplateName", "FileFormat", "AuthorityName")
  VALUES ('VE', 'RET_IVA', 'Retenciones IVA SENIAT', 'XML', 'SENIAT')
  ON CONFLICT ("CountryCode", "DeclarationType") DO NOTHING;

  INSERT INTO fiscal."DeclarationTemplate" ("CountryCode", "DeclarationType", "TemplateName", "FileFormat", "AuthorityName")
  VALUES ('VE', 'RET_ISLR', 'Retenciones ISLR SENIAT', 'XML', 'SENIAT')
  ON CONFLICT ("CountryCode", "DeclarationType") DO NOTHING;

  -- España
  INSERT INTO fiscal."DeclarationTemplate" ("CountryCode", "DeclarationType", "TemplateName", "FileFormat", "AuthorityName")
  VALUES ('ES', 'MODELO_303', 'Modelo 303 - IVA Trimestral', 'XML', 'AEAT')
  ON CONFLICT ("CountryCode", "DeclarationType") DO NOTHING;

  INSERT INTO fiscal."DeclarationTemplate" ("CountryCode", "DeclarationType", "TemplateName", "FileFormat", "AuthorityName")
  VALUES ('ES', 'MODELO_390', 'Modelo 390 - Resumen Anual IVA', 'XML', 'AEAT')
  ON CONFLICT ("CountryCode", "DeclarationType") DO NOTHING;

  INSERT INTO fiscal."DeclarationTemplate" ("CountryCode", "DeclarationType", "TemplateName", "FileFormat", "AuthorityName")
  VALUES ('ES', 'MODELO_349', 'Modelo 349 - Operaciones Intracomunitarias', 'XML', 'AEAT')
  ON CONFLICT ("CountryCode", "DeclarationType") DO NOTHING;

  INSERT INTO fiscal."DeclarationTemplate" ("CountryCode", "DeclarationType", "TemplateName", "FileFormat", "AuthorityName")
  VALUES ('ES', 'MODELO_111', 'Modelo 111 - Retenciones IRPF', 'XML', 'AEAT')
  ON CONFLICT ("CountryCode", "DeclarationType") DO NOTHING;

  INSERT INTO fiscal."DeclarationTemplate" ("CountryCode", "DeclarationType", "TemplateName", "FileFormat", "AuthorityName")
  VALUES ('ES', 'MODELO_190', 'Modelo 190 - Resumen Anual Retenciones', 'XML', 'AEAT')
  ON CONFLICT ("CountryCode", "DeclarationType") DO NOTHING;

  RAISE NOTICE '>> Plantillas de declaración insertadas.';

  -- ============================================================
  -- SEED DATA: Tarifa ISLR Venezuela 2026
  -- ============================================================
  RAISE NOTICE '>> Insertando tarifa ISLR Venezuela 2026...';

  IF NOT EXISTS (SELECT 1 FROM fiscal."ISLRTariff" WHERE "CountryCode" = 'VE' AND "TaxYear" = 2026) THEN
    INSERT INTO fiscal."ISLRTariff" ("CountryCode", "TaxYear", "BracketFrom", "BracketTo", "Rate", "Subtrahend")
    VALUES
      ('VE', 2026,     0.00, 1000.00,  6.00,   0.00),
      ('VE', 2026, 1000.00, 1500.00,  9.00,  30.00),
      ('VE', 2026, 1500.00, 2000.00, 12.00,  75.00),
      ('VE', 2026, 2000.00, 2500.00, 16.00, 155.00),
      ('VE', 2026, 2500.00, 3000.00, 20.00, 255.00),
      ('VE', 2026, 3000.00, 4000.00, 24.00, 375.00),
      ('VE', 2026, 4000.00, 6000.00, 29.00, 575.00),
      ('VE', 2026, 6000.00,    NULL, 34.00, 875.00);
    RAISE NOTICE '>> Tarifa ISLR 2026 insertada (8 tramos).';
  ELSE
    RAISE NOTICE '>> Tarifa ISLR 2026 ya existe, omitida.';
  END IF;

  -- ============================================================
  -- SEED DATA: Complemento master."TaxRetention"
  -- ============================================================
  RAISE NOTICE '>> Verificando retenciones en master."TaxRetention"...';

  -- Venezuela - IVA
  INSERT INTO master."TaxRetention" ("RetentionCode", "RetentionType", "RetentionRate", "CountryCode", "Description")
  SELECT 'RET_IVA_75', 'IVA', 75.00, 'VE', 'Retención IVA 75% Contribuyente Ordinario'
  WHERE NOT EXISTS (SELECT 1 FROM master."TaxRetention" WHERE "RetentionCode" = 'RET_IVA_75');

  INSERT INTO master."TaxRetention" ("RetentionCode", "RetentionType", "RetentionRate", "CountryCode", "Description")
  SELECT 'RET_IVA_100', 'IVA', 100.00, 'VE', 'Retención IVA 100% Contribuyente Especial'
  WHERE NOT EXISTS (SELECT 1 FROM master."TaxRetention" WHERE "RetentionCode" = 'RET_IVA_100');

  -- Venezuela - ISLR
  INSERT INTO master."TaxRetention" ("RetentionCode", "RetentionType", "RetentionRate", "CountryCode", "Description")
  SELECT 'RET_ISLR_1', 'ISLR', 1.00, 'VE', 'Retención ISLR 1% Servicios Profesionales'
  WHERE NOT EXISTS (SELECT 1 FROM master."TaxRetention" WHERE "RetentionCode" = 'RET_ISLR_1');

  INSERT INTO master."TaxRetention" ("RetentionCode", "RetentionType", "RetentionRate", "CountryCode", "Description")
  SELECT 'RET_ISLR_2', 'ISLR', 2.00, 'VE', 'Retención ISLR 2% Servicios'
  WHERE NOT EXISTS (SELECT 1 FROM master."TaxRetention" WHERE "RetentionCode" = 'RET_ISLR_2');

  INSERT INTO master."TaxRetention" ("RetentionCode", "RetentionType", "RetentionRate", "CountryCode", "Description")
  SELECT 'RET_ISLR_3', 'ISLR', 3.00, 'VE', 'Retención ISLR 3% Comisiones'
  WHERE NOT EXISTS (SELECT 1 FROM master."TaxRetention" WHERE "RetentionCode" = 'RET_ISLR_3');

  INSERT INTO master."TaxRetention" ("RetentionCode", "RetentionType", "RetentionRate", "CountryCode", "Description")
  SELECT 'RET_ISLR_5', 'ISLR', 5.00, 'VE', 'Retención ISLR 5% Honorarios'
  WHERE NOT EXISTS (SELECT 1 FROM master."TaxRetention" WHERE "RetentionCode" = 'RET_ISLR_5');

  -- España - IRPF
  INSERT INTO master."TaxRetention" ("RetentionCode", "RetentionType", "RetentionRate", "CountryCode", "Description")
  SELECT 'RET_IRPF_15', 'IRPF', 15.00, 'ES', 'Retención IRPF 15% Profesionales'
  WHERE NOT EXISTS (SELECT 1 FROM master."TaxRetention" WHERE "RetentionCode" = 'RET_IRPF_15');

  INSERT INTO master."TaxRetention" ("RetentionCode", "RetentionType", "RetentionRate", "CountryCode", "Description")
  SELECT 'RET_IRPF_19', 'IRPF', 19.00, 'ES', 'Retención IRPF 19% Rendimientos Capital'
  WHERE NOT EXISTS (SELECT 1 FROM master."TaxRetention" WHERE "RetentionCode" = 'RET_IRPF_19');

  INSERT INTO master."TaxRetention" ("RetentionCode", "RetentionType", "RetentionRate", "CountryCode", "Description")
  SELECT 'RET_IRPF_7', 'IRPF', 7.00, 'ES', 'Retención IRPF 7% Nuevos Profesionales'
  WHERE NOT EXISTS (SELECT 1 FROM master."TaxRetention" WHERE "RetentionCode" = 'RET_IRPF_7');

  RAISE NOTICE '>> Retenciones en master."TaxRetention" verificadas.';

  RAISE NOTICE '========================================================';
  RAISE NOTICE '>> Módulo fiscal/tributaria desplegado exitosamente.';
  RAISE NOTICE '========================================================';

EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE 'ERROR en módulo fiscal/tributaria: %', SQLERRM;
  RAISE;
END $$;
