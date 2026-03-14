import { Router } from "express";
import {
  getOrden,
  getOrdenes,
  getDetalleOrden,
  emitirOrdenTx,
  anularOrdenTx
} from "./service.js";

export const ordenesRouter = Router();

ordenesRouter.get("/", async (req, res) => {
  try {
    const data = await getOrdenes(req.query as any);
    return res.json(data);
  } catch (err: any) {
    return res.status(400).json({ error: err.message || String(err) });
  }
});

ordenesRouter.post("/emitir-tx", async (req, res) => {
  try {
    const data = await emitirOrdenTx(req.body);
    return res.status(201).json(data);
  } catch (err: any) {
    return res.status(400).json({ error: err.message || String(err) });
  }
});

ordenesRouter.post("/anular-tx", async (req, res) => {
  try {
    await anularOrdenTx(req.body);
    return res.json({ ok: true });
  } catch (err: any) {
    return res.status(400).json({ error: err.message || String(err) });
  }
});

ordenesRouter.get("/:num", async (req, res) => {
  try {
    const data = await getOrden(req.params.num);
    if (!data.row) return res.status(404).json({ error: "not_found" });
    return res.json(data.row);
  } catch (err: any) {
    return res.status(400).json({ error: err.message || String(err) });
  }
});

ordenesRouter.get("/:num/detalle", async (req, res) => {
  try {
    const data = await getDetalleOrden(req.params.num);
    return res.json(data);
  } catch (err: any) {
    return res.status(400).json({ error: err.message || String(err) });
  }
});
