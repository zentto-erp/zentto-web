/**
 * catalog/admin.routes.ts — Backoffice CRUD de planes + Paddle sync.
 * Montado en /v1/backoffice/catalog con requireMasterKey.
 */
import { Router } from "express";
import { requireMasterKey } from "../../middleware/master-key.js";
import { upsertPlan, listPendingSync, syncPlanToPaddle, syncAllPendingToPaddle } from "./admin.service.js";
import { listPlans, getPlanBySlug } from "./service.js";

export const catalogAdminRouter = Router();
catalogAdminRouter.use(requireMasterKey);

// GET /v1/backoffice/catalog/plans — lista completa (incluye inactivos)
catalogAdminRouter.get("/plans", async (req, res) => {
  try {
    const vertical = (req.query.vertical as string) || null;
    const plans = await listPlans({ vertical, includeTrial: true });
    res.json({ ok: true, plans });
  } catch (err: any) {
    res.status(500).json({ ok: false, error: err.message });
  }
});

// GET /v1/backoffice/catalog/plans/:slug
catalogAdminRouter.get("/plans/:slug", async (req, res) => {
  try {
    const plan = await getPlanBySlug(req.params.slug);
    if (!plan) {
      res.status(404).json({ ok: false, error: "plan_not_found" });
      return;
    }
    res.json({ ok: true, plan });
  } catch (err: any) {
    res.status(500).json({ ok: false, error: err.message });
  }
});

// POST /v1/backoffice/catalog/plans — crea o actualiza (upsert por slug)
catalogAdminRouter.post("/plans", async (req, res) => {
  try {
    const b = req.body ?? {};
    if (!b.slug || !b.name || !b.productCode) {
      res.status(400).json({ ok: false, error: "slug_name_productCode_required" });
      return;
    }
    const result = await upsertPlan({
      slug: String(b.slug).toLowerCase(),
      name: String(b.name),
      verticalType: String(b.verticalType || "none"),
      productCode: String(b.productCode),
      description: String(b.description || ""),
      monthlyPrice: Number(b.monthlyPrice || 0),
      annualPrice: Number(b.annualPrice || 0),
      billingCycleDefault: b.billingCycleDefault || "monthly",
      maxUsers: Number(b.maxUsers || 0),
      maxTransactions: Number(b.maxTransactions || 0),
      features: Array.isArray(b.features) ? b.features : [],
      moduleCodes: Array.isArray(b.moduleCodes) ? b.moduleCodes : [],
      limits: typeof b.limits === "object" && b.limits !== null ? b.limits : {},
      isAddon: Boolean(b.isAddon),
      isTrialOnly: Boolean(b.isTrialOnly),
      trialDays: Number(b.trialDays || 0),
      sortOrder: Number(b.sortOrder || 100),
      isActive: b.isActive !== false,
    });
    res.json({ ok: result?.ok ?? false, ...result });
  } catch (err: any) {
    res.status(500).json({ ok: false, error: err.message });
  }
});

// PATCH /v1/backoffice/catalog/plans/:planId/toggle
catalogAdminRouter.patch("/plans/:planId/toggle", async (req, res) => {
  try {
    const planId = Number(req.params.planId);
    if (!planId) {
      res.status(400).json({ ok: false, error: "planId_inválido" });
      return;
    }
    const isActive = req.body?.isActive !== false;
    const existing = await listPlans({ includeTrial: true });
    const plan = existing.find((p) => p.PricingPlanId === planId);
    if (!plan) {
      res.status(404).json({ ok: false, error: "plan_not_found" });
      return;
    }
    await upsertPlan({
      slug: plan.Slug,
      name: plan.Name,
      verticalType: plan.VerticalType,
      productCode: plan.ProductCode,
      description: plan.Description,
      monthlyPrice: plan.MonthlyPrice,
      annualPrice: plan.AnnualPrice,
      billingCycleDefault: plan.BillingCycleDefault,
      maxUsers: plan.MaxUsers,
      maxTransactions: plan.MaxTransactions,
      features: plan.Features,
      moduleCodes: plan.ModuleCodes,
      limits: plan.Limits as any,
      isAddon: plan.IsAddon,
      isTrialOnly: plan.IsTrialOnly,
      trialDays: plan.TrialDays,
      sortOrder: plan.SortOrder,
      isActive,
    });
    res.json({ ok: true, mensaje: isActive ? "activado" : "desactivado" });
  } catch (err: any) {
    res.status(500).json({ ok: false, error: err.message });
  }
});

// GET /v1/backoffice/catalog/paddle/pending — planes pendientes de sync
catalogAdminRouter.get("/paddle/pending", async (_req, res) => {
  try {
    const pending = await listPendingSync();
    res.json({ ok: true, pending });
  } catch (err: any) {
    res.status(500).json({ ok: false, error: err.message });
  }
});

// POST /v1/backoffice/catalog/paddle/sync/:planId — sync de un plan
catalogAdminRouter.post("/paddle/sync/:planId", async (req, res) => {
  try {
    const planId = Number(req.params.planId);
    if (!planId) {
      res.status(400).json({ ok: false, error: "planId_inválido" });
      return;
    }
    const result = await syncPlanToPaddle(planId);
    res.json(result);
  } catch (err: any) {
    res.status(500).json({ ok: false, error: err.message });
  }
});

// POST /v1/backoffice/catalog/paddle/sync-all — sync de todos los pending
catalogAdminRouter.post("/paddle/sync-all", async (_req, res) => {
  try {
    const result = await syncAllPendingToPaddle();
    res.json({ ok: true, ...result });
  } catch (err: any) {
    res.status(500).json({ ok: false, error: err.message });
  }
});
