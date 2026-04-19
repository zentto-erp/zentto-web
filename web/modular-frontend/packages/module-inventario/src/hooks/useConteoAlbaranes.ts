// hooks/useConteoAlbaranes.ts
"use client";

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { apiGet, apiPost, apiPut, apiDelete } from "@zentto/shared-api";

const API = "/api/v1/inventario";

// ── Conteo físico ─────────────────────────────────────────────────────────────

export interface HojaConteoRow {
  HojaConteoId: number;
  Numero: string;
  WarehouseCode: string;
  Estado: string;
  FechaConteo: string;
  FechaCierre: string | null;
  TotalLineas: number;
  LineasContadas: number;
}

export function useConteoList(params: { estado?: string; warehouseCode?: string; page?: number; limit?: number } = {}) {
  return useQuery({
    queryKey: ["conteo", params],
    queryFn: () => apiGet<{ rows: HojaConteoRow[]; total: number; page: number; limit: number }>(
      `${API}/conteo`,
      params as Record<string, string>,
    ),
  });
}

export function useCrearConteo() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (data: { warehouseCode: string; notas?: string }) =>
      apiPost(`${API}/conteo`, data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["conteo"] }),
  });
}

export function useUpsertLineaConteo() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ id, ...data }: { id: number; productCode: string; stockFisico: number; unitCost?: number; justificacion?: string }) =>
      apiPut(`${API}/conteo/${id}/lineas`, data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["conteo"] }),
  });
}

export function useCerrarConteo() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id: number) => apiPost(`${API}/conteo/${id}/cerrar`, {}),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["conteo"] });
      qc.invalidateQueries({ queryKey: ["inventario"] });
    },
  });
}

// ── Albaranes ─────────────────────────────────────────────────────────────────

export interface AlbaranRow {
  AlbaranId: number;
  Numero: string;
  Tipo: string;
  Estado: string;
  FechaEmision: string;
  WarehouseFrom: string | null;
  WarehouseTo: string | null;
  DestinatarioNombre: string | null;
  TotalLineas: number;
}

export function useAlbaranesList(params: { tipo?: string; estado?: string; fechaDesde?: string; fechaHasta?: string; page?: number; limit?: number } = {}) {
  return useQuery({
    queryKey: ["albaranes", params],
    queryFn: () => apiGet<{ rows: AlbaranRow[]; total: number; page: number; limit: number }>(
      `${API}/albaranes`,
      params as Record<string, string>,
    ),
  });
}

export function useCrearAlbaran() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (data: { tipo: string; warehouseFrom?: string; warehouseTo?: string; destinatarioNombre?: string; destinatarioRif?: string; observaciones?: string; sourceType?: string; sourceId?: number }) =>
      apiPost(`${API}/albaranes`, data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["albaranes"] }),
  });
}

export function useAddLineaAlbaran() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ albaranId, ...data }: { albaranId: number; productCode: string; cantidad: number; unidad?: string; costo?: number; lote?: string }) =>
      apiPost(`${API}/albaranes/${albaranId}/lineas`, data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["albaranes"] }),
  });
}

export function useEmitirAlbaran() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id: number) => apiPost(`${API}/albaranes/${id}/emitir`, {}),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["albaranes"] }),
  });
}

export function useFirmarAlbaran() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ id, firmante }: { id: number; firmante?: string }) =>
      apiPost(`${API}/albaranes/${id}/firmar`, { firmante }),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["albaranes"] });
      qc.invalidateQueries({ queryKey: ["inventario"] });
    },
  });
}

// ── Traslados multi-paso ──────────────────────────────────────────────────────

export interface TrasladoMPRow {
  TrasladoId: number;
  Numero: string;
  Estado: string;
  WarehouseFrom: string;
  WarehouseTo: string;
  FechaSolicitud: string;
  FechaSalida: string | null;
  FechaRecepcion: string | null;
}

export function useTrasladosMPList(params: { estado?: string; page?: number; limit?: number } = {}) {
  return useQuery({
    queryKey: ["traslados-mp", params],
    queryFn: () => apiGet<{ rows: TrasladoMPRow[]; total: number; page: number; limit: number }>(
      `${API}/traslados-mp`,
      params as Record<string, string>,
    ),
  });
}

export function useCrearTrasladoMP() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (data: { warehouseFrom: string; warehouseTo: string; notas?: string }) =>
      apiPost(`${API}/traslados-mp`, data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["traslados-mp"] }),
  });
}

export function useAvanzarTrasladoMP() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ id, action }: { id: number; action: string }) =>
      apiPost(`${API}/traslados-mp/${id}/avanzar`, { action }),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["traslados-mp"] });
      qc.invalidateQueries({ queryKey: ["inventario"] });
    },
  });
}

// ── Kardex ───────────────────────────────────────────────────────────────────

export interface KardexRow {
  FechaMovimiento: string;
  TipoMovimiento: string;
  Cantidad: number;
  CostoUnitario: number;
  SaldoAcumulado: number;
  Referencia: string | null;
  TipoDocumentoOrigen: string | null;
  Notas: string | null;
}

export function useKardex(productCode: string, params: { fechaDesde?: string; fechaHasta?: string; page?: number; limit?: number } = {}) {
  return useQuery({
    queryKey: ["kardex", productCode, params],
    queryFn: () => apiGet<{ rows: KardexRow[]; total: number; page: number; limit: number }>(
      `${API}/kardex/${encodeURIComponent(productCode)}`,
      params as Record<string, string>,
    ),
    enabled: !!productCode,
  });
}
