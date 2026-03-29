"use client";

import { useQuery } from "@tanstack/react-query";
import { apiGet } from "@zentto/shared-api";

const BASE = "/api/v1/compras/analytics";

export interface PurchaseKPIs {
  TotalCompras: number;
  MontoTotal: number;
  ProveedoresActivos: number;
  CxPPendiente: number;
  CxPVencida: number;
  ComprasMes: number;
  CompraMesAnterior: number;
  PromedioCompra: number;
  DiasPromPago: number;
  TopProveedor: string;
  TopProveedorMonto: number;
}

export interface PurchaseByMonth {
  Month: string;
  Count: number;
  Total: number;
  Accumulated: number;
}

export interface PurchaseBySupplier {
  SupplierCode: string;
  SupplierName: string;
  ComprasCount: number;
  Total: number;
  Percentage: number;
}

export interface APAgingBucket {
  Bucket: string;
  Count: number;
  Total: number;
  Percentage: number;
}

export interface PaymentScheduleMonth {
  Month: string;
  DueAmount: number;
  DocumentCount: number;
}

export function usePurchaseKPIs(from?: string, to?: string) {
  const params = new URLSearchParams();
  if (from) params.set("from", from);
  if (to) params.set("to", to);
  const qs = params.toString();
  return useQuery<PurchaseKPIs>({
    queryKey: ["purchases-kpis", from, to],
    queryFn: () => apiGet(`${BASE}/kpis${qs ? `?${qs}` : ""}`),
  });
}

export function usePurchasesByMonth(months?: number) {
  return useQuery<PurchaseByMonth[]>({
    queryKey: ["purchases-by-month", months],
    queryFn: () =>
      apiGet(`${BASE}/by-month${months ? `?months=${months}` : ""}`),
  });
}

export function usePurchasesBySupplier(top?: number, from?: string, to?: string) {
  const params = new URLSearchParams();
  if (top) params.set("top", String(top));
  if (from) params.set("from", from);
  if (to) params.set("to", to);
  const qs = params.toString();
  return useQuery<PurchaseBySupplier[]>({
    queryKey: ["purchases-by-supplier", top, from, to],
    queryFn: () => apiGet(`${BASE}/by-supplier${qs ? `?${qs}` : ""}`),
  });
}

export function useAPAging() {
  return useQuery<APAgingBucket[]>({
    queryKey: ["ap-aging"],
    queryFn: () => apiGet(`${BASE}/aging`),
  });
}

export function usePaymentSchedule(months?: number) {
  return useQuery<PaymentScheduleMonth[]>({
    queryKey: ["payment-schedule", months],
    queryFn: () =>
      apiGet(`${BASE}/payment-schedule${months ? `?months=${months}` : ""}`),
  });
}
