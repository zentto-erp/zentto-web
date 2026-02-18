// hooks/useInventario.ts
"use client";

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { Inventario, CreateInventarioDTO, UpdateInventarioDTO, CrudFilter, PaginatedResponse } from "@datqbox/shared-api/types";
import { apiGet, apiPost, apiPut, apiDelete } from "@datqbox/shared-api";

const QUERY_KEY = "inventario";
const API_BASE = "/api/v1/inventario";

// ============ QUERIES ============

export function useInventarioList(filter?: CrudFilter) {
  return useQuery<PaginatedResponse<Inventario>>({
    queryKey: [QUERY_KEY, "list", filter],
    queryFn: async () => {
      const params = new URLSearchParams();
      if (filter?.search) params.append("search", filter.search);
      if (filter?.page) params.append("page", filter.page.toString());
      if (filter?.limit) params.append("limit", filter.limit.toString());
      return apiGet(`${API_BASE}?${params.toString()}`);
    },
  });
}

export function useInventarioById(codigoArticulo: string) {
  return useQuery<Inventario>({
    queryKey: [QUERY_KEY, codigoArticulo],
    queryFn: () => apiGet(`${API_BASE}/${codigoArticulo}`),
    enabled: !!codigoArticulo,
  });
}

// ============ MUTATIONS ============

export function useCreateMovimiento() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (data: CreateInventarioDTO) => apiPost(`${API_BASE}/movimientos`, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: [QUERY_KEY] });
    },
  });
}

export function useUpdateInventario(codigoArticulo: string) {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (data: UpdateInventarioDTO) => apiPut(`${API_BASE}/${codigoArticulo}`, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: [QUERY_KEY] });
      queryClient.invalidateQueries({ queryKey: [QUERY_KEY, codigoArticulo] });
    },
  });
}

export function useDeleteInventario() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (codigoArticulo: string) => apiDelete(`${API_BASE}/${codigoArticulo}`),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: [QUERY_KEY] });
    },
  });
}
