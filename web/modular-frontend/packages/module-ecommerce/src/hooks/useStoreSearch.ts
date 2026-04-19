"use client";

import { useQuery } from "@tanstack/react-query";

const API_BASE =
  typeof window !== "undefined"
    ? process.env.NEXT_PUBLIC_API_URL || "http://localhost:4000"
    : "http://localhost:4000";

async function get<T>(path: string): Promise<T> {
  const res = await fetch(`${API_BASE}${path}`);
  const data = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error((data as { message?: string }).message || res.statusText);
  return data as T;
}

export interface SearchHit {
  code: string;
  name: string;
  highlight: string;
  category: string | null;
  brand: string | null;
  price: number;
  compareAt: number | null;
  stock: number;
  imageUrl: string;
  rank: number;
}

export interface SearchResponse {
  page: number;
  limit: number;
  total: number;
  rows: SearchHit[];
}

export function useStoreSearch(params: {
  query?: string;
  category?: string;
  brand?: string;
  page?: number;
  limit?: number;
  enabled?: boolean;
}) {
  const { enabled = true, ...rest } = params;
  const hasQuery = !!(rest.query && rest.query.trim().length > 0);
  return useQuery<SearchResponse>({
    queryKey: ["store-search", rest],
    enabled: enabled && hasQuery,
    queryFn: () => {
      const qs = new URLSearchParams();
      if (rest.query) qs.set("q", rest.query);
      if (rest.category) qs.set("category", rest.category);
      if (rest.brand) qs.set("brand", rest.brand);
      if (rest.page) qs.set("page", String(rest.page));
      if (rest.limit) qs.set("limit", String(rest.limit));
      return get<SearchResponse>(`/store/search?${qs}`);
    },
    staleTime: 30_000,
  });
}

export interface RecommendedProduct {
  code: string;
  name: string;
  category: string | null;
  brand: string | null;
  price: number;
  stock: number;
  imageUrl: string;
  avgRating: number;
  reviewCount: number;
  matchScore: number;
}

export function useProductRecommendations(productCode?: string, limit = 8) {
  return useQuery<RecommendedProduct[]>({
    queryKey: ["store-recommendations", productCode, limit],
    enabled: !!productCode,
    queryFn: () =>
      get<RecommendedProduct[]>(
        `/store/products/${encodeURIComponent(productCode!)}/recommendations?limit=${limit}`
      ),
    staleTime: 5 * 60 * 1000,
  });
}

export interface CompareProduct {
  code: string;
  name: string;
  brand: string | null;
  category: string | null;
  price: number;
  compareAt: number | null;
  stock: number;
  isService: boolean;
  warrantyMonths: number | null;
  weightKg: number | null;
  widthCm: number | null;
  heightCm: number | null;
  depthCm: number | null;
  imageUrl: string;
  avgRating: number;
  reviewCount: number;
  specs: Record<string, string>;
}

export function useCompareProducts(codes: string[]) {
  const safe = codes.filter(Boolean).slice(0, 4);
  const key = safe.join(",");
  return useQuery<CompareProduct[]>({
    queryKey: ["store-compare", key],
    enabled: safe.length >= 2,
    queryFn: () => get<CompareProduct[]>(`/store/compare?codes=${encodeURIComponent(key)}`),
  });
}
