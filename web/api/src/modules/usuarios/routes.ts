import { Router } from "express";
import { z } from "zod";
import {
  listUsuariosSP,
  getUsuarioByCodigoSP,
  insertUsuarioSP,
  updateUsuarioSP,
  deleteUsuarioSP,
} from "./usuarios-sp.service.js";
import {
  getModulosAcceso,
  setModulosAcceso,
  ensureUserDefaultCompanyAccess,
  changePassword,
  getUserAvatar,
  setUserAvatar,
} from "./usuarios.service.js";
import { hashPassword } from "../../auth/password.js";
import { setModulosSchema, SYSTEM_MODULES } from "./types.js";
import type { JwtPayload } from "../../auth/jwt.js";
import type { Request } from "express";

export const usuariosRouter = Router();

const listSchema = z.object({
  search: z.string().optional(),
  tipo: z.string().optional(),
  page: z.string().optional(),
  limit: z.string().optional(),
});

// Helper: coerce any truthy/falsy value to boolean (handles true/false, 1/0, "true"/"false")
const zBool = z.preprocess((v) => {
  if (typeof v === 'boolean') return v;
  if (typeof v === 'number') return v !== 0;
  if (typeof v === 'string') return v.toLowerCase() === 'true' || v === '1';
  return Boolean(v);
}, z.boolean());

const insertSchema = z.object({
  Cod_Usuario: z.string().min(1),
  Password: z.string().optional(),
  Nombre: z.string().optional(),
  Tipo: z.string().optional(),
  Updates: zBool.optional(),
  Addnews: zBool.optional(),
  Deletes: zBool.optional(),
  Creador: zBool.optional(),
  Cambiar: zBool.optional(),
  PrecioMinimo: zBool.optional(),
  Credito: zBool.optional(),
}).passthrough();

const updateSchema = z.object({
  Password: z.string().optional(),
  Nombre: z.string().optional(),
  Tipo: z.string().optional(),
  Updates: zBool.optional(),
  Addnews: zBool.optional(),
  Deletes: zBool.optional(),
  Creador: zBool.optional(),
  Cambiar: zBool.optional(),
  PrecioMinimo: zBool.optional(),
  Credito: zBool.optional(),
}).passthrough();

// ─── Self-service routes (any authenticated user) ─────────────
// These routes are placed BEFORE requireAdmin so any user can access them.

/** GET /v1/usuarios/me – own profile */
usuariosRouter.get("/me", async (req, res) => {
  try {
    const user = (req as Request & { user?: JwtPayload }).user;
    if (!user?.sub) return res.status(401).json({ error: "unauthorized" });
    const record = await getUsuarioByCodigoSP(user.sub);
    if (!record) return res.status(404).json({ error: "not_found" });
    // Strip password from response
    const { Password, ...safe } = record as Record<string, unknown>;
    void Password;
    // Avatar is fetched separately – returns null if column not yet migrated
    const avatar = await getUserAvatar(user.sub);
    return res.json({ ...safe, Avatar: avatar });
  } catch (err: unknown) {
    return res.status(500).json({ error: "internal", message: err instanceof Error ? err.message : String(err) });
  }
});

/** POST /v1/usuarios/me/avatar – upload or remove own avatar */
usuariosRouter.post("/me/avatar", async (req, res) => {
  try {
    const user = (req as Request & { user?: JwtPayload }).user;
    if (!user?.sub) return res.status(401).json({ error: "unauthorized" });
    const { avatar } = z.object({
      avatar: z.string().nullable(),
    }).parse(req.body);
    // Validate data URL format when provided
    if (avatar !== null && !avatar.startsWith("data:image/")) {
      return res.status(400).json({ error: "bad_request", message: "avatar must be a data:image/ URL" });
    }
    // Enforce a reasonable size limit (~300 KB base64)
    if (avatar && avatar.length > 400_000) {
      return res.status(413).json({ error: "too_large", message: "Avatar image too large. Max ~300 KB." });
    }
    await setUserAvatar(user.sub, avatar);
    return res.json({ ok: true });
  } catch (err: unknown) {
    return res.status(400).json({ error: "bad_request", message: err instanceof Error ? err.message : String(err) });
  }
});

