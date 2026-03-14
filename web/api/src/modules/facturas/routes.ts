import { Router } from "express";
import {
  getFactura,
  getFacturas,
  getDetalleFactura,
  emitirFacturaTx,
  anularFacturaTx
} from "./service.js";

export const facturasRouter = Router();

facturasRouter.get("/", async (req, res) => {
  try {
    const data = await getFacturas(req.query as any);
    return res.json(data);
  } catch (err: any) {
    return res.status(400).json({ error: err.message || String(err) });
  }
});

facturasRouter.post("/emitir-tx", async (req, res) => {
  try {
    const data = await emitirFacturaTx(req.body);
    return res.status(201).json(data);
  } catch (err: any) {
    return res.status(400).json({ error: err.message || String(err) });
  }
});

facturasRouter.post("/anular-tx", async (req, res) => {
  try {
    await anularFacturaTx(req.body);
    return res.json({ ok: true });
  } catch (err: any) {
    return res.status(400).json({ error: err.message || String(err) });
  }
});

facturasRouter.get("/:num", async (req, res) => {
  try {
    const data = await getFactura(req.params.num);
    if (!data.row) return res.status(404).json({ error: "not_found" });
    return res.json(data.row);
  } catch (err: any) {
    return res.status(400).json({ error: err.message || String(err) });
  }
});

facturasRouter.get("/:num/detalle", async (req, res) => {
  try {
    const data = await getDetalleFactura(req.params.num);
    return res.json(data);
  } catch (err: any) {
    return res.status(400).json({ error: err.message || String(err) });
  }
});
