/**
 * Rutas de Nómina usando NominaConceptoLegal
 */
import { Router } from "express";
import { z } from "zod";
import * as conceptoLegalService from "./conceptolegal.service.js";

export const conceptoLegalRouter = Router();

// Esquemas de validación
const procesarNominaSchema = z.object({
  nomina: z.string().min(1),
  cedula: z.string().min(1),
  fechaInicio: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
  fechaHasta: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
  convencion: z.enum(["LOT", "CCT_PETROLERO", "CONSTRUCCION", "COMERCIO", "SALUD"]).optional(),
  tipoCalculo: z.enum(["MENSUAL", "SEMANAL", "QUINCENAL", "VACACIONES", "LIQUIDACION"]).optional(),
});

const procesarVacacionesSchema = z.object({
  vacacionId: z.string().min(1),
  cedula: z.string().min(1),
  fechaInicio: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
  fechaHasta: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
  fechaReintegro: z.string().regex(/^\d{4}-\d{2}-\d{2}$/).optional(),
  convencion: z.string().optional(),
});

const procesarLiquidacionSchema = z.object({
  liquidacionId: z.string().min(1),
  cedula: z.string().min(1),
  fechaRetiro: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
  causaRetiro: z.enum(["RENUNCIA", "DESPIDO", "DESPIDO_JUSTIFICADO"]).optional(),
  convencion: z.string().optional(),
});

// GET /v1/nomina/conceptos-legales - Listar conceptos de NominaConceptoLegal
conceptoLegalRouter.get("/conceptos-legales", async (req, res) => {
  try {
    const result = await conceptoLegalService.listConceptosLegales({
      convencion: req.query.convencion as string,
      tipoCalculo: req.query.tipoCalculo as string,
      tipo: req.query.tipo as string,
      activo: req.query.activo === "true",
    });
    res.json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// GET /v1/nomina/convenciones - Listar convenciones disponibles
conceptoLegalRouter.get("/convenciones", async (req, res) => {
  try {
    const result = await conceptoLegalService.getConvencionesDisponibles();
    res.json({ rows: result });
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// POST /v1/nomina/procesar-conceptolegal - Procesar nómina
conceptoLegalRouter.post("/procesar-conceptolegal", async (req, res) => {
  const parsed = procesarNominaSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  }

  try {
    const codUsuario = (req as any).user?.username || "API";
    const result = await conceptoLegalService.procesarNominaConceptoLegal({
      ...parsed.data,
      codUsuario,
    });
    res.status(result.success ? 200 : 400).json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// POST /v1/nomina/vacaciones/procesar-conceptolegal - Procesar vacaciones
conceptoLegalRouter.post("/vacaciones/procesar-conceptolegal", async (req, res) => {
  const parsed = procesarVacacionesSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  }

  try {
    const codUsuario = (req as any).user?.username || "API";
    const result = await conceptoLegalService.procesarVacacionesConceptoLegal({
      ...parsed.data,
      codUsuario,
    });
    res.status(result.success ? 200 : 400).json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// POST /v1/nomina/liquidacion/procesar-conceptolegal - Procesar liquidación
conceptoLegalRouter.post("/liquidacion/procesar-conceptolegal", async (req, res) => {
  const parsed = procesarLiquidacionSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  }

  try {
    const codUsuario = (req as any).user?.username || "API";
    const result = await conceptoLegalService.procesarLiquidacionConceptoLegal({
      ...parsed.data,
      codUsuario,
    });
    res.status(result.success ? 200 : 400).json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// POST /v1/nomina/validar-formulas - Validar fórmulas de conceptos
conceptoLegalRouter.post("/validar-formulas", async (req, res) => {
  const schema = z.object({
    convencion: z.string().optional(),
    tipoCalculo: z.string().optional(),
  });

  const parsed = schema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  }

  try {
    const result = await conceptoLegalService.validarFormulasConceptos(parsed.data);
    res.json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});
