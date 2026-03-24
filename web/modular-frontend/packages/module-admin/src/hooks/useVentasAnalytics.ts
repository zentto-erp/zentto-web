"use client";

import { useQuery } from "@tanstack/react-query";
import { apiGet } from "@zentto/shared-api";

const BASE = "/api/v1/ventas/analytics";

export interface SalesKPIs {
  TotalFacturas: number;
  MontoTotal: number;
  ClientesActivos: number;
  CxCPendiente: number;
  CxCVencida: number;
  FacturasMes: number;
  FacturasMesAnterior: number;
  PromedioFactura: number;
  DiasPromCobro: number;
  TopCliente: string;
  TopClienteMonto: number;
}

export interface SalesByMonth {
  Month: string;
  Count: number;
  Total: number;
  Accumulated: number;
}

export interface SalesByCustomer {
  CustomerCode: string;
  CustomerName: string;
  FacturasCount: number;
  Total: number;
  Percentage: number;
}

export interface ARAgingBucket {
  Bucket: string;
  Count: number;
  Total: number;
  Percentage: number;
}

export interface CollectionForecastMonth {
  Month: string;
  DueAmount: number;
  DocumentCount: number;
}

export interface SalesByProduct {
  ProductCode: string;
  ProductName: string;
  Quantity: number;
  Total: number;
  Percentage: number;
}

export function useSalesKPIs(from?: string, to?: string) {
  const params = new URLSearchParams();
  if (from) params.set("from", from);
  if (to) params.set("to", to);
  const qs = params.toString();
  return useQuery<SalesKPIs>({
    queryKey: ["sales-kpis", from, to],
    queryFn: () => apiGet(`${BASE}/kpis${qs ? `?${qs}` : ""}`),
  });
}

export function useSalesByMonth(months?: number) {
  return useQuery<SalesByMonth[]>({
    queryKey: ["sales-by-month", months],
    queryFn: () =>
      apiGet(`${BASE}/by-month${months ? `?months=${months}` : ""}`),
  });
}

export function useSalesByCustomer(top?: number, from?: string, to?: string) {
  const params = new URLSearchParams();
  if (top) params.set("top", String(top));
  if (from) params.set("from", from);
  if (to) params.set("to", to);
  const qs = params.toString();
  return useQuery<SalesByCustomer[]>({
    queryKey: ["sales-by-customer", top, from, to],
    queryFn: () => apiGet(`${BASE}/by-customer${qs ? `?${qs}` : ""}`),
  });
}

export function useARAging() {
  return useQuery<ARAgingBucket[]>({
    queryKey: ["ar-aging"],
    queryFn: () => apiGet(`${BASE}/aging`),
  });
}

export function useCollectionForecast(months?: number) {
  return useQuery<CollectionForecastMonth[]>({
    queryKey: ["collection-forecast", months],
    queryFn: () =>
      apiGet(`${BASE}/collection-forecast${months ? `?months=${months}` : ""}`),
  });
}

export function useSalesByProduct(top?: number, from?: string, to?: string) {
  const params = new URLSearchParams();
  if (top) params.set("top", String(top));
  if (from) params.set("from", from);
  if (to) params.set("to", to);
  const qs = params.toString();
  return useQuery<SalesByProduct[]>({
    queryKey: ["sales-by-product", top, from, to],
    queryFn: () => apiGet(`${BASE}/by-product${qs ? `?${qs}` : ""}`),
  });
}
