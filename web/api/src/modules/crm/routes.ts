/**
 * CRM Routes — /v1/crm
 *
 * Pipelines, Leads, Activities, Dashboard
 */
import { Router, Request, Response } from "express";
import * as svc from "./service.js";
import { callCenterRouter } from "./callcenter.routes.js";
import { crmAnalyticsRouter } from "./analytics.routes.js";
import { crmScoringRouter } from "./scoring.routes.js";
import { crmAutomationRouter } from "./automation.routes.js";
import { crmReportsRouter } from "./reports.routes.js";
import { publicApiKeysRouter } from "./public-api-keys/routes.js";
import { webhooksRouter } from "./webhooks/routes.js";
import { savedViewRouter } from "./savedView.routes.js";
import { contactsDealsRouter } from "./contactsDeals.routes.js";
import { obs } from "../integrations/observability.js";

export const crmRouter = Router();

// ── Mount sub-routers ────────────────────────────────────────────────────────
crmRouter.use("/", callCenterRouter);
crmRouter.use("/analytics", crmAnalyticsRouter);
crmRouter.use("/", crmScoringRouter);
crmRouter.use("/", crmAutomationRouter);
crmRouter.use("/reports", crmReportsRouter);
crmRouter.use("/public-keys", publicApiKeysRouter);
crmRouter.use("/webhooks", webhooksRouter);
crmRouter.use("/saved-views", savedViewRouter);
// ADR-CRM-001: Companies / Contacts / Deals + Lead convert
crmRouter.use("/", contactsDealsRouter);

// ── Helper ───────────────────────────────────────────────────────────────────

function userId(req: Request): number {
  return (req as any).user?.userId ?? (req as any).user?.id ?? 0;
}

function intOrNull(v: unknown): number | null {
  if (v === undefined || v === null || v === "") return null;
  const n = Number(v);
  return Number.isFinite(n) ? n : null;
}

// ═══════════════════════════════════════════════════════════════════════════════
//  PIPELINES
// ═══════════════════════════════════════════════════════════════════════════════

