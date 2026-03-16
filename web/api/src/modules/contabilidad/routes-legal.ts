import { Router } from "express";
import { z } from "zod";

import {
  listInflationIndices,
  upsertInflationIndex,
  bulkLoadIndices,
  listMonetaryClassifications,
  upsertMonetaryClassification,
  autoClassifyAccounts,
  calculateInflationAdjustment,
  postInflationAdjustment,
  voidInflationAdjustment,
  getBalanceReexpresado,
  getREME
} from "./inflacion.service.js";

import {
  listTemplates,
  getTemplate,
  upsertTemplate,
  deleteTemplate,
  renderTemplate
} from "./templates.service.js";

import {
  listEquityMovements,
  insertEquityMovement,
  updateEquityMovement,
  deleteEquityMovement,
  getEquityChangesReport
} from "./patrimonio.service.js";

export const legalRouter = Router();

// ─── Inflación: Indices ──────────────────────────────────────────────────────

legalRouter.get("/inflacion/indices", async (req, res) => {
  try {
    const data = await listInflationIndices({
      countryCode: req.query.countryCode as string,
      indexName: req.query.indexName as string,
      yearFrom: req.query.yearFrom ? Number(req.query.yearFrom) : undefined,
      yearTo: req.query.yearTo ? Number(req.query.yearTo) : undefined,
    });
    return res.json(data);
  } catch (err: any) {
    return res.status(500).json({ error: err.message });
  }
});

legalRouter.post("/inflacion/indices", async (req, res) => {
  const schema = z.object({
    countryCode: z.string().length(2),
    indexName: z.string().min(1),
    periodCode: z.string().length(6),
    indexValue: z.number().positive(),
    sourceReference: z.string().optional(),
  });
  const parsed = schema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: "invalid_body", issues: parsed.error.flatten() });

  try {
    const data = await upsertInflationIndex(parsed.data);
    return res.json(data);
  } catch (err: any) {
    return res.status(500).json({ error: err.message });
  }
});

legalRouter.post("/inflacion/indices/bulk", async (req, res) => {
  const schema = z.object({
    countryCode: z.string().length(2),
    indexName: z.string().min(1),
    xmlData: z.string().min(1),
  });
  const parsed = schema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: "invalid_body", issues: parsed.error.flatten() });

  try {
    const data = await bulkLoadIndices(parsed.data);
    return res.json(data);
  } catch (err: any) {
    return res.status(500).json({ error: err.message });
  }
});

// ─── Inflación: Clasificación Monetaria ──────────────────────────────────────

legalRouter.get("/inflacion/clasificaciones", async (req, res) => {
  try {
    const data = await listMonetaryClassifications({
      classification: req.query.classification as string,
      search: req.query.search as string,
    });
    return res.json(data);
  } catch (err: any) {
    return res.status(500).json({ error: err.message });
  }
});

legalRouter.post("/inflacion/clasificaciones", async (req, res) => {
  const schema = z.object({
    accountId: z.number().int().positive(),
    classification: z.enum(["MONETARY", "NON_MONETARY"]),
    subClassification: z.string().optional(),
    reexpressionAccountId: z.number().optional(),
  });
  const parsed = schema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: "invalid_body", issues: parsed.error.flatten() });

  try {
    const data = await upsertMonetaryClassification(parsed.data);
    return res.json(data);
  } catch (err: any) {
    return res.status(500).json({ error: err.message });
  }
});

legalRouter.post("/inflacion/auto-clasificar", async (_req, res) => {
  try {
    const data = await autoClassifyAccounts();
    return res.json(data);
  } catch (err: any) {
    return res.status(500).json({ error: err.message });
  }
});

// ─── Inflación: Cálculo y publicación ────────────────────────────────────────

legalRouter.post("/inflacion/calcular", async (req, res) => {
  const schema = z.object({
    periodCode: z.string().length(6),
    fiscalYear: z.number().int().min(2000).max(2099),
  });
  const parsed = schema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: "invalid_body", issues: parsed.error.flatten() });

  try {
    const data = await calculateInflationAdjustment(parsed.data);
    return res.json(data);
  } catch (err: any) {
    return res.status(500).json({ error: err.message });
  }
});

legalRouter.post("/inflacion/:id/publicar", async (req, res) => {
  try {
    const data = await postInflationAdjustment(Number(req.params.id));
    return res.json(data);
  } catch (err: any) {
    return res.status(500).json({ error: err.message });
  }
});

legalRouter.post("/inflacion/:id/anular", async (req, res) => {
  try {
    const data = await voidInflationAdjustment(Number(req.params.id), req.body.motivo);
    return res.json(data);
  } catch (err: any) {
    return res.status(500).json({ error: err.message });
  }
});

// ─── Reportes Legales ────────────────────────────────────────────────────────

