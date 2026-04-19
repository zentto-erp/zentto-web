-- ============================================================
-- zentto_dev — DDL canónico para SQL Server 2012
-- Generado automáticamente desde 00001_baseline.sql (PG)
-- Compatible con SQL Server 2012 (compat level 110)
-- Schemas renombrados: master→mstr, sys→zsys
-- ============================================================
USE zentto_dev;
GO

-- SCHEMAS
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'sec')
  EXEC('CREATE SCHEMA [sec]');
GO
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'cfg')
  EXEC('CREATE SCHEMA [cfg]');
GO
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'acct')
  EXEC('CREATE SCHEMA [acct]');
GO
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'ar')
  EXEC('CREATE SCHEMA [ar]');
GO
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'ap')
  EXEC('CREATE SCHEMA [ap]');
GO
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'pos')
  EXEC('CREATE SCHEMA [pos]');
GO
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'rest')
  EXEC('CREATE SCHEMA [rest]');
GO
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'fiscal')
  EXEC('CREATE SCHEMA [fiscal]');
GO
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'doc')
  EXEC('CREATE SCHEMA [doc]');
GO
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'fin')
  EXEC('CREATE SCHEMA [fin]');
GO
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'hr')
  EXEC('CREATE SCHEMA [hr]');
GO
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'pay')
  EXEC('CREATE SCHEMA [pay]');
GO
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'audit')
  EXEC('CREATE SCHEMA [audit]');
GO
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'store')
  EXEC('CREATE SCHEMA [store]');
GO
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'inv')
  EXEC('CREATE SCHEMA [inv]');
GO
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'logistics')
  EXEC('CREATE SCHEMA [logistics]');
GO
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'crm')
  EXEC('CREATE SCHEMA [crm]');
GO
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'mfg')
  EXEC('CREATE SCHEMA [mfg]');
GO
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'fleet')
  EXEC('CREATE SCHEMA [fleet]');
GO
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'zsys')
  EXEC('CREATE SCHEMA [zsys]');
GO
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'mstr')
  EXEC('CREATE SCHEMA [mstr]');
GO

IF OBJECT_ID('sec.User', 'U') IS NULL
CREATE TABLE sec.[User](
  UserId            INT IDENTITY(1,1) PRIMARY KEY,
  UserCode          NVARCHAR(40) NOT NULL,
  UserName          NVARCHAR(150) NOT NULL,
  PasswordHash      NVARCHAR(255),
  Email             NVARCHAR(150),
  IsAdmin           BIT NOT NULL DEFAULT 0,
  IsActive          BIT NOT NULL DEFAULT 1,
  LastLoginAt       DATETIME2(0),
  CreatedAt         DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
  UpdatedAt         DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
  CreatedByUserId   INT,
  UpdatedByUserId   INT,
  IsDeleted         BIT NOT NULL DEFAULT 0,
  DeletedAt         DATETIME2(0),
  DeletedByUserId   INT,
  RowVer            INT NOT NULL DEFAULT 1,
  UserType          NVARCHAR(10) DEFAULT 'USER',
  CanUpdate         BIT NOT NULL DEFAULT 1,
  CanCreate         BIT NOT NULL DEFAULT 1,
  CanDelete         BIT NOT NULL DEFAULT 0,
  IsCreator         BIT NOT NULL DEFAULT 0,
  CanChangePwd      BIT NOT NULL DEFAULT 1,
  CanChangePrice    BIT NOT NULL DEFAULT 0,
  CanGiveCredit     BIT NOT NULL DEFAULT 0,
  Avatar            NVARCHAR(MAX),
  CompanyId         INT DEFAULT 1,
  DisplayName       NVARCHAR(200),
  [Role]              NVARCHAR(30) DEFAULT 'admin',
  CONSTRAINT UQ_sec_User_UserCode UNIQUE (UserCode)
);
GO

IF OBJECT_ID('sec.Role', 'U') IS NULL
CREATE TABLE sec.[Role](
  RoleId            INT IDENTITY(1,1) PRIMARY KEY,
  RoleCode          NVARCHAR(40) NOT NULL,
  RoleName          NVARCHAR(120) NOT NULL,
  IsSystem          BIT NOT NULL DEFAULT 0,
  IsActive          BIT NOT NULL DEFAULT 1,
  CreatedAt         DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
  UpdatedAt         DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
  CONSTRAINT UQ_sec_Role_RoleCode UNIQUE (RoleCode)
);
GO

IF OBJECT_ID('sec.UserRole', 'U') IS NULL
CREATE TABLE sec.UserRole(
  UserRoleId        BIGINT IDENTITY(1,1) PRIMARY KEY,
  UserId            INT NOT NULL,
  RoleId            INT NOT NULL,
  CreatedAt         DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
  CONSTRAINT UQ_sec_UserRole UNIQUE (UserId, RoleId),
  CONSTRAINT FK_sec_UserRole_User FOREIGN KEY (UserId) REFERENCES sec.[User](UserId),
  CONSTRAINT FK_sec_UserRole_Role FOREIGN KEY (RoleId) REFERENCES sec.[Role](RoleId)
);
GO

IF OBJECT_ID('cfg.Country', 'U') IS NULL
CREATE TABLE cfg.Country(
  CountryCode       NCHAR(2) NOT NULL PRIMARY KEY,
  CountryName       NVARCHAR(80) NOT NULL,
  CurrencyCode      NCHAR(3) NOT NULL,
  TaxAuthorityCode  NVARCHAR(20) NOT NULL,
  FiscalIdName      NVARCHAR(20) NOT NULL,
  TimeZoneIana      NVARCHAR(50) NULL,
  CurrencySymbol    NVARCHAR(10) NULL,
  DecimalSeparator  NCHAR(1) DEFAULT '.',
  ThousandsSeparator NCHAR(1) DEFAULT ',',
  IsActive          BIT NOT NULL DEFAULT 1,
  CreatedAt         DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
  UpdatedAt         DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME()
);
GO

IF OBJECT_ID('cfg.Company', 'U') IS NULL
CREATE TABLE cfg.Company(
  CompanyId         INT IDENTITY(1,1) PRIMARY KEY,
  CompanyCode       NVARCHAR(20) NOT NULL,
  LegalName         NVARCHAR(200) NOT NULL,
  TradeName         NVARCHAR(200),
  FiscalCountryCode NCHAR(2) NOT NULL,
  FiscalId          NVARCHAR(30),
  BaseCurrency      NCHAR(3) NOT NULL,
  Address           NVARCHAR(500) NULL,
  LegalRep          NVARCHAR(200) NULL,
  Phone             NVARCHAR(50) NULL,
  IsActive          BIT NOT NULL DEFAULT 1,
  CreatedAt         DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
  UpdatedAt         DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
  CreatedByUserId   INT,
  UpdatedByUserId   INT,
  IsDeleted         BIT NOT NULL DEFAULT 0,
  DeletedAt         DATETIME2(0),
  DeletedByUserId   INT,
  RowVer            INT NOT NULL DEFAULT 1,
  CONSTRAINT UQ_cfg_Company_CompanyCode UNIQUE (CompanyCode),
  CONSTRAINT FK_cfg_Company_Country FOREIGN KEY (FiscalCountryCode) REFERENCES cfg.Country(CountryCode),
  CONSTRAINT FK_cfg_Company_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
  CONSTRAINT FK_cfg_Company_UpdatedBy FOREIGN KEY (UpdatedByUserId) REFERENCES sec.[User](UserId)
);
GO

IF OBJECT_ID('cfg.Branch', 'U') IS NULL
CREATE TABLE cfg.Branch(
  BranchId          INT IDENTITY(1,1) PRIMARY KEY,
  CompanyId         INT NOT NULL,
  BranchCode        NVARCHAR(20) NOT NULL,
  BranchName        NVARCHAR(150) NOT NULL,
  AddressLine       NVARCHAR(250),
  Phone             NVARCHAR(40),
  CountryCode       NVARCHAR(5) NULL,
  CurrencyCode      NVARCHAR(5) NULL,
  IsActive          BIT NOT NULL DEFAULT 1,
  CreatedAt         DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
  UpdatedAt         DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
  CreatedByUserId   INT,
  UpdatedByUserId   INT,
  IsDeleted         BIT NOT NULL DEFAULT 0,
  DeletedAt         DATETIME2(0),
  DeletedByUserId   INT,
  RowVer            INT NOT NULL DEFAULT 1,
  CONSTRAINT UQ_cfg_Branch UNIQUE (CompanyId, BranchCode),
  CONSTRAINT FK_cfg_Branch_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId),
  CONSTRAINT FK_cfg_Branch_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
  CONSTRAINT FK_cfg_Branch_UpdatedBy FOREIGN KEY (UpdatedByUserId) REFERENCES sec.[User](UserId)
);
GO

IF OBJECT_ID('cfg.ExchangeRateDaily', 'U') IS NULL
CREATE TABLE cfg.ExchangeRateDaily(
  ExchangeRateDailyId BIGINT IDENTITY(1,1) PRIMARY KEY,
  CurrencyCode        NCHAR(3) NOT NULL,
  RateToBase          DECIMAL(18,6) NOT NULL,
  RateDate            DATE NOT NULL,
  SourceName          NVARCHAR(120),
  CreatedAt           DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
  CreatedByUserId     INT,
  CONSTRAINT UQ_cfg_ExchangeRateDaily UNIQUE (CurrencyCode, RateDate),
  CONSTRAINT FK_cfg_ExchangeRateDaily_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId)
);
GO

IF OBJECT_ID('mstr.Customer', 'U') IS NULL
CREATE TABLE mstr.Customer (
  CustomerId           BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
  CompanyId            INT NOT NULL,
  CustomerCode         NVARCHAR(24) NOT NULL,
  CustomerName         NVARCHAR(200) NOT NULL,
  FiscalId             NVARCHAR(30) NULL,
  Email                NVARCHAR(150) NULL,
  Phone                NVARCHAR(40) NULL,
  AddressLine          NVARCHAR(250) NULL,
  CreditLimit          DECIMAL(18,2) NOT NULL CONSTRAINT DF_master_Customer_CreditLimit DEFAULT 0,
  TotalBalance         DECIMAL(18,2) NOT NULL CONSTRAINT DF_master_Customer_TotalBalance DEFAULT 0,
  IsActive             BIT NOT NULL CONSTRAINT DF_master_Customer_IsActive DEFAULT 1,
  CreatedAt            DATETIME2(0) NOT NULL CONSTRAINT DF_master_Customer_CreatedAt DEFAULT SYSUTCDATETIME(),
  UpdatedAt            DATETIME2(0) NOT NULL CONSTRAINT DF_master_Customer_UpdatedAt DEFAULT SYSUTCDATETIME(),
  CreatedByUserId      INT NULL,
  UpdatedByUserId      INT NULL,
  IsDeleted            BIT NOT NULL CONSTRAINT DF_master_Customer_IsDeleted DEFAULT 0,
  DeletedAt            DATETIME2(0) NULL,
  DeletedByUserId      INT NULL,
  RowVer               INT NOT NULL DEFAULT 1,
  CONSTRAINT UQ_master_Customer UNIQUE (CompanyId, CustomerCode),
  CONSTRAINT FK_master_Customer_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId),
  CONSTRAINT FK_master_Customer_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
  CONSTRAINT FK_master_Customer_UpdatedBy FOREIGN KEY (UpdatedByUserId) REFERENCES sec.[User](UserId)
);
GO

IF OBJECT_ID('mstr.Supplier', 'U') IS NULL
CREATE TABLE mstr.Supplier (
  SupplierId           BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
  CompanyId            INT NOT NULL,
  SupplierCode         NVARCHAR(24) NOT NULL,
  SupplierName         NVARCHAR(200) NOT NULL,
  FiscalId             NVARCHAR(30) NULL,
  Email                NVARCHAR(150) NULL,
  Phone                NVARCHAR(40) NULL,
  AddressLine          NVARCHAR(250) NULL,
  CreditLimit          DECIMAL(18,2) NOT NULL CONSTRAINT DF_master_Supplier_CreditLimit DEFAULT 0,
  TotalBalance         DECIMAL(18,2) NOT NULL CONSTRAINT DF_master_Supplier_TotalBalance DEFAULT 0,
  IsActive             BIT NOT NULL CONSTRAINT DF_master_Supplier_IsActive DEFAULT 1,
  CreatedAt            DATETIME2(0) NOT NULL CONSTRAINT DF_master_Supplier_CreatedAt DEFAULT SYSUTCDATETIME(),
  UpdatedAt            DATETIME2(0) NOT NULL CONSTRAINT DF_master_Supplier_UpdatedAt DEFAULT SYSUTCDATETIME(),
  CreatedByUserId      INT NULL,
  UpdatedByUserId      INT NULL,
  IsDeleted            BIT NOT NULL CONSTRAINT DF_master_Supplier_IsDeleted DEFAULT 0,
  DeletedAt            DATETIME2(0) NULL,
  DeletedByUserId      INT NULL,
  RowVer               INT NOT NULL DEFAULT 1,
  CONSTRAINT UQ_master_Supplier UNIQUE (CompanyId, SupplierCode),
  CONSTRAINT FK_master_Supplier_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId),
  CONSTRAINT FK_master_Supplier_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
  CONSTRAINT FK_master_Supplier_UpdatedBy FOREIGN KEY (UpdatedByUserId) REFERENCES sec.[User](UserId)
);
GO

IF OBJECT_ID('mstr.Employee', 'U') IS NULL
CREATE TABLE mstr.Employee (
  EmployeeId           BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
  CompanyId            INT NOT NULL,
  EmployeeCode         NVARCHAR(24) NOT NULL,
  EmployeeName         NVARCHAR(200) NOT NULL,
  FiscalId             NVARCHAR(30) NULL,
  HireDate             DATE NULL,
  TerminationDate      DATE NULL,
  PositionName         NVARCHAR(150) NULL,
  DepartmentName       NVARCHAR(150) NULL,
  Salary               DECIMAL(18,2) NULL,
  IsActive             BIT NOT NULL CONSTRAINT DF_master_Employee_IsActive DEFAULT 1,
  CreatedAt            DATETIME2(0) NOT NULL CONSTRAINT DF_master_Employee_CreatedAt DEFAULT SYSUTCDATETIME(),
  UpdatedAt            DATETIME2(0) NOT NULL CONSTRAINT DF_master_Employee_UpdatedAt DEFAULT SYSUTCDATETIME(),
  CreatedByUserId      INT NULL,
  UpdatedByUserId      INT NULL,
  IsDeleted            BIT NOT NULL CONSTRAINT DF_master_Employee_IsDeleted DEFAULT 0,
  DeletedAt            DATETIME2(0) NULL,
  DeletedByUserId      INT NULL,
  RowVer               INT NOT NULL DEFAULT 1,
  CONSTRAINT UQ_master_Employee UNIQUE (CompanyId, EmployeeCode),
  CONSTRAINT FK_master_Employee_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId),
  CONSTRAINT FK_master_Employee_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
  CONSTRAINT FK_master_Employee_UpdatedBy FOREIGN KEY (UpdatedByUserId) REFERENCES sec.[User](UserId)
);
GO

IF OBJECT_ID('mstr.Product', 'U') IS NULL
CREATE TABLE mstr.Product (
  ProductId            BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
  CompanyId            INT NOT NULL,
  ProductCode          NVARCHAR(80) NOT NULL,
  ProductName          NVARCHAR(250) NOT NULL,
  CategoryCode         NVARCHAR(50) NULL,
  UnitCode             NVARCHAR(20) NULL,
  SalesPrice           DECIMAL(18,2) NOT NULL CONSTRAINT DF_master_Product_SalesPrice DEFAULT 0,
  CostPrice            DECIMAL(18,2) NOT NULL CONSTRAINT DF_master_Product_CostPrice DEFAULT 0,
  DefaultTaxCode       NVARCHAR(30) NULL,
  DefaultTaxRate       DECIMAL(9,4) NOT NULL CONSTRAINT DF_master_Product_DefaultTaxRate DEFAULT 0,
  StockQty             DECIMAL(18,3) NOT NULL CONSTRAINT DF_master_Product_StockQty DEFAULT 0,
  IsService            BIT NOT NULL CONSTRAINT DF_master_Product_IsService DEFAULT 0,
  IsActive             BIT NOT NULL CONSTRAINT DF_master_Product_IsActive DEFAULT 1,
  CreatedAt            DATETIME2(0) NOT NULL CONSTRAINT DF_master_Product_CreatedAt DEFAULT SYSUTCDATETIME(),
  UpdatedAt            DATETIME2(0) NOT NULL CONSTRAINT DF_master_Product_UpdatedAt DEFAULT SYSUTCDATETIME(),
  CreatedByUserId      INT NULL,
  UpdatedByUserId      INT NULL,
  IsDeleted            BIT NOT NULL CONSTRAINT DF_master_Product_IsDeleted DEFAULT 0,
  DeletedAt            DATETIME2(0) NULL,
  DeletedByUserId      INT NULL,
  RowVer               INT NOT NULL DEFAULT 1,
  -- Columnas ecommerce
  ShortDescription     NVARCHAR(500) NULL,
  LongDescription      NVARCHAR(MAX) NULL,
  CompareAtPrice       DECIMAL(18,4) NULL,
  BrandCode            NVARCHAR(20) NULL,
  BarCode              NVARCHAR(50) NULL,
  Slug                 NVARCHAR(200) NULL,
  WeightKg             DECIMAL(10,3) NULL,
  WidthCm              DECIMAL(10,2) NULL,
  HeightCm             DECIMAL(10,2) NULL,
  DepthCm              DECIMAL(10,2) NULL,
  WarrantyMonths       INT NULL,
  IsVariantParent      BIT NOT NULL DEFAULT 0,
  ParentProductCode    NVARCHAR(80) NULL,
  IndustryTemplateCode NVARCHAR(30) NULL,
  CONSTRAINT UQ_master_Product UNIQUE (CompanyId, ProductCode),
  CONSTRAINT FK_master_Product_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId),
  CONSTRAINT FK_master_Product_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
  CONSTRAINT FK_master_Product_UpdatedBy FOREIGN KEY (UpdatedByUserId) REFERENCES sec.[User](UserId)
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_master_Product_Company_IsActive')
  CREATE INDEX IX_master_Product_Company_IsActive ON mstr.Product (CompanyId, IsActive, ProductCode);
GO

IF OBJECT_ID('acct.Account', 'U') IS NULL
CREATE TABLE acct.Account (
  AccountId             BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
  CompanyId             INT NOT NULL,
  AccountCode           NVARCHAR(40) NOT NULL,
  AccountName           NVARCHAR(200) NOT NULL,
  AccountType           NCHAR(1) NOT NULL, -- A,P,C,I,G
  AccountLevel          INT NOT NULL CONSTRAINT DF_acct_Account_Level DEFAULT 1,
  ParentAccountId       BIGINT NULL,
  AllowsPosting         BIT NOT NULL CONSTRAINT DF_acct_Account_AllowsPosting DEFAULT 1,
  RequiresAuxiliary     BIT NOT NULL CONSTRAINT DF_acct_Account_RequiresAux DEFAULT 0,
  IsActive              BIT NOT NULL CONSTRAINT DF_acct_Account_IsActive DEFAULT 1,
  CreatedAt             DATETIME2(0) NOT NULL CONSTRAINT DF_acct_Account_CreatedAt DEFAULT SYSUTCDATETIME(),
  UpdatedAt             DATETIME2(0) NOT NULL CONSTRAINT DF_acct_Account_UpdatedAt DEFAULT SYSUTCDATETIME(),
  CreatedByUserId       INT NULL,
  UpdatedByUserId       INT NULL,
  IsDeleted             BIT NOT NULL CONSTRAINT DF_acct_Account_IsDeleted DEFAULT 0,
  DeletedAt             DATETIME2(0) NULL,
  DeletedByUserId       INT NULL,
  RowVer                INT NOT NULL DEFAULT 1,
  CONSTRAINT CK_acct_Account_AccountType CHECK (AccountType IN ('A', 'P', 'C', 'I', 'G')),
  CONSTRAINT UQ_acct_Account UNIQUE (CompanyId, AccountCode),
  CONSTRAINT FK_acct_Account_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId),
  CONSTRAINT FK_acct_Account_Parent FOREIGN KEY (ParentAccountId) REFERENCES acct.Account(AccountId),
  CONSTRAINT FK_acct_Account_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
  CONSTRAINT FK_acct_Account_UpdatedBy FOREIGN KEY (UpdatedByUserId) REFERENCES sec.[User](UserId)
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_acct_Account_Company_Parent')
  CREATE INDEX IX_acct_Account_Company_Parent ON acct.Account (CompanyId, ParentAccountId, AccountCode);
GO

IF OBJECT_ID('acct.JournalEntry', 'U') IS NULL
CREATE TABLE acct.JournalEntry (
  JournalEntryId        BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
  CompanyId             INT NOT NULL,
  BranchId              INT NOT NULL,
  EntryNumber           NVARCHAR(40) NOT NULL,
  EntryDate             DATE NOT NULL,
  PeriodCode            NVARCHAR(7) NOT NULL,
  EntryType             NVARCHAR(20) NOT NULL,
  ReferenceNumber       NVARCHAR(120) NULL,
  Concept               NVARCHAR(400) NOT NULL,
  CurrencyCode          NCHAR(3) NOT NULL,
  ExchangeRate          DECIMAL(18,6) NOT NULL CONSTRAINT DF_acct_JE_ExRate DEFAULT 1,
  TotalDebit            DECIMAL(18,2) NOT NULL CONSTRAINT DF_acct_JE_Debit DEFAULT 0,
  TotalCredit           DECIMAL(18,2) NOT NULL CONSTRAINT DF_acct_JE_Credit DEFAULT 0,
  [Status]                NVARCHAR(20) NOT NULL CONSTRAINT DF_acct_JE_Status DEFAULT 'APPROVED',
  SourceModule          NVARCHAR(40) NULL,
  SourceDocumentType    NVARCHAR(40) NULL,
  SourceDocumentNo      NVARCHAR(120) NULL,
  CreatedAt             DATETIME2(0) NOT NULL CONSTRAINT DF_acct_JE_CreatedAt DEFAULT SYSUTCDATETIME(),
  UpdatedAt             DATETIME2(0) NOT NULL CONSTRAINT DF_acct_JE_UpdatedAt DEFAULT SYSUTCDATETIME(),
  CreatedByUserId       INT NULL,
  UpdatedByUserId       INT NULL,
  IsDeleted             BIT NOT NULL CONSTRAINT DF_acct_JE_IsDeleted DEFAULT 0,
  DeletedAt             DATETIME2(0) NULL,
  DeletedByUserId       INT NULL,
  RowVer                INT NOT NULL DEFAULT 1,
  CONSTRAINT CK_acct_JE_Status CHECK ([Status] IN ('DRAFT','APPROVED','VOIDED')),
  CONSTRAINT UQ_acct_JE UNIQUE (CompanyId, BranchId, EntryNumber),
  CONSTRAINT FK_acct_JE_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId),
  CONSTRAINT FK_acct_JE_Branch FOREIGN KEY (BranchId) REFERENCES cfg.Branch(BranchId),
  CONSTRAINT FK_acct_JE_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
  CONSTRAINT FK_acct_JE_UpdatedBy FOREIGN KEY (UpdatedByUserId) REFERENCES sec.[User](UserId)
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_acct_JE_Date')
  CREATE INDEX IX_acct_JE_Date ON acct.JournalEntry (CompanyId, BranchId, EntryDate, JournalEntryId);
GO

IF OBJECT_ID('acct.JournalEntryLine', 'U') IS NULL
CREATE TABLE acct.JournalEntryLine (
  JournalEntryLineId    BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
  JournalEntryId        BIGINT NOT NULL,
  LineNumber            INT NOT NULL,
  AccountId             BIGINT NOT NULL,
  AccountCodeSnapshot   NVARCHAR(40) NOT NULL,
  Description           NVARCHAR(400) NULL,
  DebitAmount           DECIMAL(18,2) NOT NULL CONSTRAINT DF_acct_JEL_Debit DEFAULT 0,
  CreditAmount          DECIMAL(18,2) NOT NULL CONSTRAINT DF_acct_JEL_Credit DEFAULT 0,
  AuxiliaryType         NVARCHAR(20) NULL,
  AuxiliaryCode         NVARCHAR(80) NULL,
  CostCenterCode        NVARCHAR(20) NULL,
  SourceDocumentNo      NVARCHAR(120) NULL,
  CreatedAt             DATETIME2(0) NOT NULL CONSTRAINT DF_acct_JEL_CreatedAt DEFAULT SYSUTCDATETIME(),
  UpdatedAt             DATETIME2(0) NOT NULL CONSTRAINT DF_acct_JEL_UpdatedAt DEFAULT SYSUTCDATETIME(),
  RowVer                INT NOT NULL DEFAULT 1,
  CONSTRAINT UQ_acct_JEL UNIQUE (JournalEntryId, LineNumber),
  CONSTRAINT CK_acct_JEL_DebitCredit CHECK (
    (DebitAmount >= 0 AND CreditAmount >= 0)
    AND NOT (DebitAmount > 0 AND CreditAmount > 0)
  ),
  CONSTRAINT FK_acct_JEL_JE FOREIGN KEY (JournalEntryId) REFERENCES acct.JournalEntry(JournalEntryId),
  CONSTRAINT FK_acct_JEL_Account FOREIGN KEY (AccountId) REFERENCES acct.Account(AccountId)
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_acct_JEL_Account')
  CREATE INDEX IX_acct_JEL_Account ON acct.JournalEntryLine (AccountId, JournalEntryId);
GO

IF OBJECT_ID('acct.DocumentLink', 'U') IS NULL
CREATE TABLE acct.DocumentLink (
  DocumentLinkId        BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
  CompanyId             INT NOT NULL,
  BranchId              INT NOT NULL,
  ModuleCode            NVARCHAR(20) NOT NULL,
  DocumentType          NVARCHAR(20) NOT NULL,
  DocumentNumber        NVARCHAR(120) NOT NULL,
  NativeDocumentId      BIGINT NULL,
  JournalEntryId        BIGINT NOT NULL,
  CreatedAt             DATETIME2(0) NOT NULL CONSTRAINT DF_acct_DocLink_CreatedAt DEFAULT SYSUTCDATETIME(),
  CONSTRAINT UQ_acct_DocLink UNIQUE (CompanyId, BranchId, ModuleCode, DocumentType, DocumentNumber),
  CONSTRAINT FK_acct_DocLink_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId),
  CONSTRAINT FK_acct_DocLink_Branch FOREIGN KEY (BranchId) REFERENCES cfg.Branch(BranchId),
  CONSTRAINT FK_acct_DocLink_JE FOREIGN KEY (JournalEntryId) REFERENCES acct.JournalEntry(JournalEntryId)
);
GO

IF OBJECT_ID('acct.AccountingPolicy', 'U') IS NULL
CREATE TABLE acct.AccountingPolicy (
  AccountingPolicyId    BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
  CompanyId             INT NOT NULL,
  ModuleCode            NVARCHAR(20) NOT NULL,
  ProcessCode           NVARCHAR(40) NOT NULL,
  Nature                NVARCHAR(10) NOT NULL,
  AccountId             BIGINT NOT NULL,
  PriorityOrder         INT NOT NULL CONSTRAINT DF_acct_Policy_Priority DEFAULT 1,
  IsActive              BIT NOT NULL CONSTRAINT DF_acct_Policy_IsActive DEFAULT 1,
  CreatedAt             DATETIME2(0) NOT NULL CONSTRAINT DF_acct_Policy_CreatedAt DEFAULT SYSUTCDATETIME(),
  UpdatedAt             DATETIME2(0) NOT NULL CONSTRAINT DF_acct_Policy_UpdatedAt DEFAULT SYSUTCDATETIME(),
  CONSTRAINT CK_acct_Policy_Nature CHECK (Nature IN ('DEBIT','CREDIT')),
  CONSTRAINT UQ_acct_Policy UNIQUE (CompanyId, ModuleCode, ProcessCode, Nature, AccountId),
  CONSTRAINT FK_acct_Policy_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId),
  CONSTRAINT FK_acct_Policy_Account FOREIGN KEY (AccountId) REFERENCES acct.Account(AccountId)
);
GO

IF OBJECT_ID('ar.ReceivableDocument', 'U') IS NULL
CREATE TABLE ar.ReceivableDocument (
  ReceivableDocumentId   BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
  CompanyId              INT NOT NULL,
  BranchId               INT NOT NULL,
  CustomerId             BIGINT NOT NULL,
  DocumentType           NVARCHAR(20) NOT NULL,
  DocumentNumber         NVARCHAR(120) NOT NULL,
  IssueDate              DATE NOT NULL,
  DueDate                DATE NULL,
  CurrencyCode           NCHAR(3) NOT NULL,
  TotalAmount            DECIMAL(18,2) NOT NULL,
  PendingAmount          DECIMAL(18,2) NOT NULL,
  PaidFlag               BIT NOT NULL CONSTRAINT DF_ar_RecDoc_PaidFlag DEFAULT 0,
  [Status]                 NVARCHAR(20) NOT NULL CONSTRAINT DF_ar_RecDoc_Status DEFAULT 'PENDING',
  Notes                  NVARCHAR(500) NULL,
  CreatedAt              DATETIME2(0) NOT NULL CONSTRAINT DF_ar_RecDoc_CreatedAt DEFAULT SYSUTCDATETIME(),
  UpdatedAt              DATETIME2(0) NOT NULL CONSTRAINT DF_ar_RecDoc_UpdatedAt DEFAULT SYSUTCDATETIME(),
  CreatedByUserId        INT NULL,
  UpdatedByUserId        INT NULL,
  RowVer                 INT NOT NULL DEFAULT 1,
  CONSTRAINT CK_ar_RecDoc_Status CHECK ([Status] IN ('PENDING','PARTIAL','PAID','VOIDED')),
  CONSTRAINT UQ_ar_RecDoc UNIQUE (CompanyId, BranchId, DocumentType, DocumentNumber),
  CONSTRAINT FK_ar_RecDoc_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId),
  CONSTRAINT FK_ar_RecDoc_Branch FOREIGN KEY (BranchId) REFERENCES cfg.Branch(BranchId),
  CONSTRAINT FK_ar_RecDoc_Customer FOREIGN KEY (CustomerId) REFERENCES mstr.Customer(CustomerId),
  CONSTRAINT FK_ar_RecDoc_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
  CONSTRAINT FK_ar_RecDoc_UpdatedBy FOREIGN KEY (UpdatedByUserId) REFERENCES sec.[User](UserId)
);
GO

IF OBJECT_ID('ar.ReceivableApplication', 'U') IS NULL
CREATE TABLE ar.ReceivableApplication (
  ReceivableApplicationId BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
  ReceivableDocumentId    BIGINT NOT NULL,
  ApplyDate               DATE NOT NULL,
  AppliedAmount           DECIMAL(18,2) NOT NULL,
  PaymentReference        NVARCHAR(120) NULL,
  CreatedAt               DATETIME2(0) NOT NULL CONSTRAINT DF_ar_RecApp_CreatedAt DEFAULT SYSUTCDATETIME(),
  CONSTRAINT FK_ar_RecApp_Doc FOREIGN KEY (ReceivableDocumentId) REFERENCES ar.ReceivableDocument(ReceivableDocumentId)
);
GO

IF OBJECT_ID('ap.PayableDocument', 'U') IS NULL
CREATE TABLE ap.PayableDocument (
  PayableDocumentId      BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
  CompanyId              INT NOT NULL,
  BranchId               INT NOT NULL,
  SupplierId             BIGINT NOT NULL,
  DocumentType           NVARCHAR(20) NOT NULL,
  DocumentNumber         NVARCHAR(120) NOT NULL,
  IssueDate              DATE NOT NULL,
  DueDate                DATE NULL,
  CurrencyCode           NCHAR(3) NOT NULL,
  TotalAmount            DECIMAL(18,2) NOT NULL,
  PendingAmount          DECIMAL(18,2) NOT NULL,
  PaidFlag               BIT NOT NULL CONSTRAINT DF_ap_PayDoc_PaidFlag DEFAULT 0,
  [Status]                 NVARCHAR(20) NOT NULL CONSTRAINT DF_ap_PayDoc_Status DEFAULT 'PENDING',
  Notes                  NVARCHAR(500) NULL,
  CreatedAt              DATETIME2(0) NOT NULL CONSTRAINT DF_ap_PayDoc_CreatedAt DEFAULT SYSUTCDATETIME(),
  UpdatedAt              DATETIME2(0) NOT NULL CONSTRAINT DF_ap_PayDoc_UpdatedAt DEFAULT SYSUTCDATETIME(),
  CreatedByUserId        INT NULL,
  UpdatedByUserId        INT NULL,
  RowVer                 INT NOT NULL DEFAULT 1,
  CONSTRAINT CK_ap_PayDoc_Status CHECK ([Status] IN ('PENDING','PARTIAL','PAID','VOIDED')),
  CONSTRAINT UQ_ap_PayDoc UNIQUE (CompanyId, BranchId, DocumentType, DocumentNumber),
  CONSTRAINT FK_ap_PayDoc_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId),
  CONSTRAINT FK_ap_PayDoc_Branch FOREIGN KEY (BranchId) REFERENCES cfg.Branch(BranchId),
  CONSTRAINT FK_ap_PayDoc_Supplier FOREIGN KEY (SupplierId) REFERENCES mstr.Supplier(SupplierId),
  CONSTRAINT FK_ap_PayDoc_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
  CONSTRAINT FK_ap_PayDoc_UpdatedBy FOREIGN KEY (UpdatedByUserId) REFERENCES sec.[User](UserId)
);
GO

IF OBJECT_ID('ap.PayableApplication', 'U') IS NULL
CREATE TABLE ap.PayableApplication (
  PayableApplicationId   BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
  PayableDocumentId      BIGINT NOT NULL,
  ApplyDate              DATE NOT NULL,
  AppliedAmount          DECIMAL(18,2) NOT NULL,
  PaymentReference       NVARCHAR(120) NULL,
  CreatedAt              DATETIME2(0) NOT NULL CONSTRAINT DF_ap_PayApp_CreatedAt DEFAULT SYSUTCDATETIME(),
  CONSTRAINT FK_ap_PayApp_Doc FOREIGN KEY (PayableDocumentId) REFERENCES ap.PayableDocument(PayableDocumentId)
);
GO

IF OBJECT_ID('fiscal.CountryConfig', 'U') IS NULL
CREATE TABLE fiscal.CountryConfig (
  CountryConfigId         BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
  CompanyId               INT NOT NULL,
  BranchId                INT NOT NULL,
  CountryCode             NCHAR(2) NOT NULL,
  Currency                NCHAR(3) NOT NULL,
  TaxRegime               NVARCHAR(50) NULL,
  DefaultTaxCode          NVARCHAR(30) NULL,
  DefaultTaxRate          DECIMAL(9,4) NOT NULL,
  FiscalPrinterEnabled    BIT NOT NULL CONSTRAINT DF_fiscal_CountryCfg_Printer DEFAULT 0,
  PrinterBrand            NVARCHAR(30) NULL,
  PrinterPort             NVARCHAR(20) NULL,
  VerifactuEnabled        BIT NOT NULL CONSTRAINT DF_fiscal_CountryCfg_Verifactu DEFAULT 0,
  VerifactuMode           NVARCHAR(10) NULL,
  CertificatePath         NVARCHAR(500) NULL,
  CertificatePassword     NVARCHAR(255) NULL,
  AEATEndpoint            NVARCHAR(500) NULL,
  SenderNIF               NVARCHAR(20) NULL,
  SenderRIF               NVARCHAR(20) NULL,
  SoftwareId              NVARCHAR(100) NULL,
  SoftwareName            NVARCHAR(200) NULL,
  SoftwareVersion         NVARCHAR(20) NULL,
  PosEnabled              BIT NOT NULL CONSTRAINT DF_fiscal_CountryCfg_PosEnabled DEFAULT 1,
  RestaurantEnabled       BIT NOT NULL CONSTRAINT DF_fiscal_CountryCfg_RestEnabled DEFAULT 1,
  IsActive                BIT NOT NULL CONSTRAINT DF_fiscal_CountryCfg_IsActive DEFAULT 1,
  CreatedAt               DATETIME2(0) NOT NULL CONSTRAINT DF_fiscal_CountryCfg_CreatedAt DEFAULT SYSUTCDATETIME(),
  UpdatedAt               DATETIME2(0) NOT NULL CONSTRAINT DF_fiscal_CountryCfg_UpdatedAt DEFAULT SYSUTCDATETIME(),
  CreatedByUserId         INT NULL,
  UpdatedByUserId         INT NULL,
  RowVer                  INT NOT NULL DEFAULT 1,
  CONSTRAINT CK_fiscal_CountryCfg_VerifactuMode CHECK (VerifactuMode IN ('auto','manual') OR VerifactuMode IS NULL),
  CONSTRAINT UQ_fiscal_CountryCfg UNIQUE (CompanyId, BranchId, CountryCode),
  CONSTRAINT FK_fiscal_CountryCfg_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId),
  CONSTRAINT FK_fiscal_CountryCfg_Branch FOREIGN KEY (BranchId) REFERENCES cfg.Branch(BranchId),
  CONSTRAINT FK_fiscal_CountryCfg_Country FOREIGN KEY (CountryCode) REFERENCES cfg.Country(CountryCode),
  CONSTRAINT FK_fiscal_CountryCfg_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
  CONSTRAINT FK_fiscal_CountryCfg_UpdatedBy FOREIGN KEY (UpdatedByUserId) REFERENCES sec.[User](UserId)
);
GO

