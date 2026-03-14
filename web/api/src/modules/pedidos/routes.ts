import { Router } from "express";
import {
  getPedido,
  getPedidos,
  getDetallePedido,
  emitirPedidoTx,
  anularPedidoTx
} from "./service.js";

export const pedidosRouter = Router();

pedidosRouter.get("/", async (req, res) => {
  try {
    const data = await getPedidos(req.query as any);
    return res.json(data);
  } catch (err: any) {
    return res.status(400).json({ error: err.message || String(err) });
  }
});

pedidosRouter.post("/emitir-tx", async (req, res) => {
  try {
    const data = await emitirPedidoTx(req.body);
    return res.status(201).json(data);
  } catch (err: any) {
    return res.status(400).json({ error: err.message || String(err) });
  }
});

pedidosRouter.post("/anular-tx", async (req, res) => {
  try {
    await anularPedidoTx(req.body);
    return res.json({ ok: true });
  } catch (err: any) {
    return res.status(400).json({ error: err.message || String(err) });
  }
});

pedidosRouter.get("/:num", async (req, res) => {
  try {
    const data = await getPedido(req.params.num);
    if (!data.row) return res.status(404).json({ error: "not_found" });
    return res.json(data.row);
  } catch (err: any) {
    return res.status(400).json({ error: err.message || String(err) });
  }
});

pedidosRouter.get("/:num/detalle", async (req, res) => {
  try {
    const data = await getDetallePedido(req.params.num);
    return res.json(data);
  } catch (err: any) {
    return res.status(400).json({ error: err.message || String(err) });
  }
});
