SET NOCOUNT ON;
GO

IF NOT EXISTS (
  SELECT 1
  FROM sys.schemas
  WHERE name = N'sec'
)
BEGIN
  EXEC('CREATE SCHEMA sec');
END
GO

IF OBJECT_ID(N'sec.SupervisorOverride', N'U') IS NULL
BEGIN
  CREATE TABLE sec.SupervisorOverride (
    OverrideId BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    ModuleCode NVARCHAR(32) NOT NULL,
    ActionCode NVARCHAR(64) NOT NULL,
    Status NVARCHAR(20) NOT NULL CONSTRAINT DF_SupervisorOverride_Status DEFAULT(N'APPROVED'),
    CompanyId INT NULL,
    BranchId INT NULL,
    RequestedByUserCode NVARCHAR(50) NULL,
    SupervisorUserCode NVARCHAR(50) NOT NULL,
    Reason NVARCHAR(300) NOT NULL,
    PayloadJson NVARCHAR(MAX) NULL,
    SourceDocumentId BIGINT NULL,
    SourceLineId BIGINT NULL,
    ReversalLineId BIGINT NULL,
    ApprovedAtUtc DATETIME2(3) NOT NULL CONSTRAINT DF_SupervisorOverride_ApprovedAt DEFAULT(SYSUTCDATETIME()),
    ConsumedAtUtc DATETIME2(3) NULL,
    ConsumedByUserCode NVARCHAR(50) NULL,
    CreatedAt DATETIME2(3) NOT NULL CONSTRAINT DF_SupervisorOverride_CreatedAt DEFAULT(SYSUTCDATETIME()),
    UpdatedAt DATETIME2(3) NOT NULL CONSTRAINT DF_SupervisorOverride_UpdatedAt DEFAULT(SYSUTCDATETIME()),
    RowVer ROWVERSION NOT NULL
  );

  CREATE INDEX IX_SupervisorOverride_Status
    ON sec.SupervisorOverride(Status, ModuleCode, ActionCode, ApprovedAtUtc DESC);

  CREATE INDEX IX_SupervisorOverride_Source
    ON sec.SupervisorOverride(ModuleCode, ActionCode, SourceDocumentId, SourceLineId);
END
GO

IF COL_LENGTH('pos.WaitTicketLine', 'SupervisorApprovalId') IS NULL
BEGIN
  ALTER TABLE pos.WaitTicketLine
    ADD SupervisorApprovalId BIGINT NULL;
END
GO

IF COL_LENGTH('pos.WaitTicketLine', 'LineMetaJson') IS NULL
BEGIN
  ALTER TABLE pos.WaitTicketLine
    ADD LineMetaJson NVARCHAR(1000) NULL;
END
GO

IF COL_LENGTH('pos.SaleTicketLine', 'SupervisorApprovalId') IS NULL
BEGIN
  ALTER TABLE pos.SaleTicketLine
    ADD SupervisorApprovalId BIGINT NULL;
END
GO

IF COL_LENGTH('pos.SaleTicketLine', 'LineMetaJson') IS NULL
BEGIN
  ALTER TABLE pos.SaleTicketLine
    ADD LineMetaJson NVARCHAR(1000) NULL;
END
GO

IF COL_LENGTH('rest.OrderTicketLine', 'SupervisorApprovalId') IS NULL
BEGIN
  ALTER TABLE rest.OrderTicketLine
    ADD SupervisorApprovalId BIGINT NULL;
END
GO
