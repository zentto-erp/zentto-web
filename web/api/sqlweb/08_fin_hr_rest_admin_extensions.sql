
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

  IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'fin') EXEC('CREATE SCHEMA fin');
  IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'hr') EXEC('CREATE SCHEMA hr');

  DECLARE @DefaultCompanyId INT = (SELECT TOP 1 CompanyId FROM cfg.Company WHERE CompanyCode = N'DEFAULT');
  DECLARE @DefaultBranchId INT = (
    SELECT TOP 1 BranchId
    FROM cfg.Branch
    WHERE CompanyId = @DefaultCompanyId
      AND BranchCode = N'MAIN'
  );
  DECLARE @SystemUserId INT = (SELECT TOP 1 UserId FROM sec.[User] WHERE UserCode = N'SYSTEM');
  DECLARE @BaseCurrency CHAR(3) = (
    SELECT TOP 1 BaseCurrency
    FROM cfg.Company
    WHERE CompanyId = @DefaultCompanyId
  );

  IF OBJECT_ID('fin.Bank', 'U') IS NULL
  BEGIN
    CREATE TABLE fin.Bank(
      BankId                    BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      CompanyId                 INT NOT NULL,
      BankCode                  NVARCHAR(30) NOT NULL,
      BankName                  NVARCHAR(120) NOT NULL,
      ContactName               NVARCHAR(120) NULL,
      AddressLine               NVARCHAR(250) NULL,
      Phones                    NVARCHAR(120) NULL,
      IsActive                  BIT NOT NULL CONSTRAINT DF_fin_Bank_IsActive DEFAULT(1),
      CreatedAt                 DATETIME2(0) NOT NULL CONSTRAINT DF_fin_Bank_CreatedAt DEFAULT(SYSUTCDATETIME()),
      UpdatedAt                 DATETIME2(0) NOT NULL CONSTRAINT DF_fin_Bank_UpdatedAt DEFAULT(SYSUTCDATETIME()),
      CreatedByUserId           INT NULL,
      UpdatedByUserId           INT NULL,
      RowVer                    ROWVERSION NOT NULL,
      CONSTRAINT UQ_fin_Bank_Code UNIQUE (CompanyId, BankCode),
      CONSTRAINT UQ_fin_Bank_Name UNIQUE (CompanyId, BankName),
      CONSTRAINT FK_fin_Bank_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId),
      CONSTRAINT FK_fin_Bank_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
      CONSTRAINT FK_fin_Bank_UpdatedBy FOREIGN KEY (UpdatedByUserId) REFERENCES sec.[User](UserId)
    );
  END;

  IF OBJECT_ID('fin.BankAccount', 'U') IS NULL
  BEGIN
    CREATE TABLE fin.BankAccount(
      BankAccountId             BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      CompanyId                 INT NOT NULL,
      BranchId                  INT NOT NULL,
      BankId                    BIGINT NOT NULL,
      AccountNumber             NVARCHAR(40) NOT NULL,
      AccountName               NVARCHAR(150) NULL,
      CurrencyCode              CHAR(3) NOT NULL,
      Balance                   DECIMAL(18,2) NOT NULL CONSTRAINT DF_fin_BankAccount_Balance DEFAULT(0),
      AvailableBalance          DECIMAL(18,2) NOT NULL CONSTRAINT DF_fin_BankAccount_Available DEFAULT(0),
      IsActive                  BIT NOT NULL CONSTRAINT DF_fin_BankAccount_IsActive DEFAULT(1),
      CreatedAt                 DATETIME2(0) NOT NULL CONSTRAINT DF_fin_BankAccount_CreatedAt DEFAULT(SYSUTCDATETIME()),
      UpdatedAt                 DATETIME2(0) NOT NULL CONSTRAINT DF_fin_BankAccount_UpdatedAt DEFAULT(SYSUTCDATETIME()),
      CreatedByUserId           INT NULL,
      UpdatedByUserId           INT NULL,
      RowVer                    ROWVERSION NOT NULL,
      CONSTRAINT UQ_fin_BankAccount UNIQUE (CompanyId, AccountNumber),
      CONSTRAINT FK_fin_BankAccount_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId),
      CONSTRAINT FK_fin_BankAccount_Branch FOREIGN KEY (BranchId) REFERENCES cfg.Branch(BranchId),
      CONSTRAINT FK_fin_BankAccount_Bank FOREIGN KEY (BankId) REFERENCES fin.Bank(BankId),
      CONSTRAINT FK_fin_BankAccount_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
      CONSTRAINT FK_fin_BankAccount_UpdatedBy FOREIGN KEY (UpdatedByUserId) REFERENCES sec.[User](UserId)
    );

    CREATE INDEX IX_fin_BankAccount_Search
      ON fin.BankAccount (CompanyId, BranchId, IsActive, AccountNumber);
  END;

  IF OBJECT_ID('fin.BankReconciliation', 'U') IS NULL
  BEGIN
    CREATE TABLE fin.BankReconciliation(
      BankReconciliationId       BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      CompanyId                  INT NOT NULL,
      BranchId                   INT NOT NULL,
      BankAccountId              BIGINT NOT NULL,
      DateFrom                   DATE NOT NULL,
      DateTo                     DATE NOT NULL,
      OpeningSystemBalance       DECIMAL(18,2) NOT NULL,
      ClosingSystemBalance       DECIMAL(18,2) NOT NULL,
      OpeningBankBalance         DECIMAL(18,2) NOT NULL,
      ClosingBankBalance         DECIMAL(18,2) NULL,
      DifferenceAmount           DECIMAL(18,2) NULL,
      Status                     NVARCHAR(20) NOT NULL CONSTRAINT DF_fin_BankRec_Status DEFAULT(N'OPEN'),
      Notes                      NVARCHAR(500) NULL,
      ClosedAt                   DATETIME2(0) NULL,
      CreatedAt                  DATETIME2(0) NOT NULL CONSTRAINT DF_fin_BankRec_CreatedAt DEFAULT(SYSUTCDATETIME()),
      UpdatedAt                  DATETIME2(0) NOT NULL CONSTRAINT DF_fin_BankRec_UpdatedAt DEFAULT(SYSUTCDATETIME()),
      CreatedByUserId            INT NULL,
      ClosedByUserId             INT NULL,
      RowVer                     ROWVERSION NOT NULL,
      CONSTRAINT CK_fin_BankRec_Status CHECK (Status IN (N'OPEN',N'CLOSED',N'CLOSED_WITH_DIFF')),
      CONSTRAINT FK_fin_BankRec_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId),
      CONSTRAINT FK_fin_BankRec_Branch FOREIGN KEY (BranchId) REFERENCES cfg.Branch(BranchId),
      CONSTRAINT FK_fin_BankRec_Account FOREIGN KEY (BankAccountId) REFERENCES fin.BankAccount(BankAccountId),
      CONSTRAINT FK_fin_BankRec_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
      CONSTRAINT FK_fin_BankRec_ClosedBy FOREIGN KEY (ClosedByUserId) REFERENCES sec.[User](UserId)
    );

    CREATE INDEX IX_fin_BankRec_Search
      ON fin.BankReconciliation (BankAccountId, Status, DateFrom, DateTo);
  END;

  IF OBJECT_ID('fin.BankMovement', 'U') IS NULL
  BEGIN
    CREATE TABLE fin.BankMovement(
      BankMovementId             BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      BankAccountId              BIGINT NOT NULL,
      ReconciliationId           BIGINT NULL,
      MovementDate               DATETIME2(0) NOT NULL,
      MovementType               NVARCHAR(12) NOT NULL,
      MovementSign               SMALLINT NOT NULL,
      Amount                     DECIMAL(18,2) NOT NULL,
      NetAmount                  DECIMAL(18,2) NOT NULL,
      ReferenceNo                NVARCHAR(50) NULL,
      Beneficiary                NVARCHAR(255) NULL,
      Concept                    NVARCHAR(255) NULL,
      CategoryCode               NVARCHAR(50) NULL,
      RelatedDocumentNo          NVARCHAR(60) NULL,
      RelatedDocumentType        NVARCHAR(20) NULL,
      BalanceAfter               DECIMAL(18,2) NULL,
      IsReconciled               BIT NOT NULL CONSTRAINT DF_fin_BankMovement_Reconciled DEFAULT(0),
      ReconciledAt               DATETIME2(0) NULL,
      CreatedAt                  DATETIME2(0) NOT NULL CONSTRAINT DF_fin_BankMovement_CreatedAt DEFAULT(SYSUTCDATETIME()),
      CreatedByUserId            INT NULL,
      RowVer                     ROWVERSION NOT NULL,
      CONSTRAINT CK_fin_BankMovement_Sign CHECK (MovementSign IN (-1, 1)),
      CONSTRAINT CK_fin_BankMovement_Amount CHECK (Amount >= 0),
      CONSTRAINT FK_fin_BankMovement_Account FOREIGN KEY (BankAccountId) REFERENCES fin.BankAccount(BankAccountId),
      CONSTRAINT FK_fin_BankMovement_Reconciliation FOREIGN KEY (ReconciliationId) REFERENCES fin.BankReconciliation(BankReconciliationId),
      CONSTRAINT FK_fin_BankMovement_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId)
    );

    CREATE INDEX IX_fin_BankMovement_Search
      ON fin.BankMovement (BankAccountId, MovementDate DESC, BankMovementId DESC);
  END;

  IF OBJECT_ID('fin.BankStatementLine', 'U') IS NULL
  BEGIN
    CREATE TABLE fin.BankStatementLine(
      StatementLineId            BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      ReconciliationId           BIGINT NOT NULL,
      StatementDate              DATETIME2(0) NOT NULL,
      DescriptionText            NVARCHAR(255) NULL,
      ReferenceNo                NVARCHAR(50) NULL,
      EntryType                  NVARCHAR(12) NOT NULL,
      Amount                     DECIMAL(18,2) NOT NULL,
      Balance                    DECIMAL(18,2) NULL,
      IsMatched                  BIT NOT NULL CONSTRAINT DF_fin_BankStatementLine_IsMatched DEFAULT(0),
      MatchedAt                  DATETIME2(0) NULL,
      CreatedAt                  DATETIME2(0) NOT NULL CONSTRAINT DF_fin_BankStatementLine_CreatedAt DEFAULT(SYSUTCDATETIME()),
      CreatedByUserId            INT NULL,
      RowVer                     ROWVERSION NOT NULL,
      CONSTRAINT CK_fin_BankStatementLine_EntryType CHECK (EntryType IN (N'DEBITO', N'CREDITO')),
      CONSTRAINT CK_fin_BankStatementLine_Amount CHECK (Amount >= 0),
      CONSTRAINT FK_fin_BankStatementLine_Reconciliation FOREIGN KEY (ReconciliationId) REFERENCES fin.BankReconciliation(BankReconciliationId),
      CONSTRAINT FK_fin_BankStatementLine_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId)
    );

    CREATE INDEX IX_fin_BankStatementLine_Search
      ON fin.BankStatementLine (ReconciliationId, IsMatched, StatementDate);
  END;

  IF OBJECT_ID('fin.BankReconciliationMatch', 'U') IS NULL
  BEGIN
    CREATE TABLE fin.BankReconciliationMatch(
      BankReconciliationMatchId  BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      ReconciliationId           BIGINT NOT NULL,
      BankMovementId             BIGINT NOT NULL,
      StatementLineId            BIGINT NULL,
      MatchedAt                  DATETIME2(0) NOT NULL CONSTRAINT DF_fin_BankRecMatch_MatchedAt DEFAULT(SYSUTCDATETIME()),
      MatchedByUserId            INT NULL,
      CONSTRAINT UQ_fin_BankRecMatch_Movement UNIQUE (ReconciliationId, BankMovementId),
      CONSTRAINT UQ_fin_BankRecMatch_Statement UNIQUE (ReconciliationId, StatementLineId),
      CONSTRAINT FK_fin_BankRecMatch_Reconciliation FOREIGN KEY (ReconciliationId) REFERENCES fin.BankReconciliation(BankReconciliationId),
      CONSTRAINT FK_fin_BankRecMatch_Movement FOREIGN KEY (BankMovementId) REFERENCES fin.BankMovement(BankMovementId),
      CONSTRAINT FK_fin_BankRecMatch_Statement FOREIGN KEY (StatementLineId) REFERENCES fin.BankStatementLine(StatementLineId),
      CONSTRAINT FK_fin_BankRecMatch_User FOREIGN KEY (MatchedByUserId) REFERENCES sec.[User](UserId)
    );
  END;

  IF OBJECT_ID('hr.PayrollType', 'U') IS NULL
  BEGIN
    CREATE TABLE hr.PayrollType(
      PayrollTypeId              BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      CompanyId                  INT NOT NULL,
      PayrollCode                NVARCHAR(15) NOT NULL,
      PayrollName                NVARCHAR(120) NOT NULL,
      IsActive                   BIT NOT NULL CONSTRAINT DF_hr_PayrollType_IsActive DEFAULT(1),
      CreatedAt                  DATETIME2(0) NOT NULL CONSTRAINT DF_hr_PayrollType_CreatedAt DEFAULT(SYSUTCDATETIME()),
      UpdatedAt                  DATETIME2(0) NOT NULL CONSTRAINT DF_hr_PayrollType_UpdatedAt DEFAULT(SYSUTCDATETIME()),
      CreatedByUserId            INT NULL,
      UpdatedByUserId            INT NULL,
      RowVer                     ROWVERSION NOT NULL,
      CONSTRAINT UQ_hr_PayrollType UNIQUE (CompanyId, PayrollCode),
      CONSTRAINT FK_hr_PayrollType_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId),
      CONSTRAINT FK_hr_PayrollType_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
      CONSTRAINT FK_hr_PayrollType_UpdatedBy FOREIGN KEY (UpdatedByUserId) REFERENCES sec.[User](UserId)
    );
  END;

  IF OBJECT_ID('hr.PayrollConcept', 'U') IS NULL
  BEGIN
    CREATE TABLE hr.PayrollConcept(
      PayrollConceptId           BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      CompanyId                  INT NOT NULL,
      PayrollCode                NVARCHAR(15) NOT NULL,
      ConceptCode                NVARCHAR(20) NOT NULL,
      ConceptName                NVARCHAR(120) NOT NULL,
      Formula                    NVARCHAR(500) NULL,
      BaseExpression             NVARCHAR(255) NULL,
      ConceptClass               NVARCHAR(20) NULL,
      ConceptType                NVARCHAR(15) NOT NULL CONSTRAINT DF_hr_PayrollConcept_Type DEFAULT(N'ASIGNACION'),
      UsageType                  NVARCHAR(20) NULL,
      IsBonifiable               BIT NOT NULL CONSTRAINT DF_hr_PayrollConcept_Bonifiable DEFAULT(0),
      IsSeniority                BIT NOT NULL CONSTRAINT DF_hr_PayrollConcept_Seniority DEFAULT(0),
      AccountingAccountCode      NVARCHAR(50) NULL,
      AppliesFlag                BIT NOT NULL CONSTRAINT DF_hr_PayrollConcept_Applies DEFAULT(1),
      DefaultValue               DECIMAL(18,4) NOT NULL CONSTRAINT DF_hr_PayrollConcept_DefaultValue DEFAULT(0),
      ConventionCode             NVARCHAR(50) NULL,
      CalculationType            NVARCHAR(50) NULL,
      LotttArticle               NVARCHAR(50) NULL,
      CcpClause                  NVARCHAR(50) NULL,
      SortOrder                  INT NOT NULL CONSTRAINT DF_hr_PayrollConcept_Sort DEFAULT(0),
      IsActive                   BIT NOT NULL CONSTRAINT DF_hr_PayrollConcept_IsActive DEFAULT(1),
      CreatedAt                  DATETIME2(0) NOT NULL CONSTRAINT DF_hr_PayrollConcept_CreatedAt DEFAULT(SYSUTCDATETIME()),
      UpdatedAt                  DATETIME2(0) NOT NULL CONSTRAINT DF_hr_PayrollConcept_UpdatedAt DEFAULT(SYSUTCDATETIME()),
      CreatedByUserId            INT NULL,
      UpdatedByUserId            INT NULL,
      RowVer                     ROWVERSION NOT NULL,
      CONSTRAINT CK_hr_PayrollConcept_Type CHECK (ConceptType IN (N'ASIGNACION', N'DEDUCCION', N'BONO')),
      CONSTRAINT UQ_hr_PayrollConcept UNIQUE (CompanyId, PayrollCode, ConceptCode, ConventionCode, CalculationType),
      CONSTRAINT FK_hr_PayrollConcept_PayrollType FOREIGN KEY (CompanyId, PayrollCode) REFERENCES hr.PayrollType(CompanyId, PayrollCode),
      CONSTRAINT FK_hr_PayrollConcept_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
      CONSTRAINT FK_hr_PayrollConcept_UpdatedBy FOREIGN KEY (UpdatedByUserId) REFERENCES sec.[User](UserId)
    );

    CREATE INDEX IX_hr_PayrollConcept_Search
      ON hr.PayrollConcept (CompanyId, PayrollCode, IsActive, ConceptType, SortOrder, ConceptCode);
  END;

  IF OBJECT_ID('hr.PayrollRun', 'U') IS NULL
  BEGIN
    CREATE TABLE hr.PayrollRun(
      PayrollRunId               BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      CompanyId                  INT NOT NULL,
      BranchId                   INT NOT NULL,
      PayrollCode                NVARCHAR(15) NOT NULL,
      EmployeeId                 BIGINT NULL,
      EmployeeCode               NVARCHAR(24) NOT NULL,
      EmployeeName               NVARCHAR(200) NOT NULL,
      PositionName               NVARCHAR(120) NULL,
      ProcessDate                DATE NOT NULL,
      DateFrom                   DATE NOT NULL,
      DateTo                     DATE NOT NULL,
      TotalAssignments           DECIMAL(18,2) NOT NULL CONSTRAINT DF_hr_PayrollRun_Assign DEFAULT(0),
      TotalDeductions            DECIMAL(18,2) NOT NULL CONSTRAINT DF_hr_PayrollRun_Deduct DEFAULT(0),
      NetTotal                   DECIMAL(18,2) NOT NULL CONSTRAINT DF_hr_PayrollRun_Net DEFAULT(0),
      IsClosed                   BIT NOT NULL CONSTRAINT DF_hr_PayrollRun_IsClosed DEFAULT(0),
      PayrollTypeName            NVARCHAR(50) NULL,
      RunSource                  NVARCHAR(20) NOT NULL CONSTRAINT DF_hr_PayrollRun_Source DEFAULT(N'MANUAL'),
      ClosedAt                   DATETIME2(0) NULL,
      ClosedByUserId             INT NULL,
      CreatedAt                  DATETIME2(0) NOT NULL CONSTRAINT DF_hr_PayrollRun_CreatedAt DEFAULT(SYSUTCDATETIME()),
      UpdatedAt                  DATETIME2(0) NOT NULL CONSTRAINT DF_hr_PayrollRun_UpdatedAt DEFAULT(SYSUTCDATETIME()),
      CreatedByUserId            INT NULL,
      UpdatedByUserId            INT NULL,
      RowVer                     ROWVERSION NOT NULL,
      CONSTRAINT UQ_hr_PayrollRun UNIQUE (CompanyId, BranchId, PayrollCode, EmployeeCode, DateFrom, DateTo, RunSource),
      CONSTRAINT FK_hr_PayrollRun_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId),
      CONSTRAINT FK_hr_PayrollRun_Branch FOREIGN KEY (BranchId) REFERENCES cfg.Branch(BranchId),
      CONSTRAINT FK_hr_PayrollRun_Employee FOREIGN KEY (EmployeeId) REFERENCES [master].Employee(EmployeeId),
      CONSTRAINT FK_hr_PayrollRun_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
      CONSTRAINT FK_hr_PayrollRun_UpdatedBy FOREIGN KEY (UpdatedByUserId) REFERENCES sec.[User](UserId),
      CONSTRAINT FK_hr_PayrollRun_ClosedBy FOREIGN KEY (ClosedByUserId) REFERENCES sec.[User](UserId)
    );

    CREATE INDEX IX_hr_PayrollRun_Search
      ON hr.PayrollRun (CompanyId, PayrollCode, EmployeeCode, ProcessDate DESC, IsClosed);
  END;

  IF OBJECT_ID('hr.PayrollRunLine', 'U') IS NULL
  BEGIN
    CREATE TABLE hr.PayrollRunLine(
      PayrollRunLineId           BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      PayrollRunId               BIGINT NOT NULL,
      ConceptCode                NVARCHAR(20) NOT NULL,
      ConceptName                NVARCHAR(120) NOT NULL,
      ConceptType                NVARCHAR(15) NOT NULL,
      Quantity                   DECIMAL(18,4) NOT NULL CONSTRAINT DF_hr_PayrollRunLine_Qty DEFAULT(1),
      Amount                     DECIMAL(18,4) NOT NULL CONSTRAINT DF_hr_PayrollRunLine_Amount DEFAULT(0),
      Total                      DECIMAL(18,2) NOT NULL CONSTRAINT DF_hr_PayrollRunLine_Total DEFAULT(0),
      DescriptionText            NVARCHAR(255) NULL,
      AccountingAccountCode      NVARCHAR(50) NULL,
      CreatedAt                  DATETIME2(0) NOT NULL CONSTRAINT DF_hr_PayrollRunLine_CreatedAt DEFAULT(SYSUTCDATETIME()),
      CONSTRAINT FK_hr_PayrollRunLine_Run FOREIGN KEY (PayrollRunId) REFERENCES hr.PayrollRun(PayrollRunId) ON DELETE CASCADE
    );

    CREATE INDEX IX_hr_PayrollRunLine_Run
      ON hr.PayrollRunLine (PayrollRunId, ConceptType, ConceptCode);
  END;

  IF OBJECT_ID('hr.VacationProcess', 'U') IS NULL
  BEGIN
    CREATE TABLE hr.VacationProcess(
      VacationProcessId          BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      CompanyId                  INT NOT NULL,
      BranchId                   INT NOT NULL,
      VacationCode               NVARCHAR(50) NOT NULL,
      EmployeeId                 BIGINT NULL,
      EmployeeCode               NVARCHAR(24) NOT NULL,
      EmployeeName               NVARCHAR(200) NOT NULL,
      StartDate                  DATE NOT NULL,
      EndDate                    DATE NOT NULL,
      ReintegrationDate          DATE NULL,
      ProcessDate                DATE NOT NULL,
      TotalAmount                DECIMAL(18,2) NOT NULL CONSTRAINT DF_hr_VacationProcess_Total DEFAULT(0),
      CalculatedAmount           DECIMAL(18,2) NOT NULL CONSTRAINT DF_hr_VacationProcess_Calc DEFAULT(0),
      CreatedAt                  DATETIME2(0) NOT NULL CONSTRAINT DF_hr_VacationProcess_CreatedAt DEFAULT(SYSUTCDATETIME()),
      UpdatedAt                  DATETIME2(0) NOT NULL CONSTRAINT DF_hr_VacationProcess_UpdatedAt DEFAULT(SYSUTCDATETIME()),
      CreatedByUserId            INT NULL,
      UpdatedByUserId            INT NULL,
      RowVer                     ROWVERSION NOT NULL,
      CONSTRAINT UQ_hr_VacationProcess UNIQUE (CompanyId, VacationCode),
      CONSTRAINT FK_hr_VacationProcess_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId),
      CONSTRAINT FK_hr_VacationProcess_Branch FOREIGN KEY (BranchId) REFERENCES cfg.Branch(BranchId),
      CONSTRAINT FK_hr_VacationProcess_Employee FOREIGN KEY (EmployeeId) REFERENCES [master].Employee(EmployeeId),
      CONSTRAINT FK_hr_VacationProcess_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
      CONSTRAINT FK_hr_VacationProcess_UpdatedBy FOREIGN KEY (UpdatedByUserId) REFERENCES sec.[User](UserId)
    );
  END;

  IF OBJECT_ID('hr.VacationProcessLine', 'U') IS NULL
  BEGIN
    CREATE TABLE hr.VacationProcessLine(
      VacationProcessLineId      BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      VacationProcessId          BIGINT NOT NULL,
      ConceptCode                NVARCHAR(20) NOT NULL,
      ConceptName                NVARCHAR(120) NOT NULL,
      Amount                     DECIMAL(18,2) NOT NULL,
      CreatedAt                  DATETIME2(0) NOT NULL CONSTRAINT DF_hr_VacationProcessLine_CreatedAt DEFAULT(SYSUTCDATETIME()),
      CONSTRAINT FK_hr_VacationProcessLine_Process FOREIGN KEY (VacationProcessId) REFERENCES hr.VacationProcess(VacationProcessId) ON DELETE CASCADE
    );
  END;

  IF OBJECT_ID('hr.SettlementProcess', 'U') IS NULL
  BEGIN
    CREATE TABLE hr.SettlementProcess(
      SettlementProcessId        BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      CompanyId                  INT NOT NULL,
      BranchId                   INT NOT NULL,
      SettlementCode             NVARCHAR(50) NOT NULL,
      EmployeeId                 BIGINT NULL,
      EmployeeCode               NVARCHAR(24) NOT NULL,
      EmployeeName               NVARCHAR(200) NOT NULL,
      RetirementDate             DATE NOT NULL,
      RetirementCause            NVARCHAR(40) NULL,
      TotalAmount                DECIMAL(18,2) NOT NULL CONSTRAINT DF_hr_SettlementProcess_Total DEFAULT(0),
      CreatedAt                  DATETIME2(0) NOT NULL CONSTRAINT DF_hr_SettlementProcess_CreatedAt DEFAULT(SYSUTCDATETIME()),
      UpdatedAt                  DATETIME2(0) NOT NULL CONSTRAINT DF_hr_SettlementProcess_UpdatedAt DEFAULT(SYSUTCDATETIME()),
      CreatedByUserId            INT NULL,
      UpdatedByUserId            INT NULL,
      RowVer                     ROWVERSION NOT NULL,
      CONSTRAINT UQ_hr_SettlementProcess UNIQUE (CompanyId, SettlementCode),
      CONSTRAINT FK_hr_SettlementProcess_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId),
      CONSTRAINT FK_hr_SettlementProcess_Branch FOREIGN KEY (BranchId) REFERENCES cfg.Branch(BranchId),
      CONSTRAINT FK_hr_SettlementProcess_Employee FOREIGN KEY (EmployeeId) REFERENCES [master].Employee(EmployeeId),
      CONSTRAINT FK_hr_SettlementProcess_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
      CONSTRAINT FK_hr_SettlementProcess_UpdatedBy FOREIGN KEY (UpdatedByUserId) REFERENCES sec.[User](UserId)
    );
  END;

  IF OBJECT_ID('hr.SettlementProcessLine', 'U') IS NULL
  BEGIN
    CREATE TABLE hr.SettlementProcessLine(
      SettlementProcessLineId    BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      SettlementProcessId        BIGINT NOT NULL,
      ConceptCode                NVARCHAR(20) NOT NULL,
      ConceptName                NVARCHAR(120) NOT NULL,
      Amount                     DECIMAL(18,2) NOT NULL,
      CreatedAt                  DATETIME2(0) NOT NULL CONSTRAINT DF_hr_SettlementProcessLine_CreatedAt DEFAULT(SYSUTCDATETIME()),
      CONSTRAINT FK_hr_SettlementProcessLine_Process FOREIGN KEY (SettlementProcessId) REFERENCES hr.SettlementProcess(SettlementProcessId) ON DELETE CASCADE
    );
  END;

  IF OBJECT_ID('hr.PayrollConstant', 'U') IS NULL
  BEGIN
    CREATE TABLE hr.PayrollConstant(
      PayrollConstantId          BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      CompanyId                  INT NOT NULL,
      ConstantCode               NVARCHAR(50) NOT NULL,
      ConstantName               NVARCHAR(120) NOT NULL,
      ConstantValue              DECIMAL(18,4) NOT NULL,
      SourceName                 NVARCHAR(60) NULL,
      IsActive                   BIT NOT NULL CONSTRAINT DF_hr_PayrollConstant_IsActive DEFAULT(1),
      CreatedAt                  DATETIME2(0) NOT NULL CONSTRAINT DF_hr_PayrollConstant_CreatedAt DEFAULT(SYSUTCDATETIME()),
      UpdatedAt                  DATETIME2(0) NOT NULL CONSTRAINT DF_hr_PayrollConstant_UpdatedAt DEFAULT(SYSUTCDATETIME()),
      CreatedByUserId            INT NULL,
      UpdatedByUserId            INT NULL,
      RowVer                     ROWVERSION NOT NULL,
      CONSTRAINT UQ_hr_PayrollConstant UNIQUE (CompanyId, ConstantCode),
      CONSTRAINT FK_hr_PayrollConstant_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId),
      CONSTRAINT FK_hr_PayrollConstant_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
      CONSTRAINT FK_hr_PayrollConstant_UpdatedBy FOREIGN KEY (UpdatedByUserId) REFERENCES sec.[User](UserId)
    );
  END;

  IF OBJECT_ID('rest.MenuEnvironment', 'U') IS NULL
  BEGIN
    CREATE TABLE rest.MenuEnvironment(
      MenuEnvironmentId          BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      CompanyId                  INT NOT NULL,
      BranchId                   INT NOT NULL,
      EnvironmentCode            NVARCHAR(30) NOT NULL,
      EnvironmentName            NVARCHAR(120) NOT NULL,
      ColorHex                   NVARCHAR(10) NULL,
      SortOrder                  INT NOT NULL CONSTRAINT DF_rest_MenuEnvironment_Sort DEFAULT(0),
      IsActive                   BIT NOT NULL CONSTRAINT DF_rest_MenuEnvironment_IsActive DEFAULT(1),
      CreatedAt                  DATETIME2(0) NOT NULL CONSTRAINT DF_rest_MenuEnvironment_CreatedAt DEFAULT(SYSUTCDATETIME()),
      UpdatedAt                  DATETIME2(0) NOT NULL CONSTRAINT DF_rest_MenuEnvironment_UpdatedAt DEFAULT(SYSUTCDATETIME()),
      CreatedByUserId            INT NULL,
      UpdatedByUserId            INT NULL,
      RowVer                     ROWVERSION NOT NULL,
      CONSTRAINT UQ_rest_MenuEnvironment UNIQUE (CompanyId, BranchId, EnvironmentCode),
      CONSTRAINT FK_rest_MenuEnvironment_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId),
      CONSTRAINT FK_rest_MenuEnvironment_Branch FOREIGN KEY (BranchId) REFERENCES cfg.Branch(BranchId),
      CONSTRAINT FK_rest_MenuEnvironment_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
      CONSTRAINT FK_rest_MenuEnvironment_UpdatedBy FOREIGN KEY (UpdatedByUserId) REFERENCES sec.[User](UserId)
    );
  END;

  IF OBJECT_ID('rest.MenuCategory', 'U') IS NULL
  BEGIN
    CREATE TABLE rest.MenuCategory(
      MenuCategoryId             BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      CompanyId                  INT NOT NULL,
      BranchId                   INT NOT NULL,
      CategoryCode               NVARCHAR(30) NOT NULL,
      CategoryName               NVARCHAR(120) NOT NULL,
      DescriptionText            NVARCHAR(250) NULL,
      ColorHex                   NVARCHAR(10) NULL,
      SortOrder                  INT NOT NULL CONSTRAINT DF_rest_MenuCategory_Sort DEFAULT(0),
      IsActive                   BIT NOT NULL CONSTRAINT DF_rest_MenuCategory_IsActive DEFAULT(1),
      CreatedAt                  DATETIME2(0) NOT NULL CONSTRAINT DF_rest_MenuCategory_CreatedAt DEFAULT(SYSUTCDATETIME()),
      UpdatedAt                  DATETIME2(0) NOT NULL CONSTRAINT DF_rest_MenuCategory_UpdatedAt DEFAULT(SYSUTCDATETIME()),
      CreatedByUserId            INT NULL,
      UpdatedByUserId            INT NULL,
      RowVer                     ROWVERSION NOT NULL,
      CONSTRAINT UQ_rest_MenuCategory UNIQUE (CompanyId, BranchId, CategoryCode),
      CONSTRAINT FK_rest_MenuCategory_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId),
      CONSTRAINT FK_rest_MenuCategory_Branch FOREIGN KEY (BranchId) REFERENCES cfg.Branch(BranchId),
      CONSTRAINT FK_rest_MenuCategory_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
      CONSTRAINT FK_rest_MenuCategory_UpdatedBy FOREIGN KEY (UpdatedByUserId) REFERENCES sec.[User](UserId)
    );
  END;

  IF OBJECT_ID('rest.MenuProduct', 'U') IS NULL
  BEGIN
    CREATE TABLE rest.MenuProduct(
      MenuProductId              BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      CompanyId                  INT NOT NULL,
      BranchId                   INT NOT NULL,
      ProductCode                NVARCHAR(40) NOT NULL,
      ProductName                NVARCHAR(200) NOT NULL,
      DescriptionText            NVARCHAR(500) NULL,
      MenuCategoryId             BIGINT NULL,
      PriceAmount                DECIMAL(18,2) NOT NULL CONSTRAINT DF_rest_MenuProduct_Price DEFAULT(0),
      EstimatedCost              DECIMAL(18,2) NOT NULL CONSTRAINT DF_rest_MenuProduct_Cost DEFAULT(0),
      TaxRatePercent             DECIMAL(9,4) NOT NULL CONSTRAINT DF_rest_MenuProduct_Tax DEFAULT(16),
      IsComposite                BIT NOT NULL CONSTRAINT DF_rest_MenuProduct_IsComposite DEFAULT(0),
      PrepMinutes                INT NOT NULL CONSTRAINT DF_rest_MenuProduct_Prep DEFAULT(0),
      ImageUrl                   NVARCHAR(500) NULL,
      IsDailySuggestion          BIT NOT NULL CONSTRAINT DF_rest_MenuProduct_Daily DEFAULT(0),
      IsAvailable                BIT NOT NULL CONSTRAINT DF_rest_MenuProduct_Available DEFAULT(1),
      InventoryProductId         BIGINT NULL,
      IsActive                   BIT NOT NULL CONSTRAINT DF_rest_MenuProduct_IsActive DEFAULT(1),
      CreatedAt                  DATETIME2(0) NOT NULL CONSTRAINT DF_rest_MenuProduct_CreatedAt DEFAULT(SYSUTCDATETIME()),
      UpdatedAt                  DATETIME2(0) NOT NULL CONSTRAINT DF_rest_MenuProduct_UpdatedAt DEFAULT(SYSUTCDATETIME()),
      CreatedByUserId            INT NULL,
      UpdatedByUserId            INT NULL,
      RowVer                     ROWVERSION NOT NULL,
      CONSTRAINT UQ_rest_MenuProduct UNIQUE (CompanyId, BranchId, ProductCode),
      CONSTRAINT FK_rest_MenuProduct_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId),
      CONSTRAINT FK_rest_MenuProduct_Branch FOREIGN KEY (BranchId) REFERENCES cfg.Branch(BranchId),
      CONSTRAINT FK_rest_MenuProduct_Category FOREIGN KEY (MenuCategoryId) REFERENCES rest.MenuCategory(MenuCategoryId),
      CONSTRAINT FK_rest_MenuProduct_InventoryProduct FOREIGN KEY (InventoryProductId) REFERENCES [master].Product(ProductId),
      CONSTRAINT FK_rest_MenuProduct_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
      CONSTRAINT FK_rest_MenuProduct_UpdatedBy FOREIGN KEY (UpdatedByUserId) REFERENCES sec.[User](UserId)
    );

    CREATE INDEX IX_rest_MenuProduct_Search
      ON rest.MenuProduct (CompanyId, BranchId, IsActive, IsAvailable, ProductCode, ProductName);
  END;

  IF OBJECT_ID('rest.MenuComponent', 'U') IS NULL
  BEGIN
    CREATE TABLE rest.MenuComponent(
      MenuComponentId            BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      MenuProductId              BIGINT NOT NULL,
      ComponentName              NVARCHAR(120) NOT NULL,
      IsRequired                 BIT NOT NULL CONSTRAINT DF_rest_MenuComponent_IsRequired DEFAULT(0),
      SortOrder                  INT NOT NULL CONSTRAINT DF_rest_MenuComponent_Sort DEFAULT(0),
      IsActive                   BIT NOT NULL CONSTRAINT DF_rest_MenuComponent_IsActive DEFAULT(1),
      CreatedAt                  DATETIME2(0) NOT NULL CONSTRAINT DF_rest_MenuComponent_CreatedAt DEFAULT(SYSUTCDATETIME()),
      UpdatedAt                  DATETIME2(0) NOT NULL CONSTRAINT DF_rest_MenuComponent_UpdatedAt DEFAULT(SYSUTCDATETIME()),
      CONSTRAINT FK_rest_MenuComponent_Product FOREIGN KEY (MenuProductId) REFERENCES rest.MenuProduct(MenuProductId) ON DELETE CASCADE
    );
  END;

  IF OBJECT_ID('rest.MenuOption', 'U') IS NULL
  BEGIN
    CREATE TABLE rest.MenuOption(
      MenuOptionId               BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      MenuComponentId            BIGINT NOT NULL,
      OptionName                 NVARCHAR(120) NOT NULL,
      ExtraPrice                 DECIMAL(18,2) NOT NULL CONSTRAINT DF_rest_MenuOption_Extra DEFAULT(0),
      SortOrder                  INT NOT NULL CONSTRAINT DF_rest_MenuOption_Sort DEFAULT(0),
      IsActive                   BIT NOT NULL CONSTRAINT DF_rest_MenuOption_IsActive DEFAULT(1),
      CreatedAt                  DATETIME2(0) NOT NULL CONSTRAINT DF_rest_MenuOption_CreatedAt DEFAULT(SYSUTCDATETIME()),
      UpdatedAt                  DATETIME2(0) NOT NULL CONSTRAINT DF_rest_MenuOption_UpdatedAt DEFAULT(SYSUTCDATETIME()),
      CONSTRAINT FK_rest_MenuOption_Component FOREIGN KEY (MenuComponentId) REFERENCES rest.MenuComponent(MenuComponentId) ON DELETE CASCADE
    );
  END;

  IF OBJECT_ID('rest.MenuRecipe', 'U') IS NULL
  BEGIN
    CREATE TABLE rest.MenuRecipe(
      MenuRecipeId               BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      MenuProductId              BIGINT NOT NULL,
      IngredientProductId        BIGINT NOT NULL,
      Quantity                   DECIMAL(18,4) NOT NULL,
      UnitCode                   NVARCHAR(20) NULL,
      Notes                      NVARCHAR(200) NULL,
      IsActive                   BIT NOT NULL CONSTRAINT DF_rest_MenuRecipe_IsActive DEFAULT(1),
      CreatedAt                  DATETIME2(0) NOT NULL CONSTRAINT DF_rest_MenuRecipe_CreatedAt DEFAULT(SYSUTCDATETIME()),
      UpdatedAt                  DATETIME2(0) NOT NULL CONSTRAINT DF_rest_MenuRecipe_UpdatedAt DEFAULT(SYSUTCDATETIME()),
      CONSTRAINT FK_rest_MenuRecipe_MenuProduct FOREIGN KEY (MenuProductId) REFERENCES rest.MenuProduct(MenuProductId) ON DELETE CASCADE,
      CONSTRAINT FK_rest_MenuRecipe_Ingredient FOREIGN KEY (IngredientProductId) REFERENCES [master].Product(ProductId)
    );
  END;

  IF OBJECT_ID('rest.Purchase', 'U') IS NULL
  BEGIN
    CREATE TABLE rest.Purchase(
      PurchaseId                 BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      CompanyId                  INT NOT NULL,
      BranchId                   INT NOT NULL,
      PurchaseNumber             NVARCHAR(30) NOT NULL,
      SupplierId                 BIGINT NULL,
      PurchaseDate               DATETIME2(0) NOT NULL CONSTRAINT DF_rest_Purchase_Date DEFAULT(SYSUTCDATETIME()),
      Status                     NVARCHAR(20) NOT NULL CONSTRAINT DF_rest_Purchase_Status DEFAULT(N'PENDIENTE'),
      SubtotalAmount             DECIMAL(18,2) NOT NULL CONSTRAINT DF_rest_Purchase_Subtotal DEFAULT(0),
      TaxAmount                  DECIMAL(18,2) NOT NULL CONSTRAINT DF_rest_Purchase_Tax DEFAULT(0),
      TotalAmount                DECIMAL(18,2) NOT NULL CONSTRAINT DF_rest_Purchase_Total DEFAULT(0),
      Notes                      NVARCHAR(500) NULL,
      CreatedAt                  DATETIME2(0) NOT NULL CONSTRAINT DF_rest_Purchase_CreatedAt DEFAULT(SYSUTCDATETIME()),
      UpdatedAt                  DATETIME2(0) NOT NULL CONSTRAINT DF_rest_Purchase_UpdatedAt DEFAULT(SYSUTCDATETIME()),
      CreatedByUserId            INT NULL,
      UpdatedByUserId            INT NULL,
      RowVer                     ROWVERSION NOT NULL,
      CONSTRAINT UQ_rest_Purchase UNIQUE (CompanyId, BranchId, PurchaseNumber),
      CONSTRAINT FK_rest_Purchase_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId),
      CONSTRAINT FK_rest_Purchase_Branch FOREIGN KEY (BranchId) REFERENCES cfg.Branch(BranchId),
      CONSTRAINT FK_rest_Purchase_Supplier FOREIGN KEY (SupplierId) REFERENCES [master].Supplier(SupplierId),
      CONSTRAINT FK_rest_Purchase_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
      CONSTRAINT FK_rest_Purchase_UpdatedBy FOREIGN KEY (UpdatedByUserId) REFERENCES sec.[User](UserId)
    );

    CREATE INDEX IX_rest_Purchase_Search
      ON rest.Purchase (CompanyId, BranchId, PurchaseDate DESC, Status);
  END;

  IF OBJECT_ID('rest.PurchaseLine', 'U') IS NULL
  BEGIN
    CREATE TABLE rest.PurchaseLine(
      PurchaseLineId             BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      PurchaseId                 BIGINT NOT NULL,
      IngredientProductId        BIGINT NULL,
      DescriptionText            NVARCHAR(200) NOT NULL,
      Quantity                   DECIMAL(18,4) NOT NULL,
      UnitPrice                  DECIMAL(18,2) NOT NULL,
      TaxRatePercent             DECIMAL(9,4) NOT NULL,
      SubtotalAmount             DECIMAL(18,2) NOT NULL,
      CreatedAt                  DATETIME2(0) NOT NULL CONSTRAINT DF_rest_PurchaseLine_CreatedAt DEFAULT(SYSUTCDATETIME()),
      UpdatedAt                  DATETIME2(0) NOT NULL CONSTRAINT DF_rest_PurchaseLine_UpdatedAt DEFAULT(SYSUTCDATETIME()),
      CONSTRAINT FK_rest_PurchaseLine_Purchase FOREIGN KEY (PurchaseId) REFERENCES rest.Purchase(PurchaseId) ON DELETE CASCADE,
      CONSTRAINT FK_rest_PurchaseLine_Ingredient FOREIGN KEY (IngredientProductId) REFERENCES [master].Product(ProductId)
    );
  END;

  IF @DefaultCompanyId IS NOT NULL
  BEGIN
    IF NOT EXISTS (
      SELECT 1
      FROM hr.PayrollType
      WHERE CompanyId = @DefaultCompanyId
        AND PayrollCode = N'GENERAL'
    )
    BEGIN
      INSERT INTO hr.PayrollType (
        CompanyId,
        PayrollCode,
        PayrollName,
        IsActive,
        CreatedByUserId,
        UpdatedByUserId
      )
      VALUES (
        @DefaultCompanyId,
        N'GENERAL',
        N'Nomina General',
        1,
        @SystemUserId,
        @SystemUserId
      );
    END;

    IF NOT EXISTS (
      SELECT 1
      FROM hr.PayrollConstant
      WHERE CompanyId = @DefaultCompanyId
        AND ConstantCode = N'SALARIO_MINIMO'
    )
    BEGIN
      INSERT INTO hr.PayrollConstant (
        CompanyId,
        ConstantCode,
        ConstantName,
        ConstantValue,
        SourceName,
        IsActive,
        CreatedByUserId,
        UpdatedByUserId
      )
      VALUES (
        @DefaultCompanyId,
        N'SALARIO_MINIMO',
        N'Salario minimo de referencia',
        100,
        N'DEFAULT',
        1,
        @SystemUserId,
        @SystemUserId
      );
    END;

    IF NOT EXISTS (
      SELECT 1
      FROM hr.PayrollConstant
      WHERE CompanyId = @DefaultCompanyId
        AND ConstantCode = N'SALARIO_DIARIO'
    )
    BEGIN
      INSERT INTO hr.PayrollConstant (
        CompanyId,
        ConstantCode,
        ConstantName,
        ConstantValue,
        SourceName,
        IsActive,
        CreatedByUserId,
        UpdatedByUserId
      )
      VALUES (
        @DefaultCompanyId,
        N'SALARIO_DIARIO',
        N'Salario diario de referencia',
        3.3333,
        N'DEFAULT',
        1,
        @SystemUserId,
        @SystemUserId
      );
    END;

    IF NOT EXISTS (
      SELECT 1
      FROM fin.Bank
      WHERE CompanyId = @DefaultCompanyId
        AND BankCode = N'BANCO_DEFAULT'
    )
    BEGIN
      INSERT INTO fin.Bank (
        CompanyId,
        BankCode,
        BankName,
        ContactName,
        IsActive,
        CreatedByUserId,
        UpdatedByUserId
      )
      VALUES (
        @DefaultCompanyId,
        N'BANCO_DEFAULT',
        N'Banco Default',
        N'Sistema',
        1,
        @SystemUserId,
        @SystemUserId
      );
    END;

    DECLARE @DefaultBankId BIGINT = (
      SELECT TOP 1 BankId
      FROM fin.Bank
      WHERE CompanyId = @DefaultCompanyId
        AND BankCode = N'BANCO_DEFAULT'
    );

    IF @DefaultBankId IS NOT NULL
       AND @DefaultBranchId IS NOT NULL
       AND NOT EXISTS (
         SELECT 1
         FROM fin.BankAccount
         WHERE CompanyId = @DefaultCompanyId
           AND AccountNumber = N'0000000000'
       )
    BEGIN
      INSERT INTO fin.BankAccount (
        CompanyId,
        BranchId,
        BankId,
        AccountNumber,
        AccountName,
        CurrencyCode,
        Balance,
        AvailableBalance,
        IsActive,
        CreatedByUserId,
        UpdatedByUserId
      )
      VALUES (
        @DefaultCompanyId,
        @DefaultBranchId,
        @DefaultBankId,
        N'0000000000',
        N'Cuenta Principal',
        ISNULL(@BaseCurrency, 'VES'),
        0,
        0,
        1,
        @SystemUserId,
        @SystemUserId
      );
    END;

    IF @DefaultBranchId IS NOT NULL
       AND NOT EXISTS (
         SELECT 1
         FROM rest.MenuEnvironment
         WHERE CompanyId = @DefaultCompanyId
           AND BranchId = @DefaultBranchId
           AND EnvironmentCode = N'SALON'
       )
    BEGIN
      INSERT INTO rest.MenuEnvironment (
        CompanyId,
        BranchId,
        EnvironmentCode,
        EnvironmentName,
        ColorHex,
        SortOrder,
        IsActive,
        CreatedByUserId,
        UpdatedByUserId
      )
      VALUES (
        @DefaultCompanyId,
        @DefaultBranchId,
        N'SALON',
        N'Salon Principal',
        N'#4CAF50',
        1,
        1,
        @SystemUserId,
        @SystemUserId
      );
    END;

    IF @DefaultBranchId IS NOT NULL
       AND NOT EXISTS (
         SELECT 1
         FROM rest.MenuCategory
         WHERE CompanyId = @DefaultCompanyId
           AND BranchId = @DefaultBranchId
           AND CategoryCode = N'GENERAL'
       )
    BEGIN
      INSERT INTO rest.MenuCategory (
        CompanyId,
        BranchId,
        CategoryCode,
        CategoryName,
        DescriptionText,
        ColorHex,
        SortOrder,
        IsActive,
        CreatedByUserId,
        UpdatedByUserId
      )
      VALUES (
        @DefaultCompanyId,
        @DefaultBranchId,
        N'GENERAL',
        N'General',
        N'Categoria general de menu',
        N'#607D8B',
        1,
        1,
        @SystemUserId,
        @SystemUserId
      );
    END;
  END;

  COMMIT TRAN;
END TRY
BEGIN CATCH
  IF @@TRANCOUNT > 0 ROLLBACK TRAN;
  DECLARE @Err NVARCHAR(4000) = ERROR_MESSAGE();
  RAISERROR('Error 08_fin_hr_rest_admin_extensions.sql: %s',16,1,@Err);
END CATCH;
GO

