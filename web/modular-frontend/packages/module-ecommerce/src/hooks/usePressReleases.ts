"use client";

import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";

const API_BASE =
  typeof window !== "undefined"
    ? process.env.NEXT_PUBLIC_API_URL || "http://localhost:4000"
    : "http://localhost:4000";

async function storeGet(path: string) {
  const res = await fetch(`${API_BASE}${path}`);
  const data = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error(data?.message || data?.error || res.statusText);
  return data;
}

async function storeAuth(path: string, method: string, token: string | null, body?: unknown) {
  const headers: Record<string, string> = { "Content-Type": "application/json" };
  if (token) headers["Authorization"] = `Bearer ${token}`;
  const res = await fetch(`${API_BASE}${path}`, {
    method,
    headers,
    body: body !== undefined ? JSON.stringify(body) : undefined,
  });
  const data = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error(data?.message || data?.error || res.statusText);
  return data;
}

function adminToken(): string | null {
  if (typeof window === "undefined") return null;
  return localStorage.getItem("adminToken") || localStorage.getItem("zentto_admin_token") || null;
}

export interface PressReleaseSummary {
  pressReleaseId: number;
  slug: string;
  title: string;
  excerpt: string | null;
  coverImageUrl: string | null;
  tags: string[];
  status: string;
  publishedAt: string | null;
  updatedAt: string;
  createdAt: string;
}

export interface PressReleaseFull extends PressReleaseSummary {
  body: string | null;
}

// ─── Público ───────────────────────────────────────────

export function usePressReleases(page = 1, limit = 20) {
  return useQuery<{ items: PressReleaseSummary[]; totalCount: number }>({
    queryKey: ["press-releases", page, limit],
    queryFn: () => storeGet(`/store/press/releases?page=${page}&limit=${limit}`),
  });
}

export function usePressRelease(slug: string) {
  return useQuery<{ item: PressReleaseFull }>({
    queryKey: ["press-release", slug],
    enabled: !!slug,
    queryFn: () => storeGet(`/store/press/releases/${encodeURIComponent(slug)}`),
  });
}

// ─── Admin ─────────────────────────────────────────────

export function useAdminPressReleases(status?: string) {
  return useQuery<{ items: PressReleaseSummary[]; totalCount: number }>({
    queryKey: ["admin-press-releases", status],
    queryFn: () =>
      storeAuth(
        `/store/admin/press/releases${status ? `?status=${encodeURIComponent(status)}` : ""}`,
        "GET",
        adminToken(),
      ),
  });
}

export function useAdminPressRelease(id: number | null) {
  return useQuery<{ item: PressReleaseFull }>({
    queryKey: ["admin-press-release", id],
    enabled: !!id,
    queryFn: () => storeAuth(`/store/admin/press/releases/${id}`, "GET", adminToken()),
  });
}

export interface PressReleaseUpsertInput {
  slug: string;
  title: string;
  excerpt?: string | null;
  body?: string | null;
  coverImageUrl?: string | null;
  tags?: string[];
  status?: "draft" | "published" | "archived";
}

export function useUpsertPressRelease() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (input: PressReleaseUpsertInput & { pressReleaseId?: number }) =>
      input.pressReleaseId
        ? storeAuth(`/store/admin/press/releases/${input.pressReleaseId}`, "PUT", adminToken(), input)
        : storeAuth(`/store/admin/press/releases`, "POST", adminToken(), input),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["admin-press-releases"] }),
  });
}

export function useDeletePressRelease() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id: number) => storeAuth(`/store/admin/press/releases/${id}`, "DELETE", adminToken()),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["admin-press-releases"] }),
  });
}

export function usePublishPressRelease() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id: number) =>
      storeAuth(`/store/admin/press/releases/${id}/publish`, "POST", adminToken()),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["admin-press-releases"] }),
  });
}
