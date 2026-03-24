/**
 * CRM Automation Routes — /v1/crm/automations + /v1/crm/leads/stale
 */
import { Router, Request, Response } from "express";
import * as automationSvc from "./automation.service.js";

export const crmAutomationRouter = Router();

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
//  AUTOMATION RULES
// ═══════════════════════════════════════════════════════════════════════════════

crmAutomationRouter.get("/automations", async (_req: Request, res: Response) => {
  try {
    const rows = await automationSvc.listRules();
    res.json(rows);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

crmAutomationRouter.post("/automations", async (req: Request, res: Response) => {
  try {
    const result = await automationSvc.upsertRule({
      ...req.body,
      userId: userId(req),
    });
    res.status(result.success ? 201 : 400).json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

crmAutomationRouter.put("/automations/:id", async (req: Request, res: Response) => {
  try {
    const result = await automationSvc.upsertRule({
      ...req.body,
      ruleId: Number(req.params.id),
      userId: userId(req),
    });
    res.status(result.success ? 200 : 400).json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

crmAutomationRouter.delete("/automations/:id", async (req: Request, res: Response) => {
  try {
    const result = await automationSvc.deleteRule(Number(req.params.id), userId(req));
    res.status(result.success ? 200 : 400).json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// ═══════════════════════════════════════════════════════════════════════════════
//  EVALUATE — Trigger stale-lead detection + log actions
// ═══════════════════════════════════════════════════════════════════════════════

crmAutomationRouter.post("/automations/evaluate", async (req: Request, res: Response) => {
  try {
    const days = req.body.days ?? 7;
    const pipelineId = intOrNull(req.body.pipelineId) ?? undefined;

    const staleLeads = await automationSvc.findStaleLeads(days, pipelineId);

    let actionsLogged = 0;
    for (const lead of staleLeads as any[]) {
      const leadId = lead.LeadId ?? lead.leadId;
      if (!leadId) continue;
      try {
        await automationSvc.logAction(null, leadId, "STALE_DETECTED", `Stale ${days}d`);
        actionsLogged++;
      } catch {
        // skip individual failures
      }
    }

    res.json({ staleLeads, actionsLogged });
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// ═══════════════════════════════════════════════════════════════════════════════
//  AUTOMATION LOGS
// ═══════════════════════════════════════════════════════════════════════════════

crmAutomationRouter.get("/automations/logs", async (req: Request, res: Response) => {
  try {
    const q = req.query;
    const rows = await automationSvc.getAutomationLogs(
      intOrNull(q.rule),
      intOrNull(q.lead),
      intOrNull(q.limit) ?? 50,
    );
    res.json(rows);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// ═══════════════════════════════════════════════════════════════════════════════
//  STALE LEADS
// ═══════════════════════════════════════════════════════════════════════════════

crmAutomationRouter.get("/leads/stale", async (req: Request, res: Response) => {
  try {
    const q = req.query;
    const rows = await automationSvc.findStaleLeads(
      intOrNull(q.days) ?? 7,
      intOrNull(q.pipeline) ?? undefined,
    );
    res.json(rows);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});
