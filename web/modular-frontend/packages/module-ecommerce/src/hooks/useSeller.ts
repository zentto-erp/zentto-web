"use client";

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

async function call(path: string, init?: RequestInit) {
  const res = await fetch(`${API_BASE}${path}`, {
    ...init,
    headers: { ...(init?.headers || {}), ...authHeaders() },
  });
  const data = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error((data as { message?: string }).message || res.statusText);
  return data;
}

// ─── Tipos ────────────────────────────────────────────

export interface SellerDashboard {
  sellerId: number;
  legalName: string;
  storeSlug: string;
  status: "pending" | "approved" | "suspended" | "rejected";
  commissionRate: number;
  productsTotal: number;
  productsApproved: number;
  productsPending: number;
  ordersTotal: number;
  grossSalesUsd: number;
  payoutsPaidUsd: number;
}

export interface SellerProduct {
  id: number;
  productCode: string;
  name: string;
  price: number;
  stock: number;
  category: string | null;
  imageUrl: string | null;
  status: "draft" | "pending_review" | "approved" | "rejected";
  reviewNotes: string | null;
  createdAt: string;
  updatedAt: string;
}

// ─── Queries ──────────────────────────────────────────

export function useSellerDashboard() {
  const token = useCartStore((s) => s.customerToken);
  return useQuery<SellerDashboard>({
    queryKey: ["seller-dashboard"],
    enabled: !!token,
    queryFn: () => call("/store/seller/dashboard"),
    staleTime: 30_000,
  });
}

export function useSellerProducts(params: { status?: string; page?: number; limit?: number } = {}) {
  const token = useCartStore((s) => s.customerToken);
  return useQuery<{ rows: SellerProduct[]; total: number; page: number; limit: number }>({
    queryKey: ["seller-products", params],
    enabled: !!token,
    queryFn: () => {
      const qs = new URLSearchParams();
      if (params.status) qs.set("status", params.status);
      if (params.page) qs.set("page", String(params.page));
      if (params.limit) qs.set("limit", String(params.limit));
      return call(`/store/seller/products${qs.toString() ? "?" + qs : ""}`);
    },
  });
}

// ─── Mutations ────────────────────────────────────────

export function useApplySeller() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (args: {
      legalName: string;
      taxId?: string;
      storeSlug?: string;
      description?: string;
      logoUrl?: string;
      contactEmail?: string;
      contactPhone?: string;
      payoutMethod?: string;
      payoutDetails?: Record<string, unknown>;
    }) =>
      call("/store/seller/apply", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(args),
      }),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["seller-dashboard"] }),
  });
}

export function useSubmitSellerProduct() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (args: {
      productId?: number;
      code?: string;
      name: string;
      description?: string;
      price: number;
      stock: number;
      category?: string;
      imageUrl?: string;
      submit?: boolean;
    }) =>
      call("/store/seller/products", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(args),
      }),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["seller-products"] });
      qc.invalidateQueries({ queryKey: ["seller-dashboard"] });
    },
  });
}