IF OBJECT_ID('fiscal.TaxRate', 'U') IS NULL
CREATE TABLE fiscal.TaxRate (
  TaxRateId               BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
  CountryCode             NCHAR(2) NOT NULL,
  TaxCode                 NVARCHAR(30) NOT NULL,
  TaxName                 NVARCHAR(120) NOT NULL,
  Rate                    DECIMAL(9,4) NOT NULL,
  SurchargeRate           DECIMAL(9,4) NULL,
  AppliesToPOS            BIT NOT NULL CONSTRAINT DF_fiscal_TaxRate_AppliesToPOS DEFAULT 1,
  AppliesToRestaurant     BIT NOT NULL CONSTRAINT DF_fiscal_TaxRate_AppliesToRest DEFAULT 1,
  IsDefault               BIT NOT NULL CONSTRAINT DF_fiscal_TaxRate_IsDefault DEFAULT 0,
  IsActive                BIT NOT NULL CONSTRAINT DF_fiscal_TaxRate_IsActive DEFAULT 1,
  SortOrder               INT NOT NULL CONSTRAINT DF_fiscal_TaxRate_Sort DEFAULT 0,
  CreatedAt               DATETIME2(0) NOT NULL CONSTRAINT DF_fiscal_TaxRate_CreatedAt DEFAULT SYSUTCDATETIME(),
  UpdatedAt               DATETIME2(0) NOT NULL CONSTRAINT DF_fiscal_TaxRate_UpdatedAt DEFAULT SYSUTCDATETIME(),
  CreatedByUserId         INT NULL,
  UpdatedByUserId         INT NULL,
  RowVer                  INT NOT NULL DEFAULT 1,
  CONSTRAINT CK_fiscal_TaxRate_Rate CHECK (Rate >= 0 AND Rate <= 1),
  CONSTRAINT CK_fiscal_TaxRate_Surcharge CHECK (SurchargeRate IS NULL OR (SurchargeRate >= 0 AND SurchargeRate <= 1)),
  CONSTRAINT UQ_fiscal_TaxRate UNIQUE (CountryCode, TaxCode),
  CONSTRAINT FK_fiscal_TaxRate_Country FOREIGN KEY (CountryCode) REFERENCES cfg.Country(CountryCode),
  CONSTRAINT FK_fiscal_TaxRate_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
  CONSTRAINT FK_fiscal_TaxRate_UpdatedBy FOREIGN KEY (UpdatedByUserId) REFERENCES sec.[User](UserId)
);
GO

IF OBJECT_ID('fiscal.InvoiceType', 'U') IS NULL
CREATE TABLE fiscal.InvoiceType (
  InvoiceTypeId           BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
  CountryCode             NCHAR(2) NOT NULL,
  InvoiceTypeCode         NVARCHAR(20) NOT NULL,
  InvoiceTypeName         NVARCHAR(120) NOT NULL,
  IsRectificative         BIT NOT NULL CONSTRAINT DF_fiscal_InvType_Rect DEFAULT 0,
  RequiresRecipientId     BIT NOT NULL CONSTRAINT DF_fiscal_InvType_ReqRcpt DEFAULT 0,
  MaxAmount               DECIMAL(18,2) NULL,
  RequiresFiscalPrinter   BIT NOT NULL CONSTRAINT DF_fiscal_InvType_ReqPrinter DEFAULT 0,
  IsActive                BIT NOT NULL CONSTRAINT DF_fiscal_InvType_IsActive DEFAULT 1,
  SortOrder               INT NOT NULL CONSTRAINT DF_fiscal_InvType_Sort DEFAULT 0,
  CreatedAt               DATETIME2(0) NOT NULL CONSTRAINT DF_fiscal_InvType_CreatedAt DEFAULT SYSUTCDATETIME(),
  UpdatedAt               DATETIME2(0) NOT NULL CONSTRAINT DF_fiscal_InvType_UpdatedAt DEFAULT SYSUTCDATETIME(),
  CreatedByUserId         INT NULL,
  UpdatedByUserId         INT NULL,
  RowVer                  INT NOT NULL DEFAULT 1,
  CONSTRAINT UQ_fiscal_InvType UNIQUE (CountryCode, InvoiceTypeCode),
  CONSTRAINT FK_fiscal_InvType_Country FOREIGN KEY (CountryCode) REFERENCES cfg.Country(CountryCode),
  CONSTRAINT FK_fiscal_InvType_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
  CONSTRAINT FK_fiscal_InvType_UpdatedBy FOREIGN KEY (UpdatedByUserId) REFERENCES sec.[User](UserId)
);
GO

IF OBJECT_ID('fiscal.Record', 'U') IS NULL
CREATE TABLE fiscal.Record (
  FiscalRecordId          BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
  CompanyId               INT NOT NULL,
  BranchId                INT NOT NULL,
  CountryCode             NCHAR(2) NOT NULL,
  InvoiceId               INT NOT NULL,
  InvoiceType             NVARCHAR(20) NOT NULL,
  InvoiceNumber           NVARCHAR(50) NOT NULL,
  InvoiceDate             DATE NOT NULL,
  RecipientId             NVARCHAR(20) NULL,
  TotalAmount             DECIMAL(18,2) NOT NULL,
  RecordHash              NVARCHAR(64) NOT NULL,
  PreviousRecordHash      NVARCHAR(64) NULL,
  XmlContent              NVARCHAR(MAX) NULL,
  DigitalSignature        NVARCHAR(MAX) NULL,
  QRCodeData              NVARCHAR(800) NULL,
  SentToAuthority         BIT NOT NULL CONSTRAINT DF_fiscal_Record_Sent DEFAULT 0,
  SentAt                  DATETIME2(0) NULL,
  AuthorityResponse       NVARCHAR(MAX) NULL,
  AuthorityStatus         NVARCHAR(20) NULL,
  FiscalPrinterSerial     NVARCHAR(30) NULL,
  FiscalControlNumber     NVARCHAR(30) NULL,
  ZReportNumber           INT NULL,
  CreatedAt               DATETIME2(0) NOT NULL CONSTRAINT DF_fiscal_Record_CreatedAt DEFAULT SYSUTCDATETIME(),
  CONSTRAINT UQ_fiscal_Record_Hash UNIQUE (RecordHash),
  CONSTRAINT FK_fiscal_Record_CountryCfg FOREIGN KEY (CompanyId, BranchId, CountryCode) REFERENCES fiscal.CountryConfig(CompanyId, BranchId, CountryCode),
  CONSTRAINT FK_fiscal_Record_PrevHash FOREIGN KEY (PreviousRecordHash) REFERENCES fiscal.Record(RecordHash)
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_fiscal_Record_Search')
  CREATE INDEX IX_fiscal_Record_Search ON fiscal.Record (CompanyId, BranchId, CountryCode, FiscalRecordId DESC);
GO

IF OBJECT_ID('pos.WaitTicket', 'U') IS NULL
CREATE TABLE pos.WaitTicket (
  WaitTicketId            BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
  CompanyId               INT NOT NULL,
  BranchId                INT NOT NULL,
  CountryCode             NCHAR(2) NOT NULL,
  CashRegisterCode        NVARCHAR(10) NOT NULL,
  StationName             NVARCHAR(50) NULL,
  CreatedByUserId         INT NULL,
  CustomerId              BIGINT NULL,
  CustomerCode            NVARCHAR(24) NULL,
  CustomerName            NVARCHAR(200) NULL,
  CustomerFiscalId        NVARCHAR(30) NULL,
  PriceTier               NVARCHAR(20) NOT NULL CONSTRAINT DF_pos_WaitTicket_PriceTier DEFAULT 'DETAIL',
  Reason                  NVARCHAR(200) NULL,
  NetAmount               DECIMAL(18,2) NOT NULL CONSTRAINT DF_pos_WaitTicket_Net DEFAULT 0,
  DiscountAmount          DECIMAL(18,2) NOT NULL CONSTRAINT DF_pos_WaitTicket_Discount DEFAULT 0,
  TaxAmount               DECIMAL(18,2) NOT NULL CONSTRAINT DF_pos_WaitTicket_Tax DEFAULT 0,
  TotalAmount             DECIMAL(18,2) NOT NULL CONSTRAINT DF_pos_WaitTicket_Total DEFAULT 0,
  [Status]                  NVARCHAR(20) NOT NULL CONSTRAINT DF_pos_WaitTicket_Status DEFAULT 'WAITING',
  RecoveredByUserId       INT NULL,
  RecoveredAtRegister     NVARCHAR(10) NULL,
  RecoveredAt             DATETIME2(0) NULL,
  CreatedAt               DATETIME2(0) NOT NULL CONSTRAINT DF_pos_WaitTicket_CreatedAt DEFAULT SYSUTCDATETIME(),
  UpdatedAt               DATETIME2(0) NOT NULL CONSTRAINT DF_pos_WaitTicket_UpdatedAt DEFAULT SYSUTCDATETIME(),
  RowVer                  INT NOT NULL DEFAULT 1,
  CONSTRAINT CK_pos_WaitTicket_Status CHECK ([Status] IN ('WAITING','RECOVERED','VOIDED')),
  CONSTRAINT FK_pos_WaitTicket_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId),
  CONSTRAINT FK_pos_WaitTicket_Branch FOREIGN KEY (BranchId) REFERENCES cfg.Branch(BranchId),
  CONSTRAINT FK_pos_WaitTicket_Country FOREIGN KEY (CountryCode) REFERENCES cfg.Country(CountryCode),
  CONSTRAINT FK_pos_WaitTicket_Customer FOREIGN KEY (CustomerId) REFERENCES mstr.Customer(CustomerId),
  CONSTRAINT FK_pos_WaitTicket_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
  CONSTRAINT FK_pos_WaitTicket_RecoveredBy FOREIGN KEY (RecoveredByUserId) REFERENCES sec.[User](UserId)
);
GO

IF OBJECT_ID('pos.WaitTicketLine', 'U') IS NULL
CREATE TABLE pos.WaitTicketLine (
  WaitTicketLineId        BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
  WaitTicketId            BIGINT NOT NULL,
  LineNumber              INT NOT NULL,
  CountryCode             NCHAR(2) NOT NULL,
  ProductId               BIGINT NULL,
  ProductCode             NVARCHAR(80) NOT NULL,
  ProductName             NVARCHAR(250) NOT NULL,
  Quantity                DECIMAL(10,3) NOT NULL,
  UnitPrice               DECIMAL(18,2) NOT NULL,
  DiscountAmount          DECIMAL(18,2) NOT NULL CONSTRAINT DF_pos_WaitTicketLine_Discount DEFAULT 0,
  TaxCode                 NVARCHAR(30) NOT NULL,
  TaxRate                 DECIMAL(9,4) NOT NULL,
  NetAmount               DECIMAL(18,2) NOT NULL,
  TaxAmount               DECIMAL(18,2) NOT NULL,
  TotalAmount             DECIMAL(18,2) NOT NULL,
  CreatedAt               DATETIME2(0) NOT NULL CONSTRAINT DF_pos_WaitTicketLine_CreatedAt DEFAULT SYSUTCDATETIME(),
  CONSTRAINT UQ_pos_WaitTicketLine UNIQUE (WaitTicketId, LineNumber),
  CONSTRAINT FK_pos_WaitTicketLine_WaitTicket FOREIGN KEY (WaitTicketId) REFERENCES pos.WaitTicket(WaitTicketId) ON DELETE CASCADE,
  CONSTRAINT FK_pos_WaitTicketLine_Product FOREIGN KEY (ProductId) REFERENCES mstr.Product(ProductId),
  CONSTRAINT FK_pos_WaitTicketLine_Tax FOREIGN KEY (CountryCode, TaxCode) REFERENCES fiscal.TaxRate(CountryCode, TaxCode)
);
GO

IF OBJECT_ID('pos.SaleTicket', 'U') IS NULL
CREATE TABLE pos.SaleTicket (
  SaleTicketId            BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
  CompanyId               INT NOT NULL,
  BranchId                INT NOT NULL,
  CountryCode             NCHAR(2) NOT NULL,
  InvoiceNumber           NVARCHAR(20) NOT NULL,
  CashRegisterCode        NVARCHAR(10) NOT NULL,
  SoldByUserId            INT NULL,
  CustomerId              BIGINT NULL,
  CustomerCode            NVARCHAR(24) NULL,
  CustomerName            NVARCHAR(200) NULL,
  CustomerFiscalId        NVARCHAR(30) NULL,
  PriceTier               NVARCHAR(20) NOT NULL CONSTRAINT DF_pos_SaleTicket_PriceTier DEFAULT 'DETAIL',
  PaymentMethod           NVARCHAR(50) NULL,
  FiscalPayload           NVARCHAR(MAX) NULL,
  WaitTicketId            BIGINT NULL,
  NetAmount               DECIMAL(18,2) NOT NULL CONSTRAINT DF_pos_SaleTicket_Net DEFAULT 0,
  DiscountAmount          DECIMAL(18,2) NOT NULL CONSTRAINT DF_pos_SaleTicket_Discount DEFAULT 0,
  TaxAmount               DECIMAL(18,2) NOT NULL CONSTRAINT DF_pos_SaleTicket_Tax DEFAULT 0,
  TotalAmount             DECIMAL(18,2) NOT NULL CONSTRAINT DF_pos_SaleTicket_Total DEFAULT 0,
  SoldAt                  DATETIME2(0) NOT NULL CONSTRAINT DF_pos_SaleTicket_SoldAt DEFAULT SYSUTCDATETIME(),
  RowVer                  INT NOT NULL DEFAULT 1,
  CONSTRAINT UQ_pos_SaleTicket UNIQUE (CompanyId, BranchId, InvoiceNumber),
  CONSTRAINT FK_pos_SaleTicket_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId),
  CONSTRAINT FK_pos_SaleTicket_Branch FOREIGN KEY (BranchId) REFERENCES cfg.Branch(BranchId),
  CONSTRAINT FK_pos_SaleTicket_Country FOREIGN KEY (CountryCode) REFERENCES cfg.Country(CountryCode),
  CONSTRAINT FK_pos_SaleTicket_Customer FOREIGN KEY (CustomerId) REFERENCES mstr.Customer(CustomerId),
  CONSTRAINT FK_pos_SaleTicket_WaitTicket FOREIGN KEY (WaitTicketId) REFERENCES pos.WaitTicket(WaitTicketId),
  CONSTRAINT FK_pos_SaleTicket_SoldBy FOREIGN KEY (SoldByUserId) REFERENCES sec.[User](UserId)
);
GO

IF OBJECT_ID('pos.SaleTicketLine', 'U') IS NULL
CREATE TABLE pos.SaleTicketLine (
  SaleTicketLineId        BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
  SaleTicketId            BIGINT NOT NULL,
  LineNumber              INT NOT NULL,
  CountryCode             NCHAR(2) NOT NULL,
  ProductId               BIGINT NULL,
  ProductCode             NVARCHAR(80) NOT NULL,
  ProductName             NVARCHAR(250) NOT NULL,
  Quantity                DECIMAL(10,3) NOT NULL,
  UnitPrice               DECIMAL(18,2) NOT NULL,
  DiscountAmount          DECIMAL(18,2) NOT NULL CONSTRAINT DF_pos_SaleTicketLine_Discount DEFAULT 0,
  TaxCode                 NVARCHAR(30) NOT NULL,
  TaxRate                 DECIMAL(9,4) NOT NULL,
  NetAmount               DECIMAL(18,2) NOT NULL,
  TaxAmount               DECIMAL(18,2) NOT NULL,
  TotalAmount             DECIMAL(18,2) NOT NULL,
  CONSTRAINT UQ_pos_SaleTicketLine UNIQUE (SaleTicketId, LineNumber),
  CONSTRAINT FK_pos_SaleTicketLine_SaleTicket FOREIGN KEY (SaleTicketId) REFERENCES pos.SaleTicket(SaleTicketId) ON DELETE CASCADE,
  CONSTRAINT FK_pos_SaleTicketLine_Product FOREIGN KEY (ProductId) REFERENCES mstr.Product(ProductId),
  CONSTRAINT FK_pos_SaleTicketLine_Tax FOREIGN KEY (CountryCode, TaxCode) REFERENCES fiscal.TaxRate(CountryCode, TaxCode)
);
GO

IF OBJECT_ID('rest.OrderTicket', 'U') IS NULL
CREATE TABLE rest.OrderTicket (
  OrderTicketId           BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
  CompanyId               INT NOT NULL,
  BranchId                INT NOT NULL,
  CountryCode             NCHAR(2) NOT NULL,
  TableNumber             NVARCHAR(20) NULL,
  OpenedByUserId          INT NULL,
  ClosedByUserId          INT NULL,
  CustomerName            NVARCHAR(200) NULL,
  CustomerFiscalId        NVARCHAR(30) NULL,
  [Status]                  NVARCHAR(20) NOT NULL CONSTRAINT DF_rest_OrderTicket_Status DEFAULT 'OPEN',
  NetAmount               DECIMAL(18,2) NOT NULL CONSTRAINT DF_rest_OrderTicket_Net DEFAULT 0,
  TaxAmount               DECIMAL(18,2) NOT NULL CONSTRAINT DF_rest_OrderTicket_Tax DEFAULT 0,
  TotalAmount             DECIMAL(18,2) NOT NULL CONSTRAINT DF_rest_OrderTicket_Total DEFAULT 0,
  OpenedAt                DATETIME2(0) NOT NULL CONSTRAINT DF_rest_OrderTicket_OpenedAt DEFAULT SYSUTCDATETIME(),
  ClosedAt                DATETIME2(0) NULL,
  UpdatedAt               DATETIME2(0) NOT NULL CONSTRAINT DF_rest_OrderTicket_UpdatedAt DEFAULT SYSUTCDATETIME(),
  RowVer                  INT NOT NULL DEFAULT 1,
  CONSTRAINT CK_rest_OrderTicket_Status CHECK ([Status] IN ('OPEN','SENT','CLOSED','VOIDED')),
  CONSTRAINT FK_rest_OrderTicket_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId),
  CONSTRAINT FK_rest_OrderTicket_Branch FOREIGN KEY (BranchId) REFERENCES cfg.Branch(BranchId),
  CONSTRAINT FK_rest_OrderTicket_Country FOREIGN KEY (CountryCode) REFERENCES cfg.Country(CountryCode),
  CONSTRAINT FK_rest_OrderTicket_OpenedBy FOREIGN KEY (OpenedByUserId) REFERENCES sec.[User](UserId),
  CONSTRAINT FK_rest_OrderTicket_ClosedBy FOREIGN KEY (ClosedByUserId) REFERENCES sec.[User](UserId)
);
GO

IF OBJECT_ID('rest.OrderTicketLine', 'U') IS NULL
CREATE TABLE rest.OrderTicketLine (
  OrderTicketLineId       BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
  OrderTicketId           BIGINT NOT NULL,
  LineNumber              INT NOT NULL,
  CountryCode             NCHAR(2) NOT NULL,
  ProductId               BIGINT NULL,
  ProductCode             NVARCHAR(80) NOT NULL,
  ProductName             NVARCHAR(250) NOT NULL,
  Quantity                DECIMAL(10,3) NOT NULL,
  UnitPrice               DECIMAL(18,2) NOT NULL,
  TaxCode                 NVARCHAR(30) NOT NULL,
  TaxRate                 DECIMAL(9,4) NOT NULL,
  NetAmount               DECIMAL(18,2) NOT NULL,
  TaxAmount               DECIMAL(18,2) NOT NULL,
  TotalAmount             DECIMAL(18,2) NOT NULL,
  Notes                   NVARCHAR(300) NULL,
  CreatedAt               DATETIME2(0) NOT NULL CONSTRAINT DF_rest_OrderTicketLine_CreatedAt DEFAULT SYSUTCDATETIME(),
  UpdatedAt               DATETIME2(0) NOT NULL CONSTRAINT DF_rest_OrderTicketLine_UpdatedAt DEFAULT SYSUTCDATETIME(),
  CONSTRAINT UQ_rest_OrderTicketLine UNIQUE (OrderTicketId, LineNumber),
  CONSTRAINT FK_rest_OrderTicketLine_Order FOREIGN KEY (OrderTicketId) REFERENCES rest.OrderTicket(OrderTicketId) ON DELETE CASCADE,
  CONSTRAINT FK_rest_OrderTicketLine_Product FOREIGN KEY (ProductId) REFERENCES mstr.Product(ProductId),
  CONSTRAINT FK_rest_OrderTicketLine_Tax FOREIGN KEY (CountryCode, TaxCode) REFERENCES fiscal.TaxRate(CountryCode, TaxCode)
);
GO

IF OBJECT_ID('sec.AuthIdentity', 'U') IS NULL
CREATE TABLE sec.AuthIdentity (
  UserCode          NVARCHAR(40)   NOT NULL,
  Email                 NVARCHAR(254)  NULL,
  EmailNormalized       NVARCHAR(254)  NULL,
  EmailVerifiedAtUtc    DATETIME2(0)     NULL,
  IsRegistrationPending BIT       NOT NULL DEFAULT 0,
  FailedLoginCount      INT           NOT NULL DEFAULT 0,
  LastFailedLoginAtUtc  DATETIME2(0)     NULL,
  LastFailedLoginIp     NVARCHAR(64)   NULL,
  LockoutUntilUtc       DATETIME2(0)     NULL,
  LastLoginAtUtc        DATETIME2(0)     NULL,
  PasswordChangedAtUtc  DATETIME2(0)     NULL,
  CreatedAtUtc          DATETIME2(0)     NOT NULL DEFAULT SYSUTCDATETIME(),
  UpdatedAtUtc          DATETIME2(0)     NOT NULL DEFAULT SYSUTCDATETIME(),
  CONSTRAINT PK_sec_AuthIdentity PRIMARY KEY (UserCode),
  CONSTRAINT FK_sec_AuthIdentity_User
    FOREIGN KEY (UserCode) REFERENCES sec.[User](UserCode)
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UX_sec_AuthIdentity_EmailNormalized')
  CREATE UNIQUE INDEX UX_sec_AuthIdentity_EmailNormalized ON sec.AuthIdentity (EmailNormalized) WHERE EmailNormalized IS NOT NULL;
GO

IF OBJECT_ID('sec.AuthToken', 'U') IS NULL
CREATE TABLE sec.AuthToken (
  TokenId           BIGINT IDENTITY(1,1) PRIMARY KEY,
  UserCode          NVARCHAR(40)   NOT NULL,
  TokenType         NVARCHAR(32)   NOT NULL,
  TokenHash         NCHAR(64)      NOT NULL,
  EmailNormalized   NVARCHAR(254)  NULL,
  ExpiresAtUtc      DATETIME2(0)     NOT NULL,
  ConsumedAtUtc     DATETIME2(0)     NULL,
  MetaIp            NVARCHAR(64)   NULL,
  MetaUserAgent     NVARCHAR(256)  NULL,
  CreatedAtUtc      DATETIME2(0)     NOT NULL DEFAULT SYSUTCDATETIME(),
  CONSTRAINT FK_sec_AuthToken_User
    FOREIGN KEY (UserCode) REFERENCES sec.[User](UserCode),
  CONSTRAINT CK_sec_AuthToken_Type
    CHECK (TokenType IN ('VERIFY_EMAIL', 'RESET_PASSWORD'))
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UX_sec_AuthToken_TokenHash')
  CREATE UNIQUE INDEX UX_sec_AuthToken_TokenHash ON sec.AuthToken (TokenHash);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_sec_AuthToken_UserCode_Type_Expires')
  CREATE INDEX IX_sec_AuthToken_UserCode_Type_Expires ON sec.AuthToken (UserCode, TokenType, ExpiresAtUtc, ConsumedAtUtc);
GO

IF OBJECT_ID('pos.FiscalCorrelative', 'U') IS NULL
CREATE TABLE pos.FiscalCorrelative (
  FiscalCorrelativeId  BIGINT IDENTITY(1,1) PRIMARY KEY,
  CompanyId            INT         NOT NULL,
  BranchId             INT         NOT NULL,
  CorrelativeType      NVARCHAR(20) NOT NULL DEFAULT 'FACTURA',
  CashRegisterCode     NVARCHAR(10) NOT NULL DEFAULT 'GLOBAL',
  SerialFiscal         NVARCHAR(40) NOT NULL,
  CurrentNumber        INT         NOT NULL DEFAULT 0,
  Description          NVARCHAR(200) NULL,
  IsActive             BIT     NOT NULL DEFAULT 1,
  CreatedAt            DATETIME2(0)   NOT NULL DEFAULT SYSUTCDATETIME(),
  UpdatedAt            DATETIME2(0)   NOT NULL DEFAULT SYSUTCDATETIME(),
  CreatedByUserId      INT         NULL,
  UpdatedByUserId      INT         NULL,
  RowVer               INT         NOT NULL DEFAULT 1,
  CONSTRAINT UQ_pos_FiscalCorrelative UNIQUE (CompanyId, BranchId, CorrelativeType, CashRegisterCode),
  CONSTRAINT FK_pos_FiscalCorrelative_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId),
  CONSTRAINT FK_pos_FiscalCorrelative_Branch FOREIGN KEY (BranchId) REFERENCES cfg.Branch(BranchId),
  CONSTRAINT FK_pos_FiscalCorrelative_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
  CONSTRAINT FK_pos_FiscalCorrelative_UpdatedBy FOREIGN KEY (UpdatedByUserId) REFERENCES sec.[User](UserId)
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_pos_FiscalCorrelative_Search')
  CREATE INDEX IX_pos_FiscalCorrelative_Search ON pos.FiscalCorrelative (CompanyId, BranchId, CorrelativeType, CashRegisterCode, IsActive);
GO

IF OBJECT_ID('rest.DiningTable', 'U') IS NULL
CREATE TABLE rest.DiningTable (
  DiningTableId    BIGINT IDENTITY(1,1) PRIMARY KEY,
  CompanyId        INT          NOT NULL,
  BranchId         INT          NOT NULL,
  TableNumber      NVARCHAR(20)  NOT NULL,
  TableName        NVARCHAR(100) NULL,
  Capacity         INT          NOT NULL DEFAULT 4,
  EnvironmentCode  NVARCHAR(20)  NULL,
  EnvironmentName  NVARCHAR(80)  NULL,
  PositionX        INT          NULL,
  PositionY        INT          NULL,
  IsActive         BIT      NOT NULL DEFAULT 1,
  CreatedAt        DATETIME2(0)    NOT NULL DEFAULT SYSUTCDATETIME(),
  UpdatedAt        DATETIME2(0)    NOT NULL DEFAULT SYSUTCDATETIME(),
  CreatedByUserId  INT          NULL,
  UpdatedByUserId  INT          NULL,
  RowVer           INT          NOT NULL DEFAULT 1,
  CONSTRAINT UQ_rest_DiningTable UNIQUE (CompanyId, BranchId, TableNumber),
  CONSTRAINT FK_rest_DiningTable_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId),
  CONSTRAINT FK_rest_DiningTable_Branch FOREIGN KEY (BranchId) REFERENCES cfg.Branch(BranchId),
  CONSTRAINT FK_rest_DiningTable_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
  CONSTRAINT FK_rest_DiningTable_UpdatedBy FOREIGN KEY (UpdatedByUserId) REFERENCES sec.[User](UserId)
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_rest_DiningTable_Search')
  CREATE INDEX IX_rest_DiningTable_Search ON rest.DiningTable (CompanyId, BranchId, IsActive, EnvironmentCode, TableNumber);
GO

IF OBJECT_ID('fin.Bank', 'U') IS NULL
CREATE TABLE fin.Bank (
  BankId           BIGINT IDENTITY(1,1) PRIMARY KEY,
  CompanyId        INT          NOT NULL,
  BankCode         NVARCHAR(30)  NOT NULL,
  BankName         NVARCHAR(120) NOT NULL,
  ContactName      NVARCHAR(120) NULL,
  AddressLine      NVARCHAR(250) NULL,
  Phones           NVARCHAR(120) NULL,
  IsActive         BIT      NOT NULL DEFAULT 1,
  CreatedAt        DATETIME2(0)    NOT NULL DEFAULT SYSUTCDATETIME(),
  UpdatedAt        DATETIME2(0)    NOT NULL DEFAULT SYSUTCDATETIME(),
  CreatedByUserId  INT          NULL,
  UpdatedByUserId  INT          NULL,
  RowVer           INT          NOT NULL DEFAULT 1,
  CONSTRAINT UQ_fin_Bank_Code UNIQUE (CompanyId, BankCode),
  CONSTRAINT UQ_fin_Bank_Name UNIQUE (CompanyId, BankName),
  CONSTRAINT FK_fin_Bank_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId),
  CONSTRAINT FK_fin_Bank_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
  CONSTRAINT FK_fin_Bank_UpdatedBy FOREIGN KEY (UpdatedByUserId) REFERENCES sec.[User](UserId)
);
GO

IF OBJECT_ID('fin.BankAccount', 'U') IS NULL
CREATE TABLE fin.BankAccount (
  BankAccountId    BIGINT IDENTITY(1,1) PRIMARY KEY,
  CompanyId        INT            NOT NULL,
  BranchId         INT            NOT NULL,
  BankId           BIGINT         NOT NULL,
  AccountNumber    NVARCHAR(40)    NOT NULL,
  AccountName      NVARCHAR(150)   NULL,
  CurrencyCode     NCHAR(3)        NOT NULL,
  Balance          DECIMAL(18,2)  NOT NULL DEFAULT 0,
  AvailableBalance DECIMAL(18,2)  NOT NULL DEFAULT 0,
  IsActive         BIT        NOT NULL DEFAULT 1,
  CreatedAt        DATETIME2(0)      NOT NULL DEFAULT SYSUTCDATETIME(),
  UpdatedAt        DATETIME2(0)      NOT NULL DEFAULT SYSUTCDATETIME(),
  CreatedByUserId  INT            NULL,
  UpdatedByUserId  INT            NULL,
  RowVer           INT            NOT NULL DEFAULT 1,
  CONSTRAINT UQ_fin_BankAccount UNIQUE (CompanyId, AccountNumber),
  CONSTRAINT FK_fin_BankAccount_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId),
  CONSTRAINT FK_fin_BankAccount_Branch FOREIGN KEY (BranchId) REFERENCES cfg.Branch(BranchId),
  CONSTRAINT FK_fin_BankAccount_Bank FOREIGN KEY (BankId) REFERENCES fin.Bank(BankId),
  CONSTRAINT FK_fin_BankAccount_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
  CONSTRAINT FK_fin_BankAccount_UpdatedBy FOREIGN KEY (UpdatedByUserId) REFERENCES sec.[User](UserId)
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_fin_BankAccount_Search')
  CREATE INDEX IX_fin_BankAccount_Search ON fin.BankAccount (CompanyId, BranchId, IsActive, AccountNumber);
GO

IF OBJECT_ID('fin.BankReconciliation', 'U') IS NULL
CREATE TABLE fin.BankReconciliation (
  BankReconciliationId BIGINT IDENTITY(1,1) PRIMARY KEY,
  CompanyId            INT            NOT NULL,
  BranchId             INT            NOT NULL,
  BankAccountId        BIGINT         NOT NULL,
  DateFrom             DATE           NOT NULL,
  DateTo               DATE           NOT NULL,
  OpeningSystemBalance DECIMAL(18,2)  NOT NULL,
  ClosingSystemBalance DECIMAL(18,2)  NOT NULL,
  OpeningBankBalance   DECIMAL(18,2)  NOT NULL,
  ClosingBankBalance   DECIMAL(18,2)  NULL,
  DifferenceAmount     DECIMAL(18,2)  NULL,
  [Status]               NVARCHAR(20)    NOT NULL DEFAULT 'OPEN',
  Notes                NVARCHAR(500)   NULL,
  ClosedAt             DATETIME2(0)      NULL,
  CreatedAt            DATETIME2(0)      NOT NULL DEFAULT SYSUTCDATETIME(),
  UpdatedAt            DATETIME2(0)      NOT NULL DEFAULT SYSUTCDATETIME(),
  CreatedByUserId      INT            NULL,
  ClosedByUserId       INT            NULL,
  RowVer               INT            NOT NULL DEFAULT 1,
  CONSTRAINT CK_fin_BankRec_Status CHECK ([Status] IN ('OPEN','CLOSED','CLOSED_WITH_DIFF')),
  CONSTRAINT FK_fin_BankRec_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId),
  CONSTRAINT FK_fin_BankRec_Branch FOREIGN KEY (BranchId) REFERENCES cfg.Branch(BranchId),
  CONSTRAINT FK_fin_BankRec_Account FOREIGN KEY (BankAccountId) REFERENCES fin.BankAccount(BankAccountId),
  CONSTRAINT FK_fin_BankRec_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
  CONSTRAINT FK_fin_BankRec_ClosedBy FOREIGN KEY (ClosedByUserId) REFERENCES sec.[User](UserId)
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_fin_BankRec_Search')
  CREATE INDEX IX_fin_BankRec_Search ON fin.BankReconciliation (BankAccountId, [Status], DateFrom, DateTo);
GO

IF OBJECT_ID('fin.BankMovement', 'U') IS NULL
CREATE TABLE fin.BankMovement (
  BankMovementId    BIGINT IDENTITY(1,1) PRIMARY KEY,
  BankAccountId     BIGINT         NOT NULL,
  ReconciliationId  BIGINT         NULL,
  MovementDate      DATETIME2(0)      NOT NULL,
  MovementType      NVARCHAR(12)    NOT NULL,
  MovementSign      SMALLINT       NOT NULL,
  Amount            DECIMAL(18,2)  NOT NULL,
  NetAmount         DECIMAL(18,2)  NOT NULL,
  ReferenceNo       NVARCHAR(50)    NULL,
  Beneficiary       NVARCHAR(255)   NULL,
  Concept           NVARCHAR(255)   NULL,
  CategoryCode      NVARCHAR(50)    NULL,
  RelatedDocumentNo   NVARCHAR(60)  NULL,
  RelatedDocumentType NVARCHAR(20)  NULL,
  BalanceAfter      DECIMAL(18,2)  NULL,
  IsReconciled      BIT        NOT NULL DEFAULT 0,
  ReconciledAt      DATETIME2(0)      NULL,
  CreatedAt         DATETIME2(0)      NOT NULL DEFAULT SYSUTCDATETIME(),
  CreatedByUserId   INT            NULL,
  RowVer            INT            NOT NULL DEFAULT 1,
  CONSTRAINT CK_fin_BankMovement_Sign CHECK (MovementSign IN (-1, 1)),
  CONSTRAINT CK_fin_BankMovement_Amount CHECK (Amount >= 0),
  CONSTRAINT FK_fin_BankMovement_Account FOREIGN KEY (BankAccountId) REFERENCES fin.BankAccount(BankAccountId),
  CONSTRAINT FK_fin_BankMovement_Reconciliation FOREIGN KEY (ReconciliationId) REFERENCES fin.BankReconciliation(BankReconciliationId),
  CONSTRAINT FK_fin_BankMovement_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId)
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_fin_BankMovement_Search')
  CREATE INDEX IX_fin_BankMovement_Search ON fin.BankMovement (BankAccountId, MovementDate DESC, BankMovementId DESC);
GO

IF OBJECT_ID('fin.BankStatementLine', 'U') IS NULL
CREATE TABLE fin.BankStatementLine (
  StatementLineId  BIGINT IDENTITY(1,1) PRIMARY KEY,
  ReconciliationId BIGINT         NOT NULL,
  StatementDate    DATETIME2(0)      NOT NULL,
  DescriptionText  NVARCHAR(255)   NULL,
  ReferenceNo      NVARCHAR(50)    NULL,
  EntryType        NVARCHAR(12)    NOT NULL,
  Amount           DECIMAL(18,2)  NOT NULL,
  Balance          DECIMAL(18,2)  NULL,
  IsMatched        BIT        NOT NULL DEFAULT 0,
  MatchedAt        DATETIME2(0)      NULL,
  CreatedAt        DATETIME2(0)      NOT NULL DEFAULT SYSUTCDATETIME(),
  CreatedByUserId  INT            NULL,
  RowVer           INT            NOT NULL DEFAULT 1,
  CONSTRAINT CK_fin_BankStatementLine_EntryType CHECK (EntryType IN ('DEBITO', 'CREDITO')),
  CONSTRAINT CK_fin_BankStatementLine_Amount CHECK (Amount >= 0),
  CONSTRAINT FK_fin_BankStatementLine_Reconciliation FOREIGN KEY (ReconciliationId) REFERENCES fin.BankReconciliation(BankReconciliationId),
  CONSTRAINT FK_fin_BankStatementLine_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId)
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_fin_BankStatementLine_Search')
  CREATE INDEX IX_fin_BankStatementLine_Search ON fin.BankStatementLine (ReconciliationId, IsMatched, StatementDate);
GO

IF OBJECT_ID('fin.BankReconciliationMatch', 'U') IS NULL
CREATE TABLE fin.BankReconciliationMatch (
  BankReconciliationMatchId BIGINT IDENTITY(1,1) PRIMARY KEY,
  ReconciliationId          BIGINT    NOT NULL,
  BankMovementId            BIGINT    NOT NULL,
  StatementLineId           BIGINT    NULL,
  MatchedAt                 DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
  MatchedByUserId           INT       NULL,
  CONSTRAINT UQ_fin_BankRecMatch_Movement UNIQUE (ReconciliationId, BankMovementId),
  CONSTRAINT UQ_fin_BankRecMatch_Statement UNIQUE (ReconciliationId, StatementLineId),
  CONSTRAINT FK_fin_BankRecMatch_Reconciliation FOREIGN KEY (ReconciliationId) REFERENCES fin.BankReconciliation(BankReconciliationId),
  CONSTRAINT FK_fin_BankRecMatch_Movement FOREIGN KEY (BankMovementId) REFERENCES fin.BankMovement(BankMovementId),
  CONSTRAINT FK_fin_BankRecMatch_Statement FOREIGN KEY (StatementLineId) REFERENCES fin.BankStatementLine(StatementLineId),
  CONSTRAINT FK_fin_BankRecMatch_User FOREIGN KEY (MatchedByUserId) REFERENCES sec.[User](UserId)
);
GO

IF OBJECT_ID('hr.PayrollType', 'U') IS NULL
CREATE TABLE hr.PayrollType (
  PayrollTypeId    BIGINT IDENTITY(1,1) PRIMARY KEY,
  CompanyId        INT          NOT NULL,
  PayrollCode      NVARCHAR(15)  NOT NULL,
  PayrollName      NVARCHAR(120) NOT NULL,
  IsActive         BIT      NOT NULL DEFAULT 1,
  CreatedAt        DATETIME2(0)    NOT NULL DEFAULT SYSUTCDATETIME(),
  UpdatedAt        DATETIME2(0)    NOT NULL DEFAULT SYSUTCDATETIME(),
  CreatedByUserId  INT          NULL,
  UpdatedByUserId  INT          NULL,
  RowVer           INT          NOT NULL DEFAULT 1,
  CONSTRAINT UQ_hr_PayrollType UNIQUE (CompanyId, PayrollCode),
  CONSTRAINT FK_hr_PayrollType_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId),
  CONSTRAINT FK_hr_PayrollType_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
  CONSTRAINT FK_hr_PayrollType_UpdatedBy FOREIGN KEY (UpdatedByUserId) REFERENCES sec.[User](UserId)
);
GO