/** PUT /v1/usuarios/me – update own display name */
usuariosRouter.put("/me", async (req, res) => {
  try {
    const user = (req as Request & { user?: JwtPayload }).user;
    if (!user?.sub) return res.status(401).json({ error: "unauthorized" });
    const { Nombre } = z.object({ Nombre: z.string().optional() }).parse(req.body);
    if (Nombre !== undefined) {
      await updateUsuarioSP(user.sub, { Nombre });
    }
    return res.json({ ok: true });
  } catch (err: unknown) {
    return res.status(400).json({ error: "bad_request", message: err instanceof Error ? err.message : String(err) });
  }
});

/** POST /v1/usuarios/me/change-password – change own password */
usuariosRouter.post("/me/change-password", async (req, res) => {
  try {
    const user = (req as Request & { user?: JwtPayload }).user;
    if (!user?.sub) return res.status(401).json({ error: "unauthorized" });
    const { currentPassword, newPassword } = z.object({
      currentPassword: z.string().min(1),
      newPassword: z.string().min(4),
    }).parse(req.body);
    const result = await changePassword(user.sub, currentPassword, newPassword);
    return res.json(result);
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : String(err);
    if (msg.includes("invalid") || msg.includes("password") || msg.includes("Password")) {
      return res.status(400).json({ error: "invalid_password", message: msg });
    }
    return res.status(400).json({ error: "bad_request", message: msg });
  }
});

// ─── Middleware: require admin ─────────────────────────────────
function requireAdmin(req: Request, res: any, next: any) {
  const user = (req as Request & { user?: JwtPayload }).user;
  if (!user?.isAdmin) {
    return res.status(403).json({ error: "forbidden", message: "Solo administradores pueden gestionar usuarios" });
  }
  next();
}

// Apply admin check to all usuario management routes
usuariosRouter.use(requireAdmin);

// GET /v1/usuarios - Listar usuarios
usuariosRouter.get("/", async (req, res) => {
  const parsed = listSchema.safeParse(req.query);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_query", issues: parsed.error.flatten() });
  }

  const data = await listUsuariosSP({
    search: parsed.data.search,
    tipo: parsed.data.tipo,
    page: parsed.data.page ? parseInt(parsed.data.page) : 1,
    limit: parsed.data.limit ? parseInt(parsed.data.limit) : 50,
  });

  // Strip passwords from response
  const sanitized = {
    ...data,
    rows: data.rows.map(({ Password, ...rest }) => rest),
  };

  return res.json(sanitized);
});

// GET /v1/usuarios/modules - Get all available system modules
usuariosRouter.get("/modules", async (_req, res) => {
  return res.json({ modulos: SYSTEM_MODULES });
});

// GET /v1/usuarios/:codigo - Obtener usuario por código
usuariosRouter.get("/:codigo", async (req, res) => {
  const codigo = req.params.codigo;
  if (!codigo) return res.status(400).json({ error: "invalid_codigo" });

  const data = await getUsuarioByCodigoSP(codigo);
  if (!data) return res.status(404).json({ error: "not_found" });

  // Get module access
  const modulosAcceso = await getModulosAcceso(codigo);

  // Strip password from response
  const { Password, ...safe } = data;
  return res.json({ ...safe, modulosAcceso });
});

