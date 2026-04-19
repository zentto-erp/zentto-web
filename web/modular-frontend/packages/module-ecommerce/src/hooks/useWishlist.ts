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

export interface WishlistItem {
  productCode: string;
  productName: string;
  imageUrl: string | null;
  price: number;
  stock: number;
  addedAt: string;
}

export function useWishlist(enabled = true) {
  const customerToken = useCartStore((s) => s.customerToken);
  return useQuery<WishlistItem[]>({
    queryKey: ["store-wishlist", customerToken],
    enabled: enabled && !!customerToken,
    queryFn: async () => {
      const res = await fetch(`${API_BASE}/store/wishlist`, { headers: authHeaders() });
      if (!res.ok) throw new Error((await res.json().catch(() => ({}))).error || res.statusText);
      return res.json();
    },
  });
}

export function useToggleWishlist() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (productCode: string) => {
      const res = await fetch(`${API_BASE}/store/wishlist/toggle`, {
        method: "POST",
        headers: { "Content-Type": "application/json", ...authHeaders() },
        body: JSON.stringify({ productCode }),
      });
      const data = await res.json().catch(() => ({}));
      if (!res.ok) throw new Error((data as { error?: string }).error || res.statusText);
      return data as { ok: boolean; inWishlist: boolean; message: string };
    },
    onSuccess: () => qc.invalidateQueries({ queryKey: ["store-wishlist"] }),
  });
}