IF OBJECT_ID('hr.PayrollConcept', 'U') IS NULL
CREATE TABLE hr.PayrollConcept (
  PayrollConceptId      BIGINT IDENTITY(1,1) PRIMARY KEY,
  CompanyId             INT            NOT NULL,
  PayrollCode           NVARCHAR(15)    NOT NULL,
  ConceptCode           NVARCHAR(20)    NOT NULL,
  ConceptName           NVARCHAR(120)   NOT NULL,
  Formula               NVARCHAR(500)   NULL,
  BaseExpression        NVARCHAR(255)   NULL,
  ConceptClass          NVARCHAR(20)    NULL,
  ConceptType           NVARCHAR(15)    NOT NULL DEFAULT 'ASIGNACION',
  UsageType             NVARCHAR(20)    NULL,
  IsBonifiable          BIT        NOT NULL DEFAULT 0,
  IsSeniority           BIT        NOT NULL DEFAULT 0,
  AccountingAccountCode NVARCHAR(50)    NULL,
  AppliesFlag           BIT        NOT NULL DEFAULT 1,
  DefaultValue          DECIMAL(18,4)  NOT NULL DEFAULT 0,
  ConventionCode        NVARCHAR(50)    NULL,
  CalculationType       NVARCHAR(50)    NULL,
  LotttArticle          NVARCHAR(50)    NULL,
  CcpClause             NVARCHAR(50)    NULL,
  SortOrder             INT            NOT NULL DEFAULT 0,
  IsActive              BIT        NOT NULL DEFAULT 1,
  CreatedAt             DATETIME2(0)      NOT NULL DEFAULT SYSUTCDATETIME(),
  UpdatedAt             DATETIME2(0)      NOT NULL DEFAULT SYSUTCDATETIME(),
  CreatedByUserId       INT            NULL,
  UpdatedByUserId       INT            NULL,
  RowVer                INT            NOT NULL DEFAULT 1,
  CONSTRAINT CK_hr_PayrollConcept_Type CHECK (ConceptType IN ('ASIGNACION', 'DEDUCCION', 'BONO')),
  CONSTRAINT UQ_hr_PayrollConcept UNIQUE (CompanyId, PayrollCode, ConceptCode, ConventionCode, CalculationType),
  CONSTRAINT FK_hr_PayrollConcept_PayrollType FOREIGN KEY (CompanyId, PayrollCode) REFERENCES hr.PayrollType(CompanyId, PayrollCode),
  CONSTRAINT FK_hr_PayrollConcept_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
  CONSTRAINT FK_hr_PayrollConcept_UpdatedBy FOREIGN KEY (UpdatedByUserId) REFERENCES sec.[User](UserId)
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_hr_PayrollConcept_Search')
  CREATE INDEX IX_hr_PayrollConcept_Search ON hr.PayrollConcept (CompanyId, PayrollCode, IsActive, ConceptType, SortOrder, ConceptCode);
GO

IF OBJECT_ID('hr.PayrollRun', 'U') IS NULL
CREATE TABLE hr.PayrollRun (
  PayrollRunId     BIGINT IDENTITY(1,1) PRIMARY KEY,
  CompanyId        INT            NOT NULL,
  BranchId         INT            NOT NULL,
  PayrollCode      NVARCHAR(15)    NOT NULL,
  EmployeeId       BIGINT         NULL,
  EmployeeCode     NVARCHAR(24)    NOT NULL,
  EmployeeName     NVARCHAR(200)   NOT NULL,
  PositionName     NVARCHAR(120)   NULL,
  ProcessDate      DATE           NOT NULL,
  DateFrom         DATE           NOT NULL,
  DateTo           DATE           NOT NULL,
  TotalAssignments DECIMAL(18,2)  NOT NULL DEFAULT 0,
  TotalDeductions  DECIMAL(18,2)  NOT NULL DEFAULT 0,
  NetTotal         DECIMAL(18,2)  NOT NULL DEFAULT 0,
  IsClosed         BIT        NOT NULL DEFAULT 0,
  PayrollTypeName  NVARCHAR(50)    NULL,
  RunSource        NVARCHAR(20)    NOT NULL DEFAULT 'MANUAL',
  ClosedAt         DATETIME2(0)      NULL,
  ClosedByUserId   INT            NULL,
  CreatedAt        DATETIME2(0)      NOT NULL DEFAULT SYSUTCDATETIME(),
  UpdatedAt        DATETIME2(0)      NOT NULL DEFAULT SYSUTCDATETIME(),
  CreatedByUserId  INT            NULL,
  UpdatedByUserId  INT            NULL,
  RowVer           INT            NOT NULL DEFAULT 1,
  CONSTRAINT UQ_hr_PayrollRun UNIQUE (CompanyId, BranchId, PayrollCode, EmployeeCode, DateFrom, DateTo, RunSource),
  CONSTRAINT FK_hr_PayrollRun_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId),
  CONSTRAINT FK_hr_PayrollRun_Branch FOREIGN KEY (BranchId) REFERENCES cfg.Branch(BranchId),
  CONSTRAINT FK_hr_PayrollRun_Employee FOREIGN KEY (EmployeeId) REFERENCES mstr.Employee(EmployeeId),
  CONSTRAINT FK_hr_PayrollRun_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
  CONSTRAINT FK_hr_PayrollRun_UpdatedBy FOREIGN KEY (UpdatedByUserId) REFERENCES sec.[User](UserId),
  CONSTRAINT FK_hr_PayrollRun_ClosedBy FOREIGN KEY (ClosedByUserId) REFERENCES sec.[User](UserId)
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_hr_PayrollRun_Search')
  CREATE INDEX IX_hr_PayrollRun_Search ON hr.PayrollRun (CompanyId, PayrollCode, EmployeeCode, ProcessDate DESC, IsClosed);
GO

IF OBJECT_ID('hr.PayrollRunLine', 'U') IS NULL
CREATE TABLE hr.PayrollRunLine (
  PayrollRunLineId      BIGINT IDENTITY(1,1) PRIMARY KEY,
  PayrollRunId          BIGINT         NOT NULL,
  ConceptCode           NVARCHAR(20)    NOT NULL,
  ConceptName           NVARCHAR(120)   NOT NULL,
  ConceptType           NVARCHAR(15)    NOT NULL,
  Quantity              DECIMAL(18,4)  NOT NULL DEFAULT 1,
  Amount                DECIMAL(18,4)  NOT NULL DEFAULT 0,
  Total                 DECIMAL(18,2)  NOT NULL DEFAULT 0,
  DescriptionText       NVARCHAR(255)   NULL,
  AccountingAccountCode NVARCHAR(50)    NULL,
  CreatedAt             DATETIME2(0)      NOT NULL DEFAULT SYSUTCDATETIME(),
  CONSTRAINT FK_hr_PayrollRunLine_Run FOREIGN KEY (PayrollRunId) REFERENCES hr.PayrollRun(PayrollRunId) ON DELETE CASCADE
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_hr_PayrollRunLine_Run')
  CREATE INDEX IX_hr_PayrollRunLine_Run ON hr.PayrollRunLine (PayrollRunId, ConceptType, ConceptCode);
GO

IF OBJECT_ID('hr.VacationProcess', 'U') IS NULL
CREATE TABLE hr.VacationProcess (
  VacationProcessId BIGINT IDENTITY(1,1) PRIMARY KEY,
  CompanyId          INT            NOT NULL,
  BranchId           INT            NOT NULL,
  VacationCode       NVARCHAR(50)    NOT NULL,
  EmployeeId         BIGINT         NULL,
  EmployeeCode       NVARCHAR(24)    NOT NULL,
  EmployeeName       NVARCHAR(200)   NOT NULL,
  StartDate          DATE           NOT NULL,
  EndDate            DATE           NOT NULL,
  ReintegrationDate  DATE           NULL,
  ProcessDate        DATE           NOT NULL,
  TotalAmount        DECIMAL(18,2)  NOT NULL DEFAULT 0,
  CalculatedAmount   DECIMAL(18,2)  NOT NULL DEFAULT 0,
  CreatedAt          DATETIME2(0)      NOT NULL DEFAULT SYSUTCDATETIME(),
  UpdatedAt          DATETIME2(0)      NOT NULL DEFAULT SYSUTCDATETIME(),
  CreatedByUserId    INT            NULL,
  UpdatedByUserId    INT            NULL,
  RowVer             INT            NOT NULL DEFAULT 1,
  CONSTRAINT UQ_hr_VacationProcess UNIQUE (CompanyId, VacationCode),
  CONSTRAINT FK_hr_VacationProcess_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId),
  CONSTRAINT FK_hr_VacationProcess_Branch FOREIGN KEY (BranchId) REFERENCES cfg.Branch(BranchId),
  CONSTRAINT FK_hr_VacationProcess_Employee FOREIGN KEY (EmployeeId) REFERENCES mstr.Employee(EmployeeId),
  CONSTRAINT FK_hr_VacationProcess_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
  CONSTRAINT FK_hr_VacationProcess_UpdatedBy FOREIGN KEY (UpdatedByUserId) REFERENCES sec.[User](UserId)
);
GO

IF OBJECT_ID('hr.VacationProcessLine', 'U') IS NULL
CREATE TABLE hr.VacationProcessLine (
  VacationProcessLineId BIGINT IDENTITY(1,1) PRIMARY KEY,
  VacationProcessId     BIGINT        NOT NULL,
  ConceptCode           NVARCHAR(20)   NOT NULL,
  ConceptName           NVARCHAR(120)  NOT NULL,
  Amount                DECIMAL(18,2) NOT NULL,
  CreatedAt             DATETIME2(0)     NOT NULL DEFAULT SYSUTCDATETIME(),
  CONSTRAINT FK_hr_VacationProcessLine_Process FOREIGN KEY (VacationProcessId) REFERENCES hr.VacationProcess(VacationProcessId) ON DELETE CASCADE
);
GO

IF OBJECT_ID('hr.SettlementProcess', 'U') IS NULL
CREATE TABLE hr.SettlementProcess (
  SettlementProcessId BIGINT IDENTITY(1,1) PRIMARY KEY,
  CompanyId           INT            NOT NULL,
  BranchId            INT            NOT NULL,
  SettlementCode      NVARCHAR(50)    NOT NULL,
  EmployeeId          BIGINT         NULL,
  EmployeeCode        NVARCHAR(24)    NOT NULL,
  EmployeeName        NVARCHAR(200)   NOT NULL,
  RetirementDate      DATE           NOT NULL,
  RetirementCause     NVARCHAR(40)    NULL,
  TotalAmount         DECIMAL(18,2)  NOT NULL DEFAULT 0,
  CreatedAt           DATETIME2(0)      NOT NULL DEFAULT SYSUTCDATETIME(),
  UpdatedAt           DATETIME2(0)      NOT NULL DEFAULT SYSUTCDATETIME(),
  CreatedByUserId     INT            NULL,
  UpdatedByUserId     INT            NULL,
  RowVer              INT            NOT NULL DEFAULT 1,
  CONSTRAINT UQ_hr_SettlementProcess UNIQUE (CompanyId, SettlementCode),
  CONSTRAINT FK_hr_SettlementProcess_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId),
  CONSTRAINT FK_hr_SettlementProcess_Branch FOREIGN KEY (BranchId) REFERENCES cfg.Branch(BranchId),
  CONSTRAINT FK_hr_SettlementProcess_Employee FOREIGN KEY (EmployeeId) REFERENCES mstr.Employee(EmployeeId),
  CONSTRAINT FK_hr_SettlementProcess_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
  CONSTRAINT FK_hr_SettlementProcess_UpdatedBy FOREIGN KEY (UpdatedByUserId) REFERENCES sec.[User](UserId)
);
GO

IF OBJECT_ID('hr.SettlementProcessLine', 'U') IS NULL
CREATE TABLE hr.SettlementProcessLine (
  SettlementProcessLineId BIGINT IDENTITY(1,1) PRIMARY KEY,
  SettlementProcessId     BIGINT        NOT NULL,
  ConceptCode             NVARCHAR(20)   NOT NULL,
  ConceptName             NVARCHAR(120)  NOT NULL,
  Amount                  DECIMAL(18,2) NOT NULL,
  CreatedAt               DATETIME2(0)     NOT NULL DEFAULT SYSUTCDATETIME(),
  CONSTRAINT FK_hr_SettlementProcessLine_Process FOREIGN KEY (SettlementProcessId) REFERENCES hr.SettlementProcess(SettlementProcessId) ON DELETE CASCADE
);
GO

IF OBJECT_ID('hr.PayrollConstant', 'U') IS NULL
CREATE TABLE hr.PayrollConstant (
  PayrollConstantId BIGINT IDENTITY(1,1) PRIMARY KEY,
  CompanyId         INT            NOT NULL,
  ConstantCode      NVARCHAR(50)    NOT NULL,
  ConstantName      NVARCHAR(120)   NOT NULL,
  ConstantValue     DECIMAL(18,4)  NOT NULL,
  SourceName        NVARCHAR(60)    NULL,
  IsActive          BIT        NOT NULL DEFAULT 1,
  CreatedAt         DATETIME2(0)      NOT NULL DEFAULT SYSUTCDATETIME(),
  UpdatedAt         DATETIME2(0)      NOT NULL DEFAULT SYSUTCDATETIME(),
  CreatedByUserId   INT            NULL,
  UpdatedByUserId   INT            NULL,
  RowVer            INT            NOT NULL DEFAULT 1,
  CONSTRAINT UQ_hr_PayrollConstant UNIQUE (CompanyId, ConstantCode),
  CONSTRAINT FK_hr_PayrollConstant_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId),
  CONSTRAINT FK_hr_PayrollConstant_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
  CONSTRAINT FK_hr_PayrollConstant_UpdatedBy FOREIGN KEY (UpdatedByUserId) REFERENCES sec.[User](UserId)
);
GO

IF OBJECT_ID('rest.MenuEnvironment', 'U') IS NULL
CREATE TABLE rest.MenuEnvironment (
  MenuEnvironmentId BIGINT IDENTITY(1,1) PRIMARY KEY,
  CompanyId          INT          NOT NULL,
  BranchId           INT          NOT NULL,
  EnvironmentCode    NVARCHAR(30)  NOT NULL,
  EnvironmentName    NVARCHAR(120) NOT NULL,
  ColorHex           NVARCHAR(10)  NULL,
  SortOrder          INT          NOT NULL DEFAULT 0,
  IsActive           BIT      NOT NULL DEFAULT 1,
  CreatedAt          DATETIME2(0)    NOT NULL DEFAULT SYSUTCDATETIME(),
  UpdatedAt          DATETIME2(0)    NOT NULL DEFAULT SYSUTCDATETIME(),
  CreatedByUserId    INT          NULL,
  UpdatedByUserId    INT          NULL,
  RowVer             INT          NOT NULL DEFAULT 1,
  CONSTRAINT UQ_rest_MenuEnvironment UNIQUE (CompanyId, BranchId, EnvironmentCode),
  CONSTRAINT FK_rest_MenuEnvironment_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId),
  CONSTRAINT FK_rest_MenuEnvironment_Branch FOREIGN KEY (BranchId) REFERENCES cfg.Branch(BranchId),
  CONSTRAINT FK_rest_MenuEnvironment_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
  CONSTRAINT FK_rest_MenuEnvironment_UpdatedBy FOREIGN KEY (UpdatedByUserId) REFERENCES sec.[User](UserId)
);
GO

IF OBJECT_ID('rest.MenuCategory', 'U') IS NULL
CREATE TABLE rest.MenuCategory (
  MenuCategoryId   BIGINT IDENTITY(1,1) PRIMARY KEY,
  CompanyId        INT          NOT NULL,
  BranchId         INT          NOT NULL,
  CategoryCode     NVARCHAR(30)  NOT NULL,
  CategoryName     NVARCHAR(120) NOT NULL,
  DescriptionText  NVARCHAR(250) NULL,
  ColorHex         NVARCHAR(10)  NULL,
  SortOrder        INT          NOT NULL DEFAULT 0,
  IsActive         BIT      NOT NULL DEFAULT 1,
  CreatedAt        DATETIME2(0)    NOT NULL DEFAULT SYSUTCDATETIME(),
  UpdatedAt        DATETIME2(0)    NOT NULL DEFAULT SYSUTCDATETIME(),
  CreatedByUserId  INT          NULL,
  UpdatedByUserId  INT          NULL,
  RowVer           INT          NOT NULL DEFAULT 1,
  CONSTRAINT UQ_rest_MenuCategory UNIQUE (CompanyId, BranchId, CategoryCode),
  CONSTRAINT FK_rest_MenuCategory_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId),
  CONSTRAINT FK_rest_MenuCategory_Branch FOREIGN KEY (BranchId) REFERENCES cfg.Branch(BranchId),
  CONSTRAINT FK_rest_MenuCategory_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
  CONSTRAINT FK_rest_MenuCategory_UpdatedBy FOREIGN KEY (UpdatedByUserId) REFERENCES sec.[User](UserId)
);
GO

IF OBJECT_ID('rest.MenuProduct', 'U') IS NULL
CREATE TABLE rest.MenuProduct (
  MenuProductId      BIGINT IDENTITY(1,1) PRIMARY KEY,
  CompanyId          INT            NOT NULL,
  BranchId           INT            NOT NULL,
  ProductCode        NVARCHAR(40)    NOT NULL,
  ProductName        NVARCHAR(200)   NOT NULL,
  DescriptionText    NVARCHAR(500)   NULL,
  MenuCategoryId     BIGINT         NULL,
  PriceAmount        DECIMAL(18,2)  NOT NULL DEFAULT 0,
  EstimatedCost      DECIMAL(18,2)  NOT NULL DEFAULT 0,
  TaxRatePercent     DECIMAL(9,4)   NOT NULL DEFAULT 16,
  IsComposite        BIT        NOT NULL DEFAULT 0,
  PrepMinutes        INT            NOT NULL DEFAULT 0,
  ImageUrl           NVARCHAR(500)   NULL,
  IsDailySuggestion  BIT        NOT NULL DEFAULT 0,
  IsAvailable        BIT        NOT NULL DEFAULT 1,
  InventoryProductId BIGINT         NULL,
  IsActive           BIT        NOT NULL DEFAULT 1,
  CreatedAt          DATETIME2(0)      NOT NULL DEFAULT SYSUTCDATETIME(),
  UpdatedAt          DATETIME2(0)      NOT NULL DEFAULT SYSUTCDATETIME(),
  CreatedByUserId    INT            NULL,
  UpdatedByUserId    INT            NULL,
  RowVer             INT            NOT NULL DEFAULT 1,
  CONSTRAINT UQ_rest_MenuProduct UNIQUE (CompanyId, BranchId, ProductCode),
  CONSTRAINT FK_rest_MenuProduct_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId),
  CONSTRAINT FK_rest_MenuProduct_Branch FOREIGN KEY (BranchId) REFERENCES cfg.Branch(BranchId),
  CONSTRAINT FK_rest_MenuProduct_Category FOREIGN KEY (MenuCategoryId) REFERENCES rest.MenuCategory(MenuCategoryId),
  CONSTRAINT FK_rest_MenuProduct_InventoryProduct FOREIGN KEY (InventoryProductId) REFERENCES mstr.Product(ProductId),
  CONSTRAINT FK_rest_MenuProduct_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
  CONSTRAINT FK_rest_MenuProduct_UpdatedBy FOREIGN KEY (UpdatedByUserId) REFERENCES sec.[User](UserId)
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_rest_MenuProduct_Search')
  CREATE INDEX IX_rest_MenuProduct_Search ON rest.MenuProduct (CompanyId, BranchId, IsActive, IsAvailable, ProductCode, ProductName);
GO

IF OBJECT_ID('rest.MenuComponent', 'U') IS NULL
CREATE TABLE rest.MenuComponent (
  MenuComponentId  BIGINT IDENTITY(1,1) PRIMARY KEY,
  MenuProductId    BIGINT       NOT NULL,
  ComponentName    NVARCHAR(120) NOT NULL,
  IsRequired       BIT      NOT NULL DEFAULT 0,
  SortOrder        INT          NOT NULL DEFAULT 0,
  IsActive         BIT      NOT NULL DEFAULT 1,
  CreatedAt        DATETIME2(0)    NOT NULL DEFAULT SYSUTCDATETIME(),
  UpdatedAt        DATETIME2(0)    NOT NULL DEFAULT SYSUTCDATETIME(),
  CONSTRAINT FK_rest_MenuComponent_Product FOREIGN KEY (MenuProductId) REFERENCES rest.MenuProduct(MenuProductId) ON DELETE CASCADE
);
GO

IF OBJECT_ID('rest.MenuOption', 'U') IS NULL
CREATE TABLE rest.MenuOption (
  MenuOptionId     BIGINT IDENTITY(1,1) PRIMARY KEY,
  MenuComponentId  BIGINT         NOT NULL,
  OptionName       NVARCHAR(120)   NOT NULL,
  ExtraPrice       DECIMAL(18,2)  NOT NULL DEFAULT 0,
  SortOrder        INT            NOT NULL DEFAULT 0,
  IsActive         BIT        NOT NULL DEFAULT 1,
  CreatedAt        DATETIME2(0)      NOT NULL DEFAULT SYSUTCDATETIME(),
  UpdatedAt        DATETIME2(0)      NOT NULL DEFAULT SYSUTCDATETIME(),
  CONSTRAINT FK_rest_MenuOption_Component FOREIGN KEY (MenuComponentId) REFERENCES rest.MenuComponent(MenuComponentId) ON DELETE CASCADE
);
GO

IF OBJECT_ID('rest.MenuRecipe', 'U') IS NULL
CREATE TABLE rest.MenuRecipe (
  MenuRecipeId        BIGINT IDENTITY(1,1) PRIMARY KEY,
  MenuProductId       BIGINT         NOT NULL,
  IngredientProductId BIGINT         NOT NULL,
  Quantity            DECIMAL(18,4)  NOT NULL,
  UnitCode            NVARCHAR(20)    NULL,
  Notes               NVARCHAR(200)   NULL,
  IsActive            BIT        NOT NULL DEFAULT 1,
  CreatedAt           DATETIME2(0)      NOT NULL DEFAULT SYSUTCDATETIME(),
  UpdatedAt           DATETIME2(0)      NOT NULL DEFAULT SYSUTCDATETIME(),
  CONSTRAINT FK_rest_MenuRecipe_MenuProduct FOREIGN KEY (MenuProductId) REFERENCES rest.MenuProduct(MenuProductId) ON DELETE CASCADE,
  CONSTRAINT FK_rest_MenuRecipe_Ingredient FOREIGN KEY (IngredientProductId) REFERENCES mstr.Product(ProductId)
);
GO

IF OBJECT_ID('rest.Purchase', 'U') IS NULL
CREATE TABLE rest.Purchase (
  PurchaseId       BIGINT IDENTITY(1,1) PRIMARY KEY,
  CompanyId        INT            NOT NULL,
  BranchId         INT            NOT NULL,
  PurchaseNumber   NVARCHAR(30)    NOT NULL,
  SupplierId       BIGINT         NULL,
  PurchaseDate     DATETIME2(0)      NOT NULL DEFAULT SYSUTCDATETIME(),
  [Status]           NVARCHAR(20)    NOT NULL DEFAULT 'PENDIENTE',
  SubtotalAmount   DECIMAL(18,2)  NOT NULL DEFAULT 0,
  TaxAmount        DECIMAL(18,2)  NOT NULL DEFAULT 0,
  TotalAmount      DECIMAL(18,2)  NOT NULL DEFAULT 0,
  Notes            NVARCHAR(500)   NULL,
  CreatedAt        DATETIME2(0)      NOT NULL DEFAULT SYSUTCDATETIME(),
  UpdatedAt        DATETIME2(0)      NOT NULL DEFAULT SYSUTCDATETIME(),
  CreatedByUserId  INT            NULL,
  UpdatedByUserId  INT            NULL,
  RowVer           INT            NOT NULL DEFAULT 1,
  CONSTRAINT UQ_rest_Purchase UNIQUE (CompanyId, BranchId, PurchaseNumber),
  CONSTRAINT FK_rest_Purchase_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId),
  CONSTRAINT FK_rest_Purchase_Branch FOREIGN KEY (BranchId) REFERENCES cfg.Branch(BranchId),
  CONSTRAINT FK_rest_Purchase_Supplier FOREIGN KEY (SupplierId) REFERENCES mstr.Supplier(SupplierId),
  CONSTRAINT FK_rest_Purchase_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
  CONSTRAINT FK_rest_Purchase_UpdatedBy FOREIGN KEY (UpdatedByUserId) REFERENCES sec.[User](UserId)
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_rest_Purchase_Search')
  CREATE INDEX IX_rest_Purchase_Search ON rest.Purchase (CompanyId, BranchId, PurchaseDate DESC, [Status]);
GO

IF OBJECT_ID('rest.PurchaseLine', 'U') IS NULL
CREATE TABLE rest.PurchaseLine (
  PurchaseLineId      BIGINT IDENTITY(1,1) PRIMARY KEY,
  PurchaseId          BIGINT         NOT NULL,
  IngredientProductId BIGINT         NULL,
  DescriptionText     NVARCHAR(200)   NOT NULL,
  Quantity            DECIMAL(18,4)  NOT NULL,
  UnitPrice           DECIMAL(18,2)  NOT NULL,
  TaxRatePercent      DECIMAL(9,4)   NOT NULL,
  SubtotalAmount      DECIMAL(18,2)  NOT NULL,
  CreatedAt           DATETIME2(0)      NOT NULL DEFAULT SYSUTCDATETIME(),
  UpdatedAt           DATETIME2(0)      NOT NULL DEFAULT SYSUTCDATETIME(),
  CONSTRAINT FK_rest_PurchaseLine_Purchase FOREIGN KEY (PurchaseId) REFERENCES rest.Purchase(PurchaseId) ON DELETE CASCADE,
  CONSTRAINT FK_rest_PurchaseLine_Ingredient FOREIGN KEY (IngredientProductId) REFERENCES mstr.Product(ProductId)
);
GO

IF OBJECT_ID('hr.PayrollBatch', 'U') IS NULL
CREATE TABLE hr.PayrollBatch (
  BatchId         BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
  CompanyId       INT NOT NULL,
  PayrollCode     NVARCHAR(20) NOT NULL,
  FromDate        DATE NOT NULL,
  ToDate          DATE NOT NULL,
  [Status]          NVARCHAR(20) NOT NULL DEFAULT 'DRAFT',
  Notes           NVARCHAR(500) NULL,
  CreatedAt       DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
  UpdatedAt       DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
  CreatedByUserId INT NULL,
  UpdatedByUserId INT NULL,
  IsDeleted       BIT NOT NULL DEFAULT 0,
  DeletedAt       DATETIME2(0) NULL,
  DeletedByUserId INT NULL,
  RowVer          INT NOT NULL DEFAULT 1,
  CONSTRAINT FK_hr_PayrollBatch_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId)
);
GO

IF OBJECT_ID('hr.PayrollBatchLine', 'U') IS NULL
CREATE TABLE hr.PayrollBatchLine (
  LineId          BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
  BatchId         BIGINT NOT NULL,
  EmployeeId      BIGINT NULL,
  EmployeeCode    NVARCHAR(24) NOT NULL,
  EmployeeName    NVARCHAR(200) NOT NULL,
  ConceptCode     NVARCHAR(20) NOT NULL,
  ConceptName     NVARCHAR(100) NOT NULL,
  ConceptType     NVARCHAR(20) NOT NULL,
  Quantity        DECIMAL(18,4) NOT NULL DEFAULT 1,
  Amount          DECIMAL(18,2) NOT NULL DEFAULT 0,
  Total           DECIMAL(18,2) NOT NULL DEFAULT 0,
  IsModified      BIT NOT NULL DEFAULT 0,
  Notes           NVARCHAR(500) NULL,
  UpdatedAt       DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
  CONSTRAINT FK_hr_PayrollBatchLine_Batch FOREIGN KEY (BatchId) REFERENCES hr.PayrollBatch(BatchId) ON DELETE CASCADE
);
GO

IF OBJECT_ID('hr.DocumentTemplate', 'U') IS NULL
CREATE TABLE hr.DocumentTemplate (
  TemplateId      BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
  CompanyId       INT NOT NULL,
  TemplateCode    NVARCHAR(50) NOT NULL,
  TemplateName    NVARCHAR(200) NOT NULL,
  TemplateType    NVARCHAR(30) NOT NULL DEFAULT 'PAYROLL',
  CountryCode     NCHAR(2) NOT NULL DEFAULT 'VE',
  PayrollCode     NVARCHAR(20) NULL,
  ContentMD       NVARCHAR(MAX) NOT NULL DEFAULT '',
  IsDefault       BIT NOT NULL DEFAULT 0,
  IsActive        BIT NOT NULL DEFAULT 1,
  CreatedAt       DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
  UpdatedAt       DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
  CreatedByUserId INT NULL,
  UpdatedByUserId INT NULL,
  IsDeleted       BIT NOT NULL DEFAULT 0,
  DeletedAt       DATETIME2(0) NULL,
  DeletedByUserId INT NULL,
  RowVer          INT NOT NULL DEFAULT 1,
  CONSTRAINT UQ_hr_DocumentTemplate UNIQUE (CompanyId, TemplateCode),
  CONSTRAINT FK_hr_DocumentTemplate_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId)
);
GO

