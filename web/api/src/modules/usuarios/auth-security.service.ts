import { createHash, randomBytes } from "node:crypto";
import { callSp, callSpOut, sql } from "../../db/query.js";
import { hashPassword } from "../../auth/password.js";
import { env } from "../../config/env.js";
import { ensureUserDefaultCompanyAccess } from "./usuarios.service.js";
import { getAuthPublicBaseUrl, sendAuthMail } from "./auth-mailer.service.js";
import {
  verifyEmailTemplate,
  resetPasswordTemplate,
  welcomeTemplate,
  passwordChangedTemplate,
} from "./email-templates/base.js";

type TokenType = "VERIFY_EMAIL" | "RESET_PASSWORD";

type LoginSecurityState = {
  allowed: boolean;
  reason?: "locked" | "email_not_verified";
  retryAfterSeconds?: number;
};

type RegisterUserInput = {
  usuario: string;
  nombre: string;
  email: string;
  password: string;
  ip?: string;
  userAgent?: string;
};

type SendTokenInput = {
  userCode: string;
  emailNormalized: string;
  tokenType: TokenType;
  ttlMinutes: number;
  ip?: string;
  userAgent?: string;
};

type MailResult = {
  sent: boolean;
  channel: "webhook" | "console";
  verificationUrl?: string;
  resetUrl?: string;
};

export class AuthFlowError extends Error {
  status: number;
  code: string;

  constructor(status: number, code: string, message: string) {
    super(message);
    this.status = status;
    this.code = code;
  }
}

let authStoreStatus: "unknown" | "available" | "missing" = "unknown";

function toPositiveInt(value: unknown, fallback: number) {
  const parsed = Number(value);
  if (!Number.isFinite(parsed) || parsed <= 0) return fallback;
  return Math.trunc(parsed);
}

function normalizeUserCode(value: string) {
  return String(value ?? "").trim().toUpperCase();
}

function normalizeEmail(value: string) {
  return String(value ?? "").trim().toLowerCase();
}

function nowUtcMs() {
  return Date.now();
}

function getLoginMaxAttempts() {
  return toPositiveInt(process.env.AUTH_LOGIN_MAX_ATTEMPTS, 5);
}

function getLockoutMinutes() {
  return toPositiveInt(process.env.AUTH_LOCKOUT_MINUTES, 15);
}

function getVerificationTokenMinutes() {
  return toPositiveInt(process.env.AUTH_VERIFY_TOKEN_MINUTES, 24 * 60);
}

function getResetTokenMinutes() {
  return toPositiveInt(process.env.AUTH_RESET_TOKEN_MINUTES, 30);
}

function requiresEmailVerification() {
  const raw = String(process.env.AUTH_REQUIRE_EMAIL_VERIFICATION ?? "true").toLowerCase();
  return raw !== "false";
}

function shouldIncludeDebugUrl() {
  return env.nodeEnv !== "production";
}

async function ensureAuthStore() {
  if (authStoreStatus !== "unknown") return authStoreStatus === "available";

  try {
    const rows = await callSp<{ hasStore: number }>("usp_Sec_AuthStore_Check");
    authStoreStatus = rows[0]?.hasStore === 1 ? "available" : "missing";
  } catch {
    authStoreStatus = "missing";
  }

  return authStoreStatus === "available";
}

function hashToken(rawToken: string) {
  return createHash("sha256").update(rawToken).digest("hex");
}

async function userExists(userCode: string) {
  const rows = await callSp<{ existsFlag: number }>(
    "usp_Sec_Auth_UserExistsLegacy",
    { UserCode: userCode }
  );
  return rows[0]?.existsFlag === 1;
}

async function emailExists(emailNormalized: string) {
  const ready = await ensureAuthStore();
  if (!ready) return false;

  const rows = await callSp<{ existsFlag: number }>(
    "usp_Sec_Auth_EmailExists",
    { EmailNormalized: emailNormalized }
  );
  return rows[0]?.existsFlag === 1;
}

async function upsertAuthIdentity(
  userCode: string,
  email: string,
  emailNormalized: string,
  pending: boolean
) {
  await callSp(
    "usp_Sec_AuthIdentity_Upsert",
    {
      UserCode: userCode,
      Email: email,
      EmailNormalized: emailNormalized,
      Pending: pending ? 1 : 0,
    }
  );
}

async function issueToken(input: SendTokenInput) {
  const rawToken = randomBytes(32).toString("hex");
  const tokenHash = hashToken(rawToken);

  await callSp(
    "usp_Sec_AuthToken_Issue",
    {
      UserCode: input.userCode,
      TokenType: input.tokenType,
      TokenHash: tokenHash,
      EmailNormalized: input.emailNormalized,
      TtlMinutes: input.ttlMinutes,
      Ip: input.ip ?? null,
      UserAgent: input.userAgent ?? null,
    }
  );

  return rawToken;
}

