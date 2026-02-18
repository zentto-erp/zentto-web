import { Router } from "express";
import { z } from "zod";
import {
  aplicarCobro,
  getDocumentosPendientes,
  getSaldoCliente,
  AplicarCobroInput,
} from "./cxc.service.js";
import { getPool, sql } from "../../db/mssql.js";

const router = Router();

/**
 * POST /v1/cxc/aplicar-cobro-tx
 * Aplica un cobro a documentos pendientes (transacción atómica)
 * Optimizado: Usa Stored Procedure con XML para SQL Server 2012
 */
router.post("/aplicar-cobro-tx", async (req, res, next) => {
  try {
    const input: AplicarCobroInput = req.body;

    // Validación básica
    if (!input.codCliente) {
      return res.status(400).json({
        success: false,
        message: "Código de cliente requerido",
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

    // Generar requestId si no viene
    if (!input.requestId) {
      input.requestId = `req_${Date.now()}_${Math.random()
        .toString(36)
        .substr(2, 9)}`;
    }

    // Ejecutar el cobro vía SP
    const result = await aplicarCobro(input);

    if (result.success) {
      res.json({
        success: true,
        numRecibo: result.numRecibo,
        message: result.message,
        requestId: input.requestId,
      });
    } else {
      res.status(400).json({
        success: false,
        message: result.message,
        requestId: input.requestId,
      });
    }
  } catch (err) {
    next(err);
  }
});

/**
 * GET /v1/cxc/documentos
 * Lista documentos de CxC (facturas, notas, etc.)
 */
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

    const pool = await getPool();
    const request = new sql.Request(pool);

    request.input("CodCliente", sql.NVarChar(20), parsed.data.codCliente || null);
    request.input("TipoDoc", sql.NVarChar(10), parsed.data.tipoDoc || null);
    request.input("Estado", sql.NVarChar(15), parsed.data.estado || null);
    request.input("FechaDesde", sql.Date, parsed.data.fechaDesde || null);
    request.input("FechaHasta", sql.Date, parsed.data.fechaHasta || null);
    request.input("Page", sql.Int, parseInt(parsed.data.page!));
    request.input("Limit", sql.Int, parseInt(parsed.data.limit!));

    const result = await request.execute("sp_CxC_Documentos_List");

    res.json({
      success: true,
      data: result.recordset || [],
      page: parseInt(parsed.data.page!),
      limit: parseInt(parsed.data.limit!),
      total: result.recordset?.length || 0,
    });
  } catch (err) {
    // Si el SP no existe, devolver datos de ejemplo
    res.json({
      success: true,
      data: [],
      message: "Use /documentos-pendientes/:codCliente para documentos pendientes específicos",
    });
  }
});

/**
 * GET /v1/cxc/documentos-pendientes/:codCliente
 * Obtiene los documentos pendientes de un cliente
 */
router.get("/documentos-pendientes/:codCliente", async (req, res, next) => {
  try {
    const { codCliente } = req.params;
    const documentos = await getDocumentosPendientes(codCliente);

    res.json({
      success: true,
      data: documentos,
    });
  } catch (err) {
    next(err);
  }
});

/**
 * GET /v1/cxc/saldo/:codCliente
 * Obtiene el saldo de un cliente
 */
router.get("/saldo/:codCliente", async (req, res, next) => {
  try {
    const { codCliente } = req.params;
    const saldo = await getSaldoCliente(codCliente);

    res.json({
      success: true,
      data: saldo,
    });
  } catch (err) {
    next(err);
  }
});

export const cxcRouter = router;
export default router;
