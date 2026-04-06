import { Router } from "express";
import { listPricingPlans, getPricingPlan } from "./service.js";

export const pricingRouter = Router();

/**
 * GET /v1/pricing/plans?vertical=erp|medical|tickets|hotel|education
 * Publico — listar planes activos, opcionalmente filtrados por vertical.
 */
pricingRouter.get("/plans", async (req, res) => {
  try {
    const vertical = req.query.vertical as string | undefined;
    const plans = await listPricingPlans(vertical);
    res.json(plans);
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

/**
 * GET /v1/pricing/plans/:slug
 * Publico — detalle de un plan por slug.
 */
pricingRouter.get("/plans/:slug", async (req, res) => {
  try {
    const plan = await getPricingPlan(req.params.slug);
    if (!plan) {
      return res.status(404).json({ error: "Plan no encontrado" });
    }
    res.json(plan);
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});
