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

export interface AdminSeller {
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

export interface AdminSellerProduct {
  id: number;
  sellerId: number;
  sellerName: string;
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

export function useAdminSellers(params: { status?: string; page?: number; limit?: number } = {}) {
  return useQuery<{ rows: AdminSeller[]; total: number; page: number; limit: number }>({
    queryKey: ["admin-sellers", params],
    queryFn: () => {
      const qs = new URLSearchParams();
      if (params.status) qs.set("status", params.status);
      if (params.page) qs.set("page", String(params.page));
      if (params.limit) qs.set("limit", String(params.limit));
      return adminFetch(`/store/admin/sellers${qs.toString() ? "?" + qs : ""}`);
    },
  });
}

export function useAdminPendingSellerProducts(params: { status?: string; page?: number; limit?: number } = {}) {
  return useQuery<{ rows: AdminSellerProduct[]; total: number; page: number; limit: number }>({
    queryKey: ["admin-seller-products", params],
    queryFn: () => {
      const qs = new URLSearchParams();
      if (params.status) qs.set("status", params.status);
      if (params.page) qs.set("page", String(params.page));
      if (params.limit) qs.set("limit", String(params.limit));
      return adminFetch(`/store/admin/seller-products/pending${qs.toString() ? "?" + qs : ""}`);
    },
  });
}

export function useAdminSetSellerStatus() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ id, status, reason }: { id: number; status: "approved" | "rejected" | "suspended"; reason?: string }) =>
      adminFetch(`/store/admin/sellers/${id}/${status === "approved" ? "approve" : status === "rejected" ? "reject" : "suspend"}`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(reason ? { reason } : {}),
      }),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["admin-sellers"] }),
  });
}

export function useAdminReviewSellerProduct() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ id, status, notes }: { id: number; status: "approved" | "rejected"; notes?: string }) =>
      adminFetch(`/store/admin/seller-products/${id}/review`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ status, notes }),
      }),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["admin-seller-products"] }),
  });
}
