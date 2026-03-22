import { Router } from "express";
import { z } from "zod";
import {
  aplicarPago,
  listDocumentos,
  getDocumentosPendientes,
  getSaldoProveedor,
  type AplicarPagoInput,
} from "./cxp.service.js";
import { emitPagoAccountingEntry } from "./cxp-contabilidad.service.js";

const router = Router();

router.post("/aplicar-pago-tx", async (req, res, next) => {
  try {
    const input: AplicarPagoInput = req.body;

    if (!input.codProveedor) {
      return res.status(400).json({
        success: false,
        message: "Codigo de proveedor requerido",
      });
    }

    if (!input.documentos || input.documentos.length === 0) {
      return res.status(400).json({
        success: false,
        message: "Debe especificar al menos un documento",
      });
    }

    if (!input.formasPago || input.formasPago.length === 0) {
      return res.status(400).json({
        success: false,
        message: "Debe especificar al menos una forma de pago",
      });
    }

    if (!input.requestId) {
      input.requestId = `req_${Date.now()}_${Math.random().toString(36).slice(2, 11)}`;
    }

    const result = await aplicarPago(input);
    if (!result.success) {
      return res.status(400).json({
        success: false,
        message: result.message,
        requestId: input.requestId,
      });
    }

    // Generate accounting entry (best effort, never blocks)
    let contabilidad: { ok: boolean; asientoId?: number | null; numeroAsiento?: string | null } = { ok: false };
    try {
      contabilidad = await emitPagoAccountingEntry(
        {
          numPago: result.numPago!,
          codProveedor: input.codProveedor,
          fecha: input.fecha,
          montoTotal: input.montoTotal,
          formasPago: input.formasPago,
        },
        input.codUsuario
      );
    } catch {
      // Never block the CxP operation
    }

    return res.json({
      success: true,
      numPago: result.numPago,
      message: result.message,
      requestId: input.requestId,
      contabilidad,
    });
  } catch (err) {
    return next(err);
  }
});

router.get("/documentos", async (req, res, next) => {
  try {
    const querySchema = z.object({
      codProveedor: z.string().optional(),
      tipoDoc: z.string().optional(),
      estado: z.enum(["PENDIENTE", "PAGADO", "PARCIAL", "ANULADO", ""]).optional(),
      fechaDesde: z.string().optional(),
      fechaHasta: z.string().optional(),
      page: z.string().optional().default("1"),
      limit: z.string().optional().default("50"),
    });

    const parsed = querySchema.safeParse(req.query);
    if (!parsed.success) {
      return res.status(400).json({ error: "invalid_query", issues: parsed.error.flatten() });
    }

    const result = await listDocumentos({
      codProveedor: parsed.data.codProveedor,
      tipoDoc: parsed.data.tipoDoc,
      estado: parsed.data.estado,
      fechaDesde: parsed.data.fechaDesde,
      fechaHasta: parsed.data.fechaHasta,
      page: parseInt(parsed.data.page, 10),
      limit: parseInt(parsed.data.limit, 10),
    });

    return res.json({
      success: true,
      data: result.rows,
      page: result.page,
      limit: result.limit,
      total: result.total,
    });
  } catch (err) {
    return next(err);
  }
});

router.get("/documentos-pendientes/:codProveedor", async (req, res, next) => {
  try {
    const { codProveedor } = req.params;
    const documentos = await getDocumentosPendientes(codProveedor);
    return res.json({ success: true, data: documentos });
  } catch (err) {
    return next(err);
  }
});

router.get("/saldo/:codProveedor", async (req, res, next) => {
  try {
    const { codProveedor } = req.params;
    const saldo = await getSaldoProveedor(codProveedor);
    return res.json({ success: true, data: saldo });
  } catch (err) {
    return next(err);
  }
});

export default router;

