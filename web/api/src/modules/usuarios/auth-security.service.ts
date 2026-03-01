import { createHash, randomBytes } from "node:crypto";
import { execute, query } from "../../db/query.js";
import { hashPassword } from "../../auth/password.js";
import { env } from "../../config/env.js";
import { ensureUserDefaultCompanyAccess } from "./usuarios.service.js";
import { getAuthPublicBaseUrl, sendAuthMail } from "./auth-mailer.service.js";

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
    const rows = await query<{ hasStore: number }>(
      `
      SELECT
        CASE
          WHEN OBJECT_ID(N'sec.AuthIdentity', N'U') IS NOT NULL
           AND OBJECT_ID(N'sec.AuthToken', N'U') IS NOT NULL
          THEN 1
          ELSE 0
        END AS hasStore
      `
    );
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
  const rows = await query<{ existsFlag: number }>(
    `
    SELECT CASE WHEN EXISTS (
      SELECT 1 FROM dbo.Usuarios WHERE UPPER(Cod_Usuario) = UPPER(@userCode)
    ) THEN 1 ELSE 0 END AS existsFlag
    `,
    { userCode }
  );
  return rows[0]?.existsFlag === 1;
}

async function emailExists(emailNormalized: string) {
  const ready = await ensureAuthStore();
  if (!ready) return false;

  const rows = await query<{ existsFlag: number }>(
    `
    SELECT CASE WHEN EXISTS (
      SELECT 1
      FROM sec.AuthIdentity
      WHERE EmailNormalized = @emailNormalized
    ) THEN 1 ELSE 0 END AS existsFlag
    `,
    { emailNormalized }
  );
  return rows[0]?.existsFlag === 1;
}

async function upsertAuthIdentity(
  userCode: string,
  email: string,
  emailNormalized: string,
  pending: boolean
) {
  await execute(
    `
    MERGE sec.AuthIdentity AS tgt
    USING (
      SELECT
        @userCode AS UserCode,
        @email AS Email,
        @emailNormalized AS EmailNormalized
    ) AS src
      ON tgt.UserCode = src.UserCode
    WHEN MATCHED THEN
      UPDATE SET
        Email = src.Email,
        EmailNormalized = src.EmailNormalized,
        IsRegistrationPending = @pending,
        EmailVerifiedAtUtc = CASE WHEN @pending = 1 THEN NULL ELSE ISNULL(tgt.EmailVerifiedAtUtc, SYSUTCDATETIME()) END,
        UpdatedAtUtc = SYSUTCDATETIME()
    WHEN NOT MATCHED THEN
      INSERT (
        UserCode,
        Email,
        EmailNormalized,
        EmailVerifiedAtUtc,
        IsRegistrationPending,
        FailedLoginCount,
        CreatedAtUtc,
        UpdatedAtUtc
      )
      VALUES (
        src.UserCode,
        src.Email,
        src.EmailNormalized,
        CASE WHEN @pending = 1 THEN NULL ELSE SYSUTCDATETIME() END,
        @pending,
        0,
        SYSUTCDATETIME(),
        SYSUTCDATETIME()
      );
    `,
    {
      userCode,
      email,
      emailNormalized,
      pending: pending ? 1 : 0,
    }
  );
}

