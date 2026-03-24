import { Router } from "express";
import { z } from "zod";
import { obs } from "../integrations/observability.js";

import {
  listPeriodos,
  ensureYear,
  closePeriod,
  reopenPeriod,
  generateClosingEntries,
  getChecklist
} from "./cierre.service.js";

import {
  listCentrosCosto,
  getCentroCosto,
  insertCentroCosto,
  updateCentroCosto,
  deleteCentroCosto,
  pnlByCostCenter
} from "./centros-costo.service.js";

import {
  listPresupuestos,
  getPresupuesto,
  insertPresupuesto,
  updatePresupuesto,
  deletePresupuesto,
  getVarianza
} from "./presupuestos.service.js";

// Conciliación bancaria delegada a módulo de bancos: /v1/bancos/conciliaciones

import {
  listRecurrentes,
  getRecurrente,
  insertRecurrente,
  updateRecurrente,
  deleteRecurrente,
  executeRecurrente,
  getDueRecurrentes
} from "./recurrentes.service.js";

import {
  cashFlowStatement,
  balanceCompMultiPeriod,
  pnlMultiPeriod,
  agingCxC,
  agingCxP,
  financialRatios,
  taxSummary,
  drillDown
} from "./reportes-avanzados.service.js";

import { anularAsiento, crearAsiento } from "./service.js";

export const advancedRouter = Router();

// ─── Schemas ────────────────────────────────────────────────────────────────

const paginationSchema = z.object({
  page: z.string().optional(),
  limit: z.string().optional()
});

const rangoSchema = z.object({
  fechaDesde: z.string().min(1),
  fechaHasta: z.string().min(1)
});

const fechaCorteSchema = z.object({
  fechaCorte: z.string().min(1)
});

// ─── Periodos / Cierre ─────────────────────────────────────────────────────

advancedRouter.get("/periodos", async (req, res) => {
  const schema = paginationSchema.extend({
    year: z.string().optional(),
    status: z.string().optional()
  });
  const parsed = schema.safeParse(req.query);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_query", issues: parsed.error.flatten() });
  }

  try {
    const data = await listPeriodos({
      year: parsed.data.year ? Number(parsed.data.year) : undefined,
      status: parsed.data.status,
      page: parsed.data.page ? Number(parsed.data.page) : 1,
      limit: parsed.data.limit ? Number(parsed.data.limit) : 50
    });
    return res.json(data);
  } catch (err: any) {
    return res.status(500).json({ error: String(err) });
  }
});

advancedRouter.post("/periodos/ensure-year", async (req, res) => {
  const schema = z.object({ year: z.number().int().min(2000).max(2100) });
  const parsed = schema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  }

  try {
    const result = await ensureYear(parsed.data.year);
    if (!result.success) return res.status(400).json(result);
    return res.status(201).json(result);
  } catch (err: any) {
    return res.status(500).json({ error: String(err) });
  }
});

advancedRouter.post("/periodos/:periodo/cerrar", async (req, res) => {
  const periodo = req.params.periodo;
  if (!periodo) return res.status(400).json({ error: "periodo_requerido" });

  try {
    const user = (req as any).user?.username || "API";
    const result = await closePeriod(periodo, user);
    if (!result.success) return res.status(400).json(result);
    try { obs.audit('contabilidad.mes.cerrado', {
      userId: (req as any).user?.userId,
      userName: (req as any).user?.userName,
      companyId: (req as any).user?.companyId,
      module: 'contabilidad',
      entity: 'Periodo',
      entityId: periodo
    }); } catch { /* never blocks */ }
    return res.json(result);
  } catch (err: any) {
    return res.status(500).json({ error: String(err) });
  }
});

advancedRouter.post("/periodos/:periodo/reabrir", async (req, res) => {
  const periodo = req.params.periodo;
  if (!periodo) return res.status(400).json({ error: "periodo_requerido" });

  try {
    const user = (req as any).user?.username || "API";
    const result = await reopenPeriod(periodo, user);
    if (!result.success) return res.status(400).json(result);
    return res.json(result);
  } catch (err: any) {
    return res.status(500).json({ error: String(err) });
  }
});

