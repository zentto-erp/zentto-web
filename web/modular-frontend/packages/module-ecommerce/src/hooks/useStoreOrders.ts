"use client";

import { useMutation, useQuery } from "@tanstack/react-query";
import { useCartStore } from "../store/useCartStore";

const API_BASE =
  typeof window !== "undefined"
    ? process.env.NEXT_PUBLIC_API_URL || "http://localhost:4000"
    : "http://localhost:4000";

async function storePost(path: string, body: unknown) {
  const res = await fetch(`${API_BASE}${path}`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body),
  });
  const data = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error(data?.message || data?.error || res.statusText);
  return data;
}

async function storeGet(path: string) {
  const res = await fetch(`${API_BASE}${path}`);
  const data = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error(data?.message || data?.error || res.statusText);
  return data;
}

async function storeGetAuth(path: string, token: string) {
  const res = await fetch(`${API_BASE}${path}`, {
    headers: { Authorization: `Bearer ${token}` },
  });
  const data = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error(data?.message || data?.error || res.statusText);
  return data;
}

export function useCheckout() {
  const clearCart = useCartStore((s) => s.clearCart);

  return useMutation({
    mutationFn: (payload: {
      customer: {
        name: string;
        email: string;
        phone?: string;
        address?: string;
        billingAddress?: string;
        fiscalId?: string;
      };
      items: Array<{
        productCode: string;
        productName: string;
        quantity: number;
        unitPrice: number;
        taxRate: number;
        subtotal: number;
        taxAmount: number;
      }>;
      notes?: string;
      addressId?: number;
      billingAddressId?: number;
      paymentMethodId?: number;
      paymentMethodType?: string;
      currencyCode?: string;
      exchangeRate?: number;
      countryCode?: string;
    }) => storePost("/store/checkout", payload),
    onSuccess: () => {
      clearCart();
    },
  });
}

export function useOrderByToken(token?: string) {
  return useQuery<any>({
    queryKey: ["store-order", "token", token],
    enabled: !!token,
    queryFn: () => storeGet(`/store/orders/${encodeURIComponent(token!)}`),
  });
}

export function useMyOrders(page = 1, limit = 20) {
  const customerToken = useCartStore((s) => s.customerToken);
  return useQuery<any>({
    queryKey: ["store-orders", "my", page, limit],
    enabled: !!customerToken,
    queryFn: () =>
      storeGetAuth(`/store/my/orders?page=${page}&limit=${limit}`, customerToken!),
  });
}
