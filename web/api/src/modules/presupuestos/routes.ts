import { Router } from "express";
import { z } from "zod";
import {
  anularPresupuestoTx,
  createPresupuesto,
  createPresupuestoTx,
  deletePresupuesto,
  emitirPresupuestoTx,
  getPresupuesto,
  getPresupuestoDetalle,
  listPresupuestos,
  updatePresupuesto
} from "./service.js";

export const presupuestosRouter = Router();
const qSchema = z.object({ search: z.string().optional(), codigo: z.string().optional(), page: z.string().optional(), limit: z.string().optional() });
const txSchema = z.object({ presupuesto: z.record(z.any()), detalle: z.array(z.record(z.any())).default([]) });
const emitirTxSchema = z.object({
  presupuesto: z.record(z.any()).optional(),
  factura: z.record(z.any()).optional(),
  detalle: z.array(z.record(z.any())).min(1),
  formasPago: z.array(z.record(z.any())).optional().default([]),
  options: z.object({
    actualizarInventario: z.boolean().optional(),
    generarCxC: z.boolean().optional(),
    cxcTable: z.enum(["P_Cobrar", "P_CobrarC"]).optional(),
    formaPagoTable: z.string().optional(),
    actualizarSaldosCliente: z.boolean().optional()
  }).optional()
});
const anularTxSchema = z.object({ numFact: z.string().min(1), codUsuario: z.string().optional(), motivo: z.string().optional() });

presupuestosRouter.get("/", async (req, res) => { const q = qSchema.safeParse(req.query); if (!q.success) return res.status(400).json({ error: "invalid_query" }); res.json(await listPresupuestos(q.data)); });
presupuestosRouter.post("/tx", async (req, res) => { const p = txSchema.safeParse(req.body); if (!p.success) return res.status(400).json({ error: "invalid_payload" }); try { res.status(201).json(await createPresupuestoTx(p.data)); } catch (err) { res.status(400).json({ error: String(err) }); } });
presupuestosRouter.post("/emitir-tx", async (req, res) => {
  const parsed = emitirTxSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  try { res.status(201).json(await emitirPresupuestoTx(parsed.data)); } catch (err) { res.status(400).json({ error: String(err) }); }
});
presupuestosRouter.post("/anular-tx", async (req, res) => {
  const parsed = anularTxSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  try { res.json(await anularPresupuestoTx(parsed.data)); } catch (err) { res.status(400).json({ error: String(err) }); }
});
presupuestosRouter.get("/:numFact", async (req, res) => { const row = await getPresupuesto(req.params.numFact); if (!row) return res.status(404).json({ error: "not_found" }); res.json(row); });
presupuestosRouter.get("/:numFact/detalle", async (req, res) => res.json(await getPresupuestoDetalle(req.params.numFact)));
presupuestosRouter.post("/", async (req, res) => { try { res.status(201).json(await createPresupuesto(req.body ?? {})); } catch (err) { res.status(400).json({ error: String(err) }); } });
presupuestosRouter.put("/:numFact", async (req, res) => { try { res.json(await updatePresupuesto(req.params.numFact, req.body ?? {})); } catch (err) { res.status(400).json({ error: String(err) }); } });
presupuestosRouter.delete("/:numFact", async (req, res) => { try { res.json(await deletePresupuesto(req.params.numFact)); } catch (err) { res.status(400).json({ error: String(err) }); } });
