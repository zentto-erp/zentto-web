/**
 * admin-products.routes.ts — Backoffice ecommerce CRUD.
 *
 * Montado bajo /store/admin/... en app.ts.
 * Todos los endpoints requieren JWT + role=admin.
 *
 * Endpoints:
 *   GET    /store/admin/products
 *   GET    /store/admin/products/:code
 *   POST   /store/admin/products
 *   PUT    /store/admin/products/:code
 *   DELETE /store/admin/products/:code
 *   POST   /store/admin/products/:code/publish-toggle
 *   PUT    /store/admin/products/:code/images
 *   PUT    /store/admin/products/:code/highlights
 *   PUT    /store/admin/products/:code/specs
 *
 *   GET/POST /store/admin/categories
 *   PUT/DELETE /store/admin/categories/:code
 *
 *   GET/POST /store/admin/brands
 *   PUT/DELETE /store/admin/brands/:code
 *
 *   GET /store/admin/reviews
 *   POST /store/admin/reviews/:id/moderate
 *
 *   POST /store/admin/uploads/product-image (multer)
 */

import crypto from "node:crypto";
import fs from "node:fs";
import path from "node:path";
import { Router } from "express";
import multer from "multer";
import { z } from "zod";
import { env } from "../../config/env.js";
import { requireJwt, type AuthenticatedRequest } from "../../middleware/auth.js";
import { listCategories, listBrands } from "./service.js";
import {
  listAdminProducts,
  getAdminProductDetail,
  upsertAdminProduct,
  deleteAdminProduct,
  publishToggle,
  setProductImages,
  setProductHighlights,
  setProductSpecs,
  upsertCategory,
  deleteCategory,
  upsertBrand,
  deleteBrand,
  listAdminReviews,
  moderateReview,
} from "./admin-products.service.js";

export const adminProductsRouter = Router();

// ─── Middleware admin guard ───────────────────────────
adminProductsRouter.use(requireJwt, (req, res, next) => {
  const user = (req as AuthenticatedRequest).user;
  if (!user?.isAdmin) return res.status(403).json({ error: "forbidden" });
  return next();
});

// ═══════════════════════════════════════════════════════════════════════
// PRODUCTOS
// ═══════════════════════════════════════════════════════════════════════

const productListQuery = z.object({
  search: z.string().optional(),
  category: z.string().optional(),
  brand: z.string().optional(),
  published: z.enum(["published", "draft"]).optional(),
  lowStockOnly: z.enum(["0", "1", "true", "false"]).optional(),
  lowStockLimit: z.string().optional(),
  page: z.string().optional(),
  limit: z.string().optional(),
});

adminProductsRouter.get("/products", async (req, res) => {
  try {
    const parsed = productListQuery.safeParse(req.query);
    if (!parsed.success) return res.status(400).json({ error: "invalid_query", details: parsed.error.flatten() });

    const q = parsed.data;
    const lowStockOnly = q.lowStockOnly === "1" || q.lowStockOnly === "true";

    const data = await listAdminProducts({
      search: q.search,
      category: q.category,
      brand: q.brand,
      published: q.published ?? null,
      lowStockOnly,
      lowStockLimit: q.lowStockLimit ? Number(q.lowStockLimit) : undefined,
      page: q.page ? Number(q.page) : undefined,
      limit: q.limit ? Number(q.limit) : undefined,
    });
    res.json(data);
  } catch (err: any) {
    res.status(500).json({ error: "server_error", message: err.message });
  }
});

adminProductsRouter.get("/products/:code", async (req, res) => {
  try {
    const detail = await getAdminProductDetail(req.params.code);
    if (!detail) return res.status(404).json({ error: "not_found" });
    res.json(detail);
  } catch (err: any) {
    res.status(500).json({ error: "server_error", message: err.message });
  }
});

const productUpsertSchema = z.object({
  code: z.string().min(1).max(80),
  name: z.string().min(1).max(250),
  category: z.string().max(50).nullable().optional(),
  brand: z.string().max(20).nullable().optional(),
  price: z.number().nonnegative().optional(),
  compareAtPrice: z.number().nonnegative().nullable().optional(),
  costPrice: z.number().nonnegative().optional(),
  stockQty: z.number().optional(),
  shortDescription: z.string().max(500).nullable().optional(),
  longDescription: z.string().nullable().optional(),
  metaTitle: z.string().max(200).nullable().optional(),
  metaDescription: z.string().max(320).nullable().optional(),
  slug: z.string().max(200).nullable().optional(),
  barcode: z.string().max(50).nullable().optional(),
  unitCode: z.string().max(20).optional(),
  taxRate: z.number().min(0).max(100).optional(),
  weightKg: z.number().nonnegative().nullable().optional(),
  isService: z.boolean().optional(),
  isPublished: z.boolean().optional(),
});

