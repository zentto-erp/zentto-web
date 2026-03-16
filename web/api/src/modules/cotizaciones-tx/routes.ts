import { Router } from "express";
import { z } from "zod";
import { emitirCotizacionTx } from "./cotizaciones-tx.service.js";

export const cotizacionesTxRouter = Router();

const emitirTxSchema = z.object({
  cotizacion: z.record(z.any()),
  detalle: z.array(z.record(z.any())).min(1),
  codUsuario: z.string().optional(),
});

/**
 * POST /v1/cotizaciones/emitir-tx
 * Emite una cotizacion completa (transaccion atomica)
 * usando el modulo canonico DocumentosVenta (TIPO_OPERACION=COTIZ).
 */
cotizacionesTxRouter.post("/emitir-tx", async (req, res) => {
  const parsed = emitirTxSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  }

  try {
    const result = await emitirCotizacionTx(parsed.data);
    if (result.success) {
      return res.status(201).json({
        success: true,
        numFact: result.numFact,
        detalleRows: result.detalleRows,
      });
    } else {
      return res.status(400).json({ success: false, message: result.message });
    }
  } catch (err) {
    return res.status(400).json({ error: String(err) });
  }
});
