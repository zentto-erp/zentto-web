/**
 * Purchases Analytics Routes — /compras/analytics
 *
 * KPIs, ByMonth, BySupplier, AgingAP, PaymentSchedule
 */
import { Router, Request, Response } from "express";
import * as analyticsSvc from "./analytics.service.js";

export const comprasAnalyticsRouter = Router();

// ── Helper ───────────────────────────────────────────────────────────────────

function intOrNull(v: unknown): number | null {
  if (v === undefined || v === null || v === "") return null;
  const n = Number(v);
  return Number.isFinite(n) ? n : null;
}

// ═══════════════════════════════════════════════════════════════════════════════
//  KPIs
// ═══════════════════════════════════════════════════════════════════════════════

comprasAnalyticsRouter.get("/kpis", async (req: Request, res: Response) => {
  try {
    const row = await analyticsSvc.getKPIs(
      (req.query.from as string) || undefined,
      (req.query.to as string) || undefined,
    );
    res.json(row);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// ═══════════════════════════════════════════════════════════════════════════════
//  BY MONTH
// ═══════════════════════════════════════════════════════════════════════════════

comprasAnalyticsRouter.get("/by-month", async (req: Request, res: Response) => {
  try {
    const rows = await analyticsSvc.getByMonth(
      intOrNull(req.query.months) ?? undefined,
    );
    res.json(rows);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// ═══════════════════════════════════════════════════════════════════════════════
//  BY SUPPLIER
// ═══════════════════════════════════════════════════════════════════════════════

comprasAnalyticsRouter.get("/by-supplier", async (req: Request, res: Response) => {
  try {
    const rows = await analyticsSvc.getBySupplier(
      intOrNull(req.query.top) ?? undefined,
      (req.query.from as string) || undefined,
      (req.query.to as string) || undefined,
    );
    res.json(rows);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// ═══════════════════════════════════════════════════════════════════════════════
//  AGING AP
// ═══════════════════════════════════════════════════════════════════════════════

comprasAnalyticsRouter.get("/aging", async (req: Request, res: Response) => {
  try {
    const rows = await analyticsSvc.getAgingAP();
    res.json(rows);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// ═══════════════════════════════════════════════════════════════════════════════
//  PAYMENT SCHEDULE
// ═══════════════════════════════════════════════════════════════════════════════

comprasAnalyticsRouter.get("/payment-schedule", async (req: Request, res: Response) => {
  try {
    const rows = await analyticsSvc.getPaymentSchedule(
      intOrNull(req.query.months) ?? undefined,
    );
    res.json(rows);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});
