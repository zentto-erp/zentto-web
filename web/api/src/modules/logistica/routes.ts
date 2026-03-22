/**
 * Logistica Routes
 * Prefijo: /v1/logistica
 */
import { Router } from "express";
import {
  listCarriers,
  upsertCarrier,
  listDrivers,
  upsertDriver,
  listGoodsReceipts,
  getGoodsReceipt,
  createGoodsReceipt,
  approveGoodsReceipt,
  listGoodsReturns,
  createGoodsReturn,
  approveGoodsReturn,
  listDeliveryNotes,
  getDeliveryNote,
  createDeliveryNote,
  dispatchDeliveryNote,
  deliverDeliveryNote,
} from "./service.js";
import {
  processGoodsReceiptStock,
  processDeliveryNoteStock,
} from "../inventario-avanzado/inv-integracion.service.js";

export const logisticaRouter = Router();

// ── Transportistas ──────────────────────────────────────────────────────────

logisticaRouter.get("/transportistas", async (req, res) => {
  try {
    const data = await listCarriers({
      search: req.query.search as string,
      page: req.query.page ? parseInt(req.query.page as string) : undefined,
      limit: req.query.limit ? parseInt(req.query.limit as string) : undefined,
    });
    return res.json(data);
  } catch (err: any) {
    return res.status(500).json({ error: err.message });
  }
});

logisticaRouter.post("/transportistas", async (req, res) => {
  try {
    const result = await upsertCarrier(req.body);
    return res.status(result.ok ? 201 : 400).json(result);
  } catch (err: any) {
    return res.status(500).json({ error: err.message });
  }
});

// ── Conductores ─────────────────────────────────────────────────────────────

logisticaRouter.get("/conductores", async (req, res) => {
  try {
    const data = await listDrivers({
      carrierId: req.query.carrierId ? parseInt(req.query.carrierId as string) : undefined,
      search: req.query.search as string,
      page: req.query.page ? parseInt(req.query.page as string) : undefined,
      limit: req.query.limit ? parseInt(req.query.limit as string) : undefined,
    });
    return res.json(data);
  } catch (err: any) {
    return res.status(500).json({ error: err.message });
  }
});

logisticaRouter.post("/conductores", async (req, res) => {
  try {
    const result = await upsertDriver(req.body);
    return res.status(result.ok ? 201 : 400).json(result);
  } catch (err: any) {
    return res.status(500).json({ error: err.message });
  }
});

// ── Recepciones de mercancia ────────────────────────────────────────────────

logisticaRouter.get("/recepciones", async (req, res) => {
  try {
    const data = await listGoodsReceipts({
      supplierId: req.query.supplierId ? parseInt(req.query.supplierId as string) : undefined,
      status: req.query.status as string,
      fechaDesde: req.query.fechaDesde as string,
      fechaHasta: req.query.fechaHasta as string,
      page: req.query.page ? parseInt(req.query.page as string) : undefined,
      limit: req.query.limit ? parseInt(req.query.limit as string) : undefined,
    });
    return res.json(data);
  } catch (err: any) {
    return res.status(500).json({ error: err.message });
  }
});

logisticaRouter.get("/recepciones/:id", async (req, res) => {
  try {
    const data = await getGoodsReceipt(parseInt(req.params.id));
    if (!data) return res.status(404).json({ error: "not_found" });
    return res.json(data);
  } catch (err: any) {
    return res.status(500).json({ error: err.message });
  }
});

logisticaRouter.post("/recepciones", async (req, res) => {
  try {
    const result = await createGoodsReceipt(req.body);
    return res.status(result.ok ? 201 : 400).json(result);
  } catch (err: any) {
    return res.status(500).json({ error: err.message });
  }
});

