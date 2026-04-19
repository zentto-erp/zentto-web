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

export interface PerfMeasurement {
  endpoint: string;
  description: string;
  durationMs: number;
  rowCount: number;
  ok: boolean;
  error?: string;
}

export interface PerfReport {
  measurements: PerfMeasurement[];
  totalMs: number;
  averageMs: number;
  worstCase: PerfMeasurement | null;
}

export function usePerfAudit(enabled = false) {
  return useQuery<PerfReport>({
    queryKey: ["store-admin-perf"],
    enabled,
    queryFn: () => adminFetch("/store/admin/perf"),
    staleTime: 0,
    gcTime: 0,
  });
}

export interface CacheStats {
  total: number;
  active: number;
  expired: number;
}

export function useCacheStats(enabled = true) {
  return useQuery<CacheStats>({
    queryKey: ["store-admin-cache-stats"],
    enabled,
    queryFn: () => adminFetch("/store/admin/cache/stats"),
    refetchInterval: 10_000,
  });
}

export function useInvalidateCache() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (prefix: string) =>
      adminFetch("/store/admin/cache/invalidate", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ prefix }),
      }),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["store-admin-cache-stats"] }),
  });
}
