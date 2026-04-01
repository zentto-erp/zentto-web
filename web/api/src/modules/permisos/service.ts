/**
 * Servicio de Permisos (RBAC) — Permisos Granulares, Restricciones de Precio,
 * Reglas de Aprobacion, Solicitudes de Aprobacion.
 *
 * Todas las operaciones van a traves de stored procedures.
 */

import { callSp, callSpOut, sql } from "../../db/query.js";
import { getActiveScope } from "../_shared/scope.js";

// ─── Helpers ──────────────────────────────────────────────

function scope() {
  const s = getActiveScope();
  if (!s) throw new Error("No active scope");
  return s;
}

function pag(page?: number, limit?: number) {
  const p = Math.max(1, Number(page) || 1);
  const l = Math.min(Math.max(1, Number(limit) || 50), 500);
  return { page: p, limit: l };
}

// ═══════════════════════════════════════════════════════════════
// PERMISOS (Catalogo)
// ═══════════════════════════════════════════════════════════════

export async function listPermissions(moduleCode?: string) {
  return callSp<any>("usp_Sec_Permission_List", {
    ModuleCode: moduleCode?.trim() || null,
  });
}

export async function seedPermissions() {
  const rows = await callSp<any>("usp_Sec_Permission_Seed");
  return { insertedCount: Number(rows[0]?.InsertedCount ?? 0) };
}

// ═══════════════════════════════════════════════════════════════
// PERMISOS POR ROL
// ═══════════════════════════════════════════════════════════════

export async function listRolePermissions(roleId: number) {
  return callSp<any>("usp_Sec_RolePermission_List", { RoleId: roleId });
}

export async function setRolePermission(params: {
  roleId: number;
  permissionId: number;
  branchId?: number;
  isGranted: boolean;
  userId: number;
}) {
  const { output } = await callSpOut(
    "usp_Sec_RolePermission_Set",
    {
      RoleId: params.roleId,
      PermissionId: params.permissionId,
      BranchId: params.branchId ?? null,
      IsGranted: params.isGranted,
      UserId: params.userId,
    },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );

  return {
    success: Number(output.Resultado ?? 0) > 0,
    message: String(output.Mensaje ?? ""),
  };
}

export async function bulkSetRolePermissions(params: {
  roleId: number;
  permissions: Array<{
    permissionId: number;
    branchId?: number;
    isGranted: boolean;
    canCreate?: boolean;
    canRead?: boolean;
    canUpdate?: boolean;
    canDelete?: boolean;
    canExport?: boolean;
    canApprove?: boolean;
  }>;
  userId: number;
}) {
  const { output } = await callSpOut(
    "usp_Sec_RolePermission_BulkSet",
    {
      RoleId: params.roleId,
      PermissionsJson: JSON.stringify(params.permissions),
      UserId: params.userId,
    },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );

  return {
    success: Number(output.Resultado ?? 0) > 0,
    message: String(output.Mensaje ?? ""),
  };
}

// ═══════════════════════════════════════════════════════════════
// PERMISOS DE USUARIO (Overrides)
// ═══════════════════════════════════════════════════════════════

export async function listUserPermissions(userId: number) {
  return callSp<any>("usp_Sec_UserPermission_List", { UserId: userId });
}

export async function overrideUserPermission(params: {
  userId: number;
  permissionId: number;
  branchId?: number;
  isGranted: boolean;
  adminUserId: number;
}) {
  const { output } = await callSpOut(
    "usp_Sec_UserPermission_Override",
    {
      UserId: params.userId,
      PermissionId: params.permissionId,
      BranchId: params.branchId ?? null,
      IsGranted: params.isGranted,
      AdminUserId: params.adminUserId,
    },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );

  return {
    success: Number(output.Resultado ?? 0) > 0,
    message: String(output.Mensaje ?? ""),
  };
}

export async function checkUserPermission(userId: number, permissionCode: string) {
  const rows = await callSp<any>("usp_Sec_UserPermission_Check", {
    UserId: userId,
    PermissionCode: permissionCode.trim(),
  });
  return { hasPermission: Boolean(rows[0]?.HasPermission ?? false) };
}

// ═══════════════════════════════════════════════════════════════
// RESTRICCIONES DE PRECIO
// ═══════════════════════════════════════════════════════════════

export async function listPriceRestrictions() {
  const { companyId } = scope();
  return callSp<any>("usp_Sec_PriceRestriction_List", { CompanyId: companyId });
}

