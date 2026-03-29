/**
 * CRM Analytics Routes — /v1/crm/analytics
 *
 * KPIs, Forecast, Funnel, Win/Loss, Velocity, Activity Report
 */
import { Router, Request, Response } from "express";
import * as analyticsSvc from "./analytics.service.js";

export const crmAnalyticsRouter = Router();

// ── Helper ───────────────────────────────────────────────────────────────────

function intOrNull(v: unknown): number | null {
  if (v === undefined || v === null || v === "") return null;
  const n = Number(v);
  return Number.isFinite(n) ? n : null;
}

// ═══════════════════════════════════════════════════════════════════════════════
//  KPIs
// ═══════════════════════════════════════════════════════════════════════════════

crmAnalyticsRouter.get("/kpis", async (req: Request, res: Response) => {
  try {
    const row = await analyticsSvc.getKPIs(intOrNull(req.query.pipeline) ?? undefined);
    res.json(row);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// ═══════════════════════════════════════════════════════════════════════════════
//  FORECAST
// ═══════════════════════════════════════════════════════════════════════════════

crmAnalyticsRouter.get("/forecast", async (req: Request, res: Response) => {
  try {
    const rows = await analyticsSvc.getForecast(
      intOrNull(req.query.pipeline) ?? undefined,
      intOrNull(req.query.months) ?? undefined,
    );
    res.json(rows);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// ═══════════════════════════════════════════════════════════════════════════════
//  FUNNEL
// ═══════════════════════════════════════════════════════════════════════════════

crmAnalyticsRouter.get("/funnel", async (req: Request, res: Response) => {
  try {
    const rows = await analyticsSvc.getFunnel(intOrNull(req.query.pipeline) ?? undefined);
    res.json(rows);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// ═══════════════════════════════════════════════════════════════════════════════
//  WIN/LOSS BY PERIOD
// ═══════════════════════════════════════════════════════════════════════════════

crmAnalyticsRouter.get("/win-loss/period", async (req: Request, res: Response) => {
  try {
    const rows = await analyticsSvc.getWinLossByPeriod(
      intOrNull(req.query.pipeline) ?? undefined,
      (req.query.from as string) || undefined,
      (req.query.to as string) || undefined,
    );
    res.json(rows);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// ═══════════════════════════════════════════════════════════════════════════════
//  WIN/LOSS BY SOURCE
// ═══════════════════════════════════════════════════════════════════════════════

crmAnalyticsRouter.get("/win-loss/source", async (req: Request, res: Response) => {
  try {
    const rows = await analyticsSvc.getWinLossBySource(
      intOrNull(req.query.pipeline) ?? undefined,
      (req.query.from as string) || undefined,
      (req.query.to as string) || undefined,
    );
    res.json(rows);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// ═══════════════════════════════════════════════════════════════════════════════
//  VELOCITY
// ═══════════════════════════════════════════════════════════════════════════════

crmAnalyticsRouter.get("/velocity", async (req: Request, res: Response) => {
  try {
    const rows = await analyticsSvc.getVelocity(intOrNull(req.query.pipeline) ?? undefined);
    res.json(rows);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// ═══════════════════════════════════════════════════════════════════════════════
//  ACTIVITY REPORT
// ═══════════════════════════════════════════════════════════════════════════════

crmAnalyticsRouter.get("/activity-report", async (req: Request, res: Response) => {
  try {
    const rows = await analyticsSvc.getActivityReport(
      intOrNull(req.query.pipeline) ?? undefined,
      (req.query.from as string) || undefined,
      (req.query.to as string) || undefined,
    );
    res.json(rows);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});
