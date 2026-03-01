"use client";

import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { apiGet, apiPost } from "@datqbox/shared-api";

const QUERY_KEY = "conciliacion-bancaria";
const API_BASE = "/api/v1/bancos";

export type ConciliacionFilter = {
  Nro_Cta?: string;
  Estado?: string;
  page?: number;
  limit?: number;
};

export function useConciliaciones(filter?: ConciliacionFilter) {
  return useQuery<unknown>({
    queryKey: [QUERY_KEY, "list", filter],
    queryFn: async () => {
      const p = new URLSearchParams();
      if (filter?.Nro_Cta) p.append("Nro_Cta", filter.Nro_Cta);
      if (filter?.Estado) p.append("Estado", filter.Estado);
      if (filter?.page) p.append("page", String(filter.page));
      if (filter?.limit) p.append("limit", String(filter.limit));
      return apiGet(`${API_BASE}/conciliaciones?${p.toString()}`);
    }
  });
}

export function useCuentasBank() {
  return useQuery<unknown>({
    queryKey: [QUERY_KEY, "cuentas"],
    queryFn: () => apiGet(`${API_BASE}/cuentas/list`)
  });
}

export function useConciliacionDetalle(id?: number) {
  return useQuery<unknown>({
    queryKey: [QUERY_KEY, "detalle", id],
    queryFn: () => apiGet(`${API_BASE}/conciliaciones/${id}`),
    enabled: !!id
  });
}

export function useCrearConciliacion() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (payload: { Nro_Cta: string; Fecha_Desde: string; Fecha_Hasta: string }) => {
      try {
        return await apiPost(`${API_BASE}/conciliaciones`, payload);
      } catch {
        return apiPost(`${API_BASE}/conciliaciones/crear`, payload);
      }
    },
    onSuccess: () => qc.invalidateQueries({ queryKey: [QUERY_KEY] })
  });
}

export function useImportarExtracto() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (payload: { conciliacionId: number; extracto: Array<Record<string, unknown>> }) => {
      try {
        return await apiPost(`${API_BASE}/conciliaciones/${payload.conciliacionId}/extracto`, {
          extracto: payload.extracto
        });
      } catch {
        return apiPost(`${API_BASE}/conciliaciones/${payload.conciliacionId}/importar-extracto`, {
          extracto: payload.extracto
        });
      }
    },
    onSuccess: () => qc.invalidateQueries({ queryKey: [QUERY_KEY] })
  });
}

export function useConciliarMovimiento() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (payload: { Conciliacion_ID: number; MovimientoSistema_ID: number; Extracto_ID?: number }) =>
      apiPost(`${API_BASE}/conciliaciones/conciliar`, payload),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QUERY_KEY] })
  });
}

export function useGenerarAjuste() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (payload: {
      Conciliacion_ID: number;
      Tipo_Ajuste: "NOTA_CREDITO" | "NOTA_DEBITO";
      Monto: number;
      Descripcion: string;
    }) => {
      try {
        return await apiPost(`${API_BASE}/conciliaciones/ajustar`, payload);
      } catch {
        return apiPost(`${API_BASE}/conciliaciones/ajuste`, payload);
      }
    },
    onSuccess: () => qc.invalidateQueries({ queryKey: [QUERY_KEY] })
  });
}

export function useCerrarConciliacion() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (payload: { Conciliacion_ID: number; Saldo_Final_Banco: number; Observaciones?: string }) =>
      apiPost(`${API_BASE}/conciliaciones/cerrar`, payload),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QUERY_KEY] })
  });
}

