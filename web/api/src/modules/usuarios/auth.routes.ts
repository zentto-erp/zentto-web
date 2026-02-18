import { Router } from "express";
import {
  loginSchema,
  changePasswordSchema,
  resetPasswordSchema,
  SYSTEM_MODULES,
} from "./types.js";
import {
  authenticateUsuario,
  extractPermisos,
  getModulosAcceso,
  changePassword,
  resetPassword,
} from "./usuarios.service.js";
import { signJwt, type JwtPayload } from "../../auth/jwt.js";
import type { Request } from "express";

export const authRouter = Router();

// ─── POST /v1/auth/login ──────────────────────────────────────
authRouter.post("/login", async (req, res) => {
  const parsed = loginSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  }

  const { usuario, clave } = parsed.data;
  const record = await authenticateUsuario(usuario, clave);

  if (!record) {
    return res.status(401).json({ error: "invalid_credentials" });
  }

  // Determine admin status
  const isAdmin =
    record.Tipo === "ADMIN" ||
    record.Tipo === "SUP" ||
    record.Cod_Usuario.toUpperCase() === "SUP";

  // Extract field-level permissions from Usuarios table
  const permisos = extractPermisos(record);

  // Get module-level access from AccesoUsuarios table
  const modulosAcceso = await getModulosAcceso(record.Cod_Usuario);

  // If admin → all modules allowed. Otherwise filter by AccesoUsuarios
  let allowedModules: string[];
  if (isAdmin) {
    allowedModules = [...SYSTEM_MODULES];
  } else if (modulosAcceso.length === 0) {
    // No explicit assignments → default modules (basic user)
    allowedModules = ["dashboard", "facturas", "clientes", "inventario", "articulos"];
  } else {
    allowedModules = modulosAcceso
      .filter((m) => m.permitido)
      .map((m) => m.modulo);
    // Always include dashboard
    if (!allowedModules.includes("dashboard")) {
      allowedModules.unshift("dashboard");
    }
  }

  const token = signJwt({
    sub: record.Cod_Usuario,
    name: record.Nombre,
    tipo: record.Tipo,
    isAdmin,
    permisos,
    modulos: allowedModules,
  });

  return res.json({
    token,
    userId: record.Cod_Usuario,
    userName: record.Nombre,
    email: null,
    isAdmin,
    permisos,
    modulos: allowedModules,
    usuario: {
      codUsuario: record.Cod_Usuario,
      nombre: record.Nombre,
      tipo: record.Tipo,
      isAdmin,
    },
  });
});

// ─── POST /v1/auth/change-password ────────────────────────────
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

// ─── POST /v1/auth/reset-password (admin only) ───────────────
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

// ─── GET /v1/auth/me ──────────────────────────────────────────
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
  });
});