legalRouter.get("/reportes-legales/balance-reexpresado", async (req, res) => {
  const schema = z.object({ fechaCorte: z.string().min(1) });
  const parsed = schema.safeParse(req.query);
  if (!parsed.success) return res.status(400).json({ error: "invalid_query", issues: parsed.error.flatten() });

  try {
    const data = await getBalanceReexpresado(parsed.data.fechaCorte);
    return res.json(data);
  } catch (err: any) {
    return res.status(500).json({ error: err.message });
  }
});

legalRouter.get("/reportes-legales/reme", async (req, res) => {
  const schema = z.object({ fechaDesde: z.string().min(1), fechaHasta: z.string().min(1) });
  const parsed = schema.safeParse(req.query);
  if (!parsed.success) return res.status(400).json({ error: "invalid_query", issues: parsed.error.flatten() });

  try {
    const data = await getREME(parsed.data.fechaDesde, parsed.data.fechaHasta);
    return res.json(data);
  } catch (err: any) {
    return res.status(500).json({ error: err.message });
  }
});

legalRouter.get("/reportes-legales/cambios-patrimonio", async (req, res) => {
  const schema = z.object({ fiscalYear: z.string().min(4) });
  const parsed = schema.safeParse(req.query);
  if (!parsed.success) return res.status(400).json({ error: "invalid_query", issues: parsed.error.flatten() });

  try {
    const data = await getEquityChangesReport({ fiscalYear: Number(parsed.data.fiscalYear) });
    return res.json(data);
  } catch (err: any) {
    return res.status(500).json({ error: err.message });
  }
});

// ─── Plantillas ──────────────────────────────────────────────────────────────

legalRouter.get("/plantillas", async (req, res) => {
  try {
    const data = await listTemplates({
      countryCode: req.query.countryCode as string,
      reportCode: req.query.reportCode as string,
    });
    return res.json(data);
  } catch (err: any) {
    return res.status(500).json({ error: err.message });
  }
});

legalRouter.get("/plantillas/:id", async (req, res) => {
  try {
    const data = await getTemplate(Number(req.params.id));
    if (!data) return res.status(404).json({ error: "template_not_found" });
    return res.json(data);
  } catch (err: any) {
    return res.status(500).json({ error: err.message });
  }
});

legalRouter.post("/plantillas", async (req, res) => {
  try {
    const data = await upsertTemplate(req.body);
    return res.json(data);
  } catch (err: any) {
    return res.status(500).json({ error: err.message });
  }
});

legalRouter.delete("/plantillas/:id", async (req, res) => {
  try {
    const data = await deleteTemplate(Number(req.params.id));
    return res.json(data);
  } catch (err: any) {
    return res.status(500).json({ error: err.message });
  }
});

legalRouter.post("/plantillas/:id/render", async (req, res) => {
  try {
    const data = await renderTemplate(Number(req.params.id), {
      fechaDesde: req.body.fechaDesde,
      fechaHasta: req.body.fechaHasta,
      fechaCorte: req.body.fechaCorte,
    });
    return res.json(data);
  } catch (err: any) {
    return res.status(500).json({ error: err.message });
  }
});

// ─── Patrimonio ──────────────────────────────────────────────────────────────

legalRouter.get("/patrimonio/movimientos", async (req, res) => {
  const schema = z.object({ fiscalYear: z.string().min(4) });
  const parsed = schema.safeParse(req.query);
  if (!parsed.success) return res.status(400).json({ error: "invalid_query", issues: parsed.error.flatten() });

  try {
    const data = await listEquityMovements({ fiscalYear: Number(parsed.data.fiscalYear) });
    return res.json(data);
  } catch (err: any) {
    return res.status(500).json({ error: err.message });
  }
});

legalRouter.post("/patrimonio/movimientos", async (req, res) => {
  const schema = z.object({
    fiscalYear: z.number().int(),
    accountCode: z.string().min(1),
    movementType: z.string().min(1),
    movementDate: z.string().min(1),
    amount: z.number(),
    journalEntryId: z.number().optional(),
    description: z.string().optional(),
  });
  const parsed = schema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: "invalid_body", issues: parsed.error.flatten() });

  try {
    const data = await insertEquityMovement(parsed.data);
    return res.json(data);
  } catch (err: any) {
    return res.status(500).json({ error: err.message });
  }
});

legalRouter.put("/patrimonio/movimientos/:id", async (req, res) => {
  try {
    const data = await updateEquityMovement(Number(req.params.id), req.body);
    return res.json(data);
  } catch (err: any) {
    return res.status(500).json({ error: err.message });
  }
});

legalRouter.delete("/patrimonio/movimientos/:id", async (req, res) => {
  try {
    const data = await deleteEquityMovement(Number(req.params.id));
    return res.json(data);
  } catch (err: any) {
    return res.status(500).json({ error: err.message });
  }
});
