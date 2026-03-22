/**
 * Manufactura Routes — /v1/manufactura
 *
 * BOMs, Work Centers, Routing, Work Orders
 */
import { Router, Request, Response } from "express";
import * as svc from "./service.js";

export const manufacturaRouter = Router();

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
//  BOMs
// ═══════════════════════════════════════════════════════════════════════════════

manufacturaRouter.get("/bom", async (req: Request, res: Response) => {
  try {
    const q = req.query;
    const result = await svc.listBOMs({
      status: (q.status as string) || undefined,
      search: (q.search as string) || undefined,
      page: q.page ? parseInt(q.page as string) : undefined,
      limit: q.limit ? parseInt(q.limit as string) : undefined,
    });
    res.json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

manufacturaRouter.get("/bom/:id", async (req: Request, res: Response) => {
  try {
    const row = await svc.getBOM(Number(req.params.id));
    if (!row) return res.status(404).json({ error: "not_found" });
    res.json(row);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

manufacturaRouter.post("/bom", async (req: Request, res: Response) => {
  try {
    const body = req.body;
    const result = await svc.createBOM({
      productId: body.productId,
      bomCode: body.bomCode,
      bomName: body.bomName,
      expectedQuantity: body.expectedQuantity,
      linesJson: body.lines ? JSON.stringify(body.lines) : null,
      userId: userId(req),
    });
    res.status(result.success ? 201 : 400).json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

manufacturaRouter.post("/bom/:id/activar", async (req: Request, res: Response) => {
  try {
    const result = await svc.activateBOM(Number(req.params.id), userId(req));
    res.status(result.success ? 200 : 400).json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

manufacturaRouter.post("/bom/:id/obsoleto", async (req: Request, res: Response) => {
  try {
    const result = await svc.obsoleteBOM(Number(req.params.id), userId(req));
    res.status(result.success ? 200 : 400).json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// ═══════════════════════════════════════════════════════════════════════════════
//  CENTROS DE TRABAJO
// ═══════════════════════════════════════════════════════════════════════════════

manufacturaRouter.get("/centros-trabajo", async (req: Request, res: Response) => {
  try {
    const q = req.query;
    const result = await svc.listWorkCenters({
      search: (q.search as string) || undefined,
      page: q.page ? parseInt(q.page as string) : undefined,
      limit: q.limit ? parseInt(q.limit as string) : undefined,
    });
    res.json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

manufacturaRouter.post("/centros-trabajo", async (req: Request, res: Response) => {
  try {
    const result = await svc.upsertWorkCenter({ ...req.body, userId: userId(req) });
    res.status(result.success ? 200 : 400).json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// ═══════════════════════════════════════════════════════════════════════════════
//  ROUTING (rutas de produccion)
// ═══════════════════════════════════════════════════════════════════════════════

manufacturaRouter.get("/bom/:id/rutas", async (req: Request, res: Response) => {
  try {
    const rows = await svc.listRouting(Number(req.params.id));
    res.json(rows);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

manufacturaRouter.post("/bom/:id/rutas", async (req: Request, res: Response) => {
  try {
    const result = await svc.upsertRouting(Number(req.params.id), {
      ...req.body,
      userId: userId(req),
    });
    res.status(result.success ? 200 : 400).json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// ═══════════════════════════════════════════════════════════════════════════════
//  ORDENES DE TRABAJO
// ═══════════════════════════════════════════════════════════════════════════════

manufacturaRouter.get("/ordenes", async (req: Request, res: Response) => {
  try {
    const q = req.query;
    const result = await svc.listWorkOrders({
      status: (q.status as string) || undefined,
      fechaDesde: (q.fechaDesde as string) || undefined,
      fechaHasta: (q.fechaHasta as string) || undefined,
      page: q.page ? parseInt(q.page as string) : undefined,
      limit: q.limit ? parseInt(q.limit as string) : undefined,
    });
    res.json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

manufacturaRouter.get("/ordenes/:id", async (req: Request, res: Response) => {
  try {
    const row = await svc.getWorkOrder(Number(req.params.id));
    if (!row) return res.status(404).json({ error: "not_found" });
    res.json(row);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

manufacturaRouter.post("/ordenes", async (req: Request, res: Response) => {
  try {
    const result = await svc.createWorkOrder({ ...req.body, userId: userId(req) });
    res.status(result.success ? 201 : 400).json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

manufacturaRouter.post("/ordenes/:id/iniciar", async (req: Request, res: Response) => {
  try {
    const result = await svc.startWorkOrder(Number(req.params.id), userId(req));
    res.status(result.success ? 200 : 400).json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

manufacturaRouter.post("/ordenes/:id/consumir", async (req: Request, res: Response) => {
  try {
    const result = await svc.consumeMaterial(Number(req.params.id), {
      ...req.body,
      userId: userId(req),
    });
    res.status(result.success ? 200 : 400).json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

manufacturaRouter.post("/ordenes/:id/reportar-salida", async (req: Request, res: Response) => {
  try {
    const result = await svc.reportOutput(Number(req.params.id), {
      ...req.body,
      userId: userId(req),
    });
    res.status(result.success ? 200 : 400).json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

manufacturaRouter.post("/ordenes/:id/completar", async (req: Request, res: Response) => {
  try {
    const result = await svc.completeWorkOrder(Number(req.params.id), userId(req));
    res.status(result.success ? 200 : 400).json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

manufacturaRouter.post("/ordenes/:id/cancelar", async (req: Request, res: Response) => {
  try {
    const result = await svc.cancelWorkOrder(Number(req.params.id), userId(req));
    res.status(result.success ? 200 : 400).json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});
