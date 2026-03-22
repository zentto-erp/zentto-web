/**
 * Call Center Routes — /v1/crm/call-center
 *
 * Colas, Agentes, Llamadas, Scripts, Campanas, Dashboard
 */
import { Router, Request, Response } from "express";
import * as svc from "./callcenter.service.js";

export const callCenterRouter = Router();

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
//  COLAS
// ═══════════════════════════════════════════════════════════════════════════════

callCenterRouter.get("/call-center/colas", async (_req: Request, res: Response) => {
  try {
    const rows = await svc.listQueues();
    res.json(rows);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

callCenterRouter.post("/call-center/colas", async (req: Request, res: Response) => {
  try {
    const result = await svc.upsertQueue({ ...req.body, userId: userId(req) });
    res.status(result.success ? 200 : 400).json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// ═══════════════════════════════════════════════════════════════════════════════
//  AGENTES
// ═══════════════════════════════════════════════════════════════════════════════

callCenterRouter.get("/call-center/agentes", async (req: Request, res: Response) => {
  try {
    const q = req.query;
    const result = await svc.listAgents({
      queueId: intOrNull(q.queue) ?? undefined,
      status: (q.status as string) || undefined,
      page: q.page ? parseInt(q.page as string) : undefined,
      limit: q.limit ? parseInt(q.limit as string) : undefined,
    });
    res.json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

callCenterRouter.post("/call-center/agentes", async (req: Request, res: Response) => {
  try {
    const result = await svc.upsertAgent({ ...req.body, adminUserId: userId(req) });
    res.status(result.success ? 200 : 400).json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

callCenterRouter.patch("/call-center/agentes/:id/estado", async (req: Request, res: Response) => {
  try {
    const result = await svc.updateAgentStatus(Number(req.params.id), req.body.status);
    res.status(result.success ? 200 : 400).json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// ═══════════════════════════════════════════════════════════════════════════════
//  LLAMADAS
// ═══════════════════════════════════════════════════════════════════════════════

callCenterRouter.get("/call-center/llamadas", async (req: Request, res: Response) => {
  try {
    const q = req.query;
    if (!q.fechaDesde || !q.fechaHasta) {
      return res.status(400).json({ error: "fechaDesde y fechaHasta son requeridos" });
    }
    const result = await svc.listCalls({
      agentId: intOrNull(q.agent) ?? undefined,
      queueId: intOrNull(q.queue) ?? undefined,
      direction: (q.direction as string) || undefined,
      result: (q.result as string) || undefined,
      customerCode: (q.customerCode as string) || undefined,
      fechaDesde: q.fechaDesde as string,
      fechaHasta: q.fechaHasta as string,
      page: q.page ? parseInt(q.page as string) : undefined,
      limit: q.limit ? parseInt(q.limit as string) : undefined,
    });
    res.json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

callCenterRouter.get("/call-center/llamadas/:id", async (req: Request, res: Response) => {
  try {
    const row = await svc.getCall(Number(req.params.id));
    if (!row) return res.status(404).json({ error: "not_found" });
    res.json(row);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

callCenterRouter.post("/call-center/llamadas", async (req: Request, res: Response) => {
  try {
    const result = await svc.createCall({ ...req.body, userId: userId(req) });
    res.status(result.success ? 201 : 400).json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// ═══════════════════════════════════════════════════════════════════════════════
//  SCRIPTS
// ═══════════════════════════════════════════════════════════════════════════════

callCenterRouter.get("/call-center/scripts", async (req: Request, res: Response) => {
  try {
    const rows = await svc.listScripts((req.query.queueType as string) || null);
    res.json(rows);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

callCenterRouter.post("/call-center/scripts", async (req: Request, res: Response) => {
  try {
    const result = await svc.upsertScript({ ...req.body, userId: userId(req) });
    res.status(result.success ? 200 : 400).json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// ═══════════════════════════════════════════════════════════════════════════════
//  CAMPANAS
// ═══════════════════════════════════════════════════════════════════════════════

callCenterRouter.get("/call-center/campanas", async (req: Request, res: Response) => {
  try {
    const q = req.query;
    const result = await svc.listCampaigns({
      status: (q.status as string) || undefined,
      page: q.page ? parseInt(q.page as string) : undefined,
      limit: q.limit ? parseInt(q.limit as string) : undefined,
    });
    res.json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

callCenterRouter.get("/call-center/campanas/:id", async (req: Request, res: Response) => {
  try {
    const row = await svc.getCampaign(Number(req.params.id));
    if (!row) return res.status(404).json({ error: "not_found" });
    res.json(row);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

callCenterRouter.post("/call-center/campanas", async (req: Request, res: Response) => {
  try {
    const body = req.body;
    const result = await svc.createCampaign({
      ...body,
      contactsJson: body.contacts ? JSON.stringify(body.contacts) : null,
      userId: userId(req),
    });
    res.status(result.success ? 201 : 400).json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

callCenterRouter.patch("/call-center/campanas/:id/estado", async (req: Request, res: Response) => {
  try {
    const result = await svc.updateCampaignStatus(
      Number(req.params.id),
      req.body.status,
      userId(req),
    );
    res.status(result.success ? 200 : 400).json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

callCenterRouter.get("/call-center/campanas/:id/siguiente-contacto", async (req: Request, res: Response) => {
  try {
    const agentId = intOrNull(req.query.agent);
    if (!agentId) return res.status(400).json({ error: "agent es requerido" });
    const row = await svc.getNextContact(Number(req.params.id), agentId);
    if (!row) return res.status(404).json({ error: "no_contacts_available" });
    res.json(row);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

callCenterRouter.post("/call-center/campanas/contactos/:id/intento", async (req: Request, res: Response) => {
  try {
    const result = await svc.logAttempt({
      campaignContactId: Number(req.params.id),
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

callCenterRouter.get("/call-center/dashboard", async (req: Request, res: Response) => {
  try {
    const q = req.query;
    if (!q.fechaDesde || !q.fechaHasta) {
      return res.status(400).json({ error: "fechaDesde y fechaHasta son requeridos" });
    }
    const row = await svc.getDashboard(q.fechaDesde as string, q.fechaHasta as string);
    res.json(row || {});
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});
