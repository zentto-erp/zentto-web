import { Router } from "express";
import {
  getCotizacion,
  getCotizaciones,
  getDetalleCotizacion,
  emitirCotizacionTx,
  anularCotizacionTx
} from "./service.js";

export const cotizacionesRouter = Router();

cotizacionesRouter.get("/", async (req, res) => {
  try {
    const data = await getCotizaciones(req.query as any);
    return res.json(data);
  } catch (err: any) {
    return res.status(400).json({ error: err.message || String(err) });
  }
});

cotizacionesRouter.post("/emitir-tx", async (req, res) => {
  try {
    const data = await emitirCotizacionTx(req.body);
    return res.status(201).json(data);
  } catch (err: any) {
    return res.status(400).json({ error: err.message || String(err) });
  }
});

cotizacionesRouter.post("/anular-tx", async (req, res) => {
  try {
    await anularCotizacionTx(req.body);
    return res.json({ ok: true });
  } catch (err: any) {
    return res.status(400).json({ error: err.message || String(err) });
  }
});

cotizacionesRouter.get("/:num", async (req, res) => {
  try {
    const data = await getCotizacion(req.params.num);
    if (!data.row) return res.status(404).json({ error: "not_found" });
    return res.json(data.row);
  } catch (err: any) {
    return res.status(400).json({ error: err.message || String(err) });
  }
});

cotizacionesRouter.get("/:num/detalle", async (req, res) => {
  try {
    const data = await getDetalleCotizacion(req.params.num);
    return res.json(data);
  } catch (err: any) {
    return res.status(400).json({ error: err.message || String(err) });
  }
});
