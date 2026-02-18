import { Router } from "express";
import { z } from "zod";
import {
  createCompra,
  createCompraTx,
  deleteCompra,
  emitirCompraTx,
  getCompra,
  getIndicadoresCompra,
  getDetalleCompra,
  listCompras,
  updateCompra,
  anularCompraTx
} from "./service.js";

export const comprasRouter = Router();

const qSchema = z.object({
  search: z.string().optional(),
  proveedor: z.string().optional(),
  estado: z.string().optional(),
  fechaDesde: z.string().optional(),
  fechaHasta: z.string().optional(),
  page: z.string().optional(),
  limit: z.string().optional()
});

const txSchema = z.object({
  compra: z.record(z.any()),
  detalle: z.array(z.record(z.any())).default([])
});

const emitirTxSchema = z.object({
  compra: z.record(z.any()),
  detalle: z.array(z.record(z.any())).min(1),
  options: z.object({
    actualizarInventario: z.boolean().optional(),
    generarCxP: z.boolean().optional(),
    actualizarSaldosProveedor: z.boolean().optional(),
    cxpTable: z.literal("P_Pagar").optional()
  }).optional()
});

comprasRouter.get("/", async (req, res) => {
  const parsed = qSchema.safeParse(req.query);
  if (!parsed.success) return res.status(400).json({ error: "invalid_query" });
  res.json(await listCompras(parsed.data));
});

comprasRouter.post("/tx", async (req, res) => {
  const parsed = txSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });

  try {
    res.status(201).json(await createCompraTx(parsed.data));
  } catch (err) {
    res.status(400).json({ error: String(err) });
  }
});

comprasRouter.post("/emitir-tx", async (req, res) => {
  const parsed = emitirTxSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });

  try {
    res.status(201).json(await emitirCompraTx(parsed.data));
  } catch (err) {
    res.status(400).json({ error: String(err) });
  }
});

comprasRouter.get("/:numFact", async (req, res) => {
  const data = await getCompra(req.params.numFact);
  if (!data.row) return res.status(404).json({ error: "not_found" });
  res.json(data.executionMode ? { ...data.row, executionMode: data.executionMode } : data.row);
});

comprasRouter.get("/:numFact/detalle", async (req, res) => {
  res.json(await getDetalleCompra(req.params.numFact));
});

comprasRouter.get("/:numFact/indicadores", async (req, res) => {
  const data = await getIndicadoresCompra(req.params.numFact);
  if (!data) return res.status(404).json({ error: "not_found" });
  res.json(data);
});

comprasRouter.post("/", async (req, res) => {
  try {
    res.status(201).json(await createCompra(req.body ?? {}));
  } catch (err) {
    res.status(400).json({ error: String(err) });
  }
});

comprasRouter.put("/:numFact", async (req, res) => {
  try {
    res.json(await updateCompra(req.params.numFact, req.body ?? {}));
  } catch (err) {
    res.status(400).json({ error: String(err) });
  }
});

comprasRouter.delete("/:numFact", async (req, res) => {
  try {
    res.json(await deleteCompra(req.params.numFact));
  } catch (err) {
    res.status(400).json({ error: String(err) });
  }
});


const anularTxSchema = z.object({
  numFact: z.string().min(1),
  codUsuario: z.string().optional(),
  motivo: z.string().optional()
});

/**
 * POST /v1/compras/anular-tx
 * Anula una compra (transacción atómica)
 * Revierte inventario, anula CxP y registra movimiento
 */
comprasRouter.post("/anular-tx", async (req, res) => {
  const parsed = anularTxSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  }

  try {
    const result = await anularCompraTx(parsed.data);
    
    if (result.success) {
      return res.json({
        success: true,
        numFact: result.numFact,
        codProveedor: result.codProveedor,
        message: result.message
      });
    } else {
      return res.status(400).json({
        success: false,
        message: result.message
      });
    }
  } catch (err) {
    return res.status(400).json({ error: String(err) });
  }
});
