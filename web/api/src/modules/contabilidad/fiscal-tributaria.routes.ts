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
});

fiscalTributariaRouter.get("/libros/resumen", async (req, res) => {
  const bookType = req.query.bookType as string;
  const periodCode = req.query.periodCode as string;
  const countryCode = req.query.countryCode as string;
  if (!bookType || !periodCode || !countryCode) {
    return res.status(400).json({ error: "bookType, periodCode, countryCode required" });
  }
  const rows = await taxBookSummary(bookType, periodCode, countryCode);
  return res.json({ rows });
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
