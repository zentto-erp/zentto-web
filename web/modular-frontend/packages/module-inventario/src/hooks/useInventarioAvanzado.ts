// hooks/useInventarioAvanzado.ts
"use client";

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { apiGet, apiPost, apiPut, apiDelete } from "@zentto/shared-api";

const BASE = "/v1/inventario-avanzado";
const QK_LOTS = "inv-lots";
const QK_SERIALS = "inv-serials";
const QK_WAREHOUSES = "inv-warehouses";
const QK_BIN_STOCK = "inv-bin-stock";

// ── Types ────────────────────────────────────────────────────

export interface LotFilter {
  productId?: number;
  status?: string;
  page?: number;
  limit?: number;
}

export interface SerialFilter {
  productId?: number;
  status?: string;
  warehouseId?: number;
  search?: string;
  page?: number;
  limit?: number;
}

// ── Lotes ────────────────────────────────────────────────────

export function useLotesList(filter?: LotFilter) {
  return useQuery({
    queryKey: [QK_LOTS, filter],
    queryFn: () => apiGet(`${BASE}/lotes`, filter as any),
  });
}

export function useCreateLote() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (data: any) => apiPost(`${BASE}/lotes`, data),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_LOTS] }),
  });
}

// ── Seriales ─────────────────────────────────────────────────

export function useSerialsList(filter?: SerialFilter) {
  return useQuery({
    queryKey: [QK_SERIALS, filter],
    queryFn: () => apiGet(`${BASE}/seriales`, filter as any),
  });
}

export function useSerialByNumber(serialNumber?: string) {
  return useQuery({
    queryKey: [QK_SERIALS, "detail", serialNumber],
    queryFn: () => apiGet(`${BASE}/seriales/${serialNumber}`),
    enabled: !!serialNumber,
  });
}

export function useCreateSerial() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (data: any) => apiPost(`${BASE}/seriales`, data),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_SERIALS] }),
  });
}

export function useUpdateSerialStatus() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (data: { serialNumber: string; status: string }) =>
      apiPut(`${BASE}/seriales/${data.serialNumber}/status`, data),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_SERIALS] }),
  });
}

// ── Almacenes WMS ────────────────────────────────────────────

export function useWarehousesList() {
  return useQuery({
    queryKey: [QK_WAREHOUSES],
    queryFn: () => apiGet(`${BASE}/almacenes-wms`),
  });
}

export function useWarehouseZones(warehouseId?: number) {
  return useQuery({
    queryKey: [QK_WAREHOUSES, "zones", warehouseId],
    queryFn: () => apiGet(`${BASE}/almacenes-wms/${warehouseId}/zonas`),
    enabled: !!warehouseId,
  });
}

export function useWarehouseBins(zoneId?: number) {
  return useQuery({
    queryKey: [QK_WAREHOUSES, "bins", zoneId],
    queryFn: () => apiGet(`${BASE}/almacenes-wms/zonas/${zoneId}/ubicaciones`),
    enabled: !!zoneId,
  });
}

export function useCreateWarehouse() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (data: any) => apiPost(`${BASE}/almacenes-wms`, data),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_WAREHOUSES] }),
  });
}

// ── Stock por ubicación ──────────────────────────────────────

export function useBinStock(warehouseId?: number, productId?: number) {
  return useQuery({
    queryKey: [QK_BIN_STOCK, warehouseId, productId],
    queryFn: () => apiGet(`${BASE}/stock-ubicacion`, { warehouseId, productId }),
    enabled: !!warehouseId,
  });
}
