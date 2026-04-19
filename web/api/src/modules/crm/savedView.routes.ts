/**
 * savedView.routes.ts — CRM SavedView (CRM-108)
 *
 * Endpoints:
 *   GET    /v1/crm/saved-views?entity=LEAD
 *   GET    /v1/crm/saved-views/:id
 *   POST   /v1/crm/saved-views
 *   PATCH  /v1/crm/saved-views/:id
 *   DELETE /v1/crm/saved-views/:id
 *   POST   /v1/crm/saved-views/:id/default
 */
import { Router, Request, Response } from "express";
import { z } from "zod";
import * as svc from "./savedViewService.js";
import { obs } from "../integrations/observability.js";

export const savedViewRouter = Router();

// ── Helpers ──────────────────────────────────────────────────────────────────

function userId(req: Request): number {
  return (req as any).user?.userId ?? (req as any).user?.id ?? 0;
}

function auditCtx(req: Request) {
  return {
    userId: (req as any).user?.userId,
    userName: (req as any).user?.userName,
    companyId: (req as any).user?.companyId,
    module: "crm",
  };
}

const EntityEnum = z.enum(["LEAD", "CONTACT", "COMPANY", "DEAL", "ACTIVITY"]);

const JsonValue: z.ZodType<unknown> = z.lazy(() =>
  z.union([
    z.string(),
    z.number(),
    z.boolean(),
    z.null(),
    z.array(JsonValue),
    z.record(JsonValue),
  ]),
);

const CreateSchema = z.object({
  entity: EntityEnum,
  name: z.string().min(1).max(200),
  filterJson: z.union([z.record(JsonValue), z.array(JsonValue)]).optional().default({}),
  columnsJson: z.union([z.array(JsonValue), z.record(JsonValue), z.null()]).optional(),
  sortJson: z.union([z.array(JsonValue), z.record(JsonValue), z.null()]).optional(),
  isShared: z.boolean().optional().default(false),
  isDefault: z.boolean().optional().default(false),
});

const UpdateSchema = z.object({
  name: z.string().min(1).max(200).optional(),
  filterJson: z.union([z.record(JsonValue), z.array(JsonValue)]).optional(),
  columnsJson: z.union([z.array(JsonValue), z.record(JsonValue), z.null()]).optional(),
  sortJson: z.union([z.array(JsonValue), z.record(JsonValue), z.null()]).optional(),
  isShared: z.boolean().optional(),
  isDefault: z.boolean().optional(),
});

// ── GET /v1/crm/saved-views ──────────────────────────────────────────────────

savedViewRouter.get("/", async (req: Request, res: Response) => {
  try {
    const rawEntity = typeof req.query.entity === "string" ? req.query.entity.toUpperCase() : undefined;
    const entityParse = rawEntity ? EntityEnum.safeParse(rawEntity) : null;
    if (entityParse && !entityParse.success) {
      return res.status(400).json({ error: "invalid_entity", details: entityParse.error.flatten() });
    }

    const rows = await svc.listSavedViews(
      userId(req),
      entityParse?.success ? entityParse.data : undefined,
    );
    res.json({ rows, total: rows.length });
  } catch (err: any) {
    res.status(500).json({ error: String(err?.message ?? err) });
  }
});

// ── GET /v1/crm/saved-views/:id ──────────────────────────────────────────────

savedViewRouter.get("/:id", async (req: Request, res: Response) => {
  try {
    const id = Number(req.params.id);
    if (!Number.isFinite(id) || id <= 0) {
      return res.status(400).json({ error: "invalid_id" });
    }
    const row = await svc.getSavedView(userId(req), id);
    if (!row) return res.status(404).json({ error: "not_found" });
    res.json(row);
  } catch (err: any) {
    res.status(500).json({ error: String(err?.message ?? err) });
  }
});

// ── POST /v1/crm/saved-views (create) ────────────────────────────────────────

