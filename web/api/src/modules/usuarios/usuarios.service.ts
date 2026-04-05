import { callSp, query } from "../../db/query.js";
import {
  hashPassword,
  verifyPassword,
  isBcryptHash,
} from "../../auth/password.js";
import type { CompanyAccessClaim } from "../../auth/jwt.js";
import type { UsuarioRecord, UsuarioPermisos, ModuloAcceso } from "./types.js";

export type UserCompanyAccess = CompanyAccessClaim;

function normalizeCountryCode(value: unknown): string {
  const normalized = String(value ?? "").trim().toUpperCase();
  return normalized || "VE";
}

function normalizeTimeZone(value: unknown): string {
  const normalized = String(value ?? "").trim();
  return normalized || "UTC";
}

/**
 * Authenticate user using bcrypt only.
 * Plaintext or legacy ciphered passwords are rejected.
 */
export async function authenticateUsuario(usuario: string, clave: string) {
  const rows = await callSp<UsuarioRecord>(
    "usp_Sec_User_Authenticate",
    { CodUsuario: usuario }
  );

  if (rows.length === 0) return null;
  const record = rows[0];
  const stored = record.Password ?? "";

  if (!isBcryptHash(stored)) return null;

  const authenticated = await verifyPassword(clave, stored);
  return authenticated ? record : null;
}

/**
 * Obtener datos del usuario SIN verificar password.
 * Para uso con zentto-auth (ya autenticado via JWT).
 */
export async function getUsuarioRecord(usuario: string): Promise<UsuarioRecord | null> {
  const rows = await callSp<UsuarioRecord>(
    "usp_Sec_User_Authenticate",
    { CodUsuario: usuario }
  );
  return rows.length > 0 ? rows[0] : null;
}

export async function getUsuarioTipo(codUsuario: string): Promise<{ codUsuario: string; tipo: string | null } | null> {
  const rows = await callSp<{ Cod_Usuario: string; Tipo: string | null }>(
    "usp_Sec_User_GetType",
    { CodUsuario: codUsuario }
  );

  if (rows.length === 0) return null;
  return { codUsuario: rows[0].Cod_Usuario, tipo: rows[0].Tipo };
}

/** Extract permissions from UsuarioRecord */
export function extractPermisos(record: UsuarioRecord): UsuarioPermisos {
  return {
    canUpdate: record.Updates === true,
    canCreate: record.Addnews === true,
    canDelete: record.Deletes === true,
    canChangePrice: record.PrecioMinimo === true,
    canGiveCredit: record.Credito === true,
    canChangePwd: record.Cambiar === true,
    isCreator: record.Creador === true,
  };
}

/** Get module access list for a user from AccesoUsuarios table */
export async function getModulosAcceso(codUsuario: string): Promise<ModuloAcceso[]> {
  const rows = await callSp<{ Modulo: string; Permitido: boolean }>(
    "usp_Sec_User_GetModuleAccess",
    { CodUsuario: codUsuario }
  );
  return rows.map((r) => ({ modulo: r.Modulo, permitido: r.Permitido }));
}

async function listDefaultCompanyAccesses(): Promise<UserCompanyAccess[]> {
  const rows = await callSp<{
    companyId: number;
    companyCode: string;
    companyName: string;
    branchId: number;
    branchCode: string;
    branchName: string;
    countryCode: string;
    timeZone: string;
    isDefault: boolean;
  }>("usp_Sec_User_ListCompanyAccesses_Default");

  return rows.map((row) => ({
    companyId: Number(row.companyId),
    companyCode: String(row.companyCode),
    companyName: String(row.companyName),
    branchId: Number(row.branchId),
    branchCode: String(row.branchCode),
    branchName: String(row.branchName),
    countryCode: normalizeCountryCode(row.countryCode),
    timeZone: normalizeTimeZone(row.timeZone),
    isDefault: Boolean(row.isDefault),
  }));
}

