"use client";

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { apiGet, apiPost, apiPut } from "@zentto/shared-api";

const BASE = "/api/v1/logistica";
const QK_CARRIERS = "logistics-carriers";
const QK_RECEIPTS = "logistics-receipts";
const QK_RETURNS = "logistics-returns";
const QK_DELIVERY = "logistics-delivery";

// ── Types ────────────────────────────────────────────────────

export interface CarrierFilter {
  search?: string;
  page?: number;
  limit?: number;
}

export interface CarrierListResponse {
  rows: Record<string, unknown>[];
  total: number;
  page: number;
  limit: number;
}

export interface ReceiptFilter {
  status?: string;
  supplierId?: number;
  page?: number;
  limit?: number;
}

export interface ReceiptListResponse {
  rows: Record<string, unknown>[];
  total: number;
  page: number;
  limit: number;
}

export interface ReturnFilter {
  status?: string;
  page?: number;
  limit?: number;
}

export interface ReturnListResponse {
  rows: Record<string, unknown>[];
  total: number;
  page: number;
  limit: number;
}

export interface DeliveryFilter {
  status?: string;
  customerId?: number;
  page?: number;
  limit?: number;
}

export interface DeliveryListResponse {
  rows: Record<string, unknown>[];
  total: number;
  page: number;
  limit: number;
}

export interface LogisticaDashboard {
  RecepcionesPendientes: number;
  DevolucionesEnProceso: number;
  AlbaranesEnTransito: number;
  TransportistasActivos: number;
}

// ── Transportistas ──────────────────────────────────────────

export function useCarriersList(filter?: CarrierFilter) {
  return useQuery<CarrierListResponse>({
    queryKey: [QK_CARRIERS, filter],
    queryFn: async () => {
      const params = new URLSearchParams();
      if (filter?.search) params.append("search", filter.search);
      if (filter?.page) params.append("page", filter.page.toString());
      if (filter?.limit) params.append("limit", filter.limit.toString());
      return apiGet(`${BASE}/transportistas?${params.toString()}`);
    },
  });
}

export function useCarrierDetail(id?: number) {
  return useQuery({
    queryKey: [QK_CARRIERS, "detail", id],
    queryFn: () => apiGet(`${BASE}/transportistas/${id}`),
    enabled: !!id,
  });
}

export function useCreateCarrier() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (d: Record<string, unknown>) => apiPost(`${BASE}/transportistas`, d),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_CARRIERS] }),
  });
}

export function useUpdateCarrier() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (d: Record<string, unknown>) => apiPut(`${BASE}/transportistas/${d.id}`, d),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_CARRIERS] }),
  });
}

// ── Recepcion de mercancia ──────────────────────────────────

export function useReceiptsList(filter?: ReceiptFilter) {
  return useQuery<ReceiptListResponse>({
    queryKey: [QK_RECEIPTS, filter],
    queryFn: async () => {
      const params = new URLSearchParams();
      if (filter?.status) params.append("status", filter.status);
      if (filter?.supplierId) params.append("supplierId", filter.supplierId.toString());
      if (filter?.page) params.append("page", filter.page.toString());
      if (filter?.limit) params.append("limit", filter.limit.toString());
      return apiGet(`${BASE}/recepciones?${params.toString()}`);
    },
  });
}

export function useReceiptDetail(id?: number) {
  return useQuery({
    queryKey: [QK_RECEIPTS, "detail", id],
    queryFn: () => apiGet(`${BASE}/recepciones/${id}`),
    enabled: !!id,
  });
}

export function useCreateReceipt() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (d: Record<string, unknown>) => apiPost(`${BASE}/recepciones`, d),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_RECEIPTS] }),
  });
}

export function useCompleteReceipt() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id: number) => apiPost(`${BASE}/recepciones/${id}/completar`, {}),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_RECEIPTS] }),
  });
}

// ── Devoluciones ────────────────────────────────────────────

export function useReturnsList(filter?: ReturnFilter) {
  return useQuery<ReturnListResponse>({
    queryKey: [QK_RETURNS, filter],
    queryFn: async () => {
      const params = new URLSearchParams();
      if (filter?.status) params.append("status", filter.status);
      if (filter?.page) params.append("page", filter.page.toString());
      if (filter?.limit) params.append("limit", filter.limit.toString());
      return apiGet(`${BASE}/devoluciones?${params.toString()}`);
    },
  });
}

export function useReturnDetail(id?: number) {
  return useQuery({
    queryKey: [QK_RETURNS, "detail", id],
    queryFn: () => apiGet(`${BASE}/devoluciones/${id}`),
    enabled: !!id,
  });
}

export function useCreateReturn() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (d: Record<string, unknown>) => apiPost(`${BASE}/devoluciones`, d),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_RETURNS] }),
  });
}

// ── Notas de entrega / Albaranes ────────────────────────────

export function useDeliveryNotesList(filter?: DeliveryFilter) {
  return useQuery<DeliveryListResponse>({
    queryKey: [QK_DELIVERY, filter],
    queryFn: async () => {
      const params = new URLSearchParams();
      if (filter?.status) params.append("status", filter.status);
      if (filter?.customerId) params.append("customerId", filter.customerId.toString());
      if (filter?.page) params.append("page", filter.page.toString());
      if (filter?.limit) params.append("limit", filter.limit.toString());
      return apiGet(`${BASE}/notas-entrega?${params.toString()}`);
    },
  });
}

export function useDeliveryNoteDetail(id?: number) {
  return useQuery({
    queryKey: [QK_DELIVERY, "detail", id],
    queryFn: () => apiGet(`${BASE}/notas-entrega/${id}`),
    enabled: !!id,
  });
}

export function useCreateDeliveryNote() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (d: Record<string, unknown>) => apiPost(`${BASE}/notas-entrega`, d),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_DELIVERY] }),
  });
}

export function useDispatchDeliveryNote() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id: number) => apiPost(`${BASE}/notas-entrega/${id}/despachar`, {}),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_DELIVERY] }),
  });
}

export function useDeliverDeliveryNote() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (data: { id: number; deliveredToName: string }) =>
      apiPost(`${BASE}/notas-entrega/${data.id}/entregar`, data),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_DELIVERY] }),
  });
}

// ── Dashboard ───────────────────────────────────────────────

export function useLogisticaDashboard() {
  return useQuery<LogisticaDashboard>({
    queryKey: ["logistica", "dashboard"],
    queryFn: () => apiGet(`${BASE}/dashboard`),
  });
}
