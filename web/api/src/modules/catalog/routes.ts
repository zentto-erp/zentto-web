import { Router } from "express";
import { listPlans, getPlanBySlug, listProducts, checkSubdomain } from "./service.js";

export const catalogRouter = Router();

// GET /v1/catalog/plans?vertical=erp&product=erp-core&includeTrial=true
catalogRouter.get("/plans", async (req, res) => {
  try {
    const vertical = (req.query.vertical as string) || null;
    const product = (req.query.product as string) || null;
    const includeTrial = req.query.includeTrial !== "false";
    const plans = await listPlans({ vertical, product, includeTrial });
    res.json({ ok: true, plans });
  } catch (err: any) {
    res.status(500).json({ ok: false, error: err.message });
  }
});

// GET /v1/catalog/plans/:slug
catalogRouter.get("/plans/:slug", async (req, res) => {
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

// GET /v1/catalog/products?vertical=hotel
catalogRouter.get("/products", async (req, res) => {
  try {
    const vertical = (req.query.vertical as string) || undefined;
    const products = await listProducts(vertical);
    res.json({ ok: true, products });
  } catch (err: any) {
    res.status(500).json({ ok: false, error: err.message });
  }
});

// GET /v1/catalog/subdomain-check/:slug
catalogRouter.get("/subdomain-check/:slug", async (req, res) => {
  try {
    const result = await checkSubdomain(req.params.slug);
    res.json({ ok: true, ...result });
  } catch (err: any) {
    res.status(500).json({ ok: false, error: err.message });
  }
});
