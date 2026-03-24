/**
 * Sales Analytics Routes — /ventas/analytics
 *
 * KPIs, ByMonth, ByCustomer, AgingAR, CollectionForecast, ByProduct
 */
import { Router, Request, Response } from "express";
import * as analyticsSvc from "./analytics.service.js";

export const ventasAnalyticsRouter = Router();

// -- Helper -------------------------------------------------------------------

function intOrNull(v: unknown): number | null {
  if (v === undefined || v === null || v === "") return null;
  const n = Number(v);
  return Number.isFinite(n) ? n : null;
}

// == KPIs =====================================================================

ventasAnalyticsRouter.get("/kpis", async (req: Request, res: Response) => {
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

// == BY MONTH =================================================================

ventasAnalyticsRouter.get("/by-month", async (req: Request, res: Response) => {
  try {
    const rows = await analyticsSvc.getByMonth(
      intOrNull(req.query.months) ?? undefined,
    );
    res.json(rows);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// == BY CUSTOMER ==============================================================

ventasAnalyticsRouter.get("/by-customer", async (req: Request, res: Response) => {
  try {
    const rows = await analyticsSvc.getByCustomer(
      intOrNull(req.query.top) ?? undefined,
      (req.query.from as string) || undefined,
      (req.query.to as string) || undefined,
    );
    res.json(rows);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// == AGING AR =================================================================

ventasAnalyticsRouter.get("/aging", async (req: Request, res: Response) => {
  try {
    const rows = await analyticsSvc.getAgingAR();
    res.json(rows);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// == COLLECTION FORECAST ======================================================

ventasAnalyticsRouter.get("/collection-forecast", async (req: Request, res: Response) => {
  try {
    const rows = await analyticsSvc.getCollectionForecast(
      intOrNull(req.query.months) ?? undefined,
    );
    res.json(rows);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// == BY PRODUCT ===============================================================

ventasAnalyticsRouter.get("/by-product", async (req: Request, res: Response) => {
  try {
    const rows = await analyticsSvc.getByProduct(
      intOrNull(req.query.top) ?? undefined,
      (req.query.from as string) || undefined,
      (req.query.to as string) || undefined,
    );
    res.json(rows);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});
