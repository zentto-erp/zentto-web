"use client";

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { InventarioMovimiento, Inventario, InventarioFilter, PaginatedResponse } from "@/lib/types";
import { apiGet, apiPost } from "@/lib/api";

const QUERY_KEY = "inventario";
const API_BASE = "/api/v1/inventario";

// ============ QUERIES ============

export function useInventarioList(filter?: InventarioFilter) {
  return useQuery<PaginatedResponse<InventarioMovimiento>>({
    queryKey: [QUERY_KEY, "list", filter],
    queryFn: async () => {
      const params = new URLSearchParams();
      if (filter?.search) params.append("search", filter.search);
      if (filter?.page) params.append("page", filter.page.toString());
      if (filter?.limit) params.append("limit", filter.limit.toString());
      
      // Filtros específicos de inventario
      if (filter?.tipo) params.append("tipo", filter.tipo);
      if (filter?.almacen) params.append("almacen", filter.almacen);
      if (filter?.fechaDesde) params.append("fechaDesde", filter.fechaDesde.toISOString());
      if (filter?.fechaHasta) params.append("fechaHasta", filter.fechaHasta.toISOString());

      return apiGet(`${API_BASE}?${params.toString()}`);
    },
  });
}

export function useInventarioById(id: string) {
  return useQuery<InventarioMovimiento>({
    queryKey: [QUERY_KEY, id],
    queryFn: () => apiGet(`${API_BASE}/${id}`),
    enabled: !!id,
  });
}

// ============ MUTATIONS ============

export function useCreateMovimiento() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (data: Inventario) => apiPost(API_BASE, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: [QUERY_KEY] });
      // También invalidamos artículos ya que el stock cambia
      queryClient.invalidateQueries({ queryKey: ["articulos"] });
    },
  });
}