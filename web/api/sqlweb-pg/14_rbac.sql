-- ============================================================
-- Zentto PostgreSQL - 14_rbac.sql
-- Schema: sec (extension — Control de Acceso Basado en Roles)
-- Tablas: Permission, RolePermission, UserPermissionOverride,
--         PriceRestriction, ApprovalRule, ApprovalRequest,
--         ApprovalAction
-- ============================================================

BEGIN;

-- sec schema already exists from 01_core_foundation.sql

-- ============================================================
-- 1. sec."Permission"  (Permisos del sistema)
-- ============================================================
CREATE TABLE IF NOT EXISTS sec."Permission"(
  "PermissionId"          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "PermissionCode"        VARCHAR(80) NOT NULL,
  "PermissionName"        VARCHAR(200) NOT NULL,
  "Module"                VARCHAR(40) NOT NULL,
  "Category"              VARCHAR(40) NULL,
  "Description"           VARCHAR(500) NULL,
  "IsSystem"              BOOLEAN NOT NULL DEFAULT FALSE,
  "IsActive"              BOOLEAN NOT NULL DEFAULT TRUE,
  "CreatedAt"             TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"             TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId"       INT NULL,
  "UpdatedByUserId"       INT NULL,
  "IsDeleted"             BOOLEAN NOT NULL DEFAULT FALSE,
  "DeletedAt"             TIMESTAMP NULL,
  "DeletedByUserId"       INT NULL,
  CONSTRAINT "UQ_sec_Permission_Code" UNIQUE ("PermissionCode"),
  CONSTRAINT "FK_sec_Permission_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_sec_Permission_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_sec_Permission_DeletedBy" FOREIGN KEY ("DeletedByUserId") REFERENCES sec."User"("UserId")
);

CREATE INDEX IF NOT EXISTS "IX_sec_Permission_Module"
  ON sec."Permission" ("Module", "IsDeleted", "IsActive");

-- ============================================================
-- 2. sec."RolePermission"  (Permisos por rol)
-- ============================================================
CREATE TABLE IF NOT EXISTS sec."RolePermission"(
  "RolePermissionId"      BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "RoleId"                INT NOT NULL,
  "PermissionId"          BIGINT NOT NULL,
  "CanCreate"             BOOLEAN NOT NULL DEFAULT FALSE,
  "CanRead"               BOOLEAN NOT NULL DEFAULT TRUE,
  "CanUpdate"             BOOLEAN NOT NULL DEFAULT FALSE,
  "CanDelete"             BOOLEAN NOT NULL DEFAULT FALSE,
  "CanExport"             BOOLEAN NOT NULL DEFAULT FALSE,
  "CanApprove"            BOOLEAN NOT NULL DEFAULT FALSE,
  "CreatedAt"             TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"             TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId"       INT NULL,
  "UpdatedByUserId"       INT NULL,
  CONSTRAINT "UQ_sec_RolePermission" UNIQUE ("RoleId", "PermissionId"),
  CONSTRAINT "FK_sec_RolePermission_Role" FOREIGN KEY ("RoleId") REFERENCES sec."Role"("RoleId"),
  CONSTRAINT "FK_sec_RolePermission_Permission" FOREIGN KEY ("PermissionId") REFERENCES sec."Permission"("PermissionId"),
  CONSTRAINT "FK_sec_RolePermission_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_sec_RolePermission_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId")
);

CREATE INDEX IF NOT EXISTS "IX_sec_RolePermission_Role"
  ON sec."RolePermission" ("RoleId");

CREATE INDEX IF NOT EXISTS "IX_sec_RolePermission_Permission"
  ON sec."RolePermission" ("PermissionId");

