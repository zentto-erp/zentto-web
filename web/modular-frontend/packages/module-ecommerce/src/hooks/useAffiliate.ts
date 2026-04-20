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

export interface CommissionRate {
  category: string;
  rate: number;
  isDefault?: boolean;
}

export interface AffiliateDashboard {
  affiliateId: number;
  referralCode: string;
  status: "active" | "suspended" | "pending" | "rejected";
  legalName: string | null;
  clicksTotal: number;
  conversions: number;
  pendingAmount: number;
  approvedAmount: number;
  paidAmount: number;
  totalEarned: number;
  currencyCode: string;
  monthly: Array<{ mon: string; amount: number }>;
}

export interface AffiliateCommission {
  id: number;
  orderNumber: string;
  rate: number;
  category: string;
  commissionAmount: number;
  currencyCode: string;
  status: "pending" | "approved" | "paid" | "reversed";
  createdAt: string;
  paidAt: string | null;
}

// ─── Query hooks ──────────────────────────────────────

/** Tasas públicas (no requieren login). */
export function useCommissionRates() {
  return useQuery<{ rows: CommissionRate[] }>({
    queryKey: ["affiliate-commission-rates"],
    queryFn: () => call("/store/affiliate/commission-rates"),
    staleTime: 30 * 60_000,
  });
}

/** Dashboard del afiliado (requiere login como affiliate). */
export function useAffiliateDashboard() {
  const token = useCartStore((s) => s.customerToken);
  return useQuery<AffiliateDashboard>({
    queryKey: ["affiliate-dashboard"],
    enabled: !!token,
    queryFn: () => call("/store/affiliate/dashboard"),
    staleTime: 30_000,
  });
}

/** Comisiones paginadas del afiliado. */
export function useAffiliateCommissions(params: { status?: string; page?: number; limit?: number } = {}) {
  const token = useCartStore((s) => s.customerToken);
  return useQuery<{ rows: AffiliateCommission[]; total: number; page: number; limit: number }>({
    queryKey: ["affiliate-commissions", params],
    enabled: !!token,
    queryFn: () => {
      const qs = new URLSearchParams();
      if (params.status) qs.set("status", params.status);
      if (params.page) qs.set("page", String(params.page));
      if (params.limit) qs.set("limit", String(params.limit));
      return call(`/store/affiliate/commissions${qs.toString() ? "?" + qs : ""}`);
    },
  });
}

// ─── Mutations ────────────────────────────────────────

export function useRegisterAffiliate() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (args: {
      legalName: string;
      taxId?: string;
      contactEmail?: string;
      payoutMethod?: string;
      payoutDetails?: Record<string, unknown>;
    }) =>
      call("/store/affiliate/register", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(args),
      }),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["affiliate-dashboard"] });
    },
  });
}

export function useTrackAffiliateClick() {
  return useMutation({
    mutationFn: (args: { referralCode: string; sessionId?: string; referer?: string }) =>
      call("/store/affiliate/track-click", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(args),
      }),
  });
}
