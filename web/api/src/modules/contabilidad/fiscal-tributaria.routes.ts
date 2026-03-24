import { Router } from "express";
import { z } from "zod";
import {
  populateTaxBook,
  listTaxBook,
  taxBookSummary,
  calculateDeclaration,
  listDeclarations,
  getDeclaration,
  submitDeclaration,
  amendDeclaration,
  generateWithholding,
  listWithholdings,
  getWithholding,
  exportTaxBook,
  exportDeclaration,
} from "./fiscal-tributaria.service.js";
import { callSp, callSpOut } from "../../db/query.js";
import { getActiveScope } from "../_shared/scope.js";

export const fiscalTributariaRouter = Router();

// ─── Schemas ─────────────────────────────────────────────────────────

const taxBookSchema = z.object({
  bookType: z.enum(["PURCHASE", "SALES"]),
  periodCode: z.string().regex(/^\d{4}-\d{2}$/),
  countryCode: z.string().length(2),
});

const calculateSchema = z.object({
  declarationType: z.string().min(1),
  periodCode: z.string().regex(/^\d{4}-\d{2}$/),
  countryCode: z.string().length(2),
});

const withholdingSchema = z.object({
  documentId: z.number().int().positive(),
  withholdingType: z.string().min(1),
  countryCode: z.string().length(2),
});

// ─── Tax Books ───────────────────────────────────────────────────────

fiscalTributariaRouter.post("/libros/generar", async (req, res) => {
  const parsed = taxBookSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  const user = (req as any).user?.username || "API";
  const result = await populateTaxBook(parsed.data.bookType, parsed.data.periodCode, parsed.data.countryCode, user);
  if (!result.ok) return res.status(400).json(result);
  return res.status(201).json(result);
});

fiscalTributariaRouter.get("/libros", async (req, res) => {
  try {
    const bookType = req.query.bookType as string;
    const periodCode = req.query.periodCode as string;
    const countryCode = req.query.countryCode as string;
    if (!bookType || !periodCode || !countryCode) {
      return res.status(400).json({ error: "bookType, periodCode, countryCode required" });
    }
    const page = Number(req.query.page) || 1;
    const limit = Number(req.query.limit) || 100;
    const data = await listTaxBook({ bookType, periodCode, countryCode, page, limit });
    return res.json(data);
  } catch (err: any) {
    return res.status(500).json({ error: String(err.message ?? err) });
  }
});

fiscalTributariaRouter.get("/libros/resumen", async (req, res) => {
  try {
    const bookType = req.query.bookType as string;
    const periodCode = req.query.periodCode as string;
    const countryCode = req.query.countryCode as string;
    if (!bookType || !periodCode || !countryCode) {
      return res.status(400).json({ error: "bookType, periodCode, countryCode required" });
    }
    const rows = await taxBookSummary(bookType, periodCode, countryCode);
    return res.json({ rows });
  } catch (err: any) {
    return res.status(500).json({ error: String(err.message ?? err) });
  }
});

fiscalTributariaRouter.get("/libros/exportar", async (req, res) => {
  const bookType = req.query.bookType as string;
  const periodCode = req.query.periodCode as string;
  const countryCode = req.query.countryCode as string;
  if (!bookType || !periodCode || !countryCode) {
    return res.status(400).json({ error: "bookType, periodCode, countryCode required" });
  }
  const rows = await exportTaxBook(bookType, periodCode, countryCode);
  return res.json({ rows });
});

// ─── Declarations ────────────────────────────────────────────────────

fiscalTributariaRouter.post("/declaraciones/calcular", async (req, res) => {
  const parsed = calculateSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  const user = (req as any).user?.username || "API";
  const result = await calculateDeclaration(parsed.data, user);
  if (!result.ok) return res.status(400).json(result);
  return res.status(201).json(result);
});

fiscalTributariaRouter.get("/declaraciones", async (req, res) => {
  const filter = {
    declarationType: req.query.declarationType as string | undefined,
    year: Number(req.query.year) || undefined,
    status: req.query.status as string | undefined,
    page: Number(req.query.page) || 1,
    limit: Number(req.query.limit) || 50,
  };
  const data = await listDeclarations(filter);
  return res.json(data);
});

fiscalTributariaRouter.get("/declaraciones/:id", async (req, res) => {
  const id = Number(req.params.id);
  if (!id) return res.status(400).json({ error: "invalid declaration id" });
  const row = await getDeclaration(id);
  if (!row) return res.status(404).json({ error: "declaration_not_found" });
  return res.json(row);
});

fiscalTributariaRouter.post("/declaraciones/:id/presentar", async (req, res) => {
  const id = Number(req.params.id);
  if (!id) return res.status(400).json({ error: "invalid declaration id" });
  const user = (req as any).user?.username || "API";
  const filePath = req.body?.filePath || null;
  const result = await submitDeclaration(id, filePath, user);
  if (!result.ok) return res.status(400).json(result);
  return res.json(result);
});

fiscalTributariaRouter.post("/declaraciones/:id/enmendar", async (req, res) => {
  const id = Number(req.params.id);
  if (!id) return res.status(400).json({ error: "invalid declaration id" });
  const user = (req as any).user?.username || "API";
  const result = await amendDeclaration(id, user);
  if (!result.ok) return res.status(400).json(result);
  return res.json(result);
});

