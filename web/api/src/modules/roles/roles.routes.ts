import { Router } from "express";
import { z } from "zod";
import * as svc from "./roles.service.js";
import { checkUserLimit, checkCompanyLimit } from "../license/license-enforcement.service.js";

export const rolesRouter = Router();

// GET /v1/roles
rolesRouter.get("/", async (_req, res) => {
  try {
    const rows = await svc.listRoles();
    return res.json({ rows });
  } catch (err: any) {
    return res.status(500).json({ error: "internal", message: err.message ?? String(err) });
  }
});

// POST /v1/roles
const upsertSchema = z.object({
  roleId: z.number().optional(),
  roleCode: z.string().min(1),
  roleName: z.string().min(1),
  isActive: z.boolean().optional(),
});

rolesRouter.post("/", async (req, res) => {
  try {
    const parsed = upsertSchema.safeParse(req.body);
    if (!parsed.success) {
      return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
    }
    const result = await svc.upsertRole(parsed.data);
    return res.status(result.success ? 201 : 400).json(result);
  } catch (err: any) {
    return res.status(500).json({ error: "internal", message: err.message ?? String(err) });
  }
});

// DELETE /v1/roles/:id
rolesRouter.delete("/:id", async (req, res) => {
  try {
    const roleId = Number(req.params.id);
    if (!Number.isFinite(roleId) || roleId <= 0) {
      return res.status(400).json({ error: "invalid_id" });
    }
    const result = await svc.deleteRole(roleId);
    return res.json(result);
  } catch (err: any) {
    return res.status(500).json({ error: "internal", message: err.message ?? String(err) });
  }
});

// GET /v1/roles/usuarios/:userId
rolesRouter.get("/usuarios/:userId", async (req, res) => {
  try {
    const userId = Number(req.params.userId);
    if (!Number.isFinite(userId) || userId <= 0) {
      return res.status(400).json({ error: "invalid_user_id" });
    }
    const rows = await svc.listUserRoles(userId);
    return res.json({ rows });
  } catch (err: any) {
    return res.status(500).json({ error: "internal", message: err.message ?? String(err) });
  }
});

// POST /v1/roles/usuarios/:userId
const setUserRolesSchema = z.object({
  roleIds: z.array(z.number()),
});

rolesRouter.post("/usuarios/:userId", async (req, res) => {
  try {
    const userId = Number(req.params.userId);
    if (!Number.isFinite(userId) || userId <= 0) {
      return res.status(400).json({ error: "invalid_user_id" });
    }
    const parsed = setUserRolesSchema.safeParse(req.body);
    if (!parsed.success) {
      return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
    }
    const result = await svc.setUserRoles(userId, parsed.data.roleIds);
    return res.json(result);
  } catch (err: any) {
    return res.status(500).json({ error: "internal", message: err.message ?? String(err) });
  }
});

// GET /v1/roles/license/limits  (license limits for current tenant)
rolesRouter.get("/license/limits", async (_req, res) => {
  try {
    const userLimit = await checkUserLimit();
    const companyLimit = await checkCompanyLimit();
    return res.json({ users: userLimit, companies: companyLimit });
  } catch (err: any) {
    return res.status(500).json({ error: "internal", message: err.message ?? String(err) });
  }
});
