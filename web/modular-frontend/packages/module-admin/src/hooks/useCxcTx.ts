"use client";

import { useMutation, useQuery } from "@tanstack/react-query";
import { apiGet, apiPost } from "@zentto/shared-api";

export type CxcDocumentoPendiente = {
  tipoDoc: string;
  numDoc: string;
  fecha: string;
  pendiente: number;
  total: number;
};

export type CxcFormaPago = {
  formaPago: string;
  monto: number;
  banco?: string;
  numCheque?: string;
  fechaVencimiento?: string;
};

export type CxcAplicarCobroPayload = {
  requestId?: string;
  codCliente: string;
  fecha: string;
  montoTotal: number;
  codUsuario: string;
  observaciones?: string;
  documentos: Array<{
    tipoDoc: string;
    numDoc: string;
    montoAplicar: number;
  }>;
  formasPago: CxcFormaPago[];
};

export function useCxcDocumentosPendientes(codCliente: string) {
  return useQuery<{ success: boolean; data: CxcDocumentoPendiente[] }>({
    queryKey: ["cxc", "documentos", codCliente],
    enabled: !!codCliente,
    queryFn: () => apiGet(`/api/v1/cxc/documentos-pendientes/${encodeURIComponent(codCliente)}`)
  });
}

export function useCxcSaldo(codCliente: string) {
  return useQuery<{ success: boolean; data: Record<string, unknown> | null }>({
    queryKey: ["cxc", "saldo", codCliente],
    enabled: !!codCliente,
    queryFn: () => apiGet(`/api/v1/cxc/saldo/${encodeURIComponent(codCliente)}`)
  });
}

export function useAplicarCobroTx() {
  return useMutation({
    mutationFn: (payload: CxcAplicarCobroPayload) =>
      apiPost("/api/v1/cxc/aplicar-cobro-tx", payload)
  });
}

