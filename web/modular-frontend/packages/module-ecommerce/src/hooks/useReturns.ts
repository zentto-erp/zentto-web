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

export interface MyReturn {
  returnId: number;
  orderNumber: string;
  status: "requested" | "approved" | "rejected" | "in_transit" | "received" | "refunded";
  reason: string;
  refundAmount: number;
  refundCurrency: string;
  requestedAt: string;
  processedAt: string | null;
  itemCount: number;
}

export function useMyReturns() {
  const customerToken = useCartStore((s) => s.customerToken);
  return useQuery<{ rows: MyReturn[]; total: number }>({
    queryKey: ["store-my-returns", customerToken],
    enabled: !!customerToken,
    queryFn: () => call("/store/my/returns"),
  });
}

export function useMyReturnDetail(returnId?: number) {
  return useQuery<any>({
    queryKey: ["store-my-return", returnId],
    enabled: !!returnId,
    queryFn: () => call(`/store/my/returns/${returnId}`),
  });
}

export function useCreateReturn() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (args: {
      orderNumber: string;
      reason: string;
      items?: Array<{
        lineNumber?: number;
        productCode: string;
        productName?: string;
        quantity?: number;
        unitPrice?: number;
        reason?: string;
      }>;
    }) =>
      call("/store/returns", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(args),
      }),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["store-my-returns"] }),
  });
}
