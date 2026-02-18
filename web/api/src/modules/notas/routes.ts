import { Router } from "express";
import { z } from "zod";
import { notasService } from "./service.js";

export const notasRouter = Router();
const qSchema = z.object({ search: z.string().optional(), codigo: z.string().optional(), page: z.string().optional(), limit: z.string().optional() });
const txSchema = z.object({ nota: z.record(z.any()), detalle: z.array(z.record(z.any())).default([]) });
const emitirCreditoSchema = z.object({
  nota: z.record(z.any()),
  detalle: z.array(z.record(z.any())).min(1),
  options: z.object({
    impactarInventario: z.boolean().optional(),
    ajustarCxC: z.boolean().optional(),
    actualizarSaldosCliente: z.boolean().optional()
  }).optional()
});
const emitirDebitoSchema = z.object({
  nota: z.record(z.any()),
  detalle: z.array(z.record(z.any())).min(1),
  options: z.object({
    ajustarCxC: z.boolean().optional(),
    actualizarSaldosCliente: z.boolean().optional()
  }).optional()
});

notasRouter.get("/credito", async (req, res) => { const q = qSchema.safeParse(req.query); if (!q.success) return res.status(400).json({ error: "invalid_query" }); res.json(await notasService.listCredito(q.data)); });
notasRouter.post("/credito/tx", async (req, res) => { const p = txSchema.safeParse(req.body); if (!p.success) return res.status(400).json({ error: "invalid_payload" }); try { res.status(201).json(await notasService.txCredito(p.data)); } catch (err) { res.status(400).json({ error: String(err) }); } });
notasRouter.post("/credito/emitir-tx", async (req, res) => {
  const p = emitirCreditoSchema.safeParse(req.body);
  if (!p.success) return res.status(400).json({ error: "invalid_payload", issues: p.error.flatten() });
  try {
    res.status(201).json(await notasService.emitirCreditoTx(p.data));
  } catch (err) {
    res.status(400).json({ error: String(err) });
  }
});
notasRouter.get("/credito/:numFact", async (req, res) => { const r = await notasService.getCredito(req.params.numFact); if (!r) return res.status(404).json({ error: "not_found" }); res.json(r); });
notasRouter.get("/credito/:numFact/detalle", async (req, res) => res.json(await notasService.getCreditoDetalle(req.params.numFact)));
notasRouter.post("/credito", async (req, res) => { try { res.status(201).json(await notasService.createCredito(req.body ?? {})); } catch (err) { res.status(400).json({ error: String(err) }); } });
notasRouter.put("/credito/:numFact", async (req, res) => { try { res.json(await notasService.updateCredito(req.params.numFact, req.body ?? {})); } catch (err) { res.status(400).json({ error: String(err) }); } });
notasRouter.delete("/credito/:numFact", async (req, res) => { try { res.json(await notasService.deleteCredito(req.params.numFact)); } catch (err) { res.status(400).json({ error: String(err) }); } });

notasRouter.get("/debito", async (req, res) => { const q = qSchema.safeParse(req.query); if (!q.success) return res.status(400).json({ error: "invalid_query" }); res.json(await notasService.listDebito(q.data)); });
notasRouter.post("/debito/tx", async (req, res) => { const p = txSchema.safeParse(req.body); if (!p.success) return res.status(400).json({ error: "invalid_payload" }); try { res.status(201).json(await notasService.txDebito(p.data)); } catch (err) { res.status(400).json({ error: String(err) }); } });
notasRouter.post("/debito/emitir-tx", async (req, res) => {
  const p = emitirDebitoSchema.safeParse(req.body);
  if (!p.success) return res.status(400).json({ error: "invalid_payload", issues: p.error.flatten() });
  try {
    res.status(201).json(await notasService.emitirDebitoTx(p.data));
  } catch (err) {
    res.status(400).json({ error: String(err) });
  }
});
notasRouter.get("/debito/:numFact", async (req, res) => { const r = await notasService.getDebito(req.params.numFact); if (!r) return res.status(404).json({ error: "not_found" }); res.json(r); });
notasRouter.get("/debito/:numFact/detalle", async (req, res) => res.json(await notasService.getDebitoDetalle(req.params.numFact)));
notasRouter.post("/debito", async (req, res) => { try { res.status(201).json(await notasService.createDebito(req.body ?? {})); } catch (err) { res.status(400).json({ error: String(err) }); } });
notasRouter.put("/debito/:numFact", async (req, res) => { try { res.json(await notasService.updateDebito(req.params.numFact, req.body ?? {})); } catch (err) { res.status(400).json({ error: String(err) }); } });
notasRouter.delete("/debito/:numFact", async (req, res) => { try { res.json(await notasService.deleteDebito(req.params.numFact)); } catch (err) { res.status(400).json({ error: String(err) }); } });
