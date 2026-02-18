import { Router } from "express";
import { z } from "zod";
import {
  aplicarPago,
  getDocumentosPendientes,
  getSaldoProveedor,
  AplicarPagoInput,
} from "./cxp.service.js";
import { getPool, sql } from "../../db/mssql.js";

const router = Router();

/**
 * POST /v1/cxp/aplicar-pago-tx
 * Aplica un pago a documentos pendientes de proveedores (transacción atómica)
 * Optimizado: Usa Stored Procedure con XML para SQL Server 2012
 */
router.post("/aplicar-pago-tx", async (req, res, next) => {
  try {
    const input: AplicarPagoInput = req.body;

    // Validación básica
    if (!input.codProveedor) {
      return res.status(400).json({
        success: false,
        message: "Código de proveedor requerido",
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

    // Ejecutar el pago vía SP
    const result = await aplicarPago(input);

    if (result.success) {
      res.json({
        success: true,
        numPago: result.numPago,
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
 * GET /v1/cxp/documentos
 * Lista documentos de CxP (facturas, notas, etc.)
 */
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

    const pool = await getPool();
    const request = new sql.Request(pool);

    request.input("CodProveedor", sql.NVarChar(20), parsed.data.codProveedor || null);
    request.input("TipoDoc", sql.NVarChar(10), parsed.data.tipoDoc || null);
    request.input("Estado", sql.NVarChar(15), parsed.data.estado || null);
    request.input("FechaDesde", sql.Date, parsed.data.fechaDesde || null);
    request.input("FechaHasta", sql.Date, parsed.data.fechaHasta || null);
    request.input("Page", sql.Int, parseInt(parsed.data.page!));
    request.input("Limit", sql.Int, parseInt(parsed.data.limit!));

    const result = await request.execute("sp_CxP_Documentos_List");

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
      message: "Use /documentos-pendientes/:codProveedor para documentos pendientes específicos",
    });
  }
});

/**
 * GET /v1/cxp/documentos-pendientes/:codProveedor
 * Obtiene los documentos pendientes de un proveedor
 */
router.get("/documentos-pendientes/:codProveedor", async (req, res, next) => {
  try {
    const { codProveedor } = req.params;
    const documentos = await getDocumentosPendientes(codProveedor);

    res.json({
      success: true,
      data: documentos,
    });
  } catch (err) {
    next(err);
  }
});

/**
 * GET /v1/cxp/saldo/:codProveedor
 * Obtiene el saldo de un proveedor
 */
router.get("/saldo/:codProveedor", async (req, res, next) => {
  try {
    const { codProveedor } = req.params;
    const saldo = await getSaldoProveedor(codProveedor);

    res.json({
      success: true,
      data: saldo,
    });
  } catch (err) {
    next(err);
  }
});

export default router;
