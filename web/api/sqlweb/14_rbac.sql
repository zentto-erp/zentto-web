-- =============================================================================
-- 14_rbac.sql
-- RBAC granular: Permissions, Role/User Permission mapping, Price Restrictions,
--                Approval Rules, Approval Requests, Approval Actions
-- Extiende el schema sec existente (creado en 01_core_foundation.sql)
-- =============================================================================
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

  -- Schema sec ya existe desde 01_core_foundation.sql

  -- =========================================================================
  -- 1. sec.Permission
  -- =========================================================================
  IF OBJECT_ID('sec.Permission', 'U') IS NULL
  BEGIN
    CREATE TABLE sec.Permission(
      PermissionId        BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      PermissionCode      NVARCHAR(60) NOT NULL,
      ModuleCode          NVARCHAR(30) NOT NULL,
      ActionCode          NVARCHAR(20) NOT NULL,
      Description         NVARCHAR(200) NULL,
      IsActive            BIT NOT NULL CONSTRAINT DF_sec_Permission_IsActive DEFAULT(1),
      CreatedAt           DATETIME2(0) NOT NULL CONSTRAINT DF_sec_Permission_CreatedAt DEFAULT(SYSUTCDATETIME()),
      UpdatedAt           DATETIME2(0) NOT NULL CONSTRAINT DF_sec_Permission_UpdatedAt DEFAULT(SYSUTCDATETIME()),
      CreatedByUserId     INT NULL,
      UpdatedByUserId     INT NULL,
      IsDeleted           BIT NOT NULL CONSTRAINT DF_sec_Permission_IsDeleted DEFAULT(0),
      DeletedAt           DATETIME2(0) NULL,
      DeletedByUserId     INT NULL,
      RowVer              ROWVERSION NOT NULL,
      CONSTRAINT UQ_sec_Permission_Code UNIQUE (PermissionCode),
      CONSTRAINT CK_sec_Permission_Action CHECK (ActionCode IN ('VIEW','CREATE','EDIT','DELETE','VOID','APPROVE','EXPORT','PRINT')),
      CONSTRAINT FK_sec_Permission_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
      CONSTRAINT FK_sec_Permission_UpdatedBy FOREIGN KEY (UpdatedByUserId) REFERENCES sec.[User](UserId),
      CONSTRAINT FK_sec_Permission_DeletedBy FOREIGN KEY (DeletedByUserId) REFERENCES sec.[User](UserId)
    );
  END;

  -- =========================================================================
  -- 2. sec.RolePermission
  -- =========================================================================
  IF OBJECT_ID('sec.RolePermission', 'U') IS NULL
  BEGIN
    CREATE TABLE sec.RolePermission(
      RolePermissionId    BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      RoleId              INT NOT NULL,
      PermissionId        BIGINT NOT NULL,
      BranchId            INT NULL,
      IsGranted           BIT NOT NULL CONSTRAINT DF_sec_RolePerm_IsGranted DEFAULT(1),
      CreatedAt           DATETIME2(0) NOT NULL CONSTRAINT DF_sec_RolePerm_CreatedAt DEFAULT(SYSUTCDATETIME()),
      UpdatedAt           DATETIME2(0) NOT NULL CONSTRAINT DF_sec_RolePerm_UpdatedAt DEFAULT(SYSUTCDATETIME()),
      CreatedByUserId     INT NULL,
      UpdatedByUserId     INT NULL,
      IsDeleted           BIT NOT NULL CONSTRAINT DF_sec_RolePerm_IsDeleted DEFAULT(0),
      DeletedAt           DATETIME2(0) NULL,
      DeletedByUserId     INT NULL,
      RowVer              ROWVERSION NOT NULL,
      CONSTRAINT UQ_sec_RolePerm UNIQUE (RoleId, PermissionId, BranchId),
      CONSTRAINT FK_sec_RolePerm_Role FOREIGN KEY (RoleId) REFERENCES sec.Role(RoleId),
      CONSTRAINT FK_sec_RolePerm_Permission FOREIGN KEY (PermissionId) REFERENCES sec.Permission(PermissionId),
      CONSTRAINT FK_sec_RolePerm_Branch FOREIGN KEY (BranchId) REFERENCES cfg.Branch(BranchId),
      CONSTRAINT FK_sec_RolePerm_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
      CONSTRAINT FK_sec_RolePerm_UpdatedBy FOREIGN KEY (UpdatedByUserId) REFERENCES sec.[User](UserId),
      CONSTRAINT FK_sec_RolePerm_DeletedBy FOREIGN KEY (DeletedByUserId) REFERENCES sec.[User](UserId)
    );
  END;

  -- =========================================================================
  -- 3. sec.UserPermissionOverride
  -- =========================================================================
  IF OBJECT_ID('sec.UserPermissionOverride', 'U') IS NULL
  BEGIN
    CREATE TABLE sec.UserPermissionOverride(
      OverrideId          BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      UserId              INT NOT NULL,
      PermissionId        BIGINT NOT NULL,
      BranchId            INT NULL,
      IsGranted           BIT NOT NULL CONSTRAINT DF_sec_UserPermOvr_IsGranted DEFAULT(1),
      CreatedAt           DATETIME2(0) NOT NULL CONSTRAINT DF_sec_UserPermOvr_CreatedAt DEFAULT(SYSUTCDATETIME()),
      UpdatedAt           DATETIME2(0) NOT NULL CONSTRAINT DF_sec_UserPermOvr_UpdatedAt DEFAULT(SYSUTCDATETIME()),
      CreatedByUserId     INT NULL,
      UpdatedByUserId     INT NULL,
      IsDeleted           BIT NOT NULL CONSTRAINT DF_sec_UserPermOvr_IsDeleted DEFAULT(0),
      DeletedAt           DATETIME2(0) NULL,
      DeletedByUserId     INT NULL,
      RowVer              ROWVERSION NOT NULL,
      CONSTRAINT UQ_sec_UserPermOvr UNIQUE (UserId, PermissionId, BranchId),
      CONSTRAINT FK_sec_UserPermOvr_User FOREIGN KEY (UserId) REFERENCES sec.[User](UserId),
      CONSTRAINT FK_sec_UserPermOvr_Permission FOREIGN KEY (PermissionId) REFERENCES sec.Permission(PermissionId),
      CONSTRAINT FK_sec_UserPermOvr_Branch FOREIGN KEY (BranchId) REFERENCES cfg.Branch(BranchId),
      CONSTRAINT FK_sec_UserPermOvr_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
      CONSTRAINT FK_sec_UserPermOvr_UpdatedBy FOREIGN KEY (UpdatedByUserId) REFERENCES sec.[User](UserId),
      CONSTRAINT FK_sec_UserPermOvr_DeletedBy FOREIGN KEY (DeletedByUserId) REFERENCES sec.[User](UserId)
    );
  END;

  -- =========================================================================
  -- 4. sec.PriceRestriction
  -- =========================================================================
  IF OBJECT_ID('sec.PriceRestriction', 'U') IS NULL
  BEGIN
    CREATE TABLE sec.PriceRestriction(
      RestrictionId       BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      CompanyId           INT NOT NULL,
      RoleId              INT NULL,
      UserId              INT NULL,
      MaxDiscountPercent  DECIMAL(9,4) NOT NULL CONSTRAINT DF_sec_PriceRestr_MaxDisc DEFAULT(100),
      MinPricePercent     DECIMAL(9,4) NOT NULL CONSTRAINT DF_sec_PriceRestr_MinPrice DEFAULT(0),
      MaxCreditLimit      DECIMAL(18,2) NULL,
      RequiresApprovalAbove DECIMAL(18,2) NULL,
      CreatedAt           DATETIME2(0) NOT NULL CONSTRAINT DF_sec_PriceRestr_CreatedAt DEFAULT(SYSUTCDATETIME()),
      UpdatedAt           DATETIME2(0) NOT NULL CONSTRAINT DF_sec_PriceRestr_UpdatedAt DEFAULT(SYSUTCDATETIME()),
      CreatedByUserId     INT NULL,
      UpdatedByUserId     INT NULL,
      IsDeleted           BIT NOT NULL CONSTRAINT DF_sec_PriceRestr_IsDeleted DEFAULT(0),
      DeletedAt           DATETIME2(0) NULL,
      DeletedByUserId     INT NULL,
      RowVer              ROWVERSION NOT NULL,
      CONSTRAINT FK_sec_PriceRestr_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId),
      CONSTRAINT FK_sec_PriceRestr_Role FOREIGN KEY (RoleId) REFERENCES sec.Role(RoleId),
      CONSTRAINT FK_sec_PriceRestr_User FOREIGN KEY (UserId) REFERENCES sec.[User](UserId),
      CONSTRAINT FK_sec_PriceRestr_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
      CONSTRAINT FK_sec_PriceRestr_UpdatedBy FOREIGN KEY (UpdatedByUserId) REFERENCES sec.[User](UserId),
      CONSTRAINT FK_sec_PriceRestr_DeletedBy FOREIGN KEY (DeletedByUserId) REFERENCES sec.[User](UserId)
    );
  END;

  -- =========================================================================
  -- 5. sec.ApprovalRule
  -- =========================================================================
  IF OBJECT_ID('sec.ApprovalRule', 'U') IS NULL
  BEGIN
    CREATE TABLE sec.ApprovalRule(
      ApprovalRuleId      BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      CompanyId           INT NOT NULL,
      ModuleCode          NVARCHAR(30) NOT NULL,
      DocumentType        NVARCHAR(30) NOT NULL,
      MinAmount           DECIMAL(18,2) NOT NULL CONSTRAINT DF_sec_ApprRule_MinAmt DEFAULT(0),
      MaxAmount           DECIMAL(18,2) NULL,
      RequiredRoleId      INT NOT NULL,
      ApprovalLevels      INT NOT NULL CONSTRAINT DF_sec_ApprRule_Levels DEFAULT(1),
      IsActive            BIT NOT NULL CONSTRAINT DF_sec_ApprRule_IsActive DEFAULT(1),
      CreatedAt           DATETIME2(0) NOT NULL CONSTRAINT DF_sec_ApprRule_CreatedAt DEFAULT(SYSUTCDATETIME()),
      UpdatedAt           DATETIME2(0) NOT NULL CONSTRAINT DF_sec_ApprRule_UpdatedAt DEFAULT(SYSUTCDATETIME()),
      CreatedByUserId     INT NULL,
      UpdatedByUserId     INT NULL,
      IsDeleted           BIT NOT NULL CONSTRAINT DF_sec_ApprRule_IsDeleted DEFAULT(0),
      DeletedAt           DATETIME2(0) NULL,
      DeletedByUserId     INT NULL,
      RowVer              ROWVERSION NOT NULL,
      CONSTRAINT UQ_sec_ApprRule UNIQUE (CompanyId, ModuleCode, DocumentType, MinAmount),
      CONSTRAINT FK_sec_ApprRule_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId),
      CONSTRAINT FK_sec_ApprRule_Role FOREIGN KEY (RequiredRoleId) REFERENCES sec.Role(RoleId),
      CONSTRAINT FK_sec_ApprRule_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
      CONSTRAINT FK_sec_ApprRule_UpdatedBy FOREIGN KEY (UpdatedByUserId) REFERENCES sec.[User](UserId),
      CONSTRAINT FK_sec_ApprRule_DeletedBy FOREIGN KEY (DeletedByUserId) REFERENCES sec.[User](UserId)
    );
  END;

  -- =========================================================================
  -- 6. sec.ApprovalRequest
  -- =========================================================================
  IF OBJECT_ID('sec.ApprovalRequest', 'U') IS NULL
  BEGIN
    CREATE TABLE sec.ApprovalRequest(
      ApprovalRequestId   BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      CompanyId           INT NOT NULL,
      BranchId            INT NOT NULL,
      ApprovalRuleId      BIGINT NOT NULL,
      RequestedByUserId   INT NOT NULL,
      DocumentModule      NVARCHAR(30) NOT NULL,
      DocumentType        NVARCHAR(30) NOT NULL,
      DocumentNumber      NVARCHAR(60) NOT NULL,
      DocumentAmount      DECIMAL(18,2) NOT NULL CONSTRAINT DF_sec_ApprReq_Amount DEFAULT(0),
      CurrentLevel        INT NOT NULL CONSTRAINT DF_sec_ApprReq_Level DEFAULT(1),
      Status              NVARCHAR(12) NOT NULL CONSTRAINT DF_sec_ApprReq_Status DEFAULT('PENDING'),
      Notes               NVARCHAR(500) NULL,
      CreatedAt           DATETIME2(0) NOT NULL CONSTRAINT DF_sec_ApprReq_CreatedAt DEFAULT(SYSUTCDATETIME()),
      UpdatedAt           DATETIME2(0) NOT NULL CONSTRAINT DF_sec_ApprReq_UpdatedAt DEFAULT(SYSUTCDATETIME()),
      CreatedByUserId     INT NULL,
      UpdatedByUserId     INT NULL,
      IsDeleted           BIT NOT NULL CONSTRAINT DF_sec_ApprReq_IsDeleted DEFAULT(0),
      DeletedAt           DATETIME2(0) NULL,
      DeletedByUserId     INT NULL,
      RowVer              ROWVERSION NOT NULL,
      CONSTRAINT CK_sec_ApprReq_Status CHECK (Status IN ('PENDING','APPROVED','REJECTED','CANCELLED')),
      CONSTRAINT FK_sec_ApprReq_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId),
      CONSTRAINT FK_sec_ApprReq_Branch FOREIGN KEY (BranchId) REFERENCES cfg.Branch(BranchId),
      CONSTRAINT FK_sec_ApprReq_Rule FOREIGN KEY (ApprovalRuleId) REFERENCES sec.ApprovalRule(ApprovalRuleId),
      CONSTRAINT FK_sec_ApprReq_RequestedBy FOREIGN KEY (RequestedByUserId) REFERENCES sec.[User](UserId),
      CONSTRAINT FK_sec_ApprReq_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
      CONSTRAINT FK_sec_ApprReq_UpdatedBy FOREIGN KEY (UpdatedByUserId) REFERENCES sec.[User](UserId),
      CONSTRAINT FK_sec_ApprReq_DeletedBy FOREIGN KEY (DeletedByUserId) REFERENCES sec.[User](UserId)
    );

    CREATE INDEX IX_sec_ApprReq_Status
      ON sec.ApprovalRequest (CompanyId, Status, DocumentModule);
  END;

  -- =========================================================================
  -- 7. sec.ApprovalAction
  -- =========================================================================
  IF OBJECT_ID('sec.ApprovalAction', 'U') IS NULL
  BEGIN
    CREATE TABLE sec.ApprovalAction(
      ActionId            BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      ApprovalRequestId   BIGINT NOT NULL,
      [Level]             INT NOT NULL,
      ActionByUserId      INT NOT NULL,
      [Action]            NVARCHAR(10) NOT NULL,
      Comments            NVARCHAR(500) NULL,
      CreatedAt           DATETIME2(0) NOT NULL CONSTRAINT DF_sec_ApprAction_CreatedAt DEFAULT(SYSUTCDATETIME()),
      CONSTRAINT CK_sec_ApprAction_Action CHECK ([Action] IN ('APPROVE','REJECT')),
      CONSTRAINT FK_sec_ApprAction_Request FOREIGN KEY (ApprovalRequestId) REFERENCES sec.ApprovalRequest(ApprovalRequestId),
      CONSTRAINT FK_sec_ApprAction_ActionBy FOREIGN KEY (ActionByUserId) REFERENCES sec.[User](UserId)
    );
  END;

  COMMIT TRAN;
  PRINT '[14_rbac] Permisos RBAC granulares creados correctamente.';
END TRY
BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRAN;
  PRINT '[14_rbac] ERROR: ' + ERROR_MESSAGE();
  THROW;
END CATCH;
GO
