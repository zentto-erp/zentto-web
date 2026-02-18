import { Router } from "express";
import { z } from "zod";
import { createPago, createPagoTx, deletePago, getPago, getPagoDetalle, listPagos, updatePago } from "./service.js";

export const pagosRouter = Router();
const qSchema = z.object({ search: z.string().optional(), codigo: z.string().optional(), page: z.string().optional(), limit: z.string().optional() });
const txSchema = z.object({ pago: z.record(z.any()), detalle: z.array(z.record(z.any())).default([]) });

pagosRouter.get("/", async (req, res) => {
  const q = qSchema.safeParse(req.query);
  if (!q.success) return res.status(400).json({ error: "invalid_query" });
  res.json(await listPagos(q.data));
});
pagosRouter.post("/tx", async (req, res) => {
  const p = txSchema.safeParse(req.body);
  if (!p.success) return res.status(400).json({ error: "invalid_payload" });
  try { res.status(201).json(await createPagoTx(p.data)); } catch (err) { res.status(400).json({ error: String(err) }); }
});
pagosRouter.get("/:id", async (req, res) => { const r = await getPago(req.params.id); if (!r) return res.status(404).json({ error: "not_found" }); res.json(r); });
pagosRouter.get("/:id/detalle", async (req, res) => res.json(await getPagoDetalle(req.params.id)));
pagosRouter.post("/", async (req, res) => { try { res.status(201).json(await createPago(req.body ?? {})); } catch (err) { res.status(400).json({ error: String(err) }); } });
pagosRouter.put("/:id", async (req, res) => { try { res.json(await updatePago(req.params.id, req.body ?? {})); } catch (err) { res.status(400).json({ error: String(err) }); } });
pagosRouter.delete("/:id", async (req, res) => { try { res.json(await deletePago(req.params.id)); } catch (err) { res.status(400).json({ error: String(err) }); } });
