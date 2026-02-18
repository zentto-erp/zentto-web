"use client";

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { Compra, CreateCompraDTO, CompraFilter, PaginatedResponse } from "@/lib/types";
import { apiGet, apiPost } from "@/lib/api";

const QUERY_KEY = "compras";
const API_BASE = "/api/v1/documentos-compra";
const TIPO_OPERACION = "COMPRA";

// ============ QUERIES ============

export function useComprasList(filter?: CompraFilter) {
  return useQuery<PaginatedResponse<Compra>>({
    queryKey: [QUERY_KEY, "list", filter],
    queryFn: async () => {
      const params = new URLSearchParams();
      if (filter?.search) params.append("search", filter.search);
      if (filter?.page) params.append("page", filter.page.toString());
      if (filter?.limit) params.append("limit", filter.limit.toString());
      
      if (filter?.proveedor) params.append("proveedor", filter.proveedor);
      if (filter?.estado) params.append("estado", filter.estado);
      if (filter?.fechaDesde) params.append("fechaDesde", filter.fechaDesde.toISOString());
      if (filter?.fechaHasta) params.append("fechaHasta", filter.fechaHasta.toISOString());
      params.append("tipoOperacion", TIPO_OPERACION);

      return apiGet(`${API_BASE}?${params.toString()}`);
    },
  });
}

export function useCompraByNumero(numero: string) {
  return useQuery<Compra>({
    queryKey: [QUERY_KEY, numero],
    queryFn: () => apiGet(`${API_BASE}/${TIPO_OPERACION}/${encodeURIComponent(numero)}`),
    enabled: !!numero,
  });
}

// ============ MUTATIONS ============

export function useCreateCompra() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (data: CreateCompraDTO) =>
      apiPost(`${API_BASE}/emitir-tx`, {
        tipoOperacion: TIPO_OPERACION,
        documento: data as unknown as Record<string, unknown>,
        detalle: (data as unknown as { detalles?: unknown[] }).detalles ?? []
      }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: [QUERY_KEY] });
      // Invalidamos proveedores (saldo) y artículos (stock/costo)
      queryClient.invalidateQueries({ queryKey: ["proveedores"] });
      queryClient.invalidateQueries({ queryKey: ["articulos"] });
    },
  });
}
