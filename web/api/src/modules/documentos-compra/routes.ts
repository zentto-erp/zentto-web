import { Router } from "express";
import { z } from "zod";
import { obs } from "../integrations/observability.js";
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
import { emitCompraAccountingEntry, voidCompraAccountingEntry } from "./compras-contabilidad.service.js";
import { emitBusinessNotification } from "../_shared/notify.js";

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

    // Generate accounting entry (best effort, never blocks)
    let contabilidad: { ok: boolean; asientoId?: number | null; numeroAsiento?: string | null } = { ok: false };
    if (data.ok && tipoOperacion === "COMPRA") {
      try {
        const doc = parsed.data.documento;
        const codProveedor = String(doc.COD_PROVEEDOR ?? doc.CODIGO ?? doc.SupplierCode ?? "").trim();
        const fecha = String(doc.FECHA ?? doc.DocumentDate ?? new Date().toISOString().slice(0, 10));
        const subtotal = Number(doc.SUBTOTAL ?? doc.MONTO_GRA ?? doc.SubTotal ?? 0);
        const ivaAmount = Number(doc.IVA ?? doc.TaxAmount ?? 0);
        const total = Number(doc.TOTAL ?? doc.TotalAmount ?? 0);
        const isPaid = String(doc.CANCELADA ?? doc.IsPaid ?? "N").toUpperCase() === "S";

        contabilidad = await emitCompraAccountingEntry(
          {
            numDoc: data.numFact,
            tipoOperacion,
            codProveedor,
            fecha,
            subtotal,
            iva: ivaAmount,
            total,
            moneda: String(doc.MONEDA ?? doc.CurrencyCode ?? "VES"),
            tasaCambio: Number(doc.TASA_CAMBIO ?? doc.ExchangeRate ?? 1),
            isPaid,
          },
          String(doc.COD_USUARIO ?? doc.UserCode ?? "API")
        );
      } catch {
        // Never block the purchase operation
      }
    }

    // Notify: compra emitida (best-effort)
    if (data.ok && tipoOperacion === "COMPRA") {
      const doc = parsed.data.documento;
      const email = String(doc.EMAIL ?? doc.CORREO ?? "").trim();
      if (email) {
        emitBusinessNotification({
          event: "PURCHASE_ORDER_CREATED",
          to: email,
          subject: `Orden de compra ${data.numFact} registrada`,
          data: { Documento: data.numFact ?? "", Proveedor: String(doc.NOMBRE ?? ""), Total: String(doc.TOTAL ?? "0") },
        }).catch(() => {});
      }
    }

    res.status(201).json({ ...data, contabilidad });
    if (data.ok) {
      try { obs.event('compras.documento.emitido', { entityId: data.numFact, tipoOperacion, numFact: data.numFact, userId: (req as any).user?.userId, userName: (req as any).user?.userName, companyId: (req as any).user?.companyId, module: 'compras' }); } catch { /* never blocks */ }
    }
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

    // Void linked accounting entry (best effort, never blocks)
    let contabilidad: { ok: boolean; asientoId?: number | null; numeroAsiento?: string | null } = { ok: false };
    if (data.ok) {
      try {
        contabilidad = await voidCompraAccountingEntry(
          tipoOperacion,
          parsed.data.numFact,
          parsed.data.motivo
        );
      } catch {
        // Never block the void operation
      }
    }

    res.json({ ...data, contabilidad });
    if (data.ok) {
      try { obs.audit('compras.documento.anulado', { userId: (req as any).user?.userId, userName: (req as any).user?.userName, companyId: (req as any).user?.companyId, module: 'compras', entity: 'DocumentoCompra', entityId: parsed.data.numFact, numFact: parsed.data.numFact, motivo: parsed.data.motivo }); } catch { /* never blocks */ }
    }
  } catch (err) {
    res.status(400).json({ error: String(err) });
  }
});

documentosCompraRouter.post("/cerrar-orden-con-compra-tx", async (req, res) => {
  const parsed = cerrarOrdenSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  try {
    const data = await cerrarOrdenConCompraDocumentoTx(parsed.data);

    // Generate accounting entry for the new purchase (best effort)
    let contabilidad: { ok: boolean; asientoId?: number | null; numeroAsiento?: string | null } = { ok: false };
    if (data.ok && data.compraResult?.numFact) {
      try {
        const compra = parsed.data.compra ?? {};
        const codProveedor = String(compra.COD_PROVEEDOR ?? compra.SupplierCode ?? "").trim();
        const total = Number(compra.TOTAL ?? compra.TotalAmount ?? 0);

        if (total > 0) {
          contabilidad = await emitCompraAccountingEntry(
            {
              numDoc: data.compraResult.numFact,
              tipoOperacion: "COMPRA",
              codProveedor,
              fecha: String(compra.FECHA ?? compra.DocumentDate ?? new Date().toISOString().slice(0, 10)),
              subtotal: Number(compra.SUBTOTAL ?? compra.SubTotal ?? total),
              iva: Number(compra.IVA ?? compra.TaxAmount ?? 0),
              total,
              isPaid: false,
            },
            String(compra.COD_USUARIO ?? compra.UserCode ?? "API")
          );
        }
      } catch {
        // Never block
      }
    }

    res.status(201).json({ ...data, contabilidad });
    if (data.ok) {
      try { obs.audit('compras.orden.cerrada', { userId: (req as any).user?.userId, userName: (req as any).user?.userName, companyId: (req as any).user?.companyId, module: 'compras', entity: 'OrdenCompra', entityId: parsed.data.numFactOrden, numFactOrden: parsed.data.numFactOrden, numFact: data.compraResult?.numFact }); } catch { /* never blocks */ }
    }
  } catch (err) {
    res.status(400).json({ error: String(err) });
  }
});

