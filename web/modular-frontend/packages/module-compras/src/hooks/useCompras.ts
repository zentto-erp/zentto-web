"use client";

import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { apiGet, apiPost } from "@datqbox/shared-api";

const QUERY_KEY = "compras";
const API_BASE = "/api/v1/documentos-compra";
const TIPO_OPERACION = "COMPRA";

export type ComprasFilter = {
  search?: string;
  proveedor?: string;
  estado?: string;
  fechaDesde?: string;
  fechaHasta?: string;
  page?: number;
  limit?: number;
};

export type CompraRow = {
  NUM_FACT: string;
  COD_PROVEEDOR?: string;
  NOMBRE?: string;
  RIF?: string;
  FECHA?: string;
  TOTAL?: number;
  TIPO?: string;
  ANULADA?: number;
};

export type ComprasListResponse = {
  page: number;
  limit: number;
  total: number;
  rows: CompraRow[];
  executionMode?: "sp" | "ts_fallback";
};

export type EmitirCompraPayload = {
  documento?: Record<string, unknown>;
  compra: Record<string, unknown>;
  detalle: Record<string, unknown>[];
  options?: {
    actualizarInventario?: boolean;
    generarCxP?: boolean;
    actualizarSaldosProveedor?: boolean;
    cxpTable?: "P_Pagar";
  };
};

export function useComprasList(filter?: ComprasFilter) {
  return useQuery<ComprasListResponse>({
    queryKey: [QUERY_KEY, "list", filter],
    queryFn: async () => {
      const params = new URLSearchParams();
      if (filter?.search) params.append("search", filter.search);
      if (filter?.proveedor) params.append("proveedor", filter.proveedor);
      if (filter?.estado) params.append("estado", filter.estado);
      if (filter?.fechaDesde) params.append("fechaDesde", filter.fechaDesde);
      if (filter?.fechaHasta) params.append("fechaHasta", filter.fechaHasta);
      if (filter?.page) params.append("page", String(filter.page));
      if (filter?.limit) params.append("limit", String(filter.limit));
      params.append("tipoOperacion", TIPO_OPERACION);
      return apiGet(`${API_BASE}?${params.toString()}`);
    }
  });
}

export function useCompraById(numFact: string) {
  return useQuery<unknown>({
    queryKey: [QUERY_KEY, numFact],
    queryFn: () => apiGet(`${API_BASE}/${TIPO_OPERACION}/${encodeURIComponent(numFact)}`),
    enabled: !!numFact
  });
}

export function useDetalleCompra(numFact: string) {
  return useQuery<unknown[]>({
    queryKey: [QUERY_KEY, "detalle", numFact],
    queryFn: () => apiGet(`${API_BASE}/${TIPO_OPERACION}/${encodeURIComponent(numFact)}/detalle`),
    enabled: !!numFact
  });
}

export function useIndicadoresCompra(numFact: string) {
  return useQuery<unknown>({
    queryKey: [QUERY_KEY, "indicadores", numFact],
    queryFn: () => apiGet(`${API_BASE}/${TIPO_OPERACION}/${encodeURIComponent(numFact)}/indicadores`),
    enabled: !!numFact
  });
}

export function useEmitirCompraTx() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (payload: EmitirCompraPayload) =>
      apiPost(`${API_BASE}/emitir-tx`, {
        tipoOperacion: TIPO_OPERACION,
        documento: payload.documento ?? payload.compra,
        detalle: payload.detalle,
        options: payload.options
      }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: [QUERY_KEY] });
      queryClient.invalidateQueries({ queryKey: ["inventario"] });
      queryClient.invalidateQueries({ queryKey: ["proveedores"] });
      queryClient.invalidateQueries({ queryKey: ["p-pagar"] });
    }
  });
}

export function useCreateCompra() {
  return useEmitirCompraTx();
}

export function useUpdateCompra(numFact: string) {
  return useMutation({
    mutationFn: async () => {
      throw new Error(`update_not_supported_for_integrated_endpoint:${numFact}`);
    }
  });
}

export function useDeleteCompra() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (numFact: string) =>
      apiPost(`${API_BASE}/anular-tx`, {
        tipoOperacion: TIPO_OPERACION,
        numFact
      }),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: [QUERY_KEY] })
  });
}
