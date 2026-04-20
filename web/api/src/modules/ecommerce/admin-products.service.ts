/**
 * admin-products.service.ts — Backoffice ecommerce:
 *   - CRUD productos (incluye SEO + publish toggle)
 *   - Imágenes / Highlights / Specs (reemplazo masivo)
 *   - Categorías y marcas CRUD
 *   - Reviews (list + moderation)
 *
 * Todos los SPs son dual-motor (PostgreSQL + SQL Server) vía callSp/callSpOut.
 */

import { callSp, callSpOut, sql } from "../../db/query.js";
import { getActiveScope } from "../_shared/scope.js";
import { invalidatePrefix } from "../../lib/storefront-cache.js";

function scope() {
  const s = getActiveScope();
  return { companyId: s?.companyId ?? 1, branchId: s?.branchId ?? 1 };
}

// ─── Tipos ─────────────────────────────────────────────

export interface AdminProductListItem {
  id: number;
  code: string;
  name: string;
  category: string | null;
  categoryName: string | null;
  brandCode: string | null;
  brandName: string | null;
  price: number;
  compareAtPrice: number | null;
  costPrice: number;
  stock: number;
  isService: boolean;
  isPublished: boolean;
  publishedAt: string | null;
  imageUrl: string | null;
  slug: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface AdminImageInput {
  url: string;
  altText?: string | null;
  role?: string | null;
  isPrimary?: boolean;
  sortOrder?: number;
  storageKey?: string | null;
  storageProvider?: string | null;
  mimeType?: string | null;
  originalFileName?: string | null;
}

export interface AdminHighlightInput {
  text: string;
  sortOrder?: number;
}

export interface AdminSpecInput {
  group?: string;
  key: string;
  value: string;
  sortOrder?: number;
}

export interface AdminReviewListItem {
  reviewId: number;
  productCode: string;
  productName: string | null;
  rating: number;
  title: string | null;
  comment: string;
  reviewerName: string;
  reviewerEmail: string | null;
  status: "pending" | "approved" | "rejected";
  isVerified: boolean;
  createdAt: string;
  moderatedAt: string | null;
  moderatorUser: string | null;
}

// ─── Helpers ──────────────────────────────────────────

/** Invalida caches públicos relevantes del store al mutar catálogo. */
function bustStorefrontCache() {
  try {
    invalidatePrefix("products:");
    invalidatePrefix("categories:");
    invalidatePrefix("brands:");
    invalidatePrefix("search:");
    invalidatePrefix("compare");
  } catch {
    /* no-op */
  }
}

// ─── Productos ────────────────────────────────────────

export async function listAdminProducts(params: {
  search?: string;
  category?: string;
  brand?: string;
  published?: "published" | "draft" | null;
  lowStockOnly?: boolean;
  lowStockLimit?: number;
  page?: number;
  limit?: number;
}) {
  const page = Math.max(params.page ?? 1, 1);
  const limit = Math.min(Math.max(params.limit ?? 25, 1), 200);

  const { rows, output } = await callSpOut<AdminProductListItem>(
    "usp_Store_Product_ListAdmin",
    {
      CompanyId: scope().companyId,
      BranchId: scope().branchId,
      Search: params.search?.trim() || null,
      Category: params.category || null,
      Brand: params.brand || null,
      Published: params.published ?? null,
      LowStockOnly: params.lowStockOnly ? 1 : 0,
      LowStockLimit: params.lowStockLimit ?? 5,
      Page: page,
      Limit: limit,
    },
    { TotalCount: sql.Int }
  );

  return {
    page,
    limit,
    total: Number(output.TotalCount ?? 0),
    rows,
  };
}

export async function getAdminProductDetail(code: string) {
  const companyId = scope().companyId;
  const branchId = scope().branchId;

  const [productRows, images, highlightRows, specRows] = await Promise.all([
    callSp<any>("usp_Store_Product_GetByCode", { CompanyId: companyId, BranchId: branchId, Code: code }),
    callSp<any>("usp_Store_Product_GetImages", { CompanyId: companyId, BranchId: branchId, Code: code }),
    callSp<any>("usp_Store_Product_GetHighlights", { CompanyId: companyId, Code: code }),
    callSp<any>("usp_Store_Product_GetSpecs", { CompanyId: companyId, Code: code }),
  ]);

  const product = productRows[0] ?? null;
  if (!product) return null;

  return {
    ...product,
    images,
    highlights: highlightRows.map((h: any) => ({
      text: h.text ?? h.Text,
      sortOrder: h.sortOrder ?? h.SortOrder ?? 0,
    })),
    specs: specRows.map((s: any) => ({
      group: s.group ?? s.Group,
      key: s.key ?? s.Key,
      value: s.value ?? s.Value,
    })),
  };
}

export async function upsertAdminProduct(input: {
  code: string;
  name: string;
  category?: string | null;
  brand?: string | null;
  price?: number;
  compareAtPrice?: number | null;
  costPrice?: number;
  stockQty?: number;
  shortDescription?: string | null;
  longDescription?: string | null;
  metaTitle?: string | null;
  metaDescription?: string | null;
  slug?: string | null;
  barcode?: string | null;
  unitCode?: string;
  taxRate?: number;
  weightKg?: number | null;
  isService?: boolean;
  isPublished?: boolean;
  userId?: number | null;
}) {
  const { rows, output } = await callSpOut<{ Code: string }>(
    "usp_Store_Product_Upsert",
    {
      CompanyId: scope().companyId,
      Code: input.code,
      Name: input.name,
      Category: input.category ?? null,
      Brand: input.brand ?? null,
      Price: input.price ?? 0,
      CompareAtPrice: input.compareAtPrice ?? null,
      CostPrice: input.costPrice ?? 0,
      StockQty: input.stockQty ?? 0,
      ShortDescription: input.shortDescription ?? null,
      LongDescription: input.longDescription ?? null,
      MetaTitle: input.metaTitle ?? null,
      MetaDescription: input.metaDescription ?? null,
      Slug: input.slug ?? null,
      Barcode: input.barcode ?? null,
      UnitCode: input.unitCode ?? "UND",
      TaxRate: input.taxRate ?? 0,
      WeightKg: input.weightKg ?? null,
      IsService: input.isService ? 1 : 0,
      IsPublished: input.isPublished ? 1 : 0,
      UserId: input.userId ?? null,
    },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500), OutCode: sql.NVarChar(80) }
  );

  const ok = Number(output.Resultado) === 1;
  if (ok) bustStorefrontCache();

  return {
    ok,
    resultado: output.Resultado,
    mensaje: output.Mensaje ?? rows[0]?.Code ?? null,
    code: output.OutCode ?? input.code,
  };
}

