"use client";

import { useMutation, useQuery } from "@tanstack/react-query";
import { apiGet, apiPost } from "@datqbox/shared-api";

export type CxpDocumentoPendiente = {
  tipoDoc: string;
  numDoc: string;
  fecha: string;
  pendiente: number;
  total: number;
};

export type CxpFormaPago = {
  formaPago: string;
  monto: number;
  banco?: string;
  numCheque?: string;
  fechaVencimiento?: string;
};

export type CxpAplicarPagoPayload = {
  requestId?: string;
  codProveedor: string;
  fecha: string;
  montoTotal: number;
  codUsuario: string;
  observaciones?: string;
  documentos: Array<{
    tipoDoc: string;
    numDoc: string;
    montoAplicar: number;
  }>;
  formasPago: CxpFormaPago[];
};

export function useCxpDocumentosPendientes(codProveedor: string) {
  return useQuery<{ success: boolean; data: CxpDocumentoPendiente[] }>({
    queryKey: ["cxp", "documentos", codProveedor],
    enabled: !!codProveedor,
    queryFn: () => apiGet(`/api/v1/cxp/documentos-pendientes/${encodeURIComponent(codProveedor)}`)
  });
}

export function useCxpSaldo(codProveedor: string) {
  return useQuery<{ success: boolean; data: Record<string, unknown> | null }>({
    queryKey: ["cxp", "saldo", codProveedor],
    enabled: !!codProveedor,
    queryFn: () => apiGet(`/api/v1/cxp/saldo/${encodeURIComponent(codProveedor)}`)
  });
}

export function useAplicarPagoTx() {
  return useMutation({
    mutationFn: (payload: CxpAplicarPagoPayload) =>
      apiPost("/api/v1/cxp/aplicar-pago-tx", payload)
  });
}