fiscalTributariaRouter.get("/declaraciones/:id/exportar", async (req, res) => {
  const id = Number(req.params.id);
  if (!id) return res.status(400).json({ error: "invalid declaration id" });
  const rows = await exportDeclaration(id);
  return res.json({ rows });
});

// ─── Withholdings ────────────────────────────────────────────────────

fiscalTributariaRouter.post("/retenciones/generar", async (req, res) => {
  const parsed = withholdingSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  const user = (req as any).user?.username || "API";
  const result = await generateWithholding(parsed.data, user);
  if (!result.ok) return res.status(400).json(result);
  return res.status(201).json(result);
});

fiscalTributariaRouter.get("/retenciones", async (req, res) => {
  const filter = {
    withholdingType: req.query.withholdingType as string | undefined,
    periodCode: req.query.periodCode as string | undefined,
    countryCode: req.query.countryCode as string | undefined,
    page: Number(req.query.page) || 1,
    limit: Number(req.query.limit) || 50,
  };
  const data = await listWithholdings(filter);
  return res.json(data);
});

fiscalTributariaRouter.get("/retenciones/:id", async (req, res) => {
  const id = Number(req.params.id);
  if (!id) return res.status(400).json({ error: "invalid voucher id" });
  const row = await getWithholding(id);
  if (!row) return res.status(404).json({ error: "withholding_not_found" });
  return res.json(row);
});

// ============================================
// CONCEPTOS DE RETENCIÓN
// ============================================

fiscalTributariaRouter.get("/retenciones/conceptos", async (req, res) => {
  try {
    const scope = getActiveScope();
    const q = req.query;
    const rows = await callSp<any>("usp_Fiscal_WithholdingConcept_List", {
      CompanyId: scope?.companyId ?? 1,
      CountryCode: q.countryCode || null,
      RetentionType: q.retentionType || null,
      Search: q.search || null,
      Page: Number(q.page ?? 1),
      Limit: Number(q.limit ?? 50),
    });
    const total = Number(rows[0]?.p_total ?? rows.length);
    res.json({ rows, total });
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

fiscalTributariaRouter.post("/retenciones/conceptos", async (req, res) => {
  try {
    const scope = getActiveScope();
    const b = req.body;
    const { output } = await callSpOut("usp_Fiscal_WithholdingConcept_Upsert", {
      CompanyId: scope?.companyId ?? 1,
      CountryCode: b.countryCode || "VE",
      ConceptCode: b.conceptCode,
      Description: b.description,
      SupplierType: b.supplierType || "AMBOS",
      ActivityCode: b.activityCode || null,
      RetentionType: b.retentionType || "ISLR",
      Rate: Number(b.rate ?? 0),
      SubtrahendUT: Number(b.subtrahendUT ?? 0),
      MinBaseUT: Number(b.minBaseUT ?? 0),
      SeniatCode: b.seniatCode || null,
    }, { Resultado: "Int", Mensaje: "NVarChar" });
    res.json({ ok: Number(output.Resultado) === 1, mensaje: output.Mensaje });
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// ============================================
// UNIDAD TRIBUTARIA
// ============================================

fiscalTributariaRouter.get("/unidad-tributaria", async (req, res) => {
  try {
    const q = req.query;
    const rows = await callSp("usp_Cfg_TaxUnit_List", {
      CountryCode: q.countryCode || null,
      TaxYear: q.taxYear ? Number(q.taxYear) : null,
    });
    res.json({ rows });
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

fiscalTributariaRouter.put("/unidad-tributaria", async (req, res) => {
  try {
    const b = req.body;
    const { output } = await callSpOut("usp_Cfg_TaxUnit_Upsert", {
      CountryCode: b.countryCode || "VE",
      TaxYear: Number(b.taxYear),
      UnitValue: Number(b.unitValue),
      Currency: b.currency || "VES",
      EffectiveDate: b.effectiveDate || null,
    }, { Resultado: "Int", Mensaje: "NVarChar" });
    res.json({ ok: Number(output.Resultado) === 1, mensaje: output.Mensaje });
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});

// ============================================
// PREVIEW CÁLCULO DE RETENCIÓN
// ============================================

fiscalTributariaRouter.post("/retenciones/calcular", async (req, res) => {
  try {
    const scope = getActiveScope();
    const b = req.body;
    const rows = await callSp<any>("usp_Fiscal_Withholding_Calculate", {
      CompanyId: scope?.companyId ?? 1,
      SupplierCode: b.supplierCode,
      TaxableBase: Number(b.taxableBase ?? 0),
      WithholdingType: b.withholdingType || "ISLR",
      CountryCode: b.countryCode || "VE",
    });
    const result = rows[0] ?? {};
    res.json({
      rate: Number(result.Rate ?? 0),
      amount: Number(result.Amount ?? 0),
      conceptCode: result.ConceptCode ?? "",
      subtrahend: Number(result.Subtrahend ?? 0),
      description: result.Description ?? "",
    });
  } catch (err: any) {
    res.status(500).json({ error: String(err) });
  }
});
