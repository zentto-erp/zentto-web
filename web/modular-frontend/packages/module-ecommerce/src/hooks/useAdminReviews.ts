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

export interface AdminReviewRow {
  reviewId: number;
  productCode: string;
  productName: string | null;
  rating: number;
  title: string | null;
  comment: string;
  reviewerName: string;
  reviewerEmail: string | null;
  status: "pending" | "approved" | "rejected";
  isVerified: boolean;
  createdAt: string;
  moderatedAt: string | null;
  moderatorUser: string | null;
}

export interface AdminReviewListParams {
  status?: "pending" | "approved" | "rejected";
  search?: string;
  page?: number;
  limit?: number;
}

export function useAdminReviewsList(params: AdminReviewListParams = {}) {
  return useQuery<{ rows: AdminReviewRow[]; total: number; page: number; limit: number }>({
    queryKey: ["admin-reviews", params],
    queryFn: () => {
      const qs = new URLSearchParams();
      if (params.status) qs.set("status", params.status);
      if (params.search) qs.set("search", params.search);
      if (params.page) qs.set("page", String(params.page));
      if (params.limit) qs.set("limit", String(params.limit));
      return adminFetch(`/store/admin/reviews${qs.toString() ? "?" + qs : ""}`);
    },
  });
}

export function useModerateReview() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (args: {
      reviewId: number;
      status: "approved" | "rejected" | "pending";
      moderator?: string;
    }) =>
      adminFetch(`/store/admin/reviews/${args.reviewId}/moderate`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ status: args.status, moderator: args.moderator }),
      }),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["admin-reviews"] });
    },
  });
}
