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
 *   - Secret TOTP persistido en cfg.BackofficeAuth (sobrevive deploys).
 *     Fallback bootstrap a env BACKOFFICE_TOTP_SECRET sólo en primer arranque.
 */

import { Router, type Request, type Response } from "express";
import crypto from "node:crypto";
import jwt from "jsonwebtoken";
import {
  TOTP,
  NobleCryptoPlugin,
  ScureBase32Plugin,
  generateSecret,
  verifySync,
} from "otplib";
import QRCode from "qrcode";
import { obs } from "../integrations/observability.js";
import { validateCaptchaToken } from "../usuarios/captcha.service.js";
import { callSp } from "../../db/query.js";

const router = Router();

const MASTER_KEY     = process.env.MASTER_API_KEY ?? "";
const SESSION_SECRET = process.env.MASTER_API_KEY ?? "fallback-insecure";
const SESSION_TTL    = 8 * 60 * 60;                     // 8 horas en segundos
// Sufijo del issuer según ambiente — distingue dev/prod en Google Authenticator.
// El usuario verá "Zentto Backoffice (dev)" y "Zentto Backoffice" como
// entradas separadas con secrets independientes.
const TOTP_ISSUER    = (() => {
  const base = "Zentto Backoffice";
  const env = (process.env.APP_ENV || process.env.NODE_ENV || "").toLowerCase();
  if (env && env !== "production" && env !== "prod") return `${base} (${env})`;
  return base;
})();
const TOTP_ACCOUNT   = process.env.BACKOFFICE_ADMIN_EMAIL ?? "admin@zentto.net";

// TOTP plugins (otplib v13)
const otpCrypto = new NobleCryptoPlugin();
const otpBase32 = new ScureBase32Plugin();
const TOTP_OPTS = { crypto: otpCrypto, base32: otpBase32, period: 30, digits: 6 as const, algorithm: "sha1" as const, window: 2 };

const TOTP_KEY = "totp_secret"; // clave en cfg.BackofficeAuth

// ─── Helpers ──────────────────────────────────────────────────────────────────

// Cache en memoria para evitar hit a BD en cada request (TTL 60s).
let cachedSecret: { value: string; loadedAt: number } | null = null;
const CACHE_TTL_MS = 60_000;

async function getTotpSecret(): Promise<string> {
  const now = Date.now();
  if (cachedSecret && (now - cachedSecret.loadedAt) < CACHE_TTL_MS) {
    return cachedSecret.value;
  }
  // ALERT-2: SOLO BD. El fallback a env var BACKOFFICE_TOTP_SECRET quedó
  // deprecado porque permitía que un operador con acceso al .env (pero no a
  // la BD) tomara control del backoffice. Si la BD no tiene secret,
  // `usp_cfg_backoffice_auth_get` retorna vacío y el flujo exige setup
  // explícito (`scripts/backoffice-setup-totp.cjs` o el endpoint /setup).
  try {
    const rows = await callSp<{ Value: string }>("usp_cfg_backoffice_auth_get", { Key: TOTP_KEY });
    if (rows[0]?.Value) {
      cachedSecret = { value: rows[0].Value, loadedAt: now };
      return rows[0].Value;
    }
    // BD accesible pero vacía → setup pendiente
    return "";
  } catch (err: any) {
    // BD no disponible: esto es un error operativo real, no un motivo para
    // aceptar un secret de env var. Propagamos para que /login responda 5xx
    // y el operador investigue en lugar de confiar en un fallback frágil.
    console.error("[backoffice-auth] BD no disponible al leer TOTP secret:", err?.message);
    throw new Error("backoffice_auth_db_unavailable");
  }
}

async function setTotpSecret(secret: string): Promise<void> {
  // ALERT-2: BD es la única fuente de verdad. Ya no se escribe a
  // process.env.BACKOFFICE_TOTP_SECRET — el fallback fue eliminado.
  await callSp("usp_cfg_backoffice_auth_set", { Key: TOTP_KEY, Value: secret });
  cachedSecret = { value: secret, loadedAt: Date.now() };
}

