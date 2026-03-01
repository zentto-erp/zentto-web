import { Router } from "express";
import type { Request } from "express";
import { z } from "zod";
import {
  loginSchema,
  changePasswordSchema,
  resetPasswordSchema,
  registerSchema,
  verifyEmailSchema,
  forgotPasswordSchema,
  resetPasswordByTokenSchema,
  resendVerificationSchema,
  SYSTEM_MODULES,
} from "./types.js";
import {
  authenticateUsuario,
  extractPermisos,
  getModulosAcceso,
  changePassword,
  resetPassword,
  getUserCompanyAccesses,
  resolveActiveCompanyAccess,
  getUsuarioTipo,
} from "./usuarios.service.js";
import {
  AuthFlowError,
  getLoginSecurityState,
  registerLoginFailure,
  registerLoginSuccess,
  registerUser,
  requestPasswordReset,
  resendVerification,
  resetPasswordWithToken,
  verifyEmailWithToken,
} from "./auth-security.service.js";
import { validateCaptchaToken } from "./captcha.service.js";
import { signJwt, type JwtPayload } from "../../auth/jwt.js";
import { createRateLimiter, getClientIp } from "../../middleware/rate-limit.js";

export const authRouter = Router();

const switchCompanySchema = z.object({
  companyId: z.coerce.number().int().positive(),
  branchId: z.coerce.number().int().positive().optional(),
});

const loginOptionsSchema = z.object({
  usuario: z.string().min(1),
});

const loginOptionsLimiter = createRateLimiter({
  name: "auth_login_options_ip",
  max: 80,
  windowSec: 60,
});

const loginLimiter = createRateLimiter({
  name: "auth_login_ip",
  max: 30,
  windowSec: 60,
});

const registerLimiter = createRateLimiter({
  name: "auth_register_ip",
  max: 10,
  windowSec: 3600,
});

const forgotLimiter = createRateLimiter({
  name: "auth_forgot_ip",
  max: 12,
  windowSec: 3600,
});

const verifyLimiter = createRateLimiter({
  name: "auth_verify_ip",
  max: 30,
  windowSec: 3600,
});
const includeDebugMail =
  String(process.env.AUTH_EXPOSE_DEBUG_LINKS || "false").toLowerCase() === "true";
const requireCaptchaOnLogin =
  String(process.env.AUTH_LOGIN_REQUIRE_CAPTCHA || "false").toLowerCase() === "true";

function toErrorResponse(error: unknown) {
  if (error instanceof AuthFlowError) {
    return { status: error.status, body: { error: error.code, message: error.message } };
  }
  return {
    status: 500,
    body: { error: "internal_error", message: "Error interno de autenticacion" },
  };
}

async function ensureCaptcha(
  req: Request,
  captchaToken: string | undefined,
  action: "login" | "register" | "forgot_password" | "reset_password" | "verify_email" | "resend_verification"
) {
  const validation = await validateCaptchaToken(captchaToken, getClientIp(req), action);
  if (!validation.ok) {
    return {
      ok: false as const,
      status: 400,
      body: {
        error: "captcha_invalid",
        message: "Validacion CAPTCHA fallida",
        reason: validation.reason,
      },
    };
  }
  return { ok: true as const };
}

// --- POST /v1/auth/register -----------------------------------
authRouter.post("/register", registerLimiter, async (req, res) => {
  const parsed = registerSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  }

  const captcha = await ensureCaptcha(req, parsed.data.captchaToken, "register");
  if (!captcha.ok) return res.status(captcha.status).json(captcha.body);

  try {
    const created = await registerUser({
      usuario: parsed.data.usuario,
      nombre: parsed.data.nombre,
      email: parsed.data.email,
      password: parsed.data.password,
      ip: getClientIp(req),
      userAgent: req.headers["user-agent"],
    });

    return res.status(201).json({
      success: true,
      message: created.requiresEmailVerification
        ? "Registro exitoso. Revisa tu correo para confirmar la cuenta."
        : "Registro exitoso.",
      requiresEmailVerification: created.requiresEmailVerification,
      ...(includeDebugMail ? { mail: created.mail ?? null } : {}),
    });
  } catch (error) {
    const mapped = toErrorResponse(error);
    return res.status(mapped.status).json(mapped.body);
  }
});

