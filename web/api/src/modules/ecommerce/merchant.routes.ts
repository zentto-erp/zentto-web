/**
 * merchant.routes.ts — Endpoints REST del marketplace de comerciantes (merchants).
 *
 * NOTA: el recurso técnico es "merchant" (para evitar colisión con master.Seller
 * del ERP). La UI pública en español sigue diciendo "vendedor" y usa `/vender`.
 *
 * Authenticated cliente:
 *   POST   /store/merchant/apply              → aplica al marketplace
 *   GET    /store/merchant/dashboard          → métricas del merchant
 *   GET    /store/merchant/products           → lista productos propios
 *   POST   /store/merchant/products           → crear / enviar a revisión
 *
 * Admin:
 *   GET    /store/admin/merchants
 *   POST   /store/admin/merchants/:id/approve
 *   POST   /store/admin/merchants/:id/reject
 *   POST   /store/admin/merchants/:id/suspend
 *   GET    /store/admin/merchant-products/pending
 *   POST   /store/admin/merchant-products/:id/review
 *   POST   /store/admin/merchants/payouts/generate
 */

import { Router } from "express";
import { z } from "zod";
import { requireJwt, type AuthenticatedRequest } from "../../middleware/auth.js";
import { verifyCustomerToken } from "./service.js";
import {
  applyMerchant,
  getMerchantDashboard,
  submitMerchantProduct,
  listMerchantProducts,
  adminListMerchants,
  adminSetMerchantStatus,
  adminListPendingProducts,
  adminReviewProduct,
  adminGenerateMerchantPayouts,
} from "./merchant.service.js";

export const merchantRouter = Router();

// ─── Authenticated cliente ─────────────────────────────

const applySchema = z.object({
  legalName: z.string().min(2).max(200),
  taxId: z.string().max(40).optional(),
  storeSlug: z.string().max(80).optional(),
  description: z.string().max(5000).optional(),
  logoUrl: z.string().url().max(500).optional(),
  contactEmail: z.string().email().max(200).optional(),
  contactPhone: z.string().max(40).optional(),
  payoutMethod: z.string().max(30).optional(),
  payoutDetails: z.record(z.unknown()).optional(),
});

merchantRouter.post("/merchant/apply", async (req, res) => {
  try {
    const user = await verifyCustomerToken(req.headers.authorization);
    if (!user) return res.status(401).json({ error: "not_authenticated" });
    const customerId = Number(user.sub);
    if (!Number.isFinite(customerId)) return res.status(400).json({ error: "invalid_customer" });

    const parsed = applySchema.safeParse(req.body);
    if (!parsed.success) return res.status(400).json({ error: "invalid_body", details: parsed.error.flatten() });

    const result = await applyMerchant({
      customerId,
      legalName: parsed.data.legalName,
      taxId: parsed.data.taxId,
      storeSlug: parsed.data.storeSlug,
      description: parsed.data.description,
      logoUrl: parsed.data.logoUrl,
      contactEmail: parsed.data.contactEmail ?? (user as any).email,
      contactPhone: parsed.data.contactPhone,
      payoutMethod: parsed.data.payoutMethod,
      payoutDetails: parsed.data.payoutDetails as Record<string, unknown> | undefined,
    });
    if (!result.ok) return res.status(400).json(result);
    res.json(result);
  } catch (err: any) {
    res.status(500).json({ error: "server_error", message: err.message });
  }
});

merchantRouter.get("/merchant/dashboard", async (req, res) => {
  try {
    const user = await verifyCustomerToken(req.headers.authorization);
    if (!user) return res.status(401).json({ error: "not_authenticated" });
    const customerId = Number(user.sub);
    if (!Number.isFinite(customerId)) return res.status(400).json({ error: "invalid_customer" });

    const data = await getMerchantDashboard(customerId);
    if (!data) return res.status(404).json({ error: "not_a_merchant" });
    res.json(data);
  } catch (err: any) {
    res.status(500).json({ error: "server_error", message: err.message });
  }
});

const submitProductSchema = z.object({
  productId: z.number().int().optional(),
  code: z.string().max(64).optional(),
  name: z.string().min(2).max(250),
  description: z.string().max(5000).optional(),
  price: z.number().nonnegative(),
  stock: z.number().nonnegative(),
  category: z.string().max(80).optional(),
  imageUrl: z.string().url().max(500).optional(),
  submit: z.boolean().optional(),
});

merchantRouter.post("/merchant/products", async (req, res) => {
  try {
    const user = await verifyCustomerToken(req.headers.authorization);
    if (!user) return res.status(401).json({ error: "not_authenticated" });
    const customerId = Number(user.sub);
    if (!Number.isFinite(customerId)) return res.status(400).json({ error: "invalid_customer" });

    const parsed = submitProductSchema.safeParse(req.body);
    if (!parsed.success) return res.status(400).json({ error: "invalid_body", details: parsed.error.flatten() });

    const result = await submitMerchantProduct({
      customerId,
      productId: parsed.data.productId,
      code: parsed.data.code,
      name: parsed.data.name,
      description: parsed.data.description,
      price: parsed.data.price,
      stock: parsed.data.stock,
      category: parsed.data.category,
      imageUrl: parsed.data.imageUrl,
      submit: parsed.data.submit ?? false,
    });
    if (!result.ok) return res.status(400).json(result);
    res.json(result);
  } catch (err: any) {
    res.status(500).json({ error: "server_error", message: err.message });
  }
});