async function isSetupDone(): Promise<boolean> {
  try {
    return !!(await getTotpSecret());
  } catch {
    // ALERT-2: si la BD falla, consideramos setup "no hecho" desde la
    // perspectiva de /status (UX: no mostrar confirmación verde cuando no
    // podemos afirmarlo). /login sí propaga el 503.
    return false;
  }
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

router.get("/status", async (_req, res) => {
  res.json({ setupDone: await isSetupDone() });
});

// ─── POST /setup — Genera secret + QR code ───────────────────────────────────
// Requiere Master Key. Solo disponible si el TOTP aún no está configurado.

router.post("/setup", async (req: Request, res: Response) => {
  const { masterKey, captchaToken } = req.body as { masterKey?: string; captchaToken?: string };
  const ip = getIp(req);

  await constantDelay();

  // Verificar captcha (skip si AUTH_LOGIN_REQUIRE_CAPTCHA=false — entorno dev)
  if (process.env.AUTH_LOGIN_REQUIRE_CAPTCHA !== "false") {
    const captcha = await validateCaptchaToken(captchaToken, ip, "backoffice_login");
    if (!captcha.ok) {
      res.status(400).json({ error: "captcha_required", reason: captcha.reason });
      return;
    }
  }

  if (!MASTER_KEY || masterKey !== MASTER_KEY) {
    res.status(401).json({ error: "unauthorized" });
    return;
  }

  if (await isSetupDone()) {
    res.status(409).json({ error: "totp_already_configured" });
    return;
  }

  // Generar nuevo secret base32
  const secret = generateSecret(); // 20 bytes (160 bits) base32
  const otpAuthUrl = `otpauth://totp/${encodeURIComponent(TOTP_ISSUER)}:${encodeURIComponent(TOTP_ACCOUNT)}?secret=${secret}&issuer=${encodeURIComponent(TOTP_ISSUER)}&algorithm=SHA1&digits=6&period=30`;

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

  if (await isSetupDone()) {
    res.status(409).json({ error: "totp_already_configured" });
    return;
  }

  const result = verifySync({ token: code.trim(), secret, ...TOTP_OPTS });
  const valid = result.valid;
  if (!valid) {
    obs.audit("backoffice.auth.totp.setup_confirm_failed", { module: "backoffice-auth" });
    res.status(401).json({ error: "invalid_totp_code" });
    return;
  }

  // Persistir en BD (sobrevive deploys/restarts del container)
  try {
    await setTotpSecret(secret);
  } catch (err: any) {
    obs.error(`backoffice.auth.totp.setup_persist_failed: ${err?.message}`, { module: "backoffice-auth" });
    res.status(500).json({ error: "persist_failed", detail: err?.message });
    return;
  }

  obs.audit("backoffice.auth.totp.setup_confirmed", { module: "backoffice-auth" });

  res.json({
    ok: true,
    secret,
    message: "TOTP configurado correctamente y persistido en BD. Sobrevivirá redeploys.",
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

  // Captcha es opcional en /login — la protección real es TOTP + rate limit.
  // El token de Turnstile ya se consumió en /setup, y es single-use.
  if (captchaToken) {
    const captcha = await validateCaptchaToken(captchaToken, ip, "backoffice_login");
    if (!captcha.ok) {
      res.status(400).json({ error: "captcha_failed", reason: captcha.reason });
      return;
    }
  }

  // Validar Master Key
  if (!MASTER_KEY || masterKey !== MASTER_KEY) {
    obs.audit("backoffice.auth.login.invalid_key", { module: "backoffice-auth", ip });
    res.status(401).json({ error: "unauthorized" });
    return;
  }

  // Si TOTP no está configurado aún → redirigir al setup.
  // Si la BD no está disponible → 503 explícito (ALERT-2: ya no hay fallback).
  let totpSecret: string;
  try {
    totpSecret = await getTotpSecret();
  } catch (err: any) {
    obs.error(`backoffice.auth.login.totp_read_failed: ${err?.message}`, { module: "backoffice-auth" });
    res.status(503).json({
      error: "backoffice_auth_unavailable",
      hint: "Base de datos no disponible. Verifica conectividad o ejecuta scripts/backoffice-setup-totp.cjs.",
    });
    return;
  }
  if (!totpSecret) {
    res.status(428).json({ error: "totp_not_configured", setupRequired: true });
    return;
  }

  // Validar código TOTP
  if (!totpCode?.trim()) {
    res.status(401).json({ error: "totp_code_required" });
    return;
  }

  const loginResult = verifySync({ token: totpCode.trim(), secret: totpSecret, ...TOTP_OPTS });
  const valid = loginResult.valid;
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

// ─── POST /setup/regenerate — Regenera TOTP: nuevo QR + secret ──────────────
// Requiere MasterKey. Genera nuevo secret y QR para re-escanear.
// El secret anterior deja de funcionar cuando se confirma el nuevo.

router.post("/setup/regenerate", async (req: Request, res: Response) => {
  const { masterKey, captchaToken } = req.body as { masterKey?: string; captchaToken?: string };
  const ip = getIp(req);

  await constantDelay();

  // Captcha (skip si AUTH_LOGIN_REQUIRE_CAPTCHA=false)
  if (process.env.AUTH_LOGIN_REQUIRE_CAPTCHA !== "false") {
    const captcha = await validateCaptchaToken(captchaToken, ip, "backoffice_login");
    if (!captcha.ok) {
      res.status(400).json({ error: "captcha_required", reason: captcha.reason });
      return;
    }
  }

  if (!MASTER_KEY || masterKey !== MASTER_KEY) {
    res.status(401).json({ error: "unauthorized" });
    return;
  }

  // Generar nuevo secret
  const secret = generateSecret();
  const otpAuthUrl = `otpauth://totp/${encodeURIComponent(TOTP_ISSUER)}:${encodeURIComponent(TOTP_ACCOUNT)}?secret=${secret}&issuer=${encodeURIComponent(TOTP_ISSUER)}&algorithm=SHA1&digits=6&period=30`;
  const qrDataUrl = await QRCode.toDataURL(otpAuthUrl, {
    width: 256,
    margin: 2,
    color: { dark: "#1a1a2e", light: "#ffffff" },
  });

  obs.audit("backoffice.auth.totp.regenerate_initiated", { module: "backoffice-auth", ip });

  res.json({
    ok: true,
    secret,
    qrDataUrl,
    otpAuthUrl,
    instructions: [
      "1. Abre Google Authenticator en tu telefono",
      "2. Elimina la entrada anterior de 'Zentto Backoffice'",
      "3. Escanea este nuevo QR",
      "4. Ingresa el codigo de 6 digitos para confirmar",
    ],
  });
});

// ─── POST /setup/regenerate/confirm — Confirma nuevo TOTP y actualiza el .env ─
// Actualiza BACKOFFICE_TOTP_SECRET en el archivo .env del servidor automáticamente.

router.post("/setup/regenerate/confirm", async (req: Request, res: Response) => {
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

  const result = verifySync({ token: code.trim(), secret, ...TOTP_OPTS });
  if (!result.valid) {
    res.status(401).json({ error: "invalid_totp_code" });
    return;
  }

  // Persistir nuevo secret en BD (sobrevive deploys/restarts del container).
  // Antes intentaba escribir a /opt/zentto/.env.api desde DENTRO del container,
  // pero ese path no era accesible → fallaba silenciosamente y al próximo deploy
  // el container arrancaba con el secret viejo, obligando a regenerar de nuevo.
  try {
    await setTotpSecret(secret);
  } catch (err: any) {
    obs.error(`backoffice.auth.totp.regenerate_persist_failed: ${err?.message}`, { module: "backoffice-auth" });
    res.status(500).json({ error: "persist_failed", detail: err?.message });
    return;
  }

  obs.audit("backoffice.auth.totp.regenerated", { module: "backoffice-auth" });

  res.json({
    ok: true,
    message: "TOTP regenerado exitosamente. El nuevo secret ya está activo.",
  });
});

export default router;
