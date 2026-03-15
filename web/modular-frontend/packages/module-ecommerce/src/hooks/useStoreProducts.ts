"use client";

import { useQuery, useMutation } from "@tanstack/react-query";

const API_BASE =
  typeof window !== "undefined"
    ? process.env.NEXT_PUBLIC_API_URL || "http://localhost:4000"
    : "http://localhost:4000";

async function storeGet(path: string) {
  const res = await fetch(`${API_BASE}${path}`);
  const data = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error(data?.message || data?.error || res.statusText);
  return data;
}

const QK = "store-products";

export interface ProductFilters {
  search?: string;
  category?: string;
  brand?: string;
  priceMin?: number;
  priceMax?: number;
  minRating?: number;
  inStockOnly?: boolean;
  sortBy?: string;
  page?: number;
  limit?: number;
}

export function useProductList(filters?: ProductFilters) {
  return useQuery<any>({
    queryKey: [QK, "list", filters],
    queryFn: async () => {
      const p = new URLSearchParams();
      if (filters?.search) p.append("search", filters.search);
      if (filters?.category) p.append("category", filters.category);
      if (filters?.brand) p.append("brand", filters.brand);
      if (filters?.priceMin != null) p.append("priceMin", String(filters.priceMin));
      if (filters?.priceMax != null) p.append("priceMax", String(filters.priceMax));
      if (filters?.minRating != null) p.append("minRating", String(filters.minRating));
      if (filters?.inStockOnly === false) p.append("inStockOnly", "0");
      if (filters?.sortBy) p.append("sortBy", filters.sortBy);
      if (filters?.page) p.append("page", String(filters.page));
      if (filters?.limit) p.append("limit", String(filters.limit));
      const qs = p.toString();
      return storeGet(`/store/products${qs ? `?${qs}` : ""}`);
    },
  });
}

export function useProductDetail(code?: string) {
  return useQuery<any>({
    queryKey: [QK, "detail", code],
    enabled: !!code,
    queryFn: () => storeGet(`/store/products/${encodeURIComponent(code!)}`),
  });
}

export function useCategoryList() {
  return useQuery<any[]>({
    queryKey: [QK, "categories"],
    queryFn: () => storeGet("/store/categories"),
    staleTime: 5 * 60 * 1000,
  });
}

export function useBrandList() {
  return useQuery<any[]>({
    queryKey: [QK, "brands"],
    queryFn: () => storeGet("/store/brands"),
    staleTime: 5 * 60 * 1000,
  });
}

// ─── Reseñas ──────────────────────────────────────────

export function useProductReviews(productCode?: string, page = 1, limit = 20) {
  return useQuery<any>({
    queryKey: [QK, "reviews", productCode, page],
    enabled: !!productCode,
    queryFn: () => storeGet(`/store/products/${encodeURIComponent(productCode!)}/reviews?page=${page}&limit=${limit}`),
  });
}

export function useCreateReview() {
  return useMutation({
    mutationFn: async (data: { productCode: string; rating: number; title?: string; comment: string; reviewerName?: string }) => {
      const res = await fetch(`${API_BASE}/store/reviews`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(data),
      });
      const json = await res.json().catch(() => ({}));
      if (!res.ok) throw new Error(json?.message || json?.error || res.statusText);
      return json;
    },
  });
}
