USE DatqBoxWeb;
GO
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

-- ============================================================
-- 1. Agregar columnas faltantes a cfg.Country
-- ============================================================

IF COL_LENGTH('cfg.Country', 'CurrencySymbol') IS NULL
    ALTER TABLE cfg.Country ADD CurrencySymbol NVARCHAR(5) NOT NULL DEFAULT N'$';
GO
IF COL_LENGTH('cfg.Country', 'ReferenceCurrency') IS NULL
    ALTER TABLE cfg.Country ADD ReferenceCurrency CHAR(3) NOT NULL DEFAULT 'USD';
GO
IF COL_LENGTH('cfg.Country', 'ReferenceCurrencySymbol') IS NULL
    ALTER TABLE cfg.Country ADD ReferenceCurrencySymbol NVARCHAR(5) NOT NULL DEFAULT N'$';
GO
IF COL_LENGTH('cfg.Country', 'DefaultExchangeRate') IS NULL
    ALTER TABLE cfg.Country ADD DefaultExchangeRate DECIMAL(18,4) NOT NULL DEFAULT 1.0;
GO
IF COL_LENGTH('cfg.Country', 'PricesIncludeTax') IS NULL
    ALTER TABLE cfg.Country ADD PricesIncludeTax BIT NOT NULL DEFAULT 0;
GO
IF COL_LENGTH('cfg.Country', 'SpecialTaxRate') IS NULL
    ALTER TABLE cfg.Country ADD SpecialTaxRate DECIMAL(5,2) NOT NULL DEFAULT 0;
GO
IF COL_LENGTH('cfg.Country', 'SpecialTaxEnabled') IS NULL
    ALTER TABLE cfg.Country ADD SpecialTaxEnabled BIT NOT NULL DEFAULT 0;
GO
IF COL_LENGTH('cfg.Country', 'PhonePrefix') IS NULL
    ALTER TABLE cfg.Country ADD PhonePrefix NVARCHAR(5) NULL;
GO
IF COL_LENGTH('cfg.Country', 'SortOrder') IS NULL
    ALTER TABLE cfg.Country ADD SortOrder INT NOT NULL DEFAULT 100;
GO

-- ============================================================
-- 2. Stored Procedures
-- ============================================================