IF OBJECT_ID('mstr.Category', 'U') IS NULL
CREATE TABLE mstr.Category (
  CategoryId      INT IDENTITY(1,1) PRIMARY KEY,
  CompanyId       INT           NOT NULL DEFAULT 1,
  CategoryCode    NVARCHAR(20)   NULL,
  CategoryName    NVARCHAR(100)  NOT NULL,
  Description     NVARCHAR(500)  NULL,
  UserCode        NVARCHAR(20)   NULL,
  IsActive        BIT       NOT NULL DEFAULT 1,
  IsDeleted       BIT       NOT NULL DEFAULT 0,
  CreatedAt       DATETIME2(0)     NOT NULL DEFAULT SYSUTCDATETIME(),
  UpdatedAt       DATETIME2(0)     NOT NULL DEFAULT SYSUTCDATETIME(),
  CreatedByUserId INT           NULL,
  UpdatedByUserId INT           NULL
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UQ_Category_CompanyName')
  CREATE UNIQUE INDEX UQ_Category_CompanyName ON mstr.Category (CompanyId, CategoryName) WHERE IsDeleted = 0;
GO

IF OBJECT_ID('mstr.Brand', 'U') IS NULL
CREATE TABLE mstr.Brand (
  BrandId         INT IDENTITY(1,1) PRIMARY KEY,
  CompanyId       INT           NOT NULL DEFAULT 1,
  BrandCode       NVARCHAR(20)   NULL,
  BrandName       NVARCHAR(100)  NOT NULL,
  Description     NVARCHAR(500)  NULL,
  UserCode        NVARCHAR(20)   NULL,
  IsActive        BIT       NOT NULL DEFAULT 1,
  IsDeleted       BIT       NOT NULL DEFAULT 0,
  CreatedAt       DATETIME2(0)     NOT NULL DEFAULT SYSUTCDATETIME(),
  UpdatedAt       DATETIME2(0)     NOT NULL DEFAULT SYSUTCDATETIME(),
  CreatedByUserId INT           NULL,
  UpdatedByUserId INT           NULL
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UQ_Brand_CompanyName')
  CREATE UNIQUE INDEX UQ_Brand_CompanyName ON mstr.Brand (CompanyId, BrandName) WHERE IsDeleted = 0;
GO

IF OBJECT_ID('mstr.Warehouse', 'U') IS NULL
CREATE TABLE mstr.Warehouse (
  WarehouseId     INT IDENTITY(1,1) PRIMARY KEY,
  CompanyId       INT           NOT NULL DEFAULT 1,
  BranchId        INT           NULL,
  WarehouseCode   NVARCHAR(20)   NOT NULL,
  Description     NVARCHAR(200)  NOT NULL,
  WarehouseType   NVARCHAR(20)   NOT NULL DEFAULT 'PRINCIPAL',
  AddressLine     NVARCHAR(250)  NULL,
  IsActive        BIT       NOT NULL DEFAULT 1,
  IsDeleted       BIT       NOT NULL DEFAULT 0,
  CreatedAt       DATETIME2(0)     NOT NULL DEFAULT SYSUTCDATETIME(),
  UpdatedAt       DATETIME2(0)     NOT NULL DEFAULT SYSUTCDATETIME(),
  CreatedByUserId INT           NULL,
  UpdatedByUserId INT           NULL
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UQ_Warehouse_CompanyCode')
  CREATE UNIQUE INDEX UQ_Warehouse_CompanyCode ON mstr.Warehouse (CompanyId, WarehouseCode) WHERE IsDeleted = 0;
GO

IF OBJECT_ID('mstr.ProductLine', 'U') IS NULL
CREATE TABLE mstr.ProductLine (
  LineId          INT IDENTITY(1,1) PRIMARY KEY,
  CompanyId       INT           NOT NULL DEFAULT 1,
  LineCode        NVARCHAR(20)   NOT NULL,
  LineName        NVARCHAR(100)  NOT NULL,
  Description     NVARCHAR(500)  NULL,
  IsActive        BIT       NOT NULL DEFAULT 1,
  IsDeleted       BIT       NOT NULL DEFAULT 0,
  CreatedAt       DATETIME2(0)     NOT NULL DEFAULT SYSUTCDATETIME(),
  UpdatedAt       DATETIME2(0)     NOT NULL DEFAULT SYSUTCDATETIME(),
  CreatedByUserId INT           NULL,
  UpdatedByUserId INT           NULL
);
GO

IF OBJECT_ID('mstr.ProductClass', 'U') IS NULL
CREATE TABLE mstr.ProductClass (
  ClassId         INT IDENTITY(1,1) PRIMARY KEY,
  CompanyId       INT           NOT NULL DEFAULT 1,
  ClassCode       NVARCHAR(20)   NOT NULL,
  ClassName       NVARCHAR(100)  NOT NULL,
  Description     NVARCHAR(500)  NULL,
  IsActive        BIT       NOT NULL DEFAULT 1,
  IsDeleted       BIT       NOT NULL DEFAULT 0,
  CreatedAt       DATETIME2(0)     NOT NULL DEFAULT SYSUTCDATETIME(),
  UpdatedAt       DATETIME2(0)     NOT NULL DEFAULT SYSUTCDATETIME(),
  CreatedByUserId INT           NULL,
  UpdatedByUserId INT           NULL
);
GO

IF OBJECT_ID('mstr.ProductGroup', 'U') IS NULL
CREATE TABLE mstr.ProductGroup (
  GroupId         INT IDENTITY(1,1) PRIMARY KEY,
  CompanyId       INT           NOT NULL DEFAULT 1,
  GroupCode       NVARCHAR(20)   NOT NULL,
  GroupName       NVARCHAR(100)  NOT NULL,
  Description     NVARCHAR(500)  NULL,
  IsActive        BIT       NOT NULL DEFAULT 1,
  IsDeleted       BIT       NOT NULL DEFAULT 0,
  CreatedAt       DATETIME2(0)     NOT NULL DEFAULT SYSUTCDATETIME(),
  UpdatedAt       DATETIME2(0)     NOT NULL DEFAULT SYSUTCDATETIME(),
  CreatedByUserId INT           NULL,
  UpdatedByUserId INT           NULL
);
GO

IF OBJECT_ID('mstr.ProductType', 'U') IS NULL
CREATE TABLE mstr.ProductType (
  TypeId          INT IDENTITY(1,1) PRIMARY KEY,
  CompanyId       INT           NOT NULL DEFAULT 1,
  TypeCode        NVARCHAR(20)   NOT NULL,
  TypeName        NVARCHAR(100)  NOT NULL,
  CategoryCode    NVARCHAR(50)   NULL,
  Description     NVARCHAR(500)  NULL,
  IsActive        BIT       NOT NULL DEFAULT 1,
  IsDeleted       BIT       NOT NULL DEFAULT 0,
  CreatedAt       DATETIME2(0)     NOT NULL DEFAULT SYSUTCDATETIME(),
  UpdatedAt       DATETIME2(0)     NOT NULL DEFAULT SYSUTCDATETIME(),
  CreatedByUserId INT           NULL,
  UpdatedByUserId INT           NULL
);
GO

IF OBJECT_ID('mstr.UnitOfMeasure', 'U') IS NULL
CREATE TABLE mstr.UnitOfMeasure (
  UnitId          INT IDENTITY(1,1) PRIMARY KEY,
  CompanyId       INT           NOT NULL DEFAULT 1,
  UnitCode        NVARCHAR(20)   NOT NULL,
  Description     NVARCHAR(100)  NOT NULL,
  Symbol          NVARCHAR(10)   NULL,
  IsActive        BIT       NOT NULL DEFAULT 1,
  IsDeleted       BIT       NOT NULL DEFAULT 0,
  CreatedAt       DATETIME2(0)     NOT NULL DEFAULT SYSUTCDATETIME(),
  UpdatedAt       DATETIME2(0)     NOT NULL DEFAULT SYSUTCDATETIME(),
  CreatedByUserId INT           NULL,
  UpdatedByUserId INT           NULL
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UQ_UnitOfMeasure_CompanyCode')
  CREATE UNIQUE INDEX UQ_UnitOfMeasure_CompanyCode ON mstr.UnitOfMeasure (CompanyId, UnitCode) WHERE IsDeleted = 0;
GO

IF OBJECT_ID('mstr.Seller', 'U') IS NULL
CREATE TABLE mstr.Seller (
  SellerId        INT IDENTITY(1,1) PRIMARY KEY,
  CompanyId       INT           NOT NULL DEFAULT 1,
  SellerCode      NVARCHAR(10)   NOT NULL,
  SellerName      NVARCHAR(120)  NOT NULL,
  Commission      DECIMAL(5,2)  NOT NULL DEFAULT 0,
  Address         NVARCHAR(250)  NULL,
  Phone           NVARCHAR(60)   NULL,
  Email           NVARCHAR(150)  NULL,
  SellerType      NVARCHAR(20)   NOT NULL DEFAULT 'INTERNO',
  IsActive        BIT       NOT NULL DEFAULT 1,
  IsDeleted       BIT       NOT NULL DEFAULT 0,
  CreatedAt       DATETIME2(0)     NOT NULL DEFAULT SYSUTCDATETIME(),
  UpdatedAt       DATETIME2(0)     NOT NULL DEFAULT SYSUTCDATETIME(),
  CreatedByUserId INT           NULL,
  UpdatedByUserId INT           NULL
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UQ_Seller_CompanyCode')
  CREATE UNIQUE INDEX UQ_Seller_CompanyCode ON mstr.Seller (CompanyId, SellerCode) WHERE IsDeleted = 0;
GO

IF OBJECT_ID('mstr.CostCenter', 'U') IS NULL
CREATE TABLE mstr.CostCenter (
  CostCenterId    INT IDENTITY(1,1) PRIMARY KEY,
  CompanyId       INT           NOT NULL DEFAULT 1,
  CostCenterCode  NVARCHAR(20)   NOT NULL,
  CostCenterName  NVARCHAR(100)  NOT NULL,
  Description     NVARCHAR(500)  NULL,
  IsActive        BIT       NOT NULL DEFAULT 1,
  IsDeleted       BIT       NOT NULL DEFAULT 0,
  CreatedAt       DATETIME2(0)     NOT NULL DEFAULT SYSUTCDATETIME(),
  UpdatedAt       DATETIME2(0)     NOT NULL DEFAULT SYSUTCDATETIME(),
  CreatedByUserId INT           NULL,
  UpdatedByUserId INT           NULL
);
GO

IF OBJECT_ID('mstr.TaxRetention', 'U') IS NULL
CREATE TABLE mstr.TaxRetention (
  RetentionId     INT IDENTITY(1,1) PRIMARY KEY,
  CompanyId       INT           NOT NULL DEFAULT 1,
  RetentionCode   NVARCHAR(20)   NOT NULL,
  Description     NVARCHAR(200)  NOT NULL,
  RetentionType   NVARCHAR(20)   NOT NULL DEFAULT 'ISLR',
  RetentionRate   DECIMAL(8,4)  NOT NULL DEFAULT 0,
  CountryCode     NCHAR(2)       NOT NULL DEFAULT 'VE',
  IsActive        BIT       NOT NULL DEFAULT 1,
  IsDeleted       BIT       NOT NULL DEFAULT 0,
  CreatedAt       DATETIME2(0)     NOT NULL DEFAULT SYSUTCDATETIME(),
  UpdatedAt       DATETIME2(0)     NOT NULL DEFAULT SYSUTCDATETIME(),
  CreatedByUserId INT           NULL,
  UpdatedByUserId INT           NULL
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UQ_TaxRetention_CompanyCode')
  CREATE UNIQUE INDEX UQ_TaxRetention_CompanyCode ON mstr.TaxRetention (CompanyId, RetentionCode) WHERE IsDeleted = 0;
GO

IF OBJECT_ID('mstr.InventoryMovement', 'U') IS NULL
CREATE TABLE mstr.InventoryMovement (
  MovementId      BIGINT IDENTITY(1,1) PRIMARY KEY,
  CompanyId       INT            NOT NULL DEFAULT 1,
  BranchId        INT            NULL,
  ProductCode     NVARCHAR(80)    NOT NULL,
  ProductName     NVARCHAR(250)   NULL,
  DocumentRef     NVARCHAR(60)    NULL,
  MovementType    NVARCHAR(20)    NOT NULL DEFAULT 'ENTRADA',
  MovementDate    DATE           NOT NULL DEFAULT SYSUTCDATETIME(),
  Quantity        DECIMAL(18,4)  NOT NULL DEFAULT 0,
  UnitCost        DECIMAL(18,4)  NOT NULL DEFAULT 0,
  TotalCost       DECIMAL(18,4)  NOT NULL DEFAULT 0,
  Notes           NVARCHAR(300)   NULL,
  IsDeleted       BIT        NOT NULL DEFAULT 0,
  CreatedAt       DATETIME2(0)      NOT NULL DEFAULT SYSUTCDATETIME(),
  UpdatedAt       DATETIME2(0)      NOT NULL DEFAULT SYSUTCDATETIME(),
  CreatedByUserId INT            NULL,
  UpdatedByUserId INT            NULL
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_InventoryMovement_ProductDate')
  CREATE INDEX IX_InventoryMovement_ProductDate ON mstr.InventoryMovement (ProductCode, MovementDate DESC) WHERE IsDeleted = 0;
GO

IF OBJECT_ID('mstr.InventoryPeriodSummary', 'U') IS NULL
CREATE TABLE mstr.InventoryPeriodSummary (
  SummaryId   BIGINT IDENTITY(1,1) PRIMARY KEY,
  CompanyId   INT            NOT NULL DEFAULT 1,
  Period      NCHAR(6)        NOT NULL,  -- YYYYMM
  ProductCode NVARCHAR(80)    NOT NULL,
  OpeningQty  DECIMAL(18,4)  NOT NULL DEFAULT 0,
  InboundQty  DECIMAL(18,4)  NOT NULL DEFAULT 0,
  OutboundQty DECIMAL(18,4)  NOT NULL DEFAULT 0,
  ClosingQty  DECIMAL(18,4)  NOT NULL DEFAULT 0,
  SummaryDate DATE           NOT NULL DEFAULT SYSUTCDATETIME(),
  IsClosed    BIT        NOT NULL DEFAULT 0,
  CreatedAt   DATETIME2(0)      NOT NULL DEFAULT SYSUTCDATETIME(),
  UpdatedAt   DATETIME2(0)      NOT NULL DEFAULT SYSUTCDATETIME()
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UQ_InventoryPeriodSummary_Key')
  CREATE UNIQUE INDEX UQ_InventoryPeriodSummary_Key ON mstr.InventoryPeriodSummary (CompanyId, Period, ProductCode);
GO

IF OBJECT_ID('mstr.SupplierLine', 'U') IS NULL
CREATE TABLE mstr.SupplierLine (
  SupplierLineId INT IDENTITY(1,1) PRIMARY KEY,
  CompanyId       INT           NOT NULL DEFAULT 1,
  LineCode        NVARCHAR(20)   NOT NULL,
  LineName        NVARCHAR(100)  NOT NULL,
  Description     NVARCHAR(500)  NULL,
  IsActive        BIT       NOT NULL DEFAULT 1,
  IsDeleted       BIT       NOT NULL DEFAULT 0,
  CreatedAt       DATETIME2(0)     NOT NULL DEFAULT SYSUTCDATETIME(),
  UpdatedAt       DATETIME2(0)     NOT NULL DEFAULT SYSUTCDATETIME()
);
GO

IF OBJECT_ID('cfg.Holiday', 'U') IS NULL
CREATE TABLE cfg.Holiday (
  HolidayId    INT IDENTITY(1,1) PRIMARY KEY,
  CountryCode  NCHAR(2)      NOT NULL DEFAULT 'VE',
  HolidayDate  DATE         NOT NULL,
  HolidayName  NVARCHAR(100) NOT NULL,
  IsRecurring  BIT      NOT NULL DEFAULT 0,
  IsActive     BIT      NOT NULL DEFAULT 1,
  CreatedAt    DATETIME2(0)    NOT NULL DEFAULT SYSUTCDATETIME()
);
GO

IF OBJECT_ID('cfg.DocumentSequence', 'U') IS NULL
CREATE TABLE cfg.DocumentSequence (
  SequenceId    INT IDENTITY(1,1) PRIMARY KEY,
  CompanyId     INT          NOT NULL DEFAULT 1,
  BranchId      INT          NULL,
  DocumentType  NVARCHAR(20)  NOT NULL,
  Prefix        NVARCHAR(10)  NULL,
  Suffix        NVARCHAR(10)  NULL,
  CurrentNumber BIGINT       NOT NULL DEFAULT 1,
  PaddingLength INT          NOT NULL DEFAULT 8,
  IsActive      BIT      NOT NULL DEFAULT 1,
  CreatedAt     DATETIME2(0)    NOT NULL DEFAULT SYSUTCDATETIME(),
  UpdatedAt     DATETIME2(0)    NOT NULL DEFAULT SYSUTCDATETIME()
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UQ_DocumentSequence_NoBranch')
  CREATE UNIQUE INDEX UQ_DocumentSequence_NoBranch ON cfg.DocumentSequence (CompanyId, DocumentType) WHERE BranchId IS NULL;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UQ_DocumentSequence_Branch')
  CREATE UNIQUE INDEX UQ_DocumentSequence_Branch ON cfg.DocumentSequence (CompanyId, BranchId, DocumentType) WHERE BranchId IS NOT NULL;
GO

IF OBJECT_ID('cfg.Currency', 'U') IS NULL
CREATE TABLE cfg.Currency (
  CurrencyId   INT IDENTITY(1,1) PRIMARY KEY,
  CurrencyCode NCHAR(3)      NOT NULL,
  CurrencyName NVARCHAR(60)  NOT NULL,
  Symbol       NVARCHAR(10)  NULL,
  IsActive     BIT      NOT NULL DEFAULT 1,
  CreatedAt    DATETIME2(0)    NOT NULL DEFAULT SYSUTCDATETIME(),
  CONSTRAINT UQ_Currency_Code UNIQUE (CurrencyCode)
);
GO

IF OBJECT_ID('cfg.ReportTemplate', 'U') IS NULL
CREATE TABLE cfg.ReportTemplate (
  ReportId    INT IDENTITY(1,1) PRIMARY KEY,
  CompanyId   INT           NOT NULL DEFAULT 1,
  ReportCode  NVARCHAR(50)   NOT NULL,
  ReportName  NVARCHAR(150)  NOT NULL,
  ReportType  NVARCHAR(20)   NOT NULL DEFAULT 'REPORT',
  QueryText   NVARCHAR(MAX)          NULL,
  Parameters  NVARCHAR(MAX)          NULL,
  IsActive    BIT       NOT NULL DEFAULT 1,
  IsDeleted   BIT       NOT NULL DEFAULT 0,
  CreatedAt   DATETIME2(0)     NOT NULL DEFAULT SYSUTCDATETIME(),
  UpdatedAt   DATETIME2(0)     NOT NULL DEFAULT SYSUTCDATETIME()
);
GO

IF OBJECT_ID('cfg.CompanyProfile', 'U') IS NULL
CREATE TABLE cfg.CompanyProfile (
  ProfileId   INT IDENTITY(1,1) PRIMARY KEY,
  CompanyId   INT           NOT NULL,
  Phone       NVARCHAR(60)   NULL,
  AddressLine NVARCHAR(250)  NULL,
  NitCode     NVARCHAR(50)   NULL,
  AltFiscalId NVARCHAR(50)   NULL,
  WebSite     NVARCHAR(150)  NULL,
  LogoBase64  NVARCHAR(MAX)          NULL,
  Notes       NVARCHAR(500)  NULL,
  UpdatedAt   DATETIME2(0)     NOT NULL DEFAULT SYSUTCDATETIME(),
  CONSTRAINT FK_CompanyProfile_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId)
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UQ_CompanyProfile_CompanyId')
  CREATE UNIQUE INDEX UQ_CompanyProfile_CompanyId ON cfg.CompanyProfile (CompanyId);
GO

IF OBJECT_ID('sec.UserModuleAccess', 'U') IS NULL
CREATE TABLE sec.UserModuleAccess (
  AccessId    INT IDENTITY(1,1) PRIMARY KEY,
  UserCode    NVARCHAR(20)  NOT NULL,
  ModuleCode  NVARCHAR(60)  NOT NULL,
  IsAllowed   BIT      NOT NULL DEFAULT 1,
  CreatedAt   DATETIME2(0)    NOT NULL DEFAULT SYSUTCDATETIME(),
  UpdatedAt   DATETIME2(0)    NOT NULL DEFAULT SYSUTCDATETIME(),
  CONSTRAINT UQ_UserModuleAccess UNIQUE (UserCode, ModuleCode)
);
GO

IF OBJECT_ID('pay.PaymentMethods', 'U') IS NULL
CREATE TABLE pay.PaymentMethods (
  Id              INT IDENTITY(1,1) PRIMARY KEY,
  Code            NVARCHAR(30)  NOT NULL,
  [Name]            NVARCHAR(100) NOT NULL,
  Category        NVARCHAR(30)  NOT NULL,
  CountryCode     NCHAR(2)      NULL,
  IconName        NVARCHAR(50)  NULL,
  RequiresGateway BIT      DEFAULT 0,
  IsActive        BIT      DEFAULT 1,
  SortOrder       INT          DEFAULT 0,
  CreatedAt       DATETIME2(0)    DEFAULT SYSUTCDATETIME(),
  CONSTRAINT UQ_PayMethod UNIQUE (Code, CountryCode)
);
GO

IF OBJECT_ID('pay.PaymentProviders', 'U') IS NULL
CREATE TABLE pay.PaymentProviders (
  Id              INT IDENTITY(1,1) PRIMARY KEY,
  Code            NVARCHAR(30)  NOT NULL UNIQUE,
  [Name]            NVARCHAR(150) NOT NULL,
  CountryCode     NCHAR(2)      NULL,
  ProviderType    NVARCHAR(30)  NOT NULL,
  BaseUrlSandbox  NVARCHAR(500) NULL,
  BaseUrlProd     NVARCHAR(500) NULL,
  AuthType        NVARCHAR(30)  NULL,
  DocsUrl         NVARCHAR(500) NULL,
  LogoUrl         NVARCHAR(500) NULL,
  IsActive        BIT      DEFAULT 1,
  CreatedAt       DATETIME2(0)    DEFAULT SYSUTCDATETIME()
);
GO

IF OBJECT_ID('pay.ProviderCapabilities', 'U') IS NULL
CREATE TABLE pay.ProviderCapabilities (
  Id              INT IDENTITY(1,1) PRIMARY KEY,
  ProviderId      INT          NOT NULL REFERENCES pay.PaymentProviders(Id),
  Capability      NVARCHAR(50)  NOT NULL,
  PaymentMethod   NVARCHAR(30)  NULL,
  EndpointPath    NVARCHAR(200) NULL,
  HttpMethod      NVARCHAR(10)  DEFAULT 'POST',
  IsActive        BIT      DEFAULT 1,
  CONSTRAINT UQ_ProvCap UNIQUE (ProviderId, Capability, PaymentMethod)
);
GO

IF OBJECT_ID('pay.CompanyPaymentConfig', 'U') IS NULL
CREATE TABLE pay.CompanyPaymentConfig (
  Id              INT IDENTITY(1,1) PRIMARY KEY,
  EmpresaId       INT          NOT NULL,
  SucursalId      INT          NOT NULL DEFAULT 0,
  CountryCode     NCHAR(2)      NOT NULL,
  ProviderId      INT          NOT NULL REFERENCES pay.PaymentProviders(Id),
  Environment     NVARCHAR(10)  DEFAULT 'sandbox',
  ClientId        NVARCHAR(500) NULL,
  ClientSecret    NVARCHAR(500) NULL,
  MerchantId      NVARCHAR(100) NULL,
  TerminalId      NVARCHAR(100) NULL,
  IntegratorId    NVARCHAR(50)  NULL,
  CertificatePath NVARCHAR(500) NULL,
  ExtraConfig     NVARCHAR(MAX)         NULL,
  AutoCapture     BIT      DEFAULT 1,
  AllowRefunds    BIT      DEFAULT 1,
  MaxRefundDays   INT          DEFAULT 30,
  IsActive        BIT      DEFAULT 1,
  CreatedAt       DATETIME2(0)    DEFAULT SYSUTCDATETIME(),
  UpdatedAt       DATETIME2(0)    DEFAULT SYSUTCDATETIME(),
  CONSTRAINT UQ_CompanyPayConfig UNIQUE (EmpresaId, SucursalId, ProviderId)
);
GO

IF OBJECT_ID('pay.AcceptedPaymentMethods', 'U') IS NULL
CREATE TABLE pay.AcceptedPaymentMethods (
  Id                  INT IDENTITY(1,1) PRIMARY KEY,
  EmpresaId           INT            NOT NULL,
  SucursalId          INT            NOT NULL DEFAULT 0,
  PaymentMethodId     INT            NOT NULL REFERENCES pay.PaymentMethods(Id),
  ProviderId          INT            NULL REFERENCES pay.PaymentProviders(Id),
  AppliesToPOS        BIT        DEFAULT 1,
  AppliesToWeb        BIT        DEFAULT 1,
  AppliesToRestaurant BIT        DEFAULT 1,
  MinAmount           DECIMAL(18,2)  NULL,
  MaxAmount           DECIMAL(18,2)  NULL,
  CommissionPct       DECIMAL(5,4)   NULL,
  CommissionFixed     DECIMAL(18,2)  NULL,
  IsActive            BIT        DEFAULT 1,
  SortOrder           INT            DEFAULT 0,
  CONSTRAINT UQ_AcceptedPM UNIQUE (EmpresaId, SucursalId, PaymentMethodId, ProviderId)
);
GO

IF OBJECT_ID('pay.Transactions', 'U') IS NULL
CREATE TABLE pay.Transactions (
  Id                BIGINT IDENTITY(1,1) PRIMARY KEY,
  TransactionUUID   NVARCHAR(36)    NOT NULL UNIQUE,
  EmpresaId         INT            NOT NULL,
  SucursalId        INT            NOT NULL DEFAULT 0,
  SourceType        NVARCHAR(30)    NOT NULL,
  SourceId          INT            NULL,
  SourceNumber      NVARCHAR(50)    NULL,
  PaymentMethodCode NVARCHAR(30)    NOT NULL,
  ProviderId        INT            NULL REFERENCES pay.PaymentProviders(Id),
  Currency          NVARCHAR(3)     NOT NULL,
  Amount            DECIMAL(18,2)  NOT NULL,
  CommissionAmount  DECIMAL(18,2)  NULL,
  NetAmount         DECIMAL(18,2)  NULL,
  ExchangeRate      DECIMAL(18,6)  NULL,
  AmountInBase      DECIMAL(18,2)  NULL,
  TrxType           NVARCHAR(20)    NOT NULL,
  [Status]            NVARCHAR(20)    NOT NULL DEFAULT 'PENDING',
  GatewayTrxId      NVARCHAR(100)   NULL,
  GatewayAuthCode   NVARCHAR(50)    NULL,
  GatewayResponse   NVARCHAR(MAX)           NULL,
  GatewayMessage    NVARCHAR(500)   NULL,
  CardLastFour      NVARCHAR(4)     NULL,
  CardBrand         NVARCHAR(20)    NULL,
  MobileNumber      NVARCHAR(20)    NULL,
  BankCode          NVARCHAR(10)    NULL,
  PaymentRef        NVARCHAR(50)    NULL,
  IsReconciled      BIT        DEFAULT 0,
  ReconciledAt      DATETIME2(0)      NULL,
  ReconciliationId  BIGINT         NULL,
  StationId         NVARCHAR(50)    NULL,
  CashierId         NVARCHAR(20)    NULL,
  IpAddress         NVARCHAR(45)    NULL,
  UserAgent         NVARCHAR(500)   NULL,
  Notes             NVARCHAR(500)   NULL,
  CreatedAt         DATETIME2(0)      DEFAULT SYSUTCDATETIME(),
  UpdatedAt         DATETIME2(0)      DEFAULT SYSUTCDATETIME()
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_PayTrx_Source')
  CREATE INDEX IX_PayTrx_Source ON pay.Transactions (SourceType, SourceId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_PayTrx_Status')
  CREATE INDEX IX_PayTrx_Status ON pay.Transactions ([Status], CreatedAt);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_PayTrx_Recon')
  CREATE INDEX IX_PayTrx_Recon ON pay.Transactions (IsReconciled, ProviderId);
GO

IF OBJECT_ID('pay.ReconciliationBatches', 'U') IS NULL
CREATE TABLE pay.ReconciliationBatches (
  Id                BIGINT IDENTITY(1,1) PRIMARY KEY,
  EmpresaId         INT            NOT NULL,
  ProviderId        INT            NOT NULL REFERENCES pay.PaymentProviders(Id),
  DateFrom          DATE           NOT NULL,
  DateTo            DATE           NOT NULL,
  TotalTransactions INT            DEFAULT 0,
  TotalAmount       DECIMAL(18,2)  DEFAULT 0,
  MatchedCount      INT            DEFAULT 0,
  UnmatchedCount    INT            DEFAULT 0,
  [Status]            NVARCHAR(20)    DEFAULT 'PENDING',
  ResultJson        NVARCHAR(MAX)           NULL,
  CreatedAt         DATETIME2(0)      DEFAULT SYSUTCDATETIME(),
  CompletedAt       DATETIME2(0)      NULL,
  UserId            NVARCHAR(20)    NULL
);
GO

IF OBJECT_ID('pay.CardReaderDevices', 'U') IS NULL
CREATE TABLE pay.CardReaderDevices (
  Id               INT IDENTITY(1,1) PRIMARY KEY,
  EmpresaId        INT          NOT NULL,
  SucursalId       INT          NOT NULL DEFAULT 0,
  StationId        NVARCHAR(50)  NOT NULL,
  DeviceName       NVARCHAR(100) NOT NULL,
  DeviceType       NVARCHAR(30)  NOT NULL,
  ConnectionType   NVARCHAR(30)  NOT NULL,
  ConnectionConfig NVARCHAR(500) NULL,
  ProviderId       INT          NULL REFERENCES pay.PaymentProviders(Id),
  IsActive         BIT      DEFAULT 1,
  LastSeenAt       DATETIME2(0)    NULL,
  CreatedAt        DATETIME2(0)    DEFAULT SYSUTCDATETIME()
);
GO

IF OBJECT_ID('store.ProductReview', 'U') IS NULL
CREATE TABLE store.ProductReview (
  ReviewId      INT IDENTITY(1,1) PRIMARY KEY,
  CompanyId     INT          NOT NULL DEFAULT 1,
  ProductCode   NVARCHAR(80)  NOT NULL,
  Rating        INT          NOT NULL CHECK (Rating BETWEEN 1 AND 5),
  Title         NVARCHAR(200) NULL,
  Comment       NVARCHAR(2000) NOT NULL,
  ReviewerName  NVARCHAR(200) NOT NULL DEFAULT 'Cliente',
  ReviewerEmail NVARCHAR(150) NULL,
  IsVerified    BIT      NOT NULL DEFAULT 0,
  IsApproved    BIT      NOT NULL DEFAULT 1,
  IsDeleted     BIT      NOT NULL DEFAULT 0,
  CreatedAt     DATETIME2(0)    NOT NULL DEFAULT SYSUTCDATETIME()
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_ProductReview_Product')
  CREATE INDEX IX_ProductReview_Product ON store.ProductReview (CompanyId, ProductCode, IsDeleted, IsApproved);
GO

IF OBJECT_ID('store.ProductHighlight', 'U') IS NULL
CREATE TABLE store.ProductHighlight (
  HighlightId   INT IDENTITY(1,1) PRIMARY KEY,
  CompanyId     INT          NOT NULL DEFAULT 1,
  ProductCode   NVARCHAR(80)  NOT NULL,
  SortOrder     INT          NOT NULL DEFAULT 0,
  HighlightText NVARCHAR(500) NOT NULL,
  IsActive      BIT      NOT NULL DEFAULT 1,
  CreatedAt     DATETIME2(0)    NOT NULL DEFAULT SYSUTCDATETIME()
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_ProductHighlight_Product')
  CREATE INDEX IX_ProductHighlight_Product ON store.ProductHighlight (CompanyId, ProductCode, IsActive);
GO

IF OBJECT_ID('store.ProductSpec', 'U') IS NULL
CREATE TABLE store.ProductSpec (
  SpecId       INT IDENTITY(1,1) PRIMARY KEY,
  CompanyId    INT          NOT NULL DEFAULT 1,
  ProductCode  NVARCHAR(80)  NOT NULL,
  SpecGroup    NVARCHAR(100) NOT NULL DEFAULT 'General',
  SpecKey      NVARCHAR(100) NOT NULL,
  SpecValue    NVARCHAR(500) NOT NULL,
  SortOrder    INT          NOT NULL DEFAULT 0,
  IsActive     BIT      NOT NULL DEFAULT 1,
  CreatedAt    DATETIME2(0)    NOT NULL DEFAULT SYSUTCDATETIME()
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_ProductSpec_Product')
  CREATE INDEX IX_ProductSpec_Product ON store.ProductSpec (CompanyId, ProductCode, IsActive);
GO

IF OBJECT_ID('inv.Warehouse', 'U') IS NULL
CREATE TABLE inv.Warehouse(
  WarehouseId           BIGINT IDENTITY(1,1) PRIMARY KEY,
  CompanyId             INT          NOT NULL,
  BranchId              INT          NOT NULL,
  WarehouseCode         NVARCHAR(30)  NOT NULL,
  WarehouseName         NVARCHAR(150) NOT NULL,
  AddressLine           NVARCHAR(250) NULL,
  ContactName           NVARCHAR(120) NULL,
  Phone                 NVARCHAR(40)  NULL,
  IsActive              BIT      NOT NULL DEFAULT 1,
  IsDeleted             BIT      NOT NULL DEFAULT 0,
  DeletedAt             DATETIME2(0)    NULL,
  DeletedByUserId       INT          NULL,
  CreatedAt             DATETIME2(0)    NOT NULL DEFAULT SYSUTCDATETIME(),
  UpdatedAt             DATETIME2(0)    NOT NULL DEFAULT SYSUTCDATETIME(),
  CreatedByUserId       INT          NULL,
  UpdatedByUserId       INT          NULL,
  RowVer                INT          NOT NULL DEFAULT 1,
  CONSTRAINT FK_inv_Warehouse_Company   FOREIGN KEY (CompanyId)       REFERENCES cfg.Company(CompanyId),
  CONSTRAINT FK_inv_Warehouse_Branch    FOREIGN KEY (BranchId)        REFERENCES cfg.Branch(BranchId),
  CONSTRAINT FK_inv_Warehouse_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
  CONSTRAINT FK_inv_Warehouse_UpdatedBy FOREIGN KEY (UpdatedByUserId) REFERENCES sec.[User](UserId),
  CONSTRAINT FK_inv_Warehouse_DeletedBy FOREIGN KEY (DeletedByUserId) REFERENCES sec.[User](UserId)
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UQ_inv_Warehouse_Code')
  CREATE UNIQUE INDEX UQ_inv_Warehouse_Code ON inv.Warehouse (CompanyId, WarehouseCode) WHERE IsDeleted = 0;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_inv_Warehouse_Company')
  CREATE INDEX IX_inv_Warehouse_Company ON inv.Warehouse (CompanyId, IsDeleted, IsActive);
GO

IF OBJECT_ID('inv.WarehouseZone', 'U') IS NULL
CREATE TABLE inv.WarehouseZone(
  ZoneId                BIGINT IDENTITY(1,1) PRIMARY KEY,
  WarehouseId           BIGINT       NOT NULL,
  ZoneCode              NVARCHAR(30)  NOT NULL,
  ZoneName              NVARCHAR(150) NOT NULL,
  ZoneType              NVARCHAR(20)  NOT NULL DEFAULT 'STORAGE',
  Temperature           NVARCHAR(20)  NOT NULL DEFAULT 'AMBIENT',
  IsActive              BIT      NOT NULL DEFAULT 1,
  IsDeleted             BIT      NOT NULL DEFAULT 0,
  DeletedAt             DATETIME2(0)    NULL,
  DeletedByUserId       INT          NULL,
  CreatedAt             DATETIME2(0)    NOT NULL DEFAULT SYSUTCDATETIME(),
  UpdatedAt             DATETIME2(0)    NOT NULL DEFAULT SYSUTCDATETIME(),
  CreatedByUserId       INT          NULL,
  UpdatedByUserId       INT          NULL,
  RowVer                INT          NOT NULL DEFAULT 1,
  CONSTRAINT CK_inv_WarehouseZone_Type CHECK (ZoneType IN ('RECEIVING', 'STORAGE', 'PICKING', 'SHIPPING', 'QUARANTINE')),
  CONSTRAINT CK_inv_WarehouseZone_Temp CHECK (Temperature IN ('AMBIENT', 'COLD', 'FROZEN')),
  CONSTRAINT FK_inv_WarehouseZone_Warehouse FOREIGN KEY (WarehouseId)     REFERENCES inv.Warehouse(WarehouseId),
  CONSTRAINT FK_inv_WarehouseZone_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
  CONSTRAINT FK_inv_WarehouseZone_UpdatedBy FOREIGN KEY (UpdatedByUserId) REFERENCES sec.[User](UserId),
  CONSTRAINT FK_inv_WarehouseZone_DeletedBy FOREIGN KEY (DeletedByUserId) REFERENCES sec.[User](UserId)
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_inv_WarehouseZone_Warehouse')
  CREATE INDEX IX_inv_WarehouseZone_Warehouse ON inv.WarehouseZone (WarehouseId, IsDeleted, IsActive);
GO

IF OBJECT_ID('inv.WarehouseBin', 'U') IS NULL
CREATE TABLE inv.WarehouseBin(
  BinId                 BIGINT IDENTITY(1,1) PRIMARY KEY,
  ZoneId                BIGINT        NOT NULL,
  BinCode               NVARCHAR(30)   NOT NULL,
  BinName               NVARCHAR(100)  NULL,
  MaxWeight             DECIMAL(18,2) NULL,
  MaxVolume             DECIMAL(18,4) NULL,
  IsActive              BIT       NOT NULL DEFAULT 1,
  IsDeleted             BIT       NOT NULL DEFAULT 0,
  DeletedAt             DATETIME2(0)     NULL,
  DeletedByUserId       INT           NULL,
  CreatedAt             DATETIME2(0)     NOT NULL DEFAULT SYSUTCDATETIME(),
  UpdatedAt             DATETIME2(0)     NOT NULL DEFAULT SYSUTCDATETIME(),
  CreatedByUserId       INT           NULL,
  UpdatedByUserId       INT           NULL,
  RowVer                INT           NOT NULL DEFAULT 1,
  CONSTRAINT FK_inv_WarehouseBin_Zone      FOREIGN KEY (ZoneId)          REFERENCES inv.WarehouseZone(ZoneId),
  CONSTRAINT FK_inv_WarehouseBin_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
  CONSTRAINT FK_inv_WarehouseBin_UpdatedBy FOREIGN KEY (UpdatedByUserId) REFERENCES sec.[User](UserId),
  CONSTRAINT FK_inv_WarehouseBin_DeletedBy FOREIGN KEY (DeletedByUserId) REFERENCES sec.[User](UserId)
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_inv_WarehouseBin_Zone')
  CREATE INDEX IX_inv_WarehouseBin_Zone ON inv.WarehouseBin (ZoneId, IsDeleted, IsActive);
GO

IF OBJECT_ID('inv.ProductLot', 'U') IS NULL
CREATE TABLE inv.ProductLot(
  LotId                  BIGINT IDENTITY(1,1) PRIMARY KEY,
  CompanyId              INT           NOT NULL,
  ProductId              BIGINT        NOT NULL,
  LotNumber              NVARCHAR(60)   NOT NULL,
  ManufactureDate        DATE          NULL,
  ExpiryDate             DATE          NULL,
  SupplierCode           NVARCHAR(24)   NULL,
  PurchaseDocumentNumber NVARCHAR(60)   NULL,
  InitialQuantity        DECIMAL(18,4) NOT NULL DEFAULT 0,
  CurrentQuantity        DECIMAL(18,4) NOT NULL DEFAULT 0,
  UnitCost               DECIMAL(18,4) NOT NULL DEFAULT 0,
  [Status]                 NVARCHAR(20)   NOT NULL DEFAULT 'ACTIVE',
  Notes                  NVARCHAR(500)  NULL,
  IsDeleted              BIT       NOT NULL DEFAULT 0,
  DeletedAt              DATETIME2(0)     NULL,
  DeletedByUserId        INT           NULL,
  CreatedAt              DATETIME2(0)     NOT NULL DEFAULT SYSUTCDATETIME(),
  UpdatedAt              DATETIME2(0)     NOT NULL DEFAULT SYSUTCDATETIME(),
  CreatedByUserId        INT           NULL,
  UpdatedByUserId        INT           NULL,
  RowVer                 INT           NOT NULL DEFAULT 1,
  CONSTRAINT CK_inv_ProductLot_Status CHECK ([Status] IN ('ACTIVE', 'DEPLETED', 'EXPIRED', 'QUARANTINE', 'BLOCKED')),
  CONSTRAINT FK_inv_ProductLot_Company   FOREIGN KEY (CompanyId)       REFERENCES cfg.Company(CompanyId),
  CONSTRAINT FK_inv_ProductLot_Product   FOREIGN KEY (ProductId)       REFERENCES mstr.Product(ProductId),
  CONSTRAINT FK_inv_ProductLot_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
  CONSTRAINT FK_inv_ProductLot_UpdatedBy FOREIGN KEY (UpdatedByUserId) REFERENCES sec.[User](UserId),
  CONSTRAINT FK_inv_ProductLot_DeletedBy FOREIGN KEY (DeletedByUserId) REFERENCES sec.[User](UserId)
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UQ_inv_ProductLot')
  CREATE UNIQUE INDEX UQ_inv_ProductLot ON inv.ProductLot (CompanyId, ProductId, LotNumber) WHERE IsDeleted = 0;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_inv_ProductLot_Product')
  CREATE INDEX IX_inv_ProductLot_Product ON inv.ProductLot (CompanyId, ProductId, [Status]);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_inv_ProductLot_Expiry')
  CREATE INDEX IX_inv_ProductLot_Expiry ON inv.ProductLot (CompanyId, ExpiryDate) WHERE ExpiryDate IS NOT NULL AND IsDeleted = 0 AND [Status] = 'ACTIVE';
GO

IF OBJECT_ID('inv.ProductSerial', 'U') IS NULL
CREATE TABLE inv.ProductSerial(
  SerialId               BIGINT IDENTITY(1,1) PRIMARY KEY,
  CompanyId              INT          NOT NULL,
  ProductId              BIGINT       NOT NULL,
  LotId                  BIGINT       NULL,
  SerialNumber           NVARCHAR(100) NOT NULL,
  WarehouseId            BIGINT       NULL,
  BinId                  BIGINT       NULL,
  [Status]                 NVARCHAR(20)  NOT NULL DEFAULT 'AVAILABLE',
  PurchaseDocumentNumber NVARCHAR(60)  NULL,
  SalesDocumentNumber    NVARCHAR(60)  NULL,
  CustomerId             BIGINT       NULL,
  SoldAt                 DATETIME2(0)    NULL,
  WarrantyExpiry         DATE         NULL,
  Notes                  NVARCHAR(500) NULL,
  IsDeleted              BIT      NOT NULL DEFAULT 0,
  DeletedAt              DATETIME2(0)    NULL,
  DeletedByUserId        INT          NULL,
  CreatedAt              DATETIME2(0)    NOT NULL DEFAULT SYSUTCDATETIME(),
  UpdatedAt              DATETIME2(0)    NOT NULL DEFAULT SYSUTCDATETIME(),
  CreatedByUserId        INT          NULL,
  UpdatedByUserId        INT          NULL,
  RowVer                 INT          NOT NULL DEFAULT 1,
  CONSTRAINT CK_inv_ProductSerial_Status CHECK ([Status] IN ('AVAILABLE', 'RESERVED', 'SOLD', 'RETURNED', 'DEFECTIVE', 'SCRAPPED')),
  CONSTRAINT FK_inv_ProductSerial_Company   FOREIGN KEY (CompanyId)       REFERENCES cfg.Company(CompanyId),
  CONSTRAINT FK_inv_ProductSerial_Product   FOREIGN KEY (ProductId)       REFERENCES mstr.Product(ProductId),
  CONSTRAINT FK_inv_ProductSerial_Lot       FOREIGN KEY (LotId)           REFERENCES inv.ProductLot(LotId),
  CONSTRAINT FK_inv_ProductSerial_Warehouse FOREIGN KEY (WarehouseId)     REFERENCES inv.Warehouse(WarehouseId),
  CONSTRAINT FK_inv_ProductSerial_Bin       FOREIGN KEY (BinId)           REFERENCES inv.WarehouseBin(BinId),
  CONSTRAINT FK_inv_ProductSerial_Customer  FOREIGN KEY (CustomerId)      REFERENCES mstr.Customer(CustomerId),
  CONSTRAINT FK_inv_ProductSerial_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
  CONSTRAINT FK_inv_ProductSerial_UpdatedBy FOREIGN KEY (UpdatedByUserId) REFERENCES sec.[User](UserId),
  CONSTRAINT FK_inv_ProductSerial_DeletedBy FOREIGN KEY (DeletedByUserId) REFERENCES sec.[User](UserId)
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UQ_inv_ProductSerial')
  CREATE UNIQUE INDEX UQ_inv_ProductSerial ON inv.ProductSerial (CompanyId, ProductId, SerialNumber) WHERE IsDeleted = 0;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_inv_ProductSerial_Product')
  CREATE INDEX IX_inv_ProductSerial_Product ON inv.ProductSerial (CompanyId, ProductId, [Status]);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_inv_ProductSerial_Warehouse')
  CREATE INDEX IX_inv_ProductSerial_Warehouse ON inv.ProductSerial (WarehouseId, [Status]) WHERE IsDeleted = 0 AND [Status] = 'AVAILABLE';
GO

IF OBJECT_ID('inv.ProductBinStock', 'U') IS NULL
CREATE TABLE inv.ProductBinStock(
  ProductBinStockId     BIGINT IDENTITY(1,1) PRIMARY KEY,
  CompanyId             INT           NOT NULL,
  ProductId             BIGINT        NOT NULL,
  WarehouseId           BIGINT        NOT NULL,
  BinId                 BIGINT        NULL,
  LotId                 BIGINT        NULL,
  QuantityOnHand        DECIMAL(18,4) NOT NULL DEFAULT 0,
  QuantityReserved      DECIMAL(18,4) NOT NULL DEFAULT 0,
  QuantityAvailable     DECIMAL(18,4) NOT NULL DEFAULT 0,
  LastCountDate         DATE          NULL,
  IsDeleted             BIT       NOT NULL DEFAULT 0,
  DeletedAt             DATETIME2(0)     NULL,
  DeletedByUserId       INT           NULL,
  CreatedAt             DATETIME2(0)     NOT NULL DEFAULT SYSUTCDATETIME(),
  UpdatedAt             DATETIME2(0)     NOT NULL DEFAULT SYSUTCDATETIME(),
  CreatedByUserId       INT           NULL,
  UpdatedByUserId       INT           NULL,
  RowVer                INT           NOT NULL DEFAULT 1,
  CONSTRAINT FK_inv_ProductBinStock_Company   FOREIGN KEY (CompanyId)       REFERENCES cfg.Company(CompanyId),
  CONSTRAINT FK_inv_ProductBinStock_Product   FOREIGN KEY (ProductId)       REFERENCES mstr.Product(ProductId),
  CONSTRAINT FK_inv_ProductBinStock_Warehouse FOREIGN KEY (WarehouseId)     REFERENCES inv.Warehouse(WarehouseId),
  CONSTRAINT FK_inv_ProductBinStock_Bin       FOREIGN KEY (BinId)           REFERENCES inv.WarehouseBin(BinId),
  CONSTRAINT FK_inv_ProductBinStock_Lot       FOREIGN KEY (LotId)           REFERENCES inv.ProductLot(LotId),
  CONSTRAINT FK_inv_ProductBinStock_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
  CONSTRAINT FK_inv_ProductBinStock_UpdatedBy FOREIGN KEY (UpdatedByUserId) REFERENCES sec.[User](UserId),
  CONSTRAINT FK_inv_ProductBinStock_DeletedBy FOREIGN KEY (DeletedByUserId) REFERENCES sec.[User](UserId)
);
GO

-- (skipped: index UX_inv_ProductBinStock_Location uses COALESCE in columns)
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_inv_ProductBinStock_Warehouse')
  CREATE INDEX IX_inv_ProductBinStock_Warehouse ON inv.ProductBinStock (WarehouseId, ProductId) WHERE IsDeleted = 0;
GO

IF OBJECT_ID('inv.InventoryValuationMethod', 'U') IS NULL
CREATE TABLE inv.InventoryValuationMethod(
  ValuationMethodId     BIGINT IDENTITY(1,1) PRIMARY KEY,
  CompanyId             INT           NOT NULL,
  ProductId             BIGINT        NOT NULL,
  Method                NVARCHAR(20)   NOT NULL DEFAULT 'WEIGHTED_AVG',
  StandardCost          DECIMAL(18,4) NULL,
  IsDeleted             BIT       NOT NULL DEFAULT 0,
  DeletedAt             DATETIME2(0)     NULL,
  DeletedByUserId       INT           NULL,
  CreatedAt             DATETIME2(0)     NOT NULL DEFAULT SYSUTCDATETIME(),
  UpdatedAt             DATETIME2(0)     NOT NULL DEFAULT SYSUTCDATETIME(),
  CreatedByUserId       INT           NULL,
  UpdatedByUserId       INT           NULL,
  RowVer                INT           NOT NULL DEFAULT 1,
  CONSTRAINT CK_inv_ValMethod_Method CHECK (Method IN ('FIFO', 'LIFO', 'WEIGHTED_AVG', 'LAST_COST', 'STANDARD')),
  CONSTRAINT FK_inv_ValMethod_Company   FOREIGN KEY (CompanyId)       REFERENCES cfg.Company(CompanyId),
  CONSTRAINT FK_inv_ValMethod_Product   FOREIGN KEY (ProductId)       REFERENCES mstr.Product(ProductId),
  CONSTRAINT FK_inv_ValMethod_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
  CONSTRAINT FK_inv_ValMethod_UpdatedBy FOREIGN KEY (UpdatedByUserId) REFERENCES sec.[User](UserId),
  CONSTRAINT FK_inv_ValMethod_DeletedBy FOREIGN KEY (DeletedByUserId) REFERENCES sec.[User](UserId)
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UQ_inv_ValMethod_Product')
  CREATE UNIQUE INDEX UQ_inv_ValMethod_Product ON inv.InventoryValuationMethod (CompanyId, ProductId) WHERE IsDeleted = 0;
GO

IF OBJECT_ID('inv.InventoryValuationLayer', 'U') IS NULL
CREATE TABLE inv.InventoryValuationLayer(
  LayerId               BIGINT IDENTITY(1,1) PRIMARY KEY,
  CompanyId             INT           NOT NULL,
  ProductId             BIGINT        NOT NULL,
  LotId                 BIGINT        NULL,
  LayerDate             DATE          NOT NULL,
  RemainingQuantity     DECIMAL(18,4) NOT NULL DEFAULT 0,
  UnitCost              DECIMAL(18,4) NOT NULL DEFAULT 0,
  SourceDocumentType    NVARCHAR(30)   NULL,
  SourceDocumentNumber  NVARCHAR(60)   NULL,
  CreatedAt             DATETIME2(0)     NOT NULL DEFAULT SYSUTCDATETIME(),
  CONSTRAINT FK_inv_ValLayer_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId),
  CONSTRAINT FK_inv_ValLayer_Product FOREIGN KEY (ProductId) REFERENCES mstr.Product(ProductId),
  CONSTRAINT FK_inv_ValLayer_Lot     FOREIGN KEY (LotId)     REFERENCES inv.ProductLot(LotId)
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_inv_ValLayer_Product')
  CREATE INDEX IX_inv_ValLayer_Product ON inv.InventoryValuationLayer (CompanyId, ProductId, LayerDate);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_inv_ValLayer_Remaining')
  CREATE INDEX IX_inv_ValLayer_Remaining ON inv.InventoryValuationLayer (CompanyId, ProductId) WHERE RemainingQuantity > 0;
GO

IF OBJECT_ID('inv.StockMovement', 'U') IS NULL
CREATE TABLE inv.StockMovement(
  MovementId            BIGINT IDENTITY(1,1) PRIMARY KEY,
  CompanyId             INT           NOT NULL,
  BranchId              INT           NOT NULL,
  ProductId             BIGINT        NOT NULL,
  LotId                 BIGINT        NULL,
  SerialId              BIGINT        NULL,
  FromWarehouseId       BIGINT        NULL,
  ToWarehouseId         BIGINT        NULL,
  FromBinId             BIGINT        NULL,
  ToBinId               BIGINT        NULL,
  MovementType          NVARCHAR(20)   NOT NULL,
  Quantity              DECIMAL(18,4) NOT NULL,
  UnitCost              DECIMAL(18,4) NOT NULL DEFAULT 0,
  TotalCost             DECIMAL(18,2) NOT NULL DEFAULT 0,
  SourceDocumentType    NVARCHAR(30)   NULL,
  SourceDocumentNumber  NVARCHAR(60)   NULL,
  Notes                 NVARCHAR(500)  NULL,
  MovementDate          DATETIME2(0)     NOT NULL DEFAULT SYSUTCDATETIME(),
  CreatedByUserId       INT           NULL,
  CreatedAt             DATETIME2(0)     NOT NULL DEFAULT SYSUTCDATETIME(),
  CONSTRAINT CK_inv_StockMovement_Type CHECK (MovementType IN (
    'PURCHASE_IN', 'SALE_OUT', 'TRANSFER', 'ADJUSTMENT',
    'RETURN_IN', 'RETURN_OUT', 'PRODUCTION_IN', 'PRODUCTION_OUT', 'SCRAP'
  )),
  CONSTRAINT FK_inv_StockMovement_Company   FOREIGN KEY (CompanyId)       REFERENCES cfg.Company(CompanyId),
  CONSTRAINT FK_inv_StockMovement_Branch    FOREIGN KEY (BranchId)        REFERENCES cfg.Branch(BranchId),
  CONSTRAINT FK_inv_StockMovement_Product   FOREIGN KEY (ProductId)       REFERENCES mstr.Product(ProductId),
  CONSTRAINT FK_inv_StockMovement_Lot       FOREIGN KEY (LotId)           REFERENCES inv.ProductLot(LotId),
  CONSTRAINT FK_inv_StockMovement_Serial    FOREIGN KEY (SerialId)        REFERENCES inv.ProductSerial(SerialId),
  CONSTRAINT FK_inv_StockMovement_FromWH    FOREIGN KEY (FromWarehouseId) REFERENCES inv.Warehouse(WarehouseId),
  CONSTRAINT FK_inv_StockMovement_ToWH      FOREIGN KEY (ToWarehouseId)   REFERENCES inv.Warehouse(WarehouseId),
  CONSTRAINT FK_inv_StockMovement_FromBin   FOREIGN KEY (FromBinId)       REFERENCES inv.WarehouseBin(BinId),
  CONSTRAINT FK_inv_StockMovement_ToBin     FOREIGN KEY (ToBinId)         REFERENCES inv.WarehouseBin(BinId),
  CONSTRAINT FK_inv_StockMovement_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId)
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_inv_StockMovement_Product')
  CREATE INDEX IX_inv_StockMovement_Product ON inv.StockMovement (CompanyId, ProductId, MovementDate DESC);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_inv_StockMovement_Date')
  CREATE INDEX IX_inv_StockMovement_Date ON inv.StockMovement (CompanyId, MovementDate DESC);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_inv_StockMovement_Type')
  CREATE INDEX IX_inv_StockMovement_Type ON inv.StockMovement (CompanyId, MovementType, MovementDate DESC);
GO

IF OBJECT_ID('logistics.Carrier', 'U') IS NULL
CREATE TABLE logistics.Carrier (
  CarrierId       BIGINT IDENTITY(1,1) PRIMARY KEY,
  CompanyId       INT           NOT NULL,
  CarrierCode     NVARCHAR(30)   NOT NULL,
  CarrierName     NVARCHAR(150)  NOT NULL,
  FiscalId        NVARCHAR(30)   NULL,
  ContactName     NVARCHAR(120)  NULL,
  Phone           NVARCHAR(40)   NULL,
  Email           NVARCHAR(150)  NULL,
  AddressLine     NVARCHAR(250)  NULL,
  IsActive        BIT       NOT NULL DEFAULT 1,
  IsDeleted       BIT       NOT NULL DEFAULT 0,
  CreatedAt       DATETIME2(0)     NOT NULL DEFAULT SYSUTCDATETIME(),
  UpdatedAt       DATETIME2(0)     NOT NULL DEFAULT SYSUTCDATETIME(),
  CreatedByUserId INT           NULL,
  UpdatedByUserId INT           NULL,
  RowVer          INT           NOT NULL DEFAULT 1
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UQ_Carrier_CompanyCode')
  CREATE UNIQUE INDEX UQ_Carrier_CompanyCode ON logistics.Carrier (CompanyId, CarrierCode) WHERE IsDeleted = 0;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Carrier_CompanyActive')
  CREATE INDEX IX_Carrier_CompanyActive ON logistics.Carrier (CompanyId, IsDeleted, IsActive);
GO

IF OBJECT_ID('logistics.Driver', 'U') IS NULL
CREATE TABLE logistics.Driver (
  DriverId        BIGINT IDENTITY(1,1) PRIMARY KEY,
  CompanyId       INT           NOT NULL,
  CarrierId       BIGINT        NULL REFERENCES logistics.Carrier (CarrierId),
  DriverCode      NVARCHAR(30)   NOT NULL,
  DriverName      NVARCHAR(150)  NOT NULL,
  FiscalId        NVARCHAR(30)   NULL,
  LicenseNumber   NVARCHAR(40)   NULL,
  LicenseExpiry   DATE          NULL,
  Phone           NVARCHAR(40)   NULL,
  IsActive        BIT       NOT NULL DEFAULT 1,
  IsDeleted       BIT       NOT NULL DEFAULT 0,
  CreatedAt       DATETIME2(0)     NOT NULL DEFAULT SYSUTCDATETIME(),
  UpdatedAt       DATETIME2(0)     NOT NULL DEFAULT SYSUTCDATETIME(),
  CreatedByUserId INT           NULL,
  UpdatedByUserId INT           NULL,
  RowVer          INT           NOT NULL DEFAULT 1
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UQ_Driver_CompanyCode')
  CREATE UNIQUE INDEX UQ_Driver_CompanyCode ON logistics.Driver (CompanyId, DriverCode) WHERE IsDeleted = 0;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Driver_CompanyActive')
  CREATE INDEX IX_Driver_CompanyActive ON logistics.Driver (CompanyId, IsDeleted, IsActive);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Driver_Carrier')
  CREATE INDEX IX_Driver_Carrier ON logistics.Driver (CarrierId) WHERE IsDeleted = 0;
GO

IF OBJECT_ID('logistics.GoodsReceipt', 'U') IS NULL
CREATE TABLE logistics.GoodsReceipt (
  GoodsReceiptId         BIGINT IDENTITY(1,1) PRIMARY KEY,
  CompanyId              INT           NOT NULL,
  BranchId               INT           NOT NULL,
  ReceiptNumber          NVARCHAR(40)   NOT NULL,
  PurchaseDocumentNumber NVARCHAR(60)   NULL,
  SupplierId             BIGINT        NOT NULL,
  WarehouseId            BIGINT        NOT NULL,
  ReceiptDate            DATE          NOT NULL,
  [Status]                 NVARCHAR(20)   NOT NULL DEFAULT 'DRAFT'
                           CHECK ([Status] IN ('DRAFT','PARTIAL','COMPLETE','VOIDED')),
  Notes                  NVARCHAR(500)  NULL,
  CarrierId              BIGINT        NULL,
  DriverName             NVARCHAR(150)  NULL,
  VehiclePlate           NVARCHAR(20)   NULL,
  ReceivedByUserId       INT           NULL,
  IsDeleted              BIT       NOT NULL DEFAULT 0,
  CreatedAt              DATETIME2(0)     NOT NULL DEFAULT SYSUTCDATETIME(),
  UpdatedAt              DATETIME2(0)     NOT NULL DEFAULT SYSUTCDATETIME(),
  CreatedByUserId        INT           NULL,
  UpdatedByUserId        INT           NULL,
  RowVer                 INT           NOT NULL DEFAULT 1
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UQ_GoodsReceipt_Number')
  CREATE UNIQUE INDEX UQ_GoodsReceipt_Number ON logistics.GoodsReceipt (CompanyId, BranchId, ReceiptNumber) WHERE IsDeleted = 0;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_GoodsReceipt_Date')
  CREATE INDEX IX_GoodsReceipt_Date ON logistics.GoodsReceipt (CompanyId, ReceiptDate DESC);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_GoodsReceipt_Status')
  CREATE INDEX IX_GoodsReceipt_Status ON logistics.GoodsReceipt (CompanyId, [Status]) WHERE IsDeleted = 0 AND [Status] <> 'VOIDED';
GO

IF OBJECT_ID('logistics.GoodsReceiptLine', 'U') IS NULL
CREATE TABLE logistics.GoodsReceiptLine (
  GoodsReceiptLineId BIGINT IDENTITY(1,1) PRIMARY KEY,
  GoodsReceiptId     BIGINT        NOT NULL REFERENCES logistics.GoodsReceipt (GoodsReceiptId),
  LineNumber         INT           NOT NULL,
  ProductId          BIGINT        NOT NULL,
  ProductCode        NVARCHAR(40)   NOT NULL,
  Description        NVARCHAR(250)  NULL,
  OrderedQuantity    DECIMAL(18,4) NOT NULL,
  ReceivedQuantity   DECIMAL(18,4) NOT NULL,
  RejectedQuantity   DECIMAL(18,4) NOT NULL DEFAULT 0,
  UnitCost           DECIMAL(18,4) NOT NULL,
  TotalCost          DECIMAL(18,2) NOT NULL,
  LotNumber          NVARCHAR(60)   NULL,
  ExpiryDate         DATE          NULL,
  WarehouseId        BIGINT        NULL,
  BinId              BIGINT        NULL,
  InspectionStatus   NVARCHAR(20)   NOT NULL DEFAULT 'PENDING'
                       CHECK (InspectionStatus IN ('PENDING','APPROVED','REJECTED')),
  Notes              NVARCHAR(500)  NULL,
  IsDeleted          BIT       NOT NULL DEFAULT 0,
  CreatedAt          DATETIME2(0)     NOT NULL DEFAULT SYSUTCDATETIME(),
  UpdatedAt          DATETIME2(0)     NOT NULL DEFAULT SYSUTCDATETIME(),
  CreatedByUserId    INT           NULL,
  UpdatedByUserId    INT           NULL,
  RowVer             INT           NOT NULL DEFAULT 1
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_GoodsReceiptLine_Receipt')
  CREATE INDEX IX_GoodsReceiptLine_Receipt ON logistics.GoodsReceiptLine (GoodsReceiptId, LineNumber);
GO

IF OBJECT_ID('logistics.GoodsReceiptSerial', 'U') IS NULL
CREATE TABLE logistics.GoodsReceiptSerial (
  GoodsReceiptSerialId BIGINT IDENTITY(1,1) PRIMARY KEY,
  GoodsReceiptLineId   BIGINT        NOT NULL REFERENCES logistics.GoodsReceiptLine (GoodsReceiptLineId),
  SerialNumber         NVARCHAR(100)  NOT NULL,
  [Status]               NVARCHAR(20)   NOT NULL DEFAULT 'RECEIVED'
                         CHECK ([Status] IN ('RECEIVED','REJECTED')),
  Notes                NVARCHAR(250)  NULL
);
GO

IF OBJECT_ID('logistics.GoodsReturn', 'U') IS NULL
CREATE TABLE logistics.GoodsReturn (
  GoodsReturnId   BIGINT IDENTITY(1,1) PRIMARY KEY,
  CompanyId       INT           NOT NULL,
  BranchId        INT           NOT NULL,
  ReturnNumber    NVARCHAR(40)   NOT NULL,
  GoodsReceiptId  BIGINT        NULL REFERENCES logistics.GoodsReceipt (GoodsReceiptId),
  SupplierId      BIGINT        NOT NULL,
  WarehouseId     BIGINT        NOT NULL,
  ReturnDate      DATE          NOT NULL,
  Reason          NVARCHAR(500)  NULL,
  [Status]          NVARCHAR(20)   NOT NULL DEFAULT 'DRAFT'
                    CHECK ([Status] IN ('DRAFT','APPROVED','SHIPPED','VOIDED')),
  Notes           NVARCHAR(500)  NULL,
  IsDeleted       BIT       NOT NULL DEFAULT 0,
  CreatedAt       DATETIME2(0)     NOT NULL DEFAULT SYSUTCDATETIME(),
  UpdatedAt       DATETIME2(0)     NOT NULL DEFAULT SYSUTCDATETIME(),
  CreatedByUserId INT           NULL,
  UpdatedByUserId INT           NULL,
  RowVer          INT           NOT NULL DEFAULT 1
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UQ_GoodsReturn_Number')
  CREATE UNIQUE INDEX UQ_GoodsReturn_Number ON logistics.GoodsReturn (CompanyId, BranchId, ReturnNumber) WHERE IsDeleted = 0;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_GoodsReturn_Date')
  CREATE INDEX IX_GoodsReturn_Date ON logistics.GoodsReturn (CompanyId, ReturnDate DESC);
GO

IF OBJECT_ID('logistics.GoodsReturnLine', 'U') IS NULL
CREATE TABLE logistics.GoodsReturnLine (
  GoodsReturnLineId BIGINT IDENTITY(1,1) PRIMARY KEY,
  GoodsReturnId     BIGINT        NOT NULL REFERENCES logistics.GoodsReturn (GoodsReturnId),
  LineNumber        INT           NOT NULL,
  ProductId         BIGINT        NOT NULL,
  ProductCode       NVARCHAR(40)   NOT NULL,
  Quantity          DECIMAL(18,4) NOT NULL,
  UnitCost          DECIMAL(18,4) NOT NULL,
  LotNumber         NVARCHAR(60)   NULL,
  SerialNumber      NVARCHAR(100)  NULL,
  Reason            NVARCHAR(250)  NULL,
  IsDeleted         BIT       NOT NULL DEFAULT 0,
  CreatedAt         DATETIME2(0)     NOT NULL DEFAULT SYSUTCDATETIME(),
  UpdatedAt         DATETIME2(0)     NOT NULL DEFAULT SYSUTCDATETIME(),
  CreatedByUserId   INT           NULL,
  UpdatedByUserId   INT           NULL,
  RowVer            INT           NOT NULL DEFAULT 1
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_GoodsReturnLine_Return')
  CREATE INDEX IX_GoodsReturnLine_Return ON logistics.GoodsReturnLine (GoodsReturnId, LineNumber);
GO

IF OBJECT_ID('logistics.DeliveryNote', 'U') IS NULL
CREATE TABLE logistics.DeliveryNote (
  DeliveryNoteId       BIGINT IDENTITY(1,1) PRIMARY KEY,
  CompanyId            INT           NOT NULL,
  BranchId             INT           NOT NULL,
  DeliveryNumber       NVARCHAR(40)   NOT NULL,
  SalesDocumentNumber  NVARCHAR(60)   NULL,
  CustomerId           BIGINT        NOT NULL,
  WarehouseId          BIGINT        NOT NULL,
  DeliveryDate         DATE          NOT NULL,
  [Status]               NVARCHAR(20)   NOT NULL DEFAULT 'DRAFT'
                         CHECK ([Status] IN ('DRAFT','PICKING','PACKED','DISPATCHED','IN_TRANSIT','DELIVERED','VOIDED')),
  CarrierId            BIGINT        NULL REFERENCES logistics.Carrier (CarrierId),
  DriverId             BIGINT        NULL REFERENCES logistics.Driver (DriverId),
  VehiclePlate         NVARCHAR(20)   NULL,
  ShipToAddress        NVARCHAR(500)  NULL,
  ShipToContact        NVARCHAR(150)  NULL,
  EstimatedDelivery    DATE          NULL,
  ActualDelivery       DATE          NULL,
  DeliveredToName      NVARCHAR(150)  NULL,
  DeliverySignature    NVARCHAR(500)  NULL,
  Notes                NVARCHAR(500)  NULL,
  DispatchedByUserId   INT           NULL,
  IsDeleted            BIT       NOT NULL DEFAULT 0,
  CreatedAt            DATETIME2(0)     NOT NULL DEFAULT SYSUTCDATETIME(),
  UpdatedAt            DATETIME2(0)     NOT NULL DEFAULT SYSUTCDATETIME(),
  CreatedByUserId      INT           NULL,
  UpdatedByUserId      INT           NULL,
  RowVer               INT           NOT NULL DEFAULT 1
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UQ_DeliveryNote_Number')
  CREATE UNIQUE INDEX UQ_DeliveryNote_Number ON logistics.DeliveryNote (CompanyId, BranchId, DeliveryNumber) WHERE IsDeleted = 0;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_DeliveryNote_Date')
  CREATE INDEX IX_DeliveryNote_Date ON logistics.DeliveryNote (CompanyId, DeliveryDate DESC);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_DeliveryNote_ActiveStatus')
  CREATE INDEX IX_DeliveryNote_ActiveStatus ON logistics.DeliveryNote (CompanyId, [Status]) WHERE IsDeleted = 0 AND [Status] NOT IN ('DELIVERED','VOIDED');
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_DeliveryNote_Customer')
  CREATE INDEX IX_DeliveryNote_Customer ON logistics.DeliveryNote (CustomerId) WHERE IsDeleted = 0;
GO

IF OBJECT_ID('logistics.DeliveryNoteLine', 'U') IS NULL
CREATE TABLE logistics.DeliveryNoteLine (
  DeliveryNoteLineId BIGINT IDENTITY(1,1) PRIMARY KEY,
  DeliveryNoteId     BIGINT        NOT NULL REFERENCES logistics.DeliveryNote (DeliveryNoteId),
  LineNumber         INT           NOT NULL,
  ProductId          BIGINT        NOT NULL,
  ProductCode        NVARCHAR(40)   NOT NULL,
  Description        NVARCHAR(250)  NULL,
  Quantity           DECIMAL(18,4) NOT NULL,
  LotNumber          NVARCHAR(60)   NULL,
  WarehouseId        BIGINT        NULL,
  BinId              BIGINT        NULL,
  PickedQuantity     DECIMAL(18,4) NOT NULL DEFAULT 0,
  PackedQuantity     DECIMAL(18,4) NOT NULL DEFAULT 0,
  Notes              NVARCHAR(500)  NULL,
  IsDeleted          BIT       NOT NULL DEFAULT 0,
  CreatedAt          DATETIME2(0)     NOT NULL DEFAULT SYSUTCDATETIME(),
  UpdatedAt          DATETIME2(0)     NOT NULL DEFAULT SYSUTCDATETIME(),
  CreatedByUserId    INT           NULL,
  UpdatedByUserId    INT           NULL,
  RowVer             INT           NOT NULL DEFAULT 1
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_DeliveryNoteLine_Note')
  CREATE INDEX IX_DeliveryNoteLine_Note ON logistics.DeliveryNoteLine (DeliveryNoteId, LineNumber);
GO

IF OBJECT_ID('logistics.DeliveryNoteSerial', 'U') IS NULL
CREATE TABLE logistics.DeliveryNoteSerial (
  DeliveryNoteSerialId BIGINT IDENTITY(1,1) PRIMARY KEY,
  DeliveryNoteLineId   BIGINT        NOT NULL REFERENCES logistics.DeliveryNoteLine (DeliveryNoteLineId),
  SerialId             BIGINT        NULL,
  SerialNumber         NVARCHAR(100)  NOT NULL,
  [Status]               NVARCHAR(20)   NOT NULL DEFAULT 'DISPATCHED'
                         CHECK ([Status] IN ('DISPATCHED','DELIVERED','RETURNED'))
);
GO

IF OBJECT_ID('crm.Pipeline', 'U') IS NULL
CREATE TABLE crm.Pipeline(
  PipelineId            BIGINT IDENTITY(1,1) PRIMARY KEY,
  CompanyId             INT NOT NULL,
  PipelineCode          NVARCHAR(30) NOT NULL,
  PipelineName          NVARCHAR(150) NOT NULL,
  IsDefault             BIT NOT NULL DEFAULT 0,
  IsActive              BIT NOT NULL DEFAULT 1,
  IsDeleted             BIT NOT NULL DEFAULT 0,
  CreatedAt             DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
  UpdatedAt             DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
  DeletedAt             DATETIME2(0) NULL,
  CreatedByUserId       INT NULL,
  UpdatedByUserId       INT NULL,
  DeletedByUserId       INT NULL,
  RowVer                INT NOT NULL DEFAULT 1,
  CONSTRAINT FK_crm_Pipeline_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId),
  CONSTRAINT FK_crm_Pipeline_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
  CONSTRAINT FK_crm_Pipeline_UpdatedBy FOREIGN KEY (UpdatedByUserId) REFERENCES sec.[User](UserId),
  CONSTRAINT FK_crm_Pipeline_DeletedBy FOREIGN KEY (DeletedByUserId) REFERENCES sec.[User](UserId)
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UQ_crm_Pipeline_Code')
  CREATE UNIQUE INDEX UQ_crm_Pipeline_Code ON crm.Pipeline (CompanyId, PipelineCode) WHERE IsDeleted = 0;
GO

IF OBJECT_ID('crm.PipelineStage', 'U') IS NULL
CREATE TABLE crm.PipelineStage(
  StageId               BIGINT IDENTITY(1,1) PRIMARY KEY,
  PipelineId            BIGINT NOT NULL,
  StageCode             NVARCHAR(30) NOT NULL,
  StageName             NVARCHAR(100) NOT NULL,
  StageOrder            INT NOT NULL DEFAULT 0,
  Probability           DECIMAL(5,2) NOT NULL DEFAULT 0,
  DaysExpected          INT NOT NULL DEFAULT 7,
  Color                 NVARCHAR(7) NULL,
  IsClosed              BIT NOT NULL DEFAULT 0,
  IsWon                 BIT NOT NULL DEFAULT 0,
  IsActive              BIT NOT NULL DEFAULT 1,
  IsDeleted             BIT NOT NULL DEFAULT 0,
  CreatedAt             DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
  UpdatedAt             DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
  DeletedAt             DATETIME2(0) NULL,
  CreatedByUserId       INT NULL,
  UpdatedByUserId       INT NULL,
  DeletedByUserId       INT NULL,
  RowVer                INT NOT NULL DEFAULT 1,
  CONSTRAINT FK_crm_PipelineStage_Pipeline FOREIGN KEY (PipelineId) REFERENCES crm.Pipeline(PipelineId),
  CONSTRAINT FK_crm_PipelineStage_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
  CONSTRAINT FK_crm_PipelineStage_UpdatedBy FOREIGN KEY (UpdatedByUserId) REFERENCES sec.[User](UserId),
  CONSTRAINT FK_crm_PipelineStage_DeletedBy FOREIGN KEY (DeletedByUserId) REFERENCES sec.[User](UserId)
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UQ_crm_PipelineStage_Code')
  CREATE UNIQUE INDEX UQ_crm_PipelineStage_Code ON crm.PipelineStage (PipelineId, StageCode) WHERE IsDeleted = 0;
GO

IF OBJECT_ID('crm.Lead', 'U') IS NULL
CREATE TABLE crm.Lead(
  LeadId                BIGINT IDENTITY(1,1) PRIMARY KEY,
  CompanyId             INT NOT NULL,
  BranchId              INT NOT NULL,
  PipelineId            BIGINT NOT NULL,
  StageId               BIGINT NOT NULL,
  LeadCode              NVARCHAR(40) NOT NULL,
  ContactName           NVARCHAR(200) NULL,
  CompanyName           NVARCHAR(200) NULL,
  Email                 NVARCHAR(150) NULL,
  Phone                 NVARCHAR(40) NULL,
  Source                 NVARCHAR(20) NOT NULL DEFAULT 'OTHER',
  AssignedToUserId      INT NULL,
  CustomerId            BIGINT NULL,
  EstimatedValue        DECIMAL(18,2) NULL,
  CurrencyCode          NCHAR(3) NOT NULL DEFAULT 'USD',
  ExpectedCloseDate     DATE NULL,
  LostReason            NVARCHAR(500) NULL,
  Notes                 NVARCHAR(MAX) NULL,
  Tags                  NVARCHAR(500) NULL,
  Priority              NVARCHAR(10) NOT NULL DEFAULT 'MEDIUM',
  [Status]                NVARCHAR(10) NOT NULL DEFAULT 'OPEN',
  WonAt                 DATETIME2(0) NULL,
  LostAt                DATETIME2(0) NULL,
  IsDeleted             BIT NOT NULL DEFAULT 0,
  CreatedAt             DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
  UpdatedAt             DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
  DeletedAt             DATETIME2(0) NULL,
  CreatedByUserId       INT NULL,
  UpdatedByUserId       INT NULL,
  DeletedByUserId       INT NULL,
  RowVer                INT NOT NULL DEFAULT 1,
  CONSTRAINT CK_crm_Lead_Source CHECK (Source IN ('WEB', 'REFERRAL', 'COLD_CALL', 'EVENT', 'SOCIAL', 'OTHER')),
  CONSTRAINT CK_crm_Lead_Priority CHECK (Priority IN ('LOW', 'MEDIUM', 'HIGH', 'URGENT')),
  CONSTRAINT CK_crm_Lead_Status CHECK ([Status] IN ('OPEN', 'WON', 'LOST', 'ARCHIVED')),
  CONSTRAINT FK_crm_Lead_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId),
  CONSTRAINT FK_crm_Lead_Pipeline FOREIGN KEY (PipelineId) REFERENCES crm.Pipeline(PipelineId),
  CONSTRAINT FK_crm_Lead_Stage FOREIGN KEY (StageId) REFERENCES crm.PipelineStage(StageId),
  CONSTRAINT FK_crm_Lead_Customer FOREIGN KEY (CustomerId) REFERENCES mstr.Customer(CustomerId),
  CONSTRAINT FK_crm_Lead_AssignedTo FOREIGN KEY (AssignedToUserId) REFERENCES sec.[User](UserId),
  CONSTRAINT FK_crm_Lead_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
  CONSTRAINT FK_crm_Lead_UpdatedBy FOREIGN KEY (UpdatedByUserId) REFERENCES sec.[User](UserId),
  CONSTRAINT FK_crm_Lead_DeletedBy FOREIGN KEY (DeletedByUserId) REFERENCES sec.[User](UserId)
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UQ_crm_Lead_Code')
  CREATE UNIQUE INDEX UQ_crm_Lead_Code ON crm.Lead (CompanyId, LeadCode) WHERE IsDeleted = 0;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_crm_Lead_Status_Stage')
  CREATE INDEX IX_crm_Lead_Status_Stage ON crm.Lead (CompanyId, [Status], StageId) WHERE IsDeleted = 0;
GO

IF OBJECT_ID('crm.Activity', 'U') IS NULL
CREATE TABLE crm.Activity(
  ActivityId            BIGINT IDENTITY(1,1) PRIMARY KEY,
  CompanyId             INT NOT NULL,
  LeadId                BIGINT NULL,
  CustomerId            BIGINT NULL,
  ActivityType          NVARCHAR(20) NOT NULL DEFAULT 'NOTE',
  Subject               NVARCHAR(200) NOT NULL,
  Description           NVARCHAR(MAX) NULL,
  DueDate               DATETIME2(0) NULL,
  CompletedAt           DATETIME2(0) NULL,
  AssignedToUserId      INT NULL,
  IsCompleted           BIT NOT NULL DEFAULT 0,
  Priority              NVARCHAR(10) NOT NULL DEFAULT 'MEDIUM',
  IsDeleted             BIT NOT NULL DEFAULT 0,
  CreatedAt             DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
  UpdatedAt             DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
  DeletedAt             DATETIME2(0) NULL,
  CreatedByUserId       INT NULL,
  UpdatedByUserId       INT NULL,
  DeletedByUserId       INT NULL,
  RowVer                INT NOT NULL DEFAULT 1,
  CONSTRAINT CK_crm_Activity_Type CHECK (ActivityType IN ('CALL', 'EMAIL', 'MEETING', 'NOTE', 'TASK', 'FOLLOWUP')),
  CONSTRAINT CK_crm_Activity_Priority CHECK (Priority IN ('LOW', 'MEDIUM', 'HIGH', 'URGENT')),
  CONSTRAINT FK_crm_Activity_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId),
  CONSTRAINT FK_crm_Activity_Lead FOREIGN KEY (LeadId) REFERENCES crm.Lead(LeadId),
  CONSTRAINT FK_crm_Activity_Customer FOREIGN KEY (CustomerId) REFERENCES mstr.Customer(CustomerId),
  CONSTRAINT FK_crm_Activity_AssignedTo FOREIGN KEY (AssignedToUserId) REFERENCES sec.[User](UserId),
  CONSTRAINT FK_crm_Activity_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
  CONSTRAINT FK_crm_Activity_UpdatedBy FOREIGN KEY (UpdatedByUserId) REFERENCES sec.[User](UserId),
  CONSTRAINT FK_crm_Activity_DeletedBy FOREIGN KEY (DeletedByUserId) REFERENCES sec.[User](UserId)
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_crm_Activity_Pending')
  CREATE INDEX IX_crm_Activity_Pending ON crm.Activity (CompanyId, IsCompleted, DueDate) WHERE IsDeleted = 0 AND IsCompleted = 0;
GO

IF OBJECT_ID('crm.LeadHistory', 'U') IS NULL
CREATE TABLE crm.LeadHistory(
  HistoryId             BIGINT IDENTITY(1,1) PRIMARY KEY,
  LeadId                BIGINT NOT NULL,
  FromStageId           BIGINT NULL,
  ToStageId             BIGINT NULL,
  ChangedByUserId       INT NULL,
  ChangeType            NVARCHAR(20) NOT NULL DEFAULT 'NOTE',
  Notes                 NVARCHAR(500) NULL,
  CreatedAt             DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
  CONSTRAINT CK_crm_LeadHistory_ChangeType CHECK (ChangeType IN ('STAGE_CHANGE', 'ASSIGN', 'NOTE', 'STATUS')),
  CONSTRAINT FK_crm_LeadHistory_Lead FOREIGN KEY (LeadId) REFERENCES crm.Lead(LeadId),
  CONSTRAINT FK_crm_LeadHistory_FromStage FOREIGN KEY (FromStageId) REFERENCES crm.PipelineStage(StageId),
  CONSTRAINT FK_crm_LeadHistory_ToStage FOREIGN KEY (ToStageId) REFERENCES crm.PipelineStage(StageId),
  CONSTRAINT FK_crm_LeadHistory_ChangedBy FOREIGN KEY (ChangedByUserId) REFERENCES sec.[User](UserId)
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_crm_LeadHistory_Lead')
  CREATE INDEX IX_crm_LeadHistory_Lead ON crm.LeadHistory (LeadId, CreatedAt DESC);
GO

IF OBJECT_ID('crm.SavedView', 'U') IS NULL
CREATE TABLE crm.SavedView(
  ViewId                BIGINT IDENTITY(1,1) PRIMARY KEY,
  CompanyId             INT            NOT NULL,
  UserId                INT            NOT NULL,
  Entity                VARCHAR(50)    NOT NULL,
  Name                  NVARCHAR(200)  NOT NULL,
  FilterJson            NVARCHAR(MAX)  NOT NULL DEFAULT N'{}',
  ColumnsJson           NVARCHAR(MAX)  NULL,
  SortJson              NVARCHAR(MAX)  NULL,
  IsShared              BIT            NOT NULL DEFAULT 0,
  IsDefault             BIT            NOT NULL DEFAULT 0,
  CreatedAt             DATETIME2(0)   NOT NULL DEFAULT SYSUTCDATETIME(),
  UpdatedAt             DATETIME2(0)   NOT NULL DEFAULT SYSUTCDATETIME(),
  CONSTRAINT CK_crm_SavedView_Entity CHECK (Entity IN ('LEAD','CONTACT','COMPANY','DEAL','ACTIVITY')),
  CONSTRAINT FK_crm_SavedView_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId),
  CONSTRAINT FK_crm_SavedView_User FOREIGN KEY (UserId) REFERENCES sec.[User](UserId)
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UQ_crm_SavedView_Name')
  CREATE UNIQUE INDEX UQ_crm_SavedView_Name ON crm.SavedView (CompanyId, UserId, Entity, Name);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_crm_SavedView_UserEntity')
  CREATE INDEX IX_crm_SavedView_UserEntity ON crm.SavedView (CompanyId, UserId, Entity);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_crm_SavedView_Shared')
  CREATE INDEX IX_crm_SavedView_Shared ON crm.SavedView (CompanyId, Entity, IsShared) WHERE IsShared = 1;
GO

IF OBJECT_ID('mfg.BillOfMaterials', 'U') IS NULL
CREATE TABLE mfg.BillOfMaterials(
  BOMId                 BIGINT IDENTITY(1,1) PRIMARY KEY,
  CompanyId             INT NOT NULL,
  BOMCode               NVARCHAR(30) NOT NULL,
  BOMName               NVARCHAR(200) NOT NULL,
  ProductId             BIGINT NOT NULL,
  OutputQuantity        DECIMAL(18,3) NOT NULL DEFAULT 1,
  UnitOfMeasure         NVARCHAR(20) NULL,
  Version               INT NOT NULL DEFAULT 1,
  [Status]                NVARCHAR(20) NOT NULL DEFAULT 'DRAFT',
  EffectiveFrom         DATE NULL,
  EffectiveTo           DATE NULL,
  Notes                 NVARCHAR(500) NULL,
  IsActive              BIT NOT NULL DEFAULT 1,
  CreatedAt             DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
  UpdatedAt             DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
  CreatedByUserId       INT NULL,
  UpdatedByUserId       INT NULL,
  IsDeleted             BIT NOT NULL DEFAULT 0,
  DeletedAt             DATETIME2(0) NULL,
  DeletedByUserId       INT NULL,
  CONSTRAINT CK_mfg_BOM_Status CHECK ([Status] IN ('DRAFT', 'ACTIVE', 'OBSOLETE')),
  CONSTRAINT UQ_mfg_BOM_Code UNIQUE (CompanyId, BOMCode),
  CONSTRAINT FK_mfg_BOM_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId),
  CONSTRAINT FK_mfg_BOM_Product FOREIGN KEY (ProductId) REFERENCES mstr.Product(ProductId),
  CONSTRAINT FK_mfg_BOM_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
  CONSTRAINT FK_mfg_BOM_UpdatedBy FOREIGN KEY (UpdatedByUserId) REFERENCES sec.[User](UserId),
  CONSTRAINT FK_mfg_BOM_DeletedBy FOREIGN KEY (DeletedByUserId) REFERENCES sec.[User](UserId)
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_mfg_BOM_Company')
  CREATE INDEX IX_mfg_BOM_Company ON mfg.BillOfMaterials (CompanyId, IsDeleted, IsActive);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_mfg_BOM_Product')
  CREATE INDEX IX_mfg_BOM_Product ON mfg.BillOfMaterials (ProductId) WHERE IsDeleted = 0;
GO

IF OBJECT_ID('mfg.BOMLine', 'U') IS NULL
CREATE TABLE mfg.BOMLine(
  BOMLineId             BIGINT IDENTITY(1,1) PRIMARY KEY,
  BOMId                 BIGINT NOT NULL,
  LineNumber            INT NOT NULL,
  ComponentProductId    BIGINT NOT NULL,
  Quantity              DECIMAL(18,3) NOT NULL,
  UnitOfMeasure         NVARCHAR(20) NULL,
  WastePercent          DECIMAL(5,2) NOT NULL DEFAULT 0,
  IsOptional            BIT NOT NULL DEFAULT 0,
  Notes                 NVARCHAR(500) NULL,
  CreatedAt             DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
  UpdatedAt             DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
  CONSTRAINT UQ_mfg_BOMLine UNIQUE (BOMId, LineNumber),
  CONSTRAINT FK_mfg_BOMLine_BOM FOREIGN KEY (BOMId) REFERENCES mfg.BillOfMaterials(BOMId),
  CONSTRAINT FK_mfg_BOMLine_Component FOREIGN KEY (ComponentProductId) REFERENCES mstr.Product(ProductId)
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_mfg_BOMLine_BOM')
  CREATE INDEX IX_mfg_BOMLine_BOM ON mfg.BOMLine (BOMId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_mfg_BOMLine_Component')
  CREATE INDEX IX_mfg_BOMLine_Component ON mfg.BOMLine (ComponentProductId);
GO

IF OBJECT_ID('mfg.WorkCenter', 'U') IS NULL
CREATE TABLE mfg.WorkCenter(
  WorkCenterId          BIGINT IDENTITY(1,1) PRIMARY KEY,
  CompanyId             INT NOT NULL,
  WorkCenterCode        NVARCHAR(20) NOT NULL,
  WorkCenterName        NVARCHAR(200) NOT NULL,
  WarehouseId           BIGINT NULL,
  CostPerHour           DECIMAL(18,4) NOT NULL DEFAULT 0,
  Capacity              DECIMAL(18,2) NOT NULL DEFAULT 1,
  CapacityUom           NVARCHAR(20) NOT NULL DEFAULT 'UNITS_PER_HOUR',
  IsActive              BIT NOT NULL DEFAULT 1,
  CreatedAt             DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
  UpdatedAt             DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
  CreatedByUserId       INT NULL,
  UpdatedByUserId       INT NULL,
  IsDeleted             BIT NOT NULL DEFAULT 0,
  DeletedAt             DATETIME2(0) NULL,
  DeletedByUserId       INT NULL,
  CONSTRAINT UQ_mfg_WorkCenter_Code UNIQUE (CompanyId, WorkCenterCode),
  CONSTRAINT FK_mfg_WorkCenter_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId),
  CONSTRAINT FK_mfg_WorkCenter_Warehouse FOREIGN KEY (WarehouseId) REFERENCES inv.Warehouse(WarehouseId),
  CONSTRAINT FK_mfg_WorkCenter_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
  CONSTRAINT FK_mfg_WorkCenter_UpdatedBy FOREIGN KEY (UpdatedByUserId) REFERENCES sec.[User](UserId),
  CONSTRAINT FK_mfg_WorkCenter_DeletedBy FOREIGN KEY (DeletedByUserId) REFERENCES sec.[User](UserId)
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_mfg_WorkCenter_Company')
  CREATE INDEX IX_mfg_WorkCenter_Company ON mfg.WorkCenter (CompanyId, IsDeleted, IsActive);
GO

IF OBJECT_ID('mfg.Routing', 'U') IS NULL
CREATE TABLE mfg.Routing(
  RoutingId             BIGINT IDENTITY(1,1) PRIMARY KEY,
  BOMId                 BIGINT NOT NULL,
  OperationNumber       INT NOT NULL,
  OperationName         NVARCHAR(200) NOT NULL,
  WorkCenterId          BIGINT NOT NULL,
  SetupTimeMinutes      DECIMAL(10,2) NOT NULL DEFAULT 0,
  RunTimeMinutes        DECIMAL(10,2) NOT NULL DEFAULT 0,
  Notes                 NVARCHAR(500) NULL,
  CreatedAt             DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
  UpdatedAt             DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
  CONSTRAINT UQ_mfg_Routing_Operation UNIQUE (BOMId, OperationNumber),
  CONSTRAINT FK_mfg_Routing_BOM FOREIGN KEY (BOMId) REFERENCES mfg.BillOfMaterials(BOMId),
  CONSTRAINT FK_mfg_Routing_WorkCenter FOREIGN KEY (WorkCenterId) REFERENCES mfg.WorkCenter(WorkCenterId)
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_mfg_Routing_BOM')
  CREATE INDEX IX_mfg_Routing_BOM ON mfg.Routing (BOMId, OperationNumber);
GO

IF OBJECT_ID('mfg.WorkOrder', 'U') IS NULL
CREATE TABLE mfg.WorkOrder(
  WorkOrderId           BIGINT IDENTITY(1,1) PRIMARY KEY,
  CompanyId             INT NOT NULL,
  BranchId              INT NOT NULL,
  WorkOrderNumber       NVARCHAR(30) NOT NULL,
  BOMId                 BIGINT NOT NULL,
  ProductId             BIGINT NOT NULL,
  PlannedQuantity       DECIMAL(18,3) NOT NULL,
  ProducedQuantity      DECIMAL(18,3) NOT NULL DEFAULT 0,
  ScrapQuantity         DECIMAL(18,3) NOT NULL DEFAULT 0,
  UnitOfMeasure         NVARCHAR(20) NULL,
  WarehouseId           BIGINT NOT NULL,
  [Status]                NVARCHAR(20) NOT NULL DEFAULT 'DRAFT',
  Priority              NVARCHAR(10) NOT NULL DEFAULT 'MEDIUM',
  PlannedStartDate      DATETIME2(0) NULL,
  PlannedEndDate        DATETIME2(0) NULL,
  ActualStartDate       DATETIME2(0) NULL,
  ActualEndDate         DATETIME2(0) NULL,
  Notes                 NVARCHAR(500) NULL,
  CreatedAt             DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
  UpdatedAt             DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
  CreatedByUserId       INT NULL,
  UpdatedByUserId       INT NULL,
  IsDeleted             BIT NOT NULL DEFAULT 0,
  DeletedAt             DATETIME2(0) NULL,
  DeletedByUserId       INT NULL,
  CONSTRAINT CK_mfg_WorkOrder_Status CHECK ([Status] IN ('DRAFT', 'CONFIRMED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED')),
  CONSTRAINT CK_mfg_WorkOrder_Priority CHECK (Priority IN ('LOW', 'MEDIUM', 'HIGH', 'URGENT')),
  CONSTRAINT UQ_mfg_WorkOrder_Number UNIQUE (CompanyId, WorkOrderNumber),
  CONSTRAINT FK_mfg_WorkOrder_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId),
  CONSTRAINT FK_mfg_WorkOrder_Branch FOREIGN KEY (BranchId) REFERENCES cfg.Branch(BranchId),
  CONSTRAINT FK_mfg_WorkOrder_BOM FOREIGN KEY (BOMId) REFERENCES mfg.BillOfMaterials(BOMId),
  CONSTRAINT FK_mfg_WorkOrder_Product FOREIGN KEY (ProductId) REFERENCES mstr.Product(ProductId),
  CONSTRAINT FK_mfg_WorkOrder_Warehouse FOREIGN KEY (WarehouseId) REFERENCES inv.Warehouse(WarehouseId),
  CONSTRAINT FK_mfg_WorkOrder_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
  CONSTRAINT FK_mfg_WorkOrder_UpdatedBy FOREIGN KEY (UpdatedByUserId) REFERENCES sec.[User](UserId),
  CONSTRAINT FK_mfg_WorkOrder_DeletedBy FOREIGN KEY (DeletedByUserId) REFERENCES sec.[User](UserId)
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_mfg_WorkOrder_Company')
  CREATE INDEX IX_mfg_WorkOrder_Company ON mfg.WorkOrder (CompanyId, BranchId, [Status]) WHERE IsDeleted = 0;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_mfg_WorkOrder_BOM')
  CREATE INDEX IX_mfg_WorkOrder_BOM ON mfg.WorkOrder (BOMId) WHERE IsDeleted = 0;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_mfg_WorkOrder_Planned')
  CREATE INDEX IX_mfg_WorkOrder_Planned ON mfg.WorkOrder (CompanyId, PlannedStartDate) WHERE [Status] IN ('DRAFT', 'CONFIRMED') AND IsDeleted = 0;
GO

IF OBJECT_ID('mfg.WorkOrderMaterial', 'U') IS NULL
CREATE TABLE mfg.WorkOrderMaterial(
  WorkOrderMaterialId   BIGINT IDENTITY(1,1) PRIMARY KEY,
  WorkOrderId           BIGINT NOT NULL,
  LineNumber            INT NOT NULL,
  ProductId             BIGINT NOT NULL,
  PlannedQuantity       DECIMAL(18,3) NOT NULL,
  ConsumedQuantity      DECIMAL(18,3) NOT NULL DEFAULT 0,
  UnitOfMeasure         NVARCHAR(20) NULL,
  LotId                 BIGINT NULL,
  BinId                 BIGINT NULL,
  UnitCost              DECIMAL(18,4) NOT NULL DEFAULT 0,
  Notes                 NVARCHAR(500) NULL,
  CreatedAt             DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
  UpdatedAt             DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
  CONSTRAINT UQ_mfg_WOMaterial UNIQUE (WorkOrderId, LineNumber),
  CONSTRAINT FK_mfg_WOMaterial_WorkOrder FOREIGN KEY (WorkOrderId) REFERENCES mfg.WorkOrder(WorkOrderId),
  CONSTRAINT FK_mfg_WOMaterial_Product FOREIGN KEY (ProductId) REFERENCES mstr.Product(ProductId),
  CONSTRAINT FK_mfg_WOMaterial_Lot FOREIGN KEY (LotId) REFERENCES inv.ProductLot(LotId),
  CONSTRAINT FK_mfg_WOMaterial_Bin FOREIGN KEY (BinId) REFERENCES inv.WarehouseBin(BinId)
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_mfg_WOMaterial_WorkOrder')
  CREATE INDEX IX_mfg_WOMaterial_WorkOrder ON mfg.WorkOrderMaterial (WorkOrderId);
GO

IF OBJECT_ID('mfg.WorkOrderOutput', 'U') IS NULL
CREATE TABLE mfg.WorkOrderOutput(
  WorkOrderOutputId     BIGINT IDENTITY(1,1) PRIMARY KEY,
  WorkOrderId           BIGINT NOT NULL,
  ProductId             BIGINT NOT NULL,
  Quantity              DECIMAL(18,3) NOT NULL,
  UnitOfMeasure         NVARCHAR(20) NULL,
  LotNumber             NVARCHAR(60) NULL,
  WarehouseId           BIGINT NOT NULL,
  BinId                 BIGINT NULL,
  UnitCost              DECIMAL(18,4) NOT NULL DEFAULT 0,
  IsScrap               BIT NOT NULL DEFAULT 0,
  Notes                 NVARCHAR(500) NULL,
  ProducedAt            DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
  CreatedByUserId       INT NULL,
  CreatedAt             DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
  CONSTRAINT FK_mfg_WOOutput_WorkOrder FOREIGN KEY (WorkOrderId) REFERENCES mfg.WorkOrder(WorkOrderId),
  CONSTRAINT FK_mfg_WOOutput_Product FOREIGN KEY (ProductId) REFERENCES mstr.Product(ProductId),
  CONSTRAINT FK_mfg_WOOutput_Warehouse FOREIGN KEY (WarehouseId) REFERENCES inv.Warehouse(WarehouseId),
  CONSTRAINT FK_mfg_WOOutput_Bin FOREIGN KEY (BinId) REFERENCES inv.WarehouseBin(BinId),
  CONSTRAINT FK_mfg_WOOutput_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId)
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_mfg_WOOutput_WorkOrder')
  CREATE INDEX IX_mfg_WOOutput_WorkOrder ON mfg.WorkOrderOutput (WorkOrderId);
GO

IF OBJECT_ID('fleet.Vehicle', 'U') IS NULL
CREATE TABLE fleet.Vehicle(
  VehicleId             BIGINT IDENTITY(1,1) PRIMARY KEY,
  CompanyId             INT NOT NULL,
  VehicleCode           NVARCHAR(20) NOT NULL,
  LicensePlate          NVARCHAR(20) NOT NULL,
  VehicleType           NVARCHAR(30) NOT NULL DEFAULT 'CAR',
  Brand                 NVARCHAR(60) NULL,
  Model                 NVARCHAR(60) NULL,
  Year                  INT NULL,
  Color                 NVARCHAR(30) NULL,
  VinNumber             NVARCHAR(30) NULL,
  EngineNumber          NVARCHAR(30) NULL,
  FuelType              NVARCHAR(20) NOT NULL DEFAULT 'GASOLINE',
  TankCapacity          DECIMAL(10,2) NULL,
  CurrentOdometer       DECIMAL(12,2) NOT NULL DEFAULT 0,
  OdometerUnit          NVARCHAR(5) NOT NULL DEFAULT 'KM',
  DefaultDriverId       BIGINT NULL,
  WarehouseId           BIGINT NULL,
  PurchaseDate          DATE NULL,
  PurchaseCost          DECIMAL(18,2) NULL,
  InsurancePolicy       NVARCHAR(60) NULL,
  InsuranceExpiry       DATE NULL,
  [Status]                NVARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
  Notes                 NVARCHAR(500) NULL,
  IsActive              BIT NOT NULL DEFAULT 1,
  CreatedAt             DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
  UpdatedAt             DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
  CreatedByUserId       INT NULL,
  UpdatedByUserId       INT NULL,
  IsDeleted             BIT NOT NULL DEFAULT 0,
  DeletedAt             DATETIME2(0) NULL,
  DeletedByUserId       INT NULL,
  CONSTRAINT CK_fleet_Vehicle_Type CHECK (VehicleType IN ('CAR', 'TRUCK', 'VAN', 'MOTORCYCLE', 'BUS', 'TRAILER', 'FORKLIFT', 'OTHER')),
  CONSTRAINT CK_fleet_Vehicle_Fuel CHECK (FuelType IN ('GASOLINE', 'DIESEL', 'GAS', 'ELECTRIC', 'HYBRID', 'OTHER')),
  CONSTRAINT CK_fleet_Vehicle_OdoUnit CHECK (OdometerUnit IN ('KM', 'MI')),
  CONSTRAINT CK_fleet_Vehicle_Status CHECK ([Status] IN ('ACTIVE', 'IN_MAINTENANCE', 'OUT_OF_SERVICE', 'SOLD', 'SCRAPPED')),
  CONSTRAINT UQ_fleet_Vehicle_Code UNIQUE (CompanyId, VehicleCode),
  CONSTRAINT UQ_fleet_Vehicle_Plate UNIQUE (CompanyId, LicensePlate),
  CONSTRAINT FK_fleet_Vehicle_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId),
  CONSTRAINT FK_fleet_Vehicle_Driver FOREIGN KEY (DefaultDriverId) REFERENCES logistics.Driver(DriverId),
  CONSTRAINT FK_fleet_Vehicle_Warehouse FOREIGN KEY (WarehouseId) REFERENCES inv.Warehouse(WarehouseId),
  CONSTRAINT FK_fleet_Vehicle_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
  CONSTRAINT FK_fleet_Vehicle_UpdatedBy FOREIGN KEY (UpdatedByUserId) REFERENCES sec.[User](UserId),
  CONSTRAINT FK_fleet_Vehicle_DeletedBy FOREIGN KEY (DeletedByUserId) REFERENCES sec.[User](UserId)
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_fleet_Vehicle_Company')
  CREATE INDEX IX_fleet_Vehicle_Company ON fleet.Vehicle (CompanyId, IsDeleted, IsActive);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_fleet_Vehicle_Status')
  CREATE INDEX IX_fleet_Vehicle_Status ON fleet.Vehicle (CompanyId, [Status]) WHERE IsDeleted = 0;
GO

IF OBJECT_ID('fleet.FuelLog', 'U') IS NULL
CREATE TABLE fleet.FuelLog(
  FuelLogId             BIGINT IDENTITY(1,1) PRIMARY KEY,
  CompanyId             INT NOT NULL,
  VehicleId             BIGINT NOT NULL,
  DriverId              BIGINT NULL,
  FuelDate              DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
  FuelType              NVARCHAR(20) NOT NULL,
  Quantity              DECIMAL(10,3) NOT NULL,
  UnitPrice             DECIMAL(18,4) NOT NULL,
  TotalCost             DECIMAL(18,2) NOT NULL,
  CurrencyCode          NCHAR(3) NOT NULL DEFAULT 'USD',
  OdometerReading       DECIMAL(12,2) NULL,
  IsFullTank            BIT NOT NULL DEFAULT 1,
  StationName           NVARCHAR(200) NULL,
  InvoiceNumber         NVARCHAR(60) NULL,
  Notes                 NVARCHAR(500) NULL,
  CreatedAt             DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
  UpdatedAt             DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
  CreatedByUserId       INT NULL,
  UpdatedByUserId       INT NULL,
  IsDeleted             BIT NOT NULL DEFAULT 0,
  DeletedAt             DATETIME2(0) NULL,
  DeletedByUserId       INT NULL,
  CONSTRAINT FK_fleet_FuelLog_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId),
  CONSTRAINT FK_fleet_FuelLog_Vehicle FOREIGN KEY (VehicleId) REFERENCES fleet.Vehicle(VehicleId),
  CONSTRAINT FK_fleet_FuelLog_Driver FOREIGN KEY (DriverId) REFERENCES logistics.Driver(DriverId),
  CONSTRAINT FK_fleet_FuelLog_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
  CONSTRAINT FK_fleet_FuelLog_UpdatedBy FOREIGN KEY (UpdatedByUserId) REFERENCES sec.[User](UserId),
  CONSTRAINT FK_fleet_FuelLog_DeletedBy FOREIGN KEY (DeletedByUserId) REFERENCES sec.[User](UserId)
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_fleet_FuelLog_Vehicle')
  CREATE INDEX IX_fleet_FuelLog_Vehicle ON fleet.FuelLog (VehicleId, FuelDate DESC);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_fleet_FuelLog_Company')
  CREATE INDEX IX_fleet_FuelLog_Company ON fleet.FuelLog (CompanyId, FuelDate DESC) WHERE IsDeleted = 0;
GO

IF OBJECT_ID('fleet.MaintenanceType', 'U') IS NULL
CREATE TABLE fleet.MaintenanceType(
  MaintenanceTypeId     BIGINT IDENTITY(1,1) PRIMARY KEY,
  CompanyId             INT NOT NULL,
  TypeCode              NVARCHAR(20) NOT NULL,
  TypeName              NVARCHAR(200) NOT NULL,
  Category              NVARCHAR(20) NOT NULL DEFAULT 'PREVENTIVE',
  DefaultIntervalKm     DECIMAL(12,2) NULL,
  DefaultIntervalDays   INT NULL,
  IsActive              BIT NOT NULL DEFAULT 1,
  CreatedAt             DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
  UpdatedAt             DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
  CreatedByUserId       INT NULL,
  UpdatedByUserId       INT NULL,
  IsDeleted             BIT NOT NULL DEFAULT 0,
  DeletedAt             DATETIME2(0) NULL,
  DeletedByUserId       INT NULL,
  CONSTRAINT CK_fleet_MaintType_Category CHECK (Category IN ('PREVENTIVE', 'CORRECTIVE', 'PREDICTIVE', 'INSPECTION')),
  CONSTRAINT UQ_fleet_MaintType_Code UNIQUE (CompanyId, TypeCode),
  CONSTRAINT FK_fleet_MaintType_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId),
  CONSTRAINT FK_fleet_MaintType_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
  CONSTRAINT FK_fleet_MaintType_UpdatedBy FOREIGN KEY (UpdatedByUserId) REFERENCES sec.[User](UserId),
  CONSTRAINT FK_fleet_MaintType_DeletedBy FOREIGN KEY (DeletedByUserId) REFERENCES sec.[User](UserId)
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_fleet_MaintType_Company')
  CREATE INDEX IX_fleet_MaintType_Company ON fleet.MaintenanceType (CompanyId, IsDeleted, IsActive);
GO

IF OBJECT_ID('fleet.MaintenanceOrder', 'U') IS NULL
CREATE TABLE fleet.MaintenanceOrder(
  MaintenanceOrderId    BIGINT IDENTITY(1,1) PRIMARY KEY,
  CompanyId             INT NOT NULL,
  VehicleId             BIGINT NOT NULL,
  MaintenanceTypeId     BIGINT NOT NULL,
  OrderNumber           NVARCHAR(30) NOT NULL,
  OrderDate             DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
  OdometerAtService     DECIMAL(12,2) NULL,
  [Status]                NVARCHAR(20) NOT NULL DEFAULT 'DRAFT',
  Priority              NVARCHAR(10) NOT NULL DEFAULT 'MEDIUM',
  ScheduledDate         DATETIME2(0) NULL,
  StartedAt             DATETIME2(0) NULL,
  CompletedAt           DATETIME2(0) NULL,
  WorkshopName          NVARCHAR(200) NULL,
  TechnicianName        NVARCHAR(200) NULL,
  TotalLaborCost        DECIMAL(18,2) NOT NULL DEFAULT 0,
  TotalPartsCost        DECIMAL(18,2) NOT NULL DEFAULT 0,
  TotalCost             DECIMAL(18,2) NOT NULL DEFAULT 0,
  CurrencyCode          NCHAR(3) NOT NULL DEFAULT 'USD',
  Notes                 NVARCHAR(500) NULL,
  CreatedAt             DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
  UpdatedAt             DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
  CreatedByUserId       INT NULL,
  UpdatedByUserId       INT NULL,
  IsDeleted             BIT NOT NULL DEFAULT 0,
  DeletedAt             DATETIME2(0) NULL,
  DeletedByUserId       INT NULL,
  CONSTRAINT CK_fleet_MaintOrder_Status CHECK ([Status] IN ('DRAFT', 'SCHEDULED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED')),
  CONSTRAINT CK_fleet_MaintOrder_Priority CHECK (Priority IN ('LOW', 'MEDIUM', 'HIGH', 'URGENT')),
  CONSTRAINT UQ_fleet_MaintOrder_Number UNIQUE (CompanyId, OrderNumber),
  CONSTRAINT FK_fleet_MaintOrder_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId),
  CONSTRAINT FK_fleet_MaintOrder_Vehicle FOREIGN KEY (VehicleId) REFERENCES fleet.Vehicle(VehicleId),
  CONSTRAINT FK_fleet_MaintOrder_Type FOREIGN KEY (MaintenanceTypeId) REFERENCES fleet.MaintenanceType(MaintenanceTypeId),
  CONSTRAINT FK_fleet_MaintOrder_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
  CONSTRAINT FK_fleet_MaintOrder_UpdatedBy FOREIGN KEY (UpdatedByUserId) REFERENCES sec.[User](UserId),
  CONSTRAINT FK_fleet_MaintOrder_DeletedBy FOREIGN KEY (DeletedByUserId) REFERENCES sec.[User](UserId)
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_fleet_MaintOrder_Vehicle')
  CREATE INDEX IX_fleet_MaintOrder_Vehicle ON fleet.MaintenanceOrder (VehicleId, OrderDate DESC);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_fleet_MaintOrder_Status')
  CREATE INDEX IX_fleet_MaintOrder_Status ON fleet.MaintenanceOrder (CompanyId, [Status]) WHERE IsDeleted = 0;
GO

IF OBJECT_ID('fleet.MaintenanceOrderLine', 'U') IS NULL
CREATE TABLE fleet.MaintenanceOrderLine(
  MaintenanceOrderLineId BIGINT IDENTITY(1,1) PRIMARY KEY,
  MaintenanceOrderId    BIGINT NOT NULL,
  LineNumber            INT NOT NULL,
  LineType              NVARCHAR(10) NOT NULL DEFAULT 'PART',
  ProductId             BIGINT NULL,
  Description           NVARCHAR(300) NOT NULL,
  Quantity              DECIMAL(18,3) NOT NULL DEFAULT 1,
  UnitCost              DECIMAL(18,4) NOT NULL DEFAULT 0,
  TotalCost             DECIMAL(18,2) NOT NULL DEFAULT 0,
  Notes                 NVARCHAR(500) NULL,
  CreatedAt             DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
  UpdatedAt             DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
  CONSTRAINT CK_fleet_MOLine_Type CHECK (LineType IN ('PART', 'LABOR', 'SERVICE', 'OTHER')),
  CONSTRAINT UQ_fleet_MOLine UNIQUE (MaintenanceOrderId, LineNumber),
  CONSTRAINT FK_fleet_MOLine_Order FOREIGN KEY (MaintenanceOrderId) REFERENCES fleet.MaintenanceOrder(MaintenanceOrderId),
  CONSTRAINT FK_fleet_MOLine_Product FOREIGN KEY (ProductId) REFERENCES mstr.Product(ProductId)
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_fleet_MOLine_Order')
  CREATE INDEX IX_fleet_MOLine_Order ON fleet.MaintenanceOrderLine (MaintenanceOrderId);
GO

IF OBJECT_ID('fleet.Trip', 'U') IS NULL
CREATE TABLE fleet.Trip(
  TripId                BIGINT IDENTITY(1,1) PRIMARY KEY,
  CompanyId             INT NOT NULL,
  VehicleId             BIGINT NOT NULL,
  DriverId              BIGINT NULL,
  DeliveryNoteId        BIGINT NULL,
  TripNumber            NVARCHAR(30) NOT NULL,
  TripDate              DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
  Origin                NVARCHAR(300) NULL,
  Destination           NVARCHAR(300) NULL,
  DistanceKm            DECIMAL(10,2) NULL,
  OdometerStart         DECIMAL(12,2) NULL,
  OdometerEnd           DECIMAL(12,2) NULL,
  DepartedAt            DATETIME2(0) NULL,
  ArrivedAt             DATETIME2(0) NULL,
  [Status]                NVARCHAR(20) NOT NULL DEFAULT 'PLANNED',
  Notes                 NVARCHAR(500) NULL,
  CreatedAt             DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
  UpdatedAt             DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
  CreatedByUserId       INT NULL,
  UpdatedByUserId       INT NULL,
  IsDeleted             BIT NOT NULL DEFAULT 0,
  DeletedAt             DATETIME2(0) NULL,
  DeletedByUserId       INT NULL,
  CONSTRAINT CK_fleet_Trip_Status CHECK ([Status] IN ('PLANNED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED')),
  CONSTRAINT UQ_fleet_Trip_Number UNIQUE (CompanyId, TripNumber),
  CONSTRAINT FK_fleet_Trip_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId),
  CONSTRAINT FK_fleet_Trip_Vehicle FOREIGN KEY (VehicleId) REFERENCES fleet.Vehicle(VehicleId),
  CONSTRAINT FK_fleet_Trip_Driver FOREIGN KEY (DriverId) REFERENCES logistics.Driver(DriverId),
  CONSTRAINT FK_fleet_Trip_DeliveryNote FOREIGN KEY (DeliveryNoteId) REFERENCES logistics.DeliveryNote(DeliveryNoteId),
  CONSTRAINT FK_fleet_Trip_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
  CONSTRAINT FK_fleet_Trip_UpdatedBy FOREIGN KEY (UpdatedByUserId) REFERENCES sec.[User](UserId),
  CONSTRAINT FK_fleet_Trip_DeletedBy FOREIGN KEY (DeletedByUserId) REFERENCES sec.[User](UserId)
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_fleet_Trip_Vehicle')
  CREATE INDEX IX_fleet_Trip_Vehicle ON fleet.Trip (VehicleId, TripDate DESC);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_fleet_Trip_Company')
  CREATE INDEX IX_fleet_Trip_Company ON fleet.Trip (CompanyId, TripDate DESC) WHERE IsDeleted = 0;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_fleet_Trip_DeliveryNote')
  CREATE INDEX IX_fleet_Trip_DeliveryNote ON fleet.Trip (DeliveryNoteId) WHERE DeliveryNoteId IS NOT NULL;
GO

IF OBJECT_ID('fleet.VehicleDocument', 'U') IS NULL
CREATE TABLE fleet.VehicleDocument(
  VehicleDocumentId     BIGINT IDENTITY(1,1) PRIMARY KEY,
  VehicleId             BIGINT NOT NULL,
  DocumentType          NVARCHAR(30) NOT NULL,
  DocumentNumber        NVARCHAR(60) NULL,
  Description           NVARCHAR(300) NULL,
  IssuedAt              DATE NULL,
  ExpiresAt             DATE NULL,
  FileUrl               NVARCHAR(500) NULL,
  Notes                 NVARCHAR(500) NULL,
  CreatedAt             DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
  UpdatedAt             DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
  CreatedByUserId       INT NULL,
  UpdatedByUserId       INT NULL,
  IsDeleted             BIT NOT NULL DEFAULT 0,
  DeletedAt             DATETIME2(0) NULL,
  DeletedByUserId       INT NULL,
  CONSTRAINT CK_fleet_VehicleDoc_Type CHECK (DocumentType IN ('REGISTRATION', 'INSURANCE', 'INSPECTION', 'PERMIT', 'WARRANTY', 'TITLE', 'OTHER')),
  CONSTRAINT FK_fleet_VehicleDoc_Vehicle FOREIGN KEY (VehicleId) REFERENCES fleet.Vehicle(VehicleId),
  CONSTRAINT FK_fleet_VehicleDoc_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
  CONSTRAINT FK_fleet_VehicleDoc_UpdatedBy FOREIGN KEY (UpdatedByUserId) REFERENCES sec.[User](UserId),
  CONSTRAINT FK_fleet_VehicleDoc_DeletedBy FOREIGN KEY (DeletedByUserId) REFERENCES sec.[User](UserId)
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_fleet_VehicleDoc_Vehicle')
  CREATE INDEX IX_fleet_VehicleDoc_Vehicle ON fleet.VehicleDocument (VehicleId) WHERE IsDeleted = 0;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_fleet_VehicleDoc_Expiry')
  CREATE INDEX IX_fleet_VehicleDoc_Expiry ON fleet.VehicleDocument (ExpiresAt) WHERE ExpiresAt IS NOT NULL AND IsDeleted = 0;
GO

IF OBJECT_ID('sec.Permission', 'U') IS NULL
CREATE TABLE sec.Permission(
  PermissionId          BIGINT IDENTITY(1,1) PRIMARY KEY,
  PermissionCode        NVARCHAR(80) NOT NULL,
  PermissionName        NVARCHAR(200) NOT NULL,
  Module                NVARCHAR(40) NOT NULL,
  Category              NVARCHAR(40) NULL,
  Description           NVARCHAR(500) NULL,
  IsSystem              BIT NOT NULL DEFAULT 0,
  IsActive              BIT NOT NULL DEFAULT 1,
  CreatedAt             DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
  UpdatedAt             DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
  CreatedByUserId       INT NULL,
  UpdatedByUserId       INT NULL,
  IsDeleted             BIT NOT NULL DEFAULT 0,
  DeletedAt             DATETIME2(0) NULL,
  DeletedByUserId       INT NULL,
  CONSTRAINT UQ_sec_Permission_Code UNIQUE (PermissionCode),
  CONSTRAINT FK_sec_Permission_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
  CONSTRAINT FK_sec_Permission_UpdatedBy FOREIGN KEY (UpdatedByUserId) REFERENCES sec.[User](UserId),
  CONSTRAINT FK_sec_Permission_DeletedBy FOREIGN KEY (DeletedByUserId) REFERENCES sec.[User](UserId)
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_sec_Permission_Module')
  CREATE INDEX IX_sec_Permission_Module ON sec.Permission (Module, IsDeleted, IsActive);
GO

IF OBJECT_ID('sec.RolePermission', 'U') IS NULL
CREATE TABLE sec.RolePermission(
  RolePermissionId      BIGINT IDENTITY(1,1) PRIMARY KEY,
  RoleId                INT NOT NULL,
  PermissionId          BIGINT NOT NULL,
  CanCreate             BIT NOT NULL DEFAULT 0,
  CanRead               BIT NOT NULL DEFAULT 1,
  CanUpdate             BIT NOT NULL DEFAULT 0,
  CanDelete             BIT NOT NULL DEFAULT 0,
  CanExport             BIT NOT NULL DEFAULT 0,
  CanApprove            BIT NOT NULL DEFAULT 0,
  CreatedAt             DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
  UpdatedAt             DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
  CreatedByUserId       INT NULL,
  UpdatedByUserId       INT NULL,
  CONSTRAINT UQ_sec_RolePermission UNIQUE (RoleId, PermissionId),
  CONSTRAINT FK_sec_RolePermission_Role FOREIGN KEY (RoleId) REFERENCES sec.[Role](RoleId),
  CONSTRAINT FK_sec_RolePermission_Permission FOREIGN KEY (PermissionId) REFERENCES sec.Permission(PermissionId),
  CONSTRAINT FK_sec_RolePermission_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
  CONSTRAINT FK_sec_RolePermission_UpdatedBy FOREIGN KEY (UpdatedByUserId) REFERENCES sec.[User](UserId)
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_sec_RolePermission_Role')
  CREATE INDEX IX_sec_RolePermission_Role ON sec.RolePermission (RoleId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_sec_RolePermission_Permission')
  CREATE INDEX IX_sec_RolePermission_Permission ON sec.RolePermission (PermissionId);
GO

IF OBJECT_ID('sec.UserPermissionOverride', 'U') IS NULL
CREATE TABLE sec.UserPermissionOverride(
  UserPermissionOverrideId BIGINT IDENTITY(1,1) PRIMARY KEY,
  UserId                INT NOT NULL,
  PermissionId          BIGINT NOT NULL,
  OverrideType          NVARCHAR(10) NOT NULL DEFAULT 'GRANT',
  CanCreate             BIT NULL,
  CanRead               BIT NULL,
  CanUpdate             BIT NULL,
  CanDelete             BIT NULL,
  CanExport             BIT NULL,
  CanApprove            BIT NULL,
  ExpiresAt             DATETIME2(0) NULL,
  Reason                NVARCHAR(500) NULL,
  CreatedAt             DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
  UpdatedAt             DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
  CreatedByUserId       INT NULL,
  UpdatedByUserId       INT NULL,
  IsDeleted             BIT NOT NULL DEFAULT 0,
  DeletedAt             DATETIME2(0) NULL,
  DeletedByUserId       INT NULL,
  CONSTRAINT CK_sec_UPOverride_Type CHECK (OverrideType IN ('GRANT', 'DENY')),
  CONSTRAINT UQ_sec_UserPermOverride UNIQUE (UserId, PermissionId),
  CONSTRAINT FK_sec_UPOverride_User FOREIGN KEY (UserId) REFERENCES sec.[User](UserId),
  CONSTRAINT FK_sec_UPOverride_Permission FOREIGN KEY (PermissionId) REFERENCES sec.Permission(PermissionId),
  CONSTRAINT FK_sec_UPOverride_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
  CONSTRAINT FK_sec_UPOverride_UpdatedBy FOREIGN KEY (UpdatedByUserId) REFERENCES sec.[User](UserId),
  CONSTRAINT FK_sec_UPOverride_DeletedBy FOREIGN KEY (DeletedByUserId) REFERENCES sec.[User](UserId)
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_sec_UPOverride_User')
  CREATE INDEX IX_sec_UPOverride_User ON sec.UserPermissionOverride (UserId) WHERE IsDeleted = 0;
GO

IF OBJECT_ID('sec.PriceRestriction', 'U') IS NULL
CREATE TABLE sec.PriceRestriction(
  PriceRestrictionId    BIGINT IDENTITY(1,1) PRIMARY KEY,
  CompanyId             INT NOT NULL,
  RoleId                INT NULL,
  UserId                INT NULL,
  MaxDiscountPercent    DECIMAL(5,2) NOT NULL DEFAULT 0,
  MinMarginPercent      DECIMAL(5,2) NULL,
  MaxCreditAmount       DECIMAL(18,2) NULL,
  CurrencyCode          NCHAR(3) NULL,
  CanOverridePrice      BIT NOT NULL DEFAULT 0,
  CanGiveFreeItems      BIT NOT NULL DEFAULT 0,
  RequiresApprovalAbove DECIMAL(18,2) NULL,
  IsActive              BIT NOT NULL DEFAULT 1,
  CreatedAt             DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
  UpdatedAt             DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
  CreatedByUserId       INT NULL,
  UpdatedByUserId       INT NULL,
  IsDeleted             BIT NOT NULL DEFAULT 0,
  DeletedAt             DATETIME2(0) NULL,
  DeletedByUserId       INT NULL,
  CONSTRAINT FK_sec_PriceRestr_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId),
  CONSTRAINT FK_sec_PriceRestr_Role FOREIGN KEY (RoleId) REFERENCES sec.[Role](RoleId),
  CONSTRAINT FK_sec_PriceRestr_User FOREIGN KEY (UserId) REFERENCES sec.[User](UserId),
  CONSTRAINT FK_sec_PriceRestr_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
  CONSTRAINT FK_sec_PriceRestr_UpdatedBy FOREIGN KEY (UpdatedByUserId) REFERENCES sec.[User](UserId),
  CONSTRAINT FK_sec_PriceRestr_DeletedBy FOREIGN KEY (DeletedByUserId) REFERENCES sec.[User](UserId)
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_sec_PriceRestr_Role')
  CREATE INDEX IX_sec_PriceRestr_Role ON sec.PriceRestriction (RoleId) WHERE RoleId IS NOT NULL AND IsDeleted = 0;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_sec_PriceRestr_User')
  CREATE INDEX IX_sec_PriceRestr_User ON sec.PriceRestriction (UserId) WHERE UserId IS NOT NULL AND IsDeleted = 0;
GO

IF OBJECT_ID('sec.ApprovalRule', 'U') IS NULL
CREATE TABLE sec.ApprovalRule(
  ApprovalRuleId        BIGINT IDENTITY(1,1) PRIMARY KEY,
  CompanyId             INT NOT NULL,
  RuleCode              NVARCHAR(30) NOT NULL,
  RuleName              NVARCHAR(200) NOT NULL,
  DocumentType          NVARCHAR(30) NOT NULL,
  [Condition]             NVARCHAR(30) NOT NULL DEFAULT 'AMOUNT_ABOVE',
  ThresholdAmount       DECIMAL(18,2) NULL,
  CurrencyCode          NCHAR(3) NULL,
  ApproverRoleId        INT NULL,
  ApproverUserId        INT NULL,
  RequiredApprovals     INT NOT NULL DEFAULT 1,
  AutoApproveBelow      DECIMAL(18,2) NULL,
  EscalateAfterHours    INT NULL,
  EscalateToUserId      INT NULL,
  IsActive              BIT NOT NULL DEFAULT 1,
  CreatedAt             DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
  UpdatedAt             DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
  CreatedByUserId       INT NULL,
  UpdatedByUserId       INT NULL,
  IsDeleted             BIT NOT NULL DEFAULT 0,
  DeletedAt             DATETIME2(0) NULL,
  DeletedByUserId       INT NULL,
  CONSTRAINT CK_sec_ApprovalRule_Condition CHECK ([Condition] IN ('AMOUNT_ABOVE', 'DISCOUNT_ABOVE', 'CREDIT_LIMIT', 'ALWAYS', 'CUSTOM')),
  CONSTRAINT UQ_sec_ApprovalRule_Code UNIQUE (CompanyId, RuleCode),
  CONSTRAINT FK_sec_ApprovalRule_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId),
  CONSTRAINT FK_sec_ApprovalRule_ApproverRole FOREIGN KEY (ApproverRoleId) REFERENCES sec.[Role](RoleId),
  CONSTRAINT FK_sec_ApprovalRule_ApproverUser FOREIGN KEY (ApproverUserId) REFERENCES sec.[User](UserId),
  CONSTRAINT FK_sec_ApprovalRule_EscalateTo FOREIGN KEY (EscalateToUserId) REFERENCES sec.[User](UserId),
  CONSTRAINT FK_sec_ApprovalRule_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
  CONSTRAINT FK_sec_ApprovalRule_UpdatedBy FOREIGN KEY (UpdatedByUserId) REFERENCES sec.[User](UserId),
  CONSTRAINT FK_sec_ApprovalRule_DeletedBy FOREIGN KEY (DeletedByUserId) REFERENCES sec.[User](UserId)
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_sec_ApprovalRule_Company')
  CREATE INDEX IX_sec_ApprovalRule_Company ON sec.ApprovalRule (CompanyId, DocumentType, IsActive) WHERE IsDeleted = 0;
GO

IF OBJECT_ID('sec.ApprovalRequest', 'U') IS NULL
CREATE TABLE sec.ApprovalRequest(
  ApprovalRequestId     BIGINT IDENTITY(1,1) PRIMARY KEY,
  CompanyId             INT NOT NULL,
  ApprovalRuleId        BIGINT NOT NULL,
  DocumentType          NVARCHAR(30) NOT NULL,
  DocumentId            BIGINT NOT NULL,
  DocumentNumber        NVARCHAR(60) NULL,
  RequestedAmount       DECIMAL(18,2) NULL,
  CurrencyCode          NCHAR(3) NULL,
  [Status]                NVARCHAR(20) NOT NULL DEFAULT 'PENDING',
  RequestedByUserId     INT NOT NULL,
  RequestedAt           DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
  ResolvedAt            DATETIME2(0) NULL,
  Notes                 NVARCHAR(500) NULL,
  CreatedAt             DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
  UpdatedAt             DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
  CONSTRAINT CK_sec_ApprovalRequest_Status CHECK ([Status] IN ('PENDING', 'APPROVED', 'REJECTED', 'ESCALATED', 'CANCELLED', 'EXPIRED')),
  CONSTRAINT FK_sec_ApprovalReq_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId),
  CONSTRAINT FK_sec_ApprovalReq_Rule FOREIGN KEY (ApprovalRuleId) REFERENCES sec.ApprovalRule(ApprovalRuleId),
  CONSTRAINT FK_sec_ApprovalReq_RequestedBy FOREIGN KEY (RequestedByUserId) REFERENCES sec.[User](UserId)
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_sec_ApprovalReq_Status')
  CREATE INDEX IX_sec_ApprovalReq_Status ON sec.ApprovalRequest (CompanyId, [Status]) WHERE [Status] = 'PENDING';
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_sec_ApprovalReq_Document')
  CREATE INDEX IX_sec_ApprovalReq_Document ON sec.ApprovalRequest (DocumentType, DocumentId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_sec_ApprovalReq_RequestedBy')
  CREATE INDEX IX_sec_ApprovalReq_RequestedBy ON sec.ApprovalRequest (RequestedByUserId, [Status]);
GO

IF OBJECT_ID('sec.ApprovalAction', 'U') IS NULL
CREATE TABLE sec.ApprovalAction(
  ApprovalActionId      BIGINT IDENTITY(1,1) PRIMARY KEY,
  ApprovalRequestId     BIGINT NOT NULL,
  ActionType            NVARCHAR(20) NOT NULL,
  ActionByUserId        INT NOT NULL,
  ActionAt              DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
  Comments              NVARCHAR(500) NULL,
  CONSTRAINT CK_sec_ApprovalAction_Type CHECK (ActionType IN ('APPROVE', 'REJECT', 'ESCALATE', 'COMMENT', 'CANCEL')),
  CONSTRAINT FK_sec_ApprovalAction_Request FOREIGN KEY (ApprovalRequestId) REFERENCES sec.ApprovalRequest(ApprovalRequestId),
  CONSTRAINT FK_sec_ApprovalAction_ActionBy FOREIGN KEY (ActionByUserId) REFERENCES sec.[User](UserId)
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_sec_ApprovalAction_Request')
  CREATE INDEX IX_sec_ApprovalAction_Request ON sec.ApprovalAction (ApprovalRequestId, ActionAt);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_sec_ApprovalAction_User')
  CREATE INDEX IX_sec_ApprovalAction_User ON sec.ApprovalAction (ActionByUserId, ActionAt DESC);
GO

IF COL_LENGTH('mstr.Product', 'SearchVector') IS NULL
  ALTER TABLE mstr.Product ADD SearchVector TSVECTOR;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_master_Product_fulltext')
  CREATE INDEX IX_master_Product_fulltext ON mstr.Product  (SearchVector);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_master_Product_code_trgm')
  CREATE INDEX IX_master_Product_code_trgm ON mstr.Product  (ProductCode gin_trgm_ops);
GO

IF OBJECT_ID('ar.SalesDocument', 'U') IS NULL
CREATE TABLE ar.SalesDocument (
    DocumentId          INT IDENTITY(1,1) NOT NULL,
    DocumentNumber      NVARCHAR(60)   NOT NULL,
    SerialType          NVARCHAR(60)   NOT NULL DEFAULT '',
    FiscalMemoryNumber  NVARCHAR(80)   NULL DEFAULT '',
    OperationType       NVARCHAR(20)   NOT NULL,
    CustomerCode        NVARCHAR(60)   NULL,
    CustomerName        NVARCHAR(255)  NULL,
    FiscalId            NVARCHAR(20)   NULL,
    DocumentDate        DATETIME2(0)     NULL DEFAULT SYSUTCDATETIME(),
    DueDate             DATETIME2(0)     NULL,
    DocumentTime        NVARCHAR(20)   NULL DEFAULT CONVERT(NVARCHAR(8), SYSUTCDATETIME(), 108),
    SubTotal            DECIMAL(18,4) NULL DEFAULT 0,
    TaxableAmount       DECIMAL(18,4) NULL DEFAULT 0,
    ExemptAmount        DECIMAL(18,4) NULL DEFAULT 0,
    TaxAmount           DECIMAL(18,4) NULL DEFAULT 0,
    TaxRate             DECIMAL(8,4)  NULL DEFAULT 0,
    TotalAmount         DECIMAL(18,4) NULL DEFAULT 0,
    DiscountAmount      DECIMAL(18,4) NULL DEFAULT 0,
    IsVoided            BIT       NULL DEFAULT 0,
    IsPaid              NVARCHAR(1)    NULL DEFAULT 'N',
    IsInvoiced          NVARCHAR(1)    NULL DEFAULT 'N',
    IsDelivered         NVARCHAR(1)    NULL DEFAULT 'N',
    OriginDocumentNumber NVARCHAR(60)  NULL,
    OriginDocumentType  NVARCHAR(20)   NULL,
    ControlNumber       NVARCHAR(60)   NULL,
    IsLegal             BIT       NULL DEFAULT 0,
    IsPrinted           BIT       NULL DEFAULT 0,
    Notes               NVARCHAR(500)  NULL,
    Concept             NVARCHAR(255)  NULL,
    PaymentTerms        NVARCHAR(255)  NULL,
    ShipToAddress       NVARCHAR(255)  NULL,
    SellerCode          NVARCHAR(60)   NULL,
    DepartmentCode      NVARCHAR(50)   NULL,
    LocationCode        NVARCHAR(100)  NULL,
    CurrencyCode        NVARCHAR(20)   NULL DEFAULT 'BS',
    ExchangeRate        DECIMAL(18,6) NULL DEFAULT 1,
    UserCode            NVARCHAR(60)   NULL DEFAULT 'API',
    ReportDate          DATETIME2(0)     NULL DEFAULT SYSUTCDATETIME(),
    HostName            NVARCHAR(255)  NULL,
    VehiclePlate        NVARCHAR(20)   NULL,
    Mileage             INT           NULL,
    TollAmount          DECIMAL(18,4) NULL DEFAULT 0,
    CreatedAt           DATETIME2(0)     NOT NULL DEFAULT SYSUTCDATETIME(),
    UpdatedAt           DATETIME2(0)     NOT NULL DEFAULT SYSUTCDATETIME(),
    CreatedByUserId     INT           NULL,
    UpdatedByUserId     INT           NULL,
    IsDeleted           BIT       NOT NULL DEFAULT 0,
    DeletedAt           DATETIME2(0)     NULL,
    DeletedByUserId     INT           NULL,
    CONSTRAINT PK_SalesDocument PRIMARY KEY (DocumentId),
    CONSTRAINT UQ_SalesDocument_NumDocOp UNIQUE (DocumentNumber, OperationType)
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_SalesDocument_Customer')
  CREATE INDEX IX_SalesDocument_Customer ON ar.SalesDocument (CustomerCode);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_SalesDocument_OpDate')
  CREATE INDEX IX_SalesDocument_OpDate ON ar.SalesDocument (OperationType, DocumentDate DESC) WHERE IsDeleted = 0;
GO

IF OBJECT_ID('ar.SalesDocumentLine', 'U') IS NULL
CREATE TABLE ar.SalesDocumentLine (
    LineId              INT IDENTITY(1,1) NOT NULL,
    DocumentNumber      NVARCHAR(60)   NOT NULL,
    SerialType          NVARCHAR(60)   NOT NULL DEFAULT '',
    FiscalMemoryNumber  NVARCHAR(80)   NULL DEFAULT '',
    OperationType       NVARCHAR(20)   NOT NULL,
    LineNumber          INT           NULL DEFAULT 0,
    ProductCode         NVARCHAR(60)   NULL,
    Description         NVARCHAR(255)  NULL,
    AlternateCode       NVARCHAR(60)   NULL,
    Quantity            DECIMAL(18,4) NULL DEFAULT 0,
    UnitPrice           DECIMAL(18,4) NULL DEFAULT 0,
    DiscountedPrice     DECIMAL(18,4) NULL DEFAULT 0,
    UnitCost            DECIMAL(18,4) NULL DEFAULT 0,
    SubTotal            DECIMAL(18,4) NULL DEFAULT 0,
    DiscountAmount      DECIMAL(18,4) NULL DEFAULT 0,
    TotalAmount         DECIMAL(18,4) NULL DEFAULT 0,
    TaxRate             DECIMAL(8,4)  NULL DEFAULT 0,
    TaxAmount           DECIMAL(18,4) NULL DEFAULT 0,
    IsVoided            BIT       NULL DEFAULT 0,
    RelatedRef          NVARCHAR(10)   NULL DEFAULT '0',
    UserCode            NVARCHAR(60)   NULL DEFAULT 'API',
    LineDate            DATETIME2(0)     NULL DEFAULT SYSUTCDATETIME(),
    CreatedAt           DATETIME2(0)     NOT NULL DEFAULT SYSUTCDATETIME(),
    UpdatedAt           DATETIME2(0)     NOT NULL DEFAULT SYSUTCDATETIME(),
    CreatedByUserId     INT           NULL,
    UpdatedByUserId     INT           NULL,
    IsDeleted           BIT       NOT NULL DEFAULT 0,
    DeletedAt           DATETIME2(0)     NULL,
    DeletedByUserId     INT           NULL,
    CONSTRAINT PK_SalesDocumentLine PRIMARY KEY (LineId)
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_SalesDocLine_DocKey')
  CREATE INDEX IX_SalesDocLine_DocKey ON ar.SalesDocumentLine (DocumentNumber, OperationType) WHERE IsDeleted = 0;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_SalesDocLine_Product')
  CREATE INDEX IX_SalesDocLine_Product ON ar.SalesDocumentLine (ProductCode);
GO

IF OBJECT_ID('ar.SalesDocumentPayment', 'U') IS NULL
CREATE TABLE ar.SalesDocumentPayment (
    PaymentId           INT IDENTITY(1,1) NOT NULL,
    DocumentNumber      NVARCHAR(60)   NOT NULL,
    SerialType          NVARCHAR(60)   NOT NULL DEFAULT '',
    FiscalMemoryNumber  NVARCHAR(80)   NULL DEFAULT '',
    OperationType       NVARCHAR(20)   NOT NULL DEFAULT 'FACT',
    PaymentMethod       NVARCHAR(30)   NULL,
    BankCode            NVARCHAR(60)   NULL,
    PaymentNumber       NVARCHAR(60)   NULL,
    Amount              DECIMAL(18,4) NULL DEFAULT 0,
    AmountBs            DECIMAL(18,4) NULL DEFAULT 0,
    ExchangeRate        DECIMAL(18,6) NULL DEFAULT 1,
    PaymentDate         DATETIME2(0)     NULL DEFAULT SYSUTCDATETIME(),
    DueDate             DATETIME2(0)     NULL,
    ReferenceNumber     NVARCHAR(100)  NULL,
    UserCode            NVARCHAR(60)   NULL DEFAULT 'API',
    CreatedAt           DATETIME2(0)     NOT NULL DEFAULT SYSUTCDATETIME(),
    UpdatedAt           DATETIME2(0)     NOT NULL DEFAULT SYSUTCDATETIME(),
    CreatedByUserId     INT           NULL,
    UpdatedByUserId     INT           NULL,
    IsDeleted           BIT       NOT NULL DEFAULT 0,
    DeletedAt           DATETIME2(0)     NULL,
    DeletedByUserId     INT           NULL,
    CONSTRAINT PK_SalesDocumentPayment PRIMARY KEY (PaymentId)
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_SalesDocPay_DocKey')
  CREATE INDEX IX_SalesDocPay_DocKey ON ar.SalesDocumentPayment (DocumentNumber, OperationType) WHERE IsDeleted = 0;
GO

IF OBJECT_ID('ap.PurchaseDocument', 'U') IS NULL
CREATE TABLE ap.PurchaseDocument (
    DocumentId          INT IDENTITY(1,1) NOT NULL,
    DocumentNumber      NVARCHAR(60)   NOT NULL,
    SerialType          NVARCHAR(60)   NOT NULL DEFAULT '',
    FiscalMemoryNumber  NVARCHAR(80)   NULL DEFAULT '',
    OperationType       NVARCHAR(20)   NOT NULL DEFAULT 'COMPRA',
    SupplierCode        NVARCHAR(60)   NULL,
    SupplierName        NVARCHAR(255)  NULL,
    FiscalId            NVARCHAR(15)   NULL,
    DocumentDate        DATETIME2(0)     NULL DEFAULT SYSUTCDATETIME(),
    DueDate             DATETIME2(0)     NULL,
    ReceiptDate         DATETIME2(0)     NULL,
    PaymentDate         DATETIME2(0)     NULL,
    DocumentTime        NVARCHAR(20)   NULL DEFAULT CONVERT(NVARCHAR(8), SYSUTCDATETIME(), 108),
    SubTotal            DECIMAL(18,4) NULL DEFAULT 0,
    TaxableAmount       DECIMAL(18,4) NULL DEFAULT 0,
    ExemptAmount        DECIMAL(18,4) NULL DEFAULT 0,
    TaxAmount           DECIMAL(18,4) NULL DEFAULT 0,
    TaxRate             DECIMAL(8,4)  NULL DEFAULT 0,
    TotalAmount         DECIMAL(18,4) NULL DEFAULT 0,
    ExemptTotalAmount   DECIMAL(18,4) NULL DEFAULT 0,
    DiscountAmount      DECIMAL(18,4) NULL DEFAULT 0,
    IsVoided            BIT       NULL DEFAULT 0,
    IsPaid              NVARCHAR(1)    NULL DEFAULT 'N',
    IsReceived          NVARCHAR(1)    NULL DEFAULT 'N',
    IsLegal             BIT       NULL DEFAULT 0,
    OriginDocumentNumber NVARCHAR(60)  NULL,
    ControlNumber       NVARCHAR(60)   NULL,
    VoucherNumber       NVARCHAR(50)   NULL,
    VoucherDate         DATETIME2(0)     NULL,
    RetainedTax         DECIMAL(18,4) NULL DEFAULT 0,
    IsrCode             NVARCHAR(50)   NULL,
    IsrAmount           DECIMAL(18,4) NULL DEFAULT 0,
    IsrSubjectAmount    DECIMAL(18,4) NULL DEFAULT 0,
    RetentionRate       DECIMAL(8,4)  NULL DEFAULT 0,
    ImportAmount        DECIMAL(18,4) NULL DEFAULT 0,
    ImportTax           DECIMAL(18,4) NULL DEFAULT 0,
    ImportBase          DECIMAL(18,4) NULL DEFAULT 0,
    FreightAmount       DECIMAL(18,4) NULL DEFAULT 0,
    Concept             NVARCHAR(255)  NULL,
    Notes               NVARCHAR(500)  NULL,
    OrderNumber         NVARCHAR(20)   NULL,
    ReceivedBy          NVARCHAR(20)   NULL,
    WarehouseCode       NVARCHAR(50)   NULL,
    CurrencyCode        NVARCHAR(20)   NULL DEFAULT 'BS',
    ExchangeRate        DECIMAL(18,6) NULL DEFAULT 1,
    UsdAmount           DECIMAL(18,4) NULL DEFAULT 0,
    UserCode            NVARCHAR(60)   NULL DEFAULT 'API',
    ShortUserCode          NVARCHAR(40)   NULL,
    ReportDate          DATETIME2(0)     NULL DEFAULT SYSUTCDATETIME(),
    HostName            NVARCHAR(255)  NULL,
    CreatedAt           DATETIME2(0)     NOT NULL DEFAULT SYSUTCDATETIME(),
    UpdatedAt           DATETIME2(0)     NOT NULL DEFAULT SYSUTCDATETIME(),
    CreatedByUserId     INT           NULL,
    UpdatedByUserId     INT           NULL,
    IsDeleted           BIT       NOT NULL DEFAULT 0,
    DeletedAt           DATETIME2(0)     NULL,
    DeletedByUserId     INT           NULL,
    CONSTRAINT PK_PurchaseDocument PRIMARY KEY (DocumentId),
    CONSTRAINT UQ_PurchaseDocument_NumDocOp UNIQUE (DocumentNumber, OperationType)
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_PurchaseDocument_Supplier')
  CREATE INDEX IX_PurchaseDocument_Supplier ON ap.PurchaseDocument (SupplierCode);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_PurchaseDocument_OpDate')
  CREATE INDEX IX_PurchaseDocument_OpDate ON ap.PurchaseDocument (OperationType, DocumentDate) WHERE IsDeleted = 0;
GO

IF OBJECT_ID('ap.PurchaseDocumentLine', 'U') IS NULL
CREATE TABLE ap.PurchaseDocumentLine (
    LineId              INT IDENTITY(1,1) NOT NULL,
    DocumentNumber      NVARCHAR(60)   NOT NULL,
    SerialType          NVARCHAR(60)   NOT NULL DEFAULT '',
    FiscalMemoryNumber  NVARCHAR(80)   NULL DEFAULT '',
    OperationType       NVARCHAR(20)   NOT NULL DEFAULT 'COMPRA',
    LineNumber          INT           NULL DEFAULT 0,
    ProductCode         NVARCHAR(60)   NULL,
    Description         NVARCHAR(255)  NULL,
    Quantity            DECIMAL(18,4) NULL DEFAULT 0,
    UnitPrice           DECIMAL(18,4) NULL DEFAULT 0,
    UnitCost            DECIMAL(18,4) NULL DEFAULT 0,
    SubTotal            DECIMAL(18,4) NULL DEFAULT 0,
    DiscountAmount      DECIMAL(18,4) NULL DEFAULT 0,
    TotalAmount         DECIMAL(18,4) NULL DEFAULT 0,
    TaxRate             DECIMAL(8,4)  NULL DEFAULT 0,
    TaxAmount           DECIMAL(18,4) NULL DEFAULT 0,
    IsVoided            BIT       NULL DEFAULT 0,
    UserCode            NVARCHAR(60)   NULL DEFAULT 'API',
    LineDate            DATETIME2(0)     NULL DEFAULT SYSUTCDATETIME(),
    CreatedAt           DATETIME2(0)     NOT NULL DEFAULT SYSUTCDATETIME(),
    UpdatedAt           DATETIME2(0)     NOT NULL DEFAULT SYSUTCDATETIME(),
    CreatedByUserId     INT           NULL,
    UpdatedByUserId     INT           NULL,
    IsDeleted           BIT       NOT NULL DEFAULT 0,
    DeletedAt           DATETIME2(0)     NULL,
    DeletedByUserId     INT           NULL,
    CONSTRAINT PK_PurchaseDocumentLine PRIMARY KEY (LineId)
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_PurchDocLine_DocKey')
  CREATE INDEX IX_PurchDocLine_DocKey ON ap.PurchaseDocumentLine (DocumentNumber, OperationType) WHERE IsDeleted = 0;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_PurchDocLine_Product')
  CREATE INDEX IX_PurchDocLine_Product ON ap.PurchaseDocumentLine (ProductCode);
GO

IF OBJECT_ID('ap.PurchaseDocumentPayment', 'U') IS NULL
CREATE TABLE ap.PurchaseDocumentPayment (
    PaymentId           INT IDENTITY(1,1) NOT NULL,
    DocumentNumber      NVARCHAR(60)   NOT NULL,
    SerialType          NVARCHAR(60)   NOT NULL DEFAULT '',
    FiscalMemoryNumber  NVARCHAR(80)   NULL DEFAULT '',
    OperationType       NVARCHAR(20)   NOT NULL DEFAULT 'COMPRA',
    PaymentMethod       NVARCHAR(30)   NULL,
    BankCode            NVARCHAR(60)   NULL,
    PaymentNumber       NVARCHAR(60)   NULL,
    Amount              DECIMAL(18,4) NULL DEFAULT 0,
    PaymentDate         DATETIME2(0)     NULL DEFAULT SYSUTCDATETIME(),
    DueDate             DATETIME2(0)     NULL,
    ReferenceNumber     NVARCHAR(100)  NULL,
    UserCode            NVARCHAR(60)   NULL DEFAULT 'API',
    CreatedAt           DATETIME2(0)     NOT NULL DEFAULT SYSUTCDATETIME(),
    UpdatedAt           DATETIME2(0)     NOT NULL DEFAULT SYSUTCDATETIME(),
    CreatedByUserId     INT           NULL,
    UpdatedByUserId     INT           NULL,
    IsDeleted           BIT       NOT NULL DEFAULT 0,
    DeletedAt           DATETIME2(0)     NULL,
    DeletedByUserId     INT           NULL,
    CONSTRAINT PK_PurchaseDocumentPayment PRIMARY KEY (PaymentId)
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_PurchDocPay_DocKey')
  CREATE INDEX IX_PurchDocPay_DocKey ON ap.PurchaseDocumentPayment (DocumentNumber, OperationType) WHERE IsDeleted = 0;
GO

IF OBJECT_ID('acct.BankDeposit', 'U') IS NULL
CREATE TABLE acct.BankDeposit (
    BankDepositId   INT IDENTITY(1,1) PRIMARY KEY,
    Amount          DECIMAL(18,4) NOT NULL DEFAULT 0,
    CheckNumber     NVARCHAR(80)   NULL,
    BankAccount     NVARCHAR(120)  NULL,
    CustomerCode    NVARCHAR(60)   NULL,
    IsRelated       BIT       NOT NULL DEFAULT 0,
    BankName        NVARCHAR(120)  NULL,
    DocumentRef     NVARCHAR(60)   NULL,
    OperationType   NVARCHAR(20)   NULL,
    CreatedAt       DATETIME2(0)     NOT NULL DEFAULT SYSUTCDATETIME(),
    UpdatedAt       DATETIME2(0)     NOT NULL DEFAULT SYSUTCDATETIME(),
    CreatedByUserId INT           NULL,
    IsDeleted       BIT       NOT NULL DEFAULT 0
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_BankDeposit_Customer')
  CREATE INDEX IX_BankDeposit_Customer ON acct.BankDeposit (CustomerCode) WHERE IsDeleted = 0;
GO

IF OBJECT_ID('mstr.AlternateStock', 'U') IS NULL
CREATE TABLE mstr.AlternateStock (
    AlternateStockId INT IDENTITY(1,1) PRIMARY KEY,
    ProductCode      NVARCHAR(80)   NOT NULL,
    StockQty         DECIMAL(18,4) NOT NULL DEFAULT 0,
    CreatedAt        DATETIME2(0)     NOT NULL DEFAULT SYSUTCDATETIME(),
    UpdatedAt        DATETIME2(0)     NOT NULL DEFAULT SYSUTCDATETIME(),
    IsDeleted        BIT       NOT NULL DEFAULT 0,
    CONSTRAINT UQ_AlternateStock_ProductCode UNIQUE (ProductCode)
);
GO

IF OBJECT_ID('hr.MedicalExam', 'U') IS NULL
CREATE TABLE hr.MedicalExam (
  MedicalExamId  INT IDENTITY(1,1) PRIMARY KEY,
  CompanyId      INT              NOT NULL,
  EmployeeId     BIGINT           NULL,
  EmployeeCode   NVARCHAR(24)      NOT NULL,
  EmployeeName   NVARCHAR(200)     NOT NULL,
  ExamType       NVARCHAR(20)      NOT NULL,
  ExamDate       DATE             NOT NULL,
  NextDueDate    DATE             NULL,
  Result         NVARCHAR(20)      NOT NULL DEFAULT 'PENDING',
  Restrictions   NVARCHAR(500)     NULL,
  PhysicianName  NVARCHAR(200)     NULL,
  ClinicName     NVARCHAR(200)     NULL,
  DocumentUrl    NVARCHAR(500)     NULL,
  Notes          NVARCHAR(500)     NULL,
  CreatedAt      DATETIME2(0)        NOT NULL DEFAULT SYSUTCDATETIME(),
  UpdatedAt      DATETIME2(0)        NOT NULL DEFAULT SYSUTCDATETIME(),
  CONSTRAINT FK_hr_MedicalExam_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId),
  CONSTRAINT FK_hr_MedicalExam_Employee FOREIGN KEY (EmployeeId) REFERENCES mstr.Employee(EmployeeId)
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_MedExam_Company_Type')
  CREATE INDEX IX_MedExam_Company_Type ON hr.MedicalExam (CompanyId, ExamType, ExamDate DESC);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_MedExam_NextDue')
  CREATE INDEX IX_MedExam_NextDue ON hr.MedicalExam (CompanyId, NextDueDate) WHERE NextDueDate IS NOT NULL;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_MedExam_Employee')
  CREATE INDEX IX_MedExam_Employee ON hr.MedicalExam (EmployeeCode, CompanyId);
GO

IF OBJECT_ID('hr.MedicalOrder', 'U') IS NULL
CREATE TABLE hr.MedicalOrder (
  MedicalOrderId  INT IDENTITY(1,1) PRIMARY KEY,
  CompanyId       INT              NOT NULL,
  EmployeeId      BIGINT           NULL,
  EmployeeCode    NVARCHAR(24)      NOT NULL,
  EmployeeName    NVARCHAR(200)     NOT NULL,
  OrderType       NVARCHAR(20)      NOT NULL,
  OrderDate       DATE             NOT NULL,
  Diagnosis       NVARCHAR(500)     NULL,
  PhysicianName   NVARCHAR(200)     NULL,
  Prescriptions   NVARCHAR(MAX)             NULL,
  EstimatedCost   DECIMAL(18,2)    NULL,
  ApprovedAmount  DECIMAL(18,2)    NULL,
  [Status]          NVARCHAR(15)      NOT NULL DEFAULT 'PENDIENTE',
  ApprovedBy      INT              NULL,
  ApprovedAt      DATETIME2(0)        NULL,
  DocumentUrl     NVARCHAR(500)     NULL,
  Notes           NVARCHAR(500)     NULL,
  CreatedAt       DATETIME2(0)        NOT NULL DEFAULT SYSUTCDATETIME(),
  UpdatedAt       DATETIME2(0)        NOT NULL DEFAULT SYSUTCDATETIME(),
  CONSTRAINT FK_hr_MedicalOrder_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId),
  CONSTRAINT FK_hr_MedicalOrder_Employee FOREIGN KEY (EmployeeId) REFERENCES mstr.Employee(EmployeeId)
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_MedOrder_Company_Status')
  CREATE INDEX IX_MedOrder_Company_Status ON hr.MedicalOrder (CompanyId, [Status], OrderDate DESC);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_MedOrder_Employee')
  CREATE INDEX IX_MedOrder_Employee ON hr.MedicalOrder (EmployeeCode, CompanyId);
GO

IF OBJECT_ID('hr.OccupationalHealth', 'U') IS NULL
CREATE TABLE hr.OccupationalHealth (
  OccupationalHealthId       INT IDENTITY(1,1) PRIMARY KEY,
  CompanyId                  INT              NOT NULL,
  CountryCode                NCHAR(2)          NOT NULL,
  RecordType                 NVARCHAR(25)      NOT NULL,
  EmployeeId                 BIGINT           NULL,
  EmployeeCode               NVARCHAR(24)      NULL,
  EmployeeName               NVARCHAR(200)     NULL,
  OccurrenceDate             DATETIME2(0)        NOT NULL,
  ReportDeadline             DATETIME2(0)        NULL,
  ReportedDate               DATETIME2(0)        NULL,
  Severity                   NVARCHAR(15)      NULL,
  BodyPartAffected           NVARCHAR(100)     NULL,
  DaysLost                   INT              NULL,
  Location                   NVARCHAR(200)     NULL,
  Description                NVARCHAR(MAX)             NULL,
  RootCause                  NVARCHAR(500)     NULL,
  CorrectiveAction           NVARCHAR(500)     NULL,
  InvestigationDueDate       DATE             NULL,
  InvestigationCompletedDate DATE             NULL,
  InstitutionReference       NVARCHAR(100)     NULL,
  [Status]                     NVARCHAR(15)      NOT NULL DEFAULT 'OPEN',
  DocumentUrl                NVARCHAR(500)     NULL,
  Notes                      NVARCHAR(500)     NULL,
  CreatedBy                  INT              NULL,
  CreatedAt                  DATETIME2(0)        NOT NULL DEFAULT SYSUTCDATETIME(),
  UpdatedAt                  DATETIME2(0)        NOT NULL DEFAULT SYSUTCDATETIME(),
  CONSTRAINT FK_hr_OccHealth_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId),
  CONSTRAINT FK_hr_OccHealth_Employee FOREIGN KEY (EmployeeId) REFERENCES mstr.Employee(EmployeeId)
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_OccHealth_Company_Status')
  CREATE INDEX IX_OccHealth_Company_Status ON hr.OccupationalHealth (CompanyId, [Status]);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_OccHealth_Company_RecordType')
  CREATE INDEX IX_OccHealth_Company_RecordType ON hr.OccupationalHealth (CompanyId, RecordType, OccurrenceDate DESC);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_OccHealth_Employee')
  CREATE INDEX IX_OccHealth_Employee ON hr.OccupationalHealth (EmployeeId) WHERE EmployeeId IS NOT NULL;
GO

IF OBJECT_ID('hr.ProfitSharing', 'U') IS NULL
CREATE TABLE hr.ProfitSharing (
  ProfitSharingId      INT IDENTITY(1,1) PRIMARY KEY,
  CompanyId            INT              NOT NULL,
  BranchId             INT              NOT NULL,
  FiscalYear           INT              NOT NULL,
  DaysGranted          INT              NOT NULL,
  TotalCompanyProfits  DECIMAL(18,2)    NULL,
  [Status]               NVARCHAR(20)      NOT NULL DEFAULT 'BORRADOR',
  CreatedBy            INT              NULL,
  CreatedAt            DATETIME2(0)        NOT NULL DEFAULT SYSUTCDATETIME(),
  ApprovedBy           INT              NULL,
  ApprovedAt           DATETIME2(0)        NULL,
  UpdatedAt            DATETIME2(0)        NOT NULL DEFAULT SYSUTCDATETIME(),
  CONSTRAINT CK_ProfitSharing_Days   CHECK (DaysGranted >= 30 AND DaysGranted <= 120),
  CONSTRAINT CK_ProfitSharing_Status CHECK ([Status] IN ('CERRADA','PROCESADA','CALCULADA','BORRADOR')),
  CONSTRAINT FK_hr_ProfitSharing_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId),
  CONSTRAINT FK_hr_ProfitSharing_Branch  FOREIGN KEY (BranchId)  REFERENCES cfg.Branch(BranchId)
);
GO

IF OBJECT_ID('hr.ProfitSharingLine', 'U') IS NULL
CREATE TABLE hr.ProfitSharingLine (
  LineId           INT IDENTITY(1,1) PRIMARY KEY,
  ProfitSharingId  INT              NOT NULL,
  EmployeeId       BIGINT           NULL,
  EmployeeCode     NVARCHAR(24)      NOT NULL,
  EmployeeName     NVARCHAR(200)     NOT NULL,
  MonthlySalary    DECIMAL(18,2)    NOT NULL,
  DailySalary      DECIMAL(18,2)    NOT NULL,
  DaysWorked       INT              NOT NULL,
  DaysEntitled     INT              NOT NULL,
  GrossAmount      DECIMAL(18,2)    NOT NULL,
  InceDeduction    DECIMAL(18,2)    NOT NULL DEFAULT 0,
  NetAmount        DECIMAL(18,2)    NOT NULL,
  IsPaid           BIT          NOT NULL DEFAULT 0,
  PaidAt           DATETIME2(0)        NULL,
  CONSTRAINT FK_ProfitSharingLine_Header   FOREIGN KEY (ProfitSharingId) REFERENCES hr.ProfitSharing(ProfitSharingId),
  CONSTRAINT FK_ProfitSharingLine_Employee FOREIGN KEY (EmployeeId) REFERENCES mstr.Employee(EmployeeId)
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_ProfitSharingLine_Header')
  CREATE INDEX IX_ProfitSharingLine_Header ON hr.ProfitSharingLine (ProfitSharingId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_ProfitSharingLine_Employee')
  CREATE INDEX IX_ProfitSharingLine_Employee ON hr.ProfitSharingLine (EmployeeCode);
GO

IF OBJECT_ID('hr.SafetyCommittee', 'U') IS NULL
CREATE TABLE hr.SafetyCommittee (
  SafetyCommitteeId  INT IDENTITY(1,1) PRIMARY KEY,
  CompanyId          INT              NOT NULL,
  CountryCode        NCHAR(2)          NOT NULL,
  CommitteeName      NVARCHAR(200)     NOT NULL,
  FormationDate      DATE             NOT NULL,
  MeetingFrequency   NVARCHAR(15)      NOT NULL DEFAULT 'MONTHLY',
  IsActive           BIT          NOT NULL DEFAULT 1,
  CreatedAt          DATETIME2(0)        NOT NULL DEFAULT SYSUTCDATETIME(),
  CONSTRAINT FK_hr_SafetyCommittee_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId)
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Committee_Company')
  CREATE INDEX IX_Committee_Company ON hr.SafetyCommittee (CompanyId, IsActive);
GO

IF OBJECT_ID('hr.SafetyCommitteeMeeting', 'U') IS NULL
CREATE TABLE hr.SafetyCommitteeMeeting (
  MeetingId          INT IDENTITY(1,1) PRIMARY KEY,
  SafetyCommitteeId  INT              NOT NULL,
  MeetingDate        DATETIME2(0)        NOT NULL,
  MinutesUrl         NVARCHAR(500)     NULL,
  TopicsSummary      NVARCHAR(MAX)             NULL,
  ActionItems        NVARCHAR(MAX)             NULL,
  CreatedAt          DATETIME2(0)        NOT NULL DEFAULT SYSUTCDATETIME(),
  CONSTRAINT FK_CommitteeMeeting_Committee FOREIGN KEY (SafetyCommitteeId) REFERENCES hr.SafetyCommittee(SafetyCommitteeId)
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_CommitteeMeeting_Committee')
  CREATE INDEX IX_CommitteeMeeting_Committee ON hr.SafetyCommitteeMeeting (SafetyCommitteeId, MeetingDate DESC);
GO

IF OBJECT_ID('hr.SafetyCommitteeMember', 'U') IS NULL
CREATE TABLE hr.SafetyCommitteeMember (
  MemberId           INT IDENTITY(1,1) PRIMARY KEY,
  SafetyCommitteeId  INT              NOT NULL,
  EmployeeId         BIGINT           NULL,
  EmployeeCode       NVARCHAR(24)      NOT NULL,
  EmployeeName       NVARCHAR(200)     NOT NULL,
  [Role]               NVARCHAR(25)      NOT NULL,
  StartDate          DATE             NOT NULL,
  EndDate            DATE             NULL,
  CONSTRAINT FK_CommitteeMember_Committee FOREIGN KEY (SafetyCommitteeId) REFERENCES hr.SafetyCommittee(SafetyCommitteeId),
  CONSTRAINT FK_CommitteeMember_Employee  FOREIGN KEY (EmployeeId) REFERENCES mstr.Employee(EmployeeId)
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_CommitteeMember_Committee')
  CREATE INDEX IX_CommitteeMember_Committee ON hr.SafetyCommitteeMember (SafetyCommitteeId);
GO

IF OBJECT_ID('hr.SavingsFund', 'U') IS NULL
CREATE TABLE hr.SavingsFund (
  SavingsFundId          INT IDENTITY(1,1) PRIMARY KEY,
  CompanyId              INT              NOT NULL,
  EmployeeId             BIGINT           NULL,
  EmployeeCode           NVARCHAR(24)      NOT NULL,
  EmployeeName           NVARCHAR(200)     NOT NULL,
  EmployeeContribution   DECIMAL(8,4)     NOT NULL,
  EmployerMatch          DECIMAL(8,4)     NOT NULL,
  EnrollmentDate         DATE             NOT NULL,
  [Status]                 NVARCHAR(15)      NOT NULL DEFAULT 'ACTIVO',
  CreatedAt              DATETIME2(0)        NOT NULL DEFAULT SYSUTCDATETIME(),
  CONSTRAINT CK_SavingsFund_Status CHECK ([Status] IN ('ACTIVO','SUSPENDIDO','RETIRADO')),
  CONSTRAINT UX_SavingsFund_Employee UNIQUE (CompanyId, EmployeeCode),
  CONSTRAINT FK_hr_SavingsFund_Company  FOREIGN KEY (CompanyId)  REFERENCES cfg.Company(CompanyId),
  CONSTRAINT FK_hr_SavingsFund_Employee FOREIGN KEY (EmployeeId) REFERENCES mstr.Employee(EmployeeId)
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_SavingsFund_Status')
  CREATE INDEX IX_SavingsFund_Status ON hr.SavingsFund (CompanyId, [Status]);
GO

IF OBJECT_ID('hr.SavingsFundTransaction', 'U') IS NULL
CREATE TABLE hr.SavingsFundTransaction (
  TransactionId    INT IDENTITY(1,1) PRIMARY KEY,
  SavingsFundId    INT              NOT NULL,
  TransactionDate  DATE             NOT NULL,
  TransactionType  NVARCHAR(20)      NOT NULL,
  Amount           DECIMAL(18,2)    NOT NULL,
  Balance          DECIMAL(18,2)    NOT NULL,
  Reference        NVARCHAR(100)     NULL,
  PayrollBatchId   INT              NULL,
  Notes            NVARCHAR(500)     NULL,
  CreatedAt        DATETIME2(0)        NOT NULL DEFAULT SYSUTCDATETIME(),
  CONSTRAINT CK_SavingsTx_Type CHECK (TransactionType IN (
    'APORTE_EMPLEADO','APORTE_PATRONAL','RETIRO','PRESTAMO','PAGO_PRESTAMO','INTERES'
  )),
  CONSTRAINT FK_SavingsTx_Fund FOREIGN KEY (SavingsFundId) REFERENCES hr.SavingsFund(SavingsFundId)
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_SavingsTx_Fund')
  CREATE INDEX IX_SavingsTx_Fund ON hr.SavingsFundTransaction (SavingsFundId, TransactionDate);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_SavingsTx_Type')
  CREATE INDEX IX_SavingsTx_Type ON hr.SavingsFundTransaction (TransactionType);
GO

IF OBJECT_ID('hr.SavingsLoan', 'U') IS NULL
CREATE TABLE hr.SavingsLoan (
  LoanId              INT IDENTITY(1,1) PRIMARY KEY,
  SavingsFundId       INT              NOT NULL,
  EmployeeCode        NVARCHAR(24)      NOT NULL,
  RequestDate         DATE             NOT NULL,
  ApprovedDate        DATE             NULL,
  LoanAmount          DECIMAL(18,2)    NOT NULL,
  InterestRate        DECIMAL(8,5)     NOT NULL DEFAULT 0,
  TotalPayable        DECIMAL(18,2)    NOT NULL,
  MonthlyPayment      DECIMAL(18,2)    NOT NULL,
  InstallmentsTotal   INT              NOT NULL,
  InstallmentsPaid    INT              NOT NULL DEFAULT 0,
  OutstandingBalance  DECIMAL(18,2)    NOT NULL,
  [Status]              NVARCHAR(15)      NOT NULL DEFAULT 'SOLICITADO',
  ApprovedBy          INT              NULL,
  Notes               NVARCHAR(500)     NULL,
  CreatedAt           DATETIME2(0)        NOT NULL DEFAULT SYSUTCDATETIME(),
  UpdatedAt           DATETIME2(0)        NOT NULL DEFAULT SYSUTCDATETIME(),
  CONSTRAINT CK_SavingsLoan_Status CHECK ([Status] IN ('SOLICITADO','APROBADO','ACTIVO','PAGADO','RECHAZADO')),
  CONSTRAINT FK_SavingsLoan_Fund FOREIGN KEY (SavingsFundId) REFERENCES hr.SavingsFund(SavingsFundId)
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_SavingsLoan_Fund')
  CREATE INDEX IX_SavingsLoan_Fund ON hr.SavingsLoan (SavingsFundId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_SavingsLoan_Employee')
  CREATE INDEX IX_SavingsLoan_Employee ON hr.SavingsLoan (EmployeeCode);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_SavingsLoan_Status')
  CREATE INDEX IX_SavingsLoan_Status ON hr.SavingsLoan ([Status]);
GO

IF OBJECT_ID('hr.SocialBenefitsTrust', 'U') IS NULL
CREATE TABLE hr.SocialBenefitsTrust (
  TrustId             INT IDENTITY(1,1) PRIMARY KEY,
  CompanyId           INT              NOT NULL,
  EmployeeId          BIGINT           NULL,
  EmployeeCode        NVARCHAR(24)      NOT NULL,
  EmployeeName        NVARCHAR(200)     NOT NULL,
  FiscalYear          INT              NOT NULL,
  Quarter             SMALLINT         NOT NULL,
  DailySalary         DECIMAL(18,2)    NOT NULL,
  DaysDeposited       INT              NOT NULL DEFAULT 15,
  BonusDays           INT              NOT NULL DEFAULT 0,
  DepositAmount       DECIMAL(18,2)    NOT NULL,
  InterestRate        DECIMAL(8,5)     NOT NULL DEFAULT 0,
  InterestAmount      DECIMAL(18,2)    NOT NULL DEFAULT 0,
  AccumulatedBalance  DECIMAL(18,2)    NOT NULL,
  [Status]              NVARCHAR(20)      NOT NULL DEFAULT 'PENDIENTE',
  CreatedAt           DATETIME2(0)        NOT NULL DEFAULT SYSUTCDATETIME(),
  UpdatedAt           DATETIME2(0)        NOT NULL DEFAULT SYSUTCDATETIME(),
  CONSTRAINT CK_Trust_Quarter CHECK (Quarter >= 1 AND Quarter <= 4),
  CONSTRAINT CK_Trust_Status  CHECK ([Status] IN ('PENDIENTE','DEPOSITADO','PAGADO')),
  CONSTRAINT UX_Trust_Employee_Quarter UNIQUE (CompanyId, EmployeeCode, FiscalYear, Quarter),
  CONSTRAINT FK_hr_Trust_Company  FOREIGN KEY (CompanyId)  REFERENCES cfg.Company(CompanyId),
  CONSTRAINT FK_hr_Trust_Employee FOREIGN KEY (EmployeeId) REFERENCES mstr.Employee(EmployeeId)
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Trust_Company_Year')
  CREATE INDEX IX_Trust_Company_Year ON hr.SocialBenefitsTrust (CompanyId, FiscalYear, Quarter);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Trust_Employee')
  CREATE INDEX IX_Trust_Employee ON hr.SocialBenefitsTrust (EmployeeCode, FiscalYear);
GO

IF OBJECT_ID('hr.TrainingRecord', 'U') IS NULL
CREATE TABLE hr.TrainingRecord (
  TrainingRecordId   INT IDENTITY(1,1) PRIMARY KEY,
  CompanyId          INT              NOT NULL,
  CountryCode        NCHAR(2)          NOT NULL,
  TrainingType       NVARCHAR(25)      NOT NULL,
  Title              NVARCHAR(200)     NOT NULL,
  Provider           NVARCHAR(200)     NULL,
  StartDate          DATE             NOT NULL,
  EndDate            DATE             NULL,
  DurationHours      DECIMAL(6,2)     NOT NULL,
  EmployeeId         BIGINT           NULL,
  EmployeeCode       NVARCHAR(24)      NOT NULL,
  EmployeeName       NVARCHAR(200)     NOT NULL,
  CertificateNumber  NVARCHAR(100)     NULL,
  CertificateUrl     NVARCHAR(500)     NULL,
  Result             NVARCHAR(15)      NULL,
  IsRegulatory       BIT          NOT NULL DEFAULT 0,
  Notes              NVARCHAR(500)     NULL,
  CreatedAt          DATETIME2(0)        NOT NULL DEFAULT SYSUTCDATETIME(),
  UpdatedAt          DATETIME2(0)        NOT NULL DEFAULT SYSUTCDATETIME(),
  CONSTRAINT FK_hr_TrainingRecord_Company  FOREIGN KEY (CompanyId)  REFERENCES cfg.Company(CompanyId),
  CONSTRAINT FK_hr_TrainingRecord_Employee FOREIGN KEY (EmployeeId) REFERENCES mstr.Employee(EmployeeId)
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Training_Company_Type')
  CREATE INDEX IX_Training_Company_Type ON hr.TrainingRecord (CompanyId, TrainingType, StartDate DESC);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Training_Employee')
  CREATE INDEX IX_Training_Employee ON hr.TrainingRecord (EmployeeCode, CompanyId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Training_Regulatory')
  CREATE INDEX IX_Training_Regulatory ON hr.TrainingRecord (CompanyId, IsRegulatory) WHERE IsRegulatory = 1;
GO

IF OBJECT_ID('cfg.TaxUnit', 'U') IS NULL
CREATE TABLE cfg.TaxUnit (
    TaxUnitId     INT IDENTITY(1,1) PRIMARY KEY,
    CountryCode   NCHAR(2)        NOT NULL,
    TaxYear       INT            NOT NULL,
    UnitValue     DECIMAL(18,4)  NOT NULL,
    Currency      NCHAR(3)        NOT NULL DEFAULT 'VES',
    EffectiveDate DATE           NOT NULL,
    IsActive      BIT        NOT NULL DEFAULT 1,
    CreatedAt     DATETIME2(0)      NOT NULL DEFAULT SYSUTCDATETIME(),
    UpdatedAt     DATETIME2(0)      NOT NULL DEFAULT SYSUTCDATETIME(),
    CONSTRAINT UQ_cfg_TaxUnit UNIQUE (CountryCode, TaxYear, EffectiveDate)
);
GO

IF OBJECT_ID('fiscal.WithholdingConcept', 'U') IS NULL
CREATE TABLE fiscal.WithholdingConcept (
    ConceptId       INT IDENTITY(1,1) PRIMARY KEY,
    CompanyId       INT            NOT NULL DEFAULT 1,
    CountryCode     NCHAR(2)        NOT NULL,
    ConceptCode     NVARCHAR(20)    NOT NULL,
    Description     NVARCHAR(200)   NOT NULL,
    SupplierType    NVARCHAR(20)    NOT NULL DEFAULT 'AMBOS',
    ActivityCode    NVARCHAR(30)    NULL,
    RetentionType   NVARCHAR(20)    NOT NULL DEFAULT 'ISLR',
    Rate            DECIMAL(8,4)   NOT NULL,
    SubtrahendUT    DECIMAL(8,4)   NOT NULL DEFAULT 0,
    MinBaseUT       DECIMAL(8,4)   NOT NULL DEFAULT 0,
    SeniatCode      NVARCHAR(10)    NULL,
    IsActive        BIT        NOT NULL DEFAULT 1,
    IsDeleted       BIT        NOT NULL DEFAULT 0,
    CreatedAt       DATETIME2(0)      NOT NULL DEFAULT SYSUTCDATETIME(),
    UpdatedAt       DATETIME2(0)      NOT NULL DEFAULT SYSUTCDATETIME(),
    CONSTRAINT UQ_fiscal_WHConcept UNIQUE (CompanyId, CountryCode, ConceptCode),
    CONSTRAINT CK_fiscal_WHConcept_Type CHECK (SupplierType IN ('NATURAL','JURIDICA','AMBOS')),
    CONSTRAINT CK_fiscal_WHConcept_RetType CHECK (RetentionType IN ('ISLR','IVA','IRPF','ISR','RETEFUENTE','MUNICIPAL'))
);
GO

IF OBJECT_ID('hr.EmployeeTaxProfile', 'U') IS NULL
CREATE TABLE hr.EmployeeTaxProfile (
    ProfileId                INT IDENTITY(1,1) PRIMARY KEY,
    EmployeeId               BIGINT         NOT NULL,
    TaxYear                  INT            NOT NULL,
    EstimatedAnnualIncome    DECIMAL(18,2)  NOT NULL DEFAULT 0,
    DeductionType            NVARCHAR(20)    NOT NULL DEFAULT 'UNICO',
    UniqueDeductionUT        DECIMAL(8,2)   NOT NULL DEFAULT 774,
    DetailedDeductions       DECIMAL(18,2)  NOT NULL DEFAULT 0,
    DependentCount           INT            NOT NULL DEFAULT 0,
    PersonalRebateUT         DECIMAL(8,2)   NOT NULL DEFAULT 10,
    DependentRebateUT        DECIMAL(8,2)   NOT NULL DEFAULT 10,
    MonthsRemaining          INT            NOT NULL DEFAULT 12,
    CalculatedAnnualISLR     DECIMAL(18,2)  NOT NULL DEFAULT 0,
    MonthlyWithholding       DECIMAL(18,2)  NOT NULL DEFAULT 0,
    CountryCode              NCHAR(2)        NOT NULL DEFAULT 'VE',
    [Status]                   NVARCHAR(20)    NOT NULL DEFAULT 'ACTIVE',
    CreatedAt                DATETIME2(0)      NOT NULL DEFAULT SYSUTCDATETIME(),
    UpdatedAt                DATETIME2(0)      NOT NULL DEFAULT SYSUTCDATETIME(),
    CONSTRAINT UQ_hr_EmpTaxProfile UNIQUE (EmployeeId, TaxYear),
    CONSTRAINT CK_hr_EmpTaxProfile_Ded CHECK (DeductionType IN ('UNICO','DETALLADO')),
    CONSTRAINT CK_hr_EmpTaxProfile_Status CHECK ([Status] IN ('ACTIVE','INACTIVE'))
);
GO

IF OBJECT_ID('hr.VacationRequest', 'U') IS NULL
CREATE TABLE hr.VacationRequest (
    RequestId       BIGINT IDENTITY(1,1) PRIMARY KEY,
    CompanyId       INT NOT NULL DEFAULT 1,
    BranchId        INT NOT NULL DEFAULT 1,
    EmployeeCode    NVARCHAR(60) NOT NULL,
    RequestDate     DATE NOT NULL DEFAULT SYSUTCDATETIME(),
    StartDate       DATE NOT NULL,
    EndDate         DATE NOT NULL,
    TotalDays       INT NOT NULL,
    IsPartial       BIT NOT NULL DEFAULT 0,
    [Status]          NVARCHAR(20) NOT NULL DEFAULT 'PENDIENTE',
    Notes           NVARCHAR(500),
    ApprovedBy      NVARCHAR(60),
    ApprovalDate    DATETIME2(0),
    RejectionReason NVARCHAR(500),
    VacationId      BIGINT,
    CreatedAt       DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
    UpdatedAt       DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),

    CONSTRAINT CK_VacationRequest_Status CHECK ([Status] IN ('PENDIENTE','APROBADA','RECHAZADA','CANCELADA','PROCESADA')),
    CONSTRAINT CK_VacationRequest_Dates  CHECK (EndDate >= StartDate),
    CONSTRAINT CK_VacationRequest_Days   CHECK (TotalDays > 0)
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_VacationRequest_Employee')
  CREATE INDEX IX_VacationRequest_Employee ON hr.VacationRequest (CompanyId, EmployeeCode, [Status]);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_VacationRequest_Status')
  CREATE INDEX IX_VacationRequest_Status ON hr.VacationRequest ([Status], RequestDate);
GO

IF OBJECT_ID('hr.VacationRequestDay', 'U') IS NULL
CREATE TABLE hr.VacationRequestDay (
    DayId        BIGINT IDENTITY(1,1) PRIMARY KEY,
    RequestId    BIGINT NOT NULL REFERENCES hr.VacationRequest(RequestId),
    SelectedDate DATE NOT NULL,
    DayType      NVARCHAR(20) NOT NULL DEFAULT 'COMPLETO',

    CONSTRAINT CK_VacationRequestDay_Type CHECK (DayType IN ('COMPLETO','MEDIO_DIA'))
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_VacationRequestDay_Request')
  CREATE INDEX IX_VacationRequestDay_Request ON hr.VacationRequestDay (RequestId);
GO

IF OBJECT_ID('sec.SupervisorBiometricCredential', 'U') IS NULL
CREATE TABLE sec.SupervisorBiometricCredential (
  BiometricCredentialId  BIGINT IDENTITY(1,1) PRIMARY KEY,
  SupervisorUserCode          NVARCHAR(40) NOT NULL,
  CredentialHash         NCHAR(64) NOT NULL,
  CredentialId           NVARCHAR(512) NOT NULL,
  CredentialLabel        NVARCHAR(120) NULL,
  DeviceInfo             NVARCHAR(300) NULL,
  IsActive               BIT NOT NULL DEFAULT 1,
  LastValidatedAtUtc     DATETIME2(0)(3) NULL,
  CreatedAtUtc           DATETIME2(0)(3) NOT NULL DEFAULT SYSUTCDATETIME(),
  UpdatedAtUtc           DATETIME2(0)(3) NOT NULL DEFAULT SYSUTCDATETIME(),
  CreatedByUserCode          NVARCHAR(40) NULL,
  UpdatedByUserCode          NVARCHAR(40) NULL,

  CONSTRAINT FK_SupervisorBiometricCredential_SupervisorUser
    FOREIGN KEY (SupervisorUserCode) REFERENCES sec.[User](UserCode)
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UX_SupervisorBiometricCredential_UserHash')
  CREATE UNIQUE INDEX UX_SupervisorBiometricCredential_UserHash ON sec.SupervisorBiometricCredential (SupervisorUserCode, CredentialHash);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_SupervisorBiometricCredential_Active')
  CREATE INDEX IX_SupervisorBiometricCredential_Active ON sec.SupervisorBiometricCredential (SupervisorUserCode, IsActive, LastValidatedAtUtc DESC);
GO

IF OBJECT_ID('sec.SupervisorOverride', 'U') IS NULL
CREATE TABLE sec.SupervisorOverride (
  OverrideId            BIGINT IDENTITY(1,1) PRIMARY KEY,
  ModuleCode            NVARCHAR(32) NOT NULL,
  ActionCode            NVARCHAR(64) NOT NULL,
  [Status]                NVARCHAR(20) NOT NULL DEFAULT 'APPROVED',
  CompanyId             INT NULL,
  BranchId              INT NULL,
  RequestedByUserCode   NVARCHAR(50) NULL,
  SupervisorUserCode    NVARCHAR(50) NOT NULL,
  Reason                NVARCHAR(300) NOT NULL,
  PayloadJson           NVARCHAR(MAX) NULL,
  SourceDocumentId      BIGINT NULL,
  SourceLineId          BIGINT NULL,
  ReversalLineId        BIGINT NULL,
  ApprovedAtUtc         DATETIME2(0)(3) NOT NULL DEFAULT SYSUTCDATETIME(),
  ConsumedAtUtc         DATETIME2(0)(3) NULL,
  ConsumedByUserCode    NVARCHAR(50) NULL,
  CreatedAt             DATETIME2(0)(3) NOT NULL DEFAULT SYSUTCDATETIME(),
  UpdatedAt             DATETIME2(0)(3) NOT NULL DEFAULT SYSUTCDATETIME()
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_SupervisorOverride_Status')
  CREATE INDEX IX_SupervisorOverride_Status ON sec.SupervisorOverride([Status], ModuleCode, ActionCode, ApprovedAtUtc DESC);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_SupervisorOverride_Source')
  CREATE INDEX IX_SupervisorOverride_Source ON sec.SupervisorOverride(ModuleCode, ActionCode, SourceDocumentId, SourceLineId);
GO

IF OBJECT_ID('zsys.TenantDatabase', 'U') IS NULL
CREATE TABLE zsys.TenantDatabase (
  TenantDbId    INT IDENTITY(1,1) PRIMARY KEY,
  CompanyId     INT NOT NULL,
  CompanyCode   NVARCHAR(20) NOT NULL,
  DbName        NVARCHAR(63) NOT NULL,
  DbHost        NVARCHAR(255) DEFAULT NULL,
  DbPort        INT DEFAULT NULL,
  DbUser        NVARCHAR(63) DEFAULT NULL,
  DbPassword    NVARCHAR(255) DEFAULT NULL,
  PoolMin       INT NOT NULL DEFAULT 0,
  PoolMax       INT NOT NULL DEFAULT 5,
  IsActive      BIT NOT NULL DEFAULT 1,
  IsDemo        BIT NOT NULL DEFAULT 0,
  ProvisionedAt DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
  LastMigration NVARCHAR(100) NULL,
  CreatedAt     DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
  CONSTRAINT UQ_sys_TenantDatabase_CompanyId UNIQUE (CompanyId),
  CONSTRAINT UQ_sys_TenantDatabase_DbName UNIQUE (DbName)
);
GO

IF OBJECT_ID('zsys.License', 'U') IS NULL
CREATE TABLE zsys.License (
  LicenseId         BIGINT IDENTITY(1,1) PRIMARY KEY,
  CompanyId         BIGINT NOT NULL,
  LicenseType       NVARCHAR(20) NOT NULL DEFAULT 'SUBSCRIPTION',
  [Plan]              NVARCHAR(30) NOT NULL DEFAULT 'STARTER',
  LicenseKey        NVARCHAR(64) NOT NULL UNIQUE,
  [Status]            NVARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
  StartsAt          DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
  ExpiresAt         DATETIME2(0),
  PaddleSubId       NVARCHAR(100),
  ContractRef       NVARCHAR(100),
  MaxUsers          INT,
  MaxBranches       INT,
  Notes             NVARCHAR(MAX),
  ConvertedFromTrial BIT DEFAULT 0,
  CreatedAt         DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
  UpdatedAt         DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME()
);
GO

IF OBJECT_ID('zsys.TenantResourceLog', 'U') IS NULL
CREATE TABLE zsys.TenantResourceLog (
  LogId       BIGINT IDENTITY(1,1) PRIMARY KEY,
  CompanyId   BIGINT NOT NULL,
  DbName      NVARCHAR(100),
  DbSizeBytes BIGINT,
  DbSizeMB    DECIMAL(10,2),
  TableCount  INT,
  LastLoginAt DATETIME2(0),
  UserCount   INT,
  RecordedAt  DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME()
);
GO

IF OBJECT_ID('zsys.CleanupQueue', 'U') IS NULL
CREATE TABLE zsys.CleanupQueue (
  QueueId       BIGINT IDENTITY(1,1) PRIMARY KEY,
  CompanyId     BIGINT NOT NULL UNIQUE,
  Reason        NVARCHAR(50) NOT NULL,
  FlaggedAt     DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
  FlaggedBy     NVARCHAR(100) DEFAULT 'auto',
  [Status]        NVARCHAR(20) NOT NULL DEFAULT 'PENDING',
  NotifiedAt    DATETIME2(0),
  ArchivedAt    DATETIME2(0),
  DeletedAt     DATETIME2(0),
  Notes         NVARCHAR(MAX)
);
GO

IF OBJECT_ID('zsys.TenantBackup', 'U') IS NULL
CREATE TABLE zsys.TenantBackup (
  BackupId      BIGINT IDENTITY(1,1) PRIMARY KEY,
  CompanyId     BIGINT NOT NULL,
  DbName        NVARCHAR(100) NOT NULL,
  FilePath      NVARCHAR(500),
  FileName      NVARCHAR(200),
  FileSizeBytes BIGINT,
  FileSizeMB    DECIMAL(10,2),
  [Status]        NVARCHAR(20) NOT NULL DEFAULT 'PENDING',
  StartedAt     DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
  CompletedAt   DATETIME2(0),
  ErrorMessage  NVARCHAR(MAX),
  CreatedBy     NVARCHAR(100) DEFAULT 'backoffice',
  Notes         NVARCHAR(MAX),
  StorageKey    NVARCHAR(500),
  StorageUrl    NVARCHAR(1000),
  StorageStatus NVARCHAR(20) DEFAULT 'LOCAL_ONLY'
);
GO

IF COL_LENGTH('cfg.Company', 'LicenseKey') IS NULL
  ALTER TABLE cfg.Company ADD LicenseKey NVARCHAR(64);
GO

IF COL_LENGTH('cfg.Company', 'Plan') IS NULL
  ALTER TABLE cfg.Company ADD [Plan] NVARCHAR(30);
GO

IF COL_LENGTH('cfg.Company', 'TenantStatus') IS NULL
  ALTER TABLE cfg.Company ADD TenantStatus NVARCHAR(20);
GO

IF COL_LENGTH('cfg.Company', 'OwnerEmail') IS NULL
  ALTER TABLE cfg.Company ADD OwnerEmail NVARCHAR(255);
GO

IF COL_LENGTH('cfg.Company', 'TenantSubdomain') IS NULL
  ALTER TABLE cfg.Company ADD TenantSubdomain NVARCHAR(100);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_cfg_Company_OwnerEmail')
  CREATE INDEX IX_cfg_Company_OwnerEmail ON cfg.Company(OwnerEmail) WHERE OwnerEmail IS NOT NULL;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_cfg_Company_TenantStatus')
  CREATE INDEX IX_cfg_Company_TenantStatus ON cfg.Company(TenantStatus);
GO

-- Total: 169 tables, 159 indexes
PRINT 'DDL completado: 169 tablas, 159 indices';
GO