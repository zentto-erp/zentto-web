SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

USE DatqBoxWeb;
GO

/*
================================================================================
  MÓDULO FISCAL / TRIBUTARIA
  Gestión de declaraciones, libros fiscales, retenciones y plantillas
  Multi-país: VE, ES, CO, MX, US

  Tablas:
    fiscal.TaxDeclaration      - Declaraciones tributarias (IVA, ISLR, IRPF, etc.)
    fiscal.TaxBookEntry        - Líneas del libro de compras/ventas
    fiscal.WithholdingVoucher  - Comprobantes de retención
    fiscal.DeclarationTemplate - Plantillas de declaración por país
    fiscal.ISLRTariff          - Tabla progresiva ISLR Venezuela

  Seed data:
    - Plantillas de declaración (VE, ES)
    - Tarifa ISLR Venezuela 2026
    - Complemento master.TaxRetention (VE, ES)
================================================================================
*/

BEGIN TRY
  BEGIN TRAN;

  -- ============================================================
  -- ESQUEMA fiscal
  -- ============================================================
  IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'fiscal')
    EXEC('CREATE SCHEMA fiscal');
  PRINT '>> Esquema [fiscal] verificado.';

  -- ============================================================
  -- 1. fiscal.TaxDeclaration - Declaraciones tributarias
  -- ============================================================
  IF OBJECT_ID('fiscal.TaxDeclaration', 'U') IS NULL
  BEGIN
    CREATE TABLE fiscal.TaxDeclaration (
      DeclarationId       BIGINT IDENTITY(1,1) NOT NULL,
      CompanyId           INT NOT NULL,
      BranchId            INT NOT NULL DEFAULT 0,
      CountryCode         NVARCHAR(2) NOT NULL,
      DeclarationType     NVARCHAR(30) NOT NULL,       -- IVA, ISLR, IRPF, MODELO_303, MODELO_390, MODELO_349
      PeriodCode          NVARCHAR(7) NOT NULL,         -- YYYY-MM
      PeriodStart         DATE NOT NULL,
      PeriodEnd           DATE NOT NULL,
      -- Totales ventas/compras
      SalesBase           DECIMAL(18,2) DEFAULT 0,
      SalesTax            DECIMAL(18,2) DEFAULT 0,
      PurchasesBase       DECIMAL(18,2) DEFAULT 0,
      PurchasesTax        DECIMAL(18,2) DEFAULT 0,
      -- Cálculo
      TaxableBase         DECIMAL(18,2) DEFAULT 0,
      TaxAmount           DECIMAL(18,2) DEFAULT 0,
      WithholdingsCredit  DECIMAL(18,2) DEFAULT 0,
      PreviousBalance     DECIMAL(18,2) DEFAULT 0,
      NetPayable          DECIMAL(18,2) DEFAULT 0,
      -- Flujo de estado
      Status              NVARCHAR(20) DEFAULT 'DRAFT', -- DRAFT, CALCULATED, SUBMITTED, PAID, AMENDED
      SubmittedAt         DATETIME NULL,
      SubmittedFile       NVARCHAR(500) NULL,
      AuthorityResponse   NVARCHAR(MAX) NULL,
      PaidAt              DATETIME NULL,
      PaymentReference    NVARCHAR(100) NULL,
      -- Contabilidad
      JournalEntryId      BIGINT NULL,
      Notes               NVARCHAR(1000) NULL,
      CreatedBy           NVARCHAR(40) NULL,
      UpdatedBy           NVARCHAR(40) NULL,
      CreatedAt           DATETIME DEFAULT SYSUTCDATETIME(),
      UpdatedAt           DATETIME NULL,
      CONSTRAINT PK_TaxDeclaration PRIMARY KEY (DeclarationId),
      CONSTRAINT UQ_TaxDeclaration UNIQUE (CompanyId, DeclarationType, PeriodCode)
    );
    PRINT '>> Tabla [fiscal].[TaxDeclaration] creada.';
  END
  ELSE
    PRINT '>> Tabla [fiscal].[TaxDeclaration] ya existe, omitida.';

  -- ============================================================
  -- 2. fiscal.TaxBookEntry - Líneas del libro de compras/ventas
  -- ============================================================
  IF OBJECT_ID('fiscal.TaxBookEntry', 'U') IS NULL
  BEGIN
    CREATE TABLE fiscal.TaxBookEntry (
      EntryId             BIGINT IDENTITY(1,1) NOT NULL,
      CompanyId           INT NOT NULL,
      BookType            NVARCHAR(10) NOT NULL,         -- PURCHASE, SALES
      PeriodCode          NVARCHAR(7) NOT NULL,
      EntryDate           DATE NOT NULL,
      DocumentNumber      NVARCHAR(60) NOT NULL,
      DocumentType        NVARCHAR(30) NULL,             -- FACTURA, NOTA_CREDITO, NOTA_DEBITO
      ControlNumber       NVARCHAR(40) NULL,             -- Número de control (VE)
      ThirdPartyId        NVARCHAR(40) NULL,             -- RIF/NIF del tercero
      ThirdPartyName      NVARCHAR(200) NULL,
      TaxableBase         DECIMAL(18,2) NOT NULL DEFAULT 0,
      ExemptAmount        DECIMAL(18,2) DEFAULT 0,
      TaxRate             DECIMAL(5,2) NOT NULL DEFAULT 0,
      TaxAmount           DECIMAL(18,2) NOT NULL DEFAULT 0,
      WithholdingRate     DECIMAL(5,2) DEFAULT 0,
      WithholdingAmount   DECIMAL(18,2) DEFAULT 0,
      TotalAmount         DECIMAL(18,2) NOT NULL DEFAULT 0,
      SourceDocumentId    BIGINT NULL,
      SourceModule        NVARCHAR(20) NULL,             -- AR, AP, POS
      CountryCode         NVARCHAR(2) NOT NULL,
      DeclarationId       BIGINT NULL,
      CreatedAt           DATETIME DEFAULT SYSUTCDATETIME(),
      CONSTRAINT PK_TaxBookEntry PRIMARY KEY (EntryId),
      CONSTRAINT FK_TaxBookEntry_Declaration FOREIGN KEY (DeclarationId)
        REFERENCES fiscal.TaxDeclaration (DeclarationId)
    );
    PRINT '>> Tabla [fiscal].[TaxBookEntry] creada.';
  END
  ELSE
    PRINT '>> Tabla [fiscal].[TaxBookEntry] ya existe, omitida.';

  -- ============================================================
  -- 3. fiscal.WithholdingVoucher - Comprobantes de retención
  -- ============================================================
  IF OBJECT_ID('fiscal.WithholdingVoucher', 'U') IS NULL
  BEGIN
    CREATE TABLE fiscal.WithholdingVoucher (
      VoucherId           BIGINT IDENTITY(1,1) NOT NULL,
      CompanyId           INT NOT NULL,
      VoucherNumber       NVARCHAR(40) NOT NULL,
      VoucherDate         DATE NOT NULL,
      WithholdingType     NVARCHAR(20) NOT NULL,         -- IVA, ISLR, IRPF, ICA
      ThirdPartyId        NVARCHAR(40) NOT NULL,
      ThirdPartyName      NVARCHAR(200) NULL,
      DocumentNumber      NVARCHAR(60) NOT NULL,
      DocumentDate        DATE NULL,
      TaxableBase         DECIMAL(18,2) NOT NULL,
      WithholdingRate     DECIMAL(5,2) NOT NULL,
      WithholdingAmount   DECIMAL(18,2) NOT NULL,
      PeriodCode          NVARCHAR(7) NOT NULL,
      Status              NVARCHAR(20) DEFAULT 'ACTIVE', -- ACTIVE, VOIDED
      CountryCode         NVARCHAR(2) NOT NULL,
      JournalEntryId      BIGINT NULL,
      CreatedBy           NVARCHAR(40) NULL,
      CreatedAt           DATETIME DEFAULT SYSUTCDATETIME(),
      CONSTRAINT PK_WithholdingVoucher PRIMARY KEY (VoucherId),
      CONSTRAINT UQ_WithholdingVoucher UNIQUE (CompanyId, VoucherNumber)
    );
    PRINT '>> Tabla [fiscal].[WithholdingVoucher] creada.';
  END
  ELSE
    PRINT '>> Tabla [fiscal].[WithholdingVoucher] ya existe, omitida.';

  -- ============================================================
  -- 4. fiscal.DeclarationTemplate - Plantillas por país
  -- ============================================================
  IF OBJECT_ID('fiscal.DeclarationTemplate', 'U') IS NULL
  BEGIN
    CREATE TABLE fiscal.DeclarationTemplate (
      TemplateId          INT IDENTITY(1,1) NOT NULL,
      CountryCode         NVARCHAR(2) NOT NULL,
      DeclarationType     NVARCHAR(30) NOT NULL,
      TemplateName        NVARCHAR(200) NOT NULL,
      FileFormat          NVARCHAR(10) NOT NULL,         -- XML, TXT, JSON
      FormatVersion       NVARCHAR(20) NULL,
      AuthorityName       NVARCHAR(100) NULL,
      AuthorityUrl        NVARCHAR(500) NULL,
      IsActive            BIT DEFAULT 1,
      CreatedAt           DATETIME DEFAULT SYSUTCDATETIME(),
      CONSTRAINT PK_DeclarationTemplate PRIMARY KEY (TemplateId),
      CONSTRAINT UQ_DeclTemplate UNIQUE (CountryCode, DeclarationType)
    );
    PRINT '>> Tabla [fiscal].[DeclarationTemplate] creada.';
  END
  ELSE
    PRINT '>> Tabla [fiscal].[DeclarationTemplate] ya existe, omitida.';

  -- ============================================================
  -- 5. fiscal.ISLRTariff - Tabla progresiva ISLR Venezuela
  -- ============================================================
  IF OBJECT_ID('fiscal.ISLRTariff', 'U') IS NULL
  BEGIN
    CREATE TABLE fiscal.ISLRTariff (
      TariffId            INT IDENTITY(1,1) NOT NULL,
      CountryCode         NVARCHAR(2) NOT NULL DEFAULT 'VE',
      TaxYear             INT NOT NULL,
      BracketFrom         DECIMAL(18,2) NOT NULL,        -- En UT (Unidades Tributarias)
      BracketTo           DECIMAL(18,2) NULL,
      Rate                DECIMAL(5,2) NOT NULL,
      Subtrahend          DECIMAL(18,2) DEFAULT 0,
      IsActive            BIT DEFAULT 1,
      CONSTRAINT PK_ISLRTariff PRIMARY KEY (TariffId)
    );
    PRINT '>> Tabla [fiscal].[ISLRTariff] creada.';
  END
  ELSE
    PRINT '>> Tabla [fiscal].[ISLRTariff] ya existe, omitida.';

  -- ============================================================
  -- ÍNDICES
  -- ============================================================
  IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_TaxDeclaration_Country_Period')
    CREATE NONCLUSTERED INDEX IX_TaxDeclaration_Country_Period
      ON fiscal.TaxDeclaration (CountryCode, PeriodCode, Status);

  IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_TaxBookEntry_Period_Book')
    CREATE NONCLUSTERED INDEX IX_TaxBookEntry_Period_Book
      ON fiscal.TaxBookEntry (CompanyId, BookType, PeriodCode);

  IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_TaxBookEntry_Declaration')
    CREATE NONCLUSTERED INDEX IX_TaxBookEntry_Declaration
      ON fiscal.TaxBookEntry (DeclarationId)
      WHERE DeclarationId IS NOT NULL;

  IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_WithholdingVoucher_Period')
    CREATE NONCLUSTERED INDEX IX_WithholdingVoucher_Period
      ON fiscal.WithholdingVoucher (CompanyId, PeriodCode, WithholdingType);

  IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_ISLRTariff_Year')
    CREATE NONCLUSTERED INDEX IX_ISLRTariff_Year
      ON fiscal.ISLRTariff (CountryCode, TaxYear, IsActive);

  PRINT '>> Índices verificados.';

  -- ============================================================
  -- SEED DATA: Plantillas de declaración
  -- ============================================================
  PRINT '>> Insertando plantillas de declaración...';

  -- Venezuela
  IF NOT EXISTS (SELECT 1 FROM fiscal.DeclarationTemplate WHERE CountryCode = 'VE' AND DeclarationType = 'IVA')
    INSERT INTO fiscal.DeclarationTemplate (CountryCode, DeclarationType, TemplateName, FileFormat, AuthorityName)
    VALUES ('VE', 'IVA', N'Declaración IVA SENIAT', 'TXT', 'SENIAT');

  IF NOT EXISTS (SELECT 1 FROM fiscal.DeclarationTemplate WHERE CountryCode = 'VE' AND DeclarationType = 'ISLR')
    INSERT INTO fiscal.DeclarationTemplate (CountryCode, DeclarationType, TemplateName, FileFormat, AuthorityName)
    VALUES ('VE', 'ISLR', N'Declaración ISLR SENIAT', 'XML', 'SENIAT');

  IF NOT EXISTS (SELECT 1 FROM fiscal.DeclarationTemplate WHERE CountryCode = 'VE' AND DeclarationType = 'RET_IVA')
    INSERT INTO fiscal.DeclarationTemplate (CountryCode, DeclarationType, TemplateName, FileFormat, AuthorityName)
    VALUES ('VE', 'RET_IVA', N'Retenciones IVA SENIAT', 'XML', 'SENIAT');

  IF NOT EXISTS (SELECT 1 FROM fiscal.DeclarationTemplate WHERE CountryCode = 'VE' AND DeclarationType = 'RET_ISLR')
    INSERT INTO fiscal.DeclarationTemplate (CountryCode, DeclarationType, TemplateName, FileFormat, AuthorityName)
    VALUES ('VE', 'RET_ISLR', N'Retenciones ISLR SENIAT', 'XML', 'SENIAT');

  -- España
  IF NOT EXISTS (SELECT 1 FROM fiscal.DeclarationTemplate WHERE CountryCode = 'ES' AND DeclarationType = 'MODELO_303')
    INSERT INTO fiscal.DeclarationTemplate (CountryCode, DeclarationType, TemplateName, FileFormat, AuthorityName)
    VALUES ('ES', 'MODELO_303', N'Modelo 303 - IVA Trimestral', 'XML', 'AEAT');

  IF NOT EXISTS (SELECT 1 FROM fiscal.DeclarationTemplate WHERE CountryCode = 'ES' AND DeclarationType = 'MODELO_390')
    INSERT INTO fiscal.DeclarationTemplate (CountryCode, DeclarationType, TemplateName, FileFormat, AuthorityName)
    VALUES ('ES', 'MODELO_390', N'Modelo 390 - Resumen Anual IVA', 'XML', 'AEAT');

  IF NOT EXISTS (SELECT 1 FROM fiscal.DeclarationTemplate WHERE CountryCode = 'ES' AND DeclarationType = 'MODELO_349')
    INSERT INTO fiscal.DeclarationTemplate (CountryCode, DeclarationType, TemplateName, FileFormat, AuthorityName)
    VALUES ('ES', 'MODELO_349', N'Modelo 349 - Operaciones Intracomunitarias', 'XML', 'AEAT');

  IF NOT EXISTS (SELECT 1 FROM fiscal.DeclarationTemplate WHERE CountryCode = 'ES' AND DeclarationType = 'MODELO_111')
    INSERT INTO fiscal.DeclarationTemplate (CountryCode, DeclarationType, TemplateName, FileFormat, AuthorityName)
    VALUES ('ES', 'MODELO_111', N'Modelo 111 - Retenciones IRPF', 'XML', 'AEAT');

  IF NOT EXISTS (SELECT 1 FROM fiscal.DeclarationTemplate WHERE CountryCode = 'ES' AND DeclarationType = 'MODELO_190')
    INSERT INTO fiscal.DeclarationTemplate (CountryCode, DeclarationType, TemplateName, FileFormat, AuthorityName)
    VALUES ('ES', 'MODELO_190', N'Modelo 190 - Resumen Anual Retenciones', 'XML', 'AEAT');

  PRINT '>> Plantillas de declaración insertadas.';

  -- ============================================================
  -- SEED DATA: Tarifa ISLR Venezuela 2026
  -- ============================================================
  PRINT '>> Insertando tarifa ISLR Venezuela 2026...';

  IF NOT EXISTS (SELECT 1 FROM fiscal.ISLRTariff WHERE CountryCode = 'VE' AND TaxYear = 2026)
  BEGIN
    INSERT INTO fiscal.ISLRTariff (CountryCode, TaxYear, BracketFrom, BracketTo, Rate, Subtrahend)
    VALUES
      ('VE', 2026,     0.00, 1000.00,  6.00,   0.00),
      ('VE', 2026, 1000.00, 1500.00,  9.00,  30.00),
      ('VE', 2026, 1500.00, 2000.00, 12.00,  75.00),
      ('VE', 2026, 2000.00, 2500.00, 16.00, 155.00),
      ('VE', 2026, 2500.00, 3000.00, 20.00, 255.00),
      ('VE', 2026, 3000.00, 4000.00, 24.00, 375.00),
      ('VE', 2026, 4000.00, 6000.00, 29.00, 575.00),
      ('VE', 2026, 6000.00,    NULL, 34.00, 875.00);
    PRINT '>> Tarifa ISLR 2026 insertada (8 tramos).';
  END
  ELSE
    PRINT '>> Tarifa ISLR 2026 ya existe, omitida.';

  -- ============================================================
  -- SEED DATA: Complemento master.TaxRetention
  -- ============================================================
  PRINT '>> Verificando retenciones en master.TaxRetention...';

  -- Venezuela - IVA
  IF NOT EXISTS (SELECT 1 FROM master.TaxRetention WHERE RetentionCode = 'RET_IVA_75')
    INSERT INTO master.TaxRetention (RetentionCode, RetentionType, RetentionRate, CountryCode, Description)
    VALUES ('RET_IVA_75', 'IVA', 75.00, 'VE', N'Retención IVA 75% Contribuyente Ordinario');

  IF NOT EXISTS (SELECT 1 FROM master.TaxRetention WHERE RetentionCode = 'RET_IVA_100')
    INSERT INTO master.TaxRetention (RetentionCode, RetentionType, RetentionRate, CountryCode, Description)
    VALUES ('RET_IVA_100', 'IVA', 100.00, 'VE', N'Retención IVA 100% Contribuyente Especial');

  -- Venezuela - ISLR
  IF NOT EXISTS (SELECT 1 FROM master.TaxRetention WHERE RetentionCode = 'RET_ISLR_1')
    INSERT INTO master.TaxRetention (RetentionCode, RetentionType, RetentionRate, CountryCode, Description)
    VALUES ('RET_ISLR_1', 'ISLR', 1.00, 'VE', N'Retención ISLR 1% Servicios Profesionales');

  IF NOT EXISTS (SELECT 1 FROM master.TaxRetention WHERE RetentionCode = 'RET_ISLR_2')
    INSERT INTO master.TaxRetention (RetentionCode, RetentionType, RetentionRate, CountryCode, Description)
    VALUES ('RET_ISLR_2', 'ISLR', 2.00, 'VE', N'Retención ISLR 2% Servicios');

  IF NOT EXISTS (SELECT 1 FROM master.TaxRetention WHERE RetentionCode = 'RET_ISLR_3')
    INSERT INTO master.TaxRetention (RetentionCode, RetentionType, RetentionRate, CountryCode, Description)
    VALUES ('RET_ISLR_3', 'ISLR', 3.00, 'VE', N'Retención ISLR 3% Comisiones');

  IF NOT EXISTS (SELECT 1 FROM master.TaxRetention WHERE RetentionCode = 'RET_ISLR_5')
    INSERT INTO master.TaxRetention (RetentionCode, RetentionType, RetentionRate, CountryCode, Description)
    VALUES ('RET_ISLR_5', 'ISLR', 5.00, 'VE', N'Retención ISLR 5% Honorarios');

  -- España - IRPF
  IF NOT EXISTS (SELECT 1 FROM master.TaxRetention WHERE RetentionCode = 'RET_IRPF_15')
    INSERT INTO master.TaxRetention (RetentionCode, RetentionType, RetentionRate, CountryCode, Description)
    VALUES ('RET_IRPF_15', 'IRPF', 15.00, 'ES', N'Retención IRPF 15% Profesionales');

  IF NOT EXISTS (SELECT 1 FROM master.TaxRetention WHERE RetentionCode = 'RET_IRPF_19')
    INSERT INTO master.TaxRetention (RetentionCode, RetentionType, RetentionRate, CountryCode, Description)
    VALUES ('RET_IRPF_19', 'IRPF', 19.00, 'ES', N'Retención IRPF 19% Rendimientos Capital');

  IF NOT EXISTS (SELECT 1 FROM master.TaxRetention WHERE RetentionCode = 'RET_IRPF_7')
    INSERT INTO master.TaxRetention (RetentionCode, RetentionType, RetentionRate, CountryCode, Description)
    VALUES ('RET_IRPF_7', 'IRPF', 7.00, 'ES', N'Retención IRPF 7% Nuevos Profesionales');

  PRINT '>> Retenciones en master.TaxRetention verificadas.';

  -- ============================================================
  COMMIT TRAN;
  PRINT '========================================================';
  PRINT '>> Módulo fiscal/tributaria desplegado exitosamente.';
  PRINT '========================================================';
END TRY
BEGIN CATCH
  IF @@TRANCOUNT > 0
    ROLLBACK TRAN;
  PRINT '!! ERROR en módulo fiscal/tributaria:';
  PRINT '   Mensaje: ' + ERROR_MESSAGE();
  PRINT '   Línea:   ' + CAST(ERROR_LINE() AS NVARCHAR(10));
  THROW;
END CATCH;
GO
