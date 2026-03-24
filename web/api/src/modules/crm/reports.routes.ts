/**
 * CRM Reports Routes — /v1/crm/reports
 *
 * Sales by Period, Lead Aging, Conversion by Source, Top Performers
 */
import { Router, Request, Response } from "express";
import * as reportsSvc from "./reports.service.js";

export const crmReportsRouter = Router();

// ── Helper ───────────────────────────────────────────────────────────────────

function intOrNull(v: unknown): number | null {
  if (v === undefined || v === null || v === "") return null;
  const n = Number(v);
  return Number.isFinite(n) ? n : null;
}

// ═══════════════════════════════════════════════════════════════════════════════
//  SALES BY PERIOD
// ═══════════════════════════════════════════════════════════════════════════════

crmReportsRouter.get("/sales", async (req: Request, res: Response) => {
  try {
    const rows = await reportsSvc.getSalesByPeriod(
      intOrNull(req.query.pipeline) ?? undefined,
      (req.query.groupBy as string) || undefined,
    );
    res.json(rows);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// ═══════════════════════════════════════════════════════════════════════════════
//  LEAD AGING
// ═══════════════════════════════════════════════════════════════════════════════

crmReportsRouter.get("/aging", async (req: Request, res: Response) => {
  try {
    const rows = await reportsSvc.getLeadAging(
      intOrNull(req.query.pipeline) ?? undefined,
    );
    res.json(rows);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// ═══════════════════════════════════════════════════════════════════════════════
//  CONVERSION BY SOURCE
// ═══════════════════════════════════════════════════════════════════════════════

crmReportsRouter.get("/conversion", async (req: Request, res: Response) => {
  try {
    const rows = await reportsSvc.getConversionBySource(
      intOrNull(req.query.pipeline) ?? undefined,
    );
    res.json(rows);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// ═══════════════════════════════════════════════════════════════════════════════
//  TOP PERFORMERS
// ═══════════════════════════════════════════════════════════════════════════════

crmReportsRouter.get("/top-performers", async (req: Request, res: Response) => {
  try {
    const rows = await reportsSvc.getTopPerformers(
      intOrNull(req.query.pipeline) ?? undefined,
      (req.query.from as string) || undefined,
    );
    res.json(rows);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});
