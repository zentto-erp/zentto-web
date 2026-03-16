import { Router } from "express";
import { z } from "zod";
import {
  listCategories,
  getCategory,
  upsertCategory,
  listAssets,
  getAsset,
  insertAsset,
  updateAsset,
  disposeAsset,
  calculateDepreciation,
  depreciationHistory,
  addImprovement,
  revalueAsset,
  reportAssetBook,
  reportDepreciationSchedule,
  reportByCategory,
} from "./activos-fijos.service.js";

export const activosFijosRouter = Router();

// ─── Schemas ─────────────────────────────────────────────────────────

const categorySchema = z.object({
  categoryCode: z.string().min(1).max(20),
  categoryName: z.string().min(1).max(200),
  defaultUsefulLifeMonths: z.number().int().min(0),
  defaultDepreciationMethod: z.string().optional(),
  defaultResidualPercent: z.number().optional(),
  defaultAssetAccountCode: z.string().optional(),
  defaultDeprecAccountCode: z.string().optional(),
  defaultExpenseAccountCode: z.string().optional(),
  countryCode: z.string().max(2).optional(),
});

const assetSchema = z.object({
  assetCode: z.string().min(1).max(40),
  description: z.string().min(1).max(250),
  categoryId: z.number().int(),
  acquisitionDate: z.string(),
  acquisitionCost: z.number().positive(),
  residualValue: z.number().optional(),
  usefulLifeMonths: z.number().int().min(0),
  depreciationMethod: z.string().optional(),
  assetAccountCode: z.string().min(1),
  deprecAccountCode: z.string().min(1),
  expenseAccountCode: z.string().min(1),
  costCenterCode: z.string().optional(),
  location: z.string().optional(),
  serialNumber: z.string().optional(),
  unitsCapacity: z.number().int().optional(),
  currencyCode: z.string().optional(),
});

const assetUpdateSchema = z.object({
  description: z.string().optional(),
  location: z.string().optional(),
  serialNumber: z.string().optional(),
  costCenterCode: z.string().optional(),
  currencyCode: z.string().optional(),
});

const disposeSchema = z.object({
  disposalDate: z.string(),
  disposalAmount: z.number().optional(),
  disposalReason: z.string().optional(),
});

const depreciacionSchema = z.object({
  periodo: z.string().regex(/^\d{4}-\d{2}$/),
  costCenterCode: z.string().optional(),
});

const improvementSchema = z.object({
  improvementDate: z.string(),
  description: z.string().min(1),
  amount: z.number().positive(),
  additionalLifeMonths: z.number().int().optional(),
});

const revalueSchema = z.object({
  revaluationDate: z.string(),
  indexFactor: z.number().positive(),
  countryCode: z.string().length(2),
});

// ─── Categories ──────────────────────────────────────────────────────

activosFijosRouter.get("/categorias", async (req, res) => {
  const search = req.query.search as string | undefined;
  const page = Number(req.query.page) || 1;
  const limit = Number(req.query.limit) || 50;
  const data = await listCategories(search, page, limit);
  return res.json(data);
});

activosFijosRouter.get("/categorias/:code", async (req, res) => {
  const row = await getCategory(req.params.code);
  if (!row) return res.status(404).json({ error: "category_not_found" });
  return res.json(row);
});

activosFijosRouter.post("/categorias", async (req, res) => {
  const parsed = categorySchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  const result = await upsertCategory(parsed.data);
  if (!result.ok) return res.status(400).json(result);
  return res.status(201).json(result);
});

// ─── Assets CRUD ─────────────────────────────────────────────────────

activosFijosRouter.get("/", async (req, res) => {
  const filter = {
    categoryCode: req.query.categoryCode as string | undefined,
    status: req.query.status as string | undefined,
    costCenterCode: req.query.costCenterCode as string | undefined,
    search: req.query.search as string | undefined,
    page: Number(req.query.page) || 1,
    limit: Number(req.query.limit) || 50,
  };
  const data = await listAssets(filter);
  return res.json(data);
});

