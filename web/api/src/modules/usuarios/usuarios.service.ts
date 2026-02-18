import { query, execute } from "../../db/query.js";
import {
  decryptLegacy,
  encryptLegacy,
  hashPassword,
  verifyPassword,
  isBcryptHash,
} from "../../auth/password.js";
import type { UsuarioRecord, UsuarioPermisos, ModuloAcceso } from "./types.js";

/**
 * Authenticate user — supports bcrypt, legacy cipher, and plaintext.
 * If password matches with legacy/plain, it auto-upgrades to bcrypt.
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

  let authenticated = false;

  // 1) Try bcrypt first (modern hash)
  if (isBcryptHash(stored)) {
    authenticated = await verifyPassword(clave, stored);
  } else {
    // 2) Legacy: plaintext or Caesar cipher
    const encrypted = encryptLegacy(clave);
    const decrypted = decryptLegacy(stored);
    authenticated =
      stored === clave || stored === encrypted || decrypted === clave;

    // Auto-upgrade to bcrypt on successful legacy login
    if (authenticated) {
      try {
        const bcryptHash = await hashPassword(clave);
        await execute(
          "UPDATE Usuarios SET Password = @hash WHERE Cod_Usuario = @cod",
          { hash: bcryptHash, cod: record.Cod_Usuario }
        );
      } catch {
        // Non-blocking: if upgrade fails, user can still log in
      }
    }
  }

  return authenticated ? record : null;
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

/** Set module access for a user (upsert) */
export async function setModulosAcceso(
  codUsuario: string,
  modulos: { modulo: string; permitido: boolean }[]
): Promise<void> {
  // Delete existing access rows for this user
  await execute("DELETE FROM AccesoUsuarios WHERE Cod_Usuario = @cod", {
    cod: codUsuario,
  });
  // Insert new access rows
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
  // Re-authenticate with current password
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

/** Admin resets password for any user (no current password needed) */
export async function resetPassword(
  codUsuario: string,
  newPassword: string
): Promise<{ success: boolean; message: string }> {
  // Verify user exists
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
