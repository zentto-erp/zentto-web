// hooks/useCuentasPorPagar.ts
"use client";

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { CuentaPorPagar, CreateCuentaPorPagarDTO, UpdateCuentaPorPagarDTO, CrudFilter, PaginatedResponse } from "@/lib/types";
import { apiGet, apiPost, apiPut, apiDelete } from "@/lib/api";

const QUERY_KEY = "cuentas-por-pagar";
const API_BASE = "/api/v1/cuentas-por-pagar";

export function useCuentasPorPagarList(filter?: CrudFilter) {
  return useQuery<PaginatedResponse<CuentaPorPagar>>({
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

export function useCuentaPorPagarById(id: string) {
  return useQuery<CuentaPorPagar>({
    queryKey: [QUERY_KEY, id],
    queryFn: () => apiGet(`${API_BASE}/${id}`),
    enabled: !!id,
  });
}

export function useCreateCuentaPorPagar() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (data: CreateCuentaPorPagarDTO) => apiPost(API_BASE, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: [QUERY_KEY] });
    },
  });
}

export function useUpdateCuentaPorPagar(id: string) {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (data: UpdateCuentaPorPagarDTO) => apiPut(`${API_BASE}/${id}`, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: [QUERY_KEY] });
      queryClient.invalidateQueries({ queryKey: [QUERY_KEY, id] });
    },
  });
}

export function useDeleteCuentaPorPagar() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (id: string) => apiDelete(`${API_BASE}/${id}`),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: [QUERY_KEY] });
    },
  });
}