activosFijosRouter.get("/reportes/libro", async (req, res) => {
  const fechaCorte = req.query.fechaCorte as string;
  if (!fechaCorte) return res.status(400).json({ error: "fechaCorte required" });
  const rows = await reportAssetBook(fechaCorte, req.query.categoryCode as string);
  return res.json({ rows });
});

activosFijosRouter.get("/reportes/por-categoria", async (req, res) => {
  const fechaCorte = req.query.fechaCorte as string;
  if (!fechaCorte) return res.status(400).json({ error: "fechaCorte required" });
  const rows = await reportByCategory(fechaCorte);
  return res.json({ rows });
});

activosFijosRouter.get("/reportes/cuadro/:id", async (req, res) => {
  const assetId = Number(req.params.id);
  if (!assetId) return res.status(400).json({ error: "invalid asset id" });
  const rows = await reportDepreciationSchedule(assetId);
  return res.json({ rows });
});

activosFijosRouter.get("/:id", async (req, res) => {
  const assetId = Number(req.params.id);
  if (!assetId) return res.status(400).json({ error: "invalid asset id" });
  const row = await getAsset(assetId);
  if (!row) return res.status(404).json({ error: "asset_not_found" });
  return res.json(row);
});

activosFijosRouter.post("/", async (req, res) => {
  const parsed = assetSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  const user = (req as any).user?.username || "API";
  const result = await insertAsset(parsed.data, user);
  if (!result.ok) return res.status(400).json(result);
  return res.status(201).json(result);
});

activosFijosRouter.put("/:id", async (req, res) => {
  const assetId = Number(req.params.id);
  if (!assetId) return res.status(400).json({ error: "invalid asset id" });
  const parsed = assetUpdateSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  const user = (req as any).user?.username || "API";
  const result = await updateAsset(assetId, parsed.data, user);
  if (!result.ok) return res.status(400).json(result);
  return res.json(result);
});

activosFijosRouter.post("/:id/disponer", async (req, res) => {
  const assetId = Number(req.params.id);
  if (!assetId) return res.status(400).json({ error: "invalid asset id" });
  const parsed = disposeSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  const user = (req as any).user?.username || "API";
  const result = await disposeAsset(assetId, parsed.data, user);
  if (!result.ok) return res.status(400).json(result);
  return res.json(result);
});

// ─── Depreciation ────────────────────────────────────────────────────

activosFijosRouter.post("/depreciacion/calcular", async (req, res) => {
  const parsed = depreciacionSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  const user = (req as any).user?.username || "API";
  const result = await calculateDepreciation(parsed.data.periodo, false, parsed.data.costCenterCode, user);
  if (!result.ok) return res.status(400).json(result);
  return res.status(201).json(result);
});

activosFijosRouter.post("/depreciacion/preview", async (req, res) => {
  const parsed = depreciacionSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  const user = (req as any).user?.username || "API";
  const result = await calculateDepreciation(parsed.data.periodo, true, parsed.data.costCenterCode, user);
  return res.json(result);
});

activosFijosRouter.get("/:id/depreciaciones", async (req, res) => {
  const assetId = Number(req.params.id);
  if (!assetId) return res.status(400).json({ error: "invalid asset id" });
  const page = Number(req.query.page) || 1;
  const limit = Number(req.query.limit) || 50;
  const data = await depreciationHistory(assetId, page, limit);
  return res.json(data);
});

// ─── Improvements ────────────────────────────────────────────────────

activosFijosRouter.post("/:id/mejoras", async (req, res) => {
  const assetId = Number(req.params.id);
  if (!assetId) return res.status(400).json({ error: "invalid asset id" });
  const parsed = improvementSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  const user = (req as any).user?.username || "API";
  const result = await addImprovement(assetId, parsed.data, user);
  if (!result.ok) return res.status(400).json(result);
  return res.status(201).json(result);
});

// ─── Revaluation ─────────────────────────────────────────────────────

activosFijosRouter.post("/:id/revaluar", async (req, res) => {
  const assetId = Number(req.params.id);
  if (!assetId) return res.status(400).json({ error: "invalid asset id" });
  const parsed = revalueSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  const user = (req as any).user?.username || "API";
  const result = await revalueAsset(assetId, parsed.data, user);
  if (!result.ok) return res.status(400).json(result);
  return res.status(201).json(result);
});
