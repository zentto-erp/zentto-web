"use client";

import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useAdminAuthStore } from "../store/useAdminAuthStore";

const API_BASE =
  typeof window !== "undefined"
    ? process.env.NEXT_PUBLIC_API_URL || "http://localhost:4000"
    : "http://localhost:4000";

function authHeaders(): Record<string, string> {
  const { token, activeCompanyId, activeBranchId } = useAdminAuthStore.getState();
  if (!token) return {};
  const headers: Record<string, string> = { Authorization: `Bearer ${token}` };
  if (activeCompanyId) headers["X-Company-Id"] = String(activeCompanyId);
  if (activeBranchId)  headers["X-Branch-Id"]  = String(activeBranchId);
  return headers;
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

// ─── Tipos ────────────────────────────────────────────

export interface AdminAffiliate {
  id: number;
  referralCode: string;
  customerId: number;
  legalName: string | null;
  contactEmail: string | null;
  status: "active" | "suspended" | "pending" | "rejected";
  taxId: string | null;
  createdAt: string;
  approvedAt: string | null;
  pendingAmount: number;
  paidAmount: number;
}

export interface AdminAffiliateCommission {
  id: number;
  affiliateId: number;
  referralCode: string;
  legalName: string;
  orderNumber: string;
  rate: number;
  category: string;
  commissionAmount: number;
  currencyCode: string;
  status: "pending" | "approved" | "paid" | "reversed";
  createdAt: string;
}

// ─── Queries ──────────────────────────────────────────

export function useAdminAffiliates(params: { status?: string; page?: number; limit?: number } = {}) {
  return useQuery<{ rows: AdminAffiliate[]; total: number; page: number; limit: number }>({
    queryKey: ["admin-affiliates", params],
    queryFn: () => {
      const qs = new URLSearchParams();
      if (params.status) qs.set("status", params.status);
      if (params.page) qs.set("page", String(params.page));
      if (params.limit) qs.set("limit", String(params.limit));
      return adminFetch(`/store/admin/affiliates${qs.toString() ? "?" + qs : ""}`);
    },
  });
}

export function useAdminAffiliateCommissions(params: { status?: string; page?: number; limit?: number } = {}) {
  return useQuery<{ rows: AdminAffiliateCommission[]; total: number; page: number; limit: number }>({
    queryKey: ["admin-affiliate-commissions", params],
    queryFn: () => {
      const qs = new URLSearchParams();
      if (params.status) qs.set("status", params.status);
      if (params.page) qs.set("page", String(params.page));
      if (params.limit) qs.set("limit", String(params.limit));
      return adminFetch(`/store/admin/affiliates/commissions${qs.toString() ? "?" + qs : ""}`);
    },
  });
}

// ─── Mutations ────────────────────────────────────────

export function useAdminSetAffiliateStatus() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ id, status }: { id: number; status: "active" | "suspended" | "pending" | "rejected" }) =>
      adminFetch(`/store/admin/affiliates/${id}/status`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ status }),
      }),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["admin-affiliates"] }),
  });
}

export function useAdminGenerateAffiliatePayouts() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (args: { periodStart?: string; periodEnd?: string } = {}) =>
      adminFetch("/store/admin/affiliates/payouts/generate", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(args),
      }),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["admin-affiliate-commissions"] });
      qc.invalidateQueries({ queryKey: ["admin-affiliates"] });
    },
  });
}

/** Bulk-approve / bulk-mark-paid comisiones (Ola 4 — liquidación mensual). */
export function useAdminBulkSetCommissionStatus() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ ids, status }: { ids: number[]; status: "approved" | "paid" | "reversed" }) =>
      adminFetch("/store/admin/affiliates/commissions/bulk-status", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ ids, status }),
      }),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["admin-affiliate-commissions"] });
    },
  });
}
