import { callSp, callSpOut, sql } from "../../db/query.js";
import { getActiveScope } from "../_shared/scope.js";

export async function listRoles() {
  const scope = getActiveScope();
  return callSp<any>("usp_Sec_Role_List", { CompanyId: scope?.companyId ?? 1 });
}

export async function upsertRole(data: { roleId?: number; roleCode: string; roleName: string; isActive?: boolean }) {
  const scope = getActiveScope();
  const { output } = await callSpOut<never>("usp_Sec_Role_Upsert", {
    CompanyId: scope?.companyId ?? 1,
    RoleId: data.roleId ?? null,
    RoleCode: data.roleCode,
    RoleName: data.roleName,
    IsActive: data.isActive ?? true,
  }, { Resultado: sql.Int, Mensaje: sql.NVarChar(500) });
  return { success: Number(output.Resultado) > 0, message: String(output.Mensaje ?? 'OK'), roleId: Number(output.Resultado) };
}

export async function deleteRole(roleId: number) {
  const { output } = await callSpOut<never>("usp_Sec_Role_Delete", { RoleId: roleId }, { Resultado: sql.Int, Mensaje: sql.NVarChar(500) });
  return { success: Number(output.Resultado) === 1, message: String(output.Mensaje ?? 'OK') };
}

export async function listUserRoles(userId: number) {
  return callSp<any>("usp_Sec_UserRole_List", { UserId: userId });
}

export async function setUserRoles(userId: number, roleIds: number[]) {
  const { output } = await callSpOut<never>("usp_Sec_UserRole_Set", {
    UserId: userId,
    RoleIdsJson: JSON.stringify(roleIds),
  }, { Resultado: sql.Int, Mensaje: sql.NVarChar(500) });
  return { success: Number(output.Resultado) === 1, message: String(output.Mensaje ?? 'OK') };
}

// Plan limits info for UI
export async function getLicenseLimits(companyId?: number) {
  const scope = getActiveScope();
  const cid = companyId ?? scope?.companyId ?? 1;
  const rows = await callSp<any>("usp_Sys_License_GetLimits", { CompanyId: cid });
  return rows[0] ?? null;
}
