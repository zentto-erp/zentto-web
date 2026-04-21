"use client";

import { useMutation, useQueryClient } from "@tanstack/react-query";
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

export interface SpecInput {
  group?: string;
  key: string;
  value: string;
  sortOrder?: number;
}

export function useSetProductSpecs() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (args: { code: string; specs: SpecInput[] }) =>
      adminFetch(`/store/admin/products/${encodeURIComponent(args.code)}/specs`, {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ specs: args.specs }),
      }),
    onSuccess: (_data, variables) => {
      qc.invalidateQueries({ queryKey: ["admin-product", variables.code] });
    },
  });
}