advancedRouter.post("/periodos/:periodo/generar-cierre", async (req, res) => {
  const periodo = req.params.periodo;
  if (!periodo) return res.status(400).json({ error: "periodo_requerido" });

  try {
    const user = (req as any).user?.username || "API";
    const result = await generateClosingEntries(periodo, user);
    if (!result.success) return res.status(400).json(result);
    return res.status(201).json(result);
  } catch (err: any) {
    return res.status(500).json({ error: String(err) });
  }
});

advancedRouter.get("/periodos/:periodo/checklist", async (req, res) => {
  const periodo = req.params.periodo;
  if (!periodo) return res.status(400).json({ error: "periodo_requerido" });

  try {
    const data = await getChecklist(periodo);
    return res.json(data);
  } catch (err: any) {
    return res.status(500).json({ error: String(err) });
  }
});

// ─── Centros de Costo ───────────────────────────────────────────────────────

advancedRouter.get("/centros-costo", async (req, res) => {
  const schema = paginationSchema.extend({
    search: z.string().optional()
  });
  const parsed = schema.safeParse(req.query);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_query", issues: parsed.error.flatten() });
  }

  try {
    const data = await listCentrosCosto({
      search: parsed.data.search,
      page: parsed.data.page ? Number(parsed.data.page) : 1,
      limit: parsed.data.limit ? Number(parsed.data.limit) : 50
    });
    return res.json(data);
  } catch (err: any) {
    return res.status(500).json({ error: String(err) });
  }
});

advancedRouter.get("/centros-costo/:code", async (req, res) => {
  try {
    const data = await getCentroCosto(req.params.code);
    if (!data) return res.status(404).json({ error: "not_found" });
    return res.json(data);
  } catch (err: any) {
    return res.status(500).json({ error: String(err) });
  }
});

advancedRouter.post("/centros-costo", async (req, res) => {
  const schema = z.object({
    code: z.string().min(1),
    name: z.string().min(1),
    parentCode: z.string().optional()
  });
  const parsed = schema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  }

  try {
    const result = await insertCentroCosto(parsed.data);
    if (!result.success) return res.status(400).json(result);
    return res.status(201).json(result);
  } catch (err: any) {
    return res.status(500).json({ error: String(err) });
  }
});

advancedRouter.put("/centros-costo/:code", async (req, res) => {
  const schema = z.object({
    name: z.string().min(1).optional(),
    parentCode: z.string().optional()
  });
  const parsed = schema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  }

  try {
    const result = await updateCentroCosto(req.params.code, parsed.data);
    if (!result.success) return res.status(400).json(result);
    return res.json(result);
  } catch (err: any) {
    return res.status(500).json({ error: String(err) });
  }
});

advancedRouter.delete("/centros-costo/:code", async (req, res) => {
  try {
    const result = await deleteCentroCosto(req.params.code);
    if (!result.success) {
      if (result.message.includes("No se encontro")) {
        return res.status(404).json(result);
      }
      return res.status(400).json(result);
    }
    return res.json(result);
  } catch (err: any) {
    return res.status(500).json({ error: String(err) });
  }
});

// ─── Presupuestos ───────────────────────────────────────────────────────────

const budgetLineSchema = z.object({
  accountCode: z.string().min(1),
  periodCode: z.string().min(1),
  amount: z.number(),
  notes: z.string().optional()
});

advancedRouter.get("/presupuestos", async (req, res) => {
  const schema = paginationSchema.extend({
    fiscalYear: z.string().optional(),
    status: z.string().optional()
  });
  const parsed = schema.safeParse(req.query);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_query", issues: parsed.error.flatten() });
  }

  try {
    const data = await listPresupuestos({
      fiscalYear: parsed.data.fiscalYear ? Number(parsed.data.fiscalYear) : undefined,
      status: parsed.data.status,
      page: parsed.data.page ? Number(parsed.data.page) : 1,
      limit: parsed.data.limit ? Number(parsed.data.limit) : 50
    });
    return res.json(data);
  } catch (err: any) {
    return res.status(500).json({ error: String(err) });
  }
});

