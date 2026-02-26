import { Router } from "express";
import { z } from "zod";
import {
  aplicarCobro,
  listDocumentos,
  getDocumentosPendientes,
  getSaldoCliente,
  type AplicarCobroInput,
} from "./cxc.service.js";

const router = Router();

router.post("/aplicar-cobro-tx", async (req, res, next) => {
  try {
    const input: AplicarCobroInput = req.body;

    if (!input.codCliente) {
      return res.status(400).json({
        success: false,
        message: "Codigo de cliente requerido",
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

    const result = await aplicarCobro(input);
    if (!result.success) {
      return res.status(400).json({
        success: false,
        message: result.message,
        requestId: input.requestId,
      });
    }

    return res.json({
      success: true,
      numRecibo: result.numRecibo,
      message: result.message,
      requestId: input.requestId,
    });
  } catch (err) {
    return next(err);
  }
});

router.get("/documentos", async (req, res, next) => {
  try {
    const querySchema = z.object({
      codCliente: z.string().optional(),
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
      codCliente: parsed.data.codCliente,
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

router.get("/documentos-pendientes/:codCliente", async (req, res, next) => {
  try {
    const { codCliente } = req.params;
    const documentos = await getDocumentosPendientes(codCliente);
    return res.json({ success: true, data: documentos });
  } catch (err) {
    return next(err);
  }
});

router.get("/saldo/:codCliente", async (req, res, next) => {
  try {
    const { codCliente } = req.params;
    const saldo = await getSaldoCliente(codCliente);
    return res.json({ success: true, data: saldo });
  } catch (err) {
    return next(err);
  }
});

export const cxcRouter = router;
export default router;