-- ============================================================
-- 3. sec."UserPermissionOverride"  (Sobreescritura de permisos por usuario)
-- ============================================================
CREATE TABLE IF NOT EXISTS sec."UserPermissionOverride"(
  "UserPermissionOverrideId" BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "UserId"                INT NOT NULL,
  "PermissionId"          BIGINT NOT NULL,
  "OverrideType"          VARCHAR(10) NOT NULL DEFAULT 'GRANT',
  "CanCreate"             BOOLEAN NULL,
  "CanRead"               BOOLEAN NULL,
  "CanUpdate"             BOOLEAN NULL,
  "CanDelete"             BOOLEAN NULL,
  "CanExport"             BOOLEAN NULL,
  "CanApprove"            BOOLEAN NULL,
  "ExpiresAt"             TIMESTAMP NULL,
  "Reason"                VARCHAR(500) NULL,
  "CreatedAt"             TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"             TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId"       INT NULL,
  "UpdatedByUserId"       INT NULL,
  "IsDeleted"             BOOLEAN NOT NULL DEFAULT FALSE,
  "DeletedAt"             TIMESTAMP NULL,
  "DeletedByUserId"       INT NULL,
  CONSTRAINT "CK_sec_UPOverride_Type" CHECK ("OverrideType" IN ('GRANT', 'DENY')),
  CONSTRAINT "UQ_sec_UserPermOverride" UNIQUE ("UserId", "PermissionId"),
  CONSTRAINT "FK_sec_UPOverride_User" FOREIGN KEY ("UserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_sec_UPOverride_Permission" FOREIGN KEY ("PermissionId") REFERENCES sec."Permission"("PermissionId"),
  CONSTRAINT "FK_sec_UPOverride_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_sec_UPOverride_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_sec_UPOverride_DeletedBy" FOREIGN KEY ("DeletedByUserId") REFERENCES sec."User"("UserId")
);

CREATE INDEX IF NOT EXISTS "IX_sec_UPOverride_User"
  ON sec."UserPermissionOverride" ("UserId")
  WHERE "IsDeleted" = FALSE;

-- ============================================================
-- 4. sec."PriceRestriction"  (Restricciones de precios por rol/usuario)
-- ============================================================
CREATE TABLE IF NOT EXISTS sec."PriceRestriction"(
  "PriceRestrictionId"    BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"             INT NOT NULL,
  "RoleId"                INT NULL,
  "UserId"                INT NULL,
  "MaxDiscountPercent"    DECIMAL(5,2) NOT NULL DEFAULT 0,
  "MinMarginPercent"      DECIMAL(5,2) NULL,
  "MaxCreditAmount"       DECIMAL(18,2) NULL,
  "CurrencyCode"          CHAR(3) NULL,
  "CanOverridePrice"      BOOLEAN NOT NULL DEFAULT FALSE,
  "CanGiveFreeItems"      BOOLEAN NOT NULL DEFAULT FALSE,
  "RequiresApprovalAbove" DECIMAL(18,2) NULL,
  "IsActive"              BOOLEAN NOT NULL DEFAULT TRUE,
  "CreatedAt"             TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"             TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId"       INT NULL,
  "UpdatedByUserId"       INT NULL,
  "IsDeleted"             BOOLEAN NOT NULL DEFAULT FALSE,
  "DeletedAt"             TIMESTAMP NULL,
  "DeletedByUserId"       INT NULL,
  CONSTRAINT "FK_sec_PriceRestr_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId"),
  CONSTRAINT "FK_sec_PriceRestr_Role" FOREIGN KEY ("RoleId") REFERENCES sec."Role"("RoleId"),
  CONSTRAINT "FK_sec_PriceRestr_User" FOREIGN KEY ("UserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_sec_PriceRestr_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_sec_PriceRestr_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_sec_PriceRestr_DeletedBy" FOREIGN KEY ("DeletedByUserId") REFERENCES sec."User"("UserId")
);

CREATE INDEX IF NOT EXISTS "IX_sec_PriceRestr_Role"
  ON sec."PriceRestriction" ("RoleId")
  WHERE "RoleId" IS NOT NULL AND "IsDeleted" = FALSE;

CREATE INDEX IF NOT EXISTS "IX_sec_PriceRestr_User"
  ON sec."PriceRestriction" ("UserId")
  WHERE "UserId" IS NOT NULL AND "IsDeleted" = FALSE;

-- ============================================================
-- 5. sec."ApprovalRule"  (Reglas de aprobacion)
-- ============================================================
CREATE TABLE IF NOT EXISTS sec."ApprovalRule"(
  "ApprovalRuleId"        BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"             INT NOT NULL,
  "RuleCode"              VARCHAR(30) NOT NULL,
  "RuleName"              VARCHAR(200) NOT NULL,
  "DocumentType"          VARCHAR(30) NOT NULL,
  "Condition"             VARCHAR(30) NOT NULL DEFAULT 'AMOUNT_ABOVE',
  "ThresholdAmount"       DECIMAL(18,2) NULL,
  "CurrencyCode"          CHAR(3) NULL,
  "ApproverRoleId"        INT NULL,
  "ApproverUserId"        INT NULL,
  "RequiredApprovals"     INT NOT NULL DEFAULT 1,
  "AutoApproveBelow"      DECIMAL(18,2) NULL,
  "EscalateAfterHours"    INT NULL,
  "EscalateToUserId"      INT NULL,
  "IsActive"              BOOLEAN NOT NULL DEFAULT TRUE,
  "CreatedAt"             TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"             TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId"       INT NULL,
  "UpdatedByUserId"       INT NULL,
  "IsDeleted"             BOOLEAN NOT NULL DEFAULT FALSE,
  "DeletedAt"             TIMESTAMP NULL,
  "DeletedByUserId"       INT NULL,
  CONSTRAINT "CK_sec_ApprovalRule_Condition" CHECK ("Condition" IN ('AMOUNT_ABOVE', 'DISCOUNT_ABOVE', 'CREDIT_LIMIT', 'ALWAYS', 'CUSTOM')),
  CONSTRAINT "UQ_sec_ApprovalRule_Code" UNIQUE ("CompanyId", "RuleCode"),
  CONSTRAINT "FK_sec_ApprovalRule_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId"),
  CONSTRAINT "FK_sec_ApprovalRule_ApproverRole" FOREIGN KEY ("ApproverRoleId") REFERENCES sec."Role"("RoleId"),
  CONSTRAINT "FK_sec_ApprovalRule_ApproverUser" FOREIGN KEY ("ApproverUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_sec_ApprovalRule_EscalateTo" FOREIGN KEY ("EscalateToUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_sec_ApprovalRule_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_sec_ApprovalRule_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_sec_ApprovalRule_DeletedBy" FOREIGN KEY ("DeletedByUserId") REFERENCES sec."User"("UserId")
);

CREATE INDEX IF NOT EXISTS "IX_sec_ApprovalRule_Company"
  ON sec."ApprovalRule" ("CompanyId", "DocumentType", "IsActive")
  WHERE "IsDeleted" = FALSE;

-- ============================================================
-- 6. sec."ApprovalRequest"  (Solicitudes de aprobacion)
-- ============================================================
CREATE TABLE IF NOT EXISTS sec."ApprovalRequest"(
  "ApprovalRequestId"     BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"             INT NOT NULL,
  "ApprovalRuleId"        BIGINT NOT NULL,
  "DocumentType"          VARCHAR(30) NOT NULL,
  "DocumentId"            BIGINT NOT NULL,
  "DocumentNumber"        VARCHAR(60) NULL,
  "RequestedAmount"       DECIMAL(18,2) NULL,
  "CurrencyCode"          CHAR(3) NULL,
  "Status"                VARCHAR(20) NOT NULL DEFAULT 'PENDING',
  "RequestedByUserId"     INT NOT NULL,
  "RequestedAt"           TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "ResolvedAt"            TIMESTAMP NULL,
  "Notes"                 VARCHAR(500) NULL,
  "CreatedAt"             TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"             TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  CONSTRAINT "CK_sec_ApprovalRequest_Status" CHECK ("Status" IN ('PENDING', 'APPROVED', 'REJECTED', 'ESCALATED', 'CANCELLED', 'EXPIRED')),
  CONSTRAINT "FK_sec_ApprovalReq_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId"),
  CONSTRAINT "FK_sec_ApprovalReq_Rule" FOREIGN KEY ("ApprovalRuleId") REFERENCES sec."ApprovalRule"("ApprovalRuleId"),
  CONSTRAINT "FK_sec_ApprovalReq_RequestedBy" FOREIGN KEY ("RequestedByUserId") REFERENCES sec."User"("UserId")
);

CREATE INDEX IF NOT EXISTS "IX_sec_ApprovalReq_Status"
  ON sec."ApprovalRequest" ("CompanyId", "Status")
  WHERE "Status" = 'PENDING';

CREATE INDEX IF NOT EXISTS "IX_sec_ApprovalReq_Document"
  ON sec."ApprovalRequest" ("DocumentType", "DocumentId");

CREATE INDEX IF NOT EXISTS "IX_sec_ApprovalReq_RequestedBy"
  ON sec."ApprovalRequest" ("RequestedByUserId", "Status");

-- ============================================================
-- 7. sec."ApprovalAction"  (Acciones de aprobacion/rechazo)
-- ============================================================
CREATE TABLE IF NOT EXISTS sec."ApprovalAction"(
  "ApprovalActionId"      BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "ApprovalRequestId"     BIGINT NOT NULL,
  "ActionType"            VARCHAR(20) NOT NULL,
  "ActionByUserId"        INT NOT NULL,
  "ActionAt"              TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "Comments"              VARCHAR(500) NULL,
  CONSTRAINT "CK_sec_ApprovalAction_Type" CHECK ("ActionType" IN ('APPROVE', 'REJECT', 'ESCALATE', 'COMMENT', 'CANCEL')),
  CONSTRAINT "FK_sec_ApprovalAction_Request" FOREIGN KEY ("ApprovalRequestId") REFERENCES sec."ApprovalRequest"("ApprovalRequestId"),
  CONSTRAINT "FK_sec_ApprovalAction_ActionBy" FOREIGN KEY ("ActionByUserId") REFERENCES sec."User"("UserId")
);

CREATE INDEX IF NOT EXISTS "IX_sec_ApprovalAction_Request"
  ON sec."ApprovalAction" ("ApprovalRequestId", "ActionAt");

CREATE INDEX IF NOT EXISTS "IX_sec_ApprovalAction_User"
  ON sec."ApprovalAction" ("ActionByUserId", "ActionAt" DESC);

COMMIT;
