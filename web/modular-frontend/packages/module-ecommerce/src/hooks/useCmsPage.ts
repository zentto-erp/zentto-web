"use client";

import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import type { LandingConfig } from "../components/StudioPageRenderer";

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

// ─── Público ───────────────────────────────────────────

export interface CmsPageApi {
  cmsPageId: number;
  slug: string;
  title: string;
  subtitle: string | null;
  templateKey: string | null;
  config: LandingConfig;
  seo: Record<string, unknown>;
  status: string;
  publishedAt: string | null;
  updatedAt: string;
}

export function useCmsPage(slug: string) {
  return useQuery<{ page: CmsPageApi }>({
    queryKey: ["cms-page", slug],
    enabled: !!slug,
    queryFn: () => storeGet(`/store/cms/pages/${encodeURIComponent(slug)}`),
  });
}

export function useSubmitContactMessage() {
  return useMutation({
    mutationFn: (body: {
      name: string;
      email: string;
      phone?: string | null;
      subject?: string | null;
      message: string;
      source?: string;
    }) =>
      fetch(`${API_BASE}/store/contact/message`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(body),
      }).then(async (res) => {
        const data = await res.json().catch(() => ({}));
        if (!res.ok) throw new Error(data?.error || res.statusText);
        return data;
      }),
  });
}

// ─── Admin: CMS pages ──────────────────────────────────

export interface CmsPageSummaryApi {
  cmsPageId: number;
  slug: string;
  title: string;
  subtitle: string | null;
  templateKey: string | null;
  status: string;
  publishedAt: string | null;
  updatedAt: string;
  createdAt: string;
}

function adminToken(): string | null {
  if (typeof window === "undefined") return null;
  // JWT de admin viene del session admin del ERP; usamos el mismo storage.
  return localStorage.getItem("adminToken") || localStorage.getItem("zentto_admin_token") || null;
}

export function useAdminCmsPages(status?: string) {
  return useQuery<{ items: CmsPageSummaryApi[]; totalCount: number }>({
    queryKey: ["admin-cms-pages", status],
    queryFn: () =>
      storeAuth(
        `/store/admin/cms/pages${status ? `?status=${encodeURIComponent(status)}` : ""}`,
        "GET",
        adminToken(),
      ),
  });
}

export function useAdminCmsPage(id: number | null) {
  return useQuery<{ page: CmsPageApi }>({
    queryKey: ["admin-cms-page", id],
    enabled: !!id,
    queryFn: () => storeAuth(`/store/admin/cms/pages/${id}`, "GET", adminToken()),
  });
}

export interface CmsPageUpsertInput {
  slug: string;
  title: string;
  subtitle?: string | null;
  templateKey?: string | null;
  config?: unknown;
  seo?: unknown;
  status?: "draft" | "published" | "archived";
}

export function useUpsertCmsPage() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (input: CmsPageUpsertInput & { cmsPageId?: number }) =>
      input.cmsPageId
        ? storeAuth(`/store/admin/cms/pages/${input.cmsPageId}`, "PUT", adminToken(), input)
        : storeAuth(`/store/admin/cms/pages`, "POST", adminToken(), input),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["admin-cms-pages"] });
    },
  });
}

export function useDeleteCmsPage() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id: number) => storeAuth(`/store/admin/cms/pages/${id}`, "DELETE", adminToken()),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["admin-cms-pages"] }),
  });
}

export function usePublishCmsPage() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id: number) => storeAuth(`/store/admin/cms/pages/${id}/publish`, "POST", adminToken()),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["admin-cms-pages"] }),
  });
}