adminProductsRouter.post("/products", async (req, res) => {
  try {
    const parsed = productUpsertSchema.safeParse(req.body);
    if (!parsed.success) return res.status(400).json({ error: "invalid_body", details: parsed.error.flatten() });

    const result = await upsertAdminProduct(parsed.data);
    if (!result.ok) return res.status(400).json(result);
    res.status(201).json(result);
  } catch (err: any) {
    res.status(500).json({ error: "server_error", message: err.message });
  }
});

adminProductsRouter.put("/products/:code", async (req, res) => {
  try {
    const bodyWithCode = { ...(req.body ?? {}), code: req.params.code };
    const parsed = productUpsertSchema.safeParse(bodyWithCode);
    if (!parsed.success) return res.status(400).json({ error: "invalid_body", details: parsed.error.flatten() });

    const result = await upsertAdminProduct(parsed.data);
    if (!result.ok) return res.status(400).json(result);
    res.json(result);
  } catch (err: any) {
    res.status(500).json({ error: "server_error", message: err.message });
  }
});

adminProductsRouter.delete("/products/:code", async (req, res) => {
  try {
    const result = await deleteAdminProduct(req.params.code);
    if (!result.ok) return res.status(400).json(result);
    res.json(result);
  } catch (err: any) {
    res.status(500).json({ error: "server_error", message: err.message });
  }
});

const publishToggleSchema = z.object({
  publish: z.boolean().optional(),
});

adminProductsRouter.post("/products/:code/publish-toggle", async (req, res) => {
  try {
    const parsed = publishToggleSchema.safeParse(req.body ?? {});
    if (!parsed.success) return res.status(400).json({ error: "invalid_body" });

    const result = await publishToggle(req.params.code, parsed.data.publish);
    if (!result.ok) return res.status(400).json(result);
    res.json(result);
  } catch (err: any) {
    res.status(500).json({ error: "server_error", message: err.message });
  }
});

// ─── Imágenes ─────────────────────────────────────────

const imagesSetSchema = z.object({
  images: z.array(
    z.object({
      url: z.string().url().max(500),
      altText: z.string().max(255).nullable().optional(),
      role: z.string().max(50).nullable().optional(),
      isPrimary: z.boolean().optional(),
      sortOrder: z.number().int().min(0).optional(),
      storageKey: z.string().max(500).nullable().optional(),
      storageProvider: z.string().max(30).nullable().optional(),
      mimeType: z.string().max(100).nullable().optional(),
      originalFileName: z.string().max(255).nullable().optional(),
    })
  ).max(50),
});

adminProductsRouter.put("/products/:code/images", async (req, res) => {
  try {
    const parsed = imagesSetSchema.safeParse(req.body);
    if (!parsed.success) return res.status(400).json({ error: "invalid_body", details: parsed.error.flatten() });

    const result = await setProductImages(req.params.code, parsed.data.images);
    if (!result.ok) return res.status(400).json(result);
    res.json(result);
  } catch (err: any) {
    res.status(500).json({ error: "server_error", message: err.message });
  }
});

const highlightsSetSchema = z.object({
  highlights: z.array(
    z.object({
      text: z.string().min(1).max(500),
      sortOrder: z.number().int().min(0).optional(),
    })
  ).max(20),
});

adminProductsRouter.put("/products/:code/highlights", async (req, res) => {
  try {
    const parsed = highlightsSetSchema.safeParse(req.body);
    if (!parsed.success) return res.status(400).json({ error: "invalid_body", details: parsed.error.flatten() });

    const result = await setProductHighlights(req.params.code, parsed.data.highlights);
    if (!result.ok) return res.status(400).json(result);
    res.json(result);
  } catch (err: any) {
    res.status(500).json({ error: "server_error", message: err.message });
  }
});

const specsSetSchema = z.object({
  specs: z.array(
    z.object({
      group: z.string().max(100).optional(),
      key: z.string().min(1).max(100),
      value: z.string().max(500),
      sortOrder: z.number().int().min(0).optional(),
    })
  ).max(100),
});

