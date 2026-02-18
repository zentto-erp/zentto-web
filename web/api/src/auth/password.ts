import iconv from "iconv-lite";
import bcrypt from "bcryptjs";

export type LegacyCryptoMode = "standard" | "ntilde";

const ANSI_1252 = "windows-1252";
const BCRYPT_ROUNDS = 12;
/** Prefix used to identify bcrypt hashes stored in Password column */
const BCRYPT_PREFIX = "$2a$";

// ─── Modern bcrypt ────────────────────────────────────────────
export async function hashPassword(plain: string): Promise<string> {
  return bcrypt.hash(plain, BCRYPT_ROUNDS);
}

export async function verifyPassword(plain: string, hash: string): Promise<boolean> {
  return bcrypt.compare(plain, hash);
}

export function isBcryptHash(stored: string): boolean {
  return stored.startsWith(BCRYPT_PREFIX) || stored.startsWith("$2b$");
}

// ─── Legacy Caesar cipher (VB6 compat) ───────────────────────
export function encryptLegacy(input: string, mode: LegacyCryptoMode = "standard") {
  return encryt(input, 4, mode);
}

export function decryptLegacy(input: string, mode: LegacyCryptoMode = "standard") {
  return encryt(input, 0, mode);
}

function encryt(input: string, tipo: number, mode: LegacyCryptoMode) {
  if (!input) return "";

  const source = iconv.encode(input, ANSI_1252);
  const target = Buffer.alloc(source.length);

  for (let i = 0; i < source.length; i += 1) {
    let code = source[i];

    if (tipo === 0) {
      if (mode === "ntilde" && code === 210) {
        code -= 1;
      } else {
        code -= 80;
      }
    } else {
      if (mode === "ntilde" && code === 209) {
        code += 1;
      } else {
        code += 80;
      }
    }

    if (code < 0) code = 0;
    if (code > 255) code = code % 256;
    target[i] = code;
  }

  return iconv.decode(target, ANSI_1252);
}
