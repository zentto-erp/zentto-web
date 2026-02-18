import { Router } from "express";
import { z } from "zod";
import {
  anularDocumentoVentaTx,
  emitirDocumentoVentaTx,
  facturarDesdePedidoTx,
  getDetalleDocumentoVenta,
  getDocumentoVenta,
  listDocumentosVenta,
  normalizeTipoOperacionVenta
} from "./service.js";

export const documentosVentaRouter = Router();

const listSchema = z.object({
  tipoOperacion: z.string(),
  search: z.string().optional(),
  codigo: z.string().optional(),
  from: z.string().optional(),
  to: z.string().optional(),
  page: z.string().optional(),
  limit: z.string().optional()
});

const emitirSchema = z.object({
  tipoOperacion: z.string(),
  documento: z.record(z.any()),
  detalle: z.array(z.record(z.any())).min(1),
  formasPago: z.array(z.record(z.any())).optional().default([]),
  options: z.record(z.any()).optional()
});

const anularSchema = z.object({
  tipoOperacion: z.string(),
  numFact: z.string().min(1),
  codUsuario: z.string().optional(),
  motivo: z.string().optional()
});

const facturarPedidoSchema = z.object({
  numFactPedido: z.string().min(1),
  factura: z.record(z.any()),
  formasPago: z.array(z.record(z.any())).optional(),
  options: z.object({
    generarCxC: z.boolean().optional(),
    actualizarSaldosCliente: z.boolean().optional()
  }).optional()
});

documentosVentaRouter.get("/", async (req, res) => {
  const parsed = listSchema.safeParse(req.query);
  if (!parsed.success) return res.status(400).json({ error: "invalid_query", issues: parsed.error.flatten() });
  try {
    const tipoOperacion = normalizeTipoOperacionVenta(parsed.data.tipoOperacion);
    const data = await listDocumentosVenta({ ...parsed.data, tipoOperacion });
    res.json(data);
  } catch (err) {
    res.status(400).json({ error: String(err) });
  }
});

documentosVentaRouter.get("/:tipoOperacion/:numFact", async (req, res) => {
  try {
    const tipoOperacion = normalizeTipoOperacionVenta(req.params.tipoOperacion);
    const data = await getDocumentoVenta(tipoOperacion, req.params.numFact);
    if (!data.row) return res.status(404).json({ error: "not_found" });
    res.json(data.executionMode ? { ...data.row, executionMode: data.executionMode } : data.row);
  } catch (err) {
    res.status(400).json({ error: String(err) });
  }
});

documentosVentaRouter.get("/:tipoOperacion/:numFact/detalle", async (req, res) => {
  try {
    const tipoOperacion = normalizeTipoOperacionVenta(req.params.tipoOperacion);
    const data = await getDetalleDocumentoVenta(tipoOperacion, req.params.numFact);
    res.json(data);
  } catch (err) {
    res.status(400).json({ error: String(err) });
  }
});

documentosVentaRouter.post("/emitir-tx", async (req, res) => {
  const parsed = emitirSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  try {
    const tipoOperacion = normalizeTipoOperacionVenta(parsed.data.tipoOperacion);
    const data = await emitirDocumentoVentaTx({ ...parsed.data, tipoOperacion });
    res.status(201).json(data);
  } catch (err) {
    res.status(400).json({ error: String(err) });
  }
});

documentosVentaRouter.post("/anular-tx", async (req, res) => {
  const parsed = anularSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  try {
    const tipoOperacion = normalizeTipoOperacionVenta(parsed.data.tipoOperacion);
    const data = await anularDocumentoVentaTx({ ...parsed.data, tipoOperacion });
    res.json(data);
  } catch (err) {
    res.status(400).json({ error: String(err) });
  }
});

documentosVentaRouter.post("/facturar-desde-pedido-tx", async (req, res) => {
  const parsed = facturarPedidoSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  try {
    const data = await facturarDesdePedidoTx(parsed.data);
    res.status(201).json(data);
  } catch (err) {
    res.status(400).json({ error: String(err) });
  }
});

