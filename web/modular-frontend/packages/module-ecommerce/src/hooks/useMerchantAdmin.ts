"use client";

import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useAdminAuthStore } from "../store/useAdminAuthStore";

const API_BASE =
  typeof window !== "undefined"
    ? process.env.NEXT_PUBLIC_API_URL || "http://localhost:4000"
    : "http://localhost:4000";

function authHeaders(): Record<string, string> {
  const token = useAdminAuthStore.getState().token;
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

export interface AdminMerchant {
  id: number;
  legalName: string;
  storeSlug: string;
  contactEmail: string | null;
  taxId: string | null;
  status: "pending" | "approved" | "suspended" | "rejected";
  commissionRate: number;
  productCount: number;
  approvedCount: number;
  createdAt: string;
  approvedAt: string | null;
}

export interface AdminMerchantProduct {
  id: number;
  merchantId: number;
  merchantName: string;
  productCode: string;
  name: string;
  price: number;
  stock: number;
  category: string | null;
  imageUrl: string | null;
  status: "draft" | "pending_review" | "approved" | "rejected";
  reviewNotes: string | null;
  createdAt: string;
}

export function useAdminMerchants(params: { status?: string; page?: number; limit?: number } = {}) {
  return useQuery<{ rows: AdminMerchant[]; total: number; page: number; limit: number }>({
    queryKey: ["admin-merchants", params],
    queryFn: () => {
      const qs = new URLSearchParams();
      if (params.status) qs.set("status", params.status);
      if (params.page) qs.set("page", String(params.page));
      if (params.limit) qs.set("limit", String(params.limit));
      return adminFetch(`/store/admin/merchants${qs.toString() ? "?" + qs : ""}`);
    },
  });
}

export function useAdminPendingMerchantProducts(params: { status?: string; page?: number; limit?: number } = {}) {
  return useQuery<{ rows: AdminMerchantProduct[]; total: number; page: number; limit: number }>({
    queryKey: ["admin-merchant-products", params],
    queryFn: () => {
      const qs = new URLSearchParams();
      if (params.status) qs.set("status", params.status);
      if (params.page) qs.set("page", String(params.page));
      if (params.limit) qs.set("limit", String(params.limit));
      return adminFetch(`/store/admin/merchant-products/pending${qs.toString() ? "?" + qs : ""}`);
    },
  });
}

export function useAdminSetMerchantStatus() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ id, status, reason }: { id: number; status: "approved" | "rejected" | "suspended"; reason?: string }) =>
      adminFetch(`/store/admin/merchants/${id}/${status === "approved" ? "approve" : status === "rejected" ? "reject" : "suspend"}`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(reason ? { reason } : {}),
      }),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["admin-merchants"] }),
  });
}

export function useAdminReviewMerchantProduct() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ id, status, notes }: { id: number; status: "approved" | "rejected"; notes?: string }) =>
      adminFetch(`/store/admin/merchant-products/${id}/review`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ status, notes }),
      }),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["admin-merchant-products"] }),
  });
}

/**
 * Genera payouts mensuales de merchants agrupando commissions approved.
 * Análogo a useAdminGenerateAffiliatePayouts.
 */
export function useAdminGenerateMerchantPayouts() {
  const qc = useQueryClient();
  return useMutation<
    { ok: boolean; message: string; payoutsCreated: number; totalAmount: number },
    Error,
    { periodStart?: string; periodEnd?: string } | undefined
  >({
    mutationFn: (args) =>
      adminFetch("/store/admin/merchants/payouts/generate", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          periodStart: args?.periodStart,
          periodEnd: args?.periodEnd,
        }),
      }),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["admin-merchants"] }),
  });
}