export async function deleteAdminProduct(code: string, userId: number | null = null) {
  const { output } = await callSpOut(
    "usp_Store_Product_Delete",
    { CompanyId: scope().companyId, Code: code, UserId: userId },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );

  const ok = Number(output.Resultado) === 1;
  if (ok) bustStorefrontCache();

  return { ok, mensaje: output.Mensaje };
}

export async function publishToggle(code: string, publish?: boolean, userId: number | null = null) {
  const { output } = await callSpOut(
    "usp_Store_Product_PublishToggle",
    {
      CompanyId: scope().companyId,
      Code: code,
      Publish: publish === undefined ? null : publish ? 1 : 0,
      UserId: userId,
    },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500), IsPublished: sql.Bit }
  );

  const ok = Number(output.Resultado) === 1;
  if (ok) bustStorefrontCache();

  return {
    ok,
    mensaje: output.Mensaje,
    isPublished: Boolean(output.IsPublished),
  };
}

export async function setProductImages(code: string, images: AdminImageInput[], userId: number | null = null) {
  const { output } = await callSpOut(
    "usp_Store_Product_Images_Set",
    {
      CompanyId: scope().companyId,
      BranchId: scope().branchId,
      Code: code,
      ImagesJson: JSON.stringify(images ?? []),
      UserId: userId,
    },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500), Count: sql.Int }
  );

  const ok = Number(output.Resultado) === 1;
  if (ok) bustStorefrontCache();

  return { ok, mensaje: output.Mensaje, count: Number(output.Count ?? 0) };
}

