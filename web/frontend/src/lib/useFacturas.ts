"use client";

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { Factura, CreateFacturaDTO, FacturaFilter, PaginatedResponse } from "@/lib/types";
import { apiGet, apiPost } from "@/lib/api";

const QUERY_KEY = "facturas";
const API_BASE = "/api/v1/documentos-venta";
const TIPO_OPERACION = "FACT";

// ============ QUERIES ============

export function useFacturasList(filter?: FacturaFilter) {
  return useQuery<PaginatedResponse<Factura>>({
    queryKey: [QUERY_KEY, "list", filter],
    queryFn: async () => {
      const params = new URLSearchParams();
      if (filter?.search) params.append("search", filter.search);
      if (filter?.page) params.append("page", filter.page.toString());
      if (filter?.limit) params.append("limit", filter.limit.toString());
      
      // Filtros específicos de facturas
      if (filter?.cliente) params.append("cliente", filter.cliente);
      if (filter?.estado) params.append("estado", filter.estado);
      if (filter?.fechaDesde) params.append("fechaDesde", filter.fechaDesde.toISOString());
      if (filter?.fechaHasta) params.append("fechaHasta", filter.fechaHasta.toISOString());
      params.append("tipoOperacion", TIPO_OPERACION);

      return apiGet(`${API_BASE}?${params.toString()}`);
    },
  });
}

export function useFacturaByNumero(numero: string) {
  return useQuery<Factura>({
    queryKey: [QUERY_KEY, numero],
    queryFn: () => apiGet(`${API_BASE}/${TIPO_OPERACION}/${encodeURIComponent(numero)}`),
    enabled: !!numero,
  });
}

// ============ MUTATIONS ============

export function useCreateFactura() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (data: CreateFacturaDTO) =>
      apiPost(`${API_BASE}/emitir-tx`, {
        tipoOperacion: TIPO_OPERACION,
        documento: data as unknown as Record<string, unknown>,
        detalle: (data as unknown as { detalles?: unknown[] }).detalles ?? []
      }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: [QUERY_KEY] });
      // Invalidamos clientes (saldo) y artículos (stock)
      queryClient.invalidateQueries({ queryKey: ["clientes"] });
      queryClient.invalidateQueries({ queryKey: ["articulos"] });
    },
  });
}

export function useUpdateEstadoFactura(numero: string) {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (estado: string) => {
      const estadoNormalizado = String(estado || "").toUpperCase();
      if (estadoNormalizado !== "ANULADA") throw new Error("solo_anular_soportado_en_endpoint_integrado");
      return apiPost(`${API_BASE}/anular-tx`, {
        tipoOperacion: TIPO_OPERACION,
        numFact: numero
      });
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: [QUERY_KEY] });
      queryClient.invalidateQueries({ queryKey: [QUERY_KEY, numero] });
    },
  });
}
