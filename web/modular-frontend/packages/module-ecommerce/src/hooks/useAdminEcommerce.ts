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

/**
 * Hooks para uso desde el ERP modular (módulo admin/ecommerce). El JWT
 * que se envía es el del usuario admin del ERP — no el `customerToken`
 * del store; pero como el store se usa solo en la storefront pública,
 * acá esperamos que el shell autentique vía cookies httpOnly y que la
 * llamada incluya credentials.
 */
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

export interface AdminMetrics {
  totalOrders: number;
  pendingOrders: number;
  paidOrders: number;
  shippedOrders: number;
  deliveredOrders: number;
  cancelledOrders: number;
  pendingReturns: number;
  totalRevenueUsd: number;
  avgTicketUsd: number;
}

export interface AdminOrderDetail {
  orderNumber: string;
  orderDate: string;
  customerCode: string;
  customerName: string;
  fiscalId: string | null;
  notes: string | null;
  currencyCode: string;
  exchangeRate: number;
  subtotal: number;
  taxAmount: number;
  totalAmount: number;
  isPaid: string;
  isVoided: boolean;
  isDelivered: string;
  shipped: boolean;
  lines: Array<{ lineNumber: number; productCode: string; productName: string; quantity: number; unitPrice: number; lineTotal: number; }>;
  payments: Array<{ paymentId: number; method: string; reference: string; amount: number; date: string; }>;
  events: Array<{ eventCode: string; eventLabel: string; description: string | null; occurredAt: string; }>;
}

export interface ReturnSummary {
  returnId: number;
  orderNumber: string;
  customerCode: string;
  status: "requested" | "approved" | "rejected" | "in_transit" | "received" | "refunded";
  reason: string;
  refundAmount: number;
  refundCurrency: string;
  requestedAt: string;
  processedAt: string | null;
  itemCount: number;
}

export function useAdminMetrics(params: { from?: string; to?: string } = {}) {
  return useQuery<AdminMetrics>({
    queryKey: ["store-admin-metrics", params],
    queryFn: () => {
      const qs = new URLSearchParams();
      if (params.from) qs.set("from", params.from);
      if (params.to) qs.set("to", params.to);
      return adminFetch(`/store/admin/metrics${qs.toString() ? "?" + qs : ""}`);
    },
    staleTime: 60_000,
  });
}

export function useAdminOrderDetail(orderNumber?: string) {
  return useQuery<AdminOrderDetail>({
    queryKey: ["store-admin-order", orderNumber],
    enabled: !!orderNumber,
    queryFn: () => adminFetch(`/store/admin/orders/${encodeURIComponent(orderNumber!)}`),
  });
}

export function useMyOrderDetail(orderNumber?: string) {
  return useQuery<AdminOrderDetail>({
    queryKey: ["store-my-order", orderNumber],
    enabled: !!orderNumber,
    queryFn: () => adminFetch(`/store/my/orders/${encodeURIComponent(orderNumber!)}`),
  });
}

export function useAdminReturns(params: { status?: string; page?: number; limit?: number } = {}) {
  return useQuery<{ rows: ReturnSummary[]; total: number; page: number; limit: number }>({
    queryKey: ["store-admin-returns", params],
    queryFn: () => {
      const qs = new URLSearchParams();
      if (params.status) qs.set("status", params.status);
      if (params.page) qs.set("page", String(params.page));
      if (params.limit) qs.set("limit", String(params.limit));
      return adminFetch(`/store/admin/returns${qs.toString() ? "?" + qs : ""}`);
    },
  });
}

export function useAdminReturnDetail(returnId?: number) {
  return useQuery<any>({
    queryKey: ["store-admin-return", returnId],
    enabled: !!returnId,
    queryFn: () => adminFetch(`/store/admin/returns/${returnId}`),
  });
}

export function useAdminSetReturnStatus() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (args: { returnId: number; status: string; adminNotes?: string; refundMethod?: string; refundReference?: string }) =>
      adminFetch(`/store/admin/returns/${args.returnId}/status`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          status: args.status,
          adminNotes: args.adminNotes,
          refundMethod: args.refundMethod,
          refundReference: args.refundReference,
        }),
      }),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["store-admin-returns"] });
      qc.invalidateQueries({ queryKey: ["store-admin-return"] });
    },
  });
}