export async function upsertPriceRestriction(params: {
  restrictionId?: number;
  roleId?: number;
  userIdTarget?: number;
  maxDiscountPercent: number;
  minPricePercent: number;
  maxCreditLimit?: number;
  requiresApprovalAbove?: number;
  adminUserId: number;
}) {
  const { companyId } = scope();

  const { output } = await callSpOut(
    "usp_Sec_PriceRestriction_Upsert",
    {
      CompanyId: companyId,
      RestrictionId: params.restrictionId ?? null,
      RoleId: params.roleId ?? null,
      UserId_Target: params.userIdTarget ?? null,
      MaxDiscountPercent: params.maxDiscountPercent,
      MinPricePercent: params.minPricePercent,
      MaxCreditLimit: params.maxCreditLimit ?? null,
      RequiresApprovalAbove: params.requiresApprovalAbove ?? null,
      AdminUserId: params.adminUserId,
    },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );

  return {
    success: Number(output.Resultado ?? 0) > 0,
    message: String(output.Mensaje ?? ""),
  };
}

export async function checkPriceRestriction(userId: number) {
  const { companyId } = scope();
  const rows = await callSp<any>("usp_Sec_PriceRestriction_Check", {
    UserId: userId,
    CompanyId: companyId,
  });
  return rows[0] ?? null;
}

// ═══════════════════════════════════════════════════════════════
// REGLAS DE APROBACION
// ═══════════════════════════════════════════════════════════════

export async function listApprovalRules(moduleCode?: string) {
  const { companyId } = scope();
  return callSp<any>("usp_Sec_ApprovalRule_List", {
    CompanyId: companyId,
    ModuleCode: moduleCode?.trim() || null,
  });
}

export async function upsertApprovalRule(params: {
  approvalRuleId?: number;
  moduleCode: string;
  documentType: string;
  minAmount: number;
  maxAmount?: number;
  requiredRoleId: number;
  approvalLevels: number;
  isActive?: boolean;
  userId: number;
}) {
  const { companyId } = scope();

  const { output } = await callSpOut(
    "usp_Sec_ApprovalRule_Upsert",
    {
      CompanyId: companyId,
      ApprovalRuleId: params.approvalRuleId ?? null,
      ModuleCode: params.moduleCode.trim(),
      DocumentType: params.documentType.trim(),
      MinAmount: params.minAmount,
      MaxAmount: params.maxAmount ?? null,
      RequiredRoleId: params.requiredRoleId,
      ApprovalLevels: params.approvalLevels,
      IsActive: params.isActive ?? true,
      UserId: params.userId,
    },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );

  return {
    success: Number(output.Resultado ?? 0) > 0,
    message: String(output.Mensaje ?? ""),
  };
}

// ═══════════════════════════════════════════════════════════════
// SOLICITUDES DE APROBACION
// ═══════════════════════════════════════════════════════════════

export async function listApprovalRequests(params: {
  status?: string;
  moduleCode?: string;
  page?: number;
  limit?: number;
}) {
  const { companyId } = scope();
  const { page, limit } = pag(params.page, params.limit);

  const { rows, output } = await callSpOut<any>(
    "usp_Sec_ApprovalRequest_List",
    {
      CompanyId: companyId,
      Status: params.status?.trim().toUpperCase() || null,
      ModuleCode: params.moduleCode?.trim() || null,
      Page: page,
      Limit: limit,
    },
    { TotalCount: sql.Int }
  );

  return { rows, total: Number(output.TotalCount ?? 0) };
}

export async function createApprovalRequest(params: {
  documentModule: string;
  documentType: string;
  documentNumber: string;
  documentAmount: number;
  requestedByUserId: number;
}) {
  const { companyId, branchId } = scope();

  const { output } = await callSpOut(
    "usp_Sec_ApprovalRequest_Create",
    {
      CompanyId: companyId,
      BranchId: branchId,
      DocumentModule: params.documentModule.trim(),
      DocumentType: params.documentType.trim(),
      DocumentNumber: params.documentNumber.trim(),
      DocumentAmount: params.documentAmount,
      RequestedByUserId: params.requestedByUserId,
    },
    { Resultado: sql.Int, ApprovalRequestId: sql.Int }
  );

  return {
    success: Number(output.Resultado ?? 0) > 0,
    approvalRequestId: Number(output.ApprovalRequestId ?? 0),
  };
}

export async function actOnApprovalRequest(params: {
  approvalRequestId: number;
  actionByUserId: number;
  action: string;
  comments?: string;
}) {
  const { output } = await callSpOut(
    "usp_Sec_ApprovalRequest_Act",
    {
      ApprovalRequestId: params.approvalRequestId,
      ActionByUserId: params.actionByUserId,
      Action: params.action.trim().toUpperCase(),
      Comments: params.comments?.trim() || null,
    },
    { Resultado: sql.Int, NewStatus: sql.NVarChar(20) }
  );

  return {
    success: Number(output.Resultado ?? 0) > 0,
    newStatus: String(output.NewStatus ?? ""),
  };
}

export async function getApprovalRequest(id: number) {
  const rows = await callSp<any>("usp_Sec_ApprovalRequest_Get", { ApprovalRequestId: id });
  return rows[0] ?? null;
}