advancedRouter.get("/presupuestos/:id", async (req, res) => {
  const id = Number(req.params.id);
  if (!Number.isFinite(id) || id <= 0) {
    return res.status(400).json({ error: "invalid_id" });
  }

  try {
    const data = await getPresupuesto(id);
    if (!data.cabecera) return res.status(404).json({ error: "not_found" });
    return res.json(data);
  } catch (err: any) {
    return res.status(500).json({ error: String(err) });
  }
});

advancedRouter.post("/presupuestos", async (req, res) => {
  const schema = z.object({
    name: z.string().min(1),
    fiscalYear: z.number().int().min(2000).max(2100),
    costCenterCode: z.string().optional(),
    lines: z.array(budgetLineSchema).min(1)
  });
  const parsed = schema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  }

  try {
    const result = await insertPresupuesto(parsed.data);
    if (!result.success) return res.status(400).json(result);
    return res.status(201).json(result);
  } catch (err: any) {
    return res.status(500).json({ error: String(err) });
  }
});

advancedRouter.put("/presupuestos/:id", async (req, res) => {
  const id = Number(req.params.id);
  if (!Number.isFinite(id) || id <= 0) {
    return res.status(400).json({ error: "invalid_id" });
  }

  const schema = z.object({
    name: z.string().min(1).optional(),
    lines: z.array(budgetLineSchema).optional()
  });
  const parsed = schema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  }

  try {
    const result = await updatePresupuesto(id, parsed.data);
    if (!result.success) return res.status(400).json(result);
    return res.json(result);
  } catch (err: any) {
    return res.status(500).json({ error: String(err) });
  }
});

advancedRouter.delete("/presupuestos/:id", async (req, res) => {
  const id = Number(req.params.id);
  if (!Number.isFinite(id) || id <= 0) {
    return res.status(400).json({ error: "invalid_id" });
  }

  try {
    const result = await deletePresupuesto(id);
    if (!result.success) return res.status(400).json(result);
    return res.json(result);
  } catch (err: any) {
    return res.status(500).json({ error: String(err) });
  }
});

advancedRouter.get("/presupuestos/:id/varianza", async (req, res) => {
  const id = Number(req.params.id);
  if (!Number.isFinite(id) || id <= 0) {
    return res.status(400).json({ error: "invalid_id" });
  }

  const parsed = rangoSchema.safeParse(req.query);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_query", issues: parsed.error.flatten() });
  }

  try {
    const data = await getVarianza({
      budgetId: id,
      fechaDesde: parsed.data.fechaDesde,
      fechaHasta: parsed.data.fechaHasta
    });
    return res.json(data);
  } catch (err: any) {
    return res.status(500).json({ error: String(err) });
  }
});

// ─── Conciliacion Bancaria ──────────────────────────────────────────────────
// ELIMINADO: Rutas de conciliacion bancaria delegadas a /v1/bancos/conciliaciones
// Ver: web/api/src/modules/bancos/conciliacion.service.ts

// ─── Asientos Recurrentes ───────────────────────────────────────────────────

const recurringLineSchema = z.object({
  accountCode: z.string().min(1),
  description: z.string().optional(),
  costCenterCode: z.string().optional(),
  debit: z.number().min(0),
  credit: z.number().min(0)
});

advancedRouter.get("/recurrentes/due", async (_req, res) => {
  try {
    const data = await getDueRecurrentes();
    return res.json(data);
  } catch (err: any) {
    return res.status(500).json({ error: String(err) });
  }
});

advancedRouter.get("/recurrentes", async (req, res) => {
  const schema = paginationSchema.extend({
    isActive: z.string().optional()
  });
  const parsed = schema.safeParse(req.query);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_query", issues: parsed.error.flatten() });
  }

  try {
    let isActive: boolean | undefined;
    if (parsed.data.isActive === "true") isActive = true;
    else if (parsed.data.isActive === "false") isActive = false;

    const data = await listRecurrentes({
      isActive,
      page: parsed.data.page ? Number(parsed.data.page) : 1,
      limit: parsed.data.limit ? Number(parsed.data.limit) : 50
    });
    return res.json(data);
  } catch (err: any) {
    return res.status(500).json({ error: String(err) });
  }
});