adminProductsRouter.put("/products/:code/specs", async (req, res) => {
  try {
    const parsed = specsSetSchema.safeParse(req.body);
    if (!parsed.success) return res.status(400).json({ error: "invalid_body", details: parsed.error.flatten() });

    const result = await setProductSpecs(req.params.code, parsed.data.specs);
    if (!result.ok) return res.status(400).json(result);
    res.json(result);
  } catch (err: any) {
    res.status(500).json({ error: "server_error", message: err.message });
  }
});

// ═══════════════════════════════════════════════════════════════════════
// CATEGORIES
// ═══════════════════════════════════════════════════════════════════════

adminProductsRouter.get("/categories", async (_req, res) => {
  try {
    const rows = await listCategories();
    res.json({ rows });
  } catch (err: any) {
    res.status(500).json({ error: "server_error", message: err.message });
  }
});

const catalogUpsertSchema = z.object({
  code: z.string().min(1).max(20),
  name: z.string().min(1).max(100),
  description: z.string().max(500).nullable().optional(),
});

adminProductsRouter.post("/categories", async (req, res) => {
  try {
    const parsed = catalogUpsertSchema.safeParse(req.body);
    if (!parsed.success) return res.status(400).json({ error: "invalid_body", details: parsed.error.flatten() });

    const result = await upsertCategory(parsed.data);
    if (!result.ok) return res.status(400).json(result);
    res.status(201).json(result);
  } catch (err: any) {
    res.status(500).json({ error: "server_error", message: err.message });
  }
});

adminProductsRouter.put("/categories/:code", async (req, res) => {
  try {
    const bodyWithCode = { ...(req.body ?? {}), code: req.params.code };
    const parsed = catalogUpsertSchema.safeParse(bodyWithCode);
    if (!parsed.success) return res.status(400).json({ error: "invalid_body", details: parsed.error.flatten() });

    const result = await upsertCategory(parsed.data);
    if (!result.ok) return res.status(400).json(result);
    res.json(result);
  } catch (err: any) {
    res.status(500).json({ error: "server_error", message: err.message });
  }
});

adminProductsRouter.delete("/categories/:code", async (req, res) => {
  try {
    const result = await deleteCategory(req.params.code);
    if (!result.ok) return res.status(400).json(result);
    res.json(result);
  } catch (err: any) {
    res.status(500).json({ error: "server_error", message: err.message });
  }
});

// ═══════════════════════════════════════════════════════════════════════
// BRANDS
// ═══════════════════════════════════════════════════════════════════════

adminProductsRouter.get("/brands", async (_req, res) => {
  try {
    const rows = await listBrands();
    res.json({ rows });
  } catch (err: any) {
    res.status(500).json({ error: "server_error", message: err.message });
  }
});

adminProductsRouter.post("/brands", async (req, res) => {
  try {
    const parsed = catalogUpsertSchema.safeParse(req.body);
    if (!parsed.success) return res.status(400).json({ error: "invalid_body", details: parsed.error.flatten() });

    const result = await upsertBrand(parsed.data);
    if (!result.ok) return res.status(400).json(result);
    res.status(201).json(result);
  } catch (err: any) {
    res.status(500).json({ error: "server_error", message: err.message });
  }
});

adminProductsRouter.put("/brands/:code", async (req, res) => {
  try {
    const bodyWithCode = { ...(req.body ?? {}), code: req.params.code };
    const parsed = catalogUpsertSchema.safeParse(bodyWithCode);
    if (!parsed.success) return res.status(400).json({ error: "invalid_body", details: parsed.error.flatten() });

    const result = await upsertBrand(parsed.data);
    if (!result.ok) return res.status(400).json(result);
    res.json(result);
  } catch (err: any) {
    res.status(500).json({ error: "server_error", message: err.message });
  }
});

adminProductsRouter.delete("/brands/:code", async (req, res) => {
  try {
    const result = await deleteBrand(req.params.code);
    if (!result.ok) return res.status(400).json(result);
    res.json(result);
  } catch (err: any) {
    res.status(500).json({ error: "server_error", message: err.message });
  }
});

// ═══════════════════════════════════════════════════════════════════════
// REVIEWS — moderación
// ═══════════════════════════════════════════════════════════════════════

const reviewListQuery = z.object({
  status: z.enum(["pending", "approved", "rejected"]).optional(),
  search: z.string().optional(),
  page: z.string().optional(),
  limit: z.string().optional(),
});