savedViewRouter.post("/", async (req: Request, res: Response) => {
  try {
    const parsed = CreateSchema.safeParse(req.body);
    if (!parsed.success) {
      return res.status(400).json({ error: "validation_error", details: parsed.error.flatten() });
    }

    const uid = userId(req);
    const result = await svc.upsertSavedView(uid, {
      viewId: null,
      entity: parsed.data.entity,
      name: parsed.data.name,
      filterJson: parsed.data.filterJson,
      columnsJson: parsed.data.columnsJson ?? null,
      sortJson: parsed.data.sortJson ?? null,
      isShared: parsed.data.isShared,
      isDefault: parsed.data.isDefault,
    });

    res.status(result.success ? 201 : 400).json(result);

    if (result.success) {
      try {
        obs.audit("crm.view.saved", {
          ...auditCtx(req),
          entity: "SavedView",
          entityId: result.viewId ?? undefined,
          extra: { entityType: parsed.data.entity, name: parsed.data.name, action: "created" },
        } as any);
      } catch { /* never blocks */ }
    }
  } catch (err: any) {
    res.status(500).json({ error: String(err?.message ?? err) });
  }
});

// ── PATCH /v1/crm/saved-views/:id (update) ───────────────────────────────────

savedViewRouter.patch("/:id", async (req: Request, res: Response) => {
  try {
    const id = Number(req.params.id);
    if (!Number.isFinite(id) || id <= 0) {
      return res.status(400).json({ error: "invalid_id" });
    }

    const parsed = UpdateSchema.safeParse(req.body);
    if (!parsed.success) {
      return res.status(400).json({ error: "validation_error", details: parsed.error.flatten() });
    }

    const uid = userId(req);
    const result = await svc.upsertSavedView(uid, {
      viewId: id,
      name: parsed.data.name,
      filterJson: parsed.data.filterJson,
      columnsJson: parsed.data.columnsJson,
      sortJson: parsed.data.sortJson,
      isShared: parsed.data.isShared,
      isDefault: parsed.data.isDefault,
    });

    res.status(result.success ? 200 : 400).json(result);

    if (result.success) {
      try {
        obs.audit("crm.view.saved", {
          ...auditCtx(req),
          entity: "SavedView",
          entityId: id,
          extra: { action: "updated" },
        } as any);
      } catch { /* never blocks */ }
    }
  } catch (err: any) {
    res.status(500).json({ error: String(err?.message ?? err) });
  }
});

// ── DELETE /v1/crm/saved-views/:id ───────────────────────────────────────────

savedViewRouter.delete("/:id", async (req: Request, res: Response) => {
  try {
    const id = Number(req.params.id);
    if (!Number.isFinite(id) || id <= 0) {
      return res.status(400).json({ error: "invalid_id" });
    }

    const result = await svc.deleteSavedView(userId(req), id);
    res.status(result.success ? 200 : 400).json(result);

    if (result.success) {
      try {
        obs.audit("crm.view.deleted", {
          ...auditCtx(req),
          entity: "SavedView",
          entityId: id,
        } as any);
      } catch { /* never blocks */ }
    }
  } catch (err: any) {
    res.status(500).json({ error: String(err?.message ?? err) });
  }
});

// ── POST /v1/crm/saved-views/:id/default ─────────────────────────────────────

savedViewRouter.post("/:id/default", async (req: Request, res: Response) => {
  try {
    const id = Number(req.params.id);
    if (!Number.isFinite(id) || id <= 0) {
      return res.status(400).json({ error: "invalid_id" });
    }

    const result = await svc.setDefaultSavedView(userId(req), id);
    res.status(result.success ? 200 : 400).json(result);

    if (result.success) {
      try {
        obs.audit("crm.view.saved", {
          ...auditCtx(req),
          entity: "SavedView",
          entityId: id,
          extra: { action: "set_default" },
        } as any);
      } catch { /* never blocks */ }
    }
  } catch (err: any) {
    res.status(500).json({ error: String(err?.message ?? err) });
  }
});