async function issueToken(input: SendTokenInput) {
  const rawToken = randomBytes(32).toString("hex");
  const tokenHash = hashToken(rawToken);

  await execute(
    `
    INSERT INTO sec.AuthToken (
      UserCode,
      TokenType,
      TokenHash,
      EmailNormalized,
      ExpiresAtUtc,
      MetaIp,
      MetaUserAgent
    )
    VALUES (
      @userCode,
      @tokenType,
      @tokenHash,
      @emailNormalized,
      DATEADD(minute, @ttlMinutes, SYSUTCDATETIME()),
      @ip,
      @userAgent
    );
    `,
    {
      userCode: input.userCode,
      tokenType: input.tokenType,
      tokenHash,
      emailNormalized: input.emailNormalized,
      ttlMinutes: input.ttlMinutes,
      ip: input.ip ?? null,
      userAgent: input.userAgent ?? null,
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

  const subject = "Confirma tu cuenta DatqBox";
  const text = `Hola ${userCode}, confirma tu cuenta con este enlace: ${verificationUrl}`;
  const html = `
    <p>Hola <strong>${userCode}</strong>,</p>
    <p>Confirma tu cuenta para activar el acceso a DatqBox:</p>
    <p><a href="${verificationUrl}">Confirmar cuenta</a></p>
    <p>Si no solicitaste este registro, puedes ignorar este mensaje.</p>
  `;

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

  const subject = "Restablecer contrasena DatqBox";
  const text = `Hola ${userCode}, usa este enlace para restablecer tu contrasena: ${resetUrl}`;
  const html = `
    <p>Hola <strong>${userCode}</strong>,</p>
    <p>Recibimos una solicitud para restablecer tu contrasena:</p>
    <p><a href="${resetUrl}">Restablecer contrasena</a></p>
    <p>Si no fuiste tu, ignora este correo.</p>
  `;

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
  const rows = await query<{
    IsRegistrationPending: boolean;
    EmailVerifiedAtUtc: Date | null;
    LockoutUntilUtc: Date | null;
  }>(
    `
    SELECT TOP 1
      IsRegistrationPending,
      EmailVerifiedAtUtc,
      LockoutUntilUtc
    FROM sec.AuthIdentity
    WHERE UPPER(UserCode) = UPPER(@userCode)
    `,
    { userCode: normalizedCode }
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
  await execute(
    `
    UPDATE sec.AuthIdentity
    SET
      FailedLoginCount = ISNULL(FailedLoginCount, 0) + 1,
      LastFailedLoginAtUtc = SYSUTCDATETIME(),
      LastFailedLoginIp = @ip,
      LockoutUntilUtc = CASE
        WHEN ISNULL(FailedLoginCount, 0) + 1 >= @maxAttempts
          THEN DATEADD(minute, @lockoutMinutes, SYSUTCDATETIME())
        ELSE LockoutUntilUtc
      END,
      UpdatedAtUtc = SYSUTCDATETIME()
    WHERE UPPER(UserCode) = UPPER(@userCode)
    `,
    {
      userCode: normalizedCode,
      ip: ip ?? null,
      maxAttempts: getLoginMaxAttempts(),
      lockoutMinutes: getLockoutMinutes(),
    }
  );
}

export async function registerLoginSuccess(userCode: string) {
  const ready = await ensureAuthStore();
  if (!ready) return;

  const normalizedCode = normalizeUserCode(userCode);
  await execute(
    `
    UPDATE sec.AuthIdentity
    SET
      FailedLoginCount = 0,
      LastLoginAtUtc = SYSUTCDATETIME(),
      LockoutUntilUtc = NULL,
      UpdatedAtUtc = SYSUTCDATETIME()
    WHERE UPPER(UserCode) = UPPER(@userCode)
    `,
    { userCode: normalizedCode }
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

  await execute(
    `
    INSERT INTO dbo.Usuarios (
      Cod_Usuario,
      Password,
      Nombre,
      Tipo,
      Updates,
      Addnews,
      Deletes,
      Creador,
      Cambiar,
      PrecioMinimo,
      Credito,
      IsAdmin
    )
    VALUES (
      @userCode,
      @passwordHash,
      @nombre,
      N'USER',
      1,
      1,
      0,
      0,
      1,
      0,
      0,
      0
    )
    `,
    {
      userCode,
      passwordHash,
      nombre: input.nombre,
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
  const consumed = await query<{ UserCode: string; EmailNormalized: string }>(
    `
    ;WITH target AS (
      SELECT TOP 1 TokenId
      FROM sec.AuthToken
      WHERE TokenHash = @tokenHash
        AND TokenType = 'VERIFY_EMAIL'
        AND ConsumedAtUtc IS NULL
        AND ExpiresAtUtc >= SYSUTCDATETIME()
      ORDER BY TokenId DESC
    )
    UPDATE t
    SET ConsumedAtUtc = SYSUTCDATETIME()
    OUTPUT inserted.UserCode AS UserCode, inserted.EmailNormalized AS EmailNormalized
    FROM sec.AuthToken t
    INNER JOIN target x ON x.TokenId = t.TokenId;
    `,
    { tokenHash }
  );

  if (consumed.length === 0) {
    throw new AuthFlowError(400, "invalid_or_expired_token", "El enlace de verificacion no es valido o expiro.");
  }

  const userCode = normalizeUserCode(consumed[0].UserCode);
  await execute(
    `
    UPDATE sec.AuthIdentity
    SET
      IsRegistrationPending = 0,
      EmailVerifiedAtUtc = SYSUTCDATETIME(),
      FailedLoginCount = 0,
      LockoutUntilUtc = NULL,
      UpdatedAtUtc = SYSUTCDATETIME()
    WHERE UPPER(UserCode) = UPPER(@userCode)
    `,
    { userCode }
  );

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

  const rows = await query<{
    UserCode: string;
    Email: string | null;
    EmailNormalized: string | null;
    IsRegistrationPending: boolean;
    EmailVerifiedAtUtc: Date | null;
  }>(
    `
    SELECT TOP 1
      ai.UserCode AS UserCode,
      ai.Email AS Email,
      ai.EmailNormalized AS EmailNormalized,
      ai.IsRegistrationPending AS IsRegistrationPending,
      ai.EmailVerifiedAtUtc AS EmailVerifiedAtUtc
    FROM sec.AuthIdentity ai
    WHERE
      (${isEmail ? "ai.EmailNormalized = @emailNormalized" : "UPPER(ai.UserCode) = UPPER(@userCode)"})
    `
    ,
    {
      userCode,
      emailNormalized,
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

  await execute(
    `
    UPDATE sec.AuthToken
    SET ConsumedAtUtc = ISNULL(ConsumedAtUtc, SYSUTCDATETIME())
    WHERE UPPER(UserCode) = UPPER(@userCode)
      AND TokenType = 'VERIFY_EMAIL'
      AND ConsumedAtUtc IS NULL
    `,
    { userCode: resolved.userCode }
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

  await execute(
    `
    UPDATE sec.AuthToken
    SET ConsumedAtUtc = ISNULL(ConsumedAtUtc, SYSUTCDATETIME())
    WHERE UPPER(UserCode) = UPPER(@userCode)
      AND TokenType = 'RESET_PASSWORD'
      AND ConsumedAtUtc IS NULL
    `,
    { userCode: resolved.userCode }
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
  const consumed = await query<{ UserCode: string }>(
    `
    ;WITH target AS (
      SELECT TOP 1 TokenId
      FROM sec.AuthToken
      WHERE TokenHash = @tokenHash
        AND TokenType = 'RESET_PASSWORD'
        AND ConsumedAtUtc IS NULL
        AND ExpiresAtUtc >= SYSUTCDATETIME()
      ORDER BY TokenId DESC
    )
    UPDATE t
    SET ConsumedAtUtc = SYSUTCDATETIME()
    OUTPUT inserted.UserCode AS UserCode
    FROM sec.AuthToken t
    INNER JOIN target x ON x.TokenId = t.TokenId;
    `,
    { tokenHash }
  );

  if (consumed.length === 0) {
    throw new AuthFlowError(400, "invalid_or_expired_token", "El enlace de recuperacion no es valido o expiro.");
  }

  const userCode = normalizeUserCode(consumed[0].UserCode);
  const passwordHash = await hashPassword(newPassword);

  await execute(
    `
    UPDATE dbo.Usuarios
    SET Password = @passwordHash
    WHERE UPPER(Cod_Usuario) = UPPER(@userCode)
    `,
    {
      userCode,
      passwordHash,
    }
  );

  await execute(
    `
    UPDATE sec.AuthIdentity
    SET
      FailedLoginCount = 0,
      LockoutUntilUtc = NULL,
      PasswordChangedAtUtc = SYSUTCDATETIME(),
      UpdatedAtUtc = SYSUTCDATETIME()
    WHERE UPPER(UserCode) = UPPER(@userCode)
    `,
    { userCode }
  );

  return { success: true, userCode };
}