// POST /v1/usuarios - Crear usuario (hash password)
usuariosRouter.post("/", async (req, res) => {
  const parsed = insertSchema.safeParse(req.body);
  if (!parsed.success) {
    const flat = parsed.error.flatten();
    const fieldList = Object.entries(flat.fieldErrors).map(([k, v]) => `${k}: ${(v as string[]).join(', ')}`).join('; ');
    return res.status(400).json({ error: "invalid_payload", message: fieldList || "Datos inválidos", issues: flat });
  }

  // Map isAdmin → IsAdmin (DB column name)
  const { isAdmin, ...spFields } = parsed.data as Record<string, unknown>;
  const row: Record<string, unknown> = { ...spFields };
  if (isAdmin !== undefined) {
    row.IsAdmin = isAdmin;
  }

  // Hash password before storing
  if (row.Password && typeof row.Password === 'string') {
    row.Password = await hashPassword(row.Password);
  }

  const result = await insertUsuarioSP(row);
  if (result.success) {
    await ensureUserDefaultCompanyAccess(String(row.Cod_Usuario ?? ""));
    return res.status(201).json({ success: true, message: result.message });
  } else {
    return res.status(400).json({ success: false, message: result.message });
  }
});

// PUT /v1/usuarios/:codigo - Actualizar usuario
usuariosRouter.put("/:codigo", async (req, res) => {
  const codigo = req.params.codigo;
  if (!codigo) return res.status(400).json({ error: "invalid_codigo" });

  const parsed = updateSchema.safeParse(req.body);
  if (!parsed.success) {
    const flat = parsed.error.flatten();
    console.error("PUT /usuarios/:codigo validation error:", JSON.stringify(flat));
    const fieldList = Object.entries(flat.fieldErrors).map(([k, v]) => `${k}: ${(v as string[]).join(', ')}`).join('; ');
    return res.status(400).json({ error: "invalid_payload", message: fieldList || "Datos inválidos", issues: flat });
  }

  // Map isAdmin → IsAdmin (DB column name)
  const { isAdmin, ...spFields } = parsed.data as Record<string, unknown>;
  if (isAdmin !== undefined) {
    (spFields as Record<string, unknown>).IsAdmin = isAdmin;
  }

  // Hash password if provided, otherwise remove empty password
  const row: Record<string, unknown> = { ...spFields };
  if (row.Password && typeof row.Password === 'string' && row.Password.trim() !== '') {
    row.Password = await hashPassword(row.Password);
  } else {
    delete row.Password;
  }

  try {
    const result = await updateUsuarioSP(codigo, row);
    if (result.success) {
      return res.json({ success: true, message: result.message });
    } else {
      return res.status(400).json({ success: false, message: result.message });
    }
  } catch (err: any) {
    console.error("Error updating usuario:", err);
    return res.status(500).json({ success: false, message: err.message || "Error interno al actualizar usuario" });
  }
});

// DELETE /v1/usuarios/:codigo - Eliminar usuario
usuariosRouter.delete("/:codigo", async (req, res) => {
  const codigo = req.params.codigo;
  if (!codigo) return res.status(400).json({ error: "invalid_codigo" });

  const result = await deleteUsuarioSP(codigo);
  if (result.success) {
    return res.json({ success: true, message: result.message });
  } else {
    return res.status(400).json({ success: false, message: result.message });
  }
});

// GET /v1/usuarios/:codigo/modulos - Get user module access
usuariosRouter.get("/:codigo/modulos", async (req, res) => {
  const codigo = req.params.codigo;
  if (!codigo) return res.status(400).json({ error: "invalid_codigo" });

  const modulos = await getModulosAcceso(codigo);
  return res.json({ modulos, available: SYSTEM_MODULES });
});

// PUT /v1/usuarios/:codigo/modulos - Set user module access
usuariosRouter.put("/:codigo/modulos", async (req, res) => {
  const codigo = req.params.codigo;
  if (!codigo) return res.status(400).json({ error: "invalid_codigo" });

  const parsed = setModulosSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  }

  await setModulosAcceso(codigo, parsed.data.modulos);
  return res.json({ success: true, message: "Acceso a módulos actualizado" });
});
