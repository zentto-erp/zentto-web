"use client";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { apiDelete, apiGet, apiPost, apiPut } from "@zentto/shared-api";

const BASE = "/api/v1/crm";
const QK = "crm-companies";

/* ─── Types ────────────────────────────────────────────────── */

export interface Company {
  CrmCompanyId: number;
  Name: string;
  LegalName: string | null;
  TaxId: string | null;
  Industry: string | null;
  Size: string | null;
  Website: string | null;
  Phone: string | null;
  Email: string | null;
  Notes: string | null;
  IsActive: boolean;
  CreatedAt: string;
  UpdatedAt?: string;
}

export interface CompanyFilter {
  search?: string;
  industry?: string;
  active?: boolean;
  page?: number;
  limit?: number;
}

export type CompanySize = "1-10" | "11-50" | "51-200" | "201-500" | "501-1000" | "1000+";

export interface CompanyInput {
  name: string;
  legalName?: string;
  taxId?: string;
  industry?: string;
  size?: CompanySize | string;
  website?: string;
  phone?: string;
  email?: string;
  notes?: string;
  isActive?: boolean;
}

/* ─── Queries ──────────────────────────────────────────────── */

export function useCompaniesList(filter?: CompanyFilter) {
  return useQuery({
    queryKey: [QK, "list", filter],
    queryFn: () => apiGet(`${BASE}/companies`, filter as Record<string, unknown>),
  });
}

export function useCompany(id?: number | null) {
  return useQuery({
    queryKey: [QK, "detail", id],
    queryFn: () => apiGet(`${BASE}/companies/${id}`),
    enabled: !!id,
  });
}

export function useSearchCompanies(q: string, limit = 10) {
  return useQuery({
    queryKey: [QK, "search", q, limit],
    queryFn: () => apiGet(`${BASE}/companies/search`, { q, limit }),
    enabled: q.trim().length > 0,
  });
}

/* ─── Mutations ────────────────────────────────────────────── */

export function useUpsertCompany() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (d: { id?: number } & CompanyInput) => {
      if (d.id) {
        const { id, ...rest } = d;
        return apiPut(`${BASE}/companies/${id}`, rest);
      }
      return apiPost(`${BASE}/companies`, d);
    },
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK] }),
  });
}

export function useDeleteCompany() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id: number) => apiDelete(`${BASE}/companies/${id}`),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK] }),
  });
}