async function sendVerificationEmail(
  email: string,
  userCode: string,
  rawToken: string
): Promise<MailResult> {
  const baseUrl = getAuthPublicBaseUrl();
  const verificationUrl = `${baseUrl}/authentication/verify-email?token=${encodeURIComponent(rawToken)}`;

  const { subject, text, html } = verifyEmailTemplate(userCode, verificationUrl);

  const delivery = await sendAuthMail({ to: email, subject, text, html });
  return {
    sent: delivery.sent,
    channel: delivery.channel,
    ...(shouldIncludeDebugUrl() ? { verificationUrl } : {}),
  };
}

async function sendResetEmail(
  email: string,
  userCode: string,
  rawToken: string
): Promise<MailResult> {
  const baseUrl = getAuthPublicBaseUrl();
  const resetUrl = `${baseUrl}/authentication/reset-password?token=${encodeURIComponent(rawToken)}`;

  const { subject, text, html } = resetPasswordTemplate(userCode, resetUrl);

  const delivery = await sendAuthMail({ to: email, subject, text, html });
  return {
    sent: delivery.sent,
    channel: delivery.channel,
    ...(shouldIncludeDebugUrl() ? { resetUrl } : {}),
  };
}

export async function getLoginSecurityState(userCode: string): Promise<LoginSecurityState> {
  const ready = await ensureAuthStore();
  if (!ready) return { allowed: true };

  const normalizedCode = normalizeUserCode(userCode);
  const rows = await callSp<{
    IsRegistrationPending: boolean;
    EmailVerifiedAtUtc: Date | null;
    LockoutUntilUtc: Date | null;
  }>(
    "usp_Sec_Auth_GetLoginSecurityState",
    { UserCode: normalizedCode }
  );

  const row = rows[0];
  if (!row) return { allowed: true };

  if (row.LockoutUntilUtc && new Date(row.LockoutUntilUtc).getTime() > nowUtcMs()) {
    const retryAfterSeconds = Math.max(
      1,
      Math.ceil((new Date(row.LockoutUntilUtc).getTime() - nowUtcMs()) / 1000)
    );
    return { allowed: false, reason: "locked", retryAfterSeconds };
  }

  if (requiresEmailVerification() && row.IsRegistrationPending && !row.EmailVerifiedAtUtc) {
    return { allowed: false, reason: "email_not_verified" };
  }

  return { allowed: true };
}

export async function registerLoginFailure(userCode: string, ip?: string) {
  const ready = await ensureAuthStore();
  if (!ready) return;

  const normalizedCode = normalizeUserCode(userCode);
  await callSp(
    "usp_Sec_Auth_RegisterLoginFailure",
    {
      UserCode: normalizedCode,
      Ip: ip ?? null,
      MaxAttempts: getLoginMaxAttempts(),
      LockoutMinutes: getLockoutMinutes(),
    }
  );
}

export async function registerLoginSuccess(userCode: string) {
  const ready = await ensureAuthStore();
  if (!ready) return;

  const normalizedCode = normalizeUserCode(userCode);
  await callSp(
    "usp_Sec_Auth_RegisterLoginSuccess",
    { UserCode: normalizedCode }
  );
}

export async function registerUser(input: RegisterUserInput) {
  const ready = await ensureAuthStore();
  if (!ready) {
    throw new AuthFlowError(
      503,
      "auth_store_missing",
      "La capa de seguridad de autenticacion no esta desplegada en base de datos."
    );
  }

  const userCode = normalizeUserCode(input.usuario);
  const email = String(input.email ?? "").trim();
  const emailNormalized = normalizeEmail(email);

  if (await userExists(userCode)) {
    throw new AuthFlowError(409, "user_exists", "El usuario ya existe");
  }
  if (await emailExists(emailNormalized)) {
    throw new AuthFlowError(409, "email_exists", "El correo ya esta registrado");
  }

  const passwordHash = await hashPassword(input.password);

  await callSp(
    "usp_Sec_Auth_RegisterUser",
    {
      UserCode: userCode,
      PasswordHash: passwordHash,
      Nombre: input.nombre,
    }
  );

  await ensureUserDefaultCompanyAccess(userCode);

  const pending = requiresEmailVerification();
  await upsertAuthIdentity(userCode, email, emailNormalized, pending);

  let mailResult: MailResult | null = null;
  if (pending) {
    const rawToken = await issueToken({
      userCode,
      emailNormalized,
      tokenType: "VERIFY_EMAIL",
      ttlMinutes: getVerificationTokenMinutes(),
      ip: input.ip,
      userAgent: input.userAgent,
    });
    mailResult = await sendVerificationEmail(email, userCode, rawToken);
  }

  return {
    userCode,
    email,
    requiresEmailVerification: pending,
    mail: mailResult,
  };
}