crmRouter.get("/pipelines", async (_req: Request, res: Response) => {
  try {
    const rows = await svc.listPipelines();
    res.json(rows);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

crmRouter.post("/pipelines", async (req: Request, res: Response) => {
  try {
    const result = await svc.upsertPipeline({ ...req.body, userId: userId(req) });
    res.status(result.success ? 200 : 400).json(result);
    if (result.success) {
      try { obs.event('crm.pipeline.created', { entityId: result.id, userId: (req as any).user?.userId, userName: (req as any).user?.userName, companyId: (req as any).user?.companyId, module: 'crm' }); } catch { /* never blocks */ }
    }
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

crmRouter.get("/pipelines/:id/stages", async (req: Request, res: Response) => {
  try {
    const rows = await svc.getStages(Number(req.params.id));
    res.json(rows);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

crmRouter.post("/pipelines/:id/stages", async (req: Request, res: Response) => {
  try {
    const result = await svc.upsertStage(Number(req.params.id), {
      ...req.body,
      userId: userId(req),
    });
    res.status(result.success ? 200 : 400).json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// ═══════════════════════════════════════════════════════════════════════════════
//  LEADS
// ═══════════════════════════════════════════════════════════════════════════════

crmRouter.get("/leads", async (req: Request, res: Response) => {
  try {
    const q = req.query;
    const result = await svc.listLeads({
      pipelineId: intOrNull(q.pipeline) ?? undefined,
      stageId: intOrNull(q.stage) ?? undefined,
      status: (q.status as string) || undefined,
      assignedToUserId: intOrNull(q.assigned) ?? undefined,
      source: (q.source as string) || undefined,
      priority: (q.priority as string) || undefined,
      search: (q.search as string) || undefined,
      page: q.page ? parseInt(q.page as string) : undefined,
      limit: q.limit ? parseInt(q.limit as string) : undefined,
    });
    res.json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

crmRouter.get("/leads/:id", async (req: Request, res: Response) => {
  try {
    const row = await svc.getLead(Number(req.params.id));
    if (!row) return res.status(404).json({ error: "not_found" });
    res.json(row);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

crmRouter.post("/leads", async (req: Request, res: Response) => {
  try {
    const result = await svc.createLead({ ...req.body, userId: userId(req) });
    res.status(result.success ? 201 : 400).json(result);
    if (result.success) {
      try { obs.event('crm.lead.created', { entityId: result.id, userId: (req as any).user?.userId, userName: (req as any).user?.userName, companyId: (req as any).user?.companyId, module: 'crm' }); } catch { /* never blocks */ }
    }
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

crmRouter.put("/leads/:id", async (req: Request, res: Response) => {
  try {
    const result = await svc.updateLead(Number(req.params.id), {
      ...req.body,
      userId: userId(req),
    });
    res.status(result.success ? 200 : 400).json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

crmRouter.post("/leads/:id/cambiar-etapa", async (req: Request, res: Response) => {
  try {
    const result = await svc.changeLeadStage(Number(req.params.id), {
      ...req.body,
      userId: userId(req),
    });
    res.status(result.success ? 200 : 400).json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

crmRouter.post("/leads/:id/cerrar", async (req: Request, res: Response) => {
  try {
    const result = await svc.closeLead(Number(req.params.id), {
      ...req.body,
      userId: userId(req),
    });
    res.status(result.success ? 200 : 400).json(result);
    if (result.success) {
      try { obs.audit('crm.lead.converted', { userId: (req as any).user?.userId, userName: (req as any).user?.userName, companyId: (req as any).user?.companyId, module: 'crm', entity: 'Lead', entityId: Number(req.params.id) }); } catch { /* never blocks */ }
    }
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// ═══════════════════════════════════════════════════════════════════════════════
//  ACTIVIDADES
// ═══════════════════════════════════════════════════════════════════════════════

crmRouter.get("/actividades", async (req: Request, res: Response) => {
  try {
    const q = req.query;
    const result = await svc.listActivities({
      leadId: intOrNull(q.lead) ?? undefined,
      customerId: intOrNull(q.customer) ?? undefined,
      isCompleted: q.completed === "true" ? true : q.completed === "false" ? false : undefined,
      dueBefore: (q.dueBefore as string) || undefined,
      page: q.page ? parseInt(q.page as string) : undefined,
      limit: q.limit ? parseInt(q.limit as string) : undefined,
    });
    res.json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

crmRouter.post("/actividades", async (req: Request, res: Response) => {
  try {
    const result = await svc.createActivity({ ...req.body, userId: userId(req) });
    res.status(result.success ? 201 : 400).json(result);
    if (result.success) {
      try { obs.event('crm.activity.created', { entityId: result.id, userId: (req as any).user?.userId, userName: (req as any).user?.userName, companyId: (req as any).user?.companyId, module: 'crm' }); } catch { /* never blocks */ }
    }
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

crmRouter.post("/actividades/:id/completar", async (req: Request, res: Response) => {
  try {
    const result = await svc.completeActivity(Number(req.params.id), userId(req));
    res.status(result.success ? 200 : 400).json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

crmRouter.put("/actividades/:id", async (req: Request, res: Response) => {
  try {
    const result = await svc.updateActivity(Number(req.params.id), {
      ...req.body,
      userId: userId(req),
    });
    res.status(result.success ? 200 : 400).json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// ═══════════════════════════════════════════════════════════════════════════════
//  DASHBOARD
// ═══════════════════════════════════════════════════════════════════════════════

crmRouter.get("/dashboard", async (req: Request, res: Response) => {
  try {
    const rows = await svc.getDashboard(intOrNull(req.query.pipeline) ?? undefined);
    res.json(rows);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});
