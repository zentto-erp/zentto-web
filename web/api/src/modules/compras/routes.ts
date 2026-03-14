import { Router } from "express";
import {
  getCompra,
  getCompras,
  getDetalleCompra,
  emitirCompraTx,
  anularCompraTx
} from "./service.js";

export const comprasRouter = Router();

comprasRouter.get("/", async (req, res) => {
  try {
    const data = await getCompras(req.query as any);
    return res.json(data);
  } catch (err: any) {
    return res.status(400).json({ error: err.message || String(err) });
  }
});

comprasRouter.post("/emitir-tx", async (req, res) => {
  try {
    const data = await emitirCompraTx(req.body);
    return res.status(201).json(data);
  } catch (err: any) {
    return res.status(400).json({ error: err.message || String(err) });
  }
});

comprasRouter.post("/anular-tx", async (req, res) => {
  try {
    await anularCompraTx(req.body);
    return res.json({ ok: true });
  } catch (err: any) {
    return res.status(400).json({ error: err.message || String(err) });
  }
});

comprasRouter.get("/:num", async (req, res) => {
  try {
    const data = await getCompra(req.params.num);
    if (!data.row) return res.status(404).json({ error: "not_found" });
    return res.json(data.row);
  } catch (err: any) {
    return res.status(400).json({ error: err.message || String(err) });
  }
});

comprasRouter.get("/:num/detalle", async (req, res) => {
  try {
    const data = await getDetalleCompra(req.params.num);
    return res.json(data);
  } catch (err: any) {
    return res.status(400).json({ error: err.message || String(err) });
  }
});