export async function verifyEmailWithToken(token: string) {
  const ready = await ensureAuthStore();
  if (!ready) {
    throw new AuthFlowError(503, "auth_store_missing", "La capa de seguridad no esta disponible.");
  }

  const tokenHash = hashToken(String(token ?? "").trim());
  const consumed = await callSp<{ UserCode: string; EmailNormalized: string }>(
    "usp_Sec_Auth_ConsumeToken",
    { TokenHash: tokenHash, TokenType: "VERIFY_EMAIL" }
  );

  if (consumed.length === 0) {
    throw new AuthFlowError(400, "invalid_or_expired_token", "El enlace de verificacion no es valido o expiro.");
  }

  const userCode = normalizeUserCode(consumed[0].UserCode);
  await callSp(
    "usp_Sec_Auth_VerifyEmail",
    { UserCode: userCode }
  );

  // Enviar email de bienvenida tras verificación
  const emailNorm = consumed[0].EmailNormalized;
  const loginUrl = `${getAuthPublicBaseUrl()}/authentication/login`;
  const { subject, text, html } = welcomeTemplate(userCode, loginUrl);
  sendAuthMail({ to: emailNorm, subject, text, html }).catch(() => {});

  return { success: true, userCode };
}

type ResolveUserResult = {
  userCode: string;
  email: string;
  emailNormalized: string;
  isPending: boolean;
  emailVerifiedAtUtc: Date | null;
};

async function resolveUserByIdentifier(identifier: string): Promise<ResolveUserResult | null> {
  const ready = await ensureAuthStore();
  if (!ready) return null;

  const normalized = String(identifier ?? "").trim();
  if (!normalized) return null;

  const isEmail = normalized.includes("@");
  const userCode = normalizeUserCode(normalized);
  const emailNormalized = normalizeEmail(normalized);

  const rows = await callSp<{
    UserCode: string;
    Email: string | null;
    EmailNormalized: string | null;
    IsRegistrationPending: boolean;
    EmailVerifiedAtUtc: Date | null;
  }>(
    "usp_Sec_Auth_ResolveByIdentifier",
    {
      UserCode: userCode,
      EmailNormalized: emailNormalized,
      IsEmail: isEmail ? 1 : 0,
    }
  );

  const row = rows[0];
  if (!row || !row.Email || !row.EmailNormalized) return null;

  return {
    userCode: normalizeUserCode(row.UserCode),
    email: row.Email,
    emailNormalized: row.EmailNormalized,
    isPending: Boolean(row.IsRegistrationPending),
    emailVerifiedAtUtc: row.EmailVerifiedAtUtc,
  };
}

export async function resendVerification(identifier: string, ip?: string, userAgent?: string) {
  const resolved = await resolveUserByIdentifier(identifier);
  if (!resolved) {
    return { success: true };
  }

  if (!resolved.isPending || resolved.emailVerifiedAtUtc) {
    return { success: true };
  }

  await callSp(
    "usp_Sec_Auth_InvalidateTokens",
    { UserCode: resolved.userCode, TokenType: "VERIFY_EMAIL" }
  );

  const rawToken = await issueToken({
    userCode: resolved.userCode,
    emailNormalized: resolved.emailNormalized,
    tokenType: "VERIFY_EMAIL",
    ttlMinutes: getVerificationTokenMinutes(),
    ip,
    userAgent,
  });
  const mail = await sendVerificationEmail(resolved.email, resolved.userCode, rawToken);
  return { success: true, mail };
}

export async function requestPasswordReset(identifier: string, ip?: string, userAgent?: string) {
  const resolved = await resolveUserByIdentifier(identifier);
  if (!resolved) {
    return { success: true };
  }

  await callSp(
    "usp_Sec_Auth_InvalidateTokens",
    { UserCode: resolved.userCode, TokenType: "RESET_PASSWORD" }
  );

  const rawToken = await issueToken({
    userCode: resolved.userCode,
    emailNormalized: resolved.emailNormalized,
    tokenType: "RESET_PASSWORD",
    ttlMinutes: getResetTokenMinutes(),
    ip,
    userAgent,
  });
  const mail = await sendResetEmail(resolved.email, resolved.userCode, rawToken);
  return { success: true, mail };
}

export async function resetPasswordWithToken(token: string, newPassword: string) {
  const ready = await ensureAuthStore();
  if (!ready) {
    throw new AuthFlowError(503, "auth_store_missing", "La capa de seguridad no esta disponible.");
  }

  const tokenHash = hashToken(String(token ?? "").trim());
  const consumed = await callSp<{ UserCode: string }>(
    "usp_Sec_Auth_ConsumeToken",
    { TokenHash: tokenHash, TokenType: "RESET_PASSWORD" }
  );

  if (consumed.length === 0) {
    throw new AuthFlowError(400, "invalid_or_expired_token", "El enlace de recuperacion no es valido o expiro.");
  }

  const userCode = normalizeUserCode(consumed[0].UserCode);
  const passwordHash = await hashPassword(newPassword);

  await callSp(
    "usp_Sec_Auth_UpdatePassword",
    { UserCode: userCode, PasswordHash: passwordHash }
  );

  await callSp(
    "usp_Sec_Auth_ResetLockout",
    { UserCode: userCode }
  );

  return { success: true, userCode };
}
