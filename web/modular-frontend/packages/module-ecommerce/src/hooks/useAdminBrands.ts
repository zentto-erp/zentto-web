"use client";

import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
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

export interface BrandRow {
  code: string;
  name: string;
  productCount?: number;
  description?: string | null;
}

export interface BrandUpsertPayload {
  code: string;
  name: string;
  description?: string | null;
}

export function useAdminBrands() {
  return useQuery<{ rows: BrandRow[] }>({
    queryKey: ["admin-brands"],
    queryFn: () => adminFetch(`/store/admin/brands`),
  });
}

export function useUpsertBrand() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (input: BrandUpsertPayload & { isUpdate?: boolean }) => {
      const isUpdate = Boolean(input.isUpdate);
      const path = isUpdate
        ? `/store/admin/brands/${encodeURIComponent(input.code)}`
        : `/store/admin/brands`;
      const method = isUpdate ? "PUT" : "POST";
      return adminFetch(path, {
        method,
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(input),
      });
    },
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["admin-brands"] });
    },
  });
}

export function useDeleteBrand() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (code: string) =>
      adminFetch(`/store/admin/brands/${encodeURIComponent(code)}`, { method: "DELETE" }),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["admin-brands"] });
    },
  });
}