adminProductsRouter.get("/reviews", async (req, res) => {
  try {
    const parsed = reviewListQuery.safeParse(req.query);
    if (!parsed.success) return res.status(400).json({ error: "invalid_query" });

    const data = await listAdminReviews({
      status: parsed.data.status ?? null,
      search: parsed.data.search,
      page: parsed.data.page ? Number(parsed.data.page) : undefined,
      limit: parsed.data.limit ? Number(parsed.data.limit) : undefined,
    });
    res.json(data);
  } catch (err: any) {
    res.status(500).json({ error: "server_error", message: err.message });
  }
});

const reviewModerateSchema = z.object({
  status: z.enum(["approved", "rejected", "pending"]),
  moderator: z.string().max(60).optional(),
});

adminProductsRouter.post("/reviews/:id/moderate", async (req, res) => {
  try {
    const reviewId = Number(req.params.id);
    if (!Number.isFinite(reviewId) || reviewId <= 0) return res.status(400).json({ error: "invalid_id" });

    const parsed = reviewModerateSchema.safeParse(req.body);
    if (!parsed.success) return res.status(400).json({ error: "invalid_body", details: parsed.error.flatten() });

    const user = (req as AuthenticatedRequest).user;
    const moderator = parsed.data.moderator || user?.name || user?.sub || null;

    const result = await moderateReview(reviewId, parsed.data.status, moderator);
    if (!result.ok) return res.status(400).json(result);
    res.json(result);
  } catch (err: any) {
    res.status(500).json({ error: "server_error", message: err.message });
  }
});

// ═══════════════════════════════════════════════════════════════════════
// UPLOADS — product images
// ═══════════════════════════════════════════════════════════════════════

const UPLOAD_MAX_BYTES = Math.max(1, Number(env.media?.maxFileSizeMb || 5)) * 1024 * 1024;

const ALLOWED_IMAGE_MIMES = new Set([
  "image/jpeg",
  "image/png",
  "image/webp",
  "image/gif",
  "image/svg+xml",
]);

function getProductImageStorageFolder(companyId: number) {
  const base = env.media?.storagePath || "./storage/media";
  const now = new Date();
  const yyyy = String(now.getUTCFullYear());
  const mm = String(now.getUTCMonth() + 1).padStart(2, "0");
  return path.join(base, `c${companyId}`, "products", yyyy, mm);
}

const productImageStorage = multer.diskStorage({
  destination(_req, _file, cb) {
    try {
      // companyId será 1 por defecto en el contexto del admin — el upload es por archivo
      // y luego setProductImages liga vía URL.
      const folder = getProductImageStorageFolder(1);
      fs.mkdirSync(folder, { recursive: true });
      cb(null, folder);
    } catch (err) {
      cb(err as Error, env.media?.storagePath || "./storage/media");
    }
  },
  filename(_req, file, cb) {
    const ext = path.extname(file.originalname) || "";
    const id = crypto.randomUUID().replace(/-/g, "");
    cb(null, `${id}${ext}`);
  },
});

const productImageUploader = multer({
  storage: productImageStorage,
  limits: { fileSize: UPLOAD_MAX_BYTES, files: 1 },
  fileFilter: (_req, file, cb) => {
    if (!ALLOWED_IMAGE_MIMES.has(String(file.mimetype || "").toLowerCase())) {
      return cb(new Error("tipo_de_archivo_no_permitido"));
    }
    return cb(null, true);
  },
});

adminProductsRouter.post(
  "/uploads/product-image",
  productImageUploader.single("file"),
  async (req, res) => {
    try {
      const file = req.file;
      if (!file) return res.status(400).json({ error: "missing_file" });

      const basePath = env.media?.storagePath || "./storage/media";
      const storageKeyRaw = path.relative(basePath, file.path).replace(/\\/g, "/");
      const publicBaseUrl = env.media?.publicBaseUrl || "/media-files";
      const url = `${publicBaseUrl.replace(/\/+$/, "")}/${storageKeyRaw.replace(/^\/+/, "")}`;

      return res.status(201).json({
        ok: true,
        url,
        filename: file.originalname,
        storageKey: storageKeyRaw,
        storageProvider: "local",
        mimeType: file.mimetype,
        fileSizeBytes: file.size,
      });
    } catch (err: any) {
      return res.status(400).json({
        error: "upload_failed",
        message: String(err?.message ?? err),
      });
    }
  }
);