-- ------------------------------------------------------------
-- usp_CFG_Country_List
-- Lista países activos ordenados por SortOrder, CountryName
-- ------------------------------------------------------------
IF OBJECT_ID('dbo.usp_CFG_Country_List', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_CFG_Country_List;
GO

CREATE PROCEDURE dbo.usp_CFG_Country_List
    @ActiveOnly BIT = 1
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        CountryCode,
        CountryName,
        CurrencyCode,
        CurrencySymbol,
        ReferenceCurrency,
        ReferenceCurrencySymbol,
        DefaultExchangeRate,
        PricesIncludeTax,
        SpecialTaxRate,
        SpecialTaxEnabled,
        TaxAuthorityCode,
        FiscalIdName,
        TimeZoneIana,
        PhonePrefix,
        SortOrder,
        IsActive,
        CreatedAt,
        UpdatedAt
    FROM cfg.Country
    WHERE (@ActiveOnly = 0 OR IsActive = 1)
    ORDER BY SortOrder, CountryName;
END;
GO

-- ------------------------------------------------------------
-- usp_CFG_Country_Save
-- Insert o Update país
-- ------------------------------------------------------------
IF OBJECT_ID('dbo.usp_CFG_Country_Save', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_CFG_Country_Save;
GO

CREATE PROCEDURE dbo.usp_CFG_Country_Save
    @CountryCode            CHAR(2),
    @CountryName            NVARCHAR(80),
    @CurrencyCode           CHAR(3),
    @CurrencySymbol         NVARCHAR(5),
    @ReferenceCurrency      CHAR(3),
    @ReferenceCurrencySymbol NVARCHAR(5),
    @DefaultExchangeRate    DECIMAL(18,4),
    @PricesIncludeTax       BIT,
    @SpecialTaxRate         DECIMAL(5,2),
    @SpecialTaxEnabled      BIT,
    @TaxAuthorityCode       NVARCHAR(20),
    @FiscalIdName           NVARCHAR(20),
    @TimeZoneIana           NVARCHAR(64),
    @PhonePrefix            NVARCHAR(5),
    @SortOrder              INT,
    @IsActive               BIT,
    @Resultado              INT OUTPUT,
    @Mensaje                NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        IF EXISTS (SELECT 1 FROM cfg.Country WHERE CountryCode = @CountryCode)
        BEGIN
            UPDATE cfg.Country
            SET CountryName            = @CountryName,
                CurrencyCode           = @CurrencyCode,
                CurrencySymbol         = @CurrencySymbol,
                ReferenceCurrency      = @ReferenceCurrency,
                ReferenceCurrencySymbol = @ReferenceCurrencySymbol,
                DefaultExchangeRate    = @DefaultExchangeRate,
                PricesIncludeTax       = @PricesIncludeTax,
                SpecialTaxRate         = @SpecialTaxRate,
                SpecialTaxEnabled      = @SpecialTaxEnabled,
                TaxAuthorityCode       = @TaxAuthorityCode,
                FiscalIdName           = @FiscalIdName,
                TimeZoneIana           = @TimeZoneIana,
                PhonePrefix            = @PhonePrefix,
                SortOrder              = @SortOrder,
                IsActive               = @IsActive,
                UpdatedAt              = SYSUTCDATETIME()
            WHERE CountryCode = @CountryCode;

            SET @Resultado = 0;
            SET @Mensaje = N'País actualizado correctamente.';
        END
        ELSE
        BEGIN
            INSERT INTO cfg.Country (
                CountryCode, CountryName, CurrencyCode, CurrencySymbol,
                ReferenceCurrency, ReferenceCurrencySymbol, DefaultExchangeRate,
                PricesIncludeTax, SpecialTaxRate, SpecialTaxEnabled,
                TaxAuthorityCode, FiscalIdName, TimeZoneIana, PhonePrefix,
                SortOrder, IsActive, CreatedAt, UpdatedAt
            )
            VALUES (
                @CountryCode, @CountryName, @CurrencyCode, @CurrencySymbol,
                @ReferenceCurrency, @ReferenceCurrencySymbol, @DefaultExchangeRate,
                @PricesIncludeTax, @SpecialTaxRate, @SpecialTaxEnabled,
                @TaxAuthorityCode, @FiscalIdName, @TimeZoneIana, @PhonePrefix,
                @SortOrder, @IsActive, SYSUTCDATETIME(), SYSUTCDATETIME()
            );

            SET @Resultado = 0;
            SET @Mensaje = N'País creado correctamente.';
        END
    END TRY
    BEGIN CATCH
        SET @Resultado = -1;
        SET @Mensaje = ERROR_MESSAGE();
    END CATCH
END;
GO

-- ------------------------------------------------------------
-- usp_CFG_Country_Get
-- Obtener un país por código
-- ------------------------------------------------------------
IF OBJECT_ID('dbo.usp_CFG_Country_Get', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_CFG_Country_Get;
GO

CREATE PROCEDURE dbo.usp_CFG_Country_Get
    @CountryCode CHAR(2)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        CountryCode,
        CountryName,
        CurrencyCode,
        CurrencySymbol,
        ReferenceCurrency,
        ReferenceCurrencySymbol,
        DefaultExchangeRate,
        PricesIncludeTax,
        SpecialTaxRate,
        SpecialTaxEnabled,
        TaxAuthorityCode,
        FiscalIdName,
        TimeZoneIana,
        PhonePrefix,
        SortOrder,
        IsActive,
        CreatedAt,
        UpdatedAt
    FROM cfg.Country
    WHERE CountryCode = @CountryCode;
END;
GO

-- ============================================================
-- 3. Seed data: Actualizar existentes y agregar faltantes
-- ============================================================

-- Venezuela (ya existe, actualizar nuevas columnas)
IF EXISTS (SELECT 1 FROM cfg.Country WHERE CountryCode = 'VE')
BEGIN
    UPDATE cfg.Country
    SET CurrencySymbol         = N'Bs',
        ReferenceCurrency      = 'USD',
        ReferenceCurrencySymbol = N'$',
        DefaultExchangeRate    = 45.0,
        PricesIncludeTax       = 1,
        SpecialTaxRate         = 3,
        SpecialTaxEnabled      = 1,
        PhonePrefix            = N'+58',
        SortOrder              = 1,
        UpdatedAt              = SYSUTCDATETIME()
    WHERE CountryCode = 'VE';
END;
GO

-- España (ya existe, actualizar nuevas columnas)
IF EXISTS (SELECT 1 FROM cfg.Country WHERE CountryCode = 'ES')
BEGIN
    UPDATE cfg.Country
    SET CurrencySymbol         = N'€',
        ReferenceCurrency      = 'USD',
        ReferenceCurrencySymbol = N'$',
        DefaultExchangeRate    = 1.0,
        PricesIncludeTax       = 1,
        SpecialTaxRate         = 0,
        SpecialTaxEnabled      = 0,
        PhonePrefix            = N'+34',
        SortOrder              = 2,
        UpdatedAt              = SYSUTCDATETIME()
    WHERE CountryCode = 'ES';
END;
GO

-- Colombia (insertar si no existe)
IF NOT EXISTS (SELECT 1 FROM cfg.Country WHERE CountryCode = 'CO')
BEGIN
    INSERT INTO cfg.Country (
        CountryCode, CountryName, CurrencyCode, CurrencySymbol,
        ReferenceCurrency, ReferenceCurrencySymbol, DefaultExchangeRate,
        PricesIncludeTax, SpecialTaxRate, SpecialTaxEnabled,
        TaxAuthorityCode, FiscalIdName, TimeZoneIana, PhonePrefix,
        SortOrder, IsActive, CreatedAt, UpdatedAt
    )
    VALUES (
        'CO', N'Colombia', 'COP', N'$',
        'USD', N'$', 4000,
        0, 0, 0,
        N'DIAN', N'NIT', N'America/Bogota', N'+57',
        3, 1, SYSUTCDATETIME(), SYSUTCDATETIME()
    );
END;
GO

-- México (insertar si no existe)
IF NOT EXISTS (SELECT 1 FROM cfg.Country WHERE CountryCode = 'MX')
BEGIN
    INSERT INTO cfg.Country (
        CountryCode, CountryName, CurrencyCode, CurrencySymbol,
        ReferenceCurrency, ReferenceCurrencySymbol, DefaultExchangeRate,
        PricesIncludeTax, SpecialTaxRate, SpecialTaxEnabled,
        TaxAuthorityCode, FiscalIdName, TimeZoneIana, PhonePrefix,
        SortOrder, IsActive, CreatedAt, UpdatedAt
    )
    VALUES (
        'MX', N'México', 'MXN', N'$',
        'USD', N'$', 18.0,
        0, 0, 0,
        N'SAT', N'RFC', N'America/Mexico_City', N'+52',
        4, 1, SYSUTCDATETIME(), SYSUTCDATETIME()
    );
END;
GO

-- Estados Unidos (insertar si no existe)
IF NOT EXISTS (SELECT 1 FROM cfg.Country WHERE CountryCode = 'US')
BEGIN
    INSERT INTO cfg.Country (
        CountryCode, CountryName, CurrencyCode, CurrencySymbol,
        ReferenceCurrency, ReferenceCurrencySymbol, DefaultExchangeRate,
        PricesIncludeTax, SpecialTaxRate, SpecialTaxEnabled,
        TaxAuthorityCode, FiscalIdName, TimeZoneIana, PhonePrefix,
        SortOrder, IsActive, CreatedAt, UpdatedAt
    )
    VALUES (
        'US', N'Estados Unidos', 'USD', N'$',
        'EUR', N'€', 1.0,
        0, 0, 0,
        N'IRS', N'EIN', N'America/New_York', N'+1',
        5, 1, SYSUTCDATETIME(), SYSUTCDATETIME()
    );
END;
GO
