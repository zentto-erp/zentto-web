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
import { emitVentaAccountingEntry, voidVentaAccountingEntry } from "./ventas-contabilidad.service.js";
import { emitBusinessNotification } from "../_shared/notify.js";

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

    // Generate accounting entry (best effort, never blocks)
    let contabilidad: { ok: boolean; asientoId?: number | null; numeroAsiento?: string | null } = { ok: false };
    if (data.ok && tipoOperacion === "FACT") {
      try {
        const doc = parsed.data.documento;
        const codCliente = String(doc.CODIGO ?? doc.COD_CLIENTE ?? "").trim();
        const fecha = String(doc.FECHA ?? new Date().toISOString().slice(0, 10));
        const subtotal = Number(doc.SUBTOTAL ?? doc.MONTO_GRA ?? data.saldoPendiente ?? 0);
        const ivaAmount = Number(doc.IVA ?? 0);
        const total = Number(doc.TOTAL ?? 0);
        const pago = String(doc.PAGO ?? "").toUpperCase();
        const isPaid = ["CONTADO", "EFECTIVO", "PAGADA", "S"].includes(pago);

        contabilidad = await emitVentaAccountingEntry(
          {
            numDoc: data.numFact,
            tipoOperacion,
            codCliente,
            fecha,
            subtotal,
            iva: ivaAmount,
            total,
            moneda: String(doc.MONEDA ?? "VES"),
            tasaCambio: Number(doc.TASA_CAMBIO ?? 1),
            isPaid,
          },
          String(doc.COD_USUARIO ?? "API")
        );
      } catch {
        // Never block the sales operation
      }
    }

    // Notify: enviar notificación de factura (best-effort)
    if (data.ok && tipoOperacion === "FACT") {
      const doc = parsed.data.documento;
      const email = String(doc.EMAIL ?? doc.CORREO ?? "").trim();
      if (email) {
        emitBusinessNotification({
          event: "INVOICE_CREATED",
          to: email,
          subject: `Factura ${data.numFact} emitida`,
          data: { Factura: data.numFact ?? "", Cliente: String(doc.NOMBRE ?? ""), Total: String(doc.TOTAL ?? "0") },
        }).catch(() => {});
      }
    }

    res.status(201).json({ ...data, contabilidad });
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

    // Void linked accounting entry (best effort, never blocks)
    let contabilidad: { ok: boolean; asientoId?: number | null; numeroAsiento?: string | null } = { ok: false };
    if (data.ok) {
      try {
        contabilidad = await voidVentaAccountingEntry(
          tipoOperacion,
          parsed.data.numFact,
          parsed.data.motivo
        );
      } catch {
        // Never block the void operation
      }
    }

    res.json({ ...data, contabilidad });
  } catch (err) {
    res.status(400).json({ error: String(err) });
  }
});

documentosVentaRouter.post("/facturar-desde-pedido-tx", async (req, res) => {
  const parsed = facturarPedidoSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  try {
    const data = await facturarDesdePedidoTx(parsed.data);

    // Generate accounting entry for the new invoice (best effort)
    let contabilidad: { ok: boolean; asientoId?: number | null; numeroAsiento?: string | null } = { ok: false };
    if (data.ok && data.facturaResult?.numFact) {
      try {
        const factura = parsed.data.factura ?? {};
        const codCliente = String(factura.CODIGO ?? factura.COD_CLIENTE ?? "").trim();
        const total = Number(factura.TOTAL ?? 0);

        if (total > 0) {
          contabilidad = await emitVentaAccountingEntry(
            {
              numDoc: data.facturaResult.numFact,
              tipoOperacion: "FACT",
              codCliente,
              fecha: String(factura.FECHA ?? new Date().toISOString().slice(0, 10)),
              subtotal: Number(factura.SUBTOTAL ?? total),
              iva: Number(factura.IVA ?? 0),
              total,
              isPaid: false,
            },
            String(factura.COD_USUARIO ?? "API")
          );
        }
      } catch {
        // Never block
      }
    }

    res.status(201).json({ ...data, contabilidad });
  } catch (err) {
    res.status(400).json({ error: String(err) });
  }
});