// --- GET /v1/auth/verify-email?token=... ---------------------
authRouter.get("/verify-email", verifyLimiter, async (req, res) => {
  const token = String(req.query.token ?? "");
  const parsed = verifyEmailSchema.safeParse({ token });
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_query", issues: parsed.error.flatten() });
  }

  try {
    const result = await verifyEmailWithToken(parsed.data.token);
    return res.json({
      success: true,
      message: "Cuenta verificada correctamente",
      userCode: result.userCode,
    });
  } catch (error) {
    const mapped = toErrorResponse(error);
    return res.status(mapped.status).json(mapped.body);
  }
});

// --- POST /v1/auth/verify-email ------------------------------
authRouter.post("/verify-email", verifyLimiter, async (req, res) => {
  const parsed = verifyEmailSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  }

  const captcha = await ensureCaptcha(req, parsed.data.captchaToken, "verify_email");
  if (!captcha.ok) return res.status(captcha.status).json(captcha.body);

  try {
    const result = await verifyEmailWithToken(parsed.data.token);
    return res.json({
      success: true,
      message: "Cuenta verificada correctamente",
      userCode: result.userCode,
    });
  } catch (error) {
    const mapped = toErrorResponse(error);
    return res.status(mapped.status).json(mapped.body);
  }
});

// --- POST /v1/auth/resend-verification -----------------------
authRouter.post("/resend-verification", forgotLimiter, async (req, res) => {
  const parsed = resendVerificationSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  }

  const captcha = await ensureCaptcha(req, parsed.data.captchaToken, "resend_verification");
  if (!captcha.ok) return res.status(captcha.status).json(captcha.body);

  const result = await resendVerification(
    parsed.data.identifier,
    getClientIp(req),
    req.headers["user-agent"]
  );

  return res.json({
    success: true,
    message: "Si el usuario existe y esta pendiente de verificacion, enviamos un enlace.",
    ...(includeDebugMail ? { mail: result.mail ?? null } : {}),
  });
});

// --- POST /v1/auth/forgot-password ---------------------------
authRouter.post("/forgot-password", forgotLimiter, async (req, res) => {
  const parsed = forgotPasswordSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  }

  const captcha = await ensureCaptcha(req, parsed.data.captchaToken, "forgot_password");
  if (!captcha.ok) return res.status(captcha.status).json(captcha.body);

  const result = await requestPasswordReset(
    parsed.data.identifier,
    getClientIp(req),
    req.headers["user-agent"]
  );

  return res.json({
    success: true,
    message: "Si el usuario existe, recibira un enlace para restablecer la contrasena.",
    ...(includeDebugMail ? { mail: result.mail ?? null } : {}),
  });
});

// --- POST /v1/auth/reset-password/confirm --------------------
authRouter.post("/reset-password/confirm", forgotLimiter, async (req, res) => {
  const parsed = resetPasswordByTokenSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  }

  const captcha = await ensureCaptcha(req, parsed.data.captchaToken, "reset_password");
  if (!captcha.ok) return res.status(captcha.status).json(captcha.body);

  try {
    const result = await resetPasswordWithToken(parsed.data.token, parsed.data.newPassword);
    return res.json({
      success: true,
      message: "Contrasena actualizada correctamente.",
      userCode: result.userCode,
    });
  } catch (error) {
    const mapped = toErrorResponse(error);
    return res.status(mapped.status).json(mapped.body);
  }
});

