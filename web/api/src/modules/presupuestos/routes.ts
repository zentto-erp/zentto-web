import { Router } from "express";
import {
  getPresupuesto,
  getPresupuestos,
  getDetallePresupuesto,
  emitirPresupuestoTx,
  anularPresupuestoTx
} from "./service.js";

export const presupuestosRouter = Router();

presupuestosRouter.get("/", async (req, res) => {
  try {
    const data = await getPresupuestos(req.query as any);
    return res.json(data);
  } catch (err: any) {
    return res.status(400).json({ error: err.message || String(err) });
  }
});

presupuestosRouter.post("/emitir-tx", async (req, res) => {
  try {
    const data = await emitirPresupuestoTx(req.body);
    return res.status(201).json(data);
  } catch (err: any) {
    return res.status(400).json({ error: err.message || String(err) });
  }
});

presupuestosRouter.post("/anular-tx", async (req, res) => {
  try {
    await anularPresupuestoTx(req.body);
    return res.json({ ok: true });
  } catch (err: any) {
    return res.status(400).json({ error: err.message || String(err) });
  }
});

presupuestosRouter.get("/:num", async (req, res) => {
  try {
    const data = await getPresupuesto(req.params.num);
    if (!data.row) return res.status(404).json({ error: "not_found" });
    return res.json(data.row);
  } catch (err: any) {
    return res.status(400).json({ error: err.message || String(err) });
  }
});

presupuestosRouter.get("/:num/detalle", async (req, res) => {
  try {
    const data = await getDetallePresupuesto(req.params.num);
    return res.json(data);
  } catch (err: any) {
    return res.status(400).json({ error: err.message || String(err) });
  }
});
