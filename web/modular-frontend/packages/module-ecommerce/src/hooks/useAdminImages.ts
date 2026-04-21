"use client";

/**
 * Hooks para gestión de imágenes/highlights/specs del producto (admin).
 */

import { useMutation, useQueryClient } from "@tanstack/react-query";
import { useAdminAuthStore } from "../store/useAdminAuthStore";

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
  if (!res.ok) throw new Error((data as { message?: string }).message || res.statusText);
  return data;
}

export interface ProductImageInput {
  url: string;
  altText?: string | null;
  role?: string | null;
  isPrimary?: boolean;
  sortOrder?: number;
  storageKey?: string | null;
  storageProvider?: string | null;
  mimeType?: string | null;
  originalFileName?: string | null;
}

export interface ProductImageUploadResult {
  ok: boolean;
  url: string;
  filename: string;
  storageKey: string;
  storageProvider: string;
  mimeType: string;
  fileSizeBytes: number;
}

/** Sube un archivo individual y devuelve la URL para luego asociarla con setImages. */
export function useUploadProductImage() {
  return useMutation({
    mutationFn: async (file: File): Promise<ProductImageUploadResult> => {
      const form = new FormData();
      form.append("file", file);
      const res = await fetch(`${API_BASE}/store/admin/uploads/product-image`, {
        method: "POST",
        credentials: "include",
        headers: { ...authHeaders() },
        body: form,
      });
      const data = await res.json().catch(() => ({}));
      if (!res.ok) throw new Error((data as { message?: string }).message || res.statusText);
      return data as ProductImageUploadResult;
    },
  });
}

/** Reemplaza todas las imágenes del producto. */
export function useSetProductImages() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (args: { code: string; images: ProductImageInput[] }) =>
      adminFetch(`/store/admin/products/${encodeURIComponent(args.code)}/images`, {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ images: args.images }),
      }),
    onSuccess: (_data, variables) => {
      qc.invalidateQueries({ queryKey: ["admin-product", variables.code] });
      qc.invalidateQueries({ queryKey: ["admin-products"] });
    },
  });
}
