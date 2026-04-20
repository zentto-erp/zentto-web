/**
 * seller.routes.ts — Endpoints REST del marketplace de vendedores.
 *
 * Authenticated cliente:
 *   POST   /store/seller/apply              → aplica al marketplace
 *   GET    /store/seller/dashboard          → métricas del vendedor
 *   GET    /store/seller/products           → lista productos propios
 *   POST   /store/seller/products           → crear / enviar a revisión
 *
 * Admin:
 *   GET    /store/admin/sellers
 *   POST   /store/admin/sellers/:id/approve
 *   POST   /store/admin/sellers/:id/reject
 *   POST   /store/admin/sellers/:id/suspend
 *   GET    /store/admin/seller-products/pending
 *   POST   /store/admin/seller-products/:id/review
 */

import { Router } from "express";
import { z } from "zod";
import { requireJwt, type AuthenticatedRequest } from "../../middleware/auth.js";
import { verifyCustomerToken } from "./service.js";
import {
  applySeller,
  getSellerDashboard,
  submitSellerProduct,
  listSellerProducts,
  adminListSellers,
  adminSetSellerStatus,
  adminListPendingProducts,
  adminReviewProduct,
} from "./seller.service.js";

export const sellerRouter = Router();

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

sellerRouter.post("/seller/apply", async (req, res) => {
  try {
    const user = await verifyCustomerToken(req.headers.authorization);
    if (!user) return res.status(401).json({ error: "not_authenticated" });
    const customerId = Number(user.sub);
    if (!Number.isFinite(customerId)) return res.status(400).json({ error: "invalid_customer" });

    const parsed = applySchema.safeParse(req.body);
    if (!parsed.success) return res.status(400).json({ error: "invalid_body", details: parsed.error.flatten() });

    const result = await applySeller({
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

sellerRouter.get("/seller/dashboard", async (req, res) => {
  try {
    const user = await verifyCustomerToken(req.headers.authorization);
    if (!user) return res.status(401).json({ error: "not_authenticated" });
    const customerId = Number(user.sub);
    if (!Number.isFinite(customerId)) return res.status(400).json({ error: "invalid_customer" });

    const data = await getSellerDashboard(customerId);
    if (!data) return res.status(404).json({ error: "not_a_seller" });
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

sellerRouter.post("/seller/products", async (req, res) => {
  try {
    const user = await verifyCustomerToken(req.headers.authorization);
    if (!user) return res.status(401).json({ error: "not_authenticated" });
    const customerId = Number(user.sub);
    if (!Number.isFinite(customerId)) return res.status(400).json({ error: "invalid_customer" });

    const parsed = submitProductSchema.safeParse(req.body);
    if (!parsed.success) return res.status(400).json({ error: "invalid_body", details: parsed.error.flatten() });

    const result = await submitSellerProduct({
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

sellerRouter.get("/seller/products", async (req, res) => {
  try {
    const user = await verifyCustomerToken(req.headers.authorization);
    if (!user) return res.status(401).json({ error: "not_authenticated" });
    const customerId = Number(user.sub);
    if (!Number.isFinite(customerId)) return res.status(400).json({ error: "invalid_customer" });

    const status = (req.query.status as string | undefined) || undefined;
    const page = req.query.page ? Number(req.query.page) : 1;
    const limit = req.query.limit ? Number(req.query.limit) : 20;

    const data = await listSellerProducts({ customerId, status, page, limit });
    res.json(data);
  } catch (err: any) {
    res.status(500).json({ error: "server_error", message: err.message });
  }
});

// ─── Admin ─────────────────────────────────────────────

sellerRouter.get("/admin/sellers", requireJwt, async (req, res) => {
  try {
    const user = (req as AuthenticatedRequest).user;
    if (!user?.isAdmin) return res.status(403).json({ error: "forbidden" });
    const status = (req.query.status as string | undefined) || undefined;
    const page = req.query.page ? Number(req.query.page) : 1;
    const limit = req.query.limit ? Number(req.query.limit) : 20;
    const data = await adminListSellers({ status, page, limit });
    res.json(data);
  } catch (err: any) {
    res.status(500).json({ error: "server_error", message: err.message });
  }
});

const adminSellerStatusSchema = z.object({
  reason: z.string().max(500).optional(),
});

function makeSellerStatusHandler(status: "approved" | "rejected" | "suspended") {
  return async (req: any, res: any) => {
    try {
      const user = (req as AuthenticatedRequest).user;
      if (!user?.isAdmin) return res.status(403).json({ error: "forbidden" });
      const parsed = adminSellerStatusSchema.safeParse(req.body ?? {});
      if (!parsed.success) return res.status(400).json({ error: "invalid_body" });
      const sellerId = Number(req.params.id);
      const result = await adminSetSellerStatus({
        sellerId,
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

sellerRouter.post("/admin/sellers/:id/approve", requireJwt, makeSellerStatusHandler("approved"));
sellerRouter.post("/admin/sellers/:id/reject",  requireJwt, makeSellerStatusHandler("rejected"));
sellerRouter.post("/admin/sellers/:id/suspend", requireJwt, makeSellerStatusHandler("suspended"));

sellerRouter.get("/admin/seller-products/pending", requireJwt, async (req, res) => {
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

sellerRouter.post("/admin/seller-products/:id/review", requireJwt, async (req, res) => {
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
