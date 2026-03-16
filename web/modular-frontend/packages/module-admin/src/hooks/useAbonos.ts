// hooks/useAbonos.ts
"use client";

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { Abono, CreateAbonoDTO, UpdateAbonoDTO, CrudFilter, PaginatedResponse } from "@zentto/shared-api/types";
import { apiGet, apiPost, apiPut, apiDelete } from "@zentto/shared-api";

const QUERY_KEY = "abonos";
const API_BASE = "/api/v1/abonos";

export function useAbonosList(filter?: CrudFilter) {
  return useQuery<PaginatedResponse<Abono>>({
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

export function useAbonoById(numeroAbono: string) {
  return useQuery<Abono>({
    queryKey: [QUERY_KEY, numeroAbono],
    queryFn: () => apiGet(`${API_BASE}/${numeroAbono}`),
    enabled: !!numeroAbono,
  });
}

export function useCreateAbono() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (data: CreateAbonoDTO) => apiPost(API_BASE, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: [QUERY_KEY] });
    },
  });
}

export function useUpdateAbono(numeroAbono: string) {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (data: UpdateAbonoDTO) => apiPut(`${API_BASE}/${numeroAbono}`, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: [QUERY_KEY] });
      queryClient.invalidateQueries({ queryKey: [QUERY_KEY, numeroAbono] });
    },
  });
}

export function useDeleteAbono() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (numeroAbono: string) => apiDelete(`${API_BASE}/${numeroAbono}`),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: [QUERY_KEY] });
    },
  });
}
