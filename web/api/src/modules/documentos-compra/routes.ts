import { Router } from "express";
import { z } from "zod";
import {
  anularDocumentoCompraTx,
  cerrarOrdenConCompraDocumentoTx,
  emitirDocumentoCompraTx,
  getDetalleDocumentoCompra,
  getDocumentoCompra,
  getIndicadoresDocumentoCompra,
  listDocumentosCompra,
  normalizeTipoOperacionCompra
} from "./service.js";

export const documentosCompraRouter = Router();

const listSchema = z.object({
  tipoOperacion: z.string().optional().default("COMPRA"),
  search: z.string().optional(),
  codigo: z.string().optional(),
  proveedor: z.string().optional(),
  estado: z.string().optional(),
  fechaDesde: z.string().optional(),
  fechaHasta: z.string().optional(),
  page: z.string().optional(),
  limit: z.string().optional()
});

const emitirSchema = z.object({
  tipoOperacion: z.string(),
  documento: z.record(z.any()),
  detalle: z.array(z.record(z.any())).min(1),
  options: z.record(z.any()).optional()
});

const anularSchema = z.object({
  tipoOperacion: z.string(),
  numFact: z.string().min(1),
  codUsuario: z.string().optional(),
  motivo: z.string().optional()
});

const cerrarOrdenSchema = z.object({
  numFactOrden: z.string().min(1),
  compra: z.record(z.any()),
  detalle: z.array(z.record(z.any())).optional(),
  options: z.object({
    actualizarInventario: z.boolean().optional(),
    generarCxP: z.boolean().optional(),
    actualizarSaldosProveedor: z.boolean().optional()
  }).optional()
});

documentosCompraRouter.get("/", async (req, res) => {
  const parsed = listSchema.safeParse(req.query);
  if (!parsed.success) return res.status(400).json({ error: "invalid_query", issues: parsed.error.flatten() });
  try {
    const tipoOperacion = normalizeTipoOperacionCompra(parsed.data.tipoOperacion);
    const data = await listDocumentosCompra({ ...parsed.data, tipoOperacion });
    res.json(data);
  } catch (err) {
    res.status(400).json({ error: String(err) });
  }
});

documentosCompraRouter.get("/:tipoOperacion/:numFact", async (req, res) => {
  try {
    const tipoOperacion = normalizeTipoOperacionCompra(req.params.tipoOperacion);
    const data = await getDocumentoCompra(tipoOperacion, req.params.numFact);
    if (!data.row) return res.status(404).json({ error: "not_found" });
    res.json(data.executionMode ? { ...data.row, executionMode: data.executionMode } : data.row);
  } catch (err) {
    res.status(400).json({ error: String(err) });
  }
});

documentosCompraRouter.get("/:tipoOperacion/:numFact/detalle", async (req, res) => {
  try {
    const tipoOperacion = normalizeTipoOperacionCompra(req.params.tipoOperacion);
    const data = await getDetalleDocumentoCompra(tipoOperacion, req.params.numFact);
    res.json(data);
  } catch (err) {
    res.status(400).json({ error: String(err) });
  }
});

documentosCompraRouter.get("/:tipoOperacion/:numFact/indicadores", async (req, res) => {
  try {
    const tipoOperacion = normalizeTipoOperacionCompra(req.params.tipoOperacion);
    const data = await getIndicadoresDocumentoCompra(tipoOperacion, req.params.numFact);
    if (!data) return res.status(404).json({ error: "not_found" });
    res.json(data);
  } catch (err) {
    res.status(400).json({ error: String(err) });
  }
});

documentosCompraRouter.post("/emitir-tx", async (req, res) => {
  const parsed = emitirSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  try {
    const tipoOperacion = normalizeTipoOperacionCompra(parsed.data.tipoOperacion);
    const data = await emitirDocumentoCompraTx({ ...parsed.data, tipoOperacion });
    res.status(201).json(data);
  } catch (err) {
    res.status(400).json({ error: String(err) });
  }
});

documentosCompraRouter.post("/anular-tx", async (req, res) => {
  const parsed = anularSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  try {
    const tipoOperacion = normalizeTipoOperacionCompra(parsed.data.tipoOperacion);
    const data = await anularDocumentoCompraTx({ ...parsed.data, tipoOperacion });
    res.json(data);
  } catch (err) {
    res.status(400).json({ error: String(err) });
  }
});

documentosCompraRouter.post("/cerrar-orden-con-compra-tx", async (req, res) => {
  const parsed = cerrarOrdenSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  try {
    const data = await cerrarOrdenConCompraDocumentoTx(parsed.data);
    res.status(201).json(data);
  } catch (err) {
    res.status(400).json({ error: String(err) });
  }
});

