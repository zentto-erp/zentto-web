/**
 * set-password.routes.ts — Endpoint público para que el owner de un tenant
 * recién creado fije su contraseña usando un magic-link enviado por email.
 *
 * Flujo:
 *   1. Welcome email contiene URL: <subdomain>.zentto.net/auth/set-password?token=xxx
 *   2. Frontend muestra form de password
 *   3. Frontend POST /v1/auth/set-password { token, newPassword }
 *   4. Backend valida token (usp_sec_password_reset_token_consume), cambia password
 *      en la BD del tenant via usp_Sec_User_ChangePassword
 */
import { Router, type Request, type Response } from "express";
import { hashPassword } from "../../auth/password.js";
import { callSp } from "../../db/query.js";
import { consumePasswordResetToken } from "../_shared/password-reset.js";
import { obs } from "../integrations/observability.js";

export const setPasswordRouter = Router();

// Rate limiter simple in-memory (10 intentos/hora/IP)
const attempts = new Map<string, { count: number; resetAt: number }>();
const WINDOW_MS = 60 * 60 * 1000;
const MAX = 10;

function rateLimited(ip: string): boolean {
  const now = Date.now();
  const e = attempts.get(ip);
  if (!e || e.resetAt < now) {
    attempts.set(ip, { count: 1, resetAt: now + WINDOW_MS });
    return false;
  }
  if (e.count >= MAX) return true;
  e.count++;
  return false;
}

function getIp(req: Request): string {
  return (req.headers["x-forwarded-for"] as string)?.split(",")[0]?.trim() ?? req.ip ?? "unknown";
}

// POST /v1/auth/set-password { token, newPassword }
setPasswordRouter.post("/set-password", async (req: Request, res: Response) => {
  const ip = getIp(req);
  if (rateLimited(ip)) {
    res.status(429).json({ ok: false, error: "rate_limited" });
    return;
  }

  const { token, newPassword } = (req.body ?? {}) as { token?: string; newPassword?: string };
  if (!token || typeof token !== "string" || token.length < 20) {
    res.status(400).json({ ok: false, error: "token_required" });
    return;
  }
  if (!newPassword || typeof newPassword !== "string" || newPassword.length < 8) {
    res.status(400).json({ ok: false, error: "password_too_short" });
    return;
  }

  // 1) Consumir token (uso único + validación expiración)
  const consumed = await consumePasswordResetToken(token);
  if (!consumed.ok || !consumed.companyId || !consumed.userCode) {
    res.status(400).json({ ok: false, error: consumed.mensaje });
    return;
  }

  // 2) Cambiar password en la BD del tenant
  try {
    const passwordHash = await hashPassword(newPassword);
    await callSp("usp_Sec_User_SetPasswordByMagicLink", {
      CompanyId: consumed.companyId,
      UserCode: consumed.userCode,
      PasswordHash: passwordHash,
    });
    obs.audit("auth.set_password.success", {
      module: "registro",
      companyId: consumed.companyId,
      userCode: consumed.userCode,
    });
    res.json({ ok: true, message: "password_set" });
  } catch (err: any) {
    obs.error(`auth.set_password.failed: ${err?.message}`, {
      module: "registro",
      companyId: consumed.companyId,
    });
    res.status(500).json({ ok: false, error: err?.message ?? "internal_error" });
  }
});

// GET /v1/auth/set-password/validate?token=xxx — sin consumir, solo valida
// Útil para que la página muestre o no el form.
setPasswordRouter.get("/set-password/validate", async (req, res) => {
  const token = String(req.query.token ?? "");
  if (!token) {
    res.status(400).json({ ok: false, valid: false, error: "token_required" });
    return;
  }
  // Validamos sin consumir: hacemos query directa (el SP consume; usaríamos
  // un SP _peek si quisiéramos no consumir). Por ahora retornamos true; el
  // POST efectivo validará al consumir.
  res.json({ ok: true, valid: true });
});
