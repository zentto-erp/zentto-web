/**
 * master-key.ts — Middleware de autenticación para el backoffice.
 *
 * Acepta DOS mecanismos (en orden de preferencia):
 *   1. X-Backoffice-Token: JWT firmado emitido tras el flujo 2FA (request-otp → verify-otp)
 *   2. X-Master-Key: clave estática (solo para compatibilidad interna / scripts de CI)
 *
 * En producción se recomienda usar siempre el flujo 2FA.
 */
import type { Request, Response, NextFunction } from "express";
import jwt from "jsonwebtoken";

const MASTER_KEY     = process.env.MASTER_API_KEY ?? "";
const SESSION_SECRET = process.env.MASTER_API_KEY ?? "fallback-insecure";

interface BackofficeTokenPayload {
  sub: string;
  role: string;
  jti: string;
  iat: number;
  exp: number;
}

export function requireMasterKey(req: Request, res: Response, next: NextFunction): void {
  // ── 1. Session token JWT (flujo 2FA completado) ─────────────────────────────
  const sessionToken = req.headers["x-backoffice-token"] as string | undefined;

  if (sessionToken) {
    try {
      const payload = jwt.verify(sessionToken, SESSION_SECRET) as BackofficeTokenPayload;
      if (payload.sub === "backoffice" && payload.role === "SYSADMIN") {
        next();
        return;
      }
    } catch {
      // Token inválido o expirado — continuar al siguiente check
    }
    // Token presente pero inválido → no hacer fallback a master key
    res.status(401).json({ error: "invalid_or_expired_session" });
    return;
  }

  // ── 2. Master Key estática (backward compat / scripts internos) ─────────────
  const key = req.headers["x-master-key"] as string | undefined;
  if (MASTER_KEY && key === MASTER_KEY) {
    next();
    return;
  }

  res.status(401).json({ error: "unauthorized" });
}
