"use client";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { apiDelete, apiGet, apiPost, apiPut } from "@zentto/shared-api";

const BASE = "/api/v1/crm";
const QK = "crm-contacts";

/* ─── Types ────────────────────────────────────────────────── */

export interface Contact {
  ContactId: number;
  FirstName: string;
  LastName: string | null;
  FullName?: string;
  Email: string | null;
  Phone: string | null;
  Mobile: string | null;
  Title: string | null;
  Department: string | null;
  LinkedIn: string | null;
  Notes: string | null;
  CrmCompanyId: number | null;
  CompanyName?: string | null;
  IsActive: boolean;
  CreatedAt: string;
  UpdatedAt?: string;
}

export interface ContactFilter {
  crmCompanyId?: number;
  search?: string;
  active?: boolean;
  page?: number;
  limit?: number;
}

export interface ContactInput {
  firstName: string;
  lastName?: string;
  email?: string;
  phone?: string;
  mobile?: string;
  title?: string;
  department?: string;
  linkedIn?: string;
  notes?: string;
  crmCompanyId?: number;
  isActive?: boolean;
}

/* ─── Queries ──────────────────────────────────────────────── */

export function useContactsList(filter?: ContactFilter) {
  return useQuery({
    queryKey: [QK, "list", filter],
    queryFn: () => apiGet(`${BASE}/contacts`, filter as Record<string, unknown>),
  });
}

export function useContact(id?: number | null) {
  return useQuery({
    queryKey: [QK, "detail", id],
    queryFn: () => apiGet(`${BASE}/contacts/${id}`),
    enabled: !!id,
  });
}

export function useSearchContacts(q: string, limit = 10) {
  return useQuery({
    queryKey: [QK, "search", q, limit],
    queryFn: () => apiGet(`${BASE}/contacts/search`, { q, limit }),
    enabled: q.trim().length > 0,
  });
}

/* ─── Mutations ────────────────────────────────────────────── */

export function useUpsertContact() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (d: { id?: number } & ContactInput) => {
      if (d.id) {
        const { id, ...rest } = d;
        return apiPut(`${BASE}/contacts/${id}`, rest);
      }
      return apiPost(`${BASE}/contacts`, d);
    },
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK] }),
  });
}

export function useDeleteContact() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id: number) => apiDelete(`${BASE}/contacts/${id}`),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK] }),
  });
}

export function usePromoteToCustomer() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (d: { id: number; customerCode?: string }) =>
      apiPost(`${BASE}/contacts/${d.id}/promote-customer`, {
        customerCode: d.customerCode,
      }),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK] }),
  });
}
