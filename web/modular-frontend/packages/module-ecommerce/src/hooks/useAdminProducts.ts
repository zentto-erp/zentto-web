"use client";

/**
 * Hooks para CRUD de productos del backoffice ecommerce.
 */

import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useCartStore } from "../store/useCartStore";

const API_BASE =
  typeof window !== "undefined"
    ? process.env.NEXT_PUBLIC_API_URL || "http://localhost:4000"
    : "http://localhost:4000";

function authHeaders(): Record<string, string> {
  const token = useCartStore.getState().customerToken;
  return token ? { Authorization: `Bearer ${token}` } : {};
}

async function adminFetch(path: string, init: RequestInit = {}) {
  const res = await fetch(`${API_BASE}${path}`, {
    credentials: "include",
    ...init,
    headers: { ...(init.headers || {}), ...authHeaders() },
  });
  const data = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error((data as { message?: string }).message || res.statusText);
  return data;
}

// ─── Types ─────────────────────────────────────────────

export interface AdminProductRow {
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

export interface AdminProductDetail extends Partial<AdminProductRow> {
  code: string;
  name: string;
  longDescription?: string | null;
  shortDescription?: string | null;
  metaTitle?: string | null;
  metaDescription?: string | null;
  slug?: string | null;
  images?: Array<{
    id: number;
    url: string;
    altText: string | null;
    role: string | null;
    isPrimary: boolean;
    sortOrder: number;
  }>;
  highlights?: Array<{ text: string; sortOrder: number }>;
  specs?: Array<{ group: string; key: string; value: string }>;
}

export interface AdminProductUpsertPayload {
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
}

export interface AdminProductListParams {
  search?: string;
  category?: string;
  brand?: string;
  published?: "published" | "draft";
  lowStockOnly?: boolean;
  page?: number;
  limit?: number;
}

// ─── List ──────────────────────────────────────────────

export function useAdminProducts(params: AdminProductListParams = {}) {
  return useQuery<{ rows: AdminProductRow[]; total: number; page: number; limit: number }>({
    queryKey: ["admin-products", params],
    queryFn: () => {
      const qs = new URLSearchParams();
      if (params.search) qs.set("search", params.search);
      if (params.category) qs.set("category", params.category);
      if (params.brand) qs.set("brand", params.brand);
      if (params.published) qs.set("published", params.published);
      if (params.lowStockOnly) qs.set("lowStockOnly", "1");
      if (params.page) qs.set("page", String(params.page));
      if (params.limit) qs.set("limit", String(params.limit));
      return adminFetch(`/store/admin/products${qs.toString() ? "?" + qs : ""}`);
    },
    staleTime: 30_000,
  });
}

// ─── Detail ────────────────────────────────────────────

export function useAdminProductDetail(code?: string) {
  return useQuery<AdminProductDetail>({
    queryKey: ["admin-product", code],
    enabled: !!code,
    queryFn: () => adminFetch(`/store/admin/products/${encodeURIComponent(code!)}`),
  });
}

// ─── Upsert ───────────────────────────────────────────

export function useUpsertAdminProduct() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (input: AdminProductUpsertPayload & { isUpdate?: boolean }) => {
      const isUpdate = Boolean(input.isUpdate);
      const path = isUpdate
        ? `/store/admin/products/${encodeURIComponent(input.code)}`
        : `/store/admin/products`;
      const method = isUpdate ? "PUT" : "POST";
      return adminFetch(path, {
        method,
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(input),
      });
    },
    onSuccess: (_data, variables) => {
      qc.invalidateQueries({ queryKey: ["admin-products"] });
      qc.invalidateQueries({ queryKey: ["admin-product", variables.code] });
    },
  });
}

// ─── Delete ───────────────────────────────────────────

export function useDeleteAdminProduct() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (code: string) =>
      adminFetch(`/store/admin/products/${encodeURIComponent(code)}`, { method: "DELETE" }),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["admin-products"] });
    },
  });
}

// ─── Publish Toggle ───────────────────────────────────

export function usePublishToggleAdminProduct() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (args: { code: string; publish?: boolean }) =>
      adminFetch(`/store/admin/products/${encodeURIComponent(args.code)}/publish-toggle`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ publish: args.publish }),
      }),
    onSuccess: (_data, variables) => {
      qc.invalidateQueries({ queryKey: ["admin-products"] });
      qc.invalidateQueries({ queryKey: ["admin-product", variables.code] });
    },
  });
}
