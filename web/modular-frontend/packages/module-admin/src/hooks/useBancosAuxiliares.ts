"use client";

import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { apiDelete, apiGet, apiPost, apiPut } from "@datqbox/shared-api";

const QUERY_KEY = "bancos-aux";
const API_BASE = "/api/v1/bancos";

export function useBancosList(filter?: { search?: string; page?: number; limit?: number }) {
  return useQuery<{ rows?: unknown[]; items?: unknown[]; total?: number }>({
    queryKey: [QUERY_KEY, "list", filter],
    queryFn: async () => {
      const p = new URLSearchParams();
      if (filter?.search) p.append("search", filter.search);
      if (filter?.page) p.append("page", String(filter.page));
      if (filter?.limit) p.append("limit", String(filter.limit));
      return apiGet(`${API_BASE}?${p.toString()}`);
    }
  });
}

export function useCreateBanco() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (payload: Record<string, unknown>) => apiPost(API_BASE, payload),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QUERY_KEY] })
  });
}

export function useUpdateBanco() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (payload: { nombre: string; data: Record<string, unknown> }) =>
      apiPut(`${API_BASE}/${encodeURIComponent(payload.nombre)}`, payload.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QUERY_KEY] })
  });
}

export function useDeleteBanco() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (nombre: string) => apiDelete(`${API_BASE}/${encodeURIComponent(nombre)}`),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QUERY_KEY] })
  });
}

export function useCuentasBancarias() {
  return useQuery<{ rows?: unknown[]; items?: unknown[]; total?: number }>({
    queryKey: [QUERY_KEY, "cuentas"],
    queryFn: () => apiGet(`${API_BASE}/cuentas/list`)
  });
}

export function useMovimientosCuenta(input?: { nroCta?: string; desde?: string; hasta?: string; page?: number; limit?: number }) {
  return useQuery<Record<string, unknown>>({
    queryKey: [QUERY_KEY, "movimientos", input],
    enabled: !!input?.nroCta,
    queryFn: async () => {
      const p = new URLSearchParams();
      if (input?.desde) p.append("desde", input.desde);
      if (input?.hasta) p.append("hasta", input.hasta);
      if (input?.page) p.append("page", String(input.page));
      if (input?.limit) p.append("limit", String(input.limit));
      return apiGet(`${API_BASE}/cuentas/${encodeURIComponent(String(input?.nroCta))}/movimientos?${p.toString()}`);
    }
  });
}

export function useGenerarMovimientoBancario() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (payload: {
      Nro_Cta: string;
      Tipo: "PCH" | "DEP" | "NCR" | "NDB" | "IDB";
      Nro_Ref: string;
      Beneficiario: string;
      Monto: number;
      Concepto: string;
      Categoria?: string;
      Documento_Relacionado?: string;
      Tipo_Doc_Rel?: string;
    }) => apiPost(`${API_BASE}/movimientos/generar`, payload),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QUERY_KEY] })
  });
}

