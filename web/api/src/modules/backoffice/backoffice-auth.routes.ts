/**
 * backoffice-auth.routes.ts — Autenticación 2FA con TOTP (Google Authenticator)
 *
 * Flujo primera vez (setup):
 *   1. POST /v1/backoffice/auth/setup      → valida MasterKey, genera secret + QR code
 *   2. POST /v1/backoffice/auth/setup/confirm → verifica primer código TOTP, activa 2FA
 *
 * Flujo login normal:
 *   1. POST /v1/backoffice/auth/login      → valida MasterKey + código TOTP → emite JWT (8h)
 *
 * El JWT se usa en X-Backoffice-Token para todos los endpoints protegidos del backoffice.
 *
 * Seguridad:
 *   - TOTP RFC 6238 (compatible con Google Authenticator, Authy, 1Password, Bitwarden)
 *   - Ventana ±1 token (30s antes/después) para tolerancia de reloj
 *   - Rate limit: 5 intentos/IP/15min en /login
 *   - Retardo constante en validaciones (anti-timing attacks)
 *   - JWT firmado con MASTER_API_KEY, expira en 8h, incluye jti único
 *   - Secret TOTP almacenado en BACKOFFICE_TOTP_SECRET (env var, nunca en BD)
 */

import { Router, type Request, type Response } from "express";
import crypto from "node:crypto";
import jwt from "jsonwebtoken";
import { authenticator } from "otplib";
import QRCode from "qrcode";
import { obs } from "../integrations/observability.js";
import { validateCaptchaToken } from "../usuarios/captcha.service.js";

const router = Router();

const MASTER_KEY     = process.env.MASTER_API_KEY ?? "";
const SESSION_SECRET = process.env.MASTER_API_KEY ?? "fallback-insecure";
const SESSION_TTL    = 8 * 60 * 60;                     // 8 horas en segundos
const TOTP_ISSUER    = "Zentto Backoffice";
const TOTP_ACCOUNT   = process.env.BACKOFFICE_ADMIN_EMAIL ?? "admin@zentto.net";

// TOTP: ventana ±1 intervalo (30s) para tolerancia de reloj
authenticator.options = { window: 1 };

// ─── Helpers ──────────────────────────────────────────────────────────────────

function getTotpSecret(): string {
  return process.env.BACKOFFICE_TOTP_SECRET ?? "";
}

function isSetupDone(): boolean {
  return !!getTotpSecret();
}

// ─── Rate limiter en memoria (anti-brute-force login) ────────────────────────

const loginAttempts = new Map<string, { count: number; resetAt: number }>();

function checkRateLimit(ip: string): boolean {
  const now = Date.now();
  const entry = loginAttempts.get(ip);
  if (!entry || now > entry.resetAt) {
    loginAttempts.set(ip, { count: 1, resetAt: now + 15 * 60 * 1000 });
    return true;
  }
  if (entry.count >= 5) return false;
  entry.count++;
  return true;
}

// Limpiar entradas expiradas cada hora
setInterval(() => {
  const now = Date.now();
  for (const [k, v] of loginAttempts.entries()) {
    if (now > v.resetAt) loginAttempts.delete(k);
  }
}, 60 * 60 * 1000);

function getIp(req: Request): string {
  return (req.headers["x-forwarded-for"] as string)?.split(",")[0]?.trim() ?? req.ip ?? "unknown";
}

// Retardo constante para evitar timing attacks
async function constantDelay(): Promise<void> {
  await new Promise((r) => setTimeout(r, 200 + Math.random() * 100));
}

// ─── GET /status — ¿ya está configurado el TOTP? ─────────────────────────────
// No requiere autenticación — solo informa si el setup fue completado.

router.get("/status", (_req, res) => {
  res.json({ setupDone: isSetupDone() });
});

// ─── POST /setup — Genera secret + QR code ───────────────────────────────────
// Requiere Master Key. Solo disponible si el TOTP aún no está configurado.

router.post("/setup", async (req: Request, res: Response) => {
  const { masterKey, captchaToken } = req.body as { masterKey?: string; captchaToken?: string };
  const ip = getIp(req);

  await constantDelay();

  // Verificar captcha
  const captcha = await validateCaptchaToken(captchaToken, ip, "backoffice_login");
  if (!captcha.ok) {
    res.status(400).json({ error: "captcha_required", reason: captcha.reason });
    return;
  }

  if (!MASTER_KEY || masterKey !== MASTER_KEY) {
    res.status(401).json({ error: "unauthorized" });
    return;
  }

  if (isSetupDone()) {
    res.status(409).json({ error: "totp_already_configured" });
    return;
  }

  // Generar nuevo secret base32
  const secret = authenticator.generateSecret(20); // 160 bits
  const otpAuthUrl = authenticator.keyuri(TOTP_ACCOUNT, TOTP_ISSUER, secret);

  // Generar QR code como data URL (base64 PNG)
  const qrDataUrl = await QRCode.toDataURL(otpAuthUrl, {
    width: 256,
    margin: 2,
    color: { dark: "#1a1a2e", light: "#ffffff" },
  });

  obs.audit("backoffice.auth.totp.setup_initiated", { module: "backoffice-auth" });

  res.json({
    ok: true,
    secret,            // para ingresar manualmente en Google Authenticator si el QR falla
    qrDataUrl,         // imagen PNG en base64 para mostrar en el frontend
    otpAuthUrl,        // enlace otpauth:// (para apps que lo soporten)
    instructions: [
      "1. Abre Google Authenticator, Authy o Bitwarden en tu telefono",
      "2. Toca '+' → 'Escanear codigo QR'",
      "3. Escanea el QR que aparece en pantalla",
      "4. Ingresa el codigo de 6 digitos que muestra la app para confirmar",
    ],
  });
});