logisticaRouter.post("/recepciones/:id/aprobar", async (req, res) => {
  try {
    const codUsuario = req.body.userId || (req as any).user?.username || "API";
    const result = await approveGoodsReceipt(
      parseInt(req.params.id),
      codUsuario
    );

    // Integration: create stock movements for received goods (best-effort)
    let stockResult: { ok: boolean; movementsCreated?: number } = { ok: false };
    if (result.ok) {
      try {
        const scope = (req as any).user;
        stockResult = await processGoodsReceiptStock({
          companyId: scope?.companyId ?? 1,
          branchId: scope?.branchId ?? 1,
          goodsReceiptId: parseInt(req.params.id),
          codUsuario,
        });
      } catch { /* never blocks */ }
    }

    return res.status(result.ok ? 200 : 400).json({ ...result, stock: stockResult });
  } catch (err: any) {
    return res.status(500).json({ error: err.message });
  }
});

// ── Devoluciones ────────────────────────────────────────────────────────────

logisticaRouter.get("/devoluciones", async (req, res) => {
  try {
    const data = await listGoodsReturns({
      status: req.query.status as string,
      page: req.query.page ? parseInt(req.query.page as string) : undefined,
      limit: req.query.limit ? parseInt(req.query.limit as string) : undefined,
    });
    return res.json(data);
  } catch (err: any) {
    return res.status(500).json({ error: err.message });
  }
});

logisticaRouter.post("/devoluciones", async (req, res) => {
  try {
    const result = await createGoodsReturn(req.body);
    return res.status(result.ok ? 201 : 400).json(result);
  } catch (err: any) {
    return res.status(500).json({ error: err.message });
  }
});

logisticaRouter.post("/devoluciones/:id/aprobar", async (req, res) => {
  try {
    const result = await approveGoodsReturn(
      parseInt(req.params.id),
      req.body.userId
    );
    return res.status(result.ok ? 200 : 400).json(result);
  } catch (err: any) {
    return res.status(500).json({ error: err.message });
  }
});

// ── Notas de entrega ────────────────────────────────────────────────────────

logisticaRouter.get("/notas-entrega", async (req, res) => {
  try {
    const data = await listDeliveryNotes({
      customerId: req.query.customerId ? parseInt(req.query.customerId as string) : undefined,
      status: req.query.status as string,
      fechaDesde: req.query.fechaDesde as string,
      fechaHasta: req.query.fechaHasta as string,
      page: req.query.page ? parseInt(req.query.page as string) : undefined,
      limit: req.query.limit ? parseInt(req.query.limit as string) : undefined,
    });
    return res.json(data);
  } catch (err: any) {
    return res.status(500).json({ error: err.message });
  }
});

logisticaRouter.get("/notas-entrega/:id", async (req, res) => {
  try {
    const data = await getDeliveryNote(parseInt(req.params.id));
    if (!data) return res.status(404).json({ error: "not_found" });
    return res.json(data);
  } catch (err: any) {
    return res.status(500).json({ error: err.message });
  }
});

logisticaRouter.post("/notas-entrega", async (req, res) => {
  try {
    const result = await createDeliveryNote(req.body);
    return res.status(result.ok ? 201 : 400).json(result);
  } catch (err: any) {
    return res.status(500).json({ error: err.message });
  }
});

logisticaRouter.post("/notas-entrega/:id/despachar", async (req, res) => {
  try {
    const codUsuario = req.body.userId || (req as any).user?.username || "API";
    const result = await dispatchDeliveryNote(
      parseInt(req.params.id),
      codUsuario
    );

    // Integration: create stock movements for dispatched goods (best-effort)
    let stockResult: { ok: boolean; movementsCreated?: number } = { ok: false };
    if (result.ok) {
      try {
        const scope = (req as any).user;
        stockResult = await processDeliveryNoteStock({
          companyId: scope?.companyId ?? 1,
          branchId: scope?.branchId ?? 1,
          deliveryNoteId: parseInt(req.params.id),
          codUsuario,
        });
      } catch { /* never blocks */ }
    }

    return res.status(result.ok ? 200 : 400).json({ ...result, stock: stockResult });
  } catch (err: any) {
    return res.status(500).json({ error: err.message });
  }
});

logisticaRouter.post("/notas-entrega/:id/entregar", async (req, res) => {
  try {
    const result = await deliverDeliveryNote({
      deliveryNoteId: parseInt(req.params.id),
      ...req.body,
    });
    return res.status(result.ok ? 200 : 400).json(result);
  } catch (err: any) {
    return res.status(500).json({ error: err.message });
  }
});
