import { Router } from "express";
import { z } from "zod";
import {
  anularPedidoTx,
  createPedido,
  createPedidoTx,
  deletePedido,
  emitirPedidoTx,
  facturarPedidoTx,
  getPedido,
  getPedidoDetalle,
  listPedidos,
  updatePedido
} from "./service.js";

export const pedidosRouter = Router();
const qSchema = z.object({ search: z.string().optional(), codigo: z.string().optional(), page: z.string().optional(), limit: z.string().optional() });
const txSchema = z.object({ pedido: z.record(z.any()), detalle: z.array(z.record(z.any())).default([]) });
const emitirSchema = z.object({
  pedido: z.record(z.any()),
  detalle: z.array(z.record(z.any())).min(1),
  options: z.object({ comprometerInventario: z.boolean().optional() }).optional()
});
const anularSchema = z.object({
  numFact: z.string().min(1),
  codUsuario: z.string().optional(),
  motivo: z.string().optional(),
  revertirInventario: z.boolean().optional()
});
const facturarSchema = z.object({
  numFactPedido: z.string().min(1),
  factura: z.record(z.any()),
  formasPago: z.array(z.record(z.any())).optional(),
  options: z.object({
    generarCxC: z.boolean().optional(),
    actualizarSaldosCliente: z.boolean().optional()
  }).optional()
});

pedidosRouter.get("/", async (req, res) => { const q = qSchema.safeParse(req.query); if (!q.success) return res.status(400).json({ error: "invalid_query" }); res.json(await listPedidos(q.data)); });
pedidosRouter.post("/tx", async (req, res) => { const p = txSchema.safeParse(req.body); if (!p.success) return res.status(400).json({ error: "invalid_payload" }); try { res.status(201).json(await createPedidoTx(p.data)); } catch (err) { res.status(400).json({ error: String(err) }); } });
pedidosRouter.post("/emitir-tx", async (req, res) => {
  const p = emitirSchema.safeParse(req.body);
  if (!p.success) return res.status(400).json({ error: "invalid_payload", issues: p.error.flatten() });
  try {
    res.status(201).json(await emitirPedidoTx(p.data));
  } catch (err) {
    res.status(400).json({ error: String(err) });
  }
});
pedidosRouter.post("/anular-tx", async (req, res) => {
  const p = anularSchema.safeParse(req.body);
  if (!p.success) return res.status(400).json({ error: "invalid_payload", issues: p.error.flatten() });
  try {
    res.json(await anularPedidoTx(p.data));
  } catch (err) {
    res.status(400).json({ error: String(err) });
  }
});
pedidosRouter.post("/facturar-tx", async (req, res) => {
  const p = facturarSchema.safeParse(req.body);
  if (!p.success) return res.status(400).json({ error: "invalid_payload", issues: p.error.flatten() });
  try {
    res.json(await facturarPedidoTx(p.data));
  } catch (err) {
    res.status(400).json({ error: String(err) });
  }
});
pedidosRouter.get("/:numFact", async (req, res) => {
  const data = await getPedido(req.params.numFact);
  if (!data.row) return res.status(404).json({ error: "not_found" });
  res.json(data.executionMode ? { ...data.row, executionMode: data.executionMode } : data.row);
});
pedidosRouter.get("/:numFact/detalle", async (req, res) => res.json(await getPedidoDetalle(req.params.numFact)));
pedidosRouter.post("/", async (req, res) => { try { res.status(201).json(await createPedido(req.body ?? {})); } catch (err) { res.status(400).json({ error: String(err) }); } });
pedidosRouter.put("/:numFact", async (req, res) => { try { res.json(await updatePedido(req.params.numFact, req.body ?? {})); } catch (err) { res.status(400).json({ error: String(err) }); } });
pedidosRouter.delete("/:numFact", async (req, res) => { try { res.json(await deletePedido(req.params.numFact)); } catch (err) { res.status(400).json({ error: String(err) }); } });