// --- GET /v1/auth/login-options?usuario=SUP ------------------
authRouter.get("/login-options", loginOptionsLimiter, async (req, res) => {
  const parsed = loginOptionsSchema.safeParse(req.query);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_query", issues: parsed.error.flatten() });
  }

  const user = await getUsuarioTipo(parsed.data.usuario);
  if (!user) return res.status(404).json({ error: "user_not_found" });

  const isAdmin =
    user.tipo === "ADMIN" ||
    user.tipo === "SUP" ||
    user.codUsuario.toUpperCase() === "SUP";

  const companyAccesses = await getUserCompanyAccesses(user.codUsuario, isAdmin);
  const activeCompany = resolveActiveCompanyAccess(companyAccesses);

  return res.json({ rows: companyAccesses, active: activeCompany });
});

// --- POST /v1/auth/login --------------------------------------
authRouter.post("/login", loginLimiter, async (req, res) => {
  const parsed = loginSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  }

  const { usuario, clave, companyId, branchId, captchaToken } = parsed.data;
  const normalizedUser = String(usuario ?? "").trim();

  if (requireCaptchaOnLogin) {
    const captcha = await ensureCaptcha(req, captchaToken, "login");
    if (!captcha.ok) return res.status(captcha.status).json(captcha.body);
  }

  const security = await getLoginSecurityState(normalizedUser);
  if (!security.allowed) {
    if (security.reason === "locked") {
      if (security.retryAfterSeconds) {
        res.setHeader("Retry-After", String(security.retryAfterSeconds));
      }
      return res.status(423).json({
        error: "account_locked",
        message: "Cuenta bloqueada temporalmente por intentos fallidos.",
        retryAfterSeconds: security.retryAfterSeconds ?? null,
      });
    }

    return res.status(403).json({
      error: "email_not_verified",
      message: "Debes verificar tu correo antes de iniciar sesion.",
    });
  }

  const record = await authenticateUsuario(usuario, clave);

  if (!record) {
    await registerLoginFailure(normalizedUser, getClientIp(req));
    return res.status(401).json({ error: "invalid_credentials" });
  }

  const isAdmin =
    record.Tipo === "ADMIN" ||
    record.Tipo === "SUP" ||
    record.Cod_Usuario.toUpperCase() === "SUP";

  const permisos = extractPermisos(record);
  const modulosAcceso = await getModulosAcceso(record.Cod_Usuario);

  let allowedModules: string[];
  if (isAdmin) {
    allowedModules = [...SYSTEM_MODULES];
  } else if (modulosAcceso.length === 0) {
    allowedModules = ["dashboard", "facturas", "clientes", "inventario", "articulos"];
  } else {
    allowedModules = modulosAcceso
      .filter((m) => m.permitido)
      .map((m) => m.modulo);
    if (!allowedModules.includes("dashboard")) {
      allowedModules.unshift("dashboard");
    }
  }

  const companyAccesses = await getUserCompanyAccesses(record.Cod_Usuario, isAdmin);
  const activeCompany = resolveActiveCompanyAccess(companyAccesses, companyId, branchId);

  if (!activeCompany) {
    return res.status(403).json({
      error: "invalid_company_scope",
      message: "El usuario no tiene acceso a la empresa/sucursal seleccionada",
    });
  }

  const token = signJwt({
    sub: record.Cod_Usuario,
    name: record.Nombre,
    tipo: record.Tipo,
    isAdmin,
    permisos,
    modulos: allowedModules,
    companyId: activeCompany.companyId,
    companyCode: activeCompany.companyCode,
    companyName: activeCompany.companyName,
    branchId: activeCompany.branchId,
    branchCode: activeCompany.branchCode,
    branchName: activeCompany.branchName,
    countryCode: activeCompany.countryCode,
    timeZone: activeCompany.timeZone,
    companyAccesses,
  });

  await registerLoginSuccess(record.Cod_Usuario);

  return res.json({
    token,
    userId: record.Cod_Usuario,
    userName: record.Nombre,
    email: null,
    isAdmin,
    permisos,
    modulos: allowedModules,
    company: activeCompany,
    companyAccesses,
    usuario: {
      codUsuario: record.Cod_Usuario,
      nombre: record.Nombre,
      tipo: record.Tipo,
      isAdmin,
    },
  });
});

