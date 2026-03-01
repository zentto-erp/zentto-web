import { query, execute } from "../../db/query.js";
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
  const rows = await query<UsuarioRecord>(
    `SELECT TOP 1
       Cod_Usuario, Password, Nombre, Tipo,
       Updates, Addnews, Deletes, Creador, Cambiar, PrecioMinimo, Credito
     FROM Usuarios
     WHERE Cod_Usuario = @usuario`,
    { usuario }
  );

  if (rows.length === 0) return null;
  const record = rows[0];
  const stored = record.Password ?? "";

  if (!isBcryptHash(stored)) return null;

  const authenticated = await verifyPassword(clave, stored);
  return authenticated ? record : null;
}

export async function getUsuarioTipo(codUsuario: string): Promise<{ codUsuario: string; tipo: string | null } | null> {
  const rows = await query<{ Cod_Usuario: string; Tipo: string | null }>(
    `
    SELECT TOP 1 Cod_Usuario, Tipo
    FROM Usuarios
    WHERE Cod_Usuario = @codUsuario
    `,
    { codUsuario }
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
  const rows = await query<{ Modulo: string; Permitido: boolean }>(
    "SELECT Modulo, Permitido FROM AccesoUsuarios WHERE Cod_Usuario = @cod",
    { cod: codUsuario }
  );
  return rows.map((r) => ({ modulo: r.Modulo, permitido: r.Permitido }));
}

async function listDefaultCompanyAccesses(): Promise<UserCompanyAccess[]> {
  const rows = await query<{
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
    `
    SELECT
      c.CompanyId AS companyId,
      c.CompanyCode AS companyCode,
      ISNULL(NULLIF(c.TradeName, N''), c.LegalName) AS companyName,
      b.BranchId AS branchId,
      b.BranchCode AS branchCode,
      b.BranchName AS branchName,
      UPPER(ISNULL(NULLIF(b.CountryCode, ''), c.FiscalCountryCode)) AS countryCode,
      COALESCE(NULLIF(ct.TimeZoneIana, N''), CASE UPPER(ISNULL(NULLIF(b.CountryCode, ''), c.FiscalCountryCode))
        WHEN 'ES' THEN 'Europe/Madrid'
        WHEN 'VE' THEN 'America/Caracas'
        ELSE 'UTC'
      END) AS timeZone,
      CAST(CASE WHEN c.CompanyCode = N'DEFAULT' AND b.BranchCode = N'MAIN' THEN 1 ELSE 0 END AS bit) AS isDefault
    FROM cfg.Company c
    INNER JOIN cfg.Branch b
      ON b.CompanyId = c.CompanyId
    LEFT JOIN cfg.Country ct
      ON ct.CountryCode = UPPER(ISNULL(NULLIF(b.CountryCode, ''), c.FiscalCountryCode))
     AND ct.IsActive = 1
    WHERE c.IsActive = 1
      AND c.IsDeleted = 0
      AND b.IsActive = 1
      AND b.IsDeleted = 0
    ORDER BY
      CASE WHEN c.CompanyCode = N'DEFAULT' AND b.BranchCode = N'MAIN' THEN 0 ELSE 1 END,
      c.CompanyId,
      b.BranchId
    `
  );

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
    const rows = await query<{
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
      `
      SELECT
        a.CompanyId AS companyId,
        c.CompanyCode AS companyCode,
        ISNULL(NULLIF(c.TradeName, N''), c.LegalName) AS companyName,
        a.BranchId AS branchId,
        b.BranchCode AS branchCode,
        b.BranchName AS branchName,
        UPPER(ISNULL(NULLIF(b.CountryCode, ''), c.FiscalCountryCode)) AS countryCode,
        COALESCE(NULLIF(ct.TimeZoneIana, N''), CASE UPPER(ISNULL(NULLIF(b.CountryCode, ''), c.FiscalCountryCode))
          WHEN 'ES' THEN 'Europe/Madrid'
          WHEN 'VE' THEN 'America/Caracas'
          ELSE 'UTC'
        END) AS timeZone,
        a.IsDefault AS isDefault
      FROM sec.UserCompanyAccess a
      INNER JOIN cfg.Company c
        ON c.CompanyId = a.CompanyId
       AND c.IsActive = 1
       AND c.IsDeleted = 0
      INNER JOIN cfg.Branch b
        ON b.BranchId = a.BranchId
       AND b.CompanyId = a.CompanyId
       AND b.IsActive = 1
       AND b.IsDeleted = 0
      LEFT JOIN cfg.Country ct
        ON ct.CountryCode = UPPER(ISNULL(NULLIF(b.CountryCode, ''), c.FiscalCountryCode))
       AND ct.IsActive = 1
      WHERE UPPER(a.CodUsuario) = UPPER(@codUsuario)
        AND a.IsActive = 1
      ORDER BY
        CASE WHEN a.IsDefault = 1 THEN 0 ELSE 1 END,
        a.CompanyId,
        a.BranchId
      `,
      { codUsuario }
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

  await execute(
    `
    IF OBJECT_ID(N'sec.UserCompanyAccess', N'U') IS NULL
      RETURN;

    DECLARE @companyId INT = (
      SELECT TOP (1) CompanyId
      FROM cfg.Company
      WHERE CompanyCode = N'DEFAULT'
        AND IsActive = 1
        AND IsDeleted = 0
      ORDER BY CompanyId
    );

    IF @companyId IS NULL
      SET @companyId = (
        SELECT TOP (1) CompanyId
        FROM cfg.Company
        WHERE IsActive = 1
          AND IsDeleted = 0
        ORDER BY CompanyId
      );

    DECLARE @branchId INT = (
      SELECT TOP (1) BranchId
      FROM cfg.Branch
      WHERE CompanyId = @companyId
        AND BranchCode = N'MAIN'
        AND IsActive = 1
        AND IsDeleted = 0
      ORDER BY BranchId
    );

    IF @branchId IS NULL
      SET @branchId = (
        SELECT TOP (1) BranchId
        FROM cfg.Branch
        WHERE CompanyId = @companyId
          AND IsActive = 1
          AND IsDeleted = 0
        ORDER BY BranchId
      );

    IF @companyId IS NULL OR @branchId IS NULL
      RETURN;

    MERGE sec.UserCompanyAccess AS tgt
    USING (
      SELECT
        @codUsuario AS CodUsuario,
        @companyId AS CompanyId,
        @branchId AS BranchId
    ) AS src
      ON tgt.CodUsuario = src.CodUsuario
     AND tgt.CompanyId = src.CompanyId
     AND tgt.BranchId = src.BranchId
    WHEN MATCHED THEN
      UPDATE SET
        IsActive = 1,
        UpdatedAt = SYSUTCDATETIME()
    WHEN NOT MATCHED THEN
      INSERT (CodUsuario, CompanyId, BranchId, IsDefault, IsActive)
      VALUES (src.CodUsuario, src.CompanyId, src.BranchId, 1, 1);
    `,
    { codUsuario: normalizedUser }
  );
}

/** Set module access for a user (upsert) */
export async function setModulosAcceso(
  codUsuario: string,
  modulos: { modulo: string; permitido: boolean }[]
): Promise<void> {
  await execute("DELETE FROM AccesoUsuarios WHERE Cod_Usuario = @cod", {
    cod: codUsuario,
  });
  for (const m of modulos) {
    await execute(
      "INSERT INTO AccesoUsuarios (Cod_Usuario, Modulo, Permitido) VALUES (@cod, @modulo, @perm)",
      { cod: codUsuario, modulo: m.modulo, perm: m.permitido ? 1 : 0 }
    );
  }
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
  await execute("UPDATE Usuarios SET Password = @hash WHERE Cod_Usuario = @cod", {
    hash: bcryptHash,
    cod: codUsuario,
  });
  return { success: true, message: "Contraseña actualizada correctamente" };
}

/** Get avatar data URL for a user (reads directly, bypasses SP).
 * Returns null if the Avatar column doesn't exist yet (migration not yet run). */
export async function getUserAvatar(codUsuario: string): Promise<string | null> {
  try {
    const rows = await query<{ Avatar: string | null }>(
      "SELECT TOP 1 Avatar FROM Usuarios WHERE Cod_Usuario = @cod",
      { cod: codUsuario }
    );
    return rows[0]?.Avatar ?? null;
  } catch {
    // Column doesn't exist yet – silently return null until migration is applied
    return null;
  }
}

/** Set avatar data URL for a user (writes directly, bypasses SP).
 * Silently skips if the Avatar column doesn't exist yet. */
export async function setUserAvatar(codUsuario: string, dataUrl: string | null): Promise<void> {
  try {
    await execute(
      "UPDATE Usuarios SET Avatar = @avatar WHERE Cod_Usuario = @cod",
      { avatar: dataUrl, cod: codUsuario }
    );
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : String(err);
    // Re-throw everything except missing-column errors so callers still surface real failures
    if (!msg.includes("Invalid column name")) throw err;
  }
}

/** Admin resets password for any user (no current password needed) */
export async function resetPassword(
  codUsuario: string,
  newPassword: string
): Promise<{ success: boolean; message: string }> {
  const rows = await query<{ Cod_Usuario: string }>(
    "SELECT TOP 1 Cod_Usuario FROM Usuarios WHERE Cod_Usuario = @cod",
    { cod: codUsuario }
  );
  if (rows.length === 0) {
    return { success: false, message: "Usuario no encontrado" };
  }
  const bcryptHash = await hashPassword(newPassword);
  await execute("UPDATE Usuarios SET Password = @hash WHERE Cod_Usuario = @cod", {
    hash: bcryptHash,
    cod: codUsuario,
  });
  return { success: true, message: "Contraseña restablecida correctamente" };
}