export async function getUserCompanyAccesses(
  codUsuario: string,
  isAdmin: boolean
): Promise<UserCompanyAccess[]> {
  if (isAdmin) {
    return listDefaultCompanyAccesses();
  }

  try {
    const rows = await callSp<{
      companyId: number;
      companyCode: string;
      companyName: string;
      branchId: number;
      branchCode: string;
      branchName: string;
      countryCode: string;
      timeZone: string;
      isDefault: boolean;
    }>(
      "usp_Sec_User_GetCompanyAccesses",
      { CodUsuario: codUsuario }
    );

    const mapped = rows.map((row) => ({
      companyId: Number(row.companyId),
      companyCode: String(row.companyCode),
      companyName: String(row.companyName),
      branchId: Number(row.branchId),
      branchCode: String(row.branchCode),
      branchName: String(row.branchName),
      countryCode: normalizeCountryCode(row.countryCode),
      timeZone: normalizeTimeZone(row.timeZone),
      isDefault: Boolean(row.isDefault),
    }));

    if (mapped.length > 0) return mapped;
  } catch {
    // Tabla no desplegada aun. Se usa fallback.
  }

  const defaults = await listDefaultCompanyAccesses();
  return defaults.slice(0, 1).map((row) => ({ ...row, isDefault: true }));
}

export function resolveActiveCompanyAccess(
  accesses: UserCompanyAccess[],
  companyId?: number,
  branchId?: number
): UserCompanyAccess | null {
  if (!Array.isArray(accesses) || accesses.length === 0) return null;

  if (companyId && branchId) {
    return (
      accesses.find(
        (row) => Number(row.companyId) === Number(companyId) && Number(row.branchId) === Number(branchId)
      ) ?? null
    );
  }

  if (companyId) {
    return accesses.find((row) => Number(row.companyId) === Number(companyId)) ?? null;
  }

  if (branchId) {
    return accesses.find((row) => Number(row.branchId) === Number(branchId)) ?? null;
  }

  return accesses.find((row) => row.isDefault) ?? accesses[0] ?? null;
}

export async function ensureUserDefaultCompanyAccess(codUsuario: string): Promise<void> {
  const normalizedUser = String(codUsuario ?? "").trim();
  if (!normalizedUser) return;

  await callSp("usp_Sec_User_EnsureDefaultCompanyAccess", { CodUsuario: normalizedUser });
}

/** Set module access for a user (upsert) */
export async function setModulosAcceso(
  codUsuario: string,
  modulos: { modulo: string; permitido: boolean }[]
): Promise<void> {
  const modulesJson = JSON.stringify(modulos);
  await callSp("usp_Sec_User_SetModuleAccess", {
    CodUsuario: codUsuario,
    ModulesJson: modulesJson,
  });
}

/** Change own password (requires current password) */
export async function changePassword(
  codUsuario: string,
  currentPassword: string,
  newPassword: string
): Promise<{ success: boolean; message: string }> {
  const user = await authenticateUsuario(codUsuario, currentPassword);
  if (!user) {
    return { success: false, message: "Contraseña actual incorrecta" };
  }
  const bcryptHash = await hashPassword(newPassword);
  await callSp("usp_Sec_User_UpdatePassword", {
    CodUsuario: codUsuario,
    PasswordHash: bcryptHash,
  });
  return { success: true, message: "Contraseña actualizada correctamente" };
}

/** Get avatar data URL for a user.
 * Returns null if the Avatar column doesn't exist yet (migration not yet run). */
export async function getUserAvatar(codUsuario: string): Promise<string | null> {
  try {
    const rows = await callSp<{ Avatar: string | null }>(
      "usp_Sec_User_GetAvatar",
      { CodUsuario: codUsuario }
    );
    return rows[0]?.Avatar ?? null;
  } catch {
    return null;
  }
}

/** Set avatar data URL for a user.
 * Silently skips if the Avatar column doesn't exist yet. */
export async function setUserAvatar(codUsuario: string, dataUrl: string | null): Promise<void> {
  try {
    await callSp("usp_Sec_User_SetAvatar", {
      CodUsuario: codUsuario,
      Avatar: dataUrl,
    });
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : String(err);
    if (!msg.includes("Invalid column name")) throw err;
  }
}

/** Admin resets password for any user (no current password needed) */
export async function resetPassword(
  codUsuario: string,
  newPassword: string
): Promise<{ success: boolean; message: string }> {
  const rows = await callSp<{ Cod_Usuario: string }>(
    "usp_Sec_User_CheckExists",
    { CodUsuario: codUsuario }
  );
  if (rows.length === 0) {
    return { success: false, message: "Usuario no encontrado" };
  }
  const bcryptHash = await hashPassword(newPassword);
  await callSp("usp_Sec_User_UpdatePassword", {
    CodUsuario: codUsuario,
    PasswordHash: bcryptHash,
  });
  return { success: true, message: "Contraseña restablecida correctamente" };
}