merchantRouter.get("/merchant/products", async (req, res) => {
  try {
    const user = await verifyCustomerToken(req.headers.authorization);
    if (!user) return res.status(401).json({ error: "not_authenticated" });
    const customerId = Number(user.sub);
    if (!Number.isFinite(customerId)) return res.status(400).json({ error: "invalid_customer" });

    const status = (req.query.status as string | undefined) || undefined;
    const page = req.query.page ? Number(req.query.page) : 1;
    const limit = req.query.limit ? Number(req.query.limit) : 20;

    const data = await listMerchantProducts({ customerId, status, page, limit });
    res.json(data);
  } catch (err: any) {
    res.status(500).json({ error: "server_error", message: err.message });
  }
});

// ─── Admin ─────────────────────────────────────────────

merchantRouter.get("/admin/merchants", requireJwt, async (req, res) => {
  try {
    const user = (req as AuthenticatedRequest).user;
    if (!user?.isAdmin) return res.status(403).json({ error: "forbidden" });
    const status = (req.query.status as string | undefined) || undefined;
    const page = req.query.page ? Number(req.query.page) : 1;
    const limit = req.query.limit ? Number(req.query.limit) : 20;
    const data = await adminListMerchants({ status, page, limit });
    res.json(data);
  } catch (err: any) {
    res.status(500).json({ error: "server_error", message: err.message });
  }
});

const adminMerchantStatusSchema = z.object({
  reason: z.string().max(500).optional(),
});

function makeMerchantStatusHandler(status: "approved" | "rejected" | "suspended") {
  return async (req: any, res: any) => {
    try {
      const user = (req as AuthenticatedRequest).user;
      if (!user?.isAdmin) return res.status(403).json({ error: "forbidden" });
      const parsed = adminMerchantStatusSchema.safeParse(req.body ?? {});
      if (!parsed.success) return res.status(400).json({ error: "invalid_body" });
      const merchantId = Number(req.params.id);
      const result = await adminSetMerchantStatus({
        merchantId,
        status,
        actor: user.name || String(user.sub),
        reason: parsed.data.reason ?? null,
      });
      if (!result.ok) return res.status(400).json(result);
      res.json(result);
    } catch (err: any) {
      res.status(500).json({ error: "server_error", message: err.message });
    }
  };
}

merchantRouter.post("/admin/merchants/:id/approve", requireJwt, makeMerchantStatusHandler("approved"));
merchantRouter.post("/admin/merchants/:id/reject",  requireJwt, makeMerchantStatusHandler("rejected"));
merchantRouter.post("/admin/merchants/:id/suspend", requireJwt, makeMerchantStatusHandler("suspended"));

merchantRouter.get("/admin/merchant-products/pending", requireJwt, async (req, res) => {
  try {
    const user = (req as AuthenticatedRequest).user;
    if (!user?.isAdmin) return res.status(403).json({ error: "forbidden" });
    const status = (req.query.status as string | undefined) || "pending_review";
    const page = req.query.page ? Number(req.query.page) : 1;
    const limit = req.query.limit ? Number(req.query.limit) : 20;
    const data = await adminListPendingProducts({ status, page, limit });
    res.json(data);
  } catch (err: any) {
    res.status(500).json({ error: "server_error", message: err.message });
  }
});

const reviewProductSchema = z.object({
  status: z.enum(["approved", "rejected"]),
  notes: z.string().max(2000).optional(),
});

merchantRouter.post("/admin/merchant-products/:id/review", requireJwt, async (req, res) => {
  try {
    const user = (req as AuthenticatedRequest).user;
    if (!user?.isAdmin) return res.status(403).json({ error: "forbidden" });
    const parsed = reviewProductSchema.safeParse(req.body);
    if (!parsed.success) return res.status(400).json({ error: "invalid_body" });
    const productId = Number(req.params.id);
    const result = await adminReviewProduct({
      productId,
      status: parsed.data.status,
      notes: parsed.data.notes,
      actor: user.name || String(user.sub),
    });
    if (!result.ok) return res.status(400).json(result);
    res.json(result);
  } catch (err: any) {
    res.status(500).json({ error: "server_error", message: err.message });
  }
});

// ─── Admin — generar payouts mensuales de merchants ────────
const generateMerchantPayoutsSchema = z.object({
  periodStart: z.string().optional(),
  periodEnd: z.string().optional(),
});

merchantRouter.post("/admin/merchants/payouts/generate", requireJwt, async (req, res) => {
  try {
    const user = (req as AuthenticatedRequest).user;
    if (!user?.isAdmin) return res.status(403).json({ error: "forbidden" });
    const parsed = generateMerchantPayoutsSchema.safeParse(req.body ?? {});
    if (!parsed.success) return res.status(400).json({ error: "invalid_body" });
    const result = await adminGenerateMerchantPayouts({
      periodStart: parsed.data.periodStart ?? null,
      periodEnd: parsed.data.periodEnd ?? null,
    });
    res.json(result);
  } catch (err: any) {
    res.status(500).json({ error: "server_error", message: err.message });
  }
});