advancedRouter.get("/recurrentes/:id", async (req, res) => {
  const id = Number(req.params.id);
  if (!Number.isFinite(id) || id <= 0) {
    return res.status(400).json({ error: "invalid_id" });
  }

  try {
    const data = await getRecurrente(id);
    if (!data.cabecera) return res.status(404).json({ error: "not_found" });
    return res.json(data);
  } catch (err: any) {
    return res.status(500).json({ error: String(err) });
  }
});

advancedRouter.post("/recurrentes", async (req, res) => {
  const schema = z.object({
    templateName: z.string().min(1),
    frequency: z.string().min(1),
    nextExecutionDate: z.string().min(1),
    tipoAsiento: z.string().min(1),
    concepto: z.string().min(1),
    lines: z.array(recurringLineSchema).min(1)
  });
  const parsed = schema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  }

  try {
    const result = await insertRecurrente(parsed.data);
    if (!result.success) return res.status(400).json(result);
    return res.status(201).json(result);
  } catch (err: any) {
    return res.status(500).json({ error: String(err) });
  }
});

advancedRouter.put("/recurrentes/:id", async (req, res) => {
  const id = Number(req.params.id);
  if (!Number.isFinite(id) || id <= 0) {
    return res.status(400).json({ error: "invalid_id" });
  }

  const schema = z.object({
    templateName: z.string().min(1).optional(),
    frequency: z.string().min(1).optional(),
    nextExecutionDate: z.string().min(1).optional(),
    tipoAsiento: z.string().min(1).optional(),
    concepto: z.string().min(1).optional(),
    isActive: z.boolean().optional(),
    lines: z.array(recurringLineSchema).optional()
  });
  const parsed = schema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  }

  try {
    const result = await updateRecurrente(id, parsed.data);
    if (!result.success) return res.status(400).json(result);
    return res.json(result);
  } catch (err: any) {
    return res.status(500).json({ error: String(err) });
  }
});

advancedRouter.delete("/recurrentes/:id", async (req, res) => {
  const id = Number(req.params.id);
  if (!Number.isFinite(id) || id <= 0) {
    return res.status(400).json({ error: "invalid_id" });
  }

  try {
    const result = await deleteRecurrente(id);
    if (!result.success) return res.status(400).json(result);
    return res.json(result);
  } catch (err: any) {
    return res.status(500).json({ error: String(err) });
  }
});

advancedRouter.post("/recurrentes/:id/ejecutar", async (req, res) => {
  const id = Number(req.params.id);
  if (!Number.isFinite(id) || id <= 0) {
    return res.status(400).json({ error: "invalid_id" });
  }

  const schema = z.object({
    executionDate: z.string().min(1)
  });
  const parsed = schema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  }

  try {
    const user = (req as any).user?.username || "API";
    const result = await executeRecurrente(id, parsed.data.executionDate, user);
    if (!result.success) return res.status(400).json(result);
    return res.status(201).json(result);
  } catch (err: any) {
    return res.status(500).json({ error: String(err) });
  }
});

// ─── Reversion de Asientos ──────────────────────────────────────────────────

advancedRouter.post("/asientos/:id/revertir", async (req, res) => {
  const id = Number(req.params.id);
  if (!Number.isFinite(id) || id <= 0) {
    return res.status(400).json({ error: "invalid_id" });
  }

  const schema = z.object({
    motivo: z.string().min(1)
  });
  const parsed = schema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  }

  try {
    const user = (req as any).user?.username || "API";
    const result = await anularAsiento(id, parsed.data.motivo, user);
    if (!result.ok) return res.status(400).json(result);
    return res.json(result);
  } catch (err: any) {
    return res.status(500).json({ error: String(err) });
  }
});

// ─── Reportes Avanzados ─────────────────────────────────────────────────────

