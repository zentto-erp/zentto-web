"use client";

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { apiGet, apiPost } from "@zentto/shared-api";

const QUERY_KEY = "pedidos-ecommerce";
const API_BASE = "/api/v1/documentos-venta";

export type PedidoEcommerce = {
  DocumentNumber: string;
  CustomerCode: string;
  CustomerName: string;
  FiscalId: string;
  IssueDate: string;
  TotalAmount: number;
  IsInvoiced: string;
  IsDelivered: string;
  ShippingAddress?: string;
  BillingAddress?: string;
  Notes?: string;
};

type PedidosListResponse = {
  rows: PedidoEcommerce[];
  total: number;
};

type PedidosFilter = {
  search?: string;
  page?: number;
  limit?: number;
  solosPendientes?: boolean;
};

type FacturarDesdePedidoPayload = {
  numFactPedido: string;
  factura: Record<string, unknown>;
  formasPago?: unknown[];
};

export function usePedidosPendientes(filter?: PedidosFilter) {
  return useQuery<PedidosListResponse>({
    queryKey: [QUERY_KEY, "list", filter],
    queryFn: async () => {
      const params = new URLSearchParams();
      params.append("tipoOperacion", "PEDIDO");
      if (filter?.search) params.append("search", filter.search);
      if (filter?.page) params.append("page", String(filter.page));
      if (filter?.limit) params.append("limit", String(filter.limit));
      if (filter?.solosPendientes) params.append("estado", "PENDIENTE");

      const resp = await apiGet(`${API_BASE}?${params.toString()}`);
      const rows = Array.isArray(resp?.rows) ? (resp.rows as PedidoEcommerce[]) : [];

      return {
        rows,
        total: Number(resp?.total ?? rows.length),
      };
    },
  });
}

export function useFacturarDesdePedido() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (data: FacturarDesdePedidoPayload) =>
      apiPost(`${API_BASE}/facturar-desde-pedido-tx`, data),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: [QUERY_KEY] });
      qc.invalidateQueries({ queryKey: ["facturas"] });
      qc.invalidateQueries({ queryKey: ["inventario"] });
    },
  });
}
