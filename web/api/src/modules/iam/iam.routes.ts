/**
 * IAM Module — Combined router.
 *
 * Mounts all IAM sub-routers under /v1/iam/ and provides
 * a unified audit log endpoint.
 */
import { Router } from "express";
import { rolesRouter } from "../roles/roles.routes.js";
import { permisosRouter } from "../permisos/routes.js";
import { callSp } from "../../db/query.js";
import { getActiveScope } from "../_shared/scope.js";

export const iamRouter = Router();

// ── Sub-routers ─────────────────────────────────────────────────────────────

iamRouter.use("/roles", rolesRouter);
iamRouter.use("/permissions", permisosRouter);

// ── IAM Audit Log ───────────────────────────────────────────────────────────

iamRouter.get("/audit-log", async (req, res) => {
  try {
    const scope = getActiveScope();
    const companyId = scope?.companyId ?? 1;
    const rows = await callSp<any>("usp_Audit_IamChange_List", {
      CompanyId: companyId,
      ChangeType: (req.query.changeType as string) || null,
      EntityType: (req.query.entityType as string) || null,
      Page: req.query.page ? parseInt(req.query.page as string) : 1,
      Limit: req.query.limit ? parseInt(req.query.limit as string) : 50,
    });
    const total = rows[0]?.TotalCount ?? 0;
    return res.json({ rows, total });
  } catch (err: any) {
    return res.status(500).json({ error: "internal", message: err.message ?? String(err) });
  }
});

// ── IAM License Limits (unified) ────────────────────────────────────────────

iamRouter.get("/limits", async (_req, res) => {
  try {
    const scope = getActiveScope();
    const companyId = scope?.companyId ?? 1;
    const rows = await callSp<any>("usp_Sys_License_GetLimits", { CompanyId: companyId });
    return res.json(rows[0] ?? {});
  } catch (err: any) {
    return res.status(500).json({ error: "internal", message: err.message ?? String(err) });
  }
});
