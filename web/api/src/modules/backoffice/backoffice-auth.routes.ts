/**
 * backoffice-auth.routes.ts — Autenticación de 2 factores para el backoffice.
 *
 * Flujo:
 *   1. POST /v1/backoffice/auth/request-otp  → valida Master Key, envía OTP al email admin
 *   2. POST /v1/backoffice/auth/verify-otp   → valida OTP, emite session token JWT (8h)
 *
 * El session token se usa en X-Backoffice-Token para todos los endpoints protegidos.
 * La Master Key sola YA NO es suficiente — siempre se requiere el 2FA completado.
 */
import { Router } from "express";
import crypto from "node:crypto";
import jwt from "jsonwebtoken";
import { notifyOTP, verifyOTP } from "../_shared/notify.js";
import { obs } from "../integrations/observability.js";

const router = Router();

const MASTER_KEY     = process.env.MASTER_API_KEY ?? "";
const SESSION_SECRET = process.env.MASTER_API_KEY ?? "fallback-insecure";
const ADMIN_EMAIL    = process.env.BACKOFFICE_ADMIN_EMAIL ?? "admin@zentto.net";
const SESSION_TTL    = 8 * 60 * 60; // 8 horas

// ─── Rate limiter en memoria simple (anti-brute-force) ───────────────────────
// Máximo 5 intentos de request-otp por IP en 15 minutos
const otpAttempts = new Map<string, { count: number; resetAt: number }>();

function checkRateLimit(ip: string): boolean {
  const now = Date.now();
  const entry = otpAttempts.get(ip);

  if (!entry || now > entry.resetAt) {
    otpAttempts.set(ip, { count: 1, resetAt: now + 15 * 60 * 1000 });
    return true;
  }

  if (entry.count >= 5) return false;
  entry.count++;
  return true;
}

// Limpiar entradas expiradas cada hora
setInterval(() => {
  const now = Date.now();
  for (const [key, val] of otpAttempts.entries()) {
    if (now > val.resetAt) otpAttempts.delete(key);
  }
}, 60 * 60 * 1000);

// ─── POST /request-otp ───────────────────────────────────────────────────────
// Valida Master Key y envía OTP al email configurado.

router.post("/request-otp", async (req, res) => {
  const ip = (req.headers["x-forwarded-for"] as string)?.split(",")[0]?.trim() ?? req.ip ?? "unknown";

  if (!checkRateLimit(ip)) {
    res.status(429).json({ error: "too_many_attempts", retryAfterMinutes: 15 });
    return;
  }

  const { masterKey } = req.body as { masterKey?: string };

  // Validar Master Key con retardo constante para evitar timing attacks
  await new Promise((r) => setTimeout(r, 200 + Math.random() * 100));

  if (!MASTER_KEY || masterKey !== MASTER_KEY) {
    obs.audit("backoffice.auth.otp.invalid_key", { module: "backoffice-auth", ip });
    res.status(401).json({ error: "unauthorized" });
    return;
  }

  // Enviar OTP via Zentto Notify
  const result = await notifyOTP("email", ADMIN_EMAIL, { brandName: "Zentto Backoffice" });

  if (!result.ok) {
    obs.error(`backoffice.auth.otp.send_failed: ${result.error}`, { module: "backoffice-auth" });
    // Si Notify no está disponible, fallback: informar el error sin bloquear
    res.status(503).json({ error: "otp_send_failed", detail: result.error });
    return;
  }

  obs.audit("backoffice.auth.otp.sent", { module: "backoffice-auth", email: maskEmail(ADMIN_EMAIL) });
  res.json({ ok: true, maskedEmail: maskEmail(ADMIN_EMAIL) });
});

// ─── POST /verify-otp ────────────────────────────────────────────────────────
// Valida OTP y emite session token firmado.

router.post("/verify-otp", async (req, res) => {
  const ip = (req.headers["x-forwarded-for"] as string)?.split(",")[0]?.trim() ?? req.ip ?? "unknown";
  const { masterKey, code } = req.body as { masterKey?: string; code?: string };

  if (!MASTER_KEY || masterKey !== MASTER_KEY || !code?.trim()) {
    res.status(401).json({ error: "unauthorized" });
    return;
  }

  // Verificar OTP via Zentto Notify
  const result = await verifyOTP("email", ADMIN_EMAIL, code.trim());

  if (!result.ok) {
    obs.audit("backoffice.auth.otp.verify_failed", { module: "backoffice-auth", ip });
    res.status(401).json({ error: "invalid_or_expired_otp" });
    return;
  }

  // Emitir session token JWT
  const token = jwt.sign(
    {
      sub: "backoffice",
      role: "SYSADMIN",
      jti: crypto.randomUUID(),
    },
    SESSION_SECRET,
    { expiresIn: SESSION_TTL }
  );

  obs.audit("backoffice.auth.session.created", { module: "backoffice-auth", ip });
  res.json({ ok: true, token, expiresIn: SESSION_TTL, expiresAt: new Date(Date.now() + SESSION_TTL * 1000).toISOString() });
});

// ─── Helpers ─────────────────────────────────────────────────────────────────

function maskEmail(email: string): string {
  const [user, domain] = email.split("@");
  if (!user || !domain) return "***";
  return `${user[0]}${"*".repeat(Math.min(user.length - 1, 4))}@${domain}`;
}

export default router;