export async function setProductHighlights(code: string, highlights: AdminHighlightInput[]) {
  const { output } = await callSpOut(
    "usp_Store_Product_Highlights_Set",
    {
      CompanyId: scope().companyId,
      Code: code,
      HighlightsJson: JSON.stringify(highlights ?? []),
    },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500), Count: sql.Int }
  );

  const ok = Number(output.Resultado) === 1;
  if (ok) bustStorefrontCache();

  return { ok, mensaje: output.Mensaje, count: Number(output.Count ?? 0) };
}

export async function setProductSpecs(code: string, specs: AdminSpecInput[]) {
  const { output } = await callSpOut(
    "usp_Store_Product_Specs_Set",
    {
      CompanyId: scope().companyId,
      Code: code,
      SpecsJson: JSON.stringify(specs ?? []),
    },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500), Count: sql.Int }
  );

  const ok = Number(output.Resultado) === 1;
  if (ok) bustStorefrontCache();

  return { ok, mensaje: output.Mensaje, count: Number(output.Count ?? 0) };
}

// ─── Categorías ───────────────────────────────────────

export async function upsertCategory(input: {
  code: string;
  name: string;
  description?: string | null;
  userId?: number | null;
}) {
  const { output } = await callSpOut(
    "usp_Store_Category_Upsert",
    {
      CompanyId: scope().companyId,
      Code: input.code,
      Name: input.name,
      Description: input.description ?? null,
      UserId: input.userId ?? null,
    },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500), OutCode: sql.NVarChar(20) }
  );

  const ok = Number(output.Resultado) === 1;
  if (ok) bustStorefrontCache();

  return { ok, mensaje: output.Mensaje, code: output.OutCode };
}

export async function deleteCategory(code: string, userId: number | null = null) {
  const { output } = await callSpOut(
    "usp_Store_Category_Delete",
    { CompanyId: scope().companyId, Code: code, UserId: userId },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );

  const ok = Number(output.Resultado) === 1;
  if (ok) bustStorefrontCache();

  return { ok, mensaje: output.Mensaje };
}

// ─── Marcas ───────────────────────────────────────────

export async function upsertBrand(input: {
  code: string;
  name: string;
  description?: string | null;
  userId?: number | null;
}) {
  const { output } = await callSpOut(
    "usp_Store_Brand_Upsert",
    {
      CompanyId: scope().companyId,
      Code: input.code,
      Name: input.name,
      Description: input.description ?? null,
      UserId: input.userId ?? null,
    },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500), OutCode: sql.NVarChar(20) }
  );

  const ok = Number(output.Resultado) === 1;
  if (ok) bustStorefrontCache();

  return { ok, mensaje: output.Mensaje, code: output.OutCode };
}

export async function deleteBrand(code: string, userId: number | null = null) {
  const { output } = await callSpOut(
    "usp_Store_Brand_Delete",
    { CompanyId: scope().companyId, Code: code, UserId: userId },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );

  const ok = Number(output.Resultado) === 1;
  if (ok) bustStorefrontCache();

  return { ok, mensaje: output.Mensaje };
}

// ─── Reviews ──────────────────────────────────────────

export async function listAdminReviews(params: {
  status?: "pending" | "approved" | "rejected" | null;
  search?: string;
  page?: number;
  limit?: number;
}) {
  const page = Math.max(params.page ?? 1, 1);
  const limit = Math.min(Math.max(params.limit ?? 25, 1), 200);

  const { rows, output } = await callSpOut<AdminReviewListItem>(
    "usp_Store_Review_List",
    {
      CompanyId: scope().companyId,
      Status: params.status ?? null,
      Search: params.search?.trim() || null,
      Page: page,
      Limit: limit,
    },
    { TotalCount: sql.Int }
  );

  return {
    page,
    limit,
    total: Number(output.TotalCount ?? 0),
    rows,
  };
}

export async function moderateReview(reviewId: number, status: "approved" | "rejected" | "pending", moderator?: string | null) {
  const { output } = await callSpOut(
    "usp_Store_Review_Moderate",
    {
      CompanyId: scope().companyId,
      ReviewId: reviewId,
      Status: status,
      Moderator: moderator ?? null,
    },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );

  const ok = Number(output.Resultado) === 1;
  if (ok) bustStorefrontCache();

  return { ok, mensaje: output.Mensaje };
}
