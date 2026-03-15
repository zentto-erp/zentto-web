// hooks/useInventario.ts
"use client";

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { apiGet, apiPost, apiPut, apiDelete } from "@datqbox/shared-api";

const QUERY_KEY = "inventario";
const API_BASE = "/api/v1/inventario";

// ── Types ────────────────────────────────────────────────────

export interface InventarioListFilter {
  search?: string;
  page?: number;
  limit?: number;
}

export interface InventarioListResponse {
  rows: Record<string, unknown>[];
  total: number;
  page: number;
  limit: number;
}

export interface DashboardData {
  TotalArticulos: number;
  BajoStock: number;
  TotalCategorias: number;
  ValorInventario: number;
  MovimientosMes: number;
}

export interface MovimientosFilter {
  search?: string;
  productCode?: string;
  movementType?: string;
  warehouseCode?: string;
  fechaDesde?: string;
  fechaHasta?: string;
  page?: number;
  limit?: number;
}

export interface MovimientosResponse {
  rows: Record<string, unknown>[];
  total: number;
  page: number;
  limit: number;
}

export interface LibroFilter {
  fechaDesde: string;
  fechaHasta: string;
  productCode?: string;
}

// ── QUERIES ──────────────────────────────────────────────────

export function useInventarioList(filter?: InventarioListFilter) {
  return useQuery<InventarioListResponse>({
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
  return useQuery({
    queryKey: [QUERY_KEY, codigoArticulo],
    queryFn: () => apiGet(`${API_BASE}/${codigoArticulo}`),
    enabled: !!codigoArticulo,
  });
}

export function useInventarioDashboard() {
  return useQuery<DashboardData>({
    queryKey: [QUERY_KEY, "dashboard"],
    queryFn: () => apiGet(`${API_BASE}/dashboard`),
  });
}

export function useMovimientosList(filter?: MovimientosFilter) {
  return useQuery<MovimientosResponse>({
    queryKey: [QUERY_KEY, "movimientos", filter],
    queryFn: async () => {
      const params = new URLSearchParams();
      if (filter?.search) params.append("search", filter.search);
      if (filter?.productCode) params.append("productCode", filter.productCode);
      if (filter?.movementType) params.append("movementType", filter.movementType);
      if (filter?.warehouseCode) params.append("warehouseCode", filter.warehouseCode);
      if (filter?.fechaDesde) params.append("fechaDesde", filter.fechaDesde);
      if (filter?.fechaHasta) params.append("fechaHasta", filter.fechaHasta);
      if (filter?.page) params.append("page", filter.page.toString());
      if (filter?.limit) params.append("limit", filter.limit.toString());
      return apiGet(`${API_BASE}/movimientos?${params.toString()}`);
    },
    enabled: filter !== undefined,
  });
}

export function useLibroInventario(filter?: LibroFilter) {
  return useQuery<{ rows: Record<string, unknown>[] }>({
    queryKey: [QUERY_KEY, "libro", filter],
    queryFn: async () => {
      const params = new URLSearchParams();
      if (filter?.fechaDesde) params.append("fechaDesde", filter.fechaDesde);
      if (filter?.fechaHasta) params.append("fechaHasta", filter.fechaHasta);
      if (filter?.productCode) params.append("productCode", filter.productCode);
      return apiGet(`${API_BASE}/reportes/libro?${params.toString()}`);
    },
    enabled: !!filter?.fechaDesde && !!filter?.fechaHasta,
  });
}

// ── MUTATIONS ────────────────────────────────────────────────

export function useCreateMovimiento() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (data: Record<string, unknown>) => apiPost(`${API_BASE}/movimientos`, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: [QUERY_KEY] });
    },
  });
}

export function useCreateTraslado() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (data: Record<string, unknown>) => apiPost(`${API_BASE}/traslados`, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: [QUERY_KEY] });
    },
  });
}

export function useUpdateInventario(codigoArticulo: string) {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (data: Record<string, unknown>) => apiPut(`${API_BASE}/${codigoArticulo}`, data),
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