// --- GET /v1/auth/companies -----------------------------------
authRouter.get("/companies", async (req, res) => {
  const user = (req as Request & { user?: JwtPayload }).user;
  if (!user?.sub) {
    return res.status(401).json({ error: "not_authenticated" });
  }

  const companyAccesses =
    user.companyAccesses && user.companyAccesses.length > 0
      ? user.companyAccesses
      : await getUserCompanyAccesses(user.sub, Boolean(user.isAdmin));

  const activeCompany = resolveActiveCompanyAccess(
    companyAccesses,
    user.companyId,
    user.branchId
  );

  return res.json({
    rows: companyAccesses,
    active: activeCompany,
  });
});

// --- POST /v1/auth/switch-company -----------------------------
authRouter.post("/switch-company", async (req, res) => {
  const user = (req as Request & { user?: JwtPayload }).user;
  if (!user?.sub) {
    return res.status(401).json({ error: "not_authenticated" });
  }

  const parsed = switchCompanySchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  }

  const companyAccesses = await getUserCompanyAccesses(user.sub, Boolean(user.isAdmin));
  const activeCompany = resolveActiveCompanyAccess(
    companyAccesses,
    parsed.data.companyId,
    parsed.data.branchId
  );

  if (!activeCompany) {
    return res.status(403).json({
      error: "invalid_company_scope",
      message: "El usuario no tiene acceso a la empresa/sucursal seleccionada",
    });
  }

  const token = signJwt({
    sub: user.sub,
    name: user.name,
    tipo: user.tipo,
    isAdmin: user.isAdmin,
    permisos: user.permisos,
    modulos: user.modulos,
    companyId: activeCompany.companyId,
    companyCode: activeCompany.companyCode,
    companyName: activeCompany.companyName,
    branchId: activeCompany.branchId,
    branchCode: activeCompany.branchCode,
    branchName: activeCompany.branchName,
    countryCode: activeCompany.countryCode,
    timeZone: activeCompany.timeZone,
    companyAccesses,
  });

  return res.json({ token, company: activeCompany, companyAccesses });
});

// --- POST /v1/auth/change-password ----------------------------
authRouter.post("/change-password", async (req, res) => {
  const user = (req as Request & { user?: JwtPayload }).user;
  if (!user?.sub) {
    return res.status(401).json({ error: "not_authenticated" });
  }

  const parsed = changePasswordSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  }

  const result = await changePassword(
    user.sub,
    parsed.data.currentPassword,
    parsed.data.newPassword
  );

  if (!result.success) {
    return res.status(400).json({ success: false, message: result.message });
  }
  return res.json(result);
});

// --- POST /v1/auth/reset-password (admin only) ---------------
authRouter.post("/reset-password", async (req, res) => {
  const user = (req as Request & { user?: JwtPayload }).user;
  if (!user?.isAdmin) {
    return res.status(403).json({ error: "forbidden", message: "Solo administradores" });
  }

  const parsed = resetPasswordSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  }

  const result = await resetPassword(parsed.data.codUsuario, parsed.data.newPassword);
  if (!result.success) {
    return res.status(400).json({ success: false, message: result.message });
  }
  return res.json(result);
});

// --- GET /v1/auth/me ------------------------------------------
authRouter.get("/me", async (req, res) => {
  const user = (req as Request & { user?: JwtPayload }).user;
  if (!user?.sub) {
    return res.status(401).json({ error: "not_authenticated" });
  }
  return res.json({
    codUsuario: user.sub,
    nombre: user.name,
    tipo: user.tipo,
    isAdmin: user.isAdmin,
    permisos: user.permisos,
    modulos: user.modulos,
    company: {
      companyId: user.companyId,
      companyCode: user.companyCode,
      companyName: user.companyName,
      branchId: user.branchId,
      branchCode: user.branchCode,
      branchName: user.branchName,
      countryCode: user.countryCode,
      timeZone: user.timeZone,
    },
    companyAccesses: user.companyAccesses ?? [],
  });
});
