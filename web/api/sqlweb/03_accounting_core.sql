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

  IF OBJECT_ID('acct.Account', 'U') IS NULL
  BEGIN
    CREATE TABLE acct.Account(
      AccountId             BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      CompanyId             INT NOT NULL,
      AccountCode           NVARCHAR(40) NOT NULL,
      AccountName           NVARCHAR(200) NOT NULL,
      AccountType           NCHAR(1) NOT NULL, -- A,P,C,I,G
      AccountLevel          INT NOT NULL CONSTRAINT DF_acct_Account_Level DEFAULT(1),
      ParentAccountId       BIGINT NULL,
      AllowsPosting         BIT NOT NULL CONSTRAINT DF_acct_Account_AllowsPosting DEFAULT(1),
      RequiresAuxiliary     BIT NOT NULL CONSTRAINT DF_acct_Account_RequiresAux DEFAULT(0),
      IsActive              BIT NOT NULL CONSTRAINT DF_acct_Account_IsActive DEFAULT(1),
      CreatedAt             DATETIME2(0) NOT NULL CONSTRAINT DF_acct_Account_CreatedAt DEFAULT(SYSUTCDATETIME()),
      UpdatedAt             DATETIME2(0) NOT NULL CONSTRAINT DF_acct_Account_UpdatedAt DEFAULT(SYSUTCDATETIME()),
      CreatedByUserId       INT NULL,
      UpdatedByUserId       INT NULL,
      IsDeleted             BIT NOT NULL CONSTRAINT DF_acct_Account_IsDeleted DEFAULT(0),
      DeletedAt             DATETIME2(0) NULL,
      DeletedByUserId       INT NULL,
      RowVer                ROWVERSION NOT NULL,
      CONSTRAINT CK_acct_Account_AccountType CHECK (AccountType IN (N'A', N'P', N'C', N'I', N'G')),
      CONSTRAINT UQ_acct_Account UNIQUE (CompanyId, AccountCode),
      CONSTRAINT FK_acct_Account_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId),
      CONSTRAINT FK_acct_Account_Parent FOREIGN KEY (ParentAccountId) REFERENCES acct.Account(AccountId),
      CONSTRAINT FK_acct_Account_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
      CONSTRAINT FK_acct_Account_UpdatedBy FOREIGN KEY (UpdatedByUserId) REFERENCES sec.[User](UserId)
    );

    CREATE INDEX IX_acct_Account_Company_Parent
      ON acct.Account (CompanyId, ParentAccountId, AccountCode);
  END;

  IF OBJECT_ID('acct.JournalEntry', 'U') IS NULL
  BEGIN
    CREATE TABLE acct.JournalEntry(
      JournalEntryId        BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      CompanyId             INT NOT NULL,
      BranchId              INT NOT NULL,
      EntryNumber           NVARCHAR(40) NOT NULL,
      EntryDate             DATE NOT NULL,
      PeriodCode            NVARCHAR(7) NOT NULL,
      EntryType             NVARCHAR(20) NOT NULL,
      ReferenceNumber       NVARCHAR(120) NULL,
      Concept               NVARCHAR(400) NOT NULL,
      CurrencyCode          CHAR(3) NOT NULL,
      ExchangeRate          DECIMAL(18,6) NOT NULL CONSTRAINT DF_acct_JE_ExRate DEFAULT(1),
      TotalDebit            DECIMAL(18,2) NOT NULL CONSTRAINT DF_acct_JE_Debit DEFAULT(0),
      TotalCredit           DECIMAL(18,2) NOT NULL CONSTRAINT DF_acct_JE_Credit DEFAULT(0),
      Status                NVARCHAR(20) NOT NULL CONSTRAINT DF_acct_JE_Status DEFAULT('APPROVED'),
      SourceModule          NVARCHAR(40) NULL,
      SourceDocumentType    NVARCHAR(40) NULL,
      SourceDocumentNo      NVARCHAR(120) NULL,
      CreatedAt             DATETIME2(0) NOT NULL CONSTRAINT DF_acct_JE_CreatedAt DEFAULT(SYSUTCDATETIME()),
      UpdatedAt             DATETIME2(0) NOT NULL CONSTRAINT DF_acct_JE_UpdatedAt DEFAULT(SYSUTCDATETIME()),
      CreatedByUserId       INT NULL,
      UpdatedByUserId       INT NULL,
      IsDeleted             BIT NOT NULL CONSTRAINT DF_acct_JE_IsDeleted DEFAULT(0),
      DeletedAt             DATETIME2(0) NULL,
      DeletedByUserId       INT NULL,
      RowVer                ROWVERSION NOT NULL,
      CONSTRAINT CK_acct_JE_Status CHECK (Status IN ('DRAFT','APPROVED','VOIDED')),
      CONSTRAINT UQ_acct_JE UNIQUE (CompanyId, BranchId, EntryNumber),
      CONSTRAINT FK_acct_JE_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId),
      CONSTRAINT FK_acct_JE_Branch FOREIGN KEY (BranchId) REFERENCES cfg.Branch(BranchId),
      CONSTRAINT FK_acct_JE_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
      CONSTRAINT FK_acct_JE_UpdatedBy FOREIGN KEY (UpdatedByUserId) REFERENCES sec.[User](UserId)
    );

    CREATE INDEX IX_acct_JE_Date
      ON acct.JournalEntry (CompanyId, BranchId, EntryDate, JournalEntryId);
  END;

  IF OBJECT_ID('acct.JournalEntryLine', 'U') IS NULL
  BEGIN
    CREATE TABLE acct.JournalEntryLine(
      JournalEntryLineId      BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      JournalEntryId          BIGINT NOT NULL,
      LineNumber              INT NOT NULL,
      AccountId               BIGINT NOT NULL,
      AccountCodeSnapshot     NVARCHAR(40) NOT NULL,
      Description             NVARCHAR(400) NULL,
      DebitAmount             DECIMAL(18,2) NOT NULL CONSTRAINT DF_acct_JEL_Debit DEFAULT(0),
      CreditAmount            DECIMAL(18,2) NOT NULL CONSTRAINT DF_acct_JEL_Credit DEFAULT(0),
      AuxiliaryType           NVARCHAR(20) NULL,
      AuxiliaryCode           NVARCHAR(80) NULL,
      CostCenterCode          NVARCHAR(20) NULL,
      SourceDocumentNo        NVARCHAR(120) NULL,
      CreatedAt               DATETIME2(0) NOT NULL CONSTRAINT DF_acct_JEL_CreatedAt DEFAULT(SYSUTCDATETIME()),
      UpdatedAt               DATETIME2(0) NOT NULL CONSTRAINT DF_acct_JEL_UpdatedAt DEFAULT(SYSUTCDATETIME()),
      RowVer                  ROWVERSION NOT NULL,
      CONSTRAINT UQ_acct_JEL UNIQUE (JournalEntryId, LineNumber),
      CONSTRAINT CK_acct_JEL_DebitCredit CHECK (
        (DebitAmount >= 0 AND CreditAmount >= 0)
        AND NOT (DebitAmount > 0 AND CreditAmount > 0)
      ),
      CONSTRAINT FK_acct_JEL_JE FOREIGN KEY (JournalEntryId) REFERENCES acct.JournalEntry(JournalEntryId),
      CONSTRAINT FK_acct_JEL_Account FOREIGN KEY (AccountId) REFERENCES acct.Account(AccountId)
    );

    CREATE INDEX IX_acct_JEL_Account
      ON acct.JournalEntryLine (AccountId, JournalEntryId);
  END;

  IF OBJECT_ID('acct.DocumentLink', 'U') IS NULL
  BEGIN
    CREATE TABLE acct.DocumentLink(
      DocumentLinkId          BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      CompanyId               INT NOT NULL,
      BranchId                INT NOT NULL,
      ModuleCode              NVARCHAR(20) NOT NULL,
      DocumentType            NVARCHAR(20) NOT NULL,
      DocumentNumber          NVARCHAR(120) NOT NULL,
      NativeDocumentId        BIGINT NULL,
      JournalEntryId          BIGINT NOT NULL,
      CreatedAt               DATETIME2(0) NOT NULL CONSTRAINT DF_acct_DocLink_CreatedAt DEFAULT(SYSUTCDATETIME()),
      CONSTRAINT UQ_acct_DocLink UNIQUE (CompanyId, BranchId, ModuleCode, DocumentType, DocumentNumber),
      CONSTRAINT FK_acct_DocLink_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId),
      CONSTRAINT FK_acct_DocLink_Branch FOREIGN KEY (BranchId) REFERENCES cfg.Branch(BranchId),
      CONSTRAINT FK_acct_DocLink_JE FOREIGN KEY (JournalEntryId) REFERENCES acct.JournalEntry(JournalEntryId)
    );
  END;

  IF OBJECT_ID('acct.AccountingPolicy', 'U') IS NULL
  BEGIN
    CREATE TABLE acct.AccountingPolicy(
      AccountingPolicyId      BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      CompanyId               INT NOT NULL,
      ModuleCode              NVARCHAR(20) NOT NULL,
      ProcessCode             NVARCHAR(40) NOT NULL,
      Nature                  NVARCHAR(10) NOT NULL,
      AccountId               BIGINT NOT NULL,
      PriorityOrder           INT NOT NULL CONSTRAINT DF_acct_Policy_Priority DEFAULT(1),
      IsActive                BIT NOT NULL CONSTRAINT DF_acct_Policy_IsActive DEFAULT(1),
      CreatedAt               DATETIME2(0) NOT NULL CONSTRAINT DF_acct_Policy_CreatedAt DEFAULT(SYSUTCDATETIME()),
      UpdatedAt               DATETIME2(0) NOT NULL CONSTRAINT DF_acct_Policy_UpdatedAt DEFAULT(SYSUTCDATETIME()),
      CONSTRAINT CK_acct_Policy_Nature CHECK (Nature IN ('DEBIT','CREDIT')),
      CONSTRAINT UQ_acct_Policy UNIQUE (CompanyId, ModuleCode, ProcessCode, Nature, AccountId),
      CONSTRAINT FK_acct_Policy_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId),
      CONSTRAINT FK_acct_Policy_Account FOREIGN KEY (AccountId) REFERENCES acct.Account(AccountId)
    );
  END;

  COMMIT TRAN;
END TRY
BEGIN CATCH
  IF @@TRANCOUNT > 0 ROLLBACK TRAN;
  DECLARE @Err NVARCHAR(4000) = ERROR_MESSAGE();
  RAISERROR('Error 03_accounting_core.sql: %s',16,1,@Err);
END CATCH;
GO
