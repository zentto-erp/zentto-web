SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

USE DatqBoxWeb;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

BEGIN TRY
  BEGIN TRAN;

  IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'sec') EXEC('CREATE SCHEMA sec');
  IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'cfg') EXEC('CREATE SCHEMA cfg');
  IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'master') EXEC('CREATE SCHEMA [master]');
  IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'acct') EXEC('CREATE SCHEMA acct');
  IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'ar') EXEC('CREATE SCHEMA ar');
  IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'ap') EXEC('CREATE SCHEMA ap');
  IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'pos') EXEC('CREATE SCHEMA pos');
  IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'rest') EXEC('CREATE SCHEMA rest');
  IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'fiscal') EXEC('CREATE SCHEMA fiscal');
  IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'doc') EXEC('CREATE SCHEMA doc');

  IF OBJECT_ID('sec.[User]', 'U') IS NULL
  BEGIN
    CREATE TABLE sec.[User](
      UserId            INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      UserCode          NVARCHAR(40) NOT NULL,
      UserName          NVARCHAR(150) NOT NULL,
      PasswordHash      NVARCHAR(255) NULL,
      Email             NVARCHAR(150) NULL,
      IsAdmin           BIT NOT NULL CONSTRAINT DF_sec_User_IsAdmin DEFAULT(0),
      IsActive          BIT NOT NULL CONSTRAINT DF_sec_User_IsActive DEFAULT(1),
      LastLoginAt       DATETIME2(0) NULL,
      CreatedAt         DATETIME2(0) NOT NULL CONSTRAINT DF_sec_User_CreatedAt DEFAULT(SYSUTCDATETIME()),
      UpdatedAt         DATETIME2(0) NOT NULL CONSTRAINT DF_sec_User_UpdatedAt DEFAULT(SYSUTCDATETIME()),
      CreatedByUserId   INT NULL,
      UpdatedByUserId   INT NULL,
      IsDeleted         BIT NOT NULL CONSTRAINT DF_sec_User_IsDeleted DEFAULT(0),
      DeletedAt         DATETIME2(0) NULL,
      DeletedByUserId   INT NULL,
      RowVer            ROWVERSION NOT NULL,
      CONSTRAINT UQ_sec_User_UserCode UNIQUE (UserCode)
    );
  END;

  IF OBJECT_ID('sec.Role', 'U') IS NULL
  BEGIN
    CREATE TABLE sec.Role(
      RoleId            INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      RoleCode          NVARCHAR(40) NOT NULL,
      RoleName          NVARCHAR(120) NOT NULL,
      IsSystem          BIT NOT NULL CONSTRAINT DF_sec_Role_IsSystem DEFAULT(0),
      IsActive          BIT NOT NULL CONSTRAINT DF_sec_Role_IsActive DEFAULT(1),
      CreatedAt         DATETIME2(0) NOT NULL CONSTRAINT DF_sec_Role_CreatedAt DEFAULT(SYSUTCDATETIME()),
      UpdatedAt         DATETIME2(0) NOT NULL CONSTRAINT DF_sec_Role_UpdatedAt DEFAULT(SYSUTCDATETIME()),
      CONSTRAINT UQ_sec_Role_RoleCode UNIQUE (RoleCode)
    );
  END;

  IF OBJECT_ID('sec.UserRole', 'U') IS NULL
  BEGIN
    CREATE TABLE sec.UserRole(
      UserRoleId        BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      UserId            INT NOT NULL,
      RoleId            INT NOT NULL,
      CreatedAt         DATETIME2(0) NOT NULL CONSTRAINT DF_sec_UserRole_CreatedAt DEFAULT(SYSUTCDATETIME()),
      CONSTRAINT UQ_sec_UserRole UNIQUE (UserId, RoleId),
      CONSTRAINT FK_sec_UserRole_User FOREIGN KEY (UserId) REFERENCES sec.[User](UserId),
      CONSTRAINT FK_sec_UserRole_Role FOREIGN KEY (RoleId) REFERENCES sec.Role(RoleId)
    );
  END;

  IF OBJECT_ID('cfg.Country', 'U') IS NULL
  BEGIN
    CREATE TABLE cfg.Country(
      CountryCode       CHAR(2) NOT NULL PRIMARY KEY,
      CountryName       NVARCHAR(80) NOT NULL,
      CurrencyCode      CHAR(3) NOT NULL,
      TaxAuthorityCode  NVARCHAR(20) NOT NULL,
      FiscalIdName      NVARCHAR(20) NOT NULL,
      IsActive          BIT NOT NULL CONSTRAINT DF_cfg_Country_IsActive DEFAULT(1),
      CreatedAt         DATETIME2(0) NOT NULL CONSTRAINT DF_cfg_Country_CreatedAt DEFAULT(SYSUTCDATETIME()),
      UpdatedAt         DATETIME2(0) NOT NULL CONSTRAINT DF_cfg_Country_UpdatedAt DEFAULT(SYSUTCDATETIME())
    );
  END;

  IF OBJECT_ID('cfg.Company', 'U') IS NULL
  BEGIN
    CREATE TABLE cfg.Company(
      CompanyId         INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      CompanyCode       NVARCHAR(20) NOT NULL,
      LegalName         NVARCHAR(200) NOT NULL,
      TradeName         NVARCHAR(200) NULL,
      FiscalCountryCode CHAR(2) NOT NULL,
      FiscalId          NVARCHAR(30) NULL,
      BaseCurrency      CHAR(3) NOT NULL,
      IsActive          BIT NOT NULL CONSTRAINT DF_cfg_Company_IsActive DEFAULT(1),
      CreatedAt         DATETIME2(0) NOT NULL CONSTRAINT DF_cfg_Company_CreatedAt DEFAULT(SYSUTCDATETIME()),
      UpdatedAt         DATETIME2(0) NOT NULL CONSTRAINT DF_cfg_Company_UpdatedAt DEFAULT(SYSUTCDATETIME()),
      CreatedByUserId   INT NULL,
      UpdatedByUserId   INT NULL,
      IsDeleted         BIT NOT NULL CONSTRAINT DF_cfg_Company_IsDeleted DEFAULT(0),
      DeletedAt         DATETIME2(0) NULL,
      DeletedByUserId   INT NULL,
      RowVer            ROWVERSION NOT NULL,
      CONSTRAINT UQ_cfg_Company_CompanyCode UNIQUE (CompanyCode),
      CONSTRAINT FK_cfg_Company_Country FOREIGN KEY (FiscalCountryCode) REFERENCES cfg.Country(CountryCode),
      CONSTRAINT FK_cfg_Company_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
      CONSTRAINT FK_cfg_Company_UpdatedBy FOREIGN KEY (UpdatedByUserId) REFERENCES sec.[User](UserId)
    );
  END;

  IF OBJECT_ID('cfg.Branch', 'U') IS NULL
  BEGIN
    CREATE TABLE cfg.Branch(
      BranchId          INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      CompanyId         INT NOT NULL,
      BranchCode        NVARCHAR(20) NOT NULL,
      BranchName        NVARCHAR(150) NOT NULL,
      AddressLine       NVARCHAR(250) NULL,
      Phone             NVARCHAR(40) NULL,
      IsActive          BIT NOT NULL CONSTRAINT DF_cfg_Branch_IsActive DEFAULT(1),
      CreatedAt         DATETIME2(0) NOT NULL CONSTRAINT DF_cfg_Branch_CreatedAt DEFAULT(SYSUTCDATETIME()),
      UpdatedAt         DATETIME2(0) NOT NULL CONSTRAINT DF_cfg_Branch_UpdatedAt DEFAULT(SYSUTCDATETIME()),
      CreatedByUserId   INT NULL,
      UpdatedByUserId   INT NULL,
      IsDeleted         BIT NOT NULL CONSTRAINT DF_cfg_Branch_IsDeleted DEFAULT(0),
      DeletedAt         DATETIME2(0) NULL,
      DeletedByUserId   INT NULL,
      RowVer            ROWVERSION NOT NULL,
      CONSTRAINT UQ_cfg_Branch UNIQUE (CompanyId, BranchCode),
      CONSTRAINT FK_cfg_Branch_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId),
      CONSTRAINT FK_cfg_Branch_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
      CONSTRAINT FK_cfg_Branch_UpdatedBy FOREIGN KEY (UpdatedByUserId) REFERENCES sec.[User](UserId)
    );
  END;

  IF OBJECT_ID('cfg.ExchangeRateDaily', 'U') IS NULL
  BEGIN
    CREATE TABLE cfg.ExchangeRateDaily(
      ExchangeRateDailyId BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      CurrencyCode        CHAR(3) NOT NULL,
      RateToBase          DECIMAL(18,6) NOT NULL,
      RateDate            DATE NOT NULL,
      SourceName          NVARCHAR(120) NULL,
      CreatedAt           DATETIME2(0) NOT NULL CONSTRAINT DF_cfg_ExchangeRateDaily_CreatedAt DEFAULT(SYSUTCDATETIME()),
      CreatedByUserId     INT NULL,
      CONSTRAINT UQ_cfg_ExchangeRateDaily UNIQUE (CurrencyCode, RateDate),
      CONSTRAINT FK_cfg_ExchangeRateDaily_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId)
    );
  END;

  IF NOT EXISTS (SELECT 1 FROM cfg.Country WHERE CountryCode = 'VE')
    INSERT INTO cfg.Country (CountryCode, CountryName, CurrencyCode, TaxAuthorityCode, FiscalIdName)
    VALUES ('VE', N'Venezuela', 'VES', N'SENIAT', N'RIF');

  IF NOT EXISTS (SELECT 1 FROM cfg.Country WHERE CountryCode = 'ES')
    INSERT INTO cfg.Country (CountryCode, CountryName, CurrencyCode, TaxAuthorityCode, FiscalIdName)
    VALUES ('ES', N'Espana', 'EUR', N'AEAT', N'NIF');

  IF NOT EXISTS (SELECT 1 FROM sec.[User] WHERE UserCode = N'SYSTEM')
    INSERT INTO sec.[User] (UserCode, UserName, IsAdmin, IsActive) VALUES (N'SYSTEM', N'System User', 1, 1);

  IF NOT EXISTS (SELECT 1 FROM sec.Role WHERE RoleCode = N'ADMIN')
    INSERT INTO sec.Role (RoleCode, RoleName, IsSystem, IsActive) VALUES (N'ADMIN', N'Administrators', 1, 1);

  DECLARE @SystemUserId INT = (SELECT TOP 1 UserId FROM sec.[User] WHERE UserCode = N'SYSTEM');
  DECLARE @AdminRoleId INT = (SELECT TOP 1 RoleId FROM sec.Role WHERE RoleCode = N'ADMIN');

  IF @SystemUserId IS NOT NULL AND @AdminRoleId IS NOT NULL
     AND NOT EXISTS (SELECT 1 FROM sec.UserRole WHERE UserId = @SystemUserId AND RoleId = @AdminRoleId)
  BEGIN
    INSERT INTO sec.UserRole (UserId, RoleId) VALUES (@SystemUserId, @AdminRoleId);
  END;

  IF NOT EXISTS (SELECT 1 FROM cfg.Company WHERE CompanyCode = N'DEFAULT')
  BEGIN
    INSERT INTO cfg.Company (CompanyCode, LegalName, TradeName, FiscalCountryCode, FiscalId, BaseCurrency, CreatedByUserId, UpdatedByUserId)
    VALUES (N'DEFAULT', N'DatqBox Default Company', N'DatqBox', 'VE', N'J-00000000-0', 'VES', @SystemUserId, @SystemUserId);
  END;

  DECLARE @DefaultCompanyId INT = (SELECT TOP 1 CompanyId FROM cfg.Company WHERE CompanyCode = N'DEFAULT');

  IF @DefaultCompanyId IS NOT NULL
     AND NOT EXISTS (SELECT 1 FROM cfg.Branch WHERE CompanyId = @DefaultCompanyId AND BranchCode = N'MAIN')
  BEGIN
    INSERT INTO cfg.Branch (CompanyId, BranchCode, BranchName, CreatedByUserId, UpdatedByUserId)
    VALUES (@DefaultCompanyId, N'MAIN', N'Principal', @SystemUserId, @SystemUserId);
  END;

  COMMIT TRAN;
END TRY
BEGIN CATCH
  IF @@TRANCOUNT > 0 ROLLBACK TRAN;
  DECLARE @Err NVARCHAR(4000) = ERROR_MESSAGE();
  RAISERROR('Error 01_core_foundation.sql: %s', 16, 1, @Err);
END CATCH;
GO
