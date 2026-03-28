-- ============================================================
-- zentto_dev — Patch: columnas faltantes para SPs
-- ============================================================
USE zentto_dev;
GO

IF COL_LENGTH('pos.WaitTicketLine', 'LineMetaJson') IS NULL
  ALTER TABLE pos.WaitTicketLine ADD LineMetaJson NVARCHAR(MAX) NULL;
GO
IF COL_LENGTH('rest.OrderTicketLine', 'SupervisorApprovalId') IS NULL
  ALTER TABLE rest.OrderTicketLine ADD SupervisorApprovalId BIGINT NULL;
GO
IF COL_LENGTH('fin.BankMovement', 'JournalEntryId') IS NULL
  ALTER TABLE fin.BankMovement ADD JournalEntryId BIGINT NULL;
GO
IF COL_LENGTH('inv.Warehouse', 'UpdatedBy') IS NULL
  ALTER TABLE inv.Warehouse ADD UpdatedBy INT NULL;
GO
IF COL_LENGTH('inv.Warehouse', 'CreatedBy') IS NULL
  ALTER TABLE inv.Warehouse ADD CreatedBy INT NULL;
GO
IF COL_LENGTH('inv.ProductLot', 'CreatedBy') IS NULL
  ALTER TABLE inv.ProductLot ADD CreatedBy INT NULL;
GO
IF COL_LENGTH('inv.ProductSerial', 'UnitCost') IS NULL
  ALTER TABLE inv.ProductSerial ADD UnitCost DECIMAL(18,4) NULL;
GO
IF COL_LENGTH('inv.ProductBinStock', 'ReservedQuantity') IS NULL
  ALTER TABLE inv.ProductBinStock ADD ReservedQuantity DECIMAL(18,4) NOT NULL DEFAULT 0;
GO
IF COL_LENGTH('inv.StockMovement', 'ZoneId') IS NULL
  ALTER TABLE inv.StockMovement ADD ZoneId INT NULL;
GO
IF COL_LENGTH('inv.StockMovement', 'BinId') IS NULL
  ALTER TABLE inv.StockMovement ADD BinId INT NULL;
GO
-- logistics IsDeleted
IF OBJECT_ID('logistics.Carrier','U') IS NOT NULL AND COL_LENGTH('logistics.Carrier','IsDeleted') IS NULL
  ALTER TABLE logistics.Carrier ADD IsDeleted BIT NOT NULL DEFAULT 0;
GO
IF OBJECT_ID('logistics.Driver','U') IS NOT NULL AND COL_LENGTH('logistics.Driver','IsDeleted') IS NULL
  ALTER TABLE logistics.Driver ADD IsDeleted BIT NOT NULL DEFAULT 0;
GO
IF OBJECT_ID('logistics.GoodsReceipt','U') IS NOT NULL AND COL_LENGTH('logistics.GoodsReceipt','IsDeleted') IS NULL
  ALTER TABLE logistics.GoodsReceipt ADD IsDeleted BIT NOT NULL DEFAULT 0;
GO
IF OBJECT_ID('logistics.GoodsReturn','U') IS NOT NULL AND COL_LENGTH('logistics.GoodsReturn','IsDeleted') IS NULL
  ALTER TABLE logistics.GoodsReturn ADD IsDeleted BIT NOT NULL DEFAULT 0;
GO
IF OBJECT_ID('logistics.DeliveryNote','U') IS NOT NULL AND COL_LENGTH('logistics.DeliveryNote','IsDeleted') IS NULL
  ALTER TABLE logistics.DeliveryNote ADD IsDeleted BIT NOT NULL DEFAULT 0;
GO
IF OBJECT_ID('logistics.DeliveryNoteLine','U') IS NOT NULL AND COL_LENGTH('logistics.DeliveryNoteLine','IsDeleted') IS NULL
  ALTER TABLE logistics.DeliveryNoteLine ADD IsDeleted BIT NOT NULL DEFAULT 0;
GO
-- cfg.Company tenant fields
IF COL_LENGTH('cfg.Company', 'ProvisionedAt') IS NULL ALTER TABLE cfg.Company ADD ProvisionedAt DATETIME2(0) NULL;
GO
IF COL_LENGTH('cfg.Company', 'TenantSubdomain') IS NULL ALTER TABLE cfg.Company ADD TenantSubdomain NVARCHAR(100) NULL;
GO
IF COL_LENGTH('cfg.Company', 'MaxUsers') IS NULL ALTER TABLE cfg.Company ADD MaxUsers INT NULL;
GO
IF COL_LENGTH('cfg.Company', 'MaxBranches') IS NULL ALTER TABLE cfg.Company ADD MaxBranches INT NULL;
GO
IF COL_LENGTH('cfg.Company', 'Plan') IS NULL ALTER TABLE cfg.Company ADD [Plan] NVARCHAR(50) NULL;
GO
-- crm Campaign/CampaignContact
IF OBJECT_ID('crm.Campaign','U') IS NULL
CREATE TABLE crm.Campaign (
  CampaignId BIGINT IDENTITY(1,1) PRIMARY KEY,
  CompanyId INT NOT NULL,
  CampaignName NVARCHAR(200) NOT NULL,
  CampaignType NVARCHAR(30) NOT NULL DEFAULT 'OUTBOUND',
  [Status] NVARCHAR(20) NOT NULL DEFAULT 'DRAFT',
  StartDate DATE NULL, EndDate DATE NULL,
  ScriptTemplate NVARCHAR(MAX) NULL,
  CreatedAt DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
  UpdatedAt DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
  CreatedByUserId INT NULL, IsDeleted BIT NOT NULL DEFAULT 0
);
GO
IF OBJECT_ID('crm.CampaignContact','U') IS NULL
CREATE TABLE crm.CampaignContact (
  CampaignContactId BIGINT IDENTITY(1,1) PRIMARY KEY,
  CampaignId BIGINT NOT NULL,
  ContactName NVARCHAR(200) NULL, Phone NVARCHAR(40) NULL, Email NVARCHAR(150) NULL,
  [Status] NVARCHAR(20) NOT NULL DEFAULT 'PENDING',
  AssignedToUserId INT NULL, LastAttemptAt DATETIME2(0) NULL,
  AttemptCount INT NOT NULL DEFAULT 0, Notes NVARCHAR(MAX) NULL,
  Outcome NVARCHAR(50) NULL, NextCallAt DATETIME2(0) NULL,
  CreatedAt DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
  CONSTRAINT FK_CampaignContact_Campaign FOREIGN KEY (CampaignId) REFERENCES crm.Campaign(CampaignId)
);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_CampaignContact_Status')
  CREATE INDEX IX_CampaignContact_Status ON crm.CampaignContact (CampaignId, [Status]);
GO

PRINT 'Patch columnas completado';
GO
