/**
 * Inventario Avanzado Routes
 * Prefijo: /v1/inventario-avanzado
 */
import { Router } from "express";
import {
  listWarehouses,
  getWarehouse,
  upsertWarehouse,
  listZones,
  upsertZone,
  listBins,
  upsertBin,
  listLots,
  getLot,
  createLot,
  listSerials,
  getSerial,
  registerSerial,
  updateSerialStatus,
  listBinStock,
  getValuationMethod,
  setValuationMethod,
  listMovements,
  createMovement,
} from "./service.js";

export const inventarioAvanzadoRouter = Router();

// ── Almacenes ───────────────────────────────────────────────────────────────

inventarioAvanzadoRouter.get("/almacenes", async (req, res) => {
  try {
    const data = await listWarehouses({
      search: req.query.search as string,
      page: req.query.page ? parseInt(req.query.page as string) : undefined,
      limit: req.query.limit ? parseInt(req.query.limit as string) : undefined,
    });
    return res.json(data);
  } catch (err: any) {
    return res.status(500).json({ error: err.message });
  }
});

inventarioAvanzadoRouter.get("/almacenes/:id", async (req, res) => {
  try {
    const data = await getWarehouse(parseInt(req.params.id));
    if (!data) return res.status(404).json({ error: "not_found" });
    return res.json(data);
  } catch (err: any) {
    return res.status(500).json({ error: err.message });
  }
});

inventarioAvanzadoRouter.post("/almacenes", async (req, res) => {
  try {
    const result = await upsertWarehouse(req.body);
    return res.status(result.ok ? 201 : 400).json(result);
  } catch (err: any) {
    return res.status(500).json({ error: err.message });
  }
});

// ── Zonas ───────────────────────────────────────────────────────────────────

inventarioAvanzadoRouter.get("/almacenes/:id/zonas", async (req, res) => {
  try {
    const data = await listZones(parseInt(req.params.id));
    return res.json({ rows: data });
  } catch (err: any) {
    return res.status(500).json({ error: err.message });
  }
});

inventarioAvanzadoRouter.post("/almacenes/:id/zonas", async (req, res) => {
  try {
    const result = await upsertZone({
      ...req.body,
      warehouseId: parseInt(req.params.id),
    });
    return res.status(result.ok ? 201 : 400).json(result);
  } catch (err: any) {
    return res.status(500).json({ error: err.message });
  }
});

// ── Ubicaciones ─────────────────────────────────────────────────────────────

inventarioAvanzadoRouter.get("/zonas/:id/ubicaciones", async (req, res) => {
  try {
    const data = await listBins(parseInt(req.params.id));
    return res.json({ rows: data });
  } catch (err: any) {
    return res.status(500).json({ error: err.message });
  }
});

inventarioAvanzadoRouter.post("/zonas/:id/ubicaciones", async (req, res) => {
  try {
    const result = await upsertBin({
      ...req.body,
      zoneId: parseInt(req.params.id),
    });
    return res.status(result.ok ? 201 : 400).json(result);
  } catch (err: any) {
    return res.status(500).json({ error: err.message });
  }
});

// ── Lotes ───────────────────────────────────────────────────────────────────

inventarioAvanzadoRouter.get("/lotes", async (req, res) => {
  try {
    const data = await listLots({
      productId: req.query.productId ? parseInt(req.query.productId as string) : undefined,
      status: req.query.status as string,
      page: req.query.page ? parseInt(req.query.page as string) : undefined,
      limit: req.query.limit ? parseInt(req.query.limit as string) : undefined,
    });
    return res.json(data);
  } catch (err: any) {
    return res.status(500).json({ error: err.message });
  }
});

inventarioAvanzadoRouter.get("/lotes/:id", async (req, res) => {
  try {
    const data = await getLot(parseInt(req.params.id));
    if (!data) return res.status(404).json({ error: "not_found" });
    return res.json(data);
  } catch (err: any) {
    return res.status(500).json({ error: err.message });
  }
});

inventarioAvanzadoRouter.post("/lotes", async (req, res) => {
  try {
    const result = await createLot(req.body);
    return res.status(result.ok ? 201 : 400).json(result);
  } catch (err: any) {
    return res.status(500).json({ error: err.message });
  }
});

// ── Seriales ────────────────────────────────────────────────────────────────

inventarioAvanzadoRouter.get("/seriales", async (req, res) => {
  try {
    const data = await listSerials({
      productId: req.query.productId ? parseInt(req.query.productId as string) : undefined,
      status: req.query.status as string,
      search: req.query.search as string,
      page: req.query.page ? parseInt(req.query.page as string) : undefined,
      limit: req.query.limit ? parseInt(req.query.limit as string) : undefined,
    });
    return res.json(data);
  } catch (err: any) {
    return res.status(500).json({ error: err.message });
  }
});

inventarioAvanzadoRouter.get("/seriales/:id", async (req, res) => {
  try {
    const data = await getSerial(parseInt(req.params.id));
    if (!data) return res.status(404).json({ error: "not_found" });
    return res.json(data);
  } catch (err: any) {
    return res.status(500).json({ error: err.message });
  }
});

inventarioAvanzadoRouter.post("/seriales", async (req, res) => {
  try {
    const result = await registerSerial(req.body);
    return res.status(result.ok ? 201 : 400).json(result);
  } catch (err: any) {
    return res.status(500).json({ error: err.message });
  }
});

inventarioAvanzadoRouter.patch("/seriales/:id/estado", async (req, res) => {
  try {
    const result = await updateSerialStatus({
      serialId: parseInt(req.params.id),
      ...req.body,
    });
    return res.status(result.ok ? 200 : 400).json(result);
  } catch (err: any) {
    return res.status(500).json({ error: err.message });
  }
});

// ── Stock por ubicacion ─────────────────────────────────────────────────────

inventarioAvanzadoRouter.get("/stock-ubicacion", async (req, res) => {
  try {
    const data = await listBinStock({
      warehouseId: req.query.warehouseId ? parseInt(req.query.warehouseId as string) : undefined,
      productId: req.query.productId ? parseInt(req.query.productId as string) : undefined,
    });
    return res.json({ rows: data });
  } catch (err: any) {
    return res.status(500).json({ error: err.message });
  }
});

// ── Valoracion ──────────────────────────────────────────────────────────────

inventarioAvanzadoRouter.get("/valoracion/:productId", async (req, res) => {
  try {
    const data = await getValuationMethod(parseInt(req.params.productId));
    return res.json(data || { method: "WEIGHTED_AVG" });
  } catch (err: any) {
    return res.status(500).json({ error: err.message });
  }
});

inventarioAvanzadoRouter.post("/valoracion", async (req, res) => {
  try {
    const result = await setValuationMethod(req.body);
    return res.status(result.ok ? 200 : 400).json(result);
  } catch (err: any) {
    return res.status(500).json({ error: err.message });
  }
});

// ── Movimientos ─────────────────────────────────────────────────────────────

inventarioAvanzadoRouter.get("/movimientos", async (req, res) => {
  try {
    const data = await listMovements({
      productId: req.query.productId ? parseInt(req.query.productId as string) : undefined,
      warehouseId: req.query.warehouseId ? parseInt(req.query.warehouseId as string) : undefined,
      movementType: req.query.movementType as string,
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

inventarioAvanzadoRouter.post("/movimientos", async (req, res) => {
  try {
    const result = await createMovement(req.body);
    return res.status(result.ok ? 201 : 400).json(result);
  } catch (err: any) {
    return res.status(500).json({ error: err.message });
  }
});
