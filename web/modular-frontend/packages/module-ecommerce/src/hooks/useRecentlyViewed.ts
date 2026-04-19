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

export interface RecentlyViewedItem {
  productCode: string;
  productName: string;
  imageUrl: string | null;
  price: number;
  stock: number;
  viewedAt: string;
}

/** El cartToken (UUID persistente del carrito) sirve también como sessionToken para guests. */
function sessionTokenFromCart(): string | null {
  try {
    return useCartStore.getState().cartToken || null;
  } catch {
    return null;
  }
}

export function useRecentlyViewed(limit = 12) {
  const customerToken = useCartStore((s) => s.customerToken);
  const session = sessionTokenFromCart();
  return useQuery<RecentlyViewedItem[]>({
    queryKey: ["store-recently-viewed", customerToken ?? session, limit],
    enabled: !!(customerToken || session),
    queryFn: async () => {
      const url = new URL(`${API_BASE}/store/recently-viewed`);
      url.searchParams.set("limit", String(limit));
      if (!customerToken && session) url.searchParams.set("session", session);
      const res = await fetch(url.toString(), { headers: authHeaders() });
      if (!res.ok) return [];
      return res.json();
    },
  });
}

export function useTrackRecentlyViewed() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (productCode: string) => {
      const session = sessionTokenFromCart();
      const res = await fetch(`${API_BASE}/store/recently-viewed`, {
        method: "POST",
        headers: { "Content-Type": "application/json", ...authHeaders() },
        body: JSON.stringify({ productCode, sessionToken: session }),
      });
      return res.json().catch(() => ({}));
    },
    onSuccess: () => qc.invalidateQueries({ queryKey: ["store-recently-viewed"] }),
  });
}
