/**
 * CRM Scoring / Detail / Timeline Routes
 *
 * Mounted at /v1/crm (sub-router)
 */
import { Router, Request, Response } from "express";
import * as scoringSvc from "./scoring.service.js";

export const crmScoringRouter = Router();

// ── Helper ───────────────────────────────────────────────────────────────────

function intOrNull(v: unknown): number | null {
  if (v === undefined || v === null || v === "") return null;
  const n = Number(v);
  return Number.isFinite(n) ? n : null;
}

function userId(req: Request): number {
  return (req as any).user?.userId ?? (req as any).user?.id ?? 0;
}

// ═══════════════════════════════════════════════════════════════════════════════
//  FIXED ROUTES (must come before :id params)
// ═══════════════════════════════════════════════════════════════════════════════

crmScoringRouter.get("/leads/timeline", async (req: Request, res: Response) => {
  try {
    const rows = await scoringSvc.getLeadTimeline(
      intOrNull(req.query.pipeline) ?? undefined,
      (req.query.status as string) || undefined,
    );
    res.json(rows);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

crmScoringRouter.post("/leads/score/bulk", async (_req: Request, res: Response) => {
  try {
    const result = await scoringSvc.bulkCalculateScores();
    res.status(result.success ? 200 : 400).json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// ═══════════════════════════════════════════════════════════════════════════════
//  PARAMETERIZED ROUTES (:id)
// ═══════════════════════════════════════════════════════════════════════════════

crmScoringRouter.get("/leads/:id/detail", async (req: Request, res: Response) => {
  try {
    const row = await scoringSvc.getLeadDetail(Number(req.params.id));
    if (!row) return res.status(404).json({ error: "not_found" });
    res.json(row);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

crmScoringRouter.get("/leads/:id/score", async (req: Request, res: Response) => {
  try {
    const row = await scoringSvc.getLeadScore(Number(req.params.id));
    if (!row) return res.status(404).json({ error: "not_found" });
    res.json(row);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

crmScoringRouter.post("/leads/:id/score", async (req: Request, res: Response) => {
  try {
    const result = await scoringSvc.calculateLeadScore(
      Number(req.params.id),
      userId(req),
    );
    res.status(result.success ? 200 : 400).json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

crmScoringRouter.get("/leads/:id/history", async (req: Request, res: Response) => {
  try {
    const rows = await scoringSvc.getLeadHistory(Number(req.params.id));
    res.json(rows);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});
