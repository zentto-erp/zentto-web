"use client";

import { useMutation } from "@tanstack/react-query";
import { useCartStore } from "../store/useCartStore";

const API_BASE =
  typeof window !== "undefined"
    ? process.env.NEXT_PUBLIC_API_URL || "http://localhost:4000"
    : "http://localhost:4000";

async function call(path: string, init?: RequestInit) {
  const res = await fetch(`${API_BASE}${path}`, init);
  const data = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error((data as { message?: string }).message || res.statusText);
  return data;
}

export interface ServerCartItem {
  productCode: string;
  productName: string | null;
  imageUrl: string | null;
  quantity: number;
  unitPrice: number;
  taxRate: number;
}

export interface ServerCart {
  cartToken: string;
  customerCode: string | null;
  currencyCode: string | null;
  countryCode: string | null;
  exchangeRate: number;
  items: ServerCartItem[];
}

export async function fetchServerCart(token: string): Promise<ServerCart> {
  return call(`/store/cart?token=${encodeURIComponent(token)}`);
}

export async function pushCartItem(args: {
  cartToken: string;
  productCode: string;
  productName?: string | null;
  imageUrl?: string | null;
  quantity: number;
  unitPrice: number;
  taxRate: number;
  currencyCode?: string;
  countryCode?: string;
  exchangeRate?: number;
}) {
  return call("/store/cart/items", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(args),
  });
}

export async function deleteCartItem(cartToken: string, productCode: string) {
  return call(`/store/cart/items/${encodeURIComponent(productCode)}?token=${encodeURIComponent(cartToken)}`, {
    method: "DELETE",
  });
}

export async function clearServerCart(cartToken: string) {
  return call("/store/cart/clear", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ cartToken }),
  });
}

export function useMergeCart() {
  return useMutation({
    mutationFn: async (cartToken: string) => {
      const token = useCartStore.getState().customerToken;
      if (!token) throw new Error("not_authenticated");
      return call("/store/cart/merge", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify({ cartToken }),
      });
    },
  });
}
