import { Router } from "express";
import { z } from "zod";
import {
  cerrarOrdenConCompraTx,
  createOrden,
  createOrdenTx,
  deleteOrden,
  getOrden,
  getOrdenDetalle,
  listOrdenes,
  updateOrden
} from "./service.js";

export const ordenesRouter = Router();
const qSchema = z.object({ search: z.string().optional(), codigo: z.string().optional(), page: z.string().optional(), limit: z.string().optional() });
const txSchema = z.object({ orden: z.record(z.any()), detalle: z.array(z.record(z.any())).default([]) });
const cerrarSchema = z.object({
  numFactOrden: z.string().min(1),
  compra: z.record(z.any()),
  detalle: z.array(z.record(z.any())).optional(),
  options: z.object({
    actualizarInventario: z.boolean().optional(),
    generarCxP: z.boolean().optional(),
    actualizarSaldosProveedor: z.boolean().optional()
  }).optional()
});

ordenesRouter.get("/", async (req, res) => { const q = qSchema.safeParse(req.query); if (!q.success) return res.status(400).json({ error: "invalid_query" }); res.json(await listOrdenes(q.data)); });
ordenesRouter.post("/tx", async (req, res) => { const p = txSchema.safeParse(req.body); if (!p.success) return res.status(400).json({ error: "invalid_payload" }); try { res.status(201).json(await createOrdenTx(p.data)); } catch (err) { res.status(400).json({ error: String(err) }); } });
ordenesRouter.post("/cerrar-compra-tx", async (req, res) => {
  const p = cerrarSchema.safeParse(req.body);
  if (!p.success) return res.status(400).json({ error: "invalid_payload", issues: p.error.flatten() });
  try {
    res.status(201).json(await cerrarOrdenConCompraTx(p.data));
  } catch (err) {
    res.status(400).json({ error: String(err) });
  }
});
ordenesRouter.get("/:numFact", async (req, res) => { const row = await getOrden(req.params.numFact); if (!row) return res.status(404).json({ error: "not_found" }); res.json(row); });
ordenesRouter.get("/:numFact/detalle", async (req, res) => res.json(await getOrdenDetalle(req.params.numFact)));
ordenesRouter.post("/", async (req, res) => { try { res.status(201).json(await createOrden(req.body ?? {})); } catch (err) { res.status(400).json({ error: String(err) }); } });
ordenesRouter.put("/:numFact", async (req, res) => { try { res.json(await updateOrden(req.params.numFact, req.body ?? {})); } catch (err) { res.status(400).json({ error: String(err) }); } });
ordenesRouter.delete("/:numFact", async (req, res) => { try { res.json(await deleteOrden(req.params.numFact)); } catch (err) { res.status(400).json({ error: String(err) }); } });
