/**
 * JWT verification — Sprint 5 del plan de seguridad auth.
 *
 * Soporte dual:
 *   1. RS256 (preferido) — verificado contra el JWKS público de zentto-auth,
 *      cacheado por jose.createRemoteJWKSet (default 10min cache + 30s coalescing).
 *   2. HS256 (legacy)    — verificado con JWT_SECRET local. Sigue activo durante
 *      la ventana de transición; será deprecado tras la migración completa.
 *
 * El algoritmo se elige inspeccionando el header del JWT antes de verificar.
 *
 * Configuración:
 *   - AUTH_JWKS_URL (opcional): URL del JWKS endpoint de zentto-auth. Si no
 *     se setea, se deriva como ${AUTH_SERVICE_URL}/.well-known/jwks.json.
 *   - JWT_ISSUER (opcional): iss claim esperado. Si se setea, jose lo valida.
 *   - JWT_SECRET (obligatorio): para HS256 legacy.
 */

import jwt from "jsonwebtoken";
import {
  jwtVerify as joseVerify,
  createRemoteJWKSet,
  decodeProtectedHeader,
  type JWTPayload as JoseJWTPayload,
} from "jose";
import { env } from "../config/env.js";

export type CompanyAccessClaim = {
  companyId: number;
  companyCode: string;
  companyName: string;
  branchId: number;
  branchCode: string;
  branchName: string;
  countryCode: string;
  timeZone?: string;
  isDefault?: boolean;
};

export type JwtPayload = {
  sub: string;
  name?: string | null;
  email?: string | null;
  tipo?: string | null;
  isAdmin?: boolean;
  /** Sprint 2 — TokenVersion claim. Si difiere del actual del usuario, refresh debe rechazar. */
  tv?: number;
  permisos?: {
    canUpdate: boolean;
    canCreate: boolean;
    canDelete: boolean;
    canChangePrice: boolean;
    canGiveCredit: boolean;
    canChangePwd: boolean;
    isCreator: boolean;
  };
  modulos?: string[];
  companyId?: number;
  companyCode?: string;
  companyName?: string;
  branchId?: number;
  branchCode?: string;
  branchName?: string;
  countryCode?: string;
  timeZone?: string;
  companyAccesses?: CompanyAccessClaim[];
  /** Roles del usuario: unión de UserApp.Roles + UserRole M:N emitidos por zentto-auth */
  roles?: string[];
};

// ─── JWKS remoto (RS256) ──────────────────────────────────────
const AUTH_SERVICE_URL = process.env.AUTH_SERVICE_URL || "https://auth.zentto.net";
const AUTH_JWKS_URL =
  process.env.AUTH_JWKS_URL || `${AUTH_SERVICE_URL.replace(/\/$/, "")}/.well-known/jwks.json`;
const JWT_ISSUER = process.env.JWT_ISSUER || undefined;

let jwks: ReturnType<typeof createRemoteJWKSet> | null = null;
function getJwks() {
  if (!jwks) {
    jwks = createRemoteJWKSet(new URL(AUTH_JWKS_URL), {
      cooldownDuration: 30_000,    // 30s entre refetches forzados
      cacheMaxAge: 10 * 60_000,    // 10min cache
    });
  }
  return jwks;
}

// ─── Sign (legacy HS256, todavía usado por /auth/login del API) ──
// Tras la migración completa a RS256, el API ya no firma sus propios tokens —
// delega TODO a zentto-auth y solo verifica.
export function signJwt(payload: JwtPayload) {
  return jwt.sign(payload, env.jwt.secret, {
    algorithm: "HS256",
    expiresIn: env.jwt.expires as jwt.SignOptions["expiresIn"],
    ...(JWT_ISSUER && { issuer: JWT_ISSUER }),
  });
}

// ─── Verify dual HS256/RS256 ──────────────────────────────────
//
// Mantiene la firma síncrona de la versión anterior porque el middleware
// requireJwt no es async-friendly en algunos call sites. Por eso usamos
// jsonwebtoken para HS256 (sync) y solo caemos a jose async cuando es RS256.
//
// jose.jwtVerify es async, así que cuando el token es RS256 devolvemos un
// Promise — el middleware ya es async (requireJwt en auth.ts) y await funciona.
export async function verifyJwt(token: string): Promise<JwtPayload & jwt.JwtPayload> {
  let alg: string | undefined;
  try {
    alg = decodeProtectedHeader(token).alg;
  } catch {
    throw new Error("invalid_token_format");
  }

  if (alg === "RS256") {
    const { payload } = await joseVerify(token, getJwks(), {
      ...(JWT_ISSUER && { issuer: JWT_ISSUER }),
      algorithms: ["RS256"],
    });
    return payload as unknown as JwtPayload & jwt.JwtPayload;
  }

  // HS256 — primer intento con el secret primario
  try {
    return jwt.verify(token, env.jwt.secret, {
      algorithms: ["HS256"],
      ...(JWT_ISSUER && { issuer: JWT_ISSUER }),
    }) as JwtPayload & jwt.JwtPayload;
  } catch (primaryErr: any) {
    // ALERT-1: fallback a secret secundario (p.ej. el de zentto-auth durante
    // la ventana de transición). Solo se aplica si:
    //   - el error es de firma inválida (no de token expirado/malformado),
    //   - hay un JWT_SECRET_FALLBACK configurado.
    // Para errores de expiración o de formato, propaga tal cual: no tiene
    // sentido re-verificar con otro secret.
    const fallback = env.jwt.secretFallback;
    const isSignatureError =
      primaryErr?.name === "JsonWebTokenError" &&
      typeof primaryErr?.message === "string" &&
      primaryErr.message.toLowerCase().includes("invalid signature");
    if (!fallback || !isSignatureError) {
      throw primaryErr;
    }
    return jwt.verify(token, fallback, {
      algorithms: ["HS256"],
      ...(JWT_ISSUER && { issuer: JWT_ISSUER }),
    }) as JwtPayload & jwt.JwtPayload;
  }
}
