-- =============================================================================
-- 11_crm.sql
-- CRM: Pipelines, Stages, Leads, Activities, Lead History
-- =============================================================================
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

USE DatqBoxWeb;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

-- Schema
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'crm')
  EXEC('CREATE SCHEMA crm');
GO

BEGIN TRY
  BEGIN TRAN;

  -- =========================================================================
  -- 1. crm.Pipeline
  -- =========================================================================
  IF OBJECT_ID('crm.Pipeline', 'U') IS NULL
  BEGIN
    CREATE TABLE crm.Pipeline(
      PipelineId          BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      CompanyId           INT NOT NULL,
      PipelineCode        NVARCHAR(40) NOT NULL,
      PipelineName        NVARCHAR(200) NOT NULL,
      IsDefault           BIT NOT NULL CONSTRAINT DF_crm_Pipeline_IsDefault DEFAULT(0),
      IsActive            BIT NOT NULL CONSTRAINT DF_crm_Pipeline_IsActive DEFAULT(1),
      CreatedAt           DATETIME2(0) NOT NULL CONSTRAINT DF_crm_Pipeline_CreatedAt DEFAULT(SYSUTCDATETIME()),
      UpdatedAt           DATETIME2(0) NOT NULL CONSTRAINT DF_crm_Pipeline_UpdatedAt DEFAULT(SYSUTCDATETIME()),
      CreatedByUserId     INT NULL,
      UpdatedByUserId     INT NULL,
      IsDeleted           BIT NOT NULL CONSTRAINT DF_crm_Pipeline_IsDeleted DEFAULT(0),
      DeletedAt           DATETIME2(0) NULL,
      DeletedByUserId     INT NULL,
      RowVer              ROWVERSION NOT NULL,
      CONSTRAINT UQ_crm_Pipeline_Code UNIQUE (CompanyId, PipelineCode),
      CONSTRAINT FK_crm_Pipeline_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId),
      CONSTRAINT FK_crm_Pipeline_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
      CONSTRAINT FK_crm_Pipeline_UpdatedBy FOREIGN KEY (UpdatedByUserId) REFERENCES sec.[User](UserId),
      CONSTRAINT FK_crm_Pipeline_DeletedBy FOREIGN KEY (DeletedByUserId) REFERENCES sec.[User](UserId)
    );
  END;

  -- =========================================================================
  -- 2. crm.PipelineStage
  -- =========================================================================
  IF OBJECT_ID('crm.PipelineStage', 'U') IS NULL
  BEGIN
    CREATE TABLE crm.PipelineStage(
      StageId             BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      PipelineId          BIGINT NOT NULL,
      StageCode           NVARCHAR(40) NOT NULL,
      StageName           NVARCHAR(200) NOT NULL,
      StageOrder          INT NOT NULL,
      Probability         DECIMAL(9,4) NOT NULL CONSTRAINT DF_crm_PipelineStage_Probability DEFAULT(0),
      DaysExpected        INT NOT NULL CONSTRAINT DF_crm_PipelineStage_DaysExpected DEFAULT(7),
      Color               NVARCHAR(20) NULL,
      IsClosed            BIT NOT NULL CONSTRAINT DF_crm_PipelineStage_IsClosed DEFAULT(0),
      IsWon               BIT NOT NULL CONSTRAINT DF_crm_PipelineStage_IsWon DEFAULT(0),
      IsActive            BIT NOT NULL CONSTRAINT DF_crm_PipelineStage_IsActive DEFAULT(1),
      CreatedAt           DATETIME2(0) NOT NULL CONSTRAINT DF_crm_PipelineStage_CreatedAt DEFAULT(SYSUTCDATETIME()),
      UpdatedAt           DATETIME2(0) NOT NULL CONSTRAINT DF_crm_PipelineStage_UpdatedAt DEFAULT(SYSUTCDATETIME()),
      CreatedByUserId     INT NULL,
      UpdatedByUserId     INT NULL,
      IsDeleted           BIT NOT NULL CONSTRAINT DF_crm_PipelineStage_IsDeleted DEFAULT(0),
      DeletedAt           DATETIME2(0) NULL,
      DeletedByUserId     INT NULL,
      RowVer              ROWVERSION NOT NULL,
      CONSTRAINT UQ_crm_PipelineStage_Code UNIQUE (PipelineId, StageCode),
      CONSTRAINT FK_crm_PipelineStage_Pipeline FOREIGN KEY (PipelineId) REFERENCES crm.Pipeline(PipelineId),
      CONSTRAINT FK_crm_PipelineStage_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
      CONSTRAINT FK_crm_PipelineStage_UpdatedBy FOREIGN KEY (UpdatedByUserId) REFERENCES sec.[User](UserId),
      CONSTRAINT FK_crm_PipelineStage_DeletedBy FOREIGN KEY (DeletedByUserId) REFERENCES sec.[User](UserId)
    );
  END;

  -- =========================================================================
  -- 3. crm.Lead
  -- =========================================================================
  IF OBJECT_ID('crm.Lead', 'U') IS NULL
  BEGIN
    CREATE TABLE crm.Lead(
      LeadId              BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      CompanyId           INT NOT NULL,
      BranchId            INT NOT NULL,
      PipelineId          BIGINT NOT NULL,
      StageId             BIGINT NOT NULL,
      LeadCode            NVARCHAR(40) NOT NULL,
      ContactName         NVARCHAR(200) NOT NULL,
      CompanyName         NVARCHAR(200) NULL,
      Email               NVARCHAR(200) NULL,
      Phone               NVARCHAR(60) NULL,
      Source              NVARCHAR(20) NOT NULL CONSTRAINT DF_crm_Lead_Source DEFAULT('OTHER'),
      AssignedToUserId    INT NULL,
      CustomerId          BIGINT NULL,
      EstimatedValue      DECIMAL(18,2) NOT NULL CONSTRAINT DF_crm_Lead_EstimatedValue DEFAULT(0),
      CurrencyCode        CHAR(3) NOT NULL CONSTRAINT DF_crm_Lead_CurrencyCode DEFAULT('USD'),
      ExpectedCloseDate   DATE NULL,
      LostReason          NVARCHAR(500) NULL,
      Notes               NVARCHAR(MAX) NULL,
      Tags                NVARCHAR(500) NULL,
      Priority            NVARCHAR(10) NOT NULL CONSTRAINT DF_crm_Lead_Priority DEFAULT('MEDIUM'),
      Status              NVARCHAR(10) NOT NULL CONSTRAINT DF_crm_Lead_Status DEFAULT('OPEN'),
      WonAt               DATETIME2(0) NULL,
      LostAt              DATETIME2(0) NULL,
      CreatedAt           DATETIME2(0) NOT NULL CONSTRAINT DF_crm_Lead_CreatedAt DEFAULT(SYSUTCDATETIME()),
      UpdatedAt           DATETIME2(0) NOT NULL CONSTRAINT DF_crm_Lead_UpdatedAt DEFAULT(SYSUTCDATETIME()),
      CreatedByUserId     INT NULL,
      UpdatedByUserId     INT NULL,
      IsDeleted           BIT NOT NULL CONSTRAINT DF_crm_Lead_IsDeleted DEFAULT(0),
      DeletedAt           DATETIME2(0) NULL,
      DeletedByUserId     INT NULL,
      RowVer              ROWVERSION NOT NULL,
      CONSTRAINT UQ_crm_Lead_Code UNIQUE (CompanyId, LeadCode),
      CONSTRAINT CK_crm_Lead_Source CHECK (Source IN ('WEB','REFERRAL','COLD_CALL','EVENT','SOCIAL','OTHER')),
      CONSTRAINT CK_crm_Lead_Priority CHECK (Priority IN ('LOW','MEDIUM','HIGH','URGENT')),
      CONSTRAINT CK_crm_Lead_Status CHECK (Status IN ('OPEN','WON','LOST','ARCHIVED')),
      CONSTRAINT FK_crm_Lead_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId),
      CONSTRAINT FK_crm_Lead_Branch FOREIGN KEY (BranchId) REFERENCES cfg.Branch(BranchId),
      CONSTRAINT FK_crm_Lead_Pipeline FOREIGN KEY (PipelineId) REFERENCES crm.Pipeline(PipelineId),
      CONSTRAINT FK_crm_Lead_Stage FOREIGN KEY (StageId) REFERENCES crm.PipelineStage(StageId),
      CONSTRAINT FK_crm_Lead_AssignedTo FOREIGN KEY (AssignedToUserId) REFERENCES sec.[User](UserId),
      CONSTRAINT FK_crm_Lead_Customer FOREIGN KEY (CustomerId) REFERENCES master.Customer(CustomerId),
      CONSTRAINT FK_crm_Lead_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
      CONSTRAINT FK_crm_Lead_UpdatedBy FOREIGN KEY (UpdatedByUserId) REFERENCES sec.[User](UserId),
      CONSTRAINT FK_crm_Lead_DeletedBy FOREIGN KEY (DeletedByUserId) REFERENCES sec.[User](UserId)
    );

    CREATE INDEX IX_crm_Lead_Status_Stage
      ON crm.Lead (CompanyId, Status, StageId);
  END;

  -- =========================================================================
  -- 4. crm.Activity
  -- =========================================================================
  IF OBJECT_ID('crm.Activity', 'U') IS NULL
  BEGIN
    CREATE TABLE crm.Activity(
      ActivityId          BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      CompanyId           INT NOT NULL,
      LeadId              BIGINT NULL,
      CustomerId          BIGINT NULL,
      ActivityType        NVARCHAR(20) NOT NULL CONSTRAINT DF_crm_Activity_Type DEFAULT('NOTE'),
      Subject             NVARCHAR(200) NOT NULL,
      Description         NVARCHAR(MAX) NULL,
      DueDate             DATETIME2(0) NULL,
      CompletedAt         DATETIME2(0) NULL,
      AssignedToUserId    INT NULL,
      IsCompleted         BIT NOT NULL CONSTRAINT DF_crm_Activity_IsCompleted DEFAULT(0),
      Priority            NVARCHAR(10) NOT NULL CONSTRAINT DF_crm_Activity_Priority DEFAULT('MEDIUM'),
      CreatedAt           DATETIME2(0) NOT NULL CONSTRAINT DF_crm_Activity_CreatedAt DEFAULT(SYSUTCDATETIME()),
      UpdatedAt           DATETIME2(0) NOT NULL CONSTRAINT DF_crm_Activity_UpdatedAt DEFAULT(SYSUTCDATETIME()),
      CreatedByUserId     INT NULL,
      UpdatedByUserId     INT NULL,
      IsDeleted           BIT NOT NULL CONSTRAINT DF_crm_Activity_IsDeleted DEFAULT(0),
      DeletedAt           DATETIME2(0) NULL,
      DeletedByUserId     INT NULL,
      RowVer              ROWVERSION NOT NULL,
      CONSTRAINT CK_crm_Activity_Type CHECK (ActivityType IN ('CALL','EMAIL','MEETING','NOTE','TASK','FOLLOWUP')),
      CONSTRAINT CK_crm_Activity_Priority CHECK (Priority IN ('LOW','MEDIUM','HIGH','URGENT')),
      CONSTRAINT FK_crm_Activity_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId),
      CONSTRAINT FK_crm_Activity_Lead FOREIGN KEY (LeadId) REFERENCES crm.Lead(LeadId),
      CONSTRAINT FK_crm_Activity_Customer FOREIGN KEY (CustomerId) REFERENCES master.Customer(CustomerId),
      CONSTRAINT FK_crm_Activity_AssignedTo FOREIGN KEY (AssignedToUserId) REFERENCES sec.[User](UserId),
      CONSTRAINT FK_crm_Activity_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
      CONSTRAINT FK_crm_Activity_UpdatedBy FOREIGN KEY (UpdatedByUserId) REFERENCES sec.[User](UserId),
      CONSTRAINT FK_crm_Activity_DeletedBy FOREIGN KEY (DeletedByUserId) REFERENCES sec.[User](UserId)
    );

    CREATE INDEX IX_crm_Activity_Pending
      ON crm.Activity (CompanyId, IsCompleted, DueDate);
  END;

  -- =========================================================================
  -- 5. crm.LeadHistory
  -- =========================================================================
  IF OBJECT_ID('crm.LeadHistory', 'U') IS NULL
  BEGIN
    CREATE TABLE crm.LeadHistory(
      HistoryId           BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      LeadId              BIGINT NOT NULL,
      FromStageId         BIGINT NULL,
      ToStageId           BIGINT NULL,
      ChangedByUserId     INT NOT NULL,
      ChangeType          NVARCHAR(20) NOT NULL CONSTRAINT DF_crm_LeadHistory_ChangeType DEFAULT('NOTE'),
      Notes               NVARCHAR(500) NULL,
      CreatedAt           DATETIME2(0) NOT NULL CONSTRAINT DF_crm_LeadHistory_CreatedAt DEFAULT(SYSUTCDATETIME()),
      CONSTRAINT CK_crm_LeadHistory_ChangeType CHECK (ChangeType IN ('STAGE_CHANGE','ASSIGN','NOTE','STATUS')),
      CONSTRAINT FK_crm_LeadHistory_Lead FOREIGN KEY (LeadId) REFERENCES crm.Lead(LeadId),
      CONSTRAINT FK_crm_LeadHistory_FromStage FOREIGN KEY (FromStageId) REFERENCES crm.PipelineStage(StageId),
      CONSTRAINT FK_crm_LeadHistory_ToStage FOREIGN KEY (ToStageId) REFERENCES crm.PipelineStage(StageId),
      CONSTRAINT FK_crm_LeadHistory_ChangedBy FOREIGN KEY (ChangedByUserId) REFERENCES sec.[User](UserId)
    );

    CREATE INDEX IX_crm_LeadHistory_Lead
      ON crm.LeadHistory (LeadId, CreatedAt DESC);
  END;

  COMMIT TRAN;
  PRINT '[11_crm] Esquema CRM creado correctamente.';
END TRY
BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRAN;
  PRINT '[11_crm] ERROR: ' + ERROR_MESSAGE();
  THROW;
END CATCH;
GO
