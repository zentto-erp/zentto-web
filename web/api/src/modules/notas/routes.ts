import { Router } from "express";
import {
  getNota,
  getNotas,
  getDetalleNota,
  emitirNotaTx,
  anularNotaTx
} from "./service.js";
import { TipoOperacionVenta } from "../documentos-venta/service.js";

export const notasRouter = Router();

notasRouter.get("/", async (req, res) => {
  try {
    const data = await getNotas({
      numNota: req.query.numNota as string,
      tipo: req.query.tipo as TipoOperacionVenta,
      codUsuario: req.query.codUsuario as string,
      from: req.query.from as string,
      to: req.query.to as string,
      page: req.query.page as string,
      pageSize: req.query.pageSize as string
    });
    return res.json(data);
  } catch (err: any) {
    return res.status(400).json({ error: err.message || String(err) });
  }
});

notasRouter.post("/emitir-tx", async (req, res) => {
  try {
    const data = await emitirNotaTx(req.body);
    return res.status(201).json(data);
  } catch (err: any) {
    return res.status(400).json({ error: err.message || String(err) });
  }
});

notasRouter.post("/anular-tx", async (req, res) => {
  try {
    await anularNotaTx(req.body);
    return res.json({ ok: true });
  } catch (err: any) {
    return res.status(400).json({ error: err.message || String(err) });
  }
});

notasRouter.get("/:tipo/:num", async (req, res) => {
  try {
    const data = await getNota(req.params.tipo as TipoOperacionVenta, req.params.num);
    if (!data.row) return res.status(404).json({ error: "not_found" });
    return res.json(data.row);
  } catch (err: any) {
    return res.status(400).json({ error: err.message || String(err) });
  }
});

notasRouter.get("/:tipo/:num/detalle", async (req, res) => {
  try {
    const data = await getDetalleNota(req.params.tipo as TipoOperacionVenta, req.params.num);
    return res.json(data);
  } catch (err: any) {
    return res.status(400).json({ error: err.message || String(err) });
  }
});
