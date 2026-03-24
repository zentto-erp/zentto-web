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

// ── Conductores ────────────────────────────────────────────

export interface DriverFilter {
  carrierId?: number;
  search?: string;
  page?: number;
  limit?: number;
}

export interface DriverListResponse {
  rows: Record<string, unknown>[];
  total: number;
  page: number;
  limit: number;
}

const QK_DRIVERS = "logistics-drivers";

export function useDriversList(filter?: DriverFilter) {
  return useQuery<DriverListResponse>({
    queryKey: [QK_DRIVERS, filter],
    queryFn: async () => {
      const params = new URLSearchParams();
      if (filter?.carrierId) params.append("carrierId", filter.carrierId.toString());
      if (filter?.search) params.append("search", filter.search);
      if (filter?.page) params.append("page", filter.page.toString());
      if (filter?.limit) params.append("limit", filter.limit.toString());
      return apiGet(`${BASE}/conductores?${params.toString()}`);
    },
  });
}

export function useCreateDriver() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (d: Record<string, unknown>) => apiPost(`${BASE}/conductores`, d),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_DRIVERS] }),
  });
}

export function useUpdateDriver() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (d: Record<string, unknown>) => apiPost(`${BASE}/conductores`, d),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_DRIVERS] }),
  });
}

// ── Dashboard ───────────────────────────────────────────────

export function useLogisticaDashboard() {
  return useQuery<LogisticaDashboard>({
    queryKey: ["logistica", "dashboard"],
    queryFn: () => apiGet(`${BASE}/dashboard`),
  });
}

// ── Analytics ──────────────────────────────────────────────

export interface ReceiptsByMonthRow {
  Month: string;
  MonthLabel: string;
  Total: number;
}

export interface DeliveryByStatusRow {
  Status: string;
  StatusLabel: string;
  Count: number;
}

export interface RecentActivityRow {
  ActivityId: number;
  ActivityType: string;
  DocNumber: string;
  EntityName: string;
  ActivityDate: string;
  Status: string;
  StatusLabel: string;
}

export interface LogisticaTrends {
  ReceiptsThisMonth: number;
  ReceiptsLastMonth: number;
  DeliveriesThisMonth: number;
  DeliveriesLastMonth: number;
  ReturnsThisMonth: number;
  ReturnsLastMonth: number;
}

export function useReceiptsByMonth() {
  return useQuery<ReceiptsByMonthRow[]>({
    queryKey: ["logistica", "analytics", "receipts-by-month"],
    queryFn: () => apiGet(`${BASE}/analytics/receipts-by-month`),
  });
}

export function useDeliveryByStatus() {
  return useQuery<DeliveryByStatusRow[]>({
    queryKey: ["logistica", "analytics", "delivery-by-status"],
    queryFn: () => apiGet(`${BASE}/analytics/delivery-by-status`),
  });
}

export function useRecentActivity() {
  return useQuery<RecentActivityRow[]>({
    queryKey: ["logistica", "analytics", "recent-activity"],
    queryFn: () => apiGet(`${BASE}/analytics/recent-activity`),
  });
}

export function useLogisticaTrends() {
  return useQuery<LogisticaTrends>({
    queryKey: ["logistica", "analytics", "trends"],
    queryFn: () => apiGet(`${BASE}/analytics/trends`),
  });
}
