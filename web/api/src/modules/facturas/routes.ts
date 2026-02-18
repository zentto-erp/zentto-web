import { Router } from "express";
import { z } from "zod";
import {
  createFacturaTx,
  emitirFacturaTx,
  getFacturaByNumero,
  getFacturas,
  getDetalleFactura,
  anularFacturaTx
} from "./service.js";

export const facturasRouter = Router();

const listSchema = z.object({
  numFact: z.string().optional(),
  codUsuario: z.string().optional(),
  from: z.string().optional(),
  to: z.string().optional(),
  page: z.string().optional(),
  pageSize: z.string().optional()
});

const txSchema = z.object({
  factura: z.record(z.any()),
  detalle: z.array(z.record(z.any())).default([])
});

const emitirTxSchema = z.object({
  factura: z.record(z.any()),
  detalle: z.array(z.record(z.any())).min(1),
  formasPago: z.array(z.record(z.any())).optional().default([]),
  options: z.object({
    actualizarInventario: z.boolean().optional(),
    generarCxC: z.boolean().optional(),
    cxcTable: z.enum(["P_Cobrar", "P_CobrarC"]).optional(),
    formaPagoTable: z.string().optional(),
    actualizarSaldosCliente: z.boolean().optional()
  }).optional()
});

facturasRouter.get("/", async (req, res) => {
  const parsed = listSchema.safeParse(req.query);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_query", issues: parsed.error.flatten() });
  }

  const data = await getFacturas(parsed.data);
  return res.json(data);
});

facturasRouter.post("/tx", async (req, res) => {
  const parsed = txSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  }

  try {
    const data = await createFacturaTx(parsed.data);
    return res.status(201).json(data);
  } catch (err) {
    return res.status(400).json({ error: String(err) });
  }
});

facturasRouter.post("/emitir-tx", async (req, res) => {
  const parsed = emitirTxSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  }

  try {
    const data = await emitirFacturaTx(parsed.data);
    return res.status(201).json(data);
  } catch (err) {
    return res.status(400).json({ error: String(err) });
  }
});

facturasRouter.get("/:numFact", async (req, res) => {
  const numFact = req.params.numFact;
  const data = await getFacturaByNumero(numFact);
  if (!data.row) return res.status(404).json({ error: "not_found" });
  return res.json(data.executionMode ? { ...data.row, executionMode: data.executionMode } : data.row);
});

facturasRouter.get("/:numFact/detalle", async (req, res) => {
  const numFact = req.params.numFact;
  const data = await getDetalleFactura(numFact);
  return res.json(data);
});


const anularTxSchema = z.object({
  numFact: z.string().min(1),
  codUsuario: z.string().optional(),
  motivo: z.string().optional()
});

/**
 * POST /v1/facturas/anular-tx
 * Anula una factura (transacción atómica)
 * Revierte inventario, anula CxC y registra movimiento
 */
facturasRouter.post("/anular-tx", async (req, res) => {
  const parsed = anularTxSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  }

  try {
    const result = await anularFacturaTx(parsed.data);
    
    if (result.success) {
      return res.json({
        success: true,
        numFact: result.numFact,
        codCliente: result.codCliente,
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