advancedRouter.get("/reportes/flujo-efectivo", async (req, res) => {
  const parsed = rangoSchema.safeParse(req.query);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_query", issues: parsed.error.flatten() });
  }

  try {
    const data = await cashFlowStatement(parsed.data);
    return res.json(data);
  } catch (err: any) {
    return res.status(500).json({ error: String(err) });
  }
});

advancedRouter.get("/reportes/balance-comp-multiperiodo", async (req, res) => {
  const schema = z.object({
    periodos: z.string().min(1)
  });
  const parsed = schema.safeParse(req.query);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_query", issues: parsed.error.flatten() });
  }

  try {
    const data = await balanceCompMultiPeriod({ periodos: parsed.data.periodos });
    return res.json(data);
  } catch (err: any) {
    return res.status(500).json({ error: String(err) });
  }
});

advancedRouter.get("/reportes/pnl-multiperiodo", async (req, res) => {
  const schema = z.object({
    periodos: z.string().min(1)
  });
  const parsed = schema.safeParse(req.query);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_query", issues: parsed.error.flatten() });
  }

  try {
    const data = await pnlMultiPeriod({ periodos: parsed.data.periodos });
    return res.json(data);
  } catch (err: any) {
    return res.status(500).json({ error: String(err) });
  }
});

advancedRouter.get("/reportes/aging-cxc", async (req, res) => {
  const parsed = fechaCorteSchema.safeParse(req.query);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_query", issues: parsed.error.flatten() });
  }

  try {
    const data = await agingCxC(parsed.data);
    return res.json(data);
  } catch (err: any) {
    return res.status(500).json({ error: String(err) });
  }
});

advancedRouter.get("/reportes/aging-cxp", async (req, res) => {
  const parsed = fechaCorteSchema.safeParse(req.query);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_query", issues: parsed.error.flatten() });
  }

  try {
    const data = await agingCxP(parsed.data);
    return res.json(data);
  } catch (err: any) {
    return res.status(500).json({ error: String(err) });
  }
});

advancedRouter.get("/reportes/ratios-financieros", async (req, res) => {
  const parsed = fechaCorteSchema.safeParse(req.query);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_query", issues: parsed.error.flatten() });
  }

  try {
    const data = await financialRatios(parsed.data);
    if (!data) return res.status(404).json({ error: "no_data" });
    return res.json(data);
  } catch (err: any) {
    return res.status(500).json({ error: String(err) });
  }
});

advancedRouter.get("/reportes/impuestos", async (req, res) => {
  const parsed = rangoSchema.safeParse(req.query);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_query", issues: parsed.error.flatten() });
  }

  try {
    const data = await taxSummary(parsed.data);
    return res.json(data);
  } catch (err: any) {
    return res.status(500).json({ error: String(err) });
  }
});

advancedRouter.get("/reportes/drill-down", async (req, res) => {
  const schema = rangoSchema.extend({
    accountCode: z.string().min(1),
    page: z.string().optional(),
    limit: z.string().optional()
  });
  const parsed = schema.safeParse(req.query);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_query", issues: parsed.error.flatten() });
  }

  try {
    const data = await drillDown({
      accountCode: parsed.data.accountCode,
      fechaDesde: parsed.data.fechaDesde,
      fechaHasta: parsed.data.fechaHasta,
      page: parsed.data.page ? Number(parsed.data.page) : 1,
      limit: parsed.data.limit ? Number(parsed.data.limit) : 50
    });
    return res.json(data);
  } catch (err: any) {
    return res.status(500).json({ error: String(err) });
  }
});

// ─── P&L por Centro de Costo ──────────────────────────────────────────────
advancedRouter.get("/reportes/pnl-centro-costo", async (req, res) => {
  const parsed = rangoSchema.safeParse(req.query);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_query", issues: parsed.error.flatten() });
  }
  try {
    const data = await pnlByCostCenter({
      fechaDesde: parsed.data.fechaDesde,
      fechaHasta: parsed.data.fechaHasta
    });
    return res.json(data);
  } catch (err: any) {
    return res.status(500).json({ error: String(err) });
  }
});