// ─── POST /setup/confirm — Confirma el primer código TOTP y activa 2FA ───────
// Requiere Master Key + primer código TOTP válido.
// Devuelve el secret final que DEBE guardarse en BACKOFFICE_TOTP_SECRET.

router.post("/setup/confirm", async (req: Request, res: Response) => {
  const { masterKey, code, secret } = req.body as {
    masterKey?: string;
    code?: string;
    secret?: string;
  };

  await constantDelay();

  if (!MASTER_KEY || masterKey !== MASTER_KEY || !code || !secret) {
    res.status(401).json({ error: "unauthorized" });
    return;
  }

  if (isSetupDone()) {
    res.status(409).json({ error: "totp_already_configured" });
    return;
  }

  const valid = authenticator.check(code.trim(), secret);
  if (!valid) {
    obs.audit("backoffice.auth.totp.setup_confirm_failed", { module: "backoffice-auth" });
    res.status(401).json({ error: "invalid_totp_code" });
    return;
  }

  obs.audit("backoffice.auth.totp.setup_confirmed", { module: "backoffice-auth" });

  // El secret validado debe guardarse en la variable de entorno del servidor
  res.json({
    ok: true,
    secret,
    message: "TOTP configurado correctamente. Guarda este secret en BACKOFFICE_TOTP_SECRET del servidor.",
    envLine: `BACKOFFICE_TOTP_SECRET=${secret}`,
  });
});

// ─── POST /login — Login 2FA: MasterKey + código TOTP ────────────────────────
// Emite JWT de sesión válido 8 horas.

router.post("/login", async (req: Request, res: Response) => {
  const ip = getIp(req);

  if (!checkRateLimit(ip)) {
    res.status(429).json({ error: "too_many_attempts", retryAfterMinutes: 15 });
    return;
  }

  const { masterKey, totpCode, captchaToken } = req.body as {
    masterKey?: string;
    totpCode?: string;
    captchaToken?: string;
  };

  await constantDelay();

  // Verificar captcha antes de cualquier otra validación
  const captcha = await validateCaptchaToken(captchaToken, ip, "backoffice_login");
  if (!captcha.ok) {
    res.status(400).json({ error: "captcha_required", reason: captcha.reason });
    return;
  }

  // Validar Master Key
  if (!MASTER_KEY || masterKey !== MASTER_KEY) {
    obs.audit("backoffice.auth.login.invalid_key", { module: "backoffice-auth", ip });
    res.status(401).json({ error: "unauthorized" });
    return;
  }

  // Si TOTP no está configurado aún → redirigir al setup
  const totpSecret = getTotpSecret();
  if (!totpSecret) {
    res.status(428).json({ error: "totp_not_configured", setupRequired: true });
    return;
  }

  // Validar código TOTP
  if (!totpCode?.trim()) {
    res.status(401).json({ error: "totp_code_required" });
    return;
  }

  const valid = authenticator.check(totpCode.trim(), totpSecret);
  if (!valid) {
    obs.audit("backoffice.auth.login.invalid_totp", { module: "backoffice-auth", ip });
    res.status(401).json({ error: "invalid_totp_code" });
    return;
  }

  // Emitir session token JWT
  const token = jwt.sign(
    { sub: "backoffice", role: "SYSADMIN", jti: crypto.randomUUID() },
    SESSION_SECRET,
    { expiresIn: SESSION_TTL }
  );

  obs.audit("backoffice.auth.login.success", { module: "backoffice-auth", ip });
  res.json({
    ok: true,
    token,
    expiresIn: SESSION_TTL,
    expiresAt: new Date(Date.now() + SESSION_TTL * 1000).toISOString(),
  });
});

// ─── POST /setup/reset — Limpia el secret TOTP (requiere MasterKey) ──────────
// Solo para emergencias. En producción desactivar o proteger adicionalmente.

router.post("/setup/reset", async (req: Request, res: Response) => {
  const { masterKey } = req.body as { masterKey?: string };

  await constantDelay();

  if (!MASTER_KEY || masterKey !== MASTER_KEY) {
    res.status(401).json({ error: "unauthorized" });
    return;
  }

  obs.audit("backoffice.auth.totp.reset_requested", { module: "backoffice-auth", ip: getIp(req) });

  res.json({
    ok: true,
    message: "Para resetear el TOTP, elimina BACKOFFICE_TOTP_SECRET del .env del servidor y reinicia la API.",
    steps: [
      "1. SSH al servidor: ssh root@178.104.56.185",
      "2. Editar: nano /opt/zentto/.env.api  (o donde esté el archivo de entorno)",
      "3. Eliminar la línea BACKOFFICE_TOTP_SECRET=...",
      "4. Reiniciar: docker restart zentto-api",
      "5. Volver a /backoffice y escanear nuevo QR",
    ],
  });
});

export default router;
