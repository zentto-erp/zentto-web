SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

USE DatqBoxWeb;
GO

/*
  Activos Fijos - Tablas canonicas (SQL Server 2012+)
  Esquema: acct
  ---------------------------------------------------
  Crea la estructura completa para gestion de activos fijos:
    1. acct.FixedAssetCategory      - Categorias de activos con vida util por pais
    2. acct.FixedAsset              - Registro maestro de activos fijos
    3. acct.FixedAssetDepreciation  - Lineas de depreciacion mensual
    4. acct.FixedAssetImprovement   - Mejoras / adiciones capitalizables
    5. acct.FixedAssetRevaluation   - Revaluaciones por indice (inflacion)
  Seed data: categorias para VE y ES
*/

BEGIN TRY
  BEGIN TRAN;

  -- ============================================================
  -- 0. Asegurar que el esquema acct existe
  -- ============================================================
  IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'acct')
  BEGIN
    EXEC('CREATE SCHEMA acct');
    PRINT '>> Esquema [acct] creado.';
  END

  -- ============================================================
  -- 1. acct.FixedAssetCategory
  --    Categorias maestras de activos fijos.
  --    Cada pais puede tener vida util distinta (VE vs ES).
  -- ============================================================
  IF OBJECT_ID('acct.FixedAssetCategory', 'U') IS NULL
  BEGIN
    CREATE TABLE acct.FixedAssetCategory (
      CategoryId                INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      CompanyId                 INT NOT NULL,
      CategoryCode              NVARCHAR(20) NOT NULL,
      CategoryName              NVARCHAR(200) NOT NULL,
      DefaultUsefulLifeMonths   INT NOT NULL,
      DefaultDepreciationMethod NVARCHAR(20) NOT NULL
        CONSTRAINT DF_FAC_DepMethod DEFAULT('STRAIGHT_LINE'),
        -- Valores: STRAIGHT_LINE, DOUBLE_DECLINING, UNITS_PRODUCED, NONE
      DefaultResidualPercent    DECIMAL(5,2)
        CONSTRAINT DF_FAC_ResidualPct DEFAULT(0),
      DefaultAssetAccountCode   NVARCHAR(20) NULL,
      DefaultDeprecAccountCode  NVARCHAR(20) NULL,
      DefaultExpenseAccountCode NVARCHAR(20) NULL,
      CountryCode               NVARCHAR(2) NULL,
      IsActive                  BIT CONSTRAINT DF_FAC_IsActive DEFAULT(1),
      IsDeleted                 BIT CONSTRAINT DF_FAC_IsDeleted DEFAULT(0),
      CreatedAt                 DATETIME CONSTRAINT DF_FAC_CreatedAt DEFAULT(SYSUTCDATETIME()),
      CONSTRAINT UQ_FixedAssetCategory UNIQUE (CompanyId, CategoryCode, CountryCode)
    );
    PRINT '>> Tabla [acct].[FixedAssetCategory] creada.';
  END
  ELSE
    PRINT '-- Tabla [acct].[FixedAssetCategory] ya existe, omitida.';

  -- ============================================================
  -- 2. acct.FixedAsset
  --    Registro maestro de cada activo fijo.
  --    Referencia cuentas contables y centro de costo.
  -- ============================================================
  IF OBJECT_ID('acct.FixedAsset', 'U') IS NULL
  BEGIN
    CREATE TABLE acct.FixedAsset (
      AssetId              BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      CompanyId            INT NOT NULL,
      BranchId             INT NOT NULL CONSTRAINT DF_FA_Branch DEFAULT(0),
      AssetCode            NVARCHAR(40) NOT NULL,
      Description          NVARCHAR(250) NOT NULL,
      CategoryId           INT NULL
        CONSTRAINT FK_FA_Category FOREIGN KEY REFERENCES acct.FixedAssetCategory(CategoryId),
      AcquisitionDate      DATE NOT NULL,
      AcquisitionCost      DECIMAL(18,2) NOT NULL,
      ResidualValue        DECIMAL(18,2) CONSTRAINT DF_FA_Residual DEFAULT(0),
      UsefulLifeMonths     INT NOT NULL,
      DepreciationMethod   NVARCHAR(20) NOT NULL
        CONSTRAINT DF_FA_DepMethod DEFAULT('STRAIGHT_LINE'),
      AssetAccountCode     NVARCHAR(20) NOT NULL,   -- ej: 1.2.01
      DeprecAccountCode    NVARCHAR(20) NOT NULL,   -- ej: 1.2.02
      ExpenseAccountCode   NVARCHAR(20) NOT NULL,   -- ej: 6.1.xx
      CostCenterCode       NVARCHAR(20) NULL,
      Location             NVARCHAR(200) NULL,
      SerialNumber         NVARCHAR(100) NULL,
      Status               NVARCHAR(20) CONSTRAINT DF_FA_Status DEFAULT('ACTIVE'),
        -- Valores: ACTIVE, DISPOSED, FULLY_DEPRECIATED, IMPAIRED
      DisposalDate         DATE NULL,
      DisposalAmount       DECIMAL(18,2) NULL,
      DisposalReason       NVARCHAR(500) NULL,
      DisposalEntryId      BIGINT NULL,
      AcquisitionEntryId   BIGINT NULL,
      UnitsCapacity        INT NULL,
      CurrencyCode         NVARCHAR(3) CONSTRAINT DF_FA_Currency DEFAULT('VES'),
      IsDeleted            BIT CONSTRAINT DF_FA_IsDeleted DEFAULT(0),
      CreatedAt            DATETIME CONSTRAINT DF_FA_CreatedAt DEFAULT(SYSUTCDATETIME()),
      UpdatedAt            DATETIME NULL,
      CreatedBy            NVARCHAR(40) NULL,
      UpdatedBy            NVARCHAR(40) NULL,
      CONSTRAINT UQ_FixedAsset_Code UNIQUE (CompanyId, AssetCode)
    );
    PRINT '>> Tabla [acct].[FixedAsset] creada.';
  END
  ELSE
    PRINT '-- Tabla [acct].[FixedAsset] ya existe, omitida.';

  -- ============================================================
  -- 3. acct.FixedAssetDepreciation
  --    Lineas de depreciacion mensual por activo.
  --    Cada registro corresponde a un periodo YYYY-MM.
  -- ============================================================
  IF OBJECT_ID('acct.FixedAssetDepreciation', 'U') IS NULL
  BEGIN
    CREATE TABLE acct.FixedAssetDepreciation (
      DepreciationId           BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      AssetId                  BIGINT NOT NULL
        CONSTRAINT FK_FAD_Asset FOREIGN KEY REFERENCES acct.FixedAsset(AssetId),
      PeriodCode               NVARCHAR(7) NOT NULL,   -- YYYY-MM
      DepreciationDate         DATE NOT NULL,
      Amount                   DECIMAL(18,2) NOT NULL,
      AccumulatedDepreciation  DECIMAL(18,2) NOT NULL,
      BookValue                DECIMAL(18,2) NOT NULL,
      JournalEntryId           BIGINT NULL,
      Status                   NVARCHAR(20) CONSTRAINT DF_FAD_Status DEFAULT('GENERATED'),
        -- Valores: GENERATED, POSTED, REVERSED
      CreatedAt                DATETIME CONSTRAINT DF_FAD_CreatedAt DEFAULT(SYSUTCDATETIME()),
      CONSTRAINT UQ_AssetDeprec UNIQUE (AssetId, PeriodCode)
    );
    PRINT '>> Tabla [acct].[FixedAssetDepreciation] creada.';
  END
  ELSE
    PRINT '-- Tabla [acct].[FixedAssetDepreciation] ya existe, omitida.';

  -- ============================================================
  -- 4. acct.FixedAssetImprovement
  --    Mejoras capitalizables que incrementan costo y/o vida util.
  -- ============================================================
  IF OBJECT_ID('acct.FixedAssetImprovement', 'U') IS NULL
  BEGIN
    CREATE TABLE acct.FixedAssetImprovement (
      ImprovementId        BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      AssetId              BIGINT NOT NULL
        CONSTRAINT FK_FAI_Asset FOREIGN KEY REFERENCES acct.FixedAsset(AssetId),
      ImprovementDate      DATE NOT NULL,
      Description          NVARCHAR(500) NOT NULL,
      Amount               DECIMAL(18,2) NOT NULL,
      AdditionalLifeMonths INT CONSTRAINT DF_FAI_AddLife DEFAULT(0),
      JournalEntryId       BIGINT NULL,
      CreatedBy            NVARCHAR(40) NULL,
      CreatedAt            DATETIME CONSTRAINT DF_FAI_CreatedAt DEFAULT(SYSUTCDATETIME())
    );
    PRINT '>> Tabla [acct].[FixedAssetImprovement] creada.';
  END
  ELSE
    PRINT '-- Tabla [acct].[FixedAssetImprovement] ya existe, omitida.';

  -- ============================================================
  -- 5. acct.FixedAssetRevaluation
  --    Revaluaciones por indice de precios (inflacion).
  --    Aplica principalmente en paises con alta inflacion (VE).
  -- ============================================================
  IF OBJECT_ID('acct.FixedAssetRevaluation', 'U') IS NULL
  BEGIN
    CREATE TABLE acct.FixedAssetRevaluation (
      RevaluationId        BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      AssetId              BIGINT NOT NULL
        CONSTRAINT FK_FAR_Asset FOREIGN KEY REFERENCES acct.FixedAsset(AssetId),
      RevaluationDate      DATE NOT NULL,
      PreviousCost         DECIMAL(18,2) NOT NULL,
      NewCost              DECIMAL(18,2) NOT NULL,
      PreviousAccumDeprec  DECIMAL(18,2) NOT NULL,
      NewAccumDeprec       DECIMAL(18,2) NOT NULL,
      IndexFactor          DECIMAL(12,6) NOT NULL,
      JournalEntryId       BIGINT NULL,
      CountryCode          NVARCHAR(2) NOT NULL,
      CreatedBy            NVARCHAR(40) NULL,
      CreatedAt            DATETIME CONSTRAINT DF_FAR_CreatedAt DEFAULT(SYSUTCDATETIME())
    );
    PRINT '>> Tabla [acct].[FixedAssetRevaluation] creada.';
  END
  ELSE
    PRINT '-- Tabla [acct].[FixedAssetRevaluation] ya existe, omitida.';

  -- ============================================================
  -- 6. Seed data: Categorias de activos fijos (VE y ES)
  -- ============================================================
  PRINT '>> Insertando categorias seed para VE y ES...';

  DECLARE @SeedCompanyId INT;
  SELECT TOP 1 @SeedCompanyId = CompanyId FROM acct.Account;
  IF @SeedCompanyId IS NULL SET @SeedCompanyId = 1;

  -- Venezuela (VE)
  IF NOT EXISTS (SELECT 1 FROM acct.FixedAssetCategory WHERE CompanyId = @SeedCompanyId AND CategoryCode = 'MOB' AND CountryCode = 'VE')
    INSERT INTO acct.FixedAssetCategory (CompanyId, CategoryCode, CategoryName, DefaultUsefulLifeMonths, DefaultDepreciationMethod, DefaultResidualPercent, DefaultAssetAccountCode, DefaultDeprecAccountCode, DefaultExpenseAccountCode, CountryCode)
    VALUES (@SeedCompanyId, 'MOB', N'Mobiliario y Enseres', 120, 'STRAIGHT_LINE', 0, '1.2.01', '1.2.02', '6.1.06', 'VE');

  IF NOT EXISTS (SELECT 1 FROM acct.FixedAssetCategory WHERE CompanyId = @SeedCompanyId AND CategoryCode = 'VEH' AND CountryCode = 'VE')
    INSERT INTO acct.FixedAssetCategory (CompanyId, CategoryCode, CategoryName, DefaultUsefulLifeMonths, DefaultDepreciationMethod, DefaultResidualPercent, DefaultAssetAccountCode, DefaultDeprecAccountCode, DefaultExpenseAccountCode, CountryCode)
    VALUES (@SeedCompanyId, 'VEH', N'Vehículos', 60, 'STRAIGHT_LINE', 0, '1.2.01', '1.2.02', '6.1.06', 'VE');

  IF NOT EXISTS (SELECT 1 FROM acct.FixedAssetCategory WHERE CompanyId = @SeedCompanyId AND CategoryCode = 'MAQ' AND CountryCode = 'VE')
    INSERT INTO acct.FixedAssetCategory (CompanyId, CategoryCode, CategoryName, DefaultUsefulLifeMonths, DefaultDepreciationMethod, DefaultResidualPercent, DefaultAssetAccountCode, DefaultDeprecAccountCode, DefaultExpenseAccountCode, CountryCode)
    VALUES (@SeedCompanyId, 'MAQ', N'Maquinaria y Equipos', 120, 'STRAIGHT_LINE', 0, '1.2.01', '1.2.02', '6.1.06', 'VE');

  IF NOT EXISTS (SELECT 1 FROM acct.FixedAssetCategory WHERE CompanyId = @SeedCompanyId AND CategoryCode = 'EDI' AND CountryCode = 'VE')
    INSERT INTO acct.FixedAssetCategory (CompanyId, CategoryCode, CategoryName, DefaultUsefulLifeMonths, DefaultDepreciationMethod, DefaultResidualPercent, DefaultAssetAccountCode, DefaultDeprecAccountCode, DefaultExpenseAccountCode, CountryCode)
    VALUES (@SeedCompanyId, 'EDI', N'Edificios y Construcciones', 240, 'STRAIGHT_LINE', 0, '1.2.01', '1.2.02', '6.1.06', 'VE');

  IF NOT EXISTS (SELECT 1 FROM acct.FixedAssetCategory WHERE CompanyId = @SeedCompanyId AND CategoryCode = 'TER' AND CountryCode = 'VE')
    INSERT INTO acct.FixedAssetCategory (CompanyId, CategoryCode, CategoryName, DefaultUsefulLifeMonths, DefaultDepreciationMethod, DefaultResidualPercent, DefaultAssetAccountCode, DefaultDeprecAccountCode, DefaultExpenseAccountCode, CountryCode)
    VALUES (@SeedCompanyId, 'TER', N'Terrenos', 0, 'NONE', 0, '1.2.01', NULL, NULL, 'VE');

  IF NOT EXISTS (SELECT 1 FROM acct.FixedAssetCategory WHERE CompanyId = @SeedCompanyId AND CategoryCode = 'EQU' AND CountryCode = 'VE')
    INSERT INTO acct.FixedAssetCategory (CompanyId, CategoryCode, CategoryName, DefaultUsefulLifeMonths, DefaultDepreciationMethod, DefaultResidualPercent, DefaultAssetAccountCode, DefaultDeprecAccountCode, DefaultExpenseAccountCode, CountryCode)
    VALUES (@SeedCompanyId, 'EQU', N'Equipos Informáticos', 36, 'STRAIGHT_LINE', 0, '1.2.01', '1.2.02', '6.1.06', 'VE');

  IF NOT EXISTS (SELECT 1 FROM acct.FixedAssetCategory WHERE CompanyId = @SeedCompanyId AND CategoryCode = 'INT' AND CountryCode = 'VE')
    INSERT INTO acct.FixedAssetCategory (CompanyId, CategoryCode, CategoryName, DefaultUsefulLifeMonths, DefaultDepreciationMethod, DefaultResidualPercent, DefaultAssetAccountCode, DefaultDeprecAccountCode, DefaultExpenseAccountCode, CountryCode)
    VALUES (@SeedCompanyId, 'INT', N'Intangibles y Software', 60, 'STRAIGHT_LINE', 0, '1.2.03', '1.2.03', '6.1.06', 'VE');

  IF NOT EXISTS (SELECT 1 FROM acct.FixedAssetCategory WHERE CompanyId = @SeedCompanyId AND CategoryCode = 'HER' AND CountryCode = 'VE')
    INSERT INTO acct.FixedAssetCategory (CompanyId, CategoryCode, CategoryName, DefaultUsefulLifeMonths, DefaultDepreciationMethod, DefaultResidualPercent, DefaultAssetAccountCode, DefaultDeprecAccountCode, DefaultExpenseAccountCode, CountryCode)
    VALUES (@SeedCompanyId, 'HER', N'Herramientas', 60, 'STRAIGHT_LINE', 0, '1.2.01', '1.2.02', '6.1.06', 'VE');

  PRINT '   VE: 8 categorias verificadas/insertadas.';

  -- Espana (ES)
  IF NOT EXISTS (SELECT 1 FROM acct.FixedAssetCategory WHERE CompanyId = @SeedCompanyId AND CategoryCode = 'MOB' AND CountryCode = 'ES')
    INSERT INTO acct.FixedAssetCategory (CompanyId, CategoryCode, CategoryName, DefaultUsefulLifeMonths, DefaultDepreciationMethod, DefaultResidualPercent, DefaultAssetAccountCode, DefaultDeprecAccountCode, DefaultExpenseAccountCode, CountryCode)
    VALUES (@SeedCompanyId, 'MOB', N'Mobiliario y Enseres', 120, 'STRAIGHT_LINE', 0, '1.2.01', '1.2.02', '6.1.06', 'ES');

  IF NOT EXISTS (SELECT 1 FROM acct.FixedAssetCategory WHERE CompanyId = @SeedCompanyId AND CategoryCode = 'VEH' AND CountryCode = 'ES')
    INSERT INTO acct.FixedAssetCategory (CompanyId, CategoryCode, CategoryName, DefaultUsefulLifeMonths, DefaultDepreciationMethod, DefaultResidualPercent, DefaultAssetAccountCode, DefaultDeprecAccountCode, DefaultExpenseAccountCode, CountryCode)
    VALUES (@SeedCompanyId, 'VEH', N'Vehículos', 72, 'STRAIGHT_LINE', 0, '1.2.01', '1.2.02', '6.1.06', 'ES');

  IF NOT EXISTS (SELECT 1 FROM acct.FixedAssetCategory WHERE CompanyId = @SeedCompanyId AND CategoryCode = 'MAQ' AND CountryCode = 'ES')
    INSERT INTO acct.FixedAssetCategory (CompanyId, CategoryCode, CategoryName, DefaultUsefulLifeMonths, DefaultDepreciationMethod, DefaultResidualPercent, DefaultAssetAccountCode, DefaultDeprecAccountCode, DefaultExpenseAccountCode, CountryCode)
    VALUES (@SeedCompanyId, 'MAQ', N'Maquinaria y Equipos', 144, 'STRAIGHT_LINE', 0, '1.2.01', '1.2.02', '6.1.06', 'ES');

  IF NOT EXISTS (SELECT 1 FROM acct.FixedAssetCategory WHERE CompanyId = @SeedCompanyId AND CategoryCode = 'EDI' AND CountryCode = 'ES')
    INSERT INTO acct.FixedAssetCategory (CompanyId, CategoryCode, CategoryName, DefaultUsefulLifeMonths, DefaultDepreciationMethod, DefaultResidualPercent, DefaultAssetAccountCode, DefaultDeprecAccountCode, DefaultExpenseAccountCode, CountryCode)
    VALUES (@SeedCompanyId, 'EDI', N'Edificios y Construcciones', 396, 'STRAIGHT_LINE', 0, '1.2.01', '1.2.02', '6.1.06', 'ES');

  IF NOT EXISTS (SELECT 1 FROM acct.FixedAssetCategory WHERE CompanyId = @SeedCompanyId AND CategoryCode = 'TER' AND CountryCode = 'ES')
    INSERT INTO acct.FixedAssetCategory (CompanyId, CategoryCode, CategoryName, DefaultUsefulLifeMonths, DefaultDepreciationMethod, DefaultResidualPercent, DefaultAssetAccountCode, DefaultDeprecAccountCode, DefaultExpenseAccountCode, CountryCode)
    VALUES (@SeedCompanyId, 'TER', N'Terrenos', 0, 'NONE', 0, '1.2.01', NULL, NULL, 'ES');

  IF NOT EXISTS (SELECT 1 FROM acct.FixedAssetCategory WHERE CompanyId = @SeedCompanyId AND CategoryCode = 'EQU' AND CountryCode = 'ES')
    INSERT INTO acct.FixedAssetCategory (CompanyId, CategoryCode, CategoryName, DefaultUsefulLifeMonths, DefaultDepreciationMethod, DefaultResidualPercent, DefaultAssetAccountCode, DefaultDeprecAccountCode, DefaultExpenseAccountCode, CountryCode)
    VALUES (@SeedCompanyId, 'EQU', N'Equipos Informáticos', 48, 'STRAIGHT_LINE', 0, '1.2.01', '1.2.02', '6.1.06', 'ES');

  IF NOT EXISTS (SELECT 1 FROM acct.FixedAssetCategory WHERE CompanyId = @SeedCompanyId AND CategoryCode = 'INT' AND CountryCode = 'ES')
    INSERT INTO acct.FixedAssetCategory (CompanyId, CategoryCode, CategoryName, DefaultUsefulLifeMonths, DefaultDepreciationMethod, DefaultResidualPercent, DefaultAssetAccountCode, DefaultDeprecAccountCode, DefaultExpenseAccountCode, CountryCode)
    VALUES (@SeedCompanyId, 'INT', N'Intangibles y Software', 60, 'STRAIGHT_LINE', 0, '1.2.03', '1.2.03', '6.1.06', 'ES');

  IF NOT EXISTS (SELECT 1 FROM acct.FixedAssetCategory WHERE CompanyId = @SeedCompanyId AND CategoryCode = 'HER' AND CountryCode = 'ES')
    INSERT INTO acct.FixedAssetCategory (CompanyId, CategoryCode, CategoryName, DefaultUsefulLifeMonths, DefaultDepreciationMethod, DefaultResidualPercent, DefaultAssetAccountCode, DefaultDeprecAccountCode, DefaultExpenseAccountCode, CountryCode)
    VALUES (@SeedCompanyId, 'HER', N'Herramientas', 96, 'STRAIGHT_LINE', 0, '1.2.01', '1.2.02', '6.1.06', 'ES');

  PRINT '   ES: 8 categorias verificadas/insertadas.';

  -- ============================================================
  COMMIT TRAN;
  PRINT '>> Activos fijos: script completado exitosamente.';

END TRY
BEGIN CATCH
  IF @@TRANCOUNT > 0 ROLLBACK TRAN;
  PRINT '!! ERROR en create_activos_fijos.sql:';
  PRINT '   Mensaje: ' + ERROR_MESSAGE();
  PRINT '   Linea:   ' + CAST(ERROR_LINE() AS NVARCHAR(10));
  THROW;
END CATCH
GO
