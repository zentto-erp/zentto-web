/*
  Script: 001_fiscal_multipais_base.sql
  Scope : Multi-country fiscal base for Venezuela + Espana (Verifactu)
  Notes : Non-destructive and idempotent.
*/
SET NOCOUNT ON;

IF OBJECT_ID('dbo.FiscalCountryConfig', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.FiscalCountryConfig (
        Id                  INT IDENTITY(1,1) PRIMARY KEY,
        EmpresaId           INT NOT NULL,
        SucursalId          INT NOT NULL CONSTRAINT DF_FiscalCountryConfig_SucursalId DEFAULT(0),
        CountryCode         CHAR(2) NOT NULL,
        Currency            VARCHAR(3) NOT NULL,
        TaxRegime           VARCHAR(50) NULL,
        DefaultTaxCode      VARCHAR(30) NULL,
        DefaultTaxRate      DECIMAL(5,4) NOT NULL,
        FiscalPrinterEnabled BIT NOT NULL CONSTRAINT DF_FiscalCountryConfig_FiscalPrinterEnabled DEFAULT(0),
        PrinterBrand        VARCHAR(30) NULL,
        PrinterPort         VARCHAR(20) NULL,
        SenderRIF           VARCHAR(20) NULL,
        VerifactuEnabled    BIT NOT NULL CONSTRAINT DF_FiscalCountryConfig_VerifactuEnabled DEFAULT(0),
        VerifactuMode       VARCHAR(10) NULL,
        SenderNIF           VARCHAR(20) NULL,
        CertificatePath     VARCHAR(500) NULL,
        CertificatePassword VARCHAR(500) NULL,
        AEATEndpoint        VARCHAR(500) NULL,
        SoftwareId          VARCHAR(100) NULL,
        SoftwareName        VARCHAR(200) NULL,
        SoftwareVersion     VARCHAR(20) NULL,
        PosEnabled          BIT NOT NULL CONSTRAINT DF_FiscalCountryConfig_PosEnabled DEFAULT(1),
        RestaurantEnabled   BIT NOT NULL CONSTRAINT DF_FiscalCountryConfig_RestaurantEnabled DEFAULT(1),
        IsActive            BIT NOT NULL CONSTRAINT DF_FiscalCountryConfig_IsActive DEFAULT(1),
        CreatedAt           DATETIME NOT NULL CONSTRAINT DF_FiscalCountryConfig_CreatedAt DEFAULT(GETDATE()),
        UpdatedAt           DATETIME NOT NULL CONSTRAINT DF_FiscalCountryConfig_UpdatedAt DEFAULT(GETDATE())
    );

    CREATE UNIQUE INDEX UQ_FiscalCountryConfig_Context
        ON dbo.FiscalCountryConfig (EmpresaId, SucursalId, CountryCode);
END;

IF OBJECT_ID('dbo.FiscalTaxRates', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.FiscalTaxRates (
        Id                  INT IDENTITY(1,1) PRIMARY KEY,
        CountryCode         CHAR(2) NOT NULL,
        Code                VARCHAR(30) NOT NULL,
        Name                NVARCHAR(100) NOT NULL,
        Rate                DECIMAL(5,4) NOT NULL,
        SurchargeRate       DECIMAL(5,4) NULL,
        AppliesToPOS        BIT NOT NULL CONSTRAINT DF_FiscalTaxRates_AppliesToPOS DEFAULT(1),
        AppliesToRestaurant BIT NOT NULL CONSTRAINT DF_FiscalTaxRates_AppliesToRestaurant DEFAULT(1),
        IsDefault           BIT NOT NULL CONSTRAINT DF_FiscalTaxRates_IsDefault DEFAULT(0),
        IsActive            BIT NOT NULL CONSTRAINT DF_FiscalTaxRates_IsActive DEFAULT(1),
        SortOrder           INT NOT NULL CONSTRAINT DF_FiscalTaxRates_SortOrder DEFAULT(0),
        CreatedAt           DATETIME NOT NULL CONSTRAINT DF_FiscalTaxRates_CreatedAt DEFAULT(GETDATE())
    );

    CREATE UNIQUE INDEX UQ_FiscalTaxRates_Code
        ON dbo.FiscalTaxRates (CountryCode, Code);
END;

IF OBJECT_ID('dbo.FiscalInvoiceTypes', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.FiscalInvoiceTypes (
        Id                    INT IDENTITY(1,1) PRIMARY KEY,
        CountryCode           CHAR(2) NOT NULL,
        Code                  VARCHAR(10) NOT NULL,
        Name                  NVARCHAR(100) NOT NULL,
        IsRectificative       BIT NOT NULL CONSTRAINT DF_FiscalInvoiceTypes_IsRectificative DEFAULT(0),
        RequiresRecipientId   BIT NOT NULL CONSTRAINT DF_FiscalInvoiceTypes_RequiresRecipientId DEFAULT(0),
        MaxAmount             DECIMAL(18,2) NULL,
        RequiresFiscalPrinter BIT NOT NULL CONSTRAINT DF_FiscalInvoiceTypes_RequiresFiscalPrinter DEFAULT(0),
        IsActive              BIT NOT NULL CONSTRAINT DF_FiscalInvoiceTypes_IsActive DEFAULT(1),
        SortOrder             INT NOT NULL CONSTRAINT DF_FiscalInvoiceTypes_SortOrder DEFAULT(0),
        CreatedAt             DATETIME NOT NULL CONSTRAINT DF_FiscalInvoiceTypes_CreatedAt DEFAULT(GETDATE())
    );

    CREATE UNIQUE INDEX UQ_FiscalInvoiceTypes_Code
        ON dbo.FiscalInvoiceTypes (CountryCode, Code);
END;

IF OBJECT_ID('dbo.FiscalInvoiceTypes', 'U') IS NOT NULL
BEGIN
    IF COL_LENGTH('dbo.FiscalInvoiceTypes', 'Code') IS NOT NULL
       AND COL_LENGTH('dbo.FiscalInvoiceTypes', 'Code') < 20
    BEGIN
        ALTER TABLE dbo.FiscalInvoiceTypes
            ALTER COLUMN Code VARCHAR(20) NOT NULL;
    END;
END;

IF OBJECT_ID('dbo.FiscalRecords', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.FiscalRecords (
        Id                  BIGINT IDENTITY(1,1) PRIMARY KEY,
        EmpresaId           INT NOT NULL,
        SucursalId          INT NOT NULL CONSTRAINT DF_FiscalRecords_SucursalId DEFAULT(0),
        CountryCode         CHAR(2) NOT NULL,
        InvoiceId           INT NOT NULL,
        InvoiceType         VARCHAR(10) NOT NULL,
        InvoiceNumber       VARCHAR(50) NOT NULL,
        InvoiceDate         DATE NOT NULL,
        RecipientId         VARCHAR(20) NULL,
        TotalAmount         DECIMAL(18,2) NOT NULL,
        RecordHash          VARCHAR(64) NOT NULL,
        PreviousRecordHash  VARCHAR(64) NULL,
        XmlContent          NVARCHAR(MAX) NULL,
        DigitalSignature    NVARCHAR(MAX) NULL,
        QRCodeData          VARCHAR(500) NULL,
        SentToAuthority     BIT NOT NULL CONSTRAINT DF_FiscalRecords_SentToAuthority DEFAULT(0),
        SentAt              DATETIME NULL,
        AuthorityResponse   NVARCHAR(MAX) NULL,
        AuthorityStatus     VARCHAR(20) NULL,
        FiscalPrinterSerial VARCHAR(30) NULL,
        FiscalControlNumber VARCHAR(30) NULL,
        ZReportNumber       INT NULL,
        CreatedAt           DATETIME NOT NULL CONSTRAINT DF_FiscalRecords_CreatedAt DEFAULT(GETDATE())
    );

    CREATE INDEX IX_FiscalRecords_Chain
        ON dbo.FiscalRecords (EmpresaId, SucursalId, CountryCode, Id);
END;

IF OBJECT_ID('dbo.FiscalRecords', 'U') IS NOT NULL
BEGIN
    IF COL_LENGTH('dbo.FiscalRecords', 'InvoiceType') IS NOT NULL
       AND COL_LENGTH('dbo.FiscalRecords', 'InvoiceType') < 20
    BEGIN
        ALTER TABLE dbo.FiscalRecords
            ALTER COLUMN InvoiceType VARCHAR(20) NOT NULL;
    END;
END;

-- Tax rates VE
IF NOT EXISTS (SELECT 1 FROM dbo.FiscalTaxRates WHERE CountryCode = 'VE' AND Code = 'IVA_GENERAL')
    INSERT INTO dbo.FiscalTaxRates (CountryCode, Code, Name, Rate, AppliesToPOS, AppliesToRestaurant, IsDefault, SortOrder)
    VALUES ('VE', 'IVA_GENERAL', N'IVA General', 0.1600, 1, 1, 1, 10);

IF NOT EXISTS (SELECT 1 FROM dbo.FiscalTaxRates WHERE CountryCode = 'VE' AND Code = 'IVA_REDUCIDO')
    INSERT INTO dbo.FiscalTaxRates (CountryCode, Code, Name, Rate, AppliesToPOS, AppliesToRestaurant, IsDefault, SortOrder)
    VALUES ('VE', 'IVA_REDUCIDO', N'IVA Reducido', 0.0800, 1, 1, 0, 20);

IF NOT EXISTS (SELECT 1 FROM dbo.FiscalTaxRates WHERE CountryCode = 'VE' AND Code = 'IVA_ADICIONAL')
    INSERT INTO dbo.FiscalTaxRates (CountryCode, Code, Name, Rate, AppliesToPOS, AppliesToRestaurant, IsDefault, SortOrder)
    VALUES ('VE', 'IVA_ADICIONAL', N'IVA Adicional', 0.3100, 1, 0, 0, 30);

IF NOT EXISTS (SELECT 1 FROM dbo.FiscalTaxRates WHERE CountryCode = 'VE' AND Code = 'EXENTO')
    INSERT INTO dbo.FiscalTaxRates (CountryCode, Code, Name, Rate, AppliesToPOS, AppliesToRestaurant, IsDefault, SortOrder)
    VALUES ('VE', 'EXENTO', N'Exento', 0.0000, 1, 1, 0, 40);

-- Tax rates ES
IF NOT EXISTS (SELECT 1 FROM dbo.FiscalTaxRates WHERE CountryCode = 'ES' AND Code = 'IVA_GENERAL')
    INSERT INTO dbo.FiscalTaxRates (CountryCode, Code, Name, Rate, AppliesToPOS, AppliesToRestaurant, IsDefault, SortOrder)
    VALUES ('ES', 'IVA_GENERAL', N'IVA General', 0.2100, 1, 0, 1, 10);

IF NOT EXISTS (SELECT 1 FROM dbo.FiscalTaxRates WHERE CountryCode = 'ES' AND Code = 'IVA_REDUCIDO')
    INSERT INTO dbo.FiscalTaxRates (CountryCode, Code, Name, Rate, AppliesToPOS, AppliesToRestaurant, IsDefault, SortOrder)
    VALUES ('ES', 'IVA_REDUCIDO', N'IVA Reducido', 0.1000, 1, 1, 0, 20);

IF NOT EXISTS (SELECT 1 FROM dbo.FiscalTaxRates WHERE CountryCode = 'ES' AND Code = 'IVA_SUPERREDUCIDO')
    INSERT INTO dbo.FiscalTaxRates (CountryCode, Code, Name, Rate, AppliesToPOS, AppliesToRestaurant, IsDefault, SortOrder)
    VALUES ('ES', 'IVA_SUPERREDUCIDO', N'IVA Superreducido', 0.0400, 1, 0, 0, 30);

IF NOT EXISTS (SELECT 1 FROM dbo.FiscalTaxRates WHERE CountryCode = 'ES' AND Code = 'EXENTO')
    INSERT INTO dbo.FiscalTaxRates (CountryCode, Code, Name, Rate, AppliesToPOS, AppliesToRestaurant, IsDefault, SortOrder)
    VALUES ('ES', 'EXENTO', N'Exento', 0.0000, 1, 1, 0, 40);

IF NOT EXISTS (SELECT 1 FROM dbo.FiscalTaxRates WHERE CountryCode = 'ES' AND Code = 'RE_GENERAL')
    INSERT INTO dbo.FiscalTaxRates (CountryCode, Code, Name, Rate, SurchargeRate, AppliesToPOS, AppliesToRestaurant, IsDefault, SortOrder)
    VALUES ('ES', 'RE_GENERAL', N'Recargo Equivalencia General', 0.0520, 0.0520, 1, 0, 0, 50);

IF NOT EXISTS (SELECT 1 FROM dbo.FiscalTaxRates WHERE CountryCode = 'ES' AND Code = 'RE_REDUCIDO')
    INSERT INTO dbo.FiscalTaxRates (CountryCode, Code, Name, Rate, SurchargeRate, AppliesToPOS, AppliesToRestaurant, IsDefault, SortOrder)
    VALUES ('ES', 'RE_REDUCIDO', N'Recargo Equivalencia Reducido', 0.0140, 0.0140, 1, 0, 0, 60);

IF NOT EXISTS (SELECT 1 FROM dbo.FiscalTaxRates WHERE CountryCode = 'ES' AND Code = 'RE_SUPERREDUCIDO')
    INSERT INTO dbo.FiscalTaxRates (CountryCode, Code, Name, Rate, SurchargeRate, AppliesToPOS, AppliesToRestaurant, IsDefault, SortOrder)
    VALUES ('ES', 'RE_SUPERREDUCIDO', N'Recargo Equivalencia Superreducido', 0.0050, 0.0050, 1, 0, 0, 70);

-- Invoice types VE
IF NOT EXISTS (SELECT 1 FROM dbo.FiscalInvoiceTypes WHERE CountryCode = 'VE' AND Code = 'FACTURA')
    INSERT INTO dbo.FiscalInvoiceTypes (CountryCode, Code, Name, IsRectificative, RequiresRecipientId, MaxAmount, RequiresFiscalPrinter, SortOrder)
    VALUES ('VE', 'FACTURA', N'Factura Fiscal', 0, 1, NULL, 1, 10);

IF NOT EXISTS (SELECT 1 FROM dbo.FiscalInvoiceTypes WHERE CountryCode = 'VE' AND Code = 'NOTA_CREDITO')
    INSERT INTO dbo.FiscalInvoiceTypes (CountryCode, Code, Name, IsRectificative, RequiresRecipientId, MaxAmount, RequiresFiscalPrinter, SortOrder)
    VALUES ('VE', 'NOTA_CREDITO', N'Nota de Credito Fiscal', 1, 1, NULL, 1, 20);

IF NOT EXISTS (SELECT 1 FROM dbo.FiscalInvoiceTypes WHERE CountryCode = 'VE' AND Code = 'NOTA_DEBITO')
    INSERT INTO dbo.FiscalInvoiceTypes (CountryCode, Code, Name, IsRectificative, RequiresRecipientId, MaxAmount, RequiresFiscalPrinter, SortOrder)
    VALUES ('VE', 'NOTA_DEBITO', N'Nota de Debito Fiscal', 0, 1, NULL, 1, 30);

-- Invoice types ES
IF NOT EXISTS (SELECT 1 FROM dbo.FiscalInvoiceTypes WHERE CountryCode = 'ES' AND Code = 'F1')
    INSERT INTO dbo.FiscalInvoiceTypes (CountryCode, Code, Name, IsRectificative, RequiresRecipientId, MaxAmount, RequiresFiscalPrinter, SortOrder)
    VALUES ('ES', 'F1', N'Factura Completa', 0, 1, NULL, 0, 10);

IF NOT EXISTS (SELECT 1 FROM dbo.FiscalInvoiceTypes WHERE CountryCode = 'ES' AND Code = 'F2')
    INSERT INTO dbo.FiscalInvoiceTypes (CountryCode, Code, Name, IsRectificative, RequiresRecipientId, MaxAmount, RequiresFiscalPrinter, SortOrder)
    VALUES ('ES', 'F2', N'Factura Simplificada', 0, 0, 3000.00, 0, 20);

IF NOT EXISTS (SELECT 1 FROM dbo.FiscalInvoiceTypes WHERE CountryCode = 'ES' AND Code = 'F3')
    INSERT INTO dbo.FiscalInvoiceTypes (CountryCode, Code, Name, IsRectificative, RequiresRecipientId, MaxAmount, RequiresFiscalPrinter, SortOrder)
    VALUES ('ES', 'F3', N'Factura Sustitucion Simplificada', 0, 1, NULL, 0, 30);

IF NOT EXISTS (SELECT 1 FROM dbo.FiscalInvoiceTypes WHERE CountryCode = 'ES' AND Code = 'R1')
    INSERT INTO dbo.FiscalInvoiceTypes (CountryCode, Code, Name, IsRectificative, RequiresRecipientId, MaxAmount, RequiresFiscalPrinter, SortOrder)
    VALUES ('ES', 'R1', N'Rectificativa R1', 1, 1, NULL, 0, 40);

IF NOT EXISTS (SELECT 1 FROM dbo.FiscalInvoiceTypes WHERE CountryCode = 'ES' AND Code = 'R2')
    INSERT INTO dbo.FiscalInvoiceTypes (CountryCode, Code, Name, IsRectificative, RequiresRecipientId, MaxAmount, RequiresFiscalPrinter, SortOrder)
    VALUES ('ES', 'R2', N'Rectificativa R2', 1, 1, NULL, 0, 50);

IF NOT EXISTS (SELECT 1 FROM dbo.FiscalInvoiceTypes WHERE CountryCode = 'ES' AND Code = 'R3')
    INSERT INTO dbo.FiscalInvoiceTypes (CountryCode, Code, Name, IsRectificative, RequiresRecipientId, MaxAmount, RequiresFiscalPrinter, SortOrder)
    VALUES ('ES', 'R3', N'Rectificativa R3', 1, 1, NULL, 0, 60);

IF NOT EXISTS (SELECT 1 FROM dbo.FiscalInvoiceTypes WHERE CountryCode = 'ES' AND Code = 'R4')
    INSERT INTO dbo.FiscalInvoiceTypes (CountryCode, Code, Name, IsRectificative, RequiresRecipientId, MaxAmount, RequiresFiscalPrinter, SortOrder)
    VALUES ('ES', 'R4', N'Rectificativa R4', 1, 1, NULL, 0, 70);

IF NOT EXISTS (SELECT 1 FROM dbo.FiscalInvoiceTypes WHERE CountryCode = 'ES' AND Code = 'R5')
    INSERT INTO dbo.FiscalInvoiceTypes (CountryCode, Code, Name, IsRectificative, RequiresRecipientId, MaxAmount, RequiresFiscalPrinter, SortOrder)
    VALUES ('ES', 'R5', N'Rectificativa R5', 1, 0, NULL, 0, 80);

PRINT 'Fiscal multi-country base created/updated successfully.';
