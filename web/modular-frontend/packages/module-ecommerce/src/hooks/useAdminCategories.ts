"use client";

import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useAdminAuthStore } from "../store/useAdminAuthStore";
import { formatApiError } from "./_shared/apiError";

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
  if (!res.ok) throw new Error(formatApiError(data, res.statusText || `HTTP ${res.status}`));
  return data;
}

export interface CategoryRow {
  code: string;
  name: string;
  productCount?: number;
  description?: string | null;
}

export interface CategoryUpsertPayload {
  code: string;
  name: string;
  description?: string | null;
}

export function useAdminCategories() {
  return useQuery<{ rows: CategoryRow[] }>({
    queryKey: ["admin-categories"],
    queryFn: () => adminFetch(`/store/admin/categories`),
  });
}

export function useUpsertCategory() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (input: CategoryUpsertPayload & { isUpdate?: boolean }) => {
      const isUpdate = Boolean(input.isUpdate);
      const path = isUpdate
        ? `/store/admin/categories/${encodeURIComponent(input.code)}`
        : `/store/admin/categories`;
      const method = isUpdate ? "PUT" : "POST";
      return adminFetch(path, {
        method,
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(input),
      });
    },
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["admin-categories"] });
    },
  });
}

export function useDeleteCategory() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (code: string) =>
      adminFetch(`/store/admin/categories/${encodeURIComponent(code)}`, { method: "DELETE" }),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["admin-categories"] });
    },
  });
}
