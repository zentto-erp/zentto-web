"use client";

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { apiGet, apiPost } from "@zentto/shared-api";

const BASE = "/api/v1/manufactura";
const QK_BOM = "mfg-bom";
const QK_WORK_CENTERS = "mfg-work-centers";
const QK_ORDERS = "mfg-orders";

// ── Types ────────────────────────────────────────────────────

export interface BOMFilter {
  status?: string;
  search?: string;
  page?: number;
  limit?: number;
}

export interface BOMListResponse {
  rows: Record<string, unknown>[];
  total: number;
  page: number;
  limit: number;
}

export interface WorkCenterFilter {
  search?: string;
  page?: number;
  limit?: number;
}

export interface WorkCenterListResponse {
  rows: Record<string, unknown>[];
  total: number;
  page: number;
  limit: number;
}

export interface WorkOrderFilter {
  status?: string;
  fechaDesde?: string;
  fechaHasta?: string;
  page?: number;
  limit?: number;
}

export interface WorkOrderListResponse {
  rows: Record<string, unknown>[];
  total: number;
  page: number;
  limit: number;
}

export interface ManufacturaDashboard {
  BOMsActivos: number;
  CentrosTrabajo: number;
  OrdenesEnProceso: number;
  OrdenesCompletadas: number;
}

// ── BOMs ─────────────────────────────────────────────────────

export function useBOMList(filter?: BOMFilter) {
  return useQuery<BOMListResponse>({
    queryKey: [QK_BOM, filter],
    queryFn: async () => {
      const params = new URLSearchParams();
      if (filter?.status) params.append("status", filter.status);
      if (filter?.search) params.append("search", filter.search);
      if (filter?.page) params.append("page", filter.page.toString());
      if (filter?.limit) params.append("limit", filter.limit.toString());
      return apiGet(`${BASE}/bom?${params.toString()}`);
    },
  });
}

export function useBOMDetail(id?: number) {
  return useQuery({
    queryKey: [QK_BOM, "detail", id],
    queryFn: () => apiGet(`${BASE}/bom/${id}`),
    enabled: !!id,
  });
}

export function useCreateBOM() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (d: Record<string, unknown>) => apiPost(`${BASE}/bom`, d),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_BOM] }),
  });
}

export function useActivateBOM() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id: number) => apiPost(`${BASE}/bom/${id}/activar`, {}),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_BOM] }),
  });
}

export function useObsoleteBOM() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id: number) => apiPost(`${BASE}/bom/${id}/obsoleto`, {}),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_BOM] }),
  });
}

// ── Work Centers ─────────────────────────────────────────────

export function useWorkCentersList(filter?: WorkCenterFilter) {
  return useQuery<WorkCenterListResponse>({
    queryKey: [QK_WORK_CENTERS, filter],
    queryFn: async () => {
      const params = new URLSearchParams();
      if (filter?.search) params.append("search", filter.search);
      if (filter?.page) params.append("page", filter.page.toString());
      if (filter?.limit) params.append("limit", filter.limit.toString());
      return apiGet(`${BASE}/centros-trabajo?${params.toString()}`);
    },
  });
}

export function useUpsertWorkCenter() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (d: Record<string, unknown>) => apiPost(`${BASE}/centros-trabajo`, d),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_WORK_CENTERS] }),
  });
}

// ── Work Orders ──────────────────────────────────────────────

export function useWorkOrdersList(filter?: WorkOrderFilter) {
  return useQuery<WorkOrderListResponse>({
    queryKey: [QK_ORDERS, filter],
    queryFn: async () => {
      const params = new URLSearchParams();
      if (filter?.status) params.append("status", filter.status);
      if (filter?.fechaDesde) params.append("fechaDesde", filter.fechaDesde);
      if (filter?.fechaHasta) params.append("fechaHasta", filter.fechaHasta);
      if (filter?.page) params.append("page", filter.page.toString());
      if (filter?.limit) params.append("limit", filter.limit.toString());
      return apiGet(`${BASE}/ordenes?${params.toString()}`);
    },
  });
}

export function useWorkOrderDetail(id?: number) {
  return useQuery({
    queryKey: [QK_ORDERS, "detail", id],
    queryFn: () => apiGet(`${BASE}/ordenes/${id}`),
    enabled: !!id,
  });
}

export function useCreateWorkOrder() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (d: Record<string, unknown>) => apiPost(`${BASE}/ordenes`, d),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_ORDERS] }),
  });
}

export function useStartWorkOrder() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id: number) => apiPost(`${BASE}/ordenes/${id}/iniciar`, {}),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_ORDERS] }),
  });
}

export function useCompleteWorkOrder() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id: number) => apiPost(`${BASE}/ordenes/${id}/completar`, {}),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_ORDERS] }),
  });
}

export function useCancelWorkOrder() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id: number) => apiPost(`${BASE}/ordenes/${id}/cancelar`, {}),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_ORDERS] }),
  });
}

// ── Dashboard ────────────────────────────────────────────────

export function useManufacturaDashboard() {
  return useQuery<ManufacturaDashboard>({
    queryKey: ["manufactura", "dashboard"],
    queryFn: async () => {
      // Aggregate from existing endpoints
      const [boms, centers, orders] = await Promise.all([
        apiGet(`${BASE}/bom?limit=1&status=ACTIVE`) as Promise<BOMListResponse>,
        apiGet(`${BASE}/centros-trabajo?limit=1`) as Promise<WorkCenterListResponse>,
        apiGet(`${BASE}/ordenes?limit=1&status=IN_PROGRESS`) as Promise<WorkOrderListResponse>,
      ]);
      const completed = (await apiGet(`${BASE}/ordenes?limit=1&status=COMPLETED`)) as WorkOrderListResponse;
      return {
        BOMsActivos: boms?.total ?? 0,
        CentrosTrabajo: centers?.total ?? 0,
        OrdenesEnProceso: orders?.total ?? 0,
        OrdenesCompletadas: completed?.total ?? 0,
      };
    },
  });
}
