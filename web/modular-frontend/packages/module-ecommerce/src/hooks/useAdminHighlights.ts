"use client";

import { useMutation, useQueryClient } from "@tanstack/react-query";
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

export interface HighlightInput {
  text: string;
  sortOrder?: number;
}

export function useSetProductHighlights() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (args: { code: string; highlights: HighlightInput[] }) =>
      adminFetch(`/store/admin/products/${encodeURIComponent(args.code)}/highlights`, {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ highlights: args.highlights }),
      }),
    onSuccess: (_data, variables) => {
      qc.invalidateQueries({ queryKey: ["admin-product", variables.code] });
    },
  });
}
