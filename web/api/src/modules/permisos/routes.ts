/**
 * Rutas de Permisos (RBAC) — Permisos Granulares, Restricciones de Precio,
 * Reglas de Aprobacion, Solicitudes de Aprobacion.
 *
 * Montado en /v1/permisos
 */
import { Router, Request, Response } from "express";
import { z } from "zod";
import * as svc from "./service.js";

export const permisosRouter = Router();

// ─── Helper ────────────────────────────────────────────────
function getUserId(req: Request): number {
  return (req as any).user?.userId ?? (req as any).user?.id ?? 0;
}

// ═══════════════════════════════════════════════════════════════
// PERMISOS (Catalogo)
// ═══════════════════════════════════════════════════════════════

// GET /v1/permisos/permisos
permisosRouter.get("/permisos", async (req: Request, res: Response) => {
  try {
    const rows = await svc.listPermissions(req.query.moduleCode as string);
    res.json({ rows });
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// POST /v1/permisos/permisos/seed
permisosRouter.post("/permisos/seed", async (_req: Request, res: Response) => {
  try {
    const result = await svc.seedPermissions();
    res.json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// ═══════════════════════════════════════════════════════════════
// PERMISOS POR ROL
// ═══════════════════════════════════════════════════════════════

// GET /v1/permisos/roles/:roleId/permisos
permisosRouter.get("/roles/:roleId/permisos", async (req: Request, res: Response) => {
  try {
    const rows = await svc.listRolePermissions(Number(req.params.roleId));
    res.json({ rows });
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// POST /v1/permisos/roles/:roleId/permisos
const setPermissionSchema = z.object({
  permissionId: z.number().int(),
  branchId: z.number().int().optional(),
  isGranted: z.boolean(),
});

permisosRouter.post("/roles/:roleId/permisos", async (req: Request, res: Response) => {
  const parsed = setPermissionSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  }
  try {
    const result = await svc.setRolePermission({
      roleId: Number(req.params.roleId),
      ...parsed.data,
      userId: getUserId(req),
    });
    res.status(result.success ? 200 : 400).json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// POST /v1/permisos/roles/:roleId/permisos/bulk
const bulkPermissionSchema = z.object({
  permissions: z.array(z.object({
    permissionId: z.number().int(),
    branchId: z.number().int().optional(),
    isGranted: z.boolean(),
  })),
});

permisosRouter.post("/roles/:roleId/permisos/bulk", async (req: Request, res: Response) => {
  const parsed = bulkPermissionSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  }
  try {
    const result = await svc.bulkSetRolePermissions({
      roleId: Number(req.params.roleId),
      ...parsed.data,
      userId: getUserId(req),
    });
    res.status(result.success ? 200 : 400).json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// ═══════════════════════════════════════════════════════════════
// PERMISOS DE USUARIO (Overrides)
// ═══════════════════════════════════════════════════════════════

// GET /v1/permisos/usuarios/:userId/permisos
permisosRouter.get("/usuarios/:userId/permisos", async (req: Request, res: Response) => {
  try {
    const rows = await svc.listUserPermissions(Number(req.params.userId));
    res.json({ rows });
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// POST /v1/permisos/usuarios/:userId/permisos/override
const overrideSchema = z.object({
  permissionId: z.number().int(),
  branchId: z.number().int().optional(),
  isGranted: z.boolean(),
});

permisosRouter.post("/usuarios/:userId/permisos/override", async (req: Request, res: Response) => {
  const parsed = overrideSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  }
  try {
    const result = await svc.overrideUserPermission({
      userId: Number(req.params.userId),
      ...parsed.data,
      adminUserId: getUserId(req),
    });
    res.status(result.success ? 200 : 400).json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// GET /v1/permisos/usuarios/:userId/verificar/:permissionCode
permisosRouter.get("/usuarios/:userId/verificar/:permissionCode", async (req: Request, res: Response) => {
  try {
    const result = await svc.checkUserPermission(
      Number(req.params.userId),
      req.params.permissionCode
    );
    res.json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// ═══════════════════════════════════════════════════════════════
// RESTRICCIONES DE PRECIO
// ═══════════════════════════════════════════════════════════════

// GET /v1/permisos/precios
permisosRouter.get("/precios", async (_req: Request, res: Response) => {
  try {
    const rows = await svc.listPriceRestrictions();
    res.json({ rows });
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// POST /v1/permisos/precios
const priceRestrictionSchema = z.object({
  restrictionId: z.number().int().optional(),
  roleId: z.number().int().optional(),
  userIdTarget: z.number().int().optional(),
  maxDiscountPercent: z.number().min(0).max(100),
  minPricePercent: z.number().min(0).max(100),
  maxCreditLimit: z.number().optional(),
  requiresApprovalAbove: z.number().optional(),
});

permisosRouter.post("/precios", async (req: Request, res: Response) => {
  const parsed = priceRestrictionSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  }
  try {
    const result = await svc.upsertPriceRestriction({
      ...parsed.data,
      adminUserId: getUserId(req),
    });
    res.status(result.success ? 200 : 400).json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// GET /v1/permisos/precios/verificar/:userId
permisosRouter.get("/precios/verificar/:userId", async (req: Request, res: Response) => {
  try {
    const result = await svc.checkPriceRestriction(Number(req.params.userId));
    if (!result) return res.status(404).json({ error: "no_restriction" });
    res.json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// ═══════════════════════════════════════════════════════════════
// REGLAS DE APROBACION
// ═══════════════════════════════════════════════════════════════

// GET /v1/permisos/reglas-aprobacion
permisosRouter.get("/reglas-aprobacion", async (req: Request, res: Response) => {
  try {
    const rows = await svc.listApprovalRules(req.query.moduleCode as string);
    res.json({ rows });
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// POST /v1/permisos/reglas-aprobacion
const approvalRuleSchema = z.object({
  approvalRuleId: z.number().int().optional(),
  moduleCode: z.string().min(1),
  documentType: z.string().min(1),
  minAmount: z.number().min(0),
  maxAmount: z.number().optional(),
  requiredRoleId: z.number().int(),
  approvalLevels: z.number().int().min(1),
  isActive: z.boolean().optional(),
});

permisosRouter.post("/reglas-aprobacion", async (req: Request, res: Response) => {
  const parsed = approvalRuleSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  }
  try {
    const result = await svc.upsertApprovalRule({ ...parsed.data, userId: getUserId(req) });
    res.status(result.success ? 200 : 400).json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// ═══════════════════════════════════════════════════════════════
// SOLICITUDES DE APROBACION
// ═══════════════════════════════════════════════════════════════

// GET /v1/permisos/aprobaciones
permisosRouter.get("/aprobaciones", async (req: Request, res: Response) => {
  try {
    const result = await svc.listApprovalRequests({
      status: req.query.status as string,
      moduleCode: req.query.moduleCode as string,
      page: req.query.page ? parseInt(req.query.page as string) : 1,
      limit: req.query.limit ? parseInt(req.query.limit as string) : 50,
    });
    res.json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// POST /v1/permisos/aprobaciones
const approvalRequestSchema = z.object({
  documentModule: z.string().min(1),
  documentType: z.string().min(1),
  documentNumber: z.string().min(1),
  documentAmount: z.number().min(0),
});

permisosRouter.post("/aprobaciones", async (req: Request, res: Response) => {
  const parsed = approvalRequestSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  }
  try {
    const result = await svc.createApprovalRequest({
      ...parsed.data,
      requestedByUserId: getUserId(req),
    });
    res.status(result.success ? 201 : 400).json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// POST /v1/permisos/aprobaciones/:id/accion
const approvalActionSchema = z.object({
  action: z.enum(["APPROVE", "REJECT"]),
  comments: z.string().optional(),
});

permisosRouter.post("/aprobaciones/:id/accion", async (req: Request, res: Response) => {
  const parsed = approvalActionSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  }
  try {
    const result = await svc.actOnApprovalRequest({
      approvalRequestId: Number(req.params.id),
      actionByUserId: getUserId(req),
      ...parsed.data,
    });
    res.status(result.success ? 200 : 400).json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// GET /v1/permisos/aprobaciones/:id
permisosRouter.get("/aprobaciones/:id", async (req: Request, res: Response) => {
  try {
    const result = await svc.getApprovalRequest(Number(req.params.id));
    if (!result) return res.status(404).json({ error: "not_found" });
    res.json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});
